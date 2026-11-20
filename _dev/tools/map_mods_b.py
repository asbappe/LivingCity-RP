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


MODULES = {
    "cells": (1024, m_cells, "the cells: a guard room, three barred cells, a crawl duct out (left)"),
    "memorial": (768, m_memorial, "the wall of the dead: plaques and candles in a recess under the open sky (left)"),
    "clinic": (1024, m_clinic, "the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left)"),
}
