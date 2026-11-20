#!/usr/bin/env python3
"""
Living City: look at a VMF without Hammer (a rough picture, to catch mistakes before a compile)

    python3 map_view.py lc_mod_cistern.vmf --iso --cut 560 --out cistern_iso.png
    python3 map_view.py lc_mod_cistern.vmf --eye 1024 -700 464 --yaw 270 --pitch 10 --out inside.png

It draws every brush face (and displaced ground) from the file's own corner lists, with flat colours
by material, a dark line where two faces meet, and a rough light: the sun where nothing is overhead,
the file's own light entities elsewhere (no shadows). Props and other point entities are drawn as
small coloured posts, since a chat has no models: orange a prop_static, yellow a prop_physics, red a
body, cyan a prop_dynamic, green an NPC, magenta anything named for the game.

This is NOT the game's look. It shows shapes, sizes, what stands where, what is dark.
Needs numpy and Pillow (pip install numpy pillow). Reads only.
"""

import argparse
import math
import re

import numpy as np

KV = re.compile(r'^"([^"]*)"\s+"(.*)"$')


class Block:
    __slots__ = ("name", "kv", "kids", "rows")

    def __init__(self, name):
        self.name, self.kv, self.kids, self.rows = name, {}, [], []


def read(path):
    root = Block("root")
    stack, pending = [root], None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            c = s[0]
            if c == '"':
                m = KV.match(s)
                if m:
                    stack[-1].rows.append((m.group(1), m.group(2)))
                    stack[-1].kv.setdefault(m.group(1), m.group(2))
            elif c == "{":
                b = Block(pending or "?")
                stack[-1].kids.append(b)
                stack.append(b)
                pending = None
            elif c == "}":
                if len(stack) > 1:
                    stack.pop()
            elif not s.startswith("//"):
                pending = s
    return root


def nums(text):
    return [float(x) for x in text.replace("(", " ").replace(")", " ").replace("[", " ").replace("]", " ").split()]


COLOURS = (("toolsblack", (10, 10, 12)), ("com_shield", (90, 210, 255)), ("combine", (62, 78, 100)), ("citadel", (62, 78, 100)), ("toxicslime", (95, 170, 45)),
           ("water", (55, 115, 150)), ("fence", (165, 175, 185)), ("mud", (104, 84, 60)), ("dirt", (112, 92, 66)), ("rock", (110, 104, 96)), ("cliff", (110, 104, 96)),
           ("grass", (88, 112, 62)), ("nature", (104, 90, 66)), ("stair", (158, 156, 150)), ("concretefloor", (138, 138, 132)), ("concreteceiling", (120, 120, 118)),
           ("concrete", (152, 152, 146)), ("brick", (142, 92, 72)), ("woodbeam", (104, 76, 48)), ("wood", (136, 100, 64)), ("metalroof", (118, 104, 92)),
           ("metalpipe", (92, 84, 78)), ("metalhull", (96, 104, 112)), ("metal", (112, 116, 124)), ("tile", (172, 176, 166)), ("stone", (126, 120, 110)),
           ("plaster", (182, 172, 150)), ("glass", (150, 190, 200)), ("decal", (200, 180, 120)))
SKIP = ("tools/toolsskybox", "tools/toolsnodraw", "tools/toolsplayerclip", "tools/toolsareaportal", "tools/toolstrigger", "tools/toolsinvisible", "tools/toolsnpcclip",
        "tools/toolsclip", "tools/toolshint", "tools/toolsskip", "tools/toolsorigin", "tools/toolsoccluder", "tools/toolsinvisibleladder", "tools/toolsblocklight")
SEE_THROUGH = ("fence", "com_shield")
MARKS = (("prop_static", (235, 140, 40)), ("prop_physics", (240, 215, 60)), ("prop_ragdoll", (220, 50, 50)), ("prop_dynamic", (70, 215, 225)), ("npc_", (80, 220, 90)),
         ("info_player", (255, 255, 255)), ("env_fire", (255, 120, 20)))


