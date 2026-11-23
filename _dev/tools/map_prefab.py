#!/usr/bin/env python3
"""
Living City: pieces of the owner's own City 18, lifted out and placed again (the owner, 21 November: "don't be afraid
to more or less rip off and copy the design principles, textures, etc from city 18; the modules are really bad with
texture choice and architecture").

A prefab is every brush wholly inside a box of the owner's map (world brushes and detail alike), with each face's
material and texture alignment exactly as theirs, and the props, lights and decals inside it. Placed in a piece it is
moved and turned (in quarter turns) with its textures kept right, and written as detail (it never seals: the piece's
own plan does that), so a facade bay, a shopfront, a door surround or a stair of theirs can dress our walls.
A displaced face (Valve's cave rock, 21 November) keeps its dispinfo, moved and turned with it, so a cave can be lifted
too; cut its box on the grid the cave's brushes are laid on, or the rock stops short of the cut.

A piece also keeps its logic: every other entity inside the box (relays, triggers with their brushes, doors, buttons,
sounds, NPCs, scripted sequences) goes in `wiring` with its keys and outputs, a moving brush also in `solids` as a slab
taken shut (`live`: its name, `wired`: its place in `wiring`), and what the piece's outputs and keys name that is not in
it in `outside`, what outside fires into it in `fired_from_outside` (docs/dev/prefabs.md, 'Pieces with their wiring').

    python3 map_prefab.py extract c18_lc.vmf NAME X1 Y1 Z1 X2 Y2 Z2 [--anchor X Y Z] [--note "what it is"] [--wire-box X1 Y1 Z1 X2 Y2 Z2]
            writes _dev/reference/prefabs/NAME.json (the anchor, default the box's bottom corner, becomes 0 0 0;
            --wire-box: a bigger box for the logic, for a piece whose relays and sounds stand round it)
            [--drop MATERIAL ...] leaves out brushes with a face of that material (water, say)
            [--centroid] keeps every brush whose corners' mean is inside (a cave not cut on a grid: its tunnels run
            on past the box, to be capped); [--force ID ...] keeps those brushes too
    python3 map_prefab.py list                  the library, with each piece's size and what it is
    python3 map_prefab.py show NAME [--out a.vmf] [--no-wiring]   a VMF with only that piece in it (map_view.py draws it)
    python3 map_prefab.py check                 the self-check: lifts a small made-up map with logic and places it twice

In a module: from map_prefab import place; place(m, "NAME", u, v, z, turn) puts the piece's anchor at (u, v, z) of
the module's frame, turned by `turn` quarter turns anticlockwise (0 to 3) on top of the frame's own turning. Its
wiring comes too, every name given the copy's own ending (in the outputs as in the keys); place(..., wiring=False)
leaves the logic out and keeps the slabs of its moving brushes, as place() did before it kept logic.
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
STATIC_BRUSHES = ("func_detail", "func_brush", "func_wall", "func_illusionary")
# Kept out of the wiring: the map's own navigation and compile helpers, single-player level changes, things that hold
# face ids of the source map (cubemaps, overlays), and what sets the whole map (sun, fog, tonemap, skybox camera).
NOT_WIRED = ("worldspawn", "info_player_start", "info_landmark", "trigger_changelevel", "env_cubemap", "info_overlay", "info_overlay_transition",
             "func_areaportal", "func_areaportalwindow", "func_viscluster", "func_occluder", "light_environment", "shadow_control",
             "env_tonemap_controller", "env_fog_controller", "sky_camera", "water_lod_control", "info_no_dynamic_shadow", "info_hint")
# Keys that name another entity (for `outside`, and dropped when what they name is not placed). Any key whose value is a
# name of the piece is renamed with the copy, whatever it is called (a template's Template01, a beam's LightningStart).
NAME_KEYS = ("parentname", "target", "altpath", "lightingorigin", "lightingoriginhack", "nextkey", "attach1", "attach2", "position0", "slavename",
             "filtername", "damagefilter", "laddername", "lightningstart", "lightningend", "measuretarget", "sourceentityname", "m_iszentity",
             "spawntarget", "landmark", "entitytemplate", "template", "controlpoint1", "point_template", "target_entity", "glowproxy")
NOT_NAMES = ("classname", "model", "message", "texture", "origin", "id")
SPOT_KEYS = ("point0", "point1", "springaxis", "hingeaxis", "slideaxis",       # (keys that hold a place in the source map, not a name: kept as there)
             "attachpoint", "position2", "lowerleft", "lowerright", "upperleft", "upperright")      # (a length or pulley constraint's ends, a glass pane's corners)
NODE_CLASSES = ("info_node", "info_node_hint", "info_node_air", "info_node_air_hint", "info_node_climb")
SPOT_BY_CLASS = {"phys_motor": ("axis",), "phys_torque": ("axis",), "point_angularvelocitysensor": ("axis",), "phys_ragdollmagnet": ("axis",)}      # ("axis" is a place only on these)
TURN_AXES = {"func_door_rotating": (64, 128), "func_rot_button": (64, 128), "momentary_rot_button": (64, 128), "func_rotating": (4, 8)}


def nums(text):
    return [float(t) for t in text.replace("(", " ").replace(")", " ").split()]


def unwired(cls):
    """Is this a class a piece's logic never holds (NOT_WIRED, or the source map's AI nodes)?"""
    return cls in NOT_WIRED or cls.startswith("info_node")


def split_output(rest):
    """One output as kept ("target,input,value,delay,times", or with the escape character between): its five parts."""
    p = rest.split("\x1b") if "\x1b" in rest else rest.split(",")
    p += [""] * (5 - len(p))
    try:
        delay = float(p[-2] or 0)
    except ValueError:
        delay = 0.0
    return p[0].strip(), p[1].strip(), ",".join(p[2:-2]).strip(), delay, p[-1].strip() or "-1"


def connections_of(block):
    """An entity's outputs, as [output, "target,input,value,delay,times"] (Valve's comma form, as the pieces keep them)."""
    out = []
    for c in block.kids:
        if c.name == "connections":
            for k, v in c.rows:
                t, i, val, delay, times = split_output(v)
                out.append([k, ",".join((t, i, val, fmt(delay), times))])
    return out


def name_refs(e):
    """What an entity of a piece names: [(how, the name)], how being 'key K' or 'OUTPUT' with the output's line."""
    refs = []
    for k, v in e["keys"].items():
        lk = k.lower()
        if v and not v.startswith("!") and (lk in NAME_KEYS or re.match(r"template\d\d$", lk)):
            refs.append(("key " + lk, v))
    for o, rest in e.get("connections", []):
        t = rest.split(",")[0].strip()
        if t and not t.startswith("!"):
            refs.append(("%s > %s" % (o, rest), t))
    return refs


