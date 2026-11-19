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

from map_build import CELL, GATE_HIGH, GATE_WIDE, MAT, Plan, Vmf, check, flood, gate_cap, reaches, test_extras

PATCH, STEP, WALL = 512, 64, 128

FMAT = {
    "ground": "nature/blendgrassdirt01",          # ep2: forest grass, blending to forest dirt
    "cave": "nature/blendrockdirt_tunnel02a",     # ep2: cave rock, blending to dirt
    "cliff": "nature/blendcliffdirt001a",         # hl2: a cliff's face, blending to dirt (the rock round the cave's mouth)
    "pond": "nature/water_canals_water_clear",    # hl2
    "stream": "nature/water_riverbed02",          # ep2: the Episode Two river water
    "bunker_wall": "concrete/concretewall008a",   # these three are in the owner's own map
    "bunker_floor": "concrete/concretefloor031a",
    "bunker_ceiling": "concrete/concreteceiling004a",
    "door": "metal/metalhull003a",                # hl2: riveted steel plate (the bunker door's leaves)
    "office_wall": "wood/woodwall047a",           # ep2: a board wall (the mine office in the cave)
    "office_floor": "wood/woodfloor007a",         # hl2: floorboards
    "office_ceiling": "metal/metalroof004a",      # hl2: corrugated iron
    "timber": "wood/woodbeam001a",                # hl2: a squared beam
}

PINES = (("models/props_foliage/tree_pine04.mdl", 3), ("models/props_foliage/tree_pine05.mdl", 3), ("models/props_foliage/tree_pine06.mdl", 3),
         ("models/props_foliage/tree_pine_large.mdl", 1), ("models/props_foliage/tree_dead01.mdl", 0.4), ("models/props_foliage/tree_dead03.mdl", 0.4))
