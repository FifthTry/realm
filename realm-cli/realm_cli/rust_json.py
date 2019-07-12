import os
from filecmp import cmp
from string import Template
import re

REVERSE_TEMPLATE = """
use realm::utils::{Maybe, url2path};


%s
"""


def get_routes(test_dir = None):
    routes = []
    
    routes_dir_path = "src/routes/"
    if test_dir:
        routes_dir_path = test_dir + "/routes/"
    #print("gr_dir", routes_dir_path)
    for root, _, files in os.walk(routes_dir_path):
        directory = root.replace(routes_dir_path, "")
        for fileName in files:
            if not fileName.endswith(".rs"):
                continue
            # Ignore lib.rs and mod.rs files.
            if fileName == "lib.rs" or fileName == "mod.rs":
                continue
            # Generally file name should be the route name
            # and directory name should be the route path.
            routeName = fileName.replace(".rs", "")
            routePath = directory.replace("/src", "")

            print("routePath:{} routeName:{}".format(routePath, routeName))
            print("filename", fileName)

            if True:
                if routePath == "":
                    path = f"/"
                    module = routeName
                else:
                    path = f"/{routePath}/{routeName}/"
                    module = routePath.replace("/", "::") + "::" + routeName
            print("module", module)
            routes.append((path, module, parse(root + "/" + fileName)[1:]))

    routes.sort(reverse=True)
    return routes


def write_formatted_file(file_path, file_data, test_dir):
    ext = "." + file_path.split(".")[-1]
    temp_file = "/".join(file_path.split("/")[:-1]) + "/temp" + ext
    if test_dir:
        temp_file = "tests/temp.rs"
    open(temp_file, "w+").write(file_data)

    if ext == ".rs":
        os.system("rustfmt %s" % temp_file)
    elif ext == ".elm":
        os.system("elm-format --yes --elm-version=0.19 %s" % temp_file)

    if  test_dir:
        print(temp_file)
        output = open(temp_file).read()
        os.system("rm %s" % temp_file)
        
        return output
    else:
        if cmp(temp_file, file_path):
            os.system("rm %s" % temp_file)
        else:
            os.system("mv %s %s" % (temp_file, file_path))
    
    return ""


def generate_reverse( routes, test_dir= None):
    reverse = ""
    for (url, mod, args) in routes:
        if url == "/":
            function_name = mod
            if mod != "index":
                url = "/"+mod
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
    reverse_file_path = "src/reverse.rs"
    
    return write_formatted_file(reverse_file_path, REVERSE_TEMPLATE % (reverse,), test_dir= test_dir)


def parse(mod_path: str):
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
    print("r", r)
    generate_reverse(r)

def test():
    for dir in os.listdir("tests"):
        if dir == "temp.rs":
            continue
        test_dir = "tests/" + dir
        r = get_routes(test_dir = test_dir)
        #print("tests/" + dir)
        for i in r:
            print(i)
        reverse_content = generate_reverse(r, test_dir = test_dir)
        print("rev", reverse_content)
        gen_reverse_content = open("tests/" + dir + "/reverse.rs").read()
        print(gen_reverse_content)
        assert(gen_reverse_content ==  reverse_content)
        
        print(dir, " passed")

if __name__ == "__main__":
    #main()
    test()


