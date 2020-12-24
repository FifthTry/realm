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
        <title>App Test</title>
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

pub fn realm<UD>(in_: &crate::base::In<UD>) -> Result<crate::Response, crate::Error>
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
        <title>Realm Test</title>
        <meta name="viewport" content="width=device-width" />
    </head>
    <body>
        <script src='/static/realm-test.js'></script>
    </body>
</html>"#
                .into(),
        )?,
    ))
}

#[cfg(feature = "postgres")]
pub fn reset_db<UD>(in_: &crate::base::In<UD>) -> Result<crate::Response, crate::Error>
where
    UD: crate::UserData,
{
    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        });
    }

    reset_schema(in_.conn)?;

    in_.reset_for_test();

    Ok(crate::Response::Http(in_.ctx.response("ok\n".into())?))
}

pub fn reset_schema(conn: &crate::base::pg::RealmConnection) -> Result<(), crate::Error> {
    use diesel::prelude::*;

    diesel::sql_query("DROP SCHEMA IF EXISTS test CASCADE;").execute(conn)?;

    let output = std::process::Command::new("psql")
        .args(&[
            "-d",
            std::env::var("DATABASE_URL")?.as_str(),
            "-f",
            "schema.sql",
        ])
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

    Ok(())
}

#[cfg(not(feature = "postgres"))]
pub fn reset_db<UD>(in_: &crate::base::In<UD>) -> Result<crate::Response, crate::Error>
where
    UD: crate::UserData,
{
    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        });
    }

    // Copy pristine.db to hello.db
    std::fs::copy("pristine.db", "hello.db")?;

    in_.reset_ud();

    Ok(crate::Response::Http(in_.ctx.response("ok\n".into())?))
}
