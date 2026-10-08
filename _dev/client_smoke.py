"""
Client-side smoke test: runs the HUD and overlay hooks of the client files
against a fake client (no real rendering) to catch runtime errors, like a
nil function or a misspelled variable, in code the server tests can't reach.
"""
import os, sys
from lupa import luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
GMDIR = os.path.join(HERE, "..", "gamemodes", "livingcity")
MODS = os.path.join(GMDIR, "gamemode", "modules")
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
function Material() return setmetatable({}, { __index = function(_, k) if k == "IsError" then return function() return false end end return function() end end }) end
MATERIAL_TRIANGLES, MASK_SOLID_BRUSHONLY = 2, 5
TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM = 0, 1, 2, 3, 4
function math.NormalizeAngle(a) return (a + 180) % 360 - 180 end
function string.FormattedTime(s, fmt) return string.format(fmt or "%02i:%02i", math.floor(s / 60), math.floor(s % 60)) end
function GetGlobal2String(k, d) return _globals[k] or d end
function GetGlobal2Float(k, d) return _globals[k] or d end
function GetGlobal2Entity(k, d) return _globals[k] or d end
function GetGlobal2Int(k, d) return _globals[k] or d end
function GetGlobal2Bool(k, d) local v = _globals[k] if v == nil then return d end return v end
function Entity() return nil end
function chat_AddText() end
function MsgC() end
function net.SendToServer() end
input = { IsKeyDown = function() return false end, LookupBinding = function(b) if b == "+use" then return "f" end return nil end }
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

# every shared and client module, in the order the gamemode loads them (its manifest in shared.lua)
import re
_gm_shared = open(os.path.join(GMDIR, "gamemode", "shared.lua")).read()
def _side(side):
    m = re.search(side + r" = \{(.*?)\}", _gm_shared, re.S)
    return [side + "/" + n + ".lua" for n in re.findall(r'"([^"]+)"', m.group(1))]
