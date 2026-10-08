--[[
    Living City: Resistance lookouts

    A Resistance Member (rank 2 and up) talking to a sympathizer (E on them:
    the talk window, sv_livingcity_talk.lua) can ask them to keep watch. They
    stay where they're standing for lc_lookout_minutes (15) and, when Civil
    Protection or Overwatch come into sight, shout a warning and tell the
    whole Resistance on Freq 7 where. Two at a time each.

    A lookout is still a citizen: a unit can stop them (E), search them, or
    take them in, and then the Resistance hears the lookout's gone quiet.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMinutes = CreateConVar("lc_lookout_minutes", "15", FLAGS, "How long a Resistance lookout keeps watch")
local cvRange   = CreateConVar("lc_lookout_range", "1100", FLAGS, "How far a lookout sees units coming")
local MAX_EACH = 2

LC.Lookouts = LC.Lookouts or {} -- [npc] = { owner, pos, untilT, warnedAt }

local function Pick(t) return t[math.random(#t)] end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "somewhere" end
local function Vo(gender, name) return "vo/npc/" .. (gender or "male") .. "01/" .. name .. ".wav" end

local function Count(ply)
    local n = 0
    for npc, l in pairs(LC.Lookouts) do if IsValid(npc) and l.owner == ply then n = n + 1 end end
    return n
end

function LC.CanRecruitLookout(ply, npc)
    if not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "resistance" then return false, "Only the Resistance asks this of people." end
    if ply:GetNW2Int("lcf_rank", 1) < 2 then return false, "They don't know you well enough. (Member and up)" end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" or not st.rebel then return false, "They wouldn't." end
    if LC.Lookouts[npc] then return false, "They're already keeping watch." end
    if LC.Feeling and LC.Feeling(npc, ply) <= -3 then return false, "They're afraid of you." end
    if Count(ply) >= MAX_EACH then return false, "You already have two people keeping watch." end
    return true
end

function LC.RecruitLookout(ply, npc)
    local ok, why = LC.CanRecruitLookout(ply, npc)
    if not ok then return false, why end
    local st = LC.NPCs[npc]
    local now = CurTime()
    if st.npcWork and LC.NPCWorkDrop then LC.NPCWorkDrop(npc, st) end
    LC.Release(npc, st)
    npc:SetSchedule(SCHED_IDLE_STAND)
    LC.SetState(npc, st, "lookout")
    st.lookoutUntil = now + cvMinutes:GetFloat() * 60
    LC.Lookouts[npc] = { owner = ply, pos = npc:GetPos(), untilT = st.lookoutUntil, warnedAt = 0 }
    npc:SetNW2Bool("lc_lookout", true)
    npc:SetNW2String("lc_doing", "keeping watch")
    if LC.Remember then LC.Remember(npc, ply, 1) end
    hook.Run("LivingCityLookout", ply, npc)
    return true, string.format("They nod, and lean against the wall like they've nowhere to be. They'll watch %s for %d minutes. (Freq 7 hears what they see.)",
        Where(npc:GetPos()), cvMinutes:GetInt())
end

-- Freq 7 hears it; whoever posted them always does (a whistle, a runner), radio or not.
local function Tell(l, text)
    if LC.RadioNotice then LC.RadioNotice("resistance", text) end
    local o = l and l.owner
    if IsValid(o) and not (LC.RadioBand and LC.RadioBand(o) == "resistance") then o:ChatPrint("[Your lookout] " .. text) end
end

local function End(npc, why)
    local l = LC.Lookouts[npc]
    LC.Lookouts[npc] = nil
    if IsValid(npc) then
        npc:SetNW2Bool("lc_lookout", false)
        npc:SetNW2String("lc_doing", "")
        local st = LC.NPCs[npc]
        if st and st.state == "lookout" then LC.SetState(npc, st, "idle") st.untilT = CurTime() + 2 end
    end
    if l and why then Tell(l, why) end
end
LC.EndLookout = End

-- Units in sight of a lookout.
local function Spotted(npc, l)
    local eye, r2 = npc:EyePos(), cvRange:GetFloat() ^ 2
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetPos():DistToSqr(l.pos) < r2 and LC.LooksCombine and LC.LooksCombine(p)
            and LC.LineOfSight(eye, p:EyePos(), npc, p) then return p end
    end
    for n2, s2 in pairs(LC.NPCs) do
        if (s2.role == "cop" or s2.role == "soldier") and IsValid(n2) and n2:GetPos():DistToSqr(l.pos) < r2
            and LC.LineOfSight(eye, n2:EyePos(), npc, n2) then return n2 end
    end
    return nil
end

function LC.LookoutTick(now)
    now = now or CurTime()
    for npc, l in pairs(LC.Lookouts) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if not st or npc:Health() <= 0 then
            End(npc, "The lookout " .. Where(l.pos) .. " has gone quiet.")
        elseif st.state ~= "lookout" and (st.state == "detained" or st.state == "jailed" or st.state == "escorted"
            or st.state == "hostile" or st.state == "fighting") then
            End(npc, "The lookout " .. Where(l.pos) .. " has been stopped by a unit.")
        elseif st.state ~= "lookout" then
            -- (spoken to, or briefly busy: back to the watch, not a reason to stand down)
            LC.SetState(npc, st, "lookout")
        elseif now > l.untilT then
            End(npc, nil)
            if IsValid(l.owner) then l.owner:ChatPrint("[Resistance] Your lookout " .. Where(l.pos) .. " has gone home.") end
        elseif now - l.warnedAt > 45 then
            local who = Spotted(npc, l)
            if who then
                l.warnedAt = now
                npc:EmitSound(Vo(st.gender, math.random() < 0.5 and "combine01" or "combine02"), 80) -- "Combine!"
                local what = who:IsPlayer() and "a unit" or (LC.NPCs[who] and LC.NPCs[who].role == "soldier" and "Overwatch" or "a unit")
                Tell(l, "Lookout " .. Where(l.pos) .. ": " .. what .. " coming.")
                hook.Run("LivingCityLookoutWarned", npc, who)
            end
        end
    end
end

timer.Create("LivingCityLookouts", 2, 0, function()
    if next(LC.Lookouts) == nil then return end
    local ok, err = pcall(LC.LookoutTick, CurTime())
    if not ok and LC.Error then LC.Error("lookouts", err) end
end)

hook.Add("PlayerDisconnected", "LivingCityLookouts", function(ply)
    for npc, l in pairs(LC.Lookouts) do if l.owner == ply then End(npc, nil) end end
end)
