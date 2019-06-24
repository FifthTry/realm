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
    delimiters = r"(function|var|catch|try|console|_Platform_"
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
    search_result = c.search(st)
    stt=''
    if search_result:
        stt = search_result.group()
    jsFile.platform_export_statement = stt
    print("herez", jsFile.platform_export_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_var(jsFile, st, st_left):
    delimiters = r"(function|var|catch|try|console|_Platform_"
    reg_st = r"\n(?P<content>var\s+(?P<name>\S+)\s*=?.*?;)(?=\n+" + delimiters + r"))"
    c = re.compile(reg_st, re.DOTALL)

    lis_v = c.findall(st)
    for var, name, _ in lis_v:
        jsFile.identifier_map[name] = var
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_identifier(jsFile, st, st_left):
    delimiters = r"(function|var|catch|try|console|_Platform_"
    reg_st_fun = (
        r"\n(?P<contentFun>function\s+(?P<nameFun>\w+)\s*\(.*?\{.*?\})(?=\n+"
        + delimiters
        + r"))"
    )

    reg_st_var = r"\n(?P<contentVar>var\s+(?P<nameVar>\S+)\s*=?.*?;)(?=\n+" + delimiters + r"))"
    reg_st = reg_st_fun + '|' + reg_st_var
    c = re.compile(reg_st, re.DOTALL)
    lis_f = c.findall(st)
    print("lis_f", lis_f[0])
    for func, nameFun, _, var, nameVar, _ in lis_f:
        if func:
            jsFile.identifier_map[nameFun] = func
        elif var:
            jsFile.identifier_map[nameVar] = var
        else:
            pass
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
    search_result = c.search(st)
    if search_result:
        jsFile.try_catch_statement = search_result.group("content")
    print("try catch", jsFile.try_catch_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def find_consolewarn_statement(jsFile, st, st_left):
    reg_st = r"\n(?P<content>console\.warn\s*?\(.*?\)\s*?;)(?=\n)"
    c = re.compile(reg_st, re.DOTALL)
    search_result = c.search(st)
    if search_result:
        jsFile.console_warn_statement = search_result.group("content")
    print("console logp", jsFile.console_warn_statement)
    return re.sub(reg_st, "", st_left, flags=re.DOTALL)


def parse(content_st):
    

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
    #st_left = find_functions(jsFile, content_st, st_left)

    #st_left = find_var(jsFile, content_st, st_left)
    st_left = find_identifier(jsFile, content_st, st_left)
    st_left = find_export(jsFile, content_st, st_left)

    st_left = find_try_catch(jsFile, content_st, st_left)

    # st_left = find_consolewarn_statement(jsFile, content_st, st_left)
    order_lis = []
    for k in jsFile.identifier_map:
        order_lis.append(k)
        print(jsFile.identifier_map[k])

    print("st_left ", st_left.strip(), order_lis)
    print("mapH", jsFile.identifier_map)

    with open("output.txt", "w") as f:
        f.write(st_left)
    
    return jsFile

if __name__ == "__main__":
    '''
    file_path = "../l.js"
    with open(file_path) as file:
        content_st = file.read()
    main_js = parse(content_st)
    m_js = parse("../m.js")
    diff_js = main_js.diff(m_js)
    for k in diff_js.identifier_map:
        print(diff_js.identifier_map[k])'''
    pass
    

# make tolerant
# use hash in match

