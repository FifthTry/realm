use crate::pages::BasicPage;
use crate::widgets::TextWidget;
use realm::{Page, Widget, HTML};

pub fn layout(req: &realm::Request, i: i32) -> realm::Result {
    println!("{}", i);
    BasicPage::new(req, TextWidget::new(req).widget_spec()?).page(req, HTML::new().title("index"))
}
