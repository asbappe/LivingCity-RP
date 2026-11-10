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
-- (the game's ents.FindByClass takes a trailing * for "every class that starts with": npc_*)
do
    local exact, every = ents.FindByClass, ents.GetAll
    function ents.FindByClass(c)
        if type(c) ~= "string" or string.sub(c, -1) ~= "*" then return exact(c) end
        local pre, o = string.sub(c, 1, -2), {}
        for _, e in ipairs(every()) do if string.sub(e:GetClass() or "", 1, #pre) == pre then o[#o + 1] = e end end
        return o
    end
end
function CreateMaterial() return {} end
function Material() return setmetatable({}, { __index = function(_, k) if k == "IsError" then return function() return false end end return function() end end }) end
MATERIAL_TRIANGLES, MASK_SOLID_BRUSHONLY = 2, 5
TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM = 0, 1, 2, 3, 4
function math.NormalizeAngle(a) return (a + 180) % 360 - 180 end
function string.FormattedTime(s, fmt) return string.format(fmt or "%02i:%02i", math.floor(s / 60), math.floor(s % 60)) end
function GetGlobal2String(k, d) return _globals[k] or d end
function GetGlobal2Float(k, d) return _globals[k] or d end
function GetGlobal2Entity(k, d) return _globals[k] or d end
function GetGlobal2Vector(k, d) return _globals[k] or d end
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
_advance(1.6) -- (a short gap between tips, then the next: the owner, 7 November, one thing at a time)
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
    players = { { id = "STEAM_0:1|Me", name = "Me" } }, evidence = "In the evidence room: 3 items (Old radio x3)." } end
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
-- Unit tools (F2): with the evidence room's stock, and a burn going on (sv_livingcity_evidence.lua)
_globals.lc_evidence_n, _globals.lc_evidence_list, _globals.lc_evidence_burn = 3, "Old radio x3", "burning near Block 1"
made = 0
okP, errP = pcall(function() LC_CL.OpenUnitTools() end)
if not okP then problems[#problems + 1] = "unit tools: " .. tostring(errP) end
if okP and made < 20 then problems[#problems + 1] = "unit tools built only " .. made .. " controls" end
_globals.lc_evidence_n, _globals.lc_evidence_list, _globals.lc_evidence_burn = 0, "", ""
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
    officer = true, socioctl = true, socio = "yellow", -- (socioctl: the Administrator's buttons)
    manpower = { "Civil Protection: 13 in reserve (of 20), 2 lost today", "Next unit in about 4 minutes", "Overwatch: 12 in reserve (of 12), 0 lost today", "The reserve is full" } } end
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
-- Labor Assignment: after registering, before a room (sv_livingcity_labor.lua)
local laborDesk = ents.Create("lc_intake")
laborDesk:SetPos(Vector(300, 0, 0))
laborDesk.nw.lc_ikind = "labor"
_me.nw.lc_unassigned = true
if LC_CL.IntakeStep(_me) ~= "labor" then problems[#problems + 1] = "registered with no work: Labor Assignment is next, before Housing Allocation" end
_advance(1.5) -- (the terminals are looked for once a second)
if LC_CL.NearestDesk("labor") ~= laborDesk then problems[#problems + 1] = "the way to Labor Assignment isn't found" end
run("HUDPaint")
local okLs, errLs = pcall(LC_CL.DrawIntakeSign, laborDesk)
if not okLs then problems[#problems + 1] = "Labor Assignment sign: " .. tostring(errLs) end
_me.nw.lc_unassigned = false
laborDesk:Remove()
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
-- breathing: winded, the view rises and falls while you stand still; the stamina bar draws
_me.nw = _me.nw or {}
_me.nw.lc_winded, _me.nw.lc_stamina = true, 5
_me.vel = Vector(0, 0, 0)
local zs = {}
for i = 1, 12 do
    _advance(0.1)
    local bz = LC_CL.CalcView(_me, { origin = Vector(0, 0, 61), angles = Angle(), fov = 75 })
    zs[#zs + 1] = bz.origin.z
end
local lo, hi = math.huge, -math.huge
for _, z in ipairs(zs) do lo, hi = math.min(lo, z), math.max(hi, z) end
if hi - lo < 0.05 then problems[#problems + 1] = "winded, the view doesn't breathe" end
local stamHud = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityStaminaHUD
if not stamHud then problems[#problems + 1] = "no stamina bar" else
    local okS, errS = pcall(stamHud)
    if not okS then problems[#problems + 1] = "the stamina bar errors: " .. tostring(errS) end
end
_me.nw.lc_winded, _me.nw.lc_stamina = nil, nil
if not (hook.t.RenderScreenspaceEffects and hook.t.RenderScreenspaceEffects.LivingCityColorGrade) then problems[#problems + 1] = "no colour grading" end
-- the "lower your weapon" prompt on rebel ground
_me.nw.lc_lowered_ground = "rebel"
local lp = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityLowerPrompt
if not lp then problems[#problems + 1] = "no lower-your-weapon prompt" else
    local okP, errP = pcall(lp)
    if not okP then problems[#problems + 1] = "the lower-your-weapon prompt errors: " .. tostring(errP) end
end
_me.nw.lc_lowered_ground = nil
-- the sealed directive reminder, and the G-Man's summons with its envelope
_me.nw.lc_directive_until, _me.nw.lc_directive_urgent = CurTime() + 120, true
local rem = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityDirectiveReminder
if not rem then problems[#problems + 1] = "no sealed directive reminder" else
    local okR, errR = pcall(rem)
    if not okR then problems[#problems + 1] = "the directive reminder errors: " .. tostring(errR) end
end
_me.nw.lc_directive_until, _me.nw.lc_directive_urgent = nil, nil
-- the recall box, while someone can call one
_me.nw.lc_gman_rival_until = CurTime() + 600
local rb = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityRecallReminder
if not rb then problems[#problems + 1] = "no recall box" else
    local okB, errB = pcall(rb)
    if not okB then problems[#problems + 1] = "the recall box errors: " .. tostring(errB) end
end
_me.nw.lc_gman_rival_until = nil
-- the kick reminder at a locked door, with the keys looked up live
local kdoor = ents.Create("prop_door_rotating")
_me.nw.lc_kick_hint = kdoor
local kh = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityKickHint
if not kh then problems[#problems + 1] = "no kick reminder" else
    local okK, errK = pcall(kh)
    if not okK then problems[#problems + 1] = "the kick reminder errors: " .. tostring(errK) end
end
_me.nw.lc_kick_hint = nil
-- the kick shows only the legs: every bone but the hips and the kicking leg is shrunk (a fake skeleton,
-- with an extra mask bone off the head like the HL:Alyx metrocop's)
if LC_CL.KickHideUpper then
    local names = { [0] = "ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Head1", "mask",
        "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Thigh" }
    local parent = { [0] = -1, 0, 1, 2, 0, 4, 0 }
    local shrunk = {}
    local fake = { LookupBone = function(_, nm) for i = 0, 6 do if names[i] == nm then return i end end end,
        GetBoneCount = function() return 7 end, GetBoneParent = function(_, b) return parent[b] end,
        ManipulateBoneScale = function(_, b) shrunk[b] = true end }
    local okL, nL = pcall(LC_CL.KickHideUpper, fake)
    if not okL then problems[#problems + 1] = "the kick's legs-only errors: " .. tostring(nL)
    elseif not (shrunk[1] and shrunk[2] and shrunk[3] and shrunk[6] and not shrunk[0] and not shrunk[4] and not shrunk[5]) then
        problems[#problems + 1] = "the kick shows more than the legs (the mask or the head) or hides the kicking leg"
    end
else problems[#problems + 1] = "no LC_CL.KickHideUpper" end
if LC_CL.GmanVision then
    LC_CL.GmanVision("summon", "", "Come back. / Come back here, now.")
    local gv = hook.t.HUDPaint and hook.t.HUDPaint.LivingCityGmanVision
    local okV, errV = pcall(gv)
    if not okV then problems[#problems + 1] = "the G-Man's summons errors: " .. tostring(errV) end
    _advance(10) pcall(gv)
else problems[#problems + 1] = "no G-Man vision" end
-- the collapse (sv_livingcity_collapse.lua): the G-Man's offer, her shield, the last stand, the heroes
do
    local rf, rs = net.ReadFloat, net.ReadString
    net._q = { 120 }
    net.ReadFloat = function() return table.remove(net._q, 1) end
    local okO, errO = pcall(net["recv_lc_collapse_offer"])
    if not okO then problems[#problems + 1] = "the G-Man's offer errors: " .. tostring(errO)
    elseif not IsValid(LC_CL.CollapseOffer) then problems[#problems + 1] = "the G-Man's offer opens no window"
    else
        local okP2, errP2 = pcall(LC_CL.CollapseOffer.Paint, LC_CL.CollapseOffer, 520, 250)
        if not okP2 then problems[#problems + 1] = "the G-Man's offer paint: " .. tostring(errP2) end
        LC_CL.CollapseOffer:Remove()
    end
    -- the G-Man in person: his words, and the 10 seconds to go back to him
    net._q = { "arrive", "Is it really that time again?", "" }
    net.ReadString = function() return table.remove(net._q, 1) end
    local okG, errG = pcall(net["recv_lc_collapse_gman"])
    if not okG then problems[#problems + 1] = "the G-Man's words error: " .. tostring(errG)
    elseif not (LC_CL.CollapseGmanState and LC_CL.CollapseGmanState()) then problems[#problems + 1] = "the G-Man's words aren't kept to show" end
    local okW, errW = pcall(hook.t.HUDPaint.LivingCityCollapseGmanWords)
    if not okW then problems[#problems + 1] = "the G-Man's words on screen error: " .. tostring(errW) end
    _me.nw.lc_gman_back_by = CurTime() + 8
    local okB, errB = pcall(hook.t.HUDPaint.LivingCityCollapseGmanBack)
    if not okB then problems[#problems + 1] = "the 10 seconds to go back to him error: " .. tostring(errB) end
    _me.nw.lc_gman_back_by = nil
    net.ReadFloat, net.ReadString = rf, rs
    local power = ents.Create("lc_adminpower")
    power:SetPos(Vector(500, 0, 0))
    _globals.lc_collapse_power = power
    local boss = ents.Create("npc_citizen")
    boss:SetPos(Vector(300, 0, 0))
    boss.nw.lc_shield_frac = 1
    _globals.lc_collapse = true
    _globals.lc_collapse_stage = "stand"
    _globals.lc_collapse_boss = boss
    _globals.lc_collapse_office = Vector(300, 0, 0)
    _globals.lc_collapse_until = CurTime() + 300
    _globals.lc_collapse_hero = "freeman"
    _me.nw.lc_hero = "freeman"
    local sp0 = _calls["render.DrawSphere"] or 0
    local okS, errS = pcall(hook.t.PostDrawTranslucentRenderables.LivingCityCollapseShield, false, false)
    if not okS then problems[#problems + 1] = "her shield errors: " .. tostring(errS)
    elseif (_calls["render.DrawSphere"] or 0) <= sp0 then problems[#problems + 1] = "her shield isn't drawn" end
    local okH, errH = pcall(hook.t.HUDPaint.LivingCityCollapseHUD)
    if not okH then problems[#problems + 1] = "the last stand on screen errors: " .. tostring(errH) end
    _me.nw.lc_hero = nil
    for _, k in ipairs({ "lc_collapse", "lc_collapse_stage", "lc_collapse_boss", "lc_collapse_office", "lc_collapse_until", "lc_collapse_hero", "lc_collapse_power" }) do _globals[k] = nil end
    boss:Remove()
    power:Remove()
end
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
-- the board (F3) in a city with a Labor Assignment terminal: no job list, the way to the terminal instead
do
    local j2t = util.JSONToTable
    util.JSONToTable = function() return { board = "Jobs", faction = "citizen", postings = {}, active = false, traits = {}, wait = 0,
        jobs = { current = "courier", list = {}, desk = true, lockLine = "Tied to this job for 12 minutes more or 3 shifts more, whichever comes first; then a Labor Assignment terminal can change it." } } end
    net._q = { 1 }
    local okB, errB = pcall(net["recv_lcq_board"])
    if not okB then problems[#problems + 1] = "the board with a Labor Assignment terminal: " .. tostring(errB) end
    util.JSONToTable = j2t
end
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
    Run("admin", false, function() Look(nil) end) -- (the Administrator: sociostability is theirs alone)
    Run("citizen", true, function()
        local door = ents.Create("prop_door_rotating") Look(door)
    end)
    Run("citizen", false, function() local b = ents.Create("prop_ragdoll") b.nw.lc_body = true Look(b) end)
    Run("citizen", false, function() local b = ents.Create("prop_ragdoll") b.nw.lc_downed_body = true Look(b) end)
    Run("resistance", false, function() Look(ents.Create("lc_screen")) end)
    -- the quick menus: F1 (what everyone has: nine for everyone) and F2 (your side, rank and job), and every item and page runs
    local function Quick(faction, setup)
        _me.nw = { lcf_faction = faction, lce_standing = 200, lcf_rank = 9 }
        _me.alive = true
        _me.IsAdmin = function() return faction == "admin" end
        Look(nil)
        if setup then setup() end
        local okQ, root = pcall(LC_CL.QuickRoot)
        if not okQ then problems[#problems + 1] = "quick menu for " .. faction .. ": " .. tostring(root) return end
        for i = 1, 9 do if not root.items[i] then problems[#problems + 1] = "quick menu for " .. faction .. ": slot " .. i .. " is empty" end end
        for i = 1, 9 do
            local it = root.items[i]
            if it and (it.id == "unittools" or it.id == "kick" or it.role or it.label == "Black market" or string.find(tostring(it.label), "Call for backup", 1, true)) then
                problems[#problems + 1] = "F1 for " .. faction .. " has '" .. tostring(it.label) .. "': that's F2's (only what everyone has goes on F1)"
            end
        end
        if root.items[2] and root.items[2].label ~= "Put my hands up" and root.items[2].label ~= "Lower my hands" then
            problems[#problems + 1] = "F1 for " .. faction .. ": 2 should be hands up (the hints say so), is " .. tostring(root.items[2].label)
        end
        -- (the owner, 10 November: F1 > 6 > Out of character > 1 Nearby, 2 Server-wide)
        local oo = root.items[6]
        local ooPage = oo and oo.page and oo.page()
        if not (oo and oo.label == "Out of character" and ooPage and ooPage.items[1] and ooPage.items[1].label == "Nearby..."
            and ooPage.items[2] and ooPage.items[2].label == "Server-wide...") then
            problems[#problems + 1] = "F1 for " .. faction .. ": 6 should be Out of character (1 Nearby, 2 Server-wide), is " .. tostring(oo and oo.label)
        end
        local okQ2, root2 = pcall(LC_CL.QuickRoleRoot)
        if not okQ2 then problems[#problems + 1] = "F2 for " .. faction .. ": " .. tostring(root2) return end
        if not root2.items[9] then problems[#problems + 1] = "F2 for " .. faction .. " has no 9 (the full menu)" end
        if faction == "cp" then
            -- (the owner, 7 November: 1 Voice lines, 2 Unit tools, 3 Kick, 4 Call for backup, 5 BOLO, 6 Send my 10-20)
            local it = root2.items
            if not (it[1] and it[1].label == "Voice lines" and it[2] and it[2].id == "unittools" and it[3] and it[3].id == "kick"
                and it[4] and string.find(it[4].label, "Call for backup", 1, true) and it[5] and string.find(it[5].label, "BOLO", 1, true) and it[6] and it[6].label == "Send my 10-20") then
                problems[#problems + 1] = "a unit's F2 (" .. faction .. "): should be 1 Voice lines, 2 Unit tools, 3 Kick, 4 Call for backup, 5 BOLO, 6 Send my 10-20"
            end
            if LC_CL.QuickSlot("kick") ~= 3 or select(2, LC_CL.QuickSlot("kick")) ~= "F2" then problems[#problems + 1] = "the kick reminder can't find Kick at F2 > 3" end
        end
        if faction == "resistance" and not (root2.items[1] and string.find(root2.items[1].label, "clothes", 1, true) and root2.items[2] and root2.items[2].label == "Black market") then
            problems[#problems + 1] = "the Resistance's F2: clothes and the black market first"
        end
        if faction == "admin" and not (root2.items[1] and root2.items[1].label == "Sociostability") then problems[#problems + 1] = "the Administrator's F2: sociostability first" end
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
        WalkQ(root2, 0)
        -- F2, as the server answers gm_showteam: opens, draws, and F1 swaps to its own; F2 again closes it
        local okF2, errF2 = pcall(net["recv_lcg_quick2"])
        if not okF2 then problems[#problems + 1] = "F2 (" .. faction .. "): " .. tostring(errF2)
        elseif not LC_CL.QuickOpen("role") then problems[#problems + 1] = "F2 didn't open its quick menu (" .. faction .. ")" end
        local okH2, errH2 = pcall(function() for id, fn in pairs(hook.t.HUDPaint or {}) do if id == "LivingCityQuick" then fn() end end end)
        if not okH2 then problems[#problems + 1] = "F2's quick menu drawing (" .. faction .. "): " .. tostring(errH2) end
        pcall(net["recv_lcg_quick2"])
        if LC_CL.QuickOpen() then problems[#problems + 1] = "F2 again didn't close its quick menu (" .. faction .. ")" end
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
    Quick("vort") Quick("stalker") Quick("zombie")
    Quick("citizen", function() _me.nw.lcj_job, _me.nw.lc_ration_break = "mortuary", true end)
    Quick("resistance", function() _me.nw.lc_squad_n = 2 other.nw.lcf_faction = "vort" Look(other) end)
    -- nothing at all for their side or job (the infested; a plain citizen has Me > now): F2 says so, briefly
    do
        _me.nw = { lcf_faction = "zombie", lce_standing = 10 }
        _me.IsAdmin = function() return false end
        Look(nil)
        local okE, e2 = pcall(LC_CL.QuickRoleRoot)
        if not okE then problems[#problems + 1] = "an empty F2: " .. tostring(e2)
        elseif e2.items[1] or not e2.empty then problems[#problems + 1] = "an empty F2 should say there's nothing for them, not list " .. tostring(e2.items[1] and e2.items[1].label)
        else
            LC_CL.OpenQuick2()
            local okH3, errH3 = pcall(function() for id, fn in pairs(hook.t.HUDPaint or {}) do if id == "LivingCityQuick" then fn() end end end)
            if not okH3 then problems[#problems + 1] = "an empty F2 drawing: " .. tostring(errH3) end
            LC_CL.OpenQuick()
            if not LC_CL.QuickOpen("general") then problems[#problems + 1] = "F1 with F2 open didn't swap to F1" end
            LC_CL.CloseQuick()
        end
    end
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
        LC_CL.OpenDesk(With({ kind = "register", papers = true, needWork = true, laborDesk = true, awaiting = true, housingDesk = true }))
        LC_CL.OpenDesk(With({ kind = "housing", awaiting = true, needWork = true, papers = true }))
        LC_CL.OpenDesk(With({ kind = "labor", labor = { registered = false } }))
        LC_CL.OpenDesk(With({ kind = "labor", labor = { registered = true, canWork = false } }))
        LC_CL.OpenDesk(With({ kind = "labor", labor = { registered = true, canWork = true, papers = true, first = true, minMinutes = 30, minShifts = 4, housingNext = true } }))
        LC_CL.OpenDesk(With({ kind = "labor", labor = { registered = true, canWork = true, papers = true, jobName = "Courier", place = "Post office", locked = true,
            minsLeft = 12, shiftsLeft = 3, mins = 18, shifts = 1 } }))
        LC_CL.OpenDesk(With({ kind = "labor", labor = { registered = true, canWork = true, papers = false, standing = 30, wait = 200, minMinutes = 30, minShifts = 4,
            jobs = { { num = 5, id = "courier", name = "Courier", place = "Post office", current = true },
                { num = 15, id = "cleanup", name = "Infestation Cleanup", place = "the infestation", desc = "Into the infestation." },
                { num = 7, id = "porter", name = "Intake Processor", place = "Train station", locked = "needs Civil Standing 50 (yours is 30)" } } } }))
        LC_CL.OpenLab({ credits = 50, items = { { id = "gun_pistol", name = "Homemade pistol", desc = "A pistol", secs = 12, price = 72, canPay = false, canMats = true,
            mats = { { name = "Gun parts", have = 2, need = 2 } } } } })
        LC_CL.OpenLab({ credits = 0, busy = 5, items = {} })
        -- pulling the chip (the owner, 8 November), ready and not yet
        LC_CL.OpenLab({ credits = 600, items = {}, chip = { price = 500, ok = true } })
        LC_CL.OpenLab({ credits = 0, items = {}, chip = { price = 500, ok = false, why = "Not yet. You've only lived through 1 of the city's dreams." } })
        -- C > My career (cl_livingcity_career.lua)
        LC_CL.OpenCareer({ faction = "Civil Protection", xp = 312, rank = 2, conditioned = false,
            ranks = { { name = "Recruit", xp = 0 }, { name = "Metrocop", xp = 150 }, { name = "Division Leader", xp = 600 }, { name = "Combine Soldier", xp = 2000, overwatch = true } },
            steps = { "Earn 288 more XP to make Division Leader.", "Nothing you fail locks you out." }, canReassess = false, reassessIn = 1200 })
        LC_CL.OpenCareer({ none = true })
        for id, fn in pairs(hook.t.Think or {}) do if id == "LivingCityLabSmoke" then fn() end end
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
    -- F4: one window with tabs, Jobs (first), Career and Factions; the last tab looked at is remembered (cl_livingcity_hub.lua)
    do
        local rcc, ask, j2t = RunConsoleCommand, LC_CL.AskCareer, util.JSONToTable
        local asked = {}
        RunConsoleCommand = function(c) asked[c] = true end
        LC_CL.AskCareer = function() asked.career = true end
        local okHub, errHub = pcall(function()
            LC_CL.CloseHub()
            net["recv_lc_hub"]()
            if not LC_CL.HubOpen() then error("F4 didn't open the window") end
            if LC_CL.HubTab() ~= "jobs" then error("a new session's F4 should open on Jobs, not " .. tostring(LC_CL.HubTab())) end
            if next(asked) then error("F4 asked the server again for what it's already sending") end
            util.JSONToTable = function() return { board = "Jobs", faction = "citizen", active = false, traits = { loyalty = 2 }, wait = 0,
                postings = { { id = 7, title = "Sweep the plaza", desc = "Push the cart.", reward = 20, limit = 300, taken = 0, max = 1 },
                    { id = 8, title = "A story", desc = "Yours.", reward = 50, story = true, taken = 0, max = 1 } },
                jobs = { current = "courier", list = { { id = "courier", name = "Courier", path = "" } } } } end
            net._q = { 1 }
            net["recv_lcq_board"]()
            util.JSONToTable = function() return { current = "citizen", special = "", admin = true, factions = { { id = "citizen", xp = 0, rank = 1, ok = true, specials = {} },
                { id = "cp", xp = 0, rank = 1, ok = false, why = "Not yet", specials = {}, reqs = { { label = "Civil Standing", have = 40, need = 100 } } } } } end
            net._q = { 1 }
            net["recv_lcf_menu"]()
            LC_CL.OpenCareer({ faction = "Civil Protection", xp = 312, rank = 2, conditioned = false, canReassess = true,
                ranks = { { name = "Recruit", xp = 0 }, { name = "Metrocop", xp = 150 }, { name = "Combine Soldier", xp = 2000, overwatch = true } }, steps = { "Earn more XP." } })
            if LC_CL.HubTab() ~= "jobs" then error("the tabs' content moved F4 off the tab it opened on") end
            -- every tab shows, and the last one looked at is where F4 opens next time
            for _, t in ipairs({ "career", "factions" }) do
                LC_CL.OpenHub(t, true)
                if LC_CL.HubTab() ~= t then error("F4's " .. t .. " tab didn't show") end
            end
            LC_CL.CloseHub()
            if LC_CL.HubOpen() then error("the window didn't close") end
            net["recv_lc_hub"]()
            if LC_CL.HubTab() ~= "factions" then error("F4 forgot the last tab (opened on " .. tostring(LC_CL.HubTab()) .. ")") end
            LC_CL.CloseHub()
            -- !jobs, or the board again after taking a job: the window opens on Jobs and asks for the other two
            asked = {}
            util.JSONToTable = function() return { board = "Directives", postings = {}, active = true, traits = {}, wait = 0 } end
            net._q = { 1 }
            net["recv_lcq_board"]()
            if LC_CL.HubTab() ~= "jobs" or not asked.lcf_menu or not asked.career or asked.lcq_board then error("the board on its own didn't open Jobs and ask for the rest") end
            LC_CL.CloseHub()
            -- C > My career: the window on the Career tab, everything asked for
            asked = {}
            LC_CL.OpenHub("career")
            if LC_CL.HubTab() ~= "career" or not (asked.lcq_board and asked.lcf_menu and asked.career) then error("C > My career didn't open F4 on Career") end
            LC_CL.OpenCareer({ none = true })
            LC_CL.CloseHub()
        end)
        if not okHub then problems[#problems + 1] = "F4 (jobs, career, factions): " .. tostring(errHub) end
        RunConsoleCommand, LC_CL.AskCareer, util.JSONToTable = rcc, ask, j2t
    end
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
        ["!escort"] = "escort", ["!inv, !craft, !give"] = "console:gm_showspare1", ["!jobs, !abandon"] = "console:lcq_board",
        ["!faction"] = "console:lcf_menu", ["!help"] = "console:lc_help", ["!hints (read them again)"] = "net:lc_hints_list",
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
-- a unit's search as a pat-down (cl_livingcity_patsearch.lua): the unit's window builds, updates, paints; the panel
-- for the person searched; both close; a window that can't be built hands back to the old search
local psSaved = { net.ReadString, util.JSONToTable, vgui, net.SendToServer, net.Start, net.WriteUInt }
local okPS, errPS = pcall(function()
    local doc, sent, made = nil, {}, {}
    local curName
    net.ReadString = function() return "x" end
    util.JSONToTable = function() return doc end
    net.Start = function(n) curName = n end
    net.WriteUInt = function() end
    net.SendToServer = function() sent[#sent + 1] = curName end
    local function P()
        local t = {}
        made[#made + 1] = t
        return setmetatable(t, { __index = function(_, k)
            if string.sub(k, 1, 2) == "lc" or string.sub(k, 1, 1) == "_" or k == "silent" or k == "spots" or k == "wasDown" then return nil end
            if k == "IsValid" then return function() return not t._removed end end
            if k == "Remove" then return function() t._removed = true if t.OnRemove then t.OnRemove(t) end end end
            if k == "GetWide" or k == "GetTall" then return function() return 380 end end
            if k == "IsHovered" or k == "GetDisabled" then return function() return false end end
            return function() return P() end
        end })
    end
    vgui = { Create = function() return P() end, GetKeyboardFocus = function() return nil end }
    local four = function(a, b, c, d) return { { name = "Jacket", state = a }, { name = "Waist", state = b }, { name = "Legs", state = c }, { name = "Boots", state = d } } end
    doc = { role = "unit", who = "Citizen", live = false, secs = 1, spots = four(0, 0, 0, 0) }
    net.recv_lc_pat_open()
    if not IsValid(LC_CL.PatSearchWindow()) then error("the unit's pat-down window didn't build") end
    if sent[#sent] ~= "lc_pat_check" then error("the window didn't tell the server it's open") end
    doc = { role = "unit", who = "Citizen", live = true, checking = 2, secs = 1, flash = "They tried to move something: Lockpick", flashId = 1, spots = four(2, 1, 2, 0) }
    doc.spots[1].text, doc.spots[3].text = "Lockpick", "Nothing."
    net.recv_lc_pat_open()
    doc = { role = "target", who = "Unit", key = "R", slip = "ready", checking = 2, spots = four(2, 1, 0, 0) }
    for _, s in ipairs(doc.spots) do s.mine = "" end
    doc.spots[2].mine = "Old radio"
    net.recv_lc_pat_open()
    if not IsValid(LC_CL.PatSearchPanel()) then error("no panel for the person searched") end
    for _, pnl in ipairs(made) do
        for _, k in ipairs({ "Paint", "Think", "PerformLayout", "DoClick" }) do
            local f = rawget(pnl, k)
            if f then local okp, e = pcall(f, pnl, 380, 240) if not okp then error("a panel's " .. k .. " fails: " .. tostring(e)) end end
        end
    end
    local n0 = #sent
    net.recv_lc_pat_close()
    if IsValid(LC_CL.PatSearchWindow()) or IsValid(LC_CL.PatSearchPanel()) then error("the pat-down didn't close") end
    if #sent ~= n0 then error("closing on the server's word sent a close back") end
    vgui = { Create = function() error("no vgui") end, GetKeyboardFocus = function() return nil end }
    doc = { role = "unit", who = "Citizen", live = false, secs = 1, spots = four(0, 0, 0, 0) }
    net.recv_lc_pat_open()
    if sent[#sent] ~= "lc_pat_close" or IsValid(LC_CL.PatSearchWindow()) then error("a window that fails to build doesn't hand back") end
end)
net.ReadString, util.JSONToTable, vgui, net.SendToServer, net.Start, net.WriteUInt = psSaved[1], psSaved[2], psSaved[3], psSaved[4], psSaved[5], psSaved[6]
if not okPS then problems[#problems + 1] = "pat-down search: " .. tostring(errPS) end
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
-- resisting arrest (cl_livingcity_arrest.lua): the struggle bar, E counted as a press, then gone
local okAR, errAR = pcall(function()
    local rB, rS, rF, rU = net.ReadBool, net.ReadString, net.ReadFloat, net.ReadUInt
    local q = { true, "resist", "Unit 12", CurTime() + 4, 3, 5, 1.25, 2 }
    local function nx() return table.remove(q, 1) end
    net.ReadBool, net.ReadString, net.ReadFloat, net.ReadUInt = nx, nx, nx, nx
    net["recv_lc_struggle"]()
    net.ReadBool, net.ReadString, net.ReadFloat, net.ReadUInt = rB, rS, rF, rU
    local s = LC_CL.Struggle
    if not s or s.role ~= "resist" or s.mine ~= 3 then error("struggle not read") end
    run("HUDPaint")
    local blocked
    for _, fn in pairs(hook.t.PlayerBindPress or {}) do
        local r = fn(_me, "+use", true)
        if r then blocked = true end
    end
    if not blocked or LC_CL.Struggle.mine ~= 4 then error("E not taken as a press") end
    local share = LC_CL.StruggleShare(LC_CL.Struggle)
    if share <= 0 or share >= 0.5 then error("share wrong: " .. tostring(share)) end
    net.ReadBool = function() return false end
    net["recv_lc_struggle"]()
    net.ReadBool = rB
    if LC_CL.Struggle then error("not cleared") end
end)
if not okAR then problems[#problems + 1] = "resisting arrest: " .. tostring(errAR) end
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
-- the performance debugger's window (cl_livingcity_perfdebug.lua): open, the server's figures, your own game measured alongside, copy, print, close
local pdWas = { net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable, net.SendToServer, net.Start, net.WriteString, hook.GetTable, vgui }
local pdFrames = {}
local function PDPanel()
    return setmetatable({}, { __index = function(t, k)
        if k == "IsValid" then return function() return not rawget(t, "_removed") end end
        if k == "Remove" then return function() rawset(t, "_removed", true) if rawget(t, "OnRemove") then t:OnRemove() end end end
        return function() return t end
    end })
end
local okPD, errPD = pcall(function()
    local P = LC.PerfDebug
    if not (P and LC_CL.PerfDebugMenu) then error("not loaded") end
    local sentPD, cur = {}, nil
    net.Start = function(n) cur = { name = n, data = {} } end
    net.WriteString = function(v) if cur then table.insert(cur.data, v) end end
    net.SendToServer = function() sentPD[#sentPD + 1] = cur end
    hook.GetTable = function() return hook.t end
    vgui = { Create = function(c) local p = PDPanel() if c == "DFrame" then pdFrames[#pdFrames + 1] = p end return p end, GetKeyboardFocus = function() return nil end }
    LC_CL.PerfDebugMenu()
    if not (sentPD[1] and sentPD[1].name == "lc_perfdebug_cmd" and sentPD[1].data[1] == "watch") then error("didn't ask the server for its figures") end
    local doc = { side = "server", on = true, secs = 12, spikeMs = 60, frames = { n = 700, avg = 15.2, max = 240, buckets = { 690, 5, 3, 2 }, base = 15 }, luaPct = 22,
        hooks = { { k = "Think / LivingCityNPCs", n = 700, ms = 900, avg = 1.2, max = 30, pct = 7.5 } }, timers = {},
        recv = { { k = "lc_x", n = 3, ms = 1, avg = 0.3, max = 0.5, pct = 0, bytes = 90, unhandled = 1, kbs = 0 } },
        sent = { { k = "lc_data", n = 4, bytes = 40000, to = 8, kbs = 20 } }, nw = { { k = "NW2 lc_char", calls = 5000, changes = 20, cps = 2 } }, senders = {},
        spikes = { { at = "20:00:00", ms = 240, lua = 200, top = { { k = "hook: Think / LivingCityNPCs", ms = 190 } }, players = 5 } }, spikeCount = 1, floods = {},
        history = { { t = 10, ents = 900, npcs = 60, mem = 200000, edicts = 1500, players = 5 } }, growth = { { k = "prop_physics", from = 10, to = 200, diff = 190 } },
        mem = 200000, memPeak = 210000, allocKBs = 900, hooksWrapped = 300, players = { { k = "Someone", ping = 80, loss = 0, kbs = 3, queue = 0, loading = "no" } },
        map = "rp_c18_ug", playerCount = 5, tickRate = 66, cityNPCs = 60, startedBy = "Admin", left = 1700,
        cityTimers = { { k = "LivingCityThink", n = 10, ms = 50, avg = 5, max = 9 } } }
    net.ReadUInt = function() return 1 end
    net.ReadData = function() return "x" end
    util.Decompress = function(s) return s end
    util.JSONToTable = function() return doc end
    net["recv_lc_perfdebug"]()
    if not P.on then error("your own game didn't start measuring with the server") end
    for _ = 1, 3 do run("Think") _advance(1.2) end
    if P.stats.frames.n < 1 then error("your game's frames weren't measured") end
    LC_CL.PerfDebugRefresh()
    local text = LC_CL.PerfDebugReports()
    if not string.find(text, "LivingCityNPCs", 1, true) or not string.find(text, "performance report (client)", 1, true) then error("reports missing: " .. string.sub(text, 1, 200)) end
    concommand.list.lc_perfdebug_print(nil)
    pdFrames[1]:Remove()
    if P.on then error("still measuring your game after the window closed") end
    if sentPD[#sentPD].data[1] ~= "unwatch" then error("didn't tell the server the window closed") end
end)
net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable, net.SendToServer, net.Start, net.WriteString, hook.GetTable, vgui = unpack(pdWas)
if LC.PerfDebug and LC.PerfDebug.on then LC.PerfDebug.Stop() end
if not okPD then problems[#problems + 1] = "performance debugger: " .. tostring(errPD) end
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
# shared dreams (cl_livingcity_dreams.lua): the dreamer's line on screen, the admins' window
err = L.execute(r"""
local ok, e = pcall(function()
    _me:SetNW2Bool("lc_dreaming", true)
    hook.t.HUDPaint.LivingCityDreams()
    _me:SetNW2Bool("lc_dreaming", false)
    local st = { on = true, point = true, zone = false, queued = "hard", queuedName = "Hard", at = 40, every = false, delay = 60,
        active = { ending = "hard", name = "Hard", n = 2 }, asleep = 3, saved = { { sid = "1", nick = "Someone", online = true, applied = true } },
        endings = { { id = "hard", name = "Hard" } } }
    net._q = { st }
    net["recv_lc_dream"]()
    st.active, st.point, st.queued = nil, false, nil
    net._q = { st }
    net["recv_lc_dream"]()
    LC_CL.DreamsMenu()
    LC_CL.DreamAct("optout")
    -- the Administrator's tablet: tonight's dream, by mood
    local office = { jobs = {}, people = {}, manpower = { "Civil Protection: 13 in reserve (of 20), 2 lost today", "Next unit in about 4 minutes" }, dream = { ready = true, at = 30,
        groups = { { mood = "happy", name = "Happy", endings = { { id = "bus", name = "The Bus" } } }, { mood = "neutral", name = "Neutral", endings = {} },
            { mood = "nightmare", name = "Nightmare", endings = { { id = "water", name = "The Flood" } } } },
        waiting = { id = "bus", name = "The Bus", mood = "Happy", yours = true } } }
    for _, d in ipairs({ office.dream, { ready = true, groups = office.dream.groups, waiting = { id = "water", name = "The Flood", mood = "Nightmare" } },
        { ready = true, dreamt = true, groups = office.dream.groups }, { ready = false, why = "No dream point" } }) do
        office.dream = d
        local j2t = util.JSONToTable
        util.JSONToTable = function() return office end
        net._q = { 1, "x" }
        local okO, errO = pcall(net["recv_lc_admin_office"])
        util.JSONToTable = j2t
        if not okO then error("the office: " .. tostring(errO)) end
    end
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "dreams (client) " + str(err)
# the nightmare dreams you play (cl_livingcity_dreamgames.lua): tokens, lives, time, FREEZE
err = L.execute(r"""
local ok, e = pcall(function()
    _me:SetNW2Bool("lc_dreaming", true)
    local function Msg(t) net._q = { t } net["recv_lc_dreamgame"]() end
    Msg({ k = "start", id = "maze", name = "The Patrol Maze", goal = "Pick up every token.", ends = CurTime() + 300, lives = 3, maxLives = 3,
        tokens = { { 0, 0, 36, 0 }, { 10, 0, 36, 1 } }, left = 2 })
    Msg({ k = "got", i = 1 })
    Msg({ k = "state", lives = 2, left = 1, afraid = CurTime() + 5 })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    if not LC_CL.DreamGame() or LC_CL.DreamGame().left ~= 1 then error("the game's state on screen") end
    Msg({ k = "start", id = "freeze", name = "Freeze, Citizen", goal = "Stand still when he turns.", ends = CurTime() + 100, lives = 3, maxLives = 3 })
    Msg({ k = "state", lives = 3, phase = "red" })
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "state", lives = 3, phase = "green" })
    hook.t.HUDPaint.LivingCityDreamGames()
    -- an Enforcer (sv_livingcity_dreamenforcers.lua): their own line, no lives; the bad dreamers glow red
    Msg({ k = "start", id = "maze", name = "The Patrol Maze", goal = "You're an Enforcer.", ends = CurTime() + 300, lives = 1, maxLives = 1, enforcer = true })
    hook.t.HUDPaint.LivingCityDreamGames()
    _me:SetNW2Bool("lc_enforcer", true)
    _me:SetNW2Float("lc_dream_bad_until", CurTime() + 20)
    hook.t.PreDrawHalos.LivingCityDreamEnforce()
    hook.t.HUDPaint.LivingCityDreamEnforce()
    _me:SetNW2Bool("lc_enforcer", false)
    hook.t.HUDPaint.LivingCityDreamEnforce()
    _me:SetNW2Float("lc_dream_bad_until", 0)
    -- vortigaunt dream warfare (cl_livingcity_vortwar.lua): their light, the purple screen, the meter; gone again
    Msg({ k = "start", id = "harvest", name = "Record Harvest", goal = "Bring it in.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "harvest" })
    Msg({ k = "state", lives = 3, vw = { meter = 0.4, light = true, spots = { { 0, 0, 0 }, { 200, 0, 0 } }, r = 120 } })
    if not (LC_CL.VortWar and LC_CL.VortWar()) then error("the vortigaunts' state on screen") end
    hook.t.RenderScreenspaceEffects.LivingCityVortWar()
    hook.t.PostDrawTranslucentRenderables.LivingCityVortWar(false, false)
    hook.t.HUDPaint.LivingCityVortWar()
    Msg({ k = "state", lives = 3, vw = { meter = -0.6, light = false, spots = { { 0, 0, 0 } }, r = 120 } })
    hook.t.HUDPaint.LivingCityVortWar()
    Msg({ k = "state", lives = 3, vw = false })
    if LC_CL.VortWar() then error("the vortigaunts gone from the screen") end
    hook.t.HUDPaint.LivingCityVortWar()
    Msg({ k = "start", id = "crumble", name = "The Crumbling Floor", goal = "Keep moving.", ends = CurTime() + 100, lives = 1, maxLives = 1 })
    Msg({ k = "state", lives = 1, alive = 2 })
    hook.t.HUDPaint.LivingCityDreamGames()
    -- propaganda dreams: the admiring ones pink, hearts, roses, a meter, her music
    Msg({ k = "start", id = "roses", name = "Roses for Her", goal = "Lay roses at her feet.", ends = CurTime() + 100, lives = 3, maxLives = 3,
        theme = "admire", her = { 0, 0, 200 }, song = "livingcity/dreams/administrator/x.mp3" })
    Msg({ k = "state", lives = 3, roses = { { 10, 10, 20 } }, meter = 33, meterName = "Roses given: 1 of 3", carrying = true, big = "Kneel.", tone = "warn" })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "state", lives = 3, meter = 50, meterName = "Devotion", big = "Kneel, and gaze up at her.", tone = "love" })
    hook.t.HUDPaint.LivingCityDreamGames()
    -- The Saviour: the glow, her lines, the music switch; the quiz; the star
    Msg({ k = "start", id = "saviour", name = "The Saviour", goal = "Hold on.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "glory", herEnt = 1, her = { 0, 0, 100 } })
    Msg({ k = "state", lives = 3, light = true, big = "She has come.", tone = "love", meterName = "The dead: 4" })
    Msg({ k = "line", who = "The Administrator", text = "STOP!", snd = "livingcity/dreams/voice/saviour_stop1.wav" })
    Msg({ k = "music", song = "livingcity/dreams/saviour1.mp3" })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "quiz", name = "The Loyalty Quiz", goal = "Answer.", ends = CurTime() + 100, lives = 1, maxLives = 1, theme = "propaganda", star = true })
    Msg({ k = "state", big = "Who keeps you safe at night?", tone = "love" })
    hook.t.HUDPaint.LivingCityDreamGames()
    -- the ten more: glows, boards, her portrait in cards, clues, black and white, NOW for the flowers
    Msg({ k = "start", id = "harvest", name = "Record Harvest", goal = "Bring it in.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "harvest" })
    Msg({ k = "state", lives = 3, glows = { { 1, 2, 3, 1 }, { 4, 5, 6, 2 } }, board = { 0, 0, 100, 180, title = "THE PEOPLE'S HARVEST", lines = { "Plan: 100%", "Achieved: 1,234%" } },
        carryName = "a ration crate", meter = 20, meterName = "Crates delivered: 1 of 5" })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "hate", name = "Two Minutes of Hate", goal = "Jeer.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "hate" })
    Msg({ k = "state", lives = 3, board = { 0, 0, 100, 180, title = "ENEMY OF THE PEOPLE", lines = { "Report." }, face = "freeman" }, big = "Jeer!", tone = "warn" })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "massgames", name = "The Mass Games", goal = "Flip.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "propaganda" })
    Msg({ k = "state", lives = 3, mosaic = { 0, 0, 60, 180, shown = 0.4 }, big = "Picture 4: your card is GOLD (crouch)" })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "spy", name = "Careless Talk", goal = "Report.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "propaganda" })
    Msg({ k = "state", lives = 3, notes = { "The voice that said it was a woman's." }, meterName = "Clues: 1 of 3" })
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "newsreel", name = "The Newsreel", goal = "Smile.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "newsreel" })
    hook.t.RenderScreenspaceEffects.LivingCityDreamGames()
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "flowers", name = "Flowers for the Liberators", goal = "Throw.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "propaganda" })
    Msg({ k = "state", lives = 3, marchers = { 1, 2 }, nowR = 70, big = "Stay off the road." })
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "duck", name = "Duck and Cover", goal = "Duck.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "civil" })
    Msg({ k = "state", lives = 3, glows = { { 1, 2, 3, 5 }, { 1, 2, 3, 7 } }, big = "ROCKET LAUNCH!", tone = "warn", rocket = 1 })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "ravenholm", name = "Ravenholm", goal = "Run.", ends = CurTime() + 100, lives = 1, maxLives = 1, theme = "graveyard" })
    Msg({ k = "state", lives = 1, villains = { 1 }, storm = { 0, 0, 0, t = CurTime() - 1 }, truth = true, big = "A green storm..." })
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "stop", how = "won" })
    hook.t.HUDPaint.LivingCityDreamGames()
    if LC_CL.DreamGame() then error("still on screen after it stopped") end
    _me:SetNW2Bool("lc_dreaming", false)
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "dream games (client) " + str(err)
# the strange dreams (cl_livingcity_strangedreams.lua): the cheese dream's voices in the dark and its colours, wings' rings;
# and testing a dream from the Living City Editor's panel (cl_livingcity_dreams.lua, the editor tool)
L.globals()["_editor_tool"] = open(os.path.join(os.path.dirname(GMDIR), "..", "lua", "weapons", "gmod_tool", "stools", "livingcity_editor.lua")).read()
err = L.execute(r"""
local ok, e = pcall(function()
    _me:SetNW2Bool("lc_dreaming", true)
    local function Msg(t) net._q = { t } net["recv_lc_dreamgame"]() end
    Msg({ k = "start", id = "cheese", name = "The Cheese Dream", goal = "Gather.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "cheese",
        intro = CurTime() + 8, lines = { "vo/npc/male01/question06.wav", "vo/npc/female01/question06.wav" } })
    hook.t.Think.LivingCityStrangeDreams()
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    hook.t.HUDPaint.LivingCityStrangeDreams()
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "state", lives = 3, intro = CurTime() - 1, flip = CurTime() + 3, glows = { { 0, 0, 30, 1 }, { 1, 1, 30, 6 } }, meter = 40, meterName = "Cheese: 4 of 10" })
    hook.t.Think.LivingCityStrangeDreams()
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    hook.t.PostDrawTranslucentRenderables.LivingCityStrangeDreams(false, false)
    hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "flying", name = "Wings", goal = "Fly.", ends = CurTime() + 100, lives = 1, maxLives = 1, theme = "flying", center = { 0, 0, 0 }, ceiling = 900 })
    Msg({ k = "state", lives = 1, rings = { { 0, 0, 300 }, { 100, 0, 400 } }, meterName = "Rings: 1 of 8" })
    hook.t.PostDrawTranslucentRenderables.LivingCityStrangeDreams(false, false)
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "melons", name = "It's Raining Melons", goal = "Catch.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "melons" })
    Msg({ k = "state", lives = 3, glows = { { 0, 0, 6, 5 }, { 50, 0, 6, 7 } } })
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "start", id = "chairs", name = "Musical Chairs", goal = "Sit.", ends = CurTime() + 100, lives = 1, maxLives = 1, theme = "chairs" })
    Msg({ k = "music" })
    Msg({ k = "state", lives = 1, phase2 = "sit", big = "SIT! Crouch beside a free chair!", tone = "warn", glows = { { 0, 0, 30, 6 } } })
    hook.t.HUDPaint.LivingCityDreamGames()
    -- the ten more: each theme's screen draws
    Msg({ k = "start", id = "horse", name = "Hooves and All", goal = "Bite.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = "horse",
        intro = CurTime() + 8, introSecs = 9, lines = { "vo/npc/male01/question09.wav", "livingcity/dreams/voice/horse_intro_female1.mp3" }, introText = { "I'm so hungry...", "...a horse." } })
    hook.t.Think.LivingCityStrangeDreams()
    hook.t.HUDPaint.LivingCityStrangeDreams()
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    Msg({ k = "state", lives = 3, intro = CurTime() - 1, horse = 1, stunned = true, big = "NOW! Take a bite (E)!" })
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    hook.t.PostDrawTranslucentRenderables.LivingCityStrangeDreams(false, false)
    hook.t.HUDPaint.LivingCityDreamGames()
    local themes = {
        { "boxing", { ring = { 0, 0, 0, 300 }, foe = 1, windup = true, meterName = "Lamarr: 3 of 20" } },
        { "exam", { board = { 0, 0, 100, 180, title = "QUESTION 1 OF 6", lines = { "Solve for X.", "A: X" } }, glows = { { 0, 0, 8, 1 } } } },
        { "train", { door = 1, watched = true, big = "The last train leaves in 1:00" } },
        { "lamarr", { glows = { { 0, 0, 30, 1 } } } },
        { "molasses", { glows = { { 0, 0, 40, 5 } } } },
        { "potato", { nade = 1, big = "YOU HAVE THE GRENADE!", tone = "warn" } },
        { "simon", { big = "OVERWATCH SAYS: JUMP!", tone = "warn" } },
        { "dance", { bpm = 100, beat0 = CurTime() - 2.4 } },
        { "sheep", { big = "How many headcrabs?" } },
        { "clocks", { glows = { { 0, 0, 100, 7 } }, big = "It's twenty-five o'clock." } },
        { "tea", { glows = { { 0, 0, 30, 5 } }, big = "Change places! Move down 2!", tone = "warn" } },
        { "derby", { glows = { { 0, 0, 8, 1 } }, big = "And they're off!" } },
        { "photo", { flash = CurTime(), scanner = 1, big = "SAY CHEESE!" } },
        { "doors", { glows = { { 0, 0, 60, 6 } } } },
        { "paint", { colour = { 255, 80, 180 }, meterName = "Your tiles: 3" } },
        { "conga", { conga = { 1, 2 }, glows = { { 0, 0, 10, 4 } } } },
        { "shh", { noise = 80, crying = false } },
        { "bubbles", { bubbles = { { 0, 0, 30, CurTime() - 1, 1 }, { 10, 0, 30, CurTime(), 2 }, { 20, 0, 30, CurTime(), 3 } }, rise = 45 } },
        { "watchers", { watchers = { 1 }, glows = { { 0, 0, 30, 5 } } } },
    }
    for _, th in ipairs(themes) do
        Msg({ k = "start", id = th[1], name = th[1], goal = "Go.", ends = CurTime() + 100, lives = 3, maxLives = 3, theme = th[1] })
        local t = th[2]
        t.k, t.lives = "state", 3
        Msg(t)
        hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
        hook.t.PostDrawTranslucentRenderables.LivingCityStrangeDreams(false, false)
        hook.t.PostDrawTranslucentRenderables.LivingCityDreamGames(false, false)
        hook.t.HUDPaint.LivingCityStrangeDreams()
        hook.t.HUDPaint.LivingCityDreamGames()
    end
    if not LC_CL.DanceBeat({ bpm = 120, beat0 = CurTime() - 2 }, CurTime()) then error("the dance's beat") end
    -- the nonsense: floating things, faces, effects (fakes for the client-only pieces)
    local cmWas, fbcWas = ClientsideModel, ents.FindByClass
    local made = 0
    local function Proxy() made = made + 1 return setmetatable({ IsValid = function() return true end, GetFlexNum = function() return 3 end }, { __index = function() return function() end end }) end
    ClientsideModel = function() return Proxy() end
    local fakeE = setmetatable({ IsValid = function() return true end, GetModel = function() return "models/humans/group01/male_07.mdl" end,
        GetNW2Bool = function(_, k) return k == "lc_dream_face" end, GetNW2Int = function(_, k) return k == "lc_dream_fx" and 1023 or 0 end,
        EntIndex = function() return 7 end, GetPos = function() return Vector(0, 0, 0) end, GetAngles = function() return Angle(0, 0, 0) end,
        OBBMaxs = function() return Vector(10, 10, 72) end, GetModelScale = function() return 1 end, GetColor = function() return Color(255, 255, 255) end,
        GetMaterial = function() return "" end, GetSequence = function() return 0 end, GetCycle = function() return 0 end },
        { __index = function() return function() end end })
    ents.FindByClass = function(c) if c == "prop_dynamic" then return { fakeE } end return {} end
    _me:SetNW2Bool("lc_dreaming", true)
    Msg({ k = "start", id = "conga", name = "Conga!", goal = "Go.", ends = CurTime() + 100, lives = 1, maxLives = 1, theme = "conga" })
    _advance(1)
    hook.t.Think.LivingCityStrangeNonsense()
    if #LC_CL.StrangeFloaters() ~= 12 then error("the nonsense: nothing floating in the sky") end
    if not LC_CL.DreamFaces()[fakeE] or not fakeE.RenderOverride then error("the nonsense: no face on a marked figure") end
    fakeE:RenderOverride()
    if #LC_CL.DreamFxList ~= 1 or not LC_CL.DreamFxHas(1023, 10) then error("the nonsense: no effects on a marked thing") end
    hook.t.PostDrawTranslucentRenderables.LivingCityStrangeDreams(false, false)
    hook.t.RenderScreenspaceEffects.LivingCityStrangeDreams()
    local r = LC_CL.DreamVoiceRate({ theme = "conga" })
    if r and (r < 0.7 or r > 1.4) then error("a line's speed out of range") end
    Msg({ k = "stop", how = "won" })
    hook.t.Think.LivingCityStrangeNonsense()
    if #LC_CL.StrangeFloaters() ~= 0 then error("the nonsense stayed after the dream") end
    ClientsideModel, ents.FindByClass = cmWas, fbcWas
    Msg({ k = "stop", how = "won" })
    -- as the dream comes: the screen black, and the day's mood in a line (cl_livingcity_dreams.lua)
    net._q = { { text = "Today the city was calm. You slip off into a happy dream, and it goes on long enough to need a second line on a narrow screen.", til = CurTime() + 5, kind = "happy" } }
    net["recv_lc_dream_mood"]()
    _advance(2)
    hook.t.DrawOverlay.LivingCityDreamMood()
    if not LC_CL.DreamMoodShown() then error("the dream's black screen and its line") end
    _advance(10)
    hook.t.DrawOverlay.LivingCityDreamMood()
    if LC_CL.DreamMoodShown() then error("the black screen stayed after the dream began") end
    -- the Administrator, lying down on a night she didn't choose: dream it, or sleep through it
    net._q = { { skip = true } }
    net["recv_lc_dream_ask"]()
    if not LC_CL.DreamAskOpen() then error("the Administrator isn't asked about tonight's dream") end
    local said = {}
    local ws, wb, ss = net.WriteString, net.WriteBool, net.SendToServer
    net.WriteString = function(v) said[#said + 1] = v end
    net.WriteBool = function(v) said[#said + 1] = v end
    net.SendToServer = function() end
    LC_CL.DreamAskAnswer("join", true)
    net.WriteString, net.WriteBool, net.SendToServer = ws, wb, ss
    if said[1] ~= "join" or said[2] ~= true or LC_CL.DreamAskOpen() then error("her answer didn't reach the server") end
    -- a test: the line at the top says so
    _me:SetNW2Bool("lc_dream_test", true)
    hook.t.HUDPaint.LivingCityDreams()
    _me:SetNW2Bool("lc_dream_test", false)
    _me:SetNW2Bool("lc_dreaming", false)
    -- the editor's panel: Dreams: test one
    local buttons, combos = {}, {}
    local function Thing() return setmetatable({ IsValid = function() return true end }, { __index = function() return function() end end }) end
    local function Combo()
        local c = Thing()
        c.choices = {}
        c.Clear = function(self) self.choices = {} end
        c.AddChoice = function(self, text, data) self.choices[#self.choices + 1] = { text, data } end
        c.GetSelected = function(self) local f = self.choices[1] if f then return f[1], f[2] end end
        return c
    end
    local cp = setmetatable({}, { __index = function(_, k)
        if k == "Button" then return function(_, text) local b = Thing() buttons[text] = b return b end end
        if k == "ComboBox" then return function(_, text) local c = Combo() combos[text] = c return c end end
        return function() return Thing() end
    end })
    TOOL = {}
    language = language or {}
    language.Add = function() end
    assert(loadstring(_editor_tool, "livingcity_editor.lua"))()
    TOOL.BuildCPanel(cp)
    local pick = combos["Dream"]
    if not pick then error("editor: no dream to pick") end
    net._q = { { k = "list", point = true, on = true, list = { { id = "cheese", name = "The Cheese Dream", mood = "Neutral", kind = "game" }, { id = "bus", name = "The Bus", mood = "Neutral", kind = "ending" } } } }
    net["recv_lc_dream_test"]()
    if #pick.choices ~= 2 or pick.choices[1][2] ~= "cheese" then error("editor: the dreams aren't in the list") end
    local test = buttons["Test it now (just me)"]
    if not test or not test.DoClick then error("editor: no Test it now button") end
    local sent = {}
    local ss, ws = net.SendToServer, net.WriteString
    net.WriteString = function(v) sent[#sent + 1] = v end
    net.SendToServer = function() end
    test.DoClick()
    buttons["Stop the test (wake up)"].DoClick()
    net.SendToServer, net.WriteString = ss, ws
    if sent[1] ~= "test" or sent[2] ~= "cheese" or sent[3] ~= "stop" then error("editor: test and stop didn't reach the server: " .. table.concat(sent, ",")) end
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "strange dreams and the editor's dream test (client) " + str(err)
# cigarettes, alcohol, stimulants and the shakes (cl_livingcity_vices.lua); the dream games' wake-or-watch window
err = L.execute(r"""
local ok, e = pcall(function()
    net._q = { "smoke", _me, 2 }
    net["recv_lc_vice"]()
    net._q = { "whisper", _me, 0, Vector(100, 0, 0), "A black market dealer" }
    net["recv_lc_vice"]()
    hook.t.HUDPaint.LivingCityViceWhisper()
    if not LC_CL.ViceWhisper() then error("the whisper's mark") end
    _me:SetNW2Int("lc_drunk", 4)
    _me:SetNW2Float("lc_wired_until", CurTime() + 60)
    _me:SetNW2Float("lc_shaken_until", CurTime() + 60)
    hook.t.RenderScreenspaceEffects.LivingCityVices()
    local view = { angles = Angle(0, 0, 0), fov = 90, origin = Vector(0, 0, 0) }
    LC_CL.ViewMods.vices.fn(_me, view)
    _me:SetNW2Int("lc_drunk", 0)
    _me:SetNW2Float("lc_wired_until", 0)
    _me:SetNW2Float("lc_shaken_until", 0)
    _me:SetNW2Float("lc_crash_until", CurTime() + 60)
    hook.t.RenderScreenspaceEffects.LivingCityVices()
    _me:SetNW2Float("lc_crash_until", 0)
    _me:SetNW2Bool("lc_dreaming", true)
    _me:SetNW2Bool("lc_nightmare", true)
    hook.t.HUDPaint.LivingCityDreams()
    local function Msg(t) net._q = { t } net["recv_lc_dreamgame"]() end
    Msg({ k = "start", id = "maze", name = "The Patrol Maze", goal = "Tokens.", ends = CurTime() + 300, lives = 3, maxLives = 3, tokens = {}, left = 0 })
    Msg({ k = "out", how = "out", title = "Caught", text = "You're out of it." })
    hook.t.HUDPaint.LivingCityDreamGames()
    Msg({ k = "stop", how = "over" })
    _me:SetNW2Bool("lc_nightmare", false)
    _me:SetNW2Bool("lc_dreaming", false)
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "vices (client) " + str(err)
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
    local crWas, velWas = _me.Crouching, _me.GetVelocity
    _me.Crouching = function() return true end
    _me.GetVelocity = function() return Vector(0, 0, 0) end
    local unit = { IsValid = function() return true end, GetNW2String = function(_, k, d) return k == "lc_role" and "cop" or d end,
        GetClass = function() return "npc_metropolice" end,
        GetPos = function() return _me:GetPos() + Vector(-200, 0, 0) end, GetForward = function() return Vector(1, 0, 0) end, GetAngles = function() return Angle() end }
    -- (the unit arrives the way a real one does: the city's list of units hears of it, sh_livingcity_cache.lua)
    LC.EntsOf("npc_metropolice")
    hook.t.OnEntityCreated.LivingCityRegistry(unit)
    if not LC_CL.StealthInside(unit, _me:GetPos(), 900 * LC_CL.StealthFactor()) then return "sneaking: a unit facing you, close by, doesn't see you" end
    local q0 = _calls["render.DrawQuad"] or 0
    hook.t.PostDrawTranslucentRenderables.LivingCityStealthCones(false, false)
    if (_calls["render.DrawQuad"] or 0) <= q0 then return "sneaking: no sight painted on the ground" end
    if (_calls["render.DrawQuad"] or 0) - q0 < 12 * 6 then return "sneaking: the sight isn't 3D (ground, lid and walls)" end
    hook.t.HUDPaint.LivingCityStealthMeter()
    unit.GetForward = function() return Vector(-1, 0, 0) end
    if LC_CL.StealthInside(unit, _me:GetPos(), 900 * LC_CL.StealthFactor()) then return "sneaking: seen from behind his back" end
    hook.t.EntityRemoved.LivingCityRegistry(unit)
    local q1 = _calls["render.DrawQuad"] or 0
    hook.t.PostDrawTranslucentRenderables.LivingCityStealthCones(false, false)
    if (_calls["render.DrawQuad"] or 0) ~= q1 then return "sneaking: a unit that's gone still has its sight painted" end
    _me.Crouching, _me.GetVelocity = crWas, velWas
end
-- rain: the streaks in front of the camera are drawn, the ones behind it aren't (each one is a draw)
do
    local wWas, epWas, eaWas = _globals.lc_weather, EyePos, EyeAngles
    _globals.lc_weather = "rain"
    EyePos = function() return _me:EyePos() end
    local trWas = util.TraceLine
    util.TraceLine = function(t) return { Hit = true, HitSky = true, HitPos = t.endpos, Fraction = 1 } end
    _advance(1)
    hook.t.Think.LivingCityRain() -- (open sky above: outdoors)
    util.TraceLine = trWas
    local function Beams(fwd) -- (which way the camera faces; the stub's angles leave out pitch)
        EyeAngles = function() return { Forward = function() return fwd end } end
        local b0 = _calls["render.DrawBeam"] or 0
        hook.t.PostDrawTranslucentRenderables.LivingCityRain(false, false)
        return (_calls["render.DrawBeam"] or 0) - b0
    end
    local ahead, up, down = Beams(Vector(1, 0, 0)), Beams(Vector(0, 0, 1)), Beams(Vector(0, 0, -1))
    _globals.lc_weather, EyePos, EyeAngles = wWas, epWas, eaWas
    _advance(1)
    hook.t.Think.LivingCityRain() -- (and back under the roof the stub's traces say is there)
    print(string.format("rain streaks drawn: ahead %d, looking up %d, at your feet %d (of 1120)", ahead, up, down))
    if ahead < 400 or ahead > 800 then return "rain: looking ahead, about half the streaks should be drawn" end
    if up < 1000 then return "rain: looking up, nearly every streak is in view and drawn" end
    if down > 100 then return "rain: looking at your feet, the streaks above you shouldn't be drawn" end
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
L.globals()["_pr_play"] = open(os.path.join(PR_DIR, "pose_recorder", "play.lua")).read()
err = L.execute(r"""
local ok, e = pcall(function()
    include = function(p)
        if p == "pose_recorder/core.lua" then assert(loadstring(_pr_core, "core.lua"))() end
        if p == "pose_recorder/play.lua" then assert(loadstring(_pr_play, "play.lua"))() end
    end
    net.WriteDouble = net.WriteDouble or net.WriteFloat
    net.ReadDouble = net.ReadDouble or net.ReadFloat
    local props = {}
    properties = { Add = function(n, t) props[n] = t end }
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

    -- Pose Recorder 2: easing and length per keyframe, mirror, and playing it on someone
    concommand.list.pose_recorder_clear()
    PR.sel = { ent = rag, phys = { ["ValveBiped.Bip01_Pelvis"] = true, ["ValveBiped.Bip01_Spine2"] = true, ["ValveBiped.Bip01_R_UpperArm"] = true } }
    rag.GetBoneMatrix = function(_, i) local a = raised[i + 1] return M(a[1], a[2], a[3]) end
    raised = { { 0, 0, 90 }, { -80, 0, 90 }, { -20, 10, 0 } }
    concommand.list.pose_recorder_snap()
    concommand.list.pose_recorder_snap()
    if PR.frames[1].ease ~= "smooth" then error("pose recorder: a new keyframe has no easing") end
    concommand.list.pose_recorder_key_ease(nil, nil, { "bouncy", "2" })
    concommand.list.pose_recorder_key_beats(nil, nil, { "3", "all" })
    if PR.frames[2].ease ~= "bouncy" or PR.frames[1].ease ~= "smooth" or PR.frames[1].beats ~= 3 then error("pose recorder: easing or length not set on the keyframes asked") end
    concommand.list.pose_recorder_mirror(nil, nil, { "1" })
    if not PR.frames[1].bones["ValveBiped.Bip01_L_UpperArm"] or PR.frames[1].bones["ValveBiped.Bip01_R_UpperArm"] then error("pose recorder: mirror didn't move the right arm to the left") end
    concommand.list.pose_recorder_mirror_add()
    if #PR.frames ~= 4 then error("pose recorder: no mirrored copy added") end
    local d = PR.Data()
    if d.format ~= 2 or d.wrap ~= true then error("pose recorder: the file has no format or wrap") end
    net.sent = {}
    local sent
    local sts = net.SendToServer
    net.SendToServer = function() sent = true end
    concommand.list.pose_recorder_play_mine()
    net.SendToServer = sts
    if not sent then error("pose recorder: playing it on me sent nothing to the server") end
    -- the server says an NPC plays it: this client turns the bones itself
    local npc = Fake(standing)
    npc.IsNPC = function() return true end
    local clean = PR.Sanitize(d)
    PR.Library["~1/mydance"] = { data = clean, crc = "42" }
    net._q = { npc, "~1/mydance", "42", CurTime(), "loop", 1 }
    net.recv_pose_recorder_play()
    _advance(0.3)
    for _, h in pairs(hook.t["Think"] or {}) do h() end
    if not next(npc.manip) then error("pose recorder: the NPC's bones weren't turned") end
    if not props.pose_recorder_play or not props.pose_recorder_play.Filter(props.pose_recorder_play, npc) then error("pose recorder: no Play animation in the context menu for an NPC") end
    local sub = setmetatable({}, { __index = function() return function() end end })
    props.pose_recorder_play.MenuOpen(props.pose_recorder_play, { AddSubMenu = function() return sub end }, npc)
    net._q = { npc }
    net.recv_pose_recorder_stop()
    if PR.Active[npc] then error("pose recorder: stop didn't stop it") end
    for _, v in pairs(npc.manip) do if v.p ~= 0 or v.y ~= 0 or v.r ~= 0 then error("pose recorder: the bones weren't put back after stopping") end end
    concommand.list.pose_play(nil, nil, {})
    TOOL.BuildCPanel(cp)
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)
# what you can do here (cl_livingcity_context.lua): with the Arrest Baton out, the panel on the right
# says what it does, with the player's own keys; and the quest trail (cl_livingcity_trail.lua) is
# drawn from fake points, dropping the ones walked past
err = L.execute(r"""
local ok, e = pcall(function()
    local baton = { IsValid = function() return true end, GetClass = function() return "weapon_lc_baton" end }
    local gaw = _me.GetActiveWeapon
    _me.GetActiveWeapon = function() return baton end
    _me.nw.lcf_faction = "cp"
    _me.nw.lc_here = "rebel"
    local groups = LC_CL.ContextGroups(_me)
    local all = {}
    for _, g in ipairs(groups) do for _, l in ipairs(g.lines) do all[#all + 1] = l end end
    local text = table.concat(all, "\n")
    if not groups[1] or groups[1].title ~= "Arrest Baton" then error("context panel: the baton isn't first") end
    -- (the smoke test binds +use to f: the key is looked up live, not assumed to be E)
    if not string.find(text, "[F] on a citizen", 1, true) then error("context panel: no stop-a-citizen line with the live key: " .. text) end
    if not string.find(text, "[Right click] on someone: arrest", 1, true) then error("context panel: no arrest line") end
    if not string.find(text, "[G]: kick", 1, true) then error("context panel: no kick line with the kick key") end
    local zoned = false
    for _, g in ipairs(groups) do if g.title == "Rebel territory" then zoned = true end end
    if not zoned then error("context panel: nothing for rebel ground") end
    LC_CL.QuestTrackerBottom, LC_CL.QuestTrackerAt = 300, CurTime()
    LC_CL.HintTop, LC_CL.HintAt = 900, CurTime()
    local before = _calls["draw.SimpleText"] or 0
    hook.t.HUDPaint.LivingCityContext()
    if (_calls["draw.SimpleText"] or 0) <= before then error("context panel: nothing drawn for the baton") end
    if not LC_CL.ContextDrawn or #LC_CL.ContextDrawn == 0 then error("context panel: no part fitted") end
    local top, bottom = LC_CL.ContextRoom()
    if top < 310 or bottom > 890 then error("context panel: it would overlap the quest tracker or the tip card") end
    -- no room at all: nothing drawn, rather than on top of the tip card
    _advance(0.3)
    LC_CL.QuestTrackerAt = CurTime()
    LC_CL.HintTop, LC_CL.HintAt = 320, CurTime()
    hook.t.HUDPaint.LivingCityContext()
    if #LC_CL.ContextDrawn ~= 0 then error("context panel: drawn over the tip card when there's no room") end
    LC_CL.HintAt, LC_CL.QuestTrackerAt = nil, nil
    GetConVar("lc_context_show").v = "0"
    LC_CL.ContextDrawn = nil
    _advance(0.3)
    hook.t.HUDPaint.LivingCityContext()
    if LC_CL.ContextDrawn then error("context panel: still drawn when turned off") end
    GetConVar("lc_context_show").v = "1"
    _me.GetActiveWeapon = gaw
    _me.nw.lcf_faction, _me.nw.lc_here = nil, nil

    -- the trail: three points ahead, the objective at the end (on a quest: with none, there's no trail)
    local qsWas = LC_CL.QuestState
    LC_CL.QuestState = function() return { active = true, kind = "goto" } end
    _me:SetPos(Vector(0, 0, 0))
    LC_CL.SetTrail({ g = { 1000, 0, 0 }, p = { 200, 0, 0, 600, 0, 0, 1000, 0, 0 } })
    local t = LC_CL.Trail()
    if not t or #t.pts ~= 3 then error("trail: the points weren't read") end
    local beamsBefore = _calls["render.DrawBeam"] or 0
    hook.t.PostDrawTranslucentRenderables.LivingCityTrail(false, false)
    if (_calls["render.DrawBeam"] or 0) - beamsBefore < 10 then error("trail: hardly any chevrons drawn") end
    local c1 = LC_CL.TrailChevrons(t, _me:GetPos(), 10)
    local c2 = LC_CL.TrailChevrons(t, _me:GetPos(), 10.2)
    if not c1[1] or not c2[1] or c2[1].pos.x <= c1[1].pos.x then error("trail: the chevrons don't flow toward the objective") end
    if c1[#c1].pos.x > 1450 then error("trail: drawn further ahead than it should be") end
    for _, c in ipairs(c1) do if c.pos.x < 40 then error("trail: a chevron under your feet") end end
    -- walked past the first point, on the way to the second
    _me:SetPos(Vector(420, 10, 0))
    hook.t.Think.LivingCityTrail()
    _advance(0.2)
    hook.t.Think.LivingCityTrail()
    if #t.pts ~= 2 or t.pts[1].x ~= 600 then error("trail: the point walked past wasn't dropped (" .. #t.pts .. " left)") end
    for _, c in ipairs(LC_CL.TrailChevrons(t, _me:GetPos(), 10)) do if c.pos.x < 420 then error("trail: still drawn behind you") end end
    if not LC_CL.TrailActive() then error("trail: not active") end
    -- at the objective: gone
    _me:SetPos(Vector(980, 0, 0))
    _advance(0.2)
    hook.t.Think.LivingCityTrail()
    _advance(0.2)
    hook.t.Think.LivingCityTrail()
    if LC_CL.Trail() then error("trail: still there at the objective") end
    LC_CL.SetTrail({})
    if LC_CL.Trail() then error("trail: an empty message doesn't clear it") end
    -- the quest's over: the trail goes with it
    LC_CL.SetTrail({ g = { 1000, 0, 0 }, p = { 200, 0, 0, 1000, 0, 0 } })
    LC_CL.QuestState = function() return { active = false } end
    _me:SetPos(Vector(0, 0, 0))
    _advance(0.2)
    hook.t.Think.LivingCityTrail()
    if LC_CL.Trail() then error("trail: still there with no quest") end
    LC_CL.QuestState = qsWas
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "context panel / quest trail: " + str(err)

# the Resistance Insider beside a prisoner being marched to the cells (sv_livingcity_insider.lua): F2 > 7
# lets them slip and the panel on the right says so, bright; greyed and faint while someone can see;
# nothing for anyone else, or once the prisoner is out of reach
err = L.execute(r"""
local ok, e = pcall(function()
    local pris = _makeplayer("SlipPrisoner", Vector(120, 0, 0))
    pris.nw.lc_marching = true
    _me:SetPos(Vector(0, 0, 0))
    _me.nw.lcf_faction = "cp"
    _me.IsAdmin = function() return false end
    _me.GetEyeTrace = function() return { Hit = false, HitPos = Vector(0, 0, 0) } end
    local function Lines()
        local out = {}
        for _, g in ipairs(LC_CL.ContextGroups(_me)) do
            for i, l in ipairs(g.lines) do if string.find(l, "slip away", 1, true) then out[#out + 1] = { t = l, st = g.style and g.style[i], g = g } end end
        end
        return out
    end
    local function F2Slip()
        local root = LC_CL.QuickRoleRoot()
        for n = 1, 8 do local it = root.items[n] if it and it.id == "letslip" then return it, n, root end end
        return nil, nil, root
    end
    local function Told(t, why)
        if t then net._q = { true, t, why } else net._q = { false } end
        net["recv_lc_insider_slip"](0)
    end
    -- an ordinary unit: nothing, even with the server's word (it never sends it, but still)
    LC_CL.Insider = false
    Told(pris, "")
    if #Lines() > 0 or F2Slip() then error("an ordinary unit sees Let them slip") end
    -- the Insider, unseen: F2 > 7, and the line, bright, naming the key
    LC_CL.Insider = true
    local it, n, root = F2Slip()
    if not it or n ~= 7 or it.disabled then error("F2: no live Let them slip at 7 (got " .. tostring(n) .. ")") end
    if not (root.items[1].label == "Voice lines" and root.items[6].label == "Send my 10-20") then error("F2: the owner's six moved") end
    local sent
    local sa = LC_CL.SendAction
    LC_CL.SendAction = function(cmd) sent = cmd end
    LC_CL.OpenQuick2() LC_CL.QuickPick(7)
    LC_CL.SendAction = sa
    if sent ~= "letslip" then error("F2 > 7 didn't send letslip: " .. tostring(sent)) end
    local L1 = Lines()
    if #L1 ~= 1 or not string.find(L1[1].t, "[F2] > 7", 1, true) or L1[1].st ~= "bright" then
        error("panel: no bright 'Let them slip: F2 > 7' line: " .. tostring(L1[1] and L1[1].t) .. " " .. tostring(L1[1] and L1[1].st))
    end
    if LC_CL.ContextGroups(_me)[1].title ~= "Inside" then error("panel: the Insider's line isn't first") end
    _advance(0.3)
    hook.t.HUDPaint.LivingCityContext()
    -- someone can see: greyed in F2 (picking it does nothing), faint on the right
    Told(pris, "watched")
    it = F2Slip()
    if not it or not it.disabled or not string.find(it.label, "someone can see you", 1, true) then error("F2: not greyed while watched: " .. tostring(it and it.label)) end
    sent = nil
    LC_CL.SendAction = function(cmd) sent = cmd end
    LC_CL.OpenQuick2() LC_CL.QuickPick(7)
    LC_CL.SendAction = sa
    if sent then error("F2: a greyed Let them slip still sent " .. tostring(sent)) end
    LC_CL.CloseQuick()
    local L2 = Lines()
    if #L2 ~= 1 or not string.find(L2[1].t, "being watched", 1, true) or L2[1].st ~= "faint" then error("panel: no faint 'being watched' line: " .. tostring(L2[1] and L2[1].t)) end
    _advance(0.3)
    hook.t.HUDPaint.LivingCityContext()
    -- out of reach, or no longer marched, or the server says there's no one: gone
    pris:SetPos(Vector(400, 0, 0))
    if #Lines() > 0 or F2Slip() then error("still offered with the prisoner out of reach") end
    pris:SetPos(Vector(120, 0, 0))
    pris.nw.lc_marching = false
    if #Lines() > 0 or F2Slip() then error("still offered once the march is over") end
    pris.nw.lc_marching = true
    Told(nil)
    if #Lines() > 0 or F2Slip() then error("still offered after the server said there's no one") end
    LC_CL.Insider, LC_CL.InsiderSlipNet = nil, nil
    _me.nw.lcf_faction = nil
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "Insider's Let them slip (F2, panel): " + str(err)

# More on F2 (the owner, later on 7 November): the Insider's Inside >, the Resistance's Freq 7 >, a
# citizen's Me >, a prisoner's sentence, the Administrator's orders, a senior unit's Call a sweep >;
# what greys out comes from the server (lc_quick_info), and the open page follows it
err = L.execute(r"""
local ok, e = pcall(function()
    local jt = util.JSONToTable
    local function Info(t)
        util.JSONToTable = function() return t end
        net._q = { "{}" }
        net["recv_lc_quick_info"](0)
        util.JSONToTable = jt
    end
    local function Find(page, id)
        for n = 1, 9 do local it = page.items[n] if it and it.id == id then return it, n end end
        return nil
    end
    local function Labels(page) local out = {} for n = 1, 9 do out[n] = page.items[n] and page.items[n].label or "-" end return table.concat(out, " | ") end
    local sentQM, sentAct
    local function Watch()
        sentQM, sentAct = nil, nil
        local ws, st = net.WriteString, net.Start
        local name
        net.Start = function(n) name = n return st and st(n) end
        net.WriteString = function(s) if name == "lc_quickmore" and not sentQM then sentQM = s end return ws and ws(s) end
        local sa = LC_CL.SendAction
        LC_CL.SendAction = function(cmd) sentAct = cmd end
        return function() net.WriteString, net.Start, LC_CL.SendAction = ws, st, sa end
    end
    _me:SetPos(Vector(0, 0, 0))
    _me.alive = true
    _me.IsAdmin = function() return false end
    _me.GetEyeTrace = function() return { Hit = false, HitPos = Vector(0, 0, 0) } end
    LC_CL.InsiderSlipNet = nil

    -- the Insider: the owner's six, then Inside > at 7; each greyed with why
    _me.nw = { lcf_faction = "cp", lcf_rank = 2 }
    LC_CL.Insider = true
    Info({ ins = { watched = "Someone can see you.", wait = { tip = 0, skim = 0, copy = 0, foul = 0, spike = 0 }, wanted = 2, commissary = true, weedkiller = true } })
    local root = LC_CL.QuickRoleRoot()
    if not (root.items[1].label == "Voice lines" and root.items[2].id == "unittools" and root.items[3].id == "kick" and root.items[6].label == "Send my 10-20") then error("Insider: the owner's six moved: " .. Labels(root)) end
    local ins, n = Find(root, "inside")
    if n ~= 7 then error("Insider: Inside > should be 7, is " .. tostring(n) .. ": " .. Labels(root)) end
    local p = ins.page()
    for i = 1, 6 do if not p.items[i].disabled then error("Inside, watched: '" .. p.items[i].label .. "' isn't greyed") end end
    if not string.find(p.items[1].label, "watched", 1, true) or not (p.empty and p.empty[9] and string.find(p.empty[9], "Someone can see you", 1, true)) then error("Inside: doesn't say why: " .. Labels(p)) end
    Info({ ins = { wait = { tip = 0, skim = 0, copy = 300, foul = 0, spike = 0 }, wanted = 0, commissary = false, weedkiller = false } })
    p = ins.page()
    if p.items[1].disabled then error("Inside: Tip off greyed with nobody watching") end
    if not (p.items[2].disabled and string.find(p.items[2].label, "nobody's wanted", 1, true)) then error("Inside: Lose a record: " .. p.items[2].label) end
    if not (p.items[3].disabled and string.find(p.items[3].label, "Commissary only", 1, true)) then error("Inside: supplies: " .. p.items[3].label) end
    if not (p.items[4].disabled and string.find(p.items[4].label, "in 5m", 1, true)) then error("Inside: copy: " .. p.items[4].label) end
    if not string.find(p.items[#p.items].label, "Reveal myself", 1, true) then error("Inside: no Reveal myself last") end
    -- a greyed one does nothing; an open one sends the Insider's own action
    local undo = Watch()
    LC_CL.OpenQuick2() LC_CL.QuickPick(7) LC_CL.QuickPick(4)
    if sentAct then error("Inside: a greyed entry still sent " .. tostring(sentAct)) end
    Info({ ins = { wait = { tip = 0, skim = 0, copy = 0, foul = 0, spike = 0 }, wanted = 1, commissary = true, weedkiller = true } })
    if not LC_CL.QuickOpen("role") then error("Inside: the server's word closed F2") end
    LC_CL.QuickPick(4)
    undo()
    if sentAct ~= "copyrecords" then error("Inside: the page didn't follow the server's word (sent " .. tostring(sentAct) .. ")") end
    LC_CL.CloseQuick()
    -- an ordinary unit: no Inside
    LC_CL.Insider = false
    if Find(LC_CL.QuickRoleRoot(), "inside") then error("an ordinary unit has Inside >") end

    -- a Division Leader: Call a sweep >, greyed with why
    _me.nw = { lcf_faction = "cp", lcf_rank = 3 }
    Info({ sweep = { sweep = "Not while the city has something on." } })
    root = LC_CL.QuickRoleRoot()
    local sw, sn = Find(root, "sweep")
    if not sw or sn ~= 7 then error("a Division Leader: Call a sweep > should be 7: " .. Labels(root)) end
    p = sw.page()
    if not (p.items[1].disabled and not p.items[2].disabled) then error("Call a sweep: " .. Labels(p)) end
    if not (p.empty and p.empty[4] and string.find(p.empty[4], "something on", 1, true)) then error("Call a sweep doesn't say why") end
    _me.nw = { lcf_faction = "cp", lcf_rank = 2 }
    if Find(LC_CL.QuickRoleRoot(), "sweep") then error("a Metrocop can call a sweep") end

    -- the Resistance: Freq 7 >, after what was there
    _me.nw = { lcf_faction = "resistance", lcf_rank = 2 }
    Info({ reb = { tx = false, backup = 50, pos = 0 } })
    root = LC_CL.QuickRoleRoot()
    if not (string.find(root.items[1].label, "clothes", 1, true) and root.items[2].label == "Black market" and root.items[3].label == "Resistance") then error("the Resistance's F2 moved: " .. Labels(root)) end
    local band, bn = Find(root, "freq7")
    if bn ~= 4 then error("the Resistance: Freq 7 > should be 4: " .. Labels(root)) end
    p = band.page()
    if not (p.items[1].disabled and p.items[2].disabled and string.find(p.items[2].label, "in 50s", 1, true) and not p.items[3].disabled) then error("Freq 7: " .. Labels(p)) end
    if not (string.find(p.items[4].label, "rebel ground", 1, true) and string.find(p.items[5].label, "lab", 1, true)) then error("Freq 7: no guidance: " .. Labels(p)) end
    undo = Watch()
    p.items[4].run()
    undo()
    if sentQM ~= "guide" then error("Freq 7: guide me sent " .. tostring(sentQM)) end

    -- a plain citizen: Me >, with what the server says
    _me.nw = { lcf_faction = "citizen", lce_standing = 120, lc_unreg = true }
    Info({ me = { work = "intake", ration = 240, cards = 2, home = "none", standing = 120, next = 150, nextWhat = "Union foreman (F2)" } })
    root = LC_CL.QuickRoleRoot()
    local mine, mn = Find(root, "me")
    if mn ~= 1 or root.empty then error("a plain citizen: Me > should be 1, and no 'nothing here': " .. Labels(root)) end
    p = mine.page()
    if not (string.find(p.items[1].label, "Civil Intake first", 1, true) and string.find(p.items[2].label, "next in 4 min, 2 cards", 1, true)
        and string.find(p.items[3].label, "Housing", 1, true) and string.find(p.items[4].label, "120", 1, true)) then error("Me: " .. Labels(p)) end
    if not (p.empty and p.empty[6] and string.find(p.empty[6], "foreman", 1, true)) then error("Me: no next milestone") end
    undo = Watch()
    for i = 1, 4 do p.items[i].run() end
    undo()
    -- in a cell: My sentence
    _me.nw.lc_jail_until = CurTime() + 125
    local s = Find(LC_CL.QuickRoleRoot(), "sentence")
    if not s or not string.find(s.label, "2:0", 1, true) then error("a prisoner: no 'My sentence: 2:0x left'") end
    _me.nw.lc_jail_until = nil
    -- nothing at all applies (the infested): it still says so
    _me.nw = { lcf_faction = "zombie" }
    root = LC_CL.QuickRoleRoot()
    if root.items[1] or not root.empty then error("the infested's F2 should say there's nothing: " .. Labels(root)) end

    -- the Administrator: what was there, then the tablet, the laws, the dream, the guards, an arrest
    _me.nw = { lcf_faction = "admin" }
    Info({ adm = { arrest = 0, guards = 2, hold = false, dream = { ready = true, groups = {}, plan = { canPick = true, feel = "Today: calm.", every = 3, skip = true } } } })
    local cit = _makeplayer("ArrestMe", Vector(60, 0, 0))
    cit.nw.lcf_faction = "citizen"
    _me.GetEyeTrace = function() return { Hit = true, HitPos = Vector(60, 0, 60), Entity = cit } end
    root = LC_CL.QuickRoleRoot()
    if root.items[1].label ~= "Sociostability" or not string.find(root.items[2].label, "Broadcast", 1, true) then error("the Administrator's F2 moved: " .. Labels(root)) end
    local want = { "Open my tablet", "The city's laws", "Tonight's dream", "Command the guards" }
    local all = Labels(root)
    for _, w in ipairs(want) do if not string.find(all, w, 1, true) then error("the Administrator's F2 has no '" .. w .. "': " .. all) end end
    local ar = Find(root, "arrest")
    if not ar or ar.disabled then error("the Administrator can't order this citizen's arrest: " .. all) end
    undo = Watch()
    ar.run()
    undo()
    if sentQM ~= "arrest" then error("order of arrest sent " .. tostring(sentQM)) end
    for n = 1, 8 do
        local it = root.items[n]
        if it and it.page then
            local sub = it.page()
            -- (the owner, 9 November: she chooses only a kind, now and then)
            if it.label == "Tonight's dream" and not (sub.items[1] and string.find(sub.items[1].label, "Nightmare", 1, true) and sub.items[2] and string.find(sub.items[2].label, "propaganda", 1, true)
                and sub.items[3] and string.find(sub.items[3].label, "didn't choose", 1, true)) then error("Tonight's dream: " .. Labels(sub)) end
            if it.label == "Command the guards" and not (sub.items[1] and string.find(sub.items[1].label, "Follow me", 1, true) and string.find(sub.items[2].label, "Hold here", 1, true)) then error("guards: " .. Labels(sub)) end
            -- (the owner, 8 November) how close they follow, and what they do when there's trouble
            if it.label == "Command the guards" then
                local d3, m4 = sub.items[3], sub.items[4]
                if not (d3 and d3.page and d3.label == "Follow distance: Medium" and m4 and m4.page and m4.label == "When there's trouble: As always") then error("guards' orders: " .. Labels(sub)) end
                local dp = d3.page()
                if not (dp.items[1] and dp.items[1].label == "Close" and dp.items[2].label == "Medium  (now)" and dp.items[3].label == "Far") then error("follow distance: " .. Labels(dp)) end
                local mp = m4.page()
                if not (mp.items[1] and string.find(mp.items[1].label, "(now)", 1, true) and #mp.items == 4 and string.find(mp.items[4].label, "Hold fire", 1, true)) then error("when there's trouble: " .. Labels(mp)) end
                local strs, ws0 = {}, net.WriteString
                net.WriteString = function(s) strs[#strs + 1] = s return ws0 and ws0(s) end
                mp.items[3].run()
                dp.items[3].run()
                net.WriteString = ws0
                if strs[1] ~= "guards" or strs[2] ~= "between" or strs[3] ~= "guards" or strs[4] ~= "far" then error("the guards' orders sent " .. table.concat(strs, ",")) end
            end
        end
    end
    -- the order in force is the one marked, whatever it is (and her orders can be given with no guards about)
    Info({ adm = { arrest = 0, guards = 0, hold = false, dist = "far", mode = "holdfire" } })
    do
        local gn
        for n = 1, 9 do local it = LC_CL.QuickRoleRoot().items[n] if it and it.label == "Command the guards" then gn = it end end
        local gp = gn and gn.page()
        if not (gp and gp.items[1].disabled and gp.items[3].label == "Follow distance: Far" and gp.items[4].label == "When there's trouble: Hold fire" and not gp.items[3].disabled) then error("guards' orders in force: " .. (gp and Labels(gp) or "no page")) end
        local dp, mp = gp.items[3].page(), gp.items[4].page()
        if dp.items[3].label ~= "Far  (now)" or dp.items[2].label ~= "Medium" or not string.find(mp.items[4].label, "(now)", 1, true) or string.find(mp.items[1].label, "(now)", 1, true) then error("the order in force isn't marked: " .. Labels(dp) .. " / " .. Labels(mp)) end
    end
    Info({ adm = { arrest = 200, guards = 2 } })
    ar = Find(LC_CL.QuickRoleRoot(), "arrest")
    if not (ar and ar.disabled and string.find(ar.label, "in 4m", 1, true)) then error("order of arrest isn't greyed while it cools down") end
    cit.nw.lcf_faction = "cp"
    if Find(LC_CL.QuickRoleRoot(), "arrest") then error("the Administrator can order a unit's arrest") end
    _me.GetEyeTrace = function() return { Hit = false, HitPos = Vector(0, 0, 0) } end
    LC_CL.QuickInfo, LC_CL.Insider = {}, nil
    _me.nw = {}
end)
return (not ok) and tostring(e) or nil
""")
if err:
    problems = (problems + "\n" if problems else "") + "More on F2 (Inside, Freq 7, Me, the Administrator, a sweep): " + str(err)

# the owner's 7 November playtest: the panting on one handle, stopped; the rain 30% quieter; the
# eyelids under the job's objective; Civil Protection's action music
err = L.execute(r"""
local bad = {}
local made, stopped = 0, 0
local csWas, pw = CreateSound, player.GetAll
CreateSound = function(ent, path)
    made = made + 1
    local s = { path = path }
    function s:PlayEx() end
    function s:Stop() stopped = stopped + 1 end
    function s:SetSoundLevel() end
    return s
end
player.GetAll = function() return { _me } end
local ok, e = pcall(function()
    _me.alive = true
    _me.nw.lcf_faction = "citizen"
    _me.nw.lc_winded, _me.nw.lc_stamina = true, 0
    LCS.BreathTick(100)
    if made ~= 1 or not LCS.Pants[_me] then bad[#bad + 1] = "out of breath: the panting didn't start on a handle" end
    LCS.BreathTick(100.5)
    if made ~= 1 then bad[#bad + 1] = "the panting started twice" end
    _me.nw.lc_stamina = 40
    LCS.BreathTick(101)
    if stopped ~= 1 or LCS.Pants[_me] then bad[#bad + 1] = "breath back: the panting didn't stop" end
    _me.nw.lc_winded = false LCS.BreathTick(102)
    _me.nw.lc_winded, _me.nw.lc_stamina = true, 0 LCS.BreathTick(103)
    _me.alive = false LCS.BreathWatchdog(103.5)
    if made ~= 2 or stopped ~= 2 then bad[#bad + 1] = "dead: the watchdog didn't stop the panting" end
    _me.alive = true _me.nw.lc_winded = false LCS.BreathTick(104)
    _me.nw.lc_winded = true LCS.BreathTick(105)
    _me.nw.lcf_faction = "cp" LCS.BreathTick(105.5)
    if made ~= 3 or stopped ~= 3 then bad[#bad + 1] = "a faction change didn't stop the panting" end
    _me.nw.lcf_faction = "citizen" _me.nw.lc_winded = false LCS.BreathTick(106)
    _me.nw.lc_winded = true LCS.BreathTick(107) LCS.BreathTick(115.5)
    if made ~= 4 or stopped ~= 4 then bad[#bad + 1] = "still winded after 8 seconds: the panting didn't stop" end
    LCS.BreathTick(116)
    if made ~= 4 then bad[#bad + 1] = "the panting came back on its own" end
    _me.nw.lc_winded, _me.nw.lc_stamina = false, 100
    LCS.BreathTick(117)
    -- the rain
    local v1, v2, v3 = LC_CL.RainVolume("storm", true), LC_CL.RainVolume("rain", true), LC_CL.RainVolume("rain", false)
    if math.abs(v1 - 0.42) > 0.001 or math.abs(v2 - 0.28) > 0.001 or math.abs(v3 - 0.084) > 0.001 then bad[#bad + 1] = "the rain isn't 30% quieter" end
    -- the eyelids: under everything else on the screen
    if not (hook.t.HUDPaintBackground and hook.t.HUDPaintBackground.LivingCityRestLids) then bad[#bad + 1] = "the eyelids aren't drawn under the rest of the screen" end
    _me.nw.lc_tired = true
    if not LC_CL.DrawEyelids(_me, 7 * 0.9) then bad[#bad + 1] = "tired: no eyelids" end
    for _, h in pairs(hook.t.HUDPaintBackground or {}) do h() end
    _me.nw.lc_tired = false
    if LC_CL.DrawEyelids(_me, 7 * 0.9) then bad[#bad + 1] = "not tired, and the eyelids close" end
    -- Civil Protection in action: their own music
    _me.nw.lcf_faction = "cp"
    _me.nw.lc_action_until = CurTime() + 10
    if LC_CL.MusicMood() ~= "combat" then bad[#bad + 1] = "a unit in action gets no action music: " .. tostring(LC_CL.MusicMood()) end
    _me.nw.lc_action_until = 0
    if LC_CL.MusicMood() == "combat" then bad[#bad + 1] = "out of action, still the action music" end
    _me.nw.lcf_faction = "citizen"
    _me.nw.lc_action_until = CurTime() + 10
    if LC_CL.MusicMood() == "combat" then bad[#bad + 1] = "a citizen gets Civil Protection's action music" end
    _me.nw.lc_action_until = 0
    for _ = 1, 3 do _advance(1) _runtimers() end
end)
CreateSound, player.GetAll = csWas, pw
if not ok then return "7 November fixes: " .. tostring(e) end
if #bad > 0 then return "7 November fixes: " .. table.concat(bad, "; ") end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)

# the Administrator's Commissary and market panel (cl_livingcity_market.lua), and the market's lines in
# the Commissary's and the black market's windows (cl_livingcity_needs.lua)
err = L.execute(r"""
local made, sent = {}, {}
local function P()
    local t = {}
    made[#made + 1] = t
    return setmetatable(t, { __index = function(_, k)
        if string.sub(k, 1, 2) == "lc" or string.sub(k, 1, 1) == "_" then return nil end
        if k == "IsValid" then return function() return not t._removed end end
        if k == "Remove" then return function() t._removed = true end end
        if k == "GetActiveTab" then return function() return nil end end
        if k == "GetWide" or k == "GetTall" then return function() return 400 end end
        return function() return P() end
    end })
end
local vgWas, stsWas, startWas, wsWas = vgui, net.SendToServer, net.Start, net.WriteString
local rU, rD, rDc, rJ = net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable
vgui = { Create = function() return P() end, GetKeyboardFocus = function() return nil end }
local cur
net.Start = function(n) cur = { name = n, data = {} } end
net.WriteString = function(v) if cur then table.insert(cur.data, v) end end
net.SendToServer = function() sent[#sent + 1] = cur end
net.ReadUInt = function() return 1 end
net.ReadData = function() return "x" end
util.Decompress = function(s) return s end
local doc
util.JSONToTable = function() return doc end
local okM, errM = pcall(function()
    doc = { on = true, mood = "There's some grumbling in the ration lines about the restriction.", restricted = { "Bread" },
        tiers = { { name = "Probationary", min = -50 }, { name = "Citizen", min = 0 }, { name = "Trusted", min = 150 }, { name = "Exemplary", min = 400 } },
        goods = { { id = "bread", name = "Bread", price = 8, now = 8, restricted = true, mul = 1, standing = 0, baseStanding = 0, supply = "normal", note = "Restricted by the Administrator", demand = 0, black = 18 },
            { id = "healthkit", name = "Medical kit", price = 50, now = 100, restricted = false, mul = 2, standing = 400, baseStanding = 400, supply = "scarce", stock = 3, demand = 15 } },
        black = { { name = "Bread", price = 18, usual = 12, note = "Hard to get in the city", demand = 0, extra = true },
            { name = "Lockpick", price = 42, usual = 35, note = "In demand: price up 20%", demand = 20 } } }
    net.recv_lc_market_admin()
    local f = LC_CL.MarketAdminFrame()
    if not (f and f:IsValid()) then error("the market panel didn't open") end
    for _, pnl in ipairs(made) do
        for _, k in ipairs({ "Paint", "DoClick" }) do
            local fn = rawget(pnl, k)
            if fn then fn(pnl, 400, 60) end
        end
        if rawget(pnl, "OnSelect") then pnl.OnSelect(pnl, 1, "x", 2) end
        if rawget(pnl, "OnChange") then pnl.OnChange(pnl, true) end
    end
    local asked = 0
    for _, m in ipairs(sent) do if m and m.name == "lc_market_set" then asked = asked + 1 end end
    if asked < 4 then error("the panel's controls don't reach the server (" .. asked .. ")") end
    doc = { on = false }
    net.recv_lc_market_admin()
    -- the Commissary and the black market, with the market's lines
    doc = { credits = 50, standing = 0, goods = { { id = "bread", name = "Bread", price = 8, desc = "Grey.", ok = false, why = "Restricted by the Administrator.", market = "Restricted by the Administrator", tier = "Citizen" },
        { id = "milk", name = "Milk", price = 8, desc = "Nearly milk.", ok = true, tier = "Citizen" } } }
    net.recv_lce_shop()
    doc = { credits = 50, goods = { { id = "mkt_bread", name = "Bread", price = 18, desc = "Off a lorry.", ok = true, market = "Hard to get in the city" } },
        sell = { { id = "gun_pistol", name = "Pistol", n = 2, price = 80, market = "In demand: he pays more" } } }
    net.recv_lcu_market()
    -- a stranger at the quartermaster (the owner, 9 November): nothing to buy, arms to sell or give
    sent = {}
    doc = { credits = 5, goods = {}, quartermaster = true, visitor = true,
        sell = { { id = "gun_pistol", name = "Pistol", n = 1, price = 45, donate = true }, { id = "w:weapon_smg1", name = "smg1", n = 1, price = 60, weapon = true, donate = true } } }
    net.recv_lcu_market()
    for _, pnl in ipairs(made) do
        local fn = rawget(pnl, "Paint")
        if fn then fn(pnl, 400, 60) end
        if rawget(pnl, "DoClick") then pnl.DoClick(pnl) end -- (every button: Sell and Donate)
    end
    local gave = false
    for _, m in ipairs(sent) do if m and m.name == "lcu_donate" then gave = true end end
    if not gave then error("the quartermaster's Donate button doesn't reach the server") end
end)
vgui, net.SendToServer, net.Start, net.WriteString = vgWas, stsWas, startWas, wsWas
net.ReadUInt, net.ReadData, util.Decompress, util.JSONToTable = rU, rD, rDc, rJ
if not okM then return "market panel: " .. tostring(errM) end
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)

# big sends in pieces (sh_livingcity_net.lua): put back together and handed to the message's own
# receiver, which reads its length and data as if it came in one message; long global strings in parts
err = L.execute(r"""
local N = LC.Net
if not (N and N.Deliver and N.Assemble and net["recv_lc_big"] and hook.t.InitPostEntity and hook.t.InitPostEntity.LivingCityNetReady) then
    return "net: the pieces receiver or the ready handshake is missing"
end
local rU, rD, rS, rcv = net.ReadUInt, net.ReadData, net.ReadString, net.Receivers
local whole = string.rep("abcdefghij", 7000)
local got
net.Receivers = { lc_nettest = function()
    local len = net.ReadUInt(32)
    got = net.ReadData(len)
    if #got ~= len then got = "bad length" end
end }
local pieces = N.Split(whole, N.PIECE)
local okR, errR = pcall(function()
    for i, piece in ipairs(pieces) do
        local q = { 7, i, #pieces, #piece }
        net.ReadString = function() return "lc_nettest" end
        net.ReadUInt = function() return table.remove(q, 1) end
        net.ReadData = function() return piece end
        net["recv_lc_big"]()
    end
end)
net.ReadUInt, net.ReadData, net.ReadString, net.Receivers = rU, rD, rS, rcv
if not okR then return "net pieces: " .. tostring(errR) end
if got ~= whole then return "net: a send in pieces didn't reach its receiver whole" end
if net.ReadUInt ~= rU or net.ReadData ~= rD then return "net: the readers weren't put back" end
local okH, errH = pcall(hook.t.InitPostEntity.LivingCityNetReady)
if not okH then return "net ready: " .. tostring(errH) end
_globals.lc_nettest_g, _globals.lc_nettest_g_2, _globals.lc_nettest_g_parts = "abc", "def", 2
if LC.GetGlobalLong("lc_nettest_g", "") ~= "abcdef" then return "net: a long global string isn't read back whole" end
_globals.lc_nettest_g, _globals.lc_nettest_g_2, _globals.lc_nettest_g_parts = nil, nil, nil
return nil
""")
if err:
    problems = (problems + "\n" if problems else "") + str(err)

# the people's name tags (sh_livingcity_npcstr.lua): the server's answer fills the game's copy, readers
# read it through LC.NPCStr, a removed one is forgotten, and the game asks after a far one it reads
err = L.execute(r"""
local S = LC.NPCStrNet
if not (S and S.Take and S.Ask and net["recv_lc_npcstr"] and timer.list.LivingCityNPCStr) then
    return "npc tags: the receiver, the asking or its timer is missing"
end
local npc = ents.Create("npc_citizen")
npc:SetPos(Vector(90000, 0, 0))
local idx = npc:EntIndex()
if LC.NPCStr(npc, "lc_pname", "none") ~= "none" then return "npc tags: an NPC with no answer yet should read as the default" end
local rU, rS = net.ReadUInt, net.ReadString
local q, qs = { 0, 1, idx, 2, 1, 3 }, { "Mira Holt", "fixing a streetlight" } -- (none gone; one NPC: name and doing)
net.ReadUInt = function() return table.remove(q, 1) end
net.ReadString = function() return table.remove(qs, 1) end
local okT, errT = pcall(net["recv_lc_npcstr"])
net.ReadUInt, net.ReadString = rU, rS
if not okT then return "npc tags receive: " .. tostring(errT) end
if LC.NPCStr(npc, "lc_pname", "") ~= "Mira Holt" or LC.NPCStr(npc, "lc_doing", "") ~= "fixing a streetlight" then return "npc tags: the name sent didn't reach LC.NPCStr" end
local sentAsk, wrote = false, {}
local wS, wU, sts = net.WriteUInt, net.Start, net.SendToServer
net.Start = function(n) if n == "lc_npcstr_ask" then sentAsk = true end end
net.WriteUInt = function(v) wrote[#wrote + 1] = v end
net.SendToServer = function() end
local okA, errA = pcall(S.Ask)
net.WriteUInt, net.Start, net.SendToServer = wS, wU, sts
if not okA then return "npc tags ask: " .. tostring(errA) end
if not sentAsk or wrote[1] ~= 1 or wrote[2] ~= idx then return "npc tags: a far NPC read on screen isn't asked after" end
q = { 1, idx, 0 }
net.ReadUInt = function() return table.remove(q, 1) end
pcall(net["recv_lc_npcstr"])
net.ReadUInt = rU
if LC.NPCStr(npc, "lc_pname", "gone") ~= "gone" then return "npc tags: a removed NPC's tags weren't forgotten" end
local okF, errF = pcall(timer.list.LivingCityNPCStr.fn)
if not okF then return "npc tags timer: " .. tostring(errF) end
npc:Remove()
return nil
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
