use futures::{stream::Stream, IntoFuture};
use hyper::{rt::Future, Body};

type BoxFut = Box<dyn Future<Item = hyper::Response<Body>, Error = hyper::Error> + Send>;

lazy_static! {
    pub static ref THREAD_POOL: futures_cpupool::CpuPool = {
        let mut builder = futures_cpupool::Builder::new();
        builder.pool_size(2);
        builder.stack_size(16 * 1024 * 1024); // 16mb, default is 8mb
        builder.create()
    };
}

pub fn http_to_hyper(resp: http::Response<Vec<u8>>) -> hyper::Response<hyper::Body> {
    let (parts, body) = resp.into_parts();
    hyper::Response::from_parts(parts, hyper::Body::from(body))
}

pub fn handle_sync<F>(
    req: crate::Request,
    f: F,
) -> std::result::Result<hyper::Response<Body>, hyper::Error>
where
    F: Fn(&crate::Context) -> Result<crate::Response, failure::Error> + Send + Sync + 'static,
{
    let mode = crate::Mode::detect(&req);
    let url = req.uri().path().to_string();
    let ctx = crate::Context::new(req);

    match f(&ctx)
        .and_then(|r| r.render(&ctx, mode, url))
        .map(|r| http_to_hyper(r))
    {
        Ok(a) => Ok(a),
        Err(e) => {
            println!("error : {:?}", e);
            unimplemented!()
        }
    }
}

pub fn serve<F>(f: F)
where
    F: Fn(&crate::Context) -> Result<crate::Response, failure::Error> + Send + Sync + 'static,
{
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
                    let req: crate::Request = http::Request::from_parts(head, body);
                    Box::new(THREAD_POOL.spawn_fn(move || handle_sync(req, f).into_future()))
                }))
            })
        }).map_err(|e| eprintln!("server error: {}", e));

    println!("Listening on http://{}", addr);
    hyper::rt::run(server);
}

pub fn handle<F>(f: F)
where
    F: Fn(&crate::Context) -> Result<crate::Response, failure::Error> + Send + Sync + 'static,
{
    serve(f)
}
