#[derive(Serialize)]
pub struct LRoot {
    header: crate::widgets::Header,
    body: realm::WidgetSpec,
    footer: crate::widgets::Footer,
}

impl  LRoot{
    pub fn new(req: &realm::Request, body: realm::WidgetSpec) -> LRoot {
         LRoot {
            header: crate::widgets::Header::new(req),
            body,
            footer: crate::widgets::Footer::new(req),
        }
    }
}

impl realm::Page for LRoot {
    fn realm_id(&self) -> &'static str {
        "l_root"
    }
}