def resolves(target, names):
    """The piece's names (lower case) a target reaches: itself, or every one a trailing * matches."""
    t = target.lower()
    if t.endswith("*"):
        return sorted(n for n in names if n.startswith(t[:-1]))
    return [t] if t in names else []


def extract(path, name, box, anchor=None, note="", wire_box=None, lib=None, drop=(), centroid=False, force=(), keep_nodraw=False,
            portals=False, clips=False, with_names=(), without=()):
    """(portals: the source's areaportals go in the wiring too, placed only with place(..., portals=True); clips: its
    player clips are kept as brushes; with_names: entities of those names (Hammer wildcards) are wired wherever they
    stand; without: entities of those names or classes are left out altogether, Valve's story say.)"""
    import fnmatch
    import map_view as mv
    root = mv.read(path)
    x1, y1, z1, x2, y2, z2 = box
    wb = wire_box or box
    ax = anchor or (x1, y1, z1)
    solids, points, wiring = [], [], []

    def inside(p, pad=0.5, b=box):
        return b[0] - pad <= p[0] <= b[3] + pad and b[1] - pad <= p[1] <= b[4] + pad and b[2] - pad <= p[2] <= b[5] + pad

    def rel(p):
        return [p[0] - ax[0], p[1] - ax[1], p[2] - ax[2]]

    def brush(sol):
        """A brush's sides (corners as in the source) and all its corners, or None if a plane cannot be read."""
        sides, allv = [], []
        side_blocks = [k for k in sol.kids if k.name == "side"]
        worked = None
        if side_blocks and not any(k.name == "vertices_plus" for sb in side_blocks for k in sb.kids):
            worked = mv.from_planes(side_blocks)      # (an older Hammer's file: corners from the planes, for boxes and checks only)
        for side in side_blocks:
            vp = [k for k in side.kids if k.name == "vertices_plus"]
            verts = [nums(v) for k, v in vp[0].rows if k == "v"] if vp else []
            plane = nums(side.kv.get("plane", ""))
            if len(plane) != 9:
                return None
            corners = verts or ([list(v) for v in worked[len(sides)]] if worked and len(sides) < len(worked) and worked[len(sides)] else [])
            allv += corners or [plane[0:3], plane[3:6], plane[6:9]]
            sides.append({"plane": [plane[0:3], plane[3:6], plane[6:9]], "verts": verts, "corners": corners, "material": side.kv.get("material", "TOOLS/TOOLSNODRAW"),
                          "uaxis": side.kv.get("uaxis", "[1 0 0 0] 0.25"), "vaxis": side.kv.get("vaxis", "[0 -1 0 0] 0.25"),
                          "lightmapscale": side.kv.get("lightmapscale", "16")})
            di = [k for k in side.kids if k.name == "dispinfo"]
            if di:
                sides[-1]["disp"] = disp_read(di[0], (0, 0, 0))      # (made relative to the anchor in moved())
        return (sides, allv, sol.kv.get("id")) if sides else None

    def moved(sides):
        """A brush's sides moved so the anchor is at 0 0 0 (a copy: the source's stay as they were)."""
        out = []
        for s in sides:
            s = dict(s)
            s["plane"] = [rel(p) for p in s["plane"]]
            s["verts"] = [rel(p) for p in s["verts"]]
            s["corners"] = [rel(p) for p in s["corners"]]
            s["uaxis"] = shift_axis(s["uaxis"], ax)
            s["vaxis"] = shift_axis(s["vaxis"], ax)
            if s.get("disp"):
                s["disp"] = disp_shift(s["disp"], ax)
            out.append(s)
        return out

    seen = SEEN_TOOLS + (("tools/toolsplayerclip",) if clips else ())

    def all_tools(sides):
        return all("tools/" in s["material"].lower() and not s["material"].lower().startswith(seen) for s in sides)

    def free(cls):      # (a class this lift does not wire)
        return unwired(cls) and not (portals and cls in ("func_areaportal", "func_areaportalwindow"))

    def match(pats, v):
        v = (v or "").lower()
        return bool(v) and any(fnmatch.fnmatchcase(v, p.lower()) for p in pats)

    def wanted(top):
        return match(with_names, top.kv.get("targetname", ""))

    kept = set()      # (the source's entities the piece holds, by id())
    places = {}       # (where each entity is in the source: its origin, or the middle of its brushes)
    for top in root.kids:
        if top.name not in ("world", "entity"):
            continue
        cls = top.kv.get("classname", "worldspawn")
        if top.name == "entity" and (match(without, top.kv.get("targetname", "")) or match(without, cls)):
            continue      # (--without: left out altogether)
        if top.name == "entity" and not any(k.name == "solid" for k in top.kids):
            if "origin" not in top.kv:
                continue
            o = nums(top.kv["origin"])
            places[id(top)] = o
            conns = connections_of(top)
            if cls in KEEP_POINTS and inside(o):
                keys = dict((k, v) for k, v in top.rows if k not in ("id", "origin"))
                points.append({"classname": cls, "origin": rel(o), "keys": keys})
                if conns:
                    points[-1]["connections"] = conns
                kept.add(id(top))
            elif (cls not in KEEP_POINTS or wanted(top)) and not free(cls) and (inside(o, b=wb) or wanted(top)):
                keys = dict((k, v) for k, v in top.rows if k not in ("id", "origin", "classname"))
                wiring.append({"classname": cls, "origin": rel(o), "keys": keys, "connections": conns})
                kept.add(id(top))
            continue
        brushes = [b for b in (brush(sol) for sol in top.kids if sol.name == "solid") if b]
        allc = [p for b in brushes for p in b[1]]
        if top.name == "entity" and allc:
            places[id(top)] = nums(top.kv["origin"]) if "origin" in top.kv else [(min(p[k] for p in allc) + max(p[k] for p in allc)) / 2 for k in range(3)]
        live, wired = None, None
        if top.name == "entity":
            conns = connections_of(top)
            tname = top.kv.get("targetname", "")
            if (cls not in STATIC_BRUSHES or tname or conns) and not free(cls) and brushes and (all(inside(p, b=wb) for p in allc) or wanted(top)):
                keys = dict((k, v) for k, v in top.rows if k not in ("id", "origin", "classname"))
                e = {"classname": cls, "keys": keys, "connections": conns, "brushes": [moved(b[0]) for b in brushes]}
                if "origin" in top.kv:
                    e["origin"] = rel(nums(top.kv["origin"]))
                wired = len(wiring)
                wiring.append(e)
                kept.add(id(top))
                live = tname
            if cls not in STATIC_BRUSHES:
                if wired is None and free(cls):
                    continue
                cls = "%s (taken shut, as a static slab)" % cls      # (a moving brush: its look, shut, for a piece placed without its logic)
        for sides, allv, sid in brushes:
            mean = [sum(v[k] for v in allv) / len(allv) for k in range(3)] if allv else None
            # (--centroid: every brush whose corners' mean is inside, for a cave not cut on a grid; --force: by id)
            if all(inside(v) for v in allv) or (centroid and mean and inside(mean, 0)) or sid in force:
                if any(sd["material"].lower() in drop for sd in sides):
                    continue      # (--drop: water, say)
                if all_tools(sides) and not (keep_nodraw and all(sd["material"].lower() == "tools/toolsnodraw" for sd in sides)):
                    continue      # (clips, triggers, skybox, hint: the piece does not need them; black panes are seen and kept;
                                  #  --keep-nodraw keeps the plain nodraw blocks a cave is shut in with, so the piece stays shut)
                s = {"from": cls, "sides": moved(sides)}
                if wired is not None:
                    s["live"], s["wired"] = live, wired
                solids.append(s)
    out = {"name": name, "note": note, "from": os.path.basename(path), "box": list(box), "anchor": list(ax), "size": [x2 - x1, y2 - y1, z2 - z1],
           "solids": solids, "points": points}
    # What the piece's logic names that it does not hold, and what outside it fires into it.
    names = set(e["keys"].get("targetname", "").lower() for e in points + wiring) - {""}
    found = {}
    for top in root.kids:
        n = top.kv.get("targetname", "").lower() if top.name == "entity" else ""
        if n and id(top) in places:
            found.setdefault(n, []).append({"classname": top.kv.get("classname", ""), "origin": [int(round(c)) for c in places[id(top)][:3]]})
    outside = {}
    for e in points + wiring:
        who = e["keys"].get("targetname") or e["classname"]
        for how, t in name_refs(e):
            if not resolves(t, names):
                o = outside.setdefault(t.lower(), {"name": t, "found": [f for k, fs in found.items() if k == t.lower() or (t.endswith("*") and k.startswith(t[:-1].lower())) for f in fs],
                                                   "named_by": []})
                o["named_by"].append("%s %s" % (who, how))
    fired = []
    for top in root.kids:
        if top.name != "entity" or id(top) in kept:
            continue
        into = [c for c in connections_of(top) if resolves(c[1].split(",")[0].strip(), names)]
        if into:
            fired.append({"name": top.kv.get("targetname", ""), "classname": top.kv.get("classname", ""),
                          "origin": [int(round(c)) for c in places.get(id(top), [0, 0, 0])[:3]], "outputs": into})
    if wiring or outside or fired or any(p.get("connections") for p in points):
        out.update({"wiring": wiring, "outside": list(outside.values()), "fired_from_outside": fired})
    folder = lib or LIB
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, name + ".json"), "w") as f:
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


