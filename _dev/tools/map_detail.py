#!/usr/bin/env python3
"""Small world brushes made func_detail, so vvis has fewer leaves to work through (the owner, 28 November, of City 18's
first full vis: "portal flow is ludicrously slow and taking about 2 minutes per 10% ... did we break something?").

    python3 map_detail.py IN.vmf OUT.vmf [--max 128] [--near 24] [--cell 4] [--margin 48] [--dry]

A world brush becomes func_detail when it is small (its middle size, of its three, under --max: trims, frames, steps,
ledges, beams, posts) and is none of these: a displacement; one with sky, water or slime on it; one with only tool
faces (clips, hints, skips: they stay as the mapper set them); one within --near of an areaportal (an areaportal must
meet world brushes all round); one that parts two areas (on a grid of --cell, the air cut into areas by the world's
brushes and the areaportals, as map_areas.py does: a brush with different areas round it walls a room in; the
owner's City 18 has rooms walled partly by small brushes, and a first try without this broke 75 areaportals). func_detail looks and collides exactly as before; it neither seals nor cuts the map
into leaves, so only a map sealed by other brushes may lose them (City 18 is sealed by its sky box: the lesson
owner-c18-sealed-by-its-box). Every moved brush keeps its id, faces and visgroup; they go into func_detail entities of
up to 500 brushes each, after the last entity. Check afterwards: map_areas.py (no areaportal may leak) and
map_leak.py --void all --entities."""
import argparse
import re

import numpy as np
from scipy import ndimage

import map_leak as ml


