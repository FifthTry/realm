use antidote::RwLock;
use futures::{self, IntoFuture};
use futures_cpupool::{self, CpuPool};
use hyper::{self, rt::Future, Body};
use lazy_static::lazy_static;
use std::{self, thread};

pub struct Request {}
pub enum Response {}
pub type Result = std::result::Result<Response, hyper::Error>;
type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

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

pub fn serve<F>(_addr: &str, _handler: F)
where
    F: Fn(Request) -> Result,
{
    let addr = ([127, 0, 0, 1], 3000).into();
    println!("main_: {:?}", thread::current().id());

    let server = hyper::Server::bind(&addr)
        .serve(|| {
            hyper::service::service_fn(|_req: hyper::Request<Body>| -> BoxFut {
                println!("future tid: {:?}", thread::current().id());
                Box::new(THREAD_POOL.spawn_fn(move || {
                    let mut i = GLOBALS.write();
                    *i += 1;
                    let tid = thread::current().id();
                    println!("threadid: {:?}", thread::current().id());
                    println!("yo: {}, tid: {:?}", *i, tid);
                    let x: std::result::Result<
                        hyper::Response<Body>,
                        hyper::Error,
                    > = unimplemented!();
                    x.into_future()
                }))
            })
        }).map_err(|e| eprintln!("server error: {}", e));

    println!("Listening on http://{}", addr);
    hyper::rt::run(server);
}
