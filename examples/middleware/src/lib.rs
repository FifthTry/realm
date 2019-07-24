#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate failure;

extern crate url;

#[macro_use]
extern crate serde_json;
extern crate chrono;
extern crate itertools;

mod cms;
mod forward;
pub mod middleware;
mod pages;
mod reverse;
mod routes;
mod widgets;

pub type Result<T> = std::result::Result<T, failure::Error>;
