"""Room to walk (the owner, 22 November, after walking the canal ring: "MAKE A CHECK TO CHECK FOR PLAYER ROOM TO WALK":
a table on a gallery with no way past, a shack with no room before its door, stairs into walls).

Reads a VMF and lays every floor a player could stand on on a grid of 16: the top of every box brush of the world or of
a func_detail or func_brush, where a player's body (32 across, 72 high, or 36 crouched) fits over it among the brushes
and the solid props (each prop's real size, from map_assets, turned with it). Then it walks from the largest stretch of
floor the way a player can: a step of 18, a jump of 44, any drop, along ladders (func_useableladder) and on lifts (a
func_door platform that rides up or down: its foot's floor and the floor where it stops are joined). What it reports:

  - every place the map says people go that a player cannot reach: path nodes (info_node), the game's named spots
    (info_target named lc_...), both sides of every door that opens (prop_door_rotating), the front of every button;
  - every solid prop that cuts a walk in two: with the prop gone the floor round it is one, with it there it is two.

    python3 map_walk.py FILE.vmf [...]

map_build.py runs it on every piece it writes (a PROBLEM fails the build).
"""

import math
import re
import sys
from collections import deque

import map_stairs

CELL = 16
BODY, HIGH, CROUCH, STEP, JUMP = 16, 72, 36, 18, 44     # (half a body across; standing; crouched; a step; a jump)
SOLID_PROPS = ("prop_static", "prop_dynamic", "prop_dynamic_override", "prop_physics", "prop_physics_override", "prop_physics_multiplayer")


def ents_of(text):
    for m in re.finditer(r'\nentity\n\{\n(.*?)\n\}(?=\n)', text, re.S):
        e = m.group(1)
        head = e.split("\n\tsolid\n")[0].split("\n\tconnections\n")[0].split("\n\teditor\n")[0]
        kv = dict(re.findall(r'^\t"([^"]+)" "([^"]*)"$', head, re.M))
        yield kv, e


def num3(s):
    try:
        v = [float(c) for c in s.split()]
        return v if len(v) == 3 else None
    except (ValueError, AttributeError):
        return None


def prop_boxes(text):
    """The solid props as boxes: (box, model, origin)."""
    import map_assets
    out = []
    for kv, _ in ents_of(text):
        cls = kv.get("classname", "")
        if cls not in SOLID_PROPS or kv.get("solid", "6") == "0":
            continue
        if cls.startswith("prop_physics") and int(kv.get("spawnflags", "0") or 0) & 4:
            continue      # (debris: players walk through it)
        o, a, model = num3(kv.get("origin", "")), num3(kv.get("angles", "0 0 0")) or [0, 0, 0], kv.get("model", "")
        bb = map_assets.size(model.lower()) if model else None
        if not o or not bb:
            continue
        if abs(a[0]) > 30 or abs(a[2]) > 30:
            continue      # (laid down or tipped: its box turned is not worth guessing)
        yaw = math.radians(a[1])
        cs, sn = math.cos(yaw), math.sin(yaw)
        xs, ys = [], []
        for x in (bb[0], bb[3]):
            for y in (bb[1], bb[4]):
                xs.append(o[0] + x * cs - y * sn)
                ys.append(o[1] + x * sn + y * cs)
        box = (min(xs), min(ys), o[2] + bb[2], max(xs), max(ys), o[2] + bb[5])
        if box[5] - box[2] < 12 or (box[3] - box[0] < 12 and box[4] - box[1] < 12):
            continue      # (small things are stepped over or pushed aside)
        out.append((box, model, o))
    return out


