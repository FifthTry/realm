use realm::Mode;
use std::{sync::mpsc, thread};

pub fn magic_(req: &realm::Request) -> realm::Result {
    crate::routes::index::layout(req, 0)
}

pub fn magic(req: &realm::Request) -> realm::Result {
    match Mode::detect(&req) {
        Mode::HTML => {
            let (sender, receiver) = mpsc::channel();
            SENDER.send((sender, req));

            receiver.recv().unwrap()
        }
        Mode::API => magic_(req),
    }
}

lazy_static! {
    pub(crate) static ref SENDER: mpsc::Sender<(mpsc::Sender<realm::Result>, realm::Request)> = {
        let (sender, receiver) = mpsc::channel();
        thread::spawn(move || loop {
            let (sender, req) = receiver.recv().unwrap();

            thread::spawn(move || {
                thread::sleep();
                sender.send(magic_(&realm::loading_page(req)))
            });

            thread::spawn(move || sender.send(magic_(req)))
        });
        sender
    };
}
