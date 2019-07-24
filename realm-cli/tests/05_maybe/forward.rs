pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(req)?;
    match input.path.as_str() {
        "/" => {
            let m = input.get("m", true)?;
            crate::routes::index::layout(&input.req, m)
        },
        _ => unimplemented!(),
    }
}
