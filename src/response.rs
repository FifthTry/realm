use crate::mode::Mode;
use crate::PageSpec;

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
        if let Response::Http(r) = self {
            return Ok(r);
        };

        let r = self.with_default_url(url);

        match &r {
            Response::Page(spec) => {
                ctx.header(http::header::CONTENT_TYPE, mode.content_type());
                Ok(ctx.response(match mode {
                    Mode::API => serde_json::to_string_pretty(&spec.config)?.into(),
                    Mode::HTML => spec.render()?,
                    Mode::Layout => serde_json::to_string(&spec)?.into(),
                })?)
            }
            Response::Http(_) => unreachable!(),
        }
    }
}
