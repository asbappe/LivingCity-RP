--[[
    Living City: Pick Up That Can, a fever dream

      The owner, 13 November: "a fever dream nonsensical dream called 'Pick up that can', and it
      revolves entirely around the metrocop interaction in HL2 where it knocks the can off the bin
      with its stunstick saying 'pick up that can'. It should play out just like in HL2, and every
      player has their own client side can prop that they pick up, and when they do pick it up, they
      either throw it at the metrocop, put it in the bin, or throw the can elsewhere; all 3 actions
      have different fever-dream-esque responses for all the players in the dream. One of them should
      be the can grows to full size and becomes a living can that swaps roles with the metrocop, and
      the can uses its stunstick to knock a tiny metrocop off the bin and says 'pick up that can',
      but every player that triggers this causes a new clone of the little set to appear next to it."

      Pick Up That Can (can, Neutral). An officer and a bin in the middle of a bare floor. He knocks
      a can off the bin with his stunstick: "Pick up that can." Everyone has a can of their own (only
      you see yours: cl_livingcity_candream.lua draws it). Use it to pick it up, left click to throw:

        At him: the can grows as tall as a man, comes alive and takes his stunstick, and the officer
          shrinks and climbs onto the bin. The can knocks him off: "Pick up that can." From then on
          what you pick up is a tiny officer. Every hit after that (on any officer or any living can)
          puts another living can, bin and tiny officer next to the first, each knocking its own
          officer off its own bin, up to LC.CanMaxSets (30) of them. The tiny officers squeak threats
          and orders, Half-Life 2's own lines pitched as high as they go (LC.CanTinyLines; yours, on
          your own screen: LC_CL.CanTinyLines).
        In the bin (any bin): he chuckles, the bin says thank you, burps and grows, and it rains cans
          on everyone.
        Anywhere else: where it lands a can tree grows, in every colour, and he grows taller and
          slower every time. "Pick. Up. That. Can."

      Whatever you do, another can is put on the bin and knocked off for you. Try all three before
      the time is up and you wake Unbroken (LC.DreamOutcome); otherwise it costs nothing.
      Half-Life 2's own recordings are used for his lines until the owner records theirs
      (VOICE_LINES.md). Unseen in game yet: the swing, the sizes, where the stick sits on the can.
]]

if CLIENT then return end

LC = LC or {}

local K, S, S2, G = LC.DreamGameKit, LC.StrangeKit, LC.StrangeKit2, LC.DreamGames
if not K or not S or not S2 or not G then return end
local Block, Actor, Animate, Puff, Done = K.Block, K.Actor, K.Animate, K.Puff, K.Done
local Woke, Plain, Ring, SpawnAt, Flat, Dist2, FirstModel, Rainbow, SayAs = S.Woke, S.Plain, S.Ring, S.SpawnAt, S.Flat, S.Dist2, S.FirstModel, S.Rainbow, S.SayAs
local Pressed = S2.Pressed or LC.StrangePressed
local KEY_ATTACK, KEY_USE = IN_ATTACK or 1, IN_USE or 32
local function Snd(e, snd, lvl, pitch) K.Snd(e, snd, lvl, math.Clamp(math.floor(pitch or 100), 30, 255)) end -- (never warped: his pitch means something here)

