--[[
    Living City: mouths that move with the recorded voices (the owner, 12 November: "can we get the NPCs'
    mouths to move?"; 23 November: "I REALLY need you to engineer a solution to NPCs not lip syncing to our
    custom voice lines").

    Half-Life 2's own lines move a face from the phoneme track Valve's Faceposer writes into each .wav (a
    "VDAT" chunk): the game reads it and shapes the mouth on every player's screen. A recording has none, and
    an .mp3 cannot hold one. Two ways, so a mouth always moves:

      - the real one: _dev/tools/lipsync_bake.py, run once on the owner's PC, writes that track into every
        recording (an .mp3 is made into a .wav beside it). Such a clip is left to the game, which lip syncs
        it as it does Half-Life 2's. A .wav beside an .mp3 or .ogg of the same name is the one played and
        sent to players (LC.PreferWav), so nothing has to be deleted;
      - until then, here: the server works the speaker's jaw and lips itself, in time with how loud the
        recording is at each moment (read from the file: a .wav's samples, an .mp3's frame gains). Faces
        worked on the server are sent to every player like any other part of the NPC, which the old way
        (each player's game working the jaw, cl_livingcity_lipsync.lua, 12 to 14 November) never managed
        on the owner's server.

    A metrocop's mask or a soldier's helmet has no jaw, and is left alone.
]]

LC = LC or {}

LC.LipSyncStep = 0.02  -- one loudness value for every 20 ms of a recording
LC.LipSyncLead = 0.1   -- players' games draw a face about this far behind its sound: the jaw is worked this far ahead

------------------------------------------------------------------------
-- A .wav beside an .mp3 or .ogg of the same name is the one used
------------------------------------------------------------------------

-- names: what file.Find gave (names, not paths). The same list, with x.mp3 and x.ogg left out where x.wav is there.
function LC.PreferWav(names)
    names = names or {}
    local wav = {}
    for _, n in ipairs(names) do
        local base, ext = string.match(string.lower(n), "^(.-)%.(%w+)$")
        if ext == "wav" then wav[base] = true end
    end
    if next(wav) == nil then return names end
    local out = {}
    for _, n in ipairs(names) do
        local base, ext = string.match(string.lower(n), "^(.-)%.(%w+)$")
        if not (base and wav[base] and (ext == "mp3" or ext == "ogg")) then out[#out + 1] = n end
    end
    return out
end

------------------------------------------------------------------------
-- What a recording holds: its phoneme track, and how loud it is moment by moment
------------------------------------------------------------------------

local function Pct(sorted, p) return sorted[math.max(1, math.min(#sorted, math.floor(#sorted * p + 0.5)))] end

-- raw: one level per step (nil or below 0 for silence). 0..1 within the recording: its quiet floor to its peak.
local function Normalize(raw, span, least)
    local vals = {}
    for _, v in ipairs(raw) do if v and v >= 0 then vals[#vals + 1] = v end end
    if #vals < 3 then return nil end
    table.sort(vals)
    local peak = Pct(vals, 0.96)
    local floor = math.min(math.max(Pct(vals, 0.1), peak - span), peak - least)
    local env = {}
    for i, v in ipairs(raw) do
        env[i] = (v and v >= 0) and math.Clamp((v - floor) / (peak - floor), 0, 1) or 0
    end
    return env
end

-- A .wav: { phonemes = it has the track, env = loudness every LipSyncStep }
local function ReadWav(f)
    if f:Read(4) ~= "RIFF" then return {} end
    f:Read(4)
    if f:Read(4) ~= "WAVE" then return {} end
    local out, chans, rate, bits, align, dataAt, dataSize = {}, 1, 22050, 16, 2, nil, 0
    local size = f:Size()
    for _ = 1, 64 do
        if f:Tell() + 8 > size then break end
        local id, len = f:Read(4), f:ReadULong()
        if not id or #id < 4 or not len then break end
        local at = f:Tell()
        if id == "fmt " then
            f:ReadUShort()
            chans, rate = f:ReadUShort(), f:ReadULong()
            f:ReadULong()
            align, bits = f:ReadUShort(), f:ReadUShort()
        elseif id == "VDAT" then
            out.phonemes = true
        elseif id == "data" then
            dataAt, dataSize = at, len
        end
        f:Seek(at + len + len % 2)
    end
    if not dataAt or rate <= 0 or align <= 0 or (bits ~= 8 and bits ~= 16) then return out end
    local win = math.max(1, math.floor(rate * LC.LipSyncStep)) * align
    local stride = math.max(1, math.floor(win / align / 48)) * align -- (about 48 samples a step is plenty)
    local maxBytes = math.min(dataSize, rate * align * 30)
    f:Seek(dataAt)
    local raw, read = {}, 0
    while read + win <= maxBytes do
        local s = f:Read(win)
        if not s or #s < win then break end
        local sum, n = 0, 0
        for i = 1, win - 1, stride do
            local v
            if bits == 16 then
                local lo, hi = string.byte(s, i, i + 1)
                v = hi * 256 + lo
                if v >= 32768 then v = v - 65536 end
            else
                v = string.byte(s, i) - 128
            end
            sum, n = sum + math.abs(v), n + 1
        end
        raw[#raw + 1] = 20 * math.log10(sum / math.max(1, n) + 1) -- (in decibels, as the ear hears it)
        read = read + win
    end
    out.env = Normalize(raw, 26, 12) -- (speech sits within about 26 dB of its loudest: the jaw follows that)
    return out
end

-- An .mp3: its frames' gains stand in for loudness (no decoding: each frame says how loud it is coded)
local MP3_KBPS = { { 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 },
    { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 } }
local MP3_HZ = { 44100, 48000, 32000 }
local function Bits(s, start, off, n)
    local v = 0
    for i = off, off + n - 1 do
        local b = string.byte(s, start + math.floor(i / 8)) or 0
        v = v * 2 + math.floor(b / 2 ^ (7 - i % 8)) % 2
    end
    return v
end

function LC.LipSyncMp3Levels(s)
    local n, pos = #s, 1
    if string.sub(s, 1, 3) == "ID3" and n >= 10 then
        local a, b, c, d = string.byte(s, 7, 10)
        pos = 11 + ((a * 128 + b) * 128 + c) * 128 + d
    end
    local levels, t, first, guard = {}, 0, true, 0
    while pos + 4 <= n and guard < 40000 do
        guard = guard + 1
        local b1, b2, b3, b4 = string.byte(s, pos, pos + 3)
        local ver, layer = math.floor(b2 / 8) % 4, math.floor(b2 / 2) % 4
        local bri, sri = math.floor(b3 / 16), math.floor(b3 / 4) % 4
        if b1 == 255 and b2 >= 224 and ver ~= 1 and layer == 1 and bri > 0 and bri < 15 and sri < 3 then
            local m1 = ver == 3
            local hz = MP3_HZ[sri + 1] / (m1 and 1 or (ver == 2 and 2 or 4))
            local size = math.floor((m1 and 144000 or 72000) * MP3_KBPS[m1 and 1 or 2][bri] / hz) + math.floor(b3 / 2) % 2
            local side = pos + 4 + ((b2 % 2 == 0) and 2 or 0)
            local mono = math.floor(b4 / 64) == 3
            local frame = string.sub(s, pos, pos + 40)
            if first and (string.find(frame, "Xing", 1, true) or string.find(frame, "Info", 1, true)) then
                -- (the encoder's own note, not sound)
            else
                for g = 0, (m1 and 1 or 0) do
                    local off = m1 and ((mono and 18 or 20) + g * 59 * (mono and 1 or 2)) or (mono and 9 or 10)
                    local p23, big, gain = Bits(s, side, off, 12), Bits(s, side, off + 12, 9), Bits(s, side, off + 21, 8)
                    levels[#levels + 1] = { t, (p23 < 16 or big == 0) and -1 or (gain * 0.17 + math.log(p23 + 1)) }
                    t = t + 576 / hz
                end
            end
            first = false
            pos = pos + math.max(size, 4)
        else
            pos = pos + 1
        end
    end
    return levels
end

local function ReadMp3(f)
    local s = f:Read(math.min(f:Size(), 2000000)) or ""
    local levels = LC.LipSyncMp3Levels(s)
    if #levels < 3 then return {} end
    local raw, k, step = {}, 1, LC.LipSyncStep
    local last = levels[#levels][1]
    for i = 1, math.floor(last / step) + 1 do
        local t0, t1, v = (i - 1) * step, i * step, nil
        local j = k
        while j <= #levels and levels[j][1] < t1 do
            if levels[j][1] >= t0 - 0.015 then v = math.max(v or -1, levels[j][2]) end -- (the loudest piece in the step)
            j = j + 1
        end
        while k <= #levels and levels[k][1] < t1 - 0.015 do k = k + 1 end
        raw[i] = v
    end
    return { env = Normalize(raw, 2.6, 1.2) }
end

local voices = {}
function LC.LipSyncForget() voices = {} end

-- path: as it is played ("livingcity/citizens/say_hi_male1.wav"). { phonemes = true when the game lip syncs it
-- itself, env = loudness 0..1 every LipSyncStep, or nil }. Read once, then remembered.
function LC.LipSyncVoice(path)
    if type(path) ~= "string" then return nil end
    local p = string.lower(path)
    p = string.gsub(p, "^[^%w]+", "")
    p = string.gsub(p, "^sound/", "")
    if voices[p] ~= nil then return voices[p] or nil end
    voices[p] = false
    local ext = string.match(p, "%.(%w+)$")
    local f = file.Open and (ext == "wav" or ext == "mp3") and file.Open("sound/" .. p, "rb", "GAME")
    if not f then return nil end
    local ok, v = LC.Try(function() return ext == "wav" and ReadWav(f) or ReadMp3(f) end)
    f:Close()
    voices[p] = ok and v or {}
    return voices[p]
end

------------------------------------------------------------------------
-- The face
------------------------------------------------------------------------

local JAW = { "jaw_drop", "jaw_open", "mouth_open", "jaw" }
local LIPS = { "right_part", "left_part", "right_mouth_drop", "left_mouth_drop" }
local faces = {}

-- { jaw = id, lips = { ids } } for a model with a jaw (found by name), else false
function LC.LipSyncFace(ent)
    local m = IsValid(ent) and ent.GetModel and ent:GetModel()
    if not m then return false end
    if faces[m] ~= nil then return faces[m] end
    local f = false
    if ent.GetFlexNum and (ent:GetFlexNum() or 0) > 0 and ent.GetFlexIDByName and ent.SetFlexWeight then
        local jaw
        for _, n in ipairs(JAW) do
            jaw = ent:GetFlexIDByName(n)
            if jaw then break end
        end
        if jaw then
            f = { jaw = jaw, lips = {} }
            for _, n in ipairs(LIPS) do
                local id = ent:GetFlexIDByName(n)
                if id then f.lips[#f.lips + 1] = id end
            end
        end
    end
    faces[m] = f
    return f
end

-- How open, t seconds into a line with `left` seconds to go, when its loudness can't be read: a flap of
-- syllables, louder and softer by turns, with short pauses between words (0 to 1).
function LC.LipSyncOpen(t, left, seed)
    seed = seed or 0
    local syll = 0.5 + 0.5 * math.sin(t * 15.7 + seed)
    local word = 0.55 + 0.45 * math.sin(t * 3.3 + seed * 1.7)
    local gap = math.sin(t * 1.9 + seed * 0.6) > 0.82 and 0.15 or 1
    return math.Clamp(syll * word * gap * math.Clamp(t / 0.08, 0, 1) * math.Clamp(left / 0.15, 0, 1), 0, 1)
end

-- env at t seconds (between its steps)
function LC.LipSyncLevel(env, t)
    if not env or t < 0 then return 0 end
    local x = t / LC.LipSyncStep + 1
    local i = math.floor(x)
    local a, b = env[i], env[i + 1]
    if not a then return 0 end
    return a + ((b or a) - a) * (x - i)
end

LC.LipSyncTalking = LC.LipSyncTalking or {} -- [ent] = { face, env, from, untilT, cur, seed, rest }
local talking = LC.LipSyncTalking

local function Range(ent, id)
    if ent.GetFlexBounds then
        local lo, hi = ent:GetFlexBounds(id)
        if lo and hi and hi > lo then return lo, hi end
    end
    return 0, 1
end

local function SetFace(ent, t, open)
    local lo, hi = Range(ent, t.face.jaw)
    ent:SetFlexWeight(t.face.jaw, lo + (hi - lo) * open * 0.7)
    for i, id in ipairs(t.face.lips) do
        local l2, h2 = Range(ent, id)
        ent:SetFlexWeight(id, l2 + (h2 - l2) * open * (i <= 2 and 0.6 or 0.35))
    end
end

local function Stop(ent, t)
    talking[ent] = nil
    if IsValid(ent) and t.rest then
        for id, w in pairs(t.rest) do ent:SetFlexWeight(id, w) end
    end
end

-- ent starts saying path, `secs` long. false when the game does it itself (the recording has its phoneme
-- track), or there is no face to move.
function LC.LipSyncStart(ent, path, secs)
    if not IsValid(ent) or (ent.IsPlayer and ent:IsPlayer()) then return false end
    local was = talking[ent]
    local v = LC.LipSyncVoice(path)
    if v and v.phonemes then
        if was then Stop(ent, was) end
        return false
    end
    local face = LC.LipSyncFace(ent)
    if not face then return false end
    local rest = was and was.rest
    if not rest then
        rest = { [face.jaw] = ent.GetFlexWeight and ent:GetFlexWeight(face.jaw) or 0 }
        for _, id in ipairs(face.lips) do rest[id] = ent.GetFlexWeight and ent:GetFlexWeight(id) or 0 end
    end
    local now = CurTime()
    talking[ent] = { face = face, env = v and v.env, from = now, untilT = now + (secs or 2.5), cur = was and was.cur or 0,
        seed = (ent.EntIndex and ent:EntIndex() or 0) % 7, rest = rest }
    return true
end

function LC.LipSyncWork(now)
    now = now or CurTime()
    for ent, t in pairs(talking) do
        if not IsValid(ent) then
            talking[ent] = nil
        elseif now >= t.untilT or (ent.Health and ent:Health() <= 0) then
            Stop(ent, t)
        else
            local at = now - t.from + LC.LipSyncLead
            local want = t.env and LC.LipSyncLevel(t.env, at) or LC.LipSyncOpen(at, t.untilT - now, t.seed)
            -- opens quickly, closes a little slower (as a jaw does)
            t.cur = t.cur + (want - t.cur) * (want > t.cur and 0.7 or 0.45)
            SetFace(ent, t, t.cur)
        end
    end
end
hook.Add("Think", "LivingCityLipSync", function()
    if next(talking) ~= nil then LC.LipSyncWork() end
end)
