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
    "mud": "nature/blendmuddirt001a",   # hl2: mud, blending to dirt
    "clip": "tools/toolsplayerclip",
    "portal": "tools/toolsareaportal",
    "trigger": "tools/toolstrigger",
    "fence": "metal/metalfence007a",    # hl2: chain link
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
        self.points = []    # (classname, place) of every point entity, for the checks
        self.shapes = 0     # solids that aren't boxes
        self.portals = []   # the areaportals' boxes, for the checks

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

    def box_text(self, box, sides, top, bottom, vis, indent="\t", faces=None, disp=None, tex=0.25):
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
            u, v = (a.replace("0.25", _num(tex)) for a in FACE_AXES[name])
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

    def convex_text(self, faces, vis, indent="\t"):
        """Any convex solid: faces is [(corners in order round the face, material), ...]. Each face is turned
        to be clockwise seen from outside, and its texture laid along the face (level one way, down the slope the other)."""
        allv = [v for f, _ in faces for v in f]
        mid = [sum(v[k] for v in allv) / float(len(allv)) for k in range(3)]
        t = indent
        s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, self.new_id())
        for verts, mat in faces:
            def normal(vs):
                a = [vs[2][k] - vs[0][k] for k in range(3)]
                b = [vs[1][k] - vs[0][k] for k in range(3)]
                return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
            n = normal(verts)
            fc = [sum(v[k] for v in verts) / float(len(verts)) for k in range(3)]
            if sum(n[k] * (fc[k] - mid[k]) for k in range(3)) < 0:
                verts = list(reversed(verts))
                n = normal(verts)
            ln = (n[0] ** 2 + n[1] ** 2 + n[2] ** 2) ** 0.5
            if ln < 0.001 or any(c != int(c) for v in verts for c in v):
                raise ValueError("a face with no size, or a corner off the grid: %r" % (verts,))
            n = [c / ln for c in n]
            if abs(n[2]) > 0.99:
                u, w = (1.0, 0.0, 0.0), (0.0, -1.0, 0.0)
            else:
                hl = (n[0] ** 2 + n[1] ** 2) ** 0.5
                u = (-n[1] / hl, n[0] / hl, 0.0)
                w = (n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0])
                if w[2] > 0:
                    w = (-w[0], -w[1], -w[2])
            s += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, self.new_id(), t, " ".join("(%d %d %d)" % tuple(q) for q in verts[:3]))
            s += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%d %d %d"\n' % ((t,) + tuple(q)) for q in verts), t)
            s += ('%s\t\t"material" "%s"\n%s\t\t"uaxis" "[%s %s %s 0] 0.25"\n%s\t\t"vaxis" "[%s %s %s 0] 0.25"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "16"\n%s\t\t"smoothing_groups" "0"\n%s\t}\n'
                  % (t, mat.upper(), t, _num(u[0]), _num(u[1]), _num(u[2]), t, _num(w[0]), _num(w[1]), _num(w[2]), t, t, t, t))
        s += self.editor(vis, indent=t + "\t") + "%s}\n" % t
        self.shapes += 1
        return s

    def detail_shapes(self, shapes, vis="LC canal: details"):
        """Shapes that aren't boxes (sloped banks, pipes), as func_detail: each is a list of faces for convex_text."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for faces in shapes:
            s += self.convex_text(faces, vis)
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    def world_box(self, box, sides, top=None, bottom=None, vis="LC canal: walls and floors", faces=None, disp=None, seals=True, tex=0.25):
        """A brush of the world. One with a displaced face seals nothing (the compiler drops the rest of it); nor does a clip."""
        nd = MAT["nodraw"]
        self.world.append(self.box_text(box, sides, top or nd, bottom or nd, vis, faces=faces, disp=disp, tex=tex))
        self.boxes.append((box, seals and not disp))

    def detail(self, boxes, mat, vis="LC canal: details", top=None, faces=None, tex=0.25):
        """Brushes that don't seal or cut up the map (func_detail): stairs, beams, bars, low walls."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for b in boxes:
            s += self.box_text(b, mat, top or mat, mat, vis, faces=faces, tex=tex)
            self.boxes.append((b, False))
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    @staticmethod
    def wires(connections):
        """What an entity does to others: [(its output, the other's name, the input, a value, seconds later), ...].
        Written as Hammer++ writes them in the owner's map (the parts held apart by the escape character)."""
        if not connections:
            return ""
        s = "\tconnections\n\t{\n"
        for out, target, inp, value, delay in connections:
            s += '\t\t"%s" "%s"\n' % (out, "\x1b".join((target, inp, str(value), _num(delay), "-1")))
        return s + "\t}\n"

    def point(self, cls, pos, keys=None, vis="LC canal: details", connections=None):
        self.points.append((cls, tuple(pos)))
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        s += '\t"origin" "%d %d %d"\n' % tuple(pos)
        s += self.wires(connections)
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)

    def brush_entity(self, cls, keys, boxes, sides, vis, top=None, faces=None, connections=None):
        """An entity made of brushes: a moving door, a button, a trigger, an areaportal. None of them seals."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        s += self.wires(connections)
        for b in boxes:
            mat, fc = sides, faces
            if len(b) == 2:      # (a box, its own material) or (a box, {face: material})
                b, own = b
                mat, fc = (own, faces) if isinstance(own, str) else (sides, own)
            s += self.box_text(b, mat, top or mat, mat, vis, faces=fc)
            self.boxes.append((b, False))
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)

    def areaportal(self, box, vis, name=None):
        """A sheet across an opening that the game sees through only as far as the opening shows (and not at all when
        told to close): what keeps one area from being drawn while standing in another. It has to fill the opening
        from wall to wall, with open air on both its sides."""
        keys = {"StartOpen": "1", "PortalVersion": "1"}
        if name:
            keys["targetname"] = name
        self.portals.append(box)
        self.brush_entity("func_areaportal", keys, [box], MAT["portal"], vis)

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


def prism(profile, axis, a, b, mat, end_mat=None):
    """A flat shape (profile: its corners in order, as (across, up)) pushed along x or y from a to b: the faces for convex_text."""
    def at(t, pq):
        return (t, pq[0], pq[1]) if axis == "x" else (pq[0], t, pq[1])
    faces = [([at(a, q) for q in profile], end_mat or mat), ([at(b, q) for q in profile], end_mat or mat)]
    for k in range(len(profile)):
        q1, q2 = profile[k], profile[(k + 1) % len(profile)]
        faces.append(([at(a, q1), at(a, q2), at(b, q2), at(b, q1)], mat))
    return faces


def octagon(c, up, r):
    """A pipe's outline: eight corners on the grid, about r from the middle (c across, up)."""
    k = int(round(r * 0.4))
    return [(c + r, up + k), (c + k, up + r), (c - k, up + r), (c - r, up + k), (c - r, up - k), (c - k, up - r), (c + k, up - r), (c + r, up - k)]


