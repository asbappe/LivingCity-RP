"""Living City map ingestion, part "props": how Valve places props (the props helpers' a_place, a_wall, a_clus,
a_dens, in one pass).

    run(m, s) -> dict for measure.json["props"]

Props in play space only (no hidden, no 3D skybox room, no skybox-only models). Kinds come from model names
(common.KIND_RULES); "dressing" is furniture, clutter, lamps and the dead. Model boxes come from asset_facts.json
(map_assets.size, which learns a model it has not met if the Valve lists are in _dev/tools/dl).
"""
import collections
import math

import numpy as np

from .common import C, dist, top, shares, med, rnd, short, kind, world_box, yaw_class, tilt, model_box, model_facts, DRESS, node_points
from .geom import Grid

WALL_BANDS = ((0.5, "touch"), (4, "<=4"), (16, "4-16"), (32, "16-32"), (64, "32-64"), (128, "64-128"), (1e9, ">128"))
FLAGS = (1, 2, 4, 8, 64, 128, 256)


def gather(m):
    out = []
    for e in m.ents:
        if not e.cls.startswith("prop_") or not m.play_ent(e) or e.origin is None:
            continue
        k = kind(e.model, e.cls)
        if k == "skybox":
            continue
        bb = model_box(e.model)
        out.append({"e": e, "cls": e.cls, "group": group(e.cls), "model": e.model, "kind": k, "o": e.origin, "ang": e.angles,
                    "bb": bb, "wb": world_box(e.origin, e.angles, bb)})
    return out


def group(cls):
    for g in ("prop_static", "prop_physics", "prop_dynamic", "prop_ragdoll", "prop_door_rotating"):
        if cls.startswith(g):
            return g
    return "other"


def run(m, s):
    P = gather(m)
    R = collections.OrderedDict()
    R["n"] = len(P)
    R["classes"] = dict(C(p["cls"] for p in P).most_common())
    R["kinds_top"] = top(C(p["kind"] for p in P), 25)
    R["unsized_models"] = sorted(set(short(p["model"]) for p in P if not p["bb"]))[:20]
    R.update(placement(P))
    R.update(keys(P))
    walls(m, s, P)
    R.update(wall_stats(P))
    R.update(clusters(P))
    R["density"] = density(m, P)
    return R


def placement(P):
    R = {"yaw": {}, "tilted": {}}
    for g in ("prop_static", "prop_physics", "prop_dynamic"):
        S = [p for p in P if p["group"] == g]
        if S:
            R["yaw"][g] = shares(C(yaw_class(p["ang"][1]) for p in S), 2)
            R["tilted"][g] = round(sum(tilt(p["ang"]) > 0.5 for p in S) / len(S), 2)
    K = collections.defaultdict(list)
    for p in P:
        K[p["kind"]].append(p)
    R["yaw_grid_by_kind"] = {k: [len(L), round(sum(yaw_class(p["ang"][1]) == "grid" for p in L) / len(L), 2)]
                             for k, L in sorted(K.items(), key=lambda kv: -len(kv[1])) if len(L) >= 5}
    ph = [p for p in P if p["group"] == "prop_physics"]
    tl = [tilt(p["ang"]) for p in ph if tilt(p["ang"]) > 0.5]
    R["physics_tilt"] = dist(tl, 15, 8)
    R["lying_by_kind"] = top(C(p["kind"] for p in ph if 75 <= tilt(p["ang"]) <= 105), 10)
    R["upside_down"] = sum(1 for p in ph if tilt(p["ang"]) > 150)
    return R


