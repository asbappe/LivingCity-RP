--[[
    Living City: shared dreams

      The owner, 7 November: "take the endings and turn them into 'dreams' that all sleeping
      players can experience together at a set time at night".

      With a dream point placed on the map (the editor's "Point: dream", somewhere out of the
      map), the Administrator can choose a dream for tonight (below). About a minute
      (lc_dream_delay, 60 seconds) after the Administrator says good night (the night
      announcement; or the night coming, if nobody says it), everyone asleep in a bed who hasn't
      opted out dreams it together at the dream point. The rest of the city carries on as if
      nothing happened: no time stop, no vote, no freeze, no reload.

      One dream a night at most, and only when one is waiting for it: the Administrator's pick,
      or with lc_dream_every_night 1 a random one on a night with nothing waiting. Endings set
      off in play (/eatchip, an admin's lc_ending) are the whole city's, as they always were:
      the G-Man is kept for a future endings setup (the owner, 7 November).

      With no dream point, nothing changes: the endings are as they always were.

      Waking up, everything is as it was: before anyone is moved, everything about them is
      written down (where they lay, health and armour, pockets, weapons with their rounds and
      the ammunition carried, survival, credits, standing, XP, rank, faction, job, clothes,
      model, everything saved for them and everything on show about them) in memory and on
      disk (data/livingcity/dreams/<steamid64>.json, so a crash, a disconnect or a map change
      in the middle of one still gives it all back the next time they join). In the dream they
      carry only their hands, and nothing they do counts: nothing picked up, dropped, bought or
      sold, no credits or standing gained or lost, no crimes, nobody really hurt. On waking it
      is all put back, checked field by field (and anything that differs put back again), they
      are back in their bed, still asleep, and the file goes only once it all matches.

      The editor's "Zone: dream" (optional) is the dream's edge: everything the ending puts out
      stays inside it (without one, within lc_dream_radius of the point).

      The Administrator chooses tonight's dream on their tablet, by mood: Happy, Neutral or
      Nightmare (lc_dream_moods). The pick ignores the endings' cooldown, still one dream a night. A dreamer taken out of the ending watches the
      rest, flying only inside the dream and watching only the other dreamers.

      Nightmares are different (the owner, 7 November: "they can opt out if it's a neutral or
      positive dream, not out of a nightmare, and they have to play a nightmare unless they take a
      stimulant to keep themselves awake"): everyone asleep dreams a nightmare, opted out or not,
      and nobody wakes themselves from one until they're out of it (out of lives in a dream you
      play, or taken out of an ending). A stimulant shot (sv_livingcity_vices.lua) keeps you from
      sleeping at all, so a nightmare can't have you.

      Players: C > Settings > Shared dreams (on, or opt out; and "Wake up" in a dream), or
      /dream off, /dream on, /dream wake. Admins: C > Help > Dreams (what's waiting, dream it
      now, wake everyone, put back anyone's things), lc_dream_restore <name>, lc_dream_now.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dream")     -- the admins' window and the dreamer's own state
util.AddNetworkString("lc_dream_act") -- opt out / in, wake up, the admins' buttons

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_dreams", "1", FLAGS, "With a dream point placed, the secret endings are dreams: everyone asleep dreams them together at night, the rest of the city carries on (no dream point: as before)")
local cvDelay   = CreateConVar("lc_dream_delay", "60", FLAGS, "Seconds after the Administrator says good night (the night announcement) before tonight's dream starts")
local cvRadius  = CreateConVar("lc_dream_radius", "1500", FLAGS, "How far from the dream point an ending's people, props and flying may go, with no dream zone placed")
local cvNightly = CreateConVar("lc_dream_every_night", "0", FLAGS, "On a night with no ending waiting, dream a random one anyway (when the cooldown allows)")
local cvCombine = CreateConVar("lc_dream_combine", "6", FLAGS, "Civil Protection units a dream brings along for the endings that have the Combine in them (never the city's own)")
local cvMoods   = CreateConVar("lc_dream_moods", "bus=happy,plane=happy,hard=happy,shalom=happy,bloom=neutral,fire=neutral,base=neutral,harpies=nightmare,marrow=nightmare,water=nightmare,standup=nightmare",
    FLAGS, "Each ending's mood as a dream, for the Administrator's tablet: id=happy, id=neutral or id=nightmare, comma-separated (an ending not listed is neutral)")

local DIR = "livingcity/dreams/"
LC.DreamDir = DIR
local BOOT = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999)) -- (this run of the server)
local S = LC.DreamState or { night = 0, dreamedNight = -1, nextId = 0 }
LC.DreamState = S
LC.DreamSnaps = LC.DreamSnaps or {} -- [steamid64] = the snapshot, in memory (outlasts a disconnect, not a restart)

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) else p:ChatPrint(title .. ": " .. text) end
end
local function Log(level, msg) if LC.Log then LC.Log(level, msg) end end
local function Sid(p) return IsValid(p) and tostring(p:SteamID64()) or nil end

------------------------------------------------------------------------
-- Where: the dream point, and the dream zone
------------------------------------------------------------------------

function LC.DreamPoint()
    local pts = LC.PointsOfKind and LC.PointsOfKind("dream") or {}
    return pts[1]
end
function LC.DreamZone()
    local zs = LC.ZonesOfKind and LC.ZonesOfKind("dream") or {}
    return zs[1]
end
-- Dreams happen: switched on, and a dream point on this map.
function LC.DreamReady() return cvOn:GetBool() and LC.DreamPoint() ~= nil end

------------------------------------------------------------------------
-- Moods: Happy, Neutral or Nightmare (the owner, 7 November: "the administrator can choose a
-- good, happy dream if everyone has been obedient and compliant, but can choose a nightmare")
------------------------------------------------------------------------

LC.DreamMoodOrder = { "happy", "neutral", "nightmare" }
LC.DreamMoodNames = { happy = "Happy", neutral = "Neutral", nightmare = "Nightmare" }
-- Every ending's mood, from lc_dream_moods: { [id] = "happy" | "neutral" | "nightmare" }.
function LC.DreamMoods(str)
    local out = {}
    for k, v in string.gmatch(string.lower(str or cvMoods:GetString() or ""), "([%w_]+)%s*=%s*([%a]+)") do
        if LC.DreamMoodNames[v] then out[k] = v end
    end
    for _, id in ipairs(LC.EndingOrder or {}) do out[id] = out[id] or "neutral" end
    -- (the dreams you play, sv_livingcity_dreamgames.lua: their own mood unless the setting names them)
    for _, id in ipairs(LC.DreamGameOrder or {}) do out[id] = out[id] or (LC.DreamGames[id] and LC.DreamGames[id].mood) or "nightmare" end
    return out
end
-- A dream there is to dream: a secret ending, or one of the dreams you play. Its title.
function LC.DreamKnown(id) return (LC.Endings and LC.Endings[id] ~= nil) or (LC.DreamGames and LC.DreamGames[id] ~= nil) end
function LC.DreamTitle(id)
    if LC.Endings and LC.Endings[id] then return LC.Endings[id].name end
    if LC.DreamGames and LC.DreamGames[id] then return LC.DreamGames[id].name end
    return id
end
local function IsGame(id) return LC.DreamGames ~= nil and LC.DreamGames[id] ~= nil and not (LC.Endings and LC.Endings[id]) end
function LC.DreamMood(id) return LC.DreamMoods()[id] or "neutral" end
-- What the sleepers feel just before it, and the city's line the morning after (by mood).
local MOOD_LINES = {
    happy = "You drift off. Tonight's dream feels warm and light, like a song you used to know.",
    neutral = "You drift off. Tonight's dream feels strange: neither good nor bad, just strange.",
    nightmare = "You drift off, and something is wrong. Tonight's dream feels cold, and close, and hungry.",
}
LC.DreamMoodLines = MOOD_LINES
local MORNING_LINES = {
    happy = "The city slept well last night. People wake up smiling, and can't say why.",
    neutral = "The city slept strangely last night. Nobody quite remembers the dream.",
    nightmare = "The city slept badly last night. People wake shaking, and nobody wants to talk about the dream.",
}

-- Is a spot inside the dream? (air: anywhere above it too, for things that fly)
function LC.DreamHolds(dream, pos, air)
    if not dream or not pos then return true end
    local z = dream.zone
    if z and z.box then
        local b = z.box
        if pos.x < b.mins.x or pos.x > b.maxs.x or pos.y < b.mins.y or pos.y > b.maxs.y then return false end
        return air or (pos.z >= b.mins.z - 64 and pos.z <= b.maxs.z + 64)
    end
    local c, r = z and z.pos or dream.pos, LC.DreamRadius(dream)
    local dx, dy = pos.x - c.x, pos.y - c.y
    if dx * dx + dy * dy > r * r then return false end
    return air or math.abs(pos.z - c.z) <= math.max(400, z and z.r or 0)
end
function LC.DreamRadius(dream)
    local z = dream and dream.zone
    if z and z.box then return math.max(64, math.min(z.box.maxs.x - z.box.mins.x, z.box.maxs.y - z.box.mins.y) / 2) end
    if z then return z.r end
    return math.max(200, cvRadius:GetFloat())
end
-- The flood in a dream: its water fills the dream zone (its box, or the circle round the point, as a
-- square), not the whole view. Sets lc_flood_min / lc_flood_max for the dreamers' games to draw within.
function LC.FloodDreamBounds(dream)
    local z = dream and dream.zone
    local mins, maxs
    if z and z.box then
        mins, maxs = Vector(z.box.mins.x, z.box.mins.y, 0), Vector(z.box.maxs.x, z.box.maxs.y, 0)
    else
        local c, r = z and z.pos or dream.pos, LC.DreamRadius(dream)
        mins, maxs = Vector(c.x - r, c.y - r, 0), Vector(c.x + r, c.y + r, 0)
    end
    SetGlobal2Vector("lc_flood_min", mins)
    SetGlobal2Vector("lc_flood_max", maxs)
    return mins, maxs
end

-- How high things in it may fly (the dream zone's top; no zone, no limit of its own).
function LC.DreamTop(dream)
    local z = dream and dream.zone
    if z and z.box then return z.box.maxs.z end
    return (dream and dream.pos and dream.pos.z or 0) + 100000
end

------------------------------------------------------------------------
-- Who: asleep, and not opted out
------------------------------------------------------------------------

function LC.DreamOptedOut(p) return IsValid(p) and p:GetPData("lc_dream_optout", "0") == "1" end

function LC.Dreaming(p) return IsValid(p) and p.lcDreaming ~= nil end

function LC.DreamersOf(dream)
    local out = {}
    for _, p in ipairs(dream and dream.list or {}) do
        if IsValid(p) and p.lcDreaming == dream.id then out[#out + 1] = p end
    end
    return out
end

-- Asleep in a bed right now, alive, and willing (mood: tonight's; a nightmare takes the
-- unwilling too: only a stimulant keeps you out of one, by keeping you awake). The owner,
-- 8 November: a nightmare is broadcast to everyone asleep outside a Combine-only zone (anyone
-- asleep inside one is spared), and whoever beat the last one is Unbroken for a day.
-- Can't be opted out of or woken from (until out of it): a nightmare, or a propaganda dream (the
-- owner, 8 November: "I don't want these to be skippable"; sv_livingcity_propagandadreams.lua).
function LC.DreamForced(id, mood)
    mood = mood or (id and LC.DreamMood(id)) or "neutral"
    return mood == "nightmare" or (id ~= nil and LC.PropagandaDreams ~= nil and LC.PropagandaDreams[id] == true)
end
function LC.DreamSleepers(mood, id)
    local out = {}
    local forced = LC.DreamForced(id, mood)
    local prop = id ~= nil and LC.PropagandaDreams ~= nil and LC.PropagandaDreams[id] == true
    for _, p in ipairs(player.GetAll()) do
        local spared = (mood == "nightmare" and ((LC.Unbroken and LC.Unbroken(p)) or (LC.CombineZoneAt and LC.CombineZoneAt(p:GetPos()))))
            or (prop and LC.Unbroken and LC.Unbroken(p)) -- (Unbroken: the Combine can't get into your head, propaganda included)
        if p.lcSleep and p:Alive() and not p.lcDreaming and not spared and (forced or not LC.DreamOptedOut(p)) and not (LC.Wired and LC.Wired(p))
            and not (p.InVehicle and p:InVehicle()) then out[#out + 1] = p end
    end
    return out
end
-- Can they wake themselves now? Not from a nightmare, until they're out of it. True, or false and why not.
function LC.DreamCanWake(p)
    local dream = LC.DreamActive
    if not IsValid(p) or not dream or dream.id ~= p.lcDreaming or not (dream.forced or dream.mood == "nightmare") then return true end
    local g = dream.game
    if g and g.pl and g.pl[p] and g.pl[p].done then return true end
    if g and g.star == p then return true end -- (the Administrator starring in a propaganda dream isn't one of its players)
    if p.lcEndSpectating then return true end
    if dream.mood ~= "nightmare" then return false, "You can't wake yourself from this dream. You have to see it through (or be out of it)." end
    return false, "You can't wake yourself from a nightmare. You have to see it through (or be out of it)."
end
-- Wake up, if they may (C > Settings, /dream wake, the dream games' button).
function LC.DreamWakeAsked(p)
    if not IsValid(p) or not p.lcDreaming then return false end
    local ok, why = LC.DreamCanWake(p)
    if not ok then Notice(p, "warn", "A nightmare", why, 6) return false end
    LC.DreamWakeOne(p, "optout")
    return true
end

------------------------------------------------------------------------
-- The snapshot: everything about someone, before they dream
------------------------------------------------------------------------

local VMETA, AMETA = getmetatable(Vector(0, 0, 0)), getmetatable(Angle(0, 0, 0))
local function IsVec(v) if isvector then return isvector(v) end return getmetatable(v) == VMETA end
local function IsAng(v) if isangle then return isangle(v) end return getmetatable(v) == AMETA end
local function IsEnt(v)
    if isentity then return isentity(v) end
    return type(v) == "table" and getmetatable(v) ~= VMETA and getmetatable(v) ~= AMETA and v.GetClass ~= nil and v.IsValid ~= nil
end
local function V(v) return v and { v.x, v.y, v.z } or nil end
local function UnV(t) return istable(t) and Vector(tonumber(t[1]) or 0, tonumber(t[2]) or 0, tonumber(t[3]) or 0) or nil end
local function A(a) return a and { a.p, a.y, a.r } or nil end
local function UnA(t) return istable(t) and Angle(tonumber(t[1]) or 0, tonumber(t[2]) or 0, tonumber(t[3]) or 0) or nil end

-- Saved data (PData): every key the database has for them (and the ones this server has read
-- or written; and, failing both, the ones the gamemode uses by name).
local KNOWN_PDATA = {
    "lce_credits", "lce_standing", "lcf_faction", "lcf_special", "lcf_transhuman", "lcf_wl_admin", "lcf_xp_cp", "lcf_xp_resistance",
    "lcj_job", "lci_inv", "lci_spoil", "lci_line_uses", "lcq_story", "lcq_done", "lc_char", "lc_cid", "lc_desc", "lc_model", "lc_skin",
    "lc_bgs", "lc_docs", "lc_recog", "lc_intake", "lc_registered", "lc_chosen", "lc_housed_how", "lc_close_used", "lc_close_at",
    "lc_unmasked", "lc_transfer_at", "lc_surgery_next", "lc_stalker", "lc_slots", "lc_rent_free_until", "lc_new_face", "lc_legacy",
    "lc_killed", "lc_jailcount", "lc_jail_left", "lc_home_seen", "lc_first_ration", "lc_crippled_until", "lc_burned",
}
-- never put back or taken away: staff's records, time actually played, and the sleep itself
local PDATA_KEEP = {
    lc_dream_optout = true, lc_strikes = true, lc_notes = true, lc_combatlog = true, lc_played_min = true,
    lc_lived = true, lc_lived_full = true, lc_rested_for = true, lc_awake_for = true, lc_hints_off = true, lc_hints_seen = true,
}
LC.DreamPDataKeep = PDATA_KEEP
local function PDataAll(p)
    local out = {}
    if sql and sql.Query and SQLStr then
        local prefixes = {}
        if p.UniqueID then prefixes[#prefixes + 1] = tostring(p:UniqueID()) end -- (the old keys first: the new ones win)
        prefixes[#prefixes + 1] = tostring(p:SteamID64())
        for _, pre in ipairs(prefixes) do
            local rows = sql.Query("SELECT infoid, value FROM playerpdata WHERE infoid LIKE " .. SQLStr(pre .. "[%"))
            for _, r in ipairs(istable(rows) and rows or {}) do
                local k = string.match(tostring(r.infoid or ""), "^[^%[]+%[(.*)%]$")
                if k and r.value ~= nil then out[k] = tostring(r.value) end
            end
        end
    end
    for k, v in pairs(p.lcPData or {}) do if isstring(k) and isstring(v) then out[k] = v end end -- (sv_livingcity_perf.lua keeps every read and write)
    local names = {}
    for _, k in ipairs(KNOWN_PDATA) do names[#names + 1] = k end
    for _, f in ipairs(LCF and LCF.Factions or {}) do names[#names + 1] = "lcf_xp_" .. tostring(f.id) end
    for i = 1, 6 do names[#names + 1] = "lc_slot_" .. i end
    for _, k in ipairs(names) do
        if out[k] == nil then
            local v = p:GetPData(k, nil)
            if v ~= nil then out[k] = tostring(v) end
        end
    end
    for k in pairs(PDATA_KEEP) do out[k] = nil end
    return out
end

-- What's on show about them (networked): every one of theirs the engine will list, and the
-- gamemode's own by name.
local NW2_KNOWN = {
    Bool = { "lc_bolo", "lc_carry_lowered", "lc_chair", "lc_dancing", "lc_end_spectating", "lc_end_taken", "lc_flying", "lc_foreman",
        "lc_handsup", "lc_interrogated", "lc_limp", "lc_marching", "lc_on_toilet", "lc_overweight", "lc_raised", "lc_ration_break",
        "lc_rocking", "lc_seated", "lc_soiled", "lc_stalker", "lc_stink", "lc_tied", "lc_tired", "lc_unhoused", "lc_unit", "lc_unreg",
        "lc_vest", "lc_winded", "lcf_transhuman", "lc_crowd" },
    Float = { "lc_bandaged_until", "lc_blessed_until", "lc_crippled_until", "lc_dazed_until", "lc_detained_until", "lc_downed_until",
        "lc_emboldened_until", "lc_fire", "lc_hanged", "lc_intake_secs", "lc_intake_until", "lc_jail_until", "lc_ko_until",
        "lc_protect_until", "lc_recovering_until", "lc_rested_until", "lc_spotted_until", "lc_stamina", "lc_traitor_until",
        "lc_trespass_until", "lc_urge", "lc_wanted_until", "lcn_hunger", "lcn_parasites", "lcn_thirst" },
    Int = { "lc_block", "lc_close_calls", "lc_hoover_load", "lc_skin", "lc_vest_cap", "lce_credits", "lce_standing", "lcf_rank", "lcf_xp" },
    String = { "lc_act", "lc_bolo_text", "lc_char", "lc_cid", "lc_desc", "lc_intake_doing", "lc_jail_reason", "lc_legacy_title",
        "lc_model", "lc_ration_docked", "lc_soil_need", "lc_spotted_why", "lc_wanted_reason", "lcd_alias", "lcd_disguise", "lcd_title",
        "lcf_faction", "lcf_public_title", "lcf_special", "lcf_title", "lcj_job", "lcu_band", "lcu_progress" },
}
-- the dream's own, the sleep (put back with the bed), and the city's live business with them
local NW2_SKIP = {
    lc_sleeping = true, lc_sleep_done = true, lc_bed_top = true, lc_bed_yaw = true, lc_dreaming = true, lc_dream_optout = true,
    lc_afk = true, lc_directive_until = true, lc_directive_urgent = true, lc_riding = true,
}
local NW2_GET = {
    Bool = function(p, k) return p:GetNW2Bool(k, false) end, Float = function(p, k) return p:GetNW2Float(k, 0) end,
    Int = function(p, k) return p:GetNW2Int(k, 0) end, String = function(p, k) return p:GetNW2String(k, "") end,
    Vector = function(p, k) return p:GetNW2Vector(k, Vector(0, 0, 0)) end, Angle = function(p, k) return p.GetNW2Angle and p:GetNW2Angle(k, Angle(0, 0, 0)) end,
    Entity = function(p, k) return p:GetNW2Entity(k, NULL) end,
}
local NW2_SET = {
    Bool = function(p, k, v) p:SetNW2Bool(k, v == true) end, Float = function(p, k, v) p:SetNW2Float(k, tonumber(v) or 0) end,
    Int = function(p, k, v) p:SetNW2Int(k, math.floor(tonumber(v) or 0)) end, String = function(p, k, v) p:SetNW2String(k, tostring(v or "")) end,
    Vector = function(p, k, v) p:SetNW2Vector(k, v) end, Angle = function(p, k, v) if p.SetNW2Angle then p:SetNW2Angle(k, v) end end,
    Entity = function(p, k, v) p:SetNW2Entity(k, v) end,
}
-- (the engine's own list says what kind each is: a name, or the number Lua gives the kind)
local TYPE_OF = { bool = "Bool", boolean = "Bool", float = "Float", int = "Int", uint = "Int", string = "String", vector = "Vector", angle = "Angle", entity = "Entity",
    [1] = "Bool", [4] = "String", [9] = "Entity", [10] = "Vector", [11] = "Angle" }
local function NW2Kind(info, v)
    local t = info and info.type
    if t ~= nil then
        local k = TYPE_OF[isstring(t) and string.lower(t) or t]
        if k then return k end
    end
    if isbool(v) then return "Bool" elseif isstring(v) then return "String" elseif IsVec(v) then return "Vector" elseif IsAng(v) then return "Angle" elseif IsEnt(v) then return "Entity" end
    return nil -- (a number of no known kind: whole or not, there's no telling which it is)
end
local function NW2All(p)
    local out = {}
    for kind, names in pairs(NW2_KNOWN) do
        for _, k in ipairs(names) do out[k] = { t = kind, v = NW2_GET[kind](p, k) } end
    end
    local tbl = p.GetNW2VarTable and p:GetNW2VarTable()
    for k, info in pairs(istable(tbl) and tbl or {}) do
        if isstring(k) and out[k] == nil and istable(info) then
            local kind = NW2Kind(info, info.value)
            if kind then out[k] = { t = kind, v = info.value } end
        end
    end
    for k in pairs(NW2_SKIP) do out[k] = nil end
    return out
end

-- What the server keeps in memory about them (pockets, papers, notes and the like): every
-- plain value, copied. (Things in the world, and the dream's and the endings' own, are left be.)
local MEM_SKIP = {
    lcPData = true, lcSleep = true, lcBedKey = true, lcBedFrom = true, lcAfk = true, lcLastInput = true, lcStillSince = true,
    lcChatTimes = true, lcChatWarned = true, lcJoinedAt = true, lcWelcomeUntil = true, lcLivedMark = true, lcActionNext = true,
    lcNoPermadeath = false, -- (theirs is put back: the dream sets it while it lasts)
}
local function MemName(k)
    if not isstring(k) or not string.match(k, "^lc%u") or MEM_SKIP[k] then return false end
    for _, pre in ipairs({ "lcEnd", "lcDream", "lcHang", "lcShalom", "lcFire", "lcHora", "lcBloom", "lcPose" }) do
        if string.sub(k, 1, #pre) == pre then return false end
    end
    return true
end
-- A deep copy of a plain value (nil, false: it isn't one).
local function Plain(v, depth, budget)
    local t = type(v)
    if t == "number" or t == "string" or t == "boolean" then return v, true end
    if IsVec(v) then return Vector(v.x, v.y, v.z), true end
    if IsAng(v) then return Angle(v.p, v.y, v.r), true end
    if t ~= "table" or getmetatable(v) ~= nil or depth > 8 then return nil, false end
    local out = {}
    for k, x in pairs(v) do
        budget.n = budget.n - 1
        if budget.n < 0 then return nil, false end
        local kc, okk = Plain(k, depth + 1, budget)
        local xc, okx = Plain(x, depth + 1, budget)
        if not (okk and okx) then return nil, false end
        out[kc] = xc
    end
    return out, true
end
local function Same(a, b, depth)
    depth = depth or 0
    if a == b then return true end
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 0.01 end
    if IsVec(a) and IsVec(b) then return a:DistToSqr(b) < 0.01 end
    if IsAng(a) and IsAng(b) then return math.abs(a.p - b.p) + math.abs(a.y - b.y) + math.abs(a.r - b.r) < 0.01 end
    if type(a) ~= "table" or type(b) ~= "table" or depth > 9 then return false end
    for k, x in pairs(a) do if not Same(x, b[k], depth + 1) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
LC.DreamSame = Same
local function LuaTable(p)
    if p.GetTable then return p:GetTable() end
    return type(p) == "table" and p or {}
end
local function MemAll(p)
    local out = {}
    for k, v in pairs(LuaTable(p)) do
        if MemName(k) then
            local c, ok = Plain(v, 0, { n = 20000 })
            if ok then out[k] = c end
        end
    end
    return out
end

local function Weapons(p)
    local out = {}
    for _, w in ipairs(p.GetWeapons and p:GetWeapons() or {}) do
        local c = w.GetClass and w:GetClass()
        if c then out[#out + 1] = { c = c, c1 = w.Clip1 and w:Clip1() or nil, c2 = w.Clip2 and w:Clip2() or nil } end
    end
    return out
end
local function AmmoAll(p)
    local out = {}
    if p.GetAmmo then
        for id, n in pairs(p:GetAmmo() or {}) do
            local name = game.GetAmmoName and game.GetAmmoName(id) or tostring(id)
            if name and (tonumber(n) or 0) > 0 then out[name] = tonumber(n) end
        end
    end
    return out
end
local function Looks(p)
    local bgs = {}
    for i = 0, math.max(0, (p.GetNumBodyGroups and p:GetNumBodyGroups() or 1) - 1) do bgs[#bgs + 1] = { i, p.GetBodygroup and p:GetBodygroup(i) or 0 } end
    local col = p.GetColor and p:GetColor()
    return {
        model = p.GetModel and p:GetModel() or nil, skin = p.GetSkin and p:GetSkin() or 0, bgs = bgs,
        color = col and { col.r, col.g, col.b, col.a } or nil, material = p.GetMaterial and p:GetMaterial() or "",
        pcolor = p.GetPlayerColor and V(p:GetPlayerColor()) or nil,
    }
end

-- Everything, now.
function LC.DreamSnapshot(p)
    local aw = p.GetActiveWeapon and p:GetActiveWeapon()
    local snap = {
        v = 1, sid = Sid(p), nick = p:Nick(), map = game.GetMap and game.GetMap() or "", boot = BOOT, time = os.time(),
        pos = V(p:GetPos()), ang = A(p:EyeAngles()), alive = p:Alive(),
        hp = p:Health(), maxhp = p:GetMaxHealth(), armor = p.Armor and p:Armor() or 0,
        weapons = Weapons(p), active = IsValid(aw) and aw:GetClass() or nil, ammo = AmmoAll(p),
        looks = Looks(p), pdata = PDataAll(p), nw2 = NW2All(p), mem = MemAll(p),
    }
    -- (their pockets as they are this moment, whatever was last saved: on disk too)
    if istable(p.lcInv) then snap.pdata.lci_inv = util.TableToJSON(p.lcInv) end
    if istable(p.lcSpoil) then snap.pdata.lci_spoil = util.TableToJSON(p.lcSpoil) end
    local s = p.lcSleep
    if s then
        local key = p.lcBedKey
        snap.sleep = { key = key, from = V(p.lcBedFrom), top = V(p:GetNW2Vector("lc_bed_top", Vector(0, 0, 0))), yaw = p:GetNW2Float("lc_bed_yaw", 0),
            t0 = s.t0, done = s.done, slept = s.slept or nil, heal = s.heal, last = s.last }
    end
    return snap
end

-- On disk: no entities, vectors as lists (it outlasts this server).
local function ForDisk(snap)
    local nw2 = {}
    for k, e in pairs(snap.nw2 or {}) do
        if e.t == "Vector" then nw2[k] = { t = e.t, v = V(e.v) }
        elseif e.t == "Angle" then nw2[k] = { t = e.t, v = A(e.v) }
        elseif e.t ~= "Entity" then nw2[k] = { t = e.t, v = e.v } end
    end
    local ammo = {}
    for n, c in pairs(snap.ammo or {}) do ammo[#ammo + 1] = { n, c } end
    return { v = snap.v, sid = snap.sid, nick = snap.nick, map = snap.map, boot = snap.boot, time = snap.time, dream = snap.dream,
        applied = snap.applied, pos = snap.pos, ang = snap.ang, alive = snap.alive, hp = snap.hp, maxhp = snap.maxhp, armor = snap.armor,
        weapons = snap.weapons, active = snap.active, ammo = ammo, looks = snap.looks, pdata = snap.pdata, nw2 = nw2, sleep = snap.sleep }
end
local function FromDisk(t)
    if not istable(t) or not t.sid then return nil end
    local nw2 = {}
    for k, e in pairs(t.nw2 or {}) do
        if istable(e) and e.t then
            if e.t == "Vector" then nw2[k] = { t = e.t, v = UnV(e.v) }
            elseif e.t == "Angle" then nw2[k] = { t = e.t, v = UnA(e.v) }
            else nw2[k] = { t = e.t, v = e.v } end
        end
    end
    local ammo = {}
    for _, a in ipairs(t.ammo or {}) do if istable(a) and a[1] then ammo[tostring(a[1])] = tonumber(a[2]) or 0 end end
    t.nw2, t.ammo = nw2, ammo
    t.weapons = istable(t.weapons) and t.weapons or {}
    t.pdata = istable(t.pdata) and t.pdata or {}
    return t
end
local function FileOf(sid) return DIR .. tostring(sid) .. ".json" end
LC.DreamFileOf = FileOf
function LC.DreamSave(snap)
    if file.CreateDir then file.CreateDir("livingcity") file.CreateDir("livingcity/dreams") end
    local json = util.TableToJSON(ForDisk(snap))
    if not json or json == "" then return false end
    file.Write(FileOf(snap.sid), json)
    -- (read back: only a snapshot that's really there counts)
    local back = file.Read(FileOf(snap.sid), "DATA")
    local t = back and util.JSONToTable(back)
    return istable(t) and t.sid == snap.sid
end
function LC.DreamLoad(sid)
    local raw = file.Read(FileOf(sid), "DATA")
    if not raw or raw == "" then return nil end
    return FromDisk(util.JSONToTable(raw))
end
local function Forget(sid)
    LC.DreamSnaps[sid] = nil
    if file.Exists(FileOf(sid), "DATA") then file.Delete(FileOf(sid)) end
end

------------------------------------------------------------------------
-- Putting it all back, and checking it
------------------------------------------------------------------------

local function SetSleep(p, snap)
    local s = snap.sleep
    if not s then return false end
    local key = s.key
    -- the bed's still theirs (nobody took it while they dreamt)?
    local holder = key and LC.BedSleepers and LC.BedSleepers[key]
    if key and holder ~= nil and holder ~= p and IsValid(holder) then return false end
    p.lcSleep = { t0 = s.t0, done = s.done, slept = s.slept or nil, heal = s.heal, last = CurTime() }
    p:SetNW2Bool("lc_sleeping", true)
    p:SetNW2Float("lc_sleep_done", s.done or 0)
    if key and LC.BedSleepers then LC.BedSleepers[key] = p end
    p.lcBedKey = key
    p.lcBedFrom = UnV(s.from)
    p:SetNW2Vector("lc_bed_top", UnV(s.top) or Vector(0, 0, 0))
    p:SetNW2Float("lc_bed_yaw", s.yaw or 0)
    return true
end

-- Each part, put back (apply) and checked (check: true when it matches). same: this run of the server.
local FIELDS = {}
local function Field(id, apply, check) FIELDS[#FIELDS + 1] = { id = id, apply = apply, check = check } end

Field("looks", function(p, snap)
    local l = snap.looks or {}
    if l.model and p.SetModel and p:GetModel() ~= l.model then p:SetModel(l.model) end
    if p.SetSkin then p:SetSkin(l.skin or 0) end
    for _, b in ipairs(l.bgs or {}) do if p.SetBodygroup then p:SetBodygroup(b[1], b[2]) end end
    if l.color and p.SetColor then p:SetColor(Color(l.color[1], l.color[2], l.color[3], l.color[4])) end
    if p.SetMaterial then p:SetMaterial(l.material or "") end
    if l.pcolor and p.SetPlayerColor then p:SetPlayerColor(UnV(l.pcolor)) end
end, function(p, snap)
    local l = snap.looks or {}
    if l.model and p.GetModel and p:GetModel() ~= l.model then return false end
    if p.GetSkin and (p:GetSkin() or 0) ~= (l.skin or 0) then return false end
    for _, b in ipairs(l.bgs or {}) do if p.GetBodygroup and p:GetBodygroup(b[1]) ~= b[2] then return false end end
    if p.GetMaterial and (p:GetMaterial() or "") ~= (l.material or "") then return false end
    return true
end)

-- (saved text the same, or the same table written out in another order)
local function SameText(a, b)
    a, b = tostring(a), tostring(b)
    if a == b then return true end
    local c1, c2 = string.sub(a, 1, 1), string.sub(b, 1, 1)
    if (c1 == "{" or c1 == "[") and (c2 == "{" or c2 == "[") then
        local ta, tb = util.JSONToTable(a), util.JSONToTable(b)
        return istable(ta) and istable(tb) and Same(ta, tb)
    end
    return false
end
Field("pdata", function(p, snap)
    for k, v in pairs(snap.pdata or {}) do
        if not PDATA_KEEP[k] and not SameText(p:GetPData(k, nil), v) then p:SetPData(k, v) end
    end
    -- anything saved for them in the dream that wasn't there before: gone again
    for k in pairs(PDataAll(p)) do
        if snap.pdata[k] == nil and not PDATA_KEEP[k] and p.RemovePData then p:RemovePData(k) end
    end
    if not snap.same or not snap.mem then
        -- (a new join: what was read from the old values, read again)
        p.lcInv, p.lcSpoil = nil, nil
        if snap.pdata.lce_credits then p:SetNW2Int("lce_credits", tonumber(snap.pdata.lce_credits) or 0) end
        if snap.pdata.lce_standing then p:SetNW2Int("lce_standing", tonumber(snap.pdata.lce_standing) or 0) end
    end
end, function(p, snap)
    for k, v in pairs(snap.pdata or {}) do
        if not PDATA_KEEP[k] and not SameText(p:GetPData(k, nil), v) then return false end
    end
    return true
end)

Field("memory", function(p, snap)
    if not snap.same or not snap.mem then return end
    local t = LuaTable(p)
    -- (only what differs: a table something else holds too stays the same table)
    for k, v in pairs(snap.mem) do if not Same(t[k], v) then t[k] = Plain(v, 0, { n = 20000 }) end end
    for k, v in pairs(t) do
        if MemName(k) and snap.mem[k] == nil and select(2, Plain(v, 0, { n = 20000 })) then t[k] = nil end
    end
end, function(p, snap)
    if not snap.same or not snap.mem then return true end
    local t = LuaTable(p)
    for k, v in pairs(snap.mem) do if not Same(t[k], v) then return false end end
    return true
end)

Field("networked", function(p, snap)
    for k, e in pairs(snap.nw2 or {}) do
        local set, get = NW2_SET[e.t], NW2_GET[e.t]
        if set and get and not NW2_SKIP[k] and not (e.t == "Entity" and (not snap.same or not IsValid(e.v))) and not Same(get(p, k), e.v) then set(p, k, e.v) end
    end
end, function(p, snap)
    for k, e in pairs(snap.nw2 or {}) do
        local get = NW2_GET[e.t]
        if get and not NW2_SKIP[k] and not (e.t == "Entity" and (not snap.same or not IsValid(e.v))) and not Same(get(p, k), e.v) then return false end
    end
    return true
end)

Field("health", function(p, snap)
    if snap.maxhp and p.SetMaxHealth then p:SetMaxHealth(snap.maxhp) end
    if snap.hp then p:SetHealth(snap.hp) end
    if p.SetArmor then p:SetArmor(snap.armor or 0) end
end, function(p, snap)
    return p:Health() == snap.hp and (not snap.maxhp or p:GetMaxHealth() == snap.maxhp) and (not p.Armor or (p:Armor() or 0) == (snap.armor or 0))
end)

local function WeaponOf(p, c)
    if p.GetWeapon then local w = p:GetWeapon(c) if IsValid(w) then return w end end
    for _, w in ipairs(p.GetWeapons and p:GetWeapons() or {}) do if w.GetClass and w:GetClass() == c then return w end end
end
Field("weapons", function(p, snap)
    if p.StripWeapons then p:StripWeapons() end
    for _, w in ipairs(snap.weapons or {}) do
        p:Give(w.c, true) -- (no ammunition with it: theirs goes back below)
        local we = WeaponOf(p, w.c)
        if we then
            if w.c1 and we.SetClip1 then we:SetClip1(w.c1) end
            if w.c2 and we.SetClip2 then we:SetClip2(w.c2) end
        end
    end
    if snap.active and p.SelectWeapon then p:SelectWeapon(snap.active) end
end, function(p, snap)
    local have = {}
    for _, w in ipairs(Weapons(p)) do have[w.c] = w end
    local want = {}
    for _, w in ipairs(snap.weapons or {}) do
        want[w.c] = true
        local h = have[w.c]
        if not h then return false end
        if w.c1 and h.c1 and w.c1 ~= h.c1 then return false end
        if w.c2 and h.c2 and w.c2 ~= h.c2 then return false end
    end
    for c in pairs(have) do if not want[c] then return false end end
    return true
end)

Field("ammo", function(p, snap)
    if not p.GetAmmo then return end
    if p.RemoveAllAmmo then p:RemoveAllAmmo() end
    for name, n in pairs(snap.ammo or {}) do if p.SetAmmo then p:SetAmmo(n, name) end end
end, function(p, snap)
    if not p.GetAmmo then return true end
    local now = AmmoAll(p)
    for name, n in pairs(snap.ammo or {}) do if (now[name] or 0) ~= n then return false end end
    for name, n in pairs(now) do if (snap.ammo or {})[name] == nil and n > 0 then return false end end
    return true
end)

-- Back in their bed, still asleep (this run of the server); a new join on the same map, beside it.
Field("place", function(p, snap)
    if snap.map ~= (game.GetMap and game.GetMap() or "") then return end
    local asleep = snap.same and SetSleep(p, snap)
    local at = UnV(snap.pos)
    if not asleep and snap.sleep and snap.sleep.from then at = UnV(snap.sleep.from) end
    if at then p:SetPos(at) end
    if snap.ang and p.SetEyeAngles then p:SetEyeAngles(UnA(snap.ang)) end
    p.lcDreamPlacedAt = at
end, function(p, snap)
    if snap.map ~= (game.GetMap and game.GetMap() or "") then return true end
    local at = p.lcDreamPlacedAt or UnV(snap.pos)
    return not at or p:GetPos():DistToSqr(at) < 48 * 48
end)
LC.DreamFields = FIELDS

-- Every part that doesn't match (a list of their names).
function LC.DreamCheck(p, snap)
    local bad = {}
    for _, f in ipairs(FIELDS) do
        local ok, same = pcall(f.check, p, snap)
        if not ok or not same then bad[#bad + 1] = f.id end
    end
    return bad
end
local function ApplyFields(p, snap, only)
    local want
    if only then want = {} for _, id in ipairs(only) do want[id] = true end end
    for _, f in ipairs(FIELDS) do
        if not want or want[f.id] then
            local ok, err = pcall(f.apply, p, snap)
            if not ok and LC.Error then LC.Error("dream restore " .. f.id, err) end
        end
    end
    if LC.SendInv then pcall(LC.SendInv, p) end
end

local function Admins(fn) for _, a in ipairs(player.GetAll()) do if a:IsAdmin() then fn(a) end end end

-- Put everything back for someone, then check it twice, putting back again whatever differs;
-- the snapshot goes only once it all matches. done(ok, bad) when it's over.
function LC.DreamRestore(p, snap, done)
    if not IsValid(p) or not snap then if done then done(false, { "nobody" }) end return false end
    snap.same = (snap.boot == BOOT)
    if not p:Alive() and p.Spawn then p:Spawn() end
    ApplyFields(p, snap)
    -- (written down: put back once; a later join doesn't put it all back again over newer things)
    snap.applied = os.time()
    if LC.DreamSnaps[snap.sid] == snap or file.Exists(FileOf(snap.sid), "DATA") then LC.DreamSave(snap) end
    local tries = 0
    local function Pass()
        if not IsValid(p) then if done then done(false, { "left" }) end return end
        local bad = LC.DreamCheck(p, snap)
        if #bad == 0 then
            Forget(snap.sid)
            Log("info", "Dream: " .. p:Nick() .. " woke with everything as it was")
            if done then done(true, bad) end
            return
        end
        tries = tries + 1
        if tries > 2 then
            Log("warn", "Dream: " .. p:Nick() .. " still differs after putting it back (" .. table.concat(bad, ", ") .. "): the snapshot is kept")
            Admins(function(a) Notice(a, "warn", "Dream", p:Nick() .. "'s things don't all match after the dream (" .. table.concat(bad, ", ") ..
                "). The snapshot is kept: C > Help > Dreams, Put back.", 15) end)
            if done then done(false, bad) end
            return
        end
        Log("info", "Dream: putting back again for " .. p:Nick() .. ": " .. table.concat(bad, ", "))
        ApplyFields(p, snap, bad)
        timer.Simple(1, Pass)
    end
    timer.Simple(1, Pass)
    return true
end

------------------------------------------------------------------------
-- Into the dream, and out of it
------------------------------------------------------------------------

local function Enter(p, dream, spot)
    local snap = LC.DreamSnapshot(p)
    snap.dream = dream.id
    if not LC.DreamSave(snap) then
        Log("warn", "Dream: couldn't save " .. p:Nick() .. "'s snapshot to disk: they sleep on, out of it")
        return false
    end
    LC.DreamSnaps[snap.sid] = snap
    dream.snaps[p] = snap
    -- out of the bed without getting up (it stays theirs: LC.BedFree below)
    p.lcSleep = nil
    p:SetNW2Bool("lc_sleeping", false)
    p:SetNW2Float("lc_sleep_done", 0)
    p:SetNW2Vector("lc_bed_top", Vector(0, 0, 0))
    p.lcDreamBed = snap.sleep and snap.sleep.key or nil
    p.lcDreaming = dream.id
    p.lcNoPermadeath = true -- (whatever happens in a dream, nobody's character dies)
    p:SetNW2Bool("lc_dreaming", true)
    p:SetNW2Bool("lc_nightmare", dream.mood == "nightmare") -- (their screen: no waking yourself from this one)
    p:SetNW2Bool("lc_dream_forced", dream.forced == true and dream.mood ~= "nightmare") -- (a propaganda dream: the same, in its own words)
    -- just their hands: nothing to drop, spend or lose
    if p.StripWeapons then p:StripWeapons() end
    if p.RemoveAllAmmo then p:RemoveAllAmmo() end
    p:Give("weapon_lc_hands")
    if p.SelectWeapon then p:SelectWeapon("weapon_lc_hands") end
    p:SetPos(spot)
    if p.SetEyeAngles then p:SetEyeAngles(Angle(0, (dream.pos - spot):Angle().y, 0)) end
    Notice(p, "info", "A dream", "You drift into a dream, with everyone else asleep. Whatever happens here, you wake in your bed with everything you had. "
        .. "To wake up now: C > Settings > Shared dreams: wake up.", 12)
    return true
end

-- Out of the ending, right now (they're waking up while it goes on for the rest).
local function Leave(p)
    if p.lcEndFrozen or (p.IsFrozen and p:IsFrozen()) then p:Freeze(false) end
    p.lcEndFrozen = nil
    if p.SetMoveType then p:SetMoveType(MOVETYPE_WALK) end
    if p.SetNoDraw then p:SetNoDraw(false) end
    if p.SetNotSolid then p:SetNotSolid(false) end
    if p.SetGravity then p:SetGravity(1) end
    if p.lcEndSpectating and p.UnSpectate then p:UnSpectate() if p.Spawn then p:Spawn() end end
    for _, k in ipairs({ "lcEndTaken", "lcEndRide", "lcEndHang", "lcEndUnder", "lcEndSpectating", "lcEndWatching", "lcEndRoam", "lcHang", "lcHangHP",
        "lcShalom", "lcFire", "lcHora", "lcBloomUp", "lcEndModel" }) do p[k] = nil end
    for _, k in ipairs({ "lc_end_taken", "lc_end_spectating", "lc_dancing", "lc_seated", "lc_rocking", "lc_chair", "lc_flying", "lc_limp" }) do p:SetNW2Bool(k, false) end
    p:SetNW2Float("lc_fire", 0)
    p:SetNW2Float("lc_hanged", 0)
    p:SetNW2Entity("lc_riding", NULL)
    -- (their screen: the ending's over for them)
    net.Start("lc_ending")
    net.WriteTable({})
    net.Send(p)
end

-- Wake one dreamer: out of it, and everything put back.
function LC.DreamWakeOne(p, why)
    if not IsValid(p) then return false end
    local sid = Sid(p)
    local snap = LC.DreamSnaps[sid] or LC.DreamLoad(sid)
    local dream = LC.DreamActive
    if p.lcDreaming then
        local E = LC.EndingAny and LC.EndingAny()
        if E and E.dream and E.dream.id == p.lcDreaming then Leave(p) end
        if dream and dream.game and dream.id == p.lcDreaming and LC.DreamGameLeave then LC.DreamGameLeave(p, dream) end
    end
    p.lcDreaming = nil
    p.lcDreamBed = nil
    p:SetNW2Bool("lc_dreaming", false)
    p:SetNW2Bool("lc_nightmare", false)
    p:SetNW2Bool("lc_dream_forced", false)
    if dream and dream.list then
        -- (everyone gone: the ending has nobody left to be for)
        if #LC.DreamersOf(dream) == 0 then timer.Simple(0, function()
            local E = LC.EndingAny and LC.EndingAny()
            if E and E.dream == dream then LC.CancelEnding() end
            if dream.game and LC.DreamGameStop then LC.DreamGameStop(dream, "empty") end
        end) end
    end
    if not snap then
        Log("warn", "Dream: no snapshot for " .. p:Nick() .. " (woke them anyway)")
        return false
    end
    timer.Simple(0.3, function()
        if not IsValid(p) then return end
        LC.DreamRestore(p, snap, function(ok)
            if not IsValid(p) then return end
            hook.Run("LivingCityDreamWoke", p, ok, why)
            if ok then
                Notice(p, "info", why == "optout" and "Awake" or "You wake up", why == "optout" and "You wake from the dream, in your bed, with everything as it was."
                    or "You wake in your bed, with everything just as it was. Press Jump to get up.", 9)
            end
        end)
    end)
    return true
end

-- Everything the dream made (the ending's, and anything else that appeared inside it), gone.
local function CleanUp(dream)
    local E = LC.EndingAny and LC.EndingAny()
    local n = 0
    for e in pairs(dream.made or {}) do
        if IsValid(e) and not e:IsPlayer() then
            local owner = e.GetOwner and e:GetOwner()
            local held = IsValid(owner) and owner.IsPlayer and owner:IsPlayer() and not owner.lcDreaming
            if not held and LC.DreamHolds(dream, e:GetPos(), true) then e:Remove() n = n + 1 end
        end
    end
    for _, e in ipairs(dream.combine or {}) do if IsValid(e) then e:Remove() n = n + 1 end end
    for _, e in ipairs(E and E.dream == dream and E.ents or {}) do if IsValid(e) then e:Remove() n = n + 1 end end
    dream.made = {}
    return n
end
LC.DreamCleanUp = CleanUp

-- The dream's over (the ending called it, or it was cancelled): everyone wakes.
function LC.DreamWake(dream)
    if not dream then return end
    CleanUp(dream)
    for _, p in ipairs(dream.list or {}) do
        if IsValid(p) and p.lcDreaming == dream.id then LC.DreamWakeOne(p, "end") end
    end
    if LC.DreamActive == dream then LC.DreamActive = nil end
    hook.Run("LivingCityDreamEnded", dream)
end

-- The Combine's units a dream brings along (the endings with the Combine in them use these,
-- never the city's own), and its NPCs held still the way the city's are in an ending.
function LC.DreamCast(E)
    local dream = E and E.dream
    if not dream then return end
    local n = math.max(0, cvCombine:GetInt())
    local spots = n > 0 and LC.EndingRingSpots and LC.EndingRingSpots(dream.pos, 260, n) or {}
    for i = 1, n do
        if LC.EndingRoom and not LC.EndingRoom() then break end
        local c = ents.Create("npc_metropolice")
        if IsValid(c) then
            c:SetPos(spots[i] and spots[i].pos or dream.pos)
            c:Spawn()
            if c.Give then c:Give("weapon_stunstick") end
            if c.SetCondition then c:SetCondition(COND_NPC_FREEZE or 67) c.lcDreamHeld = true end -- (held still from the start)
            c.lcDreamCast = true
            E.ents[#E.ents + 1] = c
            dream.combine[#dream.combine + 1] = c
            dream.npcs[c] = { role = "cop", dream = true }
        end
    end
end
local COND_FREEZE = 67 -- (COND_NPC_FREEZE: what npc_freeze does, one NPC at a time)
local function Hold(npc)
    if npc.lcDreamHeld or not npc.SetCondition then return end
    npc.lcDreamHeld = true
    npc:SetCondition(COND_NPC_FREEZE or COND_FREEZE)
end

------------------------------------------------------------------------
-- Starting one
------------------------------------------------------------------------

-- Dream an ending now, with everyone asleep (also: an admin testing it, awake). vote: the G-Man's
-- vote first (among the dreamers). True, or false and why not.
function LC.DreamStart(id, by, vote, also, force)
    if not cvOn:GetBool() then return false, "Dreams are off (lc_dreams 0)." end
    local pt = LC.DreamPoint()
    if not pt then return false, "There's no dream point on this map: place one with the Living City Editor (Point: dream)." end
    local game = IsGame(id)
    if not (LC.Endings and LC.Endings[id]) and not game then return false, "No such ending." end
    if LC.EndingBusy and LC.EndingBusy() then return false, "An ending is already under way." end
    if LC.DreamActive then return false, "A dream is already under way." end
    if not force and not game and LC.EndingCooldownLeft and LC.EndingCooldownLeft() > 0 then return false, "Not yet (" .. math.ceil(LC.EndingCooldownLeft() / 60) .. " minutes of the endings' cooldown left)." end
    local who = LC.DreamSleepers(LC.DreamMood(id), id)
    if IsValid(also) and not also.lcDreaming and also:Alive() and not table.HasValue(who, also) then who[#who + 1] = also end
    if #who == 0 then return false, "Nobody is asleep to dream it." end
    S.nextId = (S.nextId or 0) + 1
    local dream = { id = S.nextId, ending = id, pos = pt.pos, yaw = pt.yaw or 0, zone = LC.DreamZone(), list = {}, snaps = {}, npcs = {}, combine = {},
        made = setmetatable({}, { __mode = "k" }), started = CurTime(), force = force or nil, mood = LC.DreamMood(id), forced = LC.DreamForced(id) }
    local spots = LC.EndingRingSpots and LC.EndingRingSpots(pt.pos, 60, #who) or {}
    for i, p in ipairs(who) do
        local ok, err = pcall(Enter, p, dream, spots[i] and spots[i].pos or pt.pos)
        if ok and err then dream.list[#dream.list + 1] = p elseif not ok and LC.Error then LC.Error("dream enter", err) end
    end
    if #dream.list == 0 then return false, "Nobody could be got ready to dream (their snapshots couldn't be saved)." end
    LC.DreamActive = dream
    LC.DreamPending = dream
    local ok, why
    if game then ok, why = LC.DreamGameStart(dream) -- (a dream you play: its own arena, no ending)
    else ok, why = LC.TriggerEnding(id, by, not vote) end
    LC.DreamPending = nil
    if not ok then
        LC.DreamWake(dream)
        return false, why
    end
    Log("info", string.format("Dream: %s, with %d asleep", id, #dream.list))
    hook.Run("LivingCityDreamStarted", dream)
    return true, dream
end

-- Queue an ending for tonight's dream (the Administrator's pick uses this; kept for a future
-- endings setup to call). source: who chose it. Endings set off in play don't come here: they're
-- the whole city's (the owner, 7 November: dreams are a bonus, the G-Man is kept for the endings).
function LC.DreamQueueEnding(id, by, source)
    if not LC.DreamReady() or not LC.DreamKnown(id) then return false end
    S.queued = { id = id, by = IsValid(by) and by or nil, vote = false, t = os.time(), source = source or "admin" }
    if LC.DayPhase and LC.DayPhase() == "night" and S.dreamedNight ~= S.night then
        S.at, S.warned = math.max(S.at or 0, CurTime() + math.max(5, cvDelay:GetFloat())), nil
    end
    return true
end
function LC.DreamQueued() return S.queued end

-- The Administrator's tablet (sv_livingcity_cityadmin.lua): tonight's dream, by mood.
function LC.DreamOffice()
    local out = { ready = LC.DreamReady(), groups = {} }
    if not cvOn:GetBool() then out.why = "Dreams are switched off on this server."
    elseif not LC.DreamPoint() then out.why = "There's nowhere for the city to dream yet (no dream point on this map)." end
    local moods = LC.DreamMoods()
    for _, m in ipairs(LC.DreamMoodOrder) do
        local g = { mood = m, name = LC.DreamMoodNames[m], endings = {} }
        for _, id in ipairs(LC.EndingOrder or {}) do
            if moods[id] == m then g.endings[#g.endings + 1] = { id = id, name = LC.Endings[id] and LC.Endings[id].name or id } end
        end
        for _, id in ipairs(LC.DreamGameOrder or {}) do
            if moods[id] == m and IsGame(id) then
                local prop = LC.PropagandaDreams and LC.PropagandaDreams[id] -- (sv_livingcity_propagandadreams.lua)
                g.endings[#g.endings + 1] = { id = id, name = (prop and "Propaganda: " or "") .. LC.DreamTitle(id), game = true, propaganda = prop or nil }
            end
        end
        out.groups[#out.groups + 1] = g
    end
    local q = S.queued
    if q and q.source ~= "nightly" then
        out.waiting = { id = q.id, name = LC.DreamTitle(q.id), mood = LC.DreamMoodNames[LC.DreamMood(q.id)], yours = true }
    end
    out.dreamt = (S.dreamedNight == S.night) and LC.DayPhase and LC.DayPhase() == "night" or nil
    out.at = S.at and math.max(0, math.floor(S.at - CurTime())) or nil
    out.busy = LC.DreamActive ~= nil or nil
    return out
end

-- The Administrator picks tonight's dream (id), or none ("none"). True, or false and why not.
-- The pick ignores the endings' cooldown, and there's still one dream a night; it can be changed
-- until the dream begins. (The G-Man has no part in dreams: the owner, 7 November.)
function LC.DreamAdminPick(ply, id)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false, "Only the City Administrator chooses the city's dreams." end
    if not cvOn:GetBool() then return false, "Dreams are switched off on this server." end
    if not LC.DreamPoint() then return false, "There's nowhere for the city to dream yet (no dream point on this map)." end
    local q = S.queued
    id = string.lower(tostring(id or ""))
    if id == "none" or id == "" then
        if q then S.queued = nil end
        Notice(ply, "info", "Tonight's dream", "No dream tonight. The city sleeps without one.", 7)
        return true
    end
    if not LC.DreamKnown(id) then return false, "No such dream." end
    LC.DreamQueueEnding(id, ply, "admin")
    local mood = LC.DreamMoodNames[LC.DreamMood(id)]
    local tonight = not (S.dreamedNight == S.night and LC.DayPhase and LC.DayPhase() == "night")
    if tonight and LC.DayPhase and LC.DayPhase() == "night" then
        S.at, S.warned = math.max(S.at or 0, CurTime() + math.max(5, cvDelay:GetFloat())), nil
    end
    Log("info", "Dream: the Administrator chose " .. id .. " (" .. mood .. ")")
    Notice(ply, "info", "Tonight's dream", string.format("%s (%s). %s", LC.DreamTitle(id), mood,
        tonight and "Everyone asleep will dream it tonight, a minute after you say good night." or "Tonight's dream has been dreamt already: it waits for tomorrow night."), 9)
    return true
end
function LC.DreamForget() S.queued = nil end

-- Tonight's dream, if there's one to dream: the one waiting (or, lc_dream_every_night, any).
-- (lc_dream_every_night: tonight's random one, chosen once, as the warning goes out)
local function Nightly()
    if S.queued or not cvNightly:GetBool() then return S.queued end
    local ok = {}
    for _, id in ipairs(LC.EndingOrder or {}) do if #(LC.EndingSongs and LC.EndingSongs(id) or { 1 }) > 0 then ok[#ok + 1] = id end end
    if #ok > 0 then S.queued = { id = ok[math.random(#ok)], vote = false, t = os.time(), source = "nightly" } end
    return S.queued
end
local function Pick()
    local q = Nightly()
    if q then return q.id, IsValid(q.by) and q.by or nil, q.vote, q.source == "admin" end
    return nil
end
function LC.DreamTonight()
    S.at, S.warned = nil, nil
    S.dreamedNight = S.night
    if not LC.DreamReady() then return false, "no dream point" end
    local id, by, vote, force = Pick()
    if not id then return false, "nothing to dream" end
    local ok, why = LC.DreamStart(id, by, vote, nil, force)
    if ok then
        S.queued, S.lastMood = nil, LC.DreamMood(id)
    else
        Log("info", "Tonight's dream didn't happen: " .. tostring(why))
        if S.queued and S.queued.source == "nightly" then S.queued = nil end
    end
    return ok, why
end

------------------------------------------------------------------------
-- The time: a minute after the Administrator says good night
------------------------------------------------------------------------

hook.Add("LivingCityDayPhase", "LivingCityDreams", function(phase)
    if phase == "night" then
        S.night = (S.night or 0) + 1
        S.at, S.warned = CurTime() + 4 + math.max(5, cvDelay:GetFloat()), nil -- (nobody says it: from the night coming)
    else
        S.at, S.warned = nil, nil
        -- (the morning after a dream: a line for the whole city, by its mood)
        if (phase == "dawn" or phase == "day") and S.lastMood then
            local line = MORNING_LINES[S.lastMood]
            S.lastMood = nil
            if line then for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] " .. line) end end
        end
    end
end)
hook.Add("LivingCityCustomAnnouncement", "LivingCityDreams", function(voice, trig, path)
    if trig ~= "night" or S.dreamedNight == S.night then return end
    local secs = (LC.AnnounceKnownSecs and path and LC.AnnounceKnownSecs(path)) or 0
    S.at, S.warned = CurTime() + math.max(0, secs) + math.max(5, cvDelay:GetFloat()), nil
end)

timer.Create("LivingCityDreams", 1, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        if S.at and LC.DreamReady() and (S.queued or cvNightly:GetBool()) then
            -- the sleepers, warned (and the way out)
            if not S.warned and now >= S.at - math.min(30, cvDelay:GetFloat()) then
                S.warned = true
                local q = Nightly()
                local mood = q and LC.DreamMood(q.id) or "neutral"
                local forced = q and LC.DreamForced(q.id, mood)
                for _, p in ipairs(LC.DreamSleepers(mood, q and q.id)) do
                    Notice(p, mood == "nightmare" and "warn" or "info", "A dream is coming", MOOD_LINES[mood] .. " It's shared with everyone asleep, and you'll wake in your bed with everything you had. "
                        .. (mood == "nightmare" and "There's no opting out of a nightmare: only a stimulant before bed would have kept you awake."
                            or forced and "There's no opting out of this one: only a stimulant before bed would have kept you awake."
                            or "Not tonight? C > Settings > Shared dreams: opt out."), 12)
                end
            end
            if now >= S.at and not (LC.EndingBusy and LC.EndingBusy()) and not LC.DreamActive then LC.DreamTonight() end
        end
        -- in a dream: its NPCs held still, its people kept inside it
        local dream = LC.DreamActive
        local E = LC.EndingAny and LC.EndingAny()
        if dream and dream.game then
            -- (a dream you play keeps its own dreamers in its arena: sv_livingcity_dreamgames.lua)
            if dream.game.stopped then LC.DreamWake(dream) end
        elseif dream and E and E.dream == dream then
            for _, e in ipairs(E.ents or {}) do
                if IsValid(e) and e.IsNPC and e:IsNPC() then
                    Hold(e)
                    if not dream.npcs[e] then dream.npcs[e] = { role = "dream", dream = true } end
                end
            end
            for _, p in ipairs(LC.DreamersOf(dream)) do
                if p.lcEndSpectating then
                    local at = LC.DreamClamp(dream, p:GetPos()) -- (watching: kept inside its edge)
                    if at then p:SetPos(at) end
                elseif not p.lcEndRide and not LC.DreamHolds(dream, p:GetPos()) then
                    p:SetPos(dream.pos + Vector(0, 0, 8)) -- (wandered off the edge of it: back in the middle)
                end
            end
            -- (everyone in it gone, left the server: nobody for it to be for)
            if #LC.DreamersOf(dream) == 0 then LC.CancelEnding() end
        elseif dream and not E then
            LC.DreamWake(dream) -- (the ending went without waking anyone: wake them)
        end
    end)
    if not ok and LC.Error then LC.Error("dreams", err) end
end)

-- The nearest spot inside the dream to pos, for a dreamer who's out of it and watching the rest
-- (drowned, taken, burst into sparkles): nil when it's inside already. In the dream zone's box (up
-- to its top), or without one, within lc_dream_radius and a little above and below the point.
function LC.DreamClamp(dream, pos)
    if not dream or not pos then return nil end
    local z = dream.zone
    local x, y, h, lo, hi = pos.x, pos.y, pos.z, nil, nil
    if z and z.box then
        local b = z.box
        x, y = math.Clamp(x, b.mins.x + 8, b.maxs.x - 8), math.Clamp(y, b.mins.y + 8, b.maxs.y - 8)
        lo, hi = b.mins.z, b.maxs.z - 16
    else
        local c, r = z and z.pos or dream.pos, math.max(32, LC.DreamRadius(dream) - 8)
        local dx, dy = x - c.x, y - c.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > r then x, y = c.x + dx / d * r, c.y + dy / d * r end
        lo, hi = c.z - 400, math.min(LC.DreamTop(dream), c.z + 2000) - 16
    end
    h = math.Clamp(h, lo, math.max(lo, hi))
    if math.abs(x - pos.x) < 0.01 and math.abs(y - pos.y) < 0.01 and math.abs(h - pos.z) < 0.01 then return nil end
    return Vector(x, y, h)
end
-- (flying free while watching: never past the dream's edge, every tick)
hook.Add("SetupMove", "LivingCityDreamWatch", function(p, mv)
    if not p.lcDreaming or not p.lcEndSpectating then return end
    local dream = LC.DreamActive
    if not dream or dream.id ~= p.lcDreaming then return end
    local at = LC.DreamClamp(dream, mv:GetOrigin())
    if at then
        mv:SetOrigin(at)
        mv:SetVelocity(Vector(0, 0, 0))
    end
end)

-- Everything that appears while a dream is on (whatever's inside it at the end goes).
hook.Add("OnEntityCreated", "LivingCityDreams", function(e)
    local dream = LC.DreamActive
    if dream and dream.made and IsValid(e) then dream.made[e] = true end
end)

------------------------------------------------------------------------
-- In a dream, nothing counts
------------------------------------------------------------------------

local function Blocked(p, what)
    if (p.lcDreamToldAt or 0) > CurTime() then return end
    p.lcDreamToldAt = CurTime() + 5
    Notice(p, "info", "Dreaming", (what or "That") .. " will have to wait until you wake up. (C > Settings > Shared dreams: wake up.)", 5)
end
hook.Add("PlayerCanPickupWeapon", "LivingCityDreams", function(p) if p.lcDreaming then return false end end)
hook.Add("PlayerCanPickupItem", "LivingCityDreams", function(p) if p.lcDreaming then return false end end)
hook.Add("LivingCityCrime", "LivingCityDreams", function(p) if IsValid(p) and p.lcDreaming then return false end end)
hook.Add("CanPlayerSuicide", "LivingCityDreams", function(p) if p.lcDreaming then return false end end)
hook.Add("PlayerShouldTakeDamage", "LivingCityDreams", function(p) if p.lcDreaming then return false end end)
hook.Add("EntityTakeDamage", "LivingCityDreams", function(ent) if IsValid(ent) and ent:IsPlayer() and ent.lcDreaming then return true end end)
hook.Add("PlayerSpawnObject", "LivingCityDreams", function(p) if p.lcDreaming then return false end end)

-- (wrapped once every module has loaded: whatever they've put in LC by then)
local NET_OK = { lc_ending_vote = true, lc_dream_act = true, lc_dream = true }
local CMD_OK = { dream = true }
local function Wrap()
    if LC.DreamWrapped then return end
    LC.DreamWrapped = true
    local credits, standing, give, take, inv, sleepIn, bedFree = LC.AddCredits, LC.AddStanding, LC.GiveItem, LC.TakeItem, LC.InvAction, LC.SleepIn, LC.BedFree
    if credits then LC.AddCredits = function(p, ...) if IsValid(p) and p.lcDreaming then return end return credits(p, ...) end end
    if standing then LC.AddStanding = function(p, ...) if IsValid(p) and p.lcDreaming then return end return standing(p, ...) end end
    if give then LC.GiveItem = function(p, ...) if IsValid(p) and p.lcDreaming then return false end return give(p, ...) end end
    if take then LC.TakeItem = function(p, ...) if IsValid(p) and p.lcDreaming then return false end return take(p, ...) end end
    if inv then LC.InvAction = function(p, ...) if IsValid(p) and p.lcDreaming then Blocked(p, "Your pockets") return end return inv(p, ...) end end
    if sleepIn then LC.SleepIn = function(p, ...) if IsValid(p) and p.lcDreaming then return false, "You're already dreaming." end return sleepIn(p, ...) end end
    -- a dreamer's bed is still theirs
    if bedFree then LC.BedFree = function(key, who)
        local e = LC.BedSleepers and LC.BedSleepers[key]
        if IsValid(e) and e ~= who and e.lcDreaming and e.lcDreamBed == key then return false end
        return bedFree(key, who)
    end end
    -- the menus' and windows' messages to the server: only the vote, and waking up
    local allowed = LC.NetAllowed
    if allowed then LC.NetAllowed = function(p, name)
        if IsValid(p) and p.lcDreaming and not NET_OK[name] and not string.find(tostring(name), "^lc_tune") then Blocked(p) return false end
        return allowed(p, name)
    end end
    -- chat commands
    for name, fn in pairs(LC.SlashCommands or {}) do
        if not CMD_OK[name] and type(fn) == "function" then
            LC.SlashCommands[name] = function(p, ...) if IsValid(p) and p.lcDreaming then Blocked(p) return end return fn(p, ...) end
        end
    end
    local run = LC.RunAction
    if run then LC.RunAction = function(p, cmd, ...) if IsValid(p) and p.lcDreaming and not CMD_OK[string.lower(tostring(cmd or ""))] then Blocked(p) return true end return run(p, cmd, ...) end end
    -- the gamemode's console commands (the admin's, the vote and the dream's own still work)
    if concommand and concommand.Run then
        local crun = concommand.Run
        concommand.Run = function(p, cmd, ...)
            local c = string.lower(tostring(cmd or ""))
            if IsValid(p) and p.lcDreaming and string.sub(c, 1, 2) == "lc" and not string.find(c, "^lc_dream") and c ~= "lc_ending_vote" and not p:IsAdmin() then Blocked(p) return true end
            return crun(p, cmd, ...)
        end
    end
end
LC.DreamWrap = Wrap
hook.Add("InitPostEntity", "LivingCityDreams", Wrap)

------------------------------------------------------------------------
-- Players: opting out, and waking up
------------------------------------------------------------------------

function LC.SetDreamOptOut(p, out)
    if not IsValid(p) then return end
    p:SetPData("lc_dream_optout", out and "1" or "0")
    p:SetNW2Bool("lc_dream_optout", out and true or false)
    if out and p.lcDreaming and LC.DreamCanWake(p) then LC.DreamWakeOne(p, "optout") end
    Notice(p, "info", "Shared dreams", out and "You've opted out: you sleep without the city's dreams. (C > Settings > Shared dreams to opt back in.)"
        or "You'll dream with everyone else asleep. You always wake in your bed, with everything you had.", 8)
end

local function DreamCommand(p, rest)
    local a = string.lower(string.Trim(tostring(rest or "")))
    if a == "off" or a == "out" then LC.SetDreamOptOut(p, true)
    elseif a == "on" or a == "in" then LC.SetDreamOptOut(p, false)
    elseif a == "wake" then
        if p.lcDreaming then LC.DreamWakeAsked(p) else p:ChatPrint("[Dreams] You're not dreaming.") end
    else
        p:ChatPrint("[Dreams] Shared dreams are " .. (LC.DreamOptedOut(p) and "off for you" or "on for you") .. ". /dream off, /dream on, /dream wake (or C > Settings).")
    end
end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.dream = DreamCommand

hook.Add("PlayerInitialSpawn", "LivingCityDreams", function(p)
    p:SetNW2Bool("lc_dream_optout", LC.DreamOptedOut(p))
    -- a snapshot left from a dream they didn't wake from here (a crash, a disconnect, a map change): put back
    timer.Simple(6, function()
        if not IsValid(p) or p.lcDreaming then return end
        local sid = Sid(p)
        local snap = LC.DreamSnaps[sid] or LC.DreamLoad(sid)
        if not snap then return end
        if snap.applied then
            Log("info", "Dream: " .. p:Nick() .. " has an old dream snapshot, already put back once (an admin can put it back again: C > Help > Dreams)")
            return
        end
        Log("info", "Dream: " .. p:Nick() .. " left in the middle of a dream: putting everything back")
        LC.DreamRestore(p, snap, function(ok)
            if ok and IsValid(p) then Notice(p, "info", "You wake up", "You'd left in the middle of a dream. Everything you had is just as it was.", 9) end
        end)
    end)
end)

------------------------------------------------------------------------
-- The admins: what's waiting, dream it now, wake everyone, put back
------------------------------------------------------------------------

local function FindPlayer(arg)
    arg = string.lower(tostring(arg or ""))
    if arg == "" then return nil end
    for _, p in ipairs(player.GetAll()) do
        if tostring(p:SteamID64()) == arg or string.lower(p:SteamID()) == arg or string.find(string.lower(p:Nick()), arg, 1, true) then return p end
    end
end
-- Put someone's things back from their snapshot (also an old one already put back once).
function LC.DreamForceRestore(target)
    if not IsValid(target) then return false, "No such player." end
    if target.lcDreaming then LC.DreamWakeOne(target, "admin") return true, target:Nick() .. " is woken, and everything put back." end
    local sid = Sid(target)
    local snap = LC.DreamSnaps[sid] or LC.DreamLoad(sid)
    if not snap then return false, target:Nick() .. " has no dream snapshot." end
    snap.applied = nil
    LC.DreamRestore(target, snap, function(ok, bad)
        if IsValid(target) then Log("info", "Dream: an admin put back " .. target:Nick() .. "'s things: " .. (ok and "all matches" or ("still differs: " .. table.concat(bad or {}, ", ")))) end
    end)
    return true, target:Nick() .. "'s things are being put back from their snapshot."
end

function LC.DreamStatus()
    local saved = {}
    for _, f in ipairs(file.Find(DIR .. "*.json", "DATA") or {}) do
        local sid = string.match(f, "([^/]+)%.json$")
        local snap = sid and (LC.DreamSnaps[sid] or LC.DreamLoad(sid))
        if snap then
            local online
            for _, p in ipairs(player.GetAll()) do if tostring(p:SteamID64()) == sid then online = p end end
            saved[#saved + 1] = { sid = sid, nick = snap.nick or sid, online = IsValid(online), applied = snap.applied ~= nil, time = snap.time }
        end
    end
    local list = {}
    for _, id in ipairs(LC.EndingOrder or {}) do list[#list + 1] = { id = id, name = LC.Endings[id].name } end
    for _, id in ipairs(LC.DreamGameOrder or {}) do if IsGame(id) then list[#list + 1] = { id = id, name = LC.DreamTitle(id) .. " (a dream you play)" } end end
    local d = LC.DreamActive
    return {
        on = cvOn:GetBool(), point = LC.DreamPoint() ~= nil, zone = LC.DreamZone() ~= nil, queued = S.queued and S.queued.id or nil,
        queuedName = S.queued and LC.DreamTitle(S.queued.id) or nil,
        at = S.at and math.max(0, math.floor(S.at - CurTime())) or nil, every = cvNightly:GetBool(), delay = cvDelay:GetFloat(),
        active = d and { ending = d.ending, name = LC.DreamTitle(d.ending), n = #LC.DreamersOf(d) } or nil,
        asleep = #LC.DreamSleepers(), saved = saved, endings = list,
    }
end
local function SendStatus(p)
    net.Start("lc_dream")
    net.WriteTable(LC.DreamStatus())
    net.Send(p)
end

net.Receive("lc_dream_act", function(_, p)
    if not IsValid(p) then return end
    local what, arg = net.ReadString(), net.ReadString()
    if what == "optout" then LC.SetDreamOptOut(p, true) return end
    if what == "optin" then LC.SetDreamOptOut(p, false) return end
    if what == "wake" then LC.DreamWakeAsked(p) return end
    if not p:IsAdmin() then return end
    local msg
    if what == "status" then SendStatus(p) return
    elseif what == "now" then
        local ok, why = LC.DreamStart(arg ~= "" and arg or (S.queued and S.queued.id) or "", p, false, p:IsSuperAdmin() and p or nil)
        if ok and S.queued and S.queued.id == arg then S.queued = nil end
        msg = ok and "The dream begins." or tostring(why)
    elseif what == "wakeall" then
        local E = LC.EndingAny and LC.EndingAny()
        if E and E.dream then LC.CancelEnding() msg = "Everyone in the dream is woken."
        elseif LC.DreamActive and LC.DreamActive.game and LC.DreamGameStop then LC.DreamGameStop(LC.DreamActive, "admin") msg = "Everyone in the dream is woken."
        else msg = "Nobody is dreaming." end
    elseif what == "forget" then S.queued = nil msg = "Nothing waits for tonight's dream now."
    elseif what == "restore" then
        local ok, why = LC.DreamForceRestore(FindPlayer(arg))
        msg = why
    end
    if msg then Notice(p, "info", "Dreams", msg, 6) end
    SendStatus(p)
end)

local function Reply(p, m) if IsValid(p) then p:ChatPrint("[Living City] " .. m) else print("[Living City] " .. m) end end
concommand.Add("lc_dream_restore", function(p, _, args)
    if IsValid(p) and not p:IsAdmin() then return end
    local ok, why = LC.DreamForceRestore(FindPlayer(args[1]))
    Reply(p, why or (ok and "Done." or "No."))
end)
concommand.Add("lc_dream_now", function(p, _, args)
    if IsValid(p) and not p:IsSuperAdmin() then return end
    local id = string.lower(tostring(args[1] or (S.queued and S.queued.id) or ""))
    local ok, why = LC.DreamStart(id, IsValid(p) and p or nil, false, string.lower(tostring(args[2] or "")) == "me" and p or nil)
    Reply(p, ok and ("The dream begins: " .. id) or tostring(why))
end)