def planes_of(body):
    pls = [np.array([float(x) for x in re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", p)][:9]).reshape(3, 3) for p in re.findall(r'"plane" "([^"]+)"', body)]
    P = np.array([q for pl in pls for q in pl])
    cen = P.mean(axis=0)
    out = []
    for pl in pls:
        nn = np.cross(pl[1] - pl[0], pl[2] - pl[0])
        L = np.linalg.norm(nn)
        if L == 0:
            continue
        nn = nn / L
        d = nn.dot(pl[0])
        if nn.dot(cen) - d > 0:
            nn, d = -nn, -d
        out.append((nn, d))
    return P.min(axis=0), P.max(axis=0), out


def cells_of(lo_b, hi_b, planes, lo, n, C):
    """The grid cells the brush touches: (slices, mask)."""
    i0 = np.maximum(np.floor((lo_b - lo) / C).astype(int), 0)
    i1 = np.minimum(np.ceil((hi_b - lo) / C).astype(int), n)
    if (i1 <= i0).any():
        return None, None
    g = [lo[k] + (np.arange(i0[k], i1[k]) + 0.5) * C for k in range(3)]
    X, Y, Z = np.meshgrid(*g, indexing="ij")
    ins = np.ones(X.shape, dtype=bool)
    for nn, d in planes:
        ins &= (nn[0] * X + nn[1] * Y + nn[2] * Z - d) <= (abs(nn[0]) + abs(nn[1]) + abs(nn[2])) * C / 2.0 - 0.01
    return (slice(i0[0], i1[0]), slice(i0[1], i1[1]), slice(i0[2], i1[2])), ins


def main():
    ap = argparse.ArgumentParser(description="Make small world brushes func_detail.")
    ap.add_argument("vmf")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--max", type=float, default=128.0)
    ap.add_argument("--near", type=float, default=24.0)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--cell", type=float, default=4.0)
    ap.add_argument("--margin", type=float, default=48.0)
    a = ap.parse_args()
    text = open(a.vmf, encoding="utf-8", errors="surrogateescape", newline="").read()
    eol = "\r\n" if "\r\n" in text[:2000] else "\n"
    w = text.index(eol + "world" + eol)
    we = text.index(eol + "}" + eol, w)        # (the world block's closing brace: its solids sit before it)
    # the areaportals' boxes
    portals = []
    for m in re.finditer(r'"classname" "func_areaportal(?:window)?"', text):
        s0 = text.rfind(eol + "entity", 0, m.start())
        e0 = text.find(eol + "}" + eol, m.start())
        nums = [float(x) for p in re.findall(r'"plane" "([^"]+)"', text[s0:e0]) for x in re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", p)]
        if nums:
            P = np.array(nums).reshape(-1, 3)
            portals.append((P.min(axis=0) - a.near, P.max(axis=0) + a.near))
    moved, kept = [], {"displacement": 0, "sky, water or slime": 0, "tool faces only": 0, "by an areaportal": 0, "big": 0, "parts two areas": 0}
    cand = []
    pat = re.compile(r'\tsolid' + re.escape(eol) + r'\t\{' + re.escape(eol) + r'.*?' + re.escape(eol) + r'\t\}' + re.escape(eol), re.S)
    for m in pat.finditer(text, w, we + len(eol)):
        body = m.group(0)
        if "dispinfo" in body:
            kept["displacement"] += 1
            continue
        mats = [x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]
        if any(any(k in q for k in ("skybox", "water", "slime")) for q in mats):
            kept["sky, water or slime"] += 1
            continue
        if all(q.startswith("tools/") for q in mats):
            kept["tool faces only"] += 1
            continue
        nums = [float(x) for p in re.findall(r'"plane" "([^"]+)"', body) for x in re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", p)]
        P = np.array(nums).reshape(-1, 3)
        lo, hi = P.min(axis=0), P.max(axis=0)
        if any((lo <= ph).all() and (hi >= pl).all() for pl, ph in portals):
            kept["by an areaportal"] += 1
            continue
        if sorted(hi - lo)[1] >= a.max:
            kept["big"] += 1
            continue
        cand.append((m.start(), m.end(), body))
    # Each candidate in turn, with the brushes already made detail left out: on a fine grid of the space round it (its box
    # and --margin more; a cell is solid where any sealing world brush or areaportal, but this one, touches it), is the air
    # all round it already one piece? Then it joins nothing that is not joined already, and may go (a cell counted free
    # touches no brush, so a way through free cells is a real way). Two pieces round it: it may part two areas: it stays.
    # (A first grid of 16 over the whole map let one go that closed a gap thinner than a cell: brush 37542's areaportal.)
    C, M = a.cell, a.margin
    solids = []
    for m in pat.finditer(text, w, we + len(eol)):
        body = m.group(0)
        if "dispinfo" in body or not ml.seals([x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]):
            continue
        solids.append((m.start(), planes_of(body)))
    for pm in re.finditer(r'"classname" "func_areaportal(?:window)?"', text):
        s0 = text.rfind(eol + "entity", 0, pm.start())
        e0 = text.find(eol + "}" + eol, pm.start())
        for sm in pat.finditer(text, s0, e0 + len(eol)):
            solids.append((-1, planes_of(sm.group(0))))
    LO = np.array([q[1][0] for q in solids])
    HI = np.array([q[1][1] for q in solids])
    gone = set()
    for s0, e0, body in cand:
        lo_b, hi_b, planes = planes_of(body)
        llo = np.floor((lo_b - M) / C) * C
        lhi = np.ceil((hi_b + M) / C) * C
        n = ((lhi - llo) / C).astype(int)
        grid = np.zeros(n, dtype=bool)
        near = np.where((LO <= lhi).all(axis=1) & (HI >= llo).all(axis=1))[0]
        for k in near:
            start, (blo, bhi, bpl) = solids[k]
            if start == s0 or start in gone:
                continue
            sl, ins = cells_of(blo, bhi, bpl, llo, n, C)
            if sl is not None:
                grid[sl] |= ins
        sl, mine = cells_of(lo_b, hi_b, planes, llo, n, C)
        if sl is None:
            kept["parts two areas"] += 1
            continue
        me = np.zeros(n, dtype=bool)
        me[sl] = mine
        shell = ndimage.binary_dilation(me) & ~me & ~grid
        lab, nl = ndimage.label(~grid & ~me)
        labs = set(int(v) for v in np.unique(lab[shell])) - {0}
        if len(labs) > 1:
            kept["parts two areas"] += 1
            continue
        gone.add(s0)
        moved.append((s0, e0))
    print("%d world brushes made func_detail; kept as world: %s" % (len(moved), ", ".join("%s %d" % kv for kv in kept.items())))
    if a.dry or not a.out:
        return
    nxt = max(int(x) for x in re.findall(r'"id" "(\d+)"', text)) + 1
    blocks = [text[s:e] for s, e in moved]
    for s, e in sorted(moved, reverse=True):
        text = text[:s] + text[e:]
    ents = ""
    for k in range(0, len(blocks), 500):
        ents += "entity" + eol + "{" + eol + '\t"id" "%d"' % nxt + eol + '\t"classname" "func_detail"' + eol
        ents += "".join(blocks[k:k + 500])
        ents += "\teditor" + eol + "\t{" + eol + '\t\t"color" "0 180 0"' + eol + '\t\t"visgroupshown" "1"' + eol + '\t\t"visgroupautoshown" "1"' + eol + "\t}" + eol + "}" + eol
        nxt += 1
    # after the last entity (before cameras/cordons, if any)
    i = max(text.rfind(eol + "cameras" + eol), text.rfind(eol + "cordon" + eol), text.rfind(eol + "cordons" + eol))
    i = i + len(eol) if i >= 0 else len(text)
    text = text[:i] + ents + text[i:]
    open(a.out, "w", encoding="utf-8", errors="surrogateescape", newline="").write(text)
    print("written: " + a.out)


if __name__ == "__main__":
    main()
