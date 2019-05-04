use std::{thread, sync::mpsc};

pub fn magic(req: &realm::Request, sync: bool) -> realm::Result {
    *resp.body_mut() = match (Mode::detect(&req) {
        Mode::API => serde_json::to_string(&self.realm_json()?)?.into(),
        Mode::HTML => {
            if sync {
                // actual
            } else {
                let (sender, receiver) = mpsc::channel();
                SENDER.send((sender, req, unique_id()));

                let resp = receiver.recv().unwrap();
                html.render(resp)?
            }
        }
        Mode::Layout => serde_json::to_string(&self.widget_spec()?)?.into(),
    };
    Ok(resp)
}

lazy_static! {
    pub(crate) static ref SENDER: mpsc::Sender = {
        let (sender, receiver) = mpsc::channel();
        thread::spawn(move || {
            loop {
                let (sender, req, id) = receiver.recv().unwrap();

                thread::spawn(move || {
                    thread::sleep();
                    sender.send(json!{"loading": id});
                });

                thread::spawn(move || {
                    sender.send(magic(req, false))
                })
            }
        });
        sender
    };
}
