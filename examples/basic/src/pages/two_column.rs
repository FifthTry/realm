#[derive(Serialize)]
pub struct TwoColumn {
    header: crate::widgets::Header,
    body: realm::WidgetSpec,
    footer: crate::widgets::Footer,
}

impl TwoColumn {
    pub fn new(req: &realm::Request, body: realm::WidgetSpec) -> TwoColumn {
        TwoColumn {
            header: crate::widgets::Header::new(req),
            body,
            footer: crate::widgets::Footer::new(req),
        }
    }
}

impl realm::Page for TwoColumn {
    fn realm_id(&self) -> &'static str {
        "two_column"
    }
}
