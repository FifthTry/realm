#[derive(PartialEq, Debug, Clone, serde::Serialize, serde::Deserialize, Default)]
pub struct HTMLMeta {
    pub id: Option<String>,

    pub no_index: Option<bool>,

    pub title: Option<String>,
    pub description: Option<String>,
    pub keywords: Option<String>,
    pub author: Option<String>,

    pub og_type: Option<String>,
    pub og_url: Option<String>,
    pub og_title: Option<String>,
    pub og_description: Option<String>,
    pub og_image: Option<String>,

    pub twitter_card: Option<String>,
    pub twitter_url: Option<String>,
    pub twitter_title: Option<String>,
    pub twitter_description: Option<String>,
    pub twitter_image: Option<String>,
}

impl HTMLMeta {
    pub fn merge(&mut self, other: &Self) {
        // we do not copy the id as its not used by html rendering phase
        if other.no_index.unwrap_or_default() {
            self.no_index = Some(true);
        }

        if other.title.is_some() {
            self.title = other.title.clone();
            if self.og_title.is_none() {
                self.og_title = other.title.clone();
            }
            if self.twitter_title.is_none() {
                self.twitter_title = other.title.clone();
            }
        }
        if other.description.is_some() {
            self.description = other.description.clone();
            if self.og_description.is_none() {
                self.og_description = other.description.clone();
            }
            if self.twitter_description.is_none() {
                self.twitter_description = other.description.clone();
            }
        }

        if other.og_type.is_some() {
            self.og_type = other.og_type.clone();
        }
        if other.og_url.is_some() {
            self.og_url = other.og_url.clone();
        }
        if other.og_title.is_some() {
            self.og_title = other.og_title.clone();
            if self.twitter_title.is_none() {
                self.twitter_title = other.og_title.clone();
            }
        }
        if other.og_description.is_some() {
            self.og_description = other.og_description.clone();
            if self.twitter_description.is_none() {
                self.twitter_description = other.og_description.clone();
            }
        }
        if other.og_image.is_some() {
            self.og_image = other.og_image.clone();
            if self.twitter_image.is_none() {
                self.twitter_image = other.og_image.clone();
            }
        }

        if other.twitter_card.is_some() {
            self.twitter_card = other.twitter_card.clone();
        }
        if other.twitter_url.is_some() {
            self.twitter_url = other.twitter_url.clone();
        }
        if other.twitter_title.is_some() {
            self.twitter_title = other.twitter_title.clone();
        }
        if other.twitter_description.is_some() {
            self.twitter_description = other.twitter_description.clone();
        }
        if other.twitter_image.is_some() {
            self.twitter_image = other.twitter_image.clone();
        }
    }

    pub fn merge_tldr(&mut self, tldr: &crate::TLDR) {
        if self.description.is_none() {
            self.description = Some(tldr.body.original.clone())
        }
        if self.og_description.is_none() {
            self.og_description = Some(tldr.body.original.clone())
        }
        if self.twitter_description.is_none() {
            self.twitter_description = Some(tldr.body.original.clone())
        }
        if tldr.image.is_some() {
            if self.og_image.is_none() {
                self.og_image = tldr.image.clone();
            }
            if self.twitter_image.is_none() {
                self.twitter_image = tldr.image.clone();
            }
        }
    }

