#!/usr/bin/env python3
"""
Living City: pieces of the owner's own City 18, lifted out and placed again (the owner, 21 November: "don't be afraid
to more or less rip off and copy the design principles, textures, etc from city 18; the modules are really bad with
texture choice and architecture").

A prefab is every brush wholly inside a box of the owner's map (world brushes and detail alike), with each face's
material and texture alignment exactly as theirs, and the props, lights and decals inside it. Placed in a piece it is
moved and turned (in quarter turns) with its textures kept right, and written as detail (it never seals: the piece's
own plan does that), so a facade bay, a shopfront, a door surround or a stair of theirs can dress our walls.

    python3 map_prefab.py extract c18_lc.vmf NAME X1 Y1 Z1 X2 Y2 Z2 [--anchor X Y Z] [--note "what it is"]
            writes _dev/reference/prefabs/NAME.json (the anchor, default the box's bottom corner, becomes 0 0 0)
    python3 map_prefab.py list                  the library, with each piece's size and what it is
    python3 map_prefab.py show NAME [--out a.vmf]   a VMF with only that piece in it (map_view.py draws it)

In a module: from map_prefab import place; place(m, "NAME", u, v, z, turn) puts the piece's anchor at (u, v, z) of
the module's frame, turned by `turn` quarter turns anticlockwise (0 to 3) on top of the frame's own turning.
"""
import argparse
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(HERE, "..", "reference", "prefabs")
sys.path.insert(0, HERE)

AXIS = re.compile(r"\[\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*\]\s*(\S+)")
SEEN_TOOLS = ("tools/toolsblack",)      # (tool materials players see: the black behind a window)
NAMED = ("targetname", "parentname", "slavename", "target", "spawnpos")      # (keys that name another thing of the piece)
KEEP_POINTS = ("prop_static", "prop_dynamic", "prop_dynamic_override", "prop_physics", "light", "light_spot", "infodecal", "env_sprite", "prop_door_rotating")


def nums(text):
    return [float(t) for t in text.replace("(", " ").replace(")", " ").split()]


def extract(path, name, box, anchor=None, note=""):
    import map_view as mv
    root = mv.read(path)
    x1, y1, z1, x2, y2, z2 = box
    ax = anchor or (x1, y1, z1)
    solids, points = [], []

    def inside(p, pad=0.5):
        return x1 - pad <= p[0] <= x2 + pad and y1 - pad <= p[1] <= y2 + pad and z1 - pad <= p[2] <= z2 + pad
    for top in root.kids:
        if top.name not in ("world", "entity"):
            continue
        cls = top.kv.get("classname", "worldspawn")
        if top.name == "entity" and cls not in ("func_detail", "func_brush", "func_wall", "func_illusionary"):
            if cls in KEEP_POINTS and "origin" in top.kv:
                o = nums(top.kv["origin"])
                if inside(o):
                    keys = dict((k, v) for k, v in top.rows if k not in ("id", "origin"))
                    points.append({"classname": cls, "origin": [o[0] - ax[0], o[1] - ax[1], o[2] - ax[2]], "keys": keys})
            continue
        for sol in top.kids:
            if sol.name != "solid":
                continue
            sides, allv = [], []
            side_blocks = [k for k in sol.kids if k.name == "side"]
            worked = None
            if side_blocks and not any(k.name == "vertices_plus" for sb in side_blocks for k in sb.kids):
                worked = mv.from_planes(side_blocks)      # (an older Hammer's file: corners from the planes, for boxes and checks only)
            for side in sol.kids:
                if side.name != "side":
                    continue
                vp = [k for k in side.kids if k.name == "vertices_plus"]
                verts = [nums(v) for k, v in vp[0].rows if k == "v"] if vp else []
                plane = nums(side.kv.get("plane", ""))
                if len(plane) != 9:
                    break
                corners = verts or ([list(v) for v in worked[len(sides)]] if worked and len(sides) < len(worked) and worked[len(sides)] else [])
                allv += corners or [plane[0:3], plane[3:6], plane[6:9]]
                sides.append({"plane": [plane[0:3], plane[3:6], plane[6:9]], "verts": verts, "corners": corners, "material": side.kv.get("material", "TOOLS/TOOLSNODRAW"),
                              "uaxis": side.kv.get("uaxis", "[1 0 0 0] 0.25"), "vaxis": side.kv.get("vaxis", "[0 -1 0 0] 0.25"),
                              "lightmapscale": side.kv.get("lightmapscale", "16")})
            else:
                if sides and all(inside(v) for v in allv):
                    if all("tools/" in s["material"].lower() and not s["material"].lower().startswith(SEEN_TOOLS) for s in sides):
                        continue      # (clips, triggers, skybox, hint: the piece does not need them; black panes are seen and kept)
                    for s in sides:
                        s["plane"] = [[p[0] - ax[0], p[1] - ax[1], p[2] - ax[2]] for p in s["plane"]]
                        s["verts"] = [[p[0] - ax[0], p[1] - ax[1], p[2] - ax[2]] for p in s["verts"]]
                        s["corners"] = [[p[0] - ax[0], p[1] - ax[1], p[2] - ax[2]] for p in s["corners"]]
                        s["uaxis"] = shift_axis(s["uaxis"], ax)
                        s["vaxis"] = shift_axis(s["vaxis"], ax)
                    solids.append({"from": cls, "sides": sides})
    size = [x2 - x1, y2 - y1, z2 - z1]
    out = {"name": name, "note": note, "from": os.path.basename(path), "box": list(box), "anchor": list(ax), "size": size,
           "solids": solids, "points": points}
    os.makedirs(LIB, exist_ok=True)
    with open(os.path.join(LIB, name + ".json"), "w") as f:
        json.dump(out, f, indent=0)
    return out


