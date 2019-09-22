Rust / Elm base full stack web framework.

# Publish Crate

1. Must have ownership for particular crate at crates.io
2. Must have [login through terminal] using cargo token.
3. Change current version in Cargo.toml in increasing way (Digit places should be
   change according to feature).
4. Do `cargo check --all` should not have any compile error, warning nothing.
5. Do `cargo fmt`
6. Do `git add <changes files>`
7. Do `git commit -m "message related to your changes"`
8. Do `git push`
9. Do `cargo package`
10. Do `cargo publish`, It should be successfully published.


[login through terminal]: https://doc.rust-lang.org/cargo/reference/publishing.html


# ChangeLog

## Unreleased

- `realm::base::db::RealmConnection`: in release build this is an alias for
  `PgConnection`, where as in debug build its an alias for `DebugConnection`, which
  prints SQL queries and time for execution. It also prints every connection
  established and the time it took to establish the connection.
- Removed unused `realm::base::UserStatus` type.
- Added `Realm.Utils.html` and `Realm.Utils.htmlLine` helpers to render server generated
  HTML in Elm.
  - They depend on html-parser, so add it: `elm install hecrj/html-parser` inside
    'frontend' folder.
- Added `realm::base::FormError::empty()`, and deprecated `::new()`.
- Added `realm::base::FormError::single()` to create one off error messages.
- Added `realm::Error` and `realm::request_config::Error` so we can do following error
  handling in middleware:

```rust
if e.downcast_ref::<realm::Error>().is_some()
    || e.downcast_ref::<realm::request_config::Error>().is_some()
{
    fifthtry::http404(&in_, error.as_str())
} else {
    Err(e)
}
```

- Added `realm::Or404` trait and implemented it on `Result<T, failure::Error>` so one
  can do eg `let content = fifthtry_db::content::get(in_, id).or_404()?;` in routes to
  convert arbitrary errors to 404s.
- Added `realm::request_config::RequestConfig.optional()`, to get optional values.
- When getting input values using `.param()` or `.optional()`, now onwards `null` in
  json, and empty value in query params are treated same as missing keys.
- Renamed/deprecated `.param()` to `.required()`, which goes better with `.optional()`.
- Moved test.rs, storybook.rs and iframe.rs to realm.

## 0.1.15

- Added `RequestConfig.param()` to get a parameter from request.
- Deprecated `RequestConfig.get()`, `.param()` should be used now.
- Added `Realm.tuple : JD.Decoder a -> JD.Decoder b -> JD.Decoder (a, b)` and
  `Realm.tupleE : (a -> JE.Value) -> (b -> JE.Value) -> ((a, b) -> JE.Value)`.
- Fix: Query params in URLs are not lost during navigation.
- Fix: Device switching in /storybook/ was buggy in some cases.


## 0.1.14

- `realm::Response` now implements `serde::Serialize`.
