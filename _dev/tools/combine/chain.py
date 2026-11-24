"""The Combine's wall across a street or yard (lesson valve-combine-wall-chain) and a Combine mass driven into an old
block (valve-combine-meets-old).

wall_chain: straight runs 200 to 1000 long, each turned 3 to 17 degrees from the last (the line wanders up to 34 off
the grid and is steered back), 768 high, the inner face plumb over a plinth 48 out, the outer face battered about 4.5
degrees (so the foot is twice the head); ribs following the lean on a 256 rhythm broken by pairs, a band on the
foot; a pier at every joint (a head leaning over, a stack with its light panel); a gate with unequal
sides where it crosses the road; a tower at each end. Every run is laid in a frame turned by a whole-number vector,
so its corners are whole and its faces flat.

intrusion: a plain old block with a room on its ground floor; a Combine mass turned 1 in 2 or 45 against its wall
drives in from outside, cut 128 into it at its deepest corner (16 or 8 at the other), breaking through into the room;
the wall round it cut to fit; inside, Combine plates flush and square on the old walls, one run standing 16 off."""
import math

from . import tops as TP
from .geom import LEANS, TRIM, ext, rect, rib_run, minus, Frame
from .piece import Piece

DIRS = {(a, b): math.degrees(math.atan2(b, a)) for a in range(1, 9) for b in range(-8, 9)
        if math.gcd(a, abs(b)) == 1 and math.hypot(a, b) <= 8.1 and abs(math.degrees(math.atan2(b, a))) <= 34}


def lean_units(fr, H):
    """The set-back of the outer face in frame units: a divisor of H (so the face is whole at every step) near 4.5 degrees."""
    return min((d for d in range(4, 129) if H % d == 0), key=lambda d: abs(d * fr.L - H * math.tan(math.radians(4.5))))