def shift_axis(text, d):
    """A face's texture axis after the face is moved by -d (so its texture stays where it was on the face)."""
    m = AXIS.match(text)
    if not m:
        return text
    a = [float(m.group(k)) for k in (1, 2, 3)]
    off, scale = float(m.group(4)), float(m.group(5))
    off = off + (a[0] * d[0] + a[1] * d[1] + a[2] * d[2]) / scale
    return "[%s %s %s %s] %s" % (fmt(a[0]), fmt(a[1]), fmt(a[2]), fmt(off), fmt(scale))


def turn_axis(text, turn, d):
    """A texture axis after its face is turned `turn` quarter turns about z and then moved by +d."""
    m = AXIS.match(text)
    if not m:
        return text
    a = [float(m.group(k)) for k in (1, 2, 3)]
    off, scale = float(m.group(4)), float(m.group(5))
    a = rot(a, turn)
    off = off - (a[0] * d[0] + a[1] * d[1] + a[2] * d[2]) / scale
    return "[%s %s %s %s] %s" % (fmt(a[0]), fmt(a[1]), fmt(a[2]), fmt(off % 1024 if scale else off), fmt(scale))


def rot(p, turn):
    x, y, z = p
    for _ in range(turn % 4):
        x, y = -y, x
    return [x, y, z]


def fmt(v):
    return ("%.4f" % v).rstrip("0").rstrip(".") if v != int(v) else "%d" % v


def load(name):
    with open(os.path.join(LIB, name + ".json")) as f:
        return json.load(f)


PLACED = [0]


