#!/usr/bin/env python3
"""
Living City: a Ravenholm quarter behind the Combine wall at the city's south end, and a tunnel from
it to the sewers (run it through map_build.py)

    python3 map_build.py ravenholm            lc_ravenholm.vmf
    python3 map_build.py ravenholm --test     lc_ravenholm_test.vmf, to compile and walk by itself

The owner, 19 November: "I want to attach a ravenholm-esque section of the city to the south end
that I put a sealed off wall near ... that could be opened by resistance to flood the city with
zombies/headcrabs, and also to attach an underground tunnel between this new ravenholm section and
the existing tunnels/sewers in the map so that the combine can open that tunnel (it would be sealed
by default) and flood the resistance underground". Where: "right behind the wall"; the tunnel comes
out of the sewer wall they marked (320 x 8 x 209 at 1376 397 344: brush 28290).

What is there (read from c18_lc.vmf): the wall is brush 65929 (x 93..107, y -2526..-2188) with two
rails (51870, 62363), across an east-west street whose roadway is y -2549..-2293 at z 656. Behind it
the street is finished for about 1,000 units (houses to x 1024 on the south side, 1152 on the
north); then only the roadway runs on to x 1472, and a bare strip of road (34874) hangs south from
there in empty space. That empty space is where this piece stands.

The piece, all in the map's own coordinates:
- THE GATE: the owner's wall and rails again, as one mover (lc_raven_gate) that sinks into the
  street, with the unseen wall the owner has round it (gone while the gate is open). The owner deletes
  65929, 51870, 62363, 15623 and 33530.
- THE APPROACH: walls and pavement along the unfinished last stretch of the owner's street
  (x 1024..1472), so it has sides.
- THE QUARTER (a Plan whose corner is at 1472 -2613, so its rows lie on the street's own lines):
  the street carried on east to a square; an alley north to a yard; a street south to a lower yard;
  an alley west to a back court; two houses to go into. Brick as the owner's own houses there.
- THE TUNNEL HOUSE, on the north side of the approach: a door, 44 steps down north, and a tunnel
  (z 304..448) straight north under the city to the sewer wall, 1,966 long. A vent duct of the
  owner's crosses 4 units behind that wall from x 1256 east, so the tunnel's last 128 are a passage
  36 wide along the west side, and the hatch (lc_raven_hatch) is in the wall's west end. The piece
  carries the whole wall again with that hatch in it: the owner deletes 28290.
- The owner also deletes 34874 (the bare strip): the approach's south side stands where it starts.

Nothing in the gamemode knows of this yet. Who may open the gate and the hatch is the gamemode's to
say: the map only has lc_raven_gate_open / _shut and lc_raven_hatch_open / _shut (logic_relays: fire
Trigger), and fires lc_raven_gate_opened, lc_raven_hatch_opened and their _closed for it to hear.
While the gate is open zombies and headcrabs are made in the quarter and walk out through it; while
the hatch is open, in the tunnel house, and walk to the sewer (the makers are in their own visgroup:
delete it if the gamemode is to send them itself).
"""

import random

from map_build import CELL, MAT, Plan, Vmf, check, test_extras
from map_forest import crusher

RMAT = {   # (all but the last three are the owner's own, from the street behind the wall and the sewer)
    "road": "stone/stonefloor006d_c17", "walk": "concrete/concretefloor039b", "brick_low": "brick/brickwall053e", "brick_high": "brick/brickwall040b",
    "gate": "metal/citadel_metalwall077a", "gate_rail": "metal/citadel_metalwall101b", "sewer_wall": "concrete/concretewall056c",
    "tunnel_wall": "brick/brickwall027a", "tunnel_floor": "concrete/concretefloor010b", "room_wall": "plaster/plasterwall047b",
    "room_floor": "wood/woodfloor007a", "board": "wood/woodbeam001a", "steel": "metal/metalhull003a",
}
DELETE = ("65929", "51870", "62363", "15623", "33530", "28290", "34874")   # the owner's brushes this piece stands in the place of: they delete these
# (65929, 51870, 62363: the Combine wall and its two rails. 15623: the unseen wall round it, which would still stop
#  everyone when the gate is down; the gate carries its own, that goes when it opens. 33530: a thin black sheet standing in
#  the wall, to z 1128. 28290: the sewer wall. 34874: the bare strip of road hanging south of the street's end.)
STANDS_IN = ("20571", "20578", "34853")   # the pavement and roadway the owner's wall itself stands in, as the gate does: they stay


