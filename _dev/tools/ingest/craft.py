"""Living City map ingestion, part "craft" (1 of 3): texture and brush craft (the craft helpers' tex.py, brush.py,
trim2.py, frames.py, in one pass). Surfaces are in surfaces.py, lights and decals in light.py.

    run(m, s) -> dict for measure.json["craft"] (with surfaces.run and light.run merged in)

"Near", "mid" and "far" are the distance from the nearest AI node: under 256, under 1024, beyond.
Texture sizes are not in the files, so seams are tested against 128, 256 and 512 texels.
"""
import collections
import math

import numpy as np

from .common import C, top, shares, med, rnd, node_points, near_dist, band
from . import surfaces, light

DETAIL = ("world", "func_detail")


def skip_mat(mat):
    return mat.startswith(("tools/", "effects/"))


def run(m, s):
    N = node_points(m)
    R = collections.OrderedDict()
    R.update(texture(m, N))
    R.update(brushes(m, s, N))
    R.update(surfaces.run(m, s, N))
    R.update(light.run(m, s, N))
    return R


def scale_key(f, m):
    su, sv = round(abs(m.f_u[f][4]), 3), round(abs(m.f_v[f][4]), 3)
    return "%g" % su if su == sv else "%g/%g" % (su, sv)


def texture(m, N):
    vis = [f for f in range(len(m.f_mat)) if m.play_brush(m.f_brush[f]) and not skip_mat(m.mat(f))]
    plain = [f for f in vis if m.f_disp[f] < 0 and m.f_u[f][4] != 0]
    disp = [f for f in vis if m.f_disp[f] >= 0]
    dn = near_dist(N, m.f_cen[plain]) if len(N) and plain else np.full(len(plain), 9e9)
    sc, sca, scd, lms, lmsd, scs = C(), C(), collections.defaultdict(C), C(), collections.defaultdict(C), collections.defaultdict(C)
    rot = off = shift = 0
    seam, seam0, walls = C(), C(), 0
    for f, d in zip(plain, dn):
        k = scale_key(f, m)
        a = m.f_area[f]
        sc[k] += 1
        sca[k] += a
        b = band(d)
        scd[b][k] += a
        nz = m.f_n[f][2]
        scs["floor" if nz > 0.7 else ("ceiling" if nz < -0.7 else ("wall" if abs(nz) < 0.05 else "slope"))][k] += a
        L = int(m.f_lms[f])
        lms[L] += 1
        lmsd[b][L] += 1
        rot += m.f_rot[f] != 0
        u, v = m.f_u[f], m.f_v[f]
        off += abs(abs(u[:3]).max() - 1) > 1e-3 or abs(abs(v[:3]).max() - 1) > 1e-3
        shift += u[3] != 0 or v[3] != 0
        n = m.f_n[f]
        if abs(n[2]) < 0.05 and abs(abs(n).max() - 1) < 1e-3 and abs(abs(v[2]) - 1) < 1e-3 and v[4]:
            walls += 1
            p = m.corners(f)
            z = p[:, 2].argmin()
            vt = p[z] @ v[:3] / v[4] + v[3]
            vt0 = p[z] @ v[:3] / v[4]
            for W in (128, 256, 512):
                seam[W] += min(vt % W, W - vt % W) < 0.5
                seam0[W] += min(vt0 % W, W - vt0 % W) < 0.5
    tot = max(1, len(plain))
    return {"texture": {"faces": len(plain), "scale": shares(sc, 2, 6), "scale_by_area": shares(sca, 2, 6),
                        "scale_by_distance": {b: shares(c, 2, 4) for b, c in scd.items()},
                        "scale_by_surface": {b: shares(c, 2, 4) for b, c in scs.items()},
                        "off_quarter_top": top(C(m.mat(f) for f in plain if scale_key(f, m) != "0.25"), 8, short=True),
                        "rotated": round(rot / tot, 3), "off_axis": round(off / tot, 3), "shifted": round(shift / tot, 2),
                        "walls_v_up": walls, "foot_on_seam": {str(W): round(seam[W] / max(1, walls), 2) for W in (128, 256, 512)},
                        "foot_on_seam_unshifted": {str(W): round(seam0[W] / max(1, walls), 2) for W in (128, 256, 512)}},
            "lightmapscale": {"faces": shares(lms, 3, 7), "by_distance": {b: shares(c, 2, 4) for b, c in lmsd.items()},
                              "displacements": shares(C(int(m.f_lms[f]) for f in disp), 2, 4),
                              "fine_top": top(C(m.mat(f) for f in plain if m.f_lms[f] < 16), 8, short=True),
                              "coarse_top": top(C(m.mat(f) for f in plain if m.f_lms[f] > 16), 8, short=True)}}


def brush_kind(d, nonaxis):
    d = np.sort(d)
    if nonaxis:
        return "angled"
    if d[0] <= 16 and d[1] <= 32:
        return "strip"
    if d[0] <= 16:
        return "thin"
    if d[2] <= 64:
        return "small"
    return "large" if d[2] >= 512 else "mid"