def run(p, k, H, r, inner=True, vary=False):
    """One straight run, u from 0 to k: the battered slab (jointed where its staircases end), its plinth, ribs, plates.
    inner=False: nothing on the inner face (its plinth, stack, ribs, tabs, the head leaning over it): for a wall whose
    inner face nobody can see (the street's wall, its back against the city's edge: the owner, 23 November, "98% of it
    doesn't need a backwall"). vary: the staircase of panels starts and ends at heights of its own, with 2 to 4 layers,
    and stands in from the run's ends by its own amounts (the kit's runs stand side by side: the owner, 24 November,
    "they are all at an equal height off the ground ... this all needs to be randomized")."""
    q, mm = p.fr.n, p.mm
    T, Le, Pl = q(64), lean_units(p.fr, H), q(48)
    step = H // Le
    # the outer face, lopsided: ribs or fins following the lean on a third of it (the 256 rhythm broken by pairs); on
    # the rest a staircase of panels following the lean, highest at the end away from the ribs, a band at its foot
    fa = k * r.choice((30, 35, 40)) // 100
    first = r.random() < 0.5
    (ra, rb), (ta, tb) = ((q(96), fa), (fa + q(32), k - q(64))) if first else ((k - fa, k - q(96)), (q(64), k - fa - q(32)))
    z0 = max(step, 64 // step * step)
    z1 = z0 + step * max(1, -(-48 // step))
    za, zt = z1 + step * max(1, 32 // step), H * r.choice((7, 8)) // 10 // step * step
    layers = None
    if vary:
        za = z1 + step * r.randint(max(1, 32 // step), max(1, 240 // step))
        zt = max(za + 3 * step, H * r.choice((55, 65, 75, 85, 92)) // 100 // step * step)
        layers = r.randint(2, 4)
        ta, tb = ta + q(r.choice((0, 16, 32, 64))), tb - q(r.choice((0, 16, 48, 96)))
    lays, dd, a0, a1 = [], 0, ta, tb
    for lay in range(layers or r.randint(3, 4)):
        if a1 - a0 < q(96) or zt - za < 2 * step:
            break
        st = q(r.choice((48, 56, 64))) if lay == 0 else q(r.choice(p.steps))
        lays.append((a0, a1, za, zt, dd, dd + st, mm if lay == 0 else p.plate))
        dd += st
        big, small = max(q(64), (a1 - a0) * r.choice((25, 33, 40)) // 100), r.choice((0, q(4), q(8)))
        a0, a1 = (a0 + big, a1 - small) if first else (a0 + small, a1 - big)
        za, zt = za + step * max(1, 32 // step), zt - step * r.choice((0, 1, 2))
    # the inner face: a stack over most of it from one end, ribs in pairs on the rest
    s0 = s1 = None
    if k * p.fr.L >= 512:
        sm = k * r.choice((55, 60, 70)) // 100
        s0, s1 = (q(64), sm) if r.random() < 0.5 else (k - sm, k - q(64))
    cuts = sorted({0, k, ra, rb} | ({lays[0][0], lays[0][1]} if lays else set()) | ({s0, s1} if s0 is not None else set()))
    for a, b in zip(cuts, cuts[1:]):
        p.add(ext([(-T, 0), (Le, 0), (0, H), (-T, H)], 0, a, b, mm))
        p.mids["u"].add((a + b) / 2.0)
    if inner:
        p.add(ext([(-T - Pl, 0), (-T, 0), (-T, 128), (-T - Pl, 128)], 0, 0, k, mm))
    p.mids["z"] |= {H / 2.0, 64.0}
    d, w = q(r.choice((8, 8, 48))), q(32)
    for x in rib_run(ra, rb - w, w, r, None, q(256), (q(16), q(160))):
        if p.clear(("v", 0, 1), x, w):
            p.add(ext([(Le, 0), (Le + d, 0), (d, H), (0, H)], 0, x, x + w, TRIM))
    t = max(1, q(p.thick[0]))
    xs = rib_run(max(ta, q(144)), min(tb, k - q(144)) - q(32), q(32), r, None, q(128), (q(32), q(96)))
    if xs:                                     # one band along the foot, where a row of small plates stood
        a, b = Le - z0 // step, Le - z1 // step
        p.add(ext([(a, z0), (a + t, z0), (b + t, z1), (b, z1)], 0, xs[0], xs[-1] + q(32), p.plate))
    for i, (b0, b1, zl, zh, e0, e1, mat) in enumerate(lays):
        nxt = lays[i + 1][:2] if i + 1 < len(lays) else ()
        js = sorted({b0, b1} | {j for j in nxt if b0 < j < b1})
        a, b = Le - zl // step, Le - zh // step
        for c0, c1 in zip(js, js[1:]):
            p.add(ext([(a + e0, zl), (a + e1, zl), (b + e1, zh), (b + e0, zh)], 0, c0, c1, mat))
    # the inner head leans over (looks down: half of Valve's leaning faces do), in two leans
    hm = k * r.choice((35, 45, 60)) // 100
    for h0, h1 in ((q(16), hm), (hm, k - q(16))):
        lean = q(r.choice(LEANS))
        if inner:
            p.add(ext([(-T, H - 128), (-T, H), (-T - lean, H)], 0, h0, h1, mm))
    if inner:
        p.tabs(("v", -T - Pl, -1), q(144), k - q(144), 40)
        p.tabs(("v", -T - Pl, -1), q(144), k - q(144), 88)
    rt = TP.own(r, "run", k)
    if rt.random() < 0.65:                     # fins on the head of two runs in three (Valve's broken skyline)
        a = max(q(144), k * rt.choice((1, 2, 3)) // 8)          # (clear of the piers at both ends)
        TP.fins(p, a, min(k - q(144), a + k * rt.choice((3, 4)) // 8), -T, 0, H, r)
    if s0 is not None and inner:
        o0, o1 = (s1 + q(48), k - q(48)) if s0 < k // 2 else (q(48), s0 - q(48))
        p.stack(("v", -T, -1), s0, s1, 160, H - 128, r.randint(3, 4), light=False)
        p.ribs(("v", -T, -1), o0, o1, 192, H - 192, 32, 8, "pair", 256)
        p.tabs(("v", -T, -1), o0, o1, H - 160)
        p.tabs(("v", -T, -1), o0, o1, H // 2)
    return T, Le, Pl


def pier(p, u0, H, r, T, Le, Pl, lamp=False, front=None):
    """A pier over a joint, centred at u0: a head leaning over the outer side, a stack with its light panel on its front.
    front: what its front carries instead, for the kit's piers (the owner, 24 November, of the white panels: "I don't
    recall ever seeing something like that in HL2 anywhere"): ("stack", from, to) a stack of plates with no light
    panel between those heights, ("bands", [(height, tall), ...]) trim bands across a plain face."""
    q = p.fr.n
    P, m, Hp = q(r.choice((64, 80, 96))), q(32), H + 128
    v0, v1 = -T - Pl - m, Le + m
    e0, e1 = sorted((q(16), q(48)), key=lambda _: r.random())
    p.mass(rect(u0 - P, v0, u0 + P, v1), 0, Hp - 128, (u0 - P + e0, u0 + P - e1))
    p.course2(v1, v0, Hp - 128, Hp, u0 - P, u0 + P, (q(32), q(40), q(16)))
    if front is None:
        p.stack(("v", v1, 1), u0 - P + e0, u0 + P - e1, r.choice((64, 128)), Hp - 256, r.randint(3, 4))
    elif front[0] == "stack":
        p.stack(("v", v1, 1), u0 - P + e0, u0 + P - e1, front[1], front[2], r.randint(2, 4), light=False)
    else:
        for z, h in front[1]:
            p.fbox(("v", v1, 1), u0 - P + e0, u0 + P - e1, z, z + h, 0, q(8), TRIM)
    p.tabs(("u", u0 + P, 1), v0 + q(16), v1 - q(16), r.choice((192, 320)))
    kind = TP.pick(r, kinds=(("ridge", 2), ("shed", 2), ("steps", 2), ("flat", 1)))
    p.top = TP.crown(p, kind, u0 - P, u0 + P, v0, v1, Hp, r, across="u", ribs=False)
    turn = r.choice((-30, -15, 15, 30)) if lamp else TP.own(r, "lamp", u0).choice((-30, -15, 15, 30))   # (a lamp on every pier)
    p.sink.lamps.append((p.w((u0 - P + q(24), v1 + 1, H - 96)), (p.fr.yaw() + turn) % 360, 30))


def heading(r, cur, y, y0, west):
    """The next run's direction: 3 to 17 degrees from the last, steered back toward the line y0 when it strays."""
    cands = [(d, a) for d, a in DIRS.items() if 3 <= abs(a - cur) <= 17]
    drift = (y - y0) * (-1 if west else 1)       # (going west, a rising run moves the line south)
    pref = [c for c in cands if (c[1] < cur if drift > 192 else c[1] > cur if drift < -64 else True)]
    return r.choice(pref or cands)


def half(sink, r, start, x_end, y0, H, west):
    """Runs from start (a gate end) out to x_end: [(the run's piece, its length in frame units, the end at the gate)]."""
    out, (px, py), cur = [], start, 0.0
    while True:
        (a, b), ang = heading(r, cur, py, y0, west)
        L = math.hypot(a, b)
        k = int(round(r.choice((256, 384, 512, 640, 768, 896, 1000)) / L))
        room = (px - x_end) if west else (x_end - px)
        k = min(k, room // a)
        if k * L < 200:
            return out, (px, py)
        if west:
            fr, px, py, gate_end = Frame((px - k * a, py - k * b, 0), (a, b)), px - k * a, py - k * b, k
        else:
            fr, px, py, gate_end = Frame((px, py, 0), (a, b)), px + k * a, py + k * b, 0
        out.append((Piece(fr, (k, 0), H, r, sink), k, gate_end))
        cur = ang


def wall_chain(sink, r, x_west, x_east, y0, gate, H=768):
    """The chain from x_west to x_east about the line y0 (its outer face to the south), a gate over gate = (x0, x1)."""
    gx0, gx1 = gate
    g = Piece(Frame((gx0, y0, 0)), (gx1 - gx0 + 128, 512), H, r, sink)
    wl, W = g.gate(W=r.choice((256, 320)), ho=384, T=256)
    sink.lamps += [(g.w((wl - 48, 1, 448)), 300, 30), (g.w((wl + W + 48, 1, 448)), 240, 30)]
    runs, ends = [], []
    for west, start, xe in ((True, (gx0, y0), x_west), (False, (gx1, y0), x_east)):
        rs, end = half(sink, r, start, xe, y0, H, west)
        runs += rs
        ends.append(end)
    for i, (p, k, ge) in enumerate(runs):
        T, Le, Pl = run(p, k, H, r)
        pier(p, ge, H, r, T, Le, Pl, lamp=i % 2 == 0)
    (wx, wy), (ex, ey) = ends
    towers = []
    for box in ((wx - 512, wy - 352, 0, wx + 128, wy + 288, H + 384), (ex - 128, ey - 352, 0, ex + 512, ey + 288, H + 384)):
        towers.append(Piece.from_box(box, r, sink))
        towers[-1].tower()
    return {"runs": [(p.fr.o, (p.fr.a, p.fr.b), k) for p, k, _ in runs], "gate": (gx0 + wl, gx0 + wl + W), "ends": ends,
            "tops": [p.top for p, _, _ in runs] + [g.top] + [t.top for t in towers]}


def intrusion(block, sink, r, mat, ceiling="concrete/concreteceiling004a", turn=None):
    """block (x1 y1 z1 x2 y2 z2): an old block whose north wall a Combine mass drives into near its north-west corner,
    with a room behind that wall and a door to it on the west face. Returns the door (y0, y1, height)."""
    bx1, by1, _, bx2, by2, bh = block
    k = 2 if (turn or r.choice((26.6, 26.6, 45))) == 26.6 else 1
    RW, RD, RH, DH = 640, 512, 320, 128
    cx1, cx2, cy2 = bx1 + 32, bx1 + 32 + RW, by2 - 32
    cy1 = cy2 - RD
    d0 = cy1 + 96
    d1 = d0 + 64
    # the old block: solid but for the room; the north wall over the room cut round the mass
    for box in ((bx1, by1, 0, bx2, cy1, RH), (cx2, cy1, 0, bx2, by2, RH), (bx1, cy1, 0, cx1, d0, RH), (bx1, d1, 0, cx1, by2, RH),
                (bx1, d0, DH, cx1, d1, RH), (bx1, by1, RH, bx2, by2, bh)):
        sink.boxes.append((box, mat, mat, ceiling))
    U, wd = (1, -k), (112 if k == 2 else 120)
    probe = Frame((0, 0, 0), U)
    ln = probe.n(r.choice((512, 576, 640)), even=True)
    fn = (cx1 + 160 + (64 if k == 1 else 0), by2 - 128)
    fr = Frame((fn[0] - ln, fn[1] + k * ln, 0), U)
    Hm = r.choice((768, 896))
    p = Piece(fr, (ln, wd), Hm, r, sink)
    foot = [fr.w(c)[:2] for c in ((0, 0, 0), (ln, 0, 0), (ln, -wd, 0), (0, -wd, 0))]
    if sum(foot[i - 1][0] * foot[i][1] - foot[i][0] * foot[i - 1][1] for i in range(4)) < 0:
        foot.reverse()
    for piece in minus((cx1, cy2, cx2, by2), foot):
        sink.old.append([([(x, y, 0) for x, y in piece], mat), ([(x, y, RH) for x, y in piece], mat)] +
                        [([(piece[i][0], piece[i][1], 0), (piece[i - 1][0], piece[i - 1][1], 0), (piece[i - 1][0], piece[i - 1][1], RH),
                           (piece[i][0], piece[i][1], RH)], mat) for i in range(len(piece))])
    # the mass: courses, a head leaning over toward the block, a stack on the face to the street, ribs
    q = p.q
    (s0, s1), jj = p.zone(0, ln - q(160), "lo")
    p.mass(rect(0, -wd, ln, 0), 0, Hm - 128, (jj,))
    p.course2(0, -wd, Hm - 128, Hm, 0, ln, (q(32), q(40), q(16)))
    p.add(ext([(ln, Hm - 128), (ln, Hm), (ln + q(r.choice(LEANS)), Hm)], 1, -wd, 0, p.mm))
    p.stack(("v", 0, 1), s0, s1, r.choice((64, 128)), Hm - 192, r.randint(4, 5))
    p.ribs(("v", 0, 1), s1 + q(48), ln - q(96), 448, Hm - 192, 16, 8, "pair", 256)
    p.tabs(("u", 0, -1), -wd + q(24), -q(24), 256)
    p.ribs(("v", -wd, -1), q(64), ln - q(128), 128, Hm - 256, 32, 48, None, 256)
    kind = TP.pick(r, ("flat",))
    p.top = TP.crown(p, kind, 0, ln, -wd, 0, Hm, r, across="u" if kind == "shed" else "v")
    # inside: plates flush and square on the old walls (the Nexus's way), one run 16 off on brackets, a cold panel
    rm = Piece(Frame((cx1, cy1, 0)), (RW, RD), RH, r, sink)
    rm.tiles(("v", 0, -1), 48, RW - 64, 0, 224, 0, rm.thick[0] if rm.thick[0] > 2 else 4, light=True)
    rm.ribs(("u", RW, -1), -RD + 64, -64, 32, RH - 48, 32, 8, "pair", 192)
    rm.fbox(("u", RW, -1), -RD + 48, -48, 0, 32, 0, 8, rm.plate)
    rm.fbox(("u", 0, 1), -RD + 48, -RD + 96 + 160, 176, 256, 16, 20, rm.plate)
    for v in (-RD + 80, -RD + 208):
        rm.fbox(("u", 0, 1), v, v + 16, 200, 232, 0, 16, rm.mm)
    sink.lights.append(((cx1 + RW // 2, cy1 + RD // 2, RH - 48), "255 224 144 120"))
    r.randint(14, 40), r.randint(-40, 40), r.randint(-15, 15)     # (the tilted creeping wall's draws: it floated, it went)
    sink.lamps.append((fr.w((s0 + q(32), q(64) + 1, 352)), (fr.yaw() + 15) % 360 // 15 * 15, 30))
    return {"door": (d0, d1, DH), "room": (cx1, cy1, cx2, cy2, RH), "turn": "1 in 2" if k == 2 else "45", "mass": foot, "top": p.top}


def perimeter(sink, r, x0, x1, y0, H=768, outer=-1):
    """A straight Combine wall from x0 to x1 along the line y0: a template to repeat round the city's edge (the owner,
    23 November: "a simple combine exterior wall for the city, to see from the outside ... simple combine metal and maybe
    simple designs on it ... just not a rectangle bare wall"). wall_chain's runs laid straight, 768 to 1024 long, each
    drawn afresh (so no two alike: the ribs on a 256 rhythm broken by pairs, the stepped plates, the band at the foot,
    fins on two heads in three), a pier with its Combine lamp over every joint and at both ends. outer: the side its
    battered, ribbed face looks to (-1 south, +1 north)."""
    runs, x = [], x0
    while x1 - x >= 512:
        k = min(r.choice((768, 896, 1024)), x1 - x)
        if x1 - x - k < 512:
            k = x1 - x                       # (no stub at the end: the last run takes what is left)
        fr = Frame((x, y0, 0), (1, 0)) if outer < 0 else Frame((x + k, y0, 0), (-1, 0))
        runs.append((Piece(fr, (k, 0), H, r, sink), k))
        x += k
    for i, (p, k) in enumerate(runs):
        T, Le, Pl = run(p, k, H, r)
        pier(p, 0, H, r, T, Le, Pl, lamp=i % 2 == 0)
        if i == len(runs) - 1:
            pier(p, k, H, r, T, Le, Pl, lamp=True)
    return {"runs": [(p.fr.o, k) for p, k in runs], "tops": [p.top for p, _ in runs]}

