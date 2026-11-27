#!/usr/bin/env python3
"""
Living City: the suppression core under City 18's Nexus (the Citadel's own thumper, which keeps the antlions out)

    python3 map_build.py core                       lc_core.vmf: the piece alone, in City 18's own coordinates
    python3 map_core.py OWNER.vmf OUT.vmf           the owner's map with the core in it: the piece built, carried in with
                                                    map_owner_delta.py (fresh ids, their visgroups, their line ends) and
                                                    their two walls opened (the only brushes of theirs that change)

The owner, 27 November: "a Combine 'suppression core' under the Nexus, the city's own Citadel-style thumper ... it needs
to be somewhat accessible by the resistance; it can't be too highly secured and impossible to get to like the prison ...
so whichever location allows a secret entrance via the sewers and underground tunnels is best". Then: "I would really
like to have something taken from the Valve citadel maps (the first one ideally where it is under the citadel)".

WHERE (measured in their c18.vmf): straight under the Nexus's lowest level, its power room (x 2912..3413, y 336..936,
floor 232: generators, consoles and shield walls behind the stair down from the z 368 interior). Nothing of theirs is
under z 220 anywhere from x 1300 to 4200, so the chamber is a sealed room in the empty space below: inside x 2368..3392,
y 128..1152, from the pit floor at -1408 to a roof at 192 (16 under the power room's floor brushes).

THE MACHINE is Valve's: the three diggers of d3_citadel_01 ("Our Benefactors", the pistons pounding the ground under the
Citadel), lifted with map_prefab.py into _dev/reference/prefabs/valve_citadel_diggers.json. Each is a func_tracktrain of
citadel metal (a block 192 x 192 x 1280 on a rod) on two path_tracks 384 apart (448 for the third): it drops at full speed,
stops on the bottom track with a shake, Valve's hit sound and dust, rises 2 s later, stops on the top track 2 s, and so
on; Valve's own outputs, as they were, only passed through a logic_relay per track so that lc_core_stop can cancel what
is pending. They pound the pit floor here, in a triangle; what would stand above the chamber's ceiling slab (the top of
each block and the rod) is cut off (the slab hides it, the cut end never shows: K_CUT). Valve's sounds are sound
scripts (95 dB: heard across the city), so each is played here by its own wave file (from Garry's Mod's
scripts/sounds/level_sounds_citadel.txt) with a radius, as the owner learned. dmg 0 on the trains (nothing the map moves
kills): clips keep everyone out of the pit.

THE CHAMBER: Combine metal, two catwalks round the pit (the lower one all round, the upper one on the north, east and
south walls; a ladder up a post between them), a ceiling slab 32 thick with a hole round each piston, railings and a
clip from the lower catwalk to the ceiling all round the pit, Combine wall lamps (cold, dim), a red set that is dark,
pulsing glows at the pistons, consoles, pipes, cables, a deep machine loop (a wave file, radius 1000).

THE RESISTANCE'S WAY (secret): the theater tunnel (the hatch in the street at -528 1456 793 and its ladder; the tunnel
runs east to the sewers) has a dead-end alcove on its south side (x 32..160, y 1264..1376, a power box, a stained wall).
Low in its west wall (their brush 21766) is a broken hole, 64 wide and 56 high: crouch through into a service closet,
down a ladder (342) to an old service tunnel, east 2368 under the sewers and the Nexus, down a ladder (480) at its end,
along a short passage, down a second ladder (480), and through the chamber's west wall onto the lower catwalk.

THE COMBINE'S WAY: a doorway in the power room's east wall (their brush 23625, in the niche between the two
generators), and behind it Valve's freight lift (the prefab valve_eli_lift_ride, as map_cistern.py uses it: the cage
model on Valve's own unseen collision, the gate models over unseen clips, the call buttons, its sounds), down 760 to the
upper catwalk. It is a func_door (map_walk.py rides func_door lifts): Open sends it down, Close up.

Names for the game: lc_core_machine (the main digger's train), lc_core_digger_2, lc_core_digger_3, lc_core_stop and
lc_core_start (logic_relays), lc_core_panel_1..3 (where a player stands at a console), lc_core_button (a func_button
at the main console: a press sound only, the game hears OnPressed), lc_core_room (the chamber's middle), lc_core_breach
(at the hole in the alcove), lc_core_combine_way (in the power room before the lift). The lift: lc_core_lift_down and
lc_core_lift_up (logic_relays).
"""
import json
import math
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from map_build import FACE_ORDER, MAT, check, face_corners  # noqa: E402
from map_modules import SCAPES, Build, Frame, Mod  # noqa: E402

PREFABS = os.path.join(HERE, "..", "reference", "prefabs")
T = 16                                   # walls, floors and roofs
CH = (2368, 128, 3392, 1152)             # the chamber inside: x1 y1 x2 y2
FLOOR, LOW, HIGH, CEIL, ROOF = -1408, -896, -512, -304, 192      # pit floor, lower and upper catwalk tops, ceiling slab's underside, roof's underside
SLAB = 32                                # the ceiling slab's thickness
WALK = 192                               # the catwalks' width
PIT = (CH[0] + WALK, CH[1] + WALK, CH[2] - WALK, CH[3] - WALK)   # the pit inside the lower catwalk
K_CUT = -264                             # the diggers are cut here (with each at the bottom of its stroke): over the slab, under the roof at the top
CX, CY = (CH[0] + CH[2]) // 2, (CH[1] + CH[3]) // 2
# Valve's three diggers: (their train's name, ours, where the middle of its block stands here)
DIGGERS = (("train_digger1", "lc_core_machine", (2880, 800)),
           ("train_digger2", "lc_core_digger_2", (2704, 496)),
           ("train_digger3", "lc_core_digger_3", (3056, 496)))
# the wave files under Valve's sound scripts (Garry's Mod's scripts/sounds/level_sounds_citadel.txt), with a radius
DIGGER_SOUND = {"d3_citadel.digger_hit1": "ambient/machines/floodgate_stop1.wav", "d3_citadel.digger_move1": "ambient/machines/wall_move4.wav",
                "d3_citadel.digger_stop1": "plats/hall_elev_stop.wav"}
LOOP = "ambient/levels/canals/generator_ambience_loop1.wav"      # (a deep machine loop the owner's own map already plays)
# the lift (the Combine's way): its landings' front plane, the cage's middle across, the two landings' floors
LX, LY, LZ, TZ = 3444, 608, HIGH, 248
LIFT_SPEED = 128
# the secret way and the Combine's doorway: where the piece opens the owner's own brushes (id: their box, the hole, the
# material the hole's new faces get)
HOLE = (16, 1280, 406, 32, 1344, 462)
DOORWAY = (3413, 544, 248, 3429, 672, 376)
OPENINGS = (HOLE, DOORWAY)
OPENED = {"21766": ((16, 1264, 406, 32, 1360, 526), HOLE, "brick/brickwall001a"),
          "23625": ((3413, 448, 248, 3429, 824, 480), DOORWAY, "metal/metalcombine001")}
# the owner's brushes the piece's walls meet (their walls there are the piece's): never filled by the piece
NEAR = [(16, 1264, 526, 32, 1376, 534), (16, 1360, 406, 32, 1376, 526), (32, 1264, 394, 160, 1376, 406),
        (3413, 544, 232, 3444, 672, 248), (3413, 672, 232, 3429, 936, 248), (3413, 336, 232, 3429, 544, 248), (3413, 544, 480, 3444, 672, 496)]
