use diesel::prelude::*;

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
        <script src='/static/test.js'></script>
    </body>
</html>"#
                .into(),
        )?,
    ))
}

pub fn reset_db(in_: &crate::base::In) -> Result<crate::Response, crate::Error> {
    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        });
    }

    diesel::sql_query("DROP SCHEMA IF EXISTS test CASCADE;").execute(in_.conn)?;

    let output = std::process::Command::new("psql")
        .args(&["-d", "amitu_heroku", "-f", "schema.sql"])
        .output()
        .unwrap();

    if !output.status.success() {
        eprintln!("psql failed");
        eprintln!("stdout: {}", std::str::from_utf8(&output.stdout).unwrap());
        eprintln!("stderr: {}", std::str::from_utf8(&output.stderr).unwrap());
        return Err(crate::Error::CustomError {
            message: "psql failed".to_string(),
        });
    };

    in_.logout();

    Ok(crate::Response::Http(in_.ctx.response("ok\n".into())?))
}
