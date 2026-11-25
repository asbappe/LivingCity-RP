#!/usr/bin/env python3
"""
Living City: canal modules, set C: the Combine's and the city's machinery in the canals (things both sides fight over).

    lock         a lock house: two steel gates and the control house over the canal that works them
    railbridge   a railway over the canal: a Combine train crosses every few minutes (experimental)
    pumphouse    a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge
    thumper      a Combine thumper on a fenced terrace, with the box that stops it (experimental)
    depot        the Combine's ration depot: a roller door, a loading bay, caged stores, a staff door
    armory       a Combine armoury vault behind a door that takes two people to open
    swingbridge  a footbridge that turns on a pier in the middle of the canal (experimental)
    floodroom    a valve chamber that can be flooded and drained (experimental)

map_modules.py picks this file up by itself (docs/dev/map-modules.md). Nothing here has been compiled: each module's
docstring ends with what is from memory ("Unchecked"). Every model and material passes map_assets.py; sounds cannot
be checked. Moving things follow the bunker door's pattern where they can (a func_button as a mover, named sounds).
"""

import math

from map_build import CELL, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM, SCAPES

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


def leaning(u, v, w, z1, du, dv, z2, mat):
    """A leaning square post: its foot the square (u, v) to (u + w, v + w) at z1, its head the same square moved by
    (du, dv) at z2. The faces for m.shapes (every side stays flat)."""
    foot = [(u, v, z1), (u + w, v, z1), (u + w, v + w, z1), (u, v + w, z1)]
    head = [(a + du, c + dv, z2) for a, c, _ in foot]
    faces = [(foot, mat), (head, mat)]
    for k in range(4):
        j = (k + 1) % 4
        faces.append(([foot[k], foot[j], head[j], head[k]], mat))
    return faces


def swing_gate(m, name, boxes, hinge, mat=None, speed=90, connections=None, flags="288", wait="-1"):
    """A gate or door a player opens by Use: a func_door_rotating that swings 90 degrees round `hinge` (u, v, z) and
    stays until used again (spawnflags 32 toggle + 256 use opens; not one-way, so it swings away from whoever uses it).
    boxes: (box) or (box, material). The gamemode's door rules (locks, lockpicks, kicks) reach it, as they should.
    flags "0" and wait "4": a door no Use opens, that only an input (a button's Open) opens, and that shuts by itself."""
    brush(m, "func_door_rotating", {
        "targetname": name, "origin": "%d %d %d" % (m.fr.at(hinge[0], hinge[1], hinge[2])), "distance": "90", "speed": str(speed), "wait": wait, "lip": "0",
        "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": flags, "health": "0", "ignoredebris": "0", "loopmovesound": "0", "locked_sentence": "0",
        "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"},
          boxes, mat or PIPE, connections=connections)


def mesh_gate(m, name, a, b, z, high=96, hinge_at_a=True):
    """A chain link gate from a to b (each (u, v), in line along u or v) standing on z: a steel frame with mesh in it."""
    (u1, v1), (u2, v2) = a, b
    if v1 == v2:
        lo, hi = min(u1, u2), max(u1, u2)
        parts = [((lo, v1 - 1, z + 2, hi, v1 + 1, z + high - 2), MAT["fence"]), ((lo, v1 - 2, z + high - 6, hi, v1 + 2, z + high - 2), PIPE), ((lo, v1 - 2, z + 2, hi, v1 + 2, z + 6), PIPE),
                 ((lo, v1 - 2, z + 2, lo + 4, v1 + 2, z + high - 2), PIPE), ((hi - 4, v1 - 2, z + 2, hi, v1 + 2, z + high - 2), PIPE)]
    else:
        lo, hi = min(v1, v2), max(v1, v2)
        parts = [((u1 - 1, lo, z + 2, u1 + 1, hi, z + high - 2), MAT["fence"]), ((u1 - 2, lo, z + high - 6, u1 + 2, hi, z + high - 2), PIPE), ((u1 - 2, lo, z + 2, u1 + 2, hi, z + 6), PIPE),
                 ((u1 - 2, lo, z + 2, u1 + 2, lo + 4, z + high - 2), PIPE), ((u1 - 2, hi - 4, z + 2, u1 + 2, hi, z + high - 2), PIPE)]
    swing_gate(m, name, parts, (a if hinge_at_a else b) + (z,))


def chain_link(m, a, b, z, high=96):
    """A run of chain link fence (map_modules.chain_link, fetched when called: that file loads this one)."""
    import map_modules
    map_modules.chain_link(m, a, b, z, high)


# ---------------------------------------------------------------------------
# Real things: Half-Life 2's own models laid out (the owner, 20 November: "You use almost entirely brushes to make
# things when there are perfectly good props for doing so"). Brushes are for the buildings; a thing is a model.
# ---------------------------------------------------------------------------

def ride(m, door, model, u, v, yaw, z, angles=None):
    """The model an unseen mover wears, standing on z and riding on the entity named `door` (map_mods_b.rider, but a
    physics model is a prop_dynamic_override: as a plain prop_dynamic the game removes it). Not solid: the mover's own
    unseen brush does the blocking. angles: "pitch yaw roll" in place of the yaw alone."""
    import map_assets
    cls = "prop_dynamic_override" if map_assets.is_physics_prop(model) else "prop_dynamic"
    keys = {"parentname": door, "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
            "renderamt": "255", "rendercolor": "255 255 255"}
    if angles:
        keys["angles"] = angles
    m.prop(cls, model, u, v, yaw, z, keys)


def centred(m, model, u, v, yaw, zc):
    """A model whose origin is put at the height zc, not stood on a floor (a pipe or a wheel, placed by its middle)."""
    import map_assets
    bb = map_assets.size(model)
    m.static(model, u, v, yaw, zc + int(math.floor(bb[2])) if bb else zc)


