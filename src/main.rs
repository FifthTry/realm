use hyper::{self, rt::Future, Body, Request};

type BoxFut = Box<Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

pub fn main<F>(_addr: &str, _handler: F)
where
    F: Fn(crate::Request) -> crate::Result,
{
    let addr = ([127, 0, 0, 1], 3000).into();

    let server = hyper::Server::bind(&addr)
        .serve(|| hyper::service::service_fn(|_req: Request<Body>| -> BoxFut { unimplemented!() }))
        .map_err(|e| eprintln!("server error: {}", e));

    println!("Listening on http://{}", addr);
    hyper::rt::run(server);
}
