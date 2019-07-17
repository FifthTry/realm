pub struct Context{
    pub realm_request: realm::Request,
}

pub fn middleware(req: realm::Request) -> realm::Result{
    let ireq  = Context{
        realm_request: req,
    };
    crate::forward::magic(ireq)
}
