#!/usr/bin/env python3
"""
Living City: the map builder (for the owner's PC, never the server)

The owner, 19 November: "It is SO labor intensive to do all the menial map building ... I wanted
to add more of an 'edge of city' or even outside of city area to the map for the resistance to
hide in the woods outside the city, or in the canals."

This writes a NEW, separate VMF for one piece of map (it never opens or changes the owner's own
VMF). The owner brings the piece in with a func_instance at 0 0 0, or with Paste Special at no
offset, looks at it in Hammer++, and compiles. Everything is in visgroups of its own, so it can
be hidden or deleted in one click.

    python3 map_build.py canal            writes lc_canal.vmf here
    python3 map_build.py canal --out FILE

A piece is drawn on a 64-unit grid seen from above: every square is open (a floor at some
height, under the sky or under a ceiling) or solid. From that it makes: a floor block under every
open square, a sky lid over it, and a solid block in every square that touches an open one, so
the piece is sealed by the way it is made. Squares that are alike are joined into big brushes.
Then it checks itself: every corner on the grid, and a flood from outside that must not reach
the air inside (the one opening, onto the city, is stopped up for the check). Only the owner's
compile is the proof.

The first piece, "canal" (the owner: at the skybox brush that ends the road at 3648 1864, "a
standard HL2 Route Kanal size ... not filled with water, that runs for a bit then turns and
maybe even forks and maybe dumps out to a forest"): a quay at the road's end, stairs down, a dry
canal 512 wide and 256 deep running east, a turn north, a fork (one arm ends at a barred tunnel
mouth, the other is capped where the forest will join), a low bay to hide in, two beams across.
"""

import argparse
import bisect
import math
import random
import re

# Doors an areaportal may be linked to: ones nobody can see through (Valve never shuts a portal behind bars or glass).
SOLID_DOORS = ("models/props_c17/door01_left.mdl", "models/props_c17/door01_right.mdl", "models/props_c17/door02_double.mdl")
SEE_THROUGH = ("bar", "glass", "fence", "grate", "window", "cage", "chain", "mesh", "grill")
import sys

CELL = 64

# The engine's path node limit is for a whole map, flying nodes and hints counted (the owner, 21 November: "mind the
# engine's node limit"): City 18 already has about 1826 walking and 580 flying, and our pieces are merged into it, so
# each piece has a share of what is left (1690), and its nodes are thinned to fit (map_ring.lane_cells, NODE_LEVELS).
NODE_CAP, CITY18_NODES = 4096, 2406
# (22 November: the canal ring's two halves take the old ring's and the old south sketch's 600 and the 40 left over;
#  the old ring, map_ring.py, is what the canal ring replaces: built by itself it is held to NODE_SHARE_OTHER)
NODE_SHARES = {"canal": 150, "ring": 640, "forest_bunker": 150, "forest_cave": 270, "ravenholm": 150, "town": 330}
NODE_SHARE_OTHER = 400      # (a layout not planned for the merge yet: kept to a piece's size all the same)
NODE_CLASSES = ("info_node", "info_node_air", "info_node_hint", "info_node_air_hint", "info_node_climb")


def standing_prop(model):
    """The class and keys for a model that stands still: a prop_static only when the model was built to be one and is
    no physics prop (the compiler deletes those: the owner, "tons of the static props you put in aren't showing in the
    compiled map"; lesson physics-props-dynamic), a prop_dynamic_override for a physics model, a prop_dynamic else (as
    the modules' m.static does, from map_assets' facts)."""
    import map_assets
    keys = {"skin": "0", "solid": "6", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
    if map_assets.is_static(model) is not False:
        keys.update({"disableshadows": "0", "screenspacefade": "0"})
        return "prop_static", keys
    keys.update({"disableshadows": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})
    return ("prop_dynamic_override" if map_assets.is_physics_prop(model) else "prop_dynamic"), keys


def stand_z(model, z, pitch=0, roll=0):
    """The height to put a model's origin at for it to stand ON z: many models have their origin at their middle
    (tables, couches, lockers, the lorry), so placed at the floor they are half in it. Read from the model's own box
    (map_assets.size), turned by pitch and roll (a thing lying on its side stands on its side); a model whose size is
    not known is put at z itself. The modules' m.stand and the older pieces (canal, ring, forests, Ravenholm) both
    use this."""
    import map_assets
    bb = map_assets.size(model)
    if not bb:
        return z
    sp, cp = math.sin(math.radians(pitch)), math.cos(math.radians(pitch))
    sr, cr = math.sin(math.radians(roll)), math.cos(math.radians(roll))
    low = min(-sp * x + sr * cp * y + cr * cp * h for x in (bb[0], bb[3]) for y in (bb[1], bb[4]) for h in (bb[2], bb[5]))
    return z - int(math.floor(low + 1e-6))


# Props the way Valve dresses them (docs/dev/valve-prop-notes.md, 8,951 props in 22 maps; the owner said go ahead, 21
# November): a mix of skins on things that come in several, small things that fade far off, loose things turned off
# the square, asleep until touched, and small junk that players walk through (debris).
SKIN_KINDS = ("oildrum", "crate", "container", "glassbottle", "popcan", "trashcluster", "/car00", "van001", "truck001", "coolingtank", "armchair",
              "radiator", "concrete_barrier", "wood_fence", "rockgranite", "bicycle")      # (of the 304 models with skins: those whose skins are only looks)
NO_SKIN = ("light", "lamp", "door", "sign", "combine", "monitor", "screen", "button", "keypad", "_on.", "_off.", "explosive", "clock", "tv", "radio",
           "poster", "lever", "valve")
DEBRIS = ("garbage", "trash", "popcan", "bottle", "paper", "cardboard", "box01", "box02", "shoe", "doll", "bucket", "cinderblock", "props_junk/glass",
          "plasticcrate", "milkcarton", "takeout", "tincan", "garbage_")


def _stable(*parts):
    """A number from these parts, the same every build (Python's own hash of a string changes from run to run)."""
    import zlib
    return zlib.crc32(" ".join(str(p) for p in parts).encode())


def prop_skin(model, x, y):
    """A skin for a model that comes in several, as Valve mixes them (oil drums 45% not skin 0, containers 69%, crates
    33%): half of them skin 0, the rest one of the others, the same every build for one place. "0" for a model with one
    skin (map_skins.count) or whose skins mean something (a lamp lit or not, a door, a sign, a screen)."""
    import map_skins
    m = model.lower()
    n = map_skins.count(m)
    if n < 2 or not any(k in m for k in SKIN_KINDS) or any(k in m for k in NO_SKIN):
        return "0"
    h = _stable(m, int(x), int(y))
    return "0" if h % 2 == 0 else str(1 + (h >> 1) % (n - 1))


def prop_fade(model):
    """Valve's fades for a small thing (their medians: tiny 1024 to 1500, small 1900 to 2500; a third of props have one),
    as (start, end); None for anything 64 or bigger, a lamp (its light would stay) or a model of unknown size."""
    import map_assets
    m = model.lower()
    bb = map_assets.size(m)
    if not bb or "light" in m or "lamp" in m:
        return None
    big = max(bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2])
    return (1024, 1500) if big < 24 else (1900, 2500) if big < 64 else None


def loose_yaw(model, x, y, yaw):
    """A loose thing set square (a yaw on the exact 90s) is turned 3 to 17 degrees three times in five, as Valve's are
    (41% of their physics props are square, 34% turned 1 to 20); the same every build for one place."""
    if yaw % 90:
        return yaw
    h = _stable(model.lower(), int(x), int(y), "turn")
    if h % 5 >= 3:
        return yaw
    turn = 3 + (h >> 3) % 15
    return yaw + (turn if (h >> 8) & 1 else -turn)


def loose_flags(model):
    """Valve's physics prop flags for a thing left lying about: 1 asleep until something touches it (it was put down at
    rest: the server need not move it), and 4 debris for small junk (players and other junk pass through it)."""
    return str(1 + (4 if any(k in model.lower() for k in DEBRIS) else 0))


def dress_keys(model, x, y, keys):
    """A prop's keys with Valve's skin mix and small-thing fade added (prop_skin, prop_fade), as the modules' m.prop
    does: for the older pieces' own prop helpers. A skin or fade already in keys, a name or a parent is kept as it is."""
    k = dict(keys)
    if k.get("skin", "0") == "0":
        k["skin"] = prop_skin(model, x, y)
    fade = prop_fade(model)
    if fade and str(k.get("fademindist", "-1")) == "-1" and not k.get("targetname") and not k.get("parentname"):
        k.update({"fademindist": str(fade[0]), "fademaxdist": str(fade[1]), "fadescale": "1"})
    return k


WAY_EXEMPT = ("canal_bars002", "struts_tunnel", "struts_wall", "light_cagelight", "missile_doors", "freightelevatorbutton", "control_lever", "trappropeller_lever",
              "models/lc/kit/lc_cwall")     # (arches over the way, their middle open; lamps hung overhead; Silo 2's leaves, the bunker door's, which slide out of the way and stand rolled upright and scaled, past what this box can turn; the Combine wall's models, map_corridor.combine_wall, standing on its core where its brushes stood, a player clip their collision)


def prop_box(model, pos, yaw):
    """A prop's real box in the map (x1 y1 z1 x2 y2 z2): its model's own size (asset_facts.json) turned by its yaw, or None."""
    import map_assets
    b = map_assets.size(model)
    if not b:
        return None
    c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    xs = [pos[0] + x * c - y * sn for x in (b[0], b[3]) for y in (b[1], b[4])]
    ys = [pos[1] + x * sn + y * c for x in (b[0], b[3]) for y in (b[1], b[4])]
    return (min(xs), min(ys), pos[2] + b[2], max(xs), max(ys), pos[2] + b[5])


def ways_problems(vmf):
    """Every prop against every space kept clear (Vmf.keep_way_clear) and every hinged door's swing: the prop's box from
    its model's own size (asset_facts.json via map_assets.size), turned by its yaw. A door is meant to stand in its own
    doorway and is not counted; nor are WAY_EXEMPT models. One line per prop and way it blocks."""
    import map_assets
    ways = list(vmf.ways) + [(box, "the swing of the door at (%d %d %d)" % tuple((box[k] + box[k + 3]) / 2 for k in range(3)))
                             for _, box, _ in getattr(vmf, "door_ents", [])]
    out = []
    for cls, pos, model, yaw in vmf.props:
        if cls == "prop_door_rotating" or any(k in model for k in WAY_EXEMPT):
            continue
        b = map_assets.size(model)
        if not b:
            continue
        c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        xs = [pos[0] + x * c - y * sn for x in (b[0], b[3]) for y in (b[1], b[4])]
        ys = [pos[1] + x * sn + y * c for x in (b[0], b[3]) for y in (b[1], b[4])]
        for box, label in ways:
            x1, y1, z1, x2, y2, z2 = box
            if min(xs) < x2 and max(xs) > x1 and min(ys) < y2 and max(ys) > y1 and pos[2] + b[2] < z2 and pos[2] + b[5] > z1:
                out.append("%s (%d by %d) at (%d %d %d) stands in the way at %s" % (
                    model.rsplit("/", 1)[-1], max(xs) - min(xs), max(ys) - min(ys), pos[0], pos[1], pos[2], label))
    return out


def node_share(name):
    """How many path nodes (walking, flying and hints) a piece may have: its share, or None for one module by itself."""
    if name.startswith("mod_"):
        return None
    return NODE_SHARES.get(name, NODE_SHARE_OTHER)


def node_report(vmf, name):
    """Count a piece's path nodes and say what they would do to the merged map. Gives (the line to print, a LOOK line
    or None): a LOOK when the piece is over its share, or when with City 18 and the other planned pieces' shares the
    merged map would come within a tenth of the engine's limit."""
    count = {}
    for cls, _ in vmf.points:
        if cls in NODE_CLASSES:
            count[cls] = count.get(cls, 0) + 1
    n = sum(count.values())
    if not n:
        return None, None
    others = sum(v for k, v in NODE_SHARES.items() if k != name) if name in NODE_SHARES else 0
    merged = CITY18_NODES + others + n
    share = node_share(name)
    line = "path nodes: %d (%d walking, %d flying, %d hints); its share %s; merged with City 18 (%d)%s: %d of the engine's %d" % (
        n, count.get("info_node", 0), count.get("info_node_air", 0), count.get("info_node_hint", 0), share if share is not None else "none (one module)",
        CITY18_NODES, " and the other pieces' shares" if others else "", merged, NODE_CAP)
    look = None
    if share is not None and n > share:
        look = "nodes: %d path nodes, over this piece's share of %d (NODE_SHARES in map_build.py): thin them or give it a bigger share" % (n, share)
    elif merged > (NODE_CAP if others else NODE_CAP * 0.9):      # (the planned pieces' shares are made to fill what City 18 leaves)
        look = "nodes: with City 18%s the merged map would have %d path nodes, %s the engine's %d" % (
            " and the other pieces" if others else "", merged, "over" if merged > NODE_CAP else "near", NODE_CAP)
    return line, look
GATE_WIDE, GATE_HIGH = 512, 256 # a gate: the culvert every piece ends in, so any two pieces join

# what things are made of: all of these are already used in the owner's own VMF, so they exist
MAT = {
    "canal_wall": "concrete/concretewall064a",
    "canal_floor": "concrete/concretefloor026a",
    "quay_floor": "concrete/concretefloor013a",
    "upper_wall": "brick/brickwall045d",
    "ceiling": "concrete/concreteceiling004a",
    "stairs": "concrete/concretestair005a",
    "beam": "concrete/concretewall036a",
    "bars": "metal/metalpipe001a",
    "sky": "tools/toolsskybox",
    "nodraw": "tools/toolsnodraw",
    "black": "tools/toolsblack",
    "mud": "nature/blendmuddirt001a",   # hl2: mud, blending to dirt
    "clip": "tools/toolsplayerclip",
    "origin": "tools/toolsorigin",
    "portal": "tools/toolsareaportal",
    "trigger": "tools/toolstrigger",
    "fence": "metal/metalfence007a",    # hl2: chain link
}


# ---------------------------------------------------------------------------
# Writing a VMF
# ---------------------------------------------------------------------------

# A box's six faces: for each, the two directions across it (U then V, with U x V pointing out of the
# box). Its corners go p0, p0+V, p0+U+V, p0+U: clockwise seen from outside, which is how Hammer++ writes them.
FACE_ORDER = ("top", "bottom", "west", "east", "north", "south")
FACE_UV = {"top": (0, 1), "bottom": (1, 0), "east": (1, 2), "west": (2, 1), "north": (2, 0), "south": (0, 2)}
FACE_SIDE = {"top": (2, 1), "bottom": (2, 0), "east": (0, 1), "west": (0, 0), "north": (1, 1), "south": (1, 0)} # (axis, 0 low or 1 high)
FACE_NORMAL = {"top": (0, 0, 1), "bottom": (0, 0, -1), "east": (1, 0, 0), "west": (-1, 0, 0), "north": (0, 1, 0), "south": (0, -1, 0)}
FACE_AXES = {"top": ("[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"), "bottom": ("[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"),
             "east": ("[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"), "west": ("[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"),
             "north": ("[1 0 0 0] 0.25", "[0 0 -1 0] 0.25"), "south": ("[1 0 0 0] 0.25", "[0 0 -1 0] 0.25")}


