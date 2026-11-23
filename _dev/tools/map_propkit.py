#!/usr/bin/env python3
"""
Living City: the Propper++ model kit (the canal ring's heaviest brushwork, as models)

The owner's compile of the ring test map stopped in vbsp ("Too many detail brush faces, max = 65536"), and City 18
still has to be stitched in. The owner, 23 November: "not a choice: we need it to not be nodrawn but to be deleted/non
existent; can we make 'one sided' brushes/geometry?", and chose Propper: a model has no brushes and only the faces we
keep. So the two heaviest parts are a kit of models, each made from its own small VMF in Hammer++ with Propper++, and
the ring places them as prop_statics:

  - the Combine wall between the city and the street (map_corridor.combine_wall): runs of every length the ring lays
    (512 to 1024 in steps of 128) in two looks each, the pier over every joint and flush with every free end, and the
    corner pier where the wall turns round the outside of a corner;
  - the ruins beyond the canal (map_backdrop.py): blocks with parapets, houses with tiled roofs and chimneys, burnt
    shells, collapsed blocks and broken walls, in a handful of sizes each.

Each piece's VMF holds ONE func_brush (Propper++ knows it from the FGD, and with a single entity it takes the model's
origin from the entity's origin) with the piece's brushes, its origin at the piece's pivot (0 0 0):
  - a wall run: its start, on the core's street-side face, at street height; it runs along +x, its battered face to -y;
  - the pier: its middle, on the core's face, at street height (it stands over a joint, or flush with a free end);
  - the corner pier: the corner where the two cores' street faces meet; the streets are to -y and to -x;
  - a ruin: the middle of its footprint, on the ground; its front (the face to the canal) to -y.
Every face nobody on the ring's street or in its canal can see is tools/toolsnodraw, which Propper++ deletes ("Skip
nodraw faces"): for the wall, faces looking away from the street, bottoms on the ground, tops above the eye and the run
ends that join flush (a pier or the next run covers them); for the ruins, backs, bottoms and roofs (they stand on the
canal's rim, above every eye on the street and in the canal). A face hidden inside another solid of the same piece is
nodraw too. The corner pier keeps its far sides: one of them stands out along the second street.

    python3 map_propkit.py               write the kit into _dev/propkit/ (a VMF per piece, kit.json, README.md)
    python3 map_propkit.py --check       is _dev/propkit/ what this code writes? and do rays from where players stand
                                         ever meet a face left out of a piece first? (run it after changing a piece)
    python3 map_propkit.py --placed F.vmf  ...the same rays at the Combine wall as a built VMF places the kit
    python3 map_propkit.py --list        the pieces, their sizes and faces
    python3 map_propkit.py --keep-tops   ...keeping every top and roof (for players who could look down on the kit)

kit.json is what the builders read (map_corridor.combine_wall, map_backdrop.py, map_assets.py): each piece's box, the
lamps and lights that go with it, and for the wall the boxes players are kept out of (its player clip: the models
have no collision).
"""

import argparse
import filecmp
import json
import math
import os
import random
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
KIT_DIR = os.path.normpath(os.path.join(HERE, "..", "propkit"))
MODELS = "models/lc/kit/"
NODRAW = "tools/toolsnodraw"
LOW_TOP = 256         # a top lower than this over the street is seen from it (the foot band); higher ones are not
RUN_LENGTHS = (512, 640, 768, 896, 1024)
LOOKS = ("a", "b")
CLIP_REACH = 128      # the wall's player clip stands as far out as anything of a piece lower than this (a player's reach)


# ---------------------------------------------------------------------------------------------------------------------
# Faces nobody sees
# ---------------------------------------------------------------------------------------------------------------------

def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _mid(vs):
    return tuple(sum(v[k] for v in vs) / float(len(vs)) for k in range(3))


def newell(vs):
    """A face's normal (unit), whichever way round its corners go; None for a face with no area."""
    nx = ny = nz = 0.0
    for i in range(len(vs)):
        a, b = vs[i], vs[(i + 1) % len(vs)]
        nx += (a[1] - b[1]) * (a[2] + b[2])
        ny += (a[2] - b[2]) * (a[0] + b[0])
        nz += (a[0] - b[0]) * (a[1] + b[1])
    ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    return None if ln < 1e-9 else (nx / ln, ny / ln, nz / ln)


class Solid:
    """A convex solid: its faces [(corners, material)], each face's outward normal and plane, its box."""

    def __init__(self, faces):
        self.faces = [([tuple(v) for v in vs], m) for vs, m in faces]
        allv = [v for vs, _ in self.faces for v in vs]
        c = _mid(allv)
        self.normals, self.planes = [], []
        for vs, _ in self.faces:
            n = newell(vs)
            if n is not None and _dot(n, _sub(_mid(vs), c)) < 0:
                n = (-n[0], -n[1], -n[2])
            self.normals.append(n)
            if n is not None:
                self.planes.append((n, _dot(n, vs[0])))
        self.lo = tuple(min(v[k] for v in allv) for k in range(3))
        self.hi = tuple(max(v[k] for v in allv) for k in range(3))

    def inside(self, p, tol=0.05):
        return all(_dot(n, p) - d < -tol for n, d in self.planes)


