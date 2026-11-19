--[[
    Living City: playing a spoken line the server sends (sv_livingcity_voice.lua)

    The server sends a small MP3 (the city's own Administrator's sentence). It is written to
    data/livingcity_voice/ on this machine and played from there, everywhere at once like the PA.
    The last few are kept; older ones are deleted.
]]

LC_CL = LC_CL or {}

local DIR = "livingcity_voice"
local KEEP = 4
local playing -- (kept, or the sound stops when it is collected)

local function Tidy()
    local files = file.Find(DIR .. "/*", "DATA") or {}
    table.sort(files)
    for i = 1, #files - KEEP do file.Delete(DIR .. "/" .. files[i]) end
end

function LC_CL.VoicePlay(id, title, bytes)
    if not bytes or #bytes == 0 or not (sound and sound.PlayFile) then return false end
    if not file.IsDir(DIR, "DATA") then file.CreateDir(DIR) end
    local name = string.format("%s/%d_%s", DIR, os.time(), string.gsub(tostring(id), "[^%w]", ""))
    -- (.mp3 where the game lets a file be written with that ending; .dat otherwise, which plays the same)
    local path = name .. ".mp3"
    file.Write(path, bytes)
    if not file.Exists(path, "DATA") then
        path = name .. ".dat"
        file.Write(path, bytes)
        if not file.Exists(path, "DATA") then return false end
    end
    sound.PlayFile("data/" .. path, "noplay", function(ch)
        if not IsValid(ch) then return end
        if IsValid(playing) then playing:Stop() end
        playing = ch
        ch:SetVolume(1)
        ch:Play()
    end)
    LC.Try(Tidy)
    return true
end

net.Receive("lc_voice_clip", function()
    local id, title = net.ReadString(), net.ReadString()
    local n = net.ReadUInt(16)
    local bytes = net.ReadData(n)
    LC_CL.VoicePlay(id, title, bytes)
end)
