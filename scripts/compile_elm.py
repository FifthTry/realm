import os
import sys
from os.path import expanduser


def compile_elm(source_name, destination_name):
	home = expanduser("~")
	
	source_dir = home + "/forgit/dwelm/realm/examples/dl_elm/src/"
	source_path = source_dir + source_name
	
	elm_path = 'forgit/dwelm/elm_latest/node_modules/elm/bin/elm'
	elm_path = home + '/' + elm_path
	
	destination_dir = home + "/forgit/dwelm/realm/examples/basic/static/realm/elatest/"
	destination_path = destination_dir + destination_name
	os.chdir("../examples/dl_elm/")
	
	print(os.getcwd(), source_path, destination_path)
	
	os.system(
		elm_path + " make " + source_path + " --output " + destination_path)


# run


compile_elm("F/M.elm", "F/M.js")

# compile_elm


# preserve_structure
# pick only