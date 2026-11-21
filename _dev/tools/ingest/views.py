"""Living City map ingestion, part "views": candidate pictures, scored by their pixels without looking at them,
and the best drawn at 800x520 with map_view.render, plus one small contact sheet.

    run(m, s, out_dir, n_eye=6, sections=None) -> list of pictures (file, where, view, scores)

The scene is built here from the parsed map (play space only: no hidden objects, no skybox room; displacements
wound the engine's way; props as boxes of their true size, lampposts and poles drawn thin, trees as a trunk and a
canopy) and handed to map_view.render in place of its own reading. Candidates: two overviews from above, a
cut-away over the busiest knot of props, and eye-level views from AI nodes spread over the map, each turned to
the longest clear way with the most props in sight. A candidate is drawn small and scored: plenty of edges (things
to see) and props in view are good; much sky, much darkness or one flat colour filling the frame (a wall at the
nose) are bad.
"""
import math
import os
import shutil
import tempfile

import numpy as np

from .common import C, rnd, short, model_box, POLES, TREES, node_points
from . import vmf

mv = vmf.mv
NOT_DRAWN = ("trigger_", "func_areaportal", "func_dustcloud", "func_precipitation", "func_occluder", "func_clip_vphysics",
             "func_viscluster", "func_ladder", "env_", "func_vehicleclip", "func_smokevolume")
SMALL = ("info_target", "env_sprite", "point_spotlight", "logic_relay", "env_spark", "env_smokestack", "env_fire")
COMPASS = ("east", "north-east", "north", "north-west", "west", "south-west", "south", "south-east")


def scene(m):
    polys, lights, ropes = [], [], {}
    for b in range(len(m.b_owner)):
        if not m.play_brush(b) or m.b_cls[b].startswith(NOT_DRAWN):
            continue
        for f in m.faces_of(b):
            mat = m.mat(f)
            if m.f_disp[f] >= 0:
                g = m.disp_grid(m.f_disp[f])
                if not g.size:
                    continue
                col, al = mv.colour_of(mat), m.disps[m.f_disp[f]].alphas / 255.0
                n = g.shape[0] - 1
                for i in range(n):
                    for j in range(n):
                        c = tuple(int(col[k] * (1 - 0.25 * al[i, j])) for k in range(3))
                        polys.append(([tuple(g[i, j]), tuple(g[i + 1, j]), tuple(g[i + 1, j + 1]), tuple(g[i, j + 1])], c, False))
                continue
            if mat in mv.SKIP or (mat.startswith("tools/") and "toolsblack" not in mat):
                continue
            polys.append(([tuple(p) for p in m.corners(f)], mv.colour_of(mat), any(k in mat for k in mv.SEE_THROUGH)))
    marks = []
    for e in m.ents:
        if not m.play_ent(e) or e.origin is None or e.brushes:
            continue
        pos, cls = tuple(e.origin), e.cls
        if cls in ("move_rope", "keyframe_rope"):
            ropes[e.name] = (pos, e.kv.get("nextkey"), float(e.kv.get("slack", "25") or 25))
            continue
        if cls in ("light", "light_spot"):
            l = (mv.nums(e.kv.get("_light", "255 255 255 200")) + [255, 255, 255, 200])[:4]
            aim = None
            if cls == "light_spot":
                yw, pt = math.radians(e.angles[1]), math.radians(float(e.kv.get("pitch", "-90") or -90))
                aim = ((math.cos(yw) * math.cos(pt), math.sin(yw) * math.cos(pt), math.sin(pt)), math.cos(math.radians(float(e.kv.get("_cone", "45") or 45))))
            lights.append((pos, (l[0] / 255.0, l[1] / 255.0, l[2] / 255.0), l[3], aim))
            marks.append((pos, (255, 250, 170), 6, 6))
            continue
        col = next((c for key, c in mv.MARKS if cls.startswith(key)), None)
        if col is None:
            continue
        bb = model_box(e.model) if e.model.endswith(".mdl") else None
        sm = short(e.model)
        if bb and cls.startswith("prop_") and cls != "prop_ragdoll":
            if any(t in sm for t in POLES):      # (a lamppost or pole: thin, with its arm at the top)
                polys += [(vs, col, None) for vs in mv.turned_box(pos, (-4, -4, bb[2], 4, 4, bb[5]), e.angles[1])]
                polys += [(vs, col, None) for vs in mv.turned_box(pos, (-3, bb[1], bb[5] - 14, 3, bb[4], bb[5] - 6), e.angles[1])]
            elif any(t in sm for t in TREES):      # (a tree: a trunk and a smaller canopy, not one big box)
                h, w = bb[5], max(bb[3] - bb[0], bb[4] - bb[1]) * 0.3
                o = pos
                polys += [(vs, (96, 72, 48), None) for vs in mv.box_faces((o[0] - 6, o[1] - 6, o[2], o[0] + 6, o[1] + 6, o[2] + h * 0.55))]
                polys += [(vs, (78, 108, 58), None) for vs in mv.box_faces((o[0] - w, o[1] - w, o[2] + h * 0.45, o[0] + w, o[1] + w, o[2] + h * 0.9))]
            else:
                polys += [(vs, col, None) for vs in mv.prop_faces(pos, bb, e.angles[1], model=e.model)]
        else:
            small = cls in SMALL
            marks.append((pos, col, 5 if small else 14, 10 if small else 14 if cls == "prop_ragdoll" else 56))
    for name, (a, nxt, slack) in ropes.items():
        if nxt in ropes:
            b = ropes[nxt][0]
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2 - min(60.0, slack * 0.6))
            for p, q in ((a, mid), (mid, b)):
                for dx, dy, dz in ((0, 0, 1.5), (1.5, 1.5, 0)):
                    polys.append(([(p[0] - dx, p[1] - dy, p[2] - dz), (p[0] + dx, p[1] + dy, p[2] + dz), (q[0] + dx, q[1] + dy, q[2] + dz),
                                   (q[0] - dx, q[1] - dy, q[2] - dz)], (30, 28, 26), None))
    for (x, y, z), col, r, h in marks:
        polys += [(vs, col, None) for vs in mv.box_faces((x - r, y - r, z, x + r, y + r, z + h))]
    return polys, lights


