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