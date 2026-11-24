#!/usr/bin/env python3
"""What a VMF spends of the compiler's limits (the owner's compile of the canal ring's test map, 23 November, stopped in
vbsp: "Too many detail brush faces, max = 65536"; and City 18 and every other piece still go into the same map).

    python3 map_budget.py FILE.vmf [MORE.vmf ...]      each file, then all of them added together, against the limits
    python3 map_budget.py FILE.vmf --by vis            ...and where its brushes and drawn faces go, by visgroup
    python3 map_budget.py FILE.vmf --by mat            ...by material (--by ent: by brush entity class; --top N)
    python3 map_budget.py FILE.vmf --line              one line (what every build prints)

What it counts, as vbsp will (read off the VMF, so a floor under what the compile reports):
  brushes      every solid: the world's, func_detail's, every brush entity's (triggers, clips and hints too)
  sides        brush sides as compiled: vbsp adds a bevel side for each of the 6 axis directions a brush has no face
               along, so a box is 6 and any brush is about 6 + one per sloped face
  faces        drawn faces: every side whose material is not a tool (nodraw, clip, trigger, hint, skip...) and is not
               on a brush with a displacement (vbsp drops a displaced brush's other sides); sky faces are drawn faces
               too and are shown apart. The compiler cuts more: a face wherever its lightmap would pass 31 luxels a
               side (496 units at the usual lightmap scale of 16; --deep estimates it, from the vertices_plus blocks),
               and the world's faces again wherever the BSP divides the world. Detail and the world share one limit.
  displacements, props (prop_static apart), entities (every entity block but the world), overlays, brush models
               (every brush entity but func_detail is a model of its own, func_areaportal too)
  vertices     an estimate of vbsp's unique vertices (MAX_MAP_VERTS, 65,536: the owner's compile of the ring's test
               map, 24 November, stopped on "Too many unique verts, 70769/65536" with its faces well under their limit):
               the corners of every drawn face and of every displacement's base, plus VERT_CUT_SHARE of the corners
               vbsp adds where it cuts a face every 31 luxels for its lightmap (a face's corners are worked out from
               its brush's planes, so it needs no vertices_plus). Calibrated on that compile: 50,570 corners and
               34,045 cut corners against vbsp's 70,769

The limits are Garry's Mod's (its own vbsp, as its changelists raised them: 19 February 2019, 9 June 2021, March 2024):
faces 65,536 (MAX_MAP_FACES, never raised: world, detail and brush entities share it; the one the ring hit), brush
sides about 163,840 (CS:GO's; 65,536 elsewhere), brushes 65,535 (16,384 in its 2019 notes; 8,192 elsewhere), planes
65,536 (each kept as a pair), displacements 16,384 (2,048 elsewhere), entities in the VMF 65,536 (8,192 networked at
a time in game), overlays 8,192, brush models 1,024. A face holds a lightmap of 31 luxels a side (127 in Garry's Mod,
by the Valve wiki, unconfirmed): --deep estimates the cuts with --luxels (31 by default, the worst case).
"""
import argparse
import math
import re
import sys

LIMITS = {      # Garry's Mod's vbsp and engine (its changelists 2798, 3905 and the March 2024 update; the Valve wiki)
    "brushes": 65535,
    "sides": 163840,
    "faces": 65536,
    "displacements": 16384,
    "entities": 65536,
    "overlays": 8192,
    "models": 1024,
    "planes": 65536,
    "verts": 65536,
}
OTHER_SOURCE = {"brushes": 8192, "sides": 65536, "displacements": 2048, "entities": 8192, "overlays": 512}

SKY = ("tools/toolsskybox", "tools/toolsskybox2d", "tools/toolsskyfog")
NUM = re.compile(r"-?\d+(?:\.\d+)?(?:e-?\d+)?")


def is_sky(mat):
    return mat in SKY


def drawn(mat):
    """A material vbsp makes a face for: anything but a tool (the sky is a tool texture that is drawn)."""
    return not mat.startswith("tools/") or is_sky(mat)


