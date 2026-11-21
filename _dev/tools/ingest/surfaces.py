"""Living City map ingestion, part "craft" (2 of 3): walls in bands, painted fronts, glass, sloped roofs and
displacements (the earlier measure.py walls and the craft helpers' disp.py).

    run(m, s, nodes) -> dict, merged into measure.json["craft"]
"""
import collections
import math
import re

import numpy as np

from .common import C, dist, top, shares, med, rnd, near_dist, band

WALL_CLS = ("world", "func_detail", "func_brush")


def run(m, s, N):
    vis = [f for f in range(len(m.f_mat)) if m.play_brush(m.f_brush[f]) and not m.mat(f).startswith("tools/")
           and m.b_cls[m.f_brush[f]] in WALL_CLS]
    vert = [f for f in vis if abs(m.f_n[f][2]) < 0.05 and m.f_disp[f] < 0]
    R = collections.OrderedDict()
    R["wall_bands"] = bands(m, vert)
    area = sum(m.f_area[f] for f in vert)
    tm = [f for f in vert if "template" in m.mat(f)]
    R["fronts"] = {"template_share": round(sum(m.f_area[f] for f in tm) / max(1.0, area), 2), "templates_top": top(C(m.mat(f) for f in tm), 5, short=True)}
    R["glass"] = glass(m, vert)
    roofs = [f for f in vis if 0.3 < m.f_n[f][2] < 0.97 and m.f_disp[f] < 0 and m.f_area[f] > 2000]
    R["slopes"] = {"n": len(roofs), "pitch": dist([math.degrees(math.acos(min(1.0, m.f_n[f][2]))) for f in roofs], 5, 10),
                   "materials_top": top(C(m.mat(f) for f in roofs), 6, short=True)}
    R["displacements"] = displacements(m, N)
    return R


def bands(m, vert):
    """Columns 32 apart along every wall plane: does the material change going up, and where first?"""
    info = {}
    for f in vert:
        p = m.corners(f)
        n = m.f_n[f]
        tdir = np.array([-n[1], n[0], 0.0])
        tt = p @ tdir
        info[f] = (p[:, 2].min(), p[:, 2].max(), tt.min(), tt.max(), float(n @ p[0]))
    bykey = collections.defaultdict(list)
    for f in vert:
        bykey[int(round(math.degrees(math.atan2(m.f_n[f][1], m.f_n[f][0])) / 5.0)) % 72].append(f)
    first, pairs, banded, single = [], C(), 0, 0
    for fs in bykey.values():
        fs.sort(key=lambda f: info[f][4])
        groups, cur = [], [fs[0]]
        for f in fs[1:]:
            if info[f][4] - info[cur[-1]][4] <= 10:
                cur.append(f)
            else:
                groups.append(cur)
                cur = [f]
        groups.append(cur)
        for g in groups:
            lo, hi = min(info[f][2] for f in g), max(info[f][3] for f in g)
            if hi - lo < 64:
                continue
            for sv in np.arange(lo + 16, hi, 32):
                col = sorted([f for f in g if info[f][2] <= sv <= info[f][3]], key=lambda f: info[f][0])
                if not col:
                    continue
                base, topz = info[col[0]][0], max(info[f][1] for f in col)
                if topz - base < 192:
                    continue
                runs = []
                for f in col:
                    mt, z0, z1 = m.mat(f), info[f][0], info[f][1]
                    if runs and runs[-1][0] == mt and z0 <= runs[-1][2] + 1:
                        runs[-1][2] = max(runs[-1][2], z1)
                    elif runs and z0 < runs[-1][2] - 1:
                        continue
                    else:
                        runs.append([mt, z0, z1])
                if topz - base >= 256:
                    if len(set(r[0] for r in runs)) >= 2:
                        banded += 1
                    else:
                        single += 1
                if len(runs) >= 2 and runs[0][2] - base >= 16:
                    first.append(runs[0][2] - base)
                    pairs[runs[0][0].split("/")[-1] + " > " + runs[1][0].split("/")[-1]] += 1
    return {"columns_256": banded + single, "banded_share": round(banded / max(1, banded + single), 2),
            "first_change": dist(first, 8, 12), "pairs_top": top(C({k: v for k, v in pairs.items() if k.split(" > ")[0] != k.split(" > ")[1]}), 8)}


