#!/usr/bin/env python3
"""Make a finished VMF smaller without changing what compiles (the owner, 23 November: "this map is 48.9 MB ... is there
any other way to optimize the size"). Takes out every side's vertices_plus block: Hammer++'s own copy of each face's
corners, written beside the planes that define it. vbsp never reads it, and Hammer++ works the corners out again from the
planes when it opens the file (every plane here has whole-number points). About a third of a generated map's bytes.
Run it last: map_view, map_lint and map_hidden_faces read the corners from those blocks.

    python3 map_slim.py IN.vmf [OUT.vmf]        (OUT defaults to IN, rewritten in place)
"""
import re
import sys

VP = re.compile(r'\t*vertices_plus\n\t*\{\n(?:\t*"v" "[^"]*"\n)+\t*\}\n')


def slim(text):
    return VP.sub("", text)


def main():
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else src
    text = open(src, errors="replace").read()
    thin = slim(text)
    with open(out, "w") as fh:
        fh.write(thin)
    print("%s: %.1f MB -> %.1f MB" % (out, len(text) / 1e6, len(thin) / 1e6))


if __name__ == "__main__":
    main()
