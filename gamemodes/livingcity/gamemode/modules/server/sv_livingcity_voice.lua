--[[
    Living City: the Administrator's spoken decrees (the owner, 11 November: "Please build it but I
    don't have the key or voice id so just leave it disabled for now, ready to turn on in the future")

    When the city's own Administrator issues a decree with a sentence of her own
    (sv_livingcity_brain.lua, LC.AdminApply), that sentence is spoken in her voice: the server asks
    ElevenLabs' text to speech for it (the service the owner made her recordings with), gets a small
    MP3 back, and sends it to every player to play (cl_livingcity_voice.lua). It waits for the PA to
    finish first, so it never talks over a recorded announcement.

    OFF by default (lc_voice 0), and nothing without both a key and a voice id:
      data/livingcity/voice_key.txt   the ElevenLabs key (never sent to players, never printed)
      data/livingcity/voice_id.txt    which voice (the id beside the voice in ElevenLabs' voice list)
    Both are set from the editor panel. Named people's answers in free talk are NOT spoken (it would
    cost many times what the text does).

    Settings: lc_voice 0/1, lc_voice_daily (200 spoken lines a day at most), lc_voice_model (console).
    Not checked against the real service yet: the address, the "xi-api-key" header and the model's
    name are from ElevenLabs' documentation as remembered. The panel's Test button says what it answers.
]]

LC = LC or {}

local FLAGS = FCVAR_ARCHIVE
local cvOn    = CreateConVar("lc_voice", "0", FLAGS, "The city's own Administrator's decrees are spoken in her voice (needs a voice key and a voice id set in the editor panel)")
local cvDaily = CreateConVar("lc_voice_daily", "200", FLAGS, "Most spoken lines in a day (0: no limit)")
local cvModel = CreateConVar("lc_voice_model", "eleven_v4_turbo", FLAGS, "The ElevenLabs model that speaks")

local URL = "https://api.elevenlabs.io/v1/text-to-speech/"
local FORMAT = "mp3_22050_32"    -- (small: about 4 KB a second, so a sentence fits in one net message)
local KEY_FILE, ID_FILE, USE_FILE = "livingcity/voice_key.txt", "livingcity/voice_id.txt", "livingcity/voice_usage.json"
local MAX_BYTES = 60000          -- a net message holds 64 KB
local MAX_CHARS = 200
local WAIT_PA = 40               -- seconds it waits for the PA to fall quiet before speaking anyway

if util and util.AddNetworkString then
    util.AddNetworkString("lc_voice_clip")
    util.AddNetworkString("lc_voice_key")
    util.AddNetworkString("lc_voice_test")
end

LC.Voice = LC.Voice or { calls = 0, chars = 0, day = "", today = 0, seq = 0 }
local V = LC.Voice

-- The web call. The tests put their own in its place.
LC.VoiceHTTP = LC.VoiceHTTP or function(req) return HTTP(req) end

local function ReadFile(path)
    local s = file.Read(path, "DATA")
    return s and string.Trim(s) or ""
end

local function Load()
    if V.key == nil then
        V.key, V.id = ReadFile(KEY_FILE), ReadFile(ID_FILE)
        if SetGlobal2Bool then SetGlobal2Bool("lc_voice_ready", V.key ~= "" and V.id ~= "") end
    end
end

function LC.VoiceReady() Load() return V.key ~= "" and V.id ~= "" end
local function On() return cvOn:GetBool() and LC.VoiceReady() end
LC.VoiceOn = On

-- A blank value leaves what is there; clear = true empties both.
function LC.VoiceSet(key, id, clear)
    Load()
    if file.CreateDir then file.CreateDir("livingcity") end
    key, id = string.Trim(tostring(key or "")), string.Trim(tostring(id or ""))
    if clear then
        V.key, V.id = "", ""
        if file.Delete then file.Delete(KEY_FILE) file.Delete(ID_FILE) end
    else
        if key ~= "" then V.key = key file.Write(KEY_FILE, key) end
        -- (a voice id is letters and digits only: it goes into the address)
        if id ~= "" and string.match(id, "^[%w_%-]+$") then V.id = id file.Write(ID_FILE, id) end
    end
    V.lastError = nil
    if SetGlobal2Bool then SetGlobal2Bool("lc_voice_ready", V.key ~= "" and V.id ~= "") end
    return V.key ~= "", V.id ~= ""
end

local function Today() return os.date("%Y-%m-%d") end
local function LoadUse()
    if V.useLoaded then return end
    V.useLoaded = true
    local t = util.JSONToTable(file.Read(USE_FILE, "DATA") or "") or {}
    if t.day == Today() then V.day, V.today = t.day, tonumber(t.calls) or 0 end
end

