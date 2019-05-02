use realm;

#[derive(Serialize)]
pub struct Index {}

impl realm::Widget for Index {
    fn realm_id(&self) -> &'static str {
        "index"
    }
}

impl Index {
    pub fn new(_req: &realm::Request) -> Index {
        Index {}
    }
    pub fn boxed(req: &realm::Request) -> Box<impl realm::Widget> {
        Box::new(Index::new(req))
    }
}
