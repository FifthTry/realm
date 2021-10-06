#[cfg(feature = "postgres_default")]
use crate::base::pg::RealmConnection;
#[cfg(feature = "sqlite_default")]
use crate::base::sqlite::RealmConnection;
use crate::base::*;
use chrono::prelude::*;
use std::cell::{Ref, RefCell};

pub struct In<'a, UD>
where
    UD: crate::UserData,
{
    pub ctx: &'a crate::Context,
    lang: RefCell<realm_lang::Language>,
    pub head: RefCell<http::response::Builder>,
    ud: RefCell<Option<UD>>,
    #[cfg(any(feature = "sqlite_default", feature = "postgres_default"))]
    pub conn: &'a RealmConnection,
    pub now: DateTime<Utc>,

    tid: RefCell<Option<String>>,
    tid_created: RefCell<bool>,

    vid: RefCell<Option<String>>,
    vid_created: RefCell<bool>,

    // activity stuff
    okind: RefCell<String>,
    oid: RefCell<String>,
    ekind: RefCell<String>,
    pub activity_data: RefCell<Vec<(String, serde_json::Value)>>,
}

#[allow(clippy::upper_case_acronyms)]
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
            match ctx.get_cookie("ud") {
                Some(c) => {
                    if c.is_empty() {
                        None
                    } else {
                        In::parse_ud_cookie(c)
                    }
                }
                None => None,
            }
        };
        let tid = ctx.get_cookie("tid").and_then(|v| parse_cookie("tid", v));
        let vid = ctx.get_cookie("vid").and_then(|v| parse_cookie("vid", v));

        In {
            ctx,
            lang: RefCell::new(realm_lang::Language::from_accept_language_header(
                ctx.get_cookie("realm-lang")
                    .map(|v| v.to_string())
                    .or_else(|| ctx.get_header_string(http::header::ACCEPT_LANGUAGE)),
                *crate::env::REALM_LANG,
            )),
            head: RefCell::new(http::response::Builder::new()),
            ud: RefCell::new(ud),
            conn,
            now: Utc::now(),

            tid: RefCell::new(tid),
            tid_created: RefCell::new(false),
            vid: RefCell::new(vid),
            vid_created: RefCell::new(false),

            okind: RefCell::new("".to_string()),
            oid: RefCell::new("".to_string()),
            ekind: RefCell::new("".to_string()),
            activity_data: RefCell::new(vec![]),
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
        self.ctx
            .get_header_string(http::header::HOST)
            .map(|h| h.starts_with("127.0.0.") || h.contains("localhost"))
            .unwrap_or(false)
    }

    pub fn get_host(&self) -> String {
        self.ctx.get_header_string("x-host").unwrap_or_else(|| {
            self.ctx
                .get_header_string(http::header::HOST)
                .expect("no host provided!")
        })
    }

    pub fn get_cookie(&self, name: &str) -> Option<String> {
        self.ctx
            .get_cookie(name)
            .and_then(|v| parse_cookie(name, v))
    }

    pub fn user_agent(&self) -> Option<String> {
        self.ctx.user_agent()
    }

    pub fn reset_ud(&self) {
        self.ud.replace(None);
        self.ctx.delete_cookie("ud");
    }

    pub fn reset_for_test(&self) {
        self.reset_ud();

        self.tid.replace(None);
        self.tid_created.replace(false);
        self.ctx.delete_cookie("tid");

        self.vid.replace(None);
        self.vid_created.replace(false);
        self.ctx.delete_cookie("vid");
    }

    pub fn ud(&self) -> Ref<Option<UD>> {
        self.ud.borrow()
    }

    pub fn lang(&self) -> realm_lang::Language {
        *self.lang.borrow()
    }

    pub fn user_id(&self) -> Option<String> {
        self.ud().as_ref().map(|u| u.user_id())
    }

    pub fn session_id(&self) -> Option<String> {
        self.ud().as_ref().map(|u| u.session_id())
    }

    pub fn activity(&self, okind: &str, oid: &str, ekind: &str) {
        self.okind.replace(okind.to_string());
        self.oid.replace(oid.to_string());
        self.ekind.replace(ekind.to_string());
    }

    pub(crate) fn get_activity(&self) -> crate::rr::Activity {
        crate::rr::Activity {
            oid: self.oid.borrow().to_owned(),
            okind: self.okind.borrow().to_owned(),
            ekind: self.ekind.borrow().to_owned(),
            data: serde_json::Value::Null,
        }
    }

    pub fn activity_ekind(&self, ekind: &str) {
        self.ekind.replace(ekind.to_string());
    }

    // pub fn activity_data(&self, key: &str, value: serde_json::Value) {
    //     use std::ops::DerefMut;
    //
    //     let mut v1 = self.adata.borrow_mut();
    //     let v = v1.deref_mut();
    //     let item = (key.to_string(), value);
    //     match v {
    //         Some(a) => a.push(item),
    //         None => {
    //             *v = Some(vec![item]);
    //         }
    //     }
    // }

    pub fn set_ud(&self, ud: UD) {
        self.ctx
            .cookie("ud", self.format_cookie(&ud).as_str(), DECADE);
        self.ud.replace(Some(ud));
    }

    pub fn set_lang(&self, lang: realm_lang::Language) {
        self.ctx.cookie("realm-lang", lang.id(), DECADE);
        self.lang.replace(lang);
    }

    pub fn set_tid(&self, tid: String) {
        self.ctx
            .cookie("tid", self.format_cookie_string(&tid).as_str(), DECADE * 30);
        self.tid.replace(Some(tid));
        self.tid_created.replace(true);
    }

    pub fn set_vid(&self, vid: String) {
        self.ctx.cookie(
            "vid",
            self.format_cookie_string(&vid).as_str(),
            VID_COOKIE_AGE,
        );
        self.vid.replace(Some(vid));
        self.vid_created.replace(true);
    }

    pub fn refresh_vid(&self, vid: String) {
        self.ctx.cookie(
            "vid",
            self.format_cookie_string(&vid).as_str(),
            VID_COOKIE_AGE,
        );
    }

    pub fn get_tid_vid_created_values(&self) -> Result<(bool, bool)> {
        Ok((
            self.tid_created.borrow().to_owned(),
            self.vid_created.borrow().to_owned(),
        ))
    }

    pub fn get_tid_vid_cookies(&self) -> Result<(String, String)> {
        Ok((
            self.tid
                .borrow()
                .to_owned()
                .unwrap_or_else(|| "".to_string()),
            self.vid
                .borrow()
                .to_owned()
                .unwrap_or_else(|| "".to_string()),
        ))
    }

    pub fn format_cookie(&self, ud: &UD) -> String {
        signed_cookies::sign_value(&ud.to_string(), &cookie_secret())
    }

    pub fn format_cookie_string(&self, s: &str) -> String {
        signed_cookies::sign_value(&s.to_string(), &cookie_secret())
    }

    pub fn form_error(&self, errors: &std::collections::HashMap<String, String>) -> crate::Result {
        match self.ctx.mode {
            crate::Mode::Submit => crate::json(&json!({"kind": "errors", "data": errors})),
            _ => crate::err(errors),
        }
    }

    #[observed(namespace = "realm__in")]
    pub fn parse_ud_cookie(ud: &str) -> Option<UD> {
        if ud.is_empty() {
            return None;
        }

        let ud: String = match signed_cookies::signed_value::<String>(ud, DECADE, &cookie_secret())
        {
            Ok(ud) => ud,
            Err(e) => {
                observer::log("signature failed");
                observer::transient_string("ud", ud); // TODO
                observer::observe_string("error", e.to_string().as_str()); // TODO
                return None;
            }
        };
        match ud.parse::<UD>() {
            Ok(u) => {
                observer::transient_string("ud", ud.as_str()); // TODO
                Some(u)
            }
            Err(_e) => {
                observer::log("parse failed");
                observer::transient_string("ud", ud.as_str());
                // TODO: log e: for now it doesn't implement ToString
                None
            }
        }
    }
}

const DECADE: i64 = 3600 * 24 * 365 * 10;
const VID_COOKIE_AGE: i64 = 60 * 30;

fn cookie_secret() -> Vec<u8> {
    std::env::var("COOKIE_SECRET")
        .unwrap_or_else(|_| "foo".into())
        .into_bytes()
}

// #[observed(namespace = "realm__in")]
pub fn parse_cookie(_key: &str, cookie: &str) -> Option<String> {
    if cookie.is_empty() {
        return None;
    }
    // observer::observe_string("cookie", key);
    let cookie: String =
        match signed_cookies::signed_value::<String>(cookie, DECADE, &cookie_secret()) {
            Ok(cookie) => cookie,
            Err(e) => {
                observer::log("signature failed");
                observer::observe_string("cookie", cookie); // TODO
                observer::observe_string("error", e.to_string().as_str()); // TODO
                return None;
            }
        };
    Some(cookie)
}
