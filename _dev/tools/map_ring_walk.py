"""The canal ring's test map: the first canal, the ring (map_layouts/ring.txt), the crypt's inlet, and the bunker forest
down its tunnel (map_layouts/bunker_way.txt), built as test files and joined into ONE file to compile and walk by itself, with one spawn (on the first canal's quay)
and the owner's sun. Everything stands at its real place in City 18's coordinates, so what is walked here is what goes
into the real map (the owner, 22 November: "I will need a test map once you are done with this so that I can walk it
and check on all of it (so an env_sun and spawn point please); please keep the scale correct for us to plug directly
into the c18 points").

    python3 map_ring_walk.py                         # writes lc_ring_walk.vmf
    python3 map_ring_walk.py --against c18_lc.vmf    # ...and first checks both halves and the first canal against the owner's map
    python3 map_ring_walk.py --forest THEIRS.vmf --ring-half KEPT.vmf    # the owner's own bunker forest in place of the generator's;
                                                     # the ring's half kept once passed, so the next run takes minutes

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
    ap.add_argument("--forest", help="the owner's own bunker forest (their lc_forest_bunker.vmf, edited in Hammer, at its first place): "
                                     "joined in place of the generator's build, moved 3520 east as that is; never changed, never put in the repo")
    ap.add_argument("--ring-half", help="a file to keep the ring's half in once it has had the nodraw pass (about 25 minutes of the run). If it is "
                                        "there it is used as it is: delete it after any change to the canal, the ring or the inlet")
    args = ap.parse_args()
    py = sys.executable
    kept = args.ring_half and not args.quick and os.path.exists(args.ring_half)
    plain = [("canal", []), ("chain", ["--layout", "map_layouts/ring.txt", "--first-node", "5000"]),
             ("chain", ["--layout", "map_layouts/inlet.txt", "--first-node", "9000"]),      # (the crypt's inlet off the east side, 26 November)
             # (the bunker forest, down Valve's long tunnel from the first canal's east gate: the owner, 26 November, "please
             #  stitch in the forest bunker to the ring now ... down a longer tunnel". The forest is the generator's own build,
             #  3520 east of where it was first set: the owner's file of it, edited in Hammer, is not in this test map)
             ("chain", ["--layout", "map_layouts/bunker_way.txt", "--first-node", "9500"]),
             ("forest_bunker", [])]      # (built at its first place, then moved: map_shift.py, below)
    names = ["lc_canal_test.vmf", "lc_ring_test.vmf", "lc_inlet_test.vmf", "lc_bunker_way_test.vmf", "lc_forest_bunker_test.vmf"]
    todo = list(zip(plain, names))
    if args.forest:      # (the owner, 27 November, of the generator's build in the first walk map with the forest: "crap, I made lots of
        #                   edits ... can you please replace the generator's build with my own?")
        todo = todo[:4]
    if kept:
        todo = todo[3:]
    if args.against:
        print("checking against: " + " ".join(args.against))
        for (piece, extra), _ in todo:
            run([py, "map_build.py", piece] + extra + ["--against"] + args.against + ["--out", os.devnull])
    print("building the test pieces:")
    for (piece, extra), name in todo:
        run([py, "map_build.py", piece] + extra + ["--test", "--out", name])
    if args.forest:
        import shutil
        print("  the owner's own forest: " + args.forest)
        shutil.copyfile(args.forest, os.path.join(HERE, "lc_forest_bunker_test.vmf"))
    # (the forest's builder is written for its first place, its west gate at the canal's east gate, and the owner's own
    #  file stands there too: the finished file is moved to the tunnel's far end, 3520 east)
    run([py, "map_shift.py", "lc_forest_bunker_test.vmf", "lc_forest_bunker_east_test.vmf", "3520", "0"], show=("SHIFT",))
    os.remove(os.path.join(HERE, "lc_forest_bunker_test.vmf"))
    names[-1] = "lc_forest_bunker_east_test.vmf"
    # Joined in two halves, then the halves joined (26 November: with the forest the whole map's grid of 8 unit cubes no
    # longer fits in memory). The ring's half (the canal, the ring, the inlet) gets the nodraw pass by itself, as before;
    # its open gate keeps its cap while it is passed, so the pass sees it shut, as the other half will shut it, and the
    # two caps go when the halves are joined. The forest's half (the tunnel, the forest) goes in as it was built: the
    # pass cannot see the silo's rocket or the rocks sunk in the forest's ground (the same with the forest by itself at
    # its first place: 17 LOST) and rightly refuses to write; forcing it could hide faces players see in the silo.
    halves = [("lc_walk_east_test.vmf", names[3:], ["--spawn", "8064", "4416", "416", "0"], False), ("lc_walk_ring_test.vmf", names[:3], [], True)]
    print("joining them, a half at a time:")
    for half, group, spawn, passed in halves:
        if passed and kept:
            import shutil
            print("  the ring's half as it was kept: " + args.ring_half)
            shutil.copyfile(args.ring_half, os.path.join(HERE, half))
            continue
        run([py, "map_merge.py", "--blank"] + group + spawn + ["--out", half])
        if passed and not args.quick:
            run([py, "map_hidden_faces.py", half, half, "--cell", str(args.cell)], show=("can never be seen", "LOST", "LEAK", "written", "not written"))
            if args.ring_half:
                import shutil
                shutil.copyfile(os.path.join(HERE, half), args.ring_half)
    run([py, "map_merge.py", "--blank"] + [h[0] for h in halves] + ["--out", args.out])
    for name in names + [h[0] for h in halves]:
        if os.path.exists(os.path.join(HERE, name)):
            os.remove(os.path.join(HERE, name))
    import map_budget
    print("  joined: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("finishing it:")
    run([py, "map_slim.py", args.out], show=("MB",))
    print("  finished: " + map_budget.line(map_budget.count(os.path.join(HERE, args.out))))
    print("checking the finished file:")
    # (the walk starts at the spawn and also at three places in the bunker forest: inside the bunker before its door's
    #  button, in the silo's secret room and in the leader's way out. The forest's ground is displaced, which the walk
    #  cannot read; the bunker's door opens only from the inside and the other two lie behind secret doors. The forest's
    #  own build walks its inside; what this walk proves there is the way from the canal down the tunnel to its gate)
    run([py, "map_walk.py", args.out, "--also", "14768", "4260", "410", "--also", "12688", "7024", "-142", "--also", "11748", "4770", "410"], show=("problems", "  "))
    run([py, "map_stairs.py", args.out], show=("flights", "  "))
    # (and every entity's point, as vbsp's leak test sees it once Hammer has saved the file: the owner's compile of 27
    #  November leaked at a test trigger whose middle was in the void over the buried inlet's roof)
    run([py, "map_leak_points.py", args.out], show=("OUTSIDE", "entities in air"))
    fin = map_budget.count(os.path.join(HERE, args.out))
    for key in ("faces", "verts"):
        if map_budget.over(fin, key):
            print("  OVER vbsp's limit on %s: it will not compile" % key)
    print("written: %s (compile it alone: a spawn on the first canal's quay, the owner's sun)" % args.out)


if __name__ == "__main__":
    main()
