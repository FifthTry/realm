import re


class JsStruct:
    def __init__(self):
        self.identifier_map = {}
        self.platform_export_statement = ""
        self.use_strict_statement = "(function(scope){\n'use strict';"
        self.try_catch_statement = ""
        self.console_warn_statements = ""
    
    def diff(self, jsFile):
        diffFile = JsStruct()
        for identifier in self.identifier_map:
            if identifier not in jsFile.identifier_map:
                diffFile.identifier_map[identifier] = self.identifier_map[identifier]
            else:
                if not match(self.identifier_map[identifier], jsFile.identifier_map[identifier]):
                    print("az")
                    print(self.identifier_map[identifier])
                    print("bz")
                    print(jsFile.identifier_map[identifier])
                    print("identifier ambiguity")
                    return None
        
        return diffFile
        
        


def get_word(st):
    return st.split(" ")[0]

def match(st1, st2):
    return st1==st2

def find_functions(jsFile, st, st_left):
    delimiters = r"(function|var|catch|try|console|_Platform_export"
    reg_st = (
        r"\n(?P<content>function\s+(?P<name>\w+)\s*\(.*?\{.*?\})(?=\n+"
        + delimiters
        + r"))"
    )
    c = re.compile(reg_st, re.DOTALL)
    lis_f = c.findall(st)
    print("lis_f", lis_f[0])
    for func, name, _ in lis_f:
        jsFile.identifier_map[name] = func
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_export(jsFile, st, st_left):
    reg_st = r"((?<!function )_Platform_export[(].*this[)][)];)"
    c = re.compile(reg_st, re.DOTALL)
    stt = c.search(st).group()
    print("right here", c.search(st).groups())
    jsFile.platform_export_statement = stt
    print("herez", jsFile.platform_export_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_var(jsFile, st, st_left):
    delimiters = r"(function|var|catch|try|console|_Platform_export"
    reg_st = r"\n(?P<content>var\s+(?P<name>\S+)\s*=?.*?;)(?=\n+" + delimiters + r"))"
    c = re.compile(reg_st, re.DOTALL)

    lis_v = c.findall(st)
    print("z", lis_v[0])
    for var, name, _ in lis_v:
        jsFile.identifier_map[name] = var
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def remove_comments(st):
    reg_st = r"(/[*].*?[*]/)|(//.*?\n)"
    return re.sub(reg_st, "", st, flags=re.DOTALL)


"""def remove_spaces(st):
    reg_st =  r'(\s*\n)'
    c = re.compile(reg_st, re.DOTALL)
    print("bwaha", len(c.findall(st)), len(st) - len(re.sub(reg_st, '', st, flags=re.DOTALL)))
    return re.sub(reg_st, '', st, flags=re.DOTALL)"""


def find_try_catch(jsFile, st, st_left):
    reg_st = r"\n(?P<content>try\s*\{.*?\}\s*catch\s*\(.*?\)\s*\{.*?\}\s*)(?=\n)"
    c = re.compile(reg_st, re.DOTALL)
    jsFile.try_catch_statement = c.search(st).group("content")

    print("try catch", jsFile.try_catch_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_consolewarn_statement(jsFile, st, st_left):
    reg_st = r"\n(?P<content>console\.warn\s*?\(.*?\)\s*?;)(?=\n)"
    c = re.compile(reg_st, re.DOTALL)
    jsFile.console_warn_statement = c.search(st).group("content")
    print("console logp", jsFile.console_warn_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def parse(file_path):
    content_st = ""
    with open(file_path) as file:
        content_st = file.read()

    content_st = remove_comments(content_st)

    lines = content_st.split("\n")
    print(lines)
    imp_words = [
        get_word(line)
        for line in lines
        if line is not "" and line[0] not in [" ", "\t"]
    ]
    print(imp_words)
    print("set ", set(imp_words))

    jsFile = JsStruct()
    st_left = content_st
    st_left = find_functions(jsFile, content_st, st_left)

    st_left = find_var(jsFile, content_st, st_left)

    st_left = find_export(jsFile, content_st, st_left)

    st_left = find_try_catch(jsFile, content_st, st_left)

    # st_left = find_consolewarn_statement(jsFile, content_st, st_left)

    for k in jsFile.identifier_map:
        print(jsFile.identifier_map[k])

    print("st_left ", st_left.strip())

    with open("output.txt", "w") as f:
        f.write(st_left)
    
    return jsFile


if __name__ == "__main__":
    main_js = parse("../l.js")
    m_js = parse("../m.js")
    diff_js = main_js.diff(m_js)
    print(diff_js)
    


# make tolerant
# use hash in match

