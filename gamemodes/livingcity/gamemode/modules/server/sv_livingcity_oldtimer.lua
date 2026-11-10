--[[
    Living City: the old-timer

    One of the city's citizens is an old man who has seen it all (the owner,
    10 November: "an old man NPC that gives advice and players can find them
    and talk to them"). He's one of the roster, out among everyone else,
    going about his day: you have to find him. He's the unofficial opposite
    of the Citizen Information clerk (sv_livingcity_infodesk.lua): the clerk
    gives the rules, he gives the truth.

    Press E on him and he talks. He opens up as he gets to know you (the
    same memory every citizen has, sv_livingcity_talk.lua): a word now and
    then (once every 15 minutes) and sharing food warm him to you.
      A stranger: keep your head down; curfew; scanners; don't run.
      Friendly (3): where the bins are and that nobody checks them, water,
      fishing, cooking (and he marks the way).
      Glad to see you (6): the dealer who sells what the Commissary doesn't
      (marked), what a lockpick is for, and, if you think like him, where
      the Resistance gathers.
    What he tells you, you've learned: no tip cards for it (LC.Learn).

    He's kept with the city's roster, so he's the same old man after a
    restart; if he dies, someone else grows old.

    Recordings, if you make them: garrysmod/sound/livingcity/oldtimer/,
    named for the line (bins1.wav). Every line: VOICE_LINES.md section 7
    (LC.OldTimerLines below). Without one, Half-Life 2's own citizen voice.

    Setting: lc_oldtimer (1; 0 and he's just another citizen).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOld = CreateConVar("lc_oldtimer", "1", FLAGS, "One of the city's citizens is an old man who gives advice and opens up as he knows you")

function LC.OldTimerOn() return cvOld:GetBool() end

-- The dealer, for the waypoint (the official lists leave him out, of course).
local function RegisterPlaces()
    if not LC.WaypointPlaces then return end
    LC.WaypointPlaces.dealer = function(ply)
        local e = LC.NearestEntOf and LC.NearestEntOf(ply:GetPos(), { "lc_dealer" }, function(d) return not d:GetNW2Bool("lc_busted", false) end)
        if IsValid(e) then return e:GetPos(), "The man he told you about" end
        return nil, "No dealer in the city right now."
    end
end
hook.Add("Initialize", "LivingCityOldTimerPlaces", RegisterPlaces)
hook.Add("InitPostEntity", "LivingCityOldTimerPlaces", RegisterPlaces)
RegisterPlaces()

local FRIENDLY, CLOSE = 3, 6
local VISIT_GAP = 900

LC.OldTimerVoiceRoot = "livingcity/oldtimer/"

-- id = { trust needed, button, words, place to mark (a LC.WaypointPlaces kind), tips it teaches }
LC.OldTimerTopics = {
    { "headdown", 0, "Any advice for someone like me?",
      "Keep your head down, your papers handy, and your mouth shut. The ones who last are the ones nobody remembers.", nil, { "cop_near", "stopped" } },
    { "curfew", 0, "What about curfew?",
      "When the voice says two minutes, it means one. Be indoors. I've seen what they do to the ones who are late, and so have the walls.", nil, { "curfew_warning", "event_curfew" } },
    { "scanners", 0, "The flying things?",
      "Scanners. They take your picture. Don't stand under them, don't do anything worth photographing, and if one flashes you, walk, don't run.", nil, { "scanreport", "photographed" } },
    { "running", 0, "Why does everyone walk so slowly?",
      "Run in front of a cop and you're a suspect. Walk. Even when your heart's going like a train, walk.", nil, { "running" } },
    { "bins", FRIENDLY, "Where do people find food, really?",
      "The bins. Commissary scraps, things people drop. Nobody checks them as often as they should. Here, I'll show you the nearest.", "bin", { "bin", "hungry" } },
    { "water", FRIENDLY, "And water?",
      "Sinks, the machines, open water if you're desperate. Boil anything that isn't from a tap, or you'll be coughing for a week.", "water", { "water", "sink", "thirsty", "parasites" } },
    { "fishing", FRIENDLY, "Anything else to eat out there?",
      "Fish, if you can find a line. Cook what you catch on a stove or a fire barrel. Raw meat will turn your stomach.", nil, { "item_fishing", "item_raw", "stove" } },
    { "dealer", CLOSE, "Things the Commissary doesn't sell?",
      "There's a man who trades in what you can't buy. Don't tell him I sent you, and don't let a cop see you with him. That way.", "dealer", { "dealer" } },
    { "lockpick", CLOSE, "What's a lockpick good for?",
      "Doors that aren't yours. Rooms people left in a hurry. Be quick, be quiet, and never in front of a unit.", nil, { "item_lockpick" } },
    { "resistance", CLOSE, "Is anyone fighting back?",
      "You didn't hear it from me.", nil, { "zone_rebel" } },
}

-- His troubles: an unmarked quest line (the owner, 10 November: "little hints in his dialogue that you can
-- help remedy and then he likes you more and gives you better advice"). One at a time, in order, he lets the
-- current one slip when you visit; nothing marks it. Offer him something from your pockets and he takes what
-- he needs: he warms to you (+2), thanks you, and the next trouble surfaces. Help with all of them and he
-- has one last thing to tell you, and something to give.
--   id = { what he'll take (item ids; "food" is anything fit to eat), the hint, his thanks }
LC.OldTimerTroubles = {
    { "hungry", { "food" }, "My legs won't take me to the bins any more. Some days I don't eat at all.",
      "Food. Real food. You don't know what that means to an old man." },
    { "thirsty", { "water" }, "The tap on my floor's been dry a week. Carrying water up those stairs, at my age...",
      "Water. Bless you. I'll make it last." },
    { "cough", { "medicine" }, "This cough. Twenty years I've had it. The Commissary wants more for its medicine than I see in a month.",
      "Medicine? For me? I'll sleep tonight, for the first time in a long while." },
    { "card", { "ration_card" }, "Some young thug took my ration card in the line. I'm too old to work a shift for another.",
      "A card? You worked for that. I won't forget it. Not ever." },
    { "smoke", { "cig_union", "cig_rolled" }, "What I wouldn't give for a smoke. Even the Union's, and those taste of floor sweepings.",
      "Ah. Now that's a kindness. Sit with me while I have it." },
}

LC.OldTimerLines = {
    greet = "Sit down, sit down. My knees aren't what they were. What do you want to know?",
    greet_friend = "Ah, you again. Good. Not many come back.",
    stranger = "I don't know you. Ask me something simple.",
    notyet = "Hm. Ask me that when I know you better.",
    food = "For me? You're a good one. I won't forget it.",
    nowhere = "There used to be one. Not in this part of town, not any more.",
    nothing = "Kind of you. But nothing I need, not that.",
    keepsake = "You've done more for me than my own family. Here. My old picks. I won't be needing them, and you might. Doors don't stay locked for people who know how.",
    keepsake_again = "Sit a while. The city's quieter when there's someone to share it with.",
}

------------------------------------------------------------------------
-- Who he is
------------------------------------------------------------------------

local function Living(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    return st and st.role == "citizen" and not st.test and st or nil
end

-- The old-timer in the city right now, if he's out.
function LC.OldTimer()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.oldtimer then return npc, st end
    end
end

function LC.MakeOldTimer(npc)
    local st = Living(npc)
    if not st then return false end
    st.oldtimer = true
    npc:SetNW2Bool("lc_oldtimer", true)
    if npc.lcProfile then
        npc.lcProfile.oldtimer = true
        if LC.MarkPeopleDirty then LC.MarkPeopleDirty() end
    end
    if LC.SetNPCStr then LC.SetNPCStr(npc, "lc_pjob", "Old-timer") end
    return true
end

function LC.OldTimerTick()
    if not cvOld:GetBool() then return end
    if LC.OldTimer() then return end
    -- the roster's old-timer, if he's out
    local living
    for _, p in ipairs(LC.People and LC.People.list or {}) do
        if p.oldtimer and p.alive ~= false then
            living = p
            if IsValid(p.npc) then LC.MakeOldTimer(p.npc) return end
        end
    end
    if living then return end -- (he's alive, just not out right now)
    -- nobody yet (or he died): one of the men out on the street grows old
    local pick, any = {}, {}
    for npc, st in pairs(LC.NPCs or {}) do
        if Living(npc) and npc.lcProfile and not st.rebel then
            any[#any + 1] = npc
            if st.gender ~= "female" then pick[#pick + 1] = npc end
        end
    end
    if #pick == 0 then pick = any end
    if #pick > 0 then LC.MakeOldTimer(pick[math.random(#pick)]) end
end
timer.Create("LivingCityOldTimer", 20, 0, function() LC.OldTimerTick() end)

------------------------------------------------------------------------
-- Talking to him
------------------------------------------------------------------------

local AUDIO = { wav = true, mp3 = true, ogg = true }
local clips
local function Scan()
    clips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.OldTimerVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            clips[base] = clips[base] or {}
            table.insert(clips[base], LC.OldTimerVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.OldTimerVoiceRoot .. n) end
        end
    end
end
LC.OldTimerRescan = Scan
hook.Add("Initialize", "LivingCityOldTimer", Scan)

function LC.OldTimerClip(id)
    if not clips then Scan() end
    local t = clips[id]
    return t and t[math.random(#t)] or nil
end

local function Speak(npc, st, id)
    if not IsValid(npc) then return end
    local c = LC.OldTimerClip(id)
    if c then npc:EmitSound(c, 70) return end
    local g = st and st.gender == "female" and "female01" or "male01"
    npc:EmitSound("vo/npc/" .. g .. "/" .. string.format("question%02d", math.random(1, 20)) .. ".wav", 65)
end

-- What this character of yours has helped him with (kept with the roster, sv_livingcity_people.lua).
local function Helped(npc, ply)
    local p = npc.lcProfile
    if not p then npc.lcHelpedTmp = npc.lcHelpedTmp or {} return npc.lcHelpedTmp end
    p.helped = p.helped or {}
    local key = LC.MemoryKey and LC.MemoryKey(ply) or ply:SteamID()
    p.helped[key] = p.helped[key] or {}
    return p.helped[key]
end
LC.OldTimerHelped = Helped

-- His trouble right now, for you (nil: none left).
function LC.OldTimerTrouble(npc, ply)
    local h = Helped(npc, ply)
    for _, t in ipairs(LC.OldTimerTroubles) do if not h[t[1]] then return t end end
end

local function AllHelped(npc, ply) return LC.OldTimerTrouble(npc, ply) == nil end

-- What in your pockets would help with it.
local function Remedy(ply, t)
    for _, id in ipairs(t[2]) do
        if id == "food" then
            local f = LC.FoodToGive and LC.FoodToGive(ply)
            if f then return f end
        elseif LC.HasItem(ply, id) then return id end
    end
end

local function Topic(id)
    for _, t in ipairs(LC.OldTimerTopics) do if t[1] == id then return t end end
end

local function Menu(ply, npc, st, said)
    local feel = LC.Feeling and LC.Feeling(npc, ply) or 0
    local mood = LC.MoodWord and LC.MoodWord(feel) or "a stranger"
    local opts = {}
    for _, t in ipairs(LC.OldTimerTopics) do
        if feel >= t[2] then opts[#opts + 1] = { t[1], t[3] }
        elseif t[2] == FRIENDLY or t[2] == CLOSE then opts[#opts + 1] = { t[1], t[3] .. " (he doesn't know you well enough)" } end
    end
    if AllHelped(npc, ply) then opts[#opts + 1] = { "keepsake", "Sit with him a while" } end
    opts[#opts + 1] = { "food", "Offer him something from your pockets" }
    LC.OpenDialog(ply, "oldtimer", npc, {
        title = LC.NPCStr and LC.NPCStr(npc, "lc_pname", "An old man") or "An old man",
        sub = "An old man with tired eyes. He's " .. mood .. ".",
        text = said, options = opts })
end

function LC.OpenOldTimer(ply, npc)
    local st = Living(npc)
    if not st or not st.oldtimer or not IsValid(ply) or not LC.OpenDialog then return false end
    local feel = LC.Feeling and LC.Feeling(npc, ply) or 0
    if feel <= -3 then
        if LC.OpenTalk then LC.OpenTalk(ply, npc) end -- (afraid of you: like anyone else)
        return true
    end
    -- a visit warms him to you, now and then
    ply.lcOldTimerVisit = ply.lcOldTimerVisit or {}
    local key = LC.MemoryKey and LC.MemoryKey(ply) or ply:SteamID()
    if (ply.lcOldTimerVisit[key] or 0) < CurTime() and feel < CLOSE and LC.Remember then
        ply.lcOldTimerVisit[key] = CurTime() + VISIT_GAP
        LC.Remember(npc, ply, 1)
        feel = LC.Feeling(npc, ply)
    end
    local line = feel >= FRIENDLY and "greet_friend" or "greet"
    local troubled = LC.OldTimerTrouble(npc, ply)
    Speak(npc, st, (troubled and LC.OldTimerClip("hint_" .. troubled[1])) and ("hint_" .. troubled[1]) or line)
    if LC.TalkStepAway then LC.TalkStepAway(npc, ply) end
    if LC.Face then LC.Face(npc, ply:GetPos()) end
    if st.state == "moving" then npc:SetSchedule(SCHED_IDLE_STAND) if LC.SetState then LC.SetState(npc, st, "idle") end end
    st.untilT = math.max(st.untilT or 0, CurTime() + 20)
    -- and whatever's troubling him slips out (never marked: you have to listen)
    local trouble = LC.OldTimerTrouble(npc, ply)
    Menu(ply, npc, st, "'" .. LC.OldTimerLines[line] .. (trouble and (" " .. trouble[3]) or "") .. "'")
    hook.Run("LivingCityOldTimer", ply, npc)
    return true
end

LC.DialogHandlers.oldtimer = function(ply, npc, id)
    local st = Living(npc)
    if not st or not st.oldtimer then return end
    st.untilT = math.max(st.untilT or 0, CurTime() + 20)
    local feel = LC.Feeling and LC.Feeling(npc, ply) or 0
    if id == "food" then
        -- his trouble first: what he needs, if you have it
        local trouble = LC.OldTimerTrouble(npc, ply)
        local give = trouble and Remedy(ply, trouble)
        if give and LC.TakeItem(ply, give) then
            Helped(npc, ply)[trouble[1]] = true
            if LC.MarkPeopleDirty then LC.MarkPeopleDirty() end
            LC.Remember(npc, ply, 2)
            Speak(npc, st, "thanks_" .. trouble[1])
            hook.Run("LivingCityOldTimerHelped", ply, npc, trouble[1])
            local nxt = LC.OldTimerTrouble(npc, ply)
            Menu(ply, npc, st, "'" .. trouble[4] .. "'" .. (nxt and ("\n\nLater, quieter: '" .. nxt[3] .. "'") or ""))
            return "helped_" .. trouble[1]
        end
        -- otherwise a meal, now and then, still warms him (not every minute)
        local food = LC.FoodToGive and LC.FoodToGive(ply)
        if not food then
            Speak(npc, st, "nothing")
            Menu(ply, npc, st, "'" .. LC.OldTimerLines.nothing .. (trouble and (" " .. trouble[3]) or "") .. "'")
            return "nothing"
        end
        LC.TakeItem(ply, food)
        npc.lcOldFed = npc.lcOldFed or {}
        local key = LC.MemoryKey and LC.MemoryKey(ply) or ply:SteamID()
        if (npc.lcOldFed[key] or 0) < CurTime() then
            npc.lcOldFed[key] = CurTime() + 600
            LC.Remember(npc, ply, 1)
        end
        Speak(npc, st, "food")
        Menu(ply, npc, st, "'" .. LC.OldTimerLines.food .. "'")
        return "food"
    end
    if id == "keepsake" then
        if not AllHelped(npc, ply) then return end
        local h = Helped(npc, ply)
        if not h.keepsake then
            h.keepsake = true
            if LC.MarkPeopleDirty then LC.MarkPeopleDirty() end
            if LC.GiveItem then LC.GiveItem(ply, "lockpick", 1) end
            if LC.Remember then LC.Remember(npc, ply, 2) end
            Speak(npc, st, "keepsake")
            Menu(ply, npc, st, "'" .. LC.OldTimerLines.keepsake .. "' (He presses a Lockpick set into your hand.)")
            return "keepsake"
        end
        Speak(npc, st, "keepsake_again")
        Menu(ply, npc, st, "'" .. LC.OldTimerLines.keepsake_again .. "'")
        return "keepsake_again"
    end
    local t = Topic(id)
    if not t then return end
    if feel < t[2] then
        Speak(npc, st, "notyet")
        Menu(ply, npc, st, "'" .. LC.OldTimerLines.notyet .. "'")
        return "notyet"
    end
    local said = t[4]
    if t[1] == "resistance" then
        -- only to someone who might be one of them, and only what a sympathizer would say
        local hint = LC.SafeHouseHint and LC.SafeHouseHint(ply)
        said = hint and (said .. " " .. hint) or (said .. " Nobody I know of. Not any more.")
    end
    Speak(npc, st, t[1])
    if LC.Learn then LC.Learn(ply, unpack(t[6])) end
    if t[5] then
        local find = LC.WaypointPlaces and LC.WaypointPlaces[t[5]]
        local pos, label
        if find then pos, label = find(ply) end
        if pos and LC.GuideTo then LC.GuideTo(ply, pos, label)
        elseif find then said = said .. " ... " .. LC.OldTimerLines.nowhere end
    end
    Menu(ply, npc, st, "'" .. said .. "'")
    return t[1]
end

hook.Add("LivingCityPlayerUsedNPC", "LivingCityOldTimer", function(ply, npc, st)
    if not cvOld:GetBool() or not st or not st.oldtimer then return end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return end -- (units stop citizens with E, him too)
    timer.Simple(0, function() if IsValid(ply) and IsValid(npc) then LC.OpenOldTimer(ply, npc) end end)
end)
