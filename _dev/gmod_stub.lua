-- Minimal fake Garry's Mod for exercising Living City server logic outside the game.
SERVER, CLIENT = true, false
local now = 0
function CurTime() return now end
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
function VMT:DistToSqr(o) return (self - o):LengthSqr() end
function VMT:Distance(o) return (self - o):Length() end
function VMT:Normalize() local l = self:Length() if l > 0 then self.x, self.y, self.z = self.x / l, self.y / l, self.z / l end end
function VMT:GetNormalized() local v = Vector(self.x, self.y, self.z) v:Normalize() return v end
function VMT:Dot(o) return self.x * o.x + self.y * o.y + self.z * o.z end
function VMT:Angle() return Angle(0, math.deg(math.atan2(self.y, self.x)), 0) end
vector_origin = Vector(0, 0, 0)
local AMT = {}
AMT.__index = AMT
function Angle(p, y, r) return setmetatable({ p = p or 0, y = y or 0, r = r or 0 }, AMT) end
function AMT:Forward() local y = math.rad(self.y) return Vector(math.cos(y), math.sin(y), 0) end
angle_zero = Angle()
function Color(r, g, b, a) return { r = r, g = g, b = b, a = a or 255 } end
color_white, color_black = Color(255, 255, 255), Color(0, 0, 0)

function math.Rand(a, b) return a + math.random() * (b - a) end
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
function CreateConVar(name, def) if not convars[name] then convars[name] = setmetatable({ v = def }, CVMT) end return convars[name] end
function GetConVar(name) return convars[name] end
function RunConsoleCommand(name, val) if convars[name] then convars[name].v = val end end
function _setcvar(n, v) convars[n].v = v end

hook = { t = {} }
function hook.Add(ev, id, fn) hook.t[ev] = hook.t[ev] or {} hook.t[ev][id] = fn end
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
function net.Send() table.insert(net.sent, cur) end
function net.Broadcast() table.insert(net.sent, cur) end
function net.Receive(n, fn) net["recv_" .. n] = fn end
net._q = {}
function net.ReadUInt() return table.remove(net._q, 1) end
function net.ReadString() return table.remove(net._q, 1) end
function net.ReadBool() return table.remove(net._q, 1) == true end
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
function util.TraceLine(t)
    if t.endpos.z < t.start.z - 100 then -- downward ground probe
        return { Hit = true, HitPos = Vector(t.start.x, t.start.y, 0), HitNormal = Vector(0, 0, 1), Fraction = 0.2 }
    end
    local hit = _blocked(t.start, t.endpos)
    return { Hit = hit, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), Fraction = hit and 0.5 or 1 }
end
MASK_NPCSOLID, MASK_OPAQUE, MASK_NPCSOLID_BRUSHONLY, MASK_SHOT_HULL = 1, 2, 3, 4
SCHED_FORCED_GO, SCHED_FORCED_GO_RUN, SCHED_IDLE_STAND, SCHED_CHASE_ENEMY = 71, 72, 1, 17
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
    function R:Close() end
    return R
end
MOVETYPE_WALK, MOVETYPE_NOCLIP = 2, 8
navmesh = { IsLoaded = function() return false end }
game = {
    GetWorld = function() return nil end,
    GetMap = function() return "rp_test" end, SinglePlayer = function() return false end,
    MaxPlayers = function() return 128 end, IsDedicated = function() return true end,
}
engine = { ActiveGamemode = function() return "sandbox" end, TickInterval = function() return 0.015 end }
GAMEMODE = {}
_globals = {}
function SetGlobal2String(k, v) _globals[k] = v end
function SetGlobal2Float(k, v) _globals[k] = v end
function SetGlobal2Bool(k, v) _globals[k] = v end
IN_USE = 32
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
function EMT:EntIndex() return self.idx end
function EMT:SetIdealYawAndUpdate(y) self.yaw = y end
function EMT:SetEnemy(e) self.enemy = e end
function EMT:GetEnemy() return self.enemy end
function EMT:ClearEnemyMemory() end
function EMT:GetForward() return Vector(1, 0, 0) end
function EMT:WorldSpaceCenter() return self.pos + Vector(0, 0, 36) end
function EMT:EyePos() return self.pos + Vector(0, 0, 64) end
function EMT:Fire(input)
    self.fired = self.fired or {}
    table.insert(self.fired, input)
    if input == "Lock" then self.locked = true elseif input == "Unlock" then self.locked = false end
end
function EMT:SelectWeightedSequence() return -1 end
function EMT:GetSequenceName() return "" end
function EMT:IsNPC() return self.cls:sub(1, 4) == "npc_" end
function EMT:IsPlayer() return false end
function EMT:MapCreationID() return self.mapid or -1 end
function EMT:GetInternalVariable(k) if k == "m_bLocked" then return self.locked == true end end
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
function EMT:UpdateEnemyMemory(e, pos) self.enemyMemory = pos end
function EMT:Give(c) self.weps = self.weps or {} table.insert(self.weps, c) end
function EMT:SelectWeapon(c) self.activeWeapon = c end
function EMT:SetNoDraw(b) self.nodraw = b end
function EMT:LocalToWorld(v) return self.pos + v end
function EMT:SetSkin(n) self.skin = n end

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
function PMT:EyeAngles() return Angle() end
function PMT:GetAimVector() return self.aim end
function PMT:EyePos() return self.pos + Vector(0, 0, 64) end
function PMT:Spawn() hook.Run("PlayerSpawn", self) end
function PMT:Kick(r) self.kicked = r end
function PMT:SetMaxHealth(h) self.maxhp = h end
function PMT:SetArmor(a) self.armor = a end
function PMT:SetWalkSpeed() end
function PMT:SetSlowWalkSpeed() end
function PMT:SetCrouchedWalkSpeed() end
function PMT:SetJumpPower() end
function PMT:GetRunSpeed() return 200 end
function PMT:SetRunSpeed() end
function PMT:SetupHands() end
function PMT:SelectWeapon() end
function PMT:GiveAmmo() end
function PMT:GetActiveWeapon() return nil end
function PMT:ExitVehicle() end
function PMT:IsOnGround() return self.ground ~= false end
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
function PMT:StripWeapon(c) for i = #self.weps, 1, -1 do if self.weps[i] == c then table.remove(self.weps, i) end end end

-- damage info
local DMT = {}
DMT.__index = DMT
function _dmg(attacker, amount, dtype)
    return setmetatable({ attacker = attacker, amount = amount, dtype = dtype or 0 }, DMT)
end
function DMT:GetAttacker() return self.attacker end
function DMT:GetInflictor() return self.inflictor end
function DMT:GetDamage() return self.amount end
function DMT:SetDamage(v) self.amount = v end
function DMT:IsDamageType(t) return bit.band(self.dtype, t) ~= 0 end

-- run the whole server for `seconds` in 0.1s steps
function _run(seconds)
    for _ = 1, math.floor(seconds * 10 + 0.5) do
        _advance(0.1)
        _simulate(0.1)
        _runtimers()
    end
end
