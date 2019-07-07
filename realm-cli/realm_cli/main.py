import sys
import cookiecutter
from cookiecutter.main import cookiecutter
import os
import json

def main():
    print(sys.argv)
    if sys.argv[1] == 'startproject':
        project_name = 'hello'
        if len(sys.argv) > 2 and sys.argv[2] != '':
            project_name = sys.argv[2]
            cookiecutter('gh:nilinswap/realm-startapp', extra_context={ "project_name": project_name, "project_slug": project_name}, no_input=True)
        
        
        os.chdir(project_name)
        os.system("npm install") #make exception friendly
        os.system("node_modules/elm/bin/elm install")
        
        elm_config = json.loads(open('elm.json').read())
        elm_config["source-directories"] = ["src/frontend"]
        json.dump(elm_config, open("elm.json", "w"))
        
        
    
