#[derive(Serialize)]
pub struct PageSpec {
    pub id: String,
    pub config: serde_json::Value,
    pub title: String,
    pub url: Option<String>,
    pub replace: Option<String>,
    pub redirect: Option<String>,
}

fn escape(s: &str) -> String {
    let s = s.replace('>', "\\u003E");
    let s = s.replace('<', "\\u003C");
    s.replace('&', "\\u0026")
}

impl PageSpec {
    pub fn render(&self) -> Result<Vec<u8>, failure::Error> {
        let data = escape(serde_json::to_string_pretty(&self)?.as_str());
        let script_path = match std::env::var("APP_NAME") {
            Ok(path) => format!("/static/{}/elm.js", path),
            Err(_err) => "/static/elm.js".to_string(),
        };
        Ok(format!(
            // TODO: add other stuff to html
            r#"<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <title>{}</title>
        <meta name="viewport" content="width=device-width" />
        <script id="data" type="application/json">
{}
        </script>
        <style>p {{margin: 0}}</style>
    </head>
    <body>
        <div id="main"></div>
        <script src='{}'></script>
    </body>
</html>"#,
            &self.title,
            data,
            script_path,
        )
        .into())
    }
    pub fn with_url(mut self, url: String) -> Self {
        self.url = Some(url);
        self
    }
    pub fn with_default_url(mut self, default: String) -> Self {
        if self.url.is_none() {
            self.url = Some(default);
        }
        self
    }
    pub fn with_replace(mut self, url: String) -> Self {
        self.replace = Some(url);
        self
    }
}

pub trait Page: serde::ser::Serialize {
    const ID: &'static str;
    fn with_title(&self, title: &str) -> Result<crate::Response, failure::Error> {
        Ok(crate::Response::Page(PageSpec {
            id: Self::ID.into(),
            config: serde_json::to_value(self)?,
            title: title.into(),
            url: None,
            replace: None,
            redirect: None,
        }))
    }
}
