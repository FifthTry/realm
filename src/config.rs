#[derive(Deserialize, Debug)]
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
        config
    };
}

impl Config {
    pub fn static_path(&self, rest: &str) -> std::path::PathBuf {
        std::path::Path::new(&self.static_dir).join(rest)
    }
}
