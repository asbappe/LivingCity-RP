--[[
    Living City: the dream flight recorder (server side)

      The owner, 14 November: the dreams feel "rushed", and studying each one by hand takes half
      an hour. So: a recording of a dream as it was really played, written as plain text that the
      code chat can read. "Please have this run only when I initiate a dream from the editor
      tool, as that is how I test."

      It runs ONLY for a dream tested from the Living City Editor ("Dreams: test one"), and only
      while the tester's "Record the test" box is ticked (lc_dreamrec on their own computer, on
      by default). A night's dream, an admin's "dream it now" and everything else in the city are
      never recorded, and when no test is being recorded none of this is hooked at all.

      What the server writes down, each line with the second of the dream it happened in:
        made / gone   everything the dream puts out and takes away (class, model, where)
        sound         every sound the server plays inside the dream
        notice        every notice sent to the tester (kind, title, text, seconds asked for)
        state         the dream's own workings as they change (its stage, round, lives, score...)
        nw            what's networked about the tester as it changes (the HUD's numbers)
        net           which net messages went out (their names lead back to the code)
        you           where the tester is, what they look at, hold, press and use; when they
                      stand still (idle); hurt, died; and anything they type in chat (a note
                      typed mid-dream lands in the log at that second)
        near          every five seconds, what's closest to the tester

      The lines go to the tester's own computer as the dream runs, where cl_livingcity_dreamrec.lua
      adds what was on screen (every line of text and for how long, sounds, screenshots) and
      saves it all in garrysmod/data/livingcity/dreamrec/ on their PC. Nothing is kept on the
      server, and recording changes nothing about the dream.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dreamrec") -- server > the tester: "start" (what's being recorded), "lines", "end"

local R -- the recording under way (one at a time: only one dream can be)
local MAX_LINES = 30000 -- (a safeguard: a five minute dream is a few thousand)

function LC.DreamRecording() return R end

