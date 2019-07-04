#[derive(Serialize)]
pub struct M {}

impl realm::Widget for M {
    fn realm_id(&self) -> &'static str {
        "m"
    }
}

impl M {
    pub fn new(_req: &realm::Request) -> M {
        M {}
    }
}
