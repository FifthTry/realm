#[cfg(feature = "postgres_default")]
use crate::base::pg::RealmConnection;
#[cfg(feature = "sqlite_default")]
use crate::base::sqlite::RealmConnection;
use crate::base::*;
use chrono::prelude::*;
use std::cell::Ref;

pub struct In<'a, UD>
where
    UD: crate::UserData,
{
    pub ctx: &'a crate::Context,
    pub lang: Language, // what is language_tags crate about?
    pub head: std::cell::RefCell<http::response::Builder>,
    ud: std::cell::RefCell<Option<UD>>,
    #[cfg(any(feature = "sqlite_default", feature = "postgres_default"))]
    pub conn: &'a RealmConnection,
    pub now: DateTime<Utc>,
}

pub struct UD {}

impl std::str::FromStr for UD {
    type Err = failure::Error;
    fn from_str(_ud: &str) -> Result<UD> {
        Ok(UD {})
    }
}

impl std::string::ToString for UD {
    fn to_string(&self) -> String {
        "".to_string()
    }
}

impl crate::UserData for UD {
    fn user_id(&self) -> String {
        unimplemented!("not meant to be used")
    }

    fn session_id(&self) -> String {
        unimplemented!("not meant to be used")
    }

    fn has_perm(&self, _perm: &str) -> Result<bool> {
        unimplemented!("not meant to be used")
    }
}

pub type In0<'a> = In<'a, UD>;

impl<'a, UD> In<'a, UD>
where
    UD: crate::UserData,
{
    #[cfg(any(feature = "sqlite_default", feature = "postgres_default"))]
    pub fn from(conn: &'a RealmConnection, ctx: &'a crate::Context) -> In<'a, UD> {
        let ud = if ctx.mode.is_pure() {
            observer::log("not reading ud cookie in pure mode");
            None
        } else {
            get_cookie(&ctx.request, "ud").and_then(In::parse_ud_cookie)
        };
        In {
            ctx,
            lang: Language::default(), // TODO: get this from header
            head: std::cell::RefCell::new(http::response::Builder::new()),
            ud: std::cell::RefCell::new(ud),
            conn,
            now: Utc::now(),
        }
    }

    pub fn is_dev(&self) -> bool {
        // TODO: a signed cookie and a http handler to activate dev mode (how to detect superuser?)
        crate::base::is_test()
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

    pub fn format_cookie(&self, ud: &UD) -> String {
        signed_cookies::sign_value(&ud.to_string(), &cookie_secret())
    }

    pub fn form_error(&self, errors: &std::collections::HashMap<String, String>) -> crate::Result {
        match self.get_mode() {
            crate::Mode::Submit => crate::json(&json!({"kind": "errors", "data": errors})),
            _ => crate::err(errors),
        }
    }

    #[observed(namespace = "realm__in")]
    pub fn parse_ud_cookie(ud: String) -> Option<UD> {
        let ud: String = match signed_cookies::signed_value::<String>(
            ud.as_str(),
            i64::from(COOKIE_AGE),
            &cookie_secret(),
        ) {
            Ok(ud) => ud,
            Err(e) => {
                observer::log("signature failed");
                observer::observe_string("ud", ud.as_str()); // TODO
                observer::observe_string("error", e.to_string().as_str()); // TODO
                return None;
            }
        };
        match ud.parse::<UD>() {
            Ok(u) => {
                observer::observe_string("ud", ud.as_str()); // TODO
                Some(u)
            }
            Err(_e) => {
                observer::log("parse failed");
                observer::observe_string("ud", ud.as_str()); // TODO
                                                             // TODO: log e: for now it doesn't implement ToString
                None
            }
        }
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
