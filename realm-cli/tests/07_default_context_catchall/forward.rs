pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(&req)?;
    match input.path.as_str() {
        "/" => crate::routes::index::layout(&req),
        url_ => crate::cms::layout(&req, crate::cms::get_default_context(), url_),
    }
}