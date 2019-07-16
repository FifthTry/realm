import os
import re
from typing import List, Tuple, Optional, Match
from string import Template
import json
import realm_cli.p_assert as pa

REALM_CONFIG = {}


REVERSE_TEMPLATE = """
use realm::utils::{Maybe, url2path};

%s
"""

FORWARD_TEMPLATE = """
use crate::routes;
use crate::cms;
use realm::utils::{get_slash_complete_path, get, sub_string};
use serde_json::Value;
use std::{collections::HashMap, env};
use url::Url;
use graft::{self, Context, DirContext};

pub fn get_default_context(cms_path: &str) -> impl Context {
     let mut proj_dir = env::current_dir().expect("could not find current dir");


    DirContext::new(proj_dir.join(cms_path).join("includes"))
}

pub fn magic(req: &realm::Request) -> realm::Result {
    let url = req.uri();
    let site_url = "http://127.0.0.1:3000".to_string();
    let path = get_slash_complete_path(url.path());
    let url = Url::parse(&format!("{}{}", &site_url, req.uri()).as_str())?;
    let mut rest = sub_string(path.as_ref(), path.len(), None);
    let data_: serde_json::Value = serde_json::from_slice(req.body().as_slice()).unwrap_or_else(|e| json!(null));
    let query_: HashMap<_, _> = url.query_pairs().into_owned().collect();
    match path.as_ref() {%s
        _ => unimplemented!()
    }
}

"""


def get_route_entities(test_dir: Optional[str] = None) -> List[str]:
    """
    Gets a list of all directories which are also routes in routes/
    """
    route_dir: str = "src"
    if test_dir:
        route_dir = test_dir
    route_dir += "/routes/"
    route_entities: List[str] = []
    for entity in os.scandir(route_dir):
        if entity.is_dir():
            directory: str = entity.name
            if directory == "common" or directory == "src":
                continue
            route_entities.append(directory)

    route_entities.sort()
    return route_entities


def get_routes(test_dir: Optional[str] = None):
    routes: List[Tuple[str, str, List[Tuple[str, str]]]] = []
    global REALM_CONFIG
    if os.path.exists("realm.json"):
        with open("realm.json") as f:
            REALM_CONFIG = json.load(f)
    routes_dir_path: str = "src/routes/"
    if test_dir:
        routes_dir_path = test_dir + "/routes/"
        if os.path.exists(test_dir + "/realm.json"):
            with open(test_dir + "/realm.json") as f:
                REALM_CONFIG = json.load(f)

    for root, _, files in os.walk(routes_dir_path):
        print("root, _, files", root, _, files)
        directory: str = root.replace(routes_dir_path, "")
        for fileName in files:
            if not fileName.endswith(".rs"):
                continue
            # Ignore lib.rs and mod.rs files.
            if fileName == "lib.rs" or fileName == "mod.rs":
                continue
            # Generally file name should be the route name
            # and directory name should be the route path.
            routeName: str = fileName.replace(".rs", "")
            routePath: str = directory.replace("/src", "")

            print("routePath:{} routeName:{}".format(routePath, routeName))
            print("filename", fileName)

            path: str = ""
            module: str = ""
            if routePath == "":
                path = f"/"
                module = routeName
            elif routeName == "index":
                # index routes should be treated as ""
                path = f"/{routePath}/"
                module = routePath.replace("/", "::") + "::index"
            else:
                path = f"/{routePath}/{routeName}/"
                module = routePath.replace("/", "::") + "::" + routeName
            print("module", module)
            routes.append((path, module, parse(root + "/" + fileName)[1:]))

    routes.sort(reverse=True)
    return routes


