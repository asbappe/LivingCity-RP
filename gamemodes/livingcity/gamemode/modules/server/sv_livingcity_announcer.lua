--[[
    Living City: custom announcements, for Overwatch and for the Administrator

      Drop sound files in a voice's folder and the city says them when
      something happens. No code, no list to edit: the file's name says when.

        sound/livingcity/overwatch/curfew1.wav          the Combine PA
        sound/livingcity/administrator/curfew1.wav      the Administrator, warm
        sound/livingcity/administrator/curfew_firm1.wav ... firm (stern, furious the same)
        sound/livingcity/radio/freq7_1.wav              the radios (static, union, freq7)

      One flat folder per voice. A file's name starts with its trigger
      (curfew1, curfew_soon2, ambient_3); for the Administrator, firm, stern
      or furious anywhere in the name is that tone, and no tone word is her
      warm one. (Older layouts, a folder per trigger, still work.)

      The official place is the server's own garrysmod/sound/livingcity/<voice>/
      (FastDL mirrors it to players), outside the gamemode's folder, so an
      update never touches them. (sound/livingcity/announce/<voice>/, in the old
      livingcity_sound addon or not, is still read too.)
      .wav, .mp3 and .ogg all work. Put as many files in as you like; one
      is picked each time, never the same one twice running. An optional
      text file with the same name (curfew1.txt next to curfew1.wav) is the
      subtitle printed in chat as it plays.

      Triggers (what a file's name starts with)
        events         rations  sweep  curfew  lockdown  raid  supply
                       jog  drill  parade (the morning exercise)
                       ended (an event is over: stabilization restored)
        warnings       rations_soon  curfew_soon (two minutes ahead; a sweep,
                       a raid or a supply convoy is a surprise, and a
                       lockdown answers violence, so they have none)
        the city       socio_green  socio_yellow  socio_red  socio_black (the collapse, and the shelling)
                       dawn  day  dusk  night
                       outbreak  blackout  power_restored
                       skirmish_raid  skirmish_sweep  response (a response squad)
                       breakout  overwatch_drop  block_raided  territory_grew
                       train_arrival  welcome (just for someone joining: hers, then Overwatch's)
        the collapse   black_stand (her last stand)  black_fallen (she's dead; Overwatch)  black_crushed
                       (the uprising crushed)  suppressor_down (the suppression device destroyed)
        ambient        general city announcements; also what the Administrator's
                       periodic addresses are made of (lc_breen_broadcasts 1)

      The radio repair bench (sv_livingcity_moregames.lua): what a set plays
      as you turn the dial. Static fills the gaps between stations and blends
      into them as you get close, so long, loopable files work best.
        sound/livingcity/radio/static1.wav    the hiss between stations
        sound/livingcity/radio/union1.wav     an ordinary station (the
                       Union band); none, and the Administrator's ambient
                       recordings are used
        sound/livingcity/radio/freq7_1.wav    the Resistance's pirate
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

      Pacing (the owner, 7 November: "constant announcements ... I feel stressed
      just playing"). Every voice, Overwatch's (his own recordings or Half-Life 2's)
      and the Administrator's, takes its turn on one shared PA (LC.PAMark): the next
      one waits till the last has finished (each player's game plays them one after
      another). The routine ones (the time of day, a train, a skirmish, sociostability
      going green or yellow, the PA's remarks on a wanted person...) are only made
      after lc_announce_quiet (90) seconds of quiet; in between they're left out.
      The things that matter (an event, its warning, a lockdown, red, a breakout)
      are always said. Half-Life 2's own lines are only used for something the
      server has no recording of its own for.

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
local cvOn   = CreateConVar("lc_announce_custom", "1", FLAGS, "Custom Overwatch and Administrator announcements from sound/livingcity/<voice>/")
local cvPct  = CreateConVar("lc_announce_custom_pct", "100", FLAGS, "Chance (percent) a custom Overwatch line replaces the built-in one for an event")
local cvGap  = CreateConVar("lc_announce_gap", "25", FLAGS, "Seconds between two custom announcements by the same voice")
local cvCat  = CreateConVar("lc_announce_cat_gap", "90", FLAGS, "Seconds before the same trigger can be announced again")
local cvShare = CreateConVar("lc_announce_admin_share", "50", FLAGS, "No longer used (7 November): the Administrator's recorded voice speaks when nobody plays the Administrator, Overwatch's when a player does")
local cvStock = CreateConVar("lc_announce_stock", "0", FLAGS, "1: Half-Life 2's own Overwatch voice speaks for what you have no recording of; 0 (the owner, 9 November: never Half-Life 2's): the banner and the words only")
-- Half-Life 2's own Overwatch line, or nothing (an empty path: the banner and the words still show)
function LC.StockVoice(path)
    if path and not cvStock:GetBool() and string.find(path, "^npc/overwatch/cityvoice/") then return "" end
    return path
end
local cvQuiet = CreateConVar("lc_announce_quiet", "90", FLAGS, "Seconds of quiet on the PA (after the last announcement has finished) before a routine one (the time of day, a train, a skirmish, sociostability going green or yellow...) is made; routine ones in that time are left out")

local ROOT = "livingcity/announce/"
-- (and straight under sound/livingcity/ too: sound/livingcity/overwatch/, .../administrator/,
-- .../radio/, beside endings/, is where a server's own recordings often are)
local ROOTS = { ROOT, "livingcity/" }
LC.AnnounceRoots = ROOTS -- (core: CORE.md; the tests check this list hasn't changed)
local EXT = { wav = true, mp3 = true, ogg = true }

LC.AnnounceTriggers = {
    "rations", "sweep", "curfew", "lockdown", "raid", "supply", "ended",
    "rations_soon", "curfew_soon",
    "socio_green", "socio_yellow", "socio_red", "socio_black", "dawn", "day", "dusk", "night",
    "outbreak", "blackout", "power_restored", "skirmish_raid", "skirmish_sweep", "response",
    "breakout", "overwatch_drop", "block_raided", "territory_grew", "train_arrival", "welcome", "ambient",
    "jog", "drill", "parade", -- morning exercise (sv_livingcity_exercise.lua)
    "black_stand", "black_fallen", "black_crushed", "suppressor_down", -- the collapse (sv_livingcity_collapse.lua)
}
-- No longer said (a sweep, a raid or a supply convoy is a surprise; a lockdown
-- answers violence): files named for these are left alone, never mistaken for
-- the event itself (lockdown_soon1.wav is not a lockdown line).
LC.AnnounceRetired = { "sweep_soon", "lockdown_soon", "raid_soon", "supply_soon" }
LC.AnnounceVoices = { "overwatch", "administrator" }
LC.AnnounceTierNames = { "warm", "firm", "stern", "furious" }
-- Other voices with folders of their own, and their triggers: [voice] = { trigger, ... }
LC.AnnounceExtra = { radio = { "static", "union", "freq7", "freq7_song", "jam",
    "freq7_sweep", "freq7_raid", "freq7_curfew", "freq7_supply", "freq7_incursion", "freq7_lockdown", "freq7_dropship" } } -- (Freq 7: sv_livingcity_freq7.lua)
local TIERS = LC.AnnounceTierNames

-- the tone she usually takes for each thing (1 warm .. 4 furious)
local BASE_TIER = {
    rations = 1, supply = 1, ended = 1, rations_soon = 1,
    dawn = 1, day = 1, dusk = 1, night = 1, ambient = 1, welcome = 1, power_restored = 1, train_arrival = 1, socio_green = 1,
    sweep = 2, curfew = 2, curfew_soon = 2, blackout = 2, territory_grew = 2, socio_yellow = 2, outbreak = 2,
    lockdown = 3, raid = 3, skirmish_raid = 3, skirmish_sweep = 3, response = 3, block_raided = 3, overwatch_drop = 3, socio_red = 3,
    breakout = 4, socio_black = 4, black_stand = 4, black_fallen = 4, suppressor_down = 4, black_crushed = 3,
    jog = 1, drill = 1, parade = 1, -- (she loves a bit of exercise)
}
LC.AnnounceBaseTier = BASE_TIER -- (read only: the voice lines list, _dev/voice_lines.py)
local VIOLENT = { raid = true, skirmish_raid = true, skirmish_sweep = true, breakout = true, outbreak = true, block_raided = true, territory_grew = true, overwatch_drop = true }
local heat = {} -- times of recent violent things

local function Heat()
    local now, n, keep = CurTime(), 0, {}
    for _, t in ipairs(heat) do if now - t < 600 then n = n + 1 keep[#keep + 1] = t end end
    heat = keep
    return n
end

function LC.AnnounceCalm() heat = {} end -- (forget the violence: tests, a fresh map)
LC.AnnounceHeatReset = LC.AnnounceCalm

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
    jog = "Morning exercise", drill = "Morning exercise", parade = "Morning parade",
    outbreak = "Outbreak", blackout = "Power failure", power_restored = "Power restored", skirmish_raid = "Overwatch response",
    skirmish_sweep = "Overwatch response", breakout = "Prison breakout", overwatch_drop = "Overwatch deployment",
    block_raided = "Housing block inspection", territory_grew = "Resistance activity", train_arrival = "Arrivals",
    welcome = "Welcome", dawn = "City announcement", day = "City announcement", dusk = "City announcement", night = "City announcement",
    ambient = "City announcement", response = "Overwatch response", socio_black = "Civil collapse",
    black_stand = "The Nexus", black_fallen = "The Administrator", black_crushed = "Order restored", suppressor_down = "The suppression device",
}
LC.AnnounceTitles = TITLES -- (read only: the voice lines list, _dev/voice_lines.py)

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
    local function Try(t)
        if string.sub(n, 1, #t) == t and (not best or #t > #best) then
            local rest = string.sub(n, #t + 1, #t + 1)
            if rest == "" or not string.match(rest, "%a") then best = t end
        end
    end
    for _, t in ipairs(list or LC.AnnounceTriggers) do Try(t) end
    if not list then for _, t in ipairs(LC.AnnounceRetired) do Try(t) end end
    return best
end

-- The files in a voice's folder that never play, and why (lc_announce_clips).
function LC.AnnounceUnused(voice)
    local out = {}
    local retired = {}
    for _, t in ipairs(LC.AnnounceRetired) do retired[t] = true end
    local names = {}
    for _, root in ipairs(ROOTS) do for _, n in ipairs(file.Find("sound/" .. root .. voice .. "/*", "GAME") or {}) do names[#names + 1] = n end end
    table.sort(names)
    for _, name in ipairs(names) do
        local base, ext = string.match(name, "^(.*)%.([%w]+)$")
        if base and EXT[string.lower(ext)] then
            local t = LC.AnnounceTriggerOf(base)
            if not t then
                out[#out + 1] = name .. ": doesn't start with a trigger (a typo?)"
            elseif retired[t] then
                out[#out + 1] = name .. ": " .. t .. " is no longer said (a surprise, or it answers violence)"
            elseif voice == "overwatch" and (LC.AnnounceToneOf(base) > 1 or string.find(string.lower(base), "warm", 1, true)) then
                out[#out + 1] = name .. ": plays as Overwatch (a tone word only means something to the Administrator: is this her recording?)"
            end
        end
    end
    return out
end

-- One voice's own folder, flat: every file named for its trigger
-- (curfew1.wav, curfew_firm2.wav, freq7_1.wav).
local function FlatDir(out, voice, trig, tier, list)
    for _, root in ipairs(ROOTS) do
        local dir = "sound/" .. root .. voice
        local names = file.Find(dir .. "/*", "GAME") or {}
        table.sort(names)
        for _, name in ipairs(names) do
            local base, ext = string.match(name, "^(.*)%.([%w]+)$")
            if base and not string.find(name, "/", 1, true) and EXT[string.lower(ext)] and LC.AnnounceTriggerOf(base, list) == trig
                and (not tier or LC.AnnounceToneOf(base) == tier) then
                local text = file.Read(dir .. "/" .. base .. ".txt", "GAME")
                text = text and string.Trim(text) or nil
                if text == "" then text = nil end
                out[#out + 1] = { path = root .. voice .. "/" .. name, text = text }
                if resource and resource.AddFile then resource.AddFile("sound/" .. root .. voice .. "/" .. name) end
            end
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

-- Overwatch on the PA until this time: the Administrator waits for him (LC.Announce marks it too)
function LC.OverwatchSpeaks(path)
    local secs = (LC.AnnounceClipSecs and LC.AnnounceClipSecs(path)) or 6
    LC.OverwatchUntil = math.max(LC.OverwatchUntil or 0, CurTime() + secs)
end
local trigNext = {}  -- [voice/trigger] = earliest time for this trigger again

-- The one PA everyone shares (the owner, 7 November: "3 different announcers just make it feel
-- hectic"): whoever speaks, the next waits till they've finished. Marked by every voice that
-- speaks to the city (this file's, LC.Announce's, the sociostability's).
LC.PAEndsAt = LC.PAEndsAt or 0
function LC.PAMark(secs)
    local now = CurTime()
    LC.PAEndsAt = math.max(LC.PAEndsAt or 0, now) + math.max(0, tonumber(secs) or 8)
    LC.LastPA = now
    return LC.PAEndsAt
end
-- Seconds of quiet on the PA so far (below zero while someone's still speaking).
function LC.PAQuiet()
    return CurTime() - math.max(LC.PAEndsAt or 0, LC.LastPA or -1e9)
end

local function Say(voice, trig, only, force, tier)
    if not cvOn:GetBool() then return false end
    if LC.EndingSession and LC.EndingSession() then return false end -- (quiet through a secret ending)
    voice = VoiceName(voice)
    local now = CurTime()
    if not force and ((voiceNext[voice] or 0) > now or (trigNext[voice .. "/" .. trig] or 0) > now) then return false end
    if voice == "administrator" and not only and (LC.LiveSpeaker or LC.LiveNPC) then return false end -- somebody is already on air
    -- (nobody talks over anybody: each player's game plays the voices one after another, in turn)
    local path, text, used = LC.PickAnnounceClip(voice, trig, false, tier)
    if not path then return false end
    -- one just for somebody (their welcome) doesn't hold up the city's own
    local secs = LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(path) or 0
    if not only then
        voiceNext[voice] = now + cvGap:GetFloat()
        trigNext[voice .. "/" .. trig] = now + cvCat:GetFloat()
        LC.PAMark(secs > 0.2 and secs or 8)
    end
    -- (and while someone's welcome plays, the city's go to everyone else)
    local to = only and { only } or nil
    if not to then
        to = {}
        for _, p in ipairs(player.GetAll()) do if (p.lcWelcomeUntil or 0) <= now then to[#to + 1] = p end end
        if #to == #player.GetAll() then to = nil end
    end
    if voice == "overwatch" then
        if not only then LC.OverwatchSpeaks(path) end
        net.Start("lc_announce")
        net.WriteString(path)
        net.WriteString(TITLES[trig] or "City announcement")
        net.WriteFloat(secs)
        if to then net.Send(to) else net.Broadcast() end
        for _, p in ipairs(to or player.GetAll()) do
            if text then p:ChatPrint("[" .. (TITLES[trig] or "City announcement") .. "] \"" .. text .. "\"") end
        end
    else
        local hear = only and { only } or (LC.BreencastListeners and LC.BreencastListeners()) or player.GetAll()
        if to and not only then
            local ok = {}
            for _, p in ipairs(to) do ok[p] = true end
            local kept = {}
            for _, p in ipairs(hear) do if ok[p] then kept[#kept + 1] = p end end
            hear = kept
        end
        if #hear > 0 then
            net.Start("lc_breencast")
            net.WriteString(path)
            net.WriteFloat(secs)
            net.Send(hear)
            if text then for _, p in ipairs(hear) do p:ChatPrint("[" .. (LC.AdministratorName and LC.AdministratorName() or "The Administrator") .. "] \"" .. text .. "\"") end end
        end
    end
    hook.Run("LivingCityCustomAnnouncement", voice, trig, path, used)
    return true, path
end
LC.CustomAnnounce = Say

-- How long a clip runs: the file's own header first (exact), then SoundDuration (which can
-- say 0, or come out short, on a dedicated server)
function LC.AnnounceKnownSecs(path)
    local h = LC.WavDuration and LC.WavDuration(path)
    if h and h > 0.2 and h <= 120 then return h end
    local d = SoundDuration and SoundDuration(path) or 0
    if d and d > 0.2 and d <= 120 then return d end
    return 0
end
local function ClipSecs(path)
    local d = LC.AnnounceKnownSecs(path)
    return (d > 0.2 and d <= 60) and d or 8
end
LC.AnnounceClipSecs = ClipSecs

-- Who says it: only one voice for each thing that happens, never both (the owner, 7 November):
-- with nobody playing the Administrator, her recorded voice, when she has a recording for it (else
-- Overwatch); with a player as the Administrator, she speaks for herself (her microphone), so the
-- PA is Overwatch's: the owner's own recordings, or Half-Life 2's where they have none. nil: nobody.
-- builtin: Overwatch has his own Half-Life 2 lines for it.
-- (LC.AnnounceForceVoice, for the tests: "overwatch" or "administrator" goes first, the other if it has nothing.)
function LC.AnnounceVoiceFor(trig, builtin)
    local ow = builtin or (cvOn:GetBool() and #Scan("overwatch", trig) > 0)
    local admin = cvOn:GetBool() and ResolveTier(trig, LC.AnnounceTier(trig)) ~= nil
    local force = LC.AnnounceForceVoice
    if force == "overwatch" then return ow and "overwatch" or (admin and "administrator" or nil) end
    if force ~= "administrator" and LC.HumanAdministrator and LC.HumanAdministrator() then return ow and "overwatch" or nil end
    return admin and "administrator" or (ow and "overwatch" or nil)
end

-- The routine ones: left out unless the PA has been quiet lc_announce_quiet seconds (after the
-- last one finished). (dawn, night, and sociostability going green or yellow joined them on 7
-- November: they came on top of the events that caused them.)
local MINOR = { day = true, dusk = true, train_arrival = true, territory_grew = true, block_raided = true, skirmish_raid = true,
    skirmish_sweep = true, overwatch_drop = true, power_restored = true, ambient = true,
    dawn = true, night = true, socio_green = true, socio_yellow = true }
LC.AnnounceMinor = MINOR
function LC.AnnounceTooSoon(trig)
    local q = cvQuiet:GetFloat()
    return MINOR[trig] and q > 0 and LC.PAQuiet() < q or false
end

-- One voice for one thing happening: Overwatch or the Administrator, picked
-- at random (LC.AnnounceVoiceFor). built-in: it's been said already (an event,
-- a sociostability change, a response squad: LC.Announce picks the voice there).
local function Trigger(trig, opts)
    if not LC.Running then return end
    opts = opts or {}
    local d = opts.delay or 3
    if VIOLENT[trig] then heat[#heat + 1] = CurTime() end
    if opts.builtin then return end
    if not opts.only and LC.AnnounceTooSoon(trig) then return end
    local who = LC.AnnounceVoiceFor(trig)
    if not who then return end
    timer.Simple(d, function() Say(who, trig, opts.only, opts.force, who == "administrator" and opts.tier or nil) end)
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
hook.Add("LivingCityDayPhase", "LivingCityAnnouncer", function(phase)
    -- (not "a new day" while a curfew or lockdown holds everyone indoors: it says the opposite)
    if LC.Event == "curfew" or LC.Event == "lockdown" then return end
    Trigger(phase, { delay = 4 })
end)
hook.Add("LivingCityOutbreak", "LivingCityAnnouncer", function() Trigger("outbreak") end)
hook.Add("LivingCityBlackout", "LivingCityAnnouncer", function(on)
    if on then Trigger("blackout", { delay = 1, breenAfter = 10 }) else Trigger("power_restored") end
end)
-- (a raid is announced when its fighters reach the target and the fight starts, not when they set out: sv_livingcity_rebelevents.lua)
hook.Add("LivingCitySkirmish", "LivingCityAnnouncer", function(kind) if kind ~= "raid" then Trigger("skirmish_" .. tostring(kind)) end end)
hook.Add("LivingCityRaidArrived", "LivingCityAnnouncer", function() Trigger("skirmish_raid") end)
hook.Add("LivingCityBreakout", "LivingCityAnnouncer", function() Trigger("breakout") end)
hook.Add("LivingCityOverwatchDrop", "LivingCityAnnouncer", function() Trigger("overwatch_drop") end)
hook.Add("LivingCityBlockRaided", "LivingCityAnnouncer", function() Trigger("block_raided") end)
hook.Add("LivingCityTerritoryGrew", "LivingCityAnnouncer", function() Trigger("territory_grew") end)
hook.Add("LivingCityTrainArrived", "LivingCityAnnouncer", function() Trigger("train_arrival", { delay = 2 }) end)
hook.Add("LivingCityResponseSquad", "LivingCityAnnouncer", function() Trigger("response", { builtin = true }) end)

-- The welcome, only for someone who still has to register at Civil Intake
-- (someone already on the register doesn't hear it each time they join), and
-- just for them, whatever else is going on: the Administrator,
-- then Overwatch as soon as she's finished. Nothing the city says reaches them
-- over it (they hear the next one). Also for a new person arriving
-- (sv_livingcity_intake.lua). If someone is speaking live on the loudspeakers,
-- it waits for them to finish (a minute at most).
function LC.AnnounceWelcome(ply, waited)
    if not IsValid(ply) or not cvOn:GetBool() then return end
    if not (LC.IntakePending and LC.IntakePending(ply)) then return end
    local now = CurTime()
    if not waited and (ply.lcWelcomeUntil or 0) > now then return end -- (already being welcomed)
    waited = waited or 0
    if (LC.LiveSpeaker or LC.LiveNPC) and waited < 60 then
        ply.lcWelcomeUntil = now + 4
        timer.Simple(3, function() LC.AnnounceWelcome(ply, waited + 3) end)
        return
    end
    local said, path = Say("administrator", "welcome", ply, true)
    local after = said and (ClipSecs(path) + 1) or 0
    ply.lcWelcomeUntil = now + after + 1
    timer.Simple(after, function()
        if not IsValid(ply) then return end
        local saidO, pathO = Say("overwatch", "welcome", ply, true)
        ply.lcWelcomeUntil = CurTime() + (saidO and ClipSecs(pathO) or 0) + 0.5
    end)
end

-- a few seconds after someone joins, just for them
hook.Add("PlayerInitialSpawn", "LivingCityAnnouncer", function(ply)
    timer.Simple(20, function() LC.AnnounceWelcome(ply) end)
end)

hook.Add("InitPostEntity", "LivingCityAnnouncer", function() LC.AnnounceRescan() end)

------------------------------------------------------------------------
-- For the admin
------------------------------------------------------------------------

local function Reply(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

-- Every recording the game can't play (an MP3 renamed .wav, a 48000 Hz or
-- 24-bit WAV...): { "folder/name: why" }. Nobody would hear those at all.
function LC.AnnounceBadFiles()
    if not LC.SoundProblems then return {} end
    local dirs = { "overwatch", "administrator", "radio" }
    local out = {}
    for _, d in ipairs(dirs) do
        for _, root in ipairs(ROOTS) do
            for _, why in ipairs(LC.SoundProblems(root .. d)) do out[#out + 1] = d .. "/" .. why end
        end
    end
    for _, why in ipairs(LC.SoundProblems("livingcity/endings", true)) do out[#out + 1] = "endings/" .. why end
    for _, id in ipairs(LC.EndingOrder or {}) do -- (the older layout, a folder per ending)
        for _, why in ipairs(LC.SoundProblems("livingcity/endings/" .. id, true)) do out[#out + 1] = "endings/" .. id .. "/" .. why end
    end
    return out
end

-- Told once at start-up, and each superadmin when they join.
local badCount = 0
hook.Add("InitPostEntity", "LivingCityAnnounceBadFiles", function()
    local bad = LC.AnnounceBadFiles()
    badCount = #bad
    if badCount > 0 then
        print("[Living City] " .. badCount .. " sound file(s) the game can't play (nobody hears them):")
        for _, why in ipairs(bad) do print("[Living City]   " .. why) end
    end
end)
hook.Add("PlayerInitialSpawn", "LivingCityAnnounceBadFiles", function(ply)
    timer.Simple(25, function()
        if badCount > 0 and IsValid(ply) and ply:IsSuperAdmin() and LC.Notice then
            LC.Notice(ply, "warn", "Sound files", badCount .. " recording(s) can't be played (an MP3 renamed .wav, or a WAV that isn't 16-bit 44100 Hz). " ..
                "Type lc_announce_clips in the console to see which, and how to fix each.", 12)
        end
    end)
end)

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
        for _, why in ipairs(LC.AnnounceUnused(v)) do Reply(ply, "[Living City]   check " .. v .. "/" .. why) end
    end
    local bad = LC.AnnounceBadFiles()
    for _, why in ipairs(bad) do Reply(ply, "[Living City]   CAN'T PLAY " .. why) end
    for v, trigs in pairs(LC.AnnounceExtra) do
        local parts = {}
        for _, t in ipairs(trigs) do
            local n = #Scan(v, t)
            total = total + n
            parts[#parts + 1] = t .. " " .. n
        end
        Reply(ply, "[Living City] " .. v .. ": " .. table.concat(parts, ", "))
    end
    local dl, url = GetConVar("sv_allowdownload"), GetConVar("sv_downloadurl")
    Reply(ply, "[Living City] Players' computers play these, so each needs the files: " ..
        (game.IsDedicated and game.IsDedicated() and "this is a dedicated server; " or "") ..
        "sv_allowdownload " .. (dl and dl:GetString() or "?") .. ", sv_downloadurl \"" .. (url and url:GetString() or "") .. "\"" ..
        " (a Workshop addon is the reliable way). Each player can type lc_sound_check to test their own.")
    Reply(ply, "[Living City] " .. total .. " custom announcements found. Folders: sound/livingcity/overwatch/, administrator/, radio/ (or the same under sound/" .. ROOT .. "), flat: a file's name starts with its trigger (curfew1.wav), and the Administrator's tone is in it (curfew_firm1.wav); lc_announce_rescan after adding files.")
end)

-- Every voice line the gamemode looks for that has no recording yet (the owner, 8 November: "an
-- audit and listing of all the voice files we know to still be missing"): the dreams' lines, the PA's
-- triggers for each voice (the Administrator's in any tone), the radio's, and the G-Man's.
function LC.VoiceMissing()
    local out = {}
    local function Row(name, folder, list)
        table.sort(list)
        out[#out + 1] = { name = name, folder = folder, missing = list }
    end
    local dream = {}
    for cue in pairs(LC.PropagandaCues or {}) do
        if LC.PropagandaVoice and not LC.PropagandaVoice(cue) then dream[#dream + 1] = cue end
    end
    Row("Dream lines", "dreams/voice/", dream)
    for _, v in ipairs(LC.AnnounceVoices) do
        local m = {}
        for _, t in ipairs(LC.AnnounceTriggers) do
            local n = 0
            for k = 1, (v == "administrator" and #TIERS or 1) do n = n + #Scan(v, t, k) end
            if n == 0 then m[#m + 1] = t end
        end
        Row(v, v .. "/", m)
    end
    for v, trigs in pairs(LC.AnnounceExtra) do
        local m = {}
        for _, t in ipairs(trigs) do if #Scan(v, t) == 0 then m[#m + 1] = t end end
        Row(v, v .. "/", m)
    end
    local g = {}
    local rival = GetConVar("lc_gman_line_rival")
    rival = rival and rival:GetString() or ""
    if rival ~= "" and not file.Exists("sound/" .. rival, "GAME") then g[#g + 1] = rival end
    if #(file.Find("sound/livingcity/gman/dream*", "GAME") or {}) == 0 then g[#g + 1] = "dream1 (optional)" end
    -- his lines in the collapse (sv_livingcity_collapse.lua), each a setting
    for _, name in ipairs(LC.CollapseGmanCvars or {}) do
        local cv = GetConVar(name)
        local path = cv and string.Trim(cv:GetString()) or ""
        if path ~= "" and not file.Exists("sound/" .. path, "GAME") then g[#g + 1] = path .. " (" .. name .. ")" end
    end
    Row("G-Man", "gman/", g)
    return out
end

concommand.Add("lc_voice_missing", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local total = 0
    for _, r in ipairs(LC.VoiceMissing()) do
        total = total + #r.missing
        Reply(ply, "[Living City] " .. r.name .. " (sound/livingcity/" .. r.folder .. "), " ..
            (#r.missing == 0 and "nothing missing" or (#r.missing .. " missing: " .. table.concat(r.missing, ", "))))
    end
    Reply(ply, "[Living City] " .. total .. " voice lines with no recording yet. Without one, the words still show (Half-Life 2's own Overwatch lines only with lc_announce_stock 1). " ..
        "Name a file for its line (curfew1.wav, ravenholm_defeat1.wav); a .txt with the same name is its subtitle. Everything to record, with suggested words: VOICE_LINES.md, in the gamemode's folder.")
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
