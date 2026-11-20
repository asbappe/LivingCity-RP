#!/usr/bin/env python3
"""
Living City: canal modules, set B: places where the Resistance lives (map_modules.py picks this file up by itself)

    cells      where captured units are kept: a guard room, three barred cells, a crawl duct out
    clinic     a field hospital in a vault: a ward, an operating table, a dispensary, a sluice room
    memorial   the wall of the dead: plaques and candles in a recess under the open sky
    pit        a fighting pit: a caged sunken ring, bleachers, a bookmaker
    garden     a walled garden: soil beds, a rain butt, a lean-to, a scarecrow
    stash      a secret arms room behind a section of canal wall that a pipe valve opens
    market     the black market: a vaulted arcade of five stalls with roll shutters
    press      the pamphlet press: a printing room behind a false stack of crates
    still      a distillery in a cellar: a pot still, mash casks, shelves of bottles
    plaza      half a round amphitheatre of five tiers, a rostrum at the canal's edge
    playground a rusted playground on a terrace: a relic of before

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


def swing_door(m, name, boxes, mat, hinge, speed=90, wait="-1", reverse=False, sound="doors/doormove1.wav", unseen=False):
    """A door a player opens by Use: it swings 90 degrees round `hinge` (u, v, z), anticlockwise seen from above
    (reverse: clockwise), and stays until used again. boxes: (box) or (box, material). unseen: the brush is not drawn
    (it blocks and turns; a model rides on it: see rider)."""
    out = [(m.fr.box(*b[0]), b[1]) if len(b) == 2 else m.fr.box(*b) for b in boxes]
    m.b.vmf.brush_entity("func_door_rotating", {
        "targetname": name, "origin": "%d %d %d" % (m.fr.at(hinge[0], hinge[1], hinge[2])), "distance": "90", "speed": str(speed), "wait": wait, "lip": "0",
        "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": str(32 + 256 + (2 if reverse else 0)), "noise1": sound, "health": "0",
        "ignoredebris": "0", "loopmovesound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "10" if unseen else "0",
        "renderamt": "0" if unseen else "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"}, out, MAT["nodraw"] if unseen else mat, m.dv)
    m.b.names.append((name, "func_door_rotating", m.tag))


def slide_door(m, name, parts, movedir, speed=40, lip=0, wait="-1", toggle=True, sounds=("MetalGrate.ScrapeSmooth", "MetalGrate.ImpactSoft"), starts_open=False,
               unseen=False):
    """A sliding door of more than one material, told to move by name (Open, Close, Toggle), never by a player's Use.
    parts: [(box, material), ...]. wait: seconds before it shuts by itself ("-1": it stays). unseen: the brush is not
    drawn (it blocks and moves; a model rides on it: see rider)."""
    out = [(m.fr.box(*b), MAT["nodraw"] if unseen else mat) for b, mat in parts]
    m.b.vmf.brush_entity("func_door", {
        "targetname": name, "movedir": movedir, "speed": str(speed), "lip": str(lip), "wait": wait, "spawnflags": "32" if toggle else "0", "spawnpos": "1" if starts_open else "0", "dmg": "0",
        "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "noise1": sounds[0], "noise2": sounds[1], "locked_sentence": "0",
        "unlocked_sentence": "0", "renderamt": "0" if unseen else "255", "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "10" if unseen else "0",
        "disableshadows": "1"}, out, out[0][1], m.dv)
    m.b.names.append((name, "func_door", m.tag))


def rider(m, door, model, u, v, yaw, z):
    """The model an unseen door wears: a prop_dynamic standing on z that rides on the door named `door` (not solid: the
    door's own brush does the blocking)."""
    m.prop("prop_dynamic", model, u, v, yaw, z, {"parentname": door, "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                                                "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})


WAY = {0: (1, 0), 90: (0, 1), 180: (-1, 0), 270: (0, -1)}


def dome(m, u, v, ceil, colour):
    """A dome light on a roof at `ceil`, and its light."""
    m.static("models/props_c17/light_domelight02_on.mdl", u, v, 0, z=ceil - 7)
    m.light(u, v, ceil - 20, colour)


def bell(m, u, v, ceil, colour):
    """An industrial bell lamp hung under a roof or beam at `ceil`, and its light."""
    m.static("models/props_c17/light_industrialbell01_on.mdl", u, v, 0, z=ceil - 23)
    m.light(u, v, ceil - 34, colour)


def cage(m, u, v, z, out, colour):
    """A caged lamp on a wall at (u, v), its foot at z, facing `out` (a yaw in the module), and its light."""
    m.static("models/props_c17/light_cagelight02_on.mdl", u, v, out, z=z)
    du, dv = WAY[out]
    m.light(u + 14 * du, v + 14 * dv, z + 6, colour)


def put(m, things, z, u0=0, v0=0):
    """Small things stood on a surface at z: [(model's short name under models/, du, dv, yaw), ...] from (u0, v0)."""
    for name, du, dv, yaw in things:
        m.static("models/%s.mdl" % name, u0 + du, v0 + dv, yaw, z=z)


def cheeks(m, u1, u2, top=136, out=132, thick=12):
    """Where the left wall's bank is cut for a way in (u1 to u2), a retaining wall on each side of the cut, its top
    sloping with the bank it holds back. Nothing on a street (a lifted module): there is no bank there."""
    if m.fr.dz:
        return
    shape = [(256, F), (256 - out, F), (256 - out, F + 14), (256, F + top)]
    m.shapes([prism(shape, "x", u1 - thick, u1, MAT["beam"]), prism(shape, "x", u2, u2 + thick, MAT["beam"])])


def candle(m, u, v, z, high=6, light=True):
    """A candle stub: an octagon 4 across (no model of one exists), its flame a glow, and a small steady warm light."""
    m.shapes([vpipe(u, v, 2, z, z + high, PLASTER)])
    m.glow(u, v, z + high + 3, "255 200 120", 0.08)
    if light:
        m.light(u, v, z + high + 6, "255 170 90 7")


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

def cell_front(m, cu, door, window, H):
    """A cell's front wall, 8 thick, with a way through for its door and a hole for its barred window."""
    cuts = sorted([cu, door[0], door[1], window[0], window[1], cu + 128])
    boxes = []
    for a, b in zip(cuts, cuts[1:]):
        if (a, b) == tuple(door):
            boxes.append((a, 536, F + 104, b, 544, H))
        elif (a, b) == tuple(window):
            boxes += [(a, 536, F, b, 544, F + 48), (a, 536, F + 102, b, 544, H)]
        elif a < b:
            boxes.append((a, 536, F, b, 544, H))
    m.det(boxes, MAT["beam"])


def m_cells(m, opt):
    """The cells: where the Resistance keeps captured Combine units. A heavy steel door at the foot of the left wall
    (lc_cells_entry: Use swings it in) opens on a guard room (a table, a chair, lockers, a bench, a board with the
    padlocks on it). A corridor runs on past three cells, each 128 by 160 behind a wall with a barred window and a
    barred door (lc_cells_door_1 to _3) that slides aside behind the wall when the button beside it on the corridor's
    pier is pressed (lc_cells_button_1 to _3, tally marks over each say which) or the game sends Open, Close or
    Toggle. A mattress, a bucket and a toilet in each; lc_cells_spot_1 to _3 are where a prisoner stands. The far cell
    has a loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it) onto a crawl duct 40
    high that comes out at the canal's floor through a concrete pipe: the way to break out, or in.
    The doors are Nova Prospekt's models (prison_heavydoor001a, prison_celldoor001a) riding on unseen brush doors
    of the same names and inputs as before; the windows are prison_cellwindow002a with an unseen wall in them.
    Left as brushes: the grate (no model 62 by 38), the tally marks and scratches (paint, not things).
    Unchecked: which way the door, window, bench and board models face (each is thin along its x, so its face looks
    along x: turned here to look along v); the sound ambient/atmosphere/tunnel1.wav; whether a prisoner's Use can
    reach a button round the pier's corner; the doors' sounds (doors/doormove1.wav, doors/gate_move1.wav)."""
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

    # the way in: a heavy door in a cut in the bank, a caged lamp over it
    cheeks(m, 128, 192)
    swing_door(m, "lc_cells_entry", [(129, 284, F + 1, 191, 290, F + 111)], STEEL, (129, 287, F + 56), unseen=True)
    rider(m, "lc_cells_entry", "models/props_wasteland/prison_heavydoor001a.mdl", 160, 287, 90, F)
    m.det([(124, 250, F + 112, 196, 256, F + 120)], MAT["beam"])
    cage(m, 160, 256, F + 136, 270, "255 200 140 90")
    m.lane(160, 288)

    # the guard room
    m.static("models/props_c17/furnituretable002a.mdl", 232, 420, 0)
    m.static("models/props_c17/furniturechair001a.mdl", 232, 372, 90)
    m.static("models/props_c17/lockers001a.mdl", 74, 452, 0)
    m.static("models/props_c17/bench01a.mdl", 78, 364, 0)
    m.static("models/props_lab/corkboard001.mdl", 264, 512, 270, z=F + 50)                # the board, and the padlocks hung on it
    put(m, [("props_wasteland/prison_padlock001a", 236 + 14 * k, 505, 270) for k in (0, 1, 2, 4)], F + 66)
    m.static("models/props_wasteland/prison_lamp001c.mdl", 200, 416, 0, z=H - 12)
    m.light(200, 416, H - 26, "255 205 150 110")
    m.det([(316, 384, F, 320, 392, H), (316, 504, F, 320, 512, H), (316, 384, H - 8, 320, 512, H)], STEEL)    # the frame of the way through
    m.static("models/props_junk/wood_crate001a.mdl", 284, 350, 10)                        # what was taken off the prisoners
    m.decal("decals/decalposter014a", 64, 400, F + 80)
    m.lane(200, 448)

    # the corridor and the cells
    for u in (448, 672):
        m.static("models/props_wasteland/prison_lamp001c.mdl", u, 448, 0, z=H - 12)
        m.light(u, 448, H - 26, "215 220 200 70")
    m.static("models/props_wasteland/prison_pipes001a.mdl", 576, 400, 0, z=H - 20)        # pipes under the corridor's roof
    m.static("models/props_c17/chair_stool01a.mdl", 808, 404, 0)                          # the guard's stool at the corridor's end
    for k, cu in enumerate(cells):
        n = k + 1
        last = k == 2
        door = (cu + 6, cu + 58) if last else (cu + 70, cu + 122)        # (the far cell's door is on its near half: its button is on the pier too)
        window = (cu + 76, cu + 112) if last else (cu + 16, cu + 52)
        cell_front(m, cu, door, window, H)
        name = "lc_cells_door_%d" % n
        slide_door(m, name, [((door[0], 544, F, door[1], 548, F + 104), STEEL)], "0 %d 0" % m.fr.yaw(0 if last else 180), speed=48, lip=0, unseen=True)
        rider(m, name, "models/props_wasteland/prison_celldoor001a.mdl", door[0] + 26, 546, 90, F)
        m.static("models/props_wasteland/prison_cellwindow002a.mdl", window[0] + 18, 540, 90, z=F + 48)
        m.world((window[0], 539, F + 48, window[1], 541, F + 102), MAT["clip"], seals=False)
        bu = cu - 20 if last else cu + 148                          # on the pier's face, 16 or more past the cell's edge
        m.button("lc_cells_button_%d" % n, bu, 512, F + 40, 270, [(name, "Toggle", "", 0)])
        m.det([(bu - 2 * n + 4 * j, 511, F + 72, bu - 2 * n + 4 * j + 2, 512, F + 84) for j in range(n)], PLASTER)
        m.target("lc_cells_spot_%d" % n, cu + 64, 624, F + 8, 270)
        m.loose("models/props_c17/furnituremattress001a.mdl", cu + 30, 640, 90)
        m.loose("models/props_junk/metalbucket01a.mdl", cu + 108, 580, 0)
        m.static("models/props_wasteland/prison_toilet01.mdl", cu + (40 if last else 100), 694, 0)
        m.static("models/props_wasteland/prison_lamp001c.mdl", cu + 64, 620, 0, z=H - 12)
        m.light(cu + 64, 620, H - 26, "200 205 185 22")
        m.lane(cu + 64, 448)
    m.det([(639, 596 + 4 * j, F + 70, 640, 598 + 4 * j, F + 80) for j in range(9)]
          + [(639, 594, F + 74, 640, 632, F + 76)], PLASTER)                            # days scratched on the middle cell's wall

    # the far cell's loose grate, the duct, and the concrete pipe it comes out through (in a canal: the bank is cut for it)
    slats = [(833, 641, F + 1 + 8 * j, 836, 703, F + 5 + 8 * j) for j in range(5)]
    swing_door(m, "lc_cells_grate", slats + [(833, 641, F + 1, 837, 645, F + 39), (833, 699, F + 1, 837, 703, F + 39)], BARS, (835, 643, F + 20),
               sound="doors/gate_move1.wav")
    if not m.fr.dz:
        m.prop("prop_static", "models/props_pipes/concrete_pipe001a.mdl", 928, 198, 90, F - 6, {"solid": "0", "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0",
                                                                                          "fadescale": "1"})
    m.sound("ambient/atmosphere/tunnel1.wav", 576, 448, F + 96, radius=500, volume=3)

    m.view(160, 180, F, 90, 0, "the door in the wall")
    m.view(110, 350, F, 40, 4, "the guard room")
    m.view(336, 448, F, 0, 2, "the corridor")
    m.view(736, 448, F, 80, 6, "the far cell from the corridor")
    m.view(730, 560, F, 20, 20, "in the far cell: the grate")
    m.view(928, 60, F, 90, 0, "the concrete pipe")


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


BED_YAW = 90     # the way the clinic's bed frames are turned (their long side is the model's x): 270 puts their heads the other way


# ---------------------------------------------------------------------------
# 2. The clinic
# ---------------------------------------------------------------------------

def m_clinic(m, opt):
    """The clinic: a field hospital in a vault off the left wall, whitewashed and tiled against the canal's concrete.
    A wide way in between two drawn curtains (a white cross on the wall over it); a ward of four beds along its back wall
    with cloth screens between them (lc_clinic_bed_1 to _4: where a patient lies), a mattress and a bedside drawer
    each, a hospital cart, a stove, a bench; a dispensary nook behind a shop's display counter (walk round its left
    end), kitchen shelves behind, jars and kits on it; through a curtained opening an operating theatre with a long
    steel-legged table under a bell lamp that shines straight down (lc_clinic_table: on the table), a cart, a closet
    and shelves; and off the theatre a sluice room with a sink, a boiler, a bucket and a floor grille.
    Left as brushes: the curtains and the screens between the beds (cloth: no model), the white cross (paint), the
    theatre's door frame.
    Unchecked: the sound ambient/water/leak_1.wav; which end of a bed frame is its head, and which way the sink,
    stove, radiator, drawers, closet, boiler and shelves face (sizes and places are from the models' own files;
    BED_YAW turns the frames); how the loose mattresses settle on the frames."""
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

    # the way in: a white cross on the wall, a caged lamp, two curtains drawn aside under a valance
    m.det([(474, 254, F + 168, 486, 256, F + 212), (458, 254, F + 184, 502, 256, F + 196)], PLASTER)
    cage(m, 480, 256, F + 150, 270, "235 240 225 80")
    cloth = []
    for k in range(7):
        dv = 2 if k % 2 else 0
        cloth.append((386 + 8 * k, 350 + dv, F + 2, 394 + 8 * k, 352 + dv, F + 124))
        cloth.append((518 + 8 * k, 350 + dv, F + 2, 526 + 8 * k, 352 + dv, F + 124))
    cloth.append((386, 349, F + 122, 574, 355, F + 136))
    m.det(cloth, PLASTER)
    m.det([(384, 351, F + 136, 576, 353, F + 138)], BARS)
    m.lane(480, 352)

    # the ward: four beds, a screen between each, a drawer at every bed
    for k in range(4):
        u, n = 200 + 128 * k, k + 1
        m.static("models/props_wasteland/prison_bedframe001b.mdl", u, 716, BED_YAW)
        m.loose("models/props_c17/furnituremattress001a.mdl", u, 716, BED_YAW, z=F + 31)
        m.static("models/props_c17/furnituredrawer002a.mdl", u + 42, 754, 270)
        m.target("lc_clinic_bed_%d" % n, u, 716, F + 28, 270)
        if k < 3:
            s = u + 64
            m.det([(s - 1, 652, F + 10, s + 1, 764, F + 78)], PLASTER)
            m.det([(s - 1, 650, F, s + 1, 652, F + 80), (s - 1, 764, F, s + 1, 766, F + 80), (s - 1, 650, F + 78, s + 1, 766, F + 80),
                   (s - 8, 650, F, s + 8, 652, F + 2), (s - 8, 764, F, s + 8, 766, F + 2)], BARS)
    m.static("models/props_c17/furnitureradiator001a.mdl", 136, 520, 0)
    m.static("models/props_trainstation/bench_indoor001a.mdl", 148, 644, 0)                  # a bench for whoever waits
    m.static("models/props_c17/furnituretable001a.mdl", 656, 500, 0)                         # the nurse's table
    m.static("models/props_c17/furniturechair001a.mdl", 656, 544, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 352, 474, 90)
    m.static("models/props_c17/hospital_cart01.mdl", 300, 620, 20)
    for u in (264, 520):
        dome(m, u, 590, F + 158, "235 240 228 130")
    for u, v in ((200, 600), (456, 600), (640, 560)):
        m.lane(u, v)

    # the dispensary nook: a display counter across its front, shelves behind, what is given out on the counter
    m.static("models/props_c17/display_cooler01a.mdl", 252, 446, 0)
    m.static("models/props_wasteland/kitchen_shelf001a.mdl", 176, 340, 0)
    m.static("models/props_wasteland/kitchen_shelf001a.mdl", 272, 340, 0)
    put(m, [("props_lab/jar01a", 216, 446, 0), ("props_lab/jar01b", 232, 452, 30), ("props_lab/jar01a", 250, 440, 60), ("items/healthkit", 274, 446, 100),
            ("props_junk/glassjug01", 294, 450, 0)], F + 50)
    dome(m, 224, 392, F + 126, "255 215 160 80")
    m.lane(224, 392)

    # through to the theatre: a steel frame and one curtain, drawn back
    m.det([(732, 576, F, 740, 580, F + 126), (732, 700, F, 740, 704, F + 126), (732, 576, F + 118, 740, 704, F + 126)], STEEL)
    m.det([(735, 580 + 6 * k, F + 2, 737, 586 + 6 * k, F + 118) for k in range(0, 5, 2)]
          + [(733, 586 + 6 * k, F + 2, 735, 592 + 6 * k, F + 118) for k in range(0, 4, 2)], PLASTER)
    m.lane(736, 640)

    # the operating theatre: the table under its lamp, a cart, a closet, shelves
    cu, cv = 864, 640
    m.static("models/props_wasteland/cafeteria_table001a.mdl", cu, cv, 0)
    m.target("lc_clinic_table", cu, cv, F + 36, 270)
    bell(m, cu, cv, F + 174, "240 244 235 60")
    m.spot(cu, cv, F + 148, "255 250 235 900", 0, pitch=90, cone=56)
    m.static("models/props_c17/hospital_cart01.mdl", 924, 580, 0)
    m.static("models/props_wasteland/kitchen_shelf002a.mdl", 864, 744, 270)
    m.static("models/props_wasteland/controlroom_storagecloset001a.mdl", 792, 730, 0)
    m.lane(820, 520)

    # the sluice room: a narrowed way in, the sink, a boiler, a grille in the floor
    m.det([(832, 444, F, 864, 448, F + 128), (928, 444, F, 960, 448, F + 128)], TILE)
    m.static("models/props_interiors/sinkkitchen01a.mdl", 880, 336, 90)
    m.static("models/props_c17/furnitureboiler001a.mdl", 936, 352, 180)
    m.static("models/props_vents/vent_large_grill001.mdl", 896, 400, 0, z=F + 1)
    m.loose("models/props_junk/metalbucket01a.mdl", 852, 420, 0)
    dome(m, 896, 384, F + 126, "225 235 235 45")
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
    with a ledge at its foot where candle stubs burn steadily among framed pictures, bottles, tins and pots; a tall
    candlestick at each end of it, posters on the side walls, a line strung across, and a bench out in the canal
    facing it. lc_memorial_wall is the middle of the wall, facing out: the game may one day list there the names of
    characters who died for good.
    Left as brushes: the stone wall, its plaques and the candle stubs (Half-Life 2 has no plaque and no candle).
    Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind); which way the picture frames
    face; the candlesticks are Lost Coast's (lostcoast/props_monastery/candlestick). No flowers: there is no model."""
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

    # what people leave: candle stubs on the ledge and at its foot, pictures, bottles, tins, pots
    for k, (u, high) in enumerate(((236, 5), (251, 3), (270, 7), (296, 4), (309, 6), (338, 3), (352, 8), (377, 5), (391, 4), (415, 7), (440, 3),
                                   (458, 6), (476, 4), (497, 8), (512, 5), (531, 3))):
        candle(m, u, 370 + (k * 5) % 7, Z + 24, high, light=k % 2 == 0)
    for k, (u, v, high) in enumerate(((300, 356, 4), (310, 349, 7), (322, 358, 3), (384, 350, 6), (396, 357, 4), (452, 352, 5), (468, 359, 8), (250, 354, 3))):
        candle(m, u, v, Z, high, light=k % 2 == 1)
    put(m, [("props_lab/frame002a", 326, 374, 270), ("props_lab/frame002a", 406, 374, 270), ("props_lab/frame002a", 488, 374, 270),
            ("props_junk/glassbottle01a", 262, 372, 0), ("props_junk/glassbottle01a", 366, 372, 0), ("props_junk/glassbottle01a", 448, 372, 0),
            ("props_junk/metal_paintcan001a", 284, 372, 0), ("props_junk/popcan01a", 430, 371, 0), ("props_junk/metal_paintcan001a", 524, 372, 0)], Z + 24)
    put(m, [("props_junk/terracotta01", 360, 354, 0), ("props_junk/terracotta01", 500, 352, 40)], Z)
    for u in (210, 558):                                                                 # a tall candlestick at each end
        m.static("models/lostcoast/props_monastery/candlestick.mdl", u, 364, 270, z=Z)
        m.glow(u, 364, Z + 106, "255 200 120", 0.12)
        m.light(u, 364, Z + 112, "255 170 90 14")
    m.decal("decals/decalposter014a", 192, 316, Z + 96)
    m.decal("decals/decal_posters005a", 576, 322, Z + 100)
    m.decal("decals/decal_posters005a", 208, 384, Z + 120)
    m.rope([(194, 300, Z + 216), (574, 300, Z + 216)], slack=70)

    # the bench out in the canal, facing the wall (far enough out to stand on a street's pavement too)
    m.static("models/props_trainstation/benchoutdoor01a.mdl", 384, 180, 90)
    m.blocked(320, 160, 448, 200)
    m.lane(384, 216)
    m.lane(384, 312, Z)
    m.sound("ambient/levels/canals/windmill_wind_loop1.wav", 384, 300, Z + 160, radius=600, volume=2)

    m.view(384, 40, F, 90, 0, "from across the canal")
    m.view(384, 150, F, 90, -6, "from the bench")
    m.view(240, 290, Z, 35, 2, "the ledge")
    m.view(700, 120, F, 150, 2, "walking past")