def generate_forward(directories, routes, test_dir=None):
    # filter routes and directories based on whitelist

    template = Template("use $crate;")
    use_crates = []
    for directory in directories:
        use_crates.append(template.substitute(crate=directory))
    use_crates = "\n".join(use_crates)
    forward = ""
    for (url, mod, args) in routes:

        print("uma, ", url, mod, args)

        if url == "/" and mod != "index":
            url += mod + "/"

        mod = mod.replace("::", "_").replace("_index", "")

        if len(args) == 0:
            forward += """
        "%s" => routes::%s::layout(req),""" % (
                url,
                mod,
            )
        else:
            forward += (
                """
        "%s" => {"""
                % url
            )

            for (name, type) in args:
                is_optional = "false"
                if type.startswith("Maybe<"):
                    is_optional = "true"
                forward += """
            let %s = get("%s", &query_, data_, &mut rest, %s)?;""" % (
                    name,
                    name,
                    is_optional,
                )

            forward += """
            routes::%s::layout(req, %s)
        },""" % (
                mod,
                ", ".join(arg[0] for arg in args),
            )

    print("config", REALM_CONFIG)
    if "catchall" in REALM_CONFIG and REALM_CONFIG["catchall"]:
        if "catchall_context" in REALM_CONFIG:
            context_func = REALM_CONFIG["catchall_context"]
        elif "cms_dir" in REALM_CONFIG:
            print("inside cms_dir")
            context_func = 'get_default_context("%s")' % (REALM_CONFIG["cms_dir"])
        else:
            context_func = 'get_default_context("%s")' % ("cms")

        forward += """
        url_ => cms::layout(req, %s, url_),""" % (
            context_func
        )

    forward_file_path: str = "src/forward.rs"
    forward_content = FORWARD_TEMPLATE % (forward,)
    if not test_dir:
        open(forward_file_path, "w").write(forward_content)

    return forward_content


def generate_reverse(
    routes: List[Tuple[str, str, List[Tuple[str, str]]]], test_dir: Optional[str] = None
) -> str:
    reverse: str = ""
    for (url, mod, args) in routes:
        if url == "/":
            function_name = mod
            if mod != "index":
                url = "/" + mod + "/"
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
    let mut url = Url::parse("http://127.0.0.1:3000%s").unwrap();""" % (
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
    reverse_file_path: str = "src/reverse.rs"
    reverse_content = REVERSE_TEMPLATE % (reverse,)
    if not test_dir:
        open(reverse_file_path, "w").write(reverse_content)

    return reverse_content


def parse(mod_path: str) -> List[Tuple[str, str]]:
    """
    Given a module name (file path, relative to ., eg src/acko/utils.rs), this
    function returns:

        List (arg, type)

    """
    with open(mod_path, "r") as f:
        args_str_: Optional[Match[str]] = re.compile(
            r"(?<=pub fn layout\()[^{]*(?=\) ->)"
        ).search(f.read().replace("\n", " "))
        args_str: str = "" if not args_str_ else args_str_[0].replace(" ", "")
        return [
            (r.split(":")[0], r.split(":")[1]) for r in args_str.split(",") if r != ""
        ]


def main() -> None:
    r = get_routes()
    print("r", r)
    generate_reverse(r)
    route_entities = get_route_entities()
    print(route_entities)
    gen_forward_content = generate_forward(directories=route_entities, routes=r)
    print("gen", gen_forward_content)


def test() -> None:
    for test_dir in os.listdir("tests"):
        if test_dir == "temp.rs":
            continue
        print("entered", test_dir)
        test_dir = "tests/" + test_dir
        r = get_routes(test_dir=test_dir)
        for i in r:
            print(i)
        gen_reverse_content = generate_reverse(r, test_dir=test_dir)
        reverse_content = open(test_dir + "/reverse.rs").read()

        assert gen_reverse_content.strip() == reverse_content.strip()
        print(test_dir, " passed reverse")

        route_entities = get_route_entities(test_dir=test_dir)
        gen_forward_content = generate_forward(
            directories=route_entities, routes=r, test_dir=test_dir
        )
        forward_content = open(test_dir + "/forward.rs").read()
        print("gen", gen_forward_content)
        pa.pretty_assert(test_dir, gen_forward_content.strip(), forward_content.strip())
        print(test_dir, " passed forward")


if __name__ == "__main__":
    main()
    # test()
