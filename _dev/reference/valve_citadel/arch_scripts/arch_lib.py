"""Parse an old-format VMF (plane points only) into brushes with faces, for the Combine architecture study.
Valve's files are data: read as text only."""
import math
import os
import pickle
import re
import sys

import numpy as np

sys.path.insert(0, "/home/user/LivingCity-RP/_dev/tools")
from map_lint import corners_from_planes  # noqa: E402

CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cache")
COMBINE_NUMS = {"063", "072", "076", "077", "078", "090", "091", "101"}
STRUCT_CLASSES = {"world", "func_detail", "func_brush", "func_wall", "func_lod", "func_illusionary", "func_wall_toggle"}
DOOR_CLASSES = {"func_door", "func_door_rotating", "func_movelinear"}


def mclass(m):
    m = m.lower()
    if m.startswith("tools/"):
        return "tools"
    if m.startswith("skybox/") or "/sky_" in m or m.startswith("sky"):
        return "sky"
    if m.startswith("lights/") or "glow" in m:
        return "light"
    if "combine" in m or "citadel" in m or "com_shield" in m or "comshield" in m:
        return "combine"
    mm = re.match(r"metal/metalwall(\d\d\d)", m)
    if mm and mm.group(1) in COMBINE_NUMS:
        return "combine"
    if m.startswith(("dev/", "vgui/")):
        return "dev"
    if m.startswith(("concrete/", "plaster/", "brick/", "building_template/", "stone/", "wood/", "tile/", "glass/glasswindow", "buildings/")):
        return "old"
    if m.startswith("nature/"):
        return "nature"
    return "other"


def nums(t):
    return [float(x) for x in t.replace("(", " ").replace(")", " ").split()]


def blocks(text, start, end):
    """Yield (name, body_start, body_end, depth_of_name) for blocks directly inside text[start:end]."""
    i = start
    n = end
    while i < n:
        m = re.compile(r"\n(\t*)([A-Za-z_]+)\s*\n\t*\{").search(text, i, n)
        if not m:
            return
        d = 1
        j = m.end()
        while d and j < n:
            c = text[j]
            if c == "{":
                d += 1
            elif c == "}":
                d -= 1
            j += 1
        yield m.group(2), m.end(), j - 1, len(m.group(1))
        i = j


def order_face(pts, n):
    P = np.array(pts)
    c = P.mean(0)
    a = np.array([1.0, 0, 0]) if abs(n[0]) < 0.9 else np.array([0, 1.0, 0])
    u = np.cross(n, a)
    u /= np.linalg.norm(u)
    v = np.cross(n, u)
    ang = np.arctan2((P - c) @ v, (P - c) @ u)
    P = P[np.argsort(ang)]
    area = 0.5 * np.linalg.norm(sum(np.cross(P[i], P[(i + 1) % len(P)]) for i in range(len(P))))
    return P, float(area)


def parse(path):
    text = open(path, errors="replace").read().replace("&i", "1")
    text = "\n" + text
    brushes, ents = [], []
    top = list(blocks(text, 0, len(text)))
    for name, s, e, dep in top:
        if dep != 0:
            continue
        if name == "world":
            _solids(text, s, e, "world", -1, brushes)
        elif name == "entity":
            body = text[s:e]
            keys = {}
            for km in re.finditer(r'\n\t"([^"]+)" "([^"]*)"', body):
                keys.setdefault(km.group(1).lower(), km.group(2))
            ed = re.search(r'\n\teditor\s*\n\t\{(.*?)\n\t\}', body, re.S)
            if ed and '"visgroupshown" "0"' in ed.group(1):
                continue
            eid = len(ents)
            keys["_eid"] = eid
            ents.append(keys)
            _solids(text, s, e, keys.get("classname", ""), eid, brushes)
        # top-level "hidden" blocks are left out
    return brushes, ents


def _solids(text, s, e, cls, eid, out):
    for sm in re.finditer(r"\n\tsolid\s*\n\t\{(.*?)\n\t\}", text[s:e], re.S):
        body = sm.group(1)
        ed = re.search(r'\n\t\teditor\s*\n\t\t\{(.*?)\n\t\t\}', body, re.S)
        if ed and '"visgroupshown" "0"' in ed.group(1):
            continue
        sides = re.findall(r"\n\t\tside\s*\n\t\t\{(.*?)\n\t\t\}", body, re.S)
        planes, mats, disp, uax = [], [], False, []
        for sd in sides:
            pm = re.search(r'"plane" "([^"]+)"', sd)
            mt = re.search(r'"material" "([^"]+)"', sd)
            ua = re.search(r'"uaxis" "([^"]+)"', sd)
            if not pm:
                continue
            planes.append(nums(pm.group(1)))
            mats.append(mt.group(1).lower() if mt else "")
            uax.append(ua.group(1) if ua else "")
            if "dispinfo" in sd:
                disp = True
        b = make_brush(planes, mats, uax)
        if b is None:
            continue
        b["cls"] = cls
        b["eid"] = eid
        b["disp"] = disp
        out.append(b)


