#!/usr/bin/env python3
"""
Living City: Combine pieces by the study's recipe (for the owner's PC, never the server)

The owner, 21 November: reproduce the Combine's odd, unnerving, unsymmetrical architecture ("that's
something we don't do well and the C18 map doesn't do well"). The recipe and its numbers were measured
in Valve's Citadel maps: _dev/reference/valve_citadel/wip/architecture_notes.md (lessons valve-combine-*).

combine_piece(kind, box, seed) lays masses on a 256 bay in 128 courses and skins them: plates 2, 4, 8 or
16 thick (2 or 3 a piece), 3 to 6 relief levels on about a third of a wall (first step 48 to 64, then 4
or 8), one or two leans (a 128 course set back 32, 40 or 16), one to three plan turns (45, 26.6, 14.0,
22.5) as cut corners, wedges and turned plates, ribs on a 256 rhythm broken by pairs, small plates
straight on big masses, and cold light panels flush in the plates. The two sides of every wall and
passage are built differently, and a seed whose walls or passages mirror (the study's test, walls.py)
is drawn again. It returns convex solids (face lists for Vmf.detail_shapes) on whole numbers, sloped
faces with their corners on the 4 grid.

    python3 map_combine.py test --out lc_combine_test.vmf [--seed N]   one of each kind, to compile
    python3 map_combine.py check FILE.vmf                               the study's numbers for its Combine

Kinds: wall, gate (a passage with unequal sides), tower, skin (plates flush and square in an old room).
No module uses it yet: the owner looks at the test map first.
"""
import argparse
import math
import os
import random
import sys
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [HERE, os.path.join(HERE, "..", "reference", "valve_citadel", "arch_scripts")]
from map_build import Vmf, test_extras  # noqa: E402
import arch_lib as AL  # noqa: E402  (the study's VMF reader)
import walls as WL  # noqa: E402  (the study's wall mirror test)

METAL = ("metal/citadel_metalwall077a", "metal/citadel_metalwall063a", "metal/citadel_metalwall072a")
TRIM = "metal/citadel_metalwall078a"
LIGHT, COLD = "lights/white004_nochop", "147 226 240"
OLD, FLOOR, SKY, NODRAW = "concrete/concretewall064a", "concrete/concretefloor026a", "tools/toolsskybox", "tools/toolsnodraw"
TURNS = {45: (1, 1), 26.6: (2, 1), 14.0: (4, 1), 22.5: (12, 5)}     # plan turns as whole-number ratios (along, out)
G = 4                                                               # sloped faces have their corners on this grid


def ext(prof, axis, a, b, mat):
    """A convex outline pushed along one axis (0 u, 1 v, 2 z) from a to b; prof is in the other two, in order."""
    def at(t, p):
        q = list(p)
        q.insert(axis, t)
        return tuple(q)
    n = len(prof)
    f = [([at(a, p) for p in prof], mat), ([at(b, p) for p in prof], mat)]
    return f + [([at(a, prof[i]), at(a, prof[(i + 1) % n]), at(b, prof[(i + 1) % n]), at(b, prof[i])], mat) for i in range(n)]


def loft(bot, top, z0, z1, mat):
    """From one outline at z0 to another with the same corners at z1, its edges parallel (so every face is flat)."""
    n = len(bot)
    f = [([p + (z0,) for p in bot], mat), ([p + (z1,) for p in top], mat)]
    return f + [([bot[i] + (z0,), bot[(i + 1) % n] + (z0,), top[(i + 1) % n] + (z1,), top[i] + (z1,)], mat) for i in range(n)]


def rect(u0, v0, u1, v1):
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def cut(poly, i, a, b):
    """Corner i of an outline cut off: a along u, b along v (a turned face when a:b is one of TURNS)."""
    cu, cv = poly[i]

    def toward(q):
        return (cu + a * ((q[0] > cu) - (q[0] < cu)), cv + b * ((q[1] > cv) - (q[1] < cv)))
    return poly[:i] + [toward(poly[i - 1]), toward(poly[(i + 1) % len(poly)])] + poly[i + 1:]


