pub fn magic(req: realm::Request) -> realm::Result {
    let mut input = realm::request_config::RequestConfig::new(req)?;
    match input.path.as_str() {
        "/" => {
            let i = input.get("i", false)?;
            crate::routes::index::layout(&input.req, i)
        },
        _ => unimplemented!(),
    }
}