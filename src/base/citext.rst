use diesel::deserialize::{self, FromSql};
use diesel::pg::Pg;
use diesel::serialize::{self, Output, ToSql};
use diesel::sql_types::Text;
use std::io::Write;

#[derive(Debug, Clone, Copy, SqlType, QueryId)]
#[postgres(type_name = "citext")]
pub struct Citext;

#[cfg(feature = "postgres")]
#[derive(Clone, Debug, FromSqlRow, AsExpression, PartialOrd, PartialEq)]
#[sql_type = "Citext"]
pub struct CiString(pub String);

#[cfg(feature = "postgres")]
impl From<CiString> for String {
    fn from(s: CiString) -> String {
        s.0
    }
}

#[cfg(feature = "postgres")]
pub fn cistring_to_string(s: CiString) -> String {
    s.0
}

#[cfg(feature = "postgres")]
pub fn citext(s: &str) -> CiString {
    CiString(s.into())
}

#[cfg(not(feature = "postgres"))]
pub fn citext(s: &str) -> &str {
    s
}

#[cfg(not(feature = "postgres"))]
pub type CiString = String;

#[cfg(not(feature = "postgres"))]
pub fn cistring_to_string(s: CiString) -> String {
    s
}

impl ToSql<Citext, Pg> for Text {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        Text::to_sql(&self, out)
    }
}

impl FromSql<Citext, Pg> for Text {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
        Text::from_sql(bytes)
    }
}

#[cfg(feature = "postgres")]
impl diesel::serialize::ToSql<Citext, diesel::pg::Pg> for CiString {
    fn to_sql<W: std::io::Write>(
        &self,
        out: &mut diesel::serialize::Output<W, diesel::pg::Pg>,
    ) -> diesel::serialize::Result {
        diesel::serialize::ToSql::<diesel::sql_types::Text, diesel::pg::Pg>::to_sql(&self.0, out)
    }
}

#[cfg(feature = "postgres")]
impl diesel::deserialize::FromSql<Citext, diesel::pg::Pg> for CiString {
    fn from_sql(bytes: Option<&[u8]>) -> diesel::deserialize::Result<Self> {
        Ok(CiString(diesel::deserialize::FromSql::<
            diesel::sql_types::Text,
            diesel::pg::Pg,
        >::from_sql(bytes)?))
    }
}
