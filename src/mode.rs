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

    pub fn as_str(&self) -> &'static str {
        match self {
            Mode::API => "API",
            Mode::ISED => "ISED",
            Mode::HTML => "HTML",
            Mode::Submit => "Submit",
            Mode::SSR => "SSR",
            Mode::Pure => "Pure",
        }
    }
}
