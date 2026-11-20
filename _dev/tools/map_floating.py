#!/usr/bin/env python3
"""
Living City: props that touch nothing (the owner found floating lamps and things more than once).

    python3 map_floating.py lc_showroom_1_test.vmf [more.vmf ...]

Lists every prop whose box touches no brush (floor, ceiling, wall) and no other prop, within 6 units. Rough on
purpose: boxes from the models' own files, turned by yaw only (a tilted prop is skipped); a prop on a mud mound or
any displacement shows here though it lands on it (displacements are not read). Free: run it on every piece.
"""
import sys, math, re, collections
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import map_view as mv, map_assets as ma
SKIP = re.compile(r'gibs|humans/|charple|corpse|zombie|headcrab|/rope|sprites/|glow')
def boxes_of(root):
    out = []
    for top in root.kids:
        if top.name not in ('world', 'entity'): continue
        cls = top.kv.get('classname', 'worldspawn')
        if cls.startswith('trigger') or cls in ('func_areaportal', 'func_illusionary'): continue
        for s in top.kids:
            if s.name != 'solid': continue
            pts, mats = [], set()
            for side in s.kids:
                if side.name != 'side': continue
                mats.add(side.kv.get('material', '').lower())
                vp = [k for k in side.kids if k.name == 'vertices_plus']
                if vp: pts += [tuple(mv.nums(x)) for k, x in vp[0].rows if k == 'v']
            if not pts or mats <= {'tools/toolsskybox', 'tools/toolsclip', 'tools/toolsplayerclip', 'tools/toolstrigger'}: continue
            out.append(([min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]))
    return out
def prop_box(e):
    m = e.kv.get('model', '').lower()
    bb = ma.size(m)
    if not bb: return None
    o = mv.nums(e.kv['origin']); a = mv.nums(e.kv.get('angles', '0 0 0'))
    if abs(a[0]) > 1 or abs(a[2]) > 1: return 'tilted'
    yaw = math.radians(a[1]); c, s = math.cos(yaw), math.sin(yaw)
    xs, ys = [], []
    for x in (bb[0], bb[3]):
        for y in (bb[1], bb[4]):
            xs.append(o[0] + x * c - y * s); ys.append(o[1] + x * s + y * c)
    return [min(xs), min(ys), o[2] + bb[2]], [max(xs), max(ys), o[2] + bb[5]]
def touches(a, b, g=6):
    return all(a[0][i] - g <= b[1][i] and b[0][i] - g <= a[1][i] for i in range(3))
for path in sys.argv[1:]:
    root = mv.read(path)
    bx = boxes_of(root)
    props = []
    for e in root.kids:
        if e.name == 'entity' and e.kv.get('classname', '').startswith(('prop_static', 'prop_dynamic', 'prop_physics', 'prop_door')) and 'origin' in e.kv:
            if e.kv.get('parentname'): continue
            if SKIP.search(e.kv.get('model', '').lower()): continue
            pb = prop_box(e)
            if pb and pb != 'tilted': props.append((e.kv['model'], pb))
    bad = []
    for i, (m, pb) in enumerate(props):
        if any(touches(pb, b) for b in bx): continue
        if any(j != i and touches(pb, q[1], 3) for j, q in enumerate(props)): continue
        bad.append((m.split('/')[-1], [int(t) for t in pb[0]]))
    print("%s: %d props, %d touch nothing" % (path.split('/')[-1], len(props), len(bad)))
    for m, p in bad[:30]: print("   ", m, p)
