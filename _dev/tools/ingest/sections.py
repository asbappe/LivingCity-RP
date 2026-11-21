"""Living City map ingestion, part "sections": the shape of the places people walk, measured at the AI nodes.

    run(m, s) -> dict for measure.json["sections"]   (s: a geom.Solid of the map)

nodes:    floor to ceiling over every node, outdoor share, rooms and corridors from 16 rays at waist height.
streets:  a cut along x and along y through every outdoor node (the earlier helpers' streets.py): wall to wall,
          the floor every 4 units, kerbs (a step of 3 to 20 down, a roadway, a step up again; steps down to the
          road count as the kerb, the last of them), crown (only of a roadway with no step in it), gutter,
          pavements, how tall the walls stand. Examples with a clean roadway come first.
stairs:   flights of 3 or more steps from the tops of brushes; doorways at the doors.
channels: canal-style profiles across the shortest way (channels.py).
draw_cut: a true slice drawn as a picture (dark solid, white air, blue water, pale sky, a grid every 128).
"""
import collections
import math

import numpy as np

from .common import C, dist, top, med, rnd, node_points, model_box
from . import channels

AX = ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0))


def run(m, s, quick=False):
    R = collections.OrderedDict()
    N = node_points(m)
    R["nodes"], outdoor = nodes(m, s, N)
    R["streets"] = streets(m, s, outdoor)
    R["stairs"] = stairs(m)
    R["doorways"] = doorways(m, s)
    R["channels"] = channels.run(m, s, N, limit=80 if quick else 220)
    return R


def _mat(m, f):
    return m.mat(f) if f is not None and f >= 0 else ""


def nodes(m, s, N):
    heights, skyh, out_pts, rooms4 = [], [], [], []
    ins, outs = [], []
    ang = np.linspace(0, 2 * np.pi, 16, endpoint=False)
    dirs = np.stack([np.cos(ang), np.sin(ang), np.zeros(16)], axis=1)
    for p in N:
        fz, _ = s.floor(p[0], p[1], p[2] + 24, 256)
        if fz is None:
            continue
        op, tu = s.open_above(p[0], p[1], fz + 4)
        t = np.array([(s.ray((p[0], p[1], fz + 48), d, 4096)[0] or 4096.0) for d in dirs])
        width, length = np.min(t[:8] + t[8:]), np.max(t[:8] + t[8:])
        if op:
            out_pts.append((p[0], p[1], fz))
            if tu is not None:
                skyh.append(tu + 4)
            outs.append((width, t.max(), np.median(t), (t < 512).mean()))
            continue
        h = tu + 4
        heights.append(h)
        ins.append((width, length, h, t.max()))
        if h < 220:
            w = t[0] + t[8]
            dp = t[4] + t[12]
            if max(w, dp) < 1500:
                rooms4.append((min(w, dp), max(w, dp)))
    corr = [x for x in ins if x[0] < 192 and x[1] > 3 * x[0]]
    room = [x for x in ins if not (x[0] < 192 and x[1] > 3 * x[0])]
    n = len(heights) + len(out_pts)
    R = {"n": int(len(N)), "measured": n, "outdoor_share": round(len(out_pts) / max(1, n), 2),
         "indoor_ceiling": dist(heights, 8, 16), "sky_over_outdoor_floor": med(skyh),
         "corridor_width": dist([x[0] for x in corr], 16, 10), "corridor_ceiling": med([x[2] for x in corr]),
         "room_width": dist([x[0] for x in room], 32, 10), "room_length": dist([x[1] for x in room], 64, 10),
         "room_ceiling": med([x[2] for x in room]),
         "rooms_small": dist([a for a, b in rooms4], 32, 8), "rooms_small_long": dist([b for a, b in rooms4], 32, 8),
         "longest_view_in": med([x[3] for x in ins]), "longest_view_out": med([x[1] for x in outs]),
         "typical_view_out": med([x[2] for x in outs]), "out_blocked_512": round(float(np.mean([x[3] for x in outs])), 2) if outs else None,
         "open_width_out": dist([x[0] for x in outs], 64, 10)}
    return R, out_pts


def streets(m, s, out_pts):
    secs = []
    for (x, y, fz) in out_pts:
        for ax in AX:
            sec = _street(m, s, x, y, fz, np.array(ax))
            if sec:
                secs.append(sec)
    st = [q for q in secs if "road" in q]
    wh = [h for q in secs for h in q["walls"] if h]
    R = {"sections": len(secs), "with_kerbs": len(st),
         "wall_to_wall": dist([q["W"] for q in secs], 64, 14),
         "road_width": dist([q["road"] for q in st], 32, 12),
         "pavement_width": dist([v for q in st for v in (q["pavL"], q["pavR"])], 16, 12),
         "kerb_height": dist([v for q in st for v in q["kerb"]], 1, 8),
         "crown": dist([q["crown"] for q in st if q["crown"] is not None], 2, 8), "gutter": dist([q["gutter"] for q in st], 2, 6),
         "road_mats_top": top(C(q["roadmat"] for q in st), 4, short=True),
         "pavement_mats_top": top(C(q["pavmat"] for q in st if q["pavmat"]), 4, short=True),
         "kerb_mats_top": top(C(q["kerbmat"] for q in st if q.get("kerbmat")), 4, short=True),
         "wall_height": dist(wh, 64, 14),
         "height_over_width": med([min(h for h in q["walls"] if h) / q["W"] for q in secs if all(q["walls"])])}
    mr = med([q["road"] for q in st]) or 0
    good = sorted([q for q in st if all(q["walls"])] or st, key=lambda q: (q["crown"] is None, abs(q["road"] - mr)))      # (a clean road first: not a yard of steps)
    R["examples"] = [{k: q[k] for k in ("x", "y", "z", "axis", "W", "road", "pavL", "pavR", "kerb", "crown", "walls")} for q in good[:4]]
    return R


