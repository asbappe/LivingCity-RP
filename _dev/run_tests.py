import glob, json, os, sys
import lupa
from lupa import luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
GMDIR = os.path.join(HERE, "..", "gamemodes", "livingcity")          # the gamemode
MODS = os.path.join(GMDIR, "gamemode", "modules")                    # its modules
ENTS = os.path.join(GMDIR, "entities")                               # its entities and weapons
TOOLS = os.path.join(HERE, "..", "lua", "weapons", "gmod_tool", "stools")
L = lj.LuaRuntime(unpack_returned_tuples=True)


def to_py(v):
    if lj.lua_type(v) == "table":
        keys = list(v.keys())
        if not keys:
            return []
        if all(isinstance(k, (int, float)) and float(k).is_integer() for k in keys) and \
                sorted(int(k) for k in keys) == list(range(1, len(keys) + 1)):
            return [to_py(v[i]) for i in range(1, len(keys) + 1)]
        return {str(k): to_py(v[k]) for k in keys}
    return v


def to_lua(v):
    if isinstance(v, dict):
        t = L.table()
        for k, x in v.items():
            t[k] = to_lua(x)
        return t
    if isinstance(v, list):
        t = L.table()
        for i, x in enumerate(v):
            t[i + 1] = to_lua(x)
        return t
    return v


def table_to_json(t, pretty=False):
    return json.dumps(to_py(t), indent=2 if pretty else None)


def json_to_table(s):
    try:
        return to_lua(json.loads(s))
    except Exception:
        return None


L.execute(open(os.path.join(HERE, "gmod_stub.lua")).read())
util = L.globals().util
util.TableToJSON = table_to_json
util.JSONToTable = json_to_table
util.Decompress = lambda s: s

