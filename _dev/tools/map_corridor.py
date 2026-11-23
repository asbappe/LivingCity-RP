#!/usr/bin/env python3
"""
Living City: the street beside the canal (a railway, a road, and the modules that belong up there)

The owner, 20 November: the relay, the substation, the market and their like "are low enough that they
don't make sense in context ... these would never have been built below the water level in a canal. so
either they need to be raised ... above the highest water level ... or ... put them in some other
structure ... such as a road (pavement, like an outer-edge of city highway) that drives next to the
canal on the upper side and sometimes crosses it ... I also REALLY am thinking I would like a dynamic
railway next to the canal, maybe between the road and canal, that has a massive combine train spawn
and go by at random intervals ... act as a slight danger because it can kill you if you stand in the way".

So a layout may say "upper left" (or right): then that bank of the whole chain is built up to the
street's height (z 656, the height of the city's own roads, 256 over the canal's floor), in this order
going away from the canal:

    256..320    the canal's edge: a low parapet with chain link on it, and where stairs from the canal come up
    320..512    the railway: ballast, sleepers, two rails
    512..576    a kerb and a rail between the tracks and the road, and the inner pavement
    576..960    the roadway
    960..1024   the outer pavement
    1024..      the frontage: a brick wall of blind windows, or a module lifted up here

A module's line may end in "up": then the whole module is built lifted to the street. Its own canal
becomes the road (512 wide in both), its left wall the frontage, and everything in it is 256 higher;
the real canal passes below as a plain stretch, with stairs up from it and a plank crossing over the
tracks. Nothing in the module's own code changes.

The train: every straight run that has two "shed" lines gets one. A shed is a stretch whose tracks
are roofed over (a brick shed the length of the train); the train waits out of sight in one, runs to
the other at random intervals behind its horn, and is put back unseen. It is Half-Life 2's own Combine
train (an engine and cars, as models riding an unseen brush), it is solid, and it kills what it hits.
"""

import random

from map_build import CELL, MAT, Plan

STREET = 656            # the street's height: the city's own roads, and the trim line on the canal's walls
WALL_H = 512            # the Combine wall between the city and the street ("wall combine"): its height over the street
CORE = "metal/citadel_metalwall077a"     # its sealing core (seen only where its detail leaves a gap)
EDGE, TRACK, ROAD_IN, ROAD_OUT, FRONT = 256, 320, 512, 576, 1024     # distances from the canal's middle (see above); the roadway ends at 960
LIFT_V, LIFT_Z = 768, 256                                            # how far a lifted module is moved out, and up
FTOP = STREET + 384     # the top of the frontage's wall and of the sheds
SHED_H = 320            # a shed's headroom: the engine is 289 high
RAIL_V = 416            # the middle of the tracks
# The modules that belong on the street, not in the canal's bed (the owner: they "would never have been built below the water
# level in a canal"), and the words to put after each in a layout. "flip": its own things are on its right.
STREET_MODULES = {"relay": "up flip", "substation": "up flip", "market": "up", "clinic": "up", "cells": "up", "morgue": "up", "depot": "up", "armory": "up",
                  "press": "up", "still": "up", "garden": "up", "playground": "up", "pumphouse": "up", "chimney": "up flip", "hq": "up", "memorial": "up", "pit": "up",
                  "plaza": "up", "flats": "up"}
ENGINE, CAR = "models/props_combine/combinetrain01a.mdl", "models/props_combine/combine_train02a.mdl"
ENGINE_LEN, CAR_LEN, GAP = 640, 628, 16


