#!/usr/bin/env python3
"""The Valve pieces gallery (23 November, after the owner said yes to every set piece on the list): one test map with
every lifted Valve piece that says how it is started (the key "trigger" in its JSON), each placed with all its logic on
a sealed yard under the sky, and in front of each a post with one tinted button per trigger, so every piece can be run
and judged in one compile.

    python3 map_valve_gallery.py                    every piece with a "trigger" key; writes lc_valve_gallery.vmf
    python3 map_valve_gallery.py NAME NAME ...      only those pieces

Each piece stands with its anchor's height at the yard's level, in a hole cut in the yard to its own footprint, so its
floors and pits stay as they are (the hole's bottom is under the lowest piece); a piece with no brushes (a camera, a
dropship's route) is raised until its lowest thing stands just over the yard, with no hole. Its brushes go in as detail and its
areaportals stay out: the gallery is one open yard, sealed by its own hull round everything placed. Buttons go left to
right in the order of the piece's "trigger" list; the spawn is behind every piece. The checks: sealed with every entity inside, assets (map_assets.py).
Pieces that need their surroundings (a street to drive on, sky to fly through) are only as complete as their box.
"""

import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import map_prefab
from map_build import MAT, check, test_extras
from map_modules import Build, Frame, Mod

ROW = 7000          # (how wide a row of pieces may run before the next row starts)
GAP = 512           # (between pieces, and in front of each for its buttons)
COLOURS = ("255 64 64", "255 176 32", "64 255 96", "64 160 255", "220 96 255", "255 255 255")


def pieces(names):
    lib = map_prefab.LIB
    out = []
    for f in sorted(os.listdir(lib)):
        if f.startswith("valve_") and f.endswith(".json") and (not names or f[:-5] in names):
            pf = map_prefab.load(f[:-5])
            if "trigger" in pf or names:
                out.append(pf)
    return out


def rel_box(pf):
    b, a = pf["box"], pf["anchor"]
    return [b[0] - a[0], b[1] - a[1], b[2] - a[2], b[3] - a[0], b[4] - a[1], b[5] - a[2]]


def ground(vmf, outer, holes, base, vis):
    """The yard from base to 0 over the outer rectangle, less the holes: cut into bands at every hole's edge."""
    x1, y1, x2, y2 = outer
    xs = sorted({x1, x2} | {h[0] for h in holes} | {h[2] for h in holes})
    ys = sorted({y1, y2} | {h[1] for h in holes} | {h[3] for h in holes})
    n = 0
    for j in range(len(ys) - 1):
        run = None
        for i in range(len(xs) - 1):
            cx, cy = (xs[i] + xs[i + 1]) / 2.0, (ys[j] + ys[j + 1]) / 2.0
            solid = not any(h[0] <= cx <= h[2] and h[1] <= cy <= h[3] for h in holes)
            if solid and run is None:
                run = xs[i]
            if (not solid or i == len(xs) - 2) and run is not None:
                end = xs[i + 1] if solid else xs[i]
                if end > run:
                    vmf.world_box((run, ys[j], base, end, ys[j + 1], 0), MAT["nodraw"], top=MAT["quay_floor"], vis=vis)
                    n += 1
                run = None
    return n


