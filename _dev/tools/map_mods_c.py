#!/usr/bin/env python3
"""
Living City: canal modules, set C: the Combine's and the city's machinery in the canals (things both sides fight over).

    lock        a lock house: two steel gates and the control house over the canal that works them
    substation  what powers the Combine's things in the canals: transformers in a fenced yard, a fuse to break
    railbridge  a railway over the canal: a Combine train crosses every few minutes (experimental)
    execwall    where the Combine shoots people
    pumphouse   a pumping station: a machine hall, a turbine pit, a pipe bridge

map_modules.py picks this file up by itself (docs/dev/map-modules.md). Nothing here has been compiled: each module's
docstring ends with what is from memory ("Unchecked").
"""

from map_build import CELL, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM

CMB = "metal/metalcombine002"
STEEL, PIPE = MM["steel"], MAT["bars"]


# ---------------------------------------------------------------------------
# Helpers the Mod class lacks
# ---------------------------------------------------------------------------

def vprism(outline, z1, z2, mat, end_mat=None):
    """A flat shape seen from above (outline: its corners in order, as (u, v)) standing from z1 up to z2: the faces for
    m.shapes. (map_build's prism only pushes a shape along the ground.)"""
    faces = [([(p[0], p[1], z1) for p in outline], end_mat or mat), ([(p[0], p[1], z2) for p in outline], end_mat or mat)]
    for k in range(len(outline)):
        a, b = outline[k], outline[(k + 1) % len(outline)]
        faces.append(([(a[0], a[1], z1), (b[0], b[1], z1), (b[0], b[1], z2), (a[0], a[1], z2)], mat))
    return faces


def brush(m, cls, keys, boxes, mat, connections=None, vis=None, record=True):
    """A brush entity with wires of its own (m.ent has none). boxes: (u1, v1, z1, u2, v2, z2), or (that, its own
    material). record: list its name in the report (False for the second leaf of a pair that shares one name)."""
    out = []
    for b in boxes:
        out.append((m.fr.box(*b[0]), b[1]) if len(b) == 2 else m.fr.box(*b))
    m.b.vmf.brush_entity(cls, keys, out, mat, vis or m.dv, connections=connections)
    if record and keys.get("targetname"):
        m.b.names.append((keys["targetname"], cls, m.tag))


def brush_shapes(m, cls, keys, shapes, boxes=(), mat=STEEL, connections=None, vis=None):
    """A brush entity made of shapes that are not boxes (a wheel): shapes as for m.shapes, boxes as for m.det."""
    v, vis = m.b.vmf, vis or m.dv
    s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (v.new_id(), cls)
    for k, val in keys.items():
        s += '\t"%s" "%s"\n' % (k, val)
    s += v.wires(connections)
    for faces in shapes:
        s += v.convex_text(m.fr.faces(faces), vis)
    for b in boxes:
        box = m.fr.box(*b)
        s += v.box_text(box, mat, mat, mat, vis)
        v.boxes.append((box, False))
    s += v.editor(vis, "220 30 220") + "}\n"
    v.ents.append(s)
    if keys.get("targetname"):
        m.b.names.append((keys["targetname"], cls, m.tag))


