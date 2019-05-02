use serde;
use serde_json;

#[derive(Serialize)]
pub struct WidgetSpec {
    id: &'static str,
    conf: serde_json::Value,
}

pub trait Widget: serde::ser::Serialize {
    fn realm_id(&self) -> &'static str;
    fn realm_conf(&self) -> serde_json::Value {
        serde_json::to_value(self).unwrap()
    }
    fn realm_json(&self) -> serde_json::Value {
        self.realm_conf()
    }
    fn widget_spec(&self) -> WidgetSpec {
        WidgetSpec {
            id: self.realm_id(),
            conf: self.realm_conf(),
        }
    }
}

pub trait Page: serde::ser::Serialize {
    fn realm_id(&self) -> &'static str;
    fn realm_conf(&self) -> serde_json::Value {
        serde_json::to_value(self).unwrap()
    }
    fn realm_json(&self) -> serde_json::Value {
        self.realm_conf()
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
    fn html(&self, _html: &HTML) -> crate::Result {
        unimplemented!()
    }
}

pub struct HTML {
    pub title: String,
}
