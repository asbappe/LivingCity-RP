"""Wall elevations as depth rasters: left-right symmetry of each wall's relief, overhang, and whether the two sides
of a passage match."""
import math
from collections import defaultdict

import numpy as np

RES = 8.0


def _uf(n):
    p = list(range(n))

    def f(x):
        while p[x] != x:
            p[x] = p[p[x]]
            x = p[x]
        return x

    def u(a, b):
        ra, rb = f(a), f(b)
        if ra != rb:
            p[ra] = rb
    return f, u


def group_walls(faces):
    by = defaultdict(list)
    for f in faces:
        n = f["n"]
        if abs(n[2]) >= 0.6:
            continue
        yaw = math.degrees(math.atan2(n[1], n[0])) % 360
        by[int(round(yaw)) % 360].append(f)
    walls = []
    for yaw, fs in by.items():
        th = math.radians(yaw)
        nh = np.array([math.cos(th), math.sin(th), 0.0])
        t = np.array([-math.sin(th), math.cos(th), 0.0])     # cross(z, nh)
        rec = []
        for f in fs:
            P = f["pts"]
            u = P @ t
            z = P[:, 2]
            s = P @ nh
            rec.append((u.min(), u.max(), z.min(), z.max(), s.mean(), f))
        k = len(rec)
        fnd, un = _uf(k)
        order = sorted(range(k), key=lambda i: rec[i][4])
        for ii in range(k):
            i = order[ii]
            for jj in range(ii + 1, k):
                j = order[jj]
                if rec[j][4] - rec[i][4] > 64:
                    break
                a, b = rec[i], rec[j]
                if a[0] - 8 <= b[1] and b[0] - 8 <= a[1] and a[2] - 8 <= b[3] and b[2] - 8 <= a[3]:
                    un(i, j)
        g = defaultdict(list)
        for i in range(k):
            g[fnd(i)].append(rec[i])
        for rs in g.values():
            area = sum(r[5]["area"] for r in rs)
            u0 = min(r[0] for r in rs)
            u1 = max(r[1] for r in rs)
            z0 = min(r[2] for r in rs)
            z1 = max(r[3] for r in rs)
            if area < 16384 or u1 - u0 < 192 or z1 - z0 < 96 or (u1 - u0) * (z1 - z0) > 4096 * 4096:
                continue
            walls.append({"yaw": yaw, "nh": nh, "t": t, "u0": u0, "u1": u1, "z0": z0, "z1": z1, "faces": [r[5] for r in rs], "area": area})
    return walls


