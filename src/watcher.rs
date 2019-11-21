use crossbeam_channel::{Receiver, Sender};
use notify::Watcher;

lazy_static! {
    pub static ref WATCHER: Sender<(String, Sender<String>)> = setup_watcher();
}

#[allow(clippy::zero_ptr, clippy::drop_copy)]
fn setup_watcher() -> Sender<(String, Sender<String>)> {
    let (s, r): (_, Receiver<(String, Sender<String>)>) = crossbeam_channel::bounded(0);

    std::thread::spawn(move || {
        let (ws, wr) = crossbeam_channel::unbounded();
        let mut watcher: notify::RecommendedWatcher = notify::Watcher::new_immediate(ws).unwrap();
        let to_watch =
            std::env::var("REALM_WATCHER_DIR").unwrap_or_else(|_| "frontend".to_string());
        println!(
            "watching: {}, overwrite it by setting REALM_WATCHER_DIR env",
            &to_watch
        );
        watcher
            .watch(to_watch, notify::RecursiveMode::Recursive)
            .unwrap();

        let mut waiters = vec![];
        let mut current = get_current().unwrap();

        loop {
            select! {
                recv(r) -> msg => {
                    match msg {
                        Ok((hash, ts)) => {
                            if hash != current {
                                println!("hash={}, current={}.", &hash, &current);
                                if let Err(e) = ts.send(current.clone()) {
                                    eprintln!("should not happen: {:?}", e.into_inner());
                                }
                            } else {
                                waiters.push(ts);
                            }
                        },
                        Err(e) => eprintln!("Got error [should not happen]: {:?}", e)
                    }
                },
                recv(wr) -> msg => {
                    match msg {
                        Ok(evt) => {
                            if !format!("{:?}", evt).contains(".elm\"") {
                                // println!("ignored event: {:?}", evt);
                                continue;
                            }

                            println!("got file event: {:?}", evt);

                            let new = get_current().unwrap();
                            if new == current {
                                println!("no change in hash");
                                continue
                            }
                            println!("hash changed");
                            current = new;

                            let _ : Vec<_> = waiters.iter().map(|w| {
                                if let Err(e) = w.send(current.clone()) {
                                    eprintln!("Got error [can happen]: {:?}", e.into_inner());
                                }
                            }).collect();
                            waiters.clear();
                        },
                        Err(e) => eprintln!("Got error [can happen]: {:?}", e)
                    }
                }
            }
        }
    });

    s
}

pub fn poll(ctx: &crate::Context, hash: String) -> Result<crate::Response, crate::Error> {
    if !crate::base::is_test() {
        return Err(crate::Error::PageNotFound {
            message: "server not running in test mode".to_string(),
        });
    }

    let (s, r) = crossbeam_channel::bounded(0);

    if let Err(e) = WATCHER.send((hash, s)) {
        eprintln!("Got error: {:?}", e.into_inner());
        panic!()
    }

    let hash = select! {
        recv(r) -> msg => {
            match msg {
                Ok(h) => h,
                Err(e) => {
                    eprintln!("Got error3: {:?}", e);
                    "".to_string()
                }
            }
        },
        default(std::time::Duration::from_secs(30)) => "".to_string(),
    };

    Ok(crate::Response::Http(ctx.response(hash.into()).unwrap()))
}

fn get_current() -> Result<String, failure::Error> {
    let doit_cmd =
        std::env::var("REALM_WATCHER_DOIT_CMD").unwrap_or_else(|_| "doit elm".to_string());
    let output = std::process::Command::new("sh")
        .args(&["-c", doit_cmd.as_ref()])
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .output()
        .unwrap();

    if !output.status.success() {
        eprintln!("{} failed", doit_cmd);
        eprintln!("stdout: {}", std::str::from_utf8(&output.stdout).unwrap());
        eprintln!("stderr: {}", std::str::from_utf8(&output.stderr).unwrap());
        return Err(failure::err_msg("doit failed"));
    };

    let output = std::process::Command::new("shasum")
        .arg(
            std::env::var("REALM_WATCHER_IFRAME")
                .unwrap_or_else(|_| "static/iframe.js".to_string()),
        )
        .output()
        .unwrap();

    if !output.status.success() {
        eprintln!("shasum failed");
        eprintln!("stdout: {}", std::str::from_utf8(&output.stdout).unwrap());
        eprintln!("stderr: {}", std::str::from_utf8(&output.stderr).unwrap());
        return Err(failure::err_msg("shasum failed"));
    };

    Ok(std::str::from_utf8(&output.stdout)
        .unwrap()
        .trim()
        .to_string())
}