class Painter:
    """Draws with map_view.render, culling the scene to what an eye can see first (fast small renders)."""

    def __init__(self, m, polys, lights):
        self.m, self.polys, self.lights = m, polys, lights
        cen, rad = [], []
        for v, _, _ in polys:
            a = np.asarray(v, dtype=float)
            c = a.mean(axis=0)
            cen.append(c)
            rad.append(float(np.sqrt(((a - c) ** 2).sum(axis=1)).max()))
        self.cen, self.rad = np.array(cen).reshape(-1, 3), np.array(rad)
        self.L = np.array([l[0] for l in lights]).reshape(-1, 3)

    def draw(self, out, size, title="", reach=None, **kw):
        polys, lights = self.polys, self.lights
        if kw.get("eye") is not None:
            e = np.asarray(kw["eye"], dtype=float)
            yw = math.radians(kw.get("yaw", 0.0))
            fwd = np.array([math.cos(yw), math.sin(yw), 0.0])
            rel = self.cen - e
            keep = (np.hypot(rel[:, 0], rel[:, 1]) - self.rad < (reach or 3000)) & (rel @ fwd + self.rad > -32)
            polys = [self.polys[i] for i in np.nonzero(keep)[0]]
            lk = np.hypot(self.L[:, 0] - e[0], self.L[:, 1] - e[1]) < (reach or 3000) if len(self.L) else []
            lights = [l for l, k in zip(self.lights, lk) if k]
        sc = (polys, lights)
        old = mv.scene
        mv.scene = lambda path: sc
        try:
            mv.render(self.m.path, out, size=size, title=title, **kw)
        except SystemExit:
            return None
        finally:
            mv.scene = old
        return out


def stats(path):
    from PIL import Image
    a = np.asarray(Image.open(path).convert("RGB")).astype(int)
    sky = ((abs(a[..., 0] - 120) < 12) & (abs(a[..., 1] - 150) < 12) & (abs(a[..., 2] - 185) < 14)).mean()
    dark = (a.sum(-1) < 90).mean()
    edges = (np.abs(np.diff(a, axis=1)).sum(-1) > 40).mean() + (np.abs(np.diff(a, axis=0)).sum(-1) > 40).mean()
    q = a // 24
    _, cnt = np.unique(q[..., 0] * 10000 + q[..., 1] * 100 + q[..., 2], return_counts=True)
    return {"sky": round(float(sky), 2), "dark": round(float(dark), 2), "edges": round(float(edges), 3), "modal": round(float(cnt.max() / q[..., 0].size), 2)}


def score(st, props):
    pen = max(0, st["sky"] - 0.3) * 3 + max(0, st["dark"] - 0.35) * 2 + max(0, st["modal"] - 0.4) * 2
    return round(st["edges"] * 4 + 0.03 * min(props, 12) - pen, 3)


