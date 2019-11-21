use std::{env, fs};

#[derive(Serialize)]
pub struct PageSpec {
    pub id: String,
    pub config: serde_json::Value,
    pub title: String,
    pub url: Option<String>,
    pub replace: Option<String>,
    pub redirect: Option<String>,
    #[serde(skip)]
    pub rendered: String,
}

fn escape(s: &str) -> String {
    let s = s.replace('>', "\\u003E");
    let s = s.replace('<', "\\u003C");
    s.replace('&', "\\u0026")
}

impl PageSpec {
    pub fn render(&self, is_crawler: bool) -> Result<Vec<u8>, failure::Error> {
        let data = escape(serde_json::to_string_pretty(&self)?.as_str());
        let mut html = HTML_PAGE.clone();

        html = html.replace("__realm_title__", &self.title);

        if is_crawler {
            html = html
                .replace("__realm_body__", &self.rendered)
                .replace("__realm_data__", "")
                .replace("<script src='/static/elm.js'></script>", "");
        } else {
            html = html
                .replace("__realm_data__", &data)
                .replace("__realm_body__", "");
        }

        Ok(html.into())
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

pub trait Page: serde::ser::Serialize + askama::Template {
    const ID: &'static str;
    fn with_title(&self, title: &str) -> Result<crate::Response, failure::Error> {
        Ok(crate::Response::Page(PageSpec {
            id: Self::ID.into(),
            config: serde_json::to_value(self)?,
            title: title.into(),
            url: None,
            replace: None,
            redirect: None,
            rendered: self.render()?,
        }))
    }
}

lazy_static! {
    pub static ref HTML_PAGE: String = {
        let proj_dir = env::current_dir().expect("Could not find current dir");
        let path = proj_dir.join("index.html");
        match fs::read_to_string(path) {
            Ok(p) => p,
            Err(_err) => default_page(),
        }
    };
}

pub fn default_page() -> String {
    r#"<!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8" />
                <title>__realm_title__</title>
                <meta name="viewport" content="width=device-width" />
                <script id="data" type="application/json">
                    __realm_data__
                </script>
                <style>p {margin: 0}</style>
            </head>
            <body>
                __realm_body__
                <div id="main"></div>
                <script src='/static/elm.js'></script>
            </body>
        </html>"#
        .to_string()
}
