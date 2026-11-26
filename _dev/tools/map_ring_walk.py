"""The canal ring's test map: the first canal, the ring (map_layouts/ring.txt), the crypt's inlet, and the bunker forest
down its tunnel (map_layouts/bunker_way.txt), built as test files and joined into ONE file to compile and walk by itself, with one spawn (on the first canal's quay)
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
    ap.add_argument("--quick", action="store_true", help="skip the nodraw pass (about 40 minutes): only to look the map over; vbsp needs the pass (its vertex limit)")
    args = ap.parse_args()
    py = sys.executable
    plain = [("canal", []), ("chain", ["--layout", "map_layouts/ring.txt", "--first-node", "5000"]),
             ("chain", ["--layout", "map_layouts/inlet.txt", "--first-node", "9000"]),      # (the crypt's inlet off the east side, 26 November)
             # (the bunker forest, down Valve's long tunnel from the first canal's east gate: the owner, 26 November, "please
             #  stitch in the forest bunker to the ring now ... down a longer tunnel". The forest is the generator's own build,
             #  3520 east of where it was first set: the owner's file of it, edited in Hammer, is not in this test map)
             ("chain", ["--layout", "map_layouts/bunker_way.txt", "--first-node", "9500"]),
             ("forest_bunker", [])]      # (built at its first place, then moved: map_shift.py, below)
    if args.against:
        print("checking against: " + " ".join(args.against))
        for piece, extra in plain:
            run([py, "map_build.py", piece] + extra + ["--against"] + args.against + ["--out", os.devnull])
    print("building the test pieces:")
    names = ["lc_canal_test.vmf", "lc_ring_test.vmf", "lc_inlet_test.vmf", "lc_bunker_way_test.vmf", "lc_forest_bunker_test.vmf"]
    for (piece, extra), name in zip(plain, names):
        run([py, "map_build.py", piece] + extra + ["--test", "--out", name])
    # (the forest's builder is written for its first place, its west gate at the canal's east gate: the finished file is
    #  moved to the tunnel's far end, 3520 east)
    run([py, "map_shift.py", "lc_forest_bunker_test.vmf", "lc_forest_bunker_east_test.vmf", "3520", "0"], show=("SHIFT",))
    os.remove(os.path.join(HERE, "lc_forest_bunker_test.vmf"))
    names[-1] = "lc_forest_bunker_east_test.vmf"
    print("joining them:")
    run([py, "map_merge.py", "--blank"] + names + ["--out", args.out])
    for name in names:
        os.remove(os.path.join(HERE, name))
    import map_budget
    print("  joined: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("finishing it:")
    if not args.quick:
        run([py, "map_hidden_faces.py", args.out, args.out, "--cell", str(args.cell)], show=("can never be seen", "LOST", "LEAK", "written", "not written"))
    run([py, "map_slim.py", args.out], show=("MB",))
    print("  finished: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("checking the finished file:")
    # (the walk starts at the spawn and also at three places in the bunker forest: inside the bunker before its door's
    #  button, in the silo's secret room and in the leader's way out. The forest's ground is displaced, which the walk
    #  cannot read; the bunker's door opens only from the inside and the other two lie behind secret doors. The forest's
    #  own build walks its inside; what this walk proves there is the way from the canal down the tunnel to its gate)
    run([py, "map_walk.py", args.out, "--also", "14768", "4260", "410", "--also", "12688", "7024", "-142", "--also", "11748", "4770", "410"], show=("problems", "  "))
    run([py, "map_stairs.py", args.out], show=("flights", "  "))
    fin = map_budget.count(os.path.join(HERE, args.out))
    for key in ("faces", "verts"):
        if map_budget.over(fin, key):
            print("  OVER vbsp's limit on %s: it will not compile" % key)
    print("written: %s (compile it alone: a spawn on the first canal's quay, the owner's sun)" % args.out)


if __name__ == "__main__":
    main()
