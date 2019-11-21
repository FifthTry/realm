use crate::mode::Mode;
use crate::PageSpec;
use http::StatusCode;
use serde::ser::{Serialize, SerializeStructVariant, Serializer};

pub enum Response {
    Http(http::response::Response<Vec<u8>>),
    Page(PageSpec),
}

impl Response {
    pub fn with_url(self, url: String) -> Response {
        match self {
            Response::Http(r) => Response::Http(r),
            Response::Page(s) => Response::Page(s.with_url(url)),
        }
    }

    pub fn with_default_url(self, url: String) -> Response {
        match self {
            Response::Http(r) => Response::Http(r),
            Response::Page(s) => Response::Page(s.with_default_url(url)),
        }
    }

    pub fn render(self, ctx: &crate::Context, mode: Mode, url: String) -> crate::Result {

        let user_agent:Option<String> = ctx
            .request
            .headers()
            .get(http::header::USER_AGENT)
            .and_then(|v| v.to_str().ok())
            .map(|v| v.to_string());

        println!("inside render: user_agent -  {:?}", user_agent);



        if let Response::Http(r) = self {
            return Ok(r);
        };

        let r = self.with_default_url(url);

        match &r {
            Response::Page(spec) => {
                ctx.header(http::header::CONTENT_TYPE, mode.content_type());

                Ok(ctx.response(match mode {
                    Mode::API => serde_json::to_string_pretty(&spec.config)?.into(),
                    Mode::HTML => spec.render(ctx.is_crawler(user_agent))?,
                    Mode::Layout => serde_json::to_string(&spec)?.into(),
                    Mode::Submit => serde_json::to_string(&json!({
                        "success": true,
                        "result": {
                            "kind": "navigate",
                            "data": spec,
                        }
                    }))?
                    .into(),
                })?)
            }
            Response::Http(_) => unreachable!(),
        }
    }

    pub fn ok<T>(in_: &crate::base::In, data: &T) -> Result<crate::Response, failure::Error>
    where
        T: serde::Serialize,
    {
        Ok(Response::Http(in_.ctx.response(
            serde_json::to_vec_pretty(&json!({
                "success": true,
                "result": data,
            }))?,
        )?))
    }

    pub fn redirect<T>(in_: &crate::base::In, next: T) -> Result<crate::Response, failure::Error>
    where
        T: Into<String>,
    {
        use http::header;
        match in_.get_mode() {
            Mode::Layout => Ok(Response::Page(PageSpec {
                id: "".to_owned(),
                config: json!({}),
                title: "".to_owned(),
                url: None,
                replace: None,
                redirect: Some(next.into()),
                rendered: "".to_string(),
            })),
            _ => {
                in_.ctx.header(header::LOCATION, next.into());
                in_.ctx.status(StatusCode::TEMPORARY_REDIRECT);
                Ok(Response::Http(in_.ctx.response("".into())?))
            }
        }
    }

    pub fn redirect_with<T>(
        in_: &crate::base::In,
        next: T,
        status: StatusCode,
    ) -> Result<crate::Response, failure::Error>
    where
        T: Into<String>,
    {
        use http::header;
        match in_.get_mode() {
            Mode::Layout => Ok(Response::Page(PageSpec {
                id: "".to_owned(),
                config: json!({}),
                title: "".to_owned(),
                url: None,
                replace: None,
                redirect: Some(next.into()),
                rendered: "".to_string(),
            })),
            _ => {
                in_.ctx.header(header::LOCATION, next.into());
                in_.ctx.status(status);
                Ok(Response::Http(in_.ctx.response("".into())?))
            }
        }
    }
}

impl Serialize for Response {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match *self {
            Response::Http(ref s) => {
                let mut resp = serializer.serialize_struct_variant("Response", 0, "Http", 0)?;
                resp.serialize_field("status", &s.status().as_u16())?;
                // TODO: headers
                let body = std::str::from_utf8(s.body())
                    .map(|v| v.to_string())
                    .unwrap_or_else(|_| format!("{:?}", s.body()));
                resp.serialize_field("body", &body)?;
                resp.end()
            }
            Response::Page(ref p) => {
                serializer.serialize_newtype_variant("Response", 1, "PageSpec", p)
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
            rendered: "empty.html".to_string()
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
