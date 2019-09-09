use std::collections::HashMap;

pub type FormErrors = HashMap<String, (String, Option<String>)>;

pub struct Form<'a> {
    in_: &'a crate::base::In<'a>,
    errors: FormErrors,
}

impl<'a> Form<'a> {
    pub fn new(in_: &'a crate::base::In<'a>) -> Self {
        Form {
            in_,
            errors: HashMap::new(),
        }
    }
    // f.add_error("field", field, error_message) // overwrites existing error if there
    pub fn add_error<T>(&mut self, name: &str, value: T, message: &str)
    where
        T: Into<String>,
    {
        self.errors
            .insert(name.to_string(), (value.into(), Some(message.to_string())));
    }

    pub fn c1<T, V>(&mut self, name: &str, value: T, validator: V) -> Result<(), failure::Error>
    where
        T: Into<String>,
        V: FnOnce(&crate::base::In, &str) -> Result<Option<String>, failure::Error>,
    {
        if self
            .errors
            .get(name)
            .and_then(|(_, e)| e.as_ref())
            .is_some()
        {
            return Ok(());
        };

        let value = value.into();
        let res = validator(self.in_, value.as_str())?;

        self.errors.insert(name.to_string(), (value, res));

        Ok(())
    }

    pub fn c2<T, V1, V2>(
        &mut self,
        name: &str,
        value: T,
        val1: V1,
        val2: V2,
    ) -> Result<(), failure::Error>
    where
        T: Into<String> + Clone,
        V1: FnOnce(&crate::base::In, &str) -> Result<Option<String>, failure::Error>,
        V2: FnOnce(&crate::base::In, &str) -> Result<Option<String>, failure::Error>,
    {
        self.c1(name, value.clone(), val1)?;
        self.c1(name, value, val2)
    }

    pub fn invalid(&self) -> bool {
        self.errors.values().any(|(_, e)| e.is_some())
    }

    pub fn errors<T>(self) -> Result<T, FormErrors> {
        Err(self.errors)
    }
}
