--[[
    Living City: the sound guard (server and client)

    The owner, 12 November: "Can we make a sound check that stops sounds that have played more
    than like 4 times in a row for no reason? EVERY single time we have introduced a custom sound
    for something, it gets stuck looping, we need a way to check against that."

    Every sound the gamemode starts goes through LC.SoundGuardCheck first: Entity:EmitSound,
    sound.Play and CreateSound (both sides), and on a player's computer surface.PlaySound and
    sound.PlayFile too. The same sound started on the same thing (an entity, a spot in the world,
    a player's own screen) more than LC.SoundGuardMax times (4) within LC.SoundGuardWindow seconds
    (20) is refused, the copies already playing are stopped, and a warning goes to the log (the
    debug report lists the latest under "sound guard").

    What counts: the city's own sounds (sound/livingcity/), music, alarms, machines and other
    ambient loops, every looping CreateSound, and anything else not in LC.SoundGuardFree: the
    sounds meant to repeat quickly (footsteps, weapons, physics, buttons, voices, sparks and
    splashes) are left alone, and so are the dreams' recorded lines (LC.SoundGuardLines).

    The dreams: every sound started inside a dream (on a dreamer, on anything the dream made, or
    in the dream zone) is remembered, and when the dream ends, or one dreamer wakes, each is
    stopped (LC.SoundGuardDreamEnd): on the server, and on each dreamer's own computer, along with
    any song or voice the dream was playing there (faded out).
]]

LC = LC or {}

LC.SoundGuardMax = 4       -- (starts allowed in the window; the next is refused)
LC.SoundGuardWindow = 20   -- (seconds)
-- Always counted, whatever the free list says (these are the ones that get stuck).
LC.SoundGuardAlways = { "livingcity/", "music/", "ambient/alarms/", "ambient/levels/", "ambient/machines/", "ambient/atmosphere/",
    "ambient/water/water_flow", "npc/vort/attack_charge", "npc/attack_helicopter/aheli_rotor", "npc/combine_gunship/engine" }
-- Meant to repeat quickly: never refused.
-- The city's own lines said in the dreams (one recording each time, never looping: a quiz question or a "FLIP!" may come often).
LC.SoundGuardLines = { "livingcity/dreams/voice/" }
LC.SoundGuardFree = { "player/", "physics/", "weapons/", "items/", "buttons/", "ui/", "garrysmod/", "common/", "vo/", "npc/",
    "ambient/energy/", "ambient/water/water_splash", "ambient/voices/", "ambient/explosions/", "ambient/fire/", "doors/", "friends/",
    "hl1/", "vehicles/", "phx/", "plats/" }

local recent = {}   -- [key] = { times }
local warned = {}   -- [key] = when last logged
LC.SoundGuardStopped = LC.SoundGuardStopped or {} -- the latest refusals: { { t, snd, where } }, newest last

local function Clean(snd)
    if type(snd) ~= "string" then return nil end
    local s = string.lower(string.gsub(snd, "\\", "/"))
    s = string.gsub(s, "^[%*#@<>%^%)%(}%$!?]+", "") -- (the sound-level and spatial markers some paths start with)
    if string.sub(s, 1, 6) == "sound/" then s = string.sub(s, 7) end
    return s
end
LC.SoundGuardClean = Clean

local function Starts(s, list)
    for _, pre in ipairs(list) do if string.sub(s, 1, #pre) == pre then return true end end
    return false
end
-- Is this sound watched? (looping: a CreateSound, which is a loop by nature)
function LC.SoundGuarded(snd, looping)
    local s = Clean(snd)
    if not s or s == "" then return false end
    if Starts(s, LC.SoundGuardLines) then return false end
    if Starts(s, LC.SoundGuardAlways) then return true end
    if looping then return true end
    if not string.find(s, "/", 1, true) then return false end -- (a game sound script's name: the game's own)
    return not Starts(s, LC.SoundGuardFree)
end

local function Who(owner)
    if type(owner) == "string" then return owner end
    if type(owner) == "Vector" or (type(owner) == "table" and owner.x and owner.y and owner.z and not owner.EntIndex) then
        return string.format("at %d %d %d", math.floor(owner.x / 64), math.floor(owner.y / 64), math.floor(owner.z / 64))
    end
    if owner ~= nil and owner.EntIndex then
        local ok, i = pcall(owner.EntIndex, owner)
        if ok and i then return "ent " .. tostring(i) end
    end
    return tostring(owner)
end
LC.SoundGuardWho = Who

local function Warn(key, snd, where, now)
    local list = LC.SoundGuardStopped
    list[#list + 1] = { t = now, snd = snd, where = where }
    while #list > 20 do table.remove(list, 1) end
    if warned[key] and now - warned[key] < LC.SoundGuardWindow then return end
    warned[key] = now
    local msg = string.format("Sound guard: stopped %s (%s): started more than %d times in %d seconds", tostring(snd), where, LC.SoundGuardMax, LC.SoundGuardWindow)
    if SERVER and LC.Log then LC.Log("warn", msg) elseif MsgN then MsgN("[Miscount] " .. msg) end
end

-- May this sound start on this owner now? True, or false: refused (it has started too often).
-- owner: an entity, a position, or a word ("me", "file"); looping: a CreateSound.
function LC.SoundGuardCheck(owner, snd, now, looping)
    if not LC.SoundGuarded(snd, looping) then return true end
    now = now or (CurTime and CurTime()) or os.time()
    local s = Clean(snd)
    local where = Who(owner)
    local key = where .. "|" .. s
    local t = recent[key]
    if not t then t = {} recent[key] = t end
    local keep = {}
    for _, at in ipairs(t) do if now - at < LC.SoundGuardWindow then keep[#keep + 1] = at end end
    recent[key] = keep
    if #keep >= LC.SoundGuardMax then
        Warn(key, s, where, now)
        return false
    end
    keep[#keep + 1] = now
    return true
end
-- Forget everything (tests; and a long-running server tidies itself below).
function LC.SoundGuardReset() recent, warned = {}, {} end
if timer and timer.Create then
    timer.Create("LivingCitySoundGuard", 60, 0, function()
        local now = CurTime and CurTime() or 0
        for k, t in pairs(recent) do if not t[#t] or now - t[#t] > LC.SoundGuardWindow then recent[k] = nil end end
        for k, at in pairs(warned) do if now - at > LC.SoundGuardWindow then warned[k] = nil end end
    end)
end

------------------------------------------------------------------------
-- Every sound the game starts, through the guard
------------------------------------------------------------------------

local patches = setmetatable({}, { __mode = "k" }) -- [CSoundPatch] = key (to stop the old ones when one's refused)
local STUB = setmetatable({}, { __index = function(_, k)
    if k == "IsPlaying" then return function() return false end end
    if k == "GetVolume" or k == "GetPitch" or k == "GetSoundLevel" then return function() return 0 end end
    return function() end
end })
LC.SoundGuardStub = STUB

local function Track(e, snd, patch) if LC.SoundGuardTrack then LC.SoundGuardTrack(e, snd, patch) end end

local EMT = FindMetaTable and FindMetaTable("Entity")
if EMT and EMT.EmitSound and not EMT.lcRawEmitSound then
    local rawEmit, rawStop = EMT.EmitSound, EMT.StopSound
    EMT.lcRawEmitSound, EMT.lcRawStopSound = rawEmit, rawStop
    EMT.EmitSound = function(self, snd, ...)
        if not LC.SoundGuardCheck(self, snd) then
            if rawStop then pcall(rawStop, self, snd) end -- (and the copies already going: stuck, most likely)
            return
        end
        Track(self, snd)
        return rawEmit(self, snd, ...)
    end
end
if sound and sound.Play and not sound.lcRawPlay then
    local rawPlay = sound.Play
    sound.lcRawPlay = rawPlay
    sound.Play = function(snd, pos, ...)
        if not LC.SoundGuardCheck(pos or "world", snd) then return end
        Track(pos or "world", snd)
        return rawPlay(snd, pos, ...)
    end
end
if CreateSound and not LC.SoundGuardRawCreate then
    local rawCreate = CreateSound
    LC.SoundGuardRawCreate = rawCreate
    CreateSound = function(ent, snd, ...)
        local key = Who(ent) .. "|" .. tostring(Clean(snd))
        if not LC.SoundGuardCheck(ent, snd, nil, true) then
            for p, k in pairs(patches) do if k == key and p.Stop then pcall(p.Stop, p) end end
            return STUB
        end
        local p = rawCreate(ent, snd, ...)
        if p then patches[p] = key Track(ent, snd, p) end
        return p
    end
end

------------------------------------------------------------------------
-- The dreams: what was started in one, stopped when it's over
------------------------------------------------------------------------

if SERVER then
    if util and util.AddNetworkString then util.AddNetworkString("lc_soundguard") end
    local heard = {} -- [dream id] = { list = { { e, snd } }, set = {}, patches = {} }
    LC.SoundGuardHeard = heard
    local function InDream(d, e)
        if type(e) == "Vector" then return LC.DreamHolds ~= nil and LC.DreamHolds(d, e, true) == true end
        if type(e) == "string" or not IsValid(e) then return false end
        if e.IsPlayer and e:IsPlayer() then return e.lcDreaming == d.id end
        if d.made and d.made[e] then return true end
        if e.lcDreamActor then return true end -- (a figure a dream you play made, wherever it flies: sv_livingcity_dreamgames.lua)
        return e.GetPos ~= nil and LC.DreamHolds ~= nil and LC.DreamHolds(d, e:GetPos(), true) == true
    end
    -- Remember a sound started in tonight's dream.
    function LC.SoundGuardTrack(e, snd, patch)
        local d = LC.DreamActive
        if not d or type(snd) ~= "string" then return end
        local ok, inside = pcall(InDream, d, e)
        if not ok or not inside then return end
        local h = heard[d.id]
        if not h then h = { list = {}, set = {}, patches = {} } heard[d.id] = h end
        if patch then h.patches[#h.patches + 1] = patch end
        local key = Who(e) .. "|" .. snd
        if h.set[key] or #h.list >= 400 then return end
        h.set[key] = true
        h.list[#h.list + 1] = { e = e, snd = snd }
    end
    local function Stop(e, snd)
        if type(e) == "Vector" or type(e) == "string" then
            local w = game and game.GetWorld and game.GetWorld()
            if IsValid(w) and w.StopSound then pcall(w.StopSound, w, snd) end
        elseif IsValid(e) and e.StopSound then
            pcall(e.StopSound, e, snd)
        end
    end
    -- The dream is over (who: everyone in it; one dreamer waking: just them). Every sound it started,
    -- stopped; and on their computers, with its song and voices.
    function LC.SoundGuardDreamEnd(dream, who)
        if not dream then return 0 end
        local h = heard[dream.id] or { list = {}, patches = {} }
        local whole = who == nil
        local n = 0
        local send = {}
        for _, r in ipairs(h.list) do
            if whole or r.e == who then Stop(r.e, r.snd) n = n + 1 end
            local i = (type(r.e) ~= "Vector" and type(r.e) ~= "string" and IsValid(r.e) and r.e.EntIndex) and r.e:EntIndex() or 0
            if #send < 250 then send[#send + 1] = { i, r.snd } end
        end
        if whole then
            for _, p in ipairs(h.patches) do if p and p.Stop then pcall(p.Stop, p) n = n + 1 end end
            heard[dream.id] = nil
        end
        local to = {}
        if whole then for _, p in ipairs(dream.list or {}) do if IsValid(p) then to[#to + 1] = p end end
        elseif IsValid(who) then to[1] = who end
        if #to > 0 and net and net.Start then
            net.Start("lc_soundguard")
            net.WriteTable({ k = "dreamend", list = send })
            net.Send(to)
        end
        return n
    end
    -- A recently refused sound, in words (the debug report).
    function LC.SoundGuardReport()
        local out = {}
        for i = #LC.SoundGuardStopped, math.max(1, #LC.SoundGuardStopped - 5), -1 do
            local r = LC.SoundGuardStopped[i]
            out[#out + 1] = string.format("%s (%s, %ds ago)", r.snd, r.where, math.floor((CurTime() - r.t)))
        end
        return out
    end
end

if CLIENT then
    -- (on LC, not LC_CL: this file loads before cl_livingcity.lua sets LC_CL up with its lists)
    local dreamChans = setmetatable({}, { __mode = "k" }) -- [IGModAudioChannel] = true: started while dreaming
    local byPath = {}                                      -- [path] = { [channel] = true }
    LC.SoundGuardDreamChannels = dreamChans
    if surface and surface.PlaySound and not surface.lcRawPlaySound then
        local raw = surface.PlaySound
        surface.lcRawPlaySound = raw
        surface.PlaySound = function(snd, ...)
            if not LC.SoundGuardCheck("me", snd) then return end
            return raw(snd, ...)
        end
    end
    if sound and sound.PlayFile and not sound.lcRawPlayFile then
        local raw = sound.PlayFile
        sound.lcRawPlayFile = raw
        sound.PlayFile = function(path, flags, cb)
            local s = Clean(path) or ""
            if not LC.SoundGuardCheck("file", path) then
                for ch in pairs(byPath[s] or {}) do if IsValid(ch) then ch:Stop() end end
                byPath[s] = nil
                if cb then cb(nil, -1, "refused by the sound guard") end
                return
            end
            return raw(path, flags, function(ch, ...)
                if IsValid(ch) then
                    byPath[s] = byPath[s] or setmetatable({}, { __mode = "k" })
                    byPath[s][ch] = true
                    local me = LocalPlayer and LocalPlayer()
                    if IsValid(me) and me.GetNW2Bool and me:GetNW2Bool("lc_dreaming", false) then dreamChans[ch] = true end
                end
                if cb then return cb(ch, ...) end
            end)
        end
    end
    -- Fade a channel out over secs, then stop it.
    function LC.SoundGuardFade(ch, secs)
        if not IsValid(ch) then return end
        secs = secs or 1.5
        local v0 = ch.GetVolume and ch:GetVolume() or 1
        local steps = 10
        for i = 1, steps do
            timer.Simple(secs * i / steps, function()
                if not IsValid(ch) then return end
                if i == steps then ch:Stop() elseif ch.SetVolume then ch:SetVolume(v0 * (1 - i / steps)) end
            end)
        end
    end
    -- The dream's over for me: everything it started, stopped here.
    function LC.SoundGuardClientEnd(list)
        for _, r in ipairs(list or {}) do
            local e = (r[1] or 0) > 0 and Entity and Entity(r[1]) or (game and game.GetWorld and game.GetWorld())
            if IsValid(e) and e.StopSound then pcall(e.StopSound, e, r[2]) end
            local me = LocalPlayer and LocalPlayer()
            if IsValid(me) and me.StopSound then pcall(me.StopSound, me, r[2]) end
        end
        for ch in pairs(dreamChans) do LC.SoundGuardFade(ch, 1.5) dreamChans[ch] = nil end
    end
    if net and net.Receive then
        net.Receive("lc_soundguard", function()
            local t = net.ReadTable() or {}
            if t.k == "dreamend" then LC.SoundGuardClientEnd(t.list) end
        end)
    end
end

------------------------------------------------------------------------
-- Sounds that loop by themselves (the owner, 13 November: the bleeding-out heartbeat was
-- still thumping after the respawn; "ARCHITECT A NEW WAY TO FIX THIS")
------------------------------------------------------------------------
-- Some of Half-Life 2's .wav files carry a loop mark: started once, they play for ever
-- until something stops them (player/heartbeat1.wav, player/breathe1.wav and many more).
-- Counting starts (above) never catches those: one start is enough. So:
--   1. LC.SoundLoops(snd) reads the file itself and says whether it carries a loop mark.
--   2. Such a sound started on a player is stopped by itself: after one play for the ones
--      meant as a single beat or breath (LC.SoundLoopOnce), else after LC.SoundLoopMax
--      seconds, unless whoever started it said how long it may go (LC.SoundLoopKeep).
--   3. On a player's own screen (surface.PlaySound can never be stopped) it is played on
--      the player instead, so rule 2 holds there too.
--   4. Every one of them still going on a player stops when they die and when they spawn.
LC.SoundLoopOnce = { ["player/heartbeat1.wav"] = true, ["player/breathe1.wav"] = true }
LC.SoundLoopMax = 20

local loopKnown = {}
local function LE(str, at) -- a 4-byte number, lowest byte first
    local a, b, c, d = string.byte(str, at, at + 3)
    if not d then return 0 end
    return a + b * 256 + c * 65536 + d * 16777216
end
-- Does this .wav's own data say it loops? (a "cue " or "smpl" part with a loop in it)
function LC.SoundLoopMarked(data)
    if type(data) ~= "string" or string.sub(data, 1, 4) ~= "RIFF" or string.sub(data, 9, 12) ~= "WAVE" then return false end
    local at = 13
    for _ = 1, 64 do
        if at + 7 > #data then break end
        local id, len = string.sub(data, at, at + 3), LE(data, at + 4)
        if id == "cue " then return LE(data, at + 8) > 0 end
        if id == "smpl" then return LE(data, at + 8 + 28) > 0 end
        at = at + 8 + len + (len % 2)
    end
    return false
end
function LC.SoundLoops(snd)
    local s = Clean(snd)
    if not s or s == "" then return false end
    if LC.SoundLoopOnce[s] then return true end
    if loopKnown[s] ~= nil then return loopKnown[s] end
    local loops = false
    if string.sub(s, -4) == ".wav" and file and file.Open then
        local ok, res = pcall(function()
            local f = file.Open("sound/" .. s, "rb", "GAME")
            if not f then return false end
            -- the marks sit before or after the sound itself: the head, and the tail of a long file
            local size = f:Size() or 0
            local head = f:Read(math.min(size, 4096)) or ""
            local found = LC.SoundLoopMarked(head)
            if not found and size > 4096 then
                -- walk the parts without reading the sound: each says how long it is
                local at = 12
                for _ = 1, 64 do
                    if at + 8 > size then break end
                    f:Seek(at)
                    local h = f:Read(8)
                    if not h or #h < 8 then break end
                    local id, len = string.sub(h, 1, 4), LE(h, 5)
                    if id == "cue " or id == "smpl" then
                        local body = f:Read(math.min(len, 64)) or ""
                        found = (id == "cue " and LE(body, 1) > 0) or (id == "smpl" and LE(body, 29) > 0)
                        break
                    end
                    at = at + 8 + len + (len % 2)
                end
            end
            f:Close()
            return found
        end)
        loops = ok and res == true
    end
    loopKnown[s] = loops
    return loops
end

local going = setmetatable({}, { __mode = "k" }) -- [player] = { [sound] = { gen } }
local keeps = setmetatable({}, { __mode = "k" }) -- [player] = { [clean sound] = seconds }
-- "This loop on this player is meant: let it go for secs" (then it's stopped all the same).
function LC.SoundLoopKeep(ply, snd, secs)
    local s = Clean(snd)
    if not (ply and s) then return end
    keeps[ply] = keeps[ply] or {}
    keeps[ply][s] = secs
end
-- How long a self-looping sound may go on a player before it's stopped.
function LC.SoundLoopSecs(ply, snd)
    local s = Clean(snd)
    if not s then return LC.SoundLoopMax end
    local k = keeps[ply] and keeps[ply][s]
    if k then return k end
    if LC.SoundLoopOnce[s] then
        local d = SoundDuration and SoundDuration(s) or 0
        if not d or d <= 0.2 then d = 1.5 end
        return math.min(d, 4)
    end
    return LC.SoundLoopMax
end
local function RawStop(ply, snd)
    local stop = EMT and (EMT.lcRawStopSound or EMT.StopSound)
    if stop then pcall(stop, ply, snd) end
end
function LC.SoundLoopWatch(ply, snd)
    if not (ply and ply.IsPlayer and IsValid(ply) and ply:IsPlayer()) then return false end
    if not LC.SoundLoops(snd) then return false end
    local t = going[ply]
    if not t then t = {} going[ply] = t end
    local gen = ((t[snd] and t[snd].gen) or 0) + 1
    t[snd] = { gen = gen }
    if timer and timer.Simple then
        timer.Simple(LC.SoundLoopSecs(ply, snd), function()
            local now = going[ply]
            if IsValid(ply) and now and now[snd] and now[snd].gen == gen then
                now[snd] = nil
                RawStop(ply, snd)
            end
        end)
    end
    return true
end
-- Everything self-looping still going on this player, stopped (death, spawn).
function LC.SoundLoopsStop(ply)
    if not IsValid(ply) then return 0 end
    local n = 0
    for snd in pairs(going[ply] or {}) do RawStop(ply, snd) n = n + 1 end
    going[ply] = nil
    for s in pairs(LC.SoundLoopOnce) do RawStop(ply, s) end
    return n
end
function LC.SoundLoopsGoing(ply)
    local out = {}
    for snd in pairs(going[ply] or {}) do out[#out + 1] = snd end
    return out
end

if EMT and EMT.EmitSound and not EMT.lcLoopEmit then
    local guarded = EMT.EmitSound
    EMT.lcLoopEmit = true
    EMT.EmitSound = function(self, snd, ...)
        local ok = pcall(LC.SoundLoopWatch, self, snd)
        return guarded(self, snd, ...)
    end
end

if SERVER and hook and hook.Add then
    hook.Add("PlayerSpawn", "LivingCitySoundLoops", function(p) LC.SoundLoopsStop(p) end)
    hook.Add("PostPlayerDeath", "LivingCitySoundLoops", function(p) LC.SoundLoopsStop(p) end)
end
if CLIENT then
    if surface and surface.PlaySound and not surface.lcLoopPlaySound then
        local guarded = surface.PlaySound
        surface.lcLoopPlaySound = true
        surface.PlaySound = function(snd, ...)
            local me = LocalPlayer and LocalPlayer()
            if IsValid(me) and LC.SoundLoops(snd) then
                -- on the player, not the screen: the screen's can never be stopped
                me:EmitSound(snd, 0, 100, 1)
                return
            end
            return guarded(snd, ...)
        end
    end
    local wasAlive
    local function Mine()
        local me = LocalPlayer and LocalPlayer()
        if IsValid(me) then LC.SoundLoopsStop(me) end
    end
    if timer and timer.Create then
        timer.Create("LivingCitySoundLoops", 0.5, 0, function()
            local me = LocalPlayer and LocalPlayer()
            if not IsValid(me) then return end
            local alive = me:Alive()
            if wasAlive ~= nil and alive ~= wasAlive then Mine() end
            wasAlive = alive
        end)
    end
    if gameevent and gameevent.Listen and hook and hook.Add then
        gameevent.Listen("player_spawn")
        hook.Add("player_spawn", "LivingCitySoundLoops", function(data)
            local me = LocalPlayer and LocalPlayer()
            if IsValid(me) and data and data.userid == me:UserID() then Mine() end
        end)
    end
end
