#[cfg(debug_assertions)]
use crate::base::db::colored;
use crate::base::db::red;

#[cfg(debug_assertions)]
use diesel::query_builder::QueryBuilder;
use diesel::{connection::TransactionManager, prelude::*};

fn _connection_pool(db_url: String) -> Result<RealmConnection, diesel::ConnectionError> {
    #[cfg(feature = "postgres")]
    let db_url = if crate::base::is_test() {
        // add search_path=test (%3D is = sign)
        if db_url.contains('?') {
            db_url + "&options=-c search_path%3Dtest"
        } else {
            db_url + "?options=-c search_path%3Dtest"
        }
    };

    RealmConnection::establish(db_url.as_str())
}

pub fn connection() -> Result<RealmConnection, diesel::ConnectionError> {
    connection_with_url(std::env::var("DATABASE_URL").expect("DATABASE_URL not set"))
}

pub fn connection_with_url(db_url: String) -> Result<RealmConnection, diesel::ConnectionError> {
    _connection_pool(db_url)
}

pub fn db_test<F>(run: F)
where
    F: FnOnce(&RealmConnection) -> Result<(), failure::Error>,
{
    let conn = connection().unwrap();
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
pub struct DebugConnection {
    pub conn: diesel::SqliteConnection,
}

#[cfg(debug_assertions)]
pub type RealmConnection = DebugConnection;
#[cfg(not(debug_assertions))]
pub type RealmConnection = diesel::SqliteConnection;

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
            conn: diesel::SqliteConnection::establish(url)?,
        })
    }
}

#[cfg(debug_assertions)]
impl diesel::connection::Connection for DebugConnection {
    type Backend = diesel::sqlite::Sqlite;
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
        T::Query: diesel::query_builder::QueryFragment<diesel::sqlite::Sqlite>
            + diesel::query_builder::QueryId,
        diesel::sqlite::Sqlite: diesel::sql_types::HasSqlType<T::SqlType>,
        U: diesel::deserialize::Queryable<T::SqlType, diesel::sqlite::Sqlite>,
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
        T: diesel::query_builder::QueryFragment<diesel::sqlite::Sqlite>
            + diesel::query_builder::QueryId,
        U: diesel::deserialize::QueryableByName<diesel::sqlite::Sqlite>,
    {
        let start = std::time::Instant::now();
        let query = {
            let mut qb = diesel::sqlite::SqliteQueryBuilder::default();
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
        T: diesel::query_builder::QueryFragment<diesel::sqlite::Sqlite>
            + diesel::query_builder::QueryId,
    {
        let start = std::time::Instant::now();
        let query = {
            let mut qb = diesel::sqlite::SqliteQueryBuilder::default();
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
