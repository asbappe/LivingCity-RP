--[[ An infestation control barrel (Living City, sv_livingcity_cleanup.lua): a cleanup worker
     empties their hoover into it (E). One stands at every infestation's warning post, and you
     can place your own with the editor ("Fixture: infestation control barrel").
     The Alyx hazard props pack's barrel; a yellow oil drum where the server hasn't it, and in
     the game of anyone who hasn't it either (never an ERROR). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Infestation control barrel"
ENT.Author = "Living City"
ENT.Spawnable = false

local PACK = "models/hlvr/combine_hazardprops/combinehazardprops_barrel.mdl"
local STANDIN = "models/props_c17/oildrum001.mdl"
local function Has(m) return not util.IsValidModel or util.IsValidModel(m) end

function ENT:Initialize()
    if CLIENT then return end
    local pack = Has(PACK)
    self:SetModel(pack and PACK or STANDIN)
    if not pack and self.SetColor then self:SetColor(Color(220, 190, 40)) end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseHazardBarrel then LC.UseHazardBarrel(activator, self) end
    end
end

if CLIENT then
    function ENT:Draw()
        if Has(self:GetModel()) then self:DrawModel() return end
        -- (the server has the pack and this game hasn't: the stand-in, not an ERROR)
        if not IsValid(self.lcStandin) and ClientsideModel then
            self.lcStandin = ClientsideModel(STANDIN, RENDERGROUP_OPAQUE)
            if IsValid(self.lcStandin) then self.lcStandin:SetNoDraw(true) self.lcStandin:SetColor(Color(220, 190, 40)) end
        end
        if IsValid(self.lcStandin) then
            self.lcStandin:SetPos(self:GetPos()) self.lcStandin:SetAngles(self:GetAngles())
            self.lcStandin:DrawModel()
        end
    end
    function ENT:OnRemove() if IsValid(self.lcStandin) then self.lcStandin:Remove() end end
end
