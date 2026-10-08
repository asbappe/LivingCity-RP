--[[
    Ration dispenser (Living City). Place it with the Living City Editor so it
    saves with the map layout. Put one at the front of a ration line and the
    NPCs in the line are served from it; players press E (or wait at the
    front of the line) to get theirs.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ration dispenser"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true -- so the dispensing animation plays

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_combine/combine_dispenser.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    local idle = self:LookupSequence("idle")
    if idle and idle >= 0 then self:ResetSequence(idle) end
end

if SERVER then
    function ENT:Think()
        self:NextThink(CurTime())
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if self:GetNW2Bool("lc_nopower", false) then
            self:EmitSound("buttons/button8.wav", 60)
            activator:ChatPrint("Dead. No power: no rations until it's back.")
            return
        end
        if LC.UseDispenser then LC.UseDispenser(activator, self) end
    end
end