def colour_of(mat):
    m = mat.lower()
    for key, col in COLOURS:
        if key in m:
            return col
    h = sum(ord(c) for c in m)
    return (90 + h % 70, 90 + (h // 7) % 70, 90 + (h // 13) % 70)


def turned_box(pos, bb, yaw):
    """The faces of a model's own box (x forward, y left, z up) standing at pos, turned by yaw."""
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def w(x, y, z):
        return (pos[0] + x * c - y * s, pos[1] + x * s + y * c, pos[2] + z)
    x1, y1, z1, x2, y2, z2 = bb
    lo = [w(x1, y1, z1), w(x2, y1, z1), w(x2, y2, z1), w(x1, y2, z1)]
    hi = [w(x1, y1, z2), w(x2, y1, z2), w(x2, y2, z2), w(x1, y2, z2)]
    return [hi, lo[::-1]] + [[lo[k], lo[(k + 1) % 4], hi[(k + 1) % 4], hi[k]] for k in range(4)]


def scene(path):
    """Everything to draw: polygons [(corners, colour, see-through)], lights [(place, colour, brightness)], and the sun-less places' roofs."""
    import json
    import os
    root = read(path)
    polys, lights, marks = [], [], []
    facts_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "asset_facts.json")
    facts = json.load(open(facts_path)) if os.path.exists(facts_path) else {}

    def solid(s):
        sides = [k for k in s.kids if k.name == "side"]
        worked = None
        if any(not [k for k in side.kids if k.name == "vertices_plus"] for side in sides):
            worked = from_planes(sides)      # (a file not saved by Hammer++ has no corner lists: work them out)
        for n, side in enumerate(sides):
            mat = side.kv.get("material", "").lower()
            vp = [k for k in side.kids if k.name == "vertices_plus"]
            if vp:
                verts = [tuple(nums(v)) for k, v in vp[0].rows if k == "v"]
            elif worked and worked[n]:
                verts = worked[n]
            else:
                continue
            disp = [k for k in side.kids if k.name == "dispinfo"]
            if disp:
                polys.extend(displaced(verts, disp[0], colour_of(mat)))
                continue
            if mat in SKIP or len(verts) < 3:
                continue
            polys.append((verts, colour_of(mat), any(k in mat for k in SEE_THROUGH)))

    for top in root.kids:
        if top.name == "world":
            for s in top.kids:
                if s.name == "solid":
                    solid(s)
        elif top.name == "entity":
            cls = top.kv.get("classname", "")
            for s in top.kids:
                if s.name == "solid" and cls not in ("func_areaportal", "trigger_multiple", "trigger_once", "func_dustcloud", "func_precipitation"):
                    solid(s)
            if "origin" in top.kv and not any(k.name == "solid" for k in top.kids):
                pos = tuple(nums(top.kv["origin"])[:3])
                if cls in ("light", "light_spot"):
                    l = nums(top.kv.get("_light", "255 255 255 200"))
                    aim = None
                    if cls == "light_spot":      # (a beam: the way it points, and how wide)
                        yw = math.radians(nums(top.kv.get("angles", "0 0 0"))[1])
                        pt = math.radians(float(top.kv.get("pitch", "-90")))
                        aim = ((math.cos(yw) * math.cos(pt), math.sin(yw) * math.cos(pt), math.sin(pt)), math.cos(math.radians(float(top.kv.get("_cone", "45")))))
                    lights.append((pos, (l[0] / 255.0, l[1] / 255.0, l[2] / 255.0), l[3] if len(l) > 3 else 200.0, aim))
                    marks.append((pos, (255, 250, 170), 6, 6))
                    continue
                col = None
                for key, c in MARKS:
                    if cls.startswith(key):
                        col = c
                small = cls in ("info_target", "env_sprite", "point_spotlight", "logic_relay", "env_spark", "env_smokestack")
                if top.kv.get("targetname", "").startswith("lc_") and cls not in ("ambient_generic", "move_rope", "keyframe_rope", "logic_timer", "path_track"):
                    col = (235, 60, 235)
                bb = (facts.get(top.kv.get("model", "").lower()) or {}).get("bbox")
                if col and bb and cls != "prop_ragdoll":      # (a model whose size is known: its own box, turned as it is)
                    for vs in turned_box(pos, bb, nums(top.kv.get("angles", "0 0 0"))[1]):
                        polys.append((vs, col, None))
                elif col:
                    marks.append((pos, col, 5 if small else 14, 10 if small else 14 if cls == "prop_ragdoll" else 56))
    for (x, y, z), col, r, h in marks:
        for vs in box_faces((x - r, y - r, z, x + r, y + r, z + h)):
            polys.append((vs, col, None))      # (None: a marker, which shades nothing under it)
    return polys, lights


def from_planes(sides):
    """Each side's corners, worked out from the planes alone (three points each): where three planes meet inside all the others."""
    planes = []
    for side in sides:
        p = nums(side.kv.get("plane", ""))
        if len(p) < 9:
            return None
        a, b, c = np.array(p[0:3]), np.array(p[3:6]), np.array(p[6:9])
        n = np.cross(c - a, b - a)
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            return None
        n = n / ln
        planes.append((n, float(n @ a)))
    N = np.array([pl[0] for pl in planes])
    D = np.array([pl[1] for pl in planes])
    pts = []
    k = len(planes)
    for i in range(k):
        for j in range(i + 1, k):
            for l in range(j + 1, k):
                M = N[[i, j, l]]
                if abs(np.linalg.det(M)) < 1e-6:
                    continue
                v = np.linalg.solve(M, D[[i, j, l]])
                if (N @ v - D <= 0.05).all() or (N @ v - D >= -0.05).all():
                    pts.append(v)
    out = []
    for n, d in planes:
        on = [v for v in pts if abs(n @ v - d) < 0.05]
        uniq = []
        for v in on:
            if not any(np.linalg.norm(v - w) < 0.05 for w in uniq):
                uniq.append(v)
        if len(uniq) < 3:
            out.append(None)
            continue
        mid = sum(uniq) / len(uniq)
        ax = uniq[0] - mid
        ax = ax / (np.linalg.norm(ax) or 1.0)
        ay = np.cross(n, ax)
        uniq.sort(key=lambda v: math.atan2((v - mid) @ ay, (v - mid) @ ax))
        out.append([tuple(float(x) for x in v) for v in uniq])
    return out


def box_faces(b):
    x1, y1, z1, x2, y2, z2 = b
    return [[(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)], [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
            [(x1, y1, z1), (x2, y1, z1), (x2, y1, z2), (x1, y1, z2)], [(x1, y2, z1), (x1, y2, z2), (x2, y2, z2), (x2, y2, z1)],
            [(x1, y1, z1), (x1, y1, z2), (x1, y2, z2), (x1, y2, z1)], [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)]]


def displaced(verts, disp, col):
    power = int(disp.kv.get("power", "2"))
    n = 2 ** power
    start = nums(disp.kv.get("startposition", "0 0 0"))
    k0 = min(range(len(verts)), key=lambda k: sum((verts[k][a] - start[a]) ** 2 for a in range(3)))
    p0, p1, p3 = verts[k0], verts[(k0 + 1) % 4], verts[(k0 + 3) % 4]
    rows = {b.name: [nums(v) for _, v in b.rows] for b in disp.kids}
    pts = {}
    for i in range(n + 1):
        for j in range(n + 1):
            base = [p0[a] + (p1[a] - p0[a]) * i / n + (p3[a] - p0[a]) * j / n for a in range(3)]
            nr, d = rows["normals"][i][3 * j:3 * j + 3], rows["distances"][i][j]
            pts[(i, j)] = tuple(base[a] + nr[a] * d for a in range(3))
    out = []
    for i in range(n):
        for j in range(n):
            al = rows.get("alphas", [[0] * (n + 1)] * (n + 1))[i][j] / 255.0
            c = tuple(int(col[a] * (1 - 0.25 * al)) for a in range(3))
            out.append(([pts[(i, j)], pts[(i + 1, j)], pts[(i + 1, j + 1)], pts[(i, j + 1)]], c, False))
    return out


def clip(poly, axis, limit, keep_below):
    """The part of a polygon on one side of a plane across an axis."""
    out = []
    for k in range(len(poly)):
        a, b = poly[k], poly[(k + 1) % len(poly)]
        ia = (a[axis] <= limit) if keep_below else (a[axis] >= limit)
        ib = (b[axis] <= limit) if keep_below else (b[axis] >= limit)
        if ia:
            out.append(a)
        if ia != ib:
            t = (limit - a[axis]) / (b[axis] - a[axis])
            out.append(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))
    return out


