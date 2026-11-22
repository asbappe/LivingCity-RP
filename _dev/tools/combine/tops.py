"""Tops for the Combine generator. The owner, 22 November: "are combine structures as 'flat' on top? From my memory,
they are either curved, like the combine bunkers, or pointed or some weird needless slope", then "please add this
concept to the generator". Measured first (_dev/reference/valve_citadel/notes/architecture_notes.md, "Tops"; lesson
valve-combine-tops): Valve's own Combine brushwork is flat on top three times in four (stepped or with a sloped edge
the rest, never curved or pointed), but two of three of those flat tops have their skyline broken (fins, a creeping
wall hung over the edge, a parapet or a higher step, a generator); the curves and points are Valve's models (the
bunker, the towers, the Citadel). So the masses get the owner's shapes in brushes, lopsided as the Combine is (curved
vaults with their crown off the middle, ridges and points with two different slopes, single slopes that stop short,
steps then a slope), and some tops Valve's broken flat (fins in pairs, a parapet on part of one edge), in the shares
of WEIGHTS. No top is left plain flat.

A top is a line across the piece, (s, height over z) pairs, pushed along the piece: each edge of the line a solid
with upright sides down to z, so every face is flat and every corner whole (on the 4 grid in a square frame; whole
units in a turned one). Roof slopes stay at 45 degrees or less (Valve's measure counts steeper faces as leaning)."""
import math
import random

from .geom import G, TRIM, ext, rib_run

WEIGHTS = (("vault", 3), ("ridge", 3), ("shed", 2), ("steps", 3), ("flat", 2))      # the owner's shapes 11 in 13
SLOPES = ((1, 2), (1, 1), (1, 2), (3, 4), (1, 4))    # rise over run: 26.6 (1 in 2) and 45 lead; 36.9, 14.0 (1 in 4)
ARC = ((46, 22), (44, 28), (46, 34), (34, 46), (22, 44))   # a vault's two springings, degrees off upright (crown off the middle)
STEP = (11.25, 12.0, 13.0)                         # degrees a vault segment turns (Valve's arcs: 11 to 13)


def own(r, *salt):
    """A random stream of the tops' own, drawn from r's state without moving it: the rest of a draw stays as it was."""
    return random.Random("tops %d %r" % (hash(r.getstate()[1]), salt))


def pick(r, avoid=(), kinds=None):
    return own(r, "pick", avoid, kinds).choice([k for k, w in (kinds or WEIGHTS) for _ in range(w) if k not in avoid])


def g(p, x):
    """A plan length (frame units) on the grid: 4 in a square frame, whole units in a turned one."""
    step = G if p.fr.L == 1 else 1
    return int(round(x / float(step))) * step


def z4(x):
    return int(round(x / float(G))) * G


def lift(p, line, a, b, z, mat, axis=0, d=0):
    """The line [(s, h)] as solids pushed along u (axis 0, s across v) or along v (axis 1, s across u) from a to b,
    standing on z; d lifts it (a rib)."""
    for (s0, h0), (s1, h1) in zip(line, line[1:]):
        if s1 == s0:
            continue
        if s1 < s0:
            s0, h0, s1, h1 = s1, h1, s0, h0
        prof = [(s0, z), (s1, z), (s1, z + h1 + d), (s0, z + h0 + d)]
        prof = [q for i, q in enumerate(prof) if q != prof[i - 1]]
        if len(prof) >= 3:
            p.add(ext(prof, axis, a, b, mat))


def clean(p, line, s0, s1):
    """Corners on the grid, s0 and s1 kept, no two corners at one s unless the second is a drop."""
    out, last = [], len(line) - 1
    for i, (s, h) in enumerate(line):
        s = s0 if i == 0 else s1 if i == last else min(s1, max(s0, g(p, s)))
        h = max(0, z4(h))
        if out and s == out[-1][0] and line[i - 1][0] != line[i][0]:
            if i == last:
                out[-1] = (s, h)
            continue
        out.append((s, h))
    return out


def vault(p, s0, s1, r):
    """A segmental vault, its crown off the middle: one springing low on z, the other high on an upright cheek (the
    bunker's way)."""
    L = p.fr.L
    al, be = r.choice(ARC)
    R = (s1 - s0) * L / (math.sin(math.radians(al)) + math.sin(math.radians(be)))
    n = max(4, int(round((al + be) / r.choice(STEP))))
    lo = math.cos(math.radians(max(al, be)))
    line = []
    for i in range(n + 1):
        t = math.radians(-al + i * (al + be) / float(n))
        line.append((s0 + R * (math.sin(t) + math.sin(math.radians(al))) / L, R * (math.cos(t) - lo)))
    return clean(p, line, s0, s1)


