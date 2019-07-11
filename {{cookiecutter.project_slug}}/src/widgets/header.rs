#[derive(Serialize)]
pub struct Header {}

impl realm::Widget for Header {
    fn realm_id(&self) -> &'static str {
        "header"
    }
}

impl Header {
    pub fn new(_req: &realm::Request) -> Header {
        Header {}
    }
}
