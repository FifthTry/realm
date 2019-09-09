use diesel::{
    deserialize::{self, FromSql},
    pg::Pg,
    serialize::{self, Output, ToSql},
    sql_types::Text,
};
use std::io::Write;

#[derive(Debug, Clone, Copy, SqlType, QueryId)]
#[postgres(type_name = "citext")]
pub struct Citext;

#[derive(Clone, Debug, FromSqlRow, AsExpression, PartialOrd, PartialEq)]
#[sql_type = "Citext"]
pub struct CiString(pub String);

pub fn citext(s: &str) -> CiString {
    CiString(s.into())
}

impl ToSql<Citext, Pg> for CiString {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        ToSql::<Text, Pg>::to_sql(&self.0, out)
    }
}

impl FromSql<Citext, Pg> for CiString {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
        Ok(CiString(FromSql::<Text, Pg>::from_sql(bytes)?))
    }
}
