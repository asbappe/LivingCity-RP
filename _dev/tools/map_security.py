#!/usr/bin/env python3
"""
Living City: Combine tripwires and turret rooms, wired the way Valve wires the Overwatch Nexus (d3_c17_10b; the
lessons valve-tripwire-turrets and valve-counter; owner-approved 21 November, TODO "Tripwires and turrets").
Helpers a module calls, in the style of map_wiring.py (for the owner's PC, never the server):

    tripwire(m, name, a, b, room=None)       a red laser across a way in, from a to b (u, v, z), Valve's numbers
                                             (env_beam 170 0 0, width 0.2, touched by players or NPCs), with a
                                             filter so the Combine's own NPCs pass, and a backup trigger along it
    turret_room(m, name, wires, lifts)       turrets on floor lifts: a broken wire sounds the alarm, the lasers
                                             drop and the turrets rise; each sinks again when it sees no one
                                             (OnAreaClear); when all have sunk the lasers come back; when all
                                             are dead the room is off for good
    switches(m, name, rooms, count, u, v, z) a stronghold's control rooms: a counter that turns every room off
                                             once `count` switches have been thrown (each sends it Add 1)
    check(vmf_text)                          what is wrong in any VMF: a tripwire with no filter, a re-arm
                                             counter whose max is not the number of its lifts (or that starts
                                             below it), a ground turret on nothing that moves

    python3 map_security.py check [--out FILE]   writes a small test room (lc_security_test.vmf) and checks it
    python3 map_security.py lint FILE.vmf        check() on any VMF

The gamemode's side is two logic_relays per room, named from the room's name:
    lc_<room>_alarm   fired by the map when a wire is broken (its activator is whoever broke it: the gamemode may
                      block it for the Union's own players in its AcceptInput hook, or Trigger it itself)
    lc_<room>_off     Trigger it to shut the room's defences for good, as a control room switch would (the lasers
                      and triggers removed, the turrets killed); the map fires it itself when every turret is dead
A stronghold's switches counter (lc_<name>_switches) fires every room's _off.

Who passes: filter_multi lc_security_notcombine (negated: anything but npc_combine_s, npc_metropolice,
npc_manhack, npc_cscanner, npc_hunter). Players of every side trip the wires: the map cannot tell the Union's.
Unchecked sounds: ambient/alarms/apc_alarm_loop1.wav (the alarm), Streetwar.d3_c17_10b_doormove3 (Valve's lift).
"""
import argparse
import os
import re
import sys
from types import SimpleNamespace

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import map_wiring  # noqa: E402

FILTER = "lc_security_notcombine"
COMBINE = ("npc_combine_s", "npc_metropolice", "npc_manhack", "npc_cscanner", "npc_hunter")     # filter_multi takes 5
ALARM = "ambient/alarms/apc_alarm_loop1.wav"
LIFT_MOVE, LIFT_STOP = "Streetwar.d3_c17_10b_doormove3", "MetalGrate.ImpactSoft"
PIT, RISE, PLATE = 64, 64, 8      # a pit 64 square; the turret sinks 64 below the floor on a plate 8 thick
LINING, LIFT_MAT = "metal/citadel_metalwall077a", "metal/citadel_metalwall078a"


def lc(name):
    return name if name.startswith("lc_") else "lc_" + name


def _names(m, name, cls):
    m.b.names.append((name, cls, m.tag))


def security_filter(m, u, v, z):
    """The one filter every tripwire names (placed once a file, at the first wire): passes anything not the Combine's."""
    vmf = m.b.vmf
    if not getattr(vmf, "lc_security_filter", False):
        vmf.lc_security_filter = True
        keys = {"targetname": FILTER, "FilterType": "1", "Negated": "1"}
        for i, cls in enumerate(COMBINE):
            keys["Filter%02d" % (i + 1)] = "lc_security_is_" + cls[4:]
            m.point("filter_activator_class", u, v, z + 8 * i, {"targetname": "lc_security_is_" + cls[4:], "filterclass": cls, "Negated": "0"})
        m.point("filter_multi", u, v, z + 40, keys)
    return FILTER


