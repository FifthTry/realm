pub use crate::response::Response;
use diesel::{ExpressionMethods, RunQueryDsl};

pub fn end_context<UD, NF>(
    in_: &crate::base::In<UD>,
    resp: crate::Result,
    not_found: NF,
) -> crate::Result
where
    UD: crate::UserData,
    NF: FnOnce(&crate::base::In<UD>, &str) -> crate::Result,
{
    crate::base::pg::rollback_if_required(&in_.conn);
    use crate::schema::realm_activity;

    let mut response = serde_json::Value::Null; // empty data;
    let mut final_url = crate::utils::path_and_query(&crate::cleanup_url(&in_.ctx.url));

    let (resp, outcome, code) = match resp {
        Ok(r) => {
            response = match &r {
                Response::JSON {
                    data,
                    context: _,
                    trace: _,
                } => {
                    observer::log("returning json");
                    data.clone().unwrap_or_else(|_| serde_json::json!({}))
                }
                Response::Page(p) => {
                    observer::observe_string("id", p.id.as_str());

                    if let Some(ref url) = p.url {
                        if final_url != url.as_str() {
                            final_url = url.to_string();
                            observer::observe_string("url", url.as_str());
                        }
                    };
                    if let Some(ref url) = p.redirect {
                        final_url = url.to_string();
                        observer::observe_string("redirect", url.as_str());
                    }
                    if let Some(ref url) = p.replace {
                        final_url = url.to_string();
                        observer::observe_string("replace", url.as_str());
                    }
                    p.config.clone()
                }
                _ => serde_json::json!({}),
            };
            (Ok(r), "success".to_string(), "success".to_string())
        }
        Err(e) => {
            match e.downcast_ref::<crate::Error>() {
                Some(crate::Error::PageNotFound { message }) => {
                    observer::log("PageNotFound2");
                    observer::observe_string("error", message.as_str()); // TODO
                    (
                        not_found(&in_, message.as_str()),
                        "user_error".to_string(),
                        "not_found".to_string(),
                    )
                }
                Some(crate::Error::InputError { error }) => {
                    let e = error.to_string();
                    observer::log("InputError");
                    observer::observe_json("error", serde_json::to_value(&e)?); // TODO
                    (
                        not_found(&in_, e.as_str()),
                        "user_error".to_string(),
                        "input_error".to_string(),
                    )
                }
                Some(crate::Error::FormError {
                    errors,
                    success,
                    code,
                    data: _,
                }) => {
                    observer::log("FormError");
                    observer::observe_json("form_error", serde_json::to_value(&errors)?); // TODO
                    response = serde_json::to_value(&errors).expect("TODO");
                    (
                        in_.form_error(&errors),
                        success.to_string(),
                        code.to_string(),
                    )
                }
                _ => match e.downcast_ref::<diesel::result::Error>() {
                    Some(diesel::result::Error::NotFound) => {
                        observer::log("diesel::NotFound");
                        (
                            not_found(&in_, "NotFound"),
                            "user_error".to_string(),
                            "diesel_not_found".to_string(),
                        )
                    }
                    _ => (Err(e), "server_error".to_string(), "unknown".to_string()),
                },
            }
        }
    };

    let store = store_activity(in_);

    in_.ctx.set_step(crate::rr::Step {
        method: in_.ctx.method.to_string(),
        path: crate::utils::path_and_query(&in_.ctx.url),
        body: in_.ctx.body.clone(),
        test_trace: observer::test_trace().expect("record called without observer context"),
        activity: in_.get_activity(),
        final_url,
    });

    if store {
        // call before observer::end_context()
        crate::rr::record(in_, &resp);
    }

    let hash = observer::shape_hash(); // do this before ending context
    let v = observer::end_context().expect("create_context() not called");

    // TODO: this does not handle panic!() (None::unwrap!() etc)
    let rust_trace = match resp {
        Ok(_) => None,
        Err(ref e) => Some(e.to_string()),
    };

    if store {
        let ip = in_
            .ctx
            .get_header_string("x-forwarded-for")
            .unwrap_or_else(|| "".to_string());

        let activity = in_.get_activity();
        let site_version = SITE_VERSION.to_string();
        let (tid_created, vid_created) = in_.get_tid_vid_created_values()?;
        let (tid, vid) = in_.get_tid_vid_cookies()?;
        let trace = serde_json::json!(v);
        let duration: i32 = trace["span_stack"][0]["duration"]
            .as_i64()
            .unwrap_or_else(|| -1) as i32;

        diesel::insert_into(realm_activity::table)
            .values((
                realm_activity::url.eq(in_.ctx.url.to_string()),
                realm_activity::method.eq(in_.ctx.method.to_string()),
                realm_activity::okind.eq(activity.okind),
                realm_activity::oid.eq(activity.oid),
                realm_activity::ekind.eq(activity.ekind),
                realm_activity::data.eq(activity.data),
                realm_activity::trace.eq(trace),
                realm_activity::hash.eq(hash),
                realm_activity::rust_trace.eq(rust_trace),
                realm_activity::response.eq(response),
                realm_activity::uid.eq(in_.user_id()),
                realm_activity::when.eq(in_.now),
                realm_activity::outcome.eq(outcome),
                realm_activity::code.eq(code),
                realm_activity::duration.eq(duration),
                realm_activity::site_version.eq(site_version),
                realm_activity::ua.eq(in_.user_agent().unwrap_or_else(|| "".to_string())),
                realm_activity::ip.eq(ip),
                realm_activity::sid.eq(in_.session_id()),
                // tid, vic
                realm_activity::tid.eq(tid),
                realm_activity::tid_created.eq(tid_created),
                realm_activity::vid.eq(vid),
                realm_activity::vid_created.eq(vid_created),
                // UTM
                realm_activity::utm_source.eq(in_.ctx.query.get("utm_source")),
                realm_activity::utm_medium.eq(in_.ctx.query.get("utm_medium")),
                realm_activity::utm_campaign.eq(in_.ctx.query.get("utm_campaign")),
                realm_activity::utm_term.eq(in_.ctx.query.get("utm_term")),
                realm_activity::utm_content.eq(in_.ctx.query.get("utm_content")),
            ))
            .execute(in_.conn)?;
    }

    match resp {
        Ok(crate::Response::Page(page)) if in_.is_dev() => {
            page.with_trace(v /*, fs_trace, diff*/)
                .map(crate::Response::Page)
        }
        Ok(crate::Response::JSON { data, context, .. }) if in_.is_dev() => {
            Ok(crate::Response::JSON {
                data,
                context,
                trace: Some(serde_json::to_value(v)?),
            })
        }
        resp => resp,
    }
}

pub fn store_activity<UD>(in_: &crate::base::In<UD>) -> bool
where
    UD: crate::UserData,
{
    let url = in_.ctx.url.path().to_lowercase();

    if in_.ctx.is_crawler {
        return false;
    }

    if url.ends_with(".png") {
        return false;
    }

    if url.starts_with("/static/") {
        return false;
    }

    if url == "/favicon.ico" {
        return false;
    }

    if url.starts_with("/test/") {
        return false;
    }

    if url == "/iframe/" {
        return false;
    }

    true
}

lazy_static! {
    static ref SITE_VERSION: String = format!(
        "{}: {}",
        std::env::var("VERGEN_BUILD_TIMESTAMP")
            .unwrap_or_else(|_| "".to_string())
            .chars()
            .take(19)
            .collect::<String>(),
        {
            let sha = std::env::var("VERGEN_SHA_SHORT").unwrap_or_else(|_| "".to_string());
            if sha.is_empty() {
                std::env::var("HEROKU_SLUG_COMMIT")
                    .map(|v| v.chars().take(7).collect())
                    .unwrap_or_else(|_| "unknown".to_string())
            } else {
                sha
            }
        }
    );
}