def disp_shift(disp, ax):
    """A kept displaced face's dispinfo with its start position moved by -ax (a copy)."""
    keys = []
    for k, v in disp["keys"]:
        if k == "startposition":
            p = nums(v.replace("[", " ").replace("]", " "))
            v = "[%s %s %s]" % (fmt(p[0] - ax[0]), fmt(p[1] - ax[1]), fmt(p[2] - ax[2]))
        keys.append([k, v])
    return {"keys": keys, "blocks": disp["blocks"]}


def disp_read(block, ax):
    """A displaced face's dispinfo as it was, its start position made relative to the anchor."""
    keys = []
    for k, v in block.rows:
        if k == "startposition":
            p = nums(v.replace("[", " ").replace("]", " "))
            v = "[%s %s %s]" % (fmt(p[0] - ax[0]), fmt(p[1] - ax[1]), fmt(p[2] - ax[2]))
        keys.append([k, v])
    return {"keys": keys, "blocks": [[b.name, [[k, v] for k, v in b.rows]] for b in block.kids]}


DISP_VECTORS = ("normals", "offsets", "offset_normals")      # (rows of x y z triples: they turn with the face)


def disp_text(disp, q, d, t):
    """A dispinfo block for a face turned q quarter turns and moved by d (t: the side's indent)."""
    out = "%s\t\tdispinfo\n%s\t\t{\n" % (t, t)
    for k, v in disp["keys"]:
        if k == "startposition":
            p = nums(v.replace("[", " ").replace("]", " "))
            p = [a + b for a, b in zip(rot(p, q), d)]
            v = "[%s %s %s]" % tuple(fmt(round(c, 4)) for c in p)
        out += '%s\t\t\t"%s" "%s"\n' % (t, k, v)
    for name, rows in disp["blocks"]:
        out += "%s\t\t\t%s\n%s\t\t\t{\n" % (t, name, t)
        for k, v in rows:
            if name in DISP_VECTORS and q % 4:
                f = [float(c) for c in v.split()]
                f = [c for i in range(0, len(f) - 2, 3) for c in rot(f[i:i + 3], q)]
                v = " ".join(fmt(round(c, 6)) for c in f)
            out += '%s\t\t\t\t"%s" "%s"\n' % (t, k, v)
        out += "%s\t\t\t}\n" % t
    return out + "%s\t\t}\n" % t


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


def disp_side_text(disp, q, d, t):
    """A displaced face of a piece (as extract() keeps it) turned q quarter turns and moved by d: its start moved, and
    every vector of its grid (normals, offsets, offset normals) turned with it; distances, alphas and tags as they were."""
    if "keys" in disp:      # (the form disp_read() keeps: one form for every piece since 21 November)
        kv, rows = dict(disp["keys"]), dict((name, [v for _, v in r]) for name, r in disp["blocks"])
    else:
        kv, rows = disp["kv"], disp["rows"]
    sp = nums(kv["startposition"].replace("[", " ").replace("]", " "))
    x, y, z = rot(sp, q)
    out = '%sdispinfo\n%s{\n' % (t, t)
    for k in ("power", "flags", "elevation", "subdiv"):
        if k in kv:
            out += '%s\t"%s" "%s"\n' % (t, k, kv[k])
    out += '%s\t"startposition" "[%s %s %s]"\n' % (t, fmt(x + d[0]), fmt(y + d[1]), fmt(z + d[2]))
    for name in ("normals", "distances", "offsets", "offset_normals", "alphas", "triangle_tags", "allowed_verts"):
        if name not in rows:
            continue
        out += '%s\t%s\n%s\t{\n' % (t, name, t)
        for k, row in enumerate(rows[name]):
            if name in ("normals", "offsets", "offset_normals"):
                v = nums(row)
                row = " ".join(" ".join(fmt(round(c, 6)) for c in rot(v[i:i + 3], q)) for i in range(0, len(v) - 2, 3))
            key = ("%d" % 10) if name == "allowed_verts" else "row%d" % k
            out += '%s\t\t"%s" "%s"\n' % (t, key, row)
        out += '%s\t}\n' % t
    return out + '%s}\n' % t