class Floors:
    def __init__(self, boxes, props, mud=(), slopes=()):
        self.boxes = boxes
        self.props = [p[0] for p in props]
        self.solid = boxes + self.props
        self.grid = map_stairs.Grid(self.solid, 128)
        self.cells = {}     # (i, j) -> sorted list of (floor z, headroom kind 'stand' or 'crouch')
        for b in list(boxes) + [(m[0], m[1], m[2], m[3], m[4], m[5] - 3) for m in mud]:
            if b[3] - b[0] < 8 or b[4] - b[1] < 8:
                continue      # (too thin to stand on: a rail, a bar)
            z = b[5]
            for i in range(int(math.floor(b[0] / CELL)), int(math.ceil(b[3] / CELL))):
                for j in range(int(math.floor(b[1] / CELL)), int(math.ceil(b[4] / CELL))):
                    cx, cy = (i + 0.5) * CELL, (j + 0.5) * CELL
                    if not (b[0] <= cx <= b[3] and b[1] <= cy <= b[4]):
                        continue
                    self.cells.setdefault((i, j), set()).add(z)
        for c, z in slopes:
            self.cells.setdefault(c, set()).add(z)
        self.room = {}
        for c, zs in self.cells.items():
            ok = []
            for z in sorted(zs):
                k = self.fits(c, z)
                if k:
                    ok.append((z, k))
            if ok:
                self.room[c] = ok

    def fits(self, c, z, skip=None):
        """Does a body stand ('stand') or crouch ('crouch') on floor z at cell c? None if not."""
        cx, cy = (c[0] + 0.5) * CELL, (c[1] + 0.5) * CELL
        r = (cx - BODY, cy - BODY, z, cx + BODY, cy + BODY, z + HIGH)
        low = HIGH
        for i in self.grid.near(r):
            b = self.solid[i]
            if skip is not None and b == skip:
                continue
            if b[5] <= z + STEP or b[2] >= z + HIGH:
                continue
            if b[0] < r[3] - 0.5 and b[3] > r[0] + 0.5 and b[1] < r[4] - 0.5 and b[4] > r[1] + 0.5:
                if b[2] <= z + 1:
                    return None      # (something standing here, taller than a step)
                low = min(low, b[2] - z)
        return "stand" if low >= HIGH else "crouch" if low >= CROUCH else None

    def moves(self, c, z):
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                if di or dj:
                    n = (c[0] + di, c[1] + dj)
                    for z2, _ in self.room.get(n, ()):
                        if z2 - z <= JUMP and z - z2 <= 2048:
                            yield n, z2


def walk(fl, starts, ladders):
    seen = set(starts)
    todo = deque(starts)
    lad = {}
    for a, b in ladders:
        lad.setdefault(a, []).append(b)
        lad.setdefault(b, []).append(a)
    while todo:
        c, z = todo.popleft()
        for n in list(fl.moves(c, z)) + lad.get((c, z), []):
            if n not in seen:
                seen.add(n)
                todo.append(n)
    return seen


def biggest(fl, ladders):
    """The biggest stretch a player can walk round from any one place (all it can reach from there). Every place is
    walked once: a walk stops where an earlier one went and notes which, and what a place reaches is its own walk and
    every earlier one it ran into, so a high place that drops into the whole map (a roof, a sky's top: the canal ring's
    backdrop has many) does not walk the whole map again. Exact, whatever order the places come in."""
    lad = {}
    for a, b in ladders:
        lad.setdefault(a, []).append(b)
        lad.setdefault(b, []).append(a)
    part_of, parts, into = {}, [], []
    for s in sorted(((c, z) for c, zs in fl.room.items() for z, _ in zs), key=lambda st: (-st[1], st[0])):
        if s in part_of:
            continue
        k = len(parts)
        own, hit, todo = {s}, set(), deque([s])
        part_of[s] = k
        while todo:
            c, z = todo.popleft()
            for n in list(fl.moves(c, z)) + lad.get((c, z), []):
                j = part_of.get(n)
                if j is None:
                    part_of[n] = k
                    own.add(n)
                    todo.append(n)
                elif j != k:
                    hit.add(j)
        parts.append(own)
        into.append(hit)
    best, size = (), -1
    for k in range(len(parts)):
        reach, stack = {k}, [k]
        while stack:
            for j in into[stack.pop()]:
                if j not in reach:
                    reach.add(j)
                    stack.append(j)
        n = sum(len(parts[i]) for i in reach)
        if n > size:
            best, size = reach, n
    return set().union(*(parts[i] for i in best))


def nearest(fl, p, reach=40, up=24, down=96):
    """The floor states (cell, z) a point stands over: within `reach` across, its floor between `down` under and `up` over."""
    out = []
    i0, j0 = int(math.floor(p[0] / CELL)), int(math.floor(p[1] / CELL))
    r = int(math.ceil(reach / CELL))
    for i in range(i0 - r, i0 + r + 1):
        for j in range(j0 - r, j0 + r + 1):
            for z, _ in fl.room.get((i, j), ()):
                if p[2] - down <= z <= p[2] + up:
                    out.append(((i, j), z))
    return out


