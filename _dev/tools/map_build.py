#!/usr/bin/env python3
"""
Living City: the map builder (for the owner's PC, never the server)

The owner, 19 November: "It is SO labor intensive to do all the menial map building ... I wanted
to add more of an 'edge of city' or even outside of city area to the map for the resistance to
hide in the woods outside the city, or in the canals."

This writes a NEW, separate VMF for one piece of map (it never opens or changes the owner's own
VMF). The owner brings the piece in with a func_instance at 0 0 0, or with Paste Special at no
offset, looks at it in Hammer++, and compiles. Everything is in visgroups of its own, so it can
be hidden or deleted in one click.

    python3 map_build.py canal            writes lc_canal.vmf here
    python3 map_build.py canal --out FILE

A piece is drawn on a 64-unit grid seen from above: every square is open (a floor at some
height, under the sky or under a ceiling) or solid. From that it makes: a floor block under every
open square, a sky lid over it, and a solid block in every square that touches an open one, so
the piece is sealed by the way it is made. Squares that are alike are joined into big brushes.
Then it checks itself: every corner on the grid, and a flood from outside that must not reach
the air inside (the one opening, onto the city, is stopped up for the check). Only the owner's
compile is the proof.

The first piece, "canal" (the owner: at the skybox brush that ends the road at 3648 1864, "a
standard HL2 Route Kanal size ... not filled with water, that runs for a bit then turns and
maybe even forks and maybe dumps out to a forest"): a quay at the road's end, stairs down, a dry
canal 512 wide and 256 deep running east, a turn north, a fork (one arm ends at a barred tunnel
mouth, the other is capped where the forest will join), a low bay to hide in, two beams across.
"""

import argparse
import bisect
import random
import sys

CELL = 64
GATE_WIDE, GATE_HIGH = 512, 256 # a gate: the culvert every piece ends in, so any two pieces join

# what things are made of: all of these are already used in the owner's own VMF, so they exist
MAT = {
    "canal_wall": "concrete/concretewall064a",
    "canal_floor": "concrete/concretefloor026a",
    "quay_floor": "concrete/concretefloor013a",
    "upper_wall": "brick/brickwall045d",
    "ceiling": "concrete/concreteceiling004a",
    "stairs": "concrete/concretestair005a",
    "beam": "concrete/concretewall036a",
    "bars": "metal/metalpipe001a",
    "sky": "tools/toolsskybox",
    "nodraw": "tools/toolsnodraw",
    "black": "tools/toolsblack",
}


# ---------------------------------------------------------------------------
# Writing a VMF
# ---------------------------------------------------------------------------

# A box's six faces: for each, the two directions across it (U then V, with U x V pointing out of the
# box). Its corners go p0, p0+V, p0+U+V, p0+U: clockwise seen from outside, which is how Hammer++ writes them.
FACE_ORDER = ("top", "bottom", "west", "east", "north", "south")
FACE_UV = {"top": (0, 1), "bottom": (1, 0), "east": (1, 2), "west": (2, 1), "north": (2, 0), "south": (0, 2)}
FACE_SIDE = {"top": (2, 1), "bottom": (2, 0), "east": (0, 1), "west": (0, 0), "north": (1, 1), "south": (1, 0)} # (axis, 0 low or 1 high)
FACE_NORMAL = {"top": (0, 0, 1), "bottom": (0, 0, -1), "east": (1, 0, 0), "west": (-1, 0, 0), "north": (0, 1, 0), "south": (0, -1, 0)}
FACE_AXES = {"top": ("[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"), "bottom": ("[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"),
             "east": ("[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"), "west": ("[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"),
             "north": ("[1 0 0 0] 0.25", "[0 0 -1 0] 0.25"), "south": ("[1 0 0 0] 0.25", "[0 0 -1 0] 0.25")}


def face_corners(box, name):
    lo, hi = box[:3], box[3:]
    axis, high = FACE_SIDE[name]
    u, v = FACE_UV[name]
    p0 = list(lo)
    p0[axis] = hi[axis] if high else lo[axis]
    p1, p2, p3 = list(p0), list(p0), list(p0)
    p1[v] = hi[v]
    p2[v] = hi[v]
    p2[u] = hi[u]
    p3[u] = hi[u]
    return tuple(p0), tuple(p1), tuple(p2), tuple(p3)


