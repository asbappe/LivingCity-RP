--[[
    Civil notice poster (Living City). Place it with the Living City Editor
    ("Fixture: Civil notice poster") on a wall: it faces you.

    Its words fit whatever official thing is nearest, so a poster teaches
    the rule right where it applies, on any map (the owner, 10 November:
    "signs and posters that teach"): beside the ration dispenser, that labor
    earns rations; at the Commissary, that credits come from work; at Civil
    Intake and the desks, that arrivals must register; by a sink or a water
    machine, that untreated water carries parasites; by the law board, to
    know the law; anywhere else, curfew.

    Press E to read it closely: that's learning it, and its tip cards don't
    come (LC.Learn, sv_livingcity_learning.lua).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Civil notice poster"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- kind = { heading, body } (what reading each teaches: LC.CivPosterTips, sv_livingcity_learning.lua)
local NOTICES = {
    dispenser = { "LABOR EARNS RATIONS", "One ration card for each ration. One card for each completed Union shift. No card, no ration." },
    commissary = { "THE COMMISSARY SERVES THE COMPLIANT", "Food, water, medicine and tablets, for credits. Credits are earned by work." },
    intake = { "ALL ARRIVALS MUST REGISTER", "Unregistered persons receive no rations, no work and no housing. Carry your papers at all times." },
    water = { "UNTREATED WATER CARRIES PARASITES", "Drink only from approved taps and machines. Antiparasitic tablets are available at the Commissary." },
    law = { "KNOW THE LAW", "Ignorance of the law is no defence. The city's laws are posted here. Comply." },
    curfew = { "CURFEW IS ABSOLUTE", "At the two-minute warning, return to your housing block. Do not run in the presence of Civil Protection." },
}
ENT.Notices = NOTICES

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/paper01.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-2, -24, -32), Vector(2, 24, 32))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self:SetNW2String("lc_notice", "curfew")
    -- the other fixtures may not be out yet: look a moment later, and again now and then
    timer.Simple(2, function() if IsValid(self) then self:PickNotice() end end)
end

if SERVER then
    -- (what's nearest, and what reading it teaches: sv_livingcity_learning.lua)
    function ENT:PickNotice()
        local best = LC and LC.CivPosterNotice and LC.CivPosterNotice(self:GetPos()) or "curfew"
        self:SetNW2String("lc_notice", best)
        self.lcPickedAt = CurTime()
        return best
    end

    function ENT:Think()
        if CurTime() - (self.lcPickedAt or 0) > 120 then self:PickNotice() end
        self:NextThink(CurTime() + 30)
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local kind = self:GetNW2String("lc_notice", "curfew")
        local n = NOTICES[kind] or NOTICES.curfew
        activator:ChatPrint("[City] " .. n[1] .. ". " .. n[2])
        if LC and LC.CivPosterRead then LC.CivPosterRead(activator, kind) end
    end
end

if CLIENT then
    local PAPER, INK, RED = Color(205, 200, 185, 245), Color(25, 25, 28), Color(150, 20, 20)
    function ENT:Draw()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 900 * 900 then return end
        local n = NOTICES[self:GetNW2String("lc_notice", "curfew")] or NOTICES.curfew
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(self:GetPos() + self:GetForward() * 0.6, ang, 0.1)
            draw.RoundedBox(0, -230, -310, 460, 620, PAPER)
            draw.RoundedBox(0, -230, -310, 460, 70, RED)
            draw.SimpleText("CITY ADMINISTRATION", "DermaLarge", 0, -275, PAPER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if self.lcWrappedH ~= n[1] and LC_CL and LC_CL.WrapText then
                self.lcHead, self.lcBody = LC_CL.WrapText(n[1], "DermaLarge", 420), LC_CL.WrapText(n[2], "DermaDefaultBold", 400)
                self.lcWrappedH = n[1]
            end
            local y = -200
            for _, l in ipairs(self.lcHead or { n[1] }) do
                draw.SimpleText(l, "DermaLarge", 0, y, INK, TEXT_ALIGN_CENTER)
                y = y + 40
            end
            y = y + 30
            for _, l in ipairs(self.lcBody or { n[2] }) do
                draw.SimpleText(l, "DermaDefaultBold", 0, y, INK, TEXT_ALIGN_CENTER)
                y = y + 26
            end
            draw.SimpleText("Your cooperation is noted.", "DermaDefault", 0, 280, INK, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