# ---------------------------------------------------------------------------
# 4. The fighting pit
# ---------------------------------------------------------------------------

def m_pit(m, opt):
    """The fighting pit: the canal opens on its left, through a mouth 512 wide, into an eight-sided arena under the
    open sky. In its middle a ring sunk 64 into the floor, 384 across, floored with dirt, inside a cage of Nova
    Prospekt's fence panels on a kerb; the one gate (lc_pit_gate, on the side toward the canal) slides aside when the
    button on the post beside it is pressed (lc_pit_gate_button) or the game tells it to (Open, Close), and steps go
    down from it into the ring. lc_pit_corner_a and lc_pit_corner_b are the two corners the fighters start in (a stool
    in each). Three tiers of concrete seats, 32 high each, stand on the three far sides, with stairs of 16 up the
    middle of each. By the mouth on the right the bookmaker's table, chair, till and lamp under a chalk board of odds
    (lc_pit_bookie: where he sits); on the left the corner men's bench, water drum and bucket. Two lamps hang over
    the ring from a gantry (the owner asked for these, not street lamps).
    The gate is a fence panel (interior_fence002e) riding on an unseen brush door of the same name and inputs; an
    unseen wall stands in the cage's line all round, so the cage holds whatever the panels' own shapes are.
    Left as brushes: the tiers, kerb and posts for the buttons (concrete), the chalk board (no model of one), the
    gantry and its lamps.
    Unchecked: which way the fence panels face and whether their meshes meet at the corners; whether a press of the
    gate's button can be made through the cage from inside; the button's model is Episode Two's."""
    L, cu, cv = 1280, 640, 704
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

    # the cage round the ring: a kerb, fence panels 130 and 65 wide, an unseen wall in their line; the gate's gap is on the canal's side
    r1, r2 = 192, 195                                # (the ring's edge and the cage's line, from the middle)
    a1, a2, b1, b2 = cu - r2, cu + r2, cv - r2, cv + r2
    m.det([(a1 - 4, b1 - 4, F, a2 + 4, cv - r1, F + 6), (a1 - 4, cv + r1, F, a2 + 4, b2 + 4, F + 6),
           (a1 - 4, cv - r1, F, cu - r1, cv + r1, F + 6), (cu + r1, cv - r1, F, a2 + 4, cv + r1, F + 6)], MAT["beam"])
    wide, narrow = "models/props_wasteland/interior_fence002c.mdl", "models/props_wasteland/interior_fence002e.mdl"
    for d in (-130, 0, 130):
        m.static(wide, a1, cv + d, 0, z=F + 6)
        m.static(wide, a2, cv + d, 0, z=F + 6)
        m.static(wide, cu + d, b2, 90, z=F + 6)
        if d:
            m.static(wide, cu + d, b1, 90, z=F + 6)
    m.static(narrow, cu + 33, b1, 90, z=F + 6)
    clip = MAT["clip"]
    for box in ((a1 - 1, b1, F, a1 + 1, b2, F + 140), (a2 - 1, b1, F, a2 + 1, b2, F + 140), (a1, b2 - 1, F, a2, b2 + 1, F + 140),
                (a1, b1 - 1, F, cu - 65, b1 + 1, F + 140), (cu, b1 - 1, F, a2, b1 + 1, F + 140)):
        m.world(box, clip, seals=False)
    g = b1 - 6                                           # the gate hangs just outside the cage's line and slides along it
    slide_door(m, "lc_pit_gate", [((cu - 65, g - 2, F + 8, cu, g + 2, F + 134), STEEL)], "0 %d 0" % m.fr.yaw(0), speed=60, lip=0, unseen=True)
    rider(m, "lc_pit_gate", narrow, cu - 32, g, 90, F + 6)
    m.det([(cu + 12, 470, F, cu + 24, 482, F + 64)], MAT["beam"])
    m.button("lc_pit_gate_button", cu + 18, 470, F + 34, 270, [("lc_pit_gate", "Toggle", "", 0)])
    m.test_button((542, 470, F + 40, 550, 478, F + 56), [("OnIn", "lc_pit_gate", "Open"), ("OnOut", "lc_pit_gate", "Close")])
    m.det([(536, 468, F, 556, 480, F + 40)], MAT["beam"])
    m.steps(608, cu - 64, cu, F - 64, F, "v", -1)
    m.target("lc_pit_corner_a", 496, 584, F - 56, 45)
    m.target("lc_pit_corner_b", 784, 848, F - 56, 225)
    m.static("models/props_c17/chair_stool01a.mdl", 466, 530, 0, z=F - 64)
    m.static("models/props_c17/chair_stool01a.mdl", 814, 878, 0, z=F - 64)

    # the gantry over the ring, two lamps hanging from it (as first built: the owner asked for these back)
    top = F + 144
    m.det([(cu - 208, cv - 4, F + 6, cu - 200, cv + 4, top + 84), (cu + 200, cv - 4, F + 6, cu + 208, cv + 4, top + 84),
           (cu - 207, cv - 3, top + 74, cu + 207, cv + 3, top + 80)], BARS)
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

    # the bookmaker, right of the mouth: table, chair, till, a desk lamp, the board of odds on the wall
    m.static("models/props_c17/furnituretable002a.mdl", 948, 424, 90)
    m.static("models/props_c17/furniturechair001a.mdl", 944, 380, 90)
    m.target("lc_pit_bookie", 944, 380, F + 8, 90)
    put(m, [("props_c17/cashregister01a", 966, 420, 270), ("props_lab/desklamp01", 926, 426, 60)], F + 38)
    m.light(926, 426, F + 72, "255 205 140 120")
    m.det([(964, 384, F + 44, 1020, 386, F + 104)], MAT["black"])
    m.det([(962, 384, F + 42, 1022, 387, F + 44), (962, 384, F + 104, 1022, 387, F + 106), (962, 384, F + 44, 964, 387, F + 104), (1020, 384, F + 44, 1022, 387, F + 104)], BEAM)
    chalk = [(968, 386, F + 92, 1016, 387, F + 93), (991, 386, F + 50, 992, 387, F + 92)]
    for row in range(4):
        z = F + 82 - 9 * row
        chalk += [(970 + 3 * j, 386, z, 971 + 3 * j, 387, z + 6) for j in range((3, 5, 2, 4)[row])]
        chalk += [(996 + 3 * j, 386, z, 997 + 3 * j, 387, z + 6) for j in range((4, 1, 5, 2)[row])]
    m.det(chalk, PLASTER)

    # the corner men, left of the mouth: a bench, a drum of water, a bucket
    m.static("models/props_c17/bench01a.mdl", 276, 428, 0)
    m.static("models/props_c17/oildrum001.mdl", 344, 356, 0)
    m.loose("models/props_junk/metalbucket01a.mdl", 318, 410, 0)
    for u, v in ((640, 380), (480, 380), (800, 380), (640, 300)):
        m.lane(u, v)

    m.view(640, 100, F, 90, 2, "from the canal")
    m.view(608, 440, F, 90, 8, "at the gate")
    m.view(520, 840, F - 64, 315, 0, "in the ring")
    m.view(640, 1100, F + 96, 270, 16, "from the top tier")
    m.view(840, 440, F, 20, 2, "the bookmaker")


