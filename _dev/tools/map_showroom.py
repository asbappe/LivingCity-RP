#!/usr/bin/env python3
"""
Living City: lay every canal module out as test maps (run it after adding modules)

    python3 map_showroom.py                 writes map_layouts/showroom_1.txt, _2.txt ...: every module once, ten to a map
    python3 map_showroom.py --per 8         ...eight to a map
    python3 map_build.py chain --layout map_layouts/showroom_1.txt --test      then builds one to compile and walk

Each map is rows of modules joined by turns, like a ploughed field. The tool measures how far each module's side
rooms reach to either side and sets the rows far enough apart for the widest. The owner: "Build them on a test
map and we can fit them into the map after."
"""

import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import map_modules as mm

SKIP = ("straight", "jog", "tee", "shed", "tunnel", "widen", "narrow", "wide", "widetee", "basin", "lockgate",     # (the canal itself; the wide canal goes in map_layouts/wide.txt)
        "roadend")      # (built for one place, the west road's end; the canal ring now meets that road with its street instead)
ROW = 6200      # about how long a row may be


def reach(name):
    """How far a module's squares reach to the left and to the right of the canal's middle."""
    class A:
        first_node, test = 6000, False
    lay = {"name": "measure", "start": (0, 0), "heading": "E", "rim": 784, "end": None, "modules": [[name]]}
    b, seed, spawn, end = mm.build_chain(lay, A)
    b.plan.walls()
    ys = [j * mm.CELL for (i, j) in b.plan.cells]
    return max(ys) + mm.CELL, -min(ys)


def write(path, names, reaches, title):
    rows, row, length = [], [], 0
    for n in names:
        if row and length + mm.MODULES[n][0] > ROW:
            rows.append(row)
            row, length = [], 0
        row.append(n)
        length += mm.MODULES[n][0]
    if row:
        rows.append(row)
    out = ["# %s" % title, "# Made by map_showroom.py: run it again rather than editing this.",
           "#   python3 map_build.py chain --layout map_layouts/%s --test" % os.path.basename(path), "",
           "start -3072 -4096", "heading E", "rim 784", ""]
    for k, row in enumerate(rows):
        east = k % 2 == 0
        for n in row:
            out.append(n)
        if k + 1 < len(rows):
            # the side of this row that faces the next (north), and the side of the next that faces back
            mine = max(reaches[n][0 if east else 1] for n in row)
            theirs = max(reaches[n][0 if east else 1] for n in rows[k + 1])      # (the next row heads the other way, so its same-named side faces back)
            gap = max(0, mine + theirs + 192 - 512)
            gap = (gap + 63) // 64 * 64
            turn = "left" if east else "right"
            out += ["", turn] + (["straight %d" % gap] if gap else []) + [turn, ""]
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    return len(rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--per", type=int, default=10, help="how many modules to a map")
    args = ap.parse_args()
    import map_corridor
    up = [n for n in mm.MODULES if n in map_corridor.STREET_MODULES]
    names = [n for n in mm.MODULES if n not in SKIP and n not in up]
    reaches = {n: reach(n) for n in names}
    folder = os.path.join(HERE, "map_layouts")
    for old in os.listdir(folder):
        if old.startswith("showroom") or old.startswith("street_"):
            os.remove(os.path.join(folder, old))
    # the modules that belong on the street: one straight run to a map, a shed at each end for the train, five lifted between
    for k in range(0, len(up), 5):
        part = up[k:k + 5]
        path = os.path.join(folder, "street_%d.txt" % (k // 5 + 1))
        with open(path, "w") as f:
            f.write("# Street test map %d: %s\n# Made by map_showroom.py: run it again rather than editing this.\n" % (k // 5 + 1, ", ".join(part)))
            f.write("#   python3 map_build.py chain --layout map_layouts/%s --test\n# The street (a railway and a road) runs along the left bank; a train runs between the two sheds.\n\n" % os.path.basename(path))
            f.write("start -6400 0\nheading E\nrim 784\nupper left\ncars 2\n\nshed\n" + "".join("%s %s\n" % (n, map_corridor.STREET_MODULES[n]) for n in part) + "shed\n")
        print("%s: %d modules on the street" % (os.path.basename(path), len(part)))
    for k in range(0, len(names), args.per):
        part = names[k:k + args.per]
        path = os.path.join(folder, "showroom_%d.txt" % (k // args.per + 1))
        rows = write(path, part, reaches, "Test map %d: %s" % (k // args.per + 1, ", ".join(part)))
        print("%s: %d modules in %d rows" % (os.path.basename(path), len(part), rows))


if __name__ == "__main__":
    main()
