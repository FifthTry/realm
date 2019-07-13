use itertools::Itertools;
use chrono::NaiveDate;
use serde_json::Value as JsonValue;
use std::{

    fmt::{Debug, Display},
    fs,
    io::{Read, Write},
    ops::{Add, Deref},
    str::FromStr,
    string::String,
};
use url::Url;

pub fn get_slash_complete_path(path: &str) -> String {
    if path.ends_with("/") {
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
            .unwrap_or("".to_owned())
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
                Err(e) => Err(failure::err_msg(format!("can't parse: {:?}", e))),
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
                Err(e) => Err(failure::err_msg(format!("can't parse")))?,
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