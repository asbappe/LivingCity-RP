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


def put(m, model, u, v, yaw=0, z=F):
    """A thing that stays put, standing on z: a prop_static when the model was built to be one, a prop_dynamic if not."""
    ok = False
    try:
        import map_assets
        map_assets.size(model)
        ok = bool((map_assets._known or {}).get(model.lower(), {}).get("static"))
    except Exception:
        ok = False
    (m.static if ok else m.dynamic)(model, u, v, yaw, z)


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
    put(m, P + "props_wasteland/controlroom_chair001a.mdl", 492, 536, 0, z=bz)
    m.light(492, 536, ceil - 20, "255 190 120 20")
    m.blocked(448, 448, 576, 608)
    m.lane(496, 624, pz)
    m.det([(712, 880, TRIM, 728, 896, TRIM + 44), (808, 880, TRIM, 824, 896, TRIM + 44), (704, 876, TRIM + 28, 832, 884, TRIM + 44)], MM["beam_wood"])   # the buffer
    m.bars((704, 904, TRIM, 832, 912, ceil), "u")
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 474, 440, 0, z=pz)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 474, 716, 0, z=pz)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 1062, 560, 180, z=pz)
    put(m, P + "props_trainstation/trashcan_indoor001b.mdl", 470, 640, 0, z=pz)
    put(m, P + "props_trainstation/payphone001a.mdl", 1070, 730, 180, z=pz)
    m.loose(P + "props_junk/wood_crate001a.mdl", 1040, 430, 20, z=pz)

    # --- the right station: a car at the platform with a cache in it; somebody has been living here ---
    rc = Car(708, 828, -800, pz, 0, 1, 84, 6)
    rc.build(m, [-800, -740, -680, -620, -560, -500, -440, -424], doors=((0, 1), (0, 4), (1, 3)), seats=((0, 2), (1, 1), (1, 5), (0, 5)),
             bogies=((-770, -700), (-520, -450)))
    m.target("lc_tram_stash", 768, -650, pz + 8, 90)
    m.loose(P + "props_junk/wood_crate001a.mdl", 790, -640, 10, z=pz)
    m.loose(P + "props_junk/wood_crate002a.mdl", 760, -770, 40, z=pz)
    put(m, P + "props_c17/furnituremattress001a.mdl", 520, -760, 90, z=pz)
    put(m, P + "props_c17/lockers001a.mdl", 1066, -700, 180, z=pz)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 474, -520, 0, z=pz)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 1062, -520, 180, z=pz)
    put(m, P + "props_c17/oildrum001.mdl", 1050, -790, 0, z=pz)
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
    put(m, P + "props_debris/concrete_chunk01a.mdl", 668, -96, 30)
    put(m, P + "props_debris/concrete_chunk02a.mdl", 880, -110, 110)
    put(m, P + "props_debris/broken_pile001a.mdl", 1010, 40, 60)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 590, 110, 200)
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


# ---------------------------------------------------------------------------
# tenement
# ---------------------------------------------------------------------------