# Garry's Mod's Lua isn't quite plain LuaJIT: "continue" is a keyword there, so a
# label or variable called continue loads fine here and fails in the game. Catch
# it (and anything else on this list) before the tests run.
import re
GMOD_RESERVED = ["continue"]
def strip_lua(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                i = n if end < 0 else end + len(m.group(1)) + 2
            else:
                end = src.find("\n", i)
                i = n if end < 0 else end
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            end = src.find("]" + m.group(1) + "]", i)
            i = n if end < 0 else end + len(m.group(1)) + 2
            out.append('""')
            continue
        c = src[i]
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            i = j + 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return "".join(out)
problems = []
GMROOT_ALL = os.path.join(HERE, "..")
for path in glob.glob(GMROOT_ALL + "/lua/**/*.lua", recursive=True) + glob.glob(GMROOT_ALL + "/gamemodes/**/*.lua", recursive=True):
    code = strip_lua(open(path).read())
    for word in GMOD_RESERVED:
        for m in re.finditer(r"\b" + word + r"\b", code):
            line = code.count("\n", 0, m.start()) + 1
            problems.append("%s:%d uses '%s', a keyword in Garry's Mod" % (os.path.relpath(path, GMROOT_ALL), line, word))
# "local a, b = f and f()" keeps only the first value: b is always nil. (It hid
# the reasons for a refused inform or microphone, and the on-air name.)
MULTI_AND = re.compile(r"local\s+\w+\s*,\s*[\w,\s]+=\s*[\w.]+\s+and\s+[\w.:]+\(")
for path in glob.glob(GMROOT_ALL + "/lua/**/*.lua", recursive=True) + glob.glob(GMROOT_ALL + "/gamemodes/**/*.lua", recursive=True):
    code = strip_lua(open(path).read())
    for m in MULTI_AND.finditer(code):
        line = code.count("\n", 0, m.start()) + 1
        problems.append("%s:%d takes several values from 'x and f()', which only ever gives one" % (os.path.relpath(path, GMROOT_ALL), line))
# pcall swallows an error and tells nobody: the gamemode uses LC.Try (sh_livingcity_errors.lua), which is
# pcall with the error written down in the server's errors file. (That file itself is the one place for pcall.)
BARE_PCALL = re.compile(r"(?<![\w.:])pcall\b")
for path in glob.glob(GMROOT_ALL + "/gamemodes/**/*.lua", recursive=True):
    if path.endswith("sh_livingcity_errors.lua"):
        continue
    code = strip_lua(open(path).read())
    for m in BARE_PCALL.finditer(code):
        line = code.count("\n", 0, m.start()) + 1
        problems.append("%s:%d uses pcall: use LC.Try, so what it swallows is written down" % (os.path.relpath(path, GMROOT_ALL), line))
# the house rules as numbers that may fall but not rise (house_rules.py): stand-still job steps,
# places that put text on a player's screen, console commands no menu names
import house_rules
if os.path.exists(house_rules.BASE) and not os.environ.get("LC_HOUSE_RULES_DONE"):
    problems += house_rules.check(house_rules.count()[0], json.load(open(house_rules.BASE)))
if problems:
    print("GMOD LUA CHECK FAILED")
    for p in problems: print("  " + p)
    sys.exit(1)

# the modules, in the order the gamemode loads them (its manifest, in shared.lua)
def manifest():
    src = open(os.path.join(GMDIR, "gamemode", "shared.lua")).read()
    out = {}
    for side in ("shared", "server", "client"):
        m = re.search(side + r" = \{(.*?)\}", src, re.S)
        out[side] = re.findall(r'"([^"]+)"', m.group(1)) if m else []
        on_disk = sorted(f[:-4] for f in os.listdir(os.path.join(MODS, side)) if f.endswith(".lua"))
        if sorted(out[side]) != on_disk:
            print("MANIFEST MISMATCH (%s): listed %s, on disk %s" % (side, sorted(set(out[side]) ^ set(on_disk)), side))
            sys.exit(1)
    return out
MANIFEST = manifest()
order = ["shared/" + n + ".lua" for n in MANIFEST["shared"]] + ["server/" + n + ".lua" for n in MANIFEST["server"]]
for rel in order:
    try:
        L.globals()._SRC = open(os.path.join(MODS, rel)).read()
        L.execute("assert(loadstring(_SRC, %r))()" % rel)
    except Exception as e:
        print("LOAD FAILED", rel, e)
        sys.exit(1)

# weapons and the tool only need to load cleanly
for rel in sorted(os.path.relpath(p, ENTS) for p in glob.glob(ENTS + "/entities/*.lua")):
    L.execute("ENT = {}")
    L.globals()._SRC = open(os.path.join(ENTS, rel)).read()
    L.execute("assert(loadstring(_SRC, %r))()" % rel)
    # (kept, so a test can call an entity's own functions: _ENTSRC["entities/lc_incinerator.lua"])
    L.execute("_ENTSRC = _ENTSRC or {} _ENTSRC[%r] = _SRC" % rel)
for rel in sorted(os.path.relpath(p, ENTS) for p in glob.glob(ENTS + "/weapons/*.lua")):
    L.execute("SWEP = {}")
    L.globals()._SRC = open(os.path.join(ENTS, rel)).read()
    L.execute("assert(loadstring(_SRC, %r))()" % rel)
    # (kept, so a test can load a weapon again and press its keys: _WEAPONSRC["weapons/weapon_lc_radio.lua"])
    L.execute("_WEAPONSRC = _WEAPONSRC or {} _WEAPONSRC[%r] = _SRC" % rel)
L.execute("TOOL = { GetClientInfo = function() return 'idle' end }")
L.execute(open(os.path.join(TOOLS, "livingcity_editor.lua")).read())
# the "Save with the gamemode" tool, kept for its test to load (section "Persistent props")
L.globals()._KEEPTOOL = open(os.path.join(TOOLS, "livingcity_keep.lua")).read()

# the gamemode is loaded by the tests themselves, at the point they test it
GMROOT = os.path.join(GMDIR, "gamemode")
L.globals()._GMSRC_SHARED = open(os.path.join(GMROOT, "shared.lua")).read()
L.globals()._GMSRC_INIT = open(os.path.join(GMROOT, "init.lua")).read()

# the robot players (robots.lua), run by the RobotTests unit
L.globals()._ROBOTSRC = open(os.path.join(HERE, "robots.lua")).read()
L.globals()._ROBOTS_ON = bool(os.environ.get("LC_ROBOTS"))

# the core snapshot (CORE.md): what the core looked like when the owner last OK'd it
SNAP = os.path.join(HERE, "core_snapshot.txt")
L.globals()._CORE_SNAPSHOT = open(SNAP).read() if os.path.exists(SNAP) else None

L.execute("math.randomseed(7)")
L.globals()._TESTSRC = open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "tests.lua")).read()
passed, failed, report = L.execute("""
local fn = assert(loadstring(_TESTSRC, "tests.lua"))
local ok, a, b, c = xpcall(fn, debug.traceback)
if not ok then error(a, 0) end
return a, b, c
""")
print(report)
now = L.globals()._CORE_NOW
if now is not None and (not os.path.exists(SNAP) or open(SNAP).read() != now):
    with open(os.path.join(HERE, "core_snapshot.new.txt"), "w") as f:
        f.write(now)
    print("\nThe core has changed (or there's no snapshot yet): the new list is in _dev/core_snapshot.new.txt. "
          "Diff it against core_snapshot.txt, and only with the owner's OK copy it over (CORE.md).")
# What went wrong inside the gamemode while the tests ran, as the server's own errors file would list it
# (sh_livingcity_errors.lua): errors a protected call swallowed show here and nowhere else.
# LC_ERRDUMP=/some/path python3 run_tests.py ...  writes /some/path.<pid>.txt
# The robot players' own report (what each job is made of, how it went): LC_ROBOTS=/some/file python3 run_tests.py ...
if os.environ.get("LC_ROBOTS"):
    rep = L.globals()._ROBOT_REPORT
    if rep:
        with open(os.environ["LC_ROBOTS"], "w") as f:
            f.write(str(rep) + "\n")
if os.environ.get("LC_ERRDUMP"):
    try:
        text = L.eval("LC and LC.ErrorsText and LC.ErrorsText()")
        with open("%s.%d.txt" % (os.environ["LC_ERRDUMP"], os.getpid()), "w") as f:
            f.write(text or "")
    except Exception as e:
        print("could not write the errors list: %s" % e)
print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
