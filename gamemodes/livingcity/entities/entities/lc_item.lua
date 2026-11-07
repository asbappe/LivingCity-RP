--[[
    A carryable item lying in the world: food, water, a carcass, a bottle.
    Press E to put it in your pockets (F3 to see what you're carrying).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Item"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = false
ENT.ItemId = nil -- subclasses set this

function ENT:Initialize()
    if CLIENT then return end
    local id = self:GetNW2String("lc_item", "")
    if id == "" and self.ItemId then
        id = self.ItemId
        self:SetNW2String("lc_item", id)
    end
    local it = LCS and LCS.Items[id]
    self:SetModel(it and it.model or "models/weapons/w_package.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    if id == "raw_bird" or id == "raw_crow" or id == "raw_gull" or id == "raw_headcrab" then self:SetColor(Color(150, 115, 105)) end
    if id == "raw_fish" then self:SetColor(Color(135, 160, 170)) end -- (the bugbait pod, made fish-grey)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.GiveItem then return end
        if self.lcTaken then return end -- (two people pressing E at the same moment: only one gets it)
        local id = self:GetNW2String("lc_item", "")
        self.lcTaken = true
        if LC.GiveItem(activator, id, 1, self.lcBornAt) then -- (meat keeps its age: sv_livingcity_survival.lua)
            activator:ChatPrint("Picked up: " .. (LCS.Items[id] and LCS.Items[id].name or id))
            self:EmitSound("items/ammo_pickup.wav", 60)
            self:Remove()
        else
            self.lcTaken = nil
            activator:ChatPrint(LC.CarryWhy and LC.CarryWhy(activator, id, 1) or "Your pockets are full.")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 160 * 160 then return end
        local it = LCS and LCS.Items[self:GetNW2String("lc_item", "")]
        if not it then return end
        local pos = self:GetPos() + Vector(0, 0, 18)
        local ang = Angle(0, ply:EyeAngles().y - 90, 90)
        cam.Start3D2D(pos, ang, 0.08)
            draw.SimpleTextOutlined(it.name, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        cam.End3D2D()
    end
end
