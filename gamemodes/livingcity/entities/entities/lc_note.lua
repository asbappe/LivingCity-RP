--[[ A note left on the ground, or a poster on a wall (Living City). Press E to read it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Note"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/paper01.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-6, -8, -1), Vector(6, 8, 2))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.ReadNoteEntity then LC.ReadNoteEntity(activator, self) end
    end
end

if CLIENT then
    -- a poster: the first lines, big enough to read from across the street
    function ENT:Draw()
        if not self:GetNW2Bool("lc_poster", false) then self:DrawModel() return end
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 700 * 700 then return end
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(self:GetPos() + self:GetForward() * 0.6, ang, 0.08)
            draw.RoundedBox(2, -150, -190, 300, 380, Color(222, 214, 190, 250))
            local text = self:GetNW2String("lc_note_text", "")
            if self.lcWrapped ~= text and LC_CL and LC_CL.WrapText then
                self.lcLines, self.lcWrapped = LC_CL.WrapText(text, "DermaDefaultBold", 270), text
            end
            local y = -170
            for i = 1, math.min(#(self.lcLines or {}), 14) do
                draw.SimpleText(self.lcLines[i], "DermaDefaultBold", -135, y, Color(30, 28, 24), TEXT_ALIGN_LEFT)
                y = y + 24
            end
        cam.End3D2D()
    end
end
