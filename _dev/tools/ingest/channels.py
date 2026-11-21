"""Living City map ingestion: canal-style channel profiles (the canal helpers' profile.py, feat.py and stats.py).

    run(m, s, nodes) -> dict for measure.json["sections"]["channels"]

Cuts are taken at water (every 448 along each water brush) and at AI nodes, 448 apart. At each: the floor, the
water over it, the shortest of 16 chords at 96 over the floor (that is "across"), then a true slice across,
4 units fine, 1024 each way and 1216 up. Each row of the slice gives the free run either side of the middle;
the rim is where a side opens out for good. A cut is "open" (sky over it, long both ways, both rims at 96 or
more), a "tunnel" (a roof within 640), a "room" (no chord over 1200) or "other".
"""
import math

import numpy as np

from .common import C, dist, med, rnd


def water_top(s, x, y, z0):
    w = np.where(s.code == 2)[0]
    if not len(w):
        return None
    lo, hi = s.lo[w], s.hi[w]
    ok = (lo[:, 0] <= x) & (hi[:, 0] >= x) & (lo[:, 1] <= y) & (hi[:, 1] >= y) & (hi[:, 2] > z0 + 1) & (lo[:, 2] <= z0 + 16)
    return float(hi[ok, 2].max()) if ok.any() else None


