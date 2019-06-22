import re

class JsStruct:
	def __init__(self):
		self.identifier_map = {}
		self.platform_export_statement = ''
		self.use_strict_statement = "(function(scope){\n'use strict';"
		self.try_catch_statement = ''

def get_word(st):
	return st.split(' ')[0]

def find_functions(jsFile, st, total_span_left):
	delimiters = r'(function|var|catch|try|console|_Platform_export'
	reg_st = r'\n(?P<content>function\s+(?P<name>\w+)\s*\(.*?\{.*?\})(?=\n\s*' + delimiters + r'))'
	c = re.compile(reg_st, re.DOTALL)
	lis_f =  c.findall(st)
	print("lis_f", lis_f[0])
	for func, name, _ in lis_f:
		total_span_left -= len(func)
		jsFile.identifier_map[name] = func
	return total_span_left

def find_export(jsFile, st, total_span_left):
	reg_st = r'((?<!function )_Platform_export[(].*this[)][)];)'
	c = re.compile(reg_st, re.DOTALL)
	stt = c.search(st).group()
	print("right here", c.search(st).groups())
	jsFile.platform_export_statement = stt
	print("herez", jsFile.platform_export_statement)
	total_span_left -= len(stt)
	return total_span_left


def find_var(jsFile, st, total_span_left):
	delimiters = r'(function|var|catch|try|console|_Platform_export'
	reg_st = r'\n(?P<content>var\s+(?P<name>\S+)\s*=?.*?;)(?=\n\s*' + delimiters + r'))'
	c = re.compile(reg_st, re.DOTALL)
	
	lis_v = c.findall(st)
	print("z", lis_v[0])
	for var, name, _ in lis_v:
		total_span_left -= len(var)
		jsFile.identifier_map[name] = var
	return total_span_left

def remove_comments(st):
	reg_st =  r'(/[*].*?[*]/)|(//.*?\n)'
	return re.sub(reg_st, '', st, flags=re.DOTALL)

def remove_spaces(st):
	reg_st =  r'(\s*\n)'
	c = re.compile(reg_st, re.DOTALL)
	print("bwaha", len(c.findall(st)), len(st) - len(re.sub(reg_st, '', st, flags=re.DOTALL)))
	return re.sub(reg_st, '', st, flags=re.DOTALL)

def find_try_catch(jsFile, st, total_span_left):
	reg_st = r'\n(?P<content>try\s*\{.*?\}\s*catch\s*\(.*?\)\s*\{.*?\}\s*)(?=\n)'
	c = re.compile(reg_st, re.DOTALL)
	jsFile.try_catch_statement = c.search(st).group('content')

	total_span_left -= len(jsFile.try_catch_statement)
	print("try catch", jsFile.try_catch_statement)
	return total_span_left

def find_use_strict(jsFile, st, total_span_left):
	reg_st = r'$((function(scope){\s*\{.*?\}\s*catch\s*\(.*?\)\s*\{.*?\}\s*)(?=\n)'
	c = re.compile(reg_st, re.DOTALL)
	jsFile.try_catch_statement = c.search(st).group('content')

	total_span_left -= len(jsFile.try_catch_statement)
	print("try catch", jsFile.try_catch_statement)
	return total_span_left
	
def parse( file_path ):
	content_st = ""
	with open(file_path) as file:
		content_st = file.read()
	
	total_span_left = len(content_st)
	
	content_st = remove_comments(content_st)
	print("total_span_left then", total_span_left)
	total_span_left = len(content_st)
	print("total_span_left now 1", total_span_left)
	lines = content_st.split('\n')
	print(lines)
	imp_words = [get_word(line) for line in lines if line is not '' and line[0] not in [' ', '\t']]
	print(imp_words)
	print("set ", set(imp_words))
	
	
	jsFile = JsStruct()
	
	name_content_map = {}
	
	total_span_left = find_functions(jsFile, content_st,  total_span_left)
	print("total_span_left now 2", total_span_left)
	
	total_span_left = find_var(jsFile, content_st,  total_span_left)
	
	print("total_span_left now 3", total_span_left)
	
	
	
	
	total_span_left = find_export(jsFile, content_st,  total_span_left)
	print("total_span_left now 4", total_span_left)
	
	total_span_left = find_try_catch(jsFile, content_st,  total_span_left)
	
	total_span_left -= (len(content_st) - len(remove_spaces(content_st)))
	
	
	for k in jsFile.identifier_map:
		print(jsFile.identifier_map[k])
	print(len(content_st), total_span_left)
	
	
	
	
	
if __name__ == '__main__':
	parse("../main.js")



		

# states - function use