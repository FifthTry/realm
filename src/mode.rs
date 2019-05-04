pub enum Mode {
    API,
    Layout,
    HTML,
}

impl Mode {
    pub fn detect(req: &crate::Request) -> Mode {
        let url = url::Url::parse(&format!(
            "http://foo.com/?{}",
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
            Some("html") => return Mode::HTML,
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
}
