use std::collections::HashMap;

#[derive(Serialize, Debug)]
pub struct FormErrors(HashMap<String, (String, Option<String>)>);

impl FormErrors {
    #[deprecated(since = "0.1.15", note = "Please use FormErrors::default() instead")]
    pub fn new() -> FormErrors {
        FormErrors::default()
    }

    #[deprecated(since = "0.1.18", note = "Please use FormErrors::default() instead")]
    pub fn empty() -> FormErrors {
        FormErrors::default()
    }

    pub fn single(key: &str, value: &str, msg: &str) -> FormErrors {
        let mut h = HashMap::new();
        h.insert(key.to_string(), (value.to_string(), Some(msg.to_string())));
        FormErrors(h)
    }

    pub fn single_value(key: &str, value: &str) -> FormErrors {
        let mut f = FormErrors::default();
        f.0.insert(key.to_string(), (value.to_string(), None));
        f
    }

    pub fn and_error(mut self, key: &str, value: &str, msg: &str) -> FormErrors {
        self.0
            .insert(key.to_string(), (value.to_string(), Some(msg.to_string())));
        self
    }

    pub fn get_errors(self) -> HashMap<String, (String, Option<String>)> {
        self.0
    }
}

impl From<FormErrors> for failure::Error {
    fn from(e: FormErrors) -> failure::Error {
        crate::Error::FormError {
            errors: e
                .0
                .into_iter()
                .filter(|(_, (_, e))| e.is_some())
                .map(|(k, (_, e))| (k, e.unwrap()))
                .collect(),
        }
        .into()
    }
}

impl Default for FormErrors {
    fn default() -> FormErrors {
        FormErrors(HashMap::new())
    }
}

pub struct Form<'a, UD>
where
    UD: crate::UserData,
{
    in_: &'a crate::base::In<'a, UD>,
    pub errors: FormErrors,
}

impl<'a, UD> Form<'a, UD>
where
    UD: crate::UserData,
{
    pub fn new(in_: &'a crate::base::In<'a, UD>) -> Self {
        Form {
            in_,
            errors: FormErrors(HashMap::new()),
        }
    }
    // f.add_error("field", field, error_message) // overwrites existing error if there
    pub fn add_error<T>(&mut self, name: &str, value: T, message: &str)
    where
        T: Into<String>,
    {
        self.errors
            .0
            .insert(name.to_string(), (value.into(), Some(message.to_string())));
    }

    pub fn c1<T, V>(&mut self, name: &str, value: T, validator: V) -> Result<(), failure::Error>
    where
        T: Into<String>,
        V: FnOnce(&crate::base::In<UD>, &str) -> Result<Option<String>, failure::Error>,
    {
        if self
            .errors
            .0
            .get(name)
            .and_then(|(_, e)| e.as_ref())
            .is_some()
        {
            return Ok(());
        };

        let value = value.into();
        let res = validator(self.in_, value.as_str())?;

        self.errors.0.insert(name.to_string(), (value, res));

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
        V1: FnOnce(&crate::base::In<UD>, &str) -> Result<Option<String>, failure::Error>,
        V2: FnOnce(&crate::base::In<UD>, &str) -> Result<Option<String>, failure::Error>,
    {
        self.c1(name, value.clone(), val1)?;
        self.c1(name, value, val2)
    }

    pub fn invalid(&self) -> bool {
        self.errors.0.values().any(|(_, e)| e.is_some())
    }

    pub fn errors<T>(self) -> Result<T, FormErrors> {
        Err(self.errors)
    }

    pub fn errors2<T>(self) -> Result<T, failure::Error> {
        Err(crate::Error::FormError {
            errors: self
                .errors
                .0
                .into_iter()
                .filter(|(_, (_, e))| e.is_some())
                .map(|(k, (_, e))| (k, e.unwrap()))
                .collect(),
        }
        .into())
    }
}