def face_samples(vs, n, step=8.0):
    """Points on a convex face: its middle, its corners and the middles of its edges pulled 1 in, then a grid."""
    c = _mid(vs)
    edge = []
    for i, v in enumerate(vs):
        w = vs[(i + 1) % len(vs)]
        for p in (v, ((v[0] + w[0]) / 2.0, (v[1] + w[1]) / 2.0, (v[2] + w[2]) / 2.0)):
            d = _sub(c, p)
            ln = math.sqrt(_dot(d, d))
            edge.append(p if ln < 1e-9 else tuple(p[k] + d[k] * min(1.0, ln / 2.0) / ln for k in range(3)))
    # a grid in the face's own plane (two axes in it), kept inside the face by 0.5
    e1 = _sub(vs[1], vs[0])
    l1 = math.sqrt(_dot(e1, e1)) or 1.0
    e1 = tuple(x / l1 for x in e1)
    e2 = (n[1] * e1[2] - n[2] * e1[1], n[2] * e1[0] - n[0] * e1[2], n[0] * e1[1] - n[1] * e1[0])
    st = [(_dot(_sub(v, vs[0]), e1), _dot(_sub(v, vs[0]), e2)) for v in vs]
    area = sum(st[i - 1][0] * st[i][1] - st[i][0] * st[i - 1][1] for i in range(len(st)))
    sg = 1 if area > 0 else -1

    def within(s, t):
        for i in range(len(st)):
            (s0, t0), (s1, t1) = st[i - 1], st[i]
            ln = math.hypot(s1 - s0, t1 - t0) or 1.0
            if sg * ((s1 - s0) * (t - t0) - (t1 - t0) * (s - s0)) / ln < 0.5:
                return False
        return True
    grid = []
    s_lo, s_hi = min(s for s, _ in st), max(s for s, _ in st)
    t_lo, t_hi = min(t for _, t in st), max(t for _, t in st)
    s = s_lo + step / 2.0
    while s < s_hi:
        t = t_lo + step / 2.0
        while t < t_hi:
            if within(s, t):
                grid.append(tuple(vs[0][k] + e1[k] * s + e2[k] * t for k in range(3)))
            t += step
        s += step
    return [c], edge, grid


def covered(si, fi, solids):
    """Is face fi of solid si inside other solids of the piece all over (every sample, pushed 0.5 out, inside one)?"""
    s = solids[si]
    vs, n = s.faces[fi][0], s.normals[fi]
    lo = [min(v[k] for v in vs) - 1 for k in range(3)]
    hi = [max(v[k] for v in vs) + 1 for k in range(3)]
    near = [o for j, o in enumerate(solids) if j != si and all(o.lo[k] <= hi[k] and o.hi[k] >= lo[k] for k in range(3))]
    if not near:
        return False
    for part in face_samples(vs, n):
        for p in part:
            q = (p[0] + 0.5 * n[0], p[1] + 0.5 * n[1], p[2] + 0.5 * n[2])
            if not any(o.inside(q) for o in near):
                return False
    return True


def cut_faces(shapes, rule):
    """The piece's solids with the faces nobody sees made nodraw: rule(corners, normal) says so for a face by where it
    looks; a face inside the piece's other solids all over is nodraw whatever it says. Gives (solids, drawn, nodraw)."""
    solids = [Solid(f) for f in shapes]
    out, drawn, hidden = [], 0, 0
    for si, s in enumerate(solids):
        faces = []
        for fi, (vs, mat) in enumerate(s.faces):
            n = s.normals[fi]
            hide = mat.lower() == NODRAW or n is None or rule(vs, n) or covered(si, fi, solids)
            faces.append((vs, NODRAW if hide else mat))
            hidden += hide
            drawn += not hide
        out.append(faces)
    return out, drawn, hidden


def wall_rule(k=None, back=True, keep_tops=False):
    """The wall's faces, seen from the street (to -y, at street height): a top above LOW_TOP and a bottom on the ground
    are never seen; nor (back) a face looking away from the street, nor (k) a run's ends at x 0 and k, which a pier or
    the next run covers. Without back, a face looking away is kept unless it also looks up (a crown's far slope)."""
    def rule(vs, n):
        zs = [v[2] for v in vs]
        if n[2] > 0.99:
            return not keep_tops and min(zs) >= LOW_TOP
        if n[2] < -0.99:
            return max(zs) <= 0
        if n[1] > 0.01 and (back or (n[2] > 0.01 and not keep_tops)):
            return True
        if k is not None and abs(n[0]) > 0.99 and (all(v[0] == 0 for v in vs) or all(v[0] == k for v in vs)):
            return True
        return False
    return rule


def ruin_rule(keep_tops=False):
    """The ruins' faces, seen from the street and the canal: every eye is below the ground they stand on (the canal's
    rim), so no top is seen; nor a bottom on the ground, nor a face looking away from the canal (to +y)."""
    def rule(vs, n):
        zs = [v[2] for v in vs]
        if n[2] > 0.99:
            return not keep_tops
        if n[2] < -0.99:
            return max(zs) <= 0
        if n[1] > 0.01:
            return not (keep_tops and n[2] > 0.01)
        return False
    return rule


# ---------------------------------------------------------------------------------------------------------------------
# The Combine wall's pieces (combine/chain.py's run and pier, as map_corridor.combine_wall laid them)
# ---------------------------------------------------------------------------------------------------------------------

def reach(shapes, axis, a, b):
    """How far out a piece stands toward -axis (0 x, 1 y) where a player could walk into it: the lowest coordinate of
    every solid that comes lower than CLIP_REACH and overlaps a..b along the other plan axis (0 if none)."""
    other, out = 1 - axis, 0
    for faces in shapes:
        vs = [v for f, _ in faces for v in f]
        if min(v[2] for v in vs) >= CLIP_REACH or max(v[other] for v in vs) <= a or min(v[other] for v in vs) >= b:
            continue
        out = min(out, min(v[axis] for v in vs))
    return int(math.floor(out))


