--[[
    Living City: custom announcements, for Overwatch and for Dr. Breen

      Drop sound files in a folder and the city says them when something
      happens. No code, no list to edit: the folder IS the trigger.

        sound/livingcity/announce/overwatch/<trigger>/anything.wav   the Combine PA
        sound/livingcity/announce/breen/<trigger>/anything.wav       Dr. Breen, over the loudspeakers

      (in this gamemode: gamemodes/livingcity/content/sound/livingcity/announce/...).
      .wav, .mp3 and .ogg all work. Put as many files in a folder as you like;
      one is picked each time, never the same one twice running. An optional
      text file with the same name (curfew/01_move_along.txt next to
      curfew/01_move_along.wav) is the subtitle printed in chat as it plays.

      Triggers (the folder names)
        events         rations  sweep  curfew  lockdown  raid  supply
                       ended (an event is over: stabilization restored)
        warnings       rations_soon  sweep_soon  curfew_soon  lockdown_soon
                       raid_soon  supply_soon (two minutes ahead)
        the city       socio_green  socio_yellow  socio_red
                       dawn  day  dusk  night
                       outbreak  blackout  power_restored
                       skirmish_raid  skirmish_sweep  response (a response squad)
                       breakout  overwatch_drop  block_raided  territory_grew
                       train_arrival  welcome (just for someone joining)
        ambient        general city announcements; also what Dr. Breen's
                       periodic addresses are made of (lc_breen_broadcasts 1)

      Overwatch lines replace the built-in one for an event or a sociostability
      change (lc_announce_custom_pct, 100: how often); for everything else they
      are new. Dr. Breen follows Overwatch a few seconds later, over the
      loudspeakers (his volume is the player's lc_breencast_volume). Files are
      sent to players who join (resource.AddFile); for a big pack, put the
      sounds in a Workshop addon or FastDL instead and the folders still work.

      lc_announce_custom 0/1, lc_announce_custom_pct (100), lc_announce_gap
      (25 s between any two custom announcements of one voice),
      lc_announce_cat_gap (90 s before one trigger can speak again),
      lc_announce_clips (list what was found), lc_announce_rescan,
      lc_announce_say <overwatch|breen> <trigger> (superadmin, to test)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_announce_custom", "1", FLAGS, "Custom Overwatch and Dr. Breen announcements from sound/livingcity/announce/")
local cvPct  = CreateConVar("lc_announce_custom_pct", "100", FLAGS, "Chance (percent) a custom Overwatch line replaces the built-in one for an event")
local cvGap  = CreateConVar("lc_announce_gap", "25", FLAGS, "Seconds between two custom announcements by the same voice")
local cvCat  = CreateConVar("lc_announce_cat_gap", "90", FLAGS, "Seconds before the same trigger can be announced again")

local ROOT = "livingcity/announce/"
local EXT = { wav = true, mp3 = true, ogg = true }

LC.AnnounceTriggers = {
    "rations", "sweep", "curfew", "lockdown", "raid", "supply", "ended",
    "rations_soon", "sweep_soon", "curfew_soon", "lockdown_soon", "raid_soon", "supply_soon",
    "socio_green", "socio_yellow", "socio_red", "dawn", "day", "dusk", "night",
    "outbreak", "blackout", "power_restored", "skirmish_raid", "skirmish_sweep", "response",
    "breakout", "overwatch_drop", "block_raided", "territory_grew", "train_arrival", "welcome", "ambient",
}
LC.AnnounceVoices = { "overwatch", "breen" }

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

local function Scan(voice, trig)
    local key = voice .. "/" .. trig
    if cache[key] then return cache[key] end
    local out = {}
    local dir = "sound/" .. ROOT .. voice .. "/" .. trig
    local names = file.Find(dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, name in ipairs(names) do
        local base, ext = string.match(name, "^(.*)%.([%w]+)$")
        if base and EXT[string.lower(ext)] then
            local text = file.Read(dir .. "/" .. base .. ".txt", "GAME")
            text = text and string.Trim(text) or nil
            if text == "" then text = nil end
            out[#out + 1] = { path = ROOT .. voice .. "/" .. trig .. "/" .. name, text = text }
            if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. voice .. "/" .. trig .. "/" .. name) end
        end
    end
    cache[key] = out
    return out
end

function LC.AnnounceClips(voice, trig) return Scan(voice, trig) end

function LC.AnnounceRescan()
    cache = {}
    local n = 0
    for _, v in ipairs(LC.AnnounceVoices) do
        for _, t in ipairs(LC.AnnounceTriggers) do n = n + #Scan(v, t) end
    end
    return n
end

local lastPicked = {}
-- A clip for this trigger, never the one before it. useChance: honour
-- lc_announce_custom_pct (when it replaces a built-in line).
function LC.PickAnnounceClip(voice, trig, useChance)
    if not cvOn:GetBool() then return nil end
    local clips = Scan(voice, trig)
    if #clips == 0 then return nil end
    if useChance and math.random(100) > cvPct:GetInt() then return nil end
    local key = voice .. "/" .. trig
    local pick = math.random(#clips)
    if #clips > 1 and lastPicked[key] == pick then pick = pick % #clips + 1 end
    lastPicked[key] = pick
    return clips[pick].path, clips[pick].text
end

------------------------------------------------------------------------
-- Saying them
------------------------------------------------------------------------

local voiceNext = {} -- [voice] = earliest time for the next one
local trigNext = {}  -- [voice/trigger] = earliest time for this trigger again

local function Say(voice, trig, only, force)
    if not cvOn:GetBool() then return false end
    local now = CurTime()
    if not force and ((voiceNext[voice] or 0) > now or (trigNext[voice .. "/" .. trig] or 0) > now) then return false end
    if voice == "breen" and (LC.LiveSpeaker or LC.LiveNPC) then return false end -- somebody is already on air
    local path, text = LC.PickAnnounceClip(voice, trig)
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
            if text then for _, p in ipairs(hear) do p:ChatPrint("[Dr. Breen] \"" .. text .. "\"") end end
        end
    end
    hook.Run("LivingCityCustomAnnouncement", voice, trig, path)
    return true
end
LC.CustomAnnounce = Say

-- Both voices for one thing happening: Overwatch first, Dr. Breen a few seconds after.
-- built-in: Overwatch already spoke for this one (an event or a sociostability change),
-- so only Dr. Breen is added here.
local function Trigger(trig, opts)
    if not LC.Running then return end
    opts = opts or {}
    local d = opts.delay or 3
    if not opts.builtin then
        timer.Simple(d, function() Say("overwatch", trig, opts.only, opts.force) end)
    end
    timer.Simple(d + (opts.breenAfter or 9), function() Say("breen", trig, opts.only, opts.force) end)
end
LC.TriggerAnnouncements = Trigger

------------------------------------------------------------------------
-- What triggers them
------------------------------------------------------------------------

hook.Add("LivingCityEventStarted", "LivingCityAnnouncer", function(name)
    Trigger(name, { builtin = true, force = true, breenAfter = 14 })
end)
hook.Add("LivingCityEventSoon", "LivingCityAnnouncer", function(name)
    if name then Trigger(name .. "_soon", { delay = 1, breenAfter = 8 }) end
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
    timer.Simple(9, function() if IsValid(ply) then Say("breen", "welcome", ply, true) end end)
end

-- a few seconds after someone joins, just for them
hook.Add("PlayerInitialSpawn", "LivingCityAnnouncer", function(ply)
    timer.Simple(20, function()
        if not IsValid(ply) then return end
        Say("overwatch", "welcome", ply, true)
        timer.Simple(9, function() if IsValid(ply) then Say("breen", "welcome", ply, true) end end)
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
            total = total + n
            if n > 0 then parts[#parts + 1] = t .. " " .. n end
        end
        Reply(ply, "[Living City] " .. v .. ": " .. (#parts > 0 and table.concat(parts, ", ") or "nothing yet"))
    end
    Reply(ply, "[Living City] " .. total .. " custom announcements found. Folders: sound/" .. ROOT .. "<overwatch|breen>/<trigger>/ (lc_announce_rescan after adding files).")
end)

concommand.Add("lc_announce_rescan", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    Reply(ply, "[Living City] " .. LC.AnnounceRescan() .. " custom announcements found.")
end)

concommand.Add("lc_announce_say", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local voice, trig = string.lower(tostring(args[1] or "")), string.lower(tostring(args[2] or ""))
    if voice ~= "overwatch" and voice ~= "breen" then Reply(ply, "[Living City] lc_announce_say <overwatch|breen> <trigger>") return end
    if not Say(voice, trig, nil, true) then Reply(ply, "[Living City] Nothing in sound/" .. ROOT .. voice .. "/" .. trig .. "/ to say (or it's off).") end
end)
