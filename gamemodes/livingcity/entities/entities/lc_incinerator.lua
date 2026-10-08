--[[ Incinerator (Living City): placed with the editor ("Fixture: incinerator").
     The city's dead end up here. Haul a body to it (press E on a body, or
     the actions menu, F1) and press E on the incinerator, or just let go of
     the body next to it. Mortuary Attendants are paid for every one
     (sv_livingcity_mortuary.lua). Nothing else ever spawns one: no
     incinerator on the map, no cremations.
     It's a spent headcrab canister, with a burner roaring out of its back end. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Incinerator"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

-- A spent headcrab canister, turned furnace: a burner roaring out of its back end.
local MODELS = { "models/props_combine/headcrabcannister01a.mdl", "models/props_c17/furnitureboiler001a.mdl", "models/props_wasteland/kitchen_stove002a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or MODELS[#MODELS])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if LC and LC.FeedIncinerator then
            local ok, why = LC.FeedIncinerator(ply, self)
            if not ok and why then ply:ChatPrint(why) end
        end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local FLAMES = { "particles/flamelet1", "particles/flamelet2", "particles/flamelet3", "particles/flamelet4", "particles/flamelet5" }

    -- Its two ends, along its length: the back end (the burner) and the front
    -- (where the bodies go in). The canister's back is the end nearer its
    -- origin, along its longest side.
    local function Ends(self)
        if not self.lcBackLocal then
            local mins, maxs = self:OBBMins(), self:OBBMaxs()
            local size = maxs - mins
            local axis = (size.x >= size.y and size.x >= size.z) and "x" or ((size.y >= size.z) and "y" or "z")
            local c = (mins + maxs) * 0.5
            local back, front, dir = Vector(c.x, c.y, c.z), Vector(c.x, c.y, c.z), Vector(0, 0, 0)
            local far, near = maxs[axis], mins[axis]
            if math.abs(mins[axis]) > math.abs(maxs[axis]) then far, near = mins[axis], maxs[axis] end
            back[axis], front[axis] = near, far
            dir[axis] = near > far and 1 or -1
            self.lcBackLocal, self.lcFrontLocal, self.lcBackDir = back, front, dir
        end
        local back = self:LocalToWorld(self.lcBackLocal)
        local out = self:LocalToWorld(self.lcBackLocal + self.lcBackDir) - back
        return back, self:LocalToWorld(self.lcFrontLocal), out
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 2000 * 2000 then return end
        local burning = self:GetNW2Float("lc_burn_until", 0) > CurTime()
        local back, front, out = Ends(self)
        render.SetMaterial(GLOW)
        -- the burner, roaring out of the back
        local s = (burning and 110 or 70) + math.sin(CurTime() * 9) * 8
        render.DrawSprite(back + out * 6, s, s, burning and Color(255, 160, 70) or Color(255, 120, 45, 210))
        -- and the glow of the furnace at the hatch
        local m = (burning and 44 or 22) + math.sin(CurTime() * 7) * 3
        render.DrawSprite(front, m, m, Color(255, 110, 40, burning and 200 or 110))
    end

    local emitter
    function ENT:Think()
        local me = LocalPlayer()
        if not IsValid(me) or me:GetPos():DistToSqr(self:GetPos()) > 1500 * 1500 then
            if self.lcRoar then self.lcRoar:Stop() self.lcRoar = nil end
            return
        end
        local now = CurTime()
        local burning = self:GetNW2Float("lc_burn_until", 0) > now
        local back, _, out = Ends(self)
        -- flames licking out of the back end
        if ParticleEmitter and now > (self.lcNextFlame or 0) then
            self.lcNextFlame = now + (burning and 0.04 or 0.08)
            emitter = emitter or ParticleEmitter(back)
            if emitter then
                for _ = 1, burning and 3 or 2 do
                    local p = emitter:Add(FLAMES[math.random(#FLAMES)], back + VectorRand() * 5)
                    if p then
                        p:SetVelocity(out * math.Rand(burning and 90 or 50, burning and 160 or 100) + VectorRand() * 12 + Vector(0, 0, math.Rand(15, 40)))
                        p:SetDieTime(math.Rand(0.35, burning and 0.8 or 0.55))
                        p:SetStartAlpha(230)
                        p:SetEndAlpha(0)
                        p:SetStartSize(math.Rand(burning and 14 or 9, burning and 22 or 14))
                        p:SetEndSize(math.Rand(2, 6))
                        p:SetRoll(math.Rand(0, 360))
                        p:SetRollDelta(math.Rand(-2, 2))
                        p:SetColor(255, 255, 255)
                    end
                end
            end
        end
        local d = DynamicLight(self:EntIndex())
        if d then
            d.pos = back + out * 20
            d.r, d.g, d.b = 255, 120, 40
            d.brightness = burning and 3 or 1.5
            d.size = burning and 300 or 180
            d.decay = 600
            d.dietime = now + 0.2
        end
        -- the burner's roar
        if not self.lcRoar and CreateSound then
            self.lcRoar = CreateSound(self, "ambient/fire/fire_med_loop1.wav")
            if self.lcRoar then self.lcRoar:PlayEx(0.5, 100) end
        end
        if self.lcRoar then self.lcRoar:ChangeVolume(burning and 0.9 or 0.5, 0.5) end
        self:SetNextClientThink(now + 0.03)
        return true
    end

    function ENT:OnRemove()
        if self.lcRoar then self.lcRoar:Stop() self.lcRoar = nil end
    end
end
