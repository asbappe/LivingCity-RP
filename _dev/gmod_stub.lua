-- Minimal fake Garry's Mod for exercising Living City server logic outside the game.
SERVER, CLIENT = true, false
local now = 0
function CurTime() return now end
function FrameTime() return 0.1 end
function SysTime() return os.clock() end
function _advance(dt) now = now + dt end

-- Vector / Angle / Color
local VMT = {}
VMT.__index = VMT
function Vector(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, VMT) end
VMT.__add = function(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
VMT.__sub = function(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
VMT.__mul = function(a, b) if type(a) == "number" then a, b = b, a end return Vector(a.x * b, a.y * b, a.z * b) end
VMT.__div = function(a, b) return Vector(a.x / b, a.y / b, a.z / b) end
VMT.__unm = function(a) return Vector(-a.x, -a.y, -a.z) end
VMT.__eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end
VMT.__tostring = function(a) return string.format("(%.0f %.0f %.0f)", a.x, a.y, a.z) end
function VMT:LengthSqr() return self.x ^ 2 + self.y ^ 2 + self.z ^ 2 end
function VMT:Length() return math.sqrt(self:LengthSqr()) end
function VMT:Length2DSqr() return self.x ^ 2 + self.y ^ 2 end
function VMT:Length2D() return math.sqrt(self.x ^ 2 + self.y ^ 2) end
function VMT:DistToSqr(o) return (self - o):LengthSqr() end
function VMT:Distance(o) return (self - o):Length() end
function VMT:Normalize() local l = self:Length() if l > 0 then self.x, self.y, self.z = self.x / l, self.y / l, self.z / l end end
function VMT:GetNormalized() local v = Vector(self.x, self.y, self.z) v:Normalize() return v end
function VMT:Dot(o) return self.x * o.x + self.y * o.y + self.z * o.z end
function VMT:Cross(o) return Vector(self.y * o.z - self.z * o.y, self.z * o.x - self.x * o.z, self.x * o.y - self.y * o.x) end
function VMT:Angle() return Angle(0, math.deg(math.atan2(self.y, self.x)), 0) end
vector_origin = Vector(0, 0, 0)
local AMT = {}
AMT.__index = AMT
function Angle(p, y, r) return setmetatable({ p = p or 0, y = y or 0, r = r or 0 }, AMT) end
AMT.__add = function(a, b) return Angle(a.p + b.p, a.y + b.y, a.r + b.r) end
AMT.__mul = function(a, b) if type(a) == "number" then a, b = b, a end return Angle(a.p * b, a.y * b, a.r * b) end -- (an angle times a number, as in the game)
function AMT:Forward() local y = math.rad(self.y) return Vector(math.cos(y), math.sin(y), 0) end
function AMT:Up() return Vector(0, 0, 1) end
function AMT:Right() local y = math.rad(self.y - 90) return Vector(math.cos(y), math.sin(y), 0) end
-- (only turns about an upright axis are modelled: enough for drawing)
function AMT:RotateAroundAxis(axis, deg) if axis and math.abs(axis.z or 0) > 0.9 then self.y = self.y + deg * (axis.z > 0 and 1 or -1) end end
angle_zero = Angle()
function Color(r, g, b, a) return { r = r, g = g, b = b, a = a or 255 } end
function VectorRand() return Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, 1)) end
color_white, color_black = Color(255, 255, 255), Color(0, 0, 0)

function math.Rand(a, b) return a + math.random() * (b - a) end
function Lerp(t, a, b) return a + (b - a) * t end
function LerpVector(t, a, b) return a + (b - a) * t end
function LerpAngle(t, a, b) return Angle(a.p + (b.p - a.p) * t, a.y + (b.y - a.y) * t, a.r + (b.r - a.r) * t) end
function math.Approach(cur, target, inc)
    inc = math.abs(inc)
    if cur < target then return math.min(cur + inc, target) elseif cur > target then return math.max(cur - inc, target) end
    return target