def m_tenement(m, opt):
    """The fallen tenement. A block that stood on the left street has gone into the canal and lies across it from u 320
    to 960: there is no way round, the way on is through its rooms. Its body fills the canal from the right wall to
    v 128; the strip left over by the left wall is choked by its own outer wall, fallen in slabs (with an unseen wall
    for players in it). Ground floor, 112 high: an entry hall, a living room, a kitchen, a stair hall open to the
    leaning roof, a bedroom, a small room with a bed, and behind that a nook that is easy to miss (a crawl hole 40
    high by the bed, or a hole in the floor above): lc_tenement_stash. A stair climbs to the one room left upstairs,
    with a window over the canal the far way (lc_tenement_lookout); out of that window is a drop, never a way in.
    The roof is sheared slabs lying where they slid. Where the block stood, the left wall is bitten out down to the
    trim, with its cellar walls and floor beams left.
    The way through, door by door (wide by high): the hole in the entry wall 64 by 88; hall to living room 48 by 84;
    living room to kitchen 48 by 88; kitchen door to the stair hall 48 by 96; stair hall to bedroom 48 by 92; the hole
    in the far wall 64 by 92. A short cut from the hall to the stair hall is a crawl, 48 by 40.
    Named for the game: lc_tenement_stash (an info_target in the nook: a cache), lc_tenement_lookout (an info_target
    at the upstairs window: a sentry's place)."""
    b = m.b
    g, zc, up, top = F + 8, F + 120, F + 136, F + 248
    wood, tin = MM["wood"], MM["tin"]
    m.open(0, -256, 1280, 256)
    m.open(448, 256, 832, 384, floor=TRIM, mat=DIRT)               # where it stood
    m.side(320, -256, 960, 384)
    m.no_bank(320, -264, 960, -248)
    m.blocked(304, -256, 976, 384)
    m.taken(296, -256, F, 984, 256, b.rim)
    # --- the outer walls (brick, 16 thick) ---
    ew = wall(320, -256, 336, 128, F, up + 48, [(16, 80, g, g + 88)])
    ew += [(320, -256, up + 48, 336, -196, up + 96), (320, -92, up + 48, 336, -20, up + 76), (320, 56, up + 48, 336, 128, up + 104)]
    xw = wall(944, -256, 960, 128, F, top, [(16, 80, g, g + 92), (-176, -48, up + 40, up + 88)])
    lw = [(336, 112, F, 944, 128, up), (544, 112, up, 944, 128, top), (752, 112, top, 944, 128, top + 40),
          (336, 112, up, 424, 128, up + 64), (468, 112, up, 544, 128, up + 28)]
    bw = [(336, -256, F, 944, -240, up), (736, -256, up, 944, -240, top)]
    m.det(ew + xw + lw, BRICK)
    m.det(bw, PLASTER)
    m.shapes([prism([(-256, top), (128, top), (128, top + 44)], "x", 944, 960, BRICK), prism([(-240, top), (112, top), (112, top + 40)], "x", 736, 752, PLASTER)])
    m.det([(942, -180, up + 36, 962, -44, up + 40), (942, 12, g + 92, 962, 84, g + 98), (318, 12, g + 88, 338, 84, g + 94)], MM["beam_wood"])     # a sill, two lintels
    # --- the walls inside (plaster) ---
    p1 = wall(336, -64, 944, -48, g, zc, [(400, 448, g, g + 84), (624, 672, g, g + 96), (776, 824, g, g + 92)])
    p1 += [(544, -64, zc, 736, -48, top - 20), (544, -64, top - 20, 632, -48, top)]
    p2 = wall(528, -240, 544, 112, g, zc, [(-176, -128, g, g + 88), (24, 72, g, g + 40)])
    p3 = wall(736, -240, 752, 112, g, zc, [(-24, 24, g, g + 92)]) + wall(736, -240, 752, 112, up, top, [(64, 112, up, up + 96)])
    p4 = wall(848, -240, 864, -64, g, zc, [(-240, -200, g, g + 40)])
    m.det(p1 + p2 + p3 + p4, PLASTER)
    m.det([(620, -66, g, 624, -46, g + 100), (672, -66, g, 676, -46, g + 100), (620, -66, g + 96, 676, -46, g + 100)], MM["beam_wood"])          # the kitchen's door frame
    # --- floors ---
    m.det([(336, -240, F, 544, 112, g), (544, -64, F, 736, 112, g), (736, -240, F, 944, 112, g)], MAT["canal_wall"], top=wood)
    m.det([(544, -240, F, 736, -64, g)], MAT["canal_wall"], top=TILE)
    m.det(floor_with_holes(336, -240, 544, 112, zc, up, [(416, -200, 496, -120)]) + [(544, -240, zc, 736, -48, up)], MAT["ceiling"], top=MAT["quay_floor"])
    m.det(floor_with_holes(736, -240, 944, 112, zc, up, [(880, -232, 928, -184)]), MAT["ceiling"], top=wood)
    m.steps(544, 64, 112, g, up, "u", 1)
    # --- the roof, where it slid (sheared slabs) ---
    m.shapes([para((728, -256, top), (232, 0, 0), (0, 392, 48), (0, 0, 12), tin),
              para((336, -256, up + 4), (0, 184, 0), (400, 0, 108), (0, 0, 12), tin),
              para((352, -40, up + 12), (0, 160, 0), (384, 0, 128), (0, 0, 12), tin),
              # the outer wall, fallen into the strip by the left wall
              para((336, 128, top - 24), (608, 0, 0), (0, 128, -72), (0, 0, 16), BRICK),
              para((308, 120, F), (0, 136, 0), (36, 0, 236), (16, 0, 0), BRICK),
              para((956, 120, F), (0, 136, 0), (-36, 0, 250), (16, 0, 0), BRICK),
              para((276, 136, F), (14, 110, 0), (40, -8, 150), (12, 0, 0), MAT["beam"]),
              para((1000, 140, F), (-10, 100, 0), (-44, 6, 170), (12, 0, 0), MAT["beam"]),
              # slabs thrown clear of it, on the canal's floor
              para((150, -200, F), (120, 30, 0), (-20, 90, 0), (0, 0, 12), MAT["beam"], top=BRICK),
              para((1040, -60, F), (100, -20, 0), (16, 70, 30), (0, 0, 12), MAT["beam"], top=BRICK)])
    clip(m, (308, 128, F, 972, 256, b.sky))
    clip(m, (320, -256, up + 4, 544, 128, b.sky))
    clip(m, (544, -256, up + 4, 736, -64, b.sky))
    clip(m, (544, -64, top + 64, 960, 128, b.sky))
    clip(m, (736, -256, top + 64, 960, -64, b.sky))
    # --- where it stood: cellar walls and floor beams in the bite ---
    m.det([(448, 368, TRIM, 832, 384, TRIM + 44), (448, 256, TRIM, 464, 368, TRIM + 28), (816, 256, TRIM, 832, 368, TRIM + 60), (632, 300, TRIM, 648, 368, TRIM + 36)], BRICK)
    m.det([(u, 226, TRIM - 14, u + 10, 330, TRIM) for u in (500, 590, 700, 780)], MM["beam_wood"])
    # --- what is in the rooms ---
    put(m, P + "props_c17/furniturecouch001a.mdl", 366, -150, 0, z=g)
    put(m, P + "props_debris/broken_pile001a.mdl", 444, -200, 20, z=g)
    put(m, P + "props_c17/furnitureradiator001a.mdl", 492, -232, 90, z=g)
    put(m, P + "props_c17/furniturestove001a.mdl", 700, -218, 90, z=g)
    put(m, P + "props_interiors/sinkkitchen01a.mdl", 640, -224, 90, z=g)
    put(m, P + "props_interiors/refrigerator01a.mdl", 580, -220, 90, z=g)
    put(m, P + "props_c17/furnituretable002a.mdl", 684, -150, 0, z=g)
    m.loose(P + "props_c17/furniturechair001a.mdl", 646, -150, 0, z=g)
    put(m, P + "props_c17/furnituredresser001a.mdl", 488, 90, 270, z=g)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 384, -16, 40, z=g)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 470, 16, 100, z=g)
    m.loose(P + "props_junk/wood_crate001a.mdl", 580, -20, 15, z=g)
    put(m, P + "props_c17/furnituremattress001a.mdl", 860, 90, 0, z=g)
    m.loose(P + "props_c17/furniturechair001a.mdl", 782, 94, 200, z=g)
    put(m, P + "props_c17/furniturebed001a.mdl", 792, -178, 90, z=g)
    put(m, P + "props_interiors/furniture_shelf01a.mdl", 836, -104, 180, z=g)
    m.loose(P + "props_junk/wood_crate001a.mdl", 914, -92, 0, z=g)
    m.loose(P + "props_junk/wood_crate002a.mdl", 900, -140, 90, z=g)
    put(m, P + "props_c17/furnituretable001a.mdl", 900, 40, 0, z=up)
    m.loose(P + "props_c17/furniturechair001a.mdl", 862, 40, 0, z=up)
    put(m, P + "props_c17/furnituremattress001a.mdl", 800, -200, 90, z=up)
    put(m, P + "props_c17/oildrum001.mdl", 782, 24, 0, z=up)
    put(m, P + "props_c17/furniturecouch002a.mdl", 176, -84, 140)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 250, -40, 70)
    put(m, P + "props_debris/broken_pile001a.mdl", 1030, 70, 100)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 1090, -90, 10)
    m.target("lc_tenement_stash", 904, -150, g + 8, 90)
    m.target("lc_tenement_lookout", 920, -112, up + 8, 0)
    # --- light: grey from the holes in the roof, one lamp left burning in the kitchen, a candle's worth elsewhere ---
    m.light(456, -160, up + 10, "190 205 230 45")
    m.light(640, 20, top - 30, "190 205 230 55")
    m.lamp(640, -150, zc - 8, "255 200 140 28")
    m.light(432, 32, zc - 24, "200 210 230 10")
    m.light(848, 32, g + 40, "255 170 100 12")
    m.light(904, -120, g + 30, "255 160 90 6")
    m.light(900, -100, top - 30, "190 205 230 30")
    # --- the way through, for those who cannot crawl ---
    for (u, v, z) in ((290, 48, F), (360, 48, g), (424, 16, g), (424, -56, g), (440, -130, g), (536, -152, g), (600, -150, g), (648, -100, g), (648, -56, g),
                      (656, 0, g), (744, 0, g), (800, 16, g), (880, 40, g), (952, 48, g), (1000, 48, F), (800, -56, g), (800, -100, g),
                      (560, 88, g + 8), (724, 88, up), (800, 80, up), (860, -60, up)):
        m.lane(u, v, z)
    m.view(150, 60, F, 0, 0, "what is left of it")
    m.view(350, 48, g, 320, 4, "the hall: the hole to the living room, the crawl")
    m.view(716, -84, g, 215, 8, "the kitchen")
    m.view(570, 20, g, 20, -14, "the stair hall")
    m.view(790, 60, up, 310, 6, "upstairs: the window")
    m.view(800, -84, g, 290, 16, "the small room: the nook's hole by the bed")
    m.view(1180, 30, F, 180, -6, "looking back at it")
    b.notes.append("%s: the block lies across u 320 to 960; ground floor z %d, upstairs z %d; every door on the way through is at least 48 wide and 84 high" % (m.tag, g, up))


