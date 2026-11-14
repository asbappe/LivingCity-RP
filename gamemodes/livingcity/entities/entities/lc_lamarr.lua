--[[
    Lamarr (Living City; the owner, 14 November: "add a secret Lamar pet that is non-aggressive and is
    friendly to the gamemode ... it should sit idle on top of the lab equipment prop if Dr Kleiner is the
    resistance scientist"). Dr. Kleiner's debeaked headcrab, sitting on his bench: never an NPC, so
    nobody fights her and she fights nobody. She idles, turns now and then, makes a small noise. E on
    her: she lets you pet her (or doesn't). Put there by sv_livingcity_lab.lua, never placed by hand.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lamarr"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

local MODEL = "models/lamarr.mdl"
local IDLES = { "idle01", "Idle01", "idle", "ACT_IDLE" }
local NOISES = { "npc/headcrab/idle1.wav", "npc/headcrab/idle2.wav", "npc/headcrab/idle3.wav" }
local PETS = {
    "Lamarr lets you scratch her back, then tries to climb your arm.",
    "Lamarr ignores you completely. Then she sneezes.",
    "Lamarr nuzzles your hand where her beak used to be.",
    "Lamarr hops a little closer to the warm screen and settles down again.",
}

function ENT:Initialize()
    if CLIENT then return end
    if util.IsValidModel and not util.IsValidModel(MODEL) then self:SetModel("models/headcrabclassic.mdl") else self:SetModel(MODEL) end
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-8, -8, 0), Vector(8, 8, 10))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    self:Idle()
end

if SERVER then
    function ENT:Idle()
        for _, n in ipairs(IDLES) do
            local id
            if string.sub(n, 1, 4) == "ACT_" then id = _G[n] and self.SelectWeightedSequence and self:SelectWeightedSequence(_G[n]) or nil
            else id = self:LookupSequence(n) end
            if id and id >= 0 then self:ResetSequence(id) break end
        end
        self.lcNext = CurTime() + math.Rand(6, 14)
    end
    function ENT:Think()
        local now = CurTime()
        if now >= (self.lcNext or 0) then
            self:Idle()
            -- a turn on the spot, now and then, and a small noise
            if math.random() < 0.5 then self:SetAngles(self:GetAngles() + Angle(0, math.random(-50, 50), 0)) end
            if math.random() < 0.3 then self:EmitSound(NOISES[math.random(#NOISES)], 50, 120, 0.5) end
        end
        self:NextThink(now + 0.5)
        return true
    end
    function ENT:Use(activator)
        if not (IsValid(activator) and activator:IsPlayer()) then return end
        if (activator.lcLamarrNext or 0) > CurTime() then return end
        activator.lcLamarrNext = CurTime() + 3
        activator:ChatPrint(PETS[math.random(#PETS)])
        self:EmitSound(NOISES[math.random(#NOISES)], 55, 130, 0.6)
        if hook then hook.Run("LivingCityLamarrPetted", activator, self) end
    end
    function ENT:OnTakeDamage() end -- (nobody hurts Lamarr)
end
