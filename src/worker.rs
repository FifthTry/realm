use diesel::prelude::*;

#[derive(Queryable, serde::Deserialize)]
pub struct DBTask {
    pub id: i32,
    pub path: String,
    pub method: String,
    pub data: serde_json::Value,
    pub cookies: serde_json::Value,
    pub number_tries: i32,
}

pub struct Task {
    pub path: String,
    pub method: String,
    pub data: serde_json::Value,
    pub cookies: serde_json::Value,
}

pub enum TaskStatus {
    Created,
    Failed,
    Processed,
}

impl From<TaskStatus> for String {
    fn from(status: TaskStatus) -> Self {
        match status {
            TaskStatus::Created => "created".to_string(),
            TaskStatus::Failed => "failed".to_string(),
            TaskStatus::Processed => "processed".to_string(),
        }
    }
}

pub fn latest(
    conn: &crate::base::pg::RealmConnection,
    limit: i64,
) -> crate::base::Result<Vec<DBTask>> {
    use crate::schema::realm_task;
    realm_task::table
        .select((
            realm_task::id,
            realm_task::path,
            realm_task::method,
            realm_task::data,
            realm_task::cookies,
            realm_task::number_tries,
        ))
        .filter(realm_task::status.eq("created"))
        .limit(limit)
        .load(conn)
        .map_err(|e| e.into())
}

pub fn updated_status(
    conn: &crate::base::pg::RealmConnection,
    id: i32,
    number_tries: i32,
    status: TaskStatus,
) -> crate::base::Result<()> {
    use crate::schema::realm_task;
    let status: String = status.into();
    diesel::update(realm_task::table)
        .set((
            realm_task::status.eq(status),
            realm_task::number_tries.eq(number_tries + 1),
            realm_task::updated_on.eq(chrono::Utc::now()),
        ))
        .filter(realm_task::id.eq(id))
        .execute(conn)
        .map(|_| ())
        .map_err(Into::into)
}

/*
   data,
   status
*/

pub fn create_realm_tasks<UD>(
    in_: &crate::base::In<UD>,
    tasks: Vec<Task>,
) -> crate::base::Result<()>
where
    UD: crate::UserData,
{
    use crate::schema::realm_task;
    let mut v = vec![];
    for task in tasks.into_iter() {
        v.push((
            realm_task::method.eq(task.method),
            realm_task::path.eq(task.path),
            realm_task::data.eq(task.data),
            realm_task::cookies.eq(task.cookies),
            realm_task::status.eq("created"),
            realm_task::number_tries.eq(0),
            realm_task::priority.eq(0),
            realm_task::created_on.eq(in_.now),
            realm_task::updated_on.eq(in_.now),
        ));
    }
    diesel::insert_into(realm_task::table)
        .values(&v)
        .execute(in_.conn)
        .map_err(Into::into)
        .map(|_| ())
}

#[macro_export]
macro_rules! realm_worker {
    ($e:expr) => {{

        fn handle_rows(conn: &realm::base::pg::RealmConnection) -> realm::base::Result<usize>
        {
            let tasks = realm::bojack::latest(conn, 5)?;
            let count = tasks.len();
            if count > 0 {
                println!("picked event from realm_task: {}", count);
            }
            for task in tasks.into_iter() {
                let method = {
                    // TODO: use task.method
                    http::Method::POST
                };
                match $e(&realm::Context::from(method, task.path.as_str(), task.data, serde_json::from_value(task.cookies)?)) {
                    Ok(t) => {
                        realm::bojack::updated_status(
                            conn,
                            task.id,
                            task.number_tries,
                            realm::bojack::TaskStatus::Processed,
                        )?;
                        println!("task_processed: {}", task.id);
                        // observer::observe_string(
                        //     "task_processed",
                        //     format!("{}", task.id).as_str(),
                        // );
                    }
                    Err(e) => {
                        realm::bojack::updated_status(
                            conn,
                            task.id,
                            task.number_tries,
                            realm::bojack::TaskStatus::Failed,
                        )?;
                        println!("task_process_error: {}", e);
                        // observer::observe_string("process_err", format!("{}", e).as_str());
                    }
                };
            }
            Ok(count)
        }

        let conn = realm::base::pg::connection();
        while !realm::env::ctrl_c().expect("ctrl-c issue") {
            let c = match handle_rows(&conn) {
                Ok(c) => c,
                Err(e) => {
                    observer::observe_string("main_process_err", format!("{}", e).as_str());
                    0
                }
            };
            if c == 0 {
                std::thread::sleep(std::time::Duration::from_secs(2));
            }
        };
    }};
}
