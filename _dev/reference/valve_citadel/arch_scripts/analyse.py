"""Measure the Combine's own architecture in one map (and the old buildings beside it). Writes results/NAME.json."""
import json
import math
import os
import sys
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import arch_lib as A  # noqa: E402
import walls as WL  # noqa: E402

OUT = os.path.join(HERE, "results")
os.makedirs(OUT, exist_ok=True)


def pct(xs, ps=(10, 25, 50, 75, 90)):
    if len(xs) == 0:
        return None
    return [round(float(np.percentile(xs, p)), 2) for p in ps]


def wtop(pairs, k=12, nd=0):
    c = Counter()
    for key, w in pairs:
        c[round(key, nd) if nd else int(round(key))] += w
    tot = sum(c.values()) or 1
    return [[kk, round(v / tot, 3)] for kk, v in c.most_common(k)]


FRACS = sorted({(p, q) for q in (1, 2, 3, 4, 5, 6, 8, 16) for p in range(1, 4 * q + 1)}, key=lambda t: (t[1], t[0]))


def ratio_of(deg):
    t = math.tan(math.radians(deg))
    best = None
    for p, q in FRACS:
        a = math.degrees(math.atan2(p, q))
        e = abs(a - deg)
        if best is None or e < best[2] - 1e-9:
            best = (p, q, e)
    g = math.gcd(best[0], best[1])
    return "%d in %d" % (best[0] // g, best[1] // g), best[2]


def face_angles(f):
    n = f["n"]
    off = math.degrees(math.acos(min(1.0, float(np.max(np.abs(n))))))
    nz = float(n[2])
    lean = None
    if abs(nz) < 0.6:
        lean = math.degrees(math.asin(min(1.0, abs(nz))))
    og = None
    if abs(nz) < 0.985:
        yaw = math.degrees(math.atan2(n[1], n[0])) % 90.0
        og = min(yaw, 90 - yaw)
    return off, lean, og, nz


def angles_block(faces):
    tot = sum(f["area"] for f in faces) or 1
    off_area = 0.0
    kinds = Counter()
    leans, ogs, ups = [], [], [0.0, 0.0]
    ratio_hits = Counter()
    ratio_area = 0.0
    lean_area = 0.0
    grid = Counter()
    hs = Counter()
    turn_hits = Counter()
    turn_area = 0.0
    for f in faces:
        off, lean, og, nz = face_angles(f)
        a = f["area"]
        if off > 0.5:
            off_area += a
        L = lean is not None and lean > 0.5
        O = og is not None and og > 0.5
        kinds["lean only" if L and not O else "turn only" if O and not L else "both" if L and O else "square"] += a
        if L:
            leans.append((lean, a))
            zs = f["pts"][:, 2]
            h = float(zs.max() - zs.min())
            if h >= 8:
                hs[(int(round(h)), int(round(h * math.tan(math.radians(lean)))))] += a
            ups[0 if nz > 0 else 1] += a
            r, e = ratio_of(lean)
            lean_area += a
            if e <= 0.35:
                ratio_hits[r] += a
                ratio_area += a
        if O and lean is not None:
            ogs.append((og, a))
            r2, e2 = ratio_of(og)
            turn_area += a
            if e2 <= 0.35:
                turn_hits[r2] += a
        raw = f["raw"]
        if off > 0.5:
            if all(abs(v - round(v)) < 1e-6 for v in raw):
                g = 1
                for s in (16, 8, 4, 2):
                    if all(abs(round(v) % s) == 0 for v in raw):
                        g = s
                        break
                grid[g] += 1
            else:
                grid["frac"] += 1
    return {
        "area": round(tot),
        "off_axis_share": round(off_area / tot, 3),
        "kinds": {k: round(v / tot, 3) for k, v in kinds.items()},
        "lean_top": wtop(leans, 14),
        "lean_facing_up_share": round(ups[0] / (sum(ups) or 1), 3),
        "lean_as_ratio_share": round(ratio_area / (lean_area or 1), 3),
        "lean_ratios_top": [[k, round(v / (lean_area or 1), 3)] for k, v in ratio_hits.most_common(10)],
        "turn_top": wtop(ogs, 14),
        "turn_as_ratio_share": round(sum(turn_hits.values()) / (turn_area or 1), 3),
        "turn_ratios_top": [[k, round(v / (turn_area or 1), 3)] for k, v in turn_hits.most_common(10)],
        "lean_height_setback_top": [[k[0], k[1], round(v / (lean_area or 1), 3)] for k, v in hs.most_common(14)],
        "offaxis_plane_point_grid": dict(grid.most_common()),
    }


def plate_dims(b):
    V = b["V"]
    N = b["N"]
    w = [(float(np.ptp(V @ n)), i) for i, n in enumerate(N)]
    t, it = min(w)
    nt = N[it]
    rest = [(wv, i) for wv, i in w if abs(float(N[i] @ nt)) < 0.15]
    if rest:
        w2, i2 = min(rest)
        n2 = N[i2]
        n3 = np.cross(nt, n2)
        n3 /= np.linalg.norm(n3)
        w3 = float(np.ptp(V @ n3))
    else:
        w2 = w3 = max(wv for wv, _ in w)
    a, c = sorted([w2, w3])
    orient = "lying" if abs(nt[2]) > 0.9 else ("upright" if abs(nt[2]) < 0.05 else "leaning")
    return t, a, c, orient, nt


def union_find(n):
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


def touch(a, b, pad=2.0):
    return all(a[k] - pad <= b[k + 3] and b[k] - pad <= a[k + 3] for k in range(3))


def components(brs, pad=2.0):
    G = A.Grid(brs, 256)
    f, u = union_find(len(brs))
    for i, b in enumerate(brs):
        for j in G.near(b["box"], pad):
            if j > i and touch(b["box"], brs[j]["box"], pad):
                u(i, j)
    comp = defaultdict(list)
    for i in range(len(brs)):
        comp[f(i)].append(i)
    return list(comp.values())


def boxof(brs, ids):
    bx = np.array([brs[i]["box"] for i in ids])
    return np.concatenate([bx[:, :3].min(0), bx[:, 3:].max(0)])


def units_of(brs, maxext=1536, cube=1024):
    out = []
    for comp in components(brs):
        bx = boxof(brs, comp)
        ext = bx[3:] - bx[:3]
        if ext.max() <= maxext:
            out.append((comp, False))
            continue
        cells = defaultdict(list)
        for i in comp:
            c = brs[i]["cen"]
            cells[tuple(((c - bx[:3]) // cube).astype(int))].append(i)
        for ids in cells.values():
            out.append((ids, True))
    return out


def voxels(brs, ids, res=None):
    bx = boxof(brs, ids)
    ext = bx[3:] - bx[:3]
    if res is None:
        res = float(min(32, max(4, ext.max() / 40.0)))
    dims = np.maximum(1, np.ceil(ext / res).astype(int))
    occ = np.zeros(dims, bool)
    o = bx[:3]
    for i in ids:
        b = brs[i]
        lo = np.clip(((np.array(b["box"][:3]) - o) // res).astype(int) - 1, 0, dims - 1)
        hi = np.clip(((np.array(b["box"][3:]) - o) // res).astype(int) + 1, 0, dims - 1)
        gx, gy, gz = np.meshgrid(*[np.arange(lo[k], hi[k] + 1) for k in range(3)], indexing="ij")
        P = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], 1)
        C = o + (P + 0.5) * res
        ins = ((C @ b["N"].T) - (b["D"] + res * 0.5) <= 1e-6).all(1)
        Q = P[ins]
        occ[Q[:, 0], Q[:, 1], Q[:, 2]] = True
    return occ, o, res


def shift_or(a):
    out = a.copy()
    for ax in range(3):
        for sh in (1, -1):
            r = np.roll(a, sh, ax)
            if sh == 1:
                idx = [slice(None)] * 3
                idx[ax] = 0
                r[tuple(idx)] = False
            else:
                idx = [slice(None)] * 3
                idx[ax] = -1
                r[tuple(idx)] = False
            out |= r
    return out


def shell_of(occ):
    inner = occ.copy()
    for ax in range(3):
        for sh in (1, -1):
            r = np.roll(occ, sh, ax)
            idx = [slice(None)] * 3
            idx[ax] = 0 if sh == 1 else -1
            r[tuple(idx)] = False
            inner &= r
    return occ & ~inner


def mirror_score(occ, o, res, thetas=None):
    """Share of the shape's surface (shell voxels) whose mirror image lands on its surface (within one voxel),
    about the best vertical mirror plane through the centroid of the surface."""
    sh = shell_of(occ)
    P = np.argwhere(sh)
    if len(P) < 20:
        return None
    tgt = shift_or(sh)
    C = o + (P + 0.5) * res
    c = C.mean(0)
    dims = np.array(occ.shape)

    def score(th, shift=0.0):
        m = np.array([math.cos(th), math.sin(th), 0.0])
        s = (C - c) @ m - shift
        R = C - 2 * np.outer(s, m)
        I = np.floor((R - o) / res).astype(int)
        ok = ((I >= 0) & (I < dims)).all(1)
        hits = tgt[I[ok, 0], I[ok, 1], I[ok, 2]].sum()
        return hits / len(P)
    if thetas is None:
        thetas = np.radians(np.arange(0, 180, 3))
    best = max((score(t), t) for t in thetas)
    th = best[1]
    for t in np.radians(np.arange(-2.5, 2.6, 0.5)) + th:
        for shf in (-res, -res / 2, 0, res / 2, res):
            v = score(t, shf)
            if v > best[0]:
                best = (v, t)
    return round(float(best[0]), 3), round(math.degrees(best[1]) % 180, 1)


def edge_samples(brs, ids, step):
    pts = []
    for i in ids:
        for f in brs[i]["faces"]:
            if f["mc"] in ("tools", "sky") or not f.get("vis"):
                continue
            P = f["pts"]
            for j in range(len(P)):
                a, b = P[j], P[(j + 1) % len(P)]
                L = float(np.linalg.norm(b - a))
                k = max(2, int(L / step) + 1)
                t = np.linspace(0, 1, k)[:, None]
                pts.append(a + t * (b - a))
    if not pts:
        return None
    return bury(brs, ids, np.concatenate(pts))


def bury(brs, ids, Q):
    keep = np.ones(len(Q), bool)
    for i in ids:
        b = brs[i]
        lo = np.array(b["box"][:3]) - 1
        hi = np.array(b["box"][3:]) + 1
        m = (Q >= lo).all(1) & (Q <= hi).all(1)
        if not m.any():
            continue
        idx = np.where(m)[0]
        ins = ((Q[idx] @ b["N"].T) - b["D"] < -0.5).all(1)
        keep[idx[ins]] = False
    return Q[keep]


def surface_samples(brs, ids, step):
    rng = np.random.RandomState(7)
    pts = []
    for i in ids:
        for f in brs[i]["faces"]:
            if f["mc"] in ("tools", "sky") or not f.get("vis"):
                continue
            P = f["pts"]
            k = max(1, int(f["area"] / (step * step)))
            k = min(k, 4000)
            tri = [(P[0], P[j], P[j + 1]) for j in range(1, len(P) - 1)]
            ar = np.array([0.5 * np.linalg.norm(np.cross(b - a, c - a)) for a, b, c in tri])
            if ar.sum() <= 0:
                continue
            which = rng.choice(len(tri), k, p=ar / ar.sum())
            r1 = np.sqrt(rng.rand(k))
            r2 = rng.rand(k)
            T = np.array(tri)[which]
            Q = (1 - r1)[:, None] * T[:, 0] + (r1 * (1 - r2))[:, None] * T[:, 1] + (r1 * r2)[:, None] * T[:, 2]
            pts.append(Q)
    if not pts:
        return None
    Q = np.concatenate(pts)
    # drop samples buried in another brush of the unit (a plate laid over a wall hides the wall there)
    keep = np.ones(len(Q), bool)
    for i in ids:
        b = brs[i]
        lo = np.array(b["box"][:3]) - 1
        hi = np.array(b["box"][3:]) + 1
        m = (Q >= lo).all(1) & (Q <= hi).all(1)
        if not m.any():
            continue
        idx = np.where(m)[0]
        ins = ((Q[idx] @ b["N"].T) - b["D"] < -0.5).all(1)
        keep[idx[ins]] = False
    return Q[keep]


def keyset(Q, tol, o):
    I = np.floor((Q - o) / tol).astype(np.int64)
    keys = []
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                J = I + np.array([dx, dy, dz])
                keys.append((J[:, 0] * 1000003 + J[:, 1]) * 1000003 + J[:, 2])
    return np.unique(np.concatenate(keys))


def mirror_surface(brs, ids, ext, edges=False):
    tol = float(max(4.0, ext / 128.0))
    Q = edge_samples(brs, ids, tol / 2) if edges else surface_samples(brs, ids, tol)
    if Q is None or len(Q) < 30:
        return None
    if len(Q) > 60000:
        Q = Q[np.random.RandomState(3).choice(len(Q), 60000, replace=False)]
    o = Q.min(0) - 4 * tol
    K = keyset(Q, tol, o)
    c = Q.mean(0)

    def score(th, shift=0.0):
        m = np.array([math.cos(th), math.sin(th), 0.0])
        sd = (Q - c) @ m - shift
        R = Q - 2 * np.outer(sd, m)
        I = np.floor((R - o) / tol).astype(np.int64)
        k = (I[:, 0] * 1000003 + I[:, 1]) * 1000003 + I[:, 2]
        return float(np.isin(k, K).mean())
    best = max((score(t), t) for t in np.radians(np.arange(0, 180, 3)))
    th = best[1]
    for t in np.radians(np.arange(-2.5, 2.6, 0.5)) + th:
        for shf in (-2 * tol, -tol, 0, tol, 2 * tol):
            v = score(t, shf)
            if v > best[0]:
                best = (v, t)
    return round(best[0], 3), round(math.degrees(best[1]) % 180, 1)


def distinct_dirs(faces, tol=2.0):
    dirs = []
    leans = []
    for f in faces:
        off, lean, og, nz = face_angles(f)
        if off <= 1.0:
            continue
        n = f["n"]
        if not any(math.degrees(math.acos(min(1.0, abs(float(n @ d))))) < tol for d in dirs):
            dirs.append(n)
        if lean is not None and lean > 1 and not any(abs(lean - l) < 1.0 for l in leans):
            leans.append(lean)
    return len(dirs), len(leans), sorted(round(l, 1) for l in leans)


def silhouette(occ, res):
    nz = occ.shape[2]
    if nz * res < 128:
        return None
    col = occ.any(2)
    zl = np.where(col, occ.argmax(2), -1)
    zmin = zl[col].min()
    grounded = col & (zl <= zmin + max(1, int(32 // res)))
    hang = col & (zl > zmin + max(2, int(64 // res)))
    reach = 0.0
    if hang.any() and grounded.any():
        G = np.argwhere(grounded)
        H = np.argwhere(hang)
        if len(H) > 4000:
            H = H[np.random.RandomState(1).choice(len(H), 4000, replace=False)]
        dmin = np.full(len(H), 1e9)
        for k in range(0, len(G), 2000):
            g = G[k:k + 2000]
            dd = np.sqrt(((H[:, None, :] - g[None, :, :]) ** 2).sum(2)).min(1)
            dmin = np.minimum(dmin, dd)
        reach = float(dmin.max() * res)
        reach_med = float(np.median(dmin) * res)
    else:
        reach_med = 0.0
    zs = np.where(occ.any((0, 1)))[0]
    third = max(1, len(zs) // 3)
    bot = occ[:, :, zs[:third]].any(2).sum()
    top = occ[:, :, zs[-third:]].any(2).sum()
    return {"hang_share": round(float(hang.sum() / col.sum()), 3), "reach_max": round(reach), "reach_med": round(reach_med),
            "top_over_bottom": round(float(top / max(1, bot)), 2), "height": round(nz * res)}


def rows_of(brs, ids, sigf):
    groups = defaultdict(list)
    for i in ids:
        s = sigf(brs[i])
        if s is not None:
            groups[s].append(i)
    rows = []
    for s, g in groups.items():
        if len(g) < 3:
            continue
        C = np.array([brs[i]["cen"] for i in g])
        # chain by proximity (within 512)
        f, u = union_find(len(g))
        for a in range(len(g)):
            d = np.sqrt(((C - C[a]) ** 2).sum(1))
            for b in np.where(d < 512)[0]:
                if b > a:
                    u(a, b)
        sub = defaultdict(list)
        for a in range(len(g)):
            sub[f(a)].append(a)
        for members in sub.values():
            if len(members) < 3:
                continue
            P = C[members]
            c = P.mean(0)
            U, S, Vt = np.linalg.svd(P - c)
            ax = Vt[0]
            pos = (P - c) @ ax
            resid = np.sqrt(((P - c - np.outer(pos, ax)) ** 2).sum(1)).max()
            if resid > 24:
                continue
            ps = np.sort(pos)
            sp = np.diff(ps)
            if len(sp) < 2 or sp.mean() < 4:
                continue
            rows.append({"n": len(members), "sig": s, "spacing_mean": round(float(sp.mean()), 1),
                         "cv": round(float(sp.std() / sp.mean()), 3), "spacings": [round(float(x)) for x in sp[:12]]})
    return rows


def sig_combine(b):
    t, a, c, orient, nt = plate_dims(b)
    if c < 16:
        return None
    return (round(t / 2) * 2, round(a / 4) * 4, round(c / 4) * 4, orient)


def analyse(name):
    d = A.load(name, A.path_of(name))
    B = d["brushes"]
    ents = d["ents"]
    S = [b for b in B if b["cls"] in A.STRUCT_CLASSES and not b["disp"]]
    comb = [b for b in S if b["kind"] == "combine"]
    old = [b for b in S if b["kind"] == "old"]
    R = {"map": name, "brushes": len(B), "structural": len(S), "combine_brushes": len(comb), "old_brushes": len(old),
         "sky_removed": d["sky_removed"]}
    # 1 census
    area = Counter()
    cmat = Counter()
    scales = Counter()
    for b in S:
        for f in b["faces"]:
            if f.get("vis"):
                area[f["mc"]] += f["area"]
                if f["mc"] == "combine":
                    cmat[f["mat"]] += f["area"]
                    if f["scale"]:
                        scales[round(f["scale"], 3)] += f["area"]
    ta = sum(area.values()) or 1
    R["visible_area_share"] = {k: round(v / ta, 3) for k, v in area.most_common()}
    tc = sum(cmat.values()) or 1
    R["combine_materials"] = [[k, round(v / tc, 3)] for k, v in cmat.most_common(12)]
    ts = sum(scales.values()) or 1
    R["combine_tex_scale"] = [[k, round(v / ts, 3)] for k, v in scales.most_common(5)]
    # 2 angles
    cf = [f for b in comb for f in b["faces"] if f.get("vis") and f["mc"] == "combine"]
    of = [f for b in old for f in b["faces"] if f.get("vis") and f["mc"] == "old"]
    R["angles_combine"] = angles_block(cf)
    R["angles_old"] = angles_block(of) if of else None
    # brush shapes
    nonbox = sum(1 for b in comb if any(np.max(np.abs(n)) < 0.9999 for n in b["N"]))
    R["combine_nonbox_share"] = round(nonbox / (len(comb) or 1), 3)
    R["combine_faces_per_brush"] = wtop([(len(b["faces"]), 1) for b in comb], 8)
    if old:
        R["old_nonbox_share"] = round(sum(1 for b in old if any(np.max(np.abs(n)) < 0.9999 for n in b["N"])) / len(old), 3)
    # 3 plates
    pl = [plate_dims(b) for b in comb]
    T = np.array([p[0] for p in pl]) if pl else np.array([])
    R["plates"] = {
        "thick_pct": pct(T),
        "thick_top": wtop([(round(t), 1) for t in T], 12),
        "plate_share": round(float(np.mean([(p[0] <= 16 and p[1] >= 3 * p[0]) for p in pl])), 3) if pl else None,
        "orient": dict(Counter(p[3] for p in pl)),
        "short_side_pct": pct([p[1] for p in pl if p[0] <= 16]),
        "long_side_pct": pct([p[2] for p in pl if p[0] <= 16]),
        "long_top": wtop([(round(p[2] / 16) * 16, 1) for p in pl if p[0] <= 16], 10),
    }
    if old:
        po = [plate_dims(b) for b in old]
        R["plates_old"] = {"thick_pct": pct([p[0] for p in po]), "plate_share": round(float(np.mean([(p[0] <= 16 and p[1] >= 3 * p[0]) for p in po])), 3)}
    # 5 layers / stacks (wall-ish visible combine faces)
    R["stacks"] = stacks(cf)
    R["walls_combine"] = WL.walls_block(cf)
    R["walls_old"] = WL.walls_block(of) if of else None
    # 6 units: symmetry, distinct angles, silhouettes, repetition, scale
    R["units_combine"] = units_block(comb, "combine")
    R["units_old"] = units_block(old, "old") if len(old) >= 4 else None
    R["units_detail_combine"] = units_block(comb, "combine", by_entity=True)
    R["units_detail_old"] = units_block(old, "old", by_entity=True) if len(old) >= 4 else None
    # 7 rhythm over the whole map
    rc = rows_of(comb, range(len(comb)), sig_combine)
    R["rows_combine"] = rows_summary(rc)
    if old:
        R["rows_old"] = rows_summary(rows_of(old, range(len(old)), sig_combine))
    # 8 scale contrast
    R["scale_combine"] = scale_block(comb)
    if old:
        R["scale_old"] = scale_block(old)
    # 9 meets old
    R["meets_old"] = meets(comb, old) if old else None
    # 10 lights
    R["lights"] = lights(B, S, comb, ents)
    # 11 props
    R["props"] = props(ents)
    # 12 doors
    R["doors"] = doors(B, comb, old, ents)
    json.dump(R, open(os.path.join(OUT, name + ".json"), "w"), indent=1, default=str)
    return R


def stacks(faces):
    walls = [f for f in faces if abs(f["n"][2]) < 0.6]
    keys = defaultdict(list)
    for f in walls:
        n = f["n"]
        yaw = round(math.degrees(math.atan2(n[1], n[0]))) % 360
        pit = round(math.degrees(math.asin(max(-1, min(1, n[2])))))
        keys[(yaw, pit)].append(f)
    layers, steps, depth, gaps, widths = [], [], [], [], []
    for (yaw, pit), fs in keys.items():
        n = fs[0]["n"]
        a = np.array([0, 0, 1.0]) if abs(n[2]) < 0.9 else np.array([1.0, 0, 0])
        U = np.cross(a, n)
        U /= np.linalg.norm(U)
        W = np.cross(n, U)
        rect = []
        for f in fs:
            u = f["pts"] @ U
            v = f["pts"] @ W
            rect.append((u.min(), u.max(), v.min(), v.max(), f["d"], f["area"]))
        R = np.array(rect)
        k = len(R)
        fnd, un = union_find(k)
        order = np.argsort(R[:, 4])
        for ii in range(k):
            i = order[ii]
            for jj in range(ii + 1, k):
                j = order[jj]
                if R[j, 4] - R[i, 4] > 64:
                    break
                if R[i, 0] - 8 <= R[j, 1] and R[j, 0] - 8 <= R[i, 1] and R[i, 2] - 8 <= R[j, 3] and R[j, 2] - 8 <= R[i, 3]:
                    un(i, j)
        grp = defaultdict(list)
        for i in range(k):
            grp[fnd(i)].append(i)
        for g in grp.values():
            ar = R[g, 5].sum()
            if ar < 16384:
                continue
            lv = np.unique(np.round(R[g, 4]))
            layers.append((len(lv), ar))
            depth.append((float(lv.max() - lv.min()), ar))
            for s in np.diff(lv):
                steps.append(float(s))
            # gaps between coplanar faces side by side
            byd = defaultdict(list)
            for i in g:
                byd[round(R[i, 4])].append(R[i])
            for dd, rs in byd.items():
                rs = sorted(rs, key=lambda r: r[0])
                for x in range(len(rs)):
                    widths.append(float(rs[x][1] - rs[x][0]))
                    for y in range(x + 1, min(len(rs), x + 8)):
                        r1, r2 = rs[x], rs[y]
                        vo = min(r1[3], r2[3]) - max(r1[2], r2[2])
                        if vo < 0.5 * min(r1[3] - r1[2], r2[3] - r2[2]):
                            continue
                        gp = r2[0] - r1[1]
                        if -64 <= gp <= 64:
                            gaps.append(float(gp))
    tl = sum(w for _, w in layers) or 1
    return {
        "n": len(layers),
        "layers_by_area": wtop(layers, 10),
        "layers_pct_count": pct([l for l, _ in layers]),
        "step_top": wtop([(s, 1) for s in steps if s > 0.5], 14),
        "step_pct": pct([s for s in steps if s > 0.5]),
        "depth_pct": pct([dp for dp, _ in depth]),
        "coplanar_gap_top": wtop([(g, 1) for g in gaps], 12),
        "face_width_pct": pct(widths),
    }


def units_block(brs, kind, by_entity=False):
    if by_entity:
        g = defaultdict(list)
        for i, b in enumerate(brs):
            if b["cls"] == "func_detail":
                g[b["eid"]].append(i)
        us = [(ids, False) for ids in g.values()]
    else:
        us = units_of(brs)
    sym, sizes, dirs, leans, sil, rep, scl, nb, sym_area = [], [], [], [], [], [], [], [], []
    best = []
    for ids, cut in us:
        if len(ids) < 4:
            continue
        bx = boxof(brs, ids)
        ext = bx[3:] - bx[:3]
        if ext.max() < 96:
            continue
        ms = mirror_surface(brs, ids, float(ext.max()), edges=True)
        if ms is None:
            continue
        ms_area = mirror_surface(brs, ids, float(ext.max()))
        sym_area.append(ms_area[0] if ms_area else ms[0])
        occ, o, res = voxels(brs, ids)
        faces = [f for i in ids for f in brs[i]["faces"] if f.get("vis") and f["mc"] == kind]
        nd, nl, ll = distinct_dirs(faces)
        sigs = Counter(sig_combine(brs[i]) for i in ids)
        repeated = sum(c for s, c in sigs.items() if s is not None and c >= 2) / len(ids)
        mx = [max(np.ptp(brs[i]["V"], 0)) for i in ids]
        sym.append(ms[0])
        sizes.append(float(ext.max()))
        dirs.append(nd)
        leans.append(nl)
        rep.append(repeated)
        scl.append(max(mx) / max(1.0, float(np.median(mx))))
        nb.append(len(ids))
        sl = silhouette(occ, res) if not cut else None
        if sl:
            sil.append(sl)
        best.append({"box": [round(float(v)) for v in bx], "n": len(ids), "sym": ms[0], "sym_area": sym_area[-1], "axis": ms[1], "dirs": nd,
                     "leans": ll[:8], "sil": sl, "cut": cut})
    if not sym:
        return None
    sym = np.array(sym)
    sizes = np.array(sizes)
    out = {"n": len(sym), "brushes_pct": pct(nb), "size_pct": pct(sizes), "sym_pct": pct(sym), "sym_area_pct": pct(sym_area),
           "sym_ge_0.9": round(float((sym >= 0.9).mean()), 3), "sym_lt_0.7": round(float((sym < 0.7).mean()), 3),
           "dirs_pct": pct(dirs), "leans_pct": pct(leans), "repeat_share_pct": pct(rep), "biggest_over_median_pct": pct(scl)}
    big = sizes >= 384
    if big.any():
        out["sym_pct_ge384"] = pct(sym[big])
        out["n_ge384"] = int(big.sum())
    if sil:
        out["silhouette"] = {"n": len(sil), "hang_share_pct": pct([s["hang_share"] for s in sil]),
                             "reach_max_pct": pct([s["reach_max"] for s in sil]),
                             "top_over_bottom_pct": pct([s["top_over_bottom"] for s in sil]),
                             "wider_top_share": round(float(np.mean([s["top_over_bottom"] > 1.1 for s in sil])), 3)}
    best.sort(key=lambda r: -r["n"])
    out["largest"] = best[:8]
    return out


def rows_summary(rows):
    if not rows:
        return None
    cv = [r["cv"] for r in rows]
    return {"rows": len(rows), "cv_pct": pct(cv), "even_share(cv<0.05)": round(float(np.mean([c < 0.05 for c in cv])), 3),
            "uneven_share(cv>0.25)": round(float(np.mean([c > 0.25 for c in cv])), 3),
            "spacing_top": wtop([(r["spacing_mean"], r["n"]) for r in rows], 10),
            "examples": sorted(rows, key=lambda r: -r["n"])[:6]}


def scale_block(brs):
    G = A.Grid(brs, 256)
    rat = []
    for i, b in enumerate(brs):
        mi = float(max(np.ptp(b["V"], 0)))
        for j in G.near(b["box"], 1):
            if j > i and touch(b["box"], brs[j]["box"], 1):
                mj = float(max(np.ptp(brs[j]["V"], 0)))
                rat.append(max(mi, mj) / max(1.0, min(mi, mj)))
    rat = np.array(rat)
    if not len(rat):
        return None
    return {"pairs": len(rat), "ratio_pct": pct(rat), "ge8": round(float((rat >= 8).mean()), 3),
            "ge16": round(float((rat >= 16).mean()), 3), "ge32": round(float((rat >= 32).mean()), 3),
            "max_dim_pct": pct([float(max(np.ptp(b["V"], 0))) for b in brs])}


def meets(comb, old):
    G = A.Grid(old, 256)
    touching, pen, turned, standoff = 0, [], [], []
    for b in comb:
        hit = False
        for j in G.near(b["box"], 1):
            o = old[j]
            if touch(b["box"], o["box"], 1):
                hit = True
                ov = min(min(b["box"][k + 3], o["box"][k + 3]) - max(b["box"][k], o["box"][k]) for k in range(3))
                pen.append(max(0.0, ov))
                t1 = plate_dims(b)[4]
                yaw1 = math.degrees(math.atan2(t1[1], t1[0])) % 90
                t2 = plate_dims(o)[4]
                yaw2 = math.degrees(math.atan2(t2[1], t2[0])) % 90
                dd = abs(yaw1 - yaw2) % 90
                turned.append(min(dd, 90 - dd))
                break
        if hit:
            touching += 1
        else:
            near = [j for j in G.near(b["box"], 32) if touch(b["box"], old[j]["box"], 32)]
            if near:
                gp = min(max(max(old[j]["box"][k] - b["box"][k + 3], b["box"][k] - old[j]["box"][k + 3]) for k in range(3)) for j in near)
                standoff.append(gp)
    return {"combine_touching_old": touching, "share": round(touching / (len(comb) or 1), 3),
            "overlap_depth_pct": pct(pen), "cut_in_share": round(float(np.mean([p > 1 for p in pen])), 3) if pen else None,
            "turned_off_old_share": round(float(np.mean([t > 1 for t in turned])), 3) if turned else None,
            "turned_top": wtop([(t, 1) for t in turned if t > 1], 8),
            "standoff_within32_pct": pct(standoff), "standoff_n": len(standoff)}


def lights(B, S, comb, ents):
    lb = [b for b in S if b["kind"] == "light" or any(f["mc"] == "light" and f.get("vis") for f in b["faces"])]
    mats = Counter()
    for b in lb:
        for f in b["faces"]:
            if f["mc"] == "light" and f.get("vis"):
                mats[f["mat"]] += f["area"]
    dims = [plate_dims(b) for b in lb]
    # light strip faces flush or recessed against neighbouring combine faces
    G = A.Grid(comb, 256)
    rel = []
    for b in lb:
        lf = [f for f in b["faces"] if f["mc"] == "light" and f.get("vis")]
        if not lf:
            continue
        f = max(lf, key=lambda q: q["area"])
        best = None
        for j in G.near(b["box"], 16):
            for g in comb[j]["faces"]:
                if g.get("vis") and float(g["n"] @ f["n"]) > 0.999:
                    c = g["pts"].mean(0)
                    if np.linalg.norm(c - f["pts"].mean(0)) < 256:
                        off = f["d"] - g["d"]
                        if best is None or abs(off) < abs(best):
                            best = off
        if best is not None:
            rel.append(best)
    cls = Counter(e.get("classname") for e in ents)
    lt = {k: cls[k] for k in ("light", "light_spot", "point_spotlight", "env_sprite", "env_lightglow", "beam", "env_beam", "light_dynamic", "env_sprite_oriented", "move_rope", "env_projectedtexture") if cls[k]}
    cols = Counter()
    for e in ents:
        if e.get("classname") in ("light", "light_spot"):
            v = e.get("_light", "").split()
            if len(v) >= 3:
                cols[" ".join(v[:3])] += 1
    spr = Counter(e.get("model", "") for e in ents if e.get("classname") in ("env_sprite", "env_sprite_oriented"))
    sprc = Counter(e.get("rendercolor", "") for e in ents if e.get("classname") in ("env_sprite", "env_sprite_oriented"))
    cvis = sum(f["area"] for b in comb for f in b["faces"] if f.get("vis"))
    return {"strip_brushes": len(lb), "strip_mats": [[k, round(v)] for k, v in mats.most_common(6)],
            "strip_thick_pct": pct([d[0] for d in dims]), "strip_short_pct": pct([d[1] for d in dims]),
            "strip_long_pct": pct([d[2] for d in dims]), "strip_orient": dict(Counter(d[3] for d in dims)),
            "strip_face_vs_combine_face": wtop([(r, 1) for r in rel], 10),
            "entities": lt, "light_colours_top": cols.most_common(8), "sprite_models": spr.most_common(6),
            "sprite_colours": sprc.most_common(6),
            "lights_per_1M_combine_area": round((cls["light"] + cls["light_spot"]) / max(1e-9, cvis / 1e6), 2)}


def props(ents):
    pr = [e for e in ents if e.get("classname", "").startswith("prop_")]
    models = Counter(e.get("model", "").lower() for e in pr)
    comb = Counter({m: c for m, c in models.items() if "combine" in m or "citadel" in m})
    yaws = []
    tilt = 0
    for e in pr:
        m = e.get("model", "").lower()
        if "combine" not in m and "citadel" not in m:
            continue
        a = [float(x) for x in e.get("angles", "0 0 0").split()[:3]] if e.get("angles") else [0, 0, 0]
        y = a[1] % 360
        r = y % 90
        yaws.append("90s" if min(r, 90 - r) < 0.5 else "45s" if abs(y % 45) < 0.5 or abs(y % 45 - 45) < 0.5 else "15s" if min(y % 15, 15 - y % 15) < 0.5 else "free")
        if abs(a[0]) > 0.5 or abs(a[2]) > 0.5:
            tilt += 1
    walls = {m: c for m, c in comb.items() if "innerwall" in m or "wall" in m or "citadel" in m or "tower" in m or "pipe" in m or "plate" in m or "panel" in m}
    return {"props": len(pr), "combine_props": sum(comb.values()), "combine_models_top": comb.most_common(25),
            "combine_yaw": dict(Counter(yaws)), "combine_tilted": tilt, "wall_like_models": sorted(walls.items(), key=lambda t: -t[1])[:15]}


def doors(B, comb, old, ents):
    res = []
    for kind, brs in (("combine", comb), ("old", old)):
        if len(brs) < 10:
            continue
        G = A.Grid(brs, 256)
        byent = defaultdict(list)
        for b in B:
            if b["cls"] in A.DOOR_CLASSES:
                byent[b["eid"]].append(b["box"])
        cands = []
        for eid, bxs in byent.items():
            bxa = np.array(bxs)
            cands.append({"cls": "func_door", "box": tuple(bxa[:, :3].min(0)) + tuple(bxa[:, 3:].max(0)), "nb": len(bxs)})
        for e in ents:
            m = e.get("model", "").lower()
            if e.get("classname", "").startswith("prop_") and "door" in m and ("combine" in m or "door01" in m or "lab" in m):
                o = np.array([float(x) for x in e.get("origin", "0 0 0").split()])
                yaw = float((e.get("angles", "0 0 0").split() + ["0", "0"])[1])
                fx = abs(math.cos(math.radians(yaw))) > abs(math.sin(math.radians(yaw)))
                half = np.array([8.0, 56.0, 0.0]) if fx else np.array([56.0, 8.0, 0.0])
                cands.append({"cls": "prop_door", "box": tuple(o - half) + tuple(o + half + np.array([0, 0, 128.0]))})
        for b in cands:
            bx = np.array(b["box"])
            ext = bx[3:] - bx[:3]
            if ext[2] < 64 or ext[2] > 600 or min(ext[0], ext[1]) > 128:
                continue
            ax = 0 if ext[0] < ext[1] else 1      # thin axis = wall normal
            along = 1 - ax
            c = (bx[:3] + bx[3:]) / 2
            half = ext[along] / 2 + 160
            win = np.array([0, 0, 0, 0, 0, 0], float)
            win[ax], win[ax + 3] = c[ax] - 96, c[ax] + 96
            win[along], win[along + 3] = c[along] - half, c[along] + half
            win[2], win[5] = bx[2], bx[5] + 128
            ids = [j for j in G.near(tuple(win), 0) if touch(brs[j]["box"], tuple(win), 0)]
            if len(ids) < 2:
                continue
            res8 = 8.0
            dims = np.ceil((win[3:] - win[:3]) / res8).astype(int)
            occ = np.zeros(dims, bool)
            for j in ids:
                br = brs[j]
                lo = np.clip(((np.array(br["box"][:3]) - win[:3]) // res8).astype(int) - 1, 0, dims - 1)
                hi = np.clip(((np.array(br["box"][3:]) - win[:3]) // res8).astype(int) + 1, 0, dims - 1)
                gx, gy, gz = np.meshgrid(*[np.arange(lo[k], hi[k] + 1) for k in range(3)], indexing="ij")
                P = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], 1)
                C = win[:3] + (P + 0.5) * res8
                ins = ((C @ br["N"].T) - (br["D"] + 4) <= 1e-6).all(1)
                Q = P[ins]
                occ[Q[:, 0], Q[:, 1], Q[:, 2]] = True
            occ = np.flip(occ, along) & occ if False else occ
            fl = np.flip(occ, along)
            inter = (occ & fl).sum()
            uni = (occ | fl).sum()
            if uni < 30:
                continue
            res.append((kind, round(float(inter / uni), 3), [round(float(v)) for v in c], b.get("nb", 1), round(float(ext[along])), round(float(ext[2]))))
    out = {}
    for kind in ("combine", "old"):
        v = [r[1] for r in res if r[0] == kind]
        if v:
            out[kind] = {"n": len(v), "iou_pct": pct(v), "examples": [r for r in res if r[0] == kind][:5]}
    return out


if __name__ == "__main__":
    for nm in sys.argv[1:]:
        r = analyse(nm)
        print(nm, "done", flush=True)
