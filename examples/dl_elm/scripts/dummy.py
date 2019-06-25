import re
reg_st = r'"(.*?\n.*?)"'
st = 'first\nsecond"third\n"\n"fourth"fifth\n'
print(reg_st, st)
c = re.compile(reg_st, re.DOTALL)

print(c, c.findall(st), c.match(st))

print("ok")

