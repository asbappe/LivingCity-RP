#!/usr/bin/env python3
"""
Living City: the map survey (for the owner's PC, never the server)

The owner, 14 and 19 November: read the map's VMF "to help map out NPC hotspots, player
hotspots, and what could/should be redesigned", and help find "holes and cracks between
geometry". The VMF is 27 MB, far too big to read in a chat, so this reads it on the owner's
PC and writes a small folder the code chat can read:

    python3 map_survey.py MAP.vmf
    python3 map_survey.py MAP.vmf --study ~/.steam/.../data/livingcity/study/FOLDER
    python3 map_survey.py MAP.vmf --study FOLDER1 --study FOLDER2 --out my_survey

It writes, in map_survey/ (or --out) next to where it is run:
    survey.txt       what the map is made of, and what looks wrong (see below)
    map_all.png      the whole map from above
    map_level_N.png  one picture for each height people walk at (a floor plan)
    (with --study: the play study laid over each picture, and a section in survey.txt)

It needs only Python 3. Pictures are PNG when Pillow is installed (python3-pil, there on
Linux Mint), SVG otherwise. It only reads the VMF: nothing is changed.

What "looks wrong" means here, and what it does not: these are CANDIDATES from the brushes'
shapes (corners off the grid, slivers, brushes a hair apart, things outside the world). A real
leak is found by compiling: the compiler's pointfile is the proof. This narrows where to look.
"""

import argparse
import math
import os
import re
import sys
import time
from collections import Counter, defaultdict

PLAYER_TALL, CROUCH_TALL, STEP = 72, 36, 18
KV = re.compile(r'"([^"]*)"\s+"([^"]*)"')
BIG_ROWS = {"normals", "distances", "offsets", "offset_normals", "alphas", "triangle_tags", "allowed_verts"}

# tool textures: what a brush is for (the first match wins)
TOOLS = (("toolsskybox", "sky"), ("toolstrigger", "trigger"), ("toolsplayerclip", "playerclip"), ("toolsnpcclip", "npcclip"),
         ("toolsclip", "clip"), ("toolsinvisible", "invisible"), ("toolshint", "hint"), ("toolsskip", "hint"),
         ("toolsareaportal", "areaportal"), ("toolsoccluder", "occluder"), ("toolsblocklight", "blocklight"),
         ("toolsfog", "fog"), ("toolsnodraw", "nodraw"), ("toolsblack", "black"))
NOT_SOLID = {"sky", "trigger", "hint", "areaportal", "occluder", "fog", "blocklight"}
NOT_DRAWN = NOT_SOLID | {"playerclip", "npcclip", "clip", "invisible"}


# ---------------------------------------------------------------------------
# Reading the VMF
# ---------------------------------------------------------------------------

class Block:
    __slots__ = ("name", "kv", "kids")

    def __init__(self, name):
        self.name, self.kv, self.kids = name, {}, []


def read_vmf(path):
    """The VMF as a tree of blocks. The big rows of numbers inside displacements are skipped."""
    root = Block("root")
    stack, pending, skip = [root], None, 0
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            c = s[0]
            if c == '"':
                if skip:
                    continue
                m = KV.match(s)
                if m:
                    kv = stack[-1].kv
                    k = m.group(1)
                    # (an entity may have the same key twice, its outputs: keep them all)
                    if k in kv:
                        old = kv[k]
                        if isinstance(old, list):
                            old.append(m.group(2))
                        else:
                            kv[k] = [old, m.group(2)]
                    else:
                        kv[k] = m.group(2)
            elif c == "{":
                b = Block(pending or "?")
                if skip or b.name in BIG_ROWS:
                    skip += 1
                else:
                    stack[-1].kids.append(b)
                stack.append(b)
                pending = None
            elif c == "}":
                if skip:
                    skip -= 1
                if len(stack) > 1:
                    stack.pop()
            elif not s.startswith("//"):
                pending = s
    return root


def one(v):
    return v[0] if isinstance(v, list) else v


def vec(text):
    try:
        p = [float(x) for x in str(text).replace("(", " ").replace(")", " ").replace("[", " ").replace("]", " ").split()]
        return (p[0], p[1], p[2]) if len(p) >= 3 else None
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Brushes
# ---------------------------------------------------------------------------

def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


class Brush:
    __slots__ = ("id", "verts", "mins", "maxs", "kind", "mats", "owner", "disp", "sides", "boxy", "offgrid", "hull")