def glass(m, vert):
    g = [f for f in vert if re.search(r"glass|window", m.mat(f))]
    sizes, st = C(), []
    info = {}
    for f in g:
        p = m.corners(f)
        n = m.f_n[f]
        tdir = np.array([-n[1], n[0], 0.0])
        tt = p @ tdir
        info[f] = (p[:, 2].min(), p[:, 2].max(), tt.min(), tt.max(), float(n @ p[0]))
        sizes["%gx%g" % (rnd(round((tt.max() - tt.min()) / 8) * 8), rnd(round((p[:, 2].max() - p[:, 2].min()) / 8) * 8))] += 1
    gk = collections.defaultdict(list)
    for f in g:
        gk[(int(round(math.degrees(math.atan2(m.f_n[f][1], m.f_n[f][0])) / 5.0)) % 72, int(round(info[f][4] / 16)))].append(f)
    for fs in gk.values():
        for a in fs:
            above = [info[b][0] - info[a][0] for b in fs if b != a and info[b][0] - info[a][0] > 48
                     and min(info[a][3], info[b][3]) - max(info[a][2], info[b][2]) > 16]
            if above:
                st.append(min(above))
    brush_glass = [f for f in g if "building_template" not in m.mat(f) and "storefront" not in m.mat(f)]
    th = []
    for f in brush_glass:
        b = m.f_brush[f]
        th.append(abs((m.b_hi[b] - m.b_lo[b]) @ m.f_n[f]))
    return {"faces": len(g), "sizes_top": top(sizes, 6), "materials_top": top(C(m.mat(f) for f in g), 5, short=True),
            "storey": dist(st, 8, 6), "pane_thickness_top": top(C(rnd(t) for t in th), 4)}


def displacements(m, N):
    D = [i for i, d in enumerate(m.disps) if m.play_brush(m.f_brush[d.face])]
    if not D:
        return {"n": 0}
    pw, surf, mats, sizes, lms, alpha, sign, where = C(), C(), C(), C(), C(), C(), C(), C()
    cen = []
    border, inner = [], []
    for i in D:
        d = m.disps[i]
        f = d.face
        c = m.corners(f)
        pw[d.power] += 1
        nz = m.f_n[f][2]
        surf["floor" if nz > 0.7 else ("ceiling" if nz < -0.7 else "wall")] += 1
        mats[m.mat(f)] += 1
        if len(c) == 4:
            sizes["%gx%g" % tuple(sorted((rnd(np.linalg.norm(c[1] - c[0])), rnd(np.linalg.norm(c[3] - c[0]))), reverse=True))] += 1
        lms[int(m.f_lms[f])] += 1
        painted = (d.alphas > 1).mean() > 0.05
        alpha[("blend" if "blend" in m.mat(f) else "plain") + (" painted" if painted else "")] += 1
        sd = float((d.distances * np.sign((d.normals @ m.f_n[f]) + 1e-9)).mean())
        sign["up" if sd > 1 else ("down" if sd < -1 else "level")] += 1
        dd = np.abs(d.distances)
        if dd.shape[0] > 2:
            edge = np.concatenate([dd[0], dd[-1], dd[1:-1, 0], dd[1:-1, -1]])
            border.append(edge.mean())
            inner.append(dd[1:-1, 1:-1].mean())
        cen.append(m.f_cen[f])
    dn = near_dist(N, np.array(cen)) if len(N) else np.full(len(D), 9e9)
    for x in dn:
        where[band(x)] += 1
    return {"n": len(D), "power": shares(pw, 2), "surface": dict(surf), "sizes_top": top(sizes, 5), "lightmapscale": shares(lms, 2, 4),
            "alpha": dict(alpha), "offset": dict(sign), "from_nodes": dict(where), "materials_top": top(mats, 8, short=True),
            "border_vs_inner": [med(border), med(inner)]}
