use crate::base::db::RealmConnection;
use crate::base::*;
use chrono::prelude::*;

pub struct In<'a> {
    pub ctx: &'a crate::Context,
    pub lang: Language, // what is language_tags crate about?
    pub head: std::cell::RefCell<http::response::Builder>,
    pub remote_ip: String,
    ud: std::cell::RefCell<Option<(i32, String, i32)>>,
    pub conn: &'a RealmConnection,
    user_id: std::cell::RefCell<Option<i32>>,
    pub now: DateTime<Utc>,
}

impl<'a> In<'a> {
    pub fn from(conn: &'a RealmConnection, ctx: &'a crate::Context, remote_ip: &str) -> In<'a> {
        let ud = get_cookie(&ctx.request, "ud").and_then(In::parse_ud_cookie);
        let uid = match ud {
            Some((uid, _, _)) => Some(uid),
            None => None,
        };
        In {
            ctx,
            lang: Language::default(), // TODO: get this from header
            head: std::cell::RefCell::new(http::response::Builder::new()),
            remote_ip: remote_ip.to_string(),
            ud: std::cell::RefCell::new(ud),
            conn,
            user_id: std::cell::RefCell::new(uid),
            now: Utc::now(),
        }
    }

    pub fn get_header(&self, header: http::header::HeaderName) -> Option<String> {
        self.ctx
            .request
            .headers()
            .get(header)
            .and_then(|v| v.to_str().ok())
            .map(|v| v.to_string())
    }

    pub fn user_id(&self) -> Option<i32> {
        *self.user_id.borrow()
    }

    pub fn set_user_id(&self, uid: Option<i32>) {
        self.user_id.replace(uid);
    }

    pub fn get_cookie(&self, name: &str) -> Option<String> {
        get_cookie(&self.ctx.request, name)
    }

    pub fn user_agent(&self) -> Option<String> {
        self.get_header(http::header::USER_AGENT)
    }

    pub fn name(&self) -> Option<String> {
        match *self.ud.borrow() {
            Some((_, ref name, _)) => Some(name.to_string()),
            None => None,
        }
    }

    pub fn set_ud(&self, uid: i32, name: String, sid: i32) {
        self.ud.replace(Some((uid, name.clone(), sid)));
        self.ctx.cookie(
            "ud",
            signed_cookies::sign_value(
                format!("{}|{}|{}", uid, name, sid).as_str(),
                &cookie_secret(),
            )
            .as_str(),
            COOKIE_AGE,
        );
    }

    pub fn logout(&self) {
        self.ud.replace(None);
        self.ctx.cookie("ud", "", 0);
    }

    pub fn parse_ud_cookie(ud: String) -> Option<(i32, String, i32)> {
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
        let parts: Vec<String> = ud.split('|').map(|v| v.to_string()).collect();
        Some((
            parts[0].parse().unwrap(),
            parts[1].to_string(),
            parts[2].parse().unwrap(),
        ))
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