def sound(m, name, message, u, v, z, loops=False, on=False, radius=1800, volume=10):
    """A named sound, as the bunker's door has them. spawnflags: 16 starts silent, 32 says "not looped". A sound that
    loops must have 16 alone (or 0 to play from the start): with 32 the entity never counts it as playing and StopSound
    does nothing. One that plays once must have 32, or a second PlaySound does nothing."""
    flags = ("0" if on else "16") if loops else "48"
    m.point("ambient_generic", u, v, z, {"targetname": name, "message": message, "health": str(volume), "pitch": "100", "pitchstart": "100", "radius": str(radius),
                                         "spawnflags": flags, "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0",
                                         "lfotype": "0", "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, m.b.vis + ": sounds")


def sprite(m, name, u, v, z, colour, scale=0.4, on=True):
    """A named glow (ShowSprite, HideSprite): a lamp's shine, with no light of its own."""
    m.point("env_sprite", u, v, z, {"targetname": name, "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220", "rendercolor": colour, "scale": str(scale),
                                    "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0", "renderfx": "0", "spawnflags": "1" if on else "0"}, m.lv)


def named_light(m, name, u, v, z, colour, on=True):
    """A light that can be switched (TurnOn, TurnOff). Steady: no style."""
    m.point("light", u, v, z, {"targetname": name, "_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0", "spawnflags": "0" if on else "1"}, m.lv)


def railing(m, u1, v1, u2, v2, z, high=40, mat=PIPE, step=64):
    """A handrail along a straight line on the ground (u1 == u2 or v1 == v2): a top bar, a middle bar, a post every step."""
    out = []
    if v1 == v2:
        out += [(u1, v1 - 2, z + high - 4, u2, v1 + 2, z + high), (u1, v1 - 1, z + high // 2 - 2, u2, v1 + 1, z + high // 2)]
        n = max(1, (u2 - u1) // step)
        for k in range(n + 1):
            u = u1 + (u2 - u1 - 4) * k // n
            out.append((u, v1 - 2, z, u + 4, v1 + 2, z + high - 4))
    else:
        out += [(u1 - 2, v1, z + high - 4, u1 + 2, v2, z + high), (u1 - 1, v1, z + high // 2 - 2, u1 + 1, v2, z + high // 2)]
        n = max(1, (v2 - v1) // step)
        for k in range(n + 1):
            v = v1 + (v2 - v1 - 4) * k // n
            out.append((u1 - 2, v, z, u1 + 2, v + 4, z + high - 4))
    m.det(out, mat)


def toggle(m, a, b, u, v, z, first, second, period):
    """Two relays that take turns, as the bunker door's do: `a` is live at the start and does `first`, `b` waits and
    does `second`; each puts itself out at once and lights the other after `period` seconds. Trigger both (a button
    does): only the live one answers, so one press does the one thing and the next press the other."""
    m.relay(a, u, v, z, [(a, "Disable", "", 0)] + list(first) + [(b, "Enable", "", period)], on=True)
    m.relay(b, u, v, z + 16, [(b, "Disable", "", 0)] + list(second) + [(a, "Enable", "", period)], on=False)


def pipe_u(v, z, r, u1, u2, mat=PIPE):
    """A pipe along the canal (u1 to u2), its middle at (v, z)."""
    return prism(octagon(v, z, r), "x", u1, u2, mat, MAT["black"])


def pipe_v(u, z, r, v1, v2, mat=PIPE):
    """A pipe across the canal (v1 to v2), its middle at (u, z)."""
    return prism(octagon(u, z, r), "y", v1, v2, mat, MAT["black"])


def pipe_z(u, v, r, z1, z2, mat=PIPE):
    """A pipe standing up, its middle at (u, v)."""
    return vprism(octagon(u, v, r), z1, z2, mat)


# ---------------------------------------------------------------------------
# 1. The lock house
# ---------------------------------------------------------------------------

def m_lock(m, opt):
    """The lock house: two heavy steel gates across the canal, 704 apart, and between them a control house on a concrete
    gantry at the trim's height. Whoever holds the house cuts the canal in two.

    Each gate is a pair of steel leaves between two concrete piers that fill the banks (the gateway is 256 wide); the
    leaves slide into the piers. Shut, the canal is blocked wall to wall up to z TRIM + 16. They are drawn shut (so the
    light on them is worked out there) and the map opens both as it starts: the canal is open until somebody shuts it.
    A leaf is a func_button used as a mover (PressIn opens, PressOut shuts), exactly as the bunker's door: the
    gamemode's door rules (kicks, lockpicks) do not reach it, nothing can use or shoot it open, and it has no damage of
    its own: at 30 a second a leaf that meets somebody stops and waits.

    Inside the lock, on the left bank, a concrete pier (the bank is its ramp) and stairs up to the gantry; on the gantry
    the house: a slit each way down the canal, a button under each slit's end for the gate on that side, a desk. On the
    left wall at the gantry's end a barred street door (never opens, black behind). The right half of the gantry holds
    the hydraulic pack and cannot be reached.

    Named for the game:
      lc_lock_gate_a, lc_lock_gate_b    the gates (a: toward the module's entry). Each name is on BOTH leaves of its gate.
                                        PressOut shuts, PressIn opens (no sound that way: use the relays).
      lc_lock_a_shut, lc_lock_a_open, lc_lock_b_shut, lc_lock_b_open
                                        relays: Trigger one to shut or open a gate with its sounds, warning lamp and
                                        slam. Only the one that makes sense is live (shut while open, open while shut).
      lc_lock_button_a, lc_lock_button_b   the buttons in the house (a press triggers both of its gate's relays).
      lc_lock_house                     the middle of the control house's floor.
      lc_lock_a_move, lc_lock_a_slam, lc_lock_a_warn, lc_lock_a_shake (and _b_)   the sounds, lamp and shake of each gate.

    Unchecked: the two sounds are the bunker door's (Streetwar.d3_c17_11_garage_move1 / _stop1: the owner has heard
    them there). That a func_button leaf simply stops against a player (no damage, no reversing) is how the bunker's
    leaves behaved before their crushers were added, by its comments; not seen here. The desk and chair models are from
    the guide's list, their sizes guessed."""
    b = m.b
    L, top, deck = 1536, TRIM + 16, TRIM
    quay = MAT["quay_floor"]
    m.open(0, -256, L, 256)
    # the pier inside the lock on the left bank: the dressing gives it a 45 degree bank, which is its ramp
    m.open(448, 192, 576, 256, floor=F + 128, mat=quay)
    m.side(448, 192, 576, 256)
    m.no_bank(440, 192, 456, 256)

    gates = (("a", 384), ("b", 1152))
    for g, u0 in gates:
        mid = u0 + 32
        # the piers: they fill the banks, so the gateway is a plain rectangle
        m.no_bank(u0, 248, u0 + 64, 264)
        m.no_bank(u0, -264, u0 + 64, -248)
        m.det([(u0, 128, F, u0 + 64, 256, top), (u0, -256, F, u0 + 64, -128, top)], MAT["beam"], top=quay)
        m.det([(mid - 16, -256, top, mid + 16, 256, top + 16)], STEEL)                                        # the beam the leaves hang from
        m.det([(mid - 12, -128, F, mid + 12, 128, F + 2)], PIPE)                                              # their sill
        m.det([(mid - 14, s * 128 - (4 if s > 0 else 0), F, mid + 14, s * 128 + (0 if s > 0 else 4), top) for s in (1, -1)], PIPE)   # the slots' steel lips
        m.side(u0, -128, u0 + 64, 128)
        m.taken(u0 - 8, -256, F, u0 + 72, 256, top + 48)
        m.blocked(u0 - 32, -256, u0 + 96, -96)
        m.blocked(u0 - 32, 96, u0 + 96, 256)
        m.lane(mid, 0)
        name = "lc_lock_gate_" + g
        for side in (1, -1):
            v1, v2 = (0, 128) if side > 0 else (-128, 0)
            edge = (0, 8) if side > 0 else (-8, 0)                # the meeting edge: all that shows of an open leaf
            parts = [((mid - 8, v1, F + 2, mid + 8, v2, top), STEEL), ((mid - 12, edge[0], F + 2, mid + 12, edge[1], top), PIPE)]
            for z in (F + 32, F + 128, F + 224):
                parts.append(((mid - 12, v1, z, mid - 8, v2, z + 10), PIPE))
                parts.append(((mid + 8, v1, z, mid + 12, v2, z + 10), PIPE))
            brush(m, "func_button", {"targetname": name, "movedir": "0 %d 0" % m.fr.yaw(90 if side > 0 else 270), "speed": "30", "lip": "8", "wait": "-1", "spawnflags": "0",
                                     "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                                     "min_use_angle": "0.8", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0"},
                  parts, STEEL, vis=b.vis + ": lock gates", record=side > 0)
        # sounds, the red lamp on each pier, the shake of the slam; then the two relays that take turns
        pre = "lc_lock_%s_" % g
        sound(m, pre + "move", "Streetwar.d3_c17_11_garage_move1", mid, 0, F + 140, loops=True)
        sound(m, pre + "slam", "Streetwar.d3_c17_11_garage_stop1", mid, 0, F + 140)
        for s in (1, -1):
            m.det([(mid - 5, s * 192 - 5, top + 16, mid + 5, s * 192 + 5, top + 26)], PIPE)
            sprite(m, pre + "warn_%d" % (1 if s > 0 else 2), mid, s * 192, top + 32, "255 60 40", 0.35, on=False)
        m.point("env_shake", mid, 0, F + 140, {"targetname": pre + "shake", "amplitude": "4", "radius": "600", "duration": "1", "frequency": "40", "spawnflags": "0"})
        moving = [(pre + "warn_*", "ShowSprite", "", 0), (pre + "move", "PlaySound", "", 0.5), (pre + "move", "StopSound", "", 4.5), (pre + "slam", "PlaySound", "", 4.5),
                  (pre + "warn_*", "HideSprite", "", 5.2)]
        m.relay(pre + "shut", mid, 40, top + 40, [(pre + "shut", "Disable", "", 0), (name, "PressOut", "", 0.5), (pre + "shake", "StartShake", "", 4.5)] + moving
                + [(pre + "open", "Enable", "", 5.5)], on=True)
        m.relay(pre + "open", mid, -40, top + 40, [(pre + "open", "Disable", "", 0), (name, "PressIn", "", 0.5)] + moving + [(pre + "shut", "Enable", "", 5.5)], on=False)
    m.point("logic_auto", 768, 0, deck + 150, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_lock_gate_*", "PressIn", "", 0.5)])

    # the stairs from the pier to the gantry, on a plinth, with a handrail on the open side
    m.steps(528, 192, 256, F + 128, deck, "u", 1)
    m.det([(576, 192, F, 720, 256, F + 128)], MAT["canal_wall"])
    m.shapes([prism([(528, F + 164), (720, deck + 36), (720, deck + 40), (528, F + 168)], "y", 192, 196, PIPE)])
    m.det([(u, 192, z, u + 4, 196, z + 38) for u, z in ((528, F + 128), (620, F + 192), (716, deck))], PIPE)
    m.blocked(448, 128, 720, 256)
    m.lane(500, 224, F + 128)
    m.lane(624, 224, F + 192)

    # the gantry: a slab on two steel girders from wall to wall, corbels under their ends
    g1, g2 = 720, 912
    m.det([(g1, -256, deck - 16, g2, 256, deck)], MAT["beam"], top=quay)
    m.det([(g1 + 8, -256, deck - 48, g1 + 24, 256, deck - 16), (g2 - 24, -256, deck - 48, g2 - 8, 256, deck - 16)], STEEL)
    m.shapes([prism([(s * 256, deck - 112), (s * 256, deck - 48), (s * 192, deck - 48)], "x", u, u + 32, MAT["beam"]) for s in (1, -1) for u in (g1, g2 - 32)])
    m.taken(g1, -256, deck - 112, g2, 256, deck + 130)
    railing(m, g1 + 2, -256, g1 + 2, 192, deck)
    railing(m, g2 - 2, -256, g2 - 2, 256, deck)
    # the street door on the left wall: barred, black behind, never opens
    m.det([(784, 252, deck, 848, 256, deck + 100)], MAT["black"])
    m.det([(776, 244, deck, 784, 256, deck + 108), (848, 244, deck, 856, 256, deck + 108), (776, 244, deck + 100, 856, 256, deck + 108)], MAT["beam"])
    m.bars((784, 244, deck, 848, 252, deck + 100), "u")

    # the control house
    h1, h2, w1, w2, hz = 736, 896, -112, 112, deck + 112
    walls = []
    for u in (h1, h2 - 8):                                        # the two ends: a slit each, 32 high at eye height
        walls += [(u, w1, deck, u + 8, w2, deck + 48), (u, w1, deck + 80, u + 8, w2, hz), (u, w1, deck + 48, u + 8, -72, deck + 80), (u, 72, deck + 48, u + 8, w2, deck + 80)]
    walls += [(h1 + 8, w1, deck, h2 - 8, w1 + 8, hz)]             # the right side: blind
    walls += [(h1 + 8, w2 - 8, deck, 792, w2, hz), (840, w2 - 8, deck, h2 - 8, w2, hz), (792, w2 - 8, deck + 88, 840, w2, hz)]   # the left side: the doorway
    m.det(walls, MAT["beam"])
    m.det([(h1 - 8, w1 - 8, hz, h2 + 8, w2 + 8, hz + 8)], MM["tin"])
    m.det([(h1 + 8, w1 + 8, deck, h2 - 8, w2 - 8, deck + 1)], "tile/tilefloor018a_c17")
    for g, u, out in (("a", h1 + 8, 0), ("b", h2 - 8, 180)):
        pre = "lc_lock_%s_" % g
        m.button("lc_lock_button_" + g, u, 90, deck + 40, out, [(pre + "shut", "Trigger", "", 0), (pre + "open", "Trigger", "", 0)], wait="6")
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 816, -72, 90, z=deck + 1)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 816, -30, 270, z=deck + 1)
    m.lamp(816, 0, hz - 8, "255 214 160 50")
    m.target("lc_lock_house", 816, 30, deck + 8, 90)
    m.lane(816, 180, deck)
    m.lane(816, 40, deck)
    # the hydraulic pack on the gantry's far half, and its two pipes along the right wall to the gates
    m.det([(760, -236, deck, 872, -148, deck + 56)], STEEL)
    m.det([(772, -232, deck + 56, 800, -204, deck + 76), (832, -200, deck + 56, 860, -160, deck + 64)], PIPE)
    m.shapes([prism(octagon(-244, z, 6), "x", 448, 1152, PIPE) for z in (deck - 72, deck - 90)])
    m.taken(448, -256, deck - 100, 1152, -236, deck - 60)
    # light: one lamp on the wall over the pier, one under the gantry
    m.lamp(512, 244, F + 300, "255 220 170 120")
    m.lamp(816, 0, deck - 60, "255 220 170 90")
    m.static("models/props_c17/oildrum001.mdl", 480, 228, 0, z=F + 128)
    m.loose("models/props_junk/wood_crate001a.mdl", 980, -90, 20)
    m.view(1060, -40, F, 172, 2, "in the lock, toward gate a and the stairs")
    m.view(700, 224, deck - 24, 330, 8, "the stairs' head: the gantry and the house")
    m.view(860, 20, deck, 180, 6, "in the house: the slit toward gate a")
    m.view(250, 60, F, 0, 0, "gate a from outside")
    b.notes.append("%s: the gates are at (%d %d) and (%d %d), the gateway 256 wide; the house's floor is z %d" % ((m.tag,) + m.fr.pt(416, 0) + m.fr.pt(1184, 0) + (deck,)))


# ---------------------------------------------------------------------------
# 2. The railway bridge (experimental)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 2. The railway bridge (experimental)
# ---------------------------------------------------------------------------

def m_railbridge(m, opt):
    """EXPERIMENTAL: a railway crosses over the canal on a steel girder bridge, from a tunnel mouth in the left wall to
    one in the right. Every 150 seconds a horn sounds, a red lamp shows at each mouth, and two seconds later a Combine
    train of three box cars comes out of the left tunnel, crosses, and is gone into the right one. The bridge shakes as
    it passes. Under the bridge the canal carries on between two concrete piers; a crate or two has fallen off.
    Nobody can get onto the bridge: its bed is 240 over the canal's floor, there are no stairs, and both tunnels are
    dead ends (black at the back) long enough to hide the whole train.

    The rails' bed is at the walls' top less 144 (z 640 with the usual walls), not higher: the canal walls' concrete
    ends at the rim with the fence along it and sky above, so a tunnel mouth must end at the rim.

    How it runs (none of it could be tried here):
      lc_rail_train    one func_tracktrain: all three cars, built standing hidden in the LEFT tunnel on lc_rail_p1.
                       "origin": its middle, on lc_rail_p1 exactly. "target" lc_rail_p1. "height" 0 (its origin rides
                       on the path). "orientationtype" 0 AND spawnflag 16 (fixed orientation): a tracktrain that turns
                       to face its path takes its nose to be the side built facing east, and a module can be turned
                       four ways, so this one never turns; its path is one straight line. "startspeed" 350 (Hammer
                       calls it Max Speed: what StartForward runs at) and "speed" 350 (Initial Speed: if the game
                       starts it moving at once, it makes one run as the map starts and then waits like any other).
                       spawnflags 530 = 2 no user control + 16 fixed orientation + 512 not blockable by players.
                       "dmg" 1000: whoever is on the rails (nobody can be, short of flying) is killed, not pushed.
      lc_rail_p1 .. lc_rail_p4   path_tracks in a ring. p1: where it waits (left tunnel), spawnflag 16 "teleport to
                       THIS path track". p2: 128 on, still in the tunnel; its OnPass starts the shake. p3: in the right
                       tunnel. p4: deep in the right tunnel, the whole train hidden; its OnPass tells the train Stop,
                       and since p4's next is p1 (a teleport one) the train is put back on p1 in the same moment, unseen.
                       So it always waits at p1 (within a tenth of a second's travel of it).
      lc_rail_run      a logic_relay: horn, lamps, and StartForward two seconds later. Trigger it to send a train now.
      lc_rail_timer    a logic_timer, RefireTime 150, that triggers lc_rail_run. Disable it to stop the trains.
      lc_rail_horn, lc_rail_shake, lc_rail_signal_1, lc_rail_signal_2   the horn, the env_shake (3.5 seconds, radius
                       1000 round the bridge's middle) and the two red lamps (env_sprites: ShowSprite, HideSprite).
    In a --test file a red button on the left pier's canal face triggers lc_rail_run.
    An areaportal stands 64 inside each tunnel, walled all round; the train passes through both.

    Unchecked: everything above about func_tracktrain and path_track is from memory of Hammer's entity list (the
    keys "startspeed", "speed", "orientationtype", "height", "wheels", "bank", "dmg", "MoveSound", "volume"; the
    spawnflags; that a path_track with spawnflag 16 is teleported to; the inputs StartForward and Stop; the output
    OnPass). The sounds are from memory: ambient/alarms/train_horn2.wav, ambient/machines/razor_train_wheels_loop1.wav.
    If the train comes out sideways, the fixed orientation did not take: tell me. If it never moves, try "speed" 0."""
    b = m.b
    L, rim, c, far = 1024, b.rim, 480, 1152
    D = rim - 144                                   # the rails' bed
    wide = 96                                       # half a tunnel's width
    m.open(0, -256, L, 256)
    for s in (1, -1):
        lo, hi = (256, far) if s > 0 else (-far, -256)
        m.low(c - wide, lo, c + wide, hi, rim, floor=D, mat="nature/dirtfloor005c")
        m.side(c - wide, lo, c + wide, hi)
        m.blocked(c - wide, lo, c + wide, hi)
        m.portal(c - wide, min(s * 318, s * 320), D, c + wide, max(s * 318, s * 320), rim)
        m.det([(c - wide, min(s * far, s * (far - 8)), D, c + wide, max(s * far, s * (far - 8)), rim)], MAT["black"])
        ribs = []
        for v in (448, 704, 960):
            v1, v2 = min(s * v, s * (v + 16)), max(s * v, s * (v + 16))
            ribs += [(c - wide, v1, D, c - wide + 8, v2, rim), (c + wide - 8, v1, D, c + wide, v2, rim), (c - wide, v1, rim - 8, c + wide, v2, rim)]
        m.det(ribs, MAT["beam"])
        # the mouth: a pilaster each side from the bank to the rim, and the abutment the girders rest on
        a1, a2 = min(s * 232, s * 256), max(s * 232, s * 256)
        p1, p2 = min(s * 240, s * 256), max(s * 240, s * 256)
        m.det([(c - wide - 16, p1, F, c - wide, p2, rim), (c + wide, p1, F, c + wide + 16, p2, rim)], MAT["beam"])
        m.det([(c - 88, a1, D - 104, c + 88, a2, D - 16)], MAT["beam"])
        m.taken(c - wide - 24, a1, F, c + wide + 24, a2, rim)
        # a pier at the bank's foot
        q1, q2 = min(s * 128, s * 160), max(s * 128, s * 160)
        m.det([(c - 56, q1, F, c + 56, q2, D - 72)], MAT["canal_wall"])
        m.det([(c - 88, q1 - 12, D - 72, c + 88, q2 + 12, D - 56)], MAT["beam"])
        m.blocked(c - 96, q1 - 32, c + 96, q2 + 32)
        # the signal lamp on the mouth's pilaster
        lv = s * 236
        m.det([(c - wide - 13, min(lv, lv + s * 4), D + 64, c - wide - 3, max(lv, lv + s * 4), D + 80)], PIPE)
        sprite(m, "lc_rail_signal_%d" % (1 if s > 0 else 2), c - wide - 8, s * 230, D + 72, "255 50 30", 0.4, on=False)
    # the bridge: two plate girders with the bed between them, cross girders under it
    girders, stiff = [], []
    for s in (1, -1):
        g1, g2 = min(s * 64, s * 80), max(s * 64, s * 80)
        girders += [(c + g1, -256, D - 56, c + g2, 256, D + 32)]
        girders += [(c + g1 - 4, -256, D + 32, c + g2 + 4, 256, D + 36), (c + g1 - 4, -256, D - 60, c + g2 + 4, 256, D - 56)]
        o1, o2 = min(s * 80, s * 83), max(s * 80, s * 83)
        stiff += [(c + o1, v, D - 56, c + o2, v + 6, D + 32) for v in range(-227, 256, 64)]
    m.det(girders, STEEL)
    m.det(stiff, PIPE)
    m.det([(c - 64, -256, D - 16, c + 64, 256, D)], STEEL)
    m.det([(c - 64, v, D - 40, c + 64, v + 12, D - 16) for v in range(-200, 201, 100)], PIPE)
    m.taken(c - 90, -256, D - 64, c + 90, 256, D + 40)
    # the track: ties on the bridge and a little way in, rails the whole way (broken where the areaportals stand)
    m.det([(c - 40, v, D, c + 40, v + 12, D + 2) for v in range(-312, 304, 48) if not (-322 < v < -306 or 306 < v + 12 < 322)], MM["beam_wood"])
    rails = []
    for a, e in ((-far + 8, -320), (-318, 318), (320, far - 8)):
        rails += [(c - 30, a, D, c - 26, e, D + 6), (c + 26, a, D, c + 30, e, D + 6)]
    m.det(rails, PIPE)

    # the train, standing where it waits: the left tunnel, its middle on lc_rail_p1
    tv, base = 768, D + 6
    parts = []
    for k in range(3):
        a = tv - 352 + 240 * k
        parts.append(((c - 48, a, base + 12, c + 48, a + 224, base + 124), CMB))
        parts.append(((c - 40, a + 8, base + 4, c + 40, a + 216, base + 12), PIPE))
        for o in (20, 156):
            parts.append(((c - 36, a + o, base, c + 36, a + o + 48, base + 6), PIPE))
        for o in (52, 108, 164):
            parts.append(((c - 50, a + o, base + 12, c - 48, a + o + 8, base + 124), PIPE))
            parts.append(((c + 48, a + o, base + 12, c + 50, a + o + 8, base + 124), PIPE))
        parts.append(((c - 44, a + 4, base + 124, c + 44, a + 220, base + 128), PIPE))
        if k < 2:
            parts.append(((c - 8, a + 224, base + 14, c + 8, a + 240, base + 26), PIPE))
    brush(m, "func_tracktrain", {
        "targetname": "lc_rail_train", "target": "lc_rail_p1", "origin": "%d %d %d" % (m.fr.pt(c, tv) + (base,)), "orientationtype": "0", "velocitytype": "0",
        "startspeed": "350", "speed": "350", "height": "0", "wheels": "50", "bank": "0", "dmg": "1000", "spawnflags": "530", "volume": "10",
        "MoveSound": "ambient/machines/razor_train_wheels_loop1.wav", "MoveSoundMinPitch": "60", "MoveSoundMaxPitch": "200", "MoveSoundMinTime": "0",
        "MoveSoundMaxTime": "0", "ManualSpeedChanges": "0", "ManualAccelSpeed": "0", "ManualDecelSpeed": "0", "rendermode": "0", "renderamt": "255",
        "rendercolor": "255 255 255", "disableshadows": "1"}, parts, CMB, vis=b.vis + ": the train")
    stops = (("lc_rail_p1", tv, "lc_rail_p2", "16", None), ("lc_rail_p2", tv - 128, "lc_rail_p3", "0", [("OnPass", "lc_rail_shake", "StartShake", "", 0)]),
             ("lc_rail_p3", -(tv - 128), "lc_rail_p4", "0", None), ("lc_rail_p4", -tv, "lc_rail_p1", "0", [("OnPass", "lc_rail_train", "Stop", "", 0)]))
    for name, v, nxt, flags, wires in stops:
        m.point("path_track", c, v, base, {"targetname": name, "target": nxt, "spawnflags": flags, "orientationtype": "0", "speed": "0", "radius": "0"},
                b.vis + ": the train", connections=wires)
    sound(m, "lc_rail_horn", "ambient/alarms/train_horn2.wav", c, 320, D + 64, radius=4000)
    m.point("env_shake", c, 0, D, {"targetname": "lc_rail_shake", "amplitude": "3", "radius": "1000", "duration": "3.5", "frequency": "35", "spawnflags": "0"})
    m.relay("lc_rail_run", c, 0, D + 180, [("lc_rail_horn", "PlaySound", "", 0), ("lc_rail_signal_*", "ShowSprite", "", 0), ("lc_rail_train", "StartForward", "", 2),
                                           ("lc_rail_signal_*", "HideSprite", "", 10)])
    m.point("logic_timer", c, 0, D + 200, {"targetname": "lc_rail_timer", "RefireTime": "150", "UseRandomTime": "0", "StartDisabled": "0", "spawnflags": "0"},
            connections=[("OnTimer", "lc_rail_run", "Trigger", "", 0)])
    m.test_button((c - 8, 120, F + 40, c + 8, 128, F + 56), [("OnIn", "lc_rail_run", "Trigger")])

    # under the bridge: a lamp, and what fell off the last train
    m.lamp(c, 0, D - 52, "255 214 160 60")
    m.loose("models/props_junk/wood_crate001a.mdl", c + 70, -60, 25)
    m.loose("models/props_junk/wood_crate002a.mdl", c - 90, 40, 70)
    m.loose("models/items/item_item_crate.mdl", c + 20, 70, 10)
    m.static("models/props_debris/concrete_chunk01a.mdl", c + 130, 150, 40)
    m.lane(c, 0)
    m.view(180, -40, F, 8, -14, "the bridge from the canal")
    m.view(c + 220, -60, F, 118, -22, "the left tunnel's mouth, from below")
    m.view(c - 56, 300, D, 86, 2, "in the left tunnel: the train where it waits")
    m.view(c + 60, 40, F, 200, -30, "under the bridge")
    b.notes.append("%s: the rails are at z %d (the walls' top less 144); the train waits at (%d %d) and stops at (%d %d)" % (
        (m.tag, D + 6) + m.fr.pt(c, tv) + m.fr.pt(c, -tv)))


# ---------------------------------------------------------------------------
# 3. The pumping station
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 3. The pumping station
# ---------------------------------------------------------------------------

def m_pumphouse(m, opt):
    """The pumping station: off the left wall, through a wide doorway, a machine hall 704 by 512 and 320 high. Facing
    the door a flywheel 144 across turns slowly (lc_pump_wheel) on the shaft of a gearbox; a pump drum lies each side
    of the gearbox on concrete saddles, with suction pipes back into a turbine pit (192 square, 96 deep, ankle deep in
    water, steps down into it, a rail round it, the turbine's casing standing in it) and risers up to a header under the
    roof. The main leaves through the front wall, runs along the canal wall and crosses the canal overhead on a pipe
    bridge nobody can reach. A steel gallery runs round the hall 144 up (stairs in the corner left of the door); on it,
    over the door, the control desk: gauges, a lamp, and the button that stops and starts the pumps.

    Named for the game:
      lc_pump_wheel     the flywheel: a func_rotating (Start, Stop). It turns as the map starts. Not solid: an unseen
                        wall for players stands round it instead, so nobody is caught in it.
      lc_pump_button    the button on the desk: a press triggers both relays below; only the live one answers.
      lc_pump_stop, lc_pump_start   relays: Trigger one to stop or start the pumps (wheel, sound, the desk's lamp).
                        lc_pump_stop is live while they run, lc_pump_start while they stand.
      lc_pump_sound     the pumps' drone (a looping sound, playing from the start).
      lc_pump_down, lc_pump_up      the run-down and run-up sounds.
      lc_pump_glow      the green lamp on the desk: lit while the pumps run.
      lc_pump_hall      the hall's floor, inside the door.
    An areaportal stands in the doorway's thickness (well clear of the pit's water).

    Unchecked: func_rotating's keys from memory ("maxspeed" 40 degrees a second, "fanfriction", spawnflags 1 start on +
    16 run up and down + 64 not solid, and 4 or 8 for the axle: if the wheel tumbles instead of turning, those two are
    the other way round). Sounds from memory: ambient/machines/pump_loop_1.wav, ambient/machines/thumper_shutdown1.wav,
    ambient/machines/thumper_startup1.wav. Material metal/metalgrate013a passes the assets check; how it looks as a
    floor is not known."""
    b = m.b
    L, H, G, cx = 1280, F + 320, F + 144, 672
    grate, plaster, floor = "metal/metalgrate013a", "plaster/plasterwall042c", "concrete/concretefloor016a"
    m.open(0, -256, L, 256)
    m.low(576, 256, 768, 320, F + 144)
    m.portal(576, 287, F, 768, 289, F + 144)
    m.low(320, 320, 1024, 832, H, mat=floor)
    m.low(576, 640, 768, 832, H, floor=F - 96)
    m.water(576, 640, 768, 832, F - 96, F - 72)
    m.side(320, 256, 1024, 832)
    m.blocked(576, 640, 768, 832)
    m.blocked(448, 420, 896, 640)
    m.blocked(320, 320, 384, 544)
    # the doorway's steel frame on the canal side, and the door itself slid open along the wall inside
    m.det([(568, 248, F, 576, 256, F + 152), (768, 248, F, 776, 256, F + 152), (568, 248, F + 144, 776, 256, F + 160)], STEEL)
    m.taken(560, 232, F, 784, 256, F + 168)
    m.det([(776, 322, F, 952, 330, F + 134)], STEEL)
    m.det([(776, 330, z, 952, 333, z + 8) for z in (F + 20, F + 64, F + 108)] + [(770, 320, F + 128, 956, 334, F + 136)], PIPE)

    # the gallery: steel grating on posts, a rail on its open edge, stairs up in the corner left of the door
    m.det([(320, 768, G - 8, 1024, 832, G), (320, 536, G - 8, 384, 768, G), (960, 320, G - 8, 1024, 768, G), (384, 320, G - 8, 960, 384, G)], PIPE, top=grate)
    m.det([(u, v, F, u + 6, v + 6, G - 8) for u, v in ((384, 536), (378, 762), (540, 762), (804, 762), (954, 762), (954, 560), (954, 378), (804, 378), (540, 378), (386, 378))], PIPE)
    m.steps(320, 320, 384, F, G, "v", 1)
    m.shapes([prism([(320, F + 36), (536, G + 36), (536, G + 40), (320, F + 40)], "x", 382, 386, PIPE)])
    m.det([(382, v, z, 386, v + 4, z + 38) for v, z in ((320, F), (428, F + 72), (532, G))], PIPE)
    railing(m, 386, 770, 958, 770, G)
    railing(m, 386, 540, 386, 770, G)
    railing(m, 958, 384, 958, 770, G)
    railing(m, 388, 382, 624, 382, G)
    railing(m, 720, 382, 958, 382, G)
    railing(m, 388, 322, 388, 382, G)

    # the turbine pit: steps down along its near side, a rail round it, the turbine's casing in the water
    m.steps(784, 576, 608, F - 96, F, "v", -1)
    railing(m, 608, 638, 768, 638, F)
    railing(m, 574, 640, 574, 830, F)
    railing(m, 770, 640, 770, 830, F)
    m.shapes([vprism(octagon(cx, 736, 56), F - 96, F + 24, STEEL), pipe_z(cx, 736, 36, F + 24, F + 48, PIPE), pipe_z(cx, 736, 8, F + 48, G - 8)])
    m.light(cx, 700, F - 30, "120 200 190 35")

    # the machines: flywheel, shaft, gearbox, a pump drum each side
    wz = F + 88
    brush_shapes(m, "func_rotating", {
        "targetname": "lc_pump_wheel", "origin": "%d %d %d" % (m.fr.pt(cx, 448) + (wz,)), "spawnflags": str(1 + 16 + 64 + (4 if m.fr.ax("v") == "x" else 8)),
        "maxspeed": "40", "fanfriction": "20", "volume": "0", "dmg": "0", "solidbsp": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
        "disableshadows": "1"},
        [prism(octagon(cx, wz, 72), "y", 442, 454, STEEL), prism(octagon(cx, wz, 16), "y", 434, 462, PIPE)],
        boxes=[(cx - 4, 438, wz - 68, cx + 4, 442, wz + 68), (cx - 68, 438, wz - 4, cx + 68, 442, wz + 4), (cx + 24, 436, wz + 24, cx + 52, 442, wz + 52)], mat=PIPE,
        vis=b.vis + ": the flywheel")
    m.world((cx - 78, 430, F, cx + 78, 466, wz + 78), MAT["clip"], seals=False)
    m.det([(cx - 14, 464, F, cx + 14, 480, wz + 12)], MAT["beam"])
    m.det([(cx - 32, 512, F, cx + 32, 592, F + 120)], STEEL)
    m.det([(cx - 36, 508, F + 120, cx + 36, 596, F + 126), (cx - 40, 508, F + 126, cx + 40, 512, F + 166)], PIPE)
    shapes = [pipe_v(cx, wz, 8, 462, 512)]
    shapes += [prism(octagon(cx + d, F + 146, 10), "y", 506, 508, plaster) for d in (-24, 0, 24)]
    saddles = []
    for s in (1, -1):
        a, e = (cx + 32, cx + 200) if s > 0 else (cx - 200, cx - 32)
        shapes.append(pipe_u(552, F + 72, 48, a, e, STEEL))
        shapes += [pipe_u(552, F + 72, 52, x, x + 6, PIPE) for x in (a, e - 6)]
        saddles += [(x, 506, F, x + 24, 598, F + 36) for x in (a + 24, e - 48)]
        su, ru = cx + s * 48, cx + s * 152
        shapes += [pipe_v(su, F + 56, 12, 592, 676), pipe_z(su, 664, 12, F - 90, F + 68)]          # suction, back and down into the pit
        shapes += [pipe_z(ru, 552, 16, F + 112, F + 264), pipe_z(ru, 552, 20, F + 150, F + 158)]   # the riser, with a flange
        m.dynamic("models/props_pipes/valvewheel001.mdl", cx + s * 90, 552, 0, z=F + 120)
    shapes += [pipe_u(552, F + 264, 20, cx - 168, cx + 168), pipe_v(cx, F + 264, 24, 320, 552)]
    m.shapes(shapes)
    m.det(saddles, MAT["beam"])

    # outside: the main along the canal wall, then across on the pipe bridge
    pu, pz = 992, F + 264
    m.det([(cx - 32, 240, pz - 32, cx + 32, 256, pz + 32), (pu - 32, -256, pz - 32, pu + 32, -240, pz + 32)], STEEL)
    m.shapes([pipe_u(232, pz, 24, cx, pu + 24), pipe_v(pu, pz, 24, -256, 256)])
    m.det([(u, 224, pz - 40, u + 8, 256, pz - 24) for u in range(cx + 64, pu - 60, 96)], PIPE)
    m.det([(pu - 40, -256, pz - 48, pu - 32, 256, pz - 32), (pu + 32, -256, pz - 48, pu + 40, 256, pz - 32)], STEEL)
    m.det([(pu - 40, v, pz - 32, pu + 40, v + 6, pz - 24) for v in range(-232, 240, 96)], PIPE)
    m.taken(cx - 40, 200, pz - 56, pu + 48, 256, pz + 40)
    m.taken(pu - 48, -256, pz - 56, pu + 48, -200, pz + 40)

    # the control desk on the gallery over the door
    m.shapes([prism([(364, G), (382, G), (382, G + 52), (364, G + 44)], "x", 624, 720, STEEL)] + [prism(octagon(u, G + 34, 6), "y", 362, 364, plaster) for u in (640, 656, 688, 704)])
    m.button("lc_pump_button", cx, 364, G + 16, 270, [("lc_pump_stop", "Trigger", "", 0), ("lc_pump_start", "Trigger", "", 0)], wait="3.5")
    m.det([(cx + 36, 370, G + 50, cx + 44, 378, G + 58)], PIPE)
    sprite(m, "lc_pump_glow", cx + 40, 374, G + 62, "120 255 140", 0.2)
    sound(m, "lc_pump_sound", "ambient/machines/pump_loop_1.wav", cx, 552, F + 100, loops=True, on=True, radius=1400, volume=8)
    sound(m, "lc_pump_down", "ambient/machines/thumper_shutdown1.wav", cx, 552, F + 100, radius=1400)
    sound(m, "lc_pump_up", "ambient/machines/thumper_startup1.wav", cx, 552, F + 100, radius=1400)
    toggle(m, "lc_pump_stop", "lc_pump_start", cx, 400, G + 100,
           [("lc_pump_wheel", "Stop", "", 0), ("lc_pump_sound", "StopSound", "", 0), ("lc_pump_down", "PlaySound", "", 0), ("lc_pump_glow", "HideSprite", "", 0)],
           [("lc_pump_wheel", "Start", "", 0), ("lc_pump_up", "PlaySound", "", 0), ("lc_pump_sound", "PlaySound", "", 1), ("lc_pump_glow", "ShowSprite", "", 0)], 3)

    # light and odds and ends
    for u, v in ((480, 470), (864, 470), (480, 690), (864, 690)):
        m.lamp(u, v, H - 48, "255 226 180 65", hang=40)
    m.static("models/props_c17/lockers001a.mdl", 1012, 470, 180)
    m.static("models/props_c17/lockers001a.mdl", 1012, 522, 180)
    m.static("models/props_c17/shelfunit01a.mdl", 880, 818, 0)
    m.static("models/props_c17/oildrum001.mdl", 346, 700, 0)
    m.static("models/props_c17/oildrum001.mdl", 352, 738, 40)
    m.loose("models/props_junk/wood_crate001a.mdl", 430, 780, 15)
    m.loose("models/props_junk/metalbucket01a.mdl", 900, 610, 0)
    m.target("lc_pump_hall", cx, 400, F + 8, 90)
    m.lane(cx, 288)
    m.lane(cx, 392)
    m.lane(352, 650, G)
    m.lane(cx, 800, G)
    m.lane(992, 550, G)
    m.lane(cx - 80, 344, G)
    m.view(cx, 120, F, 90, 0, "the way in")
    m.view(cx, 340, F, 90, 0, "the hall from the door: the flywheel")
    m.view(cx - 80, 344, G, 62, 16, "from the control desk")
    m.view(440, 690, F, 345, 8, "the pit and the pumps")
    m.view(1180, -100, F, 190, -24, "the pipe bridge")
    b.notes.append("%s: the hall's floor is z %d, its gallery z %d, its roof z %d; the pit's floor z %d under %d of water" % (m.tag, F, G, H, F - 96, 24))


MODULES = {
    "lock": (1536, m_lock, "a lock house: two steel gates and the control house that works them"),
    "railbridge": (1024, m_railbridge, "a railway bridge: a Combine train crosses every few minutes (experimental)"),
    "pumphouse": (1280, m_pumphouse, "a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge"),
}