# ---------------------------------------------------------------------------
# quay
# ---------------------------------------------------------------------------

def m_quay(m, opt):
    """The quay: a way up to the streets. Stairs 64 wide climb along the left wall from the canal floor (u 64) to a
    landing at the trim's height (u 448 to 512), with a rail on the canal's side. The landing opens onto a quay
    recessed into the left wall, 640 by 256 and open to the sky: a low wall along its edge, two lamp posts built of
    brushes, mooring bollards with a boat roped below, a skip, a bench, crates. At the back a street doorway 128 wide
    and 128 high stands in a concrete frame, closed 64 in by a cap of the world in its own visgroup ("the quay's
    street end (delete to join a street)"). From the quay a footbridge on two trestles crosses to a barred doorway in
    the right wall, black behind its bars.
    Named for the game: lc_quay_street (an info_target in the street doorway, facing the quay: where people arrive
    from the street), lc_quay_far_door (an info_target on the bridge before the barred door)."""
    b = m.b
    steel = MM["steel"]
    m.open(0, -256, 1024, 256)
    m.open(320, 256, 960, 512, floor=TRIM, mat=MAT["quay_floor"])
    m.low(576, 512, 704, 640, TRIM + 128, floor=TRIM, mat=MAT["quay_floor"])
    m.low(832, -320, 896, -256, TRIM + 112, floor=TRIM)
    m.side(320, 256, 960, 640)
    m.side(832, -320, 896, -256)
    m.world((576, 576, TRIM, 704, 640, TRIM + 128), MAT["black"], vis="%s: the quay's street end (delete to join a street)" % b.vis)
    b.plan.keep_out.append(m.fr.rect(512, 640, 768, 704))
    m.blocked(576, 512, 704, 640)
    m.target("lc_quay_street", 640, 544, TRIM + 8, 270)
    # --- the stairs along the wall, their landing, the rail ---
    m.no_bank(0, 248, 512, 264)
    m.steps(64, 192, 256, F, TRIM, "u", 1)
    m.det([(448, 192, F, 512, 256, TRIM)], MAT["canal_wall"], top=MAT["quay_floor"])
    rail = [(64 + 48 * k, 192, F + 8 * (4 * k + 1), 68 + 48 * k, 196, F + 40 + 32 * k) for k in range(8)]
    rail += [(u, 192, TRIM, u + 4, 196, TRIM + 40) for u in (448, 478, 508)] + [(508, 224, TRIM, 512, 228, TRIM + 40), (508, 252, TRIM, 512, 256, TRIM + 40)]
    rail += [(448, 192, TRIM + 36, 512, 196, TRIM + 40), (508, 192, TRIM + 36, 512, 256, TRIM + 40), (448, 192, TRIM + 16, 512, 194, TRIM + 19), (510, 192, TRIM + 16, 512, 256, TRIM + 19)]
    m.det(rail, MAT["bars"])
    m.shapes([prism([(64, F + 40), (448, TRIM + 40), (448, TRIM + 44), (64, F + 44)], "y", 192, 196, MAT["bars"]),
              prism([(64, F + 20), (448, TRIM + 20), (448, TRIM + 23), (64, F + 23)], "y", 192, 194, MAT["bars"])])
    m.blocked(0, 128, 512, 256)
    m.taken(0, 176, F, 520, 256, TRIM + 64)
    for (u, z) in ((36, F), (160, F + 64), (304, F + 160), (480, TRIM)):
        m.lane(u, 224, z)
    # --- the quay: a low wall along its edge (a gap at the landing, a gap at the footbridge), its coping ---
    edge = [(320, 448), (512, 832), (896, 960)]
    m.det([(a, 256, TRIM, c, 268, TRIM + 40) for a, c in edge], MAT["canal_wall"])
    m.det([(a - (0 if a == 320 else 2), 254, TRIM + 40, c + (0 if c == 960 else 2), 270, TRIM + 44) for a, c in edge], MAT["beam"])
    # the street doorway's frame, standing proud of the back wall
    m.det([(556, 496, TRIM, 576, 512, TRIM + 128), (704, 496, TRIM, 724, 512, TRIM + 128), (548, 492, TRIM + 128, 732, 512, TRIM + 152)], MAT["beam"])
    m.det([(576, 508, TRIM + 112, 704, 512, TRIM + 128)], MAT["black"])                      # where a street's name was
    # two lamp posts
    for (u, v, way) in ((344, 290, 1), (928, 484, -1)):
        m.det([(u - 8, v - 8, TRIM, u + 8, v + 8, TRIM + 14), (u - 3, v - 3, TRIM + 14, u + 3, v + 3, TRIM + 184),
               (u - 2, v + 40 * way, TRIM + 178, u + 2, v, TRIM + 182), (u - 5, v - 5, TRIM + 184, u + 5, v + 5, TRIM + 188)], MAT["bars"])
        m.shapes([prism([(v - 3, TRIM + 150), (v + 30 * way, TRIM + 178), (v + 34 * way, TRIM + 178), (v - 3, TRIM + 146)], "x", u - 1, u + 1, MAT["bars"])])
        m.lamp(u, v + 40 * way, TRIM + 166, "255 205 150 90", hang=4)
        m.blocked(u - 24, v - 24, u + 24, v + 24)
    # bollards: three before the street doorway, two for mooring on the edge
    for (u, v) in ((560, 440), (640, 440), (720, 440), (548, 290), (760, 290)):
        m.det([(u - 6, v - 6, TRIM, u + 6, v + 6, TRIM + 28), (u - 8, v - 8, TRIM + 28, u + 8, v + 8, TRIM + 34)], steel)
    put(m, P + "props_junk/trashdumpster02.mdl", 424, 440, 0, z=TRIM)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 800, 494, 270, z=TRIM)
    put(m, P + "props_trainstation/payphone001a.mdl", 752, 500, 270, z=TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 936, 300, 0, z=TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 906, 296, 0, z=TRIM)
    m.loose(P + "props_junk/wood_crate001a.mdl", 928, 350, 20, z=TRIM)
    m.loose(P + "props_junk/wood_crate002a.mdl", 600, 300, 90, z=TRIM)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 668, 300, 30, z=TRIM)
    put(m, P + "props_canal/boat001a.mdl", 690, 70, 12)
    m.rope([(760, 290, TRIM + 30), (752, 250, TRIM + 44), (720, 96, F + 40)], slack=70)
    m.blocked(580, 0, 800, 128)
    m.lane(480, 330, TRIM)
    m.lane(640, 380, TRIM)
    m.lane(640, 490, TRIM)
    m.lane(864, 330, TRIM)
    # --- the footbridge: a plank deck on two girders, two trestles, a rail each side ---
    m.det([(832, -256, TRIM - 6, 896, 256, TRIM)], MM["beam_wood"], top=MM["wood"])
    m.det([(836, -256, TRIM - 24, 842, 256, TRIM - 6), (886, -256, TRIM - 24, 892, 256, TRIM - 6)], MAT["bars"])
    br = []
    for u in (832, 894):
        br += [(u, -256, TRIM + 38, u + 2, 256, TRIM + 41), (u, -256, TRIM + 19, u + 2, 256, TRIM + 21)]
        br += [(u, v, TRIM, u + 2, v + 2, TRIM + 38) for v in range(-256, 257, 64) if v < 256] + [(u, 254, TRIM, u + 2, 256, TRIM + 38)]
    for v in (-100, 96):
        br += [(836, v, F, 842, v + 6, TRIM - 24), (886, v, F, 892, v + 6, TRIM - 24), (836, v + 1, F + 120, 892, v + 5, F + 124), (832, v - 2, TRIM - 30, 896, v + 8, TRIM - 24)]
        m.shapes([prism([(842, F + 4), (886, F + 116), (886, F + 120), (842, F + 8)], "y", v + 2, v + 4, MAT["bars"]),
                  prism([(886, F + 124), (842, F + 226), (842, F + 230), (886, F + 128)], "y", v + 2, v + 4, MAT["bars"])])
        m.blocked(816, v - 24, 912, v + 32)
    m.det(br, MAT["bars"])
    m.taken(808, 216, F, 920, 256, TRIM + 48)
    m.taken(808, -256, F, 920, -216, b.rim)
    for v in (200, 0, -200):
        m.lane(864, v, TRIM)
    # --- the barred doorway across: bars in its mouth, black behind, a steel frame, a dim lamp over it ---
    m.bars((832, -266, TRIM, 896, -258, TRIM + 112), "u")
    m.det([(832, -320, TRIM, 896, -274, TRIM + 112)], MAT["black"])
    m.det([(824, -256, TRIM, 832, -250, TRIM + 120), (896, -256, TRIM, 904, -250, TRIM + 120), (824, -256, TRIM + 112, 904, -250, TRIM + 120)], steel)
    m.lamp(864, -244, TRIM + 122, "255 120 90 25")
    m.blocked(832, -320, 896, -256)
    m.target("lc_quay_far_door", 864, -230, TRIM + 8, 270)
    m.view(20, 150, F, 20, -8, "the stairs")
    m.view(480, 224, TRIM, 40, 6, "from the landing")
    m.view(900, 300, TRIM, 160, 2, "the quay, the street doorway")
    m.view(864, 200, TRIM, 270, 6, "the footbridge")
    m.view(560, -110, F, 50, -22, "from the canal")
    b.notes.append("%s: the street end is at (%d %d), floor z %d, 128 wide and 128 high: bring a street to it, then delete its cap" % ((m.tag,) + m.fr.pt(640, 640) + (TRIM,)))


