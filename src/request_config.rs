

#[derive(Debug)]
pub struct RequestConfig{
    pub req: crate::Request,
    pub query: std::collections::HashMap<String, String>,
    pub data: serde_json::Value,
    pub rest: String,
    pub url: url::Url,
    pub path: String,
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
}
