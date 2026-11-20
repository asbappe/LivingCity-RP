#!/usr/bin/env python3
"""
Living City: the owner's corrections, checked by machine (_dev/reference/lessons.json, the lessons whose "check" names
map_lint).

    python3 map_lint.py FILE.vmf [more.vmf ...]      every finding, one line each
    python3 map_lint.py FILE.vmf --only overlap       one kind (overlap, door, offlamp, fire, mattress, view, water, rope)

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


def nums(text):
    return [float(t) for t in text.replace("(", " ").replace(")", " ").replace("[", " ").replace("]", " ").split()]


def read(path):
    """(entities: [{key: value, '_solids': [box...]}], brushes: [(box, materials)]) from a VMF, quickly."""
    text = open(path, errors="replace").read()
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
        boxes = []
        for sm in re.finditer(r"^\tsolid\s*\n\t\{(.*?)^\t\}", body, re.M | re.S):
            vs = [nums(v) for v in re.findall(r'"v" "([^"]+)"', sm.group(1))]
            mats = set(x.lower() for x in re.findall(r'"material" "([^"]+)"', sm.group(1)))
            if vs:
                box = tuple(min(v[k] for v in vs) for k in range(3)) + tuple(max(v[k] for v in vs) for k in range(3))
                planes = [nums(pl) for pl in re.findall(r'"plane" "([^"]+)"', sm.group(1))]
                boxes.append((box, mats))
                SHAPES[box] = planes
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


def check(path, views=None, only=None):
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
