use basic::widgets::{footer::*, header::*, index, two_column::*};

pub fn layout(req: realm::Request, user_id: i32) -> realm::Result {
    Ok(TwoColumn(in_, Header(in_), Index(in_), Footer(in_)).page())
}