def plane_normal(text):
    p = [float(v) for v in NUM.findall(text)]
    if len(p) < 9:
        return None, 0.0
    a, b, c = p[0:3], p[3:6], p[6:9]
    u = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    v = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    ln = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
    if ln < 1e-9:
        return None, 0.0
    n = (n[0] / ln, n[1] / ln, n[2] / ln)
    return n, n[0] * a[0] + n[1] * a[1] + n[2] * a[2]


def axial(n):
    for k in range(3):
        if abs(n[k]) > 0.9999:
            return k * 2 + (0 if n[k] > 0 else 1)
    return None


VERT_CUT_SHARE = 0.6     # (of the cut corners counted, vbsp's own count had about 59%: cuts that line up are shared)
VERT_NEAR = 58000        # (an estimate: warn this far below the limit)


def plane3(text):
    """A side's plane as Hammer writes it (three points) -> (unit normal pointing out of the brush, distance)."""
    p = [float(v) for v in NUM.findall(text)]
    if len(p) < 9:
        return None
    a, b, c = p[0:3], p[3:6], p[6:9]
    u = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    v = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    ln = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
    if ln < 1e-9:
        return None
    n = (n[0] / ln, n[1] / ln, n[2] / ln)
    return n, n[0] * a[0] + n[1] * a[1] + n[2] * a[2]


