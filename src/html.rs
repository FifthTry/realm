use crate::utils::LayoutDeps;
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
        let deps = resolve_deps(&spec, &CONFIG)?;
        //let data = json!({"data": spec, "deps": deps});
        // FixME
        let data = json!({
            "result": {
                "widget": spec,
                "replace": false,
                "session": {
                    "user": {
                        "id": null,
                        "phone": null,
                    }
                },
                "deps": deps

            }
        });
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
            title, &CONFIG.site_icon, data, rendered, &CONFIG.latest_elm,
        ).into())
    }
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
    /*
    let metadata = sd.content(&format!("deps/{}/deps.json", latest))?;
    let metadata: HashMap<String, Vec<String>> = serde_json::from_str(&metadata)?;
    let mut deps = vec![];
    let mut skip_map = vec![];
    for id in ids.iter() {
        if skip_map.contains(&id.clone()) {
            continue;
        }
        skip_map.push(id.clone());

        if let Some(ref items) = metadata.get(id) {
            for item in items.iter() {
                skip_map.push(item.clone());
                deps.push(LayoutDeps {
                    module: item.clone(),
                    source: sd.content(&format!("deps/{}/{}.js", &latest, &item))?,
                });
            }
        }

        deps.push(LayoutDeps {
            module: id.clone(),
            source: sd.content(&format!("deps/{}/{}.js", &latest, &id))?,
        });
    }
    Ok(deps)
    */
    unimplemented!()
}

#[cfg(test)]
mod tests_fetch_deps {
    use crate::utils::LayoutDeps;

    fn check(d: Vec<&str>, e: N, c: &crate::Config) {
        assert_eq!(
            super::fetch_deps(d.iter().map(|s| s.to_string()).collect(), c).unwrap(),
            e.0
        );
    }

    fn fixture() -> crate::Config {
        let mut config = crate::Config::default();
        config.static_dir = "./examples/basic".into();
        config.latest_elm = "elm000".into();
        config.deps.insert("foo".into(), vec![]);
        config
            .js_code
            .insert("foo".into(), "function foo() {}".into());
        config
    }

    struct N(pub Vec<LayoutDeps>);
    impl N {
        fn o(module: &str, source: &str) -> Self {
            let mut n = N(vec![]);
            n.0.push(LayoutDeps {
                module: module.into(),
                source: source.into(),
            });
            n
        }
        fn with(mut self, module: &str, source: &str) -> Self {
            self.0.push(LayoutDeps {
                module: module.into(),
                source: source.into(),
            });
            self
        }
    }

    #[test]
    fn fetch_deps() {
        let sd = fixture();
        check(vec![], N(vec![]), &sd);
        check(vec!["foo"], N::o("foo", "function foo() {}"), &sd);
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
