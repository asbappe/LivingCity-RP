--[[ A weed (Living City): something growing out of the cracks on open ground
     (sv_livingcity_weeds.lua). Three sizes, lc_stage 1 to 3: a tuft, weeds, a
     bush. People walk through it; E with weedkiller sprays it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weed"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(LC and LC.WeedModel and LC.WeedModel() or "models/props_lab/cactus.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- (walked through, but E and a spray still find it)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.SprayWeed then
            local ok, why = LC.SprayWeed(activator, self)
            if not ok and why then activator:ChatPrint(why) end
        end
    end
end
