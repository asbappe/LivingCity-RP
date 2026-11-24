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

    256..320    the canal's edge: a low parapet with chain link panels (props) on it, and where stairs from the canal come up
    320..512    the railway: ballast, sleepers, two rails
    512..576    a kerb between the tracks and the road, and the inner pavement
    576..960    the roadway
    960..1024   the outer pavement
    1024..      the frontage: a brick wall of blind windows, or a module lifted up here

A module's line may end in "up": then the whole module is built lifted to the street. Its own canal
becomes the road (512 wide in both), its left wall the frontage, and everything in it is 256 higher;
the real canal passes below as a plain stretch, with stairs up from it and a plank crossing over the
tracks. Nothing in the module's own code changes.

The trains: Half-Life 2's own Combine train (an engine and cars, as models riding an unseen brush),
solid, killing what it hits, sent at random intervals behind its horn. Where a turn toward the street
is marked "over" or "back" (rail_runs), a run's track is carried straight on through the square where
the two streets cross, over a bridge across the other run's canal and into a tunnel in its outer wall:
black a little way in, and beyond that solid ground where the train waits unseen. It comes out, runs
along the run and backs into its tunnel (or, with a tunnel at each end, goes into the other and is put
back unseen). Every other track end is a buffer stop short of the crossing square. The older way, still
used by the street test layouts: a straight run with two "shed" lines, a brick shed over the tracks at
each, the train running from one to the other.
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
                  "press": "up", "still": "up", "garden": "up", "playground": "up", "pumphouse": "up", "hq": "up", "memorial": "up", "pit": "up",
                  "plaza": "up", "flats": "up"}
