--[[
    A shield scanner bringing a unit's resupply (Living City; sv_livingcity_radiohq.lua).
    It comes straight down the open shaft of sky above where the unit called from, hovers, lets one small
    crate go, then climbs back up and flies off toward the nearest Combine-only zone, fading as it goes.
    Flown by the game, not the engine's AI: nothing can lead it astray, and it never fights.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resupply scanner"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local MODEL = "models/shield_scanner.mdl"
local FALLBACK = "models/combine_scanner.mdl"
local DOWN, UP, AWAY = 380, 360, 520 -- (units a second)
local HOVER = 1.4

function ENT:Initialize()
    local m = MODEL
    if util.IsValidModel and not util.IsValidModel(m) then m = FALLBACK end
    self:SetModel(m)
    if CLIENT then return end
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    local seq = self:LookupSequence("idle")
    if not seq or seq < 0 then seq = self:LookupSequence("hover") end
    if seq and seq >= 0 then self:ResetSequence(seq) self:SetPlaybackRate(1) end
    self.lcPhase = "down"
    self.lcBorn = CurTime()
    self.lcLast = CurTime()
    self.lcHum = CreateSound and CreateSound(self, "npc/scanner/cbot_fly_loop.wav")
    if self.lcHum then self.lcHum:PlayEx(0.7, 100) end
    self:EmitSound("npc/scanner/scanner_siren1.wav", 85)
    self:NextThink(CurTime())
end

if SERVER then
    local function Toward(cur, goal, step)
        local d = goal - cur
        local len = d:Length()
        if len <= step then return goal, true end
        return cur + d / len * step, false
    end

    function ENT:Face(dir)
        dir = Vector(dir.x, dir.y, 0)
        if dir:LengthSqr() > 0.01 then self:SetAngles(Angle(0, dir:Angle().y, 0)) end
    end

    function ENT:Think()
        local now = CurTime()
        local dt = math.Clamp(now - (self.lcLast or now), 0, 0.2)
        self.lcLast = now
        -- (never hangs about: whatever happens, gone in 45 seconds)
        if now - (self.lcBorn or now) > 45 then self:Remove() return end
        local pos = self:GetPos()
        local ply = self.lcFor
        if self.lcPhase == "down" then
            if IsValid(ply) then self:Face(ply:GetPos() - pos) end
            -- seen coming: from the top of the sky in about three seconds or more, never a drop in
            -- an eye-blink (the owner, 13 November: it "spawned about 3 feet above me")
            if not self.lcDownSpeed then
                local fall = self.lcDrop and (pos.z - self.lcDrop.z) or 0
                self.lcDownSpeed = math.Clamp(fall / 3, 60, DOWN)
            end
            local p, there = Toward(pos, self.lcDrop or pos, self.lcDownSpeed * dt)
            self:SetPos(p)
            if there then
                self.lcPhase = "hover"
                self.lcUntil = now + HOVER
                self:EmitSound("npc/scanner/scanner_blip1.wav", 75)
            end
        elseif self.lcPhase == "hover" then
            self:SetPos(pos + Vector(0, 0, math.sin(now * 4) * 0.6))
            if now >= self.lcUntil then
                self:Drop()
                self.lcPhase = "up"
                self:EmitSound("npc/scanner/combat_scan1.wav", 75)
            end
        elseif self.lcPhase == "up" then
            local p, there = Toward(pos, self.lcTop or (pos + Vector(0, 0, 600)), UP * dt)
            self:SetPos(p)
            if there then
                self.lcPhase = "away"
                self.lcUntil = now + 3
                self:Face(self.lcHeading or Vector(0, 1, 0))
            end
        elseif self.lcPhase == "away" then
            self:SetPos(pos + (self.lcHeading or Vector(0, 1, 0)) * AWAY * dt + Vector(0, 0, 40 * dt))
            local left = math.Clamp((self.lcUntil - now) / 3, 0, 1)
            self:SetColor(Color(255, 255, 255, math.floor(255 * left)))
            if now >= self.lcUntil then self:Remove() return end
        end
        self:NextThink(now)
        return true
    end

    function ENT:Drop()
        local c = ents.Create("lc_resupplycrate")
        if not IsValid(c) then
            if LC and LC.ResupplySpill then LC.ResupplySpill(self, self:GetPos() - Vector(0, 0, 150)) end
            return
        end
        c.lcFor, c.lcGive, c.lcWords = self.lcFor, self.lcGive, self.lcWords
        c:SetPos(self:GetPos() - Vector(0, 0, 22))
        c:SetAngles(Angle(0, self:GetAngles().y, 0))
        c:Spawn()
    end

    function ENT:OnRemove()
        if self.lcHum then self.lcHum:Stop() end
        if LC and LC.ResupplyOut and IsValid(self.lcFor) and LC.ResupplyOut[self.lcFor] == self then LC.ResupplyOut[self.lcFor] = nil end
    end
end

if CLIENT then
    function ENT:Draw() self:DrawModel() end
end
