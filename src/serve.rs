lazy_static! {
    pub static ref THREAD_POOL: futures_cpupool::CpuPool = {
        let mut builder = futures_cpupool::Builder::new();
        builder.pool_size(*crate::env::REALM_THREAD_POOL_SIZE);
        builder.stack_size(16 * 1024 * 1024); // 16mb, default is 8mb
        builder.create()
    };
}

pub fn http_to_hyper(resp: http::Response<Vec<u8>>) -> hyper::Response<hyper::Body> {
    let (parts, body) = resp.into_parts();
    hyper::Response::from_parts(parts, hyper::Body::from(body))
}

pub fn noop<F: FnOnce() -> R, R>(f: F) -> std::thread::Result<R> {
    Ok(f())
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

pub trait Middleware {
    fn handle(&self, ctx: &crate::Context) -> crate::Result;
}

pub struct RealmService<T: Middleware + Sync + std::marker::Send + 'static> {
    middleware: T,
}

impl<T: Middleware + Sync + std::marker::Send + 'static> RealmService<T> {
    pub fn new(m: T) -> Self {
        Self { middleware: m }
    }

    fn loop_till_no_realm_redirect(
        &self,
        mut req: crate::Request,
        max_redirects: u8,
    ) -> (crate::Result, crate::Context, crate::Request) {
        let mut counter = 0;
        loop {
            let ctx = crate::Context::from_request(&req);
            let r = self.middleware.handle(&ctx);

            if let Ok(crate::Response::RealmRedirect(url)) = &r {
                let new_req =
                    crate::utils::request_with_url(req, url, Some(http::method::Method::GET))
                        .unwrap();
                req = new_req;
            } else {
                return (r, ctx, req);
            }
            if counter >= max_redirects {
                return (r, ctx, req);
            }
            counter += 1;
        }
    }

    fn replay_file(
        &self,
        path: &std::path::Path,
        result: &mut crate::rr::ReplayResult,
    ) -> crate::base::Result<()> {
        use std::collections::HashMap;

        let start = std::time::Instant::now();
        let current: crate::rr::Recording = crate::rr::Recording::from_p1(ftd::p1::parse(
            std::fs::read_to_string(path)?.as_str(),
        )?)?;

        if let Some(ref b) = current.base {
            self.replay_file(&crate::rr::tid_to_path(b), result)?;
        }

        let mut context: HashMap<String, String> = HashMap::new();

        let count = current.steps.len();
        for step in current.steps.into_iter() {
            let ctx = step.ctx(result.cookies.clone(), context);
            self.middleware.handle(&ctx)?;
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
                return crate::replay_failed(format!("{:?}", path).as_str());
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

    fn replay(&self, path: &std::path::Path) -> crate::base::Result<crate::rr::ReplayResult> {
        crate::test::reset_schema(&crate::base::pg::connection())?;
        let mut result = crate::rr::ReplayResult::default();

        self.replay_file(path, &mut result)?;
        Ok(result)
    }

    fn replay_all_in(&self, dir: &std::path::Path) -> crate::base::Result<()> {
        for entry in std::fs::read_dir(dir)? {
            let path = entry?.path();
            if path.is_dir() {
                self.replay_all_in(&path)?;
            } else {
                self.replay(&path)?;
            }
        }
        Ok(())
    }

    fn replay_all(&self) -> crate::base::Result<()> {
        let args: Vec<String> = std::env::args().collect();
        if args.len() == 3 {
            let path = format!("tests/{}.json", args.get(2).unwrap());
            println!("trying: {}", path.as_str());
            self.replay(&std::path::PathBuf::from(path)).map(|_| ())
        } else {
            self.replay_all_in(std::path::PathBuf::from("tests/").as_path())
        }
    }

    fn handle_sync(
        &self,
        req: crate::Request,
    ) -> std::result::Result<hyper::Response<hyper::Body>, hyper::Error> {
        if req.uri().to_string().starts_with("/test/replay/") {
            let url = crate::utils::to_url(
                req.uri()
                    .path_and_query()
                    .map(|p| p.as_str())
                    .unwrap_or("/"),
            );
            let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();

            let tid = match query.get("tid") {
                Some(tid) => tid,
                None => return Ok(crate::serve::server_error("tid parameter not found")),
            };

            let res = self.replay(&crate::rr::tid_to_path(tid.as_str())).unwrap();
            return Ok(crate::serve::redirect(res.final_url.as_str(), res.cookies));
        }

        let req = std::sync::Mutex::new(req);
        let this = std::panic::AssertUnwindSafe(self);
        let res = std::panic::catch_unwind(|| {
            let req = req.into_inner().unwrap();

            let (appended, req) = crate::utils::request_with_slash(req);

            if appended {
                return std::sync::Mutex::new(Ok(redirect(
                    req.uri().to_string().as_str(),
                    crate::context::cookies_from_request(&req),
                )));
            };

            let (res, ctx, req) = this.loop_till_no_realm_redirect(req, 5);

            let uri = req.uri();
            let url = crate::utils::to_url(uri.path_and_query().map(|p| p.as_str()).unwrap_or("/"));
            let url = crate::cleanup_url(&url);

            let r = match res.and_then(|r| r.render(&ctx, &url)).map(http_to_hyper) {
                Ok(a) => Ok(a),
                Err(e) => {
                    println!("error: {:?}", e);
                    Ok(crate::Response::plain(
                        &ctx,
                        format!("error: {:?}", e),
                        http::StatusCode::INTERNAL_SERVER_ERROR,
                    )
                    .and_then(|r| r.render(&ctx, &url))
                    .map(http_to_hyper)
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
                Ok(crate::serve::server_error("panic"))
            }
        }
    }

    fn handle_worker(&self, conn: &crate::base::pg::RealmConnection) -> crate::base::Result<usize> {
        let tasks = crate::worker::latest(conn, 5)?;
        let count = tasks.len();
        if count > 0 {
            println!("picked event from realm_task: {}", count);
        }
        for task in tasks.into_iter() {
            let method = {
                // TODO: use task.method
                http::Method::POST
            };
            match self.middleware.handle(&crate::Context::from(
                method,
                task.path.as_str(),
                task.data,
                serde_json::from_value(task.cookies)?,
            )) {
                Ok(_t) => {
                    crate::worker::updated_status(
                        conn,
                        task.id,
                        task.number_tries,
                        crate::worker::TaskStatus::Processed,
                    )?;
                    println!("task_processed: {}", task.id);
                    // observer::observe_string(
                    //     "task_processed",
                    //     format!("{}", task.id).as_str(),
                    // );
                }
                Err(e) => {
                    crate::worker::updated_status(
                        conn,
                        task.id,
                        task.number_tries,
                        crate::worker::TaskStatus::Failed,
                    )?;
                    println!("task_process_error: {}", e);
                    // observer::observe_string("process_err", format!("{}", e).as_str());
                }
            };
        }
        Ok(count)
    }

    pub fn worker(&self) {
        let conn = crate::base::pg::connection();
        println!("Starting realm::RealmService::worker");
        while !crate::env::ctrl_c().expect("ctrl-c issue") {
            let c = match self.handle_worker(&conn) {
                Ok(c) => c,
                Err(e) => {
                    observer::observe_string("main_process_err", format!("{}", e).as_str());
                    0
                }
            };
            if c == 0 {
                std::thread::sleep(std::time::Duration::from_secs(2));
            }
        }
    }

    pub fn http(self) {
        use futures::{stream::Stream, IntoFuture};
        use hyper::{rt::Future, Body};
        use std::sync::Arc;
        type BoxFut = Box<dyn Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

        if std::env::args().any(|e| e == "--replay") {
            match self.replay_all() {
                Ok(()) => println!("test passed"),
                Err(e) => {
                    match e.downcast_ref::<crate::Error>() {
                        Some(crate::Error::ReplayFailed { tid }) => {
                            println!("failed to run test: {}", tid);
                        }
                        _ => println!("exception during test: {:?}", e),
                    };
                }
            }
        } else {
            let this = Arc::new(self);

            let port = std::env::var("PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()
                .unwrap();
            let addr = ([0, 0, 0, 0], port).into();

            let server = hyper::Server::bind(&addr)
                .serve(move || {
                    let this = this.clone();
                    hyper::service::service_fn(move |req: hyper::Request<Body>| -> BoxFut {
                        let this = this.clone();
                        let (head, body) = req.into_parts();
                        Box::new(body.concat2().and_then(|body| {
                            let body = body.to_vec();
                            let req: crate::Request = http::Request::from_parts(head, body);
                            Box::new(
                                crate::THREAD_POOL
                                    .spawn_fn(move || this.handle_sync(req).into_future()),
                            )
                        }))
                    })
                })
                .map_err(|e| eprintln!("server error: {}", e));

            println!("Listening on http://{}", addr);
            hyper::rt::run(server);
        }
    }
}
