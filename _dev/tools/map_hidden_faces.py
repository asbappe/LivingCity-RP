#!/usr/bin/env python3
"""Find the brush faces nobody can ever see and make them nodraw (the owner, 23 November: "there are TONS of surfaces
that need nodraw, surfaces/walls that are exposed to the void, facing other surfaces with no chance of ever being
visible").

How it judges, as the compiler would but from the players' side: the map is cut into cubes (--cell, 8 by default).
A cube is shut if its middle is inside an opaque brush (the world's and func_detail's, never a moving one, never glass,
a fence, a grate, water or a tool brush you can see through), or if a displacement's skin passes through it (terrain
and cave rock are walls to the eye, though not to the compiler). The open air players can reach or see into is flooded
from the player starts. A face of the world or of func_detail with a drawn material is kept if the air just in front of
it (2, 6 and 12 out, over the whole face) touches that flood anywhere; else nobody can see it and it becomes nodraw.
Sky faces are judged as the rest (since 23 November: the canal ring's sky boxes were 11,000 faces nobody sees; nodraw
seals as the sky does). Displaced faces, faces of moving or breakable brushes and other tool faces are never touched.
The flood goes in slabs, in place: the canal ring's test map (a grid of 3.6 billion cubes of 8) takes about 8 GB.

Safe by design: anything the flood can slip into counts as seen (a wall thinner than a cube may let it through, which
only keeps more faces). Only the material lines of the faces it names change; every other byte of the file stays.

    python3 map_hidden_faces.py IN.vmf OUT.vmf [--cell 8] [--list]
    python3 map_hidden_faces.py IN.vmf --holes          (writes nothing: prints every hole a player can see, HOLE lines)

--holes (the owner, 24 November: holes in the bunker's walls the builder's own checks never saw, since they judge brush
boxes, not what is drawn): every nodraw face, and every sky face under a roof, that a player can see from where they can
stand (walked from the starts on floors: a step of 18, any drop, 32 across, stopped by clips, glass, fences and grates;
seen: a straight line to the face past nothing opaque; a face a brush or a solid model's box lies flush against is
covered). The build's own pieces should print none.
Needs numpy."""
import argparse
import math
import re
import sys

import numpy as np

import map_view as mv

SEE_THROUGH = ("glass", "fence", "grate", "chainlink", "gate", "mesh", "water", "window", "wire", "cable", "decal", "overlay", "foliage",
               "leaf", "leaves", "tree", "grill", "rail", "ladder", "slime", "vent", "blinds", "cage", "lattice", "net", "hole", "alpha", "trans")
NOT_SOLID_TOOLS = ("toolstrigger", "toolsclip", "toolsplayerclip", "toolsnpcclip", "toolsareaportal", "toolshint", "toolsskip", "toolsinvisible",
                   "toolsoccluder", "toolsfog", "toolsblocklight", "toolsinvisibleladder", "toolsorigin", "toolsblock_los", "toolsdotted")
NODRAW = "TOOLS/TOOLSNODRAW"


def opaque(mats):
    """A brush the eye cannot pass: every face a solid material (nodraw, sky and black count: nobody is meant to see
    past them), none a see-through one."""
    for m in mats:
        m = m.lower()
        if m.startswith("tools/"):
            if any(t in m for t in NOT_SOLID_TOOLS):
                return False
            continue
        if any(w in m for w in SEE_THROUGH):
            return False
    return True


def drawn(mat):
    """A face the compiler draws: anything but a tool texture, and the sky (a sky face nobody sees costs a face all the
    same; nodraw seals as it does)."""
    m = mat.lower()
    return not m.startswith("tools/") or m in ("tools/toolsskybox", "tools/toolsskybox2d")


def planes_of(sides):
    out = []
    for s in sides:
        p = mv.nums(s.kv.get("plane", ""))
        a, b, c = np.array(p[0:3]), np.array(p[3:6]), np.array(p[6:9])
        n = np.cross(c - a, b - a)
        n = n / (np.linalg.norm(n) or 1.0)
        out.append((n, float(n @ a)))
    return out


