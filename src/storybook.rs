pub fn get(in_: &crate::base::In) -> Result<crate::Response, crate::Error> {
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
        <title>Test</title>
        <meta name="viewport" content="width=device-width" />
    </head>
    <body>
        <script src='/static/storybook.js'></script>
    </body>
</html>"#
                .into(),
        )?,
    ))
}
