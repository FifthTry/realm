Rust / Elm base full stack web framework.

For publish the crate
1. Must have ownership for particular crate at crates.io
2. Must have login through terminal using cargo token. [Follow this](https://doc.rust-lang.org/cargo/reference/publishing.html)
3. Change current version in Cargo.toml in increasing way(Digit places should be change according to feature). 
4. Do `cargo check --all` should not have any compile error, warning nothing.
5. Do `cargo fmt`
6. Do `git add <changes files>`
7. Do `git commit -m "message related to your changes"`
8. Do `git push`
9. Do `cargo package`
10. Do `cargo publish`, It should be successfully published.