def build(out, names):
    b = Build("valve_gallery", 784, 1)
    b.test = True
    m = Mod(b, Frame(0, 0, 0, 64), "gallery")
    vmf, vis = b.vmf, b.vis + ": gallery yard"
    holes, buttons, placed = [], 0, []
    cx, cy, row_depth = 0, 0, 0
    for pf in pieces(names):
        rb = rel_box(pf)
        sx, sy = int(rb[3] - rb[0]) + 1, int(rb[4] - rb[1]) + 1
        if cx and cx + sx > ROW:
            cx, cy, row_depth = 0, cy + row_depth + GAP * 2, 0
        u, v = cx - rb[0], cy + GAP - rb[1]
        ents = [e for e in pf.get("wiring", []) + pf.get("points", []) if "origin" in e]
        z = 0 if pf["solids"] or not ents else 8 - min(e["origin"][2] for e in ents)      # (no brushes: its lowest thing just over the yard)
        tag = map_prefab.place(m, pf, int(round(u)), int(round(v)), int(round(z)), 0)["placed_as"]
        if pf["solids"]:
            holes.append((cx, cy + GAP, cx + sx, cy + GAP + sy))
        for k, t in enumerate(pf.get("trigger", [])):
            x, y = cx + 32 + 48 * k, cy + GAP - 160
            vmf.world_box((x, y, 0, x + 16, y + 16, 64), "concrete/concretewall036a", vis=vis)
            vmf.brush_entity("func_button", {"spawnflags": "1025", "wait": "2", "rendercolor": COLOURS[k % len(COLOURS)], "sounds": "14"},
                             [(x, y - 2, 40, x + 16, y, 56)], "metal/metalwall014a", vis,
                             connections=[("OnPressed", t["name"] + tag, t.get("input", "Trigger"), t.get("value", ""), 0)])
            buttons += 1
        placed.append((pf["name"], len(pf.get("trigger", []))))
        cx += sx + GAP
        row_depth = max(row_depth, sy)
    # The hull round everything placed (its path points and sky entities too), the yard under it.
    pts = [p for _, p in vmf.points] + [c for bx, _ in vmf.boxes for c in (bx[:3], bx[3:])]
    lo = [min(p[k] for p in pts) for k in range(3)]
    hi = [max(p[k] for p in pts) for k in range(3)]
    x1, y1, x2, y2 = int(lo[0]) - 512, int(lo[1]) - 768, int(hi[0]) + 512, int(hi[1]) + 512
    base = min(-64, int(lo[2]) - 64)
    top = max(1024, int(hi[2]) + 256)
    n = ground(vmf, (x1, y1, x2, y2), holes, base, vis)
    sky = MAT["sky"]
    vmf.world_box((x1 - 16, y1 - 16, base - 16, x2 + 16, y2 + 16, base), MAT["nodraw"], vis=vis)
    for bx in ((x1 - 16, y1 - 16, base, x1, y2 + 16, top + 16), (x2, y1 - 16, base, x2 + 16, y2 + 16, top + 16),
               (x1, y1 - 16, base, x2, y1, top + 16), (x1, y2, base, x2, y2 + 16, top + 16), (x1, y1, top, x2, y2, top + 16)):
        vmf.world_box(bx, sky, top=sky, bottom=sky, vis=vis)
    spawn = (x1 + 256, y2 - 256, 8)      # (behind every piece, at the far west: the autogun's guns face the other way)
    test_extras(vmf, spawn, 270, vis)
    problems, _ = check(vmf, (spawn[0], spawn[1], 64), [])
    with open(out, "w") as f:
        f.write(vmf.text())
    print("  %d pieces, %d buttons, %d yard brushes, hull %d by %d by %d" % (len(placed), buttons, n, x2 - x1, y2 - y1, top - base))
    for name, k in placed:
        print("    %-34s %d button%s" % (name, k, "" if k == 1 else "s"))
    return problems


def main():
    ap = argparse.ArgumentParser(description="Build the Valve pieces gallery test map.")
    ap.add_argument("names", nargs="*")
    ap.add_argument("--out", default="lc_valve_gallery.vmf")
    a = ap.parse_args()
    out = a.out if os.path.isabs(a.out) else os.path.join(HERE, a.out)
    problems = build(out, a.names)
    res = subprocess.run([sys.executable, os.path.join(HERE, "map_assets.py"), out], cwd=HERE, capture_output=True, text=True)
    lines = (res.stdout + res.stderr).splitlines()
    problems += [l.strip() for l in lines if "ERROR" in l or "Traceback" in l or "PROBLEM" in l]
    print("  map_assets.py: " + (lines[-1] if lines else "(nothing)"))
    for p in problems:
        print("  PROBLEM: " + p)
    print("written: %s%s" % (out, "" if not problems else " (with %d problems)" % len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
