
use std::{
    collections::HashMap,
    str::FromStr,
    fmt::{Debug, Display},
};
use serde_json::Value as JsonValue;
use serde::de::DeserializeOwned;
#[derive(Debug)]
pub struct RequestConfig{
    pub req: crate::Request,
    pub query: std::collections::HashMap<String, String>,
    pub data: serde_json::Value,
    pub rest: String,
    pub url: url::Url,
    pub path: String,
}

pub fn sub_string(s: &str, start: usize, len: Option<usize>) -> String {
    match len {
        Some(len) => s.chars().skip(start).take(len).collect(),
        None => s.chars().skip(start).collect(),
    }
}

fn first_rest(s: &str) -> (Option<String>, String) {
    let mut parts = s.split("/");
    match parts.nth(0) {
        Some(v) => (Some(v.to_string()), sub_string(s, v.len() + 1, None)),
        None => (None, s.to_owned()),
    }
}

impl RequestConfig{
    pub fn new(req: crate::Request) -> std::result::Result<RequestConfig, failure::Error> {
        let url = req.uri();
        let path = crate::utils::get_slash_complete_path(url.path());
        let site_url = "http://127.0.0.1:3000".to_string();
        let url = url::Url::parse(&format!("{}{}", &site_url, req.uri()).as_str())?;
        let mut rest = crate::utils::sub_string(path.as_ref(), path.len(), None);
        let data: serde_json::Value = serde_json::from_slice(req.body().as_slice()).unwrap_or_else(|e| json!(null));
        let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();
        //let req_ = req.clone();
        let req_config = RequestConfig{
            url,
            rest,
            query,
            data,
            path,
            req,
        };
        Ok(req_config)
    }


    pub fn get<T>(&mut self,
        name: &str,
        is_optional: bool,
    ) -> Result<T, failure::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
        T: Default,
    {
        // handle path

        let query: &HashMap<String, String> = &self.query;
        let data: &serde_json::Value = &self.data;
        let rest: &mut String = &mut self.rest;


        if rest.len() != 0 {
            let (first, last) = first_rest(&rest);
            rest.truncate(0);
            rest.push_str(&last);
            if let Some(v) = first {
                return match v.parse() {
                    Ok(v) => Ok(v),
                    Err(e) => Err(failure::err_msg(format!("can't parse rest: {:?}", e)))?,
                };
            }
        }

        if let Some(v) = query.get(name) {
            return match v.parse() {
                Ok(v) => Ok(v),
                Err(e) => Err(failure::err_msg(format!("can't parse query: {:?}", e)))?,
            };
        }

        // TODO: if T is Option<X>, then we should not fail if key is not present in json
        if let Some(v) = data.get(name) {
            return match serde_json::from_value(v.to_owned()) {
                Ok(v) => Ok(v),
                Err(e) => Err(failure::err_msg(format!("can't parse data: {:?}", e)))?,
            };
        }

        if is_optional {
            return Ok(T::default());
        }
        Err(failure::err_msg(format!("\"{}\" not found", name)))?
    }
}