def tripwire(m, name, a, b, room=None, width=0.2):
    """A laser tripwire from a to b ((u, v, z) in module coordinates, level, along u or v): the env_beam stands at a and
    is its own start, an info_target at b its end. Touched by a player or an NPC that is not the Combine's, or a
    trigger along it entered (the beam's own touch can miss a runner), it fires lc_<room>_alarm. With no room it fires
    its own <name>_alarm, which turns it off; Trigger <name>_arm to turn it on again. Returns the wire's name."""
    name = lc(name)
    (u1, v1, z1), (u2, v2, z2) = a, b
    if z1 != z2 or (u1 != u2 and v1 != v2):
        raise ValueError("a tripwire runs level along u or v: %r %r" % (a, b))
    flt, alarm = security_filter(m, u1, v1, z1 + 24), (lc(room) + "_alarm") if room else name + "_alarm"
    m.point("env_beam", u1, v1, z1, {
        "targetname": name, "LightningStart": name, "LightningEnd": name + "_end", "spawnflags": "1", "TouchType": "3", "filtername": flt,
        "rendercolor": "170 0 0", "renderamt": "150", "BoltWidth": "%g" % width, "texture": "sprites/laserbeam.spr", "TextureScroll": "35",
        "NoiseAmplitude": "0", "life": "0", "damage": "0", "Radius": "256", "StrikeTime": "1", "HDRColorScale": "1", "framerate": "0",
        "framestart": "0", "ClipStyle": "0", "dissolvetype": "-1"}, connections=[("OnTouchedByEntity", alarm, "Trigger", "", 0)])
    m.point("info_target", u2, v2, z2, {"targetname": name + "_end", "spawnflags": "0"})
    box = (u1 - 4, min(v1, v2), z1 - 4, u1 + 4, max(v1, v2), z1 + 4) if u1 == u2 else (min(u1, u2), v1 - 4, z1 - 4, max(u1, u2), v1 + 4, z1 + 4)
    m.b.vmf.brush_entity("trigger_multiple", {"targetname": name + "_trip", "spawnflags": "3", "filtername": flt, "wait": "1", "StartDisabled": "0"},
                         [m.fr.box(*box)], "tools/toolstrigger", m.dv, connections=[("OnStartTouch", alarm, "Trigger", "", 0)])
    _names(m, name + "_trip", "trigger_multiple")
    if not room:
        m.relay(alarm, u1, v1, z1 + 16, [(name, "TurnOff", "", 0), (name + "_trip", "Disable", "", 0)])
        m.relay(name + "_arm", u1, v1, z1 + 24, [(name, "TurnOn", "", 0), (name + "_trip", "Enable", "", 0)])
    return name


