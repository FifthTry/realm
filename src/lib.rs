use http;
#[macro_use]
extern crate serde_derive;

mod error;
mod serve;
mod widget;

pub use error::Result;
pub use serve::{http_to_hyper, THREAD_POOL};
pub use widget::{Page, Widget, WidgetSpec, HTML};

pub type Request = http::request::Request<Vec<u8>>;
pub type Response = http::response::Response<Vec<u8>>;
