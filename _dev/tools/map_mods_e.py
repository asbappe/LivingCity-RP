#!/usr/bin/env python3
"""
Living City: the wide canal (map_modules.py picks these up by itself)

The owner, 21 November, of Valve's canals against ours: Valve's city canal is 512 wide, as ours, and its airboat
canals 1024. So the chain can now widen: "widen" takes the canal from 512 to 1024 in two steps, "narrow" brings it
back, and between them run the wide modules ("wide", "widetee"), whose ends are 1024 wide. A layout says when it
widens (map_layouts/wide.txt); map_build.py fails a chain whose modules' widths do not meet, and a turn inside the
wide canal is 1024 square. "basin" is the same widening and narrowing in one module, with 512 at both ends, so it
goes anywhere a plain stretch does.

The wide canal's walls stand upright, as Valve's do (the 45 degree banks are kept on the city canal, which the owner
asked for): m.upright keeps the bank off and the rest of the dressing on (lip, ribs, outfalls flush in the wall, the
caged lamps). Its floor sags about 42 at its middle (the dish, map_modules.dish_plan). Where it widens, the banks wrap
round the steps and stop against the wide canal's walls.
"""

from map_build import CELL, GATE_HIGH, MAT, gate_cap
from map_modules import CANAL_W, F, SCAPES, WIDE_W, CANAL_JUNK, canal_grime, walk_ledge

HALF, WHALF = CANAL_W // 2, WIDE_W // 2


def wide_walls(m, u1, u2):
    """The wide canal's walls upright from u1 to u2 (the rectangles reach 8 past the walls' lines, not past the ends)."""
    m.upright(u1, -WHALF - 64, u2, -WHALF + 8)
    m.upright(u1, WHALF - 8, u2, WHALF + 64)


