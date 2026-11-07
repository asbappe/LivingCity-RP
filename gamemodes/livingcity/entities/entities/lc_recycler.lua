--[[ Reclamation point (Living City): press E to hand in scrap metal, empty cans
     and bottles to the Union for a few credits and a little Civil Standing.
     Place it with the editor. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Reclamation point"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true

local MODELS = { "models/props_wasteland/laundry_washer001a.mdl", "models/props_junk/TrashDumpster01a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[1]
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.Reclaim then return end
        if (self.lcNext or 0) > CurTime() then return end
        self.lcNext = CurTime() + 1
        local ok, why = LC.Reclaim(activator, self)
        if not ok and why then activator:ChatPrint(why) end
    end
end

if CLIENT then
    -- (made once here, not every frame)
    local C_150_210_240 = Color(150, 210, 240)
    local C_220_220_220 = Color(220, 220, 220)
    function ENT:Draw()
        self:DrawModel()
        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 10)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 400 * 400 then return end
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleTextOutlined("UNION RECLAMATION", "DermaLarge", 0, 0, C_150_210_240, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
            draw.SimpleTextOutlined("Scrap  Cans  Bottles", "DermaDefaultBold", 0, 30, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        cam.End3D2D()
    end
end
