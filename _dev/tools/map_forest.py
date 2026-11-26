#!/usr/bin/env python3
"""
Living City: forest pieces for the map builder (run them through map_build.py)

The owner, 19 November: "two forest sections/areas using Episode 2 assets (EP1 and HL2 base is
fine too), one has an old abandoned nuclear/bomb/air-raid bunker, and the other has a natural
cave like in EP2. One should have a nice little pond or small lake with a small island on it,
and the other should have a small stream", each its own file, "separate from the canals ... but
can be stitched together".

    python3 map_build.py forest_bunker --preview bunker.png    the bunker, and the pond with its island
    python3 map_build.py forest_cave --preview cave.png        the cave, and the stream that runs out of it

A forest is a valley 4096 units square inside a ridge, under its own sky. Its ground is displaced
terrain (64 patches of 512, a corner every 64 units) made from one height function, so every
patch meets its neighbours. Under and round it is a sealed shell (a slab, four sky walls, a sky
lid); the ground itself seals nothing. Each has one gate: the same culvert the canal's far ends
have (512 wide, 256 high), with a concrete headwall, closed by a cap until something is joined.

Every model and material was checked to exist (and each prop_static model to be compiled as a
static prop) against lists of Half-Life 2's, Episode One's and Episode Two's files. What nobody
has checked is how any of it LOOKS: this was made without seeing it. docs/dev/map-building.md.
"""

import copy
import math
import sys
import random
import re

import map_launch as ML
import map_prefab as PF
import map_silo as MS
from map_build import CELL, FACE_AXES, FACE_ORDER, GATE_HIGH, GATE_WIDE, MAT, Plan, Vmf, check, face_corners, flood, gate_cap, reaches, dress_keys, stand_z, standing_prop, test_extras

PATCH, STEP, WALL = 512, 64, 128

FMAT = {
    "ground": "nature/blendgrassdirt01",          # ep2: forest grass, blending to forest dirt
    "cave": "nature/blendrockdirt_tunnel02a",     # ep2: cave rock, blending to dirt
    "cliff": "nature/blendcliffdirt001a",         # hl2: a cliff's face, blending to dirt (the rock round the cave's mouth)
    "pond": "nature/water_canals_water_clear",    # hl2
    "stream": "nature/water_riverbed02",          # ep2: the Episode Two river water
    "bunker_wall": "concrete/concretewall008a",   # these three are in the owner's own map
    "bunker_floor": "concrete/concretefloor031a",
    "bunker_ceiling": "concrete/concreteceiling004a",
    "door": "metal/metalhull003a",                # hl2: riveted steel plate (the bunker door's leaves)
    "office_wall": "wood/woodwall047a",           # ep2: a board wall (the mine office in the cave)
    "office_floor": "wood/woodfloor007a",         # hl2: floorboards
    "office_ceiling": "metal/metalroof004a",      # hl2: corrugated iron
    "timber": "wood/woodbeam001a",                # hl2: a squared beam
    "nest_rock": "nature/blendrockdirt_tunnel03a",  # ep2: the antlion tunnels' rock (two rocks blended)
    "nest_hive": "nature/rockwall_antlion01a",      # ep2: the hive's own crusted wall
    # White Forest's base (the owner, 21 November: "match the EP2 whiteforest bunker aesthetic"), counted in its rooms
    # (ep2_outland_11, 12a's launch control and 11b's work rooms): walls concretewall_bunker05b on the 128 over the floor
    # (its dark band at the foot), 05a above it (WFPlan; until 22 November it was the other way round, 05b repeating up
    # every wall), floors concretefloor_bunker02a, ceilings concreteceiling_bunker01a; the silo's own concrete for the hull
    "wf_foot": "concrete/concretewall_bunker05b",
    "wf_upper": "concrete/concretewall_bunker05a",
    "wf_floor": "concrete/concretefloor_bunker02a",
    "leaf_frame": "metal/metalwall085a",          # ep2: the steel of Silo 2's door leaves (Valve's own brushes under them), the bunker door's frame
    "wf_ceiling": "concrete/concreteceiling_bunker01a",
    "wf_trim": "metal/metalwall061f",
    "silo_wall": "concrete/concretewall010a",
}

MINE_MAT = {"wall": "concrete/concretewall_mine_002a", "floor": "nature/dirtfloor_mine001a", "roof": "concrete/concretewall_mine_002c"}   # Episode Two's built mine (ep2_outland_02, 03)
PINES = (("models/props_foliage/tree_pine04.mdl", 3), ("models/props_foliage/tree_pine05.mdl", 3), ("models/props_foliage/tree_pine06.mdl", 3),
         ("models/props_foliage/tree_pine_large.mdl", 1), ("models/props_foliage/tree_dead01.mdl", 0.4), ("models/props_foliage/tree_dead03.mdl", 0.4))
# (not the tree_deciduous ones: Episode Two's copy of their leaves is drawn at full brightness whatever the light,
#  as the cattails are: their materials are "UnlitGeneric". Found when the owner saw the reeds glowing in the dark.)
LEAFY = (("models/props_foliage/oak_tree01.mdl", 2), ("models/props_foliage/tree_poplar_01.mdl", 2))
SHORE = ("models/props_foliage/fern01.mdl", "models/props_foliage/ferns01.mdl", "models/props_foliage/ferns02.mdl", "models/props_foliage/shrub_small.mdl")
PLANTS = ("models/props_foliage/ferns01.mdl", "models/props_foliage/ferns02.mdl", "models/props_foliage/ferns03.mdl", "models/props_foliage/fern01.mdl",
          "models/props_foliage/bush2.mdl", "models/props_foliage/shrub_small.mdl")
ROCKS = ("models/props_foliage/forestrock_cluster01.mdl", "models/props_foliage/forestrock_cluster02.mdl", "models/props_foliage/forestrock_single01.mdl",
         "models/props_wasteland/rockgranite02a.mdl", "models/props_wasteland/rockgranite03a.mdl")
LOGS = ("models/props_foliage/fallentree01.mdl", "models/props_foliage/fallentree02.mdl", "models/props_foliage/tree_stump01.mdl", "models/props_forest/log.mdl")


# ---------------------------------------------------------------------------
# Small things
# ---------------------------------------------------------------------------

def wall_button(vmf, pos, yaw, name, box, vis, connections, wait, parent=None, extra=None):
    """A button on a wall: Episode Two's mine lift button (the owner: "the button needs a button prop
    [models/props_mining/freightelevatorbutton02.mdl would work], not a big square brush"), and round it an unseen
    func_button that takes the press and plays the model's own press. pos: the model's foot against the wall (it is 8 wide,
    20 high and stands 5 out, facing east at yaw 0); box: the unseen button's own; extra: more keys for the func_button."""
    vmf.point("prop_dynamic", pos, {"targetname": name + "_model", "model": "models/props_mining/freightelevatorbutton02.mdl", "angles": "0 %d 0" % yaw, "skin": "0", "solid": "0",
                                    "DefaultAnim": "idleoff", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                    "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0",
                                    "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0",
                                    **({"parentname": parent} if parent else {})}, vis)
    vmf.brush_entity("func_button", {"targetname": name, "spawnflags": "1025", "wait": wait, "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "0", "health": "0",
                                     "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "min_use_angle": "0.8", **({"parentname": parent} if parent else {}),
                                     **(extra or {})},
                     [box], MAT["nodraw"], vis, connections=[("OnPressed", name + "_model", "SetAnimation", "turn_ON", 0)] + list(connections))


def shove(vmf, name, parts, vis, fit=True):
    """No door, gate or moving wall kills or crushes. The owner, 22 November, first of the silo's doors: "the silo doors
    should not violently kill people, they just need to shove people back a bit so they don't get stuck AT THE CLOSE, not
    during the entire closing sequence"; then of all the rest: "considering how dying in the gamemode means a new
    character, yes just shove, not kill". So: unseen trigger_pushes (`name`) across a doorway, off but for the mover's
    last moments of closing (the wiring turns them on and off), each pushing whoever (players, NPCs, loose things) is in
    it away from the mover on its side. parts: (box, the way it pushes as a yaw, speed). The two sides push unequally, so
    that whoever stands across the plane goes one way, not nowhere. fit=False: its boxes are not held to the fit check
    (for one that stands where something of the owner's own stands, as their unseen walls do)."""
    for box, yaw, speed in parts:
        vmf.brush_entity("trigger_push", {"targetname": name, "StartDisabled": "1", "spawnflags": "11", "pushdir": "0 %d 0" % yaw, "speed": str(speed),
                                          "alternateticksfix": "0"}, [box], MAT["trigger"], vis)
    if not fit:
        del vmf.boxes[-len(parts):]


# ---------------------------------------------------------------------------
# Pieces lifted from Valve's maps (map_prefab.py), placed with their wiring
# ---------------------------------------------------------------------------

def pf_point(p, q, d):
    x, y, z = PF.rot(list(p), q)
    return [x + d[0], y + d[1], z + d[2]]


def pf_solid(vmf, sides, q, d, vis):
    """One brush of a lifted piece turned q quarter turns (anticlockwise from above) and moved by d, as place() does:
    its text and its box."""
    t = "\t"
    text = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, vmf.new_id())
    allv = []
    for s in sides:
        pl = [pf_point(p, q, d) for p in s["plane"]]
        vs = [pf_point(p, q, d) for p in s["verts"]]
        allv += vs or [pf_point(p, q, d) for p in s.get("corners", [])] or pl
        text += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, vmf.new_id(), t, " ".join("(%s %s %s)" % tuple(PF.fmt(c) for c in p) for p in pl))
        if vs:
            text += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%s %s %s"\n' % ((t,) + tuple(PF.fmt(c) for c in p)) for p in vs), t)
        text += '%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%s"\n%s\t\t"smoothing_groups" "0"\n' % (
            t, s["material"], t, PF.turn_axis(s["uaxis"], q, d), t, PF.turn_axis(s["vaxis"], q, d), t, t, s["lightmapscale"], t)
        text += (PF.disp_text(s["disp"], q, d, t) if s.get("disp") else "") + "%s\t}\n" % t
    text += vmf.editor(vis, indent=t + "\t") + "%s}\n" % t
    return text, tuple(min(p[k] for p in allv) for k in range(3)) + tuple(max(p[k] for p in allv) for k in range(3))


def pf_finish(sols, q, d, rooms, mats, models=()):
    """What Valve left bare (nodraw) where its map ran on and ours now stops at a hull of our own (the owner, 24
    November: "there are walls missing all over the stairs up to the launch control room"): a nodraw face of a lifted
    piece whose middle (or a point near one of its corners) looks, 1 out, into the open air of one of `rooms` (boxes of the map; air: inside no other brush
    of the piece) gets mats["floor"], ["ceiling"] or ["wall"] by the way it faces. sols: the piece's solids to be placed
    (changed in place: copies). rooms and mats may instead be a list of (rooms, mats), the first that holds the point
    deciding. A brush that lies wholly inside one of `models` (the boxes of the piece's own models, in its frame) is
    dressed by that model and keeps Valve's nodraw: the forest cams' screens, 2 thick inside their TVs, had been given
    concrete round their pictures. How many."""
    groups = rooms if mats is None else [(rooms, mats)]

    def plane(pts):
        a, b, c = pts
        u = [a[k] - b[k] for k in range(3)]
        w = [c[k] - b[k] for k in range(3)]
        n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        ln = math.sqrt(sum(x * x for x in n)) or 1.0
        n = [x / ln for x in n]
        return n, sum(n[k] * a[k] for k in range(3))
    placed = []
    for sol in sols:
        sides = [dict(sd, plane=[pf_point(p, q, d) for p in sd["plane"]], corners=[pf_point(p, q, d) for p in (sd.get("verts") or sd.get("corners") or [])])
                 for sd in sol["sides"]]
        placed.append((sol, sides, [plane(sd["plane"]) for sd in sides]))

    def inside(p, planes):
        return all(n[0] * p[0] + n[1] * p[1] + n[2] * p[2] - dd <= 0.01 for n, dd in planes)
    count = 0
    for sol, sides, planes in placed:
        allc = [c for sd in sides for c in sd["corners"]]
        if not allc:
            continue
        own = [c for sd in sol["sides"] for c in (sd.get("verts") or sd.get("corners") or [])]
        if own and any(all(m[k] - 0.5 <= min(c[k] for c in own) and max(c[k] for c in own) <= m[k + 3] + 0.5 for k in range(3)) for m in models):
            continue
        mid = [sum(c[k] for c in allc) / len(allc) for k in range(3)]
        for k, sd in enumerate(sides):
            if sd["material"].upper() != "TOOLS/TOOLSNODRAW" or len(sd["corners"]) < 3:
                continue
            n = planes[k][0]
            fc = [sum(c[i] for c in sd["corners"]) / len(sd["corners"]) for i in range(3)]
            if sum(n[i] * (fc[i] - mid[i]) for i in range(3)) < 0:
                n = [-x for x in n]
            got = None
            near = []
            for c in sd["corners"]:      # (its middle, and near each corner: a quarter of the way in, and 2 in)
                ln = math.sqrt(sum((fc[i] - c[i]) ** 2 for i in range(3))) or 1.0
                near += [[c[i] + (fc[i] - c[i]) * f for i in range(3)] for f in (0.25, min(1.0, 2.0 / ln), 0.05)]
            for c in [fc] + near:
                pt = [c[i] + n[i] for i in range(3)]
                ms = [m for bs, m in groups if any(all(b[i] <= pt[i] <= b[i + 3] for i in range(3)) for b in bs)]
                if ms and not any(inside(pt, pl) for other, _, pl in placed if other is not sol):
                    got = ms[0]
                    break
            if not got:
                continue
            sol["sides"][k] = dict(sol["sides"][k], material=got["floor" if n[2] > 0.7 else "ceiling" if n[2] < -0.7 else "wall"])
            count += 1
    return count


def pf_model_boxes(pf):
    """The boxes of a lifted piece's upright models (no pitch or roll) that nothing moves (no parent, no name), in the
    piece's own frame, by their real sizes. (A door's model moves away from what it covered shut: the strip over White
    Forest's south door, inside the door model's box, showed as a hole when it kept Valve's nodraw.)"""
    import map_build
    out = []
    for e in pf["points"]:
        k = e["keys"]
        m = k.get("model", "")
        a = [float(c) for c in (k.get("angles") or "0 0 0").split()]
        if m.endswith(".mdl") and len(a) == 3 and abs(a[0]) < 0.01 and abs(a[2]) < 0.01 and not k.get("parentname") and not k.get("targetname"):
            b = map_build.prop_box(m, e["origin"], a[1])
            if b:
                out.append(b)
    return out


def pf_solids(vmf, pf, q, d, vis, world=False, skip=None, finish=None):
    """A lifted piece's brushes: with `world`, those that were Valve's world brushes go into the world (they cut up the
    map for visibility, as in Valve's own) and the rest into one func_detail. Their boxes are returned, not handed to
    the build's checks: Valve's corners are off our grid, and what seals is a hull of our own round the piece.
    finish: [(rooms, mats)] for pf_finish."""
    det, boxes = "", []
    sols = [copy.deepcopy(s) for s in pf["solids"] if not (skip and skip(s))]
    if finish:
        pf_finish(sols, q, d, finish, None, models=pf_model_boxes(pf))
    for s in sols:
        text, box = pf_solid(vmf, s["sides"], q, d, vis)
        boxes.append(box)
        if world and s["from"] == "worldspawn":
            vmf.world.append(text)
        else:
            det += text
    if det:
        vmf.ents.append('entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % vmf.new_id() + det + vmf.editor(vis, "0 180 0") + "}\n")
    return boxes


def pf_brush_entity(vmf, cls, keys, brushes, q, d, vis, connections=None, origin=None):
    """A brush entity of a lifted piece (a door, a button, a trigger), its brushes turned and moved as the piece's."""
    s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (vmf.new_id(), cls)
    for k, v in keys.items():
        s += '\t"%s" "%s"\n' % (k, v)
    if origin is not None:
        s += '\t"origin" "%s %s %s"\n' % tuple(PF.fmt(round(c, 2)) for c in origin)
    s += Vmf.wires(connections)
    for b in brushes:
        s += pf_solid(vmf, b, q, d, vis)[0]
    s += vmf.editor(vis, "220 30 220") + "}\n"
    vmf.ents.append(s)


PF_NAME_KEYS = ("targetname", "parentname", "target", "lightingorigin", "nextkey", "attach1", "attach2", "spawnpos", "position0", "slavename",
                "filtername", "damagefilter", "laddername")
PF_SPOT_KEYS = ("point0", "point1", "springaxis")      # (keys that hold a place in Valve's own map, not a name)
PF_AXES = {"func_door_rotating": (64, 128), "func_rot_button": (64, 128), "momentary_rot_button": (64, 128), "func_rotating": (4, 8)}


def pf_outputs(conns):
    """Valve's outputs as kept in a piece ([output, "target,input,value,delay,times"]) as (output, target, input, value, delay)."""
    out = []
    for o, rest in conns:
        p = rest.split(",")
        if len(p) < 5:
            continue
        out.append((o, p[0], p[1], ",".join(p[2:-2]), float(p[-2] or 0)))
    return out


def pf_entities(vmf, pf, q, d, prefix, vis_props, vis_logic, keep=None, edit=None, extra=(), valve_anchor=None, exact=False):
    """A lifted piece's props, lights and wiring (its path points too), turned and moved as its brushes. Every name the
    piece gives is prefixed (two pieces never answer each other), an output to anything the piece does not have is
    dropped (Valve's story, outside the piece), and every output may fire again (Valve's once-only buttons become
    reusable). keep(e) says what to place; edit(e) may change an entity first (each is a copy, its outputs already
    as (output, target, input, value, delay) in e["out"]); extra: entities of our own in the piece's frame, named as
    the piece's. A turned piece's tilting doors and spinners change axis with it. exact: points keep Valve's places to
    0.01, not cut to whole units (Vmf.point). Returns the names placed."""
    ents = []
    for e in list(pf["points"]) + list(pf.get("wiring", [])) + list(extra):
        e = copy.deepcopy(e)
        e["out"] = e.get("out") or pf_outputs(e.get("connections", []))
        ents.append(e)
    for r in pf.get("route", []):
        keys = {"targetname": r["name"], "target": r["target"], "altpath": r["altpath"], "speed": r["speed"], "spawnflags": r["spawnflags"],
                "orientationtype": r["orientationtype"], "angles": r["angles"]}
        ents.append({"classname": "path_track", "origin": r["origin"], "keys": keys, "out": pf_outputs(r["outputs"])})
    ents = [e for e in ents if not keep or keep(e)]
    for e in ents:
        if edit:
            edit(e)
    ents = [e for e in ents if not e.get("drop")]
    names = set(e["keys"].get("targetname", "").lower() for e in ents) - {""}

    def ren(v):
        lv = v.lower()
        if lv in names:
            return prefix + v
        if lv.endswith("*") and any(n.startswith(lv[:-1]) for n in names):
            return prefix + v
        return None
    for e in ents:
        cls = e["classname"]
        keys = dict((k, v) for k, v in e["keys"].items() if k not in ("classname", "origin", "id"))
        for k in list(keys):
            # (a particle system's control points name entities too: ep2_outland_12a's hatch smoke named door.silo, and
            #  the game said "could not find control point entity (door.silo)" when it kept Valve's name)
            if (k.lower() in PF_NAME_KEYS or re.match(r"cpoint\d+$", k.lower())) and keys[k]:
                r = ren(keys[k])
                if r:
                    keys[k] = r
                elif k.lower() != "targetname":
                    del keys[k]          # (it names something outside the piece)
            if k.lower() in PF_SPOT_KEYS and valve_anchor:
                p = [float(c) for c in keys[k].split()]
                keys[k] = " ".join(PF.fmt(round(c, 2)) for c in pf_point([p[i] - valve_anchor[i] for i in range(3)], q, d))
        if e["classname"] == "func_useableladder" and keys.get("point0") and keys.get("point1"):
            # (a ladder's lower end 2 off the floor: Valve stood some exactly on it, and a player's box there touches it, which
            #  the game calls stuck, "funcladder with blocked bottom point"; map_walk.py's ladder check, 25 November)
            p0, p1 = ([float(c) for c in keys[n].split()] for n in ("point0", "point1"))
            low = "point0" if p0[2] <= p1[2] else "point1"
            lp = p0 if low == "point0" else p1
            keys[low] = " ".join(PF.fmt(round(c, 2)) for c in (lp[0], lp[1], lp[2] + 2))
        brushes = e.get("brushes")
        if brushes:
            if keys.get("movedir"):
                a = [float(c) for c in keys["movedir"].split()]
                keys["movedir"] = "%s %s %s" % (PF.fmt(a[0]), PF.fmt((a[1] + 90 * q) % 360), PF.fmt(a[2]))
            if cls in PF_AXES and q % 2:
                ax, ay = PF_AXES[cls]
                f = int(keys.get("spawnflags", "0") or 0)
                for _ in range(q % 4):
                    if f & ax:
                        f = (f & ~ax) | ay
                    elif f & ay:
                        f = ((f & ~ay) | ax) ^ 2
                keys["spawnflags"] = str(f)
        elif "angles" in keys:
            a = [float(c) for c in keys["angles"].split()]
            keys["angles"] = "%s %s %s" % (PF.fmt(a[0]), PF.fmt((a[1] + 90 * q) % 360), PF.fmt(a[2]))
        outs = []
        for o, tgt, inp, val, delay in e["out"]:
            if tgt.startswith("!"):
                outs.append((o, "!activator" if tgt.lower() == "!player" else tgt, inp, val, delay))
                continue
            r = ren(tgt)
            if r:
                outs.append((o, r, inp, val, delay))
        if brushes:
            pf_brush_entity(vmf, cls, keys, brushes, q, d, vis_logic, outs, pf_point(e["origin"], q, d) if "origin" in e else None)
        else:
            vmf.point(cls, tuple(pf_point(e["origin"], q, d)), keys, vis_props if cls.startswith("prop") else vis_logic, connections=outs, exact=exact)
    return names


def pf_disp_points(pf, which=None):
    """The points of a lifted piece's displaced faces, in the piece's own frame (before turning and moving), with each
    face's material: (material, (x, y, z)). Valve's files give a face's corners the other way round from Hammer's own
    (from_planes), so the rows here run from the start corner to the corner before it: with that, neighbouring faces
    meet (21 November, Ravenholm's tunnel: 135 shared points against 20 the other way)."""
    out = []
    for sol in pf["solids"]:
        for sd in sol["sides"]:
            dsp, v = sd.get("disp"), sd.get("corners") or []
            if not dsp or len(v) != 4 or (which and not which(sd["material"].lower())):
                continue
            keys = dict(dsp["keys"])
            rows = dict((nm, [[float(c) for c in val.split()] for _, val in r]) for nm, r in dsp["blocks"])
            n = 2 ** int(keys.get("power", "2"))
            st = [float(c) for c in keys["startposition"].strip("[]").split()]
            k0 = min(range(4), key=lambda k: sum((v[k][a] - st[a]) ** 2 for a in range(3)))
            p0, p3, p1 = v[k0], v[(k0 + 1) % 4], v[(k0 + 3) % 4]
            offs = rows.get("offsets")
            for i in range(n + 1):
                for j in range(n + 1):
                    nr, dd = rows["normals"][i][3 * j:3 * j + 3], rows["distances"][i][j]
                    off = offs[i][3 * j:3 * j + 3] if offs else (0, 0, 0)
                    out.append((sd["material"].lower(), tuple(p0[a] + (p1[a] - p0[a]) * i / n + (p3[a] - p0[a]) * j / n + off[a] + nr[a] * dd for a in range(3))))
    return out


def clip_x(sol, xmax):
    """A lifted brush that is a box cut back so it ends at x = xmax (in the piece's frame), or None if it is not a box (or
    does not reach past xmax). For a Valve wall that runs on past where a piece is cut."""
    pts = [c for sd in sol["sides"] for c in (sd["corners"] or []) + sd["plane"]]
    if max(c[0] for c in pts) <= xmax or min(c[0] for c in pts) >= xmax or len(sol["sides"]) != 6 or any(sd.get("disp") for sd in sol["sides"]):
        return None
    for sd in sol["sides"]:
        pl = sd["plane"]
        if not any(all(abs(pl[0][k] - pl[i][k]) < 0.01 for i in (1, 2)) for k in range(3)):
            return None
    out = copy.deepcopy(sol)
    for sd in out["sides"]:
        for key in ("plane", "verts", "corners"):
            sd[key] = [[min(c[0], xmax), c[1], c[2]] for c in sd.get(key) or []]
    return out


def smooth(t):
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return t * t * (3 - 2 * t)


def lerp(a, b, w):
    return a + (b - a) * w


def _lattice(ix, iy, seed):
    h = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 32767.5 - 1.0


def noise(x, y, seed=0):
    """Smooth noise, -1 to 1, the same every run."""
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = x - ix, y - iy
    sx, sy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = _lattice(ix, iy, seed), _lattice(ix + 1, iy, seed)
    c, d = _lattice(ix, iy + 1, seed), _lattice(ix + 1, iy + 1, seed)
    return lerp(lerp(a, b, sx), lerp(c, d, sx), sy)


def rect_dist(x, y, r):
    """How far a point is outside a rectangle (0 inside)."""
    dx = max(r[0] - x, 0, x - r[2])
    dy = max(r[1] - y, 0, y - r[3])
    return math.hypot(dx, dy)


def path_dist(x, y, pts):
    """How far a point is from a line through pts."""
    best = 1e18
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        vx, vy = bx - ax, by - ay
        ln = vx * vx + vy * vy
        t = 0 if ln == 0 else max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / ln))
        d = (x - ax - vx * t) ** 2 + (y - ay - vy * t) ** 2
        if d < best:
            best = d
    return math.sqrt(best)


def curve(pts, per=12):
    """A smooth line through pts (Catmull-Rom), as many short straight pieces."""
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for k in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[k - 1], p[k], p[k + 1], p[k + 2]
        for s in range(per):
            t = s / per
            out.append(tuple(0.5 * ((2 * p1[a]) + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t * t
                                    + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t * t * t) for a in range(2)))
    out.append(tuple(pts[-1]))
    return out


def pick(rnd, weighted):
    total = sum(w for _, w in weighted)
    r = rnd.random() * total
    for item, w in weighted:
        r -= w
        if r <= 0:
            return item
    return weighted[-1][0]


# ---------------------------------------------------------------------------
# A forest: the shell, the gate, the ground, what grows on it
# ---------------------------------------------------------------------------

