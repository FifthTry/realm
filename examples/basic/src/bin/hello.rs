extern crate basic;
extern crate realm;

/*
pub fn handler(req: realm::Request) -> realm::Result {
    let conn = DB_POOL.get()?;
    let in_: In::from(req, conn);

    basic::forward::magic(in_, req);
    resp.tweak();
    resp
}
*/

realm::realm!{basic::forward::magic}