class CorridorPlan(Plan):
    """The canal's squares, and beside them squares at the street's height. More kinds of square than Plan's:
    ("under", floor, material, ceiling, deck material): a room at the canal's height with the street over it;
    a "low" square or a solid one in `front` is brick above the street and rises to FTOP (a building, a shed)."""

    def __init__(self, base, rim, sky, vis):
        Plan.__init__(self, (0, 0), [(base, rim, MAT["canal_wall"]), (rim, sky + 16, MAT["sky"])], sky=sky, vis=vis)
        self.rim = rim
        self.front = set()

    def walls(self):
        if self.walled:
            return
        Plan.walls(self)
        for c, spec in list(self.cells.items()):
            front = c in self.front or any((c[0] + di, c[1] + dj) in self.front for di in (-1, 0, 1) for dj in (-1, 0, 1))
            top = FTOP if front else self.rim
            if spec[0] == "solid":
                self.cells[c] = ("solid", top, front)
            elif spec[0] == "low" and len(spec) == 4:
                self.cells[c] = spec + (max(top, spec[3]), front)

    def build(self, vmf):
        self.walls()
        cw, sky, brick = MAT["canal_wall"], MAT["sky"], "brick/brickwall045d"
        for x1, y1, x2, y2, spec in self.rectangles():
            kind = spec[0]
            if kind == "solid":
                top, front = spec[1], spec[2]
                if front and top > STREET:
                    vmf.world_box(self.box(x1, y1, self.base, x2, y2, STREET), cw, vis=self.vis)
                    vmf.world_box(self.box(x1, y1, STREET, x2, y2, top), brick, top=cw, vis=self.vis)
                else:
                    vmf.world_box(self.box(x1, y1, self.base, x2, y2, top), cw, vis=self.vis)
                vmf.world_box(self.box(x1, y1, top, x2, y2, self.top), sky, vis=self.vis)
                continue
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, spec[1]), CORE if spec[2] == CORE else self.floor_side, top=spec[2], vis=self.vis)
            if kind == "open":
                lid = spec[3] if len(spec) > 3 and spec[3] else self.sky      # (a square with a sky of its own, higher: a church's yard)
                vmf.world_box(self.box(x1, y1, lid, x2, y2, max(self.top, lid + 16)), sky, sky, sky, vis=self.vis)
            elif kind == "cellar":      # (a room under a yard open to the sky: Plan's own)
                ceil, upper, upper_mat, lid = spec[3], spec[4], spec[5], spec[6]
                vmf.world_box(self.box(x1, y1, ceil, x2, y2, upper), self.floor_side, top=upper_mat, bottom=self.ceiling, vis=self.vis)
                vmf.world_box(self.box(x1, y1, lid, x2, y2, max(self.top, lid + 16)), sky, sky, sky, vis=self.vis)
            elif kind == "under":
                vmf.world_box(self.box(x1, y1, spec[3], x2, y2, STREET), cw, top=spec[4], bottom=self.ceiling, vis=self.vis)
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), sky, sky, sky, vis=self.vis)
            else:
                top = spec[4]
                if top > spec[3]:
                    vmf.world_box(self.box(x1, y1, spec[3], x2, y2, top), brick if spec[5] and spec[3] >= STREET else cw, top=cw, bottom=self.ceiling, vis=self.vis)
                vmf.world_box(self.box(x1, y1, top, x2, y2, self.top), sky, bottom=None if top > spec[3] else (sky if spec[2] == CORE else self.ceiling), vis=self.vis)
        self.raise_sky(vmf)      # (higher skies of their own closed in on every side, as Plan's)


class View:
    """The plan as the canal's own dressing should see it: the street's squares are wall to it."""

    def __init__(self, plan, cells):
        self.plan, self.cells = plan, cells
        self.box = plan.box


def canal_view(b):
    """For the banks, trim, mud and the canal's path nodes: every square at the street's height is a wall."""
    cells = {}
    for c, spec in b.plan.cells.items():
        if spec[0] == "under":
            cells[c] = ("low", spec[1], spec[2], spec[3])
        elif spec[0] != "solid" and spec[1] >= STREET - 16 and (c in b.deck or c in b.lifted):      # (a town's gutters are 8 under the street)
            cells[c] = ("solid", STREET)
        else:
            cells[c] = spec
    return View(b.plan, cells)


def fence_view(b):
    """For the chain link along the walls' tops: none where the street is (it has its own parapet), none on buildings."""
    cells = {}
    for c, spec in b.plan.cells.items():
        if spec[0] == "under" or (spec[0] != "solid" and spec[1] >= STREET - 16) or (spec[0] == "solid" and len(spec) > 2 and spec[2]):
            continue
        cells[c] = spec
    return View(b.plan, cells)


def train_len(cars):
    return ENGINE_LEN + cars * (CAR_LEN + GAP)


