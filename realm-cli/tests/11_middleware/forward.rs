pub fn magic(ireq: crate::in_::In) -> realm::Result {
    let req = ireq.realm_request;
    let input = realm::request_config::RequestConfig::new(req)?;
    match input.path.as_str() {
            url_ => crate::cms::layout(&input.req, crate::cms::get_context("cms"), url_),
        "/" => crate::routes::index::layout(&input.req,),
        _ => unimplemented!()
    }
}
