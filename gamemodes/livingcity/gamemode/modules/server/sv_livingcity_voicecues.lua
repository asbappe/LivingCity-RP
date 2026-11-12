--[[
    Living City: named citizens say their recorded lines at the moments that fit, without the director
    (the owner, 12 November: "can we wire up all these voices now please? make the triggers?").

    The bank (sv_livingcity_lines.lua) was only used by the hosted model (free talk, the director's
    approach) and the minds' breaks. Without a key, 68 of its 79 lines were never heard. This module says
    them where the game already knows what is going on:

      the talk window (sv_livingcity_talk.lua): a greeting by how they feel about you, how they are,
        a rumour's lead-in, thanks for what you give them or a refusal, a pickpocket caught, yes or no
        to the Resistance's lookout offer, and goodbye when you walk off
      the street (sv_livingcity.lua): two citizens chatting say real lines to each other (how they are,
        the Combine, the Resistance, and an answer that fits who they are); stopped or frisked by a unit;
        protesting an arrest; panic; gunfire (sv_livingcity_streetlife.lua)
      what they see (sv_livingcity_psyche.lua, the "LivingCityThought" hook): a beating, a death, a friend
        taken away; a poster defaced
      being hurt by a player
      what a player says near them in chat (only while the director has no key): hello, goodbye, how
        are you, a joke, an insult, a threat, the Resistance, the Combine, asking for help or food
      now and then one walks up to a player: a warning (wanted, an informer near, a unit watching,
        trouble in the city), asking for food, a smoke or help, or a small gift (lc_voice_approach)

    In the places where Half-Life 2's voice already plays for everyone (street chatter, the talk window),
    only the named citizens with the recorded voice say a line (LC.OwnVoice): the others go on with
    Half-Life 2's as before. Where nothing played before (what they see, chat, being hurt, walking up to
    you), everyone named speaks: someone with Half-Life 2's voice says its own line in place of the
    recorded one (LC.HL2Instead), or nothing where it has nothing like it.

    lc_voice_cues 0 turns all of this off. lc_voice_approach: seconds between walk-ups to the same
    player (0: never). lc_voice_cue_words: the words of a line said to you show in chat.
]]

LC = LC or {}

local FLAGS = FCVAR_ARCHIVE
local cvOn = CreateConVar("lc_voice_cues", "1", FLAGS, "Named citizens say their recorded lines at the moments that fit, without the director (0: only the director and the breaks use them)")
local cvApproach = CreateConVar("lc_voice_approach", "300", FLAGS, "Seconds between a named citizen walking up to the same player to warn, ask or give something (0: never)")
local cvWords = CreateConVar("lc_voice_cue_words", "1", FLAGS, "Show the words of a recorded line said to you in chat (0: the sound only)")

local GAP = 6          -- seconds between two lines from the same person
local HEAR = 800       -- how near a player must be for a line to be worth saying
local AFRAID, WARM = -3, 3

