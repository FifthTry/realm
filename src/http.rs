use hyper;

pub struct Request {}
pub enum Response {}
pub type Result = std::result::Result<Response, hyper::Error>;
