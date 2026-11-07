--[[
    Black market dealer (Living City). Place it with the Living City Editor
    ("Fixture: black market dealer") so it saves with the map layout.

    Citizens and the Resistance press E to buy contraband and sell what
    they've picked up. Civil Protection units who press E bust the dealer,
    which disappears for a while.

    He isn't a statue (the owner, 7 November): he shifts between a few idles
    (picked again every so often, so no sequence can run out and freeze him),
    turns his head to whoever is nearest, and reaches to his rack when someone
    deals with him.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Black market dealer"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

local MODELS = {
    "models/humans/group03/male_06.mdl", "models/humans/group03/male_08.mdl",
    "models/humans/group03/female_02.mdl", "models/humans/group03/male_03.mdl",
}
-- idles: any the model has; the dealer wanders between them
local IDLES = { "LineIdle01", "LineIdle02", "LineIdle03", "idle_subtle", "Idle_Unarmed", "ACT_IDLE" }
-- a deal: reaching to the rack behind him (else a wave, else bending to the ground)
local SERVE = { "ACT_PICKUP_RACK", "Wave_close", "wave", "ACT_PICKUP_GROUND" }
-- busted: cowering as the unit takes him
local BUSTED = { "ACT_COWER", "cower" }

-- The first sequence the model has, by sequence name or by activity name ("ACT_...").
local function FindSeq(ent, names)
    for _, name in ipairs(names) do
        local id
        if string.sub(name, 1, 4) == "ACT_" then
            local act = _G[name]
            if act and ent.SelectWeightedSequence then id = ent:SelectWeightedSequence(act) end
        else
            id = ent:LookupSequence(name)
        end
        if id and id >= 0 then return id end
    end
end

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(MODELS[math.random(#MODELS)])
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    if self.SetPlaybackRate then self:SetPlaybackRate(1) end
    self:Idle()
end

if SERVER then
    -- Back to an idle (a random one of those the model has), and when to pick again.
    function ENT:Idle()
        local have = {}
        for _, name in ipairs(IDLES) do
            local id = FindSeq(self, { name })
            if id then have[#have + 1] = id end
        end
        if #have > 0 then self:ResetSequence(have[math.random(#have)]) end
        self.lcBusyUntil = nil
        self.lcNextIdle = CurTime() + math.Rand(8, 16)
    end

    -- One pass of a sequence (a deal, a bust), then back to idling.
    function ENT:Act(names)
        local id = FindSeq(self, names)
        if not id then return end
        self:ResetSequence(id)
        if self.SetCycle then self:SetCycle(0) end
        local secs = (self.SequenceDuration and self:SequenceDuration(id)) or 2
        self.lcBusyUntil = CurTime() + math.Clamp(secs, 0.5, 6)
    end

    -- (made once here, not every frame)
    local V_0_0_64 = Vector(0, 0, 64)
    function ENT:Think()
        local now = CurTime()
        if self.lcBusyUntil and now >= self.lcBusyUntil then self:Idle()
        elseif not self.lcBusyUntil and (self.lcNextIdle or 0) <= now then self:Idle() end
        -- the head follows whoever is nearest, five times a second (the pose is networked)
        if (self.lcNextLook or 0) <= now and self.SetPoseParameter then
            self.lcNextLook = now + 0.2
            local best, bestD
            for _, p in ipairs(player.GetAll()) do
                if p:Alive() then
                    local d = p:GetPos():DistToSqr(self:GetPos())
                    if d < 300 * 300 and (not bestD or d < bestD) then best, bestD = p, d end
                end
            end
            local yaw, pitch = 0, 0
            if best then
                local dir = (best:EyePos() - (self:GetPos() + V_0_0_64)):Angle()
                yaw = math.Clamp(math.NormalizeAngle(dir.y - self:GetAngles().y), -60, 60)
                pitch = math.Clamp(math.NormalizeAngle(dir.p), -30, 30)
            end
            self:SetPoseParameter("head_yaw", yaw)
            self:SetPoseParameter("head_pitch", pitch)
        end
        self:NextThink(now)
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if self:GetNW2Bool("lc_busted", false) then return end
        if LC.PlayerIsCP(activator) then
            self:Act(BUSTED)
            if LC.BustDealer then LC.BustDealer(activator, self) end
        elseif LC.OpenMarket then
            self:Act(SERVE)
            LC.OpenMarket(activator)
        end
    end
end

if CLIENT then
    function ENT:Draw()
        if self:GetNW2Bool("lc_busted", false) then return end
        self:DrawModel()
    end
end
