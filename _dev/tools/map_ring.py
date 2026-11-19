#!/usr/bin/env python3
"""
Living City: the canal round the north of the city (run it through map_build.py)

The owner, 19 November: "can we now make a canal that would go all the way around the city and
still meet up at the two aforementioned points out of the city? can you make it scale/fit
perfectly?" The two points are two roads' ends: the east one, where the first canal starts
(brush 15074), and the west one (brush 14734: the skybox brush 16 x 640 x 1504 at -2616 2240 1584).

    python3 map_build.py ring            lc_ring.vmf
    python3 map_build.py ring --test     lc_ring_test.vmf, to compile and walk by itself

This piece starts at the first canal's north gate (5888..6400, 5696), runs north, west along the
top of the city (with a jog south, to break the long view), down its west side, and in to the
west road's end, where it has a quay, stairs and a footbridge like the east one's. About 20,000
units of canal. Everything is in the map's own coordinates (this piece's origin is 0 0).

The west road is 184 higher than the east one (z 840 against 656). The canal's floor does NOT
climb for it (the first try had a weir of steps: the owner, "there would not be stairs at the
bottom of a canal ... make the lower end have a raised platform/entrance with stairs like the
other end already does. That way there is no need to correct for elevation in the canal itself").
The floor is z 400 all the way round; the west platform is simply 440 over it (54 steps), where
the east one, the first canal's, is 256. What climbs is the ground beside the canal, so the
walls' concrete ends 128 over it: z 784 in the east, 968 in the west, in eight steps of 23 that
each cross a straight run. Above the concrete there is no brick now but a chain link fence
against the sky (the owner: "make the canal walls a bit higher instead of using brickwork at the
top, and then put fencing along the boundary").

The owner removes brush 14734 (the sky wall at the west road's end) and 15630 (the invisible
wall before it). That brush is 16 thick and off the 64 grid, so the piece carries a 16-unit
strip in its place (floor, side walls, lid) and, above its own sky, the sky the road sees.

It has a gate in the west wall of its west run, for the cave forest (which sits out there, on
the far side of the city from the bunker forest: map_forest.py's default), and takes the first
canal's dressing: banks, mud, wall trim, drain stubs, bars nobody fits between. In its long
stretches stand set pieces (ring(), "things in the long stretches"): streets carried over,
a fallen bridge to walk under, a goods wagon, containers, wrecks, a camp.
"""

import random

from map_build import CELL, GATE_HIGH, MAT, Plan, Vmf, barred, check, gate_cap, octagon, prism, test_extras
from map_forest import noise

BANK = 128


