--[[
    Living City: The Fitness Test (a Happy dream you play)

    The owner, 12 November: "a new dream, an airboat race or an obstacle course". (A race
    already has its dream, The Midnight Rally: this one is the obstacle course.)

    The Fitness Test (course, Happy). The city's morning exercise, as a dream: a course of
    floor tiles snaking back and forth over a drop at the dream point, built from plain props,
    a drill officer at the start. Over the hurdles (jump), across the stepping stones (jump from
    one to the next; miss and you fall), past the giant stun batons sweeping round at ankle
    height (jump them as they come), from flag to flag, to the gold tile at the end.

      Falling, or swept off your feet by a baton: back to the last green flag you reached (the
      start, before the first). No lives are lost: it's a happy dream, and it costs nothing.
      Everyone who reaches the gold tile passes (they wake as from any dream you play that
      they've won: Unbroken, a second wind); the first three are told their place. When the
      time is up, the whistle blows and the rest wake.

      The course is laid out to fit the dream zone: as many tiles to a row as fit, the rows
      joined by short bridges at the ends, a two-tile drop between rows so nobody jumps
      across. Unseen in game yet: the baton's model turned flat (its length along its own x),
      and how far a running jump carries between the stones (they're a tile apart).

    Music, if the owner puts any in sound/livingcity/dreams/: named course (or a dreams/course/
    folder); otherwise one of Half-Life 2's own.
]]

if CLIENT then return end

LC = LC or {}

local K, G = LC.DreamGameKit, LC.DreamGames
if not K or not G then return end
local Block, Actor, Animate, Floor, Puff, Done, ToStart = K.Block, K.Actor, K.Animate, K.Floor, K.Puff, K.Done, K.ToStart
local function Snd(e, snd, lvl, pitch) if K.Snd then K.Snd(e, snd, lvl, pitch) end end
local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end

local ID = "course"
LC.CourseTile = 189.8         -- (one tile: a 4x4 plate)
LC.CourseSweepRadius = 82     -- (a baton's reach from its pivot)
LC.CourseSweepSpeed = 150     -- (degrees a second)
LC.CourseFall = 120           -- (this far below the course: fallen)
-- The course, start to finish (bridges between rows are added as it's laid out).
LC.CourseLayout = { "start", "plain", "hurdle", "plain", "hurdle", "hurdle", "flag", "stone", "stone", "stone", "plain",
    "flag", "sweep", "plain", "sweep", "sweep", "flag", "hurdle", "stone", "stone", "hurdle", "sweep", "plain", "finish" }

local PLATE4 = K.PLATE4 or "models/hunter/plates/plate4x4.mdl"
local STONE = "models/hunter/plates/plate2x2.mdl"
local BARS = { "models/hunter/blocks/cube025x4x025.mdl", "models/hunter/blocks/cube025x2x025.mdl", "models/hunter/plates/plate025x4.mdl" }
local BATON = "models/weapons/w_stunbaton.mdl"
local COP = "models/police.mdl"
local GREY, BLUE, GREEN, GOLD, RED = Color(70, 72, 80), Color(70, 100, 150), Color(70, 170, 90), Color(230, 190, 60), Color(170, 50, 40)
local WHITE = "models/debug/debugwhite"
local CHEERS = { "vo/npc/male01/yeah02.wav", "vo/npc/female01/yeah02.wav", "vo/npc/male01/nice.wav", "vo/npc/female01/nice.wav" }

local function FirstModel(list)
    for _, m in ipairs(list) do if not K.ValidModel or K.ValidModel(m) then return m end end
    return list[#list]
end

local def = { id = ID, name = "The Fitness Test", mood = "happy", secs = 180, lives = 1,
    goal = "The city's fitness test! Jump the hurdles, hop across the stepping stones, jump the batons as they sweep round, and reach the gold tile. Fall or get swept and you're back at the last green flag.",
    timeUp = { "The whistle blows", "Time's up. You wake with your legs still running." } }
G[ID] = def
do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == ID then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = ID end
    if LC.PropagandaSongWords then
        local had = false
        for _, w in ipairs(LC.PropagandaSongWords) do if w == ID then had = true end end
        if not had then LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = ID end
    end
    LC.StrangeFallbackSongs = LC.StrangeFallbackSongs or {}
    LC.StrangeFallbackSongs[ID] = LC.StrangeFallbackSongs[ID] or "music/hl2_song4.mp3"
end

-- Where each tile goes: { kind, col, row, dir } in order, snaking. cols: tiles to a row.
function LC.CourseLay(cols, layout)
    layout = layout or LC.CourseLayout
    cols = math.max(3, cols)
    local out = {}
    local col, row, dir = 0, 0, 1
    for i, kind in ipairs(layout) do
        out[#out + 1] = { kind = kind, col = col, row = row, dir = { dir, 0 } }
        if i == #layout then break end
        if col + dir >= 0 and col + dir <= cols - 1 then
            col = col + dir
        else
            -- the end of a row: a bridge over the drop to the next row, and back the other way
            out[#out + 1] = { kind = "bridge", col = col, row = row + 1, dir = { 0, 1 } }
            out[#out + 1] = { kind = "bridge", col = col, row = row + 2, dir = { 0, 1 } }
            row, dir = row + 3, -dir
        end
    end
    return out
end

function def.build(g, dream)
    local T = LC.CourseTile
    local half = LC.DreamGameHalf and LC.DreamGameHalf(dream) or 1000
    local cols = math.Clamp(math.floor((2 * half - 40) / T), 4, 14)
    local tiles = LC.CourseLay(cols)
    local rows = 0
    for _, t in ipairs(tiles) do rows = math.max(rows, t.row + 1) end
    local c = dream.pos
    local base = c.z + 2
    g.base, g.T = base, T
    local function At(col, row) return Vector(c.x + (col - (cols - 1) / 2) * T, c.y + (row - (rows - 1) / 2) * T, base) end
    local bar = FirstModel(BARS)
    g.tiles, g.sweeps, g.flags = {}, {}, {}
    for i, t in ipairs(tiles) do
        local at = At(t.col, t.row)
        t.pos, t.i = at, i
        if t.kind == "stone" then
            -- a small stone in the middle of an empty tile, nudged to one side or the other
            local side = (i % 2 == 0) and 1 or -1
            local off = Vector(t.dir[2] * side * 30, t.dir[1] * side * 30, 0)
            t.stone = at + off
            Floor(g, STONE, t.stone.x, t.stone.y, base, BLUE, WHITE)
        else
            local col = (t.kind == "flag" and GREEN) or (t.kind == "finish" and GOLD) or (t.kind == "start" and GREY) or (t.kind == "bridge" and GREY) or BLUE
            Floor(g, PLATE4, at.x, at.y, base, col, WHITE)
        end
        if t.kind == "hurdle" then
            -- a bar across the way, low enough to jump and too low to crawl under
            local e = Block(g, bar, at + Vector(0, 0, 22), Angle(0, 0, 0), RED, WHITE)
            if IsValid(e) then
                -- (whichever way the model lies, its long side across the way)
                local mins, maxs = e:OBBMins(), e:OBBMaxs()
                local longX = (maxs.x - mins.x) > (maxs.y - mins.y)
                local acrossY = t.dir[1] ~= 0 -- (going along x: the bar lies along y)
                if longX == acrossY then e:SetAngles(Angle(0, 90, 0)) end
            end
        elseif t.kind == "sweep" then
            local e = Actor(g, BATON, at + Vector(0, 0, 16), 0, LC.CourseSweepRadius * 2 / 22)
            g.sweeps[#g.sweeps + 1] = { e = e, pivot = at, ang = (i * 77) % 360, dir = (i % 2 == 0) and 1 or -1 }
        elseif t.kind == "flag" then
            g.flags[#g.flags + 1] = i
        elseif t.kind == "start" then
            g.officer = Actor(g, COP, at + Vector(-t.dir[1] * T * 0.35, T * 0.4, 0), t.dir[1] > 0 and 0 or 180, 1, ACT_IDLE or 1)
        elseif t.kind == "finish" then
            g.finishAt = at
        end
        g.tiles[i] = t
    end
    g.startAt = tiles[1].pos
    g.passed = 0
    local lo, hi = At(0, 0), At(cols - 1, rows - 1)
    g.bounds = { mins = Vector(math.min(lo.x, hi.x) - T, math.min(lo.y, hi.y) - T, base - 400), maxs = Vector(math.max(lo.x, hi.x) + T, math.max(lo.y, hi.y) + T, base + 600) }
    g.starts = {}
    for k = 0, 7 do g.starts[#g.starts + 1] = g.startAt + Vector(-50 + (k % 4) * 33, -60 + math.floor(k / 4) * 60, 4) end
    if IsValid(g.officer) then Snd(g.officer, "ambient/alarms/warningbell1.wav", 80, 110) end
    return true
end

function def.spawn(g, p, i) return g.starts[((i - 1) % #g.starts) + 1], 0 end

-- The tile under a spot (its index), or nil.
local function TileAt(g, pos)
    local h = g.T / 2 + 4
    for i, t in ipairs(g.tiles) do
        local at = t.stone or t.pos
        local r = t.stone and (47.45 + 4) or h
        if math.abs(pos.x - at.x) <= r and math.abs(pos.y - at.y) <= r then return i end
    end
    return nil
end
LC.CourseTileAt = TileAt

-- Is a spot in a baton's way right now (on the floor, not jumping over it)?
local function Swept(g, pos)
    if pos.z > g.base + 34 then return false end
    for _, s in ipairs(g.sweeps) do
        local dx, dy = pos.x - s.pivot.x, pos.y - s.pivot.y
        if dx * dx + dy * dy <= (LC.CourseSweepRadius + 16) ^ 2 then
            for _, add in ipairs({ 0, 180 }) do
                local a = math.rad(s.ang + add)
                local ux, uy = math.cos(a), math.sin(a)
                local along = dx * ux + dy * uy
                local px, py = dx - along * ux, dy - along * uy
                if along > 0 and along < LC.CourseSweepRadius + 16 and px * px + py * py < 24 * 24 then return true end
            end
        end
    end
    return false
end
LC.CourseSwept = Swept

local function Ordinal(n) return n .. (({ "st", "nd", "rd" })[n] or "th") end

function def.tick(g, dt, players)
    -- the batons sweep round
    for _, s in ipairs(g.sweeps) do
        s.ang = (s.ang + s.dir * LC.CourseSweepSpeed * dt) % 360
        if IsValid(s.e) then s.e:SetAngles(Angle(0, s.ang, 0)) end
    end
    for _, p in ipairs(players) do
        local st = g.pl[p]
        local pos = p:GetPos()
        st.far = st.far or 1
        if pos.z < g.base - LC.CourseFall then
            Notice(p, "info", "Splash... no, thud", "You fell. Back to the last green flag.", 3)
            ToStart(g, p, 1)
        elseif CurTime() >= (st.safe or 0) and Swept(g, pos) then
            Snd(p, "physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 70)
            Notice(p, "info", "Swept off your feet", "Jump the baton as it comes round. Back to the last green flag.", 3)
            ToStart(g, p, 1.5)
        else
            local i = TileAt(g, pos)
            if i and pos.z > g.base - 20 then
                if i > st.far then st.far = i g.dirty = true end
                local t = g.tiles[i]
                if t.kind == "flag" and i > (st.flag or 0) then
                    st.flag = i
                    st.start = t.pos + Vector(0, 0, 4)
                    local n = 0
                    for k, f in ipairs(g.flags) do if f == i then n = k end end
                    Snd(p, "buttons/bell1.wav", 60, 110)
                    Notice(p, "info", string.format("Flag %d of %d", n, #g.flags), "If you fall now, you start again from here.", 3)
                elseif t.kind == "finish" then
                    g.passed = g.passed + 1
                    local place = g.passed
                    Snd(p, CHEERS[math.random(#CHEERS)], 70)
                    if IsValid(g.officer) then Animate(g.officer, ACT_IDLE or 1) end
                    Done(g, p, "won", "Fitness test passed", place <= 3 and ("You came in " .. Ordinal(place) .. ". The officer actually smiles.")
                        or "You made it to the end. The officer ticks your name off.")
                end
            end
        end
    end
end

function def.state(g, p)
    local st = p and g.pl[p]
    local n = 0
    for k, f in ipairs(g.flags) do if st and (st.flag or 0) >= f then n = k end end
    return { prog = st and st.far or 1, of = #g.tiles, passed = g.passed,
        meterName = string.format("Flags: %d of %d", n, #g.flags) .. (g.passed > 0 and string.format("   Passed: %d", g.passed) or "") }
end
