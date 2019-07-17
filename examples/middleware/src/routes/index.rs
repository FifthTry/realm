use crate::pages::BasicPage;
use crate::widgets::TextWidget;
use realm::{Page, Widget, HTML};


pub fn layout(req: &realm::Request) -> realm::Result {
    BasicPage::new(req, TextWidget::new(req).widget_spec()?).page(req, HTML::new().title("index"))
}