# ---------------------------------------------------------------------------
# 5. The garden
# ---------------------------------------------------------------------------

GRASS = "nature/grassfloor002a"
CLOTH = "props/carpetfloor003a"


def m_garden(m, opt):
    """The walled garden: where the Resistance grows food. A gap in the left wall, three steps up, a fence of boards
    and an iron gate (lc_garden_gate: Use swings it in), opens on a yard 640 by 448 under the open sky, its floor 24
    above the canal's. Six raised soil beds edged with timber, three on each side of a path of flagstones
    (lc_garden_bed_1 to _6: on the beds, for a farming job; 1 to 3 on the left going back, 4 to 6 on the right),
    ridged. lc_garden_plot_1 to _8 are the planting spots for the game (melons, pumpkins): info_targets on the soil
    of the four beds that have no bean poles, two a bed, each a little off the line and turned an odd way (the same
    every build). Bean poles over the first bed on each side; a scarecrow in the middle bed on the right. Against the back wall a tool lean-to (a desk, pots, a shovel, a bucket, a bell lamp), a
    barrel under a gutter pipe in the left corner, a compost heap behind boards in the right corner; a push cart, a
    wheelbarrow and a crate of melons on the path.
    The gate is props_c17/gate_door01a riding on an unseen brush door of the same name.
    Left as brushes: the beds (timber and soil), the scarecrow (no model of one), the lean-to, the fence's two rails.
    Unchecked: which way the gate and the boards face; how the loose things lie once the game drops them."""
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

    # the fence of boards across half the gap, and the gate that swings in
    for k in range(6):
        m.static("models/props_debris/wood_board04a.mdl", 583 + 10 * k, 288, 90, z=Z)
    m.det([(576, 289, Z + 14, 642, 291, Z + 18), (576, 289, Z + 46, 642, 291, Z + 50), (638, 286, Z, 642, 292, Z + 66)], BEAM)
    swing_door(m, "lc_garden_gate", [(646, 287, Z + 2, 702, 291, Z + 110)], STEEL, (702, 289, Z + 56), reverse=True, sound="doors/gate_move1.wav", unseen=True)
    rider(m, "lc_garden_gate", "models/props_c17/gate_door01a.mdl", 674, 289, 90, Z)

    # six raised beds: timber edges, soil, three ridges each
    beds = [(352, v) for v in (360, 472, 584)] + [(736, v) for v in (360, 472, 584)]
    edges, soil, ridges, stakes = [], [], [], []
    for n, (u, v) in enumerate(beds):
        a, b = u + 192, v + 72
        edges += [(u, v, Z, a, v + 4, Z + 18), (u, b - 4, Z, a, b, Z + 18), (u, v + 4, Z, u + 4, b - 4, Z + 18), (a - 4, v + 4, Z, a, b - 4, Z + 18)]
        stakes += [(u - 2, v - 2, Z, u + 4, v + 4, Z + 22), (a - 4, v - 2, Z, a + 2, v + 4, Z + 22), (u - 2, b - 4, Z, u + 4, b + 2, Z + 22), (a - 4, b - 4, Z, a + 2, b + 2, Z + 22)]
        soil.append((u + 4, v + 4, Z, a - 4, b - 4, Z + 13))
        for row in range(3):
            c = v + 16 + 20 * row
            ridges.append(prism([(c - 7, Z + 13), (c + 7, Z + 13), (c, Z + 17)], "x", u + 6, a - 6, DIRT))
        m.target("lc_garden_bed_%d" % (n + 1), u + 96, v + 36, Z + 18, 270)
    m.det(edges + stakes, BEAM)
    m.det(soil, DIRT)
    m.shapes(ridges)
    rnd = random.Random(8)                               # the planting spots: two on each bed that has no bean poles, none quite in line
    k = 0
    for n in (1, 2, 4, 5):
        u, v = beds[n]
        for du in (52, 140):
            k += 1
            m.target("lc_garden_plot_%d" % k, u + du + rnd.randrange(-9, 10), v + 36 + rnd.randrange(-11, 12), Z + 17, rnd.randrange(0, 360))
    m.blocked(336, 344, 560, 672)
    m.blocked(720, 344, 944, 672)

    # bean poles over the first bed on each side
    for (u, v) in (beds[0], beds[3]):
        for row in (0, 2):
            for k in range(u + 24, u + 190, 72):
                m.static("models/props_c17/signpole001.mdl", k, v + 16 + 20 * row, 0, z=Z + 13)

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
    m.static("models/props_interiors/furniture_desk01a.mdl", 640, 740, 90, z=Z)
    for u in (616, 640, 666):
        m.loose("models/props_junk/terracotta01.mdl", u, 742, 0, z=Z + 40)
    m.loose("models/props_junk/metalbucket01a.mdl", 592, 712, 0, z=Z)
    m.loose("models/props_junk/shovel01a.mdl", 694, 712, 90, z=Z)
    bell(m, 640, 712, Z + 96, "255 200 130 90")

    # a barrel under a gutter pipe in the left corner
    m.static("models/props_borealis/bluebarrel001.mdl", 348, 742, 0, z=Z)
    m.static("models/props_pipes/gutter_256_001a.mdl", 348, 760, 0, z=Z + 56)
    m.static("models/props_c17/oildrum001.mdl", 400, 744, 0, z=Z)

    # the compost heap behind a row of boards in the right corner
    for k in range(4):
        m.static("models/props_debris/wood_board06a.mdl", 870, 706 + 16 * k, 0, z=Z)
    m.shapes([prism([(702, Z), (766, Z), (756, Z + 26), (722, Z + 30)], "x", 874, 956, DIRT)])
    m.blocked(864, 688, 960, 768)

    # on the path: a push cart, a wheelbarrow, a crate, melons
    m.loose("models/props_junk/pushcart01a.mdl", 696, 566, 95, z=Z)
    m.static("models/props_junk/wheebarrow01a.mdl", 596, 640, 60, z=Z)
    m.static("models/props_junk/wood_crate002a.mdl", 690, 400, 10, z=Z)
    for u, v in ((676, 452), (694, 462)):
        m.loose("models/props_junk/watermelon01.mdl", u, v, 30, z=Z)
    for v in (430, 560, 660):
        m.lane(640, v, Z)

    m.view(640, 120, F, 90, 0, "the gate from the canal")
    m.view(640, 330, Z, 90, 10, "coming in")
    m.view(640, 668, Z, 270, 12, "from the lean-to")
    m.view(590, 610, Z, 140, 0, "the barrel and the gutter")
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
        "targetname": "lc_stash_valve", "origin": "%d %d %d" % (m.fr.at(vu, 226, vz)), "distance": "90", "speed": "60", "wait": "4", "sounds": "0", "health": "0",
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
    Five stalls in alcoves along its back, each with a steel kitchen counter across the right half of its front (the
    left half is the way behind it), a shelf unit, goods on the counter, a dome light, a crate to sit on, and a tin
    roll shutter over the front (lc_market_shutter_1 to _5: each lifts and drops when the button inside its own stall
    is pressed, lc_market_button_1 to _5, or when the game sends Open or Close). lc_market_stall_1 to _5 are where
    the stallholders stand, facing out. A fire drum burns in the middle of the arcade between two benches; a
    lookout's stool stands inside each archway, where the canal can be watched both ways; ribs carry the vault at
    every pier.
    Left as brushes: the shutters, their boxes and guide rails (Half-Life 2 has no roll shutter; they are the named
    doors), the vault's ribs and the arches.
    Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look (the same settings as the vortigaunt
    culvert's fire); func_door's "spawnpos" 1 (starts open) is from memory; which way the counters and small goods
    face. The first, third and fifth shutters start up, the second and fourth down (to be seen both ways); a shut
    stall is still got into by crouching under the shutter's foot: the shutter says closed, it does not lock."""
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

    wares = ((("props_junk/watermelon01", 76, 0), ("props_junk/glassjug01", 96, 20), ("props_junk/garbage_metalcan001a", 108, 60), ("props_junk/popcan01a", 116, 100)),
             (("props_c17/suitcase001a", 82, 10), ("props_c17/briefcase001a", 110, 80), ("props_junk/cardboard_box004a", 100, 30)),
             (("props_lab/partsbin01", 78, 0), ("props_c17/tools_wrench01a", 98, 40), ("props_c17/tools_pliers01a", 112, 110), ("props_lab/harddrive01", 118, 70)),
             (("props_lab/jar01a", 76, 0), ("props_lab/jar01b", 90, 30), ("items/healthkit", 106, 80), ("props_junk/glassbottle01a", 120, 0)),
             (("props_lab/citizenradio", 80, 270), ("props_lab/reciever01a", 104, 280), ("props_c17/consolebox01a", 112, 250)))
    for k, su in enumerate(stalls):
        n = k + 1
        # the counter across the right half of the front; the left half is the way in behind it
        m.static("models/props_wasteland/kitchen_counter001%s.mdl" % "abcab"[k], su + 96, 545, 90)
        put(m, [(name, su + du, 536 + 7 * (j % 3), yaw) for j, (name, du, yaw) in enumerate(wares[k])], F + 40)
        if k % 2 == 0:
            m.static("models/props_c17/cashregister01a.mdl", su + 100, 562, 90, z=F + 40)
        # the shutter, and the box it rolls up into
        slide_door(m, "lc_market_shutter_%d" % n, [((su, 507, F + 42, su + 128, 509, A), TIN), ((su, 506, F + 42, su + 128, 510, F + 46), BARS)],
                   "-90 0 0", speed=50, lip=6, starts_open=k % 2 == 0)
        m.det([(su - 4, 500, A - 4, su + 132, 512, A + 22)], TIN)
        m.det([(su - 4, 504, F, su, 512, A - 4), (su + 128, 504, F, su + 132, 512, A - 4)], BARS)
        m.button("lc_market_button_%d" % n, su, 600, F + 44, 0, [("lc_market_shutter_%d" % n, "Toggle", "", 0)])
        m.target("lc_market_stall_%d" % n, su + 76, 596, F + 8, 270)
        m.static("models/props_c17/shelfunit01a.mdl", su + 68, 626, 0)
        dome(m, su + 64, 590, A, "255 205 140 75")
        m.static("models/props_junk/wood_crate001a.mdl", su + 30, 596, 10 * k)
        m.lane(su + 64, 470)
    m.static("models/props_c17/shelfunit01a.mdl", 1138, 420, 90)        # the end of the arcade: spare stock

    # the middle of the arcade: a fire drum between two benches, bell lamps along the roof
    bu, bv = 640, 400
    m.static("models/props_c17/oildrum001.mdl", bu, bv, 0)
    fire(m, bu, bv, F + 46, size=20, light="255 160 80 130")
    m.sound("ambient/fire/fire_small_loop1.wav", bu, bv, F + 40, radius=420, volume=3)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", bu - 56, bv, 0)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", bu + 56, bv, 0)
    m.blocked(bu - 80, bv - 60, bu + 80, bv + 60)
    for u in (448, 832):
        bell(m, u, 416, H, "255 210 150 120")
    # the lookouts' stools, inside each archway on the side they watch from
    for su in (232, 1048):
        m.static("models/props_c17/chair_stool01a.mdl", su, 340, 0)
    m.static("models/props_junk/wood_crate002a.mdl", 160, 470, 80)
    m.decal("decals/decalposter014a", 352, 512, F + 90)
    m.decal("decals/decal_posters005a", 928, 512, F + 88)

    m.view(320, 120, F, 90, 0, "an archway from the canal")
    m.view(180, 416, F, 0, 2, "down the arcade")
    m.view(640, 340, F, 80, 2, "the fire drum and the stalls")
    m.view(480, 440, F, 115, 4, "a stall")
    m.view(470, 600, F, 300, 6, "behind a counter")


