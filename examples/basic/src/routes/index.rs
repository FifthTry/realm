use crate::pages::L;
use crate::widgets::M;
use realm::{Page, Widget, HTML};

pub fn layout(req: &realm::Request, _user_id: i32) -> realm::Result {
    L::new(req, M::new(req).widget_spec()?).page(req, HTML::new().title("index"))
}
