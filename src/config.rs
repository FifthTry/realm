use std::collections::HashMap;

#[derive(Deserialize, Debug, Default)]
pub(crate) struct Config {
    #[serde(default)]
    pub context: String,
    #[serde(default)]
    pub site_icon: String,
    #[serde(default)]
    pub css: Vec<String>,
    #[serde(default)]
    pub head_extra: String,
    #[serde(default)]
    pub body_extra: String,
    #[serde(default)]
    pub site_title_prefix: String,
    #[serde(default)]
    pub site_title_postfix: String,
    #[serde(default)]
    pub static_dir: String,

    #[serde(default)]
    pub latest_elm: String,
    #[serde(default)]
    pub deps: HashMap<String, Vec<String>>,
    #[serde(default)]
    pub js_code: HashMap<String, String>,
}

lazy_static! {
    pub(crate) static ref CONFIG: Config = {
        let proj_dir = std::env::current_dir().expect("could not find current dir");
        let conf_file = proj_dir.join("realm.json");
        let conf_file = std::fs::File::open(conf_file).expect("could not load settings.json");
        let mut config: Config = serde_json::from_reader(conf_file).expect("invalid json");
        if config.static_dir == "" {
            config.static_dir = "static".into();
        };
        if config.site_icon == "" {
            config.site_icon = "/static/favicon.ico".into();
        }

        config.init_elm().expect("failed to initialize elm stuff");
        config
    };
}

impl Config {
    pub fn static_path(&self, rest: &str) -> std::path::PathBuf {
        std::path::Path::new(&self.static_dir).join(rest)
    }

    pub fn get_code(&self, id: &str) -> Result<String, failure::Error> {
        self.js_code
            .get(id)
            .map(|c| c.clone())
            .ok_or_else(|| failure::err_msg("key not found"))
    }

    pub fn init_elm(&mut self) -> Result<(), failure::Error> {
        self.latest_elm = self.content("realm/latest.txt")?;
        self.deps =
            serde_json::from_str(&self.content(&format!("realm/{}/deps.json", &self.latest_elm))?)?;

        for entry in std::fs::read_dir(self.static_path(&format!("realm/{}/", &self.latest_elm)))? {
            let entry = entry?;
            println!("entry.file_name: {:?}", entry.file_name());
            let name = entry.file_name().into_string().unwrap();
            if !name.ends_with(".js") {
                continue;
            }

            let name = entry
                .path()
                .file_stem()
                .unwrap()
                .to_owned()
                .into_string()
                .unwrap();
            self.js_code.insert(
                name.into(), // FIXME
                self.content2(entry.path())?,
            );
        }

        Ok(())
    }

    fn content(&self, path: &str) -> Result<String, failure::Error> {
        let path = self.static_path(path);
        self.content2(path)
    }

    fn content2(&self, path: std::path::PathBuf) -> Result<String, failure::Error> {
        use std::io::Read;

        match std::fs::File::open(&path) {
            Ok(mut latest) => {
                let mut latest_content = String::new();
                latest.read_to_string(&mut latest_content)?;
                Ok(latest_content.trim().to_string())
            }
            Err(_) => Err(failure::err_msg(format!("File not found: {:?}", path))),
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn init_elm() {
        let mut config = super::Config::default();
        config.static_dir = "./examples/basic/static".into();
        config.init_elm().expect("could not load init elm");

        assert_eq!(config.latest_elm, "elatest");

        assert_eq!(config.deps.len(), 2);
        assert_eq!(config.deps.get("foo").unwrap(), &vec!["bar".to_string()]);
        assert_eq!(config.deps.get("bar").unwrap().len(), 0);

        assert_eq!(config.js_code.len(), 2);
        assert_eq!(config.js_code.get("foo").unwrap(), "function foo() {bar()}");
        assert_eq!(config.js_code.get("bar").unwrap(), "function bar() {}");
    }
}
