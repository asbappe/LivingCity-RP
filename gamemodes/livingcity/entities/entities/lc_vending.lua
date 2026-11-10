--[[ Water vending machine (Living City). Place it with the Living City Editor so it saves with the map layout. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Water vending machine"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_interiors/vendingmachinesoda01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if self:GetNW2Bool("lc_nopower", false) then
            self:EmitSound("buttons/button8.wav", 60)
            if not (LC.MachineSpeak and LC.MachineSpeak(self, activator, "Vending machines can't process credits or dispense during a blackout.")) then activator:ChatPrint("Vending machines can't process credits or dispense during a blackout.") end
            return
        end
        if LC.UseVending then LC.UseVending(activator, self) end
    end
end
