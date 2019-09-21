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
extern crate failure_derive;

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

#[derive(Fail, Debug)]
pub enum Error {
    #[fail(display = "404 Page Not Found: {}", message)]
    PageNotFound { message: String },
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
