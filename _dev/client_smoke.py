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
_me.nw.lcf_faction, _me.nw.lcf_rank, _me.nw.lcf_xp = "cp", 2, 300
run("HUDPaint")
_me.nw.lcf_xp = 325
run("HUDPaint")
local frac, label, col, gain = LC_CL.XPInfo()
if not (frac and math.abs(frac - 175 / 450) < 0.01) then problems[#problems + 1] = "xp bar fraction " .. tostring(frac) end
if label ~= "Metrocop   325 / 600 XP" then problems[#problems + 1] = "xp label " .. tostring(label) end
if gain ~= "+25 XP" then problems[#problems + 1] = "xp gain " .. tostring(gain) end
_me.nw.lcf_rank, _me.nw.lcf_xp = 3, 900
frac, label = LC_CL.XPInfo()
if not (label and string.find(label, "needs the Overwatch conditioning", 1, true)) then problems[#problems + 1] = "division leader " .. tostring(label) end
_me.nw.lcf_rank, _me.nw.lcf_xp, _me.nw.lcf_transhuman = 6, 4100, true
frac, label = LC_CL.XPInfo()
if label ~= "Elite Soldier   4100 XP (top rank)" or frac ~= 1 then problems[#problems + 1] = "top rank " .. tostring(label) end
_me.nw.lcf_transhuman = nil
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
-- the faction screen, with Civil Protection's requirements as progress bars
util.JSONToTable = function() return { current = "citizen", special = "", factions = { { id = "cp", xp = 0, rank = 1, ok = false, why = "Not yet", specials = {},
    reqs = { { label = "Civil Standing", have = 40, need = 100 }, { label = "Records Clerk shifts finished", have = 2, need = 5 } } } } } end
okP, errP = pcall(net["recv_lcf_menu"])
if not okP then problems[#problems + 1] = "faction screen: " .. tostring(errP) end
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
-- asleep in a bed: lying on it, and the camera at the head on the pillow
_me.nw.lc_sleeping = true
_me.nw.lc_bed_top = Vector(100, 0, 20)
_me.nw.lc_bed_yaw = 90
_me.SetRenderOrigin = function(self, v) self.ro = v end
_me.SetRenderAngles = function(self, a) self.ra = a end
_me.LookupBone = function(self, n) return n == "ValveBiped.Bip01_Head1" and 6 or 0 end
_me.GetBonePosition = function(self, b) local o = self.ro or Vector(0, 0, 0) return o + (b == 6 and Vector(0, 30, 4) or Vector(0, 2, 4)) end
for _ = 1, 3 do run("PrePlayerDraw", _me) run("PostPlayerDraw", _me) end
local bedv = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(), fov = 75 })
if not bedv or bedv.origin:Distance(Vector(100, 0, 20)) > 60 or bedv.drawviewer then problems[#problems + 1] = "asleep in a bed: the camera isn't on the pillow: " .. tostring(bedv and bedv.origin) end
if not _me.ra or _me.ra.y ~= 90 then problems[#problems + 1] = "asleep in a bed: not turned along it" end
if _me.ro ~= nil then problems[#problems + 1] = "asleep in a bed: the drawing spot isn't put back after drawing" end
_me.nw.lc_sleeping = false
_me.SetRenderOrigin, _me.SetRenderAngles, _me.LookupBone, _me.GetBonePosition = nil, nil, nil, nil
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
-- running: a grown-up's stride, about 3 steps a second (not a toddler's 4 or 5)
_me.vel = Vector(190, 0, 0)
_me.ground = true
for _ = 1, 4 do _advance(0.05) LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 }) end
local ph0 = LC_CL.Bob.phase
for _ = 1, 10 do _advance(0.05) LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 }) end
local adv = (LC_CL.Bob.phase - ph0) % (math.pi * 2)
local stepsPerSec = adv / math.pi / 0.5
if stepsPerSec > 3.4 or stepsPerSec < 2.4 then problems[#problems + 1] = "running steps per second: " .. tostring(stepsPerSec) end
_me.vel = Vector(0, 0, 0)
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
-- the camera looks where you look, not where the scanner's body has tipped to
local tipped = LC_CL.CalcView(_me, { origin = Vector(0, 0, 64), angles = Angle(-80, 30, 45), fov = 75 })
local eyeA = _me:EyeAngles()
if not tipped or math.abs(tipped.angles.r) > 0.01 or math.abs(tipped.angles.p - eyeA.p) > 0.01 then problems[#problems + 1] = "the scanner camera tips and rolls with the scanner's body" end
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
        LC_CL.Insider = faction == "cp" -- (the Resistance's man inside: their own menu)
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
    Run("vort", false, function() Look(nil) end)
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
        local base = { name = "Erika Hollis", cid = "#63-501", credits = 30, standing = 10, papersFee = 10, good = 50,
            blocks = { { n = 1, name = "Habitation Block 01", residents = 2, m = 40 }, { n = 2, name = "Habitation Block 02", residents = 6 } } }
        local function With(t) local o = table.Copy and table.Copy(base) or {} for k, v in pairs(base) do o[k] = v end for k, v in pairs(t) do o[k] = v end return o end
        LC_CL.OpenDesk(With({ kind = "register", papers = false, cards = 2, awaiting = true, housingDesk = true }))
        LC_CL.OpenDesk(With({ kind = "housing", pending = true }))
        LC_CL.OpenDesk(With({ kind = "housing", awaiting = true, papers = true }))
        LC_CL.OpenDesk(With({ kind = "housing", block = 2, blockName = "Habitation Block 02", how = "auto", transfer = true, papers = true }))
        LC_CL.OpenDesk(With({ kind = "housing", block = 2, blockName = "Habitation Block 02", how = "allocation", transfer = false, transferWhy = "Too soon." }))
        LC_CL.OpenLab({ credits = 50, items = { { id = "gun_pistol", name = "Homemade pistol", desc = "A pistol", secs = 12, price = 72, canPay = false, canMats = true,
            mats = { { name = "Gun parts", have = 2, need = 2 } } } } })
        LC_CL.OpenLab({ credits = 0, busy = 5, items = {} })
        LC_CL.ShowPapersCard({ name = "Erika Hollis", cid = "#63-501", block = "Habitation Block 02", desc = "tall, grey coat", cards = 3, from = true, stalker = true })
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
    -- a terminal's menu on its own screen: the crosshair is the cursor, E presses
    local okS, errS = pcall(function()
        local term = ents.Create("lc_intake") term:SetPos(_me:GetPos() + Vector(60, 0, 0))
        local pressed = false
        if not LC_CL.ScreenOpen(term, "TEST", "sub", { { kind = "head", text = "Head" }, { kind = "button", text = "Press me", fn = function() pressed = true end } }) then error("didn't open") end
        local aim = LC_CL.ScreenAim
        LC_CL.ScreenAim = function() return 100, 46 + 26 + 5 end -- (on the second row: the button)
        for id, fn in pairs(hook.t.Think or {}) do if id == "LivingCityScreens" then fn() end end
        for id, fn in pairs(hook.t.PostDrawTranslucentRenderables or {}) do if id == "LivingCityScreens" then fn(false, false) end end
        local swallowed = hook.t.PlayerBindPress.LivingCityScreens(_me, "+use", true)
        if not pressed or swallowed ~= true then error("E on the button didn't press it") end
        -- the Close button at the bottom lights up when it's aimed at (it never did: made anew each layout)
        LC_CL.ScreenOpen(term, "TEST", "sub", { { kind = "head", text = "Head" }, { kind = "button", text = "Press me", fn = function() end } })
        LC_CL.ScreenAim = function() return 100, 46 + 26 * 2 + 6 + 5 end
        for id, fn in pairs(hook.t.Think or {}) do if id == "LivingCityScreens" then fn() end end
        if LC_CL.ScreenState().hover ~= 46 + 26 * 2 + 6 then error("the Close button didn't light up when aimed at: " .. tostring(LC_CL.ScreenState().hover)) end
        LC_CL.ScreenAim = aim
        LC_CL.ScreenClose()
        LC_CL.OpenDesk({ kind = "housing", awaiting = true, papers = true, blocks = { { n = 1, name = "Block 1", residents = 2 } } })
        if not LC_CL.ScreenState() then error("Housing Allocation didn't open on its screen") end
        LC_CL.ScreenClose()
        term:Remove()
    end)
    if not okS then problems[#problems + 1] = "terminal screens: " .. tostring(errS) end
    -- every chat command, and where it is now
    local WHERE = {
        ["!handsup"] = "handsup", ["!holster"] = "holster", ["!surrender"] = "surrender", ["!struggle"] = "struggle", ["!stuck"] = "stuck",
        ["!stash"] = "stash", ["!fish"] = "fish", ["!salvage"] = "salvage", ["!donate"] = "donate", ["!plain"] = "plain", ["!gearup"] = "gearup",
        ["!recognize"] = "recognize", ["!tie"] = "tie", ["!untie"] = "untie", ["!drag"] = "drag", ["!search"] = "search", ["!backup"] = "backup",
        ["!10-20"] = "10-20", ["!records"] = "records", ["!vo"] = "vo", ["!unshackle"] = "unshackle", ["!decode"] = "decode",
        ["!foreman"] = "foreman", ["!assign"] = "assign", ["!rent"] = "rent", ["!pick"] = "pick", ["!hack"] = "hack", ["!hijack"] = "hijack",
        ["!inform"] = "inform", ["/request"] = "request", ["!r"] = "r", ["!unlink"] = "unlink", ["!cuff"] = "tie", ["!uncuff"] = "untie",
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
        ["!vortcall"] = "vortcall", ["!tipoff"] = "tipoff", ["!loserecord"] = "loserecord", ["!skim"] = "skim", ["!copyrecords"] = "copyrecords", ["!reveal"] = "reveal",
        ["!foulfilters"] = "foulfilters", ["!spikefood"] = "spikefood",
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
-- (and arranged by what it's for: rebels, prison, each job)
local arr = GetConVar("lc_editor_arrange")
if arr then arr.v = "use" end
local okU, errU = pcall(LC_CL.BuildLayoutBrowser, panel, { { id = "dealer", label = "Fixture: black market dealer" },
    { id = "zone_rebel", label = "Zone: rebel territory" }, { id = "work_factory", label = "Workplace: Factory" }, { id = "conveyor", label = "Fixture: factory conveyor" } })
if not okU then problems[#problems + 1] = "layout browser, by use: " .. tostring(errU) end
if arr then arr.v = "type" end
panel.next = 0 -- (every control is this one mock panel, so their Think functions chain; a real number, not the mock's catch-all)
local okT, errT = pcall(function() if panel.Think then panel:Think() end if panel.Paint then panel:Paint(200, 24) end end)
if not okT then problems[#problems + 1] = "layout browser row: " .. tostring(errT) end
LC_CL.highlight = { dealer = true }
run("HUDPaint")
LC_CL.highlight = {}
-- the job games (cl_livingcity_jobgames.lua): the panel, the papers window, its buttons
local okJG, errJG = pcall(function()
    local rS, rJ = net.ReadString, util.JSONToTable
    local doc = { papers = { name = "Anya Vasek", cid = "12-345", model = "models/Humans/Group01/male_02.mdl",
        district = "District 4", expires = 230, permit = true, union = false, purpose = "Work", seal = "0CS" },
        rules = { "Papers must be in date.", "No entry from District 9." }, today = 214, n = 2, of = 5 }
    net.ReadString = function() return "x" end
    util.JSONToTable = function() return doc end
    net.recv_lc_papers_check()
    net.ReadString, util.JSONToTable = rS, rJ
    run("HUDPaint")
    LC_CL.PapersDecide("deny")
    -- the wiring board: opened, a turn (and a spark's bite), drawn, closed
    local rS2, rJ2 = net.ReadString, util.JSONToTable
    local wdoc = { w = 5, h = 4, tiles = { 5, 3, 7, 10, 12, 5, 6, 9, 3, 10, 12, 5, 6, 9, 3, 10, 12, 5, 6, 9 }, feed = 2, lamp = 3,
        lit = { 6, 7 }, sparks = { 4, 15 }, turns = 0, par = 7, shocks = 0, secs = 55, what = "the box" }
    net.ReadString = function() return "x" end
    util.JSONToTable = function() return wdoc end
    net.recv_lc_wire_open()
    local ws = LC_CL.WireState()
    if not ws or ws.w ~= 5 or not ws.lit[6] or not ws.sparks[15] then error("no wiring board") end
    local fr = ws.frame
    wdoc = { w = 5, h = 4, tiles = wdoc.tiles, feed = 2, lamp = 3, lit = { 6, 7, 8 }, sparks = { 1 }, zap = 4, turns = 1, par = 7, shocks = 1, secs = 50 }
    net.recv_lc_wire_open()
    ws = LC_CL.WireState()
    if ws.frame ~= fr or ws.turns ~= 1 or not ws.lit[8] or not ws.zap or ws.zap.k ~= 4 then error("board didn't update in place") end
    if fr.PaintOver then fr.PaintOver(fr, 420, 400) end
    if fr.Paint then fr.Paint(fr, 64, 64) end
    if fr.DoClick then fr.DoClick() end
    if fr.DoRightClick then fr.DoRightClick() end
    wdoc = {}
    net.recv_lc_wire_open()
    if LC_CL.WireState() then error("wiring board didn't close") end
    net.ReadString, util.JSONToTable = rS2, rJ2
end)
if not okJG then problems[#problems + 1] = "job games: " .. tostring(errJG) end
-- 20 October: the eyelids shut all the way; how long a voice runs; the rank card; subtitles under
-- a window; the screws turned round; a setting "changed" only when it really has
local okOct, errOct = pcall(function()
    local most = 0
    for i = 0, 70 do most = math.max(most, LC_CL.EyelidClose(i / 10)) end
    if most < 0.99 then error("the eyelids don't shut all the way: " .. most) end
    if LC_CL.VoiceSecs("x.mp3", 7, 4) ~= 7 or LC_CL.VoiceSecs("x.mp3", 0, 4) ~= 4 then error("voice length") end
    local was = _me.GetNW2String
    _me.GetNW2String = function(self, k, d) if k == "lcf_faction" then return "resistance" end return was(self, k, d) end
    if not LC_CL.RankCard(_me, 16, 160, 340) then error("no rank card for a Resistance member") end
    _me.GetNW2String = function(self, k, d) if k == "lcf_faction" then return "citizen" end return was(self, k, d) end
    if LC_CL.RankCard(_me, 16, 160, 340) then error("a rank card for a plain citizen") end
    _me.GetNW2String = was
    if type(LC_CL.SubsY(1920, 1080, 2)) ~= "number" then error("subtitle height") end
    if not LC_CL.EndingSameValue("0.360000", "0.36") or LC_CL.EndingSameValue("0.4", "0.36") or not LC_CL.EndingSameValue("12.2:ignite,60.2:hop", "12.2:ignite,60.2:hop") then error("ending settings compared wrong") end
    if not LC_CL.EndingCombineBody({ GetModel = function() return "models/player/police.mdl" end }) then error("a metrocop isn't a Combine body") end
end)
if not okOct then problems[#problems + 1] = "20 October: " .. tostring(errOct) end
-- the other job games (cl_livingcity_moregames.lua): every panel opened, updated, closed
local okMG, errMG = pcall(function()
    local rU, rD, rDc, rJ = net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable
    local doc
    net.ReadUInt = function() return 1 end
    net.ReadData = function() return "x" end
    util.Decompress = function(s) return s end
    util.JSONToTable = function() return doc end
    local tj0 = util.TableToJSON
    util.TableToJSON = util.TableToJSON or function() return "{}" end
    local docs = {
        { kind = "hack", band = 0.3, w = 0.2, speed = 0.5, t = 1, got = 1, need = 4, alarms = 1, sweep = true, warn = false },
        { kind = "search", n = 1, of = 3, watching = true, pockets = { { name = "Coat", open = true, find = "Papers" }, { name = "Shoes", open = false }, { name = "Lining", open = true, done = "empty" } } },
        { kind = "laundry", bins = { { label = "UNION / JURY" }, { label = "KING / TAP" }, { label = "Incident wash" } }, tag = "UNION-07", stain = true, pocket = "a folded note", n = 1, of = 12, secs = 90 },
        { kind = "filing", drawers = { "00-24", "25-49", "50-74", "75-99", "Discrepancy" }, name = "Mira Kesler", cid = "12-345", status = "Active", regName = "Mira Kessler", regCid = "12-345", n = 1, of = 10, secs = 100, blank = true },
        { kind = "radio", n = 1, of = 4, t = 95.5, f7 = 101.2, heard = "'...this is Freq 7...'", secs = 20, screws = { 0.3, 0.6, 0.5 }, turn = { 0.9, 0.1, 0.1 }, names = { "Volume trimmer", "Squelch", "Alignment" } },
        { kind = "parcel", text = "A heavy box. You ask what's in it. 'Don't ask. Just get it there.'", choices = { "take", "refuse", "report", "open" } },
        { kind = "parcel", text = "You slit the tape and look. Inside: pistol rounds.", choices = { "take", "refuse", "report" }, opened = true },
        { kind = "patdown", zones = { { name = "Coat", done = true }, { name = "Bag", done = true, found = "a lockpick" }, { name = "Boots", done = false } }, tell = "They hold the bag tight.", nerve = 2, found = "a lockpick", n = 1, of = 3 },
    }
    for _, d in ipairs(docs) do
        doc = d
        net.recv_lc_jg_panel()
        if not LC_CL.JobPanel() or LC_CL.JobPanel().kind ~= d.kind then error("no " .. d.kind .. " panel") end
        net.recv_lc_jg_panel() -- (an update to the same panel)
    end
    -- a set's screws: off, the station is faint and the hiss stays; set right, it's clean
    local good = { t = 95.5, screws = { 0.5, 0.5, 0.5 }, turn = { 0.5, 0.5, 0.5 } }
    local bad = { t = 95.5, screws = { 0.5, 0.5, 0.5 }, turn = { 0.95, 0.05, 0.9 } }
    local gs, gu = LC_CL.RadioMix(95.5, good)
    local bs, bu = LC_CL.RadioMix(95.5, bad)
    if not (gu > 0.95 and gs < 0.2 and bu < 0.3 and bs > 0.6) then error("radio screws " .. gs .. " " .. gu .. " " .. bs .. " " .. bu) end
    -- the radio mixes: static between stations, the station fading in through it, overlapping
    local vs, vu = LC_CL.RadioMix(95.5, { t = 95.5 })
    local fs, fu = LC_CL.RadioMix(80, { t = 95.5 })
    local ms, mu = LC_CL.RadioMix(96.5, { t = 95.5 })
    if not (vu > 0.95 and vs < 0.2 and fu < 0.01 and fs > 0.95 and mu > 0.3 and ms > 0.3) then error("radio mix " .. vs .. " " .. vu .. " " .. ms .. " " .. mu) end
    local hs, hu, h7 = LC_CL.RadioMix(80, { t = 95.5, f7 = 101, heard = "x" })
    if h7 ~= 1 or hu ~= 0 then error("freq 7 not up once locked") end
    doc = {}
    net.recv_lc_jg_panel()
    if LC_CL.JobPanel() then error("panel didn't close") end
    LC_CL.JobAct("try", 0.5)
    -- a set being tuned nearby: heard close up, quieter further off, silent past twenty feet
    if LC_CL.RadioFalloff(0) ~= 1 or LC_CL.RadioFalloff(140) <= 0 or LC_CL.RadioFalloff(140) >= 0.5 or LC_CL.RadioFalloff(260) ~= 0 then error("radio falloff") end
    doc = { e = _me:EntIndex(), dial = 95.4, t = 95.5, f7 = 101, heard = false, static = "x/static.wav", union = "x/union.wav" }
    net.recv_lc_radio_bench()
    if not LC_CL.RadioBenches()[_me:EntIndex()] then error("no bench") end
    run("Think")
    doc = { e = _me:EntIndex(), off = true }
    net.recv_lc_radio_bench()
    if LC_CL.RadioBenches()[_me:EntIndex()] then error("bench didn't stop") end
    util.TableToJSON = tj0
    net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable = rU, rD, rDc, rJ
    run("PreDrawHalos")
end)
if not okMG then problems[#problems + 1] = "more job games: " .. tostring(errMG) end
-- what now? (cl_livingcity_nextstep.lua): the line on screen, and its F1 page
local okWN, errWN = pcall(function()
    _me:SetNW2String("lc_next", "Find water")
    _me:SetNW2String("lc_next_why", "You're thirsty. A sink or a water machine: press E on it.")
    _me:SetNW2String("lc_next_way", "water")
    _me:SetNW2Bool("lc_next_urgent", true)
    local s = LC_CL.NextStep()
    if not s or s.text ~= "Find water" or not s.urgent then error("next step not read") end
    run("HUDPaint")
    local page = LC_CL.WhatNowPage()
    if not page or #page.items < 3 then error("no what-now page") end
    page.items[1].run()
    local places = LC_CL.PlacesPage()
    if #places.items < 6 then error("too few places") end
    for _, it in ipairs(places.items) do
        if it.run then it.run() elseif it.page then for _, x in ipairs(it.page().items) do x.run() end end
    end
    _me:SetNW2String("lc_next", "")
end)
if not okWN then problems[#problems + 1] = "what now: " .. tostring(errWN) end
-- the lag monitor (cl_livingcity_lagwatch.lua): on, a few seconds of it, the panel, the printout, off
local okLW, errLW = pcall(function()
    LC_CL.SetLagWatch(true)
    if not LC_CL.LagWatchOn() then error("didn't turn on") end
    for _ = 1, 3 do run("Think") _advance(1.1) _runtimers() end
    if not LC_CL.LagWatchRow then error("no row measured") end
    run("HUDPaint")
    concommand.list.lc_lagwatch_print(nil)
    LC_CL.SetLagWatch(false)
end)
if not okLW then problems[#problems + 1] = "lag monitor: " .. tostring(errLW) end
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
    local blocked = util.TraceLine
    util.TraceLine = function(t) return { Hit = false, HitPos = t.endpos, Fraction = 1 } end
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
    if LC_CL.InfestDepth(c + Vector(0, 0, -400)) > 0 then error("haze felt in the tunnel under the zone") end
    util.TraceLine = blocked
    if LC_CL.InfestDepth(c + Vector(800, 0, 0)) > 0 then error("haze felt through a wall") end
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
# the radio held up (a weapon, next to Hands): drawn in your view and in your hand, and the soft static
L.globals()._SRC = open(os.path.join(GMDIR, "entities", "weapons", "weapon_lc_radio.lua")).read()
err = L.execute(r"""
SWEP = {}
local ok, err = pcall(function() assert(loadstring(_SRC, "weapon_lc_radio"))() end)
if not ok then return "load: " .. tostring(err) end
local def = SWEP
local w = ents.Create("weapon_lc_radio")
w.nw = w.nw or {}
w.nw.lc_band, w.nw.lc_static = "resistance", "livingcity/radio/static.mp3"
local inst = setmetatable({}, { __index = function(t, k)
    if def[k] ~= nil then return def[k] end
    local m = w[k]
    if type(m) == "function" then return function(self, ...) return m(w, ...) end end
    if m ~= nil then return m end
    if k:match("^%u") then return function() end end
end })
w.GetOwner = function() return _me end
w.GetClass = function() return "weapon_lc_radio" end
for _, fn in ipairs({ "Initialize", "DrawHUD", "DrawWorldModel", "OnRemove" }) do
    if def[fn] then
        local ok2, err2 = pcall(def[fn], inst)
        if not ok2 then return fn .. ": " .. tostring(err2) end
    end
end
local gaw = _me.GetActiveWeapon
_me.GetActiveWeapon = function() return w end
local okT, errT = pcall(hook.t.Think.LivingCityRadioStatic)
_me.GetActiveWeapon = gaw
if not okT then return "static: " .. tostring(errT) end
pcall(hook.t.Think.LivingCityRadioStatic)
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "weapon_lc_radio (client) " + str(err)
# the cleanup crew's hoover: drawn in your view and in your hand, and its HUD
L.globals()._SRC = open(os.path.join(GMDIR, "entities", "weapons", "weapon_lc_hoover.lua")).read()
err = L.execute(r"""
SWEP = {}
local ok, err = pcall(function() assert(loadstring(_SRC, "weapon_lc_hoover"))() end)
if not ok then return "load: " .. tostring(err) end
local def = SWEP
local w = ents.Create("weapon_lc_hoover")
local inst = setmetatable({}, { __index = function(t, k)
    if def[k] ~= nil then return def[k] end
    local m = w[k]
    if type(m) == "function" then return function(self, ...) return m(w, ...) end end
    if m ~= nil then return m end
    if k:match("^%u") then return function() end end
end })
w.GetOwner = function() return _me end
local cmWas, drawn = ClientsideModel, 0
ClientsideModel = function() return { IsValid = function() return true end, SetNoDraw = function() end, SetPos = function() end,
    SetAngles = function() end, DrawModel = function() drawn = drawn + 1 end, Remove = function() end } end
for _, fn in ipairs({ "Initialize", "PreDrawViewModel", "PostDrawViewModel", "DrawWorldModel", "DrawHUD", "OnRemove" }) do
    if def[fn] then
        local ok2, err2 = pcall(def[fn], inst)
        if not ok2 then ClientsideModel = cmWas return fn .. ": " .. tostring(err2) end
    end
end
ClientsideModel = cmWas
if drawn < 2 then return "the hoover wasn't drawn (in view and in hand): " .. drawn end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "weapon_lc_hoover (client) " + str(err)
# the weedkiller sprayer: drawn in your view and in your hand, and its HUD
L.globals()._SRC = open(os.path.join(GMDIR, "entities", "weapons", "weapon_lc_sprayer.lua")).read()
err = L.execute(r"""
SWEP = {}
local ok, err = pcall(function() assert(loadstring(_SRC, "weapon_lc_sprayer"))() end)
if not ok then return "load: " .. tostring(err) end
local def = SWEP
local w = ents.Create("weapon_lc_sprayer")
local inst = setmetatable({}, { __index = function(t, k)
    if def[k] ~= nil then return def[k] end
    local m = w[k]
    if type(m) == "function" then return function(self, ...) return m(w, ...) end end
    if m ~= nil then return m end
    if k:match("^%u") then return function() end end
end })
w.GetOwner = function() return _me end
local cmWas, drawn = ClientsideModel, 0
ClientsideModel = function() return { IsValid = function() return true end, SetNoDraw = function() end, SetPos = function() end,
    SetAngles = function() end, DrawModel = function() drawn = drawn + 1 end, Remove = function() end } end
for _, fn in ipairs({ "Initialize", "PostDrawViewModel", "DrawWorldModel", "DrawHUD", "OnRemove" }) do
    if def[fn] then
        local ok2, err2 = pcall(def[fn], inst)
        if not ok2 then ClientsideModel = cmWas return fn .. ": " .. tostring(err2) end
    end
end
ClientsideModel = cmWas
if drawn < 2 then return "the sprayer wasn't drawn (in view and in hand): " .. drawn end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "weapon_lc_sprayer (client) " + str(err)
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
-- morning exercise: the jog, the drill (a cue, the rope, leading), the parade
local function paint()
    for _, h in pairs(hook.t["HUDPaint"] or {}) do h() end
    for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
    for _, h in pairs(hook.t["Think"] or {}) do h() end
end
local function pop() return table.remove(net._q, 1) end
net.ReadString, net.ReadFloat, net.ReadTable, net.ReadUInt = pop, pop, pop, pop
net.ReadBool = function() return table.remove(net._q, 1) == true end
local route = { Vector(0, 0, 0), Vector(1000, 0, 0), Vector(1000, 1000, 0) }
_me.nw.lcf_faction = "citizen"
net._q = { "jog", "muster", CurTime() + 60, CurTime() + 400, { center = route[1], route = route, pace = 150, runStart = 0, total = 2000 } }
net.recv_lc_exercise()
if not LC_CL.Exercise() or LC_CL.Exercise().kind ~= "jog" then return "exercise: state not received" end
paint()
_me.nw.lcx_in = true
paint()
net._q = { "jog", "run", CurTime() - 1, CurTime() + 400, { center = route[1], route = route, pace = 150, runStart = CurTime() - 3, total = 2000 } }
net.recv_lc_exercise()
_me.nw.lcx_cp, _me.nw.lcx_behind, _me.nw.lcx_boost = 2, true, CurTime() + 3
paint()
_me.nw.lcx_lag = 500 -- (joined late: their own pace marker)
paint()
_me.nw.lcx_lag = nil
_me.nw.lcx_cp = 4
paint()
net._q = { "drill", "run", CurTime() - 1, CurTime() + 400, { center = Vector(0, 0, 0), yard = Vector(0, 0, 0), yardYaw = 90 } }
net.recv_lc_exercise()
_me.nw.lcx_spot, _me.nw.lcx_mistakes = Vector(100, 0, 0), 2
net._q = { "spin", CurTime() + 2.5, false }
net.recv_lc_drill_cue()
paint()
net._q = { CurTime() - 0.2, 0.85, 10 }
net.recv_lc_drill_rope()
paint()
_advance(0.9)
paint()
_me.nw.lcx_leader = true
paint()
_me.nw.lcx_leader = false
net._q = { "parade", "run", CurTime() - 1, CurTime() + 400, { center = route[1], route = route } }
net.recv_lc_exercise()
_me.nw.lcx_cheer = 20
paint()
_me.nw.lcx_in = false
paint()
net._q = { "" }
net.recv_lc_exercise()
if LC_CL.Exercise() ~= nil then return "exercise: not cleared at the end" end
paint()

-- secret endings: time stopped and the vote, the flood, the reset
for _, h in pairs(hook.t["RenderScreenspaceEffects"] or {}) do h() end
net._q = { { id = "water", phase = "gman", name = "The Flood", say = "x", voteEnds = CurTime() + 20, yes = 1, skip = 0,
    lines = { "vo/citadel/gman_exit01.wav" } } }
net.recv_lc_ending()
if not LC_CL.Ending() or LC_CL.Ending().phase ~= "gman" then return "ending: state not received" end
paint()
for _, h in pairs(hook.t["RenderScreenspaceEffects"] or {}) do h() end
local blocked
for _, h in pairs(hook.t["PlayerBindPress"] or {}) do blocked = h(_me, "slot1", true) or blocked end
if not blocked then return "ending: the vote key wasn't taken" end
if not LC_CL.EndingGmanAt() then return "ending: the G-Man wasn't put in front of you" end
local musicT = (timer.list or timer.t or {}).LivingCityMusic
if musicT then
    local ok = pcall(type(musicT) == "table" and musicT.fn or musicT)
    if not ok then return "music: the timer errors while an ending's on" end
end
_advance(1)
local gv = hook.t.CalcView.LivingCityEndingGman(_me, Vector(0, 0, 64), Angle(0, 0, 0), 75)
if not gv or not gv.angles then return "ending: the view doesn't turn to the G-Man" end
local mcmd = { SetMouseX = function() end, SetMouseY = function() end }
if hook.t.InputMouseApply.LivingCityEndingGman(mcmd) ~= true then return "ending: you can still look away from the G-Man" end
paint()
net._q = { { id = "water", phase = "apocalypse", name = "The Flood", say = "x", song = "livingcity/endings/water/song.mp3", grigori = _me } }
net.recv_lc_ending()
_globals.lc_flood_z = 40
paint()
_me.nw.lc_rocking = true
for _, h in pairs(hook.t["MouthMoveAnimation"] or {}) do h(_me) end
net._q = { { id = "bloom", phase = "apocalypse", name = "Bloom", say = "x", song = "livingcity/endings/bloom/bloom.ogg",
    client = { bpm = 165, offset = 0, start = CurTime(), rateAt = CurTime() - 1, rateDur = 2, peak = 1.6, props = { 1 } } } }
net.recv_lc_ending()
_me.nw.lc_dancing = true
for _, h in pairs(hook.t["Think"] or {}) do h() end
_advance(1.2)
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
for _, h in pairs(hook.t["ShouldDrawLocalPlayer"] or {}) do h(_me) end
paint()
for _, h in pairs(hook.t["RenderScreenspaceEffects"] or {}) do h() end
net._q = { { id = "marrow", phase = "apocalypse", name = "Marrow", say = "x", song = "livingcity/endings/marrow/marrow.ogg",
    client = { party = true, lights = true, ambient = true, strobe = true, dance = "rave", danceRate = 1.5, palette = { { 120, 255, 80 }, { 170, 60, 255 } }, bpm = 128, offset = 0, start = CurTime() } } }
net.recv_lc_ending()
_advance(1.1)
for _, h in pairs(hook.t["Think"] or {}) do h() end
paint()
for _, h in pairs(hook.t["RenderScreenspaceEffects"] or {}) do h() end
net._q = { { id = "bus", phase = "apocalypse", name = "The Bus", say = "x", song = "livingcity/endings/bus/bus.ogg",
    client = { party = true, lights = true, strobe = true, dance = "bus", palette = { { 255, 40, 40 }, { 60, 140, 255 } }, bpm = 138, offset = 0, start = CurTime(), bus = 1 } } }
net.recv_lc_ending()
_me.nw.lc_seated = true
_advance(1.1)
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
paint()
-- the light rig on the bus's roof: six beams
local fakeBus = { IsValid = function() return true end, OBBMins = function() return Vector(-200, -50, 0) end, OBBMaxs = function() return Vector(200, 50, 120) end,
    LocalToWorld = function(_, v) return v end, GetAngles = function() return Angle(0, 0, 0) end, GetPos = function() return Vector(0, 0, 0) end }
local entWas, hsvWas = Entity, HSVToColor
Entity = function(i) if i == 1 then return fakeBus end return entWas(i) end
HSVToColor = HSVToColor or function() return Color(255, 120, 200) end
local rigBefore = _calls["render.DrawBeam"] or 0
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
for _, h in pairs(hook.t["Think"] or {}) do h() end
local rigBeams = (_calls["render.DrawBeam"] or 0) - rigBefore
Entity, HSVToColor = entWas, hsvWas
if rigBeams < 6 then return "bus: the light rig on the roof isn't drawn (" .. rigBeams .. " beams)" end
_me.nw.lc_seated = false
net._q = { { id = "base", phase = "apocalypse", name = "Base", say = "x", song = "livingcity/endings/base/base.ogg",
    client = { party = true, lights = true, dance = "bus", bpm = 150, offset = 0, start = CurTime() - 3, cats = true, sky = Vector(0, 0, 2600),
        bombs = { 1 }, boomAt = CurTime(), lines = { { t = 2.2, text = "CAPTAIN: What happen ?" }, { t = 3.5, text = "MECHANIC: Somebody set up us the bomb." } } } } }
net.recv_lc_ending()
_me.nw.lc_riding = _me
_advance(0.5)
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
for _, h in pairs(hook.t["PostDrawOpaqueRenderables"] or {}) do h(false, false) end
paint()
_me.nw.lc_riding = nil
net._q = { { id = "hard", phase = "apocalypse", name = "Hard", say = "x", song = "livingcity/endings/hard/hard.ogg",
    flashing = true, client = { party = true, lights = true, strobe = true, dance = "hard", partyText = true, palette = { { 255, 40, 40 }, { 60, 140, 255 } }, bpm = 150, offset = 0, start = CurTime(), section = "hard" } } }
net.recv_lc_ending()
_me.nw.lc_dancing = true
_advance(1.1)
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
paint()
net._q = { { id = "plane", phase = "apocalypse", name = "Plane", say = "x", song = "livingcity/endings/plane/plane.ogg", flashing = true,
    client = { party = true, lights = true, dance = "numa", bpm = 130, offset = 0, start = CurTime() - 16, section = "chorus", webcam = true, lipsync = true,
        palette = { { 255, 60, 60 }, { 80, 200, 255 } }, captions = { { t = 15.1, text = "MA-IA-HII" } }, whiteAt = CurTime() + 5 } } }
net.recv_lc_ending()
_me.nw.lc_dancing = true
_me.nw.lc_riding = _me
_advance(0.2)
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["MouthMoveAnimation"] or {}) do h(_me) end
for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
paint()
_me.nw.lc_riding = nil
net._q = { { id = "standup", phase = "apocalypse", name = "Standup", say = "x", song = "livingcity/endings/standup/standup.ogg",
    client = { bpm = 133, offset = 0, start = CurTime(), hangs = { { e = 1, a = Vector(0, 0, 300) } } } } }
net.recv_lc_ending()
_me.nw.lc_hanged = CurTime()
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
_me.nw.lc_limp = true
for _, h in pairs(hook.t["Think"] or {}) do h() end
_me.nw.lc_hanged = 0
_me.nw.lc_limp = false
_me.nw.lc_dancing = false
-- Shalom: the hora, kippahs, the hanukkiah, the flags, the sayings, the fireworks, the end
if LC_CL.Hebrew("\215\169\215\156\215\149\215\157") ~= "\215\157\215\149\215\156\215\169" then return "shalom: Hebrew isn't turned round to read right to left" end
if LC_CL.Hebrew("Oy vey!") ~= "Oy vey!" then return "shalom: English is turned round too" end
local matrixWas, allWas, soundPlayed = Matrix, ents.GetAll, 0
Matrix = function() return setmetatable({}, { __index = function() return function() end end }) end
ents.GetAll = function() return { _me } end
local playWas = sound.Play
sound.Play = function() soundPlayed = soundPlayed + 1 end
_me.LookupBone = function() return 6 end
_me.GetBoneMatrix = function() return { GetTranslation = function() return Vector(0, 0, 64) end, GetAngles = function() return Angle(-90, 0, 0) end } end
local pfWas = sound.PlayFile
sound.PlayFile = function() end -- (no song playing: the clock is the ending's own start)
local function shalom(at, section)
    net._q = { {} }
    net.recv_lc_ending()
    net._q = { { id = "shalom", phase = "apocalypse", name = "Shalom", say = "x", song = "livingcity/endings/shalom.mp3",
        client = { party = true, lights = true, dance = "hora", palette = { { 255, 205, 110 }, { 60, 120, 255 } }, bpm = 136, offset = 0.36, start = CurTime() - at,
            section = section, menorah = { pos = Vector(0, 0, 0), w = 180, h = 170 }, candles = { 35.7, 62.1, 86.8, 111.5, 125.7, 153.9, 183.9, 205.1 },
            poles = { Vector(400, 0, 0), Vector(-400, 0, 0) }, sky = Vector(0, 0, 900), gatherAt = 7.4, peakAt = 205.1, outroAt = 273.9, sayings = { "Gut yontif!" } } } }
    net.recv_lc_ending()
end
_me.nw.lc_dancing = true
for _, at in ipairs({ { 3, "intro" }, { 20, "gather" }, { 40, "walk" }, { 70, "hora" }, { 155, "in" }, { 206, "peak" }, { 240, "final" } }) do
    shalom(at[1], at[2])
    _me.nw.lc_chair = at[2] == "hora"
    _advance(1.1)
    for _, h in pairs(hook.t["Think"] or {}) do h() end
    for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
    local spheres = _calls["render.DrawSphere"] or 0
    hook.t.PostDrawOpaqueRenderables.LivingCityShalomKippah(false, false)
    spheres = (_calls["render.DrawSphere"] or 0) - spheres
    local boxes, quads = _calls["render.DrawBox"] or 0, _calls["render.DrawQuad"] or 0
    hook.t.PostDrawOpaqueRenderables.LivingCityShalom(false, false)
    boxes, quads = (_calls["render.DrawBox"] or 0) - boxes, (_calls["render.DrawQuad"] or 0) - quads
    for _, h in pairs(hook.t["PostDrawOpaqueRenderables"] or {}) do h(false, false) end
    for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
    paint()
    for _, h in pairs(hook.t["RenderScreenspaceEffects"] or {}) do h() end
    if boxes < 20 then return "shalom: the hanukkiah isn't drawn at " .. at[1] .. "s" end
    if quads < 100 then return "shalom: the flags aren't drawn at " .. at[1] .. "s" end
    if at[1] >= 206 and quads < 400 then return "shalom: no giant flag in the sky after the key change" end
    if at[1] >= 20 and spheres < 2 then return "shalom: no kippah at " .. at[1] .. "s" end
    if at[1] < 7 and spheres > 0 then return "shalom: a kippah before everyone's gathered" end
end
_me.nw.lc_chair = false
if soundPlayed < 1 then return "shalom: no candle lit, and no fireworks, by the key change" end
shalom(276, "outro")
local before = _calls["draw.SimpleTextOutlined"] or 0
paint()
if (_calls["draw.SimpleTextOutlined"] or 0) - before < 2 then return "shalom: no Am Yisrael chai at the end" end
if concommand.list and concommand.list.lc_shalom_pose then concommand.list.lc_shalom_pose(nil, "lc_shalom_pose", { "R_UpperArm", "-20", "-80", "0" }) end
if concommand.list and concommand.list.lc_shalom_pose_print then concommand.list.lc_shalom_pose_print() end
Matrix, ents.GetAll, sound.Play, sound.PlayFile = matrixWas, allWas, playWas, pfWas
_me.LookupBone, _me.GetBoneMatrix = nil, nil
_me.nw.lc_dancing = false
-- Fire: flames out of the behind (and smoke before they light), a glow over them, flying
do
    local pewWas, allWas2 = ParticleEmitter, ents.GetAll
    local flames = 0
    local fp = setmetatable({}, { __index = function() return function() end end })
    ParticleEmitter = function() return { Add = function() flames = flames + 1 return fp end, Finish = function() end } end
    ents.GetAll = function() return { _me } end
    _me.nw.lc_dancing = true
    local function fire(at, section, heat, flying)
        net._q = { {} }
        net.recv_lc_ending()
        net._q = { { id = "fire", phase = "apocalypse", name = "Fire", say = "x", song = "livingcity/endings/fire.mp3",
            client = { party = true, lights = true, dance = "fire", fire = true, palette = { { 255, 120, 20 } }, bpm = 100, offset = 0.18, start = CurTime() - at, section = section } } }
        net.recv_lc_ending()
        _me.nw.lc_fire, _me.nw.lc_flying, _me.nw.lc_fly_yaw = heat, flying, 90
    end
    for _, at in ipairs({ { 5, "intro", 0, false }, { 30, "ignite", 1, false }, { 80, "hop", 1.6, false }, { 120, "fly", 2.2, true } }) do
        fire(at[1], at[2], at[3], at[4])
        local f0, s0 = flames, _calls["render.DrawSprite"] or 0
        for _ = 1, 6 do _advance(0.6) for _, h in pairs(hook.t["Think"] or {}) do h() end end
        for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
        for _, h in pairs(hook.t["CalcView"] or {}) do h(_me, Vector(0, 0, 0), Angle(0, 0, 0), 75) end
        if hook.t.PrePlayerDraw and hook.t.PrePlayerDraw.LivingCityFire then hook.t.PrePlayerDraw.LivingCityFire(_me) end
        paint()
        local sprites = (_calls["render.DrawSprite"] or 0) - s0
        if at[3] > 0 and flames - f0 < 6 then return "fire: hardly any flames at " .. at[1] .. "s (" .. (flames - f0) .. ")" end
        if at[3] > 0 and sprites < 1 then return "fire: no glow over the flames at " .. at[1] .. "s" end
        if at[3] == 0 and sprites > 0 then return "fire: a glow before anyone's lit" end
    end
    if not LC_CL.EndingMoves.fire or #LC_CL.EndingMoves.fire ~= 2 then return "fire: its two moves aren't in the Endings menu" end
    net._q = { {} }
    net.recv_lc_ending()
    _me.nw.lc_fire, _me.nw.lc_flying, _me.nw.lc_dancing = 0, false, false
    ParticleEmitter, ents.GetAll = pewWas, allWas2
end
-- the playtest fixes: stage lights on the flood, spotlights for Hard, cones drawn on the hanged,
-- the arcade's score and trails, nobody running in place while an ending moves them
local entWas2 = Entity
Entity = function(i) if i == 1 then return _me end return entWas2(i) end
_me.LookupBone = function() return 6 end
_me.GetBoneMatrix = function() return { GetTranslation = function() return Vector(0, 0, 64) end, GetAngles = function() return Angle(-90, 0, 0) end } end
_me.GetForward = function() return Vector(1, 0, 0) end
local function beams() return _calls["render.DrawBeam"] or 0 end
local b0 = beams()
net._q = { { id = "water", phase = "apocalypse", name = "The Flood", say = "x", client = { bpm = 150, offset = 0, start = CurTime(), section = "heavy",
    spots = true, spotEnt = 1, spotR = 160, spotN = 6, spotCols = { { 255, 255, 255 }, { 80, 140, 255 } }, spotCycle = true } } }
net.recv_lc_ending()
_me.nw.lc_rocking = true
for _, h in pairs(hook.t["Think"] or {}) do h() end
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
_me.nw.lc_rocking = false
if beams() - b0 < 6 then return "flood: no stage lights" end
b0 = beams()
net._q = { { id = "hard", phase = "apocalypse", name = "Hard", say = "x", client = { party = true, lights = true, strobe = true, dance = "hard", partyText = true,
    palette = { { 255, 40, 40 } }, bpm = 150, offset = 0, start = CurTime(), section = "hard", spots = true, lz = Vector(0, 0, 0), spotR = 200, spotN = 10,
    spotCols = { { 255, 40, 40 }, { 60, 140, 255 } }, spotCycle = true } } }
net.recv_lc_ending()
for _, h in pairs(hook.t["PostDrawTranslucentRenderables"] or {}) do h(false, false) end
if beams() - b0 < 10 then return "hard: no spotlights" end
_me.nw.lc_dancing = true
ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE or 1
local act = hook.t.CalcMainActivity and hook.t.CalcMainActivity.LivingCityEndingStand and hook.t.CalcMainActivity.LivingCityEndingStand(_me)
if act == nil then return "endings: a dancer moved about by an ending would run on the spot" end
_me.nw.lc_dancing = false
local cmWas, drawn = ClientsideModel, 0
ClientsideModel = function() return { IsValid = function() return true end, SetNoDraw = function() end, SetModelScale = function() end, SetPos = function() end,
    SetAngles = function() end, SetupBones = function() end, DrawModel = function() drawn = drawn + 1 end, Remove = function() end } end
net._q = { { id = "standup", phase = "apocalypse", name = "Standup", say = "x", client = { bpm = 133, offset = 0, start = CurTime(), hangs = { { e = 1, a = Vector(0, 0, 300) } } } } }
net.recv_lc_ending()
hook.t.PostDrawOpaqueRenderables.LivingCityStandupCones(false, false)
ClientsideModel = cmWas
if drawn < 1 then return "standup: no cone on the hanged head" end
net._q = { { id = "base", phase = "apocalypse", name = "Base", say = "x", client = { party = true, lights = true, dance = "bus", bpm = 150, offset = 0, start = CurTime() - 40,
    sky = Vector(0, 0, 2600), bombs = { 1 }, zigs = { 1 }, lines = {} } } }
net.recv_lc_ending()
for _, h in pairs(hook.t["Think"] or {}) do h() end
_advance(0.2)
for _, h in pairs(hook.t["Think"] or {}) do h() end
net._q = { { id = "base", phase = "apocalypse", name = "Base", say = "x", client = { party = true, lights = true, dance = "bus", bpm = 150, offset = 0, start = CurTime() - 40,
    sky = Vector(0, 0, 2600), bombs = {}, zigs = { 1 }, lines = {}, boomAt = CurTime() } } }
net.recv_lc_ending()
Entity = function(i) return nil end
for _, h in pairs(hook.t["Think"] or {}) do h() end
local boxes = _calls["render.DrawBox"] or 0
hook.t.PostDrawTranslucentRenderables.LivingCityBaseArcade(false, false)
local tb = _calls["render.DrawBox"] or 0
local txt = _calls["draw.SimpleText"] or 0
hook.t.HUDPaint.LivingCityBaseArcade()
if tb - boxes < 1 then return "base: no exhaust trail behind the ZIG" end
if (_calls["draw.SimpleText"] or 0) - txt < 3 then return "base: no score, or no 1000 where a bomb went off" end
Entity = entWas2
_me.LookupBone, _me.GetBoneMatrix, _me.GetForward = nil, nil, nil
-- lc_sound_check: the counts, every ending song opened (one that won't, and one that does), a test announcement
do
    local findWas, pfWas2 = file.Find, sound.PlayFile
    file.Find = function(p) if string.find(p, "endings", 1, true) then return { "shalom1.mp3", "bad.mp3" }, {} end return { "ambient1.mp3" }, {} end
    sound.PlayFile = function(path, flags, cb)
        if string.find(path, "bad", 1, true) then cb(nil, 41, "BASS_ERROR_FILEFORM") return end
        cb(setmetatable({ IsValid = function() return true end }, { __index = function() return function() end end }))
    end
    concommand.list.lc_sound_check()
    file.Find, sound.PlayFile = findWas, pfWas2
end
-- carrying a box: each hand reaches its side of the box (the arm's lengths kept), wherever the walk had it
do
    local mxWas = Matrix
    local MM = {}
    MM.__index = MM
    MM.__mul = function(a, b) local m = setmetatable({ t = a.t + b.t, a = Angle() }, MM) return m end
    function MM:SetTranslation(v) self.t = v end
    function MM:GetTranslation() return self.t end
    function MM:SetAngles(a) self.a = a end
    function MM:GetAngles() return self.a end
    function MM:GetInverseTR() return setmetatable({ t = -self.t, a = Angle() }, MM) end
    Matrix = function() return setmetatable({ t = Vector(), a = Angle() }, MM) end
    local mats = { [1] = Vector(0, -8, 60), [2] = Vector(0, -8, 48), [3] = Vector(0, -8, 37) }
    local set = {}
    local fake = {
        LookupBone = function(_, n) return ({ ["ValveBiped.Bip01_R_UpperArm"] = 1, ["ValveBiped.Bip01_R_Forearm"] = 2, ["ValveBiped.Bip01_R_Hand"] = 3 })[n] end,
        GetBoneMatrix = function(_, i) local m = Matrix() m:SetTranslation(mats[i]) return m end,
        SetBoneMatrix = function(_, i, m) set[i] = m end,
        GetRight = function() return Vector(0, -1, 0) end, GetUp = function() return Vector(0, 0, 1) end,
        GetChildBones = function() return {} end,
    }
    local target = Vector(16, -12, 46)
    LC_CL.CarryReach(fake, "R", target)
    Matrix = mxWas
    if not (set[3] and set[3]:GetTranslation():Distance(target) < 0.6) then return "carrying: the hand doesn't reach its side of the box" end
    if math.abs(set[2]:GetTranslation():Distance(set[1]:GetTranslation()) - 12) > 0.1 then return "carrying: the upper arm changed length" end
end
-- sneaking: the bar, and a unit's sight on the ground (you in it: "A UNIT CAN SEE YOU")
do
    local crWas, fbcWas, velWas = _me.Crouching, ents.FindByClass, _me.GetVelocity
    _me.Crouching = function() return true end
    _me.GetVelocity = function() return Vector(0, 0, 0) end
    local unit = { IsValid = function() return true end, GetNW2String = function(_, k, d) return k == "lc_role" and "cop" or d end,
        GetPos = function() return _me:GetPos() + Vector(-200, 0, 0) end, GetForward = function() return Vector(1, 0, 0) end, GetAngles = function() return Angle() end }
    ents.FindByClass = function(c) if c == "npc_*" then return { unit } end return fbcWas(c) end
    if not LC_CL.StealthInside(unit, _me:GetPos(), 900 * LC_CL.StealthFactor()) then return "sneaking: a unit facing you, close by, doesn't see you" end
    local q0 = _calls["render.DrawQuad"] or 0
    hook.t.PostDrawTranslucentRenderables.LivingCityStealthCones(false, false)
    if (_calls["render.DrawQuad"] or 0) <= q0 then return "sneaking: no sight painted on the ground" end
    if (_calls["render.DrawQuad"] or 0) - q0 < 12 * 6 then return "sneaking: the sight isn't 3D (ground, lid and walls)" end
    hook.t.HUDPaint.LivingCityStealthMeter()
    unit.GetForward = function() return Vector(-1, 0, 0) end
    if LC_CL.StealthInside(unit, _me:GetPos(), 900 * LC_CL.StealthFactor()) then return "sneaking: seen from behind his back" end
    _me.Crouching, ents.FindByClass, _me.GetVelocity = crWas, fbcWas, velWas
end
-- the Endings menu: asks the server, opens on the ending playing, every tab built; a bone tuned on a
-- dancer, lit up in the world; the stand-in; the shared settings; the list of changes
do
    local saWas, stsWas, cmWas3, vgWas = _me.IsSuperAdmin, net.SendToServer, ClientsideModel, vgui
    local made2 = {}
    local function P2()
        local t = {}
        made2[#made2 + 1] = t
        return setmetatable(t, { __index = function(_, k)
            if string.sub(k, 1, 2) == "lc" or string.sub(k, 1, 1) == "_" or k == "Items" or k == "Label" then return nil end
            if k == "IsValid" then return function() return not t._removed end end
            if k == "Remove" then return function() t._removed = true if t.OnRemove then t.OnRemove() end end end
            if k == "GetValue" then return function() return 0 end end
            if k == "GetWide" or k == "GetTall" then return function() return 400 end end
            if k == "LocalToScreen" then return function() return 0, 0 end end
            return function() return P2() end
        end })
    end
    vgui = { Create = function() return P2() end, GetKeyboardFocus = function() return nil end }
    local asked = 0
    _me.IsSuperAdmin = function() return true end
    net.SendToServer = function() asked = asked + 1 end
    concommand.list.lc_endings_menu()
    if asked < 1 then return "endings menu: never asked the server" end
    net._q = { { endings = { { id = "base", name = "Base" }, { id = "shalom", name = "Shalom" } }, now = "base",
        settings = { base = { { name = "lc_ending_base_bombs", v = "60", d = "60", help = "how many" }, { name = "lc_ending_base_sections", v = "1:a,2:b", d = "1:a,2:b", help = "when" } },
            all = { { name = "lc_ending_cooldown", v = "45", d = "60", help = "minutes" } } },
        tuning = { bones = { bus = { Head = { 5, 0, 0 } } }, shared = {} } } }
    net.recv_lc_tune_info()
    local st = LC_CL.EndingTuneState()
    if st.ending ~= "base" then return "endings menu: didn't pick the ending playing (" .. tostring(st.ending) .. ")" end
    if st.move ~= "bus" then return "endings menu: Base's move isn't picked (" .. tostring(st.move) .. ")" end
    local a = LC_CL.EndingTuneBone(_me, "bus", "Head", Angle(1, 2, 3))
    if not (a.p == 6 and a.y == 2 and a.r == 3) then return "endings menu: a tuned bone isn't turned on the dancer" end
    local ch = LC_CL.EndingTuneChanges()
    if not (string.find(ch, "bus: Head 5 0 0", 1, true) and string.find(ch, "lc_ending_cooldown = 45", 1, true)) then return "endings menu: the changes list is missing something:\n" .. ch end
    st.bone = "Head"
    _me.LookupBone = function() return 6 end
    _me.GetBoneMatrix = function() return { GetTranslation = function() return Vector(0, 0, 64) end, GetAngles = function() return Angle(0, 0, 0) end } end
    local sp = _calls["render.DrawSphere"] or 0
    hook.t.PostDrawTranslucentRenderables.LivingCityEndingTune(false, false)
    if (_calls["render.DrawSphere"] or 0) <= sp then return "endings menu: the bone being tuned isn't lit up" end
    local fake = { manip = {} }
    fake.IsValid = function() return not fake.gone end
    fake.Remove = function() fake.gone = true end
    fake.GetPos = function() return Vector(100, 0, 0) end
    fake.GetAngles = function() return Angle(0, 180, 0) end
    fake.GetBonePosition = function() return Vector(100, 0, 60), Angle() end
    fake.GetModel = function() return "models/player/group01/male_02.mdl" end
    fake.LookupSequence = function() return 3 end
    fake.LookupBone = function(_, n) return #n end
    fake.ManipulateBoneAngles = function(_, id, ang) fake.manip[id] = ang end
    for _, k in ipairs({ "ResetSequence", "SetPos", "SetAngles", "SetCycle" }) do fake[k] = function() end end
    fake.GetNW2Float = function(_, _, d) return d end
    fake.GetNW2Bool = function(_, _, d) return d end
    ClientsideModel = function() return fake end
    st.standIn = true
    for _, mv in ipairs({ "bus", "ears", "hora", "chair", "numa", "hard", "cheer", "club", "bang", "hanged", "limp" }) do
        st.move = mv
        fake.manip = {}
        hook.t.Think.LivingCityEndingTuneStandIn()
        if not next(fake.manip) then return "endings menu: the stand-in doesn't do " .. mv end
    end
    st.standIn = false
    hook.t.Think.LivingCityEndingTuneStandIn()
    if not fake.gone then return "endings menu: the stand-in stays after it's unticked" end
    net._q = { { bones = {}, shared = { lc_bloom_palm = "70" } } }
    net.recv_lc_tune_all()
    local cv = { GetName = function() return "lc_bloom_palm" end, GetString = function() return "90" end }
    if LC_CL.EndingTunedCV(cv) ~= "70" then return "endings menu: the shared palms setting isn't used" end
    net._q = { { bones = {}, shared = {} } }
    net.recv_lc_tune_all()
    -- every panel's own drawing and clicks run without an error
    for _, pnl in ipairs(made2) do
        for _, k in ipairs({ "Paint", "Think", "PerformLayout", "DoClick" }) do
            local f = rawget(pnl, k)
            if f then local okp, e = pcall(f, pnl, 400, 240) if not okp then return "endings menu: a panel's " .. k .. " fails: " .. tostring(e) end end
        end
    end
    LC_CL.CloseEndingsMenu()
    _me.IsSuperAdmin, net.SendToServer, ClientsideModel, vgui = saWas, stsWas, cmWas3, vgWas
    _me.LookupBone, _me.GetBoneMatrix = nil, nil
end
if concommand.list and concommand.list.lc_bloom_pose then concommand.list.lc_bloom_pose(nil, "lc_bloom_pose", { "R_Hand", "1", "2", "3" }) end
net._q = { { id = "water", phase = "reset", name = "The Flood" } }
net.recv_lc_ending()
_advance(2)
paint()
net._q = { {} }
net.recv_lc_ending()
if LC_CL.Ending() ~= nil then return "ending: not cleared" end
paint()
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)
# Pose Recorder (the separate addon, ../pose_recorder): pick a ragdoll, snap keyframes, record,
# play the loop, copy, save and load, and the tool's panel, on the fake client
PR_DIR = os.path.join(HERE, "..", "pose_recorder", "lua")
L.globals()["_pr_core"] = open(os.path.join(PR_DIR, "pose_recorder", "core.lua")).read()
L.globals()["_pr_auto"] = open(os.path.join(PR_DIR, "autorun", "pose_recorder.lua")).read()
L.globals()["_pr_tool"] = open(os.path.join(PR_DIR, "weapons", "gmod_tool", "stools", "pose_recorder.lua")).read()
err = L.execute(r"""
local ok, e = pcall(function()
    include = function(p) if p == "pose_recorder/core.lua" then assert(loadstring(_pr_core, "core.lua"))() end end
    AddCSLuaFile = function() end
    surface.PlaySound = function() end
    chat = chat or {}
    chat.AddText = function() end
    string.GetFileFromFilename = string.GetFileFromFilename or function(p) return (string.match(p or "", "([^/]+)$")) end
    file.CreateDir = file.CreateDir or function() end
    local clip
    SetClipboardText = function(t) clip = t end
    util.TableToJSON = util.TableToJSON or function(t) return "{json}" end
    -- a fake model: a pelvis, a chest and an arm, standing; the ragdoll the same with the arm raised
    local function M(p, y, r) return { GetAngles = function() return Angle(p, y, r) end, GetTranslation = function() return Vector() end } end
    local BONES = { { "ValveBiped.Bip01_Pelvis", -1 }, { "ValveBiped.Bip01_Spine2", 0 }, { "ValveBiped.Bip01_R_UpperArm", 1 } }
    local function Fake(angles)
        local e = { manip = {} }
        e.IsValid = function() return true end
        e.GetModel = function() return "models/player/kleiner.mdl" end
        e.GetPos = function() return Vector(0, 0, 0) end
        e.GetBoneCount = function() return #BONES end
        e.GetBoneName = function(_, i) return BONES[i + 1][1] end
        e.GetBoneParent = function(_, i) return BONES[i + 1][2] end
        e.LookupBone = function(_, n) for i, b in ipairs(BONES) do if b[1] == n then return i - 1 end end end
        e.GetBoneMatrix = function(_, i) local a = angles[i + 1] return M(a[1], a[2], a[3]) end
        e.InvalidateBoneCache, e.SetupBones, e.SetNoDraw, e.SetPos, e.SetAngles = function() end, function() end, function() end, function() end, function() end
        e.LookupSequence = function() return 3 end
        e.SelectWeightedSequence = function() return 3 end
        e.ResetSequence, e.SetCycle, e.SetPlaybackRate, e.Remove = function() end, function() end, function() end, function() e.removed = true end
        e.ManipulateBoneAngles = function(_, id, a) e.manip[id] = a end
        e.GetClass = function() return "prop_ragdoll" end
        return e
    end
    local standing = { { 0, 0, 90 }, { -80, 0, 90 }, { 80, 10, 0 } }
    local raised = { { 0, 0, 90 }, { -80, 0, 90 }, { -20, 10, 0 } }
    local ghost
    ClientsideModel = function() ghost = Fake(standing) return ghost end
    SERVER, CLIENT = false, true
    assert(loadstring(_pr_auto, "pose_recorder.lua"))()
    local PR = PoseRecorder
    local rag = Fake(raised)
    net._q = nil
    PR.sel = { ent = rag, phys = { ["ValveBiped.Bip01_Pelvis"] = true, ["ValveBiped.Bip01_Spine2"] = true, ["ValveBiped.Bip01_R_UpperArm"] = true } }
    concommand.list.pose_recorder_snap()
    if #PR.frames ~= 1 then error("pose recorder: no keyframe snapped") end
    local arm = PR.frames[1].bones["ValveBiped.Bip01_R_UpperArm"]
    if not arm or math.abs(arm[1]) + math.abs(arm[2]) + math.abs(arm[3]) < 10 then error("pose recorder: the raised arm wasn't recorded as a turn") end
    local pelvis = PR.frames[1].bones["ValveBiped.Bip01_Pelvis"]
    if not pelvis or math.abs(pelvis[1]) + math.abs(pelvis[2]) + math.abs(pelvis[3]) > 0.5 then error("pose recorder: a bone posed as it stands should record no turn") end
    standing, raised = standing, standing
    rag.GetBoneMatrix = function(_, i) local a = ({ { 0, 0, 90 }, { -80, 0, 90 }, { 80, 10, 0 } })[i + 1] return M(a[1], a[2], a[3]) end
    concommand.list.pose_recorder_snap()
    concommand.list.pose_recorder_preview()
    if not IsValid(ghost) then error("pose recorder: no ghost to play the loop") end
    _advance(0.25)
    for _, h in pairs(hook.t["Think"] or {}) do h() end
    if not ghost.manip[2] then error("pose recorder: the ghost isn't posed") end
    for _, h in pairs(hook.t["HUDPaint"] or {}) do h() end
    concommand.list.pose_recorder_copy()
    if not clip then error("pose recorder: nothing copied") end
    concommand.list.pose_recorder_save()
    concommand.list.pose_recorder_clear()
    concommand.list.pose_recorder_load()
    concommand.list.pose_recorder_preview()
    concommand.list.pose_recorder_record()
    _advance(0.5)
    for _, h in pairs(hook.t["Think"] or {}) do h() end
    concommand.list.pose_recorder_record()
    if PR.mode ~= "rec" or #PR.frames < 1 then error("pose recorder: nothing recorded") end
    local cp = setmetatable({}, { __index = function() return function() return setmetatable({}, { __index = function() return function() end end }) end end })
    TOOL = {}
    language = language or {}
    language.Add = function() end
    assert(loadstring(_pr_tool, "stool.lua"))()
    TOOL.BuildCPanel(cp)
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)
# the official folder for recordings and songs is the server's garrysmod/sound/livingcity/ (CORE.md):
# what players read in the guide and the sound check must send them there, never to the old sound addon
_guide = open(os.path.join(GMDIR, "gamemode", "cl_init.lua")).read()
_notes = open(os.path.join(GMDIR, "gamemode", "modules", "client", "cl_livingcity_notices.lua")).read()
if "garrysmod/sound/livingcity/" not in _guide or "livingcity_sound" in _guide or "livingcity_sound folder" in _notes:
    problems = (problems + "\n" if problems else "") + "the guide or the sound check points somewhere other than garrysmod/sound/livingcity/"
print(problems or "no client errors")
print("zone fills drawn:", filled, "thick edges drawn:", beams)
ok = not problems and filled >= 2 and beams > 0
print("CLIENT SMOKE", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
