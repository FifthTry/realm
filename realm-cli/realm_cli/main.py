import sys
import cookiecutter
from cookiecutter.main import cookiecutter
import os
import json

from os.path import expanduser
import re

import realm_cli.compile_elm as ce

home = expanduser("~")

elm_path_G = 'forgit/dwelm/elm_latest/node_modules/elm/bin/elm'
elm_path_G = home + '/' + elm_path_G

elm_format_path_G = 'forgit/dwelm/elm_latest/node_modules/elm-format/bin/elm-format'
elm_format_path_G = home + '/' + elm_format_path_G

go_to_dir_G = home + "/forgit/dwelm/graftpress/"


def compile(source_path, destination_path, elm_path=elm_path_G,
            elm_format_path=elm_format_path_G, go_to_dir=go_to_dir_G):
    if go_to_dir:
        os.chdir(go_to_dir)
    print(os.getcwd(), source_path, destination_path)
    os.system(elm_format_path + " --yes " + source_path)
    os.system(
        elm_path + " make " + source_path + " --output " + destination_path)


def has_main(file):
    with open(file) as f:
        content_st = f.read()
    
    reg_st = r"\s+?main\s*?=\s*?(Browser[.])?((sandbox)|(element))\s*\{.*?\}"
    c = re.compile(reg_st, re.DOTALL)
    search_result = c.search(content_st)
    return (search_result != None)


def compile_all_elm(source_dir, destination_dir, elm_path=elm_path_G,
                    elm_format_path=elm_format_path_G, go_to_dir=go_to_dir_G):
    # handle error
    for file in os.listdir(source_dir):
        print(file)
        source_path = source_dir + '/' + file
        dest_path = destination_dir + '/' + file
        # if file is already present handle
        
        if os.path.isdir(source_path):
            
            if not os.path.isdir(dest_path):
                os.mkdir(dest_path)
            
            compile_all_elm(source_path, dest_path, elm_path, elm_format_path,
                            go_to_dir)
        
        filename, file_extension = os.path.splitext(file)
        if file_extension == '.elm' and has_main(source_path):
            dest_path = destination_dir + '/' + filename + ".js"
            compile(source_path, dest_path, elm_path, elm_format_path,
                    go_to_dir)


loader_script = '''
var getDocumentLayoutOutput = function() {
    var layoutOutput = {};
    var json = document.getElementById("data").text;
    json = json.replace(/&quot;/g, '"').replace(/&amp;/g, "&").replace(/&#x27;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    try {
        layoutOutput = JSON.parse(json).result;
    } catch (e) {}
    return layoutOutput;
};

function load_src(source) {
    var scriptNode = document.createElement("script");
    scriptNode.text = source;
    document.body.appendChild(scriptNode);
}

function get_app(id) {
    var current = Elm;
    mod_list = id.split(".");
    for (x in mod_list) {
        current = current[mod_list[x]];
    }
    return current;
}

function loadWidget(widget) {
    console.log("loadWidget", widget);
    var app = get_app(widget.id).init({
        node: document.getElementById(widget.uid),
        flags: {
            config: widget.config,
            uid: widget.uid
        }
    });
    console.log("widget", app);
    if (app.ports) {
        app.ports.loadWidget.subscribe(loadWidget);
    }
}

function main() {
    var data = getDocumentLayoutOutput();
    console.log(data);
    for (dep in data.deps) {
        console.log(data.deps[dep]);
        load_src(data.deps[dep].source);
    }
    console.log("hello");
    loadWidget({
        uid: "main",
        id: data.widget.id,
        config: data.widget.config
    });
}

main();

'''

def main():
    print(sys.argv)
    if sys.argv[1] == 'startproject':
        project_name = 'hello'
        if len(sys.argv) > 2 and sys.argv[2] != '':
            project_name = sys.argv[2]
            cookiecutter('gh:nilinswap/realm-startapp', extra_context={ "project_name": project_name, "project_slug": project_name}, no_input=True)

        os.chdir(project_name)
        os.system("yarn add package.json") #make exception friendly
        
        curr_dir = os.getcwd()
        print("curr_dir", curr_dir)
        bin_path = os.path.join(curr_dir, "node_modules", ".bin")
        elm_path = os.path.join(bin_path, "elm")
        os.system(elm_path + " install")
        
        
        
    elif sys.argv[1] == 'debug':
        curr_dir = os.getcwd()
        print("curr_dir, ", curr_dir)
        bin_path = os.path.join(curr_dir, "node_modules", ".bin")
        elm_path = os.path.join(bin_path, "elm")
        elm_format_path = os.path.join(bin_path, "elm-format")
        elm_src_dir = "src/frontend"
        elm_dest_dir = "src/static/realm/elatest/"
        
        ce.compile_all_elm(elm_src_dir, elm_dest_dir, elm_path, elm_format_path,
                           "")
        os.system("RUST_BACKTRACE=1 cargo run")
        
        
        
        
        
            
        

# ToDo: make main clean; in fact, read the whole thing for grace.

    