def _street(m, s, x, y, fz, a):
    o = np.array([x, y, fz + 40])
    tp, fp, _ = s.ray(o, a, 2048)
    tn, fn, _ = s.ray(o, -a, 2048)
    if tp is None or tn is None or fp < 0 or fn < 0:
        return None
    if m.f_n[fp][2] > 0.3 or m.f_n[fn][2] > 0.3 or _mat(m, fp).startswith("tools/") or _mat(m, fn).startswith("tools/"):
        return None
    W = tp + tn
    if W < 128 or W > 2000:
        return None
    start = np.array([x, y, 0.0]) - a * (tn - 2)
    prof, mats = [], []
    for sv in np.arange(0, W - 3, 4):
        q = start + a * sv
        z, f = s.floor(q[0], q[1], fz + 64, 200)
        prof.append(z if z is not None else np.nan)
        mats.append(_mat(m, f))
    prof = np.array(prof)
    if not len(prof) or np.isnan(prof).mean() > 0.2:
        return None
    d = np.diff(prof)
    ups = [i for i in range(len(d)) if not np.isnan(d[i]) and 3 <= abs(d[i]) <= 20]
    best = None
    for i in ups:
        if d[i] >= 0:
            continue      # (a step down from the near pavement into the road)
        for j in ups:
            if j <= i + 16 or d[j] <= 0:
                continue
            if np.nanmax(prof[i + 1:j + 1]) > prof[i] - 2:
                break
            best = (i, j)
            break
        if best:
            break
    if best:      # (steps down to the road, a tread apart: the kerb is the last of them, so the road is only between the kerbs)
        i, j = best
        k = i + 1
        while k < min(j - 16, i + 12):
            if not np.isnan(d[k]) and -20 <= d[k] <= -3:
                i = k
            k += 1
        best = (i, j)
    walls = []
    for sgn, t0 in ((1, tp), (-1, tn)):
        topz = None
        for h in range(64, 1600, 32):
            th, _, _ = s.ray((x, y, fz + h), a * sgn, t0 + 96)
            if th is None:
                break
            topz = h
        walls.append(topz)
    sec = dict(x=rnd(x), y=rnd(y), z=rnd(fz), axis="x" if a[0] else "y", W=rnd(W), walls=walls)
    if best:
        i, j = best
        road = prof[i + 1:j + 1]
        stepped = np.nanmax(np.abs(np.diff(road))) >= 3 if len(road) > 1 else False      # (a step inside: no road's crown, d3_c17_03's square)
        sec.update(road=(j - i) * 4, pavL=i * 4, pavR=rnd(W - (j + 1) * 4), kerb=[rnd(-d[i]), rnd(d[j])],
                   crown=None if stepped else rnd(np.nanmax(road) - (road[0] + road[-1]) / 2), gutter=rnd(road[0] - np.nanmin(road[:6])),
                   roadmat=C(mats[i + 1:j + 1]).most_common(1)[0][0],
                   pavmat=C(mats[:i] + mats[j + 1:]).most_common(1)[0][0] if i > 0 else "")
        kz = (prof[i] + prof[i + 1]) / 2
        _, kf, _ = s.ray(start + a * (i * 4 + 6) + np.array([0, 0, kz]), -a, 12)
        sec["kerbmat"] = _mat(m, kf)
    return sec


