use crate::{StaticData, CONFIG};

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
        let hash = CONFIG.content("realm/latest.txt")?;
        let deps = resolve_deps(&spec, &hash, &CONFIG.clone() /* eff you rust */)?;
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

fn resolve_deps(
    spec: &crate::WidgetSpec,
    _latest: &str,
    sd: &impl crate::StaticData,
) -> Result<std::collections::HashMap<String, String>, failure::Error> {
    // convert spec to json, and then look recursively the value for any map that contains both
    // and only "id" and "config", if found, assume id to be the elm id.
    //
    // insert the elm id, and all it dependencies in map, where the value would be data read from
    // file system for that elm id.
    fetch_deps(fetch_ids(&serde_json::to_value(spec)?), sd)
}

fn fetch_deps(
    ids: Vec<String>,
    _sd: &impl crate::StaticData,
) -> Result<std::collections::HashMap<String, String>, failure::Error> {
    let mut result = std::collections::HashMap::new();

    Ok(result)
}

#[cfg(test)]
mod tests_fetch_deps {
    use std::collections::HashMap;

    fn check(d: Vec<&str>, e: N, sd: &crate::static_data::TestStatic) {
        assert_eq!(
            super::fetch_deps(d.iter().map(|s| s.to_string()).collect(), &sd).unwrap(),
            e.0
        );
    }

    fn fixture() -> crate::static_data::TestStatic {
        crate::static_data::TestStatic::new()
            .with("latest.txt", "elmver")
            .with(
                "deps.json",
                r#"{
                    "foo": []
                }"#,
            ).with("elmver/foo.js", "function foo() {}")
    }

    struct N(pub HashMap<String, String>);
    impl N {
        fn o(key: &str, value: &str) -> Self {
            let mut n = N(HashMap::new());
            n.0.insert(key.into(), value.into());
            n
        }
        fn with(mut self, key: &str, value: &str) -> Self {
            self.0.insert(key.into(), value.into());
            self
        }
    }

    #[test]
    fn fetch_deps() {
        let sd = fixture();
        check(vec![], N(HashMap::new()), &sd);
        check(vec!["foo"], N::o("foo", "function foo() {}"), &sd);
    }
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
mod tests_fetch_ids {
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
