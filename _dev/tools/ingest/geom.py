"""Living City map ingestion: rays and true slices through a map's solid brushes and displaced ground.

    s = geom.Solid(m)                       # play-space solids of a vmf.Map (no hidden brushes, no skybox room)
    t, face, kind = s.ray(origin, direction, 4096)    # kind 1 solid, 2 water, 3 sky brush, 4 displaced ground
    z, face = s.floor(x, y, ztop)            # the first floor under a point (through water)
    ss, zs, grid = s.slice(cx, cy, ux, uy, smax, z1, z2, step)   # 0 air, 1 solid, 2 water, 3 sky

Brushes are tested exactly by their planes (a convex brush is where every plane is behind the point), displacements
as triangles. A ray that starts inside a solid returns 0. Both are found through a grid of 256 squares.
"""
import numpy as np

SOLID_CLASSES = {"world", "func_detail", "func_brush", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
                 "func_breakable", "func_breakable_surf", "func_lod", "func_movelinear", "func_physbox", "func_rotating",
                 "func_tracktrain", "func_train", "func_button", "func_rot_button", "func_water_analog", "func_reflective_glass"}
IGNORE = ("toolsclip", "toolsplayerclip", "toolsnpcclip", "toolstrigger", "toolsskip", "toolshint", "toolsareaportal",
          "toolsblocklight", "toolsoccluder", "toolsinvisible", "toolsfog", "toolsblock_los", "toolsblockbullets", "toolsdotted",
          "toolsorigin", "toolsclimb")
CELL, STEP = 256.0, 64.0


def is_water(mat):
    last = mat.split("/")[-1]
    return not mat.startswith("tools/") and (mat.startswith(("nature/", "liquids/", "water/")) or "water" in last) and ("water" in last or "slime" in last)


def is_tool(mat):
    return mat.startswith("tools/")


class Grid:
    """Items (boxes) in 2D squares; samples along a segment find every item it can touch."""

    def __init__(self, lo, hi, cell=CELL, pad=STEP / 2):
        self.cell = cell
        n = len(lo)
        if not n:
            self.keys = np.zeros(0, dtype=np.int64)
            self.items = np.zeros(0, dtype=np.int64)
            self.start = np.zeros(1, dtype=np.int64)
            return
        i0 = np.floor((lo[:, 0] - pad) / cell).astype(np.int64)
        i1 = np.floor((hi[:, 0] + pad) / cell).astype(np.int64)
        j0 = np.floor((lo[:, 1] - pad) / cell).astype(np.int64)
        j1 = np.floor((hi[:, 1] + pad) / cell).astype(np.int64)
        wx, wy = i1 - i0 + 1, j1 - j0 + 1
        cnt = wx * wy
        item = np.repeat(np.arange(n), cnt)
        first = np.repeat(np.cumsum(cnt) - cnt, cnt)
        k = np.arange(cnt.sum()) - first
        ix = i0[item] + k % wx[item]
        iy = j0[item] + k // wx[item]
        key = self._key(ix, iy)
        order = np.argsort(key, kind="stable")
        key, item = key[order], item[order]
        self.keys, idx = np.unique(key, return_index=True)
        self.start = np.append(idx, len(key))
        self.items = item

    @staticmethod
    def _key(ix, iy):
        return (ix + (1 << 20)) * (1 << 21) + (iy + (1 << 20))

    def _lookup(self, k):
        if not len(self.keys):
            return np.zeros(0, dtype=np.int64)
        k = np.unique(k)
        pos = np.searchsorted(self.keys, k)
        ok = pos < len(self.keys)
        pos, k = pos[ok], k[ok]
        pos = pos[self.keys[pos] == k]
        if not len(pos):
            return np.zeros(0, dtype=np.int64)
        parts = [self.items[self.start[p]:self.start[p + 1]] for p in pos]
        return np.unique(np.concatenate(parts)) if len(parts) > 1 else parts[0]

    def near_points(self, xy):
        """Items in the squares holding these points."""
        return self._lookup(self._key(np.floor(xy[:, 0] / self.cell).astype(np.int64), np.floor(xy[:, 1] / self.cell).astype(np.int64)))

    def near_box(self, x1, y1, x2, y2):
        """Items in every square a rectangle touches."""
        ix = np.arange(int(np.floor(x1 / self.cell)), int(np.floor(x2 / self.cell)) + 1, dtype=np.int64)
        iy = np.arange(int(np.floor(y1 / self.cell)), int(np.floor(y2 / self.cell)) + 1, dtype=np.int64)
        return self._lookup(self._key(np.repeat(ix, len(iy)), np.tile(iy, len(ix))))

    def near_segment(self, a, b):
        a, b = np.asarray(a, float)[:2], np.asarray(b, float)[:2]
        L = float(np.linalg.norm(b - a))
        n = max(1, int(np.ceil(L / STEP)))
        t = np.linspace(0.0, 1.0, n + 1)
        return self.near_points(a[None] + (b - a)[None] * t[:, None])


