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

pub fn server_error(msg: Vec<u8>) -> hyper::Response<hyper::Body> {
    let mut resp = hyper::Response::default();
    *resp.status_mut() = http::StatusCode::INTERNAL_SERVER_ERROR;
    *resp.body_mut() = hyper::Body::from(msg);
    resp
}

#[macro_export]
macro_rules! realm_serve {
    ($e:expr) => {{
        use futures::{stream::Stream, IntoFuture};
        use hyper::{rt::Future, Body};

        type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

        pub fn handle_sync(
            req: realm::Request,
        ) -> std::result::Result<hyper::Response<Body>, hyper::Error> {
            let req = std::sync::Mutex::new(req);
            let res = std::panic::catch_unwind(|| {
                let req = req.into_inner().unwrap();
                let url = req
                    .uri()
                    .path_and_query()
                    .map(|p| p.as_str().to_string())
                    .unwrap_or_else(|| "/".to_string());
                let url = url.replace("&realm_mode=ised", "");
                let url = url.replace("&realm_mode=pure", "");
                // TODO: these two statements are safe only if realm_mode is
                //       always the last parameter, which it is so far, but we
                //       need more robust mechanism.
                let url = url.replace("?realm_mode=ised", "");
                let url = url.replace("?realm_mode=pure", "");
                let ctx = {
                    let mode = realm::Mode::detect(&req);
                    realm::Context::new(req, mode)
                };

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
                    Ok(realm::serve::server_error("panic".to_string().into_bytes()))
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

        serve()
    }};
}

#[macro_export]
macro_rules! realm {
    ($e:expr) => {
        pub fn main() {
            realm::realm_serve!($e)
        }
    };
}
