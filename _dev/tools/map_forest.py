#!/usr/bin/env python3
"""
Living City: forest pieces for the map builder (run them through map_build.py)

The owner, 19 November: "two forest sections/areas using Episode 2 assets (EP1 and HL2 base is
fine too), one has an old abandoned nuclear/bomb/air-raid bunker, and the other has a natural
cave like in EP2. One should have a nice little pond or small lake with a small island on it,
and the other should have a small stream", each its own file, "separate from the canals ... but
can be stitched together".

    python3 map_build.py forest_bunker --preview bunker.png    the bunker, and the pond with its island
    python3 map_build.py forest_cave --preview cave.png        the cave, and the stream that runs out of it

A forest is a valley 4096 units square inside a ridge, under its own sky. Its ground is displaced
terrain (64 patches of 512, a corner every 64 units) made from one height function, so every
patch meets its neighbours. Under and round it is a sealed shell (a slab, four sky walls, a sky
lid); the ground itself seals nothing. Each has one gate: the same culvert the canal's far ends
have (512 wide, 256 high), with a concrete headwall, closed by a cap until something is joined.

Every model and material was checked to exist (and each prop_static model to be compiled as a
static prop) against lists of Half-Life 2's, Episode One's and Episode Two's files. What nobody
has checked is how any of it LOOKS: this was made without seeing it. docs/dev/map-building.md.
"""

import math
import random

from map_build import CELL, GATE_HIGH, GATE_WIDE, MAT, Plan, Vmf, check, gate_cap

PATCH, STEP, WALL = 512, 64, 128

FMAT = {
    "ground": "nature/blendgrassdirt01",          # ep2: forest grass, blending to forest dirt
    "cave": "nature/blendrockdirt_tunnel02a",     # ep2: cave rock, blending to dirt
    "pond": "nature/water_canals_water_clear",    # hl2
    "stream": "nature/water_riverbed02",          # ep2: the Episode Two river water
    "bunker_wall": "concrete/concretewall008a",   # these three are in the owner's own map
    "bunker_floor": "concrete/concretefloor031a",
    "bunker_ceiling": "concrete/concreteceiling004a",
}

PINES = (("models/props_foliage/tree_pine04.mdl", 3), ("models/props_foliage/tree_pine05.mdl", 3), ("models/props_foliage/tree_pine06.mdl", 3),
         ("models/props_foliage/tree_pine_large.mdl", 1), ("models/props_foliage/tree_dead01.mdl", 0.4), ("models/props_foliage/tree_dead03.mdl", 0.4))
LEAFY = (("models/props_foliage/tree_deciduous_01a.mdl", 2), ("models/props_foliage/tree_deciduous_02a.mdl", 2), ("models/props_foliage/tree_deciduous_03a.mdl", 2))
PLANTS = ("models/props_foliage/ferns01.mdl", "models/props_foliage/ferns02.mdl", "models/props_foliage/ferns03.mdl", "models/props_foliage/fern01.mdl",
          "models/props_foliage/bush2.mdl", "models/props_foliage/shrub_small.mdl")
ROCKS = ("models/props_foliage/forestrock_cluster01.mdl", "models/props_foliage/forestrock_cluster02.mdl", "models/props_foliage/forestrock_single01.mdl",
         "models/props_wasteland/rockgranite02a.mdl", "models/props_wasteland/rockgranite03a.mdl")
LOGS = ("models/props_foliage/fallentree01.mdl", "models/props_foliage/fallentree02.mdl", "models/props_foliage/tree_stump01.mdl", "models/props_forest/log.mdl")


# ---------------------------------------------------------------------------
# Small things
# ---------------------------------------------------------------------------

def smooth(t):
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return t * t * (3 - 2 * t)


def lerp(a, b, w):
    return a + (b - a) * w


def _lattice(ix, iy, seed):
    h = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 32767.5 - 1.0


def noise(x, y, seed=0):
    """Smooth noise, -1 to 1, the same every run."""
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = x - ix, y - iy
    sx, sy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = _lattice(ix, iy, seed), _lattice(ix + 1, iy, seed)
    c, d = _lattice(ix, iy + 1, seed), _lattice(ix + 1, iy + 1, seed)
    return lerp(lerp(a, b, sx), lerp(c, d, sx), sy)


def rect_dist(x, y, r):
    """How far a point is outside a rectangle (0 inside)."""
    dx = max(r[0] - x, 0, x - r[2])
    dy = max(r[1] - y, 0, y - r[3])
    return math.hypot(dx, dy)


def path_dist(x, y, pts):
    """How far a point is from a line through pts."""
    best = 1e18
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        vx, vy = bx - ax, by - ay
        ln = vx * vx + vy * vy
        t = 0 if ln == 0 else max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / ln))
        d = (x - ax - vx * t) ** 2 + (y - ay - vy * t) ** 2
        if d < best:
            best = d
    return math.sqrt(best)


def curve(pts, per=12):
    """A smooth line through pts (Catmull-Rom), as many short straight pieces."""
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for k in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[k - 1], p[k], p[k + 1], p[k + 2]
        for s in range(per):
            t = s / per
            out.append(tuple(0.5 * ((2 * p1[a]) + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t * t
                                    + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t * t * t) for a in range(2)))
    out.append(tuple(pts[-1]))
    return out


def pick(rnd, weighted):
    total = sum(w for _, w in weighted)
    r = rnd.random() * total
    for item, w in weighted:
        r -= w
        if r <= 0:
            return item
    return weighted[-1][0]


# ---------------------------------------------------------------------------
# A forest: the shell, the gate, the ground, what grows on it
# ---------------------------------------------------------------------------