def load(name):
    with open(os.path.join(LIB, name + ".json")) as f:
        return json.load(f)


PLACED = [0]


def solid_text(vmf, sides, q, d, vis, t="\t"):
    """One brush of a piece turned q quarter turns and moved by d: its text and its corners."""
    text = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, vmf.new_id())
    allv = []
    for s in sides:
        pl = [[a + b for a, b in zip(rot(p, q), d)] for p in s["plane"]]
        vs = [[a + b for a, b in zip(rot(p, q), d)] for p in s["verts"]]
        allv += vs or [[a + b for a, b in zip(rot(p, q), d)] for p in s.get("corners", [])] or pl
        text += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, vmf.new_id(), t, " ".join("(%s %s %s)" % tuple(fmt(c) for c in p) for p in pl))
        if vs:
            text += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%s %s %s"\n' % ((t,) + tuple(fmt(c) for c in p)) for p in vs), t)
        text += '%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%s"\n%s\t\t"smoothing_groups" "0"\n' % (
            t, s["material"], t, turn_axis(s["uaxis"], q, d), t, turn_axis(s["vaxis"], q, d), t, t, s["lightmapscale"], t)
        text += (disp_text(s["disp"], q, d, t) if s.get("disp") else "") + "%s\t}\n" % t
    text += vmf.editor(vis, indent=t + "\t") + "%s}\n" % t
    return text, allv


def fade_small(cls, keys):
    """A small unnamed prop of a piece fades far off, as Valve fades a third of theirs (the lint's rule); its skin is kept."""
    if cls.startswith("prop") and keys.get("model") and not keys.get("targetname") and not keys.get("parentname"):
        import map_build
        fade = map_build.prop_fade(keys["model"])
        if fade and str(keys.get("fademindist", "-1")) in ("-1", "") or (fade and str(keys.get("fademaxdist", "0")) in ("0", "")):
            keys.update({"fademindist": str(fade[0]), "fademaxdist": str(fade[1]), "fadescale": "1"})


def corner_box(allv):
    """The box round a placed brush's corners, for the checks only, rounded out to whole units: Valve's slanted faces have
    corners off the grid (their planes' three points are on it), which the brush keeps as it was."""
    import math
    return tuple(math.floor(min(p[k] for p in allv) + 1e-6) for k in range(3)) + tuple(math.ceil(max(p[k] for p in allv) - 1e-6) for k in range(3))


def place(m, name, u, v, z, turn=0, vis=None, props=True, wiring=True, keep_outside=False, keep=None, world=False, portals=False):
    """Put the prefab's anchor at (u, v, z) in the module's frame, turned `turn` quarter turns (anticlockwise seen from
    above) on top of the frame's own turning. Its brushes go in as one func_detail; its props, lights and decals as they
    were (moved and turned with it). `name` may be a piece already loaded (a dict).

    A piece with logic also brings its wiring (unless wiring=False or props=False): each entity with its outputs, its
    moving brushes placed live instead of their slabs. Every name of the piece gets the copy's own ending, in keys and
    outputs alike (an output to `name*` goes to each of the piece's names it matches), so two copies never answer each
    other; the ending is returned in the piece's "placed_as". Areaportals, nodes and the like (NOT_WIRED) stay out: the
    piece never seals, so they are the builder's to place. Outputs and keys naming what the piece does not hold are
    dropped (Valve's story outside it), or kept as they are with keep_outside=True (to wire the copy to things of the
    builder's own of those names). `!player` becomes `!activator` (one player of many is not 'the player'), and every
    output may fire again, as Vmf.wires writes them. keep(e) says which wiring entities go in instead (e: the piece's own entry).
    An ai_relationship naming `!player` names the class `player` instead (every player, not the first to join).
    world=True: the brushes that were the source's world brushes go into the world (they seal and cut the map up for
    visibility, as in the source; the piece's areaportals need them), the rest stay one func_detail. portals=True: the
    piece's own areaportals (`func_areaportal`, `func_areaportalwindow` in its wiring) go in too: only where the builder
    has sealed the piece's areas, or the compile fails. A piece's `nav` (its own path nodes, and node links between them,
    named as the piece's other entities) goes in with its wiring, each node given the build's next node id."""
    pf = name if isinstance(name, dict) else load(name)
    name = pf["name"]
    fr = m.fr
    q = (turn + fr.rot) % 4
    if fr.flip:      # (a flipped frame mirrors; a mirrored brush would turn inside out: turn it the other way round instead)
        q = (q + 2) % 4
    ox, oy = fr.pt(u, v)
    oz = z + fr.dz
    d = (ox, oy, oz)
    vmf = m.b.vmf
    logic = props and wiring and bool(pf.get("wiring") or pf.get("route") or any(p.get("connections") for p in pf["points"]))
    aps = ("func_areaportal", "func_areaportalwindow") if portals else ()
    wires = [w for w in pf.get("wiring", []) if (keep(w) if keep else not unwired(w["classname"]) or w["classname"] in aps)] if logic else []
    # An areaportal window left out leaves its fade brush (the black pane it shows when far) standing for good: out too.
    shades = set(w["keys"].get("target", "").lower() for w in pf.get("wiring", []) if w["classname"] == "func_areaportalwindow" and id(w) not in set(map(id, wires)))
    wires = [w for w in wires if w["keys"].get("targetname", "").lower() not in shades - {""}]
    # A piece's own nodes and hints (a queue's places, say) go in with the build's next node ids, its node links renumbered.
    if logic:
        b, renum, mine = getattr(m, "b", m), {}, []
        for w in pf.get("wiring", []):
            if w["classname"] in NODE_CLASSES:
                nid = getattr(b, "node_id", None) or 1
                b.node_id = nid + 1
                e = json.loads(json.dumps(w))
                renum[str(e["keys"].get("nodeid", ""))] = str(nid)
                e["keys"]["nodeid"] = str(nid)
                mine.append(e)
        for w in pf.get("wiring", []):
            if w["classname"] == "info_node_link" and str(w["keys"].get("StartNode")) in renum and str(w["keys"].get("EndNode")) in renum:
                e = json.loads(json.dumps(w))
                e["keys"]["StartNode"], e["keys"]["EndNode"] = renum[str(w["keys"]["StartNode"])], renum[str(w["keys"]["EndNode"])]
                mine.append(e)
        wires = [w for w in wires if w["classname"] not in NODE_CLASSES + ("info_node_link",)] + mine
    live = set(w["keys"].get("targetname") for w in wires) - {None, ""}
    placed = set(id(w) for w in wires)
    full = pf.get("wiring", [])
    t = "\t"
    text = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % vmf.new_id()
    written = 0
    for sol in pf["solids"]:
        if logic and ((sol.get("wired") is not None and sol["wired"] < len(full) and id(full[sol["wired"]]) in placed)
                      or (sol.get("wired") is None and sol.get("live") in live)):
            continue      # (its moving brush goes in live, with the wiring)
        s_text, allv = solid_text(vmf, sol["sides"], q, d, vis or m.dv, t)
        if world and sol.get("from") == "worldspawn":
            vmf.world.append(s_text)      # (a world brush, as the source had it)
        else:
            text += s_text
            written += 1
        if allv:
            vmf.boxes.append((corner_box(allv), False))
    text += vmf.editor(vis or m.dv, "0 180 0") + "}\n"
    if written:
        vmf.ents.append(text)
    if not props:
        return pf
    PLACED[0] += 1
    tag = "_%s%d" % (name, PLACED[0])      # (each copy's names its own: two copies' doors never open together)
    pf["placed_as"] = tag
    if not logic:
        names = set(p["keys"].get("targetname") for p in pf["points"] if p["keys"].get("targetname"))
        for p in pf["points"]:
            keys = dict(p["keys"])
            for k in NAMED:
                if keys.get(k) in names:
                    keys[k] = keys[k] + tag
            if "angles" in keys:
                a = nums(keys["angles"])
                keys["angles"] = "%s %s %s" % (fmt(a[0]), fmt((a[1] + 90 * q) % 360), fmt(a[2]))
            pos = [a + b for a, b in zip(rot(p["origin"], q), d)]
            fade_small(p["classname"], keys)
            vmf.point(p["classname"], tuple(pos), keys, m.pv if p["classname"].startswith("prop") else m.lv)
        return pf
    place_logic(m, pf, list(pf["points"]) + wires + nav_entities(m, pf), q, d, tag, keep_outside)
    return pf


