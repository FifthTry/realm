import sys
import cookiecutter
from cookiecutter.main import cookiecutter
import os

import realm_cli.compile_elm as ce


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

    
