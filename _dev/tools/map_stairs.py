"""Stairs that go somewhere (the owner, 22 November, after walking the canal ring: "WE NEED A CHECK to see if stairs go
into walls or geometry, over half the stairs just go into walls so far").

Finds every flight of stairs in a VMF from its shape alone, whatever helper made it: box brushes (world or detail), each
a tread 4 to 48 deep, one after another along x or y, each 4 to 24 higher than the last (filled steps and steel treads
with gaps alike). For each flight of 3 or more it checks, with a player's size (32 wide, 72 high, a step of 18):

  - headroom over every tread: nothing solid in the 72 over it (a wall, a ceiling, a beam the flight runs into);
  - the top: room to step off beyond the last tread, and a floor there within a step of its height;
  - the foot: room to step on before the first tread, and a floor there within a step of the flight's bottom.

Solid is every box brush of the world or of a func_detail (not water, clips, triggers, areaportals, doors or other
moving brushes: a door at a stair's head opens). Brushes that are not boxes (a stringer, a slope) are not counted as
blockers, so a flight against one is not judged.

    python3 map_stairs.py FILE.vmf [...]        every flight that fails, with where it is

map_build.py runs it on every piece it writes (a PROBLEM fails the build) and map_merge.py on the merged map.
"""

import re
import sys

PLANE = re.compile(r'"plane" "\(([-\d.e ]+)\) \(([-\d.e ]+)\) \(([-\d.e ]+)\)"')
SOLID = re.compile(r'\n(\t*)solid\n\1\{\n\1\t"id" "(\d+)"(.*?)\n\1\}', re.S)
NOT_SOLID = ("water", "slime", "tools/toolstrigger", "tools/toolsareaportal", "tools/toolshint", "tools/toolsskip",
             "tools/toolsoccluder", "tools/toolsinvisible", "tools/toolsblocklight", "tools/toolsfog")
BLOCKING_ENTITIES = ("func_detail", "func_brush", "func_wall", "func_illusionary_never")   # (func_brush: our walls of bars and fixed slabs)
PLAYER_W, PLAYER_H, STEP, ROOM = 32, 72, 18, 32


def boxes_of(text):
    """(box, is a tread candidate) for every axis-aligned box brush that blocks a player: from the world and from the
    blocking brush entities. A box: every plane's three points share one coordinate along some axis."""
    out = []

    def take(chunk):
        for m in SOLID.finditer(chunk):
            body = m.group(3)
            if "dispinfo" in body:
                continue
            mats = [x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]
            if any(any(w in x for w in NOT_SOLID) for x in mats):
                continue
            pts, axisy = [], True
            for pm in PLANE.finditer(body):
                tri = [tuple(float(c) for c in g.split()) for g in pm.groups()]
                pts += tri
                if not any(len(set(round(p[k], 2) for p in tri)) == 1 for k in range(3)):
                    axisy = False
            if not pts or not axisy:
                continue
            box = tuple(min(p[k] for p in pts) for k in range(3)) + tuple(max(p[k] for p in pts) for k in range(3))
            if all(box[k + 3] - box[k] > 0.5 for k in range(3)):
                out.append(box)
    w0 = text.find("\nworld\n")
    if w0 >= 0:
        w1 = text.find("\nentity\n", w0)
        take(text[w0:w1 if w1 > 0 else len(text)])
    for m in re.finditer(r'\nentity\n\{\n(.*?)\n\}(?=\n)', text, re.S):
        e = m.group(1)
        cls = re.search(r'"classname" "([^"]+)"', e)
        named = re.search(r'^\t"targetname" "[^"]+"$', e.split("\n\tsolid\n")[0], re.M)
        if cls and cls.group(1) in BLOCKING_ENTITIES and "\tsolid\n" in e and not (named and cls.group(1) != "func_detail"):
            take("\n" + e)      # (a named func_brush is one the game switches off: a force field, bars that lift)
    return out


def mud_boxes(text):
    """The mud's displaced skins (world brushes with a dispinfo): floor to stand on at a stair's foot, never a blocker."""
    out = []
    w0 = text.find("\nworld\n")
    if w0 < 0:
        return out
    w1 = text.find("\nentity\n", w0)
    for m in SOLID.finditer(text[w0:w1 if w1 > 0 else len(text)]):
        body = m.group(3)
        if "dispinfo" not in body:
            continue
        pts = [tuple(float(c) for c in g.split()) for pm in PLANE.finditer(body) for g in pm.groups()]
        if pts:
            out.append(tuple(min(p[k] for p in pts) for k in range(3)) + tuple(max(p[k] for p in pts) for k in range(3)))
    return out