end
function math.Clamp(v, a, b) return math.max(a, math.min(b, v)) end
function math.AngleDifference(a, b) return (a - b + 180) % 360 - 180 end
function string.StartWith(s, p) return s:sub(1, #p) == p end
function string.Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function string.NiceTime(s) return tostring(math.floor(s)) .. "s" end
function table.Count(t) local c = 0 for _ in pairs(t) do c = c + 1 end return c end
function table.IsEmpty(t) return next(t) == nil end
function table.HasValue(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
function table.GetKeys(t) local o = {} for k in pairs(t) do o[#o + 1] = k end return o end
function table.Copy(t) local o = {} for k, v in pairs(t) do o[k] = type(v) == "table" and table.Copy(v) or v end return o end
function SortedPairs(t)
    local keys = table.GetKeys(t)
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local i = 0
    return function() i = i + 1 local k = keys[i] if k ~= nil then return k, t[k] end end
end
function istable(x) return type(x) == "table" end
function isstring(x) return type(x) == "string" end
function isnumber(x) return type(x) == "number" end
function isbool(x) return type(x) == "boolean" end
bit = require("bit")

FCVAR_ARCHIVE, FCVAR_REPLICATED = 128, 8192
local convars = {}
local CVMT = {}
CVMT.__index = CVMT
function CVMT:GetInt() return math.floor(tonumber(self.v) or 0) end
function CVMT:GetFloat() return tonumber(self.v) or 0 end
function CVMT:GetBool() return (tonumber(self.v) or 0) ~= 0 end
function CVMT:GetString() return tostring(self.v) end
function CVMT:SetInt(v) self.v = math.floor(v) end
_cvarDefaults = {} -- (every setting's default as the code makes it: the core snapshot test, CORE.md)
function CreateConVar(name, def, flags, help, mn, mx)
    if not convars[name] then convars[name] = setmetatable({ v = def }, CVMT) _cvarDefaults[name] = tostring(def) end
    -- (as shared.lua's wrapper does in the game: every setting's default and help, for the Endings menu)
    LC_SettingInfo = LC_SettingInfo or {}
    LC_SettingInfo[name] = { d = tostring(def or ""), help = type(help) == "string" and help or "", min = tonumber(mn), max = tonumber(mx) }
    return convars[name]
end
function GetConVar(name) return convars[name] end
-- change callbacks fire for RunConsoleCommand (the console, the editor), not _setcvar (a test's own setup)
cvars = { cb = {} }
function cvars.AddChangeCallback(name, fn, id) cvars.cb[name] = cvars.cb[name] or {} cvars.cb[name][id or fn] = fn end
function RunConsoleCommand(name, val)
    local cv = convars[name]
    if not cv then return end
    local old = tostring(cv.v)
    cv.v = val
    for _, fn in pairs(cvars.cb[name] or {}) do fn(name, old, tostring(val)) end
end
function ConVarExists(name) return convars[name] ~= nil end
function _setcvar(n, v) convars[n].v = v end

hook = { t = {} }
function hook.Add(ev, id, fn) hook.t[ev] = hook.t[ev] or {} hook.t[ev][id] = fn end
function hook.Remove(ev, id) if hook.t[ev] then hook.t[ev][id] = nil end end
function hook.Run(ev, ...)
    local hs = hook.t[ev]
    if not hs then return end
    for _, fn in pairs(hs) do
        local a, b, c = fn(...)
        if a ~= nil then return a, b, c end
    end
end

timer = { list = {}, simple = {} }
function timer.Create(name, delay, reps, fn) timer.list[name] = { delay = delay, fn = fn, next = now + delay } end
function timer.Remove(name) timer.list[name] = nil end
function timer.Simple(d, fn) table.insert(timer.simple, { at = now + d, fn = fn }) end
function _runtimers()
    for _, t in pairs(timer.list) do if now >= t.next then t.next = now + t.delay; t.fn() end end
    local due = {}
    for i = #timer.simple, 1, -1 do
        local s = timer.simple[i]
        if now >= s.at then table.insert(due, s) table.remove(timer.simple, i) end
    end
    for _, s in ipairs(due) do s.fn() end
end

concommand = { list = {} }
function concommand.Add(n, fn) concommand.list[n] = fn end

net = { sent = {} }
local cur
function net.Start(n) cur = { name = n, data = {} } end
function net.WriteUInt(v) table.insert(cur.data, v) end
function net.WriteData(d) table.insert(cur.data, d) end
function net.WriteString(s) table.insert(cur.data, s) end
function net.WriteBool(b) table.insert(cur.data, b) end
function net.WriteVector(v) table.insert(cur.data, v) end
function net.WriteFloat(f) table.insert(cur.data, f) end
function net.WriteEntity(e) table.insert(cur.data, e) end
function net.WriteInt(v) table.insert(cur.data, v) end
function net.WriteTable(t) table.insert(cur.data, t) end
function net.Send(to) cur.to = to table.insert(net.sent, cur) end
function net.Broadcast() table.insert(net.sent, cur) end
function net.SendOmit(p) cur.omit = p table.insert(net.sent, cur) end
function net.Receive(n, fn) net["recv_" .. n] = fn end
net._q = {}
function net.ReadUInt() return table.remove(net._q, 1) end
function net.ReadInt() return table.remove(net._q, 1) end
function net.ReadVector() return table.remove(net._q, 1) end
function net.ReadString() return table.remove(net._q, 1) end
function net.ReadBool() return table.remove(net._q, 1) == true end
function net.ReadEntity() local v = table.remove(net._q, 1) return v end
function net.ReadFloat() return table.remove(net._q, 1) end
function net.ReadTable() return table.remove(net._q, 1) end
function _netcall(name, ply, ...) net._q = { ... } net["recv_" .. name](0, ply) end
function _lastnet(name) for i = #net.sent, 1, -1 do if net.sent[i].name == name then return net.sent[i] end end end

util = util or {}
function util.AddNetworkString() end
function util.Compress(s) return s end
function util.CRC(s) local h = 0 for i = 1, #s do h = (h * 31 + s:byte(i)) % 4294967296 end return tostring(h) end

-- walls: 2D segments that block traces and NPC movement
_walls = {}
local function inter(p1, p2, p3, p4)
    local d = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
    if d == 0 then return false end
    local u = ((p3.x - p1.x) * (p4.y - p3.y) - (p3.y - p1.y) * (p4.x - p3.x)) / d
    local v = ((p3.x - p1.x) * (p2.y - p1.y) - (p3.y - p1.y) * (p2.x - p1.x)) / d
    return u >= 0 and u <= 1 and v >= 0 and v <= 1
end
function _blocked(a, b) for _, w in ipairs(_walls) do if inter(a, b, w.a, w.b) then return true end end return false end
function util.TraceHull(t) local hit = _blocked(t.start, t.endpos) return { Hit = hit, HitPos = t.endpos, StartSolid = false, Fraction = hit and 0.5 or 1 } end
-- where a sideways trace meets the nearest wall: the point, and the wall's face toward the trace
local function wallHit(a, b)
    local best
    for _, w in ipairs(_walls) do
        local p1, p2, p3, p4 = a, b, w.a, w.b
        local d = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
        if d ~= 0 then
            local u = ((p3.x - p1.x) * (p4.y - p3.y) - (p3.y - p1.y) * (p4.x - p3.x)) / d
            local v = ((p3.x - p1.x) * (p2.y - p1.y) - (p3.y - p1.y) * (p2.x - p1.x)) / d
            if u >= 0 and u <= 1 and v >= 0 and v <= 1 and (not best or u < best.u) then
                local n = Vector(-(w.b.y - w.a.y), w.b.x - w.a.x, 0):GetNormalized()
                if n:Dot(a - b) < 0 then n = -n end
                best = { u = u, n = n }
            end
        end
    end
    return best
end
-- solid props (a sink, a shelf): they stop an ordinary trace, but not a brush-only one,
-- the way the map's static props behave. Spheres: { pos = Vector, r = number }.
_props = {}
local function propHit(a, b)
    local d = b - a
    local len = d:Length()
    if len < 0.001 then return nil end
    local dir = d / len
    local best
    for _, p in ipairs(_props) do
        local oc = a - p.pos
        local bq = oc:Dot(dir)
        local disc = bq * bq - (oc:Dot(oc) - p.r * p.r)
        if disc >= 0 then
            local u = -bq - math.sqrt(disc)
            if u >= 0 and u <= len and (not best or u < best) then best = u end
        end
    end
    return best and best / len or nil
end
function util.TraceLine(t)
    if t.endpos.z < t.start.z - 100 then -- downward ground probe
        -- (a test can give the world a shape: _groundFn(x, y) is the floor's height there, nil for a drop)
        local gz = 0
        if _groundFn then gz = _groundFn(t.start.x, t.start.y) end
        if not gz or (_groundFn and (gz < t.endpos.z or gz > t.start.z)) then return { Hit = false, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), Fraction = 1 } end
        return { Hit = true, HitPos = Vector(t.start.x, t.start.y, gz), HitNormal = Vector(0, 0, 1), Fraction = 0.2 }
    end
    local h = wallHit(t.start, t.endpos)
    local brushOnly = t.mask == MASK_NPCSOLID_BRUSHONLY or t.mask == MASK_SOLID_BRUSHONLY
    local pf = (not brushOnly) and #_props > 0 and propHit(t.start, t.endpos) or nil
    if pf and (not h or pf < h.u) then
        local at = t.start + (t.endpos - t.start) * pf
        return { Hit = true, HitPos = at, HitNormal = Vector(0, 0, 1), Fraction = pf }
    end
    if not h then return { Hit = false, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), Fraction = 1 } end
    return { Hit = true, HitPos = t.start + (t.endpos - t.start) * h.u, HitNormal = h.n, Fraction = math.min(h.u, 0.5) }
end
MASK_NPCSOLID, MASK_OPAQUE, MASK_NPCSOLID_BRUSHONLY, MASK_SHOT_HULL = 1, 2, 3, 4
MASK_SOLID_BRUSHONLY = 5
SCHED_FORCED_GO, SCHED_FORCED_GO_RUN, SCHED_IDLE_STAND, SCHED_CHASE_ENEMY = 71, 72, 1, 17
SCHED_RANGE_ATTACK1 = 43
SCREENFADE = { IN = 1, OUT = 2 }
D_HT, D_FR, D_LI, D_NU = 1, 2, 3, 4
DMG_CLUB, DMG_SLASH = 128, 4

_files = {}
file = {}
function file.Read(p) return _files[p] end
function file.Exists(p) return _files[p] ~= nil end
function file.Write(p, s) _files[p] = s end
function file.Append(p, s) _files[p] = (_files[p] or "") .. s end
function file.Delete(p) _files[p] = nil end
function file.CreateDir() end
function file.Find(pattern)
    local dir, glob = pattern:match("^(.*)/([^/]*)$")
    local lp = "^" .. glob:gsub("%.", "%%."):gsub("%*", ".*") .. "$"
    local out = {}
    for path in pairs(_files) do
        local d, name = path:match("^(.*)/([^/]*)$")
        if d == dir and name:match(lp) then out[#out + 1] = name end
    end
    table.sort(out)
    return out, {}
end
-- binary reads of a file in _files (for the map's AI nodegraph)
local ffi = require("ffi")
function file.Open(path)
    local data = _files[path]
    if not data then return nil end
    local buf = ffi.new("uint8_t[?]", #data + 8)
    ffi.copy(buf, data, #data)
    local pos = 0
    local R = {}
    local function rd(t, n) local v = ffi.cast(t .. "*", buf + pos)[0] pos = pos + n return tonumber(v) end
    function R:ReadLong() return rd("int32_t", 4) end
    function R:ReadFloat() return rd("float", 4) end
    function R:ReadByte() return rd("uint8_t", 1) end
    function R:ReadUShort() return rd("uint16_t", 2) end
    function R:ReadShort() return rd("int16_t", 2) end
    function R:ReadULong() return rd("uint32_t", 4) end
    function R:Read(n) local out = data:sub(pos + 1, pos + n) pos = pos + n return out end
    function R:Skip(n) pos = pos + n end
    function R:Close() end
    return R
end
MOVETYPE_WALK, MOVETYPE_NOCLIP, MOVETYPE_LADDER = 2, 8, 9
MOVETYPE_NONE = 0
function AddOriginToPVS() end
navmesh = { IsLoaded = function() return false end }
game = {
    GetWorld = function() return nil end,
    GetMap = function() return "rp_test" end, SinglePlayer = function() return false end,
    MaxPlayers = function() return 128 end, IsDedicated = function() return true end,
}
engine = { ActiveGamemode = function() return "livingcity" end, TickInterval = function() return 0.015 end }
_lightstyles = {}
function engine.LightStyle(i, s) _lightstyles[i] = s end
GAMEMODE = {}
_globals = {}
function SetGlobal2String(k, v) _globals[k] = v end
function SetGlobal2Float(k, v) _globals[k] = v end
function SetGlobal2Bool(k, v) _globals[k] = v end
function GetGlobal2String(k, d) local v = _globals[k] if v == nil then return d end return v end
GetGlobal2Float, GetGlobal2Bool, GetGlobal2Int = GetGlobal2String, GetGlobal2String, GetGlobal2String
SetGlobal2Entity, GetGlobal2Entity = SetGlobal2String, GetGlobal2String
SetGlobal2Int, GetGlobal2Int = SetGlobal2String, GetGlobal2String
SetGlobal2Vector, GetGlobal2Vector = SetGlobal2String, GetGlobal2String
IN_USE = 32
ACT_HL2MP_IDLE, ACT_HL2MP_SIT = 1780, 1977
IN_SPEED = 131072
IN_ATTACK, IN_JUMP, IN_DUCK, IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT, IN_RELOAD = IN_ATTACK or 1, IN_JUMP or 2, IN_DUCK or 4, IN_FORWARD or 8, IN_BACK or 16, IN_MOVELEFT or 512, IN_MOVERIGHT or 1024, IN_RELOAD or 8192
IN_JUMP, IN_DUCK = 2, 4
_errors = {}
function ErrorNoHalt(...) table.insert(_errors, table.concat({ ... }, " ")) end
function SafeRemoveEntityDelayed(e, d) timer.Simple(d, function() if IsValid(e) then e:Remove() end end) end
function AddCSLuaFile() end
function FindMetaTable() return {} end
function IsValid(x) return type(x) == "table" and x.IsValid ~= nil and x:IsValid() end

-- entities
local all = {}
local nextIdx = 1
local EMT = {}
EMT.__index = EMT
_EMT = EMT
ents = {}
function ents.GetAll() local o = {} for e in pairs(all) do o[#o + 1] = e end return o end
function ents.Create(cls)
    local e = setmetatable({ cls = cls, pos = Vector(), ang = Angle(), kv = {}, valid = true, hp = 100, maxhp = 100,
        idx = nextIdx, nw = {}, sched = SCHED_IDLE_STAND, rel = {}, name = "",
        model = "models/humans/group01/male_01.mdl", sim = cls:sub(1, 4) == "npc_" }, EMT)
    nextIdx = nextIdx + 1
    all[e] = true
    if hook and hook.Run then hook.Run("OnEntityCreated", e) end
    return e
end
function ents.FindInSphere(pos, r) local o = {} for e in pairs(all) do if e.pos:DistToSqr(pos) < r * r then o[#o + 1] = e end end return o end
function ents.FindByClass(c) local o = {} for e in pairs(all) do if e.cls == c then o[#o + 1] = e end end return o end
function ents.GetMapCreatedEntity(id) for e in pairs(all) do if e.mapid == id then return e end end end
function EMT:IsValid() return self.valid end
function EMT:Remove() if not self.valid then return end self.valid = false all[self] = nil hook.Run("EntityRemoved", self) end
function EMT:GetClass() return self.cls end
function EMT:SetPos(p) self.pos = Vector(p.x, p.y, p.z) end
function EMT:GetPos() return Vector(self.pos.x, self.pos.y, self.pos.z) end
function EMT:SetAngles(a) self.ang = a end
function EMT:GetAngles() return self.ang end
function EMT:SetKeyValue(k, v) self.kv[k] = v end
function EMT:Spawn() end
function EMT:Activate() end
function EMT:AddRelationship() end
function EMT:AddEntityRelationship(p, d) self.rel[p] = d; _relcalls = (_relcalls or 0) + 1 end
function EMT:SetName(n) self.name = n end
function EMT:GetName() return self.name end
function EMT:SetNW2String(k, v) self.nw[k] = v end
function EMT:GetNW2String(k, d) local v = self.nw[k] if v == nil then return d end return v end
EMT.SetNW2Vector, EMT.GetNW2Vector = EMT.SetNW2String, EMT.GetNW2String
EMT.SetNW2Float, EMT.GetNW2Float = EMT.SetNW2String, EMT.GetNW2String
EMT.SetNW2Int, EMT.GetNW2Int = EMT.SetNW2String, EMT.GetNW2String
EMT.SetNW2Entity, EMT.GetNW2Entity = EMT.SetNW2String, EMT.GetNW2String
function EMT:GetModel() return self.model end
function EMT:GetOwner() return self.owner end
function EMT:SetModel(m) self.model = m end
function EMT:SetLastPosition(p) self.goal = Vector(p.x, p.y, p.z) end
function EMT:SetSchedule(s) self.sched = s end
function EMT:IsCurrentSchedule(s) return self.sched == s end
function EMT:Health() return self.hp end
function EMT:SetHealth(h) self.hp = h end
function EMT:GetMaxHealth() return self.maxhp end
_sounds = {}
function EMT:EmitSound(s) table.insert(_sounds, s) end
function EMT:StopSound(s) end
function EMT:EntIndex() return self.idx end
function EMT:SetIdealYawAndUpdate(y) self.yaw = y end
function EMT:SetEnemy(e) self.enemy = e end
function EMT:GetEnemy() return self.enemy end
function EMT:ClearEnemyMemory() end
function EMT:GetForward() return Vector(1, 0, 0) end
function EMT:GetUp() return Vector(0, 0, 1) end
function EMT:GetModelBounds() return self:OBBMins(), self:OBBMaxs() end
function EMT:GetModelScale() return self.mscale or 1 end
function EMT:GetRight() return Vector(0, -1, 0) end
function EMT:EyeAngles() return self.ang or Angle() end
function EMT:SetParent(p) self.parent = p end
function EMT:GetParent() return self.parent end
function EMT:WorldSpaceCenter() return self.pos + Vector(0, 0, 36) end
function EMT:EyePos() return self.pos + Vector(0, 0, 64) end
function EMT:Fire(input)
    self.fired = self.fired or {}
    table.insert(self.fired, input)
    if input == "Lock" then self.locked = true elseif input == "Unlock" then self.locked = false end
    -- doors open and shut (a locked one doesn't open)
    if input == "Open" and not self.locked then self.isOpen = true
    elseif input == "Close" then self.isOpen = false
    elseif input == "Toggle" and not self.locked then self.isOpen = not self.isOpen end
end
function EMT:SelectWeightedSequence(a) return (self.acts and self.acts[a]) or -1 end
function EMT:LookupSequence(n) return (self.seqs and self.seqs[n]) or -1 end
function EMT:GetSequenceName() return "" end
function EMT:IsNPC() return self.cls:sub(1, 4) == "npc_" end
function EMT:IsPlayer() return false end
function EMT:MapCreationID() return self.mapid or -1 end
function EMT:GetInternalVariable(k)
    if k == "m_bLocked" then return self.locked == true end
    if k == "m_eDoorState" and self.cls == "prop_door_rotating" then return self.isOpen and 2 or 0 end
    if k == "m_toggle_state" and (self.cls == "func_door" or self.cls == "func_door_rotating") then return self.isOpen and 0 or 1 end
end
function EMT:OBBMaxs() return self.obbmax or Vector(2, 24, 96) end
function EMT:OBBMins() return self.obbmin or Vector(-2, -24, 0) end
function EMT:GetSpawnFlags() return 0 end
function EMT:GetVelocity() return self.vel or Vector() end
function EMT:GetPhysicsObject() return nil end
function EMT:TakeDamage(n) self.hp = self.hp - n; _damage = (_damage or 0) + n end
function EMT:Activate() end
function EMT:SetNW2Bool(k, v) self.nw[k] = v end
function EMT:GetNW2Bool(k, d) local v = self.nw[k] if v == nil then return d end return v end
function EMT:SetNotSolid(b) self.notsolid = b end
function EMT:SetCollisionGroup(g) self.colgroup = g end
function EMT:GetCollisionGroup() return self.colgroup or 0 end
function EMT:UpdateEnemyMemory(e, pos) self.enemyMemory = pos end
function EMT:Give(c) self.weps = self.weps or {} table.insert(self.weps, c) end
-- an NPC's gun: what it was given or selected last, else what it spawned with
function EMT:GetActiveWeapon()
    local cls = self.activeWeapon or (self.weps and self.weps[#self.weps]) or (self.kv and self.kv.additionalequipment)
    if not cls then return nil end
    local owner = self
    return { GetClass = function() return cls end, IsValid = function() return true end,
        GetPos = function() return owner:GetPos() + Vector(0, 0, 40) end, GetAngles = function() return Angle() end }
end
function EMT:GetMaxClip1() return 30 end
function EMT:SetClip1(n) self.clip1 = n end
function EMT:Clip1() return self.clip1 or 30 end
function EMT:SelectWeapon(c) self.activeWeapon = c end
function EMT:SetNoDraw(b) self.nodraw = b end
function EMT:LocalToWorld(v) return self.pos + v end
function EMT:WorldToLocal(v) return v - self.pos end
function EMT:CollisionRulesChanged() self.lcRulesChanged = (self.lcRulesChanged or 0) + 1 end
function EMT:SetSkin(n) self.skin = n end
function EMT:GetSkin() return self.skin or 0 end
function EMT:GetColor() return self.col or Color(255, 255, 255, 255) end
function EMT:SetColor(c) self.col = c end
function EMT:GetMaterial() return self.mat or "" end
function EMT:SetMaterial(m) self.mat = m end
function EMT:SetRenderMode(m) self.rendermode = m end
function EMT:GetNumBodyGroups() return 1 end
function EMT:GetBodygroup(i) return (self.bg or {})[i] or 0 end
function EMT:SetBodygroup(i, v) self.bg = self.bg or {} self.bg[i] = v end
function EMT:SetModelScale(s) self.mscale = s end

-- NPC movement: walk 150 u/s (run 300) toward the goal; walls stop them and end the schedule.
function _simulate(dt)
    for e in pairs(all) do
        if e.sim and e.goal and (e.sched == SCHED_FORCED_GO or e.sched == SCHED_FORCED_GO_RUN) then
            local speed = (e.sched == SCHED_FORCED_GO_RUN and 300 or 150) * dt
            local d = e.goal - e.pos
            local len = d:Length()
            local step = len <= speed and Vector(e.goal.x, e.goal.y, e.goal.z) or (e.pos + d * (speed / len))
            if _blocked(e.pos, step) then
                e.blockedTicks = (e.blockedTicks or 0) + 1
                if e.blockedTicks > 2 then e.sched = SCHED_IDLE_STAND; e.blockedTicks = 0 end
            else
                e.pos = step
                if len <= speed then e.sched = SCHED_IDLE_STAND end
            end
        end
    end
end

-- players
local PMT = setmetatable({}, { __index = EMT })
PMT.__index = PMT
_players = {}
player = {}
function player.GetAll() local o = {} for _, p in ipairs(_players) do if p.valid then o[#o + 1] = p end end return o end
function _makeplayer(name, pos)
    local p = setmetatable({ cls = "player", pos = pos or Vector(), ang = Angle(), valid = true, hp = 100, maxhp = 100,
        nw = {}, nick = name, sid = "STEAM_0:0:" .. (#_players + 1), pdata = {},
        weps = { "weapon_pistol", "weapon_crowbar" }, alive = true, aim = Vector(0, 0, 1), idx = 1000 + #_players }, PMT)
    table.insert(_players, p)
    all[p] = true
    return p
end
function PMT:IsPlayer() return true end
function PMT:IsNPC() return false end
function PMT:Nick() return self.nick end
function PMT:SteamID() return self.sid end
function PMT:SteamID64() return "7656119" .. tostring(self.sid) end
function PMT:Alive() return self.alive end
function PMT:IsAdmin() return self.admin == true end
function PMT:IsSuperAdmin() return self.superadmin == true end
function PMT:IsListenServerHost() return false end
function PMT:ChatPrint(m) self.chat = self.chat or {} table.insert(self.chat, m) end
function PMT:GetPData(k, d) local v = self.pdata[k] if v == nil then return d end return v end
function PMT:SetPData(k, v) self.pdata[k] = tostring(v) end
function PMT:RemovePData(k) self.pdata[k] = nil end
function PMT:GetWeapons() local o = {} for _, c in ipairs(self.weps) do local cls = c o[#o + 1] = { GetClass = function() return cls end } end return o end
function PMT:StripWeapons() self.weps = {} end
function PMT:Give(c) table.insert(self.weps, c) end
function PMT:InVehicle() return false end
function PMT:SetMoveType(m) self.movetype = m end
function PMT:SetEyeAngles() end
function PMT:SetLocalVelocity() end
function PMT:EyeAngles() return self.eyeang or Angle() end
function PMT:GetAimVector() return self.aim end
function PMT:GetShootPos() return self:GetPos() + Vector(0, 0, 64) end
function PMT:EyePos() return self.pos + Vector(0, 0, 64) end
function PMT:Spawn() hook.Run("PlayerSpawn", self) end
function PMT:Kick(r) self.kicked = r end
function PMT:SetMaxHealth(h) self.maxhp = h end
function PMT:SetArmor(a) self.armor = a end
function PMT:Armor() return self.armor or 0 end
function PMT:SetWalkSpeed(v) self.walkspeed = v end
function PMT:GetWalkSpeed() return self.walkspeed or 160 end
function PMT:KeyDown(k) return self.keys ~= nil and self.keys[k] == true end
function PMT:SetSlowWalkSpeed() end
function PMT:SetCrouchedWalkSpeed() end
function PMT:SetJumpPower() end
function PMT:GetRunSpeed() return self.runspeed or 260 end
function PMT:SetRunSpeed(v) self.runspeed = v end
function PMT:SetupHands() end
function PMT:SelectWeapon(c)
    if not self:HasWeapon(c) or self.active == c then return end
    local old = self:GetActiveWeapon()
    self.active = c
    hook.Run("PlayerSwitchWeapon", self, old, self:GetActiveWeapon())
end
function PMT:GiveAmmo(n, t) self.ammo = self.ammo or {} if t then self.ammo[t] = (self.ammo[t] or 0) + (n or 0) end end
function PMT:GetActiveWeapon()
    if not self.active or not self:HasWeapon(self.active) then return nil end
    local cls = self.active
    local AMMO = { weapon_pistol = 3, weapon_smg1 = 4, weapon_shotgun = 7, weapon_ar2 = 1, weapon_357 = 5 }
    return { GetClass = function() return cls end, IsValid = function() return true end, GetPrimaryAmmoType = function() return AMMO[cls] or -1 end }
end
function PMT:ExitVehicle() end
function PMT:IsOnGround() return self.ground ~= false end
function PMT:SetViewOffset(v) self.viewoff = v end
function PMT:GetViewOffset() return self.viewoff or Vector(0, 0, 64) end
function PMT:SetViewOffsetDucked(v) self.viewoffduck = v end
function PMT:ConCommand(c) self.cmds = self.cmds or {} table.insert(self.cmds, c) end
function PMT:Crouching() return self.crouch == true end
function PMT:HasWeapon(c) for _, w in ipairs(self.weps) do if w == c then return true end end return false end
function PMT:WaterLevel() return self.water or 0 end
function PMT:GetEyeTrace() return { Entity = self.lookingAt, HitPos = self.pos + Vector(50, 0, 0) } end
function PMT:SetNW2Bool(k, v) self.nw[k] = v end
function PMT:SetVelocity(v) self.pushed = v end
function PMT:Freeze(b) self.frozen = b end
function PMT:GetMoveType() return self.movetype or MOVETYPE_WALK end
function PMT:ScreenFade() end
function PMT:ViewPunch() end
-- armor takes 80% of an ordinary hit while it lasts (set p.armorSoak = true to model it)
function PMT:TakeDamage(n)
    if self.armorSoak and (self.armor or 0) > 0 then
        local toArmor = math.min(self.armor, n * 0.8)
        self.armor = self.armor - toArmor
        n = n - toArmor
    end
    self.hp = self.hp - n
    _damage = (_damage or 0) + n
end
function PMT:Kill() if not self.alive then return end self.alive = false hook.Run("PlayerDeath", self, self, self) end
function PMT:StripWeapon(c) for i = #self.weps, 1, -1 do if self.weps[i] == c then table.remove(self.weps, i) end end end

-- damage info
local DMT = {}
DMT.__index = DMT
gameevent = { Listen = function() end }
function util.RemovePData(sid, k) for _, p in ipairs(_players) do if p.sid == sid then p.pdata[k] = nil end end end
function _dmg(attacker, amount, dtype)
    return setmetatable({ attacker = attacker, amount = amount, dtype = dtype or 0 }, DMT)
end
function DMT:GetAttacker() return self.attacker end
function DMT:GetInflictor() return self.inflictor end
function DMT:GetDamage() return self.amount end
function DMT:SetDamage(v) self.amount = v end
function DMT:IsDamageType(t) return bit.band(self.dtype, t) ~= 0 end
function DMT:GetDamageType() return self.dtype end

-- run the whole server for `seconds` in 0.1s steps
function _run(seconds)
    for _ = 1, math.floor(seconds * 10 + 0.5) do
        _advance(0.1)
        _simulate(0.1)
        _runtimers()
    end
end

local AMMO_NAMES = { [1] = "AR2", [3] = "Pistol", [4] = "SMG1", [5] = "357", [7] = "Buckshot" }
game = game or {}
function game.GetAmmoName(i) return AMMO_NAMES[i] end
LC = LC or {} LC.TestMode = true -- the NPC loop does everything each tick here (no time budget)
function EffectData() return setmetatable({}, { __index = function() return function() end end }) end
util.Effect = util.Effect or function() end
