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
    press      the pamphlet press: a printing room behind a door in a side tunnel
    still      a distillery in a cellar: a pot still, mash casks, shelves of bottles
    plaza      five rows of seats stepping down from the street to a stage at the back wall
    playground Half-Life 2's playground from the train station: swings, roundabout, slide, see-saw, a path through it

How to write one, and what every call does: docs/dev/map-modules.md.
"""

import random

from map_build import CELL, MAT, bar_row, octagon, prism
from map_modules import F, TRIM, MM, SCAPES

TILE = "tile/tilefloor018a_c17"
PLASTER = "plaster/plasterwall042c"
STONE = "stone/stonewall040f"
STONE_FLOOR = "stone/stonefloor006d_c17"
CRACKED = "concrete/concretefloor016a"
DIRT = "nature/dirtfloor005c"
SAND = "nature/sandfloor010a"
DUCT = "metal/metalfloor005a"
BRICK = "brick/brickwall037a"
WOOD, TIN, STEEL = MM["wood"], MM["tin"], MM["steel"]
BARS, WALL = MAT["bars"], MAT["canal_wall"]
WARM = "255 190 120"
# What is new here is made of the owner's own materials (all in their City 18 map: _dev/reference/city18/palette.json)
TIMBER = "wood/woodwall006a"                # racks, frames, boards, staging
DECK = "wood/woodfloor006b"                 # timber floors and decks
IRON = "metal/metalhull010c"                # steel parts
CEILING = "plaster/plasterceiling008a_c17"
LOW_PAINT = "plaster/plasterwall047b"       # the lower band of a two-tone wall (the town's flats have it)
CONCRETE = "concrete/concretewall008a"      # raw concrete: City 18's commonest wall
DAMP = "concrete/concretewall059e"
CONC_CEIL = "concrete/concreteceiling004a"
CONC_FLOOR = "concrete/concretefloor013a"
RED_BRICK = "brick/brickwall045d"
OLD_BRICK = "brick/brickwall014l"
SHUTTER = "metal/metaldoor032c"             # corrugated: the owner's own roll doors
TILE_WALL = "tile/tilewall009b"
TUBE = "models/props_lab/lab_flourescentlight002b.mdl"


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
    door's own brush does the blocking). A physics model is a prop_dynamic_override: as a plain prop_dynamic the game
    objects to it."""
    import map_assets
    m.prop("prop_dynamic_override" if map_assets.is_physics_prop(model) else "prop_dynamic", model, u, v, yaw, z, {"parentname": door, "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
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


def tube(m, u, v, ceil, colour="215 228 235 60", along="u"):
    """A fluorescent tube (the lab's: City 18 has 149 of them) flat under a roof at `ceil`, its length along u or v,
    and its light under it."""
    m.static(TUBE, u, v, 90 if along == "u" else 0, z=ceil - 9)
    m.light(u, v, ceil - 22, colour)


def sounds(m, L, kind, u, v, z, radius):
    """What the place sounds like (a soundscape of SCAPES), and the canal's (or the street's) own in front of it, so
    walking back out changes it back (a soundscape holds until another is in reach)."""
    m.soundscape(SCAPES[kind], u, v, z, radius)
    m.soundscape(SCAPES["courtyard"], L // 2, -128, F, max(512, L // 2))


def rail_run(m, a, b, at, axis, z, piece=64):
    """The city's handrail (handrail04, the model's length along its y) from a to b along axis "u" or "v", at `at`
    across, standing on z: pieces of 64 end to end, and a short one to finish."""
    yaw = 0 if axis == "v" else 90
    n = (b - a) // piece
    for k in range(n):
        c = a + piece * k + piece // 2
        m.static("models/props_c17/handrail04_medium.mdl", *((at, c) if axis == "v" else (c, at)), yaw=yaw, z=z)
    if (b - a) - n * piece >= 30:
        c = b - 17
        m.static("models/props_c17/handrail04_short.mdl", *((at, c) if axis == "v" else (c, at)), yaw=yaw, z=z)


def put(m, things, z, u0=0, v0=0):
    """Small things stood on a surface at z: [(model's short name under models/, du, dv, yaw), ...] from (u0, v0)."""
    for name, du, dv, yaw in things:
        m.static("models/%s.mdl" % name, u0 + du, v0 + dv, yaw, z=z)


def in_town(m):
    """Built into the town (map_town.py), whose house fronts stand proud of the left wall and dress it."""
    return bool(m.fr.dz) and hasattr(m.b.plan, "fill")


def front_face(m, z):
    """Where the face of the left wall is at height z over the floor, for a thing hung on it: at v 256, but in the town
    the house fronts stand out from it (map_town.facade: a plinth 9 out to 24, the walls 6 out, a trim 10 out from 136
    to 152), and on the street beside the canal the courses street_front lays; a lamp or a sign goes on their face,
    not inside them."""
    if in_town(m):
        return 247 if z < 24 else 246 if 136 <= z < 152 else 250
    if m.fr.dz:
        return 250 if z < 24 else 248 if 136 <= z < 152 else 256
    return 256


def street_front(m, L):
    """On the street beside the canal (lifted, but not into the town, whose house fronts do it), the module's front
    wall laid in courses as City 18 and Valve band their walls (map_lessons.py --tag valve): a concrete plinth to 24,
    a stone string course from 136 to 152 and a stone cornice under the wall's top, each a little proud, broken
    wherever the module opens. In a canal the canal's own dressing does the walls."""
    if not m.fr.dz or in_town(m):
        return
    cells, dz = m.b.plan.cells, m.fr.dz

    def wall_from(u):        # (how high over the floor the wall starts at this 64: None where the module is open ground)
        x, y = m.fr.pt(u + 32, 288)
        spec = cells.get((x // CELL, y // CELL))
        if spec is None or spec[0] == "solid":
            return 0
        return spec[3] - dz - F if spec[0] == "low" else None
    top = m.b.rim - F
    for z1, z2, out, mat in ((0, 24, 6, "concrete/concretewall002c"), (136, 152, 8, "stone/stonewall050f"), (top - 20, top - 4, 10, "stone/stonewall050f")):
        boxes, start = [], None
        for u in list(range(0, L, CELL)) + [L]:
            w = wall_from(u) if u < L else None
            ok = w is not None and w <= z1
            if ok and start is None:
                start = u
            elif not ok and start is not None:
                boxes.append((start, 256 - out, F + z1, u, 256, F + z2))
                start = None
        if boxes:
            m.det(boxes, mat)


def cheeks(m, u1, u2, top=136, out=132, thick=12):
    """Where the left wall's bank is cut for a way in (u1 to u2), a retaining wall on each side of the cut, its top
    sloping with the bank it holds back. Nothing on a street (a lifted module): there is no bank there."""
    if m.fr.dz:
        return
    shape = [(256, F), (256 - out, F), (256 - out, F + 14), (256, F + top)]
    m.shapes([prism(shape, "x", u1 - thick, u1 + 1, MAT["beam"]), prism(shape, "x", u2 - 1, u2 + thick, MAT["beam"])])      # (1 into the cut: the bank's cut end is buried, not flush with it)


def swing(m, name, u, v, seat, bar, along="u"):
    """A swing's seat (u, v) at height seat, on a phys_hinge along the bar at height bar (the bar runs along "u" or "v")
    and two chains that follow it."""
    du, dv = (1, 0) if along == "u" else (0, 1)
    m.prop("prop_physics", "models/props_c17/playground_swingset_seat01a.mdl", u, v, 0 if along == "u" else 90, seat, {"targetname": name, "spawnflags": "0"})
    m.point("phys_hinge", u, v, bar, {"targetname": name + "_hinge", "attach1": name, "attach2": "", "hingeaxis": "%d %d %d" % m.fr.at(u + 32 * du, v + 32 * dv, bar),
                                       "hingefriction": "0", "forcelimit": "0", "torquelimit": "0", "spawnflags": "0", "systemoverridefile": ""})
    for d in (-13, 13):
        top, low = name + "_chain%d" % (d > 0), name + "_chain%d_end" % (d > 0)
        keys = {"Slack": "0", "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": "1", "TextureScale": "1", "Collide": "0", "Dangling": "0", "Breakable": "0",
                "RopeMaterial": "cable/chain.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
        m.b.vmf.point("move_rope", m.fr.at(u + d * du, v + d * dv, bar), dict(keys, targetname=top, NextKey=low), m.b.vis + ": ropes")
        m.b.vmf.point("keyframe_rope", m.fr.at(u + d * du, v + d * dv, seat + 4), dict(keys, targetname=low, parentname=name), m.b.vis + ": ropes")


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


def fire(m, u, v, z, size=24, light="255 150 70 110", drop=True):
    """A small fire that burns from the start (the vortigaunt culvert's own), and a steady warm light over it.
    drop=False: it stays at z (an env_fire falls to the ground it stands over unless told not to: the owner saw the
    drums' fires burning at their feet, 20 November)."""
    m.point("env_fire", u, v, z, {"health": "30", "firesize": str(size), "fireattack": "4", "firetype": "0", "spawnflags": "7" if drop else "23",
                                  "ignitionpoint": "32", "damagescale": "0.2"})
    m.light(u, v, z + 40, light)


def mattress(m, u, v, yaw, z=F):
    """A loose mattress, turned the right way up (unturned the model lies on its back: the owner saw the clinic's so)."""
    m.prop("prop_physics", "models/props_c17/furnituremattress001a.mdl", u, v, yaw, z + 1, {"spawnflags": "0", "angles": "0 %d 180" % m.fr.yaw(yaw)})


def frustum(u, v, r1, z1, r2, z2, mat):
    """A standing cone cut off flat (r1 round at z1, r2 at z2): a funnel, a cap."""
    lo, hi = octagon(u, v, r1), octagon(u, v, r2)
    faces = [([(a, b, z2) for a, b in hi], mat), ([(a, b, z1) for a, b in lo], mat)]
    for k in range(8):
        faces.append(([lo[k] + (z1,), lo[(k + 1) % 8] + (z1,), hi[(k + 1) % 8] + (z2,), hi[k] + (z2,)], mat))
    return faces


# ---------------------------------------------------------------------------
# 1. The cells
# ---------------------------------------------------------------------------

CELL_LOW, CELL_HIGH, CELL_RAIL = OLD_BRICK, "plaster/plasterwall041a", "stone/stonewall050f"     # City 18's own: brick to the dado, plaster above, a stone rail


def cell_front(m, cu, door, window, H, dado=56):
    """A cell's front wall, 8 thick, with a way through for its door and a hole for its barred window: brick below the
    dado and plaster above it, as the rooms are lined, with the rail on both faces where the wall runs whole."""
    cuts = sorted([cu, door[0], door[1], window[0], window[1], cu + 128])
    lows, highs, rails = [], [], []
    for a, b in zip(cuts, cuts[1:]):
        if (a, b) == tuple(door):
            highs.append((a, 536, F + 104, b, 544, H))
        elif (a, b) == tuple(window):
            lows.append((a, 536, F, b, 544, F + 48))
            highs.append((a, 536, F + 102, b, 544, H))
        elif a < b:
            lows.append((a, 536, F, b, 544, F + dado))
            highs.append((a, 536, F + dado + 4, b, 544, H))
            rails.append((a, 535, F + dado, b, 545, F + dado + 4))
    m.det(lows, CELL_LOW)
    m.det(highs, CELL_HIGH)
    m.det(rails, CELL_RAIL)


def m_cells(m, opt):
    """The cells: where the Resistance keeps captured Combine units, in an old cellar done up as City 18 does its
    rooms: brick to the dado line, plaster above it, a stone rail between, a concrete floor and roof. A heavy steel
    door at the foot of the left wall (lc_cells_entry: Use swings it in) opens on a guard room lit by a fluorescent
    tube and a prison lamp: a table with a radio and a revolver, a chair set to watch the corridor, lockers, a bench,
    a board with the padlocks on it, a shotgun on a rack, a Civil Protection helmet hung on the wall as a trophy, a
    crate of what was taken off the prisoners. A corridor runs on past three cells, a lamp over each cell's door and
    darker between, each cell 128 by 160 behind a wall with a barred window and a barred door (lc_cells_door_1 to _3)
    that slides aside behind the wall when the button beside it on the corridor's pier is pressed (lc_cells_button_1
    to _3, tally marks over each say which) or the game sends Open, Close or Toggle. Each cell has a toilet, a bucket
    and a drain in the floor, a name or two scratched on the wall; the first a mattress on the floor, the middle one
    an iron bed frame with the mattress on it and a pan of food on the floor (and the days scratched on its wall),
    the far one a mattress and the way out. lc_cells_spot_1 to _3 are where a prisoner stands. The far cell has a
    loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it), a few loose bricks and
    grit trailing from it, onto a crawl duct 40 high that comes out at the canal's floor through a concrete pipe:
    the way to break out, or in.
    The doors are Nova Prospekt's models (prison_heavydoor001a, prison_celldoor001a) riding on unseen brush doors
    of the same names and inputs as before; the windows are prison_cellwindow002a with an unseen wall in them.
    Left as brushes: the grate (no model 62 by 38), the tally marks (paint, not things), the gun rack's board.
    Unchecked: which way the door, window, bench and board models face (each is thin along its x, so its face looks
    along x: turned here to look along v); the helmet (models/barneyhelmet.mdl) hanging on its nail; whether a
    prisoner's Use can reach a button round the pier's corner; the doors' sounds (doors/doormove1.wav,
    doors/gate_move1.wav)."""
    L, H = 1024, F + 128
    m.open(0, -256, L, 256)
    m.low(128, 256, 192, 320, F + 112)                                      # the doorway
    m.low(64, 320, 320, 512, H, mat=CONC_FLOOR)                             # the guard room
    m.low(320, 384, 832, 512, H, mat=CONC_FLOOR)                            # the corridor
    cells = (320, 512, 704)
    for cu in cells:
        m.low(cu, 512, cu + 128, 704, H, mat=CONC_FLOOR)
    m.low(832, 640, 896, 704, F + 40, mat=DUCT)             # the crawl duct: out of the far cell's side wall,
    m.low(896, 256, 960, 704, F + 40, mat=DUCT)             # and down to the canal
    m.side(64, 256, L, 704)
    m.portal(128, 286, F, 192, 288, F + 112)
    m.portal(896, 318, F, 960, 320, F + 40)
    m.blocked(832, 256, 960, 704)
    m.taken(104, 200, F, 216, 256, F + 176)
    m.taken(872, 120, F, 984, 256, F + 80)
    line_walls(m, [(64, 320, 320, 512, H), (320, 384, 832, 512, H)] + [(cu, 512, cu + 128, 704, H) for cu in cells],
               dado=56, low=CELL_LOW, high=CELL_HIGH, roof=CONC_CEIL, rail=CELL_RAIL)

    # the way in: a heavy door in a cut in the bank, a caged lamp over it
    cheeks(m, 128, 192)
    swing_door(m, "lc_cells_entry", [(129, 284, F + 1, 191, 290, F + 111)], STEEL, (129, 287, F + 56), unseen=True)
    rider(m, "lc_cells_entry", "models/props_wasteland/prison_heavydoor001a.mdl", 160, 287, 90, F)
    if not in_town(m):                                                      # (in the town the house front frames the door)
        m.det([(124, 250, F + 112, 196, 256, F + 120)], MAT["beam"])
    cage(m, 160, front_face(m, 136), F + 136, 270, "255 200 140 90")
    m.grime("number", 160, front_face(m, 170), F + 170, 1)                  # (a number painted over the door, as on the city's service doors)
    m.lane(160, 288)

    # the guard room: the brightest place here
    m.static("models/props_c17/furnituretable002a.mdl", 232, 420, 0)
    put(m, [("props_lab/citizenradio", 226, 404, 100), ("props_junk/garbage_coffeemug001a", 240, 440, 0)], F + 37)
    m.dynamic("models/weapons/w_357.mdl", 236, 424, 30, z=F + 37, solid=False)
    m.static("models/props_c17/furniturechair001a.mdl", 286, 448, 0)                      # set to watch down the corridor
    m.static("models/props_c17/lockers001a.mdl", 74, 452, 0)
    m.static("models/props_c17/bench01a.mdl", 78, 364, 0)
    m.static("models/props_lab/corkboard001.mdl", 264, 512, 270, z=F + 50)                # the board, and the padlocks hung on it
    put(m, [("props_wasteland/prison_padlock001a", 236 + 14 * k, 505, 270) for k in (0, 1, 2, 4)], F + 66)
    gun_rack(m, 100, 156, 512, -1, F, "u", [(44, [("w_shotgun", 128)])])
    m.det([(203, 509, F + 86, 205, 512, F + 88)], IRON)                                   # a nail, and the helmet of a unit who did not leave
    m.dynamic("models/barneyhelmet.mdl", 204, 505, 270, z=F + 76, solid=False)
    m.static("models/props_wasteland/prison_lamp001c.mdl", 140, 416, 0, z=H - 12)
    m.light(140, 416, H - 26, "255 205 150 90")
    tube(m, 232, 420, H, "220 232 240 80", along="u")
    m.det([(316, 384, F, 321, 392, H), (316, 504, F, 321, 512, H), (316, 392, H - 8, 321, 504, H)], IRON)     # the frame of the way through
    m.static("models/props_junk/wood_crate001a.mdl", 284, 350, 10)                        # what was taken off the prisoners
    m.grime("poster", 66, 400, F + 80, 2)
    m.grime("stain", 200, 322, F + 100, 3)
    m.lane(200, 448)

    # the corridor: a prison lamp over each cell's door, darker between; pipes under its roof; the guard's stool
    for k, cu in enumerate(cells):
        du = cu + (32 if k == 2 else 96)
        m.static("models/props_wasteland/prison_lamp001c.mdl", du, 500, 0, z=H - 12)
        m.light(du, 492, H - 26, "215 220 200 60")
    m.static("models/props_wasteland/prison_pipes001a.mdl", 576, 398, 0, z=H - 20)        # pipes under the corridor's roof
    m.static("models/props_c17/chair_stool01a.mdl", 808, 404, 0)                          # the guard's stool at the corridor's end
    m.grime("grate", 576, 448, F, 4)                                                      # a drain in the floor
    m.grime("stain", 704, 386, F + 90, 5)
    m.grime("crack", 470, 386, F + 70, 6)

    # the cells
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
        m.button("lc_cells_button_%d" % n, bu, 510, F + 40, 270, [(name, "Toggle", "", 0)])          # (on the pier's lining)
        m.det([(bu - 2 * n + 4 * j, 509, F + 72, bu - 2 * n + 4 * j + 2, 510, F + 84) for j in range(n)], PLASTER)
        m.target("lc_cells_spot_%d" % n, cu + 64, 624, F + 8, 270)
        if k == 1:                                                  # the middle cell: an iron bed frame, the mattress on it, a pan of food
            m.static("models/props_wasteland/prison_bedframe001b.mdl", cu + 30, 640, 90)
            mattress(m, cu + 30, 640, 90, z=F + 31)
            put(m, [("props_c17/metalpot002a", cu + 84, 600, 20), ("props_junk/garbage_metalcan002a", cu + 96, 590, 0)], F)
        else:
            mattress(m, cu + 30, 640, 90)
        m.loose("models/props_junk/metalbucket01a.mdl", cu + 108, 580, 0)
        m.static("models/props_wasteland/prison_toilet01.mdl", cu + (40 if last else 100), 694, 0)
        m.static("models/props_wasteland/prison_lamp001c.mdl", cu + 64, 620, 0, z=H - 12)
        m.light(cu + 64, 620, H - 26, "200 205 185 22")
        m.grime("grate", cu + 64, 600, F, 10 + n)
        m.grime("graffiti", cu + (126 if last else 2), 660, F + 64, 20 + n)              # (a name scratched on the side wall)
        m.lane(cu + 64, 448)
    m.det([(637, 596 + 4 * j, F + 70, 638, 598 + 4 * j, F + 80) for j in range(9)]
          + [(635, 594, F + 74, 637, 632, F + 76)], PLASTER)                            # days scratched on the middle cell's wall

    # the far cell's loose grate, the duct, and the concrete pipe it comes out through (in a canal: the bank is cut for it)
    slats = [(833, 641, F + 1 + 8 * j, 836, 703, F + 5 + 8 * j) for j in range(5)]
    swing_door(m, "lc_cells_grate", slats + [(833, 641, F + 1, 837, 645, F + 39), (833, 699, F + 1, 837, 703, F + 39)], BARS, (835, 643, F + 20),
               sound="doors/gate_move1.wav")
    put(m, [("props_debris/concrete_cynderblock001", 816, 650, 20), ("props_debris/concrete_cynderblock001", 812, 690, 75),
            ("props_debris/concrete_chunk03a", 800, 668, 40)], F)
    m.grime("debris", 796, 672, F, 7)
    if not m.fr.dz:
        m.prop("prop_static", "models/props_pipes/concrete_pipe001a.mdl", 928, 198, 90, F - 6, {"solid": "0", "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0",
                                                                                          "fadescale": "1"})
    sounds(m, L, "tunnel", 576, 448, F, 640)
    street_front(m, L)

    m.view(160, 120, F, 90, 0, "the door in the wall")
    m.view(110, 350, F, 40, 4, "the guard room")
    m.view(336, 448, F, 0, 2, "the corridor")
    m.view(736, 448, F, 80, 6, "the far cell from the corridor")
    m.view(730, 560, F, 20, 20, "in the far cell: the grate")
    m.view(928, 60, F, 90, 0, "the concrete pipe")


def ammo_crate(m, model, ammo, u, v, yaw, z):
    """A real ammunition crate (item_ammo_crate: players open its lid and take rounds of type `ammo`: 0 pistol, 1 SMG,
    2 pulse rifle, 4 shotgun, 6 .357), standing on z; `model` is the one the game shows for that type (for the checks)."""
    zo = m.stand(model, z)
    m.point("item_ammo_crate", u, v, zo, {"AmmoType": str(ammo), "angles": "0 %d 0" % m.fr.yaw(yaw)}, m.pv)
    m.b.props.append(("item_ammo_crate", model, m.fr.at(u, v, zo), m.fr.yaw(yaw), m.tag))


def wall_point(m, cls, model, u, v, yaw, z):
    """A thing hung on a wall by its back (a health or suit charger): its origin on the wall's face at (u, v), its
    middle at z, facing yaw."""
    m.point(cls, u, v, z, {"angles": "0 %d 0" % m.fr.yaw(yaw)}, m.pv)
    m.b.props.append((cls, model, m.fr.at(u, v, z), m.fr.yaw(yaw), m.tag))


def line_walls(m, rooms, dado=56, low=TILE, high=PLASTER, roof=PLASTER, rail=None):
    """Line a vault's rooms as City 18 lines its own: a skin 2 thick on every wall of these rooms,
    [(u1, v1, u2, v2, ceiling[, floor]), ...] (floors at F unless given): `low` up to `dado` over the floor, `high`
    above it, with a rail of `rail` between when one is given (4 high and 1 proud: the dado line), `high` over a lower
    doorway's head, and a skin of `roof` under each roof. It finds the walls by itself: wherever the square next door
    is not painted, or is solid; never across a doorway."""
    cells, dz = m.b.plan.cells, m.fr.dz

    def spec(u, v):
        x, y = m.fr.pt(u + 32, v + 32)
        return cells.get((x // CELL, y // CELL))
    runs = {}
    for room in rooms:
        u1, v1, u2, v2, ceil = room[:5]
        fl = room[5] if len(room) > 5 else F
        top = ceil - 2 if roof else ceil          # (up to the roof's skin, not into it: their ends would lie flush at a doorway)
        edges = [("u", u, v1, 1, (u, v1 - CELL)) for u in range(u1, u2, CELL)] + [("u", u, v2, -1, (u, v2)) for u in range(u1, u2, CELL)]
        edges += [("v", v, u1, 1, (u1 - CELL, v)) for v in range(v1, v2, CELL)] + [("v", v, u2, -1, (u2, v)) for v in range(v1, v2, CELL)]
        for axis, a, line, side, nb in edges:
            n = spec(*nb)
            if n is None or n[0] == "solid":
                if rail:
                    parts = [(fl, fl + dado, low, 2), (fl + dado, fl + dado + 4, rail, 3), (fl + dado + 4, top, high, 2)]
                else:
                    parts = [(fl, fl + dado, low, 2), (fl + dado, top, high, 2)]
            elif n[0] == "low" and n[3] - dz < ceil:      # (the plan keeps its heights lifted with the module: dz)
                parts = [(n[3] - dz, top, high, 2)]
            else:
                continue
            for z1, z2, mat, thick in parts:
                runs.setdefault((axis, line, side, z1, z2, mat, thick), []).append(a)
        if roof:
            m.det([(u1, v1, ceil - 2, u2, v2, ceil)], roof)
    for (axis, line, side, z1, z2, mat, thick), at in sorted(runs.items()):
        at.sort()
        start = prev = at[0]
        for a in at[1:] + [None]:
            if a is not None and a == prev + CELL:
                prev = a
                continue
            lo, hi = min(line, line + thick * side), max(line, line + thick * side)
            m.det([(start, lo, z1, prev + CELL, hi, z2) if axis == "u" else (lo, start, z1, hi, prev + CELL, z2)], mat)
            start = prev = a


BED_YAW = 90     # the way the clinic's bed frames are turned (their long side is the model's x): 270 puts their heads the other way


# ---------------------------------------------------------------------------
# 2. The clinic
# ---------------------------------------------------------------------------

def m_clinic(m, opt):
    """The clinic: a field hospital in a vault off the left wall, whitewashed over a tiled dado with a stone rail
    between (City 18's dado line), against the canal's concrete. A wide way in between two drawn curtains, light cloth hung from a rail and clear of the floor (a white
    cross on the wall over it); a working health charger on the ward's front wall; a ward of four beds along its back wall under two fluorescent tubes, with cloth screens
    between them (lc_clinic_bed_1 to _4: where a patient lies), a mattress and a bedside drawer each, a chart on two of
    the drawers, a drip stand by two beds and oxygen bottles by the others, a hospital cart, a stove with a pot
    steaming on it, a bench, the nurse's table; a dispensary nook behind a shop's display counter (walk round its left
    end), kitchen shelves behind, jars and kits on it, under a warm dome light; through a curtained opening an
    operating theatre: Episode One's operating table under its surgery lamp, which shines straight down
    (lc_clinic_table: on the table), old stains under it, a drip stand, a cart, a closet and shelves under a cool tube;
    and off the theatre a sluice room with a sink, a boiler, a bucket and a floor grille, and a leak.
    Left as brushes: the curtains and the screens between the beds (cloth: no model), the white cross (paint), the
    theatre's door frame.
    Unchecked: the sound ambient/water/leak_1.wav; which end of a bed frame is its head, and which way the sink,
    stove, radiator, drawers, closet, boiler and shelves face (sizes and places are from the models' own files;
    BED_YAW turns the frames); how the loose mattresses settle on the frames; that Episode One's surgery lamp
    (props_c17/hospital_surgerylight01) hangs from its top (its box is 33 high: placed with its top on the roof)."""
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
                   (768, 448, 960, 768, F + 176), (832, 320, 960, 448, F + 128)], rail=CELL_RAIL)

    # the way in: a white cross on the wall, a caged lamp, two light curtains drawn aside under a valance, clear of the floor
    cf = front_face(m, 168)
    m.det([(474, cf - 2, F + 168, 486, cf, F + 212), (458, cf - 4, F + 184, 502, cf, F + 196)], PLASTER)
    cage(m, 480, front_face(m, 150), F + 150, 270, "235 240 225 80")
    cloth = []
    for k in range(7):
        dv = 2 if k % 2 else 0
        cloth.append((386 + 8 * k, 350 + dv, F + 8, 394 + 8 * k, 351 + dv, F + 124))
        cloth.append((518 + 8 * k, 350 + dv, F + 8, 526 + 8 * k, 351 + dv, F + 124))
    m.det(cloth, CEILING)
    m.det([(386, 349, F + 122, 574, 355, F + 136)], CEILING)                                        # the valance
    m.det([(384, 351, F + 136, 576, 353, F + 138)], BARS)                                           # the rail
    m.lane(480, 352)

    # the ward: four beds, a screen between each (posts, a rail, the cloth), a drawer at every bed
    for k in range(4):
        u, n = 200 + 128 * k, k + 1
        m.static("models/props_wasteland/prison_bedframe001b.mdl", u, 716, BED_YAW)
        mattress(m, u, 716, BED_YAW, z=F + 31)
        m.static("models/props_c17/furnituredrawer002a.mdl", u + 42, 754, 270)
        m.target("lc_clinic_bed_%d" % n, u, 716, F + 28, 270)
        if k % 2 == 0:
            m.static("models/props_c17/hospital_ivstand01.mdl", u - 34, 696, 0)                  # a drip stand
            put(m, [("props_lab/clipboard", u + 42, 752, 80)], F + 34)                         # the chart
        else:
            m.static("models/props_c17/canister01a.mdl", u - 32, 752, 0)                       # oxygen
        if k < 3:
            s = u + 64
            m.det([(s, 652, F + 10, s + 1, 764, F + 78)], CEILING)
            m.det([(s - 1, 650, F, s + 1, 652, F + 80), (s - 1, 764, F, s + 1, 766, F + 80), (s - 1, 652, F + 78, s + 1, 764, F + 80)], BARS)
            m.det([(s - 8, 648, F, s + 8, 654, F + 2), (s - 8, 762, F, s + 8, 768, F + 2)], BARS)          # (the feet hold the posts' feet: nothing flush)
    m.static("models/props_c17/furnitureradiator001a.mdl", 136, 520, 0)
    m.static("models/props_trainstation/bench_indoor001a.mdl", 148, 644, 0)                  # a bench for whoever waits
    m.static("models/props_c17/furnituretable001a.mdl", 656, 500, 0)                         # the nurse's table
    wall_point(m, "item_healthcharger", "models/props_combine/health_charger001.mdl", 600, 450, 90, F + 52)      # a working health charger on the ward's front wall (the owner, 21 November)
    m.static("models/props_c17/furniturechair001a.mdl", 656, 544, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 352, 474, 90)
    put(m, [("props_c17/metalpot001a", 352, 470, 0)], F + 41)                                 # a pot boiling instruments, steaming
    m.smoke(352, 470, F + 56, colour="235 235 235", size=4, length=40, rate=4)
    m.static("models/props_c17/hospital_cart01.mdl", 300, 620, 20)
    for u in (264, 520):
        tube(m, u, 640, F + 160, "225 235 240 110", along="u")
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

    # through to the theatre: a steel frame (the head between its jambs) and one curtain, drawn back
    m.det([(732, 576, F, 740, 580, F + 126), (732, 700, F, 740, 704, F + 126), (732, 580, F + 118, 740, 700, F + 126)], IRON)
    m.det([(735, 580 + 6 * k, F + 8, 737, 586 + 6 * k, F + 118) for k in range(0, 5, 2)]
          + [(733, 586 + 6 * k, F + 8, 735, 592 + 6 * k, F + 118) for k in range(0, 4, 2)], CEILING)
    m.lane(736, 640)

    # the operating theatre: the table under its lamp, stains under it, a drip stand, a cart, a closet, shelves
    cu, cv = 864, 640
    m.static("models/props_c17/hospital_surgerytable01.mdl", cu, cv, 0)
    m.target("lc_clinic_table", cu, cv, F + 38, 270)
    m.static("models/props_c17/hospital_surgerylight01.mdl", cu, cv, 0, z=F + 176 - 34)
    m.spot(cu, cv, F + 138, "255 250 235 1400", 0, pitch=90, cone=36)
    m.decal("decals/bloodstain_002", cu + 20, cv - 26, F)
    m.decal("decals/bloodstain_001", cu - 40, cv + 22, F)
    m.static("models/props_c17/hospital_ivstand01.mdl", 836, 690, 0)
    m.static("models/props_c17/hospital_cart01.mdl", 924, 580, 0)
    m.static("models/props_wasteland/kitchen_shelf002a.mdl", 864, 744, 270)
    m.static("models/props_wasteland/controlroom_storagecloset001a.mdl", 792, 730, 0)
    tube(m, 820, 720, F + 176, "205 225 240 60", along="u")
    m.lane(820, 520)

    # the sluice room: a narrowed way in, the sink, a boiler, a grille in the floor
    m.det([(832, 444, F, 864, 450, F + 128), (928, 444, F, 960, 450, F + 128)], TILE)
    m.static("models/props_interiors/sinkkitchen01a.mdl", 880, 336, 90)
    m.static("models/props_c17/furnitureboiler001a.mdl", 936, 352, 180)
    m.static("models/props_vents/vent_large_grill001.mdl", 896, 400, 0, z=F + 1)
    m.loose("models/props_junk/metalbucket01a.mdl", 852, 420, 0)
    dome(m, 896, 384, F + 126, "225 235 235 45")
    m.sound("ambient/water/leak_1.wav", 896, 350, F + 40, radius=320, volume=3)
    m.grime("stain", 958, 400, F + 90, 1)
    m.lane(896, 400)

    # the marks of use: damp at the way in, a crack high in the ward
    m.grime("stain", 386, 400, F + 60, 2)
    m.grime("crack", 702, 520, F + 130, 3)
    sounds(m, L, "inside", 416, 600, F, 520)
    street_front(m, L)

    m.view(480, 150, F, 90, 0, "the way in")
    m.view(480, 420, F, 100, 4, "the ward")
    m.view(600, 520, F, 190, 6, "the dispensary from the ward")
    m.view(690, 640, F, 0, 8, "the theatre")
    m.view(896, 520, F, 270, 8, "the sluice room")


# ---------------------------------------------------------------------------
# 3. The memorial
# ---------------------------------------------------------------------------

def m_memorial(m, opt):
    """The wall of the dead: a shallow recess in the left wall, open to the sky, its floor one step above the canal's
    (on a street, level with the pavement).
    A stone wall stands against its back, covered in rows of small plaques of dark metal on pale stone backs, no two
    quite the same size (the upper rows half empty: room for more), with a ledge at its foot where candle stubs burn
    steadily among framed photographs turned this way and that, bottles, tins, pots, a child's doll and a shoe; a
    tall candlestick at each end of it; names scratched on the recess's side walls where the plaques ran out, the
    lambda once, small; posters; a line strung across, and a bench out in the canal facing it. lc_memorial_wall is
    the middle of the wall, facing out: the game may one day list there the names of characters who died for good.
    Lit by the candles alone: three small lights among them.
    Left as brushes: the stone wall, its plaques and the candle stubs (Half-Life 2 has no plaque and no candle).
    Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind); which way the picture frames
    face; the candlesticks are Lost Coast's (lostcoast/props_monastery/candlestick). No flowers: there is no model."""
    L, Z = 768, (F if m.fr.dz else F + 16)        # (on a street level with the pavement: the owner, of the playground)
    m.open(0, -256, L, 256)
    m.open(192, 256, 576, 384, floor=Z, mat=STONE_FLOOR)
    m.side(192, 256, 576, 384)
    m.no_bank(192, 240, 576, 272)
    m.taken(168, 100, F, 600, 256, F + 150)
    cheeks(m, 192, 576)
    if Z > F:
        m.det([(192, 232, F, 576, 256, F + 9)], STONE, top=STONE_FLOOR)                  # the step up (1 over the mud the dressing lays: never flush with it)
        m.det([(192, 252, F + 9, 576, 256, Z)], STONE, top=STONE_FLOOR)

    # the stone wall: a plinth whose top is the ledge, the face, a coping
    m.det([(232, 380, Z + 24, 536, 384, Z + 200)], STONE)
    m.det([(224, 366, Z, 544, 384, Z + 24)], STONE, top=STONE_FLOOR)
    m.det([(224, 376, Z + 200, 544, 384, Z + 208), (368, 378, Z + 208, 400, 384, Z + 240)], STONE)
    # the plaques: a pale stone back, a dark metal face 1 proud of it with a border showing, each a little different
    rnd = random.Random(11)
    backs, faces = [], {}
    for row in range(7):
        z = Z + 36 + 22 * row
        for col in range(12):
            if rnd.random() < (0.97, 0.95, 0.9, 0.8, 0.55, 0.3, 0.12)[row]:
                w, h = rnd.choice(((20, 14), (18, 14), (20, 16), (16, 12), (22, 14)))
                u = 242 + 24 * col + rnd.randrange(-1, 2)
                zz = z + rnd.randrange(0, 3)
                backs.append((u, 378, zz, u + w, 380, zz + h))
                faces.setdefault(rnd.choice((IRON, IRON, "metal/metalwall030a")), []).append((u + 2, 377, zz + 2, u + w - 2, 378, zz + h - 2))
    m.det(backs, "stone/stonewall050f")
    for mat, boxes in sorted(faces.items()):
        m.det(boxes, mat)
    m.target("lc_memorial_wall", 384, 372, Z + 112, 270)

    # what people leave: candle stubs on the ledge and at its foot (three small lights among them), pictures, a doll,
    # a shoe, bottles, tins, pots
    for k, (u, high) in enumerate(((236, 5), (251, 3), (270, 7), (296, 4), (309, 6), (338, 3), (352, 8), (377, 5), (391, 4), (415, 7), (440, 3),
                                   (458, 6), (476, 4), (497, 8), (512, 5), (531, 3))):
        candle(m, u, 370 + (k * 5) % 7, Z + 24, high, light=False)
    for u, v, high in ((300, 356, 4), (310, 349, 7), (322, 358, 3), (384, 350, 6), (396, 357, 4), (452, 352, 5), (468, 359, 8), (250, 354, 3)):
        candle(m, u, v, Z, high, light=False)
    for u in (290, 400, 500):
        m.light(u, 360, Z + 40, "255 170 90 22")
    put(m, [("props_lab/frame002a", 326, 374, 255), ("props_lab/frame002a", 406, 373, 282), ("props_lab/frame002a", 488, 374, 264),
            ("props_c17/doll01", 449, 372, 250), ("props_junk/glassbottle01a", 262, 372, 0), ("props_junk/glassbottle01a", 366, 372, 0),
            ("props_junk/metal_paintcan001a", 284, 372, 0), ("props_junk/popcan01a", 430, 371, 0), ("props_junk/metal_paintcan001a", 524, 372, 0)], Z + 24)
    put(m, [("props_junk/terracotta01", 360, 354, 0), ("props_junk/terracotta01", 500, 352, 40), ("props_junk/shoe001a", 424, 352, 200)], Z)
    for u in (210, 558):                                                                 # a tall candlestick at each end
        m.static("models/lostcoast/props_monastery/candlestick.mdl", u, 364, 270, z=Z)
        m.glow(u, 364, Z + 106, "255 200 120", 0.12)

    # writing: names scratched on the side walls where the plaques ran out, the lambda once; posters; a line across
    for k, (u, v, z) in enumerate(((192, 300, Z + 70), (192, 344, Z + 112), (576, 296, Z + 96), (576, 340, Z + 60))):
        m.grime("graffiti", u, v, z, 40 + k)
    m.grime("lambda", 576, 368, Z + 150, 5)
    m.decal("decals/decalposter014a", 192, 316, Z + 160)
    m.decal("decals/decal_posters005a", 576, 322, Z + 190)
    m.rope([(194, 300, Z + 216), (574, 300, Z + 216)], slack=70)

    # the bench out in the canal, facing the wall (far enough out to stand on a street's pavement too)
    m.static("models/props_trainstation/benchoutdoor01a.mdl", 384, 180, 90)
    m.blocked(320, 160, 448, 200)
    m.lane(384, 216)
    m.lane(384, 312, Z)
    m.sound("ambient/levels/canals/windmill_wind_loop1.wav", 384, 300, Z + 160, radius=600, volume=2)
    sounds(m, L, "courtyard", 384, 320, Z, 384)
    street_front(m, L)

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
    Prospekt's fence panels on a kerb; the one gate (lc_pit_gate, on the side toward the canal) swings open when the
    button on the post beside it is pressed (lc_pit_gate_button) or the game tells it to (Open, Close), and steps go
    down from it into the ring. lc_pit_corner_a and lc_pit_corner_b are the two corners the fighters start in (a stool
    in each, a bucket by it, blood in the dirt). Three tiers of seats, 32 high each, concrete on brick risers, stand on
    the three far sides, with stairs of 16 up the middle of each and the city's handrail along the fronts of the upper
    two (the stairs left open); a caged lamp on the wall over each stair lights the crowd, and a painted cloth banner
    hangs on each wall above the top tier; bottles and cans left on the tiers. By the mouth on the right the
    bookmaker's table, chair, till and lamp under a chalk board of odds, betting slips trodden into the floor
    (lc_pit_bookie: where he sits); on the left the corner men's bench, water drum and bucket. Two lamps hang over
    the ring from a gantry (the owner asked for these, not street lamps).
    The gate is Nova Prospekt's gate (interior_fence001g) in its own frame (interior_fence002e), riding on an unseen
    brush door of the same name and inputs that swings it out (Use opens it too); an
    unseen wall stands in the cage's line all round, so the cage holds whatever the panels' own shapes are.
    Left as brushes: the tiers, kerb and posts for the buttons (concrete), the chalk board (no model of one), the
    gantry and its lamps' rods, the banners (cloth: no model).
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
    # the gate: Nova Prospekt's own (interior_fence001g) hung in its frame (interior_fence002e) in the gap, swinging out
    # on an unseen door of the same name (the owner: the panels used before are the gate's frames, "so they have to be
    # fitted inside of the gate frames")
    m.static(narrow, cu - 33, b1, 90, z=F + 6)
    swing_door(m, "lc_pit_gate", [(cu - 55, b1 - 2, F + 7, cu - 10, b1 + 2, F + 112)], STEEL, (cu - 55, b1, F + 60), speed=80, unseen=True)
    rider(m, "lc_pit_gate", "models/props_wasteland/interior_fence001g.mdl", cu - 32, b1, 90, F + 6)
    m.det([(cu + 12, 470, F, cu + 24, 482, F + 64)], MAT["beam"])
    m.button("lc_pit_gate_button", cu + 18, 470, F + 34, 270, [("lc_pit_gate", "Toggle", "", 0)])
    m.test_button((542, 470, F + 40, 550, 478, F + 56), [("OnIn", "lc_pit_gate", "Open"), ("OnOut", "lc_pit_gate", "Close")])
    m.det([(536, 468, F, 556, 480, F + 40)], MAT["beam"])
    m.steps(608, cu - 64, cu, F - 64, F, "v", -1)
    m.target("lc_pit_corner_a", 496, 584, F - 56, 45)
    m.target("lc_pit_corner_b", 784, 848, F - 56, 225)
    m.static("models/props_c17/chair_stool01a.mdl", 466, 530, 0, z=F - 64)
    m.static("models/props_c17/chair_stool01a.mdl", 814, 878, 0, z=F - 64)
    m.loose("models/props_junk/metalbucket01a.mdl", 480, 560, 0, z=F - 64)
    m.loose("models/props_junk/metalbucket01a.mdl", 794, 850, 0, z=F - 64)
    m.decal("decals/bloodstain_003", 640, 700, F - 64)
    m.decal("decals/bloodstain_001", 590, 770, F - 64)

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
        s = min(d, e)               # (the sides stop where the back's row of the same height starts: never two tops in one plane)
        tiers += [(cu - d - 64, cv - 192, F, cu - d, cv + s, z), (cu + d, cv - 192, F, cu + d + 64, cv + s, z), (cu - e, cv + d, F, cu + e, cv + d + 64, z)]
        stairs += [(cu - d, cv - 32, F, cu - d + 16, cv + 32, z - 16), (cu + d - 16, cv - 32, F, cu + d, cv + 32, z - 16), (cu - 32, cv + d - 16, F, cu + 32, cv + d, z - 16)]
        if k:                       # the city's handrail along the upper two rows' fronts, the stairs left open
            for a, b in ((cv - 184, cv - 40), (cv + 40, cv + s - 8)):
                rail_run(m, a, b, cu - d - 4, "v", z)
                rail_run(m, a, b, cu + d + 4, "v", z)
            for a, b in ((cu - s + 8, cu - 40), (cu + 40, cu + s - 8)):
                rail_run(m, a, b, cv + d + 4, "u", z)
    m.det(tiers, OLD_BRICK, top=MAT["quay_floor"])
    m.det(stairs, WALL, top=MAT["stairs"])
    # the crowd's side lit: a caged lamp on the wall over each stair; a painted banner on each wall above the top row
    for u, v, out in ((cu - 448, cv, 0), (cu + 448, cv, 180), (cu, cv + 448, 270)):
        cage(m, u, v, F + 176, out, "255 205 150 110")
    for cloth, rod, face, sign in (((cu - 448, cv - 200, cu - 447, cv - 72), (cu - 447, cv - 204, cu - 445, cv - 68), (cu - 447, cv - 136), "a"),
                                   ((cu + 447, cv + 72, cu + 448, cv + 200), (cu + 445, cv + 68, cu + 447, cv + 204), (cu + 447, cv + 136), "b"),
                                   ((cu + 80, cv + 447, cu + 208, cv + 448), (cu + 76, cv + 445, cu + 212, cv + 447), (cu + 144, cv + 447), "c")):
        m.det([cloth[:2] + (F + 132,) + cloth[2:] + (F + 216,)], CLOTH)
        m.det([rod[:2] + (F + 216,) + rod[2:] + (F + 218,)], BARS)                     # the pole it hangs from
        m.decal("decals/decalsignpainted001%s" % sign, face[0], face[1], F + 176)
    # what a fight night leaves: bottles and cans on the rows
    put(m, [("props_junk/glassbottle01a", cu - 352, cv + 140, 0), ("props_junk/popcan01a", cu + 356, cv - 100, 40), ("props_junk/garbage_metalcan001a", cu - 150, cv + 340, 0)], F + 64)
    put(m, [("props_junk/glassbottle01a", cu - 414, cv - 60, 0), ("props_junk/popcan01a", cu + 150, cv + 412, 0)], F + 96)

    # the bookmaker, right of the mouth: table, chair, till, a desk lamp, the board of odds on the wall
    m.static("models/props_c17/furnituretable002a.mdl", 948, 424, 90)
    m.static("models/props_c17/furniturechair001a.mdl", 944, 380, 90)
    m.target("lc_pit_bookie", 944, 380, F + 8, 90)
    put(m, [("props_c17/cashregister01a", 966, 420, 270), ("props_lab/desklamp01", 926, 426, 60)], F + 38)
    m.light(926, 426, F + 72, "255 205 140 120")
    m.det([(964, 384, F + 44, 1020, 386, F + 104)], MAT["black"])
    m.det([(962, 384, F + 42, 1022, 387, F + 44), (962, 384, F + 104, 1022, 387, F + 106), (962, 384, F + 44, 964, 387, F + 104), (1020, 384, F + 44, 1022, 387, F + 104)], TIMBER)
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
    m.grime("trash", 930, 450, F, 1)                                                   # betting slips trodden in
    m.grime("trash", 980, 470, F, 2)
    sounds(m, L, "square", cu, cv, F, 640)
    street_front(m, L)

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
POLE = "models/props_c17/signpole001.mdl"


def lean(m, model, u, v, z, yaw, roll):
    """A pole standing on z at (u, v) and leaning: roll tilts the model's top toward its -y (a pole the model's own
    size: its foot at its origin). A tilted prop: the floating check leaves it alone."""
    m.prop("prop_dynamic_override", model, u, v, yaw, z, {"angles": "0 %d %d" % (m.fr.yaw(yaw), roll), "solid": "6", "disableshadows": "1", "fademindist": "-1",
                                                          "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})


def m_garden(m, opt):
    """The walled garden: where the Resistance grows food. A gap in the left wall, a fence of boards and an iron gate
    (lc_garden_gate: Use swings it in), opens on a yard 640 by 448 under the open sky: in a canal 24 above its floor and
    two steps up, on a street level with the pavement (the owner, of the playground: places sit at the pavement's
    height). Its ground is grass, worn to earth along a path of flagstones set into it from the gate to the lean-to.
    Six raised soil beds edged with timber, three on each side of the path (lc_garden_bed_1 to _6: on the beds, for a
    farming job; 1 to 3 on the left going back, 4 to 6 on the right), ridged. lc_garden_plot_1 to _8 are the planting
    spots for the game (melons, pumpkins): info_targets on the soil of the four beds that have no bean poles, two a
    bed, each a little off the line and turned an odd way (the same every build). Over the first bed on each side
    bean poles stand in pairs leaning together, tied to a cane along the top, as a crop is grown; a scarecrow in the
    middle bed on the right. Ivy climbs the side walls. Against the back wall a tool lean-to (a desk with pots, jars
    and a sack, a shovel, a bucket, a bell lamp), a cold frame (an old window on a timber box over seedlings), a
    barrel under a gutter pipe in the left corner with a puddle by it, a compost heap behind boards in the right
    corner; a push cart, a wheelbarrow and a crate of melons on the path.
    The gate is props_c17/gate_door01a riding on an unseen brush door of the same name.
    Left as brushes: the beds (timber and soil), the canes along the bean poles, the scarecrow (no model of one), the
    lean-to, the cold frame, the fence's two rails.
    Unchecked: which way the gate, the boards and the ivy face (ivy_01 is thin along its x: its back put to the
    wall); how far the bean poles lean (roll 16: they should meet over the bed's middle); how the loose things lie
    once the game drops them."""
    L = 1280
    Z = F if m.fr.dz else F + 24
    m.open(0, -256, L, 256)
    m.open(576, 256, 704, 320, floor=Z, mat=CRACKED)
    m.open(320, 320, 960, 768, floor=Z, mat=GRASS)
    m.side(320, 256, 960, 768)
    m.no_bank(576, 240, 704, 272)
    m.taken(552, 100, F, 728, 256, F + 150)
    cheeks(m, 576, 704)
    if Z > F:
        m.steps(220, 576, 704, F, Z, "v", 1)
        m.blocked(576, 208, 704, 256)
    m.lane(640, 200)
    m.lane(640, 336, Z)

    # the fence of boards across half the gap, and the gate that swings in
    for k in range(6):
        m.static("models/props_debris/wood_board04a.mdl", 583 + 10 * k, 288, 90, z=Z)
    m.det([(576, 289, Z + 14, 638, 291, Z + 18), (576, 289, Z + 46, 638, 291, Z + 50), (638, 286, Z, 642, 292, Z + 66)], TIMBER)
    swing_door(m, "lc_garden_gate", [(646, 287, Z + 2, 702, 291, Z + 110)], STEEL, (702, 289, Z + 56), reverse=True, sound="doors/gate_move1.wav", unseen=True)
    rider(m, "lc_garden_gate", "models/props_c17/gate_door01a.mdl", 674, 289, 90, Z)

    # the ground worn to earth along the path, and the flagstones in it
    m.det([(600, 320, Z, 680, 688, Z + 1)], DIRT)
    m.det([(616 + (k % 2) * 14, 348 + 62 * k, Z, 652 + (k % 2) * 14, 386 + 62 * k, Z + 2) for k in range(5)], STONE, top=STONE_FLOOR)

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
    m.det(edges + stakes, TIMBER)
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

    # bean poles over the first bed on each side: pairs leaning together from the bed's two long edges, a cane along the top
    canes = []
    for (u, v) in (beds[0], beds[3]):
        for pu in range(u + 32, u + 190, 64):
            lean(m, POLE, pu, v + 8, Z + 13, 0, -16)
            lean(m, POLE, pu, v + 64, Z + 13, 0, 16)
        canes.append((u + 16, v + 35, Z + 112, u + 176, v + 37, Z + 114))
    m.det(canes, TIMBER)

    # the scarecrow, in the middle bed on the right
    su, sv = 832, 508
    m.det([(su - 2, sv - 2, Z + 13, su + 2, sv + 2, Z + 96), (su - 28, sv - 1, Z + 76, su + 28, sv + 1, Z + 80)], TIMBER)
    m.det([(su - 13, sv - 3, Z + 46, su + 13, sv + 3, Z + 82), (su - 30, sv - 2, Z + 70, su - 13, sv + 2, Z + 82), (su + 13, sv - 2, Z + 70, su + 30, sv + 2, Z + 82)], CLOTH)
    m.det([(su - 6, sv - 6, Z + 84, su + 6, sv + 6, Z + 97)], PLASTER)
    m.shapes([vpipe(su, sv, 11, Z + 97, Z + 99, TIN), vpipe(su, sv, 6, Z + 99, Z + 105, TIN)])

    # ivy up the side walls
    m.static("models/props_foliage/ivy_01.mdl", 344, 392, 0, z=Z)
    m.static("models/props_foliage/ivy_01.mdl", 936, 569, 180, z=Z)

    # the tool lean-to against the back wall
    m.hut(560, 688, 720, 768, Z, WOOD, high=96, front="lo", open_front=True)
    m.static("models/props_interiors/furniture_desk01a.mdl", 640, 740, 90, z=Z)
    for u in (616, 640):
        m.loose("models/props_junk/terracotta01.mdl", u, 742, 0, z=Z + 40)
    put(m, [("props_lab/jar01a", 662, 744, 0), ("props_lab/jar01b", 664, 732, 40)], Z + 40)
    m.loose("models/props_junk/garbage_bag001a.mdl", 702, 744, 80, z=Z)
    m.loose("models/props_junk/metalbucket01a.mdl", 592, 712, 0, z=Z)
    m.loose("models/props_junk/shovel01a.mdl", 694, 712, 90, z=Z)
    bell(m, 640, 712, Z + 96, "255 200 130 90")

    # a cold frame by the back wall: a timber box, seedlings in it, an old window laid sloping over it
    c1, c2, w1, w2 = 744, 848, 716, 764
    m.det([(c1, w1, Z, c2, w1 + 3, Z + 12), (c1, w2 - 3, Z, c2, w2, Z + 24)], TIMBER)
    side = [(w1 + 3, Z), (w2 - 3, Z), (w2 - 3, Z + 23), (w1 + 3, Z + 13)]
    m.shapes([prism(side, "x", c1, c1 + 3, TIMBER), prism(side, "x", c2 - 3, c2, TIMBER)])
    m.det([(c1 + 3, w1 + 3, Z, c2 - 3, w2 - 3, Z + 6)], DIRT)
    m.shapes([prism([(w1, Z + 12), (w2, Z + 24), (w2, Z + 25), (w1, Z + 13)], "x", c1 + 1, c2 - 1, "glass/glasswindow007a")])

    # a barrel under a gutter pipe in the left corner, a puddle where it overflows
    m.static("models/props_borealis/bluebarrel001.mdl", 348, 742, 0, z=Z)
    m.static("models/props_pipes/gutter_256_001a.mdl", 348, 760, 0, z=Z + 56)
    m.static("models/props_c17/oildrum001.mdl", 400, 744, 0, z=Z)
    m.grime("puddle", 372, 712, Z, 1)

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
    sounds(m, L, "courtyard", 640, 540, Z, 512)
    street_front(m, L)

    m.view(640, 120, F, 90, 0, "the gate from the canal")
    m.view(640, 330, Z, 90, 10, "coming in")
    m.view(640, 668, Z, 270, 12, "from the lean-to")
    m.view(590, 610, Z, 140, 0, "the barrel and the gutter")
    m.view(600, 500, Z, 215, 8, "the bean poles")
    m.view(650, 450, Z, 20, 6, "the scarecrow")


# ---------------------------------------------------------------------------
# 6. The stash
# ---------------------------------------------------------------------------

def gun_rack(m, a, b, at, side, z, axis, rows):
    """A rack for guns on a wall (Half-Life 2 has no model of one: a timber board, a rail and pegs for each row), with
    Half-Life 2's own weapon world models resting on the pegs, upright and their length along the wall, not solid (so
    nobody snags on them). a..b along the wall; `at` the wall's line (the room's lining is 2 thick on it); side +1 or
    -1, the way the room is from it; axis "u" or "v", the way the wall runs. rows: [(the pegs' height over z,
    [(the model's name under models/weapons/, its middle along the wall), ...]), ...]."""
    import map_assets

    def box(p1, q1, z1, p2, q2, z2):
        q1, q2 = at + side * q1, at + side * q2
        lo, hi = min(q1, q2), max(q1, q2)
        return (p1, lo, z1, p2, hi, z2) if axis == "u" else (lo, p1, z1, hi, p2, z2)
    top = max(h for h, _ in rows) + 34
    parts = [box(a, 2, z + 24, b, 5, z + top), box(a, 2, z + top, b, 7, z + top + 3)]          # the board, a shelf on its top
    for h, guns in rows:
        parts.append(box(a, 5, z + h - 6, b, 7, z + h - 2))                                     # the rail under the row
        for name, mid in guns:
            model = "models/weapons/%s.mdl" % name
            x1, y1, z1, x2, y2, z2 = map_assets.size(model)
            half = int((x2 - x1) * 0.3)
            parts += [box(mid - half - 1, 7, z + h - 5, mid - half + 1, 12, z + h), box(mid + half - 1, 7, z + h - 5, mid + half + 1, 12, z + h)]
            o = mid - (x1 + x2) / 2
            if axis == "u":            # (yaw 0: the gun's x along u, its y along v)
                q = at - 7 - y2 if side < 0 else at + 7 - y1
                m.dynamic(model, int(round(o)), int(round(q)), 0, z + h, solid=False)
            else:                      # (yaw 90: the gun's x along v, its y along -u)
                q = at + 7 + y2 if side > 0 else at - 7 + y1
                m.dynamic(model, int(round(q)), int(round(o)), 90, z + h, solid=False)
    m.det(parts, TIMBER)


def m_stash(m, opt):
    """The stash: a secret arms room. From the canal there is only a run of rusted pipes on the left wall with a valve
    wheel on the thick one (lc_stash_valve: Use turns it a quarter, and it turns back by itself), and for the
    observant a small lambda sprayed low behind the pipe. Turning it slides a section of the wall itself aside
    (lc_stash_wall: 96 wide, 112 high, of the wall's own concrete, flush with it when shut, its sill at the top of the
    bank, 128 up); it shuts again by itself after 12 seconds, and the button on the wall just inside (lc_stash_inside)
    opens it from within. Behind: a short passage of raw concrete that turns twice, then the arms room (lc_stash_room:
    its middle), a cellar of brick over a damp concrete plinth, the pipes it hides running along under its roof, lit
    by two fluorescent tubes. Racks on two walls hold Half-Life 2's own guns (pulse rifles, shotguns, SMGs, a rocket
    launcher, a crowbar, pistols; a peg or two empty: those are out); a steel workbench against the wall toward the
    canal with a vice, tools, a parts bin and a crossbow on it, the canal map and a board of papers on the wall over
    it; a planning table with papers, a radio, a desk lamp, a revolver and a mug, its chair pushed back; two of the
    Combine's ammunition crates and wooden crates along the far wall (the SMG one a real crate, opened for rounds);
    boxes of rounds on a shelf.
    Left as brushes: the racks (Half-Life 2 has no gun rack: a board, rails and pegs), the valve's wheel (it turns).
    Unchecked: func_rot_button (the valve wheel) is from memory, with its turning axis set by spawnflag 64 or 128 (the
    map's x or y, whichever way the module is turned): if the wheel turns the wrong way round or not at all, the door
    still needs only one Open sent to lc_stash_wall. The door slides a little inward as well as aside (its movedir is
    2 degrees off the wall's line) so that, open, it does not lie in the wall's own face. Sounds doors/doormove1.wav and
    doormove2.wav are the bunker doors' own. Which way the weapon models' muzzles point on the racks (their length is
    their x), which side of the ammunition crates is their front, and whether the canal map (props_canal/canalmap001)
    reads as a map on a wall."""
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
              prism(octagon(88, vz + 14, 5), "y", 236, 240, IRON)])                          # a gauge
    m.det([(u - 3, 250, vz - 12, u + 3, 256, vz + 12) for u in (64, 152)] + [(u - 2, 252, F + 208, u + 2, 256, F + 220) for u in (96, 128)]
          + [(87, 240, vz + 8, 89, 246, vz + 12)], IRON)
    m.det([(30, 236, vz - 10, 50, 256, vz + 10), (166, 236, vz - 10, 186, 256, vz + 10)]                                # a fitting at every bend
          + [(143, 243, z - 7, 157, 256, z + 7) for z in (F + 214, F + 246)] + [(57, 243, F + 207, 71, 256, F + 221)], IRON)
    m.det([(vu - 9, 236, vz - 10, vu + 9, 256, vz + 10)], IRON)                              # the valve's body
    m.shapes([prism(octagon(vu, vz, 3), "y", 228, 236, BARS)])                               # its stem
    axis = 64 if m.fr.ax("v") == "x" else 128
    shape_entity(m, "func_rot_button", {
        "targetname": "lc_stash_valve", "origin": "%d %d %d" % (m.fr.at(vu, 226, vz)), "distance": "90", "speed": "60", "wait": "4", "sounds": "0", "health": "0",
        "spawnflags": str(1024 + axis), "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
        shapes=ring("y", vu, vz, 12, 15, 224, 228, BARS),
        boxes=[(vu - 13, 225, vz - 1, vu + 13, 227, vz + 1), (vu - 1, 225, vz - 13, vu + 1, 227, vz + 13), (vu - 3, 223, vz - 3, vu + 3, 229, vz + 3)], mat=BARS,
        connections=[("OnPressed", "lc_stash_wall", "Open", "", 0)])
    m.grime("lambda", 184, 256, F + 146, 3)                                                  # (small, low, half behind the pipe's down run)
    m.grime("stain", 90, 256, F + 200, 4)                                                    # (rust run from the joints)

    # just inside: the button that opens it from within, a dim lamp, a crate; the passage's raw concrete, stained
    m.button("lc_stash_inside", 192, 350, Z + 40, 0, [("lc_stash_wall", "Open", "", 0)])
    m.lamp(256, 340, Z + 100, "255 200 140 45")
    m.static("models/props_junk/wood_crate001a.mdl", 290, 300, 0, z=Z)
    m.grime("stain", 256, 384, Z + 70, 5)
    m.grime("crack", 352, 384, Z + 60, 6)
    m.lane(256, 336, Z)
    m.lane(352, 352, Z)

    # the arms room: brick over a damp plinth, a concrete roof, the hidden pipes along under it
    R1, R2, S1, S2, top = 384, 704, 320, 576, Z + 128
    line_walls(m, [(R1, S1, R2, S2, top, Z)], dado=24, low=DAMP, high=RED_BRICK, roof=CONC_CEIL)
    for k in range(6):
        m.static("models/props_pipes/pipe02_straight01_long.mdl", 409 + 49 * k, 327, 90, z=top - 11)
        m.static("models/props_pipes/pipe02_connector01.mdl", 433 + 49 * k, 327, 0, z=top - 14)
    m.static("models/props_pipes/pipe02_straight01_short.mdl", 687, 327, 90, z=top - 11)
    m.target("lc_stash_room", 544, 448, Z + 8, 0)

    # the racks: along the back wall, and the wall beside the way in
    gun_rack(m, 400, 600, S2, -1, Z, "u", [(40, [("w_irifle", 432), ("w_shotgun", 488), ("w_irifle", 576)]),
                                           (76, [("w_smg1", 418), ("w_smg1", 448), ("w_shotgun", 500), ("w_rocket_launcher", 566)])])
    gun_rack(m, 408, 560, R1, 1, Z, "v", [(40, [("w_shotgun", 432), ("w_smg1", 476), ("w_crowbar", 530)]),
                                          (76, [("w_irifle", 448), ("w_pistol", 504), ("w_pistol", 530)])])

    # the workbench on the wall toward the canal: a vice, tools, a parts bin, a crossbow; the canal map and papers over it
    bu = 530
    m.static("models/props_wasteland/controlroom_desk001b.mdl", bu, S1 + 24, 90, z=Z)
    m.static("models/props_c17/grinderclamp01a.mdl", bu + 46, S1 + 16, 0, z=Z + 34)
    m.static("models/props_lab/partsbin01.mdl", bu - 44, S1 + 10, 90, z=Z + 34)
    put(m, [("props_c17/tools_wrench01a", bu + 18, S1 + 32, 10), ("props_c17/tools_pliers01a", bu + 30, S1 + 24, 80)], Z + 34)
    m.dynamic("models/weapons/w_crossbow.mdl", bu - 10, S1 + 26, 0, z=Z + 34, solid=False)
    m.static("models/props_canal/canalmap001.mdl", bu, S1 + 4, 90, z=Z + 40)
    m.static("models/props_lab/corkboard002.mdl", 612, S1 + 4, 90, z=Z + 44)
    tube(m, bu, S1 + 44, top, "215 228 235 70", along="u")

    # the planning table: papers, a radio, a lamp, a revolver, a mug; the chair pushed back
    tu, tv = 560, 452
    m.static("models/props_c17/furnituretable001a.mdl", tu, tv, 0, z=Z)
    put(m, [("props_c17/paper01", tu - 6, tv - 4, 20), ("props_c17/paper01", tu + 8, tv + 6, 75), ("props_lab/citizenradio", tu - 12, tv + 14, 200),
            ("props_c17/lamp001a", tu + 16, tv - 14, 0), ("props_junk/garbage_coffeemug001a", tu + 18, tv + 12, 0)], Z + 37)
    m.dynamic("models/weapons/w_357.mdl", tu + 2, tv - 12, 300, z=Z + 37, solid=False)
    m.light(tu + 16, tv - 14, Z + 64, "255 200 130 40")
    m.static("models/props_c17/furniturechair001a.mdl", tu + 46, tv + 26, 200, z=Z)
    tube(m, tu, tv, top, "215 228 235 60", along="u")

    # the stock along the far wall: the Combine's ammunition crates, wooden crates, boxes of rounds on a shelf
    ammo_crate(m, "models/items/ammocrate_smg1.mdl", 1, R2 - 19, 410, 180, Z)      # (a real one: open it for SMG rounds, the owner, 21 November)
    m.dynamic("models/items/ammocrate_ar2.mdl", R2 - 19, 472, 180, z=Z)
    m.static("models/props_junk/wood_crate001a.mdl", R2 - 24, S1 + 24, 0, z=Z)
    m.static("models/props_junk/wood_crate001a.mdl", R2 - 24, S1 + 24, 10, z=Z + 40)
    m.static("models/props_c17/shelfunit01a.mdl", 648, S2 - 14, 0, z=Z)
    put(m, [("items/boxmrounds", 630, S2 - 14, 0), ("items/boxsrounds", 662, S2 - 14, 90)], Z + 93)
    m.lane(544, 400, Z)

    # the grime: water down the brick, a crack, trash, the lambda
    m.grime("stain", R2 - 2, 530, Z + 96, 7)
    m.grime("stain", 650, S2 - 2, Z + 112, 8)
    m.grime("crack", R1 + 2, 396, Z + 90, 9)
    m.grime("lambda", R2 - 2, 440, Z + 76, 10)
    m.grime("trash", 470, 520, Z, 11)
    sounds(m, L, "tunnel", 544, 448, Z, 384)
    street_front(m, L)

    m.view(150, 40, F, 75, -8, "the pipes: nothing to see")
    m.view(256, 40, F, 90, -12, "at the wall that opens")
    m.view(256, 356, Z, 270, 4, "inside, looking back at the wall")
    m.view(400, 350, Z, 30, 8, "the arms room")
    m.view(640, 520, Z, 215, 10, "the workbench and the map")
    m.view(520, 400, Z, 90, 6, "the rack")


# ---------------------------------------------------------------------------
# 7. The black market
# ---------------------------------------------------------------------------

def m_market(m, opt):
    """The black market: a vaulted arcade inside the left wall, entered from the canal's floor by two archways, its
    walls as City 18's vaulted halls are (brick to the dado, plaster above, a stone rail between), damp at the foot
    and blackened over the fire. Five stalls in alcoves along its back, each with a steel kitchen counter across the
    right half of its front (the left half is the way behind it), a shelf unit, a trade's goods on the counter (food,
    the Combine's ration packs, parts and tools, medicine, radios), a dome light, and a roll shutter of the city's
    corrugated door metal with a handle at its foot (lc_market_shutter_1 to _5: each lifts into its box and drops
    when the button inside its own stall is pressed, lc_market_button_1 to _5, or when the game sends Open or
    Close); the two that start down carry a padlock on the handle, and three boxes carry a painted sign.
    lc_market_stall_1 to _5 are where the stallholders stand, facing out. A fire drum burns in the middle of the
    arcade between two benches, its smoke gathering under the vault; a lookout's stool stands inside each archway,
    where the canal can be watched both ways; ribs carry the vault at every pier.
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
        if not in_town(m):                                         # (in the town the house front dresses the arch)
            m.det([(au + 54, 250, A - 6, au + 74, 256, A + 18)], MAT["beam"])
        m.lane(au + 64, 288)
        m.lane(au + 64, 400)
    stalls = (192, 384, 576, 768, 960)
    for su in stalls:
        m.low(su, 512, su + 128, 704, A, mat=STONE_FLOOR)      # (192 deep: the owner, "no room to even walk into them")
    m.side(64, 256, 1216, 704)
    line_walls(m, [(128, 320, 1152, 512, H)] + [(su, 512, su + 128, 704, A) for su in stalls], dado=64, low=OLD_BRICK, high=CELL_HIGH,
               roof=CELL_HIGH, rail=CELL_RAIL)
    for ru in (136, 352, 544, 736, 928, 1128):
        arch_rib(m, ru - 8, ru + 8, 320, 512, H, 72, MAT["beam"])

    wares = ((("props_junk/watermelon01", 76, 0), ("props_junk/popcan01a", 100, 100)),                  # food, and Breen's water
             (("weapons/w_package", 80, 10), ("weapons/w_package", 104, 80)),                          # the Combine's ration packs, resold
             (("props_lab/partsbin01", 78, 0), ("props_c17/tools_wrench01a", 104, 40)),                # parts and tools
             (("items/healthkit", 78, 80), ("props_lab/jar01b", 104, 30)),                             # medicine
             (("props_lab/citizenradio", 80, 270), ("props_lab/reciever01a", 108, 280)))               # radios
    for k, su in enumerate(stalls):
        n = k + 1
        # the counter across the right half of the front; the left half is the way in behind it
        m.static("models/props_wasteland/kitchen_counter001%s.mdl" % "abcab"[k], su + 94, 545, 90)
        put(m, [(name, su + du, 536 + 7 * (j % 3), yaw) for j, (name, du, yaw) in enumerate(wares[k])], F + 40)
        if k % 2 == 0:
            m.static("models/props_c17/cashregister01a.mdl", su + 100, 562, 90, z=F + 40)
        # the shutter, and the box it rolls up into
        name = "lc_market_shutter_%d" % n
        slide_door(m, name, [((su, 507, F + 42, su + 128, 509, A), SHUTTER), ((su, 506, F + 42, su + 128, 510, F + 46), BARS),
                             ((su + 58, 504, F + 44, su + 70, 506, F + 48), IRON)], "-90 0 0", speed=50, lip=6, starts_open=k % 2 == 0)
        if k % 2:                                              # (down, and locked: a padlock on the handle, riding with the shutter)
            rider(m, name, "models/props_wasteland/prison_padlock001a.mdl", su + 64, 502, 90, F + 36)
        m.det([(su - 4, 500, A - 4, su + 132, 512, H)], TIN)                                # the box it rolls into, up to the vault
        if k % 2 == 0:
            m.decal("decals/decalsignpainted001%s" % "abc"[k // 2], su + 64, 500, A + 20)    # the trade, painted on the box
        m.det([(su - 4, 504, F, su + 2, 512, A - 4), (su + 126, 504, F, su + 132, 512, A - 4)], BARS)
        m.button("lc_market_button_%d" % n, su, 600, F + 44, 0, [("lc_market_shutter_%d" % n, "Toggle", "", 0)])
        m.target("lc_market_stall_%d" % n, su + 80, 616, F + 8, 270)
        m.static("models/props_c17/shelfunit01a.mdl", su + 64, 692, 0)
        dome(m, su + 64, 620, A, "255 205 140 75")
        m.lane(su + 64, 470)
        m.lane(su + 40, 630)
    m.static("models/props_c17/shelfunit01a.mdl", 1138, 420, 90)        # the end of the arcade: spare stock

    # the middle of the arcade: a fire drum between two benches, bell lamps along the roof
    bu, bv = 640, 400
    m.static("models/props_c17/oildrum001.mdl", bu, bv, 0)
    fire(m, bu, bv, F + 46, size=20, light="255 160 80 130", drop=False)
    m.smoke(bu, bv, F + 70, colour="60 60 60", size=8, length=90, rate=5)                 # its smoke, gathering under the vault
    m.decal("decals/scorch1", bu, bv, H - 2)                                               # and the soot it leaves there
    m.sound("ambient/fire/fire_small_loop1.wav", bu, bv, F + 40, radius=420, volume=3)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", bu - 56, bv, 0)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", bu + 56, bv, 0)
    m.blocked(bu - 80, bv - 60, bu + 80, bv + 60)
    for u in (448, 832):
        bell(m, u, 416, H, "255 210 150 120")
    # the lookouts' stools, inside each archway on the side they watch from
    for su in (232, 1048):
        m.static("models/props_c17/chair_stool01a.mdl", su, 340, 0)
    m.grime("poster", 352, 510, F + 100, 1)
    m.grime("poster", 928, 510, F + 98, 2)
    for k, (u, v) in enumerate(((180, 322), (560, 322), (1100, 322), (700, 510))):
        m.grime("stain", u, v, F + 34, 3 + k)                                              # damp at the foot of the walls
    m.grime("trash", 450, 360, F, 7)
    m.grime("lambda", 1150, 420, F + 120, 8)
    sounds(m, L, "inside", 640, 420, F, 560)
    street_front(m, L)

    m.view(320, 120, F, 90, 0, "an archway from the canal")
    m.view(180, 416, F, 0, 2, "down the arcade")
    m.view(640, 340, F, 80, 2, "the fire drum and the stalls")
    m.view(480, 440, F, 115, 4, "a stall")
    m.view(470, 600, F, 300, 6, "behind a counter")


# ---------------------------------------------------------------------------
# 8. The pamphlet press
# ---------------------------------------------------------------------------

def m_press(m, opt):
    """The pamphlet press: a short side tunnel off the left wall, shut by a wall with one of the city's doors in it
    (lc_press_door, a prop_door_rotating: anyone opens it; the game may Lock it), bricked up across the tunnel with a
    timber casing round the door. Behind is the printing room, brick to a timber dado rail and stained plaster above,
    its corners dark: lit only by a work lamp hung low in front of the press and the lamp on the table. A hand press (a
    bed on legs with the forme on it, a platen hanging from a screw between two cheeks, a long lever), lc_press_machine
    on its bed; a chest of drawers for the type, a radio on it; three drying lines across the room hung with sheets;
    boxes and bundles of paper on a pallet (lc_press_stack); a table with a lamp and papers; a board of proofs on the
    wall; drums and cans of ink, ink spattered on the walls by the press; a runner's case by the door; a mattress.
    Left as brushes: the hand press (Half-Life 2 has no printing press), the sheets on the lines (they hang; the
    paper models lie flat).
    Unchecked: how taut the drying lines hang; which way the drawers face."""
    L, H = 768, F + 144
    m.open(0, -256, L, 256)
    m.low(256, 256, 384, 512, F + 128)                          # the side tunnel
    m.low(192, 512, 640, 768, H, mat=CRACKED)                   # the printing room
    m.side(128, 256, 704, 832)
    line_walls(m, [(192, 512, 640, 768, H)], dado=48, low=RED_BRICK, high="plaster/plasterwall046b", roof=CEILING, rail=TIMBER)
    m.portal(256, 318, F, 384, 320, F + 128)
    m.taken(232, 110, F, 408, 256, F + 170)
    cheeks(m, 256, 384)
    m.lane(320, 300)

    # across the tunnel a wall of brick with the city's own door in it, that opens (the owner: "the printing press room
    # is missing its door", and of the crates that hid it: "idk why you have a heap of boxes ... in the entrance"): the
    # casing's posts and head bury the wall's edges, so nothing lies flush
    from map_town import real_door, R as TR
    m.det([(256, 408, F, 293, 424, F + 128), (347, 408, F, 384, 424, F + 128), (293, 408, F + 112, 347, 424, F + 128)], RED_BRICK)
    m.det([(291, 406, F, 295, 426, F + 114), (345, 406, F, 349, 426, F + 114), (295, 406, F + 110, 345, 426, F + 114)], TR["frame"])
    real_door(m, 297, 416, 270, F, "lc_press_door")
    m.grime("number", 320, 406, F + 120, 1)
    m.light(320, 300, F + 110, "200 205 190 25")

    # the press
    pu, pv = 300, 664
    m.det([(pu - 28, pv - 30, F, pu - 22, pv - 24, F + 30), (pu + 22, pv - 30, F, pu + 28, pv - 24, F + 30),
           (pu - 28, pv + 24, F, pu - 22, pv + 30, F + 30), (pu + 22, pv + 24, F, pu + 28, pv + 30, F + 30),
           (pu - 34, pv - 8, F, pu - 26, pv + 8, F + 102), (pu + 26, pv - 8, F, pu + 34, pv + 8, F + 102), (pu - 38, pv - 10, F + 102, pu + 38, pv + 10, F + 114)], TIMBER)
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
    put(m, [("props_lab/citizenradio", 208, 592, 0)], F + 40)

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
    m.det(sheets, CEILING)

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
    mattress(m, 600, 610, 90)
    m.lamp(300, 620, F + 110, "255 200 130 120", hang=26)                                 # the work lamp, hung low in front of the press
    m.static("models/props_lab/corkboard002.mdl", 480, 764, 270, z=F + 58)                 # the proofs, pinned up
    m.loose("models/props_c17/briefcase001a.mdl", 404, 528, 0)                             # the runner's case, by the door
    m.decal("decals/decal_paintsplatterblue001", 330, 766, F + 60)                        # ink, where the press is worked
    m.grime("stain", 194, 690, F + 70, 2)
    m.grime("stain", 638, 720, F + 100, 3)
    m.grime("lambda", 194, 720, F + 84, 4)
    m.grime("poster", 638, 620, F + 92, 5)
    for u, v in ((320, 480), (400, 600), (500, 620)):
        m.lane(u, v)
    sounds(m, L, "inside", 416, 640, F, 420)
    street_front(m, L)

    m.view(320, 150, F, 90, 0, "the tunnel and its door")
    m.view(320, 530, F, 80, 4, "the printing room")
    m.view(600, 560, F, 150, 8, "the press")
    m.view(230, 740, F, 345, 4, "the paper and the lines")


# ---------------------------------------------------------------------------
# 9. The still
# ---------------------------------------------------------------------------

def m_still(m, opt):
    """The still: a distillery in a cellar off the left wall. A short tunnel, then four steps down, walled on both
    open sides, into a cellar 64 below the canal's floor: stone to the knee and brick above, sweating, two brick ribs
    carrying its low vault, lit by the fire's glow and one bare bulb. Against its far side the still: a brick firebox
    open at the front with a small steady fire in it, a boiler standing on it with its flue up through the vault
    (blackened round it, scorched in front of the fire), a pipe across to the worm (a drum on a crate, capped, a
    funnel into it) and a glass jug under it (lc_still_pot: in front of the firebox), a bucket of water by the fire.
    Three mash barrels along the left wall, sacks of grain and boxes; kitchen shelves along the back wall with filled
    bottles on top (lc_still_shelf: in front of them); a table with a pot, bottles and a jug; a stool; the tally
    chalked on the wall and a warning painted by the fire.
    Left as brushes: the firebox (brick) and its grate, the flue, the ribs.
    Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look and env_smokestack's (the framework's own
    settings, made small and pale here); which way the boiler and the pipe pieces face; that the bare bulb
    (props_interiors/lightbulb01a, a box 49 high) hangs from its top; Half-Life 2 has no wooden cask, so the barrels
    are its blue plastic ones and an oil drum."""
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
    side = [(386, C), (480, C), (480, C + 32), (386, F + 31)]                      # the flight's open sides walled to the stair line and 32 over it
    m.shapes([prism(side, "x", 312, 320, STONE), prism(side, "x", 448, 456, STONE)])
    m.blocked(320, 384, 448, 496)
    line_walls(m, [(192, 384, 640, 704, H, C)], dado=40, low=STONE, high=RED_BRICK, roof=RED_BRICK)
    for ru in (256, 576):
        arch_rib(m, ru - 8, ru + 8, 384, 704, H, 56, RED_BRICK)
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
    m.static("models/props_pipes/pipe02_connector01.mdl", wu - 3, pv, 0, z=C + 90)            # a cap on the pipe's end (the owner saw it open)
    m.shapes([frustum(wu - 8, pv, 3, C + 85, 8, C + 91, STEEL)])                                # and a funnel from it into the drum
    m.target("lc_still_pot", pu - 60, pv, C + 8, 0)
    m.shapes([vpipe(pu + 3, pv - 3, 4, C + 116, H, IRON)])                                    # the flue, up through the vault
    m.decal("decals/scorch1", pu + 3, pv - 3, H - 2)                                          # the soot round it
    m.decal("decals/smscorch1", pu - 44, pv, C)                                               # and scorch where the fire spits
    m.smoke(wu - 32, pv, C + 18, colour="225 225 225", size=3, length=16, rate=3)             # a breath of steam off the jug
    m.loose("models/props_junk/metalbucket01a.mdl", pu - 52, pv + 44, 0, z=C)                 # water, against the fire
    m.sound("ambient/fire/fire_small_loop1.wav", pu, pv, C + 30, radius=380, volume=3)
    m.blocked(360, 552, 576, 648)

    # the mash: three barrels along the left wall, boxes
    for cv in (452, 512, 572):
        m.static("models/props_borealis/bluebarrel001.mdl", 222, cv, 0, z=C)
    m.static("models/props_junk/cardboard_box002a.mdl", 224, 640, 0, z=C)
    m.static("models/props_junk/cardboard_box001a.mdl", 228, 676, 30, z=C)
    put(m, [("props_junk/garbage_bag001a", 226, 404, 30), ("props_junk/garbage_bag001a", 254, 410, 100)], C)        # grain

    # kitchen shelves along the back wall; a table with a pot, bottles and a jug
    for u in (340, 420, 500):
        m.static("models/props_wasteland/kitchen_shelf001a.mdl", u, 684, 0, z=C)
        put(m, [("props_junk/glassbottle01a", u + du, 684 + dv, 0) for du, dv in ((-20, -4), (-6, 3), (8, -2), (22, 4))], C + 97)      # filled, in a row
    m.target("lc_still_shelf", 460, 650, C + 8, 270)
    tu, tv = 590, 460
    m.static("models/props_c17/furnituretable001a.mdl", tu, tv, 0, z=C)
    put(m, [("props_interiors/pot01a", tu - 12, tv, 0), ("props_junk/glassbottle01a", tu + 8, tv - 10, 0), ("props_junk/glassbottle01a", tu + 16, tv + 4, 0),
            ("props_junk/glassbottle01a", tu + 4, tv + 12, 0), ("props_junk/glassjug01", tu - 6, tv - 14, 0)], C + 37)
    m.static("models/props_junk/wood_crate001a.mdl", 606, 664, 10, z=C)
    m.static("models/props_c17/chair_stool01a.mdl", 548, 438, 0, z=C)
    m.static("models/props_interiors/lightbulb01a.mdl", 400, 520, 0, z=H - 50)              # the bare bulb
    m.light(400, 520, H - 60, "255 205 140 80")
    m.grime("graffiti", 638, 620, C + 84, 1)                                                  # the tally
    m.decal("decals/decalsignpainted001c", 638, 540, C + 92)                                  # a warning in their own hand
    m.grime("stain", 194, 560, C + 100, 2)
    m.grime("stain", 300, 702, C + 110, 3)
    m.grime("stain", 638, 430, C + 70, 4)
    m.lane(400, 520, C)
    m.lane(330, 620, C)
    sounds(m, L, "cave", 416, 560, C, 400)
    street_front(m, L)

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
    rectangle (cu - w .. cu + w, v1 .. vb): four convex outlines for vprism, every corner a whole number, split along
    u = cu +- a so that no two of them overlap even in their bounding boxes (the flush check reads those)."""
    a = int(round(r * 0.7071))
    out = []
    for s in (-1, 1):
        out.append([(cu + s * w, vb), (cu + s * r, vb), (cu + s * a, vb - a), (cu + s * a, v1), (cu + s * w, v1)])
        out.append([(cu + s * a, v1), (cu + s * a, vb - a), (cu, vb - r), (cu, v1)])
    return out


def m_plaza(m, opt):
    """The plaza: where people gather to listen. The canal (or the street) opens on its left, 1152 wide, onto a
    terrace at its own height, and from the terrace five concrete rows of seats step DOWN and away, each 16 high and
    48 deep (walked down anywhere, sat on anywhere), round half an eight-sided floor 512 across and 80 below the
    street. At the back wall, facing the rows and the street beyond them, a timber stage 256 wide and 48 up, two steps
    up at its front, a lectern at its edge (lc_plaza_rostrum: where the speaker stands, facing the street); behind the
    speaker a cloth banner with the lambda hangs on the wall, a tin canopy on two posts over the stage, and above the
    canopy the cluster of loudspeakers on the wall (speakercluster01a, the owner's choice: on the wall, turned to the
    street); a caged lamp on the wall each side. Two spotlights on the side walls throw their beams on the speaker; the
    rows stay in half light. A fire drum burns on each side of the floor; crates people sit on along the terrace, cans
    left on the rows. lc_plaza_crowd is the middle of the third row, facing the stage.
    (Turned round on 21 November at the owner's word: the top row used to be at the back.)
    Left as brushes: the rows, the stage, its steps and canopy (timber staging), its lectern (no model of one), the
    banner (cloth: no model).
    Unchecked: env_fire's look in the drums; which way the loudspeakers face (turned to the street); the spotlights'
    aim (yaw 15 and pitch 13 from the side walls toward the lectern)."""
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

    def ground(u, v):        # (the height of the rows at a place: how many of the octagons' edges it is beyond)
        x, y = abs(u - cu), abs(v - vb)
        d = max(0.924 * x + 0.383 * y, 0.383 * x + 0.924 * y) / 0.924
        return low + 16 * sum(1 for k in range(5) if 256 + 48 * k <= d)

    # the stage at the back wall: a timber platform, two steps up at its front, a lectern at its edge
    s1, s2, sv, top = cu - 128, cu + 128, vb - 96, low + 48
    m.det([(s1, sv, low, s2, vb, top)], TIMBER, top=DECK)
    m.det([(cu - 96, sv - 48 + 24 * k, low, cu + 96, sv - 24 + 24 * k, low + 16 * (k + 1)) for k in range(2)], TIMBER, top=DECK)
    m.det([(cu - 14, sv + 4, top, cu + 14, sv + 14, top + 38)], TIMBER)
    m.shapes([prism([(sv + 2, top + 38), (sv + 16, top + 38), (sv + 16, top + 40), (sv + 2, top + 46)], "x", cu - 16, cu + 16, DECK)])
    m.target("lc_plaza_rostrum", cu, sv + 30, top + 8, 270)
    m.target("lc_hq_setup_plaza", cu + 96, sv + 30, top + 8, 270)      # the town's flagpole beside the rostrum (the owner, 21 November: "the plaza can hold the flagpole")
    # behind the speaker: the banner on the wall, the canopy on its posts, the loudspeakers over it, a lamp each side
    m.det([(cu - 112, vb - 1, low + 60, cu + 112, vb, low + 196)], CLOTH)
    m.det([(cu - 118, vb - 4, low + 196, cu + 118, vb - 2, low + 198)], BARS)
    m.grime("lambda", cu, vb - 1, low + 128, 1)
    m.shapes([prism([(vb, low + 206), (vb, low + 210), (vb - 112, low + 190), (vb - 112, low + 186)], "x", s1 - 8, s2 + 8, "metal/metalroof008a")])
    m.det([(u, vb - 110, top, u + 6, vb - 104, low + 190) for u in (s1 + 2, s2 - 8)], TIMBER)
    m.static("models/props_wasteland/speakercluster01a.mdl", cu, vb - 17, 270, z=low + 222)
    for u in (cu - 168, cu + 168):
        cage(m, u, vb, low + 150, 270, "255 220 170 200")
    # the spotlights on the side walls, their beams on the lectern
    for u, yaw in ((cu - w, 15), (cu + w, 165)):
        m.static("models/props_c17/light_cagelight02_on.mdl", u, vb - 200, 0 if yaw < 90 else 180, z=F + 150)
        m.spot(u + (12 if yaw < 90 else -12), vb - 200, F + 150, "255 240 215 600", yaw, pitch=13, cone=24)

    # a fire drum on each side of the floor
    for u in (cu - 190, cu + 190):
        m.static("models/props_c17/oildrum001.mdl", u, vb - 40, 0, z=low)
        fire(m, u, vb - 40, low + 46, size=18, light="255 150 70 140", drop=False)
    # what people bring and leave: crates to sit on along the terrace, cans on the rows
    for u, v, yaw in ((cu - 470, vb - 330, 20), (cu + 430, vb - 420, 70), (cu + 60, vb - 470, 5)):
        m.static("models/props_junk/wood_crate001a.mdl", u, v, yaw, z=ground(u, v))
    for name, u, v in (("popcan01a", cu - 200, vb - 300), ("garbage_metalcan001a", cu + 330, vb - 270), ("popcan01a", cu - 60, vb - 410)):
        m.static("models/props_junk/%s.mdl" % name, u, v, 0, z=ground(u, v))
    for u, v in ((cu, vb - 180), (cu - 120, vb - 150), (cu + 120, vb - 150), (cu, vb - 230)):
        m.lane(u, v, low)
    for u in (cu - 420, cu - 140, cu + 140, cu + 420):
        m.lane(u, v1 + 28)
    sounds(m, L, "courtyard", cu, vb - 200, low, 640)
    street_front(m, L)

    m.view(cu, 60, F, 90, 6, "from across the canal: looking down the rows")
    m.view(cu, sv + 40, top, 270, -4, "from the stage")
    m.view(cu, v1 + 30, F, 90, 12, "from the terrace")
    m.view(cu - 300, vb - 60, low, 20, 0, "the stage from the floor")


# ---------------------------------------------------------------------------
# 11. The playground
# ---------------------------------------------------------------------------

PLAY = "models/props_c17/"
VGRASS = "nature/red_grass"                  # Valve's playground: grass, a concrete path between stone kerbs, stone walls
VPATH, VKERB, VPAVED, VSTEP = "concrete/concretefloor028c", "stone/stonefloor006b", "concrete/concretefloor019a", "concrete/concretestair005a"
VALVE_PG = (-4288, -4160)     # (the place in Valve's map that is the yard's front corner, u 128 v 256)


def vpg(x, y):
    """A place (x, y) in Valve's sdk_d1_trainstation_02.vmf as a place in the playground: Valve's x runs back from the
    street (v), its y along it (u): the prefab valve_playground_a turned three quarter turns. A yaw of Valve's is 90 less."""
    return int(round(128 + y - VALVE_PG[1])), int(round(256 + VALVE_PG[0] - x))


def m_playground(m, opt):
    """The playground: Half-Life 2's own, copied from the courtyard by the train station (sdk_d1_trainstation_02.vmf,
    the prefab valve_playground_a), each thing where Valve put it and turned as Valve turned it (vpg). A yard on the
    left, open to the sky: in a canal a terrace 128 above its floor (the bank is the way up), on a street level with the
    pavement. Valve's grass, and Valve's path through the middle of it, concrete between stone kerbs, coming in from the
    pavement between the posts of Valve's low stone wall with its metal fence on top. On the right of the path: the
    noughts and crosses post, its eight blocks turning on their rods; a bench turned toward the swings
    (lc_playground_bench: on the bench); two climbing frames; the swing set, whose two seats swing on their chains
    (lc_playground_swing_1 and _2, each on a phys_hinge under the bar), worn to mud under them; a tree over it; the doll
    lying in the grass; the see-saw, its seat rocking on a hinge (lc_playground_teeter); in the far corner Valve's
    terrace, paved 64 up behind a raised grass bed and its stone wall, with steps up. On the left: a bin overflowing,
    our sandpit edged with timber, a dumpster, the roundabout that turns (lc_playground_roundabout on a phys_hinge) and
    the slide. Leaves on the grass, chalk on the path, rust down the walls, a Combine notice. No lamp.
    Left as brushes: the sandpit, the worn patches; the path, the terrace, its steps, the low wall and its fence (Valve's
    own brushes too).
    Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (one faint wind); how freely the hinges turn
    (the see-saw's and the blocks' are Valve's settings, the swings' and the roundabout's ours)."""
    L, T = 1024, (F if m.fr.dz else F + 128)    # (on a street level with the pavement: the owner, 20 November)
    m.open(0, -256, L, 256)
    m.open(192, 256, 960, 640, floor=T, mat=VGRASS)      # (Valve's courtyard: a building's plinth along the left as far as the slide's lawn)
    m.open(128, 640, 960, 1088, floor=T, mat=VGRASS)
    m.side(192, 256, 960, 640)
    m.side(128, 640, 960, 1088)
    # the path, and the low wall across the front with its fence, a post each side of the way in
    m.det([(400, 256, T, 528, 1088, T + 1)], VPATH)
    m.det([(352, 256, T, 400, 1088, T + 1), (528, 256, T, 576, 1088, T + 1)], VKERB)
    m.det([(192, 258, T, 390, 266, T + 32), (538, 258, T, 960, 266, T + 32), (390, 256, T, 402, 268, T + 68), (526, 256, T, 538, 268, T + 68)], STONE)
    m.det([(192, 262, T + 32, 390, 263, T + 64), (538, 262, T + 32, 960, 263, T + 64)], "metal/metalfence001a", top=MAT["nodraw"])
    # Valve's terrace in the far corner: paved, 64 up, a raised grass bed and a capped stone wall along its edge, steps up
    m.det([(800, 960, T, 960, 1088, T + 64), (704, 1056, T, 800, 1088, T + 64)], STONE, top=VPAVED)
    m.det([(864, 912, T, 960, 960, T + 64)], STONE, top=VGRASS)
    m.det([(800, 896, T, 864, 960, T + 112), (864, 896, T, 960, 912, T + 112), (704, 1056, T + 64, 720, 1088, T + 112), (720, 1056, T + 64, 800, 1072, T + 112)], STONE)
    m.det([(704 + 24 * i, 960, T, 728 + 24 * i, 1056, T + 16 * (i + 1)) for i in range(4)], STONE, top=VSTEP)      # (Valve's are 8 by 12: the owner's are 16 by 24)
    m.blocked(704, 896, 960, 1088)
    m.lane(740, 1008, T + 32)
    m.lane(900, 1020, T + 64)

    # Valve's things where Valve put them (its x, its y, its yaw)
    for model, x, y, yaw in ((PLAY + "playground_swingset01.mdl", -4656, -3541, 0),
                             (PLAY + "playgroundslide01.mdl", -4960, -4056, 23.5),       # (8 off our wall: Valve's had a gap there)
                             (PLAY + "playground_jungle_gym01a.mdl", -4840, -3672, 270.5),
                             (PLAY + "playground_jungle_gym01b.mdl", -4518, -3434, 300),
                             (PLAY + "playground_teetertoter_stan.mdl", -4851, -3491, 0),
                             (PLAY + "playgroundTick-tack-toe_post01.mdl", -4476, -3599, 0),
                             ("models/props_foliage/tree_deciduous_01a-lod.mdl", -4544, -3682, 185.5),
                             ("models/props_trainstation/bench_indoor001a.mdl", -4341, -3549, 225),      # (Valve's stood by a building's corner, beyond our wall)
                             ("models/props_junk/TrashDumpster01a.mdl", -4648, -4048, 166.5)):
        u, v = vpg(x, y)
        m.static(model, u, v, int(round(yaw - 90)) % 360, z=T)
    bu, bv = vpg(-4341, -3549)
    m.target("lc_playground_bench", bu - 4, bv + 4, T + 20, 135)
    # the swings: each seat on a hinge under the bar and two chains (as Half-Life 2's swing), the ground worn under them
    for k, (x, y) in enumerate(((-4674.75, -3539.75), (-4634, -3540))):
        u, v = vpg(x, y)
        swing(m, "lc_playground_swing_%d" % (k + 1), u, v, T + 24, T + 140, along="v")
    m.det([(712, 628, T, 784, 658, T + 1), (712, 588, T, 784, 616, T + 1)], "nature/mudfloor004a")
    m.blocked(700, 520, 800, 720)
    # the roundabout, turning on its hinge
    ru, rv = vpg(-4798.45, -4010.07)
    m.prop("prop_physics", PLAY + "playground_carousel01.mdl", ru, rv, 270, T + 1, {"targetname": "lc_playground_roundabout", "spawnflags": "0"})
    m.point("phys_hinge", ru, rv, T + 24, {"targetname": "lc_playground_roundabout_hinge", "attach1": "lc_playground_roundabout", "attach2": "",
                                            "hingeaxis": "%d %d %d" % m.fr.at(ru, rv, T + 88), "hingefriction": "4", "forcelimit": "0", "torquelimit": "0",
                                            "spawnflags": "0", "systemoverridefile": ""})
    m.blocked(200, 690, 356, 1016)
    # the see-saw's seat, rocking on a hinge across it (Valve's)
    su, sv = vpg(-4851.36, -3491.65)
    m.prop("prop_physics", PLAY + "playground_teetertoter_seat.mdl", su, sv, 270, T + 16, {"targetname": "lc_playground_teeter", "spawnflags": "2"})
    (hu, hv), (au, av) = vpg(-4837.61, -3491.4), vpg(-4863.61, -3491.4)
    m.point("phys_hinge", hu, hv, T + 20, {"targetname": "lc_playground_teeter_hinge", "attach1": "lc_playground_teeter", "attach2": "",
                                            "hingeaxis": "%d %d %d" % m.fr.at(au, av, T + 20), "hingefriction": "0", "forcelimit": "0", "torquelimit": "0",
                                            "spawnflags": "8", "systemoverridefile": ""})
    m.blocked(720, 800, 880, 840)
    # the noughts and crosses: eight blocks, each turning on its row's rod (Valve's: one place is empty)
    n = 0
    for y in (-3613, -3599, -3585):
        for z in (28, 46, 62):
            if (y, z) == (-3613, 46):
                continue
            n += 1
            name, (u, v) = "lc_playground_block_%d" % n, vpg(-4476, y)
            model, pos, wy = PLAY + "playgroundTick-tack-toe_block01a.mdl", m.fr.at(u, v, T + z), m.fr.yaw(270)
            m.b.vmf.point("prop_physics", pos, {"model": model, "angles": "0 %d 0" % wy, "skin": "0", "targetname": name, "spawnflags": "768",
                                                "physdamagescale": "0.1", "fademindist": "-1", "fadescale": "1"}, m.pv)
            m.b.props.append(("prop_physics", model, pos, wy, m.tag))
            m.b.vmf.point("phys_hinge", pos, {"attach1": name, "attach2": "", "hingeaxis": "%d %d %d" % m.fr.at(u + 2, v, T + z), "hingefriction": "0.05",
                                              "forcelimit": "0", "torquelimit": "0", "spawnflags": "1", "systemoverridefile": ""}, m.dv)
    m.blocked(650, 430, 728, 460)
    # the doll, lying in the grass where Valve left it
    du, dv = vpg(-4595, -3570)
    m.point("prop_physics", du, dv, T + 3, {"model": "models/props_c17/doll01.mdl", "angles": "-90 %d 0" % m.fr.yaw(50), "skin": "0", "spawnflags": "256",
                                           "physdamagescale": "0.1", "fademindist": "-1", "fadescale": "1"}, m.pv)
    m.blocked(580, 488, 632, 536)      # (the tree's trunk)
    m.blocked(800, 456, 904, 516)
    m.blocked(596, 752, 636, 864)
    m.blocked(690, 262, 790, 356)

    # on the left of the path, ours: the sandpit, the bin overflowing by the front wall
    g1, g2, h1, h2 = 208, 336, 376, 536
    m.det([(g1, h1, T, g2, h1 + 6, T + 10), (g1, h2 - 6, T, g2, h2, T + 10), (g1, h1 + 6, T, g1 + 6, h2 - 6, T + 10), (g2 - 6, h1 + 6, T, g2, h2 - 6, T + 10)], TIMBER)
    m.det([(g1 + 6, h1 + 6, T, g2 - 6, h2 - 6, T + 5)], SAND)
    m.shapes([prism([(420, T + 5), (456, T + 5), (440, T + 12)], "x", 250, 294, SAND)])
    m.blocked(g1, h1, g2, h2)
    m.static("models/props_trainstation/trashcan_indoor001b.mdl", 222, 296, 0, z=T)
    put(m, [("props_junk/garbage_bag001a", 258, 300, 30), ("props_junk/garbage_bag001a", 226, 336, 110)], T)
    m.blocked(192, 266, 286, 356)
    m.blocked(192, 576, 288, 656)

    # Valve's leaves on the grass; chalk on the path, rust down the walls, a Combine notice
    for x, y in ((-4590, -3659), (-4452, -3701), (-4864, -3683), (-4818, -3988), (-4746, -4112), (-4924, -4110), (-5051, -4005)):
        m.decal("decals/leaves_ground02", *(vpg(x, y) + (T,)))
    m.grime("trash", 262, 330, T, 1)
    m.grime("graffiti", 464, 420, T + 1, 2)
    m.grime("stain", 128, 900, T + 120, 3)
    m.grime("stain", 650, 1088, T + 110, 4)
    m.grime("poster", 960, 700, T + 80, 5)
    m.sound("ambient/levels/canals/windmill_wind_loop1.wav", 560, 680, T + 120, radius=700, volume=2)
    sounds(m, L, "courtyard", 560, 680, T, 560)
    street_front(m, L)
    for u, v in ((464, 320), (464, 700), (464, 1000)):
        m.lane(u, v, T + 1)
    for u, v in ((660, 740), (310, 600)):
        m.lane(u, v, T)

    m.view(464, -120, F, 90, 8, "from the street, up the path")
    m.view(884, 318, T, 145, 6, "beside the bench")
    m.view(880, 1010, T + 64, 225, 10, "from the terrace")
    m.view(464, 1000, T + 1, 215, 6, "the roundabout and the slide, from the path")


MODULES = {
    "cells": (1024, m_cells, "the cells: a guard room, three barred cells, a crawl duct out (left)"),
    "memorial": (768, m_memorial, "the wall of the dead: plaques and candles in a recess under the open sky (left)"),
    "pit": (1280, m_pit, "the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left)"),
    "garden": (1280, m_garden, "the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left)"),
    "stash": (768, m_stash, "the stash: a brick arms room with guns on racks, behind a section of wall that a pipe valve opens (left)"),
    "market": (1280, m_market, "the black market: a vaulted arcade of five shuttered stalls (left)"),
    "press": (768, m_press, "the pamphlet press: a printing room behind a door in a side tunnel (left)"),
    "still": (768, m_still, "the still: a pot still, mash casks and bottles in a cellar (left)"),
    "plaza": (1536, m_plaza, "the plaza: five rows of seats stepping down from the street to a stage at the back wall (left)"),
    "playground": (1024, m_playground, "the playground: Half-Life 2's own from the train station's courtyard, a path through it (left)"),
    "clinic": (1024, m_clinic, "the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left)"),
}
