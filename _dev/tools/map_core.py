#!/usr/bin/env python3
"""
Living City: the suppression core under City 18's Nexus (the Citadel's own thumper, which keeps the antlions out)

    python3 map_build.py core                       lc_core.vmf: the piece alone, in City 18's own coordinates
    python3 map_core.py OWNER.vmf OUT.vmf           the owner's map with the core in it: the piece built, carried in with
                                                    map_owner_delta.py (fresh ids, their visgroups, their line ends) and
                                                    their two walls opened (the only brushes of theirs that change)
    python3 map_core.py OWNER.vmf OUT.vmf --refit BEFORE.vmf
                                                    their map ALREADY holds the core (it is their file now: they edit it
                                                    in Hammer): only what this build changes since BEFORE (the piece
                                                    alone as it was last carried in) goes in, and what they set right
                                                    by hand stays (refit())

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

THE CHAMBER: Combine metal, two catwalks 128 wide round a pit 768 square (the lower one all round, the upper one on the
north, east and south walls; a ladder up a post between them), a ceiling slab 32 thick with a hole round each piston,
Episode One's glass panes (glasswindow070c) on the pit's edge of both catwalks where Combine railings were (glass()),
clips over all of the pit but the reactor's bridge and platform, Combine wall lamps (cold, dim), a red set that is dark,
pulsing glows at the pistons, consoles, Valve's pipes up the corners (1024 tall: the owner raised the pit's floor to
-1296 so they end in the slab), a deep machine loop (a wave file, radius 1000). No cables (the lesson
owner-cables-join-things).

THE REACTOR (28 November, reactor()): Episode One's core between the three pistons, at 0.43 of Valve's size: the ball 200
across over a round platform with a bridge from the west catwalk, Valve's wall beams from the west, east and north
walls and their column beam through it while the core runs; lc_core_stop turns it unstable (the wall beams off, the
column noisy, the energy discharging, arcs, red), lc_core_start heals it. The pistons stand at the pit's edge: one mid
south, one in each north corner.

THE RESISTANCE'S WAY (secret): the theater tunnel (the hatch in the street at -528 1456 793 and its ladder; the tunnel
runs east to the sewers) has a dead-end alcove on its south side (x 32..160, y 1264..1376, a power box, a stained wall).
Low in its west wall (their brush 21766) is a broken hole, 64 wide and 56 high: crouch through into a service closet,
down a ladder (342) to an old service tunnel, east 2368 under the sewers and the Nexus, down a ladder (480) at its end,
along a short passage, down a second ladder (480), and through the chamber's west wall onto the lower catwalk.

THE SEALED DOOR (28 November, sealed_door()): where the Resistance's way meets the chamber, in the owner's own brush's
place, drawn as the Nexus's doors; named lc_sealed_core, which the game locks for everybody (a beep; a Hacker's
multitool or a bypass charge opens it).

THE COMBINE'S WAY: a doorway in the power room's east wall (their brush 23625, in the niche between the two
generators), and behind it a Combine lift as City 18's own are (lift(): the owner, 28 November; it was Black Mesa
East's freight lift): a glass plate in a citadel metal frame (a func_movelinear), Combine buttons, a gate drawn as a
Nexus door at each landing, down 760 to the upper catwalk. Open sends it down, Close up.

Names for the game: lc_core_machine (the main digger's train), lc_core_digger_2, lc_core_digger_3, lc_core_stop and
lc_core_start (logic_relays), lc_core_panel_1..3 (where a player stands at a console), lc_core_button (a func_button
at the main console: a press sound only, the game hears OnPressed), lc_core_room (the chamber's middle), lc_core_breach
(at the hole in the alcove), lc_core_combine_way (in the power room before the lift). The lift: lc_core_lift (the
plate), lc_core_lift_gate_top and _low, lc_core_lift_button, lc_core_lift_down and lc_core_lift_up (logic_relays). The
door: lc_sealed_core. The reactor: lc_core_reactor_ball, lc_core_energy, lc_core_beam, lc_core_column and
lc_core_column_unstable, lc_core_reactor_tesla, lc_core_reactor_arc (all worked by the two relays).
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
FLOOR, LOW, HIGH, CEIL, ROOF = -1408, -896, -512, -304, 192      # the shell's floor, lower and upper catwalk tops, ceiling slab's underside, roof's underside
PIT_FLOOR = -1296                        # the pit's floor as the owner raised it (28 November): the corner pipes (1024 tall) then end in the ceiling slab
SLAB = 32                                # the ceiling slab's thickness
WALK = 128                               # the catwalks' width (192 until 28 November: the pit was widened for the reactor)
PIT = (CH[0] + WALK, CH[1] + WALK, CH[2] - WALK, CH[3] - WALK)   # the pit inside the lower catwalk
K_CUT = -264                             # the diggers are cut here (with each at the bottom of its stroke): over the slab, under the roof at the top
CX, CY = (CH[0] + CH[2]) // 2, (CH[1] + CH[3]) // 2
# Valve's three diggers: (their train's name, ours, where the middle of its block stands here)
# (out at the pit's edge since 28 November, the reactor between them: one mid south, one in each north corner, so the
#  west, east and north walls' beams reach the core)
DIGGERS = (("train_digger1", "lc_core_machine", (CX, CY - 272)),
           ("train_digger2", "lc_core_digger_2", (CX - 272, CY + 272)),
           ("train_digger3", "lc_core_digger_3", (CX + 272, CY + 272)))
# the reactor (Episode One's core, at 0.43 of Valve's size): the ball's middle, its radius, the round platform's reach
RZ, BALL, PLAT, BRIDGE = LOW + 128, 100, 168, 32
SCALE = 0.43
GLASS, FRAME = "glass/glasswindow070c", "metal/citadel_metalwall072a"
# the wave files under Valve's sound scripts (Garry's Mod's scripts/sounds/level_sounds_citadel.txt), with a radius
DIGGER_SOUND = {"d3_citadel.digger_hit1": "ambient/machines/floodgate_stop1.wav", "d3_citadel.digger_move1": "ambient/machines/wall_move4.wav",
                "d3_citadel.digger_stop1": "plats/hall_elev_stop.wav"}
LOOP = "ambient/levels/canals/generator_ambience_loop1.wav"      # (a deep machine loop the owner's own map already plays)
# the lift (the Combine's way): its landings' front plane, the cage's middle across, the two landings' floors
LX, LY, LZ, TZ = 3444, 608, HIGH, 248
LIFT_SPEED = 180                         # (City 18's nexus_elev lifts)
# the secret way and the Combine's doorway: where the piece opens the owner's own brushes (id: their box, the hole, the
# material the hole's new faces get)
HOLE = (16, 1280, 406, 32, 1344, 462)
DOORWAY = (3413, 544, 248, 3429, 672, 376)
OPENINGS = (HOLE, DOORWAY)
SEALED = (2356, 896, -904, 2360, 1024, -784)      # the owner's own brush (4668765 in their file of 28 November), now the sealed door
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
        d = (bx - vcx, by - vcy, PIT_FLOOR + stroke - foot)
        cut = K_CUT + stroke          # (the cut as the train is built: at the top of its stroke)
        # Valve's train and tracks have their origin at the top of the block (over our roof once moved): the origin and
        # both tracks go down together, inside the room (a train's brushes move as its origin does, wherever that is)
        lower = (top["origin"][2] + d[2]) - (PIT_FLOOR + stroke + 32)
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
                o = (bx, by, PIT_FLOOR + 96)       # (at the foot of its piston, where it is heard)
            elif w["classname"] == "env_shake":
                keys["radius"] = str(min(int(float(keys.get("radius", "500"))), 640))
                keys["spawnflags"] = "0"
                o = (bx, by, HIGH if t.endswith("_top") else LOW)      # (felt on the catwalks, not up in the attic)
            elif w["classname"] == "env_ar2explosion":
                o = (o[0], o[1], PIT_FLOOR + 8)
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


def zprism(outline, z1, z2, mat, top=None, bottom=None):
    """A flat outline ([(x, y), ...] in order) stood up from z1 to z2: the faces for convex_text (detail_shapes)."""
    faces = [([(x, y, z2) for x, y in outline], top or mat), ([(x, y, z1) for x, y in outline], bottom or mat)]
    for k in range(len(outline)):
        (ax, ay), (bx, by) = outline[k], outline[(k + 1) % len(outline)]
        faces.append(([(ax, ay, z1), (bx, by, z1), (bx, by, z2), (ax, ay, z2)], mat))
    return faces


def eight(cx, cy, r):
    """An octagon's corners on the grid, r from the middle to each flat side."""
    k = int(round(r * 0.4142))
    return [(cx + r, cy + k), (cx + k, cy + r), (cx - k, cy + r), (cx - r, cy + k), (cx - r, cy - k), (cx - k, cy - r), (cx + k, cy - r), (cx + r, cy - k)]


