from typing import List, Union
import hashlib
import gzip
import brotli
import os
import re
import datetime

IGNORED: List[str] = ["node_modules", "elm-stuff", "builds", "tests"]


def task_pip():
    return {
        "actions": [
            "pip-compile --output-file=requirements.txt requirements.in",
            "pip-sync",
            "sed -i -e '/macfsevents/d' requirements.txt",
        ],
        "file_dep": ["requirements.in", "dodo.py"],
        "targets": ["requirements.txt"],
    }


def _create_index(prefix: str, static: str):
    hexdiget = open("%scurrent.txt" % (static,), "rt").read()
    open("%sindex.html" % (prefix,), "w").write(
        open("%sindex.template.html" % (prefix,)).read().replace("__hash__", hexdiget)
    )


def _merge_files_update_latest(e: str, r: str, static: str):
    print("_merge_files_update_latest")
    e = open(e, "rb").read()
    r = open(r, "rb").read()
    sw = open("realm/frontend/sw.js", "rb").read()

    # 1. concat e and r, and compute hash
    hasher = hashlib.sha256()
    hasher.update(e)
    hasher.update(r)  # repeated calls of .update() is okay
    hasher.update(sw)
    # TODO: hash other generated files too
    hexdiget = hasher.hexdigest()[:10]

    # 2. get hash from last.txt, if file missing, or different, create new guid
    try:
        last = open("%slast.txt" % (static,), "rt").read().strip()
    except FileNotFoundError:
        last = ""

    if last == hexdiget:
        return

    new = "hashed-" + datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S-") + hexdiget
    open("%slast.txt" % (static,), "wt").write(hexdiget)
    open("%scurrent.txt" % (static,), "wt").write(new)

    sw_fd = open("%ssw.%s.js" % (static, new), "wb")
    sw_fd.write(b'var realm_hash = "%s";\n' % (bytes(new, encoding="utf-8"),))
    sw_fd.write(sw)

    content = (
        b'window.realm_hash = "%s";\n' % (bytes(new, encoding="utf-8"),)
        + open("realm/frontend/pre.js", "rb").read()
        + e
        + r
    )

    fd = open("%selm.%s.js" % (static, new), "wb")
    fd.write(content)

    gzip.open("%selm.%s.js.gz" % (static, new), "wb").write(content)
    open("%selm.%s.js.br" % (static, new), "wb").write(
        brotli.compress(content, mode=brotli.MODE_TEXT, quality=11, lgwin=22)
    )


def elm_with(folder: str, target: str = "static", extra_elms: List[str] = None):
    def spec():
        basename = folder if folder else "elm"
        prefix = folder + "/" if folder else ""
        static = target if target.endswith("/") else (target + "/")

        realm_deps: List[str] = (
            glob2("realm/frontend/", r".*\.(elm|js)", recursive=True)
            + ["dodo.py"]
            + (extra_elms if extra_elms else [])
        )

        yield {
            "actions": [lambda: _create_index(prefix, static)],
            "file_dep": [
                "dodo.py",
                "%scurrent.txt" % static,
                "%sindex.template.html" % (prefix,),
            ],
            "targets": ["%sindex.html" % (prefix,)],
            "basename": basename,
            "name": "index",
        }

        proj_elms: List[str] = glob2(
            "%sfrontend" % (prefix,), r".*\.elm", recursive=True
        ) + ["%sfrontend/elm.json" % (prefix,)]
        main_elms: List[str] = [
            e.replace("%sfrontend/" % (prefix,), "")
            for e in proj_elms
            if "Pages/" in e and "Test.elm" not in e
        ]
        test_elms: List[str] = [
            e.replace("%sfrontend/" % (prefix,), "") for e in proj_elms if "Pages/" in e
        ]

        yield {
            "actions": [
                "cd %sfrontend && elm make Test.elm --output=elm-stuff/t.js"
                % (prefix,),
                "mkdir -p %s" % (static,),
                "cat "
                "   realm/frontend/pre.js "
                "   %sfrontend/elm-stuff/t.js "
                "   realm/frontend/IframeController.js "
                "   > %stest.js"
                % (prefix, static),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%stest.js" % (static,)],
            "basename": basename,
            "name": "test",
        }

        yield {
            "actions": [
                "cd %sfrontend && elm make Storybook.elm  --output=elm-stuff/s.js"
                % (prefix,),
                "mkdir -p %s" % (static,),
                "cat "
                "   realm/frontend/pre.js "
                "   %sfrontend/elm-stuff/s.js "
                "   realm/frontend/IframeController.js "
                "   > %sstorybook.js"
                % (prefix, static),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%sstorybook.js" % (static,)],
            "basename": basename,
            "name": "storybook",
        }

        elm_cmd = " ".join(
            ["cd %sfrontend && elm" % (prefix,), "make", "--output=elm-stuff/i.js"]
            + test_elms
        )
        yield {
            "actions": [
                elm_cmd,
                "mkdir -p %s" % (static,),
                "cat "
                "   realm/frontend/pre.js "
                "   %sfrontend/elm-stuff/i.js "
                "   realm/frontend/Realm.js "
                "   > %siframe.js"
                % (prefix, static),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%siframe.js" % (static,)],
            "basename": basename,
            "name": "iframe",
        }

        elm_cmd = " ".join(
            ["cd %sfrontend && elm" % (prefix,), "make", "--output=elm-stuff/e.js"]
            + main_elms
        )

        yield {
            "actions": [
                elm_cmd,
                # uglify_cmd,
                "mkdir -p %s" % (static,),
                "sh realm/delete_old_builds.sh",
                lambda: _merge_files_update_latest(
                    "%sfrontend/elm-stuff/e.js" % (prefix,),
                    "realm/frontend/Realm.js",
                    static,
                ),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%scurrent.txt" % (static,)],
            "basename": basename,
            "name": "main",
        }

    return spec


task_elm = elm_with("")


MAIN_ELM = re.compile(r"\Wmain\W")
TARGETS = ["elm", "iframe", "test", "storybook"]


def glob2(
    path: str,
    patterns: str,
    blacklist: Union[str, List[str]] = None,
    recursive: bool = False,
    links: bool = True,
) -> List[str]:
    if blacklist is None:
        blacklist = IGNORED

    ls = os.listdir(path)
    ls = [os.path.join(path, f1) for f1 in ls]

    if blacklist:
        if type(blacklist) is str:
            blacklist = [blacklist]
        ls = [e for e in ls if not any(re.search(p, e) for p in blacklist)]

    if type(patterns) is str:
        patterns = [patterns]

    files = [
        e
        for e in ls
        if os.path.isfile(e) and any(re.search(patt, e) for patt in patterns)
    ]

    if recursive:
        dirs = [e for e in ls if os.path.isdir(e) and (links or not os.path.islink(e))]
        for d in dirs:
            files.extend(glob2(d, patterns, blacklist, recursive, links))

    return files