def polygon(side, worked, k):
    vp = [b for b in side.kids if b.name == "vertices_plus"]
    if vp:
        return [tuple(mv.nums(v)) for key, v in vp[0].rows if key == "v"]
    return worked[k] if worked and worked[k] else None


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("vmf")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--cell", type=int, default=8)
    ap.add_argument("--list", action="store_true", help="print every face made nodraw")
    ap.add_argument("--force", action="store_true", help="write even if some lights or things stand in air the flood missed")
    ap.add_argument("--brushes", action="store_true", help="also delete the brushes nobody can see that do not seal the map")
    ap.add_argument("--route", nargs=3, type=float, metavar=("X", "Y", "Z"), help="print the way the seen air takes from the player start to this point")
    ap.add_argument("--holes", action="store_true", help="print every hole a player can see: a nodraw face, or a sky face under a roof, that seen air meets")
    a = ap.parse_args()
    C = float(a.cell)
    root = mv.read(a.vmf)

    brushes, faces, disps, seeds, things = [], [], [], [], []      # (planes, bbox) solid; (side id, mat, poly, normal) candidates
    holes, roofs, stops = [], [], []      # (--holes) nodraw faces of opaque brushes; the boxes of opaque brushes with no sky face;
                                          # (planes, box) of what stops a player but not the eye (clips, glass, fences, grates)
    models = []      # (--holes) (origin, forward, left, up, own box) of every solid model one cannot see through: a face it covers is no hole
    facts = {}
    if a.holes:
        import json
        import os
        try:
            facts = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "asset_facts.json")))
        except (OSError, ValueError):
            facts = {}
    every = []      # (solid id, "world" or "detail", bbox, sides, opaque, planes): every brush that could go (--brushes)
    every_point = []      # (class, name, origin): every point entity (--brushes checks none stands out in the void)
    for top in root.kids:
        if top.name == "world":
            owner, sols = "world", [k for k in top.kids if k.name == "solid"]
        elif top.name == "entity":
            cls = top.kv.get("classname", "")
            o = mv.nums(top.kv.get("origin", ""))
            if len(o) == 3 and not [k for k in top.kids if k.name == "solid"]:
                every_point.append((cls, top.kv.get("targetname", "") or top.kv.get("model", ""), o))
            if a.holes and cls.startswith("prop_") and len(o) == 3:
                model = top.kv.get("model", "").lower()
                bb = (facts.get(model) or {}).get("bbox")
                if bb and not mv.see_through(model):
                    ang = [math.radians(x) for x in (mv.nums(top.kv.get("angles", "")) + [0, 0, 0])[:3]]
                    sp, cp, sy, cy, sr, cr = math.sin(ang[0]), math.cos(ang[0]), math.sin(ang[1]), math.cos(ang[1]), math.sin(ang[2]), math.cos(ang[2])
                    fw = np.array([cp * cy, cp * sy, -sp])
                    rt = np.array([-sr * sp * cy + cr * sy, -sr * sp * sy - cr * cy, -sr * cp])
                    up = np.array([cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp])
                    models.append((np.array(o, dtype=float), fw, -rt, up, bb))
            if cls.startswith("info_player") and len(o) == 3:
                seeds.append((o[0], o[1], o[2] + 36))
            elif len(o) == 3 and cls.startswith(("light", "prop_", "npc_", "item_", "env_sprite", "point_spotlight")):
                things.append((cls, top.kv.get("targetname", "") or top.kv.get("model", ""), o))
            if a.holes and cls in ("func_brush", "func_breakable", "func_breakable_surf", "func_wall", "func_monitor"):
                for sol in [k for k in top.kids if k.name == "solid"]:
                    sides = [k for k in sol.kids if k.name == "side"]
                    pts = [p for poly in mv.from_planes(sides) if poly for p in poly]
                    if len(sides) >= 4 and pts:
                        stops.append((planes_of(sides), [min(p[i] for p in pts) for i in range(3)] + [max(p[i] for p in pts) for i in range(3)]))
            if cls != "func_detail":
                continue
            owner, sols = "detail", [k for k in top.kids if k.name == "solid"]
        else:
            continue
        for sol in sols:
            sides = [k for k in sol.kids if k.name == "side"]
            if len(sides) < 4:
                continue
            mats = [s.kv.get("material", "") for s in sides]
            has_disp = any(any(b.name == "dispinfo" for b in s.kids) for s in sides)
            worked = mv.from_planes(sides)
            polys = [polygon(s, worked, k) for k, s in enumerate(sides)]
            pts = [p for poly in polys if poly for p in poly]
            if not pts:
                continue
            pl = planes_of(sides)
            if has_disp:
                for k, s in enumerate(sides):
                    d = [b for b in s.kids if b.name == "dispinfo"]
                    if d and polys[k] and len(polys[k]) == 4:
                        verts = polys[k] if [b for b in s.kids if b.name == "vertices_plus"] else list(reversed(polys[k]))
                        disps.append(mv.displaced(verts, d[0], (0, 0, 0)))
                continue      # (a displaced brush is no wall to the compiler, nor its faces ours to change)
            box = [min(p[i] for p in pts) for i in range(3)] + [max(p[i] for p in pts) for i in range(3)]
            every.append((sol.kv.get("id"), owner, box, len(sides), opaque(mats), pl))
            if opaque(mats):
                brushes.append((pl, box))
                if a.holes and not any(m.lower() in ("tools/toolsskybox", "tools/toolsskybox2d") for m in mats):
                    roofs.append((pl, box))
            elif a.holes and not all(m.lower().startswith("tools/") and not any(t in m.lower() for t in ("playerclip", "toolsclip")) for m in mats):
                stops.append((pl, box))
            for k, s in enumerate(sides):
                if drawn(mats[k]) and polys[k] and len(polys[k]) >= 3:
                    faces.append((s.kv.get("id"), mats[k], polys[k], pl[k][0]))
                elif a.holes and opaque(mats) and mats[k].upper() == NODRAW and polys[k] and len(polys[k]) >= 3:
                    holes.append((s.kv.get("id"), mats[k], polys[k], pl[k][0]))
    if not seeds:
        sys.exit("no info_player_start to flood from")

    allp = [b[1] for b in brushes]
    lo = np.array([min(b[i] for b in allp) for i in range(3)]) - 2 * C
    hi = np.array([max(b[i + 3] for b in allp) for i in range(3)]) + 2 * C
    n = np.ceil((hi - lo) / C).astype(int)
    print("grid %d x %d x %d (%.0f M cubes of %d), %d opaque brushes, %d displaced faces, %d faces to judge" % (
        n[0], n[1], n[2], n.prod() / 1e6, a.cell, len(brushes), len(disps), len(faces)))
    solid = np.zeros(n, dtype=bool)

    def idx(p):
        return np.floor((np.asarray(p) - lo) / C).astype(int)

    def mark(grid, pl, box):
        i0, i1 = np.maximum(idx(box[:3]), 0), np.minimum(idx(box[3:]) + 1, n)
        if (i1 <= i0).any():
            return
        g = [lo[q] + (np.arange(i0[q], i1[q]) + 0.5) * C for q in range(3)]
        X, Y, Z = np.meshgrid(g[0], g[1], g[2], indexing="ij")
        inside = np.ones(X.shape, dtype=bool)
        for nn, d in pl:
            inside &= (nn[0] * X + nn[1] * Y + nn[2] * Z - d) <= 0.01
        grid[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]] |= inside

    for pl, box in brushes:
        mark(solid, pl, box)
    for quads in disps:      # a skin: every cube it passes through is shut (sampled finer than a cube)
        for quad, _c, _s in quads:
            q = np.array(quad)
            ln = max(np.linalg.norm(q[1] - q[0]), np.linalg.norm(q[3] - q[0]), np.linalg.norm(q[2] - q[1]), np.linalg.norm(q[2] - q[3]))
            m = max(2, int(math.ceil(ln / (C / 3.0))) + 1)
            s = np.linspace(0, 1, m)
            S, T = np.meshgrid(s, s, indexing="ij")
            P = ((1 - S) * (1 - T))[..., None] * q[0] + (S * (1 - T))[..., None] * q[1] + (S * T)[..., None] * q[2] + ((1 - S) * T)[..., None] * q[3]
            I = idx(P.reshape(-1, 3))
            ok = ((I >= 0) & (I < n)).all(axis=1)
            I = I[ok]
            solid[I[:, 0], I[:, 1], I[:, 2]] = True
    air = np.logical_not(solid, out=solid)      # (in place: the canal ring's grid is gigabytes)
    del solid
    reached = np.zeros(n, dtype=bool)
    for sd in seeds:
        i = idx(sd)
        if (i >= 0).all() and (i < n).all() and air[tuple(i)]:
            reached[tuple(i)] = True
    if not reached.any():
        sys.exit("every player start is inside something solid")

    def fill(reached, air, axis):
        """Along one axis, every run of air holding a seen cube is seen; done in slabs, in place (the same answer as at
        once, in a fraction of the memory: a slab's rows are independent)."""
        Av, Rv = np.moveaxis(air, axis, -1), np.moveaxis(reached, axis, -1)
        step = max(1, int(32e6 // max(1, Av[0].size)))
        for k0 in range(0, Av.shape[0], step):
            A = Av[k0:k0 + step].reshape(-1, n[axis])
            R = Rv[k0:k0 + step].reshape(-1, n[axis])
            start = A.copy()
            start[:, 1:] &= ~A[:, :-1]
            rid = np.cumsum(start, axis=None, dtype=np.int64).reshape(A.shape)
            has = np.zeros(int(rid[-1, -1]) + 2, dtype=bool)
            has[rid[R & A]] = True
            Rv[k0:k0 + step] = (A & has[rid]).reshape(Rv[k0:k0 + step].shape)
        return reached

    def flood(reached, air):
        """Every cube of `air` joined to `reached` (cubes sharing a face), by filling whole runs along each axis in
        turn until nothing more joins."""
        total = int(reached.sum())
        while True:
            for axis in (0, 1, 2):
                reached = fill(reached, air, axis)
            now = int(reached.sum())
            if now == total:
                return reached
            total = now

    reached = flood(reached, air)
    print("flood: %.1f M cubes of air seen of %.1f M open" % (reached.sum() / 1e6, air.sum() / 1e6))

    if a.route:      # (how does the air get there? a shortest way, cube by cube, through the seen air)
        goal = tuple(idx(a.route))
        if not reached[goal]:
            print("route: %s is not in seen air" % (a.route,))
        else:
            dist = np.full(n, -1, dtype=np.int32)
            start = [tuple(idx(sd)) for sd in seeds if reached[tuple(idx(sd))]][0]
            dist[start] = 0
            front, step = np.array([start]), 0
            offs = np.array([(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)])
            while dist[goal] < 0 and len(front):
                nb = (front[:, None, :] + offs[None, :, :]).reshape(-1, 3)
                ok = ((nb >= 0) & (nb < n)).all(axis=1)
                nb = nb[ok]
                nb = nb[reached[nb[:, 0], nb[:, 1], nb[:, 2]] & (dist[nb[:, 0], nb[:, 1], nb[:, 2]] < 0)]
                nb = np.unique(nb, axis=0)
                step += 1
                dist[nb[:, 0], nb[:, 1], nb[:, 2]] = step
                front = nb
            path, cur = [goal], np.array(goal)
            while dist[tuple(cur)] > 0:
                for o in offs:
                    q = cur + o
                    if (q >= 0).all() and (q < n).all() and dist[tuple(q)] == dist[tuple(cur)] - 1:
                        cur = q
                        break
                path.append(tuple(cur))
            path.reverse()
            print("route: %d cubes from the start; every 8th:" % len(path))
            for q in path[::8] + [path[-1]]:
                print("   (%d %d %d)" % tuple(lo + (np.array(q) + 0.5) * C))
    # the check: every light and placed thing should stand in air the flood saw (or inside something, where some
    # dressing sits); one in unseen air means a place people use that the flood missed, so nothing is changed
    lost = []
    for cls, name, o in things:
        i = idx(o)
        if not ((i >= 0).all() and (i < n).all()):
            continue
        near = reached[max(i[0] - 2, 0):i[0] + 3, max(i[1] - 2, 0):i[1] + 3, max(i[2] - 2, 0):i[2] + 3]
        if air[tuple(i)] and not near.any():
            lost.append((cls, name, [round(c) for c in o]))
    print("%d lights and placed things checked, %d stand in air the flood never saw" % (len(things), len(lost)))
    for x in lost[:40]:
        print("  LOST: %s %s at %s" % x)
    def covered(pts):
        """Which points lie inside an opaque brush (exactly, by its planes: a brush thinner than a cube, as a door frame's
        4 of metal, can cover a face the cubes never see), or inside a solid model's own box (Valve leaves faces under a
        model bare)."""
        lo3, hi3 = pts.min(axis=0) - 1, pts.max(axis=0) + 1
        out = np.zeros(len(pts), dtype=bool)
        for o, fw, lf, up, bb in models:
            r = max(abs(x) for x in bb) * 1.8
            if (o + r < lo3).any() or (o - r > hi3).any():
                continue
            q = pts - o
            lx, ly, lz = q @ fw, q @ lf, q @ up
            out |= (lx >= bb[0]) & (lx <= bb[3]) & (ly >= bb[1]) & (ly <= bb[4]) & (lz >= bb[2]) & (lz <= bb[5])
        for pl, box in brushes:
            if (np.array(box[:3]) > hi3).any() or (np.array(box[3:]) < lo3).any():
                continue
            inside = np.ones(len(pts), dtype=bool)
            for nn, d in pl:
                inside &= pts @ nn - d <= 0.01
            out |= inside
        return out

    def front(poly, nrm, exact=False):
        """The cubes of seen air just in front of a face (2, 6 and 12 out, over the whole face), or None when the face
        runs off the grid (not judged). exact: the points of it that something lies flush against (covered) left out."""
        P = np.array(poly)
        if np.cross(P, np.roll(P, -1, axis=0)).sum(axis=0) @ nrm < 0:
            P = P[::-1]      # (anticlockwise round its normal, for the test below: Hammer++'s corners run clockwise, and with
                             #  them every point inside a face was dropped, so only its middle and corners were judged)
        c = P.mean(axis=0)
        e1 = P[1] - P[0]
        e1 = e1 / (np.linalg.norm(e1) or 1)
        e2 = np.cross(nrm, e1)
        u, v = (P - c) @ e1, (P - c) @ e2
        us = np.arange(u.min() + 1, u.max() - 1 + 1e-6, C / 2) if u.max() - u.min() > 2 else np.array([0.0])
        vs = np.arange(v.min() + 1, v.max() - 1 + 1e-6, C / 2) if v.max() - v.min() > 2 else np.array([0.0])
        U, V = np.meshgrid(us, vs, indexing="ij")
        cand = c + U.reshape(-1, 1) * e1 + V.reshape(-1, 1) * e2
        # keep the points on the face (its polygon is convex: inside every edge)
        keep = np.ones(len(cand), dtype=bool)
        for k in range(len(P)):
            a0, a1 = P[k], P[(k + 1) % len(P)]
            side = np.cross(a1 - a0, cand - a0) @ nrm
            keep &= side >= -0.5
        cand = np.vstack([cand[keep], c[None, :], P + (c - P) * 0.05])
        if exact:
            cand = cand[~covered(cand + nrm * 1.0)]
            if not len(cand):
                return np.zeros((0, 3), dtype=int)
        for off in (2.0, 6.0, 12.0):
            I = idx(cand + nrm * off)
            ok = ((I >= 0) & (I < n)).all(axis=1)
            if not ok.all():
                return None      # (off the grid: not judged, kept)
            got = reached[I[:, 0], I[:, 1], I[:, 2]]
            if got.any():
                return I[got]
        return np.zeros((0, 3), dtype=int)
    hidden = {}
    for sid, mat, poly, nrm in faces:
        f = front(poly, nrm)
        if f is not None and not len(f):
            hidden[sid] = mat
    by = {}
    for sid, mat in hidden.items():
        by[mat] = by.get(mat, 0) + 1
    print("%d of %d drawn faces can never be seen" % (len(hidden), len(faces)))
    for mat, k in sorted(by.items(), key=lambda x: -x[1])[:25]:
        print("  %5d  %s" % (k, mat))
    if a.list:
        for sid, mat in sorted(hidden.items(), key=lambda x: int(x[0])):
            print("  side %s  %s" % (sid, mat))
    if a.holes:
        # holes a player can see (the owner, 24 November: "a void/hole in the wall before the door on the right, and there
        # are walls missing all over the stairs"): a nodraw face (the engine draws nothing there: the void or a smear shows),
        # and a sky face under a roof (a sky wall inside a building is a hole into the sky's black), that a player can see
        # from where they can stand. Where: the air walked from the player starts, stopped also by what stops a player but
        # not the eye (player clips, glass, fences, grates: a place to look at only, as the launch pad beyond its window, is
        # judged from where it is looked at); seen: a straight line from the face to that air meets nothing opaque. Under a
        # roof: some opaque brush with no sky face, or the ground's skin, is over that cube.
        walk = air.copy()
        for pl, box in stops:
            i0, i1 = np.maximum(idx(box[:3]), 0), np.minimum(idx(box[3:]) + 1, n)
            if (i1 > i0).all():
                g = [lo[q] + (np.arange(i0[q], i1[q]) + 0.5) * C for q in range(3)]
                X, Y, Z = np.meshgrid(g[0], g[1], g[2], indexing="ij")
                inside = np.ones(X.shape, dtype=bool)
                for nn, d in pl:
                    inside &= (nn[0] * X + nn[1] * Y + nn[2] * Z - d) <= 0.01
                walk[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]] &= ~inside
        # (and a player walks: from the starts, on floors, stepping up at most 18 and dropping any height, so the walk climbs
        #  no shaft and crosses no sky: the launch pad, open to the silo's shaft, is only looked at. A floor cube: air with
        #  something under it; land: for each cube of air, the floor cube it falls to)
        # (a player is 32 across: where they walk the cubes round them, a step over the floor, are free too, so no gap of a
        #  cube or two between player clips lets the walk through where a body cannot pass)
        free = walk.copy()
        for x0 in range(0, n[0], 64):
            sl = slice(max(0, x0 - 1), min(n[0], x0 + 65))
            W_ = walk[sl]
            E = W_.copy()
            E[1:] &= W_[:-1]
            E[:-1] &= W_[1:]
            E2 = E.copy()
            E2[:, 1:] &= E[:, :-1]
            E2[:, :-1] &= E[:, 1:]
            a0 = x0 - sl.start
            free[x0:x0 + 64] = E2[a0:a0 + min(64, n[0] - x0)]
            del W_, E, E2
        land = np.full(n, -1, dtype=np.int16)
        below = np.full((n[0], n[1]), -1, dtype=np.int16)
        for k in range(n[2]):
            w = walk[:, :, k]
            floor_here = w & (~walk[:, :, k - 1] if k else np.ones((n[0], n[1]), dtype=bool))
            below = np.where(floor_here, np.int16(k), np.where(w, below, np.int16(-1)))
            land[:, :, k] = below
        del below
        rise = int(math.ceil(18 / C))
        waist = int(math.ceil(24 / C))      # (the clearance is judged a step over the floor, so a slope does not count as a wall)

        def roomy(Q):
            return free[Q[:, 0], Q[:, 1], np.minimum(Q[:, 2] + waist, n[2] - 1)]
        feet, first = set(), []
        for sd in seeds:
            i = idx(sd)
            if (i >= 0).all() and (i < n).all() and land[tuple(i)] >= 0:
                q = (int(i[0]), int(i[1]), int(land[tuple(i)]))
                if q not in feet:
                    feet.add(q)
                    first.append(q)
        reach_f = np.zeros(n, dtype=bool)
        F = np.array(first, dtype=np.int64).reshape(-1, 3)
        reach_f[F[:, 0], F[:, 1], F[:, 2]] = True
        offs = np.array([(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in range(0, rise + 1) if (dx, dy) != (0, 0)], dtype=np.int64)
        while len(F):
            Q = (F[:, None, :] + offs[None, :, :]).reshape(-1, 3)
            ok = ((Q >= 0) & (Q < n)).all(axis=1)
            Q = Q[ok]
            L = land[Q[:, 0], Q[:, 1], Q[:, 2]]
            Q = Q[L >= 0]
            Q[:, 2] = L[L >= 0]
            Q = np.unique(Q, axis=0)
            Q = Q[~reach_f[Q[:, 0], Q[:, 1], Q[:, 2]] & roomy(Q)]
            reach_f[Q[:, 0], Q[:, 1], Q[:, 2]] = True
            F = Q
        del land, free
        stood = np.zeros(n, dtype=bool)      # (a player's body: from the floor up 72)
        body = int(math.ceil(72 / C))
        P = np.argwhere(reach_f)
        del reach_f
        for k in range(body):
            Z = P[:, 2] + k
            m = Z < n[2]
            stood[P[m, 0], P[m, 1], Z[m]] |= walk[P[m, 0], P[m, 1], Z[m]]
        del walk
        print("holes: %.1f M cubes of air a player can stand in or walk to" % (stood.sum() / 1e6))
        def roofed(f):
            """Which of the cubes f have a roof over them: an opaque brush with no sky face that the line straight up from the
            cube's middle passes through (exactly, by its planes), or the ground's skin."""
            pts = lo + (f + 0.5) * C
            out = np.zeros(len(f), dtype=bool)
            for pl, box in roofs:
                m = (pts[:, 0] >= box[0]) & (pts[:, 0] <= box[3]) & (pts[:, 1] >= box[1]) & (pts[:, 1] <= box[4]) & (pts[:, 2] < box[5]) & ~out
                if not m.any():
                    continue
                P = pts[m]
                t_lo, t_hi = P[:, 2].copy(), np.full(len(P), 1e9)
                ok = np.ones(len(P), dtype=bool)
                for nn, d in pl:
                    rhs = d - nn[0] * P[:, 0] - nn[1] * P[:, 1]
                    if abs(nn[2]) < 1e-9:
                        ok &= rhs >= -0.01
                    elif nn[2] > 0:
                        t_hi = np.minimum(t_hi, rhs / nn[2])
                    else:
                        t_lo = np.maximum(t_lo, rhs / nn[2])
                hit = ok & (t_hi > t_lo)
                idxs = np.where(m)[0]
                out[idxs[hit]] = True
            sk = skin_top[f[:, 0], f[:, 1]] > f[:, 2]
            return out | sk
        skin_top = np.full((n[0], n[1]), -1, dtype=np.int32)      # (each column's highest cube of the ground's skin)
        for quads in disps:
            for quad, _c, _s in quads:
                for q in quad:
                    i = idx(q)
                    if (i >= 0).all() and (i < n).all():
                        skin_top[i[0], i[1]] = max(skin_top[i[0], i[1]], i[2])
        # rays: about 200 ways round the face's front (a Fibonacci sphere's half), each up to 4096 long, in steps of a cube
        k = np.arange(400) + 0.5
        phi, th = np.arccos(1 - 2 * k / 400), np.pi * (1 + 5 ** 0.5) * k
        dirs = np.stack([np.cos(th) * np.sin(phi), np.sin(th) * np.sin(phi), np.cos(phi)], axis=1)
        steps = np.arange(1, int(4096 / C) + 1) * C

        def seen_from_floor(f, nrm):
            """Of the front cubes f of a face (normal nrm), how many a player can see (a clear line to air one can stand in)."""
            if not len(f):
                return 0
            pts = lo + (f + 0.5) * C
            if len(pts) > 24:
                pts = pts[np.linspace(0, len(pts) - 1, 24).astype(int)]
            D = dirs[dirs @ nrm > 0.05]
            got = 0
            for p in pts:
                P = p[None, None, :] + D[:, None, :] * steps[None, :, None]
                I = np.floor((P - lo) / C).astype(int)
                ok = ((I >= 0) & (I < n)).all(axis=2)
                I = np.where(ok[..., None], I, 0)
                op = ~air[I[..., 0], I[..., 1], I[..., 2]] | ~ok
                st = stood[I[..., 0], I[..., 1], I[..., 2]] & ok
                first_op = np.where(op.any(axis=1), op.argmax(axis=1), len(steps))
                first_st = np.where(st.any(axis=1), st.argmax(axis=1), len(steps) + 1)
                if (first_st < first_op).any() or stood[tuple(np.floor((p - lo) / C).astype(int))]:
                    got += 1
                    if got >= 3:
                        break
            return got
        found = []
        for sid, mat, poly, nrm in holes:
            f = front(poly, nrm, exact=True)
            if f is not None and len(f):
                k = seen_from_floor(f, nrm)
                if k:
                    found.append(("nodraw face", sid, poly, k))
        for sid, mat, poly, nrm in faces:
            if mat.lower() not in ("tools/toolsskybox", "tools/toolsskybox2d"):
                continue
            f = front(poly, nrm, exact=True)
            if f is not None and len(f):
                under = f[roofed(f)]
                k = seen_from_floor(under, nrm)
                if k:
                    found.append(("sky face under a roof", sid, poly, k))
        print("holes a player can see: %d" % len(found))
        for what, sid, poly, k in sorted(found, key=lambda h: (h[0], [round(c) for c in np.array(h[2]).mean(axis=0)])):
            P = np.array(poly)
            print("  HOLE: %s (side %s) at (%d %d %d), %d by %d by %d, seen from %d or more of its points" % ((what, sid) + tuple(P.mean(axis=0)) + tuple(P.max(axis=0) - P.min(axis=0)) + (k,)))
    gone = []
    if a.brushes:
        # the seal: world brushes alone (detail, displacements, clips and see-through brushes do not seal), and the void
        # outside it flooded in from the grid's edge; a world brush near that void is part of the seal and stays
        wall = np.zeros(n, dtype=bool)
        for sid, owner, box, ns, opq, pl in every:
            if owner == "world" and opq:
                mark(wall, pl, box)
        out_air = ~wall
        void = np.zeros(n, dtype=bool)
        void[0, :, :] = void[-1, :, :] = True
        void[:, 0, :] = void[:, -1, :] = True
        void[:, :, 0] = void[:, :, -1] = True
        void &= out_air
        rounds = 0
        while True:      # (round by round, to say where the void first meets air someone can see: a hole in the seal as cubes see it)
            before = int(void.sum())
            for axis in (0, 1, 2):
                void = fill(void, out_air, axis)
            rounds += 1
            meet = void & reached
            if meet.any():
                pts = np.argwhere(meet)[:12]
                print("LEAK (as cubes see it), round %d: the void meets seen air at %s" % (rounds, ", ".join(
                    "(%d %d %d)" % tuple(lo + (q + 0.5) * C) for q in pts)))
                break
            if int(void.sum()) == before:
                break
        void = flood(void, out_air)
        print("the void outside the seal: %.1f M cubes" % (void.sum() / 1e6))
        for cls, name, o in every_point:      # (a thing out in the void: the compiler stops on a leak)
            i = idx(o)
            if (i >= 0).all() and (i < n).all() and void[tuple(i)]:
                print("  LEAK: %s %s at %s stands outside the sealed map" % (cls, name, [round(c) for c in o]))
        m = int(round(16 / C))      # (16 of margin round every brush)
        pocket = out_air & ~void & ~reached      # (air inside the seal nobody sees: sealed pockets, the ground under the terrain)
        kinds = {}
        for sid, owner, box, ns, opq, pl in every:
            i0 = np.maximum(idx(box[:3]) - m, 0)
            i1 = np.minimum(idx(box[3:]) + 1 + m, n)
            sl = (slice(i0[0], i1[0]), slice(i0[1], i1[1]), slice(i0[2], i1[2]))
            k = "seen" if reached[sl].any() else "seal" if void[sl].any() else "pocket" if pocket[sl].any() else "buried"
            k = owner + " " + k
            kinds.setdefault(k, [0, 0])
            kinds[k][0] += 1
            kinds[k][1] += ns
        for k, (cnt, ns) in sorted(kinds.items()):
            print("  %-14s %5d brushes, %6d sides" % (k, cnt, ns))
        for sid, owner, box, ns, opq, pl in every:
            i0 = np.maximum(idx(box[:3]) - m, 0)
            i1 = np.minimum(idx(box[3:]) + 1 + m, n)
            sl = (slice(i0[0], i1[0]), slice(i0[1], i1[1]), slice(i0[2], i1[2]))
            if reached[sl].any():
                continue      # (near air someone can see into)
            if owner == "world" and void[sl].any():
                continue      # (part of the seal against the void)
            gone.append((sid, owner, ns))
        print("%d of %d brushes nobody can see and the seal does not need (%d world, %d detail): %d brush sides" % (
            len(gone), len(every), sum(1 for g in gone if g[1] == "world"), sum(1 for g in gone if g[1] == "detail"), sum(g[2] for g in gone)))
    if not a.out:
        return
    if lost and not a.force:
        sys.exit("not written: the flood missed places people use (LOST above); look into them, or --force")
    text = open(a.vmf, encoding="utf-8", errors="surrogateescape", newline="").read()
    done = [0]

    def swap(m):
        sid = m.group(2)
        if sid in hidden:
            done[0] += 1
            return m.group(1) + re.sub(r'"material" "[^"]*"', '"material" "%s"' % NODRAW, m.group(3), count=1)
        return m.group(0)
    # each side: its id, then (planes, vertices_plus) up to its material line
    text = re.sub(r'(\tside\r?\n\t*\{\r?\n\t*"id" "(\d+)")(.*?"material" "[^"]*")', swap, text, flags=re.S)
    if gone:
        eol = "\r\n" if "\r\n" in text[:4000] else "\n"
        ids = set(g[0] for g in gone)
        cut = [0]

        def drop(m):
            if m.group("id") in ids:
                cut[0] += 1
                return ""
            return m.group(0)
        # a brush: from its "solid" line (one tab in) to its closing brace at the same depth, with the line end after it
        pat = r'\tsolid%s\t\{%s\t\t"id" "(?P<id>\d+)"%s.*?%s\t\}%s' % (eol, eol, eol, eol, eol)
        text = re.sub(pat, drop, text, flags=re.S)
        # a func_detail left with no brush goes too
        ent = r'(?m)^entity%s\{%s(?:(?!^\}).)*?"classname" "func_detail"(?:(?!^\}).)*?^\}%s' % (eol, eol, eol)
        empty = [0]

        def lone(m):
            if "\tsolid" + eol not in m.group(0):
                empty[0] += 1
                return ""
            return m.group(0)
        text = re.sub(ent, lone, text, flags=re.S)
        print("%d brushes deleted, %d func_detail left empty and deleted" % (cut[0], empty[0]))
    open(a.out, "w", encoding="utf-8", errors="surrogateescape", newline="").write(text)
    print("written %s: %d faces made nodraw" % (a.out, done[0]))


if __name__ == "__main__":
    main()
