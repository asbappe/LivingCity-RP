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
import random

import map_prefab as PF
from map_build import CELL, FACE_AXES, FACE_ORDER, GATE_HIGH, GATE_WIDE, MAT, Plan, Vmf, check, face_corners, flood, gate_cap, reaches, test_extras

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
    # (ep2_outland_12a's launch control and 11b's work rooms): walls concretewall_bunker05b over a band of 05a 64 high,
    # floors concretefloor_bunker02a, ceilings concreteceiling_bunker01a; the silo's own concrete for the hull round it
    "wf_wall": "concrete/concretewall_bunker05b",
    "wf_band": "concrete/concretewall_bunker05a",
    "wf_floor": "concrete/concretefloor_bunker02a",
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

def wall_button(vmf, pos, yaw, name, box, vis, connections, wait, parent=None):
    """A button on a wall: Episode Two's mine lift button (the owner: "the button needs a button prop
    [models/props_mining/freightelevatorbutton02.mdl would work], not a big square brush"), and round it an unseen
    func_button that takes the press and plays the model's own press. pos: the model's foot against the wall (it is 8 wide,
    20 high and stands 5 out, facing east at yaw 0); box: the unseen button's own."""
    vmf.point("prop_dynamic", pos, {"targetname": name + "_model", "model": "models/props_mining/freightelevatorbutton02.mdl", "angles": "0 %d 0" % yaw, "skin": "0", "solid": "0",
                                    "DefaultAnim": "idleoff", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                    "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0",
                                    "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0",
                                    **({"parentname": parent} if parent else {})}, vis)
    vmf.brush_entity("func_button", {"targetname": name, "spawnflags": "1025", "wait": wait, "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "0", "health": "0",
                                     "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "min_use_angle": "0.8", **({"parentname": parent} if parent else {})},
                     [box], MAT["nodraw"], vis, connections=[("OnPressed", name + "_model", "SetAnimation", "turn_ON", 0)] + list(connections))


def crusher(vmf, door, box, vis, name):
    """Nothing stops a closing door (the owner: "anyone or anything that stands in the closing silo doors or closing antlion
    nest door is killed, and any props removed/deleted/shoved. nothing should stop these doors"). Two unseen boxes ride on
    the door's leading edge (`door`: its name; `box`: 14 ahead of that edge, where the door is drawn): one kills whoever
    it touches (a door only waits while something alive is in its way), one deletes whatever loose thing it touches. Both
    are off except while the door is closing: the wiring turns `name` on and off."""
    vmf.brush_entity("trigger_hurt", {"targetname": name, "parentname": door, "StartDisabled": "1", "spawnflags": "3", "damage": "100000", "damagecap": "100000",
                                      "damagetype": "1", "damagemodel": "0", "nodmgforce": "0"}, [box], MAT["trigger"], vis)
    vmf.brush_entity("trigger_multiple", {"targetname": name, "parentname": door, "StartDisabled": "1", "spawnflags": "1032", "wait": "0.1"}, [box], MAT["trigger"], vis,
                     connections=[("OnStartTouch", "!activator", "Kill", "", 0)])


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


def pf_solids(vmf, pf, q, d, vis, world=False, skip=None):
    """A lifted piece's brushes: with `world`, those that were Valve's world brushes go into the world (they cut up the
    map for visibility, as in Valve's own) and the rest into one func_detail. Their boxes are returned, not handed to
    the build's checks: Valve's corners are off our grid, and what seals is a hull of our own round the piece."""
    det, boxes = "", []
    for s in pf["solids"]:
        if skip and skip(s):
            continue
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


def pf_entities(vmf, pf, q, d, prefix, vis_props, vis_logic, keep=None, edit=None, extra=(), valve_anchor=None):
    """A lifted piece's props, lights and wiring (its path points too), turned and moved as its brushes. Every name the
    piece gives is prefixed (two pieces never answer each other), an output to anything the piece does not have is
    dropped (Valve's story, outside the piece), and every output may fire again (Valve's once-only buttons become
    reusable). keep(e) says what to place; edit(e) may change an entity first (each is a copy, its outputs already
    as (output, target, input, value, delay) in e["out"]); extra: entities of our own in the piece's frame, named as
    the piece's. A turned piece's tilting doors and spinners change axis with it. Returns the names placed."""
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
            if k.lower() in PF_NAME_KEYS and keys[k]:
                r = ren(keys[k])
                if r:
                    keys[k] = r
                elif k.lower() != "targetname":
                    del keys[k]          # (it names something outside the piece)
            if k.lower() in PF_SPOT_KEYS and valve_anchor:
                p = [float(c) for c in keys[k].split()]
                keys[k] = " ".join(PF.fmt(round(c, 2)) for c in pf_point([p[i] - valve_anchor[i] for i in range(3)], q, d))
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
            vmf.point(cls, tuple(pf_point(e["origin"], q, d)), keys, vis_props if cls.startswith("prop") else vis_logic, connections=outs)
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
                pieces = [(a, self.cuts[name][0], None), (self.cuts[name][1], b, None)]
            for s1, s2, face in pieces:
                x1, y1, x2, y2 = frames[name](s1, s2)
                v.world_box(self.box(x1, y1, self.zb, x2, y2, self.lid), sky, vis=vis, faces={face: MAT["canal_wall"]} if face else None)
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
        v.detail(head, MAT["canal_wall"], vis=self.vis("structures"))

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

    def static(self, model, x, y, z, yaw, what, solid=6, pitch=0, fade=(2800, 3400)):
        self.vmf.point("prop_static", self.w(x, y, z), {
            "model": model, "angles": "%d %d 0" % (pitch, yaw), "skin": "0", "solid": solid, "disableshadows": "0",
            "screenspacefade": "0", "fademindist": fade[0], "fademaxdist": fade[1], "fadescale": "1"}, self.vis(what))

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
                want *= self.TREES
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
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0, fade=(1500, 2000))
            n["plants"] += 1
        for kind, models, count, sink in (("rocks", ROCKS, 34, 10), ("logs", LOGS, 12, 4)):
            for _ in range(900):
                if n[kind] >= count:
                    break
                x, y = rnd.uniform(120, self.W - 120), rnd.uniform(120, self.D - 120)
                if self.kept_clear(x, y, 20) or self.slope(x, y) > 0.8 or any(math.hypot(x - tx, y - ty) < 70 for tx, ty in self.trees):
                    continue
                self.static(rnd.choice(models), x, y, self.natural(x, y) - sink, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood")
                n[kind] += 1
        self.planted = n

    def node(self, x, y, z):
        self.vmf.point("info_node", self.w(x, y, z + 16), {"nodeid": self.node_id}, self.vis("path nodes"))
        self.node_id += 1

    def ground_nodes(self):
        """Where the city's people can walk: a node every 256 units on ground that is dry, open and not steep."""
        for y in range(128, self.D, 256):
            for x in range(128, self.W, 256):
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
        if self.test:
            # (to compile and walk it by itself: a spawn point on the trail just inside the gate, and the map's sun)
            sx, sy = self.st(self.gate[1] + GATE_WIDE / 2, 220)
            yaw = {"west": 0, "south": 90, "east": 180, "north": 270}[self.gate[0]]
            test_extras(self.vmf, self.w(sx, sy, self.z0 + 16), yaw, self.vis("for testing alone (never in the real map)"))
        problems, air = check(self.vmf, self.w(self.W / 2, self.D / 2, self.lid - 100), [])
        self.problems += problems
        self.skin_check()
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
        skin = [m for m in made if m[0] != self.vis("ground")]
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
        return 0

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

class BunkerForest(Forest):
    POND = (1500, 1400, 640, 480)   # centre x, y; half its length and width
    ISLE = (1560, 1385, 260)
    B0 = (2368, 3072)               # the bunker's own corner: its door's wall is its south side. (Its x is chosen so the foot of
                                    # the second stairs, 320 west of it, is on a line between two ground patches: see height().)
    DOOR = (512, 768)               # the doorway, in the bunker's own coordinates: 256 wide and 192 high, shut by two sliding leaves

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
        hi, lo = FMAT["wf_wall"], FMAT["wf_band"]
        look = dict(floor_side=hi, ceiling=FMAT["wf_ceiling"], vis=self.vis("structures"))
        # the part under the mound: its roof is level with the mound's top, and the ground dives under it. Walls in White
        # Forest's two concretes: a band 64 high over the first level's floor (the door's room, a level up, is plain)
        plan = Plan(origin, [(zd - 64, zl, hi), (zl, zl + 64, lo), (zl + 64, zp + 272, hi)], roof=FMAT["bunker_floor"], **look)
        plan.keep_out += [(-100000, -100000, 100000, 0), (-100000, 576, -320, 832)]   # in front of the door; where the deep level joins
        plan.paint((512, 0, 768, 64), ("low", zp, fm, zp + 192))      # the doorway: 256 wide, 192 high
        plan.paint((448, 64, 832, 256), ("low", zp, fm, zp + 208))    # the room inside the door (its front wall is what the door's leaves slide into)
        plan.paint((576, 256, 704, 448), ("low", zl, fm, zp + 160))   # the stairs down
        plan.paint((576, 448, 704, 512), ("low", zl, fm, zl + 160))
        plan.paint((384, 512, 896, 832), ("low", zl, fm, zl + 160))   # the main room
        plan.paint((320, 640, 384, 768), ("low", zl, fm, zl + 128))   # (each doorway between rooms is 128 wide: a frame narrows it to the door's 96)
        plan.paint((64, 576, 320, 832), ("low", zl, fm, zl + 160))    # west: the generator and stores (the way through)
        plan.paint((896, 640, 960, 768), ("low", zl, fm, zl + 128))
        plan.paint((960, 576, 1216, 832), ("low", zl, fm, zl + 160))  # east: the bunks (a dead end)
        plan.paint((0, 640, 64, 768), ("low", zl, fm, zl + 128))      # a door in the generator room's west wall...
        plan.paint((-320, 640, 0, 768), ("low", zd, fm, zl + 160))    # ...and the second stairs, down and west
        plan.walls()
        # the deep level: wholly under the ground (its top is 72 under the gate's floor), so nothing of it shows outside
        deep = Plan(origin, [(zd - 64, zd, hi), (zd, zd + 64, lo), (zd + 64, zd + 224, hi)], **look)
        deep.keep_out += [(-320, 576, 100000, 832), (-100000, 1152, 100000, 100000)]
        room = ("low", zd, fm, zd + 160)
        door = ("low", zd, fm, zd + 128)
        deep.paint((-448, 384, -320, 768), room)       # the foot of the stairs
        deep.paint((-1216, 384, -448, 512), room)      # the passage west
        deep.paint((-704, 512, -576, 576), door)
        deep.paint((-768, 576, -512, 832), room)       # north: the radio room
        deep.paint((-1088, 512, -960, 576), door)
        deep.paint((-1152, 576, -896, 832), room)      # north: the armoury
        deep.paint((-704, 320, -576, 384), door)
        deep.paint((-768, 64, -512, 320), room)        # south: the sick bay
        deep.paint((-1088, 320, -960, 384), door)
        deep.paint((-1152, 64, -896, 320), room)       # south: the stores
        deep.paint((-1280, 384, -1216, 512), door)
        deep.paint((-1600, 256, -1280, 576), room)     # the far end: the plant room
        # the way to the silo (the owner, 21 November: "connect the silo to the bunker so that the silo sits just outside
        # the existing map area"): a door in the radio room's north wall, a corridor north under the ridge and out through
        # the forest's north wall (cut there only), then 15 steps of 16 by 24 down to the silo's gantry level
        deep.paint((-704, 832, -576, 896), door)
        deep.paint((-704, 896, -576, 1152), room)
        deep.walls()
        low = Plan(origin, [(zg - 64, zg, hi), (zg, zg + 64, lo), (zg + 64, zd + 224, hi)], **look)
        low.keep_out += [(-100000, -100000, 100000, 1152), (-100000, 1600, 100000, 100000)]
        low.paint((-704, 1152, -576, 1536), ("low", zg, fm, zd + 160))      # the stairs (their steps are detail)
        low.paint((-704, 1536, -576, 1600), ("low", zg, fm, zg + 160))      # the last of the corridor, as high as the silo's tunnel
        low.walls()
        self.low = low
        # the silo: its west tunnel (now turned to face south) meets the corridor's end at y 1600 of the bunker, its
        # gantry level is the corridor's floor; the forest's north wall is cut where the corridor and its walls pass
        self.silo_at = (origin[0] - 640, origin[1] + 1600 + 544, zg - 1408)
        self.cuts["north"] = (self.B0[0] - 768, self.B0[0] - 512)
        self.plan, self.deep = plan, deep
        self.buildings.append((plan, self.B0, zd - 110))
        self.rooms += [(plan, self.B0), (deep, self.B0)]
        if (self.B0[0] - 320) % PATCH:
            self.problems.append("the foot of the bunker's second stairs is not on a line between two ground patches: the ground would cross the stairwell")

    def height(self, x, y, bias=None):
        # The ground is under the bunker's floors (it "dives") and over the deep level's roof. Where the second stairs run
        # from one into the other it cannot do both, and the first try let it slope across the stairwell (the owner: "the
        # stairs down in the bunker have a ground geometry/brush blocking them"). So the ground is TORN there: along the
        # line at the stairs' foot the patch to the east is under the floor and the patch to the west is the forest's
        # floor above. The slit between them is in the wall that stands on the deep level's roof.
        jx, by = self.B0[0] - 320, self.B0[1]
        if x == jx and bias is not None and bias[0] > jx and by + 640 <= y <= by + 768:
            return self.zd - 110
        return Forest.height(self, x, y, bias)

    def allowed_tears(self):
        return 3

    def natural(self, x, y, bias=None):
        h = self.base_ground(x, y) + self.rim(x, y)
        # the mound the bunker is under: level with its roof, falling away on every side
        bx, by = self.B0
        mound = self.zp + 268 * (1 - smooth(rect_dist(x, y, (bx - 384, by + 448, bx + 1280, by + 1100)) / 400.0))
        h = max(h, mound)
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

    def extra_dirt(self, x, y):
        bx, by = self.B0
        return 255 * (1 - smooth(rect_dist(x, y, (bx + 448, by - 300, bx + 832, by)) / 150.0))

    def bunker(self):
        v, plan, deep, low, zp, zl, zd, zg = self.vmf, self.plan, self.deep, self.low, self.zp, self.zl, self.zd, self.zg
        plan.build(v)
        deep.build(v)
        low.build(v)
        B, W, bx, by = plan.box, plan.world, self.B0[0], self.B0[1]
        vis, wall = self.vis("structures"), FMAT["wf_wall"]
        # where the two parts meet: the stairwell is higher than the deep level's top, so a wall stands on that top
        v.world_box(B(-384, 576, zd + 224, -320, 832, zp + 272), wall, vis=vis)
        # the stairs: 15 steps north down to the first level, 23 west down to the deep one (as the owner walked them), and
        # the silo's 15 steps of 16 by 24 north and down to its gantry level (lesson stairs-16-24), wall to wall
        v.detail([B(576, 256 + 12 * k, zl, 704, 268 + 12 * k, zp - 8 * (k + 1)) for k in range(15)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(-12 * (k + 1), 640, zd, -12 * k, 768, zl - 8 * (k + 1)) for k in range(23)], wall, vis=vis, top=MAT["stairs"])
        v.detail([B(-704, 1152 + 24 * k, zg, -576, 1176 + 24 * k, zd - 16 * (k + 1)) for k in range(15)], wall, vis=vis, top=MAT["stairs"])
        self.door()
        self.room_doors()
        self.silo()
        self.dress()
        for model, x, y, yaw in (("models/props_c17/concrete_barrier001a.mdl", bx + 380, by - 110, 80), ("models/props_c17/concrete_barrier001a.mdl", bx + 920, by - 130, 100),
                                 ("models/props_vehicles/truck001a.mdl", bx + 300, by - 360, 35)):
            self.static(model, x, y, self.natural(x, y), yaw, "structures")
        self.plan_nodes(plan, self.B0, skip=[(576, 256, 704, 448), (-320, 640, 0, 768)])
        self.plan_nodes(deep, self.B0, skip=[(-704, 832, -576, 896)])
        for (u, w, z) in ((640, 296, zp - 32), (640, 364, zp - 72), (640, 420, zp - 116), (-60, 704, zl - 40), (-150, 704, zl - 100), (-240, 704, zl - 160), (-300, 704, zd)):
            self.node(bx + u, by + w, z)
        # the bunker's rooms must be shut in on every side but the doorway (for the look of it, and for the door's areaportal):
        # with the doorway stopped up, air from inside must not reach the forest. The silo and the way to it are inside.
        closed = flood(v, W(640, 160, zp + 64), [B(512, 0, zp, 768, 64, zp + 192)])
        if closed[0] is None or reaches(closed, self.w(self.W / 2, self.D / 2, self.lid - 100)):
            self.problems.append("the bunker's rooms are open to the hill somewhere other than the doorway")
        sx, sy, sz = self.silo_at
        for u, w, z, what in ((640, 672, zl + 64, "main room"), (-384, 576, zd + 64, "foot of the second stairs"), (-1440, 416, zd + 64, "plant room"), (-640, 192, zd + 64, "sick bay"),
                              (-640, 1000, zd + 64, "corridor to the silo"), (-640, 1568, zg + 64, "corridor's end at the silo")):
            if not reaches(closed, W(u, w, z)):
                self.problems.append("the bunker's %s can't be reached from its door" % what)
        for dz, what in ((1408 + 64, "gantry level"), (322 + 64, "bottom level")):
            if not reaches(closed, (sx, sy, sz + dz)):
                self.problems.append("the silo's %s can't be reached from the bunker's door" % what)
        # the deep level and the corridor must stay under the ground
        cover = min(self.natural(bx + (i + 0.5) * CELL, by + (j + 0.5) * CELL) for (i, j) in deep.cells) - (zd + 224)
        if cover < 16:
            self.problems.append("the bunker's deep level comes within %d of the ground's surface" % cover)
        self.notes.append("the bunker: its door at (%d %d), floor z %d; 15 steps down to the first level (z %d: main room, bunks, generator room), 23 more down to the deep level "
                          "(z %d: a passage, radio room, armoury, sick bay, stores, plant room), which is at least %d under the ground; 12 lights" % (
                              self.ox + bx + 640, self.oy + by, zp, zl, zd, cover))
        self.notes.append("the silo: its shaft's axis at (%d %d), from z %d to %d, in a sealed hull just north of the forest's wall; reached from the radio room's north door "
                          "by a corridor (z %d) and 15 steps of 16 by 24 down to its gantry level (z %d)" % (sx, sy, sz - 64, sz + 1792, zd, zg))

    def dress(self):
        """Light and dressing in White Forest's way (ep2_outland_11, 11a, 11b and 12a, counted 21 November): a fluorescent
        fixture (props_lab/lab_flourescentlight001a, 33 under the ceiling as Valve hangs it) over each lit room, in Valve's
        colours: cold 224 254 248 and 193 249 255 in halls and corridors, warm 253 230 159 and 252 241 180 where people
        work, red in the plant room; tube lamps (props_silo/wall_light) and cable runs (prodcables256) on the corridors'
        walls, red caged lamps inside the outer door; and each room's kit as Valve's rooms have it: consoles on a desk,
        servers and a wall console in the radio room and the main room, lockers and footlockers in the armoury, wall
        beds and a sink in the sick bay, shelves and stores, the generator, air plant and switch panels in the plant
        room, bunks and lockers in the bunk room. The same rooms as before are lit and the same left dark. All steady:
        none flickers or flashes (the owner: "get rid of the flickering lights in the bunker ... going to give me or
        someone a seizure"). Furniture whose model is a physics prop is a prop_dynamic_override (a prop_static of one is
        deleted by the compiler, as the bunker's first dressing was), standing solid where it is put."""
        v, W, bx, by = self.vmf, self.plan.world, self.B0[0], self.B0[1]
        zp, zl, zd, zg = self.zp, self.zl, self.zd, self.zg
        vis = self.vis("structures")
        cold, cold2, warm, warm2, red = "224 254 248", "193 249 255", "253 230 159", "252 241 180", "255 64 64"
        lights = ((640, 160, zp + 184, cold, 90), (640, 672, zl + 136, warm, 140), (192, 704, zl + 136, cold2, 90), (-160, 704, zl + 120, cold, 60),
                  (-384, 576, zd + 136, cold, 90), (-832, 448, zd + 136, cold, 70), (-640, 704, zd + 136, warm2, 110), (-1440, 416, zd + 136, red, 120),
                  (-640, 192, zd + 136, cold, 80), (-640, 1000, zd + 136, cold, 70), (-640, 1340, zd + 40, cold, 80), (-640, 1568, zg + 136, cold, 70))
        for (u, w, z, colour, power) in lights:
            v.point("light", W(u, w, z), {"_light": "%s %d" % (colour, power), "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        for (u, w, z) in ((640, 672, zl + 72), (-832, 448, zd + 72), (-1440, 416, zd + 72), (640, 160, zp + 72), (-640, 1000, zd + 72)):
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
        for (u, w, ceil) in ((640, 160, zp + 208), (544, 672, zl + 160), (736, 672, zl + 160), (192, 704, zl + 160), (-384, 576, zd + 160), (-832, 448, zd + 160),
                             (-640, 704, zd + 160), (-640, 192, zd + 160)):
            put("props_lab/lab_flourescentlight001a", u, w, ceil - 33, 0, "f")
        for (u, w, z, yaw) in ((-703, 1000, zd + 120, 0), (-577, 1340, zd + 16, 180), (-703, 1568, zg + 120, 0), (-832, 511, zd + 124, 270), (-832, 385, zd + 124, 90),
                               (-160, 767, zl + 40, 270)):
            put("props_silo/wall_light", u, w, z, yaw, "f")
        for (u, w, z, yaw) in ((480, 65, zp + 150, 90), (800, 65, zp + 150, 90), (-1440, 575, zd + 140, 270)):
            put("props_c17/light_cagelight01_on", u, w, z, yaw, "f")
        for (u, w, z, yaw) in ((-832, 511, zd + 146, 270), (-832, 385, zd + 146, 90), (-577, 1024, zd + 146, 180)):
            put("props_silo/prodcables256", u, w, z, yaw)
        kit = (
            # the room inside the door
            ("props_silo/wall_wires2", 831, 160, zp, 180, "s"), ("props_silo/acunit02", 458, 200, zp + 120, 0, "s"),
            # the main room: a desk of consoles, servers, a wall console, crates
            ("props_wasteland/controlroom_desk001a", 640, 811, zl + 17, 270, "d"), ("props_silo/desk_console3", 610, 811, zl + 34, 270, "s"),
            ("props_silo/desk_console1", 670, 811, zl + 34, 270, "s"), ("props_wasteland/controlroom_chair001a", 640, 768, zl + 20, 90, "d"),
            ("props_silo/silo_server_a", 800, 818, zl, 270, "s"), ("props_silo/silo_server_b", 838, 815, zl, 270, "s"), ("props_silo/wall_console2", 392, 576, zl, 0, "s"),
            ("props_junk/wood_crate001a", 425, 548, zl + 20, 10, "d"), ("props_junk/wood_crate002a", 480, 795, zl + 20, 0, "d"),
            # the bunk room: the east room, a dead end (the owner: "why did you put the bunkroom as a 'walkway' room before the
            # stairs down?"). Each frame (bunkbed) has its mattresses (bunkbed2: Valve's mattress set for it, the same origin
            # and turn; the owner: they were "floating on the other side of the room away from the bunk bed frames")
            ("props_forest/bunkbed", 1150, 805, zl, 270, "s"), ("props_forest/bunkbed2", 1150, 805, zl, 270, "s"),
            ("props_forest/bunkbed", 1030, 805, zl, 270, "s"), ("props_forest/bunkbed2", 1030, 805, zl, 270, "s"),
            ("props_lab/lockers", 1030, 589, zl, 90, "s"), ("props_forest/footlocker01_closed", 1150, 755, zl + 12, 270, "s"), ("props_wasteland/prison_sink001a", 1202, 610, zl + 28, 180, "s"),
            # the generator room: the west room, the way through to the second stairs, so all of it stands against its north
            # and south walls and the line between its two doors (y 656 to 752) stays clear
            ("props_outland/generator_static01a", 125, 608, zl, 0, "s"), ("props_forest/shelves_wood", 256, 593, zl, 90, "s"),
            ("props_silo/electricalbox02", 192, 831, zl, 270, "s"), ("props_silo/tirestack2", 150, 788, zl, 30, "s"), ("props_silo/tirestack3", 215, 788, zl, 0, "s"),
            ("props_silo/barrelwarning", 285, 800, zl, 20, "d"),
            # the radio room: the base's control room, as White Forest's
            ("props_wasteland/controlroom_desk001a", -534, 704, zd + 17, 180, "d"), ("props_silo/desk_console1", -534, 674, zd + 34, 180, "s"),
            ("props_silo/desk_console3", -534, 734, zd + 34, 180, "s"), ("props_wasteland/controlroom_chair001a", -585, 704, zd + 20, 0, "d"),
            ("props_silo/silo_server_a", -754, 640, zd, 0, "s"), ("props_silo/silo_server_b", -750, 678, zd, 0, "s"), ("props_silo/wall_console1", -760, 770, zd, 0, "s"),
            ("props_lab/reciever_cart", -555, 600, zd + 36, 180, "d"),
            # the armoury
            ("props_lab/lockers", -1140, 640, zd, 0, "s"), ("props_lab/lockers", -1140, 690, zd, 0, "s"), ("props_lab/lockers", -1140, 740, zd, 0, "s"),
            ("props_forest/footlocker01_closed", -1000, 817, zd + 12, 270, "s"), ("props_forest/footlocker01_closed", -950, 817, zd + 12, 270, "s"),
            ("props_forest/shelves", -897, 704, zd + 80, 90, "s"), ("props_junk/wood_crate002a", -925, 640, zd + 20, 0, "d"), ("props_junk/wood_crate001a", -925, 710, zd + 20, 25, "d"),
            # the sick bay
            ("props_wasteland/prison_metalbed001a", -720, 75, zd + 20, 90, "s"), ("props_wasteland/prison_metalbed001a", -600, 75, zd + 20, 90, "s"),
            ("props_wasteland/prison_sink001a", -755, 250, zd + 28, 0, "s"), ("props_c17/furnituretable002a", -640, 200, zd + 19, 0, "d"),
            ("props_wasteland/controlroom_storagecloset001a", -530, 250, zd + 44, 180, "d"),
            # the stores
            ("props_forest/shelves_wood", -1135, 160, zd, 0, "s"), ("props_wasteland/kitchen_shelf002a", -1135, 280, zd, 0, "d"), ("props_silo/barrelwarning", -940, 82, zd, 0, "d"),
            ("props_c17/canister01a", -980, 80, zd + 30, 0, "d"), ("props_junk/wood_crate002a", -1050, 100, zd + 20, 90, "d"), ("props_silo/tirestack3", -925, 230, zd, 0, "s"),
            # the plant room
            ("props_outland/generator_static01a", -1500, 515, zd, 270, "s"), ("props_silo/acunit01", -1566, 400, zd + 64, 0, "s"),
            ("props_silo/electricalbox01", -1430, 262, zd, 90, "s"), ("props_silo/tirestack2", -1340, 545, zd, 0, "s"), ("props_lab/powerbox01a", -1295, 300, zd + 60, 180, "s"),
        )
        for model, u, w, z, yaw, kind in kit:
            put(model, u, w, z, yaw, kind)

    # the doors between rooms: (which level, the doorway's squares, the way through it, the side its keypad is NOT on (+1:
    # east or north; the keypad goes on a face with wall beside the doorway), which way the leaf slides into the wall (-1:
    # south or west)). The last is the radio room's north door, to the silo.
    ROOM_DOORS = ((0, (320, 640, 384, 768), "x", -1, -1), (0, (896, 640, 960, 768), "x", 1, -1), (0, (0, 640, 64, 768), "x", -1, -1),
                  (1, (-704, 512, -576, 576), "y", 1, 1), (1, (-1088, 512, -960, 576), "y", 1, -1), (1, (-704, 320, -576, 384), "y", -1, -1),
                  (1, (-1088, 320, -960, 384), "y", -1, -1), (1, (-1280, 384, -1216, 512), "x", 1, -1), (1, (-704, 832, -576, 896), "y", 1, -1))

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
        model only (the door opens by Use, and a keypad that opened it would get round the gamemode's locks)."""
        v, vis = self.vmf, self.vis("bunker room doors")
        frames = []
        for k, (level, (u1, v1, u2, v2), way, room, slide) in enumerate(self.ROOM_DOORS):
            plan = (self.plan, self.deep)[level]
            z = (self.zl, self.zd)[level]
            B, W = plan.box, plan.world
            if way == "x":      # the way through runs east-west: the leaf stands across it, north to south, and slides along y
                a, b, m = v1 + 16, v2 - 16, (u1 + u2) // 2
                frames += [B(u1, v1, z, u2, a, z + 128), B(u1, b, z, u2, v2, z + 128), B(u1, a, z + 124, u2, b, z + 128)]
                leaf, at, yaw, movedir = B(m - 2, a, z, m + 2, b, z + 124), W(m, (a + b) // 2, z), 90, 90 if slide > 0 else 270
                pad = (W(u1 - 1, v1 - 12 if slide > 0 else v2 + 12, z + 52), 180) if room > 0 else (W(u2 + 1, v1 - 12 if slide > 0 else v2 + 12, z + 52), 0)
            else:               # the way through runs north-south: the leaf stands across it, east to west, and slides along x
                a, b, m = u1 + 16, u2 - 16, (v1 + v2) // 2
                frames += [B(u1, v1, z, a, v2, z + 128), B(b, v1, z, u2, v2, z + 128), B(a, v1, z + 124, b, v2, z + 128)]
                leaf, at, yaw, movedir = B(a, m - 2, z, b, m + 2, z + 124), W((a + b) // 2, m, z), 0, 0 if slide > 0 else 180
                pad = (W(u1 - 12 if slide > 0 else u2 + 12, v1 - 1, z + 52), 270) if room > 0 else (W(u1 - 12 if slide > 0 else u2 + 12, v2 + 1, z + 52), 90)
            name = "lc_bunker_room_door_%d" % (k + 1)
            v.brush_entity("func_door", dict(self.SILO_DOOR, **{
                "targetname": name, "movedir": "0 %d 0" % movedir, "wait": "-1", "spawnflags": "288", "forceclosed": "0", "ignoredebris": "1", "loopmovesound": "0",
                "dmg": "0", "health": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
                "renderfx": "0", "disableshadows": "1", "disablereceiveshadows": "0"}), [leaf], MAT["nodraw"], vis,
                connections=[("OnOpen", name + "_model", "SetAnimation", "unlock", 0), ("OnFullyClosed", name + "_model", "SetAnimation", "lock", 0)])
            v.point("prop_dynamic_override", at, {
                "targetname": name + "_model", "model": "models/props_silo/silo_door01.mdl", "angles": "0 %d 0" % yaw, "parentname": name, "skin": "0", "solid": "0",
                "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
                "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}, vis)
            v.point("prop_dynamic", pad[0], {"model": "models/props_lab/keypad.mdl", "angles": "0 %d 0" % pad[1], "solid": "0", "skin": "0", "disableshadows": "1",
                                             "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0"}, vis)
        v.detail(frames, FMAT["wf_trim"], vis=vis)
        self.notes.append("the bunker's rooms: %d of Episode Two's silo doors, sliding as White Forest's (Use slides each 64 into the wall; they start shut)" % len(self.ROOM_DOORS))

    DOOR_SPEED = 6      # the main door's leaves, degrees a second: Valve's own (60 degrees in 10 s)

    def door(self):
        """The bunker's door: White Forest's round blast door (the owner, 21 November: "the bunker/silo doors for whiteforest
        from EP2"), lifted from ep2_outland_11 as the piece valve_ep2_bunker_door: the doors that shut the silo's west
        tunnel in Valve's map. A drum of concrete and steel 224 wide: its lower 160 is two leaves hinged at the inside that
        swing 60 degrees outward at Valve's 6 a second (10 s), with a lock bar in the floor that drops first and rises again
        once they are shut, and Valve's start, loop and end sounds; its top 32 is the drum's fixed head. They stand open.
        A button inside shuts them (a klaxon, a steady red light, the swing, a boom, a shake) and opens them again; nothing
        outside does (the owner, 19 November: "only be opened from the inside"). Each leaf is a func_rot_button used as a
        mover (PressIn swings it open, PressOut shut; with no flags neither Use, touch nor a shot moves it) and the bar a
        func_button, so none of it is a door to the gamemode, whose door rules (kicks, lockpicks, NPCs opening doors) apply
        to func_door, func_door_rotating, func_movelinear and prop_door_rotating: only this wiring moves it. Nothing stops
        it (crusher). If the bunker is left shut with nobody inside, it opens itself after twenty seconds."""
        v, plan, zp = self.vmf, self.plan, self.zp
        B, W = plan.box, plan.world
        vis, dv = self.vis("structures"), self.vis("bunker door (the leaves, the button, the wiring)")
        u1, u2 = self.DOOR
        mid, top = (u1 + u2) // 2, zp + 192
        pf = PF.load("valve_ep2_bunker_door")
        q, d = 1, W(mid, 32, zp)         # Valve's outside (west) to ours (south); the drum's face on the front wall's face
        half = int(pf["size"][1]) // 2
        pf_solids(v, pf, q, d, vis)      # the drum's head, its jambs and hinge posts (detail)
        for a, b in ((u1, mid - half), (mid + half, u2)):      # the doorway filled to the drum each side (world: the areaportal's edges)
            v.world_box(B(a, 0, zp, b, 64, top), FMAT["wf_wall"], vis=vis)
        travel = 60.0 / self.DOOR_SPEED
        for w in pf["wiring"]:
            if w["classname"] != "func_door_rotating":
                continue
            south = w["origin"][1] < 0
            name = "lc_bunker_door_" + ("east" if south else "west")      # (turned, Valve's south leaf is our east one)
            pf_brush_entity(v, "func_rot_button", {
                "targetname": name, "angles": "0 0 0", "distance": "60", "speed": str(self.DOOR_SPEED), "wait": "-1", "lip": "0",
                "spawnflags": str(int(w["keys"]["spawnflags"]) & 2), "sounds": "0", "health": "0", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0",
                "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0", "disableshadows": "0"},
                w["brushes"], q, d, dv, origin=pf_point(w["origin"], q, d))
            # (nothing stops it: the crusher rides the leaf over its own swing and the drum's inside, from its face to 16 past its hinge)
            c = [pf_point(p, q, d) for p in ((-32, -80 if south else 0, 0), (44, 0 if south else 80, 160))]
            crusher(v, name, tuple(int(min(c[0][k], c[1][k])) for k in range(3)) + tuple(int(max(c[0][k], c[1][k])) for k in range(3)), dv, "lc_bunker_crush")
            if south:
                lock = [x for x in pf["wiring"] if x["keys"].get("targetname") == "doorlock_biground_1"][0]
                dl = (d[0], d[1], d[2] - 1)      # (sunk 1 into the floor: only its pins show, and no face lies in the floor's plane)
                pf_brush_entity(v, "func_button", {
                    "targetname": "lc_bunker_lock", "movedir": "90 0 0", "speed": "100", "lip": "0", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
                    "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255",
                    "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, lock["brushes"], q, dl, dv, origin=pf_point(lock["origin"], q, dl))
        v.point("logic_auto", W(mid, 200, zp + 150), {"spawnflags": "1"}, dv,
                connections=[("OnMapSpawn", "lc_bunker_lock", "PressIn", "", 0.4), ("OnMapSpawn", "lc_bunker_door_*", "PressIn", "", 0.5)])
        # an areaportal across the doorway, shut with the leaves, so the bunker is not drawn from outside nor the forest from
        # inside. It stands across the leaves' own swing: a shut door is only drawn from both sides if it is on both sides
        # of its areaportal (the owner, of the first sliding door, which had it behind them: "when they close they become invisible").
        portal = B(mid - half, 31, zp, mid + half, 33, top)
        self.vmf.portals.append(portal)
        v.brush_entity("func_areaportal", {"targetname": "lc_bunker_portal", "StartOpen": "1", "PortalVersion": "1"}, [portal], MAT["portal"], dv)
        # a floor plate 1 thick over the doorway's whole floor, across the areaportal's plane: a detail face belongs to every
        # leaf it touches, so it is drawn from both sides of the shut portal (the owner: with the door shut, "a gap at the
        # leaves' foot" showed the forest ground, because the floor between the leaves and the portal was the outside's
        # and was not drawn from inside). The portal still meets the world's floor under it on its bottom edge.
        v.detail([B(mid - half, 0, zp, mid + half, 64, zp + 1)], FMAT["wf_floor"], vis=vis)

        # sounds (Valve's blast door's own, and the klaxon and groan the owner heard), the red light, the shake
        def sound(name, message, at, loops=False):
            # (spawnflags: 16 starts silent, 32 says "not looped". A sound that loops must NOT have 32: with it the entity
            #  never counts the sound as playing, so StopSound does nothing. The owner: "the closing sound NEVER STOPS".)
            v.point("ambient_generic", at, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": "2200",
                                            "spawnflags": "16" if loops else "48",
                                            "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                            "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        at = W(mid, 32, zp + 96)
        sound("lc_bunker_alarm", "ambient/alarms/klaxon1.wav", W(mid, 100, zp + 170))
        sound("lc_bunker_start", "ep2_outland_11.blastdoors_open_start", at)
        sound("lc_bunker_move", "ep2_outland_11.blastdoors_open_loop", at, loops=True)
        sound("lc_bunker_stop", "ep2_outland_11.blastdoors_open_end", at)
        sound("lc_bunker_slam", "ep2_outland_11.blastdoors_close_end", at)
        sound("lc_bunker_groan", "ambient/materials/metal_stress4.wav", at)
        for pos in (W(mid, -28, zp + 240), W(mid, 150, zp + 190)):
            v.point("light", pos, {"targetname": "lc_bunker_light", "_light": "255 50 30 300", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                   "style": "0"}, dv)
        v.point("env_shake", at, {"targetname": "lc_bunker_shake", "amplitude": "7", "radius": "900", "duration": "1.6", "frequency": "40", "spawnflags": "0"}, dv)
        # the wiring. Shutting: klaxon and light at once, the leaves start a second later and swing for `travel` seconds,
        # then the boom, the groan, the shake, the bar rises and the areaportal shuts.
        end = 1 + travel
        shut = [("OnTrigger", "lc_bunker_close", "Disable", "", 0), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0)]
        shut += [("OnTrigger", "lc_bunker_alarm", "PlaySound", "", round(1.7 * k, 1)) for k in range(int(end / 1.7) + 1)]
        shut += [("OnTrigger", "lc_bunker_door_*", "PressOut", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1),
                 ("OnTrigger", "lc_bunker_crush", "Enable", "", 1), ("OnTrigger", "lc_bunker_crush", "Disable", "", end + 0.3),
                 ("OnTrigger", "lc_bunker_move", "StopSound", "", end), ("OnTrigger", "lc_bunker_slam", "PlaySound", "", end), ("OnTrigger", "lc_bunker_groan", "PlaySound", "", end + 0.1),
                 ("OnTrigger", "lc_bunker_shake", "StartShake", "", end), ("OnTrigger", "lc_bunker_lock", "PressOut", "", end), ("OnTrigger", "lc_bunker_portal", "Close", "", end + 0.2),
                 ("OnTrigger", "lc_bunker_light", "TurnOff", "", end + 2.5), ("OnTrigger", "lc_bunker_open", "Enable", "", end + 2)]
        # Opening: the bar drops first (Valve's), the start sound, the leaves a second later, the end sound as they stop.
        unshut = [("OnTrigger", "lc_bunker_open", "Disable", "", 0), ("OnTrigger", "lc_bunker_light", "TurnOn", "", 0), ("OnTrigger", "lc_bunker_groan", "PlaySound", "", 0),
                  ("OnTrigger", "lc_bunker_lock", "PressIn", "", 0), ("OnTrigger", "lc_bunker_start", "PlaySound", "", 0),
                  ("OnTrigger", "lc_bunker_portal", "Open", "", 0.9), ("OnTrigger", "lc_bunker_door_*", "PressIn", "", 1), ("OnTrigger", "lc_bunker_move", "PlaySound", "", 1),
                  ("OnTrigger", "lc_bunker_move", "StopSound", "", end), ("OnTrigger", "lc_bunker_stop", "PlaySound", "", end), ("OnTrigger", "lc_bunker_light", "TurnOff", "", end + 1),
                  ("OnTrigger", "lc_bunker_close", "Enable", "", end + 2)]
        relay = W(mid, 200, zp + 120)
        v.point("logic_relay", relay, {"targetname": "lc_bunker_close", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=shut)
        v.point("logic_relay", (relay[0] + 16, relay[1], relay[2]), {"targetname": "lc_bunker_open", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=unshut)
        # the button: on the wall inside, west of the stairs; one press works whichever relay is live
        wall_button(v, W(512, 256, zp + 40), 270, "lc_bunker_button", B(506, 246, zp + 36, 526, 256, zp + 64), dv,
                    [("OnPressed", "lc_bunker_close", "Trigger", "", 0), ("OnPressed", "lc_bunker_open", "Trigger", "", 0)], "9")
        # nobody left inside and the door shut: it opens again (the unshutting relay is only live while it is shut). The
        # corridor to the silo and the silo itself count as inside.
        inside = []
        for p, skip in ((self.plan, (u1, 0, u2, 64)), (self.deep, None), (self.low, None)):
            for x1, y1, x2, y2, spec in p.rectangles():
                if spec[0] != "solid" and not (skip and x1 >= skip[0] and x2 <= skip[2] and y1 >= skip[1] and y2 <= skip[3]):
                    inside.append(B(x1, y1, spec[1], x2, y2, spec[3]))
        sx, sy, sz = self.silo_at
        inside.append((sx - 540, sy - 540, sz + 160, sx + 540, sy + 540, sz + 1760))
        v.brush_entity("trigger_multiple", {"targetname": "lc_bunker_inside", "spawnflags": "1", "wait": "1", "StartDisabled": "0"}, inside, MAT["trigger"],
                       self.vis("bunker door's failsafe (delete to let it stay shut when empty)"), connections=[("OnEndTouchAll", "lc_bunker_open", "Trigger", "", 20)])

    # the lift's stops: the silo piece's floors with a landing on the lift shaft, bottom to top (its bottom level, the solid
    # ring's top, the ring slab's top). A floor becomes a stop by adding its height here (with its landing open in the
    # piece): its path point, gate, call button and wiring are all made from this list.
    LIFT_STOPS = (320, 896, 1152)
    LIFT_XY = (-480, 0)          # the lift's track in the piece's frame: 480 from the shaft's axis, which stays clear
    HQ_FOOT, HQ_TOP = 160 + 8, 1408 + 120      # the Resistance flag's markers on the shaft's axis: over the pit grate (160) and the gantry (1408)

    def silo(self):
        """White Forest's rocket silo (the lifted piece valve_ep2_silo: docs/dev/prefabs.md) just outside the forest's north
        wall, turned a quarter so that its west tunnel faces the corridor from the radio room, its gantry level the
        corridor's floor (zg), its lid 192 under the bunker's door. Its world brushes go into the world (they cut up the
        map for visibility as in Valve's own), the rest as detail; sealed in a hull of our own 64 thick (nodraw outside,
        the silo's own concrete inside, so each mouth of the piece Valve's rooms ran on through ends at a plain wall), with
        one opening: where the corridor comes in. Its wiring: the lift (lift(): a stop at every floor in LIFT_STOPS, it
        starts at the top), the ladder from the gantry to the lift's top landing always usable (its hatch removed), the lab
        door at the bottom (the Resistance leader's office) opened and shut by Use, with Valve's lever moved inside to
        lock it; the keypads have names of their own; the steam gate, the areaportals, Valve's story (scenes, NPC makers,
        the autosave, Uriah) and the piece's reserve (the hoisted machine) are left out; the soundscapes are Valve's silo
        ones without the rocket's ignition hisses. Invisible player clips stand in the empty shaft (where the rocket was)
        at the open levels and the gantry, so nobody walks off into a 1,250 drop. Two info_targets on the shaft's axis
        mark the Resistance flag's pole: lc_hq_setup_silo over the pit grate, lc_hq_setup_silo_top 120 over the gantry."""
        v = self.vmf
        sv, wv = self.vis("silo (Valve's White Forest silo)"), self.vis("silo's wiring")
        pf = PF.load("valve_ep2_silo")
        ax, ay, az = self.silo_at
        q, d = 1, (ax, ay, az)
        reserve = set(pf.get("reserve", {}).get("names", ()))
        live = set(w["keys"].get("targetname", "") for w in pf["wiring"]) - {""}
        pf_solids(v, pf, q, d, sv, world=True, skip=lambda s: "taken shut" in s["from"] or s.get("live") in live)
        drop = {"steam_silo1_1", "tr_laddergate_1", "sound_ladder_steam_1", "sound_ladder_steamloop_1", "sound_ladder_lock_1", "door_silo_lab_outside_1_malfunction_timer",
                # the ladder's hatch and the clip over it (the owner: "there is no way to open the gate ... can we just remove that grate?")
                "door_hatch_ladder_1", "pclip_hatch_1",
                # the lab door's keypad relay and beeps (it opens by Use now), the glass over its lever and what breaking it did
                "door_silo_lab_outside_1_door_open_rl", "door_silo_lab_outside_1_open_wav", "door_silo_lab_outside_1_keybeep_wav_1", "door_silo_lab_outside_1_keybeep_wav_2",
                "door_silo_lab_outside_1_keybeep_wav_3", "break_glass_1", "break_glass_1a", "exit_airlock_blastdoor_lever_rl",
                # Valve's lift button, the trigger that locked it, its path: lift() makes them anew
                "button_ele_2", "trigger_unlock_ele", "path_elevator_5", "path_elevator_6", "path_elevator_7", "path_elevator_8"}
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
            if k.get("targetname", "") in drop or e["classname"] == "func_areaportal":
                return False
            if k.get("targetname", "") in reserve or any(k.get(r, "") in reserve for r in ("parentname", "attach1", "attach2")):
                return False        # (the hoist: kept in the piece's reserve, not placed)
            if e["classname"] == "func_button" and tuple(e.get("origin", ())) in lab_pads:
                return False        # (the lab door's keypads are models only now)
            return not (e["classname"] == "trigger_multiple" and any(c[1].startswith("!activator,Kill") for c in e.get("connections", [])))

        # the lab door's lever, moved from the outside niche to the office's wall east of the door, facing into the office:
        # turned a quarter clockwise about its hinge and set there (the owner: "move the little lever mechanism to the inside")
        lo, lo2 = (280, 222, 374), (261, 288, 374)
        r3 = PF.rot(list(lo), 3)
        ld = (lo2[0] - r3[0], lo2[1] - r3[1], lo2[2] - r3[2])

        def indoors(p):
            x, y, z = PF.rot(list(p), 3)
            return [x + ld[0], y + ld[1], z + ld[2]]

        def indoor_brushes(brushes):
            out = []
            for b in brushes:
                nb = []
                for s in b:
                    s = dict(s, plane=[indoors(p) for p in s["plane"]], verts=[indoors(p) for p in s.get("verts", [])],
                             uaxis=PF.turn_axis(s["uaxis"], 3, ld), vaxis=PF.turn_axis(s["vaxis"], 3, ld))
                    if s.get("corners"):
                        s["corners"] = [indoors(p) for p in s["corners"]]
                    nb.append(s)
                out.append(nb)
            return out
        # Valve's silo soundscapes all play "ep2_util.rocket", whose hisses include gascan_ignite1 and ignite.wav every 5 to
        # 15 s (the owner: "a fire sound effect playing over and over on the bottom of the silo"): the same silo's soundscapes
        # from after the rocket left (12a's silo_shut) or of its rooms, which have none
        scapes = {"ep2_silo.silo_top": "ep2_silo.techroom", "ep2_silo.silo_middle": "ep2_silobattle.silo_shut", "ep2_silo.silo_bottom": "ep2_silobattle.silo_shut"}
        top = len(self.LIFT_STOPS) - 1

        def edit(e):
            cls, k = e["classname"], e["keys"]
            tn, o = k.get("targetname", ""), tuple(e.get("origin", ()))
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
            if cls == "env_soundscape" and k.get("soundscape") in scapes:
                k["soundscape"] = "ep2_silo.concreteroom" if o[1] > 200 else scapes[k["soundscape"]]      # (the one by the lab door: a room's)
            if tn == "ladder_hatch_1":
                k["StartDisabled"] = "0"        # (it waited for the hatch to open; with the hatch gone it is always there)
            if tn == "light_hatch_ladder_1":
                k["spawnflags"] = "0"           # (they lit when the hatch opened: now always)
            if tn == "sprite_hatch_ladder_1":
                k["spawnflags"] = "1"
            if tn == "door_silo_lab_outside_1":     # (the Resistance leader's office: Use opens and shuts it, as the bunker's doors)
                k.update({"spawnflags": str(int(k["spawnflags"]) | 256), "wait": "-1", "locked_sound": "DoorHandles.Locked2"})
                e["out"] = [("OnOpen", "prop_door_silo_lab_outside_1", "SetAnimation", "unlock", 0), ("OnFullyClosed", "prop_door_silo_lab_outside_1", "SetAnimation", "lock", 0)]
            if tn == "exit_airlock_blastdoor_lever":     # (a lever, not a door to the gamemode: pulled, it shuts and locks the door; pushed back, unlocks it)
                e["classname"] = "func_rot_button"
                e["keys"] = {"targetname": tn, "angles": "0 0 0", "distance": k["distance"], "speed": k["speed"], "wait": "-1", "spawnflags": str(1024 | 32 | 64), "sounds": "0",
                             "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0", "disableshadows": "0"}
                e["brushes"], e["origin"] = indoor_brushes(e["brushes"]), indoors(e["origin"])
                e["out"] = [("OnPressed", "lab_lever_sound", "PlaySound", "", 0), ("OnIn", "door_silo_lab_outside_1", "Close", "", 0),
                            ("OnIn", "door_silo_lab_outside_1", "Lock", "", 0.1), ("OnOut", "door_silo_lab_outside_1", "Unlock", "", 0)]
            if "panel_lever" in k.get("model", ""):
                a = [float(c) for c in k["angles"].split()]
                e["origin"], k["angles"] = indoors(e["origin"]), "%s %s %s" % (PF.fmt(a[0]), PF.fmt((a[1] + 270) % 360), PF.fmt(a[2]))
            if tn == "lift_2":      # (it starts at the top stop; no crush damage; its own path, made by lift())
                k.update({"target": "lift_stop_%d" % top, "height": "0", "startspeed": "40", "speed": "0", "dmg": "0"})
            if tn == "brush_pclip_lift_2":
                k["StartDisabled"] = "1"
            if tn == "lift_door_2_b":      # (a mover only the wiring moves, not a door to the gamemode)
                e["classname"] = "func_button"
                k.update({"spawnflags": "0", "wait": "-1", "sounds": "0", "health": "0"})
        extra = self.lift() + [{"classname": "ambient_generic", "origin": [261, 300, 384], "keys": {
            "targetname": "lab_lever_sound", "message": "streetwar.drawbridge_lever_start", "health": "10", "pitch": "100", "pitchstart": "100", "radius": "1250", "spawnflags": "48"}}]
        pf_entities(v, pf, q, d, "lc_silo_", sv, wv, keep=keep, edit=edit, extra=extra, valve_anchor=pf["anchor"])
        # the Resistance flag's pole (the owner: raised "from the bottom of the silo" with the flag "flush with eye level on the
        # top floor"): its foot over the pit grate on the shaft's axis, its _top marker 120 over the gantry's floor
        v.point("info_target", (ax, ay, az + self.HQ_FOOT), {"targetname": "lc_hq_setup_silo", "spawnflags": "0"}, wv)
        v.point("info_target", (ax, ay, az + self.HQ_TOP), {"targetname": "lc_hq_setup_silo_top", "spawnflags": "0"}, wv)
        for dz in (1408 + 64, 322 + 64):
            v.point("env_cubemap", (ax, ay + 200, az + dz), {"cubemapsize": "0"}, sv)
        # player clips in the empty shaft: over the solid ring's hole (159), the ring slab's grate's hole (114) and inside
        # the gantry's grates (112 to 159), each a 12-sided column round the axis
        cv, clip = self.vis("silo's player clips (the empty shaft)"), "tools/toolsplayerclip"
        for r, z1, z2 in ((160, 896, 1088), (112, 1152, 1408), (140, 1408, 1760)):
            pts = [(ax + int(round(r * math.cos(math.radians(15 + 30 * k)))), ay + int(round(r * math.sin(math.radians(15 + 30 * k))))) for k in range(12)]
            faces = [([(x, y, az + z2) for x, y in pts], clip), ([(x, y, az + z1) for x, y in reversed(pts)], clip)]
            for k in range(12):
                (xa, ya), (xb, yb) = pts[k], pts[(k + 1) % 12]
                faces.append(([(xa, ya, az + z1), (xb, yb, az + z1), (xb, yb, az + z2), (xa, ya, az + z2)], clip))
            v.world.append(v.convex_text(faces, cv))
        # the hull: the piece's box (1088 square, 1856 high) walled in, 64 thick; its lid as high as the corridor's roof
        T, nd, cw, hv = 64, MAT["nodraw"], FMAT["silo_wall"], self.vis("silo's hull (sealed)")
        x1, y1, z1, x2, y2, z2 = ax - 544, ay - 544, az - 64, ax + 544, ay + 544, az + 1792
        roof = self.zd + 224
        v.world_box((x1 - T, y1 - T, z1 - T, x2 + T, y2 + T, z1), nd, top=cw, vis=hv)
        v.world_box((x1 - T, y1 - T, z2, x2 + T, y2 + T, roof), nd, bottom=cw, vis=hv)
        v.world_box((x1 - T, y1, z1, x1, y2, z2), nd, faces={"east": cw}, vis=hv)
        v.world_box((x2, y1, z1, x2 + T, y2, z2), nd, faces={"west": cw}, vis=hv)
        v.world_box((x1 - T, y2, z1, x2 + T, y2 + T, z2), nd, faces={"south": cw}, vis=hv)
        cx1, cx2, cz = ax - 128, ax + 128, self.zg - 64      # (the corridor's end and its walls fill the south wall's middle)
        v.world_box((x1 - T, y1 - T, z1, cx1, y1, z2), nd, faces={"north": cw}, vis=hv)
        v.world_box((cx2, y1 - T, z1, x2 + T, y1, z2), nd, faces={"north": cw}, vis=hv)
        v.world_box((cx1, y1 - T, z1, cx2, y1, cz), nd, faces={"north": cw}, vis=hv)
        # the forest's north wall where the corridor passes: sky over its roof as the wall's, sealed under its floor
        lx1, lx2 = self.cuts["north"]
        sky, shv = MAT["sky"], self.vis("shell (sky, walls, slab)")
        v.world_box(self.box(lx1, self.D, roof, lx2, self.D + WALL, self.lid), sky, sky, sky, vis=shv)
        v.world_box(self.box(lx1, self.D, self.zg - 80, lx2, self.D + WALL, self.zd - 64), nd, vis=shv)

    def lift(self):
        """The silo's lift, in the piece's frame (named as the piece's: lc_silo_...), as entities for pf_entities. The owner,
        21 November: it starts at the top, "can go to any floor it is called to", each floor's gate shut while the lift is
        elsewhere, a re-usable call button at each floor, and in the car "two different PROPER PROP buttons, one on top of
        the other, and one goes up a floor and the other goes down a floor".
        How it works: Valve's car (lift_2, a func_tracktrain) runs on a path point per stop (lift_stop_N, N counted from
        the bottom; forward is down). A trip to stop N enables every point but the one just past N in the way it goes, so
        the car's path ends at N: it stops exactly there and the point's OnPass fires lift_arrive_N, the only arrival relay
        enabled for that trip (a point passed on the way fires its own, which is off). Which way to go: lift_cmp_N (a
        logic_compare holding the stop the car is at, set on every arrival) against N. While it moves every call relay
        and the car's buttons are off, so a press then does nothing. It sets off only when nobody stands in its doorway
        (a trigger on the car, between its gate and the landing's: lift_clear_dn / _up wait until it is clear). Every
        path point has a speed (a train going backward misbehaves on points whose speed is 0: Valve's wiki), and the one
        under the top starts disabled, so the car stays at the top when the map starts. It does no crush damage, and the
        gates (sliding func_buttons only the wiring moves) stop against whoever is in their way."""
        stops, (lx, ly) = self.LIFT_STOPS, self.LIFT_XY
        n, top = len(stops), len(stops) - 1
        z0 = stops[top]          # (the car is built at its top stop)
        out = []
        spots = iter([(-520 + 16 * (i % 5), -48 + 16 * ((i // 5) % 7), 1290 - 12 * (i // 35)) for i in range(1000)])

        def box(x1, y1, z1, x2, y2, z2, mat):
            sides = []
            for f in FACE_ORDER:
                p = face_corners((x1, y1, z1, x2, y2, z2), f)
                u, w = FACE_AXES[f]
                sides.append({"plane": [list(c) for c in p[:3]], "verts": [list(c) for c in p], "material": mat.upper(), "uaxis": u, "vaxis": w, "lightmapscale": "16"})
            return sides

        def ent(cls, keys, outs=(), at=None, brush=None):
            e = {"classname": cls, "origin": list(at or next(spots)), "keys": keys, "out": list(outs)}
            if brush:
                e["brushes"] = [box(*brush)]
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
            ent("path_track", {"targetname": "lift_stop_%d" % k, "target": "lift_stop_%d" % (k - 1) if k else "", "speed": "40", "spawnflags": "1" if k == top - 1 else "0",
                               "orientationtype": "0", "angles": "0 0 0"}, [("OnPass", "lift_arrive_%d" % k, "Trigger", "", 0)], at=(lx, ly, z))
            # arriving: the gates open, the car's buttons and every call work again
            arrive = [("OnTrigger", "lift_arrive_%d" % k, "Disable", "", 0), ("OnTrigger", "lift_2", "Stop", "", 0), ("OnTrigger", "lift_cmp_*", "SetValue", str(k), 0),
                      ("OnTrigger", "lift_gate_%d" % k, "PressIn", "", 1), ("OnTrigger", "lift_door_2_b", "PressIn", "", 1), ("OnTrigger", "prop_eledoor_4", "SetAnimation", "open", 1),
                      ("OnTrigger", "brush_pclip_lift_2", "Disable", "", 1), ("OnTrigger", "sprite_ele_2", "Color", "255 170 43", 1), ("OnTrigger", "lift_call_*", "Enable", "", 2)]
            arrive += [("OnTrigger", "lift_up_from_%d" % k, "Enable", "", 2)] if k < top else []
            arrive += [("OnTrigger", "lift_dn_from_%d" % k, "Enable", "", 2)] if k > 0 else []
            relay("lift_arrive_%d" % k, arrive, off=k != top)
            # a call: which way, from the stop the car is at
            relay("lift_call_%d" % k, [("OnTrigger", "lift_cmp_%d" % k, "Compare", "", 0)])
            ent("logic_compare", {"targetname": "lift_cmp_%d" % k, "InitialValue": str(top), "CompareValue": str(k)},
                [("OnEqualTo", "lift_here_%d" % k, "Trigger", "", 0)] + ([("OnLessThan", "lift_up_to_%d" % k, "Trigger", "", 0)] if k > 0 else [])
                + ([("OnGreaterThan", "lift_dn_to_%d" % k, "Trigger", "", 0)] if k < top else []))
            relay("lift_here_%d" % k, [("OnTrigger", "lift_gate_%d" % k, "PressIn", "", 0), ("OnTrigger", "lift_door_2_b", "PressIn", "", 0)])
            # setting off: everything off, the path ends at this stop, the gates shut, then it goes once the doorway is clear
            for name, past, branch in (("lift_dn_to_%d" % k, k - 1, "lift_clear_dn"), ("lift_up_to_%d" % k, k + 1, "lift_clear_up")):
                if (branch == "lift_clear_dn" and k == top) or (branch == "lift_clear_up" and k == 0):
                    continue
                go = [("OnTrigger", "lift_call_*", "Disable", "", 0), ("OnTrigger", "lift_up_from_*", "Disable", "", 0), ("OnTrigger", "lift_dn_from_*", "Disable", "", 0),
                      ("OnTrigger", "lift_stop_*", "EnablePath", "", 0), ("OnTrigger", "lift_arrive_%d" % k, "Enable", "", 0)]
                go += [("OnTrigger", "lift_stop_%d" % past, "DisablePath", "", 0.1)] if 0 <= past <= top else []
                go += [("OnTrigger", "lift_gate_*", "PressOut", "", 0), ("OnTrigger", "lift_door_2_b", "PressOut", "", 0), ("OnTrigger", "prop_eledoor_4", "SetAnimation", "close", 0),
                       ("OnTrigger", "sprite_ele_2", "Color", "255 10 10", 0), ("OnTrigger", "sound_elevator_startup_1", "PlaySound", "", 0),
                       ("OnTrigger", "sound_elevator_startup_1", "StopSound", "", 2.2), ("OnTrigger", branch, "Test", "", 2)]
                relay(name, go)
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
                [("OnFalse", "lift_2", way, "", 0), ("OnFalse", "brush_pclip_lift_2", "Enable", "", 0), ("OnTrue", branch, "Test", "", 1)])
        # the car's doorway, between its gate and the landing's: somebody there holds it
        ent("trigger_multiple", {"targetname": "lift_doorway", "parentname": "lift_2", "spawnflags": "1", "wait": "0.1", "StartDisabled": "0"},
            [("OnStartTouchAll", "lift_clear_*", "SetValue", "1", 0), ("OnEndTouchAll", "lift_clear_*", "SetValue", "0", 0)], brush=(-419, -40, z0, -391, 40, z0 + 72, MAT["trigger"]))
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
                    self.static(rnd.choice(SHORE), x, y, h - 2, rnd.randrange(0, 360, 5), "rocks, plants and fallen wood", solid=0, fade=(1500, 2000))
                    n += 1
                    break
        top = self.natural(ix, iy)
        self.static("models/props_foliage/tree_pine04.mdl", ix, iy, top - 8, 40, "trees")
        self.static("models/props_foliage/forestrock_single01.mdl", ix + 46, iy - 30, self.natural(ix + 46, iy - 30) - 8, 120, "rocks, plants and fallen wood")
        self.static("models/props_foliage/driftwood_01a.mdl", cx - rx * 0.86, cy + ry * 0.35, self.level - 2, 70, "rocks, plants and fallen wood")
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
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
    return f.vmf, f.problems


# ---------------------------------------------------------------------------
# The cave, and the stream that runs out of it
# ---------------------------------------------------------------------------

class NestTube:
    """The antlion nest's passage: the cave's own kind of skin (rows across a square tube that runs north, hung wider where
    the passage runs aslant), with a floor that falls. y0 is where it starts, at the emergency door's bulkhead."""
    HALF, TALL, LONG = 160, 320, 2560

    def __init__(self, bcx, y0, zf, seed):
        self.bcx, self.y0, self.zf, self.seed = bcx, y0, zf, seed

    def mid(self, y):
        t = y - self.y0
        return self.bcx + 448 * smooth((t - 256) / 600.0) - 832 * smooth((t - 1000) / 700.0)

    def lean(self, y):
        k = (self.mid(y + 4) - self.mid(y - 4)) / 8.0
        return math.sqrt(1 + k * k)

    def base(self, y):
        """The floor's height: down 160 over the first 700, a little more before the last chamber."""
        t = y - self.y0
        return self.zf - 160 * smooth((t - 128) / 700.0) - 32 * smooth((t - 1700) / 300.0)

    def radius(self, y):
        t = y - self.y0
        r = 150 + 180 * smooth((t - 420) / 180.0) * smooth((1280 - t) / 180.0) + 140 * smooth((t - 1690) / 160.0)
        return r * (1 - 0.35 * smooth((t - (self.LONG - 130)) / 130.0))

    def floor(self, x, y):
        return self.base(y) + 6 * noise(x / 80.0, y / 80.0, self.seed + 1) * smooth((y - self.y0) / 64.0)

    def ring(self, theta, y):
        t = y - self.y0
        R = self.radius(y)
        r = R * (1 + 0.22 * noise(math.cos(theta) * 1.6 + y / 150.0, math.sin(theta) * 1.6 - y / 210.0, self.seed + 2))
        x = self.mid(y) + 1.15 * r * math.cos(theta) * self.lean(y)
        z = max(self.base(y) + 0.51 * R + 0.85 * r * math.sin(theta), self.floor(x, y))
        if t <= 0:
            return (x, self.y0 - 6, z)                 # the first ring ends 6 inside the bulkhead
        edge = smooth(t / 64.0) * smooth((self.LONG - t) / 64.0)
        return (x, y + 14 * edge * noise(theta * 2.0 + 3, y / 90.0, self.seed + 3), z)

    def on_square(self, xn, zn, y):
        return self.ring(math.atan2(zn - self.TALL / 2.0, xn), y)


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
    CHAMBER = (1728, 2368)              # past the bend: the wide chamber the mine office is in
    OFFICE = (1792, 2304)               # the office's front, along the chamber's east wall (two of the skin's 256 pieces)
    FRONT, FRONT_HIGH = 256, 192        # that front: this far east of the chamber's middle, and this high
    SPRING = 2624                       # how far in the spring is: a low slot in the west wall the stream runs out of
    HALF, TALL = 160, 320               # the square the cave's skin is hung on
    TEAR = 640                          # the hillside is cut this far each side of the mouth
    NEST_WARNING = 11                   # seconds from opening the emergency door to the first antlions: the alarm at the breach sounds meanwhile
    LIFT_SPEED = 96                     # the lift's speed: about 13.5 s from top to foot (Valve's mine lift goes at 35)
    DEEP = 1296                         # the lower workings' floor is this far below the shaft head's (three of Episode Two's shaft cribbings)
    FOOT_DOOR_X = 1216                  # (local x) the shaft foot's north doorway
    ROOM = (512, 768)                   # the shaft head: a mine room after the old mine (across, along)
    GALLERY_Y = 7616                    # (local y) the gallery from the shaft head west to Ravenholm's big cave
    BIG_CAVE_X = 512                    # (local x) the big cave's mouth, on the west face of its joint
    MINE, BREACH = 1280, 64             # behind the emergency door: Ravenholm's mine tunnel (lifted), then the wall the antlions broke through

    def setup(self):
        z0 = self.z0
        self.zf = z0 + 30                # the cave's floor and the ground before it
        self.level = self.zf - 16        # the stream's surface
        cx, ym = self.CX, self.YM
        self.D = 5632                    # (1536 longer than a forest usually is: the cave runs on north under its hill)
        self.front_x = cx + self.BEND[2] + self.FRONT
        self.end_x = cx + self.BEND[2]                                  # the passage's middle where it ends, at the emergency door
        self.cuts["north"] = (self.end_x - 640, self.end_x + 640)       # the bulkhead that door is in
        self.nest_tube = NestTube(self.end_x, self.D + WALL + self.MINE + 64 + self.ROOM[1] + 64, self.zf + 16, self.seed + 40)
        rx = self.end_x + self.ROOM[0] / 2 - 32 - 192        # the lift's shaft, in the shaft head's east side
        ry = self.D + WALL + self.MINE + 64 + 128
        self.shaft_rect = (rx, ry, rx + 192, ry + 192)
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
        """The mine office (the owner: "a small mining office/shack on the inside ... a few rooms large; it still needs to be
        reasonably big enough for a small rebel base"): four rooms built into the rock behind the chamber's east wall. Its
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
        # (7: it lies on the ground before the cave), the edge of the hole the mine office's front fills (42: it is in
        # the front's own wall: 14 along the floor, 14 along the roof, 7 up each end), and the two rings that end in the
        # emergency door's bulkhead, the cave's last and the nest's first (28 each)
        return 67 + 7 + 42 + 28 + 28

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
        # wider at the spring, and wide again at the end: the room before the emergency door
        return (175 - 35 * (1 - smooth(s / 220.0)) - 15 * smooth((s - (s1 - 150)) / 150.0) * smooth((s2 + 150 - s) / 150.0)
                + 130 * self.in_chamber(y) + 55 * smooth(1 - abs(s - self.SPRING) / 220.0) + 165 * smooth((s - (self.LONG - 400)) / 220.0))

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
        if xn == self.HALF:
            # the mine office's front: along it the east wall's points lie flat, 4 inside the front's own wall (it is 8 thick), from the floor
            # to FRONT_HIGH. That piece of the skin is left out (the wall with its doorway and windows stands there), so the
            # floor's and the roof's edges and the rock at each end all end in that wall. Beyond each end the rock eases back
            # to its own shape over 128.
            a, b = self.YM + self.OFFICE[0], self.YM + self.OFFICE[1]
            out = max(a - y, 0, y - b)
            if out < 128:
                q = (self.front_x + 4, y if out == 0 else p[1], self.zf + zn * self.FRONT_HIGH / float(self.TALL))
                p = q if out == 0 else tuple(lerp(p[k], q[k], 1 - smooth(out / 128.0)) for k in range(3))
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
        o1, o2 = self.OFFICE
        for k in range(self.LONG // seg):
            y0 = ym + k * seg
            c = under(y0 + seg / 2)
            face((c - H, y0, zf - 16, c + H, y0 + seg, zf), "top", lambda i, j, y0=y0: self.on_square(-H + 40 * j, 0, y0 + 32 * i))
            face((c - H, y0, zf + T, c + H, y0 + seg, zf + T + 16), "bottom", lambda i, j, y0=y0: self.on_square(-H + 40 * i, T, y0 + 32 * j))
            face((c - H - 16, y0, zf, c - H, y0 + seg, zf + T), "east", lambda i, j, y0=y0: self.on_square(-H, 40 * i, y0 + 32 * j))
            if not o1 <= k * seg < o2:
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
        dress = ((-300, 70, "models/cliffs/rocks_medium01.mdl"), (290, 60, "models/cliffs/rockcluster01.mdl"), (-520, 80, "models/cliffs/rocks_large01.mdl"),
                 (500, 70, "models/cliffs/rockcluster02.mdl"), (-410, 130, "models/props_foliage/forestrock_cluster01.mdl"), (380, 140, "models/props_foliage/forestrock_cluster02.mdl"),
                 (-250, 150, "models/props_foliage/forestrock_single01.mdl"), (255, 170, "models/props_wasteland/rockgranite02a.mdl"), (-600, 150, "models/cliffs/rocks_large02.mdl"),
                 (610, 130, "models/cliffs/rocks_large03.mdl"))
        for (dx, out, model) in dress:
            x, y = cx + dx, ym - out
            self.static(model, x, y, self.natural(x, y) - 14, rnd.randrange(0, 360, 15), "cave")
        for k in range(16):
            dx = rnd.choice((-1, 1)) * rnd.uniform(235, 640)
            x, y = cx + dx, ym - rnd.uniform(40, 190)
            self.static(rnd.choice(PLANTS), x, y, self.natural(x, y) - 2, rnd.randrange(0, 360, 5), "cave", solid=0, fade=(1500, 2000))
        self.fence_gate()
        self.mine_office()
        self.bulkhead()
        self.mine()
        self.nest()
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
        self.notes.append("line of sight: a straight line from anywhere outside the mouth reaches at most %d in; the chamber and the mine office begin %d in" % (far, self.CHAMBER[0]))
        self.notes.append("the spring: a slot in the west wall at (%d %d), %d deep and %d from floor to roof (a crouched player is 36), the water %d deep in it" % (
            self.ox + lip[0], self.oy + ys, lip[0] - back_top[0], slot_high, self.level - back_low[2]))
        self.notes.append("the stream: surface z %d, from the spring, down the cave, out of the mouth, to a sink pool at (%d %d); a trail fords it" % (
            self.level, self.ox + self.sink[0], self.oy + self.sink[1]))

    def mine_office(self):
        v, zf, plan = self.vmf, self.zf, self.office
        ax, ay = self.office_at
        B, PW = plan.box, plan.world
        ov = self.vis("mine office")
        plan.build(v)
        # the thin walls: the front is world brush (the areaportals in its openings need it), the rest detail
        top = zf + 144
        for (way, line, a, b, holes, front) in self.office_walls:
            def piece(p, q, z1, z2):
                return B(line, p, z1, line + 8, q, z2) if way == "v" else B(p, line, z1, q, line + 8, z2)
            pieces, at = [], a
            for (h1, h2, z1, z2) in sorted(holes):
                if h1 > at:
                    pieces.append(piece(at, h1, zf, top))
                if z1 > zf:
                    pieces.append(piece(h1, h2, zf, z1))
                pieces.append(piece(h1, h2, z2, top))
                at = h2
            if at < b:
                pieces.append(piece(at, b, zf, top))
            if front:
                for box in pieces:
                    v.world_box(box, FMAT["office_wall"], vis=ov)
            else:
                v.detail(pieces, FMAT["office_wall"], vis=ov)
        # timber round the front's door and windows, standing 8 proud of the boards
        tm = FMAT["timber"]
        v.detail([B(-8, 220, zf, 0, 232, zf + 120), B(-8, 280, zf, 0, 292, zf + 120), B(-8, 220, zf + 108, 0, 292, zf + 120)], tm, vis=ov)
        for v1 in (64, 384):
            v.detail([B(-6, v1 - 8, zf + 40, 0, v1 + 72, zf + 48), B(-6, v1 - 8, zf + 112, 0, v1 + 72, zf + 120)], tm, vis=ov)
        # an areaportal in the front's door and each window (always open: they only narrow what is drawn through them)
        for (u1, v1, z1, u2, v2, z2) in self.office_holes:
            v.areaportal(B(3, v1, z1, 5, v2, z2), self.vis("areaportals"))
        # doors (the owner: "please add simple doors to the mining shack"): the city's own door, as the owner's map has it
        # 134 times, hinged at the south or west side of each opening. (pos, yaw: 0 the door runs north from its hinge, 270 east)
        for (u, w, yaw) in ((4, 232, 0), (480, 72, 0), (480, 392, 0), (328, 516, 270)):
            pos = PW(u, w, zf + 54)
            v.point("prop_door_rotating", pos, {
                "model": "models/props_c17/door01_left.mdl", "angles": "0 %d 0" % yaw, "ajarangles": "0 0 0", "axis": "%d %d %d, %d %d %d" % (pos + pos), "distance": "90",
                "dmg": "0", "fademindist": "-1", "fadescale": "1", "forceclosed": "0", "hardware": "1", "health": "0", "opendir": "0", "rendercolor": "255 255 255",
                "returndelay": "-1", "skin": "7", "spawnflags": "8192", "spawnpos": "0", "speed": "100"}, self.vis("mine office doors"))
        # light: a lamp over the door outside, one in each room (the bunk room dim)
        for (u, w, up, colour) in ((-60, 256, 176, "255 205 150 130"), (240, 256, 132, "255 214 170 160"), (660, 140, 130, "255 200 150 50"),
                                   (660, 400, 130, "225 235 255 80"), (384, 650, 130, "255 190 130 100")):
            v.point("light", PW(u, w, zf + up), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("env_cubemap", PW(240, 256, zf + 72), {"cubemapsize": "0"}, ov)
        # what is in it (every one compiled as a static prop)
        things = (
            ("models/props_wasteland/controlroom_desk001a.mdl", 436, 256, 90), ("models/props_wasteland/controlroom_chair001a.mdl", 376, 256, 270),
            ("models/props_wasteland/controlroom_filecabinet002a.mdl", 400, 482, 180), ("models/props_c17/furnituretable002a.mdl", 170, 410, 0),
            ("models/props_forest/stove01.mdl", 56, 476, 0), ("models/props_c17/lockers001a.mdl", 300, 28, 0), ("models/props_junk/wood_crate001a.mdl", 60, 48, 20),
            ("models/props_forest/bunkbed.mdl", 600, 242, 90), ("models/props_forest/bunkbed.mdl", 730, 242, 90), ("models/props_forest/footlocker01_closed.mdl", 600, 36, 0),
            ("models/props_forest/footlocker01_closed.mdl", 730, 36, 0),
            ("models/props_forest/shelves_wood.mdl", 800, 350, 270), ("models/props_forest/shelves_wood.mdl", 800, 450, 270), ("models/props_junk/wood_crate001a.mdl", 540, 470, 20),
            ("models/props_junk/wood_crate001a.mdl", 612, 478, 65), ("models/props_junk/wood_crate002a.mdl", 570, 340, 30), ("models/props_c17/oildrum001.mdl", 700, 330, 15),
            ("models/props_c17/furnituretable002a.mdl", 384, 716, 0), ("models/props_wasteland/controlroom_chair001a.mdl", 384, 660, 0),
            ("models/props_wasteland/kitchen_shelf002a.mdl", 478, 640, 270),
        )
        for model, u, w, yaw in things:
            self.static(model, ax + u, ay + w, zf, yaw, "mine office", fade=(-1, 0))
        # left outside it in the chamber: a cart, cut timber
        for model, x, y, yaw in (("models/props_mining/flatbed_cart01.mdl", ax - 130, ay - 150, 80), ("models/props_mining/wood_stack.mdl", ax - 120, ay + 600, 10)):
            self.static(model, x, y, self.cave_floor(x, y), yaw, "mine office", fade=(-1, 0))
        for (u, w) in ((-90, 256), (40, 256), (120, 120), (120, 400), (300, 256), (420, 96), (420, 416), (540, 96), (680, 150), (540, 416), (680, 400),
                       (352, 470), (352, 560), (400, 660)):
            self.node(ax + u, ay + w, zf)
        # the rooms must be shut in but for the front's door and windows; every room reached from the front room; the hill
        # over all of it; and none of the cave's skin in a room's air
        stops = [B(*hole) for hole in self.office_holes]
        closed = flood(v, PW(240, 256, zf + 64), stops)
        if closed[0] is None or reaches(closed, self.w(self.W / 2, 600, self.lid - 100)):
            self.problems.append("the mine office is open to the hill somewhere other than its door and windows")
        for u, w, what in ((660, 140, "bunk room"), (660, 400, "store"), (384, 650, "back room")):
            if not reaches(closed, PW(u, w, zf + 64)):
                self.problems.append("the mine office's %s can't be reached from its front room" % what)
        cover = min(self.natural(ax + (i + 0.5) * CELL, ay + (j + 0.5) * CELL, (0, 9999)) for (i, j) in plan.cells) - (zf + 224)
        if cover < 40:
            self.problems.append("the mine office's roof comes within %d of the hill's surface" % cover)
        poking = 0
        for m in v.disp_made:
            if m[0] != self.vis("cave"):
                continue
            for pt in m[1]:
                u, w = pt[0] - self.ox - ax, pt[1] - self.oy - ay
                spec = plan.cells.get((int(u // CELL), int(w // CELL)))
                if spec and spec[0] != "solid" and spec[1] + 2 < pt[2] < spec[3] - 2 and u > 8:
                    poking += 1
        if poking:
            self.problems.append("%d points of the cave's skin are inside the mine office's rooms" % poking)
        self.notes.append("the mine office: its front along the chamber's east wall from (%d %d) to (%d %d), floor z %d; walls 8 thick; a front room about 470 by 510, "
                          "a bunk room 350 by 280, a store 350 by 220 and a back room 256 by 250; 4 doors (the city's own), 2 windows; at least %d of hill over its roof" % (
                              self.ox + ax, self.oy + ay, self.ox + ax, self.oy + ay + self.OFFICE[1] - self.OFFICE[0], zf, cover))

    # --- the emergency door, and the antlion nest behind it ---------------------------

    def skin(self, box, name, point, mat, vis, tex=0.25, dirt=None):
        """One displaced face of a skin: the face `name` of `box`, its points from point(i, j)."""
        pts = {}

        def target(i, j):
            pts[(i, j)] = point(i, j)
            return self.w(*pts[(i, j)])

        def alpha(i, j):
            return dirt(pts[(i, j)]) if dirt else 0
        self.vmf.world_box(self.box(*box), MAT["nodraw"], vis=vis, faces={name: mat}, disp={name: (3, target, alpha)}, tex=tex)

    def bulkhead(self):
        """The emergency door (the owner: "an emergency door that has sealed the rest of the cave off ... requires two buttons
        to be pushed simultaneously (within 1 second of each other) that cannot be pushed by a single person"): a concrete
        bulkhead in the forest's north wall where the cave ends, a steel shutter in it that lifts into the wall, and a button
        on the bulkhead each side of it, 480 apart with a wall standing out between each and the door, so the way from one
        to the other is about 700: nobody presses both inside a second. Each press counts for one second (a math_counter);
        two at once work the door, open or shut. The shutter is a func_button used as a mover, as the bunker's leaves are."""
        v, zf, D, T = self.vmf, self.zf, self.D, WALL
        bx = self.end_x
        x1, x2 = self.cuts["north"]
        top, high = zf + 704, 160
        B, W = self.box, self.w
        cw, steel, rib = MAT["canal_wall"], FMAT["door"], MAT["bars"]
        sv, dv = self.vis("shell (sky, walls, slab)"), self.vis("nest door (the shutter, the two buttons, the wiring)")
        v.world_box(B(x1, D, self.zb, bx - 96, D + T, top), cw, vis=sv)
        v.world_box(B(bx + 96, D, self.zb, x2, D + T, top), cw, vis=sv)
        v.world_box(B(bx - 96, D, zf + high, bx + 96, D + T, top), cw, bottom=MAT["ceiling"], vis=sv)
        v.world_box(B(bx - 96, D, self.zb, bx + 96, D + T, zf), cw, top=FMAT["bunker_floor"], vis=sv)
        v.world_box(B(x1, D, top, x2, D + T, self.lid), MAT["sky"], vis=sv)
        under = min(self.natural(x, D, (0, 0)) for x in range(x1, x2 + 1, 64)) - top
        if under < 8:
            self.problems.append("the emergency door's bulkhead stands %d out of the hill" % -under)
        # a frame round the doorway, and the two walls that stand out from the bulkhead between the door and each button
        v.detail([B(bx - 112, D - 8, zf, bx - 96, D, zf + high + 16), B(bx + 96, D - 8, zf, bx + 112, D, zf + high + 16), B(bx - 112, D - 8, zf + high, bx + 112, D, zf + high + 16)],
                 MAT["beam"], vis=dv)
        v.detail([B(bx - 128, D - 224, zf - 16, bx - 112, D - 8, zf + 144), B(bx + 112, D - 224, zf - 16, bx + 128, D - 8, zf + 144)], cw, vis=dv)
        # the shutter, drawn shut; pressed in, it is up in the wall with 8 showing
        parts = [(B(bx - 96, D + 44, zf, bx + 96, D + 68, zf + high), steel)]
        for z in (20, 76, 132):
            parts.append((B(bx - 96, D + 40, zf + z, bx + 96, D + 44, zf + z + 8), rib))
            parts.append((B(bx - 96, D + 68, zf + z, bx + 96, D + 72, zf + z + 8), rib))
        v.brush_entity("func_button", {
            "targetname": "lc_nest_door", "movedir": "-90 0 0", "speed": "30", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
            "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0", "min_use_angle": "0.8",
            "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disablereceiveshadows": "0"}, parts, steel, dv)
        crusher(v, "lc_nest_door", B(bx - 96, D + 40, zf - 14, bx + 96, D + 72, zf + 2), dv, "lc_nest_crush")
        # an areaportal in it, shut while it is: the nest is not drawn, nor the cave from the nest
        portal = B(bx - 96, D + 55, zf, bx + 96, D + 57, zf + high)      # (inside the shutter's own thickness: see the bunker's)
        v.portals.append(portal)
        v.brush_entity("func_areaportal", {"targetname": "lc_nest_portal", "StartOpen": "0", "PortalVersion": "1"}, [portal], MAT["portal"], dv)
        # the two buttons, each with a lamp that shows for the second its press counts
        for side, tag in ((-1, "a"), (1, "b")):
            ux = bx + side * 240
            v.point("env_sprite", W(ux, D - 10, zf + 84), {"targetname": "lc_nest_lamp_" + tag, "model": "sprites/glow06.spr", "rendermode": "9", "renderamt": "255",
                                                             "rendercolor": "120 255 120", "scale": ".35", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                             "renderfx": "0", "spawnflags": "0"}, dv)
            wall_button(v, W(ux - 4, D, zf + 44), 270, "lc_nest_button_" + tag, B(ux - 10, D - 10, zf + 40, ux + 10, D, zf + 68), dv,
                        [("OnPressed", "lc_nest_count", "Add", "1", 0), ("OnPressed", "lc_nest_count", "Subtract", "1", 1),
                         ("OnPressed", "lc_nest_lamp_" + tag, "ShowSprite", "", 0), ("OnPressed", "lc_nest_lamp_" + tag, "HideSprite", "", 1),
                         ("OnPressed", "lc_nest_blip", "PlaySound", "", 0)], "1.2")
        # (the bulkhead must be bare where the buttons are: the rock's skin ends on it further out)
        for k in range(0, 129):
            p = self.ring(k * math.pi / 64, self.YM + self.LONG)
            if zf + 30 < p[2] < zf + 110 and abs(p[0] - bx) < 276:
                self.problems.append("the rock at the emergency door comes within %d of its middle at button height: a button would be behind it" % abs(p[0] - bx))
                break
        at = W(bx, D - 40, zf + 120)

        def sound(name, message, pos, radius="2200", loops=False):
            v.point("ambient_generic", pos, {"targetname": name, "message": message, "health": "10", "pitch": "100", "pitchstart": "100", "radius": radius,
                                             "spawnflags": "16" if loops else "48",
                                             "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0",
                                             "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, dv)
        sound("lc_nest_blip", "Buttons.snd17", W(bx, D - 30, zf + 60), "700")
        sound("lc_nest_alarm", "ambient/alarms/klaxon1.wav", W(bx, D - 60, zf + 200))
        sound("lc_nest_move", "Streetwar.d3_c17_11_garage_move1", at, loops=True)
        sound("lc_nest_slam", "Streetwar.d3_c17_11_garage_stop1", at)
        v.point("light", W(bx, D - 70, zf + 190), {"targetname": "lc_nest_light", "_light": "255 50 30 300", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "spawnflags": "1",
                                                   "style": "0"}, dv)
        v.point("env_shake", at, {"targetname": "lc_nest_shake", "amplitude": "6", "radius": "900", "duration": "1.4", "frequency": "40", "spawnflags": "0"}, dv)
        v.point("math_counter", W(bx, D - 30, zf + 110), {"targetname": "lc_nest_count", "startvalue": "0", "min": "0", "max": "2", "StartDisabled": "0"}, dv,
                connections=[("OnHitMax", "lc_nest_open", "Trigger", "", 0), ("OnHitMax", "lc_nest_shut", "Trigger", "", 0)])
        # the wiring: the shutter takes about five seconds each way. lc_nest_opened and lc_nest_closed are fired so the
        # gamemode can hear what happened (nothing in the map listens to them).
        opening = [("OnTrigger", "lc_nest_open", "Disable", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 1.7),
                   ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 3.4), ("OnTrigger", "lc_nest_light", "TurnOn", "", 0), ("OnTrigger", "lc_nest_portal", "Open", "", 1.4),
                   ("OnTrigger", "lc_nest_door", "PressIn", "", 1.5), ("OnTrigger", "lc_nest_move", "PlaySound", "", 1.5), ("OnTrigger", "lc_nest_opened", "Trigger", "", 1.5),
                   ("OnTrigger", "lc_nest_move", "StopSound", "", 6.6), ("OnTrigger", "lc_nest_slam", "PlaySound", "", 6.6), ("OnTrigger", "lc_nest_shake", "StartShake", "", 6.6),
                   ("OnTrigger", "lc_nest_light", "TurnOff", "", 9), ("OnTrigger", "lc_nest_shut", "Enable", "", 9)]
        # the alarm at the breach (Episode Two's post, CaveForest.mine): the siren and all three lamps when the door is
        # opened, the antlions 11 s later (the owner, 21 November: "20 seconds is too long; let's do 11 seconds. This is
        # triggered by the players so they know what they are getting into already"). The first antlion out stops the
        # siren (makers in nest()); the lamps stay lit while the door is open.
        opening += [("OnTrigger", "lc_nest_mouth_1_siren", "PlaySound", "", 0)] + [("OnTrigger", "lc_nest_mouth_1_lamp_%d" % k, "LightOn", "", 0.3 * (k - 1)) for k in (1, 2, 3)]
        opening += [("OnTrigger", "lc_nest_maker", "Enable", "", self.NEST_WARNING)]
        shutting = [("OnTrigger", "lc_nest_shut", "Disable", "", 0), ("OnTrigger", "lc_nest_maker", "Disable", "", 0), ("OnTrigger", "lc_nest_alarm", "PlaySound", "", 0),
                    ("OnTrigger", "lc_nest_open", "CancelPending", "", 0),          # (shut inside the 11 s: no antlions come at all)
                    ("OnTrigger", "lc_nest_mouth_1_siren", "StopSound", "", 0)] + [("OnTrigger", "lc_nest_mouth_1_lamp_%d" % k, "LightOff", "", 0) for k in (1, 2, 3)] + [
                    ("OnTrigger", "lc_nest_light", "TurnOn", "", 0), ("OnTrigger", "lc_nest_door", "PressOut", "", 1.5), ("OnTrigger", "lc_nest_move", "PlaySound", "", 1.5),
                    ("OnTrigger", "lc_nest_crush", "Enable", "", 1.5), ("OnTrigger", "lc_nest_crush", "Disable", "", 7),
                    ("OnTrigger", "lc_nest_move", "StopSound", "", 6.6), ("OnTrigger", "lc_nest_slam", "PlaySound", "", 6.6), ("OnTrigger", "lc_nest_shake", "StartShake", "", 6.6),
                    ("OnTrigger", "lc_nest_portal", "Close", "", 6.9), ("OnTrigger", "lc_nest_closed", "Trigger", "", 6.9), ("OnTrigger", "lc_nest_light", "TurnOff", "", 9),
                    ("OnTrigger", "lc_nest_open", "Enable", "", 9)]
        v.point("logic_relay", W(bx - 16, D - 30, zf + 130), {"targetname": "lc_nest_open", "StartDisabled": "0", "spawnflags": "0"}, dv, connections=opening)
        v.point("logic_relay", W(bx + 16, D - 30, zf + 130), {"targetname": "lc_nest_shut", "StartDisabled": "1", "spawnflags": "0"}, dv, connections=shutting)
        v.point("logic_relay", W(bx - 16, D - 30, zf + 150), {"targetname": "lc_nest_opened", "StartDisabled": "0", "spawnflags": "0"}, dv)
        v.point("logic_relay", W(bx + 16, D - 30, zf + 150), {"targetname": "lc_nest_closed", "StartDisabled": "0", "spawnflags": "0"}, dv)
        self.node(bx, D - 120, zf)
        self.node(bx, D + 64, zf)
        self.notes.append("the emergency door: in a bulkhead at (%d %d), floor z %d, a shutter 192 wide and %d high; its two buttons are 480 apart with a wall between each "
                          "and the door (about 700 on foot); both within a second open it, and shut it again" % (self.ox + bx, self.oy + D, zf, high))

    def mine(self):
        """Behind the emergency door, before the hive: the old mine the door was put in to shut (the owner, 21 November:
        "reference ... the HL2 ravenholm caves/mines at the end of ravenholm"; copying Valve's maps is welcome). 1280 of
        Ravenholm's low mine tunnel (d1_town_04) lifted whole (valve_raven_mine_tunnel: Valve's own rock, two timber sets,
        a clamp lamp), turned to run north from the door. Ravenholm's set again every 256 and a clamp lamp on every other,
        its rail bed laid on along it, its floor flooded from half way as Valve's is. At its end the wall the antlions broke
        through into the hive (BREACH thick, a rough hole in it, rocks heaped at its feet), and before it Episode Two's
        antlion alarm post (valve_ep2_antlion_alarm: a pole with three lamps, a sensor, a siren), named for the gamemode
        (lc_nest_mouth_1_siren, lc_nest_mouth_1_lamp_1 to 3; nothing in the map sets them off: the lesson
        valve-wave-warning, the owner to decide)."""
        v, zf, bx = self.vmf, self.zf, self.end_x
        rnd = random.Random(self.seed + 61)      # (its own: the forest's planting must not move because the mine was added)
        y1, L = self.D + WALL, self.MINE
        q, d = 1, self.w(bx, y1, zf)              # (the piece's x runs north, its y west; its floor brush's top at zf)
        mv_, lv = self.vis("old mine (Valve's Ravenholm tunnel)"), self.vis("old mine: lights and alarm")
        pf = PF.load("valve_raven_mine_tunnel")
        pf_solids(v, pf, q, d, mv_, world=True)
        self.hull.append((bx - 448, y1, zf - 256, bx + 448, y1 + L + 64, zf + 512))
        floor = [p for m, p in pf_disp_points(pf, lambda m: "gravel" in m)]

        def floor_at(xp, yp):
            """The lifted floor's height (above zf) at a place in the piece's frame."""
            near = sorted(floor, key=lambda p: (p[0] - xp) ** 2 + (p[1] - yp) ** 2)[:3]
            return sum(p[2] for p in near) / len(near)

        def at(xp, yp, zp=0):                    # the piece's frame to the forest's
            return (bx - yp, y1 + xp, zf + zp)
        # Ravenholm's set (16 by 16 posts 240 apart, cap, knee braces) again every 256 to the breach
        one_set = {"solids": [sol for sol in pf["solids"] if sol["from"] == "func_detail" and "woodfloor" in sol["sides"][0]["material"].lower()
                              and all(250 <= c[0] <= 300 for sd in sol["sides"] for c in (sd["corners"] or sd["plane"]))]}
        for off in (256, 512, 768, 1000):
            pf_solids(v, one_set, q, (d[0], d[1] + off, d[2]), mv_)
        # its rail bed (gravel 128 wide, two rails 4 square), laid as Valve's runs on past the piece's box
        B = self.box
        v.detail([B(bx - 64, y1, zf - 8, bx + 64, y1 + L - 16, zf + 8)], "nature/gravelfloor002b", vis=mv_)
        v.detail([B(bx - 32, y1, zf + 8, bx - 28, y1 + L - 16, zf + 12), B(bx + 28, y1, zf + 8, bx + 32, y1 + L - 16, zf + 12)], "nature/gravelfloor002b", vis=mv_)
        # the flood: Valve's water starts 512 in and stands at the floor brush's top
        v.world_box(B(bx - 384, y1 + 512, zf - 128, bx + 384, y1 + L, zf - 2), MAT["nodraw"], top=FMAT["stream"], vis=mv_, seals=False)
        # the clamp lamp of the first set (Valve's) again on every other set; the lift lever left out
        lamps = [e for e in pf["points"] if "light_spotlight" in e["keys"].get("model", "") or e["classname"] == "light_spot"]
        extra = [dict(e, origin=[e["origin"][0] + off, e["origin"][1], e["origin"][2]]) for off in (512, 1000) for e in lamps]
        pf_entities(v, pf, q, d, "lc_mine_", lv, lv, keep=lambda e: "tram_lever" not in e["keys"].get("model", ""), extra=extra)
        v.point("env_cubemap", self.w(*at(640, 0, 96)), {"cubemapsize": "0"}, mv_)
        # odds and ends of the miners' (Episode Two's mine props, as Valve lays them: a few, by the walls)
        for (xp, yp, model, yaw) in ((300, 104, "models/props_mining/bucket_mining01.mdl", 30), (330, -100, "models/props_mining/pickaxe01.mdl", 80)):
            x, y, z = at(xp, yp, floor_at(xp, yp) + 4)          # (loose: they have physics, so they cannot be static)
            v.point("prop_physics", self.w(x, y, z), {"model": model, "angles": "0 %d 0" % (yaw + rnd.randrange(-15, 16)), "skin": "0", "spawnflags": "0",
                                                       "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "physdamagescale": "0.1", "inertiaScale": "1.0"}, lv)
        x, y, z = at(760, 100, floor_at(760, 100))
        self.static("models/props_mining/caverocks_cluster01.mdl", x, y, z - 6, rnd.randrange(0, 360, 15), "old mine", fade=(-1, 0))
        # the old mine's end: a wall with a timber-framed doorway into the shaft head (Ravenholm's last set stands just before it)
        f1 = zf + 16
        rock, crust, conc = "nature/rockwall015a", FMAT["nest_rock"], MINE_MAT["wall"]
        self.joint("y", y1 + L, bx, 192, f1, 192, 576, zf - 160, zf + 448, rock, conc, mv_)
        for (xp, yp, model) in ((L - 70, 122, "models/props_mining/caverocks_cluster02.mdl"), (L - 60, -124, "models/props_mining/caverocks_cluster01.mdl")):
            x, y, z = at(xp, yp, floor_at(xp, yp))
            self.static(model, x, y, z - 8, rnd.randrange(0, 360, 15), "old mine", fade=(-1, 0))
        self.shaft_head(rnd)
        for xp in range(128, L - 40, 256):
            x, y, z = at(xp, 0, max(8, floor_at(xp, 0)))
            self.node(x, y, z)
        self.mine_floor = floor_at
        self.notes.append("the old mine: behind the emergency door, 1280 of Ravenholm's low mine tunnel lifted from d1_town_04 (its rock, timber sets every 256, clamp lamps, "
                          "a rail bed, flooded from 512 in), then the shaft head")

    def joint(self, axis, p0, uc, hole_w, sill, hole_h, half, zlo, zhi, neg_mat, pos_mat, vis, rough=False):
        """A wall where two parts of the cave meet: 64 thick across `axis` ("y": a wall running east-west whose south face
        is at y = p0; "x": running north-south, its west face at x = p0), `half` either side of uc and from zlo to zhi,
        with a hole hole_w wide and hole_h high from `sill`. neg_mat faces south (or west), pos_mat north (or east); the
        hole's own sides take pos_mat. rough: its top corners notched, as where the antlions broke through."""
        v, T = self.vmf, 64
        h = hole_w / 2.0
        top = sill + hole_h
        u_lo, u_hi = half if isinstance(half, tuple) else (uc - half, uc + half)      # (half: a reach either side, or the wall's own two ends)
        notch = 28 if rough else 0
        if axis == "y":
            def B(u1, z1, u2, z2):
                return self.box(u1, p0, z1, u2, p0 + T, z2)
            neg, pos, lo_u, hi_u = "south", "north", "west", "east"
        else:
            def B(u1, z1, u2, z2):
                return self.box(p0, u1, z1, p0 + T, u2, z2)
            neg, pos, lo_u, hi_u = "west", "east", "south", "north"
        parts = [((u_lo, zlo, uc - h, zhi), {lo_u: pos_mat}), ((uc + h, zlo, u_hi, zhi), {hi_u: pos_mat}),
                 ((uc - h, zlo, uc + h, sill), {"top": pos_mat}), ((uc - h, top, uc + h, zhi), {"bottom": pos_mat})]
        if notch:
            parts += [((uc - h, top - 34, uc - h + notch, top), {hi_u: pos_mat, "bottom": pos_mat}), ((uc + h - notch, top - 34, uc + h, top), {lo_u: pos_mat, "bottom": pos_mat})]
        for box, faces in parts:
            f = dict(faces)
            if axis == "x":      # (a north-south wall's hole sides face north and south)
                f = dict((({"west": "south", "east": "north"}.get(k, k)), m) for k, m in f.items())
            f.update({neg: neg_mat, pos: pos_mat})
            v.world_box(B(*box), MAT["nodraw"], faces=f, vis=vis, tex=1 if "rock" in neg_mat or "rock" in pos_mat else 0.25)

    def gallery(self, axis, a, b, uc, floor, vis, rnd, wide=320, high=208, lamps=True):
        """A built mine gallery as Episode Two's (Valve: 192 high, 294 to 365 wide, a timber set every 192 to 280, cage lamps
        in pools): along `axis` from a to b, its middle at uc across, floor at `floor`. Walls, floor and roof 16 thick; one of
        Episode Two's timber sets (struts_tunnel320, the model's own frame) every 224, a cage lamp under every other."""
        v, h = self.vmf, wide / 2.0
        lo, hi = min(a, b), max(a, b)
        if axis == "y":
            def B(u1, s1, u2, s2, z1, z2):
                return self.box(u1, s1, z1, u2, s2, z2)
        else:
            def B(u1, s1, u2, s2, z1, z2):
                return self.box(s1, u1, z1, s2, u2, z2)
        m = MINE_MAT
        v.world_box(B(uc - h - 16, lo, uc + h + 16, hi, floor - 16, floor), MAT["nodraw"], top=m["floor"], vis=vis)
        v.world_box(B(uc - h - 16, lo, uc + h + 16, hi, floor + high, floor + high + 16), MAT["nodraw"], bottom=m["roof"], vis=vis)
        v.world_box(B(uc - h - 16, lo, uc - h, hi, floor, floor + high), MAT["nodraw"], faces={"east" if axis == "y" else "north": m["wall"]}, vis=vis)
        v.world_box(B(uc + h, lo, uc + h + 16, hi, floor, floor + high), MAT["nodraw"], faces={"west" if axis == "y" else "south": m["wall"]}, vis=vis)
        n = 0
        for s_ in range(int(lo) + 112, int(hi) - 40, 224):
            model = "models/props_mining/struts_tunnel320_0%d.mdl" % rnd.choice((1, 2, 3, 4))
            if axis == "y":
                pos, yaw = (uc + 48, s_ - 8, floor), 0
            else:
                pos, yaw = (s_ + 8, uc + 48, floor), 90
            self.static(model, pos[0], pos[1], pos[2], yaw, "mine galleries", fade=(-1, 0))
            if lamps and n % 2 == 0:
                lp = (uc, s_, floor + 178) if axis == "y" else (s_, uc, floor + 178)
                self.static("models/props_c17/light_cagelight02_on.mdl", lp[0], lp[1], lp[2], yaw, "mine galleries", solid=0, fade=(-1, 0))
                v.point("light", self.w(lp[0], lp[1], lp[2] - 14), {"_light": "255 226 174 110", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"},
                        self.vis("lights"))
            n += 1
        for s_ in range(int(lo) + 96, int(hi) - 40, 256):
            self.node(*((uc, s_, floor + 8) if axis == "y" else (s_, uc, floor + 8)))

    def lower_workings(self, rnd):
        """The lower workings, DEEP below the shaft head: the lift's shaft down from the shaft head's floor to a mine room
        of the same size (the shaft foot), and from there galleries to Episode Two's antlion nest chambers and grub cavern."""
        v, zf, bx = self.vmf, self.zf, self.end_x
        f1 = zf + 16
        f2, hv = f1 - self.DEEP, 256
        x1, y1, x2, y2 = self.room_box
        sx1, sy1, sx2, sy2 = self.shaft_rect
        m, B = MINE_MAT, self.box
        vis = self.vis("lower workings (mine rooms)")
        # the shaft: four walls from the foot room's roof to the head room's floor, Episode Two's cribbing up it
        for box, face in (((sx1 - 16, sy1 - 16, sx1, sy2 + 16), "east"), ((sx2, sy1 - 16, sx2 + 16, sy2 + 16), "west"),
                          ((sx1, sy1 - 16, sx2, sy1), "north"), ((sx1, sy2, sx2, sy2 + 16), "south")):
            v.world_box(B(box[0], box[1], f2 + hv, box[2], box[3], f1 - 16), MAT["nodraw"], faces={face: m["wall"]}, vis=vis)
        cx, cy = (sx1 + sx2) / 2.0, (sy1 + sy2) / 2.0
        for z in range(int(f2), int(f1) - 200, 432):
            self.static("models/props_mining/struts_shaft01.mdl", cx, cy, z + 17, 0, "lower workings (mine rooms)", fade=(-1, 0))
        # the foot room: the head room's size, straight below; its roof round the shaft
        for box in ((x1, y1, sx1, y2), (sx2, y1, x2, y2), (sx1, y1, sx2, sy1), (sx1, sy2, sx2, y2)):
            if box[2] > box[0] and box[3] > box[1]:
                v.world_box(B(box[0], box[1], f2 + hv, box[2], box[3], f2 + hv + 16), MAT["nodraw"], bottom=m["roof"], vis=vis)
        v.world_box(B(x1 - 64, y1 - 64, f2 - 16, x2 + 64, y2 + 64, f2), MAT["nodraw"], top=m["floor"], vis=vis)
        v.world_box(B(x1 - 64, y1 - 64, f2, x2 + 64, y1, f2 + hv + 16), MAT["nodraw"], faces={"north": m["wall"]}, vis=vis)
        v.world_box(B(x2, y1, f2, x2 + 64, y2, f2 + hv + 16), MAT["nodraw"], faces={"west": m["wall"]}, vis=vis)
        v.world_box(B(x1 - 64, y1, f2, x1, y2, f2 + hv + 16), MAT["nodraw"], faces={"east": m["wall"]}, vis=vis)
        self.joint("y", y2, self.FOOT_DOOR_X, 256, f2, 192, (x1 - 64, x2 + 64), f2 - 16, f2 + hv + 16, m["wall"], m["wall"], vis)
        for (x, y) in ((bx - 120, y1 + 220), (bx - 60, y2 - 200)):
            self.static("models/props_c17/light_cagelight02_on.mdl", x, y, f2 + hv - 12, 0, "lower workings (mine rooms)", solid=0, fade=(-1, 0))
            v.point("light", self.w(x, y, f2 + hv - 30), {"_light": "255 226 174 140", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        v.point("env_cubemap", self.w(bx - 100, (y1 + y2) / 2.0, f2 + 96), {"cubemapsize": "0"}, vis)
        self.hull.append((x1 - 64, y1 - 64, f2 - 16, x2 + 64, y2 + 64, f2 + hv + 16))
        self.lift(f1, f2)
        self.deep_pieces(rnd, f2)

    def deep_pieces(self, rnd, f2):
        """(Episode Two's nest chambers and grub cavern: placed below.)"""
        return

    def lift(self, f1, f2):
        """The lift between the shaft head and the shaft foot: Episode Two's mine cage (elevator01_cage) riding on a platform
        (a func_door, toggled: our own wiring, not Valve's tracktrain, so it works the same for every player). It starts at
        the top. A call button by the shaft at each end and one in the cage; the head's open side is fenced by an unseen
        clip while the cage is away (nobody walks into the empty shaft), and a rail stands on its other three sides."""
        v = self.vmf
        sx1, sy1, sx2, sy2 = self.shaft_rect
        cx, cy = (sx1 + sx2) / 2.0, (sy1 + sy2) / 2.0
        vis = self.vis("lift (cage, buttons, wiring)")
        B = self.box
        name = "lc_mine_lift"
        v.brush_entity("func_door", {"targetname": name, "movedir": "90 0 0", "speed": str(self.LIFT_SPEED), "lip": str(16 - self.DEEP), "wait": "-1",
                                     "spawnflags": "32", "forceclosed": "0", "dmg": "0", "noise1": "plats/elevator_move_loop1.wav", "noise2": "plats/elevator_stop.wav",
                                     "locked_sound": "0", "unlocked_sound": "0", "loopmovesound": "1", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
                                     "disablereceiveshadows": "0", "ignoredebris": "1"},
                       [B(sx1 + 6, sy1 + 6, f1 - 16, sx2 - 6, sy2 - 6, f1)], FMAT["door"], vis,
                       connections=[("OnOpen", name + "_fence", "Enable", "", 0), ("OnFullyClosed", name + "_fence", "Disable", "", 0)])
        cage = {"model": "models/props_mining/elevator01_cage.mdl", "angles": "0 90 0", "parentname": name, "solid": "0", "skin": "0", "disableshadows": "1",
                "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0",
                "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}
        v.point("prop_dynamic", self.w(cx, cy, f1 + 20), dict(cage, targetname=name + "_cage"), vis)
        v.point("prop_dynamic", self.w(cx, sy2 + 24, f1 + 21), dict(cage, model="models/props_mining/elevator_winch.mdl", angles="0 0 0", parentname="",
                                                               targetname=name + "_winch", solid="6"), vis)       # (the hoist, at the shaft's head)
        # the buttons: at the head (on the room's east wall beside the shaft), at the foot (the same, below), in the cage
        x2 = self.room_box[2]
        for (z, tag, inp) in ((f1, "top", "Close"), (f2, "foot", "Open")):
            wall_button(v, self.w(x2, sy2 + 40, z + 44), 180, name + "_" + tag, B(x2 - 10, sy2 + 30, z + 40, x2, sy2 + 50, z + 68), vis,
                        [("OnPressed", name, inp, "", 0)], "1")
        wall_button(v, self.w(sx2 - 6, cy, f1 + 44), 180, name + "_inside", B(sx2 - 16, cy - 10, f1 + 40, sx2 - 6, cy + 10, f1 + 68), vis,
                    [("OnPressed", name, "Toggle", "", 0)], "1", parent=name)
        # the head: a rail on three sides of the shaft (its west side is the way on), an unseen clip across the west side
        rail = MAT["bars"]
        v.detail([B(sx1 - 4, sy1 - 4, f1 + 36, sx2 + 4, sy1, f1 + 40), B(sx1 - 4, sy2, f1 + 36, sx2 + 4, sy2 + 4, f1 + 40), B(sx2, sy1, f1 + 36, sx2 + 4, sy2, f1 + 40)]
                 + [B(x - 2, y - 2, f1, x + 2, y + 2, f1 + 36) for (x, y) in ((sx1, sy1), (sx2, sy1), (sx1, sy2), (sx2, sy2), (cx, sy1), (cx, sy2), (sx2, cy))], rail, vis=vis)
        v.brush_entity("func_brush", {"targetname": name + "_fence", "Solidity": "0", "StartDisabled": "1", "solidbsp": "0", "rendermode": "10", "renderamt": "0",
                                      "rendercolor": "255 255 255", "spawnflags": "2", "vrad_brush_cast_shadows": "0", "InputFilter": "0", "invert_exclusion": "0"},
                       [B(sx1 - 2, sy1, f1, sx1, sy2, f1 + 128)], MAT["clip"], vis)
        self.notes.append("the lift: Episode Two's mine cage on a platform (lc_mine_lift, a func_door) down %d at %d a second (%.0f s), starting at the top; call buttons at both "
                          "ends and one in the cage; an unseen clip across the open side at the top while the cage is away" % (self.DEEP, self.LIFT_SPEED, self.DEEP / float(self.LIFT_SPEED)))

    def shaft_head(self, rnd):
        """The shaft head: a mine room in Episode Two's style between the old mine and the hive (Valve's built mine rooms:
        concrete, timber, cage lamps). Its south doorway is the old mine's end, its north wall the breach into the hive
        (Episode Two's antlion alarm post stands before it), a gallery leaves its west wall for Ravenholm's big cave, and
        the lift goes down from its east side to the lower workings."""
        v, zf, bx = self.vmf, self.zf, self.end_x
        f1, R = zf + 16, self.ROOM
        x1, y1, x2, y2 = bx - R[0] / 2, self.D + WALL + self.MINE + 64, bx + R[0] / 2, self.D + WALL + self.MINE + 64 + R[1]
        hv, vis, lv = 288, self.vis("shaft head (mine room)"), self.vis("old mine: lights and alarm")
        m, B = MINE_MAT, self.box
        self.room_box = (x1, y1, x2, y2)
        # floor (round the lift's shaft), roof, east wall (the west wall has the gallery's doorway: a joint)
        sx1, sy1, sx2, sy2 = self.shaft_rect
        for box in ((x1, y1, sx1, y2), (sx2, y1, x2, y2), (sx1, y1, sx2, sy1), (sx1, sy2, sx2, y2)):
            if box[2] > box[0] and box[3] > box[1]:
                v.world_box(B(box[0], box[1], f1 - 16, box[2], box[3], f1), MAT["nodraw"], top=m["floor"], vis=vis)
        v.world_box(B(x1 - 64, y1, f1 + hv, x2 + 64, y2, f1 + hv + 16), MAT["nodraw"], bottom=m["roof"], vis=vis)
        v.world_box(B(x2, y1, f1 - 160, x2 + 64, y2, f1 + hv), MAT["nodraw"], faces={"west": m["wall"]}, vis=vis)
        gy = self.GALLERY_Y
        self.joint("x", x1 - 64, gy, 256, f1, 192, (y1, y2), f1 - 160, f1 + hv, m["wall"], m["wall"], vis)
        # the breach into the hive: a rough hole in the north wall, the hive's crust beyond
        self.joint("y", y2, bx, 144, f1, 168, 576, zf - 160, zf + 448, m["wall"], FMAT["nest_rock"], vis, rough=True)
        for (dx, model) in ((-118, "models/props_mining/caverocks_cluster02.mdl"), (122, "models/props_mining/caverocks_cluster01.mdl")):
            self.static(model, bx + dx, y2 - 50, f1 - 8, rnd.randrange(0, 360, 15), "shaft head (mine room)", fade=(-1, 0))
        self.static("models/props_mining/stalactite_cluster01.mdl", bx, y2 - 12, f1 + 174, 90, "shaft head (mine room)", fade=(-1, 0))
        # Episode Two's antlion alarm post before the breach, its lamps facing the way in from the door
        alarm = PF.load("valve_ep2_antlion_alarm")

        def louder(e):                          # (Valve's 1250 stops short of the buttons: heard at the door)
            if e["keys"].get("targetname") == "mouth_1_siren":
                e["keys"]["radius"] = "2000"
        pf_entities(v, alarm, 1, self.w(x1 + 70, y2 - 110, f1), "lc_nest_", lv, lv, edit=louder)
        # dressing and light: Episode Two's mine lamps and timber
        for (x, y) in ((bx - 120, y1 + 200), (bx + 40, y2 - 260)):
            self.static("models/props_c17/light_cagelight02_on.mdl", x, y, f1 + hv - 12, 0, "shaft head (mine room)", solid=0, fade=(-1, 0))
            v.point("light", self.w(x, y, f1 + hv - 30), {"_light": "255 226 174 140", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        self.static("models/props_mining/struts_wall03.mdl", x2 - 2, (y1 + y2) / 2.0 + 100, f1, 180, "shaft head (mine room)", fade=(-1, 0))
        v.point("env_cubemap", self.w(bx, (y1 + y2) / 2.0, f1 + 96), {"cubemapsize": "0"}, vis)
        for y in (y1 + 160, y2 - 160):
            self.node(bx - 100, y, f1 + 8)
        # the gallery west to Ravenholm's big cave, and the cave itself
        cx = self.BIG_CAVE_X
        self.gallery("x", cx + 64, x1 - 64, gy, f1, self.vis("mine galleries"), rnd)
        self.joint("x", cx, gy, 224, f1, 200, 576, f1 - 200, f1 + 460, "nature/rockwall015a", m["wall"], self.vis("mine galleries"))
        cave = PF.load("valve_raven_big_cave")
        cv = self.vis("Ravenholm's big cave (Valve's)")
        d = self.w(cx, gy, f1 - 20)
        pf_solids(v, cave, 0, d, cv, world=True)
        self.hull += [(x1 - 576, y1 - 64, f1 - 200, x2 + 576, y2 + 64, f1 + 460), (cx, gy - 600, f1 - 200, x1, gy + 600, f1 + 460),
                      (cx + cave["box"][0] - cave["anchor"][0], gy + cave["box"][1] - cave["anchor"][1], f1 - 20 + cave["box"][2] - cave["anchor"][2],
                       cx, gy + cave["box"][4] - cave["anchor"][1], f1 - 20 + cave["box"][5] - cave["anchor"][2])]
        pf_entities(v, cave, 0, d, "lc_cave2_", self.vis("Ravenholm's big cave: lights and props"), self.vis("Ravenholm's big cave: lights and props"))
        self.lower_workings(rnd)
        self.notes.append("the shaft head: a mine room %d by %d (floor z %d) after the old mine; the breach into the hive in its north wall with Episode Two's alarm post before it; "
                          "a gallery %d long west to Ravenholm's big cave (lifted whole from d1_town_04: timber stairs and walkways, a shaft rising %d)" % (
                              R[0], R[1], f1, x1 - 64 - cx - 64, 1500))


    def nest(self):
        """The antlion nest (the owner: "an EP2 style antlion nest deeper in the cave ... a mini version of the EP2 antlion
        caves"): behind the emergency door, in a shut box of its own north of the forest (so the door's areaportal can hide
        it). A passage of the cave's own kind of skin: down a slope, a first chamber with the nests, a narrow way round two
        bends, and a last chamber with the extract. While the door is open antlions are made in both chambers and run to the
        chamber before the mine office; shut the door and no more come."""
        v, n, zf = self.vmf, self.nest_tube, self.zf
        nv, mv, gv = self.vis("antlion nest"), self.vis("antlion makers (delete if the gamemode is to send the antlions itself)"), self.vis("antlion grubs")
        H, T, y0, L = n.HALF, n.TALL, n.y0, n.LONG
        # the box it is in: the forest's north wall is its south side
        bx1, bx2, by2 = n.bcx - 1088, n.bcx + 1152, y0 + L + 192
        ys = self.D + WALL                                 # (the box starts at the bulkhead: the old mine is in it too)
        ztop = zf + 640
        black = MAT["black"]
        # one shut box round everything behind the emergency door: the hive's own room and every part of the workings
        # (each registered its reach in self.hull); the forest's north wall is its south side where that wall stands
        parts = self.hull + [(bx1, ys, self.zb, bx2, by2, ztop)]
        X1, Y2 = min(p_[0] for p_ in parts) - 64, max(p_[4] for p_ in parts)
        X2, Z1, Z2 = max(p_[3] for p_ in parts), min(p_[2] for p_ in parts) - 64, max(p_[5] for p_ in parts) + 64
        if X2 > self.W:
            self.problems.append("the workings reach past the forest's east side (x %d): the ring's canal is there" % (self.ox + X2))
        if self.oy + Y2 + 64 > 16000 or self.ox + X1 - 64 < -16000 or Z1 - 64 < -16000:
            self.problems.append("the workings come within 384 of the map's edge (16384)")
        for box in ((X1 - 64, ys, Z1 - 64, X2 + 64, Y2 + 64, Z1), (X1 - 64, ys, Z2, X2 + 64, Y2 + 64, Z2 + 64),
                    (X1 - 64, ys, Z1, X1, Y2 + 64, Z2), (X2, ys, Z1, X2 + 64, Y2 + 64, Z2), (X1, Y2, Z1, X2, Y2 + 64, Z2)):
            v.world_box(self.box(*box), black, vis=nv)
        # its south side where the forest's north wall does not reach (west of the forest, under its slab, over its sky)
        tw = WALL                                          # (not T: the skin's point functions read T when the file is written)
        south = [(X1 - 64, self.D, Z1 - 64, min(-tw, X2 + 64), ys, Z2 + 64)] if X1 < -tw else []
        south += [(max(-tw, X1 - 64), self.D, Z1 - 64, X2 + 64, ys, self.zb - 64)] if Z1 < self.zb - 64 else []
        south += [(max(-tw, X1 - 64), self.D, self.lid + 16, X2 + 64, ys, Z2 + 64)] if Z2 > self.lid + 16 else []
        for box in south:
            v.world_box(self.box(*box), black, vis=nv)
        self.hull_box = (X1, ys, Z1, X2, Y2, Z2)
        rock, hive, floor = FMAT["nest_rock"], FMAT["nest_hive"], FMAT["cave"]

        def dirt_of(p):
            return 235 * (1 - smooth((p[2] - n.floor(p[0], p[1]) - 6) / 34.0))
        seg = 256
        lo, hi = 1e9, -1e9
        for k in range(L // seg):
            ya = y0 + k * seg
            c = n.bcx + int(round((n.mid(ya + seg / 2) - n.bcx) / 64.0)) * 64
            zs = int(round(n.base(ya + seg / 2) / 16.0)) * 16
            wall = rock if k < 2 else hive                 # (the first 512 is still rock; then the hive's own crust)
            self.skin((c - H, ya, zs - 16, c + H, ya + seg, zs), "top", lambda i, j, ya=ya: n.on_square(-H + 40 * j, 0, ya + 32 * i), floor, nv, dirt=dirt_of)
            self.skin((c - H, ya, zs + T, c + H, ya + seg, zs + T + 16), "bottom", lambda i, j, ya=ya: n.on_square(-H + 40 * i, T, ya + 32 * j), wall, nv, dirt=dirt_of)
            self.skin((c - H - 16, ya, zs, c - H, ya + seg, zs + T), "east", lambda i, j, ya=ya: n.on_square(-H, 40 * i, ya + 32 * j), wall, nv, dirt=dirt_of)
            self.skin((c + H, ya, zs, c + H + 16, ya + seg, zs + T), "west", lambda i, j, ya=ya: n.on_square(H, 40 * j, ya + 32 * i), wall, nv, dirt=dirt_of)
        yend = y0 + L
        mid = (n.mid(yend), yend, n.base(yend) + 0.51 * n.radius(yend))

        def dome(i, j):
            xn, zn = -H + 40 * j, 40 * i
            rho = max(abs(xn) / H, abs(zn - T / 2.0) / (T / 2.0))
            if rho < 0.001:
                p = (mid[0], mid[1] + 90, mid[2])
            else:
                edge = n.on_square(xn / rho, T / 2.0 + (zn - T / 2.0) / rho, yend)
                p = (lerp(mid[0], edge[0], rho), edge[1] + 90 * (1 - rho * rho), lerp(mid[2], edge[2], rho))
            return (p[0], p[1], max(p[2], n.floor(p[0], yend)))
        c = n.bcx + int(round((n.mid(yend) - n.bcx) / 64.0)) * 64
        zs = int(round(n.base(yend) / 16.0)) * 16
        self.skin((c - H, yend, zs, c + H, yend + 16, zs + T), "south", dome, hive, nv, dirt=dirt_of)
        # the skin must stay inside its box, and its floor must be walkable
        steep = 0
        for q in range(0, L + 1, 32):
            for k in range(0, 64):
                p = n.ring(k * math.pi / 32, y0 + q)
                lo, hi = min(lo, p[0]), max(hi, p[0])
                if p[2] > ztop - 24 or p[2] < self.zb + 40:
                    self.problems.append("the nest's skin leaves its box in height (z %d) %d in" % (p[2], q))
            steep = max(steep, abs(n.base(y0 + q + 16) - n.base(y0 + q)) / 16.0)
        if lo < bx1 + 24 or hi > bx2 - 24:
            self.problems.append("the nest's skin leaves its box sideways (x %d to %d, the box %d to %d)" % (lo, hi, bx1, bx2))
        if steep > 0.6:
            self.problems.append("the nest's floor is too steep to walk (%.2f)" % steep)

        def spot(q, across, up=0):
            """A place on the nest's floor: q in from its door, across from its middle (in parts of its half width)."""
            y = y0 + q
            x = n.mid(y) + across * 1.15 * n.radius(y) * n.lean(y) * 0.62
            return (x, y, n.floor(x, y) + up)
        # Dressed to Episode Two's caves (the plan from the ingestion, docs/dev/map-building.md: valve-cave-light,
        # valve-grub-groups, valve-grub-clusters, valve-nest-dressing). Its own random numbers: the forest's are left as
        # the nest's first dressing left them (old_nest_draws), so the planting does not move.
        forest_rnd, rnd = self.rnd, random.Random(self.seed + 62)
        before = forest_rnd.getstate()
        # light: three kinds, never far apart (Valve: a node's nearest light 165 to 185 away). A cold fill every 420
        # (Valve's 132 158 202), amber round the extract and its own glow; each grub group has its small yellow one (below).
        for (q, across, up, colour) in [(q, 0, 170, "132 158 202 40") for q in (220, 640, 1060, 1480, 1900, 2320)] + [(2150, 0, 210, "255 200 90 150"), (2380, 0.3, 100, "160 255 150 50")]:
            v.point("light", self.w(*spot(q, across, up)), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.vis("lights"))
        for q in (850, 2150):
            v.point("env_cubemap", self.w(*spot(q, 0, 80)), {"cubemapsize": "0"}, nv)
        # what is on its floor: flat nests (Valve's commonest), eggs, the extract's own nest at the end
        for (q, across, model) in ((760, 0.35, "models/props_hive/nest_lrg_flat.mdl"), (1000, -0.5, "models/props_hive/nest_med_flat.mdl"), (640, -0.6, "models/props_hive/nest_sm_flat.mdl"),
                                   (1120, 0.55, "models/props_hive/nest_sm_flat.mdl"), (1980, -0.55, "models/props_hive/nest_med_flat.mdl"), (2240, 0.6, "models/props_hive/nest_sm_flat.mdl"),
                                   (1760, 0.4, "models/props_hive/nest_med_flat.mdl"),
                                   (2360, 0, "models/props_hive/nest_extract.mdl")):
            x, y, z = spot(q, across)
            self.static(model, x, y, z - 2, rnd.randrange(0, 360, 15), "antlion nest", fade=(-1, 0))
        for k in range(14):
            x, y, z = spot(rnd.choice((rnd.uniform(620, 1150), rnd.uniform(1900, 2400))), rnd.uniform(-0.8, 0.8))
            self.static("models/props_hive/egg.mdl", x, y, z - 1, rnd.randrange(0, 360, 15), "antlion nest", fade=(-1, 0))

        def dynamic(model, pos, yaw, name=None, angles=None):
            keys = {"model": model, "angles": angles or "0 %d 0" % yaw, "skin": "0", "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                    "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0",
                    "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}
            if name:
                keys["targetname"] = name
            v.point("prop_dynamic", self.w(*pos), keys, nv)

        def chamber():
            return rnd.choice((rnd.uniform(620, 1150), rnd.uniform(1900, 2400)))

        def wall(q, side, lift=0.0, inset=0):
            """A point on the nest's wall q in: side 1 or -1, lift from 0 (half way up) towards the roof (positive) or the
            floor (negative), in radians; inset: pulled this far in towards its middle."""
            y = y0 + q
            th = lift if side > 0 else (math.pi - lift)
            p = n.ring(th, y)
            return (p[0] - side * inset, p[1], p[2])
        # overhead: web sacks from the roof, the big ones in the chambers (Valve: websackceiling01 to 05, big01, 02, 05)
        for k in range(9):
            y = y0 + chamber()
            p = n.ring(rnd.uniform(1.2, 1.9), y)
            dynamic("models/props_hive/websackceiling0%d.mdl" % rnd.choice((1, 2, 3, 5)), (p[0], p[1], p[2] - 4), rnd.randrange(0, 360, 15))
        for (q, big) in ((830, "01"), (2050, "02"), (2290, "05")):
            p = n.ring(math.pi / 2 + rnd.uniform(-0.25, 0.25), y0 + q)
            dynamic("models/props_hive/websackceilingbig%s.mdl" % big, (p[0], p[1], p[2] - 6), rnd.randrange(0, 360, 15))
        # on the walls: half sacks (their flat back to the rock) and the web plugs over side holes (grubtunnel_door)
        for k in range(10):
            q, side = rnd.uniform(560, 2440), rnd.choice((1, -1))
            p = wall(q, side, rnd.uniform(0.25, 0.5), 6)
            dynamic("models/props_hive/websackhalf%s.mdl" % rnd.choice(("", "_b", "_c")), p, 180 if side > 0 else 0)
        for (q, side) in ((700, 1), (1080, -1), (1600, 1), (1950, 1), (2300, -1)):
            p = wall(q, side, -0.15, -8)                    # (8 into the rock, so its rim is buried)
            dynamic("models/props_hive/grubtunnel_door.mdl", (p[0], p[1], p[2] + 10), 0)
        # from the roof: stalactites (Valve: 12 to 50 a cave map), where the roof is high enough
        for k in range(12):
            q = chamber()
            p = n.ring(math.pi / 2 + rnd.uniform(-0.5, 0.5), y0 + q)
            model = rnd.choice(("models/props_mining/stalactite_static01.mdl", "models/props_mining/stalactite_static02.mdl", "models/props_mining/stalactite_cluster01.mdl",
                                "models/props_mining/stalactite_cluster02.mdl"))
            drop = {"static01": 176, "static02": 150, "cluster01": 77, "cluster02": 53}[model.rsplit("_", 1)[1][:-4]]
            if p[2] - drop < n.floor(p[0], p[1]) + 110:
                continue                                    # (not where it would reach a head)
            self.static(model, p[0], p[1], p[2] + 4, rnd.randrange(0, 360, 15), "antlion nest", fade=(-1, 0))
        ex = spot(2360, 0)
        dynamic("models/props_hive/larval_essence.mdl", (ex[0], ex[1], ex[2] + 24), 0, "lc_nest_extract")
        for (q, side) in ((300, 1), (520, -1), (1350, 1), (1600, -1), (1800, 1)):
            y = y0 + q
            p = n.ring(-0.5 if side > 0 else math.pi + 0.5, y)
            self.static("models/props_mining/caverocks_cluster0%d.mdl" % rnd.choice((1, 2)), p[0] - 30 * side, p[1], n.floor(p[0] - 30 * side, p[1]) - 6, rnd.randrange(0, 360, 15), "antlion nest", fade=(-1, 0))
        # grubs (Episode Two's npc_antlion_grub: they glow, and burst when trodden on) in groups of two to four, the
        # groups about 170 apart along alternate walls, each grub 23 to 51 from the next, half of them up the wall
        # (rolled 45 to 90 to face out of it), the rest at its foot; a small yellow light 30 to 45 out from each group
        grubs = groups = 0
        for g, q0 in enumerate(range(440, L - 120, 170)):
            side = 1 if g % 2 else -1
            q = q0 + rnd.uniform(-30, 30)
            for k in range(rnd.choice((2, 3, 3, 4))):
                q += rnd.uniform(23, 51) * (1 if k else 0)
                if rnd.random() < 0.5:
                    p = wall(q, side, -rnd.uniform(0.25, 0.55), 2)
                    roll = -side * rnd.randrange(45, 91, 5)
                    v.point("npc_antlion_grub", self.w(*p), {"angles": "0 90 %d" % roll, "spawnflags": "0"}, gv)
                else:
                    x, y, z = spot(q, side * rnd.uniform(0.85, 0.97), 2)
                    v.point("npc_antlion_grub", self.w(x, y, z), {"angles": "0 %d 0" % rnd.randrange(0, 360, 15), "spawnflags": "0"}, gv)
                grubs += 1
            lx, ly, lz = spot(q0 + 30, side * 0.55, 34)
            v.point("light", self.w(lx, ly, lz), {"_light": "255 245 157 %d" % rnd.randrange(40, 81, 10), "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"},
                    self.vis("lights"))
            groups += 1
        forest_rnd.setstate(before)
        old_nest_draws(forest_rnd, L)
        # the antlions: one pattern (it is not in the map until a maker copies it), four makers that only work while the door
        # is open, two alive from each at a time. Each one made runs to lc_nest_rally, in the chamber before the mine office.
        tx, ty, tz = spot(900, 0, 8)
        v.point("npc_antlion", self.w(tx, ty, tz), {"targetname": "lc_nest_antlion", "spawnflags": "2564", "angles": "0 270 0", "radius": "256", "eludedist": "1024",
                                                    "ignorebugbait": "0", "startburrowed": "0", "unburroweffects": "0", "squadname": "lc_nest", "physdamagescale": "1.0",
                                                    "sleepstate": "0", "renderamt": "255", "rendercolor": "255 255 255"}, mv)
        makers = ((700, -0.3), (1050, 0.3), (2000, 0.2), (2250, -0.3))
        for (q, across) in makers:
            v.point("npc_template_maker", self.w(*spot(q, across, 8)), {
                "targetname": "lc_nest_maker", "TemplateName": "lc_nest_antlion", "StartDisabled": "1", "spawnflags": "32", "MaxNPCCount": "1", "SpawnFrequency": "9",
                "MaxLiveChildren": "2", "Radius": "96", "MinSpawnDistance": "0", "CriterionVisibility": "2", "CriterionDistance": "2", "angles": "0 270 0"}, mv,
                connections=[("OnSpawnNPC", "!activator", "FightToPosition", "lc_nest_rally", 0.5), ("OnSpawnNPC", "lc_nest_mouth_1_siren", "StopSound", "", 0)])
        ry = self.YM + (self.OFFICE[0] + self.OFFICE[1]) / 2
        v.point("info_target", self.w(self.mid(ry) + 60, ry, zf + 8), {"targetname": "lc_nest_rally", "angles": "0 0 0"}, mv)
        for q in range(96, L - 60, 160):
            x, y, z = spot(q, 0.15)
            self.node(x, y, z)
        # shut in but for the emergency door: with its doorway stopped, air from the nest must not reach the forest
        closed = flood(v, self.w(*spot(200, 0, 64)), [self.box(self.end_x - 96, self.D, zf, self.end_x + 96, self.D + WALL, zf + 160)])
        if closed[0] is None or reaches(closed, self.w(self.W / 2, 600, self.lid - 100)):
            self.problems.append("the nest is open to the forest somewhere other than the emergency door")
        if not reaches(closed, self.w(*spot(2300, 0, 64))):
            self.problems.append("the nest's last chamber can't be reached from its door")
        if not reaches(closed, self.w(n.bcx, self.D + WALL + self.MINE / 2, zf + 64)):
            self.problems.append("the old mine can't be reached from the hive: the breach is shut")
        self.notes.append("the antlion nest: behind the emergency door, in its own box x %d to %d, y %d to %d; %d long: down %d to a first chamber (nests, eggs), round two bends "
                          "to a last chamber with the extract (lc_nest_extract); %d grubs in %d groups, each with its light; %d makers, 2 antlions alive from each while the door is open" % (
                              self.ox + bx1 - 64, self.ox + bx2 + 64, self.oy + ys, self.oy + by2 + 64, L, n.zf - n.base(y0 + 1000), grubs, groups, len(makers)))

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
        ax, ay = self.office_at
        for x1, y1, x2, y2, spec in self.office.rectangles():
            if spec[0] != "solid":
                dr.polygon([P(ax + x1, ay + y1), P(ax + x2, ay + y1), P(ax + x2, ay + y2), P(ax + x1, ay + y2)], fill=(120, 90, 50, 200), outline=(255, 255, 255, 200))

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
    f = CaveForest("forest (cave, stream)", tuple(args.origin or (-9280, 4608)), floor, 47, args.first_node or 4600, ("east", 256))
    f.test = bool(getattr(args, "test", False))
    f.setup()
    f.shell()
    f.ground()
    f.water()
    f.cave()
    f.plant()
    f.ground_nodes()
    f.finish()
    if args.preview:
        f.preview(args.preview)
        f.cave_picture(args.preview.rsplit(".", 1)[0] + "_cave.png")
    return f.vmf, f.problems
