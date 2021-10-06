from typing import List, Union
import hashlib
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
            "sed -i -e '/pyinotify/d' requirements.txt",
        ],
        "file_dep": ["requirements.in", "dodo.py", "realm/dodo.py"],
        "targets": ["requirements.txt"],
    }


def task_wasm():
    return {
        "actions": [
            "cd ftd-rt && wasm-pack build --target web -- --features=wasm,realm",
            "cp ftd-rt/pkg/ftd_rt.js static/",
            "cp ftd-rt/pkg/ftd_rt_bg.wasm static/",
        ],
        "file_dep": (
            ["dodo.py", "realm/dodo.py"]
            + glob2("ftd", r".*\.(rs|toml)", recursive=True)
            + glob2("ftd-rt", r".*\.(rs|toml)", recursive=True)
        ),
        "targets": ["static/ftd_rt.js", "static/ftd_rt_bg.wasm"],
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
    ftd_js = open("static/ftd_rt.js", "rb").read()

    # 1. concat e and r, and compute hash
    hasher = hashlib.sha256()
    hasher.update(e)
    hasher.update(r)  # repeated calls of .update() is okay
    hasher.update(sw)
    hasher.update(ftd_js)
    # TODO: hash other generated files too
    hexdigest = hasher.hexdigest()[:10]

    # 2. get hash from last.txt, if file missing, or different, create new guid
    try:
        last = open("%slast.txt" % (static,), "rt").read().strip()
    except FileNotFoundError:
        last = ""

    if last == hexdigest:
        return

    new = "hashed-" + datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S-") + hexdigest

    os.mkdir(os.path.join(static, new))

    open("%slast.txt" % (static,), "wt").write(hexdigest)
    open("%scurrent.txt" % (static,), "wt").write(new)

    sw_fd = open(f"{static}{new}/sw.js", "wb")
    sw_fd.write(b'var realm_hash = "%s";\n' % (bytes(new, encoding="utf-8"),))
    sw_fd.write(sw)

    ftd_js_fd = open(f"{static}{new}/ftd_rt.js", "wb")
    ftd_js_fd.write(ftd_js)

    content = (
        b'window.realm_hash = "%s";\n' % (bytes(new, encoding="utf-8"),)
        + open("realm/frontend/pre.js", "rb").read()
        + e
        + r
    )

    fd = open(f"{static}{new}/elm.js", "wb")
    fd.write(content)


def elm_with(folder: str, target: str = "static", extra_elms: List[str] = None):
    def spec():
        def is_debug():
            import sys

            args = sys.argv
            if "-d" in args:
                return True
            return False

        basename = folder if folder else "elm"
        prefix = folder + "/" if folder else ""
        static = target if target.endswith("/") else (target + "/")

        realm_deps: List[str] = (
            glob2("realm/frontend/", r".*\.(elm|js)", recursive=True)
            + ["dodo.py"]
            + (extra_elms if extra_elms else [])
            + glob2("elm/", r".*\.(elm|js)", recursive=True)
        )

        yield {
            "actions": ["npm install"],
            "file_dep": ["package.json"],
            "basename": basename,
            "name": "uglifyjs",
            "targets": ["node_modules/.bin/uglifyjs"],
        }

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

        proj_elms: List[str] = (
            glob2("%sfrontend" % (prefix,), r".*\.elm", recursive=True)
            + ["%sfrontend/elm.json" % (prefix,)]
            + glob2("ftd", r".*\.elm", recursive=True)
        )

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
                "   > %stest.js" % (prefix, static),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%stest.js" % (static,)],
            "basename": basename,
            "name": "test",
        }

        yield {
            "actions": [
                "cd ftweb/frontend && elm make RealmTest.elm --output=elm-stuff/t2.js",
                "mkdir -p %s" % (static,),
                "cat "
                "   realm/frontend/pre.js "
                "   ftweb/frontend/elm-stuff/t2.js "
                "   realm/frontend/IframeController.js "
                "   > %srealm-test.js" % (static,),  # TODO: remove ftweb from there
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%srealm-test.js" % (static,)],
            "basename": basename,
            "name": "realm-test",
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
                "   > %sstorybook.js" % (prefix, static),
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
                "   > %siframe.js" % (prefix, static),
            ],
            "file_dep": proj_elms + realm_deps,
            "targets": ["%siframe.js" % (static,)],
            "basename": basename,
            "name": "iframe",
        }
        # elm make src/Main.elm --optimize --output=elm.js
        optimize = "--optimize" if not is_debug() else ""

        elm_cmd = " ".join(
            [
                "cd %sfrontend && elm" % (prefix,),
                "make %s --output=elm-stuff/e2.js" % (optimize,),
            ]
            + main_elms
        )
        uglify_cmd = f"uglifyjs {prefix}frontend/elm-stuff/e2.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output {prefix}frontend/elm-stuff/e.js"

        yield {
            "actions": [
                elm_cmd,
                uglify_cmd,
                "mkdir -p %s" % (static,),
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
TARGETS = [
    "elm",
    "iframe",
    "test",
    "realm-test",
]

# TARGETS = ["elm", "iframe", "test", "storybook", "realm-test"] todo


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