def place(m, name, u, v, z, turn=0, vis=None, props=True):
    """Put the prefab's anchor at (u, v, z) in the module's frame, turned `turn` quarter turns (anticlockwise seen from
    above) on top of the frame's own turning. Its brushes go in as one func_detail; its props, lights and decals as they
    were (moved and turned with it)."""
    pf = load(name)
    fr = m.fr
    q = (turn + fr.rot) % 4
    if fr.flip:      # (a flipped frame mirrors; a mirrored brush would turn inside out: turn it the other way round instead)
        q = (q + 2) % 4
    ox, oy = fr.pt(u, v)
    oz = z + fr.dz
    d = (ox, oy, oz)
    vmf = m.b.vmf
    t = "\t"
    text = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % vmf.new_id()
    for sol in pf["solids"]:
        text += '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, vmf.new_id())
        allv = []
        for s in sol["sides"]:
            pl = [[a + b for a, b in zip(rot(p, q), d)] for p in s["plane"]]
            vs = [[a + b for a, b in zip(rot(p, q), d)] for p in s["verts"]]
            allv += vs or [[a + b for a, b in zip(rot(p, q), d)] for p in s.get("corners", [])] or pl
            text += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, vmf.new_id(), t, " ".join("(%s %s %s)" % tuple(fmt(c) for c in p) for p in pl))
            if vs:
                text += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%s %s %s"\n' % ((t,) + tuple(fmt(c) for c in p)) for p in vs), t)
            text += '%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%s"\n%s\t\t"smoothing_groups" "0"\n%s\t}\n' % (
                t, s["material"], t, turn_axis(s["uaxis"], q, d), t, turn_axis(s["vaxis"], q, d), t, t, s["lightmapscale"], t, t)
        text += vmf.editor(vis or m.dv, indent=t + "\t") + "%s}\n" % t
        if allv:
            vmf.boxes.append((tuple(min(p[k] for p in allv) for k in range(3)) + tuple(max(p[k] for p in allv) for k in range(3)), False))
    text += vmf.editor(vis or m.dv, "0 180 0") + "}\n"
    if pf["solids"]:
        vmf.ents.append(text)
    if props:
        names = set(p["keys"].get("targetname") for p in pf["points"] if p["keys"].get("targetname"))
        PLACED[0] += 1
        tag = "_%s%d" % (name, PLACED[0])      # (each copy's names its own: two copies' doors never open together)
        for p in pf["points"]:
            keys = dict(p["keys"])
            for k in NAMED:
                if keys.get(k) in names:
                    keys[k] = keys[k] + tag
            if "angles" in keys:
                a = nums(keys["angles"])
                keys["angles"] = "%s %s %s" % (fmt(a[0]), fmt((a[1] + 90 * q) % 360), fmt(a[2]))
            pos = [a + b for a, b in zip(rot(p["origin"], q), d)]
            vmf.point(p["classname"], tuple(pos), keys, m.pv if p["classname"].startswith("prop") else m.lv)
    return pf


def main():
    ap = argparse.ArgumentParser(description="Pieces of the owner's City 18, lifted out and placed again.")
    sub = ap.add_subparsers(dest="cmd")
    e = sub.add_parser("extract")
    e.add_argument("vmf")
    e.add_argument("name")
    e.add_argument("box", nargs=6, type=float)
    e.add_argument("--anchor", nargs=3, type=float)
    e.add_argument("--note", default="")
    sub.add_parser("list")
    s = sub.add_parser("show")
    s.add_argument("name")
    s.add_argument("--out")
    a = ap.parse_args()
    if a.cmd == "extract":
        pf = extract(a.vmf, a.name, a.box, a.anchor, a.note)
        print("%s: %d brushes, %d props/lights/decals, %d by %d by %d" % (a.name, len(pf["solids"]), len(pf["points"]), pf["size"][0], pf["size"][1], pf["size"][2]))
    elif a.cmd == "list":
        for f in sorted(os.listdir(LIB)) if os.path.isdir(LIB) else []:
            if f.endswith(".json"):
                pf = load(f[:-5])
                print("%-26s %4d brushes %3d things  %5d x %5d x %5d  %s" % (pf["name"], len(pf["solids"]), len(pf["points"]), pf["size"][0], pf["size"][1], pf["size"][2], pf["note"]))
    elif a.cmd == "show":
        from map_build import Vmf
        from map_modules import Frame, Mod, Build
        b = Build("prefab_" + a.name, 784, 9000)
        m = Mod(b, Frame(0, 0, 0, 64), "prefab")
        place(m, a.name, 0, 0, 0)
        out = a.out or "lc_prefab_%s.vmf" % a.name
        with open(out, "w") as f:
            f.write(b.vmf.text())
        print("written: " + out)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
