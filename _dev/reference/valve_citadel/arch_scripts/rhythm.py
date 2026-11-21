import sys, json, pickle, os
import numpy as np
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import analyse as Z, arch_lib as A
def classify(sp):
    sp = np.array(sp, float)
    if len(sp) < 2 or sp.mean() <= 0: return None
    cv = sp.std() / sp.mean()
    if cv < 0.05: return "even"
    a, b = sp[0::2], sp[1::2]
    for s, l in ((a, b), (b, a)):
        if len(s) and len(l) and s.max() <= 40 and l.min() > 2 * max(1, s.max()) and (s.max() - s.min()) <= 4:
            return "paired"
    if cv <= 0.25: return "near even"
    return "free"
out = {}
for kind in ("combine", "old"):
    tot = Counter(); pairgap = []; pairpitch = []; pitch_cv = []; evenpitch = Counter()
    for nm in sys.argv[1:]:
        d = pickle.load(open(os.path.join(HERE, "cache", nm + ".pkl"), "rb"))
        S = [b for b in d["brushes"] if b["cls"] in A.STRUCT_CLASSES and not b["disp"] and b["kind"] == kind]
        if len(S) < 10: continue
        for r in Z.rows_of(S, range(len(S)), Z.sig_combine):
            # rows_of keeps the first 12 spacings
            c = classify(r["spacings"])
            if not c: continue
            tot[c] += 1
            sp = np.array(r["spacings"], float)
            if c == "paired":
                a, b = sp[0::2], sp[1::2]
                s, l = (a, b) if a.max() <= 40 else (b, a)
                pairgap.append(float(s.mean())); pp = l + s.mean(); pairpitch += list(pp); pitch_cv.append(float(pp.std() / pp.mean()))
            if c == "even": evenpitch[int(round(sp.mean()))] += 1
    n = sum(tot.values()) or 1
    out[kind] = {"rows": n, "kinds": {k: round(v / n, 3) for k, v in tot.most_common()},
                 "pair_gap_pct": Z.pct(pairgap), "pair_pitch_pct": Z.pct(pairpitch),
                 "pair_pitch_cv_pct": Z.pct(pitch_cv), "even_pitch_top": evenpitch.most_common(8)}
print(json.dumps(out))
