import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ORDER = ["d3_citadel_01", "d3_citadel_02", "d3_citadel_03", "d3_citadel_04", "d3_citadel_05", "d3_breen_01", "ep1_intro",
         "ep1_citadel_00", "ep1_citadel_01", "ep1_citadel_02", "ep1_citadel_02b", "ep1_citadel_03", "ep1_citadel_04",
         "styleguide_core", "styleguide_destroyed_citadel", "d3_c17_10a", "d3_c17_10b", "ep1_c17_00", "ep1_c17_01"]


def g(r, path):
    for k in path.split("."):
        if r is None:
            return None
        if isinstance(r, list):
            r = r[int(k)] if int(k) < len(r) else None
        else:
            r = r.get(k)
    return r


def main(paths):
    R = {}
    for m in ORDER:
        p = os.path.join(HERE, "results", m + ".json")
        if os.path.exists(p):
            R[m] = json.load(open(p))
    for path in paths:
        print("##", path)
        for m, r in R.items():
            v = g(r, path)
            s = json.dumps(v)
            print("  %-28s %s" % (m, s[:260]))


if __name__ == "__main__":
    main(sys.argv[1:])