class Solid:
    def __init__(self, m, classes=SOLID_CLASSES):
        self.m = m
        keep, code = [], []
        tris, tri_face = [], []
        for b in range(len(m.b_owner)):
            if not m.play_brush(b) or m.b_cls[b] not in classes:
                continue
            fs = list(m.faces_of(b))
            mats = [m.mat(f) for f in fs]
            if m.b_disp[b]:
                for f in fs:
                    di = m.f_disp[f]
                    if di < 0:
                        continue
                    g = m.disp_grid(di)
                    if not g.size:
                        continue
                    a, bb, c, d = g[:-1, :-1], g[1:, :-1], g[1:, 1:], g[:-1, 1:]
                    for t in ((a, bb, c), (a, c, d)):
                        tris.append(np.stack([x.reshape(-1, 3) for x in t], axis=1))
                        tri_face.append(np.full(len(tris[-1]), f))
                continue
            if any(any(t in mt for t in IGNORE) for mt in mats):
                continue
            if any(is_water(mt) for mt in mats):
                kind = 2
            elif all(is_tool(mt) for mt in mats) and any("toolsskybox" in mt for mt in mats):
                kind = 3
            else:
                kind = 1
            keep.append(b)
            code.append(kind)
        self.brush = np.array(keep, dtype=np.int64)
        self.code = np.array(code, dtype=np.int8)
        K = max([m.b_f1[b] - m.b_f0[b] for b in keep] or [4])
        self.N = np.zeros((len(keep), K, 3))
        self.D = np.full((len(keep), K), 1e9)
        self.Fi = np.full((len(keep), K), -1, dtype=np.int64)
        for i, b in enumerate(keep):
            f0, f1 = m.b_f0[b], m.b_f1[b]
            self.N[i, :f1 - f0] = m.f_n[f0:f1]
            self.D[i, :f1 - f0] = m.f_d[f0:f1]
            self.Fi[i, :f1 - f0] = np.arange(f0, f1)
        self.lo = m.b_lo[self.brush] if len(keep) else np.zeros((0, 3))
        self.hi = m.b_hi[self.brush] if len(keep) else np.zeros((0, 3))
        self.grid = Grid(self.lo, self.hi)
        self.T = np.concatenate(tris) if tris else np.zeros((0, 3, 3))
        self.Tf = np.concatenate(tri_face) if tri_face else np.zeros(0, dtype=np.int64)
        if len(self.T):
            e1, e2 = self.T[:, 1] - self.T[:, 0], self.T[:, 2] - self.T[:, 0]
            nz = np.cross(e1, e2)
            ln = np.linalg.norm(nz, axis=1)
            ok = ln > 1e-6
            self.T, self.Tf = self.T[ok], self.Tf[ok]
            self.Tn = (nz[ok] / ln[ok, None])
            flip = (self.Tn * m.f_n[self.Tf]).sum(axis=1) < 0      # (face the way the brush face did: ground up)
            self.Tn[flip] *= -1
            self.Tlo, self.Thi = self.T.min(axis=1), self.T.max(axis=1)
        else:
            self.Tn = np.zeros((0, 3))
            self.Tlo = self.Thi = np.zeros((0, 3))
        self.tgrid = Grid(self.Tlo, self.Thi)

    # ---- rays
    def _cands(self, o, d, maxt):
        if abs(d[0]) < 1e-9 and abs(d[1]) < 1e-9:
            return self.grid.near_points(o[None, :2]), self.tgrid.near_points(o[None, :2])
        e = o + d * maxt
        return self.grid.near_segment(o, e), self.tgrid.near_segment(o, e)

    def ray(self, o, d, maxt=4096.0, water=False, sky=True, inside=True):
        """(distance or None, face index or -1, kind). water=False lets the ray pass through water brushes;
        inside=False lets it pass out of a brush it starts in (as a ray that sees only front faces would)."""
        o, d = np.asarray(o, float), np.asarray(d, float)
        cb, ct = self._cands(o, d, maxt)
        best, face, kind = maxt, -1, 0
        if len(cb):
            if not water:
                cb = cb[self.code[cb] != 2]
            if not sky:
                cb = cb[self.code[cb] != 3]
            end = o + d * maxt
            lo, hi = np.minimum(o, end) - 1, np.maximum(o, end) + 1
            cb = cb[np.all((self.lo[cb] <= hi) & (self.hi[cb] >= lo), axis=1)]
        if len(cb):
            N, D = self.N[cb], self.D[cb]
            nd = N @ d
            no = N @ o - D
            with np.errstate(divide="ignore", invalid="ignore"):
                t = -no / nd
            enter, leave = nd < -1e-12, nd > 1e-12
            par_out = (~enter & ~leave & (no > 1e-6)).any(axis=1)
            te_all = np.where(enter, t, -np.inf)
            te = te_all.max(axis=1)
            tx = np.where(leave, t, np.inf).min(axis=1)
            hit = ~par_out & (te <= tx + 1e-6) & (tx > 1e-4)
            if not inside:
                hit &= te > 1e-4
            if hit.any():
                tt = np.where(te > 0, te, 0.0)
                tt[~hit] = np.inf
                j = int(np.argmin(tt))
                if tt[j] < best:
                    best, kind = float(tt[j]), int(self.code[cb[j]])
                    k = int(np.argmax(te_all[j]))
                    face = int(self.Fi[cb[j], k]) if te[j] > -np.inf else -1
        if len(ct):
            th, tf = self._tri_hit(o, d, ct, best)
            if th is not None and th < best:
                best, face, kind = th, tf, 4
        return (best, face, kind) if kind else (None, -1, 0)

    def _tri_hit(self, o, d, idx, maxt):
        T = self.T[idx]
        e1, e2 = T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]
        p = np.cross(d, e2)
        det = np.einsum("ij,ij->i", e1, p)
        ok = np.abs(det) > 1e-9
        inv = np.where(ok, 1.0 / np.where(ok, det, 1.0), 0.0)
        s = o - T[:, 0]
        u = np.einsum("ij,ij->i", s, p) * inv
        q = np.cross(s, e1)
        v = (q @ d) * inv
        t = np.einsum("ij,ij->i", e2, q) * inv
        hit = ok & (u >= -1e-6) & (v >= -1e-6) & (u + v <= 1 + 1e-6) & (t > 1e-3) & (t < maxt)
        if not hit.any():
            return None, -1
        j = int(np.argmin(np.where(hit, t, np.inf)))
        return float(t[j]), int(self.Tf[idx[j]])

    def floor(self, x, y, ztop, depth=512.0, water=False, inside=False):
        """(height of the first floor under (x, y, ztop) or None, its face). A point inside a brush looks past it."""
        t, f, k = self.ray((x, y, ztop), (0.0, 0.0, -1.0), depth, water=water, inside=inside)
        return (ztop - t, f) if t is not None else (None, -1)

    def open_above(self, x, y, z, reach=16384.0):
        """True when nothing but sky is over the point (a ray up meets no brush, or a sky brush, or a skybox face)."""
        t, f, k = self.ray((x, y, z), (0.0, 0.0, 1.0), reach)
        return t is None or k == 3 or (f >= 0 and "toolsskybox" in self.m.mat(f)), t

    # ---- slices
    def slice(self, cx, cy, ux, uy, smax=1024.0, z1=-128.0, z2=1280.0, step=4.0, thick=160.0):
        """A true vertical cut across (ux, uy) through (cx, cy): grid[z, s] of 0 air, 1 solid, 2 water, 3 sky."""
        ss = np.arange(-smax, smax + step / 2, step)
        zs = np.arange(z1, z2 + step / 2, step)
        R, S = len(zs), len(ss)
        out = np.zeros((R, S), dtype=np.int8)
        u = np.array([ux, uy, 0.0])
        c = np.array([cx, cy, 0.0])
        cb = self.grid.near_segment(c - u * smax, c + u * smax)
        if len(cb):
            cb = cb[(self.hi[cb, 2] >= z1) & (self.lo[cb, 2] <= z2)]
        layers = {}
        for i in cb:
            N, D = self.N[i], self.D[i]
            real = self.Fi[i] >= 0
            N, D = N[real], D[real]
            a = N @ u
            rhs = (D - N @ c)[None, :] - zs[:, None] * N[None, :, 2]
            with np.errstate(divide="ignore", invalid="ignore"):
                lim = rhs / a[None, :]
            pos, neg = a > 1e-9, a < -1e-9
            s_hi = np.where(pos[None], lim, np.inf).min(axis=1)
            s_lo = np.where(neg[None], lim, -np.inf).max(axis=1)
            flat_bad = ((~pos & ~neg)[None] & (rhs < -1e-6)).any(axis=1)
            i0 = np.ceil((s_lo + smax) / step - 1e-6)
            i1 = np.floor((s_hi + smax) / step + 1e-6)
            rows = np.where(~flat_bad & (i0 <= i1) & (i1 >= 0) & (i0 <= S - 1))[0]
            if not len(rows):
                continue
            k = int(self.code[i])
            if k not in layers:
                layers[k] = np.zeros((R, S + 1), dtype=np.int32)
            L = layers[k]
            a0 = np.clip(i0[rows], 0, S - 1).astype(int)
            a1 = np.clip(i1[rows], 0, S - 1).astype(int)
            np.add.at(L, (rows, a0), 1)
            np.add.at(L, (rows, a1 + 1), -1)
        for k in (2, 3, 1):      # (solid drawn last: it wins over water and sky)
            if k in layers:
                out[np.cumsum(layers[k][:, :S], axis=1) > 0] = k
        if len(self.T):
            self._slice_ground(out, ss, zs, c, u, thick)
        return ss, zs, out

    def _slice_ground(self, out, ss, zs, c, u, thick):
        ct = self.tgrid.near_segment(c - u * ss[-1], c + u * ss[-1])
        if not len(ct):
            return
        ct = ct[np.abs(self.Tn[ct, 2]) > 0.3]
        if not len(ct):
            return
        T, up = self.T[ct], self.Tn[ct, 2] > 0
        P = c[None, :2] + u[None, :2] * ss[:, None]
        a = T[:, 0, :2]
        v0, v1 = T[:, 1, :2] - a, T[:, 2, :2] - a
        den = v0[:, 0] * v1[:, 1] - v1[:, 0] * v0[:, 1]
        good = np.abs(den) > 1e-9
        den = np.where(good, den, 1.0)
        w = P[None] - a[:, None]
        p = (w[..., 0] * v1[:, None, 1] - v1[:, None, 0] * w[..., 1]) / den[:, None]
        q = (v0[:, None, 0] * w[..., 1] - w[..., 0] * v0[:, None, 1]) / den[:, None]
        ins = good[:, None] & (p >= -1e-6) & (q >= -1e-6) & (p + q <= 1 + 1e-6)
        ti, sj = np.nonzero(ins)
        if not len(ti):
            return
        z = T[ti, 0, 2] + p[ti, sj] * (T[ti, 1, 2] - T[ti, 0, 2]) + q[ti, sj] * (T[ti, 2, 2] - T[ti, 0, 2])
        step, z1, R = zs[1] - zs[0] if len(zs) > 1 else 1.0, zs[0], len(zs)
        lo = np.where(up[ti], z - thick, z)
        hi = np.where(up[ti], z, z + thick)
        r0 = np.clip(np.ceil((lo - z1) / step + 1e-6), 0, R)
        r1 = np.clip(np.floor((hi - z1) / step - 1e-6), -1, R - 1)
        k = r0 <= r1
        if not k.any():
            return
        L = np.zeros((R + 1, len(ss)), dtype=np.int32)
        np.add.at(L, (r0[k].astype(int), sj[k]), 1)
        np.add.at(L, (r1[k].astype(int) + 1, sj[k]), -1)
        out[np.cumsum(L[:R], axis=0) > 0] = 1