# the open spaces: (box, materials {floor, wall, ceil}, what it is)
CONCRETE = {"floor": "concrete/concretefloor031a", "wall": "concrete/concretewall008a", "ceil": "concrete/concreteceiling004a"}
BRICK = {"floor": "concrete/concretefloor031a", "wall": "brick/brickwall001a", "ceil": "concrete/concreteceiling004a"}
COMBINE = {"floor": "metal/metalcombine002", "wall": "metal/citadel_metalwall077a", "ceil": "metal/citadel_metalwall090a"}
SHAFT = {"floor": "metal/metalcombine002", "wall": "metal/citadel_metalwall090a", "ceil": "metal/citadel_metalwall090a"}
LOBBY = {"floor": "metal/metalcombine002", "wall": "metal/metalcombine001", "ceil": "metal/metalcombine001"}
SPACES = [
    (HOLE, BRICK, "the hole in the alcove's wall"),
    ((-112, 1264, 406, 16, 1360, 520), BRICK, "the service closet"),
    ((-112, 1264, 64, -48, 1360, 406), CONCRETE, "the closet's shaft"),
    ((-112, 1232, 64, -48, 1264, 192), CONCRETE, "the shaft's foot"),
    ((-112, 1104, 64, 2256, 1232, 192), CONCRETE, "the service tunnel"),
    ((2256, 1104, -416, 2352, 1232, 192), CONCRETE, "the first shaft down"),
    ((2256, 1008, -416, 2352, 1104, -288), CONCRETE, "the passage between the shafts"),
    ((2256, 912, -896, 2352, 1008, -288), CONCRETE, "the second shaft down"),
    ((CH[0] - T, 912, LOW, CH[0], 1008, LOW + 112), CONCRETE, "the way through the chamber's west wall"),
    ((CH[0], CH[1], FLOOR, CH[2], CH[3], ROOF), COMBINE, "the chamber"),
    ((CH[2], LY - 52, LZ, CH[2] + T, LY + 52, LZ + 116), LOBBY, "the lift's doorway into the chamber"),
    ((CH[2] + T, LY - 52, LZ, LX, LY + 52, LZ + 116), LOBBY, "the lift's lower landing"),
    ((LX, LY - 96, LZ - 16, LX + 192, LY + 96, TZ + 176), SHAFT, "the lift's shaft"),
    ((3429, 544, TZ, LX, 672, TZ + 128), LOBBY, "the lift's upper landing"),
    (DOORWAY, LOBBY, "the doorway in the power room's east wall"),
]
VIS = "LC core"


def minus(box, hole):
    """A box with a box taken out of it, as boxes (the hole may run out of it on any side)."""
    out, b = [], list(box)
    h = [max(box[k], hole[k]) for k in range(3)] + [min(box[k + 3], hole[k + 3]) for k in range(3)]
    if any(h[k] >= h[k + 3] for k in range(3)):
        return [tuple(box)]
    for a in range(3):
        if b[a] < h[a]:
            p = list(b)
            p[a + 3] = h[a]
            out.append(tuple(p))
            b[a] = h[a]
        if b[a + 3] > h[a + 3]:
            p = list(b)
            p[a] = h[a + 3]
            out.append(tuple(p))
            b[a + 3] = h[a + 3]
    return out


def shell(spaces, avoid):
    """The walls round open spaces: every bit of solid within T of the open air (no further), joined into the fewest boxes
    the greedy way, never where `avoid` (brushes of the owner's that are already there) is. A face is drawn only where
    it looks onto the open air, in the material of the space it looks onto (its floor, wall or ceiling); nodraw elsewhere.
    Returns [(box, {face: material})]."""
    import numpy as np
    cuts = [set(), set(), set()]
    for box, _, _ in spaces:
        for k in range(3):
            cuts[k].update((box[k], box[k + 3]) if box in OPENINGS else (box[k] - T, box[k], box[k + 3], box[k + 3] + T))
    lo = [min(c) for c in cuts]
    hi = [max(c) for c in cuts]
    for box in avoid:
        for k in range(3):
            cuts[k].update(min(max(v, lo[k]), hi[k]) for v in (box[k], box[k + 3]))
    ax = [sorted(c) for c in cuts]
    n = [len(a) - 1 for a in ax]
    grid = np.zeros(n, dtype=np.int8)        # 0 the void, 1 solid, 2 open air, 3 the owner's
    which = np.full(n, -1, dtype=np.int16)

    def cells(box):
        return tuple(slice(int(np.searchsorted(ax[k], box[k])), int(np.searchsorted(ax[k], box[k + 3]))) for k in range(3))
    for box, _, _ in spaces:
        if box not in OPENINGS:      # (an opening through the owner's own wall: their side of it is theirs, no wall of ours there)
            grid[cells(tuple(box[k] - T for k in range(3)) + tuple(box[k + 3] + T for k in range(3)))] = 1
    for box in avoid:
        sl = cells(tuple(min(max(box[k], lo[k]), hi[k]) for k in range(3)) + tuple(min(max(box[k + 3], lo[k]), hi[k]) for k in range(3)))
        grid[sl] = np.where(grid[sl] == 1, 3, grid[sl])
    for i, (box, _, _) in enumerate(spaces):
        grid[cells(box)] = 2
        which[cells(box)] = i
    used = grid != 1
    out = []
    for k in range(n[2]):
        for j in range(n[1]):
            for i in range(n[0]):
                if used[i, j, k]:
                    continue
                i2 = i
                while i2 + 1 < n[0] and not used[i2 + 1, j, k]:
                    i2 += 1
                j2 = j
                while j2 + 1 < n[1] and not used[i:i2 + 1, j2 + 1, k].any():
                    j2 += 1
                k2 = k
                while k2 + 1 < n[2] and not used[i:i2 + 1, j:j2 + 1, k2 + 1].any():
                    k2 += 1
                used[i:i2 + 1, j:j2 + 1, k:k2 + 1] = True
                box = (ax[0][i], ax[1][j], ax[2][k], ax[0][i2 + 1], ax[1][j2 + 1], ax[2][k2 + 1])
                faces = {}
                for name, sl, part in (("top", (slice(i, i2 + 1), slice(j, j2 + 1), k2 + 1), "floor"), ("bottom", (slice(i, i2 + 1), slice(j, j2 + 1), k - 1), "ceil"),
                                       ("east", (i2 + 1, slice(j, j2 + 1), slice(k, k2 + 1)), "wall"), ("west", (i - 1, slice(j, j2 + 1), slice(k, k2 + 1)), "wall"),
                                       ("north", (slice(i, i2 + 1), j2 + 1, slice(k, k2 + 1)), "wall"), ("south", (slice(i, i2 + 1), j - 1, slice(k, k2 + 1)), "wall")):
                    if any(isinstance(s, int) and (s < 0 or s >= n[q]) for q, s in enumerate(sl)):
                        continue
                    w = which[sl][grid[sl] == 2]
                    if w.size:
                        faces[name] = spaces[int(np.bincount(w).argmax())][1][part]
                out.append((tuple(int(v) for v in box), faces))
    return out


def opened_pieces():
    """What is left of each brush of the owner's the piece opens (their walls round the hole and the doorway)."""
    return [p for box, hole, _ in OPENED.values() for p in minus(box, hole)]


def axis_shift(text, d):
    """A texture axis after its face is moved by d (the texture moves with the face)."""
    from map_prefab import shift_axis
    return shift_axis(text, (-d[0], -d[1], -d[2]))


