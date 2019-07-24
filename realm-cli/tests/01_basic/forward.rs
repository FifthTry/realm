pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(req)?;
    match input.path.as_str() {
        "/" => crate::routes::index::layout(&input.req),
        _ => unimplemented!(),
    }
}