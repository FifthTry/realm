use crate::pages::BasicPage;
use crate::widgets::TextWidget;
use realm::{Page, Widget, HTML};

pub fn layout(req: &realm::Request, i: i32, s: String) -> realm::Result {
    println!("i {}, s {}", i, s);
    BasicPage::new(req, TextWidget::new(req).widget_spec()?).page(req, HTML::new().title("index"))
}
