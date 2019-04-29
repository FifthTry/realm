pub fn handler(_req: realm::Request) -> realm::Result {
    let db = DB_POOL.get();
    let in_ = In.from_conn(db);
    // start timer
    let resp = basic::reverse::magic(in_);
    // send statsd

    resp
}