class Forest:
    RIM, RIM_WIDE = 440, 420
    SHORE_MUD = True # ground just above a water's level turns to dirt (the pond's shore)
    TREES = 0.75     # how thickly trees stand (the owner, after walking both: "too thick with trees ... reduce it about 25%")
    ROCKS_N, LOGS_N = 34, 12     # how many rocks and fallen logs

    def __init__(self, name, origin, z0, seed, first_node, gate):
        self.name, self.seed = name, seed
        self.ox, self.oy = origin
        self.z0 = z0                      # the gate's floor: the height everything is measured from
        self.W = self.D = 4096
        self.zb = z0 - 256                # under the lowest ground
        self.lid = z0 + 1536              # the sky
        self.gate = gate                  # (side, where along it the culvert starts)
        self.vmf = Vmf()
        self.rnd = random.Random(seed)
        self.buildings = []               # (Plan, its origin here): the ground dives under them
        self.waters = []                  # (x1, y1, x2, y2, level, deep, material)
        self.trails = []                  # lines the ground is worn to dirt along
        self.clearings = []               # (x, y, r): nothing is planted here
        self.trees = []                   # (x, y) of what was planted, for the checks and the picture
        self.node_id = first_node
        self.first_node = first_node
        self.problems = []
        self.notes = []
        self.test = False
        self.cuts = {}                    # side: (from, to) along it: a stretch of the shell's wall the piece builds itself (never the gate's side)
        self.rooms = []                   # (Plan, its origin here): rooms the ground must stay out of (under their floors or over their ceilings)
        self.placed = []                  # every solid prop static() and stand() put down, for settle()
        self.shell_walls = []             # the shell's sky walls as built (shell()), for the check that none stands in a room

    def keep_way_clear(self, box, label):
        """A space players must be able to walk through (a doorway, a hole, a gate's approach, a gallery's middle), as a
        box in the forest's own frame: map_build fails the piece if any prop's real size (asset_facts.json) stands in it
        (Vmf.keep_way_clear, ways_problems)."""
        self.vmf.keep_way_clear(self.box(*box), label)

    def ways_check(self):
        """(map_build runs the check for every piece now: ways_problems.)"""
        return

    def vis(self, what):
        return "LC %s: %s" % (self.name, what)

    # --- places -----------------------------------------------------------

    def w(self, x, y, z):
        return (self.ox + x, self.oy + y, z)

    def box(self, x1, y1, z1, x2, y2, z2):
        return (self.ox + min(x1, x2), self.oy + min(y1, y2), min(z1, z2), self.ox + max(x1, x2), self.oy + max(y1, y2), max(z1, z2))

    def to_st(self, x, y):
        """A point as (along the gate's wall, in from it)."""
        side = self.gate[0]
        return {"west": (y, x), "south": (x, y), "east": (y, self.W - x), "north": (x, self.D - y)}[side]

    def st(self, s, t):
        side = self.gate[0]
        return {"west": (t, s), "south": (s, t), "east": (self.W - t, s), "north": (s, self.D - t)}[side]

    def st_box(self, s1, t1, s2, t2, z1, z2):
        (xa, ya), (xb, yb) = self.st(s1, t1), self.st(s2, t2)
        return self.box(xa, ya, z1, xb, yb, z2)

    # --- the ground ---------------------------------------------------------

    def base_ground(self, x, y):
        s = self.seed
        return self.z0 + 24 + 42 * noise(x / 900.0, y / 900.0, s) + 14 * noise(x / 260.0, y / 260.0, s + 1)

    def rim(self, x, y):
        d = min(x, self.W - x, y, self.D - y)
        k = 1 - smooth(d / float(self.RIM_WIDE))
        return k * (self.RIM + 70 * noise(x / 380.0, y / 380.0, self.seed + 2))

    def gate_pad(self, x, y, h):
        """The ground is flat at the gate's floor between the headwall's wings, then eases back into the forest."""
        s, t = self.to_st(x, y)
        g = self.gate[1]
        ds = max(g - s, 0, s - (g + GATE_WIDE))
        if t <= 384:
            return self.z0 if ds == 0 else h
        w = (1 - smooth((t - 384) / 320.0)) * (1 - smooth(ds / 200.0))
        return lerp(h, self.z0, w)

    def natural(self, x, y, bias=None):
        raise NotImplementedError

    def height(self, x, y, bias=None):
        for plan, (bx, by), dive in self.buildings:
            if plan.inside(x - bx, y - by):
                return dive
        return self.natural(x, y, bias)

    def slope(self, x, y):
        e = 24.0
        return math.hypot(self.natural(x + e, y) - self.natural(x - e, y), self.natural(x, y + e) - self.natural(x, y - e)) / (2 * e)

    def dirt(self, x, y):
        """How much of the ground's second look (dirt) shows, 0 to 255."""
        a = 0.0
        for line in self.trails:
            d = path_dist(x, y, line)
            a = max(a, 255 * (1 - smooth((d - 36) / 80.0)))
        a = max(a, 210 * smooth((self.slope(x, y) - 0.8) / 0.6))
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if self.SHORE_MUD and x1 - 64 <= x <= x2 + 64 and y1 - 64 <= y <= y2 + 64:
                a = max(a, 255 * (1 - smooth((self.natural(x, y) - level - 4) / 22.0)))
        s, t = self.to_st(x, y)
        if self.gate[1] - 64 <= s <= self.gate[1] + GATE_WIDE + 64 and t < 520:
            a = max(a, 255 * (1 - smooth((t - 380) / 140.0)))
        a = max(a, self.extra_dirt(x, y))
        return a + 26 * noise(x / 90.0, y / 90.0, self.seed + 9)

    def extra_dirt(self, x, y):
        return 0

    # --- building it --------------------------------------------------------

    def shell(self):
        v, W, D, T = self.vmf, self.W, self.D, WALL
        sky, nd = MAT["sky"], MAT["nodraw"]
        vis = self.vis("shell (sky, walls, slab)")
        v.world_box(self.box(-T, -T, self.zb - 64, W + T, D + T, self.zb), nd, vis=vis)
        v.world_box(self.box(-T, -T, self.lid, W + T, D + T, self.lid + 16), sky, sky, sky, vis=vis)
        side, g = self.gate
        ends = {"west": (-T, D + T), "east": (-T, D + T), "south": (0, W), "north": (0, W)}
        frames = {"west": lambda a, b: (-T, a, 0, b), "east": lambda a, b: (W, a, W + T, b), "south": lambda a, b: (a, -T, b, 0), "north": lambda a, b: (a, D, b, D + T)}
        toward = {"west": ("north", "south"), "east": ("north", "south"), "south": ("east", "west"), "north": ("east", "west")}
        for name in ("west", "east", "south", "north"):
            a, b = ends[name]
            pieces = [(a, b, None)]
            if name == side:
                pieces = [(a, g, toward[name][0]), (g + GATE_WIDE, b, toward[name][1])]
            elif name in self.cuts:
                cuts = self.cuts[name] if isinstance(self.cuts[name], list) else [self.cuts[name]]
                pieces, a0 = [], a
                for c1, c2 in sorted(cuts):
                    pieces.append((a0, c1, None))
                    a0 = c2
                pieces.append((a0, b, None))
            for s1, s2, face in pieces:
                x1, y1, x2, y2 = frames[name](s1, s2)
                v.world_box(self.box(x1, y1, self.zb, x2, y2, self.lid), sky, vis=vis, faces={face: MAT["canal_wall"]} if face else None)
                self.shell_walls.append(self.box(x1, y1, self.zb, x2, y2, self.lid))
        # the gate: a culvert through the wall, with the wall carried on under and over it
        v.world_box(self.st_box(g, -T, g + GATE_WIDE, 0, self.zb, self.z0), MAT["canal_wall"], top=MAT["canal_floor"], vis=vis)
        v.world_box(self.st_box(g, -T, g + GATE_WIDE, 0, self.z0 + GATE_HIGH, self.lid), sky, bottom=MAT["ceiling"], vis=vis)
        gate_cap(v, self.st_box(g, -T, g + GATE_WIDE, -T + 64, self.z0, self.z0 + GATE_HIGH), self.st_box(g, -T + 80, g + GATE_WIDE, -T + 88, self.z0, self.z0 + GATE_HIGH),
                 "y" if side in ("west", "east") else "x", self.vis("gate's cap (delete to join)"))
        # an areaportal across the culvert, just inside the bars: the forest is drawn from outside only through it
        v.areaportal(self.st_box(g, -T + 110, g + GATE_WIDE, -T + 112, self.z0, self.z0 + GATE_HIGH), self.vis("areaportals"))
        # the headwall inside the forest: the ridge is held back over and beside the culvert
        z0 = self.z0
        head = [self.st_box(g - 64, 0, g + GATE_WIDE + 64, 64, z0 + GATE_HIGH, z0 + 448)]
        for s1 in (g - 64, g + GATE_WIDE):
            head.append(self.st_box(s1, 0, s1 + 64, 256, z0 - 64, z0 + 448))
            head.append(self.st_box(s1, 256, s1 + 64, 384, z0 - 64, z0 + 256))
        v.detail(self.headwall_cut(head), MAT["canal_wall"], vis=self.vis("structures"))

    def headwall_cut(self, head):
        """The headwall's boxes, with any hole a piece makes in them (none here)."""
        return head

    def ground(self):
        """The terrain: a displaced patch every 512 units, each corner at the height function's height."""
        v = self.vmf
        self.heights = {}
        lo, hi = 1e9, -1e9
        for py in range(0, self.D, PATCH):
            for px in range(0, self.W, PATCH):
                bias = (px + PATCH / 2, py + PATCH / 2)
                grid = {}
                for i in range(9):
                    for j in range(9):
                        x, y = px + j * STEP, py + i * STEP
                        h = self.height(x, y, bias)
                        grid[(i, j)] = (h, self.dirt(x, y))
                        self.heights.setdefault((x, y), []).append(h)
                        lo, hi = min(lo, h), max(hi, h)

                def target(i, j, grid=grid, px=px, py=py):
                    return self.w(px + j * STEP, py + i * STEP, grid[(i, j)][0])

                def alpha(i, j, grid=grid):
                    return grid[(i, j)][1]
                v.world_box(self.box(px, py, self.zb, px + PATCH, py + PATCH, self.zb + 16), MAT["nodraw"], top=FMAT["ground"],
                            vis=self.vis("ground"), disp={"top": (3, target, alpha)})
        if lo < self.zb + 20 or hi > self.lid - 200:
            self.problems.append("the ground goes from %d to %d: outside the shell's room (%d to %d)" % (lo, hi, self.zb + 20, self.lid - 200))
        torn = sum(1 for hs in self.heights.values() if max(hs) - min(hs) > 0.01)
        if torn != self.allowed_tears():
            self.problems.append("%d places where neighbouring ground patches don't meet (expected %d)" % (torn, self.allowed_tears()))
        self.ground_range = (lo, hi)
        # the ground must not pass through a room: every room square's four corners all under its floor or all over its ceiling
        crossed = 0
        for plan, (bx, by) in self.rooms:
            for (i, j), spec in plan.cells.items():
                if spec[0] == "solid":
                    continue
                x, y = bx + i * CELL, by + j * CELL
                bias = (x // PATCH * PATCH + PATCH / 2, y // PATCH * PATCH + PATCH / 2)
                hs = [self.height(x + dx, y + dy, bias) for dx in (0, CELL) for dy in (0, CELL)]
                if min(hs) < spec[3] - 2 and max(hs) > spec[1] + 2:
                    crossed += 1
        if crossed:
            self.problems.append("the ground passes through %d squares of rooms (it must be under their floors or over their ceilings)" % crossed)

    def allowed_tears(self):
        return 0

    def water(self):
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            self.vmf.world_box(self.box(x1, y1, level - deep, x2, y2, level), MAT["nodraw"], top=mat, vis=self.vis("water"))

    def wet(self, x, y):
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if x1 <= x <= x2 and y1 <= y <= y2 and self.natural(x, y) < level + 6:
                return True
        return False

    def kept_clear(self, x, y, margin=0):
        if min(x, self.W - x, y, self.D - y) < 70:
            return True
        for (cx, cy, r) in self.clearings:
            if math.hypot(x - cx, y - cy) < r + margin:
                return True
        for line in self.trails:
            if path_dist(x, y, line) < 84 + margin:
                return True
        for plan, (bx, by), dive in self.buildings:
            for dx in (-96, 0, 96):
                for dy in (-96, 0, 96):
                    if (int(x - bx + dx) // CELL, int(y - by + dy) // CELL) in plan.cells:
                        return True
        s, t = self.to_st(x, y)
        if self.gate[1] - 150 <= s <= self.gate[1] + GATE_WIDE + 150 and t < 620:
            return True
        return self.wet(x, y)

    def static(self, model, x, y, z, yaw, what, solid=6, pitch=0, fade=(-1, 0), movable=None):
        """fade: never, unless asked (the owner, 26 November: "now all the trees are invisible from the spawn and fade in, those
        need to not do that. it's like a ps2 game"). movable: (its height at a spot: a function of (x, y); where it may stand: a test of (x, y), or None for planting's
        own rules) for a rock or log that settle() may move off whatever it stands in."""
        self.vmf.point("prop_static", self.w(x, y, z), {
            "model": model, "angles": "%d %d 0" % (pitch, yaw), "skin": "0", "solid": solid, "disableshadows": "0",
            "screenspacefade": "0", "fademindist": fade[0], "fademaxdist": fade[1], "fadescale": "1"}, self.vis(what))
        if str(solid) != "0":
            self.placed.append({"ent": len(self.vmf.ents) - 1, "pt": len(self.vmf.points) - 1, "model": model, "at": self.w(x, y, z), "angles": "%d %d 0" % (pitch, yaw),
                                "movable": movable})

    def stand(self, model, x, y, z, yaw, what, fade=(-1, 0)):
        """A made thing standing ON z (furniture, the lorry, barriers), as the modules stand theirs: lifted by the model's
        own size (tables, couches, lockers and the lorry have their origin at their middle), and a physics model as a
        prop_dynamic_override (the compiler deletes it as a prop_static). Trees, plants and rocks keep static(): they are
        sunk into the ground on purpose."""
        cls, keys = standing_prop(model)
        keys = dict(keys, model=model, angles="0 %d 0" % yaw)
        if cls == "prop_static" and fade[0] != -1:
            keys.update({"fademindist": fade[0], "fademaxdist": fade[1]})
        at = self.w(x, y, stand_z(model, z))
        keys = dress_keys(model, at[0], at[1], keys)
        self.vmf.point(cls, at, keys, self.vis(what))
        self.placed.append({"ent": len(self.vmf.ents) - 1, "pt": len(self.vmf.points) - 1, "model": model, "at": at, "angles": keys.get("angles", "0 0 0"), "movable": None})

    def thin(self, x, y):
        """How much thinner than the rule the trees stand here (1: as the rule says). A forest may thin its own."""
        return 1.0

    def plant(self, leafy_near=None):
        """Trees, undergrowth, rocks and fallen wood, by rule: thick on the ridge, none on paths, water or buildings."""
        rnd, n = self.rnd, {"trees": 0, "plants": 0, "rocks": 0, "logs": 0}
        cell = 150
        for gy in range(0, self.D, cell):
            for gx in range(0, self.W, cell):
                x, y = gx + rnd.uniform(20, cell - 20), gy + rnd.uniform(20, cell - 20)
                d = min(x, self.W - x, y, self.D - y)
                want = 0.30 + 0.34 * (0.5 + 0.5 * noise(x / 700.0, y / 700.0, self.seed + 4))
                if d < 380:
                    want = 0.85
                want *= self.TREES * self.thin(x, y)
                if rnd.random() > want or self.kept_clear(x, y):
                    continue
                sl = self.slope(x, y)
                if sl > 1.7 or (sl > 0.8 and d >= 380 and rnd.random() < 0.5):
                    continue
                kinds = PINES
                if leafy_near and math.hypot(x - leafy_near[0], y - leafy_near[1]) < leafy_near[2] and rnd.random() < 0.6:
                    kinds = LEAFY
                self.static(pick(rnd, kinds), x, y, self.natural(x, y) - 8, rnd.randrange(0, 360, 5), "trees")
                self.trees.append((x, y))
                n["trees"] += 1
        for _ in range(2400):
            if n["plants"] >= 170:
                break
            x, y = rnd.uniform(90, self.W - 90), rnd.uniform(90, self.D - 90)
            if self.kept_clear(x, y, -30) or self.slope(x, y) > 0.7:
                continue
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0)
            n["plants"] += 1
        for kind, models, count, sink in (("rocks", ROCKS, self.ROCKS_N, 10), ("logs", LOGS, self.LOGS_N, 4)):
            for _ in range(900):
                if n[kind] >= count:
                    break
                x, y = rnd.uniform(120, self.W - 120), rnd.uniform(120, self.D - 120)
                if self.kept_clear(x, y, 20) or self.slope(x, y) > 0.8 or any(math.hypot(x - tx, y - ty) < 70 for tx, ty in self.trees):
                    continue
                self.static(rnd.choice(models), x, y, self.natural(x, y) - sink, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood",
                            movable=(lambda x, y, sink=sink: self.natural(x, y) - sink, None))
                n[kind] += 1
        self.planted = n

    def settle(self):
        """Rocks and fallen wood standing in a tree, in each other or in something made (the owner, 22 November: "a LOT
        of cases of trees being inside of giant rocks ... most noticeable on the little island in the pond"). Once all is
        planted, each one that overlaps something (as map_lint.py's overlap check sees it, a tree being its trunk) moves
        to the nearest spot, out to 640 away (turned, if it fits only so), where it overlaps nothing and planting's own rules let it stand; with none,
        it is left out. Nothing else moves, and nothing here draws on the forest's random numbers, so every other tree,
        plant and rock is where it was."""
        import map_lint as ML

        def box(r, at=None):      # (at the place as the file will say it: whole units)
            return ML.prop_box({"model": r["model"], "origin": "%d %d %d" % tuple(at or r["at"]), "angles": r["angles"]})

        def clash(a, ma, ata, b, mb, atb):
            ov = ML.overlap(a, b)
            if not ov or min(a[3] - a[0], a[4] - a[1], a[5] - a[2]) < 6 or min(b[3] - b[0], b[4] - b[1], b[5] - b[2]) < 6:
                return False
            (small, ms, ats), (large, ml, c) = sorted(((a, ma, ata), (b, mb, atb)), key=lambda t: ML.vol(t[0]))
            frac = ov / max(1.0, ML.vol(small))
            if frac < 0.3 or ("ladder" in ma and "ladder" in mb):
                return False
            if ML.SHELVES.search(ml.lower()) and ML.vol(small) < ML.vol(large) * 0.25:
                return False
            if ML.is_tree(ml):
                if not ML.overlap(small, (c[0] - 16, c[1] - 16, large[2], c[0] + 16, c[1] + 16, large[5])):
                    return False
            if ma == mb and frac < 0.6:
                return False
            return True

        def free(r, a):
            return not any(clash(a, r["model"], r["at"], o["box"], o["model"], tuple(int(v) for v in o["at"])) for o in self.placed
                           if o is not r and not o.get("gone") and o["box"])

        def plantable(x, y):
            return (120 <= x <= self.W - 120 and 120 <= y <= self.D - 120 and not self.kept_clear(x, y, 20) and self.slope(x, y) <= 0.8
                    and not any(math.hypot(x - tx, y - ty) < 70 for tx, ty in self.trees))
        for r in self.placed:
            r["box"] = box(r)
        moved = dropped = 0
        for r in self.placed:
            if not r["movable"] or not r["box"] or free(r, r["box"]):
                continue
            zf, rule = r["movable"]
            rule = rule or plantable
            x0, y0 = r["at"][0] - self.ox, r["at"][1] - self.oy
            spot = None
            p, yaw = r["angles"].split()[:2]
            for dist in range(48, 641, 32):
                for k in range(16):
                    x, y = x0 + dist * math.cos(k * math.pi / 8), y0 + dist * math.sin(k * math.pi / 8)
                    if not rule(x, y):
                        continue
                    at = self.w(x, y, zf(x, y))
                    for turn in (0, 90, 45, 135):      # (its own turn first; a long log may fit between trees turned)
                        ang = "%s %d 0" % (p, (int(yaw) + turn) % 360)
                        a = box(dict(r, angles=ang), at)
                        if free(r, a):
                            spot = (at, a, ang)
                            break
                    if spot:
                        break
                if spot:
                    break
            text = self.vmf.ents[r["ent"]]
            if spot:
                at, r["box"], ang = spot
                r["at"] = at
                text = re.sub(r'\t"angles" "%s"\n' % r["angles"], '\t"angles" "%s"\n' % ang, text, count=1)
                r["angles"] = ang
                self.vmf.ents[r["ent"]] = re.sub(r'\t"origin" "[^"]*"\n', '\t"origin" "%d %d %d"\n' % tuple(at), text, count=1)
                self.vmf.points[r["pt"]] = ("prop_static", tuple(at))
                moved += 1
            else:
                r["gone"] = True
                self.vmf.ents[r["ent"]] = ""
                dropped += 1
        gone = set(r["pt"] for r in self.placed if r.get("gone"))
        if gone:
            self.vmf.points = [p for k, p in enumerate(self.vmf.points) if k not in gone]
            for r in self.placed:
                r["pt"] = None      # (the indices no longer hold)
        self.settled = (moved, dropped)
        if moved or dropped:
            self.notes.append("settled: %d rocks and fallen logs moved off a tree, a rock, a log or a made thing they stood in, %d left out (no free spot near)" % (moved, dropped))

    def node(self, x, y, z):
        self.vmf.point("info_node", self.w(x, y, z + 16), {"nodeid": self.node_id}, self.vis("path nodes"))
        self.node_id += 1

    NODE_STEP = 256     # the ground's path nodes, this far apart

    def ground_nodes(self):
        """Where the city's people can walk: a node every NODE_STEP units on ground that is dry, open and not steep."""
        step = self.NODE_STEP
        for y in range(step // 2, self.D, step):
            for x in range(step // 2, self.W, step):
                if self.slope(x, y) > 0.5 or self.wet(x, y) or any(math.hypot(x - tx, y - ty) < 56 for tx, ty in self.trees):
                    continue
                inside = False
                for plan, (bx, by), dive in self.buildings:
                    if (int(x - bx) // CELL, int(y - by) // CELL) in plan.cells:
                        inside = True
                if not inside:
                    self.node(x, y, self.natural(x, y))

    def plan_nodes(self, plan, origin, skip=()):
        for (i, j), spec in sorted(plan.cells.items()):
            if spec[0] == "solid" or i % 3 != 1 or j % 3 != 1:
                continue
            x, y = i * CELL + 32, j * CELL + 32
            if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in skip):
                continue
            self.node(origin[0] + x, origin[1] + y, spec[1])

    def finish(self):
        self.vmf.point("env_cubemap", self.w(self.W / 2, self.D / 2, self.natural(self.W / 2, self.D / 2) + 96), {"cubemapsize": "0"}, self.vis("structures"))
        # gates NPCs walk through switch their path links as they open and shut, as the modules' do (Valve's
        # info_node_link_controller: map_modules.link_gates; the cave's fence gate, the bunker's room doors)
        import types
        import map_modules
        map_modules.link_gates(types.SimpleNamespace(vmf=self.vmf, vis="LC %s" % self.name))
        if self.test:
            # (to compile and walk it by itself: a spawn point on the trail just inside the gate, and the map's sun)
            sx, sy = self.st(self.gate[1] + GATE_WIDE / 2, 220)
            yaw = {"west": 0, "south": 90, "east": 180, "north": 270}[self.gate[0]]
            test_extras(self.vmf, self.w(sx, sy, self.z0 + 16), yaw, self.vis("for testing alone (never in the real map)"))
        problems, air = check(self.vmf, self.w(self.W / 2, self.D / 2, self.lid - 100), [])
        self.problems += problems
        self.skin_check()
        self.ways_check()
        seals = sum(1 for _, s in self.vmf.boxes if s)
        side, g = self.gate
        (ax, ay), (bx, by) = self.st(g, -WALL), self.st(g + GATE_WIDE, -WALL)
        print("%s: %d sealing brushes, %d displaced faces, %d entities (%d trees, %d plants, %d rocks, %d logs, %d path nodes with ids %d to %d)" % (
            self.name, seals, self.vmf.disp_count, len(self.vmf.ents), self.planted["trees"], self.planted["plants"], self.planted["rocks"], self.planted["logs"],
            self.node_id - self.first_node, self.first_node, self.node_id - 1))
        print("  it fills x %d to %d, y %d to %d, z %d to %d; the ground runs from z %d to %d" % (
            self.ox - WALL, self.ox + self.W + WALL, self.oy - WALL, self.oy + self.D + WALL, self.zb - 64, self.lid + 16, self.ground_range[0], self.ground_range[1]))
        print("  gate (a culvert %d wide, %d high, floor z %d) in the %s wall: from (%d %d) to (%d %d)" % (
            GATE_WIDE, GATE_HIGH, self.z0, side, self.ox + ax, self.oy + ay, self.ox + bx, self.oy + by))
        for n in self.notes:
            print("  " + n)
        if self.problems:
            for p in self.problems:
                print("  PROBLEM: " + p)
        else:
            print("  checked: every brush corner on the grid; the shell is sealed; every ground patch meets its neighbours; the ground stays inside the shell")

    def skin_check(self):
        """Displaced faces: how many quads are folded back, and (for skins that aren't the ground) do their edges meet?"""
        made = self.vmf.disp_made
        folded = sum(m[2] for m in made)
        quads = sum(m[3] for m in made)
        if folded:
            self.notes.append("%d of %d displaced quads face backwards from the brush face they hang on (a sharply curved skin does this; a few are harmless)" % (folded, quads))
        skin = [m for m in made if m[0] != self.vis("ground") and m[0] not in getattr(self, "skin_skip", ())]
        if skin:
            cells = {}
            for k, m in enumerate(skin):
                for pt in m[1]:
                    cells.setdefault((round(pt[0] * 2), round(pt[1] * 2), round(pt[2] * 2)), set()).add(k)
            alone = sum(1 for ks in cells.values() if len(ks) < 2)
            self.notes.append("the cave's skin: %d faces; %d of its %d edge points meet another piece (the rest are the rock face's outer edge, expected %d)" % (
                len(skin), len(cells) - alone, len(cells), self.free_edge_points()))
            if alone != self.free_edge_points():
                self.problems.append("the cave's skin has %d loose edge points, expected %d" % (alone, self.free_edge_points()))

    def free_edge_points(self):
        return getattr(self, "skin_free", 0)

    # --- a picture from above, to look at before the owner does ---------------

    def preview(self, path):
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            print("  (no picture: Pillow isn't installed)")
            return
        step = 16
        nx, ny = self.W // step, self.D // step
        hs = [[self.natural(i * step, (ny - 1 - j) * step) for i in range(nx + 1)] for j in range(ny + 1)]
        img = Image.new("RGB", (nx, ny))
        px = img.load()
        for j in range(ny):
            for i in range(nx):
                x, y = i * step, (ny - 1 - j) * step
                h = hs[j][i]
                shade = 0.62 + ((hs[j][i] - hs[j][i + 1]) + (hs[j][i] - hs[j + 1][i])) / 46.0
                shade = max(0.25, min(1.25, shade))
                d = max(0.0, min(1.0, self.dirt(x, y) / 255.0))
                col = (lerp(70, 132, d), lerp(112, 104, d), lerp(58, 72, d))
                level = None
                for (x1, y1, x2, y2, lv, deep, mat) in self.waters:
                    if x1 <= x <= x2 and y1 <= y <= y2 and h < lv:
                        level = lv
                if level is not None:
                    k = min(1.0, (level - h) / 60.0)
                    col, shade = (lerp(70, 28, k), lerp(130, 70, k), lerp(160, 120, k)), 1.0
                px[i, j] = tuple(int(max(0, min(255, c * shade))) for c in col)
        img = img.resize((nx * 4, ny * 4), Image.BILINEAR)
        dr = ImageDraw.Draw(img, "RGBA")

        def P(x, y):
            return (x / 4.0, (self.D - y) / 4.0)
        for plan, (bx, by), dive in self.buildings:
            for (i, j), spec in plan.cells.items():
                a, b = P(bx + i * CELL, by + (j + 1) * CELL), P(bx + (i + 1) * CELL, by + j * CELL)
                dr.rectangle((a[0], a[1], b[0], b[1]), fill=(150, 150, 156, 255) if spec[0] == "solid" else (52, 52, 58, 255))
        self.preview_extra(dr, P)
        for (x, y) in self.trees:
            c = P(x, y)
            dr.ellipse((c[0] - 5, c[1] - 5, c[0] + 5, c[1] + 5), fill=(22, 60, 30, 210))
        s1, s2 = self.st(self.gate[1], 0), self.st(self.gate[1] + GATE_WIDE, 0)
        dr.line((P(*s1), P(*s2)), fill=(255, 220, 60, 255), width=5)
        dr.text((8, 8), "%s  (north up, %d by %d units; yellow: the gate)" % (self.name, self.W, self.D), fill=(255, 255, 255, 255))
        img.save(path)
        print("  picture: " + path)

    def preview_extra(self, dr, P):
        pass


# ---------------------------------------------------------------------------
# The bunker, and the pond with its island
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# White Forest's walls
# ---------------------------------------------------------------------------

WF_BAND = 128       # concretewall_bunker05b, White Forest's foot texture: 512 texels high at 0.25, 128 units, laid from the floor
WF_DIRS = (("east", 1, 0), ("west", -1, 0), ("north", 0, 1), ("south", 0, -1))


def wf_face(name, floor, z1, z2):
    """The material and texture axes of an upright face of a White Forest wall, from z1 to z2, over a room whose floor is
    at `floor`, as Valve lays them in ep2_outland_11 (counted 22 November: concretewall_bunker05b on the 128 over the
    floor, 05a over that, both at 0.25 with the texture's foot on the floor: 49 of its 05b faces are exactly 128 high and
    fit it, and 05a stands over 05b, never under it). None when the face looks at nothing (hidden)."""
    if floor is None:
        return None
    mat = FMAT["wf_foot"] if floor <= z1 and z2 <= floor + WF_BAND else FMAT["wf_upper"]
    u = "[0 1 0 0] 0.25" if name in ("east", "west") else "[1 0 0 0] 0.25"
    return mat, (u, "[0 0 -1 %d] 0.25" % ((4 * floor) % 512))


def wf_box(vmf, box, faces, vis, top=None, bottom=None, world=True):
    """A box whose upright faces are laid by wf_face: faces is {name: (material, axes) or None (nodraw)}."""
    mats = {k: (v[0] if v else MAT["nodraw"]) for k, v in faces.items()}
    axes = {k: v[1] for k, v in faces.items() if v}
    text = vmf.box_text(box, MAT["nodraw"], top or MAT["nodraw"], bottom or MAT["nodraw"], vis, faces=mats, axes=axes)
    if world:
        vmf.world.append(text)
        vmf.boxes.append((box, True))
    return text


class WFPlan(Plan):
    """A Plan walled as White Forest's base is (WF_BAND, wf_face): every upright face of its walls, and of the floors and
    lintels beside a room, takes the floor of the room it looks into, so the band runs level all round each room and round
    its corners whatever the level (the owner, 22 November: "the wall textures are atrocious, they aren't aligned ...
    Adjusted properly on their Y axis?"). A stair takes the floor at its foot (the band shows under the steps as they go
    down). A face looking out of the piece takes `outside` (the ground at the bunker's door), a face against another
    square nothing. `others`: Plans on the same grid whose rooms these walls may look into. `sills`: doorway squares whose
    floor stops 4 short, for the sill of a door frame (room_doors). `windows`: wall squares a window goes through,
    {square: (bottom, top)} of the gap left in them, which BunkerForest.shutter_window fills in round the window."""

    def __init__(self, origin, base, top, outside=None, **kw):
        Plan.__init__(self, origin, [(base, top, FMAT["wf_upper"])], **kw)
        self.outside = outside
        self.others = []
        self.sills = set()
        self.windows = {}

    def looks_at(self, c):
        """The floor of the room a face looks into from square c's side: ("room", floor), ("out",) or None (a solid square)."""
        for p in [self] + self.others:
            s = p.cells.get(c)
            if s:
                return ("room", s[1]) if s[0] != "solid" else None
        return ("out",)

    def build(self, vmf):
        self.walls()
        keys, facing_of = {}, {}
        for (i, j), spec in self.cells.items():
            facing_of[(i, j)] = tuple(self.looks_at((i + di, j + dj)) for _, di, dj in WF_DIRS)
            if spec[0] == "solid":
                gap = self.windows.get((i, j))
                cols = ((self.base, gap[0], None, None), (gap[1], self.top, None, self.roof)) if gap else ((self.base, self.top, None, self.roof),)
            elif spec[0] == "low":
                cols = ((self.base, spec[1] - (4 if (i, j) in self.sills else 0), None, spec[2]), (spec[3], self.top, self.ceiling, self.roof))
            else:
                cols = ((self.base, spec[1], None, spec[2]),)
            keys[(i, j)] = (spec[0], cols)

        def sides(i, j, w, h):
            """What each side of a w by h block of squares looks into, or None if two of its squares look into different
            things (it cannot then be one brush)."""
            out = []
            for n, (name, _, _) in enumerate(WF_DIRS):
                edge = {"east": [(i + w - 1, j + q) for q in range(h)], "west": [(i, j + q) for q in range(h)],
                        "north": [(i + q, j + h - 1) for q in range(w)], "south": [(i + q, j) for q in range(w)]}[name]
                seen = set(facing_of[c][n] for c in edge) - {None}
                if len(seen) > 1:
                    return None
                out.append(seen.pop() if seen else None)
            return tuple(out)
        left = dict(keys)
        for (i, j) in sorted(keys):      # (squares alike joined into rectangles as Plan does, each side looking into one thing)
            if (i, j) not in left:
                continue
            k = left[(i, j)]
            w = 1
            while left.get((i + w, j)) == k and sides(i, j, w + 1, 1):
                w += 1
            h = 1
            while all(left.get((i + q, j + h)) == k for q in range(w)) and sides(i, j, w, h + 1):
                h += 1
            for a in range(w):
                for b in range(h):
                    del left[(i + a, j + b)]
            x1, y1, x2, y2 = i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL
            (kind, cols), facing = k, sides(i, j, w, h)
            # the floor each face is laid from: a room's own; out of the piece, plain 05a laid from the ground at the door (or
            # the base, for a buried part), never banded (1024 under: always "above the band", the same texture phase)
            out = (self.outside if self.outside is not None else self.base) - 1024
            floors = [(f[1] if f[0] == "room" else out) if f else None for f in facing]
            if kind == "open":
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), MAT["sky"], MAT["sky"], MAT["sky"], vis=self.vis)
            for (a, b, bottom, topm) in cols:
                cuts = {a, b}
                for f in facing:
                    if f and f[0] == "room":
                        cuts |= {f[1], f[1] + WF_BAND}
                hs = sorted(z for z in cuts if a <= z <= b)
                for q in range(len(hs) - 1):
                    z1, z2 = hs[q], hs[q + 1]
                    faces = {name: wf_face(name, f, z1, z2) for (name, _, _), f in zip(WF_DIRS, floors)}
                    wf_box(vmf, self.box(x1, y1, z1, x2, y2, z2), faces, self.vis, top=topm if z2 == b else None, bottom=bottom if z1 == a else None)


class BunkerForest(Forest):
    POND = (1500, 1400, 640, 480)   # centre x, y; half its length and width
    ISLE = (1560, 1385, 260)
    B0 = (2368, 3072)               # the bunker's own corner: its door's wall is its south side. (Its x is chosen so the foot of
                                    # the second stairs, JOIN east of it, is on a line between two ground patches: see height().)
    DOOR = (512, 768)               # the doorway, in the bunker's own coordinates: 256 wide and 192 high, shut by two sliding leaves
    JOIN = 192                      # where the second stairs come down into the big room: the first level's plan stops, the deep level's begins
    # The deep level since 24 November (the owner: "for the bunker itself ... a bigger room would work better than tons of
    # small pointless rooms; keep the room that is a bedroom with the toilet/sink at the beginning of the bunker, and the
    # generator room at the end"; then "joined up by the silo please; and it is ok to reorganize the bunker to make this
    # work; so long as the bedroom/bathroom room and the red plant room remain the same inside then they can be moved
    # around"): at the foot of the second stairs a walkway west to the plant room (the far end) and the corridor to the
    # silo, and a walkway north and east under the hill to the control complex up by the silo (map_launch.py). Each is
    # (the squares, "room" or "door"): the walkway west; the plant room's door and the room; the corridor's door and the
    # corridor; the walkway to the complex north, east along the hill's foot, north through the forest's wall (NE_LEG).
    NE_LEG = (1344, 1472)
    DEEP = (((-704, 640, 192, 768), "room"),
            ((-768, 640, -704, 768), "door"), ((-1088, 512, -768, 832), "room"),
            ((-704, 768, -576, 832), "door"), ((-704, 832, -576, 1088), "room"),
            ((64, 768, 192, 960), "room"), ((64, 960, 1472, 1088), "room"), ((1344, 1088, 1472, 1280), "room"))
    PLANT = (-928, 672)             # the plant room's middle (its inside as it was, moved with it)
    # thinner (the owner, 22 November: "can we also please thin out the forest and rocks in the forest area? they are way
    # too thick and even the watchtower is useless because you can't see anything from it"): about half the trees (thin()),
    # half the rocks and fallen logs
    ROCKS_N, LOGS_N = 17, 6

    def thin(self, x, y):
        """The bunker forest's trees, about half as many as the rule gives, in Episode Two's way (clusters and clearings,
        not an even scatter: a slow noise decides which, a clearing keeping a tree in seven of a cluster's), and thinner
        still near the trail, the pond and the bunker, so there are views across the valley. The rim (380 deep) keeps
        most of its trees (0.7 of the rule): they hide the forest's edge. Nothing here draws on the forest's random numbers."""
        d = min(x, self.W - x, y, self.D - y)
        if d < 380:
            return 0.7
        c = 0.5 + 0.5 * noise(x / 900.0, y / 900.0, self.seed + 21)
        f = 0.14 + 0.86 * smooth((c - 0.3) / 0.45)
        tr = min(path_dist(x, y, t) for t in self.trails) if self.trails else 1e9
        f *= 0.3 + 0.7 * smooth((tr - 120) / 420.0)
        cx, cy, rx, ry = self.POND
        f *= 0.3 + 0.7 * smooth((math.hypot((x - cx) / rx, (y - cy) / ry) - 1.15) / 0.9)
        bx, by = self.B0
        f *= 0.3 + 0.7 * smooth(rect_dist(x, y, (bx - 384, by - 420, bx + 1280, by + 1100)) / 520.0)
        return min(1.0, 0.9 * f)

    def setup(self):
        z0 = self.z0
        self.zb = z0 - 448               # (the deep rooms need the forest's slab lower than a forest's usual 256)
        self.zp = z0 + 24                # the ground at the bunker's door
        self.zl = self.zp - 128          # the first level, down the first stairs
        self.zd = self.zl - 192          # the deep level, down the second
        self.level = z0 - 6              # the pond's surface
        self.trails.append(curve([(0, 3328), (500, 3328), (1100, 2900), (1560, 2180), (2300, 2520), (3008, 2760), (3008, 3060)]))
        self.clearings += [(self.POND[0], self.POND[1], 760), (3008, 2880, 260)]
        self.waters.append((704, 768, 2304, 2048, self.level, self.level - (self.zb + 16), FMAT["pond"]))
        zp, zl, zd, fm = self.zp, self.zl, self.zd, FMAT["wf_floor"]
        self.zg = zg = zd - 256          # the silo's gantry level: down 256 from the deep level (the silo piece's advice)
        origin = (self.ox + self.B0[0], self.oy + self.B0[1])
        look = dict(floor_side=FMAT["wf_upper"], ceiling=FMAT["wf_ceiling"], vis=self.vis("structures"))
        # the part under the mound: its roof is level with the mound's top, and the ground dives under it. Walls in White
        # Forest's two concretes laid from each room's own floor (WFPlan); the front, out of the mound, from the ground at the door
        plan = WFPlan(origin, zd - 64, zp + 272, outside=zp, roof=FMAT["bunker_floor"], **look)
        # The plan since 24 November (the owner: "for the bunker itself, can we look at the EP2 white forest rooms and just
        # copy/paste the layout and concepts? ... a bigger room would work better than tons of small pointless rooms; keep
        # the room that is a bedroom with the toilet/sink at the beginning of the bunker, and the generator room at the end"):
        # the door, the room inside it and the first stairs as they were; at their foot a short hall with the bunk room off
        # its east end and the second stairs down west; at their foot ONE big room, White Forest's control room (BIG), and
        # off it the plant room at the far end and the corridor to the silo.
        plan.keep_out += [(-100000, -100000, 100000, 0), (-100000, 576, self.JOIN, 832)]   # in front of the door; where the deep level joins
        plan.paint((512, 0, 768, 64), ("low", zp, fm, zp + 192))      # the doorway: 256 wide, 192 high
        plan.paint((448, 64, 832, 256), ("low", zp, fm, zp + 208))    # the room inside the door (its front wall is what the door's leaves slide into)
        plan.paint((576, 256, 704, 448), ("low", zl, fm, zp + 160))   # the stairs down
        plan.paint((576, 448, 704, 640), ("low", zl, fm, zl + 160))   # their foot, and on to the hall
        plan.paint((512, 640, 896, 832), ("low", zl, fm, zl + 160))   # the hall (each doorway between rooms is 128 wide: a frame narrows it to the door's 96)
        plan.paint((896, 640, 960, 768), ("low", zl, fm, zl + 128))
        plan.paint((960, 576, 1216, 832), ("low", zl, fm, zl + 160))  # east: the bunks (a dead end)
        plan.paint((self.JOIN, 640, 512, 768), ("low", zd, fm, zl + 160))    # west: the second stairs, down to the big room
        plan.walls()
        # the deep level: wholly under the ground, so nothing of it shows outside
        deep = WFPlan(origin, zd - 64, zd + 224, **look)
        # (the walkway to the complex ends at the control room's south wall, 1280 north, past the forest's north wall; the
        #  corridor to the silo goes on north as the low plan)
        deep.keep_out += [(self.JOIN, 576, 100000, 832), (-100000, 1088, -448, 100000), (-100000, 1280, 100000, 100000)]
        room = ("low", zd, fm, zd + 160)
        door = ("low", zd, fm, zd + 128)
        for rect, spec in self.DEEP:
            deep.paint(rect, room if spec == "room" else door)
        deep.walls()
        # (every doorway square has its door, and every door its doorway: a door left behind when the plan moves leaves a
        #  gaping hole where its frame should be)
        doors = set(d for lv, d, _, _, _ in self.ROOM_DOORS if lv == 1)
        ways = set(rect for rect, spec in self.DEEP if spec == "door")
        for d in sorted(doors ^ ways):
            self.problems.append("the deep level's doorway %s has %s" % (d, "no door (ROOM_DOORS)" if d in ways else "a door but no doorway (DEEP)"))
        low = WFPlan(origin, zg - 64, zd + 224, **look)
        low.keep_out += [(-100000, -100000, 100000, 1088), (-100000, 1600, 100000, 100000)]
        low.paint((-704, 1088, -576, 1472), ("low", zg, fm, zd + 160))      # the stairs (their steps are detail: a landing, then 15 steps ending at 1472)
        low.paint((-768, 1472, -512, 1600), ("low", zg, fm, zg + 192))      # the last of the corridor, as wide and high as the silo's door (silo_door)
        low.walls()
        self.low = low
        # the silo: its west tunnel (now turned to face south) meets the corridor's end at y 1600 of the bunker, its
        # gantry level is the corridor's floor; the forest's north wall is cut where the corridor and its walls pass
        self.silo_at = (origin[0] - 640, origin[1] + 1600 + 544, zg - 1408)
        # (and where the leader's way out passes it, since 24 November: map_silo.py's WAY_X, its walls with it)
        # (and where the walkway to the complex passes: its run east straddles the forest's edge (y 1024 of the bunker), so the
        #  wall is cut along all of it, its walls with it, from x 0 to the north leg's east wall. The owner, 24 November:
        #  "... no wall at all visible and it's all open to the void": the forest's sky wall had stood in its north half.)
        self.cuts["north"] = [(self.B0[0] - 768, self.B0[0] - 512), (MS.WAY_X[0] - MS.WAY_T - self.ox, MS.WAY_X[1] + MS.WAY_T - self.ox),
                              (self.B0[0] + min(r[0] for r, _ in self.DEEP if r[0] >= 0 and r[3] > self.D - self.B0[1]) - 64, self.B0[0] + self.NE_LEG[1] + 64)]
        self.plan, self.deep = plan, deep
        for p in (plan, deep, low):     # (each one's walls may look into the others' rooms where they meet)
            p.others = [q for q in (plan, deep, low) if q is not p]
        for level, (u1, v1, u2, v2), way, room, slide in self.ROOM_DOORS:      # (a doorway's floor stops 4 short, for its frame's sill)
            for i in range(u1 // CELL, u2 // CELL):
                for j in range(v1 // CELL, v2 // CELL):
                    (plan, deep)[level].sills.add((i, j))
        self.window_spots()
        self.buildings.append((plan, self.B0, zd - 110))
        self.rooms += [(plan, self.B0), (deep, self.B0)]
        if (self.B0[0] + self.JOIN) % PATCH:
            self.problems.append("the foot of the bunker's second stairs is not on a line between two ground patches: the ground would cross the stairwell")

    def height(self, x, y, bias=None):
        # The ground is under the bunker's floors (it "dives") and over the deep level's roof. Where the second stairs run
        # from one into the other it cannot do both, and the first try let it slope across the stairwell (the owner: "the
        # stairs down in the bunker have a ground geometry/brush blocking them"). So the ground is TORN there: along the
        # line at the stairs' foot the patch to the east is under the floor and the patch to the west is the forest's
        # floor above. The slit between them is in the wall that stands on the deep level's roof.
        jx, by = self.B0[0] + self.JOIN, self.B0[1]
        if x == jx and bias is not None and bias[0] > jx and by + 640 <= y <= by + 768:
            return self.zd - 110
        # and TORN along the foot of the gate's north wing wall where the leader's way out comes out through it (map_silo.py's
        # EXIT): the patch to the north lifts its edge there over the door's head, so it slopes up inside the wall and never
        # across the doorway, while the patch to the south stays flat at the gate's floor to the door's foot. The slit
        # between them is in the wall's face, behind the door.
        gy = self.gate[1] + GATE_WIDE
        if y == gy and bias is not None and bias[1] > gy and x in self.exit_tears():
            return self.z0 + 300
        return Forest.height(self, x, y, bias)

    def exit_tears(self):
        """The ground's points along the north wing wall's foot that the way out's door stands between."""
        return [x for x in range(0, self.W + 1, STEP) if MS.EXIT[0] - self.ox <= x <= MS.EXIT[1] - self.ox]

    def allowed_tears(self):
        return 3 + len(self.exit_tears())

    def headwall_cut(self, head):
        """The gate's north wing wall cut round the way out's hidden door (map_silo.py's EXIT: the door is the piece of wall
        that fills the hole, laid as the wall): beside it, under it and over it."""
        ex1, ex2, ez1, ez2 = MS.EXIT
        out = []
        for b in head:
            if b[0] < ex1 and b[3] > ex2 and b[1] == MS.EXIT_FACE and b[4] == MS.EXIT_BACK and b[2] < ez1 and b[5] > ez2:
                out += [(b[0], b[1], b[2], ex1, b[4], b[5]), (ex2, b[1], b[2], b[3], b[4], b[5]),
                        (ex1, b[1], b[2], ex2, b[4], ez1), (ex1, b[1], ez2, ex2, b[4], b[5])]
            else:
                out.append(b)
        if len(out) != len(head) + 3:
            self.problems.append("the way out's door does not stand in the gate's north wing wall")
        return out

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        # the mound the bunker is under: level with its roof, falling away on every side
        bx, by = self.B0
        mound = self.zp + 268 * (1 - smooth(rect_dist(x, y, (bx - 384, by + 448, bx + 1280, by + 1100)) / 400.0))
        h = max(h, mound, self.exit_berm(x, y))
        # flat at the door, as far as the door swings
        h = lerp(h, self.zp, 1 - smooth(rect_dist(x, y, (bx + 448, by - 340, bx + 832, by)) / 170.0))
        # the pond: a bowl, a shore, and nothing else below the water near it
        cx, cy, rx, ry = self.POND
        ang = math.atan2(y - cy, x - cx)
        wob = 1 + 0.10 * noise(math.cos(ang) * 1.4 + 7, math.sin(ang) * 1.4, self.seed + 6)
        e = math.hypot((x - cx) / rx, (y - cy) / ry) / wob
        lv = self.level
        if e < 1.4:
            if e < 1:
                bowl = lv - 6 - 92 * (1 - e * e) ** 0.8
            else:
                bowl = lerp(lv - 6, max(h, lv + 16), smooth((e - 1) / 0.4))
            h = bowl
            ix, iy, ir = self.ISLE
            h = max(h, lv - 62 + 104 * (1 - smooth(math.hypot(x - ix, y - iy) / ir)))
        elif 640 <= x <= 2368 and 704 <= y <= 2112:
            h = max(h, lv + 12)
        return self.gate_pad(x, y, h)

    # the leader's way out on the north rim (map_silo.py): the hollow in front of its face of rock, level with the hole's
    # sill, and the ridge that hides it, along its front and up its east side to the forest's wall (map coordinates)
    EXIT_HOLLOW = (8640, 5080, 9420, 822)          # from x, from y (to the wall), to x; its floor
    EXIT_RIDGE = ((8860, 5000), (9420, 5000), (9420, 5200))
    EXIT_RIDGE_TOP = 910

    # (with the forest thinned there is more open ground: the ground's nodes a little further apart keep the piece within
    # its share of path nodes, 150)
    NODE_STEP = 288

    def node(self, x, y, z):
        # (no path node in the hollow before the leader's way out, nor on the ridge that hides it: the city's people walking
        # there would give it away)
        X, Y = x + self.ox, y + self.oy
        if 8560 <= X <= 9520 and Y >= 4900 and z > 700:
            return
        Forest.node(self, x, y, z)

    def exit_berm(self, x, y):
        """The ground the leader's way out wants (the owner, 22 November: "I can see the secret tunnel exit even clearer,
        and even from the lookout tower"): a ridge 910 high in front of the face of rock and up its east side, sides of 45
        degrees, so the hole (828 to 908) is out of sight from the valley and from the bunker, and inside it a hollow at
        the hole's sill (822) that opens west, the way the escapers go. Only ever raises the ground (natural takes the
        highest)."""
        X, Y = x + self.ox, y + self.oy
        h = -1e9
        x1, y1, x2, floor = self.EXIT_HOLLOW
        if Y >= y1 and x1 <= X <= x2:
            h = floor - max(0.0, x1 + 120 - X) * 0.3          # (easing down to the ground at its open west end)
        d = path_dist(X, Y, self.EXIT_RIDGE)
        return max(h, self.EXIT_RIDGE_TOP - max(0.0, d - 16))

    def extra_dirt(self, x, y):
        bx, by = self.B0
        return 255 * (1 - smooth(rect_dist(x, y, (bx + 448, by - 300, bx + 832, by)) / 150.0))

    def bunker(self):
        v, plan, deep, low, zp, zl, zd, zg = self.vmf, self.plan, self.deep, self.low, self.zp, self.zl, self.zd, self.zg
        plan.build(v)
        deep.build(v)
        low.build(v)
        B, W, bx, by = plan.box, plan.world, self.B0[0], self.B0[1]
        vis, wall = self.vis("structures"), FMAT["wf_floor"]
        # where the two parts meet: the stairwell is higher than the deep level's top, so a wall stands on that top (its
        # face to the stairwell laid from the stairwell's foot, as the walls beside it; its top is the roof's)
        jx, top = self.JOIN, zd + 224
        wf_box(v, B(jx - 64, 576, top, jx, 832, zp + 272), {"east": wf_face("east", zd, top, zp + 272)}, vis, top=FMAT["bunker_floor"])
        # the stairs: 15 steps north down to the first level; 11 of 16 by 24 west from a landing down to the deep level (since
        # 24 November: 23 of 8 by 12 before); and the silo's 15 steps of 16 by 24 north and down to its gantry level (lesson
        # stairs-16-24), wall to wall; the risers in the floor's plain concrete (in the banded wall's they showed a stripe of
        # band on some and not on others)
        v.detail([B(576, 256 + 12 * k, zl, 704, 268 + 12 * k, zp - 8 * (k + 1)) for k in range(15)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(456 - 24 * (k + 1), 640, zd, 456 - 24 * k, 768, zl - 16 * (k + 1)) for k in range(11)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(456, 640, zd, 512, 768, zl)], wall, vis=vis, top=wall)          # (their top landing, level with the hall)
        v.detail([B(-704, 1112 + 24 * k, zg, -576, 1136 + 24 * k, zd - 16 * (k + 1)) for k in range(15)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(-704, 1088, zg, -576, 1112, zd)], wall, vis=vis, top=wall)      # (the stairs' top landing, level with the corridor)
        # the control complex up by the silo (map_launch.py): White Forest's control room and Episode Two's launch room
        self.complex_air, complex_places = ML.build(self, sys.modules[__name__])
        self.door()
        self.room_doors()
        self.silo()
        ML.safety(self)         # (the silo's doors shut and locked at a launch, the launch tube's fire: map_launch.py)
        self.dress()
        self.soundscapes()
        self.roof_fence()
        for model, x, y, yaw in (("models/props_c17/concrete_barrier001a.mdl", bx + 380, by - 110, 80), ("models/props_c17/concrete_barrier001a.mdl", bx + 920, by - 130, 100),
                                 ("models/props_vehicles/truck001a.mdl", bx + 300, by - 360, 35)):
            self.stand(model, x, y, self.natural(x, y), yaw, "structures")
        self.plan_nodes(plan, self.B0, skip=[(576, 256, 704, 448), (jx, 640, 512, 768)])
        self.plan_nodes(deep, self.B0, skip=[(-704, 768, -576, 832), (-768, 640, -704, 768)])
        for (u, w, z) in ((640, 296, zp - 32), (640, 364, zp - 72), (640, 420, zp - 116), (420, 704, zl - 32), (336, 704, zl - 80), (252, 704, zl - 144), (160, 704, zd)):
            self.node(bx + u, by + w, z)
        # the bunker's rooms must be shut in on every side but the doorway (for the look of it, and for the door's areaportal):
        # with the doorway stopped up, air from inside must not reach the forest. The silo and the way to it are inside.
        # (and with the leader's way out stopped where it comes through the forest's wall: map_silo.py)
        closed = flood(v, W(640, 160, zp + 64), [B(512, 0, zp, 768, 64, zp + 192), MS.EXIT_STOP])      # (and the way out stopped at its door)
        if closed[0] is None or reaches(closed, self.w(self.W / 2, self.D / 2, self.lid - 100)):
            self.problems.append("the bunker's rooms are open to the hill somewhere other than the doorway")
        sx, sy, sz = self.silo_at
        for u, w, z, what in ((704, 736, zl + 64, "hall"), (1088, 704, zl + 64, "bunk room"), (-320, 704, zd + 64, "walkway west"), self.PLANT + (zd + 64, "plant room"),
                              (128, 864, zd + 64, "walkway to the complex"), (1408, 1184, zd + 64, "walkway's end at the control room"),
                              (-640, 1000, zd + 64, "corridor to the silo"), (-640, 1568, zg + 64, "corridor's end at the silo")):
            if not reaches(closed, W(u, w, z)):
                self.problems.append("the bunker's %s can't be reached from its door" % what)
        for x, y, z, what in complex_places:
            if not reaches(closed, (x, y, z)):
                self.problems.append("the complex's %s can't be reached from the bunker's door" % what)
        for dz, what in ((1408 + 64, "gantry level"),):
            if not reaches(closed, (sx, sy, sz + dz)):
                self.problems.append("the silo's %s can't be reached from the bunker's door" % what)
        for (px, py, pz), what in (((sx + 150, sy + 704, sz + 1472), "leader's office"), ((sx - 340, sy + 704, sz + 1472), "leader's bedroom"),
                                   (((MS.WAY_X[0] + MS.WAY_X[1]) / 2.0, 5000, MS.WAY_HIGH + 64), "leader's way out (at its door)")):
            if not reaches(closed, (px, py, pz)):
                self.problems.append("the silo's %s can't be reached from the bunker's door" % what)
        # the door's failsafe counts everyone inside: every bit of air the door leads to (but the leader's way out, a way
        # OUT, beyond the silo's hull) must lie in one of the trigger's boxes
        seen, full, axes, leak = closed
        missed = 0
        if seen:
            cx = [0, 0, 0, -1, -1, -1]      # (the leader's way out, a way out beyond the hull, was left out of the count; it is gone)
            for c in seen:
                lo = [axes[a][c[a]] for a in range(3)]
                hi = [axes[a][c[a] + 1] for a in range(3)]
                p = [(lo[a] + hi[a]) / 2.0 for a in range(3)]
                if min(hi[a] - lo[a] for a in range(3)) < 2 or (cx[0] <= p[0] <= cx[3] and cx[1] <= p[1] <= cx[4] and cx[2] <= p[2] <= cx[5]):
                    continue
                if not any(b[0] <= p[0] <= b[3] and b[1] <= p[1] <= b[4] and b[2] <= p[2] <= b[5] for b in self.inside_boxes):
                    missed += (hi[0] - lo[0]) * (hi[1] - lo[1]) * (hi[2] - lo[2])
                    where = p
        if missed:
            self.problems.append("the bunker door's failsafe misses %d cubic units of air reached from inside, e.g. at (%d %d %d): someone there would count as gone" % (
                (missed,) + tuple(where)))
        # every room, stair and corridor has a light of its own (the owner, 22 November: "several rooms in the bunker
        # without any lights")
        lit = [p for c, p in v.points if c in ("light", "light_spot")]
        rooms = [("room inside the door", (448, 64, 832, 256), zp), ("first stairs", (576, 256, 704, 512), zl), ("hall", (512, 640, 896, 832), zl),
                 ("bunk room", (960, 576, 1216, 832), zl), ("second stairs", (jx, 640, 512, 768), zd), ("walkway west", (-704, 640, 192, 768), zd),
                 ("plant room", (-1088, 512, -768, 832), zd), ("corridor to the silo", (-704, 832, -576, 1088), zd),
                 ("silo stairs", (-704, 1088, -576, 1472), zg), ("corridor's end", (-768, 1472, -512, 1600), zg)]
        rooms += [("walkway to the complex (%s)" % n, r, zd) for n, r in (("north", (64, 768, 192, 960)), ("east", (64, 960, 1472, 1088)), ("its end", (1344, 1088, 1472, 1280)))]
        boxes = [(name, W(x1, y1, floor) + W(x2, y2, floor + 400)) for name, (x1, y1, x2, y2), floor in rooms]
        boxes += [(name, box) for name, box in ML.lit_rooms(self)]
        for name, box in boxes:
            if not any(box[0] < p[0] < box[3] and box[1] < p[1] < box[4] and box[2] < p[2] < box[5] for p in lit):
                self.problems.append("the bunker's %s has no light" % name)
        # the deep level and the corridor must stay under the ground
        # (the ground as it is laid, not as it would be: every corner of every square of the deep level in the forest, walls
        #  too, by the height of the patch it is in; the owner, 24 November, of the walkway to the complex: "a ground
        #  texture/displacement stretching over the hallway")
        cover = 1e9
        for (i, j) in deep.cells:
            x, y = bx + i * CELL, by + j * CELL
            if not (0 <= x and x + CELL <= self.W and 0 <= y and y + CELL <= self.D):
                continue
            bias = (x // PATCH * PATCH + PATCH / 2, y // PATCH * PATCH + PATCH / 2)
            cover = min(cover, min(self.height(x + dx, y + dy, bias) for dx in (0, CELL) for dy in (0, CELL)) - top)
        if cover < 16:
            self.problems.append("the bunker's deep level comes within %d of the ground's surface" % cover)
        # and nothing of the forest's shell stands in any of the bunker's rooms (its sky wall stood in the north half of the
        # walkway to the complex where it crosses the forest's edge: "no wall at all visible and it's all open to the void")
        for p in (plan, deep, low) + ((self.stair_plan,) if getattr(self, "stair_plan", None) else ()):
            for x1, y1, x2, y2, sp in p.rectangles():
                if sp[0] == "solid":
                    continue
                a = p.box(x1, y1, sp[1], x2, y2, sp[3] if sp[0] == "low" else p.top)
                for b in self.shell_walls:
                    if all(a[k] < b[k + 3] and b[k] < a[k + 3] for k in range(3)):
                        self.problems.append("the forest's shell wall at (%d %d)-(%d %d) stands in the bunker's room at (%d %d)-(%d %d)" % (
                            b[0], b[1], b[3], b[4], a[0], a[1], a[3], a[4]))
        self.notes.append("the bunker: its door at (%d %d), floor z %d; 15 steps down to the first level (z %d: a hall, the bunk room), 11 more down to the deep level "
                          "(z %d: a walkway west to the plant room and the corridor to the silo, a walkway north and east to the control complex), which is at least %d "
                          "under the ground; %d lamps, each lighting its own pool" % (self.ox + bx + 640, self.oy + by, zp, zl, zd, cover, self.lamps))
        self.notes.append("the silo: its shaft's axis at (%d %d), from z %d to %d, in a sealed hull just north of the forest's wall; reached from the walkway's north door "
                          "by a corridor (z %d) and 15 steps of 16 by 24 down to its gantry level (z %d)" % (sx, sy, sz - 64, sz + 1792, zd, zg))

    def dress(self):
        """Light and dressing in White Forest's way (ep2_outland_11, 11a, 11b and 12a, counted 21 November): a fluorescent
        fixture (props_lab/lab_flourescentlight001a, 33 under the ceiling as Valve hangs it) over each room, in Valve's
        colours: cold 224 254 248 and 193 249 255 in halls and corridors, warm 253 230 159 and 252 241 180 where people
        work, red in the plant room; tube lamps (props_silo/wall_light) and cable runs (prodcables256) on the corridors'
        walls, red caged lamps inside the outer door; and each room's kit as Valve's rooms have it: consoles on a desk,
        servers and a wall console in the radio room and the main room, lockers and footlockers in the armoury, wall
        beds and a sink in the sick bay, shelves and stores, the generator, air plant and switch panels in the plant
        room, bunks and lockers in the bunk room. Every room is lit, in pools (see the lamps below). All steady:
        none flickers or flashes (the owner: "get rid of the flickering lights in the bunker ... going to give me or
        someone a seizure"). Furniture whose model is a physics prop is a prop_dynamic_override (a prop_static of one is
        deleted by the compiler, as the bunker's first dressing was), standing solid where it is put."""
        v, W, bx, by = self.vmf, self.plan.world, self.B0[0], self.B0[1]
        zp, zl, zd, zg = self.zp, self.zl, self.zd, self.zg
        vis = self.vis("structures")
        cold, cold2, warm, warm2, red = "224 254 248", "193 249 255", "253 230 159", "252 241 180", "255 64 64"
        lv = self.vis("lights")

        def spot(u, w, z, colour, power, cone, inner, pitch, yaw=0, fifty=0, zero=0):
            v.point("light_spot", W(u, w, z), {"_light": "%s %d" % (colour, power), "_lightHDR": "-1 -1 -1 1", "_cone": str(cone), "_inner_cone": str(inner),
                                               "_exponent": "1", "_fifty_percent_distance": str(fifty), "_zero_percent_distance": str(zero), "_constant_attn": "0",
                                               "_linear_attn": "0", "_quadratic_attn": "1", "angles": "%d %d 0" % (pitch, yaw), "pitch": str(pitch), "style": "0",
                                               "spawnflags": "0"}, lv)

        def glow(u, w, z, colour, power, fill=False):
            keys = {"_light": "%s %d" % (colour, power), "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}
            if fill:        # (Valve's fill: soft and short, lifting a dark room without a lamp of its own)
                keys.update({"_constant_attn": "500", "_linear_attn": "500", "_quadratic_attn": "0"})
            v.point("light", W(u, w, z), keys, lv)
        # Every room, stair and corridor lit in pools as White Forest is (ep2_outland_11's own lamps, read 22 November; the
        # owner: "there are also several rooms in the bunker without any lights"): a tube on the ceiling throws a spot
        # straight down with a faint glow at it (lab_flourescentlight001a: 900, cone 60, inner 30, half at 64 and none at
        # 400 away; the quarters' prison_flourescentlight001a: 1000, cone 50), a tube lamp on a wall throws its spot out
        # into the passage (props_silo/wall_light: 400, cone 88, half at 128, none at 1024, with a glow of 60), the plant
        # room's red caged lamp a spot down into the room (light_cagelight01_on: 280, cone 45, 40 down). (u, w, its
        # ceiling, colour, model): the bunks, the armoury, the stores and the passage's far end were dark until then.
        self.lamps = 0
        # (u, w, its ceiling, colour, model): the room inside the door, the hall, the bunks, the walkways' tubes (cold, as White
        # Forest's corridors), the corridor's end at the silo
        lamps = ((640, 160, zp + 208, cold, "lab"), (704, 736, zl + 160, cold2, "lab"), (1088, 704, zl + 160, warm2, "prison"),
                 (-320, 704, zd + 160, cold, "lab"), (128, 864, zd + 160, cold2, "lab"), (512, 1024, zd + 160, cold, "lab"), (1024, 1024, zd + 160, cold2, "lab"),
                 (1408, 1184, zd + 160, cold, "lab"), (-640, 1488, zg + 192, cold, "lab"))
        for (u, w, ceil, colour, model) in lamps:
            at = ceil - 33
            if model == "lab":
                spot(u, w, at - 41, colour, 900, 60, 30, -90, fifty=64, zero=400)
                glow(u, w, at - 45, colour, 4)
            else:
                spot(u, w, at - 47, colour, 1000, 50, 30, -90)
                glow(u, w, at - 41, colour, 12)
            self.lamps += 1
        # (u, w, z, the way it faces: out from its wall, strong or faint)
        walls = ((-703, 1000, zd + 120, 0, 1), (-577, 1340, zd + 16, 180, 1), (352, 767, zl + 40, 270, 1), (577, 352, zp + 24, 0, 1))
        for (u, w, z, yaw, strong) in walls:
            du, dw = round(math.cos(math.radians(yaw)) * 8), round(math.sin(math.radians(yaw)) * 8)
            if strong:
                spot(u + du, w + dw, z, "240 254 255", 400, 88, 30, 0, yaw=yaw, fifty=128, zero=1024)
                glow(u + du, w + dw, z, "244 254 255", 60)
            else:
                spot(u + du, w + dw, z, "193 249 255", 80, 70, 30, 0, yaw=yaw)
                glow(u + du, w + dw, z, "193 249 255", 30)
            self.lamps += 1
        pu, pw = self.PLANT                    # the plant room's middle (since 24 November at the walkway's west end)
        spot(pu, pw + 146, zd + 127, "255 64 9", 280, 45, 30, -40, yaw=270)      # the plant room's red caged lamp, and a soft red fill
        glow(pu, pw + 148, zd + 129, "255 64 9", 20)
        glow(pu, pw, zd + 100, red, 70, fill=True)
        self.lamps += 1
        for (u, w, z) in ((640, 160, zp + 72), (704, 736, zl + 72), (1088, 704, zl + 72), (-320, 704, zd + 72), (768, 1024, zd + 72), (pu, pw, zd + 72), (-640, 1000, zd + 72)):
            v.point("env_cubemap", W(u, w, z), {"cubemapsize": "0"}, vis)

        def put(model, u, w, z, yaw, kind="s"):
            m = "models/%s.mdl" % model
            if kind == "s":
                self.static(m, bx + u, by + w, z, yaw, "structures", fade=(-1, 0))
                return
            keys = {"model": m, "angles": "0 %d 0" % yaw, "solid": "6", "skin": "0", "disableshadows": "1" if kind == "f" else "0", "fademindist": "-1", "fademaxdist": "0",
                    "fadescale": "1", "screenspacefade": "0"}
            if kind == "f":         # (a lamp: it must not shade the light hung in it)
                v.point("prop_static", W(u, w, z), dict(keys, solid="0"), vis)
                return
            keys.update({"StartDisabled": "0", "spawnflags": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10",
                         "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"})
            v.point("prop_dynamic_override", W(u, w, z), keys, vis)
        self.put = put          # (gallery() and cctv() dress with it too)
        for (u, w, ceil, colour, model) in lamps:
            put("props_lab/lab_flourescentlight001a" if model == "lab" else "props_wasteland/prison_flourescentlight001a", u, w, ceil - 33, 0, "f")
        for (u, w, z, yaw, strong) in walls:
            put("props_silo/wall_light", u, w, z, yaw, "f")
        for (u, w, z, yaw) in ((480, 65, zp + 150, 90), (800, 65, zp + 150, 90), (pu, pw + 159, zd + 140, 270)):
            put("props_c17/light_cagelight01_on", u, w, z, yaw, "f")
        for (u, w, z, yaw, model) in ((-577, 1024, zd + 146, 180, "prodcables256"), (352, 767, zl + 70, 270, "prodcables256"), (-320, 767, zd + 146, 270, "prodcables256"),
                                      (768, 1087, zd + 146, 270, "prodcables256")):
            put("props_silo/" + model, u, w, z, yaw)
        kit = (
            # the room inside the door
            ("props_silo/wall_wires2", 831, 160, zp, 180, "s"), ("props_silo/acunit02", 458, 200, zp + 120, 0, "s"),
            # the hall: a crate in the nook beside the stairs' top, a cart by the bunk room's door
            ("props_junk/wood_crate001a", 542, 798, zl + 20, 10, "d"), ("props_lab/reciever_cart", 860, 800, zl + 36, 270, "d"),
            # the bunk room: the east room, a dead end (the owner: "why did you put the bunkroom as a 'walkway' room before the
            # stairs down?"). Each frame (bunkbed) has its mattresses (bunkbed2: Valve's mattress set for it, the same origin
            # and turn; the owner: they were "floating on the other side of the room away from the bunk bed frames")
            ("props_forest/bunkbed", 1150, 805, zl, 270, "s"), ("props_forest/bunkbed2", 1150, 805, zl, 270, "s"),
            ("props_forest/bunkbed", 1030, 805, zl, 270, "s"), ("props_forest/bunkbed2", 1030, 805, zl, 270, "s"),
            ("props_lab/lockers", 1030, 589, zl, 90, "s"), ("props_forest/footlocker01_closed", 1150, 755, zl + 12, 270, "s"), ("props_wasteland/prison_sink001a", 1202, 610, zl + 28, 180, "s"),
            # the plant room (Valve's generator, air plant and switch panels: as it was, the room moved with them)
            ("props_outland/generator_static01a", pu - 60, pw + 99, zd, 270, "s"), ("props_silo/acunit01", pu - 126, pw - 16, zd + 64, 0, "s"),
            ("props_silo/electricalbox01", pu + 10, pw - 154, zd, 90, "s"), ("props_silo/tirestack2", pu + 100, pw + 129, zd, 0, "s"),
            ("props_lab/powerbox01a", pu + 145, pw - 116, zd + 60, 180, "s"),
        )
        for model, u, w, z, yaw, kind in kit:
            put(model, u, w, z, yaw, kind)

    # What each part of the bunker sounds like (the owner, 22 November: "can we please add some soundscapes in the
    # bunker?"): Half-Life 2's own soundscapes only (Garry's Mod loads Half-Life 2's scripts; Episode Two's may not be
    # there), Black Mesa East's underground corridor for the stairs and corridors (its d1_eli_01 uses it), Nova Prospekt's
    # radio-hum control room for the main room and the radio room, the canals' pump room for the generator and the plant
    # room, quiet concrete rooms for the bunks, the armoury, the stores and the sick bay, a draughty concrete room by the
    # outer door, and outside the door the quiet of a dry canal (birds and wind snippets), so the bunker's sound stops at
    # its door. (u, w, z, the soundscape, its radius): each radius ends short of every other one of a different sound
    # (and of the silo's own), so no two fight; the nearest in sight plays.
    SCAPES = (
        (640, 160, "zp", "coast.bridge_concrete_room", 192),          # the room inside the door
        (704, 736, "zl", "eli_01_lower_corridor_1", 140),             # the hall
        (1088, 704, "zl", "general.concrete_quiet", 160),             # the bunks
        (352, 704, "zd+150", "eli_01_lower_corridor_1", 120),         # the second stairs
        (-320, 704, "zd", "eli_01_lower_corridor_1", 140),            # the walkway west
        (-928, 672, "zd", "d1_canals.floodgate_machineroom", 180),    # the plant room
        (128, 864, "zd", "eli_01_lower_corridor_1", 120),             # the walkway to the complex
        (640, 1024, "zd", "eli_01_lower_corridor_1", 160),
        (1408, 1152, "zd", "eli_01_lower_corridor_1", 110),
        (-640, 960, "zd", "eli_01_lower_corridor_1", 120),            # the corridor to the silo
        (-640, 1344, "zd-128", "eli_01_lower_corridor_1", 120),       # its stairs
        # (its end at the silo's tunnel is left to the silo's own sound: map_silo.py, Silo soundscapes; the control complex's
        #  are map_launch.py's)
        (640, -256, "zp", "canals_canal_nowater", 160),               # outside the door: the forest again
    )

    def roof_fence(self):
        """The bunker's roof (the owner, 22 November: "please add fencing around the bunker roof perimeter, it just looks too
        bare and remove the watchtower please. No one should walk on top of the bunker"): Episode Two's barbed fence as
        White Forest's base has it at its gate (props_wasteland/exterior_fence002b to _e, 152 high, too high to jump),
        standing all round the roof's edge, its outer side on the edge; and an unseen player clip over the whole roof from
        its top to the sky, so nobody stands on it from the mound behind or from anywhere else. The roof is every brush of
        the bunker's whose top is the roof's (zp + 272), read off the 64 grid, and its edge is where that runs out. The
        timber lookout that stood on it (22 November) is gone."""
        v, rz = self.vmf, self.zp + 272
        vis = self.vis("bunker roof: its fence and clip")
        roof = [b for b, _ in v.boxes if b[5] == rz and b[2] < rz]
        cells = set()
        for x1, y1, _, x2, y2, _ in roof:
            for x in range(int(x1) // 64 * 64, int(x2), 64):
                for y in range(int(y1) // 64 * 64, int(y2), 64):
                    if x1 <= x and x + 64 <= x2 and y1 <= y and y + 64 <= y2:
                        cells.add((x, y))
        clip = "tools/toolsplayerclip"
        for x1, y1, _, x2, y2, _ in roof:
            v.world_box((x1, y1, rz, x2, y2, self.lid), clip, top=clip, bottom=clip, vis=vis, seals=False)
        # the edge, as runs along x and along y; each side of a cell with no roof beyond it is a piece of edge
        edges = {}
        for (x, y) in cells:
            for (dx, dy, key) in ((0, -1, ("s", y)), (0, 1, ("n", y + 64)), (-1, 0, ("w", x)), (1, 0, ("e", x + 64))):
                if (x + 64 * dx, y + 64 * dy) not in cells:
                    edges.setdefault(key, []).append(x if dx == 0 else y)
        pieces = ((512, "e"), (256, "d"), (128, "c"), (64, "b"))
        n = 0
        for (side, at), starts in sorted(edges.items()):
            starts.sort()
            runs, a0 = [], starts[0]
            for k in range(1, len(starts) + 1):
                if k == len(starts) or starts[k] != starts[k - 1] + 64:
                    runs.append((a0, starts[k - 1] + 64))
                    if k < len(starts):
                        a0 = starts[k]
            inward = {"s": 13, "n": -13, "w": 13, "e": -13}[side]
            for r1, r2 in runs:
                pos = r1
                while pos < r2:
                    length, tag = next((L, t) for L, t in pieces if L <= r2 - pos) if r2 - pos >= 64 else (64, "b")
                    mid = pos + length / 2.0
                    if side in "sn":
                        at_xy, yaw = (mid, at + inward), 90
                    else:
                        at_xy, yaw = (at + inward, mid), 0
                    v.point("prop_static", (int(round(at_xy[0])), int(round(at_xy[1])), rz + 76), {
                        "model": "models/props_wasteland/exterior_fence002%s.mdl" % tag, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6",
                        "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)
                    n += 1
                    pos += length
        self.notes.append("the bunker's roof: %d lengths of barbed fence round its edge, a player clip over all of it (nobody stands on it); no lookout" % n)

    def soundscapes(self):
        v, W = self.vmf, self.plan.world
        levels = {"zp": self.zp, "zl": self.zl, "zd": self.zd, "zg": self.zg, "zd+150": self.zd + 150, "zd-128": self.zd - 128}
        placed = []
        for u, w, lvl, name, radius in self.SCAPES:
            at = W(u, w, levels[lvl] + 64)
            v.point("env_soundscape", at, {"soundscape": name, "radius": str(radius), "StartDisabled": "0"}, self.vis("soundscapes"))
            placed.append((at, radius, name))
        others = []      # (the silo's own, from Valve's piece)
        for text in v.ents:
            if '"classname" "env_soundscape"' in text:
                o, r, n = re.search(r'"origin" "([^"]+)"', text), re.search(r'"radius" "([^"]+)"', text), re.search(r'"soundscape" "([^"]+)"', text)
                if o and r and n and not any(n.group(1) == p[2] and tuple(int(float(c)) for c in o.group(1).split()) == p[0] for p in placed):
                    others.append((tuple(float(c) for c in o.group(1).split()), float(r.group(1)), n.group(1)))
        for k, (a, ra, na) in enumerate(placed):
            for b, rb, nb in placed[k + 1:] + others:
                if na != nb and math.dist(a, b) < ra + rb:
                    self.problems.append("the soundscapes %s at (%d %d %d) and %s at (%d %d %d) overlap: they would fight" % ((na,) + tuple(a) + (nb,) + tuple(b)))
        self.notes.append("the bunker's sound: %d soundscapes of Half-Life 2's (%s), none overlapping another of a different sound" % (
            len(placed), ", ".join(sorted(set(n for _, _, n in placed)))))

    # the doors between rooms: (which level, the doorway's squares, the way through it, the side its keypad is NOT on (+1:
    # east or north; the keypad goes on a face with wall beside the doorway), which way the leaf slides into the wall (-1:
    # south or west)): the bunk room's (its keypad on the bunks' side: the hall is no wider than the doorway there), the
    # plant room's at the far end of the walkway west (its keypad inside the plant room, as it was), and the walkway's north
    # door, to the silo. Each on its doorway square in DEEP (the owner, 24 November: "the red plant room's door has been
    # moved over and left a gaping hole in the wall": the two deep doors still stood where the big room's plan had them).
    ROOM_DOORS = ((0, (896, 640, 960, 768), "x", -1, -1), (1, (-768, 640, -704, 768), "x", 1, -1), (1, (-704, 768, -576, 832), "y", 1, -1))

    # Episode Two's own small silo door, the lab door at the silo's bottom (door_silo_lab_outside_1, the owner: "has
    # CORRECT opening/closing animations and opens at the right speed"): every silo_door01 door copies it. Its func_door:
    # speed 60, lip 32, Valve's lever-door sounds; its prop has NO default animation, so it holds the last frame of
    # "unlock" while open and of "lock" while shut (with DefaultAnim "idle" it snapped back to locked when "unlock" ended).
    SILO_DOOR = {"speed": "60", "lip": "32", "noise1": "ep2_outland_11.leverdoor_open", "startclosesound": "ep2_outland_11.leverdoor_close"}

    def room_doors(self):
        """A door in each doorway between the bunker's rooms, as White Forest's are (the owner, 21 November: "the bunker/silo
        doors for whiteforest from EP2"): Episode Two's silo door (props_silo/silo_door01) carried by an unseen func_door 96
        wide and 124 high, 4 thick in the middle of the doorway, that slides 64 sideways into the wall, set as Valve's lab
        door at the silo's bottom (SILO_DOOR: speed 60, lip 32, its sounds, a prop with no default animation). Use opens
        and shuts it; it starts shut; the wheel unlocks as it opens and stays unlocked, and locks when it is shut again.
        To the gamemode these ARE doors (its door rules apply to func_door). A keypad beside each, 52 up as Valve's: a
        model only (the door opens by Use, and a keypad that opened it would get round the gamemode's locks). Beside most,
        on the side the leaf comes to rest on, Valve's shuttered window (window_spots, shutter_window); where one is, the
        keypad goes on the other side, the side the leaf slides into, as on Valve's lab door. The unseen leaf casts baked
        shadows (vrad_brush_cast_shadows), so a shut door keeps each room's light in (the owner, 22 November: "light bleeding
        through the door: the doorframe is red even with the door shut"); the model is lit from its doorway (lit_from)."""
        v, vis = self.vmf, self.vis("bunker room doors")
        pieces, shapes = [], []
        for k, (level, (u1, v1, u2, v2), way, room, slide) in enumerate(self.ROOM_DOORS):
            plan = (self.plan, self.deep)[level]
            z = (self.zl, self.zd)[level]
            B, W = plan.box, plan.world
            window = self.windows.get(k)
            near = ("south", "north") if way == "x" else ("west", "east")
            self.surround(plan, way, (u1, v1, u2, v2), z, pieces, shapes, window=window and near[window[1] > 0])
            if window:
                self.shutter_window(plan, way, window[0], window[1], room > 0, z, pieces, shapes, vis)
            ks = slide if window else -slide      # (the keypad's side along the wall: +1 north or east)
            if way == "x":      # the way through runs east-west: the leaf stands across it, north to south, and slides along y
                a, b, m = v1 + 16, v2 - 16, (u1 + u2) // 2
                leaf, at, yaw, movedir = B(m - 2, a, z - 4, m + 2, b, z + 120), W(m, (a + b) // 2, z), 90, 90 if slide > 0 else 270
                pad = (W(u1 - 1, v2 + 12 if ks > 0 else v1 - 12, z + 52), 180) if room > 0 else (W(u2 + 1, v2 + 12 if ks > 0 else v1 - 12, z + 52), 0)
            else:               # the way through runs north-south: the leaf stands across it, east to west, and slides along x
                a, b, m = u1 + 16, u2 - 16, (v1 + v2) // 2
                leaf, at, yaw, movedir = B(a, m - 2, z - 4, b, m + 2, z + 120), W((a + b) // 2, m, z), 0, 0 if slide > 0 else 180
                pad = (W(u2 + 12 if ks > 0 else u1 - 12, v1 - 1, z + 52), 270) if room > 0 else (W(u2 + 12 if ks > 0 else u1 - 12, v2 + 1, z + 52), 90)
            # (the model's lever and handle are on its own +x side: it faces away from the way it slides, so they trail and stay
            # in the doorway, as on Valve's lab door. The owner, 22 November, of the deep level's door before the stairs to the
            # silo, the one that slid toward its own +x: "opens the wrong direction".)
            yaw = (movedir + 180) % 360
            name = "lc_bunker_room_door_%d" % (k + 1)
            v.brush_entity("func_door", dict(self.SILO_DOOR, **{
                "targetname": name, "movedir": "0 %d 0" % movedir, "wait": "-1", "spawnflags": "288", "forceclosed": "0", "ignoredebris": "1", "loopmovesound": "0",
                "dmg": "0", "health": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
                "renderfx": "0", "disableshadows": "1", "disablereceiveshadows": "0", "vrad_brush_cast_shadows": "1"}), [leaf], MAT["nodraw"], vis,
                connections=[("OnOpen", name + "_model", "SetAnimation", "unlock", 0), ("OnFullyClosed", name + "_model", "SetAnimation", "lock", 0)])
            v.point("prop_dynamic_override", at, {
                "targetname": name + "_model", "model": "models/props_silo/silo_door01.mdl", "angles": "0 %d 0" % yaw, "parentname": name, "skin": "0", "solid": "0",
                "lightingorigin": MS.lit_from(v, name + "_lighting", (at[0], at[1], z + 12), vis), "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
                "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}, vis)
            v.point("prop_dynamic", pad[0], {"model": "models/props_lab/keypad.mdl", "angles": "0 %d 0" % pad[1], "solid": "0", "skin": "0", "disableshadows": "1",
                                             "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0"}, vis)
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % v.new_id()
        for box, faces, axes in pieces:
            s += v.box_text(box, MAT["nodraw"], MAT["nodraw"], MAT["nodraw"], vis, faces=faces, axes=axes)
            v.boxes.append((box, False))
        v.ents.append(s + v.editor(vis, "0 180 0") + "}\n")
        v.detail_shapes(shapes, vis)
        self.notes.append("the bunker's rooms: %d of Episode Two's silo doors, sliding as White Forest's (Use slides each 64 into the wall; they start shut), "
                          "%d with Valve's shuttered window beside (none beside door %s: no room on both sides of the wall)" % (
                              len(self.ROOM_DOORS), len(self.windows), ", ".join(str(n) for n, _ in self.window_skips)))

    # Episode Two's shuttered window beside the lab door at the silo's bottom (ep2_outland_11, read from valve_ep2_silo on
    # 22 November; the owner: "next to the resistance leader's office's door, there is a little glass window with shutters;
    # can we get those next to most of the doors (on the side of the door to which the door closes ...)"): an opening 31
    # wide and 86 high through the wall, 18 over the floor; in it a frame of metalhull003a 2 thick (its sides 6 deep, with
    # metaltruss008a on their backs), the glass 27 by 82 (glasswindow007a, a func_breakable nothing breaks: Valve's keys),
    # and on one side 14 slats of metaldoor046a 1 thick and 7 deep, tilted up toward the glass, every 6 from 23 over the
    # floor. Depths from the slatted face of the wall, heights from the floor, all as Valve's. (Valve's opening is 9 from
    # the door's; here 12, the frame's concrete beside the doorway.)
    WINDOW_GLASS = {"health": "999999", "minhealthdmg": "999", "material": "0", "propdata": "24", "spawnflags": "1", "explodemagnitude": "0", "explosion": "0",
                    "ExplodeDamage": "0", "ExplodeRadius": "0", "gibdir": "0 0 0", "nodamageforces": "0", "PerformanceMode": "0", "physdamagescale": "1.0",
                    "pressuredelay": "0", "spawnobject": "0", "disableshadows": "0", "disablereceiveshadows": "0", "renderamt": "255",
                    "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0"}

    def window_spots(self):
        """Which of the bunker's room doors get a shuttered window (shutter_window): in the wall square beside the doorway
        on the side its leaf comes to rest on when shut (away from the side it slides into), where that square is wall with
        a room on both its sides at the door's floor (a window between two rooms of the bunker, never out of it, so it
        crosses no areaportal). Its gap is left in the wall (WFPlan.windows). self.windows: {door's index: (the square, the
        way along the wall away from the doorway, +1 north or east; its floor)}; self.window_skips: [(door's number, why not)]."""
        self.windows, self.window_skips = {}, []
        for k, (level, (u1, v1, u2, v2), way, room, slide) in enumerate(self.ROOM_DOORS):
            plan, z, r = (self.plan, self.deep)[level], (self.zl, self.zd)[level], -slide
            if way == "x":
                cell = (u1, v2, u2, v2 + CELL) if r > 0 else (u1, v1 - CELL, u2, v1)
                beside = ((cell[0] - CELL, cell[1]), (cell[2], cell[1]))
            else:
                cell = (u2, v1, u2 + CELL, v2) if r > 0 else (u1 - CELL, v1, u1, v2)
                beside = ((cell[0], cell[1] - CELL), (cell[0], cell[3]))
            sq = (cell[0] // CELL, cell[1] // CELL)
            if plan.cells.get(sq) != ("solid",) or any(plan.looks_at((x // CELL, y // CELL)) != ("room", z) for x, y in beside):
                self.window_skips.append((k + 1, "the wall on its closing side has a room on one side only"))
                continue
            if any(lv == level and d[0] <= x < d[2] and d[1] <= y < d[3] for x, y in beside for lv, d, _, _, _ in self.ROOM_DOORS):
                self.window_skips.append((k + 1, "the wall on its closing side looks into another doorway"))
                continue
            plan.windows[sq] = (z, z + WF_BAND)
            self.windows[k] = (cell, r, z)

    def shutter_window(self, plan, way, cell, r, front, z, pieces, shapes, vis):
        """Valve's shuttered window (WINDOW_GLASS) in the wall square `cell` beside a doorway (window_spots): r the way along
        the wall away from the doorway, `front` True when the slats are on the square's west or south face (the keypad's,
        as Valve's are on the hall's side, its keypad's). The wall round the opening as world (its faces as the walls',
        WF_BAND; the opening's sides, sill and head in plain 05a), the frame (pieces) and slats (shapes) as func_detail,
        the glass its own func_breakable."""
        v = self.vmf
        x1, y1, x2, y2 = cell
        if way == "x":      # the wall runs north-south: its depth is along x
            d1, d2, c1, c2, dn, along, wv = x1, x2, y1, y2, ("west", "east"), ("south", "north"), "0 1 0"

            def P(d, w, h):
                return plan.world(d, w, h)
        else:
            d1, d2, c1, c2, dn, along, wv = y1, y2, x1, x2, ("south", "north"), ("west", "east"), "1 0 0"

            def P(d, w, h):
                return plan.world(w, d, h)
        e = c1 if r > 0 else c2                 # the square's edge at the doorway
        f, s = (d1, 1) if front else (d2, -1)   # the slatted face, and the way into the wall from it
        door_side, far_side = (along[0], along[1]) if r > 0 else (along[1], along[0])
        back = dn[1] if s > 0 else dn[0]        # the frame's face away from the slats

        def box(ta, tb, da, db, ha, hb):
            """ta to tb along the wall from the doorway, da to db deep from the slatted face, ha to hb over the floor."""
            a, b = P(f + s * da, e + r * ta, z + ha), P(f + s * db, e + r * tb, z + hb)
            return tuple(min(a[q], b[q]) for q in range(3)) + tuple(max(a[q], b[q]) for q in range(3))
        deep = d2 - d1
        # the wall round the opening: under it, over it, and the rest of the square beyond it
        for ta, tb, ha, hb, top, bottom, side in ((0, 31, 0, 18, FMAT["wf_upper"], None, None), (0, 31, 104, WF_BAND, None, FMAT["wf_upper"], None),
                                                  (31, CELL, 0, WF_BAND, None, None, door_side)):
            faces = {n: wf_face(n, z, z + ha, z + hb) for n in dn}
            if side:
                faces[side] = wf_face(side, z - 1024, z, z + WF_BAND)
            wf_box(v, box(ta, tb, 0, deep, ha, hb), faces, vis, top=top, bottom=bottom)
        # the frame: sill, sides, head
        hull_ax = ("[%s 0] 0.0938" % wv, "[0 0 -1 0] 0.3359")
        for ta, tb, da, db, ha, hb, outer in ((0, 31, 10, 12, 18, 20, None), (0, 2, 6, 12, 20, 104, door_side), (29, 31, 6, 12, 20, 104, far_side),
                                              (2, 29, 10, 12, 102, 104, None)):
            faces = {n: self.HULL for n in FACE_ORDER}
            axes = {n: hull_ax for n in dn}
            if outer:
                for n in (outer, back):
                    faces[n] = self.FRAME_BACK
                    axes.pop(n, None)
            pieces.append((box(ta, tb, da, db, ha, hb), faces, axes))
        # the glass
        glass_ax = ("[%s 0] 0.15" % wv, "[0 0 -1 0] 0.15")
        v.brush_entity("func_breakable", dict(self.WINDOW_GLASS), [(box(2, 29, 10, 12, 20, 102), {}, {n: glass_ax for n in dn})], self.GLASS, vis)
        # (Valve's 14 slats on the hall's side are left out: the owner, 23 November, "just get rid of the slats on every
        #  window and leave the window itself", to save brush sides)

    # White Forest's surround for its silo doors, copied from ep2_outland_11 (prop_door_silo_1 and the lab door, read 22
    # November; the owner: the old frames were an "awful texture choice and it's repeating and looks like a game from
    # 1998"): the wall's opening 104 wide and 124 high, lined with metal 4 thick (so 96 by 120 clear), in three lengths
    # through the wall (the door's own track, 10 deep, in the middle), with a sill sunk flush in the floor and a small
    # gusset in each top corner. The faces into the opening are metaltruss029a at 0.16 (metaltruss017a on the track),
    # the 4 wide faces out to the rooms metalpipe003a at 0.25 laid along each strip, the sill's top metalhull003a.
    TRUSS, TRACK, PIPE, HULL = "metal/metaltruss029a", "metal/metaltruss017a", "metal/metalpipe003a", "metal/metalhull003a"
    FRAME_BACK, GLASS, SLAT = "metal/metaltruss008a", "glass/glasswindow007a", "metal/metaldoor046a"     # (the shuttered window's: shutter_window)

    def surround(self, plan, way, rect, z, pieces, shapes, window=None):
        """The surround of one doorway (its squares `rect`, the way through it "x" or "y", its floor z): the wall filled in to
        Valve's opening (concrete, its faces laid as the walls beside it) and Valve's metal lining, as (box, faces, axes)
        in pieces and the corner gussets in shapes. window: the side ("north" ...) a shuttered window is on, whose opening's
        side is the fill's face there (shutter_window)."""
        u1, v1, u2, v2 = rect
        if way == "x":      # through along x: the depth is x, the width y
            d1, d2, w1, w2 = u1, u2, v1, v2
            front, back, lo, hi = "west", "east", "south", "north"

            def P(d, w, h):
                return plan.world(d, w, h)
        else:
            d1, d2, w1, w2 = v1, v2, u1, u2
            front, back, lo, hi = "south", "north", "west", "east"

            def P(d, w, h):
                return plan.world(w, d, h)

        def box(da, db, wa, wb, za, zb):
            a, b = P(da, wa, za), P(db, wb, zb)
            return tuple(min(a[k], b[k]) for k in range(3)) + tuple(max(a[k], b[k]) for k in range(3))

        def axis(kind, shift, scale):
            """A texture axis along the doorway's depth ("d"), width ("w") or up ("z", pointing down)."""
            vec = {"z": "0 0 -1", "d": "1 0 0" if way == "x" else "0 1 0", "w": "0 1 0" if way == "x" else "1 0 0"}[kind]
            return "[%s %g] %g" % (vec, round(shift % 1024, 3), scale)

        od, ow = (plan.origin[0], plan.origin[1]) if way == "x" else (plan.origin[1], plan.origin[0])      # (textures go by the map's own axes)
        m = (d1 + d2) // 2
        i0, j0 = (u1 // CELL, v1 // CELL)
        if way == "x":
            f_front, f_back = plan.looks_at((u1 // CELL - 1, j0)), plan.looks_at((u2 // CELL, j0))
        else:
            f_front, f_back = plan.looks_at((i0, v1 // CELL - 1)), plan.looks_at((i0, v2 // CELL))
        f_front = f_front[1] if f_front and f_front[0] == "room" else z
        f_back = f_back[1] if f_back and f_back[0] == "room" else z
        # the wall filled in to Valve's opening, 12 each side and 4 over it
        for wa, wb, za in ((w1, w1 + 12, z - 4), (w2 - 12, w2, z - 4), (w1 + 12, w2 - 12, z + 124)):
            faces, axes = {}, {}
            for name, f in ((front, f_front), (back, f_back)):
                got = wf_face(name, f, max(za, f), z + 128)
                faces[name], axes[name] = got
            side = lo if wa == w1 else hi if wb == w2 else None
            if side and side == window:
                faces[side], axes[side] = wf_face(side, z - 1024, z, z + 128)
            pieces.append((box(d1, d2, wa, wb, za, z + 128), faces, axes))
        # Valve's lining: jambs, head and sill, each one length through the wall, and a gusset in each top corner along it
        # (Valve's is in three lengths, the door's own track in the middle: the owner, 23 November, one length a side, to
        # save brush sides: 62 a doorway instead of 110)
        a, b = w1 + 12, w2 - 12           # the opening in the wall, 104
        truss_up = (axis("d", -(d1 + od) / 0.16, 0.16), axis("z", z / 0.16, 0.16))

        def ends(faces, axes, ax):
            for name in (front, back):
                faces[name], axes[name] = self.PIPE, ax
        for wa, wb, face in ((a, a + 4, hi), (b - 4, b, lo)):      # the jambs, floor to head
            faces, axes = {face: self.TRUSS}, {face: truss_up}
            ends(faces, axes, (axis("w", 166 - 4 * (wa + ow), 0.25), axis("z", 4 * z, 0.25)))
            pieces.append((box(d1, d2, wa, wb, z - 4, z + 124), faces, axes))
        faces, axes = {"bottom": self.TRUSS}, {"bottom": (axis("d", -(d1 + od) / 0.16, 0.16), axis("w", -(a + 4 + ow) / 0.16, 0.16))}
        ends(faces, axes, (axis("z", 166 + 4 * (z + 124), 0.25), axis("w", 0, 0.25)))
        pieces.append((box(d1, d2, a + 4, b - 4, z + 120, z + 124), faces, axes))      # the head
        faces, axes = {"top": self.HULL}, {}
        ends(faces, axes, (axis("z", 166 + 4 * z, 0.25), axis("w", 0, 0.25)))
        pieces.append((box(d1, d2, a + 4, b - 4, z - 4, z), faces, axes))           # the sill, its top flush with the floor
        for wc, sgn in ((a + 4, 1), (b - 4, -1)):          # a gusset 4 by 4 in each top corner
            tri = [(wc, z + 120), (wc + 4 * sgn, z + 120), (wc, z + 116)]
            tips = [[P(d, w, h) for w, h in tri] for d in (d1, d2)]
            sh = [(tips[0], self.PIPE), (tips[1][::-1], self.PIPE)]
            for q in range(3):
                r = (q + 1) % 3
                quad = [tips[0][q], tips[0][r], tips[1][r], tips[1][q]]
                sh.append((quad, self.TRUSS if q == 1 else MAT["nodraw"]))      # (the slope, from the head's corner to the jamb's, faces the opening)
            shapes.append(sh)

    DOOR_SPEED = 6      # the silo's blast door's leaves, degrees a second: Valve's own (60 degrees in 10 s)
    BLAST_AT = 596      # the silo's blast door's plane, this far from the silo's axis toward the bunker: 32 further out than Valve's (564), so that
                        # its hinge posts stand clear of the lift's car standing in the walkway at its top stop
    BLAST_PAD = (112, 556)   # the silo door's inside keypad: on the tunnel's east wall (112 east of the axis), 556 from the axis, beside the doorway
    FLAT_SPEED = 16     # the bunker door's two flat leaves, units a second: each slides 128, so 8 s
    FLAT_SCALE = 0.654  # Silo 2's leaves drawn at this size: 136 along the wall each, 216 high, 19 thick
    FLAT_PROUD = 8      # open, each leaf's edge stands this far out from the jamb (the owner, 22 November: flush, "they are flickering with the walls")
    FLAT_IN = 16        # the doorway's wall brought in this far each side, so each shut leaf overlaps it 24 (the owner: "leaks between their outer edge and the walls")
    FLAT_HALF_T = 10    # a leaf's drawn side to its blank back, at FLAT_SCALE (Valve's 14 and 15.1 either side of its middle): each leaf a pair, back to back

    def shove(self, name, parts, vis):
        """The shove at a door's close, where nothing kills (shove(), at the top of this file)."""
        shove(self.vmf, name, parts, vis)

    def door(self):
        """The bunker's door from the forest: flat doors that close, copied from the ones over the top of Silo 2 in Episode
        Two (the owner, 22 November: "the entrance to the bunker needs it's own flat doors that close (same as the ones at
        the top of the silo 2 in EP2)"): the piece valve_ep2_silo2_doors, Valve's two leaves (missile_doors.mdl) that lie
        flat over that silo and slide together, stood upright here as a sliding pair in the 256 by 192 doorway, drawn at
        FLAT_SCALE (each 136 along the wall: 8 into the jamb, meeting the other in the middle; 216 high, its top in the
        lintel), each carried by an unseen func_button (a mover only the wiring moves: PressIn slides it 120 into the front
        wall, its edge stopping FLAT_PROUD out from the jamb, PressOut back), lit from a point inside the doorway (lit_from),
        with Valve's sounds (launchdoors_close_start, its loop and its end) and a mild shake as they meet. They stand open. A button
        inside shuts them (a klaxon, a steady red light, the slide) and opens them again; nothing outside does (the owner,
        19 November: "only be opened from the inside"). Nothing kills: in the last moments of the close a shove (shove())
        pushes whoever is in the doorway out of it, in or out. If the bunker is left shut with nobody inside, it opens itself
        after twenty seconds. White Forest's round blast door that stood here first is the silo's door now (silo_door())."""
        v, plan, zp = self.vmf, self.plan, self.zp
        B, W = plan.box, plan.world
        dv = self.vis("bunker door (the leaves, the button, the wiring)")
        d1, d2 = self.DOOR                               # (the doorway's squares, 256)
        u1, u2 = d1 + self.FLAT_IN, d2 - self.FLAT_IN    # (the opening, 224: the wall brought in 16 each side)
        mid, top = (u1 + u2) // 2, zp + 192
        pf = PF.load("valve_ep2_silo2_doors")
        sc = self.FLAT_SCALE
        half = int(round(104 * sc))                      # (68: half a leaf along the wall)
        lip = 2 * half - (mid - u1 - self.FLAT_PROUD)    # (each leaf slides 104: its edge stops FLAT_PROUD out from the jamb's face, never flush)
        travel = float(2 * half - lip) / self.FLAT_SPEED
        # the doorway's wall brought in 16 each side (the owner, 22 November: "the bunker doors have leaks between their outer
        # edge and the walls ... so please just shorten the width of the opening a bit"): each leaf, 136 along the wall with
        # its outer edge where it was (8 past the doorway's squares), now overlaps the wall 24 when shut; the jambs world, laid
        # as the walls round them (the forest's side plain, the room's side banded from its floor, the reveal banded too)
        # Each jamb in three bands across the wall: the forest's side, the slot the leaves slide into, the room's side. The
        # slot's face black from floor to lintel (the owner, 23 November: "where they go into the wall ... a black brush so it
        # looks like they go into a dark space in the wall rather than just slipping into and through concrete"); world, so
        # the doorway's areaportal still meets world at its sides.
        s1, s2 = 32 - self.FLAT_HALF_T - 1, 32 + self.FLAT_HALF_T + 1        # (the slot: 11 to 53 across the 64 of wall)
        for a, b, reveal in ((d1, u1, "east"), (u2, d2, "west")):
            for z1, z2 in ((zp, zp + WF_BAND), (zp + WF_BAND, top)):
                wf_box(v, B(a, 0, z1, b, s1, z2), {"south": wf_face("south", zp - 1024, z1, z2), reveal: wf_face(reveal, zp, z1, z2)}, self.vis("structures"))
                wf_box(v, B(a, s2, z1, b, 64, z2), {"north": wf_face("north", zp, z1, z2), reveal: wf_face(reveal, zp, z1, z2)}, self.vis("structures"))
            v.world_box(B(a, s1, zp, b, s2, top), MAT["black"], MAT["black"], MAT["black"], vis=self.vis("structures"))
        lit = MS.lit_from(v, "lc_bunker_door_lighting", W(mid, 96, zp + 108), dv)     # (inside, in front of the doorway, at the leaves' middle height)
        lit_out = MS.lit_from(v, "lc_bunker_door_lighting_out", W(mid, -32, zp + 108), dv)     # (the same outside, for the outer leaves)
        model = [p for p in pf["points"] if p["keys"].get("model", "").endswith("missile_doors.mdl")][0]["keys"]
        e0, e1 = W(0, 0, 0), W(1, 0, 0)
        east = int(round(math.degrees(math.atan2(e1[1] - e0[1], e1[0] - e0[0])))) % 360       # (the bunker's +u in the map)
        for tag, (a, b), way, roll in (("west", (d1 - 8, mid), -1, -90), ("east", (mid, d2 + 8), 1, 90)):
            name = "lc_bunker_door_" + tag
            yaw = (east + (0 if way > 0 else 180)) % 360        # (the model's own +x away from the middle: its meeting edge is its -x, as in Valve's)
            v.brush_entity("func_button", {"targetname": name, "movedir": "0 %d 0" % yaw, "speed": str(self.FLAT_SPEED), "lip": str(lip), "wait": "-1", "spawnflags": "0",
                                           "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                           [B(a, 32 - self.FLAT_HALF_T - 2, zp, b, 32 + self.FLAT_HALF_T + 2, top)], MAT["nodraw"], dv)     # (as thick as the pair of leaves)
            keys = {k: model[k] for k in ("model", "skin", "MinAnimTime", "MaxAnimTime", "RandomAnimation", "SetBodyGroup", "PerformanceMode", "pressuredelay",
                                          "ExplodeDamage", "ExplodeRadius") if k in model}
            keys.update({"targetname": name + "_model", "angles": "0 %d %d" % (yaw, roll), "parentname": name, "solid": "0", "disableshadows": "1", "lightingorigin": lit,
                         "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "modelscale": str(sc), "StartDisabled": "0", "renderamt": "255",
                         "rendercolor": "255 255 255"})
            # Valve's leaf is drawn on one side only (the side seen from inside Silo 2): its other side shows as nodraw (the
            # owner, 23 November: "the blast doors at the bunker entrance are "nodraw" on the outside ... can we get the prop
            # mirrored so it's double thick and the nodraw surfaces are facing each other in the middle"). So each leaf is a
            # pair, back to back on the doorway's middle (32): this one inside, its drawn side to the bunker, and its mirror
            # (turned half round its length) outside, its drawn side to the forest, lit from outside.
            v.point("prop_dynamic", W((a + b) // 2, 32 + self.FLAT_HALF_T, zp + int(round(164.8 * sc))), keys, dv)
            back = dict(keys, targetname="lc_bunker_outer_leaf_" + tag, angles="0 %d %d" % (yaw, roll + 180), lightingorigin=lit_out)
            v.point("prop_dynamic", W((a + b) // 2, 32 - self.FLAT_HALF_T, zp + int(round(164.8 * sc))), back, dv)
        v.point("logic_auto", W(mid, 200, zp + 150), {"spawnflags": "1"}, dv, connections=[("OnMapSpawn", "lc_bunker_door_*", "PressIn", "", 0.5)])
        # an areaportal across the doorway, in the leaves' plane, shut with them, so the bunker is not drawn from outside
        # nor the forest from inside (a shut door is only drawn from both sides if it is on both sides of its areaportal)
        portal = B(u1, 31, zp, u2, 33, top)
        self.vmf.portals.append(portal)
        v.brush_entity("func_areaportal", {"targetname": "lc_bunker_portal", "StartOpen": "1", "PortalVersion": "1"}, [portal], MAT["portal"], dv)
        # a floor plate 1 thick over the doorway's whole floor, across the areaportal's plane (a detail face belongs to every
        # leaf it touches, so it is drawn from both sides of the shut portal: with it, no gap shows at the leaves' foot)
        v.detail([B(u1, 0, zp, u2, 64, zp + 1)], FMAT["wf_floor"], vis=self.vis("structures"))
        # the leaves' steel frame (the owner, 23 November: "build a frame/rails to go around the edges of the bunker doors?
        # They are supposed to be on a rail/frame"): a post up each jamb either side of its slot, standing 4 into the
        # doorway; a channel across the top and one along the floor (lips 7 wide either side of the leaves, 8 deep at the top,
        # 3 high on the floor, stepped over), each with a black strip between its lips where the leaves run
        fr = FMAT["leaf_frame"]
        for c1, c2 in ((s1 - 7, s1), (s2, s2 + 7)):
            v.detail([B(u1, c1, zp + 1, u1 + 4, c2, top), B(u2 - 4, c1, zp + 1, u2, c2, top),      # (the posts)
                      B(u1 + 4, c1, top - 8, u2 - 4, c2, top), B(u1 + 4, c1, zp + 1, u2 - 4, c2, zp + 4)], fr, vis=dv)   # (the lips between them: never flush with a post)
        v.detail([B(u1, s1, top - 1, u2, s2, top), B(u1, s1, zp + 1, u2, s2, zp + 2)], MAT["black"], vis=dv)
        ht = self.FLAT_HALF_T
        v.keep_way_clear(B(u1, -48, zp + 4, u2, 32 - ht - 4, zp + 110), "the bunker's doorway (outside the leaves)")     # (the leaves' own plane is theirs)
        v.keep_way_clear(B(u1, 32 + ht + 4, zp + 4, u2, 112, zp + 110), "the bunker's doorway (inside the leaves)")
        # the shove at the close: outside the leaves pushing out, inside pushing in (harder); each reaching 8 past the doorway,
        # as the pair of leaves is twice as thick as one
        self.shove("lc_bunker_shove", [(B(u1, -8, zp, u2, 32, zp + 160), (east + 270) % 360, 200), (B(u1, 32, zp, u2, 72, zp + 160), (east + 90) % 360, 300)], dv)

        def sound(name, message, at, loops=False):
            # (spawnflags: 16 starts silent, 32 says "not looped". A sound that loops must NOT have 32: with it the entity
            #  never counts the sound as playing, so StopSound does nothing. The owner: "the closing sound NEVER STOPS".)
            v.point("ambient_generic", at, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": "2200",
                                            "spawnflags": "16" if loops else "48",
                                            "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                            "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        at = W(mid, 32, zp + 96)
        sound("lc_bunker_alarm", "ambient/alarms/klaxon1.wav", W(mid, 100, zp + 170))
        sound("lc_bunker_start", "ep2_outland_11.launchdoors_close_start", at)
        sound("lc_bunker_move", "ep2_outland_11.launchdoors_close_loop", at, loops=True)
        sound("lc_bunker_stop", "ep2_outland_11.launchdoors_close_end", at)
        # a mild shake as they meet with Valve's end sound (the owner, 22 November: "Can we have a mild screen shake when they
        # have closed?"), as the round door had here, and a lighter one as they come to rest open
        for name, amp, radius, secs in (("lc_bunker_shake", 4, 600, 1), ("lc_bunker_shake_open", 2, 400, 0.6)):
            v.point("env_shake", at, {"targetname": name, "amplitude": str(amp), "radius": str(radius), "duration": str(secs), "frequency": "40", "spawnflags": "0"}, dv)
        for pos in (W(mid, -28, zp + 240), W(mid, 150, zp + 190)):
            v.point("light", pos, {"targetname": "lc_bunker_light", "_light": "255 50 30 300", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                   "style": "0"}, dv)
        # the wiring. Shutting: klaxon and light at once, the leaves start a second later and slide for `travel` seconds;
        # the shove for the last 0.6 s and 0.3 after; the end sound and the areaportal as they meet.
        end = 1 + travel
        shut = [("OnTrigger", "lc_bunker_close", "Disable", "", 0), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0)]
        shut += [("OnTrigger", "lc_bunker_alarm", "PlaySound", "", round(1.7 * k, 1)) for k in range(int(end / 1.7) + 1)]
        shut += [("OnTrigger", "lc_bunker_door_*", "PressOut", "", 1), ("OnTrigger", "lc_bunker_start", "PlaySound", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1.5),
                 ("OnTrigger", "lc_bunker_shove", "Enable", "", end - 0.6), ("OnTrigger", "lc_bunker_shove", "Disable", "", end + 0.3),
                 ("OnTrigger", "lc_bunker_move", "StopSound", "", end), ("OnTrigger", "lc_bunker_stop", "PlaySound", "", end), ("OnTrigger", "lc_bunker_shake", "StartShake", "", end),
                 ("OnTrigger", "lc_bunker_portal", "Close", "", end + 0.2),
                 ("OnTrigger", "lc_bunker_light", "TurnOff", "", end + 2.5), ("OnTrigger", "lc_bunker_open", "Enable", "", end + 2)]
        unshut = [("OnTrigger", "lc_bunker_open", "Disable", "", 0), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0), ("OnTrigger", "lc_bunker_start", "PlaySound", "", 0),
                  ("OnTrigger", "lc_bunker_portal", "Open", "", 0.9), ("OnTrigger", "lc_bunker_door_*", "PressIn", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1.5),
                  ("OnTrigger", "lc_bunker_move", "StopSound", "", end), ("OnTrigger", "lc_bunker_stop", "PlaySound", "", end),
                  ("OnTrigger", "lc_bunker_shake_open", "StartShake", "", end), ("OnTrigger", "lc_bunker_light", "TurnOff", "", end + 1),
                  ("OnTrigger", "lc_bunker_close", "Enable", "", end + 2)]
        relay = W(mid, 200, zp + 120)
        v.point("logic_relay", relay, {"targetname": "lc_bunker_close", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=shut)
        v.point("logic_relay", (relay[0] + 16, relay[1], relay[2]), {"targetname": "lc_bunker_open", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=unshut)
        # the button: inside, on the front wall right by the doors (east of them, the owner, 26 November: it had been on the
        # far wall west of the stairs), at hand height; one press works whichever relay is live. Emergency closes in the
        # control room and the leader's office: map_launch.emergency_buttons.
        wall_button(v, W(780, 64, zp + 40), 90, "lc_bunker_button", B(766, 64, zp + 36, 786, 74, zp + 64), dv,
                    [("OnPressed", "lc_bunker_close", "Trigger", "", 0), ("OnPressed", "lc_bunker_open", "Trigger", "", 0)], "9")
        # nobody left inside and the door shut: it opens again (the unshutting relay is only live while it is shut). Inside
        # is every room, stair and corridor of the bunker, the corridor to the silo and the WHOLE silo (its hull's inside,
        # every floor from the pit to the collar), each box floor to ceiling and touching the next. The owner (22 November)
        # went down the silo's ladder and the door opened "as if no one was in the bunker anymore": the 20 s was a delayed
        # output that nothing could take back, so one moment of touching nothing (a gap, a ladder) opened it 20 s later
        # whoever was inside by then. Now the last one out starts a countdown (lc_bunker_empty), anyone coming in cancels
        # it, and when it runs out the trigger is asked again (TouchTest): it opens only if nobody is touching it then.
        inside = []
        for p, skip in ((self.plan, (d1, 0, d2, 64)), (self.deep, None), (self.low, None)):
            for x1, y1, x2, y2, spec in p.rectangles():
                if spec[0] != "solid" and not (skip and x1 >= skip[0] and x2 <= skip[2] and y1 >= skip[1] and y2 <= skip[3]):
                    inside.append(B(x1, y1, spec[1] - 8, x2, y2, spec[3]))      # (from under a doorway's sill)
        for cell, r, z in self.windows.values():      # (and the shuttered windows beside the room doors: shutter_window)
            inside.append(B(cell[0], cell[1], z, cell[2], cell[3], z + WF_BAND))
        inside.append(self.silo_inside())
        inside += getattr(self, "complex_air", [])      # (the control complex up by the silo: map_launch.py)
        inside += MS.way_inside()      # (the leader's way out: whoever is in it is still inside until out of its door)
        fv = self.vis("bunker door's failsafe (delete to let it stay shut when empty)")
        v.brush_entity("trigger_multiple", {"targetname": "lc_bunker_inside", "spawnflags": "1", "wait": "1", "StartDisabled": "0"}, inside, MAT["trigger"], fv,
                       connections=[("OnEndTouchAll", "lc_bunker_empty", "Trigger", "", 0.1), ("OnStartTouch", "lc_bunker_empty", "CancelPending", "", 0),
                                    ("OnNotTouching", "lc_bunker_open", "Trigger", "", 0)])
        v.point("logic_relay", (relay[0] + 32, relay[1], relay[2]), {"targetname": "lc_bunker_empty", "StartDisabled": "0", "spawnflags": "0"}, fv,
                connections=[("OnTrigger", "lc_bunker_inside", "TouchTest", "", 20)])
        self.inside_boxes = inside

    def silo_door(self):
        """White Forest's round blast door (the piece valve_ep2_bunker_door) at the actual entrance of the silo (the owner,
        22 November: "the silo doors at the entrance to the bunker need to be moved to the actual entrance to the silo"):
        at the mouth of the silo's west tunnel, 32 further toward the bunker than Valve had it (BLAST_AT: its hinge posts
        clear of the lift's car standing in the walkway at its top stop), the drum at the end of the corridor from the bunker
        (widened there to 256 and 192 high, the stairs ending where it widens: setup()), Valve's way round: its leaves swing
        toward the bunker, into the corridor's end. (Turned the other way, from 22 November, they swung through the lift's
        car at the top: the owner, "the doors clip through the elevator when closing".) A drum of concrete and steel 224
        wide: its lower 160 two leaves hinged on the silo's side that swing 60 degrees at Valve's 6 a second (10 s), a lock
        bar in the floor, Valve's start, loop and end sounds. It stands open. An inner door: a button each side (the stairs'
        east wall; inside, Valve's keypad with a lamp over it on the tunnel's east wall beside the doorway) shuts it and
        opens it again, with a klaxon and a steady red light; shut from inside, the outside one is locked until it is opened
        from inside or the silo empties. Each leaf is a
        func_rot_button used as a mover, so none of it is a door to the gamemode. Nothing kills: in the last moments of the
        close a shove (shove()) pushes whoever is in the doorway out of it. It had its own areaportal until 24 November;
        since the silo opens on the launch pad (map_launch.py) the bunker's areaportal parts the bunker from the forest
        and the secret panel's the silo from the way out."""
        v = self.vmf
        sx, sy, sz = self.silo_at
        zg = self.zg
        vis, dv = self.vis("structures"), self.vis("silo door (the leaves, the buttons, the wiring)")
        pf = PF.load("valve_ep2_bunker_door")
        dy = sy - self.BLAST_AT
        q, d = 1, (sx, dy, zg)                # (Valve's way round: the leaves swing toward the bunker, never into the lift's car)
        half = int(pf["size"][1]) // 2       # (112)
        top = zg + 192
        y0, y1 = dy - 32, sy - 544             # (from the drum's face on the corridor's side to the hull's inner face)
        # the drum's head, its jambs and hinge posts (detail); what Valve left bare of them where the corridor's end and the
        # silo's tunnel now show it (the head's back, over the doorway) in the silo's finish
        pf_solids(v, pf, q, d, vis, finish=[([(sx - 192, y0 - 128, zg - 8, sx + 192, sy - 544 + 64, top + 64)], MS.FINISH_MAT)])
        for a, b in ((sx - 128, sx - half), (sx + half, sx + 128)):      # the doorway filled to the drum each side (world: the areaportal's edges)
            wf_box(v, (a, y0, zg, b, y1, top), {k: wf_face(k, zg, zg, top) for k in ("east", "west", "north", "south")}, vis)
        travel = 60.0 / self.DOOR_SPEED
        for w in pf["wiring"]:
            if w["classname"] != "func_door_rotating":
                continue
            south = w["origin"][1] < 0
            name = "lc_silo_blast_leaf_" + ("a" if south else "b")
            pf_brush_entity(v, "func_rot_button", {
                "targetname": name, "angles": "0 0 0", "distance": "60", "speed": str(self.DOOR_SPEED), "wait": "-1", "lip": "0",
                "spawnflags": str(int(w["keys"]["spawnflags"]) & 2), "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0",
                "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0", "disableshadows": "0"},
                w["brushes"], q, d, dv, origin=pf_point(w["origin"], q, d))
            if south:
                lock = [x for x in pf["wiring"] if x["keys"].get("targetname") == "doorlock_biground_1"][0]
                dl = (d[0], d[1], d[2] - 1)      # (sunk 1 into the floor: only its pins show, and no face lies in the floor's plane)
                pf_brush_entity(v, "func_button", {
                    "targetname": "lc_silo_blast_lock", "movedir": "90 0 0", "speed": "100", "lip": "0", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
                    "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255",
                    "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, lock["brushes"], q, dl, dv, origin=pf_point(lock["origin"], q, dl))
        v.point("logic_auto", (sx, dy - 136, zg + 150), {"spawnflags": "1"}, dv,
                connections=[("OnMapSpawn", "lc_silo_blast_lock", "PressIn", "", 0.4), ("OnMapSpawn", "lc_silo_blast_leaf*", "PressIn", "", 0.5)])
        # (no areaportal of its own since 24 November: the silo opens on the launch pad, and the pad on the launch room's
        #  window, so the air on the door's two sides meets another way and vbsp would stop: 'areaportal brush doesn't
        #  touch two areas')
        v.detail([(sx - half, dy - 36, zg, sx + half, dy + 36, zg + 1)], FMAT["wf_floor"], vis=vis)       # (ending short of the lift's shaft)
        v.keep_way_clear((sx - 64, dy - 104, zg + 4, sx + 64, sy - 552, zg + 110), "the silo's door")
        self.shove("lc_silo_blast_shove", [((sx - 40, dy - 60, zg, sx + 40, dy - 34, zg + 160), 270, 200),
                                           ((sx - 104, dy - 60, zg, sx - 40, dy - 24, zg + 160), 270, 200), ((sx + 40, dy - 60, zg, sx + 104, dy - 24, zg + 160), 270, 200),
                                           ((sx - 40, dy - 30, zg, sx + 40, sy - 548, zg + 160), 90, 300),
                                           ((sx - 104, dy - 4, zg, sx - 40, sy - 548, zg + 160), 90, 300), ((sx + 40, dy - 4, zg, sx + 104, sy - 548, zg + 160), 90, 300)], dv)

        def sound(name, message, at, loops=False):
            v.point("ambient_generic", at, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": "2200",
                                            "spawnflags": "16" if loops else "48",
                                            "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                            "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        at = (sx, dy, zg + 96)
        sound("lc_silo_blast_alarm", "ambient/alarms/klaxon1.wav", (sx, dy - 96, zg + 150))
        sound("lc_silo_blast_start", "ep2_outland_11.blastdoors_open_start", at)
        sound("lc_silo_blast_move", "ep2_outland_11.blastdoors_open_loop", at, loops=True)
        sound("lc_silo_blast_stop", "ep2_outland_11.blastdoors_open_end", at)
        sound("lc_silo_blast_slam", "ep2_outland_11.blastdoors_close_end", at)
        sound("lc_silo_blast_groan", "ambient/materials/metal_stress4.wav", at)
        for pos in ((sx, dy - 76, zg + 150), (sx, sy - 540, zg + 170)):
            v.point("light", pos, {"targetname": "lc_silo_blast_light", "_light": "255 50 30 300", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                   "style": "0"}, dv)
        v.point("env_shake", at, {"targetname": "lc_silo_blast_shake", "amplitude": "5", "radius": "700", "duration": "1.6", "frequency": "40", "spawnflags": "0"}, dv)
        end = 1 + travel
        shut = [("OnTrigger", "lc_silo_blast_close", "Disable", "", 0), ("OnTrigger", "lc_silo_blast_light", "TurnOn", "", 0),
                ("OnTrigger", "lc_silo_blast_inside_lamp", "Color", "197 6 1", 0)]
        shut += [("OnTrigger", "lc_silo_blast_alarm", "PlaySound", "", round(1.7 * k, 1)) for k in range(int(end / 1.7) + 1)]
        shut += [("OnTrigger", "lc_silo_blast_leaf*", "PressOut", "", 1), ("OnTrigger", "lc_silo_blast_move", "PlaySound", "", 1),
                 ("OnTrigger", "lc_silo_blast_shove", "Enable", "", end - 0.6), ("OnTrigger", "lc_silo_blast_shove", "Disable", "", end + 0.3),
                 ("OnTrigger", "lc_silo_blast_move", "StopSound", "", end), ("OnTrigger", "lc_silo_blast_slam", "PlaySound", "", end),
                 ("OnTrigger", "lc_silo_blast_groan", "PlaySound", "", end + 0.1), ("OnTrigger", "lc_silo_blast_shake", "StartShake", "", end),
                 ("OnTrigger", "lc_silo_blast_lock", "PressOut", "", end),
                 ("OnTrigger", "lc_silo_blast_close_inside", "Disable", "", 0),
                 ("OnTrigger", "lc_silo_blast_light", "TurnOff", "", end + 2.5), ("OnTrigger", "lc_silo_blast_open", "Enable", "", end + 2)]
        unshut = [("OnTrigger", "lc_silo_blast_open", "Disable", "", 0), ("OnTrigger", "lc_silo_blast_light", "TurnOn", "", 0),
                  ("OnTrigger", "lc_silo_blast_groan", "PlaySound", "", 0), ("OnTrigger", "lc_silo_blast_lock", "PressIn", "", 0),
                  ("OnTrigger", "lc_silo_blast_start", "PlaySound", "", 0),
                  ("OnTrigger", "lc_silo_blast_leaf*", "PressIn", "", 1), ("OnTrigger", "lc_silo_blast_move", "PlaySound", "", 1),
                  ("OnTrigger", "lc_silo_blast_move", "StopSound", "", end), ("OnTrigger", "lc_silo_blast_stop", "PlaySound", "", end),
                  ("OnTrigger", "lc_silo_blast_light", "TurnOff", "", end + 1), ("OnTrigger", "lc_silo_blast_close", "Enable", "", end + 2),
                  ("OnTrigger", "lc_silo_blast_inside_lamp", "Color", "40 220 40", end),
                  ("OnTrigger", "lc_silo_blast_button_corridor", "Unlock", "", 0), ("OnTrigger", "lc_silo_blast_locked_lamp", "HideSprite", "", 0),
                  ("OnTrigger", "lc_silo_blast_locked", "SetValue", "0", 0),
                  ("OnTrigger", "lc_silo_blast_close_inside", "Enable", "", end + 2)]
        relay = (sx + 16, dy - 136, zg + 120)
        v.point("logic_relay", relay, {"targetname": "lc_silo_blast_close", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=shut)
        v.point("logic_relay", (relay[0] + 16, relay[1], relay[2]), {"targetname": "lc_silo_blast_open", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=unshut)
        # the buttons: on the corridor's east wall by its last step (outside), and on the silo tunnel's east wall past the
        # leaves (inside). Either shuts it and opens it again; but shut from inside, the outside one is locked (it buzzes, a
        # red lamp over it lit) until it is opened from inside (the owner, 22 November: "if the silo doors are closed by the
        # button on the inside of the silo, THEN the button between the bunker and silo doors ... deactivates until the silo
        # doors have been opened from the inside ... that way if a rocket launch is going to happen, everyone can evacuate
        # and they can close the silo doors behind them, BUT if the resistance is inside the silo, then they can close the
        # doors from the inside for safety"). No opening by itself when the silo is empty: it would undo an evacuation.
        press = [("OnPressed", "lc_silo_blast_close", "Trigger", "", 0), ("OnPressed", "lc_silo_blast_open", "Trigger", "", 0)]
        inside = [("OnPressed", "lc_silo_blast_close_inside", "Trigger", "", 0), ("OnPressed", "lc_silo_blast_open", "Trigger", "", 0)]
        v.point("logic_relay", (relay[0] + 32, relay[1], relay[2]), {"targetname": "lc_silo_blast_close_inside", "StartDisabled": "0", "spawnflags": "0"}, dv,
                connections=[("OnTrigger", "lc_silo_blast_close", "Trigger", "", 0), ("OnTrigger", "lc_silo_blast_button_corridor", "Lock", "", 0),
                             ("OnTrigger", "lc_silo_blast_locked_lamp", "Color", "197 6 1", 0), ("OnTrigger", "lc_silo_blast_locked_lamp", "ShowSprite", "", 0),
                             ("OnTrigger", "lc_silo_blast_locked", "SetValue", "1", 0)])
        # nobody left in the silo with it shut from inside: the outside button works again and its lamp turns green (the
        # owner: "if they leave then the button lights up green on the outside of the silo door and the button works
        # again"). The door does not open; coming back in does not lock it again, only shutting it from inside does. The
        # silo's inside is the hull's and the tunnel's mouth inside the door; the last one out starts 2 s, anyone back in
        # cancels them, and then it is asked again (TouchTest), as the bunker's own failsafe does.
        v.point("logic_branch", (relay[0] + 48, relay[1], relay[2]), {"targetname": "lc_silo_blast_locked", "InitialValue": "0"}, dv,
                connections=[("OnTrue", "lc_silo_blast_button_corridor", "Unlock", "", 0), ("OnTrue", "lc_silo_blast_locked_lamp", "Color", "40 220 40", 0),
                             ("OnTrue", "lc_silo_blast_locked", "SetValue", "0", 0)])
        sv_ = self.vis("silo door's lock (who is in the silo)")
        v.brush_entity("trigger_multiple", {"targetname": "lc_silo_inside", "spawnflags": "1", "wait": "1", "StartDisabled": "0"},
                       [self.silo_inside(), (sx - half, dy + 2, zg, sx + half, sy - 544, top)], MAT["trigger"], sv_,
                       connections=[("OnEndTouchAll", "lc_silo_empty", "Trigger", "", 0.1), ("OnStartTouch", "lc_silo_empty", "CancelPending", "", 0),
                                    ("OnNotTouching", "lc_silo_blast_locked", "Test", "", 0)])
        v.point("logic_relay", (relay[0] + 64, relay[1], relay[2]), {"targetname": "lc_silo_empty", "StartDisabled": "0", "spawnflags": "0"}, sv_,
                connections=[("OnTrigger", "lc_silo_inside", "TouchTest", "", 2)])
        wall_button(v, (sx + 64, dy - 88, zg + 56), 180, "lc_silo_blast_button_corridor", (sx + 54, dy - 98, zg + 52, sx + 64, dy - 78, zg + 80), dv, press, "9",
                    extra={"locked_sound": "2"})      # (Access Denied, as Valve's locked buttons)
        v.point("env_sprite", (sx + 62, dy - 88, zg + 84), {"targetname": "lc_silo_blast_locked_lamp", "model": "sprites/glow01.spr", "rendermode": "9",
                                                             "rendercolor": "197 6 1", "renderamt": "215", "renderfx": "0", "scale": "0.15", "GlowProxySize": "2",
                                                             "HDRColorScale": ".5", "framerate": "10.0", "spawnflags": "0", "disablereceiveshadows": "0"}, dv)
        # the inside one: not the lift's mine button but Valve's keypad (props_lab/keypad, as beside the silo's own doors) with
        # a lamp over it, red while the door is shut, green open, on the tunnel's east wall right beside the doorway, the
        # wall without the lift's call button, at the outside one's height (the owner, 22 November: "there is no
        # distinguishing between the elevator call button on one wall and the silo door button on the other ... the silo
        # door button needs to be away from the elevator"). Reached from the floor beside the shaft's mouth, which neither
        # the car nor the grates ever fill.
        bx, by = sx + self.BLAST_PAD[0], sy - self.BLAST_PAD[1]
        v.point("prop_dynamic", (bx - 1, by, zg + 56), {"targetname": "lc_silo_blast_button_silo_model", "model": "models/props_lab/keypad.mdl", "angles": "0 180 0",
                                                        "solid": "0", "skin": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                                                        "StartDisabled": "0", "spawnflags": "0"}, dv)
        v.brush_entity("func_button", {"targetname": "lc_silo_blast_button_silo", "spawnflags": "1025", "wait": "9", "speed": "5", "lip": "0", "movedir": "0 0 0",
                                       "sounds": "0", "health": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "min_use_angle": "0.8"},
                       [(bx - 8, by - 7, zg + 48, bx, by + 7, zg + 68)], MAT["nodraw"], dv, connections=inside)
        v.point("env_sprite", (bx - 2, by, zg + 76), {"targetname": "lc_silo_blast_inside_lamp", "model": "sprites/glow01.spr", "rendermode": "9",
                                                      "rendercolor": "40 220 40", "renderamt": "215", "renderfx": "0", "scale": "0.15", "GlowProxySize": "2",
                                                      "HDRColorScale": ".5", "framerate": "10.0", "spawnflags": "1", "disablereceiveshadows": "0"}, dv)
        self.notes.append("the silo's door: White Forest's round blast door at the mouth of the silo's tunnel, a button each side (shut from inside, the outside "
                          "one is locked until it is opened from inside or the silo is empty), its own areaportal")

    def silo_inside(self):
        """The silo's whole inside (the hull's inner faces: 1088 square round the shaft's axis, from 64 under the pit floor
        to the collar's top), as one box: everything in it counts as inside the bunker."""
        sx, sy, sz = self.silo_at
        return (sx - 544, sy - 544, sz + self.HULL_FLOOR, sx + 544, sy + MS.OFFICE_HULL, sz + 1824)      # (from the hull's floor, under the pit's; the office's too)

    # the lift's stops: the silo piece's floors with a landing on the lift shaft, bottom to top. A floor becomes a stop by
    # adding its height here (with its landing open in the piece): its path point, gate, call button and wiring are all
    # made from this list. Only the bottom level and the walkway since 23 November (the owner: "I cannot find any
    # reasonable use for the mid levels of the silo; only the top and bottom floors ... program the lift to only go to the
    # top and bottom floors"): the car rides past levels A and B (896, 1152), whose landings are shut (map_silo.Silo.
    # shaft_shut); putting one back means opening its landing in the piece again too.
    # The top stop is the walkway into the silo from the bunker (the gantry level), where the car stands in the walkway with
    # both its ends open (lift(): the owner, 22 November, "can the lift sit in this space/walkway when at the top floor, with
    # both front and back doors open, and then if someone uses the lift it lowers to another floor and then the floor
    # grates slide back over the hole where the lift was to make the walkway?").
    LIFT_STOPS = (320, 1408)
    LIFT_XY = (-480, 0)          # the lift's track in the piece's frame: 480 from the shaft's axis, which stays clear
    LIFT_BUILT = 1152            # the car's floor where Valve built it (level B): its parts are placed there and it goes to its top stop at the start
    HULL_FLOOR = 256    # the silo's hull's floor, over the piece's pit floor: under the rocket's engines (its foot 328 up), all of it in sealed air
    SILO_PIT = 1152     # the silo cut to its top floor (the owner, 23 November): the pit's black floor, a level under the top floor's
    LIFT_HOLE = (-544, -72, -416, 72)   # the shaft's mouth in the walkway's floor (Valve's grates and middle strut over it are left out: map_silo.SKIP)
    GRATE_SPEED, GRATE_AFTER = 48, 4.5  # the walkway's two sliding grates: units a second; seconds after the car leaves the top before they close
    LIFT_CALL_TOP = (-384, 86)          # the walkway's call button: on its end frame's face toward the gantry, north of the opening
    HQ_AT = (102, 77)                          # (the silo's frame) the flag's pole: 128 from the axis, 37 degrees round, beside the rocket
    HQ_FOOT, HQ_TOP = 1152 + 8, 1408 + 120     # the Resistance flag's markers beside the rocket: over the pit's floor (SILO_PIT, since 23 November) and the gantry (1408)
    # the rebel territory the gamemode reads from the map round the flag's pole: a box 1400 wide each way and 1800 high
    # from the floor under the marker (the gamemode's reading), so the marker stands on the bottom floor beside the pole's foot
    REBEL_ZONE = ("lc_zone_rebel_r700_h970_silo", 1152 + 8)     # (its top where it was, 2130 over the piece: from the pit's floor since 23 November)

    def silo(self):
        """White Forest's rocket silo (the lifted piece valve_ep2_silo: docs/dev/prefabs.md) just outside the forest's north
        wall, turned a quarter so that its west tunnel faces the corridor from the radio room, its gantry level the
        corridor's floor (zg), its lid 192 under the bunker's door. Its world brushes go into the world (they cut up the
        map for visibility as in Valve's own), the rest as detail; sealed in a hull of our own 64 thick (nodraw outside,
        the silo's own concrete inside, so each mouth of the piece Valve's rooms ran on through ends at a plain wall), with
        one opening: where the corridor comes in. Its wiring: the lift (lift(): a stop at every floor in LIFT_STOPS, it
        starts at the top), the ladder from the gantry to the lift's top landing always usable (its hatch removed), the lab
        door at the bottom (the Resistance leader's office) opened and shut by Use (its model on the door, not solid), with
        Valve's lever wall (the lever, its recess, its box and lights) moved inside to lock it; the keypads have names of
        their own; the steam gate, the areaportals, the lab door's malfunction, Valve's story (scenes, NPC makers, the
        autosave, Uriah), Valve's soundscapes (map_silo.py places the silo's own) and the piece's reserve (the hoisted
        machine) are left out. Invisible player clips stand in the shaft round the rocket (put back on 22 November) at the
        open levels and the gantry, so nobody walks off into a 1,250 drop; the walkway up to the rocket's hatch is left out
        of the gantry's. Two info_targets on the shaft's axis
        mark the Resistance flag's pole beside the rocket: lc_hq_setup_silo 8 over the bottom floor (the pit's cover), lc_hq_setup_silo_top
        120 over the gantry; beside the foot the rebel territory's marker (REBEL_ZONE). map_silo.py makes it playable:
        the pit covered, the bare floors finished and dressed, level B's doors, the leader's office and bedroom, the
        fence gate, light where rooms had none, the soundscapes, and his way out (the secret panel, the cave tunnel, the
        cache cave and the rock on the rim)."""
        v = self.vmf
        sv, wv = self.vis("silo (Valve's White Forest silo)"), self.vis("silo's wiring")
        pf = PF.load("valve_ep2_silo")
        ax, ay, az = self.silo_at
        q, d = 1, (ax, ay, az)
        reserve = set(pf.get("reserve", {}).get("names", ()))
        live = set(w["keys"].get("targetname", "") for w in pf["wiring"]) - {""}
        finished = MS.finish(pf)        # (the nodraw faces players now see: map_silo.py)
        MS.trim_mouth(pf)               # (clear of the blast door's leaves)
        for i in MS.SKIP:
            pf["solids"][i]["skip"] = True
        pf["solids"][129]["skip"] = True      # (the plate behind Valve's ladder down to level B's balcony: gone with it)
        pf["solids"][210]["skip"] = True      # (the silo's lid: since 24 November the shaft is open to the sky, the launch pad over it: map_launch.py)
        for i in MS.DOORWAY_SEGS + MS.DOORWAY_CONE:
            pf["solids"][i]["skip"] = True    # (the shaft's wall opened for the way to the leader's office: Silo.vestibule)

        def under(sol):
            """Under the top floor's floor, where the silo was cut away (the owner, 23 November: "delete the entire silo
            EXCEPT the top floor ... we don't have the brush budget"): all but the pit's wall, the shaft's own segments
            from the pit's floor up (250 to 292 from the axis)."""
            pts = [c for sd in sol["sides"] for c in (sd.get("corners") or sd["plane"])]
            if max(p[2] for p in pts) > 1392:
                return False
            rs = [math.hypot(p[0], p[1]) for p in pts]
            return not (min(rs) >= 250 and max(rs) <= 292 and min(p[2] for p in pts) >= self.SILO_PIT - 8)
        pf_solids(v, pf, q, d, sv, world=True, skip=lambda s: "taken shut" in s["from"] or s.get("live") in live or s.get("skip") or under(s))
        drop = {"steam_silo1_1", "tr_laddergate_1", "sound_ladder_steam_1", "sound_ladder_steamloop_1", "sound_ladder_lock_1", "door_silo_lab_outside_1_malfunction_timer",
                # the ladder's hatch and the clip over it (the owner: "there is no way to open the gate ... can we just remove that grate?")
                "door_hatch_ladder_1", "pclip_hatch_1",
                # the lab door's keypad relay and beeps (it opens by Use now), the glass over its lever and what breaking it did
                "door_silo_lab_outside_1_door_open_rl", "door_silo_lab_outside_1_open_wav", "door_silo_lab_outside_1_keybeep_wav_1", "door_silo_lab_outside_1_keybeep_wav_2",
                "door_silo_lab_outside_1_keybeep_wav_3", "break_glass_1", "break_glass_1a", "exit_airlock_blastdoor_lever_rl",
                # Valve's lift button, the trigger that locked it, its path: lift() makes them anew
                "button_ele_2", "trigger_unlock_ele", "path_elevator_5", "path_elevator_6", "path_elevator_7", "path_elevator_8",
                # level B's fake door at its north end (a working door now: map_silo.py)
                "brush_fake_cit_door_1",
                # the lab door's malfunction (a passable door between the door and its model that only jerked it about, with
                # clicks and sparks: the model hangs on the door itself now) and what played it
                "door_silo_lab_outside_1_malfunction_door", "door_silo_lab_outside_1_malfunction_case", "door_silo_lab_outside_1_malfunction_spark",
                "door_silo_lab_outside_1_malfunction_reset"} | set("door_silo_lab_outside_1_malfunction_wav_%d" % k for k in range(1, 7))
        def office(e):
            """Valve's things that went with the leader's office and its lever (lifted onto the top floor: map_silo.py's
            OFFICE_PICK, office_in): by where they stood, or by name (the lever, its lights and cables stood in the hall)."""
            if e.get("office") is not None:
                return e["office"]
            k, o = e["keys"], e.get("origin") or ()
            tn = k.get("targetname", "")
            b = MS.OFFICE_PICK
            e["office"] = (k.get("targetname", "") not in drop and not (e["classname"] in ("func_areaportal", "env_soundscape") or MS.dropped_prop(e))
                           and ((len(o) == 3 and all(b[i] <= o[i] <= b[i + 3] for i in range(3))) or tn in ("exit_airlock_blastdoor_lever", "spr_blast_on", "spr_blast_off")
                                or tn.startswith("exit_airlock_rope_") or "panel_lever" in k.get("model", "")
                                or (e["classname"] == "env_sprite" and len(o) == 3 and abs(o[0] - 282) < 2 and abs(o[1] - 224) < 2)))
            return e["office"]
        pads = [p for p in pf["points"] if "keypad" in p["keys"].get("model", "")]
        buttons = [w for w in pf["wiring"] if w["classname"] == "func_button" and any(c[1].startswith("keypad_1,") for c in w.get("connections", []))]
        pad_name, lab_pads = {}, set()
        for k, b in enumerate(buttons):
            p = min(pads, key=lambda p: sum((p["origin"][i] - b["origin"][i]) ** 2 for i in range(3)))
            pad_name[tuple(p["origin"])] = pad_name[tuple(b["origin"])] = "keypad_%d" % (k + 1)
            if abs(b["origin"][2] - 373) < 20:
                lab_pads.add(tuple(b["origin"]))

        def keep(e):
            k = e["keys"]
            if k.get("targetname", "") in drop or e["classname"] in ("func_areaportal", "env_soundscape") or MS.dropped_prop(e):
                return False        # (Valve's four soundscapes too: map_silo.py's soundscapes() places the silo's own)
            o = e.get("origin") or ()
            if office(e):
                return True         # (the leader's office, on the top floor since 24 November)
            if len(o) == 3 and o[2] < 1392 or "metalladder" in k.get("model", ""):
                return False        # (under the top floor, cut away on 23 November, and the ladder down from it)
            if k.get("targetname", "") in reserve or any(k.get(r, "") in reserve for r in ("parentname", "attach1", "attach2")):
                return False        # (the hoist: kept in the piece's reserve, not placed)
            if e["classname"] == "func_button" and tuple(e.get("origin", ())) in lab_pads:
                return False        # (the lab door's keypads are models only now)
            return not (e["classname"] == "trigger_multiple" and any(c[1].startswith("!activator,Kill") for c in e.get("connections", [])))

        # the lab door's lever, moved from the outside niche to the office's wall east of the door, facing into the office,
        # with the recess it sits in, the box with its two lights over it and the cables from the box (the owner, 22
        # November: "I would like it all to be together on the inside of the office"): map_silo.py's lever_in and
        # Silo.lever_box
        indoors = MS.lever_in
        top = len(self.LIFT_STOPS) - 1

        def edit(e):
            cls, k = e["classname"], e["keys"]
            tn, o = k.get("targetname", ""), tuple(e.get("origin", ()))
            ML.steady(e)        # (nothing of Valve's fades out in the silo: the office door was not drawn from across it)
            if o in pad_name:
                if cls.startswith("prop"):
                    k["targetname"] = pad_name[o]
                else:
                    e["out"] = [(a, pad_name[o] if t == "keypad_1" else t, i, val, dl) for a, t, i, val, dl in e["out"]]
            if cls == "ambient_generic":
                k["spawnflags"] = str(int(k.get("spawnflags", "0") or 0) & ~1)
            if cls == "prop_dynamic" and "silo_door01" in k.get("model", ""):
                e["classname"] = "prop_dynamic_override"      # (the model has physics data: map_assets.py)
            if cls == "prop_static" and k.get("model", "").endswith("generatorconsole.mdl"):
                k["solid"] = "6"        # (the gantry's control panel: Valve's is not solid, and the clipboard on it fell through it)
            if "box01b" in k.get("model", "") and o and abs(o[0] - 56) < 2 and abs(o[1] - 416) < 2:
                e["origin"] = [360, 520, 323]      # (Valve's loose box stood in front of the bedroom's door: into the alcove, by the cabinets)
            if tn == "ladder_hatch_1":
                k["StartDisabled"] = "0"        # (it waited for the hatch to open; with the hatch gone it is always there)
            if tn == "light_hatch_ladder_1":
                k["spawnflags"] = "0"           # (they lit when the hatch opened: now always)
            if tn == "sprite_hatch_ladder_1":
                k["spawnflags"] = "1"
            if tn == "prop_door_silo_lab_outside_1":
                # (the lab door's model: on the door itself, not solid; Valve's was solid and in front of the door's thin
                # brush, so Use met the model and the door never opened: the owner, 22 November: "the leader's office
                # door is completely broken and doesn't open")
                k.update({"parentname": "door_silo_lab_outside_1", "solid": "0"})
            if tn in ("spr_blast_on", "spr_blast_off") or (cls == "env_sprite" and o and abs(o[0] - 282) < 2 and abs(o[1] - 224) < 2):
                e["origin"] = indoors(e["origin"])          # (the lever box's two lights and the one in its recess)
            if tn.startswith("exit_airlock_rope_"):
                # (the box's two cables: up to the ceiling and along the top of the office's wall to the door's frame)
                e["origin"] = {"exit_airlock_rope_1_1": indoors([270, 241, 398]), "exit_airlock_rope_2_1": indoors([270, 241, 402]),
                               "exit_airlock_rope_1_2": [276, 290, 442], "exit_airlock_rope_2_2": [270, 290, 442],
                               "exit_airlock_rope_1_3": [196, 290, 442], "exit_airlock_rope_2_3": [196, 290, 438]}.get(tn, e["origin"])
            if tn == "door_silo_lab_outside_1":     # (the Resistance leader's office: Use opens and shuts it, as the bunker's doors)
                k.update({"spawnflags": str(int(k["spawnflags"]) | 256), "wait": "-1", "locked_sound": "DoorHandles.Locked2", "forceclosed": "0", "dmg": "0"})
                e["out"] = [("OnOpen", "prop_door_silo_lab_outside_1", "SetAnimation", "unlock", 0), ("OnFullyClosed", "prop_door_silo_lab_outside_1", "SetAnimation", "lock", 0)]
            if tn == "exit_airlock_blastdoor_lever":     # (a lever, not a door to the gamemode: pulled, it shuts and locks the door; pushed back, unlocks it)
                e["classname"] = "func_rot_button"
                e["keys"] = {"targetname": tn, "angles": "0 0 0", "distance": k["distance"], "speed": k["speed"], "wait": "-1", "spawnflags": str(1024 | 32 | 64), "sounds": "0",
                             "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0", "disableshadows": "0"}
                e["brushes"], e["origin"] = [MS.lever_in_sides(b) for b in e["brushes"]], indoors(e["origin"])
                e["out"] = [("OnPressed", "lab_lever_sound", "PlaySound", "", 0), ("OnIn", "door_silo_lab_outside_1", "Close", "", 0),
                            ("OnIn", "door_silo_lab_outside_1", "Lock", "", 0.1), ("OnOut", "door_silo_lab_outside_1", "Unlock", "", 0),
                            ("OnIn", "spr_blast_on", "HideSprite", "", 0.1), ("OnIn", "spr_blast_off", "ShowSprite", "", 0.1),
                            ("OnOut", "spr_blast_on", "ShowSprite", "", 0), ("OnOut", "spr_blast_off", "HideSprite", "", 0)]
            if "panel_lever" in k.get("model", ""):
                a = [float(c) for c in k["angles"].split()]
                e["origin"], k["angles"] = indoors(e["origin"]), "%s %s %s" % (PF.fmt(a[0]), PF.fmt((a[1] + 270) % 360), PF.fmt(a[2]))
            if tn == "lift_2":      # (it starts at the top stop; no crush damage; its own path, made by lift())
                k.update({"target": "lift_stop_%d" % top, "height": "0", "startspeed": "40", "speed": "0", "dmg": "0"})
            if tn == "brush_pclip_lift_2":
                k["StartDisabled"] = "1"
            if tn == "lift_door_2_b":      # (a mover only the wiring moves, not a door to the gamemode)
                e["classname"] = "func_button"
                k.update({"spawnflags": "0", "wait": "-1", "sounds": "0", "health": "0", "dmg": "0", "forceclosed": "0"})      # (no harm: Valve's dmg 10 is gone)
            if e.get("office"):         # (the office and its lever onto the top floor: turned and moved as its brushes, map_silo.py's office_in)
                k = e["keys"]           # (the lever's keys are a new dict by now)
                e["origin"] = MS.office_in(e["origin"])
                if e.get("brushes"):
                    e["brushes"] = [MS.office_in_sides(b) for b in e["brushes"]]
                    if k.get("movedir"):
                        a = [float(c) for c in k["movedir"].split()]
                        k["movedir"] = "%s %s %s" % (PF.fmt(a[0]), PF.fmt(MS.office_yaw(a[1])), PF.fmt(a[2]))
                    if e["classname"] in PF_AXES:
                        k["spawnflags"] = str(MS.turned_axis_flags(int(k.get("spawnflags", "0") or 0), MS.OFFICE_TURN, *PF_AXES[e["classname"]]))
                elif "angles" in k:
                    a = [float(c) for c in k["angles"].split()]
                    k["angles"] = "%s %s %s" % (PF.fmt(a[0]), PF.fmt(MS.office_yaw(a[1])), PF.fmt(a[2]))
        # (no lift since the silo was cut to its top floor, 23 November: lift() is no longer placed; the lab lever's sound
        #  with the office, on the top floor since 24 November)
        extra = [{"classname": "ambient_generic", "origin": [261, 300, 384], "keys": {
            "targetname": "lab_lever_sound", "message": "streetwar.drawbridge_lever_start", "health": "10", "pitch": "100", "pitchstart": "100", "radius": "1250", "spawnflags": "48"}}]
        pf_entities(v, pf, q, d, "lc_silo_", sv, wv, keep=keep, edit=edit, extra=extra, valve_anchor=pf["anchor"], exact=True)
        # the rocket, back in the shaft as it stands in Episode Two (the owner, 22 November: "we could use the rocket in that silo
        # after all ... can we please re-insert the rocket into the silo as it exists in EP2?"): valve_ep2_rocket, Valve's own
        # stages, engines, nose and hatch, in the silo's frame. Its engines end 6 over the pit's cover (322).
        # (since 24 November it stands on the launch's train and rises out of the open silo when launched: map_launch.py's
        #  launch(), all of it, the stages and engines under the pit's floor too)
        # the Resistance flag's pole (the owner: raised "from the bottom of the silo" with the flag "flush with eye level on the
        # top floor"; 22 November, with the rocket back on the axis: "just move the flagpole between the rocket and the walkways
        # in the silo somewhere for now"): between the rocket (97 from the axis) and the solid ring's hole (159), 128 out, half
        # way between two of the five columns (7 and 67 degrees round, 135 out), away from the hatch's side; its foot on the
        # pit's cover, its _top marker 120 over the gantry's floor, straight above
        hx, hy = self.HQ_AT
        v.point("info_target", tuple(pf_point([hx, hy, self.HQ_FOOT], q, d)), {"targetname": "lc_hq_setup_silo", "spawnflags": "0"}, wv)
        v.point("info_target", tuple(pf_point([hx, hy, self.HQ_TOP], q, d)), {"targetname": "lc_hq_setup_silo_top", "spawnflags": "0"}, wv)
        v.point("info_target", (ax, ay, az + self.REBEL_ZONE[1]), {"targetname": self.REBEL_ZONE[0], "spawnflags": "0"}, wv)
        # the playable silo (map_silo.py): the pit covered, level B's doors, the ring halls dressed, the shuttered windows
        # from level B's quarters onto the rocket, the lift's shaft shut at levels A and B, the leader's office
        # (with Valve's lever wall moved inside) and bedroom, the bottom level's fence gate, light where rooms had none,
        # the silo's soundscapes, and the leader's way out
        # the silo cut to its top floor (the owner, 23 November: "delete the entire silo EXCEPT the top floor. The lift has to
        # be deleted, the moving floor grates where the lift comes up, the resistance leader's office, the escape tunnel,
        # and the secret escape cave and all of that"): the pit's wall's gap shut and the top floor's two holes floored
        # (halls_shut), its soundscapes; the office, bedroom, lever, fence gate, lift's shaft, lamps and the leader's way
        # out (map_silo.py) are no longer placed
        ms = MS.Silo(self, d)
        ms.halls_shut(pf)
        # the leader's office and bedroom back, on the top floor across the shaft from the corridor, with the lab lever and
        # his way out (the owner, 24 November: map_silo.py's OFFICE_BOX and WAY_*)
        added = {"office": ms.office_room(pf), "way in": ms.vestibule(pf), "lever": ms.lever_box(pf), "bedroom": ms.bedroom(), "way out": ms.way_out()}
        ms.office()
        ms.soundscapes()
        self.silo_door()
        self.notes.append("the leader's office (Valve's lab room and its lever, lifted onto the top floor across the shaft from the corridor) and bedroom; brushes and "
                          "sides added: " + ", ".join("%s %d (%d)" % (k, b, s_) for k, (b, s_) in added.items()))
        self.notes.append("the silo: its top floor only, over a dark pit %d deep with the rocket's top in it; %d nodraw faces players see finished" % (1408 - self.SILO_PIT, finished))
        for dz in (1408 + 64,):
            v.point("env_cubemap", (ax, ay + 200, az + dz), {"cubemapsize": "0"}, sv)
        # player clips in the shaft round the rocket: over the solid ring's hole (159), the ring slab's grate's hole (114) and
        # inside the gantry's grates (112 to 159), each a 12-sided column round the axis. At the gantry the walkway up to the
        # rocket's hatch (Valve's stair from the gantry's floor, its landing and the platform by the hatch: MS.WALKWAY) is
        # left out of it (the owner, 22 November: "the steps are blocked near the top"): the column there is three pieces
        # round it; the walkway has its own rails, and no gap beside it a player could fall through.
        cv, clip = self.vis("silo's player clips (the empty shaft)"), "tools/toolsplayerclip"
        wx1, wy1, wx2, wy2 = MS.WALKWAY
        for r, z1, z2 in ((140, 1408, 1760),):      # (the gantry's: the levels under it are cut away)
            pts = [(ax + int(round(r * math.cos(math.radians(15 + 30 * k)))), ay + int(round(r * math.sin(math.radians(15 + 30 * k))))) for k in range(12)]
            polys = [pts]
            if z1 >= 1408:       # (the piece's x is the map's y, its y the map's -x: the walkway is map x ax-wy2..ax-wy1, y ay+wx1..ay+wx2)
                near = MS.clip_poly(pts, 1, 0, ax - wy1)           # (piece y >= wy1, map x <= ax - wy1: the walkway's side of that line)
                polys = [MS.clip_poly(pts, -1, 0, -(ax - wy1)), MS.clip_poly(near, 0, 1, ay + wx1) if near else None, MS.clip_poly(near, 0, -1, -(ay + wx2)) if near else None]
            for poly in polys:
                if not poly:
                    continue
                faces = [([(x, y, az + z2) for x, y in poly], clip), ([(x, y, az + z1) for x, y in reversed(poly)], clip)]
                for k in range(len(poly)):
                    (xa, ya), (xb, yb) = poly[k], poly[(k + 1) % len(poly)]
                    faces.append(([(xa, ya, az + z1), (xb, yb, az + z1), (xb, yb, az + z2), (xa, ya, az + z2)], clip))
                v.world.append(v.convex_text(faces, cv))
        # the hull: the piece's box (1088 square, 1856 high) walled in, 64 thick; its lid as high as the corridor's roof
        T, nd, cw, hv = 64, MAT["nodraw"], FMAT["silo_wall"], self.vis("silo's hull (sealed)")
        # (its floor a level under the pit's black floor, so the rocket's third stage, which rises through that floor, stands
        #  in sealed air: its origin may not be outside the map)
        x1, y1, z1, x2, y2, z2 = ax - 544, ay - 544, az + self.HULL_FLOOR, ax + 544, ay + 544, az + 1792
        roof = self.zd + 224
        # (carried out north round the leader's office and bedroom since 24 November: its north wall is their back wall)
        yn = ay + MS.OFFICE_HULL
        v.world_box((x1 - T, y1 - T, z1 - T, x2 + T, yn + T, z1), nd, vis=hv)
        # the pit's floor: black, so it has no bottom; detail, so the air under it is the map's (no pocket of its own)
        v.detail([(x1, y1, az + self.SILO_PIT - 16, x2, yn, az + self.SILO_PIT)], nd, top=MAT["black"], vis=hv)       # (under the office's too)
        v.world_box((x1 - T, ML.OUT[3], z2, x2 + T, yn + T, roof), nd, bottom=cw, vis=hv)       # (south of that the launch pad is its lid: map_launch.py)
        # its west wall, the bedroom's: cut round the hole the leader's way out leaves by (behind the secret panel), its
        # sides the hull's concrete, over it the tunnel's end wall (map_silo.py's WAY_*)
        wl, ww = MS.WAY_LOW, MS.WAY_MATS["wall"]
        hole = (MS.WAY_Y[0], MS.WAY_Y[1], wl, wl + MS.PANEL[2])
        for b, faces in zip(MS.split_box((x1 - T, y1, z1, x1, yn, z2), hole),
                            ({"east": cw, "north": cw}, {"east": cw, "south": cw}, {"east": cw, "top": cw}, {"east": cw, "bottom": cw, "west": ww})):
            v.world_box(b, nd, faces=faces, vis=hv)
        v.world_box((x2, y1, z1, x2 + T, yn, z2), nd, faces={"west": cw}, vis=hv)
        v.world_box((x1 - T, yn, z1, x2 + T, yn + T, z2), nd, faces={"south": cw}, vis=hv)
        cx1, cx2, cz = ax - 128, ax + 128, self.zg - 64      # (the corridor's end and its walls fill the south wall's middle)
        v.world_box((x1 - T, y1 - T, z1, cx1, y1, z2), nd, faces={"north": cw}, vis=hv)
        v.world_box((cx2, y1 - T, z1, x2 + T, y1, z2), nd, faces={"north": cw}, vis=hv)
        v.world_box((cx1, y1 - T, z1, cx2, y1, cz), nd, faces={"north": cw}, vis=hv)
        # the forest's north wall where the corridor passes: sky over its roof as the wall's, sealed under its floor
        lx1, lx2 = self.cuts["north"][0]
        sky, shv = MAT["sky"], self.vis("shell (sky, walls, slab)")
        v.world_box(self.box(lx1, self.D, roof, lx2, self.D + WALL, self.lid), sky, sky, sky, vis=shv)
        v.world_box(self.box(lx1, self.D, self.zg - 80, lx2, self.D + WALL, self.zd - 64), nd, vis=shv)
        lx1, lx2 = self.cuts["north"][2]
        v.world_box(self.box(lx1, self.D, roof, lx2, self.D + WALL, self.lid), sky, sky, sky, vis=shv)
        v.world_box(self.box(lx1, self.D, self.zb, lx2, self.D + WALL, self.zd - 64), nd, vis=shv)

    def lift(self):
        """The silo's lift, in the piece's frame (named as the piece's: lc_silo_...), as entities for pf_entities. The owner,
        21 November: it starts at the top, "can go to any floor it is called to", each floor's gate shut while the lift is
        elsewhere, a re-usable call button at each floor, and in the car "two different PROPER PROP buttons, one on top of
        the other, and one goes up a floor and the other goes down a floor". Since 23 November it stops only at the bottom
        level and the walkway (LIFT_STOPS: "program the lift to only go to the top and bottom floors"), so up and down
        each send it to the other end, past the shut levels A and B.
        How it works: Valve's car (lift_2, a func_tracktrain) runs on a path point per stop (lift_stop_N, N counted from
        the bottom; forward is down). A trip to stop N enables every point but the one just past N in the way it goes, so
        the car's path ends at N: it stops exactly there and the point's OnPass fires lift_arrive_N, the only arrival relay
        enabled for that trip (a point passed on the way fires its own, which is off). Which way to go: lift_cmp_N (a
        logic_compare holding the stop the car is at, set on every arrival) against N. While it moves every call relay
        and the car's buttons are off, so a press then does nothing. It sets off only when nobody stands in its doorway
        (a trigger on the car, between its gate and the landing's: lift_clear_dn / _up wait until it is clear). Every
        path point has a speed (a train going backward misbehaves on points whose speed is 0: Valve's wiki), and the one
        under the top starts disabled, so the car stays at the top when the map starts. It does no crush damage, and the
        gates (sliding func_buttons only the wiring moves) stop against whoever is in their way. Its top stop is the walkway
        into the silo, where the car stands with both ends open and two grates cover the hole when it is gone (the end of
        this method)."""
        stops, (lx, ly) = self.LIFT_STOPS, self.LIFT_XY
        n, top = len(stops), len(stops) - 1
        z0 = self.LIFT_BUILT     # (the car is built where Valve built it; it goes to its first path point, the top, as the map starts)
        zt = stops[top]          # (the walkway)
        hx1, hy1, hx2, hy2 = self.LIFT_HOLE
        out = []
        spots = iter([(-520 + 16 * (i % 5), -48 + 16 * ((i // 5) % 7), 1290 - 12 * (i // 35)) for i in range(1000)])

        def box(x1, y1, z1, x2, y2, z2, mat):
            sides = []
            for f in FACE_ORDER:
                p = face_corners((x1, y1, z1, x2, y2, z2), f)
                u, w = FACE_AXES[f]
                sides.append({"plane": [list(c) for c in p[:3]], "verts": [list(c) for c in p], "material": mat.upper(), "uaxis": u, "vaxis": w, "lightmapscale": "16"})
            return sides

        def ent(cls, keys, outs=(), at=None, brush=None, more=()):
            e = {"classname": cls, "origin": list(at or next(spots)), "keys": keys, "out": list(outs)}
            if brush:
                e["brushes"] = [box(*brush)] + [box(*b) for b in more]
                e["origin"] = [(brush[0] + brush[3]) / 2.0, (brush[1] + brush[4]) / 2.0, (brush[2] + brush[5]) / 2.0]
            out.append(e)

        def relay(name, outs, off=False):
            ent("logic_relay", {"targetname": name, "StartDisabled": "1" if off else "0", "spawnflags": "0"}, outs)

        def button(name, foot, yaw, bb, outs, parent=None):
            # (Episode Two's mine lift button, freightelevatorbutton02, and round it an unseen func_button: as wall_button())
            pk = {"targetname": name + "_model", "model": "models/props_mining/freightelevatorbutton02.mdl", "angles": "0 %d 0" % yaw, "skin": "0", "solid": "0",
                  "DefaultAnim": "idleoff", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                  "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
                  "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}
            bk = {"targetname": name, "spawnflags": "1025", "wait": "1", "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "0", "health": "0", "rendermode": "10",
                  "renderamt": "0", "rendercolor": "255 255 255"}
            if parent:
                pk["parentname"] = bk["parentname"] = parent
            ent("prop_dynamic", pk, at=foot)
            ent("func_button", bk, [("OnPressed", name + "_model", "SetAnimation", "turn_ON", 0)] + list(outs), brush=tuple(bb) + (MAT["nodraw"],))

        for k, z in enumerate(stops):
            # its path point, top to bottom
            # (at the bottom the car stops 2 over the floor: its own floor's top and the floor under it were level, and
            # flickered: the owner, 22 November: "it's texture is clipping/flashing with the ground below it")
            ent("path_track", {"targetname": "lift_stop_%d" % k, "target": "lift_stop_%d" % (k - 1) if k else "", "speed": "40", "spawnflags": "1" if k == top - 1 else "0",
                               "orientationtype": "0", "angles": "0 0 0"}, [("OnPass", "lift_arrive_%d" % k, "Trigger", "", 0)], at=(lx, ly, z + (2 if k in (0, top) else 0)))
            # arriving: the gates open, the car's buttons and every call work again
            arrive = [("OnTrigger", "lift_arrive_%d" % k, "Disable", "", 0), ("OnTrigger", "lift_2", "Stop", "", 0), ("OnTrigger", "lift_cmp_*", "SetValue", str(k), 0),
                      ("OnTrigger", "lift_door_2_b", "PressIn", "", 1), ("OnTrigger", "prop_eledoor_4", "SetAnimation", "open", 1),
                      ("OnTrigger", "brush_pclip_lift_2", "Disable", "", 1), ("OnTrigger", "sprite_ele_2", "Color", "255 170 43", 1), ("OnTrigger", "lift_call_*", "Enable", "", 2)]
            # (at the walkway: both its ends open, nothing fences the hole; elsewhere: the landing's gate opens)
            arrive += ([("OnTrigger", "prop_eledoor_3", "SetAnimation", "open", 1), ("OnTrigger", "lift_fence", "Disable", "", 0),
                        ("OnTrigger", "lift_top_here", "SetValue", "1", 0)] if k == top else [("OnTrigger", "lift_gate_%d" % k, "PressIn", "", 1)])
            arrive += [("OnTrigger", "lift_up_from_%d" % k, "Enable", "", 2)] if k < top else []
            arrive += [("OnTrigger", "lift_dn_from_%d" % k, "Enable", "", 2)] if k > 0 else []
            relay("lift_arrive_%d" % k, arrive, off=k != top)
            # a call: which way, from the stop the car is at
            relay("lift_call_%d" % k, [("OnTrigger", "lift_cmp_%d" % k, "Compare", "", 0)])
            ent("logic_compare", {"targetname": "lift_cmp_%d" % k, "InitialValue": str(top), "CompareValue": str(k)},
                [("OnEqualTo", "lift_here_%d" % k, "Trigger", "", 0)] + ([("OnLessThan", "lift_up_to_%d" % k, "Trigger", "", 0)] if k > 0 else [])
                + ([("OnGreaterThan", "lift_dn_to_%d" % k, "Trigger", "", 0)] if k < top else []))
            relay("lift_here_%d" % k, ([("OnTrigger", "prop_eledoor_3", "SetAnimation", "open", 0)] if k == top else [("OnTrigger", "lift_gate_%d" % k, "PressIn", "", 0)])
                  + [("OnTrigger", "lift_door_2_b", "PressIn", "", 0)])
            # setting off: everything off, the path ends at this stop, the gates shut, then it goes once the doorway is clear
            for name, past, branch in (("lift_dn_to_%d" % k, k - 1, "lift_clear_dn"), ("lift_up_to_%d" % k, k + 1, "lift_clear_up")):
                if (branch == "lift_clear_dn" and k == top) or (branch == "lift_clear_up" and k == 0):
                    continue
                go = [("OnTrigger", "lift_call_*", "Disable", "", 0), ("OnTrigger", "lift_up_from_*", "Disable", "", 0), ("OnTrigger", "lift_dn_from_*", "Disable", "", 0),
                      ("OnTrigger", "lift_stop_*", "EnablePath", "", 0), ("OnTrigger", "lift_arrive_%d" % k, "Enable", "", 0)]
                go += [("OnTrigger", "lift_stop_%d" % past, "DisablePath", "", 0.1)] if 0 <= past <= top else []
                go += [("OnTrigger", "lift_gate_*", "PressOut", "", 0), ("OnTrigger", "lift_door_2_b", "PressOut", "", 0), ("OnTrigger", "prop_eledoor_4", "SetAnimation", "close", 0),
                       ("OnTrigger", "prop_eledoor_3", "SetAnimation", "close", 0), ("OnTrigger", "sprite_ele_2", "Color", "255 10 10", 0),
                       ("OnTrigger", "sound_elevator_startup_1", "PlaySound", "", 0), ("OnTrigger", "sound_elevator_startup_1", "StopSound", "", 2.2)]
                # (up to the walkway: first nobody on the grates, then the hole fenced and the grates away, then the car)
                go += [("OnTrigger", "lift_hole_clear", "Test", "", 0.5)] if k == top else [("OnTrigger", branch, "Test", "", 2)]
                relay(name, go)
            if k == top:
                # the walkway's call button: on the face of the walkway's end frame toward the gantry, north of the opening,
                # pressed from the gantry's bridge, never from the grates (the owner, 22 November: "hitting the call button
                # on the top floor doesn't work because the floor bridge has to open first"; a press from the grates waited
                # for them to be clear, so it never came) and far from the silo door's keypad
                bx_, by_ = self.LIFT_CALL_TOP
                button("lift_button_%d" % k, (bx_, by_, z + 40), 0, (bx_ - 1, by_ - 1, z + 39, bx_ + 6, by_ + 9, z + 61), [("OnPressed", "lift_call_%d" % k, "Trigger", "", 0)])
            else:
                # the floor's gate: two leaves of sliding grating across the landing (72 each), 40 aside into the jambs to open
                for y1, y2, way in ((0, 72, 90), (-72, 0, 270)):
                    ent("func_button", {"targetname": "lift_gate_%d" % k, "movedir": "0 %d 0" % way, "speed": "50", "lip": "32", "wait": "-1", "spawnflags": "0", "sounds": "0",
                                        "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"}, brush=(-390, y1, z, -388, y2, z + 112, "metal/metalgate001a"))
                # the floor's call button, on the landing's side of the gate's jamb, facing the landing
                fx = -384 if z == 320 else -383      # (the bottom level's jamb; the grating panels' face above)
                button("lift_button_%d" % k, (fx, 78, z + 40), 0, (fx - 1, 77, z + 39, fx + 6, 87, z + 61), [("OnPressed", "lift_call_%d" % k, "Trigger", "", 0)])
            # what the car's own buttons do at this stop
            if k < top:
                relay("lift_up_from_%d" % k, [("OnTrigger", "lift_call_%d" % (k + 1), "Trigger", "", 0)], off=True)
            if k > 0:
                relay("lift_dn_from_%d" % k, [("OnTrigger", "lift_call_%d" % (k - 1), "Trigger", "", 0)], off=True)
        for branch, way in (("lift_clear_dn", "StartForward"), ("lift_clear_up", "StartBackward")):
            ent("logic_branch", {"targetname": branch, "InitialValue": "0"},
                [("OnFalse", "lift_2", way, "", 0), ("OnFalse", "brush_pclip_lift_2", "Enable", "", 0), ("OnTrue", branch, "Test", "", 1)]
                + ([("OnFalse", "lift_top_here", "Test", "", 0)] if way == "StartForward" else []))
        # the car's doorway, between its gate and the landing's: somebody there holds it; at the walkway also its back and
        # the floor beside it (so nobody stands where the fence round the hole goes up as it leaves)
        ent("trigger_multiple", {"targetname": "lift_doorway", "parentname": "lift_2", "spawnflags": "1", "wait": "0.1", "StartDisabled": "0"},
            [("OnStartTouchAll", "lift_clear_*", "SetValue", "1", 0), ("OnEndTouchAll", "lift_clear_*", "SetValue", "0", 0)], brush=(-419, -40, z0, -391, 40, z0 + 72, MAT["trigger"]),
            more=[(-584, -104, z0, -536, 104, z0 + 72, MAT["trigger"]), (-536, 62, z0, -391, 96, z0 + 72, MAT["trigger"]), (-536, -96, z0, -391, -62, z0 + 72, MAT["trigger"])])
        # -- the walkway at the top. With the car there, it stands in the walkway, both ends open: walk through it or ride it.
        # Leaving, the hole is fenced (an unseen clip on its edges) and once the car's roof is under the floor two grates
        # (Valve's metalgrate014a on its hull steel, as the walkway's own grates) slide in from under the walkway's sides and
        # make the floor whole, and the fence goes. Called back, it waits until nobody stands on the grates, fences the
        # hole, slides them away, and only then rises. Nothing closes on anyone: the grates move only over an empty hole. --
        ent("logic_branch", {"targetname": "lift_top_here", "InitialValue": "1"}, [("OnTrue", "lift_leave_top", "Trigger", "", 0)])
        shut = self.GRATE_AFTER + float(hy2) / self.GRATE_SPEED
        relay("lift_leave_top", [("OnTrigger", "lift_top_here", "SetValue", "0", 0), ("OnTrigger", "lift_fence", "Enable", "", 0),
                                 ("OnTrigger", "lift_grates", "PressIn", "", self.GRATE_AFTER), ("OnTrigger", "lift_grates_sound", "PlaySound", "", self.GRATE_AFTER),
                                 ("OnTrigger", "lift_fence", "Disable", "", round(shut + 0.5, 2))])
        ent("logic_branch", {"targetname": "lift_hole_clear", "InitialValue": "0"},
            [("OnFalse", "lift_open_top", "Trigger", "", 0), ("OnTrue", "lift_hole_clear", "Test", "", 1)])
        relay("lift_open_top", [("OnTrigger", "lift_fence", "Enable", "", 0), ("OnTrigger", "lift_grates", "PressOut", "", 0),
                                ("OnTrigger", "lift_grates_sound", "PlaySound", "", 0), ("OnTrigger", "lift_clear_up", "Test", "", 2)])
        ent("trigger_multiple", {"targetname": "lift_hole", "spawnflags": "1", "wait": "0.1", "StartDisabled": "0"},
            [("OnStartTouchAll", "lift_hole_clear", "SetValue", "1", 0), ("OnEndTouchAll", "lift_hole_clear", "SetValue", "0", 0)],
            brush=(hx1, hy1, zt - 1, hx2, hy2, zt + 72, MAT["trigger"]))
        ent("func_brush", {"targetname": "lift_fence", "StartDisabled": "1", "Solidity": "0", "spawnflags": "2", "solidbsp": "0", "rendermode": "10", "renderamt": "255",
                           "rendercolor": "255 255 255", "disableshadows": "1", "disablereceiveshadows": "0", "InputFilter": "0", "invert_exclusion": "0"}, [],
            brush=(hx1 - 2, hy1 - 2, zt, hx1, hy2 + 2, zt + 128, "tools/toolsplayerclip"),
            more=[(hx2, hy1 - 2, zt, hx2 + 2, hy2 + 2, zt + 128, "tools/toolsplayerclip"), (hx1, hy2, zt, hx2, hy2 + 2, zt + 128, "tools/toolsplayerclip"),
                  (hx1, hy1 - 2, zt, hx2, hy1, zt + 128, "tools/toolsplayerclip")])
        # the grates, made where they rest open: each 74 across and 130 long, in the walkway's floor each side, 1 under its
        # top, 2 of it standing out of the floor's side into the hole and 1 into the floor at each end; PressIn slides each
        # 70 over the hole (shut, they meet in the middle and reach 2 under the floor's sides), PressOut back. So no face of
        # theirs lies in a face of the floor's, open or shut (the owner, 22 November: "the little auto bridge on the first
        # floor is flickering through the sidewalls of the floor, can they just stick out a hair?")
        for ya, yb, way in ((hy2 - 2, hy2 + 72, 270), (hy1 - 72, hy1 + 2, 90)):
            g = box(hx1 - 1, ya, zt - 3, hx2 + 1, yb, zt - 1, "metal/metalhull003a")
            for side in g:
                if side["plane"][0][2] == side["plane"][1][2] == side["plane"][2][2]:
                    side["material"] = "METAL/METALGRATE014A"
            out.append({"classname": "func_button", "origin": [(hx1 + hx2) / 2.0, (ya + yb) / 2.0, zt - 2], "out": [], "brushes": [g],
                        "keys": {"targetname": "lift_grates", "movedir": "0 %d 0" % way, "speed": str(self.GRATE_SPEED), "lip": "4", "wait": "-1", "spawnflags": "0",
                                 "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"}})
        ent("ambient_generic", {"targetname": "lift_grates_sound", "message": "doors/gate_move1.wav", "health": "8", "pitch": "100", "pitchstart": "100",
                                "radius": "900", "spawnflags": "48"}, at=((hx1 + hx2) / 2.0, 0, zt + 16))
        # in the car, on the wall by its door: up a floor over down a floor
        button("lift_btn_up", (-426, 45, z0 + 50), 180, (-432, 36, z0 + 49, -425, 47, z0 + 71), [("OnPressed", "lift_up_from_*", "Trigger", "", 0)], parent="lift_2")
        button("lift_btn_dn", (-426, 45, z0 + 24), 180, (-432, 36, z0 + 23, -425, 47, z0 + 45), [("OnPressed", "lift_dn_from_*", "Trigger", "", 0)], parent="lift_2")
        # when the map starts: the car is at the top (the arrival there runs once, whichever comes first)
        ent("logic_auto", {"spawnflags": "1"}, [("OnMapSpawn", "lift_arrive_%d" % top, "Trigger", "", 1)])
        return out

    def preview_extra(self, dr, P):
        # the deep level, which is under the ground: drawn faintly, so the picture shows how far the bunker goes
        bx, by = self.B0
        for (i, j), spec in self.deep.cells.items():
            a, b = P(bx + i * CELL, by + (j + 1) * CELL), P(bx + (i + 1) * CELL, by + j * CELL)
            dr.rectangle((a[0], a[1], b[0], b[1]), fill=(150, 150, 156, 110) if spec[0] == "solid" else (30, 30, 36, 170))

    def pond(self):
        cx, cy, rx, ry = self.POND
        ix, iy, ir = self.ISLE
        rnd, n = self.rnd, 0
        # ferns and low shrubs round the shore (not the cattail model: it is made to be drawn at full brightness, and glows in the dark)
        for k in range(70):
            a = rnd.uniform(0, 6.283)
            for r in (1.04, 1.08, 1.12, 1.17):
                x, y = cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)
                h = self.natural(x, y)
                if self.level + 3 <= h <= self.level + 22:
                    self.static(rnd.choice(SHORE), x, y, h - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0)
                    n += 1
                    break
        top = self.natural(ix, iy)
        self.static("models/props_foliage/tree_pine04.mdl", ix, iy, top - 8, 40, "trees")
        # (the rock and the driftwood may be moved off the pine by settle(): the rock stays on the island, at its edge if
        #  need be, the driftwood in the shallows)
        self.static("models/props_foliage/forestrock_single01.mdl", ix + 46, iy - 30, self.natural(ix + 46, iy - 30) - 8, 120, "rocks, plants and fallen wood",
                    movable=(lambda x, y: self.natural(x, y) - 8, lambda x, y: math.hypot(x - ix, y - iy) <= 170 and self.natural(x, y) >= self.level - 12))
        self.static("models/props_foliage/driftwood_01a.mdl", cx - rx * 0.86, cy + ry * 0.35, self.level - 2, 70, "rocks, plants and fallen wood",
                    movable=(lambda x, y: self.level - 2, lambda x, y: self.level - 30 <= self.natural(x, y) <= self.level - 4))
        self.trees.append((ix, iy))
        self.vmf.point("env_cubemap", self.w(cx, cy - 200, self.level + 64), {"cubemapsize": "0"}, self.vis("water"))
        self.notes.append("the pond: about %d by %d, surface z %d, up to %d deep; the island's top is %d above the water; %d ferns and shrubs on the shore" % (
            2 * rx, 2 * ry, self.level, self.level - min(self.natural(cx + dx, cy + dy) for dx in (-200, 0, 200) for dy in (-150, 150)), top - self.level, n))


def forest_bunker(args):
    f = BunkerForest("forest (bunker, pond)", tuple(args.origin or (8064, 1088)), 400 if args.floor is None else args.floor, 31, args.first_node or 4400, ("west", 3072))
    f.test = bool(getattr(args, "test", False))
    f.setup()
    f.shell()
    f.ground()
    f.water()
    f.bunker()
    f.plant(leafy_near=(f.POND[0], f.POND[1], 1100))
    f.pond()
    f.settle()
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
    return f.vmf, f.problems


# ---------------------------------------------------------------------------
# The cave, and the stream that runs out of it
# ---------------------------------------------------------------------------

def old_nest_draws(rnd, L):
    """The random numbers the nest's first dressing (19 November) drew from the forest's generator, drawn again in the
    same order: the forest is planted after the cave, so its trees stay where the owner has seen them."""
    for k in range(7):
        rnd.randrange(0, 360, 15)
    for k in range(14):
        rnd.choice((rnd.uniform(620, 1150), rnd.uniform(1900, 2400)))
        rnd.uniform(-0.8, 0.8)
        rnd.randrange(0, 360, 15)
    for k in range(9):
        rnd.choice((rnd.uniform(620, 1150), rnd.uniform(1900, 2400)))
        rnd.uniform(1.2, 1.9)
        rnd.choice((1, 2, 3, 4, 5))
        rnd.randrange(0, 360, 15)
    for k in range(5):
        rnd.choice((1, 2))
        rnd.randrange(0, 360, 15)
    for q in range(420, L - 120, 110):
        rnd.uniform(0.75, 0.95)
        rnd.randrange(0, 360, 15)


class CaveForest(Forest):
    SHORE_MUD = False                   # (the stream's banks are dirt by their own rule)
    CX, YM, LONG = 2304, 2560, 3072     # the mouth's middle, the hillside's line, how far in it goes (to the forest's north wall: the emergency door)
    # The bend (the owner: "it's a straight shot still; can it curve ... so a combine unit can't just slaughter everyone
    # inside if they are standing outside"): straight in for 768, then over the next 768 the passage moves 960 west, then
    # straight on. sight() measures how far a straight line from outside the mouth reaches; it must stop short of the chamber.
    BEND = (768, 1536, -960)
    CHAMBER = (1728, 2368)              # past the bend: where the passage widens (the mine office stood here; it is gone, the big room is beyond the north wall)
    REBEL_ZONE = ("lc_zone_rebel_r720_h420_cave", 8)   # the territory over the office and the chamber before it (a base can be raised there)
    OFFICE = (1792, 2304)               # the office's front, along the chamber's east wall (two of the skin's 256 pieces)
    FRONT, FRONT_HIGH = 256, 192        # that front: this far east of the chamber's middle, and this high
    SPRING = 2624                       # how far in the spring is: a low slot in the west wall the stream runs out of
    HALF, TALL = 160, 320               # the square the cave's skin is hung on
    TEAR = 640                          # the hillside is cut this far each side of the mouth
    NEST_WARNING = 11                   # seconds from opening the emergency door to the first antlions: the alarm at the first mouth beyond it sounds meanwhile
    MOUTH_CLEAR = (200, 450, 120)       # kept clear before the cave's mouth: this far either side of its middle, out from it, and in past its fence
    BULK_T = 256                        # the emergency door's bulkhead is this thick (the holdout's gallery walls run 208 into it)
    GALLERY_Y = -10064                  # (Valve's y) the holdout's gallery's clear middle, where the emergency door is (the timber along its south wall clear of it)
    LIFT_SPEED = 64                     # the holdout's lift: 19 s from the top landing to the floor (Valve's goes at 35, and 20 near the ends)

    def setup(self):
        z0 = self.z0
        self.zf = z0 + 30                # the cave's floor and the ground before it
        self.level = self.zf - 16        # the stream's surface
        cx, ym = self.CX, self.YM
        self.D = 5632                    # (1536 longer than a forest usually is: the cave runs on north under its hill)
        self.front_x = cx + self.BEND[2] + self.FRONT
        self.end_x = cx + self.BEND[2]                                  # the passage's middle where it ends, at the emergency door
        self.cuts["north"] = (self.end_x - 640, self.end_x + 640)       # the bulkhead that door is in
        self.joints = []                 # (what, a box in the world, points in its air): joints_check() looks there for nodraw faces in view
        self.valve_props = set()         # (which of vmf.props came with Valve's pieces: placed as Valve placed them)
        self.bulk_x = self.room_pt(0, -1792, 0)[0] + 48      # the emergency door's bulkhead: its east face, 48 inside the big room's cut lobe
        self.door_y = self.room_pt(456, 0, 0)[1]             # the door's middle (on the lobe's open floor)
        self.deep_x = self.bulk_x - self.BULK_T + 48         # the holdout's gallery is cut here, 48 inside the bulkhead's west face
        self.office_plan()
        self.hull = []                   # what lies behind the emergency door, each part's reach (x1 y1 z1 x2 y2 z2): nest() shuts them all in one box
        # the spring: where the west wall meets the floor. The slot runs 140 back into the rock from the wall's lip.
        ys = ym + self.SPRING
        self.lip_theta = math.atan2(80 - self.TALL / 2.0, -self.HALF)
        lip = self.wall_x(self.lip_theta, ys)
        self.spring = (lip - 140, ys)
        self.sink = (3560, 1280)
        inside = [(self.stream_x(ym + q), ym + q) for q in range(self.SPRING - 200, 100, -150)]
        self.cave_line = [(lip - 130, ys), (lip + 30, ys)] + curve([(lip + 30, ys)] + inside + [(cx - 60, ym)])
        self.stream_line = self.cave_line + curve([(cx - 60, ym), (cx + 60, 2230), (cx - 160, 1860), (2520, 1520), (3080, 1390), self.sink])[1:]
        # the trail from the gate to the mouth (it fords the stream just before the cave)
        side, g = self.gate
        if side == "east":
            trail = [(self.W, g + GATE_WIDE / 2), (3576, g + GATE_WIDE / 2), (3000, 800), (2420, 1130), (2040, 1520)]
        else:
            trail = [(g + GATE_WIDE / 2, 0), (g + GATE_WIDE / 2, 520), (900, 1120), (1640, 1660)]
        self.trails.append(curve(trail + [(2100, 1890), (2390, 2280), (cx + 40, ym)]))
        self.clearings += [(cx, ym - 260, 330), (self.sink[0], self.sink[1], 200)]
        deep = 48
        seen = set()
        for (x, y) in self.stream_line + [(self.sink[0] + dx, self.sink[1] + dy) for dx in (-150, 150) for dy in (-150, 150)]:
            for dx in (-100, 100):
                for dy in (-100, 100):
                    key = (int((x + dx) // PATCH), int((y + dy) // PATCH))
                    if key not in seen and 0 <= key[0] < self.W // PATCH and 0 <= key[1] < self.D // PATCH:
                        seen.add(key)
                        self.waters.append((key[0] * PATCH, key[1] * PATCH, (key[0] + 1) * PATCH, (key[1] + 1) * PATCH, self.level, deep, FMAT["stream"]))
        self.wet_patches = seen
        r = self.office_rect
        for (x1, y1, x2, y2, level, deep, mat) in self.waters:
            if x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1]:
                self.problems.append("the stream's water (the patch at %d %d) lies under the mine office" % (x1, y1))

    def office_plan(self):
        """Where the mine office was (built no more: the owner, 22 November, had Ravenholm's big room put in its place,
        behind the north wall). Its plan is still worked out, only so the hill and the ground keep the shape the forest was
        planted on (natural() and ground() read it). It was (the owner: "a small mining office/shack on the inside ... a few
        rooms large; it still needs to be reasonably big enough for a small rebel base"): four rooms built into the rock behind the chamber's east wall. Its
        front is that wall: boards, a door and a window each side. u runs east from the front, v north.
        The rooms are ONE hollow in the plan; what divides them, and the front itself, are walls 8 thick (the owner, of the
        first try, whose walls were whole 64 squares: "can we make the walls a LOT thinner? they are like 3 feet thick")."""
        zf = self.zf
        wall, floor = FMAT["office_wall"], FMAT["office_floor"]
        self.office_at = (self.front_x, self.YM + self.OFFICE[0])       # in the forest's own coordinates
        plan = Plan((self.ox + self.office_at[0], self.oy + self.office_at[1]), [(zf - 64, zf + 224, wall)], floor_side=wall, ceiling=FMAT["office_ceiling"],
                    vis=self.vis("mine office"))
        plan.keep_out.append((-100000, -100000, 0, 100000))            # the cave: no wall is built out into it
        room = ("low", zf, floor, zf + 144)
        plan.paint((0, 0, 832, 512), room)                             # the front room, the bunk room and the store
        plan.paint((256, 512, 512, 768), room)                         # the back room
        plan.walls()
        # the walls 8 thick: (which way it runs, where it stands, from, to, its openings as (from, to, sill, head), is it the front)
        door, window = (zf, zf + 108), (zf + 48, zf + 112)
        self.office_walls = (
            ("v", 0, 0, 512, ((232, 280) + door, (64, 128) + window, (384, 448) + window), True),      # the front: a door, two windows
            ("v", 476, 0, 512, ((72, 120) + door, (392, 440) + door), False),                          # front room | bunk room, store
            ("u", 284, 484, 832, (), False),                                                           # bunk room | store
            ("u", 512, 256, 512, ((328, 376) + door,), False),                                         # front room | back room
        )
        self.office_holes = [(0, a, z1, 8, b, z2) for (a, b, z1, z2) in self.office_walls[0][4]]       # the front's openings
        self.office = plan
        self.rooms.append((plan, self.office_at))
        ax, ay = self.office_at
        self.office_rect = (ax - 64, ay - 64, ax + 896, ay + 832)

    # --- the ground ---------------------------------------------------------

    def stream_dist(self, x, y):
        return path_dist(x, y, self.stream_line)

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        zf, cx, ym = self.zf, self.CX, self.YM
        ds = self.stream_dist(x, y)
        dk = math.hypot(x - self.sink[0], y - self.sink[1])
        # the stream's valley: level ground along it
        h = lerp(h, zf + 5 * noise(x / 120.0, y / 120.0, self.seed + 7), 1 - smooth((min(ds, dk) - 120) / 300.0))
        # the hill the cave is in (it follows the cave round its bend, and covers the mine office), and the gully cut into its face
        back = y > ym or (y == ym and bias is not None and bias[1] > ym)
        mid = self.mid(y) if back else cx
        away = abs(x - mid)
        if back:
            away = min(away, rect_dist(x, y, self.office_rect))
        side = 1 - smooth((away - self.TEAR - 150 * (0.5 + 0.5 * noise(y / 330.0, 1.5 if x > mid else 8.5, self.seed + 15))) / (420.0 + 160 * noise(y / 500.0, 4.5, self.seed + 16)))
        if back:
            hill = zf + (640 + 120 * smooth((y - ym) / 500.0) + 24 * noise(x / 300.0, y / 300.0, self.seed + 8)) * side
            return max(h, hill)
        ax = abs(x - cx)
        gully = smooth((ax - 224 - 0.45 * (ym - y)) / 416.0)          # 0 on the gully's floor, 1 on the hill
        reach = 560 + 170 * noise(x / 420.0, 2.5, self.seed + 17) * smooth((ax - 300) / 300.0)
        front = zf + (640 + 24 * noise(x / 300.0, ym / 300.0, self.seed + 8)) * side * (1 - smooth((ym - y) / reach)) * gully
        h = max(h, front)
        if ax < 224 + 0.45 * (ym - y) and ym - y < 620:
            h = lerp(h, zf + 4 * noise(x / 90.0, y / 90.0, self.seed + 10), 1 - smooth((ym - y - 420) / 200.0))
        # the stream's bed and banks, and its sink; nothing else below the water in the patches the water is in
        lv = self.level
        bed = lv - 18 + 30 * smooth((ds - 30) / 56.0)
        if ds < 86:
            h = min(h, bed)
        if dk < 190:
            h = min(h, lv - 40 + 54 * smooth((dk - 60) / 130.0))
        if ds >= 86 and dk >= 190 and (int(x // PATCH), int(y // PATCH)) in self.wet_patches:
            h = max(h, lv + 8)
        return self.gate_pad(x, y, h)

    def free_edge_points(self):
        # the rock face's outer edge (67 points: it is buried in the hillside), the floor's front edge across the mouth
        # (7: it lies on the ground before the cave), and the cave's last ring, which ends in the wall it meets the big
        # room through (28)
        return 67 + 7 + 28

    def allowed_tears(self):
        return sum(1 for x in range(0, self.W + 1, STEP) if abs(x - self.CX) < self.TEAR and abs(self.natural(x, self.YM, (0, 0)) - self.natural(x, self.YM, (0, 9999))) > 0.01)

    def extra_dirt(self, x, y):
        a = 255 * (1 - smooth((self.stream_dist(x, y) - 40) / 70.0))
        if abs(x - self.CX) < 420 and 0 < self.YM - y < 520:
            a = max(a, 220)
        return a

    # --- the cave's skin ------------------------------------------------------

    def wander(self, y):
        """How far east of the mouth's middle the passage's middle is, y along it: none, then the bend, then all of it."""
        s1, s2, a = self.BEND
        return a * smooth((y - self.YM - s1) / float(s2 - s1))

    def mid(self, y):
        return self.CX + self.wander(y)

    def lean(self, y):
        """Where the passage runs aslant, its skin is hung this much wider across, so the passage itself keeps its width."""
        k = (self.wander(y + 4) - self.wander(y - 4)) / 8.0
        return math.sqrt(1 + k * k)

    def in_chamber(self, y):
        s = y - self.YM
        c1, c2 = self.CHAMBER
        return smooth((s - (c1 - 220)) / 220.0) * smooth((c2 + 220 - s) / 220.0)

    def stream_x(self, y):
        # (in the chamber the stream keeps to the west side: the floor before the office is dry)
        return self.mid(y) - 60 - 110 * self.in_chamber(y)

    def radius(self, y):
        s = y - self.YM
        s1, s2, a = self.BEND
        # tight at the mouth (the owner: "caves usually are not this huge at the entrance": it was 190 there), opening to 175
        # over the first 220; narrower through the bend (that is what stops a line of sight), wide in the chamber, a little
        # wider at the spring, and wide again at the end, where the cave meets the big room (the chamber that held the mine
        # office is only a widening now: the owner, 22 November, had Ravenholm's big room put in its place, behind the north wall)
        return (175 - 35 * (1 - smooth(s / 220.0)) - 15 * smooth((s - (s1 - 150)) / 150.0) * smooth((s2 + 150 - s) / 150.0)
                + 60 * self.in_chamber(y) + 55 * smooth(1 - abs(s - self.SPRING) / 220.0) + 165 * smooth((s - (self.LONG - 400)) / 220.0))

    def cave_floor(self, x, y):
        zf = self.zf
        carve = 24 * (1 - smooth((path_dist(x, y, self.cave_line) - 14) / 44.0))
        s = y - self.YM
        inner = zf + 5 * noise(x / 80.0, y / 80.0, self.seed + 11) * smooth((self.LONG - s) / 96.0) - carve    # (level at the emergency door)
        if s < 96:
            # at the mouth the cave's floor IS the ground before it, so there is no step or crack on the threshold
            return lerp(self.natural(x, self.YM, (0, 0)), inner, smooth(s / 96.0))
        return inner

    def wall_x(self, theta, y):
        R = self.radius(y)
        r = R * (1 + 0.2 * noise(math.cos(theta) * 1.6 + y / 170.0, math.sin(theta) * 1.6 - y / 230.0, self.seed + 12))
        return self.mid(y) + 1.15 * r * math.cos(theta) * self.lean(y)

    def ring(self, theta, y):
        """A point of the cave's skin: round the passage by theta, y along it."""
        s = y - self.YM
        R = self.radius(y)
        r = R * (1 + 0.2 * noise(math.cos(theta) * 1.6 + y / 170.0, math.sin(theta) * 1.6 - y / 230.0, self.seed + 12))
        x = self.mid(y) + 1.15 * r * math.cos(theta) * self.lean(y)
        z = self.zf + 0.51 * R + 0.85 * r * math.sin(theta)
        z = max(z, self.cave_floor(x, y))
        edge = smooth(s / 64.0) * smooth((self.LONG - s) / 64.0)
        if s >= self.LONG:
            return (x, self.YM + self.LONG + 6, z)       # the last ring ends 6 inside the emergency door's bulkhead
        return (x, y + 14 * edge * noise(theta * 2.0 + 3, y / 90.0, self.seed + 13), z)

    def on_square(self, xn, zn, y):
        """A point of the square the skin hangs on (xn across from the middle, zn up from the floor), moved onto the skin."""
        p = self.ring(math.atan2(zn - self.TALL / 2.0, xn), y)
        if xn == -self.HALF and zn <= 80:
            # the spring (the owner: "a little underground spring in the cave wall that is too short for the player to crouch
            # into"): the west wall's three lowest rows of points are pulled into a slot. The floor's edge goes to the slot's
            # back, low; the next row to the back, 30 higher; the third stays at the wall as the slot's lip. So the slot is
            # 140 deep and 30 from floor to roof at its mouth (a crouched player is 36), with the water standing 6 deep in it.
            w = smooth(1 - abs(y - (self.YM + self.SPRING)) / 72.0)
            if w > 0:
                lip = self.wall_x(self.lip_theta, y)
                zf = self.zf
                q = (lip, y, zf + 8) if zn == 80 else (lip - 140, y, zf + 8) if zn == 40 else (lip - 140, y, zf - 22)
                p = tuple(lerp(p[k], q[k], w) for k in range(3))
        return p

    def collar(self, xn, zn):
        """The rock face round the mouth: the skin's own edge at the mouth, easing out to a rough wall that leans back."""
        H, T = self.HALF, self.TALL
        qx, qz = max(-H, min(H, xn)), max(0, min(T, zn))
        d = math.hypot(xn - qx, zn - qz)
        px, py, pz = self.on_square(qx, qz, self.YM)
        near = (px + (xn - qx), py, pz + (zn - qz))
        sd = self.seed
        # big shapes, small shapes, and rough ledges across it (the owner: it was "just a repeating tiled cave texture")
        crag = (24 + 62 * noise(xn / 260.0, zn / 210.0, sd + 14) + 26 * noise(xn / 85.0, zn / 85.0, sd + 18)
                + 18 * math.sin(zn / 55.0 + 3 * noise(xn / 300.0, 0.5, sd + 19)))
        far = (self.CX + xn + 14 * noise(xn / 120.0, zn / 120.0, sd + 20), self.YM - crag + 0.15 * zn, self.zf + zn - (24 * smooth(d / 100.0) if zn == 0 else 0))
        w = smooth(d / 200.0)
        return tuple(lerp(near[k], far[k], w) for k in range(3))

    def sight(self):
        """How far into the cave a straight line from outside reaches, seen from above. Any such line crosses the mouth's own
        line, so every start along the mouth and every direction is tried, against the passage at its widest (its waist)."""
        ym, step = self.YM, 16
        n = self.LONG // step
        west = [min(self.ring(math.pi + t, ym + i * step)[0] for t in (-0.4, 0, 0.4)) for i in range(n + 1)]
        east = [max(self.ring(t, ym + i * step)[0] for t in (-0.4, 0, 0.4)) for i in range(n + 1)]
        best = 0
        x0 = west[0] + 4
        while x0 < east[0]:
            for k in range(-250, 251):
                for i in range(1, n + 1):
                    x = x0 + k / 100.0 * i * step
                    if x < west[i] or x > east[i]:
                        break
                    if i * step > best:
                        best = i * step
            x0 += 16
        return best

    def cave(self):
        v, cx, ym, zf, H, T = self.vmf, self.CX, self.YM, self.zf, self.HALF, self.TALL
        vis, mat, nd = self.vis("cave"), FMAT["cave"], MAT["nodraw"]
        W = lambda p: self.w(p[0], p[1], p[2])

        def dirt_of(p):
            # dirt on the floor, rock on the walls and roof
            return 235 * (1 - smooth((p[2] - self.cave_floor(p[0], p[1]) - 6) / 34.0))

        def face(box, name, point, mat=mat, tex=0.25, dirt=dirt_of):
            pts = {}

            def target(i, j):
                pts[(i, j)] = point(i, j)
                return W(pts[(i, j)])

            def alpha(i, j):
                return dirt(pts[(i, j)])
            v.world_box(self.box(*box), nd, vis=vis, faces={name: mat}, disp={name: (3, target, alpha)}, tex=tex)

        def cliff_dirt(p):
            # dirt in the hollows and along the ledges, rock on what stands out
            return 110 + 120 * noise(p[0] / 150.0, p[2] / 110.0, self.seed + 21) + 70 * smooth(1 - (p[2] - zf) / 90.0)

        def under(y):
            # (the pieces the skin hangs on follow the bend, a whole square at a time)
            return cx + int(round(self.wander(y) / 64.0)) * 64
        seg = 256
        for k in range(self.LONG // seg):
            y0 = ym + k * seg
            c = under(y0 + seg / 2)
            face((c - H, y0, zf - 16, c + H, y0 + seg, zf), "top", lambda i, j, y0=y0: self.on_square(-H + 40 * j, 0, y0 + 32 * i))
            face((c - H, y0, zf + T, c + H, y0 + seg, zf + T + 16), "bottom", lambda i, j, y0=y0: self.on_square(-H + 40 * i, T, y0 + 32 * j))
            face((c - H - 16, y0, zf, c - H, y0 + seg, zf + T), "east", lambda i, j, y0=y0: self.on_square(-H, 40 * i, y0 + 32 * j))
            face((c + H, y0, zf, c + H + 16, y0 + seg, zf + T), "west", lambda i, j, y0=y0: self.on_square(H, 40 * j, y0 + 32 * i))
        # the rock face round the mouth: five pieces that share their edges with each other and with the cave's first ring
        for (x1, x2, z1, z2) in ((-608, -H, 0, T), (H, 608, 0, T), (-608, -H, T, 704), (-H, H, T, 704), (H, 608, T, 704)):
            face((cx + x1, ym - 16, zf + z1, cx + x2, ym, zf + z2), "south",
                 lambda i, j, x1=x1, x2=x2, z1=z1, z2=z2: self.collar(x1 + (x2 - x1) * j / 8.0, z1 + (z2 - z1) * i / 8.0), mat=FMAT["cliff"], tex=0.5, dirt=cliff_dirt)
        # light: daylight does the mouth; dim lights round the bend, more in the chamber, and the far end left to the spring's glow
        for (q, up, colour) in ((330, 150, "150 190 255 60"), (760, 130, "255 190 120 60"), (1180, 120, "255 180 110 50"), (1640, 170, "255 190 130 90"),
                                (2048, 250, "255 200 150 170"), (2600, 110, "140 180 255 50"), (2930, 300, "255 170 110 120")):
            y = ym + q
            v.point("light", self.w(self.mid(y), y, zf + up), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        for q in (1150, 2048):
            v.point("env_cubemap", self.w(self.mid(ym + q), ym + q, zf + 80), {"cubemapsize": "0"}, vis)
        # hanging rock in the bend and the chamber (there, over its west half: the roof comes down to the office's front on the east), fallen rock along the walls
        rnd = self.rnd
        for (q1, q2, n, t1, t2) in ((900, 1450, 6, 1.1, 2.0), (1760, 2340, 10, 1.6, 2.3)):
            for k in range(n):
                y = ym + rnd.uniform(q1, q2)
                p = self.ring(rnd.uniform(t1, t2), y)
                self.static("models/props_mining/stalactite_static0%d.mdl" % rnd.choice((1, 2)), p[0], p[1], p[2] - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        for (q, side) in ((200, 1), (520, -1), (900, 1), (1250, -1), (1630, 1), (1900, -1), (2200, -1), (2480, 1), (2700, -1), (2790, 1)):
            y = ym + q
            p = self.ring(-0.5 if side > 0 else math.pi + 0.5, y)
            self.static("models/props_mining/caverocks_cluster0%d.mdl" % rnd.choice((1, 2)), p[0] - 30 * side, p[1], self.cave_floor(p[0] - 30 * side, p[1]) - 6, rnd.randrange(0, 360, 15), "cave", fade=(-1, 0))
        # the rock face, dressed: boulders heaped along its foot and against it, ferns and bushes among them
        dress = ((-300, 70, "models/cliffs/rocks_medium01.mdl"), (290, 60, "models/cliffs/rocks_large03_veg.mdl"), (-520, 80, "models/cliffs/rocks_large01.mdl"),
                 (500, 70, "models/cliffs/rockcluster02.mdl"), (-410, 130, "models/props_foliage/forestrock_cluster01.mdl"), (380, 140, "models/props_foliage/forestrock_cluster02.mdl"),
                 (-250, 150, "models/props_foliage/forestrock_single01.mdl"), (255, 170, "models/props_wasteland/rockgranite02a.mdl"), (-600, 150, "models/cliffs/rocks_large02.mdl"),
                 (610, 130, "models/cliffs/rocks_large03.mdl"))
        # (the owner, 22 November, of the first compile: "you literally put a massive pile of boulders in front of the gate":
        #  rockcluster01, about 650 across, stood 290 from the mouth's middle: a smaller rock stands there now. Each boulder is pushed out sideways, by its
        #  own size turned by its yaw, until it is clear of the mouth's approach; the same random numbers are drawn)
        import map_assets
        mouth = self.MOUTH_CLEAR
        for (dx, out, model) in dress:
            yaw = rnd.randrange(0, 360, 15)
            b = map_assets.size(model) or (-32, -32, 0, 32, 32, 32)
            c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            ex = [x_ * c - y_ * sn for x_ in (b[0], b[3]) for y_ in (b[1], b[4])]
            ey = [x_ * sn + y_ * c for x_ in (b[0], b[3]) for y_ in (b[1], b[4])]
            step = 16 if dx >= 0 else -16
            while True:
                x, y = cx + dx, ym - out
                if x + max(ex) <= cx - mouth[0] or x + min(ex) >= cx + mouth[0] or y + min(ey) >= ym + mouth[2] or y + max(ey) <= ym - mouth[1]:
                    break
                dx += step
            self.static(model, x, y, self.natural(x, y) - 14, yaw, "cave")
        zf = self.zf
        self.keep_way_clear((cx - mouth[0], ym - mouth[1], zf - 40, cx + mouth[0], ym + mouth[2], zf + 110), "the cave's mouth and its fence gate")
        for k in range(16):
            dx = rnd.choice((-1, 1)) * rnd.uniform(235, 640)
            x, y = cx + dx, ym - rnd.uniform(40, 190)
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "cave", solid=0)
        self.fence_gate()
        old_nest_draws(rnd, 2560)        # (what the first nest drew from the forest's numbers: the trees stay where the owner has seen them)
        # beyond the cave's end, behind the forest's north wall (each part draws its own numbers, if any)
        self.north_joint()
        self.big_room()
        self.bulkhead()
        self.holdout()
        self.workings_hull()
        for q in range(64, self.LONG - 100, 192):
            y = ym + q
            x = self.mid(y) + 70
            self.node(x, y, self.cave_floor(x, y))
        tall = max(self.ring(math.pi / 2, ym + q)[2] for q in range(0, self.LONG, 32)) - zf
        mouth_w = self.ring(0, ym)[0] - self.ring(math.pi, ym)[0]
        mouth_h = self.ring(math.pi / 2, ym)[2] - zf
        cover = 1e9
        for q in range(0, self.LONG, 32):
            for t in (0.5, 1.0, math.pi / 2, math.pi - 1.0, math.pi - 0.5):
                p = self.ring(t, ym + q)
                cover = min(cover, self.natural(p[0], p[1], (0, 9999)) - p[2])
        if cover < 40:
            self.problems.append("the cave's roof comes within %d of the hill's surface" % cover)
        far = self.sight()
        if far > self.CHAMBER[0] - 128:
            self.problems.append("a straight line from outside the mouth reaches %d into the cave: into the chamber, which starts at %d" % (far, self.CHAMBER[0]))
        ys = ym + self.SPRING
        lip, back_top, back_low = self.on_square(-H, 80, ys), self.on_square(-H, 40, ys), self.on_square(-H, 0, ys)
        slot_high = lip[2] - back_low[2]
        if slot_high > 34:
            self.problems.append("the spring's slot is %d high: a crouched player (36) could get in" % slot_high)
        s1, s2, a = self.BEND
        self.notes.append("the cave: its mouth at (%d %d), floor z %d, about %d wide and %d high; it runs %d north, then bends %d %s over the next %d, then %d more north "
                          "to the emergency door (%d in all, up to %d high); at least %d of hill over its roof" % (
                              self.ox + cx, self.oy + ym, zf, mouth_w, mouth_h, s1, abs(a), "west" if a < 0 else "east", s2 - s1, self.LONG - s2, self.LONG, tall, cover))
        self.notes.append("line of sight: a straight line from anywhere outside the mouth reaches at most %d in; the widening past the bend begins %d in, the big room beyond the north wall %d in" % (far, self.CHAMBER[0], self.LONG))
        self.notes.append("the spring: a slot in the west wall at (%d %d), %d deep and %d from floor to roof (a crouched player is 36), the water %d deep in it" % (
            self.ox + lip[0], self.oy + ys, lip[0] - back_top[0], slot_high, self.level - back_low[2]))
        self.notes.append("the stream: surface z %d, from the spring, down the cave, out of the mouth, to a sink pool at (%d %d); a trail fords it" % (
            self.level, self.ox + self.sink[0], self.oy + self.sink[1]))
        self.joints_check()
        self.lamps_check()

    def skin(self, box, name, point, mat, vis, tex=0.25, dirt=None):
        """One displaced face of a skin: the face `name` of `box`, its points from point(i, j)."""
        pts = {}

        def target(i, j):
            pts[(i, j)] = point(i, j)
            return self.w(*pts[(i, j)])

        def alpha(i, j):
            return dirt(pts[(i, j)]) if dirt else 0
        self.vmf.world_box(self.box(*box), MAT["nodraw"], vis=vis, faces={name: mat}, disp={name: (3, target, alpha)}, tex=tex)

    # --- behind the forest's north wall ------------------------------------------------------------------------------
    # The owner, 22 November, of the first try behind the emergency door (the old mine, the shaft head, Ravenholm's big
    # cave, a lift, the lower workings, a generated hive): "every single connecting room has nodraw faces visible inwards
    # ... is it not possible to at the very least have little tunnels copy/pasted from EP2 that loop around and meet at the
    # other little tunnel entrances?"; what to build instead: "the mining tunnels from EP2 and the big mining room with the
    # big antlion/zombie fight (while waiting for the elevators) and then those connect down to the EP2 caves ... in a
    # linear fashion, one leads to the other. at the very end should be the antlion essence/extract"; and later that day,
    # of the chamber with the mine office: "replace that room with the big ravenholm mining room".
    # So, on from the cave: Ravenholm's big room (d1_town_04, lifted whole), the emergency door in a bulkhead across its
    # far lobe, then Episode Two's holdout (ep2_outland_03, lifted whole): its mine gallery to the top landing, the lift
    # down the pit to the holdout's floor, the antlion tunnels beyond that loop round, and the larval extract at their end.
    # Every cut of a Valve piece ends inside a wall of ours (its face 32 to 64 inside the kept tunnel); joints_check()
    # fails the build if a nodraw face shows near one.

    def room_pt(self, x, y, z):
        """A place in d1_town_04 (Valve's own coordinates) where it is in the forest's frame: the big room is turned three
        quarters (anticlockwise) so its mouth faces south, the mouth's cut 48 inside the forest's north wall."""
        return (self.end_x + (y + 640), self.D + WALL - 48 + (1536 - x), self.zf + (z + 5120))

    def deep_pt(self, x, y, z):
        """A place in ep2_outland_03 (Valve's own coordinates) in the forest's frame: not turned; the gallery's floor
        where it is cut sits 48 inside the emergency door's bulkhead, the door on the gallery's clear middle (GALLERY_Y,
        in line with the control room's doorway further in)."""
        return (x - 2848 + self.deep_x, y - self.GALLERY_Y + self.door_y, z + 576 + self.zf)

    def lifted(self, name, q, d, vis_w, vis_p, prefix, skip=None, keep=None, edit=None, extra=(), clip=None):
        """A piece lifted from Valve's maps (map_prefab.py), placed: its brushes (Valve's world brushes in the world), its
        props, lights and kept wiring. Everything behind the emergency door is underground in one shut box, so the sky is
        made black; and nothing of Valve's dev materials may be left in it. Returns the piece and its brushes' boxes."""
        pf = copy.deepcopy(PF.load(name))
        if clip is not None:
            pf["solids"] = [clip_x(sol, clip) or sol for sol in pf["solids"]]
        for sol in pf["solids"]:
            for sd in sol["sides"]:
                m = sd["material"].lower()
                if "toolsskybox" in m:
                    sd["material"] = MAT["black"].upper()
        boxes = pf_solids(self.vmf, pf, q, d, vis_w, world=True, skip=skip)
        bad = sorted(set(sd["material"].lower() for sol in pf["solids"] if not (skip and skip(sol)) for sd in sol["sides"]
                         if sd["material"].lower().startswith("dev/") or "toolsskybox" in sd["material"].lower()))
        if bad:
            self.problems.append("%s keeps materials a player must never see: %s" % (name, ", ".join(bad)))
        n0 = len(self.vmf.props)
        pf_entities(self.vmf, pf, q, d, prefix, vis_p, vis_p, keep=keep, edit=edit, extra=extra, valve_anchor=pf["anchor"])
        self.valve_props.update(range(n0, len(self.vmf.props)))
        return pf, boxes

    def north_joint(self):
        """Where the cave meets Ravenholm's big room: the stretch of the forest's north wall the cave ends in, a wall of
        Episode Two's mine concrete with a hole in it the size of the room's mouth passage. The cave's last ring ends 6
        inside its south face; Valve's passage runs 48 into its north face (its cut, and the cut faces of its brushes,
        are inside the wall)."""
        v, zf, D, T = self.vmf, self.zf, self.D, WALL
        x1, x2 = self.cuts["north"]
        top = zf + 704
        B = self.box
        sv = self.vis("shell (sky, walls, slab)")
        jm, fl = MINE_MAT["wall"], MINE_MAT["floor"]
        # the hole: inside the room's mouth passage where it is cut (Valve y -760 to -536, floor -5120, roof over -4890)
        hx1, hx2 = self.room_pt(0, -736, 0)[0], self.room_pt(0, -560, 0)[0]
        hz = 192
        self.joint_hole = (hx1, D, zf, hx2, D + T, zf + hz)
        v.world_box(B(x1, D, self.zb, hx1, D + T, top), jm, vis=sv)
        v.world_box(B(hx2, D, self.zb, x2, D + T, top), jm, vis=sv)
        v.world_box(B(hx1, D, zf + hz, hx2, D + T, top), jm, bottom=jm, vis=sv)
        v.world_box(B(hx1, D, self.zb, hx2, D + T, zf), jm, top=fl, vis=sv)
        v.world_box(B(x1, D, top, x2, D + T, self.lid), MAT["sky"], vis=sv)
        under = min(self.natural(x, D, (0, 0)) for x in range(x1, x2 + 1, 64)) - top
        if under < 8:
            self.problems.append("the wall the cave ends in stands %d out of the hill" % -under)
        # a timber frame round the hole, on the cave's side (Ravenholm's 16 by 16 timber)
        tb = FMAT["timber"]
        v.detail([B(hx1 - 16, D - 16, zf, hx1, D, zf + hz + 16), B(hx2, D - 16, zf, hx2 + 16, D, zf + hz + 16), B(hx1 - 16, D - 16, zf + hz, hx2 + 16, D, zf + hz + 16)], tb,
                 vis=self.vis("big room: the way in"))
        mid = (hx1 + hx2) / 2
        self.keep_way_clear((hx1 + 8, D - 160, zf + 8, hx2 - 8, D + T + 200, zf + 100), "the way from the cave into the big room")
        self.joints.append(("the hole from the cave into the big room", self.w(hx1 - 160, D - 128, zf - 64) + self.w(hx2 + 160, D + T + 160, zf + hz + 160)[0:3],
                            [self.w(mid, D - 64, zf + 64), self.w(mid, D + T + 96, zf + 64)]))

    def big_room(self):
        """Ravenholm's big mining room (the owner, 22 November: "replace that room with the big ravenholm mining room"):
        d1_town_04's headcrab cave lifted whole (valve_raven_big_room: its rock, the metal stairs up the shaft to the
        brick landing at its top, the timber), north of the forest's north wall, turned so its mouth passage runs south
        into the hole in that wall. Cut across its south lobe on Valve's grid, where the emergency door's bulkhead
        stands. A rebel headquarters can be raised in it (lc_hq_setup_cave, the territory marker), and the antlions from
        beyond the emergency door run to it (lc_nest_rally)."""
        v, zf = self.vmf, self.zf
        rv, rp = self.vis("big room (Ravenholm's, lifted from d1_town_04)"), self.vis("big room: lights and dressing")
        d = self.w(*self.room_pt(1536, -640, -5120))

        def skip(sol):
            if sol["from"].startswith(("func_physbox", "func_illusionary")):
                return True       # (Valve's loose boards, as slabs they would stand in the way; see-through things would be solid)
            pts = [c for sd in sol["sides"] for c in (sd["corners"] or sd["plane"])]
            # the passage behind the landing's door at the top of the shaft (it led on to the town): its doorway is walled up
            return all(-632 <= p[0] <= -330 and 1420 <= p[2] <= 2030 and -770 <= p[1] <= 650 for p in pts)

        def keep(e):
            cls, model = e["classname"], e["keys"].get("model", "")
            if e.get("ours"):
                return True
            if "fence03a" in model:
                return False      # (a fence across the mouth passage: the way in is through it here)
            if cls in ("prop_static", "prop_dynamic", "light", "light_spot", "infodecal", "env_sprite", "keyframe_rope", "move_rope", "point_spotlight"):
                return "explosive" not in model
            return cls == "prop_physics" and "explosive" not in model

        def edit(e):
            if e["classname"] in ("light", "light_spot"):
                e["keys"]["spawnflags"] = "0"
        pf, boxes = self.lifted("valve_raven_big_room", 3, d, rv, rp, "lc_room_", skip=skip, keep=keep, edit=edit)
        # two flights of the shaft's metal stairs are broken in Valve's own map (its stair check finds the same): the top
        # one stops in mid air where the stairs above collapsed, the bottom one hangs over the floor (its fallen catwalk,
        # a func_physbox, is left out); kept as Valve built them
        for (x1, y1, z1, x2, y2, z2), why in (((640, -1300, -4810, 744, -1230, -4730), "the shaft's top flight, ending where the stairs collapsed"),
                                              ((30, -730, -5010, 98, -630, -4930), "the shaft's bottom flight, hanging over the floor")):
            c1, c2 = self.room_pt(x1, y1, z1), self.room_pt(x2, y2, z2)
            v.stairs_as_valve(self.w(min(c1[0], c2[0]), min(c1[1], c2[1]), c1[2]) + self.w(max(c1[0], c2[0]), max(c1[1], c2[1]), c2[2]), why)
        # the landing's doorway at the top of the shaft, walled up in its own brick (the door and the passage beyond it left out)
        a = self.room_pt(888, -1280, -3648)      # (the doorway in the landing's plaster wall, 8 thick: filled flush with both its faces, its frame left round it)
        b = self.room_pt(896, -1232, -3540)
        pl = "plaster/plasterwall039c"
        v.world_box(self.box(min(a[0], b[0]), min(a[1], b[1]), a[2], max(a[0], b[0]), max(a[1], b[1]), b[2]), pl, top=pl, bottom=pl, vis=rv)
        c1, c2 = self.room_pt(760, -1400, -3680), self.room_pt(1040, -1100, -3480)
        self.joints.append(("the walled-up doorway at the top of the big room's shaft", self.w(min(c1[0], c2[0]), min(c1[1], c2[1]), c1[2]) + self.w(max(c1[0], c2[0]), max(c1[1], c2[1]), c2[2]),
                            [self.w(*self.room_pt(800, -1256, -3600))]))
        X1, Y1, Z1 = (min(bx[k] for bx in boxes) - self.ox * (k == 0) - self.oy * (k == 1) for k in range(3))
        X2, Y2, Z2 = (max(bx[k + 3] for bx in boxes) - self.ox * (k == 0) - self.oy * (k == 1) for k in range(3))
        self.room_reach = (X1, Y1, Z1, X2, Y2, Z2)
        # its own shut box (workings_hull): west, the bulkhead; south, the forest's north wall; the rest black
        self.room_box = (self.bulk_x - self.BULK_T, self.D + WALL, int(math.floor((Z1 - 16) / 16.0)) * 16,
                         int(math.ceil((X2 + 32) / 64.0)) * 64, int(math.ceil((Y2 + 32) / 64.0)) * 64, int(math.ceil((Z2 + 16) / 64.0)) * 64)
        if X1 < self.bulk_x - 48 - 1:
            self.problems.append("the big room reaches x %d, west of its cut (the bulkhead)" % (self.ox + X1))
        # its light: Valve's lamps came with it; a dim fill over the floor and at the mouth, as Valve's own cave is lit
        for (x, y, col) in ((1300, -650, "255 190 130 60"), (700, -800, "190 200 255 70"), (100, -1000, "255 200 150 90"), (400, -1500, "190 200 255 60")):
            p = self.room_pt(x, y, -4980)
            v.point("light", self.w(*p), {"_light": col, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("env_cubemap", self.w(*self.room_pt(400, -900, -5050)), {"cubemapsize": "0"}, rv)
        # a headquarters can be raised here (the owner, 22 November, of the cave: a flag and office spot, as the silo
        # has; moved here with the mine office's room): the pole's marker on the floor under the room's open height, and
        # the rebel territory over the room (map-placed territories, CORE.md: lc_zone_<kind>_r_h_)
        hq = self.room_pt(300, -800, -5120)
        v.point("info_target", self.w(hq[0], hq[1], hq[2] + 8), {"targetname": "lc_hq_setup_cave", "spawnflags": "0"}, rp)
        zc = self.room_pt(350, -950, -5120)
        v.point("info_target", self.w(zc[0], zc[1], zc[2] + 8), {"targetname": self.REBEL_ZONE[0], "spawnflags": "0"}, rp)
        ry = self.room_pt(500, -900, -5112)
        v.point("info_target", self.w(ry[0], ry[1], ry[2]), {"targetname": "lc_nest_rally", "angles": "0 0 0"},
                self.vis("antlion makers (delete if the gamemode is to send the antlions itself)"))
        for (x, y) in ((1450, -648), (1100, -650), (800, -700), (500, -900), (200, -1100), (450, -1350), (456, -1600)):
            p = self.room_pt(x, y, -5112)
            self.node(*p)
        # the ways across it: from its mouth to the floor, and from there to the emergency door
        m1, m2 = self.room_pt(1536, -720, -5112), self.room_pt(1150, -576, -5000)
        self.keep_way_clear((min(m1[0], m2[0]), min(m1[1], m2[1]), m1[2], max(m1[0], m2[0]), max(m1[1], m2[1]), m2[2]), "the big room's mouth passage")
        w1, w2 = self.room_pt(560, -1350, -5112), self.room_pt(380, -1792, -5000)
        self.keep_way_clear((min(w1[0], w2[0]), min(w1[1], w2[1]), w1[2], max(w1[0], w2[0]), max(w1[1], w2[1]), w2[2]), "the way through the big room to the emergency door")
        self.notes.append("the big room: Ravenholm's (d1_town_04, %d brushes, %d displaced faces, lifted whole), north of the forest's north wall at (%d %d), floor z %d; "
                          "its mouth passage meets the cave through a hole in that wall; the stairs up its shaft to the brick landing; the headquarters' marks in it" % (
                              len(pf["solids"]), sum(1 for sol in pf["solids"] for sd in sol["sides"] if sd.get("disp")), self.ox + self.end_x, self.oy + self.D + WALL, zf))

    def bulkhead(self):
        """The emergency door (the owner: "an emergency door that has sealed the rest of the cave off ... requires two buttons
        to be pushed simultaneously (within 1 second of each other) that cannot be pushed by a single person"): a concrete
        bulkhead across the big room's south lobe (the room's west side, as it is turned), a steel shutter in it that lifts
        into the wall, and a button on the bulkhead each side of it, 480 apart with a wall standing out between each and the
        door, so the way from one to the other is about 700: nobody presses both inside a second. Each press counts for
        one second (a math_counter); two at once work the door, open or shut. The shutter is a func_button used as a mover,
        as the bunker's leaves are. Nothing kills (it did until 22 November; the owner: "considering how dying in the
        gamemode means a new character, yes just shove, not kill"): as it comes down a shove (shove()) pushes whoever is
        under it out, into the room or out to the gallery, whichever side they stand. The bulkhead is the whole west wall
        of the room's box (it keeps the room and all behind the door apart, so its areaportal works): the room's rock runs
        48 into its east face, Episode Two's gallery 48 into its west face."""
        v, zf, T = self.vmf, self.zf, self.BULK_T
        fx, dy = self.bulk_x, self.door_y           # (its east face, the room's side; the door's middle)
        wx = fx - T                                  # (its west face, the gallery's side)
        high = 160
        B, W = self.box, self.w
        cw, steel, rib = MAT["canal_wall"], FMAT["door"], MAT["bars"]
        dv = self.vis("nest door (the shutter, the two buttons, the wiring)")
        sv = self.vis("hull behind the forest (black walls)")
        y1, y2, z1, z2 = self.room_box[1], self.room_box[4], self.room_box[2], self.room_box[5]
        v.world_box(B(wx, y1, z1, fx, dy - 96, z2), cw, vis=sv)
        v.world_box(B(wx, dy + 96, z1, fx, y2, z2), cw, vis=sv)
        v.world_box(B(wx, dy - 96, zf + high, fx, dy + 96, z2), cw, bottom=MAT["ceiling"], vis=sv)
        v.world_box(B(wx, dy - 96, z1, fx, dy + 96, zf), cw, top=FMAT["bunker_floor"], vis=sv)
        # a frame round the doorway on the room's side, and the two walls that stand out between the door and each button
        v.detail([B(fx, dy - 112, zf, fx + 8, dy - 96, zf + high + 16), B(fx, dy + 96, zf, fx + 8, dy + 112, zf + high + 16), B(fx, dy - 112, zf + high, fx + 8, dy + 112, zf + high + 16)],
                 MAT["beam"], vis=dv)
        v.detail([B(fx + 8, dy - 128, zf - 16, fx + 224, dy - 112, zf + 144), B(fx + 8, dy + 112, zf - 16, fx + 224, dy + 128, zf + 144)], cw, vis=dv)
        # the shutter, drawn shut, 44 inside the room's face; pressed in, it is up in the wall with 8 showing
        parts = [(B(fx - 68, dy - 96, zf, fx - 44, dy + 96, zf + high), steel)]
        for z in (20, 76, 132):
            parts.append((B(fx - 44, dy - 96, zf + z, fx - 40, dy + 96, zf + z + 8), rib))
            parts.append((B(fx - 72, dy - 96, zf + z, fx - 68, dy + 96, zf + z + 8), rib))
        v.brush_entity("func_button", {
            "targetname": "lc_nest_door", "movedir": "-90 0 0", "speed": "30", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
            "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "min_use_angle": "0.8",
            "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, parts, steel, dv)
        # nothing kills (shove()): in the last moments of the shut, whoever is under the shutter is pushed out from under
        # it, into the room on the room's side (harder: who stands in the middle goes there) and out to the gallery on
        # the gallery's side. A shutter coming down meets a standing head 72 up, 2.4 s before it is down, so its shove is
        # on from then (the wiring below), and the shutter is never left resting on anyone.
        shove(v, "lc_nest_shove", [(B(fx - 96, dy - 96, zf, fx - 56, dy + 96, zf + high), 180, 200), (B(fx - 56, dy - 96, zf, fx - 16, dy + 96, zf + high), 0, 300)], dv)
        # an areaportal in it, shut while it is: what lies beyond is not drawn, nor the room from there
        portal = B(fx - 57, dy - 96, zf, fx - 55, dy + 96, zf + high)      # (inside the shutter's own thickness: see the bunker's)
        v.portals.append(portal)
        v.brush_entity("func_areaportal", {"targetname": "lc_nest_portal", "StartOpen": "0", "PortalVersion": "1"}, [portal], MAT["portal"], dv)
        # the two buttons, each with a lamp that shows for the second its press counts
        for side, tag in ((-1, "a"), (1, "b")):
            uy = dy + side * 240
            v.point("env_sprite", W(fx + 10, uy, zf + 84), {"targetname": "lc_nest_lamp_" + tag, "model": "sprites/glow06.spr", "rendermode": "9", "renderamt": "255",
                                                             "rendercolor": "120 255 120", "scale": ".35", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                             "renderfx": "0", "spawnflags": "0"}, dv)
            wall_button(v, W(fx, uy - 4, zf + 44), 0, "lc_nest_button_" + tag, B(fx, uy - 10, zf + 40, fx + 10, uy + 10, zf + 68), dv,
                        [("OnPressed", "lc_nest_count", "Add", "1", 0), ("OnPressed", "lc_nest_count", "Subtract", "1", 1),
                         ("OnPressed", "lc_nest_lamp_" + tag, "ShowSprite", "", 0), ("OnPressed", "lc_nest_lamp_" + tag, "HideSprite", "", 1),
                         ("OnPressed", "lc_nest_blip", "PlaySound", "", 0)], "1.2")
        at = W(fx + 40, dy, zf + 120)

        def sound(name, message, pos, radius="2200", loops=False):
            v.point("ambient_generic", pos, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": radius,
                                             "spawnflags": "16" if loops else "48",
                                             "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                             "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        sound("lc_nest_blip", "Buttons.snd17", W(fx + 30, dy, zf + 60), "700")
        sound("lc_nest_alarm", "ambient/alarms/klaxon1.wav", W(fx + 60, dy, zf + 200))
        sound("lc_nest_move", "Streetwar.d3_c17_11_garage_move1", at, loops=True)
        sound("lc_nest_slam", "Streetwar.d3_c17_11_garage_stop1", at)
        v.point("light", W(fx + 70, dy, zf + 190), {"targetname": "lc_nest_light", "_light": "255 50 30 300", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                                     "style": "0"}, dv)
        v.point("env_shake", at, {"targetname": "lc_nest_shake", "amplitude": "6", "radius": "900", "duration": "1.4", "frequency": "40", "spawnflags": "0"}, dv)
        v.point("math_counter", W(fx + 30, dy, zf + 110), {"targetname": "lc_nest_count", "startvalue": "0", "min": "0", "max": "2", "StartDisabled": "0"}, dv,
                connections=[("OnHitMax", "lc_nest_open", "Trigger", "", 0), ("OnHitMax", "lc_nest_shut", "Trigger", "", 0)])
        # the wiring: the shutter takes about five seconds each way (152 at 30: shutting, it is down 6.57 s in). The shove
        # is on from 4 s in (its foot 74 over the floor) until 0.3 s after it is down. lc_nest_opened and lc_nest_closed
        # are fired so the gamemode can hear what happened (nothing in the map listens to them).
        opening = [("OnTrigger", "lc_nest_open", "Disable", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 1.7),
                   ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 3.4), ("OnTrigger", "lc_nest_light", "TurnOn", "", 0), ("OnTrigger", "lc_nest_portal", "Open", "", 1.4),
                   ("OnTrigger", "lc_nest_door", "PressIn", "", 1.5), ("OnTrigger", "lc_nest_move", "PlaySound", "", 1.5), ("OnTrigger", "lc_nest_opened", "Trigger", "", 1.5),
                   ("OnTrigger", "lc_nest_move", "StopSound", "", 6.6), ("OnTrigger", "lc_nest_slam", "PlaySound", "", 6.6), ("OnTrigger", "lc_nest_shake", "StartShake", "", 6.6),
                   ("OnTrigger", "lc_nest_light", "TurnOff", "", 9), ("OnTrigger", "lc_nest_shut", "Enable", "", 9)]
        # the alarm at the first mouth beyond the door (Episode Two's post, holdout()): the siren and all three lamps when the
        # door is opened, the antlions 11 s later (the owner, 21 November: "20 seconds is too long; let's do 11 seconds.
        # This is triggered by the players so they know what they are getting into already"). The first antlion out
        # stops the siren; the lamps stay lit while the door is open.
        opening += [("OnTrigger", "lc_nest_mouth_1_siren", "PlaySound", "", 0)] + [("OnTrigger", "lc_nest_mouth_1_lamp_%d" % k, "LightOn", "", 0.3 * (k - 1)) for k in (1, 2, 3)]
        opening += [("OnTrigger", "lc_nest_maker", "Enable", "", self.NEST_WARNING)]
        shutting = [("OnTrigger", "lc_nest_shut", "Disable", "", 0), ("OnTrigger", "lc_nest_maker", "Disable", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 0),
                    ("OnTrigger", "lc_nest_open", "CancelPending", "", 0),          # (shut inside the 11 s: no antlions come at all)
                    ("OnTrigger", "lc_nest_mouth_1_siren", "StopSound", "", 0)] + [("OnTrigger", "lc_nest_mouth_1_lamp_%d" % k, "LightOff", "", 0) for k in (1, 2, 3)] + [
                    ("OnTrigger", "lc_nest_light", "TurnOn", "", 0), ("OnTrigger", "lc_nest_door", "PressOut", "", 1.5), ("OnTrigger", "lc_nest_move", "PlaySound", "", 1.5),
                    ("OnTrigger", "lc_nest_shove", "Enable", "", 4), ("OnTrigger", "lc_nest_shove", "Disable", "", 6.9),
                    ("OnTrigger", "lc_nest_move", "StopSound", "", 6.6), ("OnTrigger", "lc_nest_slam", "PlaySound", "", 6.6), ("OnTrigger", "lc_nest_shake", "StartShake", "", 6.6),
                    ("OnTrigger", "lc_nest_portal", "Close", "", 6.9), ("OnTrigger", "lc_nest_closed", "Trigger", "", 6.9), ("OnTrigger", "lc_nest_light", "TurnOff", "", 9),
                    ("OnTrigger", "lc_nest_open", "Enable", "", 9)]
        v.point("logic_relay", W(fx + 30, dy - 16, zf + 130), {"targetname": "lc_nest_open", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=opening)
        v.point("logic_relay", W(fx + 30, dy + 16, zf + 130), {"targetname": "lc_nest_shut", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=shutting)
        v.point("logic_relay", W(fx + 30, dy - 16, zf + 150), {"targetname": "lc_nest_opened", "StartDisabled": "0", "spawnflags": "0"}, dv)
        v.point("logic_relay", W(fx + 30, dy + 16, zf + 150), {"targetname": "lc_nest_closed", "StartDisabled": "0", "spawnflags": "0"}, dv)
        self.node(fx + 120, dy, zf)
        self.node(wx - 72, dy, zf)
        self.door_hole = (wx, dy - 96, zf, fx, dy + 96, zf + high)
        self.keep_way_clear((wx - 200, dy - 88, zf + 4, fx + 220, dy + 88, zf + 110), "the emergency door")
        self.joints.append(("the emergency door's bulkhead", self.w(wx - 160, dy - 400, zf - 64) + self.w(fx + 160, dy + 400, zf + 420)[0:3],
                            [self.w(fx + 100, dy, zf + 64), self.w(wx - 100, dy, zf + 64)]))
        self.notes.append("the emergency door: in a bulkhead across the big room's south lobe at (%d %d), floor z %d, facing east; a shutter 192 wide and %d high; its two "
                          "buttons are 480 apart with a wall between each and the door (about 700 on foot); both within a second open it, and shut it again" % (
                              self.ox + fx, self.oy + dy, zf, high))

    def holdout(self):
        """Behind the emergency door, Episode Two's holdout from ep2_outland_03, lifted whole as Valve made it
        (valve_ep2_holdout): the built mine gallery from the door to the top landing, the pit with Valve's cage lift down
        its south wall, the holdout's floor (the big mining room where the zombies and antlions come while the lift is
        on its way), and north of it the antlion tunnels that loop round (Valve's own, with their grubs), ending in a
        chamber with the larval extract. Its story (vortigaunts, scenes, Valve's makers, autosaves, the gate the
        vortigaunt opens, items and weapons) is left out; the lift runs on our wiring (holdout_lift)."""
        v, zf = self.vmf, self.zf
        hv, hp = self.vis("holdout (Episode Two's, lifted from ep2_outland_03)"), self.vis("holdout: lights and dressing")
        mv_ = self.vis("antlion makers (delete if the gamemode is to send the antlions itself)")
        d = self.w(*self.deep_pt(2848, -10136, -576))
        drop_from = ("func_physbox", "func_breakable", "func_door", "func_button", "func_rotating", "func_brush", "func_lod", "func_illusionary")

        def skip(sol):
            f = sol["from"]
            if f.startswith(drop_from) or (f.startswith("func_tracktrain") and sol.get("live") == "holdout_elevator_1"):
                return True       # (Valve's loose boards, breakables, the gate, its buttons, the blockers, the see-through; the cage rides on our lift)
            if any(c[0] > 3060 - 2848 for sd in sol["sides"] for c in (sd["corners"] or sd["plane"])):
                return True       # (nothing past the bulkhead into the big room: the gallery's own walls end inside it; clip_x shortened the boxes)
            return any(sd["material"].lower().startswith("nature/clifftrees") for sd in sol["sides"])   # (tree cards against Valve's sky: it is black here)
        keep_cls = ("prop_static", "prop_dynamic", "prop_dynamic_override", "prop_physics", "prop_door_rotating", "light", "light_spot", "infodecal", "env_sprite",
                    "keyframe_rope", "move_rope", "point_spotlight", "npc_antlion_grub", "func_useableladder", "info_ladder_dismount", "func_rotating", "func_lod")

        def keep(e):
            if e.get("ours"):
                return True
            k, name, model = e["classname"], e["keys"].get("targetname", ""), e["keys"].get("model", "")
            if k not in keep_cls or "explosive" in model or "egg.mdl" in model:
                return False
            if name == "controlroom_exit_door" or any(m in model for m in ("wood_stack", "cafeteria_bench", "cafeteria_table", "prison_shelf", "vol_light")):
                return False      # (the gallery's door left open for the antlions, and what stood in its way; the beams of Valve's sky, black here)
            return not (name.endswith("_model_off") or name.startswith(("elevator_exit_gate", "button_elevator", "sprite_ele")))

        def edit(e):
            k, name = e["classname"], e["keys"].get("targetname", "")
            if k in ("light", "light_spot"):
                e["keys"]["spawnflags"] = "0"        # (Valve's lamps down the pit were lit by the story as the cage passed: lit here)
            if k == "point_spotlight" and name.startswith("elevator_1_light"):
                e["keys"]["spawnflags"] = "3"
        extra = self.holdout_lift()
        pf, boxes = self.lifted("valve_ep2_holdout", 0, d, hv, hp, "lc_holdout_", skip=skip, keep=keep, edit=edit, extra=extra, clip=3040 - 2848)
        X1, Y1, Z1 = (min(bx[k] for bx in boxes) - self.ox * (k == 0) - self.oy * (k == 1) for k in range(3))
        X2, Y2, Z2 = (max(bx[k + 3] for bx in boxes) - self.ox * (k == 0) - self.oy * (k == 1) for k in range(3))
        self.deep_reach = (X1, Y1, Z1, X2, Y2, Z2)
        B, P = self.box, self.deep_pt
        cm, rock = "concrete/concretewall_mine_002a", "nature/blendrockslime02a"

        def vbox(a, b):
            pa, pb = P(*a), P(*b)
            return B(*(tuple(min(pa[k], pb[k]) for k in range(3)) + tuple(max(pa[k], pb[k]) for k in range(3))))
        # the holdout floor's two corridors west were cut (they ran on to Valve's other workings): walled up 48 inside
        # what is kept of them, in their own concrete
        v.world_box(vbox((400, -9072, -1840), (560, -8080, -1536)), cm, top=cm, bottom=cm, vis=hv)
        self.joints.append(("the holdout floor's corridors west", self.w(*P(400, -9072, -1900)) + self.w(*P(760, -8080, -1400)),
                            [self.w(*P(650, -8320, -1700)), self.w(*P(650, -8832, -1700))], "apart"))
        # the antlion tunnels' way on east (to Valve's rail incline) was cut where it is narrow: walled up in its rock,
        # the face 48 inside the shortest of the tunnel's kept rock
        ends = [bx[3] - self.ox for bx in boxes if P(2780, 0, 0)[0] < bx[3] - self.ox < P(3100, 0, 0)[0] and bx[1] - self.oy < P(0, -7020, 0)[1]
                and bx[4] - self.oy > P(0, -7300, 0)[1] and bx[2] < P(0, 0, -1340)[2] and bx[5] > P(0, 0, -1620)[2]]
        face = min((min(ends) if ends else P(2950, 0, 0)[0]) - 48, P(2848, 0, 0)[0])      # (and west of Valve's own seal there: its areaportal's frame at 2872)
        self.cave_cap_x = face
        v.world_box(B(face, P(0, -7400, 0)[1], P(0, 0, -1920)[2], face + 192, P(0, -6920, 0)[1], P(0, 0, -1024)[2]), rock, top=rock, bottom=rock, vis=hv)
        self.joints.append(("the antlion tunnels' end east", self.w(face - 192, P(0, -7440, 0)[1], P(0, 0, -1960)[2]) + self.w(face + 64, P(0, -6880, 0)[1], P(0, 0, -980)[2]),
                            [self.w(face - 96, P(0, -7150, 0)[1], P(0, 0, -1500)[2])]))
        # the larval extract at the tunnels' end (Valve's honeycomb nest and the essence over it, as at the end of
        # ep2_outland_04: the essence 127 over the nest's foot, its own glow), in the chamber the loop comes round to
        ex = P(2240, -6880, -1768)
        self.static("models/props_hive/nest_extract.mdl", ex[0], ex[1], ex[2] - 2, 271, "holdout: the extract")
        v.point("prop_dynamic", self.w(ex[0] + 6, ex[1] + 5, ex[2] + 127), {
            "targetname": "lc_nest_extract", "model": "models/props_hive/larval_essence.mdl", "angles": "0 298 0", "skin": "0", "solid": "6", "disableshadows": "0",
            "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0",
            "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0",
            "ExplodeRadius": "0"}, hp)
        v.point("light", self.w(ex[0] + 40, ex[1] - 40, ex[2] + 160), {"_light": "255 200 90 150", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("light", self.w(ex[0] + 6, ex[1] + 5, ex[2] + 96), {"_light": "160 255 150 40", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        self.keep_way_clear((P(2250, 0, 0)[0], P(0, -7330, 0)[1], ex[2] + 24, P(2600, 0, 0)[0], P(0, -7240, 0)[1], ex[2] + 100), "the larval extract's chamber")
        # Episode Two's alarm post at the first mouth beyond the door (valve_ep2_antlion_alarm): in the gallery, where
        # the antlions come from the holdout's top landing, its lamps facing the way from the door
        al = P(1850, -10080, -608)
        apf = PF.load("valve_ep2_antlion_alarm")

        def louder(e):                          # (Valve's 1250 stops short of the door's buttons)
            if e["keys"].get("targetname") == "mouth_1_siren":
                e["keys"]["radius"] = "2400"
        pf_entities(v, apf, 2, self.w(al[0], al[1], al[2]), "lc_nest_", hp, self.vis("alarm post (Episode Two's)"), edit=louder, valve_anchor=apf["anchor"])
        z0 = P(0, 0, -576)[2]
        for (xa, ya, xb, yb, what) in ((2260, -10120, 2760, -10050, "the gallery from the emergency door"), (2190, -10085, 2260, -10045, "the gallery's doorway into the control room"),
                                       (1150, -9940, 1750, -9900, "the corridor on to the top landing"), (1110, -9880, 1200, -9640, "the way up to the top landing")):
            self.keep_way_clear((P(xa, 0, 0)[0], P(0, ya, 0)[1], z0 + 4, P(xb, 0, 0)[0], P(0, yb, 0)[1], z0 + 72), what)
        # the antlions while the emergency door is open: one pattern (not in the map until a maker copies it), two makers
        # in the gallery's far end, two alive from each, no end to them while it is open; each one made runs to
        # lc_nest_rally in the big room
        t = P(1500, -9920, -590)
        v.point("npc_antlion", self.w(*t), {"targetname": "lc_nest_antlion", "spawnflags": "2564", "angles": "0 0 0", "radius": "256", "eludedist": "1024", "ignorebugbait": "0",
                                           "startburrowed": "0", "unburroweffects": "0", "squadname": "lc_nest", "physdamagescale": "1.0", "sleepstate": "0",
                                           "renderamt": "255", "rendercolor": "255 255 255"}, mv_)
        makers = (P(1300, -9920, -590), P(1100, -9700, -590))
        for p in makers:
            v.point("npc_template_maker", self.w(*p), {
                "targetname": "lc_nest_maker", "TemplateName": "lc_nest_antlion", "StartDisabled": "1", "spawnflags": "32", "MaxNPCCount": "1", "SpawnFrequency": "9",
                "MaxLiveChildren": "2", "Radius": "96", "MinSpawnDistance": "0", "CriterionVisibility": "2", "CriterionDistance": "2", "angles": "0 0 0"}, mv_,
                connections=[("OnSpawnNPC", "!activator", "FightToPosition", "lc_nest_rally", 0.5), ("OnSpawnNPC", "lc_nest_mouth_1_siren", "StopSound", "", 0)])
        # their way to the door: path nodes along the gallery (the door's own are bulkhead()'s, the room's big_room()'s)
        for (x, y, z) in ((2650, -10100, -576), (2420, -10070, -576), (2230, -10064, -600), (2050, -10050, -604), (1880, -9990, -604), (1700, -9920, -604),
                          (1450, -9920, -604), (1200, -9920, -604), (1100, -9750, -604), (1100, -9550, -604)):
            self.node(*P(x, y, z))
        # the holdout's floor, for the zombies and antlions that come while the lift is on its way
        for x in range(950, 2300, 300):
            for y in (-8300, -8650):
                self.node(*P(x, y, -1788))
        for x in (1000, 1300, 1700, 2000):
            self.node(*P(x, -9000, -1788))
        for (xa, ya, za, xb, yb, zb_, what) in ((1480, -9500, -1720, 1560, -9420, -1650, "the lift's floor landing"), (1480, -9440, -504, 1560, -9400, -440, "the lift's top landing"),
                                                (1810, -9380, -1776, 1930, -8240, -1700, "the holdout's floor from the lift to the tunnels"),
                                                (1560, -8260, -1776, 1810, -8200, -1700, "the holdout's floor before the tunnels"),
                                                (1360, -8230, -1776, 1520, -7700, -1700, "the tunnel north from the holdout")):
            self.keep_way_clear((P(xa, 0, 0)[0], P(0, ya, 0)[1], P(0, 0, za)[2], P(xb, 0, 0)[0], P(0, yb, 0)[1], P(0, 0, zb_)[2]), what)
        # light: Valve lit the pit from its sky; here it is black, so a cold fill high in it and one over the floor
        for (x, y, z, col) in ((1500, -9000, -900, "150 170 210 120"), (1500, -8700, -1600, "190 200 220 90"), (1000, -8500, -1650, "255 200 150 50")):
            v.point("light", self.w(*P(x, y, z)), {"_light": col, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        for (x, y, z) in ((1500, -8800, -1700), (2000, -10136, -520), (1400, -7000, -1700)):
            v.point("env_cubemap", self.w(*P(x, y, z)), {"cubemapsize": "0"}, hv)
        grubs = sum(1 for e in pf.get("wiring", []) if e["classname"] == "npc_antlion_grub")
        self.notes.append("the holdout: Episode Two's (ep2_outland_03, %d brushes, %d displaced faces, lifted whole): a gallery %d long from the emergency door to the top landing, "
                          "the lift down %d to the holdout's floor, the antlion tunnels north of it that loop round, the larval extract (lc_nest_extract) at their end; "
                          "Valve's %d grubs where Valve put them; the alarm post in the gallery; %d antlion makers there" % (
                              len(pf["solids"]), sum(1 for sol in pf["solids"] for sd in sol["sides"] if sd.get("disp")), 2848 - 1150, 1728 - 512,
                              grubs, len(makers)))

    def holdout_lift(self):
        """The holdout's lift, as entities in the piece's frame (named as the piece's: lc_holdout_...), for pf_entities.
        Valve's cage (holdout_elevator_1: its own brushwork, open on its north side, the lamp and the rotating red light
        on it) on a func_tracktrain of our own wiring: it starts at the top, where the players come in; a call button at
        each landing and one in the cage; stops 3 over each floor, so nothing is flush; while it is away from the top an
        unseen clip closes the hole it leaves in the landing; it does no crush damage. While it is on its way down the
        holdout's makers send zombies and antlions (Valve's way: they come while you wait for it), off when it is down.
        Valve's own climbs only while someone stands in it (one trigger's OnStartTouch and OnEndTouch: it breaks with
        several players), so that is not copied."""
        pf = PF.load("valve_ep2_holdout")
        ax = pf["anchor"]
        cage = [w for w in pf["wiring"] if w["keys"].get("targetname") == "holdout_elevator_1"][0]
        rel = lambda x, y, z: [x - ax[0], y - ax[1], z - ax[2]]
        out = []

        def ent(cls, keys, at, outs=(), brushes=None, origin=None):
            e = {"classname": cls, "origin": list(at), "keys": keys, "out": list(outs), "ours": True}
            if brushes:
                e["brushes"] = brushes
            out.append(e)
            return e

        def bx(x1, y1, z1, x2, y2, z2, mat):
            sides = []
            for f in FACE_ORDER:
                p = face_corners((x1, y1, z1, x2, y2, z2), f)
                u, w = FACE_AXES[f]
                sides.append({"plane": [list(c) for c in p[:3]], "verts": [list(c) for c in p], "material": mat.upper(), "uaxis": u, "vaxis": w, "lightmapscale": "16"})
            return sides
        o = cage["origin"]                         # (-1328 590 56: the cage built at the top, its floor's top 8 over its origin)
        floor_top = 64
        delta = floor_top - o[2]
        top, bottom = rel(0, 0, -512)[2] + 3 - delta, rel(0, 0, -1728)[2] + 3 - delta
        speed = str(self.LIFT_SPEED)
        keys = dict(cage["keys"])
        keys.update({"targetname": "holdout_elevator_1", "target": "stop_top", "speed": "0", "startspeed": speed, "height": "0", "dmg": "0", "spawnflags": "19", "orientationtype": "0"})
        ent("func_tracktrain", keys, o, brushes=cage["brushes"])
        ent("path_track", {"targetname": "stop_top", "target": "stop_bottom", "speed": speed, "spawnflags": "0", "orientationtype": "0", "angles": "0 0 0"}, (o[0], o[1], top),
            [("OnPass", "arrive_top", "Trigger", "", 0)])
        ent("path_track", {"targetname": "stop_bottom", "target": "", "speed": speed, "spawnflags": "0", "orientationtype": "0", "angles": "0 0 0"}, (o[0], o[1], bottom),
            [("OnPass", "arrive_bottom", "Trigger", "", 0)])
        spots = iter([(o[0] - 200 - 16 * (i % 6), o[1] + 160 + 16 * (i // 6), floor_top + 40) for i in range(200)])

        def relay(name, outs, off=False):
            ent("logic_relay", {"targetname": name, "StartDisabled": "1" if off else "0", "spawnflags": "0"}, next(spots), outs)
        go = [("OnTrigger", "call_*", "Disable", "", 0), ("OnTrigger", "rot_redlight1", "Start", "", 0), ("OnTrigger", "spot_doors*", "LightOn", "", 0),
              ("OnTrigger", "lift_start", "PlaySound", "", 0)]
        relay("go_down", go + [("OnTrigger", "arrive_bottom", "Enable", "", 0), ("OnTrigger", "holdout_elevator_1", "StartForward", "", 1), ("OnTrigger", "fence_top", "Enable", "", 3),
                               ("OnTrigger", "zombie_maker", "Enable", "", 2), ("OnTrigger", "antlion_maker", "Enable", "", 4)])
        relay("go_up", go + [("OnTrigger", "arrive_top", "Enable", "", 0), ("OnTrigger", "holdout_elevator_1", "StartBackward", "", 1)])
        done = [("OnTrigger", "rot_redlight1", "Stop", "", 0), ("OnTrigger", "spot_doors*", "LightOff", "", 0), ("OnTrigger", "call_*", "Enable", "", 1.5)]
        relay("arrive_top", done + [("OnTrigger", "arrive_top", "Disable", "", 0), ("OnTrigger", "at_*", "SetValue", "1", 0), ("OnTrigger", "fence_top", "Disable", "", 0)], off=True)
        relay("arrive_bottom", done + [("OnTrigger", "arrive_bottom", "Disable", "", 0), ("OnTrigger", "at_*", "SetValue", "0", 0),
                                       ("OnTrigger", "zombie_maker", "Disable", "", 0), ("OnTrigger", "antlion_maker", "Disable", "", 0)], off=True)
        for name, cmp_value, outs in (("top", "1", [("OnLessThan", "go_up", "Trigger", "", 0)]), ("bottom", "0", [("OnGreaterThan", "go_down", "Trigger", "", 0)]),
                                      ("cage", "1", [("OnEqualTo", "go_down", "Trigger", "", 0), ("OnLessThan", "go_up", "Trigger", "", 0)])):
            relay("call_" + name, [("OnTrigger", "at_" + name, "Compare", "", 0)])
            ent("logic_compare", {"targetname": "at_" + name, "InitialValue": "1", "CompareValue": cmp_value}, next(spots), outs)
        ent("ambient_generic", {"targetname": "lift_start", "message": "d3_breen.core_elevator_move1", "health": "8", "pitch": "100", "pitchstart": "100", "radius": "1500",
                                "spawnflags": "48", "volstart": "0", "preset": "0"}, (o[0], o[1], floor_top + 120))
        # the clip over the landing's hole while the cage is away (on the landing's level: the riders are well below it by then)
        x1, y1, x2, y2 = -1376, 552, -1280, 628
        ent("func_brush", {"targetname": "fence_top", "StartDisabled": "1", "Solidity": "0", "spawnflags": "2", "rendermode": "10", "renderamt": "0", "excludednpc": "",
                           "invert_exclusion": "0", "solidbsp": "0", "vrad_brush_cast_shadows": "0"}, ((x1 + x2) / 2, (y1 + y2) / 2, floor_top + 56),
            brushes=[bx(x1, y1, floor_top, x2, y2 + 8, floor_top + 112, MAT["clip"])])

        def button(name, foot, yaw, box, model, outs, parent=None):
            pk = {"targetname": name + "_model", "model": model, "angles": "0 %s 0" % yaw, "skin": "0", "solid": "0", "DefaultAnim": "idleoff", "disableshadows": "1",
                  "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0",
                  "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0",
                  "ExplodeDamage": "0", "ExplodeRadius": "0"}
            bk = {"targetname": name, "spawnflags": "1025", "wait": "1", "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "0", "health": "0", "rendermode": "10",
                  "renderamt": "0", "rendercolor": "255 255 255"}
            if parent:
                pk["parentname"] = bk["parentname"] = parent
            ent("prop_dynamic", pk, foot)
            ent("func_button", bk, ((box[0] + box[3]) / 2, (box[1] + box[4]) / 2, (box[2] + box[5]) / 2),
                [("OnPressed", name + "_model", "SetAnimation", "turn_ON", 0)] + list(outs), brushes=[bx(*box, MAT["nodraw"])])
        # the top landing's: on the pit's south wall west of the cage, facing the landing; the floor's: where Valve's was
        # (freightelevatorbutton01 on the post west of the cage); the cage's: on its south side's middle post, facing in
        b02 = "models/props_mining/freightelevatorbutton02.mdl"
        button("button_top", (-1400, 536, floor_top + 40), 90, (-1410, 536, floor_top + 36, -1390, 546, floor_top + 64), b02, [("OnPressed", "call_top", "Trigger", "", 0)])
        bz = rel(0, 0, -1691)[2]
        button("button_bottom", (-1414, 616, bz), 179.5, (-1424, 606, bz - 6, -1414, 626, bz + 24), "models/props_mining/freightelevatorbutton01.mdl",
               [("OnPressed", "call_bottom", "Trigger", "", 0)])
        button("button_cage", (-1328, 556, floor_top + 36), 90, (-1338, 556, floor_top + 32, -1318, 566, floor_top + 60), b02, [("OnPressed", "call_cage", "Trigger", "", 0)],
               parent="holdout_elevator_1")
        # the holdout's makers (Valve's way: on while the lift comes down), each with its pattern; made at the room's ends
        for name, cls, at, every in (("zombie", "npc_zombie", rel(850, -8399, -1784), "4"), ("antlion", "npc_antlion", rel(2014, -9100, -1783), "6")):
            ent(cls, {"targetname": name, "spawnflags": "2564", "angles": "0 0 0", "squadname": "lc_holdout", "physdamagescale": "1.0", "sleepstate": "0",
                      "renderamt": "255", "rendercolor": "255 255 255"}, (at[0] + 64, at[1], at[2] + 8))
            ent("npc_template_maker", {"targetname": name + "_maker", "TemplateName": "lc_holdout_" + name, "StartDisabled": "1", "spawnflags": "32", "MaxNPCCount": "1",
                                       "SpawnFrequency": every, "MaxLiveChildren": "3", "Radius": "96", "MinSpawnDistance": "0", "CriterionVisibility": "2",
                                       "CriterionDistance": "2", "angles": "0 0 0"}, (at[0], at[1], at[2] + 8))
        self.lift_info = (o, top, bottom, delta)
        return out

    def workings_hull(self):
        """One shut box round all that lies behind the forest's north wall, and inside it a shut box of its own round the
        big room: the room's box is shut but for the hole from the cave and the emergency door (its west wall is the
        bulkhead), so the door's areaportal keeps the two apart whatever the lifted pieces' own rock lets through. West
        of the world's x -6720 (the ring's canal is east), at least 384 inside the map's edge. Black inside where nothing
        lifted covers it."""
        v, nv, black = self.vmf, self.vis("hull behind the forest (black walls)"), MAT["black"]
        ys = self.D + WALL
        r = self.room_box
        rx1, ry1, rz1, rx2, ry2, rz2 = r
        # the room's own box: north, east, under and over (its west wall is the bulkhead, its south the forest's wall)
        for box in ((rx1, ry2, rz1 - 64, rx2 + 64, ry2 + 64, rz2 + 64), (rx2, ry1, rz1 - 64, rx2 + 64, ry2, rz2 + 64), (rx1, ry1, rz1 - 64, rx2, ry2, rz1),
                    (rx1, ry1, rz2, rx2, ry2, rz2 + 64)):
            v.world_box(self.box(*box), black, vis=nv)
        # the box round everything
        d = self.deep_reach
        X1 = int(math.floor((min(d[0], rx1) - 64) / 64.0)) * 64
        X2 = rx2 + 64
        Y2 = int(math.ceil((max(d[4], ry2 + 64) + 64) / 64.0)) * 64
        Z1 = int(math.floor((min(d[2], rz1 - 64) - 64) / 64.0)) * 64
        Z2 = int(math.ceil((max(d[5], rz2 + 64)) / 64.0)) * 64
        for box in ((X1 - 64, ys, Z1 - 64, X2 + 64, Y2 + 64, Z1), (X1 - 64, ys, Z2, X2 + 64, Y2 + 64, Z2 + 64), (X1 - 64, ys, Z1, X1, Y2 + 64, Z2),
                    (X2, ys, Z1, X2 + 64, Y2 + 64, Z2), (X1, Y2, Z1, X2, Y2 + 64, Z2)):
            v.world_box(self.box(*box), black, vis=nv)
        # its south side where the forest's north wall does not stand: west of the forest, under its slab, over its sky (and
        # over the stretch the cave's wall and its sky are, the room's box over the sky too)
        tw = WALL
        south = [(X1 - 64, self.D, Z1 - 64, -tw, ys, Z2 + 64)] if X1 < -tw else []
        south += [(-tw, self.D, Z1 - 64, X2 + 64, ys, self.zb - 64)] if Z1 < self.zb - 64 else []
        south += [(-tw, self.D, self.lid + 16, X2 + 64, ys, Z2 + 64)] if Z2 > self.lid + 16 else []
        for box in south:
            v.world_box(self.box(*box), black, vis=nv)
        self.hull_box = (X1, ys, Z1, X2, Y2, Z2)
        wx1, wx2 = self.ox + X1 - 64, self.ox + X2 + 64
        if wx2 > -6720:
            self.problems.append("the workings reach x %d: east of x -6720, where the ring's canal is" % wx2)
        if self.oy + Y2 + 64 > 16000 or wx1 < -16000 or Z1 - 64 < -16000 or Z2 + 64 > 16000:
            self.problems.append("the workings come within 384 of the map's edge (16384)")
        # shut in: with the hole from the cave and the emergency door's doorway stopped, the air in the room must not reach the
        # forest or what lies behind the door, nor that air the forest
        stop_hole, stop_door = self.box(*self.joint_hole), self.box(*self.door_hole)
        inside_room = self.w(*self.room_pt(500, -900, -5000))
        inside_deep = self.w(*self.deep_pt(2000, -10136, -500))
        forest_air = self.w(self.W / 2, 600, self.lid - 100)
        closed = flood(v, inside_deep, [stop_door])
        if closed[0] is None or reaches(closed, forest_air) or reaches(closed, inside_room):
            self.problems.append("what lies behind the emergency door is open to the room or the forest somewhere other than the door")
        closed = flood(v, inside_room, [stop_hole, stop_door])
        if closed[0] is None or reaches(closed, forest_air) or reaches(closed, inside_deep):
            self.problems.append("the big room's box is open somewhere other than the hole from the cave and the emergency door")
        self.notes.append("behind the forest's north wall: one shut box x %d to %d, y %d to %d, z %d to %d (the big room's own box inside it)" % (
            wx1, wx2, self.oy + ys, self.oy + Y2 + 64, Z1 - 64, Z2 + 64))

    def joints_check(self):
        """Near every cut and joint behind the forest's north wall (self.joints: a box and points in its air), no nodraw face
        may face the way: the air is flooded from those points (8 unit cells) between every brush that hides what is
        behind it and every displaced surface; a nodraw face whose front is in that air would be seen (the owner, 22
        November: "every single connecting room has nodraw faces visible inwards towards the player"). A point in the air
        that is inside something is a way blocked."""
        import os
        import tempfile
        import numpy as np
        import map_view as mv
        text = "world\n{\n" + "".join(self.vmf.world) + "}\n" + "".join(e for e in self.vmf.ents if "\tsolid\n" in e)
        fd, path = tempfile.mkstemp(suffix=".vmf")
        with os.fdopen(fd, "w") as f:
            f.write(text)
        root = mv.read(path)
        os.remove(path)
        moving = ("trigger", "areaportal", "occluder", "func_button", "func_door", "func_brush", "func_tracktrain", "func_rotating", "func_illusionary", "func_clip")
        see_through = ("tools/toolsclip", "tools/toolsplayerclip", "tools/toolsnpcclip", "tools/toolstrigger", "tools/toolshint", "tools/toolsskip",
                       "tools/toolsareaportal", "tools/toolsoccluder", "tools/toolsinvisible", "tools/toolsblocklight")
        sols = []
        for top in root.kids:
            if top.name not in ("world", "entity"):
                continue
            cls = top.kv.get("classname", "worldspawn")
            if any(k in cls for k in moving):
                continue
            for sol in top.kids:
                if sol.name != "solid":
                    continue
                sides = [k for k in sol.kids if k.name == "side"]
                pts = [mv.nums(s.kv.get("plane", "")) for s in sides]
                if any(len(p) < 9 for p in pts):
                    continue
                q = [p[i:i + 3] for p in pts for i in (0, 3, 6)]
                sols.append((sides, tuple(min(c[k] for c in q) for k in range(3)) + tuple(max(c[k] for c in q) for k in range(3))))
        cell = 8.0
        found = 0
        for joint in self.joints:
            label, box, seeds = joint[:3]
            apart = len(joint) > 3 and joint[3] == "apart"
            x1, y1, z1, x2, y2, z2 = box
            n = [int(math.ceil((box[k + 3] - box[k]) / cell)) for k in range(3)]
            cx = [box[k] + cell * (np.arange(n[k]) + 0.5) for k in range(3)]
            solid = np.zeros(n, bool)
            faces = []
            for sides, bb in sols:
                if bb[3] < x1 - 64 or bb[0] > x2 + 64 or bb[4] < y1 - 64 or bb[1] > y2 + 64 or bb[5] < z1 - 64 or bb[2] > z2 + 64:
                    continue
                w = mv.from_planes(sides)
                if not w:
                    continue
                allp = [p for f in w if f for p in f]
                if not allp:
                    continue
                cen = np.mean(np.array(allp), axis=0)
                disp = [k for k, s in enumerate(sides) if any(c.name == "dispinfo" for c in s.kids)]
                if disp:
                    for k in disp:
                        if not w[k] or len(w[k]) != 4:
                            continue
                        di = [c for c in sides[k].kids if c.name == "dispinfo"][0]
                        for poly, _, _ in mv.displaced(list(reversed(w[k])), di, (1, 1, 1)):
                            a, b, c, e = (np.array(p) for p in poly)
                            m = int(max(np.linalg.norm(b - a), np.linalg.norm(e - a), np.linalg.norm(c - b)) / 3.0) + 2
                            s_ = np.linspace(0, 1, m)
                            uu, vv = np.meshgrid(s_, s_)
                            pts_ = (a[None, None] * ((1 - uu) * (1 - vv))[..., None] + b[None, None] * (uu * (1 - vv))[..., None]
                                    + c[None, None] * (uu * vv)[..., None] + e[None, None] * ((1 - uu) * vv)[..., None]).reshape(-1, 3)
                            idx = np.floor((pts_ - np.array([x1, y1, z1])) / cell).astype(int)
                            ok = np.all((idx >= 0) & (idx < np.array(n)), axis=1)
                            solid[idx[ok, 0], idx[ok, 1], idx[ok, 2]] = True
                    continue
                mats = [s.kv.get("material", "").lower() for s in sides]
                if all(m in see_through for m in mats):
                    continue
                planes = []
                for s, f in zip(sides, w):
                    p = mv.nums(s.kv.get("plane", ""))
                    a, b, c = np.array(p[0:3]), np.array(p[3:6]), np.array(p[6:9])
                    nn = np.cross(c - a, b - a)
                    nn = nn / (np.linalg.norm(nn) or 1.0)
                    dd = float(nn @ a)
                    if nn @ cen - dd > 0:
                        nn, dd = -nn, -dd
                    planes.append((nn, dd))
                    if s.kv.get("material", "").lower() == "tools/toolsnodraw" and f:
                        faces.append((nn, f))
                r = [(max(0, int((bb[k] - box[k]) // cell)), min(n[k], int((bb[k + 3] - box[k]) // cell) + 1)) for k in range(3)]
                if any(lo >= hi for lo, hi in r):
                    continue
                gx, gy, gz = np.meshgrid(cx[0][r[0][0]:r[0][1]], cx[1][r[1][0]:r[1][1]], cx[2][r[2][0]:r[2][1]], indexing="ij")
                inside = np.ones(gx.shape, bool)
                for nn, dd in planes:
                    inside &= (gx * nn[0] + gy * nn[1] + gz * nn[2] - dd) <= 0.01
                solid[r[0][0]:r[0][1], r[1][0]:r[1][1], r[2][0]:r[2][1]] |= inside
            air = np.zeros(n, bool)
            first = None
            for sd in seeds:
                i = [int((sd[k] - box[k]) // cell) for k in range(3)]
                if not all(0 <= i[k] < n[k] for k in range(3)):
                    self.problems.append("joints check: a point of the way at %s lies outside its box (%s)" % (sd, label))
                    continue
                if solid[i[0], i[1], i[2]]:
                    self.problems.append("the way at %s is blocked: (%d %d %d) is inside something" % (label, sd[0], sd[1], sd[2]))
                    continue
                air[i[0], i[1], i[2]] = True
                if first is None:
                    first = i
                    if not apart:
                        break             # (the way is flooded from its first point only: the others must be reached)
            free = ~solid
            while True:
                grow = air.copy()
                grow[1:] |= air[:-1]
                grow[:-1] |= air[1:]
                grow[:, 1:] |= air[:, :-1]
                grow[:, :-1] |= air[:, 1:]
                grow[:, :, 1:] |= air[:, :, :-1]
                grow[:, :, :-1] |= air[:, :, 1:]
                grow &= free
                if (grow == air).all():
                    break
                air = grow
            if not apart:
                for sd in seeds[1:]:
                    i = [int((sd[k] - box[k]) // cell) for k in range(3)]
                    if all(0 <= i[k] < n[k] for k in range(3)) and not air[i[0], i[1], i[2]]:
                        self.problems.append("the way at %s is shut: (%d %d %d) cannot be reached from (%d %d %d)" % (label, sd[0], sd[1], sd[2], seeds[0][0], seeds[0][1], seeds[0][2]))
            for nn, f in faces:
                fa = np.array(f)
                mid = fa.mean(axis=0)
                tries = [mid] + [mid + 0.8 * (p - mid) for p in fa] + [mid + 0.4 * (p - mid) for p in fa]
                for p in tries:
                    q = p + nn * 5
                    i = [int((q[k] - box[k]) // cell) for k in range(3)]
                    if all(0 <= i[k] < n[k] for k in range(3)) and air[i[0], i[1], i[2]]:
                        found += 1
                        if found <= 12:
                            self.problems.append("a nodraw face at (%d %d %d), facing (%.1f %.1f %.1f), is seen from the way at %s" % (
                                q[0], q[1], q[2], nn[0], nn[1], nn[2], label))
                        break
        if found > 12:
            self.problems.append("... and %d more nodraw faces seen near the joints" % (found - 12))
        self.notes.append("joints: %d cuts and joints behind the north wall checked for nodraw faces in view (8 unit cells)%s" % (
            len(self.joints), "" if found else ": none seen"))

    def lamps_check(self):
        """A lamp's model must not stand inside another model or a brush of ours (the owner, 22 November: "the light prop is
        inside the girder prop"): each lamp's middle, by its model's own size turned by its yaw, against every other
        prop's turned box and every box brush of ours."""
        import map_assets
        lamps, others = [], []
        for n, (cls, pos, model, yaw) in enumerate(self.vmf.props):
            b = map_assets.size(model)
            if not b:
                continue
            c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            xs = [pos[0] + x * c - y * sn for x in (b[0], b[3]) for y in (b[1], b[4])]
            ys = [pos[1] + x * sn + y * c for x in (b[0], b[3]) for y in (b[1], b[4])]
            tb = (min(xs), min(ys), pos[2] + b[2], max(xs), max(ys), pos[2] + b[5])
            name = model.lower().rsplit("/", 1)[-1]
            (lamps if ("light" in name or "lamp" in name) and "lightshaft" not in name and "vol_light" not in name else others).append((tb, model, n in self.valve_props))
        bad = 0
        for tb, model, valve in lamps:
            mid = [(tb[k] + tb[k + 3]) / 2 for k in range(3)]
            for ob, om, ovalve in others:
                if valve and ovalve:
                    continue          # (a lamp of Valve's on a model of Valve's, as Valve put it)
                if all(ob[k] + 2 < mid[k] < ob[k + 3] - 2 for k in range(3)):
                    bad += 1
                    self.problems.append("the lamp %s at (%d %d %d) stands inside %s" % (model.rsplit("/", 1)[-1], mid[0], mid[1], mid[2], om.rsplit("/", 1)[-1]))
                    break
            else:
                for bb, seals in self.vmf.boxes:
                    if all(bb[k] + 2 < mid[k] < bb[k + 3] - 2 for k in range(3)):
                        bad += 1
                        self.problems.append("the lamp %s at (%d %d %d) stands inside a brush" % (model.rsplit("/", 1)[-1], mid[0], mid[1], mid[2]))
                        break
        self.notes.append("lamps: %d lamp models checked against the models and brushes round them%s" % (len(lamps), "" if bad else ": none inside another"))

    def fence_gate(self):
        """A chain link fence across the cave, 48 inside its mouth, with a double gate in it: two leaves 44 wide and 100 high
        that swing away from whoever opens them, together (two func_door_rotating of one name, hinged on the outer posts;
        press Use on either; to the gamemode they are doors like any other). The owner, of the first one, a single leaf 108
        wide and 124 high: "really huge, comically wide and oversized ... maybe have a double gate (french door gate?)".
        The fence is a flat sheet wider and higher than the passage, so its edges are in the rock all the way round; the
        stream runs under it in its bed."""
        v, cx, ym, zf = self.vmf, self.CX, self.YM, self.zf
        gv = self.vis("cave gate and fence")
        nd, chain, bar = MAT["nodraw"], MAT["fence"], MAT["bars"]
        y1, y2 = ym + 47, ym + 49
        thin = {"west": nd, "east": nd, "top": nd, "bottom": nd}
        g1, g2, gh = cx + 24, cx + 120, 112          # the gateway, on the dry side of the stream: 96 wide, 112 to its top bar
        mid = (g1 + g2) // 2
        v.detail([self.box(cx - 256, y1, zf - 16, g1, y2, zf + 272), self.box(g2, y1, zf - 16, cx + 256, y2, zf + 272), self.box(g1, y1, zf + gh, g2, y2, zf + 272)],
                 chain, vis=gv, faces=thin)
        v.detail([self.box(g1 - 6, ym + 45, zf - 16, g1, ym + 51, zf + gh + 6), self.box(g2, ym + 45, zf - 16, g2 + 6, ym + 51, zf + gh + 6),
                  self.box(g1 - 6, ym + 45, zf + gh, g2 + 6, ym + 51, zf + gh + 6)], bar, vis=gv)
        for (a, b, hinge) in ((g1 + 2, mid - 1, g1 + 2), (mid + 1, g2 - 2, g2 - 2)):
            leaf = [(self.box(a, y1, zf + 8, b, y2, zf + 108), thin),
                    (self.box(a, ym + 46, zf + 8, a + 3, ym + 50, zf + 108), bar), (self.box(b - 3, ym + 46, zf + 8, b, ym + 50, zf + 108), bar),
                    (self.box(a, ym + 46, zf + 105, b, ym + 50, zf + 108), bar), (self.box(a, ym + 46, zf + 8, b, ym + 50, zf + 11), bar)]
            v.brush_entity("func_door_rotating", {
                "targetname": "lc_cave_gate", "origin": "%d %d %d" % self.w(hinge, ym + 48, zf + 58), "distance": "90", "speed": "100", "wait": "-1", "lip": "0", "dmg": "0",
                "forceclosed": "0", "solidbsp": "0", "spawnflags": "288", "noise1": "doors/gate_move1.wav", "rendermode": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "disableshadows": "1"}, leaf, chain, gv)

    def kept_clear(self, x, y, margin=0):
        if self.stream_dist(x, y) < 70 + margin:
            return True
        if abs(x - self.CX) < 240 + 0.45 * max(0, self.YM - y) and 0 <= self.YM - y < 560:
            return True
        return Forest.kept_clear(self, x, y, margin)

    def preview_extra(self, dr, P):
        ym = self.YM
        left = [P(self.ring(math.pi, ym + s)[0], ym + s) for s in range(0, self.LONG + 1, 32)]
        right = [P(self.ring(0, ym + s)[0], ym + s) for s in range(0, self.LONG + 1, 32)]
        dr.polygon(left + right[::-1], fill=(20, 20, 24, 150), outline=(255, 255, 255, 200))

    def cave_picture(self, path):
        """The mouth seen from the front, and the passage seen from the side: is the skin a sane shape?"""
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            return
        img = Image.new("RGB", (1620, 620), (16, 16, 20))
        dr = ImageDraw.Draw(img)
        cx, ym, zf = self.CX, self.YM, self.zf

        def F(x, z):
            return (360 + (x - cx) * 0.5, 440 - (z - zf) * 0.5)
        for (x1, x2, z1, z2) in ((-608, -160, 0, 320), (160, 608, 0, 320), (-608, -160, 320, 704), (-160, 160, 320, 704), (160, 608, 320, 704)):
            g = [[self.collar(x1 + (x2 - x1) * j / 8.0, z1 + (z2 - z1) * i / 8.0) for j in range(9)] for i in range(9)]
            for i in range(9):
                for j in range(9):
                    if j < 8:
                        dr.line((F(g[i][j][0], g[i][j][2]), F(g[i][j + 1][0], g[i][j + 1][2])), fill=(150, 150, 160))
                    if i < 8:
                        dr.line((F(g[i][j][0], g[i][j][2]), F(g[i + 1][j][0], g[i + 1][j][2])), fill=(150, 150, 160))
        ring = [self.ring(k * math.pi / 32, ym) for k in range(65)]
        dr.line([F(p[0], p[2]) for p in ring], fill=(255, 200, 60), width=2)
        front = [F(x, self.natural(x, ym, (0, 0))) for x in range(cx - 720, cx + 721, 16)]
        dr.line(front, fill=(90, 200, 90), width=2)
        back = [F(x, self.natural(x, ym, (0, 9999))) for x in range(cx - 720, cx + 721, 16)]
        dr.line(back, fill=(60, 120, 60), width=1)
        dr.line((F(cx - 720, self.level), F(cx + 720, self.level)), fill=(70, 130, 220))
        dr.text((10, 8), "the mouth from the front: grey the rock face, yellow the cave's first ring, green the ground before it (dark green: behind), blue the stream's level", fill=(230, 230, 230))

        def S(y, z):
            return (760 + (y - ym + 500) * 0.25, 440 - (z - zf) * 0.25)
        for th, col in ((math.pi / 2, (255, 200, 60)), (-math.pi / 2, (255, 200, 60))):
            dr.line([S(ym + s, self.ring(th, ym + s)[2]) for s in range(0, self.LONG + 1, 16)], fill=col, width=2)
        dr.line([S(ym + s, self.natural(self.mid(ym + s), ym + s, (0, 9999))) for s in range(0, self.LONG + 1, 16)], fill=(90, 200, 90), width=2)
        dr.line([S(ym - s, self.natural(cx, ym - s, (0, 0))) for s in range(0, 500, 16)], fill=(90, 200, 90), width=2)
        dr.line((S(ym - 500, self.level), S(ym + self.SPRING, self.level)), fill=(70, 130, 220))
        dr.text((760, 30), "the passage from the side, along its middle (south on the left): yellow its roof and floor, green the ground and the hill over it", fill=(230, 230, 230))
        img.save(path)
        print("  picture: " + path)


def forest_cave(args):
    # (west of the ring's west run: the far side of the city from the bunker forest. The owner: "can they be on opposite sides
    #  of the canal? that way if one is attacked, it's quite a long distance to reach the other")
    floor = 400 if args.floor is None else args.floor
    f = CaveForest("forest (cave, stream)", tuple(args.origin or (-10240, 4608)), floor, 47, args.first_node or 4600, ("east", 256))
    f.test = bool(getattr(args, "test", False))
    f.setup()
    f.shell()
    f.ground()
    f.water()
    f.cave()
    f.plant()
    f.settle()
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
        f.cave_picture(args.preview.rsplit(".", 1)[0] + "_cave.png")
    return f.vmf, f.problems
