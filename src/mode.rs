#[derive(PartialEq)]
pub enum Mode {
    API,
    ISED,
    HTML,
    Submit,
    SSR,
    Pure,
}

impl Mode {
    pub fn detect(req: &crate::Request) -> Mode {
        let url = url::Url::parse(&format!(
            "http://f.com/?{}",
            req.uri().query().unwrap_or("")
        ));
        let q: std::collections::HashMap<String, String> = match url {
            Ok(parsed_url) => parsed_url.query_pairs().into_owned().collect(),
            _ => std::collections::HashMap::new(),
        };

        // overwrite parameter: mode, if realm_mode named query parameter is set, it is used
        match q.get("realm_mode").map(String::as_str) {
            Some("api") => return Mode::API,
            Some("pure") => return Mode::Pure,
            Some("ised") => return Mode::ISED,
            Some("submit") => return Mode::Submit,
            Some("html") => return Mode::HTML,
            Some("ssr") => return Mode::SSR,
            _ => {}
        };

        // if url contains /api/, by default we pick API
        if req.uri().path().starts_with("/api/") {
            return Mode::API;
        };

        if req.method() == http::Method::GET {
            return if crate::context::is_crawler(req) {
                Mode::SSR
            } else {
                Mode::HTML
            };
        };

        Mode::API
    }

    pub fn content_type(&self) -> http::HeaderValue {
        http::HeaderValue::from_static(match self {
            Mode::HTML => "text/html",
            Mode::SSR => "text/html",
            _ => "application/json; charset=utf-8",
        })
    }

    pub fn is_pure(&self) -> bool {
        std::env::var("REALM_PURE")
            .map(|v| !v.trim().is_empty())
            .unwrap_or(false)
            && (self == &Mode::Pure || self == &Mode::HTML || self == &Mode::SSR)
    }
}
