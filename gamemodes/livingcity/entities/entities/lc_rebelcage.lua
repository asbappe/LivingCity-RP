--[[
    Holding cage (Living City). Place it with the Living City Editor
    ("Fixture: Resistance holding cage"). A tight square of chain link fence,
    one panel a side; the side facing whoever placed it is the gate. The
    Resistance open and close the gate (E on any side); it stays locked to
    whoever is held inside. Who is held, and what becomes of them:
    sv_livingcity_rebelhold.lua.

    The entity itself is an unseen anchor on the floor at the middle; the
    four panels are props it makes and takes away with it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Holding cage"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = false

-- The first chain link panel this install has is used for all four sides.
local PANELS = { "models/props_c17/fence01a.mdl", "models/props_wasteland/interior_fence002d.mdl", "models/props_c17/fence03a.mdl" }

if CLIENT then
    function ENT:Draw() end
    return
end

local function Panel(self, model)
    local p = ents.Create("prop_physics")
    if not IsValid(p) then return nil end
    p:SetModel(model)
    p:Spawn()
    p:Activate()
    local phys = p.GetPhysicsObject and p:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    p.lcCage = self
    return p
end

-- Put a panel so that the middle of its bottom edge is at `at`, turned to `yaw`.
local function Stand(p, at, yaw, mins, maxs)
    p:SetAngles(Angle(0, yaw, 0))
    local c = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
    c:Rotate(Angle(0, yaw, 0))
    p:SetPos(at - c)
end

function ENT:Build()
    local model
    for _, c in ipairs(PANELS) do
        if not util.IsValidModel or util.IsValidModel(c) then model = c break end
    end
    model = model or PANELS[1]
    self.lcParts = {}
    local base, yaw0 = self:GetPos(), self:GetAngles().y
    local half, turn, mins, maxs
    for i, off in ipairs({ 0, 90, 180, 270 }) do -- (0: the front, where the gate is)
        local p = Panel(self, model)
        if not p then return end
        if not half then
            mins, maxs = p:OBBMins(), p:OBBMaxs()
            local sx, sy = maxs.x - mins.x, maxs.y - mins.y
            half = math.max(sx, sy) / 2
            turn = sy >= sx and 0 or 90 -- (the panel's long side goes across the wall's facing)
            self.lcHalf = half
        end
        local n = Angle(0, yaw0 + off, 0):Forward()
        Stand(p, base + n * half, yaw0 + off + turn, mins, maxs)
        self.lcParts[i] = p
        if off == 0 then
            p.lcCageGate = true
            self.lcGate = p
            -- shut: across the front. open: swung out on its left-hand corner
            local side = Angle(0, yaw0 + 90, 0):Forward()
            self.lcShut = { at = base + n * half, yaw = yaw0 + turn }
            self.lcOpen = { at = base + n * half + side * half + n * half, yaw = yaw0 + 90 + turn }
            self.lcBounds = { mins, maxs }
        end
    end
    self:SetOpen(false, true)
end

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    -- (a moment later: the editor seats a fixture on the floor after it spawns)
    timer.Simple(0.5, function() if IsValid(self) then LC.Try(self.Build, self) end end)
end

function ENT:IsOpen() return self:GetNW2Bool("lc_cage_open", false) end

function ENT:SetOpen(open, quiet)
    local g = self.lcGate
    if IsValid(g) and self.lcShut then
        local to = open and self.lcOpen or self.lcShut
        Stand(g, to.at, to.yaw, self.lcBounds[1], self.lcBounds[2])
        if not quiet then g:EmitSound("physics/metal/metal_chainlink_impact_hard" .. math.random(1, 3) .. ".wav", 70) end
    end
    self:SetNW2Bool("lc_cage_open", open and true or false)
end

-- Nobody is stood in the map's wall or behind it (the owner, 14 November: "make sure that prisoners don't spawn
-- outside the map brushes/walls because the way I have to place it, the cage walls are clipping through the
-- brushes of the wall"). A spot is kept only as far out from the middle of the cage as a standing body gets
-- before it meets the map itself: the fence panels and the others held don't count.
local BODY_MIN, BODY_MAX = Vector(-13, -13, 0), Vector(13, 13, 70)
local function MapOnly(e)
    if not IsValid(e) then return true end -- (the world)
    if e.IsWorld and e:IsWorld() then return true end
    return string.sub(e.GetClass and e:GetClass() or "", 1, 5) == "func_"
end
function ENT:Inside(want)
    local mid = self:GetPos() + Vector(0, 0, 6)
    local to = Vector(want.x, want.y, mid.z)
    local tr = util.TraceHull({ start = mid, endpos = to, mins = BODY_MIN, maxs = BODY_MAX, mask = MASK_SOLID_BRUSHONLY, filter = MapOnly })
    if tr and (tr.Hit or tr.StartSolid) then
        local f = tr.StartSolid and 0 or math.max(0, (tr.Fraction or 0) - 0.1)
        to = mid + (to - mid) * f
    end
    if util.IsInWorld and not util.IsInWorld(to) then to = mid end
    return Vector(to.x, to.y, want.z)
end

-- Is this spot within the four panels? (pad: that much further out counts too)
function ENT:Holds(pos, pad)
    local d = pos - self:GetPos()
    if d.z < -40 or d.z > 110 then return false end
    d = Vector(d.x, d.y, 0)
    d:Rotate(Angle(0, -self:GetAngles().y, 0))
    local h = (self.lcHalf or 60) + (pad or 0)
    return math.abs(d.x) <= h and math.abs(d.y) <= h
end

-- Where the nth of those held stands, and a spot just outside the gate.
function ENT:Slot(n)
    local q = (self.lcHalf or 60) * 0.5
    local offs = { Vector(-q, -q, 0), Vector(-q, q, 0), Vector(q * 0.4, -q, 0), Vector(q * 0.4, q, 0), Vector(-q, 0, 0), Vector(q * 0.4, 0, 0),
        Vector(-q * 0.3, -q * 0.5, 0), Vector(-q * 0.3, q * 0.5, 0) } -- (the last two stand between the others)
    local o = offs[(n - 1) % 8 + 1]
    o:Rotate(Angle(0, self:GetAngles().y, 0))
    return self:Inside(self:GetPos() + o + Vector(0, 0, 2))
end
function ENT:Outside() return self:Inside(self:GetPos() + self:GetAngles():Forward() * ((self.lcHalf or 60) + 50) + Vector(0, 0, 2)) end

function ENT:OnRemove()
    for _, p in ipairs(self.lcParts or {}) do if IsValid(p) then p:Remove() end end
    if LC and LC.CageGone then LC.CageGone(self) end
end