def mud_tops(text):
    """The mud's displaced skins (world brushes with a dispinfo): floor to walk on, never a wall (the canal's floor
    under the mud is lower where it is dished: without these the walk could not climb out of the dish)."""
    out = []
    w0 = text.find("\nworld\n")
    w1 = text.find("\nentity\n", w0)
    for m in map_stairs.SOLID.finditer(text[w0:w1 if w1 > 0 else len(text)]):
        body = m.group(3)
        if "dispinfo" not in body:
            continue
        pts = [tuple(float(c) for c in g.split()) for pm in map_stairs.PLANE.finditer(body) for g in pm.groups()]
        if pts:
            out.append(tuple(min(p[k] for p in pts) for k in range(3)) + tuple(max(p[k] for p in pts) for k in range(3)))
    return out


def slope_floors(text):
    """Floors on brushes that are not boxes (the canal's banks, ramps, slabs): for each 16 square under one, the height of
    its top there, if that top is no steeper than a player can walk (45 degrees). [(cell, z)]."""
    def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
    def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    out = []
    chunks = []
    w0 = text.find("\nworld\n")
    w1 = text.find("\nentity\n", w0)
    chunks.append(text[w0:w1 if w1 > 0 else len(text)])
    for kv, e in ents_of(text):
        if kv.get("classname") in map_stairs.BLOCKING_ENTITIES:
            chunks.append("\n" + e)
    for chunk in chunks:
        for m in map_stairs.SOLID.finditer(chunk):
            body = m.group(3)
            if "dispinfo" in body:
                continue
            mats = [x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]
            if any(any(w in x for w in map_stairs.NOT_SOLID) for x in mats):
                continue
            planes, pts = [], []
            for pm in map_stairs.PLANE.finditer(body):
                a, b, c = [tuple(float(x) for x in g.split()) for g in pm.groups()]
                pts += [a, b, c]
                n = cross(sub(c, a), sub(b, a))
                ln = (n[0] ** 2 + n[1] ** 2 + n[2] ** 2) ** 0.5
                if ln < 1e-9:
                    break
                n = (n[0] / ln, n[1] / ln, n[2] / ln)
                planes.append((n, n[0] * a[0] + n[1] * a[1] + n[2] * a[2]))
            ups = [(n, d) for n, d in planes if n[2] > 0.05]
            if not ups or all(abs(n[2]) > 0.999 or abs(n[2]) < 0.001 for n, d in planes):
                continue      # (a box: its top is counted already)
            if not any(0.05 < n[2] < 0.999 for n, d in ups):
                continue
            vs = [tuple(float(c) for c in v.split()) for v in re.findall(r'"v" "([-\d.e ]+)"', body)] or pts
            x1, y1, x2, y2 = min(v[0] for v in vs), min(v[1] for v in vs), max(v[0] for v in vs), max(v[1] for v in vs)
            for i in range(int(math.floor(x1 / CELL)), int(math.ceil(x2 / CELL))):
                for j in range(int(math.floor(y1 / CELL)), int(math.ceil(y2 / CELL))):
                    cx, cy = (i + 0.5) * CELL, (j + 0.5) * CELL
                    if any(n[0] * cx + n[1] * cy + n[2] * 0 > d + 1e6 for n, d in planes):
                        continue
                    best = None
                    for n, d in ups:
                        z = (d - n[0] * cx - n[1] * cy) / n[2]
                        if best is None or z < best[0]:
                            best = (z, n)
                    if best is None or best[1][2] < 0.70:
                        continue
                    z = best[0]
                    # inside the solid's outline at that height? every side plane must hold the point
                    if all(n[0] * cx + n[1] * cy + n[2] * (z - 0.5) <= d + 0.5 for n, d in planes):
                        out.append(((i, j), round(z, 1)))
    return out


NOT_SOLID = ("tools/toolstrigger", "tools/toolshint", "tools/toolsskip", "tools/toolsareaportal", "tools/toolsskybox",
             "tools/toolsfog", "tools/toolsblocklight", "tools/toolsoccluder", "tools/toolsinvisibleladder", "tools/toolsblack")