# ---------------------------------------------------------------------------
# 8. The pamphlet press
# ---------------------------------------------------------------------------

def m_press(m, opt):
    """The pamphlet press: a short side tunnel off the left wall that seems to end in a stack of crates to the roof.
    The crates are real ones, stacked: between the two at the floor is a gap 48 wide and 40 high under a pallet,
    behind a hanging sack (no thing: crawl through it). Behind is the printing room: a hand press (a bed on legs
    with the forme on it, a platen hanging from a screw between two cheeks, a long lever), lc_press_machine on its
    bed; a chest of drawers for the type; three drying lines across the room hung with sheets; boxes and bundles of
    paper on a pallet (lc_press_stack); a table with a lamp and papers; drums and cans of ink; a mattress.
    Left as brushes: the hand press (Half-Life 2 has no printing press), the sheets on the lines (they hang; the
    paper models lie flat), the sack over the gap.
    Unchecked: func_illusionary (the sack) is from memory; how taut the drying lines hang; that the stacked crates
    leave the gap clear (their boxes say 48 by 40; they are solid props, not brushes); which way the drawers face."""
    L, H = 768, F + 144
    m.open(0, -256, L, 256)
    m.low(256, 256, 384, 512, F + 128)                          # the side tunnel
    m.low(192, 512, 640, 768, H, mat=CRACKED)                   # the printing room
    m.side(128, 256, 704, 832)
    m.portal(256, 318, F, 384, 320, F + 128)
    m.taken(232, 110, F, 408, 256, F + 170)
    cheeks(m, 256, 384)
    m.lane(320, 300)

    # the false stack: two long crates at the floor with the gap between them, a pallet across, two rows more to the roof
    long_crate, crate = "models/props_junk/wood_crate002a.mdl", "models/props_junk/wood_crate001a.mdl"
    m.static(long_crate, 276, 420, 0)
    m.static(long_crate, 364, 420, 0)
    m.static("models/props_junk/wood_pallet001a.mdl", 320, 420, 0, z=F + 40)
    m.static(crate, 276, 418, 0, z=F + 40)
    m.static(crate, 364, 420, 0, z=F + 40)
    m.static(crate, 320, 418, 0, z=F + 49)
    m.static(crate, 277, 420, 0, z=F + 80)
    m.static(crate, 363, 416, 0, z=F + 80)
    m.static("models/props_junk/cardboard_box001a.mdl", 320, 420, 90, z=F + 89)
    m.ent("func_illusionary", {"rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"}, [(296, 383, F + 1, 344, 384, F + 40)], CLOTH)
    m.static(crate, 279, 350, 5)
    m.blocked(256, 320, 384, 512)
    m.light(320, 300, F + 110, "200 205 190 25")

    # the press
    pu, pv = 300, 664
    m.det([(pu - 28, pv - 30, F, pu - 22, pv - 24, F + 30), (pu + 22, pv - 30, F, pu + 28, pv - 24, F + 30),
           (pu - 28, pv + 24, F, pu - 22, pv + 30, F + 30), (pu + 22, pv + 24, F, pu + 28, pv + 30, F + 30),
           (pu - 34, pv - 8, F, pu - 26, pv + 8, F + 102), (pu + 26, pv - 8, F, pu + 34, pv + 8, F + 102), (pu - 38, pv - 10, F + 102, pu + 38, pv + 10, F + 114)], BEAM)
    m.det([(pu - 30, pv - 34, F + 30, pu + 30, pv + 34, F + 36)], WOOD)                         # the bed
    m.det([(pu - 18, pv - 22, F + 36, pu + 18, pv + 22, F + 39), (pu - 17, pv - 18, F + 52, pu + 17, pv + 18, F + 60)], STEEL)   # the forme, the platen
    m.det([(pu - 15, pv - 19, F + 39, pu + 15, pv + 19, F + 40)], PLASTER)                      # a sheet, just pulled
    m.shapes([vpipe(pu, pv, 3, F + 60, F + 102, BARS), vpipe(pu, pv, 7, F + 94, F + 102, STEEL),
              vprism([(pu - 2, pv - 3), (pu + 3, pv + 2), (pu + 61, pv - 54), (pu + 56, pv - 59)], F + 74, F + 78, BARS),   # the lever
              vpipe(pu + 59, pv - 57, 4, F + 70, F + 82, WOOD)])
    m.target("lc_press_machine", pu, pv, F + 42, 270)
    m.blocked(pu - 48, pv - 64, pu + 72, pv + 48)

    # the type's chest of drawers, against the left wall
    m.static("models/props_c17/furnituredrawer001a.mdl", 208, 590, 0)

    # the drying lines, hung with sheets
    rnd = random.Random(31)
    sheets = []
    for lv in (556, 612, 736):
        m.rope([(194, lv, F + 126), (638, lv, F + 126)], slack=2, width=1)
        u = 214
        while u < 610:
            if rnd.random() < 0.75 and not (lv == 612 and 250 < u < 350):
                sheets.append((u, lv, F + 108, u + 12, lv + 1, F + 125))
            u += rnd.choice((18, 22, 30))
    m.det(sheets, PLASTER)

    # paper: boxes and bundles on a pallet, more on the floor
    m.static("models/props_junk/wood_pallet001a.mdl", 580, 706, 0)
    m.target("lc_press_stack", 580, 706, F + 30, 180)
    m.static("models/props_junk/cardboard_box001a.mdl", 566, 692, 0, z=F + 9)
    m.static("models/props_junk/cardboard_box002a.mdl", 594, 722, 90, z=F + 9)
    put(m, [("props_junk/garbage_newspaper001a", 594, 690, 10)], F + 9)
    put(m, [("props_junk/garbage_newspaper001a", 594, 690, 40)], F + 13)
    put(m, [("props_junk/garbage_newspaper001a", 566, 692, 20)], F + 33)
    put(m, [("props_junk/garbage_newspaper001a", 482, 752, 0), ("props_junk/garbage_newspaper001a", 512, 748, 50)], F)
    m.blocked(536, 656, 624, 760)

    # a table with a lamp and papers, a chair; ink; somewhere to sleep
    m.static("models/props_c17/furnituretable001a.mdl", 420, 734, 0)
    m.static("models/props_c17/furniturechair001a.mdl", 420, 694, 90)
    put(m, [("props_c17/lamp001a", 408, 740, 0), ("props_c17/paper01", 434, 734, 20)], F + 37)
    m.glow(408, 740, F + 54, "255 200 120", 0.15)
    m.light(408, 740, F + 64, "255 185 105 110")
    m.static("models/props_c17/oildrum001.mdl", 612, 540, 0)
    m.static("models/props_c17/oildrum001.mdl", 580, 536, 0)
    m.static("models/props_c17/chair_stool01a.mdl", 548, 536, 0)
    put(m, [("props_junk/metal_paintcan001a", 524, 550, 0), ("props_junk/metal_paintcan001a", 520, 532, 0)], F)
    m.loose("models/props_c17/furnituremattress001a.mdl", 600, 610, 90)
    dome(m, 300, 600, H, "225 215 190 45")
    m.decal("decals/decalposter014a", 192, 700, F + 90)
    m.decal("decals/decal_posters005a", 640, 640, F + 92)
    for u, v in ((320, 480), (400, 600), (500, 620)):
        m.lane(u, v)

    m.view(320, 150, F, 90, 0, "the tunnel: a stack of crates")
    m.view(320, 330, F, 90, 14, "at the stack: the gap")
    m.view(320, 530, F, 80, 4, "the printing room")
    m.view(600, 560, F, 150, 8, "the press")
    m.view(230, 740, F, 345, 4, "the paper and the lines")


