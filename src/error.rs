use http;
use std;

pub type Result = std::result::Result<http::Response<Vec<u8>>, http::Response<Vec<u8>>>;
