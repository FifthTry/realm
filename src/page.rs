#[derive(Serialize, Debug)]
pub struct CacheSpec {
    etag: Option<String>,
    purge_caches: Vec<String>,
    id: Option<String>,
}

impl Default for CacheSpec {
    fn default() -> CacheSpec {
        CacheSpec {
            etag: None,
            purge_caches: vec![],
            id: Some("default".to_string()),
        }
    }
}

#[derive(Serialize, Debug)]
pub struct PageSpec {
    pub id: String,
    pub config: serde_json::Value,
    pub title: String,
    pub url: Option<String>,
    pub replace: Option<String>,
    pub redirect: Option<String>,
    pub cache: Option<CacheSpec>,
    pub hash: String,
    pub pure: bool,
    pub pure_mode: String,
    pub trace: Option<serde_json::Value>,

    #[serde(skip)]
    pub rendered: String,

    #[serde(skip)]
    pub activity: Option<crate::Activity>,
}

fn escape(s: &str) -> String {
    let s = s.replace('>', "\\u003E");
    let s = s.replace('<', "\\u003C");
    s.replace('&', "\\u0026")
}

impl PageSpec {
    pub fn with_trace(mut self, trace: impl serde::Serialize) -> Result<Self, failure::Error> {
        self.trace = Some(serde_json::to_value(trace)?);
        Ok(self)
    }

    pub fn json_with_template(&self) -> Result<serde_json::Value, failure::Error> {
        // not yet sure this function (attaching template to every outgoing json) is a
        // good idea, maybe index.html should be part of js builds?
        let html = get_page();
        let data = serde_json::to_value(&self)?;

        let data = match data {
            serde_json::Value::Object(mut m) => {
                let h2 = html
                    .replace("__realm_hash__", CURRENT.as_str())
                    .replace("__realm_body__", "");
                m.insert("template".to_string(), serde_json::Value::String(h2));
                serde_json::Value::Object(m)
            }
            _ => data,
        };

        Ok(data)
    }

    pub fn render(&self, is_crawler: bool) -> Result<Vec<u8>, failure::Error> {
        let data = escape(serde_json::to_string_pretty(&self.json_with_template()?)?.as_str());

        let mut html = get_page();
        html = html.replace("__realm_title__", escape(&self.title).as_str());

        if is_crawler {
            html = html
                .replace("__realm_body__", &self.rendered)
                .replace("__realm_data__", "")
                .replace("<script src='/static/elm.__realm_hash__.js'></script>", "");
        } else {
            html = html
                .replace("__realm_data__", &data)
                .replace("__realm_body__", "")
                .replace("__realm_hash__", CURRENT.as_str());
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

    fn with(
        &self,
        title: &str,
        activity: Option<crate::Activity>,
        cache: CacheSpec,
    ) -> Result<crate::Response, failure::Error> {
        Ok(crate::Response::Page(PageSpec {
            id: Self::ID.into(),
            config: serde_json::to_value(self)?,
            title: title.into(),
            url: None,
            replace: None,
            redirect: None,
            rendered: self.render()?,
            cache: Some(cache),
            pure: false,
            pure_mode: "".into(),
            hash: CURRENT.clone(),
            trace: None,
            activity,
        }))
    }

    fn with_cache(&self, title: &str, cache: CacheSpec) -> Result<crate::Response, failure::Error> {
        self.with(title, None, cache)
    }

    fn with_etag(&self, title: &str, etag: &str) -> Result<crate::Response, failure::Error> {
        let mut cache = CacheSpec::default();
        cache.etag = Some(etag.to_string());
        self.with_cache(title, cache)
    }

    fn with_cache_id(
        &self,
        title: &str,
        etag: Option<String>,
        id: &str,
    ) -> Result<crate::Response, failure::Error> {
        let mut cache = CacheSpec::default();
        cache.etag = etag;
        cache.id = Some(id.to_string());
        self.with_cache(title, cache)
    }

    fn with_title(&self, title: &str) -> Result<crate::Response, failure::Error> {
        self.with_cache(title, CacheSpec::default())
    }

    fn with_activity(
        &self,
        title: &str,
        okind: &str,
        oid: &str,
        ekind: &str,
    ) -> Result<crate::Response, failure::Error> {
        self.with(
            title,
            Some(crate::Activity {
                okind: okind.to_string(),
                oid: oid.to_string(),
                ekind: ekind.to_string(),
                data: serde_json::Value::Null,
            }),
            CacheSpec::default(),
        )
    }
}

fn get_page() -> String {
    if cfg!(debug_assertions) {
        read_index()
    } else {
        HTML_PAGE.clone()
    }
}

fn read_index() -> String {
    let proj_dir = std::env::current_dir().expect("Could not find current dir");
    let path =
        proj_dir.join(std::env::var("REALM_INDEX").unwrap_or_else(|_| "index.html".to_string()));
    println!("reading_index: {:?}", &path);
    match std::fs::read_to_string(path) {
        Ok(p) => p,
        Err(_err) => default_page(),
    }
}

pub(crate) fn read_current() -> String {
    let proj_dir = std::env::current_dir().expect("Could not find current dir");
    let path = proj_dir.join(
        std::env::var("REALM_CURRENT_HASH_FILE")
            .unwrap_or_else(|_| "static/current.txt".to_string()),
    );
    println!("reading_current: {:?}", &path);
    std::fs::read_to_string(path).expect("current.txt missing")
}

lazy_static! {
    pub static ref HTML_PAGE: String = read_index();
    pub static ref CURRENT: String = read_current();
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
        <script src="/static/elm.__realm_hash__.js"></script>
    </body>
</html>
"#
    .to_string()
}
