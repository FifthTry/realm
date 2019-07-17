pub fn middleware(req: realm::Request) -> realm::Result{
    let ireq  = crate::in_::In{
        realm_request: req,
    };
    crate::forward::magic(ireq)
}
