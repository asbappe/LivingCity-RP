import json, os, sys, pickle
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import arch_lib as A
import analyse as Z
res = {}
for nm in sys.argv[1:]:
    d = pickle.load(open(os.path.join(HERE, "cache", nm + ".pkl"), "rb"))
    B = d["brushes"]
    S = [b for b in B if b["cls"] in A.STRUCT_CLASSES and not b["disp"]]
    comb = [b for b in S if b["kind"] == "combine"]
    old = [b for b in S if b["kind"] == "old"]
    res[nm] = Z.doors(B, comb, old, d["ents"])
    print(nm, json.dumps(res[nm])[:400], flush=True)
json.dump(res, open(os.path.join(HERE, "results", "doors.json"), "w"), indent=1)
