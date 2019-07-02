use crate::CONFIG;
use htmlescape;
use serde_json::Value;
use std::collections::HashMap;
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
    </body>
</html>"#,
            title, &CONFIG.site_icon, data, rendered, loader,
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

fn attach_uids(data: &mut serde_json::Value, count_map: &mut HashMap<String, u64>  ) {
    println!("au welcome");

    let mut edit_flag = false;
    match data {
        serde_json::Value::Object(o) => {
            if o.get("id") != None && o.get("config") != None{
                edit_flag = true;
            }

            if let Some(serde_json::Value::String(id)) = o.get("id") {
                let id = id.to_string();
                let mut uid = id.to_string();
                println!("au id {}", id);
                if edit_flag {
                    if let Some(count) = count_map.get_mut(id.as_str()){
                        uid.push_str(count.to_string().as_str());
                        *count += 1;

                    }
                    else{
                        count_map.insert(id, 1);
                        uid.push_str("0");
                    }

                    o.insert("uid".to_string(), serde_json::Value::String(uid));
                }else{
                        println!("au id but no config");
                }



            }

            for (_, value) in o.iter_mut() {
                attach_uids(value, count_map);
            }



        }
        serde_json::Value::Array(l) => {
            for o in  l.iter_mut() {
                attach_uids( o, count_map);
                println!("hello");
            }
        }
        _ => {}
    };
}

#[cfg(test)]
mod tests_attach_uids {

use std::collections::HashMap;
    fn check(i: serde_json::Value, o: serde_json::Value) {

        let mut count_map: HashMap<String, u64> = HashMap::new();
        let mut j = i.clone();
        super::attach_uids(&mut j, &mut count_map);
        assert_eq!(j, o);
    }

    #[test]
    fn attach_uids() {
        check(json!({}), json!({}));
        check(json!({"id": "f"}), json!({"id": "f"}));
        check(
            json!({"id": "f", "config": 0}),
            json!({"id": "f", "config": 0
            , "uid": "f0"
            })
        );
        check(
            json!({"id": "f"
             ,"config": {
                "id": "d"
                 ,"config": 0
               }
             }),
            json!({"id": "f"
             ,"config": {
                "id": "d"
                 ,"config": 0
                 ,"uid": "d0"
               }
             , "uid": "f0"
             })
        );

        check(
            json!({"id": "f"
             ,"config": {
                "id": "f"
                 ,"config": 0
               }
             }),
            json!({"id": "f"
             ,"config": {
                "id": "f"
                 ,"config": 0
                 ,"uid": "f1"
               }
             , "uid": "f0"
             })
        );

        check(
            json!({"id": "f"
             ,"config": {
                "id": "f"
                 ,"config": {
                    "id": "f"
                     ,"config": {
                        "id": "d"
                         ,"config": 0
                       }
                     ,"x":{

                        "id": "f"
                        ,"config": 0

                     }
                   }
                 ,"y":{
                    "z" : {
                         "id": "d"
                        ,"config": 0
                   }
                 }
               }
             }),
            json!({"id": "f"
             ,"config": {
                 "id": "f"
                 ,"config": {
                    "id": "f"
                     ,"config": {
                        "id": "d"
                         ,"config": 0
                         ,"uid": "d0"
                       }
                     ,"x":{

                        "id": "f"
                        ,"config": 0
                        , "uid": "f3"

                     }
                     , "uid": "f2"
                   }
                 ,"y":{
                    "z" : {
                         "id": "d"
                        ,"config": 0
                        ,"uid": "d1"
                   }
                 }
                 ,"uid": "f1"
               }
             , "uid": "f0"
             })
        );
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