def face_corners(box, name):
    lo, hi = box[:3], box[3:]
    axis, high = FACE_SIDE[name]
    u, v = FACE_UV[name]
    p0 = list(lo)
    p0[axis] = hi[axis] if high else lo[axis]
    p1, p2, p3 = list(p0), list(p0), list(p0)
    p1[v] = hi[v]
    p2[v] = hi[v]
    p2[u] = hi[u]
    p3[u] = hi[u]
    return tuple(p0), tuple(p1), tuple(p2), tuple(p3)


def _num(v):
    s = "%.4f" % v
    s = s.rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def disp_text(p, spec, t, record=None):
    """The dispinfo block for a face with corners p (p0 first): every point of its grid moved to target(i, j).
    record(edge points, quads folded back on themselves, quads) is told what was made, for the checks."""
    power, target, alpha = spec
    n = 2 ** power
    p0, p1, p2, p3 = p
    rows_n, rows_d, rows_a, rows_t = [], [], [], []
    pts = {}
    for i in range(n + 1):
        ns, ds, al = [], [], []
        for j in range(n + 1):
            base = [p0[k] + (p1[k] - p0[k]) * i / n + (p3[k] - p0[k]) * j / n for k in range(3)]
            to = target(i, j)
            pts[(i, j)] = to
            d = [to[k] - base[k] for k in range(3)]
            ln = (d[0] * d[0] + d[1] * d[1] + d[2] * d[2]) ** 0.5
            if ln < 0.001:
                ns.append("0 0 1")
                ds.append("0")
            else:
                ns.append("%s %s %s" % (_num(d[0] / ln), _num(d[1] / ln), _num(d[2] / ln)))
                ds.append(_num(ln))
            al.append(_num(max(0.0, min(255.0, alpha(i, j)))) if alpha else "0")
        rows_n.append(" ".join(ns))
        rows_d.append(" ".join(ds))
        rows_a.append(" ".join(al))
    for i in range(n):
        tags = []
        for j in range(n):
            # (9: flat enough to walk and build on; 0: too steep. Hammer works these out again itself.)
            a, b, c = pts[(i, j)], pts[(i + 1, j)], pts[(i, j + 1)]
            e1 = [b[k] - a[k] for k in range(3)]
            e2 = [c[k] - a[k] for k in range(3)]
            nx, ny, nz = e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0]
            ln = (nx * nx + ny * ny + nz * nz) ** 0.5 or 1.0
            tag = "9" if abs(nz) / ln > 0.7 else "0"
            tags += [tag, tag]
        rows_t.append(" ".join(tags))
    if record:
        # (a quad is folded when it faces the other way from the face it was hung on)
        fn = [(p3[(k + 1) % 3] - p0[(k + 1) % 3]) * (p1[(k + 2) % 3] - p0[(k + 2) % 3]) - (p3[(k + 2) % 3] - p0[(k + 2) % 3]) * (p1[(k + 1) % 3] - p0[(k + 1) % 3]) for k in range(3)]
        folded = 0
        for i in range(n):
            for j in range(n):
                a, b, c = pts[(i, j)], pts[(i, j + 1)], pts[(i + 1, j)]
                e1 = [b[k] - a[k] for k in range(3)]
                e2 = [c[k] - a[k] for k in range(3)]
                q = (e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0])
                if q[0] * fn[0] + q[1] * fn[1] + q[2] * fn[2] < 0:
                    folded += 1
        record([pts[(i, j)] for i in range(n + 1) for j in range(n + 1) if i in (0, n) or j in (0, n)], folded, n * n)
    zero = " ".join(["0 0 0"] * (n + 1))
    up = " ".join(["0 0 1"] * (n + 1))

    def block(name, rows):
        return '%s%s\n%s{\n%s%s}\n' % (t + "\t", name, t + "\t", "".join('%s\t\t"row%d" "%s"\n' % (t, k, r) for k, r in enumerate(rows)), t + "\t")
    s = '%sdispinfo\n%s{\n%s\t"power" "%d"\n%s\t"startposition" "[%d %d %d]"\n%s\t"flags" "0"\n%s\t"elevation" "0"\n%s\t"subdiv" "0"\n' % (
        t, t, t, power, t, p0[0], p0[1], p0[2], t, t, t)
    s += block("normals", rows_n) + block("distances", rows_d) + block("offsets", [zero] * (n + 1)) + block("offset_normals", [up] * (n + 1))
    s += block("alphas", rows_a) + block("triangle_tags", rows_t)
    s += '%s\tallowed_verts\n%s\t{\n%s\t\t"10" "-1 -1 -1 -1 -1 -1 -1 -1 -1 -1"\n%s\t}\n%s}\n' % (t, t, t, t, t)
    return s


# Valve's building craft (docs/dev/valve-craft-notes.md, 22 maps; the owner said go ahead, 21 November), done to every
# face our builder lays as the file is written (faces copied exactly from a map of the owner's or Valve's are left be):
#   lightmapscale  8 on stairs, rails, ladders and bars no longer than 256 (Valve: 3 to 10% of faces, on stairs, rails,
#                  trims); 64 on a face more than 1024 from every path node (far from play), and on a displacement more
#                  than 256 from one; 32 on other displacements and on a strip 16 or less across and over 496 long (a
#                  pipe, a rail: vbsp cuts a face every 31 luxels, and every cut adds vertices, which have a limit of
#                  65,536: the owner's compile, 24 November, stopped at 70,769); 16 for the rest
#   texture scale  0.5 on the canal's concrete walls (Valve's canal concrete: 0.5 on 53 to 90% of it), not 0.25
#   seams          a wall's texture starts at its foot: every upright face is shifted so a texture's edge lies where
#                  the stack of faces of its material in its plane stands (Valve: 54 to 56% on a seam; ours, chance)
LMS_FINE = ("stair", "rail", "metalpipe", "handrail", "ladder")
SCALE_HALF = ("concrete/concretewall064a",)        # (MAT["canal_wall"]: the canal's concrete)
CRAFT_SIDE = re.compile(r'(vertices_plus\n\t*\{\n)((?:\t*"v" "[^"]+"\n)+)(\t*\}\n\t*"material" ")([^"]+)("\n\t*"uaxis" ")([^"]+)("\n\t*"vaxis" ")([^"]+)'
                        r'("\n\t*"rotation" "0"\n\t*"lightmapscale" ")@(\d+)("\n\t*"smoothing_groups" "0"\n)(\t*dispinfo)?')


def _axis(a):
    """'[x y z shift] scale' -> ([x, y, z], shift, scale)."""
    m = re.match(r"\[\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*\]\s*(\S+)", a)
    return [float(m.group(k)) for k in (1, 2, 3)], float(m.group(4)), float(m.group(5))


