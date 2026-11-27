#!/usr/bin/env python3
"""map_leak_points.py: entities a compile would call leaked, before the owner compiles

    python3 map_leak_points.py FILE.vmf

vbsp floods the void from outside the map and stops at the first entity whose point it reaches ("Entity trigger_multiple
(3392.00 -6016.00 656.00) leaked!", the owner's compile of 27 November). A point entity's point is its origin; a brush
entity's is the "origin" key Hammer writes when it saves (the middle of its brushes), so a file the owner has saved in
Hammer can leak where the generator's own file did not: a trigger whose middle lies in the void (it reached over a
buried chain's roof). This floods the outside through the world's box brushes and prints every entity standing in air
it reaches. A world brush with a see-through, water, clip or tool face does not seal (as vbsp turns it into a window or
water); sloped and displaced brushes are left out (counted as air: it errs toward reporting too many, never too few, for
the boxes it reads). Ends with the count: 0 is what a compile needs.
"""
import sys, re, bisect
from collections import deque
t = open(sys.argv[1], errors="replace").read().replace("\r\n", "\n")
wi = t.index("\nentity\n")
NONSEAL = ("clip", "trigger", "skip", "hint", "areaportal", "water", "glass", "fence", "grate", "chainlink", "blocklight", "fog", "occluder", "invisible", "toolsblack_trans")
solid = []
for m in re.finditer(r'\n\tsolid\n\t\{(.*?)\n\t\}', t[:wi], re.S):
    body = m.group(1)
    if "dispinfo" in body: continue
    mats = [x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]
    if any(any(w in x for w in NONSEAL) for x in mats): continue
    planes = re.findall(r'"plane" "\(([-\d. e]+)\) \(([-\d. e]+)\) \(([-\d. e]+)\)"', body)
    P = [[tuple(float(x) for x in p.split()) for p in tri] for tri in planes]
    if len(P) != 6 or not all(any(q[0][a] == q[1][a] == q[2][a] for a in range(3)) for q in P): continue
    pts = [p for q in P for p in q]
    solid.append(tuple(min(p[a] for p in pts) for a in range(3)) + tuple(max(p[a] for p in pts) for a in range(3)))
axes = []
for a in range(3):
    cuts = sorted(set([b[a] for b in solid] + [b[a + 3] for b in solid]))
    axes.append([cuts[0] - 64] + cuts + [cuts[-1] + 64])
n = [len(ax) - 1 for ax in axes]
full = set()
for b in solid:
    r = [(bisect.bisect_left(axes[a], b[a]), bisect.bisect_left(axes[a], b[a + 3])) for a in range(3)]
    for i in range(*r[0]):
        for j in range(*r[1]):
            for k in range(*r[2]):
                full.add((i, j, k))
# the outside: every cell on the grid's skin, flooded inward through air
out = set(); q = deque()
for i in range(n[0]):
    for j in range(n[1]):
        for k in (0, n[2] - 1):
            c = (i, j, k)
            if c not in full and c not in out: out.add(c); q.append(c)
for i in range(n[0]):
    for k in range(n[2]):
        for j in (0, n[1] - 1):
            c = (i, j, k)
            if c not in full and c not in out: out.add(c); q.append(c)
for j in range(n[1]):
    for k in range(n[2]):
        for i in (0, n[0] - 1):
            c = (i, j, k)
            if c not in full and c not in out: out.add(c); q.append(c)
while q:
    c = q.popleft()
    for a in range(3):
        for d in (-1, 1):
            m2 = list(c); m2[a] += d; m2 = tuple(m2)
            if 0 <= m2[a] < n[a] and m2 not in full and m2 not in out:
                out.add(m2); q.append(m2)
def cell(p): return tuple(min(max(bisect.bisect_right(axes[a], p[a]) - 1, 0), n[a] - 1) for a in range(3))
bad = 0
for m in re.finditer(r'\nentity\n\{\n(.*?)\n\}', t[wi:], re.S):
    kv = dict(re.findall(r'^\t"([^"]+)" "([^"]*)"$', m.group(1), re.M))
    o = kv.get("origin")
    if not o: continue
    p = tuple(float(x) for x in o.split())
    if p == (0.0, 0.0, 0.0): continue
    c = cell(p)
    on_face = any(p[a] in (axes[a][c[a]],) for a in range(3))
    if c in out:
        bad += 1
        if bad <= 60:
            print("OUTSIDE:", kv.get("classname"), kv.get("targetname", ""), o, "(on a cell face)" if on_face else "")
print("entities in air the outside reaches:", bad)
sys.exit(1 if bad else 0)