def nav_entities(m, pf):
    """A piece's own path nodes (`nav`: {"nodes": [[x, y, z]...], "links": [{"from": i, "to": j, "keys": {...}}]}) as
    wiring entries, each node with the build's next node id and each link naming the two nodes' ids (Valve's
    info_node_link joins nodes by id, so the ids are only known as the piece is placed)."""
    nav = pf.get("nav")
    if not nav:
        return []
    b = getattr(m, "b", m)
    ids, out = [], []
    for p in nav.get("nodes", []):
        nid = getattr(b, "node_id", None)
        if nid is None:
            nid = b.node_id = 1
        ids.append(nid)
        b.node_id = nid + 1
        out.append({"classname": "info_node", "origin": list(p), "keys": {"nodeid": str(nid)}, "connections": []})
    for k in nav.get("links", []):
        a, c = nav["nodes"][k["from"]], nav["nodes"][k["to"]]
        keys = dict(k.get("keys", {}))
        keys.update({"StartNode": str(ids[k["from"]]), "EndNode": str(ids[k["to"]])})
        out.append({"classname": "info_node_link", "origin": [(a[i] + c[i]) / 2.0 for i in range(3)], "keys": keys, "connections": []})
    return out


def place_logic(m, pf, ents, q, d, tag, keep_outside=False):
    """A piece's props, lights and wiring (and its route of path points), turned, moved and renamed (see place())."""
    from map_build import Vmf
    vmf = m.b.vmf
    lv = getattr(m, "gv", None) or (getattr(m.b, "vis", "LC") + ": logic")
    for r in pf.get("route", []):
        ents.append({"classname": "path_track", "origin": r["origin"], "connections": r.get("outputs", []),
                     "keys": {"targetname": r["name"], "target": r.get("target", ""), "altpath": r.get("altpath", ""), "speed": r.get("speed", "0"),
                              "spawnflags": r.get("spawnflags", "0"), "orientationtype": r.get("orientationtype", "1"), "angles": r.get("angles", "0 0 0")}})
    names = {}
    for e in ents:
        n = e["keys"].get("targetname", "")
        if n:
            names.setdefault(n.lower(), n)

    def ren(v):
        return names[v.lower()] + tag if v.lower() in names else None
    anchor = pf.get("anchor", [0, 0, 0])
    for e in ents:
        cls = e["classname"]
        keys = {}
        for k, val in e["keys"].items():
            lk = k.lower()
            if lk in NOT_NAMES:
                if lk in ("model", "message", "texture"):
                    keys[k] = val      # (never a name, but kept: a prop placed with its logic lost its model until 23 November)
                continue
            r = ren(val) if val and not val.startswith("!") else None
            if cls == "ai_relationship" and lk in ("target", "subject") and val.lower() == "!player":
                keys[k] = "player"      # (Valve's !player is only the first player to join a server: every player)
            elif r:
                keys[k] = r
            elif val and val.endswith("*") and resolves(val, set(names)):
                keys[k] = val      # (a wildcard over the piece's own names: each copy's names still start the same)
            elif val and not val.startswith("!") and lk != "targetname" and (lk in NAME_KEYS or re.match(r"template\d\d$", lk)):
                if keep_outside:
                    keys[k] = val      # (it names something outside the piece)
            elif (lk in SPOT_KEYS or lk in SPOT_BY_CLASS.get(cls, ())) and val:
                p = nums(val)
                keys[k] = " ".join(fmt(round(c, 2)) for c in [a + b for a, b in zip(rot([p[i] - anchor[i] for i in range(3)], q), d)])
            else:
                keys[k] = val
        outs = []
        for o, rest in e.get("connections", []):
            tgt, inp, val, delay, _ = split_output(rest)
            if tgt.startswith("!"):
                outs.append((o, "!activator" if tgt.lower() == "!player" else tgt, inp, val, delay))
                continue
            hits = resolves(tgt, set(names))
            first = val.split(" ")[0] if val else ""
            if first.lower() in names and inp.lower() != "addoutput":      # (an input whose value names one of the piece's things: SetParent, ForceNPCToActBusy...)
                val = names[first.lower()] + tag + val[len(first):]
            if inp.lower() == "addoutput" and " " in val and ":" in val:      # (an output added at run time names its target in its text)
                head, body = val.split(" ", 1)
                aim, _, more = body.partition(":")
                if aim.lower() in names:
                    val = "%s %s%s:%s" % (head, names[aim.lower()], tag, more)
            if hits:
                outs += [(o, names[h] + tag, inp, val, delay) for h in hits]
            elif keep_outside:
                outs.append((o, tgt, inp, val, delay))
        brushes = e.get("brushes")
        if brushes:
            if keys.get("movedir"):
                a = nums(keys["movedir"])
                keys["movedir"] = "%s %s %s" % (fmt(a[0]), fmt((a[1] + 90 * q) % 360), fmt(a[2]))
            if cls in TURN_AXES and q % 2:      # (a door that tilts about x or y: a quarter turn swaps the axis)
                fx, fy = TURN_AXES[cls]
                f = int(keys.get("spawnflags", "0") or 0)
                for _ in range(q % 4):
                    if f & fx:
                        f = (f & ~fx) | fy
                    elif f & fy:
                        f = ((f & ~fy) | fx) ^ 2
                keys["spawnflags"] = str(f)
            s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (vmf.new_id(), cls)
            for k, val in keys.items():
                s += '\t"%s" "%s"\n' % (k, val)
            if "origin" in e:
                s += '\t"origin" "%s %s %s"\n' % tuple(fmt(round(c, 2)) for c in [a + b for a, b in zip(rot(e["origin"], q), d)])
            s += Vmf.wires(outs)
            for b in brushes:
                b_text, allv = solid_text(vmf, b, q, d, lv)
                s += b_text
                if allv and not all("tools/" in x["material"].lower() for x in b):
                    vmf.boxes.append((corner_box(allv), False))
            s += vmf.editor(lv, "220 30 220") + "}\n"
            vmf.ents.append(s)
            continue
        if "origin" not in e:
            continue
        if "angles" in keys:
            a = nums(keys["angles"])
            keys["angles"] = "%s %s %s" % (fmt(a[0]), fmt((a[1] + 90 * q) % 360), fmt(a[2]))
        pos = [a + b for a, b in zip(rot(e["origin"], q), d)]
        fade_small(cls, keys)
        vmf.point(cls, tuple(pos), keys, m.pv if cls.startswith("prop") else m.lv if cls in KEEP_POINTS else lv, connections=outs)


