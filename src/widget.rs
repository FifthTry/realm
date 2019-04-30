use serde;
use serde_json;

pub trait Widget: serde::ser::Serialize {
    fn id() -> &'static str;
    fn conf(&self) -> serde_json::Value {
        serde_json::to_value(self).unwrap()
    }
    fn json(&self) -> serde_json::Value {
        self.conf()
    }
}

pub trait Page: serde::ser::Serialize {
    fn id() -> &'static str;
    fn conf(&self) -> serde_json::Value {
        serde_json::to_value(self).unwrap()
    }
    fn json(&self) -> serde_json::Value {
        self.conf()
    }
    fn page_with_response(&self, _resp: crate::Response) -> crate::Result {
        unimplemented!()
    }
    fn page(&self) -> crate::Result {
        unimplemented!()
    }
    fn html_with_response(&self, _html: &HTML, _resp: crate::Response) -> crate::Result {
        unimplemented!()
    }
    fn html(&self, html: &HTML) -> crate::Result {
        unimplemented!()
    }
}

pub struct HTML {
    pub title: String,
}
