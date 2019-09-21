use serde::de::DeserializeOwned;
use std::{collections::HashMap, fmt::Debug, str::FromStr};

#[derive(Debug)]
pub struct RequestConfig {
    pub query: std::collections::HashMap<String, String>,
    pub data: serde_json::Value,
    pub rest: String,
    pub path: String,
}

#[derive(Fail, Debug)]
pub enum Error {
    #[fail(display = "Expected input parameter not found: {}", key)]
    NotFound { key: String },
    #[fail(display = "Can't parse {}={}, error: {}", key, value, message)]
    InvalidValue {
        key: String,
        value: String,
        message: String,
    },
}

pub fn sub_string(s: &str, start: usize, len: Option<usize>) -> String {
    match len {
        Some(len) => s.chars().skip(start).take(len).collect(),
        None => s.chars().skip(start).collect(),
    }
}

fn first_rest(s: &str) -> (Option<String>, String) {
    let mut parts = s.split('/');
    match parts.nth(0) {
        Some(v) => (Some(v.to_string()), sub_string(s, v.len() + 1, None)),
        None => (None, s.to_owned()),
    }
}

impl RequestConfig {
    pub fn new(req: &crate::Request) -> std::result::Result<RequestConfig, failure::Error> {
        let url = req.uri();
        let path = crate::utils::get_slash_complete_path(url.path());
        let url = url::Url::parse(&format!("http://foo.com{}", req.uri()).as_str())?;
        let rest = crate::utils::sub_string(path.as_ref(), path.len(), None);
        let data: serde_json::Value =
            serde_json::from_slice(req.body().as_slice()).unwrap_or_else(|_e| json!(null));
        let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();

        Ok(RequestConfig {
            rest,
            query,
            data,
            path,
        })
    }

    pub fn optional<T>(&mut self, name: &str) -> Result<Option<T>, Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        match self.param(name) {
            Ok(t) => Ok(Some(t)),
            Err(Error::NotFound { .. }) => Ok(None),
            Err(e) => Err(e),
        }
    }

    pub fn param<T>(&mut self, name: &str) -> Result<T, Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        let query: &HashMap<String, String> = &self.query;
        let data: &serde_json::Value = &self.data;
        let rest: &mut String = &mut self.rest;

        if !rest.is_empty() {
            let (first, last) = first_rest(&rest);
            rest.truncate(0);
            rest.push_str(&last);
            if let Some(v) = first {
                return match v.parse() {
                    Ok(v) => Ok(v),
                    Err(e) => {
                        // we have to do this because FromStr::Err is not Send/Sync
                        Err(Error::InvalidValue {
                            key: name.to_string(),
                            value: v.clone(),
                            message: format!("{:?}", e),
                        })?
                    }
                };
            }
        }

        if let Some(v) = query.get(name) {
            if v.is_empty() {
                return Err(Error::NotFound {
                    key: name.to_string(),
                });
            }
            return match v.parse() {
                Ok(v) => Ok(v),
                Err(e) => Err(Error::InvalidValue {
                    key: name.to_string(),
                    value: v.clone(),
                    message: format!("{:?}", e),
                })?,
            };
        }

        if let Some(v) = data.get(name) {
            if v.is_null() {
                return Err(Error::NotFound {
                    key: name.to_string(),
                });
            };
            return serde_json::from_value(v.to_owned()).map_err(|e| Error::InvalidValue {
                key: name.to_string(),
                value: v.to_string(),
                message: e.to_string(),
            });
        }

        Err(Error::NotFound {
            key: name.to_string(),
        })?
    }

    #[deprecated(since = "0.1.15", note = "Please use realm::router() instead")]
    pub fn get<T>(&mut self, name: &str, _is_optional: bool) -> Result<T, Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
        T: Default,
    {
        self.param(name)
    }
}
