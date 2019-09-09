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

pub mod base;
mod context;
mod mode;
mod page;
pub mod request_config;
mod response;
mod serve;
pub mod utils;
pub mod watcher;

pub use crate::context::Context;
pub use crate::mode::Mode;
pub use crate::page::{Page, PageSpec};
pub use crate::serve::{http_to_hyper, THREAD_POOL};

pub use crate::response::Response;
pub type Result = std::result::Result<http::Response<Vec<u8>>, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;
