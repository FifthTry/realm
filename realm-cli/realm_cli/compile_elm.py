import os
from os.path import expanduser
import re

import json

home = expanduser("~")
config = json.loads(open('realm.json').read())


def compile(source_path, destination_path):
	elm_path = 'forgit/dwelm/elm_latest/node_modules/elm/bin/elm'
	elm_path = home + '/' + elm_path
	elm_format_path = 'forgit/dwelm/elm_latest/node_modules/elm-format/bin/elm-format'
	elm_format_path = home + '/' + elm_format_path
	
	os.chdir(home + "/forgit/dwelm/graftpress/")
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


def compile_all_elm(source_dir, destination_dir):
	# handle error
	for file in os.listdir(source_dir):
		print(file)
		source_path = source_dir + '/' + file
		dest_path = destination_dir + '/' + file
		# if file is already present handle
		
		if os.path.isdir(source_path):
			
			if not os.path.isdir(dest_path):
				os.mkdir(dest_path)
			
			compile_all_elm(source_path, dest_path)
		
		filename, file_extension = os.path.splitext(file)
		if file_extension == '.elm' and has_main(source_path):
			dest_path = destination_dir + '/' + filename + ".js"
			compile(source_path, dest_path)


source_dir = 'src/frontend'

if 'elm_source_dir' in config:
	source_dir = config['elm_source_dir']
	print("source ", source_dir)

static_dir = 'src/static'
if 'static_dir' in config:
	static_dir = config['static_dir']
	print("static ", static_dir)
destination_dir = static_dir + "/realm/"
latest_dir = open(destination_dir + "latest.txt").read()
destination_dir = destination_dir + latest_dir

print(compile_all_elm(source_dir, destination_dir))

# make everything exception friendly and neat and involving less of hard coded statements.