def ladder_feet(text, ents):
    """A ladder whose ends a player cannot stand at: the game says "funcladder with blocked bottom point ... stuck in"
    (the owner's log, 25 November: a canal bank buried two ladders' feet). A player's box (32 across, 72 tall) at each
    end must be clear of every brush. Gives [((x, y, z), message)]."""
    import map_propkit
    ends = []
    for kv, _ in ents:
        if kv.get("classname") == "func_useableladder":
            for key in ("point0", "point1"):
                p = num3(kv.get(key, ""))
                if p:
                    ends.append((key, p))
    if not ends:
        return []
    solids = []
    for faces, cls in map_propkit.read_solids(text, ("worldspawn", "func_detail", "func_brush")):
        if all(m in NOT_SOLID for _, m in faces):
            continue
        solids.append(map_propkit.Solid(faces))
    out = []
    for key, p in ends:
        pts = [(p[0] + dx, p[1] + dy, p[2] + dz) for dx in (-16, 0, 16) for dy in (-16, 0, 16) for dz in (0, 36, 72)]      # (touching counts: Source calls a box that touches a brush stuck)
        for sd in solids:
            if sd.lo[0] > p[0] + 16 or sd.hi[0] < p[0] - 16 or sd.lo[1] > p[1] + 16 or sd.hi[1] < p[1] - 16 or sd.lo[2] > p[2] + 72 or sd.hi[2] < p[2]:
                continue
            if any(sd.inside(q, -0.05) for q in pts):
                out.append((p, "a ladder's %s at (%d %d %d) is inside a brush: no room for a player there" % (
                    "foot" if key == "point0" else "top", p[0], p[1], p[2])))
                break
    return out


