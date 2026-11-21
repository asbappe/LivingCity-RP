#!/usr/bin/env python3
"""
Living City: Combine pieces by the study's recipe (for the owner's PC, never the server)

The owner, 21 November: reproduce the Combine's odd, unnerving, unsymmetrical architecture. The recipe
and its numbers come from Valve's Citadel maps: _dev/reference/valve_citadel/wip/architecture_notes.md.
combine_piece(kind, box, seed): masses on a 256 bay in 128 courses; plates 2, 4, 8 or 16 thick (2 or 3
a piece) in 3 to 6 relief levels on about a third of a wall (first step 48 to 64, then 4 or 8); one or
two leans (a 128 course set back 32, 40 or 16); 1 to 3 plan turns (45, 26.6, 14.0, 22.5); ribs on a 256
rhythm broken by pairs; small plates straight on big masses; cold light panels flush in the plates; the
two sides of each wall and passage built differently, and a draw that mirrors (the study's walls.py
test) drawn again. Convex solids on whole numbers; sloped faces with their corners on the 4 grid.

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
TRIM, LIGHT, COLD = "metal/citadel_metalwall078a", "lights/white004_nochop", "147 226 240"
OLD, FLOOR, SKY, NODRAW = "concrete/concretewall064a", "concrete/concretefloor026a", "tools/toolsskybox", "tools/toolsnodraw"
TURNS = {45: (1, 1), 26.6: (2, 1), 14.0: (4, 1), 22.5: (12, 5)}     # plan turns as whole-number ratios (along, out)
G, LEANS = 4, (32, 32, 40, 40, 16)      # the grid of sloped corners; set-backs over a 128 course (1 in 4, 5 in 16, 1 in 8)


def ext(prof, axis, a, b, mat):
    """A convex outline pushed along one axis (0 u, 1 v, 2 z) from a to b; prof is in the other two, in order."""
    def at(t, p):
        q = list(p)
        q.insert(axis, t)
        return tuple(q)
    n = len(prof)
    f = [([at(a, p) for p in prof], mat), ([at(b, p) for p in prof], mat)]
    return f + [([at(a, prof[i]), at(a, prof[i - n + 1]), at(b, prof[i - n + 1]), at(b, prof[i])], mat) for i in range(n)]


def loft(bot, top, z0, z1, mat):
    """From one outline at z0 to one with the same corners at z1, edges parallel (so every face is flat)."""
    n = len(bot)
    return [([p + (z0,) for p in bot], mat), ([p + (z1,) for p in top], mat)] + [
        ([bot[i] + (z0,), bot[i - n + 1] + (z0,), top[i - n + 1] + (z1,), top[i] + (z1,)], mat) for i in range(n)]


def rect(u0, v0, u1, v1):
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def cut(poly, i, a, b):
    """Corner i of an outline cut off, a along u and b along v (a turned face when a:b is one of TURNS)."""
    cu, cv = poly[i]

    def toward(q):
        return (cu + a * ((q[0] > cu) - (q[0] < cu)), cv + b * ((q[1] > cv) - (q[1] < cv)))
    return poly[:i] + [toward(poly[i - 1]), toward(poly[(i + 1) % len(poly)])] + poly[i + 1:]


def clip(poly, a, b):
    """An outline cut to a <= u <= b (only ever across edges that run along u, so corners stay whole)."""
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
    """The legs of a cut or wedge turned by turn, about size along and at most most out: (a, b, steps)."""
    q, p = TURNS[turn]
    k = max(1, min(size // (q * G), most // (p * G)))
    return k * q * G, k * p * G, k


def rib_run(a, b, w, r, mode=None, pitch=256):
    """Starts of ribs w wide from a to b: even (2 in 5), in pairs 14 to 36 apart (1 in 5) or free (2 in 5), as Valve's runs."""
    mode, out, x = mode or r.choice(("even", "even", "pair", "free", "free")), [], a
    gap, pat = r.choice((14, 16, 24, 32, 36)), r.choice(((32, 160), (14, 98, 14, 490), (170, 36, 510), (36, 220, 36, 98)))
    while x + w * (2 if mode == "pair" else 1) + (gap if mode == "pair" else 0) <= b:
        out += [x, x + w + gap] if mode == "pair" else [x]
        x += pitch if mode != "free" else w + pat[len(out) % len(pat)]
    return out