def _num(v):
    s = "%.4f" % v
    s = s.rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def disp_text(p, spec, t, record=None):
    """The dispinfo block for a face with corners p (p0 first): every point of its grid moved to target(i, j).
    record(edge points, quads folded back on themselves, quads) is told what was made, for the checks."""
    power, target, alpha = spec
    n = 2 ** power
    p0, p1, p2, p3 = p
    rows_n, rows_d, rows_a, rows_t = [], [], [], []
    pts = {}
    for i in range(n + 1):
        ns, ds, al = [], [], []
        for j in range(n + 1):
            base = [p0[k] + (p1[k] - p0[k]) * i / n + (p3[k] - p0[k]) * j / n for k in range(3)]
            to = target(i, j)
            pts[(i, j)] = to
            d = [to[k] - base[k] for k in range(3)]
            ln = (d[0] * d[0] + d[1] * d[1] + d[2] * d[2]) ** 0.5
            if ln < 0.001:
                ns.append("0 0 1")
                ds.append("0")
            else:
                ns.append("%s %s %s" % (_num(d[0] / ln), _num(d[1] / ln), _num(d[2] / ln)))
                ds.append(_num(ln))
            al.append(_num(max(0.0, min(255.0, alpha(i, j)))) if alpha else "0")
        rows_n.append(" ".join(ns))
        rows_d.append(" ".join(ds))
        rows_a.append(" ".join(al))
    for i in range(n):
        tags = []
        for j in range(n):
            # (9: flat enough to walk and build on; 0: too steep. Hammer works these out again itself.)
            a, b, c = pts[(i, j)], pts[(i + 1, j)], pts[(i, j + 1)]
            e1 = [b[k] - a[k] for k in range(3)]
            e2 = [c[k] - a[k] for k in range(3)]
            nx, ny, nz = e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0]
            ln = (nx * nx + ny * ny + nz * nz) ** 0.5 or 1.0
            tag = "9" if abs(nz) / ln > 0.7 else "0"
            tags += [tag, tag]
        rows_t.append(" ".join(tags))
    if record:
        # (a quad is folded when it faces the other way from the face it was hung on)
        fn = [(p3[(k + 1) % 3] - p0[(k + 1) % 3]) * (p1[(k + 2) % 3] - p0[(k + 2) % 3]) - (p3[(k + 2) % 3] - p0[(k + 2) % 3]) * (p1[(k + 1) % 3] - p0[(k + 1) % 3]) for k in range(3)]
        folded = 0
        for i in range(n):
            for j in range(n):
                a, b, c = pts[(i, j)], pts[(i, j + 1)], pts[(i + 1, j)]
                e1 = [b[k] - a[k] for k in range(3)]
                e2 = [c[k] - a[k] for k in range(3)]
                q = (e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0])
                if q[0] * fn[0] + q[1] * fn[1] + q[2] * fn[2] < 0:
                    folded += 1
        record([pts[(i, j)] for i in range(n + 1) for j in range(n + 1) if i in (0, n) or j in (0, n)], folded, n * n)
    zero = " ".join(["0 0 0"] * (n + 1))
    up = " ".join(["0 0 1"] * (n + 1))

    def block(name, rows):
        return '%s%s\n%s{\n%s%s}\n' % (t + "\t", name, t + "\t", "".join('%s\t\t"row%d" "%s"\n' % (t, k, r) for k, r in enumerate(rows)), t + "\t")
    s = '%sdispinfo\n%s{\n%s\t"power" "%d"\n%s\t"startposition" "[%d %d %d]"\n%s\t"flags" "0"\n%s\t"elevation" "0"\n%s\t"subdiv" "0"\n' % (
        t, t, t, power, t, p0[0], p0[1], p0[2], t, t, t)
    s += block("normals", rows_n) + block("distances", rows_d) + block("offsets", [zero] * (n + 1)) + block("offset_normals", [up] * (n + 1))
    s += block("alphas", rows_a) + block("triangle_tags", rows_t)
    s += '%s\tallowed_verts\n%s\t{\n%s\t\t"10" "-1 -1 -1 -1 -1 -1 -1 -1 -1 -1"\n%s\t}\n%s}\n' % (t, t, t, t, t)
    return s


