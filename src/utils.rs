#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct LayoutDeps {
    pub module: String,
    pub source: String,
}
