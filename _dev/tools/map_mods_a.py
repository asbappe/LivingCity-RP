#!/usr/bin/env python3
"""
Living City: canal modules, set A (picked up by map_modules.py; the guide is docs/dev/map-modules.md)

    tram        a tram line's fallen bridge: a station in each wall, a derailed car hanging from one
    tenement    a tenement block that has collapsed into the canal: the way on is through its rooms
    quay        stairs up to a quay and a street doorway, a footbridge across
    collapse    a street's retaining wall and roadway fallen in: a squeeze and a crawl
    scrapyard   the canal widens into a yard of stacked containers under a crane

    python3 map_modules_check.py --only tram,tenement,quay,collapse,scrapyard --views /some/folder
"""

from map_build import CELL, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM

TILE = "tile/tilefloor018a_c17"
BRICK = "brick/brickwall045d"
PLASTER = "plaster/plasterwall042c"
ROAD = "concrete/concretefloor016a"
DIRT = "nature/dirtfloor005c"
DUCT = "metal/metalduct003a"
STONE = "stone/stonewall040f"
P = "models/"


# ---------------------------------------------------------------------------
# Helpers (plain functions: nothing here changes the shared framework)
# ---------------------------------------------------------------------------

def para(o, a, b, c, mat, top=None):
    """A slab that leans: one corner o and its three edges a, b, c, each (du, dv, dz). Sheared, never turned: every
    corner is a whole number when o and the edges are. top: another material for the face at the far end of c."""
    def p(i, j, k):
        return tuple(o[n] + i * a[n] + j * b[n] + k * c[n] for n in range(3))
    faces = []
    for axis in range(3):
        for end in (0, 1):
            ring = []
            for s, t in ((0, 0), (1, 0), (1, 1), (0, 1)):
                ijk = [s, t]
                ijk.insert(axis, end)
                ring.append(p(*ijk))
            faces.append((ring, top if (top and axis == 2 and end == 1) else mat))
    return faces


def wall(u1, v1, u2, v2, z1, z2, holes=()):
    """The boxes of a wall with holes in it. The wall runs along its longer side; a hole is (from, to, z from, z to)
    along that side."""
    along_u = (u2 - u1) >= (v2 - v1)
    a1, a2 = (u1, u2) if along_u else (v1, v2)

    def box(a, b, za, zb):
        return (a, v1, za, b, v2, zb) if along_u else (u1, a, za, u2, b, zb)
    out, at = [], a1
    for (h1, h2, hz1, hz2) in sorted(holes):
        if h1 > at:
            out.append(box(at, h1, z1, z2))
        if hz1 > z1:
            out.append(box(h1, h2, z1, hz1))
        if hz2 < z2:
            out.append(box(h1, h2, hz2, z2))
        at = h2
    if at < a2:
        out.append(box(at, a2, z1, z2))
    return out


def floor_with_holes(u1, v1, u2, v2, z1, z2, holes=()):
    """The boxes of a floor slab with rectangular holes (u1, v1, u2, v2) in it: strips along u, cut at every hole."""
    cuts = sorted(set([v1, v2] + [h[1] for h in holes] + [h[3] for h in holes]))
    out = []
    for k in range(len(cuts) - 1):
        a, b = cuts[k], cuts[k + 1]
        if a < v1 or b > v2:
            continue
        at = u1
        for h in sorted(h for h in holes if h[1] <= a and h[3] >= b):
            if h[0] > at:
                out.append((at, a, z1, h[0], b, z2))
            at = max(at, h[2])
        if at < u2:
            out.append((at, a, z1, u2, b, z2))
    return out


def clip(m, box):
    """An unseen wall for players only (it seals nothing)."""
    m.world(box, MAT["clip"], vis=m.b.vis + ": player clips", seals=False)