def orient(faces):
    """Each face's corners turned so that (c - a) x (b - a) points out, as Hammer writes them."""
    mid = np.mean([v for vs, _ in faces for v in vs], 0)
    out = []
    for vs, m in faces:
        a, b, c = (np.array(x, float) for x in vs[:3])
        out.append((list(vs) if np.cross(c - a, b - a) @ (np.mean(vs, 0) - mid) > 0 else list(reversed(vs)), m))
    return out


class Piece:
    def __init__(self, box, r):
        x1, y1, z1, x2, y2, z2 = box
        self.r, self.z0, self.ax = r, z1, x2 - x1 >= y2 - y1       # along x facing south, else along y facing west
        self.size = (x2 - x1, y2 - y1) if self.ax else (y2 - y1, x2 - x1)
        self.o = (x1 + 64, y1 + 128) if self.ax else (x1 + 128, y1 + 64)
        self.H = (z2 - z1) // 128 * 128
        self.solids, self.old, self.lights, self.turns = [], [], [], []
        self.thick = sorted(r.sample((2, 16), 1) + r.sample((4, 8), r.choice((1, 2))))
        self.steps = [t for t in self.thick if t in (4, 8)]
        n = r.choice((1, 2, 2, 3))
        while len(self.turns) < n:
            t = r.choice((45, 45, 26.6, 14.0, 22.5))
            self.turns += [t] if t not in self.turns else []
        self.mm, self.plate = METAL[0], r.choice(METAL[1:])

    def w(self, p):
        u, v, z = p
        return (self.o[0] + u, self.o[1] - v, self.z0 + z) if self.ax else (self.o[0] - v, self.o[1] + u, self.z0 + z)

    def add(self, faces, old=False):
        (self.old if old else self.solids).append(orient([([self.w(p) for p in vs], m) for vs, m in faces]))

    def mass(self, poly, z0, z1, cuts=()):
        """A mass in 128 courses, jointed at cuts (where a stack ends, so the slab beside it still shows)."""
        us = [p[0] for p in poly]
        edges = [min(us)] + sorted(c for c in cuts if min(us) < c < max(us)) + [max(us)]
        zs = sorted({z0, z1} | set(range(z0 // 128 * 128 + 128, z1, 128)))
        for a, b in zip(edges, edges[1:]):
            for za, zb in zip(zs, zs[1:]):
                self.add(ext(clip(poly, a, b), 2, za, zb, self.mm))

    def course(self, prof, a, b):
        """A course pushed along u: a lean or a corbel."""
        self.add(ext(prof, 0, a, b, self.mm))

    # a face is (axis 'u' or 'v', its plane, +1 or -1 the way it looks); on it s runs along, t up, d out
    def fpoly(self, face, sd, t0, t1, mat):
        ax, pl, sg = face
        self.add(ext([(s, pl + sg * d) if ax == "v" else (pl + sg * d, s) for s, d in sd], 2, t0, t1, mat))

    def fbox(self, face, s0, s1, t0, t1, d0, d1, mat):
        self.fpoly(face, [(s0, d0), (s1, d0), (s1, d1), (s0, d1)], t0, t1, mat)

    def tiles(self, face, s0, s1, t0, t1, d0, d1, slab=False, light=False, foot=0):
        """One layer: slabs or plates butted along the face, one join in five a reveal; with light the first is a light
        panel; foot: a band that high along its foot, left showing under the next layer."""
        r, s, last, lit = self.r, s0, None, 0
        bands, t = [(t0, t0 + foot)] if foot else [], t0 + foot
        while not slab and t1 - t > 256:
            h = r.choice((128, 192))
            bands, t = bands + [(t, t + h)], t + h
        bands.append((t, t1))
        while s1 - s >= 32:
            last = r.choice([x for x in ((128, 192, 256, 320) if slab else (32, 48, 64, 96, 128)) if x != last])
            e = s1 if s1 - (s + last) < 32 else s + last
            if light and not lit and t1 - t0 >= 140:
                e, lit = s + 64, 80
                self.fbox(face, s, e, t0, t1, d0, d1, LIGHT)
                ax, pl, sg = face
                q = (s + 32, pl + sg * (d1 + 40)) if ax == "v" else (pl + sg * (d1 + 40), s + 32)
                self.lights.append(self.w(q + ((t0 + t1) // 2,)))
            else:
                for b0, b1 in bands:
                    self.fbox(face, s, e, b0, b1, d0, d1, self.mm if slab else self.plate)
            s = e + (r.choice((8, 12, 40, 48)) if r.random() < 0.2 else 0)
        return lit

    def stack(self, face, s0, s1, t0, t1, levels, first=(48, 56, 64), light=True):
        """Relief levels off a face: a big first step, then plates 4 or 8, each layer inset unevenly and stepped up."""
        r, d = self.r, 0
        for k in range(levels - 1):
            step, foot = r.choice(first) if k == 0 else r.choice(self.steps), r.choice((32, 48, 64))
            if t1 - t0 < 2 * foot + 64 or s1 - s0 < 64:
                break
            lit = self.tiles(face, s0, s1, t0, t1, d, d + step, step >= 32, light and k == 0, foot)
            d += step
            a, b = sorted((r.choice((16, 32, 64, 96)), r.choice((0, 8, 24, 40))), key=lambda _: r.random())
            s0, s1, t0, t1 = s0 + max(a, lit), s1 - b, t0 + foot + r.choice((0, 8, 16)), t1 - r.choice((0, 16, 32))

    def ribs(self, face, s0, s1, t0, t1, w, d, mode=None, pitch=256, mat=TRIM, across=False):
        """A run of ribs (with across, bands up the face) on the rhythm rib_run draws."""
        for x in rib_run(t0 if across else s0, t1 if across else s1, w, self.r, mode, pitch):
            self.fbox(face, s0, s1, x, x + w, 0, d, mat) if across else self.fbox(face, x, x + w, t0, t1, 0, d, mat)

    def tabs(self, face, s0, s1, t0):
        """Small plates straight on a big mass (Valve: one join in six is a piece against one 8 times its size)."""
        self.ribs(face, s0, s1, t0, t0 + 48, 32, self.thick[0], None, 128, self.plate)

    def wedge(self, face, s, t0, t1, turn, flip=False):
        """A three-sided pier on a face, its slanted face turned by one of the ratios."""
        a, b, _ = legs(turn, 96, 64)
        s -= s % G
        self.fpoly(face, [(s, 0), (s + a, 0), (s + a, b) if flip else (s, b)], t0, t1, self.mm)
        return a

    def turned_plate(self, p1, p2, k, z0, z1):
        """A plate on a cut corner, parallel to it, its ends square to the grid."""
        du, dv = (p2[0] - p1[0]) // k, (p2[1] - p1[1]) // k
        j1, j2 = (k // 4, k - k // 4) if k >= 4 else (0, k)
        a, b = (p1[0] + j1 * du, p1[1] + j1 * dv), (p1[0] + j2 * du, p1[1] + j2 * dv)
        self.add(ext([a, b, (b[0], b[1] + 8), (a[0], a[1] + 8)], 2, z0, z1, self.plate))

    def zone(self, lo, hi, end=None):
        """A stack's span on one side of lo..hi, off its middle; and the joint where it ends inside the mass."""
        r = self.r
        m = lo + (hi - lo) * r.choice((7, 8, 9)) // 256 * 16
        if end == "lo" or (end is None and r.random() < 0.5):
            return (lo + 32, m), m
        return (m + 32, hi - 32), m + 32

    # ---- the kinds ----
    def wall(self):
        r, H = self.r, self.H
        L = (self.size[0] - 128) // 128 * 128
        a = r.choice([x for x in range(512, L - 255, 256) if 2 * x != L] or [L // 256 * 128])
        T1, T2, HA, HB = 128, r.choice((64, 128)), H - 128, H - 256
        ca, cb, k = legs(self.turns[0], 128, T2 - 16)
        c = r.choice(list(range(a + 128, L - ca - 63, 128)) or [a + 128])
        (s0, s1), j = self.zone(0, a)
        # mass one, its top course set back (looks up); mass two steps down once, its far corner cut by the first turn
        self.mass(rect(0, -T1, a, 0), 0, H - 128, (j,))
        self.course([(-T1, H - 128), (0, H - 128), (-r.choice(LEANS), H), (-T1, H)], 0, a)
        self.mass(rect(a, -T2, c, 0), 0, HA)
        self.mass(cut(rect(c, -T2, L, 0), 2, ca, cb), 0, HB)
        if k > 1:
            self.turned_plate((L - ca, 0), (L, -cb), k, 32, HB - 64)
        # front: the stack on one side of mass one; a low band over part of mass two, ribs above on each step
        fr, hb = ("v", 0, 1), r.choice((64, 96, 128))
        self.stack(fr, s0, s1, r.choice((0, 32, 64)), H - 128 - r.choice((32, 64)), r.randint(3, 6))
        self.fbox(fr, a + 32, a + 32 + (L - ca - a) * r.choice((7, 9, 11)) // 256 * 16, 0, hb, 0, self.thick[-1], self.plate)
        w, d = r.choice((16, 32)), max(self.thick[-1], 8)
        self.ribs(fr, a + 48, c - 16, hb, HA - r.choice((0, 64)), w, d, "pair")
        self.ribs(fr, c + 16, L - ca - 32, hb, HB - 32, w, d, None, 128)
        # back: turned wedges on mass one; a head leaning over the higher step (looks down); small plates
        for i, x in enumerate(rib_run(r.choice((32, 96)), a - 160, 96, r, None, r.choice((256, 384)))):
            self.wedge(("v", -T1, -1), x, 0, r.choice((256, H - 128, H)), self.turns[-1], i % 2 == 1)
        self.course([(-T2, HA - 128), (-T2, HA), (-T2 - r.choice(LEANS), HA)], a + 16, c - 16)
        self.tabs(("v", -T2, -1), a + 32, L - 64, 64)
        self.fbox(("u", 0, -1), -T1 + 16, -T1 + 64, 0, H - 160, 0, self.thick[-1], self.plate)

    def gate(self):
        r, H, T, ho = self.r, self.H, 256, 256
        L = (self.size[0] - 128) // 64 * 64
        W = r.choice((192, 256))
        wl = r.choice([x for x in (256, 320, 384, 448) if L - W - x >= 256 and abs(2 * x + W - L) >= 96] or [256])
        wr, HB = L - W - wl, H - 128
        a1, b1, _ = legs(self.turns[0], 128, 160)
        a2, b2, _ = legs(self.turns[-1], 96, 128)
        (s0, s1), j = self.zone(a1, wl, "hi") if wl > wr else self.zone(wl + W, L - a2, "lo")
        self.mass(cut(rect(0, -T, wl, 0), 3, a1, b1), 0, H, (j,))
        self.mass(cut(rect(wl + W, -T, L, 0), 2, a2, b2), 0, HB, (j,))
        # the lintel leans over the way in (looks down)
        self.course([(-T, ho), (0, ho), (32, ho + 128), (-T, ho + 128)], wl, wl + W)
        # the two sides of the way through: thin plates three to five deep on one; on the other, leaning in high and one band
        self.stack(("u", wl, 1), -T + 16, -16 - r.choice((0, 32, 64)), 0, ho - 32, r.randint(3, 5), (16, 24), False)
        self.add(ext([(wl + W, ho - 128), (wl + W, ho), (wl + W - 32, ho)], 1, -T, 0, self.mm))
        self.fbox(("u", wl + W, -1), -T + 48, -64, 32, 96, 0, self.thick[-1], self.plate)
        # front: the stack on the wider side, ribs in pairs on the narrower
        fr = ("v", 0, 1)
        self.stack(fr, s0, s1, 0, (H if wl > wr else HB) - r.choice((64, 128)), r.randint(3, 6))
        if wl > wr:
            self.ribs(fr, wl + W + 32, L - a2 - 32, 0, HB - 64, 16, 16, "pair", 192)
        else:
            self.ribs(fr, a1 + 32, wl - 32, 0, H - 64, 16, 16, "pair", 192)
        # back: turned wedges behind one side; behind the other a head leaning over part of it and small plates
        bk, x = ("v", -T, -1), 32
        while x + 160 < wl:
            x += self.wedge(bk, x, 0, H - 128, self.turns[-1], x > 64) + r.choice((48, 112))
        c = wl + W + wr * r.choice((5, 7, 9)) // 192 * 16
        self.course([(-T, HB - 128), (-T, HB), (-T - r.choice(LEANS), HB)], *r.choice(((wl + W + 16, c), (c, L - 16))))
        self.tabs(bk, wl + W + 32, L - 48, 64)

    def tower(self):
        r, H = self.r, self.H
        X, Y = (self.size[0] - 128) // 64 * 64, (self.size[1] - 192) // 64 * 64
        Hc, wa, ha = H - 256, r.choice((128, 192)), r.choice((384, 512, 640))
        a1, b1, k1 = legs(self.turns[0], 128, 128)
        a2, b2, _ = legs(self.turns[-1], 64, 64)
        s1, n0 = X - wa - r.choice((16, 32, 64)), (X - a2) // 48 * 16
        self.mass(cut(cut(rect(0, -Y, X, 0), 3, a1, b1), 1, a2, b2), 0, Hc, (s1,))

        def c16(x):
            return -(-x * 6 // 10 // 16) * 16 + 16
        # crown: one course leaning over to the south (looks down) and back on the east (looks up); a cap on it
        bot = rect(c16(a1), -Y + c16(b2), X - c16(a2), -c16(b1))
        top = rect(c16(a1), -Y + c16(b2), X - c16(a2) - 40, -c16(b1) + 32)
        self.add(loft(bot, top, Hc, Hc + 128, self.mm))
        self.mass(top, Hc + 128, H)
        # foot: the west face battered (looks up); a lower slab pressed on the south face at one end, its head set back
        self.add(ext([(0, 0), (-32, 0), (0, 128)], 1, -Y, -b1, self.mm))
        self.mass(rect(X - wa, 0, X, 64), 0, ha - 128)
        self.course([(0, ha - 128), (64, ha - 128), (64 - r.choice(LEANS), ha), (0, ha)], X - wa, X)
        self.tabs(("v", 64, 1), X - wa + 16, X - 16, ha // 2)
        # south: a tall stack beside the slab, with its light; north: three levels low on the other side
        self.stack(("v", 0, 1), a1 + 16, s1, r.choice((128, 192)), r.choice((640, 768)), r.randint(3, 6))
        self.stack(("v", -Y, -1), n0, X - a2 - 32, r.choice((64, 128)), r.choice((384, 512)), 3, light=False)
        # west: bands in pairs up one side; east: a band and small plates; a turned plate on the cut corner
        self.ribs(("u", 0, -1), -Y + 32, -Y + 32 + (Y - b1) // 32 * 8 * r.choice((1, 2)), 192, Hc - 96, 16, 16, "pair", 256, TRIM, True)
        fe = ("u", X, 1)
        self.fbox(fe, -Y + b2 + 32, -Y + b2 + 32 + (Y - b2) // 32 * 16, 640, 704, 0, self.thick[-1], self.plate)
        self.tabs(fe, -Y + b2 + 32, -48, 192)
        self.turned_plate((a1, 0), (0, -b1), k1, 64, Hc - 136)

    def skin(self):
        """Plates laid flush and square on the inside of an old room (as the Combine does in old buildings)."""
        r, t = self.r, self.thick
        X, Y = (self.size[0] - 128) // 64 * 64, (self.size[1] - 192) // 64 * 64
        d0 = r.choice(range(96, X // 2 - 128, 16))
        for bx in (rect(0, -16, d0, 0), rect(d0 + 128, -16, X, 0), rect(0, -Y, X, -Y + 16), rect(0, -Y + 16, 16, -16), rect(X - 16, -Y + 16, X, -16)):
            self.add(ext(bx, 2, 0, 320, OLD), True)
        self.add(ext(rect(d0, -16, d0 + 128, 0), 2, 192, 320, OLD), True)
        self.stack(("v", -Y + 16, 1), 48, X - 48 - X // 128 * 16, 0, 288, r.randint(3, 4), (t[-1] if t[-1] < 16 else 8,))
        fe = ("u", X - 16, -1)
        self.fbox(fe, -Y + 48, -48, 0, 64, 0, t[0], self.plate)
        self.ribs(fe, -Y + 64, -64, 64, 288, 32, 8, "pair", 192)
        self.fbox(("u", 16, 1), -Y + 48, -Y // 2, 96, 160, 0, 16, self.plate)
        self.tiles(("v", -16, -1), d0 + 144, X - 48, 0, 192, 0, 4)


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
    """A face is seen unless the point just off its middle is inside another solid (the study's test)."""
    occ = [b for b in B if AL.solid_occluder(b)]
    grid = AL.Grid(occ)
    for b in B:
        for f in b["faces"]:
            p = f["pts"].mean(0) + f["n"] * 0.5
            f["vis"] = f["mc"] not in ("tools", "sky") and not any(occ[j] is not b and AL.inside(occ[j], p) for j in grid.at(p))


def combine_faces(B):
    return [f for b in B if b["kind"] == "combine" and b["cls"] in AL.STRUCT_CLASSES and not b["disp"] for f in b["faces"] if f.get("vis") and f["mc"] == "combine"]


def mirror(faces):
    """Each wall's (mirror match, relief levels, area), and the match of the two sides of each passage (walls.py)."""
    ws = WL.group_walls(faces)
    R = [WL.raster(w) for w in ws]
    walls = [(s, WL.profile(D)[1], w["area"]) for w, D in zip(ws, R) for s in [WL.elevation_symmetry(D)] if s is not None]
    top = [float(D[np.isfinite(D)].max()) if np.isfinite(D).any() else None for D in R]
    pas = [WL.pair_match(ws[i], R[i], ws[j], R[j]) for i in range(len(ws)) for j in range(i + 1, len(ws))
           if None not in (top[i], top[j]) and (ws[j]["yaw"] - ws[i]["yaw"]) % 360 == 180 and 64 <= -top[i] - top[j] <= 640]
    return walls, [m for m in pas if m is not None]


def combine_piece(kind, box, seed=1, tries=60):
    """A Combine piece of kind (wall, gate, tower, skin) in box (x1 y1 z1 x2 y2 z2): {'solids', 'old', 'lights', ...}.
    By the study's test a draw is kept when its biggest wall of 3+ relief levels matches its mirror below 0.9, one
    such wall is below 0.6, and the two sides of every passage match below 0.5; else it is drawn again (up to tries
    times, then the least mirrored draw is kept: 'mirrored' says what it still misses)."""
    best = None
    for n in range(tries):
        p = Piece(box, random.Random("%s %d %d" % (kind, seed, n)))
        getattr(p, kind)()
        B = as_brushes(p.solids) + as_brushes(p.old, "world")
        seen(B)
        walls, pas = mirror(combine_faces(B))
        art = [(a, s) for s, lv, a in walls if lv >= 3]
        bad = 2 * (bool(art) and max(art)[1] >= 0.9) + (bool(art) and min(s for _, s in art) >= 0.6) + 2 * sum(m >= 0.5 for m in pas)
        if best is None or bad < best[0]:
            best = (bad, n + 1, p, walls, pas)
        if not bad:
            break
    bad, n, p, walls, pas = best
    return {"solids": p.solids, "old": p.old, "lights": p.lights, "draw": n, "mirrored": bad, "walls": walls, "passages": pas, "turns": p.turns, "thick": p.thick}


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
    """Same-facing wall faces within 64 of depth and touching within 8: (levels, area) of each stack, and the steps."""
    keys, out, steps = defaultdict(list), [], []
    for f in faces:
        n = f["n"]
        if abs(n[2]) < 0.6:
            keys[(round(math.degrees(math.atan2(n[1], n[0]))) % 360, round(math.degrees(math.asin(max(-1, min(1, n[2]))))))].append(f)
    for fs in keys.values():
        U = np.cross([0, 0, 1.0], fs[0]["n"])
        U /= np.linalg.norm(U)
        W = np.cross(fs[0]["n"], U)
        R = np.array([((f["pts"] @ U).min(), (f["pts"] @ U).max(), (f["pts"] @ W).min(), (f["pts"] @ W).max(), f["d"], f["area"]) for f in fs])
        par = list(range(len(R)))

        def root(x):
            while par[x] != x:
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
    leans, turns, grid, scales, la = Counter(), Counter(), Counter(), Counter(), Counter()
    for f in cf:
        n, a = f["n"], f["area"]
        scales["%g" % f["scale"] if f["scale"] else "?"] += a
        if math.degrees(math.acos(min(1.0, float(np.max(np.abs(n)))))) <= 0.5:
            continue
        off, nz, yaw = off + a, float(n[2]), math.degrees(math.atan2(n[1], n[0])) % 90
        og = min(yaw, 90 - yaw) if abs(nz) < 0.985 else 0
        if abs(nz) < 0.6 and math.degrees(math.asin(abs(nz))) > 0.5:
            lean, up = lean + a, up + a * (nz > 0)
            leans[ratio(math.degrees(math.asin(abs(nz))))] += a
        if og > 0.5:
            turn += a
            turns[ratio(og)] += a * (abs(nz) < 0.6)
        grid["on 4, 8 or 16" if all(v == int(v) and int(v) % 4 == 0 for v in f["raw"]) else "off"] += 1
    pl = [plate_dims(b) for b in comb]
    lay, steps = layers(cf)
    for lv, a in lay:
        la["1" if lv == 1 else "2" if lv == 2 else "3 to 6" if lv <= 6 else "7+"] += a
    walls, pas = mirror(cf)
    art = sorted(s for s, lv, a in walls if lv >= 3)
    g, rat = AL.Grid(comb, 256), []
    for i, b in enumerate(comb):
        for j in g.near(b["box"], 1):
            o = comb[j]["box"]
            if j > i and all(b["box"][k] - 1 <= o[k + 3] and o[k] - 1 <= b["box"][k + 3] for k in range(3)):
                m = sorted(float(max(np.ptp(x["V"], 0))) for x in (b, comb[j]))
                rat.append(m[1] / max(1.0, m[0]))
    cols = Counter(" ".join(e.get("_light", "").split()[:3]) for e in ents if e.get("classname") in ("light", "light_spot"))

    def pc(x):
        return "%.1f%%" % (100.0 * x)

    def share(xs, test):
        return pc(np.mean([test(x) for x in xs]) if len(xs) else 0)
    print("Combine in %s: %d brushes, %.1f million square units seen (Valve's ranges in brackets)" % (os.path.basename(path), len(comb), tot / 1e6))
    for name, ours, valve in (
            ("off the axes", pc(off / tot), "18.1 over 15 maps; 4 to 15 a plain hall, 15 to 35 a showpiece; d3_citadel_02 3.8"),
            ("leaning / turned", "%s / %s" % (pc(lean / tot), pc(turn / tot)), "leaning 0.4 to 11, turned 2 to 30"),
            ("leans", top(leans) + "; looking up " + pc(up / (lean or 1)), "1 in 4, 5 in 16, 1 in 8 lead; up 43 to 62"),
            ("turns", top(turns), "1 in 1 (45), 1 in 2, 1 in 4, 22.5"),
            ("sloped plane points", top(grid, 2), "HL2 on the 4 to 16 grid, EP1 mostly not"),
            ("plates", "%s of brushes; thick %s" % (share(pl, lambda p: p[0] <= 16 and p[1] >= 3 * p[0]), top(Counter(round(t) for t, _ in pl), 5)),
             "32 to 74 (median 56); 8, 16, 2, 4 lead"),
            ("layers by area", top(la, 4, "%s: %d%%"), "1: 36 to 61, 2: 10 to 29, 3 to 6: 17 to 67"),
            ("steps", top(Counter(steps), 6), "64, 48, 56, 4, 8 lead"),
            ("walls of 3+ levels", "%d: below 0.6 %s, 0.9+ %s, median %.2f" % (len(art), share(art, lambda s: s < 0.6), share(art, lambda s: s >= 0.9),
                                                                              np.median(art) if art else 0), "30 below 0.6, 43 at 0.9+"),
            ("passage sides", "%d: median %.2f" % (len(pas), np.median(pas) if pas else 0), "median 0.02 to 0.30; d3_citadel_02 0.96"),
            ("small against big", "%s of %d touching pairs differ 8 times" % (share(rat, lambda x: x >= 8), len(rat)), "15.8"),
            ("texture scale", top(scales, 3), "HL2 0.25 on 39 to 81, 1 on 21 to 55"),
            ("light panels", "%d; colours %s" % (sum(b["kind"] == "light" for b in B), top(cols, 3)), "11 to 74 a map; 147 226 240 leads")):
        print("  %-20s %s  [%s]" % (name, ours, valve))


# ---- the test map ----
LAYOUT = (("skin", (0, 1792, 0, 768, 2432, 384)), ("wall", (640, 1152, 0, 2176, 1664, 512)),
          ("gate", (2048, 384, 0, 3072, 896, 512)), ("tower", (3200, -320, 0, 3840, 320, 1280)))


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
        print("%-6s %3d solids, turns %s, plates %s, draw %d%s; walls %s; passages %s" % (
            kind, len(p["solids"]), "/".join("%g" % t for t in p["turns"]), "/".join(map(str, p["thick"])), p["draw"],
            ("", " (no wall below 0.6)", " (still mirrored)")[min(2, p["mirrored"])],
            " ".join("%.2f" % s for s, lv, a in p["walls"] if lv >= 3) or "-", " ".join("%.2f" % m for m in p["passages"]) or "-"))
    x1, y1, x2, y2, z2 = -256, -576, 4096, 2688, 1664
    sk = "LC combine: floor and sky (for testing alone)"
    v.world_box((x1, y1, -16, x2, y2, 0), NODRAW, FLOOR, NODRAW, sk)
    for b in ((x1 - 16, y1, -16, x1, y2, z2), (x2, y1, -16, x2 + 16, y2, z2), (x1 - 16, y1 - 16, -16, x2 + 16, y1, z2),
              (x1 - 16, y2, -16, x2 + 16, y2 + 16, z2), (x1 - 16, y1 - 16, z2, x2 + 16, y2 + 16, z2 + 16)):
        v.world_box(b, SKY, SKY, SKY, sk)
    test_extras(v, (1216, 256, 16), 90, sk)
    with open(out, "w") as fh:
        fh.write(v.text())
    print("wrote %s" % out)


def main():
    ap = argparse.ArgumentParser(description="Combine pieces by the study's recipe, and the study's numbers on any VMF.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("test", help="a test map: a floor, a sky box, a player start, one of each kind")
    t.add_argument("--out", default=os.path.join(HERE, "lc_combine_test.vmf"))
    t.add_argument("--seed", type=int, default=1)
    sub.add_parser("check", help="the study's numbers for the Combine in a VMF (read as text only)").add_argument("vmf")
    a = ap.parse_args()
    test_map(a.out, a.seed) if a.cmd == "test" else check(a.vmf)


if __name__ == "__main__":
    main()
