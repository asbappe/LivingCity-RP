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


def fence_gate(m, name, u, v, z, along="u", hinge_low=True):
    """Nova Prospekt's gate (interior_fence001g) hung in its frame (interior_fence002e, 64 wide) whose middle is at
    (u, v), standing on z, in a fence running `along` u or v: players open it by Use (the frame's unseen door of the
    same name turns, the model rides on it; the gamemode's door rules reach it). The owner, of the pit's: the gate
    "has to be fitted inside of the gate frames"."""
    from map_mods_b import swing_door
    yaw = 90 if along == "u" else 0
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
    """A shack whose front is its low-v side, standing on z: a post at each corner, walls of sheets 6 thick, each sheet
    of its own material, some 2 proud of the next, their tops uneven under a tin roof that slopes down to the front and
    overhangs it by 24 on two posts of its own; a doorway 'door' wide a third of the way along the front, and a window
    two thirds along it, 40 by 32 (window: "boards" nailed across, "glass" cracked, or None). open_front: no front wall
    (a stall). front "hi": the same shack facing the high-v side. Returns the doorway's middle (u)."""
    import random
    rnd = random.Random(seed)
    zf, zb = z + high, z + high + 14               # the roof's line over the front and the back walls

    def top(v):
        return zf + (zb - zf) * (v - v1) // (v2 - v1)

    def sheets(a, b):
        out, p = [], a
        while b - p > 0:
            w = min(b - p, rnd.choice((32, 40, 48, 56, 64)))
            if b - p - w < 24:
                w = b - p
            out.append((p, p + w, rnd.choice(SHEETS), rnd.choice((0, 0, 2)), rnd.choice((0, 0, 3, 6))))
            p += w
        return out
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
    boxes += [((u1 - 1, v1 - 1, z, u1 + 6, v1 + 6, zf + 2), POSTS), ((u2 - 6, v1 - 1, z, u2 + 1, v1 + 6, zf + 2), POSTS),
              ((u1 - 1, v2 - 6, z, u1 + 6, v2 + 1, zb), POSTS), ((u2 - 6, v2 - 6, z, u2 + 1, v2 + 1, zb), POSTS)]
    boxes += [((u1 - 10, v1 - 26, z, u1 - 6, v1 - 22, zf - 1), POSTS), ((u2 + 6, v1 - 26, z, u2 + 10, v1 - 22, zf - 1), POSTS)]   # the overhang's posts
    # the roof: one sheet of tin, sloping to the front, overhanging 24 there and 12 at the sides
    rf, rb = v1 - 24, v2 + 8
    zr1 = zf - (zb - zf) * 24 // (v2 - v1) - 1
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
    shows red while a gate moves.

    Inside the lock, on the left bank, a concrete pier (the bank is its ramp, a mooring cleat on it) and stairs up to
    the gantry behind a concrete parapet; on the gantry, behind the city's handrail, the house: a slit each way down
    the canal, a button under each slit's end for the gate on that side, a desk with a monitor and a chair. On the left
    wall at the gantry's end a street door, a Nova Prospekt heavy door that never opens. The right half of the gantry
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
      lc_lock_a_move, lc_lock_a_slam, lc_lock_a_warn, lc_lock_a_shake (and _b_)   the sounds, lamp and shake of each gate.

    Left as brushes: the piers, the beams, sills and slot lips, the gantry, its girders and corbels, the stairs and
    their parapet, the house's walls and roof, the street door's frame (all of them the building).

    Unchecked: the two sounds are the bunker door's (Streetwar.d3_c17_11_garage_move1 / _stop1: the owner has heard
    them there). That a func_button leaf simply stops against a player (no damage, no reversing) is how the bunker's
    leaves behaved before their crushers were added, by its comments; not seen here. How locks_small looks from each
    face (it is the canals' own lock leaf, 65 thick, 163 wide, 291 high: its sizes are read, its faces are not); that
    locks_small_b is its mirror. That a prop rides on a func_button by parentname (it does on doors)."""
    b = m.b
    L, top, deck = 1536, F + 296, TRIM
    quay = MAT["quay_floor"]
    m.open(0, -256, L, 256)
    # the pier inside the lock on the left bank: the dressing gives it a 45 degree bank, which is its ramp
    m.open(448, 192, 576, 256, floor=F + 128, mat=quay)
    m.side(448, 192, 576, 256)
    m.no_bank(440, 192, 456, 256)

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
        for s in (1, -1):
            m.static("models/props_combine/combine_light002a.mdl", mid, s * 192, 180 if g == "a" else 0, z=top + 16)
            sprite(m, pre + "warn_%d" % (1 if s > 0 else 2), mid + (-12 if g == "a" else 12), s * 192, top + 50, "255 60 40", 0.35, on=False)
        m.point("env_shake", mid, 0, F + 140, {"targetname": pre + "shake", "amplitude": "4", "radius": "600", "duration": "1", "frequency": "40", "spawnflags": "0"})
        moving = [(pre + "warn_*", "ShowSprite", "", 0), (pre + "move", "PlaySound", "", 0.5), (pre + "move", "StopSound", "", 4.5), (pre + "slam", "PlaySound", "", 4.5),
                  (pre + "warn_*", "HideSprite", "", 5.2)]
        m.relay(pre + "shut", mid, 40, top + 40, [(pre + "shut", "Disable", "", 0), (name, "PressOut", "", 0.5), (pre + "shake", "StartShake", "", 4.5)] + moving
                + [(pre + "open", "Enable", "", 5.5)], on=True)
        m.relay(pre + "open", mid, -40, top + 40, [(pre + "open", "Disable", "", 0), (name, "PressIn", "", 0.5)] + moving + [(pre + "shut", "Enable", "", 5.5)], on=False)
    m.point("logic_auto", 768, 0, deck + 150, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_lock_gate_*", "PressIn", "", 0.5)])

    # the stairs from the pier to the gantry, on a plinth, with a concrete parapet on the open side
    m.steps(528, 192, 256, F + 128, deck, "u", 1)
    m.det([(576, 192, F, 720, 256, F + 128)], MAT["canal_wall"])
    m.shapes([prism([(528, F + 128), (528, F + 164), (720, deck + 36), (720, deck)], "y", 192, 198, MAT["beam"])])
    m.blocked(448, 128, 720, 256)
    m.lane(500, 224, F + 128)
    m.lane(624, 224, F + 192)

    # the gantry: a slab on two steel girders from wall to wall, corbels under their ends
    g1, g2 = 720, 912
    m.det([(g1, -256, deck - 16, g2, 256, deck)], MAT["beam"], top=quay)
    m.det([(g1 + 8, -256, deck - 48, g1 + 24, 256, deck - 16), (g2 - 24, -256, deck - 48, g2 - 8, 256, deck - 16)], STEEL)
    m.shapes([prism([(s * 256, deck - 112), (s * 256, deck - 48), (s * 192, deck - 48)], "x", u, u + 32, MAT["beam"]) for s in (1, -1) for u in (g1, g2 - 32)])
    m.taken(g1, -256, deck - 112, g2, 256, deck + 130)
    handrail(m, (g1 + 2, -256), (g1 + 2, 192), deck)
    handrail(m, (g2 - 2, -256), (g2 - 2, 256), deck)
    # the street door on the left wall: Nova Prospekt's heavy door, shut for good (not the city's door: that one opens)
    m.det([(785, 252, deck, 847, 256, deck + 112)], MAT["black"])
    m.det([(777, 240, deck, 785, 256, deck + 120), (847, 240, deck, 855, 256, deck + 120), (777, 240, deck + 112, 855, 256, deck + 120)], MAT["beam"])
    m.static("models/props_wasteland/prison_heavydoor001a.mdl", 816, 246, 270, z=deck)

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
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 816, -78, 90, z=deck + 1)
    m.static("models/props_wasteland/controlroom_monitor001a.mdl", 800, -86, 90, z=deck + 35)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 816, -34, 270, z=deck + 1)
    m.lamp(816, 0, hz - 8, "255 214 160 50")
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
    m.static("models/props_c17/light_cagelight02_on.mdl", 512, 255, 270, z=F + 250)
    m.light(512, 240, F + 256, "255 220 170 120")
    m.static("models/props_c17/oildrum001.mdl", 480, 228, 0, z=F + 128)
    m.static("models/props_docks/dock01_cleat01a.mdl", 462, 210, 90, z=F + 128)
    m.loose("models/props_junk/wood_crate001a.mdl", 980, -90, 20)
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
    to hide the whole train. The signal lamps are caged lamps on the mouths' pilasters, a red glow in front of each.

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
    In a --test file a red button on the left pier's canal face triggers lc_rail_run.
    An areaportal stands 64 inside each tunnel, walled all round; the train passes through both.

    Left as brushes: the tunnels, the bridge (girders, bed, cross girders, abutments, piers) and the track: the only
    track models (traintrack001c, 006b, 006c) are 288 wide and more, too wide for the 128 bed.

    Unchecked: everything above about func_tracktrain and path_track is from memory of Hammer's entity list (the
    keys "startspeed", "speed", "orientationtype", "height", "wheels", "bank", "dmg", "MoveSound", "volume"; the
    spawnflags; that a path_track with spawnflag 16 is teleported to; the inputs StartForward and Stop; the output
    OnPass). The sounds are from memory: ambient/alarms/train_horn2.wav, ambient/machines/razor_train_wheels_loop1.wav.
    If the train comes out sideways, the fixed orientation did not take: tell me. If it never moves, try "speed" 0.
    That train005 is a flat car (its size is read: 118 wide, 460 long, 54 high; its look is not), and which of its
    ends is its front (it is the same both ways round in its size)."""
    b = m.b
    L, rim, c, far = 1024, b.rim, 480, 1280
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
        for v in (448, 704, 960, 1216):
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
        # the signal lamp on the mouth's pilaster: a caged lamp, its red glow in front of it
        m.static("models/props_c17/light_cagelight02_off.mdl", c - wide - 8, s * 238, 270 if s > 0 else 90, z=D + 62)
        sprite(m, "lc_rail_signal_%d" % (1 if s > 0 else 2), c - wide - 8, s * 228, D + 70, "255 50 30", 0.4, on=False)
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

    # the train, standing where it waits: the left tunnel, its middle on lc_rail_p1. The tracktrain itself is unseen;
    # two flat cars (train005, 460 long) ride on it, one with two bundles of steel beams, one with three crates
    tv, base = 800, D + 6
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
    m.lamp(c, 6, D - 48, "255 214 160 60")         # (its dome against the cross girder over the middle)
    m.loose("models/props_junk/wood_crate001a.mdl", c + 70, -60, 25)
    m.loose("models/props_junk/wood_crate002a.mdl", c - 90, 40, 70)
    m.loose("models/items/item_item_crate.mdl", c + 20, 70, 10)
    m.static("models/props_debris/concrete_chunk01a.mdl", c + 130, 96, 40)
    m.lane(c, 0)
    m.view(180, -40, F, 8, -14, "the bridge from the canal")
    m.view(c + 360, -170, F, 138, -16, "the left tunnel's mouth and the bridge")
    m.view(c - 56, 300, D, 86, 2, "in the left tunnel: the train where it waits")
    m.view(c + 60, 40, F, 200, -30, "under the bridge")
    b.notes.append("%s: the rails are at z %d (the walls' top less 144); the train waits at (%d %d) and stops at (%d %d)" % (
        (m.tag, D + 6) + m.fr.pt(c, tv) + m.fr.pt(c, -tv)))


def m_pumphouse(m, opt):
    """The pumping station: off the left wall, through a wide doorway, a machine hall 704 by 512 and 320 high. Facing
    the door a big iron wheel (Half-Life 2's wheel02b, 132 across) turns slowly (lc_pump_wheel) on the shaft of the
    pump, a long horizontal tank on the floor behind it (horizontalcoolingtank04); two risers climb from it to a
    header pipe under the roof, capped at both ends. Behind it a turbine pit (192 square, 96 deep, ankle deep in water,
    steps down into it, the city's handrail round it, the turbine's casing standing in it). The main leaves through the
    front wall, runs along the canal wall and crosses the canal overhead on a pipe bridge nobody can reach. A steel
    gallery runs round the hall 144 up behind the handrail (stairs in the corner left of the door, a steel plate along
    their open side); on it, over the door, the control desk: a monitor, a lamp, and the button that stops and starts
    the pumps. The door that shuts the doorway (a sliding gate) stands slid open along the wall inside.

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

    Left as brushes: the hall, the doorway's frame, the gallery (its grating and posts), the steel plate along the
    stairs, the wheel's bearing pedestal, the pipe bridge's girders and the plates where pipes meet the walls.

    Unchecked: func_rotating's keys from memory ("maxspeed" 40 degrees a second, "fanfriction", spawnflags 1 start on +
    16 run up and down + 64 not solid, and 4 or 8 for the axle: if the wheel tumbles instead of turning, those two are
    the other way round). That a prop parented to a func_rotating turns with it. Sounds from memory:
    ambient/machines/pump_loop_1.wav, ambient/machines/thumper_shutdown1.wav, ambient/machines/thumper_startup1.wav.
    Material metal/metalgrate013a passes the assets check; how it looks as a floor is not known. How the models look
    (their sizes are read): wheel02b as a flywheel, the cooling tank as a pump, substation_transformer01c as the
    turbine's casing, slidinggate001 as the door."""
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
    m.blocked(320, 320, 384, 544)
    # the doorway's steel frame on the canal side, and the door itself (a sliding gate) slid open along the wall inside
    m.det([(568, 248, F, 576, 256, F + 152), (768, 248, F, 776, 256, F + 152), (568, 248, F + 144, 776, 256, F + 160)], STEEL)
    m.taken(560, 232, F, 784, 256, F + 168)
    m.static("models/props_c17/slidinggate001.mdl", 852, 323, 90, z=F)

    # the gallery: steel grating on posts, the city's handrail on its open edge, stairs up in the corner left of the door
    m.det([(320, 768, G - 8, 1024, 832, G), (320, 536, G - 8, 384, 768, G), (960, 320, G - 8, 1024, 768, G), (384, 320, G - 8, 960, 384, G)], PIPE, top=grate)
    m.det([(u, v, F, u + 6, v + 6, G - 8) for u, v in ((384, 536), (378, 762), (540, 762), (804, 762), (954, 762), (954, 560), (954, 378), (804, 378), (540, 378), (386, 378))], PIPE)
    m.steps(320, 320, 384, F, G, "v", 1)
    m.shapes([prism([(320, F), (320, F + 36), (536, G + 36), (536, G)], "x", 382, 386, STEEL)])
    handrail(m, (384, 770), (960, 770), G)
    handrail(m, (382, 544), (382, 768), G)
    handrail(m, (962, 384), (962, 768), G)
    handrail(m, (384, 382), (608, 382), G)
    handrail(m, (736, 382), (960, 382), G)
    handrail(m, (386, 320), (386, 384), G)

    # the turbine pit: steps down along its near side, the handrail round it, the turbine's casing in the water
    m.steps(784, 576, 608, F - 96, F, "v", -1)
    handrail(m, (608, 638), (768, 638), F)
    handrail(m, (574, 640), (574, 832), F)
    handrail(m, (770, 640), (770, 832), F)
    m.static("models/props_c17/substation_transformer01c.mdl", cx, 736, 0, z=F - 96)
    m.light(cx, 680, F - 30, "120 200 190 35")

    # the machines: the wheel on its pedestal, its shaft into the pump, two risers to the header
    wz = F + 80
    brush_shapes(m, "func_rotating", {
        "targetname": "lc_pump_wheel", "origin": "%d %d %d" % (m.fr.at(cx, 448, wz)), "spawnflags": str(1 + 16 + 64 + (4 if m.fr.ax("v") == "x" else 8)),
        "maxspeed": "40", "fanfriction": "20", "volume": "0", "dmg": "0", "solidbsp": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255",
        "disableshadows": "1"}, [], boxes=[(cx - 8, 440, wz - 8, cx + 8, 456, wz + 8)], mat=MAT["nodraw"], vis=b.vis + ": the wheel")
    ride(m, "lc_pump_wheel", "models/props_wasteland/wheel02b.mdl", cx, 448, 0, wz - 66)
    m.world((cx - 72, 420, F, cx + 72, 476, wz + 72), MAT["clip"], seals=False)
    m.det([(cx - 14, 476, F, cx + 14, 492, wz + 10)], MAT["beam"])
    m.static("models/props_pipes/pipe03_straight01_short.mdl", cx, 488, 0, z=wz - 8)
    m.static("models/props_wasteland/horizontalcoolingtank04.mdl", cx, 552, 0, z=F)
    hz = F + 264
    for s in (1, -1):
        centred(m, "models/props_pipes/pipecluster08d_extender128.mdl", cx + s * 140, 552, 0, F + 184)
        m.static("models/props_c17/pipe_cap005.mdl", cx + s * 192, 552, 0 if s > 0 else 180, z=hz - 19)
    pipe_run(m, (cx - 192, 552), (cx + 192, 552), hz, "32d")
    pipe_run(m, (cx, 296), (cx, 552), hz, "32d")

    # outside: the main along the canal wall, then across on the pipe bridge (its middle at pu)
    pu = cx + 384
    m.det([(cx - 32, 240, hz - 32, cx + 32, 256, hz + 32), (pu - 32, -256, hz - 32, pu + 32, -240, hz + 32)], STEEL)
    pipe_run(m, (cx, 220), (pu, 220), hz, "32d")              # (clear of the trim line on the wall: it rests on it)
    m.static("models/props_c17/pipe_cap005.mdl", cx, 220, 180, z=hz - 19)    # (its start, at the plate where it leaves the hall, capped)
    pipe_run(m, (pu, -256), (pu, 256), hz, "32d")
    m.det([(pu - 40, -256, hz - 48, pu - 32, 256, hz - 32), (pu + 32, -256, hz - 48, pu + 40, 256, hz - 32)], STEEL)
    m.det([(pu - 40, v, hz - 32, pu + 40, v + 6, hz - 26) for v in range(-232, 240, 96)], PIPE)
    m.taken(cx - 40, 200, hz - 56, pu + 48, 256, hz + 40)
    m.taken(pu - 48, -256, hz - 56, pu + 48, -200, hz + 40)

    # the control desk on the gallery over the door: a monitor, the lamp, the button on its top
    m.static("models/props_wasteland/controlroom_desk001b.mdl", cx, 363, 270, z=G)
    m.static("models/props_wasteland/controlroom_monitor001a.mdl", cx - 24, 368, 270, z=G + 34)
    m.button("lc_pump_button", cx + 18, 352, G + 34, 270, [("lc_pump_stop", "Trigger", "", 0), ("lc_pump_start", "Trigger", "", 0)], wait="3.5")
    m.static("models/props_combine/combine_light002a.mdl", cx + 44, 372, 270, z=G + 34)
    sprite(m, "lc_pump_glow", cx + 44, 370, G + 74, "120 255 140", 0.2)
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
    m.static("models/props_c17/shelfunit01a.mdl", 880, 820, 180)
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
    m.view(cx, 340, F, 90, 0, "the hall from the door: the wheel")
    m.view(cx - 80, 344, G, 62, 16, "from the control desk")
    m.view(440, 690, F, 345, 8, "the pit and the pump")
    m.view(1180, -100, F, 190, -24, "the pipe bridge")
    b.notes.append("%s: the hall's floor is z %d, its gallery z %d, its roof z %d; the pit's floor z %d under %d of water" % (m.tag, F, G, H, F - 96, 24))


# ---------------------------------------------------------------------------
# 4. The thumper (experimental)
# ---------------------------------------------------------------------------

def m_thumper(m, opt):
    """EXPERIMENTAL: a Combine thumper. The canal widens to the right into a concrete terrace 512 long and 384 deep,
    128 over the floor (the bank is its ramp). On it, behind a fence of Nova Prospekt's chain link panels with a gate
    players open, Half-Life 2's own thumper (prop_thumper, the coast's CombineThumper002, 338 high) on a concrete
    plinth: it lifts and drops its hammer by itself, shakes the ground, thuds and keeps antlions away, for ever. Each
    time it lands dust jumps from the plinth. Against the terrace's near wall a Combine console, a lamp over it and the
    button that stops and starts it.

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

    Left as brushes: the terrace and the thumper's plinth (the ground it stands on).

    Unchecked: prop_thumper's keys and its input and output from memory of Half-Life 2's coast ("dustscale",
    "EffectRadius", Enable, Disable, OnThumped); that it starts running by itself; which way the model faces (it is
    placed so its box is centred on the plinth). env_smokestack's TurnOn and TurnOff for the dust. Sounds from memory:
    ambient/machines/thumper_hit.wav, ambient/machines/thumper_top.wav, ambient/machines/thumper_shutdown1.wav."""
    b = m.b
    L, P = 1024, F + 128
    cu, cv = 512, -448
    m.open(0, -256, L, 256)
    m.open(256, -640, 768, -256, floor=P, mat=MAT["quay_floor"])
    m.side(256, -640, 768, -256)
    m.taken(256, -264, F, 768, -256, P + 100)
    m.blocked(256, -640, 768, -256)
    # the fence across the terrace, 48 back from its edge, with the gate in its frame
    fv = -304
    panel_fence(m, (256, fv), (576, fv), P)
    panel_fence(m, (640, fv), (768, fv), P)
    fence_gate(m, "lc_thumper_gate", 608, fv, P, "u")
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
    m.static("models/props_c17/light_cagelight02_off.mdl", 258, -404, 0, z=P + 96)
    sprite(m, "lc_thumper_glow", 268, -404, P + 104, "120 220 255", 0.35)
    m.light(276, -404, P + 104, "120 200 255 40")
    m.button("lc_thumper_button", 256, -340, P + 36, 0, [("lc_thumper_stop", "Trigger", "", 0), ("lc_thumper_start", "Trigger", "", 0)], wait="2.5")
    toggle(m, "lc_thumper_stop", "lc_thumper_start", 270, -404, P + 160,
           [("lc_thumper_head", "Disable", "", 0), ("lc_thumper_timer", "Disable", "", 0), ("lc_thumper_glow", "HideSprite", "", 0), ("lc_thumper_down", "PlaySound", "", 0)],
           [("lc_thumper_timer", "Enable", "", 0), ("lc_thumper_head", "Enable", "", 0), ("lc_thumper_glow", "ShowSprite", "", 0)], 2)
    # outside the fence: two Combine barricades at the ramp's head; inside: what the crew left
    m.dynamic("models/props_combine/combine_barricade_short01a.mdl", 330, -280, 90, z=P)
    m.dynamic("models/props_combine/combine_barricade_short01a.mdl", 720, -280, 90, z=P)
    m.static("models/props_c17/oildrum001.mdl", 720, -600, 0, z=P)
    m.loose("models/props_junk/wood_crate001a.mdl", 690, -560, 20, z=P)
    m.lane(608, -280, P)
    m.lane(608, -350, P)
    m.lane(360, -400, P)
    m.view(512, 150, F, 270, -16, "the thumper from the canal")
    m.view(700, -280, P, 205, -10, "at the fence, by the gate")
    m.view(330, -560, P, 40, -20, "inside, by the console")
    b.notes.append("%s: the terrace is z %d; the thumper stands at (%d %d), its top z %d (%d over the walls)" % (
        (m.tag, P) + m.fr.pt(cu, cv) + (top, top - b.rim)))


# ---------------------------------------------------------------------------
# 5. The ration depot
# ---------------------------------------------------------------------------

def m_depot(m, opt):
    """The Combine's ration depot: a place to raid. In the left wall the Combine's own big door (combine_door01, 192
    wide and high: lc_depot_door, shut) opens straight off the canal's floor into a loading bay with a truck backed up
    to a dock 40 high, tyres hung on its edge. The dock runs along the back (pallets of crates) and fills the far half of
    the hall: three cages of Nova Prospekt's chain link panels against the back wall, a shelf unit, cartons and crates
    in each, each with its own gate in its frame (lc_depot_cage_1 to _3: Use opens them, the gamemode can lock them),
    the dispatch desk with a Combine console (lc_depot_desk), and a roller conveyor that carries crates out through a
    low hatch in the wall and down a chute to the canal (the hatch is 26 high over the rollers: nobody gets in that
    way). At the far end a staff door (lc_depot_side, one of the city's doors) up the steps from the canal: no Use
    opens it, only the button beside it inside, and it shuts by itself after four seconds. A caged lamp on the wall
    over each door.

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
    In a --test file a red button in the roller door's mouth opens and shuts it from outside, as the game will.
    Areaportals: one inside the thickness of each door, one in the hatch.

    Left as brushes: the hall, the dock and its steel edge, the steps, the doors' frames, the cages' mesh roof (no
    model lies flat), the roller conveyor and its chute (Half-Life 2 has no conveyor), the hatch's shutter and the
    concrete cheeks in the bank.

    Unchecked: prop_door_rotating's spawnflag 32768 (ignore Use) and "returndelay" 4; that combine_door01 stands shut
    as a prop_dynamic (it has its own animation) and which of its faces is its front. All models pass the assets check;
    the truck's, the console's and the shelf unit's facing are guesses."""
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

    # the big door: the Combine's door (its box centred in the mouth) riding on an unseen door that lifts it into the
    # wall; a steel frame round the mouth, a caged lamp over it
    from map_mods_b import slide_door
    slide_door(m, "lc_depot_door", [((384, 272, F, 576, 304, F + 192), STEEL)], "-90 0 0", speed=40, lip=8, unseen=True)
    ride(m, "lc_depot_door", "models/props_combine/combine_door01.mdl", 468, 276, 0, F)
    m.det([(376, 248, F, 384, 256, F + 200), (576, 248, F, 584, 256, F + 200), (376, 248, F + 192, 584, 256, F + 208)], PIPE)
    m.static("models/props_c17/light_cagelight02_on.mdl", 480, 255, 270, z=F + 214)
    m.light(480, 240, F + 220, "255 214 160 80")
    m.button("lc_depot_button_door", 364, 320, F + 44, 90, [("lc_depot_door", "Toggle", "", 0)], wait="2")
    m.test_button((568, 262, F + 48, 576, 274, F + 64), [("OnIn", "lc_depot_door", "Open"), ("OnOut", "lc_depot_door", "Close")])

    # the dock: a steel edge and old tyres hung on it toward the bay, steps up beside the door
    m.det([(636, 320, DK - 6, 640, 576, DK), (256, 572, DK - 6, 640, 576, DK)], PIPE)
    for u in (420, 540):
        m.static("models/props_vehicles/tire001c_car.mdl", u, 572, 270, z=DK - 34)
    for v in (432, 512):
        m.static("models/props_vehicles/tire001c_car.mdl", 636, v, 180, z=DK - 34)
    m.steps(580, 320, 384, F, DK, "u", 1)
    m.blocked(576, 320, 640, 384)
    m.static("models/props_vehicles/truck001a.mdl", 468, 448, 270)
    m.blocked(400, 320, 544, 576)
    # the back of the dock: pallets of crates waiting to go
    for k, (u, v, n) in enumerate(((312, 648, 2), (410, 652, 1), (520, 644, 2))):
        m.static("models/props_junk/wood_pallet001a.mdl", u, v, 90 if k % 2 else 0, z=DK)
        for j in range(n):
            m.loose("models/props_junk/wood_crate001a.mdl", u, v, 8 * k + 20 * j, z=DK + 9 + 40 * j)
    m.loose("models/items/item_item_crate.mdl", 590, 600, 30, z=DK)

    # the cages: Nova Prospekt's panels (129 high) with a mesh roof, two partitions, a gate in its frame each; in each
    # a shelf unit against the back wall, cartons stacked on the floor, a crate
    cz, fv = DK, 608
    for k in range(3):
        a = 640 + 128 * k
        panel_fence(m, (a, fv), (a + 32, fv), cz)
        panel_fence(m, (a + 96, fv), (a + 128, fv), cz)
        fence_gate(m, "lc_depot_cage_%d" % (k + 1), a + 64, fv, cz, "u")
        panel_fence(m, (a, fv), (a, 704), cz)
        m.static("models/props_c17/shelfunit01a.mdl", a + 64, 694, 180, z=cz)
        cu = a + (26 if k % 2 else 102)
        m.static("models/props_junk/cardboard_box001a.mdl", cu, 664, 0, z=cz)
        m.static("models/props_junk/cardboard_box002a.mdl", cu, 664, 10, z=cz + 24)
        m.static("models/props_junk/cardboard_box001a.mdl", cu, 628, 90, z=cz)
        m.loose("models/items/item_item_crate.mdl", a + (96 if k % 2 else 34), 640, 10 + 30 * k, z=cz)
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
    m.shapes([prism(cheek, "x", u, u + 8, MAT["beam"]) for u in (760, 832, 888, 960)])
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
    m.static("models/props_c17/light_cagelight02_on.mdl", 928, 255, 270, z=DK + 126)
    m.light(928, 240, DK + 132, "255 60 40 25")

    # the dispatch desk: the console against the end wall, a counter, a chair, a cabinet
    m.dynamic("models/props_combine/combine_interface001.mdl", 996, 500, 180, z=DK, name="lc_depot_desk")
    m.static("models/props_wasteland/controlroom_desk001b.mdl", 900, 504, 0, z=DK)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 946, 500, 0, z=DK)
    m.static("models/props_wasteland/controlroom_filecabinet002a.mdl", 1006, 400, 180, z=DK)
    m.loose("models/props_junk/cardboard_box002a.mdl", 900, 480, 20, z=DK + 34)
    for u, v in ((448, 448), (832, 480), (420, 640), (840, 656)):
        m.lamp(u, v, HC - 8, "255 226 180 55")
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
    it takes two people (a caged lamp over each glows green for the two seconds its press counts). Pressed together
    again, they shut it. Inside the vault (384 by 256): gun lockers along one wall, ammunition crates along the other
    with guns and boxes of rounds laid on them, more crates stacked by the door, and the Combine's weapon frame
    (weaponstripper) against the far wall with three pulse rifles standing in front of it under a blue glow. A button
    inside by the door opens it, so nobody is shut in. A red alarm lamp hangs in the corridor by the door.

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
    Areaportals: one in the entry, one inside the vault door's thickness.

    Left as brushes: the corridor, its Combine plates and ribs, the booth's wall with its slit, the door's jambs and
    head, the plinth the rifles stand on.

    Unchecked: the wiring is the owner's nest door's (math_counter Add and Subtract, OnHitMax) and the sounds are the
    bunker's and the nest's, heard there. The rifles are prop_dynamics turned to stand on their butts ("angles" -90
    pitch), the guns on the crates turned on their sides (roll 90): which way a weapon model's barrel lies is from its
    size alone. The weapon and ammunition models pass the assets check as prop_dynamic; whether the gamemode lets
    players pick such props up is its affair. How weaponstripper looks as a rack (its size is read)."""
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
    m.det([(440, 244, F, 448, 256, CH + 8), (576, 244, F, 584, 256, CH + 8), (440, 244, CH, 584, 256, CH + 16)], CMB)
    m.det([(448, 320, F, 452, 652, CH), (572, 512, F, 576, 652, CH)], CMB)
    m.det([(448, v, CH - 6, 576, v + 12, CH) for v in range(340, 640, 60)], PIPE)
    # the booth's wall: Combine metal 16 thick, a doorway at the entry's end, a slit 24 high further on
    wu, zs = 576, F + 44
    m.det([(wu, 320, F, wu + 16, 332, CH), (wu, 388, F, wu + 16, 512, zs), (wu, 388, zs + 24, wu + 16, 512, CH), (wu, 388, zs, wu + 16, 412, zs + 24),
           (wu, 492, zs, wu + 16, 512, zs + 24), (wu, 332, F + 96, wu + 16, 388, CH)], CMB)
    m.det([(wu - 2, 408, zs - 4, wu + 18, 496, zs), (wu - 2, 408, zs + 24, wu + 18, 496, zs + 28)], PIPE)
    m.dynamic("models/props_combine/combine_intmonitor001.mdl", 756, 380, 180)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 650, 452, 180)
    m.static("models/props_c17/lockers001a.mdl", 720, 500, 270)
    m.lamp(680, 416, CH - 8, "200 220 255 45")
    m.lamp(512, 420, CH - 8, "200 220 255 45")
    m.lamp(512, 560, CH - 8, "200 220 255 40")

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
    for tag, u, v, out in (("a", 768, 484, 180), ("b", 452, 616, 0)):
        du = -10 if out == 180 else 10
        m.static("models/props_c17/light_cagelight02_off.mdl", u + (-2 if out == 180 else 2), v, out, z=F + 74)
        sprite(m, "lc_armory_lamp_" + tag, u + du, v, F + 82, "120 255 120", 0.3, on=False)
        m.button("lc_armory_button_" + tag, u, v, F + 40, out,
                 [("lc_armory_count", "Add", "1", 0), ("lc_armory_count", "Subtract", "1", 2), ("lc_armory_lamp_" + tag, "ShowSprite", "", 0),
                  ("lc_armory_lamp_" + tag, "HideSprite", "", 2), ("lc_armory_blip", "PlaySound", "", 0)], wait="2.2")
    moving = [("lc_armory_alarm", "PlaySound", "", 0), ("lc_armory_alarm", "PlaySound", "", 1.7), ("lc_armory_light", "TurnOn", "", 0), ("lc_armory_groan", "PlaySound", "", 0.4),
              ("lc_armory_move", "PlaySound", "", 1), ("lc_armory_move", "StopSound", "", 7), ("lc_armory_slam", "PlaySound", "", 7), ("lc_armory_shake", "StartShake", "", 7),
              ("lc_armory_light", "TurnOff", "", 9)]
    m.relay("lc_armory_open", 500, 580, F + 100, [("lc_armory_open", "Disable", "", 0), ("lc_armory_door", "PressIn", "", 1)] + moving + [("lc_armory_shut", "Enable", "", 9.5)], on=True)
    m.relay("lc_armory_shut", 524, 580, F + 100, [("lc_armory_shut", "Disable", "", 0), ("lc_armory_door", "PressOut", "", 1)] + moving + [("lc_armory_open", "Enable", "", 9.5)], on=False)
    m.button("lc_armory_button_exit", 620, 704, F + 40, 90, [("lc_armory_open", "Trigger", "", 0)], wait="10")

    # the vault: gun lockers along the left wall; along the back wall ammunition crates, guns and rounds laid on them
    def gun(model, u, v, yaw, z, pitch=0, roll=0):
        m.point("prop_dynamic", u, v, z, {"model": model, "angles": "%d %d %d" % (pitch, m.fr.yaw(yaw), roll), "solid": "0", "skin": "0", "disableshadows": "1",
                                          "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                                          "rendercolor": "255 255 255"}, m.pv)
    for v in (744, 792, 840, 888):
        m.static("models/props_c17/lockers001a.mdl", 329, v, 0)
    for k, u in enumerate((420, 500, 580)):
        m.dynamic("models/items/ammocrate_%s.mdl" % ("smg1", "ar2", "smg1")[k], u, 943, 270)
        gun("models/weapons/w_shotgun.mdl" if k != 1 else "models/weapons/w_smg1.mdl", u - 8, 940, 0, F + 37, roll=90)
        m.dynamic("models/items/boxmrounds.mdl", u + 18, 948, 0, z=F + 34, solid=False)
    # the weapon frame on the far wall, three pulse rifles standing on their butts on a plinth in front of it
    fu = 704
    m.static("models/props_combine/weaponstripper.mdl", fu - 17, 832, 180)
    m.det([(fu - 54, 796, F, fu - 36, 868, F + 8)], CMB)
    for v in (806, 832, 858):
        gun("models/weapons/w_irifle.mdl", fu - 45, v, 180, F + 27, pitch=-90)
    m.glow(fu - 50, 832, F + 100, "120 200 255", 0.5)
    m.light(fu - 60, 832, F + 90, "120 200 255 30")
    m.rope([(fu - 10, 790, F + 129), (fu - 10, 720, VH - 4)], slack=20)
    # ammunition: crates stacked in the corner by the door, one under the frame's end, loose crates
    for u, v, yaw, z in ((372, 740, 0, 0), (372, 800, 0, 0), (372, 770, 10, 34), (430, 736, 90, 0), (640, 930, 90, 0), (660, 740, 0, 0)):
        m.dynamic("models/items/ammocrate_%s.mdl" % ("smg1", "ar2", "grenade")[(u + v) // 10 % 3], u, v, yaw, z=F + z)
    m.loose("models/items/item_item_crate.mdl", 470, 800, 20)
    m.loose("models/items/item_item_crate.mdl", 520, 860, 65)
    m.lamp(512, 832, VH - 8, "255 236 200 70")
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

def m_swingbridge(m, opt):
    """EXPERIMENTAL: a footbridge at the trim's height that turns on a round pier in the middle of the canal. As the
    map starts it lies across, from a landing in the left wall to one in the right; turned a quarter it lies along the
    canal and joins nothing. Each landing is a roofed alcove with a street door (Nova Prospekt's heavy door, shut for
    good), a green lamp that shows while the bridge is across, the city's handrail each side of the bridge's end, and
    at its back wall the canal's winch with the button over it that turns the bridge (a press is Toggle). Each has its
    own stairs from the canal floor: a covered flight in the wall, open to the canal on its side behind a concrete
    parapet, running away from the bridge (the left one toward the module's exit, the right one toward its entry).
    Whoever turns the bridge away strands the other bank at that height.

    The bridge is 456 long and 64 wide: a plank deck on two steel beams, one func_door_rotating, with the city's
    handrail along both sides riding on it (prop_dynamics parented to it). Its corners sweep a circle 461 across;
    the canal is 512 wide and the landings' lips stop 234 from the pier's middle, so it sweeps through nothing (ribs
    and drain stubs are kept off the walls there; the walls' trim line stands 240 out). A gap of 6 is left at each end.
    It has no damage of its own.

    Named for the game:
      lc_swing_bridge    the bridge: Toggle (or Open: along the canal; Close: across). 12 degrees a second.
      lc_swing_wheel_a   the button over the winch on the left landing.     lc_swing_wheel_b   the same on the right.
      lc_swing_lamp_a, lc_swing_lamp_b   the green lamps (env_sprites): lit while the bridge is across.
      lc_swing_move, lc_swing_stop       the turning sound (looping) and the clank as it comes to rest.

    Unchecked: a func_door_rotating this big, turning about its middle with people on it: the engine carries riders
    round on a turning brush, but how well is only seen in the game. Spawnflags 32 (toggle) and no Use; outputs OnOpen,
    OnClose, OnFullyOpen, OnFullyClosed for the sound and lamps. With "wait" -1 a blocked door does not turn back: it
    waits, pushing. Sounds are the bunker door's (heard there). That handrails parented to the turning bridge turn
    with it (props ride on doors so). Which way the winch faces.

    Left as brushes: the bridge's deck and beams (a bridge deck), the pier and its turntable, the landings, their lips
    and corbels, the stairs and their parapets, the doors' jambs."""
    b = m.b
    L, cu, deck = 1024, 512, TRIM
    half, wide = 228, 32
    reach = int((half * half + wide * wide) ** 0.5) + 1          # how far a corner swings out
    lip = 234
    if reach >= lip:
        b.problems.append("%s: the bridge's corners (%d out) would hit the landings' lips (%d out)" % (m.tag, reach, lip))
    m.open(0, -256, L, 256)
    for s in (1, -1):                                             # s 1: the left bank, its stairs toward the exit; -1: the right, toward the entry
        def V(a, c):
            return (min(s * a, s * c), max(s * a, s * c))
        w1, w2 = V(256, 320)
        m.low(cu - 64, w1, cu + 64, w2, deck + 112, floor=deck, mat=MAT["quay_floor"])
        for i in range(6):
            a = cu + s * (64 + 64 * i)
            top = deck - (64 * i * 8) // 12
            m.low(min(a, a + s * 64), w1, max(a, a + s * 64), w2, min(deck + 112, (top + 136) // 8 * 8))
        m.side(min(cu - s * 64, cu + s * 448), w1, max(cu - s * 64, cu + s * 448), w2)
        m.blocked(min(cu - s * 64, cu + s * 448), w1, max(cu - s * 64, cu + s * 448), w2)
        m.steps(cu + s * 448, w1, w2, F, deck, "u", -s)
        # a concrete parapet down the flight's open side
        r1, r2 = V(256, 262)
        lo, hi = cu + s * 64, cu + s * 448
        m.shapes([prism([(hi, F), (hi, F + 36), (lo, deck + 36), (lo, deck)], "y", r1, r2, MAT["beam"])])
        # the landing: its lip out toward the bridge on a corbel, the handrail each side of the bridge's end, the street
        # door (Nova Prospekt's heavy door between jambs, shut for good: not the city's door, which opens), a lamp
        l1, l2 = V(lip, 256)
        m.det([(cu - 64, l1, deck - 16, cu + 64, l2, deck)], MAT["beam"], top=MAT["quay_floor"])
        m.shapes([prism([(s * 256, deck - 56), (s * 256, deck - 16), (s * lip, deck - 16)], "x", cu - 64, cu + 64, MAT["beam"])])
        handrail(m, (cu - 64, s * (lip + 4)), (cu - 32, s * (lip + 4)), deck)
        handrail(m, (cu + 32, s * (lip + 4)), (cu + 64, s * (lip + 4)), deck)
        f1, f2 = V(304, 320)
        du = cu - s * 24                                          # the door's middle: on the landing's side away from the stairs
        m.det([(du - 39, f1, deck, du - 31, f2, deck + 112), (du + 31, f1, deck, du + 39, f2, deck + 112)], MAT["beam"])
        m.static("models/props_wasteland/prison_heavydoor001a.mdl", du, s * 314, 270 if s > 0 else 90, z=deck)
        m.lamp(cu, s * 290, deck + 104, "255 220 170 45")
        m.taken(cu - 260, V(228, 256)[0], deck - 60, cu + 260, V(228, 256)[1], deck + 120)
        # the winch at the back wall, the button over it that turns the bridge, and the green lamp over that
        tag = "a" if s > 0 else "b"
        wu = cu + s * 44                                          # (between the door's jamb and the stairs' head)
        m.static("models/props_canal/winch02.mdl", wu, s * 290, 0 if s > 0 else 180, z=deck)
        m.button("lc_swing_wheel_" + tag, wu, s * 320, deck + 56, 270 if s > 0 else 90, [("lc_swing_bridge", "Toggle", "", 0)], wait="8")
        sprite(m, "lc_swing_lamp_" + tag, wu, s * 314, deck + 96, "120 255 120", 0.3)
        m.lane(cu, s * 290, deck)
        m.lane(cu + s * 256, s * 288, F + 128)

    # the pier: a round concrete drum with a steel turntable on it
    m.shapes([vprism(octagon(cu, 0, 40), F, deck - 40, MAT["beam"]), vprism(octagon(cu, 0, 52), F, F + 24, MAT["canal_wall"]), vprism(octagon(cu, 0, 48), deck - 40, deck - 32, STEEL)])
    m.blocked(cu - 64, -64, cu + 64, 64)
    # the bridge, drawn across: two steel beams, a plank deck, cross ties; the handrail each side rides on it
    wood = MM["wood"]
    parts = [((cu - wide, -half, deck - 16, cu + wide, half, deck), wood)]
    for s in (1, -1):
        a, c = min(s * 20, s * 28), max(s * 20, s * 28)
        parts.append(((cu + a, -half, deck - 32, cu + c, half, deck - 16), STEEL))
        p = -224
        for n, kind in ((128, "long"), (128, "long"), (128, "long"), (64, "medium")):
            ride(m, "lc_swing_bridge", "models/props_c17/handrail04_%s.mdl" % kind, cu + s * (wide - 2), p + n // 2, 0, deck)
            p += n
    parts += [((cu - 28, v, deck - 30, cu + 28, v + 6, deck - 18), STEEL) for v in (-half + 4, -110, -3, 104, half - 10)]
    swing_gate(m, "lc_swing_bridge", parts, (cu, 0, deck - 16), mat=STEEL, speed=12, flags="32", connections=[
        ("OnOpen", "lc_swing_move", "PlaySound", "", 0), ("OnClose", "lc_swing_move", "PlaySound", "", 0), ("OnOpen", "lc_swing_lamp_*", "HideSprite", "", 0),
        ("OnFullyOpen", "lc_swing_move", "StopSound", "", 0), ("OnFullyClosed", "lc_swing_move", "StopSound", "", 0), ("OnFullyOpen", "lc_swing_stop", "PlaySound", "", 0),
        ("OnFullyClosed", "lc_swing_stop", "PlaySound", "", 0), ("OnFullyClosed", "lc_swing_lamp_*", "ShowSprite", "", 0)])
    sound(m, "lc_swing_move", "Streetwar.d3_c17_11_garage_move1", cu, 0, deck, loops=True, radius=1600, volume=8)
    sound(m, "lc_swing_stop", "Streetwar.d3_c17_11_garage_stop1", cu, 0, deck, radius=1600, volume=8)
    m.lane(cu, 120, deck)
    m.lane(cu, -120, deck)
    m.view(150, 60, F, 0, -12, "the bridge from the canal")
    m.view(cu + 10, 300, deck, 270, 10, "from the left landing, across the bridge")
    m.view(900, 150, F, 160, -18, "the left bank's stairs")
    m.view(cu - 40, -290, deck, 60, 6, "on the right landing: the wheel")
    b.notes.append("%s: the bridge turns about (%d %d); its deck is z %d; its corners swing %d out, the landings' lips are %d out, the walls 256" % (
        (m.tag,) + m.fr.pt(cu, 0) + (deck, reach, lip)))


# ---------------------------------------------------------------------------
# 8. The flood room (experimental)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 8. The flood room (experimental)
# ---------------------------------------------------------------------------

def m_floodroom(m, opt):
    """EXPERIMENTAL: a valve chamber that can be flooded: a trap or a refuge. Off the left wall a short passage, a
    steel door (lc_flood_door, open: Nova Prospekt's sliding door between steel jambs) and steps down into an
    eight-sided chamber 384 across. A steel gallery runs round it 96 over its floor behind the city's handrail (stairs
    up to it inside the chamber, a steel plate along their open side); from the gallery's far side a passage leads
    round the chamber and back to the canal through a second door (lc_flood_door_out, one of the city's doors: Use
    opens it), steps up from the canal's floor. In the chamber's middle the main (the city's 32 pipe) stands from floor
    to roof with a big hand wheel round it; a button on it (lc_flood_valve_b) and one on the gallery's wall by a small
    wheel (lc_flood_valve_a) flood the chamber: the steel door at the foot of the way in drops, then water rises 88 from
    under the floor to just under the gallery, in about fifteen seconds. Pressed again, it drains and the door lifts.
    Nobody is hurt: whoever is on the floor swims up to the gallery and walks out.

    Named for the game:
      lc_flood_water      the water: a func_water_analog under the chamber's floor (Open floods, Close drains; 6 a second).
      lc_flood_valve_a    the button on the gallery.     lc_flood_valve_b    the button on the main, at the floor.
      lc_flood_fill, lc_flood_drain   relays: Trigger one to flood or drain with the door and the sound. A press of
                          either button triggers both; only the one that makes sense is live.
      lc_flood_door       the door at the foot of the way in: a func_button used as a mover, as the bunker's (PressOut
                          shuts, PressIn opens; the map opens it as it starts), unseen, the door's model riding on it.
                          It has no damage of its own.
      lc_flood_door_out   the second door, at the canal: one of the city's doors (prop_door_rotating: Use; the
                          gamemode can lock it).
      lc_flood_rush       the rushing sound, playing while the water moves.
      lc_flood_chamber    the middle of the chamber's floor.
    Areaportals: one in the way in, one inside the second door's thickness: both dry, both well away from the water.

    Unchecked: func_water_analog from memory ("movedir" up, "movedistance" 88, "speed" 6, "startposition" 0; inputs
    Open and Close; outputs OnFullyOpen and OnFullyClosed). Its top is nature/water_canals_water_clear and its other
    faces nodraw; if moving water will not draw with that material, a cheap water material is needed there. Whether
    the engine lets a player surface cleanly 8 under the gallery. Sound from memory: ambient/water/water_flow_loop1.wav.
    The main is pipeset32d stood on end (pitch 90) and the hand wheel wheel01 laid flat (roll 90): both are centred on
    their origins, so they stand where they are put, but how they look so is not seen.

    Left as brushes: the chamber, its gallery's grating, the steel plate along the stairs, the door's jambs and head,
    the notch in the bank, the water."""
    b = m.b
    L, cu, cv = 1024, 448, 576
    FL, G, CH = F - 64, F + 32, F + 160            # the chamber's floor, the gallery, the chamber's roof
    PH = G + 112                                   # the passages' roof at gallery height
    grate = "metal/metalgrate013a"
    m.open(0, -256, L, 256)
    m.low(cu - 64, 256, cu + 64, 384, F + 128)                    # the way in
    for i in range(-3, 3):
        for j in range(-3, 3):
            if abs(i + 0.5) > 2 and abs(j + 0.5) > 2:
                continue
            m.low(cu + 64 * i, cv + 64 * j, cu + 64 * i + 64, cv + 64 * j + 64, CH, floor=FL)
    m.low(cu - 64, cv + 192, cu + 64, cv + 256, PH, floor=G)      # the way out: from the gallery's far side,
    m.low(cu - 64, cv + 256, cu + 320, cv + 320, PH, floor=G)     # along behind the chamber,
    m.low(cu + 256, 256, cu + 320, cv + 256, PH, floor=G)         # and back to the canal
    m.side(cu - 256, 256, cu + 320, cv + 320)
    m.blocked(cu - 192, cv - 192, cu + 192, cv + 192)
    m.no_bank(cu + 256, 248, cu + 320, 264)
    m.portal(cu - 64, 287, F, cu + 64, 289, F + 128)
    m.portal(cu + 256, 287, G, cu + 320, 289, PH)
    m.taken(cu - 80, 224, F, cu + 80, 256, F + 150)
    m.taken(cu + 240, 224, F, cu + 336, 256, PH + 24)

    def P(dx, dy):
        return (cu + dx, cv + dy)
    # the chamber's corners filled to make it eight-sided
    fills = []
    for sx in (1, -1):
        for sy in (1, -1):
            fills.append(vprism([P(sx * 64, sy * 192), P(sx * 128, sy * 192), P(sx * 128, sy * 128)], FL, CH, MAT["canal_wall"]))
            fills.append(vprism([P(sx * 128, sy * 128), P(sx * 192, sy * 128), P(sx * 192, sy * 64)], FL, CH, MAT["canal_wall"]))
    m.shapes(fills)
    # the gallery: seven of the ring's eight pieces (the eighth would cross the way in), a rail on the inner edge
    outer = [(64, -192), (192, -64), (192, 64), (64, 192), (-64, 192), (-192, 64), (-192, -64), (-64, -192)]
    inner = [(40, -136), (136, -40), (136, 40), (40, 136), (-40, 136), (-136, 40), (-136, -40), (-40, -136)]
    ends = {0: ((72, -104), (72, -184)), 7: ((-72, -104), (-72, -184))}      # (its two ends stop 8 short of the steps down, so nothing hangs over them)
    ring = []
    for k in range(7):
        i1, o1 = ends.get(k, (inner[k], outer[k]))
        i2, o2 = ends.get(k + 1, (inner[k + 1], outer[k + 1]))
        ring.append(vprism([P(*i1), P(*o1), P(*o2), P(*i2)], G - 8, G, PIPE, grate))
    m.shapes(ring)

    def rail(p, q, off):
        a, c = P(*p), P(*q)
        handrail_line(m, (a[0] + off[0] // 2, a[1] + off[1] // 2), (c[0] + off[0] // 2, c[1] + off[1] // 2), G)
    outs = [(2, -2), (3, 0), (2, 2), (0, 3), (-2, 2), (-3, 0), (-2, -2)]
    for k in range(7):
        if k == 2:
            rail((88, 88), inner[3], outs[2])      # (the stairs' landing joins the gallery on the rest of this piece)
        else:
            rail(ends.get(k, (inner[k],))[0], ends.get(k + 1, (inner[k + 1],))[0], outs[k])
    rail(ends[0][0], ends[0][1], (3, 0))           # the gallery's two ends, each side of the way in
    rail(ends[7][0], ends[7][1], (-3, 0))
    # the eight steps down from the way in, and the stairs up to the gallery
    m.steps(cv - 96, cu - 64, cu + 64, FL, F, "v", -1)
    m.steps(cv - 104, cu + 56, cu + 96, FL, G, "v", 1)
    m.det([(cu + 56, cv + 40, G - 8, cu + 140, cv + 88, G)], PIPE, top=grate)
    handrail_line(m, (cu + 58, cv + 40), (cu + 58, cv + 88), G)
    handrail_line(m, (cu + 56, cv + 86), (cu + 88, cv + 86), G)
    m.shapes([prism([(cv - 104, FL), (cv - 104, FL + 36), (cv + 40, G + 36), (cv + 40, G)], "x", cu + 54, cu + 58, STEEL)])

    # the main in the middle, floor to roof (into both), the hand wheel round it; a small wheel on the gallery's wall
    def stood(model, u, v, zc, pitch=0, roll=0):
        m.point("prop_static", u, v, zc, {"model": model, "angles": "%d %d %d" % (pitch, m.fr.yaw(0), roll), "skin": "0", "solid": "6", "disableshadows": "0",
                                          "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)
    stood("models/props_pipes/pipeset32d_256_001a.mdl", cu, cv, FL + 112, pitch=90)
    stood("models/props_wasteland/wheel01.mdl", cu, cv, FL + 52, roll=90)
    m.static("models/props_borealis/door_wheel001a.mdl", cu - 189, cv + 30, 0, z=G + 44)
    wires = [("lc_flood_fill", "Trigger", "", 0), ("lc_flood_drain", "Trigger", "", 0)]
    m.button("lc_flood_valve_a", cu - 192, cv, G + 40, 0, wires, wait="18")
    m.button("lc_flood_valve_b", cu, cv - 19, FL + 18, 270, wires, wait="18")

    # the water: one slab under the whole chamber, its top the water's face
    wbox = m.fr.box(cu - 192, cv - 192, FL - 88, cu + 192, cv + 192, FL)
    b.vmf.brush_entity("func_water_analog", {"targetname": "lc_flood_water", "movedir": "-90 0 0", "movedistance": "88", "speed": "6", "startposition": "0",
                                             "WaveHeight": "3.0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
                        [wbox], MAT["nodraw"], b.vis + ": water and sludge", top=MM["water"],
                        connections=[("OnFullyOpen", "lc_flood_rush", "StopSound", "", 0), ("OnFullyClosed", "lc_flood_rush", "StopSound", "", 0),
                                     ("OnFullyClosed", "lc_flood_door", "PressIn", "", 0.5)])
    b.names.append(("lc_flood_water", "func_water_analog", m.tag))
    sound(m, "lc_flood_rush", "ambient/water/water_flow_loop1.wav", cu, cv, F, loops=True, radius=1500, volume=9)
    toggle(m, "lc_flood_fill", "lc_flood_drain", cu, cv, CH - 40,
           [("lc_flood_door", "PressOut", "", 0), ("lc_flood_rush", "PlaySound", "", 1.5), ("lc_flood_water", "Open", "", 2.5)],
           [("lc_flood_water", "Close", "", 0), ("lc_flood_rush", "PlaySound", "", 0)], 18)
    m.target("lc_flood_chamber", cu, cv - 60, FL + 8, 90)

    # the door at the foot of the way in: Nova Prospekt's sliding door (114 wide, 120 high) between steel jambs, on an
    # unseen leaf that drops from the lintel (drawn shut; the map lifts it as it starts)
    m.det([(cu - 64, 360, F, cu - 57, 384, F + 128), (cu + 57, 360, F, cu + 64, 384, F + 128), (cu - 57, 360, F + 120, cu + 57, 384, F + 128)], STEEL)
    brush(m, "func_button", {"targetname": "lc_flood_door", "movedir": "-90 0 0", "speed": "60", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
                             "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "min_use_angle": "0.8", "rendermode": "10",
                             "renderamt": "0", "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, [(cu - 57, 366, F, cu + 57, 378, F + 120)], MAT["nodraw"],
          vis=b.vis + ": the flood door")
    ride(m, "lc_flood_door", "models/props_wasteland/prison_slidingdoor001a.mdl", cu, 372, 90, F)
    m.point("logic_auto", cu, 330, F + 110, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_flood_door", "PressIn", "", 0.5)])
    m.det([(cu - 72, 244, F, cu - 64, 256, F + 136), (cu + 64, 244, F, cu + 72, 256, F + 136), (cu - 72, 244, F + 128, cu + 72, 256, F + 144)], STEEL)

    # the second door, at the canal: four steps up from the floor in a notch in the bank
    du = cu + 256
    m.steps(208, du, du + 64, F, G, "v", 1)
    m.shapes([prism([(256, F), (120, F), (256, F + 136)], "x", u, u + 8, MAT["beam"]) for u in (du - 8, du + 64)])
    m.blocked(du, 128, du + 64, 320)
    from map_town import door_hole
    door_hole(m, "u", du, 280, 296, G, PH, PIPE, name="lc_flood_door_out", yaw=270)
    # light
    m.lamp(cu + 70, cv - 130, CH - 32, "200 230 220 60", hang=24)
    m.lamp(cu - 70, cv + 130, CH - 32, "200 230 220 60", hang=24)
    m.lamp(cu, 320, F + 120, "255 220 170 40")
    m.lamp(cu + 150, cv + 288, PH - 8, "255 220 170 40")
    m.lamp(du + 32, cv, PH - 8, "255 220 170 40")
    m.lane(cu, 320)
    m.lane(cu, cv + 224, G)
    m.lane(cu + 150, cv + 288, G)
    m.lane(du + 32, cv, G)
    m.lane(du + 32, 340, G)
    m.view(cu, 80, F, 90, 0, "the way in, from the canal")
    m.view(cu, 396, F, 90, 14, "from the door: the eight steps down, the main, the gallery")
    m.view(cu - 150, cv + 60, G, 320, 14, "on the gallery, by the valve")
    m.view(cu - 20, cv - 130, FL, 60, -8, "on the chamber's floor")
    m.view(du + 32, 100, F, 90, 0, "the second door, from the canal")
    b.notes.append("%s: the chamber's floor is z %d, its gallery z %d; flooded, the water stands at z %d" % (m.tag, FL, G, FL + 88))


MODULES = {
    "lock": (1536, m_lock, "a lock house: two steel gates and the control house that works them"),
    "pumphouse": (1280, m_pumphouse, "a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge"),
    "thumper": (1024, m_thumper, "a Combine thumper on a fenced terrace, with the box that stops it (experimental)"),
    "depot": (1280, m_depot, "the Combine's ration depot: a roller door, a loading bay, caged stores, a staff door"),
    "armory": (1024, m_armory, "a Combine armoury vault behind a two-button door: a heist target"),
    "swingbridge": (1024, m_swingbridge, "a footbridge that turns on a pier: across the canal, or along it (experimental)"),
    "floodroom": (1024, m_floodroom, "a valve chamber that floods: a trap or a refuge (experimental)"),
    "railbridge": (1024, m_railbridge, "a railway bridge: a Combine train crosses every few minutes (experimental)"),
}