def brushes(m, s, N):
    B = [b for b in range(len(m.b_owner)) if m.play_brush(b) and m.b_cls[b] in DETAIL and not m.b_disp[b]
         and any(not skip_mat(m.mat(f)) for f in m.faces_of(b))]
    kinds = {"world": C(), "func_detail": C()}
    area = C()
    for b in B:
        kinds[m.b_cls[b]][brush_kind(m.b_hi[b] - m.b_lo[b], not m.b_axis[b])] += 1
        area[m.b_cls[b]] += sum(m.f_area[f] for f in m.faces_of(b) if not skip_mat(m.mat(f)))
    nb = max(1, len(B))
    R = {"brushes": {"n": len(B), "detail_share": round(sum(m.b_cls[b] == "func_detail" for b in B) / nb, 2),
                     "detail_area_share": round(area["func_detail"] / max(1.0, area["func_detail"] + area["world"]), 2),
                     "detail_kinds": shares(kinds["func_detail"], 2), "world_kinds": shares(kinds["world"], 2),
                     "covered_faces": covered(m, B)}}
    R["trims"] = trims(m, B)
    R["ledges"] = ledges(m, s, B)
    R.update(shapes(m, B))
    if len(N):
        cells = set(map(tuple, np.floor(N / 512).astype(int)))
        cm, ck = collections.defaultdict(set), collections.defaultdict(set)
        for b in B:
            for f in m.faces_of(b):
                k = tuple(np.floor(m.f_cen[f] / 512).astype(int))
                if k in cells and not skip_mat(m.mat(f)):
                    cm[k].add(m.mat(f))
                    ck[k].add(m.mat(f).split("/")[0])
        R["materials_per_512"] = {"materials": med([len(cm[k]) for k in cells if cm[k]]), "folders": med([len(ck[k]) for k in cells if ck[k]])}
    return R


def covered(m, B):
    """Axis faces hidden behind another brush's face on the same plane: nodraw or textured?"""
    idx = collections.defaultdict(list)
    for b in B:
        for f in m.faces_of(b):
            n = m.f_n[f]
            ax = int(np.argmax(np.abs(n)))
            if abs(abs(n[ax]) - 1) < 1e-3:
                idx[(ax, 1 if n[ax] > 0 else -1, rnd(m.corners(f)[0, ax], 0))].append(f)
    out = C()
    for (ax, sg, c), lst in idx.items():
        opp = idx.get((ax, -sg, c), [])
        o = [k for k in range(3) if k != ax]
        R = np.array([[m.corners(j)[:, o[0]].min(), m.corners(j)[:, o[0]].max(), m.corners(j)[:, o[1]].min(), m.corners(j)[:, o[1]].max()] for j in opp]).reshape(-1, 4)
        for f in lst:
            p = m.corners(f)
            r = (p[:, o[0]].min(), p[:, o[0]].max(), p[:, o[1]].min(), p[:, o[1]].max())
            a = max((r[1] - r[0]) * (r[3] - r[2]), 1e-6)
            cov = 0.0
            if len(R):
                ox = np.clip(np.minimum(R[:, 1], r[1]) - np.maximum(R[:, 0], r[0]), 0, None)
                oy = np.clip(np.minimum(R[:, 3], r[3]) - np.maximum(R[:, 2], r[2]), 0, None)
                cov = (ox * oy).sum() / a
            st = "hidden" if cov > 0.98 else ("part" if cov > 0.02 else "free")
            mt = m.mat(f)
            out[st + ("_nodraw" if "nodraw" in mt else ("_tool" if mt.startswith("tools/") else "_textured"))] += 1
    res = {}
    for st in ("hidden", "free"):
        tot = sum(v for k, v in out.items() if k.startswith(st))
        res[st] = {"n": tot, "nodraw": round(out[st + "_nodraw"] / max(1, tot), 2), "textured": round(out[st + "_textured"] / max(1, tot), 2)}
    return res


def trims(m, B):
    big = [b for b in B if np.sort(m.b_hi[b] - m.b_lo[b])[1] > 48]
    blo, bhi = m.b_lo[big], m.b_hi[big]
    sizes, mats, cls, dirs, vs = C(), C(), C(), C(), C()
    for b in B:
        d = m.b_hi[b] - m.b_lo[b]
        ds = np.sort(d)
        if not (ds[0] <= 16 and ds[1] <= 32 and ds[2] >= 64) or not m.b_axis[b]:
            continue
        touch = np.where(np.all((blo <= m.b_hi[b] + 0.5) & (bhi >= m.b_lo[b] - 0.5), axis=1))[0]
        touch = [big[t] for t in touch if big[t] != b]
        if not touch:
            continue
        mat = C(m.mat(f) for f in m.faces_of(b) if not skip_mat(m.mat(f))).most_common(1)[0][0]
        tm = C()
        for f in m.faces_of(touch[0]):
            if not skip_mat(m.mat(f)):
                tm[m.mat(f)] += m.f_area[f]
        tmat = tm.most_common(1)[0][0] if tm else ""
        sizes["%gx%g" % (rnd(ds[0]), rnd(ds[1]))] += 1
        mats[mat] += 1
        cls[m.b_cls[b]] += 1
        dirs["vertical" if int(np.argmax(d)) == 2 else "horizontal"] += 1
        vs["same" if mat == tmat else ("same folder" if mat.split("/")[0] == tmat.split("/")[0] else "other")] += 1
    return {"n": sum(sizes.values()), "sections_top": top(sizes, 8), "materials_top": top(mats, 8, short=True),
            "detail_share": round(cls["func_detail"] / max(1, sum(cls.values())), 2), "direction": dict(dirs), "vs_wall": dict(vs)}