def wall_run(k, look, keep_tops=False):
    import map_corridor
    from combine.chain import run
    from combine.geom import Frame as CF
    from combine.piece import Piece, Sink
    H = map_corridor.WALL_H
    r = random.Random("lc kit combine wall run %d %s" % (k, look))
    sink = Sink()
    p = Piece(CF((0, 0, 0), (1, 0)), (k, 0), H, r, sink)
    run(p, k, H, r, inner=False)       # (its back against the city's edge: nothing built there)
    solids, drawn, hidden = cut_faces(sink.solids, wall_rule(k=k, keep_tops=keep_tops))
    return {"kind": "wall run", "length": k, "look": look, "solids": solids, "drawn": drawn, "nodraw": hidden,
            "clip": [[0, reach(sink.solids, 1, 0, k), 0, k, 0, H]], "lamps": [], "lights": [[int(c) for c in pos] + [col] for pos, col in sink.lights]}


def wall_pier(keep_tops=False):
    """The pier over a joint (centred on it) or flush with a free end: pier() with its back on the core's back face (T 32,
    no inner plinth), so it never stands out behind the core and its back is never seen."""
    import map_corridor
    from combine.chain import lean_units, pier
    from combine.geom import Frame as CF
    from combine.piece import Piece, Sink
    H = map_corridor.WALL_H
    r = random.Random("lc kit combine wall pier")
    sink = Sink()
    p = Piece(CF((0, 0, 0), (1, 0)), (256, 0), H, r, sink)
    pier(p, 0, H, r, 32, lean_units(p.fr, H), 0, lamp=True)
    solids, drawn, hidden = cut_faces(sink.solids, wall_rule(keep_tops=keep_tops))
    lo, hi = bbox(sink.solids)[0], bbox(sink.solids)[3]
    lamps = [[int(round(c)) for c in pos] + [270, pitch] for pos, _yaw, pitch in sink.lamps]
    return {"kind": "wall pier", "solids": solids, "drawn": drawn, "nodraw": hidden, "clip": [[lo, reach(sink.solids, 1, lo, hi), 0, hi, 0, H]],
            "lamps": lamps, "lights": [[int(c) for c in pos] + [col] for pos, col in sink.lights]}


def wall_corner(keep_tops=False):
    """The pier where the wall turns round the outside of a corner: a square mass 128 across, centred on the corner
    where the two cores' street faces meet (the streets to -y and to -x), as the pier is made: courses of 128, its top
    course leaning out over both streets, a stack of plates with its light panel on each front, a crown, a lamp on each
    front. The two runs' ends stand in it."""
    import map_corridor
    from combine import tops as TP
    from combine.chain import lean_units
    from combine.geom import Frame as CF, loft, rect
    from combine.piece import Piece, Sink
    H = map_corridor.WALL_H
    r = random.Random("lc kit combine wall corner")
    sink = Sink()
    p1 = Piece(CF((0, 0, 0), (1, 0)), (128, 0), H, r, sink)       # (its front to -y)
    p2 = Piece(CF((0, 0, 0), (0, -1)), (128, 0), H, r, sink)      # (its front to -x; the same square in its own frame)
    S, Hp = 64, H + 128
    e0, e1 = sorted((16, 48), key=lambda _: r.random())
    p1.mass(rect(-S, -S, S, S), 0, Hp - 128, (-S + e0, S - e1))
    ln = r.choice((16, 32, 40))
    p1.add(loft(rect(-S, -S, S, S), [(-S - ln, -S), (S, -S), (S, S + ln), (-S - ln, S + ln)], Hp - 128, Hp, p1.mm))
    lv = r.randint(3, 4)
    for p in (p1, p2):
        p.stack(("v", S, 1), -S + e0, S - e1, r.choice((64, 128)), Hp - 256, lv)
    kind = TP.pick(r, kinds=(("steps", 2), ("flat", 1), ("ridge", 1)))
    TP.crown(p1, kind, -S - ln, S, -S, S + ln, Hp, r, across="u", ribs=False)
    lamps = [[int(round(c)) for c in p1.w((S - 40, S + 1, H - 96))] + [270, 30],
             [int(round(c)) for c in p2.w((S - 40, S + 1, H - 96))] + [180, 30]]
    solids, drawn, hidden = cut_faces(sink.solids, wall_rule(back=False, keep_tops=keep_tops))
    bx = bbox(sink.solids)
    # (along the first street as far out to -y as anything low stands; along the second, to -x, from the first's core
    #  face back to the square's far side, where the next run's own clip carries on)
    clip = [[bx[0], reach(sink.solids, 1, bx[0], bx[3]), 0, bx[3], 0, H], [reach(sink.solids, 0, 0, S), 0, 0, 0, S, H]]
    return {"kind": "wall corner", "solids": solids, "drawn": drawn, "nodraw": hidden, "clip": clip,
            "lamps": lamps, "lights": [[int(c) for c in pos] + [col] for pos, col in sink.lights]}


# ---------------------------------------------------------------------------------------------------------------------
# The ruins (map_backdrop.py's building kinds, each in a handful of sizes)
# ---------------------------------------------------------------------------------------------------------------------