def check():
    """Lift a small made-up map with logic, place it twice turned, and test what comes out. Prints CHECK PASS or the faults."""
    import tempfile
    from map_modules import Frame, Mod, Build

    def box(x1, y1, z1, x2, y2, z2, mat):
        s = "\tsolid\n\t{\n"
        faces = [((x1, y2, z2), (x2, y2, z2), (x2, y1, z2)), ((x1, y1, z1), (x2, y1, z1), (x2, y2, z1)), ((x1, y2, z2), (x1, y1, z2), (x1, y1, z1)),
                 ((x2, y2, z1), (x2, y1, z1), (x2, y1, z2)), ((x2, y2, z2), (x1, y2, z2), (x1, y2, z1)), ((x2, y1, z1), (x1, y1, z1), (x1, y1, z2))]
        for f in faces:
            s += '\t\tside\n\t\t{\n\t\t\t"plane" "%s"\n\t\t\t"material" "%s"\n\t\t\t"uaxis" "[1 0 0 0] 0.25"\n\t\t\t"vaxis" "[0 -1 0 0] 0.25"\n\t\t}\n' % (
                " ".join("(%d %d %d)" % p for p in f), mat)
        return s + "\t}\n"

    def ent(cls, keys, outs=(), solid=""):
        s = 'entity\n{\n\t"classname" "%s"\n' % cls
        s += "".join('\t"%s" "%s"\n' % kv for kv in keys.items())
        if outs:
            s += "\tconnections\n\t{\n" + "".join('\t\t"%s" "%s"\n' % o for o in outs) + "\t}\n"
        return s + solid + "}\n"
    src = "world\n{\n" + box(0, 0, -16, 512, 512, 0, "CONCRETE/CONCRETEFLOOR001A") + "}\n"
    src += ent("func_door", {"targetname": "gate", "movedir": "0 90 0", "speed": "100", "origin": "256 128 64"},
               [("OnFullyOpen", "snd_gate\x1bPlaySound\x1b\x1b0\x1b-1"), ("OnFullyOpen", "story_relay\x1bTrigger\x1b\x1b2\x1b1")],
               box(192, 120, 0, 320, 136, 128, "METAL/METALDOOR001A"))
    src += ent("trigger_once", {"targetname": "trig_gate", "spawnflags": "1"}, [("OnStartTouch", "gate*\x1bOpen\x1b\x1b0\x1b1"), ("OnStartTouch", "!player\x1bSpeakResponseConcept\x1bhi\x1b0\x1b-1")],
               box(200, 160, 0, 300, 260, 96, "TOOLS/TOOLSTRIGGER"))
    src += ent("ambient_generic", {"targetname": "snd_gate", "message": "doors.move1", "origin": "256 140 64", "SourceEntityName": "gate"})
    src += ent("prop_dynamic", {"targetname": "lamp_gate", "parentname": "gate", "model": "models/props_c17/light_cagelight01_on.mdl", "origin": "256 140 120", "angles": "0 0 0"},
               [("OnUser1", "snd_gate,StopSound,,0,-1")])
    src += ent("logic_relay", {"targetname": "far_relay", "origin": "2000 0 0"}, [("OnTrigger", "gate\x1bClose\x1b\x1b0\x1b-1")])
    src += ent("info_node", {"origin": "100 100 0"})
    src += ent("logic_relay", {"targetname": "story_relay", "origin": "3000 0 0"})
    tmp = tempfile.mkdtemp(prefix="lc_prefab_check_")
    path = os.path.join(tmp, "src.vmf")
    with open(path, "w") as f:
        f.write(src)
    faults = []

    def want(ok, what):
        if not ok:
            faults.append(what)
    pf = extract(path, "check_gate", (0, 0, -16, 512, 512, 512), anchor=(256, 128, 0), lib=tmp)
    w = dict((e["classname"], e) for e in pf.get("wiring", []))
    want(set(w) == {"func_door", "trigger_once", "ambient_generic"}, "wiring holds the door, the trigger and the sound only: %s" % sorted(w))
    want(w.get("func_door", {}).get("origin") == [0, 0, 64], "the door's origin is moved to the anchor: %s" % w.get("func_door", {}).get("origin"))
    want(["OnFullyOpen", "story_relay,Trigger,,2,1"] in w.get("func_door", {}).get("connections", []), "outputs kept in the comma form with their times")
    want(len(pf["points"]) == 1 and pf["points"][0].get("connections") == [["OnUser1", "snd_gate,StopSound,,0,-1"]], "a prop keeps its outputs")
    slabs = [s for s in pf["solids"] if s.get("live") == "gate"]
    want(len(slabs) == 1 and "taken shut" in slabs[0]["from"], "the door is also a slab taken shut")
    want(not any("toolstrigger" in x["material"].lower() for s in pf["solids"] for x in s["sides"]), "the trigger is not a slab")
    want([o["name"] for o in pf.get("outside", [])] == ["story_relay"] and pf["outside"][0]["found"] == [{"classname": "logic_relay", "origin": [3000, 0, 0]}],
         "outside names story_relay where it is: %s" % pf.get("outside"))
    want([f["name"] for f in pf.get("fired_from_outside", [])] == ["far_relay"], "far_relay fires into the piece: %s" % pf.get("fired_from_outside"))
    b = Build("prefab_check", 784, 9000)
    m = Mod(b, Frame(0, 0, 0, 64), "prefab")
    a1 = place(m, pf, 0, 0, 0, 0)["placed_as"]
    old = json.loads(json.dumps(pf))      # (an areaportal, as older pieces hold: never placed)
    old["wiring"].append({"classname": "func_areaportal", "keys": {"targetname": "ap", "target": "gate"}, "connections": [], "brushes": [old["wiring"][0]["brushes"][0]]})
    a2 = place(m, old, 1024, 0, 0, 1)["placed_as"]
    text = b.vmf.text()
    for tag in (a1, a2):
        want(text.count('"targetname" "gate%s"' % tag) == 1, "copy %s has its own door" % tag)
        want(text.count('"gate%s\x1bOpen' % tag) == 1 and text.count('"snd_gate%s\x1bPlaySound' % tag) == 1, "the trigger's gate* reaches its own door only, the door its own sound (%s)" % tag)
        want('"parentname" "gate%s"' % tag in text and '"SourceEntityName" "gate%s"' % tag in text, "keys naming the door follow the copy (%s)" % tag)
    want("story_relay" not in text and "!player" not in text and "!activator\x1bSpeakResponseConcept" in text, "outputs outside the piece dropped, !player made !activator")
    want(text.count("METAL/METALDOOR001A") == 12 and text.count('"classname" "func_door"') == 2, "each door placed live once, its slab left out")
    want('"movedir" "0 180 0"' in text, "a turned copy's door moves turned")
    want(text.count('"model" "models/props_c17/light_cagelight01_on.mdl"') == 2, "a prop placed with its logic keeps its model")
    want(text.count('"classname" "info_node"') == 0 and "func_areaportal" not in text, "the map's nodes and areaportals stay out")
    b2 = Build("prefab_check2", 784, 9000)
    m2 = Mod(b2, Frame(0, 0, 0, 64), "prefab")
    place(m2, json.loads(json.dumps(pf)), 0, 0, 0, 0, wiring=False)
    t2 = b2.vmf.text()
    want(t2.count("METAL/METALDOOR001A") == 6 and '"func_door"' not in t2 and "trigger_once" not in t2, "wiring=False places the slab and no logic")
    pf4 = extract(path, "check_gate4", (0, 0, -16, 512, 512, 512), anchor=(256, 128, 0), lib=tmp, with_names=("story_*",), without=("snd_gate", "trigger_once"))
    w4 = dict((e["classname"], e) for e in pf4.get("wiring", []))
    want("ambient_generic" not in w4 and "trigger_once" not in w4 and "func_door" in w4, "--without leaves out by name and by class: %s" % sorted(w4))
    want(any(e["keys"].get("targetname") == "story_relay" for e in pf4["wiring"]) and not any(o["name"] == "story_relay" for o in pf4.get("outside", [])),
         "--with wires a named entity outside the box")
    b3 = Build("prefab_check3", 784, 500)      # (23 November: every player, world brushes, portals and nodes, for the Combine autogun)
    m3 = Mod(b3, Frame(0, 0, 0, 64), "prefab")
    more = json.loads(json.dumps(pf))
    more["wiring"].append({"classname": "ai_relationship", "origin": [0, 0, 0], "keys": {"subject": "gate_finder", "target": "!player", "disposition": "1"}, "connections": []})
    more["wiring"].append({"classname": "func_areaportalwindow", "keys": {"targetname": "apw", "target": "gate"}, "connections": [], "brushes": [more["wiring"][0]["brushes"][0]]})
    more["nav"] = {"nodes": [[0, -64, 16], [0, 64, 16]], "links": [{"from": 0, "to": 1, "keys": {"targetname": "gate_link", "initialstate": "0"}}]}
    more["wiring"][0]["connections"].append(["OnFullyOpen", "gate_link,TurnOn,,0,-1"])
    tag3 = place(m3, more, 0, 0, 0, 0, world=True, portals=True)["placed_as"]
    t3 = b3.vmf.text()
    want('"target" "player"' in t3 and "!player" not in t3, "an ai_relationship's !player names every player")
    want(t3.count('"classname" "func_areaportalwindow"') == 1, "portals=True places the piece's areaportals")
    want('"nodeid" "500"' in t3 and '"nodeid" "501"' in t3 and '"StartNode" "500"' in t3 and '"EndNode" "501"' in t3 and b3.node_id == 502,
         "the piece's nodes take the build's ids and its link names them")
    want('"gate_link%s\x1bTurnOn' % tag3 in t3, "the piece's node link is named as its own")
    b5 = Build("prefab_check5", 784, 600)      # (23 November: places, wildcards, run-time outputs, fade panes)
    m5 = Mod(b5, Frame(0, 0, 0, 64), "prefab")
    five = json.loads(json.dumps(pf))
    five["wiring"] += [
        {"classname": "phys_lengthconstraint", "origin": [0, 0, 0], "keys": {"attach2": "gate", "attachpoint": "266 138 10"}, "connections": []},
        {"classname": "phys_motor", "origin": [0, 0, 0], "keys": {"attach1": "gate", "axis": "256 128 100"}, "connections": []},
        {"classname": "filter_activator_name", "origin": [0, 0, 0], "keys": {"targetname": "only_gates", "filtername": "gate*"}, "connections": []},
        {"classname": "logic_relay", "origin": [0, 0, 0], "keys": {"targetname": "add_relay"}, "connections": [["OnTrigger", "trig_gate,AddOutput,OnStartTouch snd_gate:PlaySound::0:-1,0,-1"]]},
        {"classname": "func_areaportalwindow", "keys": {"targetname": "apw2", "target": "pane"}, "connections": [], "brushes": [five["wiring"][0]["brushes"][0]]},
        {"classname": "func_brush", "keys": {"targetname": "pane"}, "connections": [], "brushes": [five["wiring"][0]["brushes"][0]]}]
    tag5 = place(m5, five, 1000, 0, 0, 1)["placed_as"]
    t5 = b5.vmf.text()
    want('"attachpoint" "990 10 10"' in t5 and '"axis" "1000 0 100"' in t5, "constraint ends and motor axes move and turn with the piece")
    want('"filtername" "gate*"' in t5, "a wildcard key over the piece's names is kept")
    want("OnStartTouch snd_gate%s:PlaySound" % tag5 in t5, "a run-time output names the copy's own target")
    want('"targetname" "pane%s"' % tag5 not in t5, "an areaportal window's fade pane stays out with it")
    b6 = Build("prefab_check6", 784, 700)
    m6 = Mod(b6, Frame(0, 0, 0, 64), "prefab")
    six = json.loads(json.dumps(pf))
    six["wiring"] += [{"classname": "info_node_hint", "origin": [0, 0, 16], "keys": {"targetname": "spot1", "nodeid": "42", "hinttype": "0"}, "connections": []},
                      {"classname": "info_node", "origin": [64, 0, 16], "keys": {"nodeid": "43"}, "connections": []},
                      {"classname": "info_node_link", "origin": [32, 0, 16], "keys": {"StartNode": "42", "EndNode": "43"}, "connections": []},
                      {"classname": "logic_relay", "origin": [0, 0, 0], "keys": {"targetname": "go"}, "connections": [["OnTrigger", "lamp_gate,SetParent,spot1,0,-1"]]}]
    tag6 = place(m6, six, 0, 0, 0, 0)["placed_as"]
    t6 = b6.vmf.text()
    want('"nodeid" "700"' in t6 and '"nodeid" "701"' in t6 and '"StartNode" "700"' in t6 and '"EndNode" "701"' in t6 and '"targetname" "spot1%s"' % tag6 in t6,
         "a piece's own nodes and hints take the build's ids, its links follow")
    want("SetParent\x1bspot1%s" % tag6 in t6, "an input's value naming the piece's thing names the copy's")
    want("CONCRETE/CONCRETEFLOOR001A" in t3.split('"classname" "worldspawn"')[1].split("\nentity\n")[0], "world=True puts the source's world brushes in the world")
    for f in faults:
        print("  FAULT: " + f)
    print("CHECK %s" % ("PASS" if not faults else "FAIL (%d)" % len(faults)))
    return not faults


