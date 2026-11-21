#!/usr/bin/env python3
"""
Living City: the owner's corrections, checked by machine (_dev/reference/lessons.json, the lessons whose "check" names
map_lint).

    python3 map_lint.py FILE.vmf [more.vmf ...]      every finding, one line each
    python3 map_lint.py FILE.vmf --only overlap       one kind (overlap, door, offlamp, fire, mattress, view, water, rope, flush, bare, wire, palette)

Every build runs it on the file it writes and prints what it finds as LOOK lines (map_build.py), so
map_modules_check.py shows them with the rest. A finding is a thing to look at, not always a fault: a model's box is
often bigger than the model. What each kind means:

  overlap   two solid props whose boxes take up the same space (a couch inside a table: the owner, 20 November)
  door      a door model that does not open (only prop_door_rotating opens): "I can't tell where I can actually go in"
  offlamp   an unlit lamp model with a light shining from it, or a lit one with none (_on / _off)
  fire      an env_fire over a drum or a raised floor that will drop to the ground (spawnflag 16 keeps it up)
  mattress  the loose mattress not turned over (it lies on its back unturned)
  view      a module's viewpoint inside a prop or a wall (its picture shows nothing)
  water     a water brush whose top is level with a floor (they flicker through each other)
  rope      a rope or cable end tied to nothing
  palette   materials the owner's City 18 map never uses (listed once, the commonest first): use theirs where one fits
  flush     two visible faces of different brushes lying in the same plane, facing the same way and overlapping:
            they flicker through each other in game (z-fighting; the owner, 21 November). Faces made of
            axis-aligned rectangles only; a face buried in another brush is not counted.
  wire      Valve's five wiring rules (docs/dev/map-modules.md, "Wiring the way Valve does"): outputs sent to
            things not in the map, !player (player 1 only on a shared server), triggers that name nobody, sounds
            played once without "not looped" (32) or loops that carry it, timers that only dress a place left
            running, a door hanging in an areaportal that nothing closes, a valve that is a press button
  bare      a big plain wall: one face of one material at least 384 long and 256 tall with nothing on it or in front
            of it (no ledge, trim, prop, decal or overlay within 24): lay it in courses, break it with pilasters,
            dress it (lessons valve-wall-bands, valve-column-rhythm, facades). The six biggest, and how many.
"""
import argparse
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

DOORS = re.compile(r"models/props_c17/door0\d|models/props_doors/")
SHELVES = re.compile(r"shelf|rack|locker|cupboard|closet|cabinet|counter|table|desk|bench|pallet|crate002|cart|cooler|display|stall|board|bed|workbench|truck|trailer|car0|van0|container|dumpster|cargo|pole|post|ladder|mast")


SHAPES = {}      # (a brush's box -> its planes, for the exact test of a point inside a sloped brush)
SIDES = {}       # (a brush's box -> ([(material, corners)], "world" or the entity's class), for the flush-face check)


def in_brush(p, box, pad=1.0):
    """Is the point inside the brush itself (its planes), not only its box?"""
    if not inside(p, box, pad):
        return False
    planes = SHAPES.get(box)
    if not planes:
        return True
    c = [(box[k] + box[k + 3]) / 2.0 for k in range(3)]
    for pl in planes:
        if len(pl) < 9:
            continue
        a, b, d = pl[0:3], pl[3:6], pl[6:9]
        u = [b[k] - a[k] for k in range(3)]
        v = [d[k] - a[k] for k in range(3)]
        n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
        ln = math.sqrt(sum(t * t for t in n)) or 1.0
        n = [t / ln for t in n]
        side_c = sum(n[k] * (c[k] - a[k]) for k in range(3))
        side_p = sum(n[k] * (p[k] - a[k]) for k in range(3))
        if side_c == 0:
            continue
        if side_p * side_c <= 0 or abs(side_p) < pad:
            return False
    return True


