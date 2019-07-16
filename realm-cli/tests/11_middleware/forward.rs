pub fn magic(ireq: &crate::in_::In) -> realm::Result {
    let req = ireq.realm_request;
    let mut input = realm::RequestConfig::new(req);

    match input.path.as_str() {
        "/" => crate::routes::index::layout(&ireq),
        _ => unimplemented!()
    }
}
