--[[
    Living City: the dream plan (who chooses tonight's dream, and how)

      The owner, 9 November: "let's make it so the administrator (human player) can't pick which dream
      it is, they can only pick nightmare or propaganda as a category, and they can only pick once every
      few nights, not every single night; this means there have to be a neutral or happy dream in
      between propaganda and nightmare dreams on the nights an administrator doesn't (or can't) pick the
      category. Also the administrator ONLY has to show up/in/watch dreams that they picked the category
      for ... when the administrator picks a category, it does a round robin and picks the 'next' dream
      in that category ... for the gamemode's automated AI/NPC administrator (when there is no human
      played administrator) ... a nightmare if a CP unit is murdered, a toss up between propaganda or
      nightmare if the status is red throughout the day, and if just yellow then a neutral dream. happy
      dreams for sure if the status was always green or just dipped to yellow once. We want a nice
      rotation so it's not always nightmares or always one or the other category, even if there is a
      human administrator", and, as the city goes to sleep, the day's mood on the black screen in words,
      never a formula ("Today the city was calm, you slip off to a happy dream").

      The Administrator (a player): her tablet's Tonight's dream offers two kinds, Nightmare or
      Propaganda, never a particular dream. One choice every LC.DreamPickNights nights (3: choose
      tonight, the next is two nights after), and never the night straight after a Nightmare or
      propaganda dream. She can take tonight's choice back before it's dreamt (it isn't spent until
      it's dreamt). She only has to be in the dreams she chose: on other nights lights out doesn't
      send her to bed, and asleep she isn't taken into them (her tablet: "Dreams I didn't choose: skip
      them", on unless she turns it off; joining one, she can wake from it whenever she likes).
      Every other night: a Happy or Neutral dream, by the day (Happy after a calm one).

      Nobody plays her (lc_dream_auto 1): the city chooses by sociostability. After a Nightmare or
      propaganda night, a Happy or Neutral one first. Otherwise: a Civil Protection or Overwatch unit
      murdered today by a citizen, rebel or vortigaunt, a Nightmare (a player's murder; NPCs' count
      half, so two of theirs, and more on a full server, as for sociostability); sociostability at red (lc_dream_bad_socio) for most of the day
      (LC.DreamRedShare, half of it), Nightmare or propaganda, a toss-up; always green, or only one
      dip to yellow, Happy; anything else, Neutral.

      Round robin: each kind (Happy, Neutral, Nightmare, propaganda) plays its dreams in turn, the next
      one each time, so none repeat while others wait (kept in data/livingcity/dream_plan.json).

      As the dream comes, a few seconds before it begins, everyone about to dream it sees the screen
      go black and a line fade in about the day and what's coming (LC.DreamMoodTexts, chosen by why).

      lc_dream_rules 0 lifts the waits (her every-few-nights and the night in between).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dream_mood") -- (the black screen and the day's mood, as the dream comes)
util.AddNetworkString("lc_dream_ask") -- (the Administrator, lying down on a night she didn't choose: dream it, or sleep through it)

LC.DreamPickNights = 3 -- (her choice: once every this many nights)
LC.DreamRedShare = 0.5 -- (the share of the day at red that makes it a bad day for the city's own choice)
LC.DreamMoodLead = 7 -- (seconds before the dream that the black screen and its line come)
LC.DreamPlanFile = "livingcity/dream_plan.json"

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end
local function Log(level, msg) if LC.Log then LC.Log(level, msg) end end
local function Phase() return LC.DayPhase and LC.DayPhase() or "day" end
local function RulesOn() local cv = GetConVar("lc_dream_rules") return cv == nil or cv:GetBool() end
local function AutoOn() local cv = GetConVar("lc_dream_auto") return cv == nil or cv:GetBool() end
local function BadLevel() local cv = GetConVar("lc_dream_bad_socio") local v = cv and string.lower(cv:GetString()) or "red" return v == "yellow" and "yellow" or "red" end

------------------------------------------------------------------------
-- What's remembered: the turn of each kind, the nights, her last choice
------------------------------------------------------------------------

local P = LC.DreamPlan or { rot = {}, night = 0, adminNight = -100, specialNight = -100, lastKind = nil }
LC.DreamPlan = P
local function Save()
    local text = util.TableToJSON({ rot = P.rot, night = P.night, adminNight = P.adminNight, specialNight = P.specialNight, lastKind = P.lastKind })
    if LC.SafeWrite then LC.SafeWrite(LC.DreamPlanFile, text) else file.CreateDir("livingcity") file.Write(LC.DreamPlanFile, text) end
end
LC.DreamPlanSave = Save
local function Load()
    local t = LC.SafeReadJSON and LC.SafeReadJSON(LC.DreamPlanFile) or util.JSONToTable(file.Read(LC.DreamPlanFile, "DATA") or "")
    if type(t) ~= "table" then return end
    P.rot = type(t.rot) == "table" and t.rot or {}
    P.night = tonumber(t.night) or 0
    P.adminNight = tonumber(t.adminNight) or -100
    P.specialNight = tonumber(t.specialNight) or -100
    P.lastKind = t.lastKind
end
LC.DreamPlanLoad = Load
if not LC.DreamPlanLoaded then LC.DreamPlanLoaded = true LC.Try(Load) end

hook.Add("LivingCityDayPhase", "LivingCityDreamPlan", function(phase)
    if phase == "night" then P.night = (P.night or 0) + 1 Save() end
end)

-- The number of tonight's night (tomorrow's, once tonight's dream has been dreamt).
function LC.DreamPlanTonight()
    if Phase() == "night" then
        return (LC.DreamDreamtTonight and LC.DreamDreamtTonight()) and P.night + 1 or P.night
    end
    return P.night + 1
end

------------------------------------------------------------------------
-- The day, as the city felt it
------------------------------------------------------------------------

local D = LC.DreamRules -- (sv_livingcity_dreamrules.lua: worst, events)
local RANK = { green = 0, yellow = 1, red = 2 }
local T = LC.DreamDayTime or { at = CurTime(), level = "green", secs = { green = 0, yellow = 0, red = 0 }, dips = 0, murders = 0 }
LC.DreamDayTime = T
local function Settle(now)
    now = now or CurTime()
    T.secs[T.level] = (T.secs[T.level] or 0) + math.max(0, now - (T.at or now))
    T.at = now
end
function LC.DreamDayTimeReset()
    T.at, T.level = CurTime(), LC.Socio or "green"
    T.secs = { green = 0, yellow = 0, red = 0 }
    T.dips, T.murders = 0, 0
end
hook.Add("LivingCityDayPhase", "LivingCityDreamPlanDay", function(phase) if phase == "dawn" then LC.DreamDayTimeReset() end end)
hook.Add("LivingCitySocioChanged", "LivingCityDreamPlan", function(level, old)
    Settle()
    if level == "yellow" and (old == "green" or old == nil) then T.dips = T.dips + 1 end
    T.level = level
end)
-- A Civil Protection or Overwatch unit murdered: killed by someone not of the Combine (a player, or an NPC citizen, rebel or vortigaunt).
local COMBINE = { cp = true, ota = true, admin = true }
local function Murderer(a)
    if not IsValid(a) then return false end
    if a.IsPlayer and a:IsPlayer() then return not COMBINE[a:GetNW2String("lcf_faction", "")] end
    return a.GetClass ~= nil and (a:GetClass() == "npc_citizen" or a:GetClass() == "npc_vortigaunt")
end
function LC.DreamUnitMurdered(weight)
    T.murders = (T.murders or 0) + (weight or 1)
    if D and D.events then
        local have = false
        for _, e in ipairs(D.events) do if e == "a Civil Protection unit murdered" then have = true end end
        if not have then D.events[#D.events + 1] = "a Civil Protection unit murdered" end
    end
end
-- (a player's murder counts whole; an NPC's half, as it does for sociostability, and less again on a full server: sv_livingcity_cp.lua)
local UNITS = { npc_metropolice = true, npc_combine_s = true }
hook.Add("OnNPCKilled", "LivingCityDreamPlan", function(npc, attacker)
    if not (IsValid(npc) and npc.GetClass and UNITS[npc:GetClass()] and Murderer(attacker)) then return end
    if attacker.IsPlayer and attacker:IsPlayer() then LC.DreamUnitMurdered() else LC.DreamUnitMurdered(0.5 / (LC.SocioScale and LC.SocioScale() or 1)) end
end)
hook.Add("PlayerDeath", "LivingCityDreamPlan", function(victim, _, attacker)
    local f = IsValid(victim) and victim:GetNW2String("lcf_faction", "") or ""
    if (f == "cp" or f == "ota") and attacker ~= victim and Murderer(attacker) then
        if attacker.IsPlayer and attacker:IsPlayer() then LC.DreamUnitMurdered() else LC.DreamUnitMurdered(0.5 / (LC.SocioScale and LC.SocioScale() or 1)) end
    end
end)

-- The day so far: { calm, murders, worst, share (of the day at the bad level), dips }.
function LC.DreamDayMood()
    Settle()
    local total = (T.secs.green or 0) + (T.secs.yellow or 0) + (T.secs.red or 0)
    local bad = BadLevel()
    local badSecs = (T.secs.red or 0) + (bad == "yellow" and (T.secs.yellow or 0) or 0)
    local worst = (D and D.worst) or T.level or "green"
    if (RANK[T.level] or 0) > (RANK[worst] or 0) then worst = T.level end
    local share = total > 0 and badSecs / total or ((RANK[T.level] or 0) >= RANK[bad] and 1 or 0)
    local calm = worst == "green" or (worst == "yellow" and (T.dips or 0) <= 1)
    -- (murders: whole ones; two NPC murders make one)
    return { calm = calm, murders = (T.murders or 0) >= 1 and math.floor(T.murders) or 0, worst = worst, share = share, dips = T.dips or 0, bad = share >= LC.DreamRedShare and (RANK[worst] or 0) >= RANK[bad] }
end

------------------------------------------------------------------------
-- Round robin: the next dream of a kind
------------------------------------------------------------------------

-- Every dream of a kind there is to dream, in order (sv_livingcity_dreamrules.lua).
local function Kinds(kind) return LC.DreamsOfKind and LC.DreamsOfKind(kind) or {} end
function LC.DreamPlanNext(kind)
    local list = Kinds(kind)
    if #list == 0 then return nil end
    return list[((P.rot[kind] or 0) % #list) + 1]
end
local function Advance(kind) P.rot[kind] = (P.rot[kind] or 0) + 1 end
LC.DreamPlanAdvance = Advance

------------------------------------------------------------------------
-- The city's own choice (and every night she doesn't choose)
------------------------------------------------------------------------

-- Was there a Nightmare or propaganda dream last night (so tonight must be Happy or Neutral)?
function LC.DreamPlanAfterSpecial() return RulesOn() and LC.DreamPlanTonight() - (P.specialNight or -100) < 2 end

-- Tonight's kind and why (the why chooses the words on the black screen).
function LC.DreamPlanDecide()
    local day = LC.DreamDayMood()
    local rough = day.murders > 0 or day.bad
    if LC.HumanAdministrator and LC.HumanAdministrator() then -- (her nights are her choice; the rest are gentle)
        if rough then return "neutral", "spared" end -- (a murder, even on a green day, is no night for a Happy dream)
        if day.calm then return "happy", "calm" end
        return "neutral", "uneasy"
    end
    if LC.DreamPlanAfterSpecial() then return (day.calm and not rough) and "happy" or "neutral", rough and "after" or (day.calm and "calm" or "uneasy") end
    if day.murders > 0 then return "nightmare", "murder" end
    if day.bad then
        if math.random() < 0.5 then return "nightmare", "red_nightmare" end
        return "propaganda", "red_propaganda"
    end
    if day.calm then return "happy", "calm" end
    return "neutral", "uneasy"
end

-- The city's choice for tonight: a dream (the next of its kind), why, and its kind. nil when there's nothing.
function LC.DreamAutoPick()
    local kind, why = LC.DreamPlanDecide()
    local id = LC.DreamPlanNext(kind)
    if not id and (kind == "happy" or kind == "nightmare" or kind == "propaganda") then kind, why = "neutral", why == "calm" and "calm" or "uneasy" id = LC.DreamPlanNext("neutral") end
    if not id then id = LC.DreamPlanNext("happy") kind = "happy" end
    if not id then return nil end
    return id, why, kind
end

-- Does the city choose the nights nobody else does? (lc_dream_auto; a player Administrator only chooses some nights now.)
function LC.DreamCityPicks() return AutoOn() end

------------------------------------------------------------------------
-- Her choice: a kind, now and then
------------------------------------------------------------------------

LC.DreamAdminKinds = { nightmare = "a Nightmare", propaganda = "a propaganda dream" }

-- Can she choose tonight? True, or false, why not, and in how many nights she can.
function LC.DreamAdminCanPick(ply)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false, "Only the City Administrator chooses the city's dreams." end
    if not (LC.DreamReady and LC.DreamReady()) then return false, "The city can't dream yet." end
    local q = LC.DreamQueued and LC.DreamQueued()
    if q and q.source == "admin" then return false, "You've already chosen tonight's: take it back first to choose again." end
    if not RulesOn() then return true end
    local tonight = LC.DreamPlanTonight()
    local wait = LC.DreamPickNights - (tonight - (P.adminNight or -100))
    if wait > 0 then
        return false, string.format("You chose recently. Your next choice comes in %d %s.", wait, wait == 1 and "night" or "nights"), wait
    end
    if tonight - (P.specialNight or -100) < 2 then
        return false, "Last night's dream was a Nightmare or propaganda: tonight the city dreams something gentler. Choose tomorrow.", 1
    end
    return true
end

-- She chooses a kind (nightmare or propaganda): the next dream of it waits for tonight. True, or false and why not.
function LC.DreamAdminCategory(ply, kind)
    kind = string.lower(tostring(kind or ""))
    if not LC.DreamAdminKinds[kind] then return false, "Choose a Nightmare or propaganda: which dream it is, the city decides." end
    local ok, why = LC.DreamAdminCanPick(ply)
    if not ok then return false, why end
    local id = LC.DreamPlanNext(kind)
    if not id then return false, "There's no dream of that kind to dream." end
    if not (LC.DreamQueueEnding and LC.DreamQueueEnding(id, ply, "admin")) then return false, "The city can't dream yet." end
    local q = LC.DreamQueued()
    if q then q.cat, q.why = kind, "admin_" .. kind end
    Log("info", "Dream: the Administrator chose " .. kind .. " (" .. id .. ")")
    local dreamt = LC.DreamDreamtTonight and LC.DreamDreamtTonight()
    Notice(ply, "info", "Tonight's dream", string.format("You've chosen %s for %s. Which one, the city decides. You'll be in it yourself: lights out sends you to bed for it.",
        LC.DreamAdminKinds[kind], dreamt and "tomorrow night (tonight's has been dreamt)" or "tonight"), 10)
    return true
end
-- She takes tonight's choice back before it's dreamt (nothing spent).
function LC.DreamAdminCancel(ply)
    local q = LC.DreamQueued and LC.DreamQueued()
    if not (q and q.source == "admin" and q.by == ply) then return false, "You haven't chosen tonight's dream." end
    if LC.DreamActive then return false, "The city is dreaming it now." end
    if LC.DreamForget then LC.DreamForget() end
    Notice(ply, "info", "Tonight's dream", "Taken back. Tonight the city dreams its own dream, and your choice waits for another night.", 7)
    return true
end
-- Dreams she didn't choose: skip them (the default) or join them.
function LC.DreamAdminSkipping(ply) return IsValid(ply) and ply.GetPData ~= nil and ply:GetPData("lc_dream_skip", "1") ~= "0" end
function LC.DreamAdminSkipSet(ply, on)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false end
    ply:SetPData("lc_dream_skip", on and "1" or "0")
    Notice(ply, "info", "Dreams you didn't choose", on and "You'll skip them: lights out won't send you to bed for them, and asleep you sleep through them."
        or "You'll dream them with the city (and you can wake from one whenever you like).", 7)
    return true
end
-- Is tonight's dream (or the one under way) hers?
function LC.DreamAdminChoseTonight(ply)
    local d = LC.DreamActive
    if d and d.adminBy then return d.adminBy == ply end
    local q = LC.DreamQueued and LC.DreamQueued()
    return q ~= nil and q.source == "admin" and q.by == ply
end
-- Her answer for tonight, asked as she lay down (true: dream it; false: sleep through it; nil: not asked tonight).
function LC.DreamAdminTonightChoice(ply)
    local c = IsValid(ply) and ply.lcDreamTonightChoice
    if c and c.night == LC.DreamPlanTonight() then return c.join end
    return nil
end
-- Does she sit this one out? (The Administrator, and it isn't hers: tonight's answer if she gave one, else her tablet's setting.)
function LC.DreamAdminSkips(ply)
    if not (LC.IsAdministrator ~= nil and LC.IsAdministrator(ply)) or LC.DreamAdminChoseTonight(ply) then return false end
    local tonight = LC.DreamAdminTonightChoice(ply)
    if tonight ~= nil then return not tonight end
    return LC.DreamAdminSkipping(ply)
end
-- She answers as she lies down (the owner, 9 November: "add the opt-in for when she actually goes to sleep"): dream tonight's,
-- or sleep through it; remember: make it her tablet's setting too.
function LC.DreamAdminTonight(ply, join, remember)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false end
    ply.lcDreamTonightChoice = { night = LC.DreamPlanTonight(), join = join == true } -- (lcDream...: kept through a dream's putting back)
    if remember then ply:SetPData("lc_dream_skip", join and "0" or "1") end
    Notice(ply, "info", "Tonight's dream", join and "You'll dream it with the city tonight (and you can wake from it whenever you like)."
        or "You'll sleep through tonight's dream.", 6)
    return true
end
-- Lying down on a night with a dream to come that isn't hers: ask her.
function LC.DreamAdminAsk(ply)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) or LC.DreamAdminChoseTonight(ply) then return false end
    if LC.DreamAdminTonightChoice(ply) ~= nil or not (LC.DreamReady and LC.DreamReady()) then return false end
    local ph = Phase()
    if ph ~= "dusk" and ph ~= "night" then return false end -- (a nap in the day isn't tonight)
    if LC.DreamDreamtTonight and LC.DreamDreamtTonight() then return false end
    if not ((LC.DreamTonightPending and LC.DreamTonightPending()) or LC.DreamCityPicks()) then return false end
    net.Start("lc_dream_ask")
    net.WriteTable({ skip = LC.DreamAdminSkipping(ply) })
    net.Send(ply)
    return true
end
hook.Add("LivingCitySleepStarted", "LivingCityDreamPlan", function(ply) LC.DreamAdminAsk(ply) end)
net.Receive("lc_dream_ask", function(_, ply)
    local what, remember = net.ReadString(), net.ReadBool()
    if what == "join" or what == "skip" then LC.DreamAdminTonight(ply, what == "join", remember) end
end)

------------------------------------------------------------------------
-- When a dream begins: its turn taken, the nights remembered
------------------------------------------------------------------------

local function NightNow() return Phase() == "night" and P.night or P.night + 1 end -- (the night a dream starting now belongs to)
hook.Add("LivingCityDreamStarted", "LivingCityDreamPlan", function(dream)
    if not dream or dream.test then return end
    local q = LC.DreamQueued and LC.DreamQueued()
    local kind = LC.DreamKind and LC.DreamKind(dream.ending) or "neutral"
    if q and q.id == dream.ending then
        if q.source == "admin" then dream.adminBy = q.by P.adminNight = NightNow() end
        if LC.DreamPlanNext(q.cat or kind) == dream.ending then Advance(q.cat or kind) end
    elseif LC.DreamPlanNext(kind) == dream.ending then
        Advance(kind)
    end
    local ph = Phase()
    if ph == "night" or ph == "dusk" then
        if kind == "nightmare" or kind == "propaganda" then P.specialNight = NightNow() end
        P.lastKind = kind
    end
    Save()
end)

------------------------------------------------------------------------
-- The words on the black screen
------------------------------------------------------------------------

LC.DreamMoodTexts = {
    calm = {
        "Today the city was calm. You slip off into a happy dream.",
        "The streets were quiet today, and the city breathed easy. Something warm is waiting for you in your sleep.",
        "A good day, as days go here. Your eyes close on something gentle.",
        "Nobody shouted, nobody ran. Tonight, you think, will be a kind night.",
    },
    uneasy = {
        "Today the city felt a bit unsettled. Your dreams may reflect that.",
        "Something was off today: too many footsteps, too few faces. Your sleep will be a strange one.",
        "The city couldn't quite sit still today, and neither can your mind. Whatever comes tonight will be odd.",
        "Not a bad day. Not a good one. Your dreams drift somewhere in between.",
    },
    spared = {
        "The streets were rough today, but the Administrator has left tonight to the city's own dreams. Something strange, not cruel.",
        "It was an ugly day out there. Tonight, at least, nobody is choosing your dreams for you.",
        "Trouble today, and plenty of it. Your sleep doesn't seem to care: it drifts somewhere strange instead.",
    },
    after = {
        "There was trouble on the streets again, but last night's dream still hangs over the city. Tonight, something gentler.",
        "The city is still shaking off last night's dream. Whatever today was, tonight you dream something softer.",
        "Even the worst days end. Last night was dark enough; tonight your sleep goes somewhere stranger, and kinder.",
    },
    murder = {
        "The streets were filled with murder and crime. You expect a nightmare.",
        "A unit died on the streets today, and the whole city felt it. Your sleep won't be kind.",
        "Blood on the pavement, sirens until dark. You know what's coming when you close your eyes.",
        "Someone killed one of them today. The city holds its breath, and your dreams turn cold.",
    },
    red_nightmare = {
        "Sirens wailed all day and the city never settled. Something dark waits behind your eyelids.",
        "The city was on edge from dawn to dusk. Tonight, the edge comes for you.",
        "Nobody felt safe today. Nobody will feel safe tonight, either.",
    },
    red_propaganda = {
        "The city has strayed all day, and the Administration means to set it straight. Even asleep, you will listen.",
        "Today the city forgot itself. Tonight, it will be reminded what it loves.",
        "Unrest, all day long. The Administration has a lesson for you, and sleep is no excuse to miss it.",
    },
    admin_propaganda = {
        "The Administrator feels the citizens need motivation to better themselves and the city, and is keen to instruct you even in your sleep.",
        "The Administrator has words for you tonight. You'll hear them whether you're awake or not.",
        "The Administrator believes in you. She'd like to explain why, at length, in your dreams.",
    },
    admin_nightmare = {
        "The Administrator has decided the city needs reminding what disobedience costs. Tonight, you will be reminded.",
        "The Administrator was not pleased with today. Your sleep will hear about it.",
        "Tonight's dream has been chosen for you, and it was not chosen kindly.",
    },
}
-- The line for why tonight's dream is what it is (a dream picked any other way: its mood's).
function LC.DreamMoodText(why, mood)
    local list = LC.DreamMoodTexts[why or ""]
    if not list then
        list = mood == "happy" and LC.DreamMoodTexts.calm or (mood == "nightmare" and LC.DreamMoodTexts.red_nightmare)
            or (mood == "propaganda" and LC.DreamMoodTexts.admin_propaganda) or LC.DreamMoodTexts.uneasy
    end
    return list[math.random(#list)]
end
-- The day in a line for her tablet (inferred, never a formula).
function LC.DreamDayFeel()
    local day = LC.DreamDayMood()
    if day.murders > 0 then return "Today: blood on the streets. A unit was murdered." end
    if day.bad then return "Today: unrest from dawn on. The city hasn't settled." end
    if day.calm then return "Today: calm. The city is behaving itself." end
    return "Today: unsettled. Not bad, not good."
end

-- The black screen, and its line, for everyone about to dream tonight's dream. q: what's waiting.
function LC.DreamMoodSend(q, at)
    if not q or not q.id then return 0 end
    local kind = LC.DreamKind and LC.DreamKind(q.id) or "neutral"
    local text = LC.DreamMoodText(q.why, kind)
    local list = LC.DreamSleepers and LC.DreamSleepers(LC.DreamMood(q.id), q.id) or {}
    if #list == 0 then return 0 end
    for _, p in ipairs(list) do
        net.Start("lc_dream_mood")
        net.WriteTable({ text = text, til = at or (CurTime() + LC.DreamMoodLead), kind = kind,
            hint = LC.DreamSkipHint and LC.DreamSkipHint(p, q.id) or nil }) -- (earned the right to sit this kind out: sv_livingcity_dreamskip.lua)
        net.Send(p)
    end
    return #list, text
end

------------------------------------------------------------------------
-- Her tablet: what she can do tonight
------------------------------------------------------------------------

function LC.DreamPlanOffice(ply)
    local adm = IsValid(ply) and ply or (LC.HumanAdministrator and LC.HumanAdministrator())
    local ok, why, wait = false, nil, nil
    if adm then ok, why, wait = LC.DreamAdminCanPick(adm) end
    local q = LC.DreamQueued and LC.DreamQueued()
    local mine = q and q.source == "admin" and (not adm or q.by == adm)
    return { canPick = ok or nil, why = not ok and why or nil, wait = wait, feel = LC.DreamDayFeel(),
        chosen = mine and q.cat or nil, skip = adm and LC.DreamAdminSkipping(adm) or nil, every = LC.DreamPickNights }
end
