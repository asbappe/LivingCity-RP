--[[ Union Commissary terminal (Living City). Place it with the Living City Editor so it saves with the map layout. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Union Commissary terminal"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_combine/combine_interface001.mdl")
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
            activator:ChatPrint("The screen's dark due to the blackout.")
            return
        end
        -- a unit, in a city with no Civil Protection Commissary: issued their supplies here (sv_livingcity_cpsupply.lua)
        if LC.UseCPSupply and LC.HasCPSupply and not LC.HasCPSupply() and LC.PlayerIsCP and LC.PlayerIsCP(activator) then
            return LC.UseCPSupply(activator, self)
        end
        if LC.OpenShop then LC.OpenShop(activator, true) end
    end
end

if CLIENT then
    -- its sign, the Civil Intake terminals' style (cl_livingcity_intake.lua; the owner, 7 November: the
    -- Commissaries "just look like static map props")
    function ENT:Draw()
        self:DrawModel()
        if LC_CL and LC_CL.TerminalSign then LC_CL.TerminalSign(self, "UNION COMMISSARY", "Goods for citizens, by Civil Standing. Press E") end
    end
end