def corners_from_planes(planes):
    """Each face's corners from the planes alone (three points each), in the planes' order; None where it fails."""
    import numpy as np
    pl = []
    for p in planes:
        if len(p) < 9:
            return None
        a, b, c = np.array(p[0:3]), np.array(p[3:6]), np.array(p[6:9])
        n = np.cross(c - a, b - a)
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            return None
        n = n / ln
        pl.append((n, float(n @ a)))
    N = np.array([q[0] for q in pl])
    D = np.array([q[1] for q in pl])
    pts = []
    k = len(pl)
    for i in range(k):
        for j in range(i + 1, k):
            for l in range(j + 1, k):
                M = N[[i, j, l]]
                if abs(np.linalg.det(M)) < 1e-6:
                    continue
                v = np.linalg.solve(M, D[[i, j, l]])
                if (N @ v - D <= 0.05).all() or (N @ v - D >= -0.05).all():
                    pts.append(v)
    out = []
    for n, d in pl:
        on = []
        for v in pts:
            if abs(n @ v - d) < 0.05 and not any(np.linalg.norm(v - w) < 0.05 for w in on):
                on.append(v)
        out.append([tuple(round(float(x), 3) for x in v) for v in on] if len(on) >= 3 else None)
    return out


def nums(text):
    return [float(t) for t in text.replace("(", " ").replace(")", " ").replace("[", " ").replace("]", " ").split()]