def clip_brush(sides, d, cut):
    """One of Valve's brushes (the prefab's sides: plane points, material, texture axes) moved by d and cut off at z = cut
    (what is over it goes; the cut face is nodraw): its sides as [(corners clockwise seen from outside, material, uaxis,
    vaxis)], or None if nothing is left. Any convex brush (the digger's head is chamfered on one corner)."""
    import itertools
    import numpy as np
    planes = []
    for s in sides:
        a, b, c = [np.array(p, dtype=float) + np.array(d, dtype=float) for p in s["plane"]]
        nrm = np.cross(c - a, b - a)
        nrm = nrm / np.linalg.norm(nrm)
        planes.append((nrm, float(nrm @ a), s["material"], axis_shift(s["uaxis"], d), axis_shift(s["vaxis"], d)))
    planes.append((np.array([0.0, 0.0, 1.0]), float(cut), "TOOLS/TOOLSNODRAW", "[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"))
    verts = []
    for (n1, d1, *_), (n2, d2, *_), (n3, d3, *_) in itertools.combinations(planes, 3):
        mat = np.array([n1, n2, n3])
        if abs(np.linalg.det(mat)) < 1e-9:
            continue
        x = np.linalg.solve(mat, np.array([d1, d2, d3]))
        if all(nn @ x <= dd + 0.01 for nn, dd, *_ in planes):
            if not any(np.allclose(x, v, atol=0.01) for v in verts):
                verts.append(x)
    if len(verts) < 4:
        return None
    out = []
    for nrm, dist, material, ua, va in planes:
        on = [v for v in verts if abs(nrm @ v - dist) < 0.01]
        if len(on) < 3:
            continue
        mid = sum(on) / len(on)
        u = on[0] - mid
        u = u / np.linalg.norm(u)
        w = np.cross(nrm, u)
        on.sort(key=lambda v: math.atan2((v - mid) @ w, (v - mid) @ u))
        if np.cross(on[2] - on[0], on[1] - on[0]) @ nrm < 0:
            on.reverse()
        out.append(([tuple(round(float(c), 2) for c in v) for v in on], material, ua, va))
    return out if len(out) >= 4 else None


def brush_text(vmf, faces, vis, t="\t"):
    """A solid block from clip_brush's faces (Valve's lightmap scale, not ours: the craft pass leaves it alone)."""
    s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, vmf.new_id())
    for corners, material, ua, va in faces:
        s += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, vmf.new_id(), t, " ".join("(%s %s %s)" % tuple(_n(c) for c in v) for v in corners[:3]))
        s += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%s %s %s"\n' % ((t,) + tuple(_n(c) for c in v)) for v in corners), t)
        s += ('%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "16"\n%s\t\t"smoothing_groups" "0"\n%s\t}\n'
              % (t, material.upper(), t, ua, t, va, t, t, t, t))
    return s + vmf.editor(vis, indent=t + "\t") + "%s}\n" % t


def side_face(corners, box):
    """Which face of its box a side of a box brush is (by its corners)."""
    for a, (lo_name, hi_name) in enumerate((("west", "east"), ("south", "north"), ("bottom", "top"))):
        if all(abs(c[a] - box[a]) < 0.01 for c in corners):
            return lo_name
        if all(abs(c[a] - box[a + 3]) < 0.01 for c in corners):
            return hi_name
    return None


def diggers(m, vmf, problems):
    """Valve's three diggers (the prefab valve_citadel_diggers), each moved to its place here, cut over the ceiling slab,
    their path_tracks, sounds, shakes and dust with them; Valve's outputs on the tracks go through a relay per track."""
    pf = json.load(open(os.path.join(PREFABS, "valve_citadel_diggers.json")))
    wiring = pf["wiring"]
    vis = VIS + ": the diggers (Valve's, d3_citadel_01)"
    trains, starts = [], []
    for n, (valve_name, name, (bx, by)) in enumerate(DIGGERS, start=1):
        num = valve_name[-1]
        big = [w for w in wiring if w["classname"] == "func_tracktrain" and w["keys"].get("targetname") == valve_name and len(w["brushes"]) >= 4][0]
        tracks = [w for w in wiring if w["classname"] == "path_track" and w["keys"].get("targetname", "").startswith("track_digger%s_" % num)]
        top = max(tracks, key=lambda w: w["origin"][2])
        low = min(tracks, key=lambda w: w["origin"][2])
        stroke = top["origin"][2] - low["origin"][2]
        # where the block's middle is in Valve's piece, and its foot at the top of the stroke
        blocks = [b for b in big["brushes"] if all(not s["material"].lower().startswith("tools/") for s in b)]
        vs = [c for b in blocks for s in b for c in s["corners"]]
        foot = min(c[2] for c in vs)
        block = [b for b in blocks if min(c[2] for s in b for c in s["corners"]) == foot][0]
        bvs = [c for s in block for c in s["corners"]]
        vcx = (min(c[0] for c in bvs) + max(c[0] for c in bvs)) / 2.0
        vcy = (min(c[1] for c in bvs) + max(c[1] for c in bvs)) / 2.0
        d = (bx - vcx, by - vcy, FLOOR + stroke - foot)
        cut = K_CUT + stroke          # (the cut as the train is built: at the top of its stroke)
        # Valve's train and tracks have their origin at the top of the block (over our roof once moved): the origin and
        # both tracks go down together, inside the room (a train's brushes move as its origin does, wherever that is)
        lower = (top["origin"][2] + d[2]) - (FLOOR + stroke + 32)
        # (as it spawns a train goes to its first track, its origin `height` over it: Valve's stand 5 under their trains'
        #  origins, so their pistons stop 5 short of the ground; ours are set so the piston meets the pit floor)
        settle = float(big["keys"].get("height", "0")) + (top["origin"][2] - big["origin"][2])

        def at(p):
            return (p[0] + d[0], p[1] + d[1], p[2] + d[2])
        solids = ""
        for brush in big["brushes"]:
            if all(s["material"].lower().startswith("tools/") for s in brush):
                continue          # (Valve's player clip on the block: here nobody can reach the pit at all)
            faces = clip_brush(brush, d, cut)
            if not faces:
                continue
            allv = [v for f in faces for v in f[0]]
            if any(abs(c - round(c)) > 0.01 for v in allv for c in v):
                problems.append("a corner of digger %s off the 1-unit grid" % name)
            solids += brush_text(vmf, faces, vis)
            vmf.boxes.append((tuple(min(v[k] for v in allv) for k in range(3)) + tuple(max(v[k] for v in allv) for k in range(3)), False))
        keys = dict((k, v) for k, v in big["keys"].items() if k not in ("targetname", "target", "origin"))
        o = at(big["origin"])
        keys.update({"targetname": name, "target": "%s_track_top" % name, "dmg": "0", "origin": "%s %s %s" % (_n(o[0]), _n(o[1]), _n(o[2] - lower))})
        ent = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_tracktrain"\n' % vmf.new_id() + "".join('\t"%s" "%s"\n' % kv for kv in keys.items())
        vmf.ents.append(ent + solids + vmf.editor(vis, "220 30 220") + "}\n")
        m.b.names.append((name, "func_tracktrain", m.tag))
        trains.append(name)
        # the sounds, shakes and dust Valve's tracks fire, each moved with its digger, Valve's names made ours
        rename = {valve_name: name}
        mine = [w for w in wiring if w["classname"] in ("ambient_generic", "env_shake", "env_ar2explosion")
                and w["keys"].get("targetname", "").startswith(("sound_digger%s_" % num, "shake_digger%s_" % num, "dust_digger%s" % num))]
        # (a sound and a shake of the same name also stand by Valve's gauges in their control room, which move with the
        #  diggers: of a sound or shake, only the one nearest its own digger is lifted; the dust comes in twos, both kept)
        near = {}
        for w in mine:
            if w["classname"] != "env_ar2explosion":
                dist = math.hypot(w["origin"][0] - vcx, w["origin"][1] - vcy)
                t = w["keys"]["targetname"]
                if t not in near or dist < near[t][0]:
                    near[t] = (dist, id(w))
        for w in mine:
            t = w["keys"].get("targetname", "")
            if w["classname"] != "env_ar2explosion" and near[t][1] != id(w):
                continue
            o = at(w["origin"])
            kind = t.split("_")[0]      # (sound, shake or dust: each its own name, as Valve's)
            ours = "%s_%s" % (name, kind if kind == "dust" else kind + "_" + t.split("_", 2)[-1])
            rename[t] = ours
            keys = dict(w["keys"])
            keys["targetname"] = ours
            if w["classname"] == "ambient_generic":
                keys["message"] = DIGGER_SOUND.get(keys["message"], keys["message"])
                keys["radius"] = "1250"
                keys["spawnflags"] = "48"          # (starts silent, plays once: never 'everywhere' as Valve's hit was)
                keys["pitch"] = keys["pitchstart"] = str(90 + 10 * (n - 1))
                o = (bx, by, FLOOR + 96)           # (at the foot of its piston, where it is heard)
            elif w["classname"] == "env_shake":
                keys["radius"] = str(min(int(float(keys.get("radius", "500"))), 640))
                keys["spawnflags"] = "0"
                o = (bx, by, HIGH if t.endswith("_top") else LOW)      # (felt on the catwalks, not up in the attic)
            elif w["classname"] == "env_ar2explosion":
                o = (o[0], o[1], FLOOR + 8)
            vmf.point(w["classname"], tuple(int(round(v)) for v in o), keys, vis)
        # the two path_tracks; each hands its outputs (Valve's, as they were) to a relay that lc_core_stop can cancel
        for w, which in ((top, "top"), (low, "low")):
            other = "low" if which == "top" else "top"
            relay = "%s_relay_%s" % (name, which)
            keys = dict((k, v) for k, v in w["keys"].items() if k not in ("targetname", "target"))
            keys.update({"targetname": "%s_track_%s" % (name, which), "target": "%s_track_%s" % (name, other)})
            o = at(w["origin"])
            o = (o[0], o[1], o[2] - lower - settle)
            vmf.point("path_track", o, keys, vis, connections=[("OnPass", relay, "Trigger", "", 0)], exact=True)
            wires = []
            for out, val in w.get("connections", []):
                parts = val.split(",")
                target = rename.get(parts[0], parts[0])
                if target == parts[0] and parts[0] not in rename.values():
                    continue          # (a name of Valve's this piece does not hold)
                wires.append(("OnTrigger", target, parts[1], parts[2], float(parts[3] or 0)))
            vmf.point("logic_relay", (int(round(o[0])) + 24, int(round(o[1])), int(round(o[2]))), {"targetname": relay, "StartDisabled": "0", "spawnflags": "0"}, vis,
                      connections=wires)
        starts.append(name)
    return trains


