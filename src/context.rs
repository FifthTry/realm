use woothee;
pub struct Context {
    pub request: http::request::Request<Vec<u8>>,
    builder: std::cell::RefCell<http::response::Builder>,
}

impl Context {
    pub fn new(request: http::request::Request<Vec<u8>>) -> Self {
        Context {
            request,
            builder: std::cell::RefCell::new(http::response::Builder::new()),
        }
    }

    pub fn pm(&self) -> (&str, &http::Method) {
        (self.request.uri().path(), self.request.method())
    }

    pub fn is_crawler(&self) -> bool {
        // either useragent is bot: woothee::is_crawler
        // or query params is_crawler is set to any value

        if self.request.uri().to_string().contains("is_crawler=") {
            return true;
        }

        if let Some(ua) = self
            .request
            .headers()
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
                {
                    return true;
                }
            }
            woothee::is_crawler(ua)
        } else {
            false
        }
    }

    pub fn status(&self, status: http::StatusCode) {
        self.builder.borrow_mut().status(status);
    }

    pub fn cookie(&self, name: &str, value: &str, age: i32) {
        match crate::utils::set_cookie(name, value, age) {
            Ok(c) => self.header(http::header::SET_COOKIE, c),
            Err(e) => eprintln!("cant write cookie: {:?}", e),
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
}