def face_poly(planes, k):
    """The corners of side k of a brush (planes: plane3 of each side): a big square on its plane, cut by the others."""
    n, d = planes[k]
    ax = max(range(3), key=lambda i: abs(n[i]))
    up = (0.0, 0.0, 1.0) if ax != 2 else (1.0, 0.0, 0.0)
    r = (up[1] * n[2] - up[2] * n[1], up[2] * n[0] - up[0] * n[2], up[0] * n[1] - up[1] * n[0])
    ln = math.sqrt(sum(x * x for x in r))
    r = tuple(x / ln for x in r)
    w = (n[1] * r[2] - n[2] * r[1], n[2] * r[0] - n[0] * r[2], n[0] * r[1] - n[1] * r[0])
    big = 131072.0
    poly = [tuple(n[i] * d + big * (a * r[i] + b * w[i]) for i in range(3)) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    for j, o in enumerate(planes):
        if j == k or o is None:
            continue
        on, od = o
        out = []
        for q in range(len(poly)):
            p1, p2 = poly[q], poly[(q + 1) % len(poly)]
            d1 = on[0] * p1[0] + on[1] * p1[1] + on[2] * p1[2] - od
            d2 = on[0] * p2[0] + on[1] * p2[1] + on[2] * p2[2] - od
            if d1 <= 0.01:
                out.append(p1)
            if (d1 < -0.01 and d2 > 0.01) or (d1 > 0.01 and d2 < -0.01):
                t = d1 / (d1 - d2)
                out.append(tuple(p1[i] + t * (p2[i] - p1[i]) for i in range(3)))
        poly = out
        if len(poly) < 3:
            return []
    return poly


def lightmap_cut_corners(poly, uaxis, vaxis, scale, luxels=31):
    """The corners vbsp adds cutting this face into pieces of at most `luxels` a side: 2 for each cut each way, and one
    where two cuts cross."""
    cuts = []
    for a in (uaxis, vaxis):
        v = [float(x) for x in NUM.findall(a)[:3]]
        ln = math.sqrt(sum(x * x for x in v)) or 1.0
        vals = [sum(v[i] * p[i] for i in range(3)) / ln for p in poly]
        cuts.append(max(0, math.ceil((max(vals) - min(vals)) / (luxels * scale) - 1e-6) - 1))
    return 2 * cuts[0] + 2 * cuts[1] + cuts[0] * cuts[1]


def parse(path):
    """Every solid as (owner, visgroup id, sides) with sides [(material, plane, displaced, uaxis, vaxis, lightmapscale,
    corners)], every entity's classname, and the visgroups' names. A plain line reader: fast on a 50 MB file."""
    solids, ents, visnames = [], [], {}
    stack = []           # block names
    side = None
    sol = None
    ent = None           # [classname, [solids]]
    vis_block = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        pending = None
        for raw in fh:
            line = raw.strip()
            if not line:
                continue
            if line == "{":
                name = pending or ""
                stack.append(name)
                depth = len(stack)
                if name == "entity" and depth == 1:
                    ent = ["", [], 0]
                elif name == "solid" and depth == 2:
                    sol = [ent if stack[0] == "entity" else None, 0, []]
                elif name == "side" and sol is not None:
                    side = ["", "", False, "", "", 16.0, []]
                elif name == "visgroup":
                    vis_block = {}
                elif name == "dispinfo" and side is not None:
                    side[2] = True
                pending = None
                continue
            if line == "}":
                name = stack.pop() if stack else ""
                if name == "side" and side is not None and sol is not None:
                    sol[2].append(tuple(side))
                    side = None
                elif name == "solid" and sol is not None and len(stack) == 1:
                    if sol[0] is None:
                        solids.append(sol)
                    else:
                        sol[0][1].append(sol)
                    sol = None
                elif name == "entity" and ent is not None and not stack:
                    ents.append(ent)
                    ent = None
                elif name == "visgroup" and vis_block is not None:
                    if "visgroupid" in vis_block:
                        visnames[vis_block["visgroupid"]] = vis_block.get("name", "")
                    vis_block = None
                continue
            if line[0] != '"':
                pending = line
                continue
            q = line.split('"')
            if len(q) < 4:
                continue
            key, val = q[1], q[3]
            top = stack[-1] if stack else ""
            if top == "side" and side is not None:
                if key == "material":
                    side[0] = val.lower()
                elif key == "plane":
                    side[1] = val
                elif key == "uaxis":
                    side[3] = val
                elif key == "vaxis":
                    side[4] = val
                elif key == "lightmapscale":
                    try:
                        side[5] = float(val.lstrip("@")) or 16.0
                    except ValueError:
                        pass
            elif top == "vertices_plus" and side is not None and key == "v":
                side[6].append(tuple(float(x) for x in val.split()))
            elif top == "editor" and sol is not None and len(stack) >= 2 and stack[-2] == "solid" and key == "visgroupid":
                sol[1] = val
            elif top == "editor" and ent is not None and len(stack) == 2 and key == "visgroupid":
                ent[2] = val
            elif top == "entity" and ent is not None and len(stack) == 1 and key == "classname":
                ent[0] = val
            elif top == "visgroup" and vis_block is not None and key in ("name", "visgroupid"):
                vis_block[key] = val
    return solids, ents, visnames


def lightmap_pieces(corners, uaxis, vaxis, scale, luxels=31):
    """How many faces vbsp cuts one into so that no lightmap passes its luxels a side (an estimate: along the texture's
    own axes, as vbsp measures it). luxels: the most a face may hold a side."""
    if len(corners) < 3:
        return 1
    out = []
    for ax in (uaxis, vaxis):
        v = [float(x) for x in NUM.findall(ax)[:3]]
        ln = math.sqrt(sum(c * c for c in v)) or 1.0
        v = [c / ln for c in v]
        d = [sum(p[k] * v[k] for k in range(3)) for p in corners]
        out.append(max(1, int(math.ceil((max(d) - min(d)) / (luxels * scale) - 1e-6))))
    return out[0] * out[1]


def count(path, deep=False, by=None, luxels=31):
    solids, ents, visnames = parse(path)
    c = {"file": path, "brushes": 0, "disp_brushes": 0, "sides": 0, "world": 0, "sky": 0, "detail": 0, "detail_sky": 0, "brush_ents": 0,
         "displacements": 0, "props": 0, "static_props": 0, "entities": 0, "overlays": 0, "models": 0, "planes": 0, "lightmap_cuts": 0, "vert_cuts": 0}
    planes = set()
    groups = {}

    vset = set()

    def take(sol, owner, cls):
        sides = sol[2]
        c["brushes"] += 1
        disp = any(s[2] for s in sides)
        pls = [plane3(s[1]) for s in sides]
        for k, sd in enumerate(sides):
            if pls[k] is None or (sd[2] if disp else not drawn(sd[0])):
                continue
            poly = face_poly(pls, k)
            for p in poly:
                vset.add((round(p[0]), round(p[1]), round(p[2])))
            if poly and not disp and not is_sky(sd[0]):
                c["vert_cuts"] += lightmap_cut_corners(poly, sd[3], sd[4], sd[5])
        c["disp_brushes"] += disp
        angled, drawn_here = 0, 0
        for mat, pl, dsp, ua, va, lms, corners in sides:
            n, d = plane_normal(pl)
            if n is not None:
                angled += axial(n) is None
                key = (round(n[0], 4) + 0.0, round(n[1], 4) + 0.0, round(n[2], 4) + 0.0, round(d, 2) + 0.0)
                planes.add(key if key > tuple(-x + 0.0 for x in key) else tuple(-x + 0.0 for x in key))
            if dsp:
                c["displacements"] += 1
                drawn_here += 1
                c["world" if owner == "world" else "detail" if owner == "detail" else "brush_ents"] += 1
                continue
            if disp or not drawn(mat):
                continue
            drawn_here += 1
            if owner == "world":
                c["sky" if is_sky(mat) else "world"] += 1
            elif owner == "detail":
                c["detail_sky" if is_sky(mat) else "detail"] += 1
            else:
                c["brush_ents"] += 1
            if deep and not is_sky(mat):
                c["lightmap_cuts"] += lightmap_pieces(corners, ua, va, lms, luxels) - 1
        c["sides"] += 6 + angled       # (the faces it has along the 6 axis directions, a bevel for each it lacks, its sloped faces)
        if by:
            if by == "vis":
                k = visnames.get(sol[1], sol[1] or "(none)")
            elif by == "ent":
                k = cls
            else:
                ms = sorted(set(s[0] for s in sides if drawn(s[0]) and not disp))
                k = ms[0] if len(ms) == 1 else (max(ms, key=lambda m: sum(1 for s in sides if s[0] == m)) if ms else "(no drawn face)")
            g = groups.setdefault(k, [0, 0, 0])
            g[0] += 1
            g[1] += drawn_here
            g[2] += sum(1 for s in sides if is_sky(s[0]))
    for sol in solids:
        take(sol, "world", "worldspawn")
    for cls, sols, _vis in ents:
        c["entities"] += 1
        if cls.startswith("prop_"):
            c["props"] += 1
            c["static_props"] += cls == "prop_static"
        if cls == "info_overlay":
            c["overlays"] += 1
        if sols and cls != "func_detail":
            c["models"] += 1
        for sol in sols:
            take(sol, "detail" if cls == "func_detail" else "ent", cls)
    c["planes"] = 2 * len(planes)
    c["vert_corners"] = len(vset)
    c["verts"] = len(vset) + int(VERT_CUT_SHARE * c["vert_cuts"])
    c["faces"] = c["world"] + c["sky"] + c["detail"] + c["detail_sky"] + c["brush_ents"]
    c["groups"] = groups
    return c


def add(counts):
    t = {"file": "together"}
    for c in counts:
        for k, v in c.items():
            if isinstance(v, int):
                t[k] = t.get(k, 0) + v
    t["groups"] = {}
    t["planes_note"] = "planes added together count shared ones twice"
    return t


def over(c, key):
    lim = LIMITS[key]
    v = c[key] + (c.get("lightmap_cuts", 0) if key == "faces" else 0)
    return " OVER" if v > lim else ""


def line(c):
    """One line, for a build's output."""
    deep = " (+%s lightmap cuts)" % format(c["lightmap_cuts"], ",") if c.get("lightmap_cuts") else ""
    return ("budget: %s brushes, %s sides, faces %s world (+%s sky) + %s detail + %s brush entities = %s of 65,536%s%s, "
            "vertices about %s of 65,536%s, %s displacements, %s props, %s entities" % (
                format(c["brushes"], ","), format(c["sides"], ","), format(c["world"], ","), format(c["sky"] + c["detail_sky"], ","),
                format(c["detail"], ","), format(c["brush_ents"], ","), format(c["faces"], ","), deep, over(c, "faces"),
                format(c["verts"], ","), over(c, "verts") or (" NEAR" if c["verts"] > VERT_NEAR else ""),
                format(c["displacements"], ","), format(c["props"], ","), format(c["entities"], ",")))


def text_count(text, deep=False):
    """Count a VMF given as text (a build that has not written its file yet)."""
    import os
    import tempfile
    fd, tmp = tempfile.mkstemp(suffix=".vmf")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(text)
        return count(tmp, deep=deep)
    finally:
        os.remove(tmp)


def report(c):
    def row(name, v, key=None, note=""):
        lim = LIMITS.get(key) if key else None
        tail = ""
        if lim:
            tail = "   of %s (%d%%)%s" % (format(lim, ","), round(100.0 * v / lim), " OVER" if v > lim else "")
            if key in OTHER_SOURCE and v > OTHER_SOURCE[key]:
                tail += "  (over other Source games' %s)" % format(OTHER_SOURCE[key], ",")
        print("  %-30s %9s%s%s" % (name, format(v, ","), tail, note))
    print(c["file"])
    row("brushes", c["brushes"], "brushes", "  (%s with a displaced face)" % format(c["disp_brushes"], ",") if c["disp_brushes"] else "")
    row("brush sides (as compiled)", c["sides"], "sides")
    row("planes (about)", c["planes"], "planes", "  (" + c["planes_note"] + ")" if c.get("planes_note") else "")
    row("drawn faces, all", c["faces"], "faces")
    row("  world (not sky)", c["world"])
    row("  world sky", c["sky"])
    row("  detail", c["detail"] + c["detail_sky"], note="  (%s sky)" % format(c["detail_sky"], ",") if c["detail_sky"] else "")
    row("  brush entities", c["brush_ents"])
    if c.get("lightmap_cuts"):
        row("  + lightmap cuts (about)", c["lightmap_cuts"], note="  -> %s" % format(c["faces"] + c["lightmap_cuts"], ","))
    row("vertices (estimate)", c["verts"], "verts", "  (%s corners + %d%% of %s lightmap cut corners)" % (
        format(c["vert_corners"], ","), round(VERT_CUT_SHARE * 100), format(c["vert_cuts"], ",")))
    row("displacements", c["displacements"], "displacements")
    row("brush models", c["models"], "models")
    row("entities", c["entities"], "entities", "  (%s props, %s of them prop_static)" % (format(c["props"], ","), format(c["static_props"], ",")))
    row("overlays", c["overlays"], "overlays")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("vmf", nargs="+")
    ap.add_argument("--line", action="store_true", help="one line a file")
    ap.add_argument("--deep", action="store_true", help="also estimate the faces vbsp cuts for lightmaps (needs the vertices_plus blocks)")
    ap.add_argument("--luxels", type=int, default=31, help="with --deep: the most luxels a face's lightmap may have a side (31; Garry's Mod's may be 127)")
    ap.add_argument("--by", choices=["vis", "mat", "ent"], help="where the brushes and drawn faces go")
    ap.add_argument("--top", type=int, default=25)
    a = ap.parse_args()
    counts = []
    for p in a.vmf:
        c = count(p, deep=a.deep, by=a.by, luxels=a.luxels)
        counts.append(c)
        if a.line:
            print("%s: %s" % (p, line(c)))
            continue
        report(c)
        if a.by:
            print("  %-60s %8s %8s %8s" % ("by " + {"vis": "visgroup", "mat": "material", "ent": "class"}[a.by], "brushes", "faces", "sky"))
            for k, (b, f, s) in sorted(c["groups"].items(), key=lambda x: -x[1][1])[:a.top]:
                print("  %-60s %8s %8s %8s" % (k[:60], format(b, ","), format(f, ","), format(s, ",")))
    if len(counts) > 1:
        t = add(counts)
        if a.line:
            print("together: " + line(t))
        else:
            report(t)


if __name__ == "__main__":
    main()
