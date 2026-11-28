--[[
    Living City: the endings' dances, done with ActMod's animations (client)

    The owner, 28 November: "all our animations suck tbh, so I'd rather just use actmod".
    Where the server has ActMod (Workshop 2538387266) and its base (2615656036), each dance
    of an ending or its dream plays one of ActMod's animations instead of our bone turns
    (cl_livingcity_endings.lua asks LC_CL.ActDance first). Which one: LC.ActDances
    (sh_livingcity_dreamdances.lua), changed in the Endings menu, the same on everyone's
    screen. "none" keeps our own. Without ActMod, or on a model that has no such animation,
    our own dance plays as before.

    ActMod's animations are on player models only. A player plays one as their own
    animation. A citizen or a unit is drawn as their player-model twin doing it (only on
    your screen, in their place). Everyone keeps to the song's clock, so they move as one.
    The Conga dream's line walks ActMod's conga the same way (cl_livingcity_strangedreams.lua).
    Nothing of ActMod's is copied: its animations are asked for by name.
]]

LC_CL = LC_CL or {}

local cvs = {}
for move, d in pairs(LC.ActDances or {}) do
    cvs[move] = CreateClientConVar(LC.ActDanceSetting(move), d[1], true, false,
        "ActMod's animation for this dance (none: the gamemode's own)")
end

local function Pick(move)
    local cv = cvs[move]
    if not cv then return nil end
    local v = LC_CL.EndingTunedCV and LC_CL.EndingTunedCV(cv) or cv:GetString()
    if not v or v == "" or v == "none" then return nil end
    return v
end

-- [model][animation] = its number on that model, or false
local seqs = {}
local function SeqOf(ent, name)
    local mdl = ent:GetModel() or ""
    local c = seqs[mdl]
    if not c then c = {} seqs[mdl] = c end
    local s = c[name]
    if s == nil then
        s = ent:LookupSequence(name)
        if not isnumber(s) or s < 0 then s = false end
        c[name] = s
    end
    return s
end

-- How far through the animation the song's clock is (0 to 1): the same for everyone.
local function Frac(ent, seq, clock)
    local dur = ent:SequenceDuration(seq) or 0
    if dur < 0.1 then dur = 1 end
    return (clock % dur) / dur
end

-- Bloom's dancers spin as they rise into the sky.
local function Spin(ent, now)
    local t0 = ent.GetNW2Float and ent:GetNW2Float("lc_spin_t0", 0) or 0
    return t0 > 0 and (((now - t0) ^ 2) * 720 % 360) or 0
end

