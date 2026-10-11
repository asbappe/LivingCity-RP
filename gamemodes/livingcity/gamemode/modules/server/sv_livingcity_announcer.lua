--[[
    Living City: custom announcements, for Overwatch and for the Administrator

      Drop sound files in a voice's folder and the city says them when
      something happens. No code, no list to edit: the file's name says when.

        sound/livingcity/announce/overwatch/curfew1.wav          the Combine PA
        sound/livingcity/announce/administrator/curfew1.wav      the Administrator, warm
        sound/livingcity/announce/administrator/curfew_firm1.wav ... firm (stern, furious the same)
        sound/livingcity/announce/radio/freq7_1.wav              the radios (static, union, freq7)

      One flat folder per voice. A file's name starts with its trigger
      (curfew1, curfew_soon2, ambient_3); for the Administrator, firm, stern
      or furious anywhere in the name is that tone, and no tone word is her
      warm one. (Older layouts, a folder per trigger, still work.)

      They live in their own addon, garrysmod/addons/livingcity_sound/sound/livingcity/announce/...,
      so replacing the gamemode's folder on an update never touches them.
      .wav, .mp3 and .ogg all work. Put as many files in as you like; one
      is picked each time, never the same one twice running. An optional
      text file with the same name (curfew1.txt next to curfew1.wav) is the
      subtitle printed in chat as it plays.

      Triggers (what a file's name starts with)
        events         rations  sweep  curfew  lockdown  raid  supply
                       ended (an event is over: stabilization restored)
        warnings       rations_soon  curfew_soon (two minutes ahead; a sweep,
                       a raid or a supply convoy is a surprise, and a
                       lockdown answers violence, so they have none)
        the city       socio_green  socio_yellow  socio_red
                       dawn  day  dusk  night
                       outbreak  blackout  power_restored
                       skirmish_raid  skirmish_sweep  response (a response squad)
                       breakout  overwatch_drop  block_raided  territory_grew
                       train_arrival  welcome (just for someone joining)
        ambient        general city announcements; also what the Administrator's
                       periodic addresses are made of (lc_breen_broadcasts 1)

      The radio repair bench (sv_livingcity_moregames.lua): what a set plays
      as you turn the dial. Static fills the gaps between stations and blends
      into them as you get close, so long, loopable files work best.
        sound/livingcity/announce/radio/static1.wav    the hiss between stations
        sound/livingcity/announce/radio/union1.wav     an ordinary station (the
                       Union band); none, and the Administrator's ambient
                       recordings are used
        sound/livingcity/announce/radio/freq7_1.wav    the Resistance's pirate
                       band, when a set is tuned to it; its .txt is the line
                       shown on the panel. Anyone within about twenty feet
                       of the set hears it all too.

      The Administrator is a kindly parent with a dash of the cheerful host. Her
      tone is picked per announcement: every trigger has a usual tone (rations
      and the weather warm, a curfew firm, a raid or a response stern, a
      breakout furious), and it goes up a step while the city is on red
      sociostability, and up again when the last ten minutes have seen several
      violent things (raids, skirmishes, breakouts, outbreaks, rebel gains: three
      is a step, six is two). If the tone picked has no recordings she uses the
      nearest one below it, then above it. Old sound/.../breen/ folders still
      count as her warm ones. Overwatch has no tones: it is always cold.

      Overwatch lines replace the built-in one for an event or a sociostability
      change (lc_announce_custom_pct, 100: how often); for everything else they
      are new. The Administrator follows Overwatch a few seconds later, over the
      loudspeakers (the volume is the player's lc_breencast_volume). Files are
      sent to players who join (resource.AddFile); for a big pack, put the
      sounds in a Workshop addon or FastDL instead and the folders still work.

      lc_announce_custom 0/1, lc_announce_custom_pct (100), lc_announce_gap
      (25 s between any two custom announcements of one voice),
      lc_announce_cat_gap (90 s before one trigger can speak again),
      lc_announce_clips (list what was found), lc_announce_rescan,
      lc_announce_say <overwatch|administrator> <trigger> [warm|firm|stern|furious]
      (superadmin, to test), lc_announce_tier <trigger> (what tone she'd use now)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_announce_custom", "1", FLAGS, "Custom Overwatch and Administrator announcements from sound/livingcity/announce/")
local cvPct  = CreateConVar("lc_announce_custom_pct", "100", FLAGS, "Chance (percent) a custom Overwatch line replaces the built-in one for an event")
local cvGap  = CreateConVar("lc_announce_gap", "25", FLAGS, "Seconds between two custom announcements by the same voice")
local cvCat  = CreateConVar("lc_announce_cat_gap", "90", FLAGS, "Seconds before the same trigger can be announced again")

local ROOT = "livingcity/announce/"
local EXT = { wav = true, mp3 = true, ogg = true }

LC.AnnounceTriggers = {
    "rations", "sweep", "curfew", "lockdown", "raid", "supply", "ended",
    "rations_soon", "curfew_soon",
    "socio_green", "socio_yellow", "socio_red", "dawn", "day", "dusk", "night",
    "outbreak", "blackout", "power_restored", "skirmish_raid", "skirmish_sweep", "response",
    "breakout", "overwatch_drop", "block_raided", "territory_grew", "train_arrival", "welcome", "ambient",
}
LC.AnnounceVoices = { "overwatch", "administrator" }
LC.AnnounceTierNames = { "warm", "firm", "stern", "furious" }
-- Other voices with folders of their own, and their triggers: [voice] = { trigger, ... }
LC.AnnounceExtra = { radio = { "static", "union", "freq7" } }
local TIERS = LC.AnnounceTierNames

-- the tone she usually takes for each thing (1 warm .. 4 furious)
local BASE_TIER = {
    rations = 1, supply = 1, ended = 1, rations_soon = 1,
    dawn = 1, day = 1, dusk = 1, night = 1, ambient = 1, welcome = 1, power_restored = 1, train_arrival = 1, socio_green = 1,
    sweep = 2, curfew = 2, curfew_soon = 2, blackout = 2, territory_grew = 2, socio_yellow = 2, outbreak = 2,
    lockdown = 3, raid = 3, skirmish_raid = 3, skirmish_sweep = 3, response = 3, block_raided = 3, overwatch_drop = 3, socio_red = 3,
    breakout = 4,
}
local VIOLENT = { raid = true, skirmish_raid = true, skirmish_sweep = true, breakout = true, outbreak = true, block_raided = true, territory_grew = true, overwatch_drop = true }
local heat = {} -- times of recent violent things

local function Heat()
    local now, n, keep = CurTime(), 0, {}
    for _, t in ipairs(heat) do if now - t < 600 then n = n + 1 keep[#keep + 1] = t end end
    heat = keep
    return n
end

function LC.AnnounceCalm() heat = {} end -- (forget the violence: tests, a fresh map)

local function TierName(t) return TIERS[math.Clamp(t, 1, #TIERS)] end

-- how cross she is about this, right now
function LC.AnnounceTier(trig)
    local t = BASE_TIER[trig] or 1
    if LC.Socio == "red" then t = t + 1 end
    if t >= 2 then
        local h = Heat()
        t = t + (h >= 6 and 2 or h >= 3 and 1 or 0)
    end
    return math.Clamp(t, 1, #TIERS)
end

local TITLES = {
    outbreak = "Outbreak", blackout = "Power failure", power_restored = "Power restored", skirmish_raid = "Overwatch response",
    skirmish_sweep = "Overwatch response", breakout = "Prison breakout", overwatch_drop = "Overwatch deployment",
    block_raided = "Housing block inspection", territory_grew = "Resistance activity", train_arrival = "Arrivals",
    welcome = "Welcome", dawn = "City announcement", day = "City announcement", dusk = "City announcement", night = "City announcement",
    ambient = "City announcement", response = "Overwatch response",
}

------------------------------------------------------------------------
-- What's in the folders
------------------------------------------------------------------------

local cache = {} -- [voice .. "/" .. trigger] = { { path, text }, ... }

-- The Administrator's tone from a file's name: firm, stern or furious in it,
-- else warm (1 warm .. 4 furious).
function LC.AnnounceToneOf(name)
    local n = string.lower(name or "")
    if string.find(n, "furious", 1, true) then return 4 end
    if string.find(n, "stern", 1, true) then return 3 end
    if string.find(n, "firm", 1, true) then return 2 end
    return 1
end

-- tier: only the files of that tone (by name); nil: every file
local function ScanDir(out, rel, tier)
    local dir = "sound/" .. ROOT .. rel
    local names = file.Find(dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, name in ipairs(names) do
        local base, ext = string.match(name, "^(.*)%.([%w]+)$")
        if base and EXT[string.lower(ext)] and (not tier or LC.AnnounceToneOf(base) == tier) then
            local text = file.Read(dir .. "/" .. base .. ".txt", "GAME")
            text = text and string.Trim(text) or nil
            if text == "" then text = nil end
            out[#out + 1] = { path = ROOT .. rel .. "/" .. name, text = text }
            if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. rel .. "/" .. name) end
        end
    end
end

-- Which trigger a flat file is for: the trigger its name starts with (the
-- longest that fits, so curfew_soon1 isn't curfew), followed by nothing,
-- a number or a separator. nil: none of them.
function LC.AnnounceTriggerOf(base, list)
    local n = string.lower(base or "")
    local best
    for _, t in ipairs(list or LC.AnnounceTriggers) do
        if string.sub(n, 1, #t) == t and (not best or #t > #best) then
            local rest = string.sub(n, #t + 1, #t + 1)
            if rest == "" or not string.match(rest, "%a") then best = t end
        end
    end
    return best
end

-- One voice's own folder, flat: every file named for its trigger
-- (curfew1.wav, curfew_firm2.wav, freq7_1.wav).
local function FlatDir(out, voice, trig, tier, list)
    local dir = "sound/" .. ROOT .. voice
    local names = file.Find(dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, name in ipairs(names) do
        local base, ext = string.match(name, "^(.*)%.([%w]+)$")
        if base and not string.find(name, "/", 1, true) and EXT[string.lower(ext)] and LC.AnnounceTriggerOf(base, list) == trig
            and (not tier or LC.AnnounceToneOf(base) == tier) then
            local text = file.Read(dir .. "/" .. base .. ".txt", "GAME")
            text = text and string.Trim(text) or nil
            if text == "" then text = nil end
            out[#out + 1] = { path = ROOT .. voice .. "/" .. name, text = text }
            if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. voice .. "/" .. name) end
        end
    end
end

local function VoiceName(v)
    v = string.lower(tostring(v or ""))
    return v == "breen" and "administrator" or v
end

-- tier: 1 to 4 for the Administrator (1 is the trigger's own folder), nil for Overwatch
local function Scan(voice, trig, tier)
    voice = VoiceName(voice)
    local key = voice .. "/" .. trig .. "/" .. (voice == "administrator" and (tier or 1) or 0)
    if cache[key] then return cache[key] end
    local out = {}
    -- the voice's own folder, flat: the trigger (and her tone) are in the file name
    FlatDir(out, voice, trig, voice == "administrator" and (tier or 1) or nil, LC.AnnounceExtra[voice])
    if voice == "administrator" then
        tier = tier or 1
        ScanDir(out, "administrator/" .. trig, tier) -- (older: a folder per trigger)
        if tier <= 1 then
            ScanDir(out, "breen/" .. trig, 1) -- (the old folder name)
        else
            ScanDir(out, "administrator/" .. trig .. "/" .. TierName(tier)) -- (the old way: a folder per tone)
        end
    else
        ScanDir(out, voice .. "/" .. trig)
    end
    cache[key] = out
    return out
end

function LC.AnnounceClips(voice, trig, tier) return Scan(voice, trig, tier) end

-- the tone she'll actually use: the one asked for, else the nearest below it, then above
local function ResolveTier(trig, want)
    for t = want, 1, -1 do if #Scan("administrator", trig, t) > 0 then return t end end
    for t = want + 1, #TIERS do if #Scan("administrator", trig, t) > 0 then return t end end
    return nil
end

function LC.AnnounceRescan()
    cache = {}
    local n = 0
    for _, v in ipairs(LC.AnnounceVoices) do
        for _, t in ipairs(LC.AnnounceTriggers) do
            if v == "administrator" then
                for k = 1, #TIERS do n = n + #Scan(v, t, k) end
            else
                n = n + #Scan(v, t)
            end
        end
    end
    for v, trigs in pairs(LC.AnnounceExtra) do for _, t in ipairs(trigs) do n = n + #Scan(v, t) end end
    return n
end

-- The radio repair bench's recordings: "static", "union" or "freq7". Path and subtitle, or nil.
function LC.RadioClip(trig)
    local path, text = LC.PickAnnounceClip("radio", trig)
    if not path and trig == "union" then path = LC.PickAnnounceClip("administrator", "ambient", false, 1) text = nil end
    return path, text
end

local lastPicked = {}
-- A clip for this trigger, never the one before it. useChance: honour
-- lc_announce_custom_pct (when it replaces a built-in line).
function LC.PickAnnounceClip(voice, trig, useChance, tier)
    if not cvOn:GetBool() then return nil end
    voice = VoiceName(voice)
    local clips
    local used = 0
    if voice == "administrator" then
        used = ResolveTier(trig, tier or LC.AnnounceTier(trig))
        if not used then return nil end
        clips = Scan(voice, trig, used)
    else
        clips = Scan(voice, trig)
    end
    if #clips == 0 then return nil end
    if useChance and math.random(100) > cvPct:GetInt() then return nil end
    local key = voice .. "/" .. trig .. "/" .. used
    local pick = math.random(#clips)
    if #clips > 1 and lastPicked[key] == pick then pick = pick % #clips + 1 end
    lastPicked[key] = pick
    return clips[pick].path, clips[pick].text, used > 0 and used or nil
end

------------------------------------------------------------------------
-- Saying them
------------------------------------------------------------------------

local voiceNext = {} -- [voice] = earliest time for the next one
local trigNext = {}  -- [voice/trigger] = earliest time for this trigger again

local function Say(voice, trig, only, force, tier)
    if not cvOn:GetBool() then return false end
    voice = VoiceName(voice)
    local now = CurTime()
    if not force and ((voiceNext[voice] or 0) > now or (trigNext[voice .. "/" .. trig] or 0) > now) then return false end
    if voice == "administrator" and (LC.LiveSpeaker or LC.LiveNPC) then return false end -- somebody is already on air
    local path, text, used = LC.PickAnnounceClip(voice, trig, false, tier)
    if not path then return false end
    voiceNext[voice] = now + cvGap:GetFloat()
    trigNext[voice .. "/" .. trig] = now + cvCat:GetFloat()
    local to = only and { only } or nil
    if voice == "overwatch" then
        net.Start("lc_announce")
        net.WriteString(path)
        net.WriteString(TITLES[trig] or "City announcement")
        if to then net.Send(to) else net.Broadcast() end
        for _, p in ipairs(to or player.GetAll()) do
            if text then p:ChatPrint("[" .. (TITLES[trig] or "City announcement") .. "] \"" .. text .. "\"") end
        end
    else
        local hear = to or (LC.BreencastListeners and LC.BreencastListeners()) or player.GetAll()
        if #hear > 0 then
            net.Start("lc_breencast")
            net.WriteString(path)
            net.Send(hear)
            if text then for _, p in ipairs(hear) do p:ChatPrint("[" .. (LC.AdministratorName and LC.AdministratorName() or "The Administrator") .. "] \"" .. text .. "\"") end end
        end
    end
    hook.Run("LivingCityCustomAnnouncement", voice, trig, path, used)
    return true
end
LC.CustomAnnounce = Say

-- Both voices for one thing happening: Overwatch first, the Administrator a few seconds after.
-- built-in: Overwatch already spoke for this one (an event or a sociostability change),
-- so only the Administrator is added here.
local function Trigger(trig, opts)
    if not LC.Running then return end
    opts = opts or {}
    local d = opts.delay or 3
    if VIOLENT[trig] then heat[#heat + 1] = CurTime() end
    if not opts.builtin then
        timer.Simple(d, function() Say("overwatch", trig, opts.only, opts.force) end)
    end
    timer.Simple(d + (opts.breenAfter or 9), function() Say("administrator", trig, opts.only, opts.force, opts.tier) end)
end
LC.TriggerAnnouncements = Trigger

------------------------------------------------------------------------
-- What triggers them
------------------------------------------------------------------------

hook.Add("LivingCityEventStarted", "LivingCityAnnouncer", function(name)
    Trigger(name, { builtin = true, force = true, breenAfter = 14 })
end)
hook.Add("LivingCityEventSoon", "LivingCityAnnouncer", function(name)
    -- only the routine ones are announced ahead: a sweep or a raid is a surprise
    if name and LC.PublicEvents and LC.PublicEvents[name] then Trigger(name .. "_soon", { delay = 1, breenAfter = 8 }) end
end)
hook.Add("LivingCityEventEnded", "LivingCityAnnouncer", function(was)
    if was ~= "curfew" and was ~= "lockdown" then return end -- (the ones Overwatch says "restored" for)
    timer.Simple(1, function()
        if not LC.Event then Trigger("ended", { builtin = true, breenAfter = 12 }) end -- (not if another event has begun already)
    end)
end)
hook.Add("LivingCitySocioChanged", "LivingCityAnnouncer", function(level)
    Trigger("socio_" .. tostring(level), { builtin = true, breenAfter = 12 })
end)
hook.Add("LivingCityDayPhase", "LivingCityAnnouncer", function(phase) Trigger(phase, { delay = 4 }) end)
hook.Add("LivingCityOutbreak", "LivingCityAnnouncer", function() Trigger("outbreak") end)
hook.Add("LivingCityBlackout", "LivingCityAnnouncer", function(on)
    if on then Trigger("blackout", { delay = 1, breenAfter = 10 }) else Trigger("power_restored") end
end)
hook.Add("LivingCitySkirmish", "LivingCityAnnouncer", function(kind) Trigger("skirmish_" .. tostring(kind)) end)
hook.Add("LivingCityBreakout", "LivingCityAnnouncer", function() Trigger("breakout") end)
hook.Add("LivingCityOverwatchDrop", "LivingCityAnnouncer", function() Trigger("overwatch_drop") end)
hook.Add("LivingCityBlockRaided", "LivingCityAnnouncer", function() Trigger("block_raided") end)
hook.Add("LivingCityTerritoryGrew", "LivingCityAnnouncer", function() Trigger("territory_grew") end)
hook.Add("LivingCityTrainArrived", "LivingCityAnnouncer", function() Trigger("train_arrival", { delay = 2 }) end)
hook.Add("LivingCityResponseSquad", "LivingCityAnnouncer", function() Trigger("response", { builtin = true }) end)

-- The welcome, just for them (also for a new person arriving: sv_livingcity_intake.lua).
function LC.AnnounceWelcome(ply)
    if not IsValid(ply) then return end
    Say("overwatch", "welcome", ply, true)
    timer.Simple(9, function() if IsValid(ply) then Say("administrator", "welcome", ply, true) end end)
end

-- a few seconds after someone joins, just for them
hook.Add("PlayerInitialSpawn", "LivingCityAnnouncer", function(ply)
    timer.Simple(20, function()
        if not IsValid(ply) then return end
        Say("overwatch", "welcome", ply, true)
        timer.Simple(9, function() if IsValid(ply) then Say("administrator", "welcome", ply, true) end end)
    end)
end)

hook.Add("InitPostEntity", "LivingCityAnnouncer", function() LC.AnnounceRescan() end)

------------------------------------------------------------------------
-- For the admin
------------------------------------------------------------------------

local function Reply(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

concommand.Add("lc_announce_clips", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local total = 0
    for _, v in ipairs(LC.AnnounceVoices) do
        local parts = {}
        for _, t in ipairs(LC.AnnounceTriggers) do
            local n = #Scan(v, t)
            if v == "administrator" then
                local extra = {}
                for k = 2, #TIERS do
                    local m = #Scan(v, t, k)
                    n = n + m
                    if m > 0 then extra[#extra + 1] = TIERS[k] .. " " .. m end
                end
                total = total + n
                if n > 0 then parts[#parts + 1] = t .. " " .. #Scan(v, t, 1) .. (#extra > 0 and (" (" .. table.concat(extra, ", ") .. ")") or "") end
            else
                total = total + n
                if n > 0 then parts[#parts + 1] = t .. " " .. n end
            end
        end
        Reply(ply, "[Living City] " .. v .. ": " .. (#parts > 0 and table.concat(parts, ", ") or "nothing yet"))
    end
    for v, trigs in pairs(LC.AnnounceExtra) do
        local parts = {}
        for _, t in ipairs(trigs) do
            local n = #Scan(v, t)
            total = total + n
            parts[#parts + 1] = t .. " " .. n
        end
        Reply(ply, "[Living City] " .. v .. ": " .. table.concat(parts, ", "))
    end
    Reply(ply, "[Living City] " .. total .. " custom announcements found. Folders: sound/" .. ROOT .. "overwatch/, administrator/, radio/, flat: a file's name starts with its trigger (curfew1.wav), and the Administrator's tone is in it (curfew_firm1.wav); lc_announce_rescan after adding files.")
end)

concommand.Add("lc_announce_rescan", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    Reply(ply, "[Living City] " .. LC.AnnounceRescan() .. " custom announcements found.")
end)

concommand.Add("lc_announce_say", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local voice, trig = VoiceName(args[1]), string.lower(tostring(args[2] or ""))
    if voice ~= "overwatch" and voice ~= "administrator" then Reply(ply, "[Living City] lc_announce_say <overwatch|administrator> <trigger> [warm|firm|stern|furious]") return end
    local tier
    for k, nm in ipairs(TIERS) do if string.lower(tostring(args[3] or "")) == nm then tier = k end end
    if not Say(voice, trig, nil, true, tier) then Reply(ply, "[Living City] Nothing in sound/" .. ROOT .. voice .. "/" .. trig .. "/ to say (or it's off).") end
end)

concommand.Add("lc_announce_tier", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local trig = string.lower(tostring(args[1] or ""))
    local t = LC.AnnounceTier(trig)
    local used = ResolveTier(trig, t)
    Reply(ply, "[Living City] " .. trig .. ": she would be " .. TierName(t) .. " about it now (sociostability " .. tostring(LC.Socio or "green") .. ", " .. Heat() .. " violent things in ten minutes)" ..
        (used and used ~= t and (", using her " .. TierName(used) .. " recordings") or (used and "" or ", but there are no recordings for it")) .. ".")
end)
