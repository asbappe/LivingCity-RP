--[[ Union supply crate (Living City): left on the street by a supply convoy
     (the "supply" city event) and guarded by units. Anyone who isn't a unit can
     press E to take a load out of it, if they dare. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Union supply crate"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/items/item_item_crate.mdl")
    self:SetModelScale(1.6, 0)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.LootSupply then return end
        if (self.lcNext or 0) > CurTime() then return end
        self.lcNext = CurTime() + 0.8
        local ok, why = LC.LootSupply(activator, self)
        if not ok and why then activator:ChatPrint(why) end
    end
end

if CLIENT then
    ENT.RenderGroup = RENDERGROUP_BOTH -- (the label is drawn in the translucent pass, after the props stacked round it)

    function ENT:Draw()
        self:DrawModel()
    end

    -- The label hangs above the crate and is drawn over everything near it, so a pile of props or the
    -- container beside it can't hide it.
    -- (made once here, not every frame)
    local C_150_210_240 = Color(150, 210, 240)
    local C_220_220_220 = Color(220, 220, 220)
    local V_0_0_75 = Vector(0, 0, 75)
    function ENT:DrawTranslucent()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 600 * 600 then return end
        local pos = self:GetPos() + V_0_0_75
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        cam.IgnoreZ(true)
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleTextOutlined("UNION SUPPLIES", "DermaLarge", 0, 0, C_150_210_240, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
            draw.SimpleTextOutlined(self:GetNW2Int("lc_loads", 0) .. " loads", "DermaDefaultBold", 0, 30, C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        cam.End3D2D()
        cam.IgnoreZ(false)
    end
end
