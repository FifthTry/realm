
use realm::utils::{Maybe, url2path};


pub fn index(m: Maybe<i32>) -> String {
    let mut url = url::Url::parse("http://127.0.0.1:3000/").unwrap();
    url.query_pairs_mut().append_pair("m", &m.to_string());
    url2path(&url)
}

