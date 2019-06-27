use crate::pages::TwoColumn;
use crate::widgets::Index;
use realm::{Page, Widget, HTML};

pub fn layout(req: &realm::Request, _user_id: i32) -> realm::Result {
    TwoColumn::new(req, Index::new(req).widget_spec()?).page(req, HTML::new().title("foo"))
}