def keys(P):
    R = {}
    ph = [p for p in P if p["group"] == "prop_physics"]
    fl = [int(p["e"].kv.get("spawnflags", "0") or 0) for p in ph]
    R["physics_flags"] = {str(b): sum(1 for f in fl if f & b) for b in FLAGS}
    R["motion_disabled_kinds"] = top(C(p["kind"] for p, f in zip(ph, fl) if f & 8), 8)
    R["debris_kinds"] = top(C(p["kind"] for p, f in zip(ph, fl) if f & 4), 8)
    sk = [p for p in P if p["e"].kv.get("skin", "0") not in ("0", "")]
    R["skin_not_0"] = round(len(sk) / max(1, len(P)), 2)
    R["skins_top"] = top(C(short(p["model"]) for p in sk), 8)
    fades = collections.defaultdict(list)
    for p in P:
        lo, hi = float(p["e"].kv.get("fademindist", "-1") or -1), float(p["e"].kv.get("fademaxdist", "0") or 0)
        fades[p["group"]].append((lo, hi))
    R["fades"] = {g: {"set": round(sum(1 for a, b in L if b > 0) / len(L), 2), "min": med([a for a, b in L if b > 0 and a > 0]),
                      "max": med([b for a, b in L if b > 0])} for g, L in fades.items()}
    fk = collections.defaultdict(list)
    for p in P:
        hi = float(p["e"].kv.get("fademaxdist", "0") or 0)
        if hi > 0:
            fk[p["kind"]].append(hi)
    R["fade_max_by_kind"] = {k: [len(v), med(v)] for k, v in sorted(fk.items(), key=lambda kv: -len(kv[1]))[:12]}
    R["no_shadows"] = {g: round(sum(p["e"].kv.get("disableshadows", "0") == "1" for p in P if p["group"] == g) / max(1, sum(p["group"] == g for p in P)), 2)
                       for g in ("prop_static", "prop_physics", "prop_dynamic")}
    st = [p for p in P if p["group"] == "prop_static"]
    R["static_not_solid"] = round(sum(p["e"].kv.get("solid", "6") == "0" for p in st) / max(1, len(st)), 2)
    R["static_not_solid_top"] = top(C(short(p["model"]) for p in st if p["e"].kv.get("solid", "6") == "0"), 8)
    R["static_with_prop_data"] = top(C(short(p["model"]) for p in st if model_facts(p["model"]).get("prop_data")), 8)
    R["rendercolor_set"] = sum(1 for p in P if p["e"].kv.get("rendercolor", "255 255 255") not in ("255 255 255", ""))
    R["modelscale_set"] = sum(1 for p in P if p["e"].kv.get("modelscale", "1") not in ("1", "", "1.0"))
    dy = [p for p in P if p["group"] == "prop_dynamic"]
    R["dynamic_why"] = {"parented": sum(1 for p in dy if p["e"].kv.get("parentname")), "named": sum(1 for p in dy if p["e"].name and not p["e"].kv.get("parentname")),
                        "plain": sum(1 for p in dy if not p["e"].name and not p["e"].kv.get("parentname"))}
    return R


def walls(m, s, P):
    """Gap from each prop's box to the nearest axis brush at its height; what it stands on."""
    keep = [b for b in range(len(m.b_owner)) if m.play_brush(b) and m.b_axis[b] and not m.b_disp[b]
            and m.b_cls[b] in ("world", "func_detail", "func_brush", "func_wall")
            and any(not m.mat(f).startswith("tools/") or "nodraw" in m.mat(f) for f in m.faces_of(b))]
    lo, hi = m.b_lo[keep], m.b_hi[keep]
    g = Grid(lo, hi)
    wb = [p for p in P if p["wb"] is not None]
    pg = Grid(np.array([p["wb"][:3] for p in wb]).reshape(-1, 3), np.array([p["wb"][3:] for p in wb]).reshape(-1, 3))
    for p in P:
        p["wall"], p["ground"] = None, "air"
        w = p["wb"]
        if w is None:
            continue
        zlo, zhi = w[2] + 4, max(w[2] + 5, min(w[5], w[2] + 72))
        c = g.near_box(w[0] - 128, w[1] - 128, w[3] + 128, w[4] + 128)
        best = 1e9
        if len(c):
            bl, bh = lo[c], hi[c]
            ok = (bh[:, 2] > zlo) & (bl[:, 2] < zhi) & (bh[:, 2] > w[2] + 2)
            if ok.any():
                bl, bh = bl[ok], bh[ok]
                dx = np.maximum(np.maximum(bl[:, 0] - w[3], w[0] - bh[:, 0]), 0)
                dy = np.maximum(np.maximum(bl[:, 1] - w[4], w[1] - bh[:, 1]), 0)
                dd = np.where((dx == 0) | (dy == 0), np.maximum(dx, dy), np.hypot(dx, dy))
                best = float(dd.min())
        p["wall"] = best
        fz, f = s.floor(p["o"][0], p["o"][1], max(p["o"][2], w[2]) + 8, 160)
        if fz is not None and abs(min(p["o"][2], w[2]) - fz) <= 6:
            p["ground"] = "displacement" if m.f_disp[f] >= 0 else "brush"
        for j in pg.near_box(w[0], w[1], w[3], w[4]):
            q = wb[j]
            if q is p:
                continue
            v = q["wb"]
            if abs(w[2] - v[5]) <= 4:
                ox, oy = min(w[3], v[3]) - max(w[0], v[0]), min(w[4], v[4]) - max(w[1], v[1])
                a1 = (w[3] - w[0]) * (w[4] - w[1])
                if ox > 0 and oy > 0 and ox * oy >= 0.3 * a1 and v[5] - v[2] > 4:
                    p["ground"] = "prop"
                    p["on"] = q["kind"]
                    break


