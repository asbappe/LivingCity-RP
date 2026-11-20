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
    # cracks and what is left of the road's lines on the slabs' faces (slivers lying on the lean)
    m.shapes([para((274, 150, F + 20), (0, 5, 0), (70, 0, 140), (-2, 0, 0), MAT["black"]), para((300, 196, F + 72), (0, 3, 0), (40, 0, 80), (-2, 0, 0), MAT["black"]),
              para((494, 120, F + 20), (0, 4, 0), (-60, 0, 120), (2, 0, 0), MAT["black"]), para((330, 60, F + 132), (0, 8, 0), (40, 0, 80), (-2, 0, 0), PLASTER),
              para((452, 200, F + 104), (0, 8, 0), (-40, 0, 80), (2, 0, 0), PLASTER)])
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


# ---------------------------------------------------------------------------
# scrapyard
# ---------------------------------------------------------------------------

def container(m, u1, v1, z, along, mat, open_lo=False, open_hi=False, holes=(), doors="out"):
    """A shipping container of brushes to stand on and walk through: 384 long, 128 wide, 128 high, walls 4 thick.
    (u1, v1): its low corner; along: "u" or "v", the way it lies. open_lo, open_hi: no end wall there (doors: "out",
    the leaves stand open; "flat", folded back along its sides; None). holes: (side 0 or 1, from, to) doorways 96
    high cut in a long wall, measured along it from its low end."""
    def bx(a1, c1, z1, a2, c2, z2):
        return (u1 + a1, v1 + c1, z + z1, u1 + a2, v1 + c2, z + z2) if along == "u" else (u1 + c1, v1 + a1, z + z1, u1 + c2, v1 + a2, z + z2)
    out, thin = [bx(0, 0, 0, 384, 128, 4), bx(0, 0, 124, 384, 128, 128)], []
    for side, (c1, c2) in enumerate(((0, 4), (124, 128))):
        hs = sorted((h[1], h[2]) for h in holes if h[0] == side)
        at = 0
        for (h1, h2) in hs:
            out += [bx(at, c1, 4, h1, c2, 124), bx(h1, c1, 100, h2, c2, 124)]
            at = h2
        out.append(bx(at, c1, 4, 384, c2, 124))
        for a in range(28, 384, 64):                      # the ribs of its sides
            if not any(h1 - 10 < a < h2 + 2 for h1, h2 in hs):
                thin.append(bx(a, c1 - 2 if side == 0 else c2, 8, a + 8, c1 if side == 0 else c2 + 2, 120))
    for is_open, a0, way in ((open_lo, 0, -1), (open_hi, 380, 1)):
        if not is_open:
            out.append(bx(a0, 4, 4, a0 + 4, 124, 124))
            e = a0 - 2 if way < 0 else a0 + 4
            thin += [bx(e, c, 10, e + 2, c + 3, 118) for c in (30, 58, 68, 96)] + [bx(e, 62, 4, e + 2, 66, 124)]      # its doors' locking rods
            continue
        out.append(bx(a0, 4, 112, a0 + 4, 124, 124))
        if doors == "out":
            a1, a2 = (-58, 0) if way < 0 else (384, 442)
            out += [bx(a1, 0, 6, a2, 3, 122), bx(a1, 125, 6, a2, 128, 122)]
        elif doors == "flat":
            a1, a2 = (2, 60) if way < 0 else (324, 382)
            out += [bx(a1, -3, 6, a2, 0, 122), bx(a1, 128, 6, a2, 131, 122)]
    out += [bx(a, c, 0, a + 7, c + 7, 128) for a in (-1, 378) for c in (-1, 122)]          # corner posts, a little proud
    m.det(out, mat)
    m.det(thin, MAT["bars"])
    if z <= F:
        r = bx(-8, -8, 0, 392, 136, 0)
        m.blocked(r[0], r[1], r[3], r[4])


