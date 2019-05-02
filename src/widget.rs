use failure;
use serde;
use serde_json;

#[derive(Serialize)]
pub struct WidgetSpec {
    id: &'static str,
    conf: serde_json::Value,
}

pub trait Widget: serde::ser::Serialize {
    fn realm_id(&self) -> &'static str;
    fn realm_conf(&self) -> Result<serde_json::Value, failure::Error> {
        Ok(serde_json::to_value(self)?)
    }
    fn realm_json(&self) -> Result<serde_json::Value, failure::Error> {
        self.realm_conf()
    }
    fn widget_spec(&self) -> Result<WidgetSpec, failure::Error> {
        Ok(WidgetSpec {
            id: self.realm_id(),
            conf: self.realm_conf()?,
        })
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
    fn html_with_response(&self, _html: HTML, _resp: crate::Response) -> crate::Result {
        unimplemented!()
    }
    fn html(&self, html: HTML) -> crate::Result {
        self.html_with_response(html, crate::Response::new(vec![]))
    }
}

pub struct HTML {
    pub title: String,
}

impl HTML {
    pub fn new() -> HTML {
        HTML { title: "".into() }
    }
    pub fn title(mut self, title: &str) -> Self {
        self.title = title.into();
        self
    }
}
