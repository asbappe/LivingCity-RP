"""Living City map ingestion, part "craft" (3 of 3): light recipes and decals versus overlays (the craft helpers'
light.py and ovl.py).

    run(m, s, nodes) -> dict, merged into measure.json["craft"]

A light's fixture is the nearest prop model within 48. Indoors is where a ray straight up meets a brush that is
not sky. Spacing is between lights after joining those within 64 of each other (a spot and its fill light).
"""
import collections
import re

import numpy as np

from .common import C, dist, top, med, rnd, short, light_value, tone, near_dist

DECAL_KINDS = [("road", r"road|stripe|line|arrow|crosswalk|parking"), ("crack", r"crack"), ("poster", r"poster|breen|propaganda|billboard"),
               ("sign", r"sign|number|letter|exit|danger|warning"), ("stain", r"stain|dirt|grime|smear|leak|drip|mildew|rust|water|wet"),
               ("puddle", r"puddle"), ("graffiti", r"graffiti|lambda|spray|tag"), ("trash", r"trash|paper|debris|litter|rubble"),
               ("burn", r"burn|scorch|blast"), ("plant", r"ivy|leaves|moss|grass|vine"), ("blood", r"blood"),
               ("grate", r"grate|manhole|drain|vent|sewer"), ("plaster", r"plaster|concrete|wall|tile|wood|brick|metal")]


def decal_kind(mat):
    return next((k for k, r in DECAL_KINDS if re.search(r, mat)), "other")


def run(m, s, N):
    R = collections.OrderedDict()
    R["lights"] = lights(m, s, N)
    R["decals"] = decals(m, s, N)
    return R


def lights(m, s, N):
    E = [e for e in m.ents if m.play_ent(e)]
    L = [e for e in E if e.cls in ("light", "light_spot") and e.origin is not None]
    props = [(e.origin, short(e.model)) for e in E if e.cls.startswith("prop_") and e.origin is not None]
    PP = np.array([p for p, _ in props]).reshape(-1, 3)
    tones, bright = collections.defaultdict(C), collections.defaultdict(list)
    fix, fixv = C(), collections.defaultdict(list)
    fall, cone, inner, pitch, expo, ratio = C(), C(), C(), C(), C(), []
    named = styled = 0
    for e in L:
        r, g, b, br = light_value(e.kv.get("_light"))
        up, _ = s.open_above(e.origin[0], e.origin[1], e.origin[2])
        io = "out" if up else "in"
        tones[e.cls + " " + io][tone((r, g, b))] += 1
        bright[e.cls + " " + io].append(br)
        fx = "(none)"
        if len(PP):
            d = np.linalg.norm(PP - e.origin, axis=1)
            j = int(np.argmin(d))
            if d[j] < 48:
                fx = props[j][1]
        fix[(e.cls, fx)] += 1
        kv = e.kv
        if kv.get("targetname"):
            named += 1
        if kv.get("style", "0") not in ("0", ""):
            styled += 1
        a = (float(kv.get("_constant_attn", 0) or 0), float(kv.get("_linear_attn", 0) or 0), float(kv.get("_quadratic_attn", 1) or 0))
        f50 = float(kv.get("_fifty_percent_distance", 0) or 0)
        fk = "fifty/zero" if f50 > 0 else ("quadratic" if a == (0, 0, 1) else "c%g l%g q%g" % a)
        fall[fk] += 1
        rec = {"tone": tone((r, g, b)), "light": "%d %d %d" % (r, g, b), "bright": br, "falloff": fk}
        if e.cls == "light_spot":
            c1, c0 = float(kv.get("_cone", 45) or 45), float(kv.get("_inner_cone", 30) or 30)
            cone[rnd(c1 / 5, 0) * 5] += 1
            inner[rnd(c0 / 5, 0) * 5] += 1
            if c1 > 0:
                ratio.append(c0 / c1)
            p = float(kv.get("pitch", e.angles[0]) or 0)
            pitch[rnd(p / 15, 0) * 15] += 1
            expo[kv.get("_exponent", "1")] += 1
            rec.update(cone="%g/%g" % (c1, c0), pitch=p, exponent=kv.get("_exponent", "1"))
        fixv[(e.cls, fx)].append(rec)
    recipes = []
    for (cl, fx), n in fix.most_common(14):
        v = fixv[(cl, fx)]
        rr = {"class": cl, "fixture": fx, "n": n, "light": C(x["light"] for x in v).most_common(1)[0][0], "bright": med([x["bright"] for x in v]),
              "falloff": C(x["falloff"] for x in v).most_common(1)[0][0]}
        if cl == "light_spot":
            rr.update(cone=C(x["cone"] for x in v).most_common(1)[0][0], pitch=med([x["pitch"] for x in v]), exponent=C(x["exponent"] for x in v).most_common(1)[0][0])
        recipes.append(rr)
    # spacing between light groups (a spot and its fill within 64 are one light)
    P = np.array([e.origin for e in L]).reshape(-1, 3)
    groups = []
    for p in P:
        if not any(np.linalg.norm(p - q) < 64 for q in groups):
            groups.append(p)
    G = np.array(groups).reshape(-1, 3)
    nn = []
    if len(G) > 1:
        d = np.linalg.norm(G[:, None] - G[None], axis=2)
        np.fill_diagonal(d, 1e9)
        nn = d.min(axis=1)
    dark = {}
    if len(N) and len(P):
        dn = near_dist(P, N)
        ins = np.array([not s.open_above(p[0], p[1], p[2] + 16)[0] for p in N])
        for k, sel in (("in", ins), ("out", ~ins)):
            if sel.any():
                dark[k] = {"nearest": med(dn[sel]), "none_within_256": round(float((dn[sel] > 256).mean()), 2), "none_within_512": round(float((dn[sel] > 512).mean()), 2)}
    return {"n": len(L), "named": named, "styled": styled, "tones": {k: dict(v) for k, v in tones.items()},
            "brightness": {k: med(v) for k, v in bright.items()}, "falloff": dict(fall.most_common(6)),
            "spot_cone_top": top(cone, 6), "spot_inner_top": top(inner, 5), "spot_inner_over_outer": med(ratio),
            "spot_pitch_top": top(pitch, 6), "spot_exponent_top": top(expo, 4), "recipes": recipes,
            "spacing": dist(nn, 32, 12), "nodes_dark": dark}


