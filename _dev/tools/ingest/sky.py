"""Living City map ingestion: find the 3D skybox room round the sky_camera and flag what is in it.

    find(m)   sets m.sky_box (lo, hi or None), m.sky_camera, m.sky_how, m.b_sky and each entity's .sky

First the toolsskybox brushes round the camera, one each way along every axis (a sealed room). If one side is
open, the brushes touching each other round the camera (within 8192) make the room instead. A room that holds
the play space (most player starts and AI nodes) is not used.
"""
import numpy as np


def find(m):
    m.sky_box, m.sky_camera, m.sky_how = None, None, "no sky_camera"
    cams = [e for e in m.ents if e.cls == "sky_camera" and not e.hidden and e.origin is not None]
    if not cams:
        return
    c = cams[0].origin
    m.sky_camera = c
    skyb = [i for i in range(len(m.b_owner)) if m.b_owner[i] < 0 and not m.b_hidden[i]
            and any("toolsskybox" in m.mats[m.f_mat[f]] for f in range(m.b_f0[i], m.b_f1[i]))]
    lo, hi = [None] * 3, [None] * 3
    for i in skyb:
        bl, bh = m.b_lo[i], m.b_hi[i]
        for ax in range(3):
            o1, o2 = (ax + 1) % 3, (ax + 2) % 3
            if bl[o1] <= c[o1] <= bh[o1] and bl[o2] <= c[o2] <= bh[o2]:
                if bl[ax] >= c[ax] and (hi[ax] is None or bl[ax] < hi[ax]):
                    hi[ax] = bl[ax]
                if bh[ax] <= c[ax] and (lo[ax] is None or bh[ax] > lo[ax]):
                    lo[ax] = bh[ax]
    if all(v is not None for v in lo + hi):
        box = (np.array(lo) - 16, np.array(hi) + 16)
        how = "sealed by toolsskybox"
    else:      # (not sealed: the touching brushes round the camera, as long as no player start is inside)
        box, how = component(m, c), "touching brushes round the sky_camera"
    if box is None:
        m.sky_how = "sky_camera found but no room round it"
        return
    starts = [e.origin for e in m.ents if e.cls in ("info_player_start", "info_node") and e.origin is not None and not e.hidden]
    inside = [p for p in starts if np.all(p >= box[0]) and np.all(p <= box[1])]
    if starts and len(inside) > max(2, 0.2 * len(starts)):
        m.sky_how = "room round the sky_camera holds the play space: not used"
        return
    m.sky_box, m.sky_how = box, how
    cen = (m.b_lo + m.b_hi) / 2
    m.b_sky = np.all((cen >= box[0]) & (cen <= box[1]), axis=1)
    for e in m.ents:
        if e.origin is not None and np.all(e.origin >= box[0]) and np.all(e.origin <= box[1]):
            e.sky = True

def component(m, c, reach=8192.0, pad=2.0):
    near = np.where(np.all((m.b_lo <= c + reach) & (m.b_hi >= c - reach), axis=1) & ~m.b_hidden)[0]
    if not len(near):
        return None
    lo, hi = m.b_lo[near], m.b_hi[near]
    par = list(range(len(near)))

    def f(i):
        while par[i] != i:
            par[i] = par[par[i]]
            i = par[i]
        return i
    touch = np.all((lo[:, None] <= hi[None] + pad) & (lo[None] <= hi[:, None] + pad), axis=2)
    for i, j in zip(*np.nonzero(np.triu(touch, 1))):
        a, b = f(i), f(j)
        if a != b:
            par[a] = b
    roots = np.array([f(i) for i in range(len(near))])
    best = None
    for r in set(roots.tolist()):
        idx = np.where(roots == r)[0]
        l, h = lo[idx].min(axis=0), hi[idx].max(axis=0)
        if np.all(c >= l - 1) and np.all(c <= h + 1) and (best is None or len(idx) < best[0]):
            best = (len(idx), l, h)
    return (best[1], best[2]) if best else None
