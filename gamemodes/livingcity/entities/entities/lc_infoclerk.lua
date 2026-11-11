--[[
    Citizen Information clerk (Living City). Place it with the Living City
    Editor ("Fixture: Citizen Information desk"), behind a counter, so it saves
    with the map layout. Press E and the clerk answers questions on the city's
    rules, the official version (sv_livingcity_infodesk.lua).

    Built like the black market dealer (lc_dealer.lua): a few idles, the head
    turning to whoever is nearest, a gesture when answering.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Citizen Information clerk"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

local MODELS = {
    "models/humans/group01/female_01.mdl", "models/humans/group01/female_04.mdl",
    "models/humans/group01/male_02.mdl", "models/humans/group01/male_04.mdl",
}
-- idles: any the model has; the dealer wanders between them
local IDLES = { "LineIdle01", "LineIdle02", "LineIdle03", "idle_subtle", "Idle_Unarmed", "ACT_IDLE" }
-- answering: a small gesture
local SERVE = { "Wave_close", "wave", "ACT_PICKUP_RACK" }

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
    self:SetNW2String("lc_gender", string.find(self:GetModel(), "female", 1, true) and "female" or "male")
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
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.OpenInfoDesk then return end
        if LC.OpenInfoDesk(activator, self) then self:Act(SERVE) end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