    pub fn to_p1(&self) -> ftd::p1::Section {
        let mut p1 = ftd::p1::Section::with_name("html-meta")
            .add_optional_header("id", &self.id)
            .add_header_if_not_equal("no-index", "true", "false")
            .add_optional_header("title", &self.title)
            .add_optional_header("description", &self.description)
            .add_optional_header("keywords", &self.keywords)
            .add_optional_header("author", &self.author);

        if self.og_type.is_some()
            || self.og_url.is_some()
            || self.og_title.is_some()
            || self.og_description.is_some()
            || self.og_image.is_some()
        {
            p1 = p1.add_sub_section(
                ftd::p1::SubSection::with_name("open-graph")
                    .add_optional_header("type", &self.og_type)
                    .add_optional_header("url", &self.og_url)
                    .add_optional_header("title", &self.og_title)
                    .add_optional_header("image", &self.og_image)
                    .and_optional_body(&self.og_description),
            );
        }

        if self.twitter_card.is_some()
            || self.twitter_url.is_some()
            || self.twitter_title.is_some()
            || self.twitter_description.is_some()
            || self.twitter_image.is_some()
        {
            p1 = p1.add_sub_section(
                ftd::p1::SubSection::with_name("twitter")
                    .add_optional_header("card", &self.twitter_card)
                    .add_optional_header("url", &self.twitter_url)
                    .add_optional_header("title", &self.twitter_title)
                    .add_optional_header("image", &self.twitter_image)
                    .and_optional_body(&self.twitter_description),
            );
        }

        p1
    }

    // pub fn from_p1(p1: &ftd::p1::Section) -> Result<Self, crate::document::ParseError> {
    //     let mut o = Self {
    //         id: p1.header.string_optional("id")?,
    //         no_index: p1.header.bool_with_default("no-index", false)?,
    //         title: p1.header.string_optional("title")?,
    //         keywords: p1.header.string_optional("keywords")?,
    //         author: p1.header.string_optional("author")?,
    //
    //         description: p1.body.clone(),
    //         ..Default::default()
    //     };
    //
    //     for sub in p1.sub_sections.0.iter() {
    //         match sub.name.as_str() {
    //             "og" | "open-graph" => {
    //                 o.og_type = sub.header.string_optional("type")?;
    //                 o.og_url = sub.header.string_optional("url")?;
    //                 o.og_title = sub.header.string_optional("title")?;
    //                 o.og_image = sub.header.string_optional("image")?;
    //
    //                 o.og_description = sub.body.clone();
    //             }
    //             "twitter" => {
    //                 o.twitter_card = sub.header.string_optional("card")?;
    //                 o.twitter_url = sub.header.string_optional("url")?;
    //                 o.twitter_title = sub.header.string_optional("title")?;
    //                 o.twitter_image = sub.header.string_optional("image")?;
    //
    //                 o.twitter_description = sub.body.clone();
    //             }
    //             t => return crate::document::err(format!("unknown sub-section: {}", t).as_str())?,
    //         }
    //     }
    //
    //     Ok(o)
    // }

    pub fn set_title(&mut self, title: &str) {
        self.title = Some(title.to_string());
        if self.og_title.is_none() {
            self.og_title = Some(title.to_string());
        }
        if self.twitter_title.is_none() {
            self.twitter_title = Some(title.to_string());
        }
    }

    pub fn set_description(&mut self, description: &str) {
        self.description = Some(description.to_string());
        if self.og_description.is_none() {
            self.og_description = Some(description.to_string());
        }
        if self.twitter_description.is_none() {
            self.twitter_description = Some(description.to_string());
        }
    }

    pub fn set_image(&mut self, image: &str) {
        self.og_image = Some(image.to_string());
        self.twitter_image = Some(image.to_string());
    }

    pub fn og_type(&mut self, v: &str) {
        self.og_type = Some(v.to_string());
    }

    pub fn og_url(&mut self, v: &str) {
        self.og_url = Some(v.to_string());
    }

    pub fn og_title(&mut self, v: &str) {
        self.og_title = Some(v.to_string());
    }

    pub fn og_description(&mut self, v: &str) {
        self.og_description = Some(v.to_string());
    }

    pub fn og_image(&mut self, v: &str) {
        self.og_image = Some(v.to_string());
    }

    pub fn twitter_card(&mut self, v: &str) {
        self.twitter_card = Some(v.to_string())
    }

    pub fn twitter_url(&mut self, v: &str) {
        self.twitter_url = Some(v.to_string())
    }

    pub fn twitter_title(&mut self, v: &str) {
        self.twitter_title = Some(v.to_string())
    }

    pub fn twitter_description(&mut self, v: &str) {
        self.twitter_description = Some(v.to_string())
    }

