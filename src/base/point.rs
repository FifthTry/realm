// https://github.com/diesel-rs/diesel/pull/1566/files

use byteorder::{ByteOrder, LittleEndian};
use byteorder::{NetworkEndian, WriteBytesExt};
use diesel::{
    deserialize::{self, FromSql},
    pg::Pg,
    serialize::{self, IsNull, Output, ToSql},
};
use std::io::prelude::*;

#[derive(Debug, Clone, Copy, Default, QueryId, SqlType)]
#[postgres(oid = "600", array_oid = "1017")]
pub struct PgPoint;

/// Point is represented in Postgres as a tuple of 64 bit floating point values (x, y).  This
/// struct is a dumb wrapper type, meant only to indicate the tuple's meaning.
#[derive(
    Debug,
    Clone,
    PartialEq,
    Copy,
    FromSqlRow,
    AsExpression,
    SqlType,
    serde::Serialize,
    serde::Deserialize,
)]
#[sql_type = "PgPoint"]
pub struct Point {
    pub lat: f64,
    pub long: f64,
}

impl FromSql<PgPoint, Pg> for Point {
    fn from_sql(bytes: Option<&[u8]>) -> deserialize::Result<Self> {
        let bytes = not_none!(bytes);

        //  First 9 bytes store - Endian Type (1byte), Geometry (4bytes) & SRID (4bytes) followed by coordinates (of 8 bytes each)
        let endian = bytes[0];
        if endian == 1 {
            let _srid = LittleEndian::read_i32(&bytes[5..9]);
            let long = LittleEndian::read_f64(&bytes[9..17]);
            let lat = LittleEndian::read_f64(&bytes[17..25]);
            Ok(Point { lat, long })
        } else if endian == 0 {
            let _srid = NetworkEndian::read_i32(&bytes[5..9]);
            let long = NetworkEndian::read_f64(&bytes[9..17]);
            let lat = NetworkEndian::read_f64(&bytes[17..25]);
            Ok(Point { lat, long })
        } else {
            Err("Invalid Endian Value".into())
        }
    }
}

impl ToSql<PgPoint, Pg> for Point {
    fn to_sql<W: Write>(&self, out: &mut Output<W, Pg>) -> serialize::Result {
        out.write_f64::<NetworkEndian>(self.lat)?;
        out.write_f64::<NetworkEndian>(self.long)?;
        Ok(IsNull::No)
    }
}
