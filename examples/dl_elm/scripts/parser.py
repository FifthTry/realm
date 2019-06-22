import re

class JsStruct:
	def __init__(self):
		self.identifier_map = {}
		self.platform_export_statement = ''
		self.use_strict_statement = ''
		self.try_catch_statement = ''

def get_word(st):
	return st.split(' ')[0]

def find_functions(st, map, total_span_left):
	delimiters = r'(function|var|catch|try|console|_Platform_export'
	reg_st = r'\n(?P<content>function\s+(?P<name>\w+)\s*\(.*?\{.*?\})(?=\n\s*' + delimiters + r'))'
	c = re.compile(reg_st, re.DOTALL)
	lis_f =  c.findall(st)
	print("lis_f", lis_f[0])
	for func, name, _ in lis_f:
		total_span_left -= len(func)
		map[name] = func
	return total_span_left

def find_export(st, map, total_span_left):
	reg_st = r'((?<!function )_Platform_export[(].*this[)][)];)'
	c = re.compile(reg_st, re.DOTALL)
	stt = c.search(st).group()
	print("right here", c.search(st).groups())
	map['_Platform_export call'] = stt
	print("herez", map['_Platform_export call'])
	total_span_left -= len(stt)
	return total_span_left


def find_var(st, map, total_span_left):
	delimiters = r'(function|var|catch|try|console|_Platform_export'
	reg_st = r'\n(?P<content>var\s+(?P<name>\S+)\s*=?.*?;)(?=\n\s*' + delimiters + r'))'
	c = re.compile(reg_st, re.DOTALL)
	
	lis_v = c.findall(st)
	print("z", lis_v[0])
	for var, name, _ in lis_v:
		total_span_left -= len(var)
		map[name] = var
	return total_span_left

def remove_comments(st):
	reg_st =  r'(/[*].*?[*]/)|(//.*?\n)'
	return re.sub(reg_st, '', st, flags=re.DOTALL)

def remove_spaces(st):
	reg_st =  r'(\s*\n)'
	c = re.compile(reg_st, re.DOTALL)
	print("bwaha", len(c.findall(st)), len(st) - len(re.sub(reg_st, '', st, flags=re.DOTALL)))
	
	return re.sub(reg_st, '', st, flags=re.DOTALL)

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
	
	total_span_left = find_functions(content_st, name_content_map, total_span_left)
	print("total_span_left now 2", total_span_left)
	
	total_span_left = find_var(content_st, name_content_map, total_span_left)
	
	print("total_span_left now 3", total_span_left)
	
	
	
	
	total_span_left = find_export(content_st, name_content_map, total_span_left)
	print("total_span_left now 4", total_span_left)
	
	#total_span_left = find
	
	total_span_left -= (len(content_st) - len(remove_spaces(content_st)))
	
	
	for k in name_content_map:
		print(name_content_map[k])
	print(len(content_st), total_span_left)
	
	
	
	
if __name__ == '__main__':
	parse("../main.js")



		

# states - function use, function, var, (function use-strict, try, catch