-- Asks for the sentence as sound. cb(bytes or nil, why).
function LC.VoiceFetch(text, cb)
    if not LC.VoiceReady() then cb(nil, "no voice key or voice id is set") return false end
    if (V.backOff or 0) > CurTime() then cb(nil, "waiting after a problem") return false end
    LoadUse()
    if V.day ~= Today() then V.day, V.today = Today(), 0 end
    local cap = cvDaily:GetInt()
    if cap > 0 and V.today >= cap then cb(nil, "the day's limit (lc_voice_daily)") return false end
    text = LC.BrainClean and LC.BrainClean(text, MAX_CHARS) or string.sub(tostring(text or ""), 1, MAX_CHARS)
    if text == "" then cb(nil, "nothing to say") return false end
    V.today, V.calls, V.chars = V.today + 1, V.calls + 1, V.chars + #text
    file.Write(USE_FILE, string.format('{"day":"%s","calls":%d}', V.day, V.today))
    local done = false
    local function Finish(bytes, err)
        if done then return end
        done = true
        if err then V.lastError = string.sub(tostring(err), 1, 200) end
        local ok, e = pcall(cb, bytes, err)
        if not ok and LC.Error then LC.Error("voice (answer)", e) end
    end
    local sent, e = pcall(LC.VoiceHTTP, {
        url = URL .. V.id .. "?output_format=" .. FORMAT, method = "POST", type = "application/json", timeout = 30,
        body = LC.BrainJSON({ text = text, model_id = cvModel:GetString() }),
        headers = { ["xi-api-key"] = V.key, ["Accept"] = "audio/mpeg" },
        success = function(code, body)
            if code ~= 200 then
                V.backOff = CurTime() + ((code == 401 or code == 403) and 300 or 60)
                return Finish(nil, "the voice service said " .. tostring(code) .. ": " .. string.sub(tostring(body or ""), 1, 120))
            end
            if type(body) ~= "string" or #body < 200 then return Finish(nil, "the voice service sent nothing to play") end
            if #body > MAX_BYTES then return Finish(nil, "the sound was too big to send (" .. #body .. " bytes)") end
            V.lastOk = os.time()
            Finish(body)
        end,
        failed = function(reason)
            V.backOff = CurTime() + 30
            Finish(nil, "could not reach the voice service: " .. tostring(reason))
        end,
    })
    if not sent then Finish(nil, "the request could not be made: " .. tostring(e)) return false end
    return true
end

-- Sends a clip to players to play. to: a player, a list, or nil for everyone.
function LC.VoiceSend(bytes, title, to)
    V.seq = V.seq + 1
    net.Start("lc_voice_clip")
    net.WriteString(tostring(V.seq))
    net.WriteString(tostring(title or ""))
    net.WriteUInt(#bytes, 16)
    net.WriteData(bytes, #bytes)
    if to then net.Send(to) else net.Broadcast() end
    LC.LastPA = CurTime() -- (the announcer leaves room after it: sv_livingcity_announcer.lua)
end

-- Her sentence, out loud to the city, once the PA is quiet. Nothing if it is off or anything goes wrong.
function LC.VoiceSpeak(text, title)
    if not On() then return false end
    return LC.VoiceFetch(text, function(bytes)
        if not bytes then return end
        local tries = 0
        local function Go()
            tries = tries + 1
            local quiet = LC.PAQuiet and LC.PAQuiet() or 99
            if quiet < 1.5 and tries < WAIT_PA then timer.Simple(1, Go) return end
            LC.VoiceSend(bytes, title)
        end
        Go()
    end)
end

------------------------------------------------------------------------
-- The editor panel
------------------------------------------------------------------------
local function Tell(ply, kind, text)
    if not IsValid(ply) then print("[Living City] " .. text) return end
    if LC.Notice then LC.Notice(ply, kind, "Her voice", text, 8) else ply:ChatPrint("[Living City] " .. text) end
end

-- Speaks a line to the one who asked, whether lc_voice is on or not.
function LC.VoiceTest(ply)
    if not LC.VoiceReady() then Tell(ply, "warn", "Set both the voice key and the voice id first, then press Save.") return false end
    V.backOff = nil
    return LC.VoiceFetch("Citizens. This is your Administrator.", function(bytes, err)
        if bytes then
            LC.VoiceSend(bytes, "The City Administrator", IsValid(ply) and ply or nil)
            Tell(ply, "info", "The voice service answered: you should hear her now.")
        else
            Tell(ply, "warn", "No voice: " .. tostring(err or "unknown"))
        end
    end)
end

if net and net.Receive then
    net.Receive("lc_voice_key", function(_, ply)
        if not IsValid(ply) or not (LC.CanEdit and LC.CanEdit(ply)) then return end
        local key, id, clear = net.ReadString(), net.ReadString(), net.ReadBool()
        local hasKey, hasId = LC.VoiceSet(key, id, clear)
        if LC.Log then LC.Log("info", ply:Nick() .. (clear and " cleared her voice key and id" or " set her voice key or id")) end
        Tell(ply, "info", clear and "Cleared." or string.format("Saved on the server. Key: %s. Voice id: %s.", hasKey and "set" or "not set", hasId and "set" or "not set"))
    end)
    net.Receive("lc_voice_test", function(_, ply)
        if not IsValid(ply) or not (LC.CanEdit and LC.CanEdit(ply)) then return end
        LC.VoiceTest(ply)
    end)
end

-- For the debug report (never the key).
function LC.VoiceReport()
    Load() LoadUse()
    local out = { string.format("lc_voice %s | key %s | voice id %s | model %s | spoken today %d of %s | this map %d lines, %d characters", cvOn:GetString(),
        V.key ~= "" and "set" or "NOT SET", V.id ~= "" and "set" or "NOT SET", cvModel:GetString(), V.day == Today() and V.today or 0, cvDaily:GetString(), V.calls, V.chars) }
    if V.lastError then out[#out + 1] = "last problem: " .. V.lastError end
    return out
end
