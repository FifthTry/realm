//! Rust / Elm base full stack web framework.
//!
//! [Crate's Description]. [what is found through what.]
//!
//!
//! ## Realm!
//!
//! Something about the macro
//!
//! ## forward function
//!
//! ## middleware function
//!
//! examples
//!
//! ```
//! some example
//! ```
//!



#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;
#[macro_use]
extern crate lazy_static;

extern crate url;
extern crate itertools;
extern crate chrono;

mod config;
mod html;
mod mode;
mod page;
mod serve;
mod widget;
pub mod utils;
pub mod request_config;


pub(crate) use crate::config::{Config, CONFIG};
pub use crate::html::HTML;
pub use crate::page::Page;
pub use crate::serve::{http_to_hyper, THREAD_POOL};
pub use crate::widget::{Widget, WidgetSpec};

pub type Result = std::result::Result<http::Response<Vec<u8>>, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;
pub type Response = http::response::Response<Vec<u8>>;