def odds(m, u1, u2, v, seed):
    """What the wide canal's floor collects: odds and ends from CANAL_JUNK, puddles and trash, the same every build."""
    m.scatter(u1 + 64, -v, u2 - 64, v, max(1, (u2 - u1) // 384), seed, kinds=CANAL_JUNK)
    canal_grime(m, u1, u2, seed + 1)


def seed_of(m, k):
    x, y = m.fr.pt(0, 0)
    return k + (x * 7 + y * 13) % 997


def m_widen(m, opt):
    """The canal widens from 512 to 1024 (Valve's airboat canals' width): 256 of the city canal, then its walls step out
    128 each side, and again 256 on, so it is 1024 wide for its last 256. The banks wrap round both steps (a slope up
    each step's face, a quarter pyramid on each corner) and stop against the wide canal's upright walls. The next
    module must be a wide one ("wide", "widetee", a turn) or "narrow"."""
    m.open(0, -HALF, 256, HALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -WHALF, 768, WHALF)
    wide_walls(m, 520, 832)       # (from 8 past the second step: its slope keeps its last square)
    odds(m, 512, 768, 300, seed_of(m, 4100))
    m.soundscape(SCAPES["courtyard"], 512, 0, F, radius=900)


def m_narrow(m, opt):
    """The wide canal narrows back to 512: the mirror of "widen" (256 of the wide canal, two steps in, 256 of the city
    canal), the banks starting again round the steps."""
    m.open(0, -WHALF, 256, WHALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -HALF, 768, HALF)
    wide_walls(m, -64, 248)
    odds(m, 0, 256, 300, seed_of(m, 4200))
    m.soundscape(SCAPES["courtyard"], 256, 0, F, radius=900)


def m_wide(m, opt):
    """The wide canal: 1024 between upright walls, the floor sagging about 42 to its middle, any length ("wide 2048").
    From 2048 long a walk along its left wall (walk_ledge: 102 wide, 320 up, stairs at each end; "flip" puts it on the
    right, "noledge" leaves it out). "bridge": a street carried over its middle; "pipes": a pair of pipes across it.
    Odds and ends lying in it, puddles and trash, the quiet courtyard's soundscape; the lamps and outfalls come with
    its walls (dress_canal_walls)."""
    L = m.fr.length
    m.open(0, -WHALF, L, WHALF)
    wide_walls(m, -64, L + 64)
    cut = (L // 2 - 192, L // 2 + 192) if "bridge" in opt or "pipes" in opt else None
    if L >= 2048 and "noledge" not in opt:
        spans = [(256, L - 256)] if not cut else [(256, cut[0] // 64 * 64), (-(-cut[1] // 64) * 64, L - 256)]
        a, b = max(spans, key=lambda p: p[1] - p[0])
        if b - a >= 640:
            walk_ledge(m, a, b, 1, wide=True, stairs=2 if b - a >= 1152 else 1)
    if "bridge" in opt:
        m.bridge(L // 2 - 128, L // 2 + 128, -WHALF, WHALF)
    if "pipes" in opt:
        (x1, y1), (x2, y2) = m.fr.pt(L // 2, -WHALF), m.fr.pt(L // 2, WHALF)
        m.b.pipes.append(("x", x1, min(y1, y2), max(y1, y2)) if m.fr.ax("u") == "x" else ("y", y1, min(x1, x2), max(x1, x2)))
    if "bare" not in opt:
        odds(m, 0, L, 360, seed_of(m, 4300))
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=max(900, L // 2))


def m_widetee(m, opt):
    """A way off the wide canal's left wall: the same standard gate as "tee" (512 wide, 256 high), capped until another
    piece or another layout's start is joined to it, a number painted beside it. The canal is 1024 wide at both ends."""
    b = m.b
    m.open(0, -WHALF, 512, WHALF)
    wide_walls(m, -64, 576)
    m.low(0, WHALF, 512, WHALF + 256, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, WHALF + 192, F, 512, WHALF + 256, F + GATE_HIGH), m.fr.box(0, WHALF + 168, F, 512, WHALF + 176, F + GATE_HIGH), m.fr.ax("u"),
             "%s: %s side gate's cap (delete to join)" % (b.vis, m.tag))
    m.portal(0, WHALF + 126, F, 512, WHALF + 128, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(-64, WHALF + 256, 576, WHALF + 320))
    m.blocked(0, WHALF + 128, 512, WHALF + 256)
    m.side(0, WHALF, 512, WHALF + 256)
    x, y = m.fr.pt(0, 0)
    canal_grime(m, 0, 512, 3100 + (x * 7 + y * 13) % 997)
    m.grime("number", 512, WHALF + 64, F + 180, x + y)
    m.soundscape(SCAPES["courtyard"], 256, 0, F, radius=900)
    dx, dy = m.fr.way(90)
    b.notes.append("%s: its side gate is at (%d %d), heading %s: a layout may start there" % ((m.tag,) + m.fr.pt(256, WHALF + 256) + ({(1, 0): "E", (0, 1): "N", (-1, 0): "W", (0, -1): "S"}[(dx, dy)],)))


def m_basin(m, opt):
    """The canal widens into a basin 1024 wide and narrows again within one module, so it starts and ends on the plain
    512 section and goes anywhere a plain stretch does ("basin 2560": that long, 2048 at least). Its steps are those of
    "widen" and "narrow" (the banks wrap round them); between them the wide canal's upright walls and deeper dish, a
    walk along the left wall where the basin is 2560 or longer ("flip": the right; "noledge": none), odds and ends."""
    L = m.fr.length
    if L < 2048:
        m.open(0, -HALF, L, HALF)
        m.b.problems.append("%s: a basin is 2048 long at least" % m.tag)
        return
    m.open(0, -HALF, 256, HALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -WHALF, L - 512, WHALF)
    m.open(L - 512, -HALF - 128, L - 256, HALF + 128)
    m.open(L - 256, -HALF, L, HALF)
    wide_walls(m, 520, L - 520)
    if L >= 2560 and "noledge" not in opt:
        walk_ledge(m, 768, L - 768, 1, wide=True, stairs=2 if L - 1536 >= 1152 else 1)
    odds(m, 512, L - 512, 300, seed_of(m, 4400))
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=max(900, L // 2))
    m.view(560, -40, F, 10, 2, "the basin")


# ---------------------------------------------------------------------------
# lockgate: Valve's lock gates (d1_canals_08) across the wide canal
# ---------------------------------------------------------------------------

LOCK_G = 1024                  # the gate line (the leaves stand in u LOCK_G - 48 .. LOCK_G)
LOCK_HINGE = 384               # each leaf turns on a hinge this far either side of the middle (Valve's: 768 apart)
LOCK_TOP = F + 572             # the leaves' models' tops (locks_large: 572 high)
KLAXON = "d1_canals.Floodgate_Klaxon"


def m_lockgate(m, opt):
    """The lock gates: Valve's pair of lock gates from d1_canals_08 across the wide canal (the owner, 21 November: "the
    massive dual water hazard gates that shut and force the player to navigate around them ... a great toggle able gate
    to block the canal"). Two leaves 384 long and 480 high turn 80 degrees on hinges 768 apart, each carrying Valve's
    model (locks_large_b and locks_large, 572 high), wired as Valve's: speed 15, a klaxon four times a second apart as
    they start, Floodgate_Move_Short while they swing and Floodgate_Stop as they stop. Open, they lie in recesses in
    the walls downstream; shut, they close the canal from wall to wall (piers either side of them) and an areaportal in
    their thickness closes behind them, so the far canal is not drawn (Valve's rules: the portal shuts on
    OnFullyClosed and opens on OnOpen; over the leaves the gate line is sky, which it looks like anyway).
    On the left bank, upstream of the gates, a control booth in the wall 192 up (stairs up to it along the wall, the
    city's stair rail, a landing, the city's handrail along its open front, a lamp): on its back wall the switch,
    Valve's CombineButton with a light beside it that shows the gates' state, green open and red shut (Valve's switch
    recipe, the state set by the gates themselves, so it is right whoever moved them); over its front a red beacon
    that turns while the gates move (the alarm recipe: a func_rotating with two red spotlights in a cage lamp).
    For people on foot, the way round: in the right wall a doorway upstream of the gates, a passage 128 wide inside the
    wall, lit, past the gates, and a doorway back into the canal beyond the recesses (its own areaportal, always open).
    The gates start open: they swing open as the map starts ("lockgate shut" leaves them shut); the Combine, or rebels
    laying an ambush, shut them at the booth (the owner, 21 November). Nothing stops a leaf: what it meets dies or is
    broken (damage 10000, as Valve's), loose things in its way are deleted, it never waits. Path nodes go round by
    the passage, never through the gate line. The canal is 1024 wide at both ends (between "widen" and "narrow").
    Named for the game: lc_lockgate_open, lc_lockgate_close and lc_lockgate_toggle (logic_relays the gamemode fires:
    the klaxon, the beacon and the leaves), lc_lockgate_opened and lc_lockgate_closed (logic_relays fired when the
    leaves have finished moving), lc_lockgate_switch (the button in the booth: it fires lc_lockgate_toggle),
    lc_lockgate_state (a logic_branch, 1 while open), lc_lockgate_leaf_a and lc_lockgate_leaf_b (the
    func_door_rotating leaves), lc_lockgate_portal (the areaportal), lc_lockgate_klaxon, lc_lockgate_beacon.
    Left as brushes: the piers, the quoins and the sky over the gate line, the stairs and landing, the booth.
    Unchecked: Valve's sound scripts d1_canals.Floodgate_Klaxon, d1_canals.Floodgate_Move_Short and
    d1_canals.Floodgate_Stop (Half-Life 2's canal sounds); that locks_large and locks_large_b hide the areaportal
    with no gaps (Valve kept theirs far behind the gates); which way CombineButton faces (turned out of the wall and
    tipped back 30, as Valve's)."""
    from map_mods_c import cage_lamp, handrail
    from map_mods_a import tilted
    from map_modules import stair_rail
    b = m.b
    L, G, H = m.fr.length, LOCK_G, LOCK_HINGE
    sky = b.sky - m.fr.dz
    # --- the squares: the wide canal, the piers either side of the leaves, the recesses they open into ---
    m.open(0, -WHALF, L, WHALF)
    for s in (1, -1):
        m.unpaint(G - 64, min(s * 448, s * WHALF), G, max(s * 448, s * WHALF))
        m.open(G, min(s * WHALF, s * (WHALF + 64)), G + 448, max(s * WHALF, s * (WHALF + 64)))
    m.upright(-64, -WHALF - 448, L + 64, WHALF + 448)          # (every wall upright, as the wide canal's)
    for s in (1, -1):                                           # (no lip or rib on the piers, where the leaves stand)
        m.no_bank(G - 72, min(s * 440, s * (WHALF + 72)), G + 8, max(s * 440, s * (WHALF + 72)))
        m.taken(G - 80, min(s * 430, s * (WHALF + 68)), F, G + 470, max(s * 430, s * (WHALF + 68)), F + 600)
    # --- the booth on the left bank: a room in the wall 192 up, open to the canal, stairs up to it ---
    bz = F + 192
    m.low(576, WHALF, 896, WHALF + 192, F + 352, floor=bz, mat=MAT["quay_floor"])
    m.side(576, WHALF, 896, WHALF + 192)
    m.no_bank(280, WHALF - 8, 584, WHALF + 8)
    edge = WHALF - 72
    run = m.steps(288, edge, WHALF, F, bz, "u", 1)
    stair_rail(m, 288, run, edge, bz - F, 1, 1)
    m.det([(288 + run, edge, F, 640, WHALF, bz)], MAT["canal_wall"], top=MAT["quay_floor"])      # the landing at the stairs' head
    handrail(m, (288 + run, edge + 3), (640, edge + 3), bz)
    handrail(m, (637, edge + 8), (637, WHALF), bz)
    handrail(m, (640, WHALF + 3), (896, WHALF + 3), bz)
    m.blocked(272, edge - 16, 640, WHALF)
    m.lamp(736, WHALF + 128, F + 343, "255 214 170 45")
    m.lane(700, WHALF + 96, bz)
    m.lane(240, edge - 48)
    # the switch on the booth's back wall: an unseen button round Valve's CombineButton, a light beside it
    sw, back = 736, WHALF + 192
    tilted(m, "prop_dynamic", "models/props_combine/CombineButton.mdl", sw, back - 6, bz + 44, 270, pitch=-30,
           keys={"targetname": "lc_lockgate_switch_model", "solid": "0"})
    b.vmf.brush_entity("func_button", {"targetname": "lc_lockgate_switch", "spawnflags": "1025", "wait": "3", "speed": "5", "lip": "0", "movedir": "0 0 0",
                                       "sounds": "9", "health": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "min_use_angle": "0.8"},
                       [m.fr.box(sw - 12, back - 18, bz + 32, sw + 12, back, bz + 58)], MAT["nodraw"], m.dv,
                       connections=[("OnPressed", "lc_lockgate_toggle", "Trigger", "", 0)])
    b.names.append(("lc_lockgate_switch", "func_button", m.tag))
    shut = "shut" in opt
    m.point("env_sprite", sw + 18, back - 4, bz + 50, {"targetname": "lc_lockgate_switch_light", "model": "sprites/glow01.spr", "rendermode": "5", "renderamt": "200",
                                                       "rendercolor": "255 0 0", "scale": "0.1", "framerate": "10.0", "GlowProxySize": "2.0", "spawnflags": "1"}, m.lv)
    # the beacon over the booth's front: a func_rotating with two red spotlights back to back, in a cage lamp
    bu, bzb = 864, F + 362
    m.static("models/props_c17/light_cagelight01_on.mdl", bu, WHALF - 1, 270, z=bzb - 6)
    bx, by, bz2 = m.fr.at(bu, WHALF - 5, bzb)
    b.vmf.brush_entity("func_rotating", {"targetname": "lc_lockgate_beacon", "spawnflags": "64", "maxspeed": "350", "fanfriction": "20", "volume": "0",
                                         "origin": "%d %d %d" % (bx, by, bz2), "rendermode": "0", "dmg": "0", "solidbsp": "0"},
                       [m.fr.box(bu - 8, WHALF - 13, bzb - 8, bu + 8, WHALF + 3, bzb + 8)], MAT["nodraw"], m.dv)
    b.names.append(("lc_lockgate_beacon", "func_rotating", m.tag))
    for ang in ("0 0 -180", "0 180 -180"):
        b.vmf.point("point_spotlight", (bx, by, bz2), {"targetname": "lc_lockgate_beacon_spot", "parentname": "lc_lockgate_beacon", "angles": ang, "rendercolor": "255 0 0",
                                                      "spotlightlength": "96", "spotlightwidth": "25", "spawnflags": "2", "HDRColorScale": "0.6", "renderamt": "255"}, m.lv)
    # --- the gate line: piers' quoins, the sky over the leaves, the leaves and their models ---
    for s in (1, -1):
        m.world((G - 63, min(s * 440, s * 448), F, G - 1, max(s * 440, s * 448), LOCK_TOP), MAT["canal_wall"])      # (1 in from the pier's faces: the fence's posts end there)
        cage_lamp(m, G - 64, s * 480, F + 300, 180, colour="255 214 170 60")
    m.world((G - 64, -448, LOCK_TOP, G, 448, sky), MAT["sky"])
    leaf = {"spawnflags": "512", "speed": "15", "distance": "80", "wait": "-1", "lip": "0", "dmg": "10000", "health": "0", "angles": "0 0 0", "spawnpos": "0",
            "noise1": "d1_canals.Floodgate_Move_Short", "noise2": "d1_canals.Floodgate_Stop", "forceclosed": "1", "ignoredebris": "0", "solidbsp": "0",
            "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1", "locked_sentence": "0", "unlocked_sentence": "0"}
    state = [("OnOpen", "lc_lockgate_state", "SetValue", "1", 0), ("OnOpen", "lc_lockgate_portal", "Open", "", 0),
             ("OnOpen", "lc_lockgate_switch_model", "SetAnimation", "togglein", 0), ("OnOpen", "lc_lockgate_switch_light", "Color", "0 255 0", 0.2),
             ("OnOpen", "lc_lockgate_switch_light", "SetScale", "0.05", 0.2), ("OnOpen", "lc_lockgate_switch_light", "SetScale", "0.1", 0.3),
             ("OnClose", "lc_lockgate_state", "SetValue", "0", 0),
             ("OnClose", "lc_lockgate_switch_model", "SetAnimation", "toggleout", 0), ("OnClose", "lc_lockgate_switch_light", "Color", "255 0 0", 0.2),
             ("OnClose", "lc_lockgate_switch_light", "SetScale", "0.05", 0.2), ("OnClose", "lc_lockgate_switch_light", "SetScale", "0.1", 0.3),
             ("OnFullyOpen", "lc_lockgate_opened", "Trigger", "", 0),
             ("OnFullyClosed", "lc_lockgate_portal", "Close", "", 0), ("OnFullyClosed", "lc_lockgate_closed", "Trigger", "", 0)]
    from map_forest import crusher
    for name, s, model, flags, off in (("lc_lockgate_leaf_a", 1, "locks_large_b", "512", (37, -164)), ("lc_lockgate_leaf_b", -1, "locks_large", "514", (36, 163))):
        hx, hy, hz = m.fr.at(G - 4, s * H, F + 248)
        keys = dict(leaf, targetname=name, spawnflags=flags, origin="%d %d %d" % (hx, hy, hz))
        lo, hi = min(0, s * (H + 64)), max(0, s * (H + 64))
        # the leaf's own brush is as thick as Valve's model (the model rides on it, not solid itself): what it meets dies
        # or breaks (damage 10000, as Valve's), and nothing holds it (forceclosed; the owner, 21 November: "make the crush
        # anything"); while it swings, unseen boxes on its leading face kill whoever is in the way and delete what lies there
        # (map_forest.crusher, the owner's silo doors' way), one for closing (its upstream face), one for opening
        shut, opening = name.replace("leaf", "crush") + "_shut", name.replace("leaf", "crush") + "_open"
        wires = [("OnClose", shut, "Enable", "", 0), ("OnClose", opening, "Disable", "", 0), ("OnFullyClosed", shut, "Disable", "", 0),
                 ("OnOpen", opening, "Enable", "", 0), ("OnOpen", shut, "Disable", "", 0), ("OnFullyOpen", opening, "Disable", "", 0)]
        b.vmf.brush_entity("func_door_rotating", keys, [m.fr.box(G - 68, lo, F + 8, G + 136, hi, F + 564)], MAT["nodraw"], m.dv,
                           connections=(state if s > 0 else []) + wires)
        b.names.append((name, "func_door_rotating", m.tag))
        crusher(b.vmf, name, m.fr.box(G - 82, lo, F + 8, G - 68, hi, F + 564), m.dv, shut)
        crusher(b.vmf, name, m.fr.box(G + 136, lo, F + 8, G + 150, hi, F + 564), m.dv, opening)
        tilted(m, "prop_dynamic", "models/props_canal/%s.mdl" % model, G - 4 + off[0], s * H + off[1], F, 0,
               keys={"parentname": name, "solid": "0", "disableshadows": "1"})
    b.vmf.areaportal(m.fr.box(G - 26, -440, F, G - 24, 440, LOCK_TOP), b.vis + ": areaportals", name="lc_lockgate_portal")
    b.names.append(("lc_lockgate_portal", "func_areaportal", m.tag))
    m.blocked(G - 96, -WHALF, G + 160, WHALF)
    # --- the wiring (Valve's relay_locks_opengates and _closegates, the alarm's beacon, a branch for the toggle) ---
    m.point("ambient_generic", G - 32, 0, F + 300, {"targetname": "lc_lockgate_klaxon", "message": KLAXON, "health": "10", "pitch": "100", "pitchstart": "100",
                                                     "radius": "3000", "spawnflags": "48"}, b.vis + ": sounds")      # (a one-shot the wiring plays: 48)
    beacon = [("lc_lockgate_beacon_spot", "LightOn", "", 0), ("lc_lockgate_beacon", "Start", "", 0),
              ("lc_lockgate_beacon_spot", "LightOff", "", 7), ("lc_lockgate_beacon", "Stop", "", 7)]
    for name, move in (("lc_lockgate_open", "Open"), ("lc_lockgate_close", "Close")):
        m.relay(name, G - 96, 0, F + 320, [("lc_lockgate_klaxon", "PlaySound", "", t) for t in (0, 1, 2, 3)]
                + [(n, "Unlock", "", 0) for n in ("lc_lockgate_leaf_a", "lc_lockgate_leaf_b")]
                + [(n, move, "", 0.1) for n in ("lc_lockgate_leaf_a", "lc_lockgate_leaf_b")] + beacon)
    m.relay("lc_lockgate_toggle", G - 128, 0, F + 320, [("lc_lockgate_state", "Test", "", 0)])
    m.point("logic_branch", G - 160, 0, F + 320, {"targetname": "lc_lockgate_state", "InitialValue": "0"},
            connections=[("OnTrue", "lc_lockgate_close", "Trigger", "", 0), ("OnFalse", "lc_lockgate_open", "Trigger", "", 0)])
    for name in ("lc_lockgate_opened", "lc_lockgate_closed"):
        m.relay(name, G - 192, 0, F + 320, [("lc_lockgate_beacon_spot", "LightOff", "", 0), ("lc_lockgate_beacon", "Stop", "", 0)])
    if not shut:      # (they swing open as the map starts, quietly)
        m.point("logic_auto", G - 224, 0, F + 320, {"spawnflags": "1"},
                connections=[("OnMapSpawn", n, "Open", "", 0.5) for n in ("lc_lockgate_leaf_a", "lc_lockgate_leaf_b")])
    # --- the way round on foot: a passage inside the right wall, past the gates ---
    for u1, u2, v1, v2 in ((576, 704, -WHALF - 128, -WHALF), (576, 1664, -WHALF - 256, -WHALF - 128), (1536, 1664, -WHALF - 128, -WHALF)):
        m.low(u1, v1, u2, v2, F + 128)
        m.side(u1, v1, u2, v2)
    m.portal(1088, -WHALF - 256, F, 1090, -WHALF - 128, F + 128)
    for u in (640, 1120, 1600):
        m.lamp(u, -WHALF - 192, F + 119, "255 210 160 40")
    for u in (640, 896, 1152, 1408, 1600):
        m.lane(u, -WHALF - 192)
    m.lane(640, -WHALF - 64)
    m.lane(1600, -WHALF - 64)
    m.soundscape(SCAPES["tunnel"], 1120, -WHALF - 192, F, radius=560)
    m.grime("number", 736, -WHALF, F + 180, 7)                      # (a number by the passage's way in)
    # --- the canal itself: odds and ends clear of the leaves' swing, puddles, its soundscape; pictures ---
    odds(m, 0, 896, 300, seed_of(m, 4500))
    odds(m, 1536, L, 300, seed_of(m, 4600))
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=1100)
    m.view(560, -200, F, 20, -4, "the gates")
    m.view(700, WHALF + 120, bz, 300, 4, "from the booth")
    m.view(700, -WHALF - 192, F, 0, 0, "the passage round")
    b.notes.append("%s: the gate line is at u %d (the leaves start %s); the booth's floor is z %d; the passage round is in the right wall"
                   % (m.tag, G, "shut" if shut else "open (they swing open as the map starts)", bz + m.fr.dz))


MODULES = {
    "widen": (768, m_widen, "the canal widens from 512 to 1024 in two steps (its next module must be a wide one)", {"width": (CANAL_W, WIDE_W)}),
    "narrow": (768, m_narrow, "the wide canal narrows back to 512 in two steps", {"width": (WIDE_W, CANAL_W)}),
    "wide": (1024, m_wide, "the wide canal: 1024 between upright walls, any length (\"wide 2048\"), a walk along a wall from 2048", {"width": (WIDE_W, WIDE_W), "stretch": True}),
    "widetee": (512, m_widetee, "a standard gate in the wide canal's left wall, for another piece or layout to join", {"width": (WIDE_W, WIDE_W)}),
    "basin": (2048, m_basin, "the canal widens into a 1024 basin and narrows again (512 at both ends; \"basin 2560\")", {"stretch": True}),
    "lockgate": (2048, m_lockgate, "Valve's lock gates across the wide canal: toggled open and shut, a klaxon, a control booth, a passage round", {"width": (WIDE_W, WIDE_W)}),
}