def render(path, out, eye=None, yaw=0.0, pitch=0.0, fov=90.0, iso=None, cut=None, box=None, size=(1280, 800), title=None):
    """eye/yaw/pitch: a view as a player would have (pitch: degrees DOWN). iso: "NE", "NW", "SE" or "SW", the corner
    looked from, from above. cut: nothing above this height is drawn (to see into roofed places). box: x1 y1 x2 y2,
    only what is in it."""
    from PIL import Image, ImageDraw
    polys, lights = scene(path)
    if box:
        polys = [p for p in polys if all(box[0] - 1 <= v[0] <= box[2] + 1 and box[1] - 1 <= v[1] <= box[3] + 1 for v in p[0])]
    # where nothing is overhead: the highest thing over each 32-unit square
    allv = np.array([v for p in polys for v in p[0]])
    if not len(allv):
        raise SystemExit("nothing to draw")
    mn, mx = allv.min(axis=0), allv.max(axis=0)
    G = 32.0
    gw, gh = int((mx[0] - mn[0]) / G) + 2, int((mx[1] - mn[1]) / G) + 2
    roof = np.full((gw, gh), -1e9)
    for verts, col, thru in polys:
        if thru or thru is None:
            continue
        a = np.array(verts)
        if a[:, 2].max() - a[:, 2].min() > 1.0:      # (only level faces make a roof)
            continue
        i1, i2 = int((a[:, 0].min() - mn[0]) / G + 0.5), int((a[:, 0].max() - mn[0]) / G + 0.5)
        j1, j2 = int((a[:, 1].min() - mn[1]) / G + 0.5), int((a[:, 1].max() - mn[1]) / G + 0.5)
        if i2 > i1 and j2 > j1:
            roof[i1:i2, j1:j2] = np.maximum(roof[i1:i2, j1:j2], a[0, 2])
    if cut is not None:
        clipped = []
        for verts, col, thru in polys:
            v = clip(verts, 2, cut, True)
            if len(v) >= 3:
                clipped.append((v, col, thru))
        polys = clipped
    W, H = size
    if iso:
        az = {"NE": 45, "NW": 135, "SW": 225, "SE": 315}[iso.upper()]
        yaw, pitch = az + 180.0, 35.0
    cy, sy, cp, sp = math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), math.cos(math.radians(pitch)), math.sin(math.radians(pitch))
    fwd = np.array([cy * cp, sy * cp, -sp])
    right = np.array([sy, -cy, 0.0])
    up = np.cross(right, fwd)
    if iso:
        allv = np.array([v for p in polys for v in p[0]])
        cam = np.stack([allv @ right, allv @ up, allv @ fwd], axis=1)
        lo, hi = cam.min(axis=0), cam.max(axis=0)
        scale = min((W - 40) / (hi[0] - lo[0]), (H - 40) / (hi[1] - lo[1]))
        ox, oy = 20 - lo[0] * scale, 20 + hi[1] * scale
        eye_v = np.zeros(3)
    else:
        eye_v = np.array(eye, dtype=float)
        f = (W / 2.0) / math.tan(math.radians(fov) / 2.0)
    zbuf = np.full((H, W), -1e18 if not iso else 1e18)
    face = np.full((H, W), -1, dtype=np.int32)
    world = np.zeros((H, W, 3), dtype=np.float32)
    info = []
    NEAR = 6.0
    for verts, col, thru in polys:
        a = np.array(verts, dtype=float)
        nrm = np.zeros(3)
        for k in range(1, len(a) - 1):
            nrm = nrm + np.cross(a[k] - a[0], a[k + 1] - a[0])
        ln = np.linalg.norm(nrm)
        if ln < 1e-6:
            continue
        nrm /= ln
        if (np.dot(nrm, fwd) if iso else np.dot(nrm, a[0] - eye_v)) > 0:      # (turn it to face the eye)
            nrm = -nrm
        rel = a - eye_v
        c = np.stack([rel @ right, rel @ up, rel @ fwd], axis=1)
        pts = [tuple(c[k]) + tuple(a[k]) for k in range(len(a))]
        if not iso:
            pts = clip6(pts, NEAR)
            if len(pts) < 3:
                continue
        fid = len(info)
        info.append((col, nrm, thru))
        P = np.array(pts)
        if iso:
            sx, syy, dep = P[:, 0] * scale + ox, oy - P[:, 1] * scale, P[:, 2]
        else:
            sx, syy, dep = W / 2.0 + f * P[:, 0] / P[:, 2], H / 2.0 - f * P[:, 1] / P[:, 2], 1.0 / P[:, 2]
        for k in range(1, len(P) - 1):
            tri = (0, k, k + 1)
            x0, x1, x2 = sx[list(tri)]
            y0, y1, y2 = syy[list(tri)]
            den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
            if abs(den) < 1e-9:
                continue
            bx1, bx2 = max(0, int(math.floor(min(x0, x1, x2)))), min(W - 1, int(math.ceil(max(x0, x1, x2))))
            by1, by2 = max(0, int(math.floor(min(y0, y1, y2)))), min(H - 1, int(math.ceil(max(y0, y1, y2))))
            if bx1 > bx2 or by1 > by2:
                continue
            xs, ys = np.meshgrid(np.arange(bx1, bx2 + 1) + 0.5, np.arange(by1, by2 + 1) + 0.5)
            w0 = ((y1 - y2) * (xs - x2) + (x2 - x1) * (ys - y2)) / den
            w1 = ((y2 - y0) * (xs - x2) + (x0 - x2) * (ys - y2)) / den
            w2 = 1.0 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            if thru:
                inside &= ((xs.astype(int) + ys.astype(int)) % 3 == 0)
            d = w0 * dep[0] + w1 * dep[k] + w2 * dep[k + 1]
            zb = zbuf[by1:by2 + 1, bx1:bx2 + 1]
            closer = inside & ((d < zb) if iso else (d > zb))
            if not closer.any():
                continue
            zb[closer] = d[closer]
            face[by1:by2 + 1, bx1:bx2 + 1][closer] = fid
            if iso:
                wp = [w0 * P[0, 3 + q] + w1 * P[k, 3 + q] + w2 * P[k + 1, 3 + q] for q in range(3)]
            else:      # (straight in the world is not straight on the screen: weigh by 1/depth)
                wp = [(w0 * P[0, 3 + q] * dep[0] + w1 * P[k, 3 + q] * dep[k] + w2 * P[k + 1, 3 + q] * dep[k + 1]) / d for q in range(3)]
            wv = world[by1:by2 + 1, bx1:bx2 + 1]
            for q in range(3):
                wv[..., q][closer] = wp[q][closer]
    # light
    cols = np.array([i[0] for i in info] + [(120, 150, 185)], dtype=np.float32)
    nrms = np.array([i[1] for i in info] + [(0, 0, 1)], dtype=np.float32)
    idx = np.where(face < 0, len(info), face)
    base, n = cols[idx], nrms[idx]
    gi = np.clip(((world[..., 0] - mn[0]) / G).astype(int), 0, gw - 1)
    gj = np.clip(((world[..., 1] - mn[1]) / G).astype(int), 0, gh - 1)
    covered = roof[gi, gj] > world[..., 2] + 24
    sun = np.array([-0.35, 0.25, 0.9])
    sun /= np.linalg.norm(sun)
    lit = np.where(covered, 0.10, 0.42 + 0.58 * np.clip(n @ sun, 0, 1))[..., None] * np.ones(3)
    for pos, lc, bright, aim in lights:
        d = np.array(pos, dtype=np.float32) - world
        dist2 = (d * d).sum(axis=2) + 1.0
        dist = np.sqrt(dist2)
        ndl = np.clip((n * d).sum(axis=2) / dist, 0, 1) * 0.8 + 0.2
        add = np.clip(bright * 260.0 / dist2 * ndl, 0, 0.9)
        if aim:
            along = -(d * np.array(aim[0], dtype=np.float32)).sum(axis=2) / dist
            add = add * np.clip((along - aim[1]) / max(1e-3, 1 - aim[1]) * 3, 0, 1)
        lit += add[..., None] * np.array(lc)
    img = np.clip(base * np.clip(lit, 0, 1.25), 0, 255)
    edge = np.zeros((H, W), dtype=bool)
    edge[:, 1:] |= face[:, 1:] != face[:, :-1]
    edge[1:, :] |= face[1:, :] != face[:-1, :]
    img[edge] *= 0.55
    img[face < 0] = (120, 150, 185)
    im = Image.fromarray(img.astype(np.uint8))
    if title:
        ImageDraw.Draw(im).text((8, 6), title, fill=(255, 235, 120))
    im.save(out)
    return out


