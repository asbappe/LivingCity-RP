#!/usr/bin/env python3
"""
Living City: canal modules, set B: places where the Resistance lives (map_modules.py picks this file up by itself)

    cells      where captured units are kept: a guard room, three barred cells, a crawl duct out
    clinic     a field hospital in a vault: a ward, an operating table, a dispensary, a sluice room
    memorial   the wall of the dead: plaques and candles in a recess under the open sky
    pit        a fighting pit: a caged sunken ring, bleachers, a bookmaker
    garden     a walled garden: soil beds, a rain butt, a lean-to, a scarecrow
    stash      a secret arms room behind a section of canal wall that a pipe valve opens

How to write one, and what every call does: docs/dev/map-modules.md.
"""

import random

from map_build import CELL, MAT, bar_row, octagon, prism
from map_modules import F, TRIM, MM

TILE = "tile/tilefloor018a_c17"
PLASTER = "plaster/plasterwall042c"
STONE = "stone/stonewall040f"
STONE_FLOOR = "stone/stonefloor006d_c17"
CRACKED = "concrete/concretefloor016a"
DIRT = "nature/dirtfloor005c"
DUCT = "metal/metalfloor001a"
BRICK = "brick/brickwall037a"
WOOD, TIN, STEEL, BEAM = MM["wood"], MM["tin"], MM["steel"], MM["beam_wood"]
BARS, WALL = MAT["bars"], MAT["canal_wall"]
WARM = "255 190 120"


# ---------------------------------------------------------------------------
# Helpers the Mod class lacks (all in a module's own coordinates)
# ---------------------------------------------------------------------------

def vprism(pts, z1, z2, mat, top=None):
    """A flat outline seen from above, [(u, v), ...] in order, pushed up from z1 to z2: the faces for m.shapes."""
    faces = [([(u, v, z2) for u, v in pts], top or mat), ([(u, v, z1) for u, v in pts], mat)]
    for k in range(len(pts)):
        (a, b), (c, d) = pts[k], pts[(k + 1) % len(pts)]
        faces.append(([(a, b, z1), (c, d, z1), (c, d, z2), (a, b, z2)], mat))
    return faces


def vpipe(u, v, r, z1, z2, mat, top=None):
    """A standing pipe, post or drum: an octagon about r from (u, v), from z1 up to z2."""
    return vprism(octagon(u, v, r), z1, z2, mat, top)


def ring(axis, c, up, r_in, r_out, a, b, mat, keep=None):
    """A hollow pipe or a wheel's rim lying along "x" (u) or "y" (v) from a to b: eight wedges between two octagons.
    keep(wedge's four corners): leave some out (the ones under a floor)."""
    inner, outer = octagon(c, up, r_in), octagon(c, up, r_out)
    out = []
    for k in range(8):
        quad = [inner[k], inner[(k + 1) % 8], outer[(k + 1) % 8], outer[k]]
        if keep is None or keep(quad):
            out.append(prism(quad, axis, a, b, mat))
    return out


def shape_entity(m, cls, keys, shapes=(), boxes=(), mat=None, connections=None, vis=None):
    """A brush entity whose brushes need not be boxes (a wheel that turns). shapes: lists of faces, as for m.shapes;
    boxes: plain ones, of mat. connections: [(output, name, input, value, delay), ...]."""
    vmf, vis = m.b.vmf, vis or m.dv
    s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (vmf.new_id(), cls)
    for k, v in keys.items():
        s += '\t"%s" "%s"\n' % (k, v)
    s += vmf.wires(connections)
    for faces in shapes:
        s += vmf.convex_text(m.fr.faces(faces), vis)
    for bx in boxes:
        box = m.fr.box(*bx)
        s += vmf.box_text(box, mat, mat, mat, vis)
        vmf.boxes.append((box, False))
    s += vmf.editor(vis, "220 30 220") + "}\n"
    vmf.ents.append(s)
    if keys.get("targetname"):
        m.b.names.append((keys["targetname"], cls, m.tag))


def swing_door(m, name, boxes, mat, hinge, speed=90, wait="-1", reverse=False, sound="doors/doormove1.wav"):
    """A door a player opens by Use: it swings 90 degrees round `hinge` (u, v, z), anticlockwise seen from above
    (reverse: clockwise), and stays until used again. boxes: (box) or (box, material)."""
    out = [(m.fr.box(*b[0]), b[1]) if len(b) == 2 else m.fr.box(*b) for b in boxes]
    m.b.vmf.brush_entity("func_door_rotating", {
        "targetname": name, "origin": "%d %d %d" % (m.fr.pt(hinge[0], hinge[1]) + (hinge[2],)), "distance": "90", "speed": str(speed), "wait": wait, "lip": "0",
        "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": str(32 + 256 + (2 if reverse else 0)), "noise1": sound, "health": "0",
        "ignoredebris": "0", "loopmovesound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255",
        "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"}, out, mat, m.dv)
    m.b.names.append((name, "func_door_rotating", m.tag))


