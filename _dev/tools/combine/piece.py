"""The Combine's pieces by the study's recipe (wall, gate, tower, skin) and the skin every structure is dressed in:
masses in 128 courses, stacks of plates (a big first step, then 4 or 8), ribs on a 256 rhythm broken by pairs, small
plates straight on big masses, light panels flush in the plates. All of it laid in a Frame (geom.py), so a turned
piece is built exactly as a square one."""
from . import tops as TP
from .geom import METAL, TRIM, LIGHT, COLD, OLD, G, LEANS, ext, loft, rect, cut, clip, legs, rib_run, orient, Frame
TOWER, GATE = (("vault", 2), ("steps", 2), ("ridge", 1), ("flat", 1)), (("shed", 1), ("steps", 1), ("ridge", 1))


class Sink:
    """What a structure leaves for the map: Combine solids (func_detail), old solids (world, convex), old boxes (world,
    sealing: (box, sides, top, bottom)), lights ((place, colour)), Combine lamps ((place, the yaw it faces, pitch)), props
    ((model, place, (pitch, yaw, roll)))."""

    def __init__(self):
        self.solids, self.old, self.boxes, self.lights, self.lamps, self.props = [], [], [], [], [], []


class Piece:
    def __init__(self, frame, size, H, r, sink=None):
        self.fr, self.w, self.r, self.size, self.H = frame, frame.w, r, size, H // 128 * 128
        self.sink = sink or Sink()
        self.solids, self.old, self.lights = self.sink.solids, self.sink.old, self.sink.lights
        self.turns = []
        self.mids = {"u": set(), "v": set(), "z": set()}    # middles of mass faces: ribs and small plates keep off them
        self.rows = set()                                   # (rows of small plates laid: never two on one line)
        self.taken = {}                                     # face -> [(s0, s1, t0, t1)] carrying a stack, rib or bracket
        self.thick = sorted(r.sample((2, 16), 1) + r.sample((4, 8), r.choice((1, 2))))
        self.steps = [t for t in self.thick if t in (4, 8)]
        n = r.choice((1, 2, 2, 3))
        while len(self.turns) < n:
            t = r.choice((45, 45, 26.6, 14.0, 22.5))
            self.turns += [t] if t not in self.turns else []
        self.mm, self.plate = METAL[0], r.choice(METAL[1:])

    @classmethod
    def from_box(cls, box, r, sink=None):
        """A piece in a box (x1 y1 z1 x2 y2 z2): along x facing south when wider than deep, else along y facing east."""
        x1, y1, z1, x2, y2, z2 = box
        if x2 - x1 >= y2 - y1:
            return cls(Frame((x1 + 64, y1 + 128, z1)), (x2 - x1, y2 - y1), z2 - z1, r, sink)
        return cls(Frame((x2 - 128, y1 + 64, z1), (0, 1)), (y2 - y1, x2 - x1), z2 - z1, r, sink)

    def q(self, x):
        """A length along the plan in frame units (the same number in a square frame)."""
        return x if self.fr.L == 1 else self.fr.n(x)

    def add(self, faces, old=False):
        (self.old if old else self.solids).append(orient([([self.w(p) for p in vs], m) for vs, m in faces]))

    def mass(self, poly, z0, z1, cuts=(), mat=None):
        """A mass in 128 courses, jointed at cuts (where a stack ends, so the slab beside it still shows)."""
        us = [p[0] for p in poly]
        edges = [min(us)] + sorted(c for c in cuts if min(us) < c < max(us)) + [max(us)]
        zs = sorted({z0, z1} | set(range(z0 // 128 * 128 + 128, z1, 128)))
        vs = [p[1] for p in poly]
        self.mids["v"].add((min(vs) + max(vs)) / 2.0)
        for a, b in zip(edges, edges[1:]):
            self.mids["u"].add((a + b) / 2.0)
            for za, zb in zip(zs, zs[1:]):
                self.mids["z"].add((za + zb) / 2.0)
                self.add(ext(clip(poly, a, b), 2, za, zb, mat or self.mm))

    def course(self, prof, a, b, mat=None):
        """A course pushed along u: a lean or a corbel."""
        self.add(ext(prof, 0, a, b, mat or self.mm))

    def course2(self, foot, head, z0, z1, a, b, leans, back=None):
        """A leaning course from a to b in two parts with different set-backs (a lone lean is its own mirror): its face
        at foot at z0 and foot + lean at z1 (lean > 0 leans over, < 0 sets back), its back plumb at back."""
        r = self.r
        m = a + (b - a) * r.choice((3, 5, 11, 13)) // 16
        l1, l2 = r.sample(list(leans), 2) if len(set(leans)) > 1 else (leans[0], leans[0] // 2)
        bk = head if back is None else back
        for (u0, u1), ln in (((a, m), l1), ((m, b), l2)):
            self.add(ext([(bk, z0), (foot, z0), (foot + ln, z1), (bk, z1)], 0, u0, u1, self.mm))

    # a face is (axis 'u' or 'v', its plane, +1 or -1 the way it looks); on it s runs along, t up, d out
    def fpoly(self, face, sd, t0, t1, mat):
        ax, pl, sg = face
        self.add(ext([(s, pl + sg * d) if ax == "v" else (pl + sg * d, s) for s, d in sd], 2, t0, t1, mat))

    def fbox(self, face, s0, s1, t0, t1, d0, d1, mat):
        self.fpoly(face, [(s0, d0), (s1, d0), (s1, d1), (s0, d1)], t0, t1, mat)

    def light_at(self, face, s, d, t):
        ax, pl, sg = face
        q = (s, pl + sg * d) if ax == "v" else (pl + sg * d, s)
        self.lights.append((self.w(q + (t,)), COLD + " 220"))

    def take(self, face, s0, s1, t0, t1):
        self.taken.setdefault(face, []).append((min(s0, s1), max(s0, s1), t0, t1))

    def free(self, face, s0, s1, t0, t1, pad=8):
        """Nothing laid on face within pad of this rectangle (so no side of a small plate lies in another's plane)."""
        p = self.q(pad)
        return not any(s0 - p < a1 and s1 + p > a0 and t0 - pad < b1 and t1 + pad > b0 for a0, a1, b0, b1 in self.taken.get(face, ()))

    def clear(self, face, x, w, t0=None, t1=None):
        """Whether a piece from x to x + w (and t0 to t1 up) on face leaves the middles of the mass faces under it showing
        (the study's face test hides a whole face whose middle is covered)."""
        ks = self.mids["u" if face[0] == "v" else "v"]
        hit_s = any(x <= m <= x + w for m in ks)
        if t0 is None:
            return not hit_s
        return not (hit_s and any(t0 <= m <= t1 for m in self.mids["z"]))

    def tiles(self, face, s0, s1, t0, t1, d0, d1, slab=False, light=False, foot=0, joints=()):
        """One layer: slabs or plates butted along the face, one join in five a reveal; with light the first is a light
        panel; foot: a band that high along its foot, left showing under the next layer; joints: where a piece must
        end (the next layer's edges, so what it leaves bare is a face of its own)."""
        r, q, s, last, lit = self.r, self.q, s0, None, 0
        bands, t = [(t0, t0 + foot)] if foot else [], t0 + foot
        while not slab and t1 - t > 384:
            h = r.choice((192, 256))
            bands, t = bands + [(t, t + h)], t + h
        bands.append((t, t1))
        while s1 - s >= q(32):
            last = r.choice([x for x in ((128, 192, 256, 320) if slab else (32, 48, 64, 96, 128)) if x != last])
            e = s1 if s1 - (s + q(last)) < q(32) else s + q(last)
            if light and not lit and t1 - t0 >= 140:
                e, lit = s + q(64), q(80)
                self.fbox(face, s, e, t0, t1, d0, d1, LIGHT)
                self.light_at(face, s + q(32), d1 + q(40), (t0 + t1) // 2)
            else:
                e = min([j for j in joints if s + q(16) <= j < e] or [e])
                bs = bands if not foot or e - s >= q(64) or len(bands) < 2 else [(t0, bands[1][1])] + bands[2:]     # (no 32 by 32 foot)
                for b0, b1 in bs:
                    self.fbox(face, s, e, b0, b1, d0, d1, self.mm if slab else self.plate)
            s = e + (q(r.choice((8, 12, 40, 48))) if r.random() < 0.2 and e not in joints else 0)
        return lit

    def stack(self, face, s0, s1, t0, t1, levels, first=(48, 56, 64), light=True):
        """Relief levels off a face: a big first step, then plates 4 or 8; each layer stepped in a long way on one side
        (a staircase: that side 1 or 2 deep, the other 3 to 6) and 0 to 8 on the other, and stepped up. Each layer is
        jointed where the next one ends."""
        r, q, d = self.r, self.q, 0
        left = r.random() < 0.5
        lays = []
        for k in range(levels - 1):
            step, foot = q(r.choice(first) if k == 0 else r.choice(self.steps)), r.choice((32, 48, 64))
            if t1 - t0 < 2 * foot + 64 or s1 - s0 < q(64):
                break
            lit = q(80) if light and k == 0 and t1 - t0 >= 140 else 0
            lays.append((s0, s1, t0, t1, d, d + step, step >= q(32), lit > 0, foot))
            d += step
            big = max(q(r.choice((48, 56, 64))), (s1 - s0) * r.choice((20, 25, 33)) // 100 // 8 * 8)
            small = r.choice((0, q(4), q(8)))
            a, b = (big, small) if left else (small, big)
            s0, s1, t0, t1 = s0 + max(a, lit), s1 - b, t0 + foot + r.choice((0, 8, 16)), t1 - r.choice((0, 16, 32))
        if lays:
            self.take(face, lays[0][0], lays[0][1], lays[0][2], lays[0][3])
        for i, (a0, a1, b0, b1, e0, e1, sl, li, ft) in enumerate(lays):
            nxt = lays[i + 1][:2] if i + 1 < len(lays) else ()
            self.tiles(face, a0, a1, b0, b1, e0, e1, sl, li, ft, nxt)
        return d

    def ribs(self, face, s0, s1, t0, t1, w, d, mode=None, pitch=256, mat=TRIM, across=False, d0=0):
        """A run of ribs (with across, bands up the face) on the rhythm rib_run draws, kept off the middles of the faces."""
        if across:
            for x in rib_run(t0, t1, w, self.r, mode, pitch):
                if not any(x <= m <= x + w for m in self.mids["z"]):
                    self.fbox(face, s0, s1, x, x + w, d0, d0 + d, mat)
                    self.take(face, s0, s1, x, x + w)
        else:
            q = self.q
            for x in rib_run(s0, s1, q(w), self.r, mode, q(pitch), None if self.fr.L == 1 else (q(32), q(160))):
                if self.clear(face, x, q(w)):
                    self.fbox(face, x, x + q(w), t0, t1, d0, d0 + q(d), mat)
                    self.take(face, x, x + q(w), t0, t1)

    def tabs(self, face, s0, s1, t0, d0=0, h=32, keep=0, near=None):
        """Small plates 32 by 32 on a big mass across a course joint: only keep of them, the ones nearest near (beside a
        door), as the owner asked (22 November: "massively reduce their occurrence"). The row is still drawn from r, so
        the rest of a draw stays as it was."""
        q = self.q
        j = int(round(t0 / 128.0)) * 128
        t0 = j - 16 if j >= 128 else 16                   # (across a course joint, so it stands on two courses)
        while (face, t0) in self.rows:
            t0 += 128
        self.rows.add((face, t0))
        while any(t0 <= m <= t0 + h for m in self.mids["z"]):
            t0 += 8
        xs = [x for x in rib_run(s0, s1, q(32), self.r, None, q(128), (q(32), q(96)))
              if self.clear(face, x, q(32), t0, t0 + h) and self.free(face, x, x + q(32), t0, t0 + h)]
        if near is not None:
            xs.sort(key=lambda x: abs(x + q(16) - near))
        for x in xs[:keep]:
            self.fbox(face, x, x + q(32), t0, t0 + h, d0, d0 + max(1, q(self.thick[0])), self.plate)
            self.take(face, x, x + q(32), t0, t0 + h)

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
        self.fbox(fr, a + 32, a + 32 + (L - ca - a) * r.choice((7, 9, 11)) // 256 * 16, 0, hb, 0, 8, self.plate)
        w, d = r.choice((16, 32)), 8
        self.ribs(fr, a + 48, c - 16, hb, HA - r.choice((0, 64)), w, d, "pair")
        self.ribs(fr, c + 16, L - ca - 32, hb, HB - 32, w, d, None, 128)
        # back: turned wedges on mass one; a head leaning over the higher step (looks down)
        for i, x in enumerate(rib_run(r.choice((32, 96)), a - 160, 96, r, None, r.choice((256, 384)))):
            self.wedge(("v", -T1, -1), x, 0, r.choice((256, H - 128, H)), self.turns[-1], i % 2 == 1)
        self.course([(-T2, HA - 128), (-T2, HA), (-T2 - r.choice(LEANS), HA)], a + 16, c - 16)
        self.tabs(("v", -T2, -1), a + 32, L - 64, 64)
        self.fbox(("u", 0, -1), -T1 + 16, -T1 + 64, 0, H - 160, 0, 8, self.plate)
        self.top = TP.crown(self, TP.pick(r), a, c, -T2, 0, HA, r, "u", False)

    def gate(self, W=None, ho=256, T=256):
        """A passage whose two sides differ: thin plates three to five deep on one, leaning in high on the other."""
        r, H = self.r, self.H
        L = (self.size[0] - 128) // 64 * 64
        W = W or r.choice((192, 256))
        wl = r.choice([x for x in range(256, L - W - 255, 64) if abs(2 * x + W - L) >= 96] or [256])
        wr, HB = L - W - wl, H - 128
        a1, b1, _ = legs(self.turns[0], 128, 160)
        a2, b2, _ = legs(self.turns[-1], 96, 128)
        (s0, s1), j = self.zone(a1, wl, "hi") if wl > wr else self.zone(wl + W, L - a2, "lo")
        self.mass(cut(rect(0, -T, wl, 0), 3, a1, b1), 0, H, (j,))
        self.mass(cut(rect(wl + W, -T, L, 0), 2, a2, b2), 0, HB, (j,))
        # the lintel leans over the way in (looks down)
        self.course2(0, -T, ho, ho + 128, wl, wl + W, (32, 40, 16))
        if ho + 128 < HB:
            self.mass(rect(wl, -T, wl + W, 0), ho + 128, HB)
        # the two sides of the way through: thin plates three to five deep on one; on the other, leaning in high and one band
        self.stack(("u", wl, 1), -T + 48, -r.choice((48, 56, 64)), 0, ho - 32, r.randint(3, 5), (48, 56), False)
        self.add(ext([(wl + W, ho - 128), (wl + W, ho), (wl + W - 32, ho)], 1, -T, 0, self.mm))
        self.fbox(("u", wl + W, -1), -T + 48, -64, 32, 96, 0, 8, self.plate)
        # front: the stack on the wider side, ribs in pairs on the narrower
        fr = ("v", 0, 1)
        self.stack(fr, s0, s1, 0, (H if wl > wr else HB) - r.choice((64, 128)), r.randint(3, 6))
        if wl > wr:
            self.ribs(fr, wl + W + 32, L - a2 - 32, 0, HB - 64, 16, 8, "pair", 192)
        else:
            self.ribs(fr, a1 + 32, wl - 32, 0, H - 64, 16, 8, "pair", 192)
        # back: turned wedges behind one side; behind the other a head leaning over part of it and small plates
        bk, x = ("v", -T, -1), 32
        while x + 160 < wl:
            x += self.wedge(bk, x, 0, H - 128, self.turns[-1], x > 64) + r.choice((48, 112))
        c = wl + W + wr * r.choice((5, 7, 9)) // 192 * 16
        self.course([(-T, HB - 128), (-T, HB), (-T - r.choice(LEANS), HB)], *r.choice(((wl + W + 16, c), (c, L - 16))))
        self.tabs(bk, wl + W + 32, L - 48, 64, keep=2, near=wl + W)
        self.top = TP.crown(self, TP.pick(r, (), GATE), 160, wl - 32, -T, 0, H, r, "u", False)
        return wl, W

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
        self.top = TP.crown(self, TP.pick(r, (), TOWER), top[0][0], top[1][0], top[0][1], top[2][1], H, r, "u", False)
        # foot: the west face battered (looks up); a lower slab pressed on the south face at one end, its head set back
        self.add(ext([(0, 0), (-32, 0), (0, 128)], 1, -Y, -b1, self.mm))
        self.mass(rect(X - wa, 0, X, 64), 0, ha - 128)
        self.course([(0, ha - 128), (64, ha - 128), (64 - r.choice(LEANS), ha), (0, ha)], X - wa, X)
        self.tabs(("v", 64, 1), X - wa + 16, X - 16, ha // 2)
        self.sink.lamps.append((self.w((X - wa // 2 - 8, 65, ha // 2 - 64)), (self.fr.yaw() + TP.own(r, "lamp").choice((-30, -15, 15, 30))) % 360, 30))
        # south: a tall stack beside the slab, with its light; north: three levels low on the other side
        self.stack(("v", 0, 1), a1 + 16, s1, r.choice((128, 192)), r.choice((640, 768)), r.randint(3, 6))
        self.stack(("v", -Y, -1), n0, X - a2 - 32, r.choice((64, 128)), r.choice((384, 512)), 3, light=False)
        # west: bands in pairs up one side; east: a band; a turned plate on the cut corner
        self.ribs(("u", 0, -1), -Y + 32, -Y + 32 + (Y - b1) // 32 * 8 * r.choice((1, 2)), 192, Hc - 96, 16, 8, "pair", 256, TRIM, True)
        fe = ("u", X, 1)
        self.fbox(fe, -Y + b2 + 32, -Y + b2 + 32 + (Y - b2) // 32 * 16, 640, 704, 0, 8, self.plate)
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