def slope_run(p, h, rise, run):
    return h * run / float(rise) / p.fr.L


def ridge(p, s0, s1, r):
    """Two slopes meeting off the middle, each its own ratio; now and then a narrow flat on the crest."""
    (ra, na), (rb, nb) = r.sample(sorted(set(SLOPES)), 2)
    w = (s1 - s0) * p.fr.L
    h = min(z4(w / (na / float(ra) + nb / float(rb))), 384)
    sm = s0 + slope_run(p, h, ra, na)
    flat = g(p, r.choice((0, 0, 16, 32)) / p.fr.L)
    return clean(p, [(s0, 0), (sm, h), (sm + flat, h), (s1, 0)], s0, s1)


def shed(p, s0, s1, r):
    """One slope across, rising to the back or the front; it may stop short and drop (the 'needless' slope)."""
    ra, na = r.choice(((1, 2), (1, 4), (1, 1), (1, 2)))
    w = (s1 - s0) * p.fr.L
    h = min(z4(w * ra / float(na)), 320)
    if r.random() < 0.5:
        sk = s0 + slope_run(p, h, ra, na) * r.choice((0.6, 0.75))
        line = [(s0, 0), (sk, h * 3 // 4), (sk, h // 4 + 32), (s1, h // 4 + 32)]
    else:
        line = [(s0, 0), (s0 + slope_run(p, h, ra, na), h), (s1, h)]
    if r.random() < 0.5:
        line = [(s0 + s1 - s, hh) for s, hh in reversed(line)]
    return clean(p, line, s0, s1)


def steps(p, s0, s1, r, flip=None, k=None):
    """Courses stepped up from one edge (first step 48 to 64 in), then a slope or two to the other."""
    k = g(p, (k or r.choice((48, 56, 64))) / p.fr.L)
    rises = r.choice(((64, 64), (64, 128), (128,), (32, 64)))
    line, s, h = [(s0, rises[0])], s0, rises[0]
    for nxt in rises[1:]:
        s += k
        line += [(s, h), (s, h + nxt)]
        h += nxt
    s += k
    line.append((s, h))
    if s1 - s < 4 * k:
        line.append((s1, h))
    else:
        rest = ridge(p, s, s1, r) if r.random() < 0.5 else [(s, 0), (s1, min(z4((s1 - s) * p.fr.L / 2), 256))]
        line += [(x, hh + h) for x, hh in rest[1:]]
    if (r.random() < 0.5) if flip is None else flip:
        line = [(s0 + s1 - x, hh) for x, hh in reversed(line)]
    return clean(p, line, s0, s1)


def point(p, u0, u1, v0, v1, z, r, mat=None):
    """A lopsided point over a small top: four slopes up to an apex off the middle, the steepest 45."""
    au = u0 + g(p, (u1 - u0) * r.choice((1, 2)) / 3.0)
    av = v0 + g(p, (v1 - v0) * r.choice((1, 2)) / 3.0)
    au, av = min(u1 - 1, max(u0 + 1, au)), min(v1 - 1, max(v0 + 1, av))
    h = z4(min(au - u0, u1 - au, av - v0, v1 - av) * p.fr.L)
    if h < 16:
        return False
    m, top = mat or p.mm, (au, av, z + h)
    base = [(u0, v0, z), (u1, v0, z), (u1, v1, z), (u0, v1, z)]
    p.add([(base, m)] + [([base[i], base[i - 1], top], m) for i in range(4)])
    return True


def fins(p, u0, u1, v0, v1, z, r, back=True):
    """Fins standing on a top in pairs or on a beat (rib_run), 16 thick, their tops slanting, along its back edge."""
    r, w, n = own(r, "fins", u0, v0, z), max(1, g(p, 16 / p.fr.L)), 0
    d = min(v1 - v0, max(2, g(p, r.choice((96, 128, 160)) / p.fr.L)))
    va, vb = (v0, v0 + d) if back else (v1 - d, v1)
    hi, lo = r.choice(((160, 96), (192, 96), (128, 96), (224, 128)))
    lo = max(lo, hi - z4(d * p.fr.L))                 # the slant 45 or less
    if not back:
        hi, lo = lo, hi
    for x in rib_run(u0 + max(1, g(p, 32 / p.fr.L)), u1 - w, w, r, r.choice(("pair", "even", "free")), max(2, g(p, 128 / p.fr.L))):
        p.add(ext([(va, z), (vb, z), (vb, z + lo), (va, z + hi)], 0, x, x + w, TRIM))
        n += 1
    return n


def parapet(p, u0, u1, v0, v1, z, r):
    """A course 32 to 64 high on part of one edge (one of the steps Valve's tops meet their walls with)."""
    a = u0 + g(p, (u1 - u0) * r.choice((0, 1, 2)) / 5.0)
    b = min(u1, a + g(p, (u1 - u0) * r.choice((2, 3)) / 5.0))
    t = max(1, g(p, r.choice((16, 32)) / p.fr.L))
    if b - a >= 2:
        p.add(ext(rect_vz(v1 - t, v1, z, z + r.choice((32, 48, 64))), 0, a, b, p.mm))


def rect_vz(s0, s1, z0, z1):
    return [(s0, z0), (s1, z0), (s1, z1), (s0, z1)]


def crown(p, kind, u0, u1, v0, v1, z, r, across=None, ribs=True, over=0):
    """A top of kind over u0..u1, v0..v1 standing on z (frame units across, world up): its line across the shorter
    side unless across ('u' or 'v') says; ribs across it on a 256 beat broken by pairs (Valve's rhythm), lifted 8;
    over: how far its low edge stands out past the face (an overhang, as one in eight of Valve's tops). Returns kind."""
    r = own(r, kind, u0, v0, z)
    keep, p.r = p.r, r
    try:
        return _crown(p, kind, u0, u1, v0, v1, z, r, across, ribs, over)
    finally:
        p.r = keep


def _crown(p, kind, u0, u1, v0, v1, z, r, across, ribs, over):
    if kind == "flat":
        n = fins(p, u0, u1, v0, v1, z, r)
        parapet(p, u0, u1, v0, v1, z, r)
        return "flat with %d fins" % n
    if kind == "point":
        return "point" if point(p, u0, u1, v0, v1, z, r) else crown(p, "ridge", u0, u1, v0, v1, z, r)
    across = across or ("v" if (v1 - v0) * 1.0 <= (u1 - u0) else "u")
    s0, s1, a, b, axis = (v0, v1 + over, u0, u1, 0) if across == "v" else (u0, u1, v0, v1 + over, 1)
    make = {"vault": vault, "ridge": ridge, "shed": shed, "steps": steps}[kind]
    line = make(p, s0, s1, r)
    w = max(1, g(p, r.choice((16, 32)) / p.fr.L))
    cuts = [a, b]
    if kind == "steps":
        # in two parts with different steps (a stair run end to end is its own mirror), the joint off the middle
        m = a + g(p, (b - a) * r.choice((5, 6, 10, 11)) / 16.0)
        flip, ks = r.random() < 0.5, r.sample((48, 56, 64), 2)
        for (c0, c1), k in zip(((a, m), (m, b)), ks):
            line = steps(p, s0, s1, r, flip, k)
            lift(p, line, c0, c1, z, p.mm, axis)
        ribs = False
        cuts = []
    elif ribs and (b - a) * p.fr.L >= 384:
        xs = rib_run(a + max(2, g(p, 64 / p.fr.L)), b - max(2, g(p, 64 / p.fr.L)) - w, w, r, None, max(4, g(p, 256 / p.fr.L)))
        cuts = sorted({a, b} | {c for x in xs for c in (x, x + w)})
        xs = set(xs)
    else:
        xs = set()
    for c0, c1 in zip(cuts, cuts[1:]):
        lift(p, line, c0, c1, z, TRIM if c0 in xs else p.mm, axis, 8 if c0 in xs else 0)
    # small plates straight across the joint under the end faces, where the crown stands 48 or more over z
    hs = [x for x, hh in line if hh >= 48]
    if hs and max(hs) - min(hs) >= 4:
        ends = ((("v", b, 1), ("v", a, -1)) if axis == 1 else (("u", b, 1), ("u", a, -1)))
        lo, hi = min(hs), max(hs)
        for e in ends[1 if over > 0 else 0:]:                 # over part of the end only (a full row is its own mirror)
            cut = lo + g(p, (hi - lo) * r.choice((9, 11)) / 16.0)
            p.tabs(e, *((lo, cut) if r.random() < 0.5 else (cut, hi)), z)
    return kind