def stairs(m):
    tops = [f for f in range(len(m.f_mat)) if m.f_n[f][2] > 0.99 and m.f_disp[f] < 0 and m.play_brush(m.f_brush[f])
            and not m.mat(f).startswith("tools/")]
    if not tops:
        return {"flights": 0}
    TA = np.array([np.r_[m.corners(f).min(axis=0)[:2], m.corners(f).max(axis=0)[:2], m.corners(f)[:, 2].mean()] for f in tops])
    steps = []
    for i in range(len(TA)):
        lo, hi, z = TA[i, 0:2], TA[i, 2:4], TA[i, 4]
        dz = TA[:, 4] - z
        near = (dz >= 3) & (dz <= 24)
        if not near.any():
            continue
        for ax in (0, 1):
            ox = 1 - ax
            ov = np.minimum(TA[:, 2 + ox], hi[ox]) - np.maximum(TA[:, ox], lo[ox])
            cand = near & (ov >= 24)
            tr = TA[:, ax] - lo[ax]
            m1 = cand & (tr >= 6) & (tr <= 40) & (TA[:, ax] <= hi[ax] + 1) & (TA[:, 2 + ax] >= hi[ax] - 1)
            tr2 = hi[ax] - TA[:, 2 + ax]
            m2 = cand & (tr2 >= 6) & (tr2 <= 40) & (TA[:, 2 + ax] >= lo[ax] - 1) & (TA[:, ax] <= lo[ax] + 1)
            steps += [(i, j, rnd(dz[j]), rnd(tr[j])) for j in np.nonzero(m1)[0]]
            steps += [(i, j, rnd(dz[j]), rnd(tr2[j])) for j in np.nonzero(m2)[0]]
    nxt = collections.defaultdict(list)
    for i, j, r, t in steps:
        nxt[i].append((j, r, t))
    flights, seen = [], set()
    for i, j, r, t in steps:
        if (i, j) in seen:
            continue
        chain, cur = [(r, t)], j
        seen.add((i, j))
        while len(chain) <= 60:
            k = [q for q in nxt.get(cur, []) if q[1] == r]
            if not k:
                break
            seen.add((cur, k[0][0]))
            chain.append((k[0][1], k[0][2]))
            cur = k[0][0]
        if len(chain) >= 3:
            flights.append(chain)
    return {"flights": len(flights), "rise_tread_top": [["%gx%g" % k, n] for k, n in C(st for fl in flights for st in fl).most_common(6)],
            "rise": dist([r for fl in flights for r, _ in fl], 1, 8), "steps_per_flight": dist([len(fl) + 1 for fl in flights], 1, 10)}


def doorways(m, s):
    out, models = [], C()
    for e in m.ents:
        if e.cls != "prop_door_rotating" or not m.play_ent(e) or e.origin is None:
            continue
        bb = model_box(e.model)
        models[e.model.split("/")[-1].replace(".mdl", "")] += 1
        if not bb:
            continue
        yaw = math.radians(e.angles[1])
        cy, sy = math.cos(yaw), math.sin(yaw)
        cx, cyy = (bb[0] + bb[3]) / 2, (bb[1] + bb[4]) / 2
        mid = e.origin + np.array([cx * cy - cyy * sy, cx * sy + cyy * cy, 0])
        fz, _ = s.floor(mid[0], mid[1], mid[2] + 16, 128)
        if fz is None:
            continue
        tu, _, _ = s.ray((mid[0], mid[1], fz + 8), (0, 0, 1), 256, inside=False)
        side = np.array([-sy, cy, 0.0])
        ta, _, _ = s.ray((mid[0], mid[1], fz + 48), side, 128, inside=False)
        tb, _, _ = s.ray((mid[0], mid[1], fz + 48), -side, 128, inside=False)
        out.append("%sx%s" % (rnd(ta + tb) if ta and tb else "?", rnd(tu + 8) if tu else "?"))
    return {"doors": sum(models.values()), "models_top": top(models, 5), "openings_top": top(C(out), 6)}


def draw_cut(s, x, y, axis_deg, z0, path, title, smax=768, up=1024, down=64, notes=()):
    """A true cross-section picture, 800x520: across the way the axis runs (axis_deg 0 = east)."""
    from PIL import Image, ImageDraw
    a = math.radians(axis_deg + 90)
    ss, zs, g = s.slice(x, y, math.cos(a), math.sin(a), smax, z0 - down, z0 + up, 4)
    col = {0: (248, 247, 242), 1: (96, 94, 90), 2: (70, 130, 205), 3: (175, 208, 236)}
    img = np.zeros(g.shape + (3,), np.uint8)
    for k, c in col.items():
        img[g == k] = c
    W, H = 800, 520
    page = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(page)
    d.text((8, 4), title, fill=(0, 0, 0))
    top_, bottom, left = 22, H - 18 - 12 * len(notes), 34
    im = Image.fromarray(img[::-1])
    sc = min((W - left - 8) / im.size[0], (bottom - top_) / im.size[1])
    iw, ih = int(im.size[0] * sc), int(im.size[1] * sc)
    x0, y0 = left + (W - left - 8 - iw) // 2, top_ + (bottom - top_ - ih)
    page.paste(im.resize((iw, ih), Image.NEAREST), (x0, y0))
    unit = ih / (up + down)
    for h in range(0, up + 1, 64):
        yy = y0 + ih - int((h + down) * unit)
        for xx in range(x0, x0 + iw, 7):
            d.point((xx, yy), fill=(215, 120, 120) if h % 256 == 0 else (232, 190, 190))
        if h % 128 == 0:
            d.text((2, yy - 6), str(h), fill=(150, 30, 30))
    for sv in range(-smax, smax + 1, 128):
        xx = x0 + int((sv + smax) * unit)
        for yy in range(y0, y0 + ih, 7):
            d.point((xx, yy), fill=(200, 60, 60) if sv == 0 else (236, 205, 205))
    for k, t in enumerate(notes):
        d.text((8, H - 14 - 12 * (len(notes) - 1 - k)), t, fill=(0, 0, 0))
    page.save(path)
    return path
