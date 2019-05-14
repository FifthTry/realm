#[derive(Deserialize, Debug, Clone)]
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
        config
    };
}

impl Config {
    pub fn static_path(&self, rest: &str) -> std::path::PathBuf {
        std::path::Path::new(&self.static_dir).join(rest)
    }
}

impl crate::static_data::StaticData for Config {
    fn content(&self, path: &str) -> Result<String, failure::Error> {
        use std::io::Read;

        let latest_path = self.static_path(path);
        match std::fs::File::open(&latest_path) {
            Ok(mut latest) => {
                let mut latest_content = String::new();
                latest.read_to_string(&mut latest_content)?;
                Ok(latest_content.trim().to_string())
            }
            Err(_) => Err(failure::err_msg(format!("File not found: {}", path))),
        }
    }
}