class Vmf:
    def __init__(self, skyname="painted"):
        self.next = 1
        self.world, self.ents, self.groups = [], [], []
        self.visgroups = {} # name -> id
        self.skyname = skyname
        self.boxes = [] # (box, seals) for the checks
        self.disp_count = 0
        self.disp_made = [] # (visgroup, edge points, quads folded, quads) of every displaced face

    def new_id(self):
        self.next += 1
        return self.next

    def vis(self, name):
        if name not in self.visgroups:
            self.visgroups[name] = len(self.visgroups) + 1
        return self.visgroups[name]

    def editor(self, vis, colour="0 180 220", indent="\t"):
        return ('%seditor\n%s{\n%s\t"color" "%s"\n%s\t"visgroupid" "%d"\n%s\t"visgroupshown" "1"\n%s\t"visgroupautoshown" "1"\n%s}\n'
                % (indent, indent, indent, colour, indent, self.vis(vis), indent, indent, indent))

    def box_text(self, box, sides, top, bottom, vis, indent="\t", faces=None, disp=None):
        """A box brush. sides, top, bottom: materials; faces: {face name: material} for any that differ;
        disp: {face name: (power, target(i, j) -> (x, y, z), alpha(i, j) or None)} to displace a face.
        Corners are written clockwise seen from outside, as Hammer++ does (its vertices_plus), and a
        displaced face's rows run from its first corner to its second, its columns to its fourth:
        checked against the owner's own map (473 shared edge points of its displacements meet)."""
        x1, y1, z1, x2, y2, z2 = box
        if not (x1 < x2 and y1 < y2 and z1 < z2):
            raise ValueError("a box with no size: %r" % (box,))
        t = indent
        s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, self.new_id())
        for name in FACE_ORDER:
            p = face_corners(box, name)
            mat = (faces or {}).get(name) or (top if name == "top" else bottom if name == "bottom" else sides)
            u, v = FACE_AXES[name]
            s += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, self.new_id(), t, " ".join("(%d %d %d)" % q for q in p[:3]))
            s += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%d %d %d"\n' % ((t,) + q) for q in p), t)
            s += ('%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%d"\n%s\t\t"smoothing_groups" "0"\n'
                  % (t, mat.upper(), t, u, t, v, t, t, 32 if disp else 16, t))
            if disp and name in disp:
                s += disp_text(p, disp[name], t + "\t\t", lambda edge, folded, quads, vis=vis: self.disp_made.append((vis, edge, folded, quads)))
                self.disp_count += 1
            s += '%s\t}\n' % t
        s += self.editor(vis, indent=t + "\t") + "%s}\n" % t
        return s

    def world_box(self, box, sides, top=None, bottom=None, vis="LC canal: walls and floors", faces=None, disp=None):
        """A brush of the world. One with a displaced face seals nothing (the compiler drops the rest of it)."""
        nd = MAT["nodraw"]
        self.world.append(self.box_text(box, sides, top or nd, bottom or nd, vis, faces=faces, disp=disp))
        self.boxes.append((box, not disp))

    def detail(self, boxes, mat, vis="LC canal: details", top=None, faces=None):
        """Brushes that don't seal or cut up the map (func_detail): stairs, beams, bars, low walls."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for b in boxes:
            s += self.box_text(b, mat, top or mat, mat, vis, faces=faces)
            self.boxes.append((b, False))
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    def point(self, cls, pos, keys=None, vis="LC canal: details"):
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        s += '\t"origin" "%d %d %d"\n' % tuple(pos)
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)

    def text(self):
        s = 'versioninfo\n{\n\t"editorversion" "400"\n\t"editorbuild" "8873"\n\t"mapversion" "1"\n\t"formatversion" "100"\n\t"prefab" "0"\n}\n'
        s += "visgroups\n{\n"
        for name, i in self.visgroups.items():
            s += '\tvisgroup\n\t{\n\t\t"name" "%s"\n\t\t"visgroupid" "%d"\n\t\t"color" "%d %d %d"\n\t}\n' % (name, i, 80 + 40 * i, 200 - 20 * i, 255 - 30 * i)
        s += "}\n"
        s += 'viewsettings\n{\n\t"bSnapToGrid" "1"\n\t"bShowGrid" "1"\n\t"bShowLogicalGrid" "0"\n\t"nGridSpacing" "64"\n\t"bShow3DGrid" "0"\n}\n'
        s += ('world\n{\n\t"id" "1"\n\t"mapversion" "1"\n\t"classname" "worldspawn"\n\t"skyname" "%s"\n\t"maxpropscreenwidth" "-1"\n'
              '\t"detailvbsp" "detail.vbsp"\n\t"detailmaterial" "detail/detailsprites"\n' % self.skyname)
        s += "".join(self.world) + "}\n"
        s += "".join(self.ents)
        s += 'cameras\n{\n\t"activecamera" "-1"\n}\ncordons\n{\n\t"active" "0"\n}\n'
        return s


# ---------------------------------------------------------------------------
# A piece of map drawn on squares
# ---------------------------------------------------------------------------

class Plan:
    """Squares seen from above, in the piece's own coordinates (x east, y north, from its origin).
    A square is ("open", floor z, floor material) under the sky, ("low", floor z, floor material,
    ceiling z) under a ceiling, or nothing; the walls come by themselves.
    bands: the walls' looks by height, [(z from, z to, material), ...] from the bottom of everything
    to the top of everything. sky: the height of the sky lid over open squares (None: there are none)."""

    def __init__(self, origin, bands, sky=None, floor_side=None, ceiling=None, roof=None, vis="LC canal: walls and floors"):
        self.origin = origin
        self.band_list = bands
        self.base, self.top, self.sky = bands[0][0], bands[-1][1], sky
        self.floor_side = floor_side or bands[0][2]
        self.ceiling = ceiling or MAT["ceiling"]
        self.vis = vis
        self.roof = roof # what the very top is made of, where it can be seen (a building's roof)
        self.walled = False
        self.cells = {}
        self.keep_out = [] # (x1, y1, x2, y2): what's already there or belongs to another piece, never built on

    def paint(self, rect, spec):
        x1, y1, x2, y2 = rect
        for v in rect:
            if v % CELL:
                raise ValueError("off the %d grid: %r" % (CELL, rect))
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                self.cells[(i, j)] = spec

    def walls(self):
        """A solid square wherever an empty square touches an open one (corners too)."""
        if self.walled:
            return
        self.walled = True
        solid = set()
        for (i, j) in self.cells:
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    c = (i + di, j + dj)
                    if c not in self.cells:
                        x, y = c[0] * CELL, c[1] * CELL
                        if not any(x < k[2] and x + CELL > k[0] and y < k[3] and y + CELL > k[1] for k in self.keep_out):
                            solid.add(c)
        for c in solid:
            self.cells[c] = ("solid",)

    def rectangles(self):
        """Squares that are alike, joined into the biggest rectangles (fewest brushes)."""
        left = dict(self.cells)
        out = []
        for (i, j) in sorted(left):
            if (i, j) not in left:
                continue
            spec = left[(i, j)]
            w = 1
            while left.get((i + w, j)) == spec:
                w += 1
            h = 1
            while all(left.get((i + k, j + h)) == spec for k in range(w)):
                h += 1
            for a in range(w):
                for b in range(h):
                    del left[(i + a, j + b)]
            out.append((i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL, spec))
        return out

    def world(self, x, y, z):
        return (self.origin[0] + x, self.origin[1] + y, z)

    def box(self, x1, y1, z1, x2, y2, z2):
        ox, oy = self.origin[0], self.origin[1]
        return (ox + x1, oy + y1, z1, ox + x2, oy + y2, z2)

    def bands(self, z_from):
        """A wall from z_from up to the top, in its looks by height."""
        out = []
        for lo, hi, mat in self.band_list:
            a, b = max(lo, z_from), hi
            if a < b:
                out.append((a, b, mat))
        return out

    def inside(self, x, y):
        """Is this point (the piece's own coordinates) strictly inside the building: squares on every side of it?"""
        i, j = x // CELL, y // CELL
        on_x, on_y = x % CELL == 0, y % CELL == 0
        for di in ((-1, 0) if on_x else (0,)):
            for dj in ((-1, 0) if on_y else (0,)):
                if (i + di, j + dj) not in self.cells:
                    return False
        return True

    def build(self, vmf):
        self.walls()
        for x1, y1, x2, y2, spec in self.rectangles():
            if spec[0] == "solid":
                for a, b, mat in self.bands(self.base):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, top=self.roof if b == self.top else None, vis=self.vis)
                continue
            floor, floor_mat = spec[1], spec[2]
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, floor), self.floor_side, top=floor_mat, vis=self.vis)
            if spec[0] == "open":
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), MAT["sky"], MAT["sky"], MAT["sky"], vis=self.vis)
            else:
                first = True
                for a, b, mat in self.bands(spec[3]):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, top=self.roof if b == self.top else None, bottom=self.ceiling if first else None, vis=self.vis)
                    first = False


