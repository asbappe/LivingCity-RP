--[[
    Living City: citizens who show you the way

    Chat with a citizen (E on them, then Chat) while you need something and
    now and then they notice and help, instead of a card telling you (the
    owner, 10 November: "a vague statement and a waypoint and path node trail
    guidance", or "Here, let me show you" and walk over there). The words
    never name a place, so they fit any map: where to go comes from what the
    editor placed (the next step's own places, sv_livingcity_nextstep.lua).

      A citizen who likes you (warm) walks you there: "Come on, I'll show
      you." They stop and wait if you fall behind, and say one line when you
      arrive. If they can't get there (no route, stuck, pulled away, gone),
      or you wander off, they point instead.
      Anyone else says something vague, and the marker and the trail on the
      ground (LC.GuideTo) show the way.
      Nothing of the kind on this map: "Can't help you there, friend."

    What they help with is your next step (LC.NextStep): registering, work,
    a room, food, water, your block, a job, a shift. Advice comes at most
    once a minute; the rest of the time Chat is the rumours and small talk
    as before.

    Recordings, if you make them: garrysmod/sound/livingcity/citizens/,
    named for the line and the voice, advice_bins_male1.wav,
    advice_bins_female1.wav (more takes: 2, 3...). Without one they say the
    words with Half-Life 2's own citizen voice. Every line: VOICE_LINES.md,
    section 5 (LC.AdviceLines below is the list).

    Settings: lc_citizen_advice (1; 0 is Chat as before), lc_citizen_lead
    (1; 0: nobody walks you, everyone points), lc_citizen_lead_range (3000:
    further than this, even a friend points).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAdvice = CreateConVar("lc_citizen_advice", "1", FLAGS, "Citizens you chat with notice what you need and show you the way (a trail, or a friend walks you there)")
local cvLead = CreateConVar("lc_citizen_lead", "1", FLAGS, "A citizen who likes you walks you to what you need (0: they only point the way)")
local cvLeadRange = CreateConVar("lc_citizen_lead_range", "3000", FLAGS, "Further than this (units), even a friendly citizen points instead of walking you there")

local WARM = 3
local COOLDOWN = 60
local LEAD_SECS = 150
local FAR, CLOSE, LOST, ARRIVE = 450, 250, 1600, 170

LC.AdviceVoiceRoot = "livingcity/citizens/"

-- Every line a citizen says when helping: id = words. The id is the recording's name.
LC.AdviceLines = {
    advice_intake = "You're new, aren't you? Get yourself on the register before anything else. Over that way.",
    advice_labor = "Registered, but no work? Nobody gets a room without a work assignment. Go and get one.",
    advice_housing = "Nowhere to sleep? They hand out rooms. Go and ask, it's not far.",
    advice_ration = "Your ration's waiting. Don't leave it too long, they notice who doesn't come.",
    advice_buy = "You look hungry, and you've got credits. The Commissary has food. Go on.",
    advice_work = "Hungry, and no card? Work a shift. It's the only way they give you one.",
    advice_bins = "You look half-starved. Try the bins. Nobody checks them as often as they should.",
    advice_water = "You look parched. There's water near here. Drink before you fall down.",
    advice_home = "You look lost. Your block's that way. Get there before curfew.",
    advice_job = "No work? The Union doesn't like idle hands. Find a job before they find you.",
    advice_shift = "Short on credits? Get to work. A shift pays.",
    advice_eat_own = "You've got food on you, haven't you? Eat it, before someone takes it off you.",
    advice_drink_own = "You've something to drink in your coat. Drink it. You look awful.",
    advice_nowhere = "Can't help you there, friend. I wish I could.",
    lead_start = "Come on, I'll show you. Stay close.",
    lead_start2 = "Here, let me show you. Follow me.",
    lead_wait = "Keep up! I'm not waiting all day.",
    lead_arrive = "Here. Don't tell anyone I helped you.",
    lead_arrive2 = "This is it. Good luck.",
    lead_giveup = "Fine. It's that way. Find it yourself.",
    lead_cantgo = "I can't go there. It's that way, look.",
}

-- Your next step's key: the line, and whether there's a place to show.
local FOR_STEP = {
    intake = "advice_intake", labor = "advice_labor", housing = "advice_housing",
    eat_ration = "advice_ration", ration = "advice_ration", eat_buy = "advice_buy",
    eat_work = "advice_work", eat_scrounge = "advice_bins", drink = "advice_water",
    home = "advice_home", job = "advice_job", shift = "advice_shift",
    eat_own = "advice_eat_own", drink_own = "advice_drink_own",
}
LC.AdviceForStep = FOR_STEP

------------------------------------------------------------------------
-- Their voice: a recording if there is one, else Half-Life 2's citizen
------------------------------------------------------------------------

local AUDIO = { wav = true, mp3 = true, ogg = true }
local clips -- [id .. "_" .. gender] = { paths }
local function Scan()
    clips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.AdviceVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            clips[base] = clips[base] or {}
            table.insert(clips[base], LC.AdviceVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.AdviceVoiceRoot .. n) end
        end
    end
    return clips
end
LC.AdviceRescan = Scan
hook.Add("Initialize", "LivingCityAdviceVoices", Scan)

-- Is any line whose name starts with prefix recorded for this sex? (sv_livingcity_lines.lua: LC.OwnVoice)
local anyCache = {}
function LC.AdviceHasAny(prefix, gender)
    if not clips then Scan() end
    local g = gender == "female" and "female" or "male"
    local key = prefix .. g
    if anyCache.clips ~= clips then anyCache = { clips = clips } end
    if anyCache[key] == nil then
        local found = false
        for base in pairs(clips) do
            if string.sub(base, 1, #prefix) == prefix and string.sub(base, -#g - 1) == "_" .. g then found = true break end
        end
        anyCache[key] = found
    end
    return anyCache[key]
end

function LC.AdviceClip(id, gender)
    if not clips then Scan() end
    local t = clips[id .. "_" .. (gender == "female" and "female" or "male")]
    return t and t[math.random(#t)] or nil
end

local HL2 = { advice_nowhere = "sorry0" .. math.random(1, 3), lead_wait = "squad_follow02", lead_arrive = "ok01",
    lead_arrive2 = "ok02", lead_giveup = "letsgo01", lead_cantgo = "sorry01", lead_start = "letsgo02", lead_start2 = "squad_follow01" }
local function Say(npc, st, id, ply)
    if not IsValid(npc) then return end
    local g = st and st.gender or "male"
    local clip = LC.AdviceClip(id, g)
    if clip then
        npc:EmitSound(clip, 70)
    else
        local vo = HL2[id] or string.format("question%02d", math.random(1, 20))
        local path = "vo/npc/" .. (g == "female" and "female01" or "male01") .. "/" .. vo .. ".wav"
        -- (a named citizen with a recorded voice never borrows Half-Life 2's, unless that clip is re-recorded)
        if not (LC.OwnVoice and LC.OwnVoice(npc, st, path)) then npc:EmitSound(path, 65) end
    end
    if IsValid(ply) and LC.Notice then
        LC.Notice(ply, "speech", LC.NPCStr and LC.NPCStr(npc, "lc_pname", "A citizen") or "A citizen", LC.AdviceLines[id] or "")
    end
end
LC.AdviceSay = Say

------------------------------------------------------------------------
-- Pointing, and walking you there
------------------------------------------------------------------------

LC.AdviceLeads = LC.AdviceLeads or {} -- [npc] = { ply, pos, label, untilT, tries, waiting, nextWait }

local function Point(ply, pos, label)
    if LC.GuideTo then LC.GuideTo(ply, pos, label) elseif LC.SetWaypoint then LC.SetWaypoint(ply, pos, label, 170) end
end

local function EndLead(npc, line)
    local l = LC.AdviceLeads[npc]
    if not l then return end
    LC.AdviceLeads[npc] = nil
    local st = LC.NPCs and LC.NPCs[npc]
    if st then st.lcLeading = nil end
    if line and IsValid(npc) then Say(npc, st, line, l.ply) end
    if line ~= "lead_arrive" and line ~= "lead_arrive2" and IsValid(l.ply) then Point(l.ply, l.pos, l.label) end
    if IsValid(npc) and st and st.state == "moving" and st.dest == l.pos then
        npc:SetSchedule(SCHED_IDLE_STAND)
        if LC.SetState then LC.SetState(npc, st, "idle") end
        st.untilT = CurTime() + 4
    end
end
LC.AdviceEndLead = EndLead

local function Walk(npc, st, l)
    return LC.GoTo and LC.GoTo(npc, st, l.pos, false) or false
end

local function Lead(ply, npc, st, pos, label)
    for n, l in pairs(LC.AdviceLeads) do if l.ply == ply then EndLead(n) end end
    local l = { ply = ply, pos = pos, label = label, untilT = CurTime() + LEAD_SECS, tries = 0, nextWait = 0 }
    LC.AdviceLeads[npc] = l
    st.lcLeading = ply
    if not Walk(npc, st, l) then
        LC.AdviceLeads[npc] = nil
        st.lcLeading = nil
        return false
    end
    return true
end

function LC.AdviceLeadTick()
    local now = CurTime()
    for npc, l in pairs(LC.AdviceLeads) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        local ply = l.ply
        if not IsValid(ply) or not ply:Alive() then
            LC.AdviceLeads[npc] = nil
            if st then st.lcLeading = nil end
        elseif not st or st.state == "detained" or st.state == "jailed" or st.state == "escorted"
            or st.state == "event" or st.state == "hostile" or (npc.Health and npc:Health() <= 0) then
            LC.AdviceLeads[npc] = nil
            if st then st.lcLeading = nil end
            Point(ply, l.pos, l.label) -- (they can't go on: the trail does)
        elseif now > l.untilT then
            EndLead(npc, "lead_giveup")
        else
            local npos, ppos = npc:GetPos(), ply:GetPos()
            local behind = npos:Distance(ppos)
            local d = npos:Distance(l.pos)
            if d < ARRIVE or (d < ARRIVE * 2 and st.state ~= "moving" and not l.waiting) then
                LC.Face(npc, ppos)
                EndLead(npc, math.random() < 0.5 and "lead_arrive" or "lead_arrive2")
            elseif behind > LOST then
                EndLead(npc, "lead_giveup")
            elseif behind > FAR then
                -- wait for them
                if not l.waiting then
                    l.waiting = true
                    npc:SetSchedule(SCHED_IDLE_STAND)
                    if LC.SetState then LC.SetState(npc, st, "idle") end
                end
                st.untilT = now + 3
                LC.Face(npc, ppos)
                if now > l.nextWait then l.nextWait = now + 15 Say(npc, st, "lead_wait", ply) end
            elseif l.waiting and behind < CLOSE then
                l.waiting = false
                if not Walk(npc, st, l) then EndLead(npc, "lead_cantgo") end
            elseif not l.waiting and (st.state ~= "moving" or st.dest ~= l.pos) then
                -- pulled off course (or the walk gave up): back on it, a few times
                l.tries = l.tries + 1
                if l.tries > 3 or not Walk(npc, st, l) then EndLead(npc, "lead_cantgo") end
            end
        end
    end
end
timer.Create("LivingCityAdviceLead", 0.5, 0, function() LC.AdviceLeadTick() end)

------------------------------------------------------------------------
-- In Chat (sv_livingcity_talk.lua)
------------------------------------------------------------------------

-- What a citizen says to help, or nil (Chat goes on as before). Second value true: close the window (they're off).
function LC.CitizenAdvice(ply, npc, st, feel)
    if not cvAdvice:GetBool() or not LC.NextStep or not IsValid(ply) or not st then return nil end
    if (ply.lcAdviceNext or 0) > CurTime() or st.lcLeading then return nil end
    local step = LC.NextStep(ply)
    local id = step and FOR_STEP[step.key]
    if not id then return nil end
    ply.lcAdviceNext = CurTime() + COOLDOWN
    local way = step.way
    local find = way and LC.WaypointPlaces and LC.WaypointPlaces[way]
    if not find then
        Say(npc, st, id)
        return "'" .. LC.AdviceLines[id] .. "'"
    end
    local pos, label = find(ply)
    if not pos then
        Say(npc, st, "advice_nowhere")
        return "'" .. LC.AdviceLines.advice_nowhere .. "'"
    end
    hook.Run("LivingCityCitizenAdvice", ply, npc, step.key)
    if (feel or 0) >= WARM and cvLead:GetBool() and npc:GetPos():Distance(pos) <= cvLeadRange:GetFloat()
        and Lead(ply, npc, st, pos, label) then
        local s = math.random() < 0.5 and "lead_start" or "lead_start2"
        Say(npc, st, s, ply)
        return "'" .. LC.AdviceLines[id] .. " " .. LC.AdviceLines[s] .. "'", true
    end
    Say(npc, st, id)
    Point(ply, pos, label)
    return "'" .. LC.AdviceLines[id] .. "' They nod the way."
end

hook.Add("PlayerDisconnected", "LivingCityAdvice", function(ply)
    for n, l in pairs(LC.AdviceLeads) do if l.ply == ply then EndLead(n) end end
end)
