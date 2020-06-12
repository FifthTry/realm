use crate::base::db::red;
use diesel::connection::TransactionManager;
use diesel::prelude::*;

fn _connection_pool(
    mut db_url: String,
) -> r2d2::Pool<r2d2_diesel::ConnectionManager<RealmConnection>> {
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
        .max_size(
            std::env::var("REALM_DB_POOL_SIZE")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .unwrap(),
        )
        .build(manager)
        .expect("Failed to create DIESEL_POOL.")
}

lazy_static! {
    pub static ref DIESEL_POOLS: antidote::RwLock<
        std::collections::HashMap<
            String,
            r2d2::Pool<r2d2_diesel::ConnectionManager<RealmConnection>>,
        >,
    > = antidote::RwLock::new(std::collections::HashMap::new());
}

#[observed(namespace = "realm__pg")]
pub fn connection() -> r2d2::PooledConnection<r2d2_diesel::ConnectionManager<RealmConnection>> {
    connection_with_url(std::env::var("DATABASE_URL").expect("DATABASE_URL not set"))
}

pub fn connection_with_url(
    db_url: String,
) -> r2d2::PooledConnection<r2d2_diesel::ConnectionManager<RealmConnection>> {
    {
        if let Some(pool) = DIESEL_POOLS.read().get(&db_url) {
            return pool.get().unwrap();
        }
    }
    match DIESEL_POOLS.write().entry(db_url.clone()) {
        std::collections::hash_map::Entry::Vacant(e) => {
            let conn_pool = _connection_pool(db_url);
            let conn = conn_pool.get().unwrap();
            e.insert(conn_pool);
            conn
        }
        std::collections::hash_map::Entry::Occupied(e) => e.get().get().unwrap(),
    }
}

pub fn db_test<F>(run: F)
where
    F: FnOnce(&RealmConnection) -> Result<(), failure::Error>,
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
pub type RealmConnection = observer::pg::DebugConnection;
#[cfg(not(debug_assertions))]
pub type RealmConnection = diesel::PgConnection;

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
