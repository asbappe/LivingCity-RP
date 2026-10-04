"""
Client-side smoke test: runs the HUD and overlay hooks of the client files
against a fake client (no real rendering) to catch runtime errors, like a
nil function or a misspelled variable, in code the server tests can't reach.
"""
import os, sys
from lupa import luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "lua")
L = lj.LuaRuntime(unpack_returned_tuples=True)

L.execute(open(os.path.join(HERE, "gmod_stub.lua")).read())
L.execute(r"""
SERVER, CLIENT = false, true
_calls = {}
local function sink(name)
    return setmetatable({}, { __index = function(t, k)
        return function(...) _calls[name .. "." .. k] = (_calls[name .. "." .. k] or 0) + 1 end
    end })
end
render, mesh, cam, surface = sink("render"), sink("mesh"), sink("cam"), sink("surface")
draw = sink("draw")
function surface.GetTextSize() return 50, 12 end
getmetatable(Vector()).ToScreen = function(v) return { x = 100, y = 100, visible = true } end
function ScrW() return 1920 end
function ScrH() return 1080 end
function EyePos() return Vector(0, 0, 64) end
function EyeAngles() return Angle() end
function CreateMaterial() return {} end
function Material() return {} end
MATERIAL_TRIANGLES, MASK_SOLID_BRUSHONLY = 2, 5
TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM = 0, 1, 2, 3, 4
function math.NormalizeAngle(a) return (a + 180) % 360 - 180 end
function string.FormattedTime(s, fmt) return string.format(fmt or "%02i:%02i", math.floor(s / 60), math.floor(s % 60)) end
function GetGlobal2String(k, d) return _globals[k] or d end
function GetGlobal2Float(k, d) return _globals[k] or d end
function GetGlobal2Bool(k, d) local v = _globals[k] if v == nil then return d end return v end
function Entity() return nil end
function chat_AddText() end
chat = { AddText = function() end }
function SetClipboardText() end
function vgui_stub() end

local cvars_ = {}
local CV = {}
CV.__index = CV
function CV:GetBool() return (tonumber(self.v) or 0) ~= 0 end
function CV:GetInt() return math.floor(tonumber(self.v) or 0) end
function CV:GetFloat() return tonumber(self.v) or 0 end
function CV:GetString() return tostring(self.v) end
function CreateClientConVar(n, d) cvars_[n] = cvars_[n] or setmetatable({ v = d }, CV) return cvars_[n] end
local oldGet = GetConVar
function GetConVar(n) return cvars_[n] or oldGet(n) end
CreateClientConVar("livingcity_editor_mode", "zone_rebel")
CreateClientConVar("livingcity_editor_radius", "300")
CreateClientConVar("lc_economy", "1")

-- the local player, holding the editor
local tool = { IsValid = function() return true end, GetClass = function() return "gmod_tool" end,
    GetMode = function() return "livingcity_editor" end }
_me = _makeplayer("Me", Vector(0, 0, 0))
function _me:GetActiveWeapon() return tool end
function _me:GetEyeTrace() return { Hit = true, HitPos = _aim or Vector(10, 0, 0), StartPos = Vector(0, 0, 64), Entity = nil } end
function _me:GetNW2Bool(k, d) local v = self.nw[k] if v == nil then return d end return v end
function LocalPlayer() return _me end
function util.TraceLine(t) return { Hit = true, HitPos = Vector(t.start.x, t.start.y, 0), StartSolid = false, Fraction = 0.5 } end
""")

files = ["autorun/sh_livingcity_shop.lua", "autorun/sh_livingcity_jobs.lua", "autorun/sh_livingcity_factions.lua",
         "autorun/client/cl_livingcity.lua", "autorun/client/cl_livingcity_needs.lua", "autorun/client/cl_livingcity_factions.lua"]
for rel in files:
    L.globals()._SRC = open(os.path.join(ROOT, rel)).read()
    L.execute("assert(loadstring(_SRC, %r))()" % rel)

result = L.execute(r"""
local problems = {}
local function run(name, ...)
    local hs = hook.t[name] or {}
    for id, fn in pairs(hs) do
        local ok, err = pcall(fn, ...)
        if not ok then problems[#problems + 1] = name .. "/" .. id .. ": " .. tostring(err) end
    end
end
LC_CL.zones = {
    { pos = Vector(0, 0, 0), r = 300, kind = "rebel", group = 0 },
    { pos = Vector(100, 0, 0), r = 800, kind = "block", group = 2 },
}
LC_CL.points = { { pos = Vector(500, 0, 0), yaw = 0, kind = "checkpoint", group = 0 } }
LC_CL.nodes = { [1] = { id = 1, pos = Vector(900, 0, 0), links = {} } }

-- aiming at the small zone's center, in zone mode
_aim = Vector(5, 0, 0)
run("PostDrawTranslucentRenderables", false, false)
run("HUDPaint")
local filled = _calls["mesh.Begin"] or 0
local beams = _calls["render.DrawBeam"] or 0
-- aiming at a point, in a point mode
GetConVar("livingcity_editor_mode").v = "checkpoint"
_aim = Vector(510, 0, 0)
run("PostDrawTranslucentRenderables", false, false)
run("HUDPaint")
-- a zone being placed
GetConVar("livingcity_editor_mode").v = "zone_block"
_aim = Vector(3000, 3000, 0)
run("PostDrawTranslucentRenderables", false, false)
-- someone being stopped and picking a lock
_me.nw.lcu_stop_until = CurTime() + 5
_me.nw.lcu_pick_until = CurTime() + 5
_me.nw.lcu_band = "resistance"
_me.nw.lc_detained_until = CurTime() + 5
_globals.lc_needs_on = true
run("HUDPaint")
run("HUDDrawTargetID")
return table.concat(problems, "\n"), filled, beams
""")
problems, filled, beams = result
print(problems or "no client errors")
print("zone fills drawn:", filled, "thick edges drawn:", beams)
ok = not problems and filled >= 2 and beams > 0
print("CLIENT SMOKE", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
