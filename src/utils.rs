use itertools::Itertools;
use serde::de::DeserializeOwned;
use std::{
    collections::HashMap,
    fmt::{Debug, Display},
    ops::Deref,
    str::FromStr,
    string::String,
};
use url::Url;

pub fn set_cookie(name: &str, value: &str, age: i32) -> Result<http::HeaderValue, failure::Error> {
    http::HeaderValue::from_str(format!("{}={}; Max-Age={}; Path=/", name, value, age).as_str())
        .map_err(|e| format_err!("error: {:?}", e))
}

pub fn get_slash_complete_path(path: &str) -> String {
    if path.ends_with('/') {
        path.to_string()
    } else {
        format!("{}/", path)
    }
}

pub fn url2path(url: &Url) -> String {
    let url = url.clone();
    let mut search_str = url
        .query_pairs()
        .filter(|(_, v)| v != "null")
        .map(|(k, v)| format!("{}={}", k, v))
        .join("&");
    if search_str != "" {
        search_str = format!("?{}", search_str);
    };
    format!("{}{}", url.path(), search_str)
}

pub fn uri2path(uri: &hyper::Uri) -> String {
    format!(
        "{}{}",
        uri.path(),
        uri.query()
            .map(|q| format!("?{}", q))
            .unwrap_or_else(|| "".to_owned())
    )
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Maybe<T>(pub Option<T>);

impl<T> FromStr for Maybe<T>
where
    T: FromStr,
    <T as FromStr>::Err: Debug,
{
    type Err = failure::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "null" => Ok(Maybe(None)),
            _ => match s.parse() {
                Ok(v) => Ok(Maybe(Some(v))),
                Err(e) => Err(format_err!("can't parse: {:?}", e)),
            },
        }
    }
}

impl<T: ToString> ToString for Maybe<T> {
    fn to_string(&self) -> String {
        match self.0 {
            Some(ref t) => t.to_string(),
            None => "null".to_owned(),
        }
    }
}

impl<T> Deref for Maybe<T> {
    type Target = Option<T>;

    fn deref(&self) -> &Option<T> {
        &self.0
    }
}

impl<T> Default for Maybe<T> {
    fn default() -> Self {
        Maybe(None)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct List<T>(pub Vec<T>);

impl<T: ToString> ToString for List<T>
where
    T: Display,
{
    fn to_string(&self) -> String {
        self.0.iter().join("||")
    }
}

// TODO need to write test case for this
impl<T> FromStr for List<T>
where
    T: FromStr,
    <T as FromStr>::Err: Debug,
{
    type Err = failure::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut vec_t = Vec::new();
        for each_element in s.split("||") {
            let element: T = match each_element.parse() {
                Ok(v) => v,
                Err(_e) => return Err(failure::err_msg("can't parse".to_string())),
            };
            vec_t.push(element);
        }
        Ok(List(vec_t))
    }
}

impl<T> Deref for List<T> {
    type Target = Vec<T>;

    fn deref(&self) -> &Vec<T> {
        &self.0
    }
}

impl<T> Default for List<T> {
    fn default() -> Self {
        List(Vec::new())
    }
}

fn first_rest(s: &str) -> (Option<String>, String) {
    let mut parts = s.split('/');
    match parts.next() {
        Some(v) => (Some(v.to_string()), sub_string(s, v.len() + 1, None)),
        None => (None, s.to_owned()),
    }
}

pub fn sub_string(s: &str, start: usize, len: Option<usize>) -> String {
    match len {
        Some(len) => s.chars().skip(start).take(len).collect(),
        None => s.chars().skip(start).collect(),
    }
}

pub fn get<T, S: ::std::hash::BuildHasher>(
    name: &str,
    query: &HashMap<String, String, S>,
    data: &serde_json::Value,
    rest: &mut String,
    is_optional: bool,
) -> Result<T, failure::Error>
where
    T: FromStr + DeserializeOwned + Default,
    <T as FromStr>::Err: Debug,
{
    // handle path
    if !rest.is_empty() {
        let (first, last) = first_rest(&rest);
        rest.truncate(0);
        rest.push_str(&last);
        if let Some(v) = first {
            return match v.parse() {
                Ok(v) => Ok(v),
                Err(e) => return Err(format_err!("can't parse rest: {:?}", e)),
            };
        }
    }

    if let Some(v) = query.get(name) {
        return match v.parse() {
            Ok(v) => Ok(v),
            Err(e) => return Err(format_err!("can't parse query: {:?}", e)),
        };
    }

    // TODO: if T is Option<X>, then we should not fail if key is not present in json
    if let Some(v) = data.get(name) {
        return match serde_json::from_value(v.to_owned()) {
            Ok(v) => Ok(v),
            Err(e) => return Err(format_err!("can't parse data: {:?}", e)),
        };
    }

    if is_optional {
        return Ok(T::default());
    }

    Err(format_err!("\"{}\" not found", name))
}

pub fn append_params(prefix: &str, q_params: &[(String, String)]) -> String {
    let mut url: String = prefix.into();
    for (arg, val) in q_params {
        if !url.contains('?') {
            url.push_str(&format!("?{}={}", arg, val));
        } else {
            url.push_str(&format!("&{}={}", arg, val));
        }
    }
    url
}
