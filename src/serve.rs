use futures_cpupool::{self, CpuPool};
use lazy_static::lazy_static;

lazy_static! {
    pub static ref THREAD_POOL: CpuPool = {
        let mut builder = futures_cpupool::Builder::new();
        builder.pool_size(2);
        builder.stack_size(16 * 1024 * 1024); // 16mb, default is 8mb
        builder.create()
    };
}

pub fn http_to_hyper(req: http::Response<Vec<u8>>) -> hyper::Response<hyper::Body> {
    let (parts, body) = req.into_parts();
    hyper::Response::from_parts(parts, hyper::Body::from(body))
}

#[macro_export]
macro_rules! realm {
    ($e:expr) => {
        pub fn main() {
            use futures::{self, stream::Stream, IntoFuture};
            use http;
            use hyper::{self, rt::Future, Body};
            use realm::{self, http_to_hyper, THREAD_POOL};
            use std::{self, thread};

            type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

            pub fn handle_sync(
                req: http::Request<Vec<u8>>,
            ) -> std::result::Result<hyper::Response<Body>, hyper::Error> {
                Ok($e(req)
                    .map(|r| http_to_hyper(r))
                    .unwrap_or_else(|e| http_to_hyper(e)))
            }

            pub fn serve() {
                let addr = ([127, 0, 0, 1], 3000).into();

                let server = hyper::Server::bind(&addr)
                    .serve(|| {
                        hyper::service::service_fn(|req: hyper::Request<Body>| -> BoxFut {
                            let (head, body) = req.into_parts();
                            Box::new(body.concat2().and_then(|body| {
                                let body = body.to_vec();
                                let req: http::Request<Vec<u8>> =
                                    http::Request::from_parts(head, body);
                                Box::new(
                                    THREAD_POOL.spawn_fn(move || handle_sync(req).into_future()),
                                )
                            }))
                        })
                    }).map_err(|e| eprintln!("server error: {}", e));

                println!("Listening on http://{}", addr);
                hyper::rt::run(server);
            }

            serve()
        }
    };
}