class Channel:
    """One stretch of canal at one height: what dresses it. plan: its squares; floor_z: its floor; rim_z: its wall's top."""

    def __init__(self, vmf, plan, floor_z, rim_z, vis):
        self.vmf, self.plan, self.cells = vmf, plan, plan.cells
        self.floor_z, self.rim_z, self.vis = floor_z, rim_z, vis
        self.stats = {"banks": 0, "fills": 0, "ribs": 0, "stubs": 0, "mud": 0, "nodes": 0}

    def kind(self, c):
        spec = self.cells.get(c)
        if spec is None or spec[0] == "solid" or spec[1] > self.floor_z:
            return "wall"      # (a quay or a doorway is higher ground: a wall from down here)
        return "floor" if spec[0] == "open" else "gap"   # (gap: a culvert, level with the floor: an opening, no bank)

    def wall_near(self, x, y):
        best = 9999
        for di in range(-3, 3):
            for dj in range(-3, 3):
                c = (x // CELL + di, y // CELL + dj)
                if self.kind(c) != "floor" and self.cells.get(c, ("solid",))[0] != "low":
                    cx, cy = c[0] * CELL, c[1] * CELL
                    best = min(best, max(cx - x, 0, x - (cx + CELL)) + max(cy - y, 0, y - (cy + CELL)))
        return best

    def dress(self, no_bank, taken):
        """Banks along every wall (with a quarter pyramid where a wall's corner sticks out), a lip along the walls' tops,
        a rib every 512, a drain stub between ribs. no_bank: rectangles the banks stay out of. taken: boxes already on
        the walls: nothing is put within 24 units of them (and what is put is added to them)."""
        vmf, cells, kind, fz, rz = self.vmf, self.cells, self.kind, self.floor_z, self.rim_z

        def clear(x1, y1, x2, y2):
            return not any(x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1] for r in no_bank)

        def fits(box, gap=24):
            return not any(box[0] < t[3] + gap and box[3] > t[0] - gap and box[1] < t[4] + gap and box[4] > t[1] - gap
                           and box[2] < t[5] + gap and box[5] > t[2] - gap for t in taken)
        runs = {}
        for (i, j) in list(cells):
            if kind((i, j)) != "floor":
                continue
            x, y = i * CELL, j * CELL
            for (di, dj, key, a) in ((0, -1, ("x", y, 1), x), (0, 1, ("x", y + CELL, -1), x), (-1, 0, ("y", x, 1), y), (1, 0, ("y", x + CELL, -1), y)):
                if kind((i + di, j + dj)) == "wall":
                    solid = cells.get((i + di, j + dj), ("solid",))[0] == "solid"
                    edge = (a, key[1] - 8, a + CELL, key[1] + 8) if key[0] == "x" else (key[1] - 8, a, key[1] + 8, a + CELL)
                    runs.setdefault(key, []).append((a, solid, clear(*edge)))
        banks, trims = [], []
        for (axis, line, side), parts in sorted(runs.items()):
            parts.sort()
            for want, out in ((lambda p: p[2], banks), (lambda p: p[1] and p[2], trims)):
                start = prev = None
                for a, solid, free in parts + [(None, False, False)]:
                    ok = a is not None and want((a, solid, free))
                    if ok and start is not None and a == prev + CELL:
                        prev = a
                        continue
                    if start is not None:
                        out.append((axis, line, side, start, prev + CELL))
                    start = prev = a if ok else None
        m, shapes, boxes = MAT["canal_wall"], [], []
        for (axis, line, side, a, b) in banks:
            shapes.append(prism([(line, fz), (line + side * BANK, fz), (line, fz + BANK)], axis, a, b, m))
        self.stats["banks"] += len(banks)
        for (i, j) in list(cells):
            for (dx, dy) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
                if kind((i, j)) == "wall" and kind((i + dx, j)) == "floor" and kind((i, j + dy)) == "floor" and kind((i + dx, j + dy)) == "floor":
                    vx, vy = (i + (1 if dx > 0 else 0)) * CELL, (j + (1 if dy > 0 else 0)) * CELL
                    if not (clear(vx - 8, vy - 8, vx + 8, vy + 8) and clear(min(vx + dx * 8, vx + dx * 72), vy - 8, max(vx + dx * 8, vx + dx * 72), vy + 8)
                            and clear(vx - 8, min(vy + dy * 8, vy + dy * 72), vx + 8, max(vy + dy * 8, vy + dy * 72))):
                        continue
                    v0, apex = (vx, vy, fz), (vx, vy, fz + BANK)
                    px, py, pd = (vx + dx * BANK, vy, fz), (vx, vy + dy * BANK, fz), (vx + dx * BANK, vy + dy * BANK, fz)
                    shapes.append([([v0, px, pd, py], m), ([v0, px, apex], m), ([v0, py, apex], m), ([apex, px, pd], m), ([apex, py, pd], m)])
                    self.stats["fills"] += 1

        def along(axis, a, b, lo, hi, z1, z2):
            return (a, lo, z1, b, hi, z2) if axis == "x" else (lo, a, z1, hi, b, z2)
        for (axis, line, side, a, b) in trims:
            boxes.append(along(axis, a, b, min(line, line + side * 16), max(line, line + side * 16), rz, rz + 16))
            for at in range(a + 256, b - 128, 512):
                rib = along(axis, at - 24, at + 24, min(line, line + side * 24), max(line, line + side * 24), fz + 96, rz)
                if fits(rib):
                    boxes.append(rib)
                    taken.append(rib)
                    self.stats["ribs"] += 1
        for (axis, line, side, a, b) in trims:
            for at in range(a + 512, b - 128, 1024):
                z = fz + 176
                stub = along(axis, at - 24, at + 24, min(line, line + side * 40), max(line, line + side * 40), z - 24, z + 24)
                if not fits(stub):
                    continue
                taken.append(stub)
                shapes.append(prism(octagon(at, z, 24), "y" if axis == "x" else "x", min(line, line + side * 40), max(line, line + side * 40), MAT["bars"], MAT["black"]))
                self.stats["stubs"] += 1
        if shapes:
            vmf.detail_shapes(shapes, self.vis + ": banks, pipes and trim")
        if boxes:
            vmf.detail(boxes, MAT["beam"], vis=self.vis + ": banks, pipes and trim")

    def pipes(self, axis, at, a, b, taken):
        """A big pipe and a small one across the canal at `at` (axis: the way the canal runs there), on saddles at each wall (a, b)."""
        fz, rz = self.floor_z, self.rim_z
        across = "y" if axis == "x" else "x"
        shapes = [prism(octagon(at, fz + 192, 40), across, a, b, MAT["bars"], MAT["black"]), prism(octagon(at + 88, fz + 228, 16), across, a, b, MAT["bars"], MAT["black"])]
        if axis == "x":
            saddles = [(at - 56, a, fz + 128, at + 120, a + 32, rz), (at - 56, b - 32, fz + 128, at + 120, b, rz)]
        else:
            saddles = [(a, at - 56, fz + 128, a + 32, at + 120, rz), (b - 32, at - 56, fz + 128, b, at + 120, rz)]
        self.vmf.detail_shapes(shapes, self.vis + ": banks, pipes and trim")
        self.vmf.detail(saddles, MAT["beam"], vis=self.vis + ": banks, pipes and trim")
        taken += saddles

    def mud(self, seed, skip=()):
        """Mud and silt: a second, displaced skin over the floor; mud where it rises above the concrete."""
        cells, fz = self.cells, self.floor_z
        for (bi, bj) in sorted(set((i // 4, j // 4) for (i, j) in cells if self.kind((i, j)) in ("floor", "gap"))):
            x0, y0 = bi * 256, bj * 256
            if any(x0 < r[2] and x0 + 256 > r[0] and y0 < r[3] and y0 + 256 > r[1] for r in skip):
                continue
            grid, shown = {}, False
            for i in range(5):
                for j in range(5):
                    x, y = x0 + j * CELL, y0 + i * CELL
                    d = self.wall_near(x, y)
                    if d < BANK:
                        h = -16.0
                    else:
                        h = -7 + 17 * noise(x / 170.0, y / 170.0, seed) + 9 * noise(x / 60.0, y / 60.0, seed + 1) + (9 if d == BANK else 0)
                        shown = shown or h > 0
                    grid[(i, j)] = (fz + h, 128 + 127 * noise(x / 110.0, y / 110.0, seed + 2))
            if not shown:
                continue
            self.vmf.world_box((x0, y0, fz, x0 + 256, y0 + 256, fz + 8), MAT["nodraw"], top=MAT["mud"], vis=self.vis + ": mud",
                               disp={"top": (2, lambda i, j, g=grid, x0=x0, y0=y0: (x0 + j * CELL, y0 + i * CELL, g[(i, j)][0]), lambda i, j, g=grid: g[(i, j)][1])})
            self.stats["mud"] += 1

    def nodes(self, node, blocked):
        for (i, j), spec in sorted(self.cells.items()):
            if spec[0] == "solid" or i % 2 != 1 or j % 2 != 1 or (i + j) % 4 != 0:
                continue
            x, y = i * CELL + 32, j * CELL + 32
            if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in blocked):
                continue
            if self.kind((i, j)) == "floor" and self.wall_near(x, y) < BANK + 16:
                continue
            node(x, y, spec[1])
            self.stats["nodes"] += 1


class RingPlan(Plan):
    """The ring's squares: one floor all the way round, but the concrete of its walls ends higher the further west a square
    is (top_of(x, y)), with the sky above that. A "low" square carries its own top as a fifth value."""

    def __init__(self, base, sky, top_of, vis):
        Plan.__init__(self, (0, 0), [(base, sky + 16, MAT["canal_wall"])], sky=sky, vis=vis)
        self.top_of = top_of

    def low(self, rect, floor, mat, ceiling):
        self.paint(rect, ("low", floor, mat, ceiling, self.top_of(rect[0], rect[1])))

    def walls(self):
        Plan.walls(self)
        for c, spec in list(self.cells.items()):
            if spec[0] == "solid":
                self.cells[c] = ("solid", self.top_of(c[0] * CELL, c[1] * CELL))

    def build(self, vmf):
        self.walls()
        cw, sky = MAT["canal_wall"], MAT["sky"]
        for x1, y1, x2, y2, spec in self.rectangles():
            if spec[0] == "solid":
                vmf.world_box(self.box(x1, y1, self.base, x2, y2, spec[1]), cw, vis=self.vis)
                vmf.world_box(self.box(x1, y1, spec[1], x2, y2, self.top), sky, vis=self.vis)
                continue
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, spec[1]), self.floor_side, top=spec[2], vis=self.vis)
            if spec[0] == "open":
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), sky, sky, sky, vis=self.vis)
            else:
                vmf.world_box(self.box(x1, y1, spec[3], x2, y2, spec[4]), cw, bottom=self.ceiling, vis=self.vis)
                vmf.world_box(self.box(x1, y1, spec[4], x2, y2, self.top), sky, vis=self.vis)


