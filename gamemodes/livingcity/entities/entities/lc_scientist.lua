--[[
    The Resistance's scientist (Living City). He stands at a Resistance lab
    (lc_workbench), which puts him there; he isn't placed by himself. E on
    him: the Resistance get what he can make, anyone else is shown the door,
    and a unit shuts the lab down. See sv_livingcity_lab.lua.

    He isn't a statue (the owner, 7 November): he idles (an idle picked again
    every so often, so no sequence can run out and freeze him), now and then
    fiddles with his bench, turns his head to whoever is nearest, and looks at
    them with open eyes that blink (the owner, 14 November: they stood "with
    their eyes squinting"). He reaches out to hand something over only when
    he really does (ENT:HandOver: what you bought, or what he kept for you),
    never just for being spoken to, and doesn't fiddle with the bench while
    someone is at his elbow (the owner, 14 November).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Resistance scientist"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

local MODELS = { "models/kleiner.mdl", "models/humans/group02/male_02.mdl" }
local IDLES = { "idle_subtle", "LineIdle01", "LineIdle02", "LineIdle03", "LineIdle04", "idle01", "Idle01", "idle_all_01", "Idle_Relaxed_01", "idle_relaxed", "idle", "ACT_IDLE" }
-- at the bench: reaching to a rack (Kleiner and the citizens both have it), else bending down
local WORK = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND", "ACT_CIT_HEAL", "heal" }

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
    local m = self.lcModel or MODELS[1] -- (which scientist: sv_livingcity_lab.lua picks one for each lab)
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[1] end
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    if self.SetPlaybackRate then self:SetPlaybackRate(1) end
    self:Idle()
end

if SERVER then
    -- Back to an idle (a random one of those the model has), and when to move again.
    function ENT:Idle()
        local have = {}
        for _, name in ipairs(IDLES) do
            local id = FindSeq(self, { name })
            if id then have[#have + 1] = id end
        end
        if #have > 0 then self:ResetSequence(have[math.random(#have)]) end
        self.lcBusyUntil = nil
        self.lcNextIdle = CurTime() + math.Rand(8, 16)
        -- every so often, a moment at the bench
        self.lcNextWork = self.lcNextWork or (CurTime() + math.Rand(15, 40))
    end

    -- One pass of a sequence, then back to idling.
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
        elseif not self.lcBusyUntil then
            if (self.lcNextWork or 0) <= now then
                self.lcNextWork = now + math.Rand(20, 50)
                -- (not with someone right by him: it looked like handing them something)
                local near = false
                for _, p in ipairs(player.GetAll()) do
                    if p:Alive() and p:GetPos():DistToSqr(self:GetPos()) < 160 * 160 then near = true break end
                end
                if not near then self:Act(WORK) end
            elseif (self.lcNextIdle or 0) <= now then self:Idle() end
        end
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

    -- Handing something over: what was bought, or kept for someone (sv_livingcity_lab.lua).
    function ENT:HandOver()
        self:Act(WORK)
        self.lcHandedAt = CurTime()
    end

    function ENT:Use(activator)
        if not (IsValid(activator) and activator:IsPlayer() and LC and LC.UseScientist) then return end
        LC.UseScientist(activator, self)
    end
end

if CLIENT then
    -- Eyes open, looking at whoever is nearest, and a blink every few seconds: without this a
    -- prop of a face sits with its lids half down. Flexes found once by name, per model.
    local CLOSERS = { "blink", "lid_closer", "lid_droop", "lid_tightener", "half_closed", "squint" }
    local function Lids(ent)
        if ent.lcLids and ent.lcLidsModel == ent:GetModel() then return ent.lcLids end
        local t = { shut = {}, raise = {} }
        for i = 0, (ent.GetFlexNum and ent:GetFlexNum() or 0) - 1 do
            local n = string.lower(ent:GetFlexName(i) or "")
            if string.find(n, "lid_raiser", 1, true) then t.raise[#t.raise + 1] = i
            else
                for _, c in ipairs(CLOSERS) do if string.find(n, c, 1, true) then t.shut[#t.shut + 1] = i break end end
            end
        end
        ent.lcLids, ent.lcLidsModel = t, ent:GetModel()
        return t
    end
    function ENT:Draw()
        if self:GetNW2Float("lc_away_until", 0) > CurTime() then return end
        local now = CurTime()
        if self.SetFlexWeight then
            local t = Lids(self)
            if now > (self.lcBlinkAt or 0) then self.lcBlinkAt = now + math.Rand(2.5, 6) end
            local shut = (self.lcBlinkAt - now) < 0.12 and 1 or 0
            for _, i in ipairs(t.shut) do self:SetFlexWeight(i, shut) end
            for _, i in ipairs(t.raise) do self:SetFlexWeight(i, shut > 0 and 0 or 0.3) end
        end
        if self.SetEyeTarget then
            local lp = LocalPlayer()
            if IsValid(lp) and lp:GetPos():DistToSqr(self:GetPos()) < 400 * 400 then
                self:SetEyeTarget(lp:EyePos())
            else
                self:SetEyeTarget(self:GetPos() + self:GetForward() * 100 + Vector(0, 0, 64))
            end
        end
        self:DrawModel()
    end
end
