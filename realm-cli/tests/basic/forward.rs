pub fn magic(req: &realm::Request) -> realm::Result {
    let path = realm::utils::get_slash_complete_path(req.uri());
    match path.as_ref() {
        "/" => crate::routes::index::layout(req, 0),
        url_ => crate::cms::layout(req, url_),
    }
}

