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

from map_build import CELL, GATE_HIGH, MAT, Plan, Vmf, barred, check, fence, gate_cap, octagon, prism, road_bridge, stand_z, dress_keys, loose_flags, loose_yaw, test_extras
from map_forest import noise

BANK = 128
GRATE = "metal/metalgrate013a"      # (the outfalls' grates: a grating Half-Life 2 has, already in the owner's compiled maps)


class Channel:
    """One stretch of canal at one height: what dresses it. plan: its squares; floor_z: its floor; rim_z: its wall's top."""

    def __init__(self, vmf, plan, floor_z, rim_z, vis):
        self.vmf, self.plan, self.cells = vmf, plan, plan.cells
        self.floor_z, self.rim_z, self.vis = floor_z, rim_z, vis
        self.stats = {"banks": 0, "fills": 0, "ribs": 0, "stubs": 0, "mud": 0, "nodes": 0}
        # (the dished floor, map_modules.dish_plan: squares whose concrete is lowered to dish_floor, how far the mud
        #  sags at each corner of the grid over them, and the mud's height wherever it was laid over them)
        self.dished, self.dish, self.surface, self.dish_floor = set(), {}, {}, floor_z

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

    def dress(self, no_bank, taken, outfalls=False, upright=(), avoid=()):
        """Banks along every wall (with a quarter pyramid where a wall's corner sticks out), a lip along the walls' tops,
        a rib every 512, a drain stub between ribs. no_bank: rectangles the banks stay out of. taken: boxes already on
        the walls: nothing is put within 24 units of them (and what is put is added to them).
        For the canal modules (map_modules.finish, the owner's Valve canal, 21 November): upright: rectangles where the
        walls stand upright, with no bank, but keep their lip, ribs and drains (Valve's walls; the wide canal). outfalls:
        Valve's drain outfalls in place of the small stubs: a hole 128 across centred 140 up, in pairs 384 apart either
        side of every other rib (a concrete pipe's mouth out through a bank; flush in an upright wall), their rings
        and stains put on by whoever dresses them further (map_modules.dress_canal_walls). avoid: more boxes (the
        props on the walls) that only the outfalls keep clear of."""
        self.made = {}
        vmf, cells, kind, fz, rz = self.vmf, self.cells, self.kind, self.floor_z, self.rim_z

        def clear(x1, y1, x2, y2):
            return not any(x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1] for r in no_bank)

        def sloped(x1, y1, x2, y2):
            return clear(x1, y1, x2, y2) and not any(x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1] for r in upright)

        def fits(box, gap=24, more=()):
            return not any(box[0] < t[3] + gap and box[3] > t[0] - gap and box[1] < t[4] + gap and box[4] > t[1] - gap
                           and box[2] < t[5] + gap and box[5] > t[2] - gap for t in list(taken) + list(more))
        runs = {}
        for (i, j) in list(cells):
            if kind((i, j)) != "floor":
                continue
            x, y = i * CELL, j * CELL
            for (di, dj, key, a) in ((0, -1, ("x", y, 1), x), (0, 1, ("x", y + CELL, -1), x), (-1, 0, ("y", x, 1), y), (1, 0, ("y", x + CELL, -1), y)):
                if kind((i + di, j + dj)) == "wall":
                    solid = cells.get((i + di, j + dj), ("solid",))[0] == "solid"
                    edge = (a, key[1] - 8, a + CELL, key[1] + 8) if key[0] == "x" else (key[1] - 8, a, key[1] + 8, a + CELL)
                    runs.setdefault(key, []).append((a, solid, clear(*edge), sloped(*edge)))
        banks, trims = [], []
        for (axis, line, side), parts in sorted(runs.items()):
            parts.sort()
            for want, out in ((lambda p: p[3], banks), (lambda p: p[1] and p[2], trims)):
                start = prev = None
                for part in parts + [(None, False, False, False)]:
                    a = part[0]
                    ok = a is not None and want(part)
                    if ok and start is not None and a == prev + CELL:
                        prev = a
                        continue
                    if start is not None:
                        out.append((axis, line, side, start, prev + CELL))
                    start = prev = a if ok else None
        m, shapes, boxes = MAT["canal_wall"], [], []
        self.made["banks"], self.made["walls"] = list(banks), list(trims)      # (for whoever dresses them further)
        rects = self.made.setdefault("bank_rects", [])      # (where the banks stand, seen from above)
        for (axis, line, side, a, b) in banks:
            shapes.append(prism([(line, fz), (line + side * BANK, fz), (line, fz + BANK)], axis, a, b, m))
            lo, hi = min(line, line + side * BANK), max(line, line + side * BANK)
            rects.append((a, lo, b, hi) if axis == "x" else (lo, a, hi, b))
        self.stats["banks"] += len(banks)
        for (i, j) in list(cells):
            for (dx, dy) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
                if kind((i, j)) == "wall" and kind((i + dx, j)) == "floor" and kind((i, j + dy)) == "floor" and kind((i + dx, j + dy)) == "floor":
                    vx, vy = (i + (1 if dx > 0 else 0)) * CELL, (j + (1 if dy > 0 else 0)) * CELL
                    if not (sloped(vx - 8, vy - 8, vx + 8, vy + 8) and sloped(min(vx + dx * 8, vx + dx * 72), vy - 8, max(vx + dx * 8, vx + dx * 72), vy + 8)
                            and sloped(vx - 8, min(vy + dy * 8, vy + dy * 72), vx + 8, max(vy + dy * 8, vy + dy * 72))):
                        continue
                    v0, apex = (vx, vy, fz), (vx, vy, fz + BANK)
                    px, py, pd = (vx + dx * BANK, vy, fz), (vx, vy + dy * BANK, fz), (vx + dx * BANK, vy + dy * BANK, fz)
                    shapes.append([([v0, px, pd, py], m), ([v0, px, apex], m), ([v0, py, apex], m), ([apex, px, pd], m), ([apex, py, pd], m)])
                    rects.append((min(vx, vx + dx * BANK), min(vy, vy + dy * BANK), max(vx, vx + dx * BANK), max(vy, vy + dy * BANK)))
                    self.stats["fills"] += 1

        def along(axis, a, b, lo, hi, z1, z2):
            return (a, lo, z1, b, hi, z2) if axis == "x" else (lo, a, z1, hi, b, z2)
        cuts = {}
        if outfalls:      # (placed first: an outfall over a bank rises through the lip's height, and the lip stops either side of it)
            for (axis, line, side, p, z, kind) in self.outfalls(trims, banks, along, fits, taken, avoid, shapes):
                if kind == "bank":
                    cuts.setdefault((axis, line, side), []).append((p - 82, p + 82))
        for (axis, line, side, a, b) in trims:
            dz = 1 if axis == "y" else 0      # (trims along y sit inside those along x where they cross at a corner: no shared face to flicker)
            start = a
            for c1, c2 in sorted(c for c in cuts.get((axis, line, side), []) if a < c[1] and c[0] < b) + [(b, b)]:
                if min(c1, b) > start:
                    boxes.append(along(axis, start, min(c1, b), min(line, line + side * (16 - dz)), max(line, line + side * (16 - dz)), rz + dz, rz + 16 - dz))
                start = max(start, c2)
            for at in range(a + 256, b - 128, 512):
                rib = along(axis, at - 24, at + 24, min(line, line + side * 24), max(line, line + side * 24), fz + 96, rz)
                if fits(rib):
                    boxes.append(rib)
                    taken.append(rib)
                    self.stats["ribs"] += 1
                    self.made.setdefault("ribs", []).append((axis, line, side, at))      # (for whoever dresses them further)
        for (axis, line, side, a, b) in ([] if outfalls else trims):
            for at in range(a + 512, b - 128, 1024):
                z = fz + 176
                stub = along(axis, at - 24, at + 24, min(line, line + side * 40), max(line, line + side * 40), z - 24, z + 24)
                if not fits(stub):
                    continue
                taken.append(stub)
                self.made.setdefault("stubs", []).append((axis, line, side, at, z))
                shapes.append(prism(octagon(at, z, 24), "y" if axis == "x" else "x", min(line, line + side * 40), max(line, line + side * 40), MAT["bars"], MAT["black"]))
                self.stats["stubs"] += 1
        if shapes:
            vmf.detail_shapes(shapes, self.vis + ": banks, pipes and trim")
        if boxes:
            vmf.detail(boxes, MAT["beam"], vis=self.vis + ": banks, pipes and trim")

    def outfalls(self, trims, banks, along, fits, taken, avoid, shapes):
        """Valve's drain outfalls (Route Kanal: canal_cap001 rings 154 across round holes 128 across, in groups about 384
        apart): a pair either side of every other rib, now and then one alone or none (the same every build), each a dark
        hole flush with the wall, as Valve's are. In an upright wall it is centred 140 over the floor with Valve's lip under
        it (a block 32 out from the floor to 16 under the hole, its top sloped at 45 degrees); where a bank is, it sits
        where Valve puts theirs over a slope (d1_canals_10, 12, 01a and 02: the slope meets the wall just under the hole):
        its ring's foot on the bank's top edge, centred 206 up, and the lip along the walls' tops stops either side of it.
        Gives them, and puts each in made["outfalls"]: (axis, line, side, where along, centre height, "bank" or "wall")."""
        import random as _r
        fz, c = self.floor_z, MAT["canal_wall"]
        sloping, placed = {}, []
        builts = [bx for bx, _ in self.vmf.boxes] + list(getattr(self.vmf, "shape_boxes", []))      # (what the modules built before the dressing)
        for (axis, line, side, a, b) in banks:
            sloping.setdefault((axis, line, side), []).append((a, b))
        top = getattr(self, "wall_top", None) or self.rim_z      # (how high the canal's outer walls really stand: a chain's rim)
        for (axis, line, side, a, b) in trims:
            spans = sloping.get((axis, line, side), [])
            across = "y" if axis == "x" else "x"
            ribs = list(range(a + 256, b - 128, 512))
            for k, at in enumerate(ribs[:-1]):
                # (the owner, 23 November: "there are too many culverts in the walls of the canal, way too many", "the
                # concrete support pillars ... just get cut off by the culvert", "if they were building culverts to a
                # canal, they wouldn't dig them as deep as possible", "the culvert is like 1 inch below the street":
                # one in every fourth gap between ribs, midway between them; on a wall that rises well above the trim,
                # high up in it, clear of the trim's band; under a street, only a storm drain's small mouth)
                r = _r.Random(at * 7919 + line * 104729 + side * 13)
                if (k + (side > 0) * 2) % 4 or r.random() < 0.25:
                    continue
                p = at + 256
                if p - 112 < a + 16 or p + 112 > b - 16:
                    continue
                bx, by = (p, line - side * 32) if axis == "x" else (line - side * 32, p)
                behind = self.cells.get((int(bx) // 64, int(by) // 64))
                under_street = behind is not None and behind[0] == "solid" and len(behind) == 2      # (map_corridor.canal_view: the street's squares)
                if under_street or top < self.rim_z + 224:
                    z = fz + 176      # (a storm drain's mouth: above the bank's top, well under the trim)
                    stub = along(axis, p - 24, p + 24, min(line, line + side * 40), max(line, line + side * 40), z - 24, z + 24)
                    if not fits(stub, more=avoid) or not fits(stub, gap=4, more=builts):
                        continue
                    taken.append(stub)
                    self.made.setdefault("stubs", []).append((axis, line, side, p, z))
                    shapes.append(prism(octagon(p, z, 24), across, min(line, line + side * 40), max(line, line + side * 40), MAT["bars"], MAT["black"]))
                    self.stats["stubs"] += 1
                    continue
                z = self.rim_z + 136              # (high in the wall over the trim's band: its ring 40 over the band, well under the top)
                ring = along(axis, p - 80, p + 80, min(line, line + side * 22), max(line, line + side * 22), z - 80, z + 80)
                if not fits(ring, more=avoid) or not fits(ring, gap=4, more=builts):
                    continue
                taken.append(ring)
                shapes.append(prism(octagon(p, z, 68), across, min(line, line + side * 2), max(line, line + side * 2), MAT["black"]))
                # a grate over the hole, inside Valve's ring (the owner, 22 November: "put a grate over every outpipe/
                # drainage pipe on the sidewalls"): a thin sheet of grating 2 in front of the dark, detail
                shapes.append(prism(octagon(p, z, 64), across, min(line + side * 3, line + side * 5), max(line + side * 3, line + side * 5), GRATE))
                placed.append((axis, line, side, p, z, "high"))
                self.made.setdefault("outfalls", []).append((axis, line, side, p, z, "high"))
                self.stats["stubs"] += 1
        return placed

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

    def patch_skipped(self, bi, bj, skip):
        """Is this patch of mud (256 square on the map's grid) left out? Only when a side room inside it has its floor
        lower than the canal's (a pit, a basin: mud dipped under the floor would show there). A side room at the
        canal's height or higher just has the mud dip under its floor (until 22 November every patch a side room
        touched was left out, which left a square of bare concrete there: the owner saw it at the relay)."""
        x0, y0 = bi * 256, bj * 256
        hits = [r for r in skip if x0 < r[2] and x0 + 256 > r[0] and y0 < r[3] and y0 + 256 > r[1]]
        for i in range(bi * 4, bi * 4 + 4):
            for j in range(bj * 4, bj * 4 + 4):
                x, y = i * CELL, j * CELL
                if any(x < r[2] and x + CELL > r[0] and y < r[3] and y + CELL > r[1] for r in hits):
                    spec = self.cells.get((i, j))
                    if spec and spec[0] != "solid" and spec[1] < self.floor_z:
                        return True
        return False

    def mud(self, seed, skip=(), bump=None, flat=()):
        """Mud and silt: a second, displaced skin over the floor; mud where it rises above the concrete.
        bump(x, y): extra height at a place (a heap), added everywhere, the banks' feet too. flat: rectangles where
        something stands on the floor (the mud keeps under it). Every corner's height is worked out from that corner
        alone, so two patches meeting share their edge exactly (no crack to see through, the owner's walk)."""
        cells, fz = self.cells, self.floor_z
        dished, dish = self.dished, self.dish
        for (bi, bj) in sorted(set((i // 4, j // 4) for (i, j) in cells if self.kind((i, j)) in ("floor", "gap"))):
            x0, y0 = bi * 256, bj * 256
            if self.patch_skipped(bi, bj, skip):
                continue
            hits = [r for r in list(skip) + list(flat) if x0 - 8 < r[2] and x0 + 264 > r[0] and y0 - 8 < r[3] and y0 + 264 > r[1]]
            grid, shown = {}, False
            sags = any((bi * 4 + a, bj * 4 + c) in dished for a in range(4) for c in range(4))
            for i in range(5):
                for j in range(5):
                    x, y = x0 + j * CELL, y0 + i * CELL
                    d = self.wall_near(x, y)
                    if d < BANK:
                        h = -16.0
                    else:
                        h = -7 + 17 * noise(x / 170.0, y / 170.0, seed) + 9 * noise(x / 60.0, y / 60.0, seed + 1) + (9 if d == BANK else 0)
                    if bump:
                        h += bump(x, y)
                    if (x, y) in dish:      # (over a dished square: the mud is the floor, sagging to the middle)
                        h = -dish[(x, y)] + max(h, 0.0)
                    elif any((x // CELL - a, y // CELL - c) in dished for a in (0, 1) for c in (0, 1)):
                        h = max(h, 1.0)     # (at the edge of the dish: over the lowered concrete's edge; by the corner, not the patch)
                    elif any(r[0] - 8 <= x <= r[2] + 8 and r[1] - 8 <= y <= r[3] + 8 for r in hits):
                        h = min(h, -2.0)    # (in a side room or under a thing standing on the floor: the mud keeps under it)
                    shown = shown or h > 0 or sags
                    grid[(i, j)] = (fz + h, 128 + 127 * noise(x / 110.0, y / 110.0, seed + 2))
                    self.surface[(x, y)] = fz + h
            if not shown:
                continue
            self.vmf.world_box((x0, y0, self.dish_floor if sags else fz, x0 + 256, y0 + 256, fz + (3 if sags else 8)), MAT["nodraw"], top=MAT["mud"], vis=self.vis + ": mud",
                               disp={"top": (2, lambda i, j, g=grid, x0=x0, y0=y0: (x0 + j * CELL, y0 + i * CELL, g[(i, j)][0]), lambda i, j, g=grid: g[(i, j)][1])})
            self.stats["mud"] += 1

    def lanes(self, blocked, level=0, air=True):
        """The path nodes and flying nodes lane_cells and air_points would lay at a sparseness level (NODE_LEVELS)."""
        fz, cells = self.floor_z, self.cells
        open_every, tight_every, air_step = NODE_LEVELS[level]

        def floor_of(c):
            spec = cells.get(c)
            if spec is None or spec[0] == "solid" or (spec[0] in ("low", "under") and len(spec) > 3 and spec[3] - spec[1] < 72):
                return None
            return fz if c in self.dished else spec[1]
        banks = getattr(self, "made", {}).get("bank_rects", [])
        ground, line = lane_cells(cells, floor_of, lambda c: cells.get(c, ("solid",))[0] in ("low", "under"), blocked, banks, open_every, tight_every)
        flying = air_points(line, [bx for bx, _ in self.vmf.boxes] + list(getattr(self.vmf, "shape_boxes", [])), air_step) if air else []
        return ground, flying

    def nodes(self, node, blocked, air=None, share=None, extra=0):
        """Path nodes where people walk (Valve's spacing, the owner, 21 November: lane_cells): along the middle of the
        canal's floor and of every room and platform, 128 apart in the open and 64 in corridors, never on a bank; over
        the dish at the mud's height. air(x, y, z): if given, flying nodes for scanners over the open ones, about 150
        apart, 120 over the ground nodes (160 over the floor), where nothing is in the way. share: the most nodes this
        piece may have (with `extra` already spent elsewhere): sparser levels are tried until they fit."""
        for level in range(len(NODE_LEVELS)):
            ground, flying = self.lanes(blocked, level, air is not None)
            if share is None or len(ground) + len(flying) + extra <= share:
                break
        for (x, y, z, roofed) in ground:
            node(x, y, z)
            self.stats["nodes"] += 1
        for (x, y, z) in flying:
            air(x, y, z)
            self.stats["air"] = self.stats.get("air", 0) + 1
        self.stats["level"] = level

NODE_AIR, AIR_UP = 150, 160      # Valve's flying nodes: about 150 apart, 120 over the ground nodes (lane_cells lays the walking ones)


NODE_LEVELS = ((2, 1, 150), (2, 2, 256), (3, 2, 384), (4, 3, 512), (6, 4, 768), (8, 5, 1024))      # (every how many squares in the open, in corridors; flying nodes apart): densest first


def lane_cells(cells, floor_of, roofed, blocked=(), banks=(), open_every=2, tight_every=1):
    """Where people walk, for path nodes (Valve, 23 maps: rooms and sewers 64 to 72 apart, open ground 126 to 141, 96 on
    the whole; the owner, 21 November: "denser only where people walk", so the engine's 4096 for a whole map is not
    used up): one line down the middle of every walkable place (the squares farthest from its edge across it; where two
    tie side by side, the first), a node on every other square along it in the open and in roofed halls (128) and on
    every square in corridors and small rooms (64), and none on the rest of the floor. floor_of(c): the height people walk at on a square, None where nobody
    does; a step over 18 is the place's edge. blocked: rectangles with no node; banks: rectangles of slope. Gives the
    nodes [(x, y, z, roofed)] and the whole middle line (for the flying nodes), the same every build."""
    from collections import deque
    walk = {}
    for c in cells:
        z = floor_of(c)
        if z is not None:
            walk[c] = z

    def same(a, b):
        return b in walk and abs(walk[a] - walk[b]) <= 18
    ring8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
    k, dq = {}, deque()
    for c in walk:
        if any(not same(c, (c[0] + dx, c[1] + dy)) for dx, dy in ring8):
            k[c] = 1
            dq.append(c)
    while dq:
        c = dq.popleft()
        for dx, dy in ring8:
            n = (c[0] + dx, c[1] + dy)
            if n not in k and same(c, n):
                k[n] = k[c] + 1
                dq.append(n)

    def kk(c, n):
        return k.get(n, 0) if same(c, n) else 0
    kept, line, near = [], [], {}
    for c in sorted(k):
        kc = k[c]
        nb = {(1, 0): kk(c, (c[0] + 1, c[1])), (-1, 0): kk(c, (c[0] - 1, c[1])), (0, 1): kk(c, (c[0], c[1] + 1)), (0, -1): kk(c, (c[0], c[1] - 1))}
        if any(v > kc for v in nb.values()) or any(kk(c, (c[0] + dx, c[1] + dy)) > kc for dx, dy in ring8):
            continue      # (not on the middle line; nor a notch in a ragged edge)
        # a line two squares wide (two tie side by side across it): keep the first of the two
        if (nb[(0, -1)] < kc or nb[(0, 1)] < kc) and nb[(0, -1)] == kc and nb[(1, 0)] == kc == nb[(-1, 0)]:
            continue
        if (nb[(-1, 0)] < kc or nb[(1, 0)] < kc) and nb[(-1, 0)] == kc and nb[(0, 1)] == kc == nb[(0, -1)]:
            continue
        r = roofed(c)
        x, y, z = c[0] * CELL + 32, c[1] * CELL + 32, walk[c]
        if any(q[0] <= x < q[2] and q[1] <= y < q[3] for q in blocked) or any(q[0] < x < q[2] and q[1] < y < q[3] for q in banks):
            continue
        line.append((x, y, z, r))
        tight = r and kc <= 2          # (a corridor or a small room; a roofed hall is spaced as the open is)
        every = tight_every if tight else open_every
        if (c[0] + c[1]) % every:
            continue      # (in the open, every other square; in a corridor, every one, unless the piece's share is short)
        g, gap = (x // 128, y // 128), 64 * every - (8 if every == 1 else 40)
        if any((x - p[0]) ** 2 + (y - p[1]) ** 2 < gap * gap and abs(z - p[2]) < 64
               for dx in (-1, 0, 1) for dy in (-1, 0, 1) for p in near.get((g[0] + dx, g[1] + dy), [])):
            continue      # (where the middle spreads wide, as in a turn or a room: none closer than that)
        kept.append((x, y, z, r))
        near.setdefault(g, []).append((x, y, z))
    return kept, line


def air_points(line, boxes, step=NODE_AIR, up=AIR_UP, clear=32):
    """Flying nodes over the open middle line (lane_cells): about `step` apart, `up` over the floor, none within `clear`
    of a brush."""
    kept = []
    for (x, y, z, roofed) in line:
        if roofed:
            continue
        az = z + up
        if any((x - p[0]) ** 2 + (y - p[1]) ** 2 < (step - 14) ** 2 for p in kept):
            continue
        if any(b[0] - clear < x < b[3] + clear and b[1] - clear < y < b[4] + clear and b[2] - clear < az < b[5] + clear for b in boxes):
            continue
        kept.append((x, y, az))
    return kept

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


# The owner, 20 November: "even the southern half of the ring should be a bit dimmer". One sun lights the whole map alike,
# so this is the gamemode's to do, on the screen of whoever stands there: marks named lc_mood_dim along the canal south of
# this line, one every so far (sv_livingcity_daylight.lua reads them).
DIM_SOUTH_OF, DIM_APART = 4600, 700


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
    # (the plan is built with the dressing, below: the dished floor lowers some squares first)

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
        from map_build import standing_prop      # (a physics model as a prop_dynamic_override: the compiler deletes it as a prop_static)
        cls, keys = standing_prop(model)
        vmf.point(cls, (x, y, stand_z(model, z)), dress_keys(model, x, y, dict(keys, model=model, angles="0 %d 0" % yaw)), sv)      # (standing ON z, by its size)

    def loose(model, x, y, yaw, z=F, roll=0):
        vmf.point("prop_physics", (x, y, stand_z(model, z + 1, roll=roll)), dress_keys(model, x, y, {"model": model, "angles": "0 %d %d" % (loose_yaw(model, x, y, yaw), roll),
                                                                                                    "spawnflags": loose_flags(model)}), sv)

    # 1. a street over the north leg, and under it somebody's camp
    taken.append(road_bridge(vmf, plan, "y", 6656, 6976, 5888, 6400, F, TRIM, sv))
    for model, x, y, yaw in (("models/props_c17/furniturecouch001a.mdl", 6052, 6770, 90), ("models/props_c17/oildrum001.mdl", 6090, 6700, 0),
                             ("models/props_junk/wood_crate001a.mdl", 6060, 6900, 20), ("models/props_c17/furnituretable002a.mdl", 6110, 6850, 0)):
        static(model, x, y, yaw)
    loose("models/props_c17/furnituremattress001a.mdl", 6070, 6940, 90, roll=180)      # (turned over: unturned it lies on its back)
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
    taken.append(road_bridge(vmf, plan, "y", 3840, 4096, -4800, -4288, F, TRIM, sv))
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
    # (the canal modules' dressing, the owner, 21 November: "yes please": Valve's outfalls and caged lamps, the dished floor)
    from map_modules import dress_piece
    ch, _ = dress_piece(vmf, plan, "ring", "LC ring", taken,
                        [(-2944, 2368, -2816, y_foot + 64)],                                  # (no bank at the stairs)
                        [(5000, 5000, 7000, 5696), (-BIG, 4000, -5056, 6000)], 81,           # (no mud beyond a gate)
                        pipes=[("x", 4160, 7552, 8064), ("x", 2560, 7552, 8064), ("x", -1024, 6976, 7488),
                               ("y", 6336, -4800, -4288)],                                    # (the last clear of the cave forest's gate)
                        rim=ROAD_E + RISE)
    fences = fence(vmf, plan, FENCE, "LC ring: fence along the walls' tops")

    # --- where the city's people can walk ---------------------------------------------------------------------------
    node_id = [args.first_node]

    dim = []       # (where the southern half's "a bit dimmer" marks go: below)

    def node(x, y, z):
        vmf.point("info_node", (x, y, z + 40), {"nodeid": node_id[0]}, "LC ring: path nodes")
        node_id[0] += 1
        if y < DIM_SOUTH_OF and all((x - a) ** 2 + (y - b) ** 2 >= DIM_APART ** 2 for a, b, _ in dim):
            dim.append((x, y, z))
    def air_node(x, y, z):      # (flying nodes for scanners over the canal: Valve's, the owner, 21 November)
        vmf.point("info_node_air", (x, y, z), {"nodeid": node_id[0], "nodeheight": "0"}, "LC ring: flying nodes")
        node_id[0] += 1
    from map_build import node_share      # (as many as the ring's share of the merged map allows: map_build.NODE_SHARES)
    ch.nodes(node, [(5888, 5696, 6400, 5824), (-3008, 2432, -2880, y_foot), (-5056, 4864, -4928, 5376)] + blocked, air=air_node,
             share=node_share("ring"), extra=len(lanes) + len(range(2632, y_foot, 96)) + 5)
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
    # cover hints behind its wrecks and barricades, as the modules have (Valve's; in what is left of its share)
    from map_modules import piece_cover_hints
    node_id[0] += piece_cover_hints(vmf, lambda x, y: plan.cells.get((x // CELL, y // CELL)), "LC ring", "ring", node_id[0],
                                    node_share("ring") - (node_id[0] - args.first_node), ch.dished)
    for x, y, z in dim:
        vmf.point("info_target", (x, y, z + 64), {"targetname": "lc_mood_dim"}, "LC ring: the dimmer southern half (marks for the gamemode)")
    # a little left lying about
    rnd = random.Random(27)
    for model, x, y in (("models/props_c17/oildrum001.mdl", 4300, 7700), ("models/props_junk/wood_pallet001a.mdl", 4380, 7760),
                        ("models/props_canal/boat002b.mdl", 300, 7250), ("models/props_vehicles/tire001c_car.mdl", -1900, 7200),
                        ("models/props_junk/wood_crate001a.mdl", -4520, 5500), ("models/props_canal/boat001a.mdl", -4500, 3500)):
        vmf.point("prop_physics", (x, y, stand_z(model, F + 1)), dress_keys(model, x, y, {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15),
                                                                                         "spawnflags": loose_flags(model)}), "LC ring: props")

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
