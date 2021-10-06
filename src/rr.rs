use crate::base::*;

pub const COOKIE_NAME: &str = "recording";
pub const RECORD_URL: &str = "/test/";
pub const REPLAY_URL: &str = "/test/replay/";

#[derive(Debug)]
pub struct ReplayResult {
    // for now the output be on stdout
    pub final_url: String,
    pub cookies: std::collections::HashMap<String, String>,
}

impl Default for ReplayResult {
    fn default() -> Self {
        let mut cookies = std::collections::HashMap::new();
        cookies.insert("ud".to_string(), "".to_string());
        cookies.insert("vid".to_string(), "".to_string());
        cookies.insert("tid".to_string(), "".to_string());

        Self {
            final_url: "/".to_string(),
            cookies,
        }
    }
}

#[derive(serde::Serialize, Default)]
pub struct Recording {
    pub id: String,
    pub title: String,
    pub description: String,
    pub base: Option<String>,
    pub steps: Vec<Step>,
}

const P1_NAME: &str = "realm.rr.recording";
const P1_STEP_NAME: &str = "realm.rr.step";

impl Recording {
    pub fn from_p1(p1: Vec<ftd::p1::Section>) -> Result<Recording> {
        let mut iter = p1.into_iter();
        let top = match iter.next() {
            Some(t) => t,
            None => return Err(format_err!("file is empty")),
        };

        let mut r = Recording::default();
        // name must always be realm.rr
        if top.name != P1_NAME {
            return Err(format_err!(
                "name must be '{}' found '{}'",
                P1_NAME,
                top.name.as_str()
            ));
        }
        r.id = top.header.string("id")?;
        r.description = top.body.clone().unwrap_or_else(|| "".to_string());
        r.title = match top.caption {
            Some(ref t) => t.clone(),
            None => return Err(format_err!("caption is missing")),
        };
        r.base = top.header.str_optional("base")?.map(ToString::to_string);

        for sub in iter {
            r.steps.push(Step::from_p1(sub)?)
        }
        Ok(r)
    }

    pub fn to_p1(&self) -> Result<Vec<ftd::p1::Section>> {
        let mut p1 = vec![];
        let mut first = ftd::p1::Section {
            name: P1_NAME.to_string(),
            body: Some(self.description.clone()),
            caption: Some(self.title.clone()),
            ..Default::default()
        };
        first.header.add("id", self.id.as_str());
        if let Some(ref b) = self.base {
            first.header.add("base", b);
        }
        p1.push(first);

        for step in self.steps.iter() {
            p1.push(step.to_p1()?)
        }

        Ok(p1)
    }

    pub fn read(tid: &str) -> Result<Recording> {
        Self::from_p1(ftd::p1::parse(
            std::fs::read_to_string(&tid_to_path(tid))?.as_str(),
        )?)
    }

    fn save(&self) -> Result<()> {
        std::fs::write(
            &tid_to_path(self.id.as_str()),
            ftd::p1::to_string(&self.to_p1()?),
        )
        .map_err(Into::into)
    }

    fn add_step(tid: &str, step: Step) -> Result<()> {
        let mut current = Recording::read(tid)?;
        current.steps.push(step);
        current.save()
    }
}

#[derive(serde::Serialize, Default)]
pub struct Step {
    pub method: String,
    pub path: String,
    pub body: serde_json::Value,

    pub test_trace: String,
    pub final_url: String,
    // output: serde_json::Value,
    // ftd: String,
    pub activity: Activity,
}

const TRACE_NAME: &str = "realm.rr.step.trace";
const STEP_BODY: &str = "realm.rr.step.body";

impl Step {
    pub fn from_p1(p1: ftd::p1::Section) -> Result<Self> {
        let mut s = Step::default();
        if p1.name != P1_STEP_NAME {
            return Err(format_err!(
                "name must be '{}' found '{}'",
                P1_STEP_NAME,
                p1.name.as_str()
            ));
        }
        s.method = p1.header.string("method")?;
        s.path = p1.header.string("path")?;
        s.final_url = p1.header.string("final_url")?;

        s.body = serde_json::from_str(&p1.sub_sections.body_for(STEP_BODY)?)?;
        s.test_trace = p1.sub_sections.body_for(TRACE_NAME)?;
        s.activity = Activity::from_p1(p1.sub_sections.by_name(ACTIVITY_NAME)?)?;

        Ok(s)
    }

    pub fn to_p1(&self) -> Result<ftd::p1::Section> {
        let mut p1 = ftd::p1::Section {
            name: P1_STEP_NAME.to_string(),
            ..Default::default()
        };

        p1.header.add("method", self.method.as_str());
        p1.header.add("path", self.path.as_str());
        p1.header.add("final_url", self.final_url.as_str());

        p1.sub_sections.add_body(
            STEP_BODY,
            serde_json::to_string_pretty(&self.body)?.as_str(),
        );
        p1.sub_sections.add(self.activity.to_p1()?);
        p1.sub_sections
            .add_body(TRACE_NAME, self.test_trace.as_str());
        Ok(p1)
    }

    pub fn ctx(
        &self,
        cookies: std::collections::HashMap<String, String>,
        context: std::collections::HashMap<String, String>,
    ) -> crate::Context {
        let body = self.body.clone();
        let body = if let serde_json::Value::Object(mut o) = body {
            for (k, v) in context.into_iter() {
                o.insert(k, serde_json::Value::String(v));
            }
            serde_json::Value::Object(o)
        } else {
            body
        };

        crate::Context::from(self.method(), self.path.as_str(), body, cookies)
    }

    fn method(&self) -> http::Method {
        if self.method == "GET" {
            http::Method::GET
        } else {
            http::Method::POST
        }
    }
}