def gate_cap(vmf, cap, bars, vis):
    """What closes a gate while nothing is joined to it: a black wall across the culvert, and bars before it.
    In a visgroup of its own: delete the cap on each side of a join, and the two pieces are one."""
    vmf.world_box(cap, MAT["black"], MAT["black"], MAT["black"], vis=vis)
    vmf.detail(bars, MAT["bars"], vis=vis)


# ---------------------------------------------------------------------------
# Checking a piece before the owner sees it
# ---------------------------------------------------------------------------

def check(vmf, seed, stoppers):
    """Corners on the grid, no brush inside another of the world's, and no way from the air inside
    (seed) to the outside once the piece's one opening is stopped up (stoppers: boxes)."""
    problems = []
    world = [b for b, is_world in vmf.boxes if is_world]
    for b, _ in vmf.boxes:
        if any(v != int(v) for v in b):
            problems.append("a corner off the 1-unit grid: %r" % (b,))
    solid = world + list(stoppers)
    axes = []
    for a in range(3):
        cuts = sorted(set([b[a] for b in solid] + [b[a + 3] for b in solid]))
        axes.append([cuts[0] - 64] + cuts + [cuts[-1] + 64])
    n = [len(ax) - 1 for ax in axes]
    full = set()
    for b in solid:
        r = [(bisect.bisect_left(axes[a], b[a]), bisect.bisect_left(axes[a], b[a + 3])) for a in range(3)]
        for i in range(*r[0]):
            for j in range(*r[1]):
                for k in range(*r[2]):
                    full.add((i, j, k))
    start = tuple(bisect.bisect_right(axes[a], seed[a]) - 1 for a in range(3))
    if start in full:
        return problems + ["the check's starting point is inside a brush"], 0
    seen, todo, leak = {start}, [start], None
    while todo:
        c = todo.pop()
        if c[0] in (0, n[0] - 1) or c[1] in (0, n[1] - 1) or c[2] in (0, n[2] - 1):
            leak = c
            break
        for a in range(3):
            for d in (-1, 1):
                m = list(c)
                m[a] += d
                m = tuple(m)
                if m not in seen and m not in full:
                    seen.add(m)
                    todo.append(m)
    if leak:
        problems.append("NOT SEALED: the air inside reaches the outside near (%d %d %d)" % tuple(axes[a][leak[a]] for a in range(3)))
    return problems, len(seen)


