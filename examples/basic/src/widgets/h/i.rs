#[derive(Serialize)]
pub struct I {}

impl realm::Widget for I {
    fn realm_id(&self) -> &'static str {
        "H.I"
    }
}

impl I {
    pub fn new(_req: &realm::Request) -> I {
        I {}
    }
}