def slide_door(m, name, parts, movedir, speed=40, lip=0, wait="-1", toggle=True, sounds=("MetalGrate.ScrapeSmooth", "MetalGrate.ImpactSoft"), starts_open=False):
    """A sliding door of more than one material, told to move by name (Open, Close, Toggle), never by a player's Use.
    parts: [(box, material), ...]. wait: seconds before it shuts by itself ("-1": it stays)."""
    out = [(m.fr.box(*b), mat) for b, mat in parts]
    m.b.vmf.brush_entity("func_door", {
        "targetname": name, "movedir": movedir, "speed": str(speed), "lip": str(lip), "wait": wait, "spawnflags": "32" if toggle else "0", "spawnpos": "1" if starts_open else "0", "dmg": "0",
        "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "noise1": sounds[0], "noise2": sounds[1], "locked_sentence": "0",
        "unlocked_sentence": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"}, out, parts[0][1], m.dv)
    m.b.names.append((name, "func_door", m.tag))


def cheeks(m, u1, u2, top=136, out=132, thick=12):
    """Where the left wall's bank is cut for a way in (u1 to u2), a retaining wall on each side of the cut, its top
    sloping with the bank it holds back."""
    shape = [(256, F), (256 - out, F), (256 - out, F + 14), (256, F + top)]
    m.shapes([prism(shape, "x", u1 - thick, u1, MAT["beam"]), prism(shape, "x", u2, u2 + thick, MAT["beam"])])


def candle(m, u, v, z, high=6, light=True):
    """A candle stub: an octagon 4 across, its flame a glow, and a small steady warm light."""
    m.shapes([vpipe(u, v, 2, z, z + high, PLASTER)])
    m.glow(u, v, z + high + 3, "255 200 120", 0.08)
    if light:
        m.light(u, v, z + high + 6, "255 170 90 7")


def can_of_stalks(m, u, v, z, seed):
    """A tin with dried stalks in it, left by someone: a small drum and a few thin sticks."""
    rnd = random.Random(seed)
    m.shapes([vpipe(u, v, 3, z, z + 7, TIN)])
    m.det([(u + du, v + dv, z + 6, u + du + 1, v + dv + 1, z + 6 + rnd.randrange(9, 19)) for du, dv in ((-2, -1), (0, 1), (1, -2), (-1, 0))], BEAM)


def goods(m, a, b, at, side, z, levels, seed, deep=14, kinds=(PLASTER, TIN, BEAM), jar="glass/glasswindow041a", jars=0.5):
    """Shelves of small things against a wall that runs along u: boards on uprights from a to b at the wall's line `at`
    (side +1 or -1: the way the room is), a board at each height in `levels` above z, and on each a row of boxes and
    jars (the same every time for one seed)."""
    def q(d):
        return at + side * d
    lo, hi = min(q(0), q(deep)), max(q(0), q(deep))
    top = z + max(levels) + 16
    m.det([(u, lo, z, u + 3, hi, top) for u in (a, (a + b) // 2 - 1, b - 3)], BEAM)
    m.det([(a, lo, z + h, b, hi, z + h + 2) for h in levels], WOOD)
    rnd = random.Random(seed)
    c = (lo + hi) // 2
    pots, boxes = [], {}
    for h in levels:
        u = a + 6
        while u < b - 14:
            if abs(u - (a + b) // 2) < 8:
                u += 10
                continue
            w = rnd.choice((4, 4, 6, 6, 10, 14))
            if w <= 6 and rnd.random() < jars * 2:
                pots.append(vpipe(u + w // 2, c, w // 2, z + h + 2, z + h + 2 + rnd.randrange(6, 12), jar if rnd.random() < 0.7 else STEEL))
            else:
                boxes.setdefault(rnd.choice(kinds), []).append((u, c - 4, z + h + 2, u + w, c + 4, z + h + 2 + rnd.randrange(5, 13)))
            u += w + rnd.randrange(3, 10)
    if pots:
        m.shapes(pots)
    for mat, bx in sorted(boxes.items()):
        m.det(bx, mat)


def arch_rib(m, u1, u2, v1, v2, top, spring, mat):
    """A vault's rib across a hall (from v1 to v2, u1..u2 thick): the roof is at `top`, the arch springs from the walls
    `spring` below it. Six wedges, three to a side."""
    mid, w = (v1 + v2) // 2, v2 - v1
    d1, d2 = w // 12, w // 4
    out = []
    for s, v0 in ((1, v1), (-1, v2)):
        p = [(v0, top - spring), (v0 + s * d1, top - (spring * 2) // 5), (v0 + s * d2, top - spring // 8), (mid, top)]
        out += [prism([p[0], p[1], (p[1][0], top), (v0, top)], "x", u1, u2, mat),
                prism([p[1], p[2], (p[2][0], top), (p[1][0], top)], "x", u1, u2, mat),
                prism([p[2], p[3], (p[2][0], top)], "x", u1, u2, mat)]
    m.shapes(out)


def fire(m, u, v, z, size=24, light="255 150 70 110"):
    """A small fire that burns from the start (the vortigaunt culvert's own), and a steady warm light over it."""
    m.point("env_fire", u, v, z, {"health": "30", "firesize": str(size), "fireattack": "4", "firetype": "0", "spawnflags": "7", "ignitionpoint": "32", "damagescale": "0.2"})
    m.light(u, v, z + 40, light)


# ---------------------------------------------------------------------------
# 1. The cells
# ---------------------------------------------------------------------------

def m_cells(m, opt):
    """The cells: where the Resistance keeps captured Combine units. A plain steel door at the foot of the left wall
    (lc_cells_entry: Use swings it in) opens on a guard room (a table, lockers, a board of keys). A corridor runs on past
    three cells, each 128 by 160 behind a barred front: half of each front is a barred door (lc_cells_door_1 to _3) that
    slides behind the fixed half when the button beside it on the corridor's pier is pressed (lc_cells_button_1 to _3,
    tally marks over each say which). A mattress and a bucket in each; lc_cells_spot_1 to _3 are where a prisoner
    stands. The far cell has a loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it)
    onto a crawl duct 40 high that comes out at the canal's floor through a big outfall pipe: the way to break out, or in.
    Unchecked: the sound ambient/atmosphere/tunnel1.wav; whether a prisoner's Use can reach a button round the pier's
    corner (they are 16 past the cell's edge, facing away); how the prop models sit (table, chair, lockers, mattress)."""
    L, H = 1024, F + 128
    m.open(0, -256, L, 256)
    m.low(128, 256, 192, 320, F + 112)                      # the doorway
    m.low(64, 320, 320, 512, H)                             # the guard room
    m.low(320, 384, 832, 512, H)                            # the corridor
    cells = (320, 512, 704)
    for cu in cells:
        m.low(cu, 512, cu + 128, 704, H)
    m.low(832, 640, 896, 704, F + 40, mat=DUCT)             # the crawl duct: out of the far cell's side wall,
    m.low(896, 256, 960, 704, F + 40, mat=DUCT)             # and down to the canal
    m.side(64, 256, L, 704)
    m.portal(128, 286, F, 192, 288, F + 112)
    m.portal(896, 318, F, 960, 320, F + 40)
    m.blocked(832, 256, 960, 704)
    m.taken(104, 200, F, 216, 256, F + 176)
    m.taken(872, 120, F, 984, 256, F + 80)

    # the way in: a steel door in a cut in the bank, a lamp over it
    cheeks(m, 128, 192)
    swing_door(m, "lc_cells_entry", [(129, 284, F + 1, 191, 290, F + 111), ((176, 282, F + 44, 182, 292, F + 50), BARS)], STEEL, (129, 287, F + 56))
    m.det([(124, 250, F + 112, 196, 256, F + 120), (150, 236, F + 150, 170, 256, F + 154)], MAT["beam"])
    m.lamp(160, 240, F + 142, "255 200 140 90")
    m.lane(160, 288)

    # the guard room
    m.static("models/props_c17/furnituretable002a.mdl", 232, 420, 0)
    m.static("models/props_c17/furniturechair001a.mdl", 232, 372, 90)
    m.static("models/props_c17/lockers001a.mdl", 74, 452, 0)
    m.det([(72, 328, F, 112, 392, F + 18)], BEAM)                                         # a bench by the door
    m.det([(228, 506, F + 58, 300, 512, F + 86)], WOOD)                                   # the board of keys
    hooks, keys = [], []
    for k in range(5):
        u = 236 + k * 14
        hooks.append((u, 503, F + 76, u + 2, 506, F + 78))
        if k != 3:
            keys.append((u, 504, F + 66, u + 2, 505, F + 76))
    m.det(hooks, BARS)
    m.det(keys, STEEL)
    m.lamp(200, 416, H - 20, "255 205 150 110", hang=12)
    m.det([(316, 384, F, 320, 392, H), (316, 504, F, 320, 512, H), (316, 384, H - 8, 320, 512, H)], STEEL)    # the frame of the way through
    m.lane(200, 448)

    # the corridor and the cells
    for u in (448, 672):
        m.lamp(u, 448, H - 8, "215 220 200 70")
    for k, cu in enumerate(cells):
        n = k + 1
        last = k == 2
        fixed, door = (cu + 64, cu) if last else (cu, cu + 64)      # (the far cell's door is on its near half: its button is on the pier too)
        m.bars((fixed, 536, F, fixed + 64, 544, H), "u")
        m.door("lc_cells_door_%d" % n, bar_row((door, 544, F, door + 64, 552, H), "x"), BARS, "0 %d 0" % m.fr.yaw(0 if last else 180), speed=48, lip=0)
        bu = cu - 20 if last else cu + 148                          # on the pier's face, 16 or more past the cell's edge
        m.button("lc_cells_button_%d" % n, bu, 512, F + 40, 270, [("lc_cells_door_%d" % n, "Toggle", "", 0)])
        m.det([(bu - 2 * n + 4 * j, 511, F + 72, bu - 2 * n + 4 * j + 2, 512, F + 84) for j in range(n)], PLASTER)
        m.target("lc_cells_spot_%d" % n, cu + 64, 624, F + 8, 270)
        m.loose("models/props_c17/furnituremattress001a.mdl", cu + 30, 640, 90)
        m.shapes([vpipe(cu + 110, 566, 7, F, F + 14, STEEL, top=MAT["black"])])       # the bucket
        m.det([(cu + 62, 700, F + 60, cu + 66, 704, F + 66), (cu + 63, 701, F + 30, cu + 65, 702, F + 60)], BARS)   # a ring in the wall, and its chain
        m.light(cu + 64, 620, H - 14, "200 205 185 22")
        m.lane(cu + 64, 448)

    m.shapes([prism(octagon(400, H - 12, 5), "x", 320, 832, BARS)])                    # a pipe under the corridor's roof
    m.det([(u, 396, H - 20, u + 4, 404, H) for u in (384, 576, 768)], STEEL)
    m.det([(796, 392, F, 820, 416, F + 20)], BEAM)                                        # the guard's stool at the corridor's end
    m.det([(639, 596 + 4 * j, F + 70, 640, 598 + 4 * j, F + 80) for j in range(9)]
          + [(639, 594, F + 74, 640, 632, F + 76)], PLASTER)                            # days scratched on the middle cell's wall
    m.static("models/props_junk/wood_crate001a.mdl", 284, 350, 10)                        # what was taken off the prisoners
    m.decal("decals/decalposter014a", 64, 400, F + 80)

    # the far cell's loose grate, the duct, and the outfall pipe it comes out through
    slats = [(833, 641, F + 1 + 8 * j, 836, 703, F + 5 + 8 * j) for j in range(5)]
    swing_door(m, "lc_cells_grate", slats + [(833, 641, F + 1, 837, 645, F + 39), (833, 699, F + 1, 837, 703, F + 39)], BARS, (835, 643, F + 20),
               sound="doors/gate_move1.wav")
    m.shapes(ring("y", 928, F + 16, 40, 48, 124, 256, BARS, keep=lambda q: max(p[1] for p in q) > F + 8))
    m.sound("ambient/atmosphere/tunnel1.wav", 576, 448, F + 96, radius=500, volume=3)

    m.view(160, 180, F, 90, 0, "the door in the wall")
    m.view(110, 350, F, 40, 4, "the guard room")
    m.view(336, 448, F, 0, 2, "the corridor")
    m.view(736, 448, F, 80, 6, "the far cell from the corridor")
    m.view(730, 560, F, 20, 20, "in the far cell: the grate")
    m.view(928, 60, F, 90, 0, "the outfall pipe")


def line_walls(m, rooms, dado=56, low=TILE, high=PLASTER, roof=PLASTER):
    """Whitewash a vault: a skin 2 thick on every wall of these rooms, [(u1, v1, u2, v2, ceiling), ...] (floors at F):
    tile up to `dado`, plaster above, plaster over a lower doorway's head, and a plaster skin under each roof.
    It finds the walls by itself: wherever the square next door is not painted."""
    cells = m.b.plan.cells

    def spec(u, v):
        x, y = m.fr.pt(u + 32, v + 32)
        return cells.get((x // CELL, y // CELL))
    runs = {}
    for (u1, v1, u2, v2, ceil) in rooms:
        edges = [("u", u, v1, 1, (u, v1 - CELL)) for u in range(u1, u2, CELL)] + [("u", u, v2, -1, (u, v2)) for u in range(u1, u2, CELL)]
        edges += [("v", v, u1, 1, (u1 - CELL, v)) for v in range(v1, v2, CELL)] + [("v", v, u2, -1, (u2, v)) for v in range(v1, v2, CELL)]
        for axis, a, line, side, nb in edges:
            n = spec(*nb)
            if n is None:
                parts = [(F, F + dado, low), (F + dado, ceil, high)]
            elif n[0] == "low" and n[3] < ceil:
                parts = [(n[3], ceil, high)]
            else:
                continue
            for z1, z2, mat in parts:
                runs.setdefault((axis, line, side, z1, z2, mat), []).append(a)
        if roof:
            m.det([(u1, v1, ceil - 2, u2, v2, ceil)], roof)
    for (axis, line, side, z1, z2, mat), at in sorted(runs.items()):
        at.sort()
        start = prev = at[0]
        for a in at[1:] + [None]:
            if a is not None and a == prev + CELL:
                prev = a
                continue
            lo, hi = min(line, line + 2 * side), max(line, line + 2 * side)
            m.det([(start, lo, z1, prev + CELL, hi, z2) if axis == "u" else (lo, start, z1, hi, prev + CELL, z2)], mat)
            start = prev = a


BED_YAW = 90     # the way the clinic's bed frames are turned: change it if a compile shows them lying across their mattresses


# ---------------------------------------------------------------------------
# 2. The clinic
# ---------------------------------------------------------------------------

def m_clinic(m, opt):
    """The clinic: a field hospital in a vault off the left wall, whitewashed and tiled against the canal's concrete.
    A wide way in between two drawn curtains (a white cross on the wall over it); a ward of four beds along its back wall
    with cloth screens between them (lc_clinic_bed_1 to _4: where a patient lies), a bedside locker and a drip stand
    each; a dispensary nook behind a counter (crouch under its flap at the left end), shelves of bottles on its back
    wall; through a curtained opening an operating theatre with a steel table under a strong lamp that shines straight
    down (lc_clinic_table: on the table), a trolley and shelves; and off the theatre a sluice room with a sink, a
    boiler and a floor drain.
    Unchecked: the sound ambient/water/leak_1.wav; how the prop models sit and face (the bed frames above all: BED_YAW
    turns them; the sink, radiator, shelves, table and chair)."""
    L = 1024
    m.open(0, -256, L, 256)
    m.low(384, 256, 576, 320, F + 144)                          # the way in
    m.low(384, 320, 576, 448, F + 144, mat=TILE)
    m.low(128, 448, 704, 768, F + 160, mat=TILE)                # the ward
    m.low(128, 320, 320, 448, F + 128, mat=TILE)                # the dispensary nook
    m.low(704, 576, 768, 704, F + 128, mat=TILE)                # through to the theatre
    m.low(768, 448, 960, 768, F + 176, mat=TILE)                # the operating theatre
    m.low(832, 320, 960, 448, F + 128, mat=TILE)                # the sluice room
    m.side(64, 256, L, 832)
    m.portal(384, 318, F, 576, 320, F + 144)
    m.taken(360, 180, F, 600, 256, F + 230)
    cheeks(m, 384, 576)
    line_walls(m, [(384, 320, 576, 448, F + 144), (128, 448, 704, 768, F + 160), (128, 320, 320, 448, F + 128), (704, 576, 768, 704, F + 128),
                   (768, 448, 960, 768, F + 176), (832, 320, 960, 448, F + 128)])

    # the way in: a white cross on the wall, a lamp, two curtains drawn aside under a valance
    m.det([(474, 254, F + 168, 486, 256, F + 212), (458, 254, F + 184, 502, 256, F + 196)], PLASTER)
    m.lamp(480, 236, F + 150, "235 240 225 80")
    m.det([(470, 236, F + 158, 490, 256, F + 162)], MAT["beam"])
    cloth = []
    for k in range(7):
        dv = 2 if k % 2 else 0
        cloth.append((386 + 8 * k, 350 + dv, F + 2, 394 + 8 * k, 352 + dv, F + 124))
        cloth.append((518 + 8 * k, 350 + dv, F + 2, 526 + 8 * k, 352 + dv, F + 124))
    cloth.append((386, 349, F + 122, 574, 355, F + 136))
    m.det(cloth, PLASTER)
    m.det([(384, 351, F + 136, 576, 353, F + 138)], BARS)
    m.lane(480, 352)

    # the ward: four beds, a screen between each, a locker and a drip stand at every bed
    for k in range(4):
        u, n = 200 + 128 * k, k + 1
        m.static("models/props_wasteland/prison_bedframe001b.mdl", u, 716, BED_YAW)
        m.det([(u - 17, 680, F + 20, u + 17, 754, F + 25)], PLASTER)                         # a mattress and a pillow
        m.det([(u - 13, 738, F + 25, u + 13, 752, F + 29)], TILE)
        m.det([(u + 30, 744, F, u + 46, 762, F + 26)], STEEL, top=PLASTER)                   # the bedside locker
        m.det([(u - 34, 750, F, u - 32, 752, F + 78), (u - 38, 748, F, u - 28, 754, F + 2), (u - 34, 746, F + 76, u - 32, 752, F + 78)], BARS)
        m.shapes([vpipe(u - 33, 746, 2, F + 66, F + 75, "glass/glasswindow041a")])
        m.target("lc_clinic_bed_%d" % n, u, 716, F + 28, 270)
        if k < 3:
            s = u + 64
            m.det([(s - 1, 652, F + 10, s + 1, 764, F + 78)], PLASTER)
            m.det([(s - 1, 650, F, s + 1, 652, F + 80), (s - 1, 764, F, s + 1, 766, F + 80), (s - 1, 650, F + 78, s + 1, 766, F + 80),
                   (s - 8, 650, F, s + 8, 652, F + 2), (s - 8, 764, F, s + 8, 766, F + 2)], BARS)
    m.static("models/props_c17/furnitureradiator001a.mdl", 136, 520, 0)
    m.det([(132, 600, F, 152, 690, F + 18)], BEAM)                                           # a bench for whoever waits
    m.static("models/props_c17/furnituretable001a.mdl", 656, 500, 0)                         # the nurse's table
    m.static("models/props_c17/furniturechair001a.mdl", 656, 544, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 352, 474, 90)                        # a stove, its flue up through the roof
    m.shapes([vpipe(352, 456, 4, F + 34, F + 158, BARS)])
    for u in (264, 520):
        m.lamp(u, 590, F + 138, "235 240 228 130", hang=20)
    for u, v in ((200, 600), (456, 600), (640, 560)):
        m.lane(u, v)

    # the dispensary nook: a counter across its front (a flap at its left end), shelves of bottles behind
    m.det([(172, 438, F, 320, 454, F + 38)], BEAM)
    m.det([(170, 436, F + 38, 320, 456, F + 41)], WOOD)
    m.det([(130, 438, F + 38, 170, 454, F + 40)], WOOD)
    m.det([(136, 322, F, 140, 338, F + 112), (222, 322, F, 226, 338, F + 112), (308, 322, F, 312, 338, F + 112)], BEAM)
    m.det([(136, 322, z, 312, 338, z + 2) for z in (F + 30, F + 58, F + 86, F + 110)], WOOD)
    rnd = random.Random(7)
    jars, boxes = [], []
    for z in (F + 32, F + 60, F + 88):
        u = 144
        while u < 300:
            if 216 < u < 232:
                u = 232
            w = rnd.choice((4, 4, 6, 10, 14))
            if w <= 6:
                jars.append(vpipe(u + w // 2, 330, w // 2, z, z + rnd.randrange(6, 13), "glass/glasswindow041a" if rnd.random() < 0.6 else STEEL))
            else:
                boxes.append((u, 325, z, u + w, 335, z + rnd.randrange(6, 15)))
            u += w + rnd.randrange(3, 12)
    m.shapes(jars)
    m.det(boxes, PLASTER)
    m.det([(250, 440, F + 41, 270, 452, F + 43), (258, 444, F + 43, 262, 448, F + 52), (248, 444, F + 52, 272, 448, F + 53)], STEEL)   # the scales
    m.lamp(224, 392, F + 106, "255 215 160 80", hang=20)
    m.lane(224, 392)

    # through to the theatre: a steel frame and one curtain, drawn back
    m.det([(732, 576, F, 740, 580, F + 126), (732, 700, F, 740, 704, F + 126), (732, 576, F + 118, 740, 704, F + 126)], STEEL)
    m.det([(735, 580 + 6 * k, F + 2, 737, 586 + 6 * k, F + 118) for k in range(0, 5, 2)]
          + [(733, 586 + 6 * k, F + 2, 735, 592 + 6 * k, F + 118) for k in range(0, 4, 2)], PLASTER)
    m.lane(736, 640)

    # the operating theatre: the table under its lamp, a trolley, shelves
    cu, cv = 864, 640
    m.det([(cu - 8, cv - 8, F, cu + 8, cv + 8, F + 28), (cu - 16, cv - 14, F, cu + 16, cv + 14, F + 3)], STEEL)
    m.det([(cu - 38, cv - 15, F + 28, cu + 38, cv + 15, F + 33)], STEEL, top=PLASTER)
    m.det([(cu + 22, cv - 11, F + 33, cu + 36, cv + 11, F + 36)], PLASTER)
    m.target("lc_clinic_table", cu, cv, F + 36, 270)
    m.shapes([vpipe(cu, cv, 22, F + 146, F + 154, STEEL, top=STEEL), vpipe(cu, cv, 3, F + 154, F + 174, BARS)])
    m.spot(cu, cv, F + 144, "255 250 235 900", 0, pitch=90, cone=56)
    m.glow(cu, cv, F + 143, "255 250 235", 0.4)
    m.light(cu, cv, F + 120, "240 244 235 60")
    tu, tv = 924, 580                                                                        # the trolley
    m.det([(tu - 12, tv - 9, F + 30, tu + 12, tv + 9, F + 32), (tu - 12, tv - 9, F + 10, tu + 12, tv + 9, F + 12)], STEEL)
    m.det([(tu + du, tv + dv, F, tu + du + 2, tv + dv + 2, F + 34) for du in (-12, 10) for dv in (-9, 7)], BARS)
    m.det([(tu - 8, tv - 5, F + 32, tu + 6, tv + 3, F + 33), (tu - 6, tv - 3, F + 33, tu + 2, tv - 2, F + 34), (tu - 5, tv, F + 33, tu + 4, tv + 1, F + 34)], PLASTER)
    m.static("models/props_wasteland/kitchen_shelf002a.mdl", 864, 744, 270)
    m.det([(772, 700, F, 790, 760, F + 34)], STEEL, top=PLASTER)                             # a cabinet
    m.lane(820, 520)

    # the sluice room: a narrowed way in, the sink, a boiler with its flue, a drain in the floor
    m.det([(832, 444, F, 864, 448, F + 128), (928, 444, F, 960, 448, F + 128)], TILE)
    m.static("models/props_interiors/sinkkitchen01a.mdl", 880, 336, 90)
    m.shapes([vpipe(934, 348, 18, F + 8, F + 78, STEEL), vpipe(934, 348, 4, F + 78, F + 126, BARS), vpipe(934, 348, 20, F, F + 8, MAT["beam"])])
    m.det([(880, 384, F, 912, 416, F + 1)], BARS)
    m.shapes([vpipe(852, 420, 7, F, F + 14, STEEL, top=MAT["black"])])
    m.shapes([prism(octagon(326, F + 100, 3), "x", 834, 958, BARS)])                      # the water pipe
    m.light(896, 384, F + 110, "225 235 235 45")
    m.sound("ambient/water/leak_1.wav", 896, 350, F + 40, radius=320, volume=3)
    m.lane(896, 400)

    m.view(480, 150, F, 90, 0, "the way in")
    m.view(480, 420, F, 100, 4, "the ward")
    m.view(600, 520, F, 190, 6, "the dispensary from the ward")
    m.view(690, 640, F, 0, 8, "the theatre")
    m.view(896, 520, F, 270, 8, "the sluice room")


# ---------------------------------------------------------------------------
# 3. The memorial
# ---------------------------------------------------------------------------

def m_memorial(m, opt):
    """The wall of the dead: a shallow recess in the left wall, open to the sky, its floor one step above the canal's.
    A stone wall stands against its back, covered in rows of small plaques (the upper rows half empty: room for more),
    with a ledge at its foot where candle stubs burn steadily among tins of dried stalks, a few pictures and bottles;
    a wreath over it, posters on the side walls, a line strung across, and a plank bench out in the canal facing it.
    lc_memorial_wall is the middle of the wall, facing out: the game may one day list there the names of characters
    who died for good.
    Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind). No flowers: no flower model is
    known to be in the owner's game, so the dried stalks are brushes."""
    L, Z = 768, F + 16
    m.open(0, -256, L, 256)
    m.open(192, 256, 576, 384, floor=Z, mat=STONE_FLOOR)
    m.side(192, 256, 576, 384)
    m.no_bank(192, 240, 576, 272)
    m.taken(168, 100, F, 600, 256, F + 150)
    cheeks(m, 192, 576)
    m.det([(192, 232, F, 576, 256, F + 8)], STONE, top=STONE_FLOOR)                      # the step up
    m.det([(192, 252, F + 8, 576, 256, Z)], STONE, top=STONE_FLOOR)

    # the stone wall: a plinth whose top is the ledge, the face, a coping
    m.det([(232, 380, Z + 24, 536, 384, Z + 200)], STONE)
    m.det([(224, 366, Z, 544, 384, Z + 24)], STONE, top=STONE_FLOOR)
    m.det([(224, 376, Z + 200, 544, 384, Z + 208), (368, 378, Z + 208, 400, 384, Z + 240)], STONE)
    m.shapes(ring("y", 384, Z + 224, 9, 14, 374, 378, BEAM))                              # the wreath
    rnd = random.Random(11)
    kinds = (STEEL, STEEL, STEEL, TIN, BEAM)
    plaques = {}
    for row in range(7):
        z = Z + 38 + 22 * row
        for col in range(12):
            if rnd.random() < (0.97, 0.95, 0.9, 0.8, 0.55, 0.3, 0.12)[row]:
                u = 242 + 24 * col + rnd.randrange(-1, 2)
                plaques.setdefault(rnd.choice(kinds), []).append((u, 378, z, u + 20, 380, z + 14))
    for mat, boxes in sorted(plaques.items()):
        m.det(boxes, mat)
    m.target("lc_memorial_wall", 384, 372, Z + 112, 270)

    # what people leave: candle stubs on the ledge and at its foot, tins of dried stalks, pictures, bottles
    for k, (u, high) in enumerate(((236, 5), (251, 3), (270, 7), (296, 4), (309, 6), (338, 3), (352, 8), (377, 5), (391, 4), (415, 7), (440, 3),
                                   (458, 6), (476, 4), (497, 8), (512, 5), (531, 3))):
        candle(m, u, 370 + (k * 5) % 7, Z + 24, high, light=k % 2 == 0)
    for k, (u, v, high) in enumerate(((300, 356, 4), (310, 349, 7), (322, 358, 3), (384, 350, 6), (396, 357, 4), (452, 352, 5), (468, 359, 8), (250, 354, 3))):
        candle(m, u, v, Z, high, light=k % 2 == 1)
    for k, (u, v, z) in enumerate(((284, 372, Z + 24), (430, 371, Z + 24), (524, 373, Z + 24), (360, 356, Z), (500, 352, Z))):
        can_of_stalks(m, u, v, z, 20 + k)
    m.det([(u, 375, Z + 24, u + 7, 376, Z + 33) for u in (322, 402, 486)], BEAM)             # pictures, propped against the stone
    m.det([(u + 1, 374, Z + 25, u + 6, 375, Z + 32) for u in (322, 402, 486)], PLASTER)
    m.shapes([vpipe(u, 371, 2, Z + 24, Z + 33, "glass/glasswindow041a") for u in (262, 366, 448)])
    m.decal("decals/decalposter014a", 192, 316, Z + 96)
    m.decal("decals/decal_posters005a", 576, 322, Z + 100)
    m.decal("decals/decal_posters005a", 208, 384, Z + 120)
    m.rope([(194, 300, Z + 216), (574, 300, Z + 216)], slack=70)

    # the bench out in the canal, facing the wall
    m.det([(322, 142, F, 336, 164, F + 15), (432, 142, F, 446, 164, F + 15)], MAT["beam"])
    m.det([(312, 140, F + 15, 456, 150, F + 18), (312, 152, F + 15, 456, 166, F + 18)], WOOD)
    m.blocked(296, 124, 472, 182)
    m.lane(384, 208)
    m.lane(384, 312, Z)
    m.sound("ambient/levels/canals/windmill_wind_loop1.wav", 384, 300, Z + 160, radius=600, volume=2)

    m.view(384, 40, F, 90, 0, "from across the canal")
    m.view(384, 190, F, 90, -6, "from the bench")
    m.view(240, 290, Z, 35, 2, "the ledge")
    m.view(700, 120, F, 150, 2, "walking past")


# ---------------------------------------------------------------------------
# 4. The fighting pit
# ---------------------------------------------------------------------------

def m_pit(m, opt):
    """The fighting pit: the canal opens on its left, through a mouth 512 wide, into an eight-sided arena under the
    open sky. In its middle a ring sunk 64 into the floor, 384 across, floored with dirt, inside a chain-link cage on
    posts; the one gate (lc_pit_gate, on the side toward the canal) slides aside when the button on the post beside it
    is pressed (lc_pit_gate_button) or the game tells it to (Open, Close), and steps go down from it into the ring.
    lc_pit_corner_a and lc_pit_corner_b are the two corners the fighters start in (a stool in each). Three tiers of
    concrete seats, 32 high each, stand on the three far sides, with stairs of 16 up the middle of each side. By the
    mouth on the right the bookmaker's table, chair and lamp under a chalk board of odds (lc_pit_bookie: where he
    sits); on the left the corner men's bench, water drum and bucket. Two lamps hang over the ring from a gantry.
    Unchecked: whether a press of the gate's button can be made through the cage from inside (it should not: the post
    stands 16 clear of it); the button's model is Episode Two's (the framework's own choice)."""
    L, cu, cv = 1280, 640, 704
    FENCE = MAT["fence"]
    m.open(0, -256, L, 256)
    for i in range(-7, 7):
        for j in range(-7, 7):
            du, dv = i * CELL + 32, j * CELL + 32
            if abs(du) + abs(dv) >= 704:
                continue
            u, v = cu + i * CELL, cv + j * CELL
            if abs(du) < 192 and abs(dv) < 192:
                m.open(u, v, u + CELL, v + CELL, floor=F - 64, mat=DIRT)
            else:
                m.open(u, v, u + CELL, v + CELL, mat=MAT["quay_floor"])
    m.side(128, 256, 1152, 1216)
    m.no_bank(128, 264, 1152, 1216)
    m.blocked(128, 448, 1152, 1216)
    m.taken(360, 100, F, 920, 256, F + 150)
    cheeks(m, 384, 896)

    # the cage round the ring: a kerb, posts, chain link, a rail along the top; the gate's gap is on the canal's side
    r1, r2, top = 192, 204, F + 144                  # (the ring's edge and the cage's line, from the middle)
    a1, a2, b1, b2 = cu - r2, cu + r2, cv - r2, cv + r2
    m.det([(a1 - 2, b1 - 2, F, a2 + 2, cv - r1, F + 6), (a1 - 2, cv + r1, F, a2 + 2, b2 + 2, F + 6),
           (a1 - 2, cv - r1, F, cu - r1, cv + r1, F + 6), (cu + r1, cv - r1, F, a2 + 2, cv + r1, F + 6)], MAT["beam"])
    posts, sheets, rails = [], [], []
    for k in range(5):
        t = -r2 + k * 102
        for (u, v) in ((cu + t, b1), (cu + t, b2), (a1, cv + t), (a2, cv + t)):
            posts.append((u - 4, v - 4, F + 6, u + 4, v + 4, top + (80 if (k == 2 and v == cv + t) else 4)))
    posts += [(604, b1 - 4, F + 6, 608, b1 + 4, top), (672, b1 - 4, F + 6, 676, b1 + 4, top)]
    sheets += [(a1, b2 - 1, F + 6, a2, b2 + 1, top), (a1 - 1, b1, F + 6, a1 + 1, b2, top), (a2 - 1, b1, F + 6, a2 + 1, b2, top),
               (a1, b1 - 1, F + 6, 604, b1 + 1, top), (676, b1 - 1, F + 6, a2, b1 + 1, top), (604, b1 - 1, F + 118, 676, b1 + 1, top)]
    rails += [(a1, b2 - 2, top, a2, b2 + 2, top + 4), (a1 - 2, b1, top, a1 + 2, b2, top + 4), (a2 - 2, b1, top, a2 + 2, b2, top + 4),
              (a1, b1 - 2, top, a2, b1 + 2, top + 4), (604, b1 - 2, F + 114, 676, b1 + 2, F + 118)]
    m.det(posts + rails, BARS)
    m.det(sheets, FENCE)
    g = b1 - 5                                           # the gate hangs just outside the cage's line and slides along it
    slide_door(m, "lc_pit_gate", [((608, g - 1, F + 8, 672, g + 1, F + 112), FENCE), ((608, g - 2, F + 8, 612, g + 2, F + 112), BARS),
                                  ((668, g - 2, F + 8, 672, g + 2, F + 112), BARS), ((608, g - 2, F + 108, 672, g + 2, F + 112), BARS),
                                  ((608, g - 2, F + 8, 672, g + 2, F + 12), BARS), ((608, g - 2, F + 58, 672, g + 2, F + 62), BARS)],
               "0 %d 0" % m.fr.yaw(0), speed=60, lip=0)
    m.det([(692, 470, F, 704, 482, F + 64)], MAT["beam"])
    m.button("lc_pit_gate_button", 698, 470, F + 34, 270, [("lc_pit_gate", "Toggle", "", 0)])
    m.test_button((572, 470, F + 40, 580, 478, F + 56), [("OnIn", "lc_pit_gate", "Open"), ("OnOut", "lc_pit_gate", "Close")])
    m.det([(566, 468, F, 586, 480, F + 40)], MAT["beam"])
    m.steps(608, 608, 672, F - 64, F, "v", -1)
    m.target("lc_pit_corner_a", 496, 584, F - 56, 45)
    m.target("lc_pit_corner_b", 784, 848, F - 56, 225)
    m.det([(456, 520, F - 64, 472, 536, F - 48), (808, 872, F - 64, 824, 888, F - 48)], BEAM)

    # the gantry over the ring, two lamps hanging from it
    m.det([(a1 - 3, cv - 3, top + 74, a2 + 3, cv + 3, top + 80)], BARS)
    for u in (cu - 88, cu + 88):
        m.lamp(u, cv, top + 46, "255 225 180 320", hang=20)

    # the seats: three tiers on the three far sides, stairs up the middle of each
    tiers, stairs = [], []
    for k in range(3):
        d, e, z = 256 + 64 * k, 384 - 64 * k, F + 32 * (k + 1)
        tiers += [(cu - d - 64, cv - 192, F, cu - d, cv + e, z), (cu + d, cv - 192, F, cu + d + 64, cv + e, z), (cu - e, cv + d, F, cu + e, cv + d + 64, z)]
        stairs += [(cu - d, cv - 32, F, cu - d + 16, cv + 32, z - 16), (cu + d - 16, cv - 32, F, cu + d, cv + 32, z - 16), (cu - 32, cv + d - 16, F, cu + 32, cv + d, z - 16)]
    m.det(tiers, MAT["beam"], top=MAT["quay_floor"])
    m.det(stairs, WALL, top=MAT["stairs"])

    # the bookmaker, right of the mouth: table, chair, strongbox, a lamp on a post, the board of odds on the wall
    m.static("models/props_c17/furnituretable002a.mdl", 948, 424, 90)
    m.static("models/props_c17/furniturechair001a.mdl", 944, 380, 90)
    m.target("lc_pit_bookie", 944, 380, F + 8, 90)
    m.det([(962, 414, F + 38, 978, 426, F + 46)], STEEL)
    m.det([(1004, 420, F, 1008, 424, F + 118), (976, 421, F + 112, 1008, 423, F + 114)], BARS)
    m.lamp(982, 422, F + 102, "255 205 140 160", hang=4)
    m.det([(964, 384, F + 44, 1020, 386, F + 104)], MAT["black"])
    m.det([(962, 384, F + 42, 1022, 387, F + 44), (962, 384, F + 104, 1022, 387, F + 106), (962, 384, F + 44, 964, 387, F + 104), (1020, 384, F + 44, 1022, 387, F + 104)], BEAM)
    chalk = [(968, 386, F + 92, 1016, 387, F + 93), (991, 386, F + 50, 992, 387, F + 92)]
    for row in range(4):
        z = F + 82 - 9 * row
        chalk += [(970 + 3 * j, 386, z, 971 + 3 * j, 387, z + 6) for j in range((3, 5, 2, 4)[row])]
        chalk += [(996 + 3 * j, 386, z, 997 + 3 * j, 387, z + 6) for j in range((4, 1, 5, 2)[row])]
    m.det(chalk, PLASTER)

    # the corner men, left of the mouth: a bench with a towel, a drum of water, a bucket
    m.det([(268, 396, F, 284, 404, F + 16), (268, 452, F, 284, 460, F + 16)], MAT["beam"])
    m.det([(264, 392, F + 16, 288, 464, F + 19)], WOOD)
    m.det([(266, 420, F + 19, 286, 438, F + 20), (286, 420, F + 9, 287, 438, F + 20)], PLASTER)
    m.static("models/props_c17/oildrum001.mdl", 344, 356, 0)
    m.shapes([vpipe(318, 410, 7, F, F + 14, STEEL, top=MAT["black"])])
    for u, v in ((640, 380), (480, 380), (800, 380), (640, 300)):
        m.lane(u, v)

    m.view(640, 100, F, 90, 2, "from the canal")
    m.view(640, 440, F, 90, 8, "at the gate")
    m.view(520, 840, F - 64, 315, 0, "in the ring")
    m.view(640, 1100, F + 96, 270, 16, "from the top tier")
    m.view(840, 440, F, 20, 2, "the bookmaker")


# ---------------------------------------------------------------------------
# 5. The garden
# ---------------------------------------------------------------------------

GRASS = "nature/grassfloor002a"
CLOTH = "props/carpetfloor003a"


def m_garden(m, opt):
    """The walled garden: where the Resistance grows food. A gap in the left wall, three steps up and a picket gate
    (lc_garden_gate: Use swings it), opens on a yard 640 by 448 under the open sky, its floor 24 above the canal's.
    Six raised soil beds edged with timber, three on each side of a path of flagstones (lc_garden_bed_1 to _6: on the
    beds, for a farming job; 1 to 3 on the left going back, 4 to 6 on the right), ridged and planted; bean poles with
    lines between over the first bed on each side; a scarecrow in the middle bed on the right. Against the back wall a
    tool lean-to (a bench, pots, a shovel, a bucket), a rain butt fed by pipes down the wall in the left corner, a
    compost bay in the right corner; a push cart and a crate of melons on the path.
    Unchecked: nothing from memory (models and materials pass map_assets.py); how the loose things lie once the game
    drops them (shovel, bucket, pots, melons, cart)."""
    L, Z = 1280, F + 24
    m.open(0, -256, L, 256)
    m.open(576, 256, 704, 320, floor=Z, mat=CRACKED)
    m.open(320, 320, 960, 768, floor=Z, mat=CRACKED)
    m.side(320, 256, 960, 768)
    m.no_bank(576, 240, 704, 272)
    m.taken(552, 100, F, 728, 256, F + 150)
    cheeks(m, 576, 704)
    m.steps(220, 576, 704, F, Z, "v", 1)
    m.blocked(576, 208, 704, 256)
    m.lane(640, 200)
    m.lane(640, 336, Z)

    # the picket gate: a fixed half and a leaf that swings in
    pickets = [(580 + 8 * k, 287, Z + 2, 584 + 8 * k, 289, Z + 44 + (2 if k % 2 else 0)) for k in range(8)]
    m.det(pickets + [(576, 289, Z + 10, 642, 291, Z + 14), (576, 289, Z + 32, 642, 291, Z + 36), (638, 286, Z, 642, 292, Z + 48)], BEAM)
    leaf = [(646 + 8 * k, 287, Z + 2, 650 + 8 * k, 289, Z + 44 + (2 if k % 2 else 0)) for k in range(7)]
    swing_door(m, "lc_garden_gate", leaf + [(644, 289, Z + 10, 702, 291, Z + 14), (644, 289, Z + 32, 702, 291, Z + 36)], BEAM, (702, 290, Z + 24),
               reverse=True, sound="doors/gate_move1.wav")

    # six raised beds: timber edges, soil, three ridges each, something growing
    rnd = random.Random(5)
    beds = [(352, v) for v in (360, 472, 584)] + [(736, v) for v in (360, 472, 584)]
    edges, soil, ridges, greens, stakes = [], [], [], [], []
    for n, (u, v) in enumerate(beds):
        a, b = u + 192, v + 72
        edges += [(u, v, Z, a, v + 4, Z + 18), (u, b - 4, Z, a, b, Z + 18), (u, v + 4, Z, u + 4, b - 4, Z + 18), (a - 4, v + 4, Z, a, b - 4, Z + 18)]
        stakes += [(u - 2, v - 2, Z, u + 4, v + 4, Z + 22), (a - 4, v - 2, Z, a + 2, v + 4, Z + 22), (u - 2, b - 4, Z, u + 4, b + 2, Z + 22), (a - 4, b - 4, Z, a + 2, b + 2, Z + 22)]
        soil.append((u + 4, v + 4, Z, a - 4, b - 4, Z + 13))
        for row in range(3):
            c = v + 16 + 20 * row
            ridges.append(prism([(c - 7, Z + 13), (c + 7, Z + 13), (c, Z + 17)], "x", u + 6, a - 6, DIRT))
            if n in (0, 3):
                continue                                    # (the beans' beds: their poles come below)
            step = (14, 22, 18)[(n + row) % 3]
            for k in range(u + 14, a - 10, step):
                if rnd.random() < 0.82:
                    r = rnd.choice((2, 3, 3, 4))
                    greens.append(vpipe(k + rnd.randrange(-2, 3), c, r, Z + 15, Z + 17 + r + rnd.randrange(0, 4), GRASS))
        m.target("lc_garden_bed_%d" % (n + 1), u + 96, v + 36, Z + 18, 270 if n < 3 else 270)
    m.det(edges + stakes, BEAM)
    m.det(soil, DIRT)
    m.shapes(ridges + greens)
    m.blocked(336, 344, 560, 672)
    m.blocked(720, 344, 944, 672)

    # bean poles over the first bed on each side, lines strung between them
    for (u, v) in (beds[0], beds[3]):
        poles = []
        for row in (0, 2):
            c = v + 16 + 20 * row
            poles += [(k, c - 1, Z + 13, k + 2, c + 1, Z + 104) for k in range(u + 12, u + 190, 42)]
            m.rope([(u + 13, c, Z + 100), (u + 181, c, Z + 100)], slack=6, width=1)
            m.rope([(u + 13, c, Z + 62), (u + 181, c, Z + 62)], slack=6, width=1)
            greens = [vpipe(k + 1, c, 3, Z + 17 + 9 * j, Z + 23 + 9 * j, GRASS) for k in range(u + 12, u + 190, 42) for j in range(1 + (k // 42) % 4)]
            m.shapes(greens)
        m.det(poles, BEAM)

    # the scarecrow, in the middle bed on the right
    su, sv = 832, 508
    m.det([(su - 2, sv - 2, Z + 13, su + 2, sv + 2, Z + 96), (su - 30, sv - 1, Z + 76, su + 30, sv + 1, Z + 80)], BEAM)
    m.det([(su - 13, sv - 3, Z + 46, su + 13, sv + 3, Z + 82), (su - 30, sv - 2, Z + 70, su - 13, sv + 2, Z + 82), (su + 13, sv - 2, Z + 70, su + 30, sv + 2, Z + 82)], CLOTH)
    m.det([(su - 6, sv - 6, Z + 84, su + 6, sv + 6, Z + 97)], PLASTER)
    m.shapes([vpipe(su, sv, 11, Z + 97, Z + 99, TIN), vpipe(su, sv, 6, Z + 99, Z + 105, TIN)])

    # the flagstones of the path
    m.det([(616 + (k % 2) * 14, 348 + 62 * k, Z, 652 + (k % 2) * 14, 386 + 62 * k, Z + 2) for k in range(5)], STONE, top=STONE_FLOOR)

    # the tool lean-to against the back wall
    m.hut(560, 688, 720, 768, Z, WOOD, high=96, front="lo", open_front=True)
    m.det([(572, 740, Z, 708, 760, Z + 34)], BEAM, top=WOOD)
    m.det([(572, 752, Z + 60, 708, 760, Z + 62)], WOOD)
    for u in (590, 616, 690):
        m.loose("models/props_junk/terracotta01.mdl", u, 750, 0, z=Z + 34)
    m.loose("models/props_junk/metalbucket01a.mdl", 596, 716, 0, z=Z)
    m.loose("models/props_junk/shovel01a.mdl", 690, 712, 90, z=Z)
    m.shapes([prism([(746, Z), (750, Z), (724, Z + 72), (720, Z + 72)], "y", 716, 718, BEAM)])       # a hoe, leaning on the lean-to's side
    m.det([(744, 711, Z, 753, 723, Z + 2)], STEEL)
    m.lamp(640, 676, Z + 78, "255 200 130 90", hang=12)

    # the rain butt in the left corner, fed by pipes from the wall
    bu, bv = 348, 740
    m.shapes([vpipe(bu, bv, 20, Z + 4, Z + 50, WOOD, top=MAT["black"]), vpipe(bu, bv, 21, Z + 12, Z + 15, BARS), vpipe(bu, bv, 21, Z + 38, Z + 41, BARS),
              vpipe(bu, 762, 4, Z + 60, Z + 236, BARS), vpipe(bu, 762, 5, Z + 228, Z + 240, BARS),
              prism(octagon(762, Z + 234, 4), "x", bu, 556, BARS), prism(octagon(bu, Z + 60, 4), "y", bv, 766, BARS),
              vpipe(556, 762, 4, Z + 230, m.b.rim - 8, BARS), vpipe(556, 762, 5, Z + 228, Z + 240, BARS), vpipe(556, 762, 8, m.b.rim - 8, m.b.rim + 4, TIN, top=MAT["black"])])
    m.det([(u, 764, Z + 226, u + 4, 768, Z + 242) for u in (420, 500)] + [(bu - 6, 764, Z + 140, bu + 6, 768, Z + 144)], STEEL)
    m.det([(bu - 24, bv - 16, Z, bu - 8, bv + 16, Z + 4), (bu + 8, bv - 16, Z, bu + 24, bv + 16, Z + 4)], MAT["beam"])
    m.static("models/props_c17/oildrum001.mdl", 400, 744, 0, z=Z)

    # the compost bay in the right corner
    m.det([(868, 696, Z, 872, 768, Z + 34), (872, 696, Z, 956, 700, Z + 18), (868, 692, Z, 874, 698, Z + 38)], BEAM)
    m.shapes([prism([(702, Z), (766, Z), (756, Z + 26), (722, Z + 30)], "x", 874, 956, DIRT)])
    m.blocked(864, 688, 960, 768)

    # on the path: a push cart, a crate, melons
    m.loose("models/props_junk/pushcart01a.mdl", 696, 566, 95, z=Z)
    m.static("models/props_junk/wood_crate002a.mdl", 690, 400, 10, z=Z)
    for u, v in ((676, 452), (694, 462)):
        m.loose("models/props_junk/watermelon01.mdl", u, v, 30, z=Z)
    for v in (430, 560, 660):
        m.lane(640, v, Z)

    m.view(640, 120, F, 90, 0, "the gate from the canal")
    m.view(640, 330, Z, 90, 10, "coming in")
    m.view(640, 668, Z, 270, 12, "from the lean-to")
    m.view(590, 610, Z, 140, 0, "the rain butt")
    m.view(600, 500, Z, 215, 8, "the bean poles")
    m.view(650, 450, Z, 20, 6, "the scarecrow")


# ---------------------------------------------------------------------------
# 6. The stash
# ---------------------------------------------------------------------------

def rifle_rack(m, a, b, at, side, z, axis="u"):
    """A rack of long guns against a wall: a foot board, a back board, a notched rail, and a gun every 22.
    a..b along the wall, `at` the wall's line, side +1 or -1 the way the room is from it. axis: the way the wall runs."""
    def box(p1, q1, z1, p2, q2, z2):
        q1, q2 = at + side * q1, at + side * q2
        lo, hi = min(q1, q2), max(q1, q2)
        return (p1, lo, z1, p2, hi, z2) if axis == "u" else (lo, p1, z1, hi, p2, z2)
    m.det([box(a, 0, z, b, 14, z + 6), box(a, 0, z + 6, b, 3, z + 84), box(a, 3, z + 58, b, 13, z + 61), box(a, 0, z, a + 4, 14, z + 84), box(b - 4, 0, z, b, 14, z + 84)], BEAM)
    stocks, barrels = [], []
    for k in range(a + 12, b - 14, 22):
        if (k // 22) % 5 == 3:
            continue                                            # (an empty place: one is out)
        stocks.append(box(k, 4, z + 6, k + 6, 12, z + 30))
        barrels += [box(k + 1, 5, z + 30, k + 5, 10, z + 52), box(k + 2, 6, z + 52, k + 4, 9, z + 80)]
    m.det(stocks, WOOD)
    m.det(barrels, STEEL)


def m_stash(m, opt):
    """The stash: a secret arms room. From the canal there is only a run of rusted pipes on the left wall with a valve
    wheel on the thick one (lc_stash_valve: Use turns it a quarter, and it turns back by itself). Turning it slides a
    section of the wall itself aside (lc_stash_wall: 96 wide, 112 high, of the wall's own concrete, flush with it when
    shut, its sill at the top of the bank, 128 up); it shuts again by itself after 12 seconds, and the button on the
    wall just inside (lc_stash_inside) opens it from within. Behind: a short passage that turns twice, then the arms
    room (lc_stash_room: its middle): racks of long guns on two walls, a workbench with a vice under a map board,
    a planning table, shelves, crates.
    Unchecked: func_rot_button (the valve wheel) is from memory, with its turning axis set by spawnflag 64 or 128 (the
    map's x or y, whichever way the module is turned): if the wheel turns the wrong way round or not at all, the door
    still needs only one Open sent to lc_stash_wall. The door slides a little inward as well as aside (its movedir is
    2 degrees off the wall's line) so that, open, it does not lie in the wall's own face. Sounds doors/doormove1.wav and
    doormove2.wav are the bunker doors' own."""
    L, Z = 768, F + 128
    m.open(0, -256, L, 256)
    m.low(192, 256, 320, 384, Z + 112, floor=Z)                 # behind the wall, and the first turn
    m.low(320, 320, 384, 384, Z + 112, floor=Z)                 # the second
    m.low(384, 320, 704, 576, Z + 128, floor=Z, mat=CRACKED)    # the arms room
    m.side(128, 256, L, 640)
    m.world((192, 256, Z, 208, 320, Z + 112), WALL)             # the jambs: the way through is 96 wide
    m.world((304, 256, Z, 320, 320, Z + 112), WALL)
    m.portal(208, 263, Z, 304, 265, Z + 112)
    slide_door(m, "lc_stash_wall", [((208, 256, Z, 304, 272, Z + 112), WALL)], "0 %d 0" % m.fr.yaw(2), speed=32, lip=0, wait="12", toggle=False,
               sounds=("doors/doormove1.wav", "doors/doormove2.wav"))
    m.det([(192, 240, TRIM, 320, 256, TRIM + 16)], MAT["beam"])                              # the trim line, carried over the door's squares
    m.taken(16, 200, F + 60, 340, 256, F + 250)

    # the pipes on the wall, and the valve
    vu, vz = 120, F + 180
    m.shapes([prism(octagon(246, vz, 8), "x", 40, 176, BARS),                                # the thick pipe: out of the wall, along it, down into the bank
              prism(octagon(40, vz, 8), "y", 238, 256, BARS), vpipe(176, 246, 8, F + 84, vz + 8, BARS),
              prism(octagon(250, F + 214, 4), "x", 64, 150, BARS),                           # the thin one: along, then up and into the wall
              prism(octagon(64, F + 214, 4), "y", 246, 256, BARS), vpipe(150, 250, 4, F + 210, F + 246, BARS), prism(octagon(150, F + 246, 4), "y", 246, 256, BARS),
              prism(octagon(88, vz + 14, 5), "y", 236, 240, STEEL)])                         # a gauge
    m.det([(u - 3, 250, vz - 12, u + 3, 256, vz + 12) for u in (64, 152)] + [(u - 2, 252, F + 208, u + 2, 256, F + 220) for u in (96, 128)]
          + [(87, 240, vz + 8, 89, 246, vz + 12)], STEEL)
    m.det([(vu - 9, 236, vz - 10, vu + 9, 256, vz + 10)], STEEL)                             # the valve's body
    m.shapes([prism(octagon(vu, vz, 3), "y", 228, 236, BARS)])                               # its stem
    axis = 64 if m.fr.ax("v") == "x" else 128
    shape_entity(m, "func_rot_button", {
        "targetname": "lc_stash_valve", "origin": "%d %d %d" % (m.fr.pt(vu, 226) + (vz,)), "distance": "90", "speed": "60", "wait": "4", "sounds": "0", "health": "0",
        "spawnflags": str(1024 + axis), "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
        shapes=ring("y", vu, vz, 12, 15, 224, 228, BARS),
        boxes=[(vu - 13, 225, vz - 1, vu + 13, 227, vz + 1), (vu - 1, 225, vz - 13, vu + 1, 227, vz + 13), (vu - 3, 223, vz - 3, vu + 3, 229, vz + 3)], mat=BARS,
        connections=[("OnPressed", "lc_stash_wall", "Open", "", 0)])

    # just inside: the button that opens it from within, a dim lamp
    m.button("lc_stash_inside", 192, 350, Z + 40, 0, [("lc_stash_wall", "Open", "", 0)])
    m.lamp(256, 340, Z + 100, "255 200 140 45")
    m.static("models/props_junk/wood_crate001a.mdl", 290, 300, 0, z=Z)
    m.lane(256, 336, Z)
    m.lane(352, 352, Z)

    # the arms room
    m.target("lc_stash_room", 544, 448, Z + 8, 0)
    rifle_rack(m, 400, 584, 576, -1, Z)                                                      # along the back wall
    rifle_rack(m, 408, 560, 384, 1, Z, axis="v")                                             # and the wall beside the way in
    m.static("models/props_c17/shelfunit01a.mdl", 648, 562, 0, z=Z)
    m.det([(546, 438, Z + 37, 562, 450, Z + 45), (548, 440, Z + 45, 562, 450, Z + 53), (566, 456, Z + 37, 580, 468, Z + 45)], TIN)   # boxes of rounds, on the table
    # the workbench under the map board, on the wall toward the canal
    m.det([(440, 322, Z + 32, 616, 354, Z + 36)], WOOD)
    m.det([(444, 324, Z, 450, 350, Z + 32), (606, 324, Z, 612, 350, Z + 32), (450, 326, Z + 10, 606, 330, Z + 14)], BEAM)
    m.det([(580, 340, Z + 36, 596, 352, Z + 42), (584, 346, Z + 42, 592, 356, Z + 48), (586, 356, Z + 44, 590, 362, Z + 46)], STEEL)   # the vice
    m.det([(470, 334, Z + 36, 500, 338, Z + 38), (512, 330, Z + 36, 516, 350, Z + 37), (524, 340, Z + 36, 548, 346, Z + 40)], STEEL)   # tools, a part
    m.det([(456, 320, Z + 52, 600, 323, Z + 116)], BEAM)
    m.det([(462, 323, Z + 56, 594, 324, Z + 112)], PLASTER)
    m.det([(466, 324, Z + 80, 590, 325, Z + 84), (520, 324, Z + 60, 524, 325, Z + 108), (466, 324, Z + 98, 520, 325, Z + 100), (524, 324, Z + 66, 590, 325, Z + 68),
           (560, 324, Z + 84, 562, 325, Z + 108)], MAT["black"])                                 # the canals, drawn on it
    m.det([(u, 324, z, u + 2, 326, z + 2) for u, z in ((480, Z + 90), (540, Z + 74), (572, Z + 100), (504, Z + 64))], STEEL)       # pins
    m.lamp(528, 348, Z + 104, "255 215 160 70", hang=24)
    # the planning table, crates
    m.static("models/props_c17/furnituretable001a.mdl", 560, 452, 0, z=Z)
    m.static("models/props_c17/furniturechair001a.mdl", 600, 452, 180, z=Z)
    m.static("models/props_junk/wood_crate002a.mdl", 676, 372, 0, z=Z)
    m.static("models/props_junk/wood_crate001a.mdl", 676, 430, 15, z=Z)
    m.static("models/props_junk/wood_crate001a.mdl", 674, 372, 5, z=Z + 40)
    m.lamp(544, 448, Z + 112, "255 220 170 150", hang=16)
    m.lane(544, 400, Z)

    m.view(150, 40, F, 75, -8, "the pipes: nothing to see")
    m.view(256, 150, F + 40, 90, -12, "on the bank, at the wall that opens")
    m.view(256, 356, Z, 270, 4, "inside, looking back at the wall")
    m.view(400, 350, Z, 30, 8, "the arms room")
    m.view(680, 540, Z, 215, 10, "the workbench and the map")


# ---------------------------------------------------------------------------
# 7. The black market
# ---------------------------------------------------------------------------

def m_market(m, opt):
    """The black market: a vaulted arcade inside the left wall, entered from the canal's floor by two archways.
    Five stalls in alcoves along its back, each with a counter (crouch under its left end to get behind it), shelves
    of goods, a lamp, a crate to sit on, and a tin roll shutter over the counter (lc_market_shutter_1 to _5: each
    lifts and drops when the button inside its own stall is pressed, lc_market_button_1 to _5, or when the game
    sends Open or Close). lc_market_stall_1 to _5 are where the stallholders stand, facing out. A brazier burns in
    the middle of the arcade, benches by it; a lookout's stool stands inside each archway, where the canal can be
    watched both ways; ribs carry the vault at every pier.
    Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look (the same settings as the vortigaunt
    culvert's fire); a shutter starts shut, and nothing but its button or the game opens it."""
    L, H, A = 1280, F + 176, F + 128
    m.open(0, -256, L, 256)
    m.low(128, 320, 1152, 512, H, mat=STONE_FLOOR)                  # the arcade
    arches = (256, 896)
    for au in arches:
        m.low(au, 256, au + 128, 320, A, mat=STONE_FLOOR)
        m.portal(au, 286, F, au + 128, 288, A)
        cheeks(m, au, au + 128)
        m.taken(au - 24, 110, F, au + 152, 256, F + 170)
        # the arch: a chamfer in each top corner, a keystone
        m.shapes([prism([(au, A - 44), (au + 36, A), (au, A)], "y", 256, 320, MAT["beam"]), prism([(au + 128, A - 44), (au + 92, A), (au + 128, A)], "y", 256, 320, MAT["beam"])])
        m.det([(au + 54, 250, A - 6, au + 74, 256, A + 18)], MAT["beam"])
        m.lane(au + 64, 288)
        m.lane(au + 64, 400)
    stalls = (192, 384, 576, 768, 960)
    for su in stalls:
        m.low(su, 512, su + 128, 640, A, mat=STONE_FLOOR)
    m.side(64, 256, 1216, 704)
    for ru in (136, 352, 544, 736, 928, 1128):
        arch_rib(m, ru - 8, ru + 8, 320, 512, H, 72, MAT["beam"])

    themes = ((PLASTER, TIN, BEAM), (CLOTH, CLOTH, PLASTER), (STEEL, BARS, TIN), (PLASTER, PLASTER, TIN), (TIN, BEAM, STEEL))
    for k, su in enumerate(stalls):
        n = k + 1
        # the counter: its top runs the whole front, its foot leaves the left 40 open to crouch through
        m.det([(su + 40, 514, F, su + 128, 528, F + 38)], BRICK)
        m.det([(su, 510, F + 38, su + 128, 532, F + 41)], WOOD)
        # the shutter, and the box it rolls up into
        slide_door(m, "lc_market_shutter_%d" % n, [((su, 507, F + 42, su + 128, 509, A), TIN), ((su, 506, F + 42, su + 128, 510, F + 46), BARS)],
                   "-90 0 0", speed=50, lip=6)
        m.det([(su - 4, 500, A - 4, su + 132, 512, A + 22)], TIN)
        m.det([(su - 4, 504, F, su, 512, A - 4), (su + 128, 504, F, su + 132, 512, A - 4)], BARS)
        m.button("lc_market_button_%d" % n, su, 600, F + 44, 0, [("lc_market_shutter_%d" % n, "Toggle", "", 0)])
        m.target("lc_market_stall_%d" % n, su + 76, 566, F + 8, 270)
        goods(m, su + 8, su + 120, 640, -1, F, (26, 52, 78), 40 + k, kinds=themes[k], jars=0.5 if k in (0, 3) else 0.1)
        m.lamp(su + 64, 572, A - 14, "255 205 140 75", hang=6)
        m.static("models/props_junk/wood_crate001a.mdl", su + 100, 590, 10 * k)
        # what is laid out on the counter
        rnd = random.Random(70 + k)
        m.det([(u, 514, F + 41, u + rnd.choice((8, 12, 16)), 526, F + 41 + rnd.randrange(3, 9)) for u in range(su + 46, su + 110, 22)], themes[k][0])
        m.lane(su + 64, 470)
    m.static("models/props_c17/shelfunit01a.mdl", 1126, 420, 90)        # the end of the arcade: spare stock

    # the middle of the arcade: a brazier, benches, lamps along the roof
    bu, bv = 640, 400
    m.shapes([vpipe(bu, bv, 16, F + 12, F + 30, BARS, top=MAT["black"]), vpipe(bu, bv, 18, F + 28, F + 31, BARS)])
    m.det([(bu + du, bv + dv, F, bu + du + 3, bv + dv + 3, F + 14) for du in (-12, 9) for dv in (-12, 9)], BARS)
    fire(m, bu, bv, F + 30, size=20, light="255 160 80 130")
    m.sound("ambient/fire/fire_small_loop1.wav", bu, bv, F + 40, radius=420, volume=3)
    m.det([(bu - 70, bv - 12, F + 14, bu - 44, bv + 44, F + 17), (bu + 44, bv - 44, F + 14, bu + 70, bv + 12, F + 17)], WOOD)
    m.det([(bu - 66, bv - 8, F, bu - 48, bv + 2, F + 14), (bu - 66, bv + 30, F, bu - 48, bv + 40, F + 14),
           (bu + 48, bv - 40, F, bu + 66, bv - 30, F + 14), (bu + 48, bv - 2, F, bu + 66, bv + 8, F + 14)], MAT["beam"])
    m.blocked(bu - 80, bv - 60, bu + 80, bv + 60)
    for u in (448, 832):
        m.lamp(u, 416, H - 30, "255 210 150 120", hang=22)
    # the lookouts' stools, inside each archway on the side they watch from
    for su in (232, 1048):
        m.shapes([vpipe(su, 340, 9, F + 20, F + 23, WOOD), vpipe(su, 340, 3, F, F + 20, BARS)])
    m.det([(130, 440, F, 150, 500, F + 1), (1100, 330, F, 1150, 400, F + 1)], CLOTH)                 # a rug at each end
    m.static("models/props_junk/wood_crate002a.mdl", 160, 470, 80)
    m.decal("decals/decalposter014a", 352, 512, F + 90)
    m.decal("decals/decal_posters005a", 928, 512, F + 88)

    m.view(320, 120, F, 90, 0, "an archway from the canal")
    m.view(180, 416, F, 0, 2, "down the arcade")
    m.view(640, 340, F, 80, 2, "the brazier and the stalls")
    m.view(480, 440, F, 115, 4, "a stall")
    m.view(470, 600, F, 300, 6, "behind a counter")


MODULES = {
    "cells": (1024, m_cells, "the cells: a guard room, three barred cells, a crawl duct out (left)"),
    "memorial": (768, m_memorial, "the wall of the dead: plaques and candles in a recess under the open sky (left)"),
    "pit": (1280, m_pit, "the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left)"),
    "garden": (1280, m_garden, "the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left)"),
    "stash": (768, m_stash, "the stash: an arms room behind a section of wall that a pipe valve opens (left)"),
    "market": (1280, m_market, "the black market: a vaulted arcade of five shuttered stalls (left)"),
    "clinic": (1024, m_clinic, "the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left)"),
}
