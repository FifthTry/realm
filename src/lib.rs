#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;
#[macro_use]
extern crate lazy_static;

#[macro_use]
extern crate rust_embed;
extern crate chrono;
extern crate itertools;
extern crate url;


mod config;
mod html;
mod mode;
mod page;
pub mod request_config;
mod serve;
pub mod utils;
mod widget;

pub(crate) use crate::config::{Config, CONFIG};
pub use crate::html::HTML;
pub use crate::page::Page;
pub use crate::serve::{http_to_hyper, THREAD_POOL};
pub use crate::widget::{Widget, WidgetSpec};

pub type Result = std::result::Result<http::Response<Vec<u8>>, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;
pub type Response = http::response::Response<Vec<u8>>;
