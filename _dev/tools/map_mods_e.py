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

from map_build import CELL, GATE_HIGH, MAT, gate_cap, prism
from map_modules import CANAL_W, F, SCAPES, WIDE_W, CANAL_JUNK, canal_grime, walk_ledge

HALF, WHALF = CANAL_W // 2, WIDE_W // 2


def wide_walls(m, u1, u2):
    """The wide canal's walls upright from u1 to u2 (the rectangles reach 8 past the walls' lines, not past the ends)."""
    m.upright(u1, -WHALF - 64, u2, -WHALF + 8)
    m.upright(u1, WHALF - 8, u2, WHALF + 64)


def odds(m, u1, u2, v, seed, mid=0):
    """What the wide canal's floor collects: odds and ends from CANAL_JUNK, puddles and trash, the same every build."""
    m.scatter(u1 + 64, mid - v, u2 - 64, mid + v, max(1, (u2 - u1) // 384), seed, kinds=CANAL_JUNK)
    canal_grime(m, u1, u2, seed + 1)


def seed_of(m, k):
    x, y = m.fr.pt(0, 0)
    return k + (x * 7 + y * 13) % 997


def one_side(m, opt):
    """+1 or -1: the side (module's v) a one-sided widening goes to ("oneleft": the world's left of the way the chain
    runs; the chain asks for it beside a street, so the wall on the street's side runs straight on); 0 if both."""
    d = 1 if "oneleft" in opt else -1 if "oneright" in opt else 0
    return -d if m.fr.flip else d


def one_sided(m, d, wide_end, step_at, u_wide, wall_u):
    """widen (wide_end "hi") or narrow ("lo") to one side d: the street's side straight, the far side out 256 then 512."""
    near, far = (-HALF, HALF) if d > 0 else (HALF, -HALF)

    def span(out):
        return (min(near, far + d * out), max(near, far + d * out))
    for (u1, u2), out in zip(step_at, (0, 256, 512) if wide_end == "hi" else (512, 256, 0)):
        a, c = span(out)
        m.open(u1, a, u2, c)
    a, c = span(512)
    m.upright(wall_u[0], a - 64, wall_u[1], a + 8)
    m.upright(wall_u[0], c - 8, wall_u[1], c + 64)
    odds(m, u_wide[0], u_wide[1], 300, seed_of(m, 4100 if wide_end == "hi" else 4200), mid=d * 256)


def m_widen(m, opt):
    """The canal widens from 512 to 1024 (Valve's airboat canals' width): 256 of the city canal, then its walls step out
    128 each side, and again 256 on, so it is 1024 wide for its last 256. The banks wrap round both steps (a slope up
    each step's face, a quarter pyramid on each corner) and stop against the wide canal's upright walls. The next
    module must be a wide one ("wide", "widetee", a turn) or "narrow". Beside a street the chain makes it one-sided
    ("oneleft", "oneright"): the street's wall runs straight on, the far one steps out 256 and 256 again."""
    d = one_side(m, opt)
    if d:
        one_sided(m, d, "hi", ((0, 256), (256, 512), (512, 768)), (512, 768), (520, 832))
        m.soundscape(SCAPES["courtyard"], 512, d * 256, F, radius=900)
        return
    m.open(0, -HALF, 256, HALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -WHALF, 768, WHALF)
    wide_walls(m, 520, 832)       # (from 8 past the second step: its slope keeps its last square)
    odds(m, 512, 768, 300, seed_of(m, 4100))
    m.soundscape(SCAPES["courtyard"], 512, 0, F, radius=900)


def m_narrow(m, opt):
    """The wide canal narrows back to 512: the mirror of "widen" (256 of the wide canal, two steps in, 256 of the city
    canal), the banks starting again round the steps. One-sided beside a street, as "widen"."""
    d = one_side(m, opt)
    if d:
        one_sided(m, d, "lo", ((0, 256), (256, 512), (512, 768)), (0, 256), (-64, 248))
        m.soundscape(SCAPES["courtyard"], 256, d * 256, F, radius=900)
        return
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
    walk along the left wall where the basin is 2560 or longer ("flip": the right; "noledge": none), odds and ends.
    (Valve's boathouse, jetty and lookout stood here for one build: the owner's walk, 22 November, "floating props and
    no walls and a missing ceiling", "why are these on the other side": a piece lifted from a riverbank on piles does
    not stand in a dry canal. Lesson valve-piece-fit.)"""
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
    Beside a street (the canal ring) the leaf on the street's bank, open, stands 300 over the street at its canal edge,
    its recess reaching under the street's edge: the street's parapet is left out there (it would run through the leaf).
    The gates start open: they swing open as the map starts ("lockgate shut" leaves them shut); the Combine, or rebels
    laying an ambush, shut them at the booth (the owner, 21 November). Nothing kills (the owner, 22 November: "considering
    how dying in the gamemode means a new character, yes just shove, not kill"; until then a leaf killed whatever it met):
    in the last moments of each swing a shove pushes whoever is in a leaf's way out of it. Path nodes go round by the
    passage, never through the gate line. The canal is 1024 wide at both ends (between "widen" and "narrow").
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
        m.unpaint(G - 64, min(s * H, s * WHALF), G, max(s * H, s * WHALF))      # (the pier out to the hinge: it stopped at 448 and left a gap each side, the owner saw)
        m.open(G, min(s * WHALF, s * (WHALF + 64)), G + 448, max(s * WHALF, s * (WHALF + 64)))
    m.upright(-64, -WHALF - 448, L + 64, WHALF + 448)          # (every wall upright, as the wide canal's)
    ss = m.street_side()
    if ss:      # (beside a street the open leaf on its bank stands up out of its recess past the street's canal edge: no parapet or chain link there, through the leaf)
        m.b.edge_gaps.append(m.fr.rect(G, min(ss * (WHALF - 20), ss * (WHALF + 28)), G + 448, max(ss * (WHALF - 20), ss * (WHALF + 28))))
    for s in (1, -1):                                           # (no lip or rib on the piers, where the leaves stand)
        m.no_bank(G - 72, min(s * (H - 8), s * (WHALF + 72)), G + 8, max(s * (H - 8), s * (WHALF + 72)))
        m.taken(G - 80, min(s * (H - 18), s * (WHALF + 68)), F, G + 470, max(s * (H - 18), s * (WHALF + 68)), F + 600)
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
    leaf = {"spawnflags": "512", "speed": "15", "distance": "80", "wait": "-1", "lip": "0", "dmg": "0", "health": "0", "angles": "0 0 0", "spawnpos": "0",
            "noise1": "d1_canals.Floodgate_Move_Short", "noise2": "d1_canals.Floodgate_Stop", "forceclosed": "0", "ignoredebris": "0", "solidbsp": "0",
            "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1", "locked_sentence": "0", "unlocked_sentence": "0"}
    state = [("OnOpen", "lc_lockgate_state", "SetValue", "1", 0), ("OnOpen", "lc_lockgate_portal", "Open", "", 0),
             ("OnOpen", "lc_lockgate_switch_model", "SetAnimation", "togglein", 0), ("OnOpen", "lc_lockgate_switch_light", "Color", "0 255 0", 0.2),
             ("OnOpen", "lc_lockgate_switch_light", "SetScale", "0.05", 0.2), ("OnOpen", "lc_lockgate_switch_light", "SetScale", "0.1", 0.3),
             ("OnClose", "lc_lockgate_state", "SetValue", "0", 0),
             ("OnClose", "lc_lockgate_switch_model", "SetAnimation", "toggleout", 0), ("OnClose", "lc_lockgate_switch_light", "Color", "255 0 0", 0.2),
             ("OnClose", "lc_lockgate_switch_light", "SetScale", "0.05", 0.2), ("OnClose", "lc_lockgate_switch_light", "SetScale", "0.1", 0.3),
             ("OnFullyOpen", "lc_lockgate_opened", "Trigger", "", 0),
             ("OnFullyClosed", "lc_lockgate_portal", "Close", "", 0), ("OnFullyClosed", "lc_lockgate_closed", "Trigger", "", 0)]
    from map_forest import shove
    swing = 80 / 15.0              # (a leaf's swing, in seconds: 80 degrees at 15 a second)
    for name, s, model, flags, off in (("lc_lockgate_leaf_a", 1, "locks_large_b", "512", (37, -164)), ("lc_lockgate_leaf_b", -1, "locks_large", "514", (36, 163))):
        hx, hy, hz = m.fr.at(G - 4, s * H, F + 248)
        keys = dict(leaf, targetname=name, spawnflags=flags, origin="%d %d %d" % (hx, hy, hz))
        lo, hi = min(0, s * (H + 64)), max(0, s * (H + 64))
        # The leaf's own brush is as thick as Valve's model (the model rides on it, not solid itself). It used to kill: what
        # it met died or broke (damage 10000, as Valve's), nothing held it (forceclosed; the owner, 21 November: "make the
        # crush anything"), and unseen boxes on its leading faces killed whoever was in the way (map_forest's crusher, the
        # silo doors' way then). The owner's newer word replaces that (22 November, of every door that killed: "considering
        # how dying in the gamemode means a new character, yes just shove, not kill"): no damage, not forced closed, and in
        # the last moments of each swing a shove (map_forest.shove) pushes whoever is in its way out of it. Shutting (it
        # swings upstream into the gate line): across its half of the gate line, upstream on the upstream side (harder)
        # and downstream on the downstream side, which also empties the gap between the two leaves' ends as they meet.
        # Opening (it swings downstream to lie along the wall): between it and the wall, back into its recess, where it
        # leaves 50 or more clear when open. Each from its own start (OnClose, OnOpen): on 0.6 s before the swing is done,
        # off 0.3 s after.
        shut, opening = name.replace("leaf", "shove") + "_shut", name.replace("leaf", "shove") + "_open"
        t_on, t_off = round(swing - 0.6, 2), round(swing + 0.3, 2)
        wires = [("OnClose", shut, "Enable", "", t_on), ("OnClose", shut, "Disable", "", t_off), ("OnOpen", opening, "Enable", "", t_on),
                 ("OnOpen", opening, "Disable", "", t_off)]
        b.vmf.brush_entity("func_door_rotating", keys, [m.fr.box(G - 68, lo, F + 8, G + 136, hi, F + 564)], MAT["nodraw"], m.dv,
                           connections=(state if s > 0 else []) + wires)
        b.names.append((name, "func_door_rotating", m.tag))
        shove(b.vmf, shut, [(m.fr.box(G - 104, lo, F + 8, G + 34, hi, F + 200), m.fr.yaw(180), 300), (m.fr.box(G + 34, lo, F + 8, G + 172, hi, F + 200), m.fr.yaw(0), 200)], m.dv)
        shove(b.vmf, opening, [(m.fr.box(G, s * H, F + 8, G + 448, s * (WHALF + 64), F + 200), m.fr.yaw(90 if s > 0 else 270), 200)], m.dv)
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


def m_floodgate(m, opt):
    """The flood gate (the owner, 26 November: "copy the flood gate that blocks the airboat (right after you get the
    airboat) from HL2 and requires the valve to be turned; and if the valve stops being turned mid-open, the gate slams
    shut"): Valve's sliding sluice gate of d1_canals_05 (the prefab valve_canal_sluicegate_a: two metal leaves 188 wide
    side by side, door panels under a band of grating in a truss frame, 206 high) in a concrete headwall across the
    canal, its crest at the street's height. The leaves are func_movelinears that slide apart into the headwall's
    piers as far as the wheel has been turned (Half-Life 2's valvewheel001 on an unseen momentary_rot_button: hold E;
    two full turns open them). While it is turned an alarm sounds as the forest bunker's door does and a red beacon
    turns over the wheel; the gate's rumble lasts while it moves and stops with it. Let go before it is fully open
    and it slams shut; once fully open it stays, closing so slowly that it takes two minutes, and turning the wheel
    again in that time opens it again (the owner, 26 November: "once the door has been opened all the way, it stays
    open and doesn't slam shut EXCEPT it slowly slowly starts to shut and would take about 2 minutes to shut all the
    way again; if someone turns the valve again during this 2 minutes it resumes it's opening sequence"). The wheel
    stands where the men who built it would have set it with the water in mind (the owner: "the valve wheel is just
    below the canal/road level and not at the bottom of the canal ... we need to keep in mind how it would have been
    constructed with a potential water level in mind"): on the headwall's upstream face 64 under its crest, over a
    steel service platform 112 under it on the street's bank (the left, where there is no street), reached by an iron
    ladder up the canal's wall. A lamp by the wheel, a danger sign and a number on the headwall. A leaf that meets
    someone stops.
    Named for the game: lc_floodgate_N_wheel (the momentary_rot_button: Lock, Unlock, SetPosition 0 to 1),
    lc_floodgate_N_leaf_a and _b (the func_movelinears: SetPosition 0 shut to 1 open), lc_floodgate_N_latch (a
    logic_branch: 1 from fully open until shut again), lc_floodgate_N_beacon, _alarm, _alarm_timer, _move and _clang
    (the beacon and the sounds), N counting the flood gates of a map from 1.
    Left as brushes: the headwall, the leaves (they move), the platform.
    Unchecked (from Valve's wiki and maps, not run here): that a momentary_rot_button's Position output drives a
    func_movelinear's SetPosition as it turns and as it runs back, and that SetPositionImmediately 0 on the wheel sends
    it; which way valvewheel001 faces when pitched 90; plats/elevator_move_loop1.wav and
    doors/door_metal_large_chamber_close1.wav."""
    from map_mods_c import brush, cage_lamp, sound
    from map_modules import TRIM
    b = m.b
    b.floodgates = getattr(b, "floodgates", 0) + 1
    name = "lc_floodgate_%d" % b.floodgates
    cw = MAT["canal_wall"]
    m.open(0, -256, 512, 256)
    side = m.street_side() or 1                     # (the bank the platform, its ladder and the wheel are on)
    G = 256                                         # the gate's line
    if getattr(b, "buried", False):
        TRIM = b.rim - 16                           # (under the city the headwall stands to the tunnel's roof)
    # the headwall: a pier each side, a beam over the gate's opening (376 wide, 206 high), its crest a walk
    m.det([(G - 32, -256, F, G + 32, -188, TRIM), (G - 32, 188, F, G + 32, 256, TRIM)], cw, top=MAT["quay_floor"])
    m.det([(G - 32, -188, F + 208, G + 32, 188, TRIM)], cw, top=MAT["quay_floor"])
    m.det([(G - 36, -196, F + 200, G + 36, 196, F + 216)], MAT["beam"])                    # (the opening's lintel, 4 proud)
    m.taken(G - 40, -256, F, G + 40, 256, TRIM + 8)
    m.no_bank(G - 96, -264, G + 96, 264)
    m.blocked(G - 64, -256, G + 64, 256)
    # the leaves
    for leaf, sgn in (("a", -1), ("b", 1)):
        v1, v2 = sorted((0, sgn * 188))
        e1, e2 = (v1, v1 + 8) if sgn < 0 else (v2 - 8, v2)       # (its outer stile, in the pier; its meeting stile at the middle)
        c1, c2 = (v2 - 8, v2) if sgn < 0 else (v1, v1 + 8)
        parts = [((G - 4, v1 + 8, F + 2, G + 4, v2 - 8, F + 180), "metal/metaldoor046a"), ((G - 3, v1 + 8, F + 180, G + 3, v2 - 8, F + 198), "metal/metalgrate013a"),
                 ((G - 6, e1, F + 2, G + 6, e2, F + 206), "metal/metaltruss017a"), ((G - 6, c1, F + 2, G + 6, c2, F + 206), "metal/metaltruss017a"),
                 ((G - 6, v1 + 8, F + 198, G + 6, v2 - 8, F + 206), "metal/metaltruss017a")]
        brush(m, "func_movelinear", {"targetname": "%s_leaf_%s" % (name, leaf), "movedir": "0 %d 0" % m.fr.yaw(90 if sgn > 0 else 270), "movedistance": "184",
                                     "speed": "900", "startposition": "0", "blockdamage": "0", "spawnflags": "0", "disableshadows": "1"}, parts, "metal/metaldoor046a",
              connections=[("OnFullyClosed", name + "_clang", "PlaySound", "", 0)] if leaf == "a" else None)
        del b.vmf.boxes[-len(parts):]      # (a gate that opens is a way through, to the walk check)
    # the service platform on the bank, 112 under the crest, its ladder up the canal's wall, the wheel on the headwall's
    # upstream face 64 under the crest
    pz, wz = TRIM - 112, TRIM - 64
    p1, p2 = sorted((side * 144, side * 256))
    m.det([(G - 128, p1, pz - 8, G - 32, p2, pz)], "metal/metalgrate013a")
    m.det([(G - 128, p1, pz - 24, G - 120, p2, pz - 8), (G - 44, p1, pz - 24, G - 36, p2, pz - 8)], MAT["bars"])
    r1, r2 = sorted((side * 144, side * 148))
    m.det([(G - 128, r1, pz, G - 124, r2, pz + 40), (G - 36, r1, pz, G - 32, r2, pz + 40), (G - 128, r1, pz + 36, G - 32, r2, pz + 40)], MAT["bars"])
    m.ladder(G - 160, side * 256, F, pz, 270 if side > 0 else 90)
    m.taken(G - 200, side * 136, F, G - 32, side * 256, TRIM)
    wv = side * 216
    ax = 64 if m.fr.ax("u") == "x" else 128
    # How it works (the owner, 26 November, after trying the first one, which followed the wheel and slammed whenever it
    # was let go): hold the wheel and the leaves slide open as it turns, an alarm sounding as the forest bunker's door does
    # (its klaxon, every 1.7 seconds) and a red beacon turning; the gate's own rumble lasts as long as it is being turned
    # and no longer. Let go before it is fully open and it slams shut. Once fully open it does not slam: the wheel runs
    # back so slowly that the leaves take two minutes to close, the beacon turning all the while, and turning the wheel
    # again in that time opens it again from where it is.
    #   the wheel's returnspeed is 6 (720 degrees in 120 seconds), so by itself it always closes slowly;
    #   _latch (a logic_branch, 0 until the gate has been fully open, 0 again once it is shut): the wheel's OnUnpressed
    #   tests it, and while it is 0 the wheel is put straight back to 0 (SetPositionImmediately), which slams the leaves.
    wires = [("Position", "%s_leaf_a" % name, "SetPosition", "", 0), ("Position", "%s_leaf_b" % name, "SetPosition", "", 0),
             ("OnPressed", name + "_move", "PlaySound", "", 0), ("OnPressed", name + "_alarm_timer", "Enable", "", 0), ("OnPressed", name + "_alarm", "PlaySound", "", 0),
             ("OnPressed", name + "_beacon", "Start", "", 0), ("OnPressed", name + "_beacon_spot", "LightOn", "", 0),
             ("OnUnpressed", name + "_move", "StopSound", "", 0), ("OnUnpressed", name + "_alarm_timer", "Disable", "", 0), ("OnUnpressed", name + "_latch", "Test", "", 0),
             ("OnFullyClosed", name + "_latch", "SetValue", "1", 0), ("OnFullyClosed", name + "_move", "StopSound", "", 0),
             ("OnFullyClosed", name + "_alarm_timer", "Disable", "", 0), ("OnFullyClosed", name + "_clang", "PlaySound", "", 0),
             ("OnFullyOpen", name + "_latch", "SetValue", "0", 0), ("OnFullyOpen", name + "_beacon", "Stop", "", 0), ("OnFullyOpen", name + "_beacon_spot", "LightOff", "", 0)]
    brush(m, "momentary_rot_button", {"targetname": name + "_wheel", "speed": "40", "distance": "720", "returnspeed": "6", "startposition": "0", "startdirection": "-1",
                                      "sounds": "0", "spawnflags": str(1024 + ax), "rendermode": "10", "renderamt": "0", "disableshadows": "1",
                                      "origin": "%d %d %d" % m.fr.at(G - 40, wv, wz)},
          [((G - 48, wv - 14, wz - 14, G - 32, wv + 14, wz + 14), MAT["nodraw"])], MAT["nodraw"], connections=wires)
    m.point("logic_branch", G - 60, wv, wz + 40, {"targetname": name + "_latch", "InitialValue": "0"},
            connections=[("OnFalse", name + "_wheel", "SetPositionImmediately", "0", 0), ("OnFalse", "%s_leaf_a" % name, "SetPosition", "0", 0),
                         ("OnFalse", "%s_leaf_b" % name, "SetPosition", "0", 0), ("OnFalse", name + "_beacon", "Stop", "", 0.5),
                         ("OnFalse", name + "_beacon_spot", "LightOff", "", 0.5)])
    sound(m, name + "_move", "plats/elevator_move_loop1.wav", G, 0, F + 120, loops=True, radius=2200)
    sound(m, name + "_alarm", "ambient/alarms/klaxon1.wav", G - 40, wv, wz + 30, radius=2600)
    sound(m, name + "_clang", "doors/door_metal_large_chamber_close1.wav", G, 0, F + 120, radius=2200)
    m.point("logic_timer", G - 60, wv, wz + 56, {"targetname": name + "_alarm_timer", "RefireTime": "1.7", "UseRandomTime": "0", "StartDisabled": "1", "spawnflags": "0"},
            connections=[("OnTimer", name + "_alarm", "PlaySound", "", 0)])
    # the red beacon over the wheel, as the lock gates' booth has: a func_rotating with two red spotlights in a cage lamp
    bu, bv, bz = G - 40, side * 176, TRIM - 30
    m.static("models/props_c17/light_cagelight01_on.mdl", bu + 7, bv, 180, z=bz - 6)
    bx, by, bz2 = m.fr.at(bu, bv, bz)
    b.vmf.brush_entity("func_rotating", {"targetname": name + "_beacon", "spawnflags": "64", "maxspeed": "350", "fanfriction": "20", "volume": "0",
                                         "origin": "%d %d %d" % (bx, by, bz2), "rendermode": "0", "dmg": "0", "solidbsp": "0"},
                       [m.fr.box(bu - 8, bv - 8, bz - 8, bu + 8, bv + 8, bz + 8)], MAT["nodraw"], m.dv)
    for ang in ("0 0 -180", "0 180 -180"):
        b.vmf.point("point_spotlight", (bx, by, bz2), {"targetname": name + "_beacon_spot", "parentname": name + "_beacon", "angles": ang, "rendercolor": "255 0 0",
                                                      "spotlightlength": "96", "spotlightwidth": "25", "spawnflags": "2", "HDRColorScale": "0.6", "renderamt": "255"}, m.lv)
    b.names.append((name + "_beacon", "func_rotating", m.tag))
    m.point("prop_dynamic", G - 32, wv, wz, {"model": "models/props_pipes/valvewheel001.mdl", "angles": "90 %d 0" % m.fr.yaw(180), "parentname": name + "_wheel",
                                               "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"})
    cage_lamp(m, G - 32, side * 240, TRIM - 24, 180, "255 214 160 60")
    m.grime("danger", G - 32, -side * 120, F + 250, 3)
    m.grime("number", G - 32, 0, F + 236, 4)
    m.lane(G - 160, 0)
    m.lane(G + 160, 0)
    m.view(40, -120, F, 20, -8, "the flood gate and its wheel")
    b.notes.append("%s: the flood gate %s at (%d %d): the wheel at z %d on its platform at z %d" % ((m.tag, name) + m.fr.pt(G, 0) + (wz + m.fr.dz, pz + m.fr.dz)))


def m_servicetunnel(m, opt):
    """A long way on foot, in Valve's own tunnel: Black Mesa East's tunnel toward Ravenholm (the prefab
    valve_eli_raven_tunnel, lifted from d1_eli_02), laid twice end to end, 2752 of it: an arched concrete tunnel 192 wide
    and 176 to its crown on a marble floor, Valve's pipes along one wall, deck lamps in the crown (one lit in each length,
    the others dead, as Valve left them), a red emergency lamp, and in each length Valve's bulkhead (a doorway 176 wide
    and 112 high, where the Ravenholm door hung). The owner, 26 November, of the bunker forest's place on the ring: "can we
    please make it down a longer tunnel and not put it RIGHT there; like a HL2 tunnel copy/pasted".
    Its floor is at the road's height, 256 over the canal's floor, from end to end of Valve's tunnel (the owner, 27
    November: "the tunnel starts below the water line of the canal, we need it to start somewhere higher, flush with the
    road"): the chain's start gate is lifted to meet it ("startgate road"), and the first canal's east arm climbs to it by
    a stair. At the far end a concrete bulkhead with a doorway 128 wide and 128 high, a stairwell going down 256 to the
    canal's floor height (16 steps), and a landing 512 wide whose end is this chain's gate (its own cap, as a gate's: the
    chain is "close"d), where the bunker forest's west gate meets it, at the forest's own floor. At the near end the same
    bulkhead hides the tunnel's cut end from the gate's culvert. 3264 long: with the start gate the chain is 3520, as before.
    Changed from Valve's: the story left out (Dog, the door he lifts, its marks and triggers); the emergency lamp, dark
    until the attack in Valve's map, is lit; the two fence panels at the base's end left out. The second length is the
    first turned half round. Left as brushes: the tunnel (Valve's own, one func_detail a length), the bulkheads, the stairs.
    Unchecked: which way Valve's pipe models lie once turned with the piece."""
    import copy
    import map_prefab
    from map_mods_c import cage_lamp, vprism
    b = m.b
    L, RUN = 3264, 1376
    H = F + 256                       # (the road's height: the tunnel's floor)
    S0, S1 = 2 * RUN, 2 * RUN + 384   # (the stairwell, from the tunnel's end down to the landing)
    m.low(0, -128, S0, 128, H + 192, floor=H - 8)         # (the room Valve's tunnel stands in: its floor brush is 8 thick, its vault's back at 192)
    m.low(S0, -128, S1, 128, H + 192, floor=F)            # (the stairwell)
    m.low(S1, -256, L, 256, F + GATE_HIGH)                # (the landing, the gate's culvert)
    m.side(0, -256, L, 256)
    m.blocked(0, -128, L, 128)
    m.no_bank(0, -264, L, 264)
    m.portal(62, -128, H - 8, 64, 128, H + 192)
    m.portal(L - 128, -256, F, L - 126, 256, F + GATE_HIGH)
    pf = copy.deepcopy(map_prefab.load("valve_eli_raven_tunnel"))
    keep = []
    for q in pf["points"]:
        k = q["keys"]
        if "interior_fence" in k.get("model", ""):
            continue
        if k.get("targetname") == "light_emergency_turnon":
            k.pop("targetname"); k["spawnflags"] = "0"
        if k.get("targetname") == "Sprite_emerg_lights":
            k.pop("targetname"); k["spawnflags"] = "1"
        keep.append(q)
    pf["points"] = keep
    map_prefab.place(m, pf, 0, 0, H, turn=0, wiring=False)
    map_prefab.place(m, pf, S0, 0, H, turn=2, wiring=False)
    # (the lifted run began where Valve's tunnel bent away north: for its first 208 the north wall and part of the vault were
    #  the bend's own brushes, left behind. The same section built on over that length, in Valve's materials)
    wall, low_, high_, crown = "concrete/concretewall002c", "concrete/concretewall002a", "concrete/concretewall002c", "concrete/concretewall008a"
    for base, way in ((0, 1), (S0, -1)):
        fill = []
        for sg, e, mat, prof in ((1, 208, wall, [(96, 0), (96, 112), (112, 112), (112, 0)]), (1, 203, low_, [(96, 112), (91, 136), (112, 136), (112, 112)]),
                                 (1, 189, low_, [(91, 136), (77, 157), (112, 157), (112, 136)]), (1, 168, high_, [(77, 157), (56, 171), (56, 192), (112, 192), (112, 157)]),
                                 (1, 144, high_, [(56, 171), (32, 176), (32, 192), (56, 192)]), (1, 80, crown, [(-32, 176), (-32, 192), (32, 192), (32, 176)]),
                                 (-1, 56, high_, [(56, 171), (32, 176), (32, 192), (56, 192)])):
            u1, u2 = sorted((base, base + way * e))
            fill.append(prism([(way * sg * v, H + z) for v, z in prof], "x", u1, u2, mat))
        # (and the floor's corner the bend cut off: a triangle of the same marble)
        fill.append(vprism([(base, -way * 112), (base + way * 224, way * 112), (base, way * 112)], H - 8, H, MAT["nodraw"], "stone/marblefloor001b"))
        m.shapes(fill)
    # (Valve's floor stops 24 short of the cut at the base's end: the two ends meet in the middle, a strip of the same marble between them)
    m.det([(RUN - 24, -112, H - 8, RUN + 24, 112, H)], MAT["nodraw"], top="stone/marblefloor001d")
    # the stairwell: 16 steps down from the tunnel's floor to the landing, the room's whole width; two caged lamps
    m.steps(S1, -128, 128, F, H, "u", -1)
    cage_lamp(m, S0 + 128, 128, H + 40, 270, "255 214 160 45")
    cage_lamp(m, S0 + 288, -128, F + 200, 90, "255 214 160 45", lit=False)
    for u0, u1, out in ((0, 16, 180), (S0 - 16, S0, 0)):
        # a bulkhead across the tunnel at each end: it hides the tunnel's cut end, a doorway through it
        m.det([(u0, -128, H, u1, -64, H + 192), (u0, 64, H, u1, 128, H + 192), (u0, -64, H + 128, u1, 64, H + 192)], "concrete/concretewall002a")
        f0, f1 = (u0 - 4, u0) if out == 180 else (u1, u1 + 4)
        if out == 180:
            f0, f1 = u1, u1 + 4      # (its frame on the tunnel's side)
        m.det([(f0, -72, H, f1, -64, H + 136), (f0, 64, H, f1, 72, H + 136), (f0, -72, H + 128, f1, 72, H + 136)], MAT["beam"])
        m.b.vmf.keep_way_clear(m.fr.box(u0 - 48, -64, H, u1 + 48, 64, H + 128), "%s: the tunnel's doorway" % m.tag)
    cage_lamp(m, S0 + 4, 0, H + 150, 0, "255 214 160 45")
    # the landing's end: this chain's gate, capped until the forest is joined (as a gate's: m_gate)
    from map_modules import BASE
    gate_cap(b.vmf, m.fr.box(L - 64, -256, F, L, 256, F + GATE_HIGH), m.fr.box(L - 88, -256, F, L - 80, 256, F + GATE_HIGH), m.fr.ax("v"),
             "%s: the end gate's cap (delete to join)" % b.vis)
    b.allow.append(m.fr.box(L - 64, -448, BASE, L + 64, 448, b.sky + 64))
    b.plan.keep_out.append(m.fr.rect(L, -448, L + 64, 448))
    for u in list(range(64, S0, 256)) + [S0 - 32]:
        m.lane(u, 0, H)
    m.lane(S0 + 192, 0, F + 128)
    m.lane(L - 64, 0, F)
    m.soundscape(SCAPES["tunnel"], 600, 0, H, radius=900)
    m.soundscape(SCAPES["tunnel"], S0 - 600, 0, H, radius=900)
    m.soundscape(SCAPES["watery"], L - 128, 0, F, radius=400)
    m.view(40, 0, H, 0, 0, "down Valve's tunnel")
    m.view(S0 - 120, 0, H, 0, 0, "the far bulkhead and the stairs down")
    m.view(L - 40, 0, F, 180, 10, "up the stairs from the landing")


MODULES = {
    "widen": (768, m_widen, "the canal widens from 512 to 1024 in two steps (its next module must be a wide one)", {"width": (CANAL_W, WIDE_W)}),
    "narrow": (768, m_narrow, "the wide canal narrows back to 512 in two steps", {"width": (WIDE_W, CANAL_W)}),
    "wide": (1024, m_wide, "the wide canal: 1024 between upright walls, any length (\"wide 2048\"), a walk along a wall from 2048", {"width": (WIDE_W, WIDE_W), "stretch": True}),
    "widetee": (512, m_widetee, "a standard gate in the wide canal's left wall, for another piece or layout to join", {"width": (WIDE_W, WIDE_W)}),
    "basin": (2048, m_basin, "the canal widens into a 1024 basin and narrows again (512 at both ends; \"basin 2560\")", {"stretch": True}),
    "servicetunnel": (3264, m_servicetunnel, "a long way on foot at the road's height: Valve's tunnel from Black Mesa East toward Ravenholm, twice end to end, then stairs down to its own end gate"),
    "floodgate": (512, m_floodgate, "Valve's sluice gate in a headwall across the canal: hold its valve wheel to slide the leaves open; let go and they slam shut"),
    "lockgate": (2048, m_lockgate, "Valve's lock gates across the wide canal: toggled open and shut, a klaxon, a control booth, a passage round", {"width": (WIDE_W, WIDE_W)}),
}