def corners(planes):
    """Where three of a brush's faces meet, kept when inside all the others."""
    n = len(planes)
    out = []
    for i in range(n - 2):
        n1, d1 = planes[i]
        for j in range(i + 1, n - 1):
            n2, d2 = planes[j]
            c12 = cross(n1, n2)
            if abs(c12[0]) + abs(c12[1]) + abs(c12[2]) < 1e-9:
                continue
            for k in range(j + 1, n):
                n3, d3 = planes[k]
                det = dot(c12, n3)
                if abs(det) < 1e-9:
                    continue
                c23, c31 = cross(n2, n3), cross(n3, n1)
                p = ((d1 * c23[0] + d2 * c31[0] + d3 * c12[0]) / det,
                     (d1 * c23[1] + d2 * c31[1] + d3 * c12[1]) / det,
                     (d1 * c23[2] + d2 * c31[2] + d3 * c12[2]) / det)
                for nn, dd in planes:
                    if dot(nn, p) - dd > 0.05:
                        break
                else:
                    out.append(p)
    return out


def make_brush(solid, owner):
    b = Brush()
    b.id = one(solid.kv.get("id", "?"))
    b.owner, b.disp, b.mats = owner, False, Counter()
    pts, tris = [], []
    plus = []
    for side in solid.kids:
        if side.name != "side":
            continue
        mat = str(one(side.kv.get("material", ""))).lower()
        b.mats[mat] += 1
        nums = re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", str(one(side.kv.get("plane", ""))))
        if len(nums) >= 9:
            t = [(float(nums[i]), float(nums[i + 1]), float(nums[i + 2])) for i in (0, 3, 6)]
            tris.append(t)
            pts.extend(t)
        for kid in side.kids:
            if kid.name == "dispinfo":
                b.disp = True
            elif kid.name == "vertices_plus":
                v = kid.kv.get("v")
                for item in (v if isinstance(v, list) else [v] if v else []):
                    p = vec(item)
                    if p:
                        plus.append(p)
    b.sides = len(tris)
    if len(pts) < 9:
        return None
    # each face's plane, turned to face away from the brush's middle
    mid = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts), sum(p[2] for p in pts) / len(pts))
    planes, boxy = [], True
    for t in tris:
        n = cross(sub(t[1], t[0]), sub(t[2], t[0]))
        ln = math.sqrt(dot(n, n))
        if ln < 1e-9:
            continue
        n = (n[0] / ln, n[1] / ln, n[2] / ln)
        d = dot(n, t[0])
        if dot(n, mid) - d > 0:
            n, d = (-n[0], -n[1], -n[2]), -d
        if max(abs(n[0]), abs(n[1]), abs(n[2])) < 0.9999:
            boxy = False
        planes.append((n, d))
    b.boxy = boxy and len(planes) == 6
    if plus:
        verts = plus
    elif b.boxy or len(planes) > 14:
        verts = pts # (a plain box, or a many-sided thing: the corners Hammer wrote are enough)
    else:
        verts = corners(planes) or pts
    b.verts = verts
    b.mins = (min(p[0] for p in verts), min(p[1] for p in verts), min(p[2] for p in verts))
    b.maxs = (max(p[0] for p in verts), max(p[1] for p in verts), max(p[2] for p in verts))
    b.offgrid = sum(1 for p in pts if abs(p[0] - round(p[0])) > 0.01 or abs(p[1] - round(p[1])) > 0.01 or abs(p[2] - round(p[2])) > 0.01)
    kinds = Counter()
    for mat, n in b.mats.items():
        for word, kind in TOOLS:
            if word in mat:
                kinds[kind] += n
                break
        else:
            kinds["wall"] += n
    b.kind = "wall" if kinds["wall"] else kinds.most_common(1)[0][0]
    b.hull = None
    return b


