pub struct Context {
    pub method: http::Method,
    pub url: url::Url,
    pub query: std::collections::HashMap<String, String>,
    pub headers: http::HeaderMap<http::HeaderValue>,
    cookies: std::collections::HashMap<String, String>,
    set_cookies: std::cell::RefCell<std::collections::HashMap<String, String>>,
    context: std::cell::RefCell<std::collections::HashMap<String, String>>,
    pub(crate) body: serde_json::Value,
    pub mode: crate::Mode,
    pub is_crawler: bool,
    builder: std::cell::RefCell<http::response::Builder>,
    pub(crate) record: Option<String>,
    step: std::cell::RefCell<Option<crate::rr::Step>>,
    is_test: bool,
    meta: std::cell::RefCell<crate::HTMLMeta>,
}

pub fn cookies_from_request(
    req: &http::request::Request<Vec<u8>>,
) -> std::collections::HashMap<String, String> {
    req.headers()
        .get(http::header::COOKIE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .split(';')
        .map(|v| match cookie::Cookie::parse_encoded(v) {
            Ok(c) => (c.name().to_string(), c.value().to_string()),
            Err(_) => ("".to_string(), "".to_string()),
        })
        .collect()
}

impl Context {
    pub fn from(
        method: http::Method,
        path: &str,
        body: serde_json::Value,
        cookies: std::collections::HashMap<String, String>,
    ) -> Self {
        let url = crate::utils::to_url(path);
        let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();

        Context {
            method,
            headers: http::HeaderMap::default(),
            cookies,
            set_cookies: std::cell::RefCell::new(std::collections::HashMap::new()),
            context: std::cell::RefCell::new(std::collections::HashMap::new()),
            url,
            body,
            meta: std::cell::RefCell::new(Default::default()),
            mode: crate::Mode::ISED,
            is_crawler: false,
            query,
            builder: std::cell::RefCell::new(http::response::Builder::new()),
            record: None,
            step: std::cell::RefCell::new(None),
            is_test: true,
        }
    }

    pub fn meta(&self) -> std::cell::RefMut<crate::HTMLMeta> {
        self.meta.borrow_mut()
    }

    pub(crate) fn set_step(&self, step: crate::rr::Step) {
        self.step.replace(Some(step));
    }

    pub fn get_step(&self) -> Option<crate::rr::Step> {
        self.step.replace(None)
    }

    pub fn from_request(req: &http::request::Request<Vec<u8>>) -> Self {
        let url = url::Url::parse(format!("http://foo.com{}", req.uri()).as_str()).unwrap();
        let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();

        let cookies = cookies_from_request(req);

        let method = req.method().to_owned();
        let headers = req.headers().to_owned();
        let path = req.uri().path().to_string();
        let is_crawler = Context::is_crawler_(&query, &method, &headers);
        let mode = Context::detect_mode(&query, path.as_str(), is_crawler, &method);
        let body = serde_json::from_slice(req.body().as_slice()).unwrap_or(serde_json::Value::Null);

        Context {
            method,
            headers,
            url,
            mode,
            is_crawler,
            body,
            builder: std::cell::RefCell::new(http::response::Builder::new()),
            query,
            record: cookies.get(crate::rr::COOKIE_NAME).map(String::to_string),
            cookies,
            set_cookies: std::cell::RefCell::new(std::collections::HashMap::new()),
            context: std::cell::RefCell::new(std::collections::HashMap::new()),
            step: std::cell::RefCell::new(None),
            is_test: false,
            meta: std::cell::RefCell::new(Default::default()),
        }
    }

    fn detect_mode(
        query: &std::collections::HashMap<String, String>,
        path: &str,
        is_crawler: bool,
        method: &http::Method,
    ) -> crate::Mode {
        // overwrite parameter: mode, if realm_mode named query parameter is set, it is used
        match query.get("realm_mode").map(String::as_str) {
            Some("api") => return crate::Mode::API,
            Some("pure") => return crate::Mode::Pure,
            Some("ised") => return crate::Mode::ISED,
            Some("submit") => return crate::Mode::Submit,
            Some("html") => return crate::Mode::HTML,
            Some("ssr") => return crate::Mode::SSR,
            _ => {}
        };

        // if url contains /api/, by default we pick API
        if path.starts_with("/api/") {
            return crate::Mode::API;
        };

        if method == http::Method::GET {
            return if is_crawler {
                crate::Mode::SSR
            } else {
                crate::Mode::HTML
            };
        };

        crate::Mode::API
    }

    fn is_crawler_(
        query: &std::collections::HashMap<String, String>,
        method: &http::Method,
        headers: &http::HeaderMap<http::HeaderValue>,
    ) -> bool {
        if query.contains_key("is_crawler") {
            return true;
        }

        if method == http::method::Method::HEAD {
            return true;
        }

        if let Some(ua) = headers
            .get(http::header::USER_AGENT)
            .and_then(|v| v.to_str().ok())
        {
            {
                let ua = ua.to_lowercase();
                // https://github.com/monperrus/crawler-user-agents/blob/master/crawler-user-agents.json
                if ua.contains("google")
                    || ua.contains("bot")
                    || ua.contains("crawl")
                    || ua.contains("spider")
                    || ua.contains("bing")
                    || ua.contains("facebook")
                    || ua.contains("yahoo")
                    || ua.contains("baidu")
                    || ua.contains("python")
                    || ua.contains("curl")
                    || ua.contains("wget")
                    || ua.contains("archive")
                    || ua.contains("twingly")
                    || ua.contains("rss")
                    || ua.contains("bot")
                {
                    return true;
                }
            }
            woothee::is_crawler(ua)
        } else {
            false
        }
    }

    pub fn get_cookie(&self, name: &str) -> Option<&str> {
        self.cookies.get(name).map(|v| v.as_str())
    }

    pub fn get_header<K>(&self, key: K) -> Option<&http::HeaderValue>
    where
        K: http::header::AsHeaderName,
    {
        self.headers.get(key)
    }

    pub fn get_header_string<K>(&self, key: K) -> Option<String>
    where
        K: http::header::AsHeaderName,
    {
        self.get_header(key)
            .and_then(|v| v.to_str().ok())
            .map(|v| v.to_string())
    }

    pub fn remote_ip(&self) -> String {
        "127.0.0.1".to_string()
    }

    pub fn pm(&self) -> (&str, &http::Method) {
        let method = match &self.method {
            &http::Method::HEAD => &http::Method::GET,
            m => m,
        };
        (self.url.path(), method)
    }

    pub fn input(&self) -> Result<crate::RequestConfig, failure::Error> {
        crate::RequestConfig::new(&self.query, self.url.path(), self.body.clone())
    }

    pub fn status(&self, status: http::StatusCode) {
        self.builder.borrow_mut().status(status);
    }

    pub fn delete_cookie(&self, name: &str) {
        observer::observe_string("deleting_cookie", name);
        self.cookie(name, "", 0);
    }

    pub fn cookie(&self, name: &str, value: &str, age: i64) {
        if name != "vid" && name != "tid" {
            observer::observe_string("cookie_name", name);
            observer::transient_string("cookie_value", value);
            observer::observe_i64("cookie_age", age);
        }

        self.set_cookies
            .borrow_mut()
            .insert(name.to_string(), value.to_string());

        self.header(
            http::header::SET_COOKIE,
            crate::utils::set_cookie(name, value, age),
        );
    }

    pub fn update_context(&self, name: &str, value: &str) {
        self.context
            .borrow_mut()
            .insert(name.to_string(), value.to_string());
    }

    pub fn merge_cookies(&self, c: &mut std::collections::HashMap<String, String>) {
        for (key, value) in self.set_cookies.borrow().iter() {
            if value.is_empty() {
                c.remove(key);
            } else {
                c.insert(key.to_string(), value.to_string());
            }
        }
    }

    pub fn get_context(&self) -> std::collections::HashMap<String, String> {
        self.context.borrow().to_owned()
    }

    pub(crate) fn user_agent(&self) -> Option<String> {
        if self.is_test {
            Some("yo".to_string())
        } else {
            self.get_header_string(http::header::USER_AGENT)
        }
    }

    pub fn header<K, V>(&self, key: K, value: V)
    where
        http::header::HeaderName: http::HttpTryFrom<K>,
        http::header::HeaderValue: http::HttpTryFrom<V>,
    {
        self.builder.borrow_mut().header(key, value);
    }

    pub fn response<T>(&self, body: T) -> Result<http::response::Response<T>, crate::Error> {
        self.builder
            .replace(http::response::Builder::new())
            .body(body)
            .map_err(|e| e.into())
    }

    pub fn get_body(&self) -> String {
        self.body.to_string()
    }
}
