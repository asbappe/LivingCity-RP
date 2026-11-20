#!/usr/bin/env python3
"""
Living City: build every canal module every way and say what fails (run it after changing map_modules.py or a map_mods_*.py)

    python3 map_modules_check.py                     every module, heading E, N, W and S, flipped and not; then every layout
    python3 map_modules_check.py --only cistern,vort   just these
    python3 map_modules_check.py --only cistern --views /tmp/pics    ...and pictures of each (map_view.py)

It writes nothing but pictures: the VMFs go to a temporary folder.
"""

import argparse
import glob
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def run(cmd, cwd):
    r = subprocess.run([sys.executable, os.path.join(HERE, "map_build.py")] + cmd, cwd=cwd, capture_output=True, text=True)
    out = r.stdout + r.stderr
    ok = r.returncode == 0 and "checked:" in out and "PROBLEM" not in out and "Traceback" not in out
    return ok, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="module names, with commas between")
    ap.add_argument("--views", default=None, help="a folder for pictures of each module (heading east)")
    ap.add_argument("--quick", action="store_true", help="heading east only, flipped and not")
    args = ap.parse_args()
    sys.path.insert(0, HERE)
    import map_modules
    names = [n for n in args.only.split(",") if n] or sorted(map_modules.MODULES)
    bad = 0
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            fails = []
            for heading in ("E",) if args.quick else ("E", "N", "W", "S"):
                for flip in ([], ["--flip"]):
                    ok, out = run(["module", "--name", name, "--heading", heading, "--origin", "640", "-1280"] + flip, tmp)
                    if not ok:
                        fails.append((heading, bool(flip), out))
            ok, out = run(["module", "--name", name, "--test"] + (["--views", os.path.abspath(args.views)] if args.views else []), tmp)
            if not ok:
                fails.append(("E", "test", out))
            looks = [l.strip() for l in out.splitlines() if "LOOK:" in l]
            print("%-12s %s%s" % (name, "ok" if not fails else "FAILS %d ways" % len(fails), "   (%d props to look at)" % len(looks) if looks else ""))
            for l in looks[:4]:
                print("    " + l[:200])
            for heading, flip, out in fails[:1]:
                lines = [l for l in out.splitlines() if "PROBLEM" in l or "Error" in l or "Traceback" in l or l.startswith("  File")]
                print("    heading %s%s: %s" % (heading, " flipped" if flip is True else " test" if flip else "", "\n      ".join(lines[-6:]) or out[-400:]))
            bad += bool(fails)
        if not args.only:
            for lay in sorted(glob.glob(os.path.join(HERE, "map_layouts", "*.txt"))):
                ok, out = run(["chain", "--layout", lay], tmp)
                print("%-12s %s" % ("layout " + os.path.basename(lay), "ok" if ok else "FAILS"))
                if not ok:
                    print("    " + "\n    ".join([l for l in out.splitlines() if "PROBLEM" in l or "Error" in l][-6:]))
                    bad += 1
    print("MODULES CHECK %s" % ("PASS" if not bad else "FAIL (%d)" % bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
