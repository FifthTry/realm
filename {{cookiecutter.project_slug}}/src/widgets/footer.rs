#[derive(Serialize)]
pub struct Footer {}

impl realm::Widget for Footer {
    fn realm_id(&self) -> &'static str {
        "footer"
    }
}

impl Footer {
    pub fn new(_req: &realm::Request) -> Footer {
        Footer {}
    }
}
