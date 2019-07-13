import os
from os.path import expanduser
import re
from typing import Set, List, Optional, Match


home: str = expanduser("~")

elm_path_G: str = "forgit/dwelm/elm_latest/node_modules/elm/bin/elm"
elm_path_G = home + "/" + elm_path_G

elm_format_path_G: str = "forgit/dwelm/elm_latest/node_modules/elm-format/bin/elm-format"
elm_format_path_G = home + "/" + elm_format_path_G

go_to_dir_G: str = home + "/forgit/dwelm/graftpress/"


def compile(
    source_path: str,
    destination_path: str,
    elm_path: str = elm_path_G,
    elm_format_path: str = elm_format_path_G,
    elm_proj_dir: str = go_to_dir_G,
):

    if elm_proj_dir:
        os.chdir(elm_proj_dir)
    print("source dest ", os.getcwd(), source_path, destination_path)
    os.system(elm_format_path + " --yes " + source_path)
    os.system(elm_path + " make " + source_path + " --output " + destination_path)


def has_main(file: str) -> bool:
    with open(file) as f:
        content_st = f.read()

    reg_st = r"\s+?main\s*?=\s*?(Browser[.])?((sandbox)|(element))\s*\{.*?\}"
    c = re.compile(reg_st, re.DOTALL)
    search_result: Optional[Match[str]] = c.search(content_st)
    return search_result != None


def populate_set(bucket: Set[str], source_dir: str, root_path: str):

    for file in os.listdir(os.path.join(source_dir, root_path)):
        root_path = os.path.join(root_path, file)
        new_source_dir: str = os.path.join(source_dir, root_path, file)
        if os.path.isdir(new_source_dir):

            populate_set(bucket, source_dir, root_path)
        else:
            if root_path in bucket:
                raise Exception(
                    "filename- {} is used twice".format(os.path.basename(root_path))
                )
            bucket.add(root_path)


def check_conflicts(source_dirs: List[str]):
    bucket: Set[str] = set([])
    for dir in source_dirs:
        populate_set(bucket, dir, root_path="")


def compile_all_elm(
    source_dir: str,
    destination_dir: str,
    elm_path: str = elm_path_G,
    elm_format_path: str = elm_format_path_G,
    go_to_dir: str = go_to_dir_G,
):

    # handle error
    for file in os.listdir(source_dir):
        print("inside cae ", file)
        source_path: str = source_dir + "/" + file
        dest_path: str = destination_dir + "/" + file
        # if file is already present handle

        if os.path.isdir(source_path):

            print("isdir true for ", source_path)
            if not os.path.isdir(dest_path):
                os.mkdir(dest_path)
            print("dest_path exists? ", os.path.isdir(dest_path))
            compile_all_elm(
                source_path, dest_path, elm_path, elm_format_path, go_to_dir
            )

        filename, file_extension = os.path.splitext(file)

        if file_extension == ".elm" and has_main(source_path):
            dest_path = destination_dir + "/" + filename + ".js"

            compile(source_path, dest_path, elm_path, elm_format_path, go_to_dir)


if __name__ == "__main__":
    source_dir: str = "src/frontend"
    static_dir: str = "src/static"
    destination_dir: str = static_dir + "/realm/"
    latest_dir: str = open(destination_dir + "latest.txt").read()
    destination_dir = destination_dir + latest_dir

    print(compile_all_elm(source_dir, destination_dir))


# make everything exception friendly and neat and involving less of hard coded statements.