def make_brush(planes, mats, uax):
    fc = corners_from_planes(planes)
    if not fc:
        return None
    allp = [p for f in fc if f for p in f]
    if len(allp) < 4:
        return None
    V = np.unique(np.round(np.array(allp), 2), axis=0)
    cen = V.mean(0)
    faces = []
    for pl, mt, f, ua in zip(planes, mats, fc, uax):
        if not f:
            continue
        a, b, c = np.array(pl[0:3]), np.array(pl[3:6]), np.array(pl[6:9])
        n = np.cross(c - a, b - a)
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            continue
        n = n / ln
        d = float(n @ a)
        if n @ cen - d > 0:
            n, d = -n, -d
        P, area = order_face(f, n)
        sc = None
        um = re.search(r"\]\s*([-\d.e]+)", ua)
        if um:
            try:
                sc = float(um.group(1))
            except ValueError:
                sc = None
        faces.append({"mat": mt, "mc": mclass(mt), "n": n, "d": d, "pts": P, "area": area, "scale": sc, "raw": pl})
    if len(faces) < 4:
        return None
    box = tuple(V.min(0)) + tuple(V.max(0))
    kinds = {}
    for f in faces:
        if f["mc"] != "tools":
            kinds[f["mc"]] = kinds.get(f["mc"], 0) + f["area"]
    kind = max(kinds, key=kinds.get) if kinds else "tools"
    return {"faces": faces, "box": box, "V": V, "cen": cen, "kind": kind,
            "N": np.array([f["n"] for f in faces]), "D": np.array([f["d"] for f in faces])}


class Grid:
    def __init__(self, brushes, cell=256):
        self.cell = cell
        self.g = {}
        self.b = brushes
        for i, br in enumerate(brushes):
            x0, y0, z0, x1, y1, z1 = br["box"]
            for gx in range(int(x0 // cell), int(x1 // cell) + 1):
                for gy in range(int(y0 // cell), int(y1 // cell) + 1):
                    for gz in range(int(z0 // cell), int(z1 // cell) + 1):
                        self.g.setdefault((gx, gy, gz), []).append(i)

    def near(self, box, pad=0):
        c = self.cell
        out = set()
        for gx in range(int((box[0] - pad) // c), int((box[3] + pad) // c) + 1):
            for gy in range(int((box[1] - pad) // c), int((box[4] + pad) // c) + 1):
                for gz in range(int((box[2] - pad) // c), int((box[5] + pad) // c) + 1):
                    out.update(self.g.get((gx, gy, gz), ()))
        return out

    def at(self, p):
        c = self.cell
        return self.g.get((int(p[0] // c), int(p[1] // c), int(p[2] // c)), ())


def inside(br, p, eps=0.01):
    return bool((br["N"] @ p - br["D"] <= eps).all())


def solid_occluder(br):
    if br["cls"] not in STRUCT_CLASSES:
        return False
    if br["kind"] == "tools":
        mats = {f["mat"] for f in br["faces"]}
        return any(m in ("tools/toolsnodraw", "tools/toolsblack", "tools/toolsskybox") for m in mats)
    return True


def skybox_ids(brushes, ents):
    cams = [e for e in ents if e.get("classname") == "sky_camera"]
    if not cams:
        return set()
    o = np.array(nums(cams[0].get("origin", "0 0 0")))
    sky = [i for i, b in enumerate(brushes) if any(f["mat"] == "tools/toolsskybox" for f in b["faces"])]
    lo = [-1e9] * 3
    hi = [1e9] * 3
    for i in sky:
        bx = brushes[i]["box"]
        for ax in range(3):
            o1, o2 = [k for k in range(3) if k != ax]
            if bx[o1] <= o[o1] <= bx[o1 + 3] and bx[o2] <= o[o2] <= bx[o2 + 3]:
                if bx[ax] >= o[ax]:
                    hi[ax] = min(hi[ax], bx[ax + 3])
                if bx[ax + 3] <= o[ax]:
                    lo[ax] = max(lo[ax], bx[ax])
    if any(v == -1e9 for v in lo) or any(v == 1e9 for v in hi):
        # fall back: everything within 2048 of the camera
        lo = list(o - 2048)
        hi = list(o + 2048)
    out = set()
    for i, b in enumerate(brushes):
        c = b["cen"]
        if all(lo[k] - 1 <= c[k] <= hi[k] + 1 for k in range(3)):
            out.add(i)
    return out


def load(name, path):
    cp = os.path.join(CACHE, name + ".pkl")
    if os.path.exists(cp) and os.path.getmtime(cp) > os.path.getmtime(path):
        return pickle.load(open(cp, "rb"))
    brushes, ents = parse(path)
    sky = skybox_ids(brushes, ents)
    brushes = [b for i, b in enumerate(brushes) if i not in sky]
    occ = [b for b in brushes if solid_occluder(b)]
    G = Grid(occ)
    for bi, b in enumerate(brushes):
        for f in b["faces"]:
            if f["mc"] in ("tools", "sky"):
                f["vis"] = False
                continue
            p = f["pts"].mean(0) + f["n"] * 0.5
            hid = False
            for j in G.at(p):
                o = occ[j]
                if o is b:
                    continue
                if inside(o, p, 0.01):
                    hid = True
                    break
            f["vis"] = not hid
    data = {"brushes": brushes, "ents": ents, "sky_removed": len(sky)}
    pickle.dump(data, open(cp, "wb"))
    return data


MAPS = {
    "d3_citadel_01": "hl2", "d3_citadel_02": "hl2", "d3_citadel_03": "hl2", "d3_citadel_04": "hl2",
    "d3_citadel_05": "hl2", "d3_breen_01": "hl2", "ep1_intro": "ep1", "ep1_citadel_00": "ep1",
    "ep1_citadel_01": "ep1", "ep1_citadel_02": "ep1", "ep1_citadel_02b": "ep1", "ep1_citadel_03": "ep1",
    "ep1_citadel_04": "ep1", "styleguide_core": "style", "styleguide_destroyed_citadel": "style",
    "d3_c17_10a": "hl2", "d3_c17_10b": "hl2", "ep1_c17_00": "ep1", "ep1_c17_01": "ep1",
}
VALVE = "/tmp/claude-0/-home-user-LivingCity-RP/0fda6aa0-e3c1-5a1c-a472-171bd1a8ac5d/scratchpad/valve"


def path_of(name):
    return os.path.join(VALVE, MAPS[name], name + ".vmf")