LC.StrangeDreams4 = { "can" }
if LC.StrangeAll and next(LC.StrangeAll) ~= nil then LC.StrangeAll.can = true end -- (else LC.StrangeIs gathers it: sv_livingcity_strangedreams.lua)
do
    local have = false
    for _, o in ipairs(LC.DreamGameOrder) do if o == "can" then have = true end end
    if not have then LC.DreamGameOrder[#LC.DreamGameOrder + 1] = "can" end
    if LC.PropagandaSongWords then
        local w = false
        for _, x in ipairs(LC.PropagandaSongWords) do if x == "can" then w = true end end
        if not w then LC.PropagandaSongWords[#LC.PropagandaSongWords + 1] = "can" end
    end
    LC.StrangeFallbackSongs.can = LC.StrangeFallbackSongs.can or "music/hl2_song27_trainstation2.mp3"
end

LC.CanMaxSets = 30   -- (living cans with their bins and tiny officers, the first one included)
LC.CanMaxTrees = 30  -- (can trees; after that the oldest moves)
LC.CanReach = 90     -- (how near the can you must be to pick it up)
LC.CanTall = 72      -- (a living can: as tall as a man)
LC.CanTiny = 0.22    -- (a tiny officer)
LC.CanCopMax, LC.CanBinMax = 4, 3 -- (how big he, and the bin, can get)
LC.CanBack = 3       -- (seconds until the next can is on the bin for you)
LC.CanCycle = 5      -- (seconds between a living can's swings)

local COP, CAN, STICK = "models/police.mdl", "models/props_junk/popcan01a.mdl", "models/weapons/w_stunbaton.mdl"
local BINS = { "models/props_trainstation/trashcan_indoor001b.mdl", "models/props_trainstation/trashcan_indoor001a.mdl", "models/props_junk/trashbin01a.mdl" }
local PICKUP = { "npc/metropolice/vo/pickupthecan1.wav", "npc/metropolice/vo/pickupthecan2.wav", "npc/metropolice/vo/pickupthecan3.wav" }
local TRASH = { "npc/metropolice/vo/putitinthetrash1.wav", "npc/metropolice/vo/putitinthetrash2.wav" }
local CHUCKLE = "npc/metropolice/vo/chuckle.wav"
-- What a tiny officer squeaks from the floor (the owner, 13 November: "super high pitch shifted voice lines coming from
-- the tiny officer: threats, commands"): Half-Life 2's own, as high as they go. Your own one's are in cl_livingcity_candream.lua.
LC.CanTinyPitch = 240
LC.CanTinyChance = 0.6 -- (how often one of the living cans' officers has something to say about it, each time it's knocked off)
LC.CanTinyLines = { "npc/metropolice/vo/holdit.wav", "npc/metropolice/vo/holditrightthere.wav", "npc/metropolice/vo/dontmove.wav", "npc/metropolice/vo/stopthere.wav",
    "npc/metropolice/vo/firstwarningmove.wav", "npc/metropolice/vo/secondwarning.wav", "npc/metropolice/vo/finalwarning.wav", "npc/metropolice/vo/getdown.wav",
    "npc/metropolice/vo/prepareforjudgement.wav", "npc/metropolice/vo/youwantamalcomplianceverdict.wav", "npc/metropolice/vo/movealong.wav", "npc/metropolice/vo/moveit.wav",
    "npc/metropolice/vo/keepmoving.wav", "npc/metropolice/vo/finalverdictadministered.wav", "npc/metropolice/vo/citizen.wav", "npc/metropolice/vo/allunitsrespondcode3.wav" }

-- How tall a thing is, and how far its feet are below where it is (at scale 1).
local function Tall(e)
    if not (IsValid(e) and e.OBBMaxs and e.OBBMins) then return 40, 0 end
    local lo, hi = e:OBBMins(), e:OBBMaxs()
    return math.max(1, hi.z - lo.z), -lo.z
end
-- Standing on the floor (or on z), whatever its size.
local function Stand(e, x, y, z, scale)
    if not IsValid(e) then return end
    local _, feet = Tall(e)
    e:SetPos(Vector(x, y, z + feet * (scale or 1)))
end
local function Scale(e, s) if IsValid(e) and e.SetModelScale then e:SetModelScale(s) e.lcCanScale = s end end

-- One line on everyone's screen, with Half-Life 2's own recording from whoever says it unless the
-- owner recorded that line; never the same line twice within a few seconds (thirty dreamers at once).
local function Say(g, cue, from, snd, pitch, gap)
    local now = CurTime()
    g.saidAt = g.saidAt or {}
    if now < (g.saidAt[cue] or 0) then return false end
    g.saidAt[cue] = now + (gap or 4)
    local own = LC.PropagandaVoice and LC.PropagandaVoice(cue)
    if snd and not own then Snd(from, snd, 80, pitch) end
    SayAs(g, cue)
    return true
end

-- The first of them: the one in the middle.
local function Main(g) return g.sets[1] end
function LC.CanBinTop(g, set)
    set = set or Main(g)
    local tall = Tall(set.bin)
    return Vector(set.binAt.x, set.binAt.y, g.top + tall * (set.binScale or 1) + 2)
end
-- Where your can lands when it's knocked off: on the floor between the bin and where you started.
function LC.CanSpot(g, p)
    local s, at = g.pl[p], Main(g).binAt
    local to = s and s.start or (at + Vector(60, 0, 0))
    local dx, dy = to.x - at.x, to.y - at.y
    local l = math.max(1, math.sqrt(dx * dx + dy * dy))
    local r = 55 + 20 * (Main(g).binScale or 1)
    return Vector(at.x + dx / l * r, at.y + dy / l * r, g.top + 3)
end

-- Where the living cans go: beside the first, then round it, nearest first.
local function Slots(g)
    local c, out = g.dream.pos, {}
    local step, room = 100, g.half - 70
    for i = -4, 4 do for j = -4, 4 do
        if not (i == 0 and j == 0) and math.abs(i * step) <= room and math.abs(j * step) <= room then
            out[#out + 1] = { x = c.x + i * step, y = c.y + j * step, d = i * i + j * j + (j ~= 0 and 0.5 or 0) + (i < 0 and 0.1 or 0) + (j < 0 and 0.05 or 0) }
        end
    end end
    table.sort(out, function(a, b) return a.d < b.d end)
    return out
end

-- A living can with a stunstick, where the officer was (or at a new spot); it grows in from nothing much.
local function LivingCan(g, set)
    local e = Actor(g, CAN, Vector(set.o.x, set.o.y, g.top), set.yaw, 1, nil)
    if IsValid(e) then
        e.lcKeepLook = true
        local tall = Tall(e)
        set.canScale = LC.CanTall / tall
    end
    set.can, set.canScale = e, set.canScale or 10
    set.stick = Actor(g, STICK, Vector(set.o.x, set.o.y, g.top + 40), set.yaw, 2.2, nil)
    if IsValid(set.stick) then set.stick.lcKeepLook = true end
    set.born = CurTime()
    return e
end

-- Another living can, bin and tiny officer, next to the others. False: there's no room left.
function LC.CanAddSet(g)
    if #g.sets >= LC.CanMaxSets then return false end
    local slot = g.slots[#g.sets]
    if not slot then return false end
    local set = { o = Vector(slot.x - 28, slot.y, g.top), binAt = Vector(slot.x + 28, slot.y, g.top), yaw = 0, swapped = true, binScale = 1, grow = 1, n = #g.sets + 1 }
    set.bin = Actor(g, g.binModel, set.binAt, 0, 1, nil) -- (not solid: nobody gets walled in by thirty bins)
    Stand(set.bin, set.binAt.x, set.binAt.y, g.top, 1)
    if IsValid(set.bin) then set.bin.lcKeepLook = true end
    LivingCan(g, set)
    set.tiny = Actor(g, COP, LC.CanBinTop(g, set), 180, LC.CanTiny, ACT_IDLE)
    if IsValid(set.tiny) then set.tiny.lcKeepLook = true end
    set.phase = math.Rand(0, LC.CanCycle)
    g.sets[#g.sets + 1] = set
    Puff(Vector(slot.x, slot.y, g.top + 30))
    g.dirty = true
    return true
end

-- The first hit: the can grows, comes alive and takes the stunstick; the officer shrinks onto the bin.
function LC.CanSwap(g)
    local m = Main(g)
    if m.swapped then return false end
    m.swapped, g.swapped = true, CurTime()
    m.tiny, m.cop = m.cop, nil
    LivingCan(g, m)
    m.grow = 1 + ((m.grow or 1) - 1) * 0.5 -- (what he'd grown, the can keeps half of)
    Puff(Vector(m.o.x, m.o.y, g.top + 40))
    g.dirty = true
    return true
end

-- Whatever you threw, wherever: what it hit. "cop" (an officer or a living can), "bin", or "away"; and where it ends up.
function LC.CanAim(g, p)
    local eye = p.EyePos and p:EyePos() or (p:GetPos() + Vector(0, 0, 64))
    local a = p.GetAimVector and p:GetAimVector() or Vector(1, 0, 0)
    local best, bestT, bestAt, bestSet
    local function Try(what, at, r, set)
        local dx, dy, dz = at.x - eye.x, at.y - eye.y, at.z - eye.z
        local t = dx * a.x + dy * a.y + dz * a.z
        if t <= 0 or t > 1400 then return end
        local px, py, pz = dx - a.x * t, dy - a.y * t, dz - a.z * t
        if px * px + py * py + pz * pz > r * r then return end
        if not bestT or t < bestT then best, bestT, bestAt, bestSet = what, t, at, set end
    end
    local pos = p:GetPos()
    for _, set in ipairs(g.sets) do
        local top = LC.CanBinTop(g, set)
        if a.z < -0.25 and Dist2(pos, set.binAt) < 70 + 20 * (set.binScale or 1) then return "bin", top, set end -- (standing over it: dropped in)
        Try("bin", top, 24 * (set.binScale or 1), set)
        local grow = set.grow or 1
        if set.swapped then Try("cop", Vector(set.o.x, set.o.y, g.top + LC.CanTall * grow / 2), 34 * grow, set)
        else
            Try("cop", Vector(set.o.x, set.o.y, g.top + 52 * grow), 22 * grow, set)
            Try("cop", Vector(set.o.x, set.o.y, g.top + 22 * grow), 20 * grow, set)
        end
    end
    if best then return best, bestAt, bestSet end
    -- anywhere else: where it comes down
    local t = 420
    if a.z < -0.05 then t = math.min(700, (eye.z - g.top) / -a.z) end
    local c, h = g.dream.pos, g.half - 30
    return "away", Vector(math.Clamp(eye.x + a.x * t, c.x - h, c.x + h), math.Clamp(eye.y + a.y * t, c.y - h, c.y + h), g.top + 3), nil
end

-- A can tree where it landed (the oldest moves when there are enough).
local function Tree(g, at)
    g.trees = g.trees or {}
    local t
    if #g.trees >= LC.CanMaxTrees then
        t = table.remove(g.trees, 1)
    else
        t = { ent = Actor(g, CAN, at, math.random(0, 359), 1, nil) }
        if IsValid(t.ent) then t.ent.lcKeepLook = true end
    end
    t.at, t.born, t.size = at, CurTime(), math.Rand(2.5, 7)
    if IsValid(t.ent) then t.ent:SetColor(Rainbow(math.random())) end
    g.trees[#g.trees + 1] = t
end

local NOTES = {
    cop = { "Right between the eyes.", "It didn't like that. It liked that." },
    bin = { "In the bin. Good citizen.", "The bin says thank you." },
    away = { "That is not the bin.", "Littering. He felt that." },
}

-- What you did with it, and what the dream does about it, for everyone.
function LC.CanThrown(g, p, what, at, set)
    local s = g.pl[p]
    if not s then return end
    local now = CurTime()
    local m = Main(g)
    s.did = s.did or {}
    s.did[what] = (s.did[what] or 0) + 1
    g.count = g.count or { cop = 0, bin = 0, away = 0 }
    g.count[what] = g.count[what] + 1
    local n = g.count[what]
    s.can = { st = "fly", at = now, to = at, kind = s.can and s.can.kind or "can", what = what, next = now + LC.CanBack }
    s.note, s.noteTil = NOTES[what][math.min(2, s.did[what])], now + 4
    if what == "cop" then
        set = set or m
        local from = set.can or set.cop or m.bin
        Snd(from, "physics/metal/soda_can_impact_hard" .. math.random(1, 3) .. ".wav", 80, 100)
        Snd(from, "weapons/stunstick/spark" .. math.random(1, 3) .. ".wav", 75, 100)
        if not m.swapped then
            Snd(m.cop, "npc/metropolice/pain" .. math.random(1, 4) .. ".wav", 80, 100)
            LC.CanSwap(g)
            Say(g, "can_swap", m.can, PICKUP[1], 160, 6)
        elseif LC.CanAddSet(g) then
            Say(g, "can_clone", g.sets[#g.sets].can, PICKUP[2], 170, 5)
        else
            Say(g, "can_full", m.can, CHUCKLE, 160, 8)
        end
    elseif what == "bin" then
        set = set or m
        set.binned = (set.binned or 0) + 1
        set.binScale = math.min(LC.CanBinMax, 1 + 0.12 * set.binned)
        Scale(set.bin, set.binScale)
        Stand(set.bin, set.binAt.x, set.binAt.y, g.top, set.binScale)
        Snd(set.bin, "npc/barnacle/barnacle_gulp" .. math.random(1, 2) .. ".wav", 80, 70)
        g.rain = now -- (it rains cans on everyone: cl_livingcity_candream.lua)
        Snd(m.cop or m.can, CHUCKLE, 75, m.swapped and 160 or 100)
        Say(g, "can_bin", set.bin, nil, nil, 6)
    else
        Tree(g, at)
        m.grow = math.min(LC.CanCopMax, (m.grow or 1) + 0.15)
        Snd(p, "physics/metal/soda_can_impact_soft" .. math.random(1, 3) .. ".wav", 70, 100)
        Say(g, n % 3 == 1 and "can_litter" or "can_again", m.cop or m.can, PICKUP[2 + n % 2], (m.swapped and 160 or 100) / math.sqrt(m.grow), 5)
    end
    g.dirty = true
end

do
    local def = { id = "can", name = "Pick Up That Can", mood = "neutral", secs = 150, lives = 1,
        goal = "Pick up that can. Use it to pick it up, left click to throw it. Then try something else with the next one.",
        timeUp = { "The can rolls away", "It rolls off somewhere you can't follow, and you wake." },
        woke = Woke({ name = "Pick Up That Can",
            won = { "Every which way", "You wake up having done everything that can be done with a can. You feel oddly complete." },
            out = { "Pick it up", "You wake up and look for a can to pick up. There is no can." },
            time = { "The can rolls away", "You wake up sure you dropped something. You check the floor twice." },
        }) }
    G.can = def

    function def.build(g, dream)
        Plain(g, dream, 3, function(i, j) return (i + j) % 2 == 0 and Color(150, 150, 140) or Color(120, 120, 112) end)
        local c = dream.pos
        g.binModel = FirstModel(BINS)
        local m = { o = Vector(c.x - 28, c.y, g.top), binAt = Vector(c.x + 28, c.y, g.top), yaw = 0, binScale = 1, grow = 1, main = true, n = 1 }
        m.bin = Block(g, g.binModel, m.binAt, Angle(0, 0, 0))
        Stand(m.bin, m.binAt.x, m.binAt.y, g.top, 1)
        if IsValid(m.bin) then m.bin.lcKeepLook = true end
        m.cop = Actor(g, COP, m.o, 0, 1, ACT_IDLE)
        if IsValid(m.cop) then m.cop.lcKeepLook = true end
        g.sets = { m }
        g.slots = Slots(g)
        g.count = { cop = 0, bin = 0, away = 0 }
        Ring(g, math.min(230, g.half * 0.6))
        return true
    end
    def.spawn = SpawnAt
    def.hello = function() return { theme = "can" } end

    -- The officer (or the first living can) swings the stunstick at the bin.
    local function Swing(g)
        local now = CurTime()
        local m = Main(g)
        if now < (g.swungAt or 0) + 0.8 then return end
        g.swungAt = now
        if IsValid(m.cop) then
            Animate(m.cop, ACT_MELEE_ATTACK1, "swing")
            g.idleAt = now + 1.2
        end
        Snd(m.cop or m.can, "weapons/stunstick/stunstick_swing" .. math.random(1, 2) .. ".wav", 75, 100)
        Snd(m.bin, "physics/metal/soda_can_impact_hard" .. math.random(1, 3) .. ".wav", 70, 100)
        Say(g, m.swapped and "can_swap" or "can_hello", m.cop or m.can, PICKUP[1], (m.swapped and 160 or 100) / math.sqrt(m.grow or 1), 5)
    end

    -- The living cans: wobbling, swinging, and knocking their tiny officers off their bins.
    local function Sets(g, now)
        for i, set in ipairs(g.sets) do
            local grow = set.grow or 1
            if set.swapped then
                local age = now - (set.born or now)
                local in01 = math.Clamp(age / 1.2, 0.05, 1)
                local sc = (set.canScale or 10) * grow * in01
                if IsValid(set.can) then
                    Scale(set.can, sc)
                    local hop = math.abs(math.sin(now * 3 + i)) * 5
                    Stand(set.can, set.o.x, set.o.y, g.top + hop, sc)
                    set.can:SetAngles(Angle(math.sin(now * 2.3 + i) * 7, set.yaw + math.sin(now * 0.7 + i) * 20, math.cos(now * 1.9 + i) * 7))
                end
                local t = set.main and (now - (g.swungAt or -10)) or ((now + (set.phase or 0)) % LC.CanCycle)
                local swing = t < 0.5 and math.sin(t / 0.5 * math.pi) or 0
                if IsValid(set.stick) then
                    set.stick:SetPos(Vector(set.o.x + 16 * grow, set.o.y - 20 * grow, g.top + LC.CanTall * grow * in01 * 0.6))
                    set.stick:SetAngles(Angle(-60 + swing * 110, set.yaw, 0))
                end
                if IsValid(set.tiny) then
                    local top = LC.CanBinTop(g, set)
                    if set.main then
                        -- the first officer: shrinking onto the bin, then gone (every dreamer has their own to pick up)
                        local k = math.Clamp(age / 1.2, 0, 1)
                        Scale(set.tiny, 1 + (LC.CanTiny - 1) * k)
                        set.tiny:SetPos(Vector(set.o.x + (top.x - set.o.x) * k, set.o.y + (top.y - set.o.y) * k, g.top + (top.z - g.top) * k + math.sin(k * math.pi) * 30))
                        if k >= 1 and not set.hid then set.hid = true if set.tiny.SetNoDraw then set.tiny:SetNoDraw(true) end end
                    else
                        local cyc = math.floor((now + (set.phase or 0)) / LC.CanCycle)
                        if t >= 0.25 and set.cyc ~= cyc then -- (knocked off)
                            set.cyc = cyc
                            Snd(set.can, PICKUP[1 + (i % 3)], 62, 130 + (i * 17) % 90)
                            Snd(set.tiny, "npc/metropolice/pain" .. math.random(1, 4) .. ".wav", 55, 230)
                            set.squeak = math.random() < LC.CanTinyChance and (now + math.Rand(0.9, 2.6)) or nil
                        end
                        if set.squeak and now >= set.squeak then -- (flat on his back, and furious about it)
                            set.squeak, set.squeaks = nil, (set.squeaks or 0) + 1
                            Snd(set.tiny, LC.CanTinyLines[math.random(#LC.CanTinyLines)], 60, LC.CanTinyPitch + (i * 7) % 16)
                        end
                        local fx, fy = set.binAt.x + 40, set.binAt.y + ((i % 2 == 0) and 25 or -25)
                        if t < 0.25 or t >= LC.CanCycle - 0.5 then -- (on the bin, or hopping back up)
                            local k = t < 0.25 and 1 or (t - (LC.CanCycle - 0.5)) / 0.5
                            set.tiny:SetPos(Vector(fx + (top.x - fx) * k, fy + (top.y - fy) * k, g.top + (top.z - g.top) * k + math.sin(k * math.pi) * 14))
                            set.tiny:SetAngles(Angle(0, 180, 0))
                        elseif t < 0.75 then -- (falling)
                            local k = (t - 0.25) / 0.5
                            set.tiny:SetPos(Vector(top.x + (fx - top.x) * k, top.y + (fy - top.y) * k, top.z + (g.top - top.z) * k + math.sin(k * math.pi) * 18))
                            set.tiny:SetAngles(Angle(k * 360, 180, 0))
                        else -- (flat on its back)
                            set.tiny:SetPos(Vector(fx, fy, g.top + 3))
                            set.tiny:SetAngles(Angle(-90, 180, 0))
                        end
                    end
                end
            elseif IsValid(set.cop) and (set.cop.lcCanScale or 1) ~= grow then
                Scale(set.cop, grow)
            end
        end
        for _, t in ipairs(g.trees or {}) do
            if IsValid(t.ent) then
                local k = math.Clamp((now - t.born) / 1.5, 0.05, 1)
                local sc = 1 + (t.size - 1) * k
                Scale(t.ent, sc)
                Stand(t.ent, t.at.x, t.at.y, g.top, sc)
            end
        end
    end

    function def.tick(g, dt, players)
        local now = CurTime()
        local m = Main(g)
        if g.idleAt and now >= g.idleAt then g.idleAt = nil if IsValid(m.cop) then Animate(m.cop, ACT_IDLE) end end
        Sets(g, now)
        for _, p in ipairs(players) do
            local s = g.pl[p]
            s.did = s.did or {}
            local c = s.can
            if not c then
                c = { st = "bin", at = now, knock = math.max(now + 1.5, g.t0 + 3), kind = m.swapped and "cop" or "can" }
                s.can, g.dirty = c, true
            end
            local use, atk = Pressed(s, p, KEY_USE, "canUse"), Pressed(s, p, KEY_ATTACK, "canAtk")
            if c.st == "bin" then
                if now >= c.knock and not (g.swapped and now < g.swapped + 1.6) then
                    Swing(g)
                    c.st, c.at, c.pos, c.nag, g.dirty = "floor", now, LC.CanSpot(g, p), now + 9, true
                end
            elseif c.st == "floor" then
                if use and Dist2(p:GetPos(), c.pos) <= LC.CanReach then
                    c.st, c.at, g.dirty = "held", now, true
                    Snd(p, "physics/metal/soda_can_impact_soft" .. math.random(1, 3) .. ".wav", 60, c.kind == "cop" and 180 or 100)
                    Say(g, "can_trash", m.cop or m.can, TRASH[math.random(#TRASH)], (m.swapped and 160 or 100) / math.sqrt(m.grow or 1), 7)
                elseif now >= (c.nag or 0) then
                    c.nag = now + 9
                    Say(g, "can_again", m.cop or m.can, PICKUP[math.random(2, 3)], (m.swapped and 160 or 100) / math.sqrt(m.grow or 1), 7)
                end
            elseif c.st == "held" then
                if atk then
                    local what, at, set = LC.CanAim(g, p)
                    LC.CanThrown(g, p, what, at, set)
                end
            elseif c.st == "fly" then
                if now >= (c.next or 0) then
                    s.can = { st = "bin", at = now, knock = now + 1.2, kind = Main(g).swapped and "cop" or "can" }
                    g.dirty = true
                end
            end
        end
        if now >= g.ends - 0.5 and not g.scored then
            g.scored = true
            for _, p in ipairs(players) do
                local d = g.pl[p].did or {}
                if d.cop and d.bin and d.away then
                    Done(g, p, "won", "Every which way", "At him, in the bin, and anywhere but. Everything a can can do.")
                end
            end
        end
    end

    function LC.CanWays(s)
        local d, n = s and s.did or {}, 0
        for _, k in ipairs({ "cop", "bin", "away" }) do if d[k] then n = n + 1 end end
        return n
    end

    function def.state(g, p)
        local s = p and g.pl[p]
        local now = CurTime()
        local t = { sets = #g.sets, rain = g.rain, swapped = g.swapped ~= nil, tone = "warn" }
        if not s then return t end
        local c = s.can
        local ways = LC.CanWays(s)
        t.meter = math.floor(ways / 3 * 100)
        t.meterName = string.format("Ways tried: %d of 3", ways)
        if c then
            local thing = c.kind == "cop" and "officer" or "can"
            t.can = { s = c.st, k = c.kind, a = c.at, w = c.what, b = Flat(LC.CanBinTop(g)), p = c.pos and Flat(c.pos) or nil, t = c.to and Flat(c.to) or nil }
            if c.st == "floor" then
                t.glows = { Flat(c.pos + Vector(0, 0, 6), 6) }
                t.big = "Pick up that " .. thing .. ". (Use)"
            elseif c.st == "held" then
                t.big = "Left click: throw it. At him, in the bin, or anywhere."
            elseif now < (s.noteTil or 0) then
                t.big = s.note
            end
        end
        return t
    end
end

------------------------------------------------------------------------
-- Every line said in this dream (to record: VOICE_LINES.md)
------------------------------------------------------------------------

LC.StrangeAddCues({
    can_hello = { "The Officer", "Pick up that can.", "a Civil Protection officer through his mask's radio, flat and bored, just as in Half-Life 2" },
    can_trash = { "The Officer", "Now, put it in the trash can.", "the officer, flat, already enjoying himself" },
    can_again = { "The Officer", "Pick. Up. That. Can.", "the officer, slower and lower every word, losing patience" },
    can_litter = { "The Officer", "That is not the trash can. Nothing is the trash can. Pick up that can.", "the officer, slow and deep, as if he has grown very large" },
    can_bin = { "The Bin", "Thank you. Delicious.", "a deep, hollow, echoing voice from inside a metal bin, ending in a small burp" },
    can_swap = { "The Can", "Pick up that can.", "the officer's line, tinny and high, as if spoken from inside an empty drinks can" },
    can_clone = { "Another Can", "Pick up that can. Pick up that can. Pick up that can.", "tinny and high, several voices not quite together" },
    can_full = { "The Can", "No more room. Pick up all the cans.", "tinny and high, delighted with itself" },
})
