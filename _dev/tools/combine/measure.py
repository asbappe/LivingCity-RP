"""The study's numbers (_dev/reference/valve_citadel/notes/architecture_notes.md), on any VMF or on a structure
before it is kept: off-axis, leaning and turned share, plates, layers and their steps, the wall mirror test and the
passage test (the study's walls.py), small against big, texture scale, light panels. Maps are read as text only."""
import math
import os
import sys
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path[:0] = [os.path.join(HERE, "..", "reference", "valve_citadel", "arch_scripts")]
import arch_lib as AL  # noqa: E402  (the study's VMF reader)
import walls as WL  # noqa: E402  (the study's wall mirror test)


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


def score(solids, old=()):
    """How far a structure is from the study's no-mirror rule: 0 when its biggest wall of 3+ relief levels matches its
    mirror below 0.9, one such wall is below 0.6, and the two sides of every passage match below 0.5; and the walls and
    passages measured."""
    B = as_brushes(solids) + as_brushes(old, "world")
    seen(B)
    walls, pas = mirror(combine_faces(B))
    art = [(a, s) for s, lv, a in walls if lv >= 3]
    bad = 2 * (bool(art) and max(art)[1] >= 0.9) + (bool(art) and min(s for _, s in art) >= 0.6) + 2 * sum(m >= 0.5 for m in pas)
    return bad, walls, pas