def clip6(pts, near):
    """Cut a polygon (camera x, y, depth, then its world place) by the plane just in front of the eye."""
    out = []
    for k in range(len(pts)):
        a, b = pts[k], pts[(k + 1) % len(pts)]
        ia, ib = a[2] >= near, b[2] >= near
        if ia:
            out.append(a)
        if ia != ib:
            t = (near - a[2]) / (b[2] - a[2])
            out.append(tuple(a[i] + (b[i] - a[i]) * t for i in range(6)))
    return out


def sheet(pictures, out, across=3):
    """Several pictures on one sheet."""
    from PIL import Image
    ims = [Image.open(p) for p in pictures]
    w, h = ims[0].size
    down = (len(ims) + across - 1) // across
    page = Image.new("RGB", (w * across, h * down), (20, 20, 24))
    for k, im in enumerate(ims):
        page.paste(im, ((k % across) * w, (k // across) * h))
    page.save(out)
    return out


def main():
    ap = argparse.ArgumentParser(description="Draw a VMF roughly, to look at it without Hammer.")
    ap.add_argument("vmf")
    ap.add_argument("--out", default="view.png")
    ap.add_argument("--eye", type=float, nargs=3, metavar=("X", "Y", "Z"), help="look from here, as a player would (eyes are 64 over the floor)")
    ap.add_argument("--yaw", type=float, default=0.0, help="with --eye: the way to look (0 east, 90 north)")
    ap.add_argument("--pitch", type=float, default=0.0, help="with --eye: degrees down")
    ap.add_argument("--fov", type=float, default=90.0)
    ap.add_argument("--iso", choices=["NE", "NW", "SE", "SW"], help="from above, looking from this corner")
    ap.add_argument("--cut", type=float, default=None, help="draw nothing above this height (to see into roofed places)")
    ap.add_argument("--box", type=float, nargs=4, metavar=("X1", "Y1", "X2", "Y2"), help="only what is inside this rectangle")
    ap.add_argument("--size", type=int, nargs=2, default=(1280, 800))
    args = ap.parse_args()
    if not args.eye and not args.iso:
        args.iso = "SW"
    render(args.vmf, args.out, eye=args.eye, yaw=args.yaw, pitch=args.pitch, fov=args.fov, iso=args.iso, cut=args.cut, box=args.box, size=tuple(args.size))
    print("written: " + args.out)


if __name__ == "__main__":
    main()
