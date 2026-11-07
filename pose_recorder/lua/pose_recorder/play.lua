--[[
    Pose Recorder: playing animations on players and NPCs, seen by everyone

      The server only says "this entity plays this animation from this moment, looping (or
      once, or holding the last pose), at this speed". Each client turns the bones itself,
      every frame, with ManipulateBoneAngles, from that moment and the animation's keyframes.
      Anyone joining later is told what's playing, and fetches any animation it hasn't got.

      Where animations come from:
        - packs: any addon's data_static/pose_recorder/<name>.json (and, on the server,
          garrysmod/data/pose_recorder/), picked up when the server starts
        - a player's own: pose_play <name> plays their own data/pose_recorder/<name>.json,
          sent to the server (checked) and on to everyone who sees it
        - Lua: PoseRecorder.Register(name, data) on the server

      For Lua coders (on the server, everyone sees it; on a client, only that client):
        PoseRecorder.Play(ent, "wave", { mode = "loop" | "once" | "hold", speed = 1 })
        PoseRecorder.Stop(ent)
        PoseRecorder.Register("wave", data)   -- data as a saved file has it
        PoseRecorder.Get("wave")              -- the (checked) animation, or nil
        PoseRecorder.PlayingOn(ent)           -- name, mode, speed, start, or nil
      Every file is checked by PoseRecorder.Sanitize (lua/pose_recorder/core.lua) first.
]]

local PR = PoseRecorder
PR.Anims = PR.Anims or {}       -- the server: [key] = { data, zip, crc, pack = true/false }
PR.Playing = PR.Playing or {}   -- [ent] = { key, crc, start, mode, speed }

local MAX_ZIP = 60000           -- bytes, compressed, in one message
local NET = "pose_recorder_net" -- (client to server: one message, its first byte says what for)
local ASK_PLAY, ASK_UPLOAD, ASK_STOP, ASK_NEED, ASK_HELLO = 1, 2, 3, 4, 5

local function Mode(m) return (m == "once" or m == "hold") and m or "loop" end
local function Speed(s) return math.Clamp(tonumber(s) or 1, 0.1, 4) end

-- Text to an animation (or nil and why): checked and cleaned.
function PR.Decode(json)
    if type(json) ~= "string" or #json > PR.LIMITS.bytes then return nil, "it's too big" end
    local ok, t = pcall(util.JSONToTable, json)
    if not ok or type(t) ~= "table" then return nil, "it isn't readable JSON" end
    return PR.Sanitize(t)
end

-- The bone's number on this entity's model (looked up once per model).
local boneIds = {}
function PR.BoneId(e, name)
    local mdl = e:GetModel() or ""
    boneIds[mdl] = boneIds[mdl] or {}
    local id = boneIds[mdl][name]
    if id == nil then id = e:LookupBone(name) or false boneIds[mdl][name] = id end
    return id or nil
end

-- Files in one folder of one search path, as { [name] = path }.
local function Scan(dir, where, out)
    for _, ext in ipairs({ "json", "txt" }) do
        local found = file.Find(dir .. "*." .. ext, where) or {}
        for _, f in ipairs(found) do
            local n = PR.CleanName(string.gsub(f, "%.%w+$", ""))
            if n and not out[n] then out[n] = { path = dir .. f, where = where } end
        end
    end
    return out
end

-- Every animation file this side can see: packs (data_static/pose_recorder/ in any addon,
-- read through DATA and GAME), and the data folder's own pose_recorder/.
function PR.FindFiles()
    local out = {}
    Scan("pose_recorder/", "DATA", out)
    Scan("data_static/pose_recorder/", "GAME", out)
    return out
end

function PR.ReadFile(info)
    if not info then return nil, "there's no such file" end
    local size = file.Size and file.Size(info.path, info.where)
    if size and size > PR.LIMITS.bytes then return nil, "it's too big" end
    local raw = file.Read(info.path, info.where)
    if not raw then return nil, "it couldn't be read" end
    return PR.Decode(raw)
