"""Shapes for the Combine generator: outlines pushed or lofted into convex solids, and frames turned in plan by
whole-number vectors, so that every corner lands on a whole unit and every face stays flat."""
import math
from fractions import Fraction

import numpy as np

METAL = ("metal/citadel_metalwall077a", "metal/citadel_metalwall063a", "metal/citadel_metalwall072a")
TRIM, LIGHT, COLD = "metal/citadel_metalwall078a", "lights/white004_nochop", "147 226 240"
OLD, FLOOR, SKY, NODRAW = "concrete/concretewall064a", "concrete/concretefloor026a", "tools/toolsskybox", "tools/toolsnodraw"
TILE = "metal/citadel_tilefloor016a"
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


def rib_run(a, b, w, r, mode=None, pitch=256, pat=None):
    """Starts of ribs w wide from a to b: even (2 in 5), in pairs 16 to 36 apart (1 in 5) or free (2 in 5), as Valve's runs."""
    mode, out, x = mode or r.choice(("even", "even", "pair", "free", "free")), [], a
    gap = r.choice((16, 24, 32)) if w >= 32 else r.choice((32, 36))      # (side to side 48, 56 or 64: Valve's steps)
    pat = pat or r.choice(((16, 160), (24, 98, 24, 490), (170, 32, 510), (32, 220, 32, 98)))
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


class Frame:
    """Plan axes turned by a whole-number vector: u runs along (a, b), the front (v outward) along (b, -a). A frame
    unit is |(a, b)| long, so whole frame numbers land on whole world units and a flat face stays flat. (1, 0): u east,
    the front south; (1, 1): turned 45; (2, 1): 1 in 2 (26.6); (4, 1): 1 in 4 (14.0)."""

    def __init__(self, o, ab=(1, 0)):
        self.o = (o[0], o[1], o[2] if len(o) > 2 else 0)
        self.a, self.b = ab
        self.L = math.hypot(self.a, self.b)

    def w(self, p):
        u, v, z = p
        return (self.o[0] + u * self.a + v * self.b, self.o[1] + u * self.b - v * self.a, self.o[2] + z)

    def n(self, world, even=False):
        """The whole number of frame units nearest a world length (at least 1; with even, an even number)."""
        k = max(1, int(round(world / self.L)))
        return k + (k % 2) if even else k

    def yaw(self, front=True):
        """The world yaw the front looks (or, front=False, the way u runs)."""
        dx, dy = (self.b, -self.a) if front else (self.a, self.b)
        return math.degrees(math.atan2(dy, dx)) % 360


def halfplane(poly, p, d, keep_left=True):
    """A plan outline (exact fractions) cut by the line through p along d, keeping its left (or right) side."""
    def side(q):
        s = d[0] * (q[1] - p[1]) - d[1] * (q[0] - p[0])
        return s if keep_left else -s
    out = []
    for i, cur in enumerate(poly):
        prev = poly[i - 1]
        sc, sp = side(cur), side(prev)
        if (sc >= 0) != (sp >= 0):
            t = Fraction(sp) / (sp - sc)
            out.append((prev[0] + t * (cur[0] - prev[0]), prev[1] + t * (cur[1] - prev[1])))
        if sc >= 0:
            out.append(cur)
    ded = []
    for q in out:
        if not ded or q != ded[-1]:
            ded.append(q)
    if len(ded) > 1 and ded[0] == ded[-1]:
        ded.pop()
    return ded


def area2(poly):
    return sum(poly[i - 1][0] * poly[i][1] - poly[i][0] * poly[i - 1][1] for i in range(len(poly)))


def minus(box, hole):
    """A plan rectangle less a convex outline (counter-clockwise, whole numbers): convex pieces, one per edge of the
    hole that the rectangle reaches past. Corners must come out whole (choose the hole's corners with that in mind)."""
    x1, y1, x2, y2 = box
    rest = [(Fraction(x1), Fraction(y1)), (Fraction(x2), Fraction(y1)), (Fraction(x2), Fraction(y2)), (Fraction(x1), Fraction(y2))]
    out = []
    for i, p in enumerate(hole):
        q = hole[(i + 1) % len(hole)]
        d = (q[0] - p[0], q[1] - p[1])
        piece = halfplane(rest, p, d, keep_left=False)
        if len(piece) >= 3 and abs(area2(piece)) > 0:
            out.append(piece)
        rest = halfplane(rest, p, d, keep_left=True)
        if len(rest) < 3:
            break
    whole = []
    for piece in out:
        if any(c.denominator != 1 for q in piece for c in q):
            raise ValueError("a piece of the cut wall has a corner off the grid: %r" % (piece,))
        whole.append([(int(q[0]), int(q[1])) for q in piece])
    return whole
