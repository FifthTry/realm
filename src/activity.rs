#[cfg(feature = "postgres")]
table! {
    realm_activity (id) {
        id -> Integer,
        okind -> Text,
        oid -> Text,
        ekind -> Text,
        data -> Text,
        trace -> Text,
        response -> Text,
        when -> Timestamptz,
        ip -> Text,
        app -> Text,
        site_version -> Text,
        session_id -> Nullable<Text>,
        who_id -> Nullable<Text>,
        url -> Text,
    }
}

#[cfg(feature = "sqlite")]
table! {
    realm_activity (id) {
        id -> Integer,
        okind -> Text,
        oid -> Text,
        ekind -> Text,
        data -> Text,
        trace -> Text,
        response -> Text,
        when -> Timestamp,
        ip -> Text,
        app -> Text,
        site_version -> Text,
        session_id -> Nullable<Text>,
        who_id -> Nullable<Text>,
        url -> Text,
    }
}

#[derive(Debug)]
pub struct Activity {
    pub okind: String,
    pub oid: String,
    pub ekind: String,
    pub data: serde_json::Value,
}
