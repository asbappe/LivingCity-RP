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
Displaced faces, faces of moving or breakable brushes and tool faces are never touched.

Safe by design: anything the flood can slip into counts as seen (a wall thinner than a cube may let it through, which
only keeps more faces). Only the material lines of the faces it names change; every other byte of the file stays.

    python3 map_hidden_faces.py IN.vmf OUT.vmf [--cell 8] [--list]
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
    m = mat.lower()
    return not m.startswith("tools/")


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
    a = ap.parse_args()
    C = float(a.cell)
    root = mv.read(a.vmf)

    brushes, faces, disps, seeds, things = [], [], [], [], []      # (planes, bbox) solid; (side id, mat, poly, normal) candidates
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
            if cls.startswith("info_player") and len(o) == 3:
                seeds.append((o[0], o[1], o[2] + 36))
            elif len(o) == 3 and cls.startswith(("light", "prop_", "npc_", "item_", "env_sprite", "point_spotlight")):
                things.append((cls, top.kv.get("targetname", "") or top.kv.get("model", ""), o))
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
            for k, s in enumerate(sides):
                if drawn(mats[k]) and polys[k] and len(polys[k]) >= 3:
                    faces.append((s.kv.get("id"), mats[k], polys[k], pl[k][0]))
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
    air = ~solid
    reached = np.zeros(n, dtype=bool)
    for sd in seeds:
        i = idx(sd)
        if (i >= 0).all() and (i < n).all() and air[tuple(i)]:
            reached[tuple(i)] = True
    if not reached.any():
        sys.exit("every player start is inside something solid")

    def fill(reached, air, axis):
        A = np.moveaxis(air, axis, -1).reshape(-1, n[axis])
        R = np.moveaxis(reached, axis, -1).reshape(-1, n[axis])
        start = A.copy()
        start[:, 1:] &= ~A[:, :-1]
        rid = np.cumsum(start, axis=None, dtype=np.int32).reshape(A.shape)
        has = np.zeros(int(rid[-1, -1]) + 2, dtype=bool)
        has[rid[R & A]] = True
        out = A & has[rid]
        return np.moveaxis(out.reshape(np.moveaxis(air, axis, -1).shape), -1, axis)

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
    hidden = {}
    for sid, mat, poly, nrm in faces:
        P = np.array(poly)
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
        seen = False
        for off in (2.0, 6.0, 12.0):
            I = idx(cand + nrm * off)
            ok = ((I >= 0) & (I < n)).all(axis=1)
            if not ok.all():
                seen = True      # (off the grid: not judged, kept)
                break
            if reached[I[:, 0], I[:, 1], I[:, 2]].any():
                seen = True
                break
        if not seen:
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
