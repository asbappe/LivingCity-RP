#!/usr/bin/env python3
"""
Living City: a picture catalogue of every canal module (for the owner to choose from)

    python3 map_catalogue.py OUT_FOLDER                 pictures of every module, and catalogue.json describing them
    python3 map_catalogue.py OUT_FOLDER --only cistern,vort
    python3 map_catalogue.py --list ../../docs/dev/canal-modules.md      no pictures: rewrite the list of modules in the docs

For each module: a view from above with the roofs off, and up to three of the views the module asks for
(map_view.py draws them: rough shapes and light, not the game's look). catalogue.json holds each module's
length, its one-line summary, its docstring, what it names for the game, and its pictures' file names.
"""

import argparse
import inspect
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import map_modules as mm
import map_view

STRUCTURE = ("straight", "jog", "tee", "tunnel", "shed")


def one(name, folder, tmp, size):
    class A:
        first_node, test, origin, heading, rim, preview, views = 6000, False, None, None, None, None, None
    import map_corridor
    street = map_corridor.STREET_MODULES.get(name)
    lay = {"name": "cat_" + name, "start": (0, 0), "heading": "E", "rim": 784, "end": None, "modules": [[name]]}
    if street:      # (a module that belongs on the street is drawn up there)
        lay.update({"upper": "left", "cars": 2, "modules": [["straight", "256"], [name] + street.split(), ["straight", "256"]]})
    b, seed, spawn, end = mm.build_chain(lay, A)
    ch, fences, problems, names = mm.finish(b, seed, spawn, A)
    path = os.path.join(tmp, name + ".vmf")
    with open(path, "w") as f:
        f.write(b.vmf.text())
    pics = []

    def shot(tag, **kw):
        png = os.path.join(tmp, "%s_%s.png" % (name, tag))
        map_view.render(path, png, size=size, **kw)
        from PIL import Image
        jpg = "%s_%s.jpg" % (name, tag)
        Image.open(png).convert("RGB").save(os.path.join(folder, jpg), quality=82)
        pics.append(jpg)
    shot("above", iso="NE", cut=(map_corridor.STREET if street else mm.F) + 150)
    views = [v for v in b.views if "coming in" not in v[0]] or b.views
    for k, (label, eye, yaw, pitch) in enumerate(views[:3]):
        shot("view%d" % (k + 1), eye=eye, yaw=yaw, pitch=pitch)
    doc = inspect.getdoc(mm.MODULES[name][1]) or ""
    return {"name": name, "length": mm.MODULES[name][0], "summary": mm.MODULES[name][2], "doc": doc, "problems": problems,
            "file": os.path.basename(inspect.getsourcefile(mm.MODULES[name][1])), "street": street or "",
            "named": sorted(set(n[0] for n in names)), "pictures": pics, "labels": ["from above, roofs off"] + [v[0].split(" ", 2)[-1] for v in views[:3]],
            "notes": [n for n in b.notes if n.startswith("LOOK")]}


GROUPS = {"map_modules.py": "The first ten", "map_mods_a.py": "Ruins and the city's edge", "map_mods_b.py": "Resistance life",
          "map_mods_c.py": "The Combine and its machines", "map_mods_d.py": "More"}


