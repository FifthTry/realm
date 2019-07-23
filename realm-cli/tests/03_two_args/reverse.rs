use realm::utils::{Maybe, url2path};


pub fn index(i: i32, s: String) -> String {
    let mut url = url::Url::parse("http://127.0.0.1:3000/").unwrap();
    url.query_pairs_mut().append_pair("i", &i.to_string());
    url.query_pairs_mut().append_pair("s", &s.to_string());
    url2path(&url)
}