def nexus_door(box, thin, foot=12, hidden=0):
    """The boxes of a door as the Nexus's own are drawn in the owner's map (nexus_intdoor, nexus_importantdoor: a frame of
    citadel_metalwall072c round a panel of citadel_metalwall090a over a hazard stripe, pipe metal on its edges), for
    brush_entity: [(box, {face: material})]. thin: the axis it is thin along ("x" or "y"); foot: the stripe's height;
    hidden: how much of each end of its width stays inside the wall (the frame is drawn inside that)."""
    x1, y1, z1, x2, y2, z2 = box
    nd, rim, frame, panel, stripe = MAT["nodraw"], "metal/metalpipe001a", "metal/citadel_metalwall072c", "metal/citadel_metalwall090a", "dev/dev_hazzardstripe01a"
    big = ("west", "east") if thin == "x" else ("south", "north")
    ends = ("south", "north") if thin == "x" else ("west", "east")

    def piece(a, b, za, zb, mat, low_end=nd, high_end=nd, top=nd, bottom=nd):
        bx = (x1, a, za, x2, b, zb) if thin == "x" else (a, y1, za, b, y2, zb)
        return (bx, {big[0]: mat, big[1]: mat, ends[0]: low_end, ends[1]: high_end, "top": top, "bottom": bottom})
    w1, w2 = (y1, y2) if thin == "x" else (x1, x2)
    post = hidden + 4
    return [piece(w1, w2, z1, z1 + foot, stripe, stripe, stripe, nd, rim),
            piece(w1, w1 + post, z1 + foot, z2, frame, rim, nd, rim),
            piece(w2 - post, w2, z1 + foot, z2, frame, nd, rim, rim),
            piece(w1 + post, w2 - post, z2 - 4, z2, frame, nd, nd, rim),
            piece(w1 + post, w2 - post, z1 + foot, z2 - 4, panel)]


