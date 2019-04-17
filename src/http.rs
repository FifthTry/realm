use antidote::RwLock;
use futures_cpupool::{self, CpuPool};
use lazy_static::lazy_static;

pub struct Request {}
pub enum Response {}
pub type Result = std::result::Result<Response, hyper::Error>;

lazy_static! {
    pub static ref THREAD_POOL: CpuPool = {
        let mut builder = futures_cpupool::Builder::new();
        builder.pool_size(2);
        builder.stack_size(16 * 1024 * 1024); // 16mb, default is 8mb
        builder.create()
    };

    pub static ref GLOBALS: RwLock<i32> = {
        RwLock::new(42)
    };
}

#[macro_export]
macro_rules! realm {
    ($e:expr) => {
        pub fn main() {
            use futures::{self, IntoFuture};
            use hyper::{self, rt::Future, Body};
            use realm::{self, GLOBALS, THREAD_POOL};
            use std::{self, thread};

            type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

            pub fn handle_sync(
                _req: hyper::Request<Body>,
            ) -> std::result::Result<hyper::Response<Body>, hyper::Error> {
                let req: realm::Request = unimplemented!();
                $e(req).unwrap();
                unimplemented!()
            }

            pub fn serve() {
                let addr = ([127, 0, 0, 1], 3000).into();
                println!("main_: {:?}", thread::current().id());

                let server = hyper::Server::bind(&addr)
                    .serve(|| {
                        hyper::service::service_fn(|req: hyper::Request<Body>| -> BoxFut {
                            println!("future tid: {:?}", thread::current().id());
                            Box::new(THREAD_POOL.spawn_fn(|| {
                                let mut i = GLOBALS.write();
                                *i += 1;
                                let tid = thread::current().id();
                                println!("threadid: {:?}", thread::current().id());
                                println!("yo: {}, tid: {:?}", *i, tid);
                                handle_sync(req).into_future()
                            }))
                        })
                    }).map_err(|e| eprintln!("server error: {}", e));

                println!("Listening on http://{}", addr);
                hyper::rt::run(server);
            }
        }
    };
}
