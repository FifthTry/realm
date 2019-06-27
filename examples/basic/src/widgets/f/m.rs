#[derive(Serialize)]
pub struct M {}

impl realm::Widget for M {
    fn realm_id(&self) -> &'static str {
        "F.M"
    }
}

impl M {
    pub fn new(_req: &realm::Request) -> M {
        M {}
    }
}