def main():
    ap = argparse.ArgumentParser(description="Pieces of the owner's City 18, lifted out and placed again.")
    sub = ap.add_subparsers(dest="cmd")
    e = sub.add_parser("extract")
    e.add_argument("vmf")
    e.add_argument("name")
    e.add_argument("box", nargs=6, type=float)
    e.add_argument("--anchor", nargs=3, type=float)
    e.add_argument("--note", default="")
    e.add_argument("--wire-box", nargs=6, type=float, help="a bigger box for the logic (default: the piece's box)")
    e.add_argument("--drop", nargs="*", default=[])
    e.add_argument("--centroid", action="store_true")
    e.add_argument("--force", nargs="*", default=[])
    e.add_argument("--keep-nodraw", action="store_true", help="keep the source's plain nodraw blocks (the shell a cave is shut in with)")
    e.add_argument("--portals", action="store_true", help="keep the source's areaportals in the wiring (placed only with place(..., portals=True))")
    e.add_argument("--clips", action="store_true", help="keep the source's player clips as brushes")
    e.add_argument("--with", dest="with_names", nargs="*", default=[], help="names (wildcards) wired wherever they stand in the map")
    e.add_argument("--without", nargs="*", default=[], help="names or classes (wildcards) left out altogether: the source's story")
    sub.add_parser("list")
    s = sub.add_parser("show")
    s.add_argument("name")
    s.add_argument("--out")
    s.add_argument("--no-wiring", action="store_true", help="leave the logic out (moving brushes as slabs)")
    sub.add_parser("check")
    a = ap.parse_args()
    if a.cmd == "extract":
        pf = extract(a.vmf, a.name, a.box, a.anchor, a.note, a.wire_box, drop=tuple(m.lower() for m in a.drop), centroid=a.centroid, force=tuple(a.force), keep_nodraw=a.keep_nodraw,
                     portals=a.portals, clips=a.clips, with_names=tuple(a.with_names), without=tuple(a.without))
        nd = sum(1 for sol in pf["solids"] for sd in sol["sides"] if sd.get("disp"))
        print("%s: %d brushes (%d displaced faces), %d props/lights/decals, %d wired (%d names outside, %d firing in), %d by %d by %d" % (
            a.name, len(pf["solids"]), nd, len(pf["points"]), len(pf.get("wiring", [])), len(pf.get("outside", [])), len(pf.get("fired_from_outside", [])),
            pf["size"][0], pf["size"][1], pf["size"][2]))
    elif a.cmd == "list":
        for f in sorted(os.listdir(LIB)) if os.path.isdir(LIB) else []:
            if f.endswith(".json"):
                pf = load(f[:-5])
                print("%-26s %4d brushes %3d things  %5d x %5d x %5d  %s" % (pf["name"], len(pf["solids"]), len(pf["points"]), pf["size"][0], pf["size"][1], pf["size"][2], pf["note"]))
    elif a.cmd == "show":
        from map_modules import Frame, Mod, Build
        b = Build("prefab_" + a.name, 784, 9000)
        m = Mod(b, Frame(0, 0, 0, 64), "prefab")
        place(m, a.name, 0, 0, 0, wiring=not a.no_wiring)
        out = a.out or "lc_prefab_%s.vmf" % a.name
        with open(out, "w") as f:
            f.write(b.vmf.text())
        print("written: " + out)
    elif a.cmd == "check":
        sys.exit(0 if check() else 1)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