local function Pick(t) return t[math.random(#t)] end
local function Chance(p) return math.random() < p end

local function Named(npc, st)
    return IsValid(npc) and st and st.role == "citizen" and npc.lcProfile and npc.lcProfile.name and npc:Health() > 0
end

local function MindOf(npc)
    local p = IsValid(npc) and npc.lcProfile
    if not p or not LC.Psy or not LC.MindOf then return nil end
    return LC.MindOf(p)
end

-- Who they are (traits from -1 to 1) and how they are (needs from 0 to 1, stress, mood). Never nil.
local NOTRAITS = { brave = 0, temper = 0, loyal = 0, social = 0, hope = 0, greed = 0, compassion = 0, suspicion = 0, resilience = 0, pride = 0, vice = 0 }
local function Traits(npc, st)
    local m = MindOf(npc)
    local t = m and LC.Psy.Traits(m) or NOTRAITS
    if st and st.rebel and t.loyal > -0.3 then
        local c = {}
        for k, v in pairs(t) do c[k] = v end
        c.loyal = -0.5
        t = c
    end
    return t
end
local function Needs(npc)
    local m = MindOf(npc)
    local s = m and m.psy
    if not s then return { food = 0.8, rest = 0.8, company = 0.7, crave = 0, stress = 0, mood = 0 } end
    return { food = s.food or 0.8, rest = s.rest or 0.8, company = s.company or 0.7, crave = s.crave or 0, stress = s.stress or 0, mood = s.mood or 0 }
end
LC.CueTraits, LC.CueNeeds = Traits, Needs

local function Feeling(npc, ply)
    if not (IsValid(ply) and ply:IsPlayer() and LC.Feeling) then return 0 end
    return LC.Feeling(npc, ply) or 0
end

local function UnitNear(pos, r)
    for npc, st in pairs(LC.NPCs or {}) do
        if st.role == "cop" and IsValid(npc) and npc:GetPos():DistToSqr(pos) < r * r then return true end
    end
    for _, ply in ipairs(player.GetAll()) do
        if LC.PlayerIsCP and LC.PlayerIsCP(ply) and ply:GetPos():DistToSqr(pos) < r * r then return true end
    end
    return false
end

local function PlayerNear(pos, r)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetPos():DistToSqr(pos) < r * r then return true end
    end
    return false
end

local function ChatRange()
    local cv = GetConVar("lc_chat_range")
    return (cv and cv:GetFloat() > 0) and cv:GetFloat() or 350
end

local function Show(npc, words, to)
    if not cvWords:GetBool() then return end
    local name = npc.lcProfile and npc.lcProfile.name or "Someone"
    local text = name .. " says: \"" .. words .. "\""
    if to == "near" then
        local r = ChatRange()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(npc:GetPos()) < r * r then ply:ChatPrint(text) end
        end
    elseif IsValid(to) then
        to:ChatPrint(text)
    end
end

-- The opener that suits a line, said first now and then.
local LEAD = {
    say_no = "say_open_look", say_no_hard = "say_open_look", say_disagree = "say_open_look", say_truth = "say_open_look", say_ask_else = "say_open_look",
    say_maybe = "say_open_well", say_heard = "say_open_well", say_state_fine = "say_open_well", say_agree = "say_open_well",
    say_ask_food = "say_open_please", say_ask_help = "say_open_please", say_ask_smoke = "say_open_please", say_threatened = "say_open_please", say_later = "say_open_please",
    say_careful = "say_open_quiet", say_res_hint = "say_open_quiet", say_res_side = "say_open_quiet", say_hate_quiet = "say_open_quiet", say_cant_say = "say_open_quiet", say_units_near = "say_open_quiet",
    say_warn_asked = "say_open_listen", say_warn_go = "say_open_listen", say_warn_informer = "say_open_listen", say_tip_trouble = "say_open_listen", say_tip_help = "say_open_listen",
    say_warn_watched = "say_open_you", say_offer = "say_open_you",
}
LC.CueLeads = LEAD

--[[
    LC.Cue(npc, st, id, o): a named citizen says a line of the bank, if it fits who they are. Returns the
    words said (and the id), or nil. id: an id, a list to pick from, or a function(npc, st) giving one.
    o.all: everyone named speaks (Half-Life 2's own line in place of the recorded one), not only those
    with the recorded voice. o.lead: an opener (or false: none); left out, the line's usual opener now
    and then. o.to: a player, or "near", who sees the words in chat. o.force: even if they just spoke.
]]
function LC.Cue(npc, st, id, o)
    o = o or {}
    if not cvOn:GetBool() or not Named(npc, st) then return nil end
    if not o.all and not (LC.OwnVoice and LC.OwnVoice(npc, st)) then return nil end
    local now = CurTime()
    if not o.force and (npc.lcCueAt or -1e9) > now - GAP then return nil end
    if type(id) == "function" then id = id(npc, st) end
    if type(id) == "table" then id = #id > 0 and Pick(id) or nil end
    if not id or not LC.StreetLines or not LC.StreetLines[id] then return nil end
    local lead = o.lead
    if lead == nil and LEAD[id] and Chance(0.35) then lead = LEAD[id] end
    if lead == false then lead = nil end
    local words = LC.LineSay(npc, st, id, lead)
    if not words or words == "" then return nil end
    npc.lcCueAt = now
    st.lcCueLast, st.lcCueLastAt = id, now
    if o.to then Show(npc, words, o.to) end
    return words, id
end

------------------------------------------------------------------------
-- Choosing the line
------------------------------------------------------------------------

-- How they are, from their needs and mood.
function LC.CueState(npc, st)
    local s, t = Needs(npc), Traits(npc, st)
    local frayed = (LC.Psy and LC.Psy.cfg and LC.Psy.cfg.frayed) or 10
    if s.stress >= 20 then return t.temper > 0 and "say_state_angry" or "say_state_scared" end
    if s.food < 0.3 then return "say_state_hungry" end
    if s.mood < -3 and t.hope < 0 then return "say_state_low" end
    if s.stress >= frayed then return t.brave < 0 and "say_state_scared" or "say_state_angry" end
    if s.rest < 0.3 then return "say_state_tired" end
    if s.company < 0.3 and t.social > -0.2 then return "say_state_lonely" end
    if s.mood > 3 or t.hope > 0.5 then return "say_state_hopeful" end
    if s.mood < -3 then return "say_state_low" end
    return "say_state_fine"
end

-- What's on their mind, said to someone they don't fear: the Combine, the Resistance, or how they are.
function LC.CueTopic(npc, st, trusted)
    local t = Traits(npc, st)
    if UnitNear(npc:GetPos(), 500) and (t.loyal < 0 or st.rebel) then return "say_units_near" end
    local pool = { LC.CueState(npc, st), LC.CueState(npc, st) }
    if t.loyal > 0.4 then pool[#pool + 1] = "say_loyal" pool[#pool + 1] = "say_obey"
    elseif t.loyal < -0.4 then
        if trusted and t.brave > 0 then pool[#pool + 1] = "say_hate_quiet" end
        if trusted then pool[#pool + 1] = "say_res_respect" end
        pool[#pool + 1] = "say_careful"
    end
    if t.brave < -0.3 then pool[#pool + 1] = "say_fear_units" pool[#pool + 1] = "say_obey" end
    if LC.Socio == "red" or LC.Socio == "black" or LC.Socio == "yellow" then pool[#pool + 1] = "say_tip_trouble" end
    return Pick(pool)
end

-- An answer to what someone near just said, from who the one answering is.
function LC.CueAnswer(npc, st, heard)
    local t = Traits(npc, st)
    if heard == "say_loyal" or heard == "say_obey" then
        if t.loyal > 0.2 then return "say_agree" end
        if t.loyal < -0.3 then return t.brave > 0 and "say_disagree" or "say_careful" end
        return "say_yes"
    elseif heard == "say_hate_quiet" or heard == "say_res_respect" then
        if t.loyal > 0.3 then return "say_loyal_warn" end
        if t.brave < -0.3 then return "say_careful" end
        return "say_agree"
    elseif heard == "say_careful" or heard == "say_fear_units" or heard == "say_units_near" or heard == "say_tip_trouble" then
        return Pick({ "say_agree", "say_heard" })
    elseif heard == "say_state_hopeful" then
        return t.hope < -0.2 and "say_disagree" or "say_agree"
    elseif heard and string.sub(heard, 1, 10) == "say_state_" then
        if t.hope > 0.4 then return "say_state_hopeful" end
        return Pick({ "say_agree", "say_truth", LC.CueState(npc, st) })
    end
    return Pick({ "say_agree", "say_heard", LC.CueState(npc, st) })
end

-- Hello and goodbye, by how they feel about you.
function LC.CueGreeting(npc, st, ply)
    if IsValid(ply) and LC.PlayerIsCP and LC.PlayerIsCP(ply) then return "say_greet_unit" end
    local feel = Feeling(npc, ply)
    if feel <= -6 then return "say_greet_cold" end
    if feel <= AFRAID then return "say_greet_guarded" end
    if feel >= WARM then return "say_greet_warm" end
    if Traits(npc, st).suspicion > 0.5 and not (npc.lcProfile.memory and next(npc.lcProfile.memory)) then return "say_greet_guarded" end
    return "say_greet_plain"
end
function LC.CueGoodbye(npc, st, ply)
    local feel = Feeling(npc, ply)
    if feel <= AFRAID then return "say_bye_cold" end
    if feel >= WARM then return "say_bye_warm" end
    return "say_bye_plain"
end

------------------------------------------------------------------------
-- The talk window (sv_livingcity_talk.lua calls these)
------------------------------------------------------------------------

-- Opening the window: hello. Remembered, for goodbye when you walk off.
function LC.CueTalkOpen(ply, npc, st)
    if not IsValid(ply) then return nil end
    ply.lcCueTalk = { npc = npc, at = CurTime() }
    if (npc.lcCueGreeted or {})[ply] and npc.lcCueGreeted[ply] > CurTime() - 120 then return nil end
    local w = LC.Cue(npc, st, LC.CueGreeting(npc, st, ply))
    if w then
        npc.lcCueGreeted = npc.lcCueGreeted or {}
        npc.lcCueGreeted[ply] = CurTime()
    end
    return w
end

-- Chat in the window. what: "afraid", "rumour", "chronicle", "hint" or "small". Returns the words, or nil.
function LC.CueTalkChat(ply, npc, st, what)
    if IsValid(ply) then ply.lcCueTalk = { npc = npc, at = CurTime() } end
    local feel = Feeling(npc, ply)
    if what == "afraid" then return LC.Cue(npc, st, Traits(npc, st).brave < 0 and "say_threatened" or "say_dunno_scared", { force = true }) end
    if what == "rumour" or what == "chronicle" then return LC.Cue(npc, st, "say_heard", { force = true, lead = feel >= WARM and "say_open_listen" or nil }) end
    if what == "hint" then return LC.Cue(npc, st, "say_res_hint", { force = true, lead = "say_open_quiet" }) end
    local id
    if feel >= WARM and Chance(0.25) then id = "say_truth"
    elseif feel < 0 and Chance(0.3) then id = "say_ask_else"
    else id = LC.CueTopic(npc, st, feel >= WARM) end
    return LC.Cue(npc, st, id, { force = true })
end

-- Recruited as a lookout for the Resistance: yes, or no in their own way.
function LC.CueRecruit(ply, npc, st, ok)
    local feel, t = Feeling(npc, ply), Traits(npc, st)
    if ok then return LC.Cue(npc, st, feel >= 6 and "say_yes_warm" or "say_yes", { force = true }) end
    if UnitNear(npc:GetPos(), 600) then return LC.Cue(npc, st, "say_later", { force = true }) end
    if t.loyal > 0.2 then return LC.Cue(npc, st, "say_no_hard", { force = true }) end
    if t.brave < -0.2 then return LC.Cue(npc, st, "say_res_refuse", { force = true }) end
    return LC.Cue(npc, st, feel > 0 and "say_maybe" or "say_no", { force = true })
end

------------------------------------------------------------------------
-- What they see (the "LivingCityThought" hook, from sv_livingcity_psyche.lua)
------------------------------------------------------------------------

local SEEN = {
    saw_beating = function(npc, st) return "say_saw_beating" end,
    friend_beaten = function(npc, st) local t = Traits(npc, st) return (t.brave > 0.3 and t.loyal < 0) and "say_hate_quiet" or "say_saw_beating" end,
    saw_death = function() return "say_saw_death" end,
    friend_died = function() return "say_saw_death" end,
    friend_taken = function() return "say_grief" end,
    defiance_good = function(npc, st) return Traits(npc, st).loyal < -0.2 and "say_res_respect" or nil end,
    defiance_bad = function(npc, st) return Traits(npc, st).loyal > 0.3 and "say_loyal_warn" or nil end,
    stopped = function(npc, st) local t = Traits(npc, st) return t.loyal > 0.3 and "say_obey" or (t.loyal < -0.3 and t.brave > 0.2 and "say_hate_quiet" or nil) end,
}

function LC.CueThought(m, kind)
    local pick = SEEN[kind]
    local npc = pick and m and m.p and m.p.npc
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not Named(npc, st) then return end
    if not PlayerNear(npc:GetPos(), HEAR) then return end
    npc.lcCueSeen = npc.lcCueSeen or {}
    local now = CurTime()
    if (npc.lcCueSeen[kind] or -1e9) > now - 60 then return end
    npc.lcCueSeen[kind] = now
    timer.Simple(math.Rand(0.8, 2), function()
        if IsValid(npc) and LC.NPCs and LC.NPCs[npc] == st and st.state ~= "jailed" then
            local id = pick(npc, st)
            if id then LC.Cue(npc, st, id, { all = true, lead = false }) end
        end
    end)
end
hook.Add("LivingCityThought", "LivingCityVoiceCues", function(m, kind) LC.CueThought(m, kind) end)

------------------------------------------------------------------------
-- Hurt by a player: they plead, or bristle; by a unit, they say sorry
------------------------------------------------------------------------

hook.Add("EntityTakeDamage", "LivingCityVoiceCues", function(ent, dmg)
    local st = LC.NPCs and LC.NPCs[ent]
    if not Named(ent, st) then return end
    local a = dmg:GetAttacker()
    if not (IsValid(a) and a:IsPlayer()) or dmg:GetDamage() <= 0 or dmg:GetDamage() >= ent:Health() then return end
    if (ent.lcCueHurtAt or -1e9) > CurTime() - 20 then return end
    ent.lcCueHurtAt = CurTime()
    local t = Traits(ent, st)
    local id = (LC.PlayerIsCP and LC.PlayerIsCP(a)) and "say_sorry" or ((t.pride > 0.3 and t.brave > 0.2) and "say_insulted" or "say_threatened")
    timer.Simple(0.4, function() if IsValid(ent) and LC.NPCs[ent] == st then LC.Cue(ent, st, id, { all = true }) end end)
end)

------------------------------------------------------------------------
-- What a player says near them (only while the director has no key: with one, the model answers)
------------------------------------------------------------------------

local function Has(text, words)
    for _, w in ipairs(words) do
        if string.find(text, w) then return true end
    end
    return false
end

local W = {
    greet = { "^hi%f[%A]", "^hey%f[%A]", "^hello", "^morning", "^evening", "^afternoon", "^yo%f[%A]", "^greetings", "^howdy", "^hiya" },
    bye = { "bye", "see you", "see ya", "take care", "farewell", "goodnight", "good night", "gotta go", "got to go", "^later%f[%A]" },
    how = { "how are you", "how're you", "how you doing", "how are you doing", "you okay", "you ok%f[%A]", "how's it going", "how are things", "how have you been", "you alright", "you all right" },
    laugh = { "haha", "hehe", "%f[%a]lol%f[%A]", "lmao", "joke", "funny" },
    insult = { "idiot", "stupid", "moron", "shut up", "fuck", "shit", "bitch", "bastard", "loser", "ugly", "dumb", "pathetic", "coward", "scum", "rat%f[%A]" },
    threat = { "kill you", "hurt you", "beat you", "shoot you", "i'll get you", "watch yourself", "you're dead", "or else", "break your" },
    sorry = { "sorry", "apolog", "my bad", "didn't mean" },
    res = { "resistance", "rebel", "lambda", "freeman", "uprising", "fight back", "revolution", "underground" },
    combine = { "combine", "breen", "administrator", "overwatch", "civil protection", "%f[%a]cps?%f[%A]", "metrocop", "%f[%a]units?%f[%A]", "the cops" },
    against = { "suck", "hate", "bastard", "evil", "monster", "scum", "pigs", "down with", "kill", "tyrant", "murderer", "can't stand", "sick of" },
    praise = { "glory", "praise", "love the", "long live", "knows best", "thank the", "grateful", "loyal" },
    food = { "food", "%f[%a]eat", "hungry", "ration", "bread", "starving" },
    smoke = { "smoke", "cigarette", "%f[%a]cigs?%f[%A]", "a light" },
    help = { "help me", "need help", "can you help", "could you help", "help us", "i need" },
    info = { "where", "who ", "what happened", "seen ", "know anything", "news", "rumou?r", "heard", "anything going on" },
    ask = { "will you", "would you", "can you", "could you", "do you want", "join", "come with", "are you in" },
}
LC.CueWords = W

-- The line a named citizen answers what was said with (nil: nothing to say to that).
function LC.CueReply(ply, npc, st, text)
    text = string.lower(text or "")
    local feel, t = Feeling(npc, ply), Traits(npc, st)
    local unitNear = UnitNear(npc:GetPos(), 600)
    local cp = LC.PlayerIsCP and LC.PlayerIsCP(ply)
    if Has(text, W.threat) then return "say_threatened" end
    if Has(text, W.insult) then return (t.brave < -0.3 or cp) and "say_sorry" or "say_insulted" end
    if Has(text, W.res) then
        if cp then return "say_res_deny" end
        if t.loyal > 0.3 then return "say_loyal_warn" end
        if unitNear then return Pick({ "say_units_near", "say_later" }) end
        if st.rebel and feel >= 6 then return "say_res_side" end
        if st.rebel and feel >= WARM then return "say_res_hint" end
        if t.brave < -0.2 then return Pick({ "say_res_refuse", "say_dunno_scared" }) end
        if t.loyal < -0.3 and feel >= 0 then return "say_res_respect" end
        return Pick({ "say_res_deny", "say_cant_say" })
    end
    if Has(text, W.combine) then
        if Has(text, W.against) then
            if t.loyal > 0.3 or cp then return "say_loyal_warn" end
            if unitNear then return "say_units_near" end
            if t.loyal < -0.3 then return t.brave > 0 and "say_hate_quiet" or "say_agree" end
            return "say_careful"
        end
        if Has(text, W.praise) then
            if t.loyal > 0.3 then return Pick({ "say_agree", "say_loyal" }) end
            if t.loyal < -0.3 and t.brave > 0 and not cp then return "say_disagree" end
            return "say_obey"
        end
        if cp then return "say_greet_unit" end
        return t.brave < 0 and "say_fear_units" or "say_careful"
    end
    if Has(text, W.laugh) then return feel >= AFRAID and "say_laugh" or nil end
    if Has(text, W.sorry) then return feel >= -6 and "say_yes" or "say_bye_cold" end
    if Has(text, W.how) then
        if feel >= WARM and t.hope < 0 then return "say_truth" end
        return LC.CueState(npc, st)
    end
    if Has(text, W.bye) then return LC.CueGoodbye(npc, st, ply) end
    if Has(text, W.greet) then return LC.CueGreeting(npc, st, ply) end
    if Has(text, W.food) then
        if Needs(npc).food < 0.4 then return "say_state_hungry" end
        return feel >= WARM and "say_maybe" or "say_ask_else"
    end
    if Has(text, W.smoke) then return (Traits(npc, st).vice > 0.3) and "say_ask_smoke" or "say_no" end
    if Has(text, W.help) then
        if unitNear then return "say_later" end
        if feel >= WARM then return "say_tip_help" end
        return feel <= AFRAID and "say_no" or "say_ask_else"
    end
    if Has(text, W.info) then
        if t.brave < -0.4 then return "say_dunno_scared" end
        if feel >= WARM then return Pick({ "say_heard", "say_truth" }) end
        if t.suspicion > 0.3 then return "say_dunno" end
        return Pick({ "say_heard", "say_dunno", "say_ask_else" })
    end
    if Has(text, W.ask) then
        if feel >= 6 then return "say_yes_warm" end
        if feel <= AFRAID then return "say_no_hard" end
        if unitNear then return "say_later" end
        return feel >= WARM and Pick({ "say_yes", "say_maybe" }) or Pick({ "say_no", "say_maybe" })
    end
    if string.find(text, "?", 1, true) then
        return feel >= WARM and Pick({ "say_maybe", "say_truth" }) or Pick({ "say_dunno", "say_maybe" })
    end
    if string.find(text, "i think", 1, true) or string.find(text, "i believe", 1, true) then
        return (feel >= 0 and Chance(0.6)) and "say_agree" or "say_disagree"
    end
    return nil
end

-- The named citizen being spoken to: the nearest in front of the player, close enough to have heard.
function LC.CueListener(ply, kind)
    local reach = (kind == "whisper" and 110) or (kind == "yell" and 400) or 220
    local best, bestD, bestSt = nil, nil, nil
    local eye = ply.GetAimVector and ply:GetAimVector() or ply:GetForward()
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), reach)) do
        local st = LC.NPCs and LC.NPCs[ent]
        if Named(ent, st) and st.state ~= "jailed" and st.state ~= "hostile" and st.state ~= "abed" then
            local d = ent:GetPos() - ply:GetPos()
            local dist = d:Length()
            local facing = dist < 1 and 1 or eye:Dot(d / dist)
            if facing > 0.5 and (not bestD or dist < bestD) then best, bestD, bestSt = ent, dist, st end
        end
    end
    return best, bestSt
end

function LC.CueHeard(ply, kind, text)
    if not cvOn:GetBool() or not IsValid(ply) then return end
    if kind ~= "say" and kind ~= "whisper" and kind ~= "yell" then return end
    if LC.BrainOn and LC.BrainOn() then return end -- (the model answers instead: sv_livingcity_brain.lua)
    if (ply.lcCueHeardAt or -1e9) > CurTime() - 2 then return end
    local npc, st = LC.CueListener(ply, kind)
    if not npc then return end
    local id = LC.CueReply(ply, npc, st, text)
    if not id then return end
    ply.lcCueHeardAt = CurTime()
    timer.Simple(math.Rand(0.6, 1.2), function()
        if IsValid(npc) and IsValid(ply) and LC.NPCs[npc] == st then
            if LC.Face then LC.Face(npc, ply:GetPos()) end
            LC.Cue(npc, st, id, { all = true, to = "near" })
        end
    end)
end
hook.Add("LivingCitySpoke", "LivingCityVoiceCues", function(ply, kind, text)
    local ok, err = pcall(LC.CueHeard, ply, kind, text)
    if not ok and LC.Error then LC.Error("voice cues (chat)", err) end
end)

------------------------------------------------------------------------
-- Walking up to a player: a warning, asking for something, or a small gift
------------------------------------------------------------------------

local GIFTS = { "water", "ration" }

-- What this citizen would walk up to this player to say (nil: nothing).
function LC.CueApproachLine(ply, npc, st)
    local feel, t, s = Feeling(npc, ply), Traits(npc, st), Needs(npc)
    if feel <= AFRAID or (LC.PlayerIsCP and LC.PlayerIsCP(ply)) then return nil end
    local rebelPly = ply:GetNW2String("lcf_faction", "") == "resistance"
    if t.loyal < 0.2 and feel >= 0 then
        if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return "say_warn_go" end
        if LC.AlertLevel and (LC.AlertLevel(ply) or 0) >= 1 then return "say_warn_asked" end
        if rebelPly and UnitNear(ply:GetPos(), 900) then return "say_warn_watched" end
        if feel >= WARM then
            for other, ost in pairs(LC.NPCs or {}) do
                if other ~= npc and ost.role == "citizen" and ost.snitch == true and IsValid(other) and other:GetPos():DistToSqr(ply:GetPos()) < 500 * 500 then
                    return "say_warn_informer"
                end
            end
        end
        if (LC.Socio == "red" or LC.Socio == "black") then return "say_tip_trouble" end
    end
    if st.rebel and rebelPly then return feel >= WARM and "say_res_side" or "say_tip_help" end
    if feel >= 6 and t.compassion > 0 then
        local key = LC.MemoryKey and LC.MemoryKey(ply) or ply
        if not ((npc.lcCueGave or {})[key] and npc.lcCueGave[key] > CurTime() - 1800) then return "say_offer" end
        return "say_tip_help"
    end
    if s.food < 0.3 then return "say_ask_food" end
    if s.crave > 0.6 and t.vice > 0 then return "say_ask_smoke" end
    local frayed = (LC.Psy and LC.Psy.cfg and LC.Psy.cfg.frayed) or 10
    if s.stress >= frayed and t.social > 0 then return "say_ask_help" end
    if s.company < 0.3 and t.social > 0.2 then return "say_state_lonely" end
    return nil
end

-- Has this person a voice for that line? (the recorded one, or Half-Life 2's own line in its place)
local function CanSay(npc, st, id)
    if LC.LineKey and LC.LineKey(npc, st) == "citizen" then return true end
    return LC.HL2Instead and LC.HL2Instead[id] ~= nil
end

function LC.CueApproach(ply, now)
    now = now or CurTime()
    if not IsValid(ply) or not ply:Alive() or not LC.MindsErrand or not LC.MindsFree then return false end
    local cands = {}
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 1200)) do
        local st = LC.NPCs and LC.NPCs[ent]
        if Named(ent, st) and LC.MindsFree(st) and (ent.lcCueWalkAt or -1e9) < now - 900 then cands[#cands + 1] = { ent, st } end
    end
    for i = #cands, 2, -1 do local j = math.random(i) cands[i], cands[j] = cands[j], cands[i] end
    for _, c in ipairs(cands) do
        local npc, st = c[1], c[2]
        local id = LC.CueApproachLine(ply, npc, st)
        if id and CanSay(npc, st, id) then
            npc.lcCueWalkAt, ply.lcCueApproachAt = now, now
            LC.MindsErrand(npc, st, ply, function(n, s, target)
                if LC.Face then LC.Face(n, target:GetPos()) end
                local lead = (id == "say_offer" or string.sub(id, 1, 9) == "say_warn_") and Pick({ "say_open_you", "say_open_listen" }) or nil
                local said = LC.Cue(n, s, id, { all = true, force = true, lead = lead or false, to = target })
                if said and id == "say_offer" and IsValid(target) and LC.GiveItem then
                    local item = Pick(GIFTS)
                    if LCS and LCS.Items and LCS.Items[item] and LC.GiveItem(target, item, 1) then
                        local key = LC.MemoryKey and LC.MemoryKey(target) or target
                        n.lcCueGave = n.lcCueGave or {}
                        n.lcCueGave[key] = CurTime()
                        target:ChatPrint("They press " .. string.lower(LCS.Items[item].name or item) .. " into your hand.")
                    end
                end
                s.untilT = math.max(s.untilT or 0, CurTime() + 8)
            end)
            return true, id
        end
    end
    return false
end

------------------------------------------------------------------------
-- Every second or so: goodbye when you walk off, and now and then a walk-up
------------------------------------------------------------------------

timer.Create("LivingCityVoiceCues", 1, 0, function()
    if not cvOn:GetBool() or not LC.Running then return end
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local talk = ply.lcCueTalk
        if talk then
            local npc = talk.npc
            local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
            if not st or now - talk.at > 90 then ply.lcCueTalk = nil
            elseif ply:GetPos():DistToSqr(npc:GetPos()) > 260 * 260 then
                ply.lcCueTalk = nil
                LC.Cue(npc, st, LC.CueGoodbye(npc, st, ply))
            end
        end
    end
    local gap = cvApproach:GetFloat()
    if gap <= 0 or (LC.BrainOn and LC.BrainOn()) or (LC.CueApproachNext or 0) > now then return end
    LC.CueApproachNext = now + 15
    if LC.Event == "curfew" or LC.Event == "lockdown" then return end
    for _, ply in ipairs(player.GetAll()) do
        if (ply.lcCueApproachAt or -1e9) < now - gap and (ply.lcCueJoinAt or now) < now - 120 and Chance(0.35) then
            local ok, err = pcall(LC.CueApproach, ply, now)
            if not ok and LC.Error then LC.Error("voice cues (walk-up)", err) end
        end
        ply.lcCueJoinAt = ply.lcCueJoinAt or now
    end
end)