def sealed_door(m):
    """The door where the service tunnel meets the chamber (the owner, 28 November: a brush of theirs, 4 by 128 by 120 at
    2358 960 -844, "make it a combine door like the rest of the nexus ... it just makes a little beep and it can only be
    hacked open by the resistance hacker OR the combine bypass charge"). Drawn as the Nexus's doors are, in their brush's
    place, sliding up; the game seals any door named lc_sealed... by itself (sv_livingcity_doors.lua): locked for
    everybody, a beep at E, opened only by a Hacker's multitool or a bypass charge, for its 30 seconds (wait -1: the game
    shuts it)."""
    b, vmf = m.b, m.b.vmf
    name = "lc_sealed_core"
    keys = {"targetname": name, "movedir": "-90 0 0", "speed": "100", "lip": "5", "wait": "-1", "spawnflags": "2048", "dmg": "0", "forceclosed": "0", "health": "0",
            "ignoredebris": "0", "loopmovesound": "0", "noise1": "doors/doormove1.wav", "noise2": "doors/doormove2.wav", "locked_sentence": "0",
            "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "0"}
    vmf.brush_entity("func_door", keys, nexus_door(SEALED, "x", foot=20, hidden=16), MAT["nodraw"], VIS + ": the sealed door")
    b.names.append((name, "func_door", m.tag))


def combine_button(m, name, wall, yaw, wires, vis, outside=False):
    """A Combine button as City 18's lifts have them (nexus_elev1_button: props_combine/combinebutton.mdl 6 out from the
    wall under an unseen func_button that locks itself for 2.2 s and plays the model's press). wall: the point on the
    wall's face; yaw: the way it faces. Every button of one name locks together."""
    b, vmf = m.b, m.b.vmf
    dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
    x, y, z = wall
    vmf.point("prop_dynamic", (x + 6 * dx, y + 6 * dy, z), {"targetname": name + "_model", "model": "models/props_combine/combinebutton.mdl", "angles": "0 %d 0" % yaw,
                                                             "solid": "0", "disableshadows": "1", "fademindist": "-1", "fadescale": "1", "skin": "0", "StartDisabled": "0",
                                                             "renderamt": "255", "rendercolor": "255 255 255"}, vis, outside=outside)
    box = (min(x, x + 12 * dx) - 8 * abs(dy), min(y, y + 12 * dy) - 8 * abs(dx), z - 6, max(x, x + 12 * dx) + 8 * abs(dy), max(y, y + 12 * dy) + 8 * abs(dx), z + 8)
    vmf.brush_entity("func_button", {"targetname": name, "spawnflags": "1025", "wait": "3", "speed": "0", "lip": "0", "movedir": "0 0 0", "sounds": "0", "health": "0",
                                     "min_use_angle": "0.8", "locked_sound": "0", "unlocked_sound": "0", "locked_sentence": "0", "unlocked_sentence": "0",
                                     "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                     [box], "tools/toolsinvisible", vis,
                     connections=[("OnPressed", name, "Lock", "", 0), ("OnPressed", name, "Unlock", "", 2.2), ("OnPressed", name + "_model", "SetAnimation", "press", 0)]
                     + [("OnPressed", n, i, val, dl) for n, i, val, dl in wires])
    if (name, "func_button", m.tag) not in b.names:
        b.names.append((name, "func_button", m.tag))


def combine_lamp(m, x, y, yaw, z, colour="147 226 240 450", name=None, beam=False, pitch=-30):
    """The Combine's wall light (props_combine/combine_light002a: its origin is at its FOOT, the model 44 tall) with its
    light at its lens, where the owner put them (28 November: the spots had been set 22 under the model's foot and the
    beams 22 over it, "misaligned by like 6 feet"): the light_spot 12 out and 20 up, the beam beside it."""
    m.static("models/props_combine/combine_light002a.mdl", x, y, yaw, z)
    dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
    keys = {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_cone": "35", "_inner_cone": "12", "_exponent": "1", "angles": "%d %d 0" % (pitch, yaw), "pitch": str(pitch),
            "style": "0", "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1"}
    if name:
        keys["targetname"] = name + "_blue"
    m.point("light_spot", x + 12 * dx, y + 12 * dy, z + 20, keys, vis=m.lv)
    if beam:
        m.point("point_spotlight", x + 6 * dx, y + 6 * dy, z + 22, {"targetname": "lc_core_beam_blue", "angles": "%d %d 0" % (-pitch, yaw), "spawnflags": "1",
                                                                  "spotlightlength": "400", "spotlightwidth": "48", "rendercolor": "147 226 240", "renderamt": "120",
                                                                  "HDRColorScale": "0.6"}, vis=m.lv)


def lift(m, problems):
    """The Combine's way down, as City 18's own lifts are (the owner, 28 November: "replace the cargo / eli's lab lift with
    a combine lift; there are several on the C18 map that are made of combine glass and use combine buttons"): a
    func_movelinear like their nexus_elev1 (a plate of Combine glass in a frame of citadel_metalwall072a, their sounds,
    their speed), Combine buttons on the shaft's wall at both floors and outside both doorways. Their lifts run in open
    shafts 364 deep; this one is 760, so each landing has a gate drawn as a Nexus door (a func_movelinear too: E does
    nothing to it), open only while the plate is there. Open sends the plate down, Close up."""
    b, vmf = m.b, m.b.vmf
    vis = VIS + ": the lift"
    nd = MAT["nodraw"]
    car = "lc_core_lift"
    x1, y1, x2, y2 = LX + 2, LY - 94, LX + 190, LY + 94      # (2 clear of the shaft's walls all round)
    side = {"top": FRAME, "bottom": FRAME, "west": nd, "east": nd, "north": nd, "south": nd}
    plate = [((x1, y1, TZ - 8, x1 + 8, y2, TZ), dict(side, east=FRAME)), ((x2 - 8, y1, TZ - 8, x2, y2, TZ), dict(side, west=FRAME)),
             ((x1 + 8, y1, TZ - 8, x2 - 8, y1 + 8, TZ), dict(side, north=FRAME)), ((x1 + 8, y2 - 8, TZ - 8, x2 - 8, y2, TZ), dict(side, south=FRAME)),
             ((x1 + 8, y1 + 8, TZ - 8, x2 - 8, y2 - 8, TZ), {"top": "glass/combineglass001a", "bottom": "glass/combineglass001a", "west": nd, "east": nd, "north": nd, "south": nd})]
    vmf.brush_entity("func_movelinear", {"targetname": car, "movedir": "90 0 0", "movedistance": str(TZ - LZ), "speed": str(LIFT_SPEED), "startposition": "0",
                                         "blockdamage": "0", "startsound": "d3_citadel.small_elevator_move", "stopsound": "eli_lab.elevatordoor_stop",
                                         "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"},
                     plate, nd, vis, connections=[("OnFullyOpen", car + "_gate_low", "Open", "", 0.3), ("OnFullyClosed", car + "_gate_top", "Open", "", 0.3)])
    b.names.append((car, "func_movelinear", m.tag))
    gate = {"movedir": "-90 0 0", "speed": "100", "startposition": "0", "blockdamage": "0", "startsound": "doors/doormove1.wav", "stopsound": "doors/doormove2.wav",
            "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"}
    for tag, box, send in (("low", (LX - 10, LY - 52, LZ, LX - 4, LY + 52, LZ + 116), "Close"), ("top", (LX - 10, 544, TZ, LX - 4, 672, TZ + 128), "Open")):
        name = car + "_gate_" + tag
        vmf.brush_entity("func_movelinear", dict(gate, targetname=name, movedistance=str(box[5] - box[2] - 5)), nexus_door(box, "x"), nd, vis,
                         connections=[("OnFullyClosed", car, send, "", 0.5)])
        b.names.append((name, "func_movelinear", m.tag))
    both = [(car + "_down", "Trigger", "", 0), (car + "_up", "Trigger", "", 0)]
    button = car + "_button"
    combine_button(m, button, (3413, 704, TZ + 56), 180, both, vis, outside=True)      # (in the power room, on its east wall beside the doorway)
    combine_button(m, button, (LX, LY + 80, TZ + 56), 0, both, vis)                    # (in the shaft, beside the upper landing)
    combine_button(m, button, (LX, LY + 80, LZ + 56), 0, both, vis)                    # (in the shaft, beside the lower landing)
    combine_button(m, button, (CH[2], LY + 76, LZ + 56), 180, both, vis)               # (in the chamber, beside its doorway)
    m.point("logic_auto", LX + 64, LY, TZ + 150, {"spawnflags": "1"}, vis=vis, connections=[("OnMapSpawn", car + "_gate_top", "Open", "", 0.5)])
    m.point("logic_relay", LX + 80, LY, TZ + 150, {"targetname": car + "_down", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", car + "_gate_top", "Close", "", 0)])
    m.point("logic_relay", LX + 96, LY, TZ + 150, {"targetname": car + "_up", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", car + "_gate_low", "Close", "", 0)])
    # lights, as their lifts' shafts have them: one fixture at the shaft's head, over the plate's reach (a lamp lower down
    # would stand in the plate's way: it fills the shaft), shining down, and dim fills down the shaft with no fixture
    combine_lamp(m, LX + 184, LY, 180, TZ + 120, colour="147 226 240 500", pitch=-70)
    for z in (TZ - 250, TZ - 500, LZ + 96):
        m.light(LX + 96, LY, z, "147 226 240 30")
    # the niche's floor in the power room (their brush 23576) ends at the shaft: its end, nodraw where it faced the void, now
    # looks into the shaft (riders pass it): covered by a plate of ours rather than changing their brush
    vmf.detail([(LX, 544, TZ - 16, LX + 1, 672, TZ)], "metal/citadel_metalwall090a", vis=vis, faces={"west": MAT["nodraw"]})
    vmf.keep_way_clear((3413, 544, TZ, LX, 672, TZ + 116), "the lift's upper landing")
    vmf.keep_way_clear((CH[2] - 96, LY - 52, LZ, LX, LY + 52, LZ + 116), "the lift's lower landing")


def glass(m):
    """Glass round the pit in place of the Combine railings (the owner, 28 November: "replace the combine railing around
    the perimeter of the walkway with glass, similar to the EP1 reactor room's big glass panes between the consoles and
    reactor core"): Episode One's pane (glasswindow070c, 4 thick) on a low kerb under a thin cap, 112 high, on both
    catwalks, with posts at the corners and at the bridge's mouth. One long pane a side (few faces)."""
    vmf = m.b.vmf
    x1, y1, x2, y2 = CH
    px1, py1, px2, py2 = PIT
    nd = MAT["nodraw"]
    vis = VIS + ": glass"
    by1, by2 = CY - BRIDGE, CY + BRIDGE
    # a run: (axis it runs along, where it stands across, from, to), each between two posts (a post is 1 proud of the kerb
    # all round: no two faces in one plane); the pane stands 6 back from the pit's edge, on the catwalk
    w, e, s_, n = px1 - 6, px2 + 6, py1 - 6, py2 + 6
    hw = px1 + 4          # (the upper catwalk's open west ends)
    for z, runs, posts in (
            (LOW, [("x", s_, w + 5, e - 5), ("x", n, w + 5, e - 5), ("y", e, s_ + 5, n - 5), ("y", w, s_ + 5, by1 - 10), ("y", w, by2 + 10, n - 5)],
             [(w, s_), (e, s_), (w, n), (e, n), (w, by1 - 5), (w, by2 + 5)]),
            (HIGH, [("x", s_, hw + 5, e - 5), ("x", n, hw + 5, e - 5), ("y", e, s_ + 5, n - 5), ("y", hw, y1, 196), ("y", hw, n + 5, y2)],
             [(e, s_), (e, n), (hw, s_), (hw, n)])):
        kerb, pane, cap = [], [], []
        for axis, at, a, c in runs:
            def box(half, za, zb):
                return (a, at - half, za, c, at + half, zb) if axis == "x" else (at - half, a, za, at + half, c, zb)
            kerb.append(box(4, z, z + 8))
            pane.append(box(2, z + 8, z + 108))
            cap.append(box(4, z + 108, z + 112))
        vmf.detail(kerb, FRAME, vis=vis, faces={"bottom": nd})
        vmf.detail(cap, FRAME, vis=vis)
        vmf.detail(pane, GLASS, vis=vis, faces={"top": nd, "bottom": nd})
        vmf.detail([(x - 5, y - 5, z, x + 5, y + 5, z + 114) for x, y in posts], FRAME, vis=vis, faces={"bottom": nd})


def reactor(m):
    """Episode One's reactor core between the pistons (the owner, 28 November: "can we stick the reactor from EP1 inside
    this room? the little walkway around the reactor core and the core reactor effect itself right in between all the
    thumpers? Will they fit?"). Valve's ball is 462 across in a hall about 1700 wide (ep1_citadel_03); the pit is 768, so
    it is here at 0.43 of that: the ball (props_combine/coreball.mdl, as Valve's second one, core_room2: a prop_dynamic
    with two env_citadel_energy_core in it) 200 across over a round platform 336 across with a bridge from the west
    catwalk, on a column from the pit's floor, under an emitter hung from the ceiling slab. Then: "copy the EP1 beams
    that shoot at the reactor so they stick out of the walls ... those indicate the reactor is healthy, and when the
    consoles get blown up or hacked, those beams all shut off and the reactor core switches to it's unstable look":
    Valve's beam_core (sprites/core_beam1) from a nozzle on the west, east and north walls to the ball, and their
    column beam (effects/bluelaser1) through it, clean while the core runs; lc_core_stop turns the wall beams off, the
    column to Valve's noisy one, the energy beating (lc_core_reactor_pulse), the ball and the light red, arcs on; lc_core_start all back.
    Returns the wires for the two relays. Names: lc_core_reactor_ball, lc_core_energy, lc_core_reactor_target,
    lc_core_beam, lc_core_beam_glow, lc_core_column, lc_core_column_unstable, lc_core_reactor_tesla, lc_core_reactor_arc."""
    b, vmf = m.b, m.b.vmf
    x1, y1, x2, y2 = CH
    px1 = PIT[0]
    nd = MAT["nodraw"]
    vis = VIS + ": the reactor (Valve's, ep1_citadel_03)"
    metal, top = "metal/citadel_metalwall090a", "metal/citadel_tilefloor016a"
    # the platform, its bridge, the column under it, the emitters under and over the ball
    vmf.detail_shapes([zprism(eight(CX, CY, PLAT), LOW - 16, LOW, "metal/metalcombine001", top=top),
                       zprism(eight(CX, CY, 48), PIT_FLOOR, LOW - 16, metal, top=nd, bottom=nd),
                       zprism(eight(CX, CY, 96), LOW - 40, LOW - 16, metal, top=nd),
                       zprism(eight(CX, CY, 40), LOW, LOW + 12, metal, bottom=nd),
                       zprism(eight(CX, CY, 40), RZ + BALL + 24, CEIL, metal, top=nd),
                       zprism(eight(CX, CY, 56), CEIL - 24, CEIL, metal, top=nd)], vis)
    vmf.detail([(px1, CY - BRIDGE, LOW - 16, CX - PLAT, CY + BRIDGE, LOW)], "metal/metalcombine001", vis=vis, top=top, faces={"west": nd, "east": nd})
    m.static("models/props_combine/combine_core_ring01.mdl", CX, CY, 0, RZ + BALL + 30)
    # nobody into the pit: clips over all of it but the bridge and the platform, and round the ball
    clips = [(PIT[0], CY + PLAT, LOW, PIT[2], PIT[3], CEIL), (PIT[0], PIT[1], LOW, PIT[2], CY - PLAT, CEIL), (CX + PLAT, CY - PLAT, LOW, PIT[2], CY + PLAT, CEIL),
             (PIT[0], CY - PLAT, LOW, CX - PLAT, CY - BRIDGE, CEIL), (PIT[0], CY + BRIDGE, LOW, CX - PLAT, CY + PLAT, CEIL)]
    for box in clips:
        vmf.world_box(box, "tools/toolsclip", vis=VIS + ": clips", seals=False)
    k = int(round(PLAT * 0.4142))
    corners = [zprism([(CX + sx * PLAT, CY + sy * k), (CX + sx * k, CY + sy * PLAT), (CX + sx * PLAT, CY + sy * PLAT)], LOW, CEIL, "tools/toolsclip") for sx in (-1, 1) for sy in (-1, 1)]
    for faces in corners + [zprism(eight(CX, CY, BALL + 8), LOW, RZ + BALL + 24, "tools/toolsclip")]:
        vmf.world.append(vmf.convex_text(faces, VIS + ": clips"))
    vmf.keep_way_clear((px1 - 64, CY - BRIDGE, LOW, CX - 240, CY + BRIDGE, LOW + 96), "the bridge to the reactor")      # (the checker knows the ball at Valve's size: 231 round)
    # the ball, Valve's energy in it, what the beams aim at
    vmf.point("prop_dynamic", (CX, CY, RZ), {"targetname": "lc_core_reactor_ball", "model": "models/props_combine/coreball.mdl", "angles": "0 0 0", "solid": "0",
                                             "modelscale": str(SCALE), "lc_scale": str(SCALE), "disableshadows": "1", "fademindist": "-1", "fadescale": "1", "skin": "0",
                                             "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, vis)
    b.names.append(("lc_core_reactor_ball", "prop_dynamic", m.tag))
    for pitch in (90, -90):
        m.point("env_citadel_energy_core", CX, CY, RZ, {"targetname": "lc_core_energy", "angles": "%d 0 0" % pitch, "scale": "2", "spawnflags": "2"}, vis=vis)
    m.point("info_target", CX, CY, RZ, {"targetname": "lc_core_reactor_target", "angles": "0 0 0"}, vis=vis)
    m.point("info_target", CX, CY, LOW + 12, {"targetname": "lc_core_column_low", "angles": "0 0 0"}, vis=vis)
    m.point("info_target", CX, CY, RZ + BALL + 24, {"targetname": "lc_core_column_top", "angles": "0 0 0"}, vis=vis)
    beam = {"renderamt": "255", "rendercolor": "255 255 255", "Radius": "256", "life": "0", "StrikeTime": "1", "damage": "0", "framestart": "0", "framerate": "0",
            "decalname": "Bigshot", "HDRColorScale": "1.0"}
    for name, width, noise, flags in (("lc_core_column", 40, 0, 385), ("lc_core_column_unstable", 40, 8, 384)):
        m.point("env_beam", CX + (4 if noise else 0), CY, LOW + 16, dict(beam, targetname=name, LightningStart="lc_core_column_low", LightningEnd="lc_core_column_top",
                                                                       texture="effects/bluelaser1.vmt", BoltWidth=str(width), NoiseAmplitude=str(noise),
                                                                       TextureScroll="2", spawnflags=str(flags)), vis=vis)
    # the wall beams (Valve's beam_core): a nozzle on the west, east and north walls 256 over the lower catwalk (over heads,
    # under the upper catwalk, over the lower glass), each its own start
    for n, (wx, wy, dx, dy) in enumerate(((x1, CY, 1, 0), (x2, CY, -1, 0), (CX, y2, 0, -1)), start=1):
        z = LOW + 256
        ax, ay = abs(dy), abs(dx)      # (along the wall)
        base = (min(wx, wx + 32 * dx) - 32 * ax, min(wy, wy + 32 * dy) - 32 * ay, z - 32, max(wx, wx + 32 * dx) + 32 * ax, max(wy, wy + 32 * dy) + 32 * ay, z + 32)
        tip = (min(wx + 32 * dx, wx + 48 * dx) - 16 * ax, min(wy + 32 * dy, wy + 48 * dy) - 16 * ay, z - 16,
               max(wx + 32 * dx, wx + 48 * dx) + 16 * ax, max(wy + 32 * dy, wy + 48 * dy) + 16 * ay, z + 16)
        vmf.detail([base, tip], metal, vis=vis)
        sx, sy = wx + 52 * dx, wy + 52 * dy
        start = "lc_core_beam_%d" % n
        m.point("info_target", sx, sy, z, {"targetname": start, "angles": "0 0 0"}, vis=vis)
        m.point("env_beam", sx, sy, z + 8, dict(beam, targetname="lc_core_beam", LightningStart=start, LightningEnd="lc_core_reactor_target",
                                                texture="sprites/core_beam1.vmt", BoltWidth="12", NoiseAmplitude="0", TextureScroll="9", spawnflags="513"), vis=vis)
        m.point("env_sprite", sx, sy, z, {"targetname": "lc_core_beam_glow", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                          "rendercolor": "190 225 255", "scale": "0.5", "framerate": "10.0", "GlowProxySize": "4.0", "HDRColorScale": "1.0",
                                          "renderfx": "0", "spawnflags": "1"}, vis=m.lv)
    # its light and glow (the blue with the room's blue lamps, the red with its red ones: no light style of its own), its arcs
    for colour, name, on, scale in (("150 210 255", "lc_core_glow_blue", "1", "2.2"), ("255 80 40", "lc_core_glow_red", "0", "2.6")):
        m.point("env_sprite", CX, CY, RZ, {"targetname": name, "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "200", "rendercolor": colour,
                                           "scale": scale, "framerate": "10.0", "GlowProxySize": "8.0", "HDRColorScale": "1.0", "renderfx": "1", "spawnflags": on}, vis=m.lv)
    lit = {"_lightHDR": "-1 -1 -1 1", "style": "0", "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1"}
    for dx, dy in ((0, -1), (-1, 1), (1, 1)):      # (round the ball, between the pistons: a light inside the ball's clip would light nothing)
        x, y = CX + dx * (BALL + 30), CY + dy * (BALL + 30)
        m.point("light", x, y, RZ, dict(lit, targetname="lc_core_lamp_blue", _light="150 210 255 220", spawnflags="0"), vis=m.lv)
        m.point("light", x, y, RZ + 8, dict(lit, targetname="lc_core_lamp_red", _light="255 70 35 260", spawnflags="1"), vis=m.lv)
    m.point("point_tesla", CX, CY, RZ, {"targetname": "lc_core_reactor_tesla", "m_flRadius": "230", "m_Color": "255 150 90", "beamcount_min": "2", "beamcount_max": "4",
                                        "thick_min": "2", "thick_max": "7", "lifetime_min": "0.05", "lifetime_max": "0.3", "interval_min": "0.3", "interval_max": "1.2",
                                        "texture": "sprites/physbeam.vmt", "m_SoundName": "DoSpark", "spawnflags": "0"}, vis=vis)
    m.sound("ambient/energy/electric_loop.wav", CX, CY, RZ, radius=900, volume=7, name="lc_core_reactor_arc", on=False, loops=True)
    # unstable, it beats: the energy drawn in and let go again at odd moments, the ball flaring red (Valve's own energy
    # entity has two looks only: "start on" is its steady discharge, StartCharge the drawing in)
    m.point("logic_timer", CX + 16, CY, RZ + BALL + 40, {"targetname": "lc_core_reactor_pulse", "UseRandomTime": "1", "LowerRandomBound": "0.6", "UpperRandomBound": "2.2",
                                                         "StartDisabled": "1", "spawnflags": "0"}, vis=vis,
            connections=[("OnTimer", "lc_core_energy", "StartCharge", "0.4", 0), ("OnTimer", "lc_core_energy", "StartDischarge", "", 0.45),
                         ("OnTimer", "lc_core_reactor_ball", "Color", "255 60 30", 0), ("OnTimer", "lc_core_reactor_ball", "Color", "255 150 90", 0.45)])
    stop = [("lc_core_beam", "TurnOff", "", 0), ("lc_core_beam_glow", "HideSprite", "", 0), ("lc_core_column", "TurnOff", "", 0), ("lc_core_column_unstable", "TurnOn", "", 0.1),
            ("lc_core_reactor_pulse", "Enable", "", 0.2), ("lc_core_reactor_ball", "Color", "255 150 90", 0.2), ("lc_core_reactor_tesla", "TurnOn", "", 0.4),
            ("lc_core_reactor_arc", "PlaySound", "", 0.4)]
    start = [("lc_core_beam", "TurnOn", "", 1.5), ("lc_core_beam_glow", "ShowSprite", "", 1.5), ("lc_core_column_unstable", "TurnOff", "", 1.5), ("lc_core_column", "TurnOn", "", 1.5),
             ("lc_core_reactor_pulse", "Disable", "", 0), ("lc_core_energy", "StartDischarge", "", 1.0), ("lc_core_reactor_ball", "Color", "255 255 255", 1.5),
             ("lc_core_reactor_tesla", "TurnOff", "", 0),
             ("lc_core_reactor_arc", "StopSound", "", 0)]
    return stop, start


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
    # the pit's floor where the owner raised it to (their brush: the shell's own floor slab, moved 112 up; the old one
    # under it is still the shell's, out of sight)
    vmf.world_box((x1 - T, y1 - T, PIT_FLOOR - T, x2 + T, y2 + T, PIT_FLOOR), nd, top=COMBINE["floor"], vis=walls, tex=0.5)

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
    clips = [(px1 - 8, py2, HIGH, px1, y2, CEIL), (px1 - 8, y1, HIGH, px1, 196, CEIL)]      # (the ladder comes up between 196 and the pit's edge)
    for box in clips:      # (players and NPCs: nobody off the upper catwalk's open ends; the pit's own clips: reactor())
        vmf.world_box(box, "tools/toolsclip", vis=VIS + ": clips", seals=False)
    ladder(m, px1 - 16, 224, LOW, HIGH, 180, (px1 - 90, 224), (px1 + 30, 224))
    # glass on the pit's edge (both catwalks), where the Combine railings were until 28 November
    glass(m)
    # --- the machine: Valve's diggers ---
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
        combine_lamp(m, x, y, yaw, z, name="lc_core_lamp", beam=True)
    for x, y in ((CX, CY - 160), (CX - 260, CY + 220), (CX + 260, CY + 220)):
        m.point("light", x, y, LOW - 160, {"targetname": "lc_core_lamp_red", "spawnflags": "1", "_light": "255 36 24 160", "_lightHDR": "-1 -1 -1 1", "style": "0",
                                           "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
    for _, _, (x, y) in DIGGERS:
        for colour, name, on in (("110 190 255", "lc_core_glow_blue", "1"), ("255 40 30", "lc_core_glow_red", "0")):
            for ox, oy in ((-120, 0), (120, 0)):
                m.point("env_sprite", x + ox, y + oy, CEIL - 10, {"targetname": name, "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "180",
                                                                  "rendercolor": colour, "scale": "0.6", "framerate": "10.0", "GlowProxySize": "4.0",
                                                                  "HDRColorScale": "1.0", "renderfx": "1", "spawnflags": on}, vis=m.lv)
    m.light(CX - 200, CY - 40, PIT_FLOOR + 120, "120 170 200 30")          # (a faint cold fill in the pit, always on)
    # --- pipes: Valve's Combine pipes up the corners, from the pit's floor to the ceiling slab (the model is 1024 tall: the
    # owner raised the floor 112 so they end in the slab, 28 November: "you made it too tall for the pipe props"). No cables:
    # the three hung along bare walls joined nothing (the owner: "not even close to the props it was supposed to be by") ---
    for x, y, yaw in ((x1 + 40, y1 + 40, 45), (x2 - 40, y1 + 40, 135), (x2 - 40, y2 - 40, 225), (x1 + 40, y2 - 40, 315)):      # (in the corners, up through the catwalks: out of the way of the view of the pistons)
        m.static("models/props_combine/pipes01_cluster02a.mdl", x, y, yaw, PIT_FLOOR)
    # --- sound: the deep machine loop (a wave file with a radius: a sound script would be heard across the city) ---
    m.sound(LOOP, CX, CY, (LOW + HIGH) // 2, radius=1000, volume=8, name="lc_core_loop", on=False, loops=True)
    m.soundscape(SCAPES["combine"], CX, CY, HIGH - 64, radius=900)
    m.soundscape(SCAPES["tunnel"], 1072, 1168, 0, radius=700)
    # --- stop and start (fired by the game; the map starts it as it loads) ---
    trains = [n for _, n, _ in DIGGERS]
    stop, start = reactor(m)
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
    # --- the lift, the sealed door at the service tunnel's end ---
    lift(m, problems)
    sealed_door(m)
    # --- the secret way: rubble at the hole, lamps along the way, the ladders ---
    for model, x, y, yaw in (("models/props_debris/concrete_chunk03a.mdl", 52, 1270, 30), ("models/props_debris/concrete_chunk05g.mdl", 44, 1352, 70),
                             ("models/props_debris/concrete_chunk05g.mdl", 70, 1330, 10)):
        vmf.point("prop_dynamic_override", (x, y, m.stand(model, 406)), {"model": model, "angles": "0 %d 0" % yaw, "solid": "0", "disableshadows": "1", "skin": "0",
                                                                          "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                                                          "renderamt": "255", "rendercolor": "255 255 255"}, m.pv, outside=True)
    ladder(m, -48, 1312, 64, 406, 180, (-80, 1240), (-14, 1312))
    ladder(m, 2256, 1168, -416, 64, 0, (2320, 1168), (2214, 1168))
    ladder(m, 2304, 1008, -896, -416, 270, (2304, 940), (2304, 1050))
    # the service tunnel's lamps as the owner set them right (28 November): the cage lamp with the bulb showing, its spot at
    # the bulb shining out and down from the wall. The cable is theirs: from a power box by the first lamp, lamp to lamp, down
    # both shafts (ours ran along the wall 18 over the lamps, from nothing to nothing). Two more lamps at the shafts are theirs.
    for x in (160, 760, 1360, 1960):
        vmf.point("prop_static", (x, 1231, 162), {"model": "models/props_c17/light_cagelight01_on.mdl", "angles": "0 270 0", "skin": "0", "solid": "6",
                                                 "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)
        m.point("light_spot", x, 1222, 154, {"_light": "255 205 150 70", "_lightHDR": "-1 -1 -1 1", "_cone": "70", "_inner_cone": "35", "_exponent": "1",
                                             "angles": "-45 -90 -90", "pitch": "-45", "style": "0", "_constant_attn": "20", "_linear_attn": "0", "_quadratic_attn": "1"}, vis=m.lv)
    for x, y, z in ((-40, 1312, 500), (-80, 1300, 360), (2308, 1168, 56), (2304, 960, -400)):
        m.light(x, y, z, "255 200 140 35")
    vmf.keep_way_clear((-24, 1280, 406, 32, 1344, 470), "the hole in the alcove's wall and the closet behind it")
    vmf.keep_way_clear((x1 - T, 912, LOW, x1 + 120, 1008, LOW + 112), "the way in through the chamber's west wall")
    # --- path nodes on the catwalks and at the landings (Combine units can walk the chamber) ---
    w = WALK - 40
    for z, ring in ((LOW, [(x1 + w, y) for y in range(y1 + w, y2, 192)] + [(x2 - w, y) for y in range(y1 + w, y2, 192)] +
                     [(x, y1 + w) for x in range(x1 + w + 192, x2 - w, 192)] + [(x, y2 - w) for x in range(x1 + w + 192, x2 - w, 192)]),
                    (HIGH, [(x2 - w, y) for y in range(y1 + w, y2, 192)] + [(x, y1 + w) for x in range(px1 + 96, x2 - w, 192)] +
                     [(x, y2 - w) for x in range(px1 + 96, x2 - w, 192)])):
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


def refit(before, owner, out, piece):
    """The piece as it is built now, carried into the owner's file that already holds an earlier build of it (BEFORE: that
    build's piece alone, lc_core.vmf as it was). Their file is theirs: what they set right by hand stays (map_owner_delta.py
    --loose --near), only what this build changes is taken out and put in. First, by hand here: their moved copies of what
    this build replaces (they raised the pit's floor, and with it the diggers' lower tracks, relays, sounds and dust; they
    nudged the chamber's ladder), which no shape would find; and their brush that becomes the sealed door."""
    import map_owner_delta as D
    text = D.read(owner)
    eol, ents, world, sols = D.index(text)
    cuts, said = [], []
    for s0, e0 in ents:
        t = text[s0:e0]
        name, cls = D.key(t, "targetname"), D.key(t, "classname")
        if re.match(r"lc_core_(machine|digger_\d+)(_|$)", name):
            cuts.append((s0, e0))
        elif cls == "func_useableladder" and D.key(t, "origin"):
            o = D.nums(D.key(t, "origin"))
            if abs(o[0] - 2516) <= 2 and abs(o[1] - 224) <= 2 and abs(o[2] + 700) <= 16:
                cuts.append((s0, e0))
                said.append("the chamber's ladder (func_useableladder at %s): it moves with the pit's edge" % D.key(t, "origin"))
    said.append("%d entities of the three diggers (trains, tracks, relays, sounds, shakes, dust): built again where they stand now" % (len(cuts) - len(said)))
    door = None
    for s0, e0 in sols:
        t = text[s0:e0]
        pts = [tuple(float(v) for v in q) for q in re.findall(r"\(([-\d.e]+) ([-\d.e]+) ([-\d.e]+)\)", " ".join(re.findall(r'"plane" "([^"]+)"', t)))]
        if pts and tuple(min(q[k] for q in pts) for k in range(3)) + tuple(max(q[k] for q in pts) for k in range(3)) == tuple(float(v) for v in SEALED):
            door = (s0, e0, re.search(r'"id" "(\d+)"', t).group(1))
    if not door:
        sys.exit("STOP: the owner's brush for the sealed door (x %d..%d y %d..%d z %d..%d) is not in their file" % (SEALED[0], SEALED[3], SEALED[1], SEALED[4], SEALED[2], SEALED[5]))
    cuts.append(door[:2])
    said.append("world brush %s (their door brush, 4 by 128 by 120): now the func_door lc_sealed_core, drawn as the Nexus's doors" % door[2])
    for s0, e0 in sorted(cuts, reverse=True):
        text = text[:s0] + text[e0 + len(eol):]
    with tempfile.TemporaryDirectory() as tmp:
        cleared = os.path.join(tmp, "cleared.vmf")
        with open(cleared, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
            f.write(text)
        r = subprocess.run([sys.executable, os.path.join(HERE, "map_owner_delta.py"), before, piece, cleared, out, "--loose", "--near", "32"], capture_output=True, text=True)
    print("  " + (r.stdout.strip() or r.stderr.strip()).replace("\n", "\n  "))
    if r.returncode != 0:
        sys.exit("STOP: map_owner_delta.py failed")
    print("  written: " + out)
    print("  taken out of the owner's file by hand first:")
    for c in said:
        print("    " + c)


def main():
    import argparse
    ap = argparse.ArgumentParser(description="The suppression core in the owner's own map (their file is only read).")
    ap.add_argument("owner")
    ap.add_argument("out")
    ap.add_argument("--piece", default="lc_core.vmf", help="where the piece alone is written first (default lc_core.vmf)")
    ap.add_argument("--refit", metavar="BEFORE.vmf", help="the owner's file already holds the core: BEFORE is the piece alone as it was built for it (lc_core.vmf "
                                                           "of that day); only what changed since is carried in, and what the owner set right by hand stays")
    args = ap.parse_args()
    if args.refit:
        r = subprocess.run([sys.executable, os.path.join(HERE, "map_build.py"), "core", "--out", args.piece], capture_output=True, text=True)
        print(r.stdout.rstrip())
        if r.returncode != 0:
            print(r.stderr.rstrip())
            sys.exit("STOP: the piece has problems (above)")
        refit(args.refit, args.owner, args.out, args.piece)
        return
    r = subprocess.run([sys.executable, os.path.join(HERE, "map_build.py"), "core", "--out", args.piece, "--against", args.owner], capture_output=True, text=True)
    print(r.stdout.rstrip())
    if r.returncode != 0:
        print(r.stderr.rstrip())
        sys.exit("STOP: the piece has problems (above)")
    into_owner(args.owner, args.piece, args.out)


if __name__ == "__main__":
    main()