def handrail(m, a, b, z):
    """The city's handrail (handrail04, 40 high, the town's own) along a straight line from a to b (each (u, v), along
    u or along v), standing on z: pieces of 128, then 64 and 32 for the rest. Lengths are multiples of 32."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    p = lo
    while hi - p >= 32:
        n, kind = next((n, k) for n, k in ((128, "long"), (64, "medium"), (32, "short")) if hi - p >= n)
        c = p + n // 2
        model = "models/props_c17/handrail04_%s.mdl" % kind
        m.static(model, c, v1, 90, z) if along_u else m.static(model, u1, c, 0, z)
        p += n


def handrail_line(m, p, q, z):
    """The city's handrail along any straight line from p to q (each (u, v)), standing on z: pieces of 128, 64 and 32
    (a piece may run 8 past the line's end), the run centred on the line. A slanting line takes pieces of 64 at most
    (a long piece's box, turned, reaches out a long way: the checks would read it as reaching into the walls)."""
    du, dv = q[0] - p[0], q[1] - p[1]
    n = math.hypot(du, dv)
    sizes = ((128, "long"), (64, "medium"), (32, "short")) if du == 0 or dv == 0 else ((64, "medium"), (32, "short"))
    pieces, left = [], n
    while left >= 24:
        size, kind = next(((s, k) for s, k in sizes if left >= s - 8), (32, "short"))
        pieces.append((size, kind))
        left -= size
    at = (n - sum(s for s, _ in pieces)) / 2.0
    yaw = int(round(math.degrees(math.atan2(dv, du)))) - 90
    for size, kind in pieces:
        c = (at + size / 2.0) / n
        m.static("models/props_c17/handrail04_%s.mdl" % kind, int(round(p[0] + du * c)), int(round(p[1] + dv * c)), yaw % 360, z)
        at += size


PIPE_SETS = {"02d": (512, 128, 64), "08d": (512, 256, 128, 64), "32d": (512, 256, 128)}


def pipe_run(m, a, b, zc, size="08d"):
    """A run of the city's pipes (props_pipes pipeset: "02d" a bundle of thin ones, "08d" two of 8, "32d" one of 32
    with its brackets) from a to b (each (u, v), along u or along v), its middle at height zc: pieces of 512 and down.
    Its ends must go into a wall, a floor or a machine (or be capped: pipe_cap005 fits a 32)."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    p = lo
    sizes = PIPE_SETS[size]
    while hi - p >= sizes[-1]:
        n = next(n for n in sizes if hi - p >= n)
        model = "models/props_pipes/pipeset%s_%d_001a.mdl" % (size, n)
        centred(m, model, p + n // 2, v1, 0, zc) if along_u else centred(m, model, u1, p + n // 2, 90, zc)
        p += n


def panel_fence(m, a, b, z, clip=True):
    """A fence of Nova Prospekt's chain link panels (interior_fence002: 256, 128, 64 and 32 wide, 129 high) from a to
    b (each (u, v), along u or along v), standing on z, with an unseen wall in its line (no gap at a panel's edge)."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    p = lo
    while hi - p >= 32:
        n, kind = next((n, k) for n, k in ((256, "d"), (128, "c"), (64, "b"), (32, "a")) if hi - p >= n)
        model = "models/props_wasteland/interior_fence002%s.mdl" % kind
        m.static(model, p + n // 2, v1, 90, z) if along_u else m.static(model, u1, p + n // 2, 0, z)
        p += n
    if clip:
        m.world((lo, v1 - 1, z, hi, v1 + 1, z + 128) if along_u else (u1 - 1, lo, z, u1 + 1, hi, z + 128), MAT["clip"], seals=False)


def fence_gate(m, name, u, v, z, along="u", hinge_low=True, open_frame=False):
    """Nova Prospekt's gate (interior_fence001g) hung in its frame (interior_fence002e, 64 wide) whose middle is at
    (u, v), standing on z, in a fence running `along` u or v: players open it by Use (the frame's unseen door of the
    same name turns, the model rides on it; the gamemode's door rules reach it). The owner, of the pit's: the gate
    "has to be fitted inside of the gate frames". open_frame: the frame model is not solid and an unseen clip stands
    in each of its two posts instead, so the room-to-walk check (which reads a model as its whole box) sees the way
    through it; in the game the posts stop players either way."""
    from map_mods_b import swing_door
    yaw = 90 if along == "u" else 0
    if open_frame:
        m.prop("prop_static", "models/props_wasteland/interior_fence002e.mdl", u, v, yaw, z, {"solid": "0", "disableshadows": "0", "screenspacefade": "0",
                                                                                            "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"})
        for a, c in ((-33, -24), (24, 33)):
            m.world((u + a, v - 3, z, u + c, v + 3, z + 128) if along == "u" else (u - 3, v + a, z, u + 3, v + c, z + 128), MAT["clip"], seals=False)
    else:
        m.static("models/props_wasteland/interior_fence002e.mdl", u, v, yaw, z)
    s = -1 if hinge_low else 1
    if along == "u":
        h = (u + s * 23, v, z + 54)
        box = (min(u + s * 23, u - s * 22), v - 2, z + 1, max(u + s * 23, u - s * 22), v + 2, z + 106)
    else:
        h = (u, v + s * 23, z + 54)
        box = (u - 2, min(v + s * 23, v - s * 22), z + 1, u + 2, max(v + s * 23, v - s * 22), z + 106)
    swing_door(m, name, [box], STEEL, h, speed=80, unseen=True)
    ride(m, name, "models/props_wasteland/interior_fence001g.mdl", u, v, yaw, z)


# ---------------------------------------------------------------------------
# The Combine's kit and the city's light, as the owner's map sets them (measured in c18_lc.vmf, 20 November)
# ---------------------------------------------------------------------------

SHIELD = "effects/combineshield/comshieldwall2faded"      # the field the owner's map hangs between its posts (5 of them)
WAY = {0: (1, 0), 90: (0, 1), 180: (-1, 0), 270: (0, -1)}


def combine_lamp(m, u, v, z, out, colour="147 226 240 70", name=None, spot=False):
    """The Combine's wall light (combine_light002a: 75 in the owner's map) with its back on a wall face at (u, v), its
    foot at z, its face toward `out` (a yaw in the module, 0 90 180 270); its light 18 out and 20 up, the owner's
    blue-white. name: a light the game can switch (TurnOff, TurnOn). spot: a beam down the wall instead, as theirs."""
    du, dv = WAY[out]
    m.static("models/props_combine/combine_light002a.mdl", u + 10 * du, v + 10 * dv, (out + 180) % 360, z=z)
    lu, lv = u + 28 * du, v + 28 * dv
    if name:
        named_light(m, name, lu, lv, z + 20, colour)
    elif spot:
        m.spot(lu, lv, z + 20, colour, out, pitch=50, cone=70)
    else:
        m.light(lu, lv, z + 20, colour)


def tube(m, u, v, ceil, colour="217 209 190 45", along="u", name=None):
    """A lab fluorescent tube (lab_flourescentlight002b, 64 long: 149 in the owner's map) flat under a roof at ceil, lying
    `along` u or v, and its light. Two or three light a room."""
    m.static("models/props_lab/lab_flourescentlight002b.mdl", u, v, 90 if along == "u" else 0, z=ceil - 8)
    if name:
        named_light(m, name, u, v, ceil - 24, colour)
    else:
        m.light(u, v, ceil - 24, colour)


def cage_lamp(m, u, v, z, out, colour="238 226 162 50", lit=True):
    """A caged lamp (light_cagelight02: 47 in the owner's map) with its back on a wall face at (u, v), its foot at z,
    facing `out`; lit: the _on model and its light 26 out, as theirs. Unlit: the _off model and no light (a dead lamp)."""
    du, dv = WAY[out]
    m.static("models/props_c17/light_cagelight02_%s.mdl" % ("on" if lit else "off"), u + du, v + dv, out, z=z)
    if lit:
        m.light(u + 26 * du, v + 26 * dv, z + 4, colour)


def combine_rail(m, a, b, z):
    """The Combine's railing (props_combine railing_256 and _128, 40 high) along a straight line from a to b (each
    (u, v), along u or along v), standing on z. Lengths in 128s; what is left under 128 has no piece."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    p = lo
    while hi - p >= 128:
        n = 256 if hi - p >= 256 else 128
        c = p + n // 2
        model = "models/props_combine/railing_%d.mdl" % n
        m.static(model, c, v1, 0, z) if along_u else m.static(model, u1, c, 90, z)
        p += n


def combine_field(m, a, b, z, name=None, high=180, hum=True):
    """The Combine's fence: a post at each end (combine_fence01b at a, 01a at b, their fins toward each other, 192 high,
    as the owner's map sets its twelve pairs) and the field between them, the owner's comshieldwall2faded, from post to
    post and 180 high. a and b: (u, v), in line along u or along v. name: the field is a func_brush the game can switch
    (Disable lets people through, Enable shuts it); without, it always stands (players are blocked, bullets too)."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    sgn = 1 if (u2 - u1 if along_u else v2 - v1) > 0 else -1
    yaw = (270 if sgn > 0 else 90) if along_u else (0 if sgn > 0 else 180)
    m.static("models/props_combine/combine_fence01b.mdl", u1, v1, yaw, z=z)
    m.static("models/props_combine/combine_fence01a.mdl", u2, v2, yaw, z=z)
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    box = (lo + 2, v1 - 1, z, hi - 2, v1 + 1, z + high) if along_u else (u1 - 1, lo + 2, z, u1 + 1, hi - 2, z + high)
    keys = {"Solidity": "0", "StartDisabled": "0", "solidbsp": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0",
            "spawnflags": "2", "disableshadows": "1", "vrad_brush_cast_shadows": "0"}
    if name:
        keys["targetname"] = name
    brush(m, "func_brush", keys, [box], SHIELD)
    if hum:
        mu, mv = (lo + hi) // 2, v1
        if not along_u:
            mu, mv = u1, (lo + hi) // 2
        m.sound("ambient/machines/combine_shield_loop3.wav", mu, mv, z + 80, radius=500, volume=4, name=(name + "_hum") if name else None)


def pour(m, u, v, z, length=120, colour="196 208 214", size=6, yaw=0, pitch=90):
    """Water (or slime) running out of a pipe's mouth at (u, v, z) and falling: an env_steam pointed down (pitch 90:
    straight down; less, out toward `yaw` too), as the owner's map points its jets (no falling-water material is in
    Half-Life 2's lists)."""
    m.point("env_steam", u, v, z, {"angles": "%d %d 0" % (pitch, m.fr.yaw(yaw)), "type": "0", "InitialState": "1", "spawnflags": "0", "Speed": "150", "SpreadSpeed": "5",
                                   "StartSize": str(size), "EndSize": str(size * 3), "Rate": "36", "JetLength": str(length), "rendercolor": colour,
                                   "renderamt": "150", "rollspeed": "4"})


def round_arch(m, lo, hi, spring, a, b, axis="y", mat=None, steps=5):
    """A round arch's haunches filled in under a flat roof: a passage `lo` to `hi` wide (across), its roof at
    spring + (hi - lo) / 2, the arch springing from its walls at `spring`; pushed along `axis` from a to b. Upright
    strips, each from the curve up to the roof (convex, every corner a whole number, no two in one plane overlapping)."""
    r = (hi - lo) / 2.0
    mid, top = (lo + hi) // 2, spring + (hi - lo) // 2
    out = []
    for side in (-1, 1):
        pts = []
        for k in range(steps + 1):
            t = math.radians(90.0 * k / steps)
            pts.append((int(round(mid + side * r * math.cos(t))), int(round(spring + r * math.sin(t)))))
        pts[-1] = (mid, top)
        for k in range(steps):
            (x1, z1), (x2, z2) = pts[k], pts[k + 1]
            prof = [(x1, z1), (x2, z2), (x2, top), (x1, top)] if z2 < top else [(x1, z1), (x2, top), (x1, top)]
            if side < 0:
                prof = prof[::-1]
            prof = [q for i, q in enumerate(prof) if q != prof[i - 1]]
            if len(prof) >= 3 and x1 != x2:
                out.append(prism(prof, "x" if axis == "x" else "y", a, b, mat or MAT["canal_wall"]))
    m.shapes(out)


# ---------------------------------------------------------------------------
# Helpers for the canal modules written in map_modules.py
# ---------------------------------------------------------------------------

def ring_segments(cu, cv, r_in, r_out, z1, z2, mat, n, phase=0.0, skip=(), alt=False):
    """A round wall (or ring of slab) made of n straight segments: each from the circle of r_in out past r_out, from z1
    to z2; segment k spans the angles (k + phase) * 360 / n to the next. skip: segment numbers left out (a way in). The
    faces for m.shapes (corners rounded to whole numbers, shared between neighbours: no gaps). alt: every other
    segment 1 deeper and 1 taller, so that no two neighbours' tops or bottoms lie in one plane (map_lint's flush check
    reads faces by their boxes, and two angled neighbours' boxes overlap)."""
    out_r = r_out / math.cos(math.pi / n)

    def pt(r, k):
        a = 2 * math.pi * (k + phase) / n
        return (int(round(cu + r * math.cos(a))), int(round(cv + r * math.sin(a))))
    shapes = []
    for k in range(n):
        if k in skip:
            continue
        d = 1 if alt and k % 2 else 0
        shapes.append(vprism([pt(r_in, k), pt(out_r, k), pt(out_r, k + 1), pt(r_in, k + 1)], z1 - d, z2 + d, mat))
    return shapes


def ring_rail(m, cu, cv, r, z, n, phase=0.5, skip=()):
    """The city's handrail round a circle of radius r (its middle at (cu, cv)), standing on z: n chords (pieces of 64 and
    32 along each, map_mods_c.handrail_line), chord k from the angle (k + phase) * 360 / n to the next; skip: chords left
    out (a ladder's head)."""
    for k in range(n):
        if k in skip:
            continue
        a, b = 2 * math.pi * (k + phase) / n, 2 * math.pi * (k + 1 + phase) / n
        handrail_line(m, (int(round(cu + r * math.cos(a))), int(round(cv + r * math.sin(a)))), (int(round(cu + r * math.cos(b))), int(round(cv + r * math.sin(b)))), z)


def chain(m, name, pts, slack=30, width=2):
    """A chain slung from point to point, [(u, v, z), ...] (cable/chain.vmt on a rope): both ends on something."""
    keys = {"Slack": str(slack), "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": str(width), "TextureScale": "1", "Collide": "0", "Dangling": "0",
            "Breakable": "0", "RopeMaterial": "cable/chain.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
    names = ["%s_%d" % (name, k) for k in range(len(pts))]
    for k, (u, v, z) in enumerate(pts):
        kk = dict(keys, targetname=names[k])
        if k + 1 < len(pts):
            kk["NextKey"] = names[k + 1]
        m.b.vmf.point("move_rope" if k == 0 else "keyframe_rope", m.fr.at(u, v, z), kk, m.b.vis + ": ropes")


def dustmotes(m, box, colour="217 209 170"):
    """Dust hanging in a beam of light (func_dustmotes, set as the owner's map sets its two)."""
    m.ent("func_dustmotes", {"AffectedByWind": "1", "Alpha": "110", "Color": colour, "DistMax": "1024", "Frozen": "0", "LifetimeMax": "5", "LifetimeMin": "3",
                             "SizeMax": "20", "SizeMin": "10", "SpawnRate": "40", "SpeedMax": "13", "StartDisabled": "0"}, [box], MAT["trigger"])


# The shanty town's shacks, built from pieces (the module review: "walls of mismatched sheets ... roofs of tin sloping
# and overhanging on visible posts"): every material here is one the owner's map uses.
SHEETS = ("wood/woodwall006a", "metal/metalhull010c", "wood/woodfloor006b", "metal/metalroof008a", "plaster/plasterwall046b", "wood/wooddoor042a",
          "metal/metalwall030a", "wood/woodfloor007a")
POSTS = "wood/woodfloor006b"


def shack(m, u1, v1, u2, v2, z, seed, high=112, door=56, window="boards", open_front=False, roof="metal/metalroof008a", front="lo"):
    """A shack whose front is its low-v side, standing on z: walls 6 thick, one sheet each, under a tin roof that slopes down to the front and
    overhangs it by 8; a doorway 'door' wide a third of the way along the front, and a window
    two thirds along it, 40 by 32 (window: "glass" cracked, or None; "boards" is no window now). open_front: no front wall
    (a stall). front "hi": the same shack facing the high-v side. Returns the doorway's middle (u)."""
    import random
    rnd = random.Random(seed)
    if window == "boards":      # (no boarded window any more: the hole took four brushes and the boards two; the owner, 24 November, "the little boards on the window")
        window = None
    zf, zb = z + high, z + high + 14               # the roof's line over the front and the back walls

    def top(v):
        return zf + (zb - zf) * (v - v1) // (v2 - v1)

    def sheets(a, b):
        # (one sheet a wall, flush and level: the walls were a patchwork of narrow sheets, some proud, their tops
        # uneven, four or five brushes a wall; the owner, 24 November, of the relay's shack: "tons of pointless geometry")
        return [(a, b, rnd.choice(SHEETS), 0, 0)]
    shapes, boxes = [], []
    for su in ((u1, u1 + 6), (u2 - 6, u2)):        # the side walls: sheets along v, their tops on the roof's slope
        for a, b, mat, proud, drop in sheets(v1 + 6, v2 - 6):
            o = -proud if su[0] == u1 else proud
            shapes.append(prism([(a, z), (b, z), (b, top(b) - drop), (a, top(a) - drop)], "x", su[0] + o, su[1] + o, mat))
    for a, b, mat, proud, drop in sheets(u1 + 6, u2 - 6):          # the back wall
        boxes.append(((a, v2 - 6 + proud, z, b, v2 + proud, zb - drop), mat))
    dm = u1 + (u2 - u1) // 3
    wm = u1 + 2 * (u2 - u1) // 3
    if not open_front:
        for a, b, mat, proud, drop in sheets(u1 + 6, u2 - 6):      # the front wall, a doorway and a window cut from its sheets
            t = zf - drop
            for c, d in ((a, min(b, dm - door // 2)), (max(a, dm + door // 2), b)):
                if d - c < 4:
                    continue
                if window and c < wm + 20 and d > wm - 20:       # (the window's hole)
                    if wm - 20 - c >= 4:
                        boxes.append(((c, v1 - proud, z, wm - 20, v1 + 6 - proud, t), mat))
                    if d - (wm + 20) >= 4:
                        boxes.append(((wm + 20, v1 - proud, z, d, v1 + 6 - proud, t), mat))
                    lo, hi = max(c, wm - 20), min(d, wm + 20)
                    boxes += [((lo, v1 - proud, z, hi, v1 + 6 - proud, z + 48), mat), ((lo, v1 - proud, z + 80, hi, v1 + 6 - proud, t), mat)]
                else:
                    boxes.append(((c, v1 - proud, z, d, v1 + 6 - proud, t), mat))
        boxes.append(((dm - door // 2, v1, z + 88, dm + door // 2, v1 + 6, zf), rnd.choice(SHEETS)))       # over the doorway
        if window == "boards":
            boxes += [((wm - 24, v1 - 3, z + 54, wm + 24, v1 - 1, z + 60), "wood/woodfloor006b"), ((wm - 22, v1 - 3, z + 68, wm + 22, v1 - 1, z + 73), "wood/woodwall006a")]
        elif window == "glass":
            boxes.append(((wm - 20, v1 + 2, z + 48, wm + 20, v1 + 3, z + 80), "glass/glasswindowbreak070a"))
    # (no corner posts and no posts under the overhang: the owner, 24 November, "supports for porch, etc"; the roof overhangs 8, which needs none)
    # the roof: one sheet of tin, sloping to the front, overhanging 8 there and 12 at the sides
    rf, rb = v1 - 8, v2 + 8
    zr1 = zf - (zb - zf) * 8 // (v2 - v1) - 1
    zr2 = zb + (zb - zf) * 8 // (v2 - v1) + 1
    shapes.append(prism([(rf, zr1), (rb, zr2), (rb, zr2 + 3), (rf, zr1 + 3)], "x", u1 - 12, u2 + 12, roof))
    if front == "hi":          # (built facing low v, then turned over onto the high-v side: v becomes v1 + v2 - v)
        boxes = [((b[0], v1 + v2 - b[4], b[2], b[3], v1 + v2 - b[1], b[5]), mat) for b, mat in boxes]
        flipped = []
        for faces in shapes:
            flipped.append([([(p[0], v1 + v2 - p[1], p[2]) for p in pts[::-1]], mat) for pts, mat in faces])
        shapes = flipped
    for (bx, mat) in boxes:
        m.det([bx], mat)
    m.shapes(shapes)
    if front == "hi":
        m.blocked(u1 - 16, v1 - 16, u2 + 16, v2 + 28)
        m.taken(u1 - 12, v1 - 12, z, u2 + 12, v2 + 28, zr2 + 4)
    else:
        m.blocked(u1 - 16, v1 - 28, u2 + 16, v2 + 16)
        m.taken(u1 - 12, v1 - 28, z, u2 + 12, v2 + 12, zr2 + 4)
    return dm


# ---------------------------------------------------------------------------
# 1. The lock house
# ---------------------------------------------------------------------------

def m_lock(m, opt):
    """The lock house: two lock gates across the canal, 704 apart, and between them a control house on a concrete
    gantry at the trim's height. Whoever holds the house cuts the canal in two.

    Each gate is Half-Life 2's own pair of canal lock leaves (props_canal locks_small and locks_small_b, side by side)
    between two concrete piers that fill the banks (the gateway is 256 wide). The pair rides on one unseen leaf that
    slides sideways into the left pier and the wall behind it. Shut, the canal is blocked wall to wall up to z F + 296.
    They are drawn shut (so the light on them is worked out there) and the map opens both as it starts: the canal is
    open until somebody shuts it. The leaf is a func_button used as a mover (PressIn opens, PressOut shuts), exactly as
    the bunker's door: the gamemode's door rules (kicks, lockpicks) do not reach it, nothing can use or shoot it open,
    and it has no damage of its own: a leaf that meets somebody stops and waits. A Combine lamp on each pier's beam
    shows red while a gate moves, and on each pier's outer face a railway signal head shows red with it (Half-Life 2's
    light_signal002a); a klaxon sounds while a gate moves. The lock chamber says what it is: a dark tide line along its
    walls, depth numbers up the piers' faces.

    Inside the lock, on the left bank, the way up to the gantry: from the canal floor a flight of 8 along the bank
    toward gate a (an upstand on its open side) onto a landing against gate a's pier, the concrete pier beside it (an
    oil drum on it), and from the pier a flight of 8 up along the wall behind a concrete parapet; on the gantry, behind
    the city's handrail, the house (its doorway 64 wide and 104 high), concrete with steel
    plate to the waist inside: a slit each way down the canal, a button under each slit's end for the gate on that side
    with a lever panel beside it and two lamps over it (green while that gate is open, red while it is shut), the
    canals' own map on the wall, switch boxes, a desk with a monitor and a chair, a fluorescent tube. On the left wall at
    the gantry's end a street doorway that is never used: planked over, boards nailed across; where the chain's street
    runs along the left bank (the canal ring, 23 November) there is no doorway: the gantry is at the street's height and
    meets it, the street's parapet open from the upper flight's head across the gantry. The right half of the gantry
    holds the hydraulic pack (a pipe cluster and a generator) and cannot be reached; its two pipes run under the
    gantry along the right wall to the gates.

    Named for the game:
      lc_lock_gate_a, lc_lock_gate_b    the gates (a: toward the module's entry), one unseen leaf each with both
                                        leaf models riding on it. PressOut shuts, PressIn opens (no sound that way:
                                        use the relays).
      lc_lock_a_shut, lc_lock_a_open, lc_lock_b_shut, lc_lock_b_open
                                        relays: Trigger one to shut or open a gate with its sounds, warning lamp and
                                        slam. Only the one that makes sense is live (shut while open, open while shut).
      lc_lock_button_a, lc_lock_button_b   the buttons in the house (a press triggers both of its gate's relays).
      lc_lock_house                     the middle of the control house's floor.
      lc_lock_a_move, lc_lock_a_slam, lc_lock_a_warn, lc_lock_a_shake, lc_lock_a_klaxon (and _b_)   the sounds, lamps
                                        and shake of each gate.
      lc_lock_a_lamp_open, lc_lock_a_lamp_shut (and _b_)   the house's lamps for each gate (ShowSprite, HideSprite).

    Left as brushes: the piers, the beams, sills and slot lips, the gantry, its girders and corbels, the stairs and
    their parapet, the house's walls, steel lining and roof, the street doorway's frame and planking (all of them the
    building).

    Unchecked: the two sounds are the bunker door's (Streetwar.d3_c17_11_garage_move1 / _stop1: the owner has heard
    them there). That a func_button leaf simply stops against a player (no damage, no reversing) is how the bunker's
    leaves behaved before their crushers were added, by its comments; not seen here. How locks_small looks from each
    face (it is the canals' own lock leaf, 65 thick, 163 wide, 291 high: its sizes are read, its faces are not); that
    locks_small_b is its mirror. That a prop rides on a func_button by parentname (it does on doors).
    ambient/alarms/apc_alarm_loop1.wav; which way the lever panel, its handle, the signal heads and the map face."""
    b = m.b
    L, top, deck = 1536, F + 296, TRIM
    quay = MAT["quay_floor"]
    m.open(0, -256, L, 256)
    # the pier inside the lock on the left bank, the landing between the two flights up to the gantry (no bank against
    # it: the lower flight stands there)
    m.open(448, 192, 576, 256, floor=F + 128, mat=quay)
    m.side(448, 192, 576, 256)
    m.no_bank(440, 184, 736, 264)

    gates = (("a", 384), ("b", 1152))
    for g, u0 in gates:
        mid = u0 + 32
        # the piers: they fill the banks, so the gateway is a plain rectangle; 76 thick, so the leaves (65) slide into them
        m.no_bank(u0, 248, u0 + 64, 264)
        m.no_bank(u0, -264, u0 + 64, -248)
        m.det([(mid - 38, 128, F, mid + 38, 256, top), (mid - 38, -256, F, mid + 38, -128, top)], MAT["beam"], top=quay)
        m.det([(mid - 16, -256, top, mid + 16, 256, top + 16)], STEEL)                                        # the beam over the gateway
        m.det([(mid - 36, -128, F, mid + 36, 128, F + 2)], PIPE)                                              # the sill
        m.det([(mid + e, s * 128 - (4 if s > 0 else 0), F, mid + e + 5, s * 128 + (0 if s > 0 else 4), top)
               for s in (1, -1) for e in (-38, 33)], PIPE)                                                    # the slots' steel lips, each side of the leaf
        m.side(u0, -128, u0 + 64, 128)
        m.taken(u0 - 8, -256, F, u0 + 72, 256, top + 48)
        m.blocked(u0 - 32, -256, u0 + 96, -96)
        m.blocked(u0 - 32, 96, u0 + 96, 256)
        m.lane(mid, 0)
        name = "lc_lock_gate_" + g
        # the leaf: unseen, as wide as the two models (they reach 34 into the piers), sliding into the left pier: open,
        # its edge stands 8 out of the pier's face, as the old leaves' did
        brush(m, "func_button", {"targetname": name, "movedir": "0 %d 0" % m.fr.yaw(90), "speed": "70", "lip": "45", "wait": "-1", "spawnflags": "0",
                                 "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                                 "min_use_angle": "0.8", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "disablereceiveshadows": "0"},
              [(mid - 30, -162, F + 2, mid + 30, 163, top)], MAT["nodraw"], vis=b.vis + ": lock gates")
        ride(m, name, "models/props_canal/locks_small.mdl", mid, 81, 0, F + 2)
        ride(m, name, "models/props_canal/locks_small_b.mdl", mid, -81, 0, F + 2)
        # sounds, the red lamp on each pier's end of the beam, the shake of the slam; then the two relays that take turns
        pre = "lc_lock_%s_" % g
        sound(m, pre + "move", "Streetwar.d3_c17_11_garage_move1", mid, 0, F + 140, loops=True)
        sound(m, pre + "slam", "Streetwar.d3_c17_11_garage_stop1", mid, 0, F + 140)
        out = -1 if g == "a" else 1                                                                           # (the pier's face away from the lock)
        for s in (1, -1):
            m.static("models/props_combine/combine_light002a.mdl", mid, s * 192, 180 if g == "a" else 0, z=top + 16)
            sprite(m, pre + "warn_%d" % (1 if s > 0 else 2), mid + (-12 if g == "a" else 12), s * 192, top + 50, "255 60 40", 0.35, on=False)
            m.static("models/props_trainstation/light_signal002a.mdl", mid + out * 62, s * 196, 180 if g == "a" else 0, z=F + 170)     # the boats' signal
            sprite(m, pre + "warn_%d" % (3 if s > 0 else 4), mid + out * 88, s * 196, F + 250, "255 50 30", 0.3, on=False)
            for k, z in enumerate((F + 40, F + 110, F + 180)):                                              # depth numbers up the pier's face in the lock
                m.grime("number", mid - out * 38, s * 200, z, k + (3 if s > 0 else 7))
        m.point("env_shake", mid, 0, F + 140, {"targetname": pre + "shake", "amplitude": "4", "radius": "600", "duration": "1", "frequency": "40", "spawnflags": "0"})
        sound(m, pre + "klaxon", "ambient/alarms/apc_alarm_loop1.wav", mid, 0, top - 20, loops=True, radius=1400, volume=6)
        moving = [(pre + "warn_*", "ShowSprite", "", 0), (pre + "klaxon", "PlaySound", "", 0), (pre + "move", "PlaySound", "", 0.5), (pre + "move", "StopSound", "", 4.5),
                  (pre + "slam", "PlaySound", "", 4.5), (pre + "klaxon", "StopSound", "", 4.6), (pre + "warn_*", "HideSprite", "", 5.2)]
        m.relay(pre + "shut", mid, 40, top + 40, [(pre + "shut", "Disable", "", 0), (name, "PressOut", "", 0.5), (pre + "shake", "StartShake", "", 4.5),
                                                  (pre + "lamp_open", "HideSprite", "", 0), (pre + "lamp_shut", "ShowSprite", "", 4.5)] + moving
                + [(pre + "open", "Enable", "", 5.5)], on=True)
        m.relay(pre + "open", mid, -40, top + 40, [(pre + "open", "Disable", "", 0), (name, "PressIn", "", 0.5), (pre + "lamp_shut", "HideSprite", "", 0),
                                                   (pre + "lamp_open", "ShowSprite", "", 4.5)] + moving + [(pre + "shut", "Enable", "", 5.5)], on=False)
    m.point("logic_auto", 768, 0, deck + 150, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_lock_gate_*", "PressIn", "", 0.5)])

    # the way up to the gantry (the owner, 22 November: the check found the house could not be walked to): from the
    # canal floor a flight of 8 along the pier's face toward gate a, an upstand on its open side, onto a landing against
    # gate a's pier that joins the pier; then the flight of 8 from the pier up along the wall, on a plinth, a concrete
    # parapet between it and the flight below
    m.steps(704, 128, 192, F, F + 128, "u", -1)
    m.stair_side(704, 192, 122, 128, F, F + 128, -1)
    m.det([(454, 128, F, 512, 192, F + 128)], MAT["canal_wall"], top=quay)
    m.det([(454, 122, F, 512, 128, F + 160)], MAT["beam"])
    m.steps(528, 192, 256, F + 128, deck, "u", 1)
    m.det([(576, 192, F, 720, 256, F + 128)], MAT["canal_wall"])
    m.shapes([prism([(527, F + 128), (527, F + 164), (720, deck + 36), (720, deck)], "y", 190, 196, MAT["beam"])])    # (2 proud of the steps' side)
    m.blocked(448, 120, 720, 256)
    m.lane(740, 160)
    m.lane(600, 160, F + 64)
    m.lane(496, 192, F + 128)
    m.lane(624, 224, F + 192)

    # the gantry: a slab on two steel girders from wall to wall, corbels under their ends
    g1, g2 = 720, 912
    m.det([(g1, -256, deck - 16, g2, 256, deck)], MAT["beam"], top=quay)
    m.det([(g1 + 8, -256, deck - 48, g1 + 24, 256, deck - 16), (g2 - 24, -256, deck - 48, g2 - 8, 256, deck - 16)], STEEL)
    m.shapes([prism([(s * 256, deck - 112), (s * 256, deck - 48), (s * 192, deck - 48)], "x", u, u + 32, MAT["beam"]) for s in (1, -1) for u in (g1, g2 - 32)])
    m.taken(g1, -256, deck - 112, g2, 256, deck + 130)
    handrail(m, (g1 + 2, -256), (g1 + 2, 192), deck)
    handrail(m, (g2 - 2, -256), (g2 - 2, 256), deck)
    if m.street_side() == 1:
        # the chain's street runs along the left bank at the gantry's own height: the gantry meets it (the street's
        # parapet opens from the upper flight's head across the gantry), so whoever holds the house comes off the street
        b.edge_gaps.append(m.fr.rect(704, 236, 896, 284))
        m.lane(800, 288, deck)
    else:
        # the street doorway on the left wall, never used: planked over, boards nailed across (never a door that looks
        # openable where nobody can go: the owner, 20 November)
        from map_town import board
        m.det([(785, 252, deck, 847, 256, deck + 112)], "wood/woodwall006a")
        m.det([(777, 239, deck, 785, 256, deck + 112), (847, 239, deck, 855, 256, deck + 112), (777, 239, deck + 112, 855, 256, deck + 120)], MAT["beam"])   # (1 proud of the trim)
        for z, roll in ((deck + 36, 80), (deck + 76, 101)):
            board(m, 816, 248, z, 270, roll)

    # the control house
    h1, h2, w1, w2, hz = 736, 896, -112, 112, deck + 112
    walls = []
    for u in (h1, h2 - 8):                                        # the two ends: a slit each, 32 high at eye height
        walls += [(u, w1, deck, u + 8, w2, deck + 48), (u, w1, deck + 80, u + 8, w2, hz), (u, w1, deck + 48, u + 8, -72, deck + 80), (u, 72, deck + 48, u + 8, w2, deck + 80)]
    walls += [(h1 + 8, w1, deck, h2 - 8, w1 + 8, hz)]             # the right side: blind
    walls += [(h1 + 8, w2 - 8, deck, 784, w2, hz), (848, w2 - 8, deck, h2 - 8, w2, hz), (784, w2 - 8, deck + 104, 848, w2, hz)]   # the left side: the doorway, 64 wide and 104 high
    m.det(walls, MAT["beam"])
    m.det([(h1 - 8, w1 - 8, hz, h2 + 8, w2 + 8, hz + 8)], "metal/metalroof008a")
    m.det([(h1 + 8, w1 + 8, deck, h2 - 8, w2 - 8, deck + 1)], "metal/metalfloor005a")
    plate = "metal/metalwall030a"                                 # steel to the waist inside (the ends 1 lower than the sides: no shared tops)
    m.det([(h1 + 8, w1 + 12, deck + 1, h1 + 12, w2 - 12, deck + 44), (h2 - 12, w1 + 12, deck + 1, h2 - 8, w2 - 12, deck + 44)], plate)
    m.det([(h1 + 8, w1 + 8, deck + 1, h2 - 8, w1 + 12, deck + 45), (h1 + 8, w2 - 12, deck + 1, 784, w2 - 8, deck + 45), (848, w2 - 12, deck + 1, h2 - 8, w2 - 8, deck + 45)], plate)
    m.static("models/props_canal/canalmap001.mdl", 780, w1 + 12, 270, z=deck + 48)               # the canals' own map, on the blind wall
    m.static("models/props_lab/powerbox01a.mdl", 860, w1 + 26, 90, z=deck + 56)
    m.static("models/props_lab/powerbox02b.mdl", 840, w1 + 19, 90, z=deck + 70)
    for g, u, out in (("a", h1 + 8, 0), ("b", h2 - 8, 180)):
        pre = "lc_lock_%s_" % g
        m.button("lc_lock_button_" + g, u, 90, deck + 40, out, [(pre + "shut", "Trigger", "", 0), (pre + "open", "Trigger", "", 0)], wait="6")
        du = 1 if out == 0 else -1
        m.static("models/props_wasteland/panel_leverbase001a.mdl", u + du * 5, 44, (out + 180) % 360, z=deck + 30)    # a lever panel beside it
        m.static("models/props_wasteland/panel_leverhandle001a.mdl", u + du * 10, 44, (out + 180) % 360, z=deck + 42)
        m.static("models/props_lab/powerbox02a.mdl", u + du * 10, 90, out, z=deck + 74)               # the gate's two lamps over it
        sprite(m, pre + "lamp_open", u + du * 18, 82, deck + 92, "60 255 80", 0.12, on=True)
        sprite(m, pre + "lamp_shut", u + du * 18, 98, deck + 92, "255 50 30", 0.12, on=False)
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 816, -78, 90, z=deck + 1)
    m.static("models/props_wasteland/controlroom_monitor001a.mdl", 800, -86, 90, z=deck + 35)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 816, -34, 270, z=deck + 1)
    tube(m, 816, 0, hz, "217 209 190 55", along="u")
    m.target("lc_lock_house", 816, 30, deck + 8, 90)
    m.lane(816, 180, deck)
    m.lane(816, 40, deck)
    # the hydraulic pack on the gantry's far half: a pipe cluster against the right wall and the generator that drives
    # it; its two pipes along the right wall under the gantry, into the piers that hold the gates
    m.static("models/props_wasteland/pipecluster001a.mdl", 816, -236, 90, z=deck)
    m.static("models/props_vehicles/generatortrailer01.mdl", 816, -168, 0, z=deck)
    pipe_run(m, (448, -250), (1152, -250), deck - 80, "08d")
    m.taken(448, -256, deck - 100, 1152, -236, deck - 60)
    # light: a caged lamp on the wall over the pier, a dome light under the gantry's slab
    m.lamp(816, 0, deck - 24, "255 220 170 90")
    lz = F + 200 if m.street_side() == 1 else F + 250      # (beside a street the wall ends at its height: the lamp under it)
    m.static("models/props_c17/light_cagelight02_on.mdl", 512, 255, 270, z=lz)
    m.light(512, 240, lz + 6, "255 220 170 120")
    m.static("models/props_c17/oildrum001.mdl", 464, 240, 0, z=F + 128)
    m.loose("models/props_junk/wood_crate001a.mdl", 980, -90, 20)
    for k, u in enumerate((480, 600, 1000, 1100)):                 # the tide line: dark stains along both walls, over the banks
        m.grime("stain", u, 256, F + 160, 30 + k)
        m.grime("stain", u + 60, -256, F + 150, 40 + k)
    m.soundscape(SCAPES["pump"], 816, 0, deck, radius=200)
    m.soundscape(SCAPES["watery"], 768, 0, F, radius=800)
    m.view(1060, -40, F, 172, 2, "in the lock, toward gate a and the stairs")
    m.view(700, 224, deck - 24, 330, 8, "the stairs' head: the gantry and the house")
    m.view(860, 20, deck, 180, 6, "in the house: the slit toward gate a")
    m.view(120, 60, F, 0, -4, "gate a from outside")
    b.notes.append("%s: the gates are at (%d %d) and (%d %d), the gateway 256 wide; the house's floor is z %d" % ((m.tag,) + m.fr.pt(416, 0) + m.fr.at(1184, 0, deck)))


# ---------------------------------------------------------------------------
# 2. The railway bridge (experimental)
# ---------------------------------------------------------------------------

def m_railbridge(m, opt):
    """EXPERIMENTAL: a railway crosses over the canal on a steel girder bridge, from a tunnel mouth in the left wall to
    one in the right. Every 150 seconds a horn sounds, a red lamp shows at each mouth, and two seconds later a freight
    train of two flat cars (Half-Life 2's train005, one loaded with steel beams, one with crates) comes out of the left
    tunnel, crosses, and is gone into the right one. The bridge shakes as it passes. Under the bridge the canal carries
    on between two concrete piers; a crate or two has fallen off. Nobody can get onto the bridge: its bed is 240 over
    the canal's floor, there are no stairs, and both tunnels are dead ends (black at the back) 1024 deep, long enough
    to hide the whole train. Each mouth has a face: concrete pilasters, the abutment, a number and a danger sign, and
    beside it on the wall one of Half-Life 2's railway signal heads (light_signal002a) that shows red while a train
    comes. The track is seen whole: ballast on the bed, sleepers, rails running into both tunnels, and an overhead wire
    on three posts from tunnel to tunnel. When the train crosses, dust and grit fall from under the bridge. Under it,
    caged lamps on the piers (one dead), graffiti, crates fallen off the last train and broken, and the body of someone
    who stood on the line.

    The rails' bed is at the walls' top less 144 (z 640 with the usual walls), not higher: the canal walls' concrete
    ends at the rim with the fence along it and sky above, so a tunnel mouth must end at the rim.

    How it runs (none of it could be tried here):
      lc_rail_train    one func_tracktrain: an unseen block as big as the train, built standing hidden in the LEFT
                       tunnel on lc_rail_p1; the two car models and their loads ride on it (parentname).
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
      lc_rail_dust_1 .. _3   the dust off the bridge's underside (env_dustpuff: SpawnDust), sent by lc_rail_p2.
    In a --test file a red button on the left pier's canal face triggers lc_rail_run.
    An areaportal stands 64 inside each tunnel, walled all round; the train passes through both.

    Left as brushes: the tunnels, the bridge (girders, bed, cross girders, abutments, piers), the overhead wire's posts
    and the track: the only track models (traintrack001c, 006b, 006c) are 288 wide and more, too wide for the 128 bed.

    Unchecked: everything above about func_tracktrain and path_track is from memory of Hammer's entity list (the
    keys "startspeed", "speed", "orientationtype", "height", "wheels", "bank", "dmg", "MoveSound", "volume"; the
    spawnflags; that a path_track with spawnflag 16 is teleported to; the inputs StartForward and Stop; the output
    OnPass). The sounds are from memory: ambient/alarms/train_horn2.wav, ambient/machines/razor_train_wheels_loop1.wav.
    If the train comes out sideways, the fixed orientation did not take: tell me. If it never moves, try "speed" 0.
    env_dustpuff's keys; which way the signal heads face (taken as the model's +x).
    That train005 is a flat car (its size is read: 118 wide, 460 long, 54 high; its look is not), and which of its
    ends is its front (it is the same both ways round in its size)."""
    b = m.b
    L, rim, c = 1024, b.rim, 480
    D = rim - 144                                   # the rails' bed
    wide = 96                                       # half a tunnel's width
    import map_corridor
    street = m.street_side()
    # where each tunnel's mouth is: in the canal's wall, or on a street's bank behind the street (an overpass carries
    # the line over the road and tracks: the owner, 22 November, "cant you just make an overpass?")
    T0 = {s: (map_corridor.front_line(b) if s == street else 256) for s in (1, -1)}
    FAR = {s: T0[s] + 1024 for s in (1, -1)}
    m.open(0, -256, L, 256)
    from map_mods_c import cage_lamp
    for s in (1, -1):
        t0, far = T0[s], FAR[s]
        lo, hi = (t0, far) if s > 0 else (-far, -t0)
        m.low(c - wide, lo, c + wide, hi, rim, floor=D, mat="nature/dirtfloor005c")
        m.side(c - wide, lo, c + wide, hi)
        m.blocked(c - wide, lo, c + wide, hi)
        m.portal(c - wide, min(s * (t0 + 62), s * (t0 + 64)), D, c + wide, max(s * (t0 + 62), s * (t0 + 64)), rim)
        m.det([(c - wide, min(s * far, s * (far - 8)), D, c + wide, max(s * far, s * (far - 8)), rim)], MAT["black"])
        ribs = []
        for v in (t0 + 192, t0 + 448, t0 + 704, t0 + 960):
            v1, v2 = min(s * v, s * (v + 16)), max(s * v, s * (v + 16))
            ribs += [(c - wide, v1, D, c - wide + 8, v2, rim - 8), (c + wide - 8, v1, D, c + wide, v2, rim - 8), (c - wide, v1, rim - 8, c + wide, v2, rim)]
        m.det(ribs, MAT["beam"])
        # the mouth: a pilaster each side from the bank (or the street) to the rim, and the abutment the girders rest on
        foot = map_corridor.STREET if s == street else F
        a1, a2 = min(s * (t0 - 24), s * t0), max(s * (t0 - 24), s * t0)
        p1, p2 = min(s * (t0 - 18), s * t0), max(s * (t0 - 18), s * t0)             # (2 proud of the wall and 2 into the mouth: the trim's ends hide in them)
        m.det([(c - wide - 16, p1, foot, c - wide + 2, p2, rim), (c + wide - 2, p1, foot, c + wide + 16, p2, rim)], MAT["beam"])
        m.det([(c - 88, a1, D - 104, c + 88, a2, D - 16)], MAT["beam"])
        m.taken(c - wide - 24, a1, foot, c + wide + 24, a2, rim)
        if s == street:
            # over the street: a pier at the canal's edge (behind the parapet), one on the kerb between the tracks and the
            # road, each with a cap under the girders; the walk along the canal's edge passes behind the first
            for e1, e2 in ((256, 276), (map_corridor.ROAD_IN + 8, map_corridor.ROAD_OUT - 8)):
                q1, q2 = min(s * e1, s * e2), max(s * e1, s * e2)
                m.det([(c - 56, q1, foot, c + 56, q2, D - 72)], MAT["canal_wall"])
                m.det([(c - 88, q1 - (4 if s < 0 else 0), D - 72, c + 88, q2 + (4 if s > 0 else 0), D - 56)], MAT["beam"])
        # a pier at the bank's foot
        q1, q2 = min(s * 128, s * 160), max(s * 128, s * 160)
        m.det([(c - 56, q1, F, c + 56, q2, D - 72)], MAT["canal_wall"])
        m.det([(c - 88, q1 - 12, D - 72, c + 88, q2 + 12, D - 56)], MAT["beam"])
        m.blocked(c - 96, q1 - 32, c + 96, q2 + 32)
        # the signal beside the mouth on the wall: a railway signal head, its red glow in front of it; the mouth's marks
        m.static("models/props_trainstation/light_signal002a.mdl", c - wide - 80, s * (t0 - 42), 270 if s > 0 else 90, z=D - 20)
        sprite(m, "lc_rail_signal_%d" % (1 if s > 0 else 2), c - wide - 80, s * (t0 - 88), D + 60, "255 50 30", 0.4, on=False)
        m.taken(c - wide - 130, a1, D - 30, c - wide - 30, a2, D + 110)
        m.grime("number", c + wide + 60, s * t0, D + 60, 1 if s > 0 else 2)
        m.grime("danger", c + wide + 60, s * t0, D - 40, 3 if s > 0 else 4)
        m.grime("graffiti", c, s * 128, F + 100, 5 if s > 0 else 6)                     # (on the pier's face)
        cage_lamp(m, c, s * 128, F + 160, 270 if s > 0 else 90, "255 214 160 50", lit=s > 0)
    # the bridge: two plate girders with the bed between them, cross girders under it
    girders, stiff = [], []
    vl, vh = -T0[-1], T0[1]                          # (the girders run from mouth to mouth: over the canal, and over a street)
    for s in (1, -1):
        g1, g2 = min(s * 64, s * 80), max(s * 64, s * 80)
        girders += [(c + g1, vl, D - 56, c + g2, vh, D + 32)]
        girders += [(c + g1 - 4, vl, D + 32, c + g2 + 4, vh, D + 36), (c + g1 - 4, vl, D - 60, c + g2 + 4, vh, D - 56)]
        o1, o2 = min(s * 80, s * 83), max(s * 80, s * 83)
        stiff += [(c + o1, v, D - 56, c + o2, v + 6, D + 32) for v in range(vl + 29, vh, 64)]
    m.det(girders, STEEL)
    m.det(stiff, PIPE)
    m.det([(c - 64, vl, D - 16, c + 64, vh, D)], STEEL)
    m.det([(c - 64, v, D - 40, c + 64, v + 12, D - 16) for v in range(vl + 56, vh - 55, 100)], PIPE)
    m.taken(c - 90, -256, D - 64, c + 90, 256, D + 40)
    # the track: ballast on the bed, ties on the bridge and a little way in, rails the whole way (broken where the
    # areaportals stand), an overhead wire on three posts from tunnel to tunnel
    m.det([(c - 52, vl, D, c + 52, vh, D + 1)], MM["gravel"])
    pa, pb = -(T0[-1] + 62), T0[1] + 62                # (the areaportals: no tie or rail through them)
    m.det([(c - 40, v, D, c + 40, v + 12, D + 2) for v in range(pa + 6, pb - 8, 48) if not (pa - 4 < v < pa + 12 or pb - 16 < v + 12 < pb + 4)], "wood/woodfloor006b")
    posts = []
    for v in [-176, 0, 176] + [s * (T0[s] - 256) // 2 + s * 256 for s in (1, -1) if T0[s] > 256]:
        posts += [(c + 70, v - 2, D + 36, c + 74, v + 2, D + 134), (c + 2, v - 2, D + 130, c + 70, v + 2, D + 134)]
    m.det(posts, PIPE)
    wire = [(c, -(T0[-1] + 204), D + 126)] + [(c, v, D + 128) for v in sorted([-176, 0, 176] + [s * (T0[s] - 256) // 2 + s * 256 for s in (1, -1) if T0[s] > 256])] + [(c, T0[1] + 204, D + 126)]
    m.rope(wire, slack=6, width=1)
    rails = []
    for a, e in ((-FAR[-1] + 8, pa - 2), (pa, pb), (pb + 2, FAR[1] - 8)):
        rails += [(c - 30, a, D, c - 26, e, D + 6), (c + 26, a, D, c + 30, e, D + 6)]
    m.det(rails, PIPE)

    # the train, standing where it waits: the left tunnel, its middle on lc_rail_p1. The tracktrain itself is unseen;
    # two flat cars (train005, 460 long) ride on it, one with two bundles of steel beams, one with three crates
    tv, base = T0[1] + 544, D + 6                   # (it waits in the left tunnel, 544 in: wholly hidden)
    tr = T0[-1] + 544
    parts = [((c - 58, tv - 468, base + 2, c + 58, tv + 468, base + 94), MAT["nodraw"])]
    brush(m, "func_tracktrain", {
        "targetname": "lc_rail_train", "target": "lc_rail_p1", "origin": "%d %d %d" % (m.fr.at(c, tv, base)), "orientationtype": "0", "velocitytype": "0",
        "startspeed": "350", "speed": "350", "height": "0", "wheels": "50", "bank": "0", "dmg": "1000", "spawnflags": "530", "volume": "10",
        "MoveSound": "ambient/machines/razor_train_wheels_loop1.wav", "MoveSoundMinPitch": "60", "MoveSoundMaxPitch": "200", "MoveSoundMinTime": "0",
        "MoveSoundMaxTime": "0", "ManualSpeedChanges": "0", "ManualAccelSpeed": "0", "ManualDecelSpeed": "0", "rendermode": "10", "renderamt": "0",
        "rendercolor": "255 255 255", "disableshadows": "1"}, parts, MAT["nodraw"], vis=b.vis + ": the train")
    for k in (0, 1):
        ride(m, "lc_rail_train", "models/props_trainstation/train005.mdl", c, tv - 238 + 476 * k, 0, base)
    for du in (-22, 22):
        ride(m, "lc_rail_train", "models/props_junk/ibeam01a_cluster01.mdl", c + du, tv - 238, 90, base + 54)
    for du, dv, model in ((-24, 180, "wood_crate002a"), (22, 250, "wood_crate002a"), (-14, 330, "wood_crate001a")):
        ride(m, "lc_rail_train", "models/props_junk/%s.mdl" % model, c + du, tv + dv, 90, base + 54)
    for k, v in enumerate((-150, 0, 150)):                    # dust and grit off the bridge's underside as it passes
        m.point("env_dustpuff", c + (k - 1) * 30, v, D - 62, {"targetname": "lc_rail_dust_%d" % (k + 1), "scale": "14", "speed": "8", "color": "110 104 96", "angles": "90 0 0"})
    dust = [("OnPass", "lc_rail_dust_*", "SpawnDust", "", t) for t in (1.2, 1.7, 2.2, 2.8)]
    stops = (("lc_rail_p1", tv, "lc_rail_p2", "16", None), ("lc_rail_p2", tv - 128, "lc_rail_p3", "0", [("OnPass", "lc_rail_shake", "StartShake", "", 0)] + dust),
             ("lc_rail_p3", -(tr - 128), "lc_rail_p4", "0", None), ("lc_rail_p4", -tr, "lc_rail_p1", "0", [("OnPass", "lc_rail_train", "Stop", "", 0)]))
    for name, v, nxt, flags, wires in stops:
        m.point("path_track", c, v, base, {"targetname": name, "target": nxt, "spawnflags": flags, "orientationtype": "0", "speed": "0", "radius": "0"},
                b.vis + ": the train", connections=wires)
    sound(m, "lc_rail_horn", "ambient/alarms/train_horn2.wav", c, T0[1] + 64, D + 64, radius=4000)
    m.point("env_shake", c, 0, D, {"targetname": "lc_rail_shake", "amplitude": "3", "radius": "1000", "duration": "3.5", "frequency": "35", "spawnflags": "0"})
    m.relay("lc_rail_run", c, 0, D + 180, [("lc_rail_horn", "PlaySound", "", 0), ("lc_rail_signal_*", "ShowSprite", "", 0), ("lc_rail_train", "StartForward", "", 2),
                                           ("lc_rail_signal_*", "HideSprite", "", 10)])
    m.point("logic_timer", c, 0, D + 200, {"targetname": "lc_rail_timer", "RefireTime": "150", "UseRandomTime": "0", "StartDisabled": "0", "spawnflags": "0"},
            connections=[("OnTimer", "lc_rail_run", "Trigger", "", 0)])
    m.test_button((c - 8, 120, F + 40, c + 8, 128, F + 56), [("OnIn", "lc_rail_run", "Trigger")])

    # under the bridge: what fell off the last train, broken; who stood on the line
    m.loose("models/props_junk/wood_crate001a_damaged.mdl", c + 70, -60, 25)
    m.loose("models/props_junk/wood_crate002a.mdl", c - 90, 40, 70)
    m.loose("models/items/item_item_crate.mdl", c + 20, 70, 10)
    for k, (du, dv) in enumerate(((60, -20), (90, -100), (40, -90))):
        m.loose("models/props_junk/wood_crate001a_chunk0%d.mdl" % (k + 1), c + du, dv, 50 * k)
    m.static("models/props_debris/concrete_chunk01a.mdl", c + 130, 96, 40)
    m.body("models/humans/corpse1.mdl", c - 40, -30, 100)
    m.decal("decals/bloodstain_002", c - 30, -20, F + 1)
    m.soundscape(SCAPES["courtyard"], c, 0, F, radius=800)
    m.lane(c, 0)
    m.view(180, -40, F, 8, -14, "the bridge from the canal")
    m.view(c + 360, -100, F, 138, -16, "the left tunnel's mouth and the bridge")
    m.view(c - 56, T0[1] + 44, D, 86, 2, "in the left tunnel: the train where it waits")
    m.view(c + 60, 40, F, 200, -30, "under the bridge")
    b.notes.append("%s: the rails are at z %d (the walls' top less 144); the train waits at (%d %d) and stops at (%d %d)" % (
        (m.tag, D + 6) + m.fr.pt(c, tv) + m.fr.pt(c, -tr)))


def m_pumphouse(m, opt):
    """The pumping station: off the left wall, through a wide doorway, a machine hall 704 by 512 and 320 high, its walls
    laid in courses as City 18 and Valve lay a big wall (a concrete base, brick, a stone band course, concrete to the
    roof). The doorway opens onto floor, the turbine pit straight ahead; in the hall's right half a big iron wheel
    (Half-Life 2's wheel02b, 132 across) turns slowly (lc_pump_wheel) on the shaft of the pump, a long horizontal tank
    on the floor behind it (horizontalcoolingtank04) running back to the far wall, hazard stripes round the wheel's
    guard; two risers climb from the tank to a header pipe under the roof, which runs on into the front wall as the
    main; a travelling crane's beam crosses the roof with its hoist hanging; switch boxes on the wall by the stairs, a
    cable to them from the turbine. Behind the doorway's line a turbine pit (192 square, 96 deep, ankle
    deep in water, steps down into it, the city's handrail round it, hazard stripes round its edge, the turbine's
    casing standing in it), numbers on the walls by the machines. The main leaves through the
    front wall, runs along the canal wall and crosses the canal overhead on a pipe bridge nobody can reach (where the
    chain's street runs along the far bank, at 608, under the street's edge, so it goes on under the street). A steel
    gallery runs round the hall 144 up behind the handrail: its stairs climb along the left wall toward the front wall
    (a steel plate along their open side, room at their foot) onto a landing in the corner left of the door; over the
    door a bay 64 deeper holds the control desk against the front wall, 64 clear behind it: a monitor, a lamp, and the
    button that stops and starts the pumps, facing whoever stands at the desk. The door that shuts the doorway (a sliding gate) stands slid open along the wall inside.

    Named for the game:
      lc_pump_wheel     the wheel: a func_rotating (Start, Stop), unseen itself, the wheel model riding on it. It turns
                        as the map starts. Not solid: an unseen wall for players stands round it instead, so nobody is
                        caught in it.
      lc_pump_button    the button on the desk: a press triggers both relays below; only the live one answers.
      lc_pump_stop, lc_pump_start   relays: Trigger one to stop or start the pumps (wheel, sound, the desk's lamp).
                        lc_pump_stop is live while they run, lc_pump_start while they stand.
      lc_pump_sound     the pumps' drone (a looping sound, playing from the start).
      lc_pump_down, lc_pump_up      the run-down and run-up sounds.
      lc_pump_glow      the green glow on the desk's lamp: lit while the pumps run.
      lc_pump_hall      the hall's floor, inside the door.
    An areaportal stands in the doorway's thickness (well clear of the pit's water).

    Left as brushes: the hall and its courses, the doorway's frame, the gallery (its grating and posts), the steel plate
    along the stairs, the wheel's bearing pedestal, the crane's beam, the hazard stripes (dev_hazzardstripe01a, as the
    owner's map paints its edges), the pipe bridge's girders and the plates where pipes meet the walls.

    Unchecked: func_rotating's keys from memory ("maxspeed" 40 degrees a second, "fanfriction", spawnflags 1 start on +
    16 run up and down + 64 not solid, and 4 or 8 for the axle: if the wheel tumbles instead of turning, those two are
    the other way round). That a prop parented to a func_rotating turns with it. Sounds from memory:
    ambient/machines/pump_loop_1.wav, ambient/machines/thumper_shutdown1.wav, ambient/machines/thumper_startup1.wav.
    Material metal/metalgrate013a passes the assets check; how it looks as a floor is not known. How the models look
    (their sizes are read): wheel02b as a flywheel, the cooling tank as a pump, substation_transformer01c as the
    turbine's casing, slidinggate001 as the door, pulleyhook01 hung from the crane's beam (its top taken as 142 over its
    origin)."""
    b = m.b
    L, H, G, cx = 1280, F + 320, F + 144, 672
    grate, floor = "metal/metalgrate013a", "concrete/concretefloor016a"
    m.open(0, -256, L, 256)
    m.low(576, 256, 768, 320, F + 144)
    m.portal(576, 287, F, 768, 289, F + 144)
    m.low(320, 320, 1024, 832, H, mat=floor)
    m.low(576, 640, 768, 832, H, floor=F - 96)
    m.water(576, 640, 768, 832, F - 96, F - 72)
    m.side(320, 256, 1024, 832)
    m.blocked(576, 640, 768, 832)
    m.blocked(448, 420, 896, 640)
    m.blocked(320, 320, 384, 664)
    # the doorway's steel frame on the canal side, and the door itself (a sliding gate) slid open along the wall inside
    m.det([(568, 248, F, 578, 256, F + 144), (766, 248, F, 776, 256, F + 144), (568, 248, F + 144, 776, 256, F + 160)], STEEL)   # (the banks' ends hide in its posts)
    m.taken(560, 232, F, 784, 256, F + 168)
    m.static("models/props_c17/slidinggate001.mdl", 852, 334, 90, z=F)
    # the hall's walls in courses: a concrete base, brick, a stone band course, concrete to the roof (the base and band
    # 8 proud, the rest 4; the side walls' courses stop at the front and back walls' so no two tops lie in one plane)
    courses = ((F, F + 96, 8, "concrete/concretewall059c"), (F + 96, F + 256, 4, "brick/brickwall014l"), (F + 256, F + 272, 8, "stone/stonewall050f"),
               (F + 272, H, 4, "concrete/concretewall008a"))
    for z1, z2, t, mat in courses:
        boxes = [(320, 320, z1, 576, 320 + t, z2), (768, 320, z1, 1024, 320 + t, z2), (320, 832 - t, z1, 576, 832, z2), (768, 832 - t, z1, 1024, 832, z2),
                 (320, 536, z1, 320 + t, 824, z2), (1024 - t, 328, z1, 1024, 824, z2)]
        if z2 > F + 160:
            boxes.append((320, 328, max(z1, F + 160), 320 + t, 536, z2))          # (over the stairs' upper half and the landing at their head)
        if z2 > F + 144:
            boxes.append((576, 320, max(z1, F + 144), 768, 320 + t, z2))          # (over the doorway)
        if z2 > F + 96:
            boxes.append((576, 832 - t, max(z1, F + 96), 768, 832, z2))           # (over the pit's back wall)
        m.det(boxes, mat)
    m.det([(576, 828, F - 96, 768, 832, F + 96)], "concrete/concretewall059c")        # (the pit's back wall, under the base course)

    # the gallery: steel grating on posts, the city's handrail on its open edge, a bay over the door for the control desk
    # (the owner, 22 November, of the desk standing across the gallery: "THERE IS NO ROOM TO WALK HERE"), and the
    # stairs along the left wall climbing toward the front wall, onto a landing in the corner left of the door that is
    # the front gallery's end (the owner: "room with the turning wheel has stairs going into the wall")
    m.det([(320, 768, G - 8, 1024, 832, G), (320, 544, G - 8, 384, 768, G), (960, 320, G - 8, 1024, 768, G), (320, 320, G - 8, 960, 384, G),
           (576, 384, G - 8, 768, 448, G)], PIPE, top=grate)
    m.det([(u, v, F, u + 6, v + 6, G - 8) for u, v in ((384, 544), (378, 762), (540, 762), (804, 762), (954, 762), (954, 560), (954, 378), (804, 378),
                                                       (576, 442), (762, 442), (386, 378))], PIPE)
    m.steps(600, 320, 384, F, G, "v", -1)
    m.shapes([prism([(604, F), (604, F + 36), (384, G + 36), (384, G)], "x", 382, 386, STEEL)])
    handrail(m, (384, 770), (960, 770), G)
    handrail(m, (382, 544), (382, 768), G)
    handrail(m, (320, 546), (384, 546), G)                        # (across the left arm's end, over the stairs)
    handrail(m, (962, 384), (962, 768), G)
    handrail(m, (384, 382), (576, 382), G)
    handrail(m, (768, 382), (960, 382), G)
    handrail(m, (576, 446), (768, 446), G)
    handrail(m, (574, 384), (574, 448), G)
    handrail(m, (770, 384), (770, 448), G)

    # the turbine pit: steps down along its near side, the handrail round it, the turbine's casing in the water
    m.steps(784, 576, 608, F - 96, F, "v", -1)
    handrail(m, (608, 638), (768, 638), F)
    handrail(m, (574, 640), (574, 832), F)
    handrail(m, (770, 640), (770, 832), F)
    m.static("models/props_c17/substation_transformer01c.mdl", cx, 736, 0, z=F - 96)
    m.light(cx, 680, F - 30, "120 200 190 35")
    stripe = "dev/dev_hazzardstripe01a"
    m.det([(576, 628, F, 768, 636, F + 1), (566, 640, F, 574, 832, F + 1), (770, 640, F, 778, 832, F + 1)], stripe)
    m.grime("number", 576, 700, F - 40, 1)
    m.grime("number", 1024 - 8, 552, F + 180, 2)

    # the machines: the wheel on its pedestal (to the right of the doorway's line: the way in opens onto floor), its
    # shaft into the pump, two risers to the header
    wz, wu, wv = F + 80, cx + 208, 410
    brush_shapes(m, "func_rotating", {
        "targetname": "lc_pump_wheel", "origin": "%d %d %d" % (m.fr.at(wu, wv, wz)), "spawnflags": str(1 + 16 + 64 + (4 if m.fr.ax("v") == "x" else 8)),
        "maxspeed": "40", "fanfriction": "20", "volume": "0", "dmg": "0", "solidbsp": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255",
        "disableshadows": "1"}, [], boxes=[(wu - 8, wv - 8, wz - 8, wu + 8, wv + 8, wz + 8)], mat=MAT["nodraw"], vis=b.vis + ": the wheel")
    ride(m, "lc_pump_wheel", "models/props_wasteland/wheel02b.mdl", wu, wv, 0, wz - 66)
    m.world((wu - 72, wv - 28, F, wu + 72, wv + 28, wz + 72), MAT["clip"], seals=False)
    m.det([(wu - 14, wv + 28, F, wu + 14, wv + 44, wz + 10)], MAT["beam"])
    m.det([(wu - 80, wv - 40, F, wu + 80, wv - 34, F + 1), (wu - 80, wv + 50, F, wu + 80, wv + 56, F + 1), (wu - 80, wv - 34, F, wu - 74, wv + 50, F + 1),
           (wu + 74, wv - 34, F, wu + 80, wv + 50, F + 1)], "dev/dev_hazzardstripe01a")     # (the guard painted round it)
    m.static("models/props_pipes/pipe03_straight01_short.mdl", wu, wv + 40, 0, z=wz - 8)
    tv = 640                                                      # the tank, along the hall from behind the wheel to the far wall
    m.static("models/props_wasteland/horizontalcoolingtank04.mdl", wu, tv, 90, z=F)
    hz = F + 264
    for s in (1, -1):
        centred(m, "models/props_pipes/pipecluster08d_extender128.mdl", wu, tv + s * 140, 0, F + 184)
    pipe_run(m, (wu, 320), (wu, 832), hz, "32d")                  # the header, from the front wall (where it leaves as the main) to the back
    # the travelling crane's beam across the roof, its hoist; switch boxes by the pump, a cable to them from the turbine
    m.det([(328, 640, H - 24, 1016, 656, H)], "metal/metaltruss017a")
    m.static("models/props_c17/pulleywheels_large01.mdl", 480, 648, 0, z=H - 70)
    m.static("models/props_c17/pulleyhook01.mdl", 480, 648, 0, z=H - 214)
    m.static("models/props_lab/powerbox01a.mdl", 342, 700, 0, z=F + 50)
    m.static("models/props_lab/powerbox02b.mdl", 336, 740, 0, z=F + 70)
    m.rope([(342, 700, F + 104), (630, 736, F + 40)], slack=60, width=2)

    # outside: the main along the canal wall, then across on the pipe bridge (its middle at pu). Where the chain's street
    # runs along the far bank, the main crosses under the street's edge (its plate and pipe 640 or lower) and goes on
    # under the street, never up through its parapet
    pu = cx + 384
    oz = TRIM - 48 if m.street_side() == -1 else hz
    m.det([(wu - 32, 239, oz - 32, wu + 32, 256, oz + 32), (pu - 32, -256, oz - 32, pu + 32, -239, oz + 32)], STEEL)     # (1 proud of the trim)
    pipe_run(m, (wu, 220), (pu, 220), oz, "32d")              # (clear of the trim line on the wall: it rests on it)
    m.static("models/props_c17/pipe_cap005.mdl", wu, 220, 180, z=oz - 19)    # (its start, at the plate where it leaves the hall, capped)
    pipe_run(m, (pu, -256), (pu, 256), oz, "32d")
    m.det([(pu - 40, -256, oz - 48, pu - 32, 256, oz - 32), (pu + 32, -256, oz - 48, pu + 40, 256, oz - 32)], STEEL)
    m.det([(pu - 40, v, oz - 32, pu + 40, v + 6, oz - 26) for v in range(-232, 240, 96)], PIPE)
    m.taken(wu - 40, 200, oz - 56, pu + 48, 256, oz + 40)
    m.taken(pu - 48, -256, oz - 56, pu + 48, -200, oz + 40)

    # the control desk against the front wall in the bay over the door (64 clear behind it): a monitor, the lamp, the
    # button on its top facing whoever stands at it
    m.static("models/props_wasteland/controlroom_desk001b.mdl", cx, 349, 270, z=G)
    m.static("models/props_wasteland/controlroom_monitor001a.mdl", cx - 24, 348, 270, z=G + 34)
    m.button("lc_pump_button", cx + 18, 362, G + 34, 90, [("lc_pump_stop", "Trigger", "", 0), ("lc_pump_start", "Trigger", "", 0)], wait="3.5")
    m.static("models/props_combine/combine_light002a.mdl", cx + 44, 344, 270, z=G + 34)
    sprite(m, "lc_pump_glow", cx + 44, 342, G + 74, "120 255 140", 0.2)
    sound(m, "lc_pump_sound", "ambient/machines/pump_loop_1.wav", cx, 552, F + 100, loops=True, on=True, radius=1400, volume=8)
    sound(m, "lc_pump_down", "ambient/machines/thumper_shutdown1.wav", cx, 552, F + 100, radius=1400)
    sound(m, "lc_pump_up", "ambient/machines/thumper_startup1.wav", cx, 552, F + 100, radius=1400)
    toggle(m, "lc_pump_stop", "lc_pump_start", cx, 400, G + 100,
           [("lc_pump_wheel", "Stop", "", 0), ("lc_pump_sound", "StopSound", "", 0), ("lc_pump_down", "PlaySound", "", 0), ("lc_pump_glow", "HideSprite", "", 0)],
           [("lc_pump_wheel", "Start", "", 0), ("lc_pump_up", "PlaySound", "", 0), ("lc_pump_sound", "PlaySound", "", 1), ("lc_pump_glow", "ShowSprite", "", 0)], 3)

    # light and odds and ends
    for u, v in ((480, 470), (800, 470), (480, 690), (800, 760)):
        m.lamp(u, v, H - 48, "255 226 180 65", hang=40)
    m.static("models/props_c17/lockers001a.mdl", 1006, 410, 180)
    m.static("models/props_c17/lockers001a.mdl", 1006, 462, 180)
    m.soundscape(SCAPES["pump"], cx, 560, F, radius=520)
    m.static("models/props_c17/shelfunit01a.mdl", 880, 820, 180)
    m.static("models/props_c17/oildrum001.mdl", 346, 700, 0)
    m.static("models/props_c17/oildrum001.mdl", 352, 738, 40)
    m.loose("models/props_junk/wood_crate001a.mdl", 430, 780, 15)
    m.loose("models/props_junk/metalbucket01a.mdl", 790, 452, 0)
    m.target("lc_pump_hall", cx, 400, F + 8, 90)
    m.lane(cx, 288)
    m.blocked(wu - 80, wv - 40, wu + 80, 800)
    m.lane(cx, 392)
    m.lane(352, 650, G)
    m.lane(352, 680)
    m.lane(352, 352, G)
    m.lane(cx, 800, G)
    m.lane(992, 550, G)
    m.lane(cx - 80, 344, G)
    m.view(cx, 120, F, 90, 0, "the way in")
    m.view(cx, 340, F, 75, 0, "the hall from the door: the pit ahead, the wheel to the right")
    m.view(cx, 420, G, 270, 10, "at the control desk, in its bay")
    m.view(352, 720, F, 270, 8, "the stairs up to the gallery")
    m.view(440, 690, F, 345, 8, "the pit and the pump")
    m.view(1180, -100, F, 190, -24, "the pipe bridge")
    b.notes.append("%s: the hall's floor is z %d, its gallery z %d, its roof z %d; the pit's floor z %d under %d of water" % (m.tag, F, G, H, F - 96, 24))


# ---------------------------------------------------------------------------
# 4. The thumper (experimental)
# ---------------------------------------------------------------------------

def m_thumper(m, opt):
    """EXPERIMENTAL: a Combine thumper. The canal widens to the right into a concrete terrace 512 long and 384 deep,
    128 over the floor: a flight of 8 steps against its face climbs to a landing at the gate's foot (an upstand on its
    open side), and the bank either side of the flight is a ramp too. On it, behind the Combine's own fence (combine_fence01b and 01a posts, the
    owner's field between them) with a gate players open (Nova Prospekt's gate in its frame, between two of the posts),
    Half-Life 2's own thumper (prop_thumper, the coast's CombineThumper002, 338 high) on a concrete plinth, fed by a fat
    cable from a Combine generator: it lifts and drops its hammer by itself, shakes the ground, thuds and keeps antlions
    away, for ever. Each time it lands dust jumps from the plinth. Against the terrace's near wall a Combine console,
    the Combine's lamp over it and a small screen beside it, and the button that stops and starts it; Combine lamps and
    a camera on the terrace's back wall, danger signs. Why it is here is shown downstream: sand drifted over the canal's
    floor toward the exit, a burrow broken through the left wall's foot with sand spilling from it, two dead antlions.

    Named for the game:
      lc_thumper_head    the thumper itself (prop_thumper): Disable stops it, Enable starts it; its output OnThumped
                         fires each time the hammer lands (the dust and the shake hang on it).
      lc_thumper_timer   a logic_timer, RefireTime 3, that tells lc_thumper_head Enable: it keeps the thumper going
                         while it runs (the relays below switch both).
      lc_thumper_stop, lc_thumper_start   relays: Trigger one to stop or start it (the thumper, the timer, the lamp,
                         a sound). lc_thumper_stop is live while it runs. The game may hang antlions on lc_thumper_stop.
      lc_thumper_button  the button by the console: a press triggers both relays; only the live one answers.
      lc_thumper_pad     the ground under the hammer.
      lc_thumper_gate    the fence's gate (a func_door_rotating, unseen, with Nova Prospekt's gate riding on it: Use
                         opens it; the gamemode can lock it).
      lc_thumper_hit, lc_thumper_top, lc_thumper_shake, lc_thumper_dust, lc_thumper_glow, lc_thumper_down
                         a thud and a clank the game may play (the thumper makes its own sounds, so nothing plays
                         them), the shake and the dust at each landing, the blue glow on the lamp over the console
                         (lit while it runs), the run-down sound.
      lc_thumper_lamp    the console lamp's light (TurnOff, TurnOn: the relays switch it with the glow).
      lc_thumper_burrow  the burrow's mouth in the left wall (where the game may bring antlions out).

    Left as brushes: the terrace and the thumper's plinth (the ground it stands on), the burrow's back.

    Unchecked: prop_thumper's keys and its input and output from memory of Half-Life 2's coast ("dustscale",
    "EffectRadius", Enable, Disable, OnThumped); that it starts running by itself; which way the model faces (it is
    placed so its box is centred on the plinth). env_smokestack's TurnOn and TurnOff for the dust. Sounds from memory:
    ambient/machines/thumper_hit.wav, ambient/machines/thumper_top.wav, ambient/machines/thumper_shutdown1.wav.
    models/antlion.mdl as a ragdoll; nature/blendmuddirt001a for the drift (blendsandmud001a is not in the owner's Garry's Mod: their compile, 22 November); combine_shield_loop3.wav."""
    b = m.b
    L, P = 1024, F + 128
    cu, cv = 512, -448
    m.open(0, -256, L, 256)
    m.open(256, -640, 768, -256, floor=P, mat=MAT["quay_floor"])
    m.side(256, -640, 768, -256)
    m.taken(256, -264, F, 768, -256, P + 100)
    m.blocked(256, -640, 768, -256)
    # the way up (the owner, 22 November: the check found the terrace could not be walked to): a flight of 8 against the
    # terrace's face, toward the gate, an upstand on its open side, onto a landing at the gate's foot; the bank stays a
    # ramp either side of it
    m.no_bank(440, -264, 712, -248)
    m.steps(448, -256, -192, F, P, "u", 1)
    m.stair_side(448, 192, -192, -186, F, P, 1)
    m.det([(640, -256, F, 704, -192, P)], MAT["canal_wall"], top=MAT["quay_floor"])
    m.det([(640, -192, F, 704, -186, P + 32)], MAT["beam"])
    m.blocked(448, -256, 704, -186)
    m.lane(420, -160)
    m.lane(544, -224, F + 64)
    # the Combine's fence across the terrace, 48 back from its edge: posts and fields, the gate in its frame between
    fv = -304
    combine_field(m, (264, fv), (568, fv), P)
    combine_field(m, (648, fv), (760, fv), P, hum=False)
    fence_gate(m, "lc_thumper_gate", 608, fv, P, "u", open_frame=True)
    # the plinth, and the thumper on it (its box centred on the plinth: the model's middle is off its origin)
    m.shapes([vprism(octagon(cu, cv, 76), P, P + 16, MAT["beam"])])
    top = P + 16 + 338
    m.prop("prop_thumper", "models/props_combine/combinethumper002.mdl", cu - 12, cv + 18, 0, P + 16, {
        "targetname": "lc_thumper_head", "dustscale": "128", "EffectRadius": "1000"})
    m.point("logic_timer", cu, cv, top + 30, {"targetname": "lc_thumper_timer", "RefireTime": "3", "UseRandomTime": "0", "StartDisabled": "0", "spawnflags": "0"},
            connections=[("OnTimer", "lc_thumper_head", "Enable", "", 0)])
    sound(m, "lc_thumper_hit", "ambient/machines/thumper_hit.wav", cu, cv, P + 40, radius=3000)
    sound(m, "lc_thumper_top", "ambient/machines/thumper_top.wav", cu, cv, P + 240, radius=1500, volume=6)
    sound(m, "lc_thumper_down", "ambient/machines/thumper_shutdown1.wav", cu, cv, P + 240, radius=2000)
    m.point("env_shake", cu, cv, P + 20, {"targetname": "lc_thumper_shake", "amplitude": "6", "radius": "1200", "duration": "0.6", "frequency": "30", "spawnflags": "0"})
    m.point("env_smokestack", cu, cv, P + 22, {"targetname": "lc_thumper_dust", "InitialState": "0", "BaseSpread": "44", "SpreadSpeed": "40", "Speed": "30", "StartSize": "16",
                                               "EndSize": "56", "Rate": "40", "JetLength": "70", "WindAngle": "0", "WindSpeed": "0", "SmokeMaterial": "particle/SmokeStack.vmt",
                                               "twist": "6", "roll": "6", "rendercolor": "150 136 112", "renderamt": "110", "angles": "0 0 0"})
    m.target("lc_thumper_pad", cu, cv, P + 24)
    # the console against the terrace's near wall, the lamp over it, the button beside it
    m.static("models/props_combine/combine_interface001.mdl", 282, -404, 0, z=P)
    combine_lamp(m, 256, -404, P + 90, 0, "120 200 255 40", name="lc_thumper_lamp")
    sprite(m, "lc_thumper_glow", 276, -404, P + 110, "120 220 255", 0.35)
    m.static("models/props_combine/combine_smallmonitor001.mdl", 270, -456, 0, z=P + 60)
    m.button("lc_thumper_button", 256, -340, P + 36, 0, [("lc_thumper_stop", "Trigger", "", 0), ("lc_thumper_start", "Trigger", "", 0)], wait="2.5")
    toggle(m, "lc_thumper_stop", "lc_thumper_start", 270, -404, P + 160,
           [("lc_thumper_head", "Disable", "", 0), ("lc_thumper_timer", "Disable", "", 0), ("lc_thumper_glow", "HideSprite", "", 0), ("lc_thumper_down", "PlaySound", "", 0),
            ("lc_thumper_lamp", "TurnOff", "", 0)],
           [("lc_thumper_timer", "Enable", "", 0), ("lc_thumper_head", "Enable", "", 0), ("lc_thumper_glow", "ShowSprite", "", 0), ("lc_thumper_lamp", "TurnOn", "", 0)], 2)
    # its power: a Combine generator in the terrace's far corner, a fat cable over the ground to the plinth
    m.static("models/props_combine/combine_generator01.mdl", 716, -592, 180, z=P)
    m.rope([(690, -560, P + 6), (600, -500, P + 4), (cu + 74, cv - 10, P + 8)], slack=20, width=6)
    # the Combine's eyes and lamps on the terrace's back wall, its warnings
    m.static("models/props_combine/combinecamera001.mdl", 512, -622, 90, z=P + 230)
    for u in (360, 640):
        combine_lamp(m, u, -640, P + 190, 90)
    for kind, u, v, z, sd in (("danger", 450, -640, P + 120, 1), ("danger", 256, -520, P + 140, 2), ("number", 600, -640, P + 150, 3)):
        m.grime(kind, u, v, z, sd)
    # outside the fence: two Combine barricades at the ramp's head; inside: what the crew left
    m.dynamic("models/props_combine/combine_barricade_short01a.mdl", 330, -280, 90, z=P)
    m.dynamic("models/props_combine/combine_barricade_short01a.mdl", 720, -280, 90, z=P)
    m.loose("models/props_junk/wood_crate001a.mdl", 330, -600, 20, z=P)
    # downstream, why it is here: sand drifted over the floor, a burrow through the left wall's foot, dead antlions
    m.low(832, 256, 896, 320, F + 64)
    m.side(832, 256, 896, 320)
    m.blocked(832, 256, 896, 320)
    m.no_bank(824, 248, 904, 264)
    m.det([(832, 312, F, 896, 320, F + 64)], MAT["black"])
    m.taken(820, 240, F, 908, 256, F + 90)
    m.target("lc_thumper_burrow", 864, 280, F + 8, 270)
    for model, u, v, yaw in (("rockgranite03a", 796, 232, 30), ("rockgranite03b", 934, 238, 200), ("rockgranite02a", 1000, 176, 100)):     # (beside the mouth, never in front of it)
        m.static("models/props_wasteland/%s.mdl" % model, u, v, yaw, z=F)
    sx, sy = m.fr.pt(864, 240)

    def drift(x, y):
        return 30 * max(0.0, 1 - math.hypot(x - sx, y - sy) / 260.0) ** 1.2
    m.side(768, -256, 1024, 256)
    r = m.fr.rect(768, -256, 1024, 256)
    for x0 in range(r[0], r[2], 256):
        for y0 in range(r[1], r[3], 256):
            zf = F + m.fr.dz
            b.vmf.world_box((x0, y0, zf, x0 + 256, y0 + 256, zf + 8), MAT["nodraw"], top="nature/blendmuddirt001a", vis=b.vis + ": the sand drift",
                            disp={"top": (3, lambda i, j, x0=x0, y0=y0: (x0 + j * 32, y0 + i * 32, zf + drift(x0 + j * 32, y0 + i * 32) - 6),
                                          lambda i, j, x0=x0, y0=y0: 255 * min(1.0, drift(x0 + j * 32, y0 + i * 32) / 12.0))})
    m.body("models/antlion.mdl", 830, 120, 60, z=F + 20)
    m.body("models/antlion.mdl", 940, -60, 200, z=F + 4)
    m.soundscape(SCAPES["combine"], 512, -448, P, radius=520)
    m.soundscape(SCAPES["courtyard"], 880, 0, F, radius=500)
    m.lane(608, -280, P)
    m.lane(608, -350, P)
    m.lane(360, -400, P)
    m.view(512, 60, F, 270, -16, "the thumper from the canal")
    m.view(700, -60, F, 70, -6, "downstream: the sand, the burrow")
    m.view(430, -276, P, 0, -6, "at the fence, toward the gate")
    m.view(330, -560, P, 40, -20, "inside, by the console")
    b.notes.append("%s: the terrace is z %d; the thumper stands at (%d %d), its top z %d (%d over the walls)" % (
        (m.tag, P) + m.fr.pt(cu, cv) + (top, top - b.rim)))


# ---------------------------------------------------------------------------
# 5. The ration depot
# ---------------------------------------------------------------------------

def m_depot(m, opt):
    """The Combine's ration depot: a place to raid. In the left wall the Combine's own big door (combine_door01, 192
    wide and high: lc_depot_door, shut) opens straight off the canal's floor into a loading bay with a truck backed up
    to a dock 40 high, tyres hung on its edge, hazard stripes along it. The hall is the Combine's inside: its walls
    clad in their plate (a base of metalcombine001, panels of metalcombine002, a band of the Citadel's plate under the
    roof), lit by the Combine's wall lights and two tubes, a camera over the cages, a small screen by the big door. The
    dock runs along the back (pallets of the Combine's own supply crates) and fills the far half of the hall: three
    cages of Nova Prospekt's chain link panels against the back wall, a shelf unit with ration packages on it, cases of
    Breen's water and the Combine's crates in each, each with its own gate in its frame and a Combine lock on it
    (lc_depot_cage_1 to _3: Use opens them, the gamemode can lock them),
    the dispatch desk with a Combine console (lc_depot_desk), and a roller conveyor that carries crates out through a
    low hatch in the wall and down a chute to the canal (the hatch is 26 high over the rollers: nobody gets in that
    way). At the far end a staff door (lc_depot_side, one of the city's doors) up the steps from the canal: no Use
    opens it, only the button beside it inside, and it shuts by itself after four seconds. A caged lamp on the wall
    over each door; beside the big door inside, an alarm lamp the game can light.

    Named for the game:
      lc_depot_door         the big door: a func_door that lifts (Open, Close, Toggle), unseen, the Combine door's model
                            riding on it.
      lc_depot_button_door  the button inside, left of the roller door: Toggle.
      lc_depot_side         the staff door: one of the city's doors (prop_door_rotating) that ignores Use (spawnflag
                            32768): Open opens it; it shuts itself after four seconds. The gamemode's door rules
                            (lockpicks, kicks) may still reach it: that is the raiders' other way in.
      lc_depot_button_side  the button inside beside the staff door: Open.
      lc_depot_cage_1, _2, _3   the cages' gates (func_door_rotating, Use: unseen, Nova Prospekt's gate riding on each).
      lc_depot_desk         the Combine console at the dispatch desk (a prop_dynamic).
      lc_depot_alarm, lc_depot_alarm_light   the alarm lamp's red glow and light beside the big door inside (off: ShowSprite
                            and TurnOn light them, HideSprite and TurnOff put them out).
    In a --test file a red button in the roller door's mouth opens and shuts it from outside, as the game will.
    Areaportals: one inside the thickness of each door, one in the hatch.

    Left as brushes: the hall and its cladding, the dock, its steel edge and stripes, the steps, the doors' frames, the cages' mesh roof (no
    model lies flat), the roller conveyor and its chute (Half-Life 2 has no conveyor), the hatch's shutter and the
    concrete cheeks in the bank.

    Unchecked: prop_door_rotating's spawnflag 32768 (ignore Use) and "returndelay" 4; that combine_door01 stands shut
    as a prop_dynamic (it has its own animation) and which of its faces is its front. All models pass the assets check;
    the truck's, the console's and the shelf unit's facing are guesses; where combine_lock01 sits on a gate's frame."""
    b = m.b
    L, HC, DK = 1280, F + 192, F + 40
    floor, wood = "concrete/concretefloor016a", MM["wood"]
    m.open(0, -256, L, 256)
    m.low(256, 320, 1024, 704, HC, mat=floor)
    m.low(640, 320, 1024, 704, HC, floor=DK, mat=floor)
    m.low(256, 576, 640, 704, HC, floor=DK, mat=floor)
    m.low(384, 256, 576, 320, F + 192)                           # the big door's way
    m.low(768, 256, 832, 320, DK + 64, floor=DK)                 # the conveyor's hatch
    m.low(896, 256, 960, 320, DK + 112, floor=DK)                # the staff door's way
    m.side(256, 256, 1024, 704)
    m.no_bank(768, 248, 832, 264)
    m.no_bank(896, 248, 960, 264)
    m.portal(384, 287, F, 576, 289, F + 192)
    m.portal(768, 287, DK, 832, 289, DK + 64)
    m.portal(896, 287, DK, 960, 289, DK + 112)
    m.taken(368, 224, F, 592, 256, F + 216)
    m.taken(744, 224, F, 1008, 256, F + 170)
    # the Combine's cladding on the hall's walls: a base, panels, a band under the roof (the side walls' between the
    # front and back walls', so no two tops lie in one plane); the front wall cut for the three ways in
    for z1, z2, t, mat in ((F, DK + 24, 8, "metal/metalcombine001"), (DK + 24, HC - 24, 4, "metal/metalcombine002"), (HC - 24, HC, 8, "metal/citadel_metalwall090a")):
        boxes = [(256, 704 - t, z1, 1024, 704, z2), (256, 328, z1, 256 + t, 696, z2), (1024 - t, 328, z1, 1024, 696, z2)]
        for u1, u2, top in ((256, 384, None), (576, 768, None), (832, 896, None), (960, 1024, None), (768, 832, DK + 64), (896, 960, DK + 112)):
            lo = max(z1, top) if top else z1
            if lo < z2:
                boxes.append((u1, 320, lo, u2, 320 + t, z2))
        m.det(boxes, mat)
    # the big door: the Combine's door (its box centred in the mouth) riding on an unseen door that lifts it into the
    # wall; a steel frame round the mouth, a caged lamp over it
    from map_mods_b import slide_door
    slide_door(m, "lc_depot_door", [((384, 272, F, 576, 304, F + 192), STEEL)], "-90 0 0", speed=40, lip=8, unseen=True)
    ride(m, "lc_depot_door", "models/props_combine/combine_door01.mdl", 468, 276, 0, F)
    m.det([(376, 248, F, 386, 256, F + 192), (574, 248, F, 584, 256, F + 192), (376, 248, F + 192, 584, 256, F + 208)], PIPE)   # (the banks' ends hide in its posts)
    cage_lamp(m, 480, 256, F + 214, 270, "255 214 160 80")
    m.button("lc_depot_button_door", 364, 320, F + 44, 90, [("lc_depot_door", "Toggle", "", 0)], wait="2")
    m.test_button((568, 262, F + 48, 576, 274, F + 64), [("OnIn", "lc_depot_door", "Open"), ("OnOut", "lc_depot_door", "Close")])

    # the dock: a steel edge and old tyres hung on it toward the bay, hazard stripes along it, steps up beside the door
    m.det([(636, 384, DK - 6, 640, 576, DK), (256, 572, DK - 6, 636, 576, DK)], PIPE)
    m.det([(630, 384, DK, 640, 576, DK + 1), (264, 566, DK, 630, 576, DK + 1)], "dev/dev_hazzardstripe01a")
    for u in (420, 540):
        m.static("models/props_vehicles/tire001c_car.mdl", u, 572, 270, z=DK - 34)
    for v in (432, 512):
        m.static("models/props_vehicles/tire001c_car.mdl", 636, v, 180, z=DK - 34)
    m.steps(580, 320, 384, F, DK, "u", 1)
    m.blocked(576, 320, 640, 384)
    m.static("models/props_vehicles/truck001a.mdl", 468, 448, 270)
    m.blocked(400, 320, 544, 576)
    # the back of the dock: pallets of the Combine's supply crates waiting to go
    for k, (u, v, n) in enumerate(((312, 648, 3), (410, 652, 2), (520, 644, 3))):
        m.static("models/props_junk/wood_pallet001a.mdl", u, v, 90 if k % 2 else 0, z=DK)
        for j in range(n):
            m.static("models/items/item_item_crate.mdl", u + (j % 2) * 4 - 2, v - 4 + 8 * (j // 2), 8 * k + 20 * j, z=DK + 9 + 24 * j)
    m.static("models/props_lab/clipboard.mdl", 590, 600, 30, z=DK)

    # the cages: Nova Prospekt's panels (129 high) with a mesh roof, two partitions, a gate in its frame each; in each
    # a shelf unit against the back wall, cartons stacked on the floor, a crate
    cz, fv = DK, 608
    for k in range(3):
        a = 640 + 128 * k
        panel_fence(m, (a, fv), (a + 32, fv), cz)
        panel_fence(m, (a + 96, fv), (a + 128, fv), cz)
        fence_gate(m, "lc_depot_cage_%d" % (k + 1), a + 64, fv, cz, "u")
        panel_fence(m, (a, fv), (a, 704), cz)
        m.static("models/props_c17/shelfunit01a.mdl", a + 64, 688, 180, z=cz)
        for j in range(2):                                       # ration packages on its shelves
            m.static("models/weapons/w_package.mdl", a + 52 + 22 * j, 688, 90, z=cz + 40)
        cu = a + (26 if k % 2 else 102)
        m.static("models/props_junk/cardboard_box001a.mdl", cu, 664, 0, z=cz)          # Breen's water, by the case
        m.static("models/props_junk/popcan01a.mdl", cu - 6, 664, 30, z=cz + 24)
        m.static("models/items/item_item_crate.mdl", cu, 628, 90, z=cz)
        m.static("models/items/item_item_crate.mdl", a + (96 if k % 2 else 34), 640, 10 + 30 * k, z=cz)
        m.static("models/props_combine/combine_lock01.mdl", a + 92, fv - 6, 270, z=cz + 40)     # (a Combine lock on its gate's frame)
    m.det([(640, fv, cz + 129, 1024, 704, cz + 130)], MAT["fence"])
    m.blocked(640, 592, 1024, 704)

    # the conveyor: rollers between two rails from the dock out through the hatch, and a chute down to the canal
    c1, c2, bz = 780, 820, DK + 20
    rails = []
    for a, e in ((176, 287), (289, 432)):
        rails += [(c1, a, bz, c1 + 4, e, bz + 8), (c2 - 4, a, bz, c2, e, bz + 8)]
    rails += [(u, v, DK, u + 4, v + 4, bz) for u in (c1, c2 - 4) for v in (328, 428)] + [(u, 176, F, u + 4, 180, bz) for u in (c1, c2 - 4)]
    m.det(rails, PIPE)
    m.shapes([pipe_u(v, bz + 5, 3, c1 + 4, c2 - 4) for v in range(184, 430, 16) if not 280 < v < 296]
             + [prism([(176, bz), (176, bz + 4), (112, F + 8), (112, F + 4)], "x", c1, c2, STEEL)])
    m.det([(768, 298, DK + 54, 832, 304, DK + 64), (768, 298, DK, c1, 304, DK + 54), (c2, 298, DK, 832, 304, DK + 54)], STEEL)     # the hatch's shutter and cheeks
    m.loose("models/items/item_item_crate.mdl", 800, 380, 0, z=bz + 8)
    m.blocked(768, 128, 832, 448)
    # the notches in the bank at the hatch and the staff door: concrete cheeks, and the door's steps
    cheek = [(256, F), (120, F), (256, F + 136)]
    m.shapes([prism(cheek, "x", u, u + 8, MAT["beam"]) for u in (762, 830, 890, 958)])     # (each 2 into the cut: the banks' ends hide in them)
    m.steps(196, 896, 960, F, DK, "v", 1)
    m.blocked(896, 128, 960, 320)

    # the staff door: one of the city's doors in an opening fitted as the owner's are; no Use opens it, it shuts itself
    from map_town import DOOR, door_hole
    door_hole(m, "u", 896, 280, 296, DK, DK + 112, PIPE)
    m.b.vmf.point("prop_door_rotating", m.fr.at(905, 288, DK + 55), {
        "targetname": "lc_depot_side", "model": DOOR, "angles": "0 %d 0" % m.fr.yaw(270), "hardware": "1", "skin": "7", "spawnflags": "40960", "distance": "90",
        "speed": "100", "returndelay": "4", "opendir": "0", "ajarangles": "0 0 0", "dmg": "0", "forceclosed": "0", "health": "0", "spawnpos": "0",
        "rendercolor": "255 255 255", "fademindist": "-1", "fadescale": "1"}, m.pv)
    m.b.names.append(("lc_depot_side", "prop_door_rotating", m.tag))
    m.button("lc_depot_button_side", 984, 320, DK + 44, 90, [("lc_depot_side", "Open", "", 0)], wait="5")
    cage_lamp(m, 928, 256, DK + 126, 270, "255 60 40 25")

    # the dispatch desk: the console against the end wall, a counter, a chair, a cabinet
    m.dynamic("models/props_combine/combine_interface001.mdl", 996, 500, 180, z=DK, name="lc_depot_desk")
    m.static("models/props_wasteland/controlroom_desk001b.mdl", 900, 504, 0, z=DK)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 946, 500, 0, z=DK)
    m.static("models/props_wasteland/controlroom_filecabinet002a.mdl", 1006, 400, 180, z=DK)
    m.static("models/props_lab/clipboard.mdl", 896, 486, 20, z=DK + 34)
    m.static("models/props_combine/combine_intmonitor001.mdl", 1010, 560, 180, z=DK)
    # the Combine's light: their wall lights, two tubes; their eye over the cages; a screen by the big door; the alarm
    for u, v, z, out in ((256, 448, F + 120, 0), (1024, 420, DK + 100, 180), (720, 704, DK + 96, 270), (960, 704, DK + 96, 270), (360, 704, DK + 96, 270)):
        combine_lamp(m, u, v, z, out)
    tube(m, 448, 448, HC, along="v")
    tube(m, 832, 480, HC, along="u")
    m.static("models/props_combine/combinecamera001.mdl", 832, 682, 270, z=HC - 30)
    m.static("models/props_combine/combine_smallmonitor001.mdl", 640, 342, 90, z=F + 70)
    m.static("models/props_combine/combine_light001a.mdl", 330, 336, 90, z=F + 120)             # (the alarm, beside the big door)
    sprite(m, "lc_depot_alarm", 330, 350, F + 150, "255 40 30", 0.4, on=False)
    named_light(m, "lc_depot_alarm_light", 330, 366, F + 150, "255 40 30 80", on=False)
    m.soundscape(SCAPES["combine"], 640, 512, F, radius=520)
    m.lane(480, 288)
    m.lane(340, 448)
    m.lane(700, 480, DK)
    m.lane(928, 340, DK)
    m.view(480, 40, F, 90, 0, "the roller door from the canal")
    m.view(300, 350, F, 35, 4, "the loading bay")
    m.view(690, 440, DK, 55, 6, "on the dock: the cages")
    m.view(700, 560, DK, 335, 6, "the dispatch desk and the conveyor")
    m.view(880, 20, F, 95, 0, "the hatch, the chute and the staff door")
    b.notes.append("%s: the bay's floor is z %d, the dock z %d, the roof z %d" % (m.tag, F, DK, HC))


# ---------------------------------------------------------------------------
# 6. The armoury vault
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 6. The armoury vault
# ---------------------------------------------------------------------------

def m_armory(m, opt):
    """A Combine armoury vault: a heist target. Off the left wall an armoured corridor 128 wide runs 384 in to a vault
    door: Nova Prospekt's sliding door (prison_slidingdoor001a, between Combine jambs) that slides sideways into the
    wall at 20 a second, with a klaxon, a groan and a slam. Beside the corridor's first half is the guard booth, behind a wall of Combine metal with a doorway and
    a slit that looks down the corridor. The door answers only to TWO buttons pressed within two seconds of each other:
    one in the booth's far corner, one on the corridor wall by the door, 340 apart with the booth's wall between, so
    it takes two people (the Combine's small light over each glows green for the two seconds its press counts). Pressed
    together again, they shut it. A Combine camera watches the corridor from its entry. Booth and vault are the
    Combine's inside, as the corridor is: walls clad in their plate (a base of metalcombine001, panels of
    metalcombine002, the vault's a band of the Citadel's plate under its roof), the vault's floor steel; tubes light the
    corridor and the booth, the Combine's wall lights the vault. In the booth a desk with the guard's log, a chair, a
    monitor on its stand, a small screen on the wall over the slit, his stun baton, lockers. Inside the vault (384 by
    256), behind two red laser beams across its doorway: gun lockers along one wall, the Combine's ammunition crates
    along the other with guns and boxes of rounds laid on them, more stacked by the door, and the Combine's weapon frame
    (weaponstripper) against the far wall with three pulse rifles standing in front of it under a blue glow. A button
    inside by the door opens it, so nobody is shut in. A red alarm lamp hangs in the corridor by the door, and while the
    door moves two red lights come on along the corridor.

    The door is a func_button used as a mover, as the bunker's, unseen, the door's model riding on it: the gamemode's
    door rules do not reach it, and it has no damage of its own (at 20 a second it stops against whoever stands in its
    way).

    Named for the game:
      lc_armory_door        the vault door (PressIn opens, PressOut shuts; use the relays for the sounds).
      lc_armory_button_a    the button in the guard booth.     lc_armory_button_b    the button by the door.
      lc_armory_count       a math_counter, 0 to 2: each press adds 1 and takes it off two seconds later; at 2 it
                            triggers both relays below.
      lc_armory_open, lc_armory_shut   relays: Trigger one to open or shut the vault with klaxon, groan, slam and the
                            red light. Only the one that makes sense is live.
      lc_armory_button_exit the button inside the vault: triggers lc_armory_open.
      lc_armory_vault       the middle of the vault's floor.
      lc_armory_lamp_a, _b, lc_armory_blip, lc_armory_alarm, lc_armory_move, lc_armory_slam, lc_armory_groan,
      lc_armory_light, lc_armory_shake   the buttons' lamps and blip, and the door's sounds, red light and shake.
      lc_armory_red_1, lc_armory_red_2   the corridor's red lights while the door moves (TurnOn, TurnOff).
      lc_armory_beam_1, lc_armory_beam_2   the laser beams across the vault's doorway (env_beam: TurnOn, TurnOff,
                            Toggle; nothing is tied to them: the game may tie an alarm to them), between
                            lc_armory_beam_1a and _1b, _2a and _2b (info_targets).
    Areaportals: one in the entry, one inside the vault door's thickness.

    Left as brushes: the corridor, its Combine plates and ribs, the booth's wall with its slit, the booth's and the
    vault's cladding, the door's jambs and head, the plinth the rifles stand on.

    Unchecked: the wiring is the owner's nest door's (math_counter Add and Subtract, OnHitMax) and the sounds are the
    bunker's and the nest's, heard there. The rifles are prop_dynamics turned to stand on their butts ("angles" -90
    pitch), the guns on the crates turned on their sides (roll 90): which way a weapon model's barrel lies is from its
    size alone. The weapon and ammunition models pass the assets check as prop_dynamic; whether the gamemode lets
    players pick such props up is its affair. How weaponstripper looks as a rack (its size is read). env_beam's keys
    (from memory: LightningStart, LightningEnd, texture sprites/laserbeam.vmt, life 0, spawnflags 1 starts it on)."""
    b = m.b
    L, CH, VH = 1024, F + 128, F + 160
    m.open(0, -256, L, 256)
    m.low(448, 256, 576, 320, CH)                 # the entry
    m.low(448, 320, 768, 512, CH)                 # the corridor's first half and the guard booth beside it
    m.low(448, 512, 576, 704, CH)                 # the corridor's second half and the door's place
    m.low(320, 704, 704, 960, VH, mat="concrete/concretefloor016a")
    m.side(320, 256, 768, 960)
    m.portal(448, 287, F, 576, 289, CH)
    m.portal(448, 671, F, 576, 673, CH)
    m.taken(432, 224, F, 592, 256, CH + 24)
    # the entry's frame of Combine metal on the canal wall, and the corridor's armour: plates on its walls, ribs overhead
    m.det([(440, 244, F, 450, 256, CH), (574, 244, F, 584, 256, CH), (440, 244, CH, 584, 256, CH + 16)], CMB)     # (the banks' ends hide in its posts)
    m.det([(448, 320, F, 452, 652, CH), (572, 512, F, 576, 652, CH)], CMB)
    m.det([(448, v, CH - 6, 576, v + 12, CH) for v in range(340, 640, 60)], PIPE)
    # the booth's wall: Combine metal 16 thick, a doorway at the entry's end, a slit 24 high further on
    wu, zs = 576, F + 44
    m.det([(wu, 320, F, wu + 16, 332, CH), (wu, 388, F, wu + 16, 512, zs), (wu, 388, zs + 24, wu + 16, 512, CH), (wu, 388, zs, wu + 16, 412, zs + 24),
           (wu, 492, zs, wu + 16, 512, zs + 24), (wu, 332, F + 96, wu + 16, 388, CH)], CMB)
    m.det([(wu - 2, 408, zs - 4, wu + 18, 496, zs + 1), (wu - 2, 408, zs + 23, wu + 18, 496, zs + 28)], PIPE)   # (sill and head 1 into the slit)
    # the booth: the Combine's cladding, the guard's desk and log, a chair, the monitor, a screen, his baton, lockers
    for z1, z2, t, mat in ((F, F + 32, 6, "metal/metalcombine001"), (F + 32, CH, 4, CMB)):
        m.det([(592, 320, z1, 768, 320 + t, z2), (592, 512 - t, z1, 768, 512, z2), (768 - t, 320 + t, z1, 768, 512 - t, z2)], mat)
    m.det([(592, 320, F, 768, 512, F + 1)], "metal/metalfloor005a")
    m.dynamic("models/props_combine/combine_intmonitor001.mdl", 752, 364, 180)
    m.static("models/props_wasteland/controlroom_desk001b.mdl", 742, 430, 180, z=F + 1)
    m.static("models/props_lab/binderblue.mdl", 744, 416, 180, z=F + 35)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 704, 430, 0, z=F + 1)
    m.static("models/props_combine/combine_smallmonitor001.mdl", 606, 450, 0, z=F + 74)
    m.dynamic("models/weapons/w_stunbaton.mdl", 740, 400, 30, z=F + 35, solid=False)
    m.static("models/props_c17/lockers001a.mdl", 680, 498, 270, z=F + 1)
    tube(m, 680, 416, CH, "200 220 255 45", along="v")
    tube(m, 512, 420, CH, "200 220 255 45", along="v")
    tube(m, 512, 560, CH, "200 220 255 40", along="v")
    m.static("models/props_combine/combinecamera001.mdl", 512, 334, 90, z=CH - 34)            # (watching the corridor from its entry)
    for k, v in enumerate((400, 580)):                                                       # the corridor's red lights while the door moves
        named_light(m, "lc_armory_red_%d" % (k + 1), 512, v, CH - 30, "255 40 30 60", on=False)

    # the vault door, drawn shut: Nova Prospekt's sliding door (114 wide, 120 high) on an unseen leaf, between jambs of
    # Combine metal under a head; it slides away from the booth's side into the wall
    m.det([(448, 648, F, 455, 696, CH), (567, 648, F, 576, 696, CH), (455, 648, F + 120, 567, 696, CH)], CMB)
    brush(m, "func_button", {"targetname": "lc_armory_door", "movedir": "0 %d 0" % m.fr.yaw(180), "speed": "20", "lip": "5", "wait": "-1", "spawnflags": "0",
                             "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                             "min_use_angle": "0.8", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "disablereceiveshadows": "0"},
          [(454, 666, F, 568, 678, F + 120)], MAT["nodraw"], vis=b.vis + ": the vault door")
    ride(m, "lc_armory_door", "models/props_wasteland/prison_slidingdoor001a.mdl", 511, 672, 90, F)
    at = (512, 640, F + 100)
    sound(m, "lc_armory_blip", "Buttons.snd17", 512, 600, F + 60, radius=700)
    sound(m, "lc_armory_alarm", "ambient/alarms/klaxon1.wav", 512, 560, F + 110, radius=2200)
    sound(m, "lc_armory_move", "Streetwar.d3_c17_11_garage_move1", *at, loops=True, radius=2200)
    sound(m, "lc_armory_slam", "Streetwar.d3_c17_11_garage_stop1", *at, radius=2200)
    sound(m, "lc_armory_groan", "ambient/materials/metal_stress4.wav", *at, radius=2200)
    m.static("models/props_wasteland/prison_lamp001c.mdl", 512, 620, 0, z=CH - 12)
    named_light(m, "lc_armory_light", 512, 620, CH - 22, "255 50 30 200", on=False)
    m.point("env_shake", 512, 640, F + 60, {"targetname": "lc_armory_shake", "amplitude": "5", "radius": "700", "duration": "1.2", "frequency": "40", "spawnflags": "0"})
    m.point("math_counter", 512, 560, F + 90, {"targetname": "lc_armory_count", "startvalue": "0", "min": "0", "max": "2", "StartDisabled": "0"},
            connections=[("OnHitMax", "lc_armory_open", "Trigger", "", 0), ("OnHitMax", "lc_armory_shut", "Trigger", "", 0)])
    for tag, u, v, out in (("a", 764, 484, 180), ("b", 452, 616, 0)):
        du = -1 if out == 180 else 1
        m.static("models/props_combine/combine_light002a.mdl", u + du * 10, v, (out + 180) % 360, z=F + 70)    # (the Combine's small light, its face out)
        sprite(m, "lc_armory_lamp_" + tag, u + du * 22, v, F + 92, "120 255 120", 0.3, on=False)
        m.button("lc_armory_button_" + tag, u, v, F + 40, out,
                 [("lc_armory_count", "Add", "1", 0), ("lc_armory_count", "Subtract", "1", 2), ("lc_armory_lamp_" + tag, "ShowSprite", "", 0),
                  ("lc_armory_lamp_" + tag, "HideSprite", "", 2), ("lc_armory_blip", "PlaySound", "", 0)], wait="2.2")
    moving = [("lc_armory_alarm", "PlaySound", "", 0), ("lc_armory_alarm", "PlaySound", "", 1.7), ("lc_armory_light", "TurnOn", "", 0), ("lc_armory_groan", "PlaySound", "", 0.4),
              ("lc_armory_move", "PlaySound", "", 1), ("lc_armory_move", "StopSound", "", 7), ("lc_armory_slam", "PlaySound", "", 7), ("lc_armory_shake", "StartShake", "", 7),
              ("lc_armory_light", "TurnOff", "", 9), ("lc_armory_red_*", "TurnOn", "", 0), ("lc_armory_red_*", "TurnOff", "", 9)]
    m.relay("lc_armory_open", 500, 580, F + 100, [("lc_armory_open", "Disable", "", 0), ("lc_armory_door", "PressIn", "", 1)] + moving + [("lc_armory_shut", "Enable", "", 9.5)], on=True)
    m.relay("lc_armory_shut", 524, 580, F + 100, [("lc_armory_shut", "Disable", "", 0), ("lc_armory_door", "PressOut", "", 1)] + moving + [("lc_armory_open", "Enable", "", 9.5)], on=False)
    m.button("lc_armory_button_exit", 620, 704, F + 40, 90, [("lc_armory_open", "Trigger", "", 0)], wait="10")

    # the vault: the Combine's cladding and a steel floor; two laser beams across its doorway
    for z1, z2, t, mat in ((F, F + 40, 8, "metal/metalcombine001"), (F + 40, VH - 16, 4, CMB), (VH - 16, VH, 8, "metal/citadel_metalwall090a")):
        m.det([(320, 960 - t, z1, 704, 960, z2), (320, 704, z1, 448, 704 + t, z2), (576, 704, z1, 704, 704 + t, z2),
               (320, 712, z1, 320 + t, 952, z2), (704 - t, 712, z1, 704, 952, z2)], mat)
    m.det([(328, 712, F, 696, 952, F + 1)], "metal/metalfloor005a")
    for k, z in enumerate((F + 22, F + 54)):
        k1 = k + 1
        m.target("lc_armory_beam_%da" % k1, 450, 716, z)
        m.target("lc_armory_beam_%db" % k1, 574, 716, z)
        m.point("env_beam", 512, 716, z, {"targetname": "lc_armory_beam_%d" % k1, "LightningStart": "lc_armory_beam_%da" % k1, "LightningEnd": "lc_armory_beam_%db" % k1,
                                          "texture": "sprites/laserbeam.vmt", "BoltWidth": "1", "NoiseAmplitude": "0", "life": "0", "renderamt": "160",
                                          "rendercolor": "255 20 20", "Radius": "256", "TextureScroll": "35", "framerate": "0", "framestart": "0", "StrikeTime": "1",
                                          "damage": "0", "HDRColorScale": "1.0", "ClipStyle": "0", "spawnflags": "1", "touchtype": "0"})
    # gun lockers along the left wall; along the back wall ammunition crates, guns and rounds laid on them
    def gun(model, u, v, yaw, z, pitch=0, roll=0):
        m.point("prop_dynamic", u, v, z, {"model": model, "angles": "%d %d %d" % (pitch, m.fr.yaw(yaw), roll), "solid": "0", "skin": "0", "disableshadows": "1",
                                          "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                                          "rendercolor": "255 255 255"}, m.pv)
    for v in (744, 792, 840, 888):
        m.static("models/props_c17/lockers001a.mdl", 337, v, 0, z=F + 1)
    for k, u in enumerate((420, 500, 580)):
        m.dynamic("models/items/ammocrate_%s.mdl" % ("smg1", "ar2", "smg1")[k], u, 935, 270, z=F + 1)
        gun("models/weapons/w_shotgun.mdl" if k != 1 else "models/weapons/w_smg1.mdl", u - 8, 932, 0, F + 38, roll=90)
        m.dynamic("models/items/boxmrounds.mdl", u + 18, 940, 0, z=F + 35, solid=False)
    # the weapon frame on the far wall, three pulse rifles standing on their butts on a plinth in front of it
    fu = 704
    m.static("models/props_combine/weaponstripper.mdl", fu - 23, 832, 180, z=F + 1)
    m.det([(fu - 60, 796, F, fu - 42, 868, F + 9)], CMB)
    for v in (806, 832, 858):
        gun("models/weapons/w_irifle.mdl", fu - 51, v, 180, F + 28, pitch=-90)
    m.glow(fu - 50, 832, F + 100, "120 200 255", 0.5)
    m.light(fu - 60, 832, F + 90, "120 200 255 30")
    m.rope([(fu - 16, 790, F + 129), (fu - 16, 720, VH - 4)], slack=20)
    # ammunition: crates stacked in the corner by the door, one under the frame's end, loose crates
    for u, v, yaw, z in ((372, 740, 0, 0), (372, 800, 0, 0), (372, 770, 10, 34), (430, 736, 90, 0), (640, 930, 90, 0), (660, 740, 0, 0)):
        m.dynamic("models/items/ammocrate_%s.mdl" % ("smg1", "ar2", "grenade")[(u + v) // 10 % 3], u, v, yaw, z=F + z)
    m.loose("models/items/item_item_crate.mdl", 470, 800, 20)
    m.loose("models/items/item_item_crate.mdl", 520, 860, 65)
    for u, v, out in ((320, 760, 0), (704, 760, 180), (512, 960, 270)):
        combine_lamp(m, u, v, F + 90, out, "147 226 240 50")
    tube(m, 512, 832, VH, "220 230 255 40", along="u")
    m.soundscape(SCAPES["combine"], 512, 700, F, radius=420)
    m.target("lc_armory_vault", 512, 832, F + 8, 90)
    m.blocked(576, 320, 768, 512)
    m.lane(512, 288)
    m.lane(512, 480)
    m.lane(512, 620)
    m.lane(680, 440)
    m.lane(512, 800)
    m.view(512, 80, F, 90, 0, "the entry from the canal")
    m.view(512, 330, F, 90, 0, "the corridor: the booth's slit, the vault door")
    m.view(730, 370, F, 140, 4, "in the guard booth")
    m.view(500, 730, F, 60, 4, "in the vault: the charging frame")
    m.view(640, 900, F, 190, 6, "in the vault: the racks")
    b.notes.append("%s: the two buttons are %d apart; the vault door is at (%d %d)" % ((m.tag, int(((768 - 452) ** 2 + (484 - 616) ** 2) ** 0.5)) + m.fr.pt(512, 672)))


# ---------------------------------------------------------------------------
# 7. The swing bridge (experimental)
# ---------------------------------------------------------------------------

def street_landing(m, s, cu, deck, arc, lip, U, B, Y):
    """The swing bridge's end on a street's bank: no landing room, the bridge meets the street's canal edge (a gap in its
    parapet), the lip and handrails as on a landing, the button on a steel post at the edge with its lamps, the barrier arm."""
    m.b.edge_gaps.append(m.fr.rect(cu - 72, s * 236, cu + 72, s * 284))
    m.shapes([vprism([(a[0], s * a[1]), (c[0], s * c[1]), (c[0], s * 256), (a[0], s * 256)], deck - 16, deck, MAT["beam"], MAT["quay_floor"])
              for a, c in zip(arc, arc[1:])])
    m.shapes([prism([(s * 256, deck - 56), (s * 256, deck - 16), (s * 236, deck - 16)], "x", cu - 64, cu + 64, MAT["beam"])])
    handrail(m, (cu - 64, s * 238), (cu - 32, s * 238), deck)
    handrail(m, (cu + 32, s * 238), (cu + 64, s * 238), deck)
    tag = "a" if s > 0 else "b"
    wu = U(608)
    m.det([B(600, 296, deck, 616, 312, deck + 80)], STEEL)                                                    # (the post)
    m.button("lc_swing_wheel_" + tag, wu, s * 296, deck + 52, Y(270), [("lc_swing_bell", "PlaySound", "", 0), ("lc_swing_bridge", "Toggle", "", 2)], wait="10")
    sprite(m, "lc_swing_lamp_" + tag, wu - 6, s * 304, deck + 90, "120 255 120", 0.3)
    sprite(m, "lc_swing_red_" + tag, wu + 6, s * 304, deck + 90, "255 50 30", 0.3, on=False)
    sprite(m, "lc_swing_red_%s2" % tag, U(336), s * 168, deck + 90, "255 50 30", 0.35, on=False)
    ay = s * (lip + 10)
    brush(m, "func_door_rotating", {
        "targetname": "lc_swing_arm_" + tag, "origin": "%d %d %d" % m.fr.at(cu - 58, ay, deck + 38), "distance": "85", "speed": "40", "wait": "-1", "lip": "0",
        "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": str(32 + (64 if m.fr.ax("v") == "x" else 128)), "health": "0", "ignoredebris": "0",
        "loopmovesound": "0", "noise1": "Doors.Move10", "noise2": "Doors.FullOpen4", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
        "renderfx": "0", "disableshadows": "1"}, [(cu - 60, ay - 2, deck + 35, cu + 50, ay + 2, deck + 41)], "dev/dev_hazzardstripe01a")
    m.det([(cu - 64, ay - 4, deck, cu - 54, ay + 4, deck + 34)], STEEL)      # (its post)
    m.taken(*B(252, 228, deck - 60, 772, 256, deck + 120))


def m_swingbridge(m, opt):
    """EXPERIMENTAL: a footbridge 224 over the canal's floor (32 under the trim, so that every room of it is roofed at
    720 or lower and a street along the outside bank passes over it) that turns on a round pier in the middle of the
    canal. As the map starts it lies across, from a landing in the left wall to one in the right; turned a quarter it
    lies along the canal and joins nothing. Each landing is a roofed alcove 192 long and 96 high with a street doorway
    that is never used (planked over, boards nailed across; none on the far landing beside a street, where the bridge
    is the street's way down into the canal: across, then down the far landing's stairs), a green lamp that shows while the bridge is across and a red one while it is turned
    away (and a railway signal head on the wall beside the landing), a striped barrier arm across the landing's edge
    that drops while the bridge is away, the city's handrail each side of the bridge's end and along the landing's open
    edge, and against its back wall the canal's winch with the button over it that turns the bridge (a press rings a
    bell, and two seconds later is Toggle). Each landing has its own way up from the canal floor (the owner, 22 November:
    "the stairs for the turnbridge on both sides go into the canal walls"): a doorway in the canal's wall beside the
    landing (60 wide, 144 high, in a steel frame), a corridor behind it under the landing, a covered flight of 7 steps
    climbing away from the doorway, a half landing, and a flight of 7 back along the canal's wall (open to the canal over
    the bank behind a concrete parapet, a wall between it and the flight below) up onto the landing. The left one runs
    toward the module's exit, the right one toward its entry. Whoever turns the bridge away strands the other bank at
    that height.

    The bridge is 458 long and 64 wide: a plank deck on two steel beams with a truss of posts and a bottom chord under
    each and a counterweight under its right end, one func_door_rotating, with the city's handrail along both sides
    riding on it (prop_dynamics parented to it). Its two ends are arcs about the pier (232 out at the middle) and the
    landings' lips are arcs 1 farther out (the owner: "LOOK AT THAT GAP"): across, the deck meets each lip with 2 or
    less between them, and turning it sweeps past them. It turns on a drum: a wide cap on the round pier with a toothed
    ring round it and a motor box driving a pinion. The canal is 512 wide, so it sweeps through nothing (ribs and drain
    stubs are kept off the walls there). It has no damage of its own.

    Named for the game:
      lc_swing_bridge    the bridge: Toggle (or Open: along the canal; Close: across). 12 degrees a second.
      lc_swing_wheel_a   the button over the winch on the left landing.     lc_swing_wheel_b   the same on the right.
      lc_swing_lamp_a, lc_swing_lamp_b   the green lamps (env_sprites): lit while the bridge is across.
      lc_swing_move, lc_swing_stop       the turning sound (looping) and the clank as it comes to rest.
      lc_swing_bell      the bell a press rings before the bridge moves.
      lc_swing_red_a, lc_swing_red_b     the red lamps (env_sprites): lit while the bridge is turned away.
      lc_swing_arm_a, lc_swing_arm_b     the barrier arms (func_door_rotating, no Use): Close drops one across the
                         landing's edge, Open lifts it; the bridge works them (drawn down, the map lifts them as it starts).

    Unchecked: a func_door_rotating this big, turning about its middle with people on it: the engine carries riders
    round on a turning brush, but how well is only seen in the game. Spawnflags 32 (toggle) and no Use; outputs OnOpen,
    OnClose, OnFullyOpen, OnFullyClosed for the sound and lamps. With "wait" -1 a blocked door does not turn back: it
    waits, pushing. Sounds are the bunker door's (heard there). That handrails parented to the turning bridge turn
    with it (props ride on doors so). Which way the winch faces. Which way the arms swing (spawnflags 64 or 128: about
    the canal's axis across the landing; if they swing down through the floor, add 2, Reverse). ambient/alarms/warningbell1.wav.

    Left as brushes: the bridge's deck, beams, truss and counterweight (a bridge deck), the pier, its drum, toothed ring,
    motor box and turntable, the landings, their lips and corbels, the stairs, their parapet and the wall between the
    flights, the doorways' frames and the planking, the barrier arms (dev_hazzardstripe01a)."""
    b = m.b
    street = m.street_side()
    L, cu, deck = 1024, 512, (TRIM if street else TRIM - 32)      # (beside a street the deck is at the street's height and meets it on that bank)
    half, wide, cap = 229, 32, 232          # the deck's straight sides end 229 out; its ends are arcs reaching 232
    lip = cap + 1                           # the lips' edges: arcs 1 farther out than the deck's ends
    ends = [(cu - 32, half), (cu - 16, 231), (cu, cap), (cu + 16, 231), (cu + 32, half)]
    reach = max(math.hypot(u - cu, v) for u, v in ends)
    arc = [(cu + du, int(math.ceil(math.sqrt(lip * lip - du * du)))) for du in range(-64, 65, 16)]
    inner = min(math.hypot((a[0] + c[0]) / 2.0 - cu, (a[1] + c[1]) / 2.0) for a, c in zip(arc, arc[1:]))
    if reach >= inner:
        b.problems.append("%s: the bridge's ends (%d out) would hit the landings' lips (%d out)" % (m.tag, reach, inner))
    m.open(0, -256, L, 256)
    from map_town import board
    for s in (1, -1):
        # drawn for the left bank; the right is the same turned half round about the pier
        def U(u):
            return cu + s * (u - cu)

        def R(u1, v1, u2, v2):
            return (min(U(u1), U(u2)), min(s * v1, s * v2), max(U(u1), U(u2)), max(s * v1, s * v2))

        def B(u1, v1, z1, u2, v2, z2):
            r = R(u1, v1, u2, v2)
            return (r[0], r[1], z1, r[2], r[3], z2)

        def Y(yaw):
            return (yaw + (0 if s > 0 else 180)) % 360
        if s == street:
            street_landing(m, s, cu, deck, arc, lip, U, B, Y)
            continue
        mid = F + (deck - F) // 2                                 # the half landing: each flight climbs 112 in 7 steps
        roof_lo, roof_up = (F + 160, F + 200, mid + 128), (deck + 96, deck + 80, mid + 144)    # (each flight's roof, stepping with it)
        # the landing (192 long, the bridge's end in its far half), 96 high
        m.low(*R(384, 256, 576, 320), deck + 96, floor=deck, mat=MAT["quay_floor"])
        # the way up: the doorway in the canal's wall, the corridor behind it under the landing, the lower flight up
        # away from it, the half landing, the upper flight back along the canal's wall onto the landing
        m.low(*R(320, 256, 384, 320), F + 144)
        m.low(*R(320, 320, 576, 384), F + 144)
        for k in range(3):
            m.low(*R(576 + 64 * k, 320, 640 + 64 * k, 384), roof_lo[k])
            m.low(*R(576 + 64 * k, 256, 640 + 64 * k, 320), roof_up[k], floor=mid)
        m.low(*R(768, 256, 832, 384), mid + 128, floor=mid)
        m.side(*R(320, 256, 832, 384))
        m.blocked(*R(320, 256, 832, 384))
        lo2, hi2 = sorted((s * 320, s * 384))
        m.steps(U(576), lo2, hi2, F, mid, "u", s)
        m.det([B(744, 320, F, 768, 384, mid)], MAT["canal_wall"], top=MAT["stairs"])      # (the half landing's end over the lower flight's cell)
        lo1, hi1 = sorted((s * 256, s * 320))
        m.steps(U(744), lo1, hi1, mid, deck, "u", -s)
        m.det([B(max(578, 576 + 64 * k), 320, F, 640 + 64 * k, 324, roof_lo[k]) for k in range(3)], MAT["beam"])     # (the wall between the flights)
        r1, r2 = sorted((s * 254, s * 260))                       # the parapet on the upper flight's open side (2 proud of the wall's face)
        m.shapes([prism([(U(744), mid - 8), (U(744), mid + 36), (U(576), deck + 36), (U(576), deck - 8)], "y", r1, r2, MAT["beam"])])
        m.det([B(744, 254, mid - 8, 832, 260, mid + 36)], MAT["beam"])
        m.det([B(312, 248, F, 322, 256, F + 144), B(382, 248, F, 392, 256, F + 144), B(312, 248, F + 144, 392, 256, F + 160)], STEEL)   # the doorway's frame
        m.taken(*B(304, 228, F, 840, 256, deck + 120))
        cage_lamp(m, U(448), s * 384, F + 92, Y(270), "238 226 162 40")
        cage_lamp(m, U(832), s * 352, mid + 72, Y(180), "238 226 162 40")
        m.lane(U(352), s * 290)
        m.lane(U(448), s * 352)
        m.lane(U(800), s * 320, mid)
        # the landing's lip: an arc about the pier, out to meet the bridge's end, on a corbel; the handrail each side of
        # the bridge's end and along the landing's open edge
        m.shapes([vprism([(a[0], s * a[1]), (c[0], s * c[1]), (c[0], s * 256), (a[0], s * 256)], deck - 16, deck, MAT["beam"], MAT["quay_floor"])
                  for a, c in zip(arc, arc[1:])])
        m.shapes([prism([(s * 256, deck - 56), (s * 256, deck - 16), (s * 236, deck - 16)], "x", cu - 64, cu + 64, MAT["beam"])])
        handrail(m, (cu - 64, s * 238), (cu - 32, s * 238), deck)
        handrail(m, (cu + 32, s * 238), (cu + 64, s * 238), deck)
        handrail(m, (min(U(384), U(448)), s * 258), (max(U(384), U(448)), s * 258), deck)
        # the street door on the back wall (Nova Prospekt's heavy door between jambs, shut for good: not the city's
        # door, which opens), the lamp. Beside a street the other bank is the edge of the world, and a bridge from the
        # street to a door nobody can open is pointless (the owner, 23 November): no door there, the landing is the
        # bridge's way down into the canal
        if not street:
            f1, f2 = sorted((s * 304, s * 320))
            p1, p2 = sorted((s * 316, s * 320))
            du = U(432)
            m.det([(du - 39, f1, deck, du - 31, f2, deck + 96), (du + 31, f1, deck, du + 39, f2, deck + 96)], MAT["beam"])
            m.det([(du - 31, p1, deck, du + 31, p2, deck + 96)], "wood/woodwall006a")     # (planked over, never used)
            for z, roll in ((deck + 34, 82), (deck + 72, 99)):
                board(m, du, s * 312, z, Y(270), roll)
        cage_lamp(m, U(556), s * 320, deck + 60, Y(270), "255 220 170 45")
        m.static("models/props_trainstation/light_signal002a.mdl", U(336), s * 214, Y(270), z=deck + 10)    # the signal on the wall beside it
        m.taken(*B(286, 200, deck, 386, 256, deck + 140))
        m.taken(*B(252, 228, deck - 60, 772, 256, deck + 120))
        # the winch against the back wall, the button over it that turns the bridge, and the green lamp over that
        tag = "a" if s > 0 else "b"
        wu = U(507)
        m.static("models/props_canal/winch02.mdl", wu, s * 300, Y(90), z=deck)
        m.button("lc_swing_wheel_" + tag, wu, s * 320, deck + 52, Y(270), [("lc_swing_bell", "PlaySound", "", 0), ("lc_swing_bridge", "Toggle", "", 2)], wait="10")
        sprite(m, "lc_swing_lamp_" + tag, wu - 12, s * 314, deck + 84, "120 255 120", 0.3)
        sprite(m, "lc_swing_red_" + tag, wu + 12, s * 314, deck + 84, "255 50 30", 0.3, on=False)
        sprite(m, "lc_swing_red_%s2" % tag, U(336), s * 168, deck + 90, "255 50 30", 0.35, on=False)
        # the barrier arm across the landing's edge: drawn down, hinged at its end by the wall's corner
        ay = s * (lip + 10)
        brush(m, "func_door_rotating", {
            "targetname": "lc_swing_arm_" + tag, "origin": "%d %d %d" % m.fr.at(cu - 58, ay, deck + 38), "distance": "85", "speed": "40", "wait": "-1", "lip": "0",
            "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": str(32 + (64 if m.fr.ax("v") == "x" else 128)), "health": "0", "ignoredebris": "0",
            "loopmovesound": "0", "noise1": "Doors.Move10", "noise2": "Doors.FullOpen4", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
            "renderfx": "0", "disableshadows": "1"}, [(cu - 60, ay - 2, deck + 35, cu + 50, ay + 2, deck + 41)], "dev/dev_hazzardstripe01a")
        m.det([(cu - 64, ay - 4, deck, cu - 54, ay + 4, deck + 34)], STEEL)      # (its post)
        m.lane(U(480), s * 290, deck)

    # the pier: a round concrete post, a wide drum on it with a toothed ring round it and a motor box driving a pinion,
    # a steel turntable on the drum
    m.shapes([vprism(octagon(cu, 0, 40), F, deck - 72, MAT["beam"]), vprism(octagon(cu, 0, 52), F, F + 24, MAT["canal_wall"]),
              vprism(octagon(cu, 0, 60), deck - 72, deck - 41, MAT["beam"]), vprism(octagon(cu, 0, 48), deck - 41, deck - 32, STEEL),
              vprism(octagon(cu + 70, 0, 7), deck - 70, deck - 46, STEEL)])
    teeth = []
    for k in range(20):
        t = 2 * math.pi * k / 20
        tu, tv = int(round(cu + 61 * math.cos(t))), int(round(61 * math.sin(t)))
        teeth.append((tu - 3, tv - 3, deck - 66 + (k % 2), tu + 3, tv + 3, deck - 50 + (k % 2)))
    m.det(teeth, PIPE)
    m.det([(cu + 78, -14, deck - 96, cu + 102, 14, deck - 62)], "metal/metalhull010c")        # (the motor box, on a bracket off the post)
    m.det([(cu + 36, -6, deck - 100, cu + 80, 6, deck - 96)], STEEL)
    m.blocked(cu - 64, -64, cu + 64, 64)
    # the bridge, drawn across: two steel beams, a plank deck with its arced ends, cross ties; the handrail each side
    # rides on it
    wood = MM["wood"]
    parts = [((cu - wide, -half, deck - 16, cu + wide, half, deck), wood)]
    for s in (1, -1):
        a, c = min(s * 20, s * 28), max(s * 20, s * 28)
        parts.append(((cu + a, -half, deck - 32, cu + c, half, deck - 16), STEEL))
        p = -224
        for n, kind in ((128, "long"), (128, "long"), (128, "long"), (64, "medium")):
            ride(m, "lc_swing_bridge", "models/props_c17/handrail04_%s.mdl" % kind, cu + s * (wide - 2), p + n // 2, 0, deck)
            p += n
    parts += [((cu - 28, v, deck - 30, cu + 28, v + 6, deck - 18), STEEL) for v in (-half + 5, -110, -3, 104, half - 11)]
    for s in (1, -1):                                             # a truss under each beam: posts and a bottom chord
        a, c = min(s * 22, s * 26), max(s * 22, s * 26)
        parts.append(((cu + a, -half + 9, deck - 60, cu + c, half - 9, deck - 56), STEEL))
        parts += [((cu + a, v, deck - 56, cu + c, v + 4, deck - 32), STEEL) for v in range(-half + 9, half - 9, 54)]
    parts.append(((cu - 18, -half + 11, deck - 62, cu + 18, -half + 71, deck - 32), MAT["beam"]))     # the counterweight, under its right end
    shapes = [vprism([(x[0], x[1]), (x[3], x[1]), (x[3], x[4]), (x[0], x[4])], x[2], x[5], mat) for x, mat in parts]
    for s in (1, -1):
        shapes.append(vprism([(u, s * v) for u, v in ends], deck - 16, deck, wood))
    brush_shapes(m, "func_door_rotating", {
        "targetname": "lc_swing_bridge", "origin": "%d %d %d" % (m.fr.at(cu, 0, deck - 16)), "distance": "90", "speed": "12", "wait": "-1", "lip": "0",
        "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": "32", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "locked_sentence": "0",
        "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"}, shapes, connections=[
        ("OnOpen", "lc_swing_move", "PlaySound", "", 0), ("OnClose", "lc_swing_move", "PlaySound", "", 0), ("OnOpen", "lc_swing_lamp_*", "HideSprite", "", 0),
        ("OnFullyOpen", "lc_swing_move", "StopSound", "", 0), ("OnFullyClosed", "lc_swing_move", "StopSound", "", 0), ("OnFullyOpen", "lc_swing_stop", "PlaySound", "", 0),
        ("OnFullyClosed", "lc_swing_stop", "PlaySound", "", 0), ("OnFullyClosed", "lc_swing_lamp_*", "ShowSprite", "", 0),
        ("OnOpen", "lc_swing_red_*", "ShowSprite", "", 0), ("OnOpen", "lc_swing_arm_*", "Close", "", 0), ("OnFullyClosed", "lc_swing_red_*", "HideSprite", "", 0),
        ("OnFullyClosed", "lc_swing_arm_*", "Open", "", 0)])
    sound(m, "lc_swing_move", "Streetwar.d3_c17_11_garage_move1", cu, 0, deck, loops=True, radius=1600, volume=8)
    sound(m, "lc_swing_bell", "ambient/alarms/warningbell1.wav", cu, 0, deck + 40, radius=1800, volume=9)
    m.point("logic_auto", cu, 0, deck + 160, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_swing_arm_*", "Open", "", 0.5)])
    m.soundscape(SCAPES["metal"], cu, 0, F, radius=800)
    sound(m, "lc_swing_stop", "Streetwar.d3_c17_11_garage_stop1", cu, 0, deck, radius=1600, volume=8)
    m.lane(cu, 120, deck)
    m.lane(cu, -120, deck)
    m.view(150, 60, F, 0, -12, "the bridge from the canal")
    m.view(cu + 10, 290, deck, 270, 10, "from the left landing, across the bridge")
    m.view(240, 120, F, 30, 2, "the left bank's doorway and stairs")
    m.view(700, 300, F + 128, 180, 4, "the left bank's half landing, up the upper flight")
    m.view(cu - 40, -280, deck, 60, 6, "on the right landing: the wheel")
    b.notes.append("%s: the bridge turns about (%d %d); its deck is z %d; its ends reach %d out, the landings' lips are %d out, the walls 256" % (
        (m.tag,) + m.fr.pt(cu, 0) + (deck, reach, lip)))


# ---------------------------------------------------------------------------
# 8. The flood room (experimental)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 8. The flood room (experimental)
# ---------------------------------------------------------------------------

MODULES = {
    "lock": (1536, m_lock, "a lock house: two steel gates and the control house that works them"),
    "pumphouse": (1280, m_pumphouse, "a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge"),
    "thumper": (1024, m_thumper, "a Combine thumper on a fenced terrace, with the box that stops it (experimental)"),
    "depot": (1280, m_depot, "the Combine's ration depot: a roller door, a loading bay, caged stores, a staff door"),
    "armory": (1024, m_armory, "a Combine armoury vault behind a two-button door: a heist target"),
    "swingbridge": (1024, m_swingbridge, "a footbridge that turns on a pier: across the canal, or along it (experimental)"),
    "railbridge": (1024, m_railbridge, "a railway bridge: a Combine train crosses every few minutes (experimental)"),
}