ENGINE, CAR = "models/props_combine/combinetrain01a.mdl", "models/props_combine/combine_train02a.mdl"
ENGINE_LEN, CAR_LEN, GAP = 640, 628, 16
TUN = 256               # how far a train's tunnel runs into the ground beyond the canal's outer wall before its black end
DECK_UNDER = STREET - 48    # the underside of a train's bridge (its cross girders): what stairs under it must clear by 72
SPEED = 700             # the trains' speed, and the slower one they come to a stop at
STOP_SPEED = 120
STRIPE = "dev/dev_hazzardstripe01a"      # (as the owner's map paints its edges)
# One sleeper a square, 16 wide, its underside on the ballast never drawn (there were two, 12 wide: 1,668 brushes round the
# ring; the owner's compile of it ran out of faces, 23 November). TIE: where it lies in each 64 of track.
TIE = (24, 40)
POST = 256              # the kerb rail's and the edge's chain link's posts, one every POST (were 128)


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
                self.sky_box(x1, y1, top, x2, y2, self.top, sky)      # (every sky box joined at the end: Plan.sky_box)
                continue
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, spec[1]), CORE if spec[2] == CORE else self.floor_side, top=spec[2], vis=self.vis)
            if kind == "open":
                lid = spec[3] if len(spec) > 3 and spec[3] else self.sky      # (a square with a sky of its own, higher: a church's yard)
                self.sky_box(x1, y1, lid, x2, y2, max(self.top, lid + 16), sky, sky, sky)
            elif kind == "cellar":      # (a room under a yard open to the sky: Plan's own)
                ceil, upper, upper_mat, lid = spec[3], spec[4], spec[5], spec[6]
                vmf.world_box(self.box(x1, y1, ceil, x2, y2, upper), self.floor_side, top=upper_mat, bottom=self.ceiling, vis=self.vis)
                self.sky_box(x1, y1, lid, x2, y2, max(self.top, lid + 16), sky, sky, sky)
            elif kind == "under":
                vmf.world_box(self.box(x1, y1, spec[3], x2, y2, STREET), cw, top=spec[4], bottom=self.ceiling, vis=self.vis)
                self.sky_box(x1, y1, self.sky, x2, y2, self.top, sky, sky, sky)
            else:
                top = spec[4]
                if top > spec[3]:
                    vmf.world_box(self.box(x1, y1, spec[3], x2, y2, top), brick if spec[5] and spec[3] >= STREET else cw, top=cw, bottom=self.ceiling, vis=self.vis)
                self.sky_box(x1, y1, top, x2, y2, self.top, sky, bottom=None if top > spec[3] else (sky if spec[2] == CORE else self.ceiling))
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
    plan_runs = rail_runs(b, elems, s, cars)      # (where each run's track ends, and how: its tunnels' squares painted, their bridges noted)

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
                band(fr, 0, TRACK, L, ROAD_IN, road if e.get("no_track") else gravel, e["tag"])
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
        ra = a["frame"].rect(a["length"] - FR - 64, s * (EDGE + 64), a["length"], s * (FR + 64))      # (from beyond the parapet: the canal's edges keep theirs)
        rz = z["frame"].rect(0, s * (EDGE + 64), FR + 64, s * (FR + 64))      # (the whole square, however short the stretch next to the turn is: a 128 one left both pavements running on across the corner, the owner, 24 November)
        x1, y1, x2, y2 = max(ra[0], rz[0]), max(ra[1], rz[1]), min(ra[2], rz[2]), min(ra[3], rz[3])
        crossing = "rail_span" in a and "rail_span" in z      # (both runs' tracks end short of it, or one is carried across: all road)
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                junction.add((i, j))
                spec = cells.get((i, j))
                if crossing and spec and spec[0] == "open" and spec[1] == STREET:
                    cells[(i, j)] = spec[:2] + (road,) + spec[3:]
                elif crossing and spec and spec[0] == "under":
                    cells[(i, j)] = spec[:4] + (road,)

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
            # stairs from the canal's floor up its wall to the street, and planks across the tracks at their head (u0: their
            # foot; d: the way they climb, the other way or elsewhere on the stretch where a train's bridge crosses over)
            u0, d = stair_spot(b, fr, L)
            v1, v2 = sv(192, 256)
            m.steps(u0, v1, v2, F, STREET, "u", d)
            a1, a2 = sorted((u0, u0 - d * 48))
            m.det([(a1, v1, F, a2, v2, F + 2)], MAT["canal_wall"], top=MAT["quay_floor"])      # (an apron at their foot: the mud kept level there)
            n1, n2 = sorted((u0 - d * 8, u0 + d * 384))      # (the bank runs on right up to the stairs' back: the owner, 23 November)
            m.no_bank(n1, s * 256 - 8, n2, s * 256 + 8)
            k1, k2 = sorted((u0, u0 + d * 392))
            m.blocked(k1, v1, k2, v2)
            t1, t2 = sorted((u0, u0 + d * 384))
            m.taken(t1, v1, F, t2, v2, STREET)
            top = tuple(sorted((u0 + d * 384, u0 + d * 448)))
            stairs.append((top[0] - 64, top[1]) if d > 0 else (top[0], top[1] + 64))      # (the parapet stops a square short: its top steps step off sideways onto the street)
            over = e.get("rail_span") is None or e["rail_span"][0] <= top[0] and top[1] <= e["rail_span"][1]      # (no planks where the track has ended short)
            if over:
                m.det([(top[0], sv(TRACK, ROAD_IN)[0], STREET, top[1], sv(TRACK, ROAD_IN)[1], STREET + 9)], MM["wood"], vis=dv)
            m.lane(u0 - d * 24, s * 224, F)
            m.lane(u0 + d * 190, s * 224, F + 128)
            m.lane(top[0] + 32, s * 288, STREET)
            m.lane(top[0] + 32, s * RAIL_V, STREET + (9 if over else 0))
            m.lane(top[0] + 32, s * 544, STREET)
            e["crossing"] = top
            m.view(u0 - d * 60, s * 150, F, (20 if s > 0 else 340) if d > 0 else (160 if s > 0 else 200), -16, "the stairs up to the street")
        # the canal's edge: a low parapet, chain link on it (not where a bridge meets the street: b.edge_gaps)
        for u in range(0, L, CELL):
            px, py = fr.pt(u + 32, s * (EDGE + 6))
            if any(r[0] <= px <= r[2] and r[1] <= py <= r[3] for r in b.edge_gaps):
                stairs.append((u, u + CELL))
        for a, c in runs(EDGE + 32, stairs):
            v1, v2 = sv(EDGE, EDGE + 12)
            m.det([(a, v1, STREET, c, v2, STREET + 40)], MAT["beam"], vis=dv)
            edge_fence(b.vmf, fr, a, c, s * (EDGE + 6), STREET + 40, dv)
        # the tracks: sleepers and two rails wherever there is ballast, in the open and in the sheds; on a run whose ends
        # rail_runs planned, only between those ends, and across the square where two streets cross the rails alone
        # (laid in its road)
        ties, rails = [], []
        start = None
        span = e.get("rail_span")
        for u in range(0, L + 1, CELL):
            x, y = fr.pt(u + 32, s * RAIL_V)
            c = (x // CELL, y // CELL)
            ok = u < L and (c in b.deck or c in b.sheds or c in b.viaduct) and (span is None or span[0] <= u <= span[1] - CELL)
            if ok and not (span is not None and c in junction):
                v1, v2 = sv(RAIL_V - 68, RAIL_V + 68)
                ties.append((u + TIE[0], v1, STREET, u + TIE[1], v2, STREET + 3))
            if ok and start is None:
                start = u
            elif not ok and start is not None:
                for g in (-40, 37):
                    v1, v2 = sv(RAIL_V + g, RAIL_V + g + 3)
                    rails.append((start, v1, STREET + 3, u, v2, STREET + 9))
                start = None
        if ties:
            m.det(ties, MM["beam_wood"], vis=dv, faces={"bottom": MAT["nodraw"]})
            m.det(rails, MAT["bars"], vis=dv)
        # between the tracks and the road: the inner pavement and its kerb
        for a, c in ([] if e.get("no_track") else runs(ROAD_IN + 32)):
            v1, v2 = sv(ROAD_IN, ROAD_OUT)
            m.det([(a, v1, STREET, c, v2, STREET + 8)], walk, vis=dv)
        # (no rail between the tracks and the road: the owner, 24 November, "remove the hand railing between the railroad and the road/sidewalk")
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
    for r in plan_runs:      # (the planned runs: buffer stops, bridges and tunnels, and a train where a tunnel is)
        rail_ends(b, r, s, cars, junction)
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


def inside_turn(e, s):
    """A turn toward the street's side (the two runs' streets cross in a square there), or not."""
    return bool(e) and e["kind"] in ("left", "right") and (e["kind"] == "left") == (s > 0)


def back_frame(R):
    """A run's frame turned round: u from its far end back, v to the other side (so a track end at the run's far end
    is built as one at its start)."""
    from map_modules import Frame
    x, y = R.pt(R.length, 0)
    return Frame(x, y, R.rot + 2, R.length)


def in_frame(fr, x, y):
    """The (u, v) of a point of the map in a frame neither flipped nor moved over."""
    return {0: (x - fr.x, y - fr.y), 1: (y - fr.y, fr.x - x), 2: (fr.x - x, fr.y - y), 3: (fr.y - y, x - fr.x)}[fr.rot]


def hide_len(cars):
    """How far the solid a train waits in reaches beyond its tunnel's black end: the train, and room each side."""
    return (train_len(cars) + 192 + 63) // 64 * 64


def squares(r):
    for i in range(r[0] // CELL, -(-r[2] // CELL)):
        for j in range(r[1] // CELL, -(-r[3] // CELL)):
            yield (i, j)


def rail_runs(b, elems, s, cars):
    """The street's straight runs and how each one's track ends (the owner, 23 November, of the trains' sheds: "it's
    just a box where the train comes out for some reason ... Can we maybe instead have them either come from out of view
    (like the far side with the ruins/dead trees) through a tunnel or something with a black void that the player can't
    pass through and cross over top the canal via a bridge and then go onto the train tracks? They should also exit in
    the same fashion"; and of the tracks at a corner: "here the train tracks just awkwardly cross and end at the
    fence/canal? what on earth?").

    A run is the legs between two turns or gaps. Its track ends one of three ways:
      tunnel    at a turn toward the street marked for it in the layout: "left back" (the run after the turn carries its
                track back, straight on past the corner) or "left over" (the run before carries its track on). The track
                crosses the square where the two streets meet (a level crossing), a bridge over the other run's canal
                (crossing_build) and goes into a tunnel in that canal's outer wall, black a little way in; beyond, the
                train waits unseen in solid ground (hide_trains). A train is rigid and cannot bend round a curve, so this
                is how it comes and goes. Both words at one corner would cross two tracks in its square: refused.
      junction  at any other turn toward the street: a buffer stop a square short of the crossing square, so no track
                runs across the other road or ends against the canal's fence.
      open      at a turn away from the street (the road goes round its outside), a gap or the chain's end: a buffer
                stop a square from the end.
    A run with sheds keeps its tracks and train as they were (the street test layouts). Every leg of a planned run gets
    "rail_span": the stretch of its own u the track covers."""
    from map_modules import Frame
    FR = front_line(b)
    b.rail_bridges, b.rail_hides = [], []
    for k, e in enumerate(elems):
        if e["kind"] in ("left", "right"):
            e["junction"] = inside_turn(e, s) and 0 < k < len(elems) - 1 and elems[k - 1]["kind"] == "leg" and elems[k + 1]["kind"] == "leg"
            rail = e.get("rail", [])
            if rail and not e["junction"]:
                b.problems.append("%s: \"over\" and \"back\" (a train's tunnel) go only on a turn toward the street's side with the street on both runs" % e["tag"])
            if "over" in rail and "back" in rail:
                b.problems.append("%s: \"over\" and \"back\" at one corner would cross the two tracks in its square: keep one" % e["tag"])
    runs, cur, before = [], [], None
    for e in elems + [None]:
        if e is not None and e["kind"] == "leg":
            cur.append(e)
            continue
        if cur:
            runs.append({"legs": cur, "before": before, "after": e})
        cur, before = [], e
    for n, r in enumerate(runs):
        legs = r["legs"]
        f0 = legs[0]["frame"]
        L = sum(e["length"] for e in legs)
        R = Frame(f0.x, f0.y, f0.rot, L)
        r.update(n=n + 1, L=L, frame=R, tag="%s to %s" % (legs[0]["tag"], legs[-1]["tag"]), tunnels=[], ends=None)
        if any(e.get("shed") for e in legs):
            continue
        ends = []
        for which, t in (("start", r["before"]), ("end", r["after"])):
            if not (t and t.get("junction")):
                ends.append("open")
                continue
            if ("back" if which == "start" else "over") not in t.get("rail", ()):
                ends.append("junction")
                continue
            Q, sq = (R, s) if which == "start" else (back_frame(R), -s)
            tag = "the train's tunnel at the %s" % t["tag"]
            if crossing_squares(b, Q, sq, tag, cars):
                r["tunnels"].append((which, Q, sq, tag))
                ends.append("tunnel")
            else:
                ends.append("junction")
        ua = {"tunnel": -(512 + TUN), "junction": FR + 128, "open": 64}[ends[0]]
        ub = {"tunnel": L + 512 + TUN, "junction": L - FR - 128, "open": L - 64}[ends[1]]
        if ub - ua < 256:
            b.notes.append("the run %s is too short for a track between its ends" % r["tag"])
            ua = ub = 0
        if "tunnel" not in ends:
            # (a run no train can reach has no track at all: the owner, 24 November, of a length of rails between two
            # buffer stops and the corner beside it, "two roads end, intersected by redundant sidewalks and train tracks
            # ending, all of it is rubbish". Its track bed is road, with no kerb between: the road runs to the canal's edge)
            ua = ub = 0
            for e in legs:
                e["no_track"] = True
            b.notes.append("the run %s has no train's tunnel at either end: no track on it, its road runs to the canal's edge" % r["tag"])
        r.update(ends=ends, ua=ua, ub=ub)
        o = 0
        for e in legs:
            e["rail_span"] = (ua - o, ub - o)
            o += e["length"]
    return runs


def crossing_squares(b, Q, sq, tag, cars):
    """Before the street is laid (rail_runs): see that the canal a train's bridge crosses is plain open canal with
    nothing of a module's on its walls there, and that nothing stands where the tunnel and the hidden train go; then
    paint the tunnel's squares and note the bridge (for the parapet's gap and the stairs: stair_spot). Q: the run's
    frame with the track carried on to u < 0 (the canal it crosses is u -512..0, its outer wall at u -512); sq: the
    street's side in Q. Gives whether it can be built."""
    from map_modules import F, MM, Mod
    from map_backdrop import GROUND
    lo, hi = sorted((sq * (RAIL_V - 160), sq * (RAIL_V + 160)))
    wall = -(512 + TUN)
    if b.rim < STREET + 312:
        b.problems.append("%s: the canal's walls (rim %d) are too low for a train's tunnel through them (it needs %d)" % (tag, b.rim, STREET + 312))
        return False
    for c in squares(Q.rect(-512, lo, 0, hi)):
        spec = b.plan.cells.get(c)
        if spec is None or spec[0] != "open" or spec[1] != F:
            b.problems.append("%s: the canal its bridge crosses is not plain open canal at (%d %d) (%s)" % (tag, c[0] * CELL, c[1] * CELL, b.owner.get(c, "nothing")))
            return False
    box = Q.box(-512, sq * (RAIL_V - 220), DECK_UNDER - 16, 0, sq * (RAIL_V + 220), b.rim + 16)
    for t in b.taken:
        if t[0] < box[3] and t[3] > box[0] and t[1] < box[4] and t[4] > box[1] and t[2] < box[5] and t[5] > box[2]:
            b.problems.append("%s: its bridge or its tunnel's mouth runs into something of a module's on the canal's walls at (%d %d %d)" % (tag, t[0], t[1], t[2]))
            return False
    for c in squares(Q.rect(wall - hide_len(cars), lo - 64, -512, hi + 64)):      # (the tunnel, the hidden train, a square round them)
        spec = b.plan.cells.get(c)
        if spec is not None and not (spec[0] == "solid" or (spec[0] == "open" and spec[1] >= STREET + 304)):
            b.problems.append("%s: the tunnel or the train hidden beyond it runs into %s at (%d %d)" % (tag, b.owner.get(c, "something"), c[0] * CELL, c[1] * CELL))
            return False
    m = Mod(b, Q, tag)
    # (a room under ground at the rim: the backdrop puts its own sky over it; its roof 8 thick, the train 290 high)
    m.cellar(wall, lo, -512, hi, STREET, b.rim - 8, b.rim, mat=MM["gravel"], upper_mat=GROUND)
    b.rail_bridges.append((Q.rect(-512, lo, 0, hi), DECK_UNDER))
    e1, e2 = sorted((sq * (RAIL_V - 150), sq * (RAIL_V + 150)))
    b.edge_gaps.append(Q.rect(-8, e1, 24, e2))      # (the crossed run's parapet stops at the bridge's girders)
    b.rail_hides.append((Q, sq, tag, hide_len(cars)))
    return True


def stair_spot(b, fr, L):
    """Where a stretch's stairs up to the street stand (the foot's u, and 1 if they climb along u, -1 if back): the
    middle as ever, unless a train's bridge crosses over the canal there (rail_runs); then the other way, or elsewhere
    on the stretch, so their top is clear of it and every tread has 72 of headroom under it."""
    from map_modules import F
    u0 = max(64, min(L - 512, L // 2 - 256) // 64 * 64)
    bridges = []
    for rect, under in getattr(b, "rail_bridges", []):
        r = fr.rect(0, -256, L, 256)
        if rect[0] < r[2] and rect[2] > r[0] and rect[1] < r[3] and rect[3] > r[1]:
            us = [in_frame(fr, rect[0], rect[1])[0], in_frame(fr, rect[2], rect[3])[0]]
            bridges.append((min(us), max(us), under))
    if not bridges:
        return u0, 1

    def fits(foot, d):
        lo, hi = sorted((foot - d * 48, foot + d * 448))
        if lo < 0 or hi > L:
            return False
        land = sorted((foot + d * 384, foot + d * 448))
        for b1, b2, under in bridges:
            if land[0] < b2 + 16 and land[1] > b1 - 16:
                return False
            for u in range(max(lo, b1 - 16), min(hi, b2 + 16) + 1, 8):
                along = (u - foot) * d
                if 0 <= along <= 384 and F + along * 2 // 3 + 72 > under:
                    return False
        return True
    tries = [(u0, 1)] + [(f, -1) for f in range(L - 64, 383, -64)] + [(f, 1) for f in range(64, L - 447, 64)]
    for foot, d in tries:
        if fits(foot, d):
            return foot, d
    b.problems.append("stairs up to the street at (%d %d): no room for them clear of the train's bridge over the canal there" % fr.pt(u0, 0))
    return u0, 1


def first_in_way(b, Q, sq, u1, u2):
    """The first thing (a brush, a shape, a prop) standing in a train's way over its rails between u1 and u2 in Q:
    (its u, its box), or None."""
    import map_assets
    lo, hi = sorted((sq * (RAIL_V - 76), sq * (RAIL_V + 76)))
    r = Q.rect(u1, lo, u2, hi)
    z1, z2 = STREET + 12, STREET + 298
    boxes = [bx for bx, _ in b.vmf.boxes] + list(b.vmf.shape_boxes)
    for cls, place, model, yaw in getattr(b.vmf, "props", []):      # (a prop standing on the line: a lamp's arm high over it is no matter)
        sz = map_assets.size(model)
        if sz and r[0] - 24 < place[0] < r[2] + 24 and r[1] - 24 < place[1] < r[3] + 24:
            boxes.append((place[0] - 24, place[1] - 24, place[2] + sz[2], place[0] + 24, place[1] + 24, place[2] + sz[5]))
    best = None
    for bx in boxes:
        if bx[0] < r[2] and bx[3] > r[0] and bx[1] < r[3] and bx[4] > r[1] and bx[2] < z2 and bx[5] > z1:
            u = max(u1, min(in_frame(Q, bx[0], bx[1])[0], in_frame(Q, bx[3], bx[4])[0]))
            if best is None or u < best[0]:
                best = (u, tuple(int(q) for q in bx[:6]))
    return best


def rail_ends(b, r, s, cars, junction):
    """A planned run's track ends (rail_runs): a buffer stop at each end that has no tunnel; at each tunnel the bridge,
    the tunnel's mouth and the rails into it; and the run's train where it has a tunnel."""
    if not r.get("ends") or r["ub"] <= r["ua"]:
        return
    R = r["frame"]
    for which, kind in zip(("start", "end"), r["ends"]):
        if kind != "tunnel":
            buffer_stop(b, R, s, r["ua"] if which == "start" else r["ub"], -1 if which == "start" else 1, "the track's end on %s" % r["tag"])
    for which, Q, sq, tag in r["tunnels"]:
        crossing_build(b, Q, sq, tag)
    if len(r["tunnels"]) == 2:
        tunnel_train(b, r["n"], R, s, r["L"] + 512 + TUN, cars, r, junction, through=True)
    elif r["tunnels"]:
        which, Q, sq, tag = r["tunnels"][0]
        tunnel_train(b, r["n"], Q, sq, r["ub"] if which == "start" else r["L"] - r["ua"], cars, r, junction)


def buffer_stop(b, fr, sq, u, d, tag):
    """A track's end in the open: a concrete block across the ballast, a hazard stripe along its face, a steel buffer
    where each rail meets it, and Half-Life 2's track lamp on it, lit red (steady: the owner wants no flicker). u: where
    the rails end; d: 1 when the block stands beyond u (the run's far end), -1 before it (its start)."""
    from map_modules import MM, Mod
    m = Mod(b, fr, tag)
    dv = b.vis + ": the street"

    def sv(a, c):
        return tuple(sorted((sq * a, sq * c)))
    face = u + d * 16                                  # (the block's face toward the rails: the buffers fill the 16 to it)
    u1, u2 = sorted((face, face + d * 48))
    v1, v2 = sv(TRACK + 16, ROAD_IN - 16)
    m.det([(u1, v1, STREET, u2, v2, STREET + 64)], MAT["canal_wall"], vis=dv)
    f1, f2 = sorted((face, face - d * 1))
    m.det([(f1, v1, STREET + 34, f2, v2, STREET + 54)], STRIPE, vis=dv)
    pads = []
    for g in (-38, 38):
        p1, p2 = sv(RAIL_V + g - 10, RAIL_V + g + 10)
        b1, b2 = sorted((face - d * 1, face - d * 16))
        pads.append((b1, p1, STREET + 22, b2, p2, STREET + 42))
    m.det(pads, MM["steel"], vis=dv)
    cu = (u1 + u2) // 2
    m.static("models/props_trainstation/tracklight01.mdl", cu, sq * RAIL_V, 180 if d > 0 else 0, z=STREET + 64 + 23)
    m.glow(cu - d * 8, sq * RAIL_V, STREET + 64 + 32, "255 40 30", 0.2)
    m.light(cu - d * 40, sq * RAIL_V, STREET + 110, "255 50 40 18")


def crossing_build(b, Q, sq, tag):
    """A train's bridge and tunnel (crossing_squares painted the tunnel), in Q (the canal crossed is u -512..0): a
    through plate girder bridge at the street's height (its two girders the railings, their outer faces on the
    tunnel's sides, cross girders under its deck, ballast, sleepers and rails on it), the tunnel's mouth framed by two
    pilasters in the canal's outer wall with a railway signal head beside it and its number and a danger sign
    stencilled on, ribs inside, and its black end TUN in, which nobody passes; the rails run on to it."""
    from map_modules import F, MM, Mod
    m = Mod(b, Q, tag)
    dv = b.vis + ": the trains' bridges and tunnels"
    steel = MM["steel"]
    wall = -(512 + TUN)
    ceil = b.rim - 8

    def sv(a, c):
        return tuple(sorted((sq * a, sq * c)))
    lo, hi = sv(RAIL_V - 160, RAIL_V + 160)
    d1, d2 = sv(RAIL_V - 144, RAIL_V + 144)
    m.det([(-512, d1, STREET - 24, 0, d2, STREET)], MAT["beam"], top=MM["gravel"], vis=dv)
    m.det([(u, d1, DECK_UNDER, u + 12, d2, STREET - 24) for u in range(-470, -12, 96)], steel, vis=dv)
    girders, stiff = [], []
    for g in (-1, 1):
        w1, w2 = sv(RAIL_V + g * 144, RAIL_V + g * 160)
        f1, f2 = sv(RAIL_V + g * 138, RAIL_V + g * 160)
        girders += [(-512, w1, DECK_UNDER + 4, 0, w2, STREET + 64), (-512, f1, STREET + 64, 0, f2, STREET + 70), (-512, f1, DECK_UNDER, 0, f2, DECK_UNDER + 4)]
        o1, o2 = sv(RAIL_V + g * 140, RAIL_V + g * 144)
        stiff += [(u, o1, STREET, u + 6, o2, STREET + 64) for u in range(-483, -8, 64)]
    m.det(girders, steel, vis=dv)
    m.det(stiff, MAT["bars"], vis=dv)
    # the rails, on the bridge and into the tunnel to its black end
    ties, rails = [], []
    t1, t2 = sv(RAIL_V - 68, RAIL_V + 68)
    for u in range(wall + 64, 0, 64):
        ties.append((u + TIE[0], t1, STREET, u + TIE[1], t2, STREET + 3))
    m.det(ties, MM["beam_wood"], vis=dv, faces={"bottom": MAT["nodraw"]})
    for g in (-40, 37):
        r1, r2 = sv(RAIL_V + g, RAIL_V + g + 3)
        rails.append((wall + 8, r1, STREET + 3, 0, r2, STREET + 9))
    m.det(rails, MAT["bars"], vis=dv)
    # the tunnel: its black end, ribs on its walls, the mouth's pilasters (2 into the wall, the trim's ends hide in them)
    m.det([(wall, lo, STREET, wall + 8, hi, ceil)], MAT["black"], vis=dv)
    ribs = []
    for u in (-512 - 96, -512 - 192):
        a1, a2 = sv(RAIL_V - 160, RAIL_V - 152)
        c1, c2 = sv(RAIL_V + 152, RAIL_V + 160)
        ribs += [(u, a1, STREET, u + 16, a2, ceil), (u, c1, STREET, u + 16, c2, ceil)]
    m.det(ribs, MAT["beam"], vis=dv)
    p1, p2 = sv(RAIL_V - 184, RAIL_V - 160)
    q1, q2 = sv(RAIL_V + 160, RAIL_V + 184)
    m.det([(-514, p1, DECK_UNDER - 40, -496, p2, b.rim), (-514, q1, DECK_UNDER - 40, -496, q2, b.rim)], MAT["beam"], vis=dv)
    m.taken(-514, sq * (RAIL_V - 200), F, 0, sq * (RAIL_V + 200), b.rim + 16)
    m.no_bank(-8, lo, 8, hi)      # (no lip along the street's wall under the bridge's end: it would stand up across the rails)
    # the signal head beside the mouth, on the wall (lit by nothing: the trains run without one), the mouth's marks
    side = sq * (RAIL_V + 250)
    m.static("models/props_trainstation/light_signal002a.mdl", -512 + 42, side, 0, z=STREET + 120)
    m.taken(-512, side - 40, STREET + 56, -428, side + 40, STREET + 184)
    m.grime("number", -512, sq * (RAIL_V - 230), STREET + 170, 7)
    m.grime("danger", -512, sq * (RAIL_V - 230), STREET + 60, 8)
    m.view(-40, sq * (RAIL_V + 30), STREET + 64, 180, 2, "the train's bridge into its tunnel")



def tunnel_train(b, n, Q, sq, u_far, cars, r, junction, through=False):
    """A run's train (rail_runs): Half-Life 2's Combine engine and cars as models riding an unseen solid brush, waiting
    in the solid beyond its tunnel's black end (its nose 64 behind it). Sent at random every 70 to 240 seconds
    (lc_train_N_timer; lc_train_N_run: Trigger sends one now) behind its horn, it comes out over the bridge and runs
    along the run at SPEED, slowing to a stop short of the first thing in its way (a buffer stop, a bridge over the
    street), then backs into its tunnel and stops in the solid again. With a tunnel at each end (through): it runs
    into the other one and is put back unseen, as the sheds' trains are. A trigger_hurt rides on it while it runs: it
    kills what it hits. In --test files a button on the Combine wall beside the road sends one.

    How it runs (from memory, unchecked: Hammer's func_tracktrain and path_track): fixed orientation (spawnflag 16),
    so it is built facing the way it comes out. velocitytype 1 (linear blend) between the path_tracks' speeds: p1
    where it waits and p_slow at SPEED, p2 where it stops at STOP_SPEED; p2 is the path's end, where a train stops by
    itself (its OnPass then sounds the horn and sends StartBackward), p1 the other end (its OnPass turns the hurt
    off). Every path_track has a speed other than 0: with 0, StartBackward is known to jam or run the wrong way. If it
    crawls or stops early, set velocitytype 0 (it then stops dead at p2)."""
    from map_modules import Mod
    import map_assets
    vmf = b.vmf
    tv = b.vis + ": train %d" % n
    name = "lc_train_%d" % n
    TL = train_len(cars)
    half = TL // 2
    wall = -(512 + TUN)
    v = sq * RAIL_V
    u1 = wall - 64 - half
    if through:
        hit = first_in_way(b, Q, sq, wall + 8, u_far - 8)
        if hit:
            b.problems.append("train %d: something stands in its way at (%d %d %d): it could not pass through" % ((n,) + hit[1][:3]))
        u2 = u_far + 64 + half
        stop = None
    else:
        hit = first_in_way(b, Q, sq, wall + 8, u_far + 64)
        stop = (hit[0] if hit else u_far) - 96
        u2 = stop - half
        if u2 - u1 < TL + 512:
            b.problems.append("train %d: the first thing in its way (at (%d %d %d)) leaves it no room to come out of its tunnel" % ((n,) + (hit[1][:3] if hit else (0, 0, 0))))
            return
    body = Q.box(u1 - half, v - 70, STREET + 12, u1 + half, v + 70, STREET + 290)
    vmf.brush_entity("func_tracktrain", {
        "targetname": name, "target": name + "_p1", "origin": "%d %d %d" % Q.at(u1, v, STREET + 9), "orientationtype": "0",
        "velocitytype": "0" if through else "1", "startspeed": str(SPEED), "speed": "0", "height": "0", "wheels": "50", "bank": "0", "dmg": "10000",
        "spawnflags": "530", "volume": "10", "MoveSound": "ambient/machines/razor_train_wheels_loop1.wav", "MoveSoundMinPitch": "60", "MoveSoundMaxPitch": "200",
        "MoveSoundMinTime": "0", "MoveSoundMaxTime": "0", "ManualSpeedChanges": "0", "ManualAccelSpeed": "0", "ManualDecelSpeed": "0", "rendermode": "10",
        "renderamt": "0", "rendercolor": "255 255 255", "disableshadows": "1"}, [body], "tools/toolsinvisible", tv)
    b.names.append((name, "func_tracktrain", "train %d" % n))
    grow = Q.box(u1 - half - 40, v - 80, STREET + 10, u1 + half + 40, v + 80, STREET + 280)
    vmf.brush_entity("trigger_hurt", {"targetname": name + "_hurt", "parentname": name, "StartDisabled": "1", "spawnflags": "3", "damage": "100000", "damagecap": "100000",
                                      "damagetype": "1", "damagemodel": "0", "nodmgforce": "0"}, [grow], MAT["trigger"], tv)
    m = Mod(b, Q, "train %d" % n)
    keys = {"parentname": name, "solid": "0", "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
            "rendercolor": "255 255 255"}
    front = u1 + half
    eb = map_assets.size(ENGINE) or [-371, -70, 0, 269, 70, 289]
    was = len(b.props)
    m.prop("prop_dynamic", ENGINE, front - int(eb[3]), v, 0, STREET + 9, dict(keys, targetname=name + "_engine"), tv)
    back = front - ENGINE_LEN
    for k in range(cars):
        m.prop("prop_dynamic", CAR, back - GAP - CAR_LEN // 2 - k * (CAR_LEN + GAP), v, 90, STREET + 9, dict(keys, targetname="%s_car_%d" % (name, k + 1)), tv)
    del b.props[was:]      # (they wait inside the solid on purpose: not props standing in a wall, for look_at_props)
    track = {"spawnflags": "0", "orientationtype": "0", "radius": "0"}
    if through:
        vmf.point("path_track", Q.at(u1, v, STREET + 9), dict(track, targetname=name + "_p1", target=name + "_p2", spawnflags="16", speed="0"), tv)
        vmf.point("path_track", Q.at(u2, v, STREET + 9), dict(track, targetname=name + "_p2", target=name + "_p1", speed="0"), tv,
                  connections=[("OnPass", name, "Stop", "", 0), ("OnPass", name + "_hurt", "Disable", "", 0.1)])
    else:
        slow = u2 - 640 if u2 - 640 > u1 + 256 else None
        vmf.point("path_track", Q.at(u1, v, STREET + 9), dict(track, targetname=name + "_p1", target=name + ("_slow" if slow else "_p2"), speed=str(SPEED)), tv,
                  connections=[("OnPass", name + "_hurt", "Disable", "", 0)])
        if slow:
            vmf.point("path_track", Q.at(slow, v, STREET + 9), dict(track, targetname=name + "_slow", target=name + "_p2", speed=str(SPEED)), tv)
            b.names.append((name + "_slow", "path_track", "train %d" % n))
        vmf.point("path_track", Q.at(u2, v, STREET + 9), dict(track, targetname=name + "_p2", speed=str(STOP_SPEED)), tv,
                  connections=[("OnPass", name + "_horn", "PlaySound", "", 3), ("OnPass", name, "StartBackward", "", 5)])
    mouth = Q.at(-512 - 32, v, STREET + 200)
    vmf.point("ambient_generic", mouth, {"targetname": name + "_horn", "message": "ambient/alarms/razortrain_horn1.wav", "health": "10", "pitch": "100",
                                         "pitchstart": "100", "radius": "6000", "spawnflags": "48", "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0",
                                         "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0", "preset": "0", "spindown": "0", "spinup": "0",
                                         "volstart": "0"}, tv)
    vmf.point("logic_relay", (mouth[0], mouth[1], mouth[2] + 16), {"targetname": name + "_run", "StartDisabled": "0", "spawnflags": "0"}, tv,
              connections=[("OnTrigger", name + "_horn", "PlaySound", "", 0), ("OnTrigger", name + "_hurt", "Enable", "", 2.5), ("OnTrigger", name, "StartForward", "", 3)])
    vmf.point("logic_timer", (mouth[0], mouth[1], mouth[2] + 32), {"targetname": name + "_timer", "UseRandomTime": "1", "LowerRandomBound": "70",
                                                                   "UpperRandomBound": "240", "RefireTime": "120", "StartDisabled": "0", "spawnflags": "0"}, tv,
              connections=[("OnTimer", name + "_run", "Trigger", "", 0)])
    for nm, cls in ((name + "_run", "logic_relay"), (name + "_timer", "logic_timer"), (name + "_hurt", "trigger_hurt"), (name + "_horn", "ambient_generic"),
                    (name + "_p1", "path_track"), (name + "_p2", "path_track")):
        b.names.append((nm, cls, "train %d" % n))
    # the test button: on the Combine wall (or the frontage) facing the road, the first place past the crossing square
    FR = front_line(b)
    fr_ = FR - (72 if getattr(b, "street_wall", None) == "combine" else 0)
    fv1, fv2 = sorted((sq * (fr_ - 8), sq * fr_))

    def sq_of(u, a):
        x, y = Q.pt(u, sq * a)
        return (x // CELL, y // CELL)
    for u in range(FR + 128, int(u2 + half), 64):
        if sq_of(u + 32, FR - 32) in b.deck and sq_of(u + 32, FR - 32) not in junction and sq_of(u + 32, FR + 32) not in b.deck:
            m.test_button((u + 24, fv1, STREET + 44, u + 40, fv2, STREET + 60), [("OnIn", name + "_run", "Trigger"), ("OnOut", name + "_run", "Trigger")])
            break
    m.view(FR + 400, sq * 760, STREET, 180, 2, "on the road, toward train %d's bridge and tunnel" % n)
    if through:
        how = "runs into the tunnel at the far end and is put back"
    elif hit and hit[0] < u_far:
        how = "stops at (%d %d), short of what stands over its rails at (%d %d %d), and backs into its tunnel" % (Q.pt(stop, v) + hit[1][:3])
    else:
        how = "stops at (%d %d), short of the buffer stop at the run's end, and backs into its tunnel" % Q.pt(stop, v)
    b.notes.append("train %d: an engine and %d cars (%d long) out of the tunnel at (%d %d), over the bridge and along %s; it %s; about %d seconds out, at random every 70 to 240 seconds" % (
        n, cars, TL, Q.pt(-512, v)[0], Q.pt(-512, v)[1], r["tag"], how, ((u_far if through else stop) + 512) // SPEED + 1))


def hide_trains(b):
    """The solid each train waits in beyond its tunnel's black end (rail_runs): where the backdrop has laid its ground
    (solid up to the rim) or a wall of the plan's stands, that is enough; everywhere else a block of world, outside the
    plan if need be (the train's path_tracks must be in sealed air or in a brush, or the compiler leaks). Runs once the
    backdrop is down (map_modules.build_chain)."""
    from map_backdrop import rects
    for Q, sq, tag, length in getattr(b, "rail_hides", []):
        lo, hi = sorted((sq * (RAIL_V - 160), sq * (RAIL_V + 160)))
        wall = -(512 + TUN)
        free = set()
        for c in squares(Q.rect(wall - length, lo, wall, hi)):
            spec = b.plan.cells.get(c)
            if spec is None:
                free.add(c)
            elif not (spec[0] == "solid" or (spec[0] == "open" and spec[1] >= STREET + 304)):
                b.problems.append("%s: the train hidden beyond it runs into %s at (%d %d)" % (tag, b.owner.get(c, "something"), c[0] * CELL, c[1] * CELL))
        for x1, y1, x2, y2 in rects(free):
            b.vmf.world_box((x1, y1, STREET - 32, x2, y2, max(b.rim, STREET + 312)), MAT["nodraw"], vis=b.vis + ": where the trains wait, unseen")
        if free:
            b.notes.append("%s: %d squares of solid laid where nothing was, for the train to wait in" % (tag, len(free)))


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


def wall_stretches(core, street):
    """The Combine wall's straight stretches along its core: (axis, row, first square, past the last, the street's side
    (-1 below, 1 above)) for every line of 5 squares or more with the street beside it."""
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
    return segs


def stretch_frame(axis, row, a, c, side):
    """A stretch's frame: its start on the core's street face, the way it runs (the street on its right, so its face
    looks to (d[1], -d[0])) and its length."""
    L = (c - a) * CELL
    if axis == "x":      # (the street to the south (side -1) or north; the wall's face on the core's street side)
        o, d = ((a * CELL, row * CELL), (1, 0)) if side < 0 else ((c * CELL, (row + 1) * CELL), (-1, 0))
    else:
        o, d = ((row * CELL, c * CELL), (0, -1)) if side < 0 else (((row + 1) * CELL, a * CELL), (0, 1))
    return o, d, L


def wall_runs(span, r):
    """Lengths from the kit (512 to 1024 in steps of 128) adding up to span (a multiple of 128, at least 512)."""
    out, left = [], span
    while left:
        ks = [k for k in (512, 640, 768, 896, 1024) if k == left or (k < left and left - k >= 512)]
        k = r.choice(ks)
        out.append(k)
        left -= k
    return out


def combine_wall(b, seed=1):
    """The Combine wall along its core, from the Propper++ kit (map_propkit.py; the owner, 23 November, of the brush
    wall vbsp could not take: "we need it to not be nodrawn but to be deleted/non existent"): each straight stretch (5
    squares or more) a row of the kit's runs 512 to 1024 long, their battered ribbed faces to the street, the kit's pier
    over every joint and flush with every free end (one of four, by chance), its lamp beside it (map_combine.py's perimeter, combine/chain.py, as
    the brush wall was); where two stretches turn round the outside of a corner the corner pier, and where they meet in
    an inside corner their runs simply meet. All of them prop_statics that never fade, cast shadows and have no
    collision: a player clip along each stretch's foot and round each pier keeps players at the wall's front. The core
    (world) seals as before. A layout's "wall combine brushes" builds the brush wall instead (combine_wall_brushes)."""
    import math
    import random as _r
    import map_propkit as PK
    from combine.scene import lamp
    if getattr(b, "wall_brushes", False):
        return combine_wall_brushes(b, seed)
    core = getattr(b, "combine_core", set())
    if not core:
        return
    kit = PK.load()
    W, P = kit["wall"], kit["pieces"]
    half = max(max(-P[n]["box"][0], P[n]["box"][3]) for n in W["piers"])   # (the widest pier's half width: an end pier stands this far in)
    r = _r.Random("wall kit %s %d" % (b.name, seed))
    v, vis = b.vmf, b.vis + ": the Combine wall"
    keys = {"skin": "0", "solid": "0", "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
    counts = {"runs": 0, "piers": 0, "corners": 0, "lamps": 0, "clips": 0, "plain": 0}

    def put(name, pos, yaw, turn=True):
        piece = P[name]
        at = PK.place(pos, yaw)
        v.point("prop_static", pos, dict(keys, model=PK.model(name), angles="0 %d 0" % yaw), vis)
        for box in piece["clip"]:
            w = PK.place_box(pos, yaw, box)
            if w[0] < w[3] and w[1] < w[4]:
                v.world_box(w, MAT["clip"], top=MAT["clip"], bottom=MAT["clip"], vis=vis + "'s player clip", seals=False)
                counts["clips"] += 1
        for x, y, z, look, pitch in piece["lamps"]:
            lamp(v, at(x, y, z), (look + yaw + (r.choice((-30, -15, 15, 30)) if turn else 0)) % 360, pitch, vis)
            counts["lamps"] += 1
        for x, y, z, colour in piece["lights"]:
            v.point("light", at(x, y, z), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)

    st = []
    for seg in wall_stretches(core, set(b.deck)):
        o, d, L = stretch_frame(*seg)
        st.append({"o": o, "d": d, "f": (d[1], -d[0]), "L": L, "ends": ["free", "free"]})

    def end(s, e):
        """A stretch's end e (0 its start, 1 its end): its point on the street face, the way into the wall, the square."""
        u = 0 if e == 0 else s["L"]
        pt = (s["o"][0] + s["d"][0] * u, s["o"][1] + s["d"][1] * u)
        t = s["d"] if e == 0 else (-s["d"][0], -s["d"][1])
        return pt, t, ((pt[0] + 32 * t[0] - 32 * s["f"][0]) // CELL, (pt[1] + 32 * t[1] - 32 * s["f"][1]) // CELL)
    corners = []
    for i, s1 in enumerate(st):      # (corners: two stretches at right angles whose end squares touch)
        for s2 in st[i + 1:]:
            if s1["d"][0] * s2["d"][0] + s1["d"][1] * s2["d"][1]:
                continue
            for e1 in (0, 1):
                for e2 in (0, 1):
                    p1, t1, c1 = end(s1, e1)
                    p2, t2, c2 = end(s2, e2)
                    if max(abs(c1[0] - c2[0]), abs(c1[1] - c2[1])) > 1:
                        continue
                    if s1["f"][0] * t2[0] + s1["f"][1] * t2[1] >= 0:      # (the other wall stands before this one's face: an inside corner)
                        s1["ends"][e1] = s2["ends"][e2] = "inside"
                    elif p1 == p2:                                        # (round the outside: both faces end at one corner)
                        s1["ends"][e1] = s2["ends"][e2] = "corner"
                        corners.append((p1, s1["f"], s2["f"]))
    for s in st:
        a = half if s["ends"][0] == "free" else 0
        z = s["L"] - (half if s["ends"][1] == "free" else 0)
        if z - a < 512:
            counts["plain"] += 1      # (too short for a run: the core stays plain metal)
            continue
        lengths = wall_runs((z - a) // 128 * 128, r)
        extra = (z - a) % 128
        gaps = [0] * (len(lengths) + 1)      # (before each run, and after the last: a pier covers each)
        if extra:
            if s["ends"][0] == "free":
                gaps[0] = extra
            elif s["ends"][1] == "free":
                gaps[-1] = extra
            elif len(lengths) > 1:
                gaps[r.randint(1, len(lengths) - 1)] = extra
            elif s["ends"][0] == "corner":
                gaps[0] = extra
            elif s["ends"][1] == "corner":
                gaps[-1] = extra
            else:
                gaps[0], gaps[-1] = extra // 2, extra - extra // 2
        yaw = int(round(math.degrees(math.atan2(s["d"][1], s["d"][0])))) % 360
        u, runs = a, []
        for k, g in zip(lengths, gaps):
            u += g
            runs.append((u, k))
            u += k
        for u, k in runs:
            put(r.choice(W["runs"][str(k)]), (s["o"][0] + s["d"][0] * u, s["o"][1] + s["d"][1] * u, STREET), yaw)
            counts["runs"] += 1
        us = [(runs[n][0] + runs[n][1] + runs[n + 1][0]) // 2 for n in range(len(runs) - 1)]
        us = ([half] if s["ends"][0] == "free" else []) + us + ([s["L"] - half] if s["ends"][1] == "free" else [])
        for u in us:
            put(r.choice(W["piers"]), (s["o"][0] + s["d"][0] * u, s["o"][1] + s["d"][1] * u, STREET), yaw)
            counts["piers"] += 1
    for pt, fa, fb in corners:      # (the corner pier's fronts look to -y and -x of its own: turned so they meet the two faces)
        for f1, f2 in ((fa, fb), (fb, fa)):
            yaw = int(round(math.degrees(math.atan2(f1[0], -f1[1])))) % 360
            c, sn = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
            if (-c, -sn) == tuple(f2):
                put(W["corner"], (pt[0], pt[1], STREET), yaw)
                counts["corners"] += 1
                break
    b.notes.append("the Combine wall between the city and the street, from the Propper++ kit (map_propkit.py): %d stretches, %d runs, %d piers, "
                   "%d corner piers, %d lamps, %d player clips%s" % (len(st), counts["runs"], counts["piers"], counts["corners"], counts["lamps"],
                                                                     counts["clips"], ", %d too short (plain)" % counts["plain"] if counts["plain"] else ""))


def combine_wall_brushes(b, seed=1):
    """The Combine wall as brushes (the way it was built until the kit: "wall combine brushes" in a layout): each straight
    stretch (5 squares or more) a row of wall_chain's runs 512 to 1024 long, laid straight, their battered ribbed faces
    to the street, a pier with its lamp over every joint and at both ends (map_combine.py's perimeter, combine/chain.py).
    What a stretch leaves short stays plain metal."""
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
    segs = wall_stretches(core, set(b.deck))
    for seg in segs:
        o, d, L = stretch_frame(*seg)
        u, runs_ = 0, []
        while L - u >= 320:
            k = min(r.choice((512, 640, 768, 896, 1024)), L - u)
            if L - u - k < 320:
                k = L - u
            fr = CF((o[0] + d[0] * u, o[1] + d[1] * u, STREET), d)
            runs_.append((Piece(fr, (k, 0), WALL_H, r, sink), k))
            u += k
        for n, (p, k) in enumerate(runs_):
            T, Le, Pl = run(p, k, WALL_H, r, inner=False)      # (its back against the city's edge: nothing built there)
            pier(p, 0, WALL_H, r, T, Le, Pl, lamp=n % 2 == 0)
            if n == len(runs_) - 1:
                pier(p, k, WALL_H, r, T, Le, Pl, lamp=True)
    put(b.vmf, sink, b.vis + ": the Combine wall")
    b.notes.append("the Combine wall between the city and the street (brushes): %d stretches, %d lamps" % (len(segs), len(sink.lamps)))


# ---------------------------------------------------------------------------------------------------------------------
# The road round the first canal's east side (the owner, 23 November, of the street that ended at the last jog: "the road
# just ends at the canal ... you need to compensate for the road hitting the canal by either making a bridge or having it
# go around the canal"; they chose round its east side). From the east run's street end the road crosses the jog on a
# deck, runs north to the first canal's south edge, where the first canal's own piece carries it up its east bank and over
# its east arm on a bridge (map_build.canal); from the first canal's north edge the ring takes it again and carries it
# west over the north run's canal on a bridge into the north run's street. One ring road. On this stretch alone the
# canal is between the road and the city, so its Combine wall stands on the road's far (east) side.
# ---------------------------------------------------------------------------------------------------------------------

ROUND = {
    "mid": 6144,                          # the middle of the first canal's run north, of the ring's end gate and of its north run
    "deck": (6016, 1088, 7232, 1600),     # the ring's deck over the jog (from the east run's street end to the bank road)
    "south": (1600, 1856),                # the ring's: the bank road from the deck to the first canal's south edge
    "canal": (1856, 5696),                # the first canal's: up its east bank (map_build.canal)
    "arm": (4160, 4672),                  # its east arm, which the road crosses on a bridge
    "north": (5696, 6400),                # the ring's: from the first canal's north edge to the bridge's far side
    "turn": 5952,                         # where the road turns west onto the bridge (the tracks end there)
    "bridge": (5888, 5952, 6400, 6400),   # over the north run's canal, into its street
}


def east_bank(x_mid, y1, y2, road_only=()):
    """The squares of a street on the east bank of a canal running north whose middle is x_mid, from y1 to y2, laid as
    the chain's street is (the canal's edge, the tracks, the road and its pavements out to the frontage, which stands
    behind a Combine wall's foot), and the squares of the Combine wall's core beyond it. road_only: stretches of y that
    are all roadway (a turning place). Gives ({square: floor material}, {core squares})."""
    from map_modules import MM
    fr_line = FRONT + 64
    street, core = {}, set()
    for j in range(y1 // CELL, y2 // CELL):
        plain = any(a <= j * CELL < b for a, b in road_only)
        for a, c, mat in ((EDGE, TRACK, MM["walk"]), (TRACK, ROAD_IN, MM["gravel"]), (ROAD_IN, fr_line, MM["road"])):
            for i in range((x_mid + a) // CELL, (x_mid + c) // CELL):
                street[(i, j)] = MM["road"] if plain else mat
        core.add(((x_mid + fr_line) // CELL, j))
    return street, core


def bank_tops(x_mid):
    """What a deck carrying the east bank's street has on top, by x: (x1, x2, material)."""
    from map_modules import MM
    return [(x_mid + EDGE, x_mid + TRACK, MM["walk"]), (x_mid + TRACK, x_mid + ROAD_IN, MM["gravel"]), (x_mid + ROAD_IN, x_mid + FRONT + 64, MM["road"])]


FENCES = ((256, "models/props_c17/fence03a.mdl"), (128, "models/props_c17/fence01a.mdl"), (64, "models/props_c17/fence01b.mdl"))


def edge_fence(vmf, fr, a, c, v, z, vis):
    """The chain link along the canal's edge from u = a to c, standing on z, as Half-Life 2's own fence panels (the
    owner, 24 November: "what if we replaced the fence/railing between the railroad and the canal with props?"): the
    longest panels that fit, 256 then 128 then 64, one prop each where the brush fence took a sheet, a rail and a post
    every 256. The panels are 109 high (the brush fence was 72), their origin at their middle."""
    u = a
    while u < c:
        n, model = next(((n, mo) for n, mo in FENCES if u + n <= c), FENCES[-1])
        x, y, zz = fr.at(u + n // 2, v, z + 54)
        vmf.point("prop_static", (x, y, zz), {"model": model, "angles": "0 %d 0" % ((fr.yaw(0) + 90) % 360), "skin": "0", "solid": "6", "disableshadows": "0",
                                              "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)
        u += n


class _Det:
    """Just enough of a module (map_modules.Mod) for chain_link: boxes in a frame, as details."""

    def __init__(self, vmf, fr, vis):
        self.vmf, self.fr, self.dv = vmf, fr, vis

    def det(self, boxes, mat, top=None, vis=None, faces=None):
        self.vmf.detail([self.fr.box(*x) for x in boxes], mat, vis=vis or self.dv, top=top, faces=faces)


def east_bank_dress(vmf, vis, x_mid, edge=(), rail=(), tracks=(), pave=(), outer=(), buffers=(), planks=(), lane=None, lanes_at=()):
    """What stands on the east bank's street, as on the chain's (lay): the low parapet and chain link along the canal's
    edge over the stretches of y in `edge`, sleepers and rails over `tracks`, the inner pavement over `pave` and its kerb
    rail over `rail`, the outer pavement up to the Combine wall's foot over `outer`, a buffer stop across the tracks at
    each (y1, y2) in `buffers`, planks across the tracks at each (y1, y2) in `planks` (where people cross them), and a
    path node on the edge walk and on the road at each y in `lanes_at` (lane(x, y, z))."""
    from map_modules import MM, Frame, chain_link
    fr = Frame(x_mid, 0, 1, 0)       # (u is y; v is west of the middle, so the east bank is v < 0)
    m = _Det(vmf, fr, vis)
    s = -1

    def sv(a, c):
        return (s * c, s * a)
    for a, c in edge:
        v1, v2 = sv(EDGE, EDGE + 12)
        m.det([(a, v1, STREET, c, v2, STREET + 40)], MAT["beam"])
        edge_fence(vmf, fr, a, c, s * (EDGE + 6), STREET + 40, vis)
    ties, rails = [], []
    for a, c in tracks:
        v1, v2 = sv(RAIL_V - 68, RAIL_V + 68)
        for u in range(a // CELL * CELL, c, CELL):      # (on the map's grid, as the chain's are: the same spacing across a join)
            ties += [(u + TIE[0], v1, STREET, u + TIE[1], v2, STREET + 3)] if a <= u + TIE[0] and u + TIE[1] <= c else []
        for g in (-40, 37):
            w1, w2 = sv(RAIL_V + g, RAIL_V + g + 3)
            rails.append((a, w1, STREET + 3, c, w2, STREET + 9))
    if ties:
        m.det(ties, MM["beam_wood"], faces={"bottom": MAT["nodraw"]})
        m.det(rails, MAT["bars"])
    for a, c in pave:
        v1, v2 = sv(ROAD_IN, ROAD_OUT)
        m.det([(a, v1, STREET, c, v2, STREET + 8)], MM["walk"])
    # (`rail`: no longer built: the owner, 24 November, took the rail between the tracks and the road out)
    for a, c in outer:
        v1, v2 = sv(960, FRONT + 64)
        m.det([(a, v1, STREET, c, v2, STREET + 8)], MM["walk"])
    for a, c in buffers:      # (a block of concrete across the tracks' end, a beam on it)
        v1, v2 = sv(TRACK + 24, ROAD_IN - 24)
        m.det([(a, v1, STREET, c, v2, STREET + 48)], MAT["canal_wall"], top=MAT["beam"])
    for a, c in planks:      # (1 over the rails' tops: no shared face to flicker)
        v1, v2 = sv(TRACK, ROAD_IN)
        m.det([(a, v1, STREET, c, v2, STREET + 10)], MM["wood"])
    if lane:
        for u in lanes_at:
            lane(x_mid + 288, u, STREET)
            lane(x_mid + 800, u, STREET)


def deck_parapets(cells, x1, y1, x2, y2):
    """The edges of a deck that look down into a canal (the square beyond is open ground lower than the street), as
    boxes 16 thick inside the deck, joined into runs; the runs along x stop 16 short of a corner a run along y takes."""
    def low(c):
        spec = cells.get(c)
        return bool(spec) and spec[0] == "open" and spec[1] < STREET - 16

    def runs(ok, a0, a1):
        out, start = [], None
        for a in range(a0, a1 + CELL, CELL):
            if a < a1 and ok(a):
                start = a if start is None else start
            elif start is not None:
                out.append((start, a))
                start = None
        return out
    west = runs(lambda y: low((x1 // CELL - 1, y // CELL)), y1, y2)
    east = runs(lambda y: low((x2 // CELL, y // CELL)), y1, y2)
    boxes = [(x1, a, x1 + 16, c) for a, c in west] + [(x2 - 16, a, x2, c) for a, c in east]
    for y, j, inside in ((y1, y1 // CELL - 1, (y1, y1 + 16)), (y2, y2 // CELL, (y2 - 16, y2))):
        for a, c in runs(lambda x: low((x // CELL, j)), x1, x2):
            if a == x1 and any(r[0] <= y <= r[1] for r in west):
                a += 16
            if c == x2 and any(r[0] <= y <= r[1] for r in east):
                c -= 16
            boxes.append((a, inside[0], c, inside[1]))
    return boxes


def road_deck(vmf, vis, x1, y1, x2, y2, span, parapets=(), tops=None):
    """A road carried over a canal at the street's height: a slab 24 thick whose top is the street (tops: [(x1, x2,
    material)] for the bands of a street on it; the roadway's cobbles if none), girders under it every 96 from bank to
    bank (span: "x" or "y", the way they run), a parapet 48 high on each of `parapets` ((x1, y1, x2, y2) on the plan, and
    the height it stands on if not the deck's: a pavement's), and lights under it, which roofs the canal. Gives back the
    room it takes, for the canal's dressing to keep clear of."""
    import map_build
    from map_modules import MM
    for a, c, mat in (tops or [(x1, x2, MM["road"])]):
        vmf.detail([(max(a, x1), y1, STREET - 24, min(c, x2), y2, STREET)], MAT["beam"], vis=vis, top=mat)
    if span == "y":
        girders = [(x, y1, STREET - 56, x + 24, y2, STREET - 24) for x in range(x1 + 40, x2 - 40, 96)]
    else:
        girders = [(x1, y, STREET - 56, x2, y + 24, STREET - 24) for y in range(y1 + 40, y2 - 40, 96)]
    vmf.detail(girders, MAT["bars"], vis=vis)
    if parapets:
        vmf.detail([(p[0], p[1], p[4] if len(p) > 4 else STREET, p[2], p[3], (p[4] if len(p) > 4 else STREET) + 48) for p in parapets], MAT["canal_wall"], vis=vis)
    n = max(1, (max(x2 - x1, y2 - y1) + 383) // 768)
    for k in range(n):
        t = (2 * k + 1) / (2.0 * n)
        x, y = (int(x1 + (x2 - x1) * t), (y1 + y2) // 2) if x2 - x1 >= y2 - y1 else ((x1 + x2) // 2, int(y1 + (y2 - y1) * t))
        keys = {"_light": "255 214 170 45", "_lightHDR": "-1 -1 -1 1", "style": "0"}
        keys.update(map_build.falloff("fill"))
        vmf.point("light", (x, y, STREET - 112), keys, vis)
    return (x1, y1, STREET - 120, x2, y2, STREET + 64)


def road_cap(vmf, vis, name, x_mid, y1, y2, sky):
    """What stops up the bank road where it runs on into another piece, while nothing is joined there: black walls across
    the road and over the Combine wall's core, in a visgroup named as the gates' caps are (map_merge.py leaves both pieces'
    out where they meet)."""
    fr_line, k = x_mid + FRONT + 64, MAT["black"]
    group = "%s: %s gate's cap (delete to join)" % (vis, name)
    vmf.world_box((x_mid + EDGE, y1, STREET, fr_line, y2, sky), k, k, k, vis=group)
    vmf.world_box((fr_line, y1, STREET + WALL_H - 8, fr_line + 64, y2, sky), k, k, k, vis=group)


def round_gaps(b):
    """Before the chain's street is laid: where the bridge round the first canal lands on the north run's street, no
    parapet on the canal's edge and no rail between the tracks and the road."""
    x1, y1, x2, y2 = ROUND["bridge"]
    b.edge_gaps.append((x1 - 32, y1, x1 + 16, y2))


def round_east(b):
    """The ring's share of the road round the first canal's east side (ROUND, above), once the chain's street is laid:
    the deck over the jog, the bank road on to the first canal's south edge, the bank road from its north edge to the
    bridge over the north run's canal, the bridge; the Combine wall's core on the road's far side; a cap at each place
    where the first canal's piece carries the road on."""
    R = ROUND
    cells, mid = b.plan.cells, R["mid"]
    if getattr(b, "street_wall", None) != "combine":
        b.problems.append("round east: the road round the first canal needs the Combine wall (\"wall combine\")")
        return
    vis = b.vis + ": the road round the first canal"
    core_h = STREET + WALL_H - 8
    street, core = east_bank(mid, *R["south"])
    north, ncore = east_bank(mid, *R["north"], road_only=[(R["turn"], R["north"][1])])
    street.update(north)
    core |= ncore
    yn = R["north"][1]
    core |= {(i, yn // CELL) for i in range((mid + EDGE) // CELL, (mid + FRONT + 128) // CELL)}      # (across the road's north end)

    def canal(c):
        spec = cells.get(c)
        return bool(spec) and spec[0] == "open" and spec[1] < STREET - 16
    # (plain wall where the core would meet the canal: the chain link along the canal's walls would stand on a core's top)
    core = {c for c in core if not any(canal((c[0] + di, c[1] + dj)) for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for c, mat in sorted(street.items()):
        if c in cells:
            b.problems.append("the road round the first canal runs into %s at (%d %d)" % (b.owner.get(c, "something"), c[0] * CELL, c[1] * CELL))
            continue
        cells[c] = ("open", STREET, mat)
        b.owner[c] = "the road round the first canal"
        b.deck.add(c)
    for c in sorted(core):
        if c in cells:
            b.problems.append("the Combine wall round the first canal runs into %s at (%d %d)" % (b.owner.get(c, "something"), c[0] * CELL, c[1] * CELL))
            continue
        cells[c] = ("low", core_h, CORE, b.sky)
        b.owner[c] = "the Combine wall"
    # (the wall's dressing; at the first canal's north edge this stretch's pier stands over the join, and the first canal
    #  leaves its own last three squares plain so the two never stand in each other; the north end's first square is left
    #  plain so its pier does not overhang the canal)
    b.combine_core = set(getattr(b, "combine_core", set())) | {c for c in core if c != ((mid + EDGE + 64) // CELL, yn // CELL)}
    # where the first canal's piece carries the road on: kept out of this piece's walls, stopped up for it alone
    fr_line = mid + FRONT + 64
    for y_join, side in ((R["south"][1], 1), (R["north"][0], -1)):
        b.plan.keep_out.append((mid + EDGE, y_join, fr_line + 64, y_join + 64) if side > 0 else (mid + EDGE, y_join - 64, fr_line + 64, y_join))
        a, c = (y_join - 64, y_join) if side > 0 else (y_join, y_join + 64)
        road_cap(b.vmf, b.vis, "the east road's %s" % ("south" if side > 0 else "north"), mid, a, c, b.sky)
        b.allow.append((mid + EDGE - 64, y_join - 128, 0, fr_line + 192, y_join + 128, b.sky + 64))
    # the deck over the jog, and the bridge over the north run's canal (a parapet wherever an edge looks down into a canal)
    # (and no trim along the tops of the walls they rest on: it would stand 16 proud of the deck)
    x1, y1, x2, y2 = R["deck"]
    b.taken.append(road_deck(b.vmf, vis, x1, y1, x2, y2, "y", deck_parapets(cells, x1, y1, x2, y2)))
    b.no_bank += [(x1, y1 - 8, x2, y1 + 8), (x1, y2 - 8, x2, y2 + 8)]
    bx1, by1, bx2, by2 = R["bridge"]
    b.taken.append(road_deck(b.vmf, vis, bx1, by1, bx2, by2, "x", deck_parapets(cells, bx1, by1, bx2, by2)))
    b.no_bank += [(bx1 - 8, by1, bx1 + 8, by2), (bx2 - 8, by1, bx2 + 8, by2)]
    # on the bank road: the tracks from a buffer stop at the deck to the first canal, and from it to a buffer stop at the
    # turn (the rails' ends inside the buffer stops)
    s1, s2 = R["south"]
    n1, t = R["north"][0], R["turn"]
    east_bank_dress(b.vmf, vis, mid, rail=[(s1, s2), (n1, t)], tracks=[(s1 + 16, s2), (n1, t - 16)], pave=[(s1, s2), (n1, t)], outer=[(s1, s2), (n1, yn)],
                    buffers=[(s1, s1 + 32), (t - 32, t)], lane=lambda x, y, z: b.lanes.append((x, y, z)), lanes_at=(s1 + 128, n1 + 128, (t + yn) // 2))
    for x, y in ((6272, 1216), (6656, 1344), (6976, 1536), ((bx1 + bx2) // 2 - 128, (by1 + by2) // 2), ((bx1 + bx2) // 2 + 128, (by1 + by2) // 2)):
        b.lanes.append((x, y, STREET))
    b.notes.append("the road round the first canal: a deck over the jog (x %d..%d, y %d..%d), the bank road to the first canal's south edge (y %d) "
                   "and from its north edge (y %d) to a bridge over the north run's canal (y %d..%d) into its street" % (x1, x2, y1, y2, s2, n1, by1, by2))