RUINS = (      # name, kind, width along the canal, depth, height of its walls (the roof's level)
    ("lc_ruin_block_a", "block", 256, 256, 384), ("lc_ruin_block_b", "block", 384, 256, 512),
    ("lc_ruin_block_c", "block", 320, 320, 640), ("lc_ruin_block_d", "block", 512, 384, 448),
    ("lc_ruin_block_e", "block", 448, 256, 768), ("lc_ruin_block_f", "block", 640, 448, 576),
    ("lc_ruin_block_g", "block", 192, 256, 448),
    ("lc_ruin_house_a", "house", 256, 256, 256), ("lc_ruin_house_b", "house", 384, 256, 384),
    ("lc_ruin_house_c", "house", 320, 320, 512), ("lc_ruin_house_d", "house", 448, 384, 320),
    ("lc_ruin_house_e", "house", 512, 256, 448), ("lc_ruin_house_f", "house", 192, 256, 320),
    ("lc_ruin_shell_a", "shell", 256, 256, 320), ("lc_ruin_shell_b", "shell", 384, 320, 448),
    ("lc_ruin_shell_c", "shell", 320, 256, 576), ("lc_ruin_shell_d", "shell", 512, 384, 384),
    ("lc_ruin_shell_e", "shell", 448, 256, 640), ("lc_ruin_shell_f", "shell", 192, 192, 384),
    ("lc_ruin_collapsed_a", "collapsed", 384, 320, 192), ("lc_ruin_collapsed_b", "collapsed", 512, 384, 256),
    ("lc_ruin_wall_a", "broken wall", 384, 64, 0), ("lc_ruin_wall_b", "broken wall", 512, 64, 0),
)


def box_faces(box, sides, top=None, bottom=None, faces=None):
    from map_build import FACE_ORDER, face_corners
    out = []
    for name in FACE_ORDER:
        mat = (faces or {}).get(name) or (top if name == "top" and top else bottom if name == "bottom" and bottom else sides)
        out.append((list(face_corners(box, name)), mat))
    return out


def _jagged(rnd, a, b, base, room, axis, c1, c2, mat):
    """A wall from a to b along axis ("x" or "y"), c1..c2 thick, standing on base, broken off at slanting heights (each
    piece a prism from p to q, its top from h1 to h2, at most room): the shells' walls, as map_backdrop's shell()."""
    from map_build import prism
    out, p = [], a
    while p < b - 32:
        q = min(b, p + rnd.choice((64, 96, 128, 160, 192)))
        if b - q < 48:
            q = b
        h1, h2 = min(rnd.choice((0, 32, 64, 96, 128, 192, 256)), room), min(rnd.choice((0, 32, 64, 96, 128, 192, 256)), room)
        if max(h1, h2) >= 24:
            prof = [(p, base), (q, base), (q, base + max(h2, 8)), (p, base + max(h1, 8))]
            faces = prism(prof, "y" if axis == "x" else "x", c1, c2, mat)
            faces = [(vs, NODRAW if all(v[2] == base for v in vs) else m) for vs, m in faces]
            out.append(faces)
        p = q
    return out


def ruin_piece(name, kind, w, d, h, keep_tops=False):
    import map_backdrop as MB
    from map_build import prism
    rnd = random.Random("lc kit ruin " + name)
    x1, y1, x2, y2 = -w // 2, -d // 2, w // 2, d // 2
    front = rnd.choice(MB.FRONTS)
    shapes, meta = [], {"top": h}
    if kind == "block":
        shapes.append(box_faces((x1, y1, 0, x2, y2, h), front, top=rnd.choice(MB.FLAT_ROOFS), bottom=NODRAW))
        # a parapet round the roof, broken here and there (from far off, the eye passes over the roof's front edge and
        #  sees the parapets' faces onto the roof too: they are kept)
        for seg in ((x1, y1, x2, y1 + 16), (x1, y2 - 16, x2, y2), (x1, y1 + 16, x1 + 16, y2 - 16), (x2 - 16, y1 + 16, x2, y2 - 16)):
            if rnd.random() < 0.2:
                continue
            shapes.append(box_faces((seg[0], seg[1], h, seg[2], seg[3], h + 24), front, faces={"bottom": NODRAW}))
        meta["roof"] = [x1, y1, x2, y2]
    elif kind == "house":
        shapes.append(box_faces((x1, y1, 0, x2, y2, h), front, top=NODRAW, bottom=NODRAW))
        rise = int(d * rnd.choice((0.5, 0.6, 0.75)) / 2) // 8 * 8
        shapes.append(prism([(y1 - 8, h), (y2 + 8, h), (0, h + rise)], "x", x1 - 8, x2 + 8, rnd.choice(MB.TILE_ROOFS), front))
        if rnd.random() < 0.8:      # (a brick chimney through the roof's slope, near one end)
            px = int(x1 + w * rnd.choice((0.18, 0.3, 0.7, 0.82))) // 8 * 8
            py = int(y1 + d * rnd.choice((0.3, 0.7))) // 8 * 8
            ch = (h + rise + rnd.choice((32, 48, 64))) // 8 * 8
            shapes.append(box_faces((px - 24, py - 16, h, px + 24, py + 16, ch), MB.CHIMNEY, bottom=NODRAW))
            shapes.append(box_faces((px - 28, py - 20, ch, px + 28, py + 20, ch + 8), "concrete/concretefloor016a"))
    elif kind == "shell":
        shapes.append(box_faces((x1, y1, 0, x2, y2, h), front, top="concrete/concretefloor013a", bottom=NODRAW))
        t = 24
        shapes += _jagged(rnd, x1, x2, h, 256, "x", y1, y1 + t, front)                  # (the front wall)
        xs = rnd.choice((x1, x2 - t))                                                  # (one side wall, behind the front's)
        shapes += _jagged(rnd, y1 + t, y2, h, 256, "y", xs, xs + t, front)
        meta["rubble"] = [0, 0]
    elif kind == "collapsed":
        # a block broken down to its first floor, a floor slab fallen in from the back wall to the front, a side wall's
        # stump standing over it
        shapes.append(box_faces((x1, y1, 0, x2, y2, h), front, top="concrete/concretefloor013a", bottom=NODRAW))
        rb, rf = rnd.choice((160, 192, 224)), rnd.choice((16, 32, 48))
        a, b = x1 + rnd.choice((16, 32, 64)), x2 - rnd.choice((32, 64, 96))
        slab = prism([(y1 + 32, h), (y2 - 16, h), (y2 - 16, h + rb), (y1 + 32, h + rf)], "x", a, b, "concrete/concretefloor013a")
        shapes.append([(vs, NODRAW if all(v[2] == h for v in vs) else m) for vs, m in slab])
        meta["top"] = h + rb      # (what must show over the canal's wall: the slab's high end)
        xs = rnd.choice((x1, x2 - 24))
        shapes += _jagged(rnd, y1 + 64, y2, h, 224, "y", xs, xs + 24, front)
    else:      # a broken wall standing alone, 24 thick, broken off at slanting heights
        shapes += _jagged(rnd, x1, x2, 0, 320, "x", -12, 12, front)
        meta["top"] = 0
    solids, drawn, hidden = cut_faces(shapes, ruin_rule(keep_tops))
    return dict({"kind": kind, "size": [w, d, h], "solids": solids, "drawn": drawn, "nodraw": hidden, "lamps": [], "lights": []}, **meta)