local function Add(kind, text)
    if not R or R.total >= MAX_LINES then return end
    R.total = R.total + 1
    text = tostring(text)
    if #text > 700 then text = string.sub(text, 1, 700) .. "..." end
    R.out[#R.out + 1] = { CurTime() - R.t0, kind, text }
end
LC.DreamRecAdd = Add -- (a dream may add a line of its own: LC.DreamRecAdd("beat", "the cheese speaks"))

------------------------------------------------------------------------
-- Words for things
------------------------------------------------------------------------

local function Num(n)
    if n == math.floor(n) then return tostring(n) end
    return string.format("%.2f", n)
end
local function Rel(pos)
    local c = R and R.dream and R.dream.pos or R and R.point
    if not (pos and c) then return "(?)" end
    return string.format("(%d, %d, %d)", math.floor(pos.x - c.x + 0.5), math.floor(pos.y - c.y + 0.5), math.floor(pos.z - c.z + 0.5))
end

local SKIP = { predicted_viewmodel = true, viewmodel = true, gmod_hands = true, physgun_beam = true, player = true,
    worldspawn = true, player_manager = true, manipulate_bone = true, manipulate_flex = true, soundent = true,
    ai_network = true, scene_manager = true, bodyque = true, network = true, gmod_gamerules = true }

-- What an entity is, in a few words: its class, model, and anything odd about how it looks.
local function Words(e)
    local s = e:GetClass()
    local m = e.GetModel and e:GetModel()
    if m and m ~= "" then s = s .. " " .. m end
    local sc = e.GetModelScale and e:GetModelScale()
    if sc and math.abs(sc - 1) > 0.01 then s = s .. " x" .. Num(sc) end
    local mat = e.GetMaterial and e:GetMaterial()
    if mat and mat ~= "" then s = s .. " [" .. mat .. "]" end
    local c = e.GetColor and e:GetColor()
    if c and c.r and (c.r ~= 255 or c.g ~= 255 or c.b ~= 255 or (c.a or 255) ~= 255) then
        s = s .. string.format(" rgba(%d,%d,%d,%d)", c.r, c.g, c.b, c.a or 255)
    end
    return s
end

-- Counted together, so forty props put out at once are one line.
local function Count(bag, key, pos)
    local a = bag[key]
    if not a then a = { n = 0, pos = pos } bag[key] = a end
    a.n = a.n + 1
end
local function Spill(kind, bag, withPos)
    local keys = {}
    for k in pairs(bag) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local a = bag[k]
        Add(kind, (a.n > 1 and (a.n .. "x ") or "") .. k .. (withPos and a.pos and (" at " .. Rel(a.pos)) or ""))
        bag[k] = nil
    end
end

------------------------------------------------------------------------
-- What changes: the dream's own workings, and what's networked about the tester
------------------------------------------------------------------------

local function Scalars(out, prefix, t)
    for k, v in pairs(t) do
        local tk, tv = type(k), type(v)
        if (tk == "string" or tk == "number") and (tv == "number" or tv == "string" or tv == "boolean") then out[prefix .. tostring(k)] = v end
    end
end

-- A number that is a moment in time reads as the second of the dream it stands for.
local function Show(v)
    if type(v) == "number" then
        local now = CurTime()
        if R.t0 > 900 and v > R.t0 - 5 and v < now + 900 then return "at " .. string.format("%.1f", v - R.t0) .. "s" end
        return Num(v)
    end
    if type(v) == "string" then
        if #v > 160 then v = string.sub(v, 1, 160) .. "..." end
        return "\"" .. v .. "\""
    end
    return tostring(v)
end

local function DreamState()
    local out = {}
    local d = R.dream
    if not d then return out end
    local g = d.game
    if istable(g) then
        Scalars(out, "game.", g)
        for k, v in pairs(g) do
            if type(k) == "string" and istable(v) then
                local mine = v[R.ply]
                if istable(mine) then Scalars(out, "game." .. k .. ".me.", mine)
                elseif mine ~= nil then
                    local tm = type(mine)
                    if tm == "number" or tm == "string" or tm == "boolean" then out["game." .. k .. ".me"] = mine end
                end
            end
        end
    end
    local E = LC.EndingAny and LC.EndingAny()
    if istable(E) and E.dream == d then Scalars(out, "ending.", E) end
    return out
end

local function Networked()
    local out = {}
    local p = R.ply
    local t = p.GetNW2VarTable and p:GetNW2VarTable()
    if not istable(t) then return out end
    for k, v in pairs(t) do
        if istable(v) and v.value ~= nil then v = v.value end
        local tv = type(v)
        if type(k) == "string" and (tv == "number" or tv == "string" or tv == "boolean") then out["nw." .. k] = v end
    end
    return out
end

-- Write down what's new or different. Something that changes every time it's looked at (a clock,
-- a position) is named once and then left alone until it settles.
local function Diff(kind, old, new, first)
    local keys = {}
    for k in pairs(new) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local v, was = new[k], old[k]
        if was ~= v then
            local hot = (R.hot[k] or 0) + 1
            R.hot[k] = hot
            if first or hot < 4 then
                parts[#parts + 1] = k .. " = " .. Show(v) .. ((was ~= nil and not first) and (" (was " .. Show(was) .. ")") or "")
            elseif hot == 4 then
                parts[#parts + 1] = k .. " keeps changing (a clock or a count): not written again until it settles"
            end
        elseif R.hot[k] then
            if R.hot[k] >= 4 then parts[#parts + 1] = k .. " settled at " .. Show(v) end
            R.hot[k] = nil
        end
    end
    for k in pairs(old) do
        if new[k] == nil then parts[#parts + 1] = k .. " gone" R.hot[k] = nil end
    end
    -- (a few to a line, so a line stays readable)
    local line = ""
    for _, s in ipairs(parts) do
        if #line > 0 and #line + #s > 500 then Add(kind, line) line = "" end
        line = line .. (#line > 0 and "; " or "") .. s
    end
    if #line > 0 then Add(kind, line) end
end

------------------------------------------------------------------------
-- The tester: where they are, what they look at, when they stand still
------------------------------------------------------------------------

local KEYS, MOVES = {}, {}
local function Key(v, name) if v then KEYS[v] = name end end
local function Move(v) if v then MOVES[v] = true end end
Key(IN_USE, "USE") Key(IN_ATTACK, "ATTACK") Key(IN_ATTACK2, "ATTACK2") Key(IN_JUMP, "JUMP") Key(IN_RELOAD, "RELOAD") Key(IN_DUCK, "DUCK")
Move(IN_FORWARD) Move(IN_BACK) Move(IN_MOVELEFT) Move(IN_MOVERIGHT) Move(IN_SPEED)

local IDLE_AT = { 5, 10, 20, 40, 80, 160 }

local function You()
    local p = R.ply
    local now = CurTime()
    local pos = p:GetPos()
    local flags = {}
    if not p:Alive() then flags[#flags + 1] = "dead" end
    if p.IsFrozen and p:IsFrozen() then flags[#flags + 1] = "frozen" end
    if p.InVehicle and p:InVehicle() then flags[#flags + 1] = "seated" end
    if p.GetMoveType and MOVETYPE_NOCLIP and p:GetMoveType() == MOVETYPE_NOCLIP then flags[#flags + 1] = "flying" end
    if p.Crouching and p:Crouching() then flags[#flags + 1] = "crouched" end
    local flag = table.concat(flags, ", ")

    -- (standing still: no steps and no keys)
    local step = R.lastPos and pos:Distance(R.lastPos) or 0
    R.lastPos = pos
    if step > 4 or R.pressed then
        if R.idleSaid then Add("you", "moving again after " .. math.floor(now - R.idleFrom) .. "s still") end
        R.idleFrom, R.idleSaid = now, nil
    else
        local still = now - (R.idleFrom or now)
        local nextAt = IDLE_AT[(R.idleSaid or 0) + 1]
        if nextAt and still >= nextAt then
            R.idleSaid = (R.idleSaid or 0) + 1
            Add("you", "idle: " .. nextAt .. "s without a step or a key" .. (flag ~= "" and (" (" .. flag .. ")") or ""))
        end
    end
    R.pressed = nil

    local moved = R.saidPos and pos:Distance(R.saidPos) or 1e9
    if moved > 64 or flag ~= R.saidFlag or (moved > 8 and now - (R.saidPosAt or 0) >= 3) then
        local yaw = p.EyeAngles and p:EyeAngles().y or 0
        local speed = p.GetVelocity and p:GetVelocity():Length() or 0
        Add("you", "at " .. Rel(pos) .. ", facing " .. math.floor(yaw + 0.5) .. ", speed " .. math.floor(speed + 0.5) .. (flag ~= "" and (" [" .. flag .. "]") or ""))
        R.saidPos, R.saidPosAt, R.saidFlag = pos, now, flag
    end

    local hp, ar = p:Health(), p.Armor and p:Armor() or 0
    if hp ~= R.hp or ar ~= R.armor then
        if R.hp then Add("you", "health " .. hp .. " (was " .. R.hp .. ")" .. ((ar ~= R.armor) and (", armour " .. ar) or "")) end
        R.hp, R.armor = hp, ar
    end

    local w = p.GetActiveWeapon and p:GetActiveWeapon()
    local wc = IsValid(w) and w:GetClass() or "nothing"
    if wc ~= R.weapon then
        if R.weapon then Add("you", "holding " .. wc) end
        R.weapon = wc
    end

    -- (what's in front of them: only what the dream made)
    if util.TraceLine and p.EyePos and p.GetAimVector then
        local eye = p:EyePos()
        local tr = util.TraceLine({ start = eye, endpos = eye + p:GetAimVector() * 3000, filter = p })
        local e = tr and tr.Entity
        local key = IsValid(e) and R.seen[e] or nil
        if key ~= R.look and now - (R.lookAt or 0) >= 1 then
            if key then Add("you", "looking at " .. key .. " (" .. math.floor(eye:Distance(tr.HitPos or e:GetPos())) .. " away)") end
            R.look, R.lookAt = key, now
        end
    end
end

-- What's closest to the tester, of what the dream made.
local function Near()
    local p = R.ply
    local pos = p:GetPos()
    local list = {}
    for e, key in pairs(R.seen) do
        if IsValid(e) then
            local owner = e.GetOwner and e:GetOwner()
            if owner ~= p then list[#list + 1] = { d = pos:Distance(e:GetPos()), key = key } end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local parts, n = {}, 0
    for i = 1, math.min(8, #list) do
        parts[#parts + 1] = list[i].key .. " (" .. math.floor(list[i].d) .. ")"
        n = n + 1
    end
    local line = #list .. " things of the dream's; nearest: " .. (n > 0 and table.concat(parts, ", ") or "none")
    if line ~= R.nearSaid then Add("near", line) R.nearSaid = line end
end

------------------------------------------------------------------------
-- Sending it to the tester
------------------------------------------------------------------------

local function SendLines(kind, lines, info)
    local p = R and R.ply
    if not IsValid(p) then return end
    local from = 1
    repeat
        local bytes, to = 0, from - 1
        while to < #lines and to - from < 80 and bytes < 30000 do
            to = to + 1
            bytes = bytes + #lines[to][3] + 24
        end
        net.Start("lc_dreamrec")
        net.WriteString(kind)
        net.WriteString(info or "")
        net.WriteUInt(math.max(0, to - from + 1), 16)
        for i = from, to do
            net.WriteFloat(lines[i][1])
            net.WriteString(lines[i][2])
            net.WriteString(lines[i][3])
        end
        net.Send(p)
        from = to + 1
        info = nil
    until from > #lines
end

local function Flush(kind, info)
    if not R then return end
    Spill("made", R.made, true)
    Spill("gone", R.gone)
    Spill("sound", R.sounds)
    -- (net messages: by name; one that goes out every time is named once)
    local names = {}
    for name, n in pairs(R.nets) do
        local hot = (R.netHot[name] or 0) + 1
        R.netHot[name] = hot
        if hot < 6 then names[#names + 1] = name .. (n > 1 and (" x" .. n) or "")
        elseif hot == 6 then names[#names + 1] = name .. " (goes out all the time: not written again)" end
        R.nets[name] = nil
    end
    for name in pairs(R.netHot) do if not R.netSeen[name] then R.netHot[name] = nil end end
    R.netSeen = {}
    if #names > 0 then table.sort(names) Add("net", table.concat(names, ", ")) end
    if not R.started then return end -- (kept until the dream is really under way)
    local lines = R.out
    R.out = {}
    if #lines > 0 or kind then SendLines(kind or "lines", lines, info) end
end

------------------------------------------------------------------------
-- Starting and stopping
------------------------------------------------------------------------

local HOOKS = {}
local function Hook(name, fn)
    HOOKS[#HOOKS + 1] = name
    hook.Add(name, "LivingCityDreamRec", function(...)
        if not R then return end
        local ok, err = LC.Try(fn, ...)
        if not ok and LC.Error then LC.Error("dream recorder", err) end
        -- (never a return value: the recorder watches, it decides nothing)
    end)
end

local startWas, startMine, noticeWas, noticeMine

local function Stop(why)
    local r = R
    if not r then return end
    timer.Remove("LivingCityDreamRec")
    if r.started then
        Add("end", why or "the dream ended")
        LC.Try(Flush, "end", why or "")
    end
    R = nil
    for _, name in ipairs(HOOKS) do hook.Remove(name, "LivingCityDreamRec") end
    HOOKS = {}
    -- (put back only what's still ours: anything wrapped over it since stays, and ours does nothing with no recording)
    if startMine and net.Start == startMine then net.Start = startWas end
    if noticeMine and LC.Notice == noticeMine then LC.Notice = noticeWas end
    startMine, noticeMine = nil, nil
end

local function Tick()
    if not R then return end
    if not IsValid(R.ply) then Stop("the tester left") return end
    R.ticks = R.ticks + 1
    -- (safeguards: a test that never began, or a dream that went without a word, isn't waited for)
    if not R.started then
        if R.ticks > 10 then Stop() return end
    elseif LC.DreamActive ~= R.dream and not R.ply.lcDreaming then
        R.over = (R.over or 0) + 1
        if R.over > 12 then Stop("the dream was gone") return end
    end
    if R.dream then
        local ok, err = LC.Try(function()
            You()
            local st = DreamState()
            Diff("state", R.state, st, R.firstState)
            R.state, R.firstState = st, nil
            local nw = Networked()
            if R.nw then Diff("nw", R.nw, nw) end
            R.nw = nw
            if R.ticks % 10 == 0 then Near() end
        end)
        if not ok then
            R.errors = (R.errors or 0) + 1
            if R.errors <= 3 then Add("recorder", "couldn't look (" .. tostring(err) .. ")") end
        end
    end
    if R.ticks % 2 == 0 then
        local ok, err = LC.Try(Flush)
        if not ok and LC.Error then LC.Error("dream recorder", err) end
    end
end

-- A test is about to start (sv_livingcity_dreamtest.lua, before the dream is made, so everything
-- it puts out from the very first is seen). Nothing reaches the tester until it really starts.
function LC.DreamRecBegin(p, id)
    if R then Stop("another test began") end
    if not IsValid(p) then return false end
    if p.GetInfoNum and p:GetInfoNum("lc_dreamrec", 1) == 0 then return false end
    local pt = LC.DreamPoint and LC.DreamPoint()
    R = { ply = p, id = tostring(id), t0 = CurTime(), out = {}, total = 0, made = {}, gone = {}, sounds = {}, nets = {}, netHot = {}, netSeen = {},
        seen = setmetatable({}, { __mode = "k" }), state = {}, firstState = true, hot = {}, ticks = 0, point = pt and pt.pos or nil }

    Hook("OnEntityCreated", function(e)
        if not IsValid(e) then return end
        timer.Simple(0, function()
            if not R or not IsValid(e) or R.seen[e] then return end
            local class = e:GetClass()
            if SKIP[class] or e:IsPlayer() then return end
            local pos = e:GetPos()
            local owner = e.GetOwner and e:GetOwner()
            if IsValid(owner) and owner == R.ply then
                R.seen[e] = Words(e)
                Add("you", "given " .. class)
                return
            end
            if R.dream and LC.DreamHolds and not LC.DreamHolds(R.dream, pos, true) then return end -- (the city's own, elsewhere)
            local key = Words(e)
            R.seen[e] = key
            Count(R.made, key, pos)
        end)
    end)
    Hook("EntityRemoved", function(e)
        local key = R.seen[e]
        if key then Count(R.gone, key) R.seen[e] = nil end
    end)
    Hook("EntityEmitSound", function(data)
        if not istable(data) then return end
        local e = data.Entity
        local name = tostring(data.SoundName or data.OriginalSoundName or "?")
        local from
        if IsValid(e) then
            if e == R.ply then from = "the tester"
            elseif R.seen[e] then from = e:GetClass()
            elseif e:IsPlayer() then return
            elseif R.dream and LC.DreamHolds and not LC.DreamHolds(R.dream, e:GetPos(), true) then return
            else from = e:GetClass() end
        else
            from = "the world"
        end
        Count(R.sounds, name .. " (from " .. from .. ")")
    end)
    Hook("KeyPress", function(ply, key)
        if ply ~= R.ply then return end
        R.pressed = true
        if KEYS[key] then
            local now = CurTime()
            R.keyAt = R.keyAt or {}
            if now - (R.keyAt[key] or 0) >= 0.5 then Add("you", "pressed " .. KEYS[key]) R.keyAt[key] = now end
        end
    end)
    Hook("PlayerUse", function(ply, e)
        if ply ~= R.ply or not IsValid(e) then return end
        local now = CurTime()
        if R.usedEnt == e and now - (R.usedAt or 0) < 1.5 then R.usedAt = now return end
        R.usedEnt, R.usedAt = e, now
        Add("you", "used " .. (R.seen[e] or Words(e)))
    end)
    -- (chat has many listeners and any of them may answer first, so the gamemode's own "spoke" is listened to as well)
    local function Typed(text)
        text = tostring(text)
        local now = CurTime()
        if R.typed == text and now - (R.typedAt or 0) < 1 then return end
        R.typed, R.typedAt = text, now
        Add("you", "typed: " .. text)
    end
    Hook("PlayerSay", function(ply, text)
        if ply == R.ply then Typed(text) end
    end)
    Hook("LivingCitySpoke", function(ply, _, text)
        if ply == R.ply and text then Typed(text) end
    end)
    Hook("EntityTakeDamage", function(e, dmg)
        if e ~= R.ply or not dmg then return end
        local by = dmg.GetAttacker and dmg:GetAttacker()
        local n = dmg.GetDamage and dmg:GetDamage() or 0
        local now = CurTime()
        if now - (R.hurtAt or 0) < 0.5 then return end
        R.hurtAt = now
        Add("you", "hit for " .. math.floor(n + 0.5) .. " by " .. (IsValid(by) and (R.seen[by] or by:GetClass()) or "something"))
    end)
    Hook("PlayerDeath", function(ply, _, by)
        if ply == R.ply then Add("you", "died" .. (IsValid(by) and by ~= ply and (" (" .. (R.seen[by] or by:GetClass()) .. ")") or "")) end
    end)
    Hook("PlayerSpawn", function(ply)
        if ply == R.ply and R.dream then Add("you", "spawned") end
    end)
    Hook("PlayerDisconnected", function(ply)
        if ply == R.ply then Stop("the tester left") end
    end)
    Hook("LivingCityDreamStarted", function(dream)
        if not (dream and dream.test and dream.list and table.HasValue(dream.list, R.ply)) then return end
        R.dream, R.started = dream, true
        local title = LC.DreamTitle and LC.DreamTitle(R.id) or R.id
        local mood = LC.DreamMood and LC.DreamMood(R.id) or "?"
        local info = util.TableToJSON({ id = R.id, title = title, mood = mood, kind = dream.game and "a dream you play" or "an ending",
            map = game.GetMap and game.GetMap() or "?", t0 = R.t0, max = GetConVar("lc_dream_max_minutes") and GetConVar("lc_dream_max_minutes"):GetFloat() or 0 }) or "{}"
        local lines = R.out
        R.out = {}
        table.insert(lines, 1, { 0, "start", "\"" .. title .. "\" (" .. R.id .. "), " .. tostring(mood) .. ", dream point at " ..
            (dream.pos and string.format("%d %d %d", dream.pos.x, dream.pos.y, dream.pos.z) or "?") })
        SendLines("start", lines, info)
    end)
    Hook("LivingCityDreamWoke", function(ply, ok, why)
        if ply ~= R.ply then return end
        Add("you", "woke (" .. tostring(why or "?") .. ")" .. (ok and "" or ", and not everything was put back at once"))
        Stop("woke: " .. tostring(why or "?"))
    end)
    Hook("LivingCityDreamEnded", function(dream)
        if dream ~= R.dream then return end
        Add("end", "the dream is over; waking")
        -- (the tester's own waking, a moment later, closes the recording; this is in case it never comes)
        timer.Simple(3, function() if R and R.dream == dream then Stop("the dream ended") end end)
    end)

    -- Notices to the tester, and the names of the net messages going out.
    noticeWas = LC.Notice
    if noticeWas then
        noticeMine = function(ply, kind, title, text, secs, ...)
            if R and (ply == nil or ply == R.ply or (istable(ply) and table.HasValue(ply, R.ply))) then
                LC.Try(Add, "notice", "[" .. tostring(kind) .. (secs and (", " .. tostring(secs) .. "s") or "") .. "] " .. tostring(title) .. ": " .. tostring(text))
            end
            return noticeWas(ply, kind, title, text, secs, ...)
        end
        LC.Notice = noticeMine
    end
    startWas = net.Start
    startMine = function(name, ...)
        if R and name ~= "lc_dreamrec" then
            name = tostring(name)
            R.nets[name] = (R.nets[name] or 0) + 1
            R.netSeen[name] = true
        end
        return startWas(name, ...)
    end
    net.Start = startMine

    timer.Create("LivingCityDreamRec", 0.5, 0, Tick)
    return true
end

-- The test never started: nothing was sent, nothing is kept.
function LC.DreamRecAbort()
    if R and not R.started then Stop() end
end

function LC.DreamRecStop(why) Stop(why) end