def wall_stats(P):
    R = {"wall_gap": {}, "ground": {}}
    for g in ("prop_static", "prop_physics", "prop_dynamic"):
        S = [p["wall"] for p in P if p["group"] == g and p["wall"] is not None]
        if S:
            R["wall_gap"][g] = shares(C(next(lab for lim, lab in WALL_BANDS if d <= lim) for d in S), 2)
            R["ground"][g] = shares(C(p["ground"] for p in P if p["group"] == g), 2)
    K = collections.defaultdict(list)
    for p in P:
        if p["wall"] is not None:
            K[p["kind"]].append(p["wall"])
    R["within_16_by_kind"] = {k: [len(v), round(sum(d <= 16 for d in v) / len(v), 2)] for k, v in sorted(K.items(), key=lambda kv: -len(kv[1])) if len(v) >= 5}
    R["stacked_top"] = top(C("%s on %s" % (p["kind"], p["on"]) for p in P if p.get("on")), 8)
    return R


def clusters(P, r=96.0):
    D = [p for p in P if p["kind"] in DRESS]
    if len(D) < 2:
        return {"clusters": {"dressing": len(D), "n": 0}}
    A = np.array([p["o"] for p in D])
    near = (np.hypot(A[:, None, 0] - A[None, :, 0], A[:, None, 1] - A[None, :, 1]) <= r) & (np.abs(A[:, None, 2] - A[None, :, 2]) < 64)
    np.fill_diagonal(near, False)
    seen, comps = set(), []
    for i in range(len(D)):
        if i in seen:
            continue
        st, comp = [i], []
        seen.add(i)
        while st:
            x = st.pop()
            comp.append(x)
            for y in np.nonzero(near[x])[0]:
                if y not in seen:
                    seen.add(y)
                    st.append(y)
        if len(comp) >= 2:
            comps.append(comp)
    same = collections.defaultdict(list)
    for i, p in enumerate(D):
        same[p["kind"]].append(any(D[j]["kind"] == p["kind"] for j in np.nonzero(near[i])[0]))
    pairs = C()
    for comp in comps:
        ks = sorted(set(D[i]["kind"] for i in comp))
        for a in range(len(ks)):
            for b in range(a + 1, len(ks)):
                pairs[ks[a] + "+" + ks[b]] += 1
    return {"clusters": {"dressing": len(D), "n": len(comps), "size": dist([len(c) for c in comps], 1, 10),
                         "alone": len(D) - sum(len(c) for c in comps),
                         "same_kind_near": {k: [len(v), round(sum(v) / len(v), 2)] for k, v in sorted(same.items(), key=lambda kv: -len(kv[1])) if len(v) >= 5},
                         "pairs_top": top(pairs, 12)}}


def density(m, P, cell=256.0):
    """Props per 256 square of play (a square holding an AI node), and per 100 by 100."""
    N = node_points(m)
    if not len(N):
        return {"cells": 0}
    cells = set(map(tuple, np.floor(N[:, :2] / cell).astype(int)))
    cnt = C()
    dress, phys = C(), C()
    for p in P:
        k = tuple(np.floor(np.array(p["o"][:2]) / cell).astype(int))
        if k in cells:
            cnt[k] += 1
            dress[k] += p["kind"] in DRESS
            phys[k] += p["group"] == "prop_physics"
    n = len(cells)
    area = n * cell * cell / 10000.0
    return {"cells": n, "per_cell": dist([cnt[k] for k in cells], 1, 12), "per_10000": round(sum(cnt.values()) / area, 3),
            "dressing_per_10000": round(sum(dress.values()) / area, 3), "physics_per_10000": round(sum(phys.values()) / area, 3),
            "empty_cells": round(sum(1 for k in cells if not cnt[k]) / n, 2)}
