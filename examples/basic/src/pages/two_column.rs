use realm;

#[derive(Serialize)]
pub struct TwoColumn {}

impl TwoColumn {
    pub fn new(_r: realm::Request) -> TwoColumn {
        TwoColumn {}
    }
}

impl realm::Page for TwoColumn {
    fn id() -> &'static str {
        "foo"
    }
}
