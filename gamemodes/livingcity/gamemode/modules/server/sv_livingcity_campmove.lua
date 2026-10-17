--[[
    Living City: rearranging a rebel camp

      Hold E (half a second) on anything the city put down in rebel territory
      (the mattresses, couches, crates, the table and chairs, the fire, the
      supply crate, the garden pots) and you pick it up: it goes where you
      look, along the floor, and you set it down by letting go of E. R turns
      it a quarter. It stays inside its own zone. Anyone but Civil Protection
      can do it.

      Where everything was set down is kept for the map
      (data/livingcity/<map>_camp.json): next time the city dresses that
      zone, it's put back just there instead of somewhere at random.
]]

if CLIENT then return end

LC = LC or {}

local HOLD = 0.5   -- seconds of E before it's picked up
local REACH = 110  -- how far in front of you it goes
LC.CampFileOf = function() return "livingcity/" .. game.GetMap() .. "_camp.json" end
LC.CampFile = "livingcity/<map>_camp.json"

local saved
local function Load()
    if saved then return saved end
    local raw = file.Read(LC.CampFileOf(), "DATA")
    local t = raw and util.JSONToTable(raw)
    saved = istable(t) and t or {}
    return saved
end
local function Save()
    file.CreateDir("livingcity")
    file.Write(LC.CampFileOf(), util.TableToJSON(saved or {}, true))
end

function LC.CampKey(z)
    return string.format("%d_%d_%d", math.floor(z.pos.x + 0.5), math.floor(z.pos.y + 0.5), math.floor(z.pos.z + 0.5))
end
-- The camp as it was last arranged (a list of { model, cls, x, y, z, yaw, prop }), or nil.
function LC.CampSaved(z) return Load()[LC.CampKey(z)] end
function LC.CampForget() saved = {} Save() end

local function ZoneOf(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if LCZ.Contains(z, pos, 0) then return z end
    end
    return nil
end

local function Movable(e)
    if not IsValid(e) then return false end
    if not (e.lcDressing or e.lcRebelProp or e:GetClass() == "lc_fire") then return false end
    return ZoneOf(e:GetPos()) ~= nil
end
LC.CampMovable = Movable

-- What's in a zone now, written down (everything the city put there, wherever it's been moved).
function LC.CampSnapshot(z)
    if not z then return end
    local list = {}
    local function Add(e, prop)
        if IsValid(e) then
            local p = e:GetPos()
            list[#list + 1] = { model = e:GetModel(), cls = e:GetClass(), x = p.x, y = p.y, z = p.z, yaw = e:GetAngles().y, prop = prop }
        end
    end
    local d = LC.Dressed and LC.Dressed[z]
    for _, e in ipairs(d and d.ents or {}) do Add(e) end
    local r = LC.RebelProps and LC.RebelProps[z]
    if r then
        Add(r.cache, "cache")
        for _, pot in ipairs(r.pots or {}) do Add(pot, "pot") end
    end
    Load()[LC.CampKey(z)] = list
    Save()
end

local function Allowed(ply)
    return IsValid(ply) and ply:Alive() and not LC.PlayerIsCP(ply) and not (LC.IsTied and LC.IsTied(ply))
end

local function Aimed(ply)
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * 120, filter = ply })
    return tr and tr.Entity
end

local function Drop(ply)
    local c = ply.lcCampCarry
    ply.lcCampCarry = nil
    if not c or not IsValid(c.e) then return end
    local e = c.e
    if e.SetCollisionGroup and c.cg then e:SetCollisionGroup(c.cg) end
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcCarriedBy = nil
    LC.CampSnapshot(c.zone)
    if ply.ChatPrint then ply:ChatPrint("[Camp] Set down. (It'll be here next time too.)") end
end
LC.CampDrop = Drop

function LC.CampPickUp(ply, e)
    if not Allowed(ply) or not Movable(e) or e.lcCarriedBy then return false end
    local z = ZoneOf(e:GetPos())
    local mn = e.OBBMins and e:OBBMins() or Vector(0, 0, 0)
    ply.lcCampCarry = { e = e, zone = z, rot = 0, cg = e.GetCollisionGroup and e:GetCollisionGroup() or nil,
        lift = e:GetClass() == "lc_fire" and 2 or math.max(0, -mn.z) + 1, pitch = e:GetAngles().p, roll = e:GetAngles().r,
        yaw0 = e:GetAngles().y - ply:EyeAngles().y }
    e.lcCarriedBy = ply
    if e.SetCollisionGroup then e:SetCollisionGroup(COLLISION_GROUP_WORLD) end -- (it doesn't push you about while you carry it)
    if LC.Notice then LC.Notice(ply, "info", "Moving it", "It goes where you look. Let go of E to set it down; R turns it.", 5) end
    return true
end

-- One step of carrying: along the floor where you look, inside its zone.
function LC.CampCarryStep(ply)
    local c = ply.lcCampCarry
    if not c then return end
    if not IsValid(c.e) or not Allowed(ply) or not ply:KeyDown(IN_USE) then return Drop(ply) end
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * REACH, filter = { ply, c.e } })
    local at = tr and tr.HitPos or (ply:EyePos() + ply:EyeAngles():Forward() * REACH)
    local floor = LC.GroundAt and LC.GroundAt(at + Vector(0, 0, 20)) or at
    if c.zone and not LCZ.Contains(c.zone, floor, 0) then return end -- (not out of its own camp)
    c.e:SetPos(floor + Vector(0, 0, c.lift))
    c.e:SetAngles(Angle(c.pitch or 0, ply:EyeAngles().y + c.yaw0 + c.rot, c.roll or 0))
end

hook.Add("KeyPress", "LivingCityCampMove", function(ply, key)
    if key == IN_RELOAD and ply.lcCampCarry then
        ply.lcCampCarry.rot = (ply.lcCampCarry.rot + 90) % 360
        return
    end
    if key ~= IN_USE or ply.lcCampCarry or not Allowed(ply) then return end
    local e = Aimed(ply)
    if Movable(e) then ply.lcCampHold = { e = e, t0 = CurTime() } end
end)

hook.Add("Think", "LivingCityCampMove", function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local h = ply.lcCampHold
        if h then
            if not ply:KeyDown(IN_USE) or not IsValid(h.e) then
                ply.lcCampHold = nil
            elseif now - h.t0 >= HOLD then
                ply.lcCampHold = nil
                if Aimed(ply) == h.e then LC.CampPickUp(ply, h.e) end
            end
        end
        if ply.lcCampCarry then LC.CampCarryStep(ply) end
    end
end)

hook.Add("PlayerDeath", "LivingCityCampMove", function(ply) if ply.lcCampCarry then Drop(ply) end end)
hook.Add("PlayerDisconnected", "LivingCityCampMove", function(ply) if ply.lcCampCarry then Drop(ply) end end)
