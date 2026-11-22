"""A Combine building at Valve's scale (the owner, 21 November: the test map "has like 3 little wall sections ... not
like it generated a building or scene"). One huge centred mass (1536 to 2048 across, 1024 to 1536 high, walls 128
in 128 courses) with an off-centre skin: a deep stack of plates on the wider side of the door and a second one
lower, ribs in pairs and a tall fin on brackets on the narrower; a crown leaning over on one part of the front and
set back on the rest; a centred attic; a wing turned by 45, 1 in 2 or 1 in 4 driven into one side; the door a gate
with unequal sides (one jamb plates three to five deep, the other leaning in high) under a lintel leaning over; inside,
one tall hall with a walkway reached by a ramp of 1 in 2 on one side, a higher walkway on the other with a bridge that
stops in the air, plates and light panels on its walls. Kept when it passes the study's mirror test."""
import random

from . import tops as TP
from .geom import TILE, LEANS, TURNS, ext, rect, Frame
from . import seat as SE
from .measure import score, as_brushes
from .piece import Piece, Sink


class Building(Piece):
    def vmass(self, u0, u1, v0, v1, z0, z1, cuts=()):
        """A mass running along v, jointed across at cuts (so a stack on it leaves the rest of its face showing)."""
        vs = [v0] + sorted(c for c in set(cuts) if v0 < c < v1) + [v1]
        for a, b in zip(vs, vs[1:]):
            self.mass(rect(u0, a, u1, b), z0, z1)
            self.mids["v"].add((a + b) / 2.0)

    def build(self):
        r, X, Y, H = self.r, self.size[0], self.size[1], self.H
        T, W, ho = 128, r.choice((256, 320)), r.choice((384, 448, 512))
        g0 = (X // 2 - W // 2 + r.choice((-1, 1)) * r.choice((192, 256, 320))) // 64 * 64
        g1, fr = g0 + W, ("v", 0, 1)
        left = g0 >= X - g1                       # the wider side of the door carries the stacks
        # where the stacks go (the masses are jointed at their ends): the main one over three quarters of the wider
        # side from its outer end, a lower one by the door; inside, one on the same side; on the back and the sides
        w0, w1 = (64, g0 - 160) if left else (g1 + 160, X - 64)
        m = (w1 - w0) * r.choice((5, 6, 7)) // 8 // 32 * 32
        (s0, s1), (o0, o1) = ((w0, w0 + m), (w0 + m + 64, w1)) if left else ((w1 - m, w1), (w0, w1 - m - 64))
        ia, ib = (T + 64, g0 - 96) if g0 - T > X - T - g1 else (g1 + 96, X - T - 64)
        bs = X * r.choice((3, 4, 6, 7)) // 10 // 64 * 64
        b0, b1 = (64, bs) if r.random() < 0.5 else (bs, X - 64)
        sp = -Y + 64 + (Y - T - 128) * r.choice((4, 5, 6)) // 10 // 32 * 32
        ea = -Y + 96 + (Y - T) * r.choice((4, 5, 6)) // 10 // 32 * 32
        # ---- the centred mass ----
        self.mass(rect(0, -T, g0, 0), 0, H, (s0, s1, o0, o1, ia, ib))
        self.mass(rect(g1, -T, X, 0), 0, H, (s0, s1, o0, o1, ia, ib))
        self.course2(0, -T, ho, ho + 128, g0, g1, (32, 40, 16))      # the lintel leans over the way in, in two leans
        self.mass(rect(g0, -T, g1, 0), ho + 128, H)
        self.vmass(0, T, -Y, -T, 0, H, (sp + 64, -Y // 2 - 64))
        self.vmass(X - T, X, -Y, -T, 0, H, (-Y + 96, ea, -Y + T + 64, -T - 96))
        self.mass(rect(T, -Y, X - T, -Y + T), 0, H, (b0, b1))
        self.mass(rect(T, -Y + T, X - T, -T), H - 128, H)
        # crown: leaning over the front on one part (looks down), set back on the rest (looks up); a centred attic
        c = X * r.choice((5, 6, 10, 11)) // 16 // 64 * 64
        la, lb = r.choice(LEANS), r.choice(LEANS)
        kb = r.choice((32, 40))
        self.course([(-T, H), (0, H), (la, H + 128), (-T + kb, H + 128)], 0, c)
        self.course([(-T, H), (0, H), (-lb, H + 128), (-T + kb, H + 128)], c, X)
        self.add(ext([(0, H), (T, H), (T - r.choice((32, 40)), H + 128), (-r.choice(LEANS), H + 128)], 1, -Y, -T, self.mm))
        self.mass(rect(256, -Y + 256, X - 256, -256), H, H + 256)
        ca = (X - 640) * r.choice((5, 6, 7)) // 10 // 64 * 64
        ra, rb = (320, 320 + ca) if c > X // 2 else (X - 320 - ca, X - 320)
        self.ribs(("v", -256, 1), ra, rb, H + 32, H + 224, 32, 8, "pair", 256)
        self.tabs(("v", -256, 1), *((rb + 32, X - 320) if ra == 320 else (320, ra - 32)), H + 96)
        for f, a, b in ((("u", 256, -1), -Y + 320 + (Y - 640) * 5 // 8 + 32, -288), (("u", X - 256, 1), -Y + 288, -288), (("v", -Y + 256, -1), 288, X - 288)):
            self.tabs(f, a, b, H + 32)
            self.tabs(f, a, b, H + 160)
        self.ribs(("u", 256, -1), -Y + 320, -Y + 320 + (Y - 640) * 5 // 8, H + 64, H + 192, 16, 8, None, 128, across=True)
        # fins standing on the roof against the attic where those rows of small plates were (fins against a wall)
        for f, a, b in ((("v", -256, 1), *((rb + 48, X - 304) if ra == 320 else (304, ra - 48))), (("v", -Y + 256, -1), 304, X - 304)):
            TP.fin_row(self, f, a, b, H)
        # the tops (tops.py): the attic crowned in one of the owner's shapes, its line across the front so the street
        # sees it; the roof round it Valve's way (fins in pairs on the back edge, a generator)
        # the attic in two parts side by side, a vault (the bunker's curve) on the bigger, another shape on the other
        rt = TP.own(r, "roof")
        m = 256 + (X - 512) * rt.choice((5, 6, 10, 11)) // 16 // 64 * 64
        big, other = (0 if m - 256 >= X - 256 - m else 1), TP.pick(r, ("flat", "vault"))
        self.top = " and ".join(TP.crown(self, "vault" if i == big else other, a, b, -Y + 256, -256, H + 256, r, across="u",
                                         over=rt.choice((0, 48)) if i == big else 0) for i, (a, b) in enumerate(((256, m), (m, X - 256))))
        TP.fins(self, X // 2 - rt.choice((0, 256)), X - T - 32, -Y, -256, H, r)
        g = rt.choice((X - 192, 192))
        # generators on the roof beside the attic, two on one side and one or two on the other (stood in seat_props,
        # where nothing else stands)
        self.gens = [((u, v, H), (self.fr.yaw() + rt.choice((0, 90))) % 360) for u, vs in ((g, (-Y // 2 - 64, -Y // 2 + 96)),
                     (X - g, (-Y // 2 - 160, -Y // 2 + 32)[: rt.choice((1, 2))])) for v in vs]
        # ---- the wider side: a deep stack with its light, a lower one by the door ----
        self.stack(fr, s0, s1, r.choice((0, 64, 128)), H - r.choice((128, 256)), r.randint(4, 6))
        if o1 - o0 >= 192:
            self.stack(fr, o0, o1, r.choice((64, 192)), H // 2 + r.choice((0, 128)), 3)
        # ---- the narrower side: ribs in pairs over a low band, a tall fin on brackets, small plates ----
        n0, n1 = (g1 + 160, X - 64) if left else (64, g0 - 160)
        fw = r.choice((256, 320, 384))
        f0 = n1 - fw - r.choice((0, 64)) if left else n0 + r.choice((0, 64))
        gap, hb = r.choice((48, 56, 64)), r.choice((64, 96, 128))
        self.fbox(fr, n0, n1, 0, hb, 0, 8, self.plate)
        rb0, rb1 = (n0, f0 - 48) if left else (f0 + fw + 48, n1)
        self.ribs(fr, rb0, rb1, hb, H - r.choice((64, 192)), 32, 8, "pair", 256)
        fz0, fz1 = r.choice((128, 256)), H - r.choice((128, 256))
        self.fbox(fr, f0, f0 + fw, fz0, fz1, gap, gap + 16, self.plate)
        for z in range(fz0 + 64, fz1 - 63, r.choice((192, 256))):
            for x in (f0 + 56, f0 + fw - 96):
                self.fbox(fr, x, x + 32, z, z + 32, 0, gap, self.mm)
                self.take(fr, x, x + 32, z, z + 32)
        self.tabs(("v", gap + 16, 1), f0 + 16, f0 + fw - 16, (fz0 + fz1) // 2)
        self.tabs(fr, rb0 + 16, rb1 - 16, hb + 32, 8, keep=2, near=g1 if left else g0)     # (two beside the door)
        self.tabs(fr, rb0 + 16, rb1 - 16, H - 128)
        # ---- the gate: cheeks of unequal size, one jamb plates deep, the other leaning in high ----
        self.fbox(fr, g0 - 96, g0, 0, ho + 256, 0, 64, self.mm)
        self.fbox(fr, g1, g1 + 64, 0, ho + 128, 0, 48, self.mm)
        self.course([(0, ho + 128), (48, ho + 128), (48 - r.choice(LEANS), ho + 256), (0, ho + 256)], g1, g1 + 64)
        self.stack(("u", g0, 1), -T + 48, 64 - r.choice((48, 56)), 0, ho - 32, r.randint(3, 5), (48, 56), False)
        self.add(ext([(g1, ho - 128), (g1, ho), (g1 - 32, ho)], 1, -T, 48, self.mm))
        self.fbox(("u", g1, -1), -T + 48, -64, 32, 96, 0, 8, self.plate)
        self.sink.lamps += [(self.w((g0 - 48, 70, ho + 96)), (self.fr.yaw() + 30) % 360, 30),
                            (self.w((g1 + 32, 54, ho - 64)), (self.fr.yaw() - 15) % 360, 30)]
        # ---- the sides and the back: bands in pairs on one part of the west face, stacks on the rest ----
        self.ribs(("u", 0, -1), -Y + 64, sp, 192, H - 192, 16, 8, "pair", 256, across=True)
        self.stack(("u", 0, -1), sp + 64, -T - 96, 64, H // 2 + 128, 3, light=False)
        self.stack(("u", X, 1), -Y + 96, ea, H // 2, H - 192, 3, light=False)
        for z in (96, H // 2, H - 256):
            self.tabs(("u", 0, -1), sp + 32, -T - 96, z if z != H // 2 else H - 160)
            self.tabs(("u", X, 1), ea + 32, -T - 96, z + 64)
        self.stack(("v", -Y, -1), b0, b1, 128, H - 256, r.randint(3, 5), light=False)
        for z in (64, H // 2 + 32, H - 160):
            self.tabs(("v", -Y, -1), 64, X - 64, z)
        # a stretch of the back left bare for creeping walls standing on the ground (seat_props); the wedges keep off it
        fa, fb = (b1, X - 64) if b0 == 64 else (64, b0 - 160)
        cw = 608 if fb - fa >= 640 else 288 if fb - fa >= 320 else 0
        k = TP.own(r, "creeping").randrange((fb - fa - cw) // 16 + 1) if cw else 0
        self.cw = (fa + 16 * k, fa + 16 * k + cw)
        x = 64
        while x + 224 < X:
            if not b0 - 160 < x < b1:
                h = r.choice((256, 384))
                if not (cw and self.cw[0] - 112 < x < self.cw[1] + 16):
                    self.wedge(("v", -Y, -1), x, 128, h, self.turns[-1], x > X // 2)
            x += 96 + r.choice((112, 176, 240))
        self.interior(T, X, Y, H, g0, g1, ia, ib)
        return g0, g1, ho

    def interior(self, T, X, Y, H, g0, g1, ia, ib):
        """One tall hall: a walkway reached by a ramp of 1 in 2, a higher one opposite with a bridge that stops in the air."""
        r, mm = self.r, self.mm
        zw, ze, dw = r.choice((320, 384)), r.choice((576, 640, 704)), 192
        self.add(ext(rect(T, -Y + T, X - T, -T), 2, 0, 8, TILE))
        self.add(ext(rect(T, -Y + T, T + dw, -T), 2, zw - 16, zw, TILE))
        self.add(ext(rect(T + dw - 4, -Y + T + 160, T + dw, -T - 64), 2, zw, zw + 48, self.plate))
        self.add(ext([(T + dw, 8), (T + dw + 2 * (zw - 8), 8), (T + dw, zw)], 1, -Y + T, -Y + T + 160, mm))
        self.tabs(("v", -Y + T + 160, 1), T + dw + 64, T + dw + 2 * (zw - 8) - 96, 24)
        for v in range(-T - 96, -Y + T + 200, -256):
            self.add(ext(rect(T, v - 32, T + 48, v), 2, zw - 80, zw - 16, mm))
        e0 = X - T - 160
        self.add(ext(rect(e0, -Y + T, X - T, -Y // 2), 2, ze - 16, ze, TILE))
        self.add(ext(rect(e0, -Y + T, e0 + 4, -Y // 2 - 160), 2, ze, ze + 48, self.plate))
        bx = X // 2 + r.choice((-64, 0, 64))
        self.add(ext(rect(bx, -Y // 2 - 128, e0, -Y // 2), 2, ze - 16, ze, TILE))
        self.add(ext(rect(bx, -Y // 2 - 160, bx + 64, -Y // 2 + 32), 2, ze - 112, ze - 16, mm))
        # the walls: a deep stack under the high walkway; a staircase of plates over the low one; fins on the back
        self.stack(("u", X - T, -1), -Y + T + 64, -T - 96, 64, ze - 80, r.randint(3, 5))
        self.stack(("u", T, 1), -Y // 2 - 64, -T - 64, zw + 96, H - 320, 3, (48, 56))
        self.tiles(("u", T, 1), -Y + T + 64, -Y // 2 - 128, zw + 160, H - 384, 0, 8)
        self.ribs(("v", -Y + T, 1), T + 64, T + 64 + (X - 2 * T - 256) * 5 // 8, zw + 192, H - 256, 16, 48, "pair", 256)
        self.tabs(("v", -Y + T, 1), T + 2 * zw + 256, X - T - 192, 96)
        self.tabs(("u", X - T, -1), -Y + T + 64, -T - 64, ze + 128)
        for z in (zw + 64, H - 352, H - 224):
            self.tabs(("v", -Y + T, 1), T + 64, X - T - 64, z)
            self.tabs(("u", X - T, -1), -Y + T + 64, -T - 64, z + 32)
        for z in (96, 224):
            self.tabs(("u", T, 1), -Y + T + 64, -T - 64, z)
        wide = g0 - T > X - T - g1
        self.stack(("v", -T, -1), ia, ib, 128, H - 384, 3)
        self.tabs(("v", -T, -1), *((g1 + 32, X - T - 32, 64) if wide else (T + 32, g0 - 32, 64)), keep=2, near=g1 if wide else g0)
        self.lights.append((self.w((X // 2, -Y // 2, H - 256)), "147 226 240 300"))
        self.sink.props += [("models/props_combine/combine_intwallunit.mdl", self.w((T + 4, v, 160)), (0, (self.fr.yaw() + 90) % 360, 0))
                            for v in (-Y // 2 - 56, -Y // 2 + 40)]


def wing(b, side, turn, r):
    """A wing turned by turn (45, 1 in 2, 1 in 4), driven into the west or east side of b near its front: its end sunk in
    the side wall (its front corner up to 120 in, its back corner 2 in), its tip out and forward, its front to the south."""
    a, c = TURNS[turn]
    X, O = b.size[0], b.fr.o
    probe = Frame((0, 0, 0), (a, c))
    wd = min(probe.n(r.choice((224, 256, 320))), 118 // c)
    ln = probe.n(r.choice((512, 640, 768)))
    dy = r.choice((96, 160, 224))
    if side == "w":
        fe = (O[0] + 2 + wd * c, O[1] + dy)
        fr, tip = Frame((fe[0] - ln * a, fe[1] - ln * c, O[2]), (a, c)), 0
    else:
        fr, tip = Frame((O[0] + X - 2 - wd * c, O[1] + dy, O[2]), (a, -c)), ln
    Hw = (b.H * r.choice((5, 6, 7)) // 12) // 128 * 128
    p = Piece(fr, (ln, wd), Hw, r, b.sink)
    q, fr_face = p.q, ("v", 0, 1)
    (s0, s1), jj = p.zone(0, ln, "lo" if tip == 0 else "hi")
    p.mass(rect(0, -wd, ln, 0), 0, Hw - 128, (jj,))
    p.course2(0, -wd, Hw - 128, Hw, 0, ln, (q(32), q(40), q(16)))
    p.stack(fr_face, s0, s1, r.choice((0, 64)), Hw - 192, r.randint(3, 4))
    r0, r1 = (s1 + q(48), ln - q(160)) if tip == 0 else (q(160), s0 - q(48))
    p.ribs(fr_face, r0, r1, 64, Hw - 192, 16, 8, "pair", 256)
    p.tabs(("u", tip, -1 if tip == 0 else 1), -wd + q(24), -q(24), Hw // 2)
    p.ribs(("v", -wd, -1), q(64), ln - q(96), 128, Hw - 256, 32, 48, None, 256)
    kind = TP.pick(r, kinds=(("shed", 2), ("vault", 1), ("steps", 1)))
    p.top = TP.crown(p, kind, 0, ln, -wd, 0, Hw, r, across="u" if kind == "shed" else "v")
    return fr, p


def dress(b, side, r):
    """The draws of the tilted creeping wall that hung on the bare side, still made so the rest of a draw stays as it
    was (the creeping walls and the pipes are stood in seat_props now, where nothing else stands)."""
    r.choice((3, 4, 5)), r.choice((-128, 0, 128)), r.randint(6, 54), r.randint(-40, 40), r.randint(-15, 15)


def seat_props(b, seed):
    """Creeping walls as the owner asked (22 November: never "floating at odd angles out of everything ... put on a
    wall or used as a wall"): upright, the back flat on a wall, the foot on the floor, where nothing else stands. On
    the bare stretch of the back a combineinnerwall001a and a 001c side by side on the ground (lining it, as Valve
    stands its upright 001c in d3_c17_10b), or the 001c alone; inside, a 001c on the hall's back wall."""
    X, Y, T = b.size[0], b.size[1], 128
    rr = random.Random("creeping walls %d" % seed)
    room = SE.Room(as_brushes(b.solids) + as_brushes(b.old, "world"))
    fr = b.fr
    n_back = (fr.b / fr.L, -fr.a / fr.L)
    c0, c1 = getattr(b, "cw", (0, 0))
    models = ("models/props_combine/combineinnerwall001a.mdl", "models/props_combine/combineinnerwall001c.mdl")
    out, jobs = (-n_back[0], -n_back[1]), []
    if c1 - c0 >= 608:                         # the 001a at one end of the stretch, the 001c beside it
        wa = 2 * int(SE.bbox(models[0])[4]) + 2
        ea = (c0, c0 + wa + 16) if rr.random() < 0.5 else (c1 - wa - 16, c1)
        jobs += [(models[0], lambda s: b.w((s, -Y, 0)), out, 0, ea), (models[1], lambda s: b.w((s, -Y, 0)), out, 0, (c0, c1))]
    elif c1 > c0:
        jobs.append((models[1], lambda s: b.w((s, -Y, 0)), out, 0, (c0, c1)))
    jobs.append((models[1], lambda s: b.w((s, -Y + T, 0)), n_back, 8, (T, X - T)))
    for model, along, n, zf, (s0, s1) in jobs:
        hw = int(SE.bbox(model)[4]) + 1
        got = SE.wall(room, model, along, n, (s0 + hw, s1 - hw), zf, rr)
        if got:
            room.add(SE.obb_brush(model, *got))
            b.sink.props.append((model, got[0], (0, got[1], 0)))
    # Valve's props, each where nothing else stands: the roof's generators; two consoles on the hall's floor before the
    # wall units; a second run of rising pipes on the side away from the wing, where the face is bare
    for (u, v, z), yaw in getattr(b, "gens", ()):
        SE.stand(room, b.sink, "models/props_combine/combine_generator01.mdl", b.w((u, v, z)), yaw)
    for v in (-Y // 2 - 160, -Y // 2 + 112):
        SE.stand(room, b.sink, "models/props_combine/combine_interface001.mdl", b.w((T + rr.choice((224, 256, 288)), v, 8)), (fr.yaw(False) + 180) % 360)
    pipe = "models/props_combine/pipes01_single01a.mdl"
    for fu, yaw, out in (((0, 180, -1), (X, 0, 1)) if b.wing == "w" else ((X, 0, 1), (0, 180, -1))):
        runs, after = 0, -Y
        for v, off in ((v, off) for v in range(-Y + 192, -T - 128, 32) for off in (12, 20, 28)):
            spots = [(b.w((fu + out * off, v - 28 * k, 0)), (yaw + (15 if k == 1 else 0) + fr.yaw(False)) % 360) for k in range(3)]
            if runs == 2 or v < after or not all(SE.stand(SE.Room(list(room.B)), SE.Sink(), pipe, p, y) for p, y in spots):
                continue
            for p, y in spots:
                SE.stand(room, b.sink, pipe, p, y)
            runs, after = runs + 1, v + 256          # (up to two runs of three on a side, 256 or more apart)


def building(box, seed=1, tries=6, sink=None):
    """A Combine building in box (x1 y1 z1 x2 y2 z2), its front to the south: a Sink, and what the mirror test said."""
    x1, y1, z1, x2, y2, z2 = box
    best = None
    for n in range(tries):
        r = random.Random("building %d %d" % (seed, n))
        X, Y = (x2 - x1 - 256) // 256 * 256, (y2 - y1 - 320) // 128 * 128
        b = Building(Frame((x1 + 128, y1 + 192, z1)), (X, Y), (z2 - z1 - 256), r)
        door = b.build()
        side = r.choice(("w", "e"))
        wing(b, side, r.choice((45, 45, 26.6, 14.0)), r)
        dress(b, side, r)
        bad, walls, pas = score(b.solids)
        if best is None or bad < best[0]:
            best = (bad, n + 1, b, walls, pas, door, side)
        if not bad:
            break
    bad, n, b, walls, pas, door, side = best
    b.wing = side
    seat_props(b, seed)
    if sink is not None:
        for k in ("solids", "old", "boxes", "lights", "lamps", "props"):
            getattr(sink, k).extend(getattr(b.sink, k))
    return {"sink": b.sink, "draw": n, "mirrored": bad, "walls": walls, "passages": pas, "door": door, "wing": side,
            "frame": b.fr, "size": (b.size[0], b.size[1], b.H), "top": b.top}
