pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(req)?;
    match input.path.as_str() {
        "/ab/c/" => crate::routes::ab_c::layout(&input.req),
        "/ab/" => crate::routes::ab::layout(&input.req),
        "/" => crate::routes::index::layout(&input.req),
        "/foo/" => crate::routes::foo::layout(&input.req),
        "/bar/" => crate::routes::bar::layout(&input.req),
        _ => unimplemented!(),
    }
}