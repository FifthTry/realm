pub use chrono::{DateTime, Utc};
use itertools::Itertools;
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use serde::de::DeserializeOwned;

use std::{
    collections::HashMap,
    fmt::{Debug, Display},
    ops::Deref,
    str::FromStr,
    string::String,
};

pub fn get_domain_from_url(inp_str: String) -> String {
    const TEXTS: [&str; 3] = ["http://", "https://", "www."];
    let mut out_str: String = inp_str;
    for text in TEXTS.iter() {
        out_str = out_str.trim_start_matches(text).to_string();
    }
    out_str
}

#[allow(clippy::logic_bug)]
pub fn set_cookie(name: &str, value: &str, age: i64) -> String {
    let domain = if false && crate::env::is_subdomain_cookie_allowed() {
        let domain_name = get_domain_from_url(crate::env::site_url());
        format!("domain={}", domain_name)
    } else {
        "".to_string()
    };
    format!("{}={}; Max-Age={}; Path=/; {}", name, value, age, &domain)
}

pub fn get_slash_complete_path(path: &str) -> String {
    if path.ends_with('/') {
        path.to_string()
    } else {
        format!("{}/", path)
    }
}

pub fn to_url(path_and_query: &str) -> url::Url {
    url::Url::parse(format!("http://foo.com{}", path_and_query).as_str()).unwrap()
}

pub fn path_and_query(url: &url::Url) -> String {
    let mut f = url.path().to_string();
    if let Some(q) = url.query() {
        f.push('?');
        f.push_str(q)
    }
    f
}

pub fn url2path(url: &url::Url) -> String {
    let url = url.clone();
    let mut search_str = url
        .query_pairs()
        .filter(|(_, v)| v != "null")
        .map(|(k, v)| format!("{}={}", k, v))
        .join("&");
    if !search_str.is_empty() {
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

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone, PartialEq)]
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

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone)]
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

pub fn first_rest(s: &str) -> (Option<String>, String) {
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

pub fn datetime_serializer<S>(x: &DateTime<Utc>, s: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    s.serialize_i64(x.timestamp_millis())
}

pub fn option_datetime_serializer<S>(x: &Option<DateTime<Utc>>, s: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    match x {
        Some(v) => s.serialize_i64(v.timestamp_millis()),
        None => s.serialize_none(),
    }
}

pub fn datetime_serializer_t<S>(x: &DateTime<Utc>, s: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    if crate::base::is_test() {
        s.serialize_i64(0)
    } else {
        s.serialize_i64(x.timestamp_millis())
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
        let (first, last) = first_rest(rest);
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

pub fn get_random_alphanumeric_string(length: usize) -> String {
    thread_rng()
        .sample_iter(&Alphanumeric)
        .take(length)
        .map(char::from)
        .collect()
}

pub fn request_with_url(
    req: crate::Request,
    url: &str,
    method: Option<http::Method>,
) -> Result<crate::Request, failure::Error> {
    let (mut parts, _) = req.into_parts();
    if let Some(method) = method {
        parts.method = method;
    }
    parts.uri = http::Uri::from_str(url)
        .map_err(|e| failure::format_err!("Invalid url: {}", e.to_string()))?;
    Ok(http::Request::from_parts(parts, vec![]))
}

pub fn request_with_slash(req: crate::Request) -> (bool, crate::Request) {
    fn has_extension(path: &str) -> bool {
        use std::path::Path;
        Path::new(path).extension().is_some()
    }

    let uri = req.uri();

    if !uri.path().ends_with('/') && req.method() == http::Method::GET && !has_extension(uri.path())
    {
        let mut s = "".to_string();
        if let Some(scheme) = uri.scheme_part() {
            s += format!("{}://", scheme.to_string()).as_str()
        }
        if let Some(authority) = uri.authority_part() {
            s += authority.to_string().as_str();
        }

        if uri.path().ends_with('/') {
            s += uri.path()
        } else {
            s += format!("{}/", uri.path()).as_str()
        };

        if let Some(query) = uri.query() {
            s += format!("?{}", query).as_str()
        }
        (true, request_with_url(req, s.as_str(), None).unwrap())
    } else {
        (false, req)
    }
}
