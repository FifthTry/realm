lazy_static! {
    pub static ref THREAD_POOL: futures_cpupool::CpuPool = {
        let mut builder = futures_cpupool::Builder::new();
        builder.pool_size(std::env::var("REALM_THREAD_POOL_SIZE")
                .unwrap_or_else(|_|"40".to_string())
                .parse()
                .unwrap());
        builder.stack_size(16 * 1024 * 1024); // 16mb, default is 8mb
        builder.create()
    };
}

pub fn http_to_hyper(resp: http::Response<Vec<u8>>) -> hyper::Response<hyper::Body> {
    let (parts, body) = resp.into_parts();
    hyper::Response::from_parts(parts, hyper::Body::from(body))
}

pub fn server_error(msg: &str) -> hyper::Response<hyper::Body> {
    let mut resp = hyper::Response::default();
    *resp.status_mut() = http::StatusCode::INTERNAL_SERVER_ERROR;
    *resp.body_mut() = hyper::Body::from(msg.to_string().into_bytes());
    resp
}

pub fn redirect(
    url: &str,
    cookies: std::collections::HashMap<String, String>,
) -> hyper::Response<hyper::Body> {
    let mut builder = http::response::Builder::new();
    builder.status(http::StatusCode::FOUND);
    builder.header(http::header::LOCATION, url);

    for (k, v) in cookies.iter() {
        builder.header(
            http::header::SET_COOKIE,
            crate::utils::set_cookie(k, v, if v.is_empty() { 0 } else { 3600 }),
        );
    }
    builder.body(hyper::Body::empty()).unwrap()
}

