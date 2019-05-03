#[derive(Serialize)]
pub struct WidgetSpec {
    pub id: &'static str,
    pub conf: serde_json::Value,
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
