"""How far the Combine's flat slabs (floors, shelves, ledges, roofs) reach past what holds them up."""
import json
import os
import pickle
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import arch_lib as A  # noqa: E402
from analyse import plate_dims, pct, touch  # noqa: E402


def run(name):
    d = pickle.load(open(os.path.join(HERE, "cache", name + ".pkl"), "rb"))
    B = [b for b in d["brushes"] if b["cls"] in A.STRUCT_CLASSES and not b["disp"]]
    occ = [b for b in B if A.solid_occluder(b)]
    G = A.Grid(occ, 256)
    out = {}
    for kind in ("combine", "old"):
        slabs = []
        for b in B:
            if b["kind"] != kind:
                continue
            t, a, c, orient, nt = plate_dims(b)
            if orient != "lying" or t > 64 or a < 32:
                continue
            bot = [f for f in b["faces"] if f["n"][2] < -0.99]
            if not bot:
                continue
            f = bot[0]
            P = f["pts"]
            x0, y0 = P[:, 0].min(), P[:, 1].min()
            x1, y1 = P[:, 0].max(), P[:, 1].max()
            xs = np.arange(x0 + 4, x1, 16.0)
            ys = np.arange(y0 + 4, y1, 16.0)
            if len(xs) == 0 or len(ys) == 0:
                continue
            X, Y = np.meshgrid(xs, ys, indexing="ij")
            z = P[:, 2].min() - 2
            Q = np.stack([X.ravel(), Y.ravel(), np.full(X.size, z)], 1)
            # keep points that lie under the slab itself (it may be sloped in plan)
            inside_slab = ((np.column_stack([Q[:, :2], np.full(len(Q), z + 3)]) @ b["N"].T) - b["D"] <= 0.5).all(1)
            Q = Q[inside_slab]
            if len(Q) < 4:
                continue
            sup = np.zeros(len(Q), bool)
            for j in G.near(b["box"], 4):
                o = occ[j]
                if o is b:
                    continue
                m = ((Q @ o["N"].T) - o["D"] <= 0.01).all(1)
                sup |= m
            share = float(sup.mean())
            # which edges are held: a point under the edge strip is held, or a brush touches that edge from the side
            n2 = None
            for nn in b["N"]:
                if abs(nn[2]) < 0.05:
                    n2 = nn
                    break
            if n2 is None:
                continue
            n3 = np.array([-n2[1], n2[0], 0.0])
            V = b["V"]
            held = []
            att = [occ[j] for j in G.near(b["box"], 2) if occ[j] is not b and touch(b["box"], occ[j]["box"], 1)
                   and occ[j]["box"][2] < b["box"][2] - 32]
            AP = []
            for o in att:      # sample the touching brushes' corners and centre in plan, at the slab's height
                AP.append(o["cen"][:2])
                AP.extend([v[:2] for v in o["V"]])
            AP = np.array(AP) if AP else np.zeros((0, 2))
            for ax in (n2, n3):
                a2 = ax[:2]
                lo_, hi_ = float((V[:, :2] @ a2).min()), float((V[:, :2] @ a2).max())
                pq = Q[:, :2] @ a2
                for side, edge in (("lo", lo_), ("hi", hi_)):
                    strip = np.abs(pq - edge) <= 24
                    h = bool((sup & strip).any())
                    if not h and len(AP):
                        pa = AP @ a2
                        h = bool(((pa <= edge + 4) & (pa >= edge - 64) if side == "lo" else (pa >= edge - 4) & (pa <= edge + 64)).any()) and False
                    held.append(h)
                held_ax = held
            # side attachment: a touching brush whose box overlaps an edge line
            for k, (ax, side) in enumerate([(n2, "lo"), (n2, "hi"), (n3, "lo"), (n3, "hi")]):
                if held[k]:
                    continue
                a2 = ax[:2]
                lo_, hi_ = float((V[:, :2] @ a2).min()), float((V[:, :2] @ a2).max())
                edge = lo_ if side == "lo" else hi_
                for o in att:
                    pv = o["V"][:, :2] @ a2
                    if (side == "lo" and pv.min() <= edge + 2 and pv.max() <= edge + 24) or (side == "hi" and pv.max() >= edge - 2 and pv.min() >= edge - 24):
                        held[k] = True
                        break
            w2 = float(np.ptp(V[:, :2] @ n2[:2]))
            w3 = float(np.ptp(V[:, :2] @ n3[:2]))
            nh = sum(held)
            if (held[0] and held[1]) or (held[2] and held[3]):
                kind_ = "span"
                reach = 0.0
            elif nh == 1:
                kind_ = "cantilever"
                reach = w2 if (held[0] or held[1]) else w3
            elif nh == 2:
                kind_ = "cantilever"       # held at a corner: two neighbouring edges
                reach = max(w2, w3)
            elif sup.any():
                kind_ = "overhang all round"
                S = Q[sup][:, :2]
                U = Q[~sup][:, :2]
                reach = float(np.sqrt(((U[:, None, :] - S[None, :, :]) ** 2).sum(2)).min(1).max()) if len(U) else 0.0
            else:
                kind_ = "hung"
                reach = None
            slabs.append((share, reach, t, c, kind_))
        if not slabs:
            continue
        sh = np.array([s[0] for s in slabs])
        rc = [s[1] for s in slabs if s[1] is not None]
        cant = [s for s in slabs if s[4] == "cantilever"]
        from collections import Counter
        kinds = Counter(s[4] for s in slabs)
        out[kind] = {"slabs": len(slabs), "kinds": {k: round(v / len(slabs), 3) for k, v in kinds.items()},
                     "overhang_reach_pct": pct([s[1] for s in slabs if s[4] == "overhang all round"]),
                     "cantilever_reach_pct": pct([s[1] for s in cant]),
                     "cantilever_reach_over_thick_pct": pct([s[1] / max(1, s[2]) for s in cant]),
                     "cantilever_thick_pct": pct([s[2] for s in cant])}
    return out


if __name__ == "__main__":
    res = {}
    p = os.path.join(HERE, "results", "cantilever.json")
    if os.path.exists(p):
        res = json.load(open(p))
    for nm in sys.argv[1:]:
        res[nm] = run(nm)
        print(nm, json.dumps(res[nm])[:600], flush=True)
        json.dump(res, open(p, "w"), indent=1)
