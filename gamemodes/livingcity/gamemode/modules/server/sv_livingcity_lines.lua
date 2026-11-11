--[[
    Living City: what named people say, recorded (the owner, 11 November: "architect and design natural
    sounding lines so that we can pre record NPC lines and cover as much situational dialogs as possible
    with the least amount of lines")

    A small bank of lines, written to be recorded once and reused everywhere:

      by what the line DOES, not what it is about: a greeting, a refusal, "I don't know", a warning, a
      thanks. "I wouldn't know anything about that." answers a thousand questions.
      nobody's name, job, the time of day or a place in any of them, so any citizen can say any line
      short (a breath or two), so two can be said together: an opener ("Listen.") and then the line
      the same few feelings throughout: warm, plain, guarded, cold

    Who uses them:
      free talk (sv_livingcity_brain.lua): the hosted model is shown the bank and picks the line that
        says what the person would say; it only writes words of its own when none fits (lc_brain_lines)
      the director's approach: the citizen who walks up to a player opens with one
      the minds' breaks (sv_livingcity_mindsact.lua): what they shout, plead or mutter as it happens

    Recordings: a citizen's lines want a man's take and a woman's, in the folder the advice lines already
    use, garrysmod/sound/livingcity/citizens/: say_greet_warm_male1.wav, say_greet_warm_female1.wav (more
    takes ...2, ...3; one is picked at random). A unit's lines are one voice, in
    garrysmod/sound/livingcity/units/: unit_move1.wav. Without a recording a citizen speaks with
    Half-Life 2's own citizen voice, a unit is silent, and the words still show.
    VOICE_LINES.md lists them all (python3 _dev/voice_lines.py); lc_voice_missing says which are not there yet.
]]

LC = LC or {}

-- id = { words, when it is said }. Citizens: every id starts say_.
LC.StreetLines = {
    -- openers: said before another line
    say_open_listen   = { "Listen.", "Opener: before something that matters" },
    say_open_look     = { "Look.", "Opener: before a refusal or a plain truth" },
    say_open_please   = { "Please.", "Opener: before asking, or begging off" },
    say_open_quiet    = { "Keep your voice down.", "Opener: before anything dangerous to say" },
    say_open_well     = { "Well.", "Opener: thinking it over" },
    say_open_you      = { "You.", "Opener: stopping someone" },
    -- hello and goodbye
    say_greet_warm    = { "Oh, it's you. Good to see a friendly face.", "Greeting someone they like" },
    say_greet_plain   = { "Hello. Still here, then. Same as me.", "Greeting anyone" },
    say_greet_guarded = { "Do I know you?", "Greeting a stranger they are wary of" },
    say_greet_cold    = { "What do you want?", "Greeting someone they dislike" },
    say_greet_unit    = { "No trouble here, officer.", "Spoken to by a unit" },
    say_bye_warm      = { "Look after yourself. I mean it.", "Parting from someone they like" },
    say_bye_plain     = { "I'd best get on.", "Ending a conversation" },
    say_bye_cold      = { "We're done here.", "Ending a conversation they want no more of" },
    -- yes, no, perhaps
    say_yes           = { "Yes. All right.", "Agreeing to something" },
    say_yes_warm      = { "For you? Of course.", "Agreeing, for someone they like" },
    say_no            = { "No. Sorry.", "Refusing" },
    say_no_hard       = { "No. And don't ask me again.", "Refusing for good" },
    say_maybe         = { "Maybe. I'd have to think about it.", "Not sure" },
    say_later         = { "Not now. Not here.", "Putting it off: the wrong time or place" },
    -- what they know
    say_dunno         = { "I wouldn't know anything about that.", "Asked something they don't know, or won't say" },
    say_dunno_scared  = { "I don't know, and I don't want to know.", "Asked something dangerous" },
    say_heard         = { "I've heard things. Everyone has.", "Asked about a rumour" },
    say_cant_say      = { "I can't talk about that. You know why.", "Asked what can't be said aloud" },
    say_ask_else      = { "You're asking the wrong person.", "Asked for something they can't give" },
    say_truth         = { "Honestly? It's as bad as it looks.", "Asked how things are, by someone they trust" },
    -- how they are
    say_state_fine    = { "Getting by. That's all anyone can say.", "Asked how they are: all right" },
    say_state_hungry  = { "I haven't eaten properly in days.", "Asked how they are: hungry" },
    say_state_tired   = { "I'm tired. Bone tired.", "Asked how they are: worn out" },
    say_state_scared  = { "I'm frightened. Aren't you?", "Asked how they are: afraid" },
    say_state_angry   = { "I've had about as much as I can take.", "Asked how they are: close to breaking" },
    say_state_lonely  = { "It's good to just talk to someone.", "Asked how they are: starved of company" },
    say_state_hopeful = { "It can't last for ever. Nothing does.", "Asked how they are: in good spirits" },
    say_state_low     = { "What's the point? Really, what is the point?", "Asked how they are: in despair" },
    -- answering how they were spoken to
    say_thanks        = { "Thank you. I won't forget it.", "Thanked for a kindness" },
    say_thanks_big    = { "You didn't have to do that. Thank you.", "A real kindness: food, medicine, help" },
    say_sorry         = { "I'm sorry. I didn't mean anything by it.", "Backing down" },
    say_insulted      = { "There's no call for that.", "Insulted" },
    say_threatened    = { "I don't want any trouble.", "Threatened" },
    say_laugh         = { "Ha. That's the first laugh I've had all week.", "Something funny was said" },
    say_agree         = { "You're not wrong.", "Agreeing with an opinion" },
    say_disagree      = { "I don't see it that way.", "Disagreeing with an opinion" },
    -- the Combine
    say_loyal         = { "The Administrator knows best. I believe that.", "A loyal citizen, on the Combine" },
    say_loyal_warn    = { "You shouldn't say things like that. Someone will hear.", "Hearing sedition, and not liking it" },
    say_careful       = { "Careful. The walls have ears.", "Warning someone who is talking too freely" },
    say_units_near    = { "Not with them standing there.", "Won't talk with a unit close" },
    say_hate_quiet    = { "One day they'll answer for all of it.", "A disloyal citizen, to someone they trust" },
    say_fear_units    = { "Stay clear of the units today. They're in a mood.", "A warning about Civil Protection" },
    say_obey          = { "Keep your head down and do as they say. That's how you last.", "Advice to a newcomer" },
    -- the Resistance
    say_res_deny      = { "I don't know anything about any Resistance.", "Asked about the Resistance" },
    say_res_hint      = { "There are people. That's all I'll say.", "A sympathizer, hinting to someone they trust" },
    say_res_side      = { "If someone needed a door left open, mine might be.", "A sympathizer, offering help" },
    say_res_refuse    = { "I've people to think of. Leave me out of it.", "Asked to help the Resistance, and afraid" },
    say_res_respect   = { "Whoever they are, good luck to them.", "Quiet approval of the Resistance" },
    -- warnings and tips
    say_warn_asked    = { "Someone's been asking about you.", "A warning: they are being looked for" },
    say_warn_watched  = { "You're being watched. Don't look round.", "A warning: an informant or a unit has an eye on them" },
    say_warn_go       = { "You should go. Now.", "A warning: get away" },
    say_warn_informer = { "Mind who you talk to. Not everyone here is a friend.", "A warning about informants" },
    say_tip_help      = { "If you need something, ask. Quietly.", "Offering help" },
    say_tip_trouble   = { "There'll be trouble tonight. I can feel it.", "The city's mood is turning" },
    -- asking and giving
    say_ask_food      = { "You wouldn't have anything to eat, would you?", "Hungry, asking a player" },
    say_ask_smoke     = { "You haven't got a smoke, have you?", "Craving, asking a player" },
    say_ask_help      = { "I need help. I've nobody else to ask.", "In trouble, asking a player" },
    say_offer         = { "Here. Take it. Don't say where you got it.", "Giving something" },
    say_decline_gift  = { "I can't take that. Keep it.", "Refusing a gift" },
    -- as a mind gives way (sv_livingcity_mindsact.lua)
    say_break_tantrum = { "I've had enough! Do you hear me? Enough!", "A tantrum, in a unit's face" },
    say_break_despair = { "I can't. I just can't any more.", "Despair" },
    say_break_defy    = { "They can't frighten all of us for ever.", "Defiance: painting over a poster" },
    say_break_accuse  = { "That one. That one talks to Civil Protection!", "Accusing someone of informing" },
    say_break_accused = { "It's a lie! I never told them anything!", "Accused of informing" },
    say_break_binge   = { "Leave me be. Let me have this.", "Drinking in the street" },
    say_break_seek    = { "There you are. I've been looking for you.", "Finding a friend" },
    say_break_share   = { "Go on, take half. You need it more than I do.", "Sharing food" },
    say_break_steady  = { "Easy. Easy now. We're still here, aren't we?", "Steadying the people near" },
    say_break_inform  = { "Officer. I've something you'll want to hear.", "Informing to a unit" },
    say_break_beaten  = { "Stop! Please, I've done nothing!", "Being beaten" },
    -- what they saw
    say_saw_beating   = { "Don't look. Just keep walking.", "Someone beaten in front of them" },
    say_saw_death     = { "Oh God. Oh God, no.", "Someone killed in front of them" },
    say_grief         = { "They took my friend. Just took them.", "A friend arrested or dead" },
}

-- A unit's lines: one voice. Every id starts unit_.
LC.UnitLines = {
    unit_greet    = { "Citizen.", "Spoken to" },
    unit_greet_cp = { "Unit. Sector is quiet.", "Spoken to by another unit" },
    unit_move     = { "Move along.", "Wants them gone" },
    unit_papers   = { "Identification. Now.", "Suspicious of them" },
    unit_yes      = { "Affirmative.", "Agreeing" },
    unit_no       = { "Negative.", "Refusing" },
    unit_dunno    = { "That information is restricted.", "Asked anything he won't answer" },
    unit_busy     = { "Not now. Return to your duties.", "Ending it" },
    unit_curfew   = { "Get indoors.", "Curfew, a lockdown or a sweep" },
    unit_warn     = { "Final warning, citizen.", "Pushed too far" },
    unit_threat   = { "Step back, or be pacified.", "Threatened or crowded" },
    unit_insulted = { "Watch your mouth.", "Insulted" },
    unit_noted    = { "Noted. It will go on your record.", "Heard something he will report" },
    unit_thanks   = { "Your cooperation is noted.", "Told something useful, or obeyed" },
    unit_soft     = { "Keep your head down today. That is advice.", "A unit with some kindness in him, to someone he doesn't mind" },
    unit_brutal   = { "You want some as well?", "Brutality: to whoever is watching" },
    unit_drink    = { "You saw nothing.", "Caught drinking on duty" },
}

LC.UnitVoiceRoot = "livingcity/units/"

-- Half-Life 2's own citizen voice, where there is no recording (else an "answer" line)
local HL2 = { say_break_tantrum = "no02", say_break_accused = "no01", say_break_beaten = "no01", say_no = "no01", say_no_hard = "no02",
    say_sorry = "sorry01", say_yes = "ok01", say_yes_warm = "ok02", say_saw_death = "gordead_ques01", say_greet_plain = "hi01", say_greet_warm = "hi02" }

local AUDIO = { wav = true, mp3 = true, ogg = true }
local unitClips
local function ScanUnits()
    unitClips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.UnitVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            unitClips[base] = unitClips[base] or {}
            table.insert(unitClips[base], LC.UnitVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.UnitVoiceRoot .. n) end
        end
    end
    return unitClips
end
LC.UnitLinesRescan = ScanUnits
hook.Add("Initialize", "LivingCityUnitLines", ScanUnits)

function LC.UnitLineClip(id)
    if not unitClips then ScanUnits() end
    local t = unitClips[id]
    return t and t[math.random(#t)] or nil
end

local function Bank(role) return role == "cop" and LC.UnitLines or LC.StreetLines end

-- Is this a line this kind of person has? opener: only an opener counts.
function LC.LineValid(role, id, opener)
    if type(id) ~= "string" or id == "" then return false end
    if not Bank(role)[id] then return false end
    local isOpener = string.sub(id, 1, 9) == "say_open_"
    if opener then return isOpener end
    return not isOpener
end

function LC.LineWords(role, id, lead)
    local l = Bank(role)[id]
    if not l then return "" end
    local o = lead and LC.StreetLines[lead]
    return (o and (o[1] .. " ") or "") .. l[1]
end

-- The ids a kind of person has, in order: for the model's list. openers: only those, or (false) none of them.
function LC.LineIds(role, openers)
    local out = {}
    for id in pairs(Bank(role)) do
        local isOpener = string.sub(id, 1, 9) == "say_open_"
        if (openers and isOpener) or (not openers and not isOpener) then out[#out + 1] = id end
    end
    table.sort(out)
    return out
end

-- The bank as the model reads it: "id: words (when)".
function LC.LineList(role, only)
    local out = {}
    for _, id in ipairs(LC.LineIds(role, false)) do
        if not only or only(id) then
            local l = Bank(role)[id]
            out[#out + 1] = id .. ": " .. l[1] .. " (" .. l[2] .. ")"
        end
    end
    return table.concat(out, "\n")
end

local function Clip(st, id)
    if st.role == "cop" then return LC.UnitLineClip(id) end
    return LC.AdviceClip and LC.AdviceClip(id, st.gender) or nil
end

local function Emit(npc, st, id)
    local clip = Clip(st, id)
    if clip then
        npc:EmitSound(clip, 72)
        return (LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(clip)) or 0
    end
    if st.role ~= "cop" then
        local vo = HL2[id] or string.format("answer%02d", math.random(1, 20))
        npc:EmitSound("vo/npc/" .. (st.gender == "female" and "female01" or "male01") .. "/" .. vo .. ".wav", 68)
    end
    return 0
end

-- They say it out loud (the sound only: whoever calls shows the words). lead: an opener first.
-- Returns the words.
function LC.LineSay(npc, st, id, lead)
    if not IsValid(npc) or not st or not Bank(st.role)[id] then return "" end
    if lead and st.role ~= "cop" and LC.StreetLines[lead] then
        local secs = Emit(npc, st, lead)
        timer.Simple((secs > 0 and secs or 0.8) + 0.15, function()
            if IsValid(npc) and npc:Health() > 0 then Emit(npc, st, id) end
        end)
    else
        lead = nil
        Emit(npc, st, id)
    end
    return LC.LineWords(st.role, id, lead)
end

-- For lc_voice_missing (sv_livingcity_announcer.lua): the recordings not there yet.
function LC.LinesMissing()
    local cit, unit = {}, {}
    if LC.AdviceRescan then LC.AdviceRescan() end
    for id in pairs(LC.StreetLines) do
        for _, gen in ipairs({ "male", "female" }) do
            if not (LC.AdviceClip and LC.AdviceClip(id, gen)) then cit[#cit + 1] = id .. "_" .. gen end
        end
    end
    ScanUnits()
    for id in pairs(LC.UnitLines) do if not LC.UnitLineClip(id) then unit[#unit + 1] = id end end
    table.sort(cit) table.sort(unit)
    return cit, unit
end