def decals(m, s, N):
    E = [e for e in m.ents if m.play_ent(e) and e.origin is not None]
    ov = [e for e in E if e.cls == "info_overlay"]
    dc = [e for e in E if e.cls == "infodecal"]
    osurf, dsurf, sizes = collections.defaultdict(C), collections.defaultdict(C), collections.defaultdict(list)
    sides, atlas, oh, dh = C(), 0, [], []
    dirs = np.array([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]], float)
    for e in ov:
        mat = e.kv.get("material", "").lower()
        k = decal_kind(mat)
        uv = np.array([(m_nums(e.kv.get("uv%d" % i, "0 0 0")) + [0, 0, 0])[:3] for i in range(4)])
        sizes[k].append((np.ptp(uv[:, 0]), np.ptp(uv[:, 1])))
        bn = (m_nums(e.kv.get("basisnormal", "0 0 1")) + [0, 0, 1])[:3]
        o = "floor" if bn[2] > 0.7 else ("ceiling" if bn[2] < -0.7 else "wall")
        osurf[o][k] += 1
        sides[min(len(e.kv.get("sides", "").split()), 6)] += 1
        if tuple(float(e.kv.get(x, d) or d) for x, d in (("startu", 0), ("endu", 1), ("startv", 0), ("endv", 1))) != (0, 1, 0, 1):
            atlas += 1
        if o == "wall":
            q = e.origin + np.array(bn) * 4
            t, _, _ = s.ray(q, (0, 0, -1), 2048, inside=False)
            if t is not None:
                oh.append(t)
    for e in dc:
        k = decal_kind(e.kv.get("texture", "").lower())
        t = [s.ray(e.origin - d * 2, d, 64)[0] for d in dirs]
        t = [x if x is not None else 1e9 for x in t]
        j = int(np.argmin(t))
        o = "floor" if j == 5 else ("ceiling" if j == 4 else "wall")
        dsurf[o][k] += 1
        if o == "wall":
            q = e.origin - dirs[j] * 4
            tz, _, _ = s.ray(q, (0, 0, -1), 2048, inside=False)
            if tz is not None:
                dh.append(tz)
    cells = {}
    if len(N):
        ck = C(tuple(x) for x in np.floor(N / 512).astype(int))
        dk = C(tuple(x) for x in np.floor(np.array([e.origin for e in ov + dc]).reshape(-1, 3) / 512).astype(int))
        per = [dk[c] for c in ck]
        cells = {"with_any": round(sum(1 for c in ck if dk[c]) / max(1, len(ck)), 2), "per_cell": dist(per, 1, 8)}
    return {"overlays": len(ov), "decals": len(dc),
            "overlay_kinds": {o: top(c, 6) for o, c in osurf.items()}, "decal_kinds": {o: top(c, 6) for o, c in dsurf.items()},
            "overlay_sizes": {k: [len(v), med([a for a, b in v]), med([b for a, b in v])] for k, v in sizes.items()},
            "overlay_faces": dict(sides), "overlay_atlas": atlas,
            "wall_height": {"overlays": dist(oh, 8, 8), "decals": dist(dh, 8, 8)}, "cells": cells}


def m_nums(text):
    try:
        return [float(x) for x in text.replace("[", " ").replace("]", " ").split()]
    except ValueError:
        return []