class Car:
    """A tram car built of brushes, lying along v between two u's: a floor, a roof, sides with window posts, open ends.
    Its floor rises num/den for every unit of v from (v0, z0): sheared, never turned. high: the clear height inside."""

    def __init__(self, u1, u2, v0, z0, num, den, high, post):
        self.u1, self.u2, self.v0, self.z0, self.num, self.den, self.high, self.post = u1, u2, v0, z0, num, den, high, post
        self.out = []

    def zf(self, v):
        n = (v - self.v0) * self.num
        if n % self.den:
            raise ValueError("the tram's floor is off the grid at v %d" % v)
        return self.z0 + n // self.den

    def piece(self, ua, ub, va, vb, lo, hi, mat):
        self.out.append(prism([(va, self.zf(va) + lo), (vb, self.zf(vb) + lo), (vb, self.zf(vb) + hi), (va, self.zf(va) + hi)], "x", ua, ub, mat))

    def build(self, m, vs, doors=(), seats=(), bogies=(), body=None, lip=True):
        """vs: where the window posts stand along v. doors: (side 0 or 1, segment) with no panel under the window.
        seats: (side, segment) with a bench. bogies: (v from, v to)."""
        u1, u2, high, post = self.u1, self.u2, self.high, self.post
        body = body or MM["steel"]
        a, b = vs[0], vs[-1]
        self.piece(u1, u2, a, b, -8, 0, MM["wood"])
        self.piece(u1 - 2, u2 + 2, a, b, high, high + 8, MM["tin"])
        self.piece(u1 + 24, u2 - 24, vs[1], vs[-2], high + 8, high + 14, MM["tin"])
        for side, (ua, ub) in enumerate(((u1, u1 + 4), (u2 - 4, u2))):
            for k in range(len(vs) - 1):
                va, vb = vs[k], vs[k + 1]
                door = (side, k) in doors
                if not door:
                    self.piece(ua, ub, va, vb, 0, 36, body)
                    self.piece(ua - 1 if side == 0 else ub, ua if side == 0 else ub + 1, va, vb, 30, 36, MAT["bars"])      # a rail under the windows
                self.piece(ua, ub, va, vb, high - 14, high, body)
                self.piece(ua, ub, va, va + post, 0 if door else 36, high - 14, body)
                if door and k + 1 < len(vs) - 1:
                    self.piece(ua, ub, vb - post, vb, 0, high - 14, body)
                if (side, k) in seats:
                    sa, sb = (ua + 4, ua + 22) if side == 0 else (ub - 22, ub - 4)
                    self.piece(sa, sb, va + post, vb, 0, 16, MM["beam_wood"])
                    self.piece(sa if side == 0 else sb - 4, sa + 4 if side == 0 else sb, va + post, vb, 16, 34, MM["beam_wood"])
            self.piece(ua, ub, b - post, b, 0, high - 14, body)
        for (va, vb) in bogies:
            self.piece(u1 + 14, u2 - 14, va, vb, -24, -8, MAT["bars"])
            self.piece(u1 + 6, u1 + 14, va + post, vb - post, -30, -10, MAT["black"])
            self.piece(u2 - 14, u2 - 6, va + post, vb - post, -30, -10, MAT["black"])
        m.shapes(self.out)


# ---------------------------------------------------------------------------
# tram
# ---------------------------------------------------------------------------