files = _side("shared") + _side("client")
for rel in files:
    L.globals()._SRC = open(os.path.join(MODS, rel)).read()
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
    { pos = Vector(-2000, 0, 0), r = 300, kind = "prison", group = 0, box = { mins = Vector(-2200, -200, -16), maxs = Vector(-1800, 200, 192) } },
}
LC_CL.blocks = { { n = 2, pos = Vector(0, 0, 0), r = 300, box = { mins = Vector(-200, -200, -16), maxs = Vector(200, 200, 192) } } }
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
-- a box zone being placed: first corner set, aiming at the second
CreateClientConVar("livingcity_editor_shape", "box")
CreateClientConVar("livingcity_editor_height", "192")
LC_CL.boxCorner = Vector(2800, 2800, 0)
local boxesBefore = _calls["render.DrawWireframeBox"] or 0
run("PostDrawTranslucentRenderables", false, false)
if (_calls["render.DrawWireframeBox"] or 0) <= boxesBefore then problems[#problems + 1] = "box zone preview not drawn" end
LC_CL.boxCorner = nil
GetConVar("livingcity_editor_shape").v = "circle"
-- someone being stopped and picking a lock
_me.nw.lcu_stop_until = CurTime() + 5
_me.nw.lcu_pick_until = CurTime() + 5
_me.nw.lcu_band = "resistance"
_me.nw.lc_detained_until = CurTime() + 5
_globals.lc_needs_on = true
run("HUDPaint")
run("HUDDrawTargetID")
-- the rank and XP bar
_me.nw.lcf_faction, _me.nw.lcf_rank, _me.nw.lcf_xp = "cp", 3, 300
run("HUDPaint")
_me.nw.lcf_xp = 325
run("HUDPaint")
local frac, label, col, gain = LC_CL.XPInfo()
if not (frac and math.abs(frac - 75 / 200) < 0.01) then problems[#problems + 1] = "xp bar fraction " .. tostring(frac) end
if label ~= "Unit 04   325 / 450 XP" then problems[#problems + 1] = "xp label " .. tostring(label) end
if gain ~= "+25 XP" then problems[#problems + 1] = "xp gain " .. tostring(gain) end
_me.nw.lcf_rank, _me.nw.lcf_xp = 10, 4100
frac, label = LC_CL.XPInfo()
if label ~= "Sectoral Commander   4100 XP (top rank)" or frac ~= 1 then problems[#problems + 1] = "top rank " .. tostring(label) end
-- down and bleeding out; a stranger in front of you
_me.nw.lc_downed_until = CurTime() + 50
run("HUDPaint")
_me.nw.lc_downed_until = 0
if LC_CL.Description(_me) == nil or LC_CL.Knows(_me) ~= true then problems[#problems + 1] = "recognition helpers" end
-- crossing into rebel territory, a unit's 10-20, the control bar
LC_CL.territory = { { kind = "rebel", pos = Vector(0, 0, 0), r = 500 } }
_me.alive = true
_me:SetPos(Vector(10, 0, 0))
_advance(1)
run("HUDPaint")
LC_CL.marks["CP 04-1"] = { pos = Vector(300, 0, 0), untilT = CurTime() + 60 }
run("HUDPaint")
if LC_CL.TerritoryAt(Vector(10, 0, 0)) ~= "rebel" then problems[#problems + 1] = "territory lookup" end
_globals.lc_ctl_rebel, _globals.lc_ctl_infest, _globals.lc_city_state = 0.2, 0.05, "unrest"
local okBar, errBar = pcall(LC_CL.DrawControlBar, 0, 0, 600, 58)
if not okBar then problems[#problems + 1] = "control bar: " .. tostring(errBar) end
_me.nw.lcf_faction = "admin"
if LC_CL.XPInfo() ~= nil then problems[#problems + 1] = "single-rank factions show no bar" end
run("HUDPaint")
-- tips: one showing, one waiting, then something urgent jumps the queue
LC_CL.ShowHint({ k = "bin", t = "Bins", x = "Press {+use} on a bin. {gm_showteam} for pockets. {+attack2} to arrest.", d = 8 })
LC_CL.ShowHint({ k = "water", t = "Water", x = "Drink with {+use}.", d = 8 })
run("HUDPaint")
if not LC_CL.hintCur or LC_CL.hintCur.key ~= "bin" or #LC_CL.hintQueue ~= 1 then problems[#problems + 1] = "tip queue" end
if not string.find(LC_CL.hintCur.text, "[F]", 1, true) or not string.find(LC_CL.hintCur.text, "[F2]", 1, true)
    or not string.find(LC_CL.hintCur.text, "[Right click]", 1, true) then problems[#problems + 1] = "tip keys: " .. LC_CL.hintCur.text end
LC_CL.ShowHint({ k = "wanted", t = "Wanted", x = "Run.", u = true, d = 8 })
run("HUDPaint")
if not LC_CL.hintCur or LC_CL.hintCur.key ~= "wanted" or LC_CL.hintQueue[1].key ~= "bin" then problems[#problems + 1] = "urgent tip goes first, the other comes back" end
_advance(9)
run("HUDPaint")
if not LC_CL.hintCur or LC_CL.hintCur.key ~= "bin" then problems[#problems + 1] = "next tip after the first ends" end
_advance(0.1)
run("HUDPaint")
-- the admins' testing panel builds (against a do-nothing vgui)
local made = 0
local panel = setmetatable({}, { __index = function(t, k)
    if k == "GetPos" then return function() return 10, 10 end end
    if k == "GetX" or k == "GetY" or k == "GetWide" or k == "GetTall" then return function() return 10 end end
    return function() return t end
end })
vgui = { Create = function() made = made + 1 return panel end }
net.ReadData = function() return _admindata end
util.Decompress = function(s) return s end
util.JSONToTable = function() return { target = "STEAM_0:1|Me", faction = "cp", xp = { cp = 300 }, credits = 50, standing = 100,
    players = { { id = "STEAM_0:1|Me", name = "Me" } } } end
_admindata = "x"
net._q = { 1 }
local okP, errP = pcall(net["recv_lc_admintools"])
if not okP then problems[#problems + 1] = "admin panel: " .. tostring(errP) end
if made < 20 then problems[#problems + 1] = "admin panel built only " .. made .. " controls" end
okP, errP = pcall(net["recv_lc_admintools"]) -- again: it replaces itself where it was
if not okP then problems[#problems + 1] = "admin panel rebuild: " .. tostring(errP) end
-- the CP toolset: the mask's view, the records terminal and the voice menu
_me.nw.lcf_faction, _me.nw.lcf_title = "cp", "CP 04-12"
_me.alive = true
_globals.lc_socio, _globals.lc_bolos = "yellow", 2
run("HUDPaintBackground")
run("HUDPaint")
_me.nw.lc_tied = true
run("HUDPaint")
_me.nw.lc_tied, _me.nw.lc_handsup = false, true
run("HUDPaint")
_me.nw.lc_handsup = false
_me.nw.lcf_faction = "citizen"
_globals.lc_socio = "red"
run("HUDPaint")
util.JSONToTable = function() return {
    people = { { key = "#12-345", name = "Ada Grey", cid = "#12-345", online = true, standing = 40, tier = "Citizen", wanted = true,
        violations = 1, v = { { t = 1700000000, text = "Wanted: test", by = "CP 04" } }, n = { { t = 1700000000, text = "Watch her" } } },
      { key = "#99-000", name = "Old Record", cid = "#99-000", seen = 1700000000, violations = 0, v = {}, n = {} } },
    bolos = { { id = "1-1", key = "#12-345", name = "Ada Grey", cid = "#12-345", text = "red jacket", by = "CP 04", at = 1700000000, untilT = 1900000000 } },
    requests = { { name = "Ada Grey", cid = "#12-345", text = "help", where = "by the ration line", t = 1700000000 } },
    officer = true, socio = "yellow" } end
made = 0
okP, errP = pcall(net["recv_lc_records"])
if not okP then problems[#problems + 1] = "records terminal: " .. tostring(errP) end
if made < 20 then problems[#problems + 1] = "records terminal built only " .. made .. " controls" end
-- picking someone fills in their record
local before = made
okP, errP = pcall(panel.OnRowSelected, panel, 1, { key = "#12-345" })
if not okP then problems[#problems + 1] = "records detail: " .. tostring(errP) end
if made - before < 15 then problems[#problems + 1] = "records detail built only " .. (made - before) .. " controls" end
_me.nw.lcf_faction = "cp"
okP, errP = pcall(LC_CL.OpenVoiceMenu)
if not okP then problems[#problems + 1] = "voice menu: " .. tostring(errP) end
-- the staff panel, and being warned
util.JSONToTable = function() return {
    tickets = { { id = 1, name = "Ada", char = "Ada Grey", status = "open", msgs = { { t = 1700000000, from = "Ada", text = "stuck in a wall" } } } },
    logs = { { t = 1700000000, kind = "chat", text = "Ada says hello", sid = "STEAM_0:0:1" }, { t = 1700000001, kind = "kill", text = "X killed Y" } },
    players = { { name = "Ada", char = "Ada Grey", sid = "STEAM_0:0:1", faction = "citizen", warnings = 1 } },
    warnings = { { idx = 1, name = "Ada", sid = "STEAM_0:0:1", reason = "RDM", by = "Admin", t = 1700000000 } },
    bans = { { name = "Old Name", cid = "#12-345", player = "Ada", reason = "powergaming", by = "Admin", t = 1700000000 } } } end
made = 0
okP, errP = pcall(net["recv_lc_staff"])
if not okP then problems[#problems + 1] = "staff panel: " .. tostring(errP) end
if made < 25 then problems[#problems + 1] = "staff panel built only " .. made .. " controls" end
okP, errP = pcall(net["recv_lc_staff"]) -- refreshed in place
if not okP then problems[#problems + 1] = "staff panel refresh: " .. tostring(errP) end
_globals.lc_tickets_open = 1
_me.IsAdmin = function() return true end
net._q = { "No RDM", "Admin", 1 }
okP, errP = pcall(net["recv_lc_warned"])
if not okP then problems[#problems + 1] = "warned: " .. tostring(errP) end
run("HUDPaint")
-- the character list
util.JSONToTable = function() return { active = 1, slots = { { name = "Ada Grey", cid = "#12-345", model = "models/player/group01/female_01.mdl",
    faction = "Citizen", rank = "Citizen", credits = 20, standing = 0 }, false, { name = "Bo Lind", cid = "#11-111", faction = "Civil Protection" } },
    can = true } end
made = 0
okP, errP = pcall(net["recv_lc_slots"])
if not okP then problems[#problems + 1] = "character list: " .. tostring(errP) end
if made < 8 then problems[#problems + 1] = "character list built only " .. made .. " controls" end
-- pockets by weight, with a locker open beside them
util.JSONToTable = function() return { items = { bread = 2, gun_shotgun = 1, storage_crate = 1 }, size = 12, open = true,
    kg = 5.4, maxKg = 12, bulky = 2, maxBulky = 1,
    container = { id = "locker:x", kind = "locker", name = "the locker", mode = "open", kg = 1.1, maxKg = 25, owner = "Ada Grey", mine = true,
        items = { lockpick = 1, bread = 1 } } } end
made = 0
okP, errP = pcall(net["recv_lci_inv"])
if not okP then problems[#problems + 1] = "pockets with a locker: " .. tostring(errP) end
if made < 15 then problems[#problems + 1] = "pockets built only " .. made .. " controls" end
okP, errP = pcall(panel.Paint, panel, 400, 30)
if not okP then problems[#problems + 1] = "pockets paint: " .. tostring(errP) end
util.JSONToTable = function() return { items = {}, open = true, container = { kind = "crate", name = "the crate", why = "Locked." } } end
okP, errP = pcall(net["recv_lci_inv"])
if not okP then problems[#problems + 1] = "locked crate: " .. tostring(errP) end
-- Civil Intake: what's next, the marker, the bar, the terminal's sign, and the registration form
local desk = ents.Create("lc_intake")
desk:SetPos(Vector(200, 0, 0))
desk.nw.lc_ikind = "register"
_me.alive = true
_me.nw.lc_unreg = true
run("HUDPaint")
if LC_CL.IntakeStep(_me) ~= "register" then problems[#problems + 1] = "a new arrival isn't told to register" end
local nd = LC_CL.NearestDesk("register")
if nd ~= desk then problems[#problems + 1] = "the way to Civil Intake isn't found" end
_me.nw.lc_intake_until, _me.nw.lc_intake_secs, _me.nw.lc_intake_doing = CurTime() + 4, 8, "Processing your registration"
run("HUDPaint")
_me.nw.lc_unreg, _me.nw.lc_unhoused = false, true
if LC_CL.IntakeStep(_me) ~= "housing" then problems[#problems + 1] = "registered with no room: Housing Allocation is next" end
run("HUDPaint")
local okSg, errSg = pcall(LC_CL.DrawIntakeSign, desk)
if not okSg then problems[#problems + 1] = "intake sign: " .. tostring(errSg) end
_me.nw.lc_unhoused, _me.nw.lc_intake_until = false, 0
if LC_CL.IntakeStep(_me) ~= nil then problems[#problems + 1] = "nothing next once you're through intake" end
util.JSONToTable = function() return { intake = true, name = "", model = LCF.CitizenModels[1], models = LCF.CitizenModels, cid = "#12-345",
    reminder = "Choose a realistic name.", desc = "", first = true } end
made = 0
net._q = { 1 }
local okI, errI = pcall(net["recv_lcc_open"])
if not okI then problems[#problems + 1] = "registration form: " .. tostring(errI) end
if made < 11 then problems[#problems + 1] = "registration form built only " .. made .. " controls" end
util.JSONToTable = function() return { name = "Ada Grey", model = LCF.CitizenModels[1], models = LCF.CitizenModels, cid = "#12-345", reminder = "x" } end
net._q = { 1 }
okI, errI = pcall(net["recv_lcc_open"])
if not okI then problems[#problems + 1] = "character window: " .. tostring(errI) end
net._q = { "Ida Hoffman" }
okI, errI = pcall(net["recv_lcc_suggested"])
if not okI then problems[#problems + 1] = "suggested name: " .. tostring(errI) end
desk:Remove()
-- writing, reading, broadcasts, screens and the law
okP, errP = pcall(LC_CL.OpenWriter)
if not okP then problems[#problems + 1] = "writer: " .. tostring(errP) end
util.JSONToTable = function() return { text = "Meet at the canal.\nCome alone.", sig = "Ada Grey", world = "n1", take = true, tear = true } end
okP, errP = pcall(net["recv_lc_read"])
if not okP then problems[#problems + 1] = "reader: " .. tostring(errP) end
okP, errP = pcall(panel.Paint, panel, 400, 300)
if not okP then problems[#problems + 1] = "reader paint: " .. tostring(errP) end
net._q = { "Rations are increased.", "The City Administrator" }
net.ReadString = function() return table.remove(net._q, 1) end
okP, errP = pcall(net["recv_lc_broadcast"])
if not okP then problems[#problems + 1] = "broadcast: " .. tostring(errP) end
run("HUDPaint")
_globals.lc_broadcast = "Stay indoors."
_globals.lc_laws = "x"
util.JSONToTable = function() return { "Obey.", "Comply." } end
okP, errP = pcall(LC_CL.DrawCityScreen, nil)
if not okP then problems[#problems + 1] = "city screen: " .. tostring(errP) end
okP, errP = pcall(LC_CL.DrawLawBoard, nil)
if not okP then problems[#problems + 1] = "law board: " .. tostring(errP) end
util.JSONToTable = function() return { laws = { "Obey.", "Comply." }, edit = true } end
okP, errP = pcall(net["recv_lc_laws"])
if not okP then problems[#problems + 1] = "laws panel: " .. tostring(errP) end
-- night, a storm, the clock
_globals.lc_day_zero, _globals.lc_day_len, _globals.lc_weather = CurTime() - 0.95 * 3600, 3600, "storm"
run("Think")
run("HUDPaintBackground")
run("HUDPaint")
run("PostDrawTranslucentRenderables", false, false)
local okF, errF = pcall(hook.t.SetupWorldFog.LivingCityWeather)
if not okF then problems[#problems + 1] = "fog: " .. tostring(errF) end
if LC_CL.DayPhase(LC_CL.Hour()) ~= "night" then problems[#problems + 1] = "clock: " .. tostring(LC_CL.Hour()) end
-- holding a pose: the camera pulls back
_me.nw.lc_act = "sit"
util.TraceHull = function(t) return { HitPos = t.endpos } end
local view = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(), fov = 75 })
if not view or not view.drawviewer then problems[#problems + 1] = "third person while posing" end
_me.nw.lc_act = ""
-- the one camera: the field of view is capped, whatever else moves it
if hook.t.CalcView and (hook.t.CalcView.LivingCityActs or hook.t.CalcView.LivingCityScanner or hook.t.CalcView.LivingCityDizzy) then
    problems[#problems + 1] = "a camera hook outside the camera: it would take the view from the others"
end
GetConVar("lc_fov").v = "75"
local fv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 100 })
if fv.fov ~= 75 then problems[#problems + 1] = "field of view not capped: " .. tostring(fv.fov) end
fv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 30 })
if fv.fov ~= 30 then problems[#problems + 1] = "a zoom narrower than the cap was widened: " .. tostring(fv.fov) end
GetConVar("lc_fov").v = "0"
fv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 100 })
if fv.fov ~= 100 then problems[#problems + 1] = "lc_fov 0 should leave the player's own: " .. tostring(fv.fov) end
GetConVar("lc_fov").v = "75"
_me.nw.lc_act = "sit"
fv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(), fov = 100 })
if fv.fov ~= 75 or not fv.drawviewer then problems[#problems + 1] = "posing loses the field of view cap" end
_me.nw.lc_act = ""
-- a body under the camera: walking sways it, standing still doesn't, a landing dips it
_me.vel = Vector(150, 0, 0)
_me.GetVelocity = function(self) return self.vel end
_me.ground = true
local moved = false
for _ = 1, 12 do
    _advance(0.05)
    local bv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
    if math.abs(bv.origin.z - 61) > 0.05 or math.abs(bv.origin.y) > 0.05 then moved = true end
end
if not moved then problems[#problems + 1] = "the camera doesn't sway while walking" end
_me.vel = Vector(0, 0, -600)
_me.ground = false
_advance(0.05) LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
_me.vel = Vector(0, 0, 0)
_me.ground = true
local lowest = 61
for _ = 1, 6 do
    _advance(0.03)
    local bv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
    lowest = math.min(lowest, bv.origin.z)
end
if lowest > 59 then problems[#problems + 1] = "a hard landing doesn't dip the camera: " .. tostring(lowest) end
for _ = 1, 40 do _advance(0.05) LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 }) end
local settled = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
if math.abs(settled.origin.z - 61) > 0.3 then problems[#problems + 1] = "the camera doesn't settle after a landing: " .. tostring(settled.origin.z) end
GetConVar("lc_my_view_bob").v = "0"
_me.vel = Vector(150, 0, 0)
local still = true
for _ = 1, 8 do
    _advance(0.05)
    local bv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
    if math.abs(bv.origin.z - 61) > 0.001 or math.abs(bv.origin.y) > 0.001 then still = false end
end
if not still then problems[#problems + 1] = "lc_my_view_bob 0 still sways the camera" end
GetConVar("lc_my_view_bob").v = "1"
GetConVar("lc_view_bob_amount").v = "0"
still = true
for _ = 1, 8 do
    _advance(0.05)
    local bv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
    if math.abs(bv.origin.z - 61) > 0.001 or math.abs(bv.origin.y) > 0.001 then still = false end
end
if not still then problems[#problems + 1] = "lc_view_bob_amount 0 still sways the camera" end
GetConVar("lc_view_bob_amount").v = "100"
_me.vel = Vector(0, 0, 0)
-- a camera step that errors is switched off, and the rest still run
LC_CL.ViewMods.broken_test = { order = 1, fn = function() error("boom") end }
_errors = {}
_advance(1.1) -- (the order is looked at again once a second)
local okB, bvB = pcall(LC_CL.CalcView, _me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 100 })
if not okB or bvB.fov ~= 75 or #_errors ~= 1 then problems[#problems + 1] = "one failing camera step takes the rest down" end
okB, bvB = pcall(LC_CL.CalcView, _me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 100 })
if #_errors ~= 1 then problems[#problems + 1] = "a failed camera step keeps running (and erroring)" end
LC_CL.ViewMods.broken_test = nil
_errors = {}
-- flying a scanner: the view leaves the body, and units see who a report caught
local scn = ents.Create("lc_rscanner")
scn:SetPos(Vector(500, 0, 200))
scn.nw.lc_pilot = _me
scn.nw.lc_flash_at = CurTime()
_me.nw.lc_scanner = scn
_me.nw.lc_jail_until = CurTime() + 200
local sview = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(), fov = 75 })
if not sview or sview.origin.x < 400 or not sview.drawviewer then problems[#problems + 1] = "scanner view isn't from the scanner" end
if hook.t.PreDrawViewModel.LivingCityScanner() ~= true then problems[#problems + 1] = "viewmodel shows while flying a scanner" end
local halos = 0
halo = { Add = function(list) halos = halos + #list end }
DynamicLight = function() return {} end
local suspect = ents.Create("npc_citizen")
suspect:SetPos(Vector(300, 0, 0))
suspect.nw.lc_spotted_until = CurTime() + 60
suspect.nw.lc_spotted_why = "a rebel"
scn.nw.lc_target = suspect
scn.nw.lc_target_why = "a rebel"
scn.nw.lc_ground = true
run("HUDPaintBackground")
_me.nw.lc_crippled_until = CurTime() + 100
_me.nw.lc_interrogated = true
_me.nw.lc_unit = true
_me.nw.lc_jammed = true
scn.nw.lc_jammed = true
run("Think")
run("HUDPaint")
run("PreDrawHalos")
if halos < 1 then problems[#problems + 1] = "a scanner report isn't highlighted for units" end
_me.nw.lc_scanner = nil
_me.nw.lc_unit = nil
_me.nw.lc_jammed = nil
suspect.nw.lc_spotted_until = 0
local after = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(), fov = 75 })
if after.drawviewer or after.origin.x > 1 then problems[#problems + 1] = "scanner view stuck after the link" end
-- the quiet HUD: no running score; hunger and thirst only when they bite, or just after eating
GetConVar("lc_quiet_hud").v = "1"
_globals.lc_needs_on = true
_me.nw.lcn_hunger, _me.nw.lcn_thirst = 90, 90
if not LC_CL.QuietHUD() then problems[#problems + 1] = "quiet HUD setting not read" end
if LC_CL.NeedsVisible(_me) then problems[#problems + 1] = "quiet HUD shows full hunger and thirst" end
_me.nw.lcn_hunger = 30
if not LC_CL.NeedsVisible(_me) then problems[#problems + 1] = "quiet HUD hides hunger when it bites" end
_me.nw.lcn_hunger = 40
LC_CL.NeedsVisible(_me)
_me.nw.lcn_hunger = 85 -- (ate something)
if not LC_CL.NeedsVisible(_me) then problems[#problems + 1] = "quiet HUD doesn't show the bars after eating" end
_advance(7)
if LC_CL.NeedsVisible(_me) then problems[#problems + 1] = "the bars stay up long after eating" end
_me.nw.lcf_faction, _me.nw.lcf_rank, _me.nw.lcf_xp = "cp", 3, 300
run("HUDPaint")
if hook.t.DrawDeathNotice.LivingCityQuietHUD() ~= false then problems[#problems + 1] = "the kill feed shows on a quiet HUD" end
GetConVar("lc_quiet_hud").v = "0"
if hook.t.DrawDeathNotice.LivingCityQuietHUD() ~= nil then problems[#problems + 1] = "the kill feed is hidden with the quiet HUD off" end
if not LC_CL.NeedsVisible(_me) then problems[#problems + 1] = "with the quiet HUD off the bars always show" end
run("HUDPaint")
GetConVar("lc_quiet_hud").v = "1"
-- the death card
if LC_CL.Span(59) ~= "less than a minute" or LC_CL.Span(60) ~= "1 minute" or LC_CL.Span(11520) ~= "3 hours 12 minutes"
    or LC_CL.Span(90061) ~= "1 day 1 hour" or LC_CL.Span(7200) ~= "2 hours" then
    problems[#problems + 1] = "time lived reads wrong: " .. LC_CL.Span(11520) .. " / " .. LC_CL.Span(90061)
end
_me.alive = false
util.JSONToTable = function() return { gone = true, name = "Ada Grey", cid = "#12-345", lived = 11520, full = true, known = 6, she = true,
    cause = "Shot by a masked Civil Protection unit.", wait = 12 } end
_admindata = "x"
net.ReadData = function() return _admindata end
net._q = { 1 }
local okO, errO = pcall(net["recv_lc_obituary"])
if not okO then problems[#problems + 1] = "death card: " .. tostring(errO) end
local dl = LC_CL.DeathLines(LC_CL.DeathCard())
if dl[1] ~= "Lived 3 hours 12 minutes in the city." or dl[2] ~= "Six people knew her name." or dl[3] ~= "Shot by a masked Civil Protection unit." then
    problems[#problems + 1] = "death card lines: " .. tostring(dl[1]) .. " | " .. tostring(dl[2]) .. " | " .. tostring(dl[3])
end
for _ = 1, 3 do _advance(5) run("PostDrawHUD") end
if not LC_CL.DeathCard() then problems[#problems + 1] = "the death card went away before you came back" end
_me.alive = true
run("PostDrawHUD")
if LC_CL.DeathCard() then problems[#problems + 1] = "the death card stays after you're back" end
_advance(1) run("PostDrawHUD")
local nl = LC_CL.DeathLines({ gone = true, name = "Bo", lived = 30, known = 0, she = false })
if nl[1] ~= "Lived in the city since before anyone kept count." then problems[#problems + 1] = "untracked short life: " .. tostring(nl[1]) end
if LC_CL.DeathLines({ gone = true, lived = 20, full = true, known = 2 })[1] ~= "Lived less than a minute in the city." then problems[#problems + 1] = "a short life" end
if nl[2] ~= "Nobody knew his name." then problems[#problems + 1] = "nobody knew: " .. tostring(nl[2]) end
nl = LC_CL.DeathLines({ gone = true, lived = 600, full = false, known = 1 })
if nl[1] ~= "Lived at least 10 minutes in the city." or nl[2] ~= "One person knew his name." then problems[#problems + 1] = "untracked life: " .. tostring(nl[1]) .. " | " .. tostring(nl[2]) end
nl = LC_CL.DeathLines({ gone = false, note = "Died in custody: you're still you, and still serving your time." })
if #nl ~= 1 or not string.find(nl[1], "custody", 1, true) then problems[#problems + 1] = "a death that isn't the end says why" end
_me.alive = false
util.JSONToTable = function() return { gone = false, name = "Ada Grey", note = "Build mode: you keep this character.", wait = 0 } end
net._q = { 1 }
okO, errO = pcall(net["recv_lc_obituary"])
_advance(4) run("PostDrawHUD")
if not okO then problems[#problems + 1] = "short death card: " .. tostring(errO) end
_me.alive = true
run("PostDrawHUD")
-- smoke and gas clouds: grey particles, drawn here and thinned out over time
local emitted, colors = 0, {}
local fakeP = setmetatable({}, { __index = function(t, k)
    if k == "SetColor" then return function(_, r, g, b) colors[#colors + 1] = { r, g, b } end end
    return function() end
end })
ParticleEmitter = function() return { Add = function() emitted = emitted + 1 return fakeP end, Finish = function() end } end
VectorRand = VectorRand or function() return Vector(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) end
net.ReadVector = function() return Vector(10, 0, 0) end
local q = { "smoke" }
net.ReadString = function() return table.remove(q, 1) end
local fl = { 22, 240 }
net.ReadFloat = function() return table.remove(fl, 1) end
okP, errP = pcall(net["recv_lc_cloud"])
if not okP then problems[#problems + 1] = "smoke cloud: " .. tostring(errP) end
_advance(1)
run("Think")
if emitted < 20 then problems[#problems + 1] = "smoke cloud drew only " .. emitted .. " puffs" end
for _, c in ipairs(colors) do
    if c[1] > 170 or c[1] ~= c[2] or c[2] ~= c[3] then problems[#problems + 1] = "smoke isn't grey: " .. c[1] .. "," .. c[2] .. "," .. c[3] break end
end
_advance(30)
run("Think")
if #LC_CL.clouds ~= 0 then problems[#problems + 1] = "smoke cloud never cleared" end
GM = { LCBuilder = function() return false end }
function include() end
function DeriveGamemode() end
LC_LoadModules = LC_LoadModules or function() end
KEY_F1 = 92
gui = { IsGameUIVisible = function() return false end }
-- The F1 menu and Unit tools: every chat command a player can type has a place in a menu
do
    local seen = {}
    local function Note(k) seen[k] = true end
    local cur
    local saved = { Start = net.Start, WriteString = net.WriteString, WriteEntity = net.WriteEntity, WriteBool = net.WriteBool,
        SendToServer = net.SendToServer, RCC = RunConsoleCommand, vgui = vgui, DermaMenu = DermaMenu, SR = Derma_StringRequest, Q = Derma_Query,
        gui = gui, IsAdmin = _me.IsAdmin, Trace = _me.GetEyeTrace }
    net.Start = function(n) cur = { name = n, data = {} } end
    net.WriteString = function(v) table.insert(cur.data, v) end
    net.WriteEntity = function(v) table.insert(cur.data, v or false) end
    net.WriteBool = function(v) table.insert(cur.data, v) end
    net.SendToServer = function()
        if cur.name == "lc_action" then Note(cur.data[1]) else Note("net:" .. cur.name) end
    end
    RunConsoleCommand = function(cmd, a)
        if cmd == "say" then Note("say:" .. string.match(a or "", "^(%S+)")) else Note("console:" .. tostring(cmd)) end
    end
    Derma_StringRequest = function(title, prompt, default, fn) fn("test words") end
    Derma_Query = function(text, title, yes, fn) fn() end
    gui = { EnableScreenClicker = function() end, IsGameUIVisible = function() return false end }
    local clicks = {}
    local function Proxy()
        return setmetatable({}, {
            __index = function(t, k)
                if k == "GetPos" then return function() return 10, 10 end end
                if k == "GetX" or k == "GetY" or k == "GetWide" or k == "GetTall" then return function() return 10 end end
                if k == "IsValid" then return function() return true end end
                return function() return t end
            end,
            __newindex = function(t, k, v) if k == "DoClick" then clicks[#clicks + 1] = v end rawset(t, k, v) end,
        })
    end
    vgui = { Create = function() return Proxy() end }
    local menus = {}
    local function NewMenu()
        local m = { opts = {} }
        function m:AddOption(label, fn) local o = { label = label, fn = fn, SetIcon = function() end } table.insert(self.opts, o) return o end
        function m:AddSubMenu(label) local sub = NewMenu() local o = { label = label, sub = sub, SetIcon = function() end } table.insert(self.opts, o) return sub, o end
        function m:AddSpacer() end
        function m:Open() end
        function m:Center() end
        function m:Remove() self.removed = true end
        function m:IsValid() return not self.removed end
        return m
    end
    DermaMenu = function() local m = NewMenu() menus[#menus + 1] = m return m end
    local function Walk(m)
        for _, o in ipairs(m.opts) do
            if o.sub then Walk(o.sub) elseif o.fn then
                local okW, errW = pcall(o.fn)
                if not okW then problems[#problems + 1] = "menu item '" .. tostring(o.label) .. "': " .. tostring(errW) end
            end
        end
    end
    local other = _makeplayer("MenuOther", Vector(40, 0, 0))
    other.nw.lc_cid, other.nw.lcf_faction = "#55-555", "vort"
    local function Look(ent) _me.GetEyeTrace = function() return { Hit = true, HitPos = Vector(30, 0, 64), Entity = ent } end end
    local function Run(faction, admin, setup)
        _me.nw = { lcf_faction = faction, lce_standing = 200 }
        _me.alive = true
        _me:SetPos(Vector(0, 0, 0))
        _me.weps = { "weapon_pistol", "weapon_lc_multitool" }
        _me.IsAdmin = function() return admin == true end
        Look(nil)
        if setup then setup() end
        for _, m in ipairs(menus) do m.removed = true end
        local okO, errO = pcall(LC_CL.OpenActions)
        if not okO then problems[#problems + 1] = "F1 menu for " .. faction .. ": " .. tostring(errO) return end
        Walk(menus[#menus])
        menus[#menus].removed = true
        -- and whatever the Unit tools window offers
        local now = clicks
        clicks = {}
        for _, fn in ipairs(now) do
            local okC, errC = pcall(fn)
            if not okC then problems[#problems + 1] = "unit tools button: " .. tostring(errC) end
        end
    end
    local NOW = CurTime()
    -- everyone, with all the situations that bring extra items
    Run("citizen", false, function()
        _me.nw.lc_downed_until, _me.nw.lc_wanted_until, _me.nw.lc_tied = NOW + 50, NOW + 50, true
        _me.nw.lc_interrogated, _me.nw.lc_hauling, _me.nw.lc_scanner = true, true, ents.Create("lc_rscanner")
        _me.nw.lcj_job = "porter"
    end)
    Run("citizen", false, function() _me.nw.lc_foreman = true other.nw.lc_tied = true Look(other) end)
    Run("cp", false, function() other.nw.lc_tied, other.nw.lcj_job = true, "porter" Look(other) end)
    Run("cp", false, function() other.nw.lc_tied = false other.nw.lc_handsup = true Look(other) end)
    Run("resistance", false, function() Look(other) end)
    Run("citizen", true, function()
        local door = ents.Create("prop_door_rotating") Look(door)
    end)
    Run("citizen", false, function() local b = ents.Create("prop_ragdoll") b.nw.lc_body = true Look(b) end)
    Run("citizen", false, function() local b = ents.Create("prop_ragdoll") b.nw.lc_downed_body = true Look(b) end)
    Run("resistance", false, function() Look(ents.Create("lc_screen")) end)
    -- the quick menu (F1): nine for everyone, and every item and page runs
    local function Quick(faction, setup)
        _me.nw = { lcf_faction = faction, lce_standing = 200, lcf_rank = 9 }
        _me.alive = true
        _me.IsAdmin = function() return faction == "admin" end
        Look(nil)
        if setup then setup() end
        local okQ, root = pcall(LC_CL.QuickRoot)
        if not okQ then problems[#problems + 1] = "quick menu for " .. faction .. ": " .. tostring(root) return end
        for i = 1, 9 do if not root.items[i] then problems[#problems + 1] = "quick menu for " .. faction .. ": slot " .. i .. " is empty" end end
        local function WalkQ(page, depth)
            for i = 1, 9 do
                local it = page.items[i]
                if it and it.page then
                    local okP, sub = pcall(it.page)
                    if not okP then problems[#problems + 1] = "quick page '" .. tostring(it.label) .. "': " .. tostring(sub)
                    elseif depth < 2 then WalkQ(sub, depth + 1) end
                elseif it and it.run and i ~= 9 or (it and it.run and depth > 0) then
                    local okR, errR = pcall(it.run)
                    if not okR then problems[#problems + 1] = "quick item '" .. tostring(it.label) .. "' (" .. faction .. "): " .. tostring(errR) end
                end
            end
        end
        WalkQ(root, 0)
        -- and by the keys: open it, into a page, back, and closed
        LC_CL.OpenQuick()
        local okH, errH = pcall(function() for id, fn in pairs(hook.t.HUDPaint or {}) do if id == "LivingCityQuick" then fn() end end end)
        if not okH then problems[#problems + 1] = "quick menu drawing (" .. faction .. "): " .. tostring(errH) end
        local pageSlot
        for i = 1, 8 do if root.items[i] and root.items[i].page then pageSlot = i break end end
        if pageSlot then
            LC_CL.QuickPick(pageSlot)
            if not LC_CL.QuickOpen() then problems[#problems + 1] = "a quick menu page closed the menu (" .. faction .. ")" end
            LC_CL.QuickPick(0)
        end
        LC_CL.QuickPick(0)
        if LC_CL.QuickOpen() then problems[#problems + 1] = "0 didn't close the quick menu (" .. faction .. ")" end
    end
    Quick("cp") Quick("ota") Quick("citizen") Quick("resistance") Quick("admin")
    Quick("cp", function() other.nw.lc_tied, other.nw.lcj_job = true, "porter" Look(other) end)
    Quick("citizen", function() other.nw.lc_tied = false Look(other) _me.nw.lc_foreman = true end)
    Quick("citizen", function() _me.nw.lc_downed_until, _me.nw.lc_tied, _me.nw.lc_wanted_until = CurTime() + 50, true, CurTime() + 50 end)
    Quick("citizen", function() local b = ents.Create("prop_ragdoll") b.nw.lc_body = true Look(b) end)
    Quick("citizen", function() local b = ents.Create("prop_ragdoll") b.nw.lc_downed_body = true Look(b) end)
    Quick("resistance", function() Look(ents.Create("prop_door_rotating")) end)
    Quick("cp", function() Look(ents.Create("lc_powerbank")) end)
    -- the terminals' screens, the lab, the papers card, notices and a waypoint
    local okD, errD = pcall(function()
        local base = { name = "Erika Hollis", cid = "#63-501", credits = 30, standing = 10, papersFee = 10, cardFee = 15, good = 50,
            blocks = { { n = 1, name = "Habitation Block 01", residents = 2, m = 40 }, { n = 2, name = "Habitation Block 02", residents = 6 } } }
        local function With(t) local o = table.Copy and table.Copy(base) or {} for k, v in pairs(base) do o[k] = v end for k, v in pairs(t) do o[k] = v end return o end
        LC_CL.OpenDesk(With({ kind = "register", papers = false, card = true, awaiting = true, housingDesk = true }))
        LC_CL.OpenDesk(With({ kind = "housing", pending = true }))
        LC_CL.OpenDesk(With({ kind = "housing", awaiting = true, papers = true }))
        LC_CL.OpenDesk(With({ kind = "housing", block = 2, blockName = "Habitation Block 02", how = "auto", transfer = true, papers = true }))
        LC_CL.OpenDesk(With({ kind = "housing", block = 2, blockName = "Habitation Block 02", how = "allocation", transfer = false, transferWhy = "Too soon." }))
        LC_CL.OpenLab({ credits = 50, items = { { id = "gun_pistol", name = "Homemade pistol", desc = "A pistol", secs = 12, price = 72, canPay = false, canMats = true,
            mats = { { name = "Gun parts", have = 2, need = 2 } } } } })
        LC_CL.OpenLab({ credits = 0, busy = 5, items = {} })
        LC_CL.ShowPapersCard({ name = "Erika Hollis", cid = "#63-501", block = "Habitation Block 02", desc = "tall, grey coat", card = true, from = true })
        LC_CL.AddNotice("warn", "Civil Protection", "Papers. None? Carry them at all times.", 0)
        LC_CL.AddNotice("warn", "Civil Protection", "Papers. None? Carry them at all times.", 0)
        LC_CL.AddNotice("speech", "Rebel", "Hey! Those are our supplies. Quit it.", 0)
        LC_CL.AddNotice("event", "Civil status inspections", "Units stop and search people far more often.", 0)
        LC_CL.SetWaypoint(Vector(900, 0, 0), "Housing Allocation", 160)
        for id, fn in pairs(hook.t.HUDPaint or {}) do
            if id == "LivingCityNotices" or id == "LivingCityPapers" then fn() end
        end
        _me:SetPos(Vector(890, 0, 0))
        for id, fn in pairs(hook.t.HUDPaint or {}) do if id == "LivingCityNotices" then fn() end end
        if LC_CL.Waypoint() then error("the waypoint didn't clear on arrival") end
        _me:SetPos(Vector(0, 0, 0))
    end)
    if not okD then problems[#problems + 1] = "screens, lab, papers, notices: " .. tostring(errD) end
    -- every chat command, and where it is now
    local WHERE = {
        ["!handsup"] = "handsup", ["!holster"] = "holster", ["!surrender"] = "surrender", ["!struggle"] = "struggle", ["!stuck"] = "stuck",
        ["!stash"] = "stash", ["!fish"] = "fish", ["!salvage"] = "salvage", ["!donate"] = "donate", ["!plain"] = "plain", ["!gearup"] = "gearup",
        ["!recognize"] = "recognize", ["!tie"] = "tie", ["!untie"] = "untie", ["!drag"] = "drag", ["!search"] = "search", ["!backup"] = "backup",
        ["!10-20"] = "10-20", ["!records"] = "records", ["!vo"] = "vo", ["!unshackle"] = "unshackle", ["!decode"] = "decode",
        ["!foreman"] = "foreman", ["!assign"] = "assign", ["!rent"] = "rent", ["!pick"] = "pick", ["!hack"] = "hack", ["!hijack"] = "hijack",
        ["!inform"] = "inform", ["/request"] = "request", ["!r"] = "r", ["!ru"] = "ru", ["!unlink"] = "unlink",
        ["/sit"] = "sit", ["/kneel"] = "kneel", ["/lie"] = "lie", ["/lean"] = "lean", ["/cower"] = "cower", ["/stand"] = "stand", ["/pose"] = "pose",
        ["!socio"] = "socio", ["!bolo"] = "bolo", ["!giveup"] = "giveup", ["!talk"] = "net:lc_interrogate_reply", ["!papers"] = "papers",
        ["!credits"] = "credits", ["!characters"] = "characters", ["!character"] = "character", ["/chardesc"] = "chardesc",
        ["!shop"] = "shop", ["!market"] = "market", ["!write"] = "write", ["!block"] = "block", ["!apartment"] = "apartment",
        ["!lock"] = "lock", ["!unlock"] = "unlock", ["!givekey"] = "givekey", ["!takekey"] = "takekey", ["!unrent"] = "unrent",
        ["!time"] = "time", ["!city"] = "city", ["!laws"] = "laws", ["!broadcast"] = "broadcast", ["!bob"] = "console:lc_bob_toggle",
        ["!hints"] = "hints", ["@ (a ticket)"] = "ticket", ["!report"] = "ticket", ["!build"] = "build", ["!admintools"] = "admintools",
        ["!givexp and the other admin chat tools"] = "admintools", ["!staff"] = "staff", ["!warn, !charban"] = "staff", ["!pathmap"] = "pathmap",
        ["!escort"] = "escort", ["!inv, !craft, !give"] = "console:gm_showteam", ["!jobs, !abandon"] = "console:gm_showspare1",
        ["!faction"] = "console:gm_showspare2", ["!help"] = "console:lc_help", ["!hints (read them again)"] = "net:lc_hints_list",
        ["/y"] = "say:/y", ["/w"] = "say:/w", ["/me"] = "say:/me", ["/it"] = "say:/it", ["/roll"] = "say:/roll", ["/looc"] = "say:/looc",
        ["//"] = "say://", ["mail (units)"] = "readmail", ["turrets and power banks"] = "checkpoint", ["bodies"] = "searchbody",
        ["hauling"] = "haul", ["mask voice"] = "vo", ["third person while posing"] = "console:lc_act_thirdperson",
        ["!setlaw, !addlaw, !dellaw (the laws panel)"] = "laws", ["microphones"] = "takemic",
    }
    for n in pairs(LCA.Gestures) do WHERE["/" .. n] = n end
    local missing = {}
    for cmd, where in pairs(WHERE) do if not seen[where] then missing[#missing + 1] = cmd .. " (" .. where .. ")" end end
    table.sort(missing)
    if #missing > 0 then problems[#problems + 1] = "no menu for: " .. table.concat(missing, ", ") end
    -- put everything back
    net.Start, net.WriteString, net.WriteEntity, net.WriteBool, net.SendToServer = saved.Start, saved.WriteString, saved.WriteEntity, saved.WriteBool, saved.SendToServer
    RunConsoleCommand, vgui, DermaMenu, Derma_StringRequest, Derma_Query, gui = saved.RCC, saved.vgui, saved.DermaMenu, saved.SR, saved.Q, saved.gui
    _me.IsAdmin, _me.GetEyeTrace = saved.IsAdmin, saved.Trace
    _me.nw = {}
    other:Remove()
end
return table.concat(problems, "\n"), filled, beams
""")
problems, filled, beams = result
GMROOT = os.path.join(GMDIR, "gamemode")
L.globals()._SRC = open(os.path.join(GMROOT, "cl_init.lua")).read()
more = L.execute(r"""
local problems = {}
local ok0, err0 = pcall(function() assert(loadstring(_SRC, "cl_init.lua"))() end)
if not ok0 then return "cl_init: " .. tostring(err0) end
local made = 0
local panel = setmetatable({}, { __index = function(t, k)
    if k == "GetWide" then return function() return 900 end end
    if k == "GetValue" then return function() return t._v or "" end end
    if k == "SetValue" then return function(_, v) t._v = v end end
    if k == "IsValid" then return function() return not t._removed end end
    if k == "Remove" then return function() t._removed = true end end
    return function() return t end
end })
vgui = { Create = function() made = made + 1 panel._removed = nil return panel end, GetKeyboardFocus = function() return nil end }
local f1 = false
input.IsKeyDown = function(k) return k == KEY_F1 and f1 end
local function run(name) for id, fn in pairs(hook.t[name] or {}) do local ok, e = pcall(fn) if not ok then problems[#problems + 1] = name .. "/" .. id .. ": " .. tostring(e) end end end
-- F1 opens the actions menu (the guide is its first item)
local f1menu = 0
DermaMenu = function()
    local m
    m = setmetatable({}, { __index = function(t, k)
        if k == "AddSubMenu" then return function() return m, m end end
        if k == "AddOption" then return function() f1menu = f1menu + 1 return m end end
        if k == "IsValid" then return function() return false end end
        return function() return m end
    end })
    return m
end
gui = gui or {}
gui.EnableScreenClicker = function() end
gui.IsGameUIVisible = gui.IsGameUIVisible or function() return false end
f1 = true run("Think")
if not (LC_CL.QuickOpen and LC_CL.QuickOpen()) then problems[#problems + 1] = "F1 didn't open the quick menu" end
f1 = false run("Think")
LC_CL.QuickPick(9) -- 9: everything else, the full menu
if f1menu < 4 then problems[#problems + 1] = "the quick menu's 9 didn't open the full menu (" .. f1menu .. " options)" end
if LC_CL.QuickOpen() then problems[#problems + 1] = "picking 9 left the quick menu open" end
LC_CL.OpenActions() -- (closes it again)
made = 0
LC_OpenGuide(true)
if made < 20 then problems[#problems + 1] = "the guide didn't open (" .. made .. " controls)" end
f1 = true run("Think")
if not panel._removed then problems[#problems + 1] = "F1 with the guide open didn't close it" end
f1 = false run("Think")
made = 0
LC_CL.ActionsOpenedAt = 0
net._q = { true }
local okR, errR = pcall(net["recv_lcg_help"])
if not okR then problems[#problems + 1] = "!help: " .. tostring(errR) end
if made < 20 then problems[#problems + 1] = "!help didn't open the guide" end
panel._v = "tie"
local okS, errS = pcall(panel.OnChange, panel)
if not okS then problems[#problems + 1] = "guide search: " .. tostring(errS) end
-- on air with no player: Dr. Breen's address, on the screens and the banner
_globals.lc_live_npc, _globals.lc_live_name = true, "Dr. Breen"
local okTm, errTm = pcall(function() _advance(0.1) _runtimers() end) -- (the screen override goes in on the next tick)
if not okTm then problems[#problems + 1] = "client timers: " .. tostring(errTm) end
local okA, errA = pcall(function()
    run("HUDPaint")
    if LC_CL.DrawCityScreen then LC_CL.DrawCityScreen(nil) end
    if not (LC_CL.OnAir and select(2, LC_CL.OnAir()) == "Dr. Breen") then error("OnAir doesn't name Dr. Breen") end
end)
if not okA then problems[#problems + 1] = "Dr. Breen on air: " .. tostring(errA) end
net._q = { "vo/breencast/br_welcome01.wav" }
local okBr, errBr = pcall(net["recv_lc_breencast"])
if not okBr then problems[#problems + 1] = "breencast line: " .. tostring(errBr) end
_globals.lc_live_npc, _globals.lc_live_name = nil, nil
-- lenses (mask and scanner) and rain: drawn every frame, so they'd better not error
local okL, errL = pcall(LC_CL.DrawLens, 1920, 1080, { 10, 30, 45, 24 }, { 0, 6, 12, 190 }, { 120, 200, 255, 6 })
if not okL then problems[#problems + 1] = "lens: " .. tostring(errL) end
okL, errL = pcall(LC_CL.DrawLens, 1920, 1080, { 10, 30, 45, 24 }, { 0, 6, 12, 190 }, { 120, 200, 255, 6 }) -- (second time: the cached texture)
if not okL then problems[#problems + 1] = "lens again: " .. tostring(errL) end
_globals.lc_weather = "storm"
run("Think")
run("PostDrawTranslucentRenderables", false, false)
_advance(1)
run("PostDrawTranslucentRenderables", false, false)
_globals.lc_weather = nil
-- the clock line with the city's ration stores showing
_globals.lc_stock_on, _globals.lc_stock, _globals.lc_stock_max = true, 40, 400
run("HUDPaint")
_globals.lc_stock_on = nil
-- the mail: a unit reading it at the post office, and a letter you can send
local oldJ = util.JSONToTable
net.ReadUInt = function() return 1 end
net.ReadData = function() return "x" end
util.Decompress = function(s) return s end
made = 0
util.JSONToTable = function() return { letters = { { id = "L1", from = "Mira Kovacs", sig = nil, to = "Pavel Novak", text = "Meet me by the canal." } } } end
local okMl, errMl = pcall(net["recv_lc_mail_list"])
if not okMl then problems[#problems + 1] = "mail list: " .. tostring(errMl) end
if made < 4 then problems[#problems + 1] = "mail list built only " .. made .. " controls" end
util.JSONToTable = function() return { text = "Meet me by the canal.", sig = "M.", carried = 1, letter = true, to = { { "cid-1", "Pavel Novak" } } } end
made = 0
local okLt, errLt = pcall(net["recv_lc_read"])
if not okLt then problems[#problems + 1] = "letter: " .. tostring(errLt) end
if made < 5 then problems[#problems + 1] = "letter window built only " .. made .. " controls" end
util.JSONToTable = oldJ
-- the talk window (E on a citizen)
local talkNpc = ents.Create("npc_citizen")
net.ReadString = function() return table.remove(net._q, 1) end
net.ReadBool = function() return table.remove(net._q, 1) == true end
net.ReadEntity = function() return table.remove(net._q, 1) end
made = 0
net._q = { talkNpc, "Mira Kovacs", "Factory Worker", "working the line", "friendly", "warm", "'Another day.'", true, true, true, true, true }
local okTk, errTk = pcall(net["recv_lc_talk"])
if not okTk then problems[#problems + 1] = "talk window: " .. tostring(errTk) end
if made < 8 then problems[#problems + 1] = "talk window built only " .. made .. " controls (valid npc: " .. tostring(IsValid(talkNpc)) .. ")" end
net._q = { nil }
okTk, errTk = pcall(net["recv_lc_talk"]) -- (and closing it)
if not okTk then problems[#problems + 1] = "talk window close: " .. tostring(errTk) end
-- the editor's layout browser: counts, find through walls
LC_CL.points = { { pos = Vector(100, 0, 0), kind = "dealer" } }
LC_CL.zones, LC_CL.doors, LC_CL.nodes = {}, {}, {}
local okB, errB = pcall(LC_CL.BuildLayoutBrowser, panel, { { id = "dealer", label = "Fixture: black market dealer" },
    { id = "zone_rebel", label = "Zone: rebel territory" }, { id = "inspect", label = "Inspect anything" } })
if not okB then problems[#problems + 1] = "layout browser: " .. tostring(errB) end
if LC_CL.LayoutCount("dealer") ~= 1 or LC_CL.LayoutCount("inspect") ~= nil then problems[#problems + 1] = "layout counts" end
panel.next = 0 -- (every control is this one mock panel, so their Think functions chain; a real number, not the mock's catch-all)
local okT, errT = pcall(function() if panel.Think then panel:Think() end if panel.Paint then panel:Paint(200, 24) end end)
if not okT then problems[#problems + 1] = "layout browser row: " .. tostring(errT) end
LC_CL.highlight = { dealer = true }
run("HUDPaint")
LC_CL.highlight = {}
-- the infestation, up close (cl_livingcity_infest.lua): haze, the geiger counter, stains on the ground
local decals = 0
util.DecalEx = function() decals = decals + 1 end
local traceWas = util.TraceLine
util.TraceLine = function(t) return { Hit = true, HitWorld = true, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), Fraction = 0.5 } end
LC_CL.territory = { { kind = "infest", pos = _me:GetPos(), r = 600 } }
local okI, errI = pcall(function()
    for _ = 1, 6 do _advance(0.6) run("Think") end
    if LC_CL.StainZone(LC_CL.territory[1]) < 1 or decals < 1 then error("no stains on the ground") end
    if (LC_CL.InfestHaze or 0) <= 0 then error("no haze") end
    -- it thickens gradually walking in: many levels, never down, full in the middle
    local c, last, levels, seen = _me:GetPos(), 0, 0, {}
    for d = 1200, 0, -50 do
        local v = LC_CL.InfestDepth(c + Vector(d, 0, 0))
        if v < last - 1e-6 then error("haze thins walking in, at " .. d) end
        if v - last > 0.3 then error("haze jumps at " .. d .. " (" .. last .. " to " .. v .. ")") end
        local k = math.floor(v * 100 + 0.5)
        if not seen[k] then seen[k] = true levels = levels + 1 end
        last = v
    end
    if last < 0.99 or levels < 8 then error("haze steps: " .. levels .. " levels, " .. last .. " in the middle") end
end)
if not okI then problems[#problems + 1] = "infestation: " .. tostring(errI) end
run("SetupWorldFog")
util.TraceLine = traceWas
LC_CL.territory = {}
-- checkpoint cables (cl_livingcity_checkpoints.lua)
local bank = ents.Create("lc_powerbank") bank:SetPos(_me:GetPos() + Vector(200, 0, 0))
local tur = ents.Create("npc_turret_floor") tur:SetPos(_me:GetPos() + Vector(100, 0, 0))
tur:SetNW2Entity("lc_cable", bank)
local beamsWas = _calls["render.AddBeam"] or 0
run("PostDrawOpaqueRenderables")
if (_calls["render.AddBeam"] or 0) <= beamsWas then problems[#problems + 1] = "no checkpoint cable drawn" end
-- the actions menu (hold C)
local opts = 0
local mm
mm = setmetatable({}, { __index = function(t, k)
    if k == "AddSubMenu" then return function() return mm, mm end end
    if k == "AddOption" then return function() opts = opts + 1 return mm end end
    if k == "IsValid" then return function() return false end end
    return function() return mm end
end })
DermaMenu = function() return mm end
-- a Union worker: asking for an escort (sv_livingcity_escort.lua)
_me.nw.lcj_job = "maintenance"
local okW, errW = pcall(LC_CL.OpenActions)
if not okW then problems[#problems + 1] = "actions menu (worker): " .. tostring(errW) end
LC_CL.OpenActions() -- (closes it)
_me.nw.lc_escort_phase = "with"
okW, errW = pcall(LC_CL.OpenActions)
if not okW then problems[#problems + 1] = "actions menu (escorted): " .. tostring(errW) end
LC_CL.OpenActions()
-- the escort line on the HUD, in each of its states
for _, ph in ipairs({ "coming", "with", "out", "unattended" }) do
    _me.nw.lc_escort_phase, _me.nw.lc_escort_name, _me.nw.lc_escort_grace = ph, "Unit 47", CurTime() + 30
    run("HUDPaint")
end
_me.nw.lc_escort_phase, _me.nw.lc_escort_name, _me.nw.lc_escort_grace = nil, nil, nil
-- a unit, with an escort request in their menu
_me.nw.lc_escort_wait = true
opts = 0
_me.nw.lcf_faction, _me.nw.lc_unit, _me.nw.lc_interrogated = "cp", true, true
local okM, errM = pcall(LC_CL.OpenActions)
if not okM then problems[#problems + 1] = "actions menu: " .. tostring(errM) end
if opts < 10 then problems[#problems + 1] = "actions menu has only " .. opts .. " options" end
_me.nw.lcf_faction, _me.nw.lc_unit, _me.nw.lc_interrogated = nil, nil, nil
_me.nw.lc_escort_wait, _me.nw.lcj_job = nil, nil
-- the Resistance see a sympathizer's lambda (in clear sight)
_me.nw.lcf_faction = "resistance"
local sy = ents.Create("npc_citizen") sy:SetPos(Vector(150, 0, 0)) sy.nw.lc_prebel, sy.nw.lc_pjob = true, "Union Worker"
local tlWas = util.TraceLine
util.TraceLine = function(t) return { Hit = false, HitPos = t.endpos, Fraction = 1 } end
_calls["surface.DrawLine"] = 0
_advance(1)
run("HUDPaint")
util.TraceLine = tlWas
if (_calls["surface.DrawLine"] or 0) == 0 then problems[#problems + 1] = "no sympathizer lambda drawn" end
sy:Remove()
_me.nw.lcf_faction = nil
local sections = LC_GuideSections(true)
if sections[#sections][1] ~= "Admin" or #sections < 10 then problems[#problems + 1] = "guide sections" end
return table.concat(problems, "\n")
""")
if more:
    problems = (problems + "\n" if problems else "") + more

# the client half of the city's own entities: set up, drawn, thought, removed
ENTDIR = os.path.join(GMDIR, "entities", "entities")
for name in sorted(f[:-4] for f in os.listdir(ENTDIR) if f.endswith(".lua")):
    L.globals()._SRC = open(os.path.join(ENTDIR, name + ".lua")).read()
    L.globals()._ENTNAME = name
    err = L.execute(r"""
    ENT = {}
    local ok, err = pcall(function() assert(loadstring(_SRC, _ENTNAME))() end)
    if not ok then return "load: " .. tostring(err) end
    local def = ENT
    local e = ents.Create(_ENTNAME)
    e:SetPos(Vector(200, 0, 0))
    -- the entity with its script's methods on it (the harness's entities don't carry them)
    local inst = setmetatable({}, { __index = function(t, k)
        if def[k] ~= nil then return def[k] end
        local m = e[k]
        if type(m) == "function" then return function(self, ...) return m(e, ...) end end
        if m ~= nil then return m end
        if k:match("^%u") then return function() end end -- (an engine method the harness doesn't have; fields stay nil)
    end })
    for _, fn in ipairs({ "Initialize", "Draw", "DrawTranslucent", "Think", "OnRemove" }) do
        if def[fn] then
            local ok2, err2 = pcall(def[fn], inst)
            if not ok2 then return fn .. ": " .. tostring(err2) end
        end
    end
    return nil
    """)
    if err:
        problems = (problems + "\n" if problems else "") + name + " (client) " + str(err)
# the city's music: a real sound channel is userdata (it can't carry fields of its own)
err = L.execute(r"""
local realExists, realValid = file.Exists, IsValid
file.Exists = function(p) if string.sub(p or "", 1, 6) == "sound/" then return true end return realExists(p) end
IsValid = function(x) if type(x) == "userdata" then return true end return realValid(x) end
sound = sound or {}
local played = 0
sound.PlayFile = function(path, flags, cb)
    local ch = newproxy(true)
    local mt = getmetatable(ch)
    local vol = 0
    mt.__index = function(_, k)
        if k == "GetVolume" then return function() return vol end end
        if k == "SetVolume" then return function(_, v) vol = v end end
        if k == "GetState" then return function() return 1 end end
        if k == "Play" then return function() played = played + 1 end end
        return function() end
    end
    mt.__newindex = function() error("attempt to index a sound channel (a userdata value)") end
    cb(ch)
end
GMOD_CHANNEL_STOPPED = 0
local ok, e = pcall(function()
    for _ = 1, 40 do _advance(5) _runtimers() end
end)
file.Exists, IsValid = realExists, realValid
if not ok then return "music: " .. tostring(e) end
if played == 0 then return "music: nothing ever played" end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)

# graffiti uses the game's own lambda sprays; apartment door labels and the rent popup
err = L.execute(r"""
local painted, removed = 0, 0
util.DecalEx = function() painted = painted + 1 end
util.RemoveDecalsAt = function() removed = removed + 1 end
LC_CL.LambdaMats()
local function tag(x) return { x = x, y = 0, z = 50, nx = 0, ny = 0, nz = 1 } end
LC_CL.SetTags({ tag(100), tag(200) })
for _ = 1, 3 do _advance(1.1) _runtimers() end
if painted ~= 2 then return "graffiti: expected 2 decals, got " .. painted end
for _ = 1, 3 do _advance(1.1) _runtimers() end
if painted ~= 2 then return "graffiti: repainted without cause (" .. painted .. ")" end
LC_CL.SetTags({ tag(100) })
if removed < 1 then return "graffiti: a removed tag did not come off the wall" end
local before = _calls["cam.Start3D2D"] or 0
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
if (_calls["cam.Start3D2D"] or 0) ~= before then return "graffiti: drew a letter while real decals exist" end

-- the door label
local door = ents.Create("prop_door_rotating")
door:SetNW2String("lc_rent", "A:40:3")
local a, b, c = LC_CL.RentLines(door, LocalPlayer())
if not (a and string.find(a, "available") and string.find(b, "40 credits")) then return "rent label: free door says " .. tostring(a) end
door:SetNW2String("lc_rent", "O:Pat Smith")
a = LC_CL.RentLines(door, LocalPlayer())
if not (a and string.find(a, "Pat Smith")) then return "rent label: owned door says " .. tostring(a) end
if LC_CL.RentLines(ents.Create("prop_physics"), LocalPlayer()) then return "rent label on a plain prop" end
-- the yes or no
local asked = 0
Derma_Query = function(text, title, yes, yf, no) asked = asked + 1 if not string.find(text, "40 credits") then error("popup missing price") end end
local qd = { door, 40, 3 }
local rE, rU, rF = net.ReadEntity, net.ReadUInt, net.ReadFloat
net.ReadEntity = function() return qd[1] end
net.ReadUInt = function() return qd[2] end
net.ReadFloat = function() return qd[3] end
net.recv_lc_rent_ask()
net.ReadEntity, net.ReadUInt, net.ReadFloat = rE, rU, rF
if asked ~= 1 or not LC_CL.RentAskLast then return "rent popup did not open" end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)
print(problems or "no client errors")
print("zone fills drawn:", filled, "thick edges drawn:", beams)
ok = not problems and filled >= 2 and beams > 0
print("CLIENT SMOKE", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
