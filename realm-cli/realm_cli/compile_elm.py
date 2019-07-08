import os
from os.path import expanduser
import re

import json

home = expanduser("~")

elm_path_G = 'forgit/dwelm/elm_latest/node_modules/elm/bin/elm'
elm_path_G = home + '/' + elm_path_G

elm_format_path_G = 'forgit/dwelm/elm_latest/node_modules/elm-format/bin/elm-format'
elm_format_path_G = home + '/' + elm_format_path_G

go_to_dir_G = home + "/forgit/dwelm/graftpress/"

def compile(source_path, destination_path, elm_path = elm_path_G, elm_format_path = elm_format_path_G, elm_proj_dir = go_to_dir_G  ):
	
	
	if elm_proj_dir:
		os.chdir(elm_proj_dir)
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


def compile_all_elm(source_dir, destination_dir, elm_path = elm_path_G, elm_format_path = elm_format_path_G, go_to_dir = go_to_dir_G  ):
	
	# handle error
	for file in os.listdir(source_dir):
		print(file)
		source_path = source_dir + '/' + file
		dest_path = destination_dir + '/' + file
		# if file is already present handle
		
		if os.path.isdir(source_path):
			
			if not os.path.isdir(dest_path):
				os.mkdir(dest_path)
			
			compile_all_elm(source_path, dest_path, elm_path, elm_format_path, go_to_dir)
		
		filename, file_extension = os.path.splitext(file)
		if file_extension == '.elm' and has_main(source_path):
			dest_path = destination_dir + '/' + filename + ".js"
			compile(source_path, dest_path, elm_path, elm_format_path, go_to_dir)


if __name__ == '__main__':
	source_dir = 'src/frontend'
	static_dir = 'src/static'
	destination_dir = static_dir + "/realm/"
	latest_dir = open(destination_dir + "latest.txt").read()
	destination_dir = destination_dir + latest_dir
	print(compile_all_elm(source_dir, destination_dir))


# make everything exception friendly and neat and involving less of hard coded statements.