def candidates(m, s, N, spacing=448.0):
    pts = []
    for i in np.where(s.code == 2)[0]:
        lo, hi = s.lo[i], s.hi[i]
        dx, dy = hi[0] - lo[0], hi[1] - lo[1]
        if dx >= dy:
            n = max(1, int(dx // spacing))
            pts += [(lo[0] + (k + 0.5) * dx / n, (lo[1] + hi[1]) / 2, hi[2], "water") for k in range(n)]
        else:
            n = max(1, int(dy // spacing))
            pts += [((lo[0] + hi[0]) / 2, lo[1] + (k + 0.5) * dy / n, hi[2], "water") for k in range(n)]
    pts += [(p[0], p[1], p[2] + 8, "node") for p in N]
    chosen = []
    for p in pts:
        if all((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 > spacing ** 2 or abs(p[2] - q[2]) > 160 for q in chosen):
            chosen.append(p)
    return chosen


def measure(s, x, y, z, src):
    z0, _ = s.floor(x, y, z + 24, 1600)
    if z0 is None:
        return None
    wz = water_top(s, x, y, z0)
    zref = (wz if wz else z0) + 96
    chords = []
    for k in range(16):
        a = math.pi * k / 16
        d = np.array([math.cos(a), math.sin(a), 0.0])
        f = s.ray((x, y, zref), d, 4000)[0]
        b = s.ray((x, y, zref), -d, 4000)[0]
        f, b = (4000.0 if f is None else f), (4000.0 if b is None else b)
        chords.append((f + b, a, f, b))
    mn, mx = min(chords), max(chords)
    if mn[0] <= 0:
        return None
    a = mn[1]
    ux, uy = math.cos(a), math.sin(a)
    off = (mn[2] - mn[3]) / 2.0
    cx, cy = x + ux * off, y + uy * off
    z0c, _ = s.floor(cx, cy, zref, 1600)
    if z0c is not None and abs(z0c - z0) < 48:
        z0 = z0c
        wz = water_top(s, cx, cy, z0)
    else:
        cx, cy = x, y
    step = 4
    ss, zs, G = s.slice(cx, cy, ux, uy, 1024, z0 - 64, z0 + 1216, step)
    c0 = len(ss) // 2
    rows, ceiling, ceil_kind = [], None, None
    for i, zz in enumerate(zs):
        if zz <= z0:
            continue
        row = G[i]
        free = (row == 0) | (row == 2)
        if not free[c0]:
            ceiling, ceil_kind = zz - z0, ("sky" if row[c0] == 3 else "solid")
            break
        l = c0
        while l - 1 >= 0 and free[l - 1]:
            l -= 1
        r = c0
        while r + 1 < len(row) and free[r + 1]:
            r += 1
        rows.append((rnd(zz - z0), (c0 - l) * step, (r - c0) * step))
    if not rows:
        return None
    return {"src": src, "x": rnd(cx), "y": rnd(cy), "z0": rnd(z0), "axis": (rnd(math.degrees(a)) + 90) % 180,
            "chord_min": rnd(mn[0]), "chord_max": rnd(mx[0]), "water": rnd(wz - z0) if wz else 0,
            "ceiling": rnd(ceiling) if ceiling else None, "ceil_kind": ceil_kind, "rows": rows}


def rdp(pts, eps):
    if len(pts) < 3:
        return pts
    a, b = np.array(pts[0], float), np.array(pts[-1], float)
    ab = b - a
    L = np.linalg.norm(ab)
    best, bi = 0.0, 0
    for i in range(1, len(pts) - 1):
        q = np.array(pts[i], float) - a
        d = abs(ab[0] * q[1] - ab[1] * q[0]) / L if L else np.linalg.norm(q)
        if d > best:
            best, bi = d, i
    if best > eps:
        return rdp(pts[:bi + 1], eps)[:-1] + rdp(pts[bi:], eps)
    return [pts[0], pts[-1]]


def features(p):
    rows = p["rows"]
    rim = {}
    for k in (1, 2):
        prev = None
        for r in rows:
            if prev is not None and (r[k] - prev > 240 or r[k] >= 1000):
                rim[k] = r[0] - 4
                break
            prev = r[k]
    lines = {}
    for k in (1, 2):
        topz = rim.get(k, rows[-1][0])
        pts = [(r[k], r[0]) for r in rows if r[0] <= topz]
        out = [pts[0]]
        for q in pts[1:]:
            if q[0] != out[-1][0] and abs(q[0] - out[-1][0]) > 8:
                out.append((out[-1][0], q[1] - 4))
            out.append(q)
        lines[k] = rdp(out, 6)
    return {"floor_w": rows[0][1] + rows[0][2], "rim": rim, "lines": lines}


def kind(p, f):
    open_ = p["ceiling"] is None or p["ceil_kind"] == "sky"
    if p["chord_max"] < 1200:
        return "room"
    if open_ and len(f["rim"]) == 2 and min(f["rim"].values()) >= 96:
        return "open"
    if not open_ and p["ceiling"] <= 640:
        return "tunnel"
    return "other"


def side_feats(line):
    ledge = bank = None
    for (w1, h1), (w2, h2) in zip(line, line[1:]):
        dw, dh = w2 - w1, h2 - h1
        if h1 < 6 and dh < 12:
            continue
        ang = math.degrees(math.atan2(dh, abs(dw))) if (dw or dh) else 90
        if dw >= 24 and dh <= 8 and ledge is None and h1 >= 12:
            ledge = (rnd(h1), rnd(dw))
            break
        if dh >= 24 and 12 <= ang <= 78 and dw > 0 and bank is None:
            bank = (rnd(ang), rnd(dw), rnd(dh))
    return ledge, bank


def run(m, s, N, limit=220):
    cuts = []
    for (x, y, z, src) in candidates(m, s, N)[:limit]:
        p = measure(s, x, y, z, src)
        if p:
            cuts.append(p)
    R = {"cuts": len(cuts), "from_water": sum(p["src"] == "water" for p in cuts)}
    kinds = C()
    acc = {k: [] for k in ("floor_w", "w64", "w128", "rim_lo", "rim_hi", "ledge_h", "ledge_w", "bank", "bank_h", "water",
                           "t_floor", "t_max", "t_crown", "t_water")}
    ledged, examples = [], {"open": [], "tunnel": []}
    for p in cuts:
        f = features(p)
        k = kind(p, f)
        kinds[k] += 1
        if k == "open":
            w = {r[0]: r[1] + r[2] for r in p["rows"]}
            acc["floor_w"].append(f["floor_w"])
            acc["w64"].append(w.get(64))
            acc["w128"].append(w.get(128))
            acc["rim_lo"].append(min(f["rim"].values()))
            acc["rim_hi"].append(max(f["rim"].values()))
            n = 0
            for side in (1, 2):
                L, B = side_feats(f["lines"][side])
                if L:
                    acc["ledge_h"].append(L[0])
                    acc["ledge_w"].append(L[1])
                    n += 1
                if B:
                    acc["bank"].append(B[0])
                    acc["bank_h"].append(B[2])
            ledged.append(n)
            if p["water"]:
                acc["water"].append(p["water"])
            examples["open"].append(p)
        elif k == "tunnel":
            widths = [r[1] + r[2] for r in p["rows"]]
            acc["t_floor"].append(widths[0])
            acc["t_max"].append(max(widths))
            acc["t_crown"].append(p["ceiling"])
            if p["water"]:
                acc["t_water"].append(p["water"])
            examples["tunnel"].append(p)
    R["kinds"] = dict(kinds)
    steps = {"floor_w": 32, "w64": 32, "w128": 32, "rim_lo": 16, "rim_hi": 16, "ledge_h": 16, "ledge_w": 8, "bank": 5,
             "bank_h": 16, "water": 4, "t_floor": 32, "t_max": 32, "t_crown": 16, "t_water": 4}
    R["open"] = {k: dist(acc[k], steps[k], 10) for k in ("floor_w", "w64", "w128", "rim_lo", "rim_hi", "ledge_h", "ledge_w", "bank", "bank_h", "water")}
    R["open"]["sides_with_ledge"] = dict(C(ledged))
    R["tunnel"] = {k[2:]: dist(acc[k], steps[k], 10) for k in ("t_floor", "t_max", "t_crown", "t_water")}
    R["examples"] = {}
    for k, ps in examples.items():
        ps = sorted(ps, key=lambda p: (-(p["src"] == "water"), abs((p["rows"][0][1] + p["rows"][0][2]) - (med([q["rows"][0][1] + q["rows"][0][2] for q in ps]) or 0))))
        R["examples"][k] = [{q: p[q] for q in ("x", "y", "z0", "axis", "water", "ceiling", "chord_min")} for p in ps[:3]]
    return R
