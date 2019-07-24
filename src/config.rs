use std::collections::HashMap;
use std::path::Path;
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
    #[serde(default)]
    pub loader_file: String,

}
impl Config{
    pub fn new() -> Self {
        Config{

             context: "".to_string(),

             site_icon: "/static/favicon.ico".to_string(),

             css: vec![],

             head_extra: "".to_string(),

             body_extra: "".to_string(),

             site_title_prefix: "".to_string(),

             site_title_postfix: "".to_string(),

             static_dir: "static".to_string(),


             latest_elm: "".to_string(),

             deps: HashMap::new(),

             js_code: HashMap::new(),

             loader_file: "".to_string(),
        }
    }
}
lazy_static! {
    pub(crate) static ref CONFIG: Config = {
        let proj_dir = std::env::current_dir().expect("could not find current dir");
        let conf_file = proj_dir.join("realm.json");
        let mut config: Config = Config::new();
        match std::fs::File::open(conf_file){
            Ok(conf_file) => {
                config = serde_json::from_reader(conf_file).expect("invalid json")
            },
            Err(e) => {
                println!("could not find realm.json. Trying Default Json.")
            }
        };



        if config.loader_file == ""{
            config.loader_file = proj_dir.join("node_modules").join("realm_javascript").join("lib").join("loader.js").into_os_string().into_string().unwrap();
        }

        config.init_elm().expect("failed to initialize elm stuff");
        config
    };
}


fn get_prefix(path: &Path, parent_path: &Path) -> Result<String, failure::Error>{
    let dir_path = path.clone();
    println!("diryy_path {:?}", dir_path);
    let strip_dir = dir_path.strip_prefix(parent_path.to_str().unwrap())?;
    let mut relative_path_st = strip_dir.to_str().unwrap().to_string();
    if relative_path_st != "".to_string(){
        relative_path_st = relative_path_st.replace("/", ".");
        relative_path_st.push('.');
        Ok(relative_path_st)
    }
    else {
        Ok("".to_string())
    }
}

impl Config {
    pub fn static_path(&self, rest: &str) -> std::path::PathBuf {
      Path::new(&self.static_dir).join(rest)
    }

    pub fn get_code(&self, id: &str) -> Result<String, failure::Error> {
        println!("herez {:?}", id);
        for (k, v) in &self.js_code{
            println!("{}", k);
        }
        self.js_code
            .get(id)
            .map(|c| c.clone())
            .ok_or_else(|| failure::err_msg("key not found"))
    }

    fn set_js_code_recur(&mut self, path: &Path, parent_path: &Path) -> Result<(), failure::Error>{
        println!("dir {:?}", path.file_name());

        let mut name_prefix = get_prefix(path, parent_path)?;
        println!("name_prefix {:?}", name_prefix);
        for entry in std::fs::read_dir(path)? {
                let entry = entry?;

                println!("entry.file_name: {:?}", entry.file_name());
                if entry.path().is_dir() {
                    let entry_path = entry.path();
                    self.set_js_code_recur(&entry_path, &parent_path)?;
                }
                let name = entry.file_name().into_string().unwrap();
                if !name.ends_with(".js") {
                    continue;
                }





                let mut name = entry
                    .path()
                    .file_stem()
                    .unwrap()
                    .to_owned()
                    .into_string()
                    .unwrap();

                //name_prefix.push_str(&name);


                name = format!("{}{}", name_prefix, name);
                println!("name {:?}", entry.path().file_stem());
                self.js_code.insert(
                    name.into(), // FIXME
                    self.content2(entry.path())?,
                );
        }
        Ok(())
    }

    pub fn init_elm(&mut self) -> Result<(), failure::Error> {
        self.latest_elm = self.content("realm/latest.txt")?;
        self.deps =
            serde_json::from_str(&self.content(&format!("realm/{}/deps.json", &self.latest_elm))?)?;
        let path = self.static_path(&format!("realm/{}/", &self.latest_elm));

//        if let Some(path) = entry_dir{
//            self.latest_elm = path.file_name().into_string().unwrap();
//        }
        self.set_js_code_recur(&path, &path)?;



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

    #[cfg(test)]
    pub(crate) fn test() -> Self {
        let mut config = Config::default();
        config.static_dir = "./examples/basic/static".into();
        config.init_elm().expect("could not load init elm");
        config
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn init_elm() {
        let config = super::Config::test();
        assert_eq!(config.latest_elm, "elatest");

        assert_eq!(config.deps.len(), 2);
        assert_eq!(config.deps.get("f").unwrap(), &vec!["bar".to_string()]);
        assert_eq!(config.deps.get("bar").unwrap().len(), 0);

        assert_eq!(config.js_code.len(), 2);
        assert_eq!(config.js_code.get("f").unwrap(), "function f() {bar()}");
        assert_eq!(config.js_code.get("bar").unwrap(), "function bar() {}");
    }
}
