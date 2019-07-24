import sys
import cookiecutter
from cookiecutter.main import cookiecutter
import os

import realm_cli.compile_elm as ce
import realm_cli.rust_json as rj
import json
from typing import List


VERSION = "0.1.0"


def main():
    if len(sys.argv) == 1:
        print(
            f"""\
Hi, thank you for trying out realm-cli {VERSION} . I hope you like it!

----------------------------------------------------------------------------
I highly recommend walking throught https://www.realmproject.dev to get 
started. It teaches many important concepts, including how to use realm-cli 
in terminal.
----------------------------------------------------------------------------

The most common commonds are:

    realm-cli init <proj_name>
        create a new project realm project.

    realm-cli build
         build the current realm project.

    realm-cli run
         run the current realm project.

Be sure to ask on https://gitter.im/amitu/realm if you run into trouble! Folks
are friendly and happy to help out. They hang out there because it is fun, so
be kind to get best results!
        """
        )
        return

    if sys.argv[1] == "version":
        handle_version()
    elif sys.argv[1] == "init":
        handle_init()
    elif sys.argv[1] == "debug":
        handle_debug()
    elif sys.argv[1] == "build":
        rj.main()
    elif sys.argv[1] == "test":
        rj.test()
    else:
        print(f"unknown command: {sys.argv[1]}")


def handle_version():
    print(VERSION)


def handle_init():
    
    project_name: str = "hello"
    if len(sys.argv) > 2 and sys.argv[2] != "":
        project_name = sys.argv[2]
        cookiecutter(
            "gh:nilinswap/realm-startapp",
            extra_context={"project_name": project_name, "project_slug": project_name},
            no_input=True,
        )

    os.chdir(project_name)
    with open("realm.json", "r") as f:
        config = json.load(f)
    os.system("yarn add package.json")  # make exception friendly

    curr_dir: str = os.getcwd()
    print("curr_dir", curr_dir)
    
   
    if "elm_bin_path" in config:
        curr_dir = config["elm_bin_path"]
    bin_path: str = os.path.join(curr_dir, "node_modules", ".bin")

    elm_path: str = os.path.join(bin_path, "elm")
    
    os.system(elm_path + " make")


def handle_debug():
    with open("realm.json", "r") as f:
        config = json.load(f)
    curr_dir: str = os.getcwd()
    print("curr_dir, ", curr_dir)
    if "elm_bin_path" in config:
        curr_dir = config["elm_bin_path"]
    bin_path: str = os.path.join(curr_dir, "node_modules", ".bin")

    elm_path: str = os.path.join(bin_path, "elm")
   
    elm_format_path: str = os.path.join(bin_path, "elm-format")
    
    elm_dest_dir: str = "src/static/realm/elatest/"
    if "static_dir" in config:
        elm_dest_dir = config["static_dir"] + "/realm/elatest/"
    elm_src_dirs: List[str] = ["src/frontend"]
    
    
    elm_src_dirs: List[str] = config["elm_source_dirs"]

    ce.check_conflicts(elm_src_dirs)
    for src_dir in elm_src_dirs:
        ce.compile_all_elm(src_dir, elm_dest_dir, elm_path, elm_format_path, "")
    os.system("RUST_BACKTRACE=1 cargo run")


# ToDo: make main clean; in fact, read the whole thing for grace.
