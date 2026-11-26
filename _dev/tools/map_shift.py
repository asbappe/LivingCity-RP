#!/usr/bin/env python3
"""
map_shift.py: a whole VMF moved by a whole number of units

    python3 map_shift.py IN.vmf OUT.vmf DX DY [DZ]

The owner, 26 November: "please stitch in the forest bunker to the ring now ... though can we please make it down a
longer tunnel and not put it RIGHT there". The bunker forest was built with its west gate at the first canal's east
gate; with the tunnel between them (map_layouts/bunker_way.txt) it stands 3520 farther east. Its builder is written
for its first place (the silo and the rooms round it are set by the map's own coordinates), and the owner's own copy of
the forest is edited in Hammer, so neither can simply be built again somewhere else: this moves the finished file.

    python3 map_shift.py lc_forest_bunker.vmf lc_forest_bunker_east.vmf 3520 0

What moves: every brush (its planes, and Hammer's own corner lists), every displacement's start, every entity's
origin, and the keys that hold a place in the map (a ladder's ends, a constraint's ends, a hinge's or motor's axis, an
overlay's middle). Textures stay where they were on their faces (each axis's shift is corrected for the move: Hammer's
texture lock). A sky_camera moves by (1 - 1/scale) of the way: the 3D sky's pieces move with everything else, and the
camera must then stand so that they are seen where they were, seen from the moved map.

What does not: ids, names, angles, sizes, outputs, the order of anything. The file has the same number of lines after
as before. Never writes over its input.

It ends by reading both files back: the same number of lines, of brushes, of entities, and the box of all the brushes
moved by exactly the amount asked.
"""
import re
import sys

SPOT_KEYS = ("origin", "point0", "point1", "springaxis", "attachpoint", "position2", "lowerleft", "lowerright", "upperleft", "upperright", "basisorigin")
PAIR_KEYS = ("hingeaxis", "slideaxis", "axis")      # ("x y z, x y z": two places)
NUM = r"-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
TRIPLE = re.compile(r"\(\s*(%s)\s+(%s)\s+(%s)\s*\)" % (NUM, NUM, NUM))
KEY = re.compile(r'^(\s*)"([^"]+)" "([^"]*)"\s*$')
AXIS = re.compile(r"^\[\s*(%s)\s+(%s)\s+(%s)\s+(%s)\s*\]\s+(%s)\s*$" % (NUM, NUM, NUM, NUM, NUM))


def fmt(x):
    if abs(x - round(x)) < 1e-7:
        return str(int(round(x)))
    return ("%.6f" % x).rstrip("0").rstrip(".")


def moved(text, d):
    """"x y z" moved by d, or None when it is not three numbers."""
    p = text.split()
    if len(p) != 3:
        return None
    try:
        return " ".join(fmt(float(a) + b) for a, b in zip(p, d))
    except ValueError:
        return None


def shift(lines, d):
    out = list(lines)
    stack = []
    ent = None       # [classname, scale, [(line index, key, value)]] of the entity being read
    pending = None
    for i, raw in enumerate(lines):
        line = raw.strip()
        if line == "{":
            stack.append(pending or "")
            if pending == "entity" and len(stack) == 1:
                ent = [None, 16.0, []]
            pending = None
            continue
        if line == "}":
            name = stack.pop() if stack else ""
            if name == "entity" and not stack and ent:
                for j, key, val in ent[2]:
                    dd = d
                    if ent[0] == "sky_camera" and key == "origin":
                        dd = tuple(c * (1.0 - 1.0 / (ent[1] or 16.0)) for c in d)
                    if key in PAIR_KEYS:
                        parts = [moved(q.strip(), dd) for q in val.split(",")]
                        new = ", ".join(parts) if len(parts) == 2 and all(parts) else None
                    else:
                        new = moved(val, dd)
                    if new is not None:
                        m = KEY.match(lines[j].rstrip("\n"))
                        out[j] = '%s"%s" "%s"\n' % (m.group(1), m.group(2), new)
                ent = None
            continue
        m = KEY.match(raw.rstrip("\n"))
        if not m:
            pending = line
            continue
        ind, key, val = m.group(1), m.group(2), m.group(3)
        low = key.lower()
        top = stack[-1] if stack else ""
        if low == "plane" and top == "side":
            new = TRIPLE.sub(lambda q: "(%s %s %s)" % tuple(fmt(float(q.group(k + 1)) + d[k]) for k in range(3)), val)
            out[i] = '%s"%s" "%s"\n' % (ind, key, new)
        elif low in ("uaxis", "vaxis") and top == "side":
            a = AXIS.match(val)
            if a:
                ax = [float(a.group(k)) for k in (1, 2, 3)]
                off, scale = float(a.group(4)), float(a.group(5))
                if scale:
                    off -= (ax[0] * d[0] + ax[1] * d[1] + ax[2] * d[2]) / scale
                out[i] = '%s"%s" "[%s %s %s %s] %s"\n' % (ind, key, a.group(1), a.group(2), a.group(3), fmt(off), a.group(5))
        elif low == "v" and top == "vertices_plus":
            new = moved(val, d)
            if new is not None:
                out[i] = '%s"%s" "%s"\n' % (ind, key, new)
        elif low == "startposition" and top == "dispinfo":
            q = val.strip().strip("[]")
            new = moved(q, d)
            if new is not None:
                out[i] = '%s"%s" "[%s]"\n' % (ind, key, new)
        elif ent is not None and len(stack) == 1:
            if low == "classname":
                ent[0] = val.lower()
            elif low == "scale":
                try:
                    ent[1] = float(val)
                except ValueError:
                    pass
            if low in SPOT_KEYS or low in PAIR_KEYS:
                ent[2].append((i, low, val))
    return out


def facts(lines):
    """(lines, brushes, entities, the box of every plane point) of a VMF's lines."""
    lo, hi = [1e30] * 3, [-1e30] * 3
    solids = ents = 0
    for raw in lines:
        s = raw.strip()
        if s == "solid":
            solids += 1
        elif s == "entity":
            ents += 1
        elif s.startswith('"plane"'):
            for q in TRIPLE.finditer(s):
                for k in range(3):
                    x = float(q.group(k + 1))
                    lo[k], hi[k] = min(lo[k], x), max(hi[k], x)
    return len(lines), solids, ents, lo, hi


def main(argv):
    if len(argv) not in (5, 6):
        print(__doc__)
        return 2
    src, dst = argv[1], argv[2]
    d = (int(argv[3]), int(argv[4]), int(argv[5]) if len(argv) == 6 else 0)
    if src == dst:
        print("never over its input: give another name for the moved file")
        return 2
    with open(src, errors="surrogateescape", newline="") as f:
        lines = f.readlines()
    out = shift(lines, d)
    with open(dst, "w", errors="surrogateescape", newline="") as f:
        f.writelines(out)
    a, b = facts(lines), facts(out)
    ok = a[:3] == b[:3] and all(abs(b[3][k] - a[3][k] - d[k]) < 1e-3 and abs(b[4][k] - a[4][k] - d[k]) < 1e-3 for k in range(3))
    print("%s: %d lines, %d brushes, %d entities; its brushes fill x %s to %s, y %s to %s, z %s to %s" % (
        (dst, b[0], b[1], b[2]) + tuple(fmt(v) for k in range(3) for v in (b[3][k], b[4][k]))))
    print("SHIFT PASS: moved by %d %d %d" % d if ok else "SHIFT FAIL: the moved file does not match the first one moved by %d %d %d" % d)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
