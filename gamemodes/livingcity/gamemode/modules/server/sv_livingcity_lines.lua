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
    garrysmod/sound/livingcity/units/: unit_move1.wav (where Half-Life 2 has the line already, its own clip is
    used and nothing needs recording). Without a recording the line is words only (never
    Half-Life 2's voice in its place), and once any are recorded the named citizens of that sex speak ONLY
    with their recorded voice (LC.OwnVoice, below).
    VOICE_LINES.md lists them all (python3 _dev/voice_lines.py); lc_voice_missing says which are not there yet.
]]

LC = LC or {}

-- id = { words, when it is said, the words as pasted into ElevenLabs (Eleven v4 or v3: a direction in square
-- brackets changes how what follows is said) }. Citizens: every id starts say_. American wording (the owner, 11 November).
LC.StreetLines = {
    say_open_listen = { "Listen.", "Opener: before something that matters", "[low, urgent] Listen." },
    say_open_look = { "Look.", "Opener: before a refusal or a plain truth", "[tired, flat] Look." },
    say_open_please = { "Please.", "Opener: before asking, or begging off", "[pleading, quietly] Please." },
    say_open_quiet = { "Keep your voice down.", "Opener: before anything dangerous to say", "[whispers, tense] Keep your voice down." },
    say_open_well = { "Well.", "Opener: thinking it over", "[thinking it over] Well..." },
    say_open_you = { "You.", "Opener: stopping someone", "[sharp, low] You." },
    say_greet_warm = { "Oh, it's you. Good to see a friendly face.", "Greeting someone they like", "[relieved, warm] Oh, it's you. Good to see a friendly face." },
    say_greet_plain = { "Hey. Still here, huh. Me too.", "Greeting anyone", "[tired, dry] Hey. Still here, huh. [exhales] Me too." },
    say_greet_guarded = { "Do I know you?", "Greeting a stranger they are wary of", "[wary, guarded] Do I know you?" },
    say_greet_cold = { "What do you want?", "Greeting someone they dislike", "[cold, flat] What do you want?" },
    say_greet_unit = { "No trouble here, officer.", "Spoken to by a unit", "[nervous, too polite] No trouble here, officer." },
    say_bye_warm = { "Take care of yourself. I mean it.", "Parting from someone they like", "[warm, quietly] Take care of yourself. [sincere] I mean it." },
    say_bye_plain = { "I should get going.", "Ending a conversation", "[flat, tired] I should get going." },
    say_bye_cold = { "We're done here.", "Ending a conversation they want no more of", "[cold, final] We're done here." },
    say_yes = { "Yeah. All right.", "Agreeing to something", "[plain, tired] Yeah. All right." },
    say_yes_warm = { "For you? Of course.", "Agreeing, for someone they like", "[warm, a small smile] For you? Of course." },
    say_no = { "No. Sorry.", "Refusing", "[flat, apologetic] No. Sorry." },
    say_no_hard = { "No. And don't ask me again.", "Refusing for good", "[firm, low] No. [pause] And don't ask me again." },
    say_maybe = { "Maybe. I'd have to think about it.", "Not sure", "[hesitant] Maybe. I'd have to think about it." },
    say_later = { "Not now. Not here.", "Putting it off: the wrong time or place", "[hushed, tense] Not now. Not here." },
    say_dunno = { "I wouldn't know anything about that.", "Asked something they don't know, or won't say", "[guarded, flat] I wouldn't know anything about that." },
    say_dunno_scared = { "I don't know, and I don't want to know.", "Asked something dangerous", "[frightened, quick] I don't know, and I don't want to know." },
    say_heard = { "I've heard things. Everyone has.", "Asked about a rumour", "[low, careful] I've heard things. [pause] Everyone has." },
    say_cant_say = { "I can't talk about that. You know why.", "Asked what can't be said aloud", "[hushed, uneasy] I can't talk about that. You know why." },
    say_ask_else = { "You're asking the wrong person.", "Asked for something they can't give", "[tired, dismissive] You're asking the wrong person." },
    say_truth = { "Honestly? It's as bad as it looks.", "Asked how things are, by someone they trust", "[quiet, grim] Honestly? [sighs] It's as bad as it looks." },
    say_state_fine = { "Getting by. That's all anyone can say.", "Asked how they are: all right", "[worn, matter of fact] Getting by. That's all anyone can say." },
    say_state_hungry = { "I haven't had a real meal in days.", "Asked how they are: hungry", "[weak, hollow] I haven't had a real meal in days." },
    say_state_tired = { "I'm tired. Just so tired.", "Asked how they are: worn out", "[exhausted] I'm tired. [sighs] Just so tired." },
    say_state_scared = { "I'm scared. Aren't you?", "Asked how they are: afraid", "[frightened, hushed] I'm scared. Aren't you?" },
    say_state_angry = { "I've had about all I can take.", "Asked how they are: close to breaking", "[tight, barely holding it in] I've had about all I can take." },
    say_state_lonely = { "It's good to just talk to someone.", "Asked how they are: starved of company", "[soft, grateful] It's good to just talk to someone." },
    say_state_hopeful = { "It can't last forever. Nothing does.", "Asked how they are: in good spirits", "[quiet, hopeful] It can't last forever. Nothing does." },
    say_state_low = { "What's the point? Really, what is the point?", "Asked how they are: in despair", "[hollow, defeated] What's the point? [pause] Really, what is the point?" },
    say_thanks = { "Thank you. I won't forget it.", "Thanked for a kindness", "[sincere, quietly] Thank you. I won't forget it." },
    say_thanks_big = { "You didn't have to do that. Thank you.", "A real kindness: food, medicine, help", "[moved, voice catching] You didn't have to do that. Thank you." },
    say_sorry = { "I'm sorry. I didn't mean anything by it.", "Backing down", "[nervous, backing down] I'm sorry. I didn't mean anything by it." },
    say_insulted = { "Hey. There's no need for that.", "Insulted", "[stung, stiff] Hey. There's no need for that." },
    say_threatened = { "I don't want any trouble.", "Threatened", "[frightened, hands up] I don't want any trouble." },
    say_laugh = { "Ha. That's the first laugh I've had all week.", "Something funny was said", "[short laugh] Ha. [warm, surprised] That's the first laugh I've had all week." },
    say_agree = { "You're not wrong.", "Agreeing with an opinion", "[dry, low] You're not wrong." },
    say_disagree = { "I don't see it that way.", "Disagreeing with an opinion", "[even, firm] I don't see it that way." },
    say_loyal = { "The Administrator knows best. I believe that.", "A loyal citizen, on the Combine", "[earnest, a little rehearsed] The Administrator knows best. I believe that." },
    say_loyal_warn = { "You shouldn't say things like that. Someone will hear.", "Hearing sedition, and not liking it", "[alarmed, hushed] You shouldn't say things like that. Someone will hear." },
    say_careful = { "Careful. The walls have ears.", "Warning someone who is talking too freely", "[whispers] Careful. The walls have ears." },
    say_units_near = { "Not with them standing right there.", "Won't talk with a unit close", "[under their breath] Not with them standing right there." },
    say_hate_quiet = { "One day they'll answer for all of it.", "A disloyal citizen, to someone they trust", "[low, bitter, controlled] One day they'll answer for all of it." },
    say_fear_units = { "Stay away from the units today. They're in a mood.", "A warning about Civil Protection", "[low, warning] Stay away from the units today. They're in a mood." },
    say_obey = { "Keep your head down and do what they say. That's how you make it.", "Advice to a newcomer", "[tired, kindly] Keep your head down and do what they say. That's how you make it." },
    say_res_deny = { "I don't know anything about any Resistance.", "Asked about the Resistance", "[quick, stiff, too careful] I don't know anything about any Resistance." },
    say_res_hint = { "There are people. That's all I'll say.", "A sympathizer, hinting to someone they trust", "[whispers, meaningful] There are people. [pause] That's all I'll say." },
    say_res_side = { "If someone needed a door left open, mine might be.", "A sympathizer, offering help", "[very quietly, steady] If someone needed a door left open, mine might be." },
    say_res_refuse = { "I've got people to think about. Leave me out of it.", "Asked to help the Resistance, and afraid", "[afraid, firm] I've got people to think about. Leave me out of it." },
    say_res_respect = { "Whoever they are, good luck to them.", "Quiet approval of the Resistance", "[quiet, a hint of a smile] Whoever they are, good luck to them." },
    say_warn_asked = { "Someone's been asking about you.", "A warning: they are being looked for", "[low, urgent] Someone's been asking about you." },
    say_warn_watched = { "You're being watched. Don't turn around.", "A warning: an informant or a unit has an eye on them", "[whispers, barely moving lips] You're being watched. Don't turn around." },
    say_warn_go = { "You should go. Now.", "A warning: get away", "[urgent, hushed] You should go. Now." },
    say_warn_informer = { "Watch who you talk to. Not everyone here is a friend.", "A warning about informants", "[low, careful] Watch who you talk to. Not everyone here is a friend." },
    say_tip_help = { "If you need something, ask. Quietly.", "Offering help", "[low, kind] If you need something, ask. [whispers] Quietly." },
    say_tip_trouble = { "There's gonna be trouble tonight. I can feel it.", "The city's mood is turning", "[uneasy, low] There's gonna be trouble tonight. I can feel it." },
    say_ask_food = { "You got anything to eat? Anything?", "Hungry, asking a player", "[weak, ashamed to ask] You got anything to eat? [pause] Anything?" },
    say_ask_smoke = { "You wouldn't have a smoke on you, would you?", "Craving, asking a player", "[edgy, hopeful] You wouldn't have a smoke on you, would you?" },
    say_ask_help = { "I need help. I've got nobody else to ask.", "In trouble, asking a player", "[desperate, quietly] I need help. I've got nobody else to ask." },
    say_offer = { "Here. Take it. Don't say where you got it.", "Giving something", "[hushed, quick] Here. Take it. Don't say where you got it." },
    say_decline_gift = { "I can't take that. Keep it.", "Refusing a gift", "[gentle, proud] I can't take that. Keep it." },
    say_break_tantrum = { "I've had enough! Do you hear me? Enough!", "A tantrum, in a unit's face", "[shouting, voice cracking] I've had enough! Do you hear me? Enough!" },
    say_break_despair = { "I can't. I just can't anymore.", "Despair", "[broken, near tears] I can't. [shaky breath] I just can't anymore." },
    say_break_defy = { "They can't scare all of us forever.", "Defiance: painting over a poster", "[quiet, defiant, steady] They can't scare all of us forever." },
    say_break_accuse = { "That one! That one talks to Civil Protection!", "Accusing someone of informing", "[loud, accusing, pointing] That one! That one talks to Civil Protection!" },
    say_break_accused = { "That's a lie! I never told them anything!", "Accused of informing", "[panicked, loud] That's a lie! I never told them anything!" },
    say_break_binge = { "Leave me alone. Just let me have this.", "Drinking in the street", "[slurred, tired, bitter] Leave me alone. Just let me have this." },
    say_break_seek = { "There you are. I've been looking for you.", "Finding a friend", "[relieved, a little shaky] There you are. I've been looking for you." },
    say_break_share = { "Go on, take half. You need it more than I do.", "Sharing food", "[gentle, insisting] Go on, take half. You need it more than I do." },
    say_break_steady = { "Easy. Easy now. We're still here, right?", "Steadying the people near", "[calm, soothing, low] Easy. Easy now. We're still here, right?" },
    say_break_inform = { "Officer. I've got something you'll want to hear.", "Informing to a unit", "[nervous, eager, hushed] Officer. I've got something you'll want to hear." },
    say_break_beaten = { "Stop! Please, I didn't do anything!", "Being beaten", "[crying out in pain, terrified] Stop! Please, I didn't do anything!" },
    say_saw_beating = { "Don't look. Just keep walking.", "Someone beaten in front of them", "[under their breath, tense] Don't look. Just keep walking." },
    say_saw_death = { "Oh God. Oh God, no.", "Someone killed in front of them", "[horrified, gasping] Oh God. Oh God, no." },
    say_grief = { "They took my friend. Just dragged them off.", "A friend arrested or dead", "[numb, grieving] They took my friend. [pause] Just dragged them off." },
}

