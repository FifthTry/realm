#[derive(PartialEq, Debug, Clone, serde::Serialize)]
#[allow(clippy::upper_case_acronyms)]
pub struct TLDR {
    pub id: Option<String>,
    pub image: Option<String>,
    pub body: ftd_rt::Rendered,
}