def raster(w):
    nu = int(math.ceil((w["u1"] - w["u0"]) / RES))
    nz = int(math.ceil((w["z1"] - w["z0"]) / RES))
    D = np.full((nu, nz), -np.inf)
    nh, t = w["nh"], w["t"]
    ez = np.array([0, 0, 1.0])
    for f in w["faces"]:
        P = f["pts"]
        U = P @ t
        Z = P[:, 2]
        i0 = max(0, int((U.min() - w["u0"]) // RES))
        i1 = min(nu - 1, int((U.max() - w["u0"]) // RES))
        j0 = max(0, int((Z.min() - w["z0"]) // RES))
        j1 = min(nz - 1, int((Z.max() - w["z0"]) // RES))
        if i1 < i0 or j1 < j0:
            continue
        gu = w["u0"] + (np.arange(i0, i1 + 1) + 0.5) * RES
        gz = w["z0"] + (np.arange(j0, j1 + 1) + 0.5) * RES
        GU, GZ = np.meshgrid(gu, gz, indexing="ij")
        inside = np.ones(GU.shape, bool)
        m = len(U)
        sgn = None
        area2 = sum(U[i] * Z[(i + 1) % m] - U[(i + 1) % m] * Z[i] for i in range(m))
        sgn = 1.0 if area2 >= 0 else -1.0
        for i in range(m):
            a = (U[i], Z[i])
            b = (U[(i + 1) % m], Z[(i + 1) % m])
            cr = (b[0] - a[0]) * (GZ - a[1]) - (b[1] - a[1]) * (GU - a[0])
            inside &= sgn * cr >= -1e-6
        if not inside.any():
            continue
        n = f["n"]
        den = float(n @ nh)
        if abs(den) < 1e-3:
            continue
        S = (f["d"] - (GU * float(n @ t) + GZ * float(n @ ez))) / den
        sub = D[i0:i1 + 1, j0:j1 + 1]
        upd = np.where(inside, np.maximum(sub, S), sub)
        D[i0:i1 + 1, j0:j1 + 1] = upd
    return D


def elevation_symmetry(D):
    pres = np.isfinite(D)
    if pres.sum() < 50:
        return None
    base = D[pres].min()
    rel = np.where(pres, D - base, np.nan)
    nu = D.shape[0]
    best = (-1, 0)
    for c2 in range(int(nu * 0.5), int(nu * 1.5) + 1):     # mirror line at c2/2 cells (half-cell steps), middle half
        k = min(c2 // 2, nu - (c2 + 1) // 2)
        if k < 4:
            continue
        lo = np.arange(0, nu)
        mi = c2 - 1 - lo
        ok = (mi >= 0) & (mi < nu) & (lo < mi)
        if ok.sum() < 4:
            continue
        A = rel[lo[ok]]
        B = rel[mi[ok]]
        pa = np.isfinite(A)
        pb = np.isfinite(B)
        any_ = pa | pb
        both = pa & pb
        if any_.sum() == 0:
            continue
        match = both & (np.abs(np.nan_to_num(A) - np.nan_to_num(B)) <= 1.5)
        sc = match.sum() / any_.sum()
        if sc > best[0]:
            best = (sc, c2)
    return round(float(best[0]), 3)


def profile(D):
    pres = np.isfinite(D)
    base = D[pres].min()
    rel = np.where(pres, D - base, np.nan)
    nz = D.shape[1]
    q = max(1, nz // 4)
    out = []
    for i in range(D.shape[0]):
        col = rel[i]
        if np.isfinite(col).sum() < 0.6 * nz:
            continue
        b = col[:q]
        tp = col[-q:]
        if np.isfinite(b).sum() == 0 or np.isfinite(tp).sum() == 0:
            continue
        out.append(float(np.nanmean(tp) - np.nanmean(b)))
    levels = np.unique(np.round(rel[pres] / 4.0))
    return out, len(levels)


def pair_match(wa, Da, wb, Db):
    """wa faces nh, wb faces -nh; compare relief of the two sides of the passage between them."""
    # world u for b is -u along a's t
    ua0, ua1 = wa["u0"], wa["u1"]
    ub0, ub1 = -wb["u1"], -wb["u0"]
    u0, u1 = max(ua0, ub0), min(ua1, ub1)
    z0, z1 = max(wa["z0"], wb["z0"]), min(wa["z1"], wb["z1"])
    if u1 - u0 < 128 or z1 - z0 < 96:
        return None
    gu = np.arange(u0 + RES / 2, u1, RES)
    gz = np.arange(z0 + RES / 2, z1, RES)
    ia = ((gu - ua0) // RES).astype(int)
    ib = ((-gu - wb["u0"]) // RES).astype(int)
    ja = ((gz - wa["z0"]) // RES).astype(int)
    jb = ((gz - wb["z0"]) // RES).astype(int)
    ok_a = (ia >= 0) & (ia < Da.shape[0])
    ok_b = (ib >= 0) & (ib < Db.shape[0])
    okz = (ja >= 0) & (ja < Da.shape[1]) & (jb >= 0) & (jb < Db.shape[1])
    ia, ib = ia[ok_a & ok_b], ib[ok_a & ok_b]
    ja, jb = ja[okz], jb[okz]
    if len(ia) < 8 or len(ja) < 8:
        return None
    A = Da[np.ix_(ia, ja)]
    B = Db[np.ix_(ib, jb)]
    pa, pb = np.isfinite(A), np.isfinite(B)
    if pa.sum() < 20 or pb.sum() < 20:
        return None
    ra = A - A[pa].min()
    rb = B - B[pb].min()
    any_ = pa | pb
    both = pa & pb
    diff = np.where(both, np.nan_to_num(ra, neginf=0.0) - np.nan_to_num(rb, neginf=0.0), 99.0)
    match = both & (np.abs(diff) <= 2)
    return float(match.sum() / any_.sum())


def walls_block(faces):
    ws = group_walls(faces)
    syms, prof, levels, areas = [], [], [], []
    R = []
    for w in ws:
        D = raster(w)
        R.append(D)
        s = elevation_symmetry(D)
        if s is None:
            continue
        p, lv = profile(D)
        syms.append((s, w["area"], lv))
        prof += p
        levels.append(lv)
    # passages: walls facing each other 64..640 apart
    pairs = []
    for i, wa in enumerate(ws):
        Da = R[i]
        if not np.isfinite(Da).any():
            continue
        for j, wb in enumerate(ws):
            if j <= i or (wb["yaw"] - wa["yaw"]) % 360 != 180:
                continue
            Db = R[j]
            if not np.isfinite(Db).any():
                continue
            sa = float(np.max(Da[np.isfinite(Da)]))
            sb = float(np.max(Db[np.isfinite(Db)]))
            gap = -sb - sa
            if not (64 <= gap <= 640):
                continue
            m = pair_match(wa, Da, wb, Db)
            if m is not None:
                pairs.append((m, gap))
    if not syms:
        return None
    S = np.array([s for s, _, _ in syms])
    W = np.array([a for _, a, _ in syms])
    Sa = np.array([s for s, _, lv in syms if lv >= 3])
    P = np.array(prof) if prof else np.array([0.0])
    out = {"walls": len(S), "sym_pct": [round(float(np.percentile(S, q)), 3) for q in (10, 25, 50, 75, 90)],
           "sym_area_weighted_mean": round(float((S * W).sum() / W.sum()), 3),
           "sym_ge_0.9": round(float((S >= 0.9).mean()), 3), "sym_lt_0.6": round(float((S < 0.6).mean()), 3),
           "articulated(3+ levels)": {"n": int(len(Sa)), "sym_pct": [round(float(np.percentile(Sa, q)), 3) for q in (10, 25, 50, 75, 90)] if len(Sa) else None,
                                      "sym_ge_0.9": round(float((Sa >= 0.9).mean()), 3) if len(Sa) else None,
                                      "sym_lt_0.6": round(float((Sa < 0.6).mean()), 3) if len(Sa) else None},
           "relief_levels_pct": [int(np.percentile(levels, q)) for q in (10, 25, 50, 75, 90)],
           "top_proud_share(>4)": round(float((P > 4).mean()), 3), "top_back_share(<-4)": round(float((P < -4).mean()), 3),
           "top_minus_bottom_pct": [round(float(np.percentile(P, q))) for q in (10, 25, 50, 75, 90)]}
    if pairs:
        M = np.array([m for m, _ in pairs])
        out["passages"] = {"n": len(M), "sides_match_pct": [round(float(np.percentile(M, q)), 3) for q in (10, 25, 50, 75, 90)],
                           "gap_pct": [round(float(np.percentile([g for _, g in pairs], q))) for q in (10, 50, 90)]}
    return out
