use crate::routes;
use crate::cms;
use realm::utils::{get_slash_complete_path, get, sub_string};
use serde_json::Value;
use std::{collections::HashMap, env};
use url::Url;
use graft::{self, Context, DirContext};

pub fn get_default_context(cms_path: &str) -> impl Context {
     let mut proj_dir = env::current_dir().expect("could not find current dir");


    DirContext::new(proj_dir.join(cms_path).join("includes"))
}

pub fn magic(req: &realm::Request) -> realm::Result {
    let url = req.uri();
    let site_url = "http://127.0.0.1:3000".to_string();
    let path = get_slash_complete_path(url.path());
    let url = Url::parse(&format!("{}{}", &site_url, req.uri()).as_str())?;
    let mut rest = sub_string(path.as_ref(), path.len(), None);
    let data_: serde_json::Value = serde_json::from_slice(req.body().as_slice()).unwrap_or_else(|e| json!(null));
    let query_: HashMap<_, _> = url.query_pairs().into_owned().collect();
    match path.as_ref() {
        "/" => routes::index::layout(req),
        url_ => cms::layout(req, get_default_context("cms"), url_),
        _ => unimplemented!()
    }
}