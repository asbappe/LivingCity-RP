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

The west road is 184 higher than the east one (z 840 against 656), so the canal climbs: a weir
(a flight of steps the canal's full width) near the north-west corner. East of it the canal is
as the first one (floor 400, wall's top 656); west of it everything is 184 higher (floor 584,
wall's top 840). The two halves are two plans on the same grid, with a sky wall over the step
in their lids.

The owner removes brush 14734 (the sky wall at the west road's end) and 15630 (the invisible
wall before it). That brush is 16 thick and off the 64 grid, so the piece carries a 16-unit
strip in its place (floor, side walls, lid) and, above its own sky, the sky the road sees.

It has a gate in the west wall of its west run, for the cave forest (which sits out there, on
the far side of the city from the bunker forest: map_forest.py's default), and takes the first
canal's dressing: banks, mud, wall trim, drain stubs, bars nobody fits between.
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


def ring(args):
    vmf = Vmf()
    lo_f, lo_r, lo_sky = 400, 656, 1168          # east of the weir: as the first canal
    hi_f, hi_r, hi_sky = 584, 840, 1352          # west of it: 184 higher, to meet the west road (z 840)
    base = lo_f - 64
    road_sky = 2336                              # the sky over the west road
    XW = -3072                                   # the weir's line, on the north run

    def bands(rim, sky):
        return [(base, rim, MAT["canal_wall"]), (rim, rim + 256, MAT["upper_wall"]), (rim + 256, sky + 16, MAT["sky"])]
    low = Plan((0, 0), bands(lo_r, lo_sky), sky=lo_sky, vis="LC ring: walls and floors")
    high = Plan((0, 0), bands(hi_r, hi_sky), sky=hi_sky, vis="LC ring: walls and floors")
    BIG = 10 ** 6

    # --- east of the weir -----------------------------------------------------------------------------------
    lf = ("open", lo_f, MAT["canal_floor"])
    lc = ("low", lo_f, MAT["canal_floor"], lo_f + GATE_HIGH)
    low.keep_out += [(-BIG, -BIG, BIG, 5696), (-BIG, 7000, XW, 9000)]   # the first canal; the high half
    low.paint((5888, 5696, 6400, 5952), lc)             # the culvert from the first canal's north gate
    low.paint((5888, 5952, 6400, 8064), lf)             # north
    low.paint((0, 7552, 5888, 8064), lf)                # west, along the top of the city (clear of the six leftover rooms)
    low.paint((0, 6976, 512, 7552), lf)                 # a jog south...
    low.paint((-2048, 6976, 0, 7488), lf)               # ...west...
    low.paint((-2560, 6976, -2048, 7552), lf)           # ...and north again
    low.paint((XW, 7552, -2048, 8064), lf)              # west to the weir
    # --- west of the weir -----------------------------------------------------------------------------------
    hf = ("open", hi_f, MAT["canal_floor"])
    hc = ("low", hi_f, MAT["canal_floor"], hi_f + GATE_HIGH)
    high.keep_out += [(-2624, -BIG, BIG, BIG), (XW, 7000, BIG, 9000), (-BIG, -BIG, -5056, BIG)]   # the city; the low half; the cave forest
    high.paint((-4800, 7552, XW, 8064), hf)             # west from the weir
    high.paint((-4800, 2752, -4288, 7552), hf)          # south, down the city's west side (clear of what reaches x -4120)
    high.paint((-5056, 4864, -4800, 5376), hc)          # a culvert west: the cave forest's gate (x -5056)
    high.paint((-4288, 2752, -3392, 3264), hf)          # east, in toward the road (its north wall 48 clear of the city's wall at y 3376)
    high.paint((-3392, 1664, -2880, 3264), hf)          # south past the road's end
    high.paint((-2880, 1920, -2624, 2560), ("open", hi_r, MAT["quay_floor"]))                    # the quay at the west road's end
    high.paint((-3520, 1984, -3392, 2176), ("low", hi_r, MAT["quay_floor"], hi_r + 160))         # where the quay's footbridge lands
    low.build(vmf)
    high.build(vmf)
    wv = "LC ring: walls and floors"
    sky, cw = MAT["sky"], MAT["canal_wall"]

    # the step in the lids at the weir: a sky wall on the low half's lid, as high as the high half's
    vmf.world_box((XW, 7488, lo_sky + 16, XW + 16, 8128, hi_sky + 16), sky, sky, sky, vis=wv)
    # where brush 14734 was (x -2624..-2608): the quay's floor carried on to the road, a wall each side, a lid, and
    # above the lid the sky the road sees
    vmf.world_box((-2624, 1920, base, -2608, 2560, hi_r), cw, top=MAT["quay_floor"], vis=wv)
    vmf.world_box((-2624, 1856, base, -2608, 1920, hi_sky + 16), cw, vis=wv)
    vmf.world_box((-2624, 2560, base, -2608, 2624, hi_sky + 16), cw, vis=wv)
    vmf.world_box((-2624, 1920, hi_sky, -2608, 2560, hi_sky + 16), sky, sky, sky, vis=wv)
    vmf.world_box((-2624, 1920, hi_sky + 16, -2608, 2560, road_sky), sky, sky, sky, vis=wv)

    # gates: the first canal's north gate, and the cave forest's (in the west run's west wall)
    gate_cap(vmf, (5888, 5696, lo_f, 6400, 5760, lo_f + GATE_HIGH), (5888, 5776, lo_f, 6400, 5784, lo_f + GATE_HIGH), "x", "LC ring: south gate's cap (delete to join the first canal)")
    gate_cap(vmf, (-5056, 4864, hi_f, -4992, 5376, hi_f + GATE_HIGH), (-4976, 4864, hi_f, -4968, 5376, hi_f + GATE_HIGH), "y", "LC ring: west gate's cap (delete to join the cave forest)")

    # areaportals: inside each gate's culvert and across the west road's end
    pv = "LC ring: areaportals"
    vmf.areaportal((5888, 5824, lo_f, 6400, 5826, lo_f + GATE_HIGH), pv)
    vmf.areaportal((-4928, 4864, hi_f, -4926, 5376, hi_f + GATE_HIGH), pv)
    vmf.areaportal((-2658, 1920, hi_r, -2656, 2560, hi_sky), pv)

    if args.test:
        tv = "LC ring: for testing alone (never in the real map)"
        vmf.world_box((-2608, 1856, base, -2544, 2624, hi_sky + 16), sky, sky, sky, vis=tv)
        test_extras(vmf, (-2752, 2240, hi_r + 16), 180, tv)

    dv = "LC ring: details"
    # --- the weir: steps the canal's full width, up 184 ----------------------------------------------------------
    vmf.detail([(XW + 12 * k, 7552, lo_f, XW + 12 * (k + 1), 8064, hi_f - 8 * (k + 1)) for k in range(22)], cw, vis=dv, top=MAT["stairs"])
    weir = (XW, 7552, lo_f, XW + 264, 8064, hi_f)

    # --- the west quay: a low wall, a landing and 31 steps north down into the canal, a footbridge to a barred doorway ----
    steps = [(-3008, 2432, hi_f, -2880, 2560, hi_r)] + [(-3008, 2560 + 12 * i, hi_f, -2880, 2572 + 12 * i, hi_r - 8 * (i + 1)) for i in range(31)]
    vmf.detail(steps, cw, vis=dv, top=MAT["stairs"])
    vmf.detail([(-2880, 1920, hi_r, -2864, 1992, hi_r + 40), (-2880, 2168, hi_r, -2864, 2432, hi_r + 40),
                (-3008, 2432, hi_r, -2992, 2560, hi_r + 40), (-2992, 2432, hi_r, -2880, 2448, hi_r + 40)], cw, vis=dv)
    vmf.detail([(-3392, 1984, hi_r - 16, -2880, 2176, hi_r)], MAT["beam"], vis=dv, top=MAT["quay_floor"])
    vmf.detail([(-3392, 1984, hi_r, -2880, 1992, hi_r + 40), (-3392, 2168, hi_r, -2880, 2176, hi_r + 40)], cw, vis=dv)
    barred(vmf, (-3504, 1984, hi_r, -3496, 2176, hi_r + 160), "y", dv, back=(-3520, 1984, hi_r, -3512, 2176, hi_r + 160))
    west_stairs = (-3008, 2432, hi_f, -2880, 2944, hi_r + 64)
    bridge = (-3392, 1984, hi_r - 16, -2880, 2176, hi_r + 40)

    # --- banks, trim, pipes and mud, each half at its own height ---------------------------------------------------
    east = Channel(vmf, low, lo_f, lo_r, "LC ring")
    west = Channel(vmf, high, hi_f, hi_r, "LC ring")
    taken_e, taken_w = [weir], [west_stairs, bridge]
    east.pipes("x", 4160, 7552, 8064, taken_e)
    east.pipes("x", 2560, 7552, 8064, taken_e)
    east.pipes("x", -1024, 6976, 7488, taken_e)
    west.pipes("y", 6336, -4800, -4288, taken_w)                                          # (clear of the cave forest's gate)
    east.dress([(XW, 7488, XW + 320, 8128)], taken_e)
    west.dress([(-2944, 2368, -2816, 3008), (XW - 64, 7488, XW + 8, 8128)], taken_w)   # (not at the stairs; not across the weir's top)
    east.mud(81, skip=[(XW, 7552, XW + 300, 8064), (5000, 5000, 7000, 5696)])   # (not on the weir, nor beyond a gate)
    west.mud(84, skip=[(-10 ** 6, 4000, -5056, 6000)])                                   # (not beyond the cave forest's gate)

    # --- where the city's people can walk ---------------------------------------------------------------------------
    node_id = [args.first_node]

    def node(x, y, z):
        vmf.point("info_node", (x, y, z + 40), {"nodeid": node_id[0]}, "LC ring: path nodes")
        node_id[0] += 1
    east.nodes(node, [(5888, 5696, 6400, 5824), (XW, 7552, XW + 300, 8064)])
    west.nodes(node, [(-3008, 2432, -2880, 2944), (-5056, 4864, -4928, 5376)])
    for (x, y, z) in ((-2944, 2496, hi_r), (-2944, 2656, hi_r - 64), (-2944, 2752, hi_r - 128), (-2944, 2848, hi_r - 208), (-2944, 2976, hi_f),
                      (-3008, 2080, hi_r), (-3136, 2080, hi_r), (-3264, 2080, hi_r),
                      (XW + 40, 7808, hi_f - 24), (XW + 130, 7808, hi_f - 88), (XW + 220, 7808, hi_f - 148), (XW + 320, 7808, lo_f)):
        node(x, y, z)
    for (x, y, z) in ((6144, 6800, lo_f), (4800, 7808, lo_f), (3200, 7808, lo_f), (1280, 7808, lo_f), (256, 7300, lo_f), (-1024, 7232, lo_f), (-2304, 7400, lo_f),
                      (-3900, 7808, hi_f), (-4544, 6400, hi_f), (-4544, 4400, hi_f), (-3800, 3008, hi_f), (-3136, 2600, hi_f), (-2752, 2240, hi_r)):
        vmf.point("env_cubemap", (x, y, z + 72), {"cubemapsize": "0"}, dv)
    # a little left lying about
    rnd = random.Random(27)
    for model, x, y, z in (("models/props_c17/oildrum001.mdl", 4300, 7700, lo_f), ("models/props_junk/wood_pallet001a.mdl", 4380, 7760, lo_f),
                           ("models/props_canal/boat002b.mdl", 300, 7250, lo_f), ("models/props_vehicles/tire001c_car.mdl", -1500, 7200, lo_f),
                           ("models/props_junk/wood_crate001a.mdl", -4520, 5400, hi_f), ("models/props_canal/boat001a.mdl", -4500, 3700, hi_f)):
        vmf.point("prop_physics", (x, y, z + 40), {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15), "skin": "0", "spawnflags": "0"}, "LC ring: props")

    # --- the checks -------------------------------------------------------------------------------------------------
    stopper = (-2608, 1856, base, -2544, 2624, road_sky)
    problems, air = check(vmf, (6144, 6800, lo_f + 32), [] if args.test else [stopper])
    for (x1, y1, x2, y2, front) in ((-3520, 1984, -3392, 2176, "east"),):
        for i in range(x1 // CELL - 1, x2 // CELL + 1):
            for j in range(y1 // CELL - 1, y2 // CELL + 1):
                if x1 // CELL <= i < x2 // CELL and y1 // CELL <= j < y2 // CELL:
                    continue
                ahead = {"south": j < y1 // CELL, "north": j >= y2 // CELL, "west": i < x1 // CELL, "east": i >= x2 // CELL}[front]
                if high.cells.get((i, j), ("solid",))[0] != "solid" and not ahead:
                    problems.append("the doorway at (%d %d) is open at (%d %d): it should be wall" % (x1, y1, i * CELL, j * CELL))
    seals = sum(1 for _, s in vmf.boxes if s)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    st = {k: east.stats[k] + west.stats[k] for k in east.stats}
    print("ring: %d sealing brushes, %d sloped or round shapes, %d mud patches, %d entities (%d path nodes, ids %d to %d)" % (
        seals, vmf.shapes, st["mud"], len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1))
    print("  details: %d banks, %d corner fills, %d ribs, %d drain stubs, 4 pairs of pipes, a weir of 22 steps, the west quay with its stairs and footbridge" % (
        st["banks"], st["fills"], st["ribs"], st["stubs"]))
    print("  it fills x %d to %d, y %d to %d, z %d to %d" % (min(xs), max(xs), min(ys), max(ys), base, hi_sky + 16))
    print("  joins: the first canal's north gate (x 5888 to 6400 at y 5696, floor z %d); the west road's end (x -2608, y 1920 to 2560, floor z %d);" % (lo_f, hi_r))
    print("         a gate for the cave forest (y 4864 to 5376 at x -5056, floor z %d)" % hi_f)
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (%s); the doorway walled on three sides" % (
            "by itself: this is the test version" if args.test else "with the west road's opening stopped up: by itself this file is OPEN to that road and will leak"))
    args.expect_overlap = {"14734"}   # (the sky wall at the west road's end: the owner deletes it)
    return vmf, problems