# ---------------------------------------------------------------------------------------------------------------------
# The kit
# ---------------------------------------------------------------------------------------------------------------------

def pieces(keep_tops=False):
    """Every piece of the kit, in order: {name: piece}."""
    out = {}
    for k in RUN_LENGTHS:
        for look in LOOKS:
            out["lc_cwall_%d_%s" % (k, look)] = wall_run(k, look, keep_tops)
    out["lc_cwall_pier"] = wall_pier(keep_tops)
    out["lc_cwall_corner"] = wall_corner(keep_tops)
    for name, kind, w, d, h in RUINS:
        out[name] = ruin_piece(name, kind, w, d, h, keep_tops)
    return out


def bbox(solids, drawn_only=False):
    vs = [v for faces in solids for f, m in faces for v in f if not drawn_only or m != NODRAW]
    return [int(math.floor(min(v[k] for v in vs))) for k in range(3)] + [int(math.ceil(max(v[k] for v in vs))) for k in range(3)]


def vmf_text(name, piece):
    """The piece's own VMF: ONE func_brush at the pivot (origin 0 0 0) holding its brushes; nothing in the world."""
    from map_build import Vmf
    from combine.scene import tex_scale
    v = Vmf()
    vis = "LC kit: " + name
    body = ""
    for faces in piece["solids"]:
        body += v.convex_text(faces, vis)
        v.shape_boxes.append(tuple(bbox([faces])))
    ent = ('entity\n{\n\t"id" "%d"\n\t"classname" "func_brush"\n\t"targetname" "%s"\n\t"origin" "0 0 0"\n\t"Solidity" "1"\n'
           '\t"solidbsp" "0"\n\t"StartDisabled" "0"\n\t"spawnflags" "2"\n\t"rendermode" "0"\n\t"renderamt" "255"\n'
           '\t"rendercolor" "255 255 255"\n\t"disableshadows" "0"\n' % (v.new_id(), name))
    ent += body + v.editor(vis, "220 30 220") + "}\n"
    if piece["kind"].startswith("wall"):
        ent = tex_scale(ent)          # (as the brush wall had it: map_combine's texture scale by each face's size)
    v.ents.append(ent)
    return v.text()