def m_tram(m, opt):
    """The fallen tram bridge. A tram line crossed the canal here; its bridge is gone but for a stub of deck at each
    wall, one whole girder on a pier and one that sags. In each wall, at the trim's height, a station opens: a short
    tunnel mouth, then a hall with a tiled platform either side of the track, columns, benches and dim lamps. The left
    station (+v) has a ticket booth and, at the back, a stair up to the street shut by bars with black behind
    (lc_tram_exit); its track ends at a buffer. A derailed car built of brushes hangs from the left mouth down to the
    canal floor (its floor climbs 248 over a run of 310, about 39 degrees): walk in at its low end by the right bank
    and up through it into the left station. The right station is reached only by the whole girder, a beam 16 wide
    and 368 long, 256 over the floor: a second car stands at its platform with a cache in it (lc_tram_stash).
    Dropping from either stub onto a bank is safe; there is no other way up.
    Named for the game: lc_tram_exit (an info_target on the left platform before the barred stair: where people come
    from or go to the street), lc_tram_stash (an info_target inside the car in the right station: a cache).
    Unchecked: how the bench, payphone, bin, locker and mattress models face and how big they are."""
    b = m.b
    ceil, pz = TRIM + 120, TRIM + 16
    steel, wood = MM["steel"], MM["wood"]
    m.open(0, -256, 1536, 256)
    for s in (1, -1):                       # s 1: the left station (+v), -1: the right
        def v(a, c):
            return (a * s, c * s) if s > 0 else (c * s, a * s)
        m.low(640, v(256, 384)[0], 896, v(256, 384)[1], ceil, floor=TRIM)
        m.low(448, v(384, 832)[0], 1088, v(384, 832)[1], ceil, floor=TRIM)
        m.low(704, v(832, 960)[0], 832, v(832, 960)[1], ceil, floor=TRIM)
        if s > 0:
            m.low(512, 832, 640, 960, ceil, floor=TRIM)
        m.side(448, v(256, 960)[0], 1088, v(256, 960)[1])
        m.portal(640, v(318, 320)[0], TRIM, 896, v(318, 320)[1], ceil)
        m.taken(608, v(176, 256)[0], F, 928, v(176, 256)[1], b.rim)

        def box(u1, v1, z1, u2, v2, z2):
            lo, hi = v(v1, v2)
            return (u1, lo, z1, u2, hi, z2)
        # platforms either side of the track bed, their ledges out to the mouth, tiled; a dark strip along their edges
        m.det([box(448, 384, TRIM, 704, 832, pz), box(832, 384, TRIM, 1088, 832, pz), box(640, 256, TRIM, 704, 384, pz), box(832, 256, TRIM, 896, 384, pz)],
              MAT["canal_wall"], top=TILE)
        m.det([box(700, 384, pz, 704, 832, pz + 1), box(832, 384, pz, 836, 832, pz + 1)], MAT["beam"])
        # columns along the platforms' edges, a wainscot of tile on the hall's walls with a steel rail over it
        cols = [box(u, c - 12, pz, u + 24, c + 12, ceil) for u in (668, 844) for c in (480, 608, 736)]
        m.det(cols, MAT["beam"])
        m.det([box(u - 4, c - 16, ceil - 12, u + 28, c + 16, ceil) for u in (668, 844) for c in (480, 608, 736)], MAT["canal_wall"])
        tiles = [box(448, 384, pz, 450, 832, pz + 60), box(1086, 384, pz, 1088, 832, pz + 60), box(448, 384, pz, 640, 386, pz + 60), box(896, 384, pz, 1088, 386, pz + 60),
                 box(832, 830, pz, 1088, 832, pz + 60), box(640, 830, pz, 704, 832, pz + 60), box(448, 830, pz, 512, 832, pz + 60)]
        if s < 0:
            tiles.append(box(512, 830, pz, 640, 832, pz + 60))
        m.det(tiles, TILE)
        m.det([(t[0], t[1], pz + 60, t[3], t[4], pz + 64) for t in tiles], steel)
        # the rails, broken where the areaportal stands
        for u in (736, 796):
            m.det([box(u, 232, TRIM, u + 4, 316, TRIM + 3), box(u, 322, TRIM, u + 4, 880 if s > 0 else 956, TRIM + 3)], MAT["bars"])
        # the back of the track: black, where the line went on
        m.det([box(704, 944, TRIM, 832, 960, ceil)], MAT["black"])
        for (u, c) in ((576, 500), (576, 716), (960, 500), (960, 716)) if s > 0 else ((576, 608), (960, 608)):
            m.lamp(u, c * s, ceil - 8, "255 214 170 45" if s > 0 else "200 214 255 30")
        m.lane(768, 300 * s, TRIM)
        m.lane(576, 608 * s, pz)
        m.lane(960, 608 * s, pz)

    # --- the left station: the booth, the barred stair, the buffer ---
    m.det([(512, 832, TRIM, 640, 856, pz)], MAT["canal_wall"], top=TILE)
    m.bars((512, 838, pz, 640, 846, ceil), "u")
    m.steps(856, 512, 640, pz, pz + 40, "v", 1)
    m.det([(512, 916, pz, 640, 960, ceil), (512, 846, ceil - 24, 640, 916, ceil)], MAT["black"])
    m.det([(504, 826, pz, 512, 838, ceil), (640, 826, pz, 648, 838, ceil), (504, 826, ceil - 16, 648, 838, ceil)], steel)       # the stair's frame
    m.target("lc_tram_exit", 576, 800, pz + 8, 90)
    m.blocked(512, 832, 640, 960)
    # the ticket booth: 96 by 112, a window with a counter toward the track, a doorway on its far side
    bz = pz
    m.det(wall(448, 480, 544, 488, bz, ceil) + wall(448, 584, 544, 592, bz, ceil, [(472, 520, bz, bz + 88)]) +
          wall(536, 488, 544, 584, bz, ceil, [(504, 568, bz + 40, bz + 84)]), wood)
    m.det([(528, 500, bz + 36, 556, 572, bz + 40)], MM["beam_wood"])                                   # the counter
    m.det([(544, 500, bz + 88, 546, 572, bz + 100)], MAT["black"])                                     # the board over the window
    m.det(m_bars_grid(538, 504, bz + 40, 568, bz + 84), MAT["bars"])
    m.static(P + "props_wasteland/controlroom_chair001a.mdl", 492, 536, 0, z=bz)
    m.light(492, 536, ceil - 20, "255 190 120 20")
    m.blocked(448, 448, 576, 608)
    m.lane(496, 624, pz)
    m.det([(712, 880, TRIM, 728, 896, TRIM + 44), (808, 880, TRIM, 824, 896, TRIM + 44), (704, 876, TRIM + 28, 832, 884, TRIM + 44)], MM["beam_wood"])   # the buffer
    m.bars((704, 904, TRIM, 832, 912, ceil), "u")
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 474, 440, 0, z=pz)
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 474, 716, 0, z=pz)
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 1062, 560, 180, z=pz)
    m.static(P + "props_trainstation/trashcan_indoor001b.mdl", 470, 640, 0, z=pz)
    m.static(P + "props_trainstation/payphone001a.mdl", 1070, 730, 180, z=pz)
    m.loose(P + "props_junk/wood_crate001a.mdl", 1040, 430, 20, z=pz)

    # --- the right station: a car at the platform with a cache in it; somebody has been living here ---
    rc = Car(708, 828, -800, pz, 0, 1, 84, 6)
    rc.build(m, [-800, -740, -680, -620, -560, -500, -440, -424], doors=((0, 1), (0, 4), (1, 3)), seats=((0, 2), (1, 1), (1, 5), (0, 5)),
             bogies=((-770, -700), (-520, -450)))
    m.target("lc_tram_stash", 768, -650, pz + 8, 90)
    m.loose(P + "props_junk/wood_crate001a.mdl", 790, -640, 10, z=pz)
    m.loose(P + "props_junk/wood_crate002a.mdl", 760, -770, 40, z=pz)
    m.static(P + "props_c17/furnituremattress001a.mdl", 520, -760, 90, z=pz)
    m.static(P + "props_c17/lockers001a.mdl", 1066, -700, 180, z=pz)
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 474, -520, 0, z=pz)
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 1062, -520, 180, z=pz)
    m.static(P + "props_c17/oildrum001.mdl", 1050, -790, 0, z=pz)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 600, -450, 30, z=pz)
    m.light(560, -760, pz + 40, "255 150 70 18")                 # (a fire's worth of light by the mattress)
    m.blocked(704, -832, 832, -384)

    # --- the bridge's remains ---
    deck = [(640, 176, TRIM - 16, 708, 256, TRIM), (708, 228, TRIM - 16, 828, 256, TRIM), (828, 208, TRIM - 16, 896, 256, TRIM),
            (640, -256, TRIM - 16, 896, -192, TRIM)]
    m.det(deck, MAT["beam"], top=MAT["quay_floor"])
    girder = []
    for u in (648, 872):                    # under the stubs: a web and a bottom flange to each wall
        for (c1, c2) in ((176 if u == 648 else 208, 256), (-256, -192)):
            girder += [(u + 4, c1, TRIM - 40, u + 12, c2, TRIM - 16), (u, c1, TRIM - 48, u + 16, c2, TRIM - 40)]
    # the whole girder: the beam walk, its top level with both stubs
    girder += [(648, -192, TRIM - 16, 664, 176, TRIM), (652, -192, TRIM - 40, 660, 176, TRIM - 16), (648, -192, TRIM - 48, 664, 176, TRIM - 40)]
    # the other girder: a length out from the left stub, then it sags; a stump on the right
    girder += [(872, 112, TRIM - 16, 888, 208, TRIM), (876, 112, TRIM - 40, 884, 208, TRIM - 16), (872, 112, TRIM - 48, 888, 208, TRIM - 40),
               (872, -192, TRIM - 16, 888, -150, TRIM), (876, -192, TRIM - 40, 884, -150, TRIM - 16)]
    m.det(girder, MAT["bars"])
    m.shapes([para((872, 112, TRIM - 48), (16, 0, 0), (0, -100, -70), (0, 0, 48), MAT["bars"]),
              para((700, -192, TRIM - 16), (110, 0, 0), (0, 44, -40), (0, 0, 16), MAT["beam"], top=MAT["quay_floor"]),              # a slab of deck hinging down
              para((736, -192, TRIM), (4, 0, 0), (0, 60, -52), (0, 0, 3), MAT["bars"]), para((796, -192, TRIM), (4, 0, 0), (0, 52, -60), (0, 0, 3), MAT["bars"])])
    # corbels under the stubs
    m.shapes([prism([(256 * s, TRIM - 48), (200 * s, TRIM - 48), (256 * s, TRIM - 120)], "x", u, u + 16, MAT["beam"]) for s in (1, -1) for u in (648, 872)])
    # the pier the whole girder rests on, and its twin, broken
    m.det([(632, -24, F, 680, 24, TRIM - 64), (624, -32, TRIM - 64, 688, 32, TRIM - 48)], MAT["beam"])
    m.det([(856, -24, F, 904, 24, F + 88)], MAT["beam"])
    m.shapes([para((856, -24, F + 88), (48, 0, 0), (0, 48, 0), (-10, 6, 34), MAT["beam"]),
              para((930, -70, F), (130, 20, 0), (-12, 84, 0), (0, 0, 14), MAT["beam"], top=MAT["quay_floor"]),                       # deck slabs on the floor
              para((560, 40, F), (20, 96, 0), (-70, 10, 44), (0, 0, 14), MAT["beam"], top=MAT["quay_floor"])])
    m.blocked(608, -64, 704, 64)
    m.blocked(832, -64, 928, 64)

    # --- the car that came off: from the left stub down to the floor by the right bank ---
    car = Car(708, 828, -82, F + 8, 4, 5, 104, 5)
    car.build(m, [-82, -32, 18, 68, 118, 168, 218, 228], doors=((0, 2), (1, 4)), seats=((1, 1), (0, 4), (1, 3)), bogies=((18, 68), (168, 218)))
    m.det([(708, -82, F, 828, -72, F + 8)], MAT["bars"])                                              # its sill on the floor
    m.rope([(768, 250, ceil - 4), (768, 150, TRIM + 60)], slack=30)                                   # the wire, still on its roof
    m.rope([(768, -250, ceil - 4), (800, -150, F + 40), (850, -96, F + 6)], slack=60)                 # and the other end of it, down
    for k, c in enumerate((-32, 68, 168)):
        m.lane(768, c, car.zf(c))
    m.lane(768, -104, F)
    m.blocked(672, -256, 864, 0)
    m.static(P + "props_debris/concrete_chunk01a.mdl", 668, -96, 30)
    m.static(P + "props_debris/concrete_chunk02a.mdl", 880, -110, 110)
    m.static(P + "props_debris/broken_pile001a.mdl", 1010, 40, 60)
    m.static(P + "props_debris/concrete_chunk01a.mdl", 590, 110, 200)
    m.loose(P + "props_vehicles/tire001c_car.mdl", 900, 90, 0)
    m.view(430, -60, F, 15, -8, "the car and the bridge")
    m.view(768, -76, F + 8, 90, -30, "up through the car")
    m.view(768, 270, TRIM, 90, 4, "the left station")
    m.view(600, 700, pz, 300, 4, "its platform, looking back")
    m.view(656, 150, TRIM, 270, 14, "the beam walk")
    m.view(600, -430, pz, 290, 4, "the right station")
    b.notes.append("%s: stations at z %d under a roof at z %d; the car's floor climbs from z %d at v -82 to z %d at v 228; the beam is 16 wide at z %d" % (
        m.tag, TRIM, ceil, F + 8, TRIM, TRIM))


def m_bars_grid(u, v1, z1, v2, z2):
    """A booth window's grille: thin bars across a window in a wall that runs along v."""
    out = [(u, v, z1, u + 2, v + 2, z2) for v in range(v1 + 10, v2 - 4, 12)]
    out.append((u, v1, (z1 + z2) // 2, u + 2, v2, (z1 + z2) // 2 + 2))
    return out


MODULES = {
    "tram": (1536, m_tram, "a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk"),
}