-- A unit's lines: one voice. Every id starts unit_. A fourth entry names Half-Life 2's own Civil Protection
-- clips that say the same words (sound/npc/metropolice/vo/<name>.wav): with no recording of yours, the first
-- of them the server has is played, so those lines need no recording at all (the owner, 11 November: "already
-- exist in HL2").
LC.UnitLines = {
    unit_greet = { "Citizen.", "Spoken to", "[flat, clipped, cold] Citizen.", { "citizen" } },
    unit_greet_cp = { "Unit. Sector is quiet.", "Spoken to by another unit", "[flat, clipped] Unit. Sector is quiet." },
    unit_move = { "Move along.", "Wants them gone", "[curt, bored] Move along.", { "movealong", "movealong3", "keepmoving" } },
    unit_papers = { "Identification. Now.", "Suspicious of them", "[cold, commanding] Identification. Now." },
    unit_yes = { "Affirmative.", "Agreeing", "[flat] Affirmative.", { "affirmative", "affirmative2" } },
    unit_no = { "Negative.", "Refusing", "[flat] Negative.", { "negative" } },
    unit_dunno = { "That information is restricted.", "Asked anything he won't answer", "[flat, dismissive] That information is restricted." },
    unit_busy = { "Now get out of here.", "Ending it", "[curt] Now get out of here.", { "nowgetoutofhere", "getoutofhere" } },
    unit_curfew = { "Get indoors.", "Curfew, a lockdown or a sweep", "[sharp, commanding] Get indoors." },
    unit_warn = { "Final warning.", "Pushed too far", "[cold, slow, threatening] Final warning.", { "finalwarning" } },
    unit_threat = { "Hold it right there.", "Threatened or crowded", "[hard, loud] Hold it right there.", { "holditrightthere", "holdit" } },
    unit_insulted = { "Looking for trouble?", "Insulted", "[low, dangerous] Looking for trouble?", { "lookingfortrouble" } },
    unit_noted = { "Noted. It will go on your record.", "Heard something he will report", "[flat, ominous] Noted. It will go on your record." },
    unit_thanks = { "Your cooperation is noted.", "Told something useful, or obeyed", "[flat, faintly approving] Your cooperation is noted." },
    unit_soft = { "Keep your head down today. That is advice.", "A unit with some kindness in him, to someone he doesn't mind", "[low, off the record] Keep your head down today. [pause] That is advice." },
    unit_brutal = { "You want some too?", "Brutality: to whoever is watching", "[breathing hard, vicious] You want some too?" },
    unit_drink = { "You saw nothing.", "Caught drinking on duty", "[low, threatening, slightly slurred] You saw nothing." },
}

LC.UnitVoiceRoot = "livingcity/units/"

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

-- Half-Life 2's own clip for a unit's line, if the server has one of those named for it.
local STOCK_ROOT = "npc/metropolice/vo/"
local stockHas = {}
function LC.UnitLineStock(id)
    local l = LC.UnitLines[id]
    for _, name in ipairs(l and l[4] or {}) do
        if stockHas[name] == nil then stockHas[name] = file.Exists("sound/" .. STOCK_ROOT .. name .. ".wav", "GAME") == true end
        if stockHas[name] then return STOCK_ROOT .. name .. ".wav" end
    end
    return nil
end
function LC.UnitLinesForgetStock() stockHas = {} end

-- Your recording of it; else Half-Life 2's own, where it has one.
function LC.UnitLineClip(id, ownOnly)
    if not unitClips then ScanUnits() end
    local t = unitClips[id]
    if t then return t[math.random(#t)] end
    if ownOnly then return nil end
    return LC.UnitLineStock(id)
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
    return 0 -- (not recorded yet: the words only, never Half-Life 2's voice in its place)
end

-- One voice for each named person (the owner, 11 November). Once any of the bank is recorded for men (or for
-- women), the city's NAMED citizens of that sex stop speaking with Half-Life 2's citizen voice wherever the
-- gamemode chooses the sound (street chatter, the talk window, protests, under words the model wrote): the
-- words still show, and their recorded lines are their only voice. Unnamed citizens keep Half-Life 2's.
function LC.OwnVoice(npc, st)
    if not IsValid(npc) or not st or st.role ~= "citizen" then return false end
    local p = npc.lcProfile
    if not p or not p.name then return false end
    return LC.AdviceHasAny ~= nil and LC.AdviceHasAny("say_", st.gender) == true
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
    for id in pairs(LC.UnitLines) do if not LC.UnitLineClip(id) then unit[#unit + 1] = id end end -- (Half-Life 2's own clip counts)
    table.sort(cit) table.sort(unit)
    return cit, unit
end

-- What Half-Life 2 already has (the owner, 11 November: "please double check if there are others"): lc_hl2_lines,
-- in the server console, writes data/livingcity/hl2_lines.txt: every clip of Half-Life 2's citizens (a man's and
-- a woman's) and of Civil Protection that the server can see, with its words where the game's caption file gives
-- them. Bring the file back and the bank can be matched to real clips for certain, instead of from memory.
function LC.HL2LinesDump()
    local out, n = {}, 0
    local words = {}
    for _, cc in ipairs({ "resource/closecaption_english.txt", "resource/subtitles_english.txt" }) do
        local raw = file.Read(cc, "GAME")
        if raw then
            raw = string.gsub(raw, "%z", "") -- (the file is two bytes a letter: drop the empty ones)
            for token, text in string.gmatch(raw, '"([%w_%.]+)"%s+"([^"\r\n]*)"') do
                local key = string.lower(token)
                if words[key] == nil then words[key] = (string.gsub(text, "<[^>]*>", "")) end
            end
        end
    end
    local function Folder(title, path, tokens)
        out[#out + 1] = "## " .. title .. " (sound/" .. path .. ")"
        local files = file.Find("sound/" .. path .. "*.wav", "GAME") or {}
        table.sort(files)
        for _, f in ipairs(files) do
            local base = string.lower(string.gsub(f, "%.wav$", ""))
            local text
            for _, pre in ipairs(tokens) do text = text or words[pre .. base] end
            out[#out + 1] = f .. "\t" .. (text or "")
            n = n + 1
        end
        out[#out + 1] = ""
    end
    Folder("A citizen, a man", "vo/npc/male01/", { "npc_citizen.", "citizen." })
    Folder("A citizen, a woman", "vo/npc/female01/", { "npc_citizen.", "citizen." })
    Folder("Civil Protection", "npc/metropolice/vo/", { "npc_metropolice.", "metropolice." })
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write("livingcity/hl2_lines.txt", table.concat(out, "\n"))
    return n
end
concommand.Add("lc_hl2_lines", function(ply)
    if IsValid(ply) and not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local ok, n = pcall(LC.HL2LinesDump)
    local msg = ok and ("wrote data/livingcity/hl2_lines.txt: " .. tostring(n) .. " clips. Bring it back to Claude.") or ("could not list them: " .. tostring(n))
    if IsValid(ply) then ply:ChatPrint("[Living City] " .. msg) else print("[Living City] " .. msg) end
end)
