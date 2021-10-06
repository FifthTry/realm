table! {
    realm_activity (id) {
        id -> Int4,
        url -> Text,
        method -> Text,
        ua -> Text,
        ip -> Text,
        okind -> Text,
        oid -> Text,
        ekind -> Text,
        data -> Jsonb,
        uid -> Nullable<Text>,
        sid -> Nullable<Text>,
        vid -> Text,
        vid_created -> Bool,
        tid -> Text,
        tid_created -> Bool,
        when -> Timestamptz,
        duration -> Int4,
        response -> Jsonb,
        outcome -> Text,
        code -> Text,
        trace -> Jsonb,
        hash -> Text,
        rust_trace -> Nullable<Text>,
        utm_source -> Nullable<Text>,
        utm_medium -> Nullable<Text>,
        utm_campaign -> Nullable<Text>,
        utm_term -> Nullable<Text>,
        utm_content -> Nullable<Text>,
        site_version -> Text,
    }
}

table! {
    realm_task (id) {
        id -> Int4,
        data -> Jsonb,
        cookies -> Jsonb,
        status -> Text,
        path -> Text,
        method -> Text,
        number_tries -> Int4,
        priority -> Int4,
        created_on -> Timestamptz,
        updated_on -> Timestamptz,
    }
}
