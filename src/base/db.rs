use diesel::{connection::TransactionManager, prelude::*, PgConnection};

lazy_static! {
    pub static ref DIESEL_POOL: r2d2::Pool<r2d2_diesel::ConnectionManager<PgConnection>> = {
        let mut db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL not set");
        if crate::base::is_test() {
            // add search_path=test (%3D is = sign)
            if db_url.contains('?') {
                db_url += "&options=-c search_path%3Dtest"
            } else {
                db_url += "?options=-c search_path%3Dtest"
            }
        };

        let manager = r2d2_diesel::ConnectionManager::<PgConnection>::new(db_url);
        r2d2::Pool::builder()
            .max_size(10)
            .build(manager)
            .expect("Failed to create DIESEL_POOL.")
    };
}

pub fn connection() -> r2d2::PooledConnection<r2d2_diesel::ConnectionManager<PgConnection>> {
    DIESEL_POOL.get().expect("Couldn't open DB connection.")
}

pub fn rollback_if_required(conn: &PgConnection) {
    if let Err(e) = diesel::sql_query("SELECT 1").execute(conn) {
        eprintln!("connection_not_clean: {:?}", e);
        if let Err(e) = conn.transaction_manager().rollback_transaction(conn) {
            eprintln!("connection_not_clean_and_cleanup_failed: {:?}", e);
        }
    }
}
