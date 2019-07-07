
use failure;
use graft::{self, Context, DirContext};
use serde_json;
use std::collections::HashMap;



pub struct IDedContext<'a> {
    in_: &'a In<'a>,
    root: DirContext,
}

impl<'a> Context for IDedContext<'a> {
    fn lookup(&self, key: &str) -> Result<String, failure::Error> {
        match key {
            "rust:customer_header.json" => {
                return Ok(serde_json::to_string(&Header::CustomerWhite(
                    self.in_.into(),
                ))?);
            }
            "rust:customer_footer.json" => {
                return Ok(serde_json::to_string(&Footer::Main(self.in_.into()))?);
            }
            _ => {}
        }

        self.root
            .lookup(key)
            .map(|v| {
                if key.ends_with(".json") {
                    match self.root.lookup(&key.replace(".json", ".id_list")) {
                        Ok(s) => {
                            for id in s.split("\n") {
                                self.in_.add_widget_id(id);
                            }
                        }
                        _ => {}
                    }
                };
                v
            })
            .map_err(|e| {
                slog_info!(
                    self.in_.logger, "context_lookup_error";
                    "err" => format!("{:?}", &e),
                    "key" => key
                );
                e
            })
    }
}

#[derive(Debug, Deserialize, Clone)]
struct C {
    pub title: String,
    pub permission: String,
    pub widget: serde_json::Value,
}

pub fn serve(in_: &In, url: &str) -> acko_base::Result<AckoResponse> {
    if !CONFIG.enable_cms {
        slog_info!(
            in_.logger, "cms_disabled";
        );
        return Ok(AckoResponse::Http404(url.to_owned()));
    }
    let content = match acko_base::utils::cms_content(url) {
        Ok(content) => content,
        Err(e) => {
            slog_info!(
                in_.logger, "cms_content_error";
                "err" => format!("{:?}", e)
            );
            return Ok(AckoResponse::Http404(url.to_owned()));
        }
    };

    // TODO: cache directory content
    let context = IDedContext {
        in_,
        root: DirContext::new(acko_base::CONFIG.proj_dir.join("cms/includes")),
    };
    let c: C = serde_json::from_value(graft::convert(&content, &context)?)?;
    println!("c: {:#?}", &c);

    if cfg!(not(debug_assertions)) {
        let mut is_allowed = false;
        for perm in c.permission.split(",") {
            is_allowed |= match perm.trim() {
                "public" => true,
                p if PERMS_MAP.get(&p).is_some() => in_.has_perm(PERMS_MAP.get(&p).unwrap())?,
                _ => false,
            };
        }
        if !is_allowed {
            slog_info!(
                in_.logger, "cms_unauthorised";
            );
            return Ok(AckoResponse::Http404(url.to_owned()));
        }
    }

    Ok(AckoResponse::Widget(c.widget, c.title))
}
