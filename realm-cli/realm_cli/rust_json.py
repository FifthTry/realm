import os
from filecmp import cmp
from string import Template
import re

REVERSE_TEMPLATE = """
pub fn url2path(url: &Url) -> String {
    let url = url.clone();
    let mut search_str = url
        .query_pairs()
        .filter(|(_, v)| v != "null")
        .map(|(k, v)| format!("{}={}", k, v))
        .join("&");
    if search_str != "" {
        search_str = format!("?{}", search_str);
    };
    format!("{}{}", url.path(), search_str)
}

pub fn uri2path(uri: &hyper::Uri) -> String {
    format!(
        "{}{}",
        uri.path(),
        uri.query()
            .map(|q| format!("?{}", q))
            .unwrap_or("".to_owned())
    )
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Maybe<T>(pub Option<T>);

impl<T> FromStr for Maybe<T>
where
    T: FromStr,
    <T as FromStr>::Err: Debug,
{
    type Err = failure::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "null" => Ok(Maybe(None)),
            _ => match s.parse() {
                Ok(v) => Ok(Maybe(Some(v))),
                Err(e) => {
                    Err(error::ErrorKind::ValueError).context(format!("can't parse: {:?}", e))?
                }
            },
        }
    }
}

impl<T: ToString> ToString for Maybe<T> {
    fn to_string(&self) -> String {
        match self.0 {
            Some(ref t) => t.to_string(),
            None => "null".to_owned(),
        }
    }
}

impl<T> Deref for Maybe<T> {
    type Target = Option<T>;

    fn deref(&self) -> &Option<T> {
        &self.0
    }
}

impl<T> Default for Maybe<T> {
    fn default() -> Self {
        Maybe(None)
    }
}


#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct List<T>(pub Vec<T>);

impl<T: ToString> ToString for List<T>
where
    T: Display,
{
    fn to_string(&self) -> String {
        self.0.iter().join("||")
    }
}


// TODO need to write test case for this
impl<T> FromStr for List<T>
where
    T: FromStr,
    <T as FromStr>::Err: Debug,
{
    type Err = failure::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut vec_t = Vec::new();
        for each_element in s.split("||") {
            let element: T = match each_element.parse() {
                Ok(v) => v,
                Err(e) => {
                    Err(error::ClientErrorKind::ValueError.context(format!("can't parse: {:?}", e)))?
                }
            };
            vec_t.push(element);
        }
        Ok(List(vec_t))
    }
}

impl<T> Deref for List<T> {
    type Target = Vec<T>;

    fn deref(&self) -> &Vec<T> {
        &self.0
    }
}

impl<T> Default for List<T> {
    fn default() -> Self {
        List(Vec::new())
    }
}


use chrono::NaiveDate;
use serde_json::Value as JsonValue;
use url::Url;


pub fn external_login(next: String) -> String {
    let mut url = Url::parse("http://acko.com/login/").unwrap();
    url.query_pairs_mut().append_pair("next", &next.to_string());
    url2path(&url)
}

%s
"""


def get_routes():
    
    routes = []

    for root, _, files in os.walk("src/routes/"):
        directory = root.replace("src/routes/", "")
        print("dir", directory)

        # Ignore the files outside the ./src of each directory inside acko_routes/
        # such as Cargo.toml.
        if directory.find("/src") == -1:
            continue
        # Ignore common directory from acko_routes/
        if directory.find("common/src") != -1:
            continue

        for fileName in files:
            # Ignore non rust files.
            if not fileName.endswith(".rs"):
                continue
            # Ignore lib.rs and mod.rs files.
            if fileName == "lib.rs" or fileName == "mod.rs":
                continue

            # Generally file name should be the route name
            # and directory name should be the route path.
            routeName = fileName.replace(".rs", "")
            routePath = directory.replace("/src", "")
            
            print("filename", fileName)

            
            if routePath == "index":
                # index route directory should be treated as "/"
                path = "/"
                module = "index::index"
            elif routeName == "index":
                # index routes should be treated as ""
                path = f"/{routePath}/"
                module = routePath.replace("/", "::") + "::index"
            else:
                path = f"/{routePath}/{routeName}/"
                module = routePath.replace("/", "::") + "::" + routeName

            """ Todo: Below are hacks for removing /workspace/search route and
            modifying /partner/issue to /policy/issue. These routes are getting
            generated because of interdependency between crates that end up
            creating cyclic dependency. Figure out a way to remove below hacks.
            """

            if path == "/workspace/search/":
                continue
            if path == "/partner/issue/":
                path = "/policy/issue/"

            """Hacks end here."""

            routes.append((path, module, parse(root + "/" + fileName)[1:]))

    routes.sort(reverse=True)
    return routes

def write_formatted_file(file_path, file_data):
    ext = "." + file_path.split(".")[-1]
    temp_file = "/".join(file_path.split("/")[:-1]) + "/temp" + ext
    open(temp_file, "w").write(file_data)

    if ext == ".rs":
        os.system("rustfmt %s" % temp_file)
    elif ext == ".elm":
        os.system("elm-format --yes --elm-version=0.19 %s" % temp_file)

    if cmp(temp_file, file_path):
        os.system("rm %s" % temp_file)
    else:
        os.system("mv %s %s" % (temp_file, file_path))
	    
	    
def generate_reverse(routes):
    reverse = ""
    for (url, mod, args) in routes:
        if url == "/":
            function_name = "index"
        else:
            function_name = url[1:].replace("/", "_").replace("_index", "")
            if function_name.endswith("_"):
                function_name = function_name[:-1]
        if len(args) == 0:
            reverse += """
pub fn %s() -> String {
    "%s".to_owned()
}
""" % (
                function_name,
                url,
            )
        else:
            reverse += """
pub fn %s(%s) -> String {
    let mut url = Url::parse("http://acko%s").unwrap();""" % (
                function_name,
                ", ".join("%s: %s" % arg for arg in args),
                url,
            )
            for (name, _) in args:
                reverse += """
    url.query_pairs_mut().append_pair("%s", &%s.to_string());""" % (
                    name,
                    name,
                )
            reverse += """
    url2path(&url)
}
"""

    write_formatted_file(
        "src/layout/src/reverse.rs", REVERSE_TEMPLATE % (reverse,)
    )

def parse(mod_path):
    """
    Given a module name (file path, relative to ., eg src/acko/utils.rs), this
    function returns:

        List (arg, type)

    """
    with open(mod_path, "r") as f:
        args_str = re.compile(r"(?<=pub fn layout\()[^{]*(?=\) \-\>)").search(
            f.read().replace("\n", " ")
        )
        args_str = "" if not args_str else args_str[0].replace(" ", "")
        return [
            (r.split(":")[0], r.split(":")[1]) for r in args_str.split(",") if r != ""
        ]
    
    return []


def main():
    r = get_routes()
    print(r)
    generate_reverse(r)
    
main()

