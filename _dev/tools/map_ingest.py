#!/usr/bin/env python3
"""
Living City: ingest one of Valve's maps (or any VMF) so the map tools learn how Valve builds.

    python3 map_ingest.py all NAME MAP.vmf          every measuring part, the pictures, measure.json and a draft pictures.json
    python3 map_ingest.py all NAME MAP.vmf --no-pictures      the same without drawing (about a minute less)
    python3 map_ingest.py census|sections|props|logic|craft MAP.vmf     one part, printed as JSON
    python3 map_ingest.py views MAP.vmf --out DIR    candidate pictures scored, the best drawn at 800x520, one contact sheet
    python3 map_ingest.py draw MAP.vmf --eye X Y Z --yaw A --out F.png    one picture again, as views draws them
    python3 map_ingest.py draw MAP.vmf --iso SW [--box X1 Y1 X2 Y2] [--cut Z] --out F.png
    python3 map_ingest.py aggregate                  every _dev/reference/valve_*/measure.json into _dev/reference/valve_stats.json
    python3 map_ingest.py merge-lessons FILE         proposed lessons into lessons.json (as map_lessons.py --merge FILE)

"all" writes _dev/reference/valve_NAME/measure.json (compact numbers of every part, for statistics across maps),
the pictures (into that folder, or its draft/ when the set there was already reviewed; --out DIR to choose) and
a draft pictures.json (pictures.draft.json when a pictures.json is there already) whose numbers are sentences
made from the measurements and whose pictures say where they are, with "teaches" left as TODO.

Left for the reviewer: look at sheet.png (one small picture of all of them), open only the pictures worth it,
write what each teaches and its lessons into the draft, drop the dull ones, remove "draft": true (a draft set is
left out of docs/dev/city18-reference.md), put new or extended lessons in a file and merge them with
merge-lessons. Maps are read as text only. Needs numpy and Pillow. The parts live in _dev/tools/ingest/.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
REF = os.path.normpath(os.path.join(HERE, "..", "reference"))
PARTS = ("census", "sections", "props", "logic", "craft")


def dump(obj, depth=2):
    """JSON with the first levels one key a line (so grep finds a measurement), compact below."""
    def go(o, d, ind):
        if isinstance(o, dict) and d < depth and o:
            pad = " " * (ind + 1)
            return "{\n" + ",\n".join(pad + json.dumps(str(k)) + ": " + go(v, d + 1, ind + 1) for k, v in o.items()) + "\n" + " " * ind + "}"
        return json.dumps(o, separators=(",", ":"), ensure_ascii=False)
    return go(obj, 0, 0) + "\n"


def measure(m, s, parts, log):
    from ingest import census, sections, props, logic, craft
    fn = {"census": lambda: census.run(m, s), "sections": lambda: sections.run(m, s), "props": lambda: props.run(m, s),
          "logic": lambda: logic.run(m), "craft": lambda: craft.run(m, s)}
    out, secs = {}, {}
    for p in parts:
        t = time.time()
        out[p] = fn[p]()
        secs[p] = round(time.time() - t, 1)
        log("  %-9s %5.1fs" % (p, secs[p]))
    return out, secs


def set_folder(name):
    return os.path.join(REF, "valve_" + name)


def reviewed(folder):
    f = os.path.join(folder, "pictures.json")
    if not os.path.exists(f):
        return False
    try:
        return not json.load(open(f)).get("draft")
    except ValueError:
        return True


def cmd_all(a, log):
    from ingest import vmf, geom, views, report
    t0 = time.time()
    m = vmf.load(a.vmf)
    s = geom.Solid(m)
    log("read %s: %d brushes, %d entities, %d displacements; skybox room: %s (%.1fs)" % (
        os.path.basename(a.vmf), len(m.b_owner), len(m.ents), len(m.disps), m.sky_how, time.time() - t0))
    meas, secs = measure(m, s, PARTS, log)
    folder = set_folder(a.name)
    os.makedirs(folder, exist_ok=True)
    pics = []
    if not a.no_pictures:
        out = a.out or (os.path.join(folder, "draft") if reviewed(folder) else folder)
        t = time.time()
        pics = views.run(m, s, out, a.eyes, sections=meas["sections"], log=log)
        secs["views"] = round(time.time() - t, 1)
        rel = os.path.relpath(out, folder)
        for p in pics:
            p["file"] = p["file"] if rel == "." else os.path.join(rel, p["file"])
    secs["total"] = round(time.time() - t0, 1)
    M = {"name": a.name, "vmf": os.path.basename(a.vmf), "made": time.strftime("%Y-%m-%d"), "tool": "map_ingest.py", "format": 1, "seconds": secs}
    M.update(meas)
    text = dump(M)
    if chr(0x2014) in text:
        raise SystemExit("an em dash in the measurements: take it out")
    with open(os.path.join(folder, "measure.json"), "w") as f:
        f.write(text)
    d = report.draft(a.name, M, pics, os.path.relpath(folder, REF))
    target = "pictures.draft.json" if reviewed(folder) else "pictures.json"
    with open(os.path.join(folder, target), "w") as f:
        f.write(json.dumps(d, indent=1, ensure_ascii=False) + "\n")
    log("written: %s (%d KB), %s (%d sentences, %d pictures); %.0fs in all" % (
        os.path.relpath(os.path.join(folder, "measure.json")), len(text) // 1024, os.path.relpath(os.path.join(folder, target)), len(d["numbers"]), len(pics), secs["total"]))
    if len(text) > 60 * 1024:
        log("note: measure.json is over 60 KB")


def main():
    ap = argparse.ArgumentParser(description="Ingest a Valve VMF: measure it, picture it, and gather statistics across maps.")
    ap.add_argument("command", choices=("all",) + PARTS + ("views", "draw", "aggregate", "merge-lessons"))
    ap.add_argument("args", nargs="*", help="all: NAME MAP.vmf; a part or views: MAP.vmf; merge-lessons: FILE")
    ap.add_argument("--out", help="views / all: where the pictures go")
    ap.add_argument("--eyes", type=int, default=6, help="how many eye-level views to draw (default 6)")
    ap.add_argument("--no-pictures", action="store_true", help="all: measure only")
    ap.add_argument("--eye", type=float, nargs=3, metavar=("X", "Y", "Z"), help="draw: look from here")
    ap.add_argument("--yaw", type=float, default=0.0, help="draw: the way to look (0 east, 90 north)")
    ap.add_argument("--pitch", type=float, default=3.0, help="draw: degrees down")
    ap.add_argument("--iso", choices=["NE", "NW", "SE", "SW"], help="draw: from above, from this corner")
    ap.add_argument("--box", type=float, nargs=4, metavar=("X1", "Y1", "X2", "Y2"), help="draw: only what is inside")
    ap.add_argument("--cut", type=float, help="draw: nothing above this height")
    a = ap.parse_args()
    log = lambda s: print(s, flush=True)
    if a.command == "aggregate":
        from ingest import aggregate
        for line in aggregate.run(REF):
            print(line)
        print("written: %s" % os.path.relpath(os.path.join(REF, "valve_stats.json")))
        return
    if a.command == "merge-lessons":
        if len(a.args) != 1:
            raise SystemExit("usage: map_ingest.py merge-lessons FILE")
        import map_lessons
        map_lessons.merge(a.args[0])
        return
    if a.command == "all":
        if len(a.args) != 2:
            raise SystemExit("usage: map_ingest.py all NAME MAP.vmf")
        a.name, a.vmf = a.args
        return cmd_all(a, log)
    if len(a.args) != 1:
        raise SystemExit("usage: map_ingest.py %s MAP.vmf" % a.command)
    from ingest import vmf, geom
    m = vmf.load(a.args[0])
    s = geom.Solid(m)
    if a.command == "draw":
        from ingest import views
        if not a.out or not (a.eye or a.iso):
            raise SystemExit("usage: map_ingest.py draw MAP.vmf (--eye X Y Z --yaw A | --iso SW) --out F.png")
        polys, lights = views.scene(m)
        kw = dict(eye=tuple(a.eye), yaw=a.yaw, pitch=a.pitch) if a.eye else dict(iso=a.iso, box=tuple(a.box) if a.box else None, cut=a.cut)
        views.Painter(m, polys, lights).draw(a.out, (800, 520), title="", reach=5000 if a.eye else None, **kw)
        print("written: " + a.out)
        return
    if a.command == "views":
        from ingest import views
        out = a.out or os.path.join(os.getcwd(), m.name + "_views")
        for p in views.run(m, s, out, a.eyes, log=log):
            print("%s  %s" % (p["file"], p["where"]))
        print("written: %s (sheet.png is the contact sheet)" % out)
        return
    res, secs = measure(m, s, [a.command], lambda x: print(x, file=sys.stderr))
    print(dump(res[a.command], 1))


if __name__ == "__main__":
    main()
