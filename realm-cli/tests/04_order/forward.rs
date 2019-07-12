pub fn magic(req: &realm::Request) -> realm::Result {
    let path = realm::utils::get_slash_complete_path(req.uri().path());
    match path.as_ref() {
        "/foo/" => crate::routes::foo::layout(req, 0),
        "/bar/" => crate::routes::foo::layout(req, 0),
        "/ab/c/" => crate::routes::foo::layout(req, 0),
        "/ab/" => crate::routes::foo::layout(req, 0),
        "/" => crate::routes::index::layout(req, 0),
        _ => unimpemented!()
    }
}