def fence(vmf, plan, high, vis):
    """Chain link along the top of every wall that looks onto the canal (the owner: "put fencing along the boundary at the
    top of the canal walls"): a sheet standing 2 out from the wall's face, from the concrete's top up, with a rail and posts."""
    cells = plan.cells
    runs = {}
    for (i, j), spec in cells.items():
        if spec[0] != "open":
            continue
        x, y = i * CELL, j * CELL
        for (di, dj, axis, line, side, a) in ((0, -1, "x", y, 1, x), (0, 1, "x", y + CELL, -1, x), (-1, 0, "y", x, 1, y), (1, 0, "y", x + CELL, -1, y)):
            nb = cells.get((i + di, j + dj))
            if nb is None or nb[0] == "open":
                continue
            runs.setdefault((axis, line, side, nb[1] if nb[0] == "solid" else nb[4]), []).append(a)
    sheets, bars = {"x": [], "y": []}, []

    def along(axis, a, b, lo, hi, z1, z2):
        return (a, lo, z1, b, hi, z2) if axis == "x" else (lo, a, z1, hi, b, z2)
    for (axis, line, side, top), parts in sorted(runs.items()):
        parts.sort()
        start = prev = None
        for a in parts + [None]:
            if a is not None and start is not None and a == prev + CELL:
                prev = a
                continue
            if start is not None:
                b = prev + CELL
                sheets[axis].append(along(axis, start, b, min(line, line + 2 * side), max(line, line + 2 * side), top, top + high))
                lo, hi = min(line, line + 4 * side), max(line, line + 4 * side)
                bars.append(along(axis, start, b, lo, hi, top + high - 4, top + high))
                for p in range(start, b + 1, 256):
                    bars.append(along(axis, max(start, p - 2), min(b, p + 2), lo, hi, top, top + high - 4))
            start = prev = a
    nd = MAT["nodraw"]
    if sheets["x"]:
        vmf.detail(sheets["x"], MAT["fence"], vis=vis, faces={"west": nd, "east": nd, "top": nd, "bottom": nd})
    if sheets["y"]:
        vmf.detail(sheets["y"], MAT["fence"], vis=vis, faces={"north": nd, "south": nd, "top": nd, "bottom": nd})
    vmf.detail(bars, MAT["bars"], vis=vis)
    return len(sheets["x"]) + len(sheets["y"])


