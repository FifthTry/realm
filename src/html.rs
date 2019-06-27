use crate::CONFIG;
use htmlescape;
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
        let deps = resolve_deps(&spec, &CONFIG)?;
        //let data = json!({"data": spec, "deps": deps});
        // FixME
        let data = json!({
            "result": {
                "widget": spec,
                "replace": false,
                "deps": deps
            }
        });

        let data = serde_json::to_string_pretty(&data)?;
        let data = htmlescape::encode_minimal(&data);


        let loader: String= read(CONFIG.loader_file.as_str()).unwrap_or("".into());

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
        <div id="main"></div>

        <script>
        {}
        </script>
        <script src="/static/deps/{}.js"></script>
    </body>
</html>"#,
            title, &CONFIG.site_icon, data, rendered, loader, &CONFIG.latest_elm,
        ).into())
    }
}

#[derive(Debug, Serialize, PartialEq)]
pub struct LayoutDeps {
    pub module: String,
    pub source: String,
}

fn resolve_deps(
    spec: &crate::WidgetSpec,
    config: &crate::Config,
) -> Result<Vec<LayoutDeps>, failure::Error> {
    // convert spec to json, and then look recursively the value for any map that contains both
    // and only "id" and "config", if found, assume id to be the elm id.
    //
    // insert the elm id, and all it dependencies in map, where the value would be data read from
    // file system for that elm id.
    fetch_deps(fetch_ids(&serde_json::to_value(spec)?), config)
}

fn fetch_deps(ids: Vec<String>, config: &crate::Config) -> Result<Vec<LayoutDeps>, failure::Error> {
    use std::collections::HashSet;
    //let testing = env["testing"] == "1";
    println!("ids {:?}", ids);
    let mut deps = vec![];
    let mut skip_map = HashSet::new();
    for id in ids.iter() {
        if skip_map.contains(&id.clone()) {
            continue;
        }
        skip_map.insert(id.clone());

        deps.push(LayoutDeps {
            module: id.clone(),
            source: config.get_code(id)?,
        });
    }
    Ok(deps)
}

#[cfg(test)]
mod tests_fetch_deps {
    fn check(d: Vec<&str>, e: N, c: &crate::Config) {
        assert_eq!(
            super::fetch_deps(d.iter().map(|s| s.to_string()).collect(), c).unwrap(),
            e.0
        );
    }

    struct N(pub Vec<super::LayoutDeps>);
    impl N {
        fn o(module: &str, source: &str) -> Self {
            let mut n = N(vec![]);
            n.0.push(super::LayoutDeps {
                module: module.into(),
                source: source.into(),
            });
            n
        }
        fn with(mut self, module: &str, source: &str) -> Self {
            self.0.push(super::LayoutDeps {
                module: module.into(),
                source: source.into(),
            });
            self
        }
    }

    #[test]
    fn fetch_deps() {
        let config = crate::Config::test();
        check(vec![], N(vec![]), &config);
        check(vec!["bar"], N::o("bar", "function bar() {}"), &config);
        check(
            vec!["f"],
            N::o("bar", "function bar() {}").with("f", "function f() {bar()}"),
            &config,
        );
    }
}

fn read(path_st: &str) -> Result<String, failure::Error> {
        use std::io::Read;
        let path = std::path::Path::new(path_st);
        match std::fs::File::open(&path) {
            Ok(mut loader) => {
                let mut loader_content = String::new();
                loader.read_to_string(&mut loader_content)?;
                Ok(loader_content.trim().to_string())
            }
            Err(_) => Err(failure::err_msg(format!("File not found: {:?}", path))),
        }
}

fn fetch_ids(data: &serde_json::Value) -> Vec<String> {
    match data {
        serde_json::Value::Object(o) => {
            let id = if let Some(serde_json::Value::String(id)) = o.get("id") {
                id.to_string()
            } else {
                let mut r = vec![];
                for (_, value) in o {
                    r.extend(fetch_ids(value));
                }
                return r;
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
        check(json!({"id": "f"}), vec![]);
        check(json!({"id": "f", "config": 0}), vec!["f"]);
        check(
            json!({
                "id": "f",
                "config": {"id": "bar", "config": 0}
            }),
            vec!["f", "bar"],
        );
        check(
            json!({
                "id": "f", "config": [
                    {"id": "bar", "config": 0},
                    {"id": "bar2", "config": 0}
                ]
            }),
            vec!["f", "bar", "bar2"],
        );
    }
}
