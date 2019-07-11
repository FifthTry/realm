#[derive(Serialize)]
pub struct BasicPage{
    header: crate::widgets::Header,
    body: realm::WidgetSpec,
    footer: crate::widgets::Footer,
}

impl BasicPage {
    pub fn new(req: &realm::Request, body: realm::WidgetSpec) -> BasicPage {
        BasicPage {
            header: crate::widgets::Header::new(req),
            body,
            footer: crate::widgets::Footer::new(req),
        }
    }
}

impl realm::Page for BasicPage {
    fn realm_id(&self) -> &'static str {
        "Pages.BasicPage"
    }
}
