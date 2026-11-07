--[[
    Sealed directives: how the secret endings start (the owner, 2 November; ENDING_TRIGGERS_DRAFT.md)

    Every ending is a sealed directive on the City Administrator's device (right click: the office,
    then Sealed directives): an envelope with a rhyming riddle and a mark that warms (cold, warm, hot)
    as the city gets closer to it. One unlocks when the Administrator runs the city the strange way its
    riddle hints at, or when the city does it by itself in play. Then:

      1. an Administrator playing now (not AFK): theirs to sign or refuse, within
         lc_directive_sign_minutes (20); neither, and it goes down the list
      2. no Administrator, a superadmin online: a popup (start it, put it to the G-Man's vote, let it pass)
      3. no superadmin, an admin online: the same popup
      4. nobody: the G-Man's vote, by itself
      (when the last of them leaves, lc_directive_grace_minutes (10) before it goes down the list: they
      may be rejoining)

    Refused by the Administrator, the G-Man won't take no for an answer: he appears to them ("We'll see
    for long"; later, harsher, "We'll see about that"), word gets around (G-Man dreams for lc_gman_rumour_share percent
    of the players: the Administrator is keeping something from them), and he forces their hand:
    supply crates with guns and charged vests, then the infestation spreading, then more. He comes back
    with the same directive after 30 minutes, then 10, then 7 (lc_gman_return_minutes); refused a fourth
    time, he puts it to everyone's vote. Signed, the ending starts and his escalation stops.

    The G-Man also brings everyone the riddles: lc_gman_dream_chance percent of sleeps are a dream of him
    reciting the warmest one.

    New office orders for the Administrator (the riddles need them): order a blackout (and lift it),
    suspend the morticians, ban weedkiller, a Day of Cleansing, permit worship, an amnesty (every cell
    opened).
]]

LC = LC or {}
local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)

util.AddNetworkString("lc_directives")       -- the envelopes, to the Administrator
util.AddNetworkString("lc_directive_act")    -- sign, refuse, open; a staff member's choice
util.AddNetworkString("lc_directive_staff")  -- the popup for a superadmin or admin
util.AddNetworkString("lc_gman_vision")      -- the G-Man on someone's screen (a visit, a dream, his voice)

local cvOn      = CreateConVar("lc_directives", "0", FLAGS, "(Off: set aside for a future endings setup, the owner, 7 November.) Secret endings start from sealed directives: unlocked by the City Administrator or the city itself, then signed, refused, or put to the G-Man's vote")
local cvSign    = CreateConVar("lc_directive_sign_minutes", "20", FLAGS, "Minutes the Administrator has to sign or refuse an unlocked directive before it goes down the list")
local cvStaff   = CreateConVar("lc_directive_staff_minutes", "5", FLAGS, "Minutes a superadmin or admin has to answer the popup before it goes to the G-Man's vote")
local cvGrace   = CreateConVar("lc_directive_grace_minutes", "10", FLAGS, "Minutes after the last Administrator, superadmin or admin leaves before an unlocked directive goes down the list (they may be rejoining)")
local cvMinP    = CreateConVar("lc_directive_min_players", "4", FLAGS, "Players online before a directive can unlock")
local cvReturn  = CreateConVar("lc_gman_return_minutes", "30,10,7", FLAGS, "After each refusal, minutes before the G-Man brings the directive back (then a fourth refusal goes to everyone's vote)")
local cvRumour  = CreateConVar("lc_gman_rumour_share", "60", FLAGS, "Percent of players who dream of the G-Man's rumours once the Administrator has refused him")
local cvDream   = CreateConVar("lc_gman_dream_chance", "30", FLAGS, "Percent of sleeps that are a dream of the G-Man reciting a riddle")
local cvCrates  = CreateConVar("lc_gman_crates", "6", FLAGS, "Weapon crates the G-Man leaves about the city when he forces the Administrator's hand")

local function Now() return CurTime() end
local function IsAdministrator(p) return IsValid(p) and p:GetNW2String("lcf_faction", "") == "admin" end
local function Away(p) return LC.IsAFK and LC.IsAFK(p) end
local function All(msg) for _, p in ipairs(player.GetAll()) do p:ChatPrint(msg) end end

------------------------------------------------------------------------
-- What the city's been doing
------------------------------------------------------------------------

LC.DirectiveLog = LC.DirectiveLog or {} -- the Administrator's acts: { what, arg, target, t, red, curfew }
local S = LC.DirectiveState or { pvp = {}, deaths = {}, firebombs = {}, drills = {}, night = 0, commendNights = {}, orders = {}, refusals = {}, crates = {} }
LC.DirectiveState = S

local function Recent(list, secs, now)
    local n = 0
    for i = #list, 1, -1 do if now - list[i] <= secs then n = n + 1 else break end end
    return n
end
local function Trim(list, keep) while #list > keep do table.remove(list, 1) end end
local function Logged(what, secs, now, test)
    local n = 0
    for i = #LC.DirectiveLog, 1, -1 do
        local e = LC.DirectiveLog[i]
        if now - e.t > secs then break end
        if e.what == what and (not test or test(e)) then n = n + 1 end
    end
    return n
