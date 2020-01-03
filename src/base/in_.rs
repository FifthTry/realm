#[cfg(feature = "postgres_default")]
use crate::base::pg::RealmConnection;
#[cfg(feature = "sqlite_default")]
use crate::base::sqlite::RealmConnection;
use crate::base::*;
use chrono::prelude::*;
use std::cell::Ref;

pub struct In<'a, UD>
where
    UD: std::string::ToString + std::str::FromStr,
{
    pub ctx: &'a crate::Context,
    pub lang: Language, // what is language_tags crate about?
    pub head: std::cell::RefCell<http::response::Builder>,
    pub remote_ip: String,
    ud: std::cell::RefCell<Option<UD>>,
    #[cfg(any(feature = "sqlite_default", feature = "postgres_default"))]
    pub conn: &'a RealmConnection,
    pub now: DateTime<Utc>,
}

impl<'a, UD> In<'a, UD>
where
    UD: std::string::ToString + std::str::FromStr,
{
    #[cfg(any(feature = "sqlite_default", feature = "postgres_default"))]
    pub fn from(conn: &'a RealmConnection, ctx: &'a crate::Context, remote_ip: &str) -> In<'a, UD> {
        let ud = get_cookie(&ctx.request, "ud").and_then(In::parse_ud_cookie);
        In {
            ctx,
            lang: Language::default(), // TODO: get this from header
            head: std::cell::RefCell::new(http::response::Builder::new()),
            remote_ip: remote_ip.to_string(),
            ud: std::cell::RefCell::new(ud),
            conn,
            now: Utc::now(),
        }
    }

    pub fn is_anonymous(&self) -> bool {
        self.ud().is_none()
    }

    pub fn is_authenticated(&self) -> bool {
        self.ud().is_some()
    }

    pub fn is_local(&self) -> bool {
        self.get_header(http::header::HOST)
            .map(|h| h.contains("127.0.0.1") || h.contains("localhost") || h.contains("127.0.0.2"))
            .unwrap_or(false)
    }

    pub fn get_header(&self, header: http::header::HeaderName) -> Option<String> {
        self.ctx
            .request
            .headers()
            .get(header)
            .and_then(|v| v.to_str().ok())
            .map(|v| v.to_string())
    }

    pub fn get_mode(&self) -> crate::Mode {
        crate::Mode::detect(&self.ctx.request)
    }

    pub fn get_cookie(&self, name: &str) -> Option<String> {
        get_cookie(&self.ctx.request, name)
    }

    pub fn user_agent(&self) -> Option<String> {
        self.get_header(http::header::USER_AGENT)
    }

    pub fn reset_ud(&self) {
        self.ud.replace(None);
        self.ctx.cookie("ud", "", 0);
    }

    pub fn ud(&self) -> Ref<Option<UD>> {
        self.ud.borrow()
    }

    pub fn set_ud(&self, ud: UD) {
        self.ctx
            .cookie("ud", self.format_cookie(&ud).as_str(), COOKIE_AGE);
        self.ud.replace(Some(ud));
    }

    pub fn logout(&self) {
        self.ud.replace(None);
        self.ctx.cookie("ud", "", 0);
    }

    pub fn format_cookie(&self, ud: &UD) -> String {
        signed_cookies::sign_value(&ud.to_string(), &cookie_secret())
    }

    pub fn form_error(
        &self,
        errors: &std::collections::HashMap<String, String>,
    ) -> std::result::Result<crate::Response, failure::Error> {
        let mode = self.get_mode();
        self.ctx
            .header(http::header::CONTENT_TYPE, mode.content_type());
        let data = match mode {
            crate::Mode::Submit => json!({
                "success": true,
                "result": {
                    "kind": "errors",
                    "data": errors,
                }
            }),
            _ => json!({
                "success": false,
                "errors": errors,
            }),
        };
        self.ctx
            .response(serde_json::to_string_pretty(&data)?.into())
            .map(crate::Response::Http)
            .map_err(Into::into)
    }

    pub fn parse_ud_cookie(ud: String) -> Option<UD> {
        let ud: String = match signed_cookies::signed_value(
            ud.as_str(),
            i64::from(COOKIE_AGE),
            &cookie_secret(),
        ) {
            Ok(ud) => ud,
            Err(e) => {
                eprintln!("failed to read cookie: c={} err={:?}", ud, e);
                return None;
            }
        };
        ud.parse::<UD>().ok()
    }
}

const COOKIE_AGE: i32 = 3600 * 24 * 365;

fn cookie_secret() -> Vec<u8> {
    std::env::var("COOKIE_SECRET")
        .unwrap_or_else(|_| "foo".into())
        .into_bytes()
}

fn get_cookie(req: &Request, name: &str) -> Option<String> {
    match req
        .headers()
        .get(http::header::COOKIE)
        .and_then(|v| v.to_str().ok())
        .map(|v| v.split(';').collect::<Vec<&str>>())
    {
        Some(l) => {
            for item in l.iter() {
                if let Ok(c) = cookie::Cookie::parse_encoded(*item) {
                    if c.name() == name {
                        return Some(c.value().to_string());
                    }
                }
            }
            None
        }
        None => None,
    }
}
