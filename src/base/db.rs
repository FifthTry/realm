#[cfg(debug_assertions)]
use colored::Colorize;

#[cfg(debug_assertions)]
lazy_static! {
    pub static ref SS: syntect::parsing::SyntaxSet =
        syntect::parsing::SyntaxSet::load_defaults_newlines();
    pub static ref TS: syntect::highlighting::ThemeSet =
        syntect::highlighting::ThemeSet::load_defaults();
}

#[cfg(feature = "sqlite")]
#[cfg(debug_assertions)]
pub fn colored(sql: &str) -> String {
    let syntax = SS.find_syntax_by_extension("sql").unwrap();
    let mut h = syntect::easy::HighlightLines::new(syntax, &TS.themes["base16-ocean.dark"]);
    let ranges: Vec<(syntect::highlighting::Style, &str)> = h.highlight(sql, &SS);
    syntect::util::as_24_bit_terminal_escaped(&ranges[..], false) + "\x1b[0m"
}

#[allow(dead_code)]
pub fn red<T>(err_str: &str, err: T)
where
    T: std::fmt::Display,
{
    #[cfg(debug_assertions)]
    debug!("{}: {}", err_str.red(), err);
    #[cfg(not(debug_assertions))]
    debug!("{}: {}", err_str, err);
}