def read(path):
    """(entities: [{key: value, '_solids': [box...]}], brushes: [(box, materials)]) from a VMF, quickly."""
    text = open(path, errors="replace").read()
    SHAPES.clear()      # (one file's brushes only: checking several files in one run must not mix them)
    SIDES.clear()
    ents, brushes = [], []
    pos = 0
    n = len(text)
    # walk top-level blocks: world and entity
    for m in re.finditer(r"^(world|entity)\s*\n\{", text, re.M):
        start = m.end()
        depth, i = 1, start
        while depth and i < n:
            c = text[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            i += 1
        body = text[start:i - 1]
        keys = {}
        for km in re.finditer(r'^\t"([^"]+)" "([^"]*)"', body, re.M):
            keys.setdefault(km.group(1).lower(), km.group(2))
        outs = []
        cm = re.search(r"^\tconnections\s*\n\t\{(.*?)^\t\}", body, re.M | re.S)
        if cm:
            for out, val in re.findall(r'"([^"]+)" "([^"]*)"', cm.group(1)):
                parts = val.split("\x1b") if "\x1b" in val else val.split(",")      # (ours hold the parts apart with the escape character, Valve's with commas)
                outs.append((out, (parts + ["", "", "", ""])[0], (parts + ["", ""])[1]))
        keys["_outputs"] = outs
        boxes = []
        kind_of = "world" if m.group(1) == "world" else keys.get("classname", "")
        for sm in re.finditer(r"^\tsolid\s*\n\t\{(.*?)^\t\}", body, re.M | re.S):
            vs = [nums(v) for v in re.findall(r'"v" "([^"]+)"', sm.group(1))]
            mats = set(x.lower() for x in re.findall(r'"material" "([^"]+)"', sm.group(1)))
            plane_only = not vs
            if plane_only:      # (a file from an older Hammer: no corner lists; work the corners out from the planes)
                faces = corners_from_planes([nums(pl) for pl in re.findall(r'"plane" "([^"]+)"', sm.group(1))])
                vs = [list(v) for f in faces for v in f] if faces else []
            if vs:
                box = tuple(min(v[k] for v in vs) for k in range(3)) + tuple(max(v[k] for v in vs) for k in range(3))
                planes = [nums(pl) for pl in re.findall(r'"plane" "([^"]+)"', sm.group(1))]
                boxes.append((box, mats))
                SHAPES[box] = planes
                sides = []
                for k, side in enumerate(re.findall(r"side\s*\{(.*?)\n\t\t\}", sm.group(1), re.S)):
                    mt = re.search(r'"material" "([^"]+)"', side)
                    pv = [nums(v) for v in re.findall(r'"v" "([^"]+)"', side)]
                    if not pv and plane_only and faces and k < len(faces) and faces[k]:
                        pv = [list(v) for v in faces[k]]
                    if mt and len(pv) >= 3:
                        sides.append((mt.group(1).lower(), pv))
                SIDES[box] = (sides, kind_of)
        if m.group(1) == "world":
            brushes += boxes
        else:
            keys["_solids"] = boxes
            ents.append(keys)
            if keys.get("classname", "") in ("func_detail", "func_brush", "func_door", "func_wall", "func_water_analog", "func_breakable"):
                brushes += boxes
    return ents, brushes


def origin(e):
    return tuple(nums(e.get("origin", "0 0 0"))[:3])


def angles(e):
    a = nums(e.get("angles", "0 0 0"))
    return (a + [0, 0, 0])[:3]


def prop_box(e):
    """The prop's box in the map, turned by its yaw (None if its size is unknown or it is tilted much)."""
    import map_assets
    model = e.get("model", "").lower()
    if not model.endswith(".mdl"):
        return None
    bb = map_assets.size(model)
    if not bb:
        return None
    p, y, r = angles(e)
    if abs(p) > 20 or abs(r) > 20 and abs(abs(r) - 180) > 20:
        return None
    o = origin(e)
    c, s = math.cos(math.radians(y)), math.sin(math.radians(y))
    xs = [o[0] + px * c - py * s for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
    ys = [o[1] + px * s + py * c for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
    z1, z2 = (o[2] + bb[2], o[2] + bb[5]) if abs(r) < 90 else (o[2] - bb[5], o[2] - bb[2])
    return (min(xs), min(ys), z1, max(xs), max(ys), z2)


def inside(p, b, pad=0.0):
    return all(b[k] + pad < p[k] < b[k + 3] - pad for k in range(3))


def overlap(a, b):
    d = [min(a[k + 3], b[k + 3]) - max(a[k], b[k]) for k in range(3)]
    return d[0] * d[1] * d[2] if min(d) > 0 else 0.0


def vol(b):
    return max(0.0, (b[3] - b[0]) * (b[4] - b[1]) * (b[5] - b[2]))


def short(model):
    return model.split("/")[-1].replace(".mdl", "")


def check(path, views=None, only=None, air=None):
    """air: the build's own flood (map_build.flood: the air players are in); a flush face looking into the void outside
    the map is then not counted."""
    ents, brushes = read(path)
    found = []

    def say(kind, text):
        if not only or only == kind:
            found.append("%s: %s" % (kind, text))
    solid_props = []
    for e in ents:
        cls = e.get("classname", "")
        if cls.startswith(("prop_static", "prop_dynamic", "prop_physics", "prop_door")):
            bx = prop_box(e)
            if bx and not e.get("parentname") and e.get("solid", "6") != "0":
                solid_props.append((e, bx))
    lights = [origin(e) for e in ents if e.get("classname") in ("light", "light_spot")]
    # door: a door model that does not open
    for e in ents:
        m = e.get("model", "").lower()
        if DOORS.search(m) and e.get("classname") != "prop_door_rotating" and not e.get("parentname"):
            o = origin(e)
            say("door", "%s at (%d %d %d) is a %s: only prop_door_rotating opens; board the doorway or make it a real door" % (short(m), o[0], o[1], o[2], e.get("classname")))
    # offlamp
    for e in ents:
        m = e.get("model", "").lower()
        if re.search(r"light.*_(on|off)\.mdl$|lamppost.*_(on|off)\.mdl$", m):
            o = origin(e)
            near = any(math.dist(o, l) < 56 for l in lights)
            if m.endswith("_off.mdl") and near:
                say("offlamp", "%s at (%d %d %d) has a light shining from it: use the _on model, or no light" % (short(m), o[0], o[1], o[2]))
    # fire
    tops = [b for b, mats in brushes] + [bx for e, bx in solid_props]
    for e in ents:
        if e.get("classname") != "env_fire":
            continue
        if int(e.get("spawnflags", "0") or 0) & 16:
            continue
        o = origin(e)
        under = [b[5] for b in tops if b[0] <= o[0] <= b[3] and b[1] <= o[1] <= b[4] and b[5] <= o[2] + 2]
        ground = max(under) if under else None
        props_under = [bx for e2, bx in solid_props if bx[0] <= o[0] <= bx[3] and bx[1] <= o[1] <= bx[4] and o[2] - 40 <= bx[5] <= o[2] + 2]
        if props_under:
            say("fire", "env_fire at (%d %d %d) stands on a prop and will drop to the ground: set spawnflag 16 (fire(..., drop=False))" % o)
    # mattress
    for e in ents:
        if "furnituremattress001a" in e.get("model", "").lower() and not e.get("parentname"):
            p, y, r = angles(e)
            if abs(abs(r) - 180) > 20:
                o = origin(e)
                say("mattress", "mattress at (%d %d %d) is not turned over (roll %d): it lies on its back (mattress())" % (o[0], o[1], o[2], r))
    # overlap: two solid props in the same space
    big = [(e, bx) for e, bx in solid_props if min(bx[3] - bx[0], bx[4] - bx[1], bx[5] - bx[2]) >= 6]
    for i in range(len(big)):
        e1, a = big[i]
        for j in range(i + 1, len(big)):
            e2, b = big[j]
            ov = overlap(a, b)
            if not ov:
                continue
            small, large = (a, b) if vol(a) <= vol(b) else (b, a)
            el = e1 if large is a else e2
            es = e2 if large is a else e1
            frac = ov / max(1.0, vol(small))
            if frac < 0.3:
                continue
            if SHELVES.search(el.get("model", "").lower()) and vol(small) < vol(large) * 0.25:
                continue      # (a thing on a shelf, a table, in a cart: its box holds it)
            if "props_foliage/tree" in el.get("model", "").lower():
                ot = origin(el)
                if not overlap(small, (ot[0] - 16, ot[1] - 16, large[2], ot[0] + 16, ot[1] + 16, large[5])):
                    continue      # (under a tree's crown: its box is mostly air, only its trunk is solid)
            m1, m2 = short(es.get("model", "")), short(el.get("model", ""))
            o1, o2 = origin(es), origin(el)
            if m1 == m2 and (frac < 0.6 or (abs(o1[0] - o2[0]) < 2 and abs(o1[1] - o2[1]) < 2)):
                continue      # (a stack or a row of the same thing, or pieces of one pipe or ladder in a line)
            if "ladder" in m1 and "ladder" in m2:
                continue
            o = origin(es)
            say("overlap", "%s at (%d %d %d) is %d%% inside %s: move one" % (m1, o[0], o[1], o[2], 100 * frac, m2))
    # view
    for label, eye, yaw, pitch in views or []:
        for e, bx in solid_props:
            if inside(eye, bx, 1) and not re.search(r"lamppost|pole|container|cargo|trailer|truck", e.get("model", "").lower()):
                say("view", "the view \"%s\" stands inside %s: move it" % (label, short(e.get("model", ""))))
                break
        else:
            for b, mats in brushes:
                if in_brush(eye, b) and not mats <= {"tools/toolsclip", "tools/toolsplayerclip", "tools/toolstrigger", "tools/toolsskybox", "tools/toolsareaportal", "tools/toolsinvisible"}:
                    say("view", "the view \"%s\" stands inside a brush at (%d %d %d): move it" % ((label,) + tuple(int(t) for t in eye)))
                    break
    # water level with a floor
    waters = [b for b, mats in brushes if any("water" in m or "slime" in m for m in mats)]
    floors = [b for b, mats in brushes if not any("water" in m or "slime" in m or m.startswith("tools/") for m in mats)]
    for w in waters:
        for f in floors:
            if abs(w[5] - f[5]) < 1 and w[0] < f[3] - 1 and f[0] < w[3] - 1 and w[1] < f[4] - 1 and f[1] < w[4] - 1:
                say("water", "water from (%d %d) to (%d %d) has its top at z %d, level with a floor: put it 2 or more under" % (w[0], w[1], w[3], w[4], w[5]))
                break
    # rope ends tied to nothing
    near_boxes = [b for b, mats in brushes if not mats <= {"tools/toolsskybox", "tools/toolsclip", "tools/toolsplayerclip", "tools/toolstrigger", "tools/toolsareaportal"}] + [bx for e, bx in solid_props] + \
                 [prop_box(e) for e in ents if e.get("parentname") and prop_box(e)]
    for e in ents:
        if e.get("classname") not in ("move_rope", "keyframe_rope") or e.get("parentname"):
            continue
        o = origin(e)
        if not any(all(b[k] - 20 <= o[k] <= b[k + 3] + 20 for k in range(3)) for b in near_boxes):
            say("rope", "a rope's end at (%d %d %d) is tied to nothing" % o)
    # flush: two faces in one plane, facing one way, overlapping (they flicker)
    if not only or only == "flush":
        HIDDEN = ("tools/", "effects/", "nature/water", "nature/toxicslime", "nature/sewer")
        groups = {}
        for box, (sides, kind) in SIDES.items():
            if kind.startswith(("trigger", "func_areaportal", "func_illusionary", "func_water", "func_door", "func_button", "func_brush", "func_breakable", "func_movelinear", "func_rot", "func_tracktrain")):
                continue      # (moving, unseen or water brushes: not drawn where they stand, or meant to cross)
            for mat, pv in sides:
                if mat.startswith(HIDDEN):
                    continue
                for ax in range(3):
                    vals = [p[ax] for p in pv]
                    if max(vals) - min(vals) > 0.01:
                        continue
                    c = round(vals[0], 1)
                    centre = [(box[k] + box[k + 3]) / 2.0 for k in range(3)]
                    out = 1 if centre[ax] < c else -1
                    o1, o2 = [k for k in range(3) if k != ax]
                    rect = (min(p[o1] for p in pv), min(p[o2] for p in pv), max(p[o1] for p in pv), max(p[o2] for p in pv))
                    if rect[2] - rect[0] < 1 or rect[3] - rect[1] < 1:
                        continue
                    groups.setdefault((ax, c, out), []).append((rect, box, mat))
                    break
        allboxes = list(SIDES.keys())
        seen = 0
        for (ax, c, out), faces in groups.items():
            if len(faces) < 2:
                continue
            faces.sort()
            for i in range(len(faces)):
                ra, ba, ma = faces[i]
                for j in range(i + 1, len(faces)):
                    rb, bb, mb = faces[j]
                    if rb[0] >= ra[2]:
                        break
                    w = min(ra[2], rb[2]) - max(ra[0], rb[0])
                    h = min(ra[3], rb[3]) - max(ra[1], rb[1])
                    if w < 2 or h < 2 or ba == bb:
                        continue
                    o1, o2 = [k for k in range(3) if k != ax]
                    p = [0.0, 0.0, 0.0]
                    p[ax] = c + out * 1.0
                    p[o1] = (max(ra[0], rb[0]) + min(ra[2], rb[2])) / 2.0 + 0.37      # (off the grid: never on a seam between two brushes)
                    p[o2] = (max(ra[1], rb[1]) + min(ra[3], rb[3])) / 2.0 + 0.29
                    if air and air[0] is not None:
                        import bisect
                        cell = tuple(bisect.bisect_right(air[2][k], p[k]) - 1 for k in range(3))
                        if cell not in air[0]:
                            continue      # (it looks into the void outside the map, or into solid: never seen)
                    if any(b2 not in (ba, bb) and in_brush(p, b2, 0.05) for b2 in allboxes if b2[0] - 1 <= p[0] <= b2[3] + 1 and b2[1] - 1 <= p[1] <= b2[4] + 1 and b2[2] - 1 <= p[2] <= b2[5] + 1):
                        continue      # (the face is buried in another brush: not drawn)
                    seen += 1
                    if seen <= 12:
                        say("flush", "%s and %s lie flush in one plane at %s %d, %d by %d from (%d %d %d): they will flicker; move one face in by 1 or more, or cut one away" % (
                            ma, mb, "xyz"[ax], c, w, h, p[0], p[1], p[2]))
        if seen > 12:
            say("flush", "... and %d more flush faces" % (seen - 12))
    # bare: big plain walls with nothing on them
    if not only or only == "bare":
        import bisect
        things = [bx for _, bx in solid_props]
        for e in ents:
            if e.get("classname") in ("infodecal", "info_overlay", "env_sprite") and "origin" in e:
                o = origin(e)
                things.append((o[0] - 8, o[1] - 8, o[2] - 8, o[0] + 8, o[1] + 8, o[2] + 8))
        allb = list(SIDES.keys())
        bare = []
        for box, (sides, kind) in SIDES.items():
            if kind.startswith(("trigger", "func_areaportal", "func_illusionary", "func_water")):
                continue
            for mat, pv in sides:
                if mat.startswith(("tools/", "effects/", "nature/", "skybox")) or "glass" in mat or "fence" in mat:
                    continue
                for ax in (0, 1):
                    vals = [q[ax] for q in pv]
                    if max(vals) - min(vals) > 0.01:
                        continue
                    o = 1 - ax
                    lo, hi = min(q[o] for q in pv), max(q[o] for q in pv)
                    z1, z2 = min(q[2] for q in pv), max(q[2] for q in pv)
                    if hi - lo < 384 or z2 - z1 < 256:
                        break
                    c = vals[0]
                    out = 1 if (box[ax] + box[ax + 3]) / 2.0 < c else -1
                    mid = [0.0, 0.0, 0.0]
                    mid[ax], mid[o], mid[2] = c + out * 2, (lo + hi) / 2.0 + 0.37, (z1 + z2) / 2.0 + 0.29
                    if air and air[0] is not None:
                        cell = tuple(bisect.bisect_right(air[2][k], mid[k]) - 1 for k in range(3))
                        if cell not in air[0]:
                            break      # (it faces the void or solid: never seen)
                    slab = [0.0] * 6
                    slab[ax], slab[ax + 3] = (c, c + 24) if out > 0 else (c - 24, c)
                    slab[o], slab[o + 3], slab[2], slab[5] = lo, hi, z1, z2
                    if any(b2 != box and overlap(slab, b2) for b2 in allb) or any(overlap(slab, t) for t in things):
                        break
                    bare.append(((hi - lo) * (z2 - z1), mat, hi - lo, z2 - z1, mid))
                    break
        bare.sort(key=lambda t: -t[0])
        for area, mat, w, h, mid in bare[:6]:
            say("bare", "a plain wall of %s, %d long and %d tall, facing (%d %d %d) with nothing on it: courses, a pilaster, trim or dressing (map_lessons.py --tag valve)" % (mat, w, h, mid[0], mid[1], mid[2]))
        if len(bare) > 6:
            say("bare", "... and %d more plain walls" % (len(bare) - 6))
    # wire: Valve's five wiring rules
    if not only or only == "wire":
        import map_wiring
        names = set(e.get("targetname", "").lower() for e in ents if e.get("targetname"))
        classes = set(e.get("classname", "").lower() for e in ents)
        played, missing, player = set(), [], 0
        for e in ents:
            who = e.get("targetname") or e.get("classname", "?")
            for out, tgt, inp in e.get("_outputs", []):
                t = tgt.lower()
                if inp.lower() == "playsound":
                    played.add(t)
                if t == "!player":
                    player += 1
                elif t.startswith("!") or not t:
                    continue
                elif t.endswith("*"):
                    if not any(n.startswith(t[:-1]) for n in names):
                        missing.append((who, tgt))
                elif t not in names and t not in classes:
                    missing.append((who, tgt))
        for who, tgt in missing[:6]:
            say("wire", "%s sends to %s, which is not in the map" % (who, tgt))
        if len(missing) > 6:
            say("wire", "... and %d more outputs to things not in the map" % (len(missing) - 6))
        if player:
            say("wire", "%d outputs name !player: on our shared server that is player 1 only; use !activator" % player)
        DRESS = ("playsound", "sparkonce", "startspark", "spawndust", "startshake", "emitblood", "puff")
        doors = []
        for e in ents:
            cls, who = e.get("classname", ""), e.get("targetname") or e.get("classname", "?")
            try:
                flags = int(float(e.get("spawnflags", "0") or 0))
            except ValueError:
                flags = 0
            if cls.startswith("trigger_") and not flags and cls not in ("trigger_autosave", "trigger_changelevel", "trigger_transition", "trigger_soundscape"):
                say("wire", "the %s %s names nobody who touches it: set spawnflags (1 players, 2 NPCs, 8 physics)" % (cls, who))
            elif cls == "ambient_generic":
                msg, looped = e.get("message", ""), map_wiring.is_looped(e.get("message", ""))
                if not msg.lower().endswith((".wav", ".mp3")):
                    continue      # (a sound script name: whether it loops is in the script, not its name)
                if looped and flags & 32:
                    say("wire", "%s loops %s but says 'not looped' (32): StopSound will do nothing" % (who, msg))
                elif not looped and not flags & 32 and e.get("targetname", "").lower() in played:
                    say("wire", "%s plays %s once without 'not looped' (32): a second PlaySound does nothing (48)" % (who, msg))
            elif cls == "logic_timer" and e.get("startdisabled", "0") in ("0", ""):
                ins = [i.lower() for _, _, i in e.get("_outputs", [])]
                if ins and all(i in DRESS for i in ins):
                    say("wire", "the timer %s only dresses the place and runs all day: let it sleep until players are near (map_wiring.sleepy_timer)" % who)
            elif cls == "func_button" and any(w in who.lower() for w in ("valve", "wheel")):
                say("wire", "%s is a valve pressed like a button: make it a wheel that turns (map_wiring.wheel)" % who)
            if cls in ("prop_door_rotating", "func_door", "func_door_rotating", "func_movelinear") :
                if "origin" in e and cls == "prop_door_rotating":
                    o = origin(e)
                    doors.append((o[0] - 4, o[1] - 4, o[2] - 4, o[0] + 4, o[1] + 4, o[2] + 4))
                for bx, _ in e.get("_solids", []):
                    doors.append(bx)
        for e in ents:
            if e.get("classname") == "func_areaportal" and not e.get("target"):
                for bx, _ in e.get("_solids", []):
                    near = (bx[0] - 32, bx[1] - 32, bx[2] - 8, bx[3] + 32, bx[4] + 32, bx[5] + 8)
                    if any(overlap(near, d) > 0 for d in doors):
                        say("wire", "a door hangs in the areaportal at (%d %d %d) and nothing closes it: name the door in its target" % ((bx[0] + bx[3]) / 2, (bx[1] + bx[4]) / 2, bx[2]))
                        break
    # palette: materials City 18 never uses (one line, the commonest few)
    pal = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reference", "city18", "palette.json")
    if os.path.exists(pal) and (not only or only == "palette"):
        import json
        theirs = json.load(open(pal))["materials"]
        counts = {}
        for b, mats in brushes:
            for m in mats:
                if not m.startswith("tools/") and m not in theirs:
                    counts[m] = counts.get(m, 0) + 1
        if counts:
            top = sorted(counts.items(), key=lambda kv: -kv[1])[:6]
            say("palette", "materials City 18 never uses: " + ", ".join("%s (%d)" % kv for kv in top) + ": use one of theirs where it fits (map_lessons.py --find palette)")
    return found


def main():
    ap = argparse.ArgumentParser(description="The owner's corrections, checked by machine.")
    ap.add_argument("vmf", nargs="+")
    ap.add_argument("--only")
    a = ap.parse_args()
    total = 0
    for path in a.vmf:
        found = check(path, only=a.only)
        total += len(found)
        print("%s: %d to look at" % (os.path.basename(path), len(found)))
        for f in found:
            print("  " + f)
    sys.exit(0)


if __name__ == "__main__":
    main()
