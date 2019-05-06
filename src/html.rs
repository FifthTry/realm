use crate::CONFIG;

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

    pub fn render(&self, spec: crate::WidgetSpec) -> Result<Vec<u8>, failure::Error> {
        let title = format!(
            "{}{}{}",
            &CONFIG.site_title_prefix, &self.title, &CONFIG.site_title_postfix
        );
        let rendered = ""; // TODO: implement server side rendering
        let hash = latest_elm()?;
        let deps = resolve_deps(&spec, &hash)?;
        let data = json!({"data": spec, "deps": deps});
        let data = serde_json::to_string_pretty(&data)?;
        // TODO: escape html
        Ok(format!( // TODO: add other stuff to html
            r#"<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <title>{}</title>
        <meta name="viewport" content="width=device-width" />
        <link rel="icon" href="{}" type="image/x-icon" />
        <script id="data" type="application/json">
{}
        </script>
    </head>
    <body>
        <div id="root">{}</div>
        <script src="/static/deps/{}.js"></script>
    </body>
</html>"#,
            title, &CONFIG.site_icon, data, rendered, hash
        ).into())
    }
}

fn latest_elm() -> Result<String, failure::Error> {
    use std::io::Read;

    let latest = CONFIG.static_path("realm/latest.txt");
    let mut latest = std::fs::File::open(&latest)?;
    let mut latest_content = String::new();
    latest.read_to_string(&mut latest_content)?;
    Ok(latest_content.trim().to_string())
}

fn resolve_deps(
    spec: &crate::WidgetSpec,
    _latest: &str,
) -> Result<std::collections::HashMap<String, String>, failure::Error> {
    // convert spec to json, and then look recursively the value for any map that contains both
    // and only "id" and "config", if found, assume id to be the elm id.
    //
    // insert the elm id, and all it dependencies in map, where the value would be data read from
    // file system for that elm id.
    let _ids = fetch_ids(&serde_json::to_value(spec)?);
    Ok(std::collections::HashMap::new()) // TODO
}

fn fetch_ids(data: &serde_json::Value) -> Vec<String> {
    match data {
        serde_json::Value::Object(o) => {
            let id = if let Some(serde_json::Value::String(id)) = o.get("id") {
                id.to_string()
            } else {
                return vec![];
            };

            if let Some(config) = o.get("config") {
                let mut r = vec![id];
                r.extend(fetch_ids(config));
                return r;
            } else {
                return vec![];
            }
        }
        serde_json::Value::Array(l) => {
            let mut r: Vec<String> = vec![];
            for o in l.iter() {
                r.extend(fetch_ids(o))
            }
            return r;
        }
        _ => vec![],
    }
}

#[cfg(test)]
mod tests {
    fn check(d: serde_json::Value, e: Vec<&str>) {
        assert_eq!(super::fetch_ids(&d), e);
    }

    #[test]
    fn fetch_ids() {
        check(json!({}), vec![]);
        check(json!({"id": "foo"}), vec![]);
        check(json!({"id": "foo", "config": 0}), vec!["foo"]);
        check(
            json!({
                "id": "foo",
                "config": {"id": "bar", "config": 0}
            }),
            vec!["foo", "bar"],
        );
        check(
            json!({
                "id": "foo", "config": [
                    {"id": "bar", "config": 0},
                    {"id": "bar2", "config": 0}
                ]
            }),
            vec!["foo", "bar", "bar2"],
        );
    }
}