def turret_room(m, name, wires, lifts, pit=16, sound=ALARM, at=None):
    """A room of ground turrets on floor lifts, woken by its tripwires. wires: names of tripwires made with
    room=name, or (a, b) pairs to make here. lifts: (u, v, z) or (u, v, z, yaw): the floor z the turret rises to and
    the way it faces. Each turret sits in a pit 64 square, 64 deep (pit: the floor's thickness; the pit's lining is
    laid as world brushes under it, and the floor must leave the 64 square open; 0 when the module made the pit
    itself, a square painted 72 lower). Valve's wiring (d3_c17_10b atrium_turrets1):
      lc_<room>_alarm   lasers off, triggers off, the alarm for 1.5 s, every live turret's lift Open and turret Enable
      turret            OnAreaClear: its lift Close (the lift's OnClose: turret Disable); OnDeath: its lift Close and
                        never again, lc_<room>_dead Add 1
      lc_<room>_rearm   lifts shut (max = the lifts; OnFullyOpen Subtract, OnFullyClosed Add @0.2): at max the
                        lasers and triggers come back
      lc_<room>_dead    turrets dead (max = the turrets): fires lc_<room>_off
      lc_<room>_off     (once) lasers, triggers and counters removed, the turrets killed (their lifts sink)
    Returns the room's names: {'alarm', 'off', 'wires', 'turrets', 'lifts'}."""
    room = lc(name)
    alarm, off, rearm, dead = room + "_alarm", room + "_off", room + "_rearm", room + "_dead"
    names = []
    for i, w in enumerate(wires):
        names.append(lc(w) if isinstance(w, str) else tripwire(m, "%s_wire%d" % (room, i + 1), w[0], w[1], room=name))
    turrets, lps, ups = [], [], []
    for i, lift in enumerate(lifts):
        u, v, z = lift[:3]
        yaw = lift[3] if len(lift) > 3 else 0
        lp, tu, up = "%s_lift%d" % (room, i + 1), "%s_turret%d" % (room, i + 1), "%s_up%d" % (room, i + 1)
        turrets.append(tu)
        lps.append(lp)
        ups.append(up)
        h, low = PIT // 2, z - RISE
        m.b.vmf.brush_entity("func_door", {
            "targetname": lp, "movedir": "-90 0 0", "speed": "48", "lip": str(PLATE - RISE), "wait": "-1", "spawnflags": "0", "spawnpos": "0",
            "dmg": "0", "forceclosed": "1", "health": "0", "ignoredebris": "1", "loopmovesound": "0", "noise1": LIFT_MOVE, "noise2": LIFT_STOP,
            "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0",
            "disableshadows": "1"}, [m.fr.box(u - h, v - h, low - PLATE, u + h, v + h, low)], LIFT_MAT, m.dv,
            connections=[("OnFullyOpen", rearm, "Subtract", "1", 0), ("OnFullyClosed", rearm, "Add", "1", 0.2), ("OnClose", tu, "Disable", "", 0)])
        _names(m, lp, "func_door")
        m.point("npc_turret_ground", u, v, low, {"targetname": tu, "parentname": lp, "angles": "0 %d 0" % m.fr.yaw(yaw), "spawnflags": "0"},
                connections=[("OnAreaClear", lp, "Close", "", 0), ("OnDeath", up, "Disable", "", 0), ("OnDeath", lp, "Close", "", 0),
                             ("OnDeath", dead, "Add", "1", 0)])
        m.relay(up, u, v, z + 8, [(lp, "Open", "", 0), (tu, "Enable", "", 0)])
        if pit:
            b0 = low - PLATE - 16
            for box in ((u - h - 16, v - h - 16, b0, u + h + 16, v - h, z - pit), (u - h - 16, v + h, b0, u + h + 16, v + h + 16, z - pit),
                        (u - h - 16, v - h, b0, u - h, v + h, z - pit), (u + h, v - h, b0, u + h + 16, v + h, z - pit),
                        (u - h, v - h, b0, u + h, v + h, low - PLATE)):
                m.world(box, LINING)
    n = len(lifts)
    cu = sum(lf[0] for lf in lifts) // n
    cv = sum(lf[1] for lf in lifts) // n
    cz = lifts[0][2] + 96
    at = at or (cu, cv, cz)
    beams = [(w, "TurnOff", "", 0) for w in names] + [(w + "_trip", "Disable", "", 0) for w in names]
    m.sound(sound, at[0], at[1], at[2], radius=1250, volume=10, name=room + "_siren", on=False)
    m.relay(alarm, cu, cv, cz, beams + [(room + "_siren", "PlaySound", "", 0), (room + "_siren", "StopSound", "", 1.5)] +
            [(up, "Trigger", "", 0) for up in ups])
    m.point("math_counter", cu, cv, cz + 8, {"targetname": rearm, "startvalue": str(n), "min": "0", "max": str(n)},
            connections=[("OnHitMax", w, "TurnOn", "", 0) for w in names] + [("OnHitMax", w + "_trip", "Enable", "", 0) for w in names])
    m.point("math_counter", cu, cv, cz + 16, {"targetname": dead, "startvalue": "0", "min": "0", "max": str(n)},
            connections=[("OnHitMax", off, "Trigger", "", 0)])
    shut = (beams + [(w, "Kill", "", 0.1) for w in names] + [(w + "_end", "Kill", "", 0.1) for w in names] + [(w + "_trip", "Kill", "", 0.1) for w in names] +
            [(x, "Kill", "", 0) for x in (rearm, dead, alarm)] + [(up, "Kill", "", 0) for up in ups] + [(tu, "SetHealth", "0", 0.2) for tu in turrets])
    m.point("logic_relay", cu, cv, cz + 24, {"targetname": off, "StartDisabled": "0", "spawnflags": "1"}, connections=[("OnTrigger",) + w for w in shut])
    m.point("logic_auto", cu, cv, cz + 32, {"spawnflags": "1"}, connections=[("OnMapSpawn", tu, "Disable", "", 0) for tu in turrets])
    return {"alarm": alarm, "off": off, "wires": names, "turrets": turrets, "lifts": lps}


def switches(m, name, rooms, count, u, v, z):
    """A stronghold's control rooms (d3_c17_10b switches_counter, max 3): each switch thrown sends lc_<name>_switches
    Add 1; at count every room's lc_<room>_off fires. Returns the counter's name."""
    c = lc(name) + "_switches"
    m.point("math_counter", u, v, z, {"targetname": c, "startvalue": "0", "min": "0", "max": str(count)},
            connections=[("OnHitMax", lc(r) + "_off", "Trigger", "", 0) for r in rooms])
    return c


