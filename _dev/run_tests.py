import glob, json, os, sys
import lupa
from lupa import luajit21 as lj

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lua")
HERE = os.path.dirname(os.path.abspath(__file__))
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

order = sorted(os.path.relpath(p, ROOT) for p in glob.glob(ROOT + "/autorun/sh_*.lua")) + sorted(
    os.path.relpath(p, ROOT) for p in glob.glob(ROOT + "/autorun/server/*.lua"))
for rel in order:
    try:
        L.globals()._SRC = open(os.path.join(ROOT, rel)).read()
        L.execute("assert(loadstring(_SRC, %r))()" % rel)
    except Exception as e:
        print("LOAD FAILED", rel, e)
        sys.exit(1)

# weapons and the tool only need to load cleanly
for rel in sorted(os.path.relpath(p, ROOT) for p in glob.glob(ROOT + "/entities/*.lua")):
    L.execute("ENT = {}")
    L.globals()._SRC = open(os.path.join(ROOT, rel)).read()
    L.execute("assert(loadstring(_SRC, %r))()" % rel)
for rel in ["weapons/weapon_lc_baton.lua", "weapons/weapon_lc_claws.lua", "weapons/weapon_lc_blessing.lua"]:
    L.execute("SWEP = {}")
    L.execute(open(os.path.join(ROOT, rel)).read())
L.execute("TOOL = { GetClientInfo = function() return 'idle' end }")
L.execute(open(os.path.join(ROOT, "weapons/gmod_tool/stools/livingcity_editor.lua")).read())

# the gamemode is loaded by the tests themselves, at the point they test it
GMROOT = os.path.join(HERE, "..", "gamemodes", "livingcity", "gamemode")
L.globals()._GMSRC_SHARED = open(os.path.join(GMROOT, "shared.lua")).read()
L.globals()._GMSRC_INIT = open(os.path.join(GMROOT, "init.lua")).read()

L.execute("math.randomseed(7)")
L.globals()._TESTSRC = open(os.path.join(HERE, "tests.lua")).read()
passed, failed, report = L.execute("""
local fn = assert(loadstring(_TESTSRC, "tests.lua"))
local ok, a, b, c = xpcall(fn, debug.traceback)
if not ok then error(a, 0) end
return a, b, c
""")
print(report)
print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
