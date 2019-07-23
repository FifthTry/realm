#[derive(Serialize)]
pub struct L {
    header: crate::widgets::Header,
    body: realm::WidgetSpec,
    footer: crate::widgets::Footer,
}

impl L {
    pub fn new(req: &realm::Request, body: realm::WidgetSpec) -> L {
        L {
            header: crate::widgets::Header::new(req),
            body,
            footer: crate::widgets::Footer::new(req),
        }
    }
}

impl realm::Page for L {
    fn realm_id(&self) -> &'static str {
        "L"
    }
}
