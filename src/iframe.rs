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
            r#"<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <title>Realm iFrame Controller</title>
        <meta name="viewport" content="width=device-width" />
    </head>
    <body>
        <script src='/static/iframe.js'></script>
    </body>
</html>"#
                .into(),
        )?,
    ))
}