def compass(yaw):
    return COMPASS[int(((yaw % 360) + 22.5) // 45) % 8]


def run(m, s, out_dir, n_eye=6, sections=None, log=print):
    os.makedirs(out_dir, exist_ok=True)
    polys, lights = scene(m)
    P = Painter(m, polys, lights)
    N = node_points(m)
    props = [(e.origin, short(e.model)) for e in m.ents if m.play_ent(e) and e.cls.startswith("prop_") and e.origin is not None]
    PP = np.array([p for p, _ in props]).reshape(-1, 3)
    scapes = [(e.origin, e.kv.get("soundscape", "")) for e in m.ents if m.play_ent(e) and e.cls.startswith("env_soundscape") and e.origin is not None]
    base = N if len(N) else (PP if len(PP) else m.f_cen)
    lo, hi = np.percentile(base, 3, axis=0), np.percentile(base, 97, axis=0)
    box = (rnd(lo[0] - 768), rnd(lo[1] - 768), rnd(hi[0] + 768), rnd(hi[1] + 768))
    pics = [{"kind": "overview", "file": "01_overview_sw.png", "view": {"iso": "SW", "box": box}, "where": "the whole map from the south-west"},
            {"kind": "overview", "file": "02_overview_ne.png", "view": {"iso": "NE", "box": box}, "where": "the same from the north-east"}]
    tmp = tempfile.mkdtemp(prefix="lc_views_")
    try:
        pics += cutaway(m, s, PP, box)
        pics += eyes(m, s, P, N, PP, props, scapes, tmp, n_eye, log)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    for k, p in enumerate(pics):
        if p["kind"] != "overview":
            p["file"] = "%02d_%s.png" % (k + 1, p["kind"])
    if sections:
        pics += cuts(s, sections, len(pics))
    done = []
    for p in pics:
        f = os.path.join(out_dir, p["file"])
        if p["kind"] == "section":
            from .sections import draw_cut
            draw_cut(s, *p["cut"], path=f, title=p["title"])
        else:
            kw = dict(p["view"])
            if "eye" in kw:
                kw["eye"] = tuple(kw["eye"])
            if "box" in kw:
                kw["box"] = tuple(kw["box"])
            if not P.draw(f, (800, 520), title=p["file"][:-4].replace("_", " ") + "  " + p["where"], reach=5000 if "eye" in kw else None, **kw):
                continue
        done.append(p)
        log("  drew %s" % p["file"])
    sheet([os.path.join(out_dir, p["file"]) for p in done], os.path.join(out_dir, "sheet.png"))
    return done


def cutaway(m, s, PP, box, G=768.0):
    cells = C()
    for p in PP:
        if box[0] <= p[0] <= box[2] and box[1] <= p[1] <= box[3]:
            cells[(int(p[0] // G), int(p[1] // G))] += 1
    if not cells:
        return []
    k, n = cells.most_common(1)[0]
    A = np.array([p for p in PP if (int(p[0] // G), int(p[1] // G)) == k])
    cx, cy, fz = A[:, 0].mean(), A[:, 1].mean(), float(np.percentile(A[:, 2], 25))
    covered = sum(1 for p in A[:12] if not s.open_above(p[0], p[1], p[2] + 8)[0])
    cut = rnd(fz + 190) if covered >= min(len(A), 12) / 2 else None
    return [{"kind": "cutaway" if cut else "block", "view": {"iso": "SW", "box": (rnd(cx - 900), rnd(cy - 900), rnd(cx + 900), rnd(cy + 900)), "cut": cut},
             "where": "the busiest knot of props (%d near %d %d) from the south-west%s" % (n, cx, cy, ", cut at %d" % cut if cut else "")}]


def eyes(m, s, P, N, PP, props, scapes, tmp, n_eye, log):
    if not len(N):
        return []
    rng = np.random.default_rng(1)
    pick = [int(rng.integers(len(N)))]
    dmin = np.linalg.norm(N[:, :2] - N[pick[0], :2], axis=1)
    while len(pick) < min(70, len(N)):
        j = int(np.argmax(dmin))
        pick.append(j)
        dmin = np.minimum(dmin, np.linalg.norm(N[:, :2] - N[j, :2], axis=1))
    cands = []
    for j in pick:
        p = N[j]
        fz, _ = s.floor(p[0], p[1], p[2] + 24, 256)
        if fz is None:
            continue
        e = np.array([p[0], p[1], fz + 64])
        out = s.open_above(e[0], e[1], e[2])[0]
        best = None
        for yaw in range(0, 360, 45):
            d = np.array([math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0.0])
            run = s.ray(e, d, 2000)[0] or 2000.0
            if run < (384 if out else 224):
                continue
            seen = 0
            if len(PP):
                v = PP[:, :2] - e[:2]
                dist = np.linalg.norm(v, axis=1)
                cos = (v @ d[:2]) / np.maximum(dist, 1)
                seen = int(((dist > 64) & (dist < min(run, 1200)) & (cos > 0.7) & (np.abs(PP[:, 2] - fz) < 200)).sum())
            sc = min(run, 1500) / 1500 + 0.08 * min(seen, 12)
            if not best or sc > best[0]:
                best = (sc, yaw, run, seen)
        if best:
            cands.append({"eye": [rnd(x) for x in e], "yaw": best[1], "run": rnd(best[2]), "props": best[3], "out": bool(out), "pre": best[0]})
    cands.sort(key=lambda c: -c["pre"])
    scored = []
    for i, c in enumerate(cands[:36]):
        f = os.path.join(tmp, "c%d.png" % i)
        if P.draw(f, (200, 130), eye=tuple(c["eye"]), yaw=c["yaw"], pitch=3):
            c.update(stats(f))
            c["score"] = score(c, c["props"])
            scored.append(c)
    scored.sort(key=lambda c: -c["score"])
    outz = [c["eye"][2] for c in cands if c["out"]]
    gz = np.percentile(outz, 30) + 48 if outz else -1e9
    for c in scored:
        c["scape"] = min(scapes, key=lambda q: float(np.sum((q[0] - np.array(c["eye"])) ** 2)))[1] if scapes else ""
    fin = []
    for want_out, per_scape in ((True, 2), (False, 2), (False, 99)):      # (outdoors at ground level first; places spread)
        for c in scored:
            if len(fin) >= (n_eye // 2 if want_out else n_eye):
                break
            if c in fin or (want_out and not (c["out"] and c["eye"][2] <= gz)):
                continue
            if any(np.linalg.norm(np.array(c["eye"][:2]) - np.array(q["eye"][:2])) < 768 for q in fin):
                continue
            if sum(q["scape"] == c["scape"] for q in fin) >= per_scape:
                continue
            fin.append(c)
    log("  views: %d candidates scored, %d chosen" % (len(scored), len(fin)))
    res = []
    for c in fin:
        e = np.array(c["eye"], dtype=float)
        near = ""
        if len(PP):
            d = np.linalg.norm(PP - e, axis=1)
            fwd = np.array([math.cos(math.radians(c["yaw"])), math.sin(math.radians(c["yaw"])), 0])
            ahead = [props[i][1] for i in np.argsort(d) if d[i] < 900 and (PP[i] - e) @ fwd > 0][:40]
            near = ", ".join(k for k, _ in C(ahead).most_common(3))
        sc = c["scape"]
        where = "eye level %s, looking %s (eye %d %d %d, yaw %d)%s%s" % ("outdoors" if c["out"] else "indoors", compass(c["yaw"]), c["eye"][0], c["eye"][1], c["eye"][2],
                                                                     c["yaw"], ", near " + near if near else "", "; soundscape " + sc if sc else "")
        res.append({"kind": "out" if c["out"] else "in", "view": {"eye": c["eye"], "yaw": c["yaw"], "pitch": 3}, "where": where,
                    "scores": {k: c[k] for k in ("score", "sky", "dark", "edges", "modal", "props", "run")}})
    return res


def cuts(s, sec, k):
    out = []
    st = (sec.get("streets") or {}).get("examples") or []
    if st:
        q = st[0]
        axis = 90 if q["axis"] == "x" else 0      # (a cut along x runs across a street that runs north)
        out.append({"kind": "section", "file": "%02d_street_section.png" % (k + 1), "cut": (q["x"], q["y"], axis, q["z"]),
                    "title": "street cut at x %s y %s: road %s, kerbs %s, wall to wall %s" % (q["x"], q["y"], q.get("road"), "/".join(str(v) for v in q.get("kerb", [])), q["W"]),
                    "where": "a true cut across the street at x %s y %s (along %s)" % (q["x"], q["y"], q["axis"])})
    ch = ((sec.get("channels") or {}).get("examples") or {}).get("open") or []
    if ch:
        q = ch[0]
        out.append({"kind": "section", "file": "%02d_channel_section.png" % (k + 1 + len(out)), "cut": (q["x"], q["y"], q["axis"], q["z0"]),
                    "title": "channel cut at x %s y %s: water %s" % (q["x"], q["y"], q["water"]),
                    "where": "a true cut across the channel at x %s y %s" % (q["x"], q["y"])})
    return out


def sheet(files, out, across=4, scale=4):
    from PIL import Image, ImageDraw
    ims = [Image.open(f).convert("RGB") for f in files if os.path.exists(f)]
    if not ims:
        return None
    w, h = 800 // scale, 520 // scale
    down = (len(ims) + across - 1) // across
    page = Image.new("RGB", (w * across, h * down), (20, 20, 24))
    for k, im in enumerate(ims):
        t = im.resize((w, h))
        d = ImageDraw.Draw(t)
        d.rectangle((0, 0, 22, 12), fill=(0, 0, 0))
        d.text((3, 1), str(k + 1), fill=(255, 255, 0))
        page.paste(t, ((k % across) * w, (k // across) * h))
    page.save(out)
    return out
