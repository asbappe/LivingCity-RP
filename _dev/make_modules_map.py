#!/usr/bin/env python3
"""Write docs/dev/modules.md: a map from each module to its files, key functions and tests.

    python3 _dev/make_modules_map.py

One row per module name (sv_livingcity_X, cl_livingcity_X and sh_livingcity_X are the same
module X). For each: the title from the file's header comment, the server / client / shared
files with their sizes, the public functions other code uses most (so they are the ones worth
grepping for), and the test units in _dev/tests.lua that call the module's own functions
the most. Everything comes from the code, so rerun it after adding a module or a test unit
and commit the result; never hand-edit docs/dev/modules.md.
"""
import collections, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import run_section as rs

MODS = os.path.join(ROOT, "gamemodes", "livingcity", "gamemode", "modules")
OUT = os.path.join(ROOT, "docs", "dev", "modules.md")
SIDES = (("server", "sv_livingcity"), ("client", "cl_livingcity"), ("shared", "sh_livingcity"))
DEF = re.compile(r"^(?:local\s+)?function\s+([A-Za-z_]\w*)[.:]([A-Za-z_]\w*)\s*\(|^([A-Z][A-Za-z_]*)\.([A-Za-z_]\w*)\s*=\s*function")
MAX_KEY, MAX_TESTS = 6, 3


def title(src):
    m = re.match(r"\s*--\[(=*)\[(.*?)\]\1\]", src, re.S)
    for line in (m.group(2).split("\n") if m else src.split("\n")[:3]):
        line = line.strip().lstrip("-").strip()
        if line:
            line = re.sub(r"^Living City( \(\w+\))?:?\s*", "", line)
            return (line[:1].upper() + line[1:])[:100].replace("|", "/")
    return ""


def load_files():
    """module -> side -> (path, text); sv_livingcity_X, cl_livingcity_X, sh_livingcity_X are module X"""
    files = {}
    for side, prefix in SIDES:
        d = os.path.join(MODS, side)
        for f in sorted(os.listdir(d)):
            if f.endswith(".lua"):
                mod = f[:-4][len(prefix):].lstrip("_") or "core"
                files.setdefault(mod, {})[side] = (os.path.join(d, f), open(os.path.join(d, f)).read())
    return files


def public_functions(files):
    """-> (module -> [(namespace, name)], name -> set of modules that define it)"""
    pub, owners = {}, collections.defaultdict(set)
    for mod, sides in files.items():
        names = []
        for side, (path, text) in sides.items():
            for line in text.split("\n"):
                m = DEF.match(line)
                if m:
                    ns, fn = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
                    names.append((ns, fn))
                    owners[fn].add(mod)
        pub[mod] = list(dict.fromkeys(names))
    return pub, owners


def test_regions(t):
    """-> [(label, set of identifiers)]: each test unit's own lines, and each top-level section"""
    regions = []
    for u in t.units:
        if u["name"].startswith("anon@"):
            label = u["name"]                      # run it with --unit anon@LINE
        else:
            label = u["name"]
        regions.append((label, "\n".join(t.clean[k - 1] for k in t.own_lines(u))))
    for s in (x for x in t.sections if not x["unit"]):
        nxt = [x["line"] for x in t.sections if x["line"] > s["line"] and not x["unit"]]
        nxt += [u["start"] for u in t.units if u["start"] > s["line"]]
        end = (min(nxt) - 1) if nxt else t.n
        regions.append(('section "%s"' % s["name"][:50], "\n".join(t.clean[s["line"] - 1:end])))
    return [(label, set(re.findall(r"[A-Za-z_]\w*", text))) for label, text in regions]


def main():
    files = load_files()
    t = rs.Tests()
    pub, owners = public_functions(files)
    regions = test_regions(t)

    # how often each name is used anywhere (code and tests): the "key" functions are used most
    corpus = [text for sides in files.values() for _, text in sides.values()] + t.clean
    for extra in ("gamemodes/livingcity/gamemode/cl_init.lua", "gamemodes/livingcity/gamemode/init.lua",
                  "lua/weapons/gmod_tool/stools/livingcity_editor.lua"):
        corpus.append(open(os.path.join(ROOT, extra)).read())
    words = collections.Counter(re.findall(r"[A-Za-z_]\w*", "\n".join(corpus)))

    rows = []
    for mod in sorted(files):
        sides = files[mod]
        first = sides.get("server") or sides.get("shared") or sides.get("client")
        names = pub[mod]
        specific = [fn for _, fn in names if owners[fn] == {mod} and len(fn) > 3]
        top = sorted(dict.fromkeys(specific), key=lambda fn: -words[fn])[:MAX_KEY]
        key = ["%s.%s" % (next(ns for ns, f2 in names if f2 == fn), fn) for fn in top]
        spec = set(specific)
        hits = sorted(((len(spec & ws), label) for label, ws in regions if spec & ws),
                      key=lambda h: (-h[0], mod not in h[1].lower(), h[1]))
        need = 2 if len(spec) >= 4 else 1
        tests = ["%s (%d)" % (label, n) for n, label in hits[:MAX_TESTS] if n >= need]

        def cell(side):
            if side not in sides:
                return "-"
            return "`%s` %dK" % (os.path.relpath(sides[side][0], MODS), round(len(sides[side][1]) / 1024))

        rows.append("| `%s` | %s | %s | %s | %s | %s | %s |" % (
            mod, title(first[1]) or "-", cell("server"), cell("client"), cell("shared"),
            ", ".join("`%s`" % k for k in key) or "-", "; ".join(tests) or "-"))

    out = ["# Code map: module to files, key functions and tests", "",
           "Generated by `python3 _dev/make_modules_map.py`. Never hand-edit; rerun it after adding a module or a test unit.",
           "Paths are under `gamemodes/livingcity/gamemode/modules/`. To find code: `grep -n 'function LC.Name' PATH | cut -c1-160`,",
           "then read a line range. Never open a file over about 20K whole.", "",
           "**Key functions** are this module's own public functions that the rest of the code and the tests use most.",
           "**Tests** are the test units (or top-level sections) in `_dev/tests.lua` that call the most of this module's own",
           "functions, with the number of distinct functions hit. Run one with `python3 _dev/run_section.py --unit NAME`",
           "or `python3 _dev/run_section.py \"section name\"`; `anon@N` is a nameless test block starting at line N of tests.lua",
           "(`--unit anon@N`); `python3 _dev/run_section.py --list TEXT` finds them by text.",
           "A `-` under Tests means no test calls enough of this module's own functions (client code is covered by",
           "`_dev/client_smoke.py`).", "",
           "%d modules. Elsewhere: entities and weapons in `gamemodes/livingcity/entities/`, the editor tool in "
           "`lua/weapons/gmod_tool/stools/livingcity_editor.lua`, the player guide in `gamemode/cl_init.lua`." % len(rows), "",
           "| Module | What it is | Server | Client | Shared | Key functions | Tests |",
           "|---|---|---|---|---|---|---|"] + rows
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write("\n".join(out) + "\n")
    print("wrote %s: %d modules, %d bytes" % (os.path.relpath(OUT, ROOT), len(rows), os.path.getsize(OUT)))


if __name__ == "__main__":
    main()