def test_extras(vmf, start, yaw, vis):
    """What a piece needs to be compiled and walked BY ITSELF: somewhere to spawn and a sun (the owner's map's own
    settings). Never in the file that goes into the real map: that already has both."""
    vmf.point("info_player_start", start, {"angles": "0 %d 0" % yaw}, vis)
    vmf.point("light_environment", (start[0], start[1], start[2] + 128), {
        "_light": "190 214 193 50", "_ambient": "175 191 207 13", "_lightHDR": "-1 -1 -1 1", "_ambientHDR": "-1 -1 -1 1",
        "_lightscaleHDR": "1", "_ambientscaleHDR": "1", "angles": "0 149 0", "pitch": "-70", "SunSpreadAngle": "0"}, vis)


def bar_row(box, along, gap=24):
    """Bars across an opening: box is the thin slab they stand in, along is "x" or "y" (the way the row runs).
    8 thick and 24 from one to the next: 16 between them, and a player is 32 wide. A crossbar ties them at half height."""
    x1, y1, z1, x2, y2, z2 = box
    lo, hi = (x1, x2) if along == "x" else (y1, y2)
    n = (hi - lo - 8) // gap
    first = lo + (hi - lo - (n * gap + 8)) // 2
    out = []
    for i in range(n + 1):
        a = first + i * gap
        out.append((a, y1, z1, a + 8, y2, z2) if along == "x" else (x1, a, z1, x2, a + 8, z2))
    mid = (z1 + z2) // 2
    out.append((x1, y1, mid - 4, x2, y2, mid + 4))
    return out


def barred(vmf, slab, along, vis, back=None):
    """A row of bars nobody can get through (an unseen wall for players stands in the same place), and the black behind them."""
    vmf.detail(bar_row(slab, along), MAT["bars"], vis=vis)
    c = MAT["clip"]
    vmf.world_box(slab, c, c, c, vis=vis, seals=False)
    if back:
        vmf.detail([back], MAT["black"], vis=vis)


def gate_cap(vmf, cap, bars, along, vis):
    """What closes a gate while nothing is joined to it: a black wall across the culvert, and bars before it.
    In a visgroup of its own: delete the cap on each side of a join, and the two pieces are one."""
    vmf.world_box(cap, MAT["black"], MAT["black"], MAT["black"], vis=vis)
    barred(vmf, bars, along, vis)


# ---------------------------------------------------------------------------
# Checking a piece before the owner sees it
# ---------------------------------------------------------------------------

