use hyper;
use std;

use crate::response::Response;

#[derive(Debug)]
pub enum Error {
    Http404(String),
    Hyper(hyper::Error),
}

impl Error {
    pub fn to_hyper(self) -> hyper::Response<hyper::Body> {
        unimplemented!()
    }
}

pub type Result = std::result::Result<Response, Error>;
