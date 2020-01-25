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
[UDMIGRATION.md]: https://github.com/ackotech/realm/blob/realm2/UDMIGRATION.md

# ChangeLog

## Unreleased

- Added template based server side rendering. You may want to use:
```rust
fn main() {
    for entry in walkdir::WalkDir::new("templates") {
        let entry = entry.unwrap();
        eprintln!("cargo:rerun-if-changed={}", entry.path().display());
    }
}
// with the following in your Cargo.toml
// [package]
// build = "build.rs"
//
// [build-dependencies]
// walkdir = "2"
```

- Elm: Scroll to top of page on page change
- Elm: Sending a message after delay of 200ms to let app show a loading dialog
- Elm: BREAKING: removed Realm.Utils.{link, plainLink, newTabLink}, use Element versions
  instead.
- Elm: Added method `navigate : String -> Cmd (Msg msg)` in `Realm.elm`.
- Elm: Added method `mif : Maybe a -> (a -> E.Element msg) -> E.Element msg` in `Utils.elm`.
- Backtrace added for errors. Panics still needs to be cleaned.
- Added the following methods in `realm::base::In`:
  - is_anonymous: Returns true if the `ud` cookie is empty.
  - is_authenticated: Returns true if the `ud` cookie is not empty.
  - is_local: Returns true if the `HOST` is localhost, 127.0.0.1 or 127.0.0.2.
- Added method `error<T>(key: &str, message: &str)`. Returns a `FormError` containing the `key` and `message`.
- Added method `json<T>(&mut self, name: &str)` in `RequestConfig`. Takes a field name `name` and returns it's value if present in the body of the request.
- Following Database related methods and properties are moved to `realm::base::pg` and `realm::base::sqlite`:
  - connection()
  - connection_with_url()
  - RealmConnection
- Generic ud cookie: Applications can define their own struct for `ud` cookie. This change is not compatible with the previous realm versions. Please refer to [UDMIGRATION.md]  guide.
- Enable one of the following features in `Cargo.toml` to use database:
  - Postgres: postgres+postgres_default
  - SQLite: sqlite+sqlite_default


## 0.1.18 - 21 Nov 2019
- Fix: `Realm.Test` on error from server, report it and keep tests running.
- `realm::RequestConfig::required()` etc methods now return `realm::Error(InputError)`
  instead of `realm::request_config::Error`, middleware need only catch single error
  now:
```rust
    let resp = match forward::magic(&in_) {
        Ok(r) => Ok(r),
        Err(e) => {
            match e.downcast_ref::<realm::Error>()
            {
                Some(realm::Error::PageNotFound {message}) => fifthtry::http404(&in_, message.as_str()),
                Some(realm::Error::InputError {error}) => fifthtry::http404(&in_, &error.to_string()),
                _ => Err(e)
            }
        }
    };
```
- Added support for extra Elm ports. Applications can add ports to
  `window.realm_extra_ports` in `Javascript`. Applications can create `Ports.elm` and
  specify ports like this: `port something : JE.Value -> Cmd msg`. Applications can
  create a Javascript file and add the port and callback function like this to
  `window.realm_extra_ports`:

```javascript
window.realm_extra_ports = {
    "something": function(data) {
    }
};

// the realm app is available as window.realm_app. so you can also do:
window.addEventListener("foo", function(evt) { window.realm_app.ports.foo.send(evt) })
```

- Added support for using custom html. Applications can create `index.html` and realm
  will use this while rendering a page. `index.html` must contains special strings:
  `__realm_title__` and `__realm_data__`, these will be replaced by page title and page
  data.
- Removed `APP_NAME` feature, use custom `index.html` to overwrite script name instead.
- Added `window.realm_app_init()` and `window.realm_app_shutdown()` hooks, if you want
  to do something after realm app is initialized and is shutting down.
- Added `In.darkMode`.

## 0.1.17 - 16 Oct 2019

- `realm::base::CiString` is public now.
- Elm backward incompatible: changed signature of `Realm.Utils.html` and
  `Realm.Utils.htmlLine` to take `Realm.Utils.Rendered` as input instead of `String`.
- `Realm.Test`: show failures in red
- `Realm.Test`: keyboard shortcut `e` to toggle between showing all tests vs only
  failed ones
- `Realm.Test`: on test completion narrow to only failed tests if test failed.
- Added `.required2()`, `.required3()` and `.required4()` to
  `realm::request_config::RequestConfig`. Advantage of these variants over multiple
  invocations of `.required()`: all errors are shown in one go, with `.required()`, only
  the first error is shown in response.
- Added `Realm.Utils.maybe : Json.Decode.Decoder a -> Json.Decode.Decoder (Maybe a)`,
  which is a better version of `Json.Decode.maybe`.
- Added `Realm.Utils.iff : Bool -> E.Element msg -> E.Element msg` (show something or
  use E.none if false).
- Added `Realm.Utils.escEnter` to attach event handler for Escape and Enter keys. Also
  `.onEnter`, `.onSpaceAndEnter` and `.button`.
- Added logging of SQL queries to console in debug mode.
- Added `Realm.Utils.mapIth` and `.mapAIth` for updating ith member of a list/array.
- Fix: Constructing URL properly when doing submit with URLs including query parameters.
- Added `realm::is_realm_url()` and `realm::handle()` to handle realm related URLs.
- Fix: `realm::base::rollback_if_required()` now rolls back if transaction depth managed
  by diesel is wrong.
- Fix: If a nested elm module sent by server is not in `Elm`, then `getApp()` returns
  none instead of crashing, so it is consistent with what happens when a non nested,
  missing elm module is sent.
- Fix: in test mode, on missing elm module, a proper message is shown and
  test continues.
- Added `realm::Response::redirect(next)` and `realm::Response::redirect_with(next,
  StatusCode)` methods. In `Layout` mode, redirect to `next` page. In `HTML/API` mode,
  sends HTTP 3xx response with `location` header as `next`.
- Location for `elm.js` if `APP_NAME` environment variable is configured:
  `/static/APP_NAME/elm.js`. Default location for `elm.js` is `/static/elm.js`.
- Added `realm::base::db::db_test()` back.

## 0.1.16 - 23 Sept 2019

- `realm::base::db::RealmConnection`: in release build this is an alias for
  `PgConnection`, where as in debug build its an alias for `DebugConnection`, which
  prints SQL queries and time for execution. It also prints every connection
  established and the time it took to establish the connection.
- Removed unused `realm::base::UserStatus` type.
- Added `Realm.Utils.html` and `Realm.Utils.htmlLine` helpers to render server generated
  HTML in Elm.
  - They depend on html-parser, so add it: `elm install hecrj/html-parser`
 inside
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

## 0.1.15 - 14 Sept 2019

- Added `RequestConfig.param()` to get a parameter from request.
- Deprecated `RequestConfig.get()`, `.param()` should be used now.
- Added `Realm.tuple : JD.Decoder a -> JD.Decoder b -> JD.Decoder (a, b)` and
  `Realm.tupleE : (a -> JE.Value) -> (b -> JE.Value) -> ((a, b) -> JE.Value)`.
- Fix: Query params in URLs are not lost during navigation.
- Fix: Device switching in /storybook/ was buggy in some cases.


## 0.1.14 - 10 Sept 2019

- `realm::Response` now implements `serde::Serialize`.