def foot_of(w, n, boxes, grid):
    """Where a wall (w: its box, n: the way it faces) shows above the floor in front of it: the lowest top of a brush
    standing against it that is above its own bottom (a wall's brush often runs down under the floor); its own bottom
    when nothing stands against it, or when it does not face along x or y."""
    ax = 0 if abs(n[0]) > 0.99 else 1 if abs(n[1]) > 0.99 else None
    if ax is None:
        return w[2]
    plane, side, other = w[ax], (1 if n[ax] > 0 else -1), 1 - ax
    best = None
    seen = set()
    for i in range(int((w[0] - 1) // 256), int((w[3] + 1) // 256) + 1):
        for j in range(int((w[1] - 1) // 256), int((w[4] + 1) // 256) + 1):
            for b in grid.get((i, j), ()):
                if id(b) in seen:
                    continue
                seen.add(id(b))
                infront = (b[ax] <= plane + 1 and b[ax + 3] >= plane + 2) if side > 0 else (b[ax + 3] >= plane - 1 and b[ax] <= plane - 2)
                if infront and b[other] < w[other + 3] and b[other + 3] > w[other] and w[2] + 1 < b[5] < w[5]:
                    best = b[5] if best is None else min(best, b[5])
    return w[2] if best is None else best


def craft(text, nodes, boxes=()):
    """Valve's craft on every face laid by us (marked "@" before its lightmapscale), as the file is written. nodes: the
    path nodes (where people walk); boxes: every brush's box (what stands against a wall)."""
    grid_b = {}
    for b in boxes:
        for i in range(int(b[0] // 256), int(b[3] // 256) + 1):
            for j in range(int(b[1] // 256), int(b[4] // 256) + 1):
                grid_b.setdefault((i, j), []).append(b)
    faces = []
    for m in CRAFT_SIDE.finditer(text):
        vs = [tuple(int(float(c)) for c in v.split()) for v in re.findall(r'"v" "([^"]+)"', m.group(2))]
        a = [vs[1][k] - vs[0][k] for k in range(3)]
        b = [vs[2][k] - vs[0][k] for k in range(3)]
        n = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
        ln = math.sqrt(sum(c * c for c in n)) or 1.0
        n = tuple(c / ln for c in n)
        lo = [min(v[k] for v in vs) for k in range(3)]
        hi = [max(v[k] for v in vs) for k in range(3)]
        faces.append({"mat": m.group(4).lower(), "n": n, "lo": lo, "hi": hi, "disp": bool(m.group(12)), "lms": int(m.group(10)),
                      "u": m.group(6), "v": m.group(8), "plane": round(sum(n[k] * vs[0][k] for k in range(3)))})
    # how far each face is from where people walk (its box to the nearest path node), as far as 1024 matters
    cell, grid = 256, {}
    for p in nodes:
        grid.setdefault((int(p[0] // cell), int(p[1] // cell)), []).append(p)

    def far(f, limit):
        if not nodes:
            return False
        lo, hi = f["lo"], f["hi"]
        for i in range(int((lo[0] - limit) // cell), int((hi[0] + limit) // cell) + 1):
            for j in range(int((lo[1] - limit) // cell), int((hi[1] + limit) // cell) + 1):
                for p in grid.get((i, j), ()):
                    if math.sqrt(sum(max(lo[k] - p[k], 0, p[k] - hi[k]) ** 2 for k in range(3))) <= limit:
                        return False
        return True
    for f in faces:
        mat, lo, hi = f["mat"], f["lo"], f["hi"]
        seen = not mat.startswith(("tools/", "dev/"))
        area = max((hi[0] - lo[0]) * (hi[1] - lo[1]), (hi[0] - lo[0]) * (hi[2] - lo[2]), (hi[1] - lo[1]) * (hi[2] - lo[2]))
        dims = sorted(hi[k] - lo[k] for k in range(3))
        if seen and f["disp"]:
            f["lms"] = 64 if far(f, 256) else 32
        elif seen and any(k in mat for k in LMS_FINE) and area <= 128 * 256 and dims[2] <= 256:
            f["lms"] = 8
        elif seen and far(f, 1024):
            f["lms"] = 64
        elif seen and dims[1] <= 16 and dims[2] > 496:
            f["lms"] = 32
        (ua, us, uscale), (va, vs_, vscale) = _axis(f["u"]), _axis(f["v"])
        if seen and mat in SCALE_HALF and abs(f["n"][2]) < 0.9 and uscale == 0.25 and vscale == 0.25:
            uscale = vscale = 0.5
        f["axes"] = [ua, us, uscale, va, vs_, vscale]
        f["foot"] = seen and abs(f["n"][2]) < 0.01 and va == [0.0, 0.0, -1.0] and not f["disp"]
    # seams: the faces of one material in one plane that stand on each other are one wall; its texture starts at its foot
    groups = {}
    for k, f in enumerate(faces):
        if f["foot"]:
            groups.setdefault((f["mat"], tuple(round(c, 3) for c in f["n"]), f["plane"]), []).append(k)
    for ks in groups.values():
        up = dict((k, k) for k in ks)

        def root(k):
            while up[k] != k:
                up[k] = up[up[k]]
                k = up[k]
            return k
        ks.sort(key=lambda k: faces[k]["lo"][2])
        for i, a in enumerate(ks):
            fa = faces[a]
            for b in ks[i + 1:]:
                fb = faces[b]
                if fb["lo"][2] > fa["hi"][2]:
                    break
                if all(fa["lo"][q] < fb["hi"][q] and fb["lo"][q] < fa["hi"][q] for q in (0, 1) if fa["hi"][q] > fa["lo"][q]):
                    up[root(a)] = root(b)
        wall = {}
        for k in ks:
            r = root(k)
            lo, hi = faces[k]["lo"], faces[k]["hi"]
            w = wall.get(r)
            wall[r] = [min(w[0], lo[0]), min(w[1], lo[1]), min(w[2], lo[2]), max(w[3], hi[0]), max(w[4], hi[1]), max(w[5], hi[2])] if w else list(lo) + list(hi)
        for r, w in wall.items():
            wall[r] = foot_of(w, faces[r]["n"], boxes, grid_b)
        for k in ks:
            ax = faces[k]["axes"]
            ax[4] = (wall[root(k)] / ax[5]) % 1024      # (t = -z / scale + shift: 0 at the wall's foot)
    out = iter(faces)

    def put(m):
        f = next(out)
        ua, us, usc, va, vs_, vsc = f["axes"]
        u = "[%s %s %s %s] %s" % (_num(ua[0]), _num(ua[1]), _num(ua[2]), _num(us), _num(usc))
        v = "[%s %s %s %s] %s" % (_num(va[0]), _num(va[1]), _num(va[2]), _num(vs_), _num(vsc))
        return m.group(1) + m.group(2) + m.group(3) + m.group(4) + m.group(5) + u + m.group(7) + v + m.group(9) + str(f["lms"]) + m.group(11) + (m.group(12) or "")
    text = CRAFT_SIDE.sub(put, text)
    return text.replace('"lightmapscale" "@', '"lightmapscale" "')      # (any face the pass could not read keeps its own)


# Light falloffs (Valve's, docs/dev/valve-craft-notes.md "Light craft": constant, linear, quadratic). VRAD makes a light
# its brightness at 100 units whatever the falloff, so these change how far it reaches, not how bright it is there.
FALLOFF = {
    "fill": (0, 0, 1),           # a plain point light (ours until now; Valve's 246 city lights)
    "lamp": (500, 0, 1),         # a lamp's spot under its fixture (domes, bulbs, prison lamps): soft near, quadratic far
    "cage": (20, 0, 1),          # a caged lamp's spot (light_cagelight02_on)
    "tube": (100000, 100, 1),    # a fluorescent tube's spot (lights_florescent01a)
    "flood": (500000, 0, 1),     # a floodlight or Combine light: reaches far, hardly fading (Valve's city spots)
}


def falloff(kind):
    """The light keys for a falloff preset (FALLOFF)."""
    c, l, q = FALLOFF[kind]
    return {"_constant_attn": str(c), "_linear_attn": str(l), "_quadratic_attn": str(q)}


class Vmf:
    def __init__(self, skyname="painted"):
        self.next = 1
        self.world, self.ents, self.groups = [], [], []
        self.visgroups = {} # name -> id
        self.skyname = skyname
        self.boxes = [] # (box, seals) for the checks
        self.claims = []    # boxes that seal for the checks alone: where lifted brushes of Valve's (which the checks do not read) wall a place off
        self.disp_count = 0
        self.disp_made = [] # (visgroup, edge points, quads folded, quads) of every displaced face
        self.points = []    # (classname, place) of every point entity, for the checks
        self.props = []     # (classname, place, model, yaw) of every prop, for the checks that keep ways clear
        self.ways = []      # (box, label): spaces players walk through, kept clear of props (keep_way_clear, ways_problems)
        self.nudged = []    # (model, from, to): props moved out of a way or a door's swing as they were placed (clear_spot)
        self.stairs_as_built = []   # (box, why): flights copied from Valve's maps that Valve built broken on purpose (stairs_as_valve)
        self.shapes = 0     # solids that aren't boxes
        self.shape_boxes = []   # (the box round each of them, for the checks)
        self.portals = []   # the areaportals' boxes, for the checks
        self.portal_ents = []   # (where each areaportal's text is in ents, its box): linked to their doors at the end
        self.door_ents = []     # (where each door's text is in ents, its box, whether it starts open)

    def new_id(self):
        self.next += 1
        return self.next

    def vis(self, name):
        if name not in self.visgroups:
            self.visgroups[name] = len(self.visgroups) + 1
        return self.visgroups[name]

    def editor(self, vis, colour="0 180 220", indent="\t"):
        return ('%seditor\n%s{\n%s\t"color" "%s"\n%s\t"visgroupid" "%d"\n%s\t"visgroupshown" "1"\n%s\t"visgroupautoshown" "1"\n%s}\n'
                % (indent, indent, indent, colour, indent, self.vis(vis), indent, indent, indent))

    def box_text(self, box, sides, top, bottom, vis, indent="\t", faces=None, disp=None, tex=0.25, axes=None):
        """A box brush. sides, top, bottom: materials; faces: {face name: material} for any that differ;
        disp: {face name: (power, target(i, j) -> (x, y, z), alpha(i, j) or None)} to displace a face.
        Corners are written clockwise seen from outside, as Hammer++ does (its vertices_plus), and a
        displaced face's rows run from its first corner to its second, its columns to its fourth:
        checked against the owner's own map (473 shared edge points of its displacements meet)."""
        x1, y1, z1, x2, y2, z2 = box
        if not (x1 < x2 and y1 < y2 and z1 < z2):
            raise ValueError("a box with no size: %r" % (box,))
        t = indent
        s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, self.new_id())
        for name in FACE_ORDER:
            p = face_corners(box, name)
            mat = (faces or {}).get(name) or (top if name == "top" else bottom if name == "bottom" else sides)
            u, v = (a.replace("0.25", _num(tex)) for a in FACE_AXES[name])
            mark = "@"       # (laid by us: the craft pass may set its lightmapscale, scale and seam: Vmf.text)
            if axes and name in axes:
                u, v = axes[name]        # (a face's texture laid exactly as given: to copy a brush of the owner's)
                mark = ""
            s += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, self.new_id(), t, " ".join("(%d %d %d)" % q for q in p[:3]))
            s += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%d %d %d"\n' % ((t,) + q) for q in p), t)
            s += ('%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%s%d"\n%s\t\t"smoothing_groups" "0"\n'
                  % (t, mat.upper(), t, u, t, v, t, t, mark, 32 if disp else 16, t))
            if disp and name in disp:
                s += disp_text(p, disp[name], t + "\t\t", lambda edge, folded, quads, vis=vis: self.disp_made.append((vis, edge, folded, quads)))
                self.disp_count += 1
            s += '%s\t}\n' % t
        s += self.editor(vis, indent=t + "\t") + "%s}\n" % t
        return s

    def convex_text(self, faces, vis, indent="\t"):
        """Any convex solid: faces is [(corners in order round the face, material), ...]. Each face is turned
        to be clockwise seen from outside, and its texture laid along the face (level one way, down the slope the other)."""
        allv = [v for f, _ in faces for v in f]
        mid = [sum(v[k] for v in allv) / float(len(allv)) for k in range(3)]
        t = indent
        s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, self.new_id())
        for verts, mat in faces:
            def normal(vs):
                a = [vs[2][k] - vs[0][k] for k in range(3)]
                b = [vs[1][k] - vs[0][k] for k in range(3)]
                return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
            n = normal(verts)
            fc = [sum(v[k] for v in verts) / float(len(verts)) for k in range(3)]
            if sum(n[k] * (fc[k] - mid[k]) for k in range(3)) < 0:
                verts = list(reversed(verts))
                n = normal(verts)
            ln = (n[0] ** 2 + n[1] ** 2 + n[2] ** 2) ** 0.5
            if ln < 0.001 or any(c != int(c) for v in verts for c in v):
                raise ValueError("a face with no size, or a corner off the grid: %r" % (verts,))
            n = [c / ln for c in n]
            if abs(n[2]) > 0.99:
                u, w = (1.0, 0.0, 0.0), (0.0, -1.0, 0.0)
            else:
                hl = (n[0] ** 2 + n[1] ** 2) ** 0.5
                u = (-n[1] / hl, n[0] / hl, 0.0)
                w = (n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0])
                if w[2] > 0:
                    w = (-w[0], -w[1], -w[2])
            s += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, self.new_id(), t, " ".join("(%d %d %d)" % tuple(q) for q in verts[:3]))
            s += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%d %d %d"\n' % ((t,) + tuple(q)) for q in verts), t)
            s += ('%s\t\t"material" "%s"\n%s\t\t"uaxis" "[%s %s %s 0] 0.25"\n%s\t\t"vaxis" "[%s %s %s 0] 0.25"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "@16"\n%s\t\t"smoothing_groups" "0"\n%s\t}\n'
                  % (t, mat.upper(), t, _num(u[0]), _num(u[1]), _num(u[2]), t, _num(w[0]), _num(w[1]), _num(w[2]), t, t, t, t))
        s += self.editor(vis, indent=t + "\t") + "%s}\n" % t
        self.shapes += 1
        return s

    def detail_shapes(self, shapes, vis="LC canal: details"):
        """Shapes that aren't boxes (sloped banks, pipes), as func_detail: each is a list of faces for convex_text."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for faces in shapes:
            s += self.convex_text(faces, vis)
            allv = [v for f, _ in faces for v in f]
            self.shape_boxes.append(tuple(min(v[k] for v in allv) for k in range(3)) + tuple(max(v[k] for v in allv) for k in range(3)))
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    def world_box(self, box, sides, top=None, bottom=None, vis="LC canal: walls and floors", faces=None, disp=None, seals=True, tex=0.25):
        """A brush of the world. One with a displaced face seals nothing (the compiler drops the rest of it); nor does a clip,
        nor one with a see-through face (a grate, a fence, glass: vbsp makes the whole brush like glass, and the owner's
        compile of 22 November leaked through a grate floor). So a see-through top or bottom is laid as a thin detail
        sheet over solid black, and the world brush keeps sealing."""
        nd = MAT["nodraw"]
        if not disp and (see_through(top) or see_through(bottom)):
            x1, y1, z1, x2, y2, z2 = box
            if see_through(top) and z2 - z1 > 2:
                self.detail([(x1, y1, z2 - 1, x2, y2, z2)], top, vis=vis, faces={"bottom": nd})
                z2, top = z2 - 1, MAT["black"]
            if see_through(bottom) and z2 - z1 > 2:
                self.detail([(x1, y1, z1, x2, y2, z1 + 1)], bottom, vis=vis, faces={"top": nd})
                z1, bottom = z1 + 1, MAT["black"]
            box = (x1, y1, z1, x2, y2, z2)
        if see_through(sides) or any(see_through(m) for m in (faces or {}).values()):
            seals = False       # (vbsp makes it glass: it seals nothing)
        self.world.append(self.box_text(box, sides, top or nd, bottom or nd, vis, faces=faces, disp=disp, tex=tex))
        self.boxes.append((box, seals and not disp and not see_through(top) and not see_through(bottom)))

    def detail(self, boxes, mat, vis="LC canal: details", top=None, faces=None, tex=0.25):
        """Brushes that don't seal or cut up the map (func_detail): stairs, beams, bars, low walls."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for b in boxes:
            s += self.box_text(b, mat, top or mat, mat, vis, faces=faces, tex=tex)
            self.boxes.append((b, False))
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    @staticmethod
    def wires(connections):
        """What an entity does to others: [(its output, the other's name, the input, a value, seconds later), ...].
        Written as Hammer++ writes them in the owner's map (the parts held apart by the escape character)."""
        if not connections:
            return ""
        s = "\tconnections\n\t{\n"
        for out, target, inp, value, delay in connections:
            s += '\t\t"%s" "%s"\n' % (out, "\x1b".join((target, inp, str(value), _num(delay), "-1")))
        return s + "\t}\n"

    def keep_way_clear(self, box, label):
        """A space players must walk through (a doorway, a gate and its approach, a hole between two parts, a corridor's
        middle), as a box in the map's own coordinates: the build fails if a prop's real size stands in it. The owner,
        22 November: "this should please be a standard instruction for all map edits/creating/modules/etc"."""
        self.ways.append((tuple(box), label))

    def stairs_as_valve(self, box, why):
        """A flight of stairs lifted from one of Valve's maps that Valve itself built broken (ending in the air where the
        stairs collapsed, a foot hanging over the floor): the stair check leaves a flight starting in this box alone.
        Only for Valve's own (the same check on Valve's map finds the same fault); never for a flight of ours."""
        self.stairs_as_built.append((tuple(box), why))

    def clear_spot(self, model, pos, yaw):
        """Where a prop may stand: pos, or if its real box there enters a way kept clear or a hinged door's swing, the
        nearest spot up to 96 away that does not, going no further into the brushes than it was. None: no such spot."""
        def hit(p):
            b = prop_box(model, p, yaw)
            if b is None:
                return False
            ways = [w for w, _ in self.ways] + [box for _, box, _ in self.door_ents]
            return any(b[0] < w[3] and b[3] > w[0] and b[1] < w[4] and b[4] > w[1] and b[2] < w[5] and b[5] > w[2] for w in ways)

        def into_brushes(p):
            b = prop_box(model, p, yaw)
            tot = 0
            for box, _ in self.boxes:
                o = [min(b[k + 3], box[k + 3]) - max(b[k], box[k]) for k in range(3)]
                if min(o) > 0:
                    tot += o[0] * o[1] * o[2]
            return tot
        if not hit(pos):
            return pos
        base = into_brushes(pos)
        for r in range(16, 97, 16):
            for a in range(0, 360, 45):
                p = (pos[0] + r * math.cos(math.radians(a)), pos[1] + r * math.sin(math.radians(a)), pos[2])
                if not hit(p) and into_brushes(p) <= base:
                    return p
        return None

    def point(self, cls, pos, keys=None, vis="LC canal: details", connections=None, outside=False, exact=False):
        # (outside: the thing stands in the owner's own map, not in this piece: it is not held to the piece's sealed space)
        # (exact: its origin written to 0.01, not cut to whole units: a thing lifted from Valve's maps stands where Valve
        #  put it, in step with its brushes; the forest cams' TVs had dropped 0.73 off their screens)
        if not outside and cls.startswith("prop") and cls != "prop_door_rotating" and keys and keys.get("model") \
                and not any(k in str(keys["model"]) for k in WAY_EXEMPT) and (self.ways or self.door_ents):
            ang = str(keys.get("angles", "0 0 0")).split()
            spot = self.clear_spot(str(keys["model"]), pos, float(ang[1]) if len(ang) > 1 else 0.0)
            if spot is not None and tuple(spot) != tuple(pos):
                self.nudged.append((str(keys["model"]), tuple(pos), tuple(spot)))
                pos = (round(spot[0]), round(spot[1]), pos[2])
        if cls == "prop_static" and keys and str(keys.get("solid", "6")) == "6" and keys.get("model"):
            import map_assets      # (a model with no collision as solid 6: the game warns "SOLID_VPHYSICS static prop with no
            if map_assets.collides(str(keys["model"])) is False:      # vphysics model!", the owner's log, 25 November)
                keys = dict(keys, solid="0")
        if not outside:
            self.points.append((cls, tuple(pos)))
            if cls.startswith("prop") and keys and keys.get("model"):
                ang = str(keys.get("angles", "0 0 0")).split()
                self.props.append((cls, tuple(pos), str(keys["model"]), float(ang[1]) if len(ang) > 1 else 0.0))
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        if exact:
            nums = [("%.2f" % c).rstrip("0").rstrip(".") for c in pos]
            s += '\t"origin" "%s"\n' % " ".join("0" if n == "-0" else n for n in nums)
        else:
            s += '\t"origin" "%d %d %d"\n' % tuple(pos)
        s += self.wires(connections)
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)
        if cls == "prop_door_rotating" and str((keys or {}).get("model", "")).lower() in SOLID_DOORS:      # (a solid hinged door, its origin at its middle)
            opens = str((keys or {}).get("spawnpos", "0")) not in ("0", "")
            self.door_ents.append((len(self.ents) - 1, (pos[0] - 56, pos[1] - 56, pos[2] - 56, pos[0] + 56, pos[1] + 56, pos[2] + 56), opens))

    def brush_entity(self, cls, keys, boxes, sides, vis, top=None, faces=None, connections=None):
        """An entity made of brushes: a moving door, a button, a trigger, an areaportal. None of them seals."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        s += self.wires(connections)
        got = []
        for b in boxes:
            mat, fc, ax = sides, faces, None
            if len(b) == 3:      # (a box, {face: material}, {face: (uaxis, vaxis)})
                b, own, ax = b
                fc = own
            elif len(b) == 2:    # (a box, its own material) or (a box, {face: material})
                b, own = b
                mat, fc = (own, faces) if isinstance(own, str) else (sides, own)
            s += self.box_text(b, mat, top or mat, mat, vis, faces=fc, axes=ax)
            self.boxes.append((b, False))
            got.append(b)
        if cls.startswith("trigger_") and len(got) > 1:
            # (a trigger of several boxes gets an origin brush low in its biggest box, which is air in a room: Hammer gives a
            #  brush entity without one an origin at the middle of all its boxes, which can fall in the void between them,
            #  and the compiler then calls the map leaked; the owner's edit of 22 November: "Entity trigger_multiple
            #  (10240.00 5536.00 -496.00) leaked!", lc_bunker_inside, 33 boxes over the bunker and the silo)
            big = max(got, key=lambda g: (g[3] - g[0]) * (g[4] - g[1]) * (g[5] - g[2]))
            cx, cy = round((big[0] + big[3]) / 2.0), round((big[1] + big[4]) / 2.0)
            cz = round(min(big[2] + 16, (big[2] + big[5]) / 2.0))
            s += self.box_text((cx - 4, cy - 4, cz - 4, cx + 4, cy + 4, cz + 4), MAT["origin"], MAT["origin"], MAT["origin"], vis)
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)
        mats = [m.lower() for m in ([sides] if isinstance(sides, str) else []) + [x[1] for x in boxes if len(x) == 2 and isinstance(x[1], str)]]
        solid = mats and not any(m.startswith("tools/") or any(w in m for w in SEE_THROUGH) for m in mats)
        if cls in ("func_door", "func_door_rotating") and got and solid:      # (a solid door: an areaportal it hangs in is linked to it)
            try:
                opens = int(float((keys or {}).get("spawnflags", "0") or 0)) & 1
            except ValueError:
                opens = 0
            self.door_ents.append((len(self.ents) - 1, tuple(min(b[k] for b in got) for k in range(3)) + tuple(max(b[k + 3] for b in got) for k in range(3)), opens))

    def areaportal(self, box, vis, name=None):
        """A sheet across an opening that the game sees through only as far as the opening shows (and not at all when
        told to close): what keeps one area from being drawn while standing in another. It has to fill the opening
        from wall to wall, with open air on both its sides."""
        keys = {"StartOpen": "1", "PortalVersion": "1"}
        if name:
            keys["targetname"] = name
        self.portals.append(box)
        self.brush_entity("func_areaportal", keys, [box], MAT["portal"], vis)
        self.portal_ents.append((len(self.ents) - 1, box))

    def link_portal_doors(self):
        """Valve's way (the owner said go ahead, 21 November; lesson valve-portal-door): an areaportal with a door hanging
        in it names that door in its target, so it shuts when the door shuts and a room behind a shut door is not drawn.
        It starts as the door does. A door with no name gets one (door_N). Done once, as the file is written. (The
        gamemode's kick opens a door before it takes it off its hinges, so a kicked-in doorway is never left dark.)"""
        if getattr(self, "_portals_linked", False):
            return
        self._portals_linked = True
        for pi, pb in self.portal_ents:
            near = (pb[0] - 24, pb[1] - 24, pb[2] - 8, pb[3] + 24, pb[4] + 24, pb[5] + 8)
            best, most = None, 0.0
            for di, db, opens in self.door_ents:
                d = [min(near[k + 3], db[k + 3]) - max(near[k], db[k]) for k in range(3)]
                if min(d) > 0 and d[0] * d[1] * d[2] > most:
                    best, most = (di, opens), d[0] * d[1] * d[2]
            if not best:
                continue
            di, opens = best
            m = re.search(r'\t"targetname" "([^"]+)"', self.ents[di])
            name = m.group(1) if m else "door_%d" % di
            if not m:
                self.ents[di] = self.ents[di].replace('\t"classname"', '\t"targetname" "%s"\n\t"classname"' % name, 1)
            t = self.ents[pi].replace('"StartOpen" "1"', '"StartOpen" "%d"' % (1 if opens else 0), 1)
            self.ents[pi] = t.replace('\t"classname" "func_areaportal"\n', '\t"classname" "func_areaportal"\n\t"target" "%s"\n' % name, 1)

    def text(self):
        self.link_portal_doors()
        s = 'versioninfo\n{\n\t"editorversion" "400"\n\t"editorbuild" "8873"\n\t"mapversion" "1"\n\t"formatversion" "100"\n\t"prefab" "0"\n}\n'
        s += "visgroups\n{\n"
        for name, i in self.visgroups.items():
            s += '\tvisgroup\n\t{\n\t\t"name" "%s"\n\t\t"visgroupid" "%d"\n\t\t"color" "%d %d %d"\n\t}\n' % (name, i, 80 + 40 * i, 200 - 20 * i, 255 - 30 * i)
        s += "}\n"
        s += 'viewsettings\n{\n\t"bSnapToGrid" "1"\n\t"bShowGrid" "1"\n\t"bShowLogicalGrid" "0"\n\t"nGridSpacing" "64"\n\t"bShow3DGrid" "0"\n}\n'
        s += ('world\n{\n\t"id" "1"\n\t"mapversion" "1"\n\t"classname" "worldspawn"\n\t"skyname" "%s"\n\t"maxpropscreenwidth" "-1"\n'
              '\t"detailvbsp" "detail.vbsp"\n\t"detailmaterial" "detail/detailsprites"\n' % self.skyname)
        s += "".join(self.world) + "}\n"
        s += "".join(self.ents)
        s += 'cameras\n{\n\t"activecamera" "-1"\n}\ncordons\n{\n\t"active" "0"\n}\n'
        return craft(s, [p for c, p in self.points if c == "info_node"], [b for b, _ in self.boxes] + list(self.shape_boxes))


# ---------------------------------------------------------------------------
# A piece of map drawn on squares
# ---------------------------------------------------------------------------

def join_squares(cells):
    """A set of squares as the biggest rectangles (x1, y1, x2, y2): fewest brushes. Each grows along x, then along y."""
    left = set(cells)
    out = []
    for (i, j) in sorted(cells):
        if (i, j) not in left:
            continue
        w = 1
        while (i + w, j) in left:
            w += 1
        h = 1
        while all((i + k, j + h) in left for k in range(w)):
            h += 1
        for a in range(w):
            for b in range(h):
                left.discard((i + a, j + b))
        out.append((i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL))
    return out


class Plan:
    """Squares seen from above, in the piece's own coordinates (x east, y north, from its origin).
    A square is ("open", floor z, floor material) under the sky, ("low", floor z, floor material,
    ceiling z) under a ceiling, or nothing; the walls come by themselves.
    bands: the walls' looks by height, [(z from, z to, material), ...] from the bottom of everything
    to the top of everything. sky: the height of the sky lid over open squares (None: there are none)."""

    def __init__(self, origin, bands, sky=None, floor_side=None, ceiling=None, roof=None, vis="LC canal: walls and floors"):
        self.origin = origin
        self.band_list = bands
        self.base, self.top, self.sky = bands[0][0], bands[-1][1], sky
        self.floor_side = floor_side or bands[0][2]
        self.ceiling = ceiling or MAT["ceiling"]
        self.vis = vis
        self.roof = roof # what the very top is made of, where it can be seen (a building's roof)
        self.walled = False
        self.cells = {}
        self.keep_out = [] # (x1, y1, x2, y2): what's already there or belongs to another piece, never built on
        self.skies = {}    # (z1, z2, sides, top, bottom) -> squares: the sky over them, laid as the fewest boxes (sky_box, flush_sky)
        self.wall_paint = {}   # solid square -> {face: (material, z1, z2)}: its faces painted as the rooms they look into (paint_wall)

    paints = False         # (a plan that paints its rooms' walls on the walls themselves: the town's, map_town.TownPlan)

    def paint_wall(self, solid, room, mat, z1, z2):
        """Paint the face of the solid square `solid` that looks into the room's square `room` (next to it) with mat, for
        the room's floor to its ceiling (z1, z2), instead of a skin of brushes in front of it (the town, 24 November: its
        rooms' skins were 726 brushes and 2,700 faces). Only for a plan whose `paints` is set; it builds them with its
        walls (paint_faces)."""
        face = {(1, 0): "east", (-1, 0): "west", (0, 1): "north", (0, -1): "south"}[(room[0] - solid[0], room[1] - solid[1])]
        got = self.wall_paint.setdefault(tuple(solid), {})
        old = got.get(face)
        if old and old[0] == mat:
            z1, z2 = min(z1, old[1]), max(z2, old[2])
        got[face] = (mat, z1, z2, tuple(room))

    def paint_faces(self, x1, y1, z1, z2):
        """The painted faces of a rectangle of solid squares (all its squares are painted alike: rectangles), for a brush
        of it from z1 to z2: {face: material} for world_box, or None."""
        got = self.wall_paint.get((x1 // CELL, y1 // CELL))
        out = dict((f, p[0]) for f, p in (got or {}).items() if p[1] < z2 and z1 < p[2])
        return out or None

    def paint(self, rect, spec):
        x1, y1, x2, y2 = rect
        for v in rect:
            if v % CELL:
                raise ValueError("off the %d grid: %r" % (CELL, rect))
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                self.cells[(i, j)] = spec

    def walls(self):
        """A solid square wherever an empty square touches an open one (corners too)."""
        if self.walled:
            return
        self.walled = True
        solid = set()
        for (i, j) in self.cells:
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    c = (i + di, j + dj)
                    if c not in self.cells:
                        x, y = c[0] * CELL, c[1] * CELL
                        if not any(x < k[2] and x + CELL > k[0] and y < k[3] and y + CELL > k[1] for k in self.keep_out):
                            solid.add(c)
        for c in solid:
            self.cells[c] = ("solid",)

    def rectangles(self):
        """Squares that are alike, joined into the biggest rectangles (fewest brushes)."""
        left = dict(self.cells)
        for c, got in self.wall_paint.items():      # (a square painted differently is never joined with its neighbours)
            if c in left:
                left[c] = left[c] + (("painted",) + tuple(sorted((f, p[0]) for f, p in got.items())),)
        out = []
        for (i, j) in sorted(left):
            if (i, j) not in left:
                continue
            spec = left[(i, j)]
            w = 1
            while left.get((i + w, j)) == spec:
                w += 1
            h = 1
            while all(left.get((i + k, j + h)) == spec for k in range(w)):
                h += 1
            for a in range(w):
                for b in range(h):
                    del left[(i + a, j + b)]
            if self.wall_paint and spec and isinstance(spec[-1], tuple) and spec[-1][:1] == ("painted",):
                spec = spec[:-1]
            out.append((i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL, spec))
        return out

    def sky_box(self, x1, y1, z1, x2, y2, z2, sides, top=None, bottom=None):
        """A box of sky over these squares (the piece's own coordinates). Kept until flush_sky, which joins every square
        with the same box into the biggest rectangles: the same air closed by far fewer brushes (the owner's compile of the
        ring, 23 November, ran out of faces; a sky box over every rectangle of floor was 2,300 brushes of it)."""
        cells = self.skies.setdefault((z1, z2, sides, top, bottom), set())
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                cells.add((i, j))

    def flush_sky(self, vmf):
        for (z1, z2, sides, top, bottom), cells in sorted(self.skies.items(), key=lambda kv: (kv[0][0], kv[0][1], str(kv[0][2:]))):
            for x1, y1, x2, y2 in join_squares(cells):
                vmf.world_box(self.box(x1, y1, z1, x2, y2, z2), sides, top=top, bottom=bottom, vis=self.vis)
        self.skies = {}

    def world(self, x, y, z):
        return (self.origin[0] + x, self.origin[1] + y, z)

    def box(self, x1, y1, z1, x2, y2, z2):
        ox, oy = self.origin[0], self.origin[1]
        return (ox + x1, oy + y1, z1, ox + x2, oy + y2, z2)

    def bands(self, z_from):
        """A wall from z_from up to the top, in its looks by height."""
        out = []
        for lo, hi, mat in self.band_list:
            a, b = max(lo, z_from), hi
            if a < b:
                out.append((a, b, mat))
        return out

    def inside(self, x, y):
        """Is this point (the piece's own coordinates) strictly inside the building: squares on every side of it?"""
        i, j = x // CELL, y // CELL
        on_x, on_y = x % CELL == 0, y % CELL == 0
        for di in ((-1, 0) if on_x else (0,)):
            for dj in ((-1, 0) if on_y else (0,)):
                if (i + di, j + dj) not in self.cells:
                    return False
        return True

    def build(self, vmf):
        self.walls()
        for x1, y1, x2, y2, spec in self.rectangles():
            if spec[0] == "solid":
                for a, b, mat in self.bands(self.base):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, top=self.roof if b == self.top else None, vis=self.vis)
                continue
            floor, floor_mat = spec[1], spec[2]
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, floor), self.floor_side, top=floor_mat, vis=self.vis)
            if spec[0] == "open":
                lid = spec[3] if len(spec) > 3 and spec[3] else self.sky      # (a square with a sky of its own, higher: a church's yard)
                self.sky_box(x1, y1, lid, x2, y2, max(self.top, lid + 16), MAT["sky"], MAT["sky"], MAT["sky"])
            elif spec[0] == "cellar":      # (a room under a floor that is open to the sky: a church's basement, a tunnel under a yard)
                ceil, upper, upper_mat, lid = spec[3], spec[4], spec[5], spec[6]
                vmf.world_box(self.box(x1, y1, ceil, x2, y2, upper), self.floor_side, top=upper_mat, bottom=self.ceiling, vis=self.vis)
                self.sky_box(x1, y1, lid, x2, y2, max(self.top, lid + 16), MAT["sky"], MAT["sky"], MAT["sky"])
            else:
                first = True
                for a, b, mat in self.bands(spec[3]):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, top=self.roof if b == self.top else None, bottom=self.ceiling if first else None, vis=self.vis)
                    first = False
        self.raise_sky(vmf)

    def lid_top(self, spec):
        """How high a square's sky (or solid) reaches: the piece's top, or a higher lid of its own."""
        if spec and spec[0] == "open" and len(spec) > 3 and spec[3]:
            return max(self.top, spec[3] + 16)
        if spec and spec[0] == "cellar":
            return max(self.top, spec[6] + 16)
        return self.top

    def raise_sky(self, vmf):
        """Where a square's sky is higher than the piece's (open with a lid of its own, or a cellar's), every square round
        it gets a column of sky up to that height on top of what it has, so the high air is closed in on every side."""
        need = {}
        for c, spec in self.cells.items():
            top = self.lid_top(spec)
            if top <= self.top:
                continue
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    n = (c[0] + di, c[1] + dj)
                    if n in self.cells and self.lid_top(self.cells[n]) < top:
                        need[n] = max(need.get(n, 0), top)
        for (i, j), top in need.items():
            self.sky_box(i * CELL, j * CELL, self.lid_top(self.cells[(i, j)]), (i + 1) * CELL, (j + 1) * CELL, top, MAT["sky"], MAT["sky"], MAT["sky"])
        self.flush_sky(vmf)      # (every sky box of the plan, joined: Plan.sky_box)


def prism(profile, axis, a, b, mat, end_mat=None):
    """A flat shape (profile: its corners in order, as (across, up)) pushed along x or y from a to b: the faces for convex_text."""
    def at(t, pq):
        return (t, pq[0], pq[1]) if axis == "x" else (pq[0], t, pq[1])
    faces = [([at(a, q) for q in profile], end_mat or mat), ([at(b, q) for q in profile], end_mat or mat)]
    for k in range(len(profile)):
        q1, q2 = profile[k], profile[(k + 1) % len(profile)]
        faces.append(([at(a, q1), at(a, q2), at(b, q2), at(b, q1)], mat))
    return faces


def hexagon(c, up, r):
    """A flat round hole's outline with six corners (two fewer than octagon's: fewer sides and vertices), r to its
    corners left and right, 0.866 r to its flat top and bottom."""
    k, h = int(round(r * 0.5)), int(round(r * 0.866))
    return [(c + r, up), (c + k, up + h), (c - k, up + h), (c - r, up), (c - k, up - h), (c + k, up - h)]


def octagon(c, up, r):
    """A pipe's outline: eight corners on the grid, about r from the middle (c across, up)."""
    k = int(round(r * 0.4))
    return [(c + r, up + k), (c + k, up + r), (c - k, up + r), (c - r, up + k), (c - r, up - k), (c - k, up - r), (c + k, up - r), (c + r, up - k)]


# The test map's sky and sun (the owner, 24 November: "can we get a test skybox texture? I can't tell what's void and what's
# skybox and what's broken cause everything is black. can we get a test env sun too? it's so hecking dark"). The pieces'
# own sky name is Garry's Mod's "painted", which env_skypaint draws: a map without one (a piece by itself) shows it black,
# as the void looks. So a test map has Half-Life 2's clear day sky, and a day's sun: brighter, and lower in the sky
# than City 18's dim one (its 50 and 13, at 70 degrees), so the forest and the launch pad are lit and the sun shows. Never in the file
# that goes into the real map: City 18 has its own sky and sun (two light_environments in one map fight).
TEST_SKY = "sky_day01_01"
TEST_SUN = {"_light": "255 238 205 300", "_ambient": "150 170 200 60", "pitch": -50, "yaw": 149}


def test_extras(vmf, start, yaw, vis):
    """What a piece needs to be compiled and walked BY ITSELF: somewhere to spawn, a sky and a sun (TEST_SKY, TEST_SUN).
    Never in the file that goes into the real map: that already has them."""
    vmf.point("info_player_start", start, {"angles": "0 %d 0" % yaw}, vis)
    vmf.skyname = TEST_SKY
    pitch, sun_yaw = TEST_SUN["pitch"], TEST_SUN["yaw"]
    vmf.point("light_environment", (start[0], start[1], start[2] + 128), {
        "_light": TEST_SUN["_light"], "_ambient": TEST_SUN["_ambient"], "_lightHDR": "-1 -1 -1 1", "_ambientHDR": "-1 -1 -1 1",
        "_lightscaleHDR": "1", "_ambientscaleHDR": "1", "angles": "0 %d 0" % sun_yaw, "pitch": str(pitch), "SunSpreadAngle": "0"}, vis)
    # the sun itself in the sky, where that light comes from (the owner, 22 November: "could you please put a spawn point
    # and env_sun so I can see outside in the test map?"): the light's own angles with use_angles, as the wiki advises;
    # big and warm enough to find (it was 16 across and a dull red)
    vmf.point("env_sun", (start[0], start[1], start[2] + 160), {
        "angles": "%d %d 0" % (pitch, sun_yaw), "pitch": str(pitch), "use_angles": "1", "rendercolor": "255 236 200", "overlaycolor": "255 210 150",
        "size": "40", "overlaysize": "-1", "material": "sprites/light_glow02_add_noz", "overlaymaterial": "sprites/light_glow02_add_noz", "HDRColorScale": "1.0"}, vis)


def bar_row(box, along, gap=24):
    """Bars across an opening: box is the thin slab they stand in, along is "x" or "y" (the way the row runs).
    8 thick and 24 from one to the next: 16 between them, and a player is 32 wide. A crossbar ties them at half height."""
    x1, y1, z1, x2, y2, z2 = box
    lo, hi = (x1, x2) if along == "x" else (y1, y2)
    n = (hi - lo - 8) // gap
    first = lo + (hi - lo - (n * gap + 8)) // 2
    out = []
    for i in range(n + 1):
        a = first + i * gap
        out.append((a, y1, z1, a + 8, y2, z2) if along == "x" else (x1, a, z1, x2, a + 8, z2))
    mid = (z1 + z2) // 2      # (the crossbar 1 proud of the bars on each face: no face of theirs lies in its, which would flicker)
    out.append((x1, y1 - 1, mid - 4, x2, y2 + 1, mid + 4) if along == "x" else (x1 - 1, y1, mid - 4, x2 + 1, y2, mid + 4))
    return out


BAR_GATE = ("models/props_canal/canal_bars001.mdl", 384, 448)       # (the canals' big grate over a tunnel's mouth: 385 wide, 449 high, 13 thick, its origin at its middle)
BAR_PANEL = ("models/props_canal/canal_bars002.mdl", 128, 124)      # (Half-Life 2's canal bars: a panel 128 wide, 124 high, 7 thick, its origin at its middle)


def bar_props(vmf, slab, along, vis):
    """The bars across an opening as Valve's own panels, one prop each, in place of a brush for every bar (the owner,
    24 November: "all the brush grates over any entrance that is blocked in the canals is using up tons of brushes when
    there are props that can do the same"). The panels are spread evenly over the slab, overlapping where it is not a
    whole number of them. False (nothing placed) where the opening is smaller than one panel: brush bars there."""
    model, wide, high = BAR_PANEL
    x1, y1, z1, x2, y2, z2 = slab
    lo, hi = (x1, x2) if along == "x" else (y1, y2)
    if hi - lo >= 256 and z2 - z1 >= 192:
        # a blocked tunnel's mouth: the canals' big grate (canal_bars001, 385 wide and 449 high), not the culverts' small
        # one (the owner, 25 November: "I asked for canal grates over the big black brushes at various blocked tunnels in
        # the canals and it used the round grate for a culvert"). Side by side from the opening's middle, never
        # overlapping, their tops at the opening's top: what is over stands in the walls beside it and the ground under it.
        bmodel, bwide, bhigh = BAR_GATE
        cols, rows = -(-(hi - lo) // bwide), -(-(z2 - z1) // bhigh)
        start = (lo + hi) / 2.0 - cols * bwide / 2.0
        for r in range(rows):
            z = z2 - bhigh / 2.0 - r * bhigh
            for k in range(cols):
                p = start + bwide / 2.0 + k * bwide
                pos = (round(p), (y1 + y2) // 2, round(z)) if along == "x" else ((x1 + x2) // 2, round(p), round(z))
                vmf.point("prop_static", pos, {"model": bmodel, "angles": "0 %d 0" % (90 if along == "x" else 0), "skin": "0", "solid": "6", "disableshadows": "1",
                                               "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis, outside=True)
        return True
    if hi - lo < wide or z2 - z1 < high:
        return False
    cols, rows = -(-(hi - lo) // wide), -(-(z2 - z1) // high)
    for r in range(rows):
        z = z1 + high / 2 + (r * (z2 - z1 - high) / (rows - 1) if rows > 1 else (z2 - z1 - high) / 2)
        for k in range(cols):
            p = lo + wide / 2 + (k * (hi - lo - wide) / (cols - 1) if cols > 1 else (hi - lo - wide) / 2)
            pos = (round(p), (y1 + y2) // 2, round(z)) if along == "x" else ((x1 + x2) // 2, round(p), round(z))
            vmf.point("prop_static", pos, {"model": model, "angles": "0 %d 0" % (90 if along == "x" else 0), "skin": "0", "solid": "6", "disableshadows": "1",
                                           "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)
    return True


def barred(vmf, slab, along, vis, back=None):
    """A row of bars nobody can get through (an unseen wall for players stands in the same place), and the black behind them."""
    if not bar_props(vmf, slab, along, vis):
        vmf.detail(bar_row(slab, along), MAT["bars"], vis=vis)
    c = MAT["clip"]
    vmf.world_box(slab, c, c, c, vis=vis, seals=False)
    if back:
        vmf.detail([back], MAT["black"], vis=vis)


SEE_THROUGH = ("metalgrate", "metalfence", "chainlink", "glass", "window", "effects/", "metalbars", "grate0")


def see_through(mat):
    """A material vbsp treats as glass on a world brush (it stops the brush sealing): grates, fences, glass. By name."""
    return bool(mat) and any(w in mat.lower() for w in SEE_THROUGH)


def gate_cap(vmf, cap, bars, along, vis):
    """What closes a gate while nothing is joined to it: a black wall across the culvert, and bars before it.
    In a visgroup of its own: delete the cap on each side of a join, and the two pieces are one."""
    vmf.world_box(cap, MAT["black"], MAT["black"], MAT["black"], vis=vis)
    barred(vmf, bars, along, vis)


# ---------------------------------------------------------------------------
# Checking a piece before the owner sees it
# ---------------------------------------------------------------------------

def flood(vmf, seed, stoppers):
    """Where the air at seed reaches, among the piece's sealing brushes and some stopper boxes. Returns (the cells
    reached, the solid cells, the cuts along each axis, a cell on the outside if the air got there). Exact for boxes:
    space is cut at every brush face."""
    solid = [b for b, seals in vmf.boxes if seals] + list(vmf.claims) + list(stoppers)
    axes = []
    for a in range(3):
        cuts = sorted(set([b[a] for b in solid] + [b[a + 3] for b in solid]))
        axes.append([cuts[0] - 64] + cuts + [cuts[-1] + 64])
    n = [len(ax) - 1 for ax in axes]
    full = set()
    for b in solid:
        r = [(bisect.bisect_left(axes[a], b[a]), bisect.bisect_left(axes[a], b[a + 3])) for a in range(3)]
        for i in range(*r[0]):
            for j in range(*r[1]):
                for k in range(*r[2]):
                    full.add((i, j, k))
    start = tuple(bisect.bisect_right(axes[a], seed[a]) - 1 for a in range(3))
    if start in full:
        return None, full, axes, None
    seen, todo, leak = {start}, [start], None
    while todo:
        c = todo.pop()
        if c[0] in (0, n[0] - 1) or c[1] in (0, n[1] - 1) or c[2] in (0, n[2] - 1):
            leak = c
            break
        for a in range(3):
            for d in (-1, 1):
                m = list(c)
                m[a] += d
                m = tuple(m)
                if m not in seen and m not in full:
                    seen.add(m)
                    todo.append(m)
    return seen, full, axes, leak


def reaches(flooded, point):
    """Did that flood reach this point?"""
    seen, full, axes, leak = flooded
    return seen is not None and tuple(bisect.bisect_right(axes[a], point[a]) - 1 for a in range(3)) in seen


def check(vmf, seed, stoppers):
    """Corners on the grid, and no way from the air inside (seed) to the outside once the piece's one opening is
    stopped up (stoppers: boxes); then every entity must be in that air."""
    problems = []
    for b, _ in vmf.boxes:
        if any(v != int(v) for v in b):
            problems.append("a corner off the 1-unit grid: %r" % (b,))
    seen, full, axes, leak = flood(vmf, seed, stoppers)
    vmf.flooded = (seen, full, axes, leak)      # (map_lint.py asks it which side of a face is the air players are in)
    if seen is None:
        return problems + ["the check's starting point is inside a brush"], 0
    if leak:
        problems.append("NOT SEALED: the air inside reaches the outside near (%d %d %d)" % tuple(axes[a][leak[a]] for a in range(3)))
    else:
        # every entity must be in that air (or inside a brush): one in the void outside is what the compiler calls a leak
        out = []
        for cls, pos in vmf.points:
            c = tuple(bisect.bisect_right(axes[a], pos[a]) - 1 for a in range(3))
            if c not in seen and c not in full:
                out.append("%s at (%d %d %d)" % ((cls,) + tuple(pos)))
        if out:
            problems.append("%d entities are outside the sealed space (the compiler would report a leak): %s" % (len(out), "; ".join(out[:4])))
        # every areaportal: open air on both its faces, and wall, floor or roof past each of its four edges
        def solid_at(pt):
            return tuple(bisect.bisect_right(axes[a], pt[a]) - 1 for a in range(3)) in full
        for box in vmf.portals:
            size = [box[a + 3] - box[a] for a in range(3)]
            thin = size.index(min(size))
            mid = [(box[a] + box[a + 3]) / 2.0 for a in range(3)]
            bad = []
            for d in (-6, 6):
                pt = list(mid)
                pt[thin] = (box[thin] if d < 0 else box[thin + 3]) + d
                if solid_at(pt):
                    bad.append("no air on one side")
            for a in range(3):
                if a == thin:
                    continue
                for d in (-6, 6):
                    pt = list(mid)
                    pt[a] = (box[a] if d < 0 else box[a + 3]) + d
                    if not solid_at(pt):
                        bad.append("open past its %s edge" % ("xyz"[a] + ("-" if d < 0 else "+")))
            if bad:
                problems.append("the areaportal at (%d %d %d) would not work: %s" % (mid[0], mid[1], mid[2], ", ".join(bad)))
        problems += portal_areas(vmf, stoppers)
    return problems, len(seen)


def portal_areas(vmf, stoppers):
    """Every areaportal must part two places: with all of them shut, the air on its two faces must not meet some other
    way (the owner's compile, 23 November: vbsp stopped on "areaportal brush doesn't touch two areas" when the street
    opened the far side of the arcade's shop doorway). One labelling of the air, shared by all the portals."""
    ports = list(vmf.portals)
    if not ports:
        return []
    solid = [b for b, seals in vmf.boxes if seals] + list(vmf.claims) + list(stoppers) + ports
    axes = []
    for a in range(3):
        cuts = sorted(set([b[a] for b in solid] + [b[a + 3] for b in solid]))
        axes.append([cuts[0] - 64] + cuts + [cuts[-1] + 64])
    n = [len(ax) - 1 for ax in axes]
    full = set()
    for b in solid:
        r = [(bisect.bisect_left(axes[a], b[a]), bisect.bisect_left(axes[a], b[a + 3])) for a in range(3)]
        for i in range(*r[0]):
            for j in range(*r[1]):
                for k in range(*r[2]):
                    full.add((i, j, k))
    label, problems = {}, []

    def fill(start, lab):
        label[start] = lab
        todo = [start]
        while todo:
            c = todo.pop()
            for a in range(3):
                for d in (-1, 1):
                    m = list(c)
                    m[a] += d
                    if not 0 <= m[a] < n[a]:
                        continue
                    m = tuple(m)
                    if m not in label and m not in full:
                        label[m] = lab
                        todo.append(m)
    for box in ports:
        size = [box[a + 3] - box[a] for a in range(3)]
        thin = size.index(min(size))
        mid = [(box[a] + box[a + 3]) / 2.0 for a in range(3)]
        sides = []
        for d in (-6, 6):
            pt = list(mid)
            pt[thin] = (box[thin] if d < 0 else box[thin + 3]) + d
            c = tuple(bisect.bisect_right(axes[a], pt[a]) - 1 for a in range(3))
            sides.append(None if c in full else c)
        if None in sides:
            continue          # (the edge check above says so)
        for c in sides:
            if c not in label:
                fill(c, len(problems) * 0 + len(label) + 1)
        if label[sides[0]] == label[sides[1]]:
            problems.append("the areaportal at (%d %d %d) parts nothing: with every areaportal shut, the air on its two faces still meets another way (vbsp stops: 'areaportal brush doesn't touch two areas')" % tuple(mid))
            useless.append(box)
    return problems


def drop_useless_portals(vmf, stoppers):
    """Take out every areaportal that parts nothing (portal_areas): it only ever saved drawing, and vbsp will not compile
    one. Returns notes saying which went. Run before the checks (a chain's finish does)."""
    notes = []
    for _ in range(4):                     # (taking one out can leave another parting nothing)
        useless.clear()
        portal_areas(vmf, stoppers)
        if not useless:
            break
        for box in list(useless):
            for k, (pi, pb) in enumerate(vmf.portal_ents):
                if pb == box:
                    name = re.search(r'"targetname" "([^"]+)"', vmf.ents[pi])
                    vmf.ents[pi] = ""
                    if name:                   # (and the doors' outputs to it: nothing left to open)
                        drop = re.compile(r'\n[ \t]*"[^"]+" "%s[,\x1b][^"]*"' % re.escape(name.group(1)))
                        vmf.ents = [drop.sub("", e) if e else e for e in vmf.ents]
                    vmf.portal_ents.pop(k)
                    break
            if box in vmf.portals:
                vmf.portals.remove(box)
            notes.append("an areaportal at (%d %d %d) taken out: it parted nothing (the street or the backdrop opened a way round it)" % tuple((box[a] + box[a + 3]) // 2 for a in range(3)))
    return notes



def lift_ladder_feet(vmf):
    """A ladder's foot that stands in something low under it (a deck's boards, a kerb, a few units proud of the floor) is
    raised onto it, 4 above its top: a player's box at the foot must touch nothing, or the game says "funcladder with
    blocked bottom point ... stuck in" (the owner's log, 25 November). Returns notes."""
    notes = []
    for i, e in enumerate(vmf.ents):
        if '"classname" "func_useableladder"' not in e:
            continue
        m = re.search(r'"point0" "(-?\d+) (-?\d+) (-?\d+)"', e)
        if not m:
            continue
        x, y, z = (int(m.group(k)) for k in (1, 2, 3))
        top = z
        for b, _ in vmf.boxes:
            if b[0] < x + 16 and b[3] > x - 16 and b[1] < y + 16 and b[4] > y - 16 and b[2] < z and z <= b[5] <= z + 20:
                top = max(top, b[5] + 4)
        if top != z:
            vmf.ents[i] = e.replace(m.group(0), '"point0" "%d %d %d"' % (x, y, top))
            notes.append("a ladder's foot at (%d %d %d) raised %d onto what stands under it" % (x, y, z, top - z))
    return notes


useless = []


# ---------------------------------------------------------------------------
# The canal at the road's end
# ---------------------------------------------------------------------------

COMBINE_CORE = "metal/citadel_metalwall077a"      # (map_corridor.CORE: the Combine wall's core)
STREET_Z = 656                                    # (map_corridor.STREET: a deck over a square "under" a street stands there)
FENCE_POST = 512      # a post every 512 along the walls' tops, and one at each end (were every 256: 504 brushes round the ring)


def fence(vmf, plan, high, vis, top=None):
    """Chain link along the top of every wall that looks onto a canal (the owner: "put fencing along the boundary at the
    top of the canal walls"): a sheet standing 2 out from the wall's face, from the concrete's top up, with a rail and
    posts. top: where the concrete ends, for a plan whose squares don't say (the ring's do: its walls' tops climb)."""
    cells = plan.cells
    runs = {}
    for (i, j), spec in cells.items():
        if spec[0] != "open" or (len(spec) > 3 and spec[3]):      # (a yard with a sky of its own is no canal: a churchyard has its own wall)
            continue
        x, y = i * CELL, j * CELL
        for (di, dj, axis, line, side, a) in ((0, -1, "x", y, 1, x), (0, 1, "x", y + CELL, -1, x), (-1, 0, "y", x, 1, y), (1, 0, "y", x + CELL, -1, y)):
            nb = cells.get((i + di, j + dj))
            if nb is None or nb[0] in ("open", "cellar"):
                continue
            if nb[0] == "low" and len(nb) > 2 and nb[2] == COMBINE_CORE:
                continue      # (the Combine wall stands there: no chain link before it)
            if nb[0] == "under" and len(nb) > 4 and nb[4] == MAT["quay_floor"]:
                continue      # (a gate's culvert under its deck: no chain link along the deck's edge)
            at = nb[1] if nb[0] == "solid" and len(nb) > 1 else nb[4] if nb[0] == "low" and len(nb) > 4 and not isinstance(nb[4], str) else STREET_Z if nb[0] == "under" else top
            runs.setdefault((axis, line, side, at), []).append(a)
    sheets, bars = {"x": [], "y": []}, []

    def along(axis, a, b, lo, hi, z1, z2):
        return plan.box(a, lo, z1, b, hi, z2) if axis == "x" else plan.box(lo, a, z1, hi, b, z2)
    for (axis, line, side, at), parts in sorted(runs.items()):
        parts.sort()
        start = prev = None
        for a in parts + [None]:
            if a is not None and start is not None and a == prev + CELL:
                prev = a
                continue
            if start is not None:
                b = prev + CELL
                t = 1 if axis == "y" else 2       # (a run along y: its sheet 1 thick and its posts 3 either side, so at a corner
                sheets[axis].append(along(axis, start, b, min(line, line + t * side), max(line, line + t * side), at, at + high))      # no post's face lies in a sheet's plane)
                lo, hi = min(line, line + 4 * side), max(line, line + 4 * side)
                dz = 1 if axis == "y" else 0      # (a run along y sits 1 lower and 1 thinner: where two runs meet at a corner
                if axis == "y":                    # their rails never share a face, which would flicker: the owner, 21 November)
                    lo, hi = (lo, hi - 1) if side > 0 else (lo + 1, hi)
                bars.append(along(axis, start, b, lo, hi, at + high - 4 - dz, at + high - dz))
                w = 3 if axis == "y" else 2
                posts = list(range(start, b + 1, FENCE_POST))
                if b - posts[-1] > 64:
                    posts.append(b)       # (and one at the run's end)
                for p in posts:
                    bars.append(along(axis, max(start, p - w), min(b, p + w), lo, hi, at + dz, at + high - 4 - dz))      # (and 1 higher at the foot)
            start = prev = a
    nd = MAT["nodraw"]
    # (City 18's own chain link is effects/metalfence007a, which only Counter-Strike: Source has: map_assets.py fails it.
    #  The owner chose theirs on 22 November; this is Half-Life 2's of the same look, kept until CS:S is known to be there)
    if sheets["x"]:
        vmf.detail(sheets["x"], MAT["fence"], vis=vis, faces={"west": nd, "east": nd, "top": nd, "bottom": nd})
    if sheets["y"]:
        vmf.detail(sheets["y"], MAT["fence"], vis=vis, faces={"north": nd, "south": nd, "top": nd, "bottom": nd})
    vmf.detail(bars, MAT["bars"], vis=vis)
    return len(sheets["x"]) + len(sheets["y"])


def road_bridge(vmf, plan, axis, a, b, lo, hi, floor, trim, vis):
    """A street carried over a canal at the trim's height: a deck from wall to wall, parapets, girders, a pier wall on each
    bank. axis: the way the canal runs there; a, b: along it; lo, hi: its two walls. Gives back the room it takes."""
    def bx(u1, v1, z1, u2, v2, z2):
        return plan.box(u1, v1, z1, u2, v2, z2) if axis == "x" else plan.box(v1, u1, z1, v2, u2, z2)
    vmf.detail([bx(a, lo, trim - 40, b, hi, trim + 8)], MAT["beam"], vis=vis, top=MAT["quay_floor"])
    vmf.detail([bx(a, lo, trim + 8, a + 16, hi, trim + 56), bx(b - 16, lo, trim + 8, b, hi, trim + 56),
                bx(a + 48, lo + 112, floor, b - 48, lo + 144, trim - 72), bx(a + 48, hi - 144, floor, b - 48, hi - 112, trim - 72)], MAT["canal_wall"], vis=vis)
    vmf.detail([bx(u, lo, trim - 72, u + 24, hi, trim - 40) for u in range(a + 40, b - 40, 96)], MAT["bars"], vis=vis)
    return bx(a, lo, floor, b, hi, trim + 56)


def canal(args):
    # the road ends at the owner's brush 15074 (x 3328..3968, y 1856..1872): its city side is this piece's south edge
    import map_corridor as mc
    ox, oy = args.origin
    road_z, floor_z = 656, 400
    sky = road_z + 1024      # (1024 over the road, as the ring's street: room over the Combine wall beside the road on its east bank)
    # (plain concrete to 128 over the road and a fence on it, as the ring: the owner, of the brick band both canals had over
    #  the concrete, "can we just make the canal walls a bit higher instead of using brickwork at the top", then of this
    #  canal: "yes please make the first canal match")
    wall_top = road_z + 128
    # (the squares in the map's own coordinates, as the ring's and the modules' are, so the canal modules' dressing can
    #  dress this canal too: the owner, 21 November, "yes please". Everything below is written from the road's end, as
    #  before: P, B and W move it to the map. The plan is the street's kind, which knows a room under a road and the
    #  Combine wall's core.)
    plan = mc.CorridorPlan(floor_z - 64, wall_top, sky, "LC canal: walls and floors")

    def P(r):
        return (r[0] + ox, r[1] + oy, r[2] + ox, r[3] + oy)

    def B(x1, y1, z1, x2, y2, z2):
        return (x1 + ox, y1 + oy, z1, x2 + ox, y2 + oy, z2)

    def W(x, y, z):
        return (x + ox, y + oy, z)
    plan.keep_out.append(P((-100000, -100000, 100000, 0)))    # the city: everything south of the road's end is the owner's
    plan.keep_out.append(P((4608, -100000, 100000, 100000)))  # beyond the east gate: whatever is joined there
    plan.keep_out.append(P((-100000, 3840, 100000, 100000)))  # beyond the north gate
    canal_floor = ("open", floor_z, MAT["canal_floor"])
    culvert = ("low", floor_z, MAT["canal_floor"], floor_z + GATE_HIGH)
    doorway = ("low", road_z, MAT["quay_floor"], road_z + 112)         # a way into the wall at the canal's top: where a footbridge lands
    plan.paint(P((0, 0, 640, 256)), ("open", road_z, MAT["quay_floor"]))  # the quay: the road carries on to the canal's edge
    plan.paint(P((0, 256, 3072, 768)), canal_floor)                       # A: east, away from the city
    plan.paint(P((2560, 768, 3072, 2816)), canal_floor)                   # B: the turn north
    plan.paint(P((3072, 2304, 4352, 2816)), canal_floor)                  # C: the fork's east arm
    plan.paint(P((4352, 2304, 4608, 2816)), culvert)                      #    its end: a culvert to the east gate (x 4608)
    plan.paint(P((2560, 2816, 3072, 3584)), canal_floor)                  # D: the fork's north arm
    # (the north and south gates' culverts under a deck at the road's height, not a block of concrete: the owner, 26
    #  November, "a big dumb concrete block/brush ... that shouldn't be there, and there is no combine wall between it
    #  and the city")
    decked = ("under", floor_z, MAT["canal_floor"], road_z - 16, MAT["quay_floor"])
    plan.paint(P((2560, 3584, 3072, 3840)), decked)                       #    its end: a culvert to the north gate (y 3840)
    plan.paint(P((2560, 0, 3072, 256)), decked)                           # under the turn north, a culvert to the south gate (y 0): where the canal ring's south half comes in (22 November)
    plan.paint(P((3072, 1280, 3328, 1664)), ("low", floor_z, MAT["canal_floor"], floor_z + 192)) # a low bay off B: somewhere to hide
    plan.paint(P((64, 768, 256, 896)), doorway)                           # where the quay's footbridge lands, in the north wall
    plan.paint(P((2432, 1792, 2560, 2048)), doorway)                      # the second footbridge's west end, in B's west wall (wall on every side but the front)
    #                                                                       (its east end lands on the road on the east bank)

    # the road round the canal's east side (the owner, 23 November: the ring's street "just ends at the canal ... you need
    # to compensate for the road hitting the canal by either making a bridge or having it go around the canal"; they chose
    # round its east side): the ring brings it to this piece's south edge and takes it on at its north edge
    # (map_corridor.ROUND); here it runs up B's east bank as the ring's street does (the canal's edge, the tracks, the road
    # and its pavements), over the east arm on a bridge, with the Combine wall's core along its far side. The low bay off B
    # is a room under it.
    R = mc.ROUND
    road_y1, road_y2 = R["canal"]
    arm_y1, arm_y2 = R["arm"]
    core_top = road_z + mc.WALL_H - 8
    street, core = mc.east_bank(R["mid"], road_y1, road_y2)
    road_cells, under_cells = set(), set()
    for c, mat in sorted(street.items()):
        if arm_y1 <= c[1] * CELL < arm_y2:
            continue      # (the arm: the bridge carries the road over it)
        spec = plan.cells.get(c)
        if spec and spec[0] == "low" and spec[3] <= road_z - 16:
            plan.cells[c] = ("under", spec[1], spec[2], spec[3], mat)
            under_cells.add(c)
        else:
            plan.cells[c] = ("open", road_z, mat)
            road_cells.add(c)
    core = {c for c in core if not arm_y1 <= c[1] * CELL < arm_y2}
    for c in core:
        plan.cells[c] = ("low", core_top, mc.CORE, sky)
    # the Combine wall on the banks that look to the city, where no street runs (the owner, 25 November: "every section of
    # the canal that has a side/face towards the city MUST have a combine wall there"): A's south bank from the quay
    # to the south gate's culvert, A's north bank, B's and D's west bank up to the north gate
    # (set back on the top of the canal's own wall, never out over the canal: 128 back on A's south bank, where the city's
    #  edge is 256 behind the canal's face, 192 on the others; not A's west end, where the city's buildings stand close)
    #  beside the two gates' culverts it stands at their decks' edge, a return joining it to the wall set back)
    bank, bank_front, bank_ledges = mc.bank_core(
        plan.cells, [P((640, 192, 2560, 256)) + (2,), P((0, 768, 2560, 832)) + (3,), P((2496, 768, 2560, 3584)) + (3,), P((2496, 3584, 2560, 3840)), P((2496, 0, 2560, 256))],
        core_top, sky, fill=[P((2304, 3584, 2496, 3648))])

    vmf = Vmf()
    cells = plan.cells

    # the sky the road sees above this piece's own (lower) sky: what the owner's brush 15074 did, from the lid up
    vmf.world_box(B(0, 0, plan.top, 640, 16, args.road_sky), MAT["sky"], MAT["sky"], MAT["sky"])

    # the two gates, closed until something is joined: each cap is inside the canal's own last 64 units
    gate_cap(vmf, B(4544, 2304, floor_z, 4608, 2816, floor_z + GATE_HIGH), B(4520, 2304, floor_z, 4528, 2816, floor_z + GATE_HIGH), "y", "LC canal: east gate's cap (delete to join)")
    gate_cap(vmf, B(2560, 3776, floor_z, 3072, 3840, road_z - 16), B(2560, 3752, floor_z, 3072, 3760, road_z - 16), "x", "LC canal: north gate's cap (delete to join)")
    gate_cap(vmf, B(2560, 0, floor_z, 3072, 64, road_z - 16), B(2560, 80, floor_z, 3072, 88, road_z - 16), "x", "LC canal: south gate's cap (delete to join the canal ring)")
    # (and over each gate's deck and the Combine wall's core beside it, a wall of sky at the piece's edge until the ring is
    #  joined, whose own squares carry them on)
    vmf.world_box(B(2496, 3824, road_z, 3072, 3840, sky + 16), MAT["sky"], MAT["sky"], MAT["sky"], vis="LC canal: north gate's cap (delete to join)")
    vmf.world_box(B(2496, 0, road_z, 3072, 16, sky + 16), MAT["sky"], MAT["sky"], MAT["sky"], vis="LC canal: south gate's cap (delete to join the canal ring)")
    # ...and the road on the east bank at both its ends, where the ring carries it on
    mc.road_cap(vmf, "LC canal", "the east road's south", R["mid"], road_y1, road_y1 + 64, sky)
    mc.road_cap(vmf, "LC canal", "the east road's north", R["mid"], road_y2 - 64, road_y2, sky)
    # (where the pieces joined at the gates and the road's ends may overlap this one's walls: both solid, as a chain's gates allow)
    fr_line = R["mid"] + mc.FRONT + 64
    args.allow_overlap = [B(2368, -64, 0, 3264, 64, sky + 64), B(2368, 3776, 0, 3264, 3904, sky + 64), B(4544, 2112, 0, 4672, 3008, sky + 64),
                          (R["mid"] + 192, road_y1 - 128, 0, fr_line + 192, road_y1 + 128, sky + 64), (R["mid"] + 192, road_y2 - 128, 0, fr_line + 192, road_y2 + 128, sky + 64)]

    # areaportals: across each gate's culvert and across the road's end, so what is beyond one is drawn only as far as
    # it can be seen through it (each stands a little in from the opening, so it has air on both sides even when capped)
    pv = "LC canal: areaportals"
    vmf.areaportal(B(4478, 2304, floor_z, 4480, 2816, floor_z + GATE_HIGH), pv)
    vmf.areaportal(B(2560, 3710, floor_z, 3072, 3712, road_z - 16), pv)
    vmf.areaportal(B(2560, 128, floor_z, 3072, 130, road_z - 16), pv)
    vmf.areaportal(B(0, 32, road_z, 640, 34, sky), pv)

    if args.test:
        # by itself the canal is open where the road comes in (that side is the city): for a test alone, a wall there
        tv = "LC canal: for testing alone (never in the real map)"
        vmf.world_box(B(-64, -64, plan.base, 704, 0, plan.top), MAT["sky"], MAT["sky"], MAT["sky"], vis=tv)
        test_extras(vmf, W(320, 128, road_z + 16), 90, tv)

    # stairs from the quay down into the canal, along its south wall: a landing, then 31 steps east
    steps = [B(512, 256, floor_z, 640, 384, road_z)]
    for i in range(31):
        steps.append(B(640 + 12 * i, 256, floor_z, 652 + 12 * i, 384, road_z - 8 * (i + 1)))
    vmf.detail(steps, MAT["canal_wall"], top=MAT["stairs"])
    # a low wall along the quay's edge (open where the footbridge starts) and round the landing
    vmf.detail([B(0, 240, road_z, 72, 256, road_z + 40), B(248, 240, road_z, 512, 256, road_z + 40), B(512, 368, road_z, 640, 384, road_z + 40), B(512, 256, road_z, 528, 368, road_z + 40)], MAT["canal_wall"])

    no_bank = [P((448, 192, 1088, 320)), P((3008, 1792, 3136, 1856)), P((2560, 192, 3072, 320))]   # the stairs; the ladder's slot (below); the south gate's mouth
    # (and no trim along the walls' tops where a deck rests on them: it would stand 16 proud of the deck: where the second
    #  footbridge meets the road, and the arm's walls under the road's bridge)
    no_bank += [P((3064, 1856, 3080, 1984)), (R["mid"] + mc.EDGE, arm_y1 - 8, fr_line, arm_y1 + 8), (R["mid"] + mc.EDGE, arm_y2 - 8, fr_line, arm_y2 + 8)]
    # what is already on the walls: nothing put on them after this may come within 24 units of any of it
    taken = [B(448, 256, floor_z, 1088, 384, road_z + 64),                                    # the stairs and their landing
             B(2560, 192, floor_z, 3072, 320, floor_z + GATE_HIGH + 64),                       # the south gate's mouth
                             B(64, 256, road_z - 16, 256, 768, road_z + 40),                 # the quay's footbridge
                             B(2560, 1856, road_z - 16, 3072, 1984, road_z + 40),            # the second footbridge
                             B(3008, 1792, floor_z, 3072, 1856, road_z + 128)]               # the ladder

    # --- things in the long stretches, as the ring has (the owner: "the canals are kind of empty") ------------------------
    sv = "LC canal: set pieces"
    set_blocked, lanes = [], []

    def static(model, x, y, yaw):
        cls, keys = standing_prop(model)      # (a physics model as a prop_dynamic_override: the compiler deletes it as a prop_static)
        at = W(x, y, stand_z(model, floor_z))      # (standing ON the floor, by its size)
        vmf.point(cls, at, dress_keys(model, at[0], at[1], dict(keys, model=model, angles="0 %d 0" % yaw)), sv)
    # a container between the stairs and the pipes; cars pushed in beyond the pipes
    static("models/props_wasteland/cargo_container01.mdl", 1300, 590, 8)
    for model, x, y, yaw in (("models/props_vehicles/car002a_physics.mdl", 2080, 470, 25), ("models/props_vehicles/car005a_physics.mdl", 2260, 580, 190),
                             ("models/props_vehicles/tire001c_car.mdl", 2180, 420, 0), ("models/props_junk/trashdumpster02.mdl", 2420, 600, 95)):
        static(model, x, y, yaw)
    # a boat and rubble in the turn north; a street carried over the east arm; a barricade in the north arm
    static("models/props_canal/boat001a.mdl", 2800, 1120, 100)
    for model, x, y, yaw in (("models/props_debris/concrete_chunk01a.mdl", 2740, 2190, 40), ("models/props_debris/broken_pile001a.mdl", 2890, 2240, 200),
                             ("models/props_debris/concrete_chunk02a.mdl", 2700, 2300, 110)):
        static(model, x, y, yaw)
    # (the street over the east arm is the road on the east bank, on a bridge from B's edge to the Combine wall's line,
    #  a parapet on its east side looking up the arm; its west side has the road's own parapet)
    taken.append(mc.road_deck(vmf, sv, R["mid"] + mc.EDGE, arm_y1, fr_line, arm_y2, "y", parapets=[(fr_line - 16, arm_y1, fr_line, arm_y2, road_z + 8)], tops=mc.bank_tops(R["mid"])))
    static("models/props_debris/barricade_tall01a.mdl", 2740, 3160, 20)
    set_blocked += [(1080, 500, 1520, 680), (2000, 400, 2500, 660), (2700, 1000, 2900, 1240), (2650, 2130, 2960, 2360), (2640, 3060, 2860, 3260)]
    lanes += [(1300, 430), (2240, 400), (2940, 1120), (2990, 2240), (2940, 3160)]

    # --- two footbridges that go somewhere: the quay's lands in a doorway in the wall, barred at its back; the second
    # goes from a doorway like it in B's west wall to the road on the east bank ----------
    rail = MAT["canal_wall"]
    vmf.detail([B(64, 256, road_z - 16, 256, 768, road_z)], MAT["beam"], top=MAT["quay_floor"])                        # from the quay, over A
    vmf.detail([B(64, 256, road_z, 72, 768, road_z + 40), B(248, 256, road_z, 256, 768, road_z + 40)], rail)
    vmf.detail([B(2560, 1856, road_z - 16, 3072, 1984, road_z)], MAT["beam"], top=MAT["quay_floor"])                   # over B, from wall to wall
    vmf.detail([B(2560, 1856, road_z, 3072, 1864, road_z + 40), B(2560, 1976, road_z, 3072, 1984, road_z + 40)], rail)
    barred(vmf, B(64, 872, road_z, 256, 880, road_z + 112), "x", "LC canal: details", back=B(64, 888, road_z, 256, 896, road_z + 112))
    barred(vmf, B(2448, 1792, road_z, 2456, 2048, road_z + 112), "y", "LC canal: details", back=B(2432, 1792, road_z, 2440, 2048, road_z + 112))
    # a ladder up to the second bridge, in a slot left in the east bank: set up the way the owner's own map does its ladders
    # (ladder pieces 128 tall, the climbing line 28 out from them, a place to step off at each end)
    for z, model, yaw in ((floor_z, "metalladder002", 180), (floor_z + 128, "metalladder002", 180), (road_z, "metalladder002b", 0)):
        vmf.point("prop_static", W(3070, 1824, z), {"model": "models/props_c17/%s.mdl" % model, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6",
                                                    "fademindist": "-1", "fadescale": "1"}, "LC canal: details")
    vmf.point("func_useableladder", W(3042, 1824, floor_z + 130), {"point0": "%d %d %d" % W(3042, 1824, floor_z + 4), "point1": "%d %d %d" % W(3042, 1824, road_z + 12),
                                                                    "spawnflags": "0", "StartDisabled": "0"}, "LC canal: details")
    for x, z in ((3000, floor_z + 1), (3112, road_z + 1)):
        vmf.point("info_ladder_dismount", W(x, 1824, z), {}, "LC canal: details")

    # a little left lying about (few, and in a visgroup of their own: delete it and they're gone)
    rnd = random.Random(18)
    junk = (
        ("models/props_c17/oildrum001.mdl", 1700, 560, 0), ("models/props_c17/oildrum001.mdl", 1750, 600, 0), ("models/props_junk/wood_pallet001a.mdl", 1620, 500, 8),
        ("models/props_junk/wood_crate001a.mdl", 3200, 1340, 20), ("models/props_junk/wood_crate002a.mdl", 3250, 1420, 20), ("models/props_junk/wood_pallet001a.mdl", 3180, 1600, 8),
        ("models/props_vehicles/tire001c_car.mdl", 2760, 2400, 12), ("models/props_canal/boat001a.mdl", 1830, 470, 24), ("models/props_canal/boat002b.mdl", 4000, 2620, 24),
    )
    import map_assets
    for model, x, y, up in junk:      # (standing on the floor, by the model's own size: the dressing brings them down onto the mud)
        z = stand_z(model, floor_z + 1) if map_assets.size(model) else floor_z + 1 + up
        at = W(x, y, z)
        vmf.point("prop_physics", at, dress_keys(model, at[0], at[1], {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15),
                                                                        "spawnflags": loose_flags(model)}), "LC canal: props")

    # --- the road on the east bank: what stands on it, as on the ring's street; the Combine wall along its far side -----
    # (the parapet stops where the second footbridge and the ladder from the canal's floor come up onto it, and planks
    #  cross the tracks there; a path node every 512 on the edge walk and on the road)
    road_nodes = []
    gap1, gap2 = oy + 1792, oy + 1984       # (the ladder's slot and the footbridge, y 3648 to 3840)
    mc.east_bank_dress(vmf, "LC canal: the road on the east bank", R["mid"], edge=[(road_y1, gap1), (gap2, road_y2)], rail=[(road_y1, gap1 + 64), (gap2, road_y2)],
                       tracks=[(road_y1, road_y2)], pave=[(road_y1, road_y2)], outer=[(road_y1, road_y2)],      # (no planks over the tracks: the owner, 26 November, "a dumb looking wood slab on the tracks")
                       
                       lane=lambda x, y, z: road_nodes.append((x, y, z)), lanes_at=range(road_y1 + 192, road_y2, 512))
    import types      # (not over its last three squares at the north edge, where the ring's stretch beyond ends in a pier over the join,
    #                    nor over the two each side of the arm, so no pier overhangs the water)
    dressed = {c for c in core if c[1] * CELL < road_y2 - 192 and not arm_y1 - 128 <= c[1] * CELL < arm_y2 + 128}
    mc.combine_wall(types.SimpleNamespace(combine_core=dressed | bank, deck=road_cells | under_cells, wall_front=bank_front, wall_cells=plan.cells,
                                          name="canal", vmf=vmf, vis="LC canal", notes=[]))

    # --- banks, lip, ribs, Valve's outfalls and caged lamps, the dished floor and its mud: the canal modules' dressing ----
    # (the pipes across the long run where the beam was: a big one and a small one on saddles, as before. The dressing sees
    #  the road as wall to its own height and the room under it as a low room, as a chain's does; the chain link along the
    #  walls' tops stays off the road, the room under it and the Combine wall's core)
    import map_modules
    plan.walls()
    view = mc.View(plan, {c: (("solid", road_z) if c in road_cells else ("solid", core_top) if c in core else ("low",) + spec[1:4] if c in under_cells else spec)
                          for c, spec in plan.cells.items()})
    walled = mc.View(plan, {c: spec for c, spec in plan.cells.items() if c not in core and c not in under_cells})
    ch, _ = map_modules.dress_piece(vmf, plan, "canal", "LC canal", taken, no_bank, [P((2560, 0, 3072, 256))], 71, pipes=[("x", ox + 1600, oy + 256, oy + 768)], rim=wall_top,
                                    view=view)

    # --- where the city's people can walk: the flat of the floor, the quay, the stairs, the bridges ----------------
    set_blocked = set_blocked + [(c[0] * CELL - ox, c[1] * CELL - oy, c[0] * CELL + CELL - ox, c[1] * CELL + CELL - oy) for c in sorted(bank_ledges | bank)]      # (the Combine wall's ledge and its core's top: nobody walks there)
    blocked = [(512, 256, 1024, 384), (4480, 2304, 4608, 2816), (2560, 3712, 3072, 3840)] + set_blocked # (the stairs, behind each gate's bars, the set pieces)
    node_id = [args.first_node]

    dim = []       # (the owner, 20 November: the ring's southern half "a bit dimmer"; this canal is its south-east: map_ring.py)

    def node(x, y, z):
        vmf.point("info_node", W(x, y, z + 40), {"nodeid": node_id[0]}, "LC canal: path nodes")
        node_id[0] += 1
        if W(x, y, 0)[1] < 4600 and all((x - a) ** 2 + (y - b) ** 2 >= 700 ** 2 for a, b, _ in dim):
            dim.append((x, y, z))
    def air_node(x, y, z):      # (flying nodes for scanners over the canal: Valve's, the owner, 21 November)
        vmf.point("info_node_air", (x, y, z), {"nodeid": node_id[0], "nodeheight": "0"}, "LC canal: flying nodes")
        node_id[0] += 1
    ch.nodes(lambda x, y, z: node(x - ox, y - oy, z), [P(r) for r in blocked], air=air_node, share=node_share("canal"), extra=len(lanes) + 11 + len(road_nodes))
    for x, y in lanes:
        node(x, y, floor_z)
    for x, y, z in road_nodes:
        node(x - ox, y - oy, z)
    fences = fence(vmf, walled, 96, "LC canal: fence along the walls' tops", top=wall_top)
    for x, y, z in ((576, 320, road_z), (736, 320, road_z - 64), (832, 320, road_z - 128), (928, 320, road_z - 208), (1056, 320, floor_z),
                    (160, 384, road_z), (160, 512, road_z), (160, 640, road_z), (2688, 1920, road_z), (2816, 1920, road_z), (2944, 1920, road_z)):
        node(x, y, z)

    # cover hints behind its wrecks and barricades, as the modules have (Valve's; in what is left of its share)
    node_id[0] += map_modules.piece_cover_hints(vmf, lambda x, y: plan.cells.get((x // CELL, y // CELL)), "LC canal", "canal", node_id[0],
                                                node_share("canal") - (node_id[0] - args.first_node), ch.dished)
    for x, y, z in dim:
        vmf.point("info_target", W(x, y, z + 64), {"targetname": "lc_mood_dim"}, "LC canal: the dimmer southern half (marks for the gamemode)")
    # the APC's route up this piece's stretch of the ring road (the ring's own marks end at this piece's south edge and
    # start again at its north edge: map_corridor.apc_route), numbered after the ring's so the loop closes in name order
    for n, (x, y) in enumerate(mc.apc_marks([(R["mid"] + mc.APC_ROAD, road_y1 + mc.APC_END), (R["mid"] + mc.APC_ROAD, road_y2 - mc.APC_END)])):
        vmf.point("info_target", (x, y, road_z + mc.APC_UP), {"targetname": mc.APC_NAME % (mc.APC_CANAL + n)}, "LC canal: the APC's route (marks for the gamemode)")

    # reflections: one cubemap for each stretch, at eye height
    for x, y, z in ((320, 128, road_z), (800, 512, floor_z), (2000, 512, floor_z), (2816, 1500, floor_z), (3200, 1472, floor_z), (2816, 2560, floor_z), (3900, 2560, floor_z), (2816, 3300, floor_z)):
        vmf.point("env_cubemap", W(x, y, z + 72), {"cubemapsize": "0"})

    # the checks: the opening onto the road is stopped up, then a flood from the air over the canal floor
    stopper = B(0, -64, road_z - 64, 640, 0, plan.top)
    problems, air = check(vmf, W(1280, 512, floor_z + 32), [] if args.test else [stopper])
    # a doorway is open on its front only: wall on its other three sides (one that opened sideways onto the east arm
    # showed the black wall at its back edge-on: the owner, 19 November)
    for (x1, y1, x2, y2, front) in ((64, 768, 256, 896, "south"), (2432, 1792, 2560, 2048, "east")):
        for i in range(x1 // CELL - 1, x2 // CELL + 1):
            for j in range(y1 // CELL - 1, y2 // CELL + 1):
                if x1 // CELL <= i < x2 // CELL and y1 // CELL <= j < y2 // CELL:
                    continue
                side = "west" if i < x1 // CELL else "east" if i >= x2 // CELL else "south" if j < y1 // CELL else "north"
                ahead = {"south": j < y1 // CELL, "north": j >= y2 // CELL, "west": i < x1 // CELL, "east": i >= x2 // CELL}[front]
                if cells.get((i + ox // CELL, j + oy // CELL), ("solid",))[0] != "solid" and not ahead:
                    problems.append("the doorway at (%d %d) is open on its %s side at (%d %d): it should be wall" % (ox + x1, oy + y1, side, ox + i * CELL, oy + j * CELL))
    world_n = sum(1 for _, w in vmf.boxes if w)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    st = ch.stats
    print("canal: %d sealing brushes, %d detail boxes, %d sloped or round shapes, %d mud patches, %d entities (%d path nodes, ids %d to %d)" % (
        world_n, len(vmf.boxes) - world_n - st["mud"], vmf.shapes, st["mud"], len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1))
    print("  details: %d banks, %d corner fills, %d lengths of wall trim with %d ribs, %d outfalls, 2 pipes, 2 footbridges, 1 ladder, %d runs of fence" % (
        st["banks"], st["fills"], len(ch.made.get("walls", [])), st["ribs"], st["stubs"], fences))
    print("  set pieces: a container, wrecked cars and a skip, a boat, rubble, a street carried over the east arm, a barricade; the walls' concrete ends at z %d" % wall_top)
    print("  the road round its east side: up the east bank from y %d to y %d (the ring's road at both ends, capped for this file alone), over the east arm on a bridge, "
          "the Combine wall's core along its far side at x %d..%d" % (road_y1, road_y2, fr_line, fr_line + 64))
    print("  it fills x %d to %d, y %d to %d, z %d to %d (the road's sky plug to %d)" % (min(xs), max(xs), min(ys), max(ys), plan.base, plan.top, args.road_sky))
    print("  gates (a culvert %d wide, %d high, floor z %d): east at x %d, y %d to %d; north at y %d, x %d to %d; south (the canal ring's) at y %d, x %d to %d" % (
        GATE_WIDE, GATE_HIGH, floor_z, ox + 4608, oy + 2304, oy + 2816, oy + 3840, ox + 2560, ox + 3072, oy, ox + 2560, ox + 3072))
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (a flood from the air inside stays inside, %s)" % (
            "by itself: this is the test version" if args.test else "with the road's opening stopped up: by itself this file is OPEN to the road and will leak"))
    return vmf, problems


def self_line(plan, axis, line):
    """A wall's line in the map's coordinates (the plan's own are from its origin)."""
    return (plan.origin[1] if axis == "x" else plan.origin[0]) + line


def self_along(plan, axis, v):
    return (plan.origin[0] if axis == "x" else plan.origin[1]) + v


def bad_brushes(text, limit=6):
    """Every solid in a VMF's text rebuilt from its planes, as vbsp does (the meeting of their half-spaces): one that comes
    out empty, unbounded ("bounds out of range": vbsp stops), or with a face whose plane holds none of it (a plane facing
    the wrong way, from corners listed out of turn) is a problem. Displacements are left out."""
    import itertools
    def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
    def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
    big = 60000.0
    box = [((1, 0, 0), big), ((-1, 0, 0), big), ((0, 1, 0), big), ((0, -1, 0), big), ((0, 0, 1), big), ((0, 0, -1), big)]
    plane_re = re.compile(r'"plane" "\(([-\d.e ]+)\) \(([-\d.e ]+)\) \(([-\d.e ]+)\)"')
    out = []
    for m in re.finditer(r'\n(\t*)solid\n\1\{\n\1\t"id" "(\d+)"(.*?)\n\1\}', text, re.S):
        body = m.group(3)
        if "dispinfo" in body:
            continue
        pl, why = [], None
        for pm in plane_re.finditer(body):
            a, b, c = [tuple(float(x) for x in g.split()) for g in pm.groups()]
            n = cross(sub(c, a), sub(b, a))
            ln = dot(n, n) ** 0.5
            if ln < 1e-9:
                why = "a face with no plane (its three points in a line)"
                break
            n = (n[0] / ln, n[1] / ln, n[2] / ln)
            pl.append((n, dot(n, a)))
        if not why:
            allp, verts = pl + box, []
            for i, j, k in itertools.combinations(range(len(allp)), 3):
                (n1, d1), (n2, d2), (n3, d3) = allp[i], allp[j], allp[k]
                c23, c31, c12 = cross(n2, n3), cross(n3, n1), cross(n1, n2)
                den = dot(n1, c23)
                if abs(den) < 1e-9:
                    continue
                v = tuple((d1 * c23[q] + d2 * c31[q] + d3 * c12[q]) / den for q in range(3))
                if all(dot(n, v) <= d + 0.05 for n, d in allp):
                    verts.append(v)
            if len(verts) < 4:
                why = "empty (its planes leave nothing between them)"
            elif any(max(abs(c) for c in v) > 32768 for v in verts):
                why = "unbounded: vbsp stops on it (\"bounds out of range\"): a shape's corners listed out of turn"
            elif any(sum(1 for v in verts if abs(dot(n, v) - d) < 0.05) < 3 for n, d in pl):
                why = "a face whose plane holds none of it (corners listed out of turn)"
        if why:
            first = plane_re.search(body)
            where = first.group(1) if first else "?"
            out.append("brush %s near (%s) is %s" % (m.group(2), where, why))
            if len(out) >= limit:
                break
    return out


def against(vmf, path, expected, allow=()):
    """Does anything in the piece run into anything in the owner's map? (Boxes against boxes: a brush of theirs that is
    not a box may be reported though it only comes near.) expected: ids of their brushes the piece replaces. allow:
    boxes round the piece's gates where another piece's walls may overlap its own (both solid: harmless)."""
    import map_survey
    theirs = []
    root = map_survey.read_vmf(path)
    for top in root.kids:
        for k in (top.kids if top.name in ("world", "entity") else []):
            if k.name == "solid":
                b = map_survey.make_brush(k, "x")
                if b:
                    theirs.append(b)
    grid = map_survey.Grid(512)
    for b in theirs:
        grid.add(b)
    hits = {}
    for box, _ in vmf.boxes:
        for b in grid.near((box[0] + box[3]) / 2.0, (box[1] + box[4]) / 2.0, max(box[3] - box[0], box[4] - box[1]) / 2.0):
            if b.id not in expected and all(box[k] < b.maxs[k] - 0.5 and box[k + 3] > b.mins[k] + 0.5 for k in range(3)):
                cut = [max(box[k], b.mins[k]) for k in range(3)] + [min(box[k + 3], b.maxs[k]) for k in range(3)]
                if any(all(a[k] <= cut[k] + 0.5 and cut[k + 3] <= a[k + 3] + 0.5 for k in range(3)) for a in allow):
                    continue
                hits[b.id] = (b.mins, b.maxs)
    if not hits:
        print("  checked against %s: nothing in the piece runs into anything in it%s" % (path.split("/")[-1], (" (but brush %s, which it replaces)" % ", ".join(sorted(expected))) if expected else ""))
        return []
    return ["it runs into %d brushes of the map's: %s" % (len(hits), "; ".join("id %s at x %d..%d y %d..%d z %d..%d" % ((i,) + tuple(int(v) for pair in zip(m[0], m[1]) for v in pair)) for i, m in sorted(hits.items())[:5]))]


def main():
    import map_cistern
    import map_forest
    import map_modules
    import map_raven
    import map_ring
    pieces = {"chain": map_modules.chain, "module": map_modules.module, "cistern": map_cistern.cistern, "canal": canal, "ring": map_ring.ring, "forest_bunker": map_forest.forest_bunker, "forest_cave": map_forest.forest_cave, "ravenholm": map_raven.ravenholm}
    ap = argparse.ArgumentParser(description="Write a new piece of map as its own VMF (never touches the owner's VMF).")
    ap.add_argument("piece", choices=sorted(pieces))
    ap.add_argument("--out", help="the VMF to write (default: lc_PIECE.vmf)")
    ap.add_argument("--origin", type=int, nargs=2, default=None, metavar=("X", "Y"), help="where the piece sits on the map (default: where it joins what's already there)")
    ap.add_argument("--floor", type=int, default=None, help="forests: the height of the gate's floor (default 400: the canals' floor)")
    ap.add_argument("--road-sky", type=int, default=2784, help="canal: the height of the sky over the road it joins (default 2784)")
    ap.add_argument("--first-node", type=int, default=None, help="the first path node id to use (default: 4000 canal, 4400 and 4600 the forests, 5000 the ring, 5300 ravenholm; the map's own stop at 3043)")
    ap.add_argument("--preview", help="forests: also write a picture of the piece from above to this file (needs Pillow)")
    ap.add_argument("--against", nargs="+", help="the owner's own VMF: also check that nothing in the piece runs into anything in it (apart from the brush the piece replaces)")
    ap.add_argument("--layout", default="map_layouts/south.txt", help="chain: the layout to build (a text file: where it starts, then a module a line)")
    ap.add_argument("--name", default="", help="module: which one (leave out to list them)")
    ap.add_argument("--heading", choices=["E", "N", "W", "S"], default=None, help="chain, module: the way it heads from its start (default: the layout's; east)")
    ap.add_argument("--rim", type=int, default=None, help="chain, module: where the walls' concrete ends (default 784, the east canal's; the ring's west end is 968)")
    ap.add_argument("--opt", nargs="*", default=None, help="module: the words a layout line would have after its name (\"--opt 1280\")")
    ap.add_argument("--views", default=None, help="chain, module: also draw pictures of it into this folder (map_view.py: needs numpy and Pillow)")
    ap.add_argument("--ascii", action="store_true", help="chain: also print its plan in letters (free to read, where a picture is not)")
    ap.add_argument("--flip", action="store_true", help="module: its side room on the other side of the canal")
    ap.add_argument("--test", action="store_true", help="write lc_PIECE_test.vmf instead: the piece made to compile and walk by itself (a spawn point, a sun, "
                    "and for the canal a wall where the road comes in). Never put the test file in the real map.")
    args = ap.parse_args()
    if args.piece == "canal":
        args.origin = args.origin or (3328, 1856)
        args.first_node = args.first_node or 4000
    if args.piece == "ring":
        args.first_node = args.first_node or 5000
    if args.piece == "ravenholm":
        args.first_node = args.first_node or 5300
    vmf, problems = pieces[args.piece](args)
    if vmf.nudged:
        print("  props moved out of a way or a door's swing as they were placed: %d (%s)" % (len(vmf.nudged), ", ".join(
            "%s by %d" % (m.rsplit("/", 1)[-1], math.hypot(b[0] - a[0], b[1] - a[1])) for m, a, b in vmf.nudged[:6])))
    for p in ways_problems(vmf):         # (every piece and module: nothing stands in a doorway, gate, hole or walkway)
        print("  PROBLEM: " + p)
        problems.append(p)
    if args.against:
        clashes = []
        for path in args.against:      # (the owner's map, and any other piece's file: nothing may run into any of them)
            clashes += against(vmf, path, getattr(args, "expect_overlap", {"15074"} if args.piece == "canal" else set()), getattr(args, "allow_overlap", ()))
        for p in clashes:
            print("  PROBLEM: " + p)        # (the piece's own function has already printed its own)
        problems += clashes
    out = args.out or getattr(args, "out_name", None) or "lc_%s%s.vmf" % (args.piece, "_test" if args.test else "")
    text = vmf.text()
    for p in bad_brushes(text):         # (as vbsp builds each brush from its planes: the owner's compile stopped on one, 22 November)
        print("  PROBLEM: " + p)
        problems.append(p)
    import map_stairs                   # (the owner's walk, 22 November: "WE NEED A CHECK to see if stairs go into walls or geometry")
    import map_walk                     # (and: "MAKE A CHECK TO CHECK FOR PLAYER ROOM TO WALK")
    for p in map_stairs.check_text(text, as_built=vmf.stairs_as_built) + map_walk.check_text(text):
        print("  PROBLEM: " + p)
        problems.append(p)
    with open(out, "w") as f:
        f.write(text)
    print("  written: " + out)
    import os
    import map_budget                   # (what it spends of the compiler's limits: the owner's compile of the ring ran out of faces, 23 November)
    if os.path.isfile(out):
        print("  " + map_budget.line(map_budget.count(out)))
    line, look = node_report(vmf, out[3:-4].replace("_test", "") if out.startswith("lc_") else out)
    if line:
        print("  " + line)
    if look:
        print("  LOOK: " + look)
    try:      # (the owner's corrections, checked by machine: _dev/reference/lessons.json, map_lint.py)
        import map_lint
        for line in map_lint.check(out, views=getattr(args, "view_list", None), air=getattr(vmf, "flooded", None)):
            print("  LOOK: " + line)
    except Exception as e:
        print("  (map_lint could not run: %s)" % e)
    if getattr(args, "after_write", None):
        args.after_write(out)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
