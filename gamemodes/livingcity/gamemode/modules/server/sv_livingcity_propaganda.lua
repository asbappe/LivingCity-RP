--[[
    Living City: street furniture, and the city's voice

      Bins, streetlights, loudspeakers, screens   placed with the editor
                      (the "Street" section). Bins are searchable and stops on
                      bin runs. Streetlights light the street. Loudspeakers
                      carry the PA. Streetlights and loudspeakers break when
                      shot, or now and then by themselves; broken, a
                      streetlight goes dark and a loudspeaker goes quiet: the
                      PA and broadcasts can't be heard near it until the
                      maintenance or radio repair crew fixes it (their shifts
                      go to the broken ones first). Screens come as a wall
                      screen, a giant Breencast screen, and a small TV.
      Broadcasts      the Director of Propaganda (a City Administrator special)
                      carries a microphone. Left click goes live: for up to a
                      minute their voice, and what they type, goes out over
                      every loudspeaker and screen in the city. The
                      transmitter needs lc_broadcast_cooldown minutes (15)
                      before anyone can go live again. A minute on air from
                      the Combine settles the city (rebel ground stops
                      spreading for a while); a minute from anyone else is a
                      pirate broadcast (rebel ground spreads faster, and
                      sociostability slips). The microphone drops when its
                      holder dies, and can be taken off someone tied up or
                      with their hands up (the actions menu, F1): the Resistance would
                      love one.

      The Administrator (DORMANT: off unless lc_breen_broadcasts is 1) with no player as Director of Propaganda, every
                      lc_broadcast_cooldown minutes the city's Administrator
                      (lc_administrator_name, a woman; Dr. Mossman's model by
                      default, lc_administrator_model) addresses the city
                      herself: her recordings from
                      sound/livingcity/announce/administrator/ambient/ over every
                      loudspeaker, and, if the map has a broadcast studio
                      (an editor point), her at it, filmed live by the
                      camera scanner. Kill her on air and the microphone
                      drops: take it, and the transmitter is yours.
                      (Dr. Breen's own stock Breencasts are used too only with
                      lc_administrator_stock_lines 1.)

      lc_broadcast_cooldown (15), lc_broadcast_seconds (60), lc_fixture_wear 0/1,
      lc_breen_broadcasts 0/1 (off by default: dormant until there are enough lines)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCool = CreateConVar("lc_broadcast_cooldown", "15", FLAGS, "Minutes before anyone can broadcast again")
local cvSecs = CreateConVar("lc_broadcast_seconds", "60", FLAGS, "Longest a broadcast can run")
local cvWear = CreateConVar("lc_fixture_wear", "1", FLAGS, "Streetlights and loudspeakers break now and then by themselves")

local function Pick(t) return t[math.random(#t)] end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end

------------------------------------------------------------------------
-- Streetlights and loudspeakers break, and get fixed
------------------------------------------------------------------------

local STREET = { lc_streetlight = "streetlight", lc_loudspeaker = "loudspeaker" }

function LC.BreakStreetFixture(e, by)
    if not IsValid(e) or e:GetNW2Bool("lc_broken", false) then return false end
    e:SetNW2Bool("lc_broken", true)
    LC.FixtureVersion = (LC.FixtureVersion or 0) + 1
    e.lcBrokenAt = CurTime() -- (the city's own crews wait a while for a player: sv_livingcity_npcwork.lua)
    local fx = EffectData()
    fx:SetOrigin(e:WorldSpaceCenter())
    util.Effect("Sparks", fx, true, true)
    e:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75)
    if IsValid(by) and by:IsPlayer() and LC.SeenBySecurity and LC.SeenBySecurity(by, 900) and not (LC.PlayerIsCP and LC.PlayerIsCP(by)) then
        LC.ReportCrime(by, "Vandalism", 90)
    end
    hook.Run("LivingCityFixtureBroken", e, STREET[e:GetClass()])
    return true
end

function LC.RepairStreetFixture(e)
    if not IsValid(e) or not e:GetNW2Bool("lc_broken", false) then return false end
    e:SetNW2Bool("lc_broken", false)
    LC.FixtureVersion = (LC.FixtureVersion or 0) + 1
    e:EmitSound("buttons/button1.wav", 65)
    return true
end

-- The placed ones of a kind ("lc_streetlight", "lc_loudspeaker"), broken first.
function LC.StreetFixtures(cls, near, maxD)
    local broken, ok = {}, {}
    for _, e in ipairs(LC.EntsOf(cls)) do
        if not near or e:GetPos():DistToSqr(near) < (maxD or 3000) ^ 2 then
            table.insert(e:GetNW2Bool("lc_broken", false) and broken or ok, e)
        end
    end
    for _, e in ipairs(ok) do broken[#broken + 1] = e end
    return broken
end

-- Is the loudspeaker nearest here broken? (Then the PA isn't heard here.)
function LC.SpeakerBrokenNear(pos)
    local best, bd
    for _, e in ipairs(LC.EntsOf("lc_loudspeaker")) do
        local d = e:GetPos():DistToSqr(pos)
        if d < 2500 * 2500 and (not bd or d < bd) then best, bd = e, d end
    end
    return best ~= nil and (best:GetNW2Bool("lc_broken", false) or best:GetNW2Bool("lc_nopower", false)) -- broken, or no power (sv_livingcity_power.lua)
end

timer.Create("LivingCityFixtureWear", 300, 0, function()
    if not cvWear:GetBool() or not LC.Running or math.random() > 0.3 then return end
    local all = {}
    for cls in pairs(STREET) do
        for _, e in ipairs(LC.EntsOf(cls)) do if not e:GetNW2Bool("lc_broken", false) then all[#all + 1] = e end end
    end
    if #all > 0 then LC.BreakStreetFixture(Pick(all), nil) end
end)

------------------------------------------------------------------------
-- Broadcasts
------------------------------------------------------------------------

LC.LiveSpeaker = LC.LiveSpeaker or nil

local function HoldingMic(ply) local w = ply:GetActiveWeapon() return IsValid(w) and w:GetClass() == "weapon_lc_microphone" end
local function Official(ply) return ply:GetNW2String("lcf_special", "") == "propaganda_director" or (LC.PlayerIsCP and LC.PlayerIsCP(ply) and ply:GetNW2String("lcf_faction", "") == "admin") end

-- The camera: a scanner comes down out of the sky and films whoever has the
-- microphone (entities/lc_broadcastcam.lua). It films the one holding it, nobody else.
local cvCam = CreateConVar("lc_broadcast_camera", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "A scanner films broadcasts for the city screens")

function LC.SendBroadcastCamera(ply)
    if not cvCam:GetBool() or not IsValid(ply) then return nil end
    local old = GetGlobal2Entity("lc_live_cam")
    if IsValid(old) then old:Remove() end
    local cam = ents.Create("lc_broadcastcam")
    if not IsValid(cam) then return nil end
    local eye = ply:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + Vector(0, 0, 420), filter = ply, mask = MASK_SOLID_BRUSHONLY })
    local from = tr.Hit and (tr.HitPos - Vector(0, 0, 24)) or (eye + Vector(0, 0, 420))
    cam:SetPos(from + Angle(0, ply:EyeAngles().y, 0):Forward() * 60)
    cam:SetAngles(Angle(30, ply:EyeAngles().y + 180, 0))
    cam:Spawn()
    cam:SetNW2Entity("lc_subject", ply)
    SetGlobal2Entity("lc_live_cam", cam)
    return cam
end

function LC.StartBroadcast(ply)
    if LC.LiveSpeaker then return false, "Someone is already on air." end
    -- The Administrator's recorded address (below): the Director of Propaganda can cut in; anyone else waits
    if LC.LiveNPC then
        if not Official(ply) then return false, LC.AdministratorName() .. " is on air. The transmitter is hers until she's done." end
        LC.StopNPCBroadcast("preempted")
    end
    local now = CurTime()
    local wait = GetGlobal2Float("lc_live_next", 0) - now
    -- (the Administrator's own addresses don't wait for the transmitter: the owner, 7 November, "an announcement option")
    local theAdmin = LC.IsAdministrator and LC.IsAdministrator(ply)
    if wait > 0 and not theAdmin then return false, string.format("The transmitter is cooling down: %d:%02d.", math.floor(wait / 60), math.floor(wait % 60)) end
    local pirate = not Official(ply)
    LC.LiveSpeaker = ply
    LC.LiveStart = now
    SetGlobal2Entity("lc_live", ply)
    SetGlobal2Bool("lc_live_pirate", pirate)
    SetGlobal2Float("lc_live_until", now + cvSecs:GetFloat())
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(pirate and ("[Pirate broadcast] Someone has seized the city's transmitter: " .. ply:Nick() .. ".")
            or ("[City broadcast] " .. ply:Nick() .. " is on air."))
    end
    if pirate then
        for _, p in ipairs(player.GetAll()) do
            if LC.PlayerIsCP and LC.PlayerIsCP(p) then p:ChatPrint("[CP net] The city transmitter has been seized. Find whoever has the microphone.") end
        end
    end
    LC.SendBroadcastCamera(ply)
    hook.Run("LivingCityBroadcastStart", ply, pirate)
    return true
end

function LC.StopBroadcast(why)
    local ply = LC.LiveSpeaker
    if not ply then return false end
    local now = CurTime()
    local lasted = now - (LC.LiveStart or now)
    local pirate = GetGlobal2Bool("lc_live_pirate", false)
    LC.LiveSpeaker = nil
    SetGlobal2Entity("lc_live", NULL)
    SetGlobal2Float("lc_live_until", 0)
    local cam = GetGlobal2Entity("lc_live_cam")
    if IsValid(cam) then cam.leaving = cam.leaving or CurTime() end -- (it flies off: entities/lc_broadcastcam.lua)
    SetGlobal2Entity("lc_live_cam", NULL)
    SetGlobal2Float("lc_live_next", now + cvCool:GetFloat() * 60)
    for _, p in ipairs(player.GetAll()) do p:ChatPrint(pirate and "[Pirate broadcast] The transmission ends." or "[City broadcast] Off air.") end
    if lasted >= 30 then
        if pirate then
            LC.RebelSurgeUntil = now + 600
            LC.SocioOverride = { level = "yellow", untilT = now + 600, by = "pirate broadcast" }
            if LC.RefreshSocio then pcall(LC.RefreshSocio, false, true) end
            if IsValid(ply) and ply:GetNW2String("lcf_faction", "") == "resistance" and LC.AddXP then LC.AddXP(ply, 40, "pirate broadcast") end
        else
            LC.RebelCalmUntil = now + 600
            if LC.RebelSurgeUntil and LC.RebelSurgeUntil > now then LC.RebelSurgeUntil = now end
            if IsValid(ply) and LC.AddXP then LC.AddXP(ply, 15, "city broadcast") end
        end
    end
    hook.Run("LivingCityBroadcastEnd", ply, pirate, lasted)
    return true
end

function LC.ToggleBroadcast(ply)
    if LC.LiveSpeaker == ply then LC.StopBroadcast("off air") return true end
    if not HoldingMic(ply) then return false, "You need the microphone in your hand." end
    return LC.StartBroadcast(ply)
end

-- Heard everywhere, except where the loudspeaker is broken. (The engine asks
-- this many times a second for every listener: the answer is kept for a second,
-- unless they've moved or a loudspeaker broke or got fixed.)
local function BrokenFor(listener)
    local now, pos, ver = CurTime(), listener:GetPos(), LC.FixtureVersion or 0
    local c = listener.lcSpkCache
    if c and now - c.t < 1 and c.ver == ver and c.pos:DistToSqr(pos) < 64 * 64 then return c.v end
    local v = LC.SpeakerBrokenNear(pos)
    listener.lcSpkCache = { t = now, ver = ver, pos = pos, v = v }
    return v
end

hook.Add("PlayerCanHearPlayersVoice", "LivingCityBroadcast", function(listener, talker)
    if talker ~= LC.LiveSpeaker or listener == talker then return end
    if BrokenFor(listener) then return end
    return true, false
end)

-- What the speaker types goes out too
hook.Add("PlayerSay", "LivingCityBroadcast", function(ply, text)
    if ply ~= LC.LiveSpeaker then return end
    local t = string.Trim(text)
    if t == "" or string.sub(t, 1, 1) == "!" or string.sub(t, 1, 1) == "/" then return end
    local tag = GetGlobal2Bool("lc_live_pirate", false) and "[Pirate broadcast] " or "[City broadcast] "
    for _, p in ipairs(player.GetAll()) do
        if p == ply or not LC.SpeakerBrokenNear(p:GetPos()) then p:ChatPrint(tag .. ply:Nick() .. ": " .. t) end
    end
    return ""
end)

timer.Create("LivingCityBroadcast", 1, 0, function()
    local p = LC.LiveSpeaker
    if not p then return end
    if not IsValid(p) or not p:Alive() or not HoldingMic(p) or CurTime() > GetGlobal2Float("lc_live_until", 0) then LC.StopBroadcast("ended") end
end)

-- The microphone drops when its holder dies
hook.Add("DoPlayerDeath", "LivingCityMicrophone", function(ply)
    if LC.LiveSpeaker == ply then LC.StopBroadcast("ended") end
    if ply:HasWeapon("weapon_lc_microphone") then
        ply:StripWeapon("weapon_lc_microphone")
        local w = ents.Create("weapon_lc_microphone")
        if IsValid(w) then
            w:SetPos(ply:GetPos() + Vector(0, 0, 30))
            w:Spawn()
        end
    end
end)

-- Taking it off someone tied up, or with their hands up (the actions menu, F1)
function LC.TakeMicrophone(ply, target)
    if not IsValid(target) or not target:IsPlayer() or target == ply then return false, "Look at who has it." end
    if target:GetPos():DistToSqr(ply:GetPos()) > 130 * 130 then return false, "Get closer." end
    if not target:HasWeapon("weapon_lc_microphone") then return false, "They haven't got a microphone." end
    if not (target:GetNW2Bool("lc_tied", false) or target:GetNW2Bool("lc_handsup", false)) then
        return false, "Not while they can stop you: hands up, or cuffed."
    end
    if LC.LiveSpeaker == target then LC.StopBroadcast("seized") end
    target:StripWeapon("weapon_lc_microphone")
    ply:Give("weapon_lc_microphone")
    target:ChatPrint("[City] " .. ply:Nick() .. " takes the microphone off you.")
    ply:ChatPrint("[City] You take the microphone. Left click with it to go on air, when the transmitter's ready.")
    if (LC.PlayerIsCP and LC.PlayerIsCP(target)) or target:GetNW2String("lcf_special", "") == "propaganda_director" then
        for _, p in ipairs(player.GetAll()) do
            if LC.PlayerIsCP and LC.PlayerIsCP(p) then p:ChatPrint("[CP net] The city microphone has been stolen " .. Where(target:GetPos()) .. ".") end
        end
    end
    return true
end

------------------------------------------------------------------------
-- Dr. Breen: the city's own broadcasts, when no player is Director of Propaganda
------------------------------------------------------------------------

util.AddNetworkString("lc_breencast")
-- Dormant by default until there are enough recordings. Switch on with lc_breen_broadcasts 1 (the lc_breencast command still works for a test).
local cvNPCCast = CreateConVar("lc_breen_broadcasts", "0", FLAGS, "With no player as Director of Propaganda, the Administrator addresses the city now and then (off: dormant)")
local cvAdminName = CreateConVar("lc_administrator_name", "The Administrator", FLAGS, "What the city's Administrator is called on screen, in chat and on air")
local cvAdminModel = CreateConVar("lc_administrator_model", "models/mossman.mdl", FLAGS, "The Administrator's model at the broadcast studio (Dr. Mossman by default)")
local cvStock = CreateConVar("lc_administrator_stock_lines", "0", FLAGS, "Also use Dr. Breen's own stock Breencast lines in her broadcasts (a man's voice: off)")
function LC.AdministratorName()
    local n = string.Trim(cvAdminName:GetString() or "")
    return n ~= "" and n or "The Administrator"
end

-- Dr. Breen's stock addresses (the game's own Breencast lines), only with
-- lc_administrator_stock_lines 1. Only the ones this install actually has are used.
local BREEN_SETS = { { "br_welcome", 7 }, { "br_instinct", 25 }, { "br_collaboration", 11 }, { "br_overwatch", 9 }, { "br_disruptor", 8 } }
local breenLines
function LC.BreenLines()
    if not cvStock:GetBool() then return {} end
    if breenLines and #breenLines > 0 then return breenLines end
    local out = {}
    for _, set in ipairs(BREEN_SETS) do
        for i = 1, set[2] do
            local p = string.format("vo/breencast/%s%02d.wav", set[1], i)
            if file.Exists("sound/" .. p, "GAME") then out[#out + 1] = p end
        end
    end
    breenLines = out
    return out
end

-- One broadcast: her addresses whole, each line in the order they were recorded,
-- starting with one not given last time (and the next ones after it, if
-- there's time).
local lastSpeech
function LC.BreenProgram()
    local speeches = {}
    for _, set in ipairs(cvStock:GetBool() and BREEN_SETS or {}) do
        local lines = {}
        for i = 1, set[2] do
            local p = string.format("vo/breencast/%s%02d.wav", set[1], i)
            if file.Exists("sound/" .. p, "GAME") then lines[#lines + 1] = p end
        end
        if #lines > 0 then speeches[#speeches + 1] = { name = set[1], lines = lines } end
    end
    -- and the recordings dropped in sound/livingcity/announce/administrator/ambient/ (sv_livingcity_announcer.lua)
    local custom = {}
    for _, c in ipairs(LC.AnnounceClips and LC.AnnounceClips("administrator", "ambient") or {}) do custom[#custom + 1] = c.path end
    if #custom > 0 then speeches[#speeches + 1] = { name = "custom_ambient", lines = custom } end
    if #speeches == 0 then return {} end
    local start = math.random(#speeches)
    if #speeches > 1 and speeches[start].name == lastSpeech then start = start % #speeches + 1 end
    lastSpeech = speeches[start].name
    local out = {}
    for k = 0, #speeches - 1 do
        for _, p in ipairs(speeches[(start - 1 + k) % #speeches + 1].lines) do out[#out + 1] = p end
    end
    return out
end

LC.NPCBroadcastNext = LC.NPCBroadcastNext or 0

local function HumanPropagandaOnline()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetNW2String("lcf_special", "") == "propaganda_director" then return true end
    end
    return false
end

local function SpawnBreen(pt)
    local mdl = string.Trim(cvAdminModel:GetString() or "")
    if mdl == "" or (util.IsValidModel and not util.IsValidModel(mdl)) then mdl = "models/mossman.mdl" end
    local npc = ents.Create("npc_citizen")
    if IsValid(npc) then
        npc:SetModel(mdl)
    else
        npc = ents.Create("npc_breen")
        if not IsValid(npc) then return nil end
    end
    npc:SetPos(pt.pos + Vector(0, 0, 4))
    npc:SetAngles(Angle(0, pt.yaw or 0, 0))
    npc:SetKeyValue("spawnflags", tostring((SF_NPC_GAG or 4) + (SF_NPC_FADE_CORPSE or 512)))
    npc:Spawn()
    npc:Activate()
    LC.SetNPCStr(npc, "lc_pname", LC.AdministratorName())
    LC.SetNPCStr(npc, "lc_pjob", "Administrator")
    npc.lcBreen = true
    return npc
end

local function BreenLeaves(npc)
    if not IsValid(npc) then return end
    local tries = 0
    timer.Create("LivingCityBreenLeaves" .. npc:EntIndex(), 5, 30, function()
        tries = tries + 1
        if not IsValid(npc) then return end
        if tries >= 30 or not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then npc:Remove() end
    end)
end

-- How long a recording runs, from the file itself: SoundDuration can say 0 on
-- a dedicated server, so the wav's own header is read when it does.
local durations = {}
function LC.WavDuration(path)
    if string.lower(string.sub(path or "", -4)) == ".mp3" then return LC.Mp3Duration(path) end
    if durations[path] ~= nil then return durations[path] or nil end
    durations[path] = false
    local f = file.Open and file.Open("sound/" .. path, "rb", "GAME")
    if not f then return nil end
    local ok, secs = pcall(function()
        if f:Read(4) ~= "RIFF" then return nil end
        f:Read(4)
        if f:Read(4) ~= "WAVE" then return nil end
        local byteRate
        for _ = 1, 16 do -- (fmt, then data; a cue or a LIST chunk may be in between)
            local id = f:Read(4)
            if not id or #id < 4 then return nil end
            local size = f:ReadULong()
            if not size then return nil end
            if id == "fmt " then
                f:ReadUShort() f:ReadUShort() f:ReadULong() -- format, channels, sample rate
                byteRate = f:ReadULong()
                f:Skip(size - 12 + size % 2)
            elseif id == "data" then
                return byteRate and byteRate > 0 and size / byteRate or nil
            else
                f:Skip(size + size % 2)
            end
        end
        return nil
    end)
    f:Close()
    if ok and secs and secs > 0.2 and secs < 60 then durations[path] = secs return secs end
    return nil
end

-- An .mp3's length, from its first frame: the frame count a VBR file keeps
-- there (Xing, Info or VBRI), else its size over its bitrate.
local MP3_RATE = { { 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 },
    { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 } }
local MP3_HZ = { 44100, 48000, 32000 }
local function BE(s, i) return ((s:byte(i) * 256 + s:byte(i + 1)) * 256 + s:byte(i + 2)) * 256 + s:byte(i + 3) end

-- { at (where the audio starts), hz, kbps, spf (samples a frame), mono } of an mp3's first frame
function LC.Mp3Frame(data)
    if not data or #data < 16 then return nil end
    local at = 1
    if data:sub(1, 3) == "ID3" and #data >= 10 then
        local b = { data:byte(7, 10) }
        at = 11 + b[1] % 128 * 2097152 + b[2] % 128 * 16384 + b[3] % 128 * 128 + b[4] % 128
        if math.floor(data:byte(6) / 16) % 2 == 1 then at = at + 10 end -- (a footer)
    end
    for i = at, math.min(#data - 4, at + 65536) do
        local a, b, c, d = data:byte(i, i + 3)
        if a == 255 and b >= 224 then
            local ver, layer = math.floor(b / 8) % 4, math.floor(b / 2) % 4
            local bi, si = math.floor(c / 16), math.floor(c / 4) % 4
            if ver ~= 1 and layer == 1 and bi > 0 and bi < 15 and si < 3 then
                local mpeg1 = ver == 3
                return { at = i, hz = MP3_HZ[si + 1] / (mpeg1 and 1 or (ver == 2 and 2 or 4)), kbps = MP3_RATE[mpeg1 and 1 or 2][bi],
                    spf = mpeg1 and 1152 or 576, mono = math.floor(d / 64) == 3, mpeg1 = mpeg1 }
            end
        end
    end
    return nil
end

function LC.Mp3Duration(path)
    if durations[path] ~= nil then return durations[path] or nil end
    durations[path] = false
    local data = file.Read("sound/" .. path, "GAME")
    local fr = LC.Mp3Frame(data)
    if not fr then return nil end
    local side = fr.mpeg1 and (fr.mono and 17 or 32) or (fr.mono and 9 or 17)
    local secs
    local x = fr.at + 4 + side
    local tag = data:sub(x, x + 3)
    if (tag == "Xing" or tag == "Info") and #data >= x + 11 and BE(data, x + 4) % 2 == 1 then
        secs = BE(data, x + 8) * fr.spf / fr.hz
    elseif data:sub(fr.at + 36, fr.at + 39) == "VBRI" and #data >= fr.at + 53 then
        secs = BE(data, fr.at + 50) * fr.spf / fr.hz
    else
        local size = #data - fr.at + 1
        if data:sub(-128, -126) == "TAG" then size = size - 128 end
        secs = size * 8 / (fr.kbps * 1000)
    end
    if secs and secs > 0.2 and secs < 3600 then durations[path] = secs return secs end
    return nil
end

-- What's wrong with a sound file, for the game (nil: nothing). A player's game
-- plays a file by its name: an MP3 renamed .wav is silent for everyone, and a
-- WAV must be 8 or 16-bit at 44100, 22050 or 11025 Hz.
local GOOD_HZ = { [44100] = true, [22050] = true, [11025] = true }
local function U16(s, i) return s:byte(i) + s:byte(i + 1) * 256 end
local function U32(s, i) return U16(s, i) + U16(s, i + 2) * 65536 end
-- song: played by the game's music player (sound.PlayFile), which takes an
-- .mp3 or .ogg at any rate: only a file that isn't what its name says matters.
function LC.SoundProblem(path, song)
    local ext = string.lower(string.match(path or "", "%.(%w+)$") or "")
    local data = file.Read("sound/" .. path, "GAME")
    if not data or #data < 12 then return "empty, or couldn't be read" end
    local riff, ogg = data:sub(1, 4) == "RIFF", data:sub(1, 4) == "OggS"
    local mp3 = not riff and not ogg and LC.Mp3Frame(data) ~= nil
    if ext == "wav" then
        if mp3 then return "it's really an MP3 named .wav, so nobody hears it: rename it to .mp3" end
        if ogg then return "it's really an OGG named .wav, so nobody hears it: rename it to .ogg" end
        if not riff or data:sub(9, 12) ~= "WAVE" then return "not a real WAV: convert it (16-bit, 44100 Hz)" end
        local i = 13
        while i + 8 <= #data do
            local id, size = data:sub(i, i + 3), U32(data, i + 4)
            if id == "fmt " and i + 23 <= #data then
                local fmt, hz, bits = U16(data, i + 8), U32(data, i + 12), U16(data, i + 22)
                if fmt == 65534 then fmt = 1 end -- (extensible: PCM)
                if fmt == 1 and bits ~= 8 and bits ~= 16 then return bits .. "-bit, which the game can't play: convert it to 16-bit" end
                if fmt == 3 then return "32-bit float, which the game can't play: convert it to 16-bit" end
                if not GOOD_HZ[hz] then return hz .. " Hz, which the game can't play: convert it to 44100 Hz" end
                return nil
            end
            i = i + 8 + size + size % 2
        end
        return "not a real WAV: convert it (16-bit, 44100 Hz)"
    elseif ext == "mp3" then
        if riff then return "it's really a WAV named .mp3: rename it to .wav" end
        if ogg then return "it's really an OGG named .mp3: rename it to .ogg" end
        local fr = LC.Mp3Frame(data)
        if not fr then return "not a real MP3" end
        if not GOOD_HZ[fr.hz] and not song then return fr.hz .. " Hz, which may play at the wrong speed: convert it to 44100 Hz" end
    elseif ext == "ogg" then
        if riff then return "it's really a WAV named .ogg: rename it to .wav" end
        if mp3 then return "it's really an MP3 named .ogg: rename it to .mp3" end
    end
    return nil
end

-- Every sound file in a folder (under sound/) the game can't play: { "name: why" }
function LC.SoundProblems(dir, song)
    local out = {}
    local names = file.Find("sound/" .. dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, name in ipairs(names) do
        local ext = string.lower(string.match(name, "%.(%w+)$") or "")
        if ext == "wav" or ext == "mp3" or ext == "ogg" then
            local why = LC.SoundProblem(dir .. "/" .. name, song)
            if why then out[#out + 1] = name .. ": " .. why end
        end
    end
    return out
end

local function LineSecs(path)
    local dur = SoundDuration and SoundDuration(path) or 0
    if dur and dur > 0.2 and dur <= 30 then return dur end
    return LC.WavDuration(path) or 6
end

-- Over the loudspeakers: not where one is broken or the power's out, and not
-- twice for anyone standing in the studio with her (they hear her in person).
-- How far her own voice, in the studio, carries: anyone within it hears her in
-- person and not over the loudspeakers too (two copies a beat apart otherwise).
-- Her voice is pitched to fade out by about here.
local IN_PERSON = 1600
local IN_PERSON_LEVEL = 65

function LC.BreencastListeners()
    local live = LC.LiveNPC
    local npc = live and live.npc
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        local pos = p:GetPos()
        if not (IsValid(npc) and pos:DistToSqr(npc:GetPos()) < IN_PERSON * IN_PERSON) and not LC.SpeakerBrokenNear(pos) then
            out[#out + 1] = p
        end
    end
    return out
end

local function NextLine()
    local live = LC.LiveNPC
    if not live then return end
    local now = CurTime()
    live.i = live.i + 1
    local path = live.lines[(live.i - 1) % #live.lines + 1]
    local dur = LineSecs(path)
    if now + dur > live.untilT + 4 and live.i > 1 then return LC.StopNPCBroadcast("ended") end
    local to = LC.BreencastListeners()
    if #to > 0 then
        net.Start("lc_breencast")
        net.WriteString(path)
        net.WriteFloat(dur)
        net.Send(to)
    end
    if IsValid(live.npc) then live.npc:EmitSound(path, IN_PERSON_LEVEL) end -- in person, at the studio (and her lips move)
    timer.Create("LivingCityBreencast", dur + 0.7, 1, NextLine)
end

function LC.StartNPCBroadcast()
    if LC.LiveSpeaker or LC.LiveNPC then return false, "Someone is already on air." end
    local lines = LC.BreenProgram()
    if #lines == 0 then return false, "No recordings for " .. LC.AdministratorName() .. " yet (sound/livingcity/administrator/, named ambient1.wav and so on)." end
    local now = CurTime()
    local studios = LC.PointsOfKind and LC.PointsOfKind("studio") or {}
    local npc = #studios > 0 and SpawnBreen(Pick(studios)) or nil
    LC.LiveNPC = { npc = npc, start = now, untilT = now + cvSecs:GetFloat(), lines = lines, i = 0 }
    SetGlobal2Entity("lc_live", npc or NULL)
    SetGlobal2Bool("lc_live_npc", true)
    SetGlobal2String("lc_live_name", LC.AdministratorName())
    SetGlobal2Bool("lc_live_pirate", false)
    SetGlobal2Float("lc_live_until", now + cvSecs:GetFloat())
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City broadcast] " .. LC.AdministratorName() .. " addresses the city.") end
    if IsValid(npc) then LC.SendBroadcastCamera(npc) end
    NextLine()
    hook.Run("LivingCityBroadcastStart", npc, false, true)
    return true
end

function LC.StopNPCBroadcast(why)
    local live = LC.LiveNPC
    if not live then return false end
    local now = CurTime()
    LC.LiveNPC = nil
    timer.Remove("LivingCityBreencast")
    SetGlobal2Entity("lc_live", NULL)
    SetGlobal2Bool("lc_live_npc", false)
    SetGlobal2String("lc_live_name", "")
    SetGlobal2Float("lc_live_until", 0)
    local cam = GetGlobal2Entity("lc_live_cam")
    if IsValid(cam) then cam.leaving = cam.leaving or now end
    SetGlobal2Entity("lc_live_cam", NULL)
    LC.NPCBroadcastNext = now + cvCool:GetFloat() * 60 * math.Rand(0.9, 1.25)
    if why == "killed" then
        for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City broadcast] The transmission cuts out.") end
    elseif why ~= "preempted" then
        for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City broadcast] Off air.") end
    end
    -- a Combine broadcast that ran its course settles the city, like anyone's
    if now - live.start >= 30 and why ~= "killed" then
        LC.RebelCalmUntil = now + 600
        if LC.RebelSurgeUntil and LC.RebelSurgeUntil > now then LC.RebelSurgeUntil = now end
    end
    if why ~= "killed" then BreenLeaves(live.npc) end
    hook.Run("LivingCityBroadcastEnd", live.npc, false, now - live.start, true)
    return true
end

-- Kill her on air: the transmission dies, and her microphone is on the floor.
hook.Add("OnNPCKilled", "LivingCityBreen", function(npc, attacker)
    if not npc.lcBreen then return end
    local live = LC.LiveNPC
    if live and live.npc == npc then LC.StopNPCBroadcast("killed") end
    local w = ents.Create("weapon_lc_microphone")
    if IsValid(w) then
        w:SetPos(npc:GetPos() + Vector(0, 0, 30))
        w:Spawn()
    end
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsCP and LC.PlayerIsCP(p) then p:ChatPrint("[CP net] " .. LC.AdministratorName() .. " has been attacked " .. Where(npc:GetPos()) .. ". Secure the microphone.") end
    end
    if IsValid(attacker) and attacker:IsPlayer() and LC.ReportCrime then LC.ReportCrime(attacker, "Attacking the Administrator", 600) end
end)

-- A player's broadcast pushes her next one back.
hook.Add("LivingCityBroadcastEnd", "LivingCityBreenSchedule", function(_, _, _, npc)
    if not npc then LC.NPCBroadcastNext = math.max(LC.NPCBroadcastNext or 0, CurTime() + cvCool:GetFloat() * 60) end
end)

function LC.NPCBroadcastTick(now)
    now = now or CurTime()
    local live = LC.LiveNPC
    if live then
        if now > live.untilT + 8 then LC.StopNPCBroadcast("ended") end
        return
    end
    if not cvNPCCast:GetBool() or not LC.Running or LC.LiveSpeaker then return end
    if LC.NPCBroadcastNext == 0 then LC.NPCBroadcastNext = now + math.Rand(240, 420) return end -- not straight away
    if now < LC.NPCBroadcastNext or now < GetGlobal2Float("lc_live_next", 0) then return end
    if HumanPropagandaOnline() or (LC.HumanAdministrator and LC.HumanAdministrator()) then LC.NPCBroadcastNext = now + 120 return end -- (a player is the Administrator: she speaks for herself)
    if not LC.StartNPCBroadcast() then LC.NPCBroadcastNext = now + 600 end
end

timer.Create("LivingCityNPCBroadcast", 10, 0, function()
    local ok, err = pcall(LC.NPCBroadcastTick)
    if not ok and LC.Error then LC.Error("npc broadcast", err) end
end)

concommand.Add("lc_breencast", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local ok, why = LC.StartNPCBroadcast()
    local msg = ok and "[Living City] " .. LC.AdministratorName() .. " is on air." or ("[Living City] " .. tostring(why))
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
