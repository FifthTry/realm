import os


def pretty_assert(context, st1, st2):

    try:
        assert st1 == st2
    except:
        print("context", context)
        context = context.split("/")[-1]

        open("/tmp/1_" + context, "w").write(st1)
        open("/tmp/2_" + context, "w").write(st2)
        os.system("git diff /tmp/st1 /tmp/st2")
