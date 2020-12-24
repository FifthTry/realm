#[observed(with_result, namespace = "realm__storybook")]
pub fn get<UD>(in_: &crate::base::In<UD>) -> Result<crate::Response, crate::Error>
where
    UD: crate::UserData,
{
    let referer_ = in_.ctx.get_header_string(http::header::REFERER);
    let referer = referer_.as_deref().unwrap_or("none");

    let allowed_refs_ = std::env::var("REALM_ALLOWED_SB_REFERERS");
    let allowed_refs = allowed_refs_.unwrap_or_else(|_| String::from(""));

    allowed(crate::base::is_test(), referer, &allowed_refs[..])?;

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

fn allowed(is_test: bool, referer: &str, allowed_refs: &str) -> Result<(), crate::Error> {
    if is_test {
        return Ok(());
    }

    if referer == "none" {
        observer::log("not_in_test_mode, returning 404");
        return Err(crate::Error::PageNotFound {
            message: "Server not running in test mode".to_string(),
        });
    }

    if is_ref_allowed(referer, allowed_refs) {
        return Ok(());
    }

    observer::log("referer_not_allowed, returning 404");
    Err(crate::Error::PageNotFound {
        message: format!("Referer: {} not allowed", referer),
    })
}

fn is_ref_allowed(referer: &str, allowed_refs: &str) -> bool {
    let local_referers: Vec<&str> = [
        "http://127.0.0.1:3000/",
        "http://localhost:3000/",
        "http://0.0.0.0:3000/",
    ]
    .to_vec();
    let ar: Vec<&str> = allowed_refs.split(',').collect();

    local_referers
        .into_iter()
        .chain(ar.into_iter())
        .any(|x| referer.starts_with(x))
}

#[cfg(test)]
mod tests {
    use super::allowed;

    #[test]
    fn allowed_in_test_mode() {
        match allowed(true, "none", "") {
            Ok(_) => assert!(true),
            Err(_) => assert!(false, "Should be allowed in test mode"),
        }
    }

    #[test]
    fn allowed_referer_set() {
        match allowed(
            false,
            "https://www.yahoo.com/",
            "https://www.yahoo.com/,http://google.com/",
        ) {
            Ok(_) => assert!(true),
            Err(_) => assert!(false, "Should be allowed with correct referer"),
        }
    }

    #[test]
    fn not_allowed_referer_not_set() {
        match allowed(false, "none", "") {
            Ok(_) => assert!(false, "Should not be allowed without referer"),
            Err(_) => assert!(true),
        }
    }

    #[test]
    fn not_allowed_wrong_referer() {
        match allowed(false, "wrong referer", "") {
            Ok(_) => assert!(false, "Should not be allowed with wrong referer"),
            Err(_) => assert!(true),
        }
    }
}