# ---------------------------------------------------------------------------
# The canal at the road's end
# ---------------------------------------------------------------------------

def canal(args):
    # the road ends at the owner's brush 15074 (x 3328..3968, y 1856..1872): its city side is this piece's south edge
    ox, oy = args.origin
    road_z, floor_z = 656, 400
    sky = road_z + 512
    plan = Plan((ox, oy), [(floor_z - 64, road_z, MAT["canal_wall"]), (road_z, road_z + 256, MAT["upper_wall"]), (road_z + 256, sky + 16, MAT["sky"])], sky=sky)
    plan.keep_out.append((-100000, -100000, 100000, 0))    # the city: everything south of the road's end is the owner's
    plan.keep_out.append((4608, -100000, 100000, 100000))  # beyond the east gate: whatever is joined there
    plan.keep_out.append((-100000, 3840, 100000, 100000))  # beyond the north gate
    canal_floor = ("open", floor_z, MAT["canal_floor"])
    culvert = ("low", floor_z, MAT["canal_floor"], floor_z + GATE_HIGH)
    plan.paint((0, 0, 640, 256), ("open", road_z, MAT["quay_floor"]))  # the quay: the road carries on to the canal's edge
    plan.paint((0, 256, 3072, 768), canal_floor)                       # A: east, away from the city
    plan.paint((2560, 768, 3072, 2816), canal_floor)                   # B: the turn north
    plan.paint((3072, 2304, 4352, 2816), canal_floor)                  # C: the fork's east arm
    plan.paint((4352, 2304, 4608, 2816), culvert)                      #    its end: a culvert to the east gate (x 4608)
    plan.paint((2560, 2816, 3072, 3584), canal_floor)                  # D: the fork's north arm
    plan.paint((2560, 3584, 3072, 3840), culvert)                      #    its end: a culvert to the north gate (y 3840)
    plan.paint((3072, 1280, 3328, 1664), ("low", floor_z, MAT["canal_floor"], floor_z + 192)) # a low bay off B: somewhere to hide

    vmf = Vmf()
    plan.build(vmf)
    B = plan.box

    # the sky the road sees above this piece's own (lower) sky: what the owner's brush 15074 did, from the lid up
    vmf.world_box(B(0, 0, plan.top, 640, 16, args.road_sky), MAT["sky"], MAT["sky"], MAT["sky"])

    # the two gates, closed until something is joined: each cap is inside the canal's own last 64 units
    gate_cap(vmf, B(4544, 2304, floor_z, 4608, 2816, floor_z + GATE_HIGH), [B(4520, 2304 + 24 + 48 * i, floor_z, 4528, 2304 + 32 + 48 * i, floor_z + GATE_HIGH) for i in range(10)], "LC canal: east gate's cap (delete to join)")
    gate_cap(vmf, B(2560, 3776, floor_z, 3072, 3840, floor_z + GATE_HIGH), [B(2560 + 24 + 48 * i, 3752, floor_z, 2560 + 32 + 48 * i, 3760, floor_z + GATE_HIGH) for i in range(10)], "LC canal: north gate's cap (delete to join)")

    # stairs from the quay down into the canal, along its south wall: a landing, then 31 steps east
    steps = [B(512, 256, floor_z, 640, 384, road_z)]
    for i in range(31):
        steps.append(B(640 + 12 * i, 256, floor_z, 652 + 12 * i, 384, road_z - 8 * (i + 1)))
    vmf.detail(steps, MAT["canal_wall"], top=MAT["stairs"])
    # a low wall along the quay's edge and round the landing (40 high: seen over, not fallen over)
    vmf.detail([B(0, 240, road_z, 512, 256, road_z + 40), B(512, 368, road_z, 640, 384, road_z + 40), B(512, 256, road_z, 528, 368, road_z + 40)], MAT["canal_wall"])
    # two beams across, at the canal wall's top: cover from above, and something to break the long view
    vmf.detail([B(1536, 256, road_z - 64, 1664, 768, road_z), B(2560, 1856, road_z - 64, 3072, 1984, road_z)], MAT["beam"])

    # where the city's people can walk: a path node every 192 units on every open floor, and on the stairs' ends
    blocked = [(512, 256, 1024, 384), (4480, 2304, 4608, 2816), (2560, 3712, 3072, 3840)] # (the stairs, and behind each gate's bars)
    node_id = args.first_node
    for (i, j), spec in sorted(plan.cells.items()):
        if spec[0] == "solid" or i % 3 != 1 or j % 3 != 1:
            continue
        x, y = i * CELL + 32, j * CELL + 32
        if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in blocked):
            continue
        vmf.point("info_node", plan.world(x, y, spec[1] + 16), {"nodeid": node_id}, "LC canal: path nodes")
        node_id += 1
    for x, y, z in ((576, 320, road_z), (736, 320, road_z - 64), (832, 320, road_z - 128), (928, 320, road_z - 208), (1056, 320, floor_z)):
        vmf.point("info_node", plan.world(x, y, z + 16), {"nodeid": node_id}, "LC canal: path nodes")
        node_id += 1

    # reflections: one cubemap for each stretch, at eye height
    for x, y, z in ((320, 128, road_z), (800, 512, floor_z), (2000, 512, floor_z), (2816, 1500, floor_z), (3200, 1472, floor_z), (2816, 2560, floor_z), (3900, 2560, floor_z), (2816, 3300, floor_z)):
        vmf.point("env_cubemap", plan.world(x, y, z + 72), {"cubemapsize": "0"})

    # a little left lying about (few, and in a visgroup of their own: delete it and they're gone)
    rnd = random.Random(18)
    junk = (
        ("models/props_c17/oildrum001.mdl", 1700, 700, 0), ("models/props_c17/oildrum001.mdl", 1750, 720, 0), ("models/props_junk/wood_pallet001a.mdl", 1620, 690, 8),
        ("models/props_junk/wood_crate001a.mdl", 3200, 1340, 20), ("models/props_junk/wood_crate002a.mdl", 3250, 1420, 20), ("models/props_junk/wood_pallet001a.mdl", 3180, 1600, 8),
        ("models/props_vehicles/tire001c_car.mdl", 2700, 2300, 12), ("models/props_canal/boat001a.mdl", 2000, 420, 24), ("models/props_canal/boat002b.mdl", 4000, 2700, 24),
    )
    for model, x, y, up in junk:
        vmf.point("prop_physics", plan.world(x, y, floor_z + up), {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15), "skin": "0", "spawnflags": "0"}, "LC canal: props")

    # the checks: the opening onto the road is stopped up, then a flood from the air over the canal floor
    stopper = B(0, -64, road_z - 64, 640, 0, plan.top)
    problems, air = check(vmf, plan.world(1280, 512, floor_z + 32), [stopper])
    world_n = sum(1 for _, w in vmf.boxes if w)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    print("canal: %d world brushes, %d detail brushes, %d entities (%d path nodes, ids %d to %d)" % (
        world_n, len(vmf.boxes) - world_n, len(vmf.ents), node_id - args.first_node, args.first_node, node_id - 1))
    print("  it fills x %d to %d, y %d to %d, z %d to %d (the road's sky plug to %d)" % (min(xs), max(xs), min(ys), max(ys), plan.base, plan.top, args.road_sky))
    print("  gates (a culvert %d wide, %d high, floor z %d): east at x %d, y %d to %d; north at y %d, x %d to %d" % (
        GATE_WIDE, GATE_HIGH, floor_z, ox + 4608, oy + 2304, oy + 2816, oy + 3840, ox + 2560, ox + 3072))
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (a flood from the air inside stays inside, with the road's opening stopped up)")
    return vmf, problems


def main():
    import map_forest
    pieces = {"canal": canal, "forest_bunker": map_forest.forest_bunker, "forest_cave": map_forest.forest_cave}
    ap = argparse.ArgumentParser(description="Write a new piece of map as its own VMF (never touches the owner's VMF).")
    ap.add_argument("piece", choices=sorted(pieces))
    ap.add_argument("--out", help="the VMF to write (default: lc_PIECE.vmf)")
    ap.add_argument("--origin", type=int, nargs=2, default=None, metavar=("X", "Y"), help="where the piece sits on the map (default: where it joins what's already there)")
    ap.add_argument("--floor", type=int, default=400, help="forests: the height of the gate's floor (default 400, the canal's floor)")
    ap.add_argument("--road-sky", type=int, default=2784, help="canal: the height of the sky over the road it joins (default 2784)")
    ap.add_argument("--first-node", type=int, default=None, help="the first path node id to use (default: 4000 canal, 4400 and 4800 the forests; the map's own stop at 3043)")
    ap.add_argument("--preview", help="forests: also write a picture of the piece from above to this file (needs Pillow)")
    args = ap.parse_args()
    if args.piece == "canal":
        args.origin = args.origin or (3328, 1856)
        args.first_node = args.first_node or 4000
    vmf, problems = pieces[args.piece](args)
    out = args.out or "lc_%s.vmf" % args.piece
    with open(out, "w") as f:
        f.write(vmf.text())
    print("  written: " + out)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