def _n(v):
    s = ("%.2f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def ladder(m, x, y, z0, z1, out, foot, top):
    """A ladder as the owner's map has them (Valve's metal ladder props up a wall at (x, y) from z0 to z1 facing `out`,
    a func_useableladder 28 out from the wall), with a dismount at the foot and one at the top where given."""
    vmf, vis = m.b.vmf, m.dv
    dx, dy = int(round(math.cos(math.radians(out)))), int(round(math.sin(math.radians(out))))
    z = z0
    while z < z1:
        vmf.point("prop_static", (x, y, z), {"model": "models/props_c17/metalladder002.mdl", "angles": "0 %d 0" % out, "skin": "0", "solid": "6",
                                             "fademindist": "-1", "fadescale": "1"}, vis)
        z += 128
    vmf.point("prop_static", (x, y, z1), {"model": "models/props_c17/metalladder002b.mdl", "angles": "0 %d 0" % ((out + 180) % 360), "skin": "0", "solid": "6",
                                          "fademindist": "-1", "fadescale": "1"}, vis)
    lx, ly = x + 28 * dx, y + 28 * dy
    vmf.point("func_useableladder", (lx, ly, (z0 + z1) // 2), {"point0": "%d %d %d" % (lx, ly, z0 + 4), "point1": "%d %d %d" % (lx, ly, z1 + 12),
                                                               "spawnflags": "0", "StartDisabled": "0"}, vis)
    vmf.point("info_ladder_dismount", (foot[0], foot[1], z0 + 1), {}, vis)
    vmf.point("info_ladder_dismount", (top[0], top[1], z1 + 1), {}, vis)


def lift(m, problems):
    """The Combine's way down: Valve's freight lift (d1_eli_01, the prefab valve_eli_lift_ride, as map_cistern.lift has
    it), its landings facing west (the power room's doorway at the top, the chamber's east wall at the bottom), its shaft
    to the east. Valve's piece has its doorway's middle at (0, 0) and its shaft toward -y: here x = LX - y, y = LY + x."""
    b, vmf = m.b, m.b.vmf
    vis = VIS + ": the lift"
    pf = json.load(open(os.path.join(PREFABS, "valve_eli_lift_ride.json")))

    def valve(x1, y1, z1, x2, y2, z2, z0):
        return (LX - y2, LY + x1, z0 + z1, LX - y1, LY + x2, z0 + z2)

    def place(x, y, z, z0):
        return (LX - y, LY + x, z0 + z)

    def turned(yaw):
        return (yaw + 90) % 360
    prop_keys = {"skin": "0", "disableshadows": "1", "fademindist": "-1", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255",
                 "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}
    cage = [w for w in pf["wiring"] if w["keys"].get("targetname") == "elevator_lab"][0]
    boxes = []
    for brush in cage["brushes"]:
        vs = [v for side in brush for v in side["corners"]]
        boxes.append(valve(*([int(round(min(v[k] for v in vs))) for k in range(3)] + [int(round(max(v[k] for v in vs))) for k in range(3)]), z0=TZ))
    high = max(bx[5] for bx in boxes) - min(bx[2] for bx in boxes)
    car = "lc_core_lift"
    vmf.brush_entity("func_door", {"targetname": car, "movedir": "90 0 0", "speed": str(LIFT_SPEED), "lip": str(high - (TZ - LZ)), "wait": "-1", "spawnflags": "0",
                                   "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "1",
                                   "noise1": "eli_lab.elevator_move", "noise2": "eli_lab.elevator_stop", "locked_sentence": "0", "unlocked_sentence": "0",
                                   "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
                     boxes, MAT["nodraw"], vis, connections=[("OnFullyOpen", car + "_gate_low", "Open", "", 0.3), ("OnFullyClosed", car + "_gate_top", "Open", "", 0.3)])
    b.names.append((car, "func_door", m.tag))
    vmf.point("prop_dynamic", place(0, -88, -8, TZ), dict(prop_keys, targetname=car + "_cage", model="models/props_lab/freightelevator.mdl", angles="0 %d 0" % turned(90),
                                                         solid="0", parentname=car), vis)

    def button(name, pos, yaw, wires, parent=None, outside=False):
        """Half-Life 2's lift button on a wall's face, facing yaw, and an unseen func_button over it."""
        more = {"parentname": parent} if parent else {}
        vmf.point("prop_dynamic", pos, dict(prop_keys, targetname=name + "_model", model="models/props_lab/freightelevatorbutton.mdl", angles="0 %d 0" % yaw,
                                            solid="0", **more), vis, outside=outside)
        dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
        x, y, z = pos
        bb = (min(x - dx, x + 8 * dx) - 6 * abs(dy), min(y - dy, y + 8 * dy) - 6 * abs(dx), z + 2, max(x - dx, x + 8 * dx) + 6 * abs(dy), max(y - dy, y + 8 * dy) + 6 * abs(dx), z + 22)
        vmf.brush_entity("func_button", dict({"targetname": name, "spawnflags": "1025", "wait": "2", "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "15", "health": "0",
                                              "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255"}, **more),
                         [bb], MAT["nodraw"], vis, connections=[("OnPressed", n, i, val, dl) for n, i, val, dl in wires])
        b.names.append((name, "func_button", m.tag))
    both = [(car + "_down", "Trigger", "", 0), (car + "_up", "Trigger", "", 0)]
    button(car + "_button", place(78, -50, 32, TZ), turned(180), both, parent=car)
    # the call buttons: in the power room on its east wall beside the doorway, and in the chamber beside its doorway
    button(car + "_call_top", (3412, 704, 272), 180, [(car + "_up", "Trigger", "", 0)], outside=True)
    button(car + "_call_low", (CH[2] - 1, LY + 76, LZ + 40), 180, [(car + "_down", "Trigger", "", 0)])
    door = {"speed": "100", "lip": "16", "wait": "-1", "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
            "noise1": "eli_lab.elevatordoor_move", "noise2": "eli_lab.elevatordoor_stop", "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255",
            "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"}
    for tag, z0, send in (("low", LZ, "Close"), ("top", TZ, "Open")):
        gate = car + "_gate_" + tag
        vmf.point("prop_dynamic", place(0, -4, 1, z0), dict(prop_keys, targetname=gate + "_model", model="models/props_lab/elevatordoor.mdl", angles="0 %d 0" % turned(90),
                                                           solid="6"), vis)
        for k, (leaf, way) in enumerate(((valve(0, -12, 0, 96, -2, 160, z0), 0), (valve(-96, -12, 0, 0, -2, 160, z0), 180))):
            wires = [("OnFullyClosed", car, send, "", 0.5), ("OnClose", gate + "_model", "SetAnimation", "close", 0), ("OnOpen", gate + "_model", "SetAnimation", "open", 0)]
            vmf.brush_entity("func_door", dict(door, targetname=gate, movedir="0 %d 0" % turned(way), spawnflags="0" if k == 0 else "4096"), [leaf], MAT["clip"], vis,
                             connections=wires if k == 0 else None)
        b.names.append((gate, "func_door", m.tag))
    m.point("logic_auto", LX + 64, LY, TZ + 150, {"spawnflags": "1"}, vis=vis, connections=[("OnMapSpawn", car + "_gate_top", "Open", "", 0.5)])
    m.point("logic_relay", LX + 80, LY, TZ + 150, {"targetname": car + "_down", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", car + "_gate_top", "Close", "", 0)])
    m.point("logic_relay", LX + 96, LY, TZ + 150, {"targetname": car + "_up", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", car + "_gate_low", "Close", "", 0)])
    # lights: a cage lamp over each landing (its own light), one in the shaft's head
    for z0 in (LZ, TZ):
        m.static("models/props_c17/light_cagelight02_on.mdl", LX - 12, LY, 90, z0 + 104)
        m.point("light_spot", LX - 4, LY, z0 + 100, {"_light": "200 225 255 60", "_lightHDR": "-1 -1 -1 1", "_cone": "70", "_inner_cone": "35", "_exponent": "1",
                                                   "angles": "-90 0 0", "pitch": "-90", "style": "0", "_constant_attn": "20", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
    m.light(LX + 96, LY, TZ + 160, "200 225 255 40")
    vmf.keep_way_clear((3413, 544, TZ, LX, 672, TZ + 116), "the lift's upper landing")
    vmf.keep_way_clear((CH[2] - 96, LY - 52, LZ, LX, LY + 52, LZ + 116), "the lift's lower landing")


def ceiling_slab():
    """The ceiling slab's pieces round the three holes the pistons go up through (224 square each)."""
    holes = [(bx - 112, by - 112, bx + 112, by + 112) for _, _, (bx, by) in DIGGERS]
    xs = sorted(set([CH[0], CH[2]] + [h[0] for h in holes] + [h[2] for h in holes]))
    strips = []
    for x1, x2 in zip(xs, xs[1:]):
        ys = [(CH[1], CH[3])]
        for h in holes:
            if h[0] < x2 and h[2] > x1:
                nys = []
                for a, c in ys:
                    if c <= h[1] or a >= h[3]:
                        nys.append((a, c))
                        continue
                    if a < h[1]:
                        nys.append((a, h[1]))
                    if c > h[3]:
                        nys.append((h[3], c))
                ys = nys
        strips.append((x1, x2, ys))
    out = []
    for x1, x2, ys in strips:
        for a, c in ys:
            for k, (ox1, oy1, ox2, oy2) in enumerate(out):
                if ox2 == x1 and oy1 == a and oy2 == c:
                    out[k] = (ox1, oy1, x2, oy2)
                    break
            else:
                out.append((x1, a, x2, c))
    return [(x1, y1, CEIL, x2, y2, CEIL + SLAB) for x1, y1, x2, y2 in out], holes


def core(args):
    b = Build("core", 0, getattr(args, "first_node", None) or 6600)
    b.test = bool(getattr(args, "test", False))
    m = Mod(b, Frame(0, 0, 0, 1), "core")
    vmf = b.vmf
    problems = []
    walls = VIS + ": walls"
    # --- the open spaces and the walls round them (sealed by construction; the owner's own brushes stand where the
    # piece meets their map: the alcove's wall with its hole, the power room's wall with its doorway) ---
    for box, faces in shell(SPACES, NEAR + opened_pieces()):
        big = max(box[3] - box[0], box[4] - box[1], box[5] - box[2]) > 1024      # (Valve's far walls: texture scale 0.5)
        vmf.world_box(box, MAT["nodraw"], top=faces.get("top"), bottom=faces.get("bottom"), vis=walls, faces=faces, tex=0.5 if big else 0.25)
    # --- the chamber: catwalks, the ceiling slab, clips round the pit, the ladder between the catwalks ---
    x1, y1, x2, y2 = CH
    px1, py1, px2, py2 = PIT
    nd = MAT["nodraw"]

    def hidden(box):
        """The faces of a detail slab that lie on a wall of the chamber or on another slab: nodraw."""
        f = {}
        if box[0] == x1:
            f["west"] = nd
        if box[3] == x2:
            f["east"] = nd
        if box[1] == y1:
            f["south"] = nd
        if box[4] == y2:
            f["north"] = nd
        return f
    for z, arms in ((LOW, [(x1, y1, x2, py1), (x1, py2, x2, y2), (x1, py1, px1, py2), (px2, py1, x2, py2)]),
                    (HIGH, [(px1, y1, x2, py1), (px1, py2, x2, y2), (px2, py1, x2, py2)])):
        for a in arms:
            box = (a[0], a[1], z - 16, a[2], a[3], z)
            faces = dict(hidden(box), top="metal/citadel_tilefloor016a")
            if a[1] == py1 and a[3] == py2:      # (the east and west arms end on the north and south arms)
                faces.update({"north": nd, "south": nd})
            vmf.detail([box], "metal/metalcombine001", vis=VIS + ": catwalks", faces=faces)
    post = (px1 - 16, 200, LOW, px1 + 16, 248, HIGH - 16)
    vmf.detail([post], "metal/citadel_metalwall090a", vis=VIS + ": catwalks")
    slab, holes = ceiling_slab()
    for box in slab:
        vmf.detail([box], "metal/citadel_metalwall090a", vis=VIS + ": ceiling", faces=dict(hidden(box), top=nd))
    clips = [(px1, py2 - 8, LOW, px2, py2, CEIL), (px1, py1, LOW, px2, py1 + 8, CEIL), (px1, py1 + 8, LOW, px1 + 8, py2 - 8, CEIL), (px2 - 8, py1 + 8, LOW, px2, py2 - 8, CEIL),
             (px1 - 8, py2, HIGH, px1, y2, CEIL), (px1 - 8, y1, HIGH, px1, 196, CEIL), (px1 - 8, 252, HIGH, px1, py1, CEIL)]
    for box in clips:      # (players and NPCs: nobody gets into the pit, nor off the upper catwalk's open ends)
        vmf.world_box(box, "tools/toolsclip", vis=VIS + ": clips", seals=False)
    ladder(m, px1 - 16, 224, LOW, HIGH, 180, (px1 - 90, 224), (px1 + 30, 224))
    # railings on the pit's edge (both catwalks; the upper one has no west side)
    rail = []
    for z, sides in ((LOW, "nsew"), (HIGH, "nse")):
        for s in sides:
            if s in "ns":
                y = py2 + 8 if s == "n" else py1 - 8
                rail += [("models/props_combine/railing_512.mdl", px1 + 224, y, 0, z), ("models/props_combine/railing_128.mdl", px2 - 64, y, 0, z)]
            else:
                x = px1 - 8 if s == "w" else px2 + 8
                rail += [("models/props_combine/railing_512.mdl", x, py1 + 224, 90, z), ("models/props_combine/railing_128.mdl", x, py2 - 64, 90, z)]
    for model, x, y, yaw, z in rail:
        m.static(model, x, y, yaw, z)
    # --- the machine: Valve's diggers ---
    diggers(m, vmf, problems)
    # --- consoles, the main console's button, where players stand to work them ---
    consoles = (("lc_core_panel_1", "models/props_combine/combine_interface001.mdl", (x1 + 27, CY), 0, LOW),
                ("lc_core_panel_2", "models/props_combine/combine_interface002.mdl", (x2 - 27, CY), 180, LOW),
                ("lc_core_panel_3", "models/props_combine/combine_interface003.mdl", (CX, y2 - 27), 270, HIGH),
                (None, "models/props_combine/combine_interface001.mdl", (2976, y1 + 27), 90, HIGH))
    for name, model, (x, y), yaw, z in consoles:
        m.static(model, x, y, yaw, z)
        if name:
            dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
            m.target(name, x + 72 * dx, y + 72 * dy, z + 8, (yaw + 180) % 360)
    # the main console's button: a Combine button on the south wall beside it, under an unseen func_button
    bx, by, bz = 3048, y1 + 1, HIGH + 48
    vmf.point("prop_dynamic", (bx, by, bz), {"targetname": "lc_core_button_model", "model": "models/props_combine/combinebutton.mdl", "angles": "0 90 0", "solid": "6",
                                             "disableshadows": "1", "fademindist": "-1", "fadescale": "1", "skin": "0", "StartDisabled": "0", "renderamt": "255",
                                             "rendercolor": "255 255 255"}, m.pv)
    vmf.brush_entity("func_button", {"targetname": "lc_core_button", "spawnflags": "1025", "wait": "3", "speed": "0", "lip": "0", "movedir": "0 0 0", "sounds": "41",
                                     "health": "0", "min_use_angle": "0.8", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                                     "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                     [(bx - 8, y1, bz - 6, bx + 8, y1 + 12, bz + 8)], "tools/toolsinvisible", m.dv)
    b.names.append(("lc_core_button", "func_button", m.tag))
    # --- lights: cold Combine wall lamps (dim) that go off when the core stops, red ones that come on, pulsing glows ---
    lamps = [((x1 + 8, 400), 0, LOW + 96), ((x2 - 8, 880), 180, LOW + 96), ((2656, y1 + 8), 90, LOW + 96), ((3104, y2 - 8), 270, LOW + 96),
             ((2720, y2 - 8), 270, HIGH + 96), ((3200, y1 + 8), 90, HIGH + 96), ((x2 - 8, 900), 180, HIGH + 96), ((x1 + 8, 760), 0, HIGH + 96)]
    for (x, y), yaw, z in lamps:
        m.static("models/props_combine/combine_light002a.mdl", x, y, yaw, z)
        dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
        m.point("light_spot", x + 12 * dx, y + 12 * dy, z - 22, {"targetname": "lc_core_lamp_blue", "_light": "147 226 240 450", "_lightHDR": "-1 -1 -1 1", "_cone": "35",
                                                               "_inner_cone": "12", "_exponent": "1", "angles": "-30 %d 0" % yaw, "pitch": "-30", "style": "0",
                                                               "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
        m.point("point_spotlight", x + 6 * dx, y + 6 * dy, z + 22, {"targetname": "lc_core_beam_blue", "angles": "30 %d 0" % yaw, "spawnflags": "1", "spotlightlength": "400",
                                                                  "spotlightwidth": "48", "rendercolor": "147 226 240", "renderamt": "120", "HDRColorScale": "0.6"}, vis=m.lv)
    for x, y in ((CX, CY - 160), (CX - 260, CY + 220), (CX + 260, CY + 220)):
        m.point("light", x, y, LOW - 160, {"targetname": "lc_core_lamp_red", "spawnflags": "1", "_light": "255 36 24 160", "_lightHDR": "-1 -1 -1 1", "style": "0",
                                           "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
    for _, _, (x, y) in DIGGERS:
        for colour, name, on in (("110 190 255", "lc_core_glow_blue", "1"), ("255 40 30", "lc_core_glow_red", "0")):
            for ox, oy in ((-120, 0), (120, 0)):
                m.point("env_sprite", x + ox, y + oy, CEIL - 10, {"targetname": name, "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "180",
                                                                  "rendercolor": colour, "scale": "0.6", "framerate": "10.0", "GlowProxySize": "4.0",
                                                                  "HDRColorScale": "1.0", "renderfx": "1", "spawnflags": on}, vis=m.lv)
    m.light(CX, CY, FLOOR + 120, "120 170 200 30")          # (a faint cold fill in the pit, always on)
    # --- pipes and cables: Valve's Combine pipes up the corners, cables hung along the walls ---
    for x, y, yaw in ((x1 + 40, y1 + 40, 45), (x2 - 40, y1 + 40, 135), (x2 - 40, y2 - 40, 225), (x1 + 40, y2 - 40, 315)):      # (in the corners, up through the catwalks: out of the way of the view of the pistons)
        m.static("models/props_combine/pipes01_cluster02a.mdl", x, y, yaw, FLOOR)
    for (ax_, ay_), (bx_, by_) in (((x1 + 8, y1 + 300), (x1 + 8, y2 - 300)), ((x2 - 8, y1 + 200), (x2 - 8, y2 - 200)), ((x1 + 300, y2 - 8), (x2 - 300, y2 - 8))):
        m.rope([(ax_, ay_, CEIL - 24), (bx_, by_, CEIL - 24)], slack=180, width=3)
    # --- sound: the deep machine loop (a wave file with a radius: a sound script would be heard across the city) ---
    m.sound(LOOP, CX, CY, (LOW + HIGH) // 2, radius=1000, volume=8, name="lc_core_loop", on=False, loops=True)
    m.soundscape(SCAPES["combine"], CX, CY, HIGH - 64, radius=900)
    m.soundscape(SCAPES["tunnel"], 1072, 1168, 0, radius=700)
    # --- stop and start (fired by the game; the map starts it as it loads) ---
    trains = [n for _, n, _ in DIGGERS]
    stop, start = [], []
    for k, t in enumerate(trains):
        for w in ("top", "low"):
            stop += [("%s_relay_%s" % (t, w), "CancelPending", "", 0), ("%s_relay_%s" % (t, w), "Disable", "", 0)]
            start += [("%s_relay_%s" % (t, w), "Enable", "", 0)]
        stop += [(t, "Stop", "", 0.05), (t + "_sound_rise", "StopSound", "", 0), (t + "_shake_hit", "StopShake", "", 0)]
        start += [(t, "StartForward", "", 0.5 + 1.5 * k)]
    stop += [("lc_core_loop", "FadeOut", "2", 0), ("lc_core_loop", "StopSound", "", 2.5), ("lc_core_lamp_blue", "TurnOff", "", 0), ("lc_core_beam_blue", "LightOff", "", 0),
             ("lc_core_glow_blue", "HideSprite", "", 0), ("lc_core_lamp_red", "TurnOn", "", 0.4), ("lc_core_glow_red", "ShowSprite", "", 0.4), ("lc_core_sound_down", "PlaySound", "", 0)]
    start += [("lc_core_loop", "PlaySound", "", 0), ("lc_core_lamp_blue", "TurnOn", "", 0), ("lc_core_beam_blue", "LightOn", "", 0), ("lc_core_glow_blue", "ShowSprite", "", 0),
              ("lc_core_lamp_red", "TurnOff", "", 0), ("lc_core_glow_red", "HideSprite", "", 0)]
    m.sound("plats/hall_elev_stop.wav", CX, CY, LOW + 32, radius=1250, volume=10, name="lc_core_sound_down", on=False, loops=False)
    m.relay("lc_core_stop", CX - 32, CY, HIGH + 64, stop)
    m.relay("lc_core_start", CX + 32, CY, HIGH + 64, start)
    m.point("logic_auto", CX, CY, HIGH + 96, {"spawnflags": "1"}, connections=[("OnMapSpawn", "lc_core_start", "Trigger", "", 1)])
    # --- the lift ---
    lift(m, problems)
    # --- the secret way: rubble at the hole, lamps along the way, the ladders ---
    for model, x, y, yaw in (("models/props_debris/concrete_chunk03a.mdl", 52, 1270, 30), ("models/props_debris/concrete_chunk05g.mdl", 44, 1352, 70),
                             ("models/props_debris/concrete_chunk05g.mdl", 70, 1330, 10)):
        vmf.point("prop_dynamic_override", (x, y, m.stand(model, 406)), {"model": model, "angles": "0 %d 0" % yaw, "solid": "0", "disableshadows": "1", "skin": "0",
                                                                          "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                                                          "renderamt": "255", "rendercolor": "255 255 255"}, m.pv, outside=True)
    ladder(m, -48, 1312, 64, 406, 180, (-80, 1240), (-14, 1312))
    ladder(m, 2256, 1168, -416, 64, 0, (2320, 1168), (2214, 1168))
    ladder(m, 2304, 1008, -896, -416, 270, (2304, 940), (2304, 1050))
    for x in (160, 760, 1360, 1960):
        m.static("models/props_c17/light_cagelight02_on.mdl", x, 1231, 270, 150)
        m.point("light_spot", x, 1216, 146, {"_light": "255 205 150 70", "_lightHDR": "-1 -1 -1 1", "_cone": "70", "_inner_cone": "35", "_exponent": "1",
                                             "angles": "-90 0 0", "pitch": "-90", "style": "0", "_constant_attn": "20", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
    for x, y, z in ((-40, 1312, 500), (-80, 1300, 360), (2304, 1168, 160), (2304, 1056, -320), (2304, 960, -400)):
        m.light(x, y, z, "255 200 140 35")
    m.rope([(-100, 1226, 180), (2240, 1226, 180)], slack=160, width=2)
    vmf.keep_way_clear((-24, 1280, 406, 32, 1344, 470), "the hole in the alcove's wall and the closet behind it")
    vmf.keep_way_clear((x1 - T, 912, LOW, x1 + 120, 1008, LOW + 112), "the way in through the chamber's west wall")
    # --- path nodes on the catwalks and at the landings (Combine units can walk the chamber) ---
    for z, ring in ((LOW, [(x1 + 96, y) for y in range(y1 + 96, y2, 192)] + [(x2 - 96, y) for y in range(y1 + 96, y2, 192)] +
                     [(x, y1 + 96) for x in range(x1 + 288, x2 - 96, 192)] + [(x, y2 - 96) for x in range(x1 + 288, x2 - 96, 192)]),
                    (HIGH, [(x2 - 96, y) for y in range(y1 + 96, y2, 192)] + [(x, y1 + 96) for x in range(px1 + 96, x2 - 96, 192)] +
                     [(x, y2 - 96) for x in range(px1 + 96, x2 - 96, 192)])):
        for x, y in ring:
            b.node(x, y, z - 40 + 8)
    b.node(CH[2] + 24, LY, LZ - 32)
    # --- the core is an area of its own, behind the hole and the doorway (else the Nexus's own areaportal in nexus_intdoor
    # would no longer part two areas: the power room would join the city through the core) ---
    vmf.areaportal((24, HOLE[1], HOLE[2], 25, HOLE[4], HOLE[5]), VIS + ": areaportals", name="lc_core_portal_hole")
    vmf.areaportal((3420, DOORWAY[1], DOORWAY[2], 3421, DOORWAY[4], DOORWAY[5]), VIS + ": areaportals", name="lc_core_portal_lift")
    # --- named spots for the game ---
    m.target("lc_core_room", CX, CY, (LOW + HIGH) // 2)
    vmf.point("info_target", (60, 1312, 414), {"targetname": "lc_core_breach", "angles": "0 180 0"}, m.dv, outside=True)
    vmf.point("info_target", (3360, LY, 240), {"targetname": "lc_core_combine_way", "angles": "0 0 0"}, m.dv, outside=True)
    b.names += [("lc_core_breach", "info_target", m.tag), ("lc_core_combine_way", "info_target", m.tag)]
    # --- checks: sealed (where it meets the owner's map, their brushes stand), on the grid, every way clear ---
    beyond = [(32, HOLE[1], HOLE[2], 33, HOLE[4], HOLE[5]), (3412, DOORWAY[1], DOORWAY[2], 3413, DOORWAY[4], DOORWAY[5])]      # (the alcove's and the power room's air)
    seal, cells = check(vmf, (CX, CY, LOW + 200), NEAR + opened_pieces() + beyond)
    for p in seal:
        print("  PROBLEM: " + p)
    problems += seal
    print("  the core: %d world brushes, %d entities; sealed with the owner's walls where it meets them (%d cells of air)" % (len(vmf.world), len(vmf.ents), cells))
    args.expect_overlap = set(OPENED)      # (--against: the two brushes of theirs it opens; only the holes through them are the piece's)
    args.out_name = getattr(args, "out", None) or "lc_core.vmf"
    return vmf, problems


# ---------------------------------------------------------------------------
# Into the owner's own file
# ---------------------------------------------------------------------------

EMPTY = ('versioninfo\n{\n\t"editorversion" "400"\n\t"editorbuild" "8873"\n\t"mapversion" "1"\n\t"formatversion" "100"\n\t"prefab" "0"\n}\n'
         'visgroups\n{\n}\nworld\n{\n\t"id" "1"\n\t"mapversion" "1"\n\t"classname" "worldspawn"\n\t"skyname" "painted"\n}\n'
         'cameras\n{\n\t"activecamera" "-1"\n}\ncordons\n{\n\t"active" "0"\n}\n')


def solid_span(text, sid):
    """Where a world brush's solid block is in the text (start of its line, end after its closing brace's line end)."""
    m = re.search(r'(\r?\n)\tsolid\r?\n\t\{\r?\n\t\t"id" "%s"\r?\n' % sid, text)
    if not m:
        return None
    s = m.start() + len(m.group(1))
    e = re.compile(r'\r?\n\t\}\r?\n').search(text, m.end())
    return s, e.end()


def open_brush(text, eol, sid, box, hole, mat, new_id, air):
    """Replace one of the owner's box brushes by its pieces round a hole. Faces on its own planes keep their material,
    texture and (on the biggest piece) their ids; the faces round the hole, and any face of theirs that was hidden and is
    now seen from the piece's open air, get `mat`. Returns the new text, {old side id: [new side ids on its plane]}, and
    the ids used."""
    span = solid_span(text, sid)
    if not span:
        sys.exit("STOP: brush %s is not in the owner's file" % sid)
    blk = text[span[0]:span[1]]
    sides = re.findall(r'\t\tside\r?\n\t\t\{\r?\n\t\t\t"id" "(\d+)"\r?\n\t\t\t"plane" "([^"]+)"(.*?)\r?\n\t\t\}', blk, re.S)
    corners = {}
    info = {}
    for side_id, plane, rest in sides:
        pts = [tuple(float(c) for c in p.split()) for p in re.findall(r'\(([^)]+)\)', plane)]
        vp = [tuple(float(c) for c in v.split()) for v in re.findall(r'"v" "([^"]+)"', rest)]
        f = side_face(vp or pts, box)
        if not f:
            sys.exit("STOP: brush %s is not the box %r it was (the owner changed it?)" % (sid, box))
        kv = dict(re.findall(r'"([^"]+)" "([^"]*)"', rest))
        info[f] = (side_id, kv)
        corners[f] = vp
    if set(info) != set(FACE_ORDER):
        sys.exit("STOP: brush %s is not a box" % sid)
    edit = re.search(r'\t\teditor\r?\n\t\t\{.*?\r?\n\t\t\}', blk, re.S).group(0)
    pieces = sorted(minus(box, hole), key=lambda p: -((p[3] - p[0]) * (p[4] - p[1]) * (p[5] - p[2])))
    ids = [new_id]
    out, on_plane = [], {info[f][0]: [] for f in FACE_ORDER}
    from map_build import FACE_AXES, FACE_SIDE

    def seen(p, f):
        a, high = FACE_SIDE[f]
        q = list(p)
        if high:
            q[a], q[a + 3] = p[a + 3], p[a + 3] + 1
        else:
            q[a], q[a + 3] = p[a] - 1, p[a]
        return any(all(q[k] < s[k + 3] and q[k + 3] > s[k] for k in range(3)) for s in air)
    for n, p in enumerate(pieces):
        if n == 0:
            psid = sid
        else:
            ids[0] += 1
            psid = str(ids[0])
        s = '\tsolid' + eol + '\t{' + eol + '\t\t"id" "%s"' % psid + eol
        for f in FACE_ORDER:
            a, high = FACE_SIDE[f]
            own = abs(p[a + 3 if high else a] - box[a + 3 if high else a]) < 0.01
            old_id, kv = info[f]
            if own and n == 0:
                fid = old_id
            else:
                ids[0] += 1
                fid = str(ids[0])
            if own:
                on_plane[old_id].append(fid)
            material = kv.get("material", "TOOLS/TOOLSNODRAW")
            uaxis, vaxis = kv.get("uaxis", ""), kv.get("vaxis", "")
            if (not own or material.lower().startswith("tools/")) and seen(p, f):
                material = mat.upper()
                u, v = FACE_AXES[f]
                uaxis, vaxis = u, v
            elif not own:
                material = "TOOLS/TOOLSNODRAW"
                u, v = FACE_AXES[f]
                uaxis, vaxis = u, v
            c = face_corners(p, f)
            s += '\t\tside' + eol + '\t\t{' + eol + '\t\t\t"id" "%s"' % fid + eol
            s += '\t\t\t"plane" "%s"' % " ".join("(%s %s %s)" % tuple(_n(x) for x in q) for q in c[:3]) + eol
            s += '\t\t\tvertices_plus' + eol + '\t\t\t{' + eol + "".join('\t\t\t\t"v" "%s %s %s"' % tuple(_n(x) for x in q) + eol for q in c) + '\t\t\t}' + eol
            s += '\t\t\t"material" "%s"' % material + eol + '\t\t\t"uaxis" "%s"' % uaxis + eol + '\t\t\t"vaxis" "%s"' % vaxis + eol
            s += '\t\t\t"rotation" "%s"' % kv.get("rotation", "0") + eol + '\t\t\t"lightmapscale" "%s"' % kv.get("lightmapscale", "16") + eol
            s += '\t\t\t"smoothing_groups" "%s"' % kv.get("smoothing_groups", "0") + eol + '\t\t}' + eol
        s += edit.replace('\r\n', '\n').replace('\n', eol) + eol + '\t}' + eol
        out.append(s)
    return text[:span[0]] + "".join(out) + text[span[1]:], on_plane, ids[0]


def into_owner(owner, piece, out):
    """The piece carried into the owner's file (map_owner_delta.py, from an empty build), then their two walls opened."""
    with tempfile.TemporaryDirectory() as tmp:
        empty = os.path.join(tmp, "empty.vmf")
        with open(empty, "w") as f:
            f.write(EMPTY)
        merged = os.path.join(tmp, "merged.vmf")
        r = subprocess.run([sys.executable, os.path.join(HERE, "map_owner_delta.py"), empty, piece, owner, merged], capture_output=True, text=True)
        print("  " + (r.stdout.strip() or r.stderr.strip()).replace("\n", "\n  "))
        if r.returncode != 0:
            sys.exit("STOP: map_owner_delta.py failed")
        text = open(merged, encoding="utf-8", errors="surrogateescape", newline="").read()
    eol = "\r\n" if "\r\n" in text[:2000] else "\n"
    nxt = max(int(x) for x in re.findall(r'"id" "(\d+)"', text)) + 1
    air = [s[0] for s in SPACES]
    changed = []
    for sid, (box, hole, mat) in OPENED.items():
        text, on_plane, nxt = open_brush(text, eol, sid, box, hole, mat, nxt, air)
        nxt += 1
        changed.append("world brush %s (x %d..%d y %d..%d z %d..%d): split round the %s, into %d pieces" % (
            sid, box[0], box[3], box[1], box[4], box[2], box[5], "hole" if sid == "21766" else "doorway", len(minus(box, hole))))
        # an overlay of theirs on a face of it is laid on the same face of every piece
        for old, new in on_plane.items():
            for m in re.finditer(r'"sides" "([^"]*)"', text):
                ids = m.group(1).split()
                if old in ids and len(new) > 1:
                    keep = [i for i in ids if i != old] + new
                    eid = re.findall(r'"id" "(\d+)"', text[:m.start()])[-1]
                    text = text[:m.start()] + '"sides" "%s"' % " ".join(keep) + text[m.end():]
                    changed.append("info_overlay %s: its faces (sides) %s now %s (the same wall, in pieces)" % (eid, old, " ".join(new)))
                    break
    with open(out, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
        f.write(text)
    print("  written: " + out)
    print("  the owner's brushes and entities changed:")
    for c in changed:
        print("    " + c)
    return changed


def main():
    import argparse
    ap = argparse.ArgumentParser(description="The suppression core in the owner's own map (their file is only read).")
    ap.add_argument("owner")
    ap.add_argument("out")
    ap.add_argument("--piece", default="lc_core.vmf", help="where the piece alone is written first (default lc_core.vmf)")
    args = ap.parse_args()
    r = subprocess.run([sys.executable, os.path.join(HERE, "map_build.py"), "core", "--out", args.piece, "--against", args.owner], capture_output=True, text=True)
    print(r.stdout.rstrip())
    if r.returncode != 0:
        print(r.stderr.rstrip())
        sys.exit("STOP: the piece has problems (above)")
    into_owner(args.owner, args.piece, args.out)


if __name__ == "__main__":
    main()