const ACTIVITY_NAME: &str = "realm.rr.step.activity";

#[derive(serde::Serialize, Default)]
pub struct Activity {
    pub okind: String,
    pub oid: String,
    pub ekind: String,
    pub data: serde_json::Value,
}

impl Activity {
    pub fn to_p1(&self) -> Result<ftd::p1::SubSection> {
        let mut p1 = ftd::p1::SubSection {
            name: ACTIVITY_NAME.to_string(),
            body: Some(serde_json::to_string_pretty(&self.data)?),
            ..Default::default()
        };
        p1.header.add("okind", self.okind.as_str());
        p1.header.add("oid", self.oid.as_str());
        p1.header.add("ekind", self.ekind.as_str());

        Ok(p1)
    }

    pub fn from_p1(p1: &ftd::p1::SubSection) -> Result<Self> {
        Ok(Activity {
            okind: p1.header.string_with_default("okind", "")?,
            oid: p1.header.string_with_default("oid", "")?,
            ekind: p1.header.string_with_default("ekind", "")?,
            data: serde_json::from_str(p1.body()?.as_str())?,
        })
    }
}

pub fn tid_to_path(tid: &str) -> std::path::PathBuf {
    std::path::PathBuf::from(format!("tests/{}.p1", tid))
}

pub(crate) fn record<UD>(in_: &crate::base::In<UD>, _res: &crate::Result)
where
    UD: crate::UserData,
{
    let tid: &str = match in_.ctx.record {
        Some(ref t) => t,
        None => {
            return;
        }
    };

    let step = match in_.ctx.get_step() {
        Some(step) => step,
        None => {
            eprint!("step not found");
            return;
        }
    };

    if let Err(e) = Recording::add_step(tid, step) {
        eprintln!("{:?}", e);
    }
}

#[derive(serde::Serialize, Template)]
#[template(path = "page.html")]
struct Page {
    recording: Option<Recording>,
    deleted: Option<String>,
    existing: Vec<Recording>,
}

fn scan(dir: &std::path::Path) -> Result<Vec<Recording>> {
    let mut recordings = vec![];
    for entry in std::fs::read_dir(dir)? {
        let path = entry?.path();
        if path.is_dir() {
            recordings.append(&mut scan(&path)?)
        } else {
            recordings.push(Recording::from_p1(ftd::p1::parse(
                std::fs::read_to_string(path)?.as_str(),
            )?)?)
        }
    }
    Ok(recordings)
}

impl Page {
    fn from(recording: Option<Recording>, deleted: Option<String>) -> Result<Page> {
        Ok(Page {
            recording,
            deleted,
            existing: scan(std::path::PathBuf::from("tests/").as_path())?,
        })
    }
}

impl crate::Page for Page {
    const ID: &'static str = "Pages.Realm.Record";
}

pub fn get<UD>(in_: &crate::base::In<UD>) -> crate::Result
where
    UD: crate::UserData,
{
    use crate::Page as _Page;

    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        }
        .into());
    }

    let (recording, deleted) = match in_.ctx.get_cookie(COOKIE_NAME) {
        Some(tid) => match Recording::read(tid) {
            Ok(r) => (Some(r), None),
            Err(e) => match e.downcast_ref::<std::io::Error>() {
                Some(e1) => match e1.kind() {
                    std::io::ErrorKind::NotFound => {
                        in_.ctx.delete_cookie(COOKIE_NAME);
                        (None, Some(tid.to_string()))
                    }
                    _ => return Err(e),
                },
                _ => return Err(e),
            },
        },
        None => (None, None),
    };

    Page::from(recording, deleted)?.with_title("record")
}

pub fn stop<UD>(in_: &crate::base::In<UD>) -> crate::Result
where
    UD: crate::UserData,
{
    in_.ctx.delete_cookie(COOKIE_NAME);
    crate::response::Response::redirect(in_, RECORD_URL)
}

pub fn post<UD>(
    in_: &crate::base::In<UD>,
    id: String,
    title: String,
    description: String,
    base: Option<String>,
) -> crate::Result
where
    UD: crate::UserData,
{
    use std::io::Write;

    if !crate::base::is_test() {
        observer::log("not in test mode, ignoring");
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        }
        .into());
    }

    let url = match base {
        Some(ref b) => {
            // if base is passed it must exist
            if !tid_to_path(b).exists() {
                return crate::error("base", "Not found", "user_error", "base_not_found");
            }
            REPLAY_URL.to_owned() + "?tid=" + b
        }
        None => "/".to_string(),
    };

    let recording = Recording {
        id: id.clone(),
        title,
        description,
        base,
        steps: vec![],
    };

    let path = tid_to_path(id.as_str());
    std::fs::DirBuilder::new()
        .recursive(true)
        .create(path.parent().unwrap())?;

    if let Err(e) = std::fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(path)?
        .write(ftd::p1::to_string(&recording.to_p1()?).as_bytes())
    {
        observer::observe_string("failed to create recording file", e.to_string().as_str());
        return match e.kind() {
            std::io::ErrorKind::AlreadyExists => crate::error(
                "id",
                "ID already exists.",
                "user_error",
                "id_already_exists",
            ),
            _ => crate::error(
                "id",
                e.to_string().as_str(),
                "server_error",
                "failed_to_write_record_file",
            ),
        };
    }

    in_.ctx.cookie(COOKIE_NAME, id.as_str(), 365 * 86400);
    crate::test::reset_schema(in_.conn)?;
    in_.reset_for_test();
    observer::observe_string("url", url.as_str());
    crate::response::Response::redirect(in_, url.as_str())
}
