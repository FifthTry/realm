use crate::pages::TwoColumn;
use realm::Page;

pub fn layout(req: realm::Request, _user_id: i32) -> realm::Result {
    TwoColumn::new(req).page()

    // let mut resp = http::Response::new();
    // res.set_cookie("foo", "barr");

    // tc.page_with_response(resp, HTML::new())

    // tc.page() // tc.html(HTML::new())
}
