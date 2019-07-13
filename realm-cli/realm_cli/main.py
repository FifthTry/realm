import sys
import cookiecutter
from cookiecutter.main import cookiecutter
import os

import realm_cli.compile_elm as ce
import realm_cli.rust_json as rj
import json
from typing import List


def main():
    print(sys.argv)
    if sys.argv[1] == "startproject":
        project_name: str = "hello"
        if len(sys.argv) > 2 and sys.argv[2] != "":
            project_name = sys.argv[2]
            cookiecutter(
                "gh:nilinswap/realm-startapp",
                extra_context={
                    "project_name": project_name,
                    "project_slug": project_name,
                },
                no_input=True,
            )

        os.chdir(project_name)
        os.system("yarn add package.json")  # make exception friendly

        curr_dir: str = os.getcwd()
        print("curr_dir", curr_dir)
        bin_path: str = os.path.join(curr_dir, "node_modules", ".bin")
        elm_path: str = os.path.join(bin_path, "elm")
        os.system(elm_path + " install")

    elif sys.argv[1] == "debug":
        curr_dir: str = os.getcwd()
        print("curr_dir, ", curr_dir)
        bin_path: str = os.path.join(curr_dir, "node_modules", ".bin")
        elm_path: str = os.path.join(bin_path, "elm")
        elm_format_path: str = os.path.join(bin_path, "elm-format")
        elm_dest_dir: str = "src/static/realm/elatest/"
        elm_src_dirs: List[str] = ["src/frontend"]
        with open("realm.json", "r") as f:
            config = json.load(f)
            elm_src_dirs: List[str] = config["elm_source_dirs"]

        ce.check_conflicts(elm_src_dirs)
        for src_dir in elm_src_dirs:
            ce.compile_all_elm(src_dir, elm_dest_dir, elm_path, elm_format_path, "")
        os.system("RUST_BACKTRACE=1 cargo run")

    elif sys.argv[1] == "build":
        rj.main()


# ToDo: make main clean; in fact, read the whole thing for grace.
