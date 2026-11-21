"""Living City map ingestion: read a VMF once into arrays that every part shares.

    from ingest import vmf
    m = vmf.load("sdk_d1_trainstation_02.vmf")
    m.ents[0].cls, m.ents[0].kv["origin"], m.ents[0].outputs
    m.mats[m.f_mat[i]], m.f_n[i], m.corners(i), m.f_u[i], m.f_lms[i], m.f_disp[i]

Old Hammer files (editorversion 400) give only three points a side: the corners are worked out here from the
planes. Newer files may carry vertices_plus: those are used as they are. Objects inside a "hidden" block or in a
visgroup turned off are flagged hidden; the 3D skybox room round the sky_camera is found and flagged too. Play
space numbers leave both out (use m.play_ent and the brush flags). Reads only; nothing is ever run from a map.
"""
import itertools
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import map_view as mv      # (the shared tokenizer: one tree of blocks)
from . import sky

EPS = 0.06
SPECIAL = ("!self", "!activator", "!caller", "!player", "!picker", "!pvsplayer", "!speechtarget")


def nums(text):
    return mv.nums(text or "")


class Ent:
    __slots__ = ("i", "cls", "kv", "outputs", "hidden", "vis", "origin", "angles", "brushes", "sky")

    def __init__(self, i, kv, hidden, vis):
        self.i, self.kv, self.hidden, self.vis = i, kv, hidden, vis
        self.cls = kv.get("classname", "").lower()
        self.outputs, self.brushes, self.sky = [], [], False
        o = nums(kv.get("origin", ""))
        self.origin = np.array(o[:3]) if len(o) >= 3 else None
        a = nums(kv.get("angles", "0 0 0"))
        self.angles = (a + [0.0, 0.0, 0.0])[:3]

    @property
    def name(self):
        return self.kv.get("targetname", "")

    @property
    def model(self):
        return self.kv.get("model", "").lower().replace("\\", "/")


def split_output(value):
    """One connections line: target, input, value, delay, times (old files use commas, newer ones ESC)."""
    p = value.split("\x1b") if "\x1b" in value else value.split(",")
    if len(p) < 5:
        p += [""] * (5 - len(p))
    target, inp = p[0].strip(), p[1].strip()
    param = ",".join(p[2:-2]).strip()
    try:
        delay = float(p[-2] or 0)
    except ValueError:
        delay = 0.0
    try:
        times = int(float(p[-1] or -1))
    except ValueError:
        times = -1
    return target, inp, param, delay, times


_TRI = {}


def _triples(k):
    if k not in _TRI:
        _TRI[k] = np.array(list(itertools.combinations(range(k), 3)), dtype=np.int32)
    return _TRI[k]


def _plane(text):
    p = nums(text)
    if len(p) < 9:
        return None
    a, b, c = np.array(p[0:3]), np.array(p[3:6]), np.array(p[6:9])
    n = np.cross(c - a, b - a)
    ln = np.linalg.norm(n)
    if ln < 1e-9:
        return None
    n = n / ln
    return n, float(n @ a)