def check_text(text, limit=12, where=None, start=None, also=()):
    boxes = map_stairs.boxes_of(text)
    props = prop_boxes(text)
    fl = Floors(boxes, props, mud_tops(text), slope_floors(text))
    if not fl.room:
        return []
    ents = list(ents_of(text))
    ladders = []
    for kv, _ in ents:
        if kv.get("classname") == "func_useableladder":
            p0, p1 = num3(kv.get("point0", "")), num3(kv.get("point1", ""))
            if p0 and p1:
                lo, hi = (p0, p1) if p0[2] < p1[2] else (p1, p0)
                a = nearest(fl, lo, reach=48, up=40, down=64)
                b = nearest(fl, (hi[0], hi[1], hi[2] + 24), reach=64, up=64, down=96)
                for x in a[:4]:
                    for y in b[:6]:
                        ladders.append((x, y))
    problems_ladders = ladder_feet(text, ents)
    # lifts: a func_door that rides up or down (a flat platform moving at least 64, more than twice its own height) joins
    # the floor round its foot to the floor round where it stops, as a ladder does (the freight lift's dock)
    for kv, e in ents:
        if kv.get("classname") != "func_door" or "\tsolid\n" not in e:
            continue
        md = num3(kv.get("movedir", ""))
        if not md or abs(abs(md[0]) - 90) > 1:
            continue
        pts = [tuple(float(c) for c in g.split()) for pm in map_stairs.PLANE.finditer(e) for g in pm.groups()]
        if not pts:
            continue
        x1, y1, z1 = (min(p[k] for p in pts) for k in range(3))
        x2, y2, z2 = (max(p[k] for p in pts) for k in range(3))
        try:
            travel = (z2 - z1) - float(kv.get("lip", "0") or 0)
        except ValueError:
            continue
        if travel < 64 or z2 - z1 > travel / 2 or x2 - x1 < 64 or y2 - y1 < 64:
            continue
        lo = z1 if md[0] < 0 else z1 - travel          # (movedir -90: up from where it is drawn; 90: down)
        mid, reach = ((x1 + x2) / 2, (y1 + y2) / 2), max(x2 - x1, y2 - y1) / 2 + 48
        a = nearest(fl, (mid[0], mid[1], lo + 8), reach=reach, up=24, down=32)
        b = nearest(fl, (mid[0], mid[1], lo + travel + 8), reach=reach, up=24, down=32)
        for x in a[:8]:
            for y in b[:8]:
                ladders.append((x, y))
    # where people go
    targets = []
    for kv, _ in ents:
        cls, name = kv.get("classname", ""), kv.get("targetname", "")
        o = num3(kv.get("origin", ""))
        if not o:
            continue
        if cls == "info_player_start" and not start:
            start = o
        elif cls == "info_target" and name.startswith("lc_"):
            targets.append(("the game's spot %s" % name, (o[0], o[1], o[2]), "spot"))
        elif cls == "prop_door_rotating":
            yaw = math.radians((num3(kv.get("angles", "0 0 0")) or [0, 0, 0])[1])
            ax, ay = math.cos(yaw), math.sin(yaw)          # (the leaf runs to its left: its middle is 24 along that)
            mx, my = o[0] - ay * 24, o[1] + ax * 24
            for s in (1, -1):
                targets.append(("a side of the door%s" % (" " + name if name else ""), (mx + s * ax * 40, my + s * ay * 40, o[2] - 55), "door"))
        elif cls == "prop_dynamic" and "button" in kv.get("model", "").lower():
            yaw = math.radians((num3(kv.get("angles", "0 0 0")) or [0, 0, 0])[1])
            targets.append(("the front of the button %s" % (name or kv.get("model")), (o[0] + math.cos(yaw) * 36, o[1] + math.sin(yaw) * 36, o[2] - 30), "button"))
    # the start: the spawn or one given; else the biggest stretch of floor a player can walk round
    starts = nearest(fl, start, reach=48, down=128) if start else []
    for p in also:      # (more places to walk from: the far side of ground this walk cannot read, as a forest's displaced ground)
        starts = starts + nearest(fl, p, reach=48, down=128) if starts else starts
    if starts:
        seen = walk(fl, starts, ladders)
    else:
        seen = biggest(fl, ladders)
    movers = []      # (lifts, platforms, doors that slide: a spot beside one is reached by riding it, which this walk cannot)
    for kv, e in ents:
        if kv.get("classname") in ("func_door", "func_movelinear", "func_tracktrain", "func_train") and "\tsolid\n" in e:
            pts = [tuple(float(c) for c in g.split()) for pm in map_stairs.PLANE.finditer(e) for g in pm.groups()]
            if pts:
                movers.append((min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)))
    problems = ["walk: " + ((where(p[0], p[1]) + ": ") if where else "") + msg for p, msg in problems_ladders][:limit]
    for label, p, kind in targets:
        if any(r[0] - 160 <= p[0] <= r[2] + 160 and r[1] - 160 <= p[1] <= r[3] + 160 for r in movers):
            continue
        at = nearest(fl, p, up=8 if kind == "spot" else 24, down=24 if kind == "spot" else 96)
        if not at:
            if kind == "spot":
                continue      # (a spot not standing on a floor: a light's aim, a thing on a table)
            msg = "%s at (%d %d %d) has no floor a player fits on before it" % (label, p[0], p[1], p[2])
        elif not any(s in seen for s in at):
            msg = "%s at (%d %d %d) cannot be walked to (no way in a player fits through)" % (label, p[0], p[1], p[2])
        else:
            continue
        problems.append("walk: " + ((where(p[0], p[1]) + ": ") if where else "") + msg)
        if len(problems) >= limit:
            return problems
    # props that cut a walk in two
    for box, model, o in props:
        z = box[2]
        c0 = (int(math.floor(o[0] / CELL)), int(math.floor(o[1] / CELL)))
        win = 12
        local = {}
        for i in range(c0[0] - win, c0[0] + win + 1):
            for j in range(c0[1] - win, c0[1] + win + 1):
                for fz, _ in fl.room.get((i, j), ()):
                    if abs(fz - z) <= 4:
                        local[(i, j)] = fz
        if len(local) < 20:
            continue
        free = {}
        for c, fz in local.items():
            if fl.fits(c, fz, skip=box):
                free[c] = fz

        def parts(cells):
            left, n = set(cells), 0
            sizes = []
            while left:
                q = [left.pop()]
                size = 1
                while q:
                    a = q.pop()
                    for di in (-1, 0, 1):
                        for dj in (-1, 0, 1):
                            b = (a[0] + di, a[1] + dj)
                            if b in left:
                                left.discard(b)
                                q.append(b)
                                size += 1
                sizes.append(size)
            return [s for s in sizes if s >= 6]
        with_it = [c for c in free if c in fl.room and any(abs(z2 - free[c]) <= 4 for z2, _ in fl.room[c])]
        a, b = len(parts(free)), len(parts(with_it))
        if b > a:
            problems.append("walk: " + ((where(o[0], o[1]) + ": ") if where else "") + "%s at (%d %d %d) cuts a walk in two: no room for a player past it" % (
                model.rsplit("/", 1)[-1], o[0], o[1], o[2]))
            if len(problems) >= limit:
                break
    return problems


def main():
    """map_walk.py FILE.vmf ... [--also X Y Z]...: each --also is one more place the walk starts from (beside the spawn):
    for a part of the map that can only be reached over ground this walk cannot read (a forest's ground is displaced:
    the walk knows flat and sloped brushes), or from the inside (a door that only opens from within)."""
    bad = 0
    args, also = sys.argv[1:], []
    while "--also" in args:
        i = args.index("--also")
        also.append(tuple(float(v) for v in args[i + 1:i + 4]))
        del args[i:i + 4]
    for path in args:
        text = open(path, errors="replace").read()
        found = check_text(text, limit=300, also=also)
        print("%s: %d problems" % (path, len(found)))
        for p in found:
            print("  " + p)
        bad += len(found)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
