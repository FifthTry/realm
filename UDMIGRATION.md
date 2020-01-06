# Generic UD cookie Migration
- Define a struct `UD` in `ud.rs`. This struct contains fields to be included in
 ud 
    cookie.
```rust
pub struct UD {
    pub user_id: u64,
    pub display_name: String,
    pub session_id: u64,
}
```
- Implement `std::str::FromStr` and `std::string::ToString` traits for UD.
```rust
impl std::string::ToString for UD {
    fn to_string(&self) -> String {
        // Write your own logic to convert UD struct to cookie string format
        format!("{}|{}|{}", &user_id, &self.display_name, &session_id)
    }
}
```
```rust
impl std::str::FromStr for UD {
    type Err = failure::Error;
    fn from_str(ud: &str) -> Result<UD> {
        // Write your own logic to validate cookie and construct UD struct
        let parts: Vec<String> = ud.split('|').map(|v| v.to_string()).collect();
        if parts.len() != 3 {
            eprintln!("got cookie with invalid number of parts: {}", ud);
            return Err(failure::err_msg(format!(
                "got cookie with invalid number of parts: {}",
                ud
            )));
        }
        
        Ok(UD {
            user_id,
            display_name: parts[1].to_string(),
            session_id,
        })
    }
}
```
- Define an alias for `In` object in `ud.rs`. Include this `In` object in `prelude`
 or 
replace `realm::base::In` with `ud::In`.
```rust
pub type In<'a> = realm::base::In<'a, UD>;
```
- Define methods to retrieve fields from UD.
```rust
pub fn user_id(in_: &In) -> Option<u64> {
    match &*in_.ud() {
        Some(u) => Some(u.user_id),
        None => None,
    }
}
```