def write(folder, keep_tops=False, quiet=False):
    from map_build import bad_brushes
    os.makedirs(folder, exist_ok=True)
    ps = pieces(keep_tops)
    problems = []
    manifest = {"models": MODELS, "keep_tops": keep_tops, "wall": {"runs": {}, "pier": "lc_cwall_pier", "corner": "lc_cwall_corner"},
                "ruins": {}, "pieces": {}}
    for name, p in ps.items():
        text = vmf_text(name, p)
        for b in bad_brushes(text):
            problems.append("%s: %s" % (name, b))
        with open(os.path.join(folder, name + ".vmf"), "w") as f:
            f.write(text)
        entry = {k: v for k, v in p.items() if k != "solids"}
        entry["box"] = bbox(p["solids"])
        entry["drawn_box"] = bbox(p["solids"], True)
        entry["brushes"] = len(p["solids"])
        manifest["pieces"][name] = entry
        if p["kind"] == "wall run":
            manifest["wall"]["runs"].setdefault(str(p["length"]), []).append(name)
        elif not p["kind"].startswith("wall"):
            manifest["ruins"].setdefault(p["kind"], []).append(name)
    with open(os.path.join(folder, "kit.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
        f.write("\n")
    with open(os.path.join(folder, "README.md"), "w") as f:
        f.write(readme(manifest))
    if not quiet:
        print("the kit: %d pieces in %s (%d faces kept, %d nodraw)" % (len(ps), folder, sum(p["drawn"] for p in ps.values()), sum(p["nodraw"] for p in ps.values())))
    for p in problems:
        print("  PROBLEM: " + p)
    return problems


def readme(m):
    P = m["pieces"]
    lines = ["# The Propper++ model kit (the canal ring's Combine wall and ruins)", "",
             "Written by `_dev/tools/map_propkit.py`: never edit these files by hand; change the code and run it again "
             "(`python3 map_propkit.py`; then `--check` says whether the folder matches the code, and casts rays from where players "
             "stand at every piece: none may meet a face left out of it first).", "",
             "Each VMF here is one model. It holds a single `func_brush` whose origin (0 0 0) is the model's origin; "
             "every face nobody on the ring's street or in its canal can see is `tools/toolsnodraw`, which Propper++ "
             "leaves out. The ring's builders (`map_corridor.combine_wall`, `map_backdrop.py`) place these models as "
             "`prop_static`s named `%s<file name>.mdl`, and read `kit.json` for their sizes, lamps and lights." % m["models"], "",
             "## Pieces", "", "| File | What | Size (x by y by z) | Faces kept | Pivot |", "|---|---|---|---|---|"]
    for name, p in P.items():
        bx = p["box"]
        size = "%d by %d by %d" % (bx[3] - bx[0], bx[4] - bx[1], bx[5] - bx[2])
        if p["kind"] == "wall run":
            what, pivot = "Combine wall run, %d long, look %s" % (p["length"], p["look"]), "its start, on the core's street face, at street height"
        elif p["kind"] == "wall pier":
            what, pivot = "Combine wall pier (over every joint, flush with every free end)", "its middle, on the core's street face, at street height"
        elif p["kind"] == "wall corner":
            what, pivot = "Combine wall corner pier (the wall turning round a corner)", "the corner of the two cores' street faces"
        else:
            what, pivot = "ruin: %s" % p["kind"], "the middle of its footprint, on the ground"
        lines.append("| `%s.vmf` | %s | %s | %d | %s |" % (name, what, size, p["drawn"], pivot))
    lines += ["", "Every piece faces -y (south in Hammer's top view): the wall's battered face and the ruins' fronts. The wall "
              "is 512 high over the street (its piers 640 and their crowns more); the ruins stand on the canal's rim.", "",
              "## Making the models (facts for the owner's instructions)", "",
              "- Hammer++, once: Tools > Options > Build Programs > MDL executable: Garry's Mod's `bin/studiomdl.exe` "
              "(the 32-bit one in `bin`, not `bin/x64`).",
              "- For each VMF here: open it, select all (Ctrl+A), Tools > Propper++ (Ctrl+Shift+P), then Build + Compile.",
              "- Propper++ settings, set once and kept: Model Path + Name `lc/kit/$vmf` (each model is named after its file: "
              "`models/lc/kit/<file name>.mdl`); Entity name as physics mesh BLANK (no collision: the ring puts a player "
              "clip along the wall instead); Skip nodraw faces ON; Material path `models/lc/kit` (the converted materials "
              "go to `materials/models/lc/kit/`); Rename shaders ON and Remove $bumpmap/$phong ON (so VRAD can light the "
              "props per vertex); Add incremental suffix OFF (so a piece built again replaces the old model).",
              "- The first time: with Create entity after compile on, the model should land exactly where the brushes were, "
              "facing the same way. If it comes out turned or moved, stop and say so (the ring places every model by that).",
              "- What the compile makes, to copy to the server (both under `garrysmod/`, as FastDL mirrors it): "
              "`models/lc/kit/` (each piece's .mdl, .vvd and .vtx files) and `materials/models/lc/kit/`. They are our own "
              "models, not in Half-Life 2: pack them into the map (CompilePal's pack step, or VIDE) or send them as "
              "downloads, or players see errors.",
              "- The map's compile: VRAD with `-StaticPropLighting` (props lit per vertex; without it each model is lit from "
              "one point, and a long wall run comes out flat or dark) and `-StaticPropPolys` (shadows from the models' own "
              "faces: they have no collision mesh to cast them from).",
              "- Until a model is compiled, the game shows an error model where it stands, and `map_assets.py` reports it as "
              "ours, not missing.", "",
              "## What is left out of each model", "",
              "- The wall: faces looking away from the street (to +y), bottoms on the ground, tops more than %d over the "
              "street, and each run's two ends (a pier, the corner pier or the next run covers them). The corner pier keeps "
              "its far sides (one of them stands out along the second street)." % LOW_TOP,
              "- The ruins: backs, bottoms and roofs (they stand on the canal's rim, above every eye on the street and in the "
              "canal).",
              "- Any face that lies inside another solid of the same piece.",
              "- Built with `--keep-tops`, the kit keeps every top and roof (for a place where players could look down on it). "
              "This kit was built %s." % ("with every top kept" if m["keep_tops"] else "without them"), ""]
    return "\n".join(lines) + "\n"


def load(folder=KIT_DIR):
    """kit.json, as the builders read it (cached)."""
    global _loaded
    if _loaded is None or _loaded[0] != folder:
        with open(os.path.join(folder, "kit.json")) as f:
            _loaded = (folder, json.load(f))
    return _loaded[1]


_loaded = None


def model(name):
    return MODELS + name + ".mdl"


def place(pos, yaw):
    """A point of a piece (kit coordinates) placed at pos turned by yaw (a multiple of 90): world coordinates."""
    c, s = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
    return lambda x, y, z: (pos[0] + x * c - y * s, pos[1] + x * s + y * c, pos[2] + z)


def place_box(pos, yaw, box):
    """A box of a piece (x1 y1 z1 x2 y2 z2, kit coordinates) placed and turned: the world box round it."""
    at = place(pos, yaw)
    a, b = at(box[0], box[1], box[2]), at(box[3], box[4], box[5])
    return (min(a[0], b[0]), min(a[1], b[1]), a[2], max(a[0], b[0]), max(a[1], b[1]), b[2])


# ---------------------------------------------------------------------------------------------------------------------
# The checks: rays from where players stand must never meet a face left out of a model first
# ---------------------------------------------------------------------------------------------------------------------

def read_solids(text, classes=None):
    """The convex solids of a VMF's text, [(faces [(corners, material)], the entity's class)], from their vertices_plus
    (classes: only those of the world, "worldspawn", or of these entity classes)."""
    import re
    out = []
    for blk in re.split(r'\n(?=(?:world|entity)\n\{)', text):
        if not blk.startswith(("world", "entity")):
            continue
        m = re.search(r'\n\t"classname" "([^"]+)"', blk)
        cls = m.group(1) if m else "worldspawn"
        if classes is not None and cls not in classes:
            continue
        for s in re.split(r'\n\t+solid\n', blk)[1:]:
            faces = [([tuple(float(c) for c in v.split()) for v in re.findall(r'"v" "([^"]+)"', vs)], mat.lower())
                     for vs, mat in re.findall(r'vertices_plus\n\t*\{\n((?:\t*"v" "[^"]+"\n)+)\t*\}\n\t*"material" "([^"]+)"', s)]
            if faces:
                out.append((faces, cls))
    return out


def ray_hit(s, o, d):
    """Where a ray o + t d enters a convex solid: (t, face index), or None."""
    t0, t1, fi = -1e18, 1e18, None
    for i, n in enumerate(s.normals):
        if n is None:
            continue
        den, num = _dot(n, d), _dot(n, s.faces[i][0][0]) - _dot(n, o)
        if abs(den) < 1e-12:
            if num < 0:
                return None
            continue
        t = num / den
        if den < 0:
            if t > t0:
                t0, fi = t, i
        else:
            t1 = min(t1, t)
    return None if fi is None or t0 > t1 or t0 < 0 else (t0, fi)


def left_out_first(solids, others, o, tgt):
    """Does the ray from o to tgt meet only faces left out of the models (nodraw faces of solids, none of others) first?"""
    d = (tgt[0] - o[0], tgt[1] - o[1], tgt[2] - o[2])
    lo = [min(o[k], tgt[k]) - 1 for k in range(3)]
    hi = [max(o[k], tgt[k]) + 1 for k in range(3)]
    hits = []
    for group, kit in ((solids, True), (others, False)):
        for s in group:
            if any(s.hi[k] < lo[k] or s.lo[k] > hi[k] for k in range(3)):
                continue
            h = ray_hit(s, o, d)
            if h:
                hits.append((h[0], kit and s.faces[h[1]][1] == NODRAW))
    if not hits:
        return False
    t0 = min(h[0] for h in hits)
    return t0 <= 1.0001 and all(left for t, left in hits if t <= t0 + 1e-6)


def _targets(solids, rnd, per_face, most):
    out = [tuple(sum(v[k] * w for v, w in zip(vs, ws)) / sum(ws) for k in range(3))
           for s in solids for vs, _ in s.faces for ws in ([rnd.random() for _ in vs] for _ in range(per_face))]
    rnd.shuffle(out)
    return out[:most]


def rays(folder=KIT_DIR, seed=1):
    """Each piece alone, from where players see it: a wall run from in front of it along its length (its ends are
    covered when placed), the pier from anywhere in front, the corner pier from both streets, at heights from the foot
    to 200 over the street; a ruin from in front of it at the eye on the street and on the canal's floor (312 and 568
    below the rim it stands on), the ground it stands on in the way. Gives [problems]."""
    rnd = random.Random(seed)
    kit, problems = load(folder), []
    for name, p in kit["pieces"].items():
        with open(os.path.join(folder, name + ".vmf")) as f:
            solids = [Solid(faces) for faces, _ in read_solids(f.read())]
        others = []
        if p["kind"] == "wall run":
            vw = [(x, y, z) for x in range(0, p["length"] + 1, 64) for y in (-150, -400, -900, -1500) for z in (8, 64, 128, 200)]
        elif p["kind"].startswith("wall"):
            vw = [(x, y, z) for x in range(-1500, 1501, 100) for y in (-150, -400, -900) for z in (8, 64, 128, 200)]
            if p["kind"] == "wall corner":
                vw += [(x, y, z) for y, x, z in vw]
        else:
            front = -p["size"][1] / 2.0
            vw = [(x, y, z) for x in range(-3000, 3001, 250) for y in (front - 400, front - 900, front - 1600, front - 2600) for z in (-248, -504)]
            others = [Solid(box_faces((-6000, int(front - 128), -16, 6000, 6000, 0), "ground"))]
        bad = sum(left_out_first(solids, others, o, t) for t in _targets(solids, rnd, 6, 3000) for o in rnd.sample(vw, min(12, len(vw))))
        if bad:
            problems.append("%s: %d rays from where players stand meet a face left out of the model first" % (name, bad))
    return problems


def rays_placed(path, folder=KIT_DIR, seed=3):
    """The Combine wall as a built VMF places it (its runs, piers and corner piers with the world and func_detail round
    them): rays from the street in front of each piece (never from inside a brush, a model or a player clip) at points
    on it. Gives (rays cast, [problems])."""
    import collections
    rnd = random.Random(seed)
    kit = load(folder)
    with open(path) as f:
        text = f.read()
    import re
    props = []
    for m in re.finditer(r'entity\n\{\n\t"id" "\d+"\n\t"classname" "prop_static"\n(.*?)\n\}', text, re.S):
        mm = re.search(r'"model" "%s(lc_cwall[^"]*)\.mdl"' % MODELS, m.group(1))
        if mm:
            o = tuple(int(float(c)) for c in re.search(r'"origin" "([^"]+)"', m.group(1)).group(1).split())
            props.append((mm.group(1), o, int(float(re.search(r'"angles" "([^"]+)"', m.group(1)).group(1).split()[1]))))
    world, clips = [], []
    for faces, _ in read_solids(text, ("worldspawn", "func_detail")):
        mats = {m for _, m in faces}
        if "tools/toolsplayerclip" in mats:
            clips.append(Solid(faces))
        elif not all(m.startswith("tools/") and m != NODRAW for m in mats) and not any("skybox" in m or "trigger" in m for m in mats):
            world.append(Solid(faces))
    pieces_ = {}
    for name in set(n for n, _, _ in props):
        with open(os.path.join(folder, name + ".vmf")) as f:
            pieces_[name] = [faces for faces, _ in read_solids(f.read())]

    def grid(solids):
        g = collections.defaultdict(list)
        for s in solids:
            for gx in range(int(s.lo[0] // 512), int(s.hi[0] // 512) + 1):
                for gy in range(int(s.lo[1] // 512), int(s.hi[1] // 512) + 1):
                    g[(gx, gy)].append(s)
        return g

    def near(g, lo, hi):
        out = {}
        for gx in range(int(lo[0] // 512), int(hi[0] // 512) + 1):
            for gy in range(int(lo[1] // 512), int(hi[1] // 512) + 1):
                for s in g.get((gx, gy), ()):
                    out[id(s)] = s
        return list(out.values())
    placed = []
    for name, o, yaw in props:
        at = place(o, yaw)
        placed.append([Solid([([at(*v) for v in vs], m) for vs, m in faces]) for faces in pieces_[name]])
    kgrid, wgrid, cgrid = grid([s for ss in placed for s in ss]), grid(world), grid(clips)

    def blocked(p):
        for q in ((p[0] + dx, p[1] + dy, p[2]) for dx in (-16, 0, 16) for dy in (-16, 0, 16)):
            lo, hi = [c - 1 for c in q], [c + 1 for c in q]
            if any(s.inside(q, 0) for g in (kgrid, wgrid, cgrid) for s in near(g, lo, hi)):
                return True
        return False
    cast, problems = 0, []
    for (name, o, yaw), mine in zip(props, placed):
        at, box = place(o, yaw), kit["pieces"][name]["box"]
        vw = [at(a, b, z) for a in range(box[0] - 600, box[3] + 601, 150) for b in (-160, -420, -800) for z in (16, 64, 140)]
        if "corner" in name:
            vw += [at(b, a, z) for a in range(box[1] - 600, box[4] + 601, 150) for b in (-160, -420, -800) for z in (16, 64, 140)]
        vw = [p for p in vw if not blocked(p)]
        if not vw:
            continue
        bad = 0
        for tgt in _targets(mine, rnd, 3, 120):
            for vp in rnd.sample(vw, min(6, len(vw))):
                lo = [min(vp[k], tgt[k]) - 1 for k in range(3)]
                hi = [max(vp[k], tgt[k]) + 1 for k in range(3)]
                cast += 1
                bad += left_out_first(near(kgrid, lo, hi), near(wgrid, lo, hi), vp, tgt)
        if bad:
            problems.append("%s at (%d %d %d): %d rays from the street meet a face left out of a model first" % ((name,) + o + (bad,)))
    return cast, problems


def check(folder=KIT_DIR, keep_tops=None):
    """Write the kit into a scratch folder and compare it with folder: [what differs]."""
    if keep_tops is None:
        try:
            keep_tops = load(folder).get("keep_tops", False)
        except (OSError, ValueError):
            keep_tops = False
    tmp = tempfile.mkdtemp(prefix="lc_propkit_")
    try:
        write(tmp, keep_tops, quiet=True)
        names = sorted(set(os.listdir(tmp)) | set(n for n in os.listdir(folder) if not n.startswith(".")))
        return [n for n in names if not (os.path.exists(os.path.join(folder, n)) and os.path.exists(os.path.join(tmp, n))
                                         and filecmp.cmp(os.path.join(folder, n), os.path.join(tmp, n), shallow=False))]
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description="Write the Propper++ model kit (the ring's Combine wall and ruins), one VMF per model.")
    ap.add_argument("--out", default=KIT_DIR, help="the folder (default: _dev/propkit)")
    ap.add_argument("--check", action="store_true", help="say whether the folder is what this code writes, and cast rays at each piece")
    ap.add_argument("--placed", metavar="VMF", help="cast rays at the Combine wall as this built VMF places the kit")
    ap.add_argument("--list", action="store_true", help="list the pieces")
    ap.add_argument("--keep-tops", action="store_true", help="keep every top and roof (for players who could look down on the kit)")
    args = ap.parse_args()
    if args.check:
        diff = check(args.out, True if args.keep_tops else None)
        print("KIT %s" % ("MATCHES THE CODE" if not diff else "DIFFERS: " + ", ".join(diff) + " (run python3 map_propkit.py)"))
        problems = rays(args.out)
        for p in problems:
            print("  PROBLEM: " + p)
        print("RAYS %s (every piece, from where players stand)" % ("PASS" if not problems else "FAIL (%d)" % len(problems)))
        sys.exit(1 if diff or problems else 0)
    if args.placed:
        cast, problems = rays_placed(args.placed, args.out)
        for p in problems:
            print("  PROBLEM: " + p)
        print("PLACED %s (%d rays at the Combine wall's models in %s)" % ("PASS" if not problems else "FAIL (%d)" % len(problems), cast, args.placed))
        sys.exit(1 if problems else 0)
    if args.list:
        for name, p in load(args.out)["pieces"].items():
            bx = p["box"]
            print("%-22s %-12s %5d by %4d by %4d  %4d faces kept, %4d nodraw, %3d brushes" % (
                name, p["kind"], bx[3] - bx[0], bx[4] - bx[1], bx[5] - bx[2], p["drawn"], p["nodraw"], p["brushes"]))
        return
    sys.exit(1 if write(args.out, args.keep_tops) else 0)


if __name__ == "__main__":
    main()
