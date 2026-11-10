--[[
    Living City: The Midnight Rally (a Happy dream you play)

    The owner, 10 November: "a Mario kart esque buggy race dream".

    Everyone asleep is in a small buggy on a winding loop of road round the dream point, marked
    out with traffic cones, at night under coloured lights. Three, two, one, go.

      Driving (sh_livingcity_kart.lua): forward to go, back to brake and reverse, look where
      you want to go. The buggy only comes round so fast, so a corner taken flat out runs wide.
      Off the road (inside the cones or outside them) you crawl. You watch from behind your
      buggy (cl_livingcity_dreamrally.lua).

      The race: a number of laps, anticlockwise, worked out so the race is about the same
      length whatever the size of the dream (LC.RallyDistance; 3 laps at least). The road is
      cut into twelve stretches, and a lap only counts if you drove them in order, on the road
      or just beside it: no cutting across the middle, and no circling it.

      Pickups: glowing crates on the road. Drive through one for a pickup, one at a time; Jump
      (or attack) uses it:
        Boost         a burst of speed for a few seconds (the grass doesn't slow you while it lasts)
        Melon         dropped behind you: whoever drives over it spins out
        Horn blast    everyone near you is slowed for a few seconds

      Rival drivers: when fewer than lc_dream_min are asleep, the city's own people drive the
      other buggies (this dream brings its own stand-ins). They take the corners properly, use
      pickups now and then, spin out on melons like anyone, and ease off when they're far ahead
      of every player. They can beat you: it's a race.

      The finish: the first three buggies over the line win (they wake as from any dream you
      play that they've won: Unbroken, a second wind); the rest are told where they came. When
      the time is up the race is called. Nobody loses anything here: it's a happy dream.

    Music, if the owner puts any in sound/livingcity/dreams/: named rally; otherwise one of
    Half-Life 2's own.
]]

if CLIENT then return end

LC = LC or {}

local K, G = LC.DreamGameKit, LC.DreamGames
if not K or not G then return end
local Actor, Floor, Puff, Done = K.Actor, K.Floor, K.Puff, K.Done
local PLATE8, PLATE8_S = K.PLATE8, K.PLATE8_S
local function Snd(e, snd, lvl, pitch) if K.Snd then K.Snd(e, snd, lvl, pitch) end end

local ID = "rally"
LC.RallyDistance = 26000 -- (units of road the whole race is, about: the laps follow from the lap's length)
LC.RallySectors = 12
LC.RallyItems = { "boost", "melon", "pulse" }
LC.RallyItemNames = { boost = "BOOST", melon = "MELON", pulse = "HORN BLAST" }
local BUGGY, CONE, CRATE, MELON = "models/buggy.mdl", "models/props_junk/trafficcone001a.mdl", "models/items/item_item_crate.mdl", "models/props_junk/watermelon01.mdl"
local BUGGY_SCALE = 0.45
local COLOURS = { Color(255, 90, 90), Color(90, 170, 255), Color(120, 230, 120), Color(255, 210, 80), Color(230, 130, 255), Color(255, 150, 60),
    Color(120, 235, 235), Color(240, 240, 240) }

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end
local function Chat(g, text)
    for _, p in ipairs(LC.DreamersOf and LC.DreamersOf(g.dream) or {}) do if IsValid(p) and p.ChatPrint then p:ChatPrint(text) end end
end
local function Ordinal(n)
    local t = n % 100
    if t >= 11 and t <= 13 then return n .. "th" end
    return n .. (({ "st", "nd", "rd" })[n % 10] or "th")
end
LC.RallyOrdinal = Ordinal

local def = { id = ID, name = "The Midnight Rally", mood = "happy", secs = 200, lives = 1, ownStandins = true,
    goal = "A buggy race! Forward to go, back to brake, look where you want to go. Stay between the cones, drive through the glowing crates, and press Jump to use what you pick up.",
    timeUp = { "The flag comes down", "The race is called, and the road rolls itself up. You wake still leaning into a corner." } }
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
    LC.StrangeFallbackSongs[ID] = LC.StrangeFallbackSongs[ID] or "music/hl2_song12_long.mp3"
end

function def.woke(p, how)
    if how == "won" then
        Notice(p, "info", "On the podium", "You wake with the wind still in your hair and your hands on a wheel that isn't there.", 9)
        if LC.DreamOutcome then LC.DreamOutcome(p, "won", def.name) end
    elseif how == "time" then
        Notice(p, "info", "What a race", "You wake grinning, one foot pressing the mattress flat.", 9)
    end
end

------------------------------------------------------------------------
-- The road: a winding loop round the dream point
------------------------------------------------------------------------

-- How far from the middle the road's centre line is, at angle a.
local function RoadR(g, a) return g.R * (1 + 0.13 * math.sin(3 * a)) end
-- A spot on the road at angle a, lane units out from its centre line (minus: towards the middle).
local function RoadAt(g, a, lane)
    local r = RoadR(g, a) + (lane or 0)
    return Vector(g.c.x + math.cos(a) * r, g.c.y + math.sin(a) * r, g.top + 2)
end
-- The way the road runs at angle a (degrees), anticlockwise.
local function RoadYaw(g, a)
    local a2 = a + 0.02
    local p1, p2 = RoadAt(g, a), RoadAt(g, a2)
    return math.deg(math.atan2(p2.y - p1.y, p2.x - p1.x))
end
-- Where pos is: its angle (0 to 2 pi), how far off the centre line (plus: outside), and whether that's on the road.
local function Where(g, pos)
    local dx, dy = pos.x - g.c.x, pos.y - g.c.y
    local a = math.atan2(dy, dx)
    if a < 0 then a = a + math.pi * 2 end
    local off = math.sqrt(dx * dx + dy * dy) - RoadR(g, a)
    return a, off, math.abs(off) <= g.W / 2
end
local function Sector(a) return math.floor(a / (math.pi * 2) * LC.RallySectors) % LC.RallySectors end
LC.RallyRoadAt, LC.RallyWhere, LC.RallySector = RoadAt, Where, Sector

-- One step of the lap count: sec is the stretch they're in now. Only the next stretch counts; back over
-- the line into the last one undoes nothing. Returns true when that completed a lap.
local function Advance(s, sec)
    local N = LC.RallySectors
    if sec == (s.sec + 1) % N then
        s.sec = sec
        s.prog = s.prog + 1
        if sec == 0 then s.lap = s.lap + 1 return true end
    end
    return false
end
LC.RallyAdvance = Advance

function def.build(g, dream)
    local half = LC.DreamGameHalf(dream)
    local n = math.Clamp(math.floor(half * 2 / PLATE8_S), 3, 7)
    local c = dream.pos
    local top = c.z + 2
    local H = n * PLATE8_S / 2
    local x0, y0 = c.x - H, c.y - H
    for i = 1, n do for j = 1, n do
        local f = Floor(g, PLATE8, x0 + (i - 0.5) * PLATE8_S, y0 + (j - 0.5) * PLATE8_S, top, (i + j) % 2 == 0 and Color(38, 40, 52) or Color(46, 48, 62), "models/debug/debugwhite")
        if IsValid(f) then f.lcKeepLook = true end
    end end
    g.c, g.top, g.H = c, top, H
    g.W = math.Clamp(H * 0.4, 150, 300)                -- (the road's width)
    g.R = (H - 30 - g.W / 2) / 1.13                    -- (so its widest swing still fits on the floor)
    g.bounds = { mins = Vector(x0 - 80, y0 - 80, top - 200), maxs = Vector(x0 + n * PLATE8_S + 80, y0 + n * PLATE8_S + 80, top + 500) }
    -- the lap's length, and so the laps
    local len, last = 0, RoadAt(g, 0)
    for i = 1, 72 do
        local at = RoadAt(g, i / 72 * math.pi * 2)
        len = len + math.sqrt((at.x - last.x) ^ 2 + (at.y - last.y) ^ 2)
        last = at
    end
    g.lapLen = len
    g.laps = math.Clamp(math.ceil(LC.RallyDistance / len), 3, 12)
    -- cones down both sides, coloured lights in the middle, two posts at the line
    local cones = math.Clamp(math.floor(len / 150), 16, 44)
    for i = 0, cones - 1 do
        local a = i / cones * math.pi * 2
        for _, side in ipairs({ -1, 1 }) do
            local e = Actor(g, CONE, RoadAt(g, a, side * (g.W / 2 + 8)), math.deg(a), 1)
            if IsValid(e) then e.lcKeepLook = true end
        end
    end
    for _, side in ipairs({ -1, 1 }) do
        local e = Actor(g, "models/props_c17/signpole001.mdl", RoadAt(g, 0, side * (g.W / 2 + 14)), 0, 1)
        if IsValid(e) then e.lcKeepLook = true if e.SetColor then e:SetColor(Color(255, 255, 255)) end end
    end
    for i = 1, 3 do
        local a = math.rad(i * 120)
        local e = Actor(g, "models/props_c17/oildrum001.mdl", Vector(c.x + math.cos(a) * g.R * 0.25, c.y + math.sin(a) * g.R * 0.25, top), 0, 1)
        if IsValid(e) and e.SetColor then e:SetColor(COLOURS[i]) end
    end
    -- the crates
    g.boxes = {}
    local nb = 6
    for i = 1, nb do
        local a = (i - 0.5) / nb * math.pi * 2
        local at = RoadAt(g, a, (i % 2 == 0 and 1 or -1) * g.W * 0.2)
        local e = Actor(g, CRATE, at + Vector(0, 0, 14), 0, 0.6)
        if IsValid(e) then
            e.lcKeepLook = true
            if e.SetColor then e:SetColor(Color(255, 220, 90)) end
            if e.SetRenderFX then e:SetRenderFX(kRenderFxPulseFast or 0) end
        end
        g.boxes[i] = { pos = at, e = e, back = 0 }
    end
    g.traps, g.finish, g.bots = {}, {}, {}
    g.goAt = CurTime() + 4 -- (three, two, one)
    -- the rival drivers (this dream's own stand-ins)
    local want = (LC.DreamMin and LC.DreamMin() or 0) - #(LC.DreamersOf and LC.DreamersOf(dream) or {})
    if want > 0 and LC.DreamStandinPeople then
        local names = {}
        for i, who in ipairs(LC.DreamStandinPeople(math.min(want, 7))) do
            local a = -(0.05 + 0.045 * (i + 3))
            local lane = (i % 2 == 0 and 1 or -1) * g.W * 0.22
            local e = Actor(g, BUGGY, RoadAt(g, a, lane), RoadYaw(g, a), BUGGY_SCALE)
            if IsValid(e) then
                e.lcKeepLook, e.lcDreamStandin = true, true
                if e.SetColor then e:SetColor(COLOURS[(i + 3) % #COLOURS + 1]) end
                g.bots[#g.bots + 1] = { name = who.name, e = e, a = a, a0 = a, lane = lane, wantLane = lane, pace = math.Rand(0.76, 0.9), prog = 0, laneAt = 0 }
                names[#names + 1] = who.name
            end
        end
        if #names > 0 then Chat(g, "(in the dream) Also on the grid: " .. table.concat(names, ", ") .. ".") end
    end
    g.standins = {} -- (none of the usual kind: the drivers above are this dream's)
    return true
end

function def.spawn(g, p, i)
    local a = -(0.05 + 0.045 * math.floor((i - 1) / 2))
    local lane = ((i % 2 == 0) and 1 or -1) * g.W * 0.22
    local at, yaw = RoadAt(g, a, lane), RoadYaw(g, a)
    return at, yaw
end

-- Into a buggy (as they're placed, and again whenever the tick finds a driver without one).
local function Seat(g, p)
    local s = g.pl[p]
    if not s or s.kart then return end
    s.n = (g.seated or 0) + 1
    g.seated = s.n
    s.sec, s.prog, s.lap = LC.RallySectors - 1, 0, 0 -- (behind the line: crossing it starts lap 1)
    local e = Actor(g, BUGGY, p:GetPos(), s.yaw or 0, BUGGY_SCALE)
    if IsValid(e) then
        e.lcKeepLook = true
        if e.SetColor then e:SetColor(COLOURS[(s.n - 1) % #COLOURS + 1]) end
    end
    s.kart, s.kartYaw = e, s.yaw or 0
    p.lcKart = true
    p:SetNW2Bool("lc_kart", true)
    p:SetNW2Float("lc_kart_max", 0)
    p:SetNW2Float("lc_kart_spin", 0)
    if p.SetNoDraw then p:SetNoDraw(true) end
end
-- Out of it (finished, woken, gone).
local function Unseat(g, p)
    local s = g and g.pl and g.pl[p]
    if s and IsValid(s.kart) then s.kart:Remove() end
    if s then s.kart = nil end
    if not IsValid(p) then return end
    p.lcKart = nil
    p:SetNW2Bool("lc_kart", false)
    p:SetNW2Float("lc_kart_max", 0)
    p:SetNW2Float("lc_kart_spin", 0)
    if p.SetNoDraw then p:SetNoDraw(false) end
end
def.leave = Unseat
LC.RallySeat, LC.RallyUnseat = Seat, Unseat

def.hello = function(g) return { center = { math.floor(g.c.x), math.floor(g.c.y), math.floor(g.c.z) } } end

------------------------------------------------------------------------
-- Pickups
------------------------------------------------------------------------

-- Every buggy but this one: { pos, slow = function, spin = function, who }.
local function Others(g, me)
    local out = {}
    for p, s in pairs(g.pl) do
        if p ~= me and IsValid(p) and not s.done and s.kart then
            out[#out + 1] = { pos = p:GetPos(), who = p, slow = function(t) s.slow = t end, spin = function(t) s.spin = t p:SetNW2Float("lc_kart_spin", t) end }
        end
    end
    for _, b in ipairs(g.bots) do
        if b ~= me and IsValid(b.e) then
            out[#out + 1] = { pos = b.pos or b.e:GetPos(), who = b, slow = function(t) b.slow = t end, spin = function(t) b.spin = t end }
        end
    end
    return out
end
local function Flat(a, b) local dx, dy = a.x - b.x, a.y - b.y return math.sqrt(dx * dx + dy * dy) end

-- Use a pickup. who: a player's state or a rival driver; at: where they are; yaw: the way they're going (degrees).
local function Use(g, who, item, at, yaw, ent, now)
    if item == "boost" then
        who.boost = now + 2.5
        Snd(ent, "ambient/machines/thumper_startup1.wav", 65, 160)
    elseif item == "melon" then
        local back = Angle(0, yaw, 0):Forward() * -70
        local pos = Vector(at.x + back.x, at.y + back.y, g.top + 10)
        local e = Actor(g, MELON, pos, math.random(0, 359), 1.2)
        if IsValid(e) then e.lcKeepLook = true end
        g.traps[#g.traps + 1] = { pos = pos, e = e, arm = now + 0.6, gone = now + 45 }
        Snd(ent, "physics/flesh/flesh_squishy_impact_hard1.wav", 60, 110)
    elseif item == "pulse" then
        for _, o in ipairs(Others(g, who.bot or who.ply)) do
            if Flat(o.pos, at) < 900 then
                o.slow(now + 2.5)
                if Puff then Puff(o.pos + Vector(0, 0, 30)) end
            end
        end
        Snd(ent, "ambient/alarms/warningbell1.wav", 75, 140)
    end
    g.dirty = true
end
LC.RallyUse = Use

------------------------------------------------------------------------
-- The race
------------------------------------------------------------------------

local function Place(g) return #g.finish + 1 end
-- Where a driver is in the running now (1 is leading): by stretches driven, among everyone still racing or finished.
local function Standing(g, prog)
    local ahead = #g.finish
    for p, s in pairs(g.pl) do if IsValid(p) and not s.done and s.kart and (s.prog or 0) > prog then ahead = ahead + 1 end end
    for _, b in ipairs(g.bots) do if not b.done and b.prog > prog then ahead = ahead + 1 end end
    return ahead + 1
end
local function Field(g)
    local n = #g.bots
    for p, s in pairs(g.pl) do if IsValid(p) and (s.kart or s.place) then n = n + 1 end end
    return n
end

function def.tick(g, dt, players)
    local now = CurTime()
    local racing = now >= g.goAt
    if racing and not g.gone then
        g.gone = true
        for _, p in ipairs(players) do Snd(p, "buttons/button17.wav", 70, 120) end
    end
    local best = 0
    -- the drivers
    for _, p in ipairs(players) do
        local s = g.pl[p]
        if not s.kart then Seat(g, p) end
        local pos = p:GetPos()
        best = math.max(best, s.prog or 0)
        local a, off, on = Where(g, pos)
        s.off = not on
        -- fallen through, or flung off the floor: back on the road where they were
        if pos.z < g.top - 80 then
            local at = RoadAt(g, (s.sec + 0.5) / LC.RallySectors * math.pi * 2)
            p:SetPos(at + Vector(0, 0, 6))
            if p.SetVelocity and p.GetVelocity then p:SetVelocity(-p:GetVelocity()) end
        end
        -- (only on the road, or just beside it: circling the middle is no lap)
        if racing and math.abs(off) <= g.W / 2 + 60 and Advance(s, Sector(a)) then
            if s.lap > g.laps then
                local place = Place(g)
                g.finish[#g.finish + 1] = p:Nick()
                s.place = place
                Chat(g, "(in the dream) " .. p:Nick() .. " crosses the line, " .. Ordinal(place) .. "!")
                Unseat(g, p)
                if place <= 3 then
                    Done(g, p, "won", Ordinal(place) .. " over the line", "The flag, the lights, the cones flying past: you're on the podium.")
                else
                    Done(g, p, "time", Ordinal(place) .. " over the line", "You finished the race. Not on the podium this time, but what a drive.")
                end
            elseif s.lap > 1 then
                Snd(p, "buttons/bell1.wav", 60, 100 + s.lap * 6)
            end
            g.dirty = true
        end
        if not s.done then
            -- what they carry, and using it (Jump, or attack)
            local down = (p.KeyDown ~= nil) and ((IN_JUMP ~= nil and p:KeyDown(IN_JUMP) == true) or (IN_ATTACK ~= nil and p:KeyDown(IN_ATTACK) == true))
            if down and not s.useWas and s.item and racing then
                local item = s.item
                s.item = nil
                s.ply = p
                Use(g, s, item, pos, s.kartYaw or 0, p, now)
            end
            s.useWas = down
            -- the top speed now
            local max = racing and LCK.Base or 0
            local boosted = (s.boost or 0) > now
            if boosted then max = max * 1.5 elseif s.off then max = max * 0.45 end
            if (s.slow or 0) > now then max = max * 0.5 end
            max = math.floor(max)
            if s.max ~= max then s.max = max p:SetNW2Float("lc_kart_max", max) end
            -- their buggy, under them
            if IsValid(s.kart) then
                local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0)
                local yaw = s.kartYaw or 0
                if (s.spin or 0) > now then yaw = yaw + 900 * dt
                elseif v.x * v.x + v.y * v.y > 1600 then yaw = math.deg(math.atan2(v.y, v.x))
                elseif p.EyeAngles then yaw = p:EyeAngles().y end
                s.kartYaw = yaw
                s.kart:SetPos(pos)
                s.kart:SetAngles(Angle(0, yaw, 0))
            end
        end
    end
    -- a driver who's done (or woken) and still has a buggy
    for p, s in pairs(g.pl) do
        if s.kart and (s.done or not IsValid(p) or p.lcDreaming ~= g.dream.id) then Unseat(g, p) end
    end
    -- the rival drivers
    for _, b in ipairs(g.bots) do
        if IsValid(b.e) then
            local speed = 0
            if racing then
                speed = LCK.Base * b.pace
                if b.done then speed = LCK.Base * 0.35
                elseif b.prog > best + LC.RallySectors * 0.5 then speed = speed * 0.82 end -- (far ahead of every player: easing off)
                if (b.boost or 0) > now then speed = speed * 1.4 end
                if (b.slow or 0) > now then speed = speed * 0.5 end
                if (b.spin or 0) > now then speed = 0 end
                -- (slower through the tight parts, as a driver would be)
                speed = speed * (0.86 + 0.14 * math.abs(math.cos(1.5 * b.a)))
            end
            if now >= b.laneAt then
                b.laneAt = now + math.Rand(2, 5)
                b.wantLane = math.Rand(-0.32, 0.32) * g.W
            end
            b.lane = b.lane + math.Clamp(b.wantLane - b.lane, -60 * dt, 60 * dt)
            b.a = b.a + speed * dt / math.max(60, RoadR(g, b.a))
            b.pos = RoadAt(g, b.a, b.lane)
            b.e:SetPos(b.pos)
            b.yaw = (b.spin or 0) > now and ((b.yaw or 0) + 900 * dt) or RoadYaw(g, b.a)
            b.e:SetAngles(Angle(0, b.yaw, 0))
            local prog = math.max(0, math.floor(b.a / (math.pi * 2) * LC.RallySectors))
            if prog ~= b.prog then b.prog = prog g.dirty = true end
            if not b.done and b.a >= g.laps * math.pi * 2 then
                b.done = true
                local place = Place(g)
                g.finish[#g.finish + 1] = b.name
                Chat(g, "(in the dream) " .. b.name .. " crosses the line, " .. Ordinal(place) .. ".")
            end
        end
    end
    -- the crates: turning, picked up, back after a while
    for i, bx in ipairs(g.boxes) do
        local out = bx.back > now
        if IsValid(bx.e) then
            if bx.e.SetNoDraw then bx.e:SetNoDraw(out) end
            bx.e:SetAngles(Angle(0, (now * 90 + i * 60) % 360, 0))
        end
        if not out and racing then
            for _, p in ipairs(players) do
                local s = g.pl[p]
                if not s.done and not s.item and Flat(p:GetPos(), bx.pos) < 60 then
                    s.item = LC.RallyItems[math.random(#LC.RallyItems)]
                    bx.back = now + 5
                    Snd(p, "items/ammo_pickup.wav", 65, 110)
                    g.dirty = true
                    break
                end
            end
            if bx.back <= now then
                for _, b in ipairs(g.bots) do
                    if not b.done and b.pos and Flat(b.pos, bx.pos) < 60 then
                        bx.back = now + 5
                        if math.random() < 0.5 then
                            b.bot = b
                            Use(g, b, math.random() < 0.6 and "boost" or "melon", b.pos, b.yaw or 0, b.e, now)
                        end
                        break
                    end
                end
            end
        end
    end
    -- the melons on the road
    for i = #g.traps, 1, -1 do
        local t = g.traps[i]
        local hit
        if now >= t.arm then
            for _, o in ipairs(Others(g, nil)) do
                if Flat(o.pos, t.pos) < 46 then hit = o break end
            end
        end
        if hit or now >= t.gone then
            if hit then
                hit.spin(now + 1.3)
                if Puff then Puff(t.pos + Vector(0, 0, 20)) end
                if IsValid(t.e) then Snd(t.e, "physics/flesh/flesh_squishy_impact_hard2.wav", 70, 100) end
            end
            if IsValid(t.e) then t.e:Remove() end
            table.remove(g.traps, i)
        end
    end
end

function def.state(g, p)
    local s = p and g.pl[p] or {}
    local now = CurTime()
    local big, tone
    local left = g.goAt - now
    if left > 0 then big = left > 3 and "On the grid..." or tostring(math.ceil(left)) tone = "warn"
    elseif left > -1.2 then big = "GO!"
    elseif (s.spin or 0) > now then big = "Spinning out!" tone = "warn"
    elseif (s.slow or 0) > now then big = "Slowed!" tone = "warn" end
    local lap = math.Clamp(s.lap or 0, 1, g.laps)
    local bits = { string.format("Lap %d of %d", lap, g.laps), Ordinal(Standing(g, s.prog or 0)) .. " of " .. Field(g) }
    if s.item then bits[#bits + 1] = "Carrying: " .. (LC.RallyItemNames[s.item] or s.item) .. " (Jump to use)" end
    if s.off and left <= 0 and (s.boost or 0) <= now then bits[#bits + 1] = "off the road" end
    return { big = big, tone = tone, meter = math.floor(math.Clamp((s.prog or 0) / (g.laps * LC.RallySectors), 0, 1) * 100), meterName = table.concat(bits, "   ") }
end
