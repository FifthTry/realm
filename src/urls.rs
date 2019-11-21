pub fn is_realm_url(p: (&str, &http::Method)) -> bool {
    match p {
        ("/storybook/", &http::Method::GET) => true,
        ("/storybook/poll/", &http::Method::GET) => true,
        ("/test/", &http::Method::GET) => true,
        ("/test/reset-db/", &http::Method::GET) => true,
        ("/test/reset-db/", &http::Method::POST) => true,
        ("/iframe/", &http::Method::GET) => true,
        _ => false,
    }
}

pub fn handle(
    in_: &crate::base::In,
    p: (&str, &http::Method),
    input: &mut crate::request_config::RequestConfig,
) -> Result<crate::Response, failure::Error> {
    match p {
        ("/storybook/", &http::Method::GET) => crate::storybook::get(in_).map_err(Into::into),
        ("/storybook/poll/", &http::Method::GET) => {
            let hash = input.required("hash")?;
            crate::watcher::poll(in_.ctx, hash).map_err(Into::into)
        }
        ("/test/", &http::Method::GET) => crate::test::get(in_).map_err(Into::into),
        ("/test/reset-db/", &http::Method::GET) => crate::test::reset_db(in_).map_err(Into::into),
        ("/test/reset-db/", &http::Method::POST) => crate::test::reset_db(in_).map_err(Into::into),
        ("/iframe/", &http::Method::GET) => crate::iframe::get(in_).map_err(Into::into),
        _ => unimplemented!(),
    }
}
