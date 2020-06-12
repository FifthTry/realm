#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;
#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate crossbeam_channel;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate failure;
#[macro_use]
extern crate log;
#[macro_use]
extern crate observer_attribute;

#[cfg(any(
    all(
        feature = "postgre_default",
        any(feature = "mysql_default", feature = "sqlite_default")
    ),
    all(
        feature = "mysql_default",
        any(feature = "postgre_default", feature = "sqlite_default")
    ),
    all(
        feature = "sqlite_default",
        any(feature = "mysql_default", feature = "postgre_default")
    ),
))]
compile_error!("only one of postgre_default, mysql_default or sqlite_default can be activated");

pub mod activity;
pub mod base;
mod context;
pub mod iframe;
mod mode;
mod page;
pub mod request_config;
mod response;
pub mod serve;
pub mod serve_static;
pub mod storybook;
pub mod test;
mod urls;
pub mod utils;
pub mod watcher;

pub use crate::context::Context;
pub use crate::mode::Mode;
pub use crate::page::{Page, PageSpec};
pub use crate::request_config::RequestConfig;
pub use crate::response::{err, json, json_ok, json_with_context};
pub use crate::serve::{http_to_hyper, THREAD_POOL};
pub use crate::serve_static::serve_static;
pub use crate::urls::{handle, is_realm_url};

pub use crate::activity::Activity;

pub use crate::response::Response;
pub type Result = std::result::Result<crate::response::Response, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;

pub trait Subject: askama::Template {}
pub trait Text: askama::Template {}
pub trait HTML: askama::Template {}

// TODO: add a constraint to FromStr::Err implements Debug
pub trait UserData: std::string::ToString + std::str::FromStr {
    fn user_id(&self) -> String;
    fn session_id(&self) -> String;
    fn has_perm(&self, perm: &str) -> std::result::Result<bool, failure::Error>;
}

pub fn end_context<UD, NF>(in_: &crate::base::In<UD>, resp: Result, not_found: NF) -> Result
where
    UD: crate::UserData,
    NF: FnOnce(&crate::base::In<UD>, &str) -> Result,
{
    #[cfg(feature = "postgres")]
    crate::base::pg::rollback_if_required(&in_.conn);

    let resp = match resp {
        Ok(r) => Ok(r),
        Err(e) => {
            match e.downcast_ref::<crate::Error>() {
                Some(crate::Error::PageNotFound { message }) => {
                    observer::log("PageNotFound");
                    observer::observe_string("error", message.as_str()); // TODO
                    not_found(&in_, message.as_str())
                }
                Some(crate::Error::InputError { error }) => {
                    let e = error.to_string();
                    observer::log("InputError");
                    observer::observe_json("error", serde_json::to_value(&e)?); // TODO
                    not_found(&in_, e.as_str())
                }
                Some(crate::Error::FormError { errors }) => {
                    observer::log("FormError");
                    observer::observe_json("form_error", serde_json::to_value(&errors)?); // TODO
                    in_.form_error(&errors)
                }
                _ => Err(e),
            }
        }
    };

    let v = observer::end_context().expect("create_context() not called");

    match resp {
        Ok(crate::Response::Page(page)) if in_.is_dev() => {
            page.with_trace(v).map(crate::Response::Page)
        }
        Ok(crate::Response::JSON { data, context, .. }) if in_.is_dev() => {
            Ok(crate::Response::JSON {
                data,
                context,
                trace: Some(serde_json::to_value(v)?),
            })
        }
        resp => resp,
    }
}

#[derive(Fail, Debug)]
pub enum Error {
    #[fail(display = "404 Page Not Found: {}", message)]
    PageNotFound { message: String },

    #[fail(display = "Input Error: {:?}", error)]
    InputError {
        #[cause]
        error: crate::request_config::Error,
    },

    #[fail(display = "Form Error: {:?}", errors)]
    FormError {
        errors: std::collections::HashMap<String, String>,
    },

    #[fail(display = "Internal Server Error: {}", message)]
    CustomError { message: String },

    #[fail(display = "HTTP Error: {}", error)]
    HttpError {
        #[cause]
        error: http::Error,
    },

    #[fail(display = "Env Var Error: {}", error)]
    VarError {
        #[cause]
        error: std::env::VarError,
    },

    #[fail(display = "Diesel Error: {}", error)]
    DieselError {
        #[cause]
        error: diesel::result::Error,
    },
}

pub fn error<T>(key: &str, message: &str) -> std::result::Result<T, failure::Error> {
    let mut e = std::collections::HashMap::new();
    e.insert(key.into(), message.into());

    Err(Error::FormError { errors: e }.into())
}

impl From<diesel::result::Error> for Error {
    fn from(error: diesel::result::Error) -> Error {
        Error::DieselError { error }
    }
}

impl From<std::env::VarError> for Error {
    fn from(error: std::env::VarError) -> Error {
        Error::VarError { error }
    }
}

impl From<http::Error> for Error {
    fn from(error: http::Error) -> Error {
        Error::HttpError { error }
    }
}

impl From<crate::request_config::Error> for Error {
    fn from(error: crate::request_config::Error) -> Error {
        Error::InputError { error }
    }
}

pub trait Or404<T> {
    fn or_404(self) -> std::result::Result<T, failure::Error>;
}

impl<T> Or404<T> for std::result::Result<T, failure::Error> {
    fn or_404(self) -> std::result::Result<T, failure::Error> {
        self.map_err(|e| {
            Error::PageNotFound {
                message: e.to_string(),
            }
            .into()
        })
    }
}
