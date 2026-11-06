#!/usr/bin/env python3
"""Write docs/dev/modules.md: a map from each module to its files, key functions and tests.

    python3 _dev/make_modules_map.py                  regenerate the map
    python3 _dev/make_modules_map.py --module NAME    one module: its row, plus a line-range outline of
                                                      each of its files over 20K (NAME may be part of a name)
    python3 _dev/make_modules_map.py --outline PATH   line-range outline of any Lua file
                                                      (add --grep TEXT to keep only matching entries)

One row per module name (sv_livingcity_X, cl_livingcity_X and sh_livingcity_X are the same
module X). For each: the title from the file's header comment, the server / client / shared
files with their sizes, the public functions other code uses most (so they are the ones worth
grepping for), and the test units in _dev/tests.lua that call the module's own functions
the most. Everything comes from the code, so rerun it after adding a module or a test unit
and commit the result; never hand-edit docs/dev/modules.md.
"""
import argparse, collections, os, re, sys

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


BIG = 20 * 1024
RULE = re.compile(r"^-{20,}\s*$")
TOPDEF = re.compile(r"^(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(|^([A-Za-z_][\w.]*)\s*=\s*function\s*\(")
TOPHOOK = re.compile(r"^(hook\.Add|net\.Receive|concommand\.Add)\(\s*\"([^\"]+)\"(?:\s*,\s*\"([^\"]+)\")?")
ONELINE = re.compile(r"\bend\)*[;,]?\s*(--.*)?$")


def outline(text):
    """-> [(start, end, label)] for a Lua file: section banners (end None), top-level functions,
    hooks, net receivers and console commands. A top-level block ends at the next line that starts
    with 'end' in column 0; a definition whose first line already ends in 'end' is one line."""
    lines = text.split("\n")
    out, open_def, in_banner = [], None, False
    for i, line in enumerate(lines, 1):
        if open_def is not None:
            if line.startswith("end"):
                out.append((open_def[0], i, open_def[1]))
                open_def = None
            continue
        if RULE.match(line):
            in_banner = not in_banner
            continue
        if in_banner:
            if line.startswith("--") and not any(o[2] is None and o[0] == i - 1 for o in out):
                prev = out[-1] if out else None
                if not (prev and prev[1] is None and prev[0] >= i - 3):
                    out.append((i, None, line.lstrip("-").strip()[:70]))
            continue
        m = TOPDEF.match(line)
        if m:
            label = ("local " if line.startswith("local") else "") + (m.group(1) or m.group(2))
        else:
            h = TOPHOOK.match(line)
            if not h:
                continue
            label = "%s %s" % (h.group(1), " / ".join(g for g in h.group(2, 3) if g))
            if "function" not in line:
                continue
        if ONELINE.search(line):
            out.append((i, i, label))
        else:
            open_def = (i, label)
    return out


def print_outline(path, grep=None):
    text = open(path).read()
    rel = os.path.relpath(path, ROOT)
    rows = outline(text)
    if grep:
        g = grep.lower()
        rows = [r for r in rows if g in r[2].lower()]
    print("## %s (%dK, %d lines)" % (rel, round(len(text) / 1024), text.count("\n") + 1))
    for a, b, label in rows:
        if b is None:
            print("%d  # %s" % (a, label))
        else:
            print("%s %s" % ("%d" % a if a == b else "%d-%d" % (a, b), label))


def lookup(name, grep=None, everything=False):
    """print the map rows that match NAME and an outline of each of their big files"""
    rows = [l for l in open(OUT) if l.startswith("| `")]
    key = name.lower().strip("`")
    hit = [l for l in rows if l.split("`")[1] == key] or [l for l in rows if key in l.split("`")[1]]
    if not hit:
        sys.exit("no module matches %r (try: grep -n TEXT docs/dev/modules.md | cut -c1-300)" % name)
    if len(hit) > 8:
        sys.exit("%d modules match %r: %s" % (len(hit), name, ", ".join(l.split("`")[1] for l in hit)))
    for l in hit:
        cells = [c.strip() for c in l.strip().strip("|").split(" | ")]
        print("module %s: %s" % (cells[0].strip("`"), cells[1]))
        for label, c in zip(("server", "client", "shared"), cells[2:5]):
            if c != "-":
                print("  %s: %s" % (label, c))
        print("  key functions: %s" % cells[5])
        print("  tests: %s" % cells[6])
        for c in cells[2:5]:
            if c == "-":
                continue
            path = os.path.join(MODS, c.split("`")[1])
            if everything or os.path.getsize(path) > BIG:
                print()
                print_outline(path, grep)
        print()


def main():
    ap = argparse.ArgumentParser(description="module code map")
    ap.add_argument("--module", metavar="NAME", help="print one module's row and an outline of its big files")
    ap.add_argument("--outline", metavar="PATH", help="print the line-range outline of one Lua file")
    ap.add_argument("--grep", metavar="TEXT", help="with --module/--outline: keep only entries containing TEXT")
    ap.add_argument("--all", action="store_true", help="with --module: outline small files too")
    a = ap.parse_args()
    if a.outline:
        return print_outline(os.path.abspath(a.outline), a.grep)
    if a.module:
        return lookup(a.module, a.grep, a.all)
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
           "**Do not read this file whole (30K).** One module: `python3 _dev/make_modules_map.py --module NAME` prints its row and, for each",
           "file over 20K, an outline of `start-end name` for every top-level function, hook and section (add `--grep TEXT` to",
           "narrow it; `--outline PATH` does any Lua file). Read just that line range with `sed -n 'A,Bp' PATH`.",
           "To find a feature by word: `grep -n TEXT docs/dev/modules.md | cut -c1-300`. Paths are under",
           "`gamemodes/livingcity/gamemode/modules/`. Never open a file over about 20K whole.", "",
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