-- The player model that looks like this citizen or unit, or false. [model] = model
local twins = { ["models/gman.mdl"] = "models/player/gman_high.mdl" }
local function TwinModel(mdl)
    mdl = string.lower(mdl or "")
    local t = twins[mdl]
    if t ~= nil then return t end
    local tries = {
        (string.gsub(mdl, "^models/humans/", "models/player/")),
        (string.gsub(string.gsub(mdl, "^models/humans/", "models/player/"), "/group0%d/", "/group01/")),
        "models/player/" .. (string.match(mdl, "[^/]+$") or ""),
    }
    t = false
    if string.find(mdl, "^models/player/") then
        t = mdl -- (already a player model, as Marrow's skeletons are: its own twin)
    else
        for _, try in ipairs(tries) do
            if string.find(try, "^models/player/") and file.Exists(try, "GAME") then t = try break end
        end
    end
    twins[mdl] = t
    return t
end
LC_CL.ActDanceTwinModel = TwinModel

local active = {} -- [ent] = "player" | "own" | "twin"

local function DropTwin(ent)
    local tw = ent.lcActTwin
    if tw and IsValid(tw) then tw:Remove() end
    ent.lcActTwin = nil
    if ent.lcActDrawn then
        ent.RenderOverride = ent.lcActRenderWas
        ent.lcActRenderWas, ent.lcActDrawn = nil, nil
    end
end

-- This one dances our own way again (or not at all).
function LC_CL.ActDanceStop(ent)
    local how = active[ent]
    if not how then return end
    active[ent] = nil
    if not IsValid(ent) then return end
    if how == "player" then
        ent.lcActDance = nil
    elseif how == "own" then
        if ent.lcActWas and ent.ResetSequence then ent:ResetSequence(ent.lcActWas) ent:SetPlaybackRate(1) end
        ent.lcActWas, ent.lcActSeq = nil, nil
    else
        DropTwin(ent)
    end
end

local function DrawTwin(self)
    local tw, d = self.lcActTwin, self.lcActDance
    if not (tw and IsValid(tw) and d) then return self:DrawModel() end
    local pos = self:GetPos()
    if d.ground then
        -- (the Conga line's figures are bobbed up and down by the server: the twin's feet stay on the floor)
        local tr = util.TraceLine({ start = pos + Vector(0, 0, 8), endpos = pos - Vector(0, 0, 48), filter = self })
        if tr and tr.Hit and not tr.StartSolid then pos = tr.HitPos end
    end
    tw:SetPos(pos)
    tw:SetAngles(Angle(0, self:GetAngles().y + d.spin, 0))
    tw:SetCycle(d.frac)
    tw:SetupBones()
    tw:DrawModel()
end

-- Does ActMod's animation play on this one now? (false: dance our own way.)
-- move: the dance's name; clock: the song's seconds.
function LC_CL.ActDance(ent, move, clock)
    move = string.gsub(move or "", "_combine$", "")
    local name = Pick(move)
    if not name or not IsValid(ent) or not ent.LookupSequence then return false end
    -- a dance shared half and half: every other dancer keeps our own (by their number, so the
    -- same ones on everyone's screen; the Endings menu's stand-in shows ActMod's)
    local idx = ent.EntIndex and ent:EntIndex() or -1
    if LC.ActDances[move].half and idx > 0 and idx % 2 == 0 then return false end
    -- not on the rope, not in the air on the fire, not the hora's rush in or its chair: those are poses
    if ent.GetNW2Float and ent:GetNW2Float("lc_hanged", 0) > 0 then return false end
    if ent.lcTuneFly or ent.lcTuneChair or ent.lcTuneSection == "in" or (ent.GetNW2Bool and ent:GetNW2Bool("lc_flying", false)) then return false end
    local now = CurTime()
    ent.lcActAt = now
    if ent.IsPlayer and ent:IsPlayer() then
        -- (sat on the bus or the plane too; the owner: "just use actmod's animations regardless")
        local seq = SeqOf(ent, name)
        if not seq then return false end
        local d = ent.lcActDance or {}
        d.seq, d.frac, d.till, d.spin = seq, Frac(ent, seq, clock), now + 0.3, Spin(ent, now)
        ent.lcActDance = d
        active[ent] = "player"
        return true
    end
    -- something only on this screen (the Endings menu's stand-in): its own animation, if its model has it
    if not ent.EntIndex or ent:EntIndex() < 0 then
        local seq = ent.ResetSequence and ent.SetCycle and ent.SetPlaybackRate and SeqOf(ent, name)
        if not seq then return false end
        if ent.lcActSeq ~= seq then
            ent.lcActWas = ent.lcActWas or (ent.GetSequence and ent:GetSequence()) or 0
            ent:ResetSequence(seq)
            ent.lcActSeq = seq
        end
        ent:SetPlaybackRate(0)
        ent:SetCycle(Frac(ent, seq, clock))
        active[ent] = "own"
        return true
    end
    -- a citizen, a unit: their player-model twin, drawn in their place
    local mdl = TwinModel(ent:GetModel())
    if not mdl then return false end
    local tw = ent.lcActTwin
    if not (tw and IsValid(tw)) or ent.lcActTwinModel ~= mdl then
        DropTwin(ent)
        tw = ClientsideModel(mdl)
        if not (tw and IsValid(tw)) then return false end
        tw:SetNoDraw(true)
        ent.lcActTwin, ent.lcActTwinModel = tw, mdl
    end
    local seq = SeqOf(tw, name)
    if not seq then DropTwin(ent) twins[string.lower(ent:GetModel() or "")] = false return false end
    if tw.lcActSeq ~= seq then tw:ResetSequence(seq) tw.lcActSeq = seq end
    tw:SetPlaybackRate(0)
    tw:SetSkin(ent:GetSkin() or 0)
    tw:SetModelScale(ent:GetModelScale() or 1)
    local d = ent.lcActDance or {}
    d.seq, d.frac, d.spin, d.ground = seq, Frac(tw, seq, clock), Spin(ent, now), move == "conga"
    ent.lcActDance = d
    if not ent.lcActDrawn then
        ent.lcActRenderWas, ent.lcActDrawn = ent.RenderOverride, true
        ent.RenderOverride = DrawTwin
    end
    active[ent] = "twin"
    return true
end

-- The animation a dancing player plays now (cl_livingcity_endings.lua asks too, so the
-- order the game calls the hooks in does not matter).
function LC_CL.ActDanceSeq(ply)
    local d = ply.lcActDance
    if d and d.till and d.till > CurTime() then return d.seq, d end
end

hook.Add("CalcMainActivity", "LivingCityActDance", function(ply)
    local seq = LC_CL.ActDanceSeq(ply)
    if seq then return ACT_MP_STAND_IDLE, seq end
end)

hook.Add("UpdateAnimation", "LivingCityActDance", function(ply)
    local seq, d = LC_CL.ActDanceSeq(ply)
    if not seq then return end
    ply:SetPlaybackRate(0)
    ply:SetCycle(d.frac)
    if d.spin ~= 0 and ply.SetRenderAngles then ply:SetRenderAngles(Angle(0, ply:EyeAngles().y + d.spin, 0)) end
    return true
end)

-- Those who are gone, or who stopped without a word, are let go (their twins with them).
timer.Create("LivingCityActDanceSweep", 2, 0, function()
    for ent, how in pairs(active) do
        if not IsValid(ent) then
            active[ent] = nil
        elseif CurTime() - (ent.lcActAt or 0) > 1 then
            LC_CL.ActDanceStop(ent)
        end
    end
end)

-- The Endings menu's list: every ActMod animation your own model has, by name.
local choices
function LC_CL.ActDanceChoices()
    if choices and #choices > 0 then return choices end
    choices = {}
    local me = LocalPlayer()
    local list = IsValid(me) and me.GetSequenceList and me:GetSequenceList() or {}
    for _, name in pairs(list) do
        if isstring(name) and string.find(string.lower(name), "^amod_") then choices[#choices + 1] = name end
    end
    table.sort(choices)
    return choices
end
