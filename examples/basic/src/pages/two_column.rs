use crate::widgets::{Footer, Header};
use realm;

#[derive(Serialize)]
pub struct TwoColumn<W>
where
    W: realm::Widget,
{
    header: Header,
    body: Box<W>,
    footer: Footer,
}

impl<W> TwoColumn<W>
where
    W: realm::Widget,
{
    pub fn new(req: &realm::Request, body: Box<W>) -> TwoColumn<W> {
        TwoColumn {
            header: Header::new(req),
            body,
            footer: Footer::new(req),
        }
    }
}

impl<W> realm::Page for TwoColumn<W>
where
    W: realm::Widget,
{
    fn realm_id(&self) -> &'static str {
        "foo"
    }
}
