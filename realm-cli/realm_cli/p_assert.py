import os


def pretty_assert(context, dir,  st1, st2):

    try:
        assert st1 == st2
    except:
        print("context", dir)
        dir = dir.split("/")[-1]

        open("/tmp/"+ context+ "_gen_" + dir, "w").write(st1)
        open("/tmp/"+ context+ "_tar_" + dir, "w").write(st2)
        os.system("git diff "+ "/tmp/"+ context+ "_gen_" + dir + " /tmp/"+ context+ "_tar_" + dir)