# ---- the check ----
def entities(text):
    """Every entity in a VMF as {'keys': {...}, 'conns': [(output, [target, input, value, delay, times])]}."""
    ents, stack, cur, pending = [], [], None, None
    for line in text.splitlines():
        s = line.strip()
        if s == "{":
            stack.append(pending)
            if stack == ["entity"]:
                cur = {"keys": {}, "conns": []}
                ents.append(cur)
        elif s == "}":
            if stack:
                stack.pop()
        else:
            kv = re.match(r'"([^"]*)"\s+"([^"]*)"', s)
            if not kv:
                pending = s
            elif stack == ["entity"]:
                cur["keys"].setdefault(kv.group(1).lower(), kv.group(2))
            elif stack == ["entity", "connections"]:
                cur["conns"].append((kv.group(1), re.split(r"[\x1b,]", kv.group(2))))
    return ents


def check(vmf_text):
    """Problems in a VMF's security wiring, one line each (none: an empty list)."""
    ents = entities(vmf_text)
    filters = {e["keys"].get("targetname") for e in ents if e["keys"].get("classname", "").startswith("filter_")}
    out = []
    for e in ents:
        k = e["keys"]
        cls, nm = k.get("classname", ""), k.get("targetname", "(unnamed)")
        if cls == "env_beam" and k.get("touchtype", "0") not in ("", "0"):
            if not k.get("filtername"):
                out.append("tripwire %s has no filter: the Combine's own NPCs would set it off (name %s)" % (nm, FILTER))
            elif k["filtername"] not in filters:
                out.append("tripwire %s names the filter %s, which is not in the file" % (nm, k["filtername"]))
        if cls == "npc_turret_ground" and not k.get("parentname"):
            out.append("ground turret %s stands on nothing that moves: it never scans (it must rise on a lift)" % nm)
        if cls == "math_counter":
            lifts = {d["keys"].get("targetname") for d in ents if d["keys"].get("classname") == "func_door"
                     for o, c in d["conns"] if c[0] == nm and (o, c[1]) in (("OnFullyClosed", "Add"), ("OnFullyOpen", "Subtract"))}
            if lifts:
                top = k.get("max", "0")
                if float(top or 0) != len(lifts):
                    out.append("re-arm counter %s has max %s but %d lifts feed it: the lasers %s" % (
                        nm, top, len(lifts), "never come back" if float(top or 0) > len(lifts) else "come back while a turret is still up"))
                elif float(k.get("startvalue") or 0) != len(lifts):
                    out.append("re-arm counter %s starts at %s, not at its %d shut lifts: the lasers never come back" % (nm, k.get("startvalue", "0"), len(lifts)))
    return out


# ---- a test room, to compile and walk by itself ----
class Flat:
    """The identity frame: module coordinates are map coordinates (for the test room, which is no module)."""
    dz = 0

    def at(self, u, v, z):
        return (u, v, z)

    def box(self, u1, v1, z1, u2, v2, z2):
        return (min(u1, u2), min(v1, v2), min(z1, z2), max(u1, u2), max(v1, v2), max(z1, z2))

    def yaw(self, a):
        return a % 360


class Bare:
    """Just enough of a module (map_modules.Mod) over a bare Vmf for these helpers."""

    def __init__(self, vmf, vis):
        self.b, self.fr, self.tag = SimpleNamespace(vmf=vmf, names=[], props=[], vis=vis), Flat(), "security"
        self.dv = self.pv = vis

    def point(self, cls, u, v, z, keys=None, vis=None, connections=None):
        self.b.vmf.point(cls, (u, v, z), keys or {}, vis or self.dv, connections=connections)
        if keys and keys.get("targetname"):
            self.b.names.append((keys["targetname"], cls, self.tag))

    def relay(self, name, u, v, z, wires, on=True):
        self.point("logic_relay", u, v, z, {"targetname": name, "StartDisabled": "0" if on else "1", "spawnflags": "0"},
                   connections=[("OnTrigger", n, i, val, d) for n, i, val, d in wires])

    def sound(self, message, u, v, z, radius=1100, volume=7, name=None, on=True, loops=None):
        keys = {"message": message, "health": str(volume), "radius": str(radius), "pitch": "100", "pitchstart": "100",
                "spawnflags": map_wiring.sound_flags(message, on, loops)}
        if name:
            keys["targetname"] = name
        self.point("ambient_generic", u, v, z, keys)

    def world(self, box, mat, top=None, vis=None, seals=True):
        self.b.vmf.world_box(self.fr.box(*box), mat, top=top or mat, bottom=mat, vis=vis or self.dv, seals=seals)


