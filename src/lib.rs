#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate lazy_static;

mod config;
mod html;
mod mode;
mod page;
mod serve;
mod widget;

pub use html::HTML;
pub use mode::Mode;
pub use page::Page;
pub use serve::{http_to_hyper, THREAD_POOL};
pub use widget::{Widget, WidgetSpec};

pub type Result = std::result::Result<http::Response<Vec<u8>>, failure::Error>;
pub type Request = http::request::Request<Vec<u8>>;
pub type Response = http::response::Response<Vec<u8>>;

pub fn loading_page(_req: &Request) -> Request {
    // change the path to /realm_loading/
    // put the path back as realm_original_url header
    unimplemented!()
}
