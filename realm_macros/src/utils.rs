use inflector;
pub fn convert_id_to_html_path(id_: &str) -> String{
    // first seperate the string on .
    let id = String::from(id_);
    let mut html_path = String::new();
    let v: Vec<&str> = id.split('.').collect();
    for sli in v[1..].iter(){
        let k_sli = inflector::cases::kebabcase::to_kebab_case(sli).to_lowercase();
        html_path.push_str(&k_sli);
    }
    html_path

}


#[cfg(test)]
mod tests {
    pub fn convert_id_to_html_path(id_: &str) -> String{
        // first seperate the string on .
        let id = String::from(id_);
        let mut html_path = String::new();
        let v: Vec<&str> = id.split('.').collect();
        let mut v_: Vec<String> = vec![];
        for sli in v[1..].iter(){
            let k_sli = inflector::cases::kebabcase::to_kebab_case(sli).to_lowercase();
            v_.push(String::from(k_sli))
            //html_path.push_str("/");
        }
        html_path = v_.join("/");
        html_path.push_str(".html");
        html_path
    }
    #[test]
    fn cithp_test() {
        let p = "Pages.A.B";
        let tar_s = "a/b.html".to_string();

        let q = "Pages.A.BaC";
        let tar_r = "a/ba-c.html".to_string();

        let r = "Pages.A.cC";
        let tar_d = "a/c-c.html".to_string();

        println!("tar_s {:?}", tar_r);
        assert_eq!(tar_s, convert_id_to_html_path(p));
        assert_eq!(tar_r, convert_id_to_html_path(q));
        assert_eq!(tar_d, convert_id_to_html_path(r));

    }

}