end
function LC.DirectiveNote(what, arg, target)
    local e = { what = what, arg = arg, target = target, t = Now(), red = LC.Socio == "red", curfew = LC.Event == "curfew", night = S.night }
    LC.DirectiveLog[#LC.DirectiveLog + 1] = e
    Trim(LC.DirectiveLog, 400)
    if what == "commend" and LC.IsNight and LC.IsNight() then S.commendNights[S.night] = true end
    return e
end

hook.Add("PlayerDeath", "LivingCityDirectives", function(victim, inflictor, attacker)
    local now = Now()
    S.deaths[#S.deaths + 1] = now Trim(S.deaths, 200)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then S.pvp[#S.pvp + 1] = now Trim(S.pvp, 100) end
end)
hook.Add("OnNPCKilled", "LivingCityDirectives", function()
    S.deaths[#S.deaths + 1] = Now() Trim(S.deaths, 200)
end)

-- The Administrator's office: the orders below, and every act noted
local ORDERS = {}
local function Wrap()
    if LC.AdminDo and not LC.lcDirectivesWrapped then
        LC.lcDirectivesWrapped = true
        local orig = LC.AdminDo
        LC.AdminDo = function(ply, what, arg, target)
            if ORDERS[what] then
                if not IsAdministrator(ply) then return false, "Only the City Administrator." end
                local ok, why = ORDERS[what](ply, arg)
                if ok then LC.DirectiveNote(what, arg) end
                return ok, why
            end
            local ok, why = orig(ply, what, arg, target)
            if ok ~= false then LC.DirectiveNote(what, arg, target) end
            return ok, why
        end
    end
    if LC.Firebomb and not LC.lcDirFirebomb then
        LC.lcDirFirebomb = true
        local orig = LC.Firebomb
        LC.Firebomb = function(...) S.firebombs[#S.firebombs + 1] = Now() Trim(S.firebombs, 50) return orig(...) end
    end
    if LC.ExerciseFinish and not LC.lcDirDrill then
        LC.lcDirDrill = true
        local orig = LC.ExerciseFinish
        LC.ExerciseFinish = function(...)
            local x = LC.ExerciseSession and LC.ExerciseSession()
            if x and x.people then
                local done, clean, mistakes = 0, 0, 0
                for p, r in pairs(x.people) do
                    if IsValid(p) and p:IsPlayer() and r.done then done = done + 1 if (r.beatings or 0) == 0 then clean = clean + 1 end end
                    mistakes = mistakes + (r.beatings or 0)
                end
                S.drills[#S.drills + 1] = { t = Now(), day = S.night, done = done, clean = clean, mistakes = mistakes }
                Trim(S.drills, 20)
            end
            return orig(...)
        end
    end
    -- weedkiller banned: not issued, and nobody sprays
    if LC.IssueWeedkiller and not LC.lcDirWeed then
        LC.lcDirWeed = true
        local issue, spray = LC.IssueWeedkiller, LC.SprayWeed
        LC.IssueWeedkiller = function(...) if LC.WeedkillerBanned() then return false end return issue(...) end
        if spray then
            LC.SprayWeed = function(ply, ...)
                if LC.WeedkillerBanned() then return false, "Weedkiller is banned, by the Administrator's order." end
                return spray(ply, ...)
            end
        end
    end
end
hook.Add("Initialize", "LivingCityDirectives", Wrap)
hook.Add("InitPostEntity", "LivingCityDirectives", Wrap)
timer.Simple(0, Wrap)

function LC.WeedkillerBanned() return (S.orders.weedkiller or 0) > Now() end
function LC.MorticiansSuspended() return (S.orders.morticians or 0) > Now() end

local function Announce(text) All("[City] " .. text) end
ORDERS.blackout = function(ply)
    if not LC.ForceBlackout then return false end
    LC.ForceBlackout("on")
    S.orders.blackoutAt = Now()
    timer.Create("LivingCityOrderedBlackout", 15 * 60, 1, function() if LC.ForceBlackout then LC.ForceBlackout("auto") end S.orders.blackoutAt = nil end)
    Announce("By order of the City Administrator: the grid is shut down. Stay indoors.")
    return true
end
ORDERS.lift = function(ply)
    if not LC.ForceBlackout then return false end
    LC.ForceBlackout("auto")
    S.orders.blackoutAt = nil
    timer.Remove("LivingCityOrderedBlackout")
    Announce("By order of the City Administrator: power is restored.")
    return true
end
ORDERS.morticians = function(ply)
    S.orders.morticians = Now() + 20 * 60
    Announce("By order of the City Administrator: the morticians are stood down. The dead will wait.")
    return true
end
ORDERS.weedkiller = function(ply)
    S.orders.weedkiller = Now() + 20 * 60
    Announce("By order of the City Administrator: weedkiller is banned. Let the city grow.")
    return true
end
ORDERS.cleansing = function(ply)
    Announce("By order of the City Administrator: a Day of Cleansing. What was seized will burn, in public.")
    return true
end
ORDERS.worship = function(ply)
    S.orders.worship = Now()
    Announce("By order of the City Administrator: Father Grigori's flock may gather and worship, unhindered.")
    return true
end
ORDERS.amnesty = function(ply)
    local n = 0
    for p in pairs(LC.Prisoners or {}) do if IsValid(p) and LC.ReleasePrisoner and LC.ReleasePrisoner(p) then n = n + 1 end end
    Announce("By order of the City Administrator: an amnesty. Every cell is opened (" .. n .. " released).")
    return true
end
LC.DirectiveOrders = ORDERS

------------------------------------------------------------------------
-- The eleven directives: the riddle, and how close the city is (the Administrator's way,
-- the city's own); each returns a list of parts done (true/false) or a number of 0..1
------------------------------------------------------------------------

local function Frac(n, need) return math.Clamp(n / math.max(1, need), 0, 1) end
local function Since(key, cond, now)
    if cond then S[key] = S[key] or now else S[key] = nil end
    return S[key] and (now - S[key]) or 0
end
local function Dancers()
    local ds = {}
    for _, p in ipairs(player.GetAll()) do
        local act = p:GetNW2String("lc_act", "")
        if p:Alive() and (p:GetNW2Bool("lc_dancing", false) or string.find(act, "dance", 1, true)) then ds[#ds + 1] = p end
    end
    if #ds < 2 then return #ds end
    local c = Vector(0, 0, 0)
    for _, p in ipairs(ds) do c = c + p:GetPos() end
    c = c / #ds
    local n = 0
    for _, p in ipairs(ds) do if p:GetPos():Distance(c) < 500 then n = n + 1 end end
    return n
end
local function Burning()
    local n = #ents.FindByClass("entityflame")
    for _, e in ipairs(ents.FindByClass("env_fire")) do n = n + 1 end
    return n
end
local function Bodies()
    local n = 0
    for _, e in ipairs(ents.FindByClass("prop_ragdoll")) do if e:GetNW2Bool("lc_body", false) then n = n + 1 end end
    return n
end
local function DrillDays(need, clean)
    -- the last finished drills, one a day, on days in a row
    local days, last = 0, nil
    for i = #S.drills, 1, -1 do
        local d = S.drills[i]
        if d.done > 0 and (not clean or d.mistakes == 0) then
            if last == nil then days, last = 1, d.day
            elseif d.day == last then -- (the same day)
            elseif d.day == last - 1 then days, last = days + 1, d.day
            else break end
        end
    end
    return Frac(days, need)
end

local D = {
    harpies = {
        riddle = "Lock the streets for curfew, then kill every light; / set three prisoners loose, and they'll return tonight.",
        hint = "Something circles the city at night, waiting for the lights to go out.",
        admin = function(now)
            local cur = LC.Event == "curfew"
            local start = S.curfewAt or now
            return { cur, cur and Logged("blackout", now - start + 1, now) > 0, cur and Logged("pardon", now - start + 1, now) >= 3 }
        end,
        city = function(now) return Frac(Recent(S.pvp, 300, now), 12) end,
    },
    bus = {
        riddle = "Cheap bread and full bowls and a bonus for all: / a city this kind, and the bus comes to call.",
        hint = "A bus with no driver was seen on the overpass. It had a disco ball.",
        admin = function(now)
            return { Logged("prices", 600, now, function(e) return tonumber(e.arg) and tonumber(e.arg) <= 0.76 end) > 0,
                Logged("rations", 600, now, function(e) return e.arg == "generous" end) > 0,
                Logged("bonus", 600, now) > 0, #player.GetAll() >= 6 }
        end,
        city = function(now)
            local lag = Since("lagAt", (S.lagging or false) or (ents.GetEdictCount and ents.GetEdictCount() > 7600), now)
            return Frac(lag, 300)
        end,
    },
    plane = {
        riddle = "Three dawns of drilling, not one left undone, / and the sky opens up for a dance in the sun.",
        hint = "Overwatch logged an airspace violation: one noncompliant aircraft, low over the plaza.",
        admin = function(now) return DrillDays(3, false) end,
        city = function(now)
            local last = S.drills[#S.drills]
            return (last and now - last.t < 600 and last.done >= 5 and last.mistakes == 0) and 1 or 0
        end,
    },
    standup = {
        riddle = "Shame five in an hour while the city burns red: / the crowd wants a show, and the rope's overhead.",
        hint = "Someone's been buying up rope. Nobody will say what for.",
        admin = function(now)
            local seen, n = {}, 0
            for i = #LC.DirectiveLog, 1, -1 do
                local e = LC.DirectiveLog[i]
                if now - e.t > 3600 then break end
                if e.what == "censure" and e.red and IsValid(e.target) and not seen[e.target] then seen[e.target] = true n = n + 1 end
            end
            return Frac(n, 5)
        end,
        city = function(now) return Frac(Since("redAt", LC.Socio == "red", now), 45 * 60) end,
    },
    hard = {
        riddle = "Darken the grid and let nobody mend it: / someone parties in the dark, and nobody can end it.",
        hint = "In the last blackout the lamps flickered in time, like a strobe. Like a beat.",
        admin = function(now)
            local at = S.orders.blackoutAt
            return { at ~= nil, at ~= nil and LC.CityDark == true and now - at >= 600 }
        end,
        city = function(now) return Frac(Since("darkAt", LC.CityDark == true, now), 15 * 60) end,
    },
    shalom = {
        riddle = "One kind word each night, for eight nights through, / and the city joins hands in a ring around you.",
        hint = "Candles in the windows of the blocks. One more each night.",
        admin = function(now)
            local n = 0
            for i = S.night, S.night - 8, -1 do if S.commendNights[i] then n = n + 1 elseif i < S.night then break end end
            return Frac(n, 8)
        end,
        city = function(now) return Frac(Dancers(), 6) end,
    },
    fire = {
        riddle = "Three firebombs fly, then you cleanse what you seize: / now everyone's burning, and not at the knees.",
        hint = "Smoke on the horizon. The Commissary's matches sold out.",
        admin = function(now) return { Recent(S.firebombs, 1800, now) >= 3, Logged("cleansing", 1800, now) > 0 } end,
        city = function(now) return Frac(Burning(), 15) end,
    },
    base = {
        riddle = "Open each cell while the rebels hold ground, / and somebody sets up us the bomb all around.",
        hint = "Civil Intake's terminal flickered: MAIN SCREEN TURN ON.",
        admin = function(now)
            local held = (LC.GrownCount and LC.GrownCount("rebel") or 0) > 0 or LC.Skirmish ~= nil
            return { Logged("amnesty", 1800, now) > 0, held }
        end,
        city = function(now) return 0 end, -- (the master data core to a lab scientist: not yet in the game)
    },
    marrow = {
        riddle = "Send the morticians home, let ten bodies lie: / the dead get up dancing beneath the night sky.",
        hint = "Bones rattling in the bins at night. Probably rats.",
        admin = function(now) return { LC.MorticiansSuspended(), Bodies() >= 10 } end,
        city = function(now)
            return math.max(Frac(Recent(S.deaths, 600, now), 40), Frac(LC.GrownCount and LC.GrownCount("infest") or 0, 8))
        end,
    },
    bloom = {
        riddle = "Ban the poison, let the green take the street; / when the weeds are at full, every foot finds the beat.",
        hint = "Flowers in the cracks of the plaza, more every hour.",
        admin = function(now)
            local max = GetConVar("lc_weeds_max") and GetConVar("lc_weeds_max"):GetInt() or 30
            return { LC.WeedkillerBanned(), #(LC.Weeds and LC.Weeds() or {}) >= max }
        end,
        city = function(now)
            local max = GetConVar("lc_weeds_max") and GetConVar("lc_weeds_max"):GetInt() or 30
            return Frac(Since("weedsAt", #(LC.Weeds and LC.Weeds() or {}) >= max, now), 600)
        end,
    },
    water = {
        riddle = "Give the priest his permit, give his faithful their bread; / the rain will not stop till the water's overhead.",
        hint = "The rain gets heavier every time the flock meets.",
        admin = function(now)
            local w = S.orders.worship
            return { w ~= nil and now - w < 1800, Logged("event", 1800, now, function(e) return e.arg == "rations" end) > 0 }
        end,
        city = function(now) return 0 end, -- (as before: Father Grigori eating the master data core starts it by itself)
    },
}
LC.Directives = D
LC.DirectiveOrder = { "harpies", "bus", "plane", "standup", "hard", "shalom", "fire", "base", "marrow", "bloom", "water" }

local function Parts(v)
    if type(v) == "number" then return v end
    if type(v) ~= "table" or #v == 0 then return 0 end
    local n = 0
    for _, b in ipairs(v) do if b then n = n + 1 end end
    return n / #v
end
-- how close: 0..1 (the closer of the two ways), and whether it's unlocked
function LC.DirectiveHeat(id, now)
    local d = D[id]
    if not d then return 0, false end
    local okA, a = pcall(d.admin, now or Now())
    local okC, c = pcall(d.city, now or Now())
    a = okA and Parts(a) or 0
    c = okC and Parts(c) or 0
    return math.max(a, c), a >= 1 or c >= 1, a >= 1 and "administrator" or "city"
end
local function HeatWord(h) return h >= 0.67 and "hot" or (h >= 0.34 and "warm" or "cold") end

------------------------------------------------------------------------
-- Who decides
------------------------------------------------------------------------

S.offer = S.offer or nil -- { id, stage = "admin"/"staff"/"waiting"/"vote", deadline, to }

local function OnlineAdministrator()
    for _, p in ipairs(player.GetAll()) do if IsAdministrator(p) and not Away(p) then return p end end
end
local function Staff(super)
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if (super and p:IsSuperAdmin()) or (not super and p:IsAdmin() and not p:IsSuperAdmin()) then out[#out + 1] = p end
    end
    return out
end
local function Deciders() return OnlineAdministrator() ~= nil or #Staff(true) > 0 or #Staff(false) > 0 end

function LC.Vision(ply, mode, sound, text)
    net.Start("lc_gman_vision")
    net.WriteString(mode or "visit")
    net.WriteString(sound or "")
    net.WriteString(text or "")
    if ply then net.Send(ply) else net.Broadcast() end
end
-- His three Episode One lines are only in the pre-release Episode One files, so each is a setting:
-- put the file on the server (under garrysmod/sound/, and sync FastDL) and point the setting at it, or
-- use any other line. Missing, it's skipped (the subtitle still shows). Files found are sent to players.
-- (the owner, 2 November: "Not for long" first, "We'll see about that" after: the actor is harsher in that one)
local cvFirst = CreateConVar("lc_gman_line_refused", "vo/episode_1/npc/gman/gman_notforlong.wav", FLAGS, "The G-Man's line when the Administrator first refuses him (\"Not for long\")")
local cvAgain = CreateConVar("lc_gman_line_refused_again", "vo/episode_1/npc/gman/gman_wellseeaboutthat.wav", FLAGS, "The G-Man's line when the Administrator refuses him again (\"We'll see about that\", the harsher one)")
local cvNotThis  = CreateConVar("lc_gman_line_vote_no", "vo/episode_1/npc/gman/gman_notthistime.wav", FLAGS, "The G-Man's line when his vote says no (\"Not this time\")")
local cvCallLine = CreateConVar("lc_gman_line_last_call", "vo/episode_1/npc/gman/gman_comebacknow.wav", FLAGS, "The G-Man's line when the Administrator has lc_directive_last_call_minutes left to answer (\"Come back. Come back here, now.\": splice out \"Oh no, Freeman\")")
local cvAwayLine = CreateConVar("lc_gman_line_walk_away", "vo/episode_1/npc/gman/gman_getbackhere.wav", FLAGS, "The G-Man's line when the Administrator closes an open directive without answering it (\"Get back here...\")")
local cvRivalLine = CreateConVar("lc_gman_line_rival", "livingcity/gman/gman_replacement.wav", FLAGS, "The G-Man's line to the rival he picks after a refusal (Half-Life: Alyx: \"A previous hire has been unable, or unwilling... Until now.\")")
local cvElected  = CreateConVar("lc_gman_line_elected", "vo/citadel/gman_exit05.wav", FLAGS, "The G-Man's line to a newly chosen City Administrator (\"...interesting offers for your services... extraordinary times\")")
local cvCrateLine = CreateConVar("lc_gman_line_crates", "vo/gman_misc/gman_03.wav", FLAGS, "The G-Man's line when someone first looks at one of his crates (\"The right man in the wrong place can make all the difference in the world\")")
local cvGlimpseLine = CreateConVar("lc_gman_line_glimpse", "vo/episode_1/npc/gman/gman_inhale.wav", FLAGS, "The sound when someone glimpses the G-Man about the city (his inhale; empty: silent)")
local cvGlimpses = CreateConVar("lc_gman_glimpses", "1", FLAGS, "As a sealed directive warms up, players now and then glimpse the G-Man about the city, gone when they look again")
local cvGlimpseMin = CreateConVar("lc_gman_glimpse_minutes", "8", FLAGS, "The fewest minutes between one player's glimpses of the G-Man")
local cvRivalMin = CreateConVar("lc_gman_rival_minutes", "30", FLAGS, "Minutes the rival the G-Man picks has to call a recall vote on the Administrator")
local cvLastCall = CreateConVar("lc_directive_last_call_minutes", "5", FLAGS, "Minutes before an unanswered directive passes the Administrator by when the G-Man calls them back to it (0: never)")
local LINES = {
    first = { cvFirst },
    again = { cvAgain, "vo/episode_1/intro/gman_wellseeaboutthat.wav" },
    notthistime = { cvNotThis },
    lastcall = { cvCallLine },
    rival = { cvRivalLine },
    elected = { cvElected },
    crates = { cvCrateLine },
    glimpse = { cvGlimpseLine },
    walkaway = { cvAwayLine },
}
function LC.GmanLine(key)
    for _, p in ipairs(LINES[key] or {}) do
        if type(p) ~= "string" then p = p:GetString() end
        if p ~= "" and (not LC.SoundExists or LC.SoundExists(p)) then return p end
    end
    return ""
end
hook.Add("InitPostEntity", "LivingCityGmanLines", function()
    if not (resource and resource.AddFile) then return end
    for _, list in pairs(LINES) do
        for _, p in ipairs(list) do
            if type(p) ~= "string" then p = p:GetString() end
            if p ~= "" and file.Exists("sound/" .. p, "GAME") then resource.AddFile("sound/" .. p) end
        end
    end
end)

local function SendEnvelopes(ply)
    local now = Now()
    local list = {}
    for i, id in ipairs(LC.DirectiveOrder) do
        local h, open = LC.DirectiveHeat(id, now)
        local offered = S.offer and S.offer.id == id and S.offer.stage == "admin" and S.offer.to == ply
        list[i] = { id = id, riddle = D[id].riddle, heat = HeatWord(h), open = offered, name = offered and (LC.Endings and LC.Endings[id] and LC.Endings[id].name) or nil,
            left = offered and math.max(0, math.floor(S.offer.deadline - now)) or nil }
    end
    net.Start("lc_directives")
    net.WriteTable(list)
    net.Send(ply)
end
LC.SendEnvelopes = SendEnvelopes

-- The reminder on the Administrator's screen (cl_livingcity_directives.lua): the directive waiting, how long
-- they have, and how to open it; urgent (red, pulsing) once the G-Man has called them back to it.
local function Mark(ply, deadline, urgent)
    if not IsValid(ply) then return end
    ply:SetNW2Float("lc_directive_until", deadline or 0)
    ply:SetNW2Bool("lc_directive_urgent", urgent == true)
end
LC.DirectiveMark = Mark
local function Unmark(o) if o and IsValid(o.to) then Mark(o.to, 0, false) end end

local function Start(id, vote, by)
    Unmark(S.offer)
    S.offer = nil
    LC.DirectiveCalm()
    if not LC.TriggerEnding then return false end
    local ok, why = LC.TriggerEnding(id, by, not vote)
    if LC.Log then LC.Log("info", "Sealed directive " .. id .. (vote and " put to the G-Man's vote" or " started") .. (ok and "" or (": " .. tostring(why)))) end
    return ok, why
end
LC.DirectiveStart = Start

local function OfferStaff(o, now)
    local super = Staff(true)
    local who = #super > 0 and super or Staff(false)
    if #who == 0 then return false end
    o.stage, o.deadline, o.to = "staff", now + math.max(1, cvStaff:GetFloat()) * 60, nil
    for _, p in ipairs(who) do
        net.Start("lc_directive_staff")
        net.WriteString(o.id)
        net.WriteString(LC.Endings and LC.Endings[o.id] and LC.Endings[o.id].name or o.id)
        net.WriteString(D[o.id].riddle)
        net.Send(p)
    end
    return true
end

-- An unlocked one: to the first on the list who's here
local function Route(o, now, skipAdmin)
    if not skipAdmin then
        local admin = OnlineAdministrator()
        if admin then
            o.stage, o.deadline, o.to = "admin", now + math.max(1, cvSign:GetFloat()) * 60, admin
            o.called, o.walkedAway = nil, nil
            Mark(admin, o.deadline, false)
            admin:ChatPrint("[???] One of your sealed directives has broken its seal. Your device, the office: Sealed directives.")
            if LC.Notice then LC.Notice(admin, "event", "A seal has broken", "A sealed directive is open on your device (right click: the office, Sealed directives). Sign it or refuse it.", 10) end
            return
        end
    end
    if OfferStaff(o, now) then return end
    -- nobody to decide: wait out the grace (they may be rejoining), then the G-Man's vote
    if S.deciderLeftAt and now - S.deciderLeftAt < math.max(0, cvGrace:GetFloat()) * 60 then
        o.stage, o.deadline = "waiting", S.deciderLeftAt + cvGrace:GetFloat() * 60
        return
    end
    o.stage = "vote"
    Start(o.id, true)
end
LC.DirectiveRoute = Route

hook.Add("PlayerDisconnected", "LivingCityDirectives", function(ply)
    timer.Simple(0, function() if not Deciders() then S.deciderLeftAt = Now() end end)
end)
hook.Add("PlayerInitialSpawn", "LivingCityDirectives", function()
    -- someone who can decide is back: a waiting directive is theirs again
    timer.Simple(5, function() if S.offer and S.offer.stage == "waiting" and Deciders() then Route(S.offer, Now()) end end)
end)

------------------------------------------------------------------------
-- The G-Man forces their hand
------------------------------------------------------------------------

local function CrateSpot()
    if LC.SafeCitizenSpot then local p = LC.SafeCitizenSpot() if p then return p end end
    local pts = LC.PointsOfKind and LC.PointsOfKind("idle") or {}
    if #pts > 0 then return pts[math.random(#pts)].pos + Vector(0, 0, 8) end
end
-- (each player, the first time they look at one of his crates, hears him: once a round of crates)
S.crateRound = S.crateRound or 0
local function DropCrates(n)
    S.crateRound = S.crateRound + 1
    for _ = 1, n do
        local pos = CrateSpot()
        if pos then
            local c = ents.Create("lc_gmancrate")
            if IsValid(c) then
                c:SetPos(pos)
                c:Spawn()
                S.crates[#S.crates + 1] = c
            end
        end
    end
end
local function Spread()
    local seeds = LC.TerritorySeeds and LC.TerritorySeeds("infest") or {}
    if #seeds > 0 and LC.GrowTerritory then pcall(LC.GrowTerritory, seeds[math.random(#seeds)], nil, nil, "something unseen") end
end

-- what each refusal brings, in stages, and when he comes back
local function Escalate(id, level, now)
    S.esc = { id = id, level = level, at = now, rumour = true, spreads = 0 }
    local back = {}
    for m in string.gmatch(cvReturn:GetString(), "[%d%.]+") do back[#back + 1] = tonumber(m) end
    S.esc.returnAt = now + (back[level] or back[#back] or 10) * 60
    local crates = math.max(0, cvCrates:GetInt())
    local function At(mins, fn) S.esc.steps = S.esc.steps or {} S.esc.steps[#S.esc.steps + 1] = { t = now + mins * 60, fn = fn } end
    At(2, function() LC.GmanRival() end) -- (a rival, who may call a recall)
    if level == 1 then
        At(10, function() DropCrates(crates) All("[???] Crates have turned up around the city. Nobody saw who left them.") end)
        At(20, function() S.esc.spreading = true All("[City] The infestation is spreading faster than the crews can hold it.") end)
    elseif level == 2 then
        At(1, function() DropCrates(crates) S.esc.spreading = true end)
        At(4, function() if LC.ForceBlackout then LC.ForceBlackout("on") S.esc.blackout = true end All("[City] The grid is failing, block by block.") end)
    else
        At(0.5, function() DropCrates(crates + 2) S.esc.spreading = true if LC.ForceBlackout then LC.ForceBlackout("on") S.esc.blackout = true end end)
        At(3, function() if LC.StartEvent then pcall(LC.StartEvent, "outbreak") end All("[City] They're out of the infestation, in the streets.") end)
    end
end

-- signed, started, or put to the vote: his hand comes off the city
function LC.DirectiveCalm()
    for _, c in ipairs(S.crates) do if IsValid(c) then c:Remove() end end
    S.crates = {}
    if S.esc and S.esc.blackout and LC.ForceBlackout then LC.ForceBlackout("auto") end
    S.esc = nil
end

function LC.DirectiveAnswer(ply, id, sign)
    local o = S.offer
    if not o or o.id ~= id or o.stage ~= "admin" or o.to ~= ply then return false, "That directive isn't yours to answer." end
    if sign then
        Start(id, false, ply)
        return true
    end
    -- refused
    S.refusals[id] = (S.refusals[id] or 0) + 1
    local n = S.refusals[id]
    Unmark(o)
    S.offer = nil
    if n >= 4 then
        LC.Vision(ply, "visit", LC.GmanLine("again"), "We'll see about that.")
        Start(id, true)
        return true
    end
    LC.Vision(ply, "visit", LC.GmanLine(n == 1 and "first" or "again"), n == 1 and "Not for long." or "We'll see about that.")
    Escalate(id, n, Now())
    return true
end

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

local lastSys
function LC.DirectiveTick(now)
    if not cvOn:GetBool() then return end
    -- the city's clock: nights counted, curfews timed, lag noticed
    local night = LC.IsNight and LC.IsNight() or false
    if night and not S.wasNight then S.night = S.night + 1 end
    S.wasNight = night
    if LC.Event == "curfew" then S.curfewAt = S.curfewAt or now else S.curfewAt = nil end
    local sys = SysTime and SysTime() or now
    if lastSys then S.lagging = (sys - lastSys) > 2.5 end
    lastSys = sys
    -- the G-Man's hand
    local esc = S.esc
    if esc then
        for _, st in ipairs(esc.steps or {}) do if not st.done and now >= st.t then st.done = true pcall(st.fn) end end
        if esc.spreading and esc.spreads < 8 and now >= (esc.nextSpread or 0) then
            esc.nextSpread = now + 60
            esc.spreads = esc.spreads + 1
            Spread()
        end
        if now >= esc.returnAt and not S.offer then
            -- he comes back with the same directive
            local o = { id = esc.id }
            S.offer = o
            local admin = OnlineAdministrator()
            if admin then LC.Vision(admin, "visit", "", "The same directive. Again.") end
            Route(o, now)
        end
    end
    -- an open offer
    local o = S.offer
    if o then
        if o.stage == "admin" and IsValid(o.to) and not o.called and cvLastCall:GetFloat() > 0 and o.deadline - now <= cvLastCall:GetFloat() * 60 and now < o.deadline then
            -- the last call: he appears and calls them back to it, and the reminder turns urgent
            o.called = true
            Mark(o.to, o.deadline, true)
            LC.Vision(o.to, "summon", LC.GmanLine("lastcall"), "Come back. / Come back here, now.")
        end
        if o.stage == "admin" and (not IsValid(o.to) or now >= o.deadline) then
            Unmark(o)
            Route(o, now, true) -- (not answered: down the list)
        elseif o.stage == "staff" and now >= o.deadline then
            o.stage = "vote"
            Start(o.id, true)
        elseif o.stage == "waiting" and (Deciders() or now >= o.deadline) then
            if Deciders() then Route(o, now) else o.stage = "vote" Start(o.id, true) end
        end
        return
    end
    -- anything newly unlocked?
    if #player.GetAll() < cvMinP:GetInt() then return end
    if LC.EndingCooldownLeft and LC.EndingCooldownLeft() > 0 then return end
    if S.esc then return end
    for _, id in ipairs(LC.DirectiveOrder) do
        local _, open = LC.DirectiveHeat(id, now)
        if open then
            S.offer = { id = id }
            if LC.Log then LC.Log("info", "Sealed directive unlocked: " .. id) end
            Route(S.offer, now)
            return
        end
    end
end
timer.Create("LivingCityDirectives", 2, 0, function()
    local ok, err = pcall(LC.DirectiveTick, CurTime())
    if not ok and LC.Error then LC.Error("sealed directives", err) end
end)

------------------------------------------------------------------------
-- Dreams: the riddles, and (after a refusal) the rumours
------------------------------------------------------------------------

local RUMOURS = {
    "The Administrator holds a sealed order meant for all of you, and keeps it in a drawer.",
    "Ask the Administrator what they refused. Ask them why.",
    "The city could be changed tonight. One signature stands in the way.",
    "Your Administrator has been offered a choice, and chose for you.",
}
local function Rumoured(p)
    local pct = math.Clamp(cvRumour:GetFloat(), 0, 100)
    return (tonumber(util.CRC(p:SteamID() .. "gman")) or 0) % 100 < pct
end
local function Warmest(now)
    local best, bh
    for _, id in ipairs(LC.DirectiveOrder) do
        local h = LC.DirectiveHeat(id, now)
        if not bh or h > bh then best, bh = id, h end
    end
    if not best or bh <= 0 then best = LC.DirectiveOrder[math.random(#LC.DirectiveOrder)] end
    return best
end
-- His voice in a dream: any recording in garrysmod/sound/livingcity/gman/ whose name starts with
-- "dream" (dream1.wav, dream_listen.mp3, ...), one at random; with none there, lc_gman_line_dream.
local cvDreamLine = CreateConVar("lc_gman_line_dream", "vo/episode_1/npc/gman/gman_inhale.wav", FLAGS, "The G-Man's sound as he comes into a dream, when no sound/livingcity/gman/dream* recording is on the server (empty: silent)")
local dreamLines
function LC.GmanDreamLines()
    if dreamLines then return dreamLines end
    dreamLines = {}
    for _, ext in ipairs({ "wav", "mp3", "ogg" }) do
        for _, f in ipairs((file.Find("sound/livingcity/gman/dream*." .. ext, "GAME")) or {}) do
            dreamLines[#dreamLines + 1] = "livingcity/gman/" .. f
            if resource and resource.AddFile then resource.AddFile("sound/livingcity/gman/" .. f) end
        end
    end
    table.sort(dreamLines)
    return dreamLines
end
timer.Simple(0, function() pcall(LC.GmanDreamLines) end)
local function DreamLine()
    local list = LC.GmanDreamLines()
    if #list > 0 then return list[math.random(#list)] end
    return cvDreamLine:GetString()
end
function LC.GmanDream(p, now)
    now = now or Now()
    if S.esc and S.esc.rumour and Rumoured(p) then
        LC.Vision(p, "dream", DreamLine(), RUMOURS[math.random(#RUMOURS)])
        return "rumour"
    end
    if math.random(100) <= cvDream:GetFloat() then
        local id = Warmest(now)
        LC.Vision(p, "dream", DreamLine(), D[id].riddle)
        return "riddle"
    end
end
timer.Create("LivingCityGmanDreams", 3, 0, function()
    if not cvOn:GetBool() then return end
    local now = Now()
    for _, p in ipairs(player.GetAll()) do
        local asleep = p:GetNW2Bool("lc_sleeping", false)
        if asleep and not p.lcWasAsleep then pcall(LC.GmanDream, p, now) end
        p.lcWasAsleep = asleep
        -- awake, now and then: a whisper (after a refusal)
        if not asleep and S.esc and S.esc.rumour and Rumoured(p) and now >= (p.lcGmanWhisper or 0) then
            p.lcGmanWhisper = now + math.Rand(300, 600)
            if (p.lcGmanWhisperSeen or 0) > 0 then p:ChatPrint("[???] " .. RUMOURS[math.random(#RUMOURS)]) end
            p.lcGmanWhisperSeen = 1
        end
    end
end)

------------------------------------------------------------------------
-- The device and the popups
------------------------------------------------------------------------

net.Receive("lc_directive_act", function(_, ply)
    local what, id = net.ReadString(), net.ReadString()
    if what == "open" then
        if IsAdministrator(ply) then SendEnvelopes(ply) end
    elseif what == "walkaway" then
        -- the envelope window closed without an answer: once a directive, he calls them back
        local o = S.offer
        if o and o.id == id and o.stage == "admin" and o.to == ply and not o.walkedAway then
            o.walkedAway = true
            LC.Vision(ply, "visit", LC.GmanLine("walkaway"), "Get back here...")
        end
    elseif what == "sign" or what == "refuse" then
        local ok, why = LC.DirectiveAnswer(ply, id, what == "sign")
        if not ok and why then ply:ChatPrint("[???] " .. why) end
    elseif what == "start" or what == "vote" or what == "pass" then
        local o = S.offer
        if not (o and o.id == id and o.stage == "staff" and ply:IsAdmin()) then return end
        if what == "pass" then
            S.offer = nil
            ply:ChatPrint("[???] Very well. It passes, for now.")
        else
            Start(id, what == "vote", ply)
        end
    end
end)

------------------------------------------------------------------------
-- His crates, his rival, the new Administrator, and glimpses of him (the owner, 2 November)
------------------------------------------------------------------------

timer.Create("LivingCityGmanCrateLook", 0.5, 0, function()
    if not S.crates or #S.crates == 0 then return end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and (p.lcCrateHeard or 0) < S.crateRound then
            local tr = p:GetEyeTrace()
            local e = tr and tr.Entity
            if IsValid(e) and e:GetClass() == "lc_gmancrate" and e:GetPos():DistToSqr(p:GetPos()) < 350 * 350 then
                p.lcCrateHeard = S.crateRound
                LC.Vision(p, "voice", LC.GmanLine("crates"), "The right man in the wrong place / can make all the difference in the world.")
            end
        end
    end
end)

-- After a refusal: a rival, someone who could run for the office, is visited and may call a recall
function LC.GmanRival(now)
    now = now or Now()
    local need = GetConVar("lc_admin_hours") and GetConVar("lc_admin_hours"):GetFloat() or 8
    local pool = {}
    for _, p in ipairs(player.GetAll()) do
        if not IsAdministrator(p) and not Away(p) and p:Alive() and (not LC.AdminHours or LC.AdminHours(p) >= need) then pool[#pool + 1] = p end
    end
    if #pool == 0 then return nil end
    local rival = pool[math.random(#pool)]
    rival:SetNW2Float("lc_gman_rival_until", now + math.max(1, cvRivalMin:GetFloat()) * 60)
    LC.Vision(rival, "visit", LC.GmanLine("rival"), "A previous hire has been unable, or unwilling, to perform the tasks laid before him. / We have struggled to find a suitable replacement. Until now.")
    timer.Simple(9, function()
        if IsValid(rival) then rival:ChatPrint("[City] You can now call a vote to remove the City Administrator and take their place: press F1 and choose \"Call a vote to remove the City Administrator\" (or type /recall). You have " .. math.floor(cvRivalMin:GetFloat()) .. " minutes. Civil Protection and the Administration vote.") end
    end)
    return rival
end

-- A new Administrator (elected, or by recall): he pays a visit; and if he's forcing the old one's
-- hand, he brings the directive to the new one soon
hook.Add("LivingCityAdministratorChosen", "LivingCityDirectives", function(ply, how)
    if not cvOn:GetBool() or not IsValid(ply) then return end
    timer.Simple(4, function()
        if IsValid(ply) then LC.Vision(ply, "visit", LC.GmanLine("elected"), "I've received some interesting offers for your services. / These are extraordinary times.") end
    end)
    if S.esc and not S.offer then S.esc.returnAt = math.min(S.esc.returnAt, Now() + 90) end
end)

-- Glimpses: as a directive warms, now and then someone sees him at a distance (their game finds the spot)
util.AddNetworkString("lc_gman_glimpse")
function LC.GmanGlimpseTick(now)
    if not cvOn:GetBool() or not cvGlimpses:GetBool() then return end
    local warmest = 0
    for _, id in ipairs(LC.DirectiveOrder) do warmest = math.max(warmest, (LC.DirectiveHeat(id, now))) end
    if S.esc then warmest = 1 end
    if warmest < 0.34 then return end
    local chance = warmest >= 0.67 and 0.3 or 0.12
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not p:GetNW2Bool("lc_sleeping", false) and now >= (p.lcGlimpseNext or 0) and math.random() < chance then
            p.lcGlimpseNext = now + math.max(1, cvGlimpseMin:GetFloat()) * 60
            net.Start("lc_gman_glimpse")
            net.WriteString(LC.GmanLine("glimpse"))
            net.Send(p)
        end
    end
end
timer.Create("LivingCityGmanGlimpses", 60, 0, function()
    local ok, err = pcall(LC.GmanGlimpseTick, CurTime())
    if not ok and LC.Error then LC.Error("G-Man glimpses", err) end
end)
