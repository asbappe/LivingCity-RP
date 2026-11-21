import json, os, glob
HERE = os.path.dirname(os.path.abspath(__file__))
from summarise import ORDER
D = json.load(open(os.path.join(HERE, "results", "doors.json")))
rows = []
for m in ORDER:
    p = os.path.join(HERE, "results", m + ".json")
    if not os.path.exists(p): continue
    r = json.load(open(p))
    ac = r["angles_combine"]; ao = r.get("angles_old") or {}
    st = r["stacks"]; l3 = sum(v for k, v in st["layers_by_area"] if k >= 3)
    wc = r.get("walls_combine") or {}; wo = r.get("walls_old") or {}
    art = wc.get("articulated(3+ levels)") or {}; arto = wo.get("articulated(3+ levels)") or {}
    pas = (wc.get("passages") or {}).get("sides_match_pct") or [None]*5
    dc = (D.get(m, {}).get("combine") or {}); do = (D.get(m, {}).get("old") or {})
    sc = r.get("scale_combine") or {}; so = r.get("scale_old") or {}
    print("%-26s offC %.3f offO %s | layers3+ %.2f | artC n%s med %s lt.6 %s | artO n%s med %s lt.6 %s | pass %s | doorC %s/%s doorO %s/%s | ge8 C %s O %s" % (
        m, ac["off_axis_share"], ao.get("off_axis_share"), l3,
        art.get("n"), (art.get("sym_pct") or [None]*5)[2], art.get("sym_lt_0.6"),
        arto.get("n"), (arto.get("sym_pct") or [None]*5)[2], arto.get("sym_lt_0.6"),
        pas[2], dc.get("n"), (dc.get("iou_pct") or [None]*5)[2], do.get("n"), (do.get("iou_pct") or [None]*5)[2],
        sc.get("ge8"), so.get("ge8")))