# ---------------------------------------------------------------------------
# collapse
# ---------------------------------------------------------------------------

def m_collapse(m, opt):
    """The cave-in. The left street's retaining wall and a length of roadway have come down across the canal (the wall
    is bitten out to a ledge of earth at z 528, open to the sky). From the bite to v 32 two great slabs lean on each
    other like a tent, its ridge at z 640; from v 32 a wedge of roadway slopes down to a standing piece of the wall at
    v -160. Every face is steeper than a player can walk. Two ways through:
    the squeeze: 96 wide between that standing piece and the right wall (v -256 to -160), open to the sky, no bank;
    the crawl: a hole 48 wide and 44 high at the foot of the near slab (v 72 to 120) into the hollow under the tent
    (192 by 96 of flat floor, room to stand, earth sloping up behind), and another out through the far slab (v 40 to
    88): the two holes do not line up, so nobody sees or shoots straight through. The hollow is a hide
    (lc_collapse_hide). Each side also has a perch: the earth bank leads up to the end of the bite's ledge beside the
    slabs. Rebar, a car that came down with the road, rubble.
    Named for the game: lc_collapse_hide (an info_target in the hollow under the slabs)."""
    b = m.b
    con = MAT["beam"]
    m.open(0, -256, 768, 256)
    m.open(256, 256, 512, 384, floor=F + 128, mat=DIRT)
    m.side(256, 256, 512, 384)
    m.no_bank(256, 248, 512, 264)
    m.no_bank(192, -264, 576, -248)
    m.taken(176, -256, F, 592, -200, b.rim)
    m.taken(232, 200, F, 536, 256, b.rim)
    # --- the tent: two slabs leaning 1 in 2, 24 thick, a crawl hole at the foot of each ---
    near_low, near_up = [(264, F), (288, F), (310, F + 44), (286, F + 44)], [(286, F + 44), (310, F + 44), (408, F + 240), (384, F + 240)]
    far_low, far_up = [(504, F), (480, F), (458, F + 44), (482, F + 44)], [(482, F + 44), (458, F + 44), (360, F + 240), (384, F + 240)]
    m.shapes([prism(near_low, "y", 32, 72, con), prism(near_low, "y", 120, 256, con), prism(near_up, "y", 32, 256, con, ROAD),
              prism(far_low, "y", 32, 40, con), prism(far_low, "y", 88, 256, con), prism(far_up, "y", 32, 256, con, ROAD),
              # ...and on across the bite's ledge
              prism([(328, F + 128), (352, F + 128), (408, F + 240), (384, F + 240)], "y", 256, 384, con),
              prism([(440, F + 128), (416, F + 128), (360, F + 240), (384, F + 240)], "y", 256, 384, con),
              # the earth that came with the wall, in place of the bank
              prism([(256, F + 128), (128, F), (256, F)], "x", 256, 512, DIRT),
              # the wedge of roadway from the tent down to the standing piece, its skin of road, and the piece itself
              prism([(-144, F), (32, F), (32, F + 216)], "x", 288, 480, con),
              para((276, -144, F), (216, 0, 0), (0, 176, 216), (0, 0, 10), ROAD),
              para((280, -160, F), (208, 0, 0), (0, 24, 150), (0, 16, 0), MAT["canal_wall"]),
              # slabs lying about, both sides
              para((120, 20, F), (110, 24, 0), (-18, 80, 0), (0, 0, 12), con, top=ROAD),
              para((180, -130, F), (70, -10, 0), (10, 60, 26), (0, 0, 12), con, top=ROAD),
              para((560, 96, F), (120, -20, 0), (14, 76, 0), (0, 0, 12), con, top=ROAD),
              para((520, -140, F), (16, 70, 0), (40, 6, 70), (10, 0, 0), con)])
    # rebar: out of the ridge, out of the wedge's edges, out of the bite's lip
    bars = [(382 + (k % 3) * 3, v, F + 236, 384 + (k % 3) * 3, v + 2, F + 262 + 9 * (k % 4)) for k, v in enumerate(range(44, 250, 23))]
    bars += [(286, v, F + 150 + k * 20, 290, v + 2, F + 152 + k * 20) for k, v in enumerate((-40, -10, 14))]
    bars += [(476, v, F + 96 + k * 30, 500, v + 2, F + 98 + k * 30) for k, v in enumerate((-90, -50, 0))]
    bars += [(u, 236, F + 122, u + 2, 262, F + 124) for u in (268, 300, 470, 500)]
    m.det(bars, MAT["bars"])
    m.shapes([para((300 + 40 * k, -160, F + 150), (2, 0, 0), (0, 2, 0), (6 - 4 * k, 5, 28 + 6 * k), MAT["bars"]) for k in range(5)])
    clip(m, (380, -160, F + 192, 388, 384, b.sky))
    # --- the hollow: somebody's hide ---
    m.target("lc_collapse_hide", 384, 64, F + 8, 90)
    put(m, P + "props_c17/furnituremattress001a.mdl", 420, 104, 0)
    m.loose(P + "props_junk/wood_crate001a.mdl", 340, 52, 20)
    put(m, P + "props_c17/oildrum001.mdl", 440, 56, 0)
    m.light(384, 84, F + 150, "200 210 230 14")
    # --- outside ---
    put(m, P + "props_vehicles/car004a_physics.mdl", 628, -36, 168)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 226, 150, 30)
    put(m, P + "props_debris/broken_pile001a.mdl", 216, -40, 80)
    put(m, P + "props_debris/concrete_chunk02a.mdl", 240, 60, 140)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 548, 170, 100)
    put(m, P + "props_debris/broken_pile001a.mdl", 560, -200, 10)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 250, -210, 60)
    m.loose(P + "props_vehicles/tire001c_car.mdl", 700, 60, 0)
    put(m, P + "props_wasteland/rockgranite02a.mdl", 300, 330, 0, z=F + 128)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 470, 320, 60, z=F + 128)
    m.blocked(192, -160, 576, 384)
    m.blocked(520, -100, 740, 30)
    for u in (176, 300, 384, 470, 592):
        m.lane(u, -208, F)
    m.view(120, -150, F, 350, 0, "the squeeze")
    m.view(150, 110, F, 0, 2, "the crawl")
    m.view(320, 56, F, 50, -12, "in the hollow")
    m.view(290, 290, F + 128, 300, 14, "from the perch")
    m.view(700, 20, F, 180, -8, "looking back")
    b.notes.append("%s: the squeeze is 96 wide along the right wall; the crawl's two holes are 48 wide and 44 high; the tent's ridge is at z %d" % (m.tag, F + 240))


MODULES = {
    "tram": (1536, m_tram, "a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk"),
    "tenement": (1280, m_tenement, "a tenement block fallen across the canal: the way on is through its rooms"),
    "quay": (1024, m_quay, "stairs up to a quay with a street doorway (a cap to delete), a footbridge to a barred door"),
    "collapse": (768, m_collapse, "a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs"),
}
