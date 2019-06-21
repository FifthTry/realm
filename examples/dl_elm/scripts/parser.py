import re

def get_word(st):
	return st.split(' ')[0]

def find_functions(st):
	
	reg_st = r'\n(function\s+(\w+)\s*\(.*?\{.*?\})(?=\n)'
	c = re.compile(reg_st, re.DOTALL)
	return c.findall(st)

def find_var(st):
	reg_st = '\n(var\s+(\w+)\s*=.*?;)(?=\n)'
	c = re.compile(reg_st, re.DOTALL)
	return c.findall(st)

def parse( file_path ):
	content_st = ""
	with open(file_path) as file:
		content_st = file.read()
	
	lines = content_st.split('\n')
	print(lines)
	imp_words = [get_word(line) for line in lines if line is not '' and line[0] not in [' ', '\t']]
	print(imp_words)
	print("set ", set(imp_words))
	lis_f = find_functions(content_st)
	print()
	print()
	
	print(lis_f[:5])
	print(lis_f[0][0])
	
	lis_v = find_var(content_st)
	print()
	print()
	print(lis_v[:5])
	print(lis_v[0])
	

if __name__ == '__main__':
	parse("../main.js")

# replace comments
# states - function use, function, var, (function use-strict,