def lay(b, elems, side, cars):
    """Build the street along one bank of everything in the chain. elems: each stretch in order, as a dict with its
    frame (never flipped or lifted), its length, its kind ("leg", "left" or "right" for a turn), and whether it is a
    shed, a lifted module, or wants stairs."""
    from map_modules import F, MM, Mod, chain_link
    s = 1 if side == "left" else -1
    plan, cells = b.plan, b.plan.cells
    road, walk, gravel = MM["road"], MM["walk"], MM["gravel"]
    FR = front_line(b)          # (where the frontage stands: FRONT, or 64 farther out behind a Combine wall's foot)
    shed_front = set()     # (the sheds' own brick walls: never the Combine wall)

    def band(fr, u1, a, u2, c, mat, tag):
        """Squares from a to c out from the canal's middle, on the street's side: make them street."""
        r = fr.rect(u1, s * a, u2, s * c)
        for i in range(r[0] // CELL, r[2] // CELL):
            for j in range(r[1] // CELL, r[3] // CELL):
                spec = cells.get((i, j))
                if spec is None:
                    cells[(i, j)] = ("open", STREET, mat)
                    b.owner[(i, j)] = "the street"
                    b.deck.add((i, j))
                elif spec[0] == "open":
                    if spec[1] >= STREET:
                        b.deck.add((i, j))
                    else:
                        b.viaduct.add((i, j))
                elif spec[0] == "low" and spec[1] < STREET:
                    if spec[3] > STREET + 64:
                        b.problems.append("%s's room at (%d %d) is too tall to pass under the street (its roof is z %d): flip it to the other bank, or lift it (\"up\")" % (
                            b.owner.get((i, j), "a module"), i * CELL, j * CELL, spec[3]))
                        continue
                    cells[(i, j)] = ("under", spec[1], spec[2], min(spec[3], STREET - 16), mat)
                    b.deck.add((i, j))

    # --- the runs between turns, and the sheds in each ---
    legs, leg = [], []
    for e in elems:
        if e["kind"] == "leg":
            leg.append(e)
        else:
            if leg:
                legs.append(leg)
            leg = []
    if leg:
        legs.append(leg)
    need = train_len(cars) + 96      # (the back wall's 64, and 16 clear at each end: the train waits against the closed end)

    # --- the squares ---
    for e in elems:
        if e["kind"] == "gap":      # (a stretch with no street: "nostreet")
            continue
        fr, L = e["frame"], e["length"]
        if e["kind"] == "leg":
            if e.get("shed"):
                if L < need:
                    b.problems.append("%s is %d long: a shed must be at least %d for a train of %d cars" % (e["tag"], L, need, cars))
                # the tracks roofed over: brick walls where the canal's edge and the inner pavement would be, a back wall at one end
                back = e["shed"]          # "start": this shed's closed end is at u 0; "end": at u L
                u1, u2 = (64, L) if back == "start" else (0, L - 64)
                r = fr.rect(u1, s * TRACK, u2, s * ROAD_IN)
                for i in range(r[0] // CELL, r[2] // CELL):
                    for j in range(r[1] // CELL, r[3] // CELL):
                        if (i, j) in cells:
                            b.problems.append("%s: its shed runs into %s at (%d %d)" % (e["tag"], b.owner.get((i, j), "something"), i * CELL, j * CELL))
                        cells[(i, j)] = ("low", STREET, gravel, STREET + SHED_H)
                        b.owner[(i, j)] = e["tag"]
                        b.sheds.add((i, j))
                r = fr.rect(0, s * EDGE, L, s * ROAD_OUT)
                for i in range(r[0] // CELL, r[2] // CELL):
                    for j in range(r[1] // CELL, r[3] // CELL):
                        plan.front.add((i, j))
                        shed_front.add((i, j))
                band(fr, 0, ROAD_OUT, L, FR, road, e["tag"])
            else:
                band(fr, 0, EDGE, L, TRACK, walk, e["tag"])
                band(fr, 0, TRACK, L, ROAD_IN, gravel, e["tag"])
                band(fr, 0, ROAD_IN, L, FR, road, e["tag"])
            r = fr.rect(0, s * FR, L, s * (FR + (1600 if e.get("lifted") else 64)))
            for i in range(r[0] // CELL, r[2] // CELL):
                for j in range(r[1] // CELL, r[3] // CELL):
                    plan.front.add((i, j))
        elif e["kind"] in ("left", "right") and (e["kind"] == "right") == (s > 0):      # (a turn away from the street's side: the street goes round the outside of it)
            band(fr, 0, EDGE, 256 + FR, FR, road, e["tag"])
            r = fr.rect(512, s * -256, 256 + FR, s * 256)
            for i in range(r[0] // CELL, r[2] // CELL):
                for j in range(r[1] // CELL, r[3] // CELL):
                    if (i, j) not in cells:
                        cells[(i, j)] = ("open", STREET, road)
                        b.owner[(i, j)] = "the street"
                        b.deck.add((i, j))
            r = fr.rect(-64, s * -320, 256 + FR + 64, s * (FR + 64))
            for i in range(r[0] // CELL, r[2] // CELL):
                for j in range(r[1] // CELL, r[3] // CELL):
                    plan.front.add((i, j))

    # --- the junctions: at a turn toward the street's side the two runs' streets cross in a square; nothing that runs
    # along one street (its rail between tracks and road, its frontage, its lamps) is carried across the other there ---
    junction = set()
    for k, e in enumerate(elems):
        if e["kind"] not in ("left", "right") or (e["kind"] == "left") != (s > 0):
            continue
        a = elems[k - 1] if k > 0 else None
        z = elems[k + 1] if k + 1 < len(elems) else None
        if not a or not z or a["kind"] != "leg" or z["kind"] != "leg":
            continue
        ra = a["frame"].rect(max(0, a["length"] - FR - 64), s * (EDGE + 64), a["length"], s * (FR + 64))      # (from beyond the parapet: the canal's edges keep theirs)
        rz = z["frame"].rect(0, s * (EDGE + 64), min(z["length"], FR + 64), s * (FR + 64))
        x1, y1, x2, y2 = max(ra[0], rz[0]), max(ra[1], rz[1]), min(ra[2], rz[2]), min(ra[3], rz[3])
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                junction.add((i, j))

    if getattr(b, "street_wall", None) == "combine":
        combine_core(b, shed_front)

    # --- what stands on it ---
    rnd = random.Random(len(elems) * 31 + 7)
    for n, e in enumerate(elems):
        if e["kind"] != "leg":
            continue
        fr, L = e["frame"], e["length"]
        m = Mod(b, fr, e["tag"] + " (the street)")
        dv = b.vis + ": the street"

        def sv(a, c):      # (two distances out from the canal's middle, as v from low to high)
            return (s * a, s * c) if s > 0 else (s * c, s * a)

        def is_deck(u, a):
            x, y = fr.pt(u, s * a)
            return (x // CELL, y // CELL) in b.deck

        def in_junction(u, a):
            x, y = fr.pt(u, s * a)
            return (x // CELL, y // CELL) in junction

        def runs(a, skip=()):
            """Stretches of u where the square at distance a is street (and u is in none of the skipped stretches)."""
            out, start = [], None
            for u in range(0, L + 1, CELL):
                ok = u < L and is_deck(u + 32, a) and not in_junction(u + 32, a) and not any(k1 <= u < k2 for k1, k2 in skip)
                if ok and start is None:
                    start = u
                elif not ok and start is not None:
                    out.append((start, u))
                    start = None
            return out
        stairs = []
        if e.get("stairs") and not e.get("shed"):
            # stairs from the canal's floor up its wall to the street, and planks across the tracks at their head
            u0 = max(64, min(L - 512, L // 2 - 256) // 64 * 64)
            v1, v2 = sv(192, 256)
            m.steps(u0, v1, v2, F, STREET, "u", 1)
            m.det([(u0 - 48, v1, F, u0, v2, F + 2)], MAT["canal_wall"], top=MAT["quay_floor"])      # (an apron at their foot: the mud kept level there)
            m.no_bank(u0 - 8, s * 256 - 8, u0 + 392, s * 256 + 8)
            m.blocked(u0, v1, u0 + 392, v2)
            m.taken(u0, v1, F, u0 + 384, v2, STREET)
            top = (u0 + 384, u0 + 448)
            stairs.append((top[0] - 64, top[1]))      # (the parapet stops a square short: its top steps step off sideways onto the street)
            m.det([(top[0], sv(TRACK, ROAD_IN)[0], STREET, top[1], sv(TRACK, ROAD_IN)[1], STREET + 9)], MM["wood"], vis=dv)
            m.lane(u0 - 24, s * 224, F)
            m.lane(u0 + 190, s * 224, F + 128)
            m.lane(top[0] + 32, s * 288, STREET)
            m.lane(top[0] + 32, s * RAIL_V, STREET + 9)
            m.lane(top[0] + 32, s * 544, STREET)
            e["crossing"] = top
            m.view(u0 - 60, s * 150, F, 20 if s > 0 else 340, -16, "the stairs up to the street")
        # the canal's edge: a low parapet, chain link on it (not where a bridge meets the street: b.edge_gaps)
        for u in range(0, L, CELL):
            px, py = fr.pt(u + 32, s * (EDGE + 6))
            if any(r[0] <= px <= r[2] and r[1] <= py <= r[3] for r in b.edge_gaps):
                stairs.append((u, u + CELL))
        for a, c in runs(EDGE + 32, stairs):
            v1, v2 = sv(EDGE, EDGE + 12)
            m.det([(a, v1, STREET, c, v2, STREET + 40)], MAT["beam"], vis=dv)
            chain_link(m, (a, s * (EDGE + 6)), (c, s * (EDGE + 6)), STREET + 40, 72)
        # the tracks: sleepers and two rails wherever there is ballast, in the open and in the sheds
        ties, rails = [], []
        start = None
        for u in range(0, L + 1, CELL):
            x, y = fr.pt(u + 32, s * RAIL_V)
            c = (x // CELL, y // CELL)
            ok = u < L and (c in b.deck or c in b.sheds or c in b.viaduct)
            if ok:
                v1, v2 = sv(RAIL_V - 68, RAIL_V + 68)
                ties.append((u + 10, v1, STREET, u + 22, v2, STREET + 3))
                ties.append((u + 42, v1, STREET, u + 54, v2, STREET + 3))
            if ok and start is None:
                start = u
            elif not ok and start is not None:
                for g in (-40, 37):
                    v1, v2 = sv(RAIL_V + g, RAIL_V + g + 3)
                    rails.append((start, v1, STREET + 3, u, v2, STREET + 9))
                start = None
        if ties:
            m.det(ties, MM["beam_wood"], vis=dv)
            m.det(rails, MAT["bars"], vis=dv)
        # between the tracks and the road: the inner pavement, a kerb and a rail (open at a crossing)
        for a, c in runs(ROAD_IN + 32):
            v1, v2 = sv(ROAD_IN, ROAD_OUT)
            m.det([(a, v1, STREET, c, v2, STREET + 8)], walk, vis=dv)
        for a, c in runs(ROAD_IN + 32, stairs):
            v1, v2 = sv(ROAD_IN + 2, ROAD_IN + 6)
            m.det([(a, v1, STREET + 40, c, v2, STREET + 44)] + [(u, v1, STREET + 8, u + 4, v2, STREET + 40) for u in range(a, c, 128)] + [(c - 4, v1, STREET + 8, c, v2, STREET + 40)], MAT["bars"], vis=dv)
        if not e.get("lifted") and getattr(b, "street_wall", None) == "combine":
            for a, c in runs(FR - 32):          # (the outer pavement up to the Combine wall's foot; the wall itself: combine_wall)
                v1, v2 = sv(960, FR)
                m.det([(a, v1, STREET, c, v2, STREET + 8)], walk, vis=dv)
        elif not e.get("lifted"):
            # the outer pavement, street lamps, and the frontage: a plinth, piers, blind windows, now and then a barred doorway
            open_front = [(u, u + CELL) for u in range(0, L, CELL) if is_deck(u + 32, FRONT + 32)]      # (the frontage opens there: another street, a road off it)
            for a, c in runs(FRONT - 32, open_front):
                v1, v2 = sv(960, FRONT)
                m.det([(a, v1, STREET, c, v2, STREET + 8)], walk, vis=dv)
                p1, p2 = sv(FRONT - 8, FRONT)
                w1, w2 = sv(FRONT - 3, FRONT)
                m.det([(a, p1, STREET + 8, c, p2, STREET + 40)], MAT["beam"], vis=dv)
                for u in range(a, c, 256):
                    if u + 256 > c:
                        break
                    m.det([(u, p1, STREET + 40, u + 24, p2, FTOP - 24)], MAT["beam"], vis=dv)
                    if rnd.random() < 0.18:
                        m.det([(u + 88, w1, STREET + 8, u + 192, w2, STREET + 136)], MAT["black"], vis=dv)
                        m.bars((u + 88, sv(FRONT - 10, FRONT - 4)[0], STREET + 8, u + 192, sv(FRONT - 10, FRONT - 4)[1], STREET + 136), "u", vis=dv)
                    else:
                        m.det([(u + 72, w1, STREET + 104, u + 208, w2, STREET + 232)], MAT["black"], vis=dv)
                        m.det([(u + 66, p1, STREET + 96, u + 214, p2, STREET + 104), (u + 138, sv(FRONT - 5, FRONT)[0], STREET + 104, u + 142, sv(FRONT - 5, FRONT)[1], STREET + 232)], MAT["beam"], vis=dv)
                    if rnd.random() < 0.3:
                        m.decal("decals/decalposter014a" if rnd.random() < 0.5 else "decals/decal_posters005a", u + 44, s * (FRONT - 1), STREET + 110)
                m.det([(a, p1, FTOP - 24, c, p2, FTOP)], MAT["beam"], vis=dv)
            for u in range(256, L - 64, 768):
                if is_deck(u, FRONT - 32) and not in_junction(u, FRONT - 32) and not is_deck(u, FRONT + 32):
                    m.static("models/props_c17/lamppost03a_on.mdl", u, s * 978, 270 if s > 0 else 90, z=STREET + 8)
                    m.light(u, s * 880, STREET + 400, "255 214 160 220")
            if L >= 1024 and rnd.random() < 0.5 and is_deck(L // 2, 800):
                m.static("models/props_vehicles/car00%da_physics.mdl" % rnd.choice((2, 4, 5)), L // 2 + rnd.randrange(-100, 100), s * rnd.randrange(700, 880), rnd.randrange(0, 360, 15), z=STREET)
        if e.get("lifted"):
            # where the lifted module has open ground higher than the road (a terrace: in the canal the bank was its ramp), a slope up to it
            from map_build import prism
            start, was = None, 0
            for u in list(range(0, L, CELL)) + [L]:
                h = 0
                if u < L:
                    x, y = fr.pt(u + 32, s * (FRONT + 32))
                    spec = cells.get((x // CELL, y // CELL))
                    if spec and spec[0] == "open" and STREET < spec[1] <= STREET + 128:
                        h = spec[1] - STREET
                if h != was:
                    if was:
                        m.shapes([prism([(s * FRONT, STREET), (s * (FRONT - was), STREET), (s * FRONT, STREET + was)], "x", start, u, MAT["canal_wall"])], vis=dv)
                    start, was = u, h
        if e.get("shed"):
            # the shed's mouth: a lintel and a lamp over the tracks
            um = L if e["shed"] == "start" else 0
            v1, v2 = sv(TRACK, ROAD_IN)
            m.det([(um - 8, v1, STREET + SHED_H - 24, um + 8, v2, STREET + SHED_H)], MAT["beam"], vis=dv)
            m.light(um + (-200 if e["shed"] == "start" else 200), s * RAIL_V, STREET + SHED_H - 30, "255 190 120 60")
        # the street's own path nodes
        for u in range(96, L, 256):
            for a in (288, 640, 880):
                if is_deck(u, a):
                    m.lane(u, s * a, STREET + (8 if a == 288 else 0))
    # a viaduct where the street passes over open ground lower down
    slabs = [(i * CELL, j * CELL, STREET - 16, (i + 1) * CELL, (j + 1) * CELL, STREET) for (i, j) in sorted(b.viaduct)]
    piers = [(i * CELL + 16, j * CELL + 16, cells[(i, j)][1], i * CELL + 48, j * CELL + 48, STREET - 16) for (i, j) in sorted(b.viaduct) if i % 4 == 0 and j % 4 == 0]
    if slabs:
        b.vmf.detail(slabs, MAT["beam"], vis=b.vis + ": the street", top=road)
        if piers:
            b.vmf.detail(piers, MAT["canal_wall"], vis=b.vis + ": the street")
        b.notes.append("the street crosses %d squares of lower open ground on a viaduct" % len(slabs))
    # --- the trains ---
    for k, leg in enumerate(legs):
        sheds = [e for e in leg if e.get("shed")]
        if len(sheds) != 2:
            if sheds:
                b.problems.append("a straight run with %d shed (it takes two for a train: one to come out of, one to go into)" % len(sheds))
            continue
        train(b, k + 1, sheds[0], sheds[1], s, cars)
    for e in elems:
        if e.get("lifted"):
            fr, L = e["frame"], e["length"]
            r = fr.rect(0, s * ROAD_IN, L, s * (FRONT + 1600))
            for i in range(r[0] // CELL, r[2] // CELL):
                for j in range(r[1] // CELL, r[3] // CELL):
                    if (i, j) in cells and cells[(i, j)][0] != "solid":
                        b.lifted.add((i, j))


def train(b, n, a, z, s, cars):
    """One train between two sheds: Half-Life 2's Combine engine and cars, as models riding an unseen solid brush."""
    from map_modules import Mod
    import map_assets
    vmf = b.vmf
    tv = b.vis + ": train %d" % n
    name = "lc_train_%d" % n
    fa, fz = a["frame"], z["frame"]
    TL = train_len(cars)
    ua, uz = (a["length"] + 64) // 2, (z["length"] - 64) // 2      # (the middle of each shed's room: its closed end is 64 thick)
    p1, p2 = fa.at(ua, s * RAIL_V, STREET + 9), fz.at(uz, s * RAIL_V, STREET + 9)
    half = TL // 2
    body = fa.box(ua - half, s * RAIL_V - 70, STREET + 12, ua + half, s * RAIL_V + 70, STREET + 290)
    inv = "tools/toolsinvisible"
    vmf.brush_entity("func_tracktrain", {
        "targetname": name, "target": name + "_p1", "origin": "%d %d %d" % p1, "orientationtype": "0", "velocitytype": "0", "startspeed": "700", "speed": "700",
        "height": "0", "wheels": "50", "bank": "0", "dmg": "10000", "spawnflags": "530", "volume": "10", "MoveSound": "ambient/machines/razor_train_wheels_loop1.wav",
        "MoveSoundMinPitch": "60", "MoveSoundMaxPitch": "200", "MoveSoundMinTime": "0", "MoveSoundMaxTime": "0", "ManualSpeedChanges": "0", "ManualAccelSpeed": "0",
        "ManualDecelSpeed": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "disableshadows": "1"}, [body], inv, tv)
    b.names.append((name, "func_tracktrain", "train %d" % n))
    grow = fa.box(ua - half - 8, s * RAIL_V - 80, STREET + 10, ua + half + 40, s * RAIL_V + 80, STREET + 280)
    vmf.brush_entity("trigger_hurt", {"targetname": name + "_hurt", "parentname": name, "StartDisabled": "1", "spawnflags": "3", "damage": "100000", "damagecap": "100000",
                                      "damagetype": "1", "damagemodel": "0", "nodmgforce": "0"}, [grow], MAT["trigger"], tv)
    m = Mod(b, fa, "train %d" % n)
    keys = {"parentname": name, "solid": "0", "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
            "rendercolor": "255 255 255"}
    front = ua + half
    eb = map_assets.size(ENGINE) or [-371, -70, 0, 269, 70, 289]
    m.prop("prop_dynamic", ENGINE, front - int(eb[3]), s * RAIL_V, 0, STREET + 9, dict(keys, targetname=name + "_engine"), tv)
    back = front - ENGINE_LEN
    for k in range(cars):
        m.prop("prop_dynamic", CAR, back - GAP - CAR_LEN // 2 - k * (CAR_LEN + GAP), s * RAIL_V, 90, STREET + 9, dict(keys, targetname="%s_car_%d" % (name, k + 1)), tv)
    vmf.point("path_track", p1, {"targetname": name + "_p1", "target": name + "_p2", "spawnflags": "16", "orientationtype": "0", "speed": "0", "radius": "0"}, tv)
    vmf.point("path_track", p2, {"targetname": name + "_p2", "target": name + "_p1", "spawnflags": "0", "orientationtype": "0", "speed": "0", "radius": "0"}, tv,
              connections=[("OnPass", name, "Stop", "", 0), ("OnPass", name + "_hurt", "Disable", "", 0.1)])
    mouth = fa.at(a["length"], s * RAIL_V, STREET + 200)
    for snd, msg, pos in (("_horn", "ambient/alarms/razortrain_horn1.wav", mouth),):
        vmf.point("ambient_generic", pos, {"targetname": name + snd, "message": msg, "health": "10", "pitch": "100", "pitchstart": "100", "radius": "6000",
                                           "spawnflags": "48", "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0",
                                           "lfotype": "0", "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, tv)
    vmf.point("logic_relay", (mouth[0], mouth[1], mouth[2] + 16), {"targetname": name + "_run", "StartDisabled": "0", "spawnflags": "0"}, tv,
              connections=[("OnTrigger", name + "_horn", "PlaySound", "", 0), ("OnTrigger", name + "_hurt", "Enable", "", 2.5), ("OnTrigger", name, "StartForward", "", 3)])
    vmf.point("logic_timer", (mouth[0], mouth[1], mouth[2] + 32), {"targetname": name + "_timer", "UseRandomTime": "1", "LowerRandomBound": "70", "UpperRandomBound": "240",
                                                                   "RefireTime": "120", "StartDisabled": "0", "spawnflags": "0"}, tv,
              connections=[("OnTimer", name + "_run", "Trigger", "", 0)])
    for nm, cls in ((name + "_run", "logic_relay"), (name + "_timer", "logic_timer"), (name + "_hurt", "trigger_hurt"), (name + "_horn", "ambient_generic")):
        b.names.append((nm, cls, "train %d" % n))
    v1, v2 = (s * 262, s * 270) if s > 0 else (s * 270, s * 262)
    fr_ = front_line(b) - (72 if getattr(b, "street_wall", None) == "combine" else 0)      # (before a Combine wall's battered foot)
    fv1, fv2 = sorted((s * (fr_ - 8), s * fr_))      # (on the frontage's wall, facing the road: a walker stands on the pavement to press it)
    m.test_button((a["length"] + 40, fv1, STREET + 44, a["length"] + 56, fv2, STREET + 60), [("OnIn", name + "_run", "Trigger"), ("OnOut", name + "_run", "Trigger")])
    m.view(a["length"] + 500, -s * 120, 400, 180, -22, "from the canal, toward the shed")
    m.view(a["length"] + 420, s * 760, STREET, 180, 0, "on the road, toward the shed")
    run = abs(p2[0] - p1[0]) + abs(p2[1] - p1[1])
    b.notes.append("train %d: an engine and %d cars (%d long) from the shed in %s to the shed in %s, %d of track, about %d seconds a pass, at random every 70 to 240 seconds" % (
        n, cars, TL, a["tag"], z["tag"], run, run // 700))


def spur(b, x1, y1, x2, y2, z_end, ids=()):
    """A road from the street's frontage (x1, at the street's height) east to x2, where it meets a road of the owner's at
    z_end: built for the canal ring's join to the owner's west road (the owner, 23 November: the road and the railway
    between the city and the canal; their west road ends at brush 14734, x -2624..-2608, y 1920..2560, z 840). Squares
    stepping up a little at a time under one smooth slope of road, building fronts either side, and where the owner's
    brush was the road carried on to theirs, a wall each side and a lid (as roadend did); stopped up for the seal check."""
    from map_build import prism
    from map_modules import BASE, MM, Frame, Mod
    plan, cells = b.plan, b.plan.cells
    m = Mod(b, Frame(0, 0, 0, max(1, x2 - x1)), "the road to the owner's")
    n = (x2 - x1) // CELL
    for k in range(n):
        z = STREET + (z_end - STREET) * k // n           # (each square's floor under the slope's height at its near edge)
        for j in range(y1 // CELL, y2 // CELL):
            cells[(x1 // CELL + k, j)] = ("open", z, MM["road"])
            b.owner[(x1 // CELL + k, j)] = "the road to the owner's"
    for k in range(-1, n + 1):                           # (building fronts along both sides, brick to the frontage's top)
        for j in (y1 // CELL - 1, y2 // CELL):
            plan.front.add((x1 // CELL + k, j))
    b.vmf.detail_shapes([prism([(x2, STREET - 8), (x2, z_end), (x1, STREET), (x1, STREET - 8)], "y", y1, y2, MM["road"])], b.vis + ": the street")
    # where the owner's brush was: the road carried on to theirs, a wall each side, a lid, the sky their road sees
    cw, sky = MAT["canal_wall"], MAT["sky"]
    m.world((x2, y1, BASE, x2 + 16, y2, z_end), cw, top=MM["road"])
    m.world((x2, y1 - 64, BASE, x2 + 16, y1, b.sky + 16), cw)
    m.world((x2, y2, BASE, x2 + 16, y2 + 64, b.sky + 16), cw)
    m.world((x2, y1, b.sky, x2 + 16, y2, b.sky + 16), sky)
    m.portal(x2 + 6, y1, z_end, x2 + 8, y2, b.sky)      # (in the end's own walls: floor, sides and lid all world)
    b.plan.keep_out.append((x2, y1 - 64, x2 + 4096, y2 + 64))
    b.stoppers.append((x2 + 16, y1 - 64, BASE, x2 + 80, y2 + 64, b.sky + 16))
    b.allow.append((x2 - 64, y1 - 128, BASE, x2 + 128, y2 + 128, b.sky + 64))
    b.replaces |= set(ids)
    if b.test:
        m.world((x2 + 16, y1 - 64, BASE, x2 + 80, y2 + 64, b.sky + 16), sky, vis=b.vis + ": for testing alone (never in the real map)")
    # lamps along its south side, path nodes up its middle
    for x in range(x1 + 256, x2 - 128, 512):
        z = STREET + (z_end - STREET) * (x - x1) // (x2 - x1)
        m.static("models/props_c17/lamppost03a_on.mdl", x, y1 + 40, 90, z)
        m.light(x, y1 + 80, z + 300, "255 214 170 250")
    for x in range(x1 + 64, x2, 256):
        m.lane(x, (y1 + y2) // 2, STREET + (z_end - STREET) * (x - x1) // (x2 - x1))
    b.notes.append("the road to the owner's: from the street at (%d %d) up to their road at (%d %d), z %d to %d" % (x1, (y1 + y2) // 2, x2, (y1 + y2) // 2, STREET, z_end))


def front_line(b):
    """How far from the canal's middle the frontage stands: FRONT, or behind a Combine wall 64 farther (its battered foot
    and ribs stand on the pavement before it)."""
    return FRONT + (64 if getattr(b, "street_wall", None) == "combine" else 0)


def combine_core(b, shed_front):
    """The Combine wall's core (the owner, 23 November: "it makes more sense to have the combine wall between the city
    and the road/railroad ... City > combine wall > road > railroad > canal"): every empty square beside the street on
    its far side (its frontage, round its corners, across its ends) becomes a sealing core WALL_H high less 8, with air
    over it up to the sky so the wall's piers, head and fins stand clear; combine_wall dresses it."""
    cells = b.plan.cells
    street = set(b.deck)
    keep = b.plan.keep_out

    def kept(c, pad=0):
        x, y = c[0] * CELL + 32, c[1] * CELL + 32
        return any(r[0] - pad <= x < r[2] + pad and r[1] - pad <= y < r[3] + pad for r in keep)
    core = set()
    for (i, j) in street:
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c = (i + di, j + dj)
            if c not in cells and c not in shed_front and c not in core and not kept(c, CELL):
                core.add(c)      # (never in, nor beside, a place kept for another piece: the plain wall stays there)
    for c in core:
        cells[c] = ("low", STREET + WALL_H - 8, CORE, b.sky)
        b.owner[c] = "the Combine wall"
    b.combine_core = core


def combine_wall(b, seed=1):
    """The Combine wall along its core: each straight stretch (5 squares or more) a row of wall_chain's runs 512 to 1024
    long, laid straight, their battered ribbed faces to the street, a pier with its lamp over every joint and at both
    ends (map_combine.py's perimeter, combine/chain.py). What a stretch leaves short stays plain metal."""
    import random as _r
    from combine.chain import pier, run
    from combine.geom import Frame as CF
    from combine.piece import Piece, Sink
    from combine.scene import put
    core = getattr(b, "combine_core", set())
    if not core:
        return
    r = _r.Random("wall %s %d" % (b.name, seed))
    sink = Sink()
    street = set(b.deck)
    segs = []
    for axis in ("x", "y"):
        lines = {}
        for (i, j) in core:
            lines.setdefault(j if axis == "x" else i, []).append(i if axis == "x" else j)
        for row, ks in lines.items():
            ks.sort()
            start = prev = ks[0]
            for k in ks[1:] + [None]:
                if k is not None and k == prev + 1:
                    prev = k
                    continue
                if prev - start + 1 >= 5:
                    cellsof = [((t, row) if axis == "x" else (row, t)) for t in range(start, prev + 1)]
                    lo = sum(1 for (i, j) in cellsof if ((i, j - 1) if axis == "x" else (i - 1, j)) in street)
                    hi = sum(1 for (i, j) in cellsof if ((i, j + 1) if axis == "x" else (i + 1, j)) in street)
                    if lo or hi:
                        segs.append((axis, row, start, prev + 1, -1 if lo >= hi else 1))
                if k is not None:
                    start = prev = k
    for axis, row, a, c, side in segs:
        L = (c - a) * CELL
        if axis == "x":      # (the street to the south (side -1) or north; the wall's face on the core's street side)
            o, d = ((a * CELL, row * CELL), (1, 0)) if side < 0 else ((c * CELL, (row + 1) * CELL), (-1, 0))
        else:
            o, d = ((row * CELL, c * CELL), (0, -1)) if side < 0 else (((row + 1) * CELL, a * CELL), (0, 1))
        u, runs_ = 0, []
        while L - u >= 320:
            k = min(r.choice((512, 640, 768, 896, 1024)), L - u)
            if L - u - k < 320:
                k = L - u
            fr = CF((o[0] + d[0] * u, o[1] + d[1] * u, STREET), d)
            runs_.append((Piece(fr, (k, 0), WALL_H, r, sink), k))
            u += k
        for n, (p, k) in enumerate(runs_):
            T, Le, Pl = run(p, k, WALL_H, r)
            pier(p, 0, WALL_H, r, T, Le, Pl, lamp=n % 2 == 0)
            if n == len(runs_) - 1:
                pier(p, k, WALL_H, r, T, Le, Pl, lamp=True)
    put(b.vmf, sink, b.vis + ": the Combine wall")
    b.notes.append("the Combine wall between the city and the street: %d stretches, %d runs, %d lamps" % (len(segs), sum(1 for _ in sink.solids) and len(segs), len(sink.lamps)))

