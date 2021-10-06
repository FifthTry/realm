#[observed(with_result, namespace = "realm")]
pub fn serve_static(ctx: &crate::Context) -> Result<crate::Response, failure::Error> {
    let start = std::time::Instant::now();
    let path = ctx.url.path();
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
        .get_header("Accept-Encoding")
        .map(|v| format!("{:?}", v).contains("br"))
        .unwrap_or(false)
    {
        if let Ok(content) = static_content((path.to_string() + ".br").as_str())
            .or_else(|_| static_content(&format!("{}.br", path)))
        {
            println!(
                "ok: br {:?} {} in {}",
                &ctx.method,
                path,
                crate::base::elapsed(start)
            );
            return Ok(crate::Response::Http(
                http::Response::builder()
                    .header("Cache-Control", cache_control)
                    .header("Content-Encoding", "br")
                    .header("Content-Type", mime.to_string())
                    .header("Service-Worker-Allowed", "/")
                    .status(http::StatusCode::OK)
                    .body(content)?,
            ));
        };
    }
    if ctx
        .get_header("Accept-Encoding")
        .map(|v| format!("{:?}", v).contains("gzip"))
        .unwrap_or(false)
    {
        if let Ok(content) = static_content((path.to_string() + ".gz").as_str())
            .or_else(|_| static_content(&format!("{}.gz", path)))
        {
            println!(
                "ok: gz {:?} {} in {}",
                &ctx.method,
                path,
                crate::base::elapsed(start)
            );
            return Ok(crate::Response::Http(
                http::Response::builder()
                    .header("Cache-Control", cache_control)
                    .header("Content-Encoding", "gzip")
                    .header("Content-Type", mime.to_string())
                    .header("Service-Worker-Allowed", "/")
                    .status(http::StatusCode::OK)
                    .body(content)?,
            ));
        };
    }

    match static_content(path) {
        Ok(content) => Ok(crate::Response::Http(
            http::Response::builder()
                .header("Cache-Control", cache_control)
                .header("Content-Type", mime.to_string())
                .header("Service-Worker-Allowed", "/")
                .status(http::StatusCode::OK)
                .body(content)?,
        )),
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

lazy_static! {
    pub static ref ELM: std::io::Result<Vec<u8>> = read_static(PrefixSuffix::Elm);
    pub static ref ELM_GZ: std::io::Result<Vec<u8>> = read_static(PrefixSuffix::ElmGz);
    pub static ref ELM_BR: std::io::Result<Vec<u8>> = read_static(PrefixSuffix::ElmBr);
    pub static ref SW: std::io::Result<Vec<u8>> = read_static(PrefixSuffix::Sw);
}

fn read_static(pre_suffix: PrefixSuffix) -> std::io::Result<Vec<u8>> {
    let proj_dir = std::env::current_dir().map_err(|e| {
        println!("read_static_err: {}", e.to_string());
        e
    })?;
    let (prefix, suffix) = pre_suffix.to_str();
    let path = proj_dir.join(format!(
        "static/{}.{}.js{}",
        prefix,
        crate::page::read_current(),
        suffix
    ));
    std::fs::read(path.as_path()).map_err(|e| {
        println!(
            "path_not_found: {:?}, err: {}",
            path.as_os_str(),
            e.to_string()
        );
        e
    })
}

enum PrefixSuffix {
    Elm,   // "elm", ""
    ElmGz, // "elm", ".gz"
    ElmBr, // "elm", ".br"
    Sw,    // "sw", ""
}

impl PrefixSuffix {
    pub fn to_str(&self) -> (&str, &str) {
        match self {
            Self::Elm => ("elm", ""),
            Self::ElmGz => ("elm", ".gz"),
            Self::ElmBr => ("elm", ".br"),
            Self::Sw => ("sw", ""),
        }
    }
}

fn get_static(pre_suffix: PrefixSuffix) -> Result<Vec<u8>, failure::Error> {
    if cfg!(debug_assertions) {
        read_static(pre_suffix).map_err(|e| failure::err_msg(format!("{}", e)))
    } else {
        match match pre_suffix {
            PrefixSuffix::Elm => ELM.as_ref(),
            PrefixSuffix::ElmGz => ELM_GZ.as_ref(),
            PrefixSuffix::ElmBr => ELM_BR.as_ref(),
            PrefixSuffix::Sw => SW.as_ref(),
        } {
            Ok(t) => Ok(t.clone()),
            Err(e) => Err(failure::err_msg(format!("{}", e))),
        }
    }
}

pub fn static_content(src: &str) -> Result<Vec<u8>, failure::Error> {
    use std::io::Read;

    if src.starts_with("/static/elm.hashed-") {
        if !src.contains(crate::page::CURRENT.as_str()) {
            observer::log("fetched latest elm when old was requested");
        }

        return Ok(if src.ends_with(".js") {
            get_static(PrefixSuffix::Elm)?
        } else if src.ends_with(".js.gz") {
            get_static(PrefixSuffix::ElmGz)?
        } else {
            get_static(PrefixSuffix::ElmBr)?
        });
    }

    if src.starts_with("/static/sw.hashed-") {
        if !src.contains(crate::page::CURRENT.as_str()) {
            observer::log("fetched latest sw when old was requested");
        }

        return Ok(if src.ends_with(".js") {
            get_static(PrefixSuffix::Sw)?
        } else {
            return Err(failure::err_msg("not found"));
        });
    }

    let path = std::fs::canonicalize(".".to_string() + src)?;
    if !path.starts_with(std::env::current_dir()?) {
        return Err(failure::err_msg("outside file rejected"));
    }

    let mut file = std::fs::File::open(&path)?;

    let mut content = Vec::new();
    file.read_to_end(&mut content)?;
    Ok(content)
}
