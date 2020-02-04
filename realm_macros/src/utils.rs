pub fn convert_id_to_html_path(id_: &str) -> String {
    // first separate the string on .
    let id = String::from(id_);
    let mut html_path;
    let v: Vec<&str> = id.split('.').collect();
    let mut v_: Vec<String> = vec![];
    for sli in v.iter() {
        let k_sli = inflector::cases::kebabcase::to_kebab_case(sli).to_lowercase();
        v_.push(k_sli)
        //html_path.push_str("/");
    }
    html_path = v_.join("/");
    html_path.push_str(".html");
    html_path
}

#[cfg(test)]
mod tests {
    #[test]
    fn cithp_test() {
        let p = "Pages.A.B";
        let tar_s = "pages/a/b.html".to_string();

        let q = "Pages.A.BaC";
        let tar_r = "pages/a/ba-c.html".to_string();

        let r = "Pages.A.cC";
        let tar_d = "pages/a/c-c.html".to_string();

        assert_eq!(tar_s, super::convert_id_to_html_path(p));
        assert_eq!(tar_r, super::convert_id_to_html_path(q));
        assert_eq!(tar_d, super::convert_id_to_html_path(r));
    }
}
