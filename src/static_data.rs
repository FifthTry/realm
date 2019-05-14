pub(crate) trait StaticData {
    fn content(&self, path: &str) -> Result<String, failure::Error>;
}

pub(crate) struct TestStatic(std::collections::HashMap<String, String>);

impl TestStatic {
    pub(crate) fn new() -> Self {
        TestStatic(std::collections::HashMap::new())
    }

    pub(crate) fn with(mut self, key: &str, value: &str) -> Self {
        self.0.insert(format!("deps/{}", key), value.into());
        self
    }
}

impl StaticData for &TestStatic {
    fn content(&self, path: &str) -> Result<String, failure::Error> {
        match self.0.get(path) {
            Some(c) => Ok(c.to_string()),
            None => Err(failure::err_msg(format!("file not found: {}", path))),
        }
    }
}