# (not the tree_deciduous ones: Episode Two's copy of their leaves is drawn at full brightness whatever the light,
#  as the cattails are: their materials are "UnlitGeneric". Found when the owner saw the reeds glowing in the dark.)
LEAFY = (("models/props_foliage/oak_tree01.mdl", 2), ("models/props_foliage/tree_poplar_01.mdl", 2))
SHORE = ("models/props_foliage/fern01.mdl", "models/props_foliage/ferns01.mdl", "models/props_foliage/ferns02.mdl", "models/props_foliage/shrub_small.mdl")
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
    TREES = 0.75     # how thickly trees stand (the owner, after walking both: "too thick with trees ... reduce it about 25%")

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
        self.test = False

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
        gate_cap(v, self.st_box(g, -T, g + GATE_WIDE, -T + 64, self.z0, self.z0 + GATE_HIGH), self.st_box(g, -T + 80, g + GATE_WIDE, -T + 88, self.z0, self.z0 + GATE_HIGH),
                 "y" if side in ("west", "east") else "x", self.vis("gate's cap (delete to join)"))
        # an areaportal across the culvert, just inside the bars: the forest is drawn from outside only through it
        v.areaportal(self.st_box(g, -T + 110, g + GATE_WIDE, -T + 112, self.z0, self.z0 + GATE_HIGH), self.vis("areaportals"))
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
                want *= self.TREES
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
        if self.test:
            # (to compile and walk it by itself: a spawn point on the trail just inside the gate, and the map's sun)
            sx, sy = self.st(self.gate[1] + GATE_WIDE / 2, 220)
            yaw = {"west": 0, "south": 90, "east": 180, "north": 270}[self.gate[0]]
            test_extras(self.vmf, self.w(sx, sy, self.z0 + 16), yaw, self.vis("for testing alone (never in the real map)"))
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
        step = 16
        nx, ny = self.W // step, self.D // step
        hs = [[self.natural(i * step, (ny - 1 - j) * step) for i in range(nx + 1)] for j in range(ny + 1)]
        img = Image.new("RGB", (nx, ny))
        px = img.load()
        for j in range(ny):
            for i in range(nx):
                x, y = i * step, (ny - 1 - j) * step
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
        img = img.resize((nx * 4, ny * 4), Image.BILINEAR)
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
        dr.text((8, 8), "%s  (north up, %d by %d units; yellow: the gate)" % (self.name, self.W, self.D), fill=(255, 255, 255, 255))
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
    DOOR = (512, 768)               # the doorway, in the bunker's own coordinates: 256 wide and 192 high, shut by two sliding leaves

    def setup(self):
        z0 = self.z0
        self.zb = z0 - 448               # (the deep rooms need the forest's slab lower than a forest's usual 256)
        self.zp = z0 + 24                # the ground at the bunker's door
        self.zl = self.zp - 128          # the first level, down the first stairs
        self.zd = self.zl - 192          # the deep level, down the second
        self.level = z0 - 6              # the pond's surface
        self.trails.append(curve([(0, 3328), (500, 3328), (1100, 2900), (1560, 2180), (2300, 2520), (2880, 2760), (2880, 3060)]))
        self.clearings += [(self.POND[0], self.POND[1], 760), (2880, 2880, 260)]
        self.waters.append((704, 768, 2304, 2048, self.level, self.level - (self.zb + 16), FMAT["pond"]))
        zp, zl, zd, fm = self.zp, self.zl, self.zd, FMAT["bunker_floor"]
        origin = (self.ox + self.B0[0], self.oy + self.B0[1])
        look = dict(floor_side=FMAT["bunker_wall"], ceiling=FMAT["bunker_ceiling"], vis=self.vis("structures"))
        # the part under the mound: its roof is level with the mound's top, and the ground dives under it
        plan = Plan(origin, [(zd - 64, zp + 272, FMAT["bunker_wall"])], roof=FMAT["bunker_floor"], **look)
        plan.keep_out += [(-100000, -100000, 100000, 0), (-100000, 576, -320, 832)]   # in front of the door; where the deep level joins
        plan.paint((512, 0, 768, 64), ("low", zp, fm, zp + 192))      # the doorway: 256 wide, 192 high
        plan.paint((448, 64, 832, 256), ("low", zp, fm, zp + 208))    # the room inside the door (its front wall is what the door's leaves slide into)
        plan.paint((576, 256, 704, 448), ("low", zl, fm, zp + 160))   # the stairs down
        plan.paint((576, 448, 704, 512), ("low", zl, fm, zl + 160))
        plan.paint((384, 512, 896, 832), ("low", zl, fm, zl + 160))   # the main room
        plan.paint((320, 640, 384, 704), ("low", zl, fm, zl + 128))
        plan.paint((64, 576, 320, 832), ("low", zl, fm, zl + 160))    # west: the bunks
        plan.paint((896, 640, 960, 704), ("low", zl, fm, zl + 128))
        plan.paint((960, 576, 1216, 832), ("low", zl, fm, zl + 160))  # east: the generator and stores
        plan.paint((0, 640, 64, 704), ("low", zl, fm, zl + 128))      # a door in the bunk room's west wall...
        plan.paint((-320, 640, 0, 768), ("low", zd, fm, zl + 160))    # ...and the second stairs, down and west
        plan.walls()
        # the deep level: wholly under the ground (its top is 72 under the gate's floor), so nothing of it shows outside
        deep = Plan(origin, [(zd - 64, zd + 224, FMAT["bunker_wall"])], **look)
        deep.keep_out.append((-320, 576, 100000, 832))
        room = ("low", zd, fm, zd + 160)
        door = ("low", zd, fm, zd + 128)
        deep.paint((-448, 384, -320, 768), room)       # the foot of the stairs
        deep.paint((-1216, 384, -448, 512), room)      # the passage west
        deep.paint((-704, 512, -640, 576), door)
        deep.paint((-768, 576, -512, 832), room)       # north: the radio room
        deep.paint((-1088, 512, -1024, 576), door)
        deep.paint((-1152, 576, -896, 832), room)      # north: the armoury
        deep.paint((-704, 320, -640, 384), door)
        deep.paint((-768, 64, -512, 320), room)        # south: the sick bay
        deep.paint((-1088, 320, -1024, 384), door)
        deep.paint((-1152, 64, -896, 320), room)       # south: the stores
        deep.paint((-1280, 384, -1216, 448), door)
        deep.paint((-1600, 256, -1280, 576), room)     # the far end: the plant room
        deep.walls()
        self.plan, self.deep = plan, deep
        self.buildings.append((plan, self.B0, zd - 110))

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        # the mound the bunker is under: level with its roof, falling away on every side
        bx, by = self.B0
        mound = self.zp + 268 * (1 - smooth(rect_dist(x, y, (bx - 384, by + 448, bx + 1280, by + 1100)) / 400.0))
        h = max(h, mound)
        # flat at the door, as far as the door swings
        h = lerp(h, self.zp, 1 - smooth(rect_dist(x, y, (bx + 448, by - 340, bx + 832, by)) / 170.0))
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
        return 255 * (1 - smooth(rect_dist(x, y, (bx + 448, by - 300, bx + 832, by)) / 150.0))

    def bunker(self):
        v, plan, deep, zp, zl, zd = self.vmf, self.plan, self.deep, self.zp, self.zl, self.zd
        plan.build(v)
        deep.build(v)
        B, W, bx, by = plan.box, plan.world, self.B0[0], self.B0[1]
        vis, wall = self.vis("structures"), FMAT["bunker_wall"]
        # where the two parts meet: the stairwell is higher than the deep level's top, so a wall stands on that top
        v.world_box(B(-384, 576, zd + 224, -320, 832, zp + 272), wall, vis=vis)
        # both stairs: 15 steps north down to the first level, 23 steps west down to the deep one
        v.detail([B(576, 256 + 12 * k, zl, 704, 268 + 12 * k, zp - 8 * (k + 1)) for k in range(15)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(-12 * (k + 1), 640, zd, -12 * k, 768, zl - 8 * (k + 1)) for k in range(23)], wall, vis=vis, top=MAT["stairs"])
        self.door()
        # light: enough to find the way; the bunks and two of the deep rooms are left dark
        lights = ((640, 160, zp + 184, "255 225 190 90", "0"), (640, 672, zl + 136, "255 205 150 140", "0"), (1088, 704, zl + 136, "190 255 215 90", "10"),
                  (-160, 704, zl + 120, "255 215 170 60", "0"), (-384, 576, zd + 136, "255 200 150 90", "0"), (-832, 448, zd + 136, "255 190 140 70", "0"),
                  (-640, 704, zd + 136, "170 210 255 110", "0"), (-1440, 416, zd + 136, "255 90 60 120", "0"), (-640, 192, zd + 136, "235 255 235 80", "10"))
        for (u, w, z, colour, style) in lights:
            v.point("light", W(u, w, z), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": style}, self.vis("lights"))
        for (u, w, z) in ((640, 672, zl + 72), (-832, 448, zd + 72), (-1440, 416, zd + 72), (640, 160, zp + 72)):
            v.point("env_cubemap", W(u, w, z), {"cubemapsize": "0"}, vis)
        # what was left behind (every one compiled as a static prop; in the structures' visgroup)
        first = (
            ("models/props_forest/bunkbed.mdl", 130, 790, 90), ("models/props_forest/bunkbed.mdl", 250, 790, 90), ("models/props_forest/footlocker01_closed.mdl", 130, 612, 0),
            ("models/props_c17/lockers001a.mdl", 250, 606, 0), ("models/props_wasteland/controlroom_desk001a.mdl", 640, 790, 180),
            ("models/props_wasteland/controlroom_filecabinet002a.mdl", 850, 800, 180), ("models/props_c17/oildrum001.mdl", 430, 560, 15),
            ("models/props_junk/wood_crate001a.mdl", 440, 780, 20), ("models/props_junk/wood_crate001a.mdl", 500, 800, 65),
            ("models/props_outland/generator_static01a.mdl", 1090, 770, 90), ("models/props_forest/shelves.mdl", 1180, 760, 270),
            ("models/props_silo/barrelwarning.mdl", 1010, 620, 30), ("models/props_silo/barrelwarning.mdl", 1060, 612, 200),
        )
        below = (
            ("models/props_silo/desk_console1.mdl", -620, 796, 180), ("models/props_silo/silo_server_a.mdl", -735, 690, 90), ("models/props_silo/silo_server_b.mdl", -735, 770, 90),
            ("models/props_wasteland/controlroom_chair001a.mdl", -620, 730, 0), ("models/props_wasteland/controlroom_filecabinet001a.mdl", -545, 800, 180),
            ("models/props_c17/lockers001a.mdl", -1120, 680, 90), ("models/props_c17/lockers001a.mdl", -1120, 760, 90), ("models/props_lab/lockers.mdl", -990, 806, 180),
            ("models/props_junk/wood_crate002a.mdl", -940, 770, 30), ("models/props_junk/wood_crate001a.mdl", -945, 660, 75),
            ("models/props_wasteland/prison_bedframe001b.mdl", -730, 130, 90), ("models/props_wasteland/prison_bedframe001b.mdl", -560, 130, 90),
            ("models/props_c17/furnituretable002a.mdl", -560, 250, 0), ("models/props_wasteland/controlroom_storagecloset001a.mdl", -740, 250, 90),
            ("models/props_forest/shelves_wood.mdl", -1120, 120, 90), ("models/props_forest/shelves_wood.mdl", -1120, 230, 90), ("models/props_wasteland/kitchen_shelf002a.mdl", -930, 100, 270),
            ("models/props_silo/barrelwarning.mdl", -940, 270, 10), ("models/props_c17/oildrum001.mdl", -990, 100, 60), ("models/props_c17/canister01a.mdl", -940, 190, 0),
            ("models/props_outland/generator_static01a.mdl", -1500, 500, 0), ("models/props_silo/fuel_cask.mdl", -1540, 320, 0), ("models/props_silo/fuel_cask.mdl", -1440, 310, 40),
            ("models/props_silo/electricalbox01.mdl", -1340, 546, 180),
        )
        for rows, z in ((first, zl), (below, zd)):
            for model, u, w, yaw in rows:
                self.static(model, bx + u, by + w, z, yaw, "structures", fade=(-1, 0))
        for model, x, y, yaw in (("models/props_c17/concrete_barrier001a.mdl", bx + 380, by - 110, 80), ("models/props_c17/concrete_barrier001a.mdl", bx + 920, by - 130, 100),
                                 ("models/props_vehicles/truck001a.mdl", bx + 300, by - 360, 35)):
            self.static(model, x, y, self.natural(x, y), yaw, "structures")
        self.plan_nodes(plan, self.B0, skip=[(576, 256, 704, 448), (-320, 640, 0, 768)])
        self.plan_nodes(deep, self.B0)
        for (u, w, z) in ((640, 296, zp - 32), (640, 364, zp - 72), (640, 420, zp - 116), (-60, 704, zl - 40), (-150, 704, zl - 100), (-240, 704, zl - 160), (-300, 704, zd)):
            self.node(bx + u, by + w, z)
        # the bunker's rooms must be shut in on every side but the doorway (for the look of it, and for the door's areaportal):
        # with the doorway stopped up, air from inside must not reach the forest
        closed = flood(v, W(640, 160, zp + 64), [B(512, 0, zp, 768, 64, zp + 192)])
        if closed[0] is None or reaches(closed, self.w(self.W / 2, self.D / 2, self.lid - 100)):
            self.problems.append("the bunker's rooms are open to the hill somewhere other than the doorway")
        for u, w, z, what in ((640, 672, zl + 64, "main room"), (-384, 576, zd + 64, "foot of the second stairs"), (-1440, 416, zd + 64, "plant room"), (-640, 192, zd + 64, "sick bay")):
            if not reaches(closed, W(u, w, z)):
                self.problems.append("the bunker's %s can't be reached from its door" % what)
        # the deep level must stay under the ground
        cover = min(self.natural(bx + (i + 0.5) * CELL, by + (j + 0.5) * CELL) for (i, j) in deep.cells) - (zd + 224)
        if cover < 16:
            self.problems.append("the bunker's deep level comes within %d of the ground's surface" % cover)
        self.notes.append("the bunker: its door at (%d %d), floor z %d; 15 steps down to the first level (z %d: main room, bunks, generator room), 23 more down to the deep level "
                          "(z %d: a passage, radio room, armoury, sick bay, stores, plant room), which is at least %d under the ground; 9 lights" % (
                              self.ox + bx + 640, self.oy + by, zp, zl, zd, cover))

    def door(self):
        """The bunker's door: two steel leaves that slide out of the wall on either side and meet in the middle, as a missile
        silo's do (the owner: "why not just have 2 sliding bunker doors like a missile silo, that slide until they meet
        together?"). They stand open, drawn back into the wall with only their edges showing. A button inside shuts them
        (a klaxon, a red light, about five seconds of travel, a slam) and opens them again; nothing outside does.
        Each leaf is a func_button used as a mover (PressIn draws it back into the wall, PressOut slides it shut; read from
        the engine's own buttons.cpp: its travel is its width less its lip, and neither Use, touch nor a shot moves it): not a door to the
        gamemode, whose door rules (kicks, lockpicks, NPCs opening doors) apply to func_door, func_door_rotating,
        func_movelinear and prop_door_rotating, so only this wiring moves it. Nothing can use, touch or shoot a leaf to move it.
        If the bunker is left shut with nobody inside, it opens itself after twenty seconds."""
        v, plan, zp = self.vmf, self.plan, self.zp
        B, W = plan.box, plan.world
        vis, dv = self.vis("structures"), self.vis("bunker door (the leaves, the button, the wiring)")
        u1, u2 = self.DOOR
        mid, top = (u1 + u2) // 2, zp + 192
        half, lip = (u2 - u1) // 2, 8
        steel, rib = FMAT["door"], MAT["bars"]
        # a frame round the doorway outside, standing proud of the wall
        v.detail([B(u1 - 16, -8, zp, u1, 0, top), B(u2, -8, zp, u2 + 16, 0, top), B(u1 - 16, -8, top, u2 + 16, 0, top + 32)], MAT["beam"], vis=vis)
        # the two leaves, drawn as they stand when shut (so the light on them is worked out there, not inside the wall).
        # Pressed in, each is back in the wall on its own side with 8 of it still showing; the map presses them in as it starts.
        for side, name in ((-1, "west"), (1, "east")):
            a = u1 if side < 0 else mid                           # the leaf's west edge when shut
            edge = mid - lip if side < 0 else mid                 # its meeting edge: a thicker bar, all that is seen of it when open
            parts = [(B(a, 20, zp, a + half, 44, top), steel), (B(edge, 14, zp, edge + lip, 50, top), rib)]
            for z in (24, 92, 160):
                parts.append((B(a, 16, zp + z, a + half, 20, zp + z + 8), rib))
                parts.append((B(a, 44, zp + z, a + half, 48, zp + z + 8), rib))
            v.brush_entity("func_button", {
                "targetname": "lc_bunker_door", "movedir": "0 180 0" if side < 0 else "0 0 0", "speed": "26", "lip": lip, "wait": "-1", "spawnflags": "0",
                "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "min_use_angle": "0.8",
                "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, parts, steel, dv)
            # (open, a leaf must be inside the wall but for its edge: if the wall there is not solid it would show)
            lo, hi = (u1 - (half - lip), u1) if side < 0 else (u2, u2 + half - lip)
            for u in range(lo // CELL * CELL, hi, CELL):
                if plan.cells.get((u // CELL, 0), ("",))[0] != "solid":
                    self.problems.append("the bunker door's %s leaf has no wall to slide into at %d" % (name, u))
        v.point("logic_auto", W(mid, 200, zp + 150), {"spawnflags": "1"}, dv, connections=[("OnMapSpawn", "lc_bunker_door", "PressIn", "", 0.5)])
        # an areaportal across the doorway, behind the leaves: shut with them, so the bunker is not drawn from outside nor the forest from inside
        self.vmf.portals.append(B(u1, 54, zp, u2, 56, top))
        v.brush_entity("func_areaportal", {"targetname": "lc_bunker_portal", "StartOpen": "1", "PortalVersion": "1"}, [B(u1, 54, zp, u2, 56, top)], MAT["portal"], dv)

        # sounds, the red light, the shake
        def sound(name, message, at):
            v.point("ambient_generic", at, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": "2200", "spawnflags": "48",
                                            "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                            "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        at = W(mid, 32, zp + 96)
        sound("lc_bunker_alarm", "ambient/alarms/klaxon1.wav", W(mid, 100, zp + 170))
        sound("lc_bunker_move", "Streetwar.d3_c17_11_garage_move1", at)
        sound("lc_bunker_slam", "Streetwar.d3_c17_11_garage_stop1", at)
        sound("lc_bunker_groan", "ambient/materials/metal_stress4.wav", at)
        for pos in (W(mid, -28, zp + 240), W(mid, 150, zp + 190)):
            v.point("light", pos, {"targetname": "lc_bunker_light", "_light": "255 50 30 400", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                   "pattern": "zzzzzaaaaa", "style": "0"}, dv)
        v.point("env_shake", at, {"targetname": "lc_bunker_shake", "amplitude": "7", "radius": "900", "duration": "1.6", "frequency": "40", "spawnflags": "0"}, dv)
        # the wiring. Shutting: klaxon and light at once, the leaves start a second later and take about 4.6 s, then the slam.
        shut = [("OnTrigger", "lc_bunker_close", "Disable", "", 0), ("OnTrigger", "lc_bunker_alarm", "PlaySound", "", 0), ("OnTrigger", "lc_bunker_alarm", "PlaySound", "", 1.7),
                ("OnTrigger", "lc_bunker_alarm", "PlaySound", "", 3.4), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0),
                ("OnTrigger", "lc_bunker_door", "PressOut", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1),
                ("OnTrigger", "lc_bunker_move", "StopSound", "", 5.6), ("OnTrigger", "lc_bunker_slam", "PlaySound", "", 5.6), ("OnTrigger", "lc_bunker_groan", "PlaySound", "", 5.7),
                ("OnTrigger", "lc_bunker_shake", "StartShake", "", 5.6), ("OnTrigger", "lc_bunker_portal", "Close", "", 5.8),
                ("OnTrigger", "lc_bunker_light", "TurnOff", "", 8.5), ("OnTrigger", "lc_bunker_open", "Enable", "", 8)]
        unshut = [("OnTrigger", "lc_bunker_open", "Disable", "", 0), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0), ("OnTrigger", "lc_bunker_groan", "PlaySound", "", 0),
                  ("OnTrigger", "lc_bunker_portal", "Open", "", 0.9), ("OnTrigger", "lc_bunker_door", "PressIn", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1),
                  ("OnTrigger", "lc_bunker_move", "StopSound", "", 5.6), ("OnTrigger", "lc_bunker_slam", "PlaySound", "", 5.6), ("OnTrigger", "lc_bunker_light", "TurnOff", "", 7),
                  ("OnTrigger", "lc_bunker_close", "Enable", "", 8)]
        relay = W(mid, 200, zp + 120)
        v.point("logic_relay", relay, {"targetname": "lc_bunker_close", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=shut)
        v.point("logic_relay", (relay[0] + 16, relay[1], relay[2]), {"targetname": "lc_bunker_open", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=unshut)
        # the button: a red knob on a plate on the wall inside, west of the stairs; one press works whichever relay is live
        v.detail([B(480, 248, zp + 36, 552, 256, zp + 76)], MAT["bars"], vis=dv)
        v.brush_entity("func_button", {"targetname": "lc_bunker_button", "spawnflags": "1025", "wait": "9", "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "0",
                                       "health": "0", "rendercolor": "220 40 30", "rendermode": "0", "renderamt": "255", "min_use_angle": "0.8"},
                       [B(504, 240, zp + 44, 528, 248, zp + 68)], MAT["bars"], dv,
                       connections=[("OnPressed", "lc_bunker_close", "Trigger", "", 0), ("OnPressed", "lc_bunker_open", "Trigger", "", 0)])
        # nobody left inside and the door shut: it opens again (the unshutting relay is only live while it is shut)
        inside = []
        for p, skip in ((self.plan, (u1, 0, u2, 64)), (self.deep, None)):
            for x1, y1, x2, y2, spec in p.rectangles():
                if spec[0] != "solid" and not (skip and x1 >= skip[0] and x2 <= skip[2] and y1 >= skip[1] and y2 <= skip[3]):
                    inside.append(B(x1, y1, spec[1], x2, y2, spec[3]))
        v.brush_entity("trigger_multiple", {"targetname": "lc_bunker_inside", "spawnflags": "1", "wait": "1", "StartDisabled": "0"}, inside, MAT["trigger"],
                       self.vis("bunker door's failsafe (delete to let it stay shut when empty)"), connections=[("OnEndTouchAll", "lc_bunker_open", "Trigger", "", 20)])

    def preview_extra(self, dr, P):
        # the deep level, which is under the ground: drawn faintly, so the picture shows how far the bunker goes
        bx, by = self.B0
        for (i, j), spec in self.deep.cells.items():
            a, b = P(bx + i * CELL, by + (j + 1) * CELL), P(bx + (i + 1) * CELL, by + j * CELL)
            dr.rectangle((a[0], a[1], b[0], b[1]), fill=(150, 150, 156, 110) if spec[0] == "solid" else (30, 30, 36, 170))

    def pond(self):
        cx, cy, rx, ry = self.POND
        ix, iy, ir = self.ISLE
        rnd, n = self.rnd, 0
        # ferns and low shrubs round the shore (not the cattail model: it is made to be drawn at full brightness, and glows in the dark)
        for k in range(70):
            a = rnd.uniform(0, 6.283)
            for r in (1.04, 1.08, 1.12, 1.17):
                x, y = cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)
                h = self.natural(x, y)
                if self.level + 3 <= h <= self.level + 22:
                    self.static(rnd.choice(SHORE), x, y, h - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0, fade=(1500, 2000))
                    n += 1
                    break
        top = self.natural(ix, iy)
        self.static("models/props_foliage/tree_pine04.mdl", ix, iy, top - 8, 40, "trees")
        self.static("models/props_foliage/forestrock_single01.mdl", ix + 46, iy - 30, self.natural(ix + 46, iy - 30) - 8, 120, "rocks, plants and fallen wood")
        self.static("models/props_foliage/driftwood_01a.mdl", cx - rx * 0.86, cy + ry * 0.35, self.level - 2, 70, "rocks, plants and fallen wood")
        self.trees.append((ix, iy))
        self.vmf.point("env_cubemap", self.w(cx, cy - 200, self.level + 64), {"cubemapsize": "0"}, self.vis("water"))
        self.notes.append("the pond: about %d by %d, surface z %d, up to %d deep; the island's top is %d above the water; %d ferns and shrubs on the shore" % (
            2 * rx, 2 * ry, self.level, self.level - min(self.natural(cx + dx, cy + dy) for dx in (-200, 0, 200) for dy in (-150, 150)), top - self.level, n))


def forest_bunker(args):
    f = BunkerForest("forest (bunker, pond)", tuple(args.origin or (8064, 1088)), 400 if args.floor is None else args.floor, 31, args.first_node or 4400, ("west", 3072))
    f.test = bool(getattr(args, "test", False))
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
    CX, YM, LONG = 2304, 2560, 2816     # the mouth's middle, the hillside's line, how far in it goes
    # The bend (the owner: "it's a straight shot still; can it curve ... so a combine unit can't just slaughter everyone
    # inside if they are standing outside"): straight in for 768, then over the next 768 the passage moves 960 west, then
    # straight on. sight() measures how far a straight line from outside the mouth reaches; it must stop short of the chamber.
    BEND = (768, 1536, -960)
    CHAMBER = (1728, 2368)              # past the bend: the wide chamber the mine office is in
    OFFICE = (1792, 2304)               # the office's front, along the chamber's east wall (two of the skin's 256 pieces)
    FRONT, FRONT_HIGH = 256, 192        # that front: this far east of the chamber's middle, and this high
    SPRING = 2624                       # how far in the spring is: a low slot in the west wall the stream runs out of
    HALF, TALL = 160, 320               # the square the cave's skin is hung on
    TEAR = 640                          # the hillside is cut this far each side of the mouth

    def setup(self):
        z0 = self.z0
        self.zf = z0 + 30                # the cave's floor and the ground before it
        self.level = self.zf - 16        # the stream's surface
        cx, ym = self.CX, self.YM
        self.D = 5632                    # (1536 longer than a forest usually is: the cave runs on north under its hill)
        self.front_x = cx + self.BEND[2] + self.FRONT
        self.office_plan()
        # the spring: where the west wall meets the floor. The slot runs 140 back into the rock from the wall's lip.
        ys = ym + self.SPRING
        self.lip_theta = math.atan2(80 - self.TALL / 2.0, -self.HALF)
        lip = self.wall_x(self.lip_theta, ys)
        self.spring = (lip - 140, ys)
        self.sink = (3560, 1280)
        inside = [(self.stream_x(ym + q), ym + q) for q in range(self.SPRING - 200, 100, -150)]
        self.cave_line = [(lip - 130, ys), (lip + 30, ys)] + curve([(lip + 30, ys)] + inside + [(cx - 60, ym)])
        self.stream_line = self.cave_line + curve([(cx - 60, ym), (cx + 60, 2230), (cx - 160, 1860), (2520, 1520), (3080, 1390), self.sink])[1:]
        # the trail from the gate to the mouth (it fords the stream just before the cave)
        side, g = self.gate
        if side == "east":
            trail = [(self.W, g + GATE_WIDE / 2), (3576, g + GATE_WIDE / 2), (3000, 800), (2420, 1130), (2040, 1520)]
        else:
            trail = [(g + GATE_WIDE / 2, 0), (g + GATE_WIDE / 2, 520), (900, 1120), (1640, 1660)]
        self.trails.append(curve(trail + [(2100, 1890), (2390, 2280), (cx + 40, ym)]))
        self.clearings += [(cx, ym - 260, 330), (self.sink[0], self.sink[1], 200)]
        deep = 48
        seen = set()
        for (x, y) in self.stream_line + [(self.sink[0] + dx, self.sink[1] + dy) for dx in (-150, 150) for dy in (-150, 150)]:
            for dx in (-100, 100):
                for dy in (-100, 100):
                    key = (int((x + dx) // PATCH), int((y + dy) // PATCH))
                    if key not in seen and 0 <= key[0] < self.W // PATCH and 0 <= key[1] < self.D // PATCH:
                        seen.add(key)
                        self.waters.append((key[0] * PATCH, key[1] * PATCH, (key[0] + 1) * PATCH, (key[1] + 1) * PATCH, self.level, deep, FMAT["stream"]))
        self.wet_patches = seen
        r = self.office_rect
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1]:
                self.problems.append("the stream's water (the patch at %d %d) lies under the mine office" % (x1, y1))

    def office_plan(self):
        """The mine office (the owner: "a small mining office/shack on the inside ... a few rooms large; it still needs to be
        reasonably big enough for a small rebel base"): four rooms built into the rock behind the chamber's east wall. Its
        front is that wall: boards, a doorway 128 wide and a window each side. u runs east from the front, v north."""
        zf = self.zf
        wall, floor = FMAT["office_wall"], FMAT["office_floor"]
        self.office_at = (self.front_x, self.YM + self.OFFICE[0])       # in the forest's own coordinates
        plan = Plan((self.ox + self.office_at[0], self.oy + self.office_at[1]), [(zf - 64, zf + 224, wall)], floor_side=wall, ceiling=FMAT["office_ceiling"],
                    vis=self.vis("mine office"))
        plan.keep_out.append((-100000, -100000, 0, 100000))            # the cave: no wall is built out into it
        room, door = ("low", zf, floor, zf + 144), ("low", zf, floor, zf + 112)
        self.office_holes = [(0, 192, zf, 64, 320, zf + 128), (0, 64, zf + 48, 64, 128, zf + 112), (0, 384, zf + 48, 64, 448, zf + 112)]   # the doorway, the windows
        for (u1, v1, z1, u2, v2, z2) in self.office_holes:
            plan.paint((u1, v1, u2, v2), ("low", z1, floor if z1 == zf else FMAT["timber"], z2))
        plan.paint((64, 0, 448, 512), ("low", zf, floor, zf + 160))     # the front room: 384 by 512
        plan.paint((448, 64, 512, 128), door)
        plan.paint((512, 0, 832, 256), room)                            # east of it: the bunk room, 320 by 256...
        plan.paint((448, 384, 512, 448), door)
        plan.paint((512, 320, 832, 512), room)                          # ...and the store, 320 by 192
        plan.paint((320, 512, 384, 576), door)
        plan.paint((256, 576, 512, 768), room)                          # north of it: the back room (maps, the radio), 256 by 192
        plan.walls()
        self.office = plan
        ax, ay = self.office_at
        self.office_rect = (ax - 64, ay - 64, ax + 896, ay + 832)

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
        # the hill the cave is in (it follows the cave round its bend, and covers the mine office), and the gully cut into its face
        back = y > ym or (y == ym and bias is not None and bias[1] > ym)
        mid = self.mid(y) if back else cx
        away = abs(x - mid)
        if back:
            away = min(away, rect_dist(x, y, self.office_rect))
        side = 1 - smooth((away - self.TEAR - 150 * (0.5 + 0.5 * noise(y / 330.0, 1.5 if x > mid else 8.5, self.seed + 15))) / (420.0 + 160 * noise(y / 500.0, 4.5, self.seed + 16)))
        if back:
            hill = zf + (640 + 120 * smooth((y - ym) / 500.0) + 24 * noise(x / 300.0, y / 300.0, self.seed + 8)) * side
            return max(h, hill)
        ax = abs(x - cx)
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
        # the rock face's outer edge (67 points: it is buried in the hillside), the floor's front edge across the mouth
        # (7: it lies on the ground before the cave), and the edge of the hole the mine office's front fills (42: it is in
        # the front's own wall: 14 along the floor, 14 along the roof, 7 up each end)
        return 67 + 7 + 42

    def allowed_tears(self):
        return sum(1 for x in range(0, self.W + 1, STEP) if abs(x - self.CX) < self.TEAR and abs(self.natural(x, self.YM, (0, 0)) - self.natural(x, self.YM, (0, 9999))) > 0.01)

    def extra_dirt(self, x, y):
        a = 255 * (1 - smooth((self.stream_dist(x, y) - 40) / 70.0))
        if abs(x - self.CX) < 420 and 0 < self.YM - y < 520:
            a = max(a, 220)
        return a

    # --- the cave's skin ------------------------------------------------------

    def wander(self, y):
        """How far east of the mouth's middle the passage's middle is, y along it: none, then the bend, then all of it."""
        s1, s2, a = self.BEND
        return a * smooth((y - self.YM - s1) / float(s2 - s1))

    def mid(self, y):
        return self.CX + self.wander(y)

    def lean(self, y):
        """Where the passage runs aslant, its skin is hung this much wider across, so the passage itself keeps its width."""
        k = (self.wander(y + 4) - self.wander(y - 4)) / 8.0
        return math.sqrt(1 + k * k)

    def in_chamber(self, y):
        s = y - self.YM
        c1, c2 = self.CHAMBER
        return smooth((s - (c1 - 220)) / 220.0) * smooth((c2 + 220 - s) / 220.0)

    def stream_x(self, y):
        # (in the chamber the stream keeps to the west side: the floor before the office is dry)
        return self.mid(y) - 60 - 110 * self.in_chamber(y)

    def radius(self, y):
        s = y - self.YM
        s1, s2, a = self.BEND
        # narrower through the bend (that is what stops a line of sight), wide in the chamber, a little wider at the spring
        r = (190 - 30 * smooth(1 - abs(s - 300) / 200.0) - 30 * smooth((s - (s1 - 150)) / 150.0) * smooth((s2 + 150 - s) / 150.0)
             + 115 * self.in_chamber(y) + 40 * smooth(1 - abs(s - self.SPRING) / 220.0))
        return r * (1 - 0.35 * smooth((s - (self.LONG - 130)) / 130.0))

    def cave_floor(self, x, y):
        zf = self.zf
        carve = 24 * (1 - smooth((path_dist(x, y, self.cave_line) - 14) / 44.0))
        inner = zf + 5 * noise(x / 80.0, y / 80.0, self.seed + 11) - carve
        s = y - self.YM
        if s < 96:
            # at the mouth the cave's floor IS the ground before it, so there is no step or crack on the threshold
            return lerp(self.natural(x, self.YM, (0, 0)), inner, smooth(s / 96.0))
        return inner

    def wall_x(self, theta, y):
        R = self.radius(y)
        r = R * (1 + 0.2 * noise(math.cos(theta) * 1.6 + y / 170.0, math.sin(theta) * 1.6 - y / 230.0, self.seed + 12))
        return self.mid(y) + 1.15 * r * math.cos(theta) * self.lean(y)

    def ring(self, theta, y):
        """A point of the cave's skin: round the passage by theta, y along it."""
        s = y - self.YM
        R = self.radius(y)
        r = R * (1 + 0.2 * noise(math.cos(theta) * 1.6 + y / 170.0, math.sin(theta) * 1.6 - y / 230.0, self.seed + 12))
        x = self.mid(y) + 1.15 * r * math.cos(theta) * self.lean(y)
        z = self.zf + 0.51 * R + 0.85 * r * math.sin(theta)
        z = max(z, self.cave_floor(x, y))
        edge = smooth(s / 64.0) * smooth((self.LONG - s) / 64.0)
        return (x, y + 14 * edge * noise(theta * 2.0 + 3, y / 90.0, self.seed + 13), z)

    def on_square(self, xn, zn, y):
        """A point of the square the skin hangs on (xn across from the middle, zn up from the floor), moved onto the skin."""
        p = self.ring(math.atan2(zn - self.TALL / 2.0, xn), y)
        if xn == -self.HALF and zn <= 80:
            # the spring (the owner: "a little underground spring in the cave wall that is too short for the player to crouch
            # into"): the west wall's three lowest rows of points are pulled into a slot. The floor's edge goes to the slot's
            # back, low; the next row to the back, 30 higher; the third stays at the wall as the slot's lip. So the slot is
            # 140 deep and 30 from floor to roof at its mouth (a crouched player is 36), with the water standing 6 deep in it.
            w = smooth(1 - abs(y - (self.YM + self.SPRING)) / 72.0)
            if w > 0:
                lip = self.wall_x(self.lip_theta, y)
                zf = self.zf
                q = (lip, y, zf + 8) if zn == 80 else (lip - 140, y, zf + 8) if zn == 40 else (lip - 140, y, zf - 22)
                p = tuple(lerp(p[k], q[k], w) for k in range(3))
        if xn == self.HALF:
            # the mine office's front: along it the east wall's points lie flat, 6 inside the front's own wall, from the floor
            # to FRONT_HIGH. That piece of the skin is left out (the wall with its doorway and windows stands there), so the
            # floor's and the roof's edges and the rock at each end all end in that wall. Beyond each end the rock eases back
            # to its own shape over 128.
            a, b = self.YM + self.OFFICE[0], self.YM + self.OFFICE[1]
            out = max(a - y, 0, y - b)
            if out < 128:
                q = (self.front_x + 6, y if out == 0 else p[1], self.zf + zn * self.FRONT_HIGH / float(self.TALL))
                p = q if out == 0 else tuple(lerp(p[k], q[k], 1 - smooth(out / 128.0)) for k in range(3))
        return p

    def collar(self, xn, zn):
        """The rock face round the mouth: the skin's own edge at the mouth, easing out to a rough wall that leans back."""
        H, T = self.HALF, self.TALL
        qx, qz = max(-H, min(H, xn)), max(0, min(T, zn))
        d = math.hypot(xn - qx, zn - qz)
        px, py, pz = self.on_square(qx, qz, self.YM)
        near = (px + (xn - qx), py, pz + (zn - qz))
        sd = self.seed
        # big shapes, small shapes, and rough ledges across it (the owner: it was "just a repeating tiled cave texture")
        crag = (24 + 62 * noise(xn / 260.0, zn / 210.0, sd + 14) + 26 * noise(xn / 85.0, zn / 85.0, sd + 18)
                + 18 * math.sin(zn / 55.0 + 3 * noise(xn / 300.0, 0.5, sd + 19)))
        far = (self.CX + xn + 14 * noise(xn / 120.0, zn / 120.0, sd + 20), self.YM - crag + 0.15 * zn, self.zf + zn - (24 * smooth(d / 100.0) if zn == 0 else 0))
        w = smooth(d / 200.0)
        return tuple(lerp(near[k], far[k], w) for k in range(3))

    def sight(self):
        """How far into the cave a straight line from outside reaches, seen from above. Any such line crosses the mouth's own
        line, so every start along the mouth and every direction is tried, against the passage at its widest (its waist)."""
        ym, step = self.YM, 16
        n = self.LONG // step
        west = [min(self.ring(math.pi + t, ym + i * step)[0] for t in (-0.4, 0, 0.4)) for i in range(n + 1)]
        east = [max(self.ring(t, ym + i * step)[0] for t in (-0.4, 0, 0.4)) for i in range(n + 1)]
        best = 0
        x0 = west[0] + 4
        while x0 < east[0]:
            for k in range(-250, 251):
                for i in range(1, n + 1):
                    x = x0 + k / 100.0 * i * step
                    if x < west[i] or x > east[i]:
                        break
                    if i * step > best:
                        best = i * step
            x0 += 16
        return best

    def cave(self):
        v, cx, ym, zf, H, T = self.vmf, self.CX, self.YM, self.zf, self.HALF, self.TALL
        vis, mat, nd = self.vis("cave"), FMAT["cave"], MAT["nodraw"]
        W = lambda p: self.w(p[0], p[1], p[2])

        def dirt_of(p):
            # dirt on the floor, rock on the walls and roof
            return 235 * (1 - smooth((p[2] - self.cave_floor(p[0], p[1]) - 6) / 34.0))

        def face(box, name, point, mat=mat, tex=0.25, dirt=dirt_of):
            pts = {}

            def target(i, j):
                pts[(i, j)] = point(i, j)
                return W(pts[(i, j)])

            def alpha(i, j):
                return dirt(pts[(i, j)])
            v.world_box(self.box(*box), nd, vis=vis, faces={name: mat}, disp={name: (3, target, alpha)}, tex=tex)

        def cliff_dirt(p):
            # dirt in the hollows and along the ledges, rock on what stands out
            return 110 + 120 * noise(p[0] / 150.0, p[2] / 110.0, self.seed + 21) + 70 * smooth(1 - (p[2] - zf) / 90.0)

        def under(y):
            # (the pieces the skin hangs on follow the bend, a whole square at a time)
            return cx + int(round(self.wander(y) / 64.0)) * 64
        seg = 256
        o1, o2 = self.OFFICE
        for k in range(self.LONG // seg):
            y0 = ym + k * seg
            c = under(y0 + seg / 2)
            face((c - H, y0, zf - 16, c + H, y0 + seg, zf), "top", lambda i, j, y0=y0: self.on_square(-H + 40 * j, 0, y0 + 32 * i))
            face((c - H, y0, zf + T, c + H, y0 + seg, zf + T + 16), "bottom", lambda i, j, y0=y0: self.on_square(-H + 40 * i, T, y0 + 32 * j))
            face((c - H - 16, y0, zf, c - H, y0 + seg, zf + T), "east", lambda i, j, y0=y0: self.on_square(-H, 40 * i, y0 + 32 * j))
            if not o1 <= k * seg < o2:
                face((c + H, y0, zf, c + H + 16, y0 + seg, zf + T), "west", lambda i, j, y0=y0: self.on_square(H, 40 * j, y0 + 32 * i))
        # the far end: the skin drawn together into a rough dome
        yend = ym + self.LONG
        mid = (self.mid(yend), yend, zf + 0.51 * self.radius(yend))

        def dome(i, j):
            xn, zn = -H + 40 * j, 40 * i
            rho = max(abs(xn) / H, abs(zn - T / 2.0) / (T / 2.0))
            if rho < 0.001:
                p = (mid[0], mid[1] + 90, mid[2])
            else:
                edge = self.on_square(xn / rho, T / 2.0 + (zn - T / 2.0) / rho, yend)
                p = (lerp(mid[0], edge[0], rho), edge[1] + 90 * (1 - rho * rho), lerp(mid[2], edge[2], rho))
            return (p[0], p[1], max(p[2], self.cave_floor(p[0], yend)))
        c = under(yend)
        face((c - H, yend, zf, c + H, yend + 16, zf + T), "south", dome)
        # the rock face round the mouth: five pieces that share their edges with each other and with the cave's first ring
        for (x1, x2, z1, z2) in ((-608, -H, 0, T), (H, 608, 0, T), (-608, -H, T, 704), (-H, H, T, 704), (H, 608, T, 704)):
            face((cx + x1, ym - 16, zf + z1, cx + x2, ym, zf + z2), "south",
                 lambda i, j, x1=x1, x2=x2, z1=z1, z2=z2: self.collar(x1 + (x2 - x1) * j / 8.0, z1 + (z2 - z1) * i / 8.0), mat=FMAT["cliff"], tex=0.5, dirt=cliff_dirt)
        # light: daylight does the mouth; dim lights round the bend, more in the chamber, and the far end left to the spring's glow
        for (q, up, colour) in ((330, 150, "150 190 255 60"), (760, 130, "255 190 120 60"), (1180, 120, "255 180 110 50"), (1640, 170, "255 190 130 90"),
                                (2048, 250, "255 200 150 170"), (2600, 110, "140 180 255 50")):
            y = ym + q
            v.point("light", self.w(self.mid(y), y, zf + up), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        for q in (1150, 2048):
            v.point("env_cubemap", self.w(self.mid(ym + q), ym + q, zf + 80), {"cubemapsize": "0"}, vis)
        # hanging rock in the bend and the chamber (there, over its west half: the roof comes down to the office's front on the east), fallen rock along the walls
        rnd = self.rnd
        for (q1, q2, n, t1, t2) in ((900, 1450, 6, 1.1, 2.0), (1760, 2340, 10, 1.6, 2.3)):
            for k in range(n):
                y = ym + rnd.uniform(q1, q2)
                p = self.ring(rnd.uniform(t1, t2), y)
                self.static("models/props_mining/stalactite_static0%d.mdl" % rnd.choice((1, 2)), p[0], p[1], p[2] - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        for (q, side) in ((200, 1), (520, -1), (900, 1), (1250, -1), (1630, 1), (1900, -1), (2200, -1), (2480, 1), (2700, -1)):
            y = ym + q
            p = self.ring(-0.5 if side > 0 else math.pi + 0.5, y)
            self.static("models/props_mining/caverocks_cluster0%d.mdl" % rnd.choice((1, 2)), p[0] - 30 * side, p[1], self.cave_floor(p[0] - 30 * side, p[1]) - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        # the rock face, dressed: boulders heaped along its foot and against it, ferns and bushes among them
        dress = ((-300, 70, "models/cliffs/rocks_medium01.mdl"), (290, 60, "models/cliffs/rockcluster01.mdl"), (-520, 80, "models/cliffs/rocks_large01.mdl"),
                 (500, 70, "models/cliffs/rockcluster02.mdl"), (-410, 130, "models/props_foliage/forestrock_cluster01.mdl"), (380, 140, "models/props_foliage/forestrock_cluster02.mdl"),
                 (-250, 150, "models/props_foliage/forestrock_single01.mdl"), (255, 170, "models/props_wasteland/rockgranite02a.mdl"), (-600, 150, "models/cliffs/rocks_large02.mdl"),
                 (610, 130, "models/cliffs/rocks_large03.mdl"))
        for (dx, out, model) in dress:
            x, y = cx + dx, ym - out
            self.static(model, x, y, self.natural(x, y) - 14, rnd.randrange(0, 360, 15), "cave")
        for k in range(16):
            dx = rnd.choice((-1, 1)) * rnd.uniform(235, 640)
            x, y = cx + dx, ym - rnd.uniform(40, 190)
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "cave", solid=0, fade=(1500, 2000))
        self.fence_gate()
        self.mine_office()
        for q in range(64, self.LONG - 100, 192):
            y = ym + q
            x = self.mid(y) + 70
            self.node(x, y, self.cave_floor(x, y))
        tall = max(self.ring(math.pi / 2, ym + q)[2] for q in range(0, self.LONG, 32)) - zf
        mouth_w = self.ring(0, ym)[0] - self.ring(math.pi, ym)[0]
        mouth_h = self.ring(math.pi / 2, ym)[2] - zf
        cover = 1e9
        for q in range(0, self.LONG, 32):
            for t in (0.5, 1.0, math.pi / 2, math.pi - 1.0, math.pi - 0.5):
                p = self.ring(t, ym + q)
                cover = min(cover, self.natural(p[0], p[1], (0, 9999)) - p[2])
        if cover < 40:
            self.problems.append("the cave's roof comes within %d of the hill's surface" % cover)
        far = self.sight()
        if far > self.CHAMBER[0] - 128:
            self.problems.append("a straight line from outside the mouth reaches %d into the cave: into the chamber, which starts at %d" % (far, self.CHAMBER[0]))
        ys = ym + self.SPRING
        lip, back_top, back_low = self.on_square(-H, 80, ys), self.on_square(-H, 40, ys), self.on_square(-H, 0, ys)
        slot_high = lip[2] - back_low[2]
        if slot_high > 34:
            self.problems.append("the spring's slot is %d high: a crouched player (36) could get in" % slot_high)
        s1, s2, a = self.BEND
        self.notes.append("the cave: its mouth at (%d %d), floor z %d, about %d wide and %d high; it runs %d north, then bends %d %s over the next %d, then %d more north "
                          "(%d in all, up to %d high); at least %d of hill over its roof" % (
                              self.ox + cx, self.oy + ym, zf, mouth_w, mouth_h, s1, abs(a), "west" if a < 0 else "east", s2 - s1, self.LONG - s2, self.LONG, tall, cover))
        self.notes.append("line of sight: a straight line from anywhere outside the mouth reaches at most %d in; the chamber and the mine office begin %d in" % (far, self.CHAMBER[0]))
        self.notes.append("the spring: a slot in the west wall at (%d %d), %d deep and %d from floor to roof (a crouched player is 36), the water %d deep in it" % (
            self.ox + lip[0], self.oy + ys, lip[0] - back_top[0], slot_high, self.level - back_low[2]))
        self.notes.append("the stream: surface z %d, from the spring, down the cave, out of the mouth, to a sink pool at (%d %d); a trail fords it" % (
            self.level, self.ox + self.sink[0], self.oy + self.sink[1]))

    def mine_office(self):
        v, zf, plan = self.vmf, self.zf, self.office
        ax, ay = self.office_at
        B, PW = plan.box, plan.world
        ov = self.vis("mine office")
        plan.build(v)
        # timber round the doorway and the windows, standing 8 proud of the boards
        tm = FMAT["timber"]
        v.detail([B(-8, 180, zf, 0, 192, zf + 140), B(-8, 320, zf, 0, 332, zf + 140), B(-8, 180, zf + 128, 0, 332, zf + 140)], tm, vis=ov)
        for v1 in (64, 384):
            v.detail([B(-6, v1 - 8, zf + 40, 0, v1 + 72, zf + 48), B(-6, v1 - 8, zf + 112, 0, v1 + 72, zf + 120)], tm, vis=ov)
        # an areaportal in the doorway and in each window: the rooms are drawn from the cave (and the cave from the rooms) only through them
        for (u1, v1, z1, u2, v2, z2) in self.office_holes:
            v.areaportal(B(30, v1, z1, 32, v2, z2), self.vis("areaportals"))
        # light: a lamp over the door outside, one in each room (the bunk room dim)
        for (u, w, up, colour) in ((-60, 256, 176, "255 205 150 130"), (256, 256, 148, "255 214 170 160"), (672, 128, 130, "255 200 150 50"),
                                   (672, 416, 130, "225 235 255 80"), (384, 672, 130, "255 190 130 100")):
            v.point("light", PW(u, w, zf + up), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("env_cubemap", PW(256, 256, zf + 72), {"cubemapsize": "0"}, ov)
        # what is in it (every one compiled as a static prop)
        things = (
            ("models/props_wasteland/controlroom_desk001a.mdl", 406, 250, 90), ("models/props_wasteland/controlroom_chair001a.mdl", 345, 250, 270),
            ("models/props_wasteland/controlroom_filecabinet002a.mdl", 400, 480, 180), ("models/props_c17/furnituretable002a.mdl", 170, 410, 0),
            ("models/props_forest/stove01.mdl", 112, 474, 0), ("models/props_c17/lockers001a.mdl", 300, 30, 0), ("models/props_junk/wood_crate001a.mdl", 110, 50, 20),
            ("models/props_forest/bunkbed.mdl", 600, 214, 90), ("models/props_forest/bunkbed.mdl", 730, 214, 90), ("models/props_forest/footlocker01_closed.mdl", 600, 40, 0),
            ("models/props_forest/footlocker01_closed.mdl", 730, 40, 0),
            ("models/props_forest/shelves_wood.mdl", 800, 372, 270), ("models/props_forest/shelves_wood.mdl", 800, 460, 270), ("models/props_junk/wood_crate001a.mdl", 560, 470, 20),
            ("models/props_junk/wood_crate001a.mdl", 630, 478, 65), ("models/props_junk/wood_crate002a.mdl", 590, 368, 30), ("models/props_c17/oildrum001.mdl", 700, 350, 15),
            ("models/props_c17/furnituretable002a.mdl", 384, 716, 0), ("models/props_wasteland/controlroom_chair001a.mdl", 384, 660, 0),
            ("models/props_wasteland/kitchen_shelf002a.mdl", 478, 640, 270),
        )
        for model, u, w, yaw in things:
            self.static(model, ax + u, ay + w, zf, yaw, "mine office", fade=(-1, 0))
        # left outside it in the chamber: a cart, cut timber
        for model, x, y, yaw in (("models/props_mining/flatbed_cart01.mdl", ax - 130, ay - 150, 80), ("models/props_mining/wood_stack.mdl", ax - 120, ay + 600, 10)):
            self.static(model, x, y, self.cave_floor(x, y), yaw, "mine office", fade=(-1, 0))
        self.plan_nodes(plan, self.office_at)
        self.node(ax + 32, ay + 256, zf)
        self.node(ax - 90, ay + 256, zf)
        # the rooms must be shut in but for the doorway and the windows; every room reached from the door; the hill over all of
        # it; and none of the cave's skin in a room's air
        stops = [B(*hole) for hole in self.office_holes]
        closed = flood(v, PW(256, 256, zf + 64), stops)
        if closed[0] is None or reaches(closed, self.w(self.W / 2, 600, self.lid - 100)):
            self.problems.append("the mine office is open to the hill somewhere other than its doorway and windows")
        for u, w, what in ((672, 128, "bunk room"), (672, 416, "store"), (384, 672, "back room")):
            if not reaches(closed, PW(u, w, zf + 64)):
                self.problems.append("the mine office's %s can't be reached from its front room" % what)
        cover = min(self.natural(ax + (i + 0.5) * CELL, ay + (j + 0.5) * CELL, (0, 9999)) for (i, j) in plan.cells) - (zf + 224)
        if cover < 40:
            self.problems.append("the mine office's roof comes within %d of the hill's surface" % cover)
        poking = 0
        for m in v.disp_made:
            if m[0] != self.vis("cave"):
                continue
            for pt in m[1]:
                u, w = pt[0] - self.ox - ax, pt[1] - self.oy - ay
                spec = plan.cells.get((int(u // CELL), int(w // CELL)))
                if spec and spec[0] != "solid" and spec[1] + 2 < pt[2] < spec[3] - 2 and u > 8:
                    poking += 1
        if poking:
            self.problems.append("%d points of the cave's skin are inside the mine office's rooms" % poking)
        self.notes.append("the mine office: its front along the chamber's east wall from (%d %d) to (%d %d), floor z %d; a doorway 128 wide and two windows; "
                          "a front room 384 by 512, a bunk room 320 by 256, a store 320 by 192 and a back room 256 by 192; at least %d of hill over its roof" % (
                              self.ox + ax, self.oy + ay, self.ox + ax, self.oy + ay + self.OFFICE[1] - self.OFFICE[0], zf, cover))

    def fence_gate(self):
        """A chain link fence across the cave, 48 inside its mouth, with a gate in it that opens and shuts as any door does
        (a func_door_rotating: press Use on it; to the gamemode it is a door like any other). The fence is a flat sheet wider and
        higher than the passage, so its edges are in the rock all the way round; the stream runs under it in its bed."""
        v, cx, ym, zf = self.vmf, self.CX, self.YM, self.zf
        gv = self.vis("cave gate and fence")
        nd, chain, bar = MAT["nodraw"], MAT["fence"], MAT["bars"]
        y1, y2 = ym + 47, ym + 49
        thin = {"west": nd, "east": nd, "top": nd, "bottom": nd}
        g1, g2 = cx + 16, cx + 128          # the gateway, on the dry side of the stream
        v.detail([self.box(cx - 256, y1, zf - 16, g1, y2, zf + 272), self.box(g2, y1, zf - 16, cx + 256, y2, zf + 272), self.box(g1, y1, zf + 136, g2, y2, zf + 272)],
                 chain, vis=gv, faces=thin)
        v.detail([self.box(g1 - 8, ym + 44, zf - 16, g1, ym + 52, zf + 144), self.box(g2, ym + 44, zf - 16, g2 + 8, ym + 52, zf + 144),
                  self.box(g1 - 8, ym + 44, zf + 136, g2 + 8, ym + 52, zf + 144)], bar, vis=gv)
        leaf = [(self.box(g1 + 2, y1, zf + 8, g2 - 2, y2, zf + 132), thin),
                (self.box(g1 + 2, ym + 46, zf + 8, g1 + 6, ym + 50, zf + 132), bar), (self.box(g2 - 6, ym + 46, zf + 8, g2 - 2, ym + 50, zf + 132), bar),
                (self.box(g1 + 2, ym + 46, zf + 128, g2 - 2, ym + 50, zf + 132), bar), (self.box(g1 + 2, ym + 46, zf + 8, g2 - 2, ym + 50, zf + 12), bar)]
        v.brush_entity("func_door_rotating", {
            "targetname": "lc_cave_gate", "origin": "%d %d %d" % self.w(g1 + 2, ym + 48, zf + 70), "distance": "90", "speed": "100", "wait": "-1", "lip": "0", "dmg": "0",
            "forceclosed": "0", "solidbsp": "0", "spawnflags": "288", "noise1": "doors/gate_move1.wav", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
            "disableshadows": "1"}, leaf, chain, gv)

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
        ax, ay = self.office_at
        for x1, y1, x2, y2, spec in self.office.rectangles():
            if spec[0] != "solid":
                dr.polygon([P(ax + x1, ay + y1), P(ax + x2, ay + y1), P(ax + x2, ay + y2), P(ax + x1, ay + y2)], fill=(120, 90, 50, 200), outline=(255, 255, 255, 200))

    def cave_picture(self, path):
        """The mouth seen from the front, and the passage seen from the side: is the skin a sane shape?"""
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            return
        img = Image.new("RGB", (1620, 620), (16, 16, 20))
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
            return (760 + (y - ym + 500) * 0.25, 440 - (z - zf) * 0.25)
        for th, col in ((math.pi / 2, (255, 200, 60)), (-math.pi / 2, (255, 200, 60))):
            dr.line([S(ym + s, self.ring(th, ym + s)[2]) for s in range(0, self.LONG + 1, 16)], fill=col, width=2)
        dr.line([S(ym + s, self.natural(self.mid(ym + s), ym + s, (0, 9999))) for s in range(0, self.LONG + 1, 16)], fill=(90, 200, 90), width=2)
        dr.line([S(ym - s, self.natural(cx, ym - s, (0, 0))) for s in range(0, 500, 16)], fill=(90, 200, 90), width=2)
        dr.line((S(ym - 500, self.level), S(ym + self.SPRING, self.level)), fill=(70, 130, 220))
        dr.text((760, 30), "the passage from the side, along its middle (south on the left): yellow its roof and floor, green the ground and the hill over it", fill=(230, 230, 230))
        img.save(path)
        print("  picture: " + path)


def forest_cave(args):
    # (west of the ring's west run: the far side of the city from the bunker forest. The owner: "can they be on opposite sides
    #  of the canal? that way if one is attacked, it's quite a long distance to reach the other")
    floor = 584 if args.floor is None else args.floor
    f = CaveForest("forest (cave, stream)", tuple(args.origin or (-9280, 4608)), floor, 47, args.first_node or 4600, ("east", 256))
    f.test = bool(getattr(args, "test", False))
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
