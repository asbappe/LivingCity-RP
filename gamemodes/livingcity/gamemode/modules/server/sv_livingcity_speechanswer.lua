--[[
    Living City: the Resistance answers her speeches

    The owner, 12 November: "dynamic speeches. The Administrator's speeches made up from what is
    happening in the city, and the Resistance's anti-Administrator answer, maybe given by Colonel
    Cubbage; the resistance ghost then uses some other old man's model."

    Her address (sv_livingcity_speech.lua) is made up from what happened lately. A few minutes after
    one ends (lc_speech_answer_delay, 240 seconds), Colonel Cubbage answers it from the Resistance's
    camp: he stands up by the quartermaster (Odessa Cubbage's face, alive and well; he stays only as
    long as he speaks) and takes her apart, point by point:

      - an opening, then an answer to each thing she spoke about (up to three: the deaths, the
        arrests, the hunger, the mood...; LC.SpeechAnswerLines), then a closing;
      - when she gave her own words (a player Administrator), he answers what the city has been
        through lately instead (the same pieces she would have chosen: LC.SpeechCompose);
      - everyone within lc_speech_answer_radius (900) of him hears it in chat, and so does anyone
        whose radio is on Freq 7 while it's on the air; a recording of a line cuts in on Freq 7 too.

    No camp (no quartermaster and no rebel ground), the Combine in the camp, or lc_speech_answer 0:
    no answer.

    The ghost by the quartermaster (sv_livingcity_colonel.lua) now wears another old man's face
    (lc_colonel_model, a Half-Life 2 citizen), so the two are never the same man; lc_colonel_model
    models/odessa.mdl puts the old face back.

    Recordings, if you make them: garrysmod/sound/livingcity/cubbage/, named for the line
    (answer_open1.wav, answer_ev_deaths1.wav, answer_close1.wav; .wav, .mp3 or .ogg). Every line:
    VOICE_LINES.md. Without one, his words are in chat only.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_speech_answer", "1", FLAGS, "Colonel Cubbage answers the Administrator's addresses from the Resistance's camp (and on Freq 7)")
local cvDelay  = CreateConVar("lc_speech_answer_delay", "240", FLAGS, "Seconds after her address ends before Colonel Cubbage answers it")
local cvRadius = CreateConVar("lc_speech_answer_radius", "900", FLAGS, "How far from Colonel Cubbage his answer is heard (besides on Freq 7)")
local cvGhost  = CreateConVar("lc_colonel_model", "models/Humans/Group01/male_07.mdl", FLAGS,
    "The face of the Colonel, the ghost only the Resistance sees (models/odessa.mdl: Odessa Cubbage's, as it was; Cubbage himself now answers her speeches)")

LC.CubbageVoiceRoot = "livingcity/cubbage/"
LC.CubbageModel = "models/odessa.mdl"

-- His answer to each piece of her address (LC.SpeechPieces), and his own opening and closing.
LC.SpeechAnswerLines = {
    open = "You heard her. Now hear me. Colonel Cubbage, and I have a few corrections to make.",
    ev_deaths = "She talks about blood in the streets. Ask whose hands it's on. Her units don't carry those batons for show.",
    ev_arrests = "Not one of them taken at random, she says. Then tell me what crime a man commits by standing in the wrong square.",
    ev_informers = "She thanks the ones who whispered to her. We know who you are too. It isn't too late to stop.",
    ev_informer_hurt = "She calls us cowards. We don't drag families out of bed at night. We deal with the ones who sell their neighbours.",
    ev_taken = "Yes, we take some of hers, and we ask them questions. She takes all of you, every day, and doesn't bother asking.",
    ev_escape = "Some of ours walked out of her cells. Good. If one of them knocks at your door, open it.",
    ev_posters = "She frets about her posters. Paper. She worries about paper while you go hungry.",
    ev_theft = "Stealing, she says. The only thief in this city sits in an office and takes your bread to pay for her speeches.",
    ev_defiance = "People raised their voices at her officers. Good. Your voice is the first thing they take, and the last thing you should give up.",
    ev_sabotage = "Broken machines hurt only you, she says. They're her machines, and they keep you in line. Let them break.",
    ev_heavyhand = "Firmness, she calls it. You saw what it was. Remember it.",
    ev_drink = "She doesn't blame you for drinking. Of course she doesn't. A drunk doesn't fight back.",
    ev_kindness = "She takes the credit for you sharing your bread. That was you. It's the one thing she can't stamp out, and it frightens her.",
    ev_despair = "Hope is a choice, she says. Then choose it. Just don't let her tell you what to hope for.",
    unrest = "Whispers of freedom mean chaos, she says. We mean freedom. She knows the difference, and it terrifies her.",
    hunger = "She feels every empty bowl, does she? Then why is hers never empty?",
    order = "Her authority is not in question, she says. When someone has to say that out loud, it already is.",
    morale = "Tired faces, she says. You're tired because she works you to the bone. Rest isn't her gift. It's yours.",
    calm = "Quiet days, she calls them. Quiet is what she calls it when nobody dares to speak.",
    mood_afraid = "You've nothing to fear from her, she says. Tell that to the ones she's taken.",
    mood_restless = "She feels your restlessness, she says. Good. Let her feel it.",
    mood_content = "Rested, fed and calm, she says. Look around you. Does that look like anyone you know?",
    slogan = "Love your neighbour, hate the traitor, she says. We agree. Ask yourself who sold this city.",
    close = "That's all from me. Keep your heads down, your eyes open, and your door unlocked for a friend. We're closer than she thinks.",
}

-- His answer to an address: a list of { id, words } (an opening, up to three answers, a closing).
-- pieces: what she said (LC.SpeechPieces entries), or nil to answer what the city has been through lately.
function LC.SpeechAnswerCompose(pieces)
    if not pieces and LC.SpeechCompose then
        local since = CurTime() - 4 * 3600
        local cv = GetConVar("lc_speech_lookback")
        if cv then since = CurTime() - cv:GetFloat() * 60 end
        local state = LC.Ledger and LC.Ledger() or {}
        pieces = LC.SpeechCompose(state, LC.SpeechEvents and LC.SpeechEvents(since) or {}, LC.SpeechMood and LC.SpeechMood() or nil)
    end
    local L = LC.SpeechAnswerLines
    local out = { { id = "open", words = L.open } }
    for _, p in ipairs(pieces or {}) do
        local id = istable(p) and p.id or p
        if id ~= "open" and id ~= "close" and L[id] and #out < 4 then out[#out + 1] = { id = id, words = L[id] } end
    end
    if #out == 1 then out[#out + 1] = { id = "calm", words = L.calm } end
    out[#out + 1] = { id = "close", words = L.close }
    return out
end

-- A recording of one of his lines, or nil.
local clips = {}
function LC.CubbageClip(id)
    if clips[id] == nil then
        clips[id] = false
        for _, n in ipairs(file.Find("sound/" .. LC.CubbageVoiceRoot .. "answer_" .. id .. "*", "GAME") or {}) do
            local ext = string.lower(string.match(n, "%.(%w+)$") or "")
            local base = string.match(n, "^answer_(.-)%d*%.%w+$")
            if base == id and (ext == "wav" or ext == "mp3" or ext == "ogg") then clips[id] = LC.CubbageVoiceRoot .. n break end
        end
    end
    return clips[id] or nil
end
do -- (sent to players when the map starts, like every recording)
    for _, n in ipairs(file.Find("sound/" .. LC.CubbageVoiceRoot .. "*", "GAME") or {}) do
        if resource and resource.AddFile then resource.AddFile("sound/" .. LC.CubbageVoiceRoot .. n) end
    end
end

-- The ghost's face, for the Resistance's screens (cl_livingcity_colonel.lua).
local function GhostFace() if SetGlobal2String then SetGlobal2String("lc_colonel_model", cvGhost:GetString()) end end
GhostFace()
if cvars and cvars.AddChangeCallback then cvars.AddChangeCallback("lc_colonel_model", function() GhostFace() end, "LivingCitySpeechAnswer") end

------------------------------------------------------------------------
-- Answering
------------------------------------------------------------------------

local A -- the answer under way: { queue, nextAt, man, pos }
local due -- { at, pieces }
function LC.SpeechAnswerState() return A, due end

-- Who hears a line: near him, or on Freq 7 while it's on the air.
function LC.SpeechAnswerHearers(pos)
    local out, seen = {}, {}
    local r = cvRadius:GetFloat()
    for _, p in ipairs(player.GetAll()) do
        if pos and p:GetPos():DistToSqr(pos) <= r * r then out[#out + 1] = { p, "near" } seen[p] = true end
    end
    local now = LC.Freq7Now and LC.Freq7Now()
    if now and now.onAir and now.f then
        for p, l in pairs(LC.Listening or {}) do
            if IsValid(p) and not seen[p] and l.dial and math.abs(l.dial - now.f) < 0.15 then out[#out + 1] = { p, "radio" } end
        end
    end
    return out
end

local function Say(line)
    local clip = LC.CubbageClip(line.id)
    if clip and IsValid(A.man) then A.man:EmitSound(clip, 90, 100) end
    if clip and LC.Freq7CutIn then LC.Freq7CutIn(clip, line.words) end
    local heard = {}
    for _, h in ipairs(LC.SpeechAnswerHearers(A.pos)) do
        local p, how = h[1], h[2]
        heard[p] = true
        p:ChatPrint((how == "radio" and "[Freq 7] Colonel Cubbage: " or "[Colonel Cubbage, at the camp] ") .. line.words)
    end
    -- and from every loudspeaker the Resistance's hackers have spliced into (sv_livingcity_speakerhack.lua)
    if LC.SpeakerHackSay then LC.SpeakerHackSay(clip, line.words, heard) end
    local secs = clip and LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(clip) or 0
    if secs <= 0.2 then
        local n = 0
        for _ in string.gmatch(line.words, "%S+") do n = n + 1 end
        secs = math.max(3, n / 2.6)
    end
    return secs
end

local function Finish()
    if A and IsValid(A.man) then A.man:Remove() end
    A = nil
end
LC.SpeechAnswerStop = Finish

-- Is the Combine in the camp right now?
local function CombineAt(pos)
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p) and p:GetPos():DistToSqr(pos) < 700 * 700 then return true end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.role == "cop" or st.role == "soldier") and npc:GetPos():DistToSqr(pos) < 700 * 700 then return true end
    end
    return false
end

-- He answers now (pieces: what she said, or nil). True, or false and why not.
function LC.SpeechAnswer(pieces)
    if A then return false, "He's already speaking." end
    if not cvOn:GetBool() then return false, "Off (lc_speech_answer 0)." end
    local spot, yaw
    if LC.ColonelSpot then spot, yaw = LC.ColonelSpot() end
    if not spot then return false, "There's no Resistance camp." end
    if CombineAt(spot) then return false, "The Combine are in the camp." end
    -- (beside where the ghost stands, not on him)
    local ang = math.rad((yaw or 0) + 90)
    local pos = spot + Vector(math.cos(ang) * 110, math.sin(ang) * 110, 0)
    local man = ents.Create("prop_dynamic")
    if IsValid(man) then
        man:SetModel(LC.CubbageModel)
        man:SetKeyValue("solid", "0")
        man:SetPos(pos)
        man:SetAngles(Angle(0, yaw or 0, 0))
        man:Spawn()
        man:SetNotSolid(true)
        local seq = man.SelectWeightedSequence and man:SelectWeightedSequence(ACT_IDLE or 1) or -1
        if seq and seq >= 0 and man.ResetSequence then man:ResetSequence(seq) end
        man.lcCubbage = true
    end
    A = { queue = LC.SpeechAnswerCompose(pieces), nextAt = CurTime() + 1, man = man, pos = pos }
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_faction", "") == "resistance" and LC.Notice then
            LC.Notice(p, "info", "Colonel Cubbage answers her", "He's speaking at the camp now, and on Freq 7.", 6)
        end
    end
    return true
end

function LC.SpeechAnswerThink(now)
    now = now or CurTime()
    if due and now >= due.at and not (LC.SpeechSession and LC.SpeechSession()) then
        local pieces = due.pieces
        due = nil
        LC.SpeechAnswer(pieces)
    end
    if A and now >= A.nextAt then
        if CombineAt(A.pos) then Finish() return end -- (the Combine walked in: he's gone)
        local line = table.remove(A.queue, 1)
        if not line then Finish() return end
        A.nextAt = now + Say(line) + 0.6
    end
end

-- Her address over: his answer is due. (The session is watched, not changed: sv_livingcity_speech.lua.)
local watched
hook.Add("LivingCitySpeechCalled", "LivingCitySpeechAnswer", function(_, session) watched = session end)
function LC.SpeechAnswerWatch(now)
    local s = LC.SpeechSession and LC.SpeechSession()
    if s then watched = s return end
    if watched then
        local spoke = watched.spoken ~= nil
        local pieces = watched.pieces
        watched = nil
        if spoke and cvOn:GetBool() then due = { at = (now or CurTime()) + cvDelay:GetFloat(), pieces = pieces } end
    end
end

timer.Create("LivingCitySpeechAnswer", 1, 0, function()
    local ok, err = pcall(function()
        LC.SpeechAnswerWatch(CurTime())
        LC.SpeechAnswerThink(CurTime())
    end)
    if not ok and LC.Error then LC.Error("speech answer", err) end
end)