def floor_round(x1, y1, x2, y2, holes):
    """A floor rectangle as boxes round square holes ((x1, y1, x2, y2) each): cut into rows at the holes' edges."""
    ys = sorted({y1, y2} | {h[1] for h in holes} | {h[3] for h in holes})
    out = []
    for a, b in zip(ys, ys[1:]):
        cuts = sorted(h for h in holes if h[1] <= a and h[3] >= b)
        x = x1
        for h in cuts:
            if h[0] > x:
                out.append((x, a, h[0], b))
            x = max(x, h[2])
        if x < x2:
            out.append((x, a, x2, b))
    return out


def test_room(out):
    """A sealed Combine room 1280 by 768: the start in the west part, a wall with two doorways each crossed by a
    tripwire, two turrets in pits in the east part facing the doorways, and a red button by the start that throws the
    stronghold's one switch (every room off). Breaking a wire: the alarm, the turrets rise; walk back out of sight and
    they sink, the lasers return. Returns the Vmf's text."""
    from map_build import Vmf, test_extras
    v = Vmf()
    vis = "LC security: test room"
    m = Bare(v, vis)
    X, Y, H, wx = 1280, 768, 256, 512     # room size, its height, the dividing wall's west face
    floor, wall = "concrete/concretefloor026a", "metal/citadel_metalwall077a"
    lifts = [(1024, 256, 0, 180), (1088, 544, 0, 180)]
    holes = [(u - PIT // 2, w - PIT // 2, u + PIT // 2, w + PIT // 2) for u, w, _, _ in lifts]
    for r in floor_round(0, 0, X, Y, holes):
        v.world_box((r[0], r[1], -16, r[2], r[3], 0), wall, top=floor, bottom=wall, vis=vis)
    for b, inner in (((-16, -16, -16, 0, Y + 16, H + 16), "east"), ((X, -16, -16, X + 16, Y + 16, H + 16), "west"),
                     ((0, -16, -16, X, 0, H + 16), "north"), ((0, Y, -16, X, Y + 16, H + 16), "south"), ((0, 0, H, X, Y, H + 16), "bottom")):
        v.world_box(b, "tools/toolsnodraw", vis=vis, faces={inner: wall})      # (the shell: only its face into the room is drawn)
    doors = [(160, 256), (480, 608)]      # the two doorways (y from, to), 96 and 128 wide
    ys = [0] + [y for d in doors for y in d] + [Y]
    for a, b in zip(ys[::2], ys[1::2]):
        v.world_box((wx, a, 0, wx + 32, b, H), wall, vis=vis)
    for a, b in doors:
        v.world_box((wx, a, 128, wx + 32, b, H), wall, vis=vis)      # (doorways 128 high)
    wires = [((wx + 16, a, 40), (wx + 16, b, 40)) for a, b in doors]
    turret_room(m, "sectest", wires, lifts)
    switches(m, "sectest", ["sectest"], 1, 160, 600, 64)
    v.brush_entity("func_button", {"movedir": "0 0 0", "speed": "8", "lip": "4", "wait": "-1", "spawnflags": "1025", "sounds": "0", "health": "0",
                                   "rendermode": "0", "renderamt": "255", "rendercolor": "255 60 60"}, [(96, Y - 8, 48, 128, Y, 80)], "metal/citadel_metalwall078a",
                   vis, connections=[("OnPressed", "lc_sectest_switches", "Add", "1", 0)])
    for x, y in ((256, 384), (896, 384)):
        v.point("light", (x, y, H - 32), {"_light": "147 226 240 200", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)
    test_extras(v, (128, 384, 16), 0, vis)
    text = v.text()
    with open(out, "w") as fh:
        fh.write(text)
    return text


def main():
    ap = argparse.ArgumentParser(description="Combine tripwires and turret rooms: a test room, and the check on any VMF.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check", help="write the test room and check it (and that the check finds faults)")
    c.add_argument("--out", default=os.path.join(HERE, "lc_security_test.vmf"))
    sub.add_parser("lint", help="check() on a VMF").add_argument("vmf")
    a = ap.parse_args()
    if a.cmd == "lint":
        probs = check(open(a.vmf, errors="replace").read())
        print("\n".join(probs) or "no security faults")
        sys.exit(1 if probs else 0)
    text = test_room(a.out)
    probs = check(text)
    broken = text.replace('"filtername" "%s"\n\t"rendercolor"' % FILTER, '"rendercolor"', 1).replace('"max" "2"', '"max" "3"', 1)
    found = check(broken)
    print("wrote %s" % a.out)
    print("\n".join(probs) or "no security faults")
    print("the check on a broken copy finds: %s" % ("; ".join(found) or "NOTHING"))
    ok = not probs and len(found) >= 2
    print("SECURITY CHECK %s" % ("PASS" if ok else "FAIL"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
