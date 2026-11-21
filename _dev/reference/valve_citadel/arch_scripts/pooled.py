import json, os
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
from summarise import ORDER
CIT = [m for m in ORDER if not m.startswith(("d3_c17", "ep1_c17"))]
C17 = [m for m in ORDER if m.startswith(("d3_c17", "ep1_c17"))]
D = json.load(open(os.path.join(HERE, "results", "doors.json")))
R = {m: json.load(open(os.path.join(HERE, "results", m + ".json"))) for m in ORDER if os.path.exists(os.path.join(HERE, "results", m + ".json"))}
def pool_off(maps, key):
    a = o = 0
    for m in maps:
        x = R[m].get(key)
        if x: a += x["area"]; o += x["area"] * x["off_axis_share"]
    return round(o / max(1, a), 3), round(a / 1e6)
print("Combine off-axis (citadel)", pool_off([m for m in CIT if m in R], "angles_combine"))
print("Old off-axis (c17 intact 10a 10b)", pool_off(["d3_c17_10a", "d3_c17_10b"], "angles_old"), "(all c17)", pool_off([m for m in C17 if m in R], "angles_old"))
def pool_art(maps, key):
    n = lt = ge = 0; meds = []
    for m in maps:
        w = (R[m].get(key) or {}).get("articulated(3+ levels)") or {}
        if w.get("n"):
            n += w["n"]; lt += w["n"] * w["sym_lt_0.6"]; ge += w["n"] * w["sym_ge_0.9"]; meds.append(w["sym_pct"][2])
    return n, round(lt / max(1, n), 3), round(ge / max(1, n), 3), sorted(meds)
print("articulated walls Combine", pool_art([m for m in CIT if m in R], "walls_combine"))
print("articulated walls old", pool_art([m for m in ORDER if m in R], "walls_old"))
def pool_pass(maps, key):
    v = []
    for m in maps:
        p = (R[m].get(key) or {}).get("passages")
        if p: v.append((m, p["n"], p["sides_match_pct"][2]))
    return v
print("passages Combine", pool_pass([m for m in CIT if m in R], "walls_combine"))
print("passages old", pool_pass([m for m in ORDER if m in R], "walls_old"))
dc = [e[1] for m in CIT for e in (D.get(m, {}).get("combine") or {}).get("examples", [])]
allc = []; allo = []
for m in ORDER:
    for kind, L in (("combine", allc), ("old", allo)):
        d = D.get(m, {}).get(kind)
        if d: L.append((m, d["n"], d["iou_pct"][2]))
print("doors combine", allc); print("doors old", allo)
def pool_scale(maps, key):
    p = g8 = g16 = 0
    for m in maps:
        s = R[m].get(key)
        if s: p += s["pairs"]; g8 += s["pairs"] * s["ge8"]; g16 += s["pairs"] * s["ge16"]
    return p, round(g8 / max(1, p), 3), round(g16 / max(1, p), 3)
print("scale combine citadel", pool_scale([m for m in CIT if m in R], "scale_combine"))
print("scale old all", pool_scale([m for m in ORDER if m in R], "scale_old"))
lay = []
for m in CIT:
    if m in R: lay.append(round(sum(v for k, v in R[m]["stacks"]["layers_by_area"] if k >= 3), 2))
print("3+ layers share of wall-stack area per citadel map", sorted(lay))
pl = [(m, R[m]["plates"]["plate_share"]) for m in CIT if m in R]
print("plate share", sorted(v for _, v in pl))
