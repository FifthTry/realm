pub fn layout(req: &realm::Request, a: String, b: String) -> realm::Result {
    BasicPage::new(req, TextWidget::new(req).widget_spec()?).page(req, HTML::new().title("index"))
}