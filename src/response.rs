use crate::mode::Mode;
use crate::PageSpec;

#[allow(clippy::large_enum_variant)]
pub enum Response {
    Http(http::response::Response<Vec<u8>>),
    JSON {
        data: Result<serde_json::Value, serde_json::Value>,
        context: Option<serde_json::Value>,
        trace: Option<serde_json::Value>,
    },
    Page(PageSpec),
}

#[observed(with_result, namespace = "realm__response")]
pub fn json<T>(data: &T) -> crate::Result
where
    T: serde::Serialize,
{
    Ok(Response::JSON {
        data: Ok(serde_json::to_value(data)?),
        context: None,
        trace: None,
    })
}

#[observed(with_result, namespace = "realm__response")]
pub fn json_ok() -> crate::Result {
    Ok(Response::JSON {
        data: Ok(serde_json::to_value("ok")?),
        context: None,
        trace: None,
    })
}

#[observed(with_result, namespace = "realm__response")]
pub fn json_with_context<T1, T2>(data: &T1, key: &str, value: &T2) -> crate::Result
where
    T1: serde::Serialize,
    T2: serde::Serialize,
{
    let context = if crate::base::is_test() {
        json!({
            "key": key,
            "value": value
        })
    } else {
        serde_json::Value::Null
    };

    Ok(Response::JSON {
        data: Ok(serde_json::to_value(data)?),
        context: Some(context),
        trace: None,
    })
}

pub fn err<T>(data: T) -> crate::Result
where
    T: serde::Serialize,
{
    Ok(Response::JSON {
        data: Err(serde_json::to_value(data)?),
        context: None,
        trace: None,
    })
}

impl Response {
    pub fn with_url(self, url: String) -> Response {
        match self {
            Response::Page(s) => Response::Page(s.with_url(url)),
            _ => self,
        }
    }
    pub fn with_replace(self, url: String) -> Response {
        match self {
            Response::Page(s) => Response::Page(s.with_replace(url)),
            _ => self,
        }
    }

    pub fn with_default_url(self, url: String) -> Response {
        match self {
            Response::Page(s) => Response::Page(s.with_default_url(url)),
            _ => self,
        }
    }

    pub fn render(
        self,
        ctx: &crate::Context,
        url: &str,
    ) -> std::result::Result<http::Response<Vec<u8>>, failure::Error> {
        let mut spec = match self.with_default_url(url.to_string()) {
            Response::Page(spec) => spec,
            Response::Http(r) => {
                return Ok(r);
            }
            Response::JSON {
                data,
                context,
                trace,
            } => {
                return Ok(ctx.response(serde_json::to_vec_pretty(&match data {
                    Ok(data) => json!({
                        "success": true,
                        "result": data,
                        "context": context,
                        "trace": trace,
                    }),
                    Err(msg) => json!({
                        "success": false,
                        "error": msg,
                        "context": context,
                        "trace": trace,
                    }),
                })?)?)
            }
        };

        ctx.header(http::header::CONTENT_TYPE, ctx.mode.content_type());
        spec.pure_mode = std::env::var("REALM_PURE")
            .map(|v| v.trim().to_string())
            .unwrap_or_else(|_| "".to_string());
        spec.pure = ctx.mode.is_pure();

        if spec.pure
            && std::env::var("REALM_EDGE")
                .map(|v| v == "cf")
                .unwrap_or(false)
        {
            println!("sending immutable header");
            ctx.header(
                http::header::CACHE_CONTROL,
                "immutable, public, max-age=3600000000",
            );
        }

        Ok(ctx.response(match ctx.mode {
            Mode::API => serde_json::to_string_pretty(&spec.config)?.into(),
            Mode::HTML => spec.render(false)?,
            Mode::SSR => spec.render(true)?,
            Mode::ISED | Mode::Pure => {
                serde_json::to_string_pretty(&spec.json_with_template()?)?.into()
            }
            Mode::Submit => serde_json::to_string_pretty(&json!({
                "success": true,
                "result": {
                    "kind": "navigate",
                    "data": spec.json_with_template()?,
                }
            }))?
            .into(),
        })?)
    }

    pub fn plain(ctx: &crate::Context, resp: String, status: http::StatusCode) -> crate::Result {
        ctx.status(status);
        Ok(Response::Http(ctx.response(resp.into_bytes())?))
    }

    pub fn redirect<T, UD>(in_: &crate::base::In<UD>, next: T) -> crate::Result
    where
        T: Into<String>,
        UD: crate::UserData,
    {
        use http::header;
        match in_.get_mode() {
            Mode::ISED => Ok(Response::Page(PageSpec {
                id: "".to_owned(),
                config: json!({}),
                title: "".to_owned(),
                url: None,
                replace: None,
                redirect: Some(next.into()),
                rendered: "".to_string(),
                cache: None,
                pure: false,
                pure_mode: "".into(),
                hash: crate::page::CURRENT.clone(),
                trace: None,
                activity: None,
            })),
            _ => {
                in_.ctx.header(header::LOCATION, next.into());
                in_.ctx.status(http::StatusCode::TEMPORARY_REDIRECT);
                Ok(Response::Http(in_.ctx.response("".into())?))
            }
        }
    }

    pub fn redirect_with<T, UD>(
        in_: &crate::base::In<UD>,
        next: T,
        status: http::StatusCode,
    ) -> crate::Result
    where
        T: Into<String>,
        UD: crate::UserData,
    {
        use http::header;
        match in_.get_mode() {
            Mode::ISED => Ok(Response::Page(PageSpec {
                id: "".to_owned(),
                config: json!({}),
                title: "".to_owned(),
                url: None,
                replace: None,
                redirect: Some(next.into()),
                rendered: "".to_string(),
                cache: None,
                pure: false,
                pure_mode: "".into(),
                hash: crate::page::CURRENT.clone(),
                trace: None,
                activity: None,
            })),
            _ => {
                in_.ctx.header(header::LOCATION, next.into());
                in_.ctx.status(status);
                Ok(Response::Http(in_.ctx.response("".into())?))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::PageSpec;
    use http::Response as HttpResponse;
    use serde_json::Value::Null;

    #[test]
    fn test_http_resp_default() {
        let http_resp = HttpResponse::default();
        let r = super::Response::Http(http_resp);
        assert_eq!(
            serde_json::to_value(r).unwrap(),
            json!({
                "Http": {
                    "body": "",
                    "status": 200
                }
            })
        );
    }

    #[test]
    fn test_http_resp_with_body() {
        let http_resp = HttpResponse::new("hello world".into());
        let r = super::Response::Http(http_resp);
        assert_eq!(
            serde_json::to_value(r).unwrap(),
            json!({
                "Http": {
                    "body": "hello world",
                    "status": 200
                }
            })
        );
    }

    #[test]
    fn test_page_spec() {
        let page_spec = PageSpec {
            id: "test-id".into(),
            config: json!({}),
            title: "test-title".into(),
            url: None,
            replace: None,
            redirect: None,
            rendered: "empty.html".to_string(),
            trace: None,
            activity: None,
        };
        let r = super::Response::Page(page_spec);
        assert_eq!(
            serde_json::to_value(r).unwrap(),
            json!({
                "PageSpec": {
                    "id": "test-id",
                    "config": json!({}),
                    "title": "test-title",
                    "url": Null,
                    "replace": Null,
                    "redirect": Null
                }
            })
        );
    }
}