class Grid:
    def __init__(self, boxes, cell=256):
        self.cell, self.cells = cell, {}
        for i, b in enumerate(boxes):
            for gx in range(int(b[0] // cell), int(b[3] // cell) + 1):
                for gy in range(int(b[1] // cell), int(b[4] // cell) + 1):
                    self.cells.setdefault((gx, gy), []).append(i)

    def near(self, r):
        out = set()
        for gx in range(int(r[0] // self.cell), int(r[3] // self.cell) + 1):
            for gy in range(int(r[1] // self.cell), int(r[4] // self.cell) + 1):
                out.update(self.cells.get((gx, gy), ()))
        return out


def overlap(a, b, k):
    return min(a[k + 3], b[k + 3]) - max(a[k], b[k])


def flights(boxes):
    """Chains of treads: (axis 0 for x or 1 for y, sign +1 or -1 the way it climbs, [indices of the treads in order])."""
    cand = [i for i, b in enumerate(boxes)
            if 4 <= min(b[3] - b[0], b[4] - b[1]) <= 48 and max(b[3] - b[0], b[4] - b[1]) >= 24]
    grid = Grid([boxes[i] for i in cand], 128)
    nxt = {}
    for n, i in enumerate(cand):
        t = boxes[i]
        run = 0 if t[3] - t[0] <= t[4] - t[1] else 1
        cross = 1 - run
        best = None
        for mi in grid.near((t[0] - 64, t[1] - 64, 0, t[3] + 64, t[4] + 64, 0)):
            j = cand[mi]
            if j == i:
                continue
            u = boxes[j]
            rise = u[5] - t[5]
            if not 4 <= rise <= 24:
                continue
            if abs((u[3 + cross] - u[cross]) - (t[3 + cross] - t[cross])) > 8 or overlap(t, u, cross) < 0.8 * min(t[3 + cross] - t[cross], u[3 + cross] - u[cross]):
                continue
            for s in (1, -1):
                gap = (u[run] - t[run + 3]) if s > 0 else (t[run] - u[run + 3])
                if -1 <= gap <= 16 and 4 <= u[run + 3] - u[run] <= 48:
                    key = (abs(gap), abs(rise - 12))
                    if best is None or key < best[0]:
                        best = (key, j, run, s)
        if best:
            nxt[i] = best[1:]
    has_prev = {v[0] for v in nxt.values()}
    out = []
    for i in nxt:
        if i in has_prev:
            continue
        chain, run, s = [i], nxt[i][1], nxt[i][2]
        while chain[-1] in nxt and nxt[chain[-1]][1] == run and nxt[chain[-1]][2] == s and len(chain) < 400:
            chain.append(nxt[chain[-1]][0])
        if len(chain) >= 3:
            out.append((run, s, chain))
    return out


def check_text(text, limit=12, where=None):
    """Problems (strings) for the flights in a VMF's text. where(x, y): a name for a place (the module it is in)."""
    boxes = boxes_of(text)
    grid = Grid(boxes)
    muds = mud_boxes(text)
    mud_grid = Grid(muds)
    problems = []

    def hits(region, skip, floor):
        """A brush in the region a player could not step onto (its top more than a step over `floor`)."""
        r = region
        for i in grid.near(r):
            if i in skip:
                continue
            b = boxes[i]
            if b[5] <= floor + STEP:
                continue      # (a floor, a landing, the next step: stepped onto, not into)
            if all(b[k] < r[k + 3] - 4 and b[k + 3] > r[k] + 4 for k in range(2)) and b[2] < r[5] - 0.5 and b[5] > r[2] + 0.5:
                return b      # (in by 4 or more across: a fence's edge 3 into the space is stepped round)
        return None

    def floor_at(region, z, skip):
        """Is there a floor under this region within a step of z?"""
        r = (region[0], region[1], z - STEP - 2, region[3], region[4], z + STEP)
        for i in grid.near(r):
            if i in skip:
                continue
            b = boxes[i]
            if z - STEP - 2 <= b[5] <= z + STEP and overlap(b, r, 0) >= 8 and overlap(b, r, 1) >= 8:
                return True
        for i in mud_grid.near(r):      # (the canal's mud: its skin rises and dips over a dished floor, so a wide band)
            b = muds[i]
            if z - STEP - 48 <= b[5] <= z + STEP + 48 and overlap(b, r, 0) >= 8 and overlap(b, r, 1) >= 8:
                return True
        return False

    for run, s, chain in flights(boxes):
        tr = [boxes[i] for i in chain]
        cross = 1 - run
        lo = max(b[cross] for b in tr)
        hi = min(b[cross + 3] for b in tr)
        if hi - lo < 16:
            continue
        mid = (lo + hi) / 2.0
        half = min(PLAYER_W, hi - lo - 4) / 2.0
        c1, c2 = mid - half, mid + half
        skip = set(chain)
        rise = (tr[-1][5] - tr[0][5]) / max(1, len(tr) - 1)

        def region(r1, r2, z1, z2):
            a, b = min(r1, r2), max(r1, r2)
            return (a, c1, z1, b, c2, z2) if run == 0 else (c1, a, z1, c2, b, z2)
        label = "a flight of %d steps (%d up) climbing %s%s at (%d %d %d)" % (
            len(tr), tr[-1][5] - tr[0][5] + rise, "+-"[s < 0], "xy"[run], tr[0][0], tr[0][1], tr[0][5])
        if where:
            label = where(tr[0][0], tr[0][1]) + ": " + label
        bad = None
        for t in tr:      # headroom over each tread
            b = hits(region(t[run] + 1, t[run + 3] - 1, t[5] + 2, t[5] + PLAYER_H), skip, t[5])
            if b:
                bad = "it runs into something solid over its step at height %d (a brush at x %d..%d y %d..%d z %d..%d)" % ((t[5],) + tuple(int(v) for v in (b[0], b[3], b[1], b[4], b[2], b[5])))
                break
        def side(tread, z, ahead):
            """The ways off a tread at height z: straight on (ahead), or to either side of it (a flight that turns onto a
            landing); (brush in the way or None, floor there) for the first that is clear, else the straight one's."""
            ways = []
            t0, t1 = tread[run], tread[run + 3]
            edge = t1 if ahead > 0 else t0
            ways.append(region(edge, edge + ahead * ROOM, z + 2, z + PLAYER_H))
            for c, sgn in ((lo, -1), (hi, 1)):      # (to either side of the tread, as deep as a body)
                a, b2 = sorted((c, c + sgn * ROOM))
                ways.append((t0, a, z + 2, t1, b2, z + PLAYER_H) if run == 0 else (a, t0, z + 2, b2, t1, z + PLAYER_H))
            first = None
            for w in ways:
                blk = hits(w, skip, z)
                fl = floor_at(w, z, skip)
                if first is None:
                    first = (blk, fl)
                if not blk and fl:
                    return None, True
            return first
        if not bad:
            top = tr[-1][5]
            b, fl = side(tr[-1], top, s)
            if b:
                bad = "there is no room to step off at its top (height %d), ahead or to either side: a brush at x %d..%d y %d..%d z %d..%d" % ((top,) + tuple(int(v) for v in (b[0], b[3], b[1], b[4], b[2], b[5])))
            elif not fl:
                bad = "it ends in the air at its top (height %d): no floor ahead or to either side" % top
        if not bad:
            base = tr[0][5] - rise
            b, fl = side(tr[0], base, -s)
            if b:
                bad = "there is no room to step on at its foot (height %d), before it or to either side: a brush at x %d..%d y %d..%d z %d..%d" % ((int(base),) + tuple(int(v) for v in (b[0], b[3], b[1], b[4], b[2], b[5])))
            elif not fl:
                bad = "its foot is in the air (height %d): no floor before it or to either side" % base
        if bad:
            problems.append("stairs: %s: %s" % (label, bad))
            if len(problems) >= limit:
                break
    return problems


def main():
    bad = 0
    for path in sys.argv[1:]:
        text = open(path, errors="replace").read()
        found = check_text(text, limit=200)
        n = len(flights(boxes_of(text)))
        print("%s: %d flights, %d fail" % (path, n, len(found)))
        for p in found:
            print("  " + p)
        bad += len(found)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
