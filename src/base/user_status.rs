pub enum UserStatus {
    EmailNotConfirmed,
    Ready,
    Flagged,
    Suspended,
    Deactivated,
}

impl UserStatus {
    #[allow(clippy::wrong_self_convention)]
    pub fn to_string(_status: Vec<UserStatus>) -> String {
        unimplemented!()
    }
}
