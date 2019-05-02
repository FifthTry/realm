use http;
#[macro_use]
extern crate serde_derive;

mod serve;
mod widget;

pub use serve::{http_to_hyper, THREAD_POOL};
pub use widget::{Page, Widget, WidgetSpec, HTML};

pub type Result = std::result::Result<http::Response<Vec<u8>>, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;
pub type Response = http::response::Response<Vec<u8>>;