def flood(vmf, seed, stoppers):
    """Where the air at seed reaches, among the piece's sealing brushes and some stopper boxes. Returns (the cells
    reached, the solid cells, the cuts along each axis, a cell on the outside if the air got there). Exact for boxes:
    space is cut at every brush face."""
    solid = [b for b, seals in vmf.boxes if seals] + list(stoppers)
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
        return None, full, axes, None
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
    return seen, full, axes, leak


def reaches(flooded, point):
    """Did that flood reach this point?"""
    seen, full, axes, leak = flooded
    return seen is not None and tuple(bisect.bisect_right(axes[a], point[a]) - 1 for a in range(3)) in seen


def check(vmf, seed, stoppers):
    """Corners on the grid, and no way from the air inside (seed) to the outside once the piece's one opening is
    stopped up (stoppers: boxes); then every entity must be in that air."""
    problems = []
    for b, _ in vmf.boxes:
        if any(v != int(v) for v in b):
            problems.append("a corner off the 1-unit grid: %r" % (b,))
    seen, full, axes, leak = flood(vmf, seed, stoppers)
    if seen is None:
        return problems + ["the check's starting point is inside a brush"], 0
    if leak:
        problems.append("NOT SEALED: the air inside reaches the outside near (%d %d %d)" % tuple(axes[a][leak[a]] for a in range(3)))
    else:
        # every entity must be in that air (or inside a brush): one in the void outside is what the compiler calls a leak
        out = []
        for cls, pos in vmf.points:
            c = tuple(bisect.bisect_right(axes[a], pos[a]) - 1 for a in range(3))
            if c not in seen and c not in full:
                out.append("%s at (%d %d %d)" % ((cls,) + tuple(pos)))
        if out:
            problems.append("%d entities are outside the sealed space (the compiler would report a leak): %s" % (len(out), "; ".join(out[:4])))
        # every areaportal: open air on both its faces, and wall, floor or roof past each of its four edges
        def solid_at(pt):
            return tuple(bisect.bisect_right(axes[a], pt[a]) - 1 for a in range(3)) in full
        for box in vmf.portals:
            size = [box[a + 3] - box[a] for a in range(3)]
            thin = size.index(min(size))
            mid = [(box[a] + box[a + 3]) / 2.0 for a in range(3)]
            bad = []
            for d in (-6, 6):
                pt = list(mid)
                pt[thin] = (box[thin] if d < 0 else box[thin + 3]) + d
                if solid_at(pt):
                    bad.append("no air on one side")
            for a in range(3):
                if a == thin:
                    continue
                for d in (-6, 6):
                    pt = list(mid)
                    pt[a] = (box[a] if d < 0 else box[a + 3]) + d
                    if not solid_at(pt):
                        bad.append("open past its %s edge" % ("xyz"[a] + ("-" if d < 0 else "+")))
            if bad:
                problems.append("the areaportal at (%d %d %d) would not work: %s" % (mid[0], mid[1], mid[2], ", ".join(bad)))
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
    doorway = ("low", road_z, MAT["quay_floor"], road_z + 160)         # a way into the wall at the canal's top: where a footbridge lands
    plan.paint((0, 0, 640, 256), ("open", road_z, MAT["quay_floor"]))  # the quay: the road carries on to the canal's edge
    plan.paint((0, 256, 3072, 768), canal_floor)                       # A: east, away from the city
    plan.paint((2560, 768, 3072, 2816), canal_floor)                   # B: the turn north
    plan.paint((3072, 2304, 4352, 2816), canal_floor)                  # C: the fork's east arm
    plan.paint((4352, 2304, 4608, 2816), culvert)                      #    its end: a culvert to the east gate (x 4608)
    plan.paint((2560, 2816, 3072, 3584), canal_floor)                  # D: the fork's north arm
    plan.paint((2560, 3584, 3072, 3840), culvert)                      #    its end: a culvert to the north gate (y 3840)
    plan.paint((3072, 1280, 3328, 1664), ("low", floor_z, MAT["canal_floor"], floor_z + 192)) # a low bay off B: somewhere to hide
    plan.paint((64, 768, 256, 896), doorway)                           # where the quay's footbridge lands, in the north wall
    plan.paint((2432, 1792, 2560, 2048), doorway)                      # the second footbridge's two ends, either side of B
    plan.paint((3072, 1792, 3200, 2048), doorway)                      # (wall on every side but the front: clear of the bay and of the east arm)

    vmf = Vmf()
    plan.build(vmf)
    B = plan.box
    W = plan.world
    cells = plan.cells

    # the sky the road sees above this piece's own (lower) sky: what the owner's brush 15074 did, from the lid up
    vmf.world_box(B(0, 0, plan.top, 640, 16, args.road_sky), MAT["sky"], MAT["sky"], MAT["sky"])

    # the two gates, closed until something is joined: each cap is inside the canal's own last 64 units
    gate_cap(vmf, B(4544, 2304, floor_z, 4608, 2816, floor_z + GATE_HIGH), B(4520, 2304, floor_z, 4528, 2816, floor_z + GATE_HIGH), "y", "LC canal: east gate's cap (delete to join)")
    gate_cap(vmf, B(2560, 3776, floor_z, 3072, 3840, floor_z + GATE_HIGH), B(2560, 3752, floor_z, 3072, 3760, floor_z + GATE_HIGH), "x", "LC canal: north gate's cap (delete to join)")

    # areaportals: across each gate's culvert and across the road's end, so what is beyond one is drawn only as far as
    # it can be seen through it (each stands a little in from the opening, so it has air on both sides even when capped)
    pv = "LC canal: areaportals"
    vmf.areaportal(B(4478, 2304, floor_z, 4480, 2816, floor_z + GATE_HIGH), pv)
    vmf.areaportal(B(2560, 3710, floor_z, 3072, 3712, floor_z + GATE_HIGH), pv)
    vmf.areaportal(B(0, 32, road_z, 640, 34, sky), pv)

    if args.test:
        # by itself the canal is open where the road comes in (that side is the city): for a test alone, a wall there
        tv = "LC canal: for testing alone (never in the real map)"
        vmf.world_box(B(-64, -64, plan.base, 704, 0, plan.top), MAT["sky"], MAT["sky"], MAT["sky"], vis=tv)
        test_extras(vmf, W(320, 128, road_z + 16), 90, tv)

    # stairs from the quay down into the canal, along its south wall: a landing, then 31 steps east
    steps = [B(512, 256, floor_z, 640, 384, road_z)]
    for i in range(31):
        steps.append(B(640 + 12 * i, 256, floor_z, 652 + 12 * i, 384, road_z - 8 * (i + 1)))
    vmf.detail(steps, MAT["canal_wall"], top=MAT["stairs"])
    # a low wall along the quay's edge (open where the footbridge starts) and round the landing
    vmf.detail([B(0, 240, road_z, 72, 256, road_z + 40), B(248, 240, road_z, 512, 256, road_z + 40), B(512, 368, road_z, 640, 384, road_z + 40), B(512, 256, road_z, 528, 368, road_z + 40)], MAT["canal_wall"])

    # --- what is a wall to the canal's floor, square by square -------------------------------------------
    def kind(c):
        spec = cells.get(c)
        if spec is None or spec[0] == "solid":
            return "wall"
        if spec[1] > floor_z:
            return "wall"   # (the quay, a doorway: higher ground is a wall from down here)
        return "floor" if spec[0] == "open" else "gap"   # (gap: a culvert or the bay, level with the floor: an opening, no bank)

    no_bank = [(448, 192, 1088, 320), (3008, 1792, 3136, 1856)]   # the stairs; the ladder's slot (below)

    def clear(x1, y1, x2, y2):
        return not any(x1 < r[2] and x2 > r[0] and y1 < r[3] and y2 > r[1] for r in no_bank)
    # every edge between a floor square and a wall, as (which way it runs, its line, from, to, which side the floor is)
    runs = {}
    for (i, j) in list(cells):
        if kind((i, j)) != "floor":
            continue
        x, y = i * CELL, j * CELL
        for (di, dj, key, a) in ((0, -1, ("x", y, 1), x), (0, 1, ("x", y + CELL, -1), x), (-1, 0, ("y", x, 1), y), (1, 0, ("y", x + CELL, -1), y)):
            if kind((i + di, j + dj)) == "wall":
                solid = cells.get((i + di, j + dj), ("solid",))[0] == "solid"
                edge = (a, key[1] - 8, a + CELL, key[1] + 8) if key[0] == "x" else (key[1] - 8, a, key[1] + 8, a + CELL)
                runs.setdefault(key, []).append((a, solid, clear(*edge)))
    banks, trims, ribs, drains = [], [], [], []
    BANK = 128
    for (axis, line, side), parts in sorted(runs.items()):
        parts.sort()
        # joined into the longest stretches, apart for banks (not at the stairs or the ladder) and for trim (only on real wall)
        for want, out in ((lambda p: p[2], banks), (lambda p: p[1] and p[2], trims)):
            start = prev = None
            for a, solid, free in parts + [(None, False, False)]:
                ok = a is not None and want((a, solid, free))
                if ok and start is not None and a == prev + CELL:
                    prev = a
                    continue
                if start is not None:
                    out.append((axis, line, side, start, prev + CELL))
                start = prev = a if ok else None
    shapes = []
    for (axis, line, side, a, b) in banks:
        # a concrete bank: 128 out from the wall's foot, 128 up it (45 degrees: the steepest that can still be walked)
        ln, top = self_line(plan, axis, line), floor_z + BANK
        prof = [(ln, floor_z), (ln + side * BANK, floor_z), (ln, top)]
        shapes.append(prism(prof, axis, self_along(plan, axis, a), self_along(plan, axis, b), MAT["canal_wall"]))
    # where a wall's corner sticks out into the canal, the two banks meet round it: a quarter of a pyramid fills the corner
    for (i, j) in list(cells):
        for (dx, dy) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            vx, vy = (i + (1 if dx > 0 else 0)) * CELL, (j + (1 if dy > 0 else 0)) * CELL   # the corner of this square in that direction
            if kind((i, j)) == "wall" and kind((i + dx, j)) == "floor" and kind((i, j + dy)) == "floor" and kind((i + dx, j + dy)) == "floor":
                if not (clear(vx - 8, vy - 8, vx + 8, vy + 8) and clear(vx + dx * 8, vy - 8, vx + dx * 72, vy + 8) and clear(vx - 8, vy + dy * 8, vx + 8, vy + dy * 72)):
                    continue
                v0, apex = W(vx, vy, floor_z), W(vx, vy, floor_z + BANK)
                px, py, pd = W(vx + dx * BANK, vy, floor_z), W(vx, vy + dy * BANK, floor_z), W(vx + dx * BANK, vy + dy * BANK, floor_z)
                m = MAT["canal_wall"]
                shapes.append([([v0, px, pd, py], m), ([v0, px, apex], m), ([v0, py, apex], m), ([apex, px, pd], m), ([apex, py, pd], m)])
    # pipes across the long run, where the beam was: a big one and a small one, on concrete saddles at each wall
    pm = MAT["bars"]
    shapes.append(prism([(ox + q[0], q[1]) for q in octagon(1600, 592, 40)], "y", oy + 256, oy + 768, pm, MAT["black"]))
    shapes.append(prism([(ox + q[0], q[1]) for q in octagon(1688, 628, 16)], "y", oy + 256, oy + 768, pm, MAT["black"]))
    saddles = [B(1544, 256, 528, 1720, 288, road_z), B(1544, 736, 528, 1720, 768, road_z)]
    vmf.detail(saddles, MAT["beam"])
    # what is already on the walls: nothing put on them after this may come within 24 units of any of it
    taken = list(saddles) + [B(448, 256, floor_z, 1088, 384, road_z + 64),                    # the stairs and their landing
                             B(64, 256, road_z - 16, 256, 768, road_z + 40),                 # the quay's footbridge
                             B(2560, 1856, road_z - 16, 3072, 1984, road_z + 40),            # the second footbridge
                             B(3008, 1792, floor_z, 3072, 1856, road_z + 128)]               # the ladder

    def fits(box, gap=24):
        return not any(box[0] < t[3] + gap and box[3] > t[0] - gap and box[1] < t[4] + gap and box[4] > t[1] - gap and box[2] < t[5] + gap and box[5] > t[2] - gap for t in taken)
    # along the top of every real wall, a concrete lip; up the walls, a rib every 512; between the ribs, a drain pipe's stub
    boxes = []
    for (axis, line, side, a, b) in trims:
        lo, hi = min(line, line + side * 16), max(line, line + side * 16)
        boxes.append(B(a, lo, road_z, b, hi, road_z + 16) if axis == "x" else B(lo, a, road_z, hi, b, road_z + 16))
        for at in range(a + 256, b - 128, 512):
            lo, hi = min(line, line + side * 24), max(line, line + side * 24)
            rib = B(at - 24, lo, floor_z + 96, at + 24, hi, road_z) if axis == "x" else B(lo, at - 24, floor_z + 96, hi, at + 24, road_z)
            if fits(rib):
                boxes.append(rib)
                taken.append(rib)
                ribs.append(at)
    for (axis, line, side, a, b) in trims:
        # (a stub half way between two ribs, on every other gap: the ribs are at 256, 768, 1280... along the wall)
        for at in range(a + 512, b - 128, 1024):
            lo, hi = min(line, line + side * 40), max(line, line + side * 40)
            z = floor_z + 176
            stub = B(at - 24, lo, z - 24, at + 24, hi, z + 24) if axis == "x" else B(lo, at - 24, z - 24, hi, at + 24, z + 24)
            if not fits(stub):
                continue
            taken.append(stub)
            ln = self_line(plan, axis, line)
            prof = [((ox if axis == "x" else oy) + q[0], q[1]) for q in octagon(at, z, 24)]
            # (pushed along the other way: out of the wall)
            shapes.append(prism(prof, "y" if axis == "x" else "x", min(ln, ln + side * 40), max(ln, ln + side * 40), pm, MAT["black"]))
            drains.append((axis, line, side, at))
    vmf.detail_shapes(shapes, "LC canal: banks, pipes and trim")
    vmf.detail(boxes, MAT["beam"], vis="LC canal: banks, pipes and trim")

    # --- two footbridges that go somewhere: each lands in a doorway in the wall, barred at its back ----------
    rail = MAT["canal_wall"]
    vmf.detail([B(64, 256, road_z - 16, 256, 768, road_z)], MAT["beam"], top=MAT["quay_floor"])                        # from the quay, over A
    vmf.detail([B(64, 256, road_z, 72, 768, road_z + 40), B(248, 256, road_z, 256, 768, road_z + 40)], rail)
    vmf.detail([B(2560, 1856, road_z - 16, 3072, 1984, road_z)], MAT["beam"], top=MAT["quay_floor"])                   # over B, from wall to wall
    vmf.detail([B(2560, 1856, road_z, 3072, 1864, road_z + 40), B(2560, 1976, road_z, 3072, 1984, road_z + 40)], rail)
    barred(vmf, B(64, 872, road_z, 256, 880, road_z + 160), "x", "LC canal: details", back=B(64, 888, road_z, 256, 896, road_z + 160))
    barred(vmf, B(2448, 1792, road_z, 2456, 2048, road_z + 160), "y", "LC canal: details", back=B(2432, 1792, road_z, 2440, 2048, road_z + 160))
    barred(vmf, B(3176, 1792, road_z, 3184, 2048, road_z + 160), "y", "LC canal: details", back=B(3192, 1792, road_z, 3200, 2048, road_z + 160))
    # a ladder up to the second bridge, in a slot left in the east bank: set up the way the owner's own map does its ladders
    # (ladder pieces 128 tall, the climbing line 28 out from them, a place to step off at each end)
    for z, model, yaw in ((floor_z, "metalladder002", 180), (floor_z + 128, "metalladder002", 180), (road_z, "metalladder002b", 0)):
        vmf.point("prop_static", W(3070, 1824, z), {"model": "models/props_c17/%s.mdl" % model, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6",
                                                    "fademindist": "-1", "fadescale": "1"}, "LC canal: details")
    vmf.point("func_useableladder", W(3042, 1824, floor_z + 130), {"point0": "%d %d %d" % W(3042, 1824, floor_z + 4), "point1": "%d %d %d" % W(3042, 1824, road_z + 12),
                                                                    "spawnflags": "0", "StartDisabled": "0"}, "LC canal: details")
    for x, z in ((3000, floor_z + 1), (3112, road_z + 1)):
        vmf.point("info_ladder_dismount", W(x, 1824, z), {}, "LC canal: details")

    # --- mud and silt on the bottom (the owner: "like some dirt/mud on the bottom of the canal?") ----------------
    # A second, displaced skin over the floor: where it rises above the concrete there is mud, where it dips below there is
    # bare concrete, so the mud has uneven edges; it piles a little at the banks' feet. Hung on thin slabs just over the floor.
    def wall_near(x, y):
        """How far a point of the floor is from the nearest wall (0 if it isn't floor)."""
        best = 9999
        for di in range(-3, 3):
            for dj in range(-3, 3):
                c = (x // CELL + di, y // CELL + dj)
                if kind(c) != "floor" and cells.get(c, ("solid",))[0] != "low":
                    cx1, cy1 = c[0] * CELL, c[1] * CELL
                    best = min(best, max(cx1 - x, 0, x - (cx1 + CELL)) + max(cy1 - y, 0, y - (cy1 + CELL)))
        return best
    import map_forest
    silt_n = 0
    blocks = sorted(set((i // 4, j // 4) for (i, j) in cells if kind((i, j)) in ("floor", "gap")))
    for (bi, bj) in blocks:
        x0, y0 = bi * 256, bj * 256
        grid = {}
        shown = False
        for i in range(5):
            for j in range(5):
                x, y = x0 + j * CELL, y0 + i * CELL
                d = wall_near(x, y)
                if d < BANK:
                    h = -16.0
                else:
                    h = -7 + 17 * map_forest.noise(x / 170.0, y / 170.0, 71) + 9 * map_forest.noise(x / 60.0, y / 60.0, 72) + (9 if d == BANK else 0)
                    shown = shown or h > 0
                grid[(i, j)] = (floor_z + h, 128 + 127 * map_forest.noise(x / 110.0, y / 110.0, 73))
        if not shown:
            continue
        vmf.world_box(B(x0, y0, floor_z, x0 + 256, y0 + 256, floor_z + 8), MAT["nodraw"], top=MAT["mud"], vis="LC canal: mud",
                      disp={"top": (2, lambda i, j, g=grid, x0=x0, y0=y0: W(x0 + j * CELL, y0 + i * CELL, g[(i, j)][0]), lambda i, j, g=grid: g[(i, j)][1])})
        silt_n += 1

    # --- where the city's people can walk: the flat of the floor, the quay, the stairs, the bridges ----------------
    blocked = [(512, 256, 1024, 384), (4480, 2304, 4608, 2816), (2560, 3712, 3072, 3840)] # (the stairs, and behind each gate's bars)
    node_id = [args.first_node]

    def node(x, y, z):
        vmf.point("info_node", W(x, y, z + 40), {"nodeid": node_id[0]}, "LC canal: path nodes")
        node_id[0] += 1
    for (i, j), spec in sorted(cells.items()):
        if spec[0] == "solid" or i % 2 != 1 or j % 2 != 1 or (i + j) % 4 != 0:
            continue
        x, y = i * CELL + 32, j * CELL + 32
        if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in blocked):
            continue
        if kind((i, j)) == "floor" and wall_near(x, y) < BANK + 16:
            continue   # (on a bank)
        node(x, y, spec[1])
    for x, y, z in ((576, 320, road_z), (736, 320, road_z - 64), (832, 320, road_z - 128), (928, 320, road_z - 208), (1056, 320, floor_z),
                    (160, 384, road_z), (160, 512, road_z), (160, 640, road_z), (2688, 1920, road_z), (2816, 1920, road_z), (2944, 1920, road_z)):
        node(x, y, z)

    # reflections: one cubemap for each stretch, at eye height
    for x, y, z in ((320, 128, road_z), (800, 512, floor_z), (2000, 512, floor_z), (2816, 1500, floor_z), (3200, 1472, floor_z), (2816, 2560, floor_z), (3900, 2560, floor_z), (2816, 3300, floor_z)):
        vmf.point("env_cubemap", W(x, y, z + 72), {"cubemapsize": "0"})

    # a little left lying about (few, and in a visgroup of their own: delete it and they're gone)
    rnd = random.Random(18)
    junk = (
        ("models/props_c17/oildrum001.mdl", 1700, 560, 0), ("models/props_c17/oildrum001.mdl", 1750, 600, 0), ("models/props_junk/wood_pallet001a.mdl", 1620, 500, 8),
        ("models/props_junk/wood_crate001a.mdl", 3200, 1340, 20), ("models/props_junk/wood_crate002a.mdl", 3250, 1420, 20), ("models/props_junk/wood_pallet001a.mdl", 3180, 1600, 8),
        ("models/props_vehicles/tire001c_car.mdl", 2760, 2400, 12), ("models/props_canal/boat001a.mdl", 2000, 470, 24), ("models/props_canal/boat002b.mdl", 4000, 2620, 24),
    )
    for model, x, y, up in junk:
        vmf.point("prop_physics", W(x, y, floor_z + up + 24), {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15), "skin": "0", "spawnflags": "0"}, "LC canal: props")

    # the checks: the opening onto the road is stopped up, then a flood from the air over the canal floor
    stopper = B(0, -64, road_z - 64, 640, 0, plan.top)
    problems, air = check(vmf, W(1280, 512, floor_z + 32), [] if args.test else [stopper])
    # a doorway is open on its front only: wall on its other three sides (one that opened sideways onto the east arm
    # showed the black wall at its back edge-on: the owner, 19 November)
    for (x1, y1, x2, y2, front) in ((64, 768, 256, 896, "south"), (2432, 1792, 2560, 2048, "east"), (3072, 1792, 3200, 2048, "west")):
        for i in range(x1 // CELL - 1, x2 // CELL + 1):
            for j in range(y1 // CELL - 1, y2 // CELL + 1):
                if x1 // CELL <= i < x2 // CELL and y1 // CELL <= j < y2 // CELL:
                    continue
                side = "west" if i < x1 // CELL else "east" if i >= x2 // CELL else "south" if j < y1 // CELL else "north"
                ahead = {"south": j < y1 // CELL, "north": j >= y2 // CELL, "west": i < x1 // CELL, "east": i >= x2 // CELL}[front]
                if cells.get((i, j), ("solid",))[0] != "solid" and not ahead:
                    problems.append("the doorway at (%d %d) is open on its %s side at (%d %d): it should be wall" % (ox + x1, oy + y1, side, ox + i * CELL, oy + j * CELL))
    world_n = sum(1 for _, w in vmf.boxes if w)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    print("canal: %d sealing brushes, %d detail boxes, %d sloped or round shapes, %d mud patches, %d entities (%d path nodes, ids %d to %d)" % (
        world_n, len(vmf.boxes) - world_n - silt_n, vmf.shapes, silt_n, len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1))
    print("  details: %d banks, %d corner fills, %d lengths of wall trim with %d ribs, %d drain stubs, 2 pipes, 2 footbridges, 1 ladder" % (
        len(banks), vmf.shapes - len(banks) - len(drains) - 2, len(trims), len(ribs), len(drains)))
    print("  it fills x %d to %d, y %d to %d, z %d to %d (the road's sky plug to %d)" % (min(xs), max(xs), min(ys), max(ys), plan.base, plan.top, args.road_sky))
    print("  gates (a culvert %d wide, %d high, floor z %d): east at x %d, y %d to %d; north at y %d, x %d to %d" % (
        GATE_WIDE, GATE_HIGH, floor_z, ox + 4608, oy + 2304, oy + 2816, oy + 3840, ox + 2560, ox + 3072))
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (a flood from the air inside stays inside, %s)" % (
            "by itself: this is the test version" if args.test else "with the road's opening stopped up: by itself this file is OPEN to the road and will leak"))
    return vmf, problems


def self_line(plan, axis, line):
    """A wall's line in the map's coordinates (the plan's own are from its origin)."""
    return (plan.origin[1] if axis == "x" else plan.origin[0]) + line


def self_along(plan, axis, v):
    return (plan.origin[0] if axis == "x" else plan.origin[1]) + v


def against(vmf, path, expected):
    """Does anything in the piece run into anything in the owner's map? (Boxes against boxes: a brush of theirs that is
    not a box may be reported though it only comes near.) expected: ids of their brushes the piece replaces."""
    import map_survey
    theirs = []
    root = map_survey.read_vmf(path)
    for top in root.kids:
        for k in (top.kids if top.name in ("world", "entity") else []):
            if k.name == "solid":
                b = map_survey.make_brush(k, "x")
                if b:
                    theirs.append(b)
    grid = map_survey.Grid(512)
    for b in theirs:
        grid.add(b)
    hits = {}
    for box, _ in vmf.boxes:
        for b in grid.near((box[0] + box[3]) / 2.0, (box[1] + box[4]) / 2.0, max(box[3] - box[0], box[4] - box[1]) / 2.0):
            if b.id not in expected and all(box[k] < b.maxs[k] - 0.5 and box[k + 3] > b.mins[k] + 0.5 for k in range(3)):
                hits[b.id] = (b.mins, b.maxs)
    if not hits:
        print("  checked against %s: nothing in the piece runs into anything in it%s" % (path.split("/")[-1], (" (but brush %s, which it replaces)" % ", ".join(sorted(expected))) if expected else ""))
        return []
    return ["it runs into %d brushes of the map's: %s" % (len(hits), "; ".join("id %s at x %d..%d y %d..%d z %d..%d" % ((i,) + tuple(int(v) for pair in zip(m[0], m[1]) for v in pair)) for i, m in sorted(hits.items())[:5]))]


def main():
    import map_forest
    import map_ring
    pieces = {"canal": canal, "ring": map_ring.ring, "forest_bunker": map_forest.forest_bunker, "forest_cave": map_forest.forest_cave}
    ap = argparse.ArgumentParser(description="Write a new piece of map as its own VMF (never touches the owner's VMF).")
    ap.add_argument("piece", choices=sorted(pieces))
    ap.add_argument("--out", help="the VMF to write (default: lc_PIECE.vmf)")
    ap.add_argument("--origin", type=int, nargs=2, default=None, metavar=("X", "Y"), help="where the piece sits on the map (default: where it joins what's already there)")
    ap.add_argument("--floor", type=int, default=None, help="forests: the height of the gate's floor (default: 400 the bunker forest, the canal's floor; 584 the cave forest, "
                    "the floor of the ring's west half)")
    ap.add_argument("--road-sky", type=int, default=2784, help="canal: the height of the sky over the road it joins (default 2784)")
    ap.add_argument("--first-node", type=int, default=None, help="the first path node id to use (default: 4000 canal, 4400 and 4600 the forests, 5000 the ring; the map's own stop at 3043)")
    ap.add_argument("--preview", help="forests: also write a picture of the piece from above to this file (needs Pillow)")
    ap.add_argument("--against", help="the owner's own VMF: also check that nothing in the piece runs into anything in it (apart from the brush the piece replaces)")
    ap.add_argument("--test", action="store_true", help="write lc_PIECE_test.vmf instead: the piece made to compile and walk by itself (a spawn point, a sun, "
                    "and for the canal a wall where the road comes in). Never put the test file in the real map.")
    args = ap.parse_args()
    if args.piece == "canal":
        args.origin = args.origin or (3328, 1856)
        args.first_node = args.first_node or 4000
    if args.piece == "ring":
        args.first_node = args.first_node or 5000
    vmf, problems = pieces[args.piece](args)
    if args.against:
        problems += against(vmf, args.against, getattr(args, "expect_overlap", {"15074"} if args.piece == "canal" else set()))
    out = args.out or "lc_%s%s.vmf" % (args.piece, "_test" if args.test else "")
    with open(out, "w") as f:
        f.write(vmf.text())
    print("  written: " + out)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