    pub fn twitter_image(&mut self, v: &str) {
        self.twitter_image = Some(v.to_string())
    }

    pub fn to_html(&self, title: &str) -> String {
        fn meta(
            key: &'static str,
            name: &str,
            value: &Option<String>,
            default: Option<&str>,
        ) -> String {
            // TODO: escape value
            match (value, default) {
                (Some(ref v), _) => {
                    format!(
                        "<meta {}=\"{}\" content=\"{}\">",
                        key,
                        escape(name),
                        escape(v.as_str()),
                    )
                }
                (None, Some(v)) => format!(
                    "<meta {}=\"{}\" content=\"{}\">",
                    key,
                    escape(name),
                    escape(v)
                ),
                _ => "".to_string(),
            }
        }

        fn name(name: &str, value: &Option<String>, default: Option<&str>) -> String {
            meta("name", name, value, default)
        }

        fn property(name: &str, value: &Option<String>, default: Option<&str>) -> String {
            meta("property", name, value, default)
        }

        let noindex = Some("noindex".to_string());
        format!(
            r#"

    <!-- Primary Meta Tags -->
    {robots}
    {viewport}
    {title}
    {description}
    {keywords}
    {author}

    <!-- Open Graph / Facebook -->
    {og_type}
    {og_url}
    {og_title}
    {og_description}
    {og_image}

    <!-- Twitter -->
    {twitter_card}
    {twitter_url}
    {twitter_title}
    {twitter_description}
    {twitter_image}
        "#,
            robots = name("robots", if self.no_index.unwrap_or_default() { &noindex} else { &None }, None),
            viewport = name("viewport", &None, Some("width=device-width, height=device-height, initial-scale=1.0, user-scalable=no, user-scalable=0,  viewport-fit=cover")),
            title = name("title", &self.title, Some(title)),
            description = name("description", &self.description, None),
            keywords = name("keywords", &self.title, None),
            author = name("author", &self.description, None),

            og_type = property("og:type", &self.og_type, Some("website")),
            og_url = property("og:url", &self.og_url, None),
            og_title = property("og:title", &self.og_title, Some(title)),
            og_description = property("og:description", &self.description, None),
            og_image = property("og:image", &self.og_image, None),

            twitter_card = property("twitter:card", &self.twitter_card, Some("summary_large_image")),
            twitter_url = property("twitter:url", &self.twitter_url, None),
            twitter_title = property("twitter:title", &self.twitter_title, None),
            twitter_description = property("twitter:description", &self.twitter_description, None),
            twitter_image = property("twitter:image", &self.twitter_image, None),
        )
    }
}

pub fn escape(s: &str) -> String {
    let s = s.replace('>', "\\u003E");
    let s = s.replace('<', "\\u003C");
    let s = s.replace('\n', " ");
    s.replace('&', "\\u0026")
}

#[cfg(test)]
mod tests {

    // #[test]
    // fn test() {
    //     p(
    //         &indoc::indoc!(
    //             "
    //              -- html-meta:
    //              title: hello there

    //              this is the description
    //         "
    //         ),
    //         &vec![crate::Section::HTMLMeta(crate::HTMLMeta {
    //             title: Some("hello there".to_string()),
    //             description: Some("this is the description".to_string()),
    //             ..Default::default()
    //         })],
    //     );

    //     p(
    //         &indoc::indoc!(
    //             "
    //              -- html-meta:
    //              title: hello there

    //              this is the description

    //              --- twitter:
    //              title: twitter title

    //              twitter description

    //              --- open-graph:
    //              title: og title

    //              og description
    //         "
    //         ),
    //         &vec![crate::Section::HTMLMeta(crate::HTMLMeta {
    //             title: Some("hello there".to_string()),
    //             description: Some("this is the description".to_string()),
    //             twitter_title: Some("twitter title".to_string()),
    //             twitter_description: Some("twitter description".to_string()),
    //             og_title: Some("og title".to_string()),
    //             og_description: Some("og description".to_string()),
    //             ..Default::default()
    //         })],
    //     );
    // }
}
