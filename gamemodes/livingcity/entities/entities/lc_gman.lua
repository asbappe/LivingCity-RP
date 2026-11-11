--[[ The G-Man (Living City): the man in the blue suit, standing in front of the City Administrator when the
     city collapses to BLACK (sv_livingcity_collapse.lua). Only she sees him (nobody else's game is sent him),
     and nothing touches him: no collisions, no bullets, no harm (the owner, 10 November: "he needs to be
     invincible and non killable"). He turns to face her; E on him (looking at him, close) brings back his
     offer. When he's done he turns and walks off, and is gone. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "The G-Man"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

local function Seq(self, names)
    if not self.LookupSequence then return nil end
    for _, n in ipairs(names) do local q = self:LookupSequence(n) if q and q >= 0 then return q end end
end

function ENT:Initialize()
    self:SetModel("models/gman_high.mdl")
    if CLIENT then return end
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    if self.SetNotSolid then self:SetNotSolid(true) end
    if self.SetCollisionGroup then self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE or 10) end
    local idle = Seq(self, { "idle_subtle", "idle", "Idle01" })
    if idle and self.ResetSequence then self:ResetSequence(idle) end
end

if SERVER then
    function ENT:OnTakeDamage() end -- (nothing hurts him)
    function ENT:GravGunPunt() return false end
    function ENT:GravGunPickupAllowed() return false end
    function ENT:PhysgunPickup() return false end

    -- facing her, or walking off
    function ENT:Think()
        local now = CurTime()
        local who = self.lcFor
        if self.lcLeaveAt then
            if not self.lcWalking then
                self.lcWalking = true
                self:SetAngles(Angle(0, self:GetAngles().y + 150, 0))
                local walk = Seq(self, { "walk_all", "Walk", "walk" })
                if walk and self.ResetSequence then self:ResetSequence(walk) end
            end
            self:SetPos(self:GetPos() + self:GetForward() * 45 * 0.1)
            if now >= self.lcLeaveAt then self:Remove() return end
        elseif IsValid(who) then
            local d = who:GetPos() - self:GetPos()
            d.z = 0
            if d:LengthSqr() > 1 then self:SetAngles(Angle(0, d:Angle().y, 0)) end
        end
        self:NextThink(now + 0.1)
        return true
    end

    -- walk off and go
    function ENT:Leave(secs)
        if self.lcLeaveAt then return end
        self.lcLeaveAt = CurTime() + (secs or 3)
        self:SetNW2Bool("lc_leaving", true)
    end
end

if CLIENT then
    -- (only for her, even if he were ever sent to someone else)
    function ENT:Draw()
        if self:GetNW2Entity("lc_for") ~= LocalPlayer() then return end
        self:DrawModel()
    end
end