#[macro_export]
macro_rules! realm_serve {
    ($e:expr) => {{
        use futures::{stream::Stream, IntoFuture};
        use hyper::{rt::Future, Body};
        use std::collections::HashMap;

        type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

        fn replay_file(path: &std::path::Path, result: &mut realm::rr::ReplayResult) -> Result<()> {
            let start = std::time::Instant::now();
            let current: realm::rr::Recording = realm::rr::Recording::from_p1(ftd::p1::parse(
                std::fs::read_to_string(path)?.as_str(),
            )?)?;

            if let Some(ref b) = current.base {
                replay_file(&realm::rr::tid_to_path(b), result)?;
            }

            let mut context: HashMap<String, String> = HashMap::new();

            let count = current.steps.len();
            for step in current.steps.into_iter() {
                let ctx = step.ctx(result.cookies.clone(), context);
                $e(&ctx)?;
                let got = ctx.get_step().unwrap();
                if got.test_trace.trim() != step.test_trace.trim() {
                    println!(
                        "expected:\n{}\n\nfound:\n{}\n\n",
                        step.test_trace.as_str(),
                        got.test_trace.as_str()
                    );
                    println!(
                        "diff:\n{}\n",
                        diffy::create_patch(step.test_trace.as_str(), got.test_trace.as_str())
                    );
                    println!(
                        "{:?} failed in {:?}",
                        path,
                        std::time::Instant::now().duration_since(start)
                    );
                    return realm::replay_failed(format!("{:?}", path).as_str());
                }
                ctx.merge_cookies(&mut result.cookies);
                context = ctx.get_context();

                result.final_url = step.final_url.clone();
            }

            println!(
                "{:?}, {} steps, passed in {:?}",
                path,
                count,
                std::time::Instant::now().duration_since(start)
            );

            Ok(())
        }

        fn replay(path: &std::path::Path) -> Result<realm::rr::ReplayResult> {
            realm::test::reset_schema(&pg::connection())?;
            let mut result = realm::rr::ReplayResult::default();

            replay_file(path, &mut result)?;
            Ok(result)
        }

        fn replay_all_in(dir: &std::path::Path) -> Result<()> {
            for entry in std::fs::read_dir(dir)? {
                let path = entry?.path();
                if path.is_dir() {
                    replay_all_in(&path)?;
                } else {
                    replay(&path)?;
                }
            }
            Ok(())
        }

        fn replay_all() -> Result<()> {
            let args: Vec<String> = std::env::args().collect();
            if args.len() == 3 {
                let path = format!("tests/{}.json", args.get(2).unwrap());
                println!("trying: {}", path.as_str());
                replay(&std::path::PathBuf::from(path)).map(|_| ())
            } else {
                replay_all_in(std::path::PathBuf::from("tests/").as_path())
            }
        }

        pub fn handle_sync(
            req: realm::Request,
        ) -> std::result::Result<hyper::Response<Body>, hyper::Error> {
            if req.uri().to_string().starts_with("/test/replay/") {
                let url = realm::utils::to_url(
                    req.uri()
                        .path_and_query()
                        .map(|p| p.as_str())
                        .unwrap_or("/"),
                );
                let query: std::collections::HashMap<_, _> =
                    url.query_pairs().into_owned().collect();

                let tid = match query.get("tid") {
                    Some(tid) => tid,
                    None => return Ok(realm::serve::server_error("tid parameter not found")),
                };

                let res = replay(&realm::rr::tid_to_path(tid.as_str())).unwrap();
                return Ok(realm::serve::redirect(res.final_url.as_str(), res.cookies));
            }

            let req = std::sync::Mutex::new(req);
            let res = std::panic::catch_unwind(|| {
                let req = req.into_inner().unwrap();
                let url = realm::utils::to_url(
                    req.uri()
                        .path_and_query()
                        .map(|p| p.as_str())
                        .unwrap_or("/"),
                );
                let url = realm::cleanup_url(&url);
                let ctx = realm::Context::from_request(req);

                let r = match $e(&ctx)
                    .and_then(|r| r.render(&ctx, &url))
                    .map(|r| realm::http_to_hyper(r))
                {
                    Ok(a) => Ok(a),
                    Err(e) => {
                        println!("error: {:?}", e);
                        Ok(realm::Response::plain(
                            &ctx,
                            format!("error: {:?}", e),
                            http::StatusCode::INTERNAL_SERVER_ERROR,
                        )
                        .and_then(|r| r.render(&ctx, &url))
                        .map(|r| realm::http_to_hyper(r))
                        .unwrap())
                    }
                };

                // TODO: handle different components of activity
                std::sync::Mutex::new(r)
            });

            match res {
                Ok(r) => r.into_inner().unwrap(),
                Err(_) => {
                    // https://docs.rs/log-panics/2.0.0/src/log_panics/lib.rs.html#50-87
                    // we are not getting any meaningful message to print here. one way
                    // to do it would be set a hook as described in link above, and
                    // since hooks are global, store the panic message in a global
                    // hashmap (thread id-message), and retrieve the message by sending
                    // the current thread id.
                    Ok(realm::serve::server_error("panic"))
                }
            }
        }

        pub fn serve() {
            let port = std::env::var("PORT")
                .unwrap_or("3000".to_string())
                .parse()
                .unwrap();
            let addr = ([0, 0, 0, 0], port).into();

            let server = hyper::Server::bind(&addr)
                .serve(|| {
                    hyper::service::service_fn(|req: hyper::Request<Body>| -> BoxFut {
                        let (head, body) = req.into_parts();
                        Box::new(body.concat2().and_then(|body| {
                            let body = body.to_vec();
                            let req: realm::Request = http::Request::from_parts(head, body);
                            Box::new(
                                realm::THREAD_POOL.spawn_fn(move || handle_sync(req).into_future()),
                            )
                        }))
                    })
                })
                .map_err(|e| eprintln!("server error: {}", e));

            println!("Listening on http://{}", addr);
            hyper::rt::run(server);
        }

        if std::env::args().any(|e| e == "--replay") {
            match replay_all() {
                Ok(()) => println!("test passed"),
                Err(e) => {
                    match e.downcast_ref::<realm::Error>() {
                        Some(realm::Error::ReplayFailed { tid }) => {
                            println!("failed to run test: {}", tid);
                        }
                        _ => println!("exception during test: {:?}", e),
                    };
                }
            }
        } else {
            serve()
        }
    }};
}

#[macro_export]
macro_rules! realm {
    ($e:expr) => {
        pub fn main() {
            let logger = observer::backends::logger::Logger::builder()
                .with_path("/tmp/observer.log")
                .with_stdout()
                .build();

            observer::builder(logger).init();
            realm::realm_serve!($e)
        }
    };
}
