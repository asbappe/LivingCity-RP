"""Does every areaportal part two areas? (the owner's compile, 24 November: "Brush 2676: areaportal brush doesn't touch
two areas ... AREAPORTAL LEAKED", after solid blocks behind the bunker entrance's walls were deleted.)

    python3 map_areas.py FILE.vmf [--cell 8]

Lays the map on a grid of cubes the way vbsp splits areas, roughly: world brushes wall space off (but not clip, trigger,
hint, skip and other tool-only brushes), and so do the func_areaportal brushes; func_detail, displacements and every
other entity do not. Then it labels the pieces of air and, for each areaportal, looks a little way out from both of its
broad faces: the two sides must be two different pieces. Prints one line per portal and "AREAPORTAL LEAK" for a portal
whose two sides join some other way (a hole in a world wall, or a func_detail wall with no world brush behind it).
Needs numpy and scipy (pip install scipy).
"""
import argparse
import re

import numpy as np

NOSEAL = ('tools/toolsclip', 'tools/toolsplayerclip', 'tools/toolsnpcclip', 'tools/toolstrigger', 'tools/toolshint',
          'tools/toolsskip', 'tools/toolsareaportal', 'tools/toolsoccluder', 'tools/toolsfog', 'tools/toolslight')


def solids(block):
    out = []
    for m in re.finditer(r'\tsolid\r?\n\t*\{(.*?)\n\t*editor', block, re.S):
        body = m.group(1)
        if 'dispinfo' in body:
            continue
        pls = [np.array([float(x) for x in re.findall(r'[-\d.e]+', p)]).reshape(3, 3) for p in re.findall(r'"plane" "([^"]+)"', body)]
        mats = [x.lower() for x in re.findall(r'"material" "([^"]+)"', body)]
        out.append((pls, mats))
    return out


def planes_of(pls):
    P = np.array([p for pl in pls for p in pl])
    cen = P.mean(axis=0)
    out = []
    for pl in pls:
        nn = np.cross(pl[1] - pl[0], pl[2] - pl[0])
        L = np.linalg.norm(nn)
        if L < 1e-9:
            continue
        nn = nn / L
        d = nn @ pl[0]
        if nn @ cen - d > 0:
            nn, d = -nn, -d
        out.append((nn, d))
    return P, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('vmf')
    ap.add_argument('--cell', type=float, default=8.0)
    a = ap.parse_args()
    import scipy.ndimage as ndi
    C = a.cell
    t = open(a.vmf, encoding='utf-8', errors='replace', newline='').read()
    w0 = t.find('\nworld')
    w1 = t.find('\nentity', w0)
    seal = [s for s in solids(t[w0:w1]) if not all(m in NOSEAL for m in s[1])]
    portals = []      # (name, brush planes)
    for m in re.finditer(r'"classname" "func_areaportal(window)?"', t):
        s = t.rfind('\nentity', 0, m.start())
        e = t.find('\nentity', m.start())
        blk = t[s:len(t) if e < 0 else e]
        nm = re.search(r'"targetname" "([^"]*)"', blk)
        sid = re.search(r'solid\r?\n\t*\{\r?\n\t*"id" "(\d+)"', blk)
        for so in solids(blk):
            portals.append(((nm.group(1) if nm else 'unnamed') + ' (brush %s)' % (sid.group(1) if sid else '?'), so[0]))
    allp = np.array([p for s in seal for pl in s[0] for p in pl] + [p for _, pls in portals for pl in pls for p in pl])
    lo = allp.min(axis=0) - 2 * C
    hi = allp.max(axis=0) + 2 * C
    n = np.ceil((hi - lo) / C).astype(int)
    solid = np.zeros(n, dtype=bool)

    def mark(pls):      # (a cube the brush overlaps, by its planes pushed out half a cube: thin brushes are not missed)
        P, planes = planes_of(pls)
        b0 = np.maximum(((P.min(axis=0) - lo) // C).astype(int) - 1, 0)
        b1 = np.minimum(((P.max(axis=0) - lo) // C).astype(int) + 2, n)
        g = [lo[q] + (np.arange(b0[q], b1[q]) + 0.5) * C for q in range(3)]
        X, Y, Z = np.meshgrid(*g, indexing='ij')
        ins = np.ones(X.shape, dtype=bool)
        for nn, d in planes:
            ins &= nn[0] * X + nn[1] * Y + nn[2] * Z - d < (C / 2) * abs(nn).sum() - 0.01
        solid[b0[0]:b1[0], b0[1]:b1[1], b0[2]:b1[2]] |= ins
    for s in seal:
        mark(s[0])
    for _, pls in portals:
        mark(pls)
    lab, nl = ndi.label(~solid)
    del solid
    bad = 0
    for name, pls in portals:
        P, _ = planes_of(pls)
        b_lo, b_hi = P.min(axis=0), P.max(axis=0)
        ax = int(np.argmin(b_hi - b_lo))      # (its thin way: the portal faces along it)
        cen = (b_lo + b_hi) / 2
        sides = []
        for sgn in (-1, 1):
            q = cen.copy()
            q[ax] = (b_lo[ax] if sgn < 0 else b_hi[ax]) + sgn * 1.5 * C
            i = tuple(((q - lo) // C).astype(int))
            sides.append(int(lab[i]))
        where = '(%d %d %d)' % tuple(cen)
        if 0 in sides:
            print('  %s at %s: one side is in a wall; look at it by hand' % (name, where))
        elif sides[0] == sides[1]:
            bad += 1
            print('AREAPORTAL LEAK: %s at %s: its two sides join some other way' % (name, where))
        else:
            print('  %s at %s: parts two areas' % (name, where))
    print('%d areaportals, %d leak' % (len(portals), bad))
    raise SystemExit(1 if bad else 0)


if __name__ == '__main__':
    main()