end

local function Over(ent, st, now)
    if st.mode ~= "once" then return false end
    local a = PR.Get and PR.Get(st.key)
    if not a then return false end
    return now > st.start + PR.Duration(a) / st.speed + PR.FADE
end

if SERVER then
    util.AddNetworkString(NET)
    util.AddNetworkString("pose_recorder_play")
    util.AddNetworkString("pose_recorder_stop")
    util.AddNetworkString("pose_recorder_anim")
    util.AddNetworkString("pose_recorder_list")
    util.AddNetworkString("pose_recorder_say")

    local cvSelf = CreateConVar("pose_recorder_play_self", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
        "Pose Recorder: players may play animations on themselves (1) or not (0)")
    local cvNPC = CreateConVar("pose_recorder_play_npcs", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
        "Pose Recorder: who may play animations on NPCs: 0 nobody, 1 anyone allowed to use the context menu on it, 2 admins")
    local cvUp = CreateConVar("pose_recorder_uploads", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
        "Pose Recorder: players may play their own animations, sent to the server and on to everyone (1) or only the server's packs (0)")

    local function Tell(ply, msg)
        if not IsValid(ply) then print("[Pose Recorder] " .. msg) return end
        net.Start("pose_recorder_say")
        net.WriteString(msg)
        net.Send(ply)
    end

    -- Store an animation (already checked) under a key.
    local uploads = {}
    local function Store(key, data, pack)
        local zip = util.Compress(util.TableToJSON(data))
        if not zip or #zip > MAX_ZIP then return nil, "it's too big to send" end
        PR.Anims[key] = { data = data, zip = zip, crc = util.CRC(zip), pack = pack }
        return PR.Anims[key]
    end

    local function SendList(to)
        local names = {}
        for k, a in pairs(PR.Anims) do if a.pack then names[#names + 1] = k end end
        table.sort(names)
        net.Start("pose_recorder_list")
        net.WriteUInt(math.min(#names, 1023), 10)
        for i = 1, math.min(#names, 1023) do net.WriteString(names[i]) end
        if to then net.Send(to) else net.Broadcast() end
    end

    function PR.Register(name, data)
        local key = PR.CleanName(name)
        if not key then return nil, "it needs a name" end
        local clean, err = PR.Sanitize(data)
        if not clean then return nil, err end
        local ok, why = Store(key, clean, true)
        if not ok then return nil, why end
        if PR.listReady then SendList() end
        return key
    end

    function PR.Get(name)
        local a = PR.Anims[name] or PR.Anims[PR.CleanName(name) or ""]
        return a and a.data or nil
    end

    -- The packs: every file the server can see, checked; a broken one is skipped and named.
    function PR.LoadPacks()
        local n = 0
        for name, info in pairs(PR.FindFiles()) do
            local data, err = PR.ReadFile(info)
            if data then
                if Store(name, data, true) then n = n + 1 end
            else
                print("[Pose Recorder] skipped " .. info.path .. ": " .. tostring(err))
            end
        end
        PR.listReady = true
        SendList()
        return n
    end

    local function SendPlay(ent, st, to)
        net.Start("pose_recorder_play")
        net.WriteEntity(ent)
        net.WriteString(st.key)
        net.WriteString(st.crc)
        net.WriteDouble(st.start)
        net.WriteString(st.mode)
        net.WriteFloat(st.speed)
        if to then net.Send(to) else net.Broadcast() end
    end

    function PR.Play(ent, name, opts)
        if not IsValid(ent) then return false, "there's nothing to play it on" end
        opts = opts or {}
        local key = PR.Anims[name] and name or PR.CleanName(name)
        local a = key and PR.Anims[key]
        if not a then return false, "there's no animation called " .. tostring(name) end
        local st = { key = key, crc = a.crc, start = tonumber(opts.start) or CurTime(), mode = Mode(opts.mode), speed = Speed(opts.speed) }
        PR.Playing[ent] = st
        SendPlay(ent, st)
        return true
    end

    function PR.Stop(ent)
        if not PR.Playing[ent] then return end
        PR.Playing[ent] = nil
        net.Start("pose_recorder_stop")
        net.WriteEntity(ent)
        net.Broadcast()
    end

    function PR.IsPlaying(ent)
        local st = PR.Playing[ent]
        if st and Over(ent, st, CurTime()) then PR.Playing[ent] = nil st = nil end
        return st
    end

    -- Who may play what on whom (a hook can decide: return true or false).
    function PR.CanPlay(ply, ent)
        if not IsValid(ply) then return true end
        if not IsValid(ent) then return false end
        local h = hook.Run("PoseRecorderCanPlay", ply, ent)
        if h ~= nil then return h end
        if ent == ply then return cvSelf:GetBool() end
        if ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) then
            local who = cvNPC:GetInt()
            if who <= 0 or (who >= 2 and not ply:IsAdmin()) then return false end
            return hook.Run("CanProperty", ply, "pose_recorder_play", ent) ~= false
        end
        return false
    end

    -- Each player's asking, kept within reason.
    local budget = {}
    local function Allowed(ply, cost)
        local b = budget[ply]
        local now = CurTime()
        if not b then b = { left = 20, at = now } budget[ply] = b end
        b.left = math.min(20, b.left + (now - b.at) * 2)
        b.at = now
        if b.left < cost then return false end
        b.left = b.left - cost
        return true
    end

    local function Start(ply, ent, key, mode, speed)
        if not PR.CanPlay(ply, ent) then Tell(ply, "You can't play animations on that.") return end
        local ok, err = PR.Play(ent, key, { mode = mode, speed = speed })
        if not ok then Tell(ply, "Couldn't play it: " .. err .. ".") end
    end

    net.Receive(NET, function(len, ply)
        if not IsValid(ply) then return end
        local kind = net.ReadUInt(4)
        if kind == ASK_HELLO then
            if ply.poseRecorderHello then return end
            ply.poseRecorderHello = true
            SendList(ply)
            for ent, st in pairs(PR.Playing) do
                if IsValid(ent) and PR.IsPlaying(ent) then SendPlay(ent, st, ply) end
            end
        elseif kind == ASK_NEED then
            local key = net.ReadString()
            local a = PR.Anims[key]
            if not a or not Allowed(ply, 1) then return end
            net.Start("pose_recorder_anim")
            net.WriteString(key)
            net.WriteString(a.crc)
            net.WriteUInt(#a.zip, 16)
            net.WriteData(a.zip, #a.zip)
            net.Send(ply)
        elseif kind == ASK_STOP then
            local ent = net.ReadEntity()
            if not Allowed(ply, 1) then return end
            if IsValid(ent) and PR.CanPlay(ply, ent) then PR.Stop(ent) end
        elseif kind == ASK_PLAY then
            local ent, name, mode, speed = net.ReadEntity(), net.ReadString(), net.ReadString(), net.ReadFloat()
            if not Allowed(ply, 2) then return end
            local key = PR.CleanName(name)
            if not (key and PR.Anims[key] and PR.Anims[key].pack) then Tell(ply, "The server has no animation called " .. tostring(key) .. ".") return end
            Start(ply, ent, key, mode, speed)
        elseif kind == ASK_UPLOAD then
            local ent, name, mode, speed = net.ReadEntity(), net.ReadString(), net.ReadString(), net.ReadFloat()
            local size = net.ReadUInt(16)
            if size <= 0 or size > MAX_ZIP or size > len / 8 then return end
            local zip = net.ReadData(size)
            if not Allowed(ply, 5) then Tell(ply, "Slow down a little.") return end
            if not cvUp:GetBool() then Tell(ply, "This server only plays its own animations (its packs).") return end
            if not PR.CanPlay(ply, ent) then Tell(ply, "You can't play animations on that.") return end
            local json = util.Decompress(zip, PR.LIMITS.bytes)
            local data, err = PR.Decode(json)
            local clean = PR.CleanName(name)
            if not data or not clean then Tell(ply, "The server turned that animation down: " .. tostring(err or "it needs a name") .. ".") return end
            -- (a player's own animations are kept under their own key, the last 8 per player)
            local key = "~" .. (ply:SteamID64() or tostring(ply:UserID())) .. "/" .. clean
            local mine = uploads[ply:SteamID64() or ply] or {}
            uploads[ply:SteamID64() or ply] = mine
            for i = #mine, 1, -1 do if mine[i] == key then table.remove(mine, i) end end
            mine[#mine + 1] = key
            while #mine > 8 do
                local old = table.remove(mine, 1)
                local used = false
                for _, st in pairs(PR.Playing) do if st.key == old then used = true end end
                if not used then PR.Anims[old] = nil end
            end
            local ok, why = Store(key, data, false)
            if not ok then Tell(ply, "The server turned that animation down: " .. why .. ".") return end
            Start(ply, ent, key, mode, speed)
        end
    end)

    hook.Add("EntityRemoved", "PoseRecorderPlay", function(ent) PR.Playing[ent] = nil end)
    hook.Add("PlayerDeath", "PoseRecorderPlay", function(ply) PR.Stop(ply) end)
    hook.Add("PlayerDisconnected", "PoseRecorderPlay", function(ply) budget[ply] = nil end)
    timer.Create("PoseRecorderTidy", 2, 0, function()
        for ent in pairs(PR.Playing) do if not IsValid(ent) then PR.Playing[ent] = nil else PR.IsPlaying(ent) end end
    end)

    concommand.Add("pose_recorder_reload_packs", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        Tell(ply, "Packs loaded: " .. PR.LoadPacks() .. " animations.")
    end)

    PR.LoadPacks()
else
    ------------------------------------------------------------------------
    -- Each client: the animations it has, what's playing, and turning the bones
    ------------------------------------------------------------------------
    PR.Library = PR.Library or {} -- [key] = { data, crc }
    PR.Packs = PR.Packs or {}     -- the names the server offers, sorted
    PR.Active = PR.Active or {}   -- [ent] = { key, crc, start, mode, speed, touched = { [boneId] = true } }
    local asked = {}

    local cvMode = CreateClientConVar("pose_recorder_playmode", "loop", true, false, "Pose Recorder: how an animation plays: loop, once, or hold (stays in the last pose)")
    local cvSpeed = CreateClientConVar("pose_recorder_speed", "1", true, false, "Pose Recorder: how fast an animation plays (1 is as made)")

    local function Say(msg)
        if PR.Say then PR.Say(msg) else chat.AddText(Color(120, 200, 255), "[Pose Recorder] ", Color(235, 235, 235), msg) end
    end

    local function Ask(kind)
        net.Start(NET)
        net.WriteUInt(kind, 4)
    end

    function PR.Get(name)
        local l = PR.Library[name]
        return l and l.data or nil
    end

    -- Put the bones back as the model has them.
    local function Release(ent, st)
        if not IsValid(ent) or not st or not st.touched then return end
        for id in pairs(st.touched) do ent:ManipulateBoneAngles(id, Angle(0, 0, 0)) end
        st.touched = {}
    end

    -- Ask the server for an animation's keyframes once (again after a few seconds if they
    -- haven't come: the server answers only so many at a time).
    local function Fetch(st)
        local have = PR.Library[st.key]
        if st.crc == "local" or (have and have.crc == st.crc) then return end
        local k = st.key .. "|" .. st.crc
        if asked[k] and CurTime() - asked[k] < 5 then return end
        asked[k] = CurTime()
        Ask(ASK_NEED)
        net.WriteString(st.key)
        net.SendToServer()
    end

    local function Begin(ent, st)
        Release(ent, PR.Active[ent])
        st.touched = {}
        PR.Active[ent] = st
        Fetch(st)
    end

    function PR.StopLocal(ent)
        Release(ent, PR.Active[ent])
        PR.Active[ent] = nil
    end

    net.Receive("pose_recorder_play", function()
        local ent, key, crc, start, mode, speed = net.ReadEntity(), net.ReadString(), net.ReadString(), net.ReadDouble(), net.ReadString(), net.ReadFloat()
        if not IsValid(ent) then return end
        Begin(ent, { key = key, crc = crc, start = start, mode = Mode(mode), speed = Speed(speed) })
    end)

    net.Receive("pose_recorder_stop", function()
        local ent = net.ReadEntity()
        if IsValid(ent) or PR.Active[ent] then PR.StopLocal(ent) end
    end)

    net.Receive("pose_recorder_anim", function()
        local key, crc, size = net.ReadString(), net.ReadString(), net.ReadUInt(16)
        if size <= 0 or size > MAX_ZIP then return end
        local zip = net.ReadData(size)
        local data = PR.Decode(util.Decompress(zip, PR.LIMITS.bytes))
        if data then PR.Library[key] = { data = data, crc = crc } end
    end)

    net.Receive("pose_recorder_list", function()
        local names = {}
        for _ = 1, net.ReadUInt(10) do names[#names + 1] = net.ReadString() end
        PR.Packs = names
        hook.Run("PoseRecorderLibraryChanged")
    end)

    net.Receive("pose_recorder_say", function() Say(net.ReadString()) end)

    hook.Add("InitPostEntity", "PoseRecorderPlay", function()
        Ask(ASK_HELLO)
        net.SendToServer()
    end)

    -- Every frame: each playing entity's bones, eased from its start time.
    hook.Add("Think", "PoseRecorderPlay", function()
        local now = CurTime()
        for ent, st in pairs(PR.Active) do
            if not IsValid(ent) then
                PR.Active[ent] = nil
            elseif not (ent.IsDormant and ent:IsDormant()) then
                local lib = PR.Library[st.key]
                if lib and (lib.crc == st.crc or st.crc == "local") then
                    local pose, w, done = PR.Evaluate(lib.data, now - st.start, st)
                    if done then
                        PR.StopLocal(ent)
                    else
                        for name, a in pairs(pose) do
                            local id = PR.BoneId(ent, name)
                            if id then
                                ent:ManipulateBoneAngles(id, Angle(a[1] * w, a[2] * w, a[3] * w))
                                st.touched[id] = true
                            end
                        end
                    end
                else
                    Fetch(st)
                end
            end
        end
    end)

    hook.Add("EntityRemoved", "PoseRecorderPlay", function(ent) PR.Active[ent] = nil end)

    -- Your own saved animations and the server's packs, as one sorted list of names.
    function PR.Choices()
        local seen, out = {}, {}
        for name in pairs(PR.FindFiles()) do if not seen[name] then seen[name] = true out[#out + 1] = name end end
        for _, name in ipairs(PR.Packs) do if not seen[name] then seen[name] = true out[#out + 1] = name end end
        table.sort(out)
        return out
    end

    -- Ask the server to play an animation on ent (yourself, or an NPC): your own file if you
    -- have one by that name (sent along, checked by the server), or else the server's pack.
    -- data: a whole animation to send instead of reading a file (the tool's current work).
    function PR.RequestPlay(ent, name, mode, speed, data)
        if not IsValid(ent) then Say("There's nothing to play it on.") return false end
        local key = PR.CleanName(name)
        if not key then Say("Which animation? Give it a name.") return false end
        mode, speed = Mode(mode or cvMode:GetString()), Speed(speed or cvSpeed:GetFloat())
        local err
        if not data then
            local info = PR.FindFiles()[key]
            if info then data, err = PR.ReadFile(info) end
            if not data and info and not table.HasValue(PR.Packs, key) then Say("Your " .. key .. " can't be played: " .. tostring(err) .. ".") return false end
        end
        if not data then
            if not table.HasValue(PR.Packs, key) then Say("There's no animation called " .. key .. " (saved by you, or on the server).") return false end
            Ask(ASK_PLAY)
            net.WriteEntity(ent)
            net.WriteString(key)
            net.WriteString(mode)
            net.WriteFloat(speed)
            net.SendToServer()
            return true
        end
        local clean, why = PR.Sanitize(data)
        if not clean then Say("That animation can't be played: " .. tostring(why) .. ".") return false end
        local zip = util.Compress(util.TableToJSON(clean))
        if not zip or #zip > MAX_ZIP then Say("That animation is too big to send.") return false end
        Ask(ASK_UPLOAD)
        net.WriteEntity(ent)
        net.WriteString(key)
        net.WriteString(mode)
        net.WriteFloat(speed)
        net.WriteUInt(#zip, 16)
        net.WriteData(zip, #zip)
        net.SendToServer()
        return true
    end

    function PR.RequestStop(ent)
        if not IsValid(ent) then return end
        Ask(ASK_STOP)
        net.WriteEntity(ent)
        net.SendToServer()
    end

    -- Lua on a client: only this client sees it (handy for a clientside model in a menu).
    function PR.Play(ent, name, opts)
        if not IsValid(ent) then return false, "there's nothing to play it on" end
        opts = opts or {}
        local data, key = nil, nil
        if type(name) == "table" then
            data, key = PR.Sanitize(name), "local:" .. tostring(name)
        else
            key = PR.CleanName(name) or ""
            local l = PR.Library[name] or PR.Library[key]
            data = l and l.data
            if not data then data = PR.ReadFile(PR.FindFiles()[key]) end
            key = "local:" .. key
        end
        if not data then return false, "there's no animation called " .. tostring(name) end
        PR.Library[key] = { data = data, crc = "local" }
        Begin(ent, { key = key, crc = "local", start = tonumber(opts.start) or CurTime(), mode = Mode(opts.mode), speed = Speed(opts.speed) })
        return true
    end

    PR.Stop = PR.StopLocal

    -- pose_play <name> [loop|once|hold] [speed], on yourself; pose_stop
    concommand.Add("pose_play", function(_, _, args)
        if not args[1] then Say("pose_play <name> [loop, once or hold] [speed]: plays one of your saved animations, or the server's, on you.") return end
        PR.RequestPlay(LocalPlayer(), args[1], args[2], args[3])
    end, function(cmd) local o = {} for _, n in ipairs(PR.Choices()) do o[#o + 1] = cmd .. " " .. n end return o end)
    concommand.Add("pose_stop", function() PR.RequestStop(LocalPlayer()) end)

    -- The context menu (hold C, right click an NPC): Play animation, Stop animation.
    if properties and properties.Add then
        properties.Add("pose_recorder_play", {
            MenuLabel = "Play animation",
            Order = 2100,
            MenuIcon = "icon16/film.png",
            Filter = function(self, ent) return IsValid(ent) and (ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) or false) end,
            MenuOpen = function(self, option, ent)
                local sub = option:AddSubMenu()
                local names = PR.Choices()
                if #names == 0 then
                    sub:AddOption("None yet: make one with Tools, Poser, Pose Recorder", function() end)
                    return
                end
                for _, n in ipairs(names) do sub:AddOption(n, function() PR.RequestPlay(ent, n) end) end
            end,
            Action = function() end,
        })
        properties.Add("pose_recorder_stop", {
            MenuLabel = "Stop animation",
            Order = 2101,
            MenuIcon = "icon16/film_delete.png",
            Filter = function(self, ent) return IsValid(ent) and PR.Active[ent] ~= nil end,
            Action = function(self, ent) PR.RequestStop(ent) end,
        })
    end
end

-- The same on both sides: what's playing on an entity (key, mode, speed, start), or nil.
function PR.PlayingOn(ent)
    local st = SERVER and PR.IsPlaying(ent) or (CLIENT and PR.Active[ent])
    if not st then return nil end
    return st.key, st.mode, st.speed, st.start
end
