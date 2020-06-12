pub fn is_realm_url(p: (&str, &http::Method)) -> bool {
    match p {
        ("/storybook/", &http::Method::GET) => true,
        ("/storybook/poll/", &http::Method::GET) => true,
        ("/test/", &http::Method::GET) => true,
        ("/test/reset-db/", &http::Method::GET) => true,
        ("/test/reset-db/", &http::Method::POST) => true,
        ("/iframe/", &http::Method::GET) => true,
        ("/favicon.ico", &http::Method::GET) => true,
        (t, &http::Method::GET) if t.starts_with("/static/") => true,
        _ => false,
    }
}

#[observed(with_result, namespace = "realm")]
pub fn handle<UD>(
    in_: &crate::base::In<UD>,
    p: (&str, &http::Method),
    input: &mut crate::request_config::RequestConfig,
) -> Result<crate::Response, failure::Error>
where
    UD: crate::UserData,
{
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
        ("/favicon.ico", &http::Method::GET) => {
            crate::serve_static::serve_static(in_.ctx).map_err(Into::into)
        }
        (t, &http::Method::GET) if t.starts_with("/static/") => {
            crate::serve_static::serve_static(in_.ctx).map_err(Into::into)
        }
        _ => unreachable!(),
    }
}
