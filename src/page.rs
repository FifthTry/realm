use crate::{WidgetSpec, HTML};
use failure;
use serde;
use serde_json;

pub trait Page: serde::ser::Serialize {
    fn realm_id(&self) -> &'static str;
    fn realm_conf(&self) -> Result<serde_json::Value, failure::Error> {
        Ok(serde_json::to_value(self)?)
    }
    fn realm_json(&self) -> Result<serde_json::Value, failure::Error> {
        self.realm_conf()
    }
    fn page_with_response(&self, _html: HTML, _resp: crate::Response) -> crate::Result {
        unimplemented!()
    }
    fn page(&self, html: HTML) -> crate::Result {
        self.page_with_response(html, crate::Response::new(vec![]))
    }
    fn widget_spec(&self) -> Result<WidgetSpec, failure::Error> {
        Ok(WidgetSpec {
            id: self.realm_id(),
            conf: self.realm_conf()?,
        })
    }
}
