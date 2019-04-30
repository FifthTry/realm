use hyper;

pub enum Response {
    Success(Success),
    Redirect(Redirect),
}

pub struct Redirect {
    pub path: String,
}

pub struct Success {
    // title: Maybe<String>,
    pub new_path: String,
    pub replace: bool,
    pub body: Vec<u8>,
    // headers:
    // cookies
    // status code
    // x-sendfile

    // seo stuff

    // id
    // config
}

impl Response {
    // pub fn empty() -> Response {}
    // pub fn add_cookie(key: String, value: String) {}
    // pub fn new(id: String, config: String) -> Response {}
    // pub fn api(json) -> Response {}

    pub fn to_hyper(self) -> hyper::Response<hyper::Body> {
        unimplemented!()
    }
}
