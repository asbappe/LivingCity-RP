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

import math

from map_build import CELL, FACE_ORDER, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM, SCAPES, canal_grime
from map_mods_b import fire, mattress, rider

TILE = "tile/tilefloor018a_c17"
BRICK = "brick/brickwall045d"
PLASTER = "plaster/plasterwall042c"
ROAD = "concrete/concretefloor016a"
DIRT = "nature/dirtfloor005c"
DUCT = "metal/metalwall014a"      # (the guide lists metal/metalduct003a, but no such material is in the game: it is props/metalduct003a)
STONE = "stone/stonewall040f"
WOODTRIM = "wood/woodwall006a"    # (the owner's own panelling and trims: their map has no wood/woodbeam001a)
HULL = "metal/metalhull010c"      # (the owner's own steel plate: their map has no metal/metalhull003a)
P = "models/"
M_ = "models/"


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


def vprism(pts, z1, z2, mat, top=None):
    """A standing prism: a flat outline seen from above, [(u, v), ...] in order round it, from z1 up to z2."""
    faces = [([(u, v, z1) for u, v in pts], mat), ([(u, v, z2) for u, v in pts], top or mat)]
    for k in range(len(pts)):
        (a, c), (d, e) = pts[k], pts[(k + 1) % len(pts)]
        faces.append(([(a, c, z1), (d, e, z1), (d, e, z2), (a, c, z2)], mat))
    return faces


