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
    timer.Simple(0.5, function() if IsValid(self) then pcall(self.Build, self) end end)
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

-- Where the nth of those held stands, and a spot just outside the gate.
function ENT:Slot(n)
    local q = (self.lcHalf or 60) * 0.42
    local offs = { Vector(-q, -q, 0), Vector(-q, q, 0), Vector(q, -q, 0), Vector(q, q, 0) }
    local o = offs[(n - 1) % 4 + 1]
    o:Rotate(Angle(0, self:GetAngles().y, 0))
    return self:GetPos() + o + Vector(0, 0, 2)
end
function ENT:Outside() return self:GetPos() + self:GetAngles():Forward() * ((self.lcHalf or 60) + 50) + Vector(0, 0, 2) end

function ENT:OnRemove()
    for _, p in ipairs(self.lcParts or {}) do if IsValid(p) then p:Remove() end end
    if LC and LC.CageGone then LC.CageGone(self) end
end