# ---------------------------------------------------------------------------
# 9. The still
# ---------------------------------------------------------------------------

def m_still(m, opt):
    """The still: a distillery in a cellar off the left wall. A short tunnel, then eight steps down into a cellar
    64 below the canal's floor. Against its far side the still: a brick firebox open at the front with a small steady
    fire in it, a boiler standing on it, a pipe across to the worm (a drum on a crate) and a glass jug under it
    (lc_still_pot: in front of the firebox). Three mash barrels along the left wall, boxes; kitchen shelves along the
    back wall (lc_still_shelf: in front of them); a table with a pot, bottles and a jug; a stool; a pale steam over
    the boiler.
    Left as brushes: the firebox (brick) and its grate.
    Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look and env_smokestack's (the framework's own
    settings, made small and pale here); which way the boiler and the pipe pieces face; Half-Life 2 has no wooden
    cask, so the barrels are its blue plastic ones and an oil drum."""
    L, C = 768, F - 64
    H = C + 160
    m.open(0, -256, L, 256)
    m.low(320, 256, 448, 384, F + 128)                          # the tunnel
    m.low(192, 384, 640, 704, H, floor=C, mat=STONE_FLOOR)      # the cellar
    m.side(128, 256, 704, 768)
    m.portal(320, 318, F, 448, 320, F + 128)
    m.taken(296, 110, F, 472, 256, F + 170)
    cheeks(m, 320, 448)
    m.steps(480, 320, 448, C, F, "v", -1)
    m.blocked(320, 384, 448, 496)
    m.lane(384, 300)
    m.lane(384, 520, C)
    m.light(384, 330, F + 110, "200 200 185 22")

    # the still: firebox, boiler, pipe, worm
    pu, pv = 524, 600
    m.det([(pu - 24, pv - 30, C, pu + 30, pv - 22, C + 26), (pu - 24, pv + 22, C, pu + 30, pv + 30, C + 26), (pu + 22, pv - 22, C, pu + 30, pv + 22, C + 26),
           (pu - 30, pv - 30, C, pu - 24, pv - 14, C + 26), (pu - 30, pv + 14, C, pu - 24, pv + 30, C + 26), (pu - 30, pv - 14, C + 20, pu - 24, pv + 14, C + 26)], BRICK)
    m.det([(pu - 32, pv - 32, C + 26, pu + 32, pv + 32, C + 30)], STEEL)
    m.det([(pu - 22, pv - 12, C + 4, pu + 16, pv - 9, C + 6), (pu - 22, pv - 2, C + 4, pu + 16, pv + 1, C + 6), (pu - 22, pv + 9, C + 4, pu + 16, pv + 12, C + 6)], BARS)   # the grate
    fire(m, pu - 6, pv, C + 7, size=14, light="255 150 70 90")
    m.static("models/props_c17/furnitureboiler001a.mdl", pu + 2, pv - 2, 180, z=C + 30)
    wu = 414
    for u in (wu + 16, wu + 48, wu + 80):
        m.static("models/props_pipes/pipe02_straight01_short.mdl", u, pv, 90, z=C + 92)
    m.static("models/props_junk/wood_crate001a.mdl", wu, pv, 0, z=C)
    m.static("models/props_c17/oildrum001.mdl", wu, pv, 0, z=C + 40)
    m.static("models/props_junk/glassjug01.mdl", wu - 32, pv, 0, z=C)
    m.target("lc_still_pot", pu - 60, pv, C + 8, 0)
    m.smoke(pu, pv, C + 124, colour="215 215 215", size=7, length=30, rate=6)
    m.sound("ambient/fire/fire_small_loop1.wav", pu, pv, C + 30, radius=380, volume=3)
    m.blocked(360, 552, 576, 648)

    # the mash: three barrels along the left wall, boxes
    for cv in (452, 512, 572):
        m.static("models/props_borealis/bluebarrel001.mdl", 222, cv, 0, z=C)
    m.static("models/props_junk/cardboard_box002a.mdl", 224, 640, 0, z=C)
    m.static("models/props_junk/cardboard_box001a.mdl", 228, 676, 30, z=C)

    # kitchen shelves along the back wall; a table with a pot, bottles and a jug
    for u in (340, 420, 500):
        m.static("models/props_wasteland/kitchen_shelf001a.mdl", u, 684, 0, z=C)
    m.target("lc_still_shelf", 460, 650, C + 8, 270)
    tu, tv = 590, 460
    m.static("models/props_c17/furnituretable001a.mdl", tu, tv, 0, z=C)
    put(m, [("props_interiors/pot01a", tu - 12, tv, 0), ("props_junk/glassbottle01a", tu + 8, tv - 10, 0), ("props_junk/glassbottle01a", tu + 16, tv + 4, 0),
            ("props_junk/glassbottle01a", tu + 4, tv + 12, 0), ("props_junk/glassjug01", tu - 6, tv - 14, 0)], C + 37)
    m.static("models/props_junk/wood_crate001a.mdl", 606, 664, 10, z=C)
    m.static("models/props_c17/chair_stool01a.mdl", 548, 438, 0, z=C)
    dome(m, 400, 520, H, "255 205 140 110")
    m.lane(400, 520, C)
    m.lane(330, 620, C)

    m.view(384, 150, F, 90, 0, "the tunnel from the canal")
    m.view(384, 370, F, 80, 16, "down the steps")
    m.view(330, 500, C, 25, 2, "the still")
    m.view(600, 520, C, 160, 6, "the barrels and the shelves")
    m.view(470, 520, C, 60, 6, "the boiler and the fire")