def hull2d(points):
    """The outline of some points seen from above."""
    pts = sorted(set((round(p[0], 1), round(p[1], 1)) for p in points))
    if len(pts) < 3:
        return pts

    def turn(o, a, c): return (a[0] - o[0]) * (c[1] - o[1]) - (a[1] - o[1]) * (c[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and turn(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and turn(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


class Grid:
    """Brushes by the 256-unit squares they touch, to find what's near a spot quickly."""

    def __init__(self, cell=256):
        self.cell, self.cells = cell, defaultdict(list)

    def add(self, b, pad=0):
        c = self.cell
        for gx in range(int((b.mins[0] - pad) // c), int((b.maxs[0] + pad) // c) + 1):
            for gy in range(int((b.mins[1] - pad) // c), int((b.maxs[1] + pad) // c) + 1):
                self.cells[(gx, gy)].append(b)

    def near(self, x, y, r):
        c, seen, out = self.cell, set(), []
        for gx in range(int((x - r) // c), int((x + r) // c) + 1):
            for gy in range(int((y - r) // c), int((y + r) // c) + 1):
                for b in self.cells.get((gx, gy), ()):
                    if id(b) not in seen and b.mins[0] <= x + r and b.maxs[0] >= x - r and b.mins[1] <= y + r and b.maxs[1] >= y - r:
                        seen.add(id(b))
                        out.append(b)
        return out


# ---------------------------------------------------------------------------
# The play study's log (sv_livingcity_study.lua): where the player was, jumped and crouched
# ---------------------------------------------------------------------------

LOG = re.compile(r"^\[\s*(-?[\d.]+)\]\s+(\S+)\s+(.*)$")
XYZ = re.compile(r"(-?\d+) (-?\d+) (-?\d+)")


def read_study(path):
    if os.path.isdir(path):
        path = os.path.join(path, "log.txt")
    trail, jumps, lows, paused, who = [], [], [], False, "?"
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = LOG.match(line.rstrip("\n"))
            if not m:
                continue
            kind, text = m.group(2), m.group(3)
            if kind == "pause":
                paused = not text.startswith("playing again")
            elif kind == "who":
                who = text.split(" (was")[0]
            elif paused:
                continue
            elif kind == "at":
                p = XYZ.search(text)
                if p:
                    trail.append((int(p.group(1)), int(p.group(2)), int(p.group(3)), who))
            elif kind == "event" and (text.startswith("jumped") or text.startswith("crouched")):
                p = XYZ.search(text)
                if p:
                    (jumps if text.startswith("jumped") else lows).append((int(p.group(1)), int(p.group(2)), int(p.group(3)), who))
    return trail, jumps, lows


def why_here(grid, x, y, z):
    """What the map has at a spot that would make someone jump or crouch there (z: their feet)."""
    step, low = None, None
    for b in grid.near(x, y, 56):
        if b.kind in NOT_SOLID or b.kind == "npcclip":
            continue
        top, bottom = b.maxs[2], b.mins[2]
        if z + STEP < top <= z + 80 and bottom < top - 1:
            h = top - z
            if step is None or h < step:
                step = h
        if z + CROUCH_TALL - 4 <= bottom < z + PLAYER_TALL and b.mins[0] <= x + 24 and b.maxs[0] >= x - 24 and b.mins[1] <= y + 24 and b.maxs[1] >= y - 24:
            h = bottom - z
            if low is None or h < low:
                low = h
    return step, low


# ---------------------------------------------------------------------------
# Pictures
# ---------------------------------------------------------------------------

class Picture:
    """A picture from above: PNG with Pillow, SVG without."""

    def __init__(self, mins, maxs, size=2400):
        w, h = max(1.0, maxs[0] - mins[0]), max(1.0, maxs[1] - mins[1])
        self.scale = size / max(w, h)
        self.mins, self.maxs = mins, maxs
        self.w, self.h = int(w * self.scale) + 40, int(h * self.scale) + 60
        try:
            from PIL import Image, ImageDraw
            self.img = Image.new("RGB", (self.w, self.h), (14, 14, 16))
            self.draw = ImageDraw.Draw(self.img, "RGBA")
            self.svg = None
        except ImportError:
            self.img = None
            self.svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" style="background:#0e0e10">' % (self.w, self.h)]

    def xy(self, x, y):
        return (20 + (x - self.mins[0]) * self.scale, 20 + (self.maxs[1] - y) * self.scale) # (north up)

    def poly(self, pts, fill, outline=None):
        p = [self.xy(x, y) for x, y in pts]
        if len(p) < 3:
            return
        if self.img:
            self.draw.polygon(p, fill=fill, outline=outline)
        else:
            self.svg.append('<polygon points="%s" fill="rgba(%d,%d,%d,%.2f)"%s/>' % (
                " ".join("%.1f,%.1f" % q for q in p), fill[0], fill[1], fill[2], (fill[3] if len(fill) > 3 else 255) / 255,
                (' stroke="rgb(%d,%d,%d)"' % outline[:3]) if outline else ""))

    def dot(self, x, y, r, fill):
        cx, cy = self.xy(x, y)
        if self.img:
            self.draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)
        else:
            self.svg.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="rgba(%d,%d,%d,%.2f)"/>' % (cx, cy, r, fill[0], fill[1], fill[2], (fill[3] if len(fill) > 3 else 255) / 255))

    def square(self, x, y, size, fill):
        self.poly([(x, y), (x + size, y), (x + size, y + size), (x, y + size)], fill)

    def text(self, px, py, s, fill=(230, 230, 230)):
        if self.img:
            self.draw.text((px, py), s, fill=fill)
        else:
            self.svg.append('<text x="%d" y="%d" fill="rgb(%d,%d,%d)" font-size="12" font-family="monospace">%s</text>' % (
                px, py + 10, fill[0], fill[1], fill[2], s.replace("&", "&amp;").replace("<", "&lt;")))

    def label(self, x, y, s, fill=(230, 230, 230)):
        cx, cy = self.xy(x, y)
        self.text(int(cx) + 4, int(cy) - 6, s, fill)

    def frame(self, title):
        # a grid line every 1024 units, with its map coordinate, so a spot in the picture can be named
        gx = math.ceil(self.mins[0] / 1024) * 1024
        while gx <= self.maxs[0]:
            a, b = self.xy(gx, self.mins[1]), self.xy(gx, self.maxs[1])
            self.poly([(gx, self.mins[1]), (gx + 2 / self.scale, self.mins[1]), (gx + 2 / self.scale, self.maxs[1]), (gx, self.maxs[1])], (255, 255, 255, 26))
            self.text(int(a[0]) + 2, self.h - 34, "x %d" % gx, (130, 130, 130))
            gx += 1024
        gy = math.ceil(self.mins[1] / 1024) * 1024
        while gy <= self.maxs[1]:
            self.poly([(self.mins[0], gy), (self.maxs[0], gy), (self.maxs[0], gy + 2 / self.scale), (self.mins[0], gy + 2 / self.scale)], (255, 255, 255, 26))
            self.text(2, int(self.xy(self.mins[0], gy)[1]) - 12, "y %d" % gy, (130, 130, 130))
            gy += 1024
        self.text(20, self.h - 18, title)

    def save(self, path):
        if self.img:
            self.img.save(path + ".png")
            return path + ".png"
        with open(path + ".svg", "w") as f:
            f.write("\n".join(self.svg) + "\n</svg>\n")
        return path + ".svg"


ENT_COLOURS = (("info_node", (90, 200, 255, 150), 2), ("info_player", (80, 255, 120, 255), 5), ("npc_", (255, 120, 80, 255), 4),
               ("prop_door", (255, 220, 90, 255), 3), ("func_door", (255, 220, 90, 255), 3), ("light", (255, 255, 200, 70), 2),
               ("trigger_", (255, 90, 255, 200), 3), ("path_", (170, 255, 170, 160), 2))


def paint(pic, brushes, ents, band=None):
    """Brushes from above, low ones first. band: (feet, head) draws one level as a floor plan."""
    drawn = []
    for b in brushes:
        if b.kind in NOT_DRAWN:
            continue
        if band:
            lo, hi = band
            floor = lo - 48 <= b.maxs[2] <= lo + STEP
            wall = b.mins[2] < lo + PLAYER_TALL and b.maxs[2] > lo + STEP and not floor
            if not (floor or wall):
                continue
            drawn.append((1 if wall else 0, b.maxs[2], b, wall))
        else:
            drawn.append((0, b.maxs[2], b, False))
    drawn.sort(key=lambda t: (t[0], t[1]))
    zs = [t[1] for t in drawn] or [0]
    zlo, zhi = min(zs), max(zs)
    for _, top, b, wall in drawn:
        if b.hull is None:
            b.hull = hull2d(b.verts)
        if wall:
            pic.poly(b.hull, (150, 150, 160, 255))
        else:
            t = (top - zlo) / max(1.0, zhi - zlo)
            g = int(46 + 80 * t)
            pic.poly(b.hull, (g, g + (10 if b.disp else 0), g - (8 if b.disp else 0), 255), (g + 18, g + 18, g + 18, 255))
    for cls, pos in ents:
        if band and not (band[0] - 64 <= pos[2] <= band[1] + 64):
            continue
        for word, colour, r in ENT_COLOURS:
            if cls.startswith(word):
                pic.dot(pos[0], pos[1], r, colour)
                break


def dead_floor(brushes, nodes, band, cell=128, reach=512):
    """Squares of floor on a level with no ground path node within reach: where the city's people can't walk to."""
    lo = band[0]
    floor, wall = set(), set()
    for b in brushes:
        if b.kind in NOT_DRAWN:
            continue
        is_floor = lo - 48 <= b.maxs[2] <= lo + STEP
        is_wall = not is_floor and b.mins[2] < lo + PLAYER_TALL and b.maxs[2] > lo + STEP
        if not (is_floor or is_wall):
            continue
        target = floor if is_floor else wall
        # (the squares whose middle the brush covers, by its box)
        for gx in range(int(math.ceil((b.mins[0] - cell / 2) / cell)), int(math.floor((b.maxs[0] - cell / 2) / cell)) + 1):
            for gy in range(int(math.ceil((b.mins[1] - cell / 2) / cell)), int(math.floor((b.maxs[1] - cell / 2) / cell)) + 1):
                target.add((gx, gy))
    walk = floor - wall
    near = set()
    r = int(reach // cell)
    for n in nodes:
        if lo - 96 <= n[2] <= band[1] + 64:
            cx, cy = int(n[0] // cell), int(n[1] // cell)
            for dx in range(-r, r + 1):
                for dy in range(-r, r + 1):
                    if dx * dx + dy * dy <= r * r:
                        near.add((cx + dx, cy + dy))
    return walk, walk - near


def paint_study(pic, trail, jumps, lows, band=None):
    def inside(p):
        return not band or band[0] - 40 <= p[2] <= band[1]
    cells = Counter()
    for p in trail:
        if inside(p):
            cells[(p[0] // 128, p[1] // 128)] += 1
    top = max(cells.values()) if cells else 1
    for (cx, cy), n in cells.items():
        a = int(70 + 150 * math.sqrt(n / top))
        pic.square(cx * 128, cy * 128, 128, (255, 120, 30, a))
    for p in jumps:
        if inside(p):
            pic.dot(p[0], p[1], 5, (80, 220, 255, 255))
    for p in lows:
        if inside(p):
            pic.dot(p[0], p[1], 5, (255, 80, 220, 255))


# ---------------------------------------------------------------------------
# The survey
# ---------------------------------------------------------------------------

def levels(ents, trail):
    """The heights people walk at: from the study's trail when there is one, else from where things stand."""
    zs = [p[2] for p in trail] if len(trail) >= 20 else [pos[2] for cls, pos in ents if cls.startswith(("info_player", "info_node", "npc_", "prop_door", "path_"))]
    if not zs:
        return []
    bands = Counter(int(z // 96) * 96 for z in zs)
    picked = []
    for z, n in bands.most_common():
        if n < max(3, len(zs) * 0.03):
            break
        if all(abs(z - q) >= 160 for q in picked):
            picked.append(z)
        if len(picked) >= 6:
            break
    return sorted(picked)


def survey(args):
    t0 = time.time()
    out = []

    def P(s=""):
        out.append(s)

    def say(s):
        print(s, flush=True)

    say("Reading %s ..." % args.vmf)
    root = read_vmf(args.vmf)
    brushes, ents, classes, models, bad = [], [], Counter(), Counter(), []
    world_n, ent_brush_n = 0, Counter()
    names = {}
    for top in root.kids:
        if top.name == "world":
            for kid in top.kids:
                if kid.name == "solid":
                    b = make_brush(kid, "world")
                    if b:
                        brushes.append(b)
                        world_n += 1
                    else:
                        bad.append(one(kid.kv.get("id", "?")))
        elif top.name == "entity":
            cls = str(one(top.kv.get("classname", "?")))
            classes[cls] += 1
            pos = vec(one(top.kv.get("origin", "")))
            solids = [k for k in top.kids if k.name == "solid"]
            for kid in solids:
                b = make_brush(kid, cls)
                if b:
                    brushes.append(b)
                    ent_brush_n[cls] += 1
                    if cls.startswith("trigger") or cls in ("func_areaportal", "func_occluder", "func_viscluster", "func_illusionary", "func_precipitation", "func_dustmotes", "func_smokevolume", "env_embers"):
                        b.kind = "trigger" if b.kind == "wall" else b.kind
            if pos and not solids:
                ents.append((cls, pos))
                if cls.startswith("prop_"):
                    models[str(one(top.kv.get("model", "?"))).lower()] += 1
            name = one(top.kv.get("targetname", ""))
            if name and pos:
                names[str(name)] = (cls, pos)
    say("  %d brushes, %d entities (%.0fs)" % (len(brushes), sum(classes.values()), time.time() - t0))
    if not brushes:
        sys.exit("No brushes found: is this a VMF?")

    solid = [b for b in brushes if b.kind not in NOT_SOLID]
    hard = [b for b in brushes if b.owner == "world" and b.kind not in NOT_SOLID]
    mins = tuple(min(b.mins[i] for b in solid) for i in range(3))
    maxs = tuple(max(b.maxs[i] for b in solid) for i in range(3))
    grid = Grid()
    for b in solid:
        grid.add(b)

    P("LIVING CITY: A MAP SURVEY")
    P("%s (%.1f MB), read %s" % (os.path.basename(args.vmf), os.path.getsize(args.vmf) / 1e6, time.strftime("%d %B %Y, %H:%M")))
    P("")
    P("How to read this (for the code chat): map coordinates are x y z in units (a person is 72 tall, 36 crouched, steps up 18")
    P("without jumping). The pictures are from above, north up, with a grid line every 1024 units. Everything under WHAT LOOKS")
    P("WRONG is a candidate found from the brushes' shapes, to be looked at in Hammer: only a compile proves a leak.")
    P("")
    P("== WHAT THE MAP IS MADE OF ==")
    P("  The world, from (%d %d %d) to (%d %d %d): %d x %d x %d units." % (mins + maxs + tuple(int(maxs[i] - mins[i]) for i in range(3))))
    P("  Brushes: %d in the world, %d in brush entities; %d with displacements." % (world_n, sum(ent_brush_n.values()), sum(1 for b in brushes if b.disp)))
    kinds = Counter(b.kind for b in brushes)
    P("  By what they're for: " + ", ".join("%s %d" % kv for kv in kinds.most_common()))
    P("  Brush entities: " + ", ".join("%s %d" % kv for kv in ent_brush_n.most_common(14)))
    P("  Point entities, most first: " + ", ".join("%s %d" % kv for kv in Counter(c for c, _ in ents).most_common(30)))
    P("  Models placed, most first: " + ", ".join("%s x%d" % (m.replace("models/", ""), n) for m, n in models.most_common(20)))
    nodes = [pos for cls, pos in ents if cls in ("info_node", "info_node_climb")] # (ground nodes: what people walk on)
    P("  For the city's people: %d ground path nodes (info_node), %d air nodes, %d hints, %d npc clips, %d player clips, %d spawn points." % (
        len(nodes), classes["info_node_air"], sum(n for c, n in classes.items() if c.startswith("info_node_hint") or c == "info_hint"), kinds["npcclip"], kinds["playerclip"],
        sum(n for c, n in classes.items() if c.startswith("info_player"))))

    P("")
    P("== WHAT LOOKS WRONG (candidates) ==")
    if bad:
        P("  Brushes that couldn't be read (fewer than three faces with a plane): ids " + ", ".join(bad[:40]))
    off = sorted((b for b in hard if b.offgrid), key=lambda b: -b.offgrid)
    P("  World brushes with corners off the 1-unit grid: %d of %d (off-grid corners are where hairline cracks come from)." % (len(off), len(hard)))
    for b in off[:25]:
        P("    id %s at (%d %d %d), %d corners off" % (b.id, (b.mins[0] + b.maxs[0]) / 2, (b.mins[1] + b.maxs[1]) / 2, (b.mins[2] + b.maxs[2]) / 2, b.offgrid))
    thin = [b for b in hard if min(b.maxs[i] - b.mins[i] for i in range(3)) < 1.0]
    P("  World brushes thinner than 1 unit (slivers): %d" % len(thin))
    for b in thin[:15]:
        P("    id %s at (%d %d %d), %.2f thick" % (b.id, (b.mins[0] + b.maxs[0]) / 2, (b.mins[1] + b.maxs[1]) / 2, (b.mins[2] + b.maxs[2]) / 2, min(b.maxs[i] - b.mins[i] for i in range(3))))
    # box-shaped world brushes a hair apart: a gap under 2 units between faces that overlap
    gaps = []
    boxes = [b for b in hard if b.boxy and not b.disp]
    bgrid = Grid(512)
    for b in boxes:
        bgrid.add(b, 2) # (so two brushes either side of a square's edge still meet)
    seen = set()
    for cell in bgrid.cells.values():
        for i, a in enumerate(cell):
            for b in cell[i + 1:]:
                key = (id(a), id(b)) if id(a) < id(b) else (id(b), id(a))
                if key in seen:
                    continue
                seen.add(key)
                for ax in range(3):
                    g = max(a.mins[ax] - b.maxs[ax], b.mins[ax] - a.maxs[ax])
                    if 0.02 < g < 2.0:
                        o1, o2 = [i for i in range(3) if i != ax]
                        w1 = min(a.maxs[o1], b.maxs[o1]) - max(a.mins[o1], b.mins[o1])
                        w2 = min(a.maxs[o2], b.maxs[o2]) - max(a.mins[o2], b.mins[o2])
                        if w1 > 8 and w2 > 8:
                            mid = [(max(a.mins[i], b.mins[i]) + min(a.maxs[i], b.maxs[i])) / 2 for i in range(3)]
                            mid[ax] = (min(a.maxs[ax], b.maxs[ax]) + max(a.mins[ax], b.mins[ax])) / 2
                            gaps.append((w1 * w2, g, "xyz"[ax], mid, a.id, b.id))
    gaps.sort(key=lambda t: -t[0])
    P("  Box brushes a hair apart (a gap under 2 units between faces that overlap): %d. The widest faces first:" % len(gaps))
    for area, g, ax, mid, ia, ib in gaps[:40]:
        P("    gap %.2f along %s at (%d %d %d), ids %s and %s, %d sq units of face" % (g, ax, mid[0], mid[1], mid[2], ia, ib, area))
    # (the sky's own brushes count as the world here: the 3D skybox's camera sits inside them)
    amin = tuple(min(b.mins[i] for b in brushes) for i in range(3))
    amax = tuple(max(b.maxs[i] for b in brushes) for i in range(3))
    outside = [(c, p) for c, p in ents if any(p[i] < amin[i] - 1 or p[i] > amax[i] + 1 for i in range(3))]
    P("  Point entities outside the world's bounds (a classic leak): %d" % len(outside))
    for c, p in outside[:30]:
        P("    %s at (%d %d %d)" % (c, p[0], p[1], p[2]))

    # the play study, laid over the map
    trail, jumps, lows = [], [], []
    for s in args.study or []:
        t, j, l = read_study(s)
        trail += t
        jumps += j
        lows += l
    if args.study:
        P("")
        P("== THE PLAY STUDY ON THE MAP (%d places on the trail, %d jumps, %d crouches) ==" % (len(trail), len(jumps), len(lows)))
        for title, spots, key in (("Jumps", jumps, 0), ("Crouches", lows, 1)):
            by = defaultdict(list)
            for p in spots:
                by[(p[0] // 96, p[1] // 96, p[2] // 96)].append(p)
            P("  %s, by spot (most first). \"the map\": something there to get over or under; \"a habit\": nothing found within 56 units." % title)
            verdicts = Counter()
            rows = []
            for cell, ps in sorted(by.items(), key=lambda kv: -len(kv[1])):
                x, y, z = (sum(p[i] for p in ps) / len(ps) for i in range(3))
                step, low = why_here(grid, x, y, z)
                if key == 0:
                    why = ("the map: a %d-unit rise" % step) if step else "a habit (nothing to get over)"
                else:
                    why = ("the map: %d units of headroom" % low) if low else "a habit (room to stand)"
                verdicts[why.split(":")[0].split(" (")[0]] += len(ps)
                rows.append("    (%d %d %d) x%d, as %s: %s" % (x, y, z, len(ps), ps[0][3], why))
            P("    in all: " + (", ".join("%s %d" % kv for kv in verdicts.most_common()) or "none"))
            for r in rows[:40]:
                P(r)
        # where the player goes that the city's people can't, and the other way round
        if nodes and trail:
            ngrid = defaultdict(list)
            for n in nodes:
                ngrid[(int(n[0] // 512), int(n[1] // 512))].append(n)

            def node_near(p, r=400):
                for gx in range(int((p[0] - r) // 512), int((p[0] + r) // 512) + 1):
                    for gy in range(int((p[1] - r) // 512), int((p[1] + r) // 512) + 1):
                        for n in ngrid.get((gx, gy), ()):
                            if abs(n[2] - p[2]) < 160 and (n[0] - p[0]) ** 2 + (n[1] - p[1]) ** 2 < r * r:
                                return True
                return False
            lonely = Counter()
            for p in trail:
                if not node_near(p):
                    lonely[(p[0] // 256 * 256 + 128, p[1] // 256 * 256 + 128, p[2] // 128 * 128 + 64)] += 1
            P("  Where the player spends time with no path node within 400 units (the city's people may not be able to follow): %d squares" % len(lonely))
            for c, n in lonely.most_common(25):
                P("    (%d %d %d) x%d" % (c + (n,)))
            tgrid = set((p[0] // 512, p[1] // 512) for p in trail)
            unseen = Counter()
            for n in nodes:
                if not any((int(n[0] // 512) + dx, int(n[1] // 512) + dy) in tgrid for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                    unseen[(int(n[0] // 1024) * 1024 + 512, int(n[1] // 1024) * 1024 + 512)] += 1
            P("  Where there are path nodes the player never went near (1024-unit squares, most nodes first): %d squares" % len(unseen))
            for c, n in unseen.most_common(25):
                P("    (%d %d) %d nodes" % (c + (n,)))
        elif not nodes:
            P("  The VMF has no path nodes (info_node...): nothing to compare the trail with.")

    # pictures
    os.makedirs(args.out, exist_ok=True)
    say("Drawing ...")
    P("")
    P("== THE PICTURES ==")
    P("  Grey: brushes from above, lighter is higher (greenish: displacements). Light grey blocks on a level: walls. Dots: blue path nodes,")
    P("  green spawn points, yellow doors, red NPCs, purple triggers, pale lights. Red squares on a level: floor with no ground path node")
    P("  within 512 units (the city's people can't walk there; a roof at that height shows red too).")
    if args.study:
        P("  Orange squares: where the study's player was (brighter: longer). Cyan dots: jumps. Pink dots: crouches.")
    lo2, hi2 = (mins[0], mins[1]), (maxs[0], maxs[1])
    pic = Picture(lo2, hi2, args.size)
    paint(pic, sorted(brushes, key=lambda b: b.maxs[2]), ents)
    if args.study:
        paint_study(pic, trail, jumps, lows)
    pic.frame("%s: the whole map from above" % os.path.basename(args.vmf))
    P("  " + os.path.basename(pic.save(os.path.join(args.out, "map_all"))) + ": the whole map")
    for i, z in enumerate(levels(ents, trail), 1):
        band = (z, z + 96)
        pic = Picture(lo2, hi2, args.size)
        paint(pic, brushes, ents, band)
        walk, dead = dead_floor(brushes, nodes, band)
        for cx, cy in dead:
            pic.square(cx * 128, cy * 128, 128, (220, 40, 40, 90))
        if args.study:
            paint_study(pic, trail, jumps, lows, band)
        pic.frame("%s: level %d, feet at z %d to %d" % (os.path.basename(args.vmf), i, z, z + 96))
        here = sum(1 for n in nodes if z - 96 <= n[2] <= z + 160)
        P("  %s: level %d, feet at z %d to %d: %d ground nodes; about %d of %d floor squares (128 units) have no node within 512 units (red)" % (
            os.path.basename(pic.save(os.path.join(args.out, "map_level_%d" % i))), i, z, z + 96, here, len(dead), len(walk)))

    with open(os.path.join(args.out, "survey.txt"), "w") as f:
        f.write("\n".join(out) + "\n")
    say("Done in %.0fs: %s/ (survey.txt and the pictures). Zip the folder and give it to the code chat." % (time.time() - t0, args.out))


def main():
    ap = argparse.ArgumentParser(description="Survey a Source map's VMF for the Living City code chat (reads only; changes nothing).")
    ap.add_argument("vmf", help="the map's .vmf file")
    ap.add_argument("--study", action="append", help="a play study's folder (or its log.txt) to lay over the map; may be given more than once")
    ap.add_argument("--out", default="map_survey", help="the folder to write (default: map_survey)")
    ap.add_argument("--size", type=int, default=2400, help="the pictures' longest side in pixels (default 2400)")
    survey(ap.parse_args())


if __name__ == "__main__":
    main()
