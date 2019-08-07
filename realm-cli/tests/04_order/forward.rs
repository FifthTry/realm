pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(&req)?;
    match input.path.as_str() {
        "/ab/c/" => crate::routes::ab_c::layout(&req),
        "/ab/" => crate::routes::ab::layout(&req),
        "/" => crate::routes::index::layout(&req),
        "/foo/" => crate::routes::foo::layout(&req),
        "/bar/" => crate::routes::bar::layout(&req),
        _ => unimplemented!(),
    }
}