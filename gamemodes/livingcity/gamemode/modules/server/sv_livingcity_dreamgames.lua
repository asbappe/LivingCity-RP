--[[
    Living City: nightmare dreams you play (the dream games)

      The owner, 7 November: "make some nightmare dreams for the game mode": a maze where giant
      metro cops chase everyone, a climb with explosive barrels that blow up if touched, "and any
      other similar ideas".

      Four Nightmare dreams for the Administrator's tablet, next to the endings (Tablet > Tonight's
      dream > Nightmare). Each builds its own arena at the dream point out of plain props (nothing
      of the map is used, and all of it goes when the dream ends). Everything else about a dream
      is as it always was (sv_livingcity_dreams.lua): only those asleep dream it, everything about
      them is written down first, nothing they do counts, nobody is really hurt, and they wake in
      their bed with everything they had.

        The Patrol Maze (maze): pick up every glowing ration token in a maze while giant Civil
          Protection officers hunt you down its corridors. The four golden tokens in the corners
          turn the tables for a few seconds: the officers run, and touching one sends him back to
          the middle. Caught: one of your three lives gone, back to the start. No lives left: you
          jolt awake. Every token gone: everyone still in it wins.
        The Barrel Tower (barrels): climb the ramps to the top, where a giant Overwatch soldier
          rolls explosive barrels down at you. Touch a barrel and it blows: back to the bottom,
          one of three lives gone. Jump over them. Reach the top to win.
        The Crumbling Floor (crumble): the floor is tiles over a drop. A tile you stand on cracks
          and falls a moment later, and a scanner overhead marks more. Fall and you wake. The last
          one standing wins (alone: last 90 seconds).
        Freeze, Citizen (freeze): cross the yard while a giant officer has his back turned. When
          he turns and shouts, anyone still moving is sent back to the start (three strikes and
          you wake). Reach the line in front of him to win.

      Each has a time limit: when it's up, whoever is still in it wakes as the nightmare fades.
      Out of lives, or won (the owner, 7 November: "give players the option to wake up if they run
      out of lives, otherwise they can spectate til it's over"): a choice on screen, wake up now or
      watch the rest (flying about inside the arena) until it's over. Waking, a winner is well
      rested and whoever lasted to the end gets a little; whoever lost every life wakes shaken
      (LC.DreamOutcome, sv_livingcity_vices.lua). Nobody wakes themselves from a nightmare while
      they're still in it (sv_livingcity_dreams.lua). The random dream (lc_dream_every_night) still
      picks only from the endings.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dreamgame") -- the dreamer's screen: the game, its tokens, lives, time

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) else p:ChatPrint(title .. ": " .. text) end
end
local function Log(level, msg) if LC.Log then LC.Log(level, msg) end end
local function Snd(e, s, lvl, pitch) if IsValid(e) and e.EmitSound then e:EmitSound(s, lvl or 75, pitch or 100) end end
local function Boom(pos)
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetMagnitude(1)
    ed:SetScale(1)
    util.Effect("Explosion", ed, true, true)
end
local function Puff(pos)
    local ed = EffectData()
    ed:SetOrigin(pos)
    util.Effect("cball_explode", ed, true, true)
end

local G = LC.DreamGames or {}
LC.DreamGames = G
LC.DreamGameOrder = { "maze", "barrels", "crumble", "freeze" }

-- Models (Garry's Mod's own building blocks and Half-Life 2's people): sizes as they are in game.
local PLATE8, PLATE8_S = "models/hunter/plates/plate8x8.mdl", 379.6
local PLATE4, PLATE4_S = "models/hunter/plates/plate4x4.mdl", 189.8
local WALL = "models/hunter/plates/plate2x4.mdl" -- (94.9 by 189.8: stood on its long edge, a wall 95 high)
local COP = "models/police.mdl"
local SOLDIER = "models/combine_super_soldier.mdl"
local SCANNER = "models/combine_scanner.mdl"
local BARREL = "models/props_c17/oildrum001_explosive.mdl"
local PLATE_HALF = 1.5 -- (half a plate's thickness)

LC.DreamGameNames = {}
function LC.DreamGameName(id) return G[id] and G[id].name or nil end

------------------------------------------------------------------------
-- The arena: room for it, and its props
------------------------------------------------------------------------

-- How far the arena may reach from the dream point (half its width): the dream zone, or the
-- square inside lc_dream_radius.
function LC.DreamGameHalf(dream)
    local z, c = dream.zone, dream.pos
    if z and z.box then
        local b = z.box
        return math.max(300, math.min(c.x - b.mins.x, b.maxs.x - c.x, c.y - b.mins.y, b.maxs.y - c.y) - 16)
    end
    if z and z.pos then
        local d = math.sqrt((c.x - z.pos.x) ^ 2 + (c.y - z.pos.y) ^ 2)
        return math.max(300, (z.r - d) * 0.7)
    end
    return math.max(300, (LC.DreamRadius and LC.DreamRadius(dream) or 1500) * 0.7)
end
-- Headroom above the dream point (up to 2000).
function LC.DreamGameHeadroom(dream)
    local from = dream.pos + Vector(0, 0, 16)
    local tr = util.TraceLine({ start = from, endpos = from + Vector(0, 0, 2000), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit and tr.HitPos then return math.max(0, tr.HitPos.z - dream.pos.z) end
    return 2000
end

local function ValidModel(m) return not util.IsValidModel or util.IsValidModel(m) end

-- A solid, still prop for the arena (walls, floors, ramps).
local function Block(g, model, pos, ang, col, mat)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetKeyValue("solid", "6")
    e:SetPos(pos)
    e:SetAngles(ang or Angle(0, 0, 0))
    e:Spawn()
    if e.SetMoveType then e:SetMoveType(MOVETYPE_NONE) end
    if col then e:SetColor(col) end
    if mat then e:SetMaterial(mat) end
    e.lcDreamGame = true
    g.ents[#g.ents + 1] = e
    return e
end
-- Something that moves under the dream's own hand (officers, barrels, the scanner): not solid,
-- moved every tick; touching is measured, not felt.
local function Actor(g, model, pos, yaw, scale, act)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetKeyValue("solid", "0")
    e:SetPos(pos)
    e:SetAngles(Angle(0, yaw or 0, 0))
    e:Spawn()
    if e.SetMoveType then e:SetMoveType(MOVETYPE_NONE) end
    e:SetNotSolid(true)
    if scale and scale ~= 1 then e:SetModelScale(scale) end
    if act then
        local seq = e.SelectWeightedSequence and e:SelectWeightedSequence(act) or -1
        if seq and seq >= 0 and e.ResetSequence then e:ResetSequence(seq) if e.SetPlaybackRate then e:SetPlaybackRate(1) end end
    end
    e.lcDreamGame = true
    g.ents[#g.ents + 1] = e
    return e
end
local function Animate(e, act, name)
    if not IsValid(e) or not e.ResetSequence then return end
    local seq = name and e.LookupSequence and e:LookupSequence(name) or -1
    if (not seq or seq < 0) and act and e.SelectWeightedSequence then seq = e:SelectWeightedSequence(act) end
    if seq and seq >= 0 then e:ResetSequence(seq) if e.SetPlaybackRate then e:SetPlaybackRate(1) end end
end
-- A floor plate whose top is at height z.
local function Floor(g, model, x, y, z, col, mat)
    return Block(g, model, Vector(x, y, z - PLATE_HALF), Angle(0, 0, 0), col, mat)
end
-- A wall 95 high and 190 long, from a to b along x or y (its middle at the given point).
local function WallAt(g, mid, alongX, floorTop, col)
    local e = Block(g, WALL, Vector(mid.x, mid.y, floorTop + 47.45), Angle(0, 0, 0), col, "models/debug/debugwhite")
    if not e then return nil end
    -- the plate lies flat with its long side along one of its own axes: stand it on that edge
    local mins, maxs = e:OBBMins(), e:OBBMaxs()
    local longY = (maxs.y - mins.y) >= (maxs.x - mins.x)
    if longY then
        e:SetAngles(Angle(90, alongX and -90 or 0, 0)) -- (pitched up: its short side stands, its long side along the run)
    else
        e:SetAngles(Angle(0, alongX and 0 or 90, 90))
    end
    return e
end

------------------------------------------------------------------------
-- Dreamers in the game: lives, the start, being caught, winning
------------------------------------------------------------------------

local function Send(g, t, who)
    net.Start("lc_dreamgame")
    net.WriteTable(t)
    if who then net.Send(who) else
        local list = {}
        for p in pairs(g.pl) do if IsValid(p) then list[#list + 1] = p end end
        for p in pairs(g.enf or {}) do if IsValid(p) then list[#list + 1] = p end end -- (Enforcers hear it all too)
        if #list > 0 then net.Send(list) end
    end
end
local function InPlay(g)
    local out = {}
    for p, s in pairs(g.pl) do
        if IsValid(p) and not s.done and p.lcDreaming == g.dream.id then out[#out + 1] = p end
    end
    return out
end
LC.DreamGameInPlay = InPlay

-- To the start (and a moment nobody can catch them).
local function ToStart(g, p, grace)
    local s = g.pl[p]
    if not s then return end
    p:SetPos(s.start)
    if p.SetVelocity then p:SetVelocity(-(p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0))) end
    if p.SetEyeAngles and s.yaw then p:SetEyeAngles(Angle(0, s.yaw, 0)) end
    s.safe = CurTime() + (grace or 2.5)
end

-- Out of it, watching the rest: flying about inside the arena until it's over.
local function Watch(g, p)
    local s = g.pl[p]
    s.watching = true
    p.lcGameWatching = true
    p:SetNW2Bool("lc_game_watching", true)
    if p.Spectate then p:Spectate(OBS_MODE_ROAMING or 6) end
    p:SetPos(g.watchAt or (g.dream.pos + Vector(0, 0, 350)))
end
-- Out of the game (won, caught too often, fallen, or the time's up). Won or out: wake now, or
-- watch the rest (their choice, on screen); the time's up: awake.
local function Done(g, p, how, title, text)
    local s = g.pl[p]
    if not s or s.done then return end
    s.done, s.how = true, how
    p.lcDreamGameResult = { how = how, name = g.def.name, id = g.def.id } -- (how they wake: LC.DreamOutcome, or the dream's own woke)
    if how == "won" then g.won[#g.won + 1] = p end
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, how == "won" and Color(255, 245, 210, 255) or Color(0, 0, 0, 255), 1.2, 0.2) end
    Notice(p, how == "won" and "info" or "warn", title, text, 8)
    if how == "time" then
        Send(g, { k = "stop", how = how }, p)
        if LC.DreamWakeOne then LC.DreamWakeOne(p, "game") end
        return
    end
    Watch(g, p)
    Send(g, { k = "out", how = how, title = title, text = text }, p)
    g.dirty = true
end
LC.DreamGameDone = Done

-- Caught (or blown up): a life gone, back to the start; none left, awake.
local function Hit(g, p, title, text)
    local s = g.pl[p]
    if not s or s.done or CurTime() < (s.safe or 0) then return false end
    s.lives = s.lives - 1
    if s.lives <= 0 then
        Done(g, p, "out", title, text .. " You're out of it.")
        return true
    end
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(160, 0, 0, 200), 0.6, 0.1) end
    Notice(p, "warn", title, text .. string.format(" %d %s left.", s.lives, s.lives == 1 and "life" or "lives"), 4)
    ToStart(g, p)
    g.dirty = true
    return true
end
LC.DreamGameHit = Hit

local function Win(g, p, text)
    Done(g, p, "won", "You beat the nightmare", text or "You made it. The nightmare lets go of you.")
end
LC.DreamGameWin = Win

-- Out of the arena (over a wall, off the edge): back to the start.
local function Strayed(g, p)
    local pos, b = p:GetPos(), g.bounds
    if not b then return false end
    return pos.x < b.mins.x or pos.x > b.maxs.x or pos.y < b.mins.y or pos.y > b.maxs.y or pos.z < b.mins.z or pos.z > b.maxs.z
end

------------------------------------------------------------------------
-- The Patrol Maze
------------------------------------------------------------------------

do
    local CELL = PLATE4_S -- (each corridor is a plate wide)
    local def = { id = "maze", name = "The Patrol Maze", mood = "nightmare", secs = 300, lives = 3,
        goal = "Pick up every glowing token. Giant officers hunt you: don't let them touch you. A golden token makes them run for a while." }
    G.maze = def

    local function Key(cx, cy) return cx .. "_" .. cy end

    -- A maze of w by h cells: every cell reachable, and some extra ways through (so there's always
    -- another way round). open[Key(a)][Key(b)] = true where a and b are joined.
    function LC.DreamMaze(w, h, loops)
        local open, seen, stack = {}, {}, {}
        for x = 1, w do for y = 1, h do open[Key(x, y)] = {} end end
        local function Join(ax, ay, bx, by) open[Key(ax, ay)][Key(bx, by)] = true open[Key(bx, by)][Key(ax, ay)] = true end
        local sx, sy = math.random(w), math.random(h)
        seen[Key(sx, sy)] = true
        stack[1] = { sx, sy }
        while #stack > 0 do
            local c = stack[#stack]
            local opts = {}
            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local nx, ny = c[1] + d[1], c[2] + d[2]
                if nx >= 1 and nx <= w and ny >= 1 and ny <= h and not seen[Key(nx, ny)] then opts[#opts + 1] = { nx, ny } end
            end
            if #opts == 0 then table.remove(stack) else
                local n = opts[math.random(#opts)]
                Join(c[1], c[2], n[1], n[2])
                seen[Key(n[1], n[2])] = true
                stack[#stack + 1] = n
            end
        end
        for _ = 1, loops or 0 do
            local x, y = math.random(w), math.random(h)
            if math.random() < 0.5 and x < w then Join(x, y, x + 1, y) elseif y < h then Join(x, y, x, y + 1) end
        end
        return open
    end

    -- The shortest way from one cell to another: the next cell to step to.
    local function NextStep(g, from, to)
        if from == to then return nil end
        local prev, q, head = { [from] = from }, { from }, 1
        while head <= #q do
            local c = q[head]
            head = head + 1
            if c == to then break end
            for n in pairs(g.open[c]) do
                if not prev[n] then prev[n] = c q[#q + 1] = n end
            end
        end
        if not prev[to] then return nil end
        local c = to
        while prev[c] ~= from do c = prev[c] end
        return c
    end

    local function CellPos(g, k) return g.cells[k] end
    local function CellOf(g, pos)
        local cx = math.Clamp(math.floor((pos.x - g.x0) / CELL) + 1, 1, g.w)
        local cy = math.Clamp(math.floor((pos.y - g.y0) / CELL) + 1, 1, g.h)
        return Key(cx, cy)
    end
    LC.DreamMazeCellOf = CellOf

    function def.build(g, dream)
        local half = LC.DreamGameHalf(dream)
        local w = math.Clamp(math.floor(half * 2 / CELL), 5, 9)
        local h = math.Clamp(math.floor(half * 2 / CELL), 5, 8)
        g.w, g.h = w, h
        g.x0, g.y0 = dream.pos.x - w * CELL / 2, dream.pos.y - h * CELL / 2
        local top = dream.pos.z + 2
        g.top = top
        g.open = LC.DreamMaze(w, h, math.floor(w * h / 6))
        g.cells = {}
        for x = 1, w do for y = 1, h do g.cells[Key(x, y)] = Vector(g.x0 + (x - 0.5) * CELL, g.y0 + (y - 0.5) * CELL, top) end end
        -- the floor
        local fx, fy = math.ceil(w * CELL / PLATE8_S), math.ceil(h * CELL / PLATE8_S)
        for i = 1, fx do for j = 1, fy do
            Floor(g, PLATE8, g.x0 + (i - 0.5) * PLATE8_S, g.y0 + (j - 0.5) * PLATE8_S, top, Color(20, 22, 40), "models/debug/debugwhite")
        end end
        -- the walls: round the outside, and between cells that aren't joined
        local blue = Color(40, 70, 220)
        for x = 1, w do
            WallAt(g, Vector(g.x0 + (x - 0.5) * CELL, g.y0, 0), true, top, blue)
            WallAt(g, Vector(g.x0 + (x - 0.5) * CELL, g.y0 + h * CELL, 0), true, top, blue)
        end
        for y = 1, h do
            WallAt(g, Vector(g.x0, g.y0 + (y - 0.5) * CELL, 0), false, top, blue)
            WallAt(g, Vector(g.x0 + w * CELL, g.y0 + (y - 0.5) * CELL, 0), false, top, blue)
        end
        for x = 1, w do for y = 1, h do
            if x < w and not g.open[Key(x, y)][Key(x + 1, y)] then WallAt(g, Vector(g.x0 + x * CELL, g.y0 + (y - 0.5) * CELL, 0), false, top, blue) end
            if y < h and not g.open[Key(x, y)][Key(x, y + 1)] then WallAt(g, Vector(g.x0 + (x - 0.5) * CELL, g.y0 + y * CELL, 0), true, top, blue) end
        end end
        -- the tokens: one in every cell and one in every way between two, golden in the corners
        g.tokens, g.tokenAt, g.left = {}, {}, 0
        local corners = { [Key(1, 1)] = true, [Key(w, 1)] = true, [Key(1, h)] = true, [Key(w, h)] = true }
        g.pen = Key(math.ceil(w / 2), math.ceil(h / 2))
        local function Token(pos, big, cell)
            g.tokens[#g.tokens + 1] = { pos = pos + Vector(0, 0, 36), big = big, cell = cell }
            g.left = g.left + 1
        end
        for x = 1, w do for y = 1, h do
            local k = Key(x, y)
            if k ~= g.pen then Token(g.cells[k], corners[k], k) end
            if x < w and g.open[k][Key(x + 1, y)] then Token(g.cells[k] + Vector(CELL / 2, 0, 0), false, k) end
            if y < h and g.open[k][Key(x, y + 1)] then Token(g.cells[k] + Vector(0, CELL / 2, 0), false, k) end
        end end
        -- the officers, in the middle, giants
        g.cops = {}
        local n = math.Clamp(2 + math.floor(#g.dream.list / 2), 2, 4)
        for i = 1, n do
            local e = Actor(g, COP, g.cells[g.pen], 0, 1.7, ACT_RUN or 10)
            if e then g.cops[#g.cops + 1] = { e = e, at = g.pen, to = nil, t = 0, kind = i, home = CurTime() + 3 + i * 2 } end
        end
        g.bounds = { mins = Vector(g.x0 - 40, g.y0 - 40, top - 200), maxs = Vector(g.x0 + w * CELL + 40, g.y0 + h * CELL + 40, top + 60) }
        -- where the dreamers start: the bottom row, from the middle out
        g.starts = {}
        local mid = math.ceil(w / 2)
        for i = 0, w - 1 do
            local x = mid + (i % 2 == 0 and i / 2 or -(i + 1) / 2)
            if x >= 1 and x <= w then g.starts[#g.starts + 1] = g.cells[Key(x, 1)] + Vector(0, 0, 4) end
        end
        return true
    end

    function def.spawn(g, p, i)
        return g.starts[((i - 1) % #g.starts) + 1], 90
    end

    function def.hello(g)
        local list = {}
        for i, t in ipairs(g.tokens) do list[i] = { math.floor(t.pos.x), math.floor(t.pos.y), math.floor(t.pos.z), t.big and 1 or 0 } end
        return { tokens = list, left = g.left }
    end

    local function Speed(g)
        local run, n = 0, 0
        for p in pairs(g.pl) do if IsValid(p) and p.GetRunSpeed then run, n = run + p:GetRunSpeed(), n + 1 end end
        run = n > 0 and run / n or 240
        local ramp = math.min(0.13, (CurTime() - g.t0) / 300 * 0.13) -- (a little faster as it goes on)
        return run * (0.8 + ramp)
    end

    local function Target(g, c, players)
        if #players == 0 then return nil end
        local pos = c.e:GetPos()
        local best, bd
        for _, p in ipairs(players) do
            local d = p:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = p, d end
        end
        if c.kind == 2 then -- (heads for where you're going)
            local ahead = best:GetPos() + (best.GetVelocity and best:GetVelocity() or Vector(0, 0, 0)) * 1.2
            return CellOf(g, ahead)
        elseif c.kind == 3 then -- (picks someone, and keeps after them a while)
            if not IsValid(c.prey) or (c.preyUntil or 0) < CurTime() or g.pl[c.prey] == nil or g.pl[c.prey].done then
                c.prey, c.preyUntil = players[math.random(#players)], CurTime() + 12
            end
            return CellOf(g, c.prey:GetPos())
        elseif c.kind == 4 and math.floor((CurTime() - g.t0) / 7) % 2 == 1 then -- (goes off round the corners, now and then)
            local ks = { Key(1, 1), Key(g.w, 1), Key(1, g.h), Key(g.w, g.h) }
            return ks[(math.floor((CurTime() - g.t0) / 14) % 4) + 1]
        end
        return CellOf(g, best:GetPos())
    end

    local VOICE = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/dontmove.wav", "npc/metropolice/vo/prepareforjudgement.wav",
        "npc/metropolice/vo/finalwarning.wav", "npc/metropolice/vo/citizen.wav", "npc/metropolice/vo/getdown.wav" }

    function def.tick(g, dt, players)
        local now = CurTime()
        local afraid = (g.afraid or 0) > now
        local speed = Speed(g) * (afraid and 0.55 or 1)
        -- the dreamers: tokens, walls
        for _, p in ipairs(players) do
            local pos = p:GetPos()
            if pos.z > g.top + 50 then -- (up on a wall: down into the nearest corridor)
                p:SetPos(g.cells[CellOf(g, pos)] + Vector(0, 0, 4))
            end
            for i, t in ipairs(g.tokens) do
                if not t.got and math.abs(t.pos.x - pos.x) < 40 and math.abs(t.pos.y - pos.y) < 40 and math.abs(t.pos.z - 36 - pos.z) < 70 then
                    t.got = true
                    g.left = g.left - 1
                    Send(g, { k = "got", i = i })
                    if t.big then
                        g.afraid = now + 8
                        for _, c in ipairs(g.cops) do if IsValid(c.e) then c.e:SetColor(Color(70, 110, 255)) end end
                        for q in pairs(g.pl) do if IsValid(q) then Snd(q, "npc/metropolice/vo/movingtocode3.wav", 60) end end
                        Notice(p, "info", "A golden token", "The officers are afraid of you for a few seconds: catch one to send him back to the middle.", 4)
                    else
                        Snd(p, "buttons/blip1.wav", 55, 140)
                    end
                    g.dirty = true
                end
            end
        end
        if not afraid and g.wasAfraid then
            for _, c in ipairs(g.cops) do if IsValid(c.e) then c.e:SetColor(Color(255, 255, 255)) end end
        end
        g.wasAfraid = afraid
        -- every token gone: they win
        if g.left <= 0 then
            for _, p in ipairs(players) do Win(g, p, "Every token picked up. The officers fade into the dark.") end
            return
        end
        -- the officers
        for _, c in ipairs(g.cops) do
            if IsValid(c.e) then
                if (c.home or 0) > now then
                    c.at, c.to = g.pen, nil
                    c.e:SetPos(g.cells[g.pen])
                else
                    if not c.to then
                        local nxt
                        if afraid then -- (running: any way but back)
                            local opts = {}
                            for k in pairs(g.open[c.at]) do if k ~= c.last then opts[#opts + 1] = k end end
                            if #opts == 0 then for k in pairs(g.open[c.at]) do opts[#opts + 1] = k end end
                            nxt = opts[math.random(math.max(1, #opts))]
                        else
                            local goal = Target(g, c, players)
                            nxt = goal and NextStep(g, c.at, goal)
                            if not nxt then for k in pairs(g.open[c.at]) do nxt = k break end end
                        end
                        c.to, c.t = nxt, 0
                    end
                    if c.to then
                        local a, b = g.cells[c.at], g.cells[c.to]
                        local len = math.max(1, a:Distance(b))
                        c.t = c.t + speed * dt / len
                        if c.t >= 1 then
                            c.last, c.at, c.to = c.at, c.to, nil
                            c.e:SetPos(b)
                        else
                            c.e:SetPos(LerpVector(c.t, a, b))
                            c.e:SetAngles(Angle(0, (b - a):Angle().y, 0))
                        end
                    end
                end
                -- touching a dreamer
                local cp = c.e:GetPos()
                for _, p in ipairs(players) do
                    local pp = p:GetPos()
                    if (pp.x - cp.x) ^ 2 + (pp.y - cp.y) ^ 2 < 52 * 52 and math.abs(pp.z - cp.z) < 90 and (c.home or 0) <= now then
                        if afraid then
                            c.home = now + 5
                            Puff(cp + Vector(0, 0, 50))
                            Snd(p, "weapons/stunstick/stunstick_impact1.wav", 70)
                            Notice(p, "info", "Got him", "Back to the middle with him.", 3)
                            break
                        elseif Hit(g, p, "Caught", "A giant hand closes round you.") then
                            Snd(c.e, VOICE[math.random(#VOICE)], 80, 70)
                        end
                    end
                end
                -- (now and then, the hunt calls out: deeper than any real officer)
                if (c.voiceAt or 0) < now then
                    c.voiceAt = now + math.Rand(7, 14)
                    Snd(c.e, VOICE[math.random(#VOICE)], 80, 65)
                end
            end
        end
    end

    function def.state(g) return { left = g.left, afraid = (g.afraid or 0) > CurTime() and g.afraid or nil } end
end

------------------------------------------------------------------------
-- The Barrel Tower
------------------------------------------------------------------------

do
    local S = PLATE8_S
    local RISE = 110
    local def = { id = "barrels", name = "The Barrel Tower", mood = "nightmare", secs = 240, lives = 3,
        goal = "Climb the ramps to the top. Don't touch the barrels: they explode. Jump over them, or get out of their way." }
    G.barrels = def

    function def.build(g, dream)
        local room = LC.DreamGameHeadroom(dream)
        local n = math.Clamp(math.floor((room - 260) / RISE), 2, 5)
        local theta = math.atan(RISE / (2 * S))
        local L = S * math.cos(theta) -- (each ramp is two plates long; this is half its length on the ground)
        local base = dream.pos.z + 2
        local c = dream.pos
        g.n, g.L, g.base = n, L, base
        local function V(k) return c.y + (k - (n - 1) / 2) * S end
        local function U(u) return c.x + u end
        local steel = Color(110, 90, 70)
        -- the ramps: side by side, each climbing the other way
        for k = 0, n - 1 do
            local up = (k % 2 == 0) and 1 or -1 -- (ramp k climbs toward +x, or -x)
            local z0 = base + k * RISE
            for j = 0, 1 do
                local frac = (j + 0.5) / 2
                local u = up * (-L + frac * 2 * L)
                Block(g, PLATE8, Vector(U(u), V(k), z0 + frac * RISE - PLATE_HALF), Angle(-up * math.deg(theta), 0, 0), steel, "models/debug/debugwhite")
            end
            -- the landing at its top, joining the next ramp
            if k < n - 1 then
                local side = up * (L + S / 2)
                Floor(g, PLATE8, U(side), V(k), z0 + RISE, steel, "models/debug/debugwhite")
                Floor(g, PLATE8, U(side), V(k + 1), z0 + RISE, steel, "models/debug/debugwhite")
            end
        end
        -- the start, and the top
        Floor(g, PLATE8, U(-L - S / 2), V(0), base, Color(60, 60, 60), "models/debug/debugwhite")
        local lastUp = ((n - 1) % 2 == 0) and 1 or -1
        g.topSide = lastUp
        g.topZ = base + n * RISE
        Floor(g, PLATE8, U(lastUp * (L + S / 2)), V(n - 1), g.topZ, Color(140, 30, 30), "models/debug/debugwhite")
        g.topAt = Vector(U(lastUp * (L + S / 2)), V(n - 1), g.topZ)
        -- the giant at the top, by the edge, facing down the ramp
        g.giant = Actor(g, SOLDIER, Vector(U(lastUp * (L + S * 0.85)), V(n - 1), g.topZ), lastUp > 0 and 180 or 0, 2.3, ACT_IDLE or 1)
        -- the barrels' way down: from the giant's feet, down every ramp, off the bottom
        local path = {}
        local function P(u, k, z) path[#path + 1] = { u = u, k = k, z = z } end
        P(lastUp * (L + S * 0.6), n - 1, g.topZ)
        for k = n - 1, 0, -1 do
            local up = (k % 2 == 0) and 1 or -1
            P(up * L, k, base + (k + 1) * RISE)
            P(-up * L, k, base + k * RISE)
            if k > 0 then
                local side = -up * (L + S * 0.5)
                P(side, k, base + k * RISE)
                P(side, k - 1, base + k * RISE)
                P(-up * L, k - 1, base + k * RISE)
            end
        end
        P(-L - S * 0.5, 0, base)
        g.path = path
        g.V, g.U = V, U
        g.barrels = {}
        g.nextBarrel = CurTime() + 4
        g.bounds = { mins = Vector(c.x - L - S - 60, V(0) - S / 2 - 60, base - 160), maxs = Vector(c.x + L + S + 60, V(n - 1) + S / 2 + 60, g.topZ + 400) }
        g.starts = {}
        for i = 0, 7 do g.starts[#g.starts + 1] = Vector(U(-L - S / 2 - 60 + (i % 4) * 40), V(0) - 120 + math.floor(i / 4) * 80 + (i % 2) * 20, base + 4) end
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    local function PathPos(g, b)
        local a, c = g.path[b.seg], g.path[b.seg + 1]
        local t = b.t
        local u = a.u + (c.u - a.u) * t
        local v = g.V(a.k) + (g.V(c.k) - g.V(a.k)) * t + b.lane
        local z = a.z + (c.z - a.z) * t
        return Vector(g.U(u), v, z + 13), Vector(c.u - a.u, g.V(c.k) - g.V(a.k), c.z - a.z)
    end
    LC.DreamBarrelPos = PathPos

    function def.tick(g, dt, players)
        local now = CurTime()
        -- a new barrel, more often as it goes on
        if now >= g.nextBarrel and #g.barrels < 14 then
            local gap = math.max(1.1, 2.6 - (now - g.t0) / 60)
            g.nextBarrel = now + gap * math.Rand(0.8, 1.2)
            local e = Actor(g, BARREL, g.topAt + Vector(0, 0, 14), 0, 1)
            if e then
                g.barrels[#g.barrels + 1] = { e = e, seg = 1, t = 0, lane = math.Rand(-S / 2 + 50, S / 2 - 50), speed = math.Rand(210, 290),
                    hop = math.random() < 0.2 and math.Rand(20, 34) or 0, spin = 0 }
                Animate(g.giant, ACT_RANGE_ATTACK_THROW, "grenThrow")
                g.idleAt = now + 1.2
                Snd(g.giant, "physics/metal/metal_barrel_impact_hard" .. math.random(1, 3) .. ".wav", 75)
            end
        end
        if g.idleAt and now >= g.idleAt then g.idleAt = nil Animate(g.giant, ACT_IDLE or 1) end
        -- the barrels roll
        for i = #g.barrels, 1, -1 do
            local b = g.barrels[i]
            if not IsValid(b.e) then table.remove(g.barrels, i) else
                local _, dir = PathPos(g, b)
                local len = math.max(1, dir:Length())
                b.t = b.t + b.speed * dt / len
                while b.t >= 1 and b.seg < #g.path - 1 do
                    b.t = (b.t - 1) * len
                    b.seg = b.seg + 1
                    local _, d2 = PathPos(g, b)
                    len = math.max(1, d2:Length())
                    b.t = b.t / len
                end
                if b.t >= 1 then -- (off the bottom: it fizzles out)
                    Puff(b.e:GetPos())
                    b.e:Remove()
                    table.remove(g.barrels, i)
                else
                    local pos, d = PathPos(g, b)
                    if b.hop > 0 then pos.z = pos.z + math.abs(math.sin(now * 5 + i)) * b.hop end
                    b.e:SetPos(pos)
                    b.spin = (b.spin + b.speed * dt * 4) % 360
                    local yaw = Vector(d.x, d.y, 0):Angle().y
                    b.e:SetAngles(Angle(b.spin, yaw, 90))
                    -- touched: it blows
                    for _, p in ipairs(players) do
                        local pp = p:GetPos()
                        if (pp.x - pos.x) ^ 2 + (pp.y - pos.y) ^ 2 < 38 * 38 and pp.z < pos.z + 12 and pp.z > pos.z - 70 then
                            if CurTime() >= (g.pl[p].safe or 0) then
                                Boom(pos)
                                for _, q in ipairs(players) do
                                    if q ~= p and q:GetPos():DistToSqr(pos) < 90 * 90 then Hit(g, q, "Blown off your feet", "A barrel went up right next to you.") end
                                end
                                Hit(g, p, "Boom", "You touched a barrel and it went up.")
                                b.e:Remove()
                                table.remove(g.barrels, i)
                                break
                            end
                        end
                    end
                end
            end
        end
        -- the dreamers: the top, or a fall
        for _, p in ipairs(players) do
            local pp = p:GetPos()
            if pp.z > g.topZ - 30 and (pp.x - g.topAt.x) ^ 2 + (pp.y - g.topAt.y) ^ 2 < (S / 2 + 20) ^ 2 then
                Win(g, p, "You reached the top. The giant crumbles to dust.")
            elseif pp.z < g.base - 140 then
                ToStart(g, p, 1)
            end
        end
    end

    function def.state(g) return {} end
end

------------------------------------------------------------------------
-- The Crumbling Floor
------------------------------------------------------------------------

do
    local def = { id = "crumble", name = "The Crumbling Floor", mood = "nightmare", secs = 180, lives = 1,
        goal = "Keep moving: a tile you stand on cracks and falls. The scanner marks more. Fall and you wake. Be the last one standing." }
    G.crumble = def
    local CRACK, FALL = 0.55, 1.0 -- (seconds: cracking, then gone)

    function def.build(g, dream)
        local model, T = PLATE4, PLATE4_S
        if not ValidModel(model) then model, T = PLATE8, PLATE8_S end
        local half = LC.DreamGameHalf(dream)
        local n = math.Clamp(math.floor(half * 2 / T), 4, 8)
        g.n, g.T = n, T
        local lift = math.Clamp(LC.DreamGameHeadroom(dream) - 320, 0, 240) -- (over a drop, where there's room)
        g.top = dream.pos.z + 2 + lift
        g.x0, g.y0 = dream.pos.x - n * T / 2, dream.pos.y - n * T / 2
        g.tiles = {}
        for i = 1, n do for j = 1, n do
            local even = (i + j) % 2 == 0
            local col = even and Color(200, 200, 210) or Color(150, 150, 165)
            local e = Floor(g, model, g.x0 + (i - 0.5) * T, g.y0 + (j - 0.5) * T, g.top, col, "models/debug/debugwhite")
            g.tiles[i .. "_" .. j] = { e = e, i = i, j = j, col = col }
        end end
        g.scanner = Actor(g, SCANNER, Vector(dream.pos.x, dream.pos.y, g.top + 220), 0, 1.5)
        g.scanTo, g.nextMark = nil, CurTime() + 4
        g.bounds = { mins = Vector(g.x0 - 300, g.y0 - 300, g.top - 2000), maxs = Vector(g.x0 + n * T + 300, g.y0 + n * T + 300, g.top + 400) }
        g.starts = {}
        local ring = math.max(1, math.floor(n / 2) - 1)
        for k = 1, 12 do
            local a = (k - 1) / 12 * math.pi * 2
            g.starts[k] = Vector(dream.pos.x + math.cos(a) * ring * T * 0.8, dream.pos.y + math.sin(a) * ring * T * 0.8, g.top + 4)
        end
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    local function TileAt(g, pos)
        local i, j = math.floor((pos.x - g.x0) / g.T) + 1, math.floor((pos.y - g.y0) / g.T) + 1
        if i < 1 or j < 1 or i > g.n or j > g.n then return nil end
        return g.tiles[i .. "_" .. j]
    end
    LC.DreamTileAt = TileAt

    local function Crack(g, t)
        if t.gone or t.crack then return end
        t.crack = CurTime()
        if IsValid(t.e) then t.e:SetColor(Color(230, 200, 60)) Snd(t.e, "physics/concrete/concrete_impact_hard" .. math.random(1, 3) .. ".wav", 70) end
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local calm = now < g.t0 + 3
        -- tiles: cracking, then falling away
        for _, t in pairs(g.tiles) do
            if t.crack and not t.gone then
                local age = now - t.crack
                if age >= FALL then
                    t.gone = true
                    if IsValid(t.e) then Snd(t.e, "physics/concrete/concrete_break" .. math.random(2, 3) .. ".wav", 75) t.e:Remove() end
                elseif age >= CRACK and IsValid(t.e) and not t.red then
                    t.red = true
                    t.e:SetColor(Color(220, 50, 40))
                end
            end
        end
        -- the scanner marks one, more often as it goes on
        if not calm and now >= g.nextMark then
            g.nextMark = now + math.max(0.35, 1.6 - (now - g.t0) / 80)
            local live = {}
            for _, t in pairs(g.tiles) do if not t.gone and not t.crack then live[#live + 1] = t end end
            if #live > 0 then
                local t = live[math.random(#live)]
                Crack(g, t)
                g.scanTo = Vector(g.x0 + (t.i - 0.5) * g.T, g.y0 + (t.j - 0.5) * g.T, g.top + 200)
                if IsValid(g.scanner) then Snd(g.scanner, "npc/scanner/scanner_photo1.wav", 70) end
            end
        end
        if IsValid(g.scanner) and g.scanTo then
            local sp = g.scanner:GetPos()
            g.scanner:SetPos(LerpVector(math.min(1, dt * 4), sp, g.scanTo))
        end
        -- the dreamers: standing on a tile cracks it; nothing under you, you fall
        for _, p in ipairs(players) do
            local pp = p:GetPos()
            local t = TileAt(g, pp)
            local onTop = pp.z <= g.top + 6 and pp.z >= g.top - 2
            if t and not t.gone and onTop and not calm then Crack(g, t) end
            if pp.z < g.top - 1 and (not t or t.gone) or pp.z < g.top - 60 then
                Done(g, p, "out", "You fell", "The floor gives way, and you fall, and fall, into the dark.")
            end
        end
        -- the last one standing
        local left = InPlay(g)
        if g.started >= 2 and #left == 1 then
            Win(g, left[1], "Last one standing. The floor holds.")
        elseif g.started == 1 and #left == 1 and now >= g.t0 + 90 then
            Win(g, left[1], "You kept your feet for ninety seconds. The floor holds.")
        end
    end

    function def.state(g) return { alive = #InPlay(g) } end
end

------------------------------------------------------------------------
-- Freeze, Citizen
------------------------------------------------------------------------

do
    local def = { id = "freeze", name = "Freeze, Citizen", mood = "nightmare", secs = 180, lives = 3,
        goal = "Cross the yard to the giant officer. Move only while his back is turned: when he turns and shouts, stand still." }
    G.freeze = def
    local SHOUTS = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/dontmove.wav", "npc/metropolice/vo/finalwarning.wav", "npc/metropolice/vo/firstwarningmove.wav" }

    function def.build(g, dream)
        local half = LC.DreamGameHalf(dream)
        local long = math.Clamp(math.floor(half * 2 / PLATE8_S), 2, 4)
        local c = dream.pos
        local top = c.z + 2
        g.top = top
        local x0 = c.x - long * PLATE8_S / 2
        for i = 1, long do for j = 0, 1 do
            Floor(g, PLATE8, x0 + (i - 0.5) * PLATE8_S, c.y + (j - 0.5) * PLATE8_S, top, Color(70, 75, 80), "models/debug/debugwhite")
        end end
        g.startX, g.finishX = x0 + 90, x0 + long * PLATE8_S - 160
        -- the finish line (a red strip), and the officer behind it
        local strip = Block(g, "models/hunter/plates/plate1x6.mdl", Vector(g.finishX, c.y, top), Angle(0, 0, 0), Color(220, 30, 30), "models/debug/debugwhite")
        if strip then -- (its long side across the yard)
            local mins, maxs = strip:OBBMins(), strip:OBBMaxs()
            if (maxs.x - mins.x) > (maxs.y - mins.y) then strip:SetAngles(Angle(0, 90, 0)) end
        end
        g.cop = Actor(g, COP, Vector(x0 + long * PLATE8_S - 70, c.y, top), 0, 3.2, ACT_IDLE or 1)
        g.phase, g.phaseAt, g.turned = "green", CurTime() + math.Rand(3, 5), false
        g.bounds = { mins = Vector(x0 - 60, c.y - PLATE8_S - 60, top - 160), maxs = Vector(x0 + long * PLATE8_S + 60, c.y + PLATE8_S + 60, top + 300) }
        g.starts = {}
        for i = 0, 11 do g.starts[#g.starts + 1] = Vector(g.startX + (i % 2) * 40, c.y - 330 + i * 60, top + 4) end
        return true
    end

    function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

    function def.tick(g, dt, players)
        local now = CurTime()
        local pace = math.max(0.5, 1 - (now - g.t0) / 240) -- (faster turns as it goes on)
        if now >= g.phaseAt then
            if g.phase == "green" then
                g.phase, g.phaseAt, g.redFrom = "red", now + math.Rand(2, 3.5), now + 0.6 -- (a moment to stop)
                if IsValid(g.cop) then Snd(g.cop, SHOUTS[math.random(#SHOUTS)], 95, 70) end
            else
                g.phase, g.phaseAt = "green", now + math.Rand(1.5, 4.5) * pace
            end
            g.dirty = true
        end
        if IsValid(g.cop) then
            local want = g.phase == "red" and 180 or 0
            local ang = g.cop:GetAngles()
            local y = math.ApproachAngle and math.ApproachAngle(ang.y, want, 600 * dt) or want
            g.cop:SetAngles(Angle(0, y, 0))
        end
        for _, p in ipairs(players) do
            local pp = p:GetPos()
            if pp.x >= g.finishX then
                Win(g, p, "You reached him without being seen. He's gone.")
            elseif g.phase == "red" and now >= (g.redFrom or 0) then
                local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0)
                if v:Length2D() > 45 and Hit(g, p, "Seen", "He saw you move.") then
                    Snd(p, "weapons/stunstick/stunstick_fleshhit1.wav", 75)
                end
            end
        end
    end

    function def.state(g) return { phase = g.phase } end
end

------------------------------------------------------------------------
-- Starting, running and ending one (sv_livingcity_dreams.lua calls these)
------------------------------------------------------------------------

local function Tick()
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped then timer.Remove("LivingCityDreamGames") return end
    local ok, err = pcall(function()
        local now = CurTime()
        local dt = math.Clamp(now - (g.last or now), 0, 0.25)
        g.last = now
        local players = InPlay(g)
        for _, p in ipairs(players) do
            if Strayed(g, p) then ToStart(g, p, 1) end
        end
        -- the star (the Administrator playing herself) woke up: the dream carries on without her
        if g.star and not (IsValid(g.star) and g.star.lcDreaming == g.dream.id) then
            local was = g.star
            g.star = nil
            if g.def.starGone then g.def.starGone(g, was) end
        end
        g.def.tick(g, dt, InPlay(g))
        -- the time's up, or nobody's left in it
        if now >= g.ends then
            local up = g.def.timeUp or { "The nightmare fades", "It loosens its grip before the end, and you wake." }
            for _, p in ipairs(InPlay(g)) do Done(g, p, "time", up[1], up[2]) end
        end
        if #InPlay(g) == 0 then LC.DreamGameStop(dream, "over") return end
        if g.dirty or now >= (g.sentAt or 0) + 1 then
            g.dirty, g.sentAt = nil, now
            for p, s in pairs(g.pl) do
                if IsValid(p) and (not s.done or s.watching) then -- (watchers see how it goes on too)
                    local t = g.def.state(g, p) or {} -- (with who it's for: a dream may show each their own)
                    t.k, t.lives = "state", s.lives
                    Send(g, t, p)
                end
            end
            if IsValid(g.star) then
                local t = g.def.state(g, g.star) or {}
                t.k = "state"
                Send(g, t, g.star)
            end
            for p in pairs(g.enf or {}) do -- (Enforcers see how it goes too: sv_livingcity_dreamenforcers.lua)
                if IsValid(p) and p.lcDreaming == g.dream.id then
                    local t = g.def.state(g, p) or {}
                    t.k, t.enforcer = "state", true
                    Send(g, t, p)
                end
            end
        end
    end)
    if not ok then
        if LC.Error then LC.Error("dream games", err) end
        LC.DreamGameStop(dream, "error")
    end
end

-- Build tonight's game at the dream point and put its dreamers in it. True, or false and why not.
function LC.DreamGameStart(dream)
    local def = dream and G[dream.ending]
    if not def then return false, "No such dream." end
    if ents.GetEdictCount and ents.GetEdictCount() > 7600 then return false, "The server has too many things in it right now to build that dream." end
    local g = { def = def, id = def.id, dream = dream, ents = {}, pl = {}, won = {}, enf = {}, t0 = CurTime(), last = CurTime(), watchAt = dream.pos + Vector(0, 0, 350) }
    g.ends = g.t0 + def.secs
    dream.game = g
    local players = LC.DreamersOf and LC.DreamersOf(dream) or dream.list
    -- the Administrator, asleep with the others, may star in it herself (sv_livingcity_propagandadreams.lua)
    if def.starring and LC.DreamStarOf then g.star = LC.DreamStarOf(players) end
    local ok, err = pcall(def.build, g, dream)
    if not ok or err == false then
        for _, e in ipairs(g.ents) do if IsValid(e) then e:Remove() end end
        dream.game = nil
        if not ok and LC.Error then LC.Error("dream game build", err) end
        return false, "The dream couldn't be built here."
    end
    g.started = #players
    local hello = def.hello and def.hello(g) or {}
    local n = 0
    local enforcers = {}
    for _, p in ipairs(players) do
        if p ~= g.star and LC.DreamEnforcerRole and LC.DreamEnforcerRole(p, def.id) then
            enforcers[#enforcers + 1] = p -- (Civil Protection and the Administration: they watch over it, after the dreamers are placed)
        elseif p == g.star then
            p.lcDreamGame, p.lcDreamStar = def.id, true
            def.starring(g, p)
            local t = { k = "start", id = def.id, name = def.name, goal = def.starGoal or def.goal, ends = g.ends, lives = 1, maxLives = 1, star = true }
            for k, v in pairs(hello) do t[k] = v end
            Send(g, t, p)
            Notice(p, "info", def.name .. ": you're the star", def.starGoal or def.goal, 10)
        else
            n = n + 1
            local i = n
            local at, yaw = def.spawn(g, p, i)
            g.pl[p] = { lives = def.lives, start = at, yaw = yaw }
            p.lcDreamGame = def.id
            ToStart(g, p, 3)
            local t = { k = "start", id = def.id, name = def.name, goal = def.goal, ends = g.ends, lives = def.lives, maxLives = def.lives }
            for k, v in pairs(hello) do t[k] = v end
            Send(g, t, p)
            Notice(p, "warn", def.name, def.goal, 10)
        end
    end
    for _, p in ipairs(enforcers) do
        if LC.DreamEnforcerJoin then LC.DreamEnforcerJoin(g, p, hello) end
    end
    timer.Create("LivingCityDreamGames", 0, 0, Tick)
    Log("info", string.format("Dream game: %s, %d dreamers, %d props", def.id, #players, #g.ents))
    return true
end

-- One dreamer out of the game (they're waking up, whatever the reason).
function LC.DreamGameLeave(p, dream)
    if not IsValid(p) then return end
    local g = dream and dream.game
    if g and g.pl[p] and not g.pl[p].done then
        g.pl[p].done, g.pl[p].how = true, g.pl[p].how or "woke"
        Send(g, { k = "stop", how = "woke" }, p)
    end
    if p.lcDreamStar then
        p.lcDreamStar = nil
        if g and g.star == p then Send(g, { k = "stop", how = "woke" }, p) end
        if LC.DreamStarDone then LC.DreamStarDone(p) end
    end
    if g and g.enf and g.enf[p] then
        g.enf[p] = nil
        Send(g, { k = "stop", how = "woke" }, p)
        if LC.DreamEnforcerLeave then LC.DreamEnforcerLeave(p) end
    end
    p.lcDreamGame = nil
    if p.lcEndFrozen or (p.IsFrozen and p:IsFrozen()) then p:Freeze(false) end
    p.lcEndFrozen = nil
    if p.lcGameWatching then
        p.lcGameWatching = nil
        p:SetNW2Bool("lc_game_watching", false)
        if p.UnSpectate then p:UnSpectate() if p.Spawn then p:Spawn() end end
    end
end

-- Watching: never past the arena's edge (a little above it is fine).
hook.Add("SetupMove", "LivingCityDreamGameWatch", function(p, mv)
    if not p.lcGameWatching then return end
    local dream = LC.DreamActive
    local g = dream and dream.game
    local b = g and g.bounds
    if not b then return end
    local o = mv:GetOrigin()
    local x, y, z = math.Clamp(o.x, b.mins.x, b.maxs.x), math.Clamp(o.y, b.mins.y, b.maxs.y), math.Clamp(o.z, b.mins.z, b.maxs.z + 800)
    if x ~= o.x or y ~= o.y or z ~= o.z then
        mv:SetOrigin(Vector(x, y, z))
        mv:SetVelocity(Vector(0, 0, 0))
    end
end)

-- Back in bed with everything put back: now how the dream leaves them (sv_livingcity_vices.lua).
hook.Add("LivingCityDreamWoke", "LivingCityDreamGames", function(p)
    local r = IsValid(p) and p.lcDreamGameResult
    if not r then return end
    p.lcDreamGameResult = nil
    local def = r.id and G[r.id]
    if def and def.woke then def.woke(p, r.how) -- (a dream with its own way of leaving you: the Administrator's)
    elseif LC.DreamOutcome then LC.DreamOutcome(p, r.how, r.name) end
end)

-- The game's over: its props gone, and everyone still in it woken.
function LC.DreamGameStop(dream, why)
    local g = dream and dream.game
    if not g or g.stopped then return end
    g.stopped = true
    timer.Remove("LivingCityDreamGames")
    for p, s in pairs(g.pl) do
        if IsValid(p) and not s.done then Send(g, { k = "stop", how = why or "over" }, p) end
    end
    if IsValid(g.star) then Send(g, { k = "stop", how = why or "over" }, g.star) end
    for p in pairs(g.enf or {}) do if IsValid(p) then Send(g, { k = "stop", how = why or "over" }, p) end end
    for _, e in ipairs(g.ents) do if IsValid(e) then e:Remove() end end
    g.ents = {}
    Log("info", string.format("Dream game over: %s (%s), %d won", g.id, tostring(why or "over"), #g.won))
    if LC.DreamWake then LC.DreamWake(dream) end
end

-- A game dream counts as busy too (only one dream at a time).
-- The building blocks, for dreams written in other files (sv_livingcity_propagandadreams.lua).
LC.DreamGameKit = { Block = Block, Actor = Actor, Animate = Animate, Floor = Floor, WallAt = WallAt, Snd = Snd, Puff = Puff,
    Send = Send, InPlay = InPlay, ToStart = ToStart, Done = Done, Hit = Hit, ValidModel = ValidModel,
    PLATE8 = PLATE8, PLATE8_S = PLATE8_S, PLATE4 = PLATE4, PLATE4_S = PLATE4_S }
function LC.DreamGameBusy() return LC.DreamActive ~= nil and LC.DreamActive.game ~= nil and not LC.DreamActive.game.stopped end