# ---------------------------------------------------------------------------
# 10. The plaza
# ---------------------------------------------------------------------------

def bowl(cu, v1, vb, w, r):
    """The ground round half an eight-sided hollow of radius r whose middle is (cu, vb) on the back wall, out to a
    rectangle (cu - w .. cu + w, v1 .. vb): four outlines for vprism, every corner a whole number."""
    a = int(round(r * 0.7071))
    out = []
    for s in (-1, 1):
        out.append([(cu + s * w, vb), (cu + s * r, vb), (cu + s * a, vb - a), (cu + s * w, v1)])
        out.append([(cu + s * w, v1), (cu + s * a, vb - a), (cu, vb - r), (cu, v1)])
    return out


def m_plaza(m, opt):
    """The plaza: where people gather to listen. The canal (or the street) opens on its left, 1152 wide, onto a
    terrace at its own height, and from the terrace five concrete rows of seats step DOWN and away, each 16 high and
    48 deep (walked down anywhere, sat on anywhere), round half an eight-sided floor 512 across and 80 below the
    street. At the back wall, facing the rows and the street beyond them, a timber rostrum three steps up with a
    lectern (lc_plaza_rostrum: where the speaker stands, facing the street), between two street lamps that carry a
    wire for a banner; a cluster of loudspeakers on one (speakercluster01a), turned to the street; a fire drum on
    each side of the floor. lc_plaza_crowd is the middle of the third row, facing the rostrum.
    (Turned round on 21 November at the owner's word: the top row used to be at the back.)
    Left as brushes: the rows, the rostrum's deck and steps (timber staging), its lectern (no model of one).
    Unchecked: env_fire's look in the drums; which way the loudspeakers and the lamps' arms point (the arms are along
    the model's y, turned here toward the rows); no sound here."""
    L, cu, v1, vb, w = 1536, 768, 256, 768, 576
    low = F - 80
    m.open(0, -256, L, 256)
    m.open(cu - w, v1, cu + w, vb, floor=low, mat=MAT["quay_floor"])
    m.side(cu - w, v1, cu + w, vb)
    m.no_bank(cu - w, v1 + 8, cu + w, vb + 64)
    m.blocked(cu - w, v1, cu + w, vb)
    m.taken(cu - w - 24, 110, F, cu + w + 24, 256, F + 150)
    cheeks(m, cu - w, cu + w)

    # the rows: the ground round the hollow at each height, the highest (the terrace, level with the street) the widest
    rows = []
    for k in range(5):
        for pts in bowl(cu, v1, vb, w, 256 + 48 * k):
            rows.append(vprism(pts, low, low + 16 * (k + 1), MAT["beam"], top=MAT["quay_floor"]))
    m.shapes(rows)
    m.target("lc_plaza_crowd", cu, vb - 376, low + 56, 90)

    # the rostrum at the back wall: a timber deck three steps up, a lectern at its front
    r1, r2, rv1, rv2, top = cu - 48, cu + 48, vb - 66, vb, low + 24
    m.det([(r1, rv1, top - 4, r2, rv2, top)], WOOD)
    m.det([(u, v, low, u + 6, v + 6, top - 4) for u in (r1, cu - 3, r2 - 6) for v in (rv1, rv2 - 6)]
          + [(r1, rv1, top - 10, r2, rv1 + 4, top - 4), (r1, rv2 - 4, top - 10, r2, rv2, top - 4)], BEAM)
    m.det([(r1 - 12 * (3 - k), rv1 + 8, low, r1 - 12 * (2 - k), rv2 - 8, low + 8 * (k + 1)) for k in range(3)], BEAM, top=WOOD)
    m.det([(cu - 14, rv1 + 4, top, cu + 14, rv1 + 14, top + 38)], WOOD)
    m.shapes([prism([(rv1 + 2, top + 38), (rv1 + 16, top + 38), (rv1 + 16, top + 40), (rv1 + 2, top + 46)], "x", cu - 16, cu + 16, BEAM)])
    m.target("lc_plaza_rostrum", cu, vb - 30, top + 8, 270)
    # two street lamps and the wire for a banner; the loudspeakers on one, turned to the street
    p1, p2, pz = r1 - 22, r2 + 22, low + 208
    for u in (p1, p2):
        m.static("models/props_c17/lamppost03a_on.mdl", u, vb - 20, 180, z=low)
        m.light(u, vb - 116, low + 420, "255 220 170 1500")
    m.rope([(p1, vb - 20, pz), (p2, vb - 20, pz)], slack=10, width=1)
    m.static("models/props_wasteland/speakercluster01a.mdl", p1, vb - 38, 270, z=low + 176)

    # a fire drum on each side of the floor
    for u in (cu - 190, cu + 190):
        m.static("models/props_c17/oildrum001.mdl", u, vb - 40, 0, z=low)
        fire(m, u, vb - 40, low + 46, size=18, light="255 150 70 140")
    for u, v in ((cu, vb - 120), (cu - 120, vb - 100), (cu + 120, vb - 100), (cu, vb - 200)):
        m.lane(u, v, low)
    for u in (cu - 420, cu - 140, cu + 140, cu + 420):
        m.lane(u, v1 + 28)

    m.view(cu, 60, F, 90, 6, "from across the canal: looking down the rows")
    m.view(cu, vb - 30, top, 270, -4, "from the rostrum")
    m.view(cu, v1 + 30, F, 90, 12, "from the terrace")
    m.view(cu - 300, vb - 60, low, 20, 0, "the rostrum from the floor")


