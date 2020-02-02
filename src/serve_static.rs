use observer::prelude::*;

#[observed(with_result, namespace = "realm")]
pub fn serve_static(ctx: &crate::Context) -> Result<crate::Response, failure::Error> {
    let start = std::time::Instant::now();
    let path = ctx.request.uri().path();
    let mime = mime_guess::from_path(&path).first_or_text_plain();

    observe_field("mime", mime.to_string().as_str());

    let path = if path == "/favicon.ico" {
        "/static/favicon.ico"
    } else {
        path
    };

    let cache_control = if path.contains(".hashed-") {
        "immutable, public, max-age=3600000000"
    } else {
        ""
    };

    observe_field("cache_control", cache_control);

    if ctx
        .request
        .headers()
        .get("Accept-Encoding")
        .map(|v| format!("{:?}", v).contains("br"))
        .unwrap_or(false)
    {
        if let Ok(content) = static_content((path.to_string() + ".br").as_str())
            .or_else(|_| static_content(&format!("{}.br", path)))
        {
            println!(
                "ok: br {:?} {} in {}",
                ctx.request.method(),
                path,
                crate::base::elapsed(start)
            );
            return Ok(crate::Response::Http(
                http::Response::builder()
                    .header("Cache-Control", cache_control)
                    .header("Content-Encoding", "br")
                    .header("Content-Type", mime.to_string())
                    .status(http::StatusCode::OK)
                    .body(content)?,
            ));
        };
    }
    if ctx
        .request
        .headers()
        .get("Accept-Encoding")
        .map(|v| format!("{:?}", v).contains("gzip"))
        .unwrap_or(false)
    {
        if let Ok(content) = static_content((path.to_string() + ".gz").as_str())
            .or_else(|_| static_content(&format!("{}.gz", path)))
        {
            println!(
                "ok: gz {:?} {} in {}",
                ctx.request.method(),
                path,
                crate::base::elapsed(start)
            );
            return Ok(crate::Response::Http(
                http::Response::builder()
                    .header("Cache-Control", cache_control)
                    .header("Content-Encoding", "gzip")
                    .header("Content-Type", mime.to_string())
                    .status(http::StatusCode::OK)
                    .body(content)?,
            ));
        };
    }

    match static_content(path) {
        Ok(content) => {
            println!(
                "ok: {:?} {} in {}",
                ctx.request.method(),
                path,
                crate::base::elapsed(start)
            );
            Ok(crate::Response::Http(
                http::Response::builder()
                    .header("Cache-Control", cache_control)
                    .header("Content-Type", mime.to_string())
                    .status(http::StatusCode::OK)
                    .body(content)?,
            ))
        }
        Err(e) => {
            eprintln!("err: {} {}", e.to_string(), path);
            Ok(crate::Response::Http(
                http::Response::builder()
                    .status(http::StatusCode::NOT_FOUND)
                    .body(format!("no such file: {}", path).into())?,
            ))
        }
    }
}

pub fn static_content(src: &str) -> Result<Vec<u8>, failure::Error> {
    use std::io::Read;

    let path = std::fs::canonicalize(".".to_string() + src)?;
    if !path.starts_with(std::env::current_dir()?) {
        return Err(failure::err_msg("outside file rejected"));
    }

    let mut file = std::fs::File::open(&path)?;

    let mut content = Vec::new();
    file.read_to_end(&mut content)?;
    Ok(content)
}
