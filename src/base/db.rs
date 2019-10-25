#[cfg(debug_assertions)]
use colored::Colorize;
#[cfg(debug_assertions)]
use diesel::query_builder::QueryBuilder;
use diesel::{connection::TransactionManager, prelude::*};
use failure::Error;
use std::collections::{hash_map::Entry, HashMap};

#[cfg(debug_assertions)]
lazy_static! {
    pub static ref SS: syntect::parsing::SyntaxSet =
        { syntect::parsing::SyntaxSet::load_defaults_newlines() };
    pub static ref TS: syntect::highlighting::ThemeSet =
        { syntect::highlighting::ThemeSet::load_defaults() };
}

#[cfg(debug_assertions)]
fn colored(sql: &str) -> String {
    let syntax = SS.find_syntax_by_extension("sql").unwrap();
    let mut h = syntect::easy::HighlightLines::new(syntax, &TS.themes["base16-ocean.dark"]);
    let ranges: Vec<(syntect::highlighting::Style, &str)> = h.highlight(sql, &SS);
    syntect::util::as_24_bit_terminal_escaped(&ranges[..], false) + "\x1b[0m"
}

#[cfg(debug_assertions)]
pub struct DebugConnection {
    pub conn: diesel::PgConnection,
}

#[cfg(debug_assertions)]
pub type RealmConnection = DebugConnection;
#[cfg(not(debug_assertions))]
pub type RealmConnection = diesel::PgConnection;

fn _connection_pool(db_url: String) -> r2d2::Pool<r2d2_diesel::ConnectionManager<RealmConnection>> {
    let mut db_url = db_url.clone();
    if crate::base::is_test() {
        // add search_path=test (%3D is = sign)
        if db_url.contains('?') {
            db_url += "&options=-c search_path%3Dtest"
        } else {
            db_url += "?options=-c search_path%3Dtest"
        }
    };

    let manager = r2d2_diesel::ConnectionManager::<RealmConnection>::new(db_url);
    r2d2::Pool::builder()
        .max_size(10)
        .build(manager)
        .expect("Failed to create DIESEL_POOL.")
}

lazy_static! {
    pub static ref DIESEL_POOLS: antidote::RwLock<HashMap<String, r2d2::Pool<r2d2_diesel::ConnectionManager<RealmConnection>>>> =
        antidote::RwLock::new(HashMap::new());
}

pub fn connection() -> r2d2::PooledConnection<r2d2_diesel::ConnectionManager<RealmConnection>> {
    connection_with_url(std::env::var("DATABASE_URL").expect("DATABASE_URL not set"))
}

pub fn connection_with_url(
    db_url: String,
) -> r2d2::PooledConnection<r2d2_diesel::ConnectionManager<RealmConnection>> {
    if let Some(pool) = DIESEL_POOLS.read().get(&db_url) {
        pool.get().unwrap()
    } else {
        match DIESEL_POOLS.write().entry(db_url.clone()) {
            Entry::Vacant(e) => {
                let conn_pool = _connection_pool(db_url);
                let conn = conn_pool.get().unwrap();
                e.insert(conn_pool);
                conn
            }
            Entry::Occupied(e) => e.get().get().unwrap(),
        }
    }
}
pub fn red<T>(err_str: &str, err: T)
where
    T: std::fmt::Display,
{
    #[cfg(debug_assertions)]
    eprintln!("{}: {}", err_str.red(), err);
    #[cfg(not(debug_assertions))]
    eprintln!("{}: {}", err_str, err);
}

fn rollback(conn: &RealmConnection) {
    if let Err(e) = conn.transaction_manager().rollback_transaction(conn) {
        red("connection_not_clean_and_cleanup_failed", e);
    };
}

pub fn rollback_if_required(conn: &RealmConnection) {
    if let Err(e) = diesel::sql_query("SELECT 1").execute(conn) {
        red("connection_not_clean", e);
        rollback(conn);
    } else {
        let t: &dyn diesel::connection::TransactionManager<RealmConnection> =
            conn.transaction_manager();
        let depth = t.get_transaction_depth();
        if depth != 0 {
            red("connection_not_clean", depth);
            rollback(conn);
        }
    }
}