# ---------------------------------------------------------------------------
# 11. The playground
# ---------------------------------------------------------------------------

def m_playground(m, opt):
    """The playground: a relic of before. A terrace 128 above the canal's floor on the left, open to the sky (the
    bank along it is the way up). On it, City 17's own playground models: a swing set with one seat still hanging on
    its chains and one fallen, hanging by a single chain; a slide; a roundabout; and, built here, a sandpit edged with
    timber; a bench with its back to the wall, facing it all (lc_playground_bench: on the bench). Nothing else, and
    no lamp.
    Left as brushes: the sandpit (timber and sand in the ground).
    Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (one faint wind); which end of the slide is
    its ladder and which way the bench faces; whether the swing set's model has chains of its own (the seats are
    separate models, hung here on ropes); on a street there is no bank, so the terrace needs steps of the street's."""
    L, T = 1024, F + 128
    m.open(0, -256, L, 256)
    m.open(192, 256, 832, 640, floor=T, mat=CRACKED)
    m.side(192, 256, 832, 640)

    # the swings
    sv, sz = 500, T + 134
    m.static("models/props_c17/playground_swingset01.mdl", 338, sv, 0, z=T)
    m.static("models/props_c17/playground_swingset_seat01a.mdl", 300, sv, 0, z=T + 20)       # the seat that still hangs true
    m.rope([(286, sv, sz), (286, sv, T + 24)], slack=0, width=1)
    m.rope([(314, sv, sz), (314, sv, T + 24)], slack=0, width=1)
    m.static("models/props_c17/playground_swingset_seat01a.mdl", 374, sv - 8, 20, z=T)        # the other: one chain gone, its end on the ground
    m.rope([(362, sv, sz), (362, sv - 10, T + 4)], slack=4, width=1)
    m.rope([(388, sv, sz), (388, sv, T + 70)], slack=0, width=1)
    m.blocked(232, 440, 440, 560)

    # the slide, the roundabout
    m.static("models/props_c17/playgroundslide01.mdl", 640, 340, 270, z=T)
    m.blocked(540, 288, 760, 392)
    m.static("models/props_c17/playground_carousel01.mdl", 330, 350, 0, z=T)
    m.blocked(256, 272, 408, 428)

    # the sandpit
    g1, g2, h1, h2 = 520, 680, 430, 580
    m.det([(g1, h1, T, g2, h1 + 6, T + 10), (g1, h2 - 6, T, g2, h2, T + 10), (g1, h1 + 6, T, g1 + 6, h2 - 6, T + 10), (g2 - 6, h1 + 6, T, g2, h2 - 6, T + 10)], BEAM)
    m.det([(g1 + 6, h1 + 6, T, g2 - 6, h2 - 6, T + 5)], DIRT)
    m.shapes([prism([(470, T + 5), (506, T + 5), (490, T + 12)], "x", 590, 634, DIRT)])
    m.blocked(g1, h1, g2, h2)

    # the bench, its back to the wall
    m.static("models/props_c17/bench01a.mdl", 640, 624, 270, z=T)
    m.target("lc_playground_bench", 640, 618, T + 20, 270)
    m.sound("ambient/levels/canals/windmill_wind_loop1.wav", 512, 440, T + 120, radius=700, volume=2)
    for u, v in ((480, 300), (480, 400), (760, 480), (220, 600)):
        m.lane(u, v, T)

    m.view(512, 40, F, 90, -6, "from the canal")
    m.view(220, 290, T, 30, 4, "up on the terrace")
    m.view(640, 600, T, 250, 6, "from the bench")
    m.view(780, 420, T, 190, 6, "the slide and the swings")


MODULES = {
    "cells": (1024, m_cells, "the cells: a guard room, three barred cells, a crawl duct out (left)"),
    "memorial": (768, m_memorial, "the wall of the dead: plaques and candles in a recess under the open sky (left)"),
    "pit": (1280, m_pit, "the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left)"),
    "garden": (1280, m_garden, "the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left)"),
    "stash": (768, m_stash, "the stash: an arms room behind a section of wall that a pipe valve opens (left)"),
    "market": (1280, m_market, "the black market: a vaulted arcade of five shuttered stalls (left)"),
    "press": (768, m_press, "the pamphlet press: a printing room behind a false stack of crates (left)"),
    "still": (768, m_still, "the still: a pot still, mash casks and bottles in a cellar (left)"),
    "plaza": (1536, m_plaza, "the plaza: five rows of seats stepping down from the street to a rostrum at the back wall (left)"),
    "playground": (1024, m_playground, "the playground: a rusted relic on a terrace over the canal (left)"),
    "clinic": (1024, m_clinic, "the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left)"),
}