def arch(a, b, zt, rise, lo, hi, mat, axis="x"):
    """The haunches of an arch over an opening from a to b under a soffit at zt: prisms that round its two top corners
    (three facets a side), pushed from lo to hi along u (axis "x": the opening is in v) or along v ("y": it is in u).
    Each facet stops 1 short of the last at both ends, so no two of their end faces share a plane (they would flicker)."""
    out = []
    for corner, way in ((a, 1), (b, -1)):
        pts = [(corner, zt - rise), (corner + way * (rise // 8), zt - rise // 2), (corner + way * (3 * rise // 8), zt - (3 * rise) // 16), (corner + way * rise, zt)]
        for k in range(3):
            out.append(prism([(corner, zt), pts[k], pts[k + 1]], axis, lo + k, hi - k, mat))
    return out


def wall_stair(m, start, v1, v2, sign, rail_v):
    """Stairs 64 wide along a canal wall from the floor up to the trim's height, rising along u from `start` in the way
    of sign, with the city's own stair rail on the canal's side (rail_v: that side's v): two handrail04_doublerise, each
    rising 128 over 192 as these stairs do (their origins are at their middles, so they are set by hand)."""
    run = m.steps(start, v1, v2, F, TRIM, "u", sign)
    end = start + sign * run
    side = (rail_v - 8, rail_v) if rail_v == v1 else (rail_v, rail_v + 8)
    m.stair_side(start, run, side[0], side[1], F, TRIM, sign)          # its open side solid from the floor (the module review)
    rv = rail_v + 2 if rail_v == v1 else rail_v - 2
    for d, z in ((96, F + 88), (288, F + 216)):
        tilted(m, "prop_static", P + "props_c17/handrail04_doublerise.mdl", start + sign * d, rv, z, 270 if sign > 0 else 90)
    return end


def clip(m, box):
    """An unseen wall for players only (it seals nothing)."""
    m.world(box, MAT["clip"], vis=m.b.vis + ": player clips", seals=False)


def tilted(m, cls, model, u, v, z, yaw, pitch=0, roll=0, keys=None):
    """A prop at an angle, its origin exactly at (u, v, z) (never lifted to stand: work its height out for the tilt).
    Turned by yaw in the module, then pitched (its front, +x, goes down) and rolled (its left side, +y, goes up), the way
    the game reads "angles". cls: prop_static (only for a model built static) or prop_dynamic."""
    wy = m.fr.yaw(yaw)
    k = {"model": model, "angles": "%g %g %g" % (pitch, round(wy, 2), roll), "skin": "0", "solid": "6", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
    if cls == "prop_static":
        k.update({"disableshadows": "0", "screenspacefade": "0"})
    else:
        k.update({"disableshadows": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})
    k.update(keys or {})
    m.point(cls, u, v, z, k, m.pv)
    m.b.props.append((cls, model, m.fr.at(u, v, z), wy, m.tag))


def steps_up(m, u1, u2, start, z1, z2, sign, axis="v"):
    """Hand-made stairs as m.steps makes them (16 up, 24 along), rising from z1 at `start` in the way of sign along axis,
    u1..u2 across (for axis "u": v1..v2 across). Returns where they end."""
    n = max(1, -(-(z2 - z1) // 16))
    out = []
    for i in range(n):
        a, c = start + sign * 24 * i, start + sign * 24 * (i + 1)
        top = z1 + (z2 - z1) * (i + 1) // n
        a, c = min(a, c), max(a, c)
        out.append((u1, a, z1, u2, c, top) if axis == "v" else (a, u1, z1, c, u2, top))
    m.det(out, MAT["canal_wall"], top=MAT["stairs"])
    return start + sign * 24 * n


# ---------------------------------------------------------------------------
# tram
# ---------------------------------------------------------------------------

CAR = "models/props_trainstation/passengercar001.mdl"            # Episode Two's own passenger car (the owner's choice)
WRECK = "models/props_trainstation/passengercar001_dam01b.mdl"   # the same car crushed, its front end torn off
BOGIE = "models/props_trainstation/train_wheels1.mdl"


def m_tram(m, opt):
    """The fallen tram bridge. A tram line crossed the canal here, 96 over its floor; its bridge is gone but for a stub
    of deck at each wall, one whole girder on a pier and one that sags. In each wall a station opens: a short mouth, then
    a hall with a platform 64 high either side of a track pit, dressed in Half-Life 2's own station kit: its cast iron
    columns (trainstation_column001) carrying its arches (column_arch001a between them, ceiling_arch001a to the back
    wall) under a girder across the hall, a plaster ceiling, walls in two tones as the city's station (brick to the
    shoulder, a rail, plaster over it), its wall lamps (light_128wallmounted001a) each with a beam down on the platform,
    its indoor benches, bins and payphone, route signs and the city's notices on the walls. Episode Two's own passenger
    car, crushed and its front end torn off (passengercar001_dam01b), has come off the bridge: it lies across the canal
    from the right bank's foot, where its open front end is on the floor, up over the left mouth's lip into the left
    station, about 13 degrees, leaning 5 to one side; two of its seats and a suitcase spilled out of its open end. Walk in
    at its open end and up through it into the left station (its doors there open onto the mouth's ledges, its far end
    over the pit). The overhead wire still hangs from it, snapped, its live end spitting sparks on the canal floor. The
    left station has a ticket booth with a barred window and, at the back, a stair up to the street behind a prison's
    sliding gate with a danger sign over it, black beyond (lc_tram_exit); its pit ends in the line's own buffer stop and
    steps up to a concourse, a signal on the far platform, the station clock stopped over the concourse. The right station
    is reached only along the whole girder, a beam 16 wide and 368 long, 96 over the floor (steps at its end climb from
    the pit to the platform): the same car whole (passengercar001) stands at its platform on two bogies with a cache in it
    (lc_tram_stash), and somebody has been living on that platform (a mattress, a fire in a drum, a lambda on the wall).
    Dropping from either stub is safe. Sounds: the station's own soundscape in each hall (d1_trainstation.Turnstyle, which
    the owner's map uses), the metal groaning over the wreck (coast.util_metalstress).
    Named for the game: lc_tram_exit (an info_target on the left platform before the barred stair: where people come
    from or go to the street), lc_tram_stash (an info_target inside the car in the right station: a cache).
    Left as brushes: the stations' walls, platforms, steps, tiles and girders (architecture), the bridge's deck, girders
    and pier (a building's frame), the rails (no single track narrower than 288 exists as a model), the booth's walls.
    Unchecked: the cars are Episode Two's (players without it see errors; the owner asked for them); that the cars' own
    collision lets a player walk inside them, where their doors are and that the wreck's floor walks well at 13
    degrees; how high the car's floor is inside (the platform is 12 over its underside); which way the wall lamps, the
    benches, the signal, the clock and the payphone face (set by their boxes); that the columns, sunk 40 into the
    platform so their heads meet the roof, and the arches under it read as meant; the light_256ceilingmounted001a lamp
    the review named hangs 320 and does not fit under these roofs, so it is left out."""
    b = m.b
    ceil, zr = TRIM + 120, F + 96           # the halls' roof; the stations' floor, the track bed and the bridge's deck
    pz = zr + 64                            # the platforms
    steel = HULL
    m.open(0, -256, 1536, 256)
    m.no_bank(640, 192, 896, 320)           # (no bank up to either mouth: a ramp would make the girder pointless)
    m.no_bank(640, -320, 896, -192)
    for s in (1, -1):                       # s 1: the left station (+v), -1: the right
        def v(a, c):
            return (a * s, c * s) if s > 0 else (c * s, a * s)
        back = 832 if s > 0 else 1088
        m.low(640, v(256, 384)[0], 896, v(256, 384)[1], ceil, floor=zr)
        m.low(448, v(384, back)[0], 1088, v(384, back)[1], ceil, floor=zr)
        if s > 0:
            m.low(512, 832, 640, 960, ceil, floor=pz)
        else:
            m.low(704, -1152, 832, -1088, ceil, floor=zr)
            m.det([(704, -1152, zr, 832, -1136, ceil)], MAT["black"])                     # where the line went on
        m.side(448, v(256, back + 128)[0], 1088, v(256, back + 128)[1])
        m.portal(640, v(318, 320)[0], zr, 896, v(318, 320)[1], ceil)
        m.taken(608, v(176, 256)[0], F, 928, v(176, 256)[1], b.rim)

        def box(u1, v1, z1, u2, v2, z2):
            lo, hi = v(v1, v2)
            return (u1, lo, z1, u2, hi, z2)
        # the platforms either side of the pit, out to the mouth; steps at the mouth's low side climb from the deck. The
        # left station's edges stand back further: the wreck's crushed side and its lean reach toward them.
        e1, e2 = (692, 840) if s > 0 else (700, 836)
        m.det([box(448, 384, zr, e1, back, pz), box(e2, 384, zr, 1088, back, pz), box(640, 352, zr, e1, 384, pz), box(e2, 256, zr, 896, 384, pz)],
              MAT["canal_wall"], top=TILE)
        steps_up(m, 640, e1, 256 * s, zr, pz, s)
        m.det([box(e1 - 4, 352, pz, e1, back, pz + 1), box(e2, 256, pz, e2 + 4, back, pz + 1)], MAT["beam"])          # a dark strip along the edges
        # Half-Life 2's own station kit: its cast iron columns (sunk 40 so their heads meet this lower roof), its arches
        # between them and on to the back wall, a girder across the hall over each pair, a plaster ceiling
        rows = (480, 736) if s > 0 else (480, 736, 992)
        for c in rows:
            for u in (676, 860):
                m.static(P + "props_trainstation/trainstation_column001.mdl", u, c * s, 0, ceil - 257)
        m.det([box(448, c - 8, ceil - 20, 1088, c + 8, ceil - 2) for c in rows], steel)
        for u in (676, 860):
            for c1, c2 in zip(rows, rows[1:]):
                m.static(P + "props_trainstation/column_arch001a.mdl", u, (c1 + c2) // 2 * s, 0, ceil - 109)
            m.static(P + "props_trainstation/ceiling_arch001a.mdl", u, (rows[-1] + back) // 2 * s, 0, ceil - 109)
        m.det([box(448, 384, ceil - 2, 1088, back, ceil), box(640, 256, ceil - 2, 896, 384, ceil)], "plaster/plasterceiling008a_c17")
        # the walls in two tones as the city's station: brick to the shoulder, a rail, plaster over it
        walls = [box(448, 384, pz, 450, back, ceil - 2), box(1086, 384, pz, 1088, back, ceil - 2), box(448, 384, pz, 640, 386, ceil - 2),
                 box(896, 384, pz, 1088, 386, ceil - 2), box(e2, back - 2, pz, 1088, back, ceil - 2), box(448, back - 2, pz, 512 if s > 0 else e1, back, ceil - 2)]
        if s > 0:
            walls += [box(640, back - 2, pz, e1, back, ceil - 2), box(e1, back - 2, pz, e2, back, ceil - 2)]
        else:
            walls += [box(e1, back - 2, zr, 704, back, ceil - 2), box(832, back - 2, zr, e2, back, ceil - 2)]
        m.det([w[:2] + (w[2],) + w[3:5] + (pz + 72,) for w in walls], BRICK)
        m.det([w[:2] + (pz + 76,) + w[3:5] + (ceil - 2,) for w in walls], "plaster/plasterwall041a")
        m.det([(w[0] - (w[3] - w[0] == 2), w[1] - (w[4] - w[1] == 2), pz + 72, w[3] + (w[3] - w[0] == 2), w[4] + (w[4] - w[1] == 2), pz + 76) for w in walls],
              WOODTRIM)
        # the rails in the pit, from the mouth's lip
        for u in (736, 796):
            m.det([box(u, 256, zr, u + 4, 316, zr + 3), box(u, 322, zr, u + 4, 736 if s > 0 else 1136, zr + 3)], MAT["bars"])
        # light: the station's own wall lamps over the platforms' backs, each with a light and a beam down onto the platform
        for (u, c) in ((448, 690), (1088, 500), (1088, 700)) if s > 0 else ((448, 560), (448, 900), (1088, 560), (1088, 900)):
            inward = 0 if u == 448 else 180
            m.static(P + "props_trainstation/light_128wallmounted001a.mdl", u + (11 if u == 448 else -11), c * s, 90, pz + 92)
            m.light(u + (40 if u == 448 else -40), c * s, pz + 130, "255 214 170 45" if s > 0 else "200 214 255 30")
            m.spot(u + (14 if u == 448 else -14), c * s, pz + 150, "255 220 180 60" if s > 0 else "200 214 255 40", inward, 55, 50)
        m.soundscape("d1_trainstation.Turnstyle", 768, 600 * s, pz, radius=520)       # (one the owner's own map uses 14 times)
        m.lane(670, 300 * s, pz)
        m.lane(576, 608 * s, pz)
        m.lane(960, 608 * s, pz)
        m.blocked(e1, v(256, back)[0], e2, v(256, back)[1])

    # --- the left station: the booth, the barred stair, the end of the line ---
    m.det([(504, 826, pz, 520, 838, ceil), (632, 826, pz, 648, 838, ceil), (504, 826, pz + 120, 648, 838, ceil)], steel)      # its frame round the gate
    m.static(P + "props_wasteland/prison_slidingdoor001a.mdl", 576, 842, 90, pz)                  # Nova Prospekt's sliding gate, shut
    clip(m, (520, 846, pz, 632, 848, pz + 120))
    m.steps(856, 520, 632, pz, pz + 48, "v", 1)
    m.det([(512, 916, pz, 640, 960, ceil), (512, 846, pz + 120, 640, 916, ceil), (512, 856, pz, 520, 916, pz + 120), (632, 856, pz, 640, 916, pz + 120)],
          MAT["black"])
    m.target("lc_tram_exit", 576, 800, pz + 8, 90)
    m.blocked(512, 832, 640, 960)
    # the ticket booth: 96 by 112, a barred window with a sill toward the track, an open doorway on its far side
    bz = pz
    m.det(wall(448, 480, 544, 488, bz, ceil) + wall(448, 584, 544, 592, bz, ceil, [(472, 520, bz, bz + 88)]) +
          wall(536, 488, 544, 584, bz, ceil, [(500, 572, bz + 36, bz + 90)]), MM["wood"])
    m.det([(528, 500, bz + 32, 556, 572, bz + 36)], WOODTRIM)                                   # the sill
    for c in (518, 554):
        m.static(P + "props_wasteland/prison_cellwindow002a.mdl", 540, c, 0, bz + 36)
    m.static(P + "props_wasteland/controlroom_chair001a.mdl", 492, 536, 0, bz)
    m.light(492, 536, ceil - 20, "255 190 120 20")
    m.blocked(448, 448, 576, 608)
    m.lane(496, 624, pz)
    # the pit's end: steps up to a concourse joining the platforms, the line's own buffer stop before them, a signal
    # on the far platform, the station clock stopped over the concourse
    steps_up(m, 692, 840, 736, zr, pz, 1)
    m.static(P + "props_trainstation/trackends01.mdl", 766, 722, 0, zr)
    m.static(P + "props_trainstation/light_signal001a.mdl", 904, 690, 270, pz)
    m.static(P + "props_trainstation/trainstation_clock001.mdl", 766, 827, 270, pz + 110)
    m.static(P + "props_trainstation/bench_indoor001a.mdl", 467, 760, 0, pz)
    m.static(P + "props_trainstation/bench_indoor001a.mdl", 1069, 600, 180, pz)
    m.static(P + "props_trainstation/trashcan_indoor001a.mdl", 470, 640, 0, pz)
    m.static(P + "props_trainstation/payphone001a.mdl", 1076, 760, 180, pz)
    m.loose(P + "props_junk/wood_crate001a.mdl", 1040, 430, 20, z=pz)
    m.decal("decals/decal_signroute004a", 450, 620, pz + 112)                    # route signs, a timetable, the city's notices
    m.decal("decals/decal_signroute007a", 1086, 700, pz + 112)
    m.decal("decals/decal_posterbreen", 1086, 470, pz + 100)
    m.grime("poster", 450, 720, pz + 96, 3)
    m.grime("danger", 576, 826, pz + 150, 1)                                      # no entry, over the barred stair
    m.grime("trash", 600, 620, pz + 1, 5)
    m.grime("stain", 1086, 820, pz + 160, 6)
    m.grime("crack", 740, 830, pz + 190, 7)

    # --- the right station: the car whole at the platform, a cache in it; somebody has been living here ---
    m.dynamic(CAR, 767, -740, 0, zr + 52)
    m.static(BOGIE, 767, -524, 90, zr)
    m.static(BOGIE, 767, -956, 270, zr)
    m.target("lc_tram_stash", 767, -640, zr + 80, 90)
    m.loose(P + "props_junk/wood_crate001a.mdl", 780, -620, 10, z=zr + 92)
    m.loose(P + "props_junk/wood_crate002a.mdl", 756, -700, 40, z=zr + 92)
    mattress(m, 520, -760, 90, pz)
    m.static(P + "props_c17/lockers001a.mdl", 1078, -700, 180, pz)
    m.static(P + "props_trainstation/bench_indoor001a.mdl", 467, -470, 0, pz)
    m.static(P + "props_trainstation/bench_indoor001a.mdl", 1069, -470, 180, pz)
    m.static(P + "props_trainstation/trainstation_clock001.mdl", 960, -1085, 90, pz + 110)
    m.decal("decals/decal_signroute006a", 1086, -700, pz + 112)
    m.grime("lambda", 450, -640, pz + 120, 2)                                     # whoever lives here is with the Resistance
    m.grime("graffiti", 1086, -980, pz + 90, 4)
    m.grime("trash", 560, -700, pz + 1, 8)
    m.grime("burn", 560, -880, pz + 1, 9)
    m.grime("stain", 450, -1000, pz + 170, 10)
    m.static(P + "props_c17/oildrum001.mdl", 560, -840, 0, pz)
    fire(m, 560, -840, pz + 46, 18, "255 150 70 60", drop=False)                    # a fire in the drum by the mattress
    m.loose(P + "props_junk/wood_pallet001a.mdl", 600, -450, 30, z=pz)
    m.static(P + "props_junk/cardboard_box001a.mdl", 1050, -900, 15, pz)

    # --- the bridge's remains ---
    deck = [(640, 176, zr - 16, 692, 256, zr), (840, 208, zr - 16, 896, 256, zr),      # (the wreck took the deck between them)
            (640, -256, zr - 16, 896, -192, zr)]
    m.det(deck, MAT["beam"], top=MAT["quay_floor"])
    girder = []
    for u in (648, 872):                    # under the stubs: a web and a bottom flange to each wall
        for (c1, c2) in ((176 if u == 648 else 208, 256), (-256, -192)):
            girder += [(u + 4, c1, zr - 40, u + 12, c2, zr - 16), (u, c1, zr - 48, u + 16, c2, zr - 40)]
    # the whole girder: the beam walk, its top level with both stubs
    girder += [(648, -192, zr - 16, 664, 176, zr), (652, -192, zr - 40, 660, 176, zr - 16), (648, -192, zr - 48, 664, 176, zr - 40)]
    # the other girder: a length out from the left stub, then it sags to the floor; a stump on the right
    girder += [(872, 112, zr - 16, 888, 208, zr), (876, 112, zr - 40, 888 - 4, 208, zr - 16), (872, 112, zr - 48, 888, 208, zr - 40),
               (872, -192, zr - 16, 888, -150, zr), (876, -192, zr - 40, 884, -150, zr - 16)]
    m.det(girder, MAT["bars"])
    m.shapes([para((872, 112, zr - 48), (16, 0, 0), (0, -100, -48), (0, 0, 48), MAT["bars"]),
              para((848, -192, zr - 16), (48, 0, 0), (0, 44, -40), (0, 0, 16), MAT["beam"], top=MAT["quay_floor"]),             # a slab of deck hinging down
              para((736, -192, zr), (4, 0, 0), (0, 6, -50), (0, 0, 3), MAT["bars"]), para((796, -192, zr), (4, 0, 0), (0, 8, -46), (0, 0, 3), MAT["bars"])])
    # corbels under the stubs
    m.shapes([prism([(256 * s, zr - 48), (200 * s, zr - 48), (256 * s, zr - 96)], "x", u, u + 16, MAT["beam"]) for s in (1, -1) for u in (648, 872)])
    # the pier the whole girder rests on, and its twin, broken
    m.det([(632, -24, F, 680, 24, zr - 64), (624, -32, zr - 64, 688, 32, zr - 48)], MAT["beam"])
    m.det([(856, -24, F, 904, 24, F + 24)], MAT["beam"])
    m.shapes([para((856, -24, F + 24), (48, 0, 0), (0, 48, 0), (-10, 6, 18), MAT["beam"]),
              para((930, -70, F), (130, 20, 0), (-12, 84, 0), (0, 0, 14), MAT["beam"], top=MAT["quay_floor"]),                       # deck slabs on the floor
              para((560, 40, F), (20, 96, 0), (-70, 10, 44), (0, 0, 14), MAT["beam"], top=MAT["quay_floor"])])
    m.blocked(608, -64, 704, 64)
    m.blocked(832, -64, 928, 64)

    # --- the car that came off: from the right bank's foot up over the left mouth's lip. Its pose was worked out so that
    # its open front end's lowest corner is on the floor, its underside just touches the lip at v 256 on its low side and
    # its far end reaches v 400 (rolled 13: its +y end up; pitched 5: its +x side down; yaw 1.15 keeps it along v). ---
    tilted(m, "prop_dynamic", WRECK, 766, 85, 463, 1.15, 5, 13)
    tilted(m, "prop_static", BOGIE, 540, -20, F + 46, 20, 0, 90)                    # its front bogie, torn off, on its side
    m.static(P + "props_debris/concrete_debris128pile001b.mdl", 768, 372, 90, zr - 4)    # what it brought down with it, under its far end
    m.rope([(766, 300, ceil - 4), (775, 150, 690)], slack=30)                        # the wire, still on its roof
    m.rope([(766, -300, ceil - 4), (900, -150, F + 40), (930, -96, F + 6)], slack=60)     # and the other end of it, down
    m.spark(930, -96, F + 8)                                                          # still live: it spits now and then
    tilted(m, "prop_static", P + "props_trainstation/traincar_seats001.mdl", 700, -200, F, 205, 0, 0)    # seats spilled from its open end
    tilted(m, "prop_static", P + "props_trainstation/traincar_seats001.mdl", 820, -236, F + 14, 70, 0, 75)
    m.loose(P + "props_c17/suitcase001a.mdl", 960, -180, 35)
    m.soundscape(SCAPES["metal"], 768, 0, F, radius=560)                             # the wreck's metal groaning under its own weight
    canal_grime(m, 32, 560, 4100)
    canal_grime(m, 1000, 1504, 4200)
    m.lane(766, -200, F)
    m.blocked(640, -256, 896, 256)
    m.static(P + "props_debris/concrete_debris128pile001a.mdl", 1010, 130, 60, F - 4)
    m.static(P + "props_debris/broken_pile001a.mdl", 1100, -60, 200, F - 2)
    m.static(P + "props_debris/concrete_floorpile01a.mdl", 600, -150, 20, F - 4)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 880, -110, 110)
    m.loose(P + "props_vehicles/tire001c_car.mdl", 900, 90, 0)
    m.view(360, -100, F, 22, -6, "the car and the bridge")
    m.view(766, -110, F, 90, -14, "into the car's open end")
    m.view(670, 300, pz, 90, 4, "the left station")
    m.view(600, 700, pz, 300, 4, "its platform, looking back")
    m.view(656, 150, zr, 270, 14, "the beam walk")
    m.view(600, -430, pz, 290, 4, "the right station")
    b.notes.append("%s: stations on z %d (platforms z %d) under a roof at z %d; the wreck lies from z %d on the floor up to its lip at z %d; the beam is 16 wide at z %d" % (
        m.tag, zr, pz, ceil, F, zr, zr))


# ---------------------------------------------------------------------------
# tenement
# ---------------------------------------------------------------------------

def wedge(u1, u2, v1, v2, base, fz, mat, top):
    """A floor that tilts across v: from `base` up to fz(v) (its top: material `top`), pushed along u from u1 to u2."""
    f = prism([(v1, base), (v2, base), (v2, fz(v2)), (v1, fz(v1))], "x", u1, u2, mat)
    f[4] = (f[4][0], top)
    return f


def ragged(m, axis, at, t1, t2, a1, a2, zb, zt, mat, seed):
    """A hole torn in a wall rather than cut: teeth of the wall's own stuff left round an opening a1..a2 (along the wall)
    by zb..zt, in a wall from t1 to t2 through it. axis "u": the wall runs along u (pushed along v); "v": it runs along v."""
    w = a2 - a1
    teeth = [[(a1, zb), (a1 + 12, zb + 30), (a1, zb + 52)], [(a1, zb + 52), (a1 + 8, zb + 70), (a1, zt - 20)],
             [(a1, zt), (a1, zt - 20), (a1 + 30, zt)], [(a1 + 30, zt), (a1 + 48, zt - 10), (a1 + w * 2 // 3, zt)], [(a1 + w * 2 // 3, zt), (a2 - 14, zt - 16), (a2, zt)],
             [(a2, zt - 20), (a2 - 12, zb + 70), (a2, zb + 46)], [(a2, zb + 46), (a2 - 8, zb + 20), (a2, zb)]]
    if seed % 2:
        teeth = [[(a1 + a2 - p, z) for p, z in t] for t in teeth]
    m.shapes([prism(t, "x" if axis == "v" else "y", t1, t2, mat) for t in teeth])


def lining(m, u1, v1, u2, v2, fz, ceil, faces, low="plaster/plasterwall047b", skin=None):
    """A room's walls as the city's flats are: a lower tone up to a dado rail 40 over the floor, the rail proud of it.
    The floor tilts across v (fz(v) is its top), so a rail along a wall that runs along v slopes with it. faces:
    {"u1"|"u2"|"v1"|"v2": [(from, to) of each doorway or window to leave open along it]}; a face named in skin is a
    brick wall: plaster is laid over it above the rail as well."""
    lo, rail, over = [], [], []
    for face, holes in faces.items():
        a1, a2 = (u1, u2) if face[0] == "v" else (v1, v2)
        spans, at = [], a1
        for h1, h2 in sorted(holes):
            if h1 > at:
                spans.append((at, h1))
            at = max(at, h2)
        if at < a2:
            spans.append((at, a2))
        for a, b in spans:
            if face[0] == "v":
                w = v1 if face == "v1" else v2 - 2
                z = fz(v1 if face == "v1" else v2)
                ka, kb = (3 if a == u1 else 0), (3 if b == u2 else 0)      # (clear of the walls across the room's corners)
                lo.append((a + ka, w, z, b - kb, w + 2, z + 40))
                rail.append((a + ka, w - (face == "v2"), z + 40, b - kb, w + 2 + (face == "v1"), z + 44))
                if skin and face in skin:
                    over.append((a + ka, w + (face == "v2"), z + 44, b - kb, w + 1 + (face == "v2"), ceil))
            else:
                w = u1 if face == "u1" else u2 - 2
                za, zb = fz(a), fz(b)
                m.shapes([prism([(a, za - 2), (b, zb - 2), (b, zb + 40), (a, za + 40)], "x", w, w + 2, low)])
                d = -1 if face == "u2" else 0
                m.shapes([prism([(a, za + 40), (b, zb + 40), (b, zb + 44), (a, za + 44)], "x", w + d, w + d + 3, WOODTRIM)])
                if skin and face in skin:
                    e = 1 if face == "u2" else 0
                    m.shapes([prism([(a, za + 44), (b, zb + 44), (b, ceil), (a, ceil)], "x", w + e, w + e + 1, PLASTER)])
    if lo:
        m.det(lo, low)
        m.det(rail, WOODTRIM)
    if over:
        m.det(over, PLASTER)


def m_tenement(m, opt):
    """The fallen tenement. A block that stood on the left street has gone into the canal and lies across it from u 320
    to 960: there is no way round, the way on is through its rooms. It came down tilted: every floor in it leans 5
    degrees down toward the left bank (32 over its 352 depth), the furniture has slid to the low side, the tallest wall
    in it leans over the kitchen, a crack runs across the kitchen's ceiling with daylight through it, and the canal's
    water has crept into the low side of the hall. Its body fills the canal from the right wall to v 128; the strip left
    over by the left wall is choked by its own outer wall, fallen in slabs (with an unseen wall for players in it). Its
    face to the canal at each end is a tenement's (a plinth, a string course, windows with sills and lintels, broken),
    and the ways in are holes torn in it, ragged, rubble and rebar at their edges. Ground floor, 112 high: an entry hall,
    a living room, a kitchen, a stair hall open to the leaning roof, a bedroom, a back room, a small room with a bed,
    and behind that a nook that is easy to miss (a crawl hole by the bed, or a hole in the floor above):
    lc_tenement_stash. A stair climbs to the one room left upstairs, a sentry's chair and binoculars at its window over
    the canal the far way (lc_tenement_lookout); out of that window is a drop, never a way in. The rooms are the city's
    flats: plaster in two tones split by a dado rail, wood floors, door casings proud of the walls, a radiator under
    the window, posters and a radio. The roof is sheared slabs lying where they slid. Where the block stood, the left
    wall is bitten out down to the trim, with its cellar walls and floor beams left. It creaks (d1_town.WoodBuilding).
    The way through, door by door (wide, and high over the tilted floor at its lowest): the hole in the entry wall about
    74 by 90; hall to living room 48 by 84; living room to kitchen 48 by 84; kitchen door to the stair hall 48 by 84;
    stair hall to bedroom 48 by 80; the hole in the far wall about 74 by 90. A short cut from the hall to the stair hall
    is a crawl, 48 by 42; the nook's crawl is 40 by 42.
    Named for the game: lc_tenement_stash (an info_target in the nook: a cache), lc_tenement_lookout (an info_target
    at the upstairs window: a sentry's place).
    Left as brushes: the block itself (its walls, floors, stair, the roof's slabs and the outer wall fallen in slabs),
    its trims (plinth, string course, sills, lintels, dado rails, door casings), the cellar walls and joists in the
    bite. Its furniture is the game's own (couches, radiator, stove, sink, a fridge on its back, tables, chairs,
    dresser, bed, shelf, a radio, mattresses turned the right way up), and rubble, rebar and a torn ceiling of the
    game's lie where it struck.
    Unchecked: that the crawl holes pass a crouched player in the game as they do on paper; how the furniture models
    face; that the tilted props (the fridge, a fallen chair, the hanging lamp) lie as worked out; how destroyedceiling01a
    looks round the living room's hole; that nobody can get onto the roof (unseen walls stand over it in case)."""
    b = m.b
    g, zc, up, top = F + 8, F + 120, F + 136, F + 248
    wood, tin = MM["wood"], MM["tin"]

    def fz(v):            # the ground floor's top: 5 degrees down toward +v
        return g + (112 - v) * 32 // 352

    def fu(v):            # ...and upstairs
        return up + (112 - v) * 32 // 352
    m.open(0, -256, 1280, 256)
    m.open(448, 256, 832, 384, floor=TRIM, mat=DIRT)               # where it stood
    m.side(320, -256, 960, 384)
    m.no_bank(320, -264, 960, -248)
    m.blocked(304, -256, 976, 384)
    m.taken(296, -256, F, 984, 256, b.rim)
    # --- the outer walls (brick, 16 thick): the ways in torn through them, two broken windows in the entry wall ---
    ew = wall(320, -256, 336, 128, F, up + 48, [(-224, -168, g + 40, g + 104), (-128, -72, g + 40, g + 104), (0, 96, g, g + 112)])
    ew += [(320, -256, up + 48, 336, -196, up + 96), (320, -92, up + 48, 336, -20, up + 76), (320, 56, up + 48, 336, 128, up + 104)]
    xw = wall(944, -256, 960, 128, F, top, [(0, 96, g, g + 112), (-176, -48, up + 40, up + 88)])
    lw = [(336, 112, F, 944, 128, up), (544, 112, up, 944, 128, top), (752, 112, top, 944, 128, top + 40),
          (336, 112, up, 424, 128, up + 64), (468, 112, up, 544, 128, up + 28)]
    bw = [(336, -256, F, 944, -240, up), (736, -256, up, 944, -240, top)]
    m.det(ew + xw + lw, BRICK)
    m.det(bw, PLASTER)
    for (t1, t2, seed) in ((320, 336, 1), (944, 960, 2)):
        ragged(m, "v", 0, t1, t2, 0, 96, g, g + 112, BRICK, seed)
    m.shapes([prism([(-256, top), (128, top), (128, top + 44)], "x", 944, 960, BRICK), prism([(-240, top), (112, top), (112, top + 40)], "x", 736, 752, PLASTER)])
    # its face to the canal at both ends, as the town's houses: a plinth, a string course at the first floor, the windows
    # with stone sills and lintels (both downstairs broken, one boarded), a sill under the lookout's window
    trim, plinth = "stone/stonewall050f", "concrete/concretewall002c"
    for u0, d in ((320, -1), (960, 1)):
        a, c = (u0 - 8, u0) if d < 0 else (u0, u0 + 8)
        m.det(wall(a, -256, c, 128, F, F + 24, [(0, 96, F, F + 24)]), plinth)
        m.det([(min(u0, u0 + 6 * d), -256, up - 8, max(u0, u0 + 6 * d), 128, up + 4)], trim)
    for (a1, a2) in ((-224, -168), (-128, -72)):
        m.det([(310, a1 - 6, g + 34, 322, a2 + 6, g + 41), (314, a1 - 4, g + 104, 320, a2 + 4, g + 112)], trim)
    m.det([(958, -180, up + 34, 968, -44, up + 41), (960, -178, up + 88, 966, -46, up + 96)], trim)
    m.det([(940, -180, up + 36, 946, -44, up + 41)], WOODTRIM)                        # the lookout's sill inside
    for z, roll in ((g + 60, 8), (g + 86, -6)):
        m.point("prop_dynamic_override", 316, -100, z, {"model": P + "props_debris/wood_board05a.mdl", "angles": "0 %d %d" % (m.fr.yaw(0), 90 + roll), "skin": "0",
                                                         "solid": "6", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                                                         "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)
    # rubble spilled from the torn holes, rebar standing out of their edges
    m.static(P + "props_debris/broken_pile001a.mdl", 292, 48, 90, F - 2)
    m.static(P + "props_debris/plaster_floorpile001a.mdl", 990, 40, 270, F - 2)
    for (u, v, z, model) in ((316, 2, g + 92, "rebar001c_64"), (316, 92, g + 60, "rebar001b_48"), (964, 6, g + 80, "rebar_cluster001a"), (964, 90, g + 96, "rebar001c_64")):
        m.static(P + "props_debris/%s.mdl" % model, u, v, 0, z)
    # --- the walls inside (plaster), their doorways raised to pass over the tilted floor, the tall wall over the kitchen leaning ---
    p1 = wall(336, -64, 944, -48, g, zc, [(400, 448, g, g + 100), (624, 672, g, g + 100), (776, 824, g, g + 100)])
    p2 = wall(528, -240, 544, 112, g, zc, [(-176, -128, g, g + 108), (24, 72, g, g + 48)])
    p3 = wall(736, -240, 752, 112, g, zc, [(-24, 24, g, g + 100)]) + wall(736, -240, 752, 112, up, top, [(64, 112, up, up + 96)])
    p4 = wall(848, -240, 864, -64, g, zc, [(-240, -200, g, g + 72)])
    m.det(p1 + p2 + p3 + p4, PLASTER)
    m.shapes([para((544, -64, zc), (192, 0, 0), (0, 16, 0), (0, -20, top - 20 - zc), PLASTER),
              para((544, -84, top - 20), (88, 0, 0), (0, 16, 0), (0, -4, 20), PLASTER)])
    cas = []
    for (a, c) in ((400, 448), (624, 672), (776, 824)):             # hole a..c in the wall v -64..-48
        cas += [(a - 4, -67, g, a + 1, -45, g + 99), (c - 1, -67, g, c + 4, -45, g + 99), (a - 4, -67, g + 99, c + 4, -45, g + 104)]
    cas += [(525, -180, g, 547, -175, zc), (525, -129, g, 547, -124, zc),
            (733, -28, g, 755, -23, g + 99), (733, 23, g, 755, 28, g + 99), (733, -28, g + 99, 755, 28, g + 104)]
    m.det(cas, WOODTRIM)
    # --- floors, all tilted the same way; the kitchen's ceiling cracked across ---
    m.shapes([wedge(336, 544, -240, 112, F, fz, MAT["canal_wall"], wood), wedge(544, 736, -64, 112, F, fz, MAT["canal_wall"], wood),
              wedge(736, 944, -240, 112, F, fz, MAT["canal_wall"], wood), wedge(544, 736, -240, -64, F, fz, MAT["canal_wall"], TILE)])
    m.det(floor_with_holes(336, -240, 544, 112, zc, up, [(416, -200, 496, -120)]), MAT["ceiling"], top=MAT["quay_floor"])
    m.det([(544, -240, zc, 736, -158, up), (544, -142, zc, 736, -48, up)], MAT["ceiling"], top=MAT["quay_floor"])
    m.shapes([prism([(-158, zc), (-150, zc), (-158, up)], "x", 544, 640, MAT["ceiling"]), prism([(-142, zc), (-142, up), (-150, up)], "x", 640, 736, MAT["ceiling"])])
    m.shapes([wedge(736, 880, -240, 112, zc, fu, MAT["ceiling"], wood), wedge(880, 928, -240, -232, zc, fu, MAT["ceiling"], wood),
              wedge(880, 928, -184, 112, zc, fu, MAT["ceiling"], wood), wedge(928, 944, -240, 112, zc, fu, MAT["ceiling"], wood)])
    m.steps(544, 64, 112, g, up, "u", 1)
    # the rooms lined as the city's flats are (brick walls plastered over above the rail)
    rooms = [(336, -240, 528, -64, zc, {"u1": [(-224, -168), (-128, -72)], "u2": [(-180, -124)], "v1": [], "v2": [(396, 452)]}, ("u1",)),
             (336, -48, 528, 112, zc, {"u1": [(0, 96)], "u2": [(24, 72)], "v1": [(396, 452)], "v2": []}, ("u1", "v2")),
             (544, -240, 736, -64, zc, {"u1": [(-180, -124)], "u2": [], "v1": [], "v2": [(620, 676)]}, ()),
             (544, -48, 736, 112, zc, {"u1": [(24, 72)], "u2": [(-28, 28)], "v1": [(620, 676)]}, ()),
             (752, -240, 848, -64, zc, {"u1": [], "u2": [(-240, -200)], "v1": [], "v2": [(772, 828)]}, ()),
             (864, -240, 944, -64, zc, {"u1": [(-240, -200)], "u2": [], "v1": [], "v2": []}, ("u2",)),
             (752, -48, 944, 112, zc, {"u1": [(-28, 28)], "u2": [(0, 96)], "v1": [(772, 828)], "v2": []}, ("u2", "v2"))]
    for (u1, v1, u2, v2, ceil, faces, skin) in rooms:
        lining(m, u1, v1, u2, v2, fz, ceil, faces, low=TILE if (u1, v1) == (544, -240) else "plaster/plasterwall047b", skin=skin)
    lining(m, 752, -240, 944, 112, fu, top, {"u1": [(64, 112)], "u2": [(-176, -48)], "v1": [], "v2": []}, skin=("u2", "v2"))
    # --- the roof, where it slid (sheared slabs) ---
    m.shapes([para((728, -256, top), (233, 0, 0), (0, 392, 48), (0, 0, 12), tin),
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
    m.det([(u, 226, TRIM - 12, u + 10, 330, TRIM + 2) for u in (500, 590, 700, 780)], WOODTRIM)
    # --- what is in the rooms, slid to the low side ---
    put(m, P + "props_c17/furniturecouch001a.mdl", 432, -100, 0, z=fz(-100))                                    # living room
    put(m, P + "props_c17/furnitureradiator001a.mdl", 342, -100, 0, z=fz(-75) + 2)
    put(m, P + "props_c17/furnitureradiator001a.mdl", 342, -196, 0, z=fz(-171) + 2)
    put(m, P + "props_debris/plaster_floorpile001a.mdl", 460, -170, 20, z=fz(-140))
    m.static(P + "props_debris/destroyedceiling01a.mdl", 456, -160, 0, zc - 33)                                  # torn round the hole
    put(m, P + "props_c17/furnituredresser001a.mdl", 500, -210, 270, z=fz(-180))
    put(m, P + "props_lab/citizenradio.mdl", 500, -210, 270, z=fz(-180) + 82)
    put(m, P + "props_c17/furniturestove001a.mdl", 712, -218, 90, z=fz(-192))                                  # kitchen
    put(m, P + "props_interiors/sinkkitchen01a.mdl", 664, -224, 90, z=fz(-210))
    tilted(m, "prop_static", P + "props_interiors/refrigerator01a.mdl", 590, -140, fz(-120) + 16, 90, 90, 0)   # the fridge, fallen on its back
    put(m, P + "props_c17/furnituretable002a.mdl", 660, -100, 0, z=fz(-80))
    tilted(m, "prop_physics", P + "props_c17/furniturechair001a.mdl", 700, -110, fz(-100) + 10, 30, 0, -90)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 384, 40, 40, z=fz(40))                                     # the hall
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 470, 60, 100, z=fz(60))
    m.loose(P + "props_junk/wood_crate001a.mdl", 600, 20, 15, z=fz(20))                                         # the stair hall
    mattress(m, 860, 80, 0, fz(80))                                                                           # the back room
    m.loose(P + "props_c17/furniturechair001a.mdl", 782, 90, 200, z=fz(90))
    put(m, P + "props_c17/furniturebed001a.mdl", 796, -96, 0, z=fz(-74))                                        # the small room
    put(m, P + "props_interiors/furniture_shelf01a.mdl", 760, -200, 0, z=fz(-176))
    m.loose(P + "props_junk/wood_crate001a.mdl", 914, -92, 0, z=fz(-72))                                       # the nook
    m.loose(P + "props_junk/wood_crate002a.mdl", 900, -140, 90, z=fz(-120))
    put(m, P + "props_c17/furnituretable001a.mdl", 900, 30, 0, z=fu(30))                                       # upstairs
    put(m, P + "props_c17/oildrum001.mdl", 782, 24, 0, z=fu(24))
    mattress(m, 800, -170, 90, fu(-150))
    put(m, P + "props_c17/furniturechair001a.mdl", 920, -112, 0, z=fu(-112))                                    # the lookout's chair at the window
    m.static(P + "props_combine/combine_binocular01.mdl", 924, -60, 90, fu(-50))
    put(m, P + "props_c17/furniturecouch002a.mdl", 150, -56, 140)                                              # thrown out into the canal
    put(m, P + "props_debris/concrete_chunk01a.mdl", 250, -40, 70)
    put(m, P + "props_debris/broken_pile001a.mdl", 1050, 120, 100)
    m.static(P + "props_debris/concrete_debris128pile001a.mdl", 200, -186, 0, F - 4)       # rubble where it struck, clear of the way in
    m.static(P + "props_debris/concrete_debris128pile001a.mdl", 200, 150, 0, F - 4)
    m.static(P + "props_debris/concrete_debris128pile001b.mdl", 1150, 174, 200, F - 4)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 1090, -90, 10)
    m.water(336, 64, 528, 112, F + 2, g + 3)                                               # the canal's water, come in at the low side
    m.target("lc_tenement_stash", 904, -150, fz(-150) + 8, 90)
    m.target("lc_tenement_lookout", 920, -112, fu(-112) + 8, 0)
    # --- light: grey from the holes in the roof and the crack, one lamp left burning in the kitchen (hanging on its cable,
    # askew), a candle in the small room, the radio's corner lit low ---
    m.light(456, -160, up + 10, "190 205 230 45")
    m.spot(456, -160, up + 40, "190 205 230 70", 0, 88, 50)
    m.light(640, 20, top - 30, "190 205 230 55")
    m.spot(600, -150, up + 60, "200 212 235 80", 90, 85, 30)                                 # daylight down through the kitchen's crack
    m.rope([(640, -100, zc - 1), (646, -100, zc - 34)], slack=4)
    tilted(m, "prop_static", P + "props_c17/light_industrialbell01_on.mdl", 646, -100, zc - 34, 0, 12, 0)
    m.light(648, -100, zc - 62, "255 200 140 34")
    m.light(432, 32, zc - 24, "200 210 230 10")
    m.lamp(432, 32, zc, "200 210 230 8")
    from map_mods_b import candle
    candle(m, 760, -200, fz(-176) + 88)
    m.light(848, 32, g + 40, "255 170 100 12")
    m.light(904, -120, g + 30, "255 160 90 6")
    m.light(900, -100, top - 30, "190 205 230 30")
    m.spot(900, -112, top - 10, "190 205 230 50", 0, 70, 40)
    m.soundscape(SCAPES["house"], 640, -64, g, radius=420)
    # --- grime: cracks where it struck, stains where the water got in, posters and the lambda of whoever sheltered here ---
    for kind, u, v, z, seed in (("crack", 336 + 2, -150, g + 70, 1), ("crack", 528, -30, g + 80, 2), ("crack", 736 - 2, -150, g + 90, 3), ("poster", 544 + 2, 0, g + 60, 4),
                                ("poster", 752 + 2, -150, g + 56, 5), ("stain", 640, -240 + 2, g + 70, 6), ("lambda", 864 + 2, -150, g + 50, 7), ("stain", 336 + 2, 30, g + 50, 8),
                                ("trash", 440, 0, fz(0), 9), ("debris", 400, -130, fz(-130), 10), ("stain", 319, -60, F + 60, 11), ("crack", 319, -200, up + 20, 12),
                                ("stain", 961, -120, F + 90, 13), ("graffiti", 961, -200, F + 40, 14)):
        m.grime(kind, u, v, z, seed)
    canal_grime(m, 32, 300, 4300)
    canal_grime(m, 980, 1250, 4400)
    # --- the way through, for those who cannot crawl ---
    for (u, v) in ((360, 48), (424, 16), (424, -56), (440, -130), (536, -152), (600, -150), (648, -100), (648, -56), (656, 0), (744, 0), (800, 16), (880, 40),
                   (952, 48), (800, -56), (800, -100), (560, 88)):
        m.lane(u, v, fz(v))
    for (u, v, z) in ((290, 48, F), (1000, 48, F), (724, 88, fu(88)), (800, 80, fu(80)), (860, -60, fu(-60))):
        m.lane(u, v, z)
    m.view(150, 60, F, 0, 0, "what is left of it")
    m.view(350, 48, fz(48), 320, 4, "the hall: the hole to the living room, the crawl")
    m.view(716, -84, fz(-84), 215, 8, "the kitchen")
    m.view(570, 20, fz(20), 20, -14, "the stair hall")
    m.view(790, 60, fu(60), 310, 6, "upstairs: the window")
    m.view(800, -140, fz(-140), 305, 16, "the small room: the nook's hole by the bed")
    m.view(1180, 30, F, 180, -6, "looking back at it")
    b.notes.append("%s: the block lies across u 320 to 960; ground floor z %d to %d, upstairs z %d to %d (tilted 5 degrees); every door on the way through is at least 48 wide and 80 high" % (
        m.tag, g, fz(-240), up, fu(-240)))


# ---------------------------------------------------------------------------
# quay
# ---------------------------------------------------------------------------

def m_quay(m, opt):
    """The quay: a way up to the streets. Stairs 64 wide climb along the left wall from the canal floor (u 64) to a
    landing at the trim's height (u 448 to 512), with the city's own stair rail on the canal's side; their open side is
    made solid from the floor to a parapet over the flight, so from the canal it reads as one stair built against the
    wall. The landing opens onto a quay recessed into the left wall, 640 by 256 and open to the sky: a low wall along
    its edge, two of the city's street lamps at the edge with their arms over the quay, mooring cleats with a boat roped
    below, tyres hung down the quay wall as fenders on short ropes, an iron ladder from the canal floor up through a gap
    in the edge wall (a second way up), three posts before the street doorway, a skip, a bench, a payphone, crates. At
    the back a street doorway 128 wide and 128 high stands in a concrete frame, a route sign over it, the city's notices
    beside it and a Combine camera on the wall watching who comes down; it is closed 64 in by a cap of the world in its
    own visgroup ("the quay's street end (delete to join a street)"). From the quay a footbridge on two trestles,
    railed both sides, crosses to a barred door of Nova Prospekt's in the right wall: behind it a short passage to the
    city's locked store for the quay (the Combine's supply crates on shelves, a lamp left on), seen through the bars.
    Sounds: the quiet courtyard up on the quay, the watery hallway down in the canal (both the owner's map's own).
    Named for the game: lc_quay_street (an info_target in the street doorway, facing the quay: where people arrive
    from the street), lc_quay_far_door (an info_target on the bridge before the barred door).
    Left as brushes: the stairs and their solid side, the landing, the quay's low wall, the doorway's frame, the
    store's walls, the footbridge's deck, girders and trestles (a structure, no model fits 512 by 64).
    Unchecked: that handrail04_doublerise rises toward its own +y end (if the stair rail falls the wrong way, turn
    both by 180) and where its posts meet the steps (they were made for steps of 8 and 12, these are 16 and 24); how
    the boat, bench, payphone and camera models face; that the hung tyres (turned up on edge) lie flat to the wall;
    the doorway's frame stands 24 above the walls' tops when the rim is at its lowest (784), which may look odd from
    the street."""
    b = m.b
    steel = HULL
    m.open(0, -256, 1024, 256)
    m.open(320, 256, 960, 512, floor=TRIM, mat=MAT["quay_floor"])
    m.low(576, 512, 704, 640, TRIM + 128, floor=TRIM, mat=MAT["quay_floor"])
    m.low(832, -320, 896, -256, TRIM + 112, floor=TRIM)
    m.low(768, -448, 960, -320, TRIM + 128, floor=TRIM)
    m.side(320, 256, 960, 640)
    m.side(768, -448, 960, -256)
    m.world((576, 576, TRIM, 704, 640, TRIM + 128), MAT["black"], vis="%s: the quay's street end (delete to join a street)" % b.vis)
    b.plan.keep_out.append(m.fr.rect(512, 640, 768, 704))
    m.blocked(576, 512, 704, 640)
    m.target("lc_quay_street", 640, 544, TRIM + 8, 270)
    # --- the stairs along the wall, their landing, the rail ---
    m.no_bank(0, 248, 512, 264)
    run = m.steps(64, 192, 256, F, TRIM, "u", 1)
    m.det([(448, 192, F, 512, 256, TRIM)], MAT["canal_wall"], top=MAT["quay_floor"])
    m.stair_side(64, run, 184, 192, F, TRIM, 1)                  # its open side solid, from the floor to a parapet over the flight
    m.det([(448, 184, F, 513, 192, TRIM + 32)], MAT["beam"])
    # the stair rail: two of the city's rails for a flight (each rises 128 over 192, as these stairs do), then the
    # landing's rail round its open sides. (Their origins are at their middles: set by hand, not stood.)
    for uc, zc in ((160, F + 88), (352, F + 216)):
        tilted(m, "prop_static", P + "props_c17/handrail04_doublerise.mdl", uc, 194, zc, 270)
    m.static(P + "props_c17/handrail04_medium.mdl", 480, 194, 270, TRIM)
    m.static(P + "props_c17/handrail04_medium.mdl", 510, 224, 0, TRIM)
    m.blocked(0, 128, 512, 256)
    m.taken(0, 176, F, 520, 256, TRIM + 64)
    for (u, z) in ((36, F), (160, F + 64), (304, F + 160), (480, TRIM)):
        m.lane(u, 224, z)
    # --- the quay: a low wall along its edge (a gap at the landing, a gap at the footbridge), its coping ---
    edge = [(320, 448), (512, 672), (704, 832), (896, 960)]
    m.det([(a, 256, TRIM, c, 268, TRIM + 40) for a, c in edge], MAT["canal_wall"])
    m.det([(a - (0 if a == 320 else 2), 254, TRIM + 40, c + (0 if c == 960 else 2), 270, TRIM + 44) for a, c in edge], MAT["beam"])
    # the street doorway's frame, standing proud of the back wall
    m.det([(556, 496, TRIM, 576, 512, TRIM + 128), (704, 496, TRIM, 724, 512, TRIM + 128), (548, 492, TRIM + 127, 732, 512, TRIM + 152)], MAT["beam"])
    # two of the city's street lamps, their arms over the quay (the arm reaches along the model's left)
    for u in (392, 816):
        m.static(P + "props_c17/lamppost03a_on.mdl", u, 286, 0, TRIM)
        m.light(u, 386, TRIM + 400, "255 214 170 300")
        m.blocked(u - 24, 262, u + 24, 310)
    # posts before the street doorway, cleats for mooring on the edge
    for u in (560, 640, 720):
        m.static(P + "props_trainstation/trainstation_post001.mdl", u, 440, 0, TRIM)
    for u in (548, 760):
        m.static(P + "props_docks/dock01_cleat01a.mdl", u, 290, 0, TRIM)
    put(m, P + "props_junk/trashdumpster02.mdl", 424, 440, 0, z=TRIM)
    put(m, P + "props_trainstation/benchoutdoor01a.mdl", 800, 494, 270, z=TRIM)
    put(m, P + "props_trainstation/payphone001a.mdl", 752, 500, 270, z=TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 936, 300, 0, z=TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 936, 332, 0, z=TRIM)
    m.loose(P + "props_junk/wood_crate001a.mdl", 928, 380, 20, z=TRIM)
    m.loose(P + "props_junk/wood_crate002a.mdl", 600, 300, 90, z=TRIM)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 668, 300, 30, z=TRIM)
    put(m, P + "props_canal/boat001a.mdl", 690, 70, 12)
    m.rope([(760, 290, TRIM + 14), (752, 250, TRIM + 44), (720, 96, F + 40)], slack=70)
    m.blocked(580, 0, 800, 128)
    m.lane(480, 330, TRIM)
    m.lane(640, 380, TRIM)
    m.lane(640, 490, TRIM)
    m.lane(864, 330, TRIM)
    # --- the footbridge: a plank deck on two girders, two trestles, a rail each side ---
    m.det([(832, -256, TRIM - 6, 896, 256, TRIM)], WOODTRIM, top=MM["wood"])
    m.det([(836, -256, TRIM - 24, 842, 256, TRIM - 6), (886, -256, TRIM - 24, 892, 256, TRIM - 6)], MAT["bars"])
    br = []
    for u in (835, 893):                    # its rails: the city's own, four lengths a side
        for c in (-192, -64, 64, 192):
            m.static(P + "props_c17/handrail04_long.mdl", u, c, 0, TRIM)
    for v in (-100, 96):
        br += [(836, v, F, 842, v + 6, TRIM - 24), (886, v, F, 892, v + 6, TRIM - 24), (837, v + 1, F + 120, 891, v + 5, F + 124), (832, v - 2, TRIM - 30, 896, v + 8, TRIM - 24)]
        m.shapes([prism([(842, F + 4), (886, F + 116), (886, F + 120), (842, F + 8)], "y", v + 2, v + 4, MAT["bars"]),
                  prism([(886, F + 124), (842, F + 226), (842, F + 230), (886, F + 128)], "y", v + 2, v + 4, MAT["bars"])])
        m.blocked(816, v - 24, 912, v + 32)
    m.det(br, MAT["bars"])
    m.taken(808, 216, F, 920, 256, TRIM + 48)
    m.taken(808, -256, F, 920, -216, b.rim)
    for v in (200, 0, -200):
        m.lane(864, v, TRIM)
    # --- the barred door across: a cell door of Nova Prospekt's, shut in a steel frame fitted to it, black behind, a
    # caged lamp on the wall over it ---
    m.static(P + "props_wasteland/prison_celldoor001a.mdl", 864, -260, 90, TRIM)
    clip(m, (832, -266, TRIM, 896, -264, TRIM + 112))
    m.det([(824, -264, TRIM - 1, 839, -250, TRIM + 103), (889, -264, TRIM - 1, 904, -250, TRIM + 103), (824, -264, TRIM + 103, 904, -250, TRIM + 120)], steel)
    # behind it, the city's store for the quay, locked up: the Combine's crates of supplies on shelves, a lamp left on
    m.portal(832, -302, TRIM, 896, -300, TRIM + 112)
    m.det([(768, -448, TRIM, 960, -446, TRIM + 128), (768, -448, TRIM, 770, -320, TRIM + 128), (958, -448, TRIM, 960, -320, TRIM + 128),
           (770, -322, TRIM, 832, -320, TRIM + 128), (896, -322, TRIM, 958, -320, TRIM + 128)], "concrete/concretewall008a")
    for (u, v, yaw) in ((800, -420, 0), (928, -420, 0)):
        m.dynamic(P + "props_wasteland/kitchen_shelf001a.mdl", u, v, yaw, TRIM)
    for (u, v, z, yaw) in ((790, -360, TRIM, 15), (790, -360, TRIM + 24, 40), (930, -370, TRIM, 80), (864, -420, TRIM, 0)):
        m.static(P + "items/item_item_crate.mdl", u, v, yaw, z)
    m.static(P + "props_c17/light_cagelight02_on.mdl", 864, -446, 90, TRIM + 96)
    m.light(864, -420, TRIM + 100, "200 220 255 30")
    m.grime("number", 959, -380, TRIM + 70, 3)
    m.grime("stain", 769, -400, TRIM + 90, 4)
    m.blocked(768, -448, 960, -320)
    m.static(P + "props_c17/light_cagelight02_on.mdl", 864, -256, 90, TRIM + 130)
    m.light(864, -236, TRIM + 128, "255 120 90 25")
    m.blocked(832, -320, 896, -256)
    m.target("lc_quay_far_door", 864, -230, TRIM + 8, 270)
    # a working quay: tyres hung down its wall as fenders, an iron ladder up from the canal, the street's sign and the
    # city's notices by the doorway, a camera watching who comes down
    m.no_bank(640, 248, 704, 264)
    m.ladder(688, 254, F, TRIM, 270)
    for u in (560, 760, 912):
        tilted(m, "prop_dynamic_override", P + "props_vehicles/tire001c_car.mdl", u, 250, F + 210, 90, 0, 90, {"solid": "6"})
        m.rope([(u, 262, TRIM + 40), (u, 252, F + 224)], slack=6)
    m.taken(540, 236, F + 180, 932, 256, TRIM)
    m.decal("decals/decal_signroute001a", 640, 492, TRIM + 166)
    m.decal("decals/decal_posterbreen", 760, 511, TRIM + 80)
    m.grime("poster", 520, 511, TRIM + 70, 2)
    m.static(P + "props_combine/combinecamera001.mdl", 780, 495, 270, TRIM + 190)
    for kind, u, v, z, seed in (("puddle", 500, 360, TRIM + 1, 1), ("puddle", 880, 420, TRIM + 1, 2), ("stain", 424, 380, TRIM + 1, 3), ("trash", 820, 470, TRIM + 1, 4),
                                ("trash", 430, 500, TRIM + 1, 5), ("stain", 960 - 1, 400, TRIM + 60, 6), ("stain", 200, 184, F + 120, 7), ("graffiti", 300, 184, F + 60, 8)):
        m.grime(kind, u, v, z, seed)
    canal_grime(m, 32, 1000, 4500)
    m.soundscape(SCAPES["courtyard"], 640, 380, TRIM, radius=520)
    m.soundscape(SCAPES["watery"], 512, -100, F, radius=400)
    m.view(20, 150, F, 20, -8, "the stairs")
    m.view(480, 224, TRIM, 40, 6, "from the landing")
    m.view(930, 450, TRIM, 195, 2, "the quay, the street doorway")
    m.view(864, 200, TRIM, 270, 6, "the footbridge")
    m.view(560, -110, F, 50, -22, "from the canal")
    b.notes.append("%s: the street end is at (%d %d), floor z %d, 128 wide and 128 high: bring a street to it, then delete its cap" % ((m.tag,) + m.fr.at(640, 640, TRIM)))


# ---------------------------------------------------------------------------
# collapse
# ---------------------------------------------------------------------------

def m_collapse(m, opt):
    """The cave-in. The left street's retaining wall and a length of roadway have come down across the canal (the wall
    is bitten out to a ledge of earth at z 528, open to the sky). From the bite to v 32 two great slabs lean on each
    other like a tent, its ridge at z 640; from v 32 a wedge of roadway slopes down to a standing piece of the wall at
    v -160. Each slab is plainly a piece of the owner's street: cobbles on top (stonefloor006d_c17) with a sett gutter,
    a kerb and a strip of pavement at its far end, raw concrete underneath with rebar standing out of every broken edge,
    the broken ends rough; cracks and grit painted on them. Every face is steeper than a player can walk. Two ways
    through: the squeeze: 96 wide between that standing piece and the right wall (v -256 to -160), open to the sky, no
    bank; the crawl: a hole 40 wide (a beam props it) and 44 high at the foot of the near slab (v 72 to 112), torn at its
    corner, into the hollow under the tent (192 by 96 of flat floor, room to stand, earth sloping up behind), and another
    out through the far slab (v 40 to 88): the two holes do not line up, so nobody sees or shoots straight through. The
    hollow is a hide (lc_collapse_hide): a slot 16 wide by the ridge lets one shaft of daylight in, dust hangs in it.
    Each side also has a perch: the earth bank leads up to the end of the bite's ledge beside the slabs. What came down
    with the street lies about: broken slabs of road, a bench, a cone, a car, rubble (all real models); the street's
    cables still hang strung from the bite to the ridge. Sounds: metal and concrete settling (coast.util_metalstress),
    the hollow a cave's quiet (d1_town.CaveTunnel), both the owner's map's own.
    Named for the game: lc_collapse_hide (an info_target in the hollow under the slabs).
    Left as brushes: the great slabs, the wedge and the standing piece of wall (the fallen street itself, too big for
    any model), the kerb, gutter and pavement on them, the prop beam.
    Unchecked: how far each rebar model sticks out of its slab (set by their boxes); that players cannot scramble up
    the slabs (they lean at 63 and 51 degrees; the game's limit is about 45); that the leaning hole reads as a way in;
    how the car and the bench lie; the func_dustmotes keys (from Half-Life 2's own entity, not read from the owner's
    map); how the cobbles' texture lies on the slopes."""
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
    # each slab is a piece of the owner's own street: cobbles on top with a sett gutter, a kerb and a strip of pavement
    # at its far end; raw concrete underneath; broken ends rough
    raw, rough, road, walk, kerb, sett = "concrete/concretewall008a", "concrete/concretewall059e", MM["road"], MM["walk"], "concrete/concretefloor039b", "stone/stonefloor006f_c17"

    def slab(profile, v1, v2, top_face, under_face):
        f = prism(profile, "y", v1, v2, raw, rough)
        f[2 + top_face] = (f[2 + top_face][0], road)
        f[2 + under_face] = (f[2 + under_face][0], raw)
        return f
    far_up = [(482, F + 44), (458, F + 44), (384, F + 192), (396, F + 216)]          # (it stops against the near slab's underside)
    m.shapes([slab(near_low, 32, 72, 3, 1), slab(near_low, 120, 256, 3, 1), slab(near_up, 32, 150, 3, 1), slab(near_up, 166, 256, 3, 1),
              slab(far_low, 32, 40, 3, 1), slab(far_low, 88, 257, 3, 1), slab(far_up, 32, 257, 3, 1),
              # ...and on across the bite's ledge
              prism([(328, F + 128), (352, F + 128), (408, F + 240), (384, F + 240)], "y", 256, 384, raw, rough),
              prism([(440, F + 128), (416, F + 128), (396, F + 168), (380, F + 136)], "y", 257, 384, raw, rough),
              # the earth that came with the wall, in place of the bank
              prism([(256, F + 128), (128, F), (256, F)], "x", 256, 512, DIRT),
              # the wedge of roadway from the tent down to the standing piece, its skin of cobbles, and the piece itself
              prism([(-144, F), (32, F), (32, F + 216)], "x", 288, 480, raw, rough),
              para((276, -144, F), (216, 0, 0), (0, 176, 216), (0, 0, 10), raw, top=road),
              para((280, -160, F), (208, 0, 0), (0, 24, 150), (0, 16, 0), MAT["canal_wall"]),
              # the gutter, the kerb and the pavement on both slabs (lying on their faces)
              para((264, 184, F), (0, 16, 0), (120, 0, 240), (-2, 0, 1), raw, top=sett), para((504, 184, F), (0, 16, 0), (-120, 0, 240), (2, 0, 1), raw, top=sett),
              para((264, 200, F), (0, 55, 0), (120, 0, 240), (-6, 0, 3), kerb, top=walk), para((504, 200, F), (0, 55, 0), (-120, 0, 240), (6, 0, 3), kerb, top=walk),
              # the crawl hole torn rather than cut, a beam propping it
              prism([(72, F + 44), (84, F + 44), (72, F + 28)], "x", 284, 308, rough)])
    m.det([(290, 110, F, 298, 118, F + 46)], WOODTRIM)
    # broken slabs of road lying about, both sides (two flat, one leaning on the wedge, one stood on end)
    D = P + "props_debris/"
    m.static(D + "concrete_section128floor001a.mdl", 176, 72, 12, F)
    m.static(D + "concrete_section128floor001b.mdl", 622, 132, 350, F)
    tilted(m, "prop_static", D + "concrete_section64floor001a.mdl", 236, -112, F + 8, 350, 0, 12)
    tilted(m, "prop_static", D + "concrete_section64floor001c.mdl", 540, -100, F + 4, 180, -62, 0)
    # cracks and grit on the slabs (painted, on their faces), the street's things that came down with it
    for kind, u, v, z, seed in (("crack", 324, 150, F + 120, 1), ("crack", 444, 110, F + 120, 2), ("debris", 344, 210, F + 160, 3), ("crack", 330, -60, F + 140, 4),
                                ("stain", 456, 230, F + 96, 5), ("debris", 200, -20, F + 1, 6), ("debris", 600, -140, F + 1, 7), ("stain", 320, 383, F + 200, 8)):
        m.grime(kind, u, v, z, seed)
    m.static(P + "props_trainstation/benchoutdoor01a.mdl", 104, -40, 40, F)
    m.loose(P + "props_junk/trafficcone001a.mdl", 660, 190, 0)
    m.rope([(300, 383, b.rim - 30), (380, 300, F + 236)], slack=60)                     # cables torn out of the street, still strung
    m.rope([(460, 383, b.rim - 44), (400, 290, F + 236)], slack=90)
    # rebar (the game's own): out of the ridge, out of the wedge's sides, out of the bite's lip, out of the standing
    # piece's top. Each half in its slab: their origins are at their middles.
    for (u, v, z, model, yaw, pitch, roll) in ((384, 70, F + 250, "rebar_cluster002a", 0, 0, 0), (386, 150, F + 252, "rebar_cluster002b", 90, 0, 0),
                                                (382, 226, F + 250, "rebar_cluster001a", 200, 0, 0), (296, -20, F + 120, "rebar002d_96", 0, -50, 0),
                                                (474, -60, F + 80, "rebar004d_96", 0, 55, 0), (282, 250, F + 128, "rebar001c_64", 0, 8, 0),
                                                (488, 244, F + 128, "rebar002c_64", 0, -10, 0), (330, -128, F + 150, "rebar_cluster001b", 90, 0, 0),
                                                (440, -126, F + 148, "rebar003c_64", 0, 14, 0)):
        tilted(m, "prop_static", D + model + ".mdl", u, v, z, yaw, pitch, roll)
    clip(m, (380, -160, F + 192, 388, 384, b.sky))
    # --- the hollow: somebody's hide ---
    m.target("lc_collapse_hide", 384, 64, F + 8, 90)
    mattress(m, 420, 104, 0)
    m.loose(P + "props_junk/wood_crate001a.mdl", 340, 52, 20)
    put(m, P + "props_c17/oildrum001.mdl", 440, 56, 0)
    m.light(384, 84, F + 150, "200 210 230 14")
    m.spot(384, 158, F + 186, "210 220 240 60", 0, 80, 24)                              # one shaft of daylight in through the slot by the ridge
    m.ent("func_dustmotes", {"SpawnRate": "30", "Color": "255 255 255", "SizeMin": "10", "SizeMax": "20", "Alpha": "255", "MinSpeed": "1", "MaxSpeed": "2",
                             "LifetimeMin": "3", "LifetimeMax": "5", "DistMax": "1024", "Frozen": "0", "StartDisabled": "0"},
          [(336, 48, F + 8, 432, 200, F + 150)], MAT["trigger"])
    m.soundscape(SCAPES["metal"], 384, 0, F, radius=420)
    m.soundscape(SCAPES["cave"], 384, 100, F, radius=120)
    canal_grime(m, 16, 220, 4600)
    canal_grime(m, 580, 760, 4700)
    # --- outside ---
    put(m, P + "props_vehicles/car004a_physics.mdl", 628, -36, 168)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 226, 150, 30)
    put(m, P + "props_debris/broken_pile001a.mdl", 216, -40, 80)
    put(m, P + "props_debris/concrete_chunk02a.mdl", 90, 150, 140)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 720, 104, 100)
    put(m, P + "props_debris/broken_pile001a.mdl", 560, -200, 10)
    m.loose(P + "props_debris/concrete_chunk02a.mdl", 250, -210, 60)
    m.loose(P + "props_vehicles/tire001c_car.mdl", 700, 60, 0)
    put(m, P + "props_wasteland/rockgranite02a.mdl", 300, 330, 0, z=F + 128)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 470, 320, 60, z=F + 128)
    m.blocked(192, -160, 576, 384)
    m.blocked(520, -100, 740, 30)
    for u in (176, 300, 384, 470, 592):
        m.lane(u, -208, F)
    m.view(120, -120, F, 345, 0, "the squeeze")
    m.view(150, 110, F, 0, 2, "the crawl")
    m.view(320, 56, F, 50, -12, "in the hollow")
    m.view(290, 290, F + 128, 300, 14, "from the perch")
    m.view(700, 20, F, 180, -8, "looking back")
    b.notes.append("%s: the squeeze is 96 wide along the right wall; the crawl's two holes are 48 wide and 44 high; the tent's ridge is at z %d" % (m.tag, F + 240))


# ---------------------------------------------------------------------------
# scrapyard
# ---------------------------------------------------------------------------

def cargo(m, kind, u, v, z, yaw, skin=0):
    """One of the game's shipping containers standing on z, its middle at (u, v): 133 wide, 388 long (along its model's
    +y, which yaw turns), 130 high. kind "" is shut (solid); "b" is open at its +y end and hollow; "c" is the same with
    one door swung out (24 beyond its side). skin 0 to 2: its colour (not "c")."""
    m.prop("prop_static", P + "props_wasteland/cargo_container01%s.mdl" % kind, u, v, yaw, z,
           {"solid": "6", "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "skin": str(skin)})
    if z <= F:
        h = 200 if yaw % 180 else 70
        w = 70 if yaw % 180 else 200
        m.blocked(u - h, v - w, u + h, v + w)


def m_scrapyard(m, opt):
    """The scrapyard. The canal widens 384 on both sides into a yard of dirt where the Combine dump what they clear from
    the streets: the game's own shipping containers (133 by 388 by 130; the open ones hollow, to walk into), some of them
    dumped off the square, wrecked cars stacked two high, tyres, and a tower crane on a plinth in the far right corner
    whose jib reaches over the yard, Half-Life 2's crane magnet hanging from it on its cable over the open ground (its
    hook lies in the dirt). Oil stains, puddles and trash on the ground. It is lit as a yard is: a floodlight on the
    crane's cab and a lamp cluster on a utility pole at three corners, each throwing a beam down into it. In the right
    corner by the entry the foreman's office, a wooden hut with a window over the yard: a desk, a radio, a filing
    cabinet, a calendar on the wall, a bare bulb. The yard groans (coast.util_metalstress).
    On the ground: a container lies across the canal at each end of the yard (the near one open toward the left bank,
    the far one shut): go round their ends. Between them one lies along the middle, open toward the entry, a door swung
    out; left and right lanes run past more containers, open ones to hide in, and round the stacked wrecks. Nothing
    gives a straight view from one end to the other.
    Over the top: a ramp of planks at each end (130 up over 256) to the roof of the container lying across; from the
    entry one plank bridges on to a covered porch on the middle stack and one to the left stack, where a ramp (130 up
    over 192) climbs to the roof of the second level; a ramp from the far container's roof climbs there too. From that
    roof a plank crosses to a ledge on the middle stack, and a ladder climbs the last 130 to the top of the third
    container (lc_scrap_perch, z 790: level with the canal walls' tops, the whole yard under it), with sheets of metal
    to crouch behind. The second container of the middle stack is open toward the exit: a nest reached from its ledge.
    Named for the game: lc_scrap_perch (an info_target on the highest container: a sniper's or a lookout's place).
    Left as brushes: the plank ramps and bridges and their cleats (walkways; a board model is 128 long at most), the
    crane's plinth, lattice tower, cab and jib (no crane model fits under the sky), the office's walls and roof.
    Unchecked: which end of cargo_container01b and 01c is open (taken to be the +y end, where the model is 3 longer)
    and that their insides walk; the ladder on a container's end; that two planks 22 wide side by side walk as one
    ramp; how the wrecks, the magnet, the floodlights and the desk face; where the lamp cluster sits on its pole (set
    by their boxes). The magnet only hangs: making it lift (a phys_magnet) is left for later."""
    b = m.b
    steel = HULL
    wood = MM["wood"]
    L1Z, L2Z, L3Z = F + 130, F + 260, F + 390
    m.open(0, -256, 1536, 256)
    m.open(192, 256, 1344, 640, mat=DIRT)                # (a yard of dirt, oil-black where the loaders stand)
    m.open(192, -640, 1344, -256, mat=DIRT)
    m.side(192, -640, 1344, 640)
    # --- the containers: across the canal at each end, the middle stack of three, the left stack, the right lane ---
    cargo(m, "b", 448, 0, F, 0, 1)                  # across, entry side, open toward the left bank
    cargo(m, "", 1152, 0, F, 180, 2)                # across, exit side, shut
    cargo(m, "c", 768, 0, F, 90, 0)                 # the middle stack: ground, open toward the entry
    cargo(m, "b", 896, 0, L1Z, 270, 2)              # ...second, open toward the exit: the nest
    cargo(m, "", 768, 0, L2Z, 90, 0)                # ...third: the perch (it overhangs the porch)
    cargo(m, "b", 640, 320, F, 180, 0)              # the left stack's way in, open toward the canal
    cargo(m, "c", 960, 320, F, 270, 0)
    cargo(m, "", 1024, 320, L1Z, 90, 1)
    cargo(m, "b", 512, -384, F, 270, 1)             # the right lane
    cargo(m, "b", 1024, -384, F, 97, 0)             # (dumped, not stacked by a surveyor: turned off the square)
    cargo(m, "", 512, -384, L1Z, 103, 2)
    # --- planks: ramps (sheared, never steeper than 130 up over 192) and bridges ---
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
    m.det([(132, -170, F, 138, -118, F + 5), (1462, 118, F, 1468, 170, F + 5), (780, 290, L1Z, 786, 350, L1Z + 89), (1146, 190, L1Z, 1206, 196, L1Z + 79)], WOODTRIM)   # cleats and props
    # --- the perch: a ladder up the third container's end from the ledge, sheets of metal to crouch behind ---
    m.ladder(960, 0, L2Z, L3Z - 2, 0)
    for (u, v, yaw) in ((600, -40, 0), (600, 30, 0), (700, -62, 90), (860, 60, 270)):
        m.dynamic(P + "props_debris/metal_panel02a.mdl", u, v, yaw, L3Z)
    m.target("lc_scrap_perch", 768, 0, L3Z + 8, 180)
    # --- wrecked cars stacked two high, as the Combine's loaders leave them ---
    for (u, v, yaw, low, high, turn) in ((784, -272, 90, "car001b_hatchback", "car002b_physics", 84), (912, 470, 0, "car001a_hatchback", "car003b_physics", 10),
                                         (1272, 348, 90, "car001b_hatchback", "car005b_physics", 6), (262, -52, 0, "car001a_hatchback", None, 0),
                                         (1000, -172, 0, "car001b_hatchback", "car004b_physics", 172)):
        m.static(P + "props_vehicles/%s.mdl" % low, u, v, yaw)
        if high:
            m.static(P + "props_vehicles/%s.mdl" % high, u, v, yaw + turn, F + (53 if low == "car001a_hatchback" else 43))     # (sunk 4 into the roof under it)
        m.blocked(u - 90, v - 90, u + 90, v + 90)
    # --- the crane: a plinth, a lattice tower, a cab, a jib of three chords over the yard, the hook ---
    tu, tv, top = 1288, -520, F + 600
    m.det([(1232, -576, F, 1344, -464, F + 136)], MAT["beam"], top=MAT["quay_floor"])
    legs = [(tu + du, tv + dv, F + 136, tu + du + 8, tv + dv + 8, top) for du in (-32, 24) for dv in (-32, 24)]
    for z in range(F + 240, top, 116):
        legs += [(tu - 31, tv - 30, z, tu + 31, tv - 26, z + 4), (tu - 31, tv + 26, z + 1, tu + 31, tv + 30, z + 5), (tu - 30, tv - 31, z + 2, tu - 26, tv + 31, z + 6),
                 (tu + 26, tv - 31, z + 3, tu + 30, tv + 31, z + 7)]
    m.det(legs + [(tu - 36, tv - 36, top, tu + 36, tv + 36, top + 6), (tu - 4, tv - 4, top + 6, tu + 4, tv + 4, top + 60)], MAT["bars"])
    m.det([(tu - 29, tv - 29, top - 66, tu + 29, tv + 29, top - 15)], steel)                                     # the cab, under the top ties
    m.det([(tu - 30, tv - 8, top - 46, tu - 29, tv + 25, top - 22), (tu - 8, tv + 29, top - 46, tu + 25, tv + 30, top - 22)], "glass/glasswindow007a")
    m.det([(tu + 30, tv - 40, top - 60, tu + 54, tv - 4, top - 20)], MAT["beam"])                              # the counterweight
    jz = top - 56
    jib = [para((tu - 20, tv + 28, jz), (-580, 580, 0), (6, 6, 0), (0, 0, 8), MAT["bars"]), para((tu - 34, tv + 14, jz + 1), (-580, 580, 0), (6, 6, 0), (0, 0, 8), MAT["bars"]),
           para((tu - 27, tv + 21, jz + 48), (-560, 560, -40), (6, 6, 0), (0, 0, 8), MAT["bars"])]
    for k in range(0, 9):                                                                                   # ties between the chords
        o = (tu - 34 - 70 * k, tv + 14 + 70 * k, jz)
        jib.append(para((o[0], o[1], jz + 2), (20, -20, 0), (4, 4, 0), (0, 0, 5), MAT["bars"]))
        if k:
            jib.append(para((o[0] + 9, o[1] - 5, jz + 8), (4, 4, 0), (-2, 2, 0), (0, 0, 40 - (40 * k) // 14), MAT["bars"]))
    m.shapes(jib)
    # Half-Life 2's crane magnet hanging on its cable from the jib's middle over open ground, the hook left lying
    m.dynamic(P + "props_wasteland/cranemagnet01a.mdl", 911, -150, 45, jz - 278)
    m.rope([(911, -150, jz - 1), (911, -150, jz - 121)], slack=4, width=3)
    m.static(P + "props_c17/pulleyhook01.mdl", 1180, -380, 30, F)
    # floodlights: a lamp on the crane's cab and a cluster on a pole at each corner of the yard, beams down into it
    m.static(P + "props_wasteland/light_spotlight01_lamp.mdl", tu - 36, tv + 36, 135, top - 68)
    m.spot(tu - 44, tv + 44, top - 62, "255 225 180 400", 135, pitch=42, cone=50)
    for (u, v, way, face) in ((260, 590, -1, 311), (1276, 590, -1, 229), (560, -610, 1, 71)):
        m.static(P + "props_c17/utilitypole01a.mdl", u, v, 90 if way < 0 else 270, F)
        m.static(P + "props_trainstation/lighttowercluster01.mdl", u, v + 24 * way, 90, F + 400)
        m.spot(u, v + 50 * way, F + 400, "255 230 190 350", face, pitch=50, cone=60)
        m.blocked(u - 48, v - 32, u + 48, v + 32)
    m.blocked(1216, -592, 1344, -448)
    # --- wrecks, tyres, drums ---
    put(m, P + "props_vehicles/car004a_physics.mdl", 940, 190, 185)
    put(m, P + "props_vehicles/car002a_physics.mdl", 1130, -250, 15)
    put(m, P + "props_vehicles/car005a_physics.mdl", 262, 120, 80)
    put(m, P + "props_vehicles/car002a_physics.mdl", 440, 400, 110)
    put(m, P + "props_vehicles/car004a_physics.mdl", 1290, -150, 270)
    put(m, P + "props_junk/trashdumpster02.mdl", 720, -560, 0)
    for (u, v, n) in ((480, 300, 3), (640, -250, 3), (1060, 440, 4), (1250, 190, 3), (540, -110, 2)):
        for k in range(n):
            m.loose(P + "props_vehicles/tire001c_car.mdl", u + 22 * (k % 3), v + 30 * (k // 3), 90 * (k % 2))
    put(m, P + "props_c17/oildrum001.mdl", 730, 100, 0)
    put(m, P + "props_c17/oildrum001.mdl", 1030, -90, 0)
    put(m, P + "props_c17/oildrum001.mdl", 612, 20, 0, z=L1Z)
    m.loose(P + "props_junk/wood_crate001a.mdl", 700, 20, 10, z=F + 12)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 900, 0, 0, z=L1Z + 12)
    m.loose(P + "props_junk/wood_crate001a.mdl", 760, -30, 30, z=L1Z + 12)
    m.blocked(840, 140, 1040, 240)
    m.blocked(1040, -300, 1220, -200)
    m.blocked(200, 30, 320, 210)
    for (u, v, z) in ((330, 0, F), (448, 0, F + 4), (544, 0, F), (640, 0, F + 4), (820, 0, F + 4), (896, -36, F + 4), (896, -100, F), (1024, -20, F),
                      (1260, 0, F), (448, 230, F), (544, 96, F), (640, 300, F + 4), (736, 432, F), (448, -256, F), (760, -384, F), (1024, -384, F + 4), (1260, -384, F)):
        m.lane(u, v, z)
    # --- the yard office: a hut on the right, a window over the yard, a desk, a radio, the foreman's calendar, a bare bulb ---
    ou1, ov1, ou2, ov2, oh = 216, -632, 376, -496, 112
    m.det(wall(ou1, ov1, ou2, ov1 + 8, F, F + oh) + wall(ou1, ov2 - 8, ou2, ov2, F, F + oh, [(320, 366, F, F + 96)]) +
          wall(ou1, ov1 + 8, ou1 + 8, ov2 - 8, F, F + oh) + wall(ou2 - 8, ov1 + 8, ou2, ov2 - 8, F, F + oh, [(-600, -528, F + 44, F + 92)]), "wood/woodwall006a")
    m.det([(ou1 - 12, ov1 - 12, F + oh, ou2 + 12, ov2 + 24, F + oh + 6)], MM["tin"])
    m.det([(ou2 - 1, -604, F + 40, ou2 + 6, -524, F + 45)], WOODTRIM)
    m.det([(318, ov2 - 9, F, 322, ov2 + 1, F + 95), (364, ov2 - 9, F, 368, ov2 + 1, F + 95), (318, ov2 - 9, F + 95, 368, ov2 + 1, F + 99)], WOODTRIM)
    m.no_bank(176, -656, 400, -624)                                   # (no bank where the office stands)
    m.no_bank(176, -640, 208, -384)
    m.dynamic(P + "props_wasteland/controlroom_desk001b.mdl", 352, -566, 0, F)
    m.loose(P + "props_c17/furniturechair001a.mdl", 320, -566, 270)
    m.static(P + "props_lab/citizenradio.mdl", 352, -540, 180, F + 34)
    m.dynamic(P + "props_wasteland/controlroom_filecabinet002a.mdl", 236, -612, 0, F)
    m.static(P + "props_interiors/lightbulb01a.mdl", 296, -564, 0, F + oh - 49)
    m.light(296, -564, F + oh - 56, "255 210 150 30")
    m.grime("poster", ou1 + 8, -560, F + 60, 5)
    m.blocked(ou1 - 16, ov1, ou2 + 16, ov2 + 16)
    m.lane(290, -470, F)
    m.lane(296, -540, F)
    m.view(280, -420, F, 272, 4, "the yard office")
    # --- grime: oil where the loaders stood, puddles, trash, numbers on the containers ---
    for kind, u, v, z, seed in (("stain", 700, 420, F + 1, 1), ("stain", 900, -500, F + 1, 2), ("puddle", 400, 520, F + 1, 3), ("puddle", 1200, -460, F + 1, 4),
                                ("trash", 330, 300, F + 1, 5), ("trash", 820, -320, F + 1, 6), ("stain", 1150, 560, F + 1, 7), ("burn", 600, -560, F + 1, 8)):
        m.grime(kind, u, v, z, seed)
    canal_grime(m, 16, 180, 4800)
    canal_grime(m, 1360, 1520, 4900)
    m.soundscape(SCAPES["metal"], 768, 0, F, radius=900)
    m.view(70, -40, F, 355, -4, "the ramp, the way through")
    m.view(448, 0, L1Z, 0, -4, "from the first roof: the stack, the porch")
    m.view(610, 0, F + 4, 0, 2, "inside the middle container")
    m.view(1100, 330, L2Z, 235, 10, "the left stack's roof: the plank to the ledge, the ladder")
    m.view(840, 0, L3Z, 180, 22, "from the perch, the way people come")
    m.view(1460, -60, F, 170, -10, "from the far end")
    b.notes.append("%s: the yard is %d by %d; container roofs at z %d, %d and %d (the perch); the crane's tower tops out at z %d, its hook hangs to z %d" % (
        m.tag, 1152, 1280, L1Z, L2Z, L3Z, top + 60, jz - 144))


# ---------------------------------------------------------------------------
# boathouse
# ---------------------------------------------------------------------------

def m_boathouse(m, opt):
    """The smugglers' boathouse: a boat shed built into the left wall, its floor 64 over the canal's. A slipway of
    concrete with two launching rails climbs from the canal floor through a cut in the bank to a roll-up door of the
    owner's corrugated steel (metaldoor032c) 256 wide, a slot of daylight under it (lc_boathouse_door: a func_door that
    lifts). The door is worked by a button inside, to the right of it, and by one outside on the canal wall, on the far
    side of a drain pipe so that nobody coming along the canal sees it (stand on the bank to reach it). Inside, under a
    pitched tin roof on four timber trusses with a ridge beam: a boat on two crates on the rails' line, the canal's own
    winch behind it with its cable on the bow, a chain hoist (the game's pulley hook on its cable) hanging from the ridge
    over the slip, a workbench of two tables with an outboard engine on it and the tools on a board over it, shelves,
    fuel drums, bare bulbs on their cables under the tie beams. In the floor at the back a steel hatch
    (lc_boathouse_hatch: a func_door that slides aside, worked by the button over the workbench) covers steps down to a
    cellar 192 square of damp brick where the contraband is kept: the Combine's own ammunition crates and a supply crate,
    shelves, a radio (lc_boathouse_cellar). Sounds: the watery hallway in the shed, a dripping tunnel in the cellar.
    Named for the game: lc_boathouse_door (func_door: Open, Close, Toggle), lc_boathouse_hatch (func_door, the same),
    lc_boathouse_button_in, lc_boathouse_button_out, lc_boathouse_hatch_button (func_buttons that already work in the
    map), lc_boathouse_cellar (an info_target in the cellar: the cache).
    Left as brushes: the roll-up door and the hatch (plates the game moves; no roll-up door or floor hatch exists as a
    model), the door's guides and roller housing, the slipway and its rails, the roof, its trusses and the tool board.
    Unchecked: which way the winch, the engine and the ammunition crates face; how the corrugated door's ribs lie (the
    owner's own way of laying it is the default one); the buttons' model is Episode Two's (the shared button helper's
    choice); that the outside button can be pressed past the pipe; that the hatch, sliding from under someone, lets them
    down the steps cleanly; that the tools hung on the board (rolled 90) lie flat to it."""
    b = m.b
    fz, ceil, cz = F + 64, F + 224, F - 64
    roof = F + 352                                               # (the shed's own roof: high enough for a pitched roof under it)
    steel, tin, wood = HULL, MM["tin"], MM["wood"]
    m.open(0, -256, 1024, 256)
    m.low(448, 256, 704, 320, ceil, floor=fz)                    # the doorway
    m.low(320, 320, 832, 704, roof, floor=fz)                    # the shed
    m.low(640, 512, 704, 704, roof, floor=cz)                    # the stair's well in its floor
    m.low(576, 704, 768, 896, cz + 112, floor=cz)                # the cellar
    m.side(320, 256, 832, 896)
    m.portal(448, 283, fz, 704, 285, ceil)
    m.portal(576, 708, cz, 768, 710, cz + 112)
    # --- the slipway through the bank, its rails on into the shed ---
    m.no_bank(448, 248, 704, 264)
    m.shapes([prism([(256, fz), (64, F), (256, F)], "x", 448, 704, MAT["beam"]),
              para((520, 64, F), (8, 0, 0), (0, 192, 64), (0, 0, 5), MAT["bars"]), para((624, 64, F), (8, 0, 0), (0, 192, 64), (0, 0, 5), MAT["bars"]),
              para((449, 100, F + 12), (254, 0, 0), (0, 12, 4), (0, 0, 3), MAT["canal_wall"]), para((449, 190, F + 42), (254, 0, 0), (0, 12, 4), (0, 0, 3), MAT["canal_wall"])])
    m.det([(520, 256, fz, 528, 640, fz + 5), (624, 256, fz, 632, 640, fz + 5)], MAT["bars"])
    m.blocked(448, 64, 704, 320)
    m.lane(576, 40, F)
    m.lane(576, 160, F + 32)
    m.lane(576, 300, fz)
    # --- the roll-up door, its guides and roller housing, the two buttons ---
    m.door("lc_boathouse_door", [(448, 280, fz + 6, 704, 288, ceil)], "metal/metaldoor032c", "-90 0 0", speed=36, lip=14)    # (a slot of light under it)
    m.det([(441, 246, fz, 449, 256, ceil + 8), (703, 246, fz, 711, 256, ceil + 8), (436, 236, ceil + 8, 716, 256, ceil + 40)], steel)
    m.det([(448, 276, fz, 452, 292, ceil), (700, 276, fz, 704, 292, ceil)], steel)
    m.taken(424, 200, F, 728, 256, ceil + 48)
    m.button("lc_boathouse_button_in", 740, 320, fz + 40, 90, [("lc_boathouse_door", "Toggle", "", 0)])
    m.static(P + "props_pipes/gutter_256_001a.mdl", 731, 248, 90, b.rim - 257)       # the drain pipe down the wall, from the top
    m.button("lc_boathouse_button_out", 748, 256, F + 160, 270, [("lc_boathouse_door", "Toggle", "", 0)])
    m.taken(712, 220, F, 768, 256, b.rim)
    # --- the hatch over the cellar steps, its frame, the steps, the cellar ---
    m.door("lc_boathouse_hatch", [(640, 512, fz, 704, 704, fz + 5)], steel, "0 %d 0" % m.fr.yaw(180), speed=30, lip=0)
    m.det([(636, 512, fz, 640, 704, fz + 2), (704, 512, fz, 708, 704, fz + 2), (636, 508, fz, 708, 512, fz + 2)], MAT["bars"])
    m.steps(704, 640, 704, cz, fz, "v", -1)
    m.blocked(576, 448, 768, 704)
    m.button("lc_boathouse_hatch_button", 320, 560, fz + 52, 0, [("lc_boathouse_hatch", "Toggle", "", 0)])
    m.target("lc_boathouse_cellar", 672, 800, cz + 8, 270)
    m.light(672, 800, cz + 56, "255 190 120 22")
    m.static(P + "props_interiors/lightbulb01a.mdl", 672, 800, 0, cz + 112 - 49)
    m.det([(576, 704, cz, 578, 896, cz + 112), (766, 704, cz, 768, 896, cz + 112), (578, 894, cz, 766, 896, cz + 112), (578, 704, cz, 640, 706, cz + 112),
           (704, 704, cz, 766, 706, cz + 112)], "brick/brickwall037a")                                    # damp brick
    for kind, u, v, z, seed in (("stain", 579, 820, cz + 70, 1), ("stain", 765, 760, cz + 60, 2), ("crack", 700, 893, cz + 80, 3), ("puddle", 660, 760, cz + 1, 4)):
        m.grime(kind, u, v, z, seed)
    m.dynamic(P + "items/ammocrate_smg1.mdl", 720, 740, 180, cz)
    m.dynamic(P + "items/ammocrate_ar2.mdl", 610, 860, 0, cz)
    m.static(P + "items/item_item_crate.mdl", 700, 860, 20, cz)
    m.soundscape(SCAPES["tunnel"], 672, 800, cz, radius=200)
    for u in (624, 720):                                                                                    # the cellar's racking
        m.static(P + "props_c17/shelfunit01a.mdl", u, 884, 0, cz)
    m.loose(P + "props_junk/wood_crate001a.mdl", 610, 740, 10, z=cz)
    m.loose(P + "props_junk/wood_crate002a.mdl", 736, 840, 90, z=cz)
    put(m, P + "props_c17/canister01a.mdl", 750, 780, 30, z=cz)
    put(m, P + "props_lab/citizenradio.mdl", 736, 840, 270, z=cz + 33)
    m.lane(672, 800, cz)
    m.lane(672, 490, fz)
    # --- the shed: the boat on trestles, the winch and its cable, the bench, shelves, drums ---
    for v in (452, 588):                                                                                    # the boat's two crates, on the rails' line
        m.dynamic(P + "props_junk/wood_crate001a.mdl", 576, v, 0, fz)
    put(m, P + "props_canal/boat001a.mdl", 576, 520, 90, z=fz + 40)
    m.static(P + "props_canal/winch02.mdl", 576, 680, 270, fz)
    m.rope([(576, 676, fz + 36), (576, 632, fz + 62)], slack=6)
    ez, rz = F + 232, F + 332                                                                               # the eaves, the ridge
    m.shapes([prism([(320, ez), (576, rz), (576, rz + 8), (320, ez + 8)], "y", 320, 704, tin), prism([(832, ez), (576, rz), (576, rz + 8), (832, ez + 8)], "y", 320, 704, tin)])
    trusses = []
    for v in (368, 464, 560, 656):
        trusses += [(321, v - 4, ez - 8, 831, v + 4, ez), (572, v - 4, ez, 580, v + 4, rz - 8)]
        m.shapes([prism([(400, ez), (408, ez), (572, ez + 72), (572, ez + 80)], "y", v - 3, v + 3, WOODTRIM),
                  prism([(752, ez), (744, ez), (580, ez + 72), (580, ez + 80)], "y", v - 3, v + 3, WOODTRIM)])
    m.det(trusses + [(572, 321, rz - 8, 580, 703, rz)], WOODTRIM)                                            # tie beams, king posts, the ridge beam
    tilted(m, "prop_static", P + "props_c17/pulleyhook01.mdl", 576, 400, F + 160, 0)                        # the chain hoist over the slip
    m.rope([(576, 400, F + 300), (576, 400, rz - 9)], slack=2, width=3)
    for v in (564, 636):                                                                                    # the workbench: two tables end to end
        m.dynamic(P + "props_c17/furnituretable002a.mdl", 350, v, 0, fz)
    m.static(P + "props_c17/trappropeller_engine.mdl", 350, 640, 0, fz + 37)                                 # an outboard on the bench
    put(m, P + "props_junk/metalbucket01a.mdl", 352, 580, 0, z=fz + 37)
    m.det([(320, 540, fz + 56, 322, 660, fz + 120)], "wood/woodwall006a")                                    # the tool board over it
    for (v, model) in ((566, "tools_wrench01a"), (600, "tools_pliers01a"), (632, "tools_wrench01a")):
        m.point("prop_dynamic_override", 323, v, fz + 90, {"model": P + "props_c17/%s.mdl" % model, "angles": "0 %d 90" % m.fr.yaw(0), "solid": "0",
                                                           "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                                                           "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)
    put(m, P + "props_c17/shelfunit01a.mdl", 440, 690, 0, z=fz)
    for (u, v) in ((790, 380), (800, 420), (766, 356)):
        put(m, P + "props_c17/oildrum001.mdl", u, v, 0, z=fz)
    put(m, P + "props_c17/oildrum001_explosive.mdl", 796, 470, 0, z=fz)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 780, 640, 20, z=fz)
    m.loose(P + "props_vehicles/tire001c_car.mdl", 350, 370, 0, z=fz)
    for (u, v) in ((440, 464), (720, 560), (440, 656)):                                                     # bare bulbs on their cables under the tie beams
        m.static(P + "props_interiors/lightbulb01a.mdl", u, v, 0, ez - 8 - 49)
        m.light(u, v, ez - 70, "255 205 150 40")
    m.light(576, 300, fz + 10, "200 212 235 18")                                                             # day, in under the door
    for kind, u, v, z, seed in (("puddle", 560, 136, F + 24, 1), ("stain", 600, 200, F + 45, 2), ("stain", 321, 420, fz + 60, 3), ("stain", 831, 500, fz + 90, 4),
                                ("trash", 760, 600, fz + 1, 5), ("number", 576, 703, fz + 140, 6), ("drain", 731, 257, F + 140, 7)):
        m.grime(kind, u, v, z, seed)
    m.soundscape(SCAPES["watery"], 576, 500, fz, radius=420)
    canal_grime(m, 16, 420, 5000)
    canal_grime(m, 740, 1010, 5100)
    m.blocked(528, 400, 624, 704)
    m.lane(400, 600, fz)
    m.lane(760, 560, fz)
    m.lane(420, 380, fz)
    m.view(576, -80, F, 90, -6, "the slipway and the door")
    m.view(860, 110, F, 129, -12, "the button behind the pipe")
    m.view(770, 350, fz, 150, 6, "inside: the boat")
    m.view(400, 650, fz, 320, 8, "from the bench: the hatch, the door")
    m.view(600, 730, cz, 50, 2, "the cellar")
    b.notes.append("%s: the shed's floor is z %d, the cellar's z %d; the door and the hatch both start shut" % (m.tag, fz, cz))


# ---------------------------------------------------------------------------
# arcade
# ---------------------------------------------------------------------------

def m_arcade(m, opt):
    """The market arcade: an old covered market built over the canal on three stone arches (u 640 to 896). Below, the
    canal passes between two piers 64 thick with cutwaters: a middle arch 128 wide over the flat of the floor, a side
    arch over each bank; a keystone of lighter dressed stone at the crowns, a trim along the deck's edge, a caged lamp
    on each pier lighting the middle arch, water stains down the piers. Above, at the trim's height, a covered walk 256
    wide crosses from wall to wall under a pitched tin roof on columns: open bays with a parapet 36 high look up and
    down the canal, three stalls (the game's kitchen counters) stand down its middle, each under an awning with a few
    goods on it (melons, a pot, a crate), lamps hang under tie beams across the walk, and barred shop fronts (the city's
    own bars) close its two ends: through the bars a shallow shop each side (plaster in two tones, a counter, shelves
    with a jar or a jug left, a dead lamp). It is reached by a stair along each wall, railed, its open side solid from
    the floor: on the left bank from the entry side (u 256 up to 640), on the right bank from the exit side (u 1280 down
    to 896), so each end of the canal has its own way up. Two levels to fight over: whoever holds the walk sees both
    approaches, whoever is below has the piers. It creaks above (d1_town.WoodBuilding) and drips below
    (prison.watery_hallway).
    Named for the game: lc_arcade_upper (an info_target in the middle of the walk).
    Left as brushes: the piers, arches, keystones, deck, parapets, columns, brackets, tie beams and roof (the building),
    the shop fronts' frames and the shops' walls.
    Unchecked: the look of stone/stonewall040f on the piers and arches; how the bin, the pushcart, the counters and
    the awnings face; which end of handrail04_doublerise is its high end (see wall_stair)."""
    b = m.b
    deck, roof = TRIM, TRIM + 120
    stone, tin, wood = STONE, MM["tin"], MM["wood"]
    m.open(0, -256, 1536, 256)
    # --- below: the deck on its piers and arches ---
    m.det([(640, -256, deck - 32, 896, 256, deck)], stone, top=TILE)
    m.det([(640, 64, F, 896, 128, deck - 32), (640, -128, F, 896, -64, deck - 32)], stone)
    cut = []
    for (v1, v2) in ((64, 128), (-128, -64)):
        mid = (v1 + v2) // 2
        cut += [vprism([(640, v1), (640, v2), (600, mid)], F, F + 176, stone), vprism([(896, v1), (896, v2), (936, mid)], F, F + 176, stone)]
        m.blocked(576, v1 - 32, 960, v2 + 32)
    m.shapes(cut)
    haunch = []
    for (a, c) in ((-256, -128), (-64, 64), (128, 256)):
        haunch += arch(a, c, deck - 32, 64, 640, 896, stone)
    m.shapes(haunch)
    m.det([(632, -256, deck - 12, 640, 256, deck + 4), (896, -256, deck - 12, 904, 256, deck + 4)], "stone/stonewall050f")    # the cornice along each face
    # dressed stone at the arches: a keystone at each crown on both faces, and a lamp under the middle arch on each pier
    m.det([(u, c - 12, deck - 60, u + 6, c + 12, deck - 30) for (u, c) in ((634, 0), (634, -192), (896, 0), (896, 192))], "stone/stonewall050f")    # (not over the stairs)
    for v, out in ((63, 270), (-63, 90)):
        m.static(P + "props_c17/light_cagelight02_on.mdl", 768, v, out, F + 196)
        m.light(768, v - 14 if out == 270 else v + 14, F + 202, "255 200 140 40")
    for kind, u, v, z, seed in (("stain", 639, 96, F + 120, 1), ("stain", 639, -96, F + 100, 2), ("stain", 897, 96, F + 110, 3), ("stain", 897, -96, F + 130, 4),
                                ("graffiti", 768, 63, F + 60, 5), ("drain", 639, 0, deck - 40, 6)):
        m.grime(kind, u, v, z, seed)
    m.taken(600, 192, F, 936, 256, b.rim)
    m.taken(600, -256, F, 936, -192, b.rim)
    # --- the stairs: left bank from the entry side, right bank from the exit side ---
    m.no_bank(192, 248, 640, 264)
    m.no_bank(896, -264, 1344, -248)
    wall_stair(m, 256, 192, 256, 1, 192)
    wall_stair(m, 1280, -256, -192, -1, -192)
    m.blocked(192, 128, 640, 256)
    m.blocked(896, -256, 1344, -128)
    m.taken(192, 176, F, 640, 256, deck + 64)
    m.taken(896, -256, F, 1344, -176, deck + 64)
    for k, u in enumerate((230, 352, 496, 630)):
        m.lane(u, 224, (F, F + 64, F + 160, deck)[k])
        m.lane(1536 - u, -224, (F, F + 64, F + 160, deck)[k])
    # --- above: the covered walk. Columns and a parapet along each face (a gap where each stair comes up) ---
    cols, brackets = [], []
    for (ua, ub, gap) in ((640, 652, (192, 256)), (884, 896, (-256, -192))):
        for c in (-256, -152, -56, 40, 136, 240):
            cols.append((ua, max(c, -255), deck, ub, min(c + 16, 255), roof - 16))
            for way in (-1, 1):
                edge = c if way < 0 else c + 16
                if -256 < edge + way * 24 < 256:
                    brackets.append(prism([(edge, roof - 16), (edge, roof - 44), (edge + way * 28, roof - 16)], "x", ua + 2, ub - 2, WOODTRIM))
        para_boxes = [x for x in wall(ua + 2, -254, ub - 2, 254, deck, deck + 36, [(max(gap[0], -254), min(gap[1], 254), deck, deck + 36)]) if x[4] - x[1] > 0]
        m.det(para_boxes, stone)
        m.det([(ua - 2 if ua == 640 else ua + 1, x[1], deck + 36, ub - 1 if ua == 640 else ub + 2, x[4], deck + 40) for x in para_boxes], "stone/stonewall050f")
        m.det([(ua, -256, roof - 16, ub, 256, roof)], WOODTRIM)
    m.det(cols, stone)
    m.shapes(brackets)
    m.det([(628, -256, roof, 908, 256, roof + 8)], WOODTRIM)
    m.shapes([prism([(620, roof + 8), (916, roof + 8), (768, roof + 64)], "y", -256, 256, tin)])
    # barred shop fronts closing the walk's two ends: the city's storefront bars in a wooden frame, dark behind
    for s in (1, -1):
        v1, v2 = (248, 256) if s > 0 else (-256, -248)
        m.det([(664, v1, deck, 681, v2, deck + 105), (743, v1, deck, 793, v2, deck + 105), (855, v1, deck, 872, v2, deck + 105), (664, v1, deck + 105, 872, v2, deck + 113)],
              WOODTRIM)
        # behind the bars, a shallow shop: a counter, shelves with a few things left, a dead lamp
        sv1, sv2 = (256, 320) if s > 0 else (-320, -256)
        m.low(640, sv1, 896, sv2, deck + 112, floor=deck)
        m.side(640, sv1, 896, sv2)
        m.portal(640, 258 * s - (2 if s < 0 else 0), deck, 896, 258 * s + (2 if s > 0 else 0), deck + 112)
        lining(m, 640, sv1, 896, sv2, lambda v: deck, deck + 112, {"u1": [], "u2": [], ("v2" if s > 0 else "v1"): []},
               skin=("u1", "u2", "v2" if s > 0 else "v1"))
        for u in (700, 836):
            m.dynamic(P + "props_wasteland/kitchen_shelf001a.mdl", u, 302 * s, 0 if s > 0 else 180, deck)
        m.dynamic(P + "props_wasteland/kitchen_counter001b.mdl", 768, 286 * s, 90 if s > 0 else 270, deck)
        m.static(P + "props_c17/light_domelight02_off.mdl", 768, 290 * s, 0, deck + 112 - 7)
        m.static(P + "props_junk/glassjug01.mdl", 700, 300 * s, 0, deck + 64)
        m.static(P + "props_lab/jar01a.mdl", 836, 300 * s, 0, deck + 64)
        m.grime("poster", 641, 290 * s, deck + 70, 7 + s)
        for u in (712, 824):
            m.static(P + "props_building_details/storefront_template001a_bars.mdl", u, 246 * s, 90, deck)
    # three empty stalls down the middle: the game's kitchen counters, a pushcart left by one
    for c in (-160, 0, 160):
        m.dynamic(P + "props_wasteland/kitchen_counter001d.mdl", 768, c, 0 if c else 180, deck)
    m.dynamic(P + "props_junk/pushcart01a.mdl", 852, 150, 100, deck)
    m.target("lc_arcade_upper", 768, 80, deck + 8, 0)
    for c in (-160, 0, 160):
        m.static(P + "props_c17/awning001a.mdl", 768, c, 0 if c else 180, roof - 45)
    for (u, v, model) in ((760, -190, "props_junk/watermelon01"), (776, -168, "props_junk/watermelon01"), (764, -140, "props_junk/watermelon01"),
                          (770, 20, "props_c17/metalpot001a"), (760, 150, "props_junk/plasticcrate01a")):
        m.static(P + model + ".mdl", u, v, 0, deck + 40)
    for v in (-80, 80, 230, -230):                                   # tie beams across the walk, a hanging lamp under each
        m.det([(652, v - 4, roof - 16, 884, v + 4, roof)], WOODTRIM)
        m.static(P + "props_c17/lampfixture01a.mdl", 768, v, 0, roof - 36)
        m.light(768, v, roof - 48, "255 205 150 32")
    m.soundscape(SCAPES["house"], 768, 0, deck, radius=300)
    m.soundscape(SCAPES["watery"], 768, 0, F, radius=360)
    canal_grime(m, 16, 560, 5200)
    canal_grime(m, 980, 1520, 5300)

    m.loose(P + "props_junk/wood_pallet001a.mdl", 850, -60, 30, z=deck)
    put(m, P + "props_trainstation/trashcan_indoor001b.mdl", 690, 120, 0, z=deck)
    m.loose(P + "props_junk/wood_crate002a.mdl", 690, -200, 90, z=deck)
    put(m, P + "props_c17/oildrum001.mdl", 850, 200, 0, z=deck)
    for (u, v) in ((692, 224), (692, 80), (692, -100), (844, 100), (844, -80), (844, -224)):
        m.lane(u, v, deck)
    # --- below: what has washed up against the piers ---
    put(m, P + "props_debris/concrete_chunk02a.mdl", 590, -30, 100)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 950, 30, 40)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 610, 150, 0)
    put(m, P + "props_c17/oildrum001.mdl", 930, -150, 0)
    m.view(430, -40, F, 5, -10, "the arches")
    m.view(250, 150, F, 15, -16, "the left stair")
    m.view(668, 224, deck, 280, 6, "the walk and its stalls")
    m.view(870, 90, deck, 200, 12, "from the walk, the way people come")
    m.view(1420, 0, F, 180, -10, "from the far side")
    b.notes.append("%s: the walk is at z %d, 256 wide, under a roof at z %d; the arches' crowns are %d over the floor" % (m.tag, deck, roof, deck - 32 - F))


# ---------------------------------------------------------------------------
# chimney
# ---------------------------------------------------------------------------

def ring(r, k=None):
    """An octagon's corners round (0, 0), going round: r to its flat sides, k to where they end (0.4 r)."""
    k = (2 * r) // 5 if k is None else k
    return [(r, k), (k, r), (-k, r), (-r, k), (-r, -k), (-k, -r), (k, -r), (r, -k)]


def frustum(bottom, top, z1, z2, mat):
    """A solid between two flat outlines of the same number of corners, one at z1 and one at z2 (its sides lean)."""
    n = len(bottom)
    faces = [([(u, v, z1) for u, v in bottom], mat), ([(u, v, z2) for u, v in top], mat)]
    for i in range(n):
        j = (i + 1) % n
        faces.append(([bottom[i] + (z1,), bottom[j] + (z1,), top[j] + (z2,), top[i] + (z2,)], mat))
    return faces


def m_chimney(m, opt):
    """The chimney. The canal widens to the right into a round yard 896 across, its wall faced with straight segments
    drawn through the inner corners of the squares' steps (so it reads as a many-sided court, not a staircase), the
    canal's lip carried round it at the trim; in its middle stands what is left of a factory: its brick chimney,
    eight-sided, hollow (200 across inside), on a stone plinth 320 across with a coping, tapering to its top 624 over
    the canal floor and 240 over the canal walls' tops, built in courses as a works chimney is: dark brick with two bands
    of light stone and three iron hoops, a corbelled crown flaring out under the gallery, a lightning conductor down its
    back. A doorway 48 wide and 96 high at its foot faces the canal. Inside, slabs of stone climb round the wall in
    thirteen short flights (five treads and a landing in each corner, 48 up a side, an open well down the middle with the
    old hoist rope hanging in it from a pulley under the cap) to an iron gallery round the chimney's top: plates to crouch
    behind on four sides, the city's handrails on the other four and round the stair's head, a cap on four posts, a pair
    of binoculars left there. From up there the whole canal both ways is in view: a sniper's nest with one way up
    (lc_chimney_top). In the yard, the works that was: a brick wall with two arched windows, broken off at the top, a
    leaning piece of another, the pulley wheels of its machinery, drums, a skip, a car. Sounds: the quiet courtyard down
    in the yard, the wind on a rooftop up on the gallery (both the owner's map's own).
    Named for the game: lc_chimney_top (an info_target on the gallery).
    Left as brushes: the chimney, its plinth, courses, crown, door frame and stair (the building), the gallery's floor,
    its parapet plates, the cap and its posts, the yard's facing wall and lip, the works' broken walls.
    Unchecked: that the corner landings turn a player comfortably (about 38 of clear floor between the well and the
    corner's wall); how the taper and the courses look in brick and stone; whether the map's fog or far plane hides
    the canal from up there; how the binoculars and the pulley wheels face. The courses' joints step 1 unit between
    neighbouring sides (so no two faces share a plane): too small to see."""
    b = m.b
    cu, cv, R = 512, -576, 448
    plinth, top = F + 128, F + 624
    if top + 104 > b.sky - 32:
        b.problems.append("%s: the sky is too low for the chimney" % m.tag)
    steel = HULL
    m.open(0, -256, 1024, 256)
    for i in range(-8, 8):
        for j in range(-8, 8):
            u, v = cu + i * CELL, cv + j * CELL
            if math.hypot(i + 0.5, j + 0.5) * CELL < R and v + CELL <= -256:
                m.open(u, v, u + CELL, v + CELL)
    m.side(cu - 160, cv - 160, cu + 160, cv + 160)
    m.blocked(cu - 192, cv - 192, cu + 192, cv + 192)
    # the yard's wall: the squares' stepped outline, faced with a wall of straight segments drawn through its inner
    # corners (each segment lies in the yard, so none of the steps shows), the canal's lip along it at the trim
    m.no_bank(cu - 520, cv - 520, cu + 520, -264)
    m.taken(cu - 520, cv - 520, F, cu + 520, -264, b.rim)
    yard = set()
    for i in range(-8, 8):
        for j in range(-8, 8):
            u, v = cu + i * CELL, cv + j * CELL
            if math.hypot(i + 0.5, j + 0.5) * CELL < R and v + CELL <= -256:
                yard.add((u, v))
    corners = []
    for (u, v) in yard:
        for (x, y) in ((u, v), (u + CELL, v), (u, v + CELL), (u + CELL, v + CELL)):
            near = [(x - CELL, y - CELL), (x, y - CELL), (x - CELL, y), (x, y)]
            if sum(1 for c in near if c in yard) == 3 and y <= -256:      # an inner corner of the steps
                corners.append((x, y))
    for (u, v) in sorted(yard):                                           # ...and the two ends where the yard meets the canal
        if v == -320 and (u - CELL, v) not in yard:
            corners.append((u, -256))
        if v == -320 and (u + CELL, v) not in yard:
            corners.append((u + CELL, -256))
    corners = sorted(set(corners), key=lambda p: math.atan2(p[1] - cv, p[0] - cu))
    segs, lip = [], []
    for k in range(len(corners) - 1):
        (x1, y1), (x2, y2) = corners[k], corners[k + 1]
        if (y1 == -256 and y2 == -256) or x1 == x2 or y1 == y2:
            continue                     # (along the squares' own line the wall is straight already: nothing to face)
        def out(x, y, d):
            r = math.hypot(x - cu, y - cv)
            return (int(round(cu + (x - cu) * (r + d) / r)), int(round(cv + (y - cv) * (r + d) / r)))
        o1, o2 = out(x1, y1, 72), out(x2, y2, 72)
        i1, i2 = out(x1, y1, -16), out(x2, y2, -16)
        segs.append(vprism([(x1, y1), (x2, y2), o2, o1], F, b.rim + k % 2, "concrete/concretewall008a"))
        lip.append(vprism([(x1, y1), (x2, y2), i2, i1], TRIM + k % 2, TRIM + 16 + k % 2, MAT["beam"]))
    m.shapes(segs + lip)

    def at(pts):
        return [(cu + du, cv + dv) for du, dv in pts]
    inner, base, foot, head = ring(100), ring(160), ring(150), ring(125)
    g = top

    def rad(z):                     # the shaft's outline at z (it tapers from 150 at the plinth to 125 at its top)
        return ring(150 - (25 * (z - plinth)) // (top - plinth))
    # (each course's joints step 1 between neighbouring sides, and none lies level with a stair tread's face: no two
    # faces share a plane)
    courses, z0 = [], plinth
    for z1, mat in ((F + 220, BRICK), (F + 228, HULL), (F + 332, BRICK), (F + 348, "stone/stonewall050f"), (F + 452, BRICK), (F + 459, HULL),
                    (F + 524, BRICK), (F + 540, "stone/stonewall050f"), (F + 580, BRICK), (F + 587, HULL)):
        courses.append((z0, z1, mat))
        z0 = z1
    crown = z0

    def jz(z, i):
        return z + (i % 2) if plinth < z < g - 8 else z
    # --- the plinth, with the doorway in its side toward the canal ---
    shapes = []
    for i in range(8):
        j = (i + 1) % 8
        if i == 1:
            continue
        shapes.append(vprism(at([base[i], base[j], inner[j], inner[i]]), F, plinth + i % 2, STONE))     # (its joints step 1 from side to side)
        for (z1, z2, mat) in courses:
            r1, r2 = rad(z1), rad(z2)
            shapes.append(frustum(at([r1[i], r1[j], inner[j], inner[i]]), at([r2[i], r2[j], inner[j], inner[i]]), jz(z1, i), jz(z2, i), mat))
        shapes.append(frustum(at([rad(crown)[i], rad(crown)[j], inner[j], inner[i]]), at([ring(170)[i], ring(170)[j], inner[j], inner[i]]), jz(crown, i), g - 8, BRICK))
        shapes.append(frustum(at([ring(161)[i], ring(161)[j], foot[j], foot[i]]), at([ring(158)[i], ring(158)[j], foot[j], foot[i]]), plinth, plinth + 6 + i % 2, "stone/stonewall050f"))
    shapes += [vprism(at([(-64, 160), (-24, 160), (-24, 100), (-40, 100)]), F, plinth, STONE), vprism(at([(24, 160), (64, 160), (40, 100), (24, 100)]), F, plinth, STONE),
               vprism(at([(-24, 160), (24, 160), (24, 100), (-24, 100)]), F + 96, plinth, STONE)]
    for (z1, z2, mat) in courses:
        r1, r2 = rad(z1), rad(z2)
        shapes.append(frustum(at([r1[1], r1[2], inner[2], inner[1]]), at([r2[1], r2[2], inner[2], inner[1]]), jz(z1, 1), jz(z2, 1), mat))
    shapes.append(frustum(at([rad(crown)[1], rad(crown)[2], inner[2], inner[1]]), at([ring(170)[1], ring(170)[2], inner[2], inner[1]]), jz(crown, 1), g - 8, BRICK))
    shapes.append(frustum(at([ring(161)[1], ring(161)[2], foot[2], foot[1]]), at([ring(158)[1], ring(158)[2], foot[2], foot[1]]), plinth, plinth + 7, "stone/stonewall050f"))
    shapes.append(para((cu - 1, cv - 152, plinth + 6), (2, 0, 0), (0, 2, 0), (0, 25, g - 52 - plinth), MAT["bars"]))   # the lightning conductor
    m.shapes(shapes)
    m.det([(cu - 28, cv + 158, F + 95, cu + 28, cv + 164, F + 104), (cu - 30, cv + 158, F, cu - 23, cv + 164, F + 95), (cu + 23, cv + 158, F, cu + 30, cv + 164, F + 95)], steel)     # the door's frame
    m.det([(cu - 24, cv + 100, F, cu + 24, cv + 176, F + 4)], MAT["beam"])
    # --- the stair: thirteen flights round the inside, each on the next wall, a landing in each corner ---
    def turn(f, a, c):
        return [(c, -a), (-a, -c), (-c, a), (a, c)][f % 4]

    def slab(f, a1, c1, a2, c2, z1, z2):
        (x1, y1), (x2, y2) = turn(f, a1, c1), turn(f, a2, c2)
        return (cu + min(x1, x2), cv + min(y1, y2), z1, cu + max(x1, x2), cv + max(y1, y2), z2)
    treads, lands = [], []
    for k in range(13):
        z = F + 48 * k
        for i in range(5):
            treads.append(slab(k, -30 + 12 * i, 60, -18 + 12 * i, 100, z + 8 * i + 2, z + 8 * i + 8))
        lands.append(slab(k, 30, 30, 100, 100, z + 42, z + 48))
    m.det(treads, STONE)
    m.det(lands[:-1], STONE)
    m.static(P + "props_c17/pulleywheels_small01.mdl", cu, cv, 0, top + 76)                 # the hoist's pulley under the cap
    m.det([(cu - 1, cv - 12, top + 86, cu + 1, cv + 12, top + 97)], MAT["bars"])
    m.rope([(cu, cv, top + 78), (cu + 6, cv - 6, F + 8)], slack=30)
    for z in (F + 110, F + 300, F + 480):
        m.light(cu, cv, z, "255 190 120 14")
    # --- the gallery: an iron floor round the top (open over the last flights), plates and rails, a cap ---
    floor = [[(-30, 176), (-70, 176), (-176, 70), (-176, -70), (-70, -176), (-30, -176)], [(-30, -176), (30, -176), (30, 60), (-30, 60)], [(-30, 100), (30, 100), (30, 176), (-30, 176)],
             [(30, -176), (70, -176), (176, -70), (176, -30), (30, -30)], [(100, -30), (176, -30), (176, 70), (100, 146)], [(30, 100), (100, 100), (100, 146), (70, 176), (30, 176)]]
    m.shapes([vprism(at(f), g - 8, g, steel) for f in floor])
    edge = ring(176, 70)
    rails, plates = [], []
    for i in range(8):
        j = (i + 1) % 8
        (x1, y1), (x2, y2) = edge[i], edge[j]
        o = (cu + x1, cv + y1)
        a = (x2 - x1, y2 - y1, 0)
        inward = (-2 if x1 + x2 > 0 else 2 if x1 + x2 < 0 else 0, -2 if y1 + y2 > 0 else 2 if y1 + y2 < 0 else 0, 0)
        if i % 2:                                   # the four flat sides: plates to crouch behind
            plates.append(para(o + (g,), a, inward, (0, 0, 38), steel))
        else:                                       # the four corners: a handrail along each, turned to its line
            mu, mv = (x1 + x2) * 97 // 200, (y1 + y2) * 97 // 200
            yaw = {(1, 1): 45, (-1, 1): 135, (-1, -1): 225, (1, -1): 315}[(1 if mu > 0 else -1, 1 if mv > 0 else -1)]
            m.static(P + "props_c17/handrail04_long.mdl", cu + mu, cv + mv, yaw, g)
    m.shapes(rails + plates)
    m.det([(cu + x - 3, cv + y - 3, g, cu + x + 3, cv + y + 3, g + 96) for x in (-112, 112) for y in (-112, 112)], MAT["bars"])
    m.shapes([vprism(at(ring(150)), g + 96, g + 104, MM["tin"])])
    m.static(P + "props_c17/handrail04_medium.mdl", cu + 30, cv + 20, 0, g)          # a rail by the stair's opening
    m.static(P + "props_c17/handrail04_medium.mdl", cu - 2, cv + 60, 90, g)
    m.target("lc_chimney_top", cu - 90, cv, g + 8, 90)
    m.static(P + "props_combine/combine_binocular01.mdl", cu - 130, cv - 40, 300, g)          # binoculars left for the lookout
    m.soundscape(SCAPES["rooftop"], cu, cv, g, radius=240)
    # --- the yard: what is left of the works ---
    wu1, wu2 = cu - 300, cu - 284
    m.det(wall(wu1, cv - 220, wu2, cv + 180, F, F + 180, [(cv - 120, cv - 56, F + 48, F + 150), (cv + 4, cv + 68, F + 48, F + 150)]), BRICK)
    m.shapes(arch(cv - 120, cv - 56, F + 150, 32, wu1, wu2, BRICK) + arch(cv + 4, cv + 68, F + 150, 32, wu1, wu2, BRICK) +
             [prism([(cv - 220, F + 180), (cv - 150, F + 180), (cv - 190, F + 236)], "x", wu1, wu2, BRICK),         # its top broken off
              prism([(cv + 90, F + 180), (cv + 180, F + 180), (cv + 180, F + 210)], "x", wu1, wu2, BRICK)])
    m.det([(wu1 - 2, a1, F + 44, wu2 + 2, a2, F + 49) for (a1, a2) in ((cv - 124, cv - 52), (cv, cv + 72))], "stone/stonewall050f")       # sills
    m.static(P + "props_c17/pulleywheels_large01.mdl", cu + 150, cv + 200, 30, F)
    m.static(P + "props_c17/pulleywheels_large01.mdl", cu - 200, cv + 60, 80, F)
    m.shapes([para((cu + 200, cv - 120, F), (16, 140, 0), (60, -8, 90), (12, 0, 0), BRICK)])
    put(m, P + "props_c17/oildrum001.mdl", cu + 200, cv + 120, 0)
    put(m, P + "props_c17/oildrum001.mdl", cu + 232, cv + 100, 0)
    put(m, P + "props_junk/trashdumpster02.mdl", cu - 220, cv - 150, 100)
    put(m, P + "props_debris/broken_pile001a.mdl", cu + 60, cv + 230, 30)
    put(m, P + "props_debris/concrete_chunk01a.mdl", cu - 100, cv + 250, 120)
    m.loose(P + "props_junk/wood_pallet001a.mdl", cu + 250, cv - 40, 20)
    m.loose(P + "props_junk/wood_crate001a.mdl", cu + 40, cv + 40, 20)
    put(m, P + "props_vehicles/car002a_physics.mdl", cu - 60, cv - 250, 200)
    m.blocked(cu - 320, cv - 240, cu - 264, cv + 220)
    m.lane(cu, cv + 200, F)
    m.lane(cu, cv + 130, F)
    for kind, u, v, z, seed in (("stain", cu, cv + 152, F + 200, 1), ("graffiti", cu - 140, cv + 60, F + 60, 2), ("debris", cu + 100, cv + 260, F + 1, 3),
                                ("puddle", cu - 120, cv - 300, F + 1, 4), ("trash", cu + 220, cv + 60, F + 1, 5), ("stain", wu2, cv + 120, F + 120, 6)):
        m.grime(kind, u, v, z, seed)
    m.soundscape(SCAPES["courtyard"], cu, cv + 200, F, radius=600)
    canal_grime(m, 16, 180, 5400)
    canal_grime(m, 840, 1010, 5500)
    m.view(200, 60, F, 315, -14, "the chimney from the canal")
    m.view(cu, cv + 250, F, 270, -4, "its doorway")
    m.view(cu - 40, cv + 60, F, 300, -40, "up the well")
    m.view(cu - 90, cv + 30, g, 80, 14, "from the gallery, over the canal")
    m.view(cu - 60, cv - 40, g, 0, 10, "the gallery: the stair's head")
    b.notes.append("%s: the chimney's middle is at (%d %d); its gallery is at z %d (%d over the walls' tops), its cap at z %d; the sky's lid is at z %d" % (
        (m.tag,) + m.fr.pt(cu, cv) + (g, g - b.rim, g + 104, b.sky)))


# ---------------------------------------------------------------------------
# crypt
# ---------------------------------------------------------------------------

def coffin(m, u1, v1, z, opened=False, ajar=False):
    """A stone coffin lying along v: a carved base of brushes 36 by 104 by 24 under one of the graveyard's own stone
    lids (gravestone_coffinpiece001a, 113 by 57 by 20). ajar: the lid slid 8 toward -u and turned; opened: the base
    hollow, the lid (coffinpiece002a) off and leaning against its +u side, one edge on the floor."""
    u2, v2 = u1 + 36, v1 + 104
    mu, mv = u1 + 18, v1 + 52
    lid = P + "props_c17/gravestone_coffinpiece00%da.mdl"
    if not opened:
        m.det([(u1, v1, z, u2, v2, z + 24)], STONE)
        if ajar:
            m.static(lid % 1, mu - 8, mv + 4, 93, z + 24)
        else:
            m.static(lid % 1, mu, mv, 90, z + 24)
        return
    m.det([(u1, v1, z, u2, v2, z + 4), (u1, v1, z + 4, u1 + 5, v2, z + 24), (u2 - 5, v1, z + 4, u2, v2, z + 24), (u1 + 5, v1, z + 4, u2 - 5, v1 + 5, z + 24),
           (u1 + 5, v2 - 5, z + 4, u2 - 5, v2, z + 24)], STONE)
    m.det([(u1 + 5, v1 + 5, z + 4, u2 - 5, v2 - 5, z + 5)], MAT["black"])
    tilted(m, "prop_static", lid % 2, u2 + 22, mv, z + 21, 90, 0, 31)     # (its far edge on the base's top, its near one on the floor)


def m_crypt(m, opt):
    """The crypt. The canal's left wall has broken through into the crypt of a church that is no longer there: a
    ragged hole 128 wide at the top of the bank (the bank is the way up), torn rather than cut (teeth of brick and stone
    round it), broken slabs round it and rubble down the bank under it; from the canal it is a dark mouth with
    candlelight deep inside. Then a vaulted room 512 square under a roof 112 high, its floor of old stone 128 over the
    canal's. Four squat pillars carry arches both ways. In each side wall two burial niches hold a stone coffin under
    one of the graveyard's carved lids; one lid is ajar, bones lie in a niche. In the middle of the nave stands a tomb
    that has been opened, its lid leaning against it, a skull in it and bones spilled beside it. At the back Lost
    Coast's monastery altar on a step, two of its tall candlesticks, a cross cut in the wall behind it (lc_crypt_altar),
    and to its right a stair that once went up into the church: bricked up, with a crack of daylight at the top. Stone
    plaques on the walls. It is lit by people, not by fittings: candles here and there (a cluster on the altar, one in
    a niche, one on a pillar's base, a few by the tomb, one on the stair; the other pillars dark), dust hanging in their
    light, a little day at the hole. The Resistance uses it: a radio on the altar, a mattress for the wounded, the lambda
    on the wall. Water from the canal stains the wall by the hole and stands on the floor. It drips
    (prison.general_dripping_tunnel). Quiet and old: a place to hide, to meet, or to be buried.
    Named for the game: lc_crypt_altar (an info_target before the altar).
    Left as brushes: the crypt, pillars, vault, niches, the coffins' carved bases, the altar's step, the cross cut in
    the wall, the plaques, the bricked stair, the broken slabs and teeth round the hole, the candle stubs (no model of one
    exists).
    Unchecked: the bones (models/gibs) as prop_dynamics; which way the altar faces; the look of stone/stonefloor006d_c17
    and stone/stonewall040f; whether the candles' small lights are enough to see by; the func_dustmotes keys."""
    b = m.b
    cz, ceil = F + 128, F + 240
    floor = "stone/stonefloor006d_c17"
    m.open(0, -256, 1024, 256)
    m.low(448, 256, 576, 320, ceil, floor=cz, mat=floor)                 # the hole
    m.low(256, 320, 768, 832, ceil, floor=cz, mat=floor)                 # the crypt
    for (u, v) in ((384, 448), (576, 448), (384, 640), (576, 640)):      # its pillars
        m.unpaint(u, v, u + 64, v + 64)
    niches = [(192, 384), (192, 576), (768, 384), (768, 576)]
    for (u, v) in niches:
        m.low(u, v, u + 64, v + 128, cz + 96, floor=cz + 24, mat=floor)
    m.low(640, 832, 768, 960, ceil, floor=cz, mat=floor)                 # the stair that went up
    m.side(192, 256, 832, 960)
    m.portal(448, 286, cz, 576, 288, ceil)
    m.taken(416, 200, F, 608, 256, b.rim)
    # --- the hole: broken slabs of the wall round it and under it ---
    m.shapes([para((428, 236, cz - 20), (26, 0, 0), (-10, 0, 150), (0, 22, 0), MAT["canal_wall"]), para((574, 240, cz - 10), (24, 0, 0), (12, 0, 128), (0, 18, 0), MAT["canal_wall"]),
              para((440, 238, ceil - 6), (150, 0, 14), (0, 20, 0), (0, 0, 22), MAT["canal_wall"]), para((400, 130, F), (60, 16, 0), (-8, 50, 40), (0, 0, 12), MAT["beam"]),
              para((590, 150, F + 20), (50, -10, 0), (10, 44, 30), (0, 0, 12), MAT["beam"]), para((452, 262, cz), (30, 6, 0), (-6, 40, 0), (0, 0, 9), STONE),
              para((540, 300, cz), (28, -8, 0), (10, 34, 0), (0, 0, 7), STONE)])
    ragged(m, "u", 0, 250, 280, 448, 576, cz, ceil, BRICK, 1)                      # the hole torn, not cut: brick teeth round it
    m.shapes([prism([(448, cz + 60), (470, cz + 80), (448, cz + 96)], "y", 251, 271, STONE), prism([(576, ceil - 20), (548, ceil), (576, ceil)], "y", 252, 270, STONE)])
    put(m, P + "props_debris/concrete_chunk01a.mdl", 500, 110, 30)
    put(m, P + "props_debris/broken_pile001a.mdl", 600, 90, 70)
    put(m, P + "props_debris/concrete_chunk02a.mdl", 560, 330, 10, z=cz)
    m.static(P + "props_debris/concrete_debris128pile001b.mdl", 512, 174, 0, F + 40)      # what came down the bank when it broke
    m.light(512, 290, ceil - 20, "170 190 220 16")
    m.lane(512, 220, F + 92)
    m.lane(512, 296, cz)
    # --- the vault: a base and a capital on each pillar, arches both ways from pillar to pillar and to the walls ---
    ribs, blocks = [], []
    for (u, v) in ((384, 448), (576, 448), (384, 640), (576, 640)):
        blocks += [(u - 6, v - 6, cz, u + 70, v + 70, cz + 10), (u - 8, v - 8, ceil - 34, u + 72, v + 72, ceil - 22)]
    for v in (448, 640):
        for (a, c) in ((256, 384), (448, 576), (640, 768)):
            ribs += arch(a, c, ceil, 32, v + 8, v + 56, STONE, "y")
    for u in (384, 576):
        for (a, c) in ((320, 448), (512, 640), (704, 832)):
            ribs += arch(a, c, ceil, 32, u + 8, u + 56, STONE, "x")
    m.det(blocks, STONE)
    m.shapes(ribs)
    # --- the niches' coffins (one lid ajar), the tomb in the nave ---
    for k, (u, v) in enumerate(niches):
        cu = u + 14
        coffin(m, cu, v + 12, cz + 24, ajar=(k == 2))
        m.det([(u + (61 if u < 512 else -1), v, cz, u + (65 if u < 512 else 3), v + 128, cz + 25)], STONE)          # the niche's sill
    m.det([(470, 548, cz, 586, 676, cz + 8)], STONE)
    coffin(m, 494, 560, cz + 8, opened=True)
    m.dynamic(P + "gibs/hgibs.mdl", 512, 640, 0, z=cz + 13)
    for (u, v, yaw, model) in ((560, 716, 30, "hgibs_rib"), (548, 728, 100, "hgibs_spine"), (574, 724, 0, "hgibs"), (220, 500, 70, "hgibs_scapula")):
        m.dynamic(P + "gibs/%s.mdl" % model, u, v, yaw, z=cz + (24 if u < 256 else 0))      # bones out of the opened tomb, and in a niche
    m.blocked(448, 512, 576, 704)
    # --- the altar on its step, the cross behind it ---
    m.det([(432, 752, cz, 592, 832, cz + 8)], STONE)
    m.static(P + "lostcoast/props_monastery/altar.mdl", 512, 806, 270, cz + 8)
    for u in (420, 604):
        m.dynamic(P + "lostcoast/props_monastery/candlestick.mdl", u, 788, 270, cz)
        m.glow(u, 788, cz + 104, "255 190 110", 0.12)
        m.light(u, 788, cz + 100, "255 170 90 9")
    m.det([(506, 828, cz + 56, 518, 832, cz + 108), (490, 828, cz + 84, 506, 832, cz + 94), (518, 828, cz + 84, 534, 832, cz + 94)], STONE)
    m.static(P + "props_lab/citizenradio.mdl", 492, 812, 270, cz + 49)                     # the Resistance meets here: a radio on the altar
    mattress(m, 712, 760, 0, cz)                                                          # ...and keeps its wounded here
    m.det([(256, 532, cz + 44, 258, 572, cz + 76), (766, 404, cz + 44, 768, 444, cz + 76), (360, 830, cz + 50, 400, 832, cz + 82)], "stone/stonewall050f")   # plaques
    m.target("lc_crypt_altar", 512, 730, cz + 8, 90)
    m.blocked(448, 768, 576, 832)
    # --- the stair up into the church: three steps, then brick, black through the gap at its top ---
    m.steps(840, 656, 752, cz, cz + 24, "v", 1)
    m.det([(640, 876, cz, 768, 892, ceil - 14)], BRICK)
    m.det([(640, 892, cz, 768, 960, ceil)], MAT["black"])
    m.det([(640, 832, cz, 656, 876, ceil - 12), (752, 832, cz, 768, 876, ceil - 12), (640, 832, ceil - 12, 768, 846, ceil)], STONE)
    m.spot(704, 872, ceil - 8, "210 220 240 50", 270, pitch=35, cone=30)                  # a crack of day over the bricks: the church above
    m.blocked(640, 832, 768, 960)
    # --- candle stubs: a stub of wax, a small steady light, a glow ---
    # (lit by people, not fittings: a cluster on the altar, one in a niche, one on a pillar's base, a few on the floor
    # by the tomb, one on the stair; the other pillars dark)
    from map_mods_b import candle
    for (u, v, z, lit, high) in ((476, 806, cz + 49, True, 8), (548, 806, cz + 49, True, 6), (512, 800, cz + 49, False, 10), (250, 448, cz + 24, True, 5),
                                 (774, 640, cz + 24, True, 7), (412, 444, cz + 10, True, 6), (452, 722, cz, True, 9), (462, 732, cz, False, 5),
                                 (444, 736, cz, False, 7), (700, 850, cz + 12, True, 4)):
        candle(m, u, v, z, high, lit)
    m.ent("func_dustmotes", {"SpawnRate": "20", "Color": "255 230 200", "SizeMin": "8", "SizeMax": "16", "Alpha": "200", "MinSpeed": "1", "MaxSpeed": "2",
                             "LifetimeMin": "4", "LifetimeMax": "6", "DistMax": "800", "Frozen": "0", "StartDisabled": "0"},
          [(400, 360, cz + 8, 624, 800, ceil - 40)], MAT["trigger"])
    for kind, u, v, z, seed in (("stain", 446, 300, cz + 60, 1), ("stain", 578, 300, cz + 70, 2), ("puddle", 512, 360, cz + 1, 3), ("stain", 448, 320, cz + 1, 4),
                                ("crack", 256, 700, cz + 90, 5), ("lambda", 768, 760, cz + 60, 6), ("stain", 512, 255, F + 160, 7)):
        m.grime(kind, u, v, z, seed)
    m.soundscape(SCAPES["tunnel"], 512, 560, cz, radius=420)
    canal_grime(m, 16, 400, 5600)
    canal_grime(m, 640, 1010, 5700)
    for (u, v) in ((512, 400), (512, 720), (320, 580), (704, 580)):
        m.lane(u, v, cz)
    m.view(512, -40, F, 90, -12, "the hole in the wall")
    m.view(512, 300, cz, 90, 2, "coming in: the nave, the tomb, the altar")
    m.view(330, 350, cz, 60, 4, "the left aisle: niches, pillars")
    m.view(530, 700, cz, 40, 2, "the altar and the bricked stair")
    m.view(700, 420, cz, 20, 6, "a niche: the lid ajar")
    b.notes.append("%s: the crypt's floor is z %d, its roof z %d; the hole is 128 wide at the top of the left bank" % (m.tag, cz, ceil))


# ---------------------------------------------------------------------------
# lift (experimental)
# ---------------------------------------------------------------------------

def m_lift(m, opt):
    """The freight lift (experimental: nothing like it has been compiled yet). A loading dock is recessed into the
    left wall at the trim's height, 448 by 320 and open to the sky: a low wall along its edge, a van backed up to the
    lift with its back open, the Combine's supply crates on a pallet, a clipboard on the wall, a street gate (the city's
    own fence gate, 128 square) with a Breen poster by it, one of the city's street lamps. The gate and the cap behind
    it are in one visgroup ("the dock's street end (delete to join a street)"). Against the wall below the dock, where
    the bank is cut away, a lift platform 160 square with the city's handrails on three sides (riding on it; an unseen
    rail in the platform does their blocking) rides between four guide posts from the canal floor (its deck 8 over the
    floor) up 256 to the dock (its deck 8 over the dock's: a step down). It hangs from cables run over the sheave at the
    frame's head, beside the motor's housing, and their low ends ride with it; a counterweight falls in its channel
    against the wall as it rises; a caged lamp lights the frame at each level. It is one func_door,
    lc_lift_platform, that stays where it is sent; each of three buttons sends it to its other end (Toggle), and the
    counterweight with it: one on a post at the bottom, one on a post on the dock, one on a stand on the platform that
    rides with it. Its own moving sound is a motor's, looping while it moves, and a clank when it stops. Sounds: the
    quiet courtyard on the dock, the metal's groan by the lift.
    Named for the game: lc_lift_platform (func_door: Open is up, Close is down, Toggle), lc_lift_counterweight (a
    func_door that moves the other way: Toggle with the platform), lc_lift_button_low, lc_lift_button_high (func_buttons
    that already work), lc_lift_button_ride (a func_button parented to the platform), lc_lift_dock (an info_target on
    the dock), lc_lift_street (an info_target at the street gate).
    Left as brushes: the platform's deck and the stand its button sits on (what the game moves), the counterweight and
    its channel, the guide posts, their ties, sheave and the motor's housing (the lift's frame), the gate's frame, the
    dock's low wall, the buttons' posts.
    Unchecked: that the handrails and the cables' ends parented to the platform ride with it smoothly; that a func_door
    carries players up 256 smoothly and reverses if someone stands under it (it does no harm: dmg 0); that the button
    parented to it follows and still takes a press; that the counterweight keeps time with the platform (both take
    about 5.4 seconds); the sounds plats/elevator_move_loop1.wav and plats/elevator_stop1.wav; the buttons' model is
    Episode Two's; which way the van faces (taken to be its +x)."""
    b = m.b
    steel = HULL
    m.open(0, -256, 1024, 256)
    m.open(320, 256, 768, 576, floor=TRIM, mat=MAT["quay_floor"])
    m.low(448, 576, 576, 704, TRIM + 128, floor=TRIM, mat=MAT["quay_floor"])
    m.side(320, 256, 768, 704)
    m.side(448, 64, 640, 256)                                           # (no mud over the platform)
    gate = "%s: the dock's street end (delete to join a street)" % b.vis
    m.world((448, 640, TRIM, 576, 704, TRIM + 128), MAT["black"], vis=gate)
    m.prop("prop_static", P + "props_c17/gate_door02a.mdl", 512, 584, 90, TRIM, {"solid": "6", "disableshadows": "0", "fademindist": "-1", "fadescale": "1"}, vis=gate)
    b.plan.keep_out.append(m.fr.rect(384, 704, 640, 768))
    m.blocked(448, 576, 576, 704)
    m.det([(428, 560, TRIM, 448, 576, TRIM + 128), (576, 560, TRIM, 596, 576, TRIM + 128), (420, 556, TRIM + 128, 604, 576, TRIM + 152)], MAT["beam"])
    m.target("lc_lift_street", 512, 540, TRIM + 8, 270)
    m.target("lc_lift_dock", 544, 400, TRIM + 8, 270)
    # --- the lift: the bank cut away, four guide posts tied at their heads, the platform ---
    u1, v1, u2, v2 = 464, 96, 624, 256
    m.no_bank(448, 248, 704, 264)
    posts = [(u, v, F, u + 8, v + 8, TRIM + 120) for u in (u1 - 8, u2) for v in (v1 - 8, v2 - 8)]
    posts += [(u1 - 8, v1 - 8, TRIM + 120, u2 + 8, v1, TRIM + 128), (u1 - 8, v2 - 8, TRIM + 120, u2 + 8, v2, TRIM + 128),
              (u1 - 8, v1, TRIM + 120, u1, v2 - 8, TRIM + 128), (u2, v1, TRIM + 120, u2 + 8, v2 - 8, TRIM + 128), (536, v1 - 8, TRIM + 128, 552, v2, TRIM + 140)]
    posts += [(u - 1, v1 - 6, z, u + 9, v1 - 2, z + 4) for u in (u1 - 8, u2) for z in range(F + 96, TRIM + 100, 96)]         # cleats up the two free posts
    m.det(posts, MAT["bars"])
    m.shapes([prism(octagon(176, TRIM + 152, 14), "x", 538, 550, MAT["bars"])])                                                # the sheave
    m.det([(u1 - 17, v1 - 17, F, u1 + 1, v1 + 1, F + 6), (u2 - 1, v1 - 17, F, u2 + 17, v1 + 1, F + 6)], MAT["beam"])
    m.det([(556, 150, TRIM + 128, 600, 200, TRIM + 164)], HULL)                                                                 # the motor's housing by the sheave
    m.grime("danger", 578, 149, TRIM + 146, 1)
    # cables from the sheave down to the platform's corners, their low ends riding with it
    for k, (cu_, cv_) in enumerate(((u1 + 6, v1 + 6), (u2 - 6, v1 + 6))):
        names = ["lc_rope_%s_lift_%d_%d" % (b.name, k, n) for n in (0, 1)]
        common = {"Slack": "0", "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": "2", "TextureScale": "1", "Collide": "0", "Dangling": "0", "Breakable": "0",
                  "RopeMaterial": "cable/cable.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
        top = dict(common, targetname=names[0], NextKey=names[1])
        low = dict(common, targetname=names[1], parentname="lc_lift_platform")
        m.b.vmf.point("move_rope", m.fr.at(544, 176 - 10 + 20 * k, TRIM + 140), top, m.b.vis + ": ropes")
        m.b.vmf.point("keyframe_rope", m.fr.at(cu_, cv_, F + 9), low, m.b.vis + ": ropes")
    # the counterweight in its channel against the wall beside the shaft: it falls as the platform rises
    m.det([(644, 234, F, 648, 256, TRIM + 120), (676, 234, F, 680, 256, TRIM + 120)], MAT["bars"])
    m.ent("func_door", {"targetname": "lc_lift_counterweight", "movedir": "90 0 0", "speed": "37", "lip": "-140", "wait": "-1", "spawnflags": "32", "spawnpos": "0",
                        "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                        "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"},
          [(648, 238, TRIM + 40, 676, 254, TRIM + 100)], MAT["beam"])
    m.taken(640, 228, F, 684, 256, TRIM + 124)
    # caged lamps on the frame at each level
    for z in (F + 110, TRIM + 90):
        m.static(P + "props_c17/light_cagelight02_on.mdl", u1 - 4, v1 - 9, 270, z)
        m.light(u1 - 4, v1 - 24, z + 6, "255 210 160 40")
    deck = [(u1, v1, F, u2, v2, F + 8)]
    # unseen rails down each side and across the canal's side (but for a way on 64 wide): they block; the city's
    # handrails ride on them for looks (see below)
    unseen = dict((f, MAT["nodraw"]) for f in FACE_ORDER)
    rails = [((u, v1, F + 8, u + 3, v2, F + 48), unseen) for u in (u1, u2 - 3)] + [((a, v1, F + 8, c, v1 + 3, F + 48), unseen) for a, c in ((u1, u1 + 48), (u2 - 48, u2))]
    stand = [(u2 - 22, v1 + 60, F + 8, u2 - 14, v1 + 68, F + 44), (u2 - 26, v1 + 56, F + 44, u2 - 10, v1 + 72, F + 48)]       # the stand its button sits on
    boxes = [m.fr.box(*x) for x in deck + stand] + [(m.fr.box(*x), f) for x, f in rails]
    high = 48
    m.b.vmf.brush_entity("func_door", {"targetname": "lc_lift_platform", "movedir": "-90 0 0", "speed": "48", "lip": str(high - 256), "wait": "-1", "spawnflags": "32", "spawnpos": "0",
                                        "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "1", "noise1": "plats/elevator_move_loop1.wav",
                                        "noise2": "plats/elevator_stop1.wav", "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255",
                                        "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"},
                           boxes, steel, m.dv, top=MM["wood"])
    b.names.append(("lc_lift_platform", "func_door", m.tag))
    for u in (u1 + 2, u2 - 2):
        for (c, size) in ((128, "medium"), (192, "medium"), (240, "short")):
            rider(m, "lc_lift_platform", P + "props_c17/handrail04_%s.mdl" % size, u, c, 0, F + 8)
    for c in (u1 + 24, u2 - 24):
        rider(m, "lc_lift_platform", P + "props_c17/handrail04_short.mdl", c, v1 + 2, 90, F + 8)
    m.b.vmf.brush_entity("func_button", {"targetname": "lc_lift_button_ride", "parentname": "lc_lift_platform", "spawnflags": "1025", "wait": "2", "speed": "5", "lip": "0",
                                          "movedir": "0 0 0", "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 70 60"},
                           [m.fr.box(u2 - 23, v1 + 59, F + 48, u2 - 13, v1 + 69, F + 52)], steel, m.dv, connections=[("OnPressed", "lc_lift_platform", "Toggle", "", 0), ("OnPressed", "lc_lift_counterweight", "Toggle", "", 0)])
    b.names.append(("lc_lift_button_ride", "func_button", m.tag))
    # the button at the bottom, on a post by the way on; the one at the top, on a post on the dock
    m.det([(u1 - 40, v1 - 24, F, u1 - 24, v1 - 8, F + 56)], MAT["beam"])
    m.button("lc_lift_button_low", u1 - 32, v1 - 24, F + 30, 270, [("lc_lift_platform", "Toggle", "", 0), ("lc_lift_counterweight", "Toggle", "", 0)], wait="2")
    m.det([(u2 + 16, 272, TRIM, u2 + 32, 288, TRIM + 56)], MAT["beam"])
    m.button("lc_lift_button_high", u2 + 24, 288, TRIM + 30, 90, [("lc_lift_platform", "Toggle", "", 0), ("lc_lift_counterweight", "Toggle", "", 0)], wait="2")
    m.taken(432, 200, F, 656, 256, b.rim)
    m.blocked(432, 64, 656, 256)
    # --- the dock: a low wall along its edge (open where the lift comes up), stripes there, the lorry, crates, a lamp ---
    edge = [(320, u1 - 8), (u2 + 8, 768)]
    m.det([(a, 256, TRIM, c, 268, TRIM + 40) for a, c in edge], MAT["canal_wall"])
    m.det([(a, 254, TRIM + 40, c, 270, TRIM + 44) for a, c in edge], MAT["beam"])
    m.det([(u, 258, TRIM, u + 16, 286, TRIM + 1) for u in range(u1 + 8, u2 - 8, 32)], MAT["black"])
    m.static(P + "props_vehicles/van001a_nodoor.mdl", 680, 440, 90, TRIM)          # a van backed up to the lift, its back open
    m.blocked(600, 300, 740, 540)
    for (u, v, z, yaw) in ((380, 440, TRIM + 9, 10), (396, 430, TRIM + 9, 40), (384, 436, TRIM + 33, 80)):
        m.static(P + "items/item_item_crate.mdl", u, v, yaw, z)                      # the Combine's supplies on a pallet
    m.point("prop_dynamic_override", 640, 575, TRIM + 60, {"model": P + "props_lab/clipboard.mdl", "angles": "0 %d 90" % m.fr.yaw(270), "solid": "0",
                                                         "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                                         "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)
    m.decal("decals/decal_posterbreen", 420, 559, TRIM + 70)
    for kind, u, v, z, seed in (("stain", 690, 330, TRIM + 1, 1), ("puddle", 450, 420, TRIM + 1, 2), ("trash", 740, 560, TRIM + 1, 3), ("number", 456, 92, F + 60, 4),
                                ("danger", 662, 233, TRIM + 20, 5), ("stain", 500, 255, F + 150, 6)):
        m.grime(kind, u, v, z, seed)
    m.soundscape(SCAPES["courtyard"], 544, 420, TRIM, radius=400)
    m.soundscape(SCAPES["metal"], 544, 120, F, radius=300)
    canal_grime(m, 16, 420, 5800)
    canal_grime(m, 700, 1010, 5900)
    m.static(P + "props_c17/lamppost03a_on.mdl", 344, 540, 270, TRIM)                # its arm over the dock
    m.light(444, 540, TRIM + 400, "255 214 170 300")
    m.loose(P + "props_junk/wood_crate001a.mdl", 360, 300, 10, z=TRIM)
    m.loose(P + "props_junk/wood_crate001a.mdl", 362, 346, 40, z=TRIM)
    m.loose(P + "props_junk/wood_crate002a.mdl", 410, 310, 90, z=TRIM)
    m.static(P + "props_junk/wood_pallet001a.mdl", 384, 436, 0, TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 740, 290, 0, z=TRIM)
    put(m, P + "props_c17/oildrum001.mdl", 744, 326, 0, z=TRIM)
    put(m, P + "props_debris/concrete_chunk01a.mdl", 400, 60, 40)
    m.loose(P + "props_junk/wood_pallet001a.mdl", 680, 60, 60)
    m.lane(544, 60, F)
    m.lane(544, 330, TRIM)
    m.lane(512, 520, TRIM)
    m.view(300, -70, F, 30, -10, "the lift at the bottom, the dock above")
    m.view(544, 110, F + 8, 90, -32, "from the platform, up")
    m.view(544, 300, TRIM, 100, 4, "the dock: the gate, the van")
    m.view(420, 500, TRIM, 300, 8, "from the back of the dock")
    b.notes.append("%s: the street end is at (%d %d), floor z %d, 128 wide and 128 high: bring a street to it, then delete its gate and cap; the lift's deck rides from z %d to z %d" % (
        (m.tag,) + m.fr.pt(512, 704) + (TRIM, F + 8, F + 264)))


# ---------------------------------------------------------------------------
# barge
# ---------------------------------------------------------------------------

def oblique(pts, shift, mat):
    """A prism that leans: a flat outline of 3D corners, and the same outline moved by shift (du, dv, dz)."""
    far = [(p[0] + shift[0], p[1] + shift[1], p[2] + shift[2]) for p in pts]
    faces = [(list(pts), mat), (far, mat)]
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        faces.append(([pts[i], pts[j], far[j], far[i]], mat))
    return faces


def m_barge(m, opt):
    """The grounded barge. A river barge lies on the canal floor from u 320 to 960, askew (its stern 80 nearer the left
    bank than its bow: sheared in plan, never turned): a steel hull 640 long, 192 wide and 96 high, its sides flaring,
    its bow and stern raked and tapered (no ship model fits a canal: the hull stays brushes). Its face is a vessel's: a
    timber rub rail along the sheer, a band of a second plate at the old waterline, rust streaking down from the
    scuppers, its name painted on the bow (the owner's own ship's sign decal), the anchor's chain run out ahead into the
    mud, tyres hung down both sides for fenders, mud heaped against its sides where it grounded. Forward a wooden pole
    of the docks for a mast with a caged lamp on it, the canal's own winch, cleats; amidships the hold under four hatch
    covers, the second slid back onto the third: a ladder goes down through the gap. The hold (336 by 128, 88 high) is
    somebody's hideout, its floor clear down the middle: two beds forward, a stove with its pipe (the city's pipe pieces)
    up through the deck and a thin smoke from it, a table and chairs to one side, a lamp, a crate (lc_barge_hold). Aft a
    wheelhouse with windows all round, a doorway astern, an instrument console with a radio under the front windows and
    a wooden spoked wheel on its pedestal (lc_barge_wheel). A gangplank runs level from the left bank to the deck. The
    canal stays passable either side of the hull: a strip of floor and the bank. Sounds: the hull's metal groaning
    (coast.util_metalstress), the hold a wooden room's creak (d1_town.WoodBuilding).
    Named for the game: lc_barge_hold (an info_target in the hold), lc_barge_wheel (an info_target at the wheel).
    Left as brushes: the hull, its rub rail and waterline band, decks, bulwarks, hatch coaming and covers, the
    wheelhouse, its console and pedestal, the funnel, the mast's yard, the gangplank (the vessel itself), the mud heaped
    against it.
    Unchecked: that props_wasteland/wheel01 (a cart's wheel: Half-Life 2 has no ship's wheel) reads as a ship's; which
    way the winch and the radio face; the ladder standing free in the hatch (the shared helper's models and dismount
    points); that walls sheared in plan do not snag a player walking the side decks (40 wide); the colour of the
    waterline band (metal/metalwall030a, one of the owner's commonest metals, chosen unseen); that the hung tyres lie
    flat to the flaring sides. Not done: a list to one side (a roll sheared into every brush would not keep their faces
    on the grid)."""
    b = m.b
    steel, wood, tin = HULL, MM["wood"], MM["tin"]
    U0, V0, dk = 320, -136, F + 96
    m.open(0, -256, 1280, 256)
    m.side(320, -160, 960, 160)
    m.blocked(304, -176, 976, 176)

    def P(a, c):
        return (U0 + a, V0 + c + a // 8)

    def sk(a1, c1, z1, a2, c2, z2, mat, top=None):
        u, v = P(a1, c1)
        return para((u, v, z1), (a2 - a1, (a2 - a1) // 8, 0), (0, c2 - c1, 0), (0, 0, z2 - z1), mat, top)
    sh = []
    # --- the hull: flaring sides, a bottom plate, a raked bow and stern, bulkheads ---
    for (c, lean) in ((24, -22), (160, 22)):
        u, v = P(96, c)
        sh.append(para((u, v, F), (480, 60, 0), (0, lean, 88), (0, 8, 0), steel))          # (to the deck's underside)
    # a hull's face: a rub rail along the sheer, a band of a second plate at the old waterline, mud heaped against it
    # where it grounded
    sh += [sk(100, -6, dk - 16, 572, 6, dk - 6, WOODTRIM), sk(100, 186, dk - 16, 572, 198, dk - 6, WOODTRIM)]
    band = "metal/metalwall030a"
    for (c, lean) in ((19, -6), (169, 6)):
        u, v = P(100, c)
        sh.append(para((u, v, F + 20), (472, 59, 0), (0, lean, 24), (0, 4, 0), band))
    mud = DIRT
    for (c_in, c_mid, c_out) in ((24, 17, -40), (168, 175, 232)):
        tri = [P(100, c_in) + (F,), P(100, c_mid) + (F + 30,), P(100, c_out) + (F,)]
        sh.append(oblique(tri, (472, 59, 0), mud))
    sh.append(sk(96, 24, F, 576, 168, F + 8, steel, wood))
    sh.append(frustum([P(24, 78), P(24, 114), P(96, 168), P(96, 24)], [P(0, 72), P(0, 120), P(96, 192), P(96, 0)], F, dk, steel))
    sh.append(frustum([P(576, 24), P(576, 168), P(624, 150), P(624, 42)], [P(576, 0), P(576, 192), P(640, 168), P(640, 24)], F, dk, steel))
    sh += [sk(96, 24, F + 8, 104, 168, dk - 8, steel), sk(440, 24, F + 8, 448, 168, dk - 8, steel), sk(448, 24, F + 8, 576, 168, dk - 8, steel)]
    # --- the deck: fore and aft, a walk down each side of the hold, a low bulwark, the hatch's coaming ---
    sh += [sk(96, 0, dk - 8, 128, 192, dk, steel, wood), sk(416, 0, dk - 8, 576, 192, dk, steel, wood), sk(128, 0, dk - 8, 416, 40, dk, steel, wood), sk(128, 152, dk - 8, 416, 192, dk, steel, wood)]
    sh += [sk(96, 0, dk, 576, 4, dk + 12, steel), sk(96, 188, dk, 456, 192, dk + 12, steel), sk(496, 188, dk, 576, 192, dk + 12, steel)]            # (a gap for the gangplank)
    sh += [sk(128, 40, dk, 416, 46, dk + 8, steel), sk(128, 146, dk, 416, 152, dk + 8, steel), sk(120, 40, dk, 128, 152, dk + 8, steel), sk(416, 40, dk, 424, 152, dk + 8, steel)]
    # the hatch covers: the first, the second slid back on top of the third, the third, the fourth
    sh += [sk(128, 40, dk + 8, 200, 152, dk + 14, tin), sk(272, 40, dk + 8, 344, 152, dk + 14, tin), sk(344, 40, dk + 8, 416, 152, dk + 14, tin), sk(256, 44, dk + 14, 328, 148, dk + 20, tin)]
    sh += [sk(a, 40, dk + 14, a + 4, 152, dk + 16, MAT["bars"]) for a in (160, 376)]
    # --- the wheelhouse: windows all round, a doorway astern, a roof with an overhang ---
    wz = dk
    for c in (40, 146):
        sh += [sk(456, c, wz, 552, c + 6, wz + 40, wood), sk(456, c, wz + 80, 552, c + 6, wz + 96, wood), sk(456, c, wz + 40, 464, c + 6, wz + 80, wood),
               sk(544, c, wz + 40, 552, c + 6, wz + 80, wood), sk(496, c, wz + 40, 504, c + 6, wz + 80, wood)]
    sh += [sk(456, 46, wz, 464, 146, wz + 41, wood), sk(456, 46, wz + 79, 464, 146, wz + 96, wood), sk(456, 92, wz + 41, 464, 100, wz + 79, wood),
           sk(544, 46, wz, 552, 76, wz + 96, wood), sk(544, 116, wz, 552, 146, wz + 96, wood), sk(544, 76, wz + 84, 552, 116, wz + 96, wood),
           sk(448, 32, wz + 96, 560, 160, wz + 102, tin)]
    # the wheel on its pedestal, a bench, the funnel behind the house
    wu, wv = P(480, 96)
    sh.append(sk(472, 90, wz, 480, 102, wz + 34, steel))
    tilted(m, "prop_static", M_ + "props_wasteland/wheel01.mdl", wu + 12, wv, wz + 50, 277)       # the wheel before its pedestal (its middle: set by hand)
    fu, fv = P(568, 96)
    sh.append(vprism([(fu + x, fv + y) for x, y in ring(15)], dk, dk + 150, steel))
    sh.append(vprism([(fu + x, fv + y) for x, y in ring(20)], dk + 120, dk + 132, MAT["black"]))
    m.target("lc_barge_wheel", wu + 22, wv, wz + 8, 180)
    sh.append(sk(458, 54, wz, 468, 138, wz + 34, steel, MM["wood"]))                       # the instrument console under the front windows
    ru, rv = P(462, 120)
    m.static(M_ + "props_lab/citizenradio.mdl", ru, rv, 7, wz + 34)
    # --- forward: bitts, a winch, the mast and its stay ---
    for (a, c) in ((40, 84), (40, 104), (600, 60), (600, 128)):
        u, v = P(a, c)
        m.static(M_ + "props_docks/dock01_cleat01a.mdl", u, v, 7, dk)
    xu, xv = P(72, 96)
    m.static(M_ + "props_canal/winch02.mdl", xu, xv, 7, dk)
    mu, mv = P(112, 96)
    m.static(M_ + "props_docks/dock01_pole01a_256.mdl", mu, mv, 0, F + 8)         # the mast, stepped on the hold's floor through the deck
    m.det([(mu - 2, mv - 30, dk + 146, mu + 2, mv + 30, dk + 150)], WOODTRIM)
    m.rope([(mu, mv, dk + 164), (wu + 20, wv, wz + 104)], slack=30)
    m.rope([(mu, mv, dk + 164), P(8, 96) + (dk + 4,)], slack=6)
    m.static(M_ + "props_c17/light_cagelight02_on.mdl", mu + 9, mv + 1, 7, dk + 110)   # a caged lamp on the mast, looking aft
    m.light(mu + 24, mv + 3, dk + 110, "255 200 140 40")
    m.shapes(sh)
    # --- the gangplank from the left bank, level with the deck ---
    gu = 320 + 476
    m.det([(gu - 20, 112, dk, gu + 20, 236, dk + 5)], wood)
    m.det([(gu - 20, v, dk + 5, gu + 20, v + 3, dk + 7) for v in range(124, 230, 24)], WOODTRIM)
    m.lane(gu, 236, dk)
    m.lane(gu, 140, dk)
    # --- the hold: the ladder down from the first hatch cover, bunks, the stove and its pipe, a table, a lamp ---
    lu, lv = P(200, 96)
    m.shapes([sk(192, 80, F + 8, 200, 112, dk + 8, steel)])
    m.ladder(lu, lv, F + 8, dk + 8, 0)
    for c in (50, 142):                                                     # two beds forward
        bu, bv = P(146, c)
        m.dynamic(M_ + "props_c17/furniturebed001a.mdl", bu, bv, 7, F + 8)
    su, sv = P(408, 56)
    put(m, M_ + "props_c17/furniturestove001a.mdl", su, sv + 4, 187, z=F + 8)
    for k, z in enumerate((F + 74, F + 123, F + 155)):                      # its pipe: three lengths up through the deck, a collar on top
        tilted(m, "prop_static", M_ + "props_pipes/pipe02_straight01_%s.mdl" % ("short" if k == 2 else "long"), su, sv + 8, z, 0, 0, 90)
    tilted(m, "prop_static", M_ + "props_pipes/pipe02_connector01.mdl", su, sv + 4, F + 172, 0, 90, 0)
    tu, tv = P(320, 134)
    put(m, M_ + "props_c17/furnituretable001a.mdl", tu, tv, 7, z=F + 8)
    m.loose(M_ + "props_c17/furniturechair001a.mdl", tu - 40, tv - 4, 7, z=F + 8)
    m.loose(M_ + "props_c17/furniturechair001a.mdl", tu + 40, tv - 2, 187, z=F + 8)
    lu2, lv2 = P(320, 166)
    m.lamp(lu2, lv2, dk - 16, "255 190 120 26")                            # (under the side deck: the hatch covers are higher)
    cu, cv = P(420, 130)
    m.loose(M_ + "props_junk/wood_crate001a.mdl", cu, cv, 10, z=F + 8)
    m.smoke(su, sv + 4, F + 182, size=10, length=160, rate=8)                              # the stove is lit: a thin smoke from its pipe
    put(m, M_ + "props_junk/metalbucket01a.mdl", su - 40, sv, 0, z=F + 8)
    hu, hv = P(280, 80)
    m.target("lc_barge_hold", hu, hv, F + 16, 0)
    # --- round it ---
    put(m, M_ + "props_debris/concrete_chunk01a.mdl", 250, -60, 40)
    m.loose(M_ + "props_vehicles/tire001c_car.mdl", 1010, 70, 0)
    put(m, M_ + "props_c17/oildrum001.mdl", 1030, -40, 0)
    m.loose(M_ + "props_junk/wood_pallet001a.mdl", 270, 90, 30)
    du, dv = P(540, 20)
    nu, nv = P(120, 6)
    m.decal("decals/decalshipsign005d", nu, nv, F + 72)                                     # its name on the bow
    for k, (a, c, z) in enumerate(((200, 6, F + 72), (360, 3, F + 84), (480, 9, F + 60), (240, 186, F + 72), (400, 189, F + 84))):
        su_, sv_ = P(a, c)
        m.grime("stain", su_, sv_, z, k + 1)                                                 # rust down from the scuppers
    bu_, bv_ = P(8, 96)
    m.rope([(bu_, bv_, dk + 2), (bu_ - 96, bv_ - 20, F + 2)], slack=20, width=4)            # the anchor's chain, run out into the mud
    m.b.vmf.ents[-1] = m.b.vmf.ents[-1].replace("cable/cable.vmt", "cable/chain.vmt")
    m.b.vmf.ents[-2] = m.b.vmf.ents[-2].replace("cable/cable.vmt", "cable/chain.vmt")
    for (a, c, out) in ((200, 4, 2), (380, 4, 2), (220, 188, 190), (420, 188, 190)):
        tu_, tv_ = P(a, c)
        ru_, rv_ = P(a, out)
        tilted(m, "prop_dynamic_override", M_ + "props_vehicles/tire001c_car.mdl", tu_, tv_, F + 60, 97, 0, 0)
        m.rope([(ru_, rv_, dk + 12), (tu_, tv_, F + 74)], slack=6)
    for kind, u, v, z, seed in (("puddle", 260, 160, F + 1, 1), ("trash", 1020, -120, F + 1, 2), ("stain", 900, 60, F + 1, 3)):
        m.grime(kind, u, v, z, seed)
    m.soundscape(SCAPES["metal"], 640, 0, F, radius=560)
    m.soundscape(SCAPES["house"], P(300, 96)[0], P(300, 96)[1], F + 8, radius=150)
    m.view(120, 40, F, 355, -8, "the barge, bow on")
    m.view(gu, 232, dk, 262, 12, "from the gangplank")
    m.view(P(110, 150)[0], P(110, 150)[1], dk, 5, 6, "along the deck: the hatch, the wheelhouse")
    m.view(P(230, 96)[0], P(230, 96)[1], F + 8, 0, 4, "in the hold, looking aft")
    m.view(P(420, 96)[0], P(420, 96)[1], F + 8, 180, 4, "in the hold, looking forward: the ladder, the bunks")
    m.view(P(536, 62)[0], P(536, 62)[1], dk, 165, 6, "in the wheelhouse")
    b.notes.append("%s: the deck is at z %d, the hold's floor z %d; the hull lies from u 320 to 960, its stern 80 to the left of its bow" % (m.tag, dk, F + 8))


# ---------------------------------------------------------------------------
# busbridge
# ---------------------------------------------------------------------------

class BusBody:
    """A city bus's body of brushes (no bus model exists in any of the games), lying along v between two u's, sheared
    (its floor rises num/den for every unit of v from (v0, z0)), never turned. It is built as a bus is: a skirt of
    panels to the window line in one colour with an arch over each wheel, a belt strip, window posts and a header in a
    second colour, a roof with rounded edges, a front with its windscreen frame, a grille and the destination board, a
    back with the engine's grille. high: the clear height inside. What is in it (seats, wheels, an axle) is the game's
    own models. (Each layer of a side stands in its own plane, a unit off the next, so no two faces share one.)"""

    def __init__(self, u1, u2, v0, z0, num, den, high, post):
        self.u1, self.u2, self.v0, self.z0, self.num, self.den, self.high, self.post = u1, u2, v0, z0, num, den, high, post
        self.out = []

    def zf(self, v):
        n = (v - self.v0) * self.num
        if n % self.den:
            raise ValueError("the bus's floor is off the grid at v %d" % v)
        return self.z0 + n // self.den

    def piece(self, ua, ub, va, vb, lo, hi, mat):
        self.out.append(prism([(va, self.zf(va) + lo), (vb, self.zf(vb) + lo), (vb, self.zf(vb) + hi), (va, self.zf(va) + hi)], "x", ua, ub, mat))

    def poly(self, ua, ub, pts, mat):
        self.out.append(prism([(v, self.zf(v) + d) for v, d in pts], "x", ua, ub, mat))

    def side(self, s, a, b):
        """The u's of a layer from a to b out of the side's outer line (side 0 at u1, side 1 at u2)."""
        return (self.u1 + a, self.u1 + b) if s == 0 else (self.u2 - b, self.u2 - a)

    def build(self, m, vs, doors=(), wheels=(), lower=None, upper=None):
        """vs: where the window posts stand along v (the first and last are the bus's ends). doors: (side 0 or 1,
        segment) open from the floor. wheels: where along v each axle is (an arch 60 long over it)."""
        u1, u2, high, post = self.u1, self.u2, self.high, self.post
        lower, upper = lower or "metal/metalwall030a", upper or HULL
        a, b = vs[0], vs[-1]
        grille, trim = "metal/metalgrate016a", MAT["bars"]
        self.piece(u1 + 4, u2 - 4, a + 5, b - 5, -8, 0, MM["wood"])                                  # the floor
        for s in (0, 1):
            gaps = [(vs[k], vs[k + 1]) for (sd, k) in doors if sd == s]
            arches = [(c - 30, c + 30) for c in wheels]
            cuts = sorted(gaps + arches)
            at = a
            for (g1, g2) in cuts + [(b, b)]:                                                       # the skirt, to the window line
                if g1 > at:
                    self.piece(*self.side(s, 0, 4), at, g1, -24, 40, lower)
                at = max(at, g2)
            for (c1, c2) in arches:                                                                 # ...arched over the wheels
                self.piece(*self.side(s, 0, 4), c1, c2, 8, 40, lower)
                self.poly(*self.side(s, -1, 3), [(c1, -24), (c1, 8), (c1 + 10, 8)], lower)
                self.poly(*self.side(s, -1, 3), [(c2, -24), (c2 - 10, 8), (c2, 8)], lower)
            at = a + 5
            for (g1, g2) in sorted(gaps) + [(b - 5, b - 5)]:                                        # the belt strip, on the skirt's top
                if g1 > at:
                    self.piece(*self.side(s, -2, 2), at, g1, 40, 46, trim)
                at = max(at, g2)
            self.piece(*self.side(s, 1, 5), a, b, high - 14, high, upper)                          # the header over the windows
            for k, v in enumerate(vs[:-1]):                                                        # the window posts (one closing a door stands inside it)
                closing = (s, k - 1) in doors
                door = (s, k) in doors or closing
                v1_ = v - post if closing else v
                self.piece(*self.side(s, -1, 3), v1_, v1_ + post, 0 if door else 46, high - 14, upper)
            last_door = (s, len(vs) - 2) in doors
            self.piece(*self.side(s, -1, 3), b - post, b, 0 if last_door else 46, high - 14, upper)
        # the roof, its edges rounded down to the sides
        self.piece(u1 + 12, u2 - 12, a, b, high, high + 8, MM["tin"])
        run = (0, b - a, self.zf(b) - self.zf(a))
        z = self.zf(a)
        self.out += [oblique([(u1 - 2, a, z + high), (u1 + 12, a, z + high), (u1 + 12, a, z + high + 8)], run, MM["tin"]),
                     oblique([(u2 + 2, a, z + high), (u2 - 12, a, z + high), (u2 - 12, a, z + high + 8)], run, MM["tin"])]
        # the front: a grille crushed into the floor, the windscreen's frame (its glass gone), the destination board
        f1, f2 = a, a + 5
        self.piece(u1 + 5, u2 - 5, f1, f2, -24, -4, grille)
        self.piece(u1 + 6, u1 + 16, f1, f2, -4, high - 24, upper)
        self.piece(u2 - 16, u2 - 6, f1, f2, -4, high - 24, upper)
        self.piece(u1 + 5, u2 - 5, f1, f2, high - 24, high, upper)
        self.piece(u1 + 26, u2 - 26, f1 - 5, f1, high - 20, high - 6, MAT["black"])      # (v steps of 5 keep the shear on the grid)
        # the back: the engine's grille low down, the rear window's frame over it
        r1, r2 = b - 5, b
        self.piece(u1 + 5, u2 - 5, r1, r2, -24, 16, grille)
        self.piece(u1 + 6, u1 + 16, r1, r2, 16, high - 14, upper)
        self.piece(u2 - 16, u2 - 6, r1, r2, 16, high - 14, upper)
        self.piece(u1 + 5, u2 - 5, r1, r2, high - 14, high, upper)
        m.shapes(self.out)


def m_busbridge(m, opt):
    """The bus. A city bus has gone through the left street's parapet and hangs nose-down from the wall's lip to the
    canal floor: a hollow body of brushes (no bus model exists in any of the games; the trailers are closed boxes),
    sheared (its floor climbs 248 over a run of 310, about 39 degrees), built as a bus is (BusBody): skirt panels in one
    colour to the window line with an arch over each wheel and the truck tyres half hidden in them, a belt strip, window
    posts and a header in a second colour, a roof with rounded edges, a front door and a middle door, its front with the
    windscreen's frame (the glass gone), a grille crushed into the floor and the destination board, its back with the
    engine's grille and the rear window's frame. Inside, the old train's bench seats along its sides tilted with its
    floor, the driver's chair at its foot; its windscreen end is open on the floor at v -54, its luggage spilled out
    there; its back axle is caught on the lip. Climbing through it is a way UP: its back end comes out on a short
    stretch of pavement recessed into the wall at the trim's height (256 by 128, open to the sky, the fence gone, what is
    left of the parapet either side with its rail broken off over the gap, one of the city's street lamps knocked askew
    and dark, a bus stop's sign on its pole and a shelter over its bench, the timetable on the wall), with a street
    doorway behind closed by a cap of the world in its own visgroup ("the bus's street end (delete to join a street)").
    The scrape where it slid is cracked down the wall under the lip. The canal stays passable under the bus's high end by
    the left bank and round its nose on the right. Sounds: metal groaning (coast.util_metalstress), the quiet courtyard
    up on the pavement.
    Named for the game: lc_bus_top (an info_target on the pavement where the bus comes out), lc_bus_street (an
    info_target in the street doorway, facing the canal).
    Left as brushes: the bus's body (no model of one), the pavement, the parapet's stubs, the shelter, the doorway's
    frame, the slabs on the floor.
    Unchecked: that the sheared floor walks well and the tilted seats do not snag a climber; which way
    traincar_seats001 faces; that players fit under the high end (72 clear from v 66 to the bank); the two colours
    (metal/metalwall030a below, metal/metalhull010c above: the owner's own metals, chosen unseen). Each layer of the
    bus's sides stands a unit off the next (so no two faces share a plane): too small to see."""
    b = m.b
    m.open(0, -256, 1024, 256)
    m.open(384, 256, 640, 384, floor=TRIM, mat=MAT["quay_floor"])
    m.low(448, 384, 576, 512, TRIM + 128, floor=TRIM, mat=MAT["quay_floor"])
    m.side(384, 256, 640, 512)
    m.world((448, 448, TRIM, 576, 512, TRIM + 128), MAT["black"], vis="%s: the bus's street end (delete to join a street)" % b.vis)
    b.plan.keep_out.append(m.fr.rect(384, 512, 640, 576))
    m.blocked(448, 384, 576, 512)
    m.target("lc_bus_street", 512, 416, TRIM + 8, 270)
    m.target("lc_bus_top", 512, 300, TRIM + 8, 270)
    m.taken(368, 176, F, 656, 256, b.rim)
    # --- the bus ---
    bus = BusBody(460, 564, -54, F + 8, 4, 5, 104, 5)
    vs = [-54, -4, 46, 96, 146, 196, 246, 256]
    bus.build(m, vs, doors=((0, 0), (0, 3)), wheels=(26, 196))
    slope = math.degrees(math.atan2(4, 5))
    for (u, c, yaw) in ((482, 51, 0), (542, 11, 180), (542, 121, 180)):      # bench seats along its sides, tilted with its floor (none by the doors)
        tilted(m, "prop_static", M_ + "props_trainstation/traincar_seats001.mdl", u, c, bus.zf(c), yaw, 0, round(slope if yaw == 0 else -slope, 1))
    tilted(m, "prop_dynamic_override", M_ + "props_wasteland/controlroom_chair001a.mdl", 548, -43, F + 43, 270, round(slope, 1), 0)    # the driver's
    for c in (26, 196):                                                       # its wheels in their arches, and the back axle caught on the lip
        for u in (464, 560):
            tilted(m, "prop_dynamic_override", M_ + "props_vehicles/tire001b_truck.mdl", u, c, bus.zf(c) - 26, 0)
    tilted(m, "prop_dynamic_override", M_ + "props_vehicles/carparts_axel01a.mdl", 512, 252, TRIM - 8, 90)
    for c in (-4, 96, 196):
        m.lane(512, c, bus.zf(c))
    m.lane(512, -84, F)
    m.lane(512, 280, TRIM)
    m.blocked(432, -96, 592, 256)
    # --- the pavement: the kerb, what is left of the parapet, the lamp knocked askew, the stop's sign, the doorway's frame ---
    m.det([(384, 256, TRIM, 452, 268, TRIM + 40), (572, 256, TRIM, 640, 268, TRIM + 30), (384, 254, TRIM + 40, 440, 270, TRIM + 44)], MAT["canal_wall"])
    m.shapes([para((452, 257, TRIM), (0, 10, 0), (-14, 0, 34), (6, 0, 0), MAT["canal_wall"]), para((572, 257, TRIM), (0, 10, 0), (10, 0, 26), (-6, 0, 0), MAT["canal_wall"]),
              para((330, -30, F), (90, 20, 0), (-10, 50, 0), (0, 0, 12), MAT["canal_wall"]), para((600, 30, F), (60, -24, 0), (12, 44, 30), (0, 0, 12), MAT["canal_wall"])])
    tilted(m, "prop_static", M_ + "props_c17/lamppost03a_off.mdl", 610, 282, TRIM - 2, 0, -17, 5)       # dark, leaning 18 toward where the bus went over
    m.dynamic(M_ + "props_c17/signpole001.mdl", 398, 352, 0, TRIM)
    m.dynamic(M_ + "props_c17/streetsign005c.mdl", 398, 350, 0, TRIM + 84)
    m.det([(428, 368, TRIM, 448, 384, TRIM + 128), (576, 368, TRIM, 596, 384, TRIM + 128), (420, 364, TRIM + 128, 604, 384, TRIM + 152)], MAT["beam"])
    put(m, M_ + "props_trainstation/benchoutdoor01a.mdl", 410, 300, 0, z=TRIM)
    put(m, M_ + "props_trainstation/trashcan_indoor001b.mdl", 618, 350, 0, z=TRIM)
    put(m, M_ + "props_debris/concrete_chunk01a.mdl", 420, -60, 30)
    put(m, M_ + "props_debris/broken_pile001a.mdl", 620, -70, 100)
    m.loose(M_ + "props_debris/concrete_chunk02a.mdl", 380, 60, 60)
    m.loose(M_ + "props_vehicles/tire001c_car.mdl", 640, 110, 0)
    m.light(512, 100, bus.zf(96) + 80, "200 210 230 12")
    # what came down with it: the parapet's rail broken off, the scrape down the wall where it slid, the luggage spilled
    # from its low end; at the top a shelter over the stop's bench, the timetable on the wall
    m.static(M_ + "props_c17/handrail04_brokenlong.mdl", 570, 262, 90, TRIM + 30)
    for kind, u, v, z, seed in (("crack", 470, 255, F + 210, 1), ("stain", 540, 255, F + 180, 2), ("crack", 500, 255, F + 150, 3), ("debris", 520, -90, F + 1, 4),
                                ("poster", 412, 383, TRIM + 64, 5), ("trash", 600, 330, TRIM + 1, 6), ("stain", 430, 290, TRIM + 1, 7)):
        m.grime(kind, u, v, z, seed)
    m.loose(M_ + "props_c17/suitcase001a.mdl", 470, -96, 20)
    m.loose(M_ + "props_c17/suitcase001a.mdl", 556, -110, 75)
    m.loose(M_ + "props_c17/briefcase001a.mdl", 520, -130, 140)
    m.det([(386, 272, TRIM, 390, 276, TRIM + 96), (386, 330, TRIM, 390, 334, TRIM + 96), (436, 272, TRIM, 440, 276, TRIM + 96), (436, 330, TRIM, 440, 334, TRIM + 96)], MAT["bars"])
    m.det([(384, 268, TRIM + 96, 444, 338, TRIM + 100)], MM["tin"])
    m.soundscape(SCAPES["metal"], 512, 80, F, radius=420)
    m.soundscape(SCAPES["courtyard"], 512, 320, TRIM, radius=260)
    canal_grime(m, 16, 400, 6000)
    canal_grime(m, 700, 1010, 6100)
    m.view(250, -110, F, 30, -12, "the bus from the canal")
    m.view(512, -50, F + 8, 90, -32, "up through it")
    m.view(512, 292, TRIM, 90, 4, "out at the top: the pavement, the street doorway")
    m.view(420, 340, TRIM, 300, 16, "from the pavement, down")
    m.view(800, 60, F, 165, -14, "from the far side")
    b.notes.append("%s: the street end is at (%d %d), floor z %d, 128 wide and 128 high: bring a street to it, then delete its cap; the bus's floor climbs from z %d at v -54 to z %d at v 256" % (
        (m.tag,) + m.fr.pt(512, 512) + (TRIM, F + 8, TRIM)))


# ---------------------------------------------------------------------------
# shell
# ---------------------------------------------------------------------------

def m_shell(m, opt):
    """The shell. A headcrab canister has come down in the canal: the game's own (headcrabcannister01b, shown
    opened, as the game leaves one that has landed) stands out of the right bank where it struck, nose buried, leaning
    back the way it came at about 55 degrees, in a crater: a ring of mud raised on the floor, rocks thrown up on the
    bank, the bank scorched and littered round it. Steam vents from its open end, it spits a spark now and then, a small
    fire burns on the bank, a thread of smoke rises from the crater and the trail it came down on drifts off in the sky
    the way it came. The wall above it is cracked from the bank to the trim (painted cracks, the owner's own plaster
    decals) and a piece of its face lies on the bank. Round it the beginnings of an infestation: seven low fleshy mounds
    (one func_brush tinted dark red, lc_shell_growth, so the game can take them away), torn flesh on them and a sick
    yellow glow that swells slowly over three (a sprite, no light), a faint sick-green light that does not flicker. What
    came out of it lies dead: two headcrabs, a zombie's torso, and the people it got (three bodies, blood). The Combine
    came, lost a Civil Protection officer (lying by the far end), and shut the canal: two of their short barricades and
    a police line across it at the far end, a danger sign on the wall. It sounds of slime (canals_slime_tunnel). No
    living creatures: the game brings its own (the four patches).
    Named for the game: lc_shell_canister (an info_target at the shell's open end), lc_shell_patch_1 to _4
    (info_targets on the floor round it, where the game may put infestation patches and headcrabs), lc_shell_growth
    (a func_brush: the mounds; Disable removes them).
    Left as brushes: the growth mounds (no model of flesh exists in the games; the game takes them away by name), the
    piece of the wall's face on the bank.
    Unchecked: that the canister shows opened with DefaultAnim idle_open and which end is its nose (taken to be +x,
    where its trail is not); that a func_brush takes the dark red tint (rendercolor) on plaster and the flesh decals on
    it; models/humans/corpse1, headcrabclassic, zombie/classic_torso and police as ragdolls lying where put; how high
    the mud ring comes out (it is the mud's displaced skin, raised up to 34); the env_steam and the drifting
    env_smokestack's keys (Half-Life 2's own entities, not read from the owner's map); that the slow pulse of the
    growth's glow (renderfx 1) is not taken for a flicker."""
    b = m.b
    cmb = "metal/metalcombine002"
    m.open(0, -256, 1024, 256)
    cu, cv = 470, -206                                 # where its nose went in (inside the bank)
    m.taken(360, -256, F, 680, -200, b.rim)
    # --- the shell: its axis climbs 2 for every 1 along u and 1 along v ---
    def at(z):
        d = (z - (F + 20)) // 2
        return cu + d, cv + d

    def oct_at(z, r):
        u, v = at(z)
        return [(u + x, v + y) for x, y in ring(r, (r * 5) // 12)]

    def tube(z1, z2, r, mat):
        lo, hi = oct_at(z1, r), oct_at(z2, r)
        faces = [([p + (z1,) for p in lo], mat), ([p + (z2,) for p in hi], mat)]
        for i in range(8):
            j = (i + 1) % 8
            faces.append(([lo[i] + (z1,), lo[j] + (z1,), hi[j] + (z2,), hi[i] + (z2,)], mat))
        return faces
    # the game's canister along that axis, nose (+x) down into the bank at (cu + 12, cv + 12): its origin 94 back from its nose's tip
    top = F + 143
    tilted(m, "prop_dynamic", M_ + "props_combine/headcrabcannister01b.mdl", cu + 50, cv + 50, F + 97, 225, 55, 0, {"DefaultAnim": "idle_open"})
    eu, ev = cu + 73, cv + 73
    m.target("lc_shell_canister", eu, ev, top + 12, 45)
    # --- the crater: mud thrown up in a ring on the floor, clods of earth on the bank ---
    kx, ky = m.fr.pt(cu + 30, cv + 90)
    m.b.bumps.append(lambda x, y: 34 * max(0.0, 1 - abs(math.hypot(x - kx, y - ky) - 110) / 70.0) ** 1.2)
    for k, (u, v, yaw) in enumerate(((400, -180, 20), (560, -224, 140), (452, -130, 75), (580, -150, 200), (380, -236, 310), (630, -200, 250))):
        z = F + max(0, -128 - v)                                             # (the bank's face there: each rock sunk into it, deeper on the slope)
        m.static(M_ + "props_wasteland/rockgranite03%s.mdl" % "ab"[k % 2], u, v, yaw, z - (12 if z > F + 8 else 5))
    m.smoke(cu + 16, cv + 30, F + 70, colour="70 80 60", size=14, length=160, rate=8)
    # the shell as the game shows one that has landed: steam from its open end, sparks now and then, a fire on the bank,
    # the trail it left drifting off the way it came
    m.point("env_steam", eu, ev, top + 6, {"InitialState": "1", "type": "0", "SpreadSpeed": "12", "Speed": "90", "StartSize": "8", "EndSize": "28", "Rate": "24",
                                           "rendercolor": "235 240 235", "JetLength": "70", "renderamt": "200", "angles": "-60 %d 0" % m.fr.yaw(45)})
    m.spark(eu - 6, ev - 6, top)
    from map_mods_b import fire
    fire(m, 420, -170, F + 42, 16, "255 150 70 60")
    m.point("env_smokestack", cu + 60, cv + 60, top + 40, {"InitialState": "1", "BaseSpread": "10", "SpreadSpeed": "6", "Speed": "40", "StartSize": "20", "EndSize": "70",
                                                           "Rate": "6", "JetLength": "420", "WindAngle": "0 %d 0" % m.fr.yaw(45), "WindSpeed": "30",
                                                           "SmokeMaterial": "particle/SmokeStack.vmt", "twist": "2", "roll": "2", "rendercolor": "90 90 90",
                                                           "renderamt": "90", "angles": "0 0 0"})
    # --- the wall above it, cracked ---
    for k, (du, z) in enumerate(((-6, F + 140), (8, F + 176), (-2, F + 212), (20, F + 240), (44, F + 200), (-30, F + 160))):
        m.decal("decals/plaster%03da" % (13, 16, 13, 16, 13, 16)[k], cu + du, -256, z)
    for k, (u, v) in enumerate(((420, -180), (540, -200), (600, -160), (470, -150))):
        m.grime("burn" if k % 2 == 0 else "debris", u, v, F + (-128 - v), k + 1)            # scorched and littered round the impact (on the bank's slope)
    m.shapes([para((cu + 40, -250, F + 124), (50, 0, 6), (0, 20, -14), (0, 0, 10), MAT["canal_wall"])])                 # a piece of the wall's face, down on the bank
    # --- the growth: low mounds in three tiers, one tinted func_brush ---
    mounds = []
    for (u, v, r) in ((560, -60, 34), (430, -40, 28), (620, -130, 24), (500, 30, 22), (350, -110, 26), (690, -30, 20), (590, 60, 18)):
        z = F + max(0, -128 - v)
        mounds += [(u - r, v - r + 4, z, u + r, v + r - 4, z + 7), (u - (2 * r) // 3, v - (2 * r) // 3, z + 7, u + (2 * r) // 3 - 4, v + (2 * r) // 3, z + 13),
                   (u - r // 3 - 2, v - r // 3, z + 13, u + r // 3, v + r // 3 + 2, z + 18)]
    m.ent("func_brush", {"targetname": "lc_shell_growth", "Solidity": "0", "StartDisabled": "0", "solidbsp": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "112 30 26",
                         "renderfx": "0", "spawnflags": "2", "disableshadows": "1", "vrad_brush_cast_shadows": "0"}, mounds, PLASTER)
    for k, (u, v) in enumerate(((600, -20), (410, -90), (520, 80), (700, -100))):
        m.target("lc_shell_patch_%d" % (k + 1), u, v, F + 8, 90 * k)
    for (u, v, yaw) in ((650, 40, 30), (380, 20, 200), (540, -110, 120)):
        m.body(M_ + "humans/corpse1.mdl", u, v, yaw)
    for k, (u, v, r) in enumerate(((560, -60, 34), (430, -40, 28), (500, 30, 22))):
        z = F + max(0, -128 - v)
        m.decal("decals/alienflesh/shot%d" % (k + 1), u, v, z + 18)
        m.point("env_sprite", u, v, z + 24, {"model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "120", "rendercolor": "190 220 60", "scale": "0.18",
                                             "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0", "renderfx": "1", "spawnflags": "1"}, m.lv)
    m.body(M_ + "headcrabclassic.mdl", 470, 120, 40)                                  # what came out of it, and what it did
    m.body(M_ + "headcrabclassic.mdl", 760, -60, 200)
    m.body(M_ + "zombie/classic_torso.mdl", 300, -40, 300)
    m.body(M_ + "police.mdl", 880, 70, 160)                                          # the Combine came, and lost one; then they shut the canal
    for v in (-70, 70):
        m.static(M_ + "props_combine/combine_barricade_short01a.mdl", 900, v, 0, F)
    m.grime("police", 900, 0, F + 1, 1)
    m.grime("danger", 900, -256, F + 170, 2)
    for k, (u, v) in enumerate(((440, 100), (380, 60), (780, -40))):
        m.decal("decals/blood%d" % (k + 1), u, v, F + 1)
    m.soundscape(SCAPES["slime"], 520, -60, F, radius=520)
    canal_grime(m, 16, 300, 6200)
    m.light(cu + 60, cv + 110, F + 90, "150 220 110 45")
    m.light(eu, ev, top + 30, "150 220 110 18")
    put(m, M_ + "props_debris/concrete_chunk01a.mdl", 640, -180, 40, z=F + 52)
    m.loose(M_ + "props_debris/concrete_chunk02a.mdl", 450, 90, 10)
    m.loose(M_ + "props_junk/wood_crate001a.mdl", 330, 60, 30)
    m.blocked(320, -256, 704, -32)
    m.lane(512, 120, F)
    m.view(200, 40, F, 335, -6, "the shell in the bank")
    m.view(520, 110, F, 270, -4, "from across the canal: the crater, the crack")
    m.view(700, -40, F, 200, -8, "from beyond it: the growth, the dead")
    b.notes.append("%s: the shell's nose is in the right bank at (%d %d), its open end at z %d" % ((m.tag,) + m.fr.at(cu, cv, top)))


# ---------------------------------------------------------------------------
# aqueduct
# ---------------------------------------------------------------------------

def m_aqueduct(m, opt):
    """The aqueduct. A smaller channel crosses OVER the canal at the trim's height: a concrete trough 112 wide on two
    piers, ribbed under its belly, pilasters down its far side every 64, a coping of the city's trim stone along both
    rims, from a culvert mouth in the left wall to one in the right, each shut by the canal's own bars: behind the bars a
    lit stretch of culvert, the trough's water flowing on into it, dark where it goes on. 24 of standing water in it.
    Along its entry side runs a maintenance walk 48 wide (the trough's rim and a grating on brackets) with the city's
    handrail on its outer edge: a ladder climbs the left pier's buttress to it (256 up), and from it the whole canal can
    be watched, or crossed up high from bank to bank (the walk ends at each wall; the way down is the ladder or a drop to
    a bank). It is lit from below: a caged lamp on each pier and a lamp washing each side of the trough. At mid-span the
    trough is cracked (painted cracks): its water stains and greens its sides, falls in a thin stream onto the canal
    floor, and lies there in a shallow pool in a ring of mud, with a dripping sound. A sluice valve stands on the trough's
    rim by the left wall. It sounds of water (prison.watery_hallway).
    Named for the game: lc_aqueduct_walk (an info_target on the walk at mid-span: a lookout's place).
    Left as brushes: the trough, its piers, ribs, pilasters, coping and buttress, the culverts' frames, the grating and
    its brackets.
    Unchecked: which way canal_bars004 faces; the sound ambient/water/drip_loop1.wav (if it is not there, the place is
    silent); water standing in a trough of detail brushes; the pool, a sheet of water 5 deep lying on the floor; the
    ladder against a buttress; that a thin env_steam pointed down reads as falling water (Half-Life 2 has no falling
    water material). Not done: the valve draining the trough to open a way along it (a route the game would have to
    want)."""
    b = m.b
    top, bed = TRIM, TRIM - 32
    con = MAT["beam"]
    m.open(0, -256, 1024, 256)
    for s in (1, -1):
        v1, v2 = (256, 320) if s > 0 else (-320, -256)
        c1, c2 = (256, 448) if s > 0 else (-448, -256)
        m.low(448, c1, 576, c2, bed + 112, floor=bed)                      # (as high as the canal's bars that shut it; on a way into the wall)
        m.side(448, c1, 576, c2)
        m.static(M_ + "props_canal/canal_bars004.mdl", 512, 264 * s, 90, bed)
        clip(m, (448, 272 if s > 0 else -274, bed, 576, 274 if s > 0 else -272, bed + 112))
        m.det([(448, 444 if s > 0 else -448, bed, 576, 448 if s > 0 else -444, bed + 112)], MAT["black"])         # where it goes on, dark
        m.water(448, 264 if s > 0 else -444, 576, 444 if s > 0 else -264, bed - 8, top - 8)
        m.static(M_ + "props_c17/light_cagelight02_on.mdl", 512, 444 * s - 1 * s, 270 if s > 0 else 90, bed + 70)
        m.light(512, 420 * s, bed + 80, "200 220 210 30")
        m.grime("stain", 449, 380 * s, bed + 60, 3 + s)
        m.det([(440, 248 if s > 0 else -256, bed - 16, 449, 256 if s > 0 else -248, bed + 112), (575, 248 if s > 0 else -256, bed - 16, 584, 256 if s > 0 else -248, bed + 112),
               (440, 248 if s > 0 else -256, bed + 112, 584, 256 if s > 0 else -248, bed + 120)], con)
        m.blocked(448, c1, 576, c2)
        m.taken(416, 192 if s > 0 else -256, F, 608, 256 if s > 0 else -192, b.rim)
    # --- the trough, its piers and their caps ---
    m.det([(464, -256, bed - 16, 576, 256, bed), (464, -256, bed, 480, 256, top), (560, -256, bed, 576, 256, top)], con)
    for v in (96, -160):
        m.det([(464, v, F, 576, v + 64, bed - 32), (456, v - 8, bed - 32, 584, v + 72, bed - 16)], con)
        m.blocked(432, v - 16, 608, v + 80)
    m.water(480, -256, 560, 256, bed, top - 8)
    # ribs under the trough, pilasters down its far side every 64, a coping of the city's trim stone along both rims
    m.det([(464, v, bed - 28, 576, v + 12, bed - 16) for v in (-250, -40, 28, 238)], con)
    m.det([(576, v, bed - 16, 580, v + 8, top - 1) for v in range(-228, 229, 64)], con)
    m.det([(462, -238, top, 482, 238, top + 4), (558, -238, top, 581, 238, top + 4)], "stone/stonewall050f")
    # light under it: a caged lamp on each pier, a lamp washing each side of the trough from below
    for (v, u, out) in ((128, 463, 180), (-128, 577, 0)):
        m.static(M_ + "props_c17/light_cagelight02_on.mdl", u, v, out, F + 150)
        m.light(u - 14 if out == 180 else u + 14, v, F + 156, "255 210 160 45")
    m.spot(380, 0, F + 30, "220 225 210 120", 0, -40, 50)
    m.spot(660, 0, F + 30, "220 225 210 120", 180, -40, 50)
    # --- the walk: a grating on brackets beside the trough's rim, a rail (a gap where the ladder comes up) ---
    m.det([(432, -256, top - 4, 464, 256, top)], "metal/metalgrate013a")
    m.shapes([prism([(464, top - 4), (434, top - 4), (464, top - 40)], "y", v, v + 4, MAT["bars"]) for v in range(-240, 241, 96)])
    for (c, size) in ((-192, "long"), (-64, "long"), (32, "medium"), (88, "short"), (176, "medium"), (232, "short")):      # (a gap where the ladder comes up)
        m.static(M_ + "props_c17/handrail04_%s.mdl" % size, 433, c, 0, top)
    # the ladder up the left pier's buttress
    m.det([(432, 112, F, 464, 144, top - 4)], con)
    m.ladder(432, 128, F, top, 180)
    m.target("lc_aqueduct_walk", 456, 0, top + 8, 180)
    m.lane(456, 128, top)
    m.lane(456, -128, top)
    m.lane(380, 128, F)
    # --- the crack at mid-span: a stain down the trough's side, a broken lip, the pool under it in a ring of mud ---
    for k, (u, v, z) in enumerate(((464, -6, top - 20), (464, 10, bed + 10), (580, 0, top - 24), (580, -12, bed + 4))):
        m.decal("decals/plaster%03da" % (13, 16)[k % 2], u, v, z)
    for k, (u, v, z) in enumerate(((464, 4, bed - 4), (580, -4, bed - 8), (464, -30, bed + 8))):
        m.grime("stain", u, v, z, 10 + k)                                                  # the water's stain and the algae down its sides
    m.point("env_steam", 528, 0, bed - 20, {"InitialState": "1", "type": "0", "SpreadSpeed": "2", "Speed": "120", "StartSize": "3", "EndSize": "6", "Rate": "40",
                                           "rendercolor": "200 215 225", "JetLength": "200", "renderamt": "120", "angles": "90 0 0"})      # a thin fall of water
    m.water(432, -64, 624, 64, F, F + 5)
    px, py = m.fr.pt(528, 0)
    m.b.bumps.append(lambda x, y: 16 * max(0.0, 1 - abs(math.hypot(x - px, y - py) - 120) / 56.0))
    m.sound("ambient/water/drip_loop1.wav", 528, 0, F + 40, radius=700, volume=5)
    m.soundscape(SCAPES["watery"], 528, 0, F, radius=560)
    canal_grime(m, 16, 400, 6300)
    canal_grime(m, 650, 1010, 6400)
    m.static(M_ + "props_pipes/valve002.mdl", 568, 204, 90, top)                # a sluice valve on the trough's rim by the left wall
    put(m, M_ + "props_debris/concrete_chunk01a.mdl", 620, -40, 30)
    m.loose(M_ + "props_junk/metalbucket01a.mdl", 440, 40, 0, z=top)
    put(m, M_ + "props_c17/oildrum001.mdl", 400, 180, 0)
    m.view(200, -20, F, 5, -14, "the aqueduct")
    m.view(390, 128, F, 0, -34, "the ladder up the pier")
    m.view(448, 230, top, 270, 8, "along the walk")
    m.view(448, 0, top, 180, 18, "from the walk, the way people come")
    m.view(760, 40, F, 185, -6, "from beyond: the crack, the pool")
    b.notes.append("%s: the trough's walk is at z %d, its water at z %d; the pool under the crack is at the canal's middle" % (m.tag, top, top - 8))


# ---------------------------------------------------------------------------
# pipes
# ---------------------------------------------------------------------------

def m_pipes(m, opt):
    """The pipes. A tangle of the city's service mains fills a stretch of the canal: steel pipes 87 across (solid,
    eight-sided, in the owner's own pipe steel), a flange every 128, every end shut by a bolted plate, stencilled
    numbers on their sides.
    On the floor: one main lies across the whole floor at u 480 with 54 under it, and the fat main along the left side
    has 66 under it: everyone on the floor ducks once. Past it two mains on the floor (86 high, too high to hop) make a
    chicane: the first reaches from under the main to v -30 (go round its end on the right), the second from the right
    wall to v -31 (go round on the left, by the main). A run of the city's pipes crosses high overhead.
    Over the top: a steel service stair (grating treads on two stringers, the city's rail on its open side; u 96 to
    324, by the left side) up to a valve platform 152 over the floor, with a valve, a gas meter and a lamp; from it a
    plank 32 wide with the city's handrail runs along the top of the main (u 428 to 878); a grating bridge, railed,
    crosses the canal there to a second fat main on the right, and from its end a ramp of planks (144 down over 244)
    comes back to the floor at u 1192. That is also the only way for anyone who cannot duck.
    Two steam leaks on the main: a pale one with a hiss, and one at a joint by the bridge (lc_pipes_leak) that the
    button by the platform's valve shuts and opens again (lc_pipes_valve). Risers of the city's pipe up the walls, each
    with a caged lamp. The mains are cover from end to end, and the plank is a firing step over all of it
    (lc_pipes_top). It hums like a pump room (d1_canals.waterpuzzleroom).
    Named for the game: lc_pipes_top (an info_target on the main's plank), lc_pipes_leak (an env_steam: TurnOn,
    TurnOff, Toggle; it starts on), lc_pipes_valve (a func_button that already works: it toggles the leak).
    Left as brushes: the mains, their flanges and end plates (no pipe model of the game is 87 across), the saddles and
    posts they rest on, the platform's deck and posts, the stair's treads and stringers, the bridge's grating and
    girders, the planks.
    Unchecked: the sound ambient/gas/steam_loop1.wav; that 54 and 66 of headroom pass a crouched player easily; that
    the 86-high mains cannot be hopped; what pipeset32d_512_001a looks like overhead; where handrail04_doublerise's
    posts meet the treads; the button's model is Episode Two's (the shared helper's choice). The leak does no harm:
    the game can add a hurt to it if it wants the valve to matter."""
    b = m.b
    pm, steel, wood = MAT["bars"], HULL, MM["wood"]
    top = F + 152
    main = "metal/metalpipe003a"                     # (the owner's own pipe steel)
    m.open(0, -256, 1280, 256)
    plates = []

    def run(axis, at, z, a, n, kinds=None):
        """A steel main 87 across (an eight-sided pipe of brushes, as long as n of the old sections, 113 each) along
        axis ("u" or "v") at `at` across it, its middle z, from a: a flange every 128 and a stencilled number."""
        b_ = int(round(a + 112.6 * n))
        ax = "x" if axis == "u" else "y"
        plates.append(prism(octagon(at, z, 42), ax, a, b_, main))
        for f in range(a + 64, b_ - 32, 128):
            plates.append(prism(octagon(at, z, 46), ax, f, f + 6, MAT["bars"]))
        mid = (a + b_) // 2 + 20
        m.grime("number", mid if axis == "u" else at - 42, at - 42 if axis == "u" else mid, z, a)
        return b_

    def plate(axis, at, z, e, way):
        """A bolted steel plate shutting a section's end at e (way: which side of e it lies, +1 or -1)."""
        a, c = (e, e + 4) if way > 0 else (e - 4, e)
        plates.append(prism(octagon(at, z, 46), "x" if axis == "u" else "y", a, c, steel))
    # --- the over route: steps, the valve platform, the main with its plank, the bridge, the second pipe, the ramp ---
    treads = []
    for i in range(10):
        ua_, ub_ = 96 + 228 * i // 10, 96 + 228 * (i + 1) // 10
        z = F + 152 * (i + 1) // 10
        treads.append((ua_, 76, z - 4, ub_ + 2 if i < 9 else ub_, 124, z))
    m.det(treads, "metal/metalgrate013a")
    m.shapes([para((96, 72, F - 20), (228, 0, 152), (0, 4, 0), (0, 0, 22), MAT["bars"]), para((96, 124, F - 20), (228, 0, 152), (0, 4, 0), (0, 0, 22), MAT["bars"])])
    tilted(m, "prop_static", M_ + "props_c17/handrail04_doublerise.mdl", 210, 71, F + 112, 270)          # the city's stair rail on its open side
    m.det([(324, 72, top - 6, 427, 184, top)], "metal/metalgrate013a")
    m.det([(u, v, F + (64 if v > 128 else 0), u + 6, v + 6, top - 12) for u in (324, 421) for v in (72, 178)] + [(324, 72, top - 12, 427, 78, top - 6), (324, 178, top - 12, 427, 184, top - 6)], pm)
    m.static(M_ + "props_c17/handrail04_medium.mdl", 356, 73, 270, top)            # its rails, on the open sides
    m.static(M_ + "props_c17/handrail04_short.mdl", 406, 73, 270, top)
    m.static(M_ + "props_c17/handrail04_medium.mdl", 325, 156, 0, top)
    m.static(M_ + "props_pipes/valve002.mdl", 396, 166, 270, top)                  # the valve, the gas meter
    m.static(M_ + "props_c17/gasmeter001a.mdl", 356, 176, 270, top)
    m.det([(374, 180, top, 378, 184, top + 114), (374, 150, top + 114, 378, 184, top + 118)], pm)          # the lamp's post and arm
    m.lamp(376, 154, top + 100, "255 205 150 50", hang=14)
    e = run("u", 126, F + 108, 428, 4)                                             # the main
    plate("u", 126, F + 108, 428, -1)
    plate("u", 126, F + 108, e, 1)
    m.det([(428, 110, top, 880, 142, top + 4)], wood)
    for (c, size) in ((492, "long"), (620, "long"), (748, "long"), (846, "medium")):
        m.static(M_ + "props_c17/handrail04_%s.mdl" % size, c, 141, 270, top + 4)
    m.det([(520, 86, F, 544, 166, F + 65), (780, 86, F, 804, 166, F + 65)], MAT["beam"])                       # saddles
    m.det([(832, -128, top - 4, 880, 128, top)], "metal/metalgrate013a")
    m.det([(832, -128, top - 12, 836, 128, top - 4), (876, -128, top - 12, 880, 128, top - 4), (852, -4, F, 860, 4, top - 18), (840, -6, top - 18, 872, 6, top - 12)], pm)
    for u in (833, 879):
        for c in (-64, 64):
            m.static(M_ + "props_c17/handrail04_long.mdl", u, c, 0, top)
    e = run("u", -136, F + 108, 831, 1, "b")                                       # the second fat pipe
    plate("u", -136, F + 108, 831, -1)
    plate("u", -136, F + 108, e, 1)
    m.det([(832, -152, top, 944, -120, top + 4)], wood)
    m.det([(880, -176, F, 904, -96, F + 65)], MAT["beam"])
    m.shapes([prism([(948, top + 4), (1192, F + 12), (1192, F + 6), (948, top - 2)], "y", -152, -137, wood),
              prism([(948, top + 4), (1192, F + 12), (1192, F + 6), (948, top - 2)], "y", -135, -120, wood)])
    m.det([(1080, -150, F, 1088, -122, F + 76), (1140, -150, F, 1148, -122, F + 40)], WOODTRIM)
    m.target("lc_pipes_top", 660, 126, top + 12, 0)
    # --- on the floor: the pipe to duck under, the chicane's two ---
    e = run("v", 480, F + 96, -256, 3)
    plate("v", 480, F + 96, e, 1)
    m.det([(460, -200, F, 500, -176, F + 54)], MAT["beam"])
    e = run("v", 640, F + 44, -30, 1, "c")
    plate("v", 640, F + 44, -30, -1)
    plate("v", 640, F + 44, e, 1)
    e = run("v", 760, F + 44, -256, 2, "da")
    plate("v", 760, F + 44, e, 1)
    m.shapes(plates)
    # --- overhead and up the walls ---
    m.static(M_ + "props_pipes/pipeset32d_512_001a.mdl", 1104, 0, 90, F + 176)
    for v in (-248, 232):
        m.det([(1088, v, F + 150, 1120, v + 16, F + 176)], MAT["beam"])
    for (u, s) in ((200, 1), (640, 1), (760, -1), (1010, -1)):              # risers: three lengths each from the bank to over the walls' top
        for k in range(3):
            tilted(m, "prop_static", M_ + "props_pipes/pipe03_straight01_long.mdl", u - 8 * s, 246 * s, b.rim + 6 - 48 - 96 * k, 90 if s > 0 else 270, 0, 90)
    m.taken(176, 200, F, 1040, 256, b.rim)
    m.taken(440, -256, F, 1040, -200, b.rim)
    m.taken(1072, -256, F + 140, 1136, 256, F + 250)
    # --- the leak, odds and ends ---
    m.smoke(566, 84, F + 100, colour="215 215 215", size=7, length=70, rate=10)
    m.sound("ambient/gas/steam_loop1.wav", 566, 84, F + 100, radius=600, volume=4)
    # a second leak, at a joint in the main by the bridge, that the valve on the platform shuts and opens again
    m.point("env_steam", 812, 84, F + 112, {"targetname": "lc_pipes_leak", "InitialState": "1", "type": "0", "SpreadSpeed": "15", "Speed": "110", "StartSize": "10",
                                            "EndSize": "30", "Rate": "30", "rendercolor": "225 225 225", "JetLength": "90", "renderamt": "200",
                                            "angles": "0 %d 0" % m.fr.yaw(270)})
    m.button("lc_pipes_valve", 392, 183, top + 30, 270, [("lc_pipes_leak", "Toggle", "", 0)])
    m.static(M_ + "props_pipes/valvewheel001.mdl", 812, 168, 90, F + 108)                 # the joint's valve wheel
    for (u, sd) in ((200, 1), (640, 1), (760, -1), (1010, -1)):                            # caged lamps on the risers
        m.static(M_ + "props_c17/light_cagelight02_on.mdl", u + 14, 255 * sd, 270 if sd > 0 else 90, F + 200)
        m.light(u + 14, 240 * sd, F + 206, "255 210 160 40")
    m.soundscape(SCAPES["pump"], 640, 0, F, radius=700)
    canal_grime(m, 16, 90, 6500)
    canal_grime(m, 1210, 1270, 6600)
    put(m, M_ + "props_c17/oildrum001.mdl", 700, -90, 0)
    m.loose(M_ + "props_junk/wood_crate001a.mdl", 560, -80, 20)
    m.loose(M_ + "props_junk/metalbucket01a.mdl", 400, 100, 0, z=top)
    put(m, M_ + "props_c17/oildrum001.mdl", 1000, 60, 0)
    m.loose(M_ + "props_junk/wood_pallet001a.mdl", 900, 30, 40)
    # --- for path nodes: nothing that walks upright gets along the floor past u 480; the way is over ---
    m.blocked(96, 64, 440, 192)
    m.blocked(436, -256, 524, 256)
    m.blocked(596, -48, 684, 256)
    m.blocked(716, -256, 804, 48)
    m.blocked(832, -24, 880, 24)
    m.blocked(944, -200, 1200, -96)
    for (u, v, z) in ((70, 100, F), (200, 100, F + 72), (376, 120, top), (500, 126, top + 4), (700, 126, top + 4), (856, 126, top + 4), (856, 0, top), (856, -136, top + 4), (930, -136, top + 4),
                      (1084, -136, F + 80), (1210, -136, F)):
        m.lane(u, v, z)
    m.view(60, -60, F, 10, -10, "the pipes, the steps up")
    m.view(400, -20, F, 0, 0, "the pipe to duck under")
    m.view(560, -90, F, 20, 4, "the chicane")
    m.view(376, 100, top, 0, 6, "from the valve platform, along the main")
    m.view(856, 100, top, 250, 14, "the bridge, the second pipe, the ramp")
    m.view(1230, 0, F, 180, -10, "looking back")
    b.notes.append("%s: the plank along the main is at z %d; under the duck pipe %d, under the main %d" % (m.tag, top + 4, 52, 64))


# ---------------------------------------------------------------------------
# camp
# ---------------------------------------------------------------------------

def tent(m, u1, v1, z, L, W, H, along, open_end, mat, mat_floor, guy=30):
    """A ridge tent of brushes: two sheared sides meeting at a ridge H up, a closed back, two flaps at its open end
    (a way in 44 wide: crouch), a mat inside, a pole and two guy ropes at its back. (u1, v1): its low corner; L: its
    length along `along` ("u" or "v"); W: its width; open_end: "lo" or "hi". Returns the middle of its floor."""
    def pt(a, c):
        return (u1 + a, v1 + c) if along == "u" else (u1 + c, v1 + a)

    def vec(a, c, dz):
        return (a, c, dz) if along == "u" else (c, a, dz)
    half = W // 2
    back, front = (0, L) if open_end == "hi" else (L, 0)
    sh = [para(pt(1, 0) + (z,), vec(L - 2, 0, 0), vec(0, half, H), (0, 0, 3), mat), para(pt(2, W) + (z,), vec(L - 4, 0, 0), vec(0, -half, H), (0, 0, 3), mat)]   # (each side stops short of the ends by a different unit: no two end faces in one plane)
    axis = "x" if along == "u" else "y"
    base = u1 if along == "u" else v1
    cross = v1 if along == "u" else u1
    b1, b2 = (base + back, base + back + 2) if back == 0 else (base + back - 2, base + back)
    sh.append(prism([(cross, z), (cross + W, z), (cross + half, z + H)], axis, b1, b2, mat))
    f1, f2 = (base + front - 2, base + front) if front == L else (base + front, base + front + 2)
    c1 = half - 22
    h1 = (H * c1) // half
    sh.append(prism([(cross, z), (cross + c1, z), (cross + c1, z + h1)], axis, f1, f2, mat))
    sh.append(prism([(cross + W, z), (cross + W - c1, z), (cross + W - c1, z + h1)], axis, f1, f2, mat))
    m.shapes(sh)
    (ma, mc), (mb, md) = pt(8, 10), pt(L - 8, W - 10)
    m.det([(min(ma, mb), min(mc, md), z, max(ma, mb), max(mc, md), z + 2)], mat_floor)
    # the ridge pole, the back pole, its two guys and their pegs
    (ra, rc), (rb, rd) = pt(0, half - 1), pt(L, half + 2)
    m.det([(min(ra, rb), min(rc, rd), z + H, max(ra, rb), max(rc, rd), z + H + 3)], WOODTRIM)
    pa = back + (-4 if back == 0 else 1)
    (qa, qc), (qb, qd) = pt(pa, half - 1), pt(pa + 3, half + 2)
    m.det([(min(qa, qb), min(qc, qd), z, max(qa, qb), max(qc, qd), z + H + 8)], WOODTRIM)
    ga = back - guy if back == 0 else back + guy
    for c in (-8, W + 8):
        gu, gv = pt(ga, c)
        tu, tv = pt(pa + 1, half)
        m.rope([(tu, tv, z + H + 6), (gu, gv, z + 6)], slack=2, width=1)
        m.det([(gu - 1, gv - 1, z, gu + 2, gv + 2, z + 9)], WOODTRIM)
    (ba, bc), (bb, bd) = pt(-4, -8), pt(L + 4, W + 8)
    m.blocked(min(ba, bb), min(bc, bd), max(ba, bb), max(bc, bd))
    return pt(L // 2, half)


def m_camp(m, opt):
    """The camp. The canal widens to the left onto a broad terrace of beaten earth 128 over the floor (896 by 448, open
    to the sky; the bank along its whole edge is the way up). People who have nowhere else live here: six ridge
    tents (brushes: no tent model exists), no two the same size, patched from tar paper, carpet and sheeting, each
    with a mat inside, a back pole and guy ropes to pegs, their open ends (crouch to go in) turned to a cooking fire
    in the middle: a ring of the game's stones, a pot hung from a tripod, embers that glow and do not flicker, a thread
    of smoke, two benches carried off from a station and two flat rocks to sit on round it. A washing line on two poles with what they own on it
    and a laundry basket under it, a water barrel and buckets, a pushcart, a cork notice board on a pole where the bank
    comes up, a few crates and a chair. Quiet, poor, lived in.
    Named for the game: lc_camp_fire (an info_target at the fire), lc_camp_tent_1 to lc_camp_tent_6 (an info_target
    on the floor inside each tent: where someone sleeps).
    Left as brushes: the tents, their poles and pegs, the tripod's three bars, the embers, the washing (no model of
    cloth hung to dry).
    Unchecked: which face of the cork board is its front; how props/tarpaperroof002a, props/carpetfloor003a and props/carpetfloor006a look as tent cloth (no
    canvas is in the game's own materials); that thin sheared sides 3 thick stop a player cleanly; that the washing
    line's rope hangs where its cloths are (the rope sags by itself)."""
    b = m.b
    tz = F + 128
    tarp, c3, c6, rug = "props/tarpaperroof002a", "props/carpetfloor003a", "props/carpetfloor006a", "props/carpetfloor001a"
    wd = WOODTRIM
    m.open(0, -256, 1280, 256)
    m.open(192, 256, 1088, 704, floor=tz, mat=DIRT)
    m.side(192, 256, 1088, 704)
    # --- the tents: (low corner, length, width, height, the way it lies, its open end, cloth, mat, how far its pegs stand) ---
    # three ridge tents, no two the same size; then people making do: a pallet shelter under a tarp, a lean-to against
    # the back wall, a car's wreck with a tarp run off its side
    tents = [(1, 240, 400, 144, 112, 88, "u", "hi", tarp, rug, 30), (5, 330, 284, 112, 96, 72, "v", "hi", c6, rug, 20), (6, 800, 280, 124, 108, 90, "v", "hi", PLASTER, rug, 18)]
    beds = {}
    for (k, u, v, L, W, H, along, end, cloth, mat, guy) in tents:
        beds[k] = tent(m, u, v, tz, L, W, H, along, end, cloth, mat, guy)
    mattress(m, beds[1][0], beds[1][1] + 20, 0, tz + 2)
    for (u, v, yaw) in ((978, 431, 90), (978, 519, 90), (1017, 475, 0)):                   # the pallet shelter: pallets stood on edge, a tarp on them
        tilted(m, "prop_dynamic_override", M_ + "props_junk/wood_pallet001a.mdl", u, v, tz + 34, yaw, 90, 0, {"solid": "6"})
    m.shapes([para((936, 426, tz + 62), (86, 0, 8), (0, 98, 0), (0, 0, 3), c3)])
    m.det([(946, 440, tz, 1008, 510, tz + 2)], rug)
    beds[2] = (976, 475)
    m.shapes([para((440, 610, tz + 56), (120, 0, 0), (0, 94, 64), (0, 0, 3), PLASTER),        # the lean-to against the back wall, open in front
              prism([(610, tz), (703, tz), (703, tz + 119), (610, tz + 55)], "x", 441, 443, c6), prism([(610, tz), (703, tz), (703, tz + 119), (610, tz + 55)], "x", 557, 559, c6)])
    m.det([(444, 612, tz, 448, 616, tz + 56), (552, 612, tz, 556, 616, tz + 56)], WOODTRIM)
    m.det([(450, 630, tz, 550, 700, tz + 2)], c6)
    beds[3] = (500, 668)
    m.static(M_ + "props_vehicles/car002b_physics.mdl", 764, 642, 0, tz)                       # the car's wreck, a tarp off its side
    m.shapes([para((690, 548, tz), (140, 0, 0), (0, 52, 50), (0, 0, 3), tarp)])
    m.det([(700, 556, tz, 820, 596, tz + 2)], c3)
    mattress(m, 760, 576, 0, tz + 2)
    beds[4] = (760, 576)
    for k in range(1, 7):
        cu, cv = beds[k]
        m.target("lc_camp_tent_%d" % k, cu, cv, tz + 8, 0)
    # a lantern by each one, lit low (the city's oil lamp)
    for (u, v) in ((380, 470), (948, 500), (452, 616), (712, 560), (360, 386), (820, 382)):
        m.dynamic(M_ + "props_c17/lamp001a.mdl", u, v, 0, tz)
        m.light(u, v, tz + 30, "255 180 110 22")
    # patches sewn on two of them (slivers lying on the cloth)
    m.shapes([para((280, 420, tz + 16), (40, 0, 0), (0, 20, 31), (0, 0, 4), c3), para((720, 600, tz + 12), (0, 36, 0), (24, 0, 36), (0, 0, 4), PLASTER)])
    # --- the fire: stones, logs, a pot on a tripod, embers, smoke; log seats round it ---
    fu, fv = 640, 470
    for k, (x, y) in enumerate(((24, 0), (-24, 0), (0, 24), (0, -24), (17, 17), (-17, 17), (17, -17), (-17, -17))):
        m.dynamic(M_ + "props_junk/rock001a.mdl", fu + x, fv + y, 45 * k, tz - 2)       # the ring of stones (each sunk 2 in the earth)
    m.det([(fu - 18, fv - 3, tz, fu + 18, fv + 3, tz + 5), (fu - 3, fv - 16, tz + 4, fu + 3, fv + 16, tz + 9)], MAT["black"])
    m.shapes([para((fu - 26, fv - 14, tz), (3, 0, 0), (0, 3, 0), (24, 12, 62), MAT["bars"]), para((fu + 23, fv - 14, tz), (3, 0, 0), (0, 3, 0), (-24, 12, 63), MAT["bars"]),
              para((fu - 2, fv + 26, tz), (3, 0, 0), (0, 3, 0), (0, -26, 64), MAT["bars"])])
    m.det([(fu - 1, fv - 1, tz + 34, fu + 1, fv + 1, tz + 61)], MAT["bars"])
    m.dynamic(M_ + "props_c17/metalpot001a.mdl", fu, fv, 0, tz + 20)                   # the pot, hung on the tripod's chain
    m.static(M_ + "props_trainstation/bench_indoor001a.mdl", fu - 3, fv - 64, 90, tz)     # seats round it: two benches carried off from a station, two flat rocks
    m.static(M_ + "props_trainstation/bench_indoor001a.mdl", fu + 5, fv + 66, 270, tz)
    m.static(M_ + "props_wasteland/rockgranite03c.mdl", fu - 74, fv + 2, 90, tz - 3)
    m.static(M_ + "props_wasteland/rockgranite03c.mdl", fu + 76, fv + 3, 80, tz - 3)
    m.glow(fu, fv, tz + 8, "255 140 60", 0.35)
    m.light(fu, fv, tz + 26, "255 150 70 75")
    m.smoke(fu, fv, tz + 36, colour="70 70 70", size=9, length=220, rate=8)
    m.target("lc_camp_fire", fu, fv + 40, tz + 8, 270)
    m.blocked(fu - 96, fv - 96, fu + 96, fv + 96)
    # --- the washing line: two poles, a rope, what hangs on it ---
    for u in (469, 717):
        m.dynamic(M_ + "props_c17/signpole001.mdl", u, 319, 0, tz)
    m.rope([(469, 319, tz + 106), (717, 319, tz + 106)], slack=3, width=1)
    m.dynamic(M_ + "props_wasteland/laundry_basket001.mdl", 548, 344, 20, tz)
    m.det([(500, 319, tz + 64, 530, 320, tz + 102), (560, 319, tz + 74, 578, 320, tz + 101), (670, 319, tz + 60, 698, 320, tz + 102)], PLASTER)
    m.det([(596, 319, tz + 68, 640, 320, tz + 101)], c3)
    # --- water, the handcart, the notice post, odds and ends ---
    put(m, M_ + "props_c17/oildrum001.mdl", 620, 688, 0, z=tz)                              # the water barrel under a gutter pipe down the wall
    m.static(M_ + "props_pipes/gutter_256_001a.mdl", 620, 697, 0, b.rim - 256)
    m.loose(M_ + "props_junk/metalbucket01a.mdl", 648, 668, 0, z=tz)
    m.loose(M_ + "props_junk/metalbucket01a.mdl", 596, 660, 40, z=tz)
    m.dynamic(M_ + "props_c17/doll01.mdl", 410, 560, 30, tz)                                   # children live here too
    for kind, u, v, z, seed in (("graffiti", 300, 703, tz + 30, 1), ("graffiti", 380, 703, tz + 22, 2), ("poster", 560, 703, tz + 150, 3),
                                ("stain", 620, 703, tz + 60, 4), ("trash", 700, 440, tz + 1, 5), ("burn", 640, 470, tz + 1, 6), ("stain", 900, 600, tz + 1, 7)):
        m.grime(kind, u, v, z, seed)
    m.decal("decals/decal_posterbreen", 900, 703, tz + 160)                                    # the Combine's face over them
    m.static(M_ + "props_combine/combinecamera001.mdl", 640, -239, 90, b.rim - 40)            # ...and its eye on the opposite rim
    m.soundscape(SCAPES["courtyard"], 640, 480, tz, radius=520)
    m.dynamic(M_ + "props_junk/pushcart01a.mdl", 966, 602, 0, tz)
    m.blocked(912, 560, 1056, 640)
    m.dynamic(M_ + "props_c17/signpole001.mdl", 630, 280, 0, tz)                       # the notice board where the bank comes up
    m.static(M_ + "props_lab/corkboard002.mdl", 630, 277, 270, tz + 48)
    m.loose(M_ + "props_junk/wood_crate001a.mdl", 250, 580, 20, z=tz)
    m.loose(M_ + "props_junk/wood_crate002a.mdl", 1040, 320, 90, z=tz)
    m.loose(M_ + "props_c17/furniturechair001a.mdl", fu + 50, fv - 70, 120, z=tz)
    m.loose(M_ + "props_junk/wood_pallet001a.mdl", 240, 300, 0, z=tz)
    put(m, M_ + "props_c17/furniturecouch002a.mdl", 480, 420, 300, z=tz)
    m.view(120, 60, F, 30, -10, "the terrace from the canal")
    m.view(730, 290, tz, 115, 4, "coming up the bank: the fire, the tents")
    m.view(420, 470, tz, 0, 6, "from the first tent's mouth")
    m.view(980, 680, tz, 225, 10, "from the back corner")
    m.view(500, 684, tz, 270, 4, "under the lean-to, looking out at the fire")
    b.notes.append("%s: the terrace is at z %d, from u 192 to 1088 and v 256 to 704; the fire is at (%d %d)" % ((m.tag, tz) + m.fr.pt(fu, fv)))


MODULES = {
    "tram": (1536, m_tram, "a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk"),
    "tenement": (1280, m_tenement, "a tenement block fallen across the canal: the way on is through its rooms"),
    "quay": (1024, m_quay, "stairs up to a quay with a street doorway (a cap to delete), a footbridge to a barred door"),
    "collapse": (768, m_collapse, "a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs"),
    "scrapyard": (1536, m_scrapyard, "the canal widens into a yard of stacked containers under a crane: ways through, ways over, a perch"),
    "boathouse": (1024, m_boathouse, "a smugglers' boat shed in the left wall: a roll-up door, a slipway, a hatch to a cellar"),
    "arcade": (1536, m_arcade, "a market arcade over the canal on three arches: a covered walk above, a stair on each bank"),
    "chimney": (1024, m_chimney, "a round yard on the right with a hollow brick chimney to climb: a lookout over the whole canal"),
    "crypt": (1024, m_crypt, "the left wall broken into a church crypt: pillars, niches with stone coffins, an altar, a bricked stair"),
    "lift": (1024, m_lift, "EXPERIMENTAL: a freight lift from the canal floor up to a loading dock with a street gate (a cap to delete)"),
    "barge": (1280, m_barge, "a river barge grounded askew: a hideout in its hold, a wheelhouse, a gangplank from the bank"),
    "busbridge": (1024, m_busbridge, "a bus hanging nose-down from the left street: climb through it to a pavement and a street doorway (a cap to delete)"),
    "shell": (1024, m_shell, "a headcrab canister in the right bank: a crater, a cracked wall, the start of an infestation (no creatures)"),
    "aqueduct": (1024, m_aqueduct, "a water trough crossing over the canal on two piers: a ladder to a walk along it, a leak and a pool"),
    "pipes": (1280, m_pipes, "a tangle of service pipes: duck and weave along the floor, or climb to a plank along the main and a bridge"),
    "camp": (1280, m_camp, "a refugee camp on a terrace on the left bank: six tents of brushes round a cooking fire"),
}
