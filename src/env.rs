use std::env;

pub fn base_url() -> String {
    match env::var("REALM_BASE_URL") {
        Ok(url) => url,
        Err(_) => "http://127.0.0.1:3000".to_string(),
    }
}

pub fn store_response() -> bool {
    match env::var("REALM_STORE_RESPONSE") {
        Ok(v) => v == "true",
        Err(env::VarError::NotPresent) => true,
        Err(env::VarError::NotUnicode(_)) => false,
    }
}
