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


MODULES = {
    "lock": (1536, m_lock, "a lock house: two steel gates and the control house that works them"),
}