class Forest:
    RIM, RIM_WIDE = 440, 420
    SHORE_MUD = True # ground just above a water's level turns to dirt (the pond's shore)

    def __init__(self, name, origin, z0, seed, first_node, gate):
        self.name, self.seed = name, seed
        self.ox, self.oy = origin
        self.z0 = z0                      # the gate's floor: the height everything is measured from
        self.W = self.D = 4096
        self.zb = z0 - 256                # under the lowest ground
        self.lid = z0 + 1536              # the sky
        self.gate = gate                  # (side, where along it the culvert starts)
        self.vmf = Vmf()
        self.rnd = random.Random(seed)
        self.buildings = []               # (Plan, its origin here): the ground dives under them
        self.waters = []                  # (x1, y1, x2, y2, level, deep, material)
        self.trails = []                  # lines the ground is worn to dirt along
        self.clearings = []               # (x, y, r): nothing is planted here
        self.trees = []                   # (x, y) of what was planted, for the checks and the picture
        self.node_id = first_node
        self.first_node = first_node
        self.problems = []
        self.notes = []

    def vis(self, what):
        return "LC %s: %s" % (self.name, what)

    # --- places -----------------------------------------------------------

    def w(self, x, y, z):
        return (self.ox + x, self.oy + y, z)

    def box(self, x1, y1, z1, x2, y2, z2):
        return (self.ox + min(x1, x2), self.oy + min(y1, y2), min(z1, z2), self.ox + max(x1, x2), self.oy + max(y1, y2), max(z1, z2))

    def to_st(self, x, y):
        """A point as (along the gate's wall, in from it)."""
        side = self.gate[0]
        return {"west": (y, x), "south": (x, y), "east": (y, self.W - x), "north": (x, self.D - y)}[side]

    def st(self, s, t):
        side = self.gate[0]
        return {"west": (t, s), "south": (s, t), "east": (self.W - t, s), "north": (s, self.D - t)}[side]

    def st_box(self, s1, t1, s2, t2, z1, z2):
        (xa, ya), (xb, yb) = self.st(s1, t1), self.st(s2, t2)
        return self.box(xa, ya, z1, xb, yb, z2)

    # --- the ground ---------------------------------------------------------

    def base_ground(self, x, y):
        s = self.seed
        return self.z0 + 24 + 42 * noise(x / 900.0, y / 900.0, s) + 14 * noise(x / 260.0, y / 260.0, s + 1)

    def rim(self, x, y):
        d = min(x, self.W - x, y, self.D - y)
        k = 1 - smooth(d / float(self.RIM_WIDE))
        return k * (self.RIM + 70 * noise(x / 380.0, y / 380.0, self.seed + 2))

    def gate_pad(self, x, y, h):
        """The ground is flat at the gate's floor between the headwall's wings, then eases back into the forest."""
        s, t = self.to_st(x, y)
        g = self.gate[1]
        ds = max(g - s, 0, s - (g + GATE_WIDE))
        if t <= 384:
            return self.z0 if ds == 0 else h
        w = (1 - smooth((t - 384) / 320.0)) * (1 - smooth(ds / 200.0))
        return lerp(h, self.z0, w)

    def natural(self, x, y, bias=None):
        raise NotImplementedError

    def height(self, x, y, bias=None):
        for plan, (bx, by), dive in self.buildings:
            if plan.inside(x - bx, y - by):
                return dive
        return self.natural(x, y, bias)

    def slope(self, x, y):
        e = 24.0
        return math.hypot(self.natural(x + e, y) - self.natural(x - e, y), self.natural(x, y + e) - self.natural(x, y - e)) / (2 * e)

    def dirt(self, x, y):
        """How much of the ground's second look (dirt) shows, 0 to 255."""
        a = 0.0
        for line in self.trails:
            d = path_dist(x, y, line)
            a = max(a, 255 * (1 - smooth((d - 36) / 80.0)))
        a = max(a, 210 * smooth((self.slope(x, y) - 0.8) / 0.6))
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if self.SHORE_MUD and x1 - 64 <= x <= x2 + 64 and y1 - 64 <= y <= y2 + 64:
                a = max(a, 255 * (1 - smooth((self.natural(x, y) - level - 4) / 22.0)))
        s, t = self.to_st(x, y)
        if self.gate[1] - 64 <= s <= self.gate[1] + GATE_WIDE + 64 and t < 520:
            a = max(a, 255 * (1 - smooth((t - 380) / 140.0)))
        a = max(a, self.extra_dirt(x, y))
        return a + 26 * noise(x / 90.0, y / 90.0, self.seed + 9)

    def extra_dirt(self, x, y):
        return 0

    # --- building it --------------------------------------------------------

    def shell(self):
        v, W, D, T = self.vmf, self.W, self.D, WALL
        sky, nd = MAT["sky"], MAT["nodraw"]
        vis = self.vis("shell (sky, walls, slab)")
        v.world_box(self.box(-T, -T, self.zb - 64, W + T, D + T, self.zb), nd, vis=vis)
        v.world_box(self.box(-T, -T, self.lid, W + T, D + T, self.lid + 16), sky, sky, sky, vis=vis)
        side, g = self.gate
        ends = {"west": (-T, D + T), "east": (-T, D + T), "south": (0, W), "north": (0, W)}
        frames = {"west": lambda a, b: (-T, a, 0, b), "east": lambda a, b: (W, a, W + T, b), "south": lambda a, b: (a, -T, b, 0), "north": lambda a, b: (a, D, b, D + T)}
        toward = {"west": ("north", "south"), "east": ("north", "south"), "south": ("east", "west"), "north": ("east", "west")}
        for name in ("west", "east", "south", "north"):
            a, b = ends[name]
            pieces = [(a, b, None)]
            if name == side:
                pieces = [(a, g, toward[name][0]), (g + GATE_WIDE, b, toward[name][1])]
            for s1, s2, face in pieces:
                x1, y1, x2, y2 = frames[name](s1, s2)
                v.world_box(self.box(x1, y1, self.zb, x2, y2, self.lid), sky, vis=vis, faces={face: MAT["canal_wall"]} if face else None)
        # the gate: a culvert through the wall, with the wall carried on under and over it
        v.world_box(self.st_box(g, -T, g + GATE_WIDE, 0, self.zb, self.z0), MAT["canal_wall"], top=MAT["canal_floor"], vis=vis)
        v.world_box(self.st_box(g, -T, g + GATE_WIDE, 0, self.z0 + GATE_HIGH, self.lid), sky, bottom=MAT["ceiling"], vis=vis)
        bars = [self.st_box(g + 24 + 48 * i, -T + 80, g + 32 + 48 * i, -T + 88, self.z0, self.z0 + GATE_HIGH) for i in range(10)]
        gate_cap(v, self.st_box(g, -T, g + GATE_WIDE, -T + 64, self.z0, self.z0 + GATE_HIGH), bars, self.vis("gate's cap (delete to join)"))
        # the headwall inside the forest: the ridge is held back over and beside the culvert
        z0 = self.z0
        head = [self.st_box(g - 64, 0, g + GATE_WIDE + 64, 64, z0 + GATE_HIGH, z0 + 448)]
        for s1 in (g - 64, g + GATE_WIDE):
            head.append(self.st_box(s1, 0, s1 + 64, 256, z0 - 64, z0 + 448))
            head.append(self.st_box(s1, 256, s1 + 64, 384, z0 - 64, z0 + 256))
        v.detail(head, MAT["canal_wall"], vis=self.vis("structures"))

    def ground(self):
        """The terrain: a displaced patch every 512 units, each corner at the height function's height."""
        v = self.vmf
        self.heights = {}
        lo, hi = 1e9, -1e9
        for py in range(0, self.D, PATCH):
            for px in range(0, self.W, PATCH):
                bias = (px + PATCH / 2, py + PATCH / 2)
                grid = {}
                for i in range(9):
                    for j in range(9):
                        x, y = px + j * STEP, py + i * STEP
                        h = self.height(x, y, bias)
                        grid[(i, j)] = (h, self.dirt(x, y))
                        self.heights.setdefault((x, y), []).append(h)
                        lo, hi = min(lo, h), max(hi, h)

                def target(i, j, grid=grid, px=px, py=py):
                    return self.w(px + j * STEP, py + i * STEP, grid[(i, j)][0])

                def alpha(i, j, grid=grid):
                    return grid[(i, j)][1]
                v.world_box(self.box(px, py, self.zb, px + PATCH, py + PATCH, self.zb + 16), MAT["nodraw"], top=FMAT["ground"],
                            vis=self.vis("ground"), disp={"top": (3, target, alpha)})
        if lo < self.zb + 20 or hi > self.lid - 200:
            self.problems.append("the ground goes from %d to %d: outside the shell's room (%d to %d)" % (lo, hi, self.zb + 20, self.lid - 200))
        torn = sum(1 for hs in self.heights.values() if max(hs) - min(hs) > 0.01)
        if torn != self.allowed_tears():
            self.problems.append("%d places where neighbouring ground patches don't meet (expected %d)" % (torn, self.allowed_tears()))
        self.ground_range = (lo, hi)

    def allowed_tears(self):
        return 0

    def water(self):
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            self.vmf.world_box(self.box(x1, y1, level - deep, x2, y2, level), MAT["nodraw"], top=mat, vis=self.vis("water"))

    def wet(self, x, y):
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if x1 <= x <= x2 and y1 <= y <= y2 and self.natural(x, y) < level + 6:
                return True
        return False

    def kept_clear(self, x, y, margin=0):
        if min(x, self.W - x, y, self.D - y) < 70:
            return True
        for (cx, cy, r) in self.clearings:
            if math.hypot(x - cx, y - cy) < r + margin:
                return True
        for line in self.trails:
            if path_dist(x, y, line) < 84 + margin:
                return True
        for plan, (bx, by), dive in self.buildings:
            for dx in (-96, 0, 96):
                for dy in (-96, 0, 96):
                    if (int(x - bx + dx) // CELL, int(y - by + dy) // CELL) in plan.cells:
                        return True
        s, t = self.to_st(x, y)
        if self.gate[1] - 150 <= s <= self.gate[1] + GATE_WIDE + 150 and t < 620:
            return True
        return self.wet(x, y)

    def static(self, model, x, y, z, yaw, what, solid=6, pitch=0, fade=(2800, 3400)):
        self.vmf.point("prop_static", self.w(x, y, z), {
            "model": model, "angles": "%d %d 0" % (pitch, yaw), "skin": "0", "solid": solid, "disableshadows": "0",
            "screenspacefade": "0", "fademindist": fade[0], "fademaxdist": fade[1], "fadescale": "1"}, self.vis(what))

    def plant(self, leafy_near=None):
        """Trees, undergrowth, rocks and fallen wood, by rule: thick on the ridge, none on paths, water or buildings."""
        rnd, n = self.rnd, {"trees": 0, "plants": 0, "rocks": 0, "logs": 0}
        cell = 150
        for gy in range(0, self.D, cell):
            for gx in range(0, self.W, cell):
                x, y = gx + rnd.uniform(20, cell - 20), gy + rnd.uniform(20, cell - 20)
                d = min(x, self.W - x, y, self.D - y)
                want = 0.30 + 0.34 * (0.5 + 0.5 * noise(x / 700.0, y / 700.0, self.seed + 4))
                if d < 380:
                    want = 0.85
                if rnd.random() > want or self.kept_clear(x, y):
                    continue
                sl = self.slope(x, y)
                if sl > 1.7 or (sl > 0.8 and d >= 380 and rnd.random() < 0.5):
                    continue
                kinds = PINES
                if leafy_near and math.hypot(x - leafy_near[0], y - leafy_near[1]) < leafy_near[2] and rnd.random() < 0.6:
                    kinds = LEAFY
                self.static(pick(rnd, kinds), x, y, self.natural(x, y) - 8, rnd.randrange(0, 360, 5), "trees")
                self.trees.append((x, y))
                n["trees"] += 1
        for _ in range(2400):
            if n["plants"] >= 170:
                break
            x, y = rnd.uniform(90, self.W - 90), rnd.uniform(90, self.D - 90)
            if self.kept_clear(x, y, -30) or self.slope(x, y) > 0.7:
                continue
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0, fade=(1500, 2000))
            n["plants"] += 1
        for kind, models, count, sink in (("rocks", ROCKS, 34, 10), ("logs", LOGS, 12, 4)):
            for _ in range(900):
                if n[kind] >= count:
                    break
                x, y = rnd.uniform(120, self.W - 120), rnd.uniform(120, self.D - 120)
                if self.kept_clear(x, y, 20) or self.slope(x, y) > 0.8 or any(math.hypot(x - tx, y - ty) < 70 for tx, ty in self.trees):
                    continue
                self.static(rnd.choice(models), x, y, self.natural(x, y) - sink, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood")
                n[kind] += 1
        self.planted = n

    def node(self, x, y, z):
        self.vmf.point("info_node", self.w(x, y, z + 16), {"nodeid": self.node_id}, self.vis("path nodes"))
        self.node_id += 1

    def ground_nodes(self):
        """Where the city's people can walk: a node every 256 units on ground that is dry, open and not steep."""
        for y in range(128, self.D, 256):
            for x in range(128, self.W, 256):
                if self.slope(x, y) > 0.5 or self.wet(x, y) or any(math.hypot(x - tx, y - ty) < 56 for tx, ty in self.trees):
                    continue
                inside = False
                for plan, (bx, by), dive in self.buildings:
                    if (int(x - bx) // CELL, int(y - by) // CELL) in plan.cells:
                        inside = True
                if not inside:
                    self.node(x, y, self.natural(x, y))

    def plan_nodes(self, plan, origin, skip=()):
        for (i, j), spec in sorted(plan.cells.items()):
            if spec[0] == "solid" or i % 3 != 1 or j % 3 != 1:
                continue
            x, y = i * CELL + 32, j * CELL + 32
            if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in skip):
                continue
            self.node(origin[0] + x, origin[1] + y, spec[1])

    def finish(self):
        self.vmf.point("env_cubemap", self.w(self.W / 2, self.D / 2, self.natural(self.W / 2, self.D / 2) + 96), {"cubemapsize": "0"}, self.vis("structures"))
        problems, air = check(self.vmf, self.w(self.W / 2, self.D / 2, self.lid - 100), [])
        self.problems += problems
        self.skin_check()
        seals = sum(1 for _, s in self.vmf.boxes if s)
        side, g = self.gate
        (ax, ay), (bx, by) = self.st(g, -WALL), self.st(g + GATE_WIDE, -WALL)
        print("%s: %d sealing brushes, %d displaced faces, %d entities (%d trees, %d plants, %d rocks, %d logs, %d path nodes with ids %d to %d)" % (
            self.name, seals, self.vmf.disp_count, len(self.vmf.ents), self.planted["trees"], self.planted["plants"], self.planted["rocks"], self.planted["logs"],
            self.node_id - self.first_node, self.first_node, self.node_id - 1))
        print("  it fills x %d to %d, y %d to %d, z %d to %d; the ground runs from z %d to %d" % (
            self.ox - WALL, self.ox + self.W + WALL, self.oy - WALL, self.oy + self.D + WALL, self.zb - 64, self.lid + 16, self.ground_range[0], self.ground_range[1]))
        print("  gate (a culvert %d wide, %d high, floor z %d) in the %s wall: from (%d %d) to (%d %d)" % (
            GATE_WIDE, GATE_HIGH, self.z0, side, self.ox + ax, self.oy + ay, self.ox + bx, self.oy + by))
        for n in self.notes:
            print("  " + n)
        if self.problems:
            for p in self.problems:
                print("  PROBLEM: " + p)
        else:
            print("  checked: every brush corner on the grid; the shell is sealed; every ground patch meets its neighbours; the ground stays inside the shell")

    def skin_check(self):
        """Displaced faces: how many quads are folded back, and (for skins that aren't the ground) do their edges meet?"""
        made = self.vmf.disp_made
        folded = sum(m[2] for m in made)
        quads = sum(m[3] for m in made)
        if folded:
            self.notes.append("%d of %d displaced quads face backwards from the brush face they hang on (a sharply curved skin does this; a few are harmless)" % (folded, quads))
        skin = [m for m in made if m[0] != self.vis("ground")]
        if skin:
            cells = {}
            for k, m in enumerate(skin):
                for pt in m[1]:
                    cells.setdefault((round(pt[0] * 2), round(pt[1] * 2), round(pt[2] * 2)), set()).add(k)
            alone = sum(1 for ks in cells.values() if len(ks) < 2)
            self.notes.append("the cave's skin: %d faces; %d of its %d edge points meet another piece (the rest are the rock face's outer edge, expected %d)" % (
                len(skin), len(cells) - alone, len(cells), self.free_edge_points()))
            if alone != self.free_edge_points():
                self.problems.append("the cave's skin has %d loose edge points, expected %d" % (alone, self.free_edge_points()))

    def free_edge_points(self):
        return 0

    # --- a picture from above, to look at before the owner does ---------------

    def preview(self, path):
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            print("  (no picture: Pillow isn't installed)")
            return
        n, step = 256, 16
        hs = [[self.natural(i * step, (n - 1 - j) * step) for i in range(n + 1)] for j in range(n + 1)]
        img = Image.new("RGB", (n, n))
        px = img.load()
        for j in range(n):
            for i in range(n):
                x, y = i * step, (n - 1 - j) * step
                h = hs[j][i]
                shade = 0.62 + ((hs[j][i] - hs[j][i + 1]) + (hs[j][i] - hs[j + 1][i])) / 46.0
                shade = max(0.25, min(1.25, shade))
                d = max(0.0, min(1.0, self.dirt(x, y) / 255.0))
                col = (lerp(70, 132, d), lerp(112, 104, d), lerp(58, 72, d))
                level = None
                for (x1, y1, x2, y2, lv, deep, mat) in self.waters:
                    if x1 <= x <= x2 and y1 <= y <= y2 and h < lv:
                        level = lv
                if level is not None:
                    k = min(1.0, (level - h) / 60.0)
                    col, shade = (lerp(70, 28, k), lerp(130, 70, k), lerp(160, 120, k)), 1.0
                px[i, j] = tuple(int(max(0, min(255, c * shade))) for c in col)
        img = img.resize((1024, 1024), Image.BILINEAR)
        dr = ImageDraw.Draw(img, "RGBA")

        def P(x, y):
            return (x / 4.0, (self.D - y) / 4.0)
        for plan, (bx, by), dive in self.buildings:
            for (i, j), spec in plan.cells.items():
                a, b = P(bx + i * CELL, by + (j + 1) * CELL), P(bx + (i + 1) * CELL, by + j * CELL)
                dr.rectangle((a[0], a[1], b[0], b[1]), fill=(150, 150, 156, 255) if spec[0] == "solid" else (52, 52, 58, 255))
        self.preview_extra(dr, P)
        for (x, y) in self.trees:
            c = P(x, y)
            dr.ellipse((c[0] - 5, c[1] - 5, c[0] + 5, c[1] + 5), fill=(22, 60, 30, 210))
        s1, s2 = self.st(self.gate[1], 0), self.st(self.gate[1] + GATE_WIDE, 0)
        dr.line((P(*s1), P(*s2)), fill=(255, 220, 60, 255), width=5)
        dr.text((8, 8), "%s  (north up, 4096 units square; yellow: the gate)" % self.name, fill=(255, 255, 255, 255))
        img.save(path)
        print("  picture: " + path)

    def preview_extra(self, dr, P):
        pass


# ---------------------------------------------------------------------------
# The bunker, and the pond with its island
# ---------------------------------------------------------------------------

class BunkerForest(Forest):
    POND = (1500, 1400, 640, 480)   # centre x, y; half its length and width
    ISLE = (1560, 1385, 260)
    B0 = (2240, 3072)               # the bunker's own corner: its door's wall is its south side

    def setup(self):
        z0 = self.z0
        self.zp = z0 + 24                # the ground at the bunker's door
        self.zl = self.zp - 128          # the bunker's floor, down the stairs
        self.level = z0 - 6              # the pond's surface
        self.trails.append(curve([(0, 3328), (500, 3328), (1100, 2900), (1560, 2180), (2300, 2520), (2880, 2760), (2880, 3060)]))
        self.clearings += [(self.POND[0], self.POND[1], 760), (2880, 2900, 240)]
        self.waters.append((704, 768, 2304, 2048, self.level, self.level - (self.zb + 16), FMAT["pond"]))
        zp, zl, fm = self.zp, self.zl, FMAT["bunker_floor"]
        plan = Plan((self.ox + self.B0[0], self.oy + self.B0[1]), [(zl - 64, zp + 208, FMAT["bunker_wall"])], floor_side=FMAT["bunker_wall"],
                    ceiling=FMAT["bunker_ceiling"], roof=FMAT["bunker_floor"], vis=self.vis("structures"))
        plan.keep_out.append((-100000, -100000, 100000, 0))
        plan.paint((576, 0, 704, 64), ("low", zp, fm, zp + 128))      # the doorway
        plan.paint((576, 64, 704, 192), ("low", zp, fm, zp + 144))    # inside the door
        plan.paint((576, 192, 704, 384), ("low", zl, fm, zp + 144))   # the stairs down
        plan.paint((576, 384, 704, 448), ("low", zl, fm, zl + 160))
        plan.paint((384, 448, 896, 832), ("low", zl, fm, zl + 160))   # the main room
        plan.paint((320, 640, 384, 704), ("low", zl, fm, zl + 128))
        plan.paint((64, 512, 320, 832), ("low", zl, fm, zl + 160))    # west: the bunks
        plan.paint((896, 640, 960, 704), ("low", zl, fm, zl + 128))
        plan.paint((960, 512, 1216, 832), ("low", zl, fm, zl + 160))  # east: the generator and stores
        plan.walls()
        self.plan = plan
        self.buildings.append((plan, self.B0, zl - 110))

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        # the mound the bunker is under: level with its roof, falling away on every side
        bx, by = self.B0
        mound = self.zp + 204 * (1 - smooth(rect_dist(x, y, (bx, by + 448, bx + 1280, by + 1100)) / 400.0))
        h = max(h, mound)
        # flat at the door
        h = lerp(h, self.zp, 1 - smooth(rect_dist(x, y, (bx + 512, by - 340, bx + 768, by)) / 170.0))
        # the pond: a bowl, a shore, and nothing else below the water near it
        cx, cy, rx, ry = self.POND
        ang = math.atan2(y - cy, x - cx)
        wob = 1 + 0.10 * noise(math.cos(ang) * 1.4 + 7, math.sin(ang) * 1.4, self.seed + 6)
        e = math.hypot((x - cx) / rx, (y - cy) / ry) / wob
        lv = self.level
        if e < 1.4:
            if e < 1:
                bowl = lv - 6 - 92 * (1 - e * e) ** 0.8
            else:
                bowl = lerp(lv - 6, max(h, lv + 16), smooth((e - 1) / 0.4))
            h = bowl
            ix, iy, ir = self.ISLE
            h = max(h, lv - 62 + 104 * (1 - smooth(math.hypot(x - ix, y - iy) / ir)))
        elif 640 <= x <= 2368 and 704 <= y <= 2112:
            h = max(h, lv + 12)
        return self.gate_pad(x, y, h)

    def extra_dirt(self, x, y):
        bx, by = self.B0
        return 255 * (1 - smooth(rect_dist(x, y, (bx + 480, by - 300, bx + 800, by)) / 150.0))

    def bunker(self):
        v, plan, zp, zl = self.vmf, self.plan, self.zp, self.zl
        plan.build(v)
        B, bx, by = plan.box, self.B0[0], self.B0[1]
        vis = self.vis("structures")
        v.detail([B(576, 192 + 12 * k, zl, 704, 204 + 12 * k, zp - 8 * (k + 1)) for k in range(15)], FMAT["bunker_wall"], vis=vis, top=MAT["stairs"])
        # light: the main room, the stairs, and a failing tube in the east room; the bunks are dark
        for (u, w, z, colour, style) in ((640, 640, zl + 136, "255 205 150 140", "0"), (640, 150, zp + 120, "255 225 190 70", "0"), (1088, 672, zl + 136, "190 255 215 90", "10")):
            v.point("light", plan.world(u, w, z), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": style}, self.vis("lights"))
        v.point("env_cubemap", plan.world(640, 640, zl + 72), {"cubemapsize": "0"}, vis)
        # what was left behind (all compiled as static props; in the structures' visgroup)
        inside = (
            ("models/props_forest/bunkbed.mdl", 130, 600, 0), ("models/props_forest/bunkbed.mdl", 130, 760, 0), ("models/props_forest/footlocker01_closed.mdl", 250, 560, 90),
            ("models/props_c17/lockers001a.mdl", 250, 806, 180), ("models/props_wasteland/controlroom_desk001a.mdl", 640, 790, 180),
            ("models/props_wasteland/controlroom_filecabinet002a.mdl", 850, 800, 180), ("models/props_c17/oildrum001.mdl", 430, 490, 15),
            ("models/props_junk/wood_crate001a.mdl", 440, 780, 20), ("models/props_junk/wood_crate001a.mdl", 500, 800, 65),
            ("models/props_outland/generator_static01a.mdl", 1090, 770, 90), ("models/props_forest/shelves.mdl", 1180, 580, 270),
            ("models/props_silo/barrelwarning.mdl", 1010, 560, 30), ("models/props_silo/barrelwarning.mdl", 1060, 548, 200),
        )
        for model, u, w, yaw in inside:
            self.static(model, bx + u, by + w, zl, yaw, "structures", fade=(-1, 0))
        for model, x, y, yaw in (("models/props_c17/concrete_barrier001a.mdl", bx + 470, by - 70, 80), ("models/props_c17/concrete_barrier001a.mdl", bx + 800, by - 90, 100),
                                 ("models/props_vehicles/truck001a.mdl", bx + 420, by - 330, 35)):
            self.static(model, x, y, self.natural(x, y), yaw, "structures")
        self.plan_nodes(plan, self.B0, skip=[(576, 192, 704, 384)])
        for (u, w, z) in ((640, 232, zp - 32), (640, 300, zp - 72), (640, 360, zp - 116)):
            self.node(bx + u, by + w, z)
        self.notes.append("the bunker: its door at (%d %d), floor z %d inside the door and %d down the stairs; five rooms, 3 lights" % (
            self.ox + bx + 640, self.oy + by, zp, zl))

    def pond(self):
        cx, cy, rx, ry = self.POND
        ix, iy, ir = self.ISLE
        rnd, n = self.rnd, 0
        for k in range(60):
            a = rnd.uniform(0, 6.283)
            for r in (0.96, 1.0, 1.04, 1.08):
                x, y = cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)
                h = self.natural(x, y)
                if self.level - 10 <= h <= self.level + 3:
                    self.static("models/props_foliage/cattails.mdl", x, y, h, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0, fade=(1500, 2000))
                    n += 1
                    break
        top = self.natural(ix, iy)
        self.static("models/props_foliage/tree_deciduous_01a.mdl", ix, iy, top - 8, 40, "trees")
        self.static("models/props_foliage/forestrock_single01.mdl", ix + 46, iy - 30, self.natural(ix + 46, iy - 30) - 8, 120, "rocks, plants and fallen wood")
        self.static("models/props_foliage/driftwood_01a.mdl", cx - rx * 0.86, cy + ry * 0.35, self.level - 2, 70, "rocks, plants and fallen wood")
        self.trees.append((ix, iy))
        self.vmf.point("env_cubemap", self.w(cx, cy - 200, self.level + 64), {"cubemapsize": "0"}, self.vis("water"))
        self.notes.append("the pond: about %d by %d, surface z %d, up to %d deep; the island's top is %d above the water; %d cattails on the shore" % (
            2 * rx, 2 * ry, self.level, self.level - min(self.natural(cx + dx, cy + dy) for dx in (-200, 0, 200) for dy in (-150, 150)), top - self.level, n))


def forest_bunker(args):
    f = BunkerForest("forest (bunker, pond)", tuple(args.origin or (8064, 1088)), args.floor, 31, args.first_node or 4400, ("west", 3072))
    f.setup()
    f.shell()
    f.ground()
    f.water()
    f.bunker()
    f.plant(leafy_near=(f.POND[0], f.POND[1], 1100))
    f.pond()
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
    return f.vmf, f.problems


# ---------------------------------------------------------------------------
# The cave, and the stream that runs out of it
# ---------------------------------------------------------------------------

class CaveForest(Forest):
    SHORE_MUD = False                   # (the stream's banks are dirt by their own rule)
    CX, YM, LONG = 2304, 2560, 1280     # the mouth's middle, the hillside's line, how far in it goes
    HALF, TALL = 160, 320               # the square the cave's skin is hung on
    TEAR = 640                          # the hillside is cut this far each side of the mouth

    def setup(self):
        z0 = self.z0
        self.zf = z0 + 30                # the cave's floor and the ground before it
        self.level = self.zf - 16        # the stream's surface
        cx, ym = self.CX, self.YM
        self.spring = (cx - 60, ym + 880)
        self.sink = (3560, 1280)
        inside = [(cx - 60 + self.wander(ym + s), ym + s) for s in (880, 700, 500, 300, 120)]
        self.stream_line = curve(inside + [(cx - 60, ym), (cx + 60, 2230), (cx - 160, 1860), (2520, 1520), (3080, 1390), self.sink])
        self.trails.append(curve([(512, 0), (512, 520), (900, 1120), (1640, 1660), (2100, 1890), (2390, 2280), (cx + 40, ym)]))
        self.clearings += [(cx, ym - 260, 330), (self.sink[0], self.sink[1], 200)]
        deep = 48
        seen = set()
        for (x, y) in self.stream_line + [(self.sink[0] + dx, self.sink[1] + dy) for dx in (-150, 150) for dy in (-150, 150)]:
            for dx in (-100, 100):
                for dy in (-100, 100):
                    key = (int((x + dx) // PATCH), int((y + dy) // PATCH))
                    if key not in seen and 0 <= key[0] < 8 and 0 <= key[1] < 8:
                        seen.add(key)
                        self.waters.append((key[0] * PATCH, key[1] * PATCH, (key[0] + 1) * PATCH, (key[1] + 1) * PATCH, self.level, deep, FMAT["stream"]))
        self.wet_patches = seen

    # --- the ground ---------------------------------------------------------

    def stream_dist(self, x, y):
        return path_dist(x, y, self.stream_line)

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        zf, cx, ym = self.zf, self.CX, self.YM
        ds = self.stream_dist(x, y)
        dk = math.hypot(x - self.sink[0], y - self.sink[1])
        # the stream's valley: level ground along it
        h = lerp(h, zf + 5 * noise(x / 120.0, y / 120.0, self.seed + 7), 1 - smooth((min(ds, dk) - 120) / 300.0))
        # the hill the cave is in, and the gully cut into its face
        ax = abs(x - cx)
        side = 1 - smooth((ax - self.TEAR - 150 * (0.5 + 0.5 * noise(y / 330.0, 1.5 if x > cx else 8.5, self.seed + 15))) / (420.0 + 160 * noise(y / 500.0, 4.5, self.seed + 16)))
        back = y > ym or (y == ym and bias is not None and bias[1] > ym)
        if back:
            hill = zf + (640 + 120 * smooth((y - ym) / 500.0) + 24 * noise(x / 300.0, y / 300.0, self.seed + 8)) * side
            return max(h, hill)
        gully = smooth((ax - 224 - 0.45 * (ym - y)) / 416.0)          # 0 on the gully's floor, 1 on the hill
        reach = 560 + 170 * noise(x / 420.0, 2.5, self.seed + 17) * smooth((ax - 300) / 300.0)
        front = zf + (640 + 24 * noise(x / 300.0, ym / 300.0, self.seed + 8)) * side * (1 - smooth((ym - y) / reach)) * gully
        h = max(h, front)
        if ax < 224 + 0.45 * (ym - y) and ym - y < 620:
            h = lerp(h, zf + 4 * noise(x / 90.0, y / 90.0, self.seed + 10), 1 - smooth((ym - y - 420) / 200.0))
        # the stream's bed and banks, and its sink; nothing else below the water in the patches the water is in
        lv = self.level
        bed = lv - 18 + 30 * smooth((ds - 30) / 56.0)
        if ds < 86:
            h = min(h, bed)
        if dk < 190:
            h = min(h, lv - 40 + 54 * smooth((dk - 60) / 130.0))
        if ds >= 86 and dk >= 190 and (int(x // PATCH), int(y // PATCH)) in self.wet_patches:
            h = max(h, lv + 8)
        return self.gate_pad(x, y, h)

    def free_edge_points(self):
        # the rock face's outer edge (67 points: it is buried in the hillside), and the floor's front edge
        # across the mouth (7: it lies on the ground before the cave)
        return 67 + 7

    def allowed_tears(self):
        return sum(1 for x in range(0, self.W + 1, STEP) if abs(x - self.CX) < self.TEAR and abs(self.natural(x, self.YM, (0, 0)) - self.natural(x, self.YM, (0, 9999))) > 0.01)

    def extra_dirt(self, x, y):
        a = 255 * (1 - smooth((self.stream_dist(x, y) - 40) / 70.0))
        if abs(x - self.CX) < 420 and 0 < self.YM - y < 520:
            a = max(a, 220)
        return a

    # --- the cave's skin ------------------------------------------------------

    def wander(self, y):
        s = y - self.YM
        return 110 * math.sin(s / 420.0 + 0.6) * smooth(s / 256.0)

    def radius(self, y):
        s = y - self.YM
        r = 190 - 30 * smooth(1 - abs(s - 300) / 200.0) + 150 * smooth(1 - abs(s - 800) / 330.0)
        return r * (1 - 0.35 * smooth((s - 1150) / 130.0))

    def cave_floor(self, x, y):
        zf = self.zf
        sx = self.CX - 60 + self.wander(y)
        carve = 0.0
        if y <= self.spring[1] + 40:
            carve = 24 * (1 - smooth((abs(x - sx) - 14) / 44.0))
        carve = max(carve, 36 * (1 - smooth((math.hypot(x - self.spring[0] - self.wander(self.spring[1]), y - self.spring[1]) - 40) / 90.0)))
        inner = zf + 5 * noise(x / 80.0, y / 80.0, self.seed + 11) - carve
        s = y - self.YM
        if s < 96:
            # at the mouth the cave's floor IS the ground before it, so there is no step or crack on the threshold
            return lerp(self.natural(x, self.YM, (0, 0)), inner, smooth(s / 96.0))
        return inner

    def ring(self, theta, y):
        """A point of the cave's skin: round the passage by theta, y along it."""
        s = y - self.YM
        R = self.radius(y)
        r = R * (1 + 0.2 * noise(math.cos(theta) * 1.6 + y / 170.0, math.sin(theta) * 1.6 - y / 230.0, self.seed + 12))
        x = self.CX + self.wander(y) + 1.15 * r * math.cos(theta)
        z = self.zf + 0.51 * R + 0.85 * r * math.sin(theta)
        z = max(z, self.cave_floor(x, y))
        edge = smooth(s / 64.0) * smooth((self.LONG - s) / 64.0)
        return (x, y + 14 * edge * noise(theta * 2.0 + 3, y / 90.0, self.seed + 13), z)

    def on_square(self, xn, zn, y):
        """A point of the square the skin hangs on (xn across from the middle, zn up from the floor), moved onto the skin."""
        return self.ring(math.atan2(zn - self.TALL / 2.0, xn), y)

    def collar(self, xn, zn):
        """The rock face round the mouth: the skin's own edge at the mouth, easing out to a rough wall that leans back."""
        H, T = self.HALF, self.TALL
        qx, qz = max(-H, min(H, xn)), max(0, min(T, zn))
        d = math.hypot(xn - qx, zn - qz)
        px, py, pz = self.on_square(qx, qz, self.YM)
        near = (px + (xn - qx), py, pz + (zn - qz))
        bulge = 26 + 34 * noise(xn / 140.0, zn / 140.0, self.seed + 14)
        far = (self.CX + xn, self.YM - bulge + 0.15 * zn, self.zf + zn - (24 * smooth(d / 100.0) if zn == 0 else 0))
        w = smooth(d / 200.0)
        return tuple(lerp(near[k], far[k], w) for k in range(3))

    def cave(self):
        v, cx, ym, zf, H, T = self.vmf, self.CX, self.YM, self.zf, self.HALF, self.TALL
        vis, mat, nd = self.vis("cave"), FMAT["cave"], MAT["nodraw"]
        W = lambda p: self.w(p[0], p[1], p[2])

        def dirt_of(p):
            # dirt on the floor, rock on the walls and roof
            return 235 * (1 - smooth((p[2] - self.cave_floor(p[0], p[1]) - 6) / 34.0))

        def face(box, name, point):
            pts = {}

            def target(i, j):
                pts[(i, j)] = point(i, j)
                return W(pts[(i, j)])

            def alpha(i, j):
                return dirt_of(pts[(i, j)])
            v.world_box(self.box(*box), nd, vis=vis, faces={name: mat}, disp={name: (3, target, alpha)})
        seg = 256
        for k in range(self.LONG // seg):
            y0 = ym + k * seg
            face((cx - H, y0, zf - 16, cx + H, y0 + seg, zf), "top", lambda i, j, y0=y0: self.on_square(-H + 40 * j, 0, y0 + 32 * i))
            face((cx - H, y0, zf + T, cx + H, y0 + seg, zf + T + 16), "bottom", lambda i, j, y0=y0: self.on_square(-H + 40 * i, T, y0 + 32 * j))
            face((cx - H - 16, y0, zf, cx - H, y0 + seg, zf + T), "east", lambda i, j, y0=y0: self.on_square(-H, 40 * i, y0 + 32 * j))
            face((cx + H, y0, zf, cx + H + 16, y0 + seg, zf + T), "west", lambda i, j, y0=y0: self.on_square(H, 40 * j, y0 + 32 * i))
        # the far end: the skin drawn together into a rough dome
        yend = ym + self.LONG
        mid = (cx + self.wander(yend), yend, zf + 0.51 * self.radius(yend))

        def dome(i, j):
            xn, zn = -H + 40 * j, 40 * i
            rho = max(abs(xn) / H, abs(zn - T / 2.0) / (T / 2.0))
            if rho < 0.001:
                p = (mid[0], mid[1] + 90, mid[2])
            else:
                edge = self.on_square(xn / rho, T / 2.0 + (zn - T / 2.0) / rho, yend)
                p = (lerp(mid[0], edge[0], rho), edge[1] + 90 * (1 - rho * rho), lerp(mid[2], edge[2], rho))
            return (p[0], p[1], max(p[2], self.cave_floor(p[0], yend)))
        face((cx - H, yend, zf, cx + H, yend + 16, zf + T), "south", dome)
        # the rock face round the mouth: five pieces that share their edges with each other and with the cave's first ring
        for (x1, x2, z1, z2) in ((-608, -H, 0, T), (H, 608, 0, T), (-608, -H, T, 704), (-H, H, T, 704), (H, 608, T, 704)):
            face((cx + x1, ym - 16, zf + z1, cx + x2, ym, zf + z2), "south",
                 lambda i, j, x1=x1, x2=x2, z1=z1, z2=z2: self.collar(x1 + (x2 - x1) * j / 8.0, z1 + (z2 - z1) * i / 8.0))
        # light: daylight does the mouth; two dim lights further in, and the far end left dark
        for (s, up, colour) in ((470, 150, "150 190 255 60"), (820, 210, "255 190 120 110")):
            y = ym + s
            v.point("light", self.w(cx + self.wander(y), y, zf + up), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("env_cubemap", self.w(cx + self.wander(ym + 800), ym + 800, zf + 80), {"cubemapsize": "0"}, vis)
        # hanging rock in the big chamber, fallen rock along the walls, and rocks to dress the mouth's edges
        rnd = self.rnd
        for k in range(7):
            y = ym + rnd.uniform(560, 1020)
            th = rnd.uniform(1.1, 2.0)
            p = self.ring(th, y)
            self.static("models/props_mining/stalactite_static0%d.mdl" % rnd.choice((1, 2)), p[0], p[1], p[2] - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        for (s, side) in ((200, 1), (620, -1), (900, 1), (1120, -1)):
            y = ym + s
            p = self.ring(-0.5 if side > 0 else math.pi + 0.5, y)
            self.static("models/props_mining/caverocks_cluster0%d.mdl" % rnd.choice((1, 2)), p[0] - 30 * side, p[1], self.cave_floor(p[0] - 30 * side, p[1]) - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        for (dx, model) in ((-300, "models/cliffs/rocks_medium01.mdl"), (290, "models/cliffs/rockcluster01.mdl"), (-520, "models/cliffs/rocks_large01.mdl"), (500, "models/cliffs/rockcluster02.mdl")):
            x, y = cx + dx, ym - 60
            self.static(model, x, y, self.natural(x, y) - 14, rnd.randrange(0, 360, 15), "cave")
        for s in range(64, self.LONG - 100, 192):
            y = ym + s
            x = cx + self.wander(y) + 70
            self.node(x, y, self.cave_floor(x, y))
        tall = max(self.ring(math.pi / 2, ym + s)[2] for s in range(0, self.LONG, 32)) - zf
        mouth_w = self.ring(0, ym)[0] - self.ring(math.pi, ym)[0]
        mouth_h = self.ring(math.pi / 2, ym)[2] - zf
        cover = min(self.natural(cx + self.wander(ym + s), ym + s, (0, 9999)) - self.ring(math.pi / 2, ym + s)[2] for s in range(0, self.LONG, 32))
        if cover < 40:
            self.problems.append("the cave's roof comes within %d of the hill's surface" % cover)
        self.notes.append("the cave: its mouth at (%d %d), floor z %d, about %d wide and %d high; it runs %d north, up to %d high in its big chamber; at least %d of hill over its roof" % (
            self.ox + cx, self.oy + ym, zf, mouth_w, mouth_h, self.LONG, tall, cover))
        self.notes.append("the stream: surface z %d, from a spring in the cave's chamber, out of the mouth, to a sink pool at (%d %d); a trail fords it" % (
            self.level, self.ox + self.sink[0], self.oy + self.sink[1]))

    def kept_clear(self, x, y, margin=0):
        if self.stream_dist(x, y) < 70 + margin:
            return True
        if abs(x - self.CX) < 240 + 0.45 * max(0, self.YM - y) and 0 <= self.YM - y < 560:
            return True
        return Forest.kept_clear(self, x, y, margin)

    def preview_extra(self, dr, P):
        ym = self.YM
        left = [P(self.ring(math.pi, ym + s)[0], ym + s) for s in range(0, self.LONG + 1, 32)]
        right = [P(self.ring(0, ym + s)[0], ym + s) for s in range(0, self.LONG + 1, 32)]
        dr.polygon(left + right[::-1], fill=(20, 20, 24, 150), outline=(255, 255, 255, 200))

    def cave_picture(self, path):
        """The mouth seen from the front, and the passage seen from the side: is the skin a sane shape?"""
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            return
        img = Image.new("RGB", (1500, 620), (16, 16, 20))
        dr = ImageDraw.Draw(img)
        cx, ym, zf = self.CX, self.YM, self.zf

        def F(x, z):
            return (360 + (x - cx) * 0.5, 440 - (z - zf) * 0.5)
        for (x1, x2, z1, z2) in ((-608, -160, 0, 320), (160, 608, 0, 320), (-608, -160, 320, 704), (-160, 160, 320, 704), (160, 608, 320, 704)):
            g = [[self.collar(x1 + (x2 - x1) * j / 8.0, z1 + (z2 - z1) * i / 8.0) for j in range(9)] for i in range(9)]
            for i in range(9):
                for j in range(9):
                    if j < 8:
                        dr.line((F(g[i][j][0], g[i][j][2]), F(g[i][j + 1][0], g[i][j + 1][2])), fill=(150, 150, 160))
                    if i < 8:
                        dr.line((F(g[i][j][0], g[i][j][2]), F(g[i + 1][j][0], g[i + 1][j][2])), fill=(150, 150, 160))
        ring = [self.ring(k * math.pi / 32, ym) for k in range(65)]
        dr.line([F(p[0], p[2]) for p in ring], fill=(255, 200, 60), width=2)
        front = [F(x, self.natural(x, ym, (0, 0))) for x in range(cx - 720, cx + 721, 16)]
        dr.line(front, fill=(90, 200, 90), width=2)
        back = [F(x, self.natural(x, ym, (0, 9999))) for x in range(cx - 720, cx + 721, 16)]
        dr.line(back, fill=(60, 120, 60), width=1)
        dr.line((F(cx - 720, self.level), F(cx + 720, self.level)), fill=(70, 130, 220))
        dr.text((10, 8), "the mouth from the front: grey the rock face, yellow the cave's first ring, green the ground before it (dark green: behind), blue the stream's level", fill=(230, 230, 230))

        def S(y, z):
            return (760 + (y - ym) * 0.52, 440 - (z - zf) * 0.5)
        for th, col in ((math.pi / 2, (255, 200, 60)), (-math.pi / 2, (255, 200, 60))):
            dr.line([S(ym + s, self.ring(th, ym + s)[2]) for s in range(0, self.LONG + 1, 16)], fill=col, width=2)
        dr.line([S(ym + s, self.natural(cx + self.wander(ym + s), ym + s, (0, 9999))) for s in range(0, self.LONG + 1, 16)], fill=(90, 200, 90), width=2)
        dr.line([S(ym - s, self.natural(cx, ym - s, (0, 0))) for s in range(0, 600, 16)], fill=(90, 200, 90), width=2)
        dr.line((S(ym - 600, self.level), S(ym + 900, self.level)), fill=(70, 130, 220))
        dr.text((760, 30), "the passage from the side (south on the left): yellow its roof and floor, green the ground and the hill over it", fill=(230, 230, 230))
        img.save(path)
        print("  picture: " + path)


def forest_cave(args):
    f = CaveForest("forest (cave, stream)", tuple(args.origin or (5632, 5824)), args.floor, 47, args.first_node or 4800, ("south", 256))
    f.setup()
    f.shell()
    f.ground()
    f.water()
    f.cave()
    f.plant()
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
        f.cave_picture(args.preview.rsplit(".", 1)[0] + "_cave.png")
    return f.vmf, f.problems
