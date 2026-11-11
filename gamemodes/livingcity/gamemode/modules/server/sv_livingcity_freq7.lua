--[[
    Living City: Freq 7, the Resistance's pirate broadcast

    "Frequency 7" is a rule, not a number: the Resistance only broadcast on a
    frequency whose digits add up to seven. On the dial there are exactly
    seven of them (100.6 101.5 102.4 103.3 104.2 105.1 106.0), so the name is
    the whole instruction, and it fits in a whisper.

      One station      every radio on Freq 7 hears the same thing at once:
                       a voice line, then a quiet spell (just static,
                       lc_freq7_quiet seconds, 120) so the band stays clear
                       for people talking on it, then another voice line.
                       lc_freq7_songs 1 puts songs back in the gaps
      Warnings         when something's coming for the Resistance (a sweep, a
                       raid, curfew, a supply convoy, an incursion into rebel
                       ground, a lockdown, a dropship) the warning cuts in at
                       once, even mid-song, and a song follows it
      The hunt         the Combine find it after a while on one frequency and
                       jam it: a harsh whine there, and the broadcast is dark
                       for a minute or so, then back on another of the seven.
                       A jammed frequency stays dead for a while.
                       The worse the city's mood, the faster they find it
                       (green: about lc_freq7_hold minutes; yellow 60%; red 30%).
                       Jamming runs on city power: in a blackout the hunt stops
                       and Freq 7 holds where it is.
      Who follows it   a Resistance (retuned) radio follows each hop on its
                       own; a plain Union radio has to be retuned by hand
      Units            are told on their net when it's located and jammed

    Recordings (garrysmod/sound/livingcity/radio/):
      freq7_1.wav ...             the voice lines (between songs)
      freq7_song_<anything>.ogg   the songs (.ogg or .wav: the server can
                                  tell how long those run)
      freq7_<warning>1.wav        sweep, raid, curfew, supply, incursion,
                                  lockdown, dropship
      jam1.wav                    the jamming whine (a stock sound otherwise)

      lc_freq7_hold 18            minutes it holds a frequency on green
      lc_freq7_jammed 8           minutes a jammed frequency stays dead
      lc_freq7_status             where it is and what's on (admin)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvHold = CreateConVar("lc_freq7_hold", "18", FLAGS, "Minutes Freq 7 holds one frequency before the Combine find it, on green (yellow 60%, red 30%)")
local cvJammed = CreateConVar("lc_freq7_jammed", "8", FLAGS, "Minutes a jammed frequency stays dead")
local cvSongs  = CreateConVar("lc_freq7_songs", "0", FLAGS, "Songs on Freq 7 between the voice lines (0: off, so the band stays clear for talk; a quiet spell instead)")
local cvQuiet  = CreateConVar("lc_freq7_quiet", "120", FLAGS, "Seconds of quiet (just static) between Freq 7's voice lines when there are no songs")

LC.Freq7Freqs = { 100.6, 101.5, 102.4, 103.3, 104.2, 105.1, 106.0 }
LC.Freq7Warnings = { "sweep", "raid", "curfew", "supply", "incursion", "lockdown", "dropship" }
local STOCK_JAM = "ambient/energy/electric_loop.wav"
local GAP = 1.5 -- (a breath between one thing and the next)

LC.Freq7 = LC.Freq7 or { jammed = {}, seq = 0 }
local S = LC.Freq7

-- True for a frequency whose digits add up to seven (the rule).
function LC.IsFreq7(f)
    local n = 0
    for d in string.gmatch(string.format("%.1f", tonumber(f) or 0), "%d") do n = n + tonumber(d) end
    return n == 7
end

------------------------------------------------------------------------
-- How long a recording runs
------------------------------------------------------------------------

local oggSecs = {}
local function LE(s, i, n)
    local v = 0
    for k = n, 1, -1 do v = v * 256 + string.byte(s, i + k - 1) end
    return v
end
-- An .ogg's length: the last page's sample count over the sample rate.
function LC.OggDuration(path)
    if oggSecs[path] ~= nil then return oggSecs[path] or nil end
    oggSecs[path] = false
    local data = file.Read("sound/" .. path, "GAME")
    if not data or #data < 64 then return nil end
    local id = string.find(data, "\1vorbis", 1, true)
    if not id or #data < id + 16 then return nil end
    local rate = LE(data, id + 12, 4)
    local last, at = nil, 1
    while true do
        local p = string.find(data, "OggS", at, true)
        if not p then break end
        last, at = p, p + 4
    end
    if not last or rate <= 0 or #data < last + 13 then return nil end
    local granule = LE(data, last + 6, 6) -- (8 bytes; the top two are always zero for anything this short)
    local secs = granule / rate
    if secs > 0.2 and secs < 3600 then oggSecs[path] = secs return secs end
    return nil
end

local function ClipSecs(path, fallback)
    local d = SoundDuration and SoundDuration(path) or 0
    if d and d > 0.2 and d < 3600 then return d end
    return (LC.WavDuration and LC.WavDuration(path)) or LC.OggDuration(path) or fallback
end

------------------------------------------------------------------------
-- The station
------------------------------------------------------------------------

local function Clip(trig) if LC.RadioClip then return LC.RadioClip(trig) end end

local function HoldSecs()
    local mul = 1
    local socio = LC.Socio or "green"
    if socio == "yellow" then mul = 0.6 elseif socio == "red" then mul = 0.3 end
    return math.max(60, cvHold:GetFloat() * 60 * mul * math.Rand(0.75, 1.25))
end

local function PickFreq(now, avoid)
    local open, any = {}, {}
    for _, f in ipairs(LC.Freq7Freqs) do
        if f ~= avoid then
            any[#any + 1] = f
            if (S.jammed[f] or 0) <= now then open[#open + 1] = f end
        end
    end
    local list = #open > 0 and open or any
    return list[math.random(#list)]
end

local function Play(now, path, kind, text, loop)
    S.seq = S.seq + 1
    S.item = path and { path = path, kind = kind, text = text, loop = loop,
        ends = loop and math.huge or (now + ClipSecs(path, kind == "song" and 150 or 12) + GAP) } or nil
    if kind ~= "jam" then S.lastKind = kind end
end

-- Next on air: a voice line, then (with songs off, the default) a quiet spell, just static,
-- so the band stays clear for people talking on it; with lc_freq7_songs 1, a song instead.
local function Next(now)
    if not cvSongs:GetBool() then
        if S.lastKind == "voice" then
            S.seq = S.seq + 1
            S.item = { kind = "quiet", ends = now + math.max(10, cvQuiet:GetFloat()) * math.Rand(0.75, 1.25) }
            S.lastKind = "quiet"
            return
        end
        local path, text = Clip("freq7")
        if not path then S.item = nil S.lastKind = nil return end
        Play(now, path, "voice", text)
        return
    end
    local want = S.lastKind == "voice" and "song" or "voice"
    local trig = { voice = "freq7", song = "freq7_song" }
    local path, text = Clip(trig[want])
    if not path then
        want = want == "voice" and "song" or "voice"
        path, text = Clip(trig[want])
    end
    if not path then S.item = nil S.lastKind = nil return end
    Play(now, path, want, text)
end

function LC.Freq7Jam(now)
    now = now or CurTime()
    if S.dark or not S.freq then return false end
    local f = S.freq
    S.dark, S.jamFreq = true, f
    S.jammed[f] = now + cvJammed:GetFloat() * 60
    S.darkUntil = now + math.Rand(45, 90)
    local path = Clip("jam")
    Play(now, path or STOCK_JAM, "jam", nil, true)
    if LC.RadioNotice then LC.RadioNotice("cp", string.format("Dispatch: pirate signal located on %.1f. Jamming.", f)) end
    hook.Run("LivingCityFreq7Jammed", f)
    return true
end

local function Back(now)
    S.dark = false
    S.freq = PickFreq(now, S.jamFreq)
    S.holdUntil = now + HoldSecs()
    S.lastKind = "song" -- (back on air with a voice: "we always come back"; anything but "voice" does it)
    Next(now)
end

-- A warning for the Resistance cuts in now (and a quiet spell, or a song, follows it).
function LC.Freq7Warn(name)
    if S.dark or not S.freq then return false end
    local path, text = Clip("freq7_" .. tostring(name))
    if not path then return false end
    Play(CurTime(), path, "voice", text)
    return true
end

function LC.Freq7Tick(now, dt)
    now = now or CurTime()
    if not S.freq then
        S.freq = PickFreq(now)
        S.holdUntil = now + HoldSecs()
    end
    if LC.CityDark then S.holdUntil = (S.holdUntil or now) + (dt or 1) end -- (no power, no jamming)
    if S.dark then
        if LC.CityDark or now >= (S.darkUntil or 0) then Back(now) end
        return
    end
    if not LC.CityDark and now >= (S.holdUntil or math.huge) then LC.Freq7Jam(now) return end
    if not S.item or now >= S.item.ends then Next(now) end
end

-- What the radios are on: { f (where it is on the dial, or where the jamming
-- is), clip, seq (a new number for each new thing on air), loop, onAir }
function LC.Freq7Now()
    if not S.freq then LC.Freq7Tick(CurTime(), 0) end
    local it = S.item
    return { f = S.dark and S.jamFreq or S.freq, clip = it and it.path or nil, seq = S.seq, loop = it and it.loop or false,
        onAir = not S.dark, kind = it and it.kind or nil, text = it and it.text or nil }
end

function LC.Freq7Reset()
    LC.Freq7 = { jammed = {}, seq = S.seq or 0 }
    S = LC.Freq7
end

timer.Create("LivingCityFreq7", 1, 0, function() LC.Freq7Tick(CurTime(), 1) end)

------------------------------------------------------------------------
-- What cuts in
------------------------------------------------------------------------

hook.Add("LivingCityEventSoon", "LivingCityFreq7", function(name)
    if name == "sweep" or name == "raid" or name == "curfew" or name == "supply" then LC.Freq7Warn(name) end
end)
hook.Add("LivingCityEventStarted", "LivingCityFreq7", function(name)
    if name == "lockdown" then LC.Freq7Warn("lockdown") end
end)
hook.Add("LivingCitySkirmish", "LivingCityFreq7", function(kind)
    if kind == "sweep" then LC.Freq7Warn("incursion") end
end)
hook.Add("LivingCityOverwatchDrop", "LivingCityFreq7", function() LC.Freq7Warn("dropship") end)

concommand.Add("lc_freq7_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local n = LC.Freq7Now()
    local msg = string.format("[Miscount] Freq 7: %s %.1f; on now: %s (%s); found in %d s%s",
        n.onAir and "on air at" or "jammed at", n.f or 0, n.clip or "nothing (no recordings)", n.kind or "-",
        math.max(0, math.floor((S.holdUntil or 0) - CurTime())), LC.CityDark and " (blackout: the hunt has stopped)" or "")
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
end)