def _corner_groups(jobs):
    """jobs: [(key, N (k,3), D (k,))]. For each key: (N, D) turned outward and the corners of each plane, or None."""
    out = {}
    byk = {}
    for key, N, D in jobs:
        byk.setdefault(len(D), []).append((key, N, D))
    for k, js in byk.items():
        if k < 4:
            for key, _, _ in js:
                out[key] = None
            continue
        T = _triples(k)
        for s in range(0, len(js), max(1, 200000 // max(1, len(T)))):
            part = js[s:s + max(1, 200000 // max(1, len(T)))]
            N = np.array([j[1] for j in part])
            D = np.array([j[2] for j in part])
            M = N[:, T]
            R = D[:, T]
            det = np.linalg.det(M)
            bi, ti = np.nonzero(np.abs(det) > 1e-6)
            if not len(bi):
                for key, _, _ in part:
                    out[key] = None
                continue
            P = np.linalg.solve(M[bi, ti], R[bi, ti][..., None])[..., 0]
            res = np.einsum("nkj,nj->nk", N[bi], P) - D[bi]
            good = (res <= 0.05).all(axis=1) | (res >= -0.05).all(axis=1)
            bi, P = bi[good], P[good]
            order = np.argsort(bi, kind="stable")
            bi, P = bi[order], P[order]
            starts = np.searchsorted(bi, np.arange(len(part) + 1))
            for b, (key, _, _) in enumerate(part):
                pts = P[starts[b]:starts[b + 1]]
                if len(pts) < 4:
                    out[key] = None
                    continue
                pts = np.unique(np.round(pts, 2), axis=0)
                n, d = N[b].copy(), D[b].copy()
                cen = pts.mean(axis=0)
                flip = (n @ cen - d) > 0      # (outward: the middle of the brush behind every plane)
                n[flip] *= -1
                d[flip] *= -1
                faces = []
                for j in range(k):
                    on = pts[np.abs(pts @ n[j] - d[j]) < EPS]
                    faces.append(_order(on, n[j]) if len(on) >= 3 else None)
                out[key] = (n, d, faces)
    return out


def _order(pts, n):
    """Corners turned round the outward normal (counter-clockwise seen from outside)."""
    mid = pts.mean(axis=0)
    ax = pts[0] - mid
    ax = ax / (np.linalg.norm(ax) or 1.0)
    ay = np.cross(n, ax)
    ang = np.arctan2((pts - mid) @ ay, (pts - mid) @ ax)
    return pts[np.argsort(ang)]


def _shown(block):
    for k in block.kids:
        if k.name == "editor":
            return k.kv.get("visgroupshown", "1") != "0" and k.kv.get("visgroupautoshown", "1") != "0"
    return True


def _vis_ids(block):
    for k in block.kids:
        if k.name == "editor":
            return [v for key, v in k.rows if key == "visgroupid"]
    return []


class Map:
    """Everything read from one VMF. Brushes and faces are parallel arrays (b_*, f_*)."""

    def __init__(self, path):
        self.path = path
        self.name = os.path.basename(path)[:-4].replace("sdk_", "")
        root = mv.read(path)
        self.editorversion, self.world, self.visgroups, self.ents = None, {}, {}, []
        self.vertices_plus = False
        self._solids = []      # (solid block, owner entity index or -1, owner class, hidden)
        for top in root.kids:
            if top.name == "versioninfo":
                self.editorversion = top.kv.get("editorversion")
            elif top.name == "visgroups":
                self._read_visgroups(top)
            elif top.name == "world":
                self.world = {k.lower(): v for k, v in top.kv.items()}
                self._world(top, False)
            elif top.name == "entity":
                self._entity(top, False)
            elif top.name == "hidden":
                for e in top.kids:
                    if e.name == "entity":
                        self._entity(e, True)
                    elif e.name == "world":
                        self._world(e, True)
        self._build()
        sky.find(self)
        self.by_name = {}
        for e in self.ents:
            if e.name:
                self.by_name.setdefault(e.name.lower(), []).append(e.i)

    # ---- reading the tree
    def _read_visgroups(self, block):
        for v in block.kids:
            if v.name == "visgroup":
                self.visgroups[v.kv.get("visgroupid", "")] = v.kv.get("name", "")
                self._read_visgroups(v)

    def _world(self, w, hidden):
        for s in w.kids:
            if s.name == "solid":
                self._solids.append((s, -1, "world", hidden or not _shown(s)))
            elif s.name == "hidden":
                for s2 in s.kids:
                    if s2.name == "solid":
                        self._solids.append((s2, -1, "world", True))

    def _entity(self, top, hidden):
        kv = {k.lower(): v for k, v in top.rows[::-1]}      # (the first of a repeated key wins, as in map_view)
        hidden = hidden or not _shown(top)
        e = Ent(len(self.ents), kv, hidden, _vis_ids(top))
        self.ents.append(e)
        for k in top.kids:
            if k.name == "connections":
                e.outputs += [(o,) + split_output(v) for o, v in k.rows]
            elif k.name == "solid":
                self._solids.append((k, e.i, e.cls, hidden or not _shown(k)))
            elif k.name == "hidden":
                for s2 in k.kids:
                    if s2.name == "solid":
                        self._solids.append((s2, e.i, e.cls, True))

    # ---- brushes and faces
    def _build(self):
        jobs, sides_of = [], []
        for si, (s, owner, cls, hid) in enumerate(self._solids):
            sides = [k for k in s.kids if k.name == "side"]
            sides_of.append(sides)
            pl = [_plane(sd.kv.get("plane", "")) for sd in sides]
            if not sides or any(p is None for p in pl):
                continue
            if all(any(k.name == "vertices_plus" for k in sd.kids) for sd in sides):
                self.vertices_plus = True
                continue
            jobs.append((si, np.array([p[0] for p in pl]), np.array([p[1] for p in pl])))
        worked = _corner_groups(jobs)
        mats, mat_i = [], {}
        B = {k: [] for k in ("owner", "cls", "hidden", "lo", "hi", "f0", "f1", "disp", "axis")}
        F = {k: [] for k in ("mat", "n", "d", "c0", "c1", "u", "v", "rot", "lms", "brush", "disp")}
        pts, self.disps, self.bad_brushes = [], [], 0
        npts = 0
        for si, (s, owner, cls, hid) in enumerate(self._solids):
            sides = sides_of[si]
            got = worked.get(si)
            if got is None and sides and all(any(k.name == "vertices_plus" for k in sd.kids) for sd in sides):
                got = self._from_vertices(sides)
            if got is None:
                self.bad_brushes += 1
                continue
            n_arr, d_arr, faces = got
            bi = len(B["owner"])
            allp = np.vstack([f for f in faces if f is not None])
            B["owner"].append(owner); B["cls"].append(cls); B["hidden"].append(hid)
            B["lo"].append(allp.min(axis=0)); B["hi"].append(allp.max(axis=0)); B["f0"].append(len(F["mat"]))
            has_disp, axis = False, True
            for j, sd in enumerate(sides):
                poly = faces[j]
                if poly is None:
                    continue
                mat = sd.kv.get("material", "").lower().replace("\\", "/")
                if mat not in mat_i:
                    mat_i[mat] = len(mats)
                    mats.append(mat)
                F["mat"].append(mat_i[mat]); F["n"].append(n_arr[j]); F["d"].append(d_arr[j])
                F["c0"].append(npts); npts += len(poly); F["c1"].append(npts); pts.append(poly)
                u, v = nums(sd.kv.get("uaxis", "")), nums(sd.kv.get("vaxis", ""))
                F["u"].append(u[:5] if len(u) >= 5 else [0, 0, 0, 0, 0]); F["v"].append(v[:5] if len(v) >= 5 else [0, 0, 0, 0, 0])
                F["rot"].append(float(sd.kv.get("rotation", "0") or 0)); F["lms"].append(float(sd.kv.get("lightmapscale", "16") or 16))
                F["brush"].append(bi)
                if abs(abs(n_arr[j]).max() - 1) > 1e-3:
                    axis = False
                di = [k for k in sd.kids if k.name == "dispinfo"]
                if di:
                    has_disp = True
                    F["disp"].append(len(self.disps))
                    self.disps.append(Disp(len(F["mat"]) - 1, di[0]))
                else:
                    F["disp"].append(-1)
            B["f1"].append(len(F["mat"])); B["disp"].append(has_disp); B["axis"].append(axis)
            if owner >= 0:
                self.ents[owner].brushes.append(bi)
        self.mats = mats
        self.b_owner = np.array(B["owner"], dtype=np.int32)
        self.b_cls = B["cls"]
        self.b_hidden = np.array(B["hidden"], dtype=bool)
        self.b_lo = np.array(B["lo"]).reshape(-1, 3)
        self.b_hi = np.array(B["hi"]).reshape(-1, 3)
        self.b_f0 = np.array(B["f0"], dtype=np.int32)
        self.b_f1 = np.array(B["f1"], dtype=np.int32)
        self.b_disp = np.array(B["disp"], dtype=bool)
        self.b_axis = np.array(B["axis"], dtype=bool)
        self.f_mat = np.array(F["mat"], dtype=np.int32)
        self.f_n = np.array(F["n"]).reshape(-1, 3)
        self.f_d = np.array(F["d"])
        self.f_c0 = np.array(F["c0"], dtype=np.int64)
        self.f_c1 = np.array(F["c1"], dtype=np.int64)
        self.f_u = np.array(F["u"], dtype=float).reshape(-1, 5)
        self.f_v = np.array(F["v"], dtype=float).reshape(-1, 5)
        self.f_rot = np.array(F["rot"])
        self.f_lms = np.array(F["lms"])
        self.f_brush = np.array(F["brush"], dtype=np.int32)
        self.f_disp = np.array(F["disp"], dtype=np.int32)
        self.pts = np.vstack(pts) if pts else np.zeros((0, 3))
        self.f_area = np.zeros(len(self.f_mat))
        self.f_cen = np.zeros((len(self.f_mat), 3))
        for i in range(len(self.f_mat)):
            p = self.pts[self.f_c0[i]:self.f_c1[i]]
            cr = np.cross(p[1:-1] - p[0], p[2:] - p[0]).sum(axis=0)
            self.f_area[i] = np.linalg.norm(cr) / 2
            self.f_cen[i] = p.mean(axis=0)
        self.b_hidden |= np.array([self.ents[o].hidden if o >= 0 else False for o in self.b_owner], dtype=bool)
        self.b_sky = np.zeros(len(self.b_owner), dtype=bool)
        del self._solids

    def _from_vertices(self, sides):
        n_l, d_l, faces = [], [], []
        allv = []
        for sd in sides:
            vp = [k for k in sd.kids if k.name == "vertices_plus"][0]
            allv += [nums(v)[:3] for key, v in vp.rows if key == "v"]
        if len(allv) < 4:
            return None
        cen = np.mean(np.array(allv), axis=0)
        for sd in sides:
            p = _plane(sd.kv.get("plane", ""))
            vp = [k for k in sd.kids if k.name == "vertices_plus"][0]
            v = np.array([nums(x)[:3] for key, x in vp.rows if key == "v"])
            n, d = p
            if n @ cen - d > 0:
                n, d = -n, -d
            n_l.append(n); d_l.append(d)
            faces.append(_order(v, n) if len(v) >= 3 else None)
        return np.array(n_l), np.array(d_l), faces

    # ---- helpers every part uses
    def corners(self, f):
        return self.pts[self.f_c0[f]:self.f_c1[f]]

    def mat(self, f):
        return self.mats[self.f_mat[f]]

    def play_ent(self, e):
        return not e.hidden and not e.sky

    def play_brush(self, b):
        return not self.b_hidden[b] and not self.b_sky[b]

    def faces_of(self, b):
        return range(self.b_f0[b], self.b_f1[b])

    def disp_grid(self, di):
        f = self.disps[di].face
        return self.disps[di].grid(self.corners(f), self.f_n[f])


class Disp:
    """One displacement: its rows as arrays, and the displaced points worked out when first asked."""
    __slots__ = ("face", "power", "elevation", "start", "normals", "distances", "offsets", "alphas", "_grid")

    def __init__(self, face, block):
        self.face = face
        self.power = int(float(block.kv.get("power", "2") or 2))
        self.elevation = float(block.kv.get("elevation", "0") or 0)
        self.start = np.array((nums(block.kv.get("startposition", "0 0 0")) + [0, 0, 0])[:3])
        n = 2 ** self.power + 1
        rows = {b.name: b for b in block.kids}

        def grid(name, width, default):
            b = rows.get(name)
            out = np.full((n, n * width), default, dtype=float)
            if b is not None:
                for key, v in b.rows:
                    if key.startswith("row"):
                        r = int(key[3:])
                        vals = nums(v)
                        if r < n and len(vals) >= n * width:
                            out[r] = vals[:n * width]
            return out.reshape(n, n, width) if width > 1 else out
        self.normals = grid("normals", 3, 0.0)
        self.distances = grid("distances", 1, 0.0)
        self.offsets = grid("offsets", 3, 0.0)
        self.alphas = grid("alphas", 1, 0.0)
        self._grid = None

    def grid(self, corners, normal):
        """(n+1, n+1, 3) points of the displaced surface. Rows run from the start corner to the next corner of the
        engine's winding (clockwise seen from outside), columns to the corner before it."""
        if self._grid is not None:
            return self._grid
        c = np.asarray(corners, dtype=float)
        if len(c) != 4:
            self._grid = np.zeros((0, 0, 3))
            return self._grid
        c = c[::-1]      # (stored counter-clockwise: the engine winds the other way)
        k0 = int(np.argmin(((c - self.start) ** 2).sum(axis=1)))
        p0, p1, p3 = c[k0], c[(k0 + 1) % 4], c[(k0 + 3) % 4]
        n = 2 ** self.power
        t = np.arange(n + 1) / n
        base = p0[None, None] + (p1 - p0)[None, None] * t[:, None, None] + (p3 - p0)[None, None] * t[None, :, None]
        self._grid = base + self.normals * self.distances[..., None] + self.offsets + np.asarray(normal) * self.elevation
        return self._grid


_CACHE = {}


def load(path):
    """Read (once per run) and return the Map."""
    key = os.path.abspath(path)
    if key not in _CACHE:
        _CACHE[key] = Map(path)
    return _CACHE[key]