def ravenholm(args):
    vmf = Vmf()
    X0, Y0 = 1472, -2613                 # the plan's corner: where the owner's roadway ends, its rows on that street's own lines
    Z, SKY = 656, 1600                   # the street; this piece's own sky (under a window brush of the owner's that hangs at z 1666)
    base = Z - 64
    BIG = 10 ** 6
    sky = MAT["sky"]
    wv, dv, pv, tv = "LC ravenholm: walls and floors", "LC ravenholm: details", "LC ravenholm: props", "LC ravenholm: tunnel"
    gv, mv = "LC ravenholm: gate, hatch and their wiring", "LC ravenholm: zombie makers (delete if the gamemode is to send them itself)"
    test = bool(args.test)

    # --- the quarter ---------------------------------------------------------------------------------------------
    plan = Plan((X0, Y0), [(base, 896, RMAT["brick_low"]), (896, 1408, RMAT["brick_high"]), (1408, SKY + 16, sky)], sky=SKY, vis=wv)
    plan.keep_out.append((-BIG, -BIG, 0, BIG))               # west of it is the owner's street
    road, walk = ("open", Z, RMAT["road"]), ("open", Z, RMAT["walk"])
    room, doorway = ("low", Z, RMAT["room_floor"], Z + 144), ("low", Z, RMAT["room_floor"], Z + 112)
    plan.paint((0, 0, 704, 384), walk)
    plan.paint((0, 64, 704, 320), road)                      # the street, carried on east (roadway and a pavement each side)
    plan.paint((704, -128, 1152, 448), road)                 # the square
    plan.paint((832, 448, 960, 768), walk)                   # an alley north...
    plan.paint((704, 768, 1088, 960), walk)                  # ...to a yard
    plan.paint((832, -832, 1024, -128), road)                # a street south...
    plan.paint((512, -1088, 1216, -832), road)               # ...to the lower yard
    plan.paint((256, -576, 832, -448), walk)                 # an alley west off it...
    plan.paint((64, -704, 256, -384), walk)                  # ...to a back court
    plan.paint((128, -320, 512, -64), room)                  # a house between the street and the back court
    plan.paint((256, -64, 320, 0), doorway)
    plan.paint((192, -384, 256, -320), doorway)
    plan.paint((128, 448, 576, 704), room)                   # a house north of the street
    plan.paint((320, 384, 384, 448), doorway)
    plan.build(vmf)
    B, W, cells = plan.box, plan.world, plan.cells

    # --- the approach: sides for the owner's street where it has none (x 1024..1472) -------------------------------
    def wall3(x1, y1, x2, y2):
        for a, b, m in plan.band_list:
            vmf.world_box((x1, y1, a, x2, y2, b), m, vis=wv)
    wall3(1024, Y0 - 64, X0, Y0)                                                                   # the south side, from the last house
    vmf.world_box((1216, Y0, base, X0, Y0 + 64, Z), RMAT["brick_low"], top=RMAT["walk"], vis=wv)   # the south pavement, from where the owner's stops
    vmf.world_box((1152, Y0 + 320, base, X0, Y0 + 384, Z), RMAT["brick_low"], top=RMAT["walk"], vis=wv)   # the north pavement
    wall3(1152, Y0 + 384, 1200, Y0 + 448)                                                          # the north side: a wall either side of the tunnel house
    wall3(1424, Y0 + 384, X0, Y0 + 448)

    # --- the tunnel house and the tunnel ---------------------------------------------------------------------------
    TX1, TX2 = 1216, 1408                      # the tunnel, inside
    FLOOR, CEIL = 304, 448
    ys, ya = Y0 + 384, Y0 + 512                # the house's front (y -2229); the head of the stairs (y -2101)
    STEPS = 44
    yb = ya + 12 * STEPS                       # the stairs' foot (y -1573)
    slot_y, wall_y = 265, 393                  # where the narrow last passage begins; the sewer wall's south face
    tw, tf = RMAT["tunnel_wall"], RMAT["tunnel_floor"]

    def WB(box, m, **k):
        vmf.world_box(box, m, vis=tv, **k)
    # the front wall with its doorway (48 wide, 108 high), carried down to the tunnel's floor
    WB((TX1 - 16, ys, 240, 1288, ys + 16, 816), tw)
    WB((1336, ys, 240, TX2 + 16, ys + 16, 816), tw)
    WB((1288, ys, 240, 1336, ys + 16, Z), tw, top=tf)
    WB((1288, ys, Z + 108, 1336, ys + 16, 816), tw)
    # the side walls: the stair hall's (to its highest roof), then the tunnel's
    WB((TX1 - 16, ys + 16, 240, TX1, yb, 816), tw)
    WB((TX2, ys + 16, 240, TX2 + 16, yb, 816), tw)
    WB((TX1 - 16, yb, 240, TX1, wall_y + 8, CEIL + 16), tw)
    WB((TX2, yb, 240, TX2 + 16, slot_y, CEIL + 16), tw)
    # floors: the landing inside the door, and one slab under the stairs and the tunnel
    WB((TX1, ys + 16, base, TX2, ya, Z), tw, top=tf)
    WB((TX1, ys + 16, 240, TX2, slot_y, FLOOR), tw, top=tf)
    vmf.detail([(TX1, ya + 12 * i, FLOOR, TX2, ya + 12 * (i + 1), Z - 8 * (i + 1)) for i in range(STEPS - 1)], tw, vis=tv, top=MAT["stairs"])
    # roofs over the stairs: four lengths, each 88 lower than the last, with a wall down from each to the next
    tops = [Z + 144 - 88 * k for k in range(4)]
    for k in range(4):
        y1, y2 = (ys + 16 if k == 0 else ya + 132 * k + 16), ya + 132 * (k + 1)
        WB((TX1, y1, tops[k], TX2, y2, tops[k] + 16), tw, bottom=MAT["ceiling"])
        WB((TX1, y2, tops[k + 1] if k < 3 else CEIL, TX2, y2 + 16, tops[k] + 16), tw)
    WB((TX1, yb + 16, CEIL, TX2, slot_y, CEIL + 16), tw, bottom=MAT["ceiling"])
    # the last 128: the owner's vent duct crosses from x 1256 east just behind the sewer wall, so a passage 36 wide along
    # the west side, shut off from the duct's side
    WB((1252, slot_y, 240, TX2 + 16, slot_y + 16, CEIL + 16), tw)
    WB((1252, slot_y + 16, 240, 1256, wall_y, CEIL + 16), tw)
    WB((TX1, slot_y, 240, 1252, wall_y, FLOOR), tw, top=tf)
    WB((TX1, slot_y, CEIL, 1252, wall_y + 8, CEIL + 16), tw, bottom=MAT["ceiling"])
    # the sewer wall again (the owner's brush 28290), with the hatch's opening in its west end
    WB((1252, wall_y, 239, 1536, wall_y + 8, CEIL), RMAT["sewer_wall"])
    WB((TX1, wall_y, 239, 1252, wall_y + 8, 307), RMAT["sewer_wall"], top=tf)
    hatch = [((TX1, wall_y + 2, 307, 1252, wall_y + 6, CEIL), RMAT["steel"])]
    vmf.brush_entity("func_button", {"targetname": "lc_raven_hatch", "movedir": "-90 0 0", "speed": "30", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0",
                                     "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"}, hatch, RMAT["steel"], gv)
    crusher(vmf, "lc_raven_hatch", (TX1, wall_y + 1, 293, 1252, wall_y + 7, 309), gv, "lc_raven_hatch_crush")
    # the house's door (the city's own), and light: one inside the door, a dim one every 320 of tunnel, some of it dark
    pos = (1288, ys + 8, Z + 54)
    vmf.point("prop_door_rotating", pos, {
        "model": "models/props_c17/door01_left.mdl", "angles": "0 270 0", "ajarangles": "0 0 0", "axis": "%d %d %d, %d %d %d" % (pos + pos), "distance": "90", "dmg": "0",
        "fademindist": "-1", "fadescale": "1", "forceclosed": "0", "hardware": "1", "health": "0", "opendir": "0", "rendercolor": "255 255 255", "returndelay": "-1",
        "skin": "7", "spawnflags": "8192", "spawnpos": "0", "speed": "100"}, tv)
    for (x, y, z, colour) in [(1312, ys + 70, Z + 120, "255 200 150 90")] + [(1312, y, CEIL - 16, "255 190 130 60") for y in range(yb + 120, slot_y - 100, 320) if (y // 320) % 3]:
        vmf.point("light", (x, y, z), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, "LC ravenholm: lights")

    # --- the gate: the owner's wall and its two rails, as one mover that sinks into the street (never in the test file:
    # it stands in the owner's street, a thousand units outside this piece) ------------------------------------------------
    if not test:
        vmf.brush_entity("func_button", {"targetname": "lc_raven_gate", "movedir": "90 0 0", "speed": "36", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0",
                                         "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                         [((93, -2526, 648, 107, -2188, 944), RMAT["gate"]), ((77, -2526, 708, 93, -2357, 740), RMAT["gate_rail"]),
                          ((77, -2357, 840, 93, -2188, 856), RMAT["gate_rail"])], RMAT["gate"], gv)
        # the unseen wall the owner has round it (so nobody gets over): there while the gate is shut, gone while it is open
        vmf.brush_entity("func_brush", {"targetname": "lc_raven_gate_clip", "Solidity": "0", "StartDisabled": "0", "solidbsp": "0", "spawnflags": "2", "rendermode": "0",
                                        "renderamt": "255", "rendercolor": "255 255 255", "vrad_brush_cast_shadows": "0", "disableshadows": "1", "invert_exclusion": "0"},
                         [(65, -2639, 648, 197, -2075, 1280)], "tools/toolsinvisible", gv)
        vmf.boxes.pop()      # (not held to the fit check: it is the owner's own unseen wall again, which stands in their pillars and houses as theirs does)
        # where what is made here walks to: the city's side of the gate; the sewer beyond the hatch
        vmf.point("info_target", (-300, -2421, Z + 16), {"targetname": "lc_raven_rally"}, mv, outside=True)
        vmf.point("info_target", (1376, 760, 323), {"targetname": "lc_raven_hatch_rally"}, mv, outside=True)

    # --- the wiring. The relays and sounds stand inside the quarter (a sound can be told what to play from). ---------------
    def sound(name, message, source, pos, loops=False):
        vmf.point("ambient_generic", pos, {"targetname": name, "message": message, "SourceEntityName": source, "health": "10", "pitch": "100", "pitchstart": "100",
                                           "radius": "3000", "spawnflags": "16" if loops else "48", "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0",
                                           "lfomodvol": "0", "lforate": "0", "lfotype": "0", "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, gv)

    def relays(name, door, took, at, makers, crush=None, clip=None):
        """name_open and name_shut (one live at a time), name_opened and name_closed for the gamemode to hear."""
        sound(name + "_move", "Streetwar.d3_c17_11_garage_move1", door, at, loops=True)
        sound(name + "_stop", "Streetwar.d3_c17_11_garage_stop1", door, (at[0], at[1] + 16, at[2]))
        opening = [("OnTrigger", name + "_open", "Disable", "", 0), ("OnTrigger", door, "PressIn", "", 0.5), ("OnTrigger", name + "_move", "PlaySound", "", 0.5),
                   ("OnTrigger", name + "_opened", "Trigger", "", 0.5), ("OnTrigger", name + "_move", "StopSound", "", 0.5 + took),
                   ("OnTrigger", name + "_stop", "PlaySound", "", 0.5 + took), ("OnTrigger", makers, "Enable", "", 0.5 + took), ("OnTrigger", name + "_shut", "Enable", "", took + 2)]
        shutting = [("OnTrigger", name + "_shut", "Disable", "", 0), ("OnTrigger", makers, "Disable", "", 0), ("OnTrigger", door, "PressOut", "", 0.5),
                    ("OnTrigger", name + "_move", "PlaySound", "", 0.5), ("OnTrigger", name + "_move", "StopSound", "", 0.5 + took),
                    ("OnTrigger", name + "_stop", "PlaySound", "", 0.5 + took), ("OnTrigger", name + "_closed", "Trigger", "", 0.5 + took),
                    ("OnTrigger", name + "_open", "Enable", "", took + 2)]
        if crush:
            shutting += [("OnTrigger", crush, "Enable", "", 0.5), ("OnTrigger", crush, "Disable", "", 0.9 + took)]
        if clip:
            opening.append(("OnTrigger", clip, "Disable", "", 0.5))
            shutting.append(("OnTrigger", clip, "Enable", "", 0.5 + took))
        vmf.point("logic_relay", (at[0], at[1], at[2] + 16), {"targetname": name + "_open", "StartDisabled": "0", "spawnflags": "0"}, gv, connections=opening)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 32), {"targetname": name + "_shut", "StartDisabled": "1", "spawnflags": "0"}, gv, connections=shutting)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 48), {"targetname": name + "_opened", "StartDisabled": "0", "spawnflags": "0"}, gv)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 64), {"targetname": name + "_closed", "StartDisabled": "0", "spawnflags": "0"}, gv)
    relays("lc_raven_gate", "lc_raven_gate", 8.0, W(40, 190, Z + 96), "lc_raven_maker", clip="lc_raven_gate_clip")
    relays("lc_raven_hatch", "lc_raven_hatch", 4.5, (1312, ys + 60, Z + 60), "lc_raven_hatch_maker", crush="lc_raven_hatch_crush")

    # --- what is made while a way is open: zombies and headcrabs, sent walking to that way's far side ----------------------
    def makers(name, child, march, goal, spots):
        for (pos, cls) in spots:
            vmf.point("npc_maker", pos, {"targetname": name, "NPCType": cls, "NPCTargetname": child, "StartDisabled": "1", "spawnflags": "32", "MaxNPCCount": "1",
                                         "SpawnFrequency": "14", "MaxLiveChildren": "2", "angles": "0 180 0"}, mv,
                      connections=[("OnSpawnNPC", march, "StartSchedule", "", 1)])
        vmf.point("aiscripted_schedule", (spots[0][0][0], spots[0][0][1], spots[0][0][2] + 64), {
            "targetname": march, "m_iszEntity": child, "m_flRadius": "0", "graball": "1", "forcestate": "0", "schedule": "1", "interruptability": "0", "goalent": goal,
            "spawnflags": "4"}, mv)
    makers("lc_raven_maker", "lc_raven_zombie", "lc_raven_march", "lc_raven_rally",
           [(W(900, 160, Z + 8), "npc_zombie"), (W(930, -480, Z + 8), "npc_zombie"), (W(860, -960, Z + 8), "npc_fastzombie"), (W(896, 860, Z + 8), "npc_headcrab"),
            (W(160, -540, Z + 8), "npc_headcrab")])
    makers("lc_raven_hatch_maker", "lc_raven_hatch_zombie", "lc_raven_hatch_march", "lc_raven_hatch_rally",
           [((1312, yb + 200, FLOOR + 8), "npc_zombie"), ((1312, yb + 420, FLOOR + 8), "npc_headcrab")])

    # --- the houses: a wall 8 thick down the middle of each with a way through, frames to the doorways, the city's doors ----
    hv = "LC ravenholm: houses"
    for (u, v1, v2, gap) in ((316, -320, -64, -216), (348, 448, 704, 540)):
        vmf.detail([B(u, v1, Z, u + 8, gap, Z + 144), B(u, gap + 48, Z, u + 8, v2, Z + 144), B(u, gap, Z + 108, u + 8, gap + 48, Z + 144)], RMAT["room_wall"], vis=hv)
    for (u1, v1) in ((256, -64), (192, -384), (320, 384)):      # each doorway is a square 64 wide through a wall 64 thick: jambs to 48
        vmf.detail([B(u1, v1, Z, u1 + 8, v1 + 64, Z + 112), B(u1 + 56, v1, Z, u1 + 64, v1 + 64, Z + 112), B(u1 + 8, v1, Z + 108, u1 + 56, v1 + 64, Z + 112)], MAT["beam"], vis=hv)
        pos = W(u1 + 8, v1 + 32, Z + 54)
        vmf.point("prop_door_rotating", pos, {
            "model": "models/props_c17/door01_left.mdl", "angles": "0 270 0", "ajarangles": "0 0 0", "axis": "%d %d %d, %d %d %d" % (pos + pos), "distance": "90", "dmg": "0",
            "fademindist": "-1", "fadescale": "1", "forceclosed": "0", "hardware": "1", "health": "0", "opendir": "0", "rendercolor": "255 255 255", "returndelay": "-1",
            "skin": "7", "spawnflags": "8192", "spawnpos": "0", "speed": "100"}, hv)
    for (u, v) in ((220, -190), (420, -190), (230, 580), (470, 580)):
        vmf.point("light", W(u, v, Z + 128), {"_light": "255 200 150 70", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, "LC ravenholm: lights")

    def static(model, u, v, yaw, vis=pv):
        vmf.point("prop_static", W(u, v, Z), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6", "disableshadows": "0", "screenspacefade": "0",
                                              "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)

    def loose(model, u, v, yaw):
        vmf.point("prop_physics", W(u, v, Z + 24), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "spawnflags": "0"}, pv)
    for model, u, v, yaw in (("models/props_c17/furnituretable002a.mdl", 200, -250, 0), ("models/props_wasteland/controlroom_chair001a.mdl", 200, -200, 180),
                             ("models/props_forest/shelves_wood.mdl", 480, -200, 270), ("models/props_junk/wood_crate001a.mdl", 440, -100, 30),
                             ("models/props_wasteland/kitchen_shelf002a.mdl", 160, 600, 90), ("models/props_c17/furnituretable002a.mdl", 480, 520, 0),
                             ("models/props_forest/bunkbed.mdl", 500, 660, 90)):
        static(model, u, v, yaw, hv)

    # --- boarded windows on every wall that looks onto a street: a dark pane, two boards across; a dark pane above ---------
    runs = {}
    for (i, j), spec in cells.items():
        if spec[0] != "open":
            continue
        x, y = i * CELL, j * CELL
        for (di, dj, axis, line, side, a) in ((0, -1, "x", y, 1, x), (0, 1, "x", y + CELL, -1, x), (-1, 0, "y", x, 1, y), (1, 0, "y", x + CELL, -1, y)):
            if cells.get((i + di, j + dj), ("",))[0] == "solid":
                runs.setdefault((axis, line, side), []).append(a)
    panes, boards = [], []

    def along(axis, a, b, lo, hi, z1, z2):
        return B(a, lo, z1, b, hi, z2) if axis == "x" else B(lo, a, z1, hi, b, z2)
    for (axis, line, side), parts in sorted(runs.items()):
        parts.sort()
        start = prev = None
        for a in parts + [None]:
            if a is not None and start is not None and a == prev + CELL:
                prev = a
                continue
            if start is not None:
                for p in range(start + 64, prev + CELL - 96, 192):
                    panes.append(along(axis, p, p + 64, min(line, line + 2 * side), max(line, line + 2 * side), Z + 80, Z + 192))
                    panes.append(along(axis, p, p + 64, min(line, line + 2 * side), max(line, line + 2 * side), Z + 320, Z + 448))
                    for z in (Z + 104, Z + 152):
                        boards.append(along(axis, p - 8, p + 72, min(line + 2 * side, line + 5 * side), max(line + 2 * side, line + 5 * side), z, z + 12))
            start = prev = a
    vmf.detail(panes, MAT["black"], vis="LC ravenholm: windows")
    vmf.detail(boards, RMAT["board"], vis="LC ravenholm: windows")

    # --- what is left in the streets ----------------------------------------------------------------------------------
    for model, u, v, yaw in (("models/props_vehicles/car002a_physics.mdl", 300, 250, 20), ("models/props_vehicles/car004a_physics.mdl", 560, 120, 200),
                             ("models/props_debris/barricade_tall01a.mdl", 640, 300, 100), ("models/props_foliage/tree_dead01.mdl", 928, 160, 0),
                             ("models/props_junk/trashdumpster02.mdl", 1100, 380, 180), ("models/props_wasteland/barricade001a.mdl", 900, -260, 90),
                             ("models/props_vehicles/truck001a.mdl", 760, -960, 35), ("models/props_wasteland/cargo_container01.mdl", 1060, -1000, 80),
                             ("models/props_debris/broken_pile001a.mdl", 620, -520, 40), ("models/props_debris/concrete_chunk01a.mdl", 150, -620, 0),
                             ("models/props_vehicles/car005a_physics.mdl", 980, 880, 300), ("models/props_debris/barricade_short01a.mdl", 896, 560, 90)):
        static(model, u, v, yaw)
    for model, u, v in (("models/props_junk/sawblade001a.mdl", 800, 60), ("models/props_junk/sawblade001a.mdl", 1010, -700), ("models/props_junk/sawblade001a.mdl", 140, -450),
                        ("models/props_c17/oildrum001_explosive.mdl", 1040, 300), ("models/props_c17/oildrum001_explosive.mdl", 1080, 250),
                        ("models/props_c17/oildrum001_explosive.mdl", 600, -980), ("models/props_junk/wood_pallet001a.mdl", 880, 820), ("models/props_c17/oildrum001.mdl", 720, 200)):
        loose(model, u, v, random.Random(u + v).randrange(0, 360, 15))
    for (u, v, colour) in ((928, 160, "255 150 80 140"), (896, 620, "255 170 100 80"), (930, -500, "255 160 90 90"), (860, -960, "255 150 80 110"), (160, -540, "200 220 255 50")):
        vmf.point("light", W(u, v, Z + 150), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, "LC ravenholm: lights")
    for (u, v) in ((352, 192), (928, 160), (928, -480), (860, -960), (896, 860), (160, -540)):
        vmf.point("env_cubemap", W(u, v, Z + 72), {"cubemapsize": "0"}, dv)

    # --- where the city's people (and what is made here) can walk ------------------------------------------------------------
    node_id = [args.first_node]

    def node(x, y, z):
        vmf.point("info_node", (x, y, z + 16), {"nodeid": node_id[0]}, "LC ravenholm: path nodes")
        node_id[0] += 1
    for (i, j), spec in sorted(cells.items()):
        if spec[0] != "solid" and i % 2 == 1 and j % 2 == 1:
            node(X0 + i * CELL + 32, Y0 + j * CELL + 32, Z)
    for (u, v) in ((288, -32), (224, -352), (352, 416), (200, -130), (430, -250), (250, 640), (480, 620)):
        node(X0 + u, Y0 + v, Z)
    for x in range(1088, X0, 128):
        node(x, Y0 + 192, Z)                                 # along the owner's own last stretch of street
    node(1312, ys - 32, Z)
    node(1312, ys + 60, Z)
    for i in range(3, STEPS, 5):
        node(1312, ya + 12 * i + 6, Z - 8 * (i + 1))
    for y in range(yb + 40, slot_y, 128):
        node(1312, y, FLOOR)
    for y in (slot_y + 40, wall_y - 30):
        node(1234, y, FLOOR)
    if not test:
        vmf.point("info_node", (1234, wall_y + 40, 307 + 16), {"nodeid": node_id[0]}, "LC ravenholm: path nodes", outside=True)   # on the sewer's own ledge
        node_id[0] += 1

    # --- the checks: sealed, with the owner's own street (which is not in this file) stopped round ----------------------------
    lobby = [(1008, Y0 - 64, base - 16, 1024, Y0 + 448, SKY + 32), (1024, Y0 - 64, base - 16, X0, Y0 + 448, base), (1024, Y0 - 64, SKY + 16, X0, Y0 + 448, SKY + 32),
             (1024, Y0 + 384, base, 1152, Y0 + 448, SKY + 16), (1200, ys, 816, 1424, ys + 16, SKY + 16)]
    behind = (TX1, wall_y + 8, 239, 1252, wall_y + 24, CEIL + 16)
    if test:
        xv = "LC ravenholm: for testing alone (never in the real map)"
        for box in lobby + [behind]:
            vmf.world_box(box, sky, sky, sky, vis=xv)
        for box in ((1024, Y0 + 64, base, X0, Y0 + 320, Z), (1024, Y0, base, 1216, Y0 + 64, Z), (1024, Y0 + 320, base, 1152, Y0 + 384, Z)):
            vmf.world_box(box, RMAT["brick_low"], top=RMAT["road"], vis=xv)                                   # the owner's roadway and pavements, stood in for
        test_extras(vmf, (1120, Y0 + 192, Z + 16), 0, xv)
    problems, air = check(vmf, W(352, 192, Z + 64), [] if test else lobby + [behind])
    args.expect_overlap = set(DELETE) | set(STANDS_IN)
    seals = sum(1 for _, s in vmf.boxes if s)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys_ = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    print("ravenholm: %d sealing brushes, %d entities (%d path nodes, ids %d to %d), %d boarded windows" % (
        seals, len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1, len(panes) // 2))
    print("  it fills x %d to %d, y %d to %d, z %d to %d; the street is z %d" % (min(xs), max(xs), min(ys_), max(ys_), 239, SKY + 16, Z))
    print("  the gate: the owner's wall at x 93..107, y -2526..-2188 again, as a mover that sinks into the street (lc_raven_gate_open, _shut)")
    print("  the tunnel: from a house at (1312 %d), %d steps down, then %d north at z %d to the sewer wall at y %d; the hatch is x %d..1252 (lc_raven_hatch_open, _shut)" % (
        ys, STEPS, slot_y - yb, FLOOR, wall_y, TX1))
    print("  the owner deletes brushes 65929, 51870, 62363 (the wall and its rails), 15623 (the unseen wall round it), 33530 (a black sheet in it), 28290 (the sewer wall) "
          "and 34874 (the bare strip of road)")
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (%s)" % ("by itself: this is the test version" if test else
                                                                 "with the owner's street, which it opens onto, stopped round: by itself this file is OPEN there and will leak"))
    return vmf, problems