def ring(args):
    vmf = Vmf()
    F, TRIM = 400, 656                           # the floor, the same all the way round; the trim line on the walls (the first canal's wall top)
    ROAD_E, ROAD_W = 656, 840                    # the two roads: the west one is 184 higher
    RISE, STEP, FENCE = 128, 23, 96              # the concrete stands this far over the ground beside it; that ground climbs in 8 steps of 23
    SKY = ROAD_W + 512
    base = F - 64
    road_sky = 2336                              # the sky over the west road
    BIG = 10 ** 6
    cw, sky = MAT["canal_wall"], MAT["sky"]
    wv, dv, sv = "LC ring: walls and floors", "LC ring: details", "LC ring: set pieces"

    def zone(x, y):
        """How far round the square is, 0 (east) to 8 (the west road's end). Each line between two crosses a straight run."""
        if y < 3328 and x < -2000:
            return 8 if x >= -3584 else 7
        if x < -4000 and y < 6400:
            return 6 if y < 4480 else 5
        if x < -3712:
            return 4
        if x < -2624:
            return 3
        if x < 576:
            return 2
        return 1 if x < 3072 else 0

    def top_of(x, y):
        return ROAD_E + RISE + STEP * zone(x, y)

    plan = RingPlan(base, SKY, top_of, wv)
    fl = ("open", F, MAT["canal_floor"])
    plan.keep_out += [(-2624, -BIG, BIG, 5696), (-BIG, -BIG, -5056, BIG)]   # the first canal and the city; the cave forest
    plan.low((5888, 5696, 6400, 5952), F, MAT["canal_floor"], F + GATE_HIGH)   # the culvert from the first canal's north gate
    plan.paint((5888, 5952, 6400, 8064), fl)            # north
    plan.paint((0, 7552, 5888, 8064), fl)               # west, along the top of the city (clear of the six leftover rooms)
    plan.paint((0, 6976, 512, 7552), fl)                # a jog south...
    plan.paint((-2048, 6976, 0, 7488), fl)              # ...west...
    plan.paint((-2560, 6976, -2048, 7552), fl)          # ...and north again
    plan.paint((-4800, 7552, -2048, 8064), fl)          # west to the corner
    plan.paint((-4800, 2752, -4288, 7552), fl)          # south, down the city's west side (clear of what reaches x -4120)
    plan.low((-5056, 4864, -4800, 5376), F, MAT["canal_floor"], F + GATE_HIGH)  # a culvert west: the cave forest's gate (x -5056)
    plan.paint((-4288, 2752, -3392, 3264), fl)          # east, in toward the road (its north wall 48 clear of the city's wall at y 3376)
    plan.paint((-3392, 1664, -2880, 3264), fl)          # south past the road's end
    plan.paint((-2880, 1920, -2624, 2560), ("open", ROAD_W, MAT["quay_floor"]))    # the platform at the west road's end
    plan.low((-3520, 1984, -3392, 2176), ROAD_W, MAT["quay_floor"], ROAD_W + 112)  # where its footbridge lands
    plan.build(vmf)

    # where brush 14734 was (x -2624..-2608): the platform's floor carried on to the road, a wall each side, a lid, and
    # above the lid the sky the road sees
    vmf.world_box((-2624, 1920, base, -2608, 2560, ROAD_W), cw, top=MAT["quay_floor"], vis=wv)
    vmf.world_box((-2624, 1856, base, -2608, 1920, SKY + 16), cw, vis=wv)
    vmf.world_box((-2624, 2560, base, -2608, 2624, SKY + 16), cw, vis=wv)
    vmf.world_box((-2624, 1920, SKY, -2608, 2560, SKY + 16), sky, sky, sky, vis=wv)
    vmf.world_box((-2624, 1920, SKY + 16, -2608, 2560, road_sky), sky, sky, sky, vis=wv)

    # gates: the first canal's north gate, and the cave forest's (in the west run's west wall)
    gate_cap(vmf, (5888, 5696, F, 6400, 5760, F + GATE_HIGH), (5888, 5776, F, 6400, 5784, F + GATE_HIGH), "x", "LC ring: south gate's cap (delete to join the first canal)")
    gate_cap(vmf, (-5056, 4864, F, -4992, 5376, F + GATE_HIGH), (-4976, 4864, F, -4968, 5376, F + GATE_HIGH), "y", "LC ring: west gate's cap (delete to join the cave forest)")

    # areaportals: inside each gate's culvert and across the west road's end
    pv = "LC ring: areaportals"
    vmf.areaportal((5888, 5824, F, 6400, 5826, F + GATE_HIGH), pv)
    vmf.areaportal((-4928, 4864, F, -4926, 5376, F + GATE_HIGH), pv)
    vmf.areaportal((-2658, 1920, ROAD_W, -2656, 2560, SKY), pv)

    if args.test:
        tv = "LC ring: for testing alone (never in the real map)"
        vmf.world_box((-2608, 1856, base, -2544, 2624, SKY + 16), sky, sky, sky, vis=tv)
        test_extras(vmf, (-2752, 2240, ROAD_W + 16), 180, tv)

    # --- the west platform: a low wall, a landing and 54 steps north down to the canal's floor, a footbridge to a barred doorway.
    # (The owner: no slope or steps IN the canal for the roads' different heights: "make the lower end have a raised
    # platform/entrance with stairs like the other end already does. That way there is no need to correct for elevation in
    # the canal itself." The east road's platform and stairs are the first canal's; this one is 440 over the floor.)
    n_steps = (ROAD_W - F) // 8 - 1
    y_foot = 2560 + 12 * n_steps
    steps = [(-3008, 2432, F, -2880, 2560, ROAD_W)] + [(-3008, 2560 + 12 * i, F, -2880, 2572 + 12 * i, ROAD_W - 8 * (i + 1)) for i in range(n_steps)]
    vmf.detail(steps, cw, vis=dv, top=MAT["stairs"])
    vmf.detail([(-2880, 1920, ROAD_W, -2864, 1992, ROAD_W + 40), (-2880, 2168, ROAD_W, -2864, 2432, ROAD_W + 40),
                (-3008, 2432, ROAD_W, -2992, 2560, ROAD_W + 40), (-2992, 2432, ROAD_W, -2880, 2448, ROAD_W + 40)], cw, vis=dv)
    vmf.detail([(-3392, 1984, ROAD_W - 16, -2880, 2176, ROAD_W)], MAT["beam"], vis=dv, top=MAT["quay_floor"])
    vmf.detail([(-3392, 1984, ROAD_W, -2880, 1992, ROAD_W + 40), (-3392, 2168, ROAD_W, -2880, 2176, ROAD_W + 40)], cw, vis=dv)
    pier = (-3152, 2048, F, -3120, 2112, ROAD_W - 16)
    vmf.detail([pier], cw, vis=dv)
    barred(vmf, (-3504, 1984, ROAD_W, -3496, 2176, ROAD_W + 112), "y", dv, back=(-3520, 1984, ROAD_W, -3512, 2176, ROAD_W + 112))
    west_stairs = (-3008, 2432, F, -2880, y_foot, ROAD_W + 64)
    bridge = (-3392, 1984, ROAD_W - 16, -2880, 2176, ROAD_W + 40)

    # --- things in the long stretches (the owner: "the canals are kind of empty ... HL2 solved this by having buildings
    # collapsed onto them that you'd crawl through, or traincars that fell into the canal") --------------------------------
    taken, blocked, lanes = [west_stairs, bridge, pier], [], []

    def static(model, x, y, yaw, z=F):
        vmf.point("prop_static", (x, y, z), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6", "disableshadows": "0", "screenspacefade": "0",
                                             "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, sv)

    def loose(model, x, y, yaw, z=F):
        vmf.point("prop_physics", (x, y, z + 24), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "spawnflags": "0"}, sv)

    def road_bridge(axis, a, b, lo, hi):
        """A street carried over the canal at the trim's height: a deck from wall to wall, parapets, girders, a pier wall on each bank."""
        def bx(u1, v1, z1, u2, v2, z2):
            return (u1, v1, z1, u2, v2, z2) if axis == "x" else (v1, u1, z1, v2, u2, z2)
        vmf.detail([bx(a, lo, TRIM - 40, b, hi, TRIM + 8)], MAT["beam"], vis=sv, top=MAT["quay_floor"])
        vmf.detail([bx(a, lo, TRIM + 8, a + 16, hi, TRIM + 56), bx(b - 16, lo, TRIM + 8, b, hi, TRIM + 56),
                    bx(a + 48, lo + 112, F, b - 48, lo + 144, TRIM - 72), bx(a + 48, hi - 144, F, b - 48, hi - 112, TRIM - 72)], cw, vis=sv)
        vmf.detail([bx(u, lo, TRIM - 72, u + 24, hi, TRIM - 40) for u in range(a + 40, b - 40, 96)], MAT["bars"], vis=sv)
        taken.append(bx(a, lo, F, b, hi, TRIM + 56))

    # 1. a street over the north leg, and under it somebody's camp
    road_bridge("y", 6656, 6976, 5888, 6400)
    for model, x, y, yaw in (("models/props_c17/furniturecouch001a.mdl", 6052, 6770, 90), ("models/props_c17/oildrum001.mdl", 6090, 6700, 0),
                             ("models/props_junk/wood_crate001a.mdl", 6060, 6900, 20), ("models/props_c17/furnituretable002a.mdl", 6110, 6850, 0)):
        static(model, x, y, yaw)
    loose("models/props_c17/furnituremattress001a.mdl", 6070, 6940, 90)
    loose("models/props_junk/wood_pallet001a.mdl", 6200, 6690, 30)
    vmf.point("light", (6110, 6820, F + 120), {"_light": "255 170 90 90", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, sv)
    # 2. a goods wagon off its rails, lying along the north side of the north run, and a container beyond it
    static("models/props_trainstation/train002.mdl", 5150, 7860, 8)
    static("models/props_wasteland/cargo_container01.mdl", 4640, 7770, 70)
    blocked += [(4780, 7780, 5530, 8064), (4480, 7616, 4800, 7936)]
    lanes += [(4900, 7720), (5150, 7716), (5400, 7720), (4640, 7960)]
    # 3. a street's bridge fallen in: three slabs leaning from the south wall to the floor (walk under their high side),
    #    the stubs of the deck still on both walls, rubble at their feet
    slabs = []
    for (a, b, foot, lift) in ((1696, 1808, 7940, 0), (1824, 1992, 7900, 14), (2008, 2104, 7964, -10)):
        slabs.append(prism([(7556, TRIM - 24 + lift), (7556, TRIM + 12 + lift), (foot, F + 36), (foot, F)], "x", a, b, MAT["beam"]))
    vmf.detail_shapes(slabs, sv)
    vmf.detail([(1680, 7552, TRIM - 40, 2120, 7632, TRIM + 8), (1680, 7984, TRIM - 40, 2120, 8064, TRIM + 8)], MAT["beam"], vis=sv, top=MAT["quay_floor"])
    vmf.detail([(1700 + 60 * k, 7632, TRIM - 20, 1704 + 60 * k, 7672 + 9 * (k % 3), TRIM - 16) for k in range(7)]
               + [(1710 + 60 * k, 7950 - 8 * (k % 3), TRIM - 20, 1714 + 60 * k, 7984, TRIM - 16) for k in range(7)], MAT["bars"], vis=sv)
    taken.append((1680, 7552, F, 2120, 8064, TRIM + 60))
    for model, x, y, yaw in (("models/props_debris/concrete_chunk01a.mdl", 1660, 7900, 40), ("models/props_debris/concrete_chunk02a.mdl", 1790, 7985, 110),
                             ("models/props_debris/broken_pile001a.mdl", 1930, 7960, 200), ("models/props_debris/concrete_chunk01a.mdl", 2060, 7990, 300),
                             ("models/props_debris/concrete_chunk02a.mdl", 2150, 7880, 75), ("models/props_debris/broken_pile001a.mdl", 2160, 7640, 20),
                             ("models/props_debris/concrete_chunk01a.mdl", 1640, 7650, 160)):
        static(model, x, y, yaw)
    blocked.append((1664, 7808, 2128, 8064))
    lanes += [(1720, 7730), (1900, 7730), (2080, 7730)]
    # 4. containers left in the jog
    static("models/props_wasteland/cargo_container01.mdl", -1500, 7300, 12)
    static("models/props_wasteland/cargo_container01.mdl", -520, 7170, -68)
    static("models/props_debris/barricade_tall01a.mdl", -1250, 7150, 30)
    blocked += [(-1730, 7180, -1270, 7420), (-660, 6990, -380, 7350)]
    lanes += [(-1500, 7130), (-720, 7300)]
    # 5. cars pushed off the road above, in the north run's west end
    for model, x, y, yaw in (("models/props_vehicles/car002a_physics.mdl", -3300, 7760, 30), ("models/props_vehicles/car004a_physics.mdl", -3470, 7880, 200),
                             ("models/props_vehicles/car005a_physics.mdl", -3180, 7900, 115), ("models/props_vehicles/tire001c_car.mdl", -3380, 7700, 0),
                             ("models/props_vehicles/tire001c_car.mdl", -3560, 7760, 0)):
        static(model, x, y, yaw)
    blocked.append((-3560, 7700, -3100, 7960))
    lanes += [(-3330, 7650), (-3330, 7990)]
    # 6. a boat and a skip in the west run; a street over it further down, a wrecked APC past that
    static("models/props_canal/boat001a.mdl", -4520, 6850, 20)
    static("models/props_junk/trashdumpster02.mdl", -4610, 5850, 90)
    road_bridge("y", 3840, 4096, -4800, -4288)
    static("models/props_vehicles/apc001.mdl", -4560, 4380, 100)
    static("models/props_wasteland/barricade001a.mdl", -4470, 4560, 80)
    static("models/props_wasteland/barricade002a.mdl", -4620, 4600, 100)
    blocked += [(-4700, 6700, -4380, 7000), (-4700, 5720, -4500, 5980), (-4700, 4240, -4420, 4520)]
    lanes += [(-4410, 6600), (-4440, 4380)]
    # 7. a container and a barricade in the south run
    static("models/props_wasteland/cargo_container01.mdl", -3900, 3040, 5)
    static("models/props_debris/barricade_tall01a.mdl", -3620, 2930, 95)
    blocked.append((-4130, 2930, -3670, 3160))
    lanes.append((-3900, 2880))

    # --- banks, trim, pipes, mud, and the fence along the top ------------------------------------------------------------
    ch = Channel(vmf, plan, F, TRIM, "LC ring")
    ch.pipes("x", 4160, 7552, 8064, taken)
    ch.pipes("x", 2560, 7552, 8064, taken)
    ch.pipes("x", -1024, 6976, 7488, taken)
    ch.pipes("y", 6336, -4800, -4288, taken)                                              # (clear of the cave forest's gate)
    ch.dress([(-2944, 2368, -2816, y_foot + 64)], taken)                                  # (no bank at the stairs)
    ch.mud(81, skip=[(5000, 5000, 7000, 5696), (-BIG, 4000, -5056, 6000)])                # (not beyond a gate)
    fences = fence(vmf, plan, FENCE, "LC ring: fence along the walls' tops")

    # --- where the city's people can walk ---------------------------------------------------------------------------
    node_id = [args.first_node]

    def node(x, y, z):
        vmf.point("info_node", (x, y, z + 40), {"nodeid": node_id[0]}, "LC ring: path nodes")
        node_id[0] += 1
    ch.nodes(node, [(5888, 5696, 6400, 5824), (-3008, 2432, -2880, y_foot), (-5056, 4864, -4928, 5376)] + blocked)
    for (x, y) in lanes:
        node(x, y, F)
    node(-2944, 2496, ROAD_W)
    for y in range(2632, y_foot, 96):
        node(-2944, y, ROAD_W - 8 * ((y - 2560) // 12 + 1))
    node(-2944, y_foot + 36, F)
    for x in (-3008, -3136, -3264):
        node(x, 2080, ROAD_W)
    for (x, y, z) in ((6144, 6400, F), (4800, 7808, F), (3200, 7808, F), (1280, 7808, F), (256, 7300, F), (-1024, 7232, F), (-2304, 7400, F),
                      (-3900, 7808, F), (-4544, 6400, F), (-4544, 4700, F), (-3800, 3008, F), (-3136, 2600, F), (-2752, 2240, ROAD_W)):
        vmf.point("env_cubemap", (x, y, z + 72), {"cubemapsize": "0"}, dv)
    # a little left lying about
    rnd = random.Random(27)
    for model, x, y in (("models/props_c17/oildrum001.mdl", 4300, 7700), ("models/props_junk/wood_pallet001a.mdl", 4380, 7760),
                        ("models/props_canal/boat002b.mdl", 300, 7250), ("models/props_vehicles/tire001c_car.mdl", -1900, 7200),
                        ("models/props_junk/wood_crate001a.mdl", -4520, 5500), ("models/props_canal/boat001a.mdl", -4500, 3500)):
        vmf.point("prop_physics", (x, y, F + 40), {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15), "skin": "0", "spawnflags": "0"}, "LC ring: props")

    # --- the checks -------------------------------------------------------------------------------------------------
    stopper = (-2608, 1856, base, -2544, 2624, road_sky)
    problems, air = check(vmf, (6144, 6800, F + 32), [] if args.test else [stopper])
    for (x1, y1, x2, y2, front) in ((-3520, 1984, -3392, 2176, "east"),):
        for i in range(x1 // CELL - 1, x2 // CELL + 1):
            for j in range(y1 // CELL - 1, y2 // CELL + 1):
                if x1 // CELL <= i < x2 // CELL and y1 // CELL <= j < y2 // CELL:
                    continue
                ahead = {"south": j < y1 // CELL, "north": j >= y2 // CELL, "west": i < x1 // CELL, "east": i >= x2 // CELL}[front]
                if plan.cells.get((i, j), ("solid",))[0] != "solid" and not ahead:
                    problems.append("the doorway at (%d %d) is open at (%d %d): it should be wall" % (x1, y1, i * CELL, j * CELL))
    if top_of(-2880, 2240) != ROAD_W + RISE or top_of(6144, 6000) != ROAD_E + RISE:
        problems.append("the walls' tops do not come out at the two roads' heights")
    seals = sum(1 for _, s in vmf.boxes if s)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    st = ch.stats
    print("ring: %d sealing brushes, %d sloped or round shapes, %d mud patches, %d entities (%d path nodes, ids %d to %d)" % (
        seals, vmf.shapes, st["mud"], len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1))
    print("  details: %d banks, %d corner fills, %d ribs, %d drain stubs, 4 pairs of pipes, %d runs of fence, the west platform with its %d steps and footbridge" % (
        st["banks"], st["fills"], st["ribs"], st["stubs"], fences, n_steps))
    print("  set pieces: 2 streets carried over (a camp under one), a goods wagon, a fallen bridge to walk under, containers, wrecked cars, a boat, an APC")
    print("  it fills x %d to %d, y %d to %d, z %d to %d; the floor is z %d all the way; the walls' concrete ends at z %d in the east, %d in the west (8 steps of %d)" % (
        min(xs), max(xs), min(ys), max(ys), base, SKY + 16, F, ROAD_E + RISE, ROAD_W + RISE, STEP))
    print("  joins: the first canal's north gate (x 5888 to 6400 at y 5696, floor z %d); the west road's end (x -2608, y 1920 to 2560, floor z %d);" % (F, ROAD_W))
    print("         a gate for the cave forest (y 4864 to 5376 at x -5056, floor z %d)" % F)
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (%s); the doorway walled on three sides" % (
            "by itself: this is the test version" if args.test else "with the west road's opening stopped up: by itself this file is OPEN to that road and will leak"))
    args.expect_overlap = {"14734"}   # (the sky wall at the west road's end: the owner deletes it)
    return vmf, problems
