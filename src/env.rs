static CONTROL_C: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

pub fn ctrl_c() -> Result<bool, failure::Error> {
    if !*REALM_CATCH_CONTROL_C {
        return Err(format_err!("REALM_CATCH_CONTROL_C not set to true"));
    }

    Ok(CONTROL_C.load(std::sync::atomic::Ordering::Relaxed))
}

pub fn bool_with_default(name: &str, default: bool) -> bool {
    match std::env::var(name) {
        Ok(v) => match v.trim().to_lowercase().as_str() {
            "true" => true,
            "false" => false,
            _ => panic!("{} is {}, must be either true or false", name, v),
        },
        Err(std::env::VarError::NotPresent) => default,
        Err(std::env::VarError::NotUnicode(_)) => panic!("{} is wrongly set", name),
    }
}

pub fn base_url() -> String {
    match std::env::var("REALM_BASE_URL") {
        Ok(url) => url,
        Err(_) => "http://127.0.0.1:3000".to_string(),
    }
}

pub fn site_url() -> String {
    match std::env::var("REALM_SITE_URL") {
        Ok(url) => url,
        Err(_) => "https://www.fifthtry.com".to_string(),
    }
}

pub fn store_response() -> bool {
    match std::env::var("REALM_STORE_RESPONSE") {
        Ok(v) => v == "true",
        Err(std::env::VarError::NotPresent) => true,
        Err(std::env::VarError::NotUnicode(_)) => false,
    }
}

pub fn is_subdomain_cookie_allowed() -> bool {
    std::env::var("REALM_SUBDOMAIN_COOKIE").is_ok()
}

lazy_static! {
    pub static ref REALM_LANG: realm_lang::Language = default_language();
    pub static ref REALM_CATCH_CONTROL_C: bool = bool_with_default("REALM_CATCH_CONTROL_C", false);
    pub static ref REALM_SITE_URL: String =
        std::env::var("REALM_SITE_URL").expect("REALM_SITE_URL not found");
    pub static ref REALM_THREAD_POOL_SIZE: usize = std::env::var("REALM_THREAD_POOL_SIZE")
        .unwrap_or_else(|_| "40".to_string())
        .parse()
        .unwrap();
    pub static ref REALM_SECRET: String =
        std::env::var("REALM_SECRET").expect("REALM_SECRET not found");
}

fn default_language() -> realm_lang::Language {
    match std::env::var("REALM_LANG") {
        Ok(v) => v.parse().expect("unknown language"),
        Err(std::env::VarError::NotPresent) => realm_lang::Language::English,
        Err(std::env::VarError::NotUnicode(_)) => panic!("REALM_LANG env is not unicode"),
    }
}

pub fn check() {
    lazy_static::initialize(&REALM_LANG);
    lazy_static::initialize(&REALM_SITE_URL);
    lazy_static::initialize(&REALM_THREAD_POOL_SIZE);
    lazy_static::initialize(&REALM_SECRET);

    if *REALM_CATCH_CONTROL_C {
        ctrlc::set_handler(|| {
            println!("ignoring CTRL-C");
            CONTROL_C.store(false, std::sync::atomic::Ordering::SeqCst);
        })
        .expect("Error setting Ctrl-C handler");
    }
}
