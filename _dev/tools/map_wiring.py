#!/usr/bin/env python3
"""
Living City: wiring the way Valve does (the owner, 21 November: "yes please go ahead"). The five rules measured in
23 of Valve's maps (docs/dev/map-modules.md, "Wiring the way Valve does"; the lessons valve-wheel-gate,
valve-portal-door, valve-sound-flags, valve-timer-asleep, valve-trigger-who), as helpers a module calls:

    sound_flags(message, on, loops=None)   the ambient_generic spawnflags for a sound: 0 a loop playing from the
                                           start, 16 a loop that waits for PlaySound, 32 a one-shot played at the
                                           start, 48 a one-shot the wiring plays (Valve's 48 on 240 sounds)
    is_looped(message)                     whether a sound file loops (by its name, and the stock loops named here)
    wheel(m, name, u, v, z, out, ...)      a valve wheel players turn (momentary_rot_button): its Position drives
                                           SetPosition on what it moves, as far as it is turned; turned all the way
                                           it can lock itself with Valve's lock sound and fire what it finishes
    sleepy_timer(m, name, ...)             a logic_timer that only dresses a place: it starts asleep, wakes while
                                           players are near (a trigger_multiple's OnStartTouchAll / OnEndTouchAll)
    trigger(m, name, boxes, wires, who=1)  a trigger_multiple that names who touches it (1 players, 2 NPCs, 8 physics)

The areaportal rule (a door works its portal) is done by the builder itself: map_build.Vmf.link_portal_doors links
every portal to the door hanging in it, so a room behind a shut door is not drawn.
"""

# Stock sounds that loop although their names don't say so (they have loop marks: the soundscapes play them looping).
LOOPED = {
    "ambient/atmosphere/tunnel1.wav", "ambient/machines/diesel_engine_idle1.wav", "ambient/creatures/flies1.wav",
    "ambient/creatures/flies2.wav", "ambient/creatures/flies3.wav", "ambient/creatures/flies4.wav",
    "ambient/creatures/flies5.wav", "ambient/water/leak_1.wav",
}


def is_looped(message):
    m = (message or "").lower().replace("\\", "/")
    return "loop" in m or m in LOOPED


def sound_flags(message, on, loops=None):
    """Valve's spawnflags for an ambient_generic (16 starts silent, 32 says 'not looped'). A loop must never carry 32
    (with it StopSound does nothing: the owner met that, 'the closing sound NEVER STOPS'); a one-shot must carry it
    (without it a second PlaySound does nothing)."""
    loops = is_looped(message) if loops is None else loops
    if loops:
        return "0" if on else "16"
    return "32" if on else "48"


# Valve's wheels (d1_canals_05 gate3_wheel and others): an unseen brush that turns, the wheel's model riding on it.
WHEEL_MODEL = "models/props_pipes/valvewheel002a.mdl"      # (Valve's, stood up: angles "90 yaw 0", its stem out of the wall)
LOCK_SOUND = "Doors.Lock"      # (what Valve's wheel plays as it locks; any sound script name or file will do)


def wheel(m, name, u, v, z, out, drives=(), on_open=(), on_closed=(), lock_open=True, model=WHEEL_MODEL,
          distance=360, speed=90, start=0.0):
    """A valve wheel on a wall at (u, v), its middle at z, facing `out` (module degrees). Turning it (hold E) moves
    everything in `drives` as far as it is turned: [name, ...] each told SetPosition with the wheel's 0 to 1. Turned
    all the way open it fires `on_open` [(name, input, value, delay), ...] and, if lock_open, locks itself with
    Valve's lock sound; turned all the way back it fires `on_closed`. distance: degrees of turning from shut to open;
    speed: degrees a second while held."""
    z += m.fr.dz
    x, y = m.fr.pt(u, v)
    dx, dy = m.fr.way(out)
    axis = 64 if abs(dx) > abs(dy) else 128      # (it turns about the wall's normal: x for a wall facing along x)
    r, out_by = 9, 12      # (the unseen brush that turns: round the wheel, from the wall's face 12 out)
    box = (x - r if dx == 0 else min(x, x + out_by * dx), y - r if dy == 0 else min(y, y + out_by * dy), z - r,
           x + r if dx == 0 else max(x, x + out_by * dx), y + r if dy == 0 else max(y, y + out_by * dy), z + r)
    wires = [("Position", d, "SetPosition", "", 0) for d in drives]
    wires += [("OnFullyOpen", n, i, val, d) for n, i, val, d in on_open]
    wires += [("OnFullyClosed", n, i, val, d) for n, i, val, d in on_closed]
    if lock_open:
        wires += [("OnFullyOpen", "!self", "Lock", "", 0), ("OnFullyOpen", name + "_lock", "PlaySound", "", 0)]
        m.b.vmf.point("ambient_generic", (x, y, z), {"targetname": name + "_lock", "message": LOCK_SOUND, "health": "10", "pitch": "100",
                                                     "pitchstart": "100", "radius": "800", "spawnflags": "48"}, m.b.vis + ": sounds")
    keys = {"targetname": name, "spawnflags": str(1024 + 1 + axis), "distance": str(distance), "speed": str(speed), "returnspeed": "0",
            "startposition": str(start), "sounds": "0", "origin": "%g %g %g" % (x, y, z), "solidbsp": "0"}
    m.b.vmf.brush_entity("momentary_rot_button", keys, [box], "tools/toolsinvisible", m.dv, connections=wires)
    m.b.names.append((name, "momentary_rot_button", m.tag))
    yaw = m.fr.yaw(out)
    m.b.vmf.point("prop_dynamic", (x, y, z), {"model": model, "parentname": name, "angles": "90 %d 0" % yaw, "solid": "0",
                                              "disableshadows": "1", "fademindist": "-1", "fadescale": "1"}, m.pv)
    m.b.props.append(("prop_dynamic", model, (x, y, z), yaw, m.tag))
    return name


def trigger(m, name, boxes, wires, who=1, wait=1, start_on=True):
    """A trigger_multiple over boxes (module coordinates) that names who touches it (spawnflags: 1 players, 2 NPCs,
    8 physics props, 64 everything). On our shared server use OnStartTouchAll / OnEndTouchAll (the first in, the
    last out) and !activator in wires, never !player (it means player 1)."""
    keys = {"targetname": name, "spawnflags": str(who), "wait": str(wait), "StartDisabled": "0" if start_on else "1"}
    m.b.vmf.brush_entity("trigger_multiple", keys, [m.fr.box(*b) for b in boxes], "tools/toolstrigger", m.dv,
                         connections=[(o, n, i, val, d) for o, n, i, val, d in wires])
    m.b.names.append((name, "trigger_multiple", m.tag))
    return name


def sleepy_timer(m, name, u, v, z, near, wires, low=3, high=10):
    """A logic_timer that only dresses a place (dust, sparks, steam, a far noise): asleep until a player comes into
    `near` (boxes in module coordinates), fired at random between low and high seconds while anyone is there, asleep
    again when the last one leaves. wires: what each tick does, [(name, input, value, delay), ...]."""
    m.point("logic_timer", u, v, z, {"targetname": name, "StartDisabled": "1", "UseRandomTime": "1", "LowerRandomBound": str(low),
                                     "UpperRandomBound": str(high)}, connections=[("OnTimer", n, i, val, d) for n, i, val, d in wires])
    trigger(m, name + "_near", near, [("OnStartTouchAll", name, "Enable", "", 0), ("OnEndTouchAll", name, "Disable", "", 0)])
    return name
