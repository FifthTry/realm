pub enum Mode {
    API,
    Layout,
    HTML,
    HTMLExplicit,
    Submit,
    SSR,
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
            Some("layout") => return Mode::Layout,
            Some("submit") => return Mode::Submit,
            Some("html") => return Mode::HTMLExplicit,
            Some("ssr") => return Mode::SSR,
            _ => {}
        };

        // if url contains /api/, by default we pick API
        if req.uri().path().starts_with("/api/") {
            return Mode::API;
        };

        if req.method() == http::Method::GET {
            return Mode::HTML;
        };

        Mode::API
    }
    pub fn content_type(&self) -> http::HeaderValue {
        http::HeaderValue::from_static(match self {
            Mode::HTML => "text/html",
            _ => "application/json; charset=utf-8",
        })
    }
}
