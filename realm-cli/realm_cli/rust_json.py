import os
import re
from typing import List, Tuple, Optional, Match

REVERSE_TEMPLATE = """
use realm::utils::{Maybe, url2path};

%s
"""


def get_routes(test_dir: Optional[str] = None) -> List[Tuple[str, str, List[Tuple[str, str]]]]:
    routes: List[Tuple[str, str, List[Tuple[str, str]]]]= []

    routes_dir_path: str = "src/routes/"
    if test_dir:
        routes_dir_path = test_dir + "/routes/"

    for root, _, files in os.walk(routes_dir_path):
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


def generate_reverse(routes: List[Tuple[str, str, List[Tuple[str, str]]]], test_dir: Optional[str] = None) -> str:
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
    if test_dir:
        reverse_file_path = test_dir + "/reverse.rs"
    reverse_content = REVERSE_TEMPLATE % (reverse,)
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


def test() -> None:
    for test_dir in os.listdir("tests"):
        if test_dir == "temp.rs":
            continue
        print("entered", test_dir)
        test_dir = "tests/" + test_dir
        r = get_routes(test_dir=test_dir)
        for i in r:
            print(i)
        reverse_content = generate_reverse(r, test_dir=test_dir)
        print("rev", reverse_content)
        gen_reverse_content = open(test_dir + "/reverse.rs").read()
        print(gen_reverse_content)
        assert gen_reverse_content.strip() == reverse_content.strip()
        print(test_dir, " passed")


if __name__ == "__main__":
    # main()
    test()