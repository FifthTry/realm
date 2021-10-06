pub use in_::{In, In0, UD};
pub use utils::elapsed;

mod db;
pub(crate) mod in_;
#[cfg(feature = "postgres")]
pub mod pg;
#[cfg(feature = "sqlite")]
pub mod sqlite;

#[cfg(feature = "postgres")]
pub mod point;

mod utils;

pub type Request = http::Request<Vec<u8>>;
pub type Result<T> = std::result::Result<T, failure::Error>;

pub fn error_stack(err: &failure::Error) -> String {
    let mut b = "".to_string();
    for cause in err.iter_causes() {
        b.push_str(&format!("{}\n", cause));
    }
    b.push_str(&format!("{}\n", err.backtrace()));
    b
}

pub fn is_test() -> bool {
    std::env::args().any(|e| e == "--test" || e == "--replay")
}

#[observed(namespace = "realm", with_result)]
pub fn hash_password(password: &str) -> Result<String> {
    bcrypt::hash(
        password,
        if is_test() {
            /* if we do not do this, tests are too slow */
            4
        } else {
            bcrypt::DEFAULT_COST
        },
    )
    .map_err(|e| e.into())
}

#[observed(namespace = "realm", with_result)]
pub fn verify_password(password: &str, hash: &str) -> Result<bool> {
    bcrypt::verify(password, hash).map_err(|e| e.into())
}
