use serde::de::DeserializeOwned;
use std::{collections::HashMap, fmt::Debug, str::FromStr};

#[derive(Debug)]
pub struct RequestConfig {
    pub query: std::collections::HashMap<String, String>,
    pub data: serde_json::Value,
    pub rest: String,
    pub path: String,
}

#[derive(Fail, Debug, Serialize)]
pub enum Error {
    #[fail(display = "Expected input parameter not found: {}", key)]
    NotFound { key: String },
    #[fail(display = "Can't parse {}={}, error: {}", key, value, message)]
    InvalidValue {
        key: String,
        value: String,
        message: String,
    },
    #[fail(display = "Errors: {:?}", _0)]
    Multi(Vec<Error>),
}

impl RequestConfig {
    pub fn new(
        query: &std::collections::HashMap<String, String>,
        path: &str,
        data: serde_json::Value,
    ) -> std::result::Result<RequestConfig, failure::Error> {
        Ok(RequestConfig {
            rest: crate::utils::sub_string(path, path.len(), None),
            query: query.to_owned(),
            data,
            path: path.to_string(),
        })
    }

    pub fn optional<T>(&mut self, name: &str) -> Result<Option<T>, crate::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        match self.required_(name) {
            Ok(t) => Ok(Some(t)),
            Err(Error::NotFound { .. }) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn either_optional<T>(&mut self, n1: &str, n2: &str) -> Result<Option<T>, crate::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2)) {
            (Ok(t), _) => Ok(Some(t)),
            (_, Ok(t)) => Ok(Some(t)),
            (Err(Error::NotFound { .. }), Err(Error::NotFound { .. })) => Ok(None),
            (r1, _) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn optional2<T1, T2>(
        &mut self,
        n1: &str,
        n2: &str,
    ) -> Result<(Option<T1>, Option<T2>), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2)) {
            // All or nothing
            (Ok(t1), Ok(t2)) => Ok((Some(t1), Some(t2))),
            (Err(Error::NotFound { .. }), Err(Error::NotFound { .. })) => Ok((None, None)),

            // One absent
            (Ok(t1), Err(Error::NotFound { .. })) => Ok((Some(t1), None)),
            (Err(Error::NotFound { .. }), Ok(t2)) => Ok((None, Some(t2))),

            // Other errors
            (Err(e), _) => Err(e.into()),
            (_, Err(e)) => Err(e.into()),
        }
    }

    #[allow(clippy::type_complexity)]
    pub fn optional3<T1, T2, T3>(
        &mut self,
        n1: &str,
        n2: &str,
        n3: &str,
    ) -> Result<(Option<T1>, Option<T2>, Option<T3>), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
        T3: FromStr + DeserializeOwned,
        <T3 as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2), self.required_(n3)) {
            // All or nothing
            (Ok(t1), Ok(t2), Ok(t3)) => Ok((Some(t1), Some(t2), Some(t3))),
            (
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
            ) => Ok((None, None, None)),

            // One absent
            (Err(Error::NotFound { .. }), Ok(t2), Ok(t3)) => Ok((None, Some(t2), Some(t3))),
            (Ok(t1), Err(Error::NotFound { .. }), Ok(t3)) => Ok((Some(t1), None, Some(t3))),
            (Ok(t1), Ok(t2), Err(Error::NotFound { .. })) => Ok((Some(t1), Some(t2), None)),

            // Two absent
            (Err(Error::NotFound { .. }), Err(Error::NotFound { .. }), Ok(t3)) => {
                Ok((None, None, Some(t3)))
            }
            (Err(Error::NotFound { .. }), Ok(t2), Err(Error::NotFound { .. })) => {
                Ok((None, Some(t2), None))
            }
            (Ok(t1), Err(Error::NotFound { .. }), Err(Error::NotFound { .. })) => {
                Ok((Some(t1), None, None))
            }

            // Other errors
            (Err(e), _, _) => Err(e.into()),
            (_, Err(e), _) => Err(e.into()),
            (_, _, Err(e)) => Err(e.into()),
        }
    }

    #[allow(clippy::type_complexity)]
    pub fn optional4<T1, T2, T3, T4>(
        &mut self,
        n1: &str,
        n2: &str,
        n3: &str,
        n4: &str,
    ) -> Result<(Option<T1>, Option<T2>, Option<T3>, Option<T4>), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
        T3: FromStr + DeserializeOwned,
        <T3 as FromStr>::Err: Debug,
        T4: FromStr + DeserializeOwned,
        <T4 as FromStr>::Err: Debug,
    {
        match (
            self.required_(n1),
            self.required_(n2),
            self.required_(n3),
            self.required_(n4),
        ) {
            // All or nothing
            (Ok(t1), Ok(t2), Ok(t3), Ok(t4)) => Ok((Some(t1), Some(t2), Some(t3), Some(t4))),
            (
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
            ) => Ok((None, None, None, None)),

            // One absent
            (Err(Error::NotFound { .. }), Ok(t2), Ok(t3), Ok(t4)) => {
                Ok((None, Some(t2), Some(t3), Some(t4)))
            }
            (Ok(t1), Err(Error::NotFound { .. }), Ok(t3), Ok(t4)) => {
                Ok((Some(t1), None, Some(t3), Some(t4)))
            }
            (Ok(t1), Ok(t2), Err(Error::NotFound { .. }), Ok(t4)) => {
                Ok((Some(t1), Some(t2), None, Some(t4)))
            }
            (Ok(t1), Ok(t2), Ok(t3), Err(Error::NotFound { .. })) => {
                Ok((Some(t1), Some(t2), Some(t3), None))
            }

            // Two absent
            (Err(Error::NotFound { .. }), Err(Error::NotFound { .. }), Ok(t3), Ok(t4)) => {
                Ok((None, None, Some(t3), Some(t4)))
            }
            (Err(Error::NotFound { .. }), Ok(t2), Err(Error::NotFound { .. }), Ok(t4)) => {
                Ok((None, Some(t2), None, Some(t4)))
            }
            (Err(Error::NotFound { .. }), Ok(t2), Ok(t3), Err(Error::NotFound { .. })) => {
                Ok((None, Some(t2), Some(t3), None))
            }
            (Ok(t1), Err(Error::NotFound { .. }), Err(Error::NotFound { .. }), Ok(t4)) => {
                Ok((Some(t1), None, None, Some(t4)))
            }
            (Ok(t1), Err(Error::NotFound { .. }), Ok(t3), Err(Error::NotFound { .. })) => {
                Ok((Some(t1), None, Some(t3), None))
            }
            (Ok(t1), Ok(t2), Err(Error::NotFound { .. }), Err(Error::NotFound { .. })) => {
                Ok((Some(t1), Some(t2), None, None))
            }

            // Three absent
            (
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Ok(t4),
            ) => Ok((None, None, None, Some(t4))),
            (
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Ok(t3),
                Err(Error::NotFound { .. }),
            ) => Ok((None, None, Some(t3), None)),
            (
                Err(Error::NotFound { .. }),
                Ok(t2),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
            ) => Ok((None, Some(t2), None, None)),
            (
                Ok(t1),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
                Err(Error::NotFound { .. }),
            ) => Ok((Some(t1), None, None, None)),

            // Other errors
            (Err(e), _, _, _) => Err(e.into()),
            (_, Err(e), _, _) => Err(e.into()),
            (_, _, Err(e), _) => Err(e.into()),
            (_, _, _, Err(e)) => Err(e.into()),
        }
    }

    #[deprecated(since = "0.1.16", note = "Please use .required() instead")]
    pub fn param<T>(&mut self, name: &str) -> Result<T, crate::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        self.required(name)
    }

    pub fn required2<T1, T2>(&mut self, n1: &str, n2: &str) -> Result<(T1, T2), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2)) {
            (Ok(t1), Ok(t2)) => Ok((t1, t2)),
            (r1, r2) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                if let Err(e) = r2 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn either<T>(&mut self, n1: &str, n2: &str) -> Result<T, crate::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2)) {
            (Ok(t1), _) => Ok(t1),
            (_, Ok(t2)) => Ok(t2),
            (r1, _) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn required3<T1, T2, T3>(
        &mut self,
        n1: &str,
        n2: &str,
        n3: &str,
    ) -> Result<(T1, T2, T3), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
        T3: FromStr + DeserializeOwned,
        <T3 as FromStr>::Err: Debug,
    {
        match (self.required_(n1), self.required_(n2), self.required_(n3)) {
            (Ok(t1), Ok(t2), Ok(t3)) => Ok((t1, t2, t3)),
            (r1, r2, r3) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                if let Err(e) = r2 {
                    errors.push(e)
                };
                if let Err(e) = r3 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn required4<T1, T2, T3, T4>(
        &mut self,
        n1: &str,
        n2: &str,
        n3: &str,
        n4: &str,
    ) -> Result<(T1, T2, T3, T4), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
        T3: FromStr + DeserializeOwned,
        <T3 as FromStr>::Err: Debug,
        T4: FromStr + DeserializeOwned,
        <T4 as FromStr>::Err: Debug,
    {
        match (
            self.required_(n1),
            self.required_(n2),
            self.required_(n3),
            self.required_(n4),
        ) {
            (Ok(t1), Ok(t2), Ok(t3), Ok(t4)) => Ok((t1, t2, t3, t4)),
            (r1, r2, r3, r4) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                if let Err(e) = r2 {
                    errors.push(e)
                };
                if let Err(e) = r3 {
                    errors.push(e)
                };
                if let Err(e) = r4 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn required5<T1, T2, T3, T4, T5>(
        &mut self,
        n1: &str,
        n2: &str,
        n3: &str,
        n4: &str,
        n5: &str,
    ) -> Result<(T1, T2, T3, T4, T5), crate::Error>
    where
        T1: FromStr + DeserializeOwned,
        <T1 as FromStr>::Err: Debug,
        T2: FromStr + DeserializeOwned,
        <T2 as FromStr>::Err: Debug,
        T3: FromStr + DeserializeOwned,
        <T3 as FromStr>::Err: Debug,
        T4: FromStr + DeserializeOwned,
        <T4 as FromStr>::Err: Debug,
        T5: FromStr + DeserializeOwned,
        <T5 as FromStr>::Err: Debug,
    {
        match (
            self.required_(n1),
            self.required_(n2),
            self.required_(n3),
            self.required_(n4),
            self.required_(n5),
        ) {
            (Ok(t1), Ok(t2), Ok(t3), Ok(t4), Ok(t5)) => Ok((t1, t2, t3, t4, t5)),
            (r1, r2, r3, r4, r5) => {
                let mut errors = vec![];
                if let Err(e) = r1 {
                    errors.push(e)
                };
                if let Err(e) = r2 {
                    errors.push(e)
                };
                if let Err(e) = r3 {
                    errors.push(e)
                };
                if let Err(e) = r4 {
                    errors.push(e)
                };
                if let Err(e) = r5 {
                    errors.push(e)
                };
                Err(Error::Multi(errors).into())
            }
        }
    }

    pub fn required<T>(&mut self, name: &str) -> Result<T, crate::Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        self.required_(name).map_err(Into::into)
    }

    fn required_<T>(&mut self, name: &str) -> Result<T, Error>
    where
        T: FromStr + DeserializeOwned,
        <T as FromStr>::Err: Debug,
    {
        let query: &HashMap<String, String> = &self.query;
        let data: &serde_json::Value = &self.data;
        let rest: &mut String = &mut self.rest;

        if !rest.is_empty() {
            let (first, last) = crate::utils::first_rest(&rest);
            rest.truncate(0);
            rest.push_str(&last);
            if let Some(v) = first {
                return match v.parse() {
                    Ok(v) => Ok(v),
                    Err(e) => {
                        // we have to do this because FromStr::Err is not Send/Sync
                        return Err(Error::InvalidValue {
                            key: name.to_string(),
                            value: v.clone(),
                            message: format!("{:?}", e),
                        });
                    }
                };
            }
        }

        if let Some(v) = query.get(name) {
            if v.is_empty() {
                return Err(Error::NotFound {
                    key: name.to_string(),
                });
            }
            return match v.parse() {
                Ok(v) => Ok(v),
                Err(e) => {
                    return Err(Error::InvalidValue {
                        key: name.to_string(),
                        value: v.clone(),
                        message: format!("{:?}", e),
                    })
                }
            };
        }

        if let Some(v) = data.get(name) {
            if v.is_null() {
                return Err(Error::NotFound {
                    key: name.to_string(),
                });
            };
            return serde_json::from_value(v.to_owned()).map_err(|e| Error::InvalidValue {
                key: name.to_string(),
                value: v.to_string(),
                message: e.to_string(),
            });
        }

        Err(Error::NotFound {
            key: name.to_string(),
        })
    }

    pub fn json<T>(&mut self, name: &str) -> Result<T, Error>
    where
        T: DeserializeOwned,
    {
        let data: &serde_json::Value = &self.data;

        if let Some(v) = data.get(name) {
            if v.is_null() {
                return Err(Error::NotFound {
                    key: name.to_string(),
                });
            };
            return serde_json::from_value(v.to_owned()).map_err(|e| Error::InvalidValue {
                key: name.to_string(),
                value: v.to_string(),
                message: e.to_string(),
            });
        }

        Err(Error::NotFound {
            key: name.to_string(),
        })
    }

    #[deprecated(since = "0.1.15", note = "Please use .required() instead")]
    pub fn get<T>(&mut self, name: &str, _is_optional: bool) -> Result<T, crate::Error>
    where
        T: FromStr + DeserializeOwned + Default,
        <T as FromStr>::Err: Debug,
    {
        self.required(name)
    }
}