def ledges(m, s, B):
    blo, bhi = m.b_lo[B], m.b_hi[B]
    proj, hgt, where = C(), C(), C()
    zs = []
    for b in B:
        d = m.b_hi[b] - m.b_lo[b]
        if d[2] > 32 or max(d[0], d[1]) < 96 or min(d[0], d[1]) > 32 or not m.b_axis[b]:
            continue
        ax = 0 if d[0] < d[1] else 1
        touch = np.all((blo <= m.b_hi[b] + 0.5) & (bhi >= m.b_lo[b] - 0.5), axis=1)
        wall = touch & ((bhi[:, 2] - blo[:, 2]) >= 96) & ((bhi[:, ax] <= m.b_lo[b][ax] + 0.5) | (blo[:, ax] >= m.b_hi[b][ax] - 0.5))
        if not wall.any():
            continue
        j = np.where(wall)[0][0]
        side = 1 if bhi[j, ax] <= m.b_lo[b][ax] + 0.5 else -1
        c = (m.b_lo[b] + m.b_hi[b]) / 2
        c[ax] += side * (d[ax] / 2 + 2)
        t, _, _ = s.ray((c[0], c[1], m.b_lo[b][2] - 1), (0, 0, -1), 4096)
        proj[rnd(d[ax])] += 1
        hgt[rnd(d[2])] += 1
        if t is not None:
            zs.append(t)
            where["skirting" if t <= 8 else ("rail 8-96" if t < 96 else ("band 96-256" if t < 256 else "cornice 256+"))] += 1
    return {"n": sum(proj.values()), "stand_out_top": top(proj, 5), "tall_top": top(hgt, 5), "kinds": dict(where), "over_ground": med(zs)}


def shapes(m, B):
    cham, bev, cyl, cylr, yaws, pitch, slab, slab2 = [], [], C(), [], C(), C(), C(), C()
    for b in B:
        fs = list(m.faces_of(b))
        vert = [f for f in fs if abs(m.f_n[f][2]) < 0.01]
        if len(vert) >= 8:
            cyl[len(vert)] += 1
            cylr.append(max(m.b_hi[b][0] - m.b_lo[b][0], m.b_hi[b][1] - m.b_lo[b][1]) / 2)
        has_ax = any(abs(abs(m.f_n[g]).max() - 1) < 1e-3 for g in vert)
        for f in vert:
            if abs(abs(m.f_n[f]).max() - 1) > 1e-3:
                a = math.degrees(math.atan2(m.f_n[f][1], m.f_n[f][0])) % 90
                yaws[rnd(a, 1)] += 1
                if abs(a - 45) < 0.5 and len(vert) < 8 and has_ax:
                    hz = m.corners(f)[:, :2]
                    cham.append(float(np.linalg.norm(hz.max(axis=0) - hz.min(axis=0))))
        flo = any(m.f_n[g][2] > 0.7 for g in fs)
        for f in fs:
            nz = abs(m.f_n[f][2])
            if 0.01 < nz < 0.99:
                p = math.degrees(math.asin(min(1.0, nz)))
                pitch[rnd(p)] += 1
                if abs(p - 45) < 0.5 and flo and vert:
                    bev.append(float(np.ptp(m.corners(f)[:, 2])) * math.sqrt(2))
        d = m.b_hi[b] - m.b_lo[b]
        if m.b_axis[b] and d[2] >= 96 and max(d[0], d[1]) >= 3 * min(d[0], d[1]):
            th = rnd(min(d[0], d[1]))
            slab[th] += 1
            ax = 0 if d[0] < d[1] else 1
            big = [f for f in fs if abs(m.f_n[f][ax]) > 0.99]
            if len(big) == 2 and all(not skip_mat(m.mat(f)) for f in big):
                slab2[th] += 1
    return {"chamfers": {"n": len(cham), "width_top": top(C(rnd(w) for w in cham), 6)},
            "bevels": {"n": len(bev), "slant_top": top(C(rnd(w) for w in bev), 5)},
            "round": {"n": sum(cyl.values()), "sides_top": top(cyl, 6), "radius": med(cylr)},
            "wall_angles_top": top(yaws, 8), "slope_pitch_top": top(pitch, 8),
            "slabs": {"thickness_top": top(slab, 6), "both_faces_textured_top": top(slab2, 5)}}
