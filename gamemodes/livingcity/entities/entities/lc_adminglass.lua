--[[ The Administrator's glass (Living City): a Combine glass screen in front of each of her transformers
     (lc_adminpower), on the side that faced whoever placed it with the editor. Unbreakable: it stops bullets,
     so nobody can shoot her transformer from the doorway; they have to get round it, past its guards (the
     owner, 10 November). It goes where its transformer goes. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Combine glass"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local W, H, T = 180, 170, 4 -- wide, high, thick
local MINS, MAXS = Vector(-T / 2, -W / 2, 0), Vector(T / 2, W / 2, H)

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl") -- (any model: it's drawn by hand, and solid by its box)
    if self.SetRenderBounds then self:SetRenderBounds(MINS, MAXS) end
    if CLIENT then return end
    self:PhysicsInitBox(MINS, MAXS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    if self.SetCollisionBounds then self:SetCollisionBounds(MINS, MAXS) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
end

if SERVER then
    function ENT:OnTakeDamage() end -- (nothing breaks it)
    function ENT:GravGunPunt() return false end
    function ENT:GravGunPickupAllowed() return false end
end

if CLIENT then
    local PANE = Color(110, 170, 255, 45)
    local FRAME = Color(150, 200, 255, 200)
    function ENT:Draw() end
    function ENT:DrawTranslucent()
        local pos, ang = self:GetPos(), self:GetAngles()
        render.SetColorMaterial()
        render.DrawBox(pos, ang, MINS, MAXS, PANE)
        render.DrawWireframeBox(pos, ang, MINS, MAXS, FRAME, true)
        -- (a faint sheen across it, so it reads as glass)
        local t = (CurTime() * 0.25) % 1
        render.DrawBox(pos, ang, Vector(-T / 2 - 0.3, MINS.y + W * t - 6, 0), Vector(T / 2 + 0.3, MINS.y + W * t + 6, H), Color(200, 230, 255, 25))
    end
end