def page(mods, path, embed=False):
    """One page to browse them all: a fragment of HTML with the pictures beside it, or (embed) inside it as one file
    (what the owner's catalogue is published from)."""
    import base64
    import html
    import re
    folder = os.path.dirname(path)

    def src(p):
        if not embed:
            return p
        with open(os.path.join(folder, p), "rb") as f:
            return "data:image/jpeg;base64," + base64.b64encode(f.read()).decode()
    cards = []
    for m in mods:
        group = "Canal structure" if m["name"] in STRUCTURE else GROUPS.get(m.get("file"), "More")
        doc = m["doc"]
        unchecked = ""
        k = doc.find("Unchecked:")
        if k >= 0:
            doc, unchecked = doc[:k], doc[k + len("Unchecked:"):].strip()
        k = doc.find("Named for the game")
        if k >= 0:
            doc = doc[:k]
        doc = re.sub(r"^\d+\.\s*", "", " ".join(doc.split()))
        pics = "".join('<button class="shot" type="button" data-cap="%s"><img src="%s" alt="%s: %s" loading="lazy" width="720" height="450"><span>%s</span></button>' % (
            html.escape("%s: %s" % (m["name"], l), True), src(p), html.escape(m["name"], True), html.escape(l, True), html.escape(l)) for p, l in zip(m["pictures"], m["labels"]))
        named = "".join("<li>%s</li>" % html.escape(n) for n in m["named"]) or ""
        where = '<span class="up">on the street: %s %s</span>' % (html.escape(m["name"]), html.escape(m["street"])) if m.get("street") else "<span>in the canal</span>"
        cards.append('<article class="mod" data-group="%s" data-text="%s"><header><h2>%s</h2><p class="meta"><span>%d long</span><span>%s</span>%s</p></header>'
                     '<p class="sum">%s</p><div class="shots">%s</div>%s%s</article>' % (
                         html.escape(group, True), html.escape((m["name"] + " " + m["summary"] + " " + doc + " " + " ".join(m["named"])).lower(), True), html.escape(m["name"]),
                         m["length"], html.escape(group), where, html.escape(doc), pics,
                         '<div class="named"><h3>Named for the game</h3><ul>%s</ul></div>' % named if named else "",
                         '<p class="unchecked"><b>Not yet checkable:</b> %s</p>' % html.escape(unchecked) if unchecked else ""))
    groups = []
    for m in mods:
        g = "Canal structure" if m["name"] in STRUCTURE else GROUPS.get(m.get("file"), "More")
        if g not in groups:
            groups.append(g)
    chips = '<button type="button" class="chip on" data-g="">All %d</button>' % len(mods) + "".join('<button type="button" class="chip" data-g="%s">%s</button>' % (html.escape(g, True), html.escape(g)) for g in groups)
    with open(os.path.join(HERE, "map_catalogue_page.html")) as f:
        tpl = f.read()
    with open(path, "w") as f:
        f.write(tpl.replace("<!--CHIPS-->", chips).replace("<!--CARDS-->", "\n".join(cards)).replace("<!--COUNT-->", str(len(mods))))
    print("written: %s" % path)


def listing(path):
    """The list of every module as a page of the docs: made from the modules themselves, so it is never out of date."""
    class A:
        first_node, test = 6000, False
    rows, texts = [], []
    for name in [n for n in mm.MODULES if n not in STRUCTURE] + [n for n in STRUCTURE if n in mm.MODULES]:
        info = mm.MODULES[name]
        lay = {"name": "list", "start": (0, 0), "heading": "E", "rim": 784, "end": None, "modules": [[name]]}
        try:
            b, seed, spawn, end = mm.build_chain(lay, A)
            named = sorted(set(n[0] for n in b.names if n[0] != "clash"))
        except Exception as e:
            named = ["(does not build: %s)" % e]
        src = os.path.basename(inspect.getsourcefile(info[1]))
        rows.append("| `%s` | %d | %s | %s | `%s` |" % (name, info[0], info[2].replace("|", "/"), ", ".join("`%s`" % n for n in named) or "none", src))
        texts.append("### `%s`\n\n%s\n" % (name, inspect.getdoc(info[1]) or ""))
    with open(path, "w") as f:
        f.write("# The canal modules (made by `_dev/tools/map_catalogue.py --list`: never edit by hand)\n\n")
        f.write("What a module is and how to lay them out: `docs/dev/map-building.md` (\"Canal modules\"). How to write one: `docs/dev/map-modules.md`. "
                "Everything under \"named for the game\" is there for the gamemode to give a use: nothing uses them yet unless a feature's own doc says so.\n\n")
        f.write("| Module | Long | What it is | Named for the game | File |\n|---|---|---|---|---|\n" + "\n".join(rows) + "\n\n")
        f.write("## Each module, in its own words\n\n" + "\n".join(texts))
    print("written: %s (%d modules)" % (path, len(rows)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", nargs="?")
    ap.add_argument("--list", default=None, help="write the list of modules as a page of the docs, and nothing else")
    ap.add_argument("--only", default="")
    ap.add_argument("--size", type=int, nargs=2, default=(720, 450))
    args = ap.parse_args()
    if args.list:
        listing(args.list)
        return
    os.makedirs(args.out, exist_ok=True)
    names = [n for n in args.only.split(",") if n] or [n for n in mm.MODULES if n not in STRUCTURE] + [n for n in STRUCTURE if n in mm.MODULES]
    out = []
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            try:
                out.append(one(name, args.out, tmp, tuple(args.size)))
                print("%-12s %d pictures%s" % (name, len(out[-1]["pictures"]), "  PROBLEMS: %d" % len(out[-1]["problems"]) if out[-1]["problems"] else ""))
            except Exception as e:      # (one broken module must not stop the catalogue)
                print("%-12s FAILED: %s: %s" % (name, type(e).__name__, e))
    with open(os.path.join(args.out, "catalogue.json"), "w") as f:
        json.dump(out, f, indent=1)
    page(out, os.path.join(args.out, "index.html"))
    page(out, os.path.join(args.out, "canal_modules.html"), embed=True)
    print("written: %s (%d modules)" % (os.path.join(args.out, "catalogue.json"), len(out)))


if __name__ == "__main__":
    main()
