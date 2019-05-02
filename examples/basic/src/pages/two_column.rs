use crate::widgets::{Footer, Header};
use realm;

#[derive(Serialize)]
pub struct TwoColumn {
    header: Header,
    body: realm::WidgetSpec,
    footer: Footer,
}

impl TwoColumn {
    pub fn new(req: &realm::Request, body: realm::WidgetSpec) -> TwoColumn {
        TwoColumn {
            header: Header::new(req),
            body,
            footer: Footer::new(req),
        }
    }
}

impl realm::Page for TwoColumn {
    fn realm_id(&self) -> &'static str {
        "foo"
    }
}
