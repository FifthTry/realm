#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LayoutDeps {
    pub module: String,
    pub source: String,
}