pub fn db_test<F>(run: F)
where
    F: FnOnce(&RealmConnection) -> Result<(), Error>,
{
    let conn = connection();
    conn.test_transaction::<_, failure::Error, _>(|| {
        let r = run(&conn).map_err(|e| {
            eprintln!("failed: {:?}", &e);
            e
        });
        rollback_if_required(&conn);
        r
    })
}

#[cfg(debug_assertions)]
impl diesel::connection::SimpleConnection for DebugConnection {
    fn batch_execute(&self, query: &str) -> QueryResult<()> {
        self.conn.batch_execute(query)
    }
}

#[cfg(debug_assertions)]
impl DebugConnection {
    fn new(url: &str) -> ConnectionResult<Self> {
        Ok(DebugConnection {
            conn: diesel::PgConnection::establish(url)?,
        })
    }
}

#[cfg(debug_assertions)]
impl diesel::connection::Connection for DebugConnection {
    type Backend = diesel::pg::Pg;
    type TransactionManager = diesel::connection::AnsiTransactionManager;

    fn establish(url: &str) -> ConnectionResult<Self> {
        let start = std::time::Instant::now();
        let r = DebugConnection::new(url);
        eprintln!("EstablishConnection in {}", crate::base::elapsed(start));
        r
    }
    fn execute(&self, query: &str) -> QueryResult<usize> {
        let start = std::time::Instant::now();
        let r = self.conn.execute(query);
        eprintln!(
            "ExecuteQuery: {} in {}.",
            colored(query),
            crate::base::elapsed(start)
        );
        r
    }

    fn query_by_index<T, U>(&self, source: T) -> QueryResult<Vec<U>>
    where
        T: diesel::query_builder::AsQuery,
        T::Query:
            diesel::query_builder::QueryFragment<diesel::pg::Pg> + diesel::query_builder::QueryId,
        diesel::pg::Pg: diesel::sql_types::HasSqlType<T::SqlType>,
        U: diesel::deserialize::Queryable<T::SqlType, diesel::pg::Pg>,
    {
        let start = std::time::Instant::now();
        let query = source.as_query();
        let debug_query = diesel::debug_query(&query).to_string();
        let r = self.conn.query_by_index(query);

        eprintln!(
            "QueryByIndex: {} in {}.",
            colored(debug_query.as_str()),
            crate::base::elapsed(start)
        );
        r
    }

    fn query_by_name<T, U>(&self, source: &T) -> QueryResult<Vec<U>>
    where
        T: diesel::query_builder::QueryFragment<diesel::pg::Pg> + diesel::query_builder::QueryId,
        U: diesel::deserialize::QueryableByName<diesel::pg::Pg>,
    {
        let start = std::time::Instant::now();
        let query = {
            let mut qb = diesel::pg::PgQueryBuilder::default();
            source.to_sql(&mut qb)?;
            qb.finish()
        };
        let r = self.conn.query_by_name(source);
        eprintln!(
            "QueryByName: {} in {}",
            colored(query.as_str()),
            crate::base::elapsed(start)
        );
        r
    }

    fn execute_returning_count<T>(&self, source: &T) -> QueryResult<usize>
    where
        T: diesel::query_builder::QueryFragment<diesel::pg::Pg> + diesel::query_builder::QueryId,
    {
        let start = std::time::Instant::now();
        let query = {
            let mut qb = diesel::pg::PgQueryBuilder::default();
            source.to_sql(&mut qb)?;
            qb.finish()
        };
        let r = self.conn.execute_returning_count(source);
        eprintln!(
            "ExecuteReturningCount: {} in {}",
            colored(query.as_str()),
            crate::base::elapsed(start)
        );
        r
    }

    fn transaction_manager(&self) -> &Self::TransactionManager {
        self.conn.transaction_manager()
    }
}

#[cfg(test)]
mod tests {
    use super::RealmConnection;
    use crate::diesel::RunQueryDsl;
    use diesel::{self, sql_query};

    // cargo test --package amitu_base base::db::tests::print_test -- --nocapture --exact
    #[test]
    fn print_test() {
        fn exec(conn: &RealmConnection) {
            let _ = sql_query("SELECT 1").execute(conn);
        }
        let conn = super::connection();
        exec(&conn);
    }
}
