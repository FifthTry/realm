pub fn get<UD>(in_: &crate::base::In<UD>) -> Result<crate::Response, crate::Error>
where
    UD: crate::UserData,
{
    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        });
    }

    Ok(crate::Response::Http(
        in_.ctx.response(
            crate::page::HTML_PAGE
                .replace("__realm_meta__", "")
                .replace("__realm_body__", "")
                .replace(
                    &format!("{}/elm.", &crate::page::CURRENT.to_string()),
                    "iframe.",
                )
                .into(),
        )?,
    ))
}