def clip(poly, a, b):
    """A convex outline cut to a <= u <= b (cuts only cross edges along u, so corners stay whole)."""
    for lim, sg in ((a, 1), (b, -1)):
        out = []
        for i, p in enumerate(poly):
            q = poly[i - 1]
            if (sg * (p[0] - lim) >= 0) != (sg * (q[0] - lim) >= 0):
                out.append((lim, q[1] + (lim - q[0]) * (p[1] - q[1]) // (p[0] - q[0])))
            if sg * (p[0] - lim) >= 0:
                out.append(p)
        poly = [p for i, p in enumerate(out) if p != out[i - 1]]
    return poly


def legs(turn, size, most=1 << 20):
    """The two legs of a cut or wedge turned by turn, about size long and at most most out: (a, b, steps)."""
    q, p = TURNS[turn]
    k = max(1, min(size // (q * G), most // (p * G)))
    return k * q * G, k * p * G, k


def rib_run(a, b, w, r, mode=None, pitch=256):
    """Starts of ribs w wide from a to b: even (2 in 5), in pairs 14 to 36 apart (1 in 5) or free (2 in 5), as Valve's runs."""
    mode = mode or r.choice(("even", "even", "pair", "free", "free"))
    out, x = [], a
    if mode == "even":
        while x + w <= b:
            out.append(x)
            x += pitch
    elif mode == "pair":
        g = r.choice((14, 16, 24, 32, 36))
        while x + 2 * w + g <= b:
            out += [x, x + w + g]
            x += pitch
    else:
        pat = r.choice(((32, 160), (14, 98, 14, 490), (170, 36, 510), (36, 220, 36, 98)))
        while x + w <= b:
            out.append(x)
            x += w + pat[len(out) % len(pat)]
    return out


def orient(faces):
    """Each face's corners turned so that (c - a) x (b - a) points out, as Hammer writes them."""
    allv = [v for vs, _ in faces for v in vs]
    mid = np.mean(allv, 0)
    out = []
    for vs, m in faces:
        a, b, c = (np.array(x, float) for x in vs[:3])
        if np.cross(c - a, b - a) @ (np.mean(vs, 0) - mid) < 0:
            vs = list(reversed(vs))
        out.append((list(vs), m))
    return out


class Piece:
    def __init__(self, box, r):
        x1, y1, z1, x2, y2, z2 = box
        self.r, self.z0 = r, z1
        self.ax = x2 - x1 >= y2 - y1                    # along x, facing south; else along y, facing west
        self.size = (x2 - x1, y2 - y1) if self.ax else (y2 - y1, x2 - x1)
        self.o = (x1 + 64, y1 + 128) if self.ax else (x1 + 128, y1 + 64)
        self.H = (z2 - z1) // 128 * 128
        self.solids, self.old, self.lights = [], [], []
        self.thick = sorted(r.sample((2, 16), 1) + r.sample((4, 8), r.choice((1, 2))))
        self.steps = [t for t in self.thick if t in (4, 8)]
        self.turns = []
        while len(self.turns) < r.choice((1, 2, 2, 3)):
            t = r.choice((45, 45, 26.6, 14.0, 22.5))
            if t not in self.turns:
                self.turns.append(t)
        self.mass_m, self.plate = METAL[0], r.choice(METAL[1:])

    def w(self, p):
        u, v, z = p
        x, y = (self.o[0] + u, self.o[1] - v) if self.ax else (self.o[0] - v, self.o[1] + u)
        return (int(x), int(y), int(self.z0 + z))

    def add(self, faces, old=False):
        (self.old if old else self.solids).append(orient([([self.w(p) for p in vs], m) for vs, m in faces]))

    def bays(self, lo, hi, skip=()):
        """Cuts on the 256 bay between lo and hi, none inside a sloped edge's span."""
        return [u for u in range(lo // 256 * 256 + 256, hi, 256) if not any(a <= u <= b for a, b in skip)]

    def mass(self, poly, z0, z1):
        """A mass in blocks on the 256 bay and the 128 course, as Valve builds them."""
        us = [p[0] for p in poly]
        slant = [(min(p[0], q[0]), max(p[0], q[0])) for p, q in zip(poly, poly[1:] + poly[:1]) if p[0] != q[0] and p[1] != q[1]]
        cuts = self.bays(min(us), max(us), slant)
        zs = sorted({z0, z1} | set(range(z0 // 128 * 128 + 128, z1, 128)))
        for a, b in zip([min(us)] + cuts, cuts + [max(us)]):
            part = clip(poly, a, b)
            for za, zb in zip(zs, zs[1:]):
                self.add(ext(part, 2, za, zb, self.mass_m))

    def course(self, prof, a, b):
        """A course pushed along u (a lean or a corbel), cut on the bay."""
        cuts = self.bays(a, b)
        for x, y in zip([a] + cuts, cuts + [b]):
            self.add(ext(prof, 0, x, y, self.mass_m))

    # a face is (axis 'u' or 'v', its plane, +1 or -1 for the way it looks); on it s runs along, t up, d out
    def fpoly(self, face, sd, t0, t1, mat):
        ax, pl, sg = face
        self.add(ext([(s, pl + sg * d) if ax == "v" else (pl + sg * d, s) for s, d in sd], 2, t0, t1, mat))

    def fbox(self, face, s0, s1, t0, t1, d0, d1, mat):
        self.fpoly(face, [(s0, d0), (s1, d0), (s1, d1), (s0, d1)], t0, t1, mat)

    def fpt(self, face, s, t, d):
        ax, pl, sg = face
        return self.w((s, pl + sg * d, t) if ax == "v" else (pl + sg * d, s, t))

    def bands(self, t0, t1):
        out, t = [], t0
        while t1 - t > 256:
            h = self.r.choice((128, 192))
            out.append((t, t + h))
            t += h
        return out + [(t, t1)]

    def tiles(self, face, s0, s1, t0, t1, d0, d1, slab=False, light=False):
        """One layer: slabs or plates butted along the face, one join in five a reveal; with light, the first a light panel."""
        r, s, last, lit = self.r, s0, None, 0
        ws = (128, 192, 256, 320) if slab else (32, 48, 64, 96, 128)
        bands = [(t0, t1)] if slab else self.bands(t0, t1)
        while s1 - s >= 32:
            w = r.choice([x for x in ws if x != last])
            last = w
            e = s1 if s1 - (s + w) < 32 else s + w
            if light and not lit and t1 - t0 >= 140:
                e, lit = s + 64, 80
                self.fbox(face, s, e, t0, t1, d0, d1, LIGHT)
                self.lights.append(self.fpt(face, s + 32, (t0 + t1) // 2, d1 + 40))
            else:
                for b0, b1 in bands:
                    self.fbox(face, s, e, b0, b1, d0, d1, self.mass_m if slab else self.plate)
            s = e + (r.choice((8, 12, 40, 48)) if r.random() < 0.2 else 0)
        return lit

    def stack(self, face, s0, s1, t0, t1, levels, first=(48, 56, 64), light=True):
        """Relief levels off the face: a big first step, then plates 4 or 8, each layer inset unevenly."""
        r, d = self.r, 0
        for k in range(levels - 1):
            step = r.choice(first) if k == 0 else r.choice(self.steps)
            lit = self.tiles(face, s0, s1, t0, t1, d, d + step, slab=step >= 32, light=light and k == 0)
            d += step
            a, b = r.choice((16, 32, 64, 96)), r.choice((0, 8, 24, 40))
            if r.random() < 0.5:
                a, b = b, a
            s0, s1 = s0 + max(a, lit), s1 - b
            t0, t1 = t0 + r.choice((0, 16, 32)), t1 - r.choice((16, 32, 64))
            if s1 - s0 < 64 or t1 - t0 < 64:
                break

    def ribs(self, face, s0, s1, t0, t1, w, d, mode=None, pitch=256, mat=TRIM, across=False):
        """A run of ribs (or bands up the face, with across) on the rhythm rib_run draws."""
        for x in rib_run(t0 if across else s0, t1 if across else s1, w, self.r, mode, pitch):
            if across:
                self.fbox(face, s0, s1, x, x + w, 0, d, mat)
            else:
                self.fbox(face, x, x + w, t0, t1, 0, d, mat)

    def wedge(self, face, s, t0, t1, turn, size, flip=False):
        """A three-sided pier on a face, its slanted face turned by one of the ratios."""
        a, b, _ = legs(turn, size, 64)
        self.fpoly(face, [(s, 0), (s + a, 0), (s + a, b) if flip else (s, b)], t0, t1, self.mass_m)
        return a

    def turned_plate(self, p1, p2, k, off, z0, z1):
        """A plate standing on a cut corner, parallel to it, its ends square to the grid."""
        du, dv = (p2[0] - p1[0]) // k, (p2[1] - p1[1]) // k
        j1, j2 = k // 4, k - k // 4
        if j2 <= j1:
            j1, j2 = 0, k
        a, b = (p1[0] + j1 * du, p1[1] + j1 * dv), (p1[0] + j2 * du, p1[1] + j2 * dv)
        self.add(ext([a, b, (b[0] + off[0], b[1] + off[1]), (a[0] + off[0], a[1] + off[1])], 2, z0, z1, self.plate))

    # ---- the kinds ----
    def wall(self):
        r, H = self.r, self.H
        L = (self.size[0] - 128) // 128 * 128
        a = r.choice([x for x in range(512, L - 255, 256) if 2 * x != L] or [L // 256 * 128])
        T1, T2 = 128, r.choice((64, 128))
        H2 = H - 128
        # mass one, its top course set back (the face looks up)
        self.add(ext(rect(0, -T1, a, 0), 2, 0, H - 128, self.mass))
        self.add(ext([(-T1, H - 128), (0, H - 128), (-r.choice((32, 40, 16)), H), (-T1, H)], 0, 0, a, self.mass))
        # mass two, lower, its far front corner cut by the first turn and a turned plate on the cut
        ca, cb, k = legs(self.turns[0], 128, T2 - 16)
        self.add(ext(cut(rect(a, -T2, L, 0), 2, ca, cb), 2, 0, H2, self.mass))
        if k > 1:
            self.turned_plate((L - ca, 0), (L, -cb), k, (0, 8), 32, H2 - 64)
        # front: the stack on mass one, off centre; ribs in pairs on mass two
        s0 = r.randrange(32, max(48, a // 4), 16)
        s1 = min(a - 32, s0 + a * r.choice((5, 6, 7)) // 160 * 16)
        self.stack(("v", 0, 1), s0, s1, r.choice((0, 32, 64)), H - 128 - r.choice((32, 64)), r.randint(3, 6))
        self.ribs(("v", 0, 1), a + 48, L - ca - 32, 0, H2 - r.choice((0, 64)), r.choice((16, 32)), max(self.thick[-1], 8), "pair")
        # back: turned wedges on mass one; mass two's head leaning over (the face looks down) and small plates
        fb, s = ("v", -T1, -1), r.choice((32, 96))
        for i, x in enumerate(rib_run(s, a - 160, 96, r, None, r.choice((256, 384)))):
            self.wedge(fb, x, 0, r.choice((256, H - 128, H)), self.turns[-1], 96, i % 2 == 1)
        self.add(ext([(-T2, H2 - 128), (-T2, H2), (-T2 - r.choice((32, 40, 16)), H2)], 0, a + 16, L - 16, self.mass))
        self.ribs(("v", -T2, -1), a + 32, L - 64, 96, 160, 32, self.thick[0], None, 128, self.plate)
        self.fbox(("u", 0, -1), -T1 + 16, -T1 + 64, 0, H - 160, 0, self.thick[-1], self.plate)

    def gate(self):
        r, H, T = self.r, self.H, 256
        L = (self.size[0] - 128) // 64 * 64
        W = r.choice((192, 256))
        ok = [x for x in (256, 320, 384, 448) if L - W - x >= 256 and abs(2 * x + W - L) >= 96]
        wl = r.choice(ok or [256])
        wr, ho, HB = L - W - wl, 256, H - 128
        a1, b1, _ = legs(self.turns[0], 128, 160)
        a2, b2, _ = legs(self.turns[-1], 96, 128)
        self.add(ext(cut(rect(0, -T, wl, 0), 3, a1, b1), 2, 0, H, self.mass))
        self.add(ext(cut(rect(wl + W, -T, L, 0), 2, a2, b2), 2, 0, HB, self.mass))
        # the lintel, its face leaning over the way in (looks down)
        self.add(ext([(-T, ho), (0, ho), (32, ho + 128), (-T, ho + 128)], 0, wl, wl + W, self.mass))
        # the two sides of the way through: thin plates three to five deep on one, leaning in high and one band on the other
        self.stack(("u", wl, 1), -T + 16, -16 - r.choice((0, 32, 64)), 0, ho - 32, r.randint(3, 5), (16, 24), False)
        self.add(ext([(wl + W, ho - 128), (wl + W, ho), (wl + W - 32, ho)], 1, -T, 0, self.mass))
        self.fbox(("u", wl + W, -1), -T + 48, -64, 32, 96, 0, self.thick[-1], self.plate)
        # front: the stack on the wider side, ribs in pairs on the narrower
        fr = ("v", 0, 1)
        if wl > wr:
            self.stack(fr, a1 + 32, wl - 32, 0, H - r.choice((64, 128)), r.randint(3, 6))
            self.ribs(fr, wl + W + 32, L - a2 - 32, 0, HB - 64, 16, 16, "pair", 192)
        else:
            self.stack(fr, wl + W + 32, L - a2 - 32, 0, HB - r.choice((32, 64)), r.randint(3, 6))
            self.ribs(fr, a1 + 32, wl - 32, 0, H - 64, 16, 16, "pair", 192)
        # back: turned wedges behind one side, a low plate band behind the other
        bk = ("v", -T, -1)
        x = 32
        while x + 160 < wl:
            x += self.wedge(bk, x, 0, H - 128, self.turns[-1], 96, x > 64) + r.choice((48, 112))
        self.fbox(bk, wl + W + 32, L - 64, 64, 128, 0, self.thick[0], self.plate)

    def tower(self):
        r, H = self.r, self.H
        X, Y = (self.size[0] - 128) // 64 * 64, (self.size[1] - 192) // 64 * 64
        Hc = H - 256
        a1, b1, k1 = legs(self.turns[0], 128, 128)
        a2, b2, _ = legs(self.turns[-1], 64, 64)
        self.add(ext(cut(cut(rect(0, -Y, X, 0), 3, a1, b1), 1, a2, b2), 2, 0, Hc, self.mass))

        def c16(x):
            return -(-x * 6 // 10 // 16) * 16 + 16
        # crown: one course leaning over to the south (looks down) and back on the east (looks up); a cap on it
        bot = rect(c16(a1), -Y + c16(b2), X - c16(a2), -c16(b1))
        top = rect(c16(a1), -Y + c16(b2), X - c16(a2) - 40, -c16(b1) + 32)
        self.add(loft(bot, top, Hc, Hc + 128, self.mass))
        self.add(ext(top, 2, Hc + 128, H, self.mass))
        # foot: the west face battered (looks up)
        self.add(ext([(0, 0), (-32, 0), (0, 128)], 1, -Y, -b1, self.mass))
        # south: a tall stack off centre with its light; west: bands in pairs up one side; east: a band and small plates
        s0 = a1 + 32
        self.stack(("v", 0, 1), s0, min(X - 32, s0 + (X - a1) * 6 // 160 * 16), r.choice((128, 192)), r.choice((640, 768)), r.randint(3, 6))
        self.ribs(("u", 0, -1), -Y + 32, -b1 - 64 - r.choice((0, 32)), 192, Hc - 96, 16, 16, "pair", 256, TRIM, True)
        fe = ("u", X, 1)
        self.fbox(fe, -Y + b2 + 32, -32, 640, 704, 0, self.thick[-1], self.plate)
        self.ribs(fe, -Y + b2 + 32, -48, 192, 256, 32, self.thick[0], None, 128, self.plate)
        self.turned_plate((a1, 0), (0, -b1), k1, (0, 8), 64, Hc - 128)

    def skin(self):
        """Plates laid flush and square on the inside of an old room (as the Combine does in old buildings)."""
        r = self.r
        X, Y = (self.size[0] - 128) // 64 * 64, (self.size[1] - 192) // 64 * 64
        Hr, d0 = 256, r.choice(range(96, X // 2 - 128, 16))
        for bx in (rect(0, -16, d0, 0), rect(d0 + 128, -16, X, 0), rect(0, -Y, X, -Y + 16), rect(0, -Y + 16, 16, -16), rect(X - 16, -Y + 16, X, -16)):
            self.add(ext(bx, 2, 0, Hr, OLD), True)
        self.add(ext(rect(d0, -16, d0 + 128, 0), 2, 192, Hr, OLD), True)
        t = self.thick
        self.stack(("v", -Y + 16, 1), 48, 48 + (X - 96) * 2 // 48 * 16, 0, 224, r.randint(3, 4), (t[-1] if t[-1] < 16 else 8,))
        fe = ("u", X - 16, -1)
        self.fbox(fe, -Y + 48, -48, 0, 64, 0, t[0], self.plate)
        self.ribs(fe, -Y + 64, -64, 64, 240, 32, 8, "pair", 192)
        self.fbox(("u", 16, 1), -Y + 48, -Y // 2, 96, 160, 0, 16, self.plate)
        self.tiles(("v", -16, -1), 48, d0 - 16, 0, 192, 0, 4)


# ---- the study's measures, on any VMF or on a piece before it is kept ----
def as_brushes(solids, cls="func_detail"):
    out = []
    for faces in solids:
        b = AL.make_brush([[float(c) for v in vs[:3] for c in v] for vs, _ in faces], [m.lower() for _, m in faces], [""] * len(faces))
        if b is None or len(b["faces"]) != len(faces):
            raise ValueError("not a convex solid: %r" % (faces,))
        b["cls"], b["disp"] = cls, False
        out.append(b)
    return out


def seen(B):
    """Mark each face seen unless the point just off it is inside another solid (the study's test)."""
    occ = [b for b in B if AL.solid_occluder(b)]
    grid = AL.Grid(occ)
    for b in B:
        for f in b["faces"]:
            p = f["pts"].mean(0) + f["n"] * 0.5
            f["vis"] = f["mc"] not in ("tools", "sky") and not any(occ[j] is not b and AL.inside(occ[j], p) for j in grid.at(p))


def combine_faces(B):
    return [f for b in B if b["kind"] == "combine" and b["cls"] in AL.STRUCT_CLASSES and not b["disp"] for f in b["faces"] if f.get("vis") and f["mc"] == "combine"]


def mirror(faces):
    """Each wall's mirror match and relief levels, and the match of the two sides of each passage (walls.py)."""
    ws = WL.group_walls(faces)
    R = [WL.raster(w) for w in ws]
    walls, pas = [], []
    for D in R:
        s = WL.elevation_symmetry(D)
        if s is not None:
            walls.append((s, WL.profile(D)[1]))
    top = [float(D[np.isfinite(D)].max()) if np.isfinite(D).any() else None for D in R]
    for i, wa in enumerate(ws):
        for j in range(i + 1, len(ws)):
            if top[i] is None or top[j] is None or (ws[j]["yaw"] - wa["yaw"]) % 360 != 180 or not 64 <= -top[i] - top[j] <= 640:
                continue
            m = WL.pair_match(wa, R[i], ws[j], R[j])
            if m is not None:
                pas.append(m)
    return walls, pas


def combine_piece(kind, box, seed=1, tries=60):
    """A Combine piece of kind (wall, gate, tower, skin) in box (x1 y1 z1 x2 y2 z2): {'solids', 'old', 'lights', ...}.
    A draw whose articulated walls match their mirror at 0.9 or more, or a passage's sides at 0.5 or more, is drawn again."""
    for n in range(tries):
        p = Piece(box, random.Random("%s %d %d" % (kind, seed, n)))
        getattr(p, kind)()
        B = as_brushes(p.solids) + as_brushes(p.old, "world")
        seen(B)
        walls, pas = mirror(combine_faces(B))
        if all(s < 0.9 for s, lv in walls if lv >= 3) and all(m < 0.5 for m in pas):
            break
    return {"solids": p.solids, "old": p.old, "lights": p.lights, "draws": n + 1, "walls": walls, "passages": pas, "turns": p.turns, "thick": p.thick}


FRACS = sorted({(p, q) for q in (1, 2, 3, 4, 5, 6, 8, 16) for p in range(1, 4 * q + 1)}, key=lambda t: (t[1], t[0]))


def ratio(deg):
    p, q = min(FRACS, key=lambda t: abs(math.degrees(math.atan2(*t)) - deg))
    g = math.gcd(p, q)
    return "%d in %d" % (p // g, q // g) if abs(math.degrees(math.atan2(p, q)) - deg) <= 0.35 else "%.1f" % deg


def top(c, k=4, fmt="%s %d%%"):
    tot = sum(c.values()) or 1
    return ", ".join(fmt % (key, round(100 * v / tot)) for key, v in c.most_common(k)) or "none"


def plate_dims(b):
    V, N = b["V"], b["N"]
    w = sorted((float(np.ptp(V @ n)), i) for i, n in enumerate(N))
    t, it = w[0]
    rest = [(x, i) for x, i in w if abs(float(N[i] @ N[it])) < 0.15]
    if not rest:
        return t, w[-1][0]
    n3 = np.cross(N[it], N[rest[0][1]])
    return t, min(rest[0][0], float(np.ptp(V @ (n3 / np.linalg.norm(n3)))))


def layers(faces):
    """Same-facing wall faces within 64 of depth, touching within 8: (levels, area) of each such stack, and the steps."""
    keys, out, steps = defaultdict(list), [], []
    for f in faces:
        n = f["n"]
        if abs(n[2]) < 0.6:
            keys[(round(math.degrees(math.atan2(n[1], n[0]))) % 360, round(math.degrees(math.asin(max(-1, min(1, n[2]))))))].append(f)
    for fs in keys.values():
        n = fs[0]["n"]
        U = np.cross([0, 0, 1.0], n)
        U /= np.linalg.norm(U)
        W = np.cross(n, U)
        R = np.array([((f["pts"] @ U).min(), (f["pts"] @ U).max(), (f["pts"] @ W).min(), (f["pts"] @ W).max(), f["d"], f["area"]) for f in fs])
        par = list(range(len(R)))

        def root(x):
            while par[x] != x:
                par[x] = par[par[x]]
                x = par[x]
            return x
        order = np.argsort(R[:, 4])
        for ii, i in enumerate(order):
            for j in order[ii + 1:]:
                if R[j, 4] - R[i, 4] > 64:
                    break
                if R[i, 0] - 8 <= R[j, 1] and R[j, 0] - 8 <= R[i, 1] and R[i, 2] - 8 <= R[j, 3] and R[j, 2] - 8 <= R[i, 3]:
                    par[root(i)] = root(j)
        grp = defaultdict(list)
        for i in range(len(R)):
            grp[root(i)].append(i)
        for g in grp.values():
            if R[g, 5].sum() >= 16384:
                lv = np.unique(np.round(R[g, 4]))
                out.append((len(lv), R[g, 5].sum()))
                steps += [round(float(s)) for s in np.diff(lv) if s > 0.5]
    return out, steps


def check(path):
    B, ents = AL.parse(path)
    sky = AL.skybox_ids(B, ents)
    B = [b for i, b in enumerate(B) if i not in sky]
    seen(B)
    comb = [b for b in B if b["kind"] == "combine" and b["cls"] in AL.STRUCT_CLASSES and not b["disp"]]
    cf = combine_faces(B)
    tot = sum(f["area"] for f in cf) or 1
    off = lean = turn = up = 0.0
    leans, turns, grid, scales = Counter(), Counter(), Counter(), Counter()
    for f in cf:
        n, a = f["n"], f["area"]
        scales["%g" % f["scale"] if f["scale"] else "?"] += a
        if math.degrees(math.acos(min(1.0, float(np.max(np.abs(n)))))) <= 0.5:
            continue
        off += a
        nz = float(n[2])
        yaw = math.degrees(math.atan2(n[1], n[0])) % 90
        og = min(yaw, 90 - yaw) if abs(nz) < 0.985 else 0
        if abs(nz) < 0.6 and math.degrees(math.asin(abs(nz))) > 0.5:
            lean += a
            up += a * (nz > 0)
            leans[ratio(math.degrees(math.asin(abs(nz))))] += a
        if og > 0.5:
            turn += a
            if abs(nz) < 0.6:
                turns[ratio(og)] += a
        raw = f["raw"]
        grid["on 4, 8 or 16" if all(v == int(v) and int(v) % 4 == 0 for v in raw) else "off"] += 1
    pl = [plate_dims(b) for b in comb]
    lay, steps = layers(cf)
    la = Counter()
    for lv, a in lay:
        la["1" if lv == 1 else "2" if lv == 2 else "3 to 6" if lv <= 6 else "7+"] += a
    walls, pas = mirror(cf)
    art = sorted(s for s, lv in walls if lv >= 3)
    g = AL.Grid(comb, 256)
    rat = []
    for i, b in enumerate(comb):
        mi = float(max(np.ptp(b["V"], 0)))
        for j in g.near(b["box"], 1):
            o = comb[j]["box"]
            if j > i and all(b["box"][k] - 1 <= o[k + 3] and o[k] - 1 <= b["box"][k + 3] for k in range(3)):
                mj = float(max(np.ptp(comb[j]["V"], 0)))
                rat.append(max(mi, mj) / max(1.0, min(mi, mj)))
    cols = Counter(" ".join(e.get("_light", "").split()[:3]) for e in ents if e.get("classname") in ("light", "light_spot"))
    pc = lambda x: "%.1f%%" % (100.0 * x)  # noqa: E731
    print("Combine in %s: %d brushes, %.1f million square units seen" % (os.path.basename(path), len(comb), tot / 1e6))
    rows = (
        ("off the axes", pc(off / tot), "18.1% over 15 maps; 4 to 15 a plain hall, 15 to 35 a showpiece; d3_citadel_02 3.8"),
        ("leaning / turned", "%s / %s" % (pc(lean / tot), pc(turn / tot)), "leaning 0.4 to 11, turned 2 to 30 (by area)"),
        ("leans", top(leans) + "; looking up " + pc(up / (lean or 1)), "1 in 4, 5 in 16, 1 in 8 lead; looking up 43 to 62%"),
        ("turns", top(turns), "1 in 1 (45), 1 in 2, 1 in 4, 22.5"),
        ("sloped plane points", top(grid, 2), "HL2 on the 4 to 16 grid; EP1 mostly fractional"),
        ("plates", "%s of brushes; thick %s" % (pc(np.mean([t <= 16 and s >= 3 * t for t, s in pl]) if pl else 0),
                                                top(Counter(round(t) for t, _ in pl), 5)), "32 to 74% (median 56); 8, 16, 2, 4 lead"),
        ("layers by area", top(la, 4, "%s: %d%%"), "1: 36 to 61, 2: 10 to 29, 3 to 6: 17 to 67"),
        ("steps", top(Counter(steps), 6), "64, 48, 56, 4, 8 lead"),
        ("walls of 3+ levels", "%d: below 0.6 %s, 0.9+ %s, median %.2f" % (len(art), pc(np.mean([s < 0.6 for s in art]) if art else 0),
                                                                          pc(np.mean([s >= 0.9 for s in art]) if art else 0), np.median(art) if art else 0),
         "30% below 0.6, 43% at 0.9+; per-map median 0.57 to 1.0"),
        ("passage sides", "%d: median %.2f" % (len(pas), np.median(pas) if pas else 0), "median 0.02 to 0.30 in 12 of 15 maps; d3_citadel_02 0.96"),
        ("small against big", "%s of %d touching pairs differ 8 times" % (pc(np.mean([x >= 8 for x in rat]) if rat else 0), len(rat)), "15.8%"),
        ("texture scale", top(scales, 3), "HL2 0.25 on 39 to 81%, 1 on 21 to 55%"),
        ("light panels", "%d; light colours %s" % (sum(b["kind"] == "light" for b in B), top(cols, 3)), "11 to 74 a map; 147 226 240 leads"),
    )
    for name, ours, valve in rows:
        print("  %-20s %s\n  %-20s   (Valve: %s)" % (name, ours, "", valve))


# ---- the test map ----
LAYOUT = (("skin", (0, 2304, 0, 768, 2944, 320)), ("wall", (896, 1408, 0, 2176, 1920, 512)),
          ("gate", (2432, 640, 0, 3456, 1152, 512)), ("tower", (3712, -128, 0, 4224, 448, 1280)))


def tex_scale(text):
    """Texture scale by the face's longest side, as Valve's (under 512: 0.25; to 1024: 1; over: 2)."""
    parts = text.split("\t\tside\n")
    for i in range(1, len(parts)):
        vs = [[int(c) for c in m.split('"')[0].split()] for m in parts[i].split('"v" "')[1:]]
        e = max(max(v[k] for v in vs) - min(v[k] for v in vs) for k in range(3))
        parts[i] = parts[i].replace('0] 0.25"', '0] %s"' % ("0.25" if e < 512 else "1" if e <= 1024 else "2"))
    return "\t\tside\n".join(parts)


def test_map(out, seed):
    v = Vmf()
    for kind, box in LAYOUT:
        p = combine_piece(kind, box, seed)
        vis = "LC combine: " + kind
        v.detail_shapes(p["solids"], vis)
        v.ents[-1] = tex_scale(v.ents[-1])
        for o in p["old"]:
            v.world.append(v.convex_text(o, "LC combine: old room"))
        for pos in p["lights"]:
            v.point("light", pos, {"_light": COLD + " 220", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)
        print("%-6s %4d solids, %d lights, turns %s, plates %s, drawn %d time(s); walls %s; passages %s" % (
            kind, len(p["solids"]), len(p["lights"]), "/".join("%g" % t for t in p["turns"]), "/".join(map(str, p["thick"])), p["draws"],
            " ".join("%.2f" % s for s, lv in p["walls"] if lv >= 3) or "-", " ".join("%.2f" % m for m in p["passages"]) or "-"))
    x1, y1, x2, y2, z2 = -512, -640, 4736, 3456, 1664
    sk = "LC combine: floor and sky (for testing alone)"
    v.world_box((x1, y1, -16, x2, y2, 0), NODRAW, FLOOR, NODRAW, sk)
    for b in ((x1 - 16, y1, -16, x1, y2, z2), (x2, y1, -16, x2 + 16, y2, z2), (x1 - 16, y1 - 16, -16, x2 + 16, y1, z2),
              (x1 - 16, y2, -16, x2 + 16, y2 + 16, z2), (x1 - 16, y1 - 16, z2, x2 + 16, y2 + 16, z2 + 16)):
        v.world_box(b, SKY, SKY, SKY, sk)
    test_extras(v, (2048, 0, 16), 90, sk)
    with open(out, "w") as fh:
        fh.write(v.text())
    print("wrote %s" % out)


def main():
    ap = argparse.ArgumentParser(description="Combine pieces by the study's recipe, and the study's numbers on any VMF.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("test", help="write a test map: a floor, a sky box, a player start, one of each kind")
    t.add_argument("--out", default=os.path.join(HERE, "lc_combine_test.vmf"))
    t.add_argument("--seed", type=int, default=1)
    c = sub.add_parser("check", help="the study's numbers for the Combine in a VMF (read as text only)")
    c.add_argument("vmf")
    a = ap.parse_args()
    if a.cmd == "test":
        test_map(a.out, a.seed)
    else:
        check(a.vmf)


if __name__ == "__main__":
    main()