def m_scrapyard(m, opt):
    """The scrapyard. The canal widens 384 on both sides into a yard where the Combine dump what they clear from the
    streets: shipping containers built of brushes (each 384 by 128 by 128, walls 4 thick, to walk through and stand
    on), bales of crushed cars, wrecks, tyres, and a tower crane on a plinth in the far right corner whose jib reaches
    over the yard, its hook hanging on a rope above the highest container.
    On the ground: a container lies across the canal at each end of the yard with a doorway cut through its sides
    (64 wide, 96 high) and both ends open; between them one lies along the middle, open toward the entry, with a
    doorway cut in its right side near its closed end; side lanes left and right run through more containers and
    round the bales. Nothing gives a straight view from one end to the other.
    Over the top: a ramp of planks at each end (128 up over 256) to the roof of the container lying across; from
    the entry one plank bridges on to a covered porch on the middle stack and one to the left stack, where a ramp
    (128 up over 192) climbs to the roof of the second level; a ramp from the far container's roof climbs there too.
    From that roof a plank crosses to a ledge on the middle stack, and a ladder climbs the last 128 to the top of the
    third container (lc_scrap_perch, z 784: level with the canal walls' tops, the whole yard under it). The second
    container of the middle stack is open toward the exit: a nest reached from the far container's roof.
    Named for the game: lc_scrap_perch (an info_target on the highest container: a sniper's or a lookout's place)."""
    b = m.b
    steel, tin, wood, cmb = MM["steel"], MM["tin"], MM["wood"], "metal/metalcombine002"
    L1Z, L2Z, L3Z = F + 128, F + 256, F + 384
    m.open(0, -256, 1536, 256)
    m.open(192, 256, 1344, 640)
    m.open(192, -640, 1344, -256)
    m.side(192, -640, 1344, 640)
    # --- the containers ---
    container(m, 384, -192, F, "v", steel, open_lo=True, open_hi=True, holes=((0, 160, 224), (1, 160, 224)))              # across the canal, entry side
    container(m, 1088, -192, F, "v", DUCT, open_lo=True, open_hi=True, holes=((0, 160, 224), (1, 160, 224)))             # across the canal, exit side
    container(m, 576, -64, F, "u", tin, open_lo=True, holes=((0, 288, 352),), doors="flat")                              # the middle stack: ground
    container(m, 704, -64, L1Z, "u", steel, open_hi=True, doors=None)                                                     # ...second, open toward the exit
    container(m, 576, -64, L2Z, "u", cmb)                                                                                 # ...third: the perch
    container(m, 576, 128, F, "v", DUCT, open_lo=True, holes=((1, 272, 336),), doors="flat")                             # the left stack's way in
    container(m, 768, 256, F, "u", tin, open_hi=True)
    container(m, 832, 256, L1Z, "u", steel)
    container(m, 320, -448, F, "u", cmb, open_hi=True)                                                                    # the right lane
    container(m, 832, -448, F, "u", steel, open_lo=True, open_hi=True)
    container(m, 320, -432, L1Z, "u", DUCT)
    # --- planks: ramps (sheared, never steeper than 128 up over 192) and bridges ---
    planks = []
    for (v1, v2) in ((-168, -146), (-142, -120)):
        planks.append(prism([(128, F), (384, L1Z), (384, L1Z - 6), (140, F)], "y", v1, v2, wood))
    for (v1, v2) in ((120, 142), (146, 168)):
        planks.append(prism([(1472, F), (1216, L1Z), (1216, L1Z - 6), (1460, F)], "y", v1, v2, wood))
    for (v1, v2) in ((296, 318), (322, 344)):
        planks.append(prism([(640, L1Z), (832, L2Z), (832, L2Z - 6), (649, L1Z)], "y", v1, v2, wood))
    for (u1, u2) in ((1152, 1174), (1178, 1200)):
        planks.append(prism([(64, L1Z), (256, L2Z), (256, L2Z - 6), (73, L1Z)], "x", u1, u2, wood))
    m.shapes(planks)
    m.det([(496, 136, L1Z, 592, 158, L1Z + 6), (492, 162, L1Z, 588, 184, L1Z + 6), (496, -24, L1Z, 592, -2, L1Z + 6), (500, 2, L1Z, 596, 24, L1Z + 6),
           (1000, 48, L2Z, 1022, 272, L2Z + 6), (1026, 52, L2Z, 1048, 276, L2Z + 6)], wood)
    m.det([(132, -170, F, 138, -118, F + 5), (1462, 118, F, 1468, 170, F + 5), (780, 290, L1Z, 786, 350, L1Z + 60), (1146, 190, L1Z, 1206, 196, L1Z + 76)], MM["beam_wood"])   # cleats and props
    # --- the perch: a ladder up the third container's end from the ledge, plates to crouch behind ---
    m.ladder(960, 0, L2Z, L3Z, 0)
    m.det([(576, -64, L3Z, 582, 64, L3Z + 26), (582, -64, L3Z, 700, -58, L3Z + 26), (640, 58, L3Z, 760, 64, L3Z + 26), (800, -64, L3Z, 900, -58, L3Z + 22)], steel)
    m.target("lc_scrap_perch", 768, 0, L3Z + 8, 180)
    # --- bales of crushed cars: 64 by 96 by 48, stacked like bricks ---
    bale = [(752, -320, F, 0), (752, -224, F, 1), (752, -288, F + 48, 2), (880, 400, F, 1), (880, 432, F + 48, 0), (1240, 300, F, 2), (1240, 396, F, 0), (1240, 340, F + 48, 1),
            (230, -100, F, 2), (1000, -220, F, 0), (1000, -124, F, 1)]
    for k in range(3):
        boxes = [(u, v, z, u + 64, v + 96, z + 48) for (u, v, z, kind) in bale if kind == k]
        m.det(boxes, (steel, DUCT, tin)[k])
    m.det([(u - 1, v + c, z + 1, u + 65, v + c + 3, z + 49) for (u, v, z, kind) in bale for c in (22, 70)], MAT["bars"])       # their straps
    for (u, v, z, kind) in bale:
        if z == F:
            m.blocked(u - 16, v - 16, u + 80, v + 112)
    # --- the crane: a plinth, a lattice tower, a cab, a jib of three chords over the yard, the hook ---
    tu, tv, top = 1288, -520, F + 600
    m.det([(1232, -576, F, 1344, -464, F + 136)], MAT["beam"], top=MAT["quay_floor"])
    legs = [(tu + du, tv + dv, F + 136, tu + du + 8, tv + dv + 8, top) for du in (-32, 24) for dv in (-32, 24)]
    for z in range(F + 240, top, 116):
        legs += [(tu - 32, tv - 30, z, tu + 32, tv - 26, z + 4), (tu - 32, tv + 26, z, tu + 32, tv + 30, z + 4), (tu - 30, tv - 32, z, tu - 26, tv + 32, z + 4), (tu + 26, tv - 32, z, tu + 30, tv + 32, z + 4)]
    m.det(legs + [(tu - 36, tv - 36, top, tu + 36, tv + 36, top + 6), (tu - 4, tv - 4, top + 6, tu + 4, tv + 4, top + 60)], MAT["bars"])
    m.det([(tu - 30, tv - 30, top - 64, tu + 30, tv + 30, top - 8)], steel)
    m.det([(tu - 31, tv - 8, top - 44, tu - 30, tv + 31, top - 20), (tu - 8, tv + 30, top - 44, tu + 31, tv + 31, top - 20)], MAT["black"])
    m.det([(tu + 30, tv - 40, top - 60, tu + 54, tv - 4, top - 20)], MAT["beam"])                              # the counterweight
    jz = top - 56
    jib = [para((tu - 20, tv + 28, jz), (-580, 580, 0), (6, 6, 0), (0, 0, 8), MAT["bars"]), para((tu - 34, tv + 14, jz), (-580, 580, 0), (6, 6, 0), (0, 0, 8), MAT["bars"]),
           para((tu - 27, tv + 21, jz + 48), (-560, 560, -40), (6, 6, 0), (0, 0, 8), MAT["bars"])]
    for k in range(0, 9):                                                                                   # ties between the chords
        o = (tu - 34 - 70 * k, tv + 14 + 70 * k, jz)
        jib.append(para(o, (20, -20, 0), (4, 4, 0), (0, 0, 6), MAT["bars"]))
        if k:
            jib.append(para((o[0] + 9, o[1] - 5, jz + 8), (4, 4, 0), (-2, 2, 0), (0, 0, 40 - (40 * k) // 14), MAT["bars"]))
    m.shapes(jib)
    hu, hv = 768, 0
    m.det([(hu - 10, hv - 10, jz - 10, hu + 10, hv + 10, jz), (hu - 6, hv - 6, L3Z + 76, hu + 6, hv + 6, L3Z + 92), (hu - 2, hv - 2, L3Z + 60, hu + 2, hv + 2, L3Z + 76),
           (hu - 2, hv - 2, L3Z + 56, hu + 12, hv + 2, L3Z + 60), (hu + 8, hv - 2, L3Z + 56, hu + 12, hv + 2, L3Z + 68)], MAT["bars"])
    m.rope([(hu, hv, jz - 10), (hu, hv, L3Z + 92)], slack=2, width=3)
    m.spot(tu - 40, tv + 40, top - 70, "255 225 180 500", 135, pitch=42, cone=50)
    m.blocked(1216, -592, 1344, -448)
    # --- wrecks, tyres, drums ---
    put(m, P + "props_vehicles/car004a_physics.mdl", 940, 190, 185)
    put(m, P + "props_vehicles/car002a_physics.mdl", 1130, -250, 15)
    put(m, P + "props_vehicles/car005a_physics.mdl", 262, 120, 80)
    put(m, P + "props_vehicles/car002a_physics.mdl", 440, 400, 110)
    put(m, P + "props_vehicles/car004a_physics.mdl", 1280, -120, 250)
    put(m, P + "props_junk/trashdumpster02.mdl", 420, -300, 90)
    for (u, v, n) in ((540, 300, 4), (700, -250, 3), (1060, 440, 5), (1250, 190, 3), (560, -100, 2)):
        for k in range(n):
            m.loose(P + "props_vehicles/tire001c_car.mdl", u + 22 * (k % 3), v + 30 * (k // 3), 90 * (k % 2))
    put(m, P + "props_c17/oildrum001.mdl", 730, 100, 0)
    put(m, P + "props_c17/oildrum001.mdl", 1030, -90, 0)
    put(m, P + "props_c17/oildrum001.mdl", 612, 20, 0, z=L1Z)
    m.loose(P + "props_junk/wood_crate001a.mdl", 700, 20, 10, z=F + 4)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 900, 0, 0, z=L1Z + 4)
    m.loose(P + "props_junk/wood_crate001a.mdl", 760, -30, 30, z=L1Z + 4)
    m.blocked(840, 140, 1040, 240)
    m.blocked(1040, -300, 1220, -200)
    m.blocked(200, 30, 320, 210)
    for (u, v, z) in ((330, 0, F), (448, 0, F + 4), (544, 0, F), (640, 0, F + 4), (820, 0, F + 4), (896, -36, F + 4), (896, -100, F), (1024, -20, F), (1152, 0, F + 4),
                      (1260, 0, F), (448, 230, F), (544, 96, F), (640, 300, F + 4), (736, 432, F), (448, -256, F), (760, -384, F), (1024, -384, F + 4), (1260, -384, F)):
        m.lane(u, v, z)
    m.view(260, -144, F, 5, -6, "the ramp, the way through")
    m.view(448, 0, L1Z, 0, -4, "from the first roof: the stack, the porch")
    m.view(610, 0, F + 4, 0, 2, "inside the middle container")
    m.view(900, 320, L2Z, 250, 8, "the left stack's roof: the plank to the ledge, the ladder")
    m.view(700, 0, L3Z, 180, 16, "from the perch, the way people come")
    m.view(1460, -60, F, 170, -10, "from the far end")
    b.notes.append("%s: the yard is %d by %d; container roofs at z %d, %d and %d (the perch); the crane's tower tops out at z %d, its hook hangs at z %d" % (
        m.tag, 1152, 1280, L1Z, L2Z, L3Z, top + 60, L3Z + 56))


MODULES = {
    "tram": (1536, m_tram, "a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk"),
    "tenement": (1280, m_tenement, "a tenement block fallen across the canal: the way on is through its rooms"),
    "quay": (1024, m_quay, "stairs up to a quay with a street doorway (a cap to delete), a footbridge to a barred door"),
    "collapse": (768, m_collapse, "a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs"),
    "scrapyard": (1536, m_scrapyard, "the canal widens into a yard of stacked containers under a crane: ways through, ways over, a perch"),
}
