"""The canal ring's test map: the first canal and the ring (map_layouts/ring.txt)
built as test files and joined into ONE file to compile and walk by itself, with one spawn (on the first canal's quay)
and the owner's sun. Everything stands at its real place in City 18's coordinates, so what is walked here is what goes
into the real map (the owner, 22 November: "I will need a test map once you are done with this so that I can walk it
and check on all of it (so an env_sun and spawn point please); please keep the scale correct for us to plug directly
into the c18 points").

    python3 map_ring_walk.py                         # writes lc_ring_walk.vmf
    python3 map_ring_walk.py --against c18_lc.vmf    # ...and first checks both halves and the first canal against the owner's map

The joined file is then finished as a compile wants it (the owner's compile of 23 November stopped in vbsp: "Too many
detail brush faces, max = 65536"): map_hidden_faces.py makes every face nobody can see nodraw (vbsp leaves those out),
map_slim.py takes out the vertices_plus copies (last: the other tools read them), map_budget.py prints what it spends
of the limits, and map_walk.py and map_stairs.py check the finished file.

The real map is made with map_merge.py from the plain (not test) files, as ever:
    python3 map_build.py canal && python3 map_build.py chain --layout map_layouts/ring.txt --first-node 5000
    python3 map_merge.py c18_lc.vmf lc_canal.vmf lc_ring.vmf ... --out c18_lc_merged.vmf
(the ring stands in the place of the old ring, lc_ring.vmf: never merge both.) The two finishing passes over that file
would reach the owner's own brushes too (their hidden faces made nodraw): ask the owner first. Its grid is bigger: --cell
12 or 16 there if 8 runs out of memory.
"""

import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def run(args, show=()):
    print("  " + " ".join(args[1:]))
    out = subprocess.run(args, cwd=HERE, capture_output=True, text=True)
    lines = (out.stdout + out.stderr).splitlines()
    for l in lines:
        if "PROBLEM" in l or "checked against" in l or "Traceback" in l or "Error" in l or any(w in l for w in show):
            print("    " + l.strip())
    if out.returncode:
        print("\n".join(lines[-15:]))
        raise SystemExit("stopped: %s failed" % " ".join(args[1:3]))


def main():
    ap = argparse.ArgumentParser(description="Build the canal ring's test map (the first canal and both halves, joined, a spawn and a sun).")
    ap.add_argument("--against", nargs="+", help="the owner's VMF (and any other piece's): check the ring against them first")
    ap.add_argument("--out", default="lc_ring_walk.vmf")
    ap.add_argument("--cell", type=int, default=8, help="map_hidden_faces.py's cube (8: finer finds more; 16 takes an eighth of the memory)")
    args = ap.parse_args()
    py = sys.executable
    plain = [("canal", []), ("chain", ["--layout", "map_layouts/ring.txt", "--first-node", "5000"])]
    if args.against:
        print("checking against: " + " ".join(args.against))
        for piece, extra in plain:
            run([py, "map_build.py", piece] + extra + ["--against"] + args.against + ["--out", os.devnull])
    print("building the test pieces:")
    names = ["lc_canal_test.vmf", "lc_ring_test.vmf"]
    for (piece, extra), name in zip(plain, names):
        run([py, "map_build.py", piece] + extra + ["--test", "--out", name])
    print("joining them:")
    run([py, "map_merge.py", "--blank"] + names + ["--out", args.out])
    for name in names:
        os.remove(os.path.join(HERE, name))
    import map_budget
    print("  joined: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("finishing it:")
    run([py, "map_hidden_faces.py", args.out, args.out, "--cell", str(args.cell)], show=("can never be seen", "LOST", "written", "not written"))
    run([py, "map_slim.py", args.out], show=("MB",))
    print("  finished: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("checking the finished file:")
    run([py, "map_walk.py", args.out], show=("problems", "  "))
    run([py, "map_stairs.py", args.out], show=("flights", "  "))
    print("written: %s (compile it alone: a spawn on the first canal's quay, the owner's sun)" % args.out)


if __name__ == "__main__":
    main()
