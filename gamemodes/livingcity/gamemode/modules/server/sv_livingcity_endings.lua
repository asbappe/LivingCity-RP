--[[
    Living City: secret endings

      Do the right (wrong) thing, mostly with the motherlode (the master data
      core out of the Combine's master terminal), and the city ends. Not for
      real: nobody dies, characters, Civil Standing and credits carry on, and
      the map reloads with its Living City layout afterwards.

      How every one goes
        1. Something triggers it.
        2. A few seconds later (lc_ending_pause, 4) the G-Man stops time:
           everyone freezes, every NPC stops, colour drains out of the world,
           the G-Man is standing right in front of each person (whichever way
           they were looking; their view turns to him and stays on him),
           his voice plays for everyone (lc_ending_gman_lines) and the vote
           comes up on every screen. 1: let it happen. 2: skip it.
        3. lc_ending_vote_secs (30) later: more skips than yeses and he
           straightens his tie, time starts again, and life goes on. Anything
           else (a tie, or nobody voting at all): the apocalypse.
        4. The ending plays out with its song, until everyone's been taken
           (or lc_ending_max seconds), then the world goes white and the map
           reloads.

      The endings (their songs go straight in sound/livingcity/endings/,
      named for the ending: bus.mp3, harpies.ogg, bus2.mp3 for another;
      .mp3, .ogg or .wav. The official place is the server's own
      garrysmod/sound/livingcity/endings/ (FastDL mirrors it), outside the
      gamemode's folder, so updating the gamemode never touches them. The older layout, a
      folder per ending, endings/bus/anything.mp3, still works.)
        harpies    lights out, everyone at the landing zone, and the mingebags
                   (the 2007 default: Dr. Kleiner in the reference pose, a
                   physgun stuck at his crotch, sliding)
                   gather in the dark for a minute, rush in when the song
                   swells, then leap; everyone's dead by 2:00 and watches
                   (lc_ending_minge_swell, lc_ending_minge_end, _max, _models)
        bus        the party bus: it drives about through the song's intro,
                   then everyone (and some of the Combine) is in it and it
                   flies through walls, a rainbow behind it, speed surging on
                   the beat, through rings that pop; down to drive again, then
                   up faster (lc_ending_bus_sections)
        plane      numa numa: everyone dancing on the wings of an airplane over
                   the city, the webcam dance, everyone mouthing the words, a
                   little webcam of your own face in the corner; swooping and
                   rolling in the choruses, fireworks in the last, and up into
                   the clouds on the final note (lc_ending_plane_sections)
        standup    the rope (the hanged painted white, white cone hats on, a
                   crowd cheering): someone new strung up every other beat, from
                   whatever is above them or the nearest wall; the hanged
                   struggle while their health drains, then go limp and look
                   on (lc_ending_standup_sections)
        hard       party hard: everyone at the landing zone (every NPC in the
                   city dancing too), the cheap mirror-flip meme dance on the
                   half-beat, PARTY HARD flashing everywhere, strobes; people
                   pass out one at a time (lc_ending_hard_sections)
        base       someone set up us the bomb: the song's opening lines as
                   arcade subtitles, bombs all over the city, CATS in the sky;
                   everyone on a ZIG (a dropship), the fleet circling the city
                   as the bombs go off, then diving at CATS for great justice;
                   chat in Engrish (lc_ending_base_sections, _lines)
        marrow     skeletons dance their way in from all over the map to the
                   landing zone; on the song's heavy parts everyone (the
                   Combine's units too) dances with them, club lights
                   strobing; in between they attack, and whoever they get
                   becomes one, dancing for good; the outro (the xylophone)
                   claims the rest, everyone dancing double time
                   (lc_ending_marrow_sections lines it up with your file)
        bloom      everyone dances (every NPC too) and can't stop; the city dims
                   and coloured light pulses on the beat; from 2:01
                   (lc_ending_bloom_speedup) the song speeds up, and at the top
                   of it the dancers spin up into the sky one at a time and
                   burst. (A codeword: the song's name is in nothing players
                   download.)
        water      the flood: a stage floats at the landing zone in the worst
                   storm the city's seen; the waves knock people off it,
                   ichthyosaurs hunt the water and leap at the edge; swim, or
                   drown. Father Grigori rocks out on it, mouthing every word,
                   untouchable, and goes last on the final note
                   (lc_ending_flood_sections, from the song itself).
                   Triggered by Father Grigori himself eating the motherlode:
                   /eatchip, with a master data core in his pockets.
        shalom     the hora: Israeli flags round the landing zone, a giant
                   hanukkiah in the middle (a candle lit each phrase), kippahs
                   on every head and Yiddish and Hebrew sayings over them;
                   everyone dances the hora in rings, the Combine putting
                   their guns down to join in, someone up on a chair, a giant
                   flag and Star of David fireworks at the key change
                   (lc_ending_shalom_sections, _candles)
        fire       everyone's behind catches fire: they sputter and smoke
                   through the intro, ignite at the drop and dance bent over,
                   hop on the beat as the flames grow, then lift off on their
                   own jets and fly Superman style in a ring over the city;
                   at the end each one rockets straight up and goes off like
                   a firework (lc_ending_fire_sections, _hop, _fly_speed)

      Nobody can be hurt during the vote or an ending (and "taken" isn't dead:
      no new character). The city's events wait. One ending (or a skipped one)
      every lc_ending_cooldown minutes (180: three hours), remembered across the reload.

      Admins: lc_endings (the songs found, the cooldown), lc_ending <id> [now]
      (trigger one; now: no vote), lc_ending_cancel (stop one, no reload),
      lc_ending_reset_cooldown.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_ending")
util.AddNetworkString("lc_ending_vote")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_endings_on", "1", FLAGS, "Secret endings (the G-Man, a vote, and the city's end)")
local cvPause   = CreateConVar("lc_ending_pause", "4", FLAGS, "Seconds between a secret ending's trigger and the G-Man stopping time")
local cvVote    = CreateConVar("lc_ending_vote_secs", "30", FLAGS, "Seconds the G-Man's vote stays open")
local cvMax     = CreateConVar("lc_ending_max", "180", FLAGS, "Longest a secret ending runs before the reset")
local cvCool    = CreateConVar("lc_ending_cooldown", "180", FLAGS, "Minutes between secret endings (triggered, voted on or skipped)")
local cvGman    = CreateConVar("lc_ending_gman_lines", "vo/citadel/gman_exit02.wav", FLAGS,
    "The G-Man's lines when he stops time, in order (comma-separated sound paths)")
local cvSongVol = CreateConVar("lc_ending_song_volume", "harpies=4,shalom=2", FLAGS, "How loud an ending's song plays, for a quiet recording: id=volume, comma-separated (1 is as it is; up to 6)")
local cvRadius  = CreateConVar("lc_ending_flight_radius", "2200", FLAGS, "How wide the flying endings circle the city, at most (narrower where buildings are in the way: they keep to open sky)")

local ROOT = "livingcity/endings/"
local EXT = { wav = true, mp3 = true, ogg = true }

LC.Endings = {
    harpies   = { name = "They Return", say = "The lights go out. Something is gathering out there in the dark." },
    bus       = { name = "The Bus", say = "Hear that horn? All aboard." },
    plane     = { name = "Plane", say = "Alo, salut. Please fasten your seatbelts." },
    standup   = { name = "Standup", say = "Look up." },
    water     = { name = "The Flood", say = "Father Grigori has eaten the motherlode. The waters rise." },
    bloom     = { name = "Bloom", say = "Everybody dances. Nobody stops." },
    marrow    = { name = "Marrow", say = "Something is rattling out there. Lots of somethings." },
    base      = { name = "Base", say = "What happen ?" },
    hard      = { name = "Hard", say = "It's time." },
    shalom    = { name = "Shalom", say = "Shalom. Take your neighbour by the shoulders: it's time to dance." },
    fire      = { name = "Fire", say = "Something smells like smoke. It's coming from behind you." },
}
-- The ones with strobes or flashes: everyone is warned before and as they start
-- (and lc_ending_calm, on each player's own screen, leaves the flashing out).
for _, id in ipairs({ "bus", "bloom", "marrow", "base", "hard", "water", "plane", "fire" }) do if LC.Endings[id] then LC.Endings[id].flashing = true end end
LC.EndingOrder = { "harpies", "bus", "plane", "standup", "water", "bloom", "marrow", "base", "hard", "shalom", "fire" }

local E -- the ending in progress: { id, phase, by, ... }
-- (a dream, sv_livingcity_dreams.lua: only the dreamers are in it, so to the rest of the city
-- there is no ending; LC.EndingAny is the one in progress either way)
function LC.EndingSession() if E and E.dream then return nil end return E end
function LC.EndingAny() return E end
function LC.EndingBusy() return E ~= nil end
-- Everyone an ending is for: the whole city, or in a dream only the dreamers.
function LC.EndingPlayers()
    if E and E.dream and LC.DreamersOf then return LC.DreamersOf(E.dream) end
    return player.GetAll()
end
-- The NPCs an ending dances, hangs or sets alight: the city's, or in a dream only its own.
function LC.EndingNPCs()
    if E and E.dream then return E.dream.npcs or {} end
    return LC.NPCs or {}
end

local function All(msg) for _, p in ipairs(LC.EndingPlayers()) do p:ChatPrint(msg) end end

------------------------------------------------------------------------
-- Songs, and the cooldown (kept in a file: it outlasts the reload)
------------------------------------------------------------------------

-- Which ending a song in the endings folder is for: the codeword its name
-- starts with (the longest that fits), followed by nothing, a number or a
-- separator: bus.mp3, bus2.mp3, bus_remix.ogg. nil: none of them.
function LC.EndingOfSong(name)
    local base = string.lower(string.match(name or "", "^(.*)%.[%w]+$") or "")
    local best
    for _, id in ipairs(LC.EndingOrder) do
        if string.sub(base, 1, #id) == id and (not best or #id > #best) then
            local rest = string.sub(base, #id + 1, #id + 1)
            if rest == "" or not string.match(rest, "%a") then best = id end
        end
    end
    return best
end

function LC.EndingSongs(id)
    local out = {}
    local function Add(rel)
        out[#out + 1] = ROOT .. rel
        if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. rel) end
    end
    local function Audio(n) local ext = string.match(n, "%.([%w]+)$") return ext and EXT[string.lower(ext)] end
    -- straight in the folder, named for the ending
    local names = file.Find("sound/" .. ROOT .. "*", "GAME") or {}
    table.sort(names)
    for _, n in ipairs(names) do
        if not string.find(n, "/", 1, true) and Audio(n) and LC.EndingOfSong(n) == id then Add(n) end
    end
    -- (older: a folder per ending, any name)
    names = file.Find("sound/" .. ROOT .. id .. "/*", "GAME") or {}
    table.sort(names)
    for _, n in ipairs(names) do
        if Audio(n) then Add(id .. "/" .. n) end
    end
    return out
end

local COOL_FILE = "livingcity/endings.json"
LC.EndingRoot, LC.EndingCooldownFile = ROOT, COOL_FILE -- (core: CORE.md)
local function LastEnding()
    local raw = file.Read(COOL_FILE, "DATA")
    if not raw or raw == "" then return 0 end
    local t = util.JSONToTable(raw) or {}
    return tonumber(t.last) or 0
end
local function MarkEnding()
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(COOL_FILE, util.TableToJSON({ last = os.time() }))
end
function LC.EndingCooldownLeft()
    return math.max(0, LastEnding() + cvCool:GetFloat() * 60 - os.time())
end

------------------------------------------------------------------------
-- Telling the clients
------------------------------------------------------------------------

function LC.EndingSongVolume(id)
    for k, v in string.gmatch(cvSongVol:GetString() or "", "([%w_]+)%s*=%s*([%d%.]+)") do
        if string.lower(k) == id then return math.Clamp(tonumber(v) or 1, 0, 6) end
    end
    return 1
end

local function Send(to)
    net.Start("lc_ending")
    if not E then
        net.WriteTable({})
    else
        local yes, skip = 0, 0
        for _, v in pairs(E.votes or {}) do if v then yes = yes + 1 else skip = skip + 1 end end
        net.WriteTable({ id = E.id, phase = E.phase, name = LC.Endings[E.id].name, say = LC.Endings[E.id].say,
            voteEnds = E.voteEnds, yes = yes, skip = skip, song = E.song, songVolume = LC.EndingSongVolume(E.id), lines = E.lines, grigori = E.grigori,
            floodZ = E.floodZ, client = E.client, flashing = LC.Endings[E.id].flashing or nil })
    end
    if to then net.Send(to) elseif E and E.dream then net.Send(LC.EndingPlayers()) else net.Broadcast() end
end

------------------------------------------------------------------------
-- Stopping time
------------------------------------------------------------------------

local function Freeze(on)
    if not (E and E.dream) then
        LC.TimeStopped = on or nil
        SetGlobal2Bool("lc_timestop", on and true or false)
        if RunConsoleCommand then RunConsoleCommand("ai_disabled", on and "1" or "0") end
    end
    for _, p in ipairs(LC.EndingPlayers()) do
        if on then
            p.lcEndFrozen = true
            p:Freeze(true)
        elseif p.lcEndFrozen then
            p.lcEndFrozen = nil
            p:Freeze(false)
        end
    end
end
LC.EndingFreeze = Freeze

------------------------------------------------------------------------
-- The endings themselves
------------------------------------------------------------------------

-- "Taken": out of it, not dead (no new character). Frozen, hidden, the screen goes.
local function Take(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken = true
    p:Freeze(true)
    if p.SetNoDraw then p:SetNoDraw(true) end
    if p.SetNotSolid then p:SetNotSolid(true) end
    p:SetNW2Bool("lc_end_taken", true)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.OUT or 2, Color(0, 0, 0, 255), 1.5, 600) end
    p:ChatPrint(how or "You were taken.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end
LC.EndingTake = Take

local function Living()
    local out = {}
    for _, p in ipairs(LC.EndingPlayers()) do if p:Alive() and not p.lcEndTaken then out[#out + 1] = p end end
    return out
end

local function Centre()
    local sum, n = Vector(0, 0, 0), 0
    for _, p in ipairs(LC.EndingPlayers()) do sum = sum + p:GetPos() n = n + 1 end
    return n > 0 and sum * (1 / n) or Vector(0, 0, 0)
end

-- Open sky to fly in: the height just under the map's sky over a spot, and
-- the widest circle (up to lc_ending_flight_radius) round it that stays in
-- open air the whole way round, so whatever flies (and whoever rides it, and
-- the camera behind them) never goes through a building or out of the map.
-- { z, r, centre } (kept for the ending in E.flight).
local function Open(pos)
    if util.IsInWorld and not util.IsInWorld(pos) then return false end
    if util.PointContents and CONTENTS_SOLID and bit.band(util.PointContents(pos), CONTENTS_SOLID) ~= 0 then return false end
    return true
end
local function OpenPath(a, b)
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID_BRUSHONLY })
    return not tr.Hit and not tr.StartSolid
end
LC.EndingOpenPath = OpenPath
-- How high it's open above a spot (the sky, or a roof, whichever's lowest there).
local function CeilingAt(pos)
    local tr = util.TraceLine({ start = pos, endpos = pos + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
    if tr.StartSolid then return pos.z end
    return tr.Hit and tr.HitPos and tr.HitPos.z or (pos.z + 4000)
end
LC.EndingCeilingAt = CeilingAt
function LC.EndingSky(centre)
    centre = centre or Vector(0, 0, 0)
    local up = util.TraceLine({ start = centre + Vector(0, 0, 64), endpos = centre + Vector(0, 0, 32768), mask = MASK_SOLID_BRUSHONLY })
    local top = (up.Hit and up.HitPos and up.HitPos.z) or (centre.z + 1600)
    if not up.HitSky and top - centre.z < 600 then top = centre.z + 1600 end -- (under a roof: aim well above it)
    local z = math.max(centre.z + 350, top - 220)
    if top - centre.z < 700 then z = centre.z + (top - centre.z) * 0.6 end
    local function RingOK(r, zz, c)
        c = c or centre
        local prev
        for i = 0, 24 do
            local a = i / 24 * math.pi * 2
            local p = Vector(c.x + math.cos(a) * r, c.y + math.sin(a) * r, zz)
            if not Open(p) or (prev and not OpenPath(prev, p)) then return false end
            prev = p
        end
        return true
    end
    -- the widest open circle: round the spot itself, else the roomiest patch of sky nearby
    local function Widest(c, zz)
        if not Open(Vector(c.x, c.y, zz)) then return 0 end
        local r = cvRadius:GetFloat()
        while r >= 300 do
            if RingOK(r, zz, c) then return r end
            r = r * 0.82
        end
        return 0
    end
    local best, bestR, bestZ = centre, 0, z
    local want = cvRadius:GetFloat() * 0.7
    local tries = { Vector(0, 0, 0) }
    local dream = E and E.dream
    if not dream then for gx = -3, 3 do for gy = -3, 3 do if gx ~= 0 or gy ~= 0 then tries[#tries + 1] = Vector(gx * 1200, gy * 1200, 0) end end end end
    table.sort(tries, function(a, b) return a:LengthSqr() < b:LengthSqr() end)
    for _, zz in ipairs({ z, z - 200, z - 450 }) do
        for _, off in ipairs(tries) do
            local c = centre + off
            local r = Widest(c, zz)
            if r > bestR then best, bestR, bestZ = c, r, zz end
            if bestR >= want then break end
        end
        if bestR >= want then break end
    end
    if bestR == 0 then bestR = 300 end
    local roam = math.max(3000, cvRadius:GetFloat() * 2)
    if dream and LC.DreamRadius then -- (a dream: the flying stays inside it)
        local dr = LC.DreamRadius(dream)
        bestR, roam = math.min(bestR, dr * 0.8), math.min(roam, dr)
        if LC.DreamTop then bestZ = math.min(bestZ, LC.DreamTop(dream) - 120) end
    end
    return { z = bestZ, top = top, r = bestR, centre = Vector(best.x, best.y, bestZ), roam = roam, from = Vector(centre.x, centre.y, z) }
end

-- Room for another entity? The engine has 8192 in all and the server falls over
-- when they run out, so an ending never spawns anything past lc_ending_edict_limit.
local cvEdicts = CreateConVar("lc_ending_edict_limit", "7000", FLAGS, "Endings spawn nothing more once the server has this many entities (the engine's limit is 8192)")
local function Room()
    return not ents.GetEdictCount or ents.GetEdictCount() < cvEdicts:GetInt()
end
LC.EndingRoom = Room

local function FirstModel(list)
    for _, m in ipairs(list) do if not util.IsValidModel or util.IsValidModel(m) then return m end end
    return list[#list]
end

local function Prop(model, pos, scale)
    if not Room() then return nil end
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    e:Spawn()
    if scale and e.SetModelScale then e:SetModelScale(scale, 0) end
    E.ents[#E.ents + 1] = e
    return e
end

-- Riders: held in place on a moving thing, every tick.
-- (held, not frozen: a frozen player can't even look about, and the camera behind
-- whatever they're riding turns with their mouse)
local function HoldOn(p)
    if p.lcEndFrozen or (p.IsFrozen and p:IsFrozen()) then p:Freeze(false) end
    p.lcEndFrozen = nil
    p:SetMoveType(MOVETYPE_NONE)
end
local function Board(vehicle, riders, offsets)
    for i, p in ipairs(riders) do
        HoldOn(p)
        p.lcEndRide = { v = vehicle, off = offsets[i] or Vector(0, 0, 40) }
    end
end

local function Ride(now)
    for _, p in ipairs(LC.EndingPlayers()) do
        local r = p.lcEndRide
        if r and IsValid(r.v) then p:SetPos(r.v:GetPos() + r.off) end
    end
end

local SETUP, TICK = {}, {}

-- the Harpies: the mingebags. Lights out, everyone at the landing zone, and
-- old-school Garry's Mod players in the civilian pose, sliding. For the first
-- minute they gather in the dark, far off and out of sight, keeping their
-- distance and getting bolder; when the song swells (lc_ending_minge_swell,
-- 60 s) they rush in and surround everyone; 9 seconds later they leap, all of
-- them, and it's a slaughter. From 1:50 walls don't stop them; by 2:00
-- (lc_ending_minge_end) everyone's gone. The dead watch (spectating).
local cvMingeMax    = CreateConVar("lc_ending_minge_max", "60", FLAGS, "How many mingebags the Harpies ending gathers")
local cvMingeSwell  = CreateConVar("lc_ending_minge_swell", "60", FLAGS, "Seconds into the Harpies' song when it swells and the mingebags rush in (they leap 9 seconds later)")
local cvMingeEnd    = CreateConVar("lc_ending_minge_end", "120", FLAGS, "Seconds into the Harpies' song by which everyone is dead (walls stop mattering 10 seconds before)")
CreateConVar("lc_ending_minge_pose", "ragdoll", FLAGS, "The mingebags' pose: a sequence name on their models (ragdoll: the reference pose)")
local cvMingeModels = CreateConVar("lc_ending_minge_models",
    "models/player/kleiner.mdl", FLAGS, "The mingebags' models (comma-separated; any missing are skipped). Kleiner: the 2007 default, physgun at the crotch")

local RUSH = 9 -- (seconds of rushing in before the leaping)
local UP = Vector(0, 0, 1)

-- The floor under a spot (nil: inside a wall, or nothing there).
-- The floor under a spot: close below first, then much further down (the landing
-- zone may be up on a roof or a platform, with the streets round it far below).
local function Ground(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 120), endpos = pos - Vector(0, 0, 600), mask = MASK_SOLID_BRUSHONLY })
    if tr.Hit and not tr.StartSolid then return tr.HitPos end
    if tr.StartSolid then return nil end
    tr = util.TraceLine({ start = pos - Vector(0, 0, 590), endpos = pos - Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
    if tr.Hit and not tr.StartSolid then return tr.HitPos end
    return nil
end

-- Nothing solid between two spots, at knee height.
local function Clear(a, b)
    local tr = util.TraceLine({ start = a + Vector(0, 0, 24), endpos = b + Vector(0, 0, 24), mask = MASK_SOLID_BRUSHONLY })
    return not tr.Hit
end

-- The Combine's own units in the city (they're in this too).
local function CombineNPCs()
    if E and E.dream then return E.dream.combine or {} end -- (a dream: the units it brought, never the city's)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity and LC.IsSecurity(st) then out[#out + 1] = npc end
    end
    return out
end

-- n spots round a centre, from radius r0 out, each one clear of the others (taken: spots already
-- given out, which it adds to) and of walls. A ring that's full spills onto the next one out
-- (the owner, 1 November: with 100+ NPCs, the endings' rings had them standing inside each other,
-- and the engine pushed some through the floor). Returns { { pos =, a = angle }, ... }.
local RING_GAP = 46
local function RingFree(g, taken)
    for _, t in ipairs(taken) do
        if math.abs(t.z - g.z) < 60 and (t.x - g.x) ^ 2 + (t.y - g.y) ^ 2 < (RING_GAP * 0.9) ^ 2 then return false end
    end
    if util.TraceHull then
        local tr = util.TraceHull({ start = g + Vector(0, 0, 6), endpos = g + Vector(0, 0, 8), mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 64), mask = MASK_SOLID_BRUSHONLY })
        if tr and (tr.Hit or tr.StartSolid) then return false end
    end
    return true
end
function LC.EndingRingSpots(centre, r0, n, taken, turn)
    taken = taken or {}
    local out, r = {}, math.max(r0 or 60, 24)
    for ring = 1, 40 do
        if #out >= n then break end
        local slots = math.max(6, math.floor(2 * math.pi * r / RING_GAP))
        local left = n - #out
        local step = left < slots and slots / left or 1 -- (a ring that isn't filled: spread round it)
        local k = 0
        while k < slots and #out < n do
            local a = (turn or 0) + ring * 0.37 + math.floor(k) / slots * math.pi * 2
            local g = Ground(centre + Vector(math.cos(a) * r, math.sin(a) * r, 0))
            if g and E and E.dream and LC.DreamHolds and not LC.DreamHolds(E.dream, g) then g = nil end -- (a dream: never out in the city)
            if g and RingFree(g, taken) then out[#out + 1] = { pos = g, a = a } taken[#taken + 1] = g end
            k = k + step
        end
        r = r + RING_GAP
    end
    -- (a tiny room with no space left: the rest by the centre, as before)
    while #out < n do out[#out + 1] = { pos = Ground(centre) or centre, a = #out } end
    return out
end
local RingSpots = LC.EndingRingSpots

-- The Combine's units, to the landing zone with everyone (a ring outside the players).
local function GatherCombine(centre, r, taken)
    local list = CombineNPCs()
    local spots = RingSpots(centre, r, #list, taken, 0.3)
    for i, npc in ipairs(list) do
        npc:SetPos(spots[i].pos) -- (right on the ground: time's stopped, so nothing would drop them onto it)
        npc:SetAngles(Angle(0, math.deg(spots[i].a), 0))
    end
    return list
end

local function Seen(pos)
    for _, p in ipairs(Living()) do
        local tr = util.TraceLine({ start = p:EyePos(), endpos = pos + Vector(0, 0, 50), mask = MASK_SOLID_BRUSHONLY })
        if not tr.Hit then return true end
    end
    return false
end

-- A spot about `dist` from the centre (near `angle`, if given), out of sight if `hide`.
local function RingSpot(centre, dist, hide, angle)
    for i = 1, 10 do
        local a = angle and (angle + math.Rand(-0.5, 0.5)) or math.Rand(0, math.pi * 2)
        local d = dist + math.Rand(-150, 150)
        local g = Ground(centre + Vector(math.cos(a) * d, math.sin(a) * d, 0))
        if g and E and E.dream and LC.DreamHolds and not LC.DreamHolds(E.dream, g) then g = nil end -- (a dream: never out in the city)
        if g and (not hide or i > 7 or not Seen(g)) then return g, a end
    end
    -- nowhere found: somewhere people can walk, about that far out (the map's own navigation)
    if LC.NavNodesNear and not (E and E.dream) then
        local near = {}
        for _, nd in ipairs(LC.NavNodesNear(centre, dist + 500)) do
            local d2 = (nd.pos - centre):Length2D()
            if d2 >= dist * 0.5 then near[#near + 1] = nd end
        end
        if #near > 0 then
            local nd = near[math.random(#near)]
            local off = nd.pos - centre
            return nd.pos, math.atan2(off.y, off.x)
        end
    end
    return nil
end

LC.EndingRingSpot = RingSpot

local function MingeModel()
    local list = {}
    for m in string.gmatch(cvMingeModels:GetString() or "", "[^,]+") do
        m = string.Trim(m)
        if m ~= "" and (not util.IsValidModel or util.IsValidModel(m)) then list[#list + 1] = m end
    end
    return list[math.random(math.max(1, #list))] or "models/player/kleiner.mdl"
end

local function SpawnMinge(pos, angle)
    if not Room() then return nil end
    local m = ents.Create("lc_minge")
    if not IsValid(m) then return nil end
    m.lcModel = MingeModel()
    m:SetModel(m.lcModel)
    m:SetPos(pos)
    m:SetAngles(Angle(0, math.deg(angle or 0) + 180, 0))
    m:Spawn()
    m.lcMinge = { mode = "lurk", angle = angle, hp = 25 }
    E.ents[#E.ents + 1] = m
    E.minges[#E.minges + 1] = m
    return m
end

local cvBodies = CreateConVar("lc_ending_bodies", "120", FLAGS, "How many bodies an ending leaves lying about before the oldest go (each is a ragdoll: the server's limits apply)")
local function Body(model, pos, yaw, fling)
    if not Room() then return nil end
    local r = ents.Create("prop_ragdoll")
    if not IsValid(r) then return nil end
    r:SetModel(model or "models/player/kleiner.mdl")
    r:SetPos(pos)
    r:SetAngles(Angle(0, yaw or 0, 0))
    r:Spawn()
    if r.GetPhysicsObjectCount then
        for i = 0, r:GetPhysicsObjectCount() - 1 do
            local ph = r:GetPhysicsObjectNum(i)
            if IsValid(ph) then ph:SetVelocity(VectorRand() * fling + Vector(0, 0, fling * 0.6)) end
        end
    end
    E.ents[#E.ents + 1] = r
    E.bodies = E.bodies or {}
    E.bodies[#E.bodies + 1] = r
    if #E.bodies > cvBodies:GetInt() then local old = table.remove(E.bodies, 1) if IsValid(old) then old:Remove() end end
    return r
end

-- Who a dead player watches: the living first, then the mingebags.
local function Watch(p, dir)
    local list = {}
    for _, q in ipairs(Living()) do list[#list + 1] = q end
    for _, m in ipairs(E and E.minges or {}) do if IsValid(m) then list[#list + 1] = m end end
    if #list == 0 then return end
    p.lcEndWatchI = ((p.lcEndWatchI or 0) + (dir or 1) - 1) % #list + 1
    p.lcEndWatching = list[p.lcEndWatchI]
    if p.SpectateEntity then p:SpectateEntity(p.lcEndWatching) end
end

-- Killed by them: a body on the ground, and the player watches the rest.
-- (Not really dead: no close call spent, no new character; the map resets.)
local function Spectator(p, how, col)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken, p.lcEndSpectating = true, true
    -- (out of it: no longer frozen in a dance or a seat, or pinned to the bus or the plane,
    -- so the keys work: clicks to watch someone else, jump to fly free)
    if p.lcEndFrozen or (p.IsFrozen and p:IsFrozen()) then p:Freeze(false) p.lcEndFrozen = nil end
    p.lcEndRide = nil
    p:SetNW2Entity("lc_riding", NULL)
    p:SetNW2Bool("lc_seated", false)
    p:SetNW2Bool("lc_dancing", false)
    p:SetNW2Bool("lc_end_taken", true)
    p:SetNW2Bool("lc_end_spectating", true)
    if p.SetNoDraw then p:SetNoDraw(true) end
    if p.SetNotSolid then p:SetNotSolid(true) end
    if p.Spectate then p:Spectate(OBS_MODE_CHASE) end
    Watch(p, 1)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, col or Color(140, 0, 0, 220), 2, 0) end
    p:ChatPrint(how or "You're out of it. Watch the rest.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end
LC.EndingSpectator = Spectator

local function Slaughter(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    Body(p:GetModel(), p:GetPos(), p:EyeAngles().y, 260)
    p:EmitSound("vo/npc/male01/pain0" .. math.random(7, 9) .. ".wav", 80)
    Spectator(p, how or "The mingebags got you.")
end
LC.EndingSlaughter = Slaughter

-- How hard they hit: light for the first 30 seconds of the leaping (a chance
-- to run), then climbing steeply to full at 45 seconds, and worse after.
function LC.MingeFury(now)
    local since = (now or CurTime()) - ((E and E.leapAt) or math.huge)
    if since < 30 then return 0.3 end
    return 0.3 + ((math.min(since, 45) - 30) / 15) ^ 2 * 2.7 + math.max(0, since - 45) * 0.2
end

local function Hit(p)
    if not IsValid(p) or p.lcEndTaken then return false end
    local now = CurTime()
    if now < (p.lcMingeHitAt or 0) then return false end
    local fury = LC.MingeFury(now)
    p.lcMingeHitAt = now + 0.3 / math.min(1, fury) * 0.8
    if not p:IsPlayer() then -- (one of the Combine's units, or one of the city's people in the ring)
        if E then E.ringHits = (E.ringHits or 0) + 1 end
        p:SetHealth(p:Health() - math.max(1, math.floor(math.random(10, 18) * fury)))
        p:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
        if p:Health() <= 0 then
            local unit = E and table.HasValue(E.combine or {}, p)
            Body(p:GetModel(), p:GetPos(), p:GetAngles().y, 260)
            p:Remove()
            if unit and LC.EndingChatter then LC.EndingChatter("down") end
        end
        return true
    end
    p:SetHealth(p:Health() - math.max(1, math.floor(math.random(7, 12) * fury)))
    if p.ViewPunch then p:ViewPunch(Angle(math.Rand(-10, 10), math.Rand(-10, 10), 0)) end
    p:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(p:GetPos() + Vector(0, 0, 40))
        util.Effect("BloodImpact", fx)
    end
    if p:Health() <= 0 then Slaughter(p, "They're on you, all of them, in that pose. The mingebags got you.") end
    return true
end

-- One step of a mingebag's slide or leap (each server tick: lc_minge.lua).
function LC.MingeStep(m, dt)
    local s = m.lcMinge
    if not s or not E or E.id ~= "harpies" then return end
    local now = CurTime()
    local pos = m:GetPos()
    if s.leap then
        local L = s.leap
        local f = math.min(1, (now - L.t0) / L.dur)
        m:SetPos(LerpVector(f, L.from, L.to) + UP * (4 * L.h * f * (1 - f)))
        if f >= 1 then
            s.leap = nil
            local t = s.target
            if IsValid(t) and (t:IsPlayer() or t:IsNPC()) and t:GetPos():DistToSqr(m:GetPos()) < 80 * 80 then Hit(t) end
        end
        return
    end
    if not s.goal then return end
    -- (a way round a wall, over the map's nodegraph, once one's in the way: waypoint by waypoint)
    local aim = s.goal
    if s.path then
        if not s.pathGoal or s.pathGoal:DistToSqr(s.goal) > 200 * 200 then s.path = nil
        else
            local wp = s.path[s.pathI]
            while wp and (wp - pos):Length2D() < 30 do s.pathI = s.pathI + 1 wp = s.path[s.pathI] end
            if wp then aim = wp else s.path = nil end
        end
    end
    local to = aim - pos
    to.z = 0
    local dist = to:Length()
    if dist < 4 then return end
    local dir = to * (1 / dist)
    local step = math.min(dist, (s.speed or 100) * (dt or 0.1))
    local nextPos = pos + dir * step
    if not s.noclip then
        if not Clear(pos, nextPos + dir * 16) then
            local found
            for _, turn in ipairs({ 50, -50, 90, -90 }) do
                local a = dir:Angle()
                a.y = a.y + turn
                local alt = pos + a:Forward() * step
                if Clear(pos, alt + a:Forward() * 16) then nextPos, found = alt, true break end
            end
            if not found then
                s.stuck = (s.stuck or 0) + (dt or 0.1)
                if s.stuck > 0.6 and not s.path and LC.NavRoute and now >= (s.routeAt or 0) then
                    s.routeAt = now + 2
                    local route = LC.NavRoute(pos, s.goal)
                    if type(route) == "table" then s.path, s.pathI, s.pathGoal = route, 1, s.goal end
                end
                return
            end
        end
        s.stuck = 0
        local g = Ground(nextPos)
        if g and math.abs(g.z - pos.z) < 60 then nextPos.z = g.z end
    else
        local g = Ground(nextPos)
        nextPos.z = g and g.z or nextPos.z + (s.goal.z - nextPos.z) * 0.2
    end
    m:SetPos(nextPos)
end

-- Shot: nothing touches them until they've gathered; after that one goes
-- down, and another takes its place.
function LC.MingeHurt(m, dmg)
    local s = m.lcMinge
    if not s or not E or not E.vulnerable then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 25)
    if s.hp > 0 then return false end
    Body(m:GetModel(), m:GetPos(), m:GetAngles().y, 120)
    m:Remove()
    return true
end

local function Nearest(pos, list)
    local best, bd
    for _, p in ipairs(list) do
        local d = p:GetPos():DistToSqr(pos)
        if not bd or d < bd then best, bd = p, d end
    end
    return best, bd and math.sqrt(bd) or nil
end

-- Who else stands in the ring with everyone: the city's own people (never
-- the Resistance), topped up to lc_ending_minge_crowd with ordinary citizens.
local cvMingeCrowd = CreateConVar("lc_ending_minge_crowd", "12", FLAGS, "The Harpies: how many of the city's people stand in the ring too (its own NPCs first, never the Resistance; topped up with citizens)")
local FOLK = {
    "models/humans/group01/male_02.mdl", "models/humans/group01/female_02.mdl", "models/humans/group01/male_05.mdl", "models/humans/group01/female_04.mdl",
    "models/humans/group01/male_08.mdl", "models/humans/group01/female_07.mdl", "models/humans/group02/male_04.mdl", "models/humans/group02/female_03.mdl",
    "models/humans/group02/male_08.mdl", "models/humans/group02/female_06.mdl",
}
local NOT_IN_RING = { rebel = true, resistance = true, vortigaunt = true, vort = true, zombie = true, scanner = true }
local function CityFolk()
    if E and E.dream then return {} end -- (a dream: never the city's people; the endings bring their own)
    local out, known = {}, LC.NPCs or {}
    for npc, st in pairs(known) do
        if IsValid(npc) and not NOT_IN_RING[st.role or ""] and not (LC.IsSecurity and LC.IsSecurity(st)) then out[#out + 1] = npc end
    end
    for _, cls in ipairs({ "npc_citizen", "npc_breen", "npc_mossman" }) do
        for _, npc in ipairs(ents.FindByClass and ents.FindByClass(cls) or {}) do
            local mdl = string.lower(npc.GetModel and npc:GetModel() or "")
            if IsValid(npc) and not known[npc] and not npc.lcCrowd and not string.find(mdl, "group03", 1, true) then out[#out + 1] = npc end
        end
    end
    return out
end
-- Standing in the model's own idle, not the bind pose (time's stopped, so nothing
-- else animates them). The model is asked for its idle; names are the fallback.
local function StandIdle(e)
    if not IsValid(e) then return end
    local seq = e.SelectWeightedSequence and ACT_IDLE and e:SelectWeightedSequence(ACT_IDLE) or -1
    if not seq or seq < 0 then
        for _, name in ipairs({ "idle_all_01", "LineIdle01", "idle_unarmed", "Idle01", "idle_subtle" }) do
            seq = e.LookupSequence and e:LookupSequence(name)
            if seq and seq >= 0 then break end
        end
    end
    if not seq or seq < 0 then return end
    if e.SetSequence then e:SetSequence(seq) end
    if e.ResetSequence then e:ResetSequence(seq) end
    if e.SetCycle then e:SetCycle(math.Rand(0, 1)) end
    if e.SetPlaybackRate then e:SetPlaybackRate(1) end
end
LC.EndingStandIdle = StandIdle

local function SpawnFolk(pos, i)
    if not Room() then return nil end
    local c = ents.Create("npc_citizen")
    if not IsValid(c) then return nil end
    if c.SetKeyValue then c:SetKeyValue("citizentype", "4") end -- (the model it's given, not one of its own)
    c:SetModel(FOLK[(i - 1) % #FOLK + 1])
    c:SetPos(pos)
    c:Spawn()
    c.lcCrowd = true
    -- (time's stopped, so nothing animates them: set them standing, or they'd be in the bind pose;
    -- and again a moment later, in case spawning set one of its own)
    StandIdle(c)
    timer.Simple(0.3, function() StandIdle(c) end)
    E.ents[#E.ents + 1] = c
    return c
end

-- What the Combine's units say out loud, by what they're seeing. Missing
-- files are left out (lc_ending_minge_chatter 0: none of it).
local cvMingeChatter = CreateConVar("lc_ending_minge_chatter", "1", FLAGS, "The Harpies: the Combine's Civil Protection units talk on their radios, out loud, about what they're seeing (0 off)")
local MP, CS = "npc/metropolice/vo/", "npc/combine_soldier/vo/"
local function Lines(dir, list) local o = {} for _, n in ipairs(list) do o[#o + 1] = dir .. n .. ".wav" end return o end
local CHATTER = {
    cop = {
        on = Lines(MP, { "on1", "on2" }),
        lurk = Lines(MP, { "searchingforsuspect", "sweepingforsuspect", "holdthisposition", "lockyourposition", "cpweneedtoestablishaperimeterat", "suspectlocationunknown" }),
        closing = Lines(MP, { "acquiringonvisual", "possible10-103alerttagunits", "holdit", "dontmove", "ivegot408hereatlocation", "hidinglastseenatrange", "lookout" }),
        rush = Lines(MP, { "lookout", "watchit", "getdown", "malignant", "holditrightthere", "readytoprosecute", "dispatchineed10-78", "isclosingonsuspect" }),
        fire = Lines(MP, { "openfire", "takedown", "prosecute", "firingtoexposetarget", "shotsfiredhostilemalignants", "readytoprosecutefinalwarning" }),
        fight = Lines(MP, { "officerunderfiretakingcover", "11-99officerneedsassistance", "takecover", "help", "backup", "minorhitscontinuing",
            "runninglowonverdicts", "reload", "movingtocover", "shotsfiredhostilemalignants", "getdown", "necrotics" }),
        down = Lines(MP, { "officerdowncode3tomy10-20", "officerdowniam10-99", "11-99officerneedsassistance", "help" }),
    },
    soldier = {
        on = Lines(CS, { "on1", "on2" }),
        lurk = Lines(CS, { "motioncheckallradials", "stayalertreportsightlines", "lostcontact", "fixsightlinesmovein", "teamdeployedandscanning", "gosharpgosharp", "stayalert" }),
        closing = Lines(CS, { "sectorisnotsecure", "hardenthatposition", "alert1", "weaponsoffsafeprepforcontact", "readyweapons", "motioncheckallradials" }),
        rush = Lines(CS, { "contact", "contactconfim", "readyweaponshostilesinbound", "alert1", "weaponsoffsafeprepforcontact", "heavyresistance", "inbound", "targetmyradial" }),
        fire = Lines(CS, { "openfire", "engaging", "prosecuting", "contactconfirmprosecuting", "goactiveintercept" }),
        fight = Lines(CS, { "overwatchrequestreinforcement", "displace", "displace2", "cover", "coverhurt", "requestmedical", "ripcordripcord",
            "heavyresistance", "sectorisnotsecure", "infected", "outbreak", "targetineffective" }),
        down = Lines(CS, { "overwatchteamisdown", "onedown", "requestmedical", "overwatchrequestreinforcement" }),
    },
    folk = {
        male = Lines("vo/npc/male01/", { "runforyourlife01", "runforyourlife02", "help01", "watchout", "ohno", "uhoh", "gethellout", "startle01", "startle02" }),
        female = Lines("vo/npc/female01/", { "runforyourlife01", "runforyourlife02", "help01", "watchout", "ohno", "uhoh", "gethellout", "startle01", "startle02" }),
    },
}
local hasSound = {}
local function Has(path)
    if hasSound[path] == nil then hasSound[path] = (not file.Exists) or file.Exists("sound/" .. path, "GAME") end
    return hasSound[path]
end
local function Pick(list)
    local ok = {}
    for _, p in ipairs(list or {}) do if Has(p) then ok[#ok + 1] = p end end
    return ok[math.random(math.max(1, #ok))]
end
local function VoiceOf(n) return n.GetClass and n:GetClass() == "npc_combine_s" and "soldier" or "cop" end
-- One of the Combine's units says something (kind: lurk, rush, fire, fight, down), radio click first.
local function Chatter(n, kind)
    if not cvMingeChatter:GetBool() or not IsValid(n) then return false end
    local v = CHATTER[VoiceOf(n)]
    local line = Pick(v[kind])
    if not line then return false end
    local click = Pick(v.on)
    if click then n:EmitSound(click, 75, 100, 0.7) end
    timer.Simple(click and 0.25 or 0, function() if IsValid(n) then n:EmitSound(line, 80, 100, 0.85) end end)
    E.chatterLog = E.chatterLog or {}
    E.chatterLog[#E.chatterLog + 1] = line
    return true
end
local function Speaker()
    local list = {}
    for _, n in ipairs(E.combine or {}) do if IsValid(n) then list[#list + 1] = n end end
    return list[math.random(math.max(1, #list))]
end
local function Scream(c)
    if not IsValid(c) then return end
    local female = string.find(string.lower(c.GetModel and c:GetModel() or ""), "female", 1, true)
    local line = Pick(CHATTER.folk[female and "female" or "male"])
    if line then c:EmitSound(line, 80, math.random(96, 106)) end
end

-- The Combine open fire once the mingebags leap: each unit turns on the
-- nearest one and shoots (time is stopped for them otherwise: this is them).
local GUNS = {
    weapon_ar2 = { sound = "Weapon_AR2.NPC_Single", tracer = "AR2Tracer", dmg = 8, num = 1, spread = 0.04, gap = { 0.1, 0.22 } },
    weapon_smg1 = { sound = "Weapon_SMG1.NPC_Single", tracer = "Tracer", dmg = 5, num = 1, spread = 0.05, gap = { 0.08, 0.18 } },
    weapon_pistol = { sound = "Weapon_Pistol.NPC_Single", tracer = "Tracer", dmg = 8, num = 1, spread = 0.04, gap = { 0.3, 0.55 } },
    weapon_shotgun = { sound = "Weapon_Shotgun.NPC_Single", tracer = "Tracer", dmg = 6, num = 7, spread = 0.09, gap = { 0.8, 1.1 } },
}
local function Shoot(n, now, list, hurt)
    local best, bd
    for _, m in ipairs(list or E.minges or {}) do
        if IsValid(m) then
            local d = m:GetPos():DistToSqr(n:GetPos())
            if d < 1800 * 1800 and (not bd or d < bd) then best, bd = m, d end
        end
    end
    if not best then return false end
    local wep = n.GetActiveWeapon and n:GetActiveWeapon()
    local cls = IsValid(wep) and wep:GetClass() or ""
    if not GUNS[cls] and n.Give and not n.lcGivenGun then -- (a stunstick won't do: a pistol, then; once, never one a shot)
        n.lcGivenGun = true
        n:Give("weapon_pistol")
        if n.SelectWeapon then n:SelectWeapon("weapon_pistol") end
        wep = n.GetActiveWeapon and n:GetActiveWeapon()
        cls = IsValid(wep) and wep:GetClass() or "weapon_pistol"
    end
    local G = GUNS[cls] or GUNS.weapon_pistol
    n.lcNextShot = now + math.Rand(G.gap[1], G.gap[2])
    local aimAt = best:GetPos() + Vector(0, 0, 40)
    n:SetAngles(Angle(0, (aimAt - n:GetPos()):Angle().y, 0))
    local src = n:GetPos() + Vector(0, 0, 50) + n:GetForward() * 20
    if IsValid(wep) and wep.LookupAttachment then
        local id = wep:LookupAttachment("muzzle")
        local at = id and id > 0 and wep:GetAttachment(id)
        if at and at.Pos then src = at.Pos end
    end
    n:EmitSound(G.sound, 78, math.random(96, 104), 0.45) -- (under the song, not over it)
    if n.FireBullets then
        n:FireBullets({ Attacker = n, Inflictor = IsValid(wep) and wep or n, Num = G.num, Src = src, Dir = (aimAt - src):GetNormalized(),
            Spread = Vector(G.spread, G.spread, 0), Tracer = 1, TracerName = G.tracer, Force = 2, Damage = G.dmg, IgnoreEntity = n })
    elseif math.random() < 0.6 then
        (hurt or LC.MingeHurt)(best, { GetDamage = function() return G.dmg * G.num end })
    end
    E.shots = (E.shots or 0) + 1
    return true
end

LC.EndingChatter = function(kind) if E then return Chatter(Speaker(), kind) end end

SETUP.harpies = function()
    E.minges, E.bodies = {}, {}
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (LC.SupplyDropSpot and LC.SupplyDropSpot()) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.holdUntil = CurTime() + cvMingeEnd:GetFloat()
    if LC.OpenEveryDoor and not E.dream then LC.OpenEveryDoor() E.doorsOpen = true end -- (every door locked open: nothing stuck behind one, them or us)
    -- everyone to the landing zone, facing out into the dark
    local ps = LC.EndingPlayers()
    local taken = {}
    local pspots = RingSpots(E.lz, 60, #ps, taken)
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        local a = pspots[i].a
        p:SetPos(pspots[i].pos + Vector(0, 0, 4))
        if p.SetEyeAngles then p:SetEyeAngles(Angle(0, math.deg(a), 0)) end
        if p:Health() < 100 then p:SetHealth(100) end
    end
    -- the city stops, and the Combine's units are out there with everyone, in a ring round them
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    -- the city's people stand with them (never the Resistance), between everyone and the Combine
    E.folk = {}
    local folk = CityFolk()
    for i = #folk + 1, cvMingeCrowd:GetInt() do folk[#folk + 1] = i end -- (the rest: citizens, spawned below)
    local fspots = RingSpots(E.lz, 120 + 12 * #ps, #folk, taken, 0.15)
    local outerR = 0
    for _, sp in ipairs(fspots) do outerR = math.max(outerR, (sp.pos - E.lz):Length2D()) end
    E.ringR = math.max(210 + 12 * #ps, outerR + RING_GAP)
    E.combine = GatherCombine(E.lz, E.ringR, taken)
    for _, n in ipairs(E.combine) do n.lcRing = true end
    for i, c in ipairs(folk) do
        local a = fspots[i].a
        local spot = fspots[i].pos + Vector(0, 0, 4)
        if type(c) == "number" then c = SpawnFolk(spot, c) elseif IsValid(c) then c:SetPos(spot) end
        if IsValid(c) then
            c:SetAngles(Angle(0, math.deg(a), 0))
            c.lcRing = true
            E.folk[#E.folk + 1] = c
        end
    end
    -- and every light in the city goes out
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = true end
    if LC.ForceBlackout and not E.dream then LC.ForceBlackout("on") end
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
end

TICK.harpies = function(now)
    local t = now - E.phaseT
    local swell, fin = cvMingeSwell:GetFloat(), cvMingeEnd:GetFloat()
    local living = Living()
    -- who they go for: the Combine's units first (they're the ones shooting),
    -- then the city's people, and only then the players
    local targets = {}
    for _, n in ipairs(E.combine or {}) do if IsValid(n) then targets[#targets + 1] = n end end
    if #targets == 0 then for _, c in ipairs(E.folk or {}) do if IsValid(c) then targets[#targets + 1] = c end end end
    if #targets == 0 then for _, p in ipairs(living) do targets[#targets + 1] = p end end
    local tier = targets[1] and (targets[1]:IsPlayer() and 3 or (table.HasValue(E.combine or {}, targets[1]) and 1 or 2)) or 3
    local centre = E.lz
    local mode = t < swell and "lurk" or (t < swell + RUSH and "rush" or "leap")
    local firing = t >= swell + RUSH - 3 -- (the Combine open fire first: that's what sets them off)
    local noclip = t >= fin - 10
    local k = math.Clamp(t / swell, 0, 1)
    local far = 2400 - 1800 * k -- (how far off they keep: closer as the song goes on)
    if E.dream and LC.DreamRadius then far = math.min(far, LC.DreamRadius(E.dream) * 0.85) end -- (a dream: inside it)
    E.vulnerable = t >= swell - 10
    local was = E.mode
    E.mode = mode

    if mode == "leap" and was ~= "leap" then E.leapAt = now end
    -- the Combine's radios, out loud: what they see out there, then contact, then the order to fire, then the fight
    if firing and not E.fireOrdered then
        E.fireOrdered = true
        E.client = E.client or {}
        E.client.loud = true -- (the song up over the gunfire)
        Send()
        local a, b = Speaker(), Speaker()
        Chatter(a, "fire")
        if b ~= a then timer.Simple(0.9, function() if E then Chatter(b, "fire") end end) end
        for _, p in ipairs(LC.EndingPlayers()) do p:ChatPrint("[Civil Protection] \"All Civil Protection units, open fire! Take them down!\"") end
        E.nextChatter = now + math.Rand(2.5, 3.5)
        for _, c in ipairs(E.folk or {}) do if math.random() < 0.5 then timer.Simple(math.Rand(0, 1.5), function() Scream(c) end) end end
    elseif mode == "rush" and was ~= "rush" then
        Chatter(Speaker(), "rush")
        E.nextChatter = now + math.Rand(2.5, 4)
        for _, c in ipairs(E.folk or {}) do if math.random() < 0.3 then timer.Simple(math.Rand(0.5, 3), function() Scream(c) end) end end
    elseif now >= (E.nextChatter or (E.phaseT + 6)) then
        local kind = mode == "lurk" and (k < 0.55 and "lurk" or "closing") or (firing and "fight" or "rush")
        Chatter(Speaker(), kind)
        E.nextChatter = now + (mode == "lurk" and math.Rand(7, 12) or (mode == "rush" and math.Rand(2.5, 4) or math.Rand(2, 3.5)))
    end
    -- the Combine open fire, a moment before the leaping (and keep firing)
    if firing then
        for _, n in ipairs(E.combine or {}) do
            if IsValid(n) and now >= (n.lcNextShot or 0) then Shoot(n, now, E.minges, LC.MingeHurt) end
        end
    end

    -- gather: a handful at first, a crowd by the swell, replaced as fast as they fall after it
    local alive = {}
    for _, m in ipairs(E.minges) do if IsValid(m) then alive[#alive + 1] = m end end
    E.minges = alive
    local want = mode == "lurk" and math.floor(4 + (cvMingeMax:GetInt() - 4) * k ^ 1.3) or cvMingeMax:GetInt()
    if #E.minges < want and now >= (E.nextSpawn or 0) then
        E.nextSpawn = now + (mode == "lurk" and 0.4 or 0.1)
        local g, a = RingSpot(centre, mode == "lurk" and far or 900, mode == "lurk" and k < 0.6)
        -- (only somewhere it can get to everyone from on foot: never shut away behind a wall)
        if g and (E.dream or not LC.NavReachable or LC.NavReachable(g, centre)) then SpawnMinge(g, a) end -- (a dream: out of the map, no paths there)
    end

    for i, m in ipairs(E.minges) do
        local s = m.lcMinge
        local pos = m:GetPos()
        s.noclip = noclip
        local near, nd = Nearest(pos, living)
        local face = (near and near:GetPos()) or centre
        m:SetAngles(Angle(0, (face - pos):Angle().y, 0))
        if mode == "lurk" then
            -- keep their distance, at the edge of the dark, a little bolder all the time
            s.speed = 40 + 160 * k
            if not s.goal or (pos:DistToSqr(s.goal) < 30 * 30 and now >= (s.rest or 0)) or math.abs((s.ringD or far) - far) > 250 then
                local g, a = RingSpot(centre, far, k < 0.6, s.angle)
                if g then s.goal, s.angle, s.ringD = g, a, far end
                s.rest = now + math.Rand(2, 6)
            end
            if (s.stuck or 0) > 3 then
                -- (stuck against a wall with no way round: somewhere else on the edge of the dark)
                local g2 = RingSpot(centre, far, false, s.angle)
                if g2 then m:SetPos(g2) s.stuck, s.path = 0, nil end
            end
            if near and nd < far * 0.5 then
                -- someone walks up to one: it backs away into the dark
                s.goal = pos + (pos - near:GetPos()):GetNormalized() * 500
                s.speed = 260 - 120 * k
                s.rest = now + 3
            end
        else
            -- each has someone (shared out evenly: players and the Combine's units) and a place round them
            if not IsValid(s.target) or s.target.lcEndTaken or (s.tier or 0) < tier then
                s.target = #targets > 0 and targets[(i - 1) % #targets + 1] or nil
                s.tier = tier
                -- (their place on the ring: the nearest point to where they are, so none cuts across it)
                local off = pos - centre
                s.slot = math.atan2(off.y, off.x) + math.Rand(-0.15, 0.15)
                s.ring = math.floor((i - 1) / 24)
            end
            local tp = IsValid(s.target) and s.target:GetPos()
                or (#E.bodies > 0 and IsValid(E.bodies[#E.bodies]) and E.bodies[#E.bodies]:GetPos()) or centre
            if mode == "rush" then
                -- round the outside of the ring, shoulder to shoulder, never inside it until they leap
                local out = (E.ringR or 250) + 70 + 36 * (s.ring or 0)
                s.goal = centre + Vector(math.cos(s.slot), math.sin(s.slot), 0) * out
                s.speed = 650
            elseif not s.leap and now >= (s.nextLeap or 0) then
                local d = pos:Distance(tp)
                if d < 520 and (noclip or Clear(pos, tp)) then
                    local dur = 0.3 + d / 1500
                    s.leap = { from = pos, to = tp + Vector(math.Rand(-15, 15), math.Rand(-15, 15), 0), t0 = now, dur = dur, h = 30 + d * 0.18 }
                    s.nextLeap = now + dur + math.Rand(0.15, 0.7)
                else
                    s.goal, s.speed = tp, noclip and 700 or 520
                end
            end
            -- stuck behind something (before the walls stop mattering): around the other way, out of sight
            if not noclip and (s.stuck or 0) > 2.5 and IsValid(s.target) then
                local g = RingSpot(tp, 350, false)
                if g and Clear(g, tp) then m:SetPos(g) s.stuck, s.path = 0, nil end
            end
        end
    end

    -- the last two seconds: nobody's left
    if t >= fin - 2 then
        for _, p in ipairs(living) do Slaughter(p, "There's nowhere left. The mingebags got you.") end
        for _, n in ipairs(E.combine or {}) do if IsValid(n) then Body(n:GetModel(), n:GetPos(), n:GetAngles().y, 260) n:Remove() end end
        for _, c in ipairs(E.folk or {}) do if IsValid(c) then Body(c:GetModel(), c:GetPos(), c:GetAngles().y, 260) c:Remove() end end
    end
    -- the dead keep watching someone
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.lcEndSpectating and not p.lcEndRoam and (not IsValid(p.lcEndWatching) or p.lcEndWatching.lcEndTaken) then Watch(p, 1) end
    end
    -- (anything that doesn't move itself every tick, moves here)
    for _, m in ipairs(E.minges) do if IsValid(m) and not m.lcThinks then LC.MingeStep(m, 0.1) end end
end

-- The dead watching: left and right click, someone else; jump, fly free.
local function EndKey(p, key)
    if not E or not p.lcEndSpectating then return end
    -- (it comes from the key event or from the polling below, whichever's first: once)
    p.lcEndKeyT = p.lcEndKeyT or {}
    local now = CurTime()
    if now - (p.lcEndKeyT[key] or -1) < 0.3 then return end
    p.lcEndKeyT[key] = now
    if key == IN_ATTACK then Watch(p, 1)
    elseif key == IN_ATTACK2 then Watch(p, -1)
    elseif key == IN_JUMP then
        p.lcEndRoam = not p.lcEndRoam
        if p.Spectate then p:Spectate(p.lcEndRoam and OBS_MODE_ROAM or OBS_MODE_CHASE) end
        if p.lcEndRoam and p.SetMoveType and MOVETYPE_OBSERVER then p:SetMoveType(MOVETYPE_OBSERVER) end -- (free to fly)
        if not p.lcEndRoam then Watch(p, 0) end
    end
end
LC.EndingKey = EndKey
hook.Add("KeyPress", "LivingCityEndingWatch", EndKey)
-- (and polled, in case something else ate the key event: the dead's controls always work)
function LC.EndingPollKeys()
    if not E then return end
    local KEYS = {}
    for _, k in pairs({ IN_ATTACK or false, IN_ATTACK2 or false, IN_JUMP or false }) do if k then KEYS[#KEYS + 1] = k end end
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.lcEndSpectating and p.KeyDown then
            p.lcEndKeyWas = p.lcEndKeyWas or {}
            for _, k in ipairs(KEYS) do
                local down = p:KeyDown(k) and true or false
                if down and not p.lcEndKeyWas[k] then EndKey(p, k) end
                p.lcEndKeyWas[k] = down
            end
        end
    end
end

-- Bloom: everyone dances (players, and every NPC in the city), and nobody
-- can stop. The city dims, coloured light pulses on the beat, the props
-- hop. At lc_ending_bloom_speedup (2:01) the song starts speeding up; at the
-- top of it, the dancers spin up into the sky one at a time and burst.
-- (The song's own name stays out of everything players can see: the file
-- is endings/bloom.mp3.)
local cvBloomBPM     = CreateConVar("lc_ending_bloom_bpm", "165", FLAGS, "Bloom: the song's beats per minute (the dance keeps to it)")
local cvBloomOffset  = CreateConVar("lc_ending_bloom_offset", "0", FLAGS, "Bloom: seconds into the song of its first beat")
local cvBloomSpeedup = CreateConVar("lc_ending_bloom_speedup", "121", FLAGS, "Bloom: seconds into the song when it starts speeding up")
local cvBloomRamp    = CreateConVar("lc_ending_bloom_ramp", "20", FLAGS, "Bloom: seconds it takes to reach top speed")
local cvBloomPeak    = CreateConVar("lc_ending_bloom_peak", "1.6", FLAGS, "Bloom: top speed (1.6: 60% faster, and higher, like a record spun up)")
local cvBloomWindow  = CreateConVar("lc_ending_bloom_launch_secs", "16", FLAGS, "Bloom: seconds over which everyone spins up into the sky, one at a time, once it's at top speed")

local function Dancers()
    local out = {}
    for npc in pairs(LC.EndingNPCs()) do if IsValid(npc) then out[#out + 1] = npc end end
    return out
end

SETUP.bloom = function()
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = "e" end -- (dim, so the coloured light shows)
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    -- the city stops what it's doing...
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    -- ...gathers at the landing zone (the Combine's units round everyone)...
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    local ps = LC.EndingPlayers()
    local taken = {}
    local pspots = RingSpots(E.lz, 70, #ps, taken)
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p:SetPos(pspots[i].pos) -- (frozen, nobody drops: on the floor, not over it)
    end
    GatherCombine(E.lz, 150 + 14 * #ps, taken)
    -- ...and dances
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p.lcEndFrozen = true -- (so a cancel lets them go again)
        p:Freeze(true)
        p:SetNW2Bool("lc_dancing", true)
    end
    for _, n in ipairs(Dancers()) do n:SetNW2Bool("lc_dancing", true) end
    -- the props near anyone hop along
    local props, seen = {}, {}
    for _, p in ipairs(LC.EndingPlayers()) do
        for _, e in ipairs(ents.FindInSphere(p:GetPos(), 900)) do
            local c = IsValid(e) and e:GetClass() or ""
            if not seen[e] and #props < 48 and (c == "prop_physics" or c == "prop_dynamic" or c == "prop_physics_multiplayer") then
                seen[e] = true
                props[#props + 1] = e:EntIndex()
            end
        end
    end
    local now = CurTime()
    E.client = { party = true, lights = true, overlay = "bloom", dance = "ears", bpm = cvBloomBPM:GetFloat(), offset = cvBloomOffset:GetFloat(), start = now,
        rateAt = now + cvBloomSpeedup:GetFloat(), rateDur = math.max(1, cvBloomRamp:GetFloat()), peak = math.max(1, cvBloomPeak:GetFloat()),
        props = props }
    E.climax = E.client.rateAt + E.client.rateDur
    E.launchGap = math.Clamp(cvBloomWindow:GetFloat() / math.max(1, #LC.EndingPlayers()), 0.6, 3)
    E.holdUntil = E.climax + math.max(cvBloomWindow:GetFloat(), E.launchGap * #LC.EndingPlayers()) + 5 -- (the last one up, and a moment)
    E.launching = {}
end

-- One dancer spins up into the sky, and bursts.
local PALETTE_BLOOM = { { 255, 110, 200 }, { 220, 90, 255 }, { 100, 190, 255 }, { 110, 255, 190 }, { 255, 235, 110 } }
local function Launch(e, now)
    if not IsValid(e) or e.lcBloomUp then return end
    e.lcBloomUp = { t0 = now, from = e:GetPos() }
    e:SetNW2Float("lc_spin_t0", now)
    if e:IsPlayer() then e:SetMoveType(MOVETYPE_NONE) end
    E.launching[#E.launching + 1] = e
end

TICK.bloom = function(now)
    if now >= (E.climax or math.huge) then
        -- the players, one at a time
        if now >= (E.nextLaunch or 0) then
            E.nextLaunch = now + E.launchGap
            local pick = {}
            for _, p in ipairs(Living()) do if not p.lcBloomUp then pick[#pick + 1] = p end end
            if #pick > 0 then Launch(pick[math.random(#pick)], now) end
        end
        -- and the city's own dancers, a few at a time
        if now >= (E.nextNPCLaunch or 0) then
            E.nextNPCLaunch = now + 0.25
            for _, n in ipairs(Dancers()) do if not n.lcBloomUp then Launch(n, now) break end end
        end
    end
    local keep = {}
    for _, e in ipairs(E.launching) do
        local u = IsValid(e) and e.lcBloomUp
        if u then
            local t = now - u.t0
            e:SetPos(u.from + Vector(0, 0, 40 * t + 70 * t * t)) -- (about 500 up when it bursts: low enough for everyone to see it)
            if t >= 2.5 then
                -- the burst: a flash of energy and a shower of confetti in every colour, big enough to see from the ground
                if util.Effect and EffectData then
                    local at = e:GetPos() + Vector(0, 0, 40)
                    local fx = EffectData()
                    fx:SetOrigin(at)
                    util.Effect("cball_explode", fx)
                    for i = 1, 14 do
                        local c = PALETTE_BLOOM[i % #PALETTE_BLOOM + 1]
                        local cf = EffectData()
                        cf:SetOrigin(at + VectorRand() * 70)
                        if cf.SetStart then cf:SetStart(Vector(c[1], c[2], c[3])) end
                        util.Effect("balloon_pop", cf)
                    end
                end
                e:EmitSound("garrysmod/balloon_pop_cute.wav", 100)
                if sound and sound.Play then sound.Play("weapons/flaregun/burn.wav", e:GetPos(), 95, 140, 0.7) end
                if e:IsPlayer() then
                    if e.SetNoDraw then e:SetNoDraw(true) end
                    Spectator(e, "You spin up into the sky and burst into sparkles. Watch the rest go.", Color(255, 150, 210, 70))
                else
                    e:Remove()
                end
            else
                keep[#keep + 1] = e
            end
        end
    end
    E.launching = keep
end

-- Marrow: skeletons. Everyone (the Combine's units too) is put at the
-- landing zone and the city dims; skeletons appear dancing all over the map
-- and work their way in. The song's sections decide the rest
-- (lc_ending_marrow_sections): on the heavy parts everyone is made to dance
-- with them, a club, strobing (the rave part faster); in between, the
-- skeletons attack, and whoever they get becomes one of them, dancing for
-- good; at the outro they claim whoever's left.
local cvMarrowSections = CreateConVar("lc_ending_marrow_sections", "45:dance,75:attack,82:rave,112:attack,150:dance,180:attack,188:dance,217:outro,232:end", FLAGS,
    "Marrow: the song's sections, second:kind (dance, rave, attack, outro, end); before the first, the skeletons gather")
local cvMarrowMax   = CreateConVar("lc_ending_marrow_max", "80", FLAGS, "Marrow: how many skeletons at the most (their numbers build to it by about two thirds of the way through the song)")
local cvMarrowBPM   = CreateConVar("lc_ending_marrow_bpm", "128", FLAGS, "Marrow: the song's beats per minute (the dancing and the lights keep to it)")
local cvMarrowModel = CreateConVar("lc_ending_marrow_model", "models/player/skeleton.mdl", FLAGS, "Marrow: the skeletons' model")
local cvMarrowCrowd = CreateConVar("lc_ending_marrow_crowd", "10", FLAGS, "Marrow: how many of the city's people are at the landing zone with everyone (its own NPCs first, topped up with citizens)")
local SPOOKY = { { 170, 60, 255 }, { 255, 130, 20 } } -- (purple and orange)
local DANCING = { dance = true, rave = true, outro = true }

function LC.MarrowSections(str)
    local out = {}
    for t, kind in string.gmatch(str or cvMarrowSections:GetString(), "([%d%.]+)%s*:%s*(%a+)") do out[#out + 1] = { t = tonumber(t), kind = string.lower(kind) } end
    table.sort(out, function(x, y) return x.t < y.t end)
    return out
end

local function SectionAt(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function SpawnSkel(pos)
    if not Room() then return nil end
    local k = ents.Create("lc_skel")
    if not IsValid(k) then return nil end
    k.lcModel = cvMarrowModel:GetString()
    k:SetModel(k.lcModel)
    k:SetPos(pos)
    k:Spawn()
    k.lcSkel = { hp = 100, phase = "walk", untilT = CurTime() + math.Rand(3, 6) } -- (tough: the Combine's units don't mow them down)
    E.ents[#E.ents + 1] = k
    E.skels[#E.skels + 1] = k
    return k
end

local function Anim(m, name)
    local s = m.lcSkel
    if s.anim == name or not m.LookupSequence then return end
    s.anim = name
    local seq = m:LookupSequence(name)
    if seq and seq >= 0 then m:ResetSequence(seq) if m.SetPlaybackRate then m:SetPlaybackRate(1) end end
end

-- Got by a skeleton: you're one of them now, dancing for good.
local function Convert(p, how)
    if not IsValid(p) or p.lcEndTaken then return end
    p.lcEndTaken = true
    p.lcEndModel = p.lcEndModel or p:GetModel()
    p:SetModel(cvMarrowModel:GetString())
    p:SetNW2Bool("lc_end_taken", true)
    p.lcEndFrozen = true
    p:Freeze(true)
    p:SetNW2Bool("lc_dancing", true)
    if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(90, 255, 120, 200), 1.5, 0) end
    p:ChatPrint(how or "The skeletons got you. You're one of them now. Dance.")
    hook.Run("LivingCityEndingTook", p, E and E.id)
end

-- A unit of the Combine caught: a skeleton where it stood.
local function Bones(npc)
    if not IsValid(npc) then return end
    local pos = npc:GetPos()
    npc:Remove()
    local k = SpawnSkel(pos)
    if k then k:SetNW2Bool("lc_dancing", DANCING[E.section] or false) end
end

-- The skeletons never get faster (you can always outrun one: faster than a
-- walk, slower than a run) or harder: there are just more and more of them,
-- 15 at first and the full lc_ending_marrow_max by about two thirds of the way
-- through, and each one claws on its own, so a crowd of them is the end of you.
local SKEL_SPEED = 160
function LC.MarrowCount(t)
    local len = E and E.holdUntil and E.phaseT and (E.holdUntil - E.phaseT) or 232
    local k = math.Clamp((t or 0) / (len * 0.62), 0, 1) ^ 2
    local max = cvMarrowMax:GetInt()
    return math.floor(math.min(max, 15) + (max - math.min(max, 15)) * k)
end

local function Claw(target, k)
    local now = CurTime()
    if not IsValid(target) or not IsValid(k) or now < (k.lcClawAt or 0) then return end
    k.lcClawAt = now + 0.8 -- (each skeleton on its own: the more of them on you, the worse)
    target:EmitSound("npc/zombie/claw_strike" .. math.random(1, 3) .. ".wav", 75)
    target:SetHealth(target:Health() - math.random(4, 6))
    if target:IsPlayer() then
        if target.ViewPunch then target:ViewPunch(Angle(math.Rand(-8, 8), math.Rand(-8, 8), 0)) end
        if target:Health() <= 0 then Convert(target) end
    elseif target:Health() <= 0 then
        Bones(target)
    end
end

-- One step of a skeleton (each server tick: lc_skel.lua).
function LC.SkelStep(m, dt)
    local s = m.lcSkel
    if not s or not E or E.id ~= "marrow" then return end
    local pos = m:GetPos()
    if not s.goal or m:GetNW2Bool("lc_dancing", false) then Anim(m, "idle_all_01") return end
    local to = s.goal - pos
    to.z = 0
    local dist = to:Length()
    if dist < 6 then Anim(m, "idle_all_01") return end
    Anim(m, (s.speed or 0) > 130 and "run_all_01" or "walk_all")
    local dir = to * (1 / dist)
    local step = math.min(dist, (s.speed or 100) * (dt or 0.1))
    local nextPos = pos + dir * step
    if not Clear(pos, nextPos + dir * 16) then
        local found
        for _, turn in ipairs({ 50, -50, 90, -90 }) do
            local a = dir:Angle()
            a.y = a.y + turn
            local alt = pos + a:Forward() * step
            if Clear(pos, alt + a:Forward() * 16) then nextPos, found = alt, true break end
        end
        if not found then s.stuck = (s.stuck or 0) + (dt or 0.1) return end
    end
    s.stuck = 0
    local g = Ground(nextPos)
    if g and math.abs(g.z - pos.z) < 60 then nextPos.z = g.z end
    m:SetPos(nextPos)
    m:SetAngles(Angle(0, dir:Angle().y, 0))
end

-- Hurt: only in a fight (dancing, they're untouchable); down it goes, and another comes later.
function LC.SkelHurt(m, dmg)
    local s = m.lcSkel
    if not s or not E or E.section ~= "attack" then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 40)
    if s.hp > 0 then return false end
    Body(m:GetModel(), m:GetPos(), m:GetAngles().y, 100)
    m:EmitSound("physics/wood/wood_box_break" .. math.random(1, 2) .. ".wav", 75)
    m:Remove()
    E.nextSpawn = CurTime() + 3
    return true
end

local function ApplySection(kind, now)
    E.section = kind
    local dancing = DANCING[kind] or false
    E.client.lights = true -- (purple and orange, all the way through)
    E.client.strobe = kind == "dance" or kind == "rave"
    E.client.dance = kind == "rave" and "rave" or "club"
    E.client.danceRate = (kind == "rave" and 1.5) or (kind == "outro" and 2) or 1 -- (the xylophone outro: double time)
    E.client.loud = kind == "attack" -- (the song up over the gunfire in a fight)
    E.client.section = kind
    E.client.spots = dancing -- (the spotlights round the circle, while everyone dances)
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.lcEndTaken then
            p:SetNW2Bool("lc_dancing", true)
        elseif dancing then
            p.lcEndFrozen = true
            p:Freeze(true)
            p:SetNW2Bool("lc_dancing", true)
        else
            p.lcEndFrozen = nil
            p:Freeze(false)
            p:SetNW2Bool("lc_dancing", false)
        end
    end
    for _, n in ipairs(CombineNPCs()) do n:SetNW2Bool("lc_dancing", dancing) end
    for _, c in ipairs(E.folk or {}) do if IsValid(c) then c:SetNW2Bool("lc_dancing", dancing) end end
    for _, k in ipairs(E.skels) do
        if IsValid(k) then
            k:SetNW2Bool("lc_dancing", dancing)
            if dancing then k.lcSkel.goal = nil end
        end
    end
    if kind == "attack" then
        local a = Speaker()
        Chatter(a, "fire")
        E.nextChatter = now + math.Rand(2, 3)
    end
    if kind == "outro" then
        for _, p in ipairs(Living()) do Convert(p, "The skeletons claim everyone in the end. You're one of them now. Dance it out.") end
        for _, n in ipairs(CombineNPCs()) do Bones(n) end
        for _, c in ipairs(E.folk or {}) do Bones(c) end
    end
    Send()
end

SETUP.marrow = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.skels = {}
    E.sections = LC.MarrowSections()
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 232)
    if LC.OpenEveryDoor and not E.dream then LC.OpenEveryDoor() E.doorsOpen = true end -- (every door locked open: nothing stuck behind one, them or us)
    -- the city stops; everyone (the Combine's units too) to the landing zone; the lights dim
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    local ps = LC.EndingPlayers()
    local taken = {}
    local pspots = RingSpots(E.lz, 60, #ps, taken)
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p:SetPos(pspots[i].pos + Vector(0, 0, 4))
        if p:Health() < 100 then p:SetHealth(100) end
    end
    -- the city's people with everyone, between the players and the Combine (never the Resistance)
    E.folk = {}
    local folk = CityFolk()
    for i = #folk + 1, cvMarrowCrowd:GetInt() do folk[i] = i end
    while #folk > cvMarrowCrowd:GetInt() do table.remove(folk) end
    local fspots = RingSpots(E.lz, 80 + 12 * #ps, #folk, taken, 0.15)
    E.combine = GatherCombine(E.lz, 100 + 12 * #ps, taken)
    for _, n in ipairs(E.combine) do n.lcRing = true end
    for i, c in ipairs(folk) do
        local a = fspots[i].a
        local spot = fspots[i].pos
        if type(c) == "number" then c = SpawnFolk(spot, c) elseif IsValid(c) then c:SetPos(spot) end
        if IsValid(c) then
            c:SetAngles(Angle(0, math.deg(a), 0))
            c.lcRing = true
            E.folk[#E.folk + 1] = c
        end
    end
    -- the first of them already there, in plain sight round everyone, dancing
    for _ = 1, 10 do
        local g = RingSpot(E.lz, math.Rand(350, 650), false)
        if g then
            local k = SpawnSkel(g)
            if k then k:SetNW2Bool("lc_dancing", true) end
        end
    end
    -- the map goes dark (every lamp out), and the coloured light pulses everywhere
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = true end
    if LC.ForceBlackout and not E.dream then LC.ForceBlackout("on") end
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    E.client = { party = true, lights = true, ambient = true, dance = "club", palette = SPOOKY, bpm = cvMarrowBPM:GetFloat(), offset = 0, start = now,
        lz = E.lz, spotR = 260 + 12 * #ps }
    E.section = "intro"
end

TICK.marrow = function(now)
    local t = now - E.phaseT
    local kind = SectionAt(t)
    if kind ~= E.section and kind ~= "end" then ApplySection(kind, now) end
    local alive = {}
    for _, k in ipairs(E.skels) do if IsValid(k) then alive[#alive + 1] = k end end
    E.skels = alive
    -- more of them, all over the map at first
    local want = LC.MarrowCount(t)
    if #E.skels < want and now >= (E.nextSpawn or 0) then
        E.nextSpawn = now + (E.section == "intro" and 0.2 or 0.4)
        -- a few at a time; far off if there's room, closer in where the map's cramped, and
        -- in a fight, round whoever's still standing, on every side
        local living = Living()
        for _ = 1, math.min(3, want - #E.skels) do
            local g
            local near = E.section == "attack" and #living > 0 and living[math.random(#living)]:GetPos() or E.lz
            for _, d in ipairs(E.section == "intro" and { math.Rand(350, 900), 550, 380 } or { 900, 650, 450 }) do
                g = RingSpot(near, d, false)
                if g then break end
            end
            if g then
                local k = SpawnSkel(g)
                if k then k:SetNW2Bool("lc_dancing", E.section == "intro" or DANCING[E.section] or false) end
            end
        end
    end
    -- who they go for: the nearest of you, or of the Combine's units
    local targets = {}
    for _, p in ipairs(Living()) do targets[#targets + 1] = p end
    for _, n in ipairs(E.combine or {}) do if IsValid(n) then targets[#targets + 1] = n end end
    for _, c in ipairs(E.folk or {}) do if IsValid(c) then targets[#targets + 1] = c end end
    -- and in a fight, the Combine shoot back (talking it through on their radios)
    if E.section == "attack" then
        for _, n in ipairs(E.combine or {}) do
            if IsValid(n) and now >= (n.lcNextShot or 0) then Shoot(n, now, E.skels, LC.SkelHurt) end
        end
        if now >= (E.nextChatter or 0) then
            Chatter(Speaker(), "fight")
            E.nextChatter = now + math.Rand(2, 3.5)
        end
    end
    for _, k in ipairs(E.skels) do
        local s = k.lcSkel
        if E.section == "intro" then
            -- the opening: they just dance, all round everyone, waiting for the drop
            s.goal = nil
            if not k:GetNW2Bool("lc_dancing", false) then k:SetNW2Bool("lc_dancing", true) end
        elseif E.section == "attack" then
            -- at whoever's nearest, and the claws
            local best, bd = nil, nil
            for _, p in ipairs(targets) do
                local d = p:GetPos():DistToSqr(k:GetPos())
                if not bd or d < bd then best, bd = p, d end
            end
            if best then
                s.goal, s.speed = best:GetPos(), SKEL_SPEED
                if bd < 60 * 60 then Claw(best, k) end
            end
            if (s.stuck or 0) > 1.5 and best then
                local g = RingSpot(best:GetPos(), 300, true)
                if g then k:SetPos(g) s.stuck = 0 end
            end
        end
        if not k.lcThinks then LC.SkelStep(k, 0.1) end
    end
end

-- flying things: a vehicle per group of riders, circling the city
local function Fly(models, perVehicle, height, speed, scale, secs)
    E.flights = {}
    E.flightSecs = secs
    local living = Living()
    local centre = Centre()
    local model = FirstModel(models)
    local groups = math.max(1, math.ceil(#living / perVehicle))
    for g = 1, groups do
        local riders = {}
        for i = (g - 1) * perVehicle + 1, math.min(#living, g * perVehicle) do riders[#riders + 1] = living[i] end
        local v = Prop(model, centre + Vector(0, 0, height), scale)
        if v then
            local offs = {}
            for i = 1, #riders do offs[i] = Vector((i - (#riders + 1) / 2) * 40, 0, 50) end
            Board(v, riders, offs)
            E.flights[#E.flights + 1] = { v = v, phase = (g - 1) / groups * math.pi * 2, height = height, speed = speed }
        end
    end
    E.centre = centre
    E.started = CurTime()
end

local function FlyTick(now)
    E.flight = E.flight or LC.EndingSky(E.centre)
    local r = E.flight.r
    for i, f in ipairs(E.flights or {}) do
        if IsValid(f.v) then
            local a = f.phase + (now - E.started) * f.speed
            local pos = Vector(E.flight.centre.x + math.cos(a) * r, E.flight.centre.y + math.sin(a) * r, E.flight.z - 120 + math.sin(a * 3 + i) * 100)
            f.v:SetPos(pos)
            f.v:SetAngles(Angle(math.sin(a * 2) * 12, math.deg(a) + 90, math.cos(a * 3) * 18))
        end
    end
    Ride(now)
    -- the ride lasts the song, more or less, and then nobody ever gets off
    if now - E.started > (E.flightSecs or 80) then
        for _, p in ipairs(Living()) do Take(p, "The ride doesn't stop. It never stops.") end
    end
end

-- The Bus: the party bus. It drives about the streets through the
-- song's intro; on the drop (lc_ending_bus_sections) everyone, and some of
-- the Combine's units, are in it, seated, and it takes off: through walls,
-- a rainbow behind it, its speed surging on the beat, rings to fly through,
-- the light inside pulsing. It comes down and drives again for a while,
-- then takes off faster still. Nobody gets off (die, and you're back on).
local cvBusSections = CreateConVar("lc_ending_bus_sections", "27:fly,149:drive,176:fast,220:end", FLAGS,
    "The Bus: the song's sections, second:kind (fly, drive, fast, end); before the first, it drives about the streets")
local cvBusBPM   = CreateConVar("lc_ending_bus_bpm", "138", FLAGS, "The Bus: the song's beats per minute (its speed and the lights keep to it)")
local cvBusCombine = CreateConVar("lc_ending_bus_combine", "6", FLAGS, "The Bus: how many of the Combine's Civil Protection units get on too")
local BUS = { "models/props_vehicles/bus01_2.mdl", "models/props_vehicles/van001a_physics.mdl" }
local RAINBOW = { { 255, 40, 40 }, { 255, 150, 30 }, { 255, 240, 40 }, { 60, 230, 80 }, { 60, 140, 255 }, { 170, 70, 255 } }
local RING = "models/hunter/tubes/tube4x4x025.mdl"

local function BusSection(t)
    local kind = "drive"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- A seat: rows down the bus, two across, and on top of each other when it's full.
local function Seat(i)
    local row, side, layer = (i - 1) % 8, math.floor((i - 1) / 8) % 2, math.floor((i - 1) / 16)
    return Vector(-140 + row * 40, side == 0 and -24 or 24, 18 + layer * 46)
end

local function BusBoard(e)
    if not IsValid(e) or e.lcEndRide then return end
    E.seats = (E.seats or 0) + 1
    e.lcEndRide = { v = E.bus, off = Seat(E.seats) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        HoldOn(e)
    end
    e:SetNW2Bool("lc_seated", true)
    e:SetNW2Bool("lc_dancing", true)
end

local function GroundSpot(near)
    for _ = 1, 8 do
        local a = math.Rand(0, math.pi * 2)
        local d = math.Rand(400, 1100)
        local g = Ground(near + Vector(math.cos(a) * d, math.sin(a) * d, 0))
        if not (E and E.dream) then return g or near end
        if g and (not LC.DreamHolds or LC.DreamHolds(E.dream, g)) then return g end -- (a dream: never out in the city)
    end
    return near
end

-- How high the sky is over a spot: up through any roof or floor in the way, to the
-- skybox itself (the bus flies through buildings, never up into the sky).
local function SkyZ(pos)
    -- (measured up from about the landing zone's level: from up in the sky itself, or inside
    -- a wall, there'd be no telling)
    local p = Vector(pos.x, pos.y, math.min(pos.z, (E and E.centre and E.centre.z or pos.z) + 64))
    for _ = 1, 24 do
        local tr = util.TraceLine({ start = p, endpos = p + Vector(0, 0, 16000), mask = MASK_SOLID_BRUSHONLY })
        if tr.StartSolid then p = p + Vector(0, 0, 64)
        elseif not tr.Hit then return p.z + 16000
        elseif tr.HitSky then return tr.HitPos.z
        else p = tr.HitPos + Vector(0, 0, 8) end
        if util.IsInWorld and not util.IsInWorld(p) then return p.z end
    end
    return p.z
end
-- (the bus sits on its wheels, not half in the road: its model's middle is its origin)
local function BusLift(bus)
    local lo = IsValid(bus) and bus.OBBMins and bus:OBBMins().z or 0
    return math.max(0, -lo) + 2
end

-- Somewhere to fly to: anywhere in the map's air, well away from where the bus
-- is, under the sky (so it roams about aimlessly, straight through whatever's
-- in the way).
local function SkySpot()
    E.flight = E.flight or LC.EndingSky(E.centre)
    local sky = E.flight
    local from = IsValid(E.bus) and E.bus:GetPos()
    local base = from or sky.centre
    local best, bestD
    for _ = 1, 30 do
        local a, d = math.Rand(0, math.pi * 2), math.Rand(600, sky.roam)
        local p = Vector(base.x + math.cos(a) * d, base.y + math.sin(a) * d, sky.z - math.Rand(0, 450))
        -- (well under the sky there, which may come lower than over the landing zone)
        local top = SkyZ(p - Vector(0, 0, 600))
        if top - 260 < p.z then p.z = top - 260 end
        if Open(p) and not (E.dream and LC.DreamHolds and not LC.DreamHolds(E.dream, p, true)) then
            if d >= 1200 then return p end
            if not bestD or d > bestD then best, bestD = p, d end
        end
    end
    if best then return best end
    local a = math.Rand(0, math.pi * 2)
    return Vector(sky.centre.x + math.cos(a) * sky.r, sky.centre.y + math.sin(a) * sky.r, sky.z)
end

local function NewRing(at, from)
    local ring = ents.Create("prop_dynamic")
    if not IsValid(ring) then return end
    ring:SetModel(RING)
    ring:SetPos(at)
    local dir = (at - from)
    ring:SetAngles(dir:Angle() + Angle(90, 0, 0)) -- (facing the way the bus comes)
    ring:Spawn()
    if ring.SetModelScale then ring:SetModelScale(1.7, 0) end
    if ring.SetSolid then ring:SetSolid(SOLID_NONE) end
    if ring.SetRenderMode then ring:SetRenderMode(RENDERMODE_TRANSCOLOR) end
    E.ents[#E.ents + 1] = ring
    E.rings[#E.rings + 1] = ring
end

SETUP.bus = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvBusSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 220)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.centre = (#lz > 0 and lz[1].pos) or Centre()
    E.rings = {}
    LC.TimeStopped = (not E.dream) or nil -- (the city stops and watches)
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    -- the bus, somewhere near people, on the road
    local near = (Living()[1] and Living()[1]:GetPos()) or E.centre
    local bus = Prop(FirstModel(BUS), GroundSpot(near))
    if not bus then return end
    bus:SetPos(bus:GetPos() + Vector(0, 0, BusLift(bus)))
    if bus.SetSolid then bus:SetSolid(SOLID_NONE) end
    E.bus = bus
    E.busDir = Vector(1, 0, 0)
    E.goal = GroundSpot(near)
    -- the rainbow behind it: a trail of each colour, one above the other
    for i, c in ipairs(RAINBOW) do
        local a = ents.Create("prop_dynamic")
        if IsValid(a) then
            a:SetModel("models/hunter/plates/plate.mdl")
            a:SetPos(bus:GetPos())
            a:Spawn()
            if a.SetNoDraw then a:SetNoDraw(true) end
            if a.SetSolid then a:SetSolid(SOLID_NONE) end
            a:SetParent(bus)
            if a.SetLocalPos then a:SetLocalPos(Vector(-230, 0, 20 + (#RAINBOW - i) * 14)) end
            if util.SpriteTrail then util.SpriteTrail(a, 0, Color(c[1], c[2], c[3]), true, 16, 4, 2.5, 1 / 20 * 0.5, "trails/laser.vmt") end
            E.ents[#E.ents + 1] = a
        end
    end
    E.client = { party = true, lights = true, dance = "bus", palette = RAINBOW, bpm = cvBusBPM:GetFloat(), offset = 0, start = now, bus = bus:EntIndex() }
    E.section = "intro"
end

local function BoardBus()
    for _, p in ipairs(LC.EndingPlayers()) do BusBoard(p) end
    local n = 0
    for _, npc in ipairs(CombineNPCs()) do
        if n >= cvBusCombine:GetInt() then break end
        n = n + 1
        BusBoard(npc)
    end
end

TICK.bus = function(now)
    local bus = E.bus
    if not IsValid(bus) then return end
    local t = now - E.phaseT
    local kind = BusSection(t)
    if kind ~= E.section then
        E.section = kind
        if kind == "fly" or kind == "fast" then
            E.boarded = true
            BoardBus()
            E.goal = SkySpot()
        else
            E.goal = GroundSpot(bus:GetPos())
        end
        E.client.strobe = kind == "fast"
        Send()
    end
    if E.boarded then for _, p in ipairs(LC.EndingPlayers()) do BusBoard(p) end end -- (someone just joining, or back from the dead)
    -- the speed, surging on the beat
    local beat = t * cvBusBPM:GetFloat() / 60
    local surge = 1 + 0.35 * math.abs(math.sin(beat * math.pi))
    local flying = E.section == "fly" or E.section == "fast"
    local speed = (flying and (E.section == "fast" and 1500 or 900) or 380) * (flying and surge or 1)
    local pos = bus:GetPos()
    local to = E.goal - pos
    if not flying then to.z = 0 end
    local dist = to:Length()
    -- reached it (within a couple of steps at this speed, or circling it too long: it'd orbit
    -- a spot it keeps overshooting), and on to the next
    E.goalSince = E.goalSince or now
    if E.lastGoal ~= E.goal then E.lastGoal, E.goalSince = E.goal, now end
    if dist < math.max(120, speed * 0.1 * 2.5) or (flying and now - E.goalSince > 6) then
        if flying then
            local from = E.goal
            E.goal = SkySpot()
            if #E.rings < 4 then NewRing(E.goal, from) end
        else
            E.goal = GroundSpot(pos)
        end
    else
        -- swing round towards it, not snap
        local want = to * (1 / dist)
        E.busDir = (E.busDir * 0.85 + want * 0.15):GetNormalized()
        local step = math.min(dist, speed * 0.1)
        local nextPos = pos + E.busDir * step
        if flying then
            -- straight through walls and buildings, but never up into the sky (you'd see
            -- nothing), down through the ground, or off the edge of the map
            local top = SkyZ(nextPos)
            if nextPos.z > top - 220 then nextPos.z = top - 220 end
            local fl = util.TraceLine({ start = nextPos, endpos = nextPos - Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
            if not fl.StartSolid and fl.Hit and nextPos.z < fl.HitPos.z + 80 then nextPos.z = fl.HitPos.z + 80 end
            if util.IsInWorld and not util.IsInWorld(nextPos) then
                E.goal = SkySpot()
                nextPos = pos
            end
        end
        if not flying then
            local g = Ground(nextPos)
            -- (coming down to the road: a gentle descent rather than a drop; on its wheels)
            nextPos.z = g and (pos.z + (g.z + BusLift(bus) - pos.z) * 0.3) or pos.z
        end
        bus:SetPos(nextPos)
        local ang = E.busDir:Angle()
        bus:SetAngles(Angle(flying and ang.p or 0, ang.y, flying and math.sin(t * 1.3) * 14 or 0))
    end
    -- the rings: through one, and it pops
    local keep = {}
    for _, ring in ipairs(E.rings) do
        if IsValid(ring) then
            local c = RAINBOW[(math.floor(beat) % #RAINBOW) + 1]
            ring:SetColor(Color(c[1], c[2], c[3], 220))
            if ring:GetPos():DistToSqr(bus:GetPos()) < 160 * 160 then
                ring:EmitSound("garrysmod/balloon_pop_cute.wav", 90)
                if util.Effect and EffectData then
                    local fx = EffectData()
                    fx:SetOrigin(ring:GetPos())
                    util.Effect("balloon_pop", fx)
                end
                ring:Remove()
                E.ringsPopped = (E.ringsPopped or 0) + 1
            else
                keep[#keep + 1] = ring
            end
        end
    end
    E.rings = keep
    if flying and #E.rings == 0 then NewRing(E.goal, bus:GetPos()) end
    -- everyone in their seat (the seats turn with the bus)
    for _, e in ipairs(E.riders or {}) do
        local r = IsValid(e) and e.lcEndRide
        if r and r.v == bus then
            e:SetPos(bus.LocalToWorld and bus:LocalToWorld(r.off) or (bus:GetPos() + r.off))
            if not e:IsPlayer() then e:SetAngles(Angle(0, bus:GetAngles().y, 0)) end
        end
    end
end

-- Swimming in the flood: you sink slowly, move slowly, and Jump swims up
-- (cl_livingcity_endings.lua does the same, so it feels right).
function LC.FloodSwim(p, mv, z)
    if not z or p:GetPos().z + 40 >= z then return false end
    local v = mv:GetVelocity()
    v.x, v.y = v.x * 0.9, v.y * 0.9
    v.z = math.max(v.z * 0.9, -50)
    if mv:KeyDown(IN_JUMP) then v.z = 220 end
    mv:SetVelocity(v)
    return true
end
hook.Add("SetupMove", "LivingCityFlood", function(p, mv)
    if not E or E.id ~= "water" or E.phase ~= "apocalypse" or p.lcEndTaken or IsValid(E.realWater) or (E.dream and not p.lcDreaming) then return end
    LC.FloodSwim(p, mv, E.floodZ)
end)

-- Nobody gets off the bus: no suicide, and the dead are put straight back on.
hook.Add("CanPlayerSuicide", "LivingCityEndings", function(p) if E and E.phase == "apocalypse" and (not E.dream or (IsValid(p) and p.lcDreaming)) then return false end end)
hook.Add("PlayerDeath", "LivingCityEndingBus", function(p)
    if E and E.id == "bus" and E.boarded and (not E.dream or p.lcDreaming) then
        p.lcEndRide = nil
        timer.Simple(0.5, function() if IsValid(p) and not p:Alive() then p:Spawn() end end)
    end
end)

-- Base (a codeword): someone set up us the bomb. The song's opening lines
-- play as arcade subtitles (lc_ending_base_lines); bombs appear all over the
-- city, beeping; the main screen turns on and CATS fills the sky; when the
-- remix kicks in everyone (and some of the Combine) is on a ZIG, a dropship,
-- and the whole fleet takes off and circles the city on the beat while the
-- bombs go off below; "Move ZIG" faster; "For great justice" they dive at
-- CATS, the bombs chain, and everything blows. All the while, everyone's
-- chat comes out in Engrish.
local cvBaseSections = CreateConVar("lc_ending_base_sections", "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end", FLAGS,
    "Base: the song's moments, second:kind (bomb, screen, zig, move, justice, boom, end)")
local cvBaseLines = CreateConVar("lc_ending_base_lines",
    "2.15=CAPTAIN: What happen ?|3.55=MECHANIC: Somebody set up us the bomb.|4.65=OPERATOR: We get signal.|6.5=CAPTAIN: What !|9.5=OPERATOR: Main screen turn on.|11.7=CAPTAIN: It's you !!|12.55=CATS: How are you gentlemen !!|14.7=CATS: All your base are belong to us.|18.45=CATS: You are on the way to destruction.|20.6=CAPTAIN: What you say !!|21.65=CATS: You have no chance to survive make your time.|26.0=CATS: Ha ha ha ha ....|34=CAPTAIN: Take off every 'ZIG' !!|126=CAPTAIN: Move 'ZIG'.|174=CAPTAIN: For great justice.",
    FLAGS, "Base: the subtitles, second=WHO: line, separated by |")
local cvBaseBPM   = CreateConVar("lc_ending_base_bpm", "150", FLAGS, "Base: the song's beats per minute (the bombs and the fleet keep to it)")
local cvBaseBombs = CreateConVar("lc_ending_base_bombs", "60", FLAGS, "Base: how many bombs someone sets up (and keeps setting up, as they go off)")
local ZIG = { "models/combine_dropship.mdl" }
local BOMB = { "models/props_phx/ww2bomb.mdl", "models/props_c17/oildrum001_explosive.mdl" }

function LC.BaseLines(str)
    local out = {}
    for t, line in string.gmatch((str or cvBaseLines:GetString()) .. "|", "([%d%.]+)%s*=%s*([^|]+)|") do out[#out + 1] = { t = tonumber(t), text = string.Trim(line) } end
    table.sort(out, function(x, y) return x.t < y.t end)
    return out
end

-- Engrish: what everyone says, the way the captain would say it.
local ENGRISH = { { "%f[%a][Yy]our%f[%A]", "you" }, { "%f[%a][Yy]ou're%f[%A]", "you are" }, { "%f[%a]is%f[%A]", "are belong" },
    { "%f[%a]the%f[%A] ", "" }, { "%f[%a]The%f[%A] ", "" }, { "%f[%a]a%f[%A] ", "" }, { "%f[%a]I am%f[%A]", "I are" },
    { "%f[%a]happened%f[%A]", "happen" }, { "%f[%a]what's%f[%A]", "what" }, { "%f[%a]going to%f[%A]", "on the way to" } }
function LC.Engrish(text)
    local s = tostring(text or "")
    for _, r in ipairs(ENGRISH) do s = string.gsub(s, r[1], r[2]) end
    s = string.gsub(s, "%s+$", "")
    if not string.find(s, "[!?%.]$") then s = s .. " !!" else s = string.gsub(s, "([!?])$", " %1%1") end
    return s
end

local function BaseSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function Blow(pos, big)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect("Explosion", fx)
    end
    local near = E and E.dream -- (a dream: felt and heard in it, not across the whole map)
    if util.ScreenShake then util.ScreenShake(pos, big and 12 or 5, 5, big and 2 or 1, near and 1200 or (big and 3000 or 1500)) end
    if sound and sound.Play then sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", pos, near and 95 or (big and 140 or 110), 100, 1) end
end

local function SetBomb(pos)
    local b = Prop(FirstModel(BOMB), pos + Vector(0, 0, 10))
    if b then
        b:SetAngles(Angle(0, math.Rand(0, 360), math.Rand(-10, 10)))
        if b.SetSolid then b:SetSolid(SOLID_NONE) end
        E.bombs[#E.bombs + 1] = b
    end
    return b
end

-- Somewhere to set one: far out if there's room, closer in where the map's cramped.
local function BombSpot()
    for _, d in ipairs({ math.Rand(1500, 3000), math.Rand(800, 1500), math.Rand(300, 800), 250 }) do
        local g = RingSpot(E.lz, d, false)
        if g then return g end
    end
    return nil
end

local function BombIndices()
    local out = {}
    for _, b in ipairs(E.bombs) do if IsValid(b) then out[#out + 1] = b:EntIndex() end end
    return out
end

-- On a ZIG: a place on top of it (crammed in, like the bus).
local function ZigSeat(i)
    local row, side = (i - 1) % 3, math.floor((i - 1) / 3) % 2
    return Vector(-80 + row * 80, side == 0 and -40 or 40, 150 + math.floor((i - 1) / 6) * 50)
end

local function ZigBoard(e)
    if not IsValid(e) or e.lcEndRide or #E.zigs == 0 then return end
    E.zigSeat = (E.zigSeat or 0) + 1
    local zi = (E.zigSeat - 1) % #E.zigs + 1
    local per = math.floor((E.zigSeat - 1) / #E.zigs) + 1
    e.lcEndRide = { v = E.zigs[zi], off = ZigSeat(per) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        HoldOn(e)
    end
    e:SetNW2Entity("lc_riding", E.zigs[zi])
    e:SetNW2Bool("lc_dancing", true)
end

SETUP.base = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvBaseSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 224)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.bombs, E.zigs = {}, {}
    E.sky = E.lz + Vector(0, 0, 2600)
    LC.TimeStopped = (not E.dream) or nil -- (the city stops and stares)
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = "f" end
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    E.client = { party = true, lights = false, dance = "bus", bpm = cvBaseBPM:GetFloat(), offset = 0, start = now,
        lines = LC.BaseLines(), palette = { { 255, 60, 40 }, { 255, 200, 60 } }, sky = E.sky, bombs = {} }
    E.section = "intro"
end

TICK.base = function(now)
    local t = now - E.phaseT
    local kind = BaseSection(t)
    local beat = t * cvBaseBPM:GetFloat() / 60
    if kind ~= E.section then
        E.section = kind
        E.client.section = kind
        if kind == "bomb" then
            -- somebody set up us the bomb: all over the city
            for _ = 1, cvBaseBombs:GetInt() do
                local g = BombSpot()
                if g then SetBomb(g) end
            end
            if LC.Log then LC.Log("info", "Base: " .. #E.bombs .. " bombs set up (of " .. cvBaseBombs:GetInt() .. ")") end
        elseif kind == "screen" then
            E.client.cats = true -- (main screen turn on: CATS in the sky)
        elseif kind == "zig" then
            -- take off every ZIG: the fleet at the landing zone, everyone aboard
            local n = math.max(3, math.ceil(#LC.EndingPlayers() / 6) + 1)
            for i = 1, n do
                local side = (i % 2 == 0) and 1 or -1
                local rank = math.floor(i / 2)
                local z = Prop(FirstModel(ZIG), E.lz + Vector(-rank * 420, side * rank * 380, 250))
                if z then
                    if z.SetSolid then z:SetSolid(SOLID_NONE) end
                    z.lcSlot = Vector(-rank * 420, side * rank * 380, rank * 60)
                    E.zigs[#E.zigs + 1] = z
                end
            end
            for _, p in ipairs(LC.EndingPlayers()) do ZigBoard(p) end
            local c = 0
            for _, npc in ipairs(CombineNPCs()) do if c < 6 then c = c + 1 ZigBoard(npc) end end
            E.client.lights = true
            E.client.zigs = {}
            for _, z in ipairs(E.zigs) do E.client.zigs[#E.client.zigs + 1] = z:EntIndex() end -- (their exhaust trails, on every screen)
            E.fleetA = 0
        elseif kind == "move" then
            E.client.strobe = true
        elseif kind == "boom" then
            -- for great justice
            for _, b in ipairs(E.bombs) do if IsValid(b) then Blow(b:GetPos(), true) b:Remove() end end
            Blow(E.sky, true)
            E.client.cats = false
            E.client.boomAt = now
        end
        E.client.bombs = BombIndices()
        Send()
    end
    if E.boarded ~= false and #E.zigs > 0 then for _, p in ipairs(LC.EndingPlayers()) do ZigBoard(p) end end
    -- the fleet: round the city in formation, faster with the beat; at the end, at CATS
    if #E.zigs > 0 then
        local surge = 1 + 0.3 * math.abs(math.sin(beat * math.pi))
        local speed = (kind == "move" and 0.32) or (kind == "justice" and 0.4) or 0.2
        E.fleetA = (E.fleetA or 0) + speed * surge * 0.1
        E.flight = E.flight or LC.EndingSky(E.lz) -- (open sky: the fleet and its riders stay out of the buildings)
        local sky = E.flight
        local r = kind == "justice" and math.max(300, sky.r * (1 - math.Clamp((t - 174) / 38, 0, 1) * 0.75)) or sky.r
        local height = kind == "justice" and math.min(sky.top - 60, sky.z + math.Clamp((t - 174) / 38, 0, 1) * 1500) or sky.z
        local lead = Vector(sky.centre.x + math.cos(E.fleetA) * r, sky.centre.y + math.sin(E.fleetA) * r, height)
        local yaw = math.deg(E.fleetA) + 90
        local roll = (kind == "move" or kind == "justice") and math.sin(t * 2) * 25 or math.sin(t) * 8
        for _, z in ipairs(E.zigs) do
            if IsValid(z) then
                local off = z.lcSlot or Vector()
                local ang = Angle(0, yaw, 0)
                local pos = lead + ang:Forward() * off.x + ang:Right() * off.y + Vector(0, 0, off.z)
                -- (each ship, out in the formation, well under the sky or a roof right where it is)
                local ceil = CeilingAt(pos)
                if ceil - pos.z < 260 then pos.z = ceil - 260 end
                local cur = z:GetPos()
                if CeilingAt(cur) <= cur.z + 1 then cur = cur - Vector(0, 0, 250) end -- (up in the sky: out of it)
                z:SetPos(LerpVector(0.35, cur, pos))
                z:SetAngles(Angle(math.sin(t * 1.3) * 5, yaw, roll))
            end
        end
        for _, e in ipairs(E.riders or {}) do
            local rd = IsValid(e) and e.lcEndRide
            if rd and IsValid(rd.v) then e:SetPos(rd.v.LocalToWorld and rd.v:LocalToWorld(rd.off) or (rd.v:GetPos() + rd.off)) end
        end
    end
    -- the end: a barrage, bombs going off everywhere, below the fleet and all round it,
    -- one after another to the last note (each one heard: it's played where you are)
    if kind == "boom" and now >= (E.nextBoom or 0) then
        E.nextBoom = now + math.Rand(0.12, 0.3)
        local lead = (#E.zigs > 0 and IsValid(E.zigs[1]) and E.zigs[1]:GetPos()) or E.lz
        local at = lead + Vector(math.Rand(-900, 900), math.Rand(-900, 900), math.Rand(-700, 150))
        if math.random() < 0.5 then
            local g = Ground(at)
            if g then at = g + Vector(0, 0, 20) end
        end
        Blow(at, math.random() < 0.3)
        for _, p in ipairs(LC.EndingPlayers()) do
            if math.random() < 0.6 then p:EmitSound("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", 85, math.random(85, 110), 0.7) end
        end
    end
    -- the bombs go off below, more and more of them
    if (kind == "zig" or kind == "move" or kind == "justice") then
        local b = math.floor(beat)
        if b ~= E.lastBeat then
            E.lastBeat = b
            local chance = (kind == "justice" and 0.7) or (kind == "move" and 0.4) or 0.2
            if math.random() < chance then
                local alive = {}
                for _, bb in ipairs(E.bombs) do if IsValid(bb) then alive[#alive + 1] = bb end end
                E.bombs = alive
                if #alive > 0 then
                    local bb = table.remove(E.bombs, math.random(#alive))
                    Blow(bb:GetPos(), false)
                    bb:Remove()
                    -- (and somebody sets up another, and keeps it topped up)
                    for _ = 1, math.min(2, cvBaseBombs:GetInt() - #E.bombs) do
                        local g = BombSpot()
                        if g then SetBomb(g) end
                    end
                    E.client.bombs = BombIndices()
                    Send()
                end
            end
        end
    end
end

-- Everyone's chat, in Engrish, while the base is belong to them.
hook.Add("PlayerSay", "LivingCityEngrish", function(p, text, team)
    if not E or E.id ~= "base" or E.phase ~= "apocalypse" or (E.dream and not p.lcDreaming) then return end
    if string.sub(text or "", 1, 1) == "!" or string.sub(text or "", 1, 1) == "/" then return end
    return LC.Engrish(text)
end)

-- Hard (a codeword): party hard. Everyone at the landing zone, the Combine's
-- units too, every NPC in the city dancing where they stand; the cheap meme
-- dance (each half-beat, the mirror image of the last pose), PARTY HARD
-- flashing everywhere, the strobe never stops. From lc_ending_hard_sections'
-- "passout" people drop, one at a time, having partied too hard; when the
-- music cuts, whoever's left goes down too.
local cvHardSections = CreateConVar("lc_ending_hard_sections", "6:hard,28:break,32:hard,150:passout,177:fade,188:end", FLAGS,
    "Hard: the song's sections, second:kind (hard, break, passout, fade, end); before the first, the intro")
local cvHardBPM = CreateConVar("lc_ending_hard_bpm", "150", FLAGS, "Hard: the song's beats per minute (the flips and the strobe keep to it)")
local RAINBOW2 = { { 255, 40, 40 }, { 255, 150, 30 }, { 255, 240, 40 }, { 60, 230, 80 }, { 60, 140, 255 }, { 200, 70, 255 }, { 255, 80, 200 } }

local function HardSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- Through the song, one at a time, one of the Combine's units really goes
-- for it: a crowd surf over everyone's heads, a frenzied spin, or a jump for
-- joy with a backflip, confetti and all (every lc_ending_hard_moment_beats
-- beats in the "hard" parts; each unit gets a turn before anyone goes twice).
local cvHardMoment = CreateConVar("lc_ending_hard_moment_beats", "5", FLAGS, "Hard: beats between another of the Combine's Civil Protection units going for it (a crowd surf, a spin, a backflip; 0 off)")
local cvHardMomentMax = CreateConVar("lc_ending_hard_moment_max", "3", FLAGS, "Hard: how many of the Combine's Civil Protection units can be going for it at once")
local WOO = {
    "npc/metropolice/vo/affirmative.wav", "npc/metropolice/vo/rodgerthat.wav", "npc/metropolice/vo/ten4.wav",
    "npc/combine_soldier/vo/affirmative.wav", "npc/combine_soldier/vo/affirmative2.wav", "npc/combine_soldier/vo/copythat.wav",
}
local YEAH = { "vo/npc/male01/yeah02.wav", "vo/npc/female01/yeah02.wav", "vo/npc/male01/fantastic01.wav", "vo/npc/female01/nice01.wav" }
local function Confetti(pos, n)
    if not (util.Effect and EffectData) then return end
    for _ = 1, n or 4 do
        local fx = EffectData()
        fx:SetOrigin(pos + VectorRand() * 30)
        local c = RAINBOW2 and RAINBOW2[math.random(#RAINBOW2)]
        if c and fx.SetStart then fx:SetStart(Vector(c[1], c[2], c[3])) end
        util.Effect("balloon_pop", fx)
    end
end
local function PartyMoment(now)
    local pool = {}
    for _, n in ipairs(CombineNPCs()) do if IsValid(n) and not n.lcEndTaken then pool[#pool + 1] = n end end
    if #pool == 0 then return end
    E.partied = E.partied or {}
    E.moments = E.moments or {}
    local busy = {}
    for _, m in ipairs(E.moments) do busy[m.e] = true end
    local fresh = {}
    for _, n in ipairs(pool) do if not E.partied[n] and not busy[n] then fresh[#fresh + 1] = n end end
    if #fresh == 0 then
        E.partied = {}
        for _, n in ipairs(pool) do if not busy[n] then fresh[#fresh + 1] = n end end
        if #fresh == 0 then return end
    end
    local e = fresh[math.random(#fresh)]
    E.partied[e] = true
    local kinds = { "surf", "spin", "flip" }
    local kind = kinds[(E.momentsDone or 0) % #kinds + 1]
    local from, yaw = e:GetPos(), e:GetAngles().y
    local across = E.lz + (E.lz - from) -- (the far side of the ring)
    across.z = from.z
    E.moments[#E.moments + 1] = { e = e, kind = kind, t0 = now, dur = kind == "surf" and 4.5 or (kind == "spin" and 3 or 1.6), from = from, to = kind == "surf" and across or from, yaw = yaw }
    E.momentsDone = (E.momentsDone or 0) + 1
    local w = Pick(WOO)
    if w then e:EmitSound(w, 85) end
    for _, n in ipairs(pool) do if n ~= e and math.random() < 0.15 then local y = Pick(YEAH) if y then n:EmitSound(y, 75, math.random(95, 110)) end end end
    if kind ~= "surf" then Confetti(from + Vector(0, 0, 50), 5) end
end
local function MomentOne(m, now)
    local e = m.e
    local f = (now - m.t0) / m.dur
    if not IsValid(e) or f >= 1 then
        if IsValid(e) then
            e:SetPos(m.to)
            e:SetAngles(Angle(0, m.kind == "surf" and (E.lz - m.to):Angle().y or m.yaw, 0))
            if m.kind == "flip" then Confetti(m.to + Vector(0, 0, 40), 6) end
        end
        return true -- (done)
    end
    if m.kind == "surf" then
        -- lifted up, laid flat, and passed across the ring over everyone's heads
        local up = math.min(1, f * 4, (1 - f) * 4)
        e:SetPos(LerpVector(f, m.from, m.to) + Vector(0, 0, 70 * up))
        e:SetAngles(Angle(-80 * up, m.yaw + f * 180, 0))
    elseif m.kind == "spin" then
        e:SetPos(m.from)
        e:SetAngles(Angle(0, m.yaw + f * 1440, 0))
        if math.random() < 0.3 then Confetti(m.from + Vector(0, 0, 60), 1) end
    else
        -- straight up, a full backflip, and down
        e:SetPos(m.from + Vector(0, 0, 4 * 180 * f * (1 - f)))
        e:SetAngles(Angle(-360 * f, m.yaw, 0))
    end
    return false
end
local function MomentStep(now)
    local left = {}
    for _, m in ipairs(E.moments or {}) do if not MomentOne(m, now) then left[#left + 1] = m end end
    E.moments = left
end

-- Partied too hard: down they go.
local function PassOut(e, how)
    if not IsValid(e) or e.lcEndTaken then return end
    Body(e:GetModel(), e:GetPos(), e:GetAngles().y, 60)
    if e:IsPlayer() then
        e:EmitSound("vo/npc/male01/moan0" .. math.random(1, 5) .. ".wav", 75)
        if e.SetNoDraw then e:SetNoDraw(true) end
        Spectator(e, how or "You partied too hard. Lights out.", Color(255, 80, 200, 200))
    else
        e:Remove()
    end
end

SETUP.hard = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvHardSections:GetString())
    for _, sct in ipairs(E.sections) do
        if sct.kind == "end" then E.holdUntil = now + sct.t end
        if sct.kind == "passout" then E.passAt = now + sct.t end
        if sct.kind == "fade" then E.fadeAt = now + sct.t end
    end
    E.holdUntil = E.holdUntil or (now + 188)
    E.passAt, E.fadeAt = E.passAt or (now + 150), E.fadeAt or (now + 177)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    local ps = LC.EndingPlayers()
    local taken = {}
    local pspots = RingSpots(E.lz, 60, #ps, taken)
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p:SetPos(pspots[i].pos)
        p.lcEndFrozen = true
        p:Freeze(true)
        p:SetNW2Bool("lc_dancing", true)
    end
    GatherCombine(E.lz, 120 + 14 * #ps, taken)
    for npc in pairs(LC.EndingNPCs()) do if IsValid(npc) then npc:SetNW2Bool("lc_dancing", true) end end
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = "e" end
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    E.client = { party = true, lights = true, strobe = true, dance = "hard", partyText = true, palette = RAINBOW2,
        bpm = cvHardBPM:GetFloat(), offset = 0, start = now, section = "intro",
        spots = true, lz = E.lz, spotR = 200 + 14 * #ps, spotN = 10, spotCols = RAINBOW2, spotCycle = true } -- (spotlights round the ring, every colour)
    E.passGap = math.max(0.5, (E.fadeAt - E.passAt) / math.max(1, #ps))
end

TICK.hard = function(now)
    local t = now - E.phaseT
    local kind = HardSection(t)
    if kind ~= E.client.section then
        E.client.section = kind
        E.client.strobe = kind ~= "break" and kind ~= "fade"
        E.client.partyText = kind ~= "break" and kind ~= "fade"
        Send()
    end
    -- one of the Combine's units goes for it, every so many beats in the hard parts
    local every = cvHardMoment:GetInt()
    if every > 0 and kind == "hard" and #(E.moments or {}) < cvHardMomentMax:GetInt() then
        local beat = math.floor(t * cvHardBPM:GetFloat() / 60)
        if beat ~= E.momentBeat and beat % every == 0 then
            E.momentBeat = beat
            PartyMoment(now)
        end
    end
    MomentStep(now)
    -- one at a time, they drop
    if kind == "passout" and now >= (E.nextPass or 0) then
        E.nextPass = now + E.passGap
        local pick = Living()
        if #pick > 0 then PassOut(pick[math.random(#pick)]) end
    end
    if (kind == "passout") and now >= (E.nextNPCPass or 0) then
        E.nextNPCPass = now + 0.4
        for npc in pairs(LC.EndingNPCs()) do if IsValid(npc) then PassOut(npc) break end end
    end
    -- the music cuts: everyone left goes down
    if (kind == "fade" or kind == "end") and not E.allOut then
        E.allOut = true
        for _, p in ipairs(Living()) do PassOut(p, "The music stops. So do you. You partied too hard.") end
    end
end

do -- (Shalom keeps its own names to itself: the file is near Lua's limit on them)
-- Shalom (a codeword): the hora. Israeli flags shoot up on poles round the
-- landing zone on the intro's hit, and everyone is gathered there in rings
-- round a giant hanukkiah: the players in the inner ring, the city's people
-- in the outer one, and the Combine's units standing round them, watching.
-- Kippahs go on, sayings float over every head (Yiddish and Israeli, in
-- English and Hebrew), and the rings sway, then walk, then dance the hora
-- (arms on each other's shoulders, the grapevine step), the two rings going
-- opposite ways. When the hora proper starts, the Combine's units drop their
-- guns and join the outer ring. A candle on the hanukkiah is lit at each
-- phrase, all eight burning by the key change; on the breakdowns everyone
-- rushes into the middle with their arms up and back out; through the song
-- someone is lifted up on a chair over everyone's heads, like at a wedding.
-- At the key change a giant flag unfurls across the sky and blue and white
-- Star of David fireworks go off; the last run is the fastest, and the song
-- ends with everyone still dancing. Nobody is taken. (Timed from the song:
-- 4:49, 136 BPM, E Phrygian dominant up to F at 3:25.)
local cvShalomSections = CreateConVar("lc_ending_shalom_sections",
    "7.4:gather,35.7:walk,62.1:hora,111.5:lift,125.7:hora,153.9:in,157.4:hora,180.4:in,183.9:build,205.1:peak,219.2:hora,224.5:in,231.5:final,273.9:outro,288.5:end", FLAGS,
    "Shalom: the song's sections, second:kind (gather, walk, hora, lift, in, build, peak, final, outro, end); before the first, the intro")
local cvShalomBPM = CreateConVar("lc_ending_shalom_bpm", "136", FLAGS, "Shalom: the song's beats per minute (the steps keep to it)")
local cvShalomOffset = CreateConVar("lc_ending_shalom_offset", "0.36", FLAGS, "Shalom: seconds into the song of its first beat")
local cvShalomCandles = CreateConVar("lc_ending_shalom_candles", "35.7,62.1,86.8,111.5,125.7,153.9,183.9,205.1", FLAGS,
    "Shalom: the seconds into the song the hanukkiah's eight candles are lit, one by one (the shamash burns from the start)")
local cvShalomLift = CreateConVar("lc_ending_shalom_lift_beats", "8", FLAGS, "Shalom: beats between someone else being lifted up on a chair (every 4 in the lift section; 0 off)")
local cvShalomCrowd = CreateConVar("lc_ending_shalom_crowd", "12", FLAGS, "Shalom: how many of the city's people dance in the outer ring (its own NPCs first, topped up with citizens)")
local cvShalomSayings = CreateConVar("lc_ending_shalom_sayings", "", FLAGS, "Shalom: more sayings to float over heads, separated by | (added to the built-in ones)")
local SHALOM_PAL = { { 255, 205, 110 }, { 60, 120, 255 }, { 255, 255, 255 }, { 120, 170, 255 } }
local SHALOM_SPEED = { intro = 0, gather = 0, walk = 0.5, hora = 1, lift = 1, ["in"] = 0, build = 1.2, peak = 1.6, final = 1.8, outro = 0.4, ["end"] = 0 }
local HORA_STEP = 38      -- (shoulder to shoulder, round a ring)
local HORA_PACE = 42      -- (how fast a ring goes round at the hora's own speed: units a second)

local function ShalomSection(t)
    local kind, at = "intro", 0
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind, at = sct.kind, sct.t end end
    return kind, at
end
local function SecondOf(kind, fallback)
    for _, sct in ipairs(E.sections or {}) do if sct.kind == kind then return sct.t end end
    return fallback
end
-- (the shortest way round from one angle to another)
local function AngleTo(a, b) return (b - a + math.pi) % (math.pi * 2) - math.pi end

-- A ring: shoulder to shoulder, evenly spaced, wide enough for everyone in it.
local function Layout(ring, minR)
    local n = #ring.members
    ring.r = math.max(minR or ring.minR or 150, n * HORA_STEP / (math.pi * 2))
    -- (in the order they stand, so nobody cuts across to a new place)
    table.sort(ring.members, function(x, y) return (x.a % (math.pi * 2)) < (y.a % (math.pi * 2)) end)
    local base = n > 0 and ring.members[1].a or 0
    for i, m in ipairs(ring.members) do m.ta = base + (i - 1) / math.max(1, n) * math.pi * 2 end
end
local function Member(ring, e, a)
    local m = { e = e, a = a, ta = a, r = ring.r or 150 }
    ring.members[#ring.members + 1] = m
    e.lcHora = m
    return m
end

-- Up on a chair, over everyone's heads (a beat-long bounce on every beat), then down.
local function LiftUp(m, now)
    if not m or m.lift or not IsValid(m.e) then return end
    local beats = 16
    m.lift = { t0 = now, dur = beats * 60 / math.max(40, cvShalomBPM:GetFloat()) }
    m.e:SetNW2Bool("lc_chair", true)
    E.lifted = E.lifted or {}
    E.lifted[m.e] = true
    local y = Pick(YEAH)
    for _, r in ipairs({ E.rings.inner, E.rings.outer }) do
        for _, o in ipairs(r.members) do
            if o ~= m and IsValid(o.e) and not o.e:IsPlayer() and math.random() < 0.2 then
                local s = Pick(YEAH) if s then o.e:EmitSound(s, 75, math.random(95, 110)) end
            end
        end
    end
    if y and m.e.EmitSound then m.e:EmitSound(y, 80) end
end
local function LiftDown(m)
    if not m or not m.lift then return end
    m.lift = nil
    if IsValid(m.e) then m.e:SetNW2Bool("lc_chair", false) end
end
-- Whose turn: players and the city's people in turn, nobody twice till everyone's been up.
local function NextLift()
    E.lifted = E.lifted or {}
    local up = 0
    local pools = { {}, {} }
    for _, r in ipairs({ E.rings.inner, E.rings.outer }) do
        for _, m in ipairs(r.members) do
            if m.lift then up = up + 1
            elseif IsValid(m.e) then local pl = m.e:IsPlayer() and 1 or 2 pools[pl][#pools[pl] + 1] = m end
        end
    end
    E.liftTurn = (E.liftTurn or 0) + 1
    local order = E.liftTurn % 2 == 1 and { 1, 2 } or { 2, 1 }
    for _, k in ipairs(order) do
        local fresh = {}
        for _, m in ipairs(pools[k]) do if not (E.lifted or {})[m.e] then fresh[#fresh + 1] = m end end
        if #fresh == 0 and #pools[k] > 0 then
            for _, m in ipairs(pools[k]) do E.lifted[m.e] = nil end
            fresh = pools[k]
        end
        if #fresh > 0 then return fresh[math.random(#fresh)], up end
    end
    return nil, up
end

-- The Combine's units put their guns down and join the outer ring.
local function CombineJoin(now)
    if E.joined then return end
    E.joined = true
    local outer, watch = E.rings.outer, E.rings.watch
    E.hidWeps = E.hidWeps or {}
    for _, m in ipairs(watch.members) do
        local n = m.e
        if IsValid(n) then
            local w = n.GetActiveWeapon and n:GetActiveWeapon()
            if IsValid(w) then
                local mdl = w.GetModel and w:GetModel()
                if mdl and mdl ~= "" then
                    local dropped = ents.Create("prop_physics")
                    if IsValid(dropped) then
                        dropped:SetModel(mdl)
                        dropped:SetPos(n:GetPos() + Vector(0, 0, 40) + (n.GetForward and n:GetForward() or Vector(1, 0, 0)) * 18)
                        dropped:Spawn()
                        E.ents[#E.ents + 1] = dropped
                    end
                end
                if w.SetNoDraw then w:SetNoDraw(true) end
                E.hidWeps[#E.hidWeps + 1] = w
            end
            n:SetNW2Bool("lc_dancing", true)
            m.a = (m.a + watch.spin) - outer.spin
            outer.members[#outer.members + 1] = m
        end
    end
    watch.members = {}
    Layout(outer, E.rings.inner.r + 85)
    local s = Pick(WOO)
    local first = outer.members[1]
    if s and first and IsValid(first.e) then first.e:EmitSound(s, 85) end
end

-- Everyone round the rings, every frame (and every tick, which is all a test has).
function LC.ShalomStep(now)
    if not E or E.id ~= "shalom" or E.phase ~= "apocalypse" or not E.rings then return end
    local dt = math.Clamp(now - (E.stepAt or now), 0, 0.25)
    E.stepAt = now
    local t = now - E.phaseT
    local kind, at = ShalomSection(t)
    local bpm = math.max(40, cvShalomBPM:GetFloat())
    local beat = (t - cvShalomOffset:GetFloat()) * bpm / 60
    -- how fast: by the section, the build speeding up through it, the outro winding down
    local want = SHALOM_SPEED[kind] or 1
    if kind == "build" then
        local nextT = SecondOf("peak", at + 20)
        want = 1 + 0.4 * math.Clamp((t - at) / math.max(1, nextT - at), 0, 1)
    end
    E.mult = (E.mult or 0) + math.Clamp(want - (E.mult or 0), -1.5 * dt, 1.5 * dt)
    -- into the middle with the arms up and back out, every two bars, on the breakdowns
    local rush = 1
    if kind == "in" then
        local p = (((t - at) * bpm / 60) % 8) / 8
        rush = 1 - 0.35 * math.sin(math.pi * p)
    end
    E.rush = (E.rush or 1) + math.Clamp(rush - (E.rush or 1), -2 * dt, 2 * dt)
    local c, z0 = E.lz, E.floorZ
    -- (the ground under each of them, not one height for all: the landing zone's middle can be
    -- a kerb or a step above the road round it; looked up once a spot and kept)
    E.groundAt = E.groundAt or {}
    local function FloorAt(x, y)
        local key = math.floor(x / 16) .. ":" .. math.floor(y / 16)
        local z = E.groundAt[key]
        if z == nil then
            local g = Ground(Vector(x, y, z0 + 40))
            z = (g and math.abs(g.z - z0) < 80) and g.z or z0 -- (never down off a roof's edge)
            E.groundAt[key] = z
        end
        return z
    end
    for name, ring in pairs(E.rings) do
        ring.spin = ring.spin + ring.dir * HORA_PACE * E.mult / math.max(60, ring.r) * dt
        for _, m in ipairs(ring.members) do
            local e = m.e
            if IsValid(e) then
                m.a = m.a + math.Clamp(AngleTo(m.a, m.ta), -1.2 * dt, 1.2 * dt)
                m.r = m.r + math.Clamp(ring.r - m.r, -150 * dt, 150 * dt)
                local a = m.a + ring.spin
                local r = m.r * (name == "watch" and 1 or E.rush)
                local px, py = c.x + math.cos(a) * r, c.y + math.sin(a) * r
                local pos = Vector(px, py, FloorAt(px, py)) -- (right on the floor: anything held up off it looks like it floats)
                local yaw = math.deg(a) + 180
                if m.lift then
                    local f = (now - m.lift.t0) / m.lift.dur
                    local up = math.Clamp(math.min(f * 5, (1 - f) * 5), 0, 1)
                    local s = up * up * (3 - 2 * up)
                    pos.z = pos.z + s * (62 + 8 * math.abs(math.sin(beat * math.pi)))
                    -- (the chair itself is drawn on every screen under their hips: cl_livingcity_endings.lua)
                end
                e:SetPos(pos)
                if e:IsPlayer() then
                    if math.abs(AngleTo(math.rad(m.yawSent or 0), math.rad(yaw))) > 0.05 then
                        m.yawSent = yaw
                        if e.SetEyeAngles then e:SetEyeAngles(Angle(0, yaw, 0)) end
                    end
                else
                    e:SetAngles(Angle(0, yaw, 0))
                end
            end
        end
    end
end
hook.Add("Think", "LivingCityShalom", function() if E and E.id == "shalom" then LC.ShalomStep(CurTime()) end end)

SETUP.shalom = function()
    local now = CurTime()
    E.songEnds = true -- (everyone dances to the last note; then it's over)
    E.sections = LC.MarrowSections(cvShalomSections:GetString())
    E.holdUntil = now + SecondOf("end", 288.5)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.floorZ = (Ground(E.lz) or E.lz).z
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    E.rings = {
        inner = { members = {}, dir = 1, spin = 0, minR = 150 },
        outer = { members = {}, dir = -1, spin = 0 },
        watch = { members = {}, dir = 0, spin = 0 },
    }
    -- the players: the inner ring
    local ps = LC.EndingPlayers()
    for i, p in ipairs(ps) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        p.lcEndFrozen = true
        p:Freeze(true)
        p:SetMoveType(MOVETYPE_NONE)
        p.lcShalom = true
        p:SetNW2Bool("lc_dancing", true)
        Member(E.rings.inner, p, (i - 1) / math.max(1, #ps) * math.pi * 2)
    end
    Layout(E.rings.inner)
    -- the city's people: the outer ring (its own first, topped up with citizens)
    local folk = CityFolk()
    local want = cvShalomCrowd:GetInt()
    while #folk > want do table.remove(folk) end
    local outerR = math.max(E.rings.inner.r + 85, (want + #CombineNPCs()) * HORA_STEP / (math.pi * 2))
    E.rings.outer.r = outerR
    for i = 1, want do
        local a = (i - 1) / math.max(1, want) * math.pi * 2 + 0.1
        local spot = Vector(E.lz.x + math.cos(a) * outerR, E.lz.y + math.sin(a) * outerR, E.floorZ)
        local c = folk[i]
        if not IsValid(c) then c = SpawnFolk(spot, i) elseif c.SetPos then c:SetPos(spot) end
        if IsValid(c) then
            c.lcRing = true
            c:SetNW2Bool("lc_dancing", true)
            Member(E.rings.outer, c, a)
        end
    end
    Layout(E.rings.outer, E.rings.inner.r + 85)
    -- the Combine's units: round the outside, watching, guns in hand (up to two dozen; any more dance where they stand)
    local cps = CombineNPCs()
    local watchR = E.rings.outer.r + 80
    E.rings.watch.r = watchR
    for i, n in ipairs(cps) do
        if i <= 24 then
            n.lcRing = true
            n:SetNW2Bool("lc_dancing", false)
            Member(E.rings.watch, n, (i - 1) / math.min(24, #cps) * math.pi * 2 + 0.2)
        end
    end
    for _, m in ipairs(E.rings.watch.members) do m.r = watchR end
    -- every other NPC in the city dances the hora where they stand
    for npc in pairs(LC.EndingNPCs()) do
        if IsValid(npc) and not npc.lcHora then npc:SetNW2Bool("lc_dancing", true) end
    end
    LC.ShalomStep(now)
    -- the hanukkiah in the middle (it fits inside the rush in), the flagpoles round the outside, the sky over it all
    local mw = E.rings.inner.r * 1.05
    local mh = math.max(150, mw * 0.95)
    local room = CeilingAt(Vector(E.lz.x, E.lz.y, E.floorZ + 8)) - E.floorZ - 20
    if room > 60 then mh = math.min(mh, room) end
    local poles = {}
    local poleR = watchR + 90
    for i = 1, 8 do
        local a = (i - 0.5) / 8 * math.pi * 2
        poles[i] = Vector(E.lz.x + math.cos(a) * poleR, E.lz.y + math.sin(a) * poleR, E.floorZ)
    end
    local skyZ = math.min(CeilingAt(Vector(E.lz.x, E.lz.y, E.floorZ + 64)) - 80, E.floorZ + 700)
    local candles = {}
    for s in string.gmatch(cvShalomCandles:GetString() or "", "[%d%.]+") do candles[#candles + 1] = tonumber(s) end
    table.sort(candles)
    local extra = {}
    for s in string.gmatch(cvShalomSayings:GetString() or "", "[^|]+") do s = string.Trim(s) if s ~= "" then extra[#extra + 1] = s end end
    E.client = { party = true, lights = true, strobe = false, dance = "hora", palette = SHALOM_PAL,
        bpm = cvShalomBPM:GetFloat(), offset = cvShalomOffset:GetFloat(), start = now, section = "intro",
        menorah = { pos = Vector(E.lz.x, E.lz.y, E.floorZ), w = mw, h = mh }, candles = candles, poles = poles,
        sky = Vector(E.lz.x, E.lz.y, math.max(E.floorZ + 200, skyZ)),
        gatherAt = SecondOf("gather", 7.4), peakAt = SecondOf("peak", 205.1), outroAt = SecondOf("outro", 273.9),
        sayings = #extra > 0 and extra or nil }
end

TICK.shalom = function(now)
    local t = now - E.phaseT
    local kind = ShalomSection(t)
    if kind ~= E.client.section then
        E.client.section = kind
        Send()
    end
    -- the hora proper: the Combine's units join in
    if not E.joined and t >= SecondOf("hora", 62.1) then CombineJoin(now) end
    LC.ShalomStep(now)
    -- the chairs: back down when it's over, and someone else up every so many beats
    for _, r in ipairs({ E.rings.inner, E.rings.outer }) do
        for _, m in ipairs(r.members) do
            if m.lift and (now - m.lift.t0 >= m.lift.dur or not IsValid(m.e)) then LiftDown(m) end
        end
    end
    local every = kind == "lift" and 4 or cvShalomLift:GetInt()
    local lifting = { hora = true, lift = true, build = true, peak = true, final = true }
    if every > 0 and lifting[kind] then
        local beat = math.floor((t - cvShalomOffset:GetFloat()) * math.max(40, cvShalomBPM:GetFloat()) / 60)
        if beat ~= E.liftBeat and beat % every == 0 then
            E.liftBeat = beat
            local m, up = NextLift()
            if m and up < (kind == "lift" and 3 or 2) then LiftUp(m, now) end
        end
    end
    if kind == "outro" or kind == "end" then
        for _, r in ipairs({ E.rings.inner, E.rings.outer }) do for _, m in ipairs(r.members) do LiftDown(m) end end
    end
end
end

-- Fire (a codeword): everyone's behind catches fire. Everyone gathers at the
-- landing zone (the players in the middle, the city's people and the
-- Combine's units round them); through the intro their behinds sputter and
-- smoke on the beat; at the drop they ignite, flames roaring out of every
-- behind, and everyone dances bent over, behind out; the flames grow and
-- everyone hops on the beat; at the peak they lift off on their own jets and
-- fly, Superman style, in a great ring over the city, faster and faster,
-- exhaust trailing; at the end each one rockets straight up and goes off
-- like a firework. (Timed from the song: 2:33, 100 BPM.)
do
local cvFireSections = CreateConVar("lc_ending_fire_sections", "12.2:ignite,60.2:hop,101:fly,146.6:launch,153:end", FLAGS,
    "Fire: the song's sections, second:kind (ignite, hop, fly, launch, end); before the first, the behinds sputter")
local cvFireBPM = CreateConVar("lc_ending_fire_bpm", "100", FLAGS, "Fire: the song's beats per minute (the dance and the hops keep to it)")
local cvFireOffset = CreateConVar("lc_ending_fire_offset", "0.18", FLAGS, "Fire: seconds into the song of its first beat")
local cvFireCrowd = CreateConVar("lc_ending_fire_crowd", "10", FLAGS, "Fire: how many of the city's people stand round everyone (its own NPCs first, topped up with citizens)")
local cvFireHop = CreateConVar("lc_ending_fire_hop", "22", FLAGS, "Fire: how high everyone hops on the beat (units)")
local cvFireSpeed = CreateConVar("lc_ending_fire_fly_speed", "0.35", FLAGS, "Fire: how fast the flyers go round the ring at first (radians a second; twice that by the end)")
local FIRE_PAL = { { 255, 120, 20 }, { 255, 200, 60 }, { 255, 60, 10 }, { 255, 160, 40 } }
-- how hard each behind burns, by section (the client draws the flames from it)
local FIRE_HEAT = { intro = 0, ignite = 1, hop = 1.6, fly = 2.2, launch = 3, ["end"] = 3 }
local RISE, OUT = 3, 3 -- (seconds to rise to the ring's height, then to fly out onto it)

local function FireSection(t)
    local kind, at = "intro", 0
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind, at = sct.kind, sct.t end end
    return kind, at
end
local function FireAt(kind, fallback)
    for _, sct in ipairs(E.sections or {}) do if sct.kind == kind then return sct.t end end
    return fallback
end
local function Smooth(x) x = math.Clamp(x, 0, 1) return x * x * (3 - 2 * x) end

-- Everyone the ending holds: { e, home (on the floor), i }
local function Hold(e, home, yaw)
    if not IsValid(e) then return end
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        e.lcEndFrozen = true
        e:Freeze(true)
        e:SetMoveType(MOVETYPE_NONE)
        e.lcFire = true
    end
    e:SetPos(home)
    if e:IsPlayer() then
        if e.SetEyeAngles then e:SetEyeAngles(Angle(0, yaw, 0)) end
    elseif e.SetAngles then
        e:SetAngles(Angle(0, yaw, 0))
    end
    e:SetNW2Bool("lc_dancing", true)
    E.fliers[#E.fliers + 1] = { e = e, home = home, i = #E.fliers + 1 }
end

SETUP.fire = function()
    local now = CurTime()
    E.songEnds = true -- (it's over when the song is)
    E.sections = LC.MarrowSections(cvFireSections:GetString())
    E.holdUntil = now + FireAt("end", 153)
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = "f" end -- (dimmer, so the flames light everyone up)
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.floorZ = (Ground(E.lz) or E.lz).z
    E.fliers = {}
    -- the players in the middle, facing out (their behinds to the middle: the flames go in)
    local ps = LC.EndingPlayers()
    local r1 = 70 + 16 * #ps
    for i, p in ipairs(ps) do
        local a = (i - 1) / math.max(1, #ps) * math.pi * 2
        local spot = Ground(E.lz + Vector(math.cos(a) * r1, math.sin(a) * r1, 0)) or Vector(E.lz.x + math.cos(a) * r1, E.lz.y + math.sin(a) * r1, E.floorZ)
        Hold(p, spot, math.deg(a))
    end
    -- the city's people, and the Combine's units, round them
    local folk = CityFolk()
    local want = cvFireCrowd:GetInt()
    while #folk > want do table.remove(folk) end
    local cps = CombineNPCs()
    local outer = {}
    for i = 1, want do
        local c = folk[i]
        if not IsValid(c) then c = SpawnFolk(E.lz, i) end
        if IsValid(c) then outer[#outer + 1] = c end
    end
    for i, n in ipairs(cps) do if i <= 24 then outer[#outer + 1] = n end end
    local r2 = math.max(r1 + 110, #outer * 45 / (math.pi * 2))
    for i, e in ipairs(outer) do
        local a = (i - 1) / math.max(1, #outer) * math.pi * 2 + 0.2
        local spot = Ground(E.lz + Vector(math.cos(a) * r2, math.sin(a) * r2, 0)) or Vector(E.lz.x + math.cos(a) * r2, E.lz.y + math.sin(a) * r2, E.floorZ)
        e.lcRing = true
        Hold(e, spot, math.deg(a))
    end
    -- every other NPC in the city burns (and dances) where they stand
    for npc in pairs(LC.EndingNPCs()) do if IsValid(npc) then npc:SetNW2Bool("lc_dancing", true) end end
    -- the sky to fly in
    E.flight = LC.EndingSky(E.lz)
    E.client = { party = true, lights = true, dance = "fire", fire = true, palette = FIRE_PAL, bpm = cvFireBPM:GetFloat(), offset = cvFireOffset:GetFloat(),
        start = now, section = "intro" }
end

local function Heat(kind)
    local h = FIRE_HEAT[kind] or 0
    for npc in pairs(LC.EndingNPCs()) do if IsValid(npc) then npc:SetNW2Float("lc_fire", h) end end
    for _, f in ipairs(E.fliers) do if IsValid(f.e) then f.e:SetNW2Float("lc_fire", h) end end
end

-- the ring in the sky: everyone evenly round it, each at their own height
local function RingPos(f, t, n)
    local fl = E.flight
    local flyT = t - FireAt("fly", 101)
    local w0 = cvFireSpeed:GetFloat()
    local span = math.max(1, FireAt("launch", 146.6) - FireAt("fly", 101))
    local turned = w0 * flyT + w0 * flyT * flyT / (2 * span) -- (the speed doubles over the flight)
    local a = (f.i - 1) / math.max(1, n) * math.pi * 2 + turned
    local z = fl.z - 60 + 140 * ((f.i * 0.618) % 1) + 30 * math.sin(t * 1.3 + f.i)
    return Vector(fl.centre.x + math.cos(a) * fl.r, fl.centre.y + math.sin(a) * fl.r, z), a
end

local function Burst(f, now)
    local e = f.e
    if not IsValid(e) then return end
    local at = e:GetPos() + Vector(0, 0, 30)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(at)
        util.Effect("Explosion", fx, true, true) -- (only the look and the sound: nobody's hurt)
        for i = 1, 12 do
            local c = FIRE_PAL[i % #FIRE_PAL + 1]
            local cf = EffectData()
            cf:SetOrigin(at + VectorRand() * 90)
            if cf.SetStart then cf:SetStart(Vector(c[1], c[2], c[3])) end
            util.Effect("balloon_pop", cf)
        end
    end
    if e:IsPlayer() then
        e:SetNW2Float("lc_fire", 0)
        e:SetNW2Bool("lc_flying", false)
        Spectator(e, "Your behind takes you all the way up, and you go off like a firework. Watch the rest go.", Color(255, 140, 30, 90))
    else
        e:SetNW2Float("lc_fire", 0)
        e:SetNW2Bool("lc_flying", false)
        if e.lcCrowd then e:Remove() elseif e.SetNoDraw then e:SetNoDraw(true) end
    end
    f.gone = true
end

TICK.fire = function(now)
    local t = now - E.phaseT
    local kind = FireSection(t)
    if kind ~= E.client.section then
        E.client.section = kind
        Heat(kind)
        -- each new section starts with a roar
        for i, f in ipairs(E.fliers) do
            if IsValid(f.e) and i <= 30 and sound and sound.Play then
                if kind == "ignite" then sound.Play("ambient/fire/ignite.wav", f.e:GetPos(), 80, math.random(90, 115), 0.8)
                elseif kind == "fly" then sound.Play("weapons/rpg/rocketfire1.wav", f.e:GetPos(), 85, math.random(85, 110), 0.8) end
            end
        end
        Send()
    end
    local bpm = math.max(40, cvFireBPM:GetFloat())
    local beat = (t - cvFireOffset:GetFloat()) * bpm / 60
    local n = #E.fliers
    local flyAt, launchAt = FireAt("fly", 101), FireAt("launch", 146.6)
    for _, f in ipairs(E.fliers) do
        local e = f.e
        if IsValid(e) and not f.gone then
            local pos, yaw
            if t < flyAt then
                -- on the ground: hopping on the beat once the flames are big enough
                pos = f.home
                if kind == "hop" then pos = f.home + Vector(0, 0, cvFireHop:GetFloat() * math.abs(math.sin(beat * math.pi))) end
            else
                local ring, a = RingPos(f, t, n)
                local ft = t - flyAt
                if not f.up then
                    f.up = true
                    e:SetNW2Bool("lc_flying", true)
                    e:SetNW2Bool("lc_dancing", true)
                end
                if ft < RISE then
                    -- lift off: straight up, faster and faster, to the ring's height
                    local s = (ft / RISE) ^ 2
                    pos = Vector(f.home.x, f.home.y, Lerp(s, f.home.z, ring.z))
                    yaw = math.deg(math.atan2(ring.y - f.home.y, ring.x - f.home.x))
                elseif ft < RISE + OUT then
                    -- out onto the ring
                    local from = Vector(f.home.x, f.home.y, ring.z)
                    pos = LerpVector(Smooth((ft - RISE) / OUT), from, ring)
                    yaw = math.deg(math.atan2(ring.y - from.y, ring.x - from.x))
                else
                    pos = ring
                    yaw = math.deg(a) + 90 -- (round the ring, the way it turns)
                end
                if t >= launchAt then
                    -- the end: one after another, straight up, and bang
                    f.launchT = f.launchT or (now + ((f.i - 1) % 12) * 0.25)
                    if now >= f.launchT then
                        if not f.launchFrom then
                            f.launchFrom = e:GetPos()
                            if sound and sound.Play then sound.Play("weapons/rpg/rocketfire1.wav", f.launchFrom, 90, 120, 0.9) end
                        end
                        local lt = now - f.launchT
                        local top = (E.flight.top or (f.launchFrom.z + 600)) - 40
                        pos = Vector(f.launchFrom.x, f.launchFrom.y, math.min(top, f.launchFrom.z + 250 * lt + 500 * lt * lt))
                        if lt >= 1.4 then Burst(f, now) end
                    else
                        pos = pos or e:GetPos()
                    end
                end
            end
            if not f.gone then
                e:SetPos(pos)
                if yaw then
                    e:SetNW2Float("lc_fly_yaw", yaw)
                    if not e:IsPlayer() and e.SetAngles then e:SetAngles(Angle(0, yaw, 0)) end
                end
            end
        end
    end
end
end

-- Plane (a codeword): numa numa. Like the band in the video, everyone dances
-- on the wings of an airplane over the city. It circles low through the
-- intro; at the first hook everyone (and some of the Combine) is up on it,
-- doing the webcam dance, everyone's jaw mouthing the words; the verses
-- cruise, the choruses swoop and roll, the breakdown glides, the last chorus
-- is fastest, with fireworks; on the final note it climbs into the clouds.
local cvPlaneSections = CreateConVar("lc_ending_plane_sections", "17:board,26:verse,63:chorus,89:verse,122:chorus,148:break,167:final,210:climb,215:end", FLAGS,
    "Plane: the song's sections, second:kind (board, verse, chorus, break, final, climb, end); before the first, it circles low")
local cvPlaneCaptions = CreateConVar("lc_ending_plane_captions", "15.1=MA-IA-HII|16.3=MA-IA-HUU|17.5=MA-IA-HOO|18.7=MA-IA-HAHA", FLAGS,
    "Plane: the sing-along captions, second=TEXT, separated by | (the choruses add their own)")
local cvPlaneBPM = CreateConVar("lc_ending_plane_bpm", "130", FLAGS, "Plane: the song's beats per minute")
local cvPlaneCombine = CreateConVar("lc_ending_plane_combine", "8", FLAGS, "Plane: how many of the Combine's Civil Protection units get on the wings too")
local cvPlaneModelYaw = CreateConVar("lc_ending_plane_model_yaw", "-90", FLAGS, "Plane: which way its body model's nose points, turned to the way it flies (-90, 90, 0 or 180: whichever puts the nose in front)")
local PLANE_BODY, PLANE_WING = { "models/xqm/jetbody3.mdl", "models/props_vehicles/van001a_physics.mdl" }, "models/xqm/airplanewing1.mdl"
local FIREWORK = { { 255, 60, 60 }, { 255, 210, 60 }, { 80, 200, 255 }, { 120, 255, 120 }, { 255, 100, 230 } }

local function PlaneSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- A place on the wings and the roof: out along each wing, a few rows deep.
local function WingSpot(i)
    local side = (i % 2 == 0) and 1 or -1
    local k = math.floor((i - 1) / 2)
    local along, row = k % 5, math.floor(k / 5)
    return Vector(-40 + row * 50, side * (90 + along * 55), 80 + row * 6)
end

local function PlaneBoard(e)
    if not IsValid(e) or e.lcEndRide or not IsValid(E.plane) then return end
    E.planeSeat = (E.planeSeat or 0) + 1
    e.lcEndRide = { v = E.plane, off = WingSpot(E.planeSeat) }
    E.riders = E.riders or {}
    E.riders[#E.riders + 1] = e
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        HoldOn(e)
    end
    e:SetNW2Entity("lc_riding", E.plane)
    e:SetNW2Bool("lc_dancing", true)
end

-- The flight, every frame (and every tick, which is all a test has): wide and steady in the
-- verses, swooping in the choruses, a glide in the break, a barrel roll on the big hits
-- (round the way it's flying: everyone on it goes round with it).
local function OnPlane(frame, pos, off)
    return pos + frame:Forward() * off.x - frame:Right() * off.y + frame:Up() * off.z
end
function LC.PlaneStep(now)
    if not E or E.id ~= "plane" or E.phase ~= "apocalypse" or not IsValid(E.plane) then return end
    local plane = E.plane
    local dt = math.Clamp(now - (E.planeStepAt or now), 0, 0.25)
    E.planeStepAt = now
    local t = now - E.phaseT
    local kind = E.client.section or "intro"
    local speed = ({ intro = 0.12, board = 0.15, verse = 0.14, chorus = 0.24, ["break"] = 0.07, final = 0.32, climb = 0.2 })[kind] or 0.14
    E.planeA = E.planeA + speed * dt
    -- (in open sky: E.flight, so the plane, its riders and the camera stay out of the buildings)
    local sky = E.flight or LC.EndingSky(E.lz)
    local r = sky.r
    local height = sky.z
    if kind == "chorus" or kind == "final" then height = height - 120 + math.sin(t * 0.9) * 120 end
    if kind == "climb" then E.climb = math.min((E.climb or 0) + (60 + (E.climb or 0) * 0.08) * dt * 10, math.max(0, sky.top - sky.z - 40)) end
    local pos = Vector(sky.centre.x + math.cos(E.planeA) * r, sky.centre.y + math.sin(E.planeA) * r, height + (E.climb or 0))
    local yaw = math.deg(E.planeA) + 90
    local bank = (kind == "chorus" or kind == "final") and 30 or 12
    local roll = bank
    if E.rollFrom and now - E.rollFrom < 2 then
        local f = (now - E.rollFrom) / 2
        roll = bank + 360 * (f * f * (3 - 2 * f))
    end
    local pitch = kind == "climb" and -70 or math.sin(t * 0.7) * 6
    local ceil = CeilingAt(pos) -- (well under the sky right there, which can come lower than over the landing zone)
    if ceil - pos.z < 240 then pos.z = ceil - 240 end
    local cur = plane:GetPos()
    if CeilingAt(cur) <= cur.z + 1 then cur = cur - Vector(0, 0, 250) end
    pos = LerpVector(1 - 0.6 ^ (dt * 10), cur, pos)
    -- the way it flies (its frame), and the body model turned to it (lc_ending_plane_model_yaw)
    local frame = Angle(pitch, yaw, roll)
    E.planeFrame = frame
    local body = Angle(frame.p, frame.y, frame.r)
    if body.RotateAroundAxis then body:RotateAroundAxis(frame:Up(), cvPlaneModelYaw:GetFloat()) end
    plane:SetPos(pos)
    plane:SetAngles(body)
    for _, w in ipairs(E.wings or {}) do
        if IsValid(w.e) then
            w.e:SetPos(OnPlane(frame, pos, Vector(0, w.side * 160, 40)))
            local wa = Angle(frame.p, frame.y, frame.r)
            if w.side < 0 and wa.RotateAroundAxis then wa:RotateAroundAxis(frame:Up(), 180) end
            w.e:SetAngles(wa)
        end
    end
    for _, e in ipairs(E.riders or {}) do
        local rd = IsValid(e) and e.lcEndRide
        if rd and rd.v == plane then
            e:SetPos(OnPlane(frame, pos, rd.off))
            if not e:IsPlayer() then e:SetAngles(Angle(frame.p, frame.y, frame.r)) end -- (the Combine's units go round with it; a player can't be turned over)
        end
    end
end
hook.Add("Think", "LivingCityPlane", function() if E and E.id == "plane" then LC.PlaneStep(CurTime()) end end)

SETUP.plane = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvPlaneSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 215)
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    -- the plane: a body and two wings, low over the city
    E.flight = LC.EndingSky(E.lz)
    local body = Prop(FirstModel(PLANE_BODY), Vector(E.flight.centre.x + E.flight.r, E.flight.centre.y, E.flight.z), 3)
    if not body then return end
    if body.SetSolid then body:SetSolid(SOLID_NONE) end
    E.plane = body
    E.wings = {}
    if not util.IsValidModel or util.IsValidModel(PLANE_WING) then
        for _, side in ipairs({ -1, 1 }) do
            local w = Prop(PLANE_WING, body:GetPos(), 3)
            if w then
                if w.SetSolid then w:SetSolid(SOLID_NONE) end
                E.wings[#E.wings + 1] = { e = w, side = side }
            end
        end
    end
    E.planeA, E.roll = 0, 0
    E.planeFrame = Angle(0, 90, 0)
    local caps = LC.BaseLines(cvPlaneCaptions:GetString())
    E.client = { party = true, lights = true, dance = "numa", bpm = cvPlaneBPM:GetFloat(), offset = 0, start = now, section = "intro",
        palette = FIREWORK, captions = caps, webcam = true, lipsync = true }
end

TICK.plane = function(now)
    local plane = E.plane
    if not IsValid(plane) then return end
    local t = now - E.phaseT
    local kind = PlaneSection(t)
    local beat = t * cvPlaneBPM:GetFloat() / 60
    if kind ~= E.client.section then
        E.client.section = kind
        E.client.lights = kind ~= "break"
        if kind == "board" then
            for _, p in ipairs(LC.EndingPlayers()) do PlaneBoard(p) end
            local c = 0
            for _, npc in ipairs(CombineNPCs()) do if c < cvPlaneCombine:GetInt() then c = c + 1 PlaneBoard(npc) end end
        elseif kind == "climb" then
            E.client.whiteAt = now + 3
        end
        Send()
    end
    if E.planeSeat then for _, p in ipairs(LC.EndingPlayers()) do PlaneBoard(p) end end -- (anyone joining, or back)
    if (kind == "chorus" or kind == "final") and math.floor(beat) % 16 == 0 and math.floor(beat) ~= E.rollBeat then
        E.rollBeat = math.floor(beat)
        E.rollFrom = now
    end
    LC.PlaneStep(now)
    -- fireworks round it in the last chorus
    if kind == "final" and now >= (E.nextFirework or 0) then
        E.nextFirework = now + math.Rand(0.3, 0.8)
        if util.Effect and EffectData then
            local fx = EffectData()
            fx:SetOrigin(plane:GetPos() + VectorRand() * 600 + Vector(0, 0, 200))
            local c = FIREWORK[math.random(#FIREWORK)]
            if fx.SetStart then fx:SetStart(Vector(c[1], c[2], c[3])) end
            util.Effect("balloon_pop", fx)
            util.Effect("cball_explode", fx)
            E.fwBig = (E.fwBig or 0) + 1
            if E.fwBig % 3 == 0 then
                util.Effect("Explosion", fx) -- (every third one a big bang)
                if sound and sound.Play then sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", (fx.GetOrigin and fx:GetOrigin()) or plane:GetPos(), 100, math.random(95, 115), 0.8) end
            end
        end
        if sound and sound.Play then sound.Play("weapons/flaregun/burn.wav", plane:GetPos(), 90, math.random(90, 130), 0.6) end
    end
end

-- Standup (a codeword): the rope. Every other beat from lc_ending_standup_sections'
-- "hang", someone else is strung up: a rope from whatever is above them (a
-- ledge, a balcony, a ceiling), or from the nearest wall of a building, or
-- failing both, from the sky. Players are spread through the song; the
-- city's people (the Combine's units too) fill the beats between, and when
-- there's nobody left, new people turn up near you to be next. The hanged
-- swing and struggle while their health drains; at nothing they go limp,
-- and stay hanging there, looking on.
local cvStandupSections = CreateConVar("lc_ending_standup_sections", "11:hang,104:last,110:end", FLAGS,
    "Standup: the song's sections, second:kind (hang, last, end)")
local cvStandupBPM   = CreateConVar("lc_ending_standup_bpm", "133", FLAGS, "Standup: the song's beats per minute (someone new every other beat)")
local cvStandupDrain = CreateConVar("lc_ending_standup_drain", "4", FLAGS, "Standup: health a second the hanged lose")
local cvStandupMax   = CreateConVar("lc_ending_standup_max", "60", FLAGS, "Standup: the most people strung up in all")
local cvStandupCrowd = CreateConVar("lc_ending_standup_crowd", "14", FLAGS, "Standup: how many people gather round to cheer")
-- (the hanged are painted white, white cone hats on: the Klan, strung up, and the crowd loves it)
local CROWD = {
    "models/humans/group01/male_01.mdl", "models/humans/group01/male_03.mdl", "models/humans/group01/male_04.mdl", "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_09.mdl", "models/humans/group01/female_01.mdl", "models/humans/group01/female_03.mdl", "models/humans/group01/female_06.mdl",
    "models/humans/group02/male_02.mdl", "models/humans/group02/male_06.mdl", "models/humans/group02/female_02.mdl", "models/humans/group02/female_04.mdl",
}
local CHEERS = { "vo/npc/male01/yeah02.wav", "vo/npc/female01/yeah02.wav", "vo/npc/male01/fantastic01.wav", "vo/npc/female01/finally.wav",
    "vo/npc/male01/likethat.wav", "vo/npc/female01/nice01.wav", "vo/npc/male01/question17.wav" }

local function StandupSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

-- Where the rope goes: something overhead, else the nearest wall, else the sky.
local function RopeAnchor(pos)
    local up = util.TraceLine({ start = pos + Vector(0, 0, 80), endpos = pos + Vector(0, 0, 900), mask = MASK_SOLID_BRUSHONLY })
    if up.Hit and not up.HitSky then return up.HitPos - Vector(0, 0, 4), Vector(0, 0, 0) end
    local best, bestD, out
    for i = 0, 7 do
        local dir = Angle(0, i * 45, 0):Forward()
        local tr = util.TraceLine({ start = pos + Vector(0, 0, 300), endpos = pos + Vector(0, 0, 300) + dir * 700, mask = MASK_SOLID_BRUSHONLY })
        if tr.Hit and not tr.HitSky and (not bestD or tr.Fraction < bestD) then best, bestD, out = tr.HitPos, tr.Fraction, (tr.HitNormal or -dir) end
    end
    if best then return best + out * 40, out end
    return pos + Vector(0, 0, 500), Vector(0, 0, 0)
end

local function Hang(e)
    if not IsValid(e) or e.lcHang or e.lcEndTaken then return false end
    local pos = e:GetPos()
    local anchor = RopeAnchor(pos)
    local g = Ground(pos)
    local drop = anchor.z - 110 - 72 -- (a rope, then the person under it)
    local feet = math.max(drop, ((g and g.z) or pos.z) + 25)
    e.lcHang = { anchor = anchor, base = Vector(anchor.x, anchor.y, feet), t0 = CurTime() }
    -- (drained fast enough to go limp before the song ends, however late they went up)
    local left = ((E.holdUntil or (CurTime() + 60)) - CurTime()) - 3
    e.lcHang.rate = math.max(cvStandupDrain:GetFloat(), (e.Health and e:Health() or 100) / math.max(1.5, left))
    e:SetNW2Float("lc_hanged", CurTime())
    -- painted white, and a white cone hat pulled down over the head (drawn on every screen
    -- on the head itself, wherever it swings: cl_livingcity_endings.lua; a prop riding along
    -- on the server never showed)
    if e.SetMaterial then e:SetMaterial("models/debug/debugwhite") end
    if e.SetColor then e:SetColor(Color(245, 245, 245, 255)) end
    if e:IsPlayer() then
        if e.InVehicle and e:InVehicle() and e.ExitVehicle then e:ExitVehicle() end
        -- (held there, not frozen: a frozen player can't even look about, and the rope's
        -- view is all about looking about; where they are is set every tick anyway)
        e:Freeze(false)
        e.lcEndFrozen = nil
        e:SetMoveType(MOVETYPE_NONE)
        e:ChatPrint("A rope drops round your neck from above, and up you go. (You can still look about.)")
    end
    e:EmitSound("physics/wood/wood_strain" .. math.random(2, 4) .. ".wav", 80)
    -- and the crowd goes wild
    for i = 1, math.min(3, #(E.crowd or {})) do
        local c = E.crowd[math.random(#E.crowd)]
        if IsValid(c) then c:EmitSound(CHEERS[math.random(#CHEERS)], 80, math.random(95, 108)) end
    end
    E.hanged[#E.hanged + 1] = e
    E.client.hangs[#E.client.hangs + 1] = { e = e:EntIndex(), a = anchor }
    Send()
    return true
end

-- Gone limp: still hanging there, looking on.
local function Limp(e)
    if not IsValid(e) or e.lcEndTaken then return end
    e:SetNW2Bool("lc_limp", true)
    if e:IsPlayer() then
        e.lcEndTaken = true
        e:SetNW2Bool("lc_end_taken", true)
        e:ChatPrint("You stop kicking. You hang there, and watch the rest.")
        hook.Run("LivingCityEndingTook", e, E and E.id)
    end
end

SETUP.standup = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvStandupSections:GetString())
    local hangAt, lastAt = now + 11, now + 104
    for _, sct in ipairs(E.sections) do
        if sct.kind == "end" then E.holdUntil = now + sct.t end
        if sct.kind == "hang" then hangAt = now + sct.t end
        if sct.kind == "last" then lastAt = now + sct.t end
    end
    E.holdUntil = E.holdUntil or (now + 110)
    E.hanged, E.crowd = {}, {}
    E.beatLen = 60 / math.max(1, cvStandupBPM:GetFloat())
    -- the players, spread through the song; everyone else on the beats between
    local ps = LC.EndingPlayers()
    E.playerGap = math.max(E.beatLen * 2, (lastAt - hangAt) / math.max(1, #ps))
    E.nextPlayer = hangAt
    E.nextAny = hangAt
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    E.client = { party = true, lights = false, dance = "cheer", bpm = cvStandupBPM:GetFloat(), offset = 0, start = now, hangs = {} }
end

TICK.standup = function(now)
    local t = now - E.phaseT
    local kind = StandupSection(t)
    -- the crowd gathers round, and cheers every one
    if (kind == "hang" or kind == "last") and not E.crowded then
        E.crowded = true
        local near = Living()[1] or LC.EndingPlayers()[1]
        local centre = near and near:GetPos() or Centre()
        for i = 1, cvStandupCrowd:GetInt() do
            local spot = RingSpot(centre, math.Rand(220, 520), false)
            if spot then
                local c = ents.Create("npc_citizen")
                if IsValid(c) then
                    if c.SetKeyValue then c:SetKeyValue("citizentype", "4") end -- (the model it's given)
                    c:SetModel(CROWD[(i - 1) % #CROWD + 1])
                    c:SetPos(spot)
                    c:SetAngles(Angle(0, (centre - spot):Angle().y, 0))
                    c:Spawn()
                    c.lcCrowd = true
                    c:SetNW2Bool("lc_dancing", true)
                    E.ents[#E.ents + 1] = c
                    E.crowd[#E.crowd + 1] = c
                end
            end
        end
    end
    if kind == "hang" or kind == "last" then
        -- a player, on their turn
        if now >= E.nextPlayer then
            E.nextPlayer = now + E.playerGap
            local pick = {}
            for _, p in ipairs(Living()) do if not p.lcHang then pick[#pick + 1] = p end end
            if #pick > 0 then Hang(pick[math.random(#pick)]) E.nextAny = now + E.beatLen * 2 end
        end
        -- and on every other beat between, somebody else
        if now >= E.nextAny and #E.hanged < cvStandupMax:GetInt() then
            E.nextAny = now + E.beatLen * 2
            local victim
            -- the Combine's units first, every one of them (brought to where you can see it)
            for _, n in ipairs(CombineNPCs()) do if not n.lcHang then victim = n break end end
            if IsValid(victim) then
                local near = Living()[1] or LC.EndingPlayers()[1]
                local spot = near and RingSpot(near:GetPos(), math.Rand(250, 650), false)
                if spot then victim:SetPos(spot) end
            end
            for npc in pairs(LC.EndingNPCs()) do if not victim and IsValid(npc) and not npc.lcHang and not npc.lcCrowd then victim = npc break end end
            if not victim then
                -- nobody left: someone turns up near one of you to be next
                local near = Living()[1] or LC.EndingPlayers()[1]
                local spot = near and RingSpot(near:GetPos(), math.Rand(250, 600), false)
                if spot then
                    victim = ents.Create("npc_citizen")
                    if IsValid(victim) then
                        victim:SetPos(spot)
                        victim:Spawn()
                        E.ents[#E.ents + 1] = victim
                    end
                end
            end
            if IsValid(victim) then Hang(victim) end
        end
    end
    -- the last of the song: everyone left goes up
    if kind == "last" and not E.lastHang then
        E.lastHang = true
        for _, p in ipairs(Living()) do if not p.lcHang then Hang(p) end end
        for _, n in ipairs(CombineNPCs()) do if not n.lcHang then Hang(n) end end -- (and every unit of the Combine still standing)
    end
    -- the hanged: swinging, turning, and (the living) losing health
    local drain = cvStandupDrain:GetFloat() * 0.1
    for _, e in ipairs(E.hanged) do
        local h = IsValid(e) and e.lcHang
        if h then
            local k = now - h.t0
            local limp = e:GetNW2Bool("lc_limp", false)
            local swing = limp and 4 or 10
            e:SetPos(h.base + Vector(math.sin(k * 1.3) * swing, math.cos(k * 1.1) * swing * 0.6, 0))
            e:SetAngles(Angle(0, (k * (limp and 6 or 25)) % 360, 0))
            if not limp then
                if e:IsPlayer() then
                    e.lcHangHP = (e.lcHangHP or e:Health()) - (h.rate and h.rate * 0.1 or drain)
                    e:SetHealth(math.max(1, math.floor(e.lcHangHP)))
                    if e.lcHangHP <= 0 then Limp(e) end
                elseif k > 6 then
                    Limp(e)
                end
            end
        end
    end
end

-- The hanged can't do anything about it.
hook.Add("CanPlayerSuicide", "LivingCityStandup", function(p) if p.lcHang then return false end end)

-- The Flood: Father Grigori's song. A stage floats at the landing zone with
-- everyone on it; the storm is at its worst; the water rises over the city.
-- The song's sections (lc_ending_flood_sections, worked out from the song
-- itself) set how violent it is: the stage pitches and the waves knock
-- people off, ichthyosaurs circle under the water, go for anyone in it, and
-- leap at anyone near the edge; lightning on the big beats. In the water
-- you swim (Jump to go up) and can climb back on, but stay under too long
-- and you drown. Father Grigori rocks out the whole time, untouchable, and
-- goes last, on the final note.
local cvFloodSections = CreateConVar("lc_ending_flood_sections", "15:heavy,79:calm,102:heavy,134:calm,169:heavy,183:climax,212:calm,235:heavy,249:climax,264:outro,276:last,285:end", FLAGS,
    "The Flood: the song's sections, second:kind (calm, heavy, climax, outro, last, end); before the first, it builds")
local cvFloodBPM   = CreateConVar("lc_ending_flood_bpm", "150", FLAGS, "The Flood: the song's beats per minute (the lightning keeps to it)")
local cvFloodRise  = CreateConVar("lc_ending_flood_rise", "900", FLAGS, "The Flood: how high the water rises over the landing zone by the outro")
local cvFloodDrown = CreateConVar("lc_ending_flood_drown", "15", FLAGS, "The Flood: seconds under the water before you drown")
local cvIcthys     = CreateConVar("lc_ending_flood_icthys", "8", FLAGS, "The Flood: how many ichthyosaurs at the worst of it")
local cvFloodCrowd = CreateConVar("lc_ending_flood_crowd", "10", FLAGS, "The Flood: how many of the city's people and the Combine's Civil Protection units are on the stage too, headbanging (the big waves take them one by one)")
local cvFloodAttack = CreateConVar("lc_ending_flood_attack_from", "140", FLAGS, "The Flood: seconds into the song before the ichthyosaurs bite or leap at anyone (till then they circle)")
local cvFloodBoats = CreateConVar("lc_ending_flood_boats", "6", FLAGS, "The Flood: rowboats floating round the stage (climb in from the water with Jump; the waves don't throw you out of them)")
local BOATS = { "models/props_canal/boat001a.mdl", "models/props_canal/boat001b.mdl", "models/props_canal/boat002b.mdl", "models/hunter/plates/plate2x4.mdl" }
local STAGE_LIGHTS = { { 255, 255, 255 }, { 80, 140, 255 }, { 255, 60, 60 }, { 255, 200, 60 } }
local INTENSITY = { intro = 0.3, calm = 0.35, heavy = 0.75, climax = 1, outro = 0.25, last = 0.1 }
local STAGE_MODEL, STAGE_R = "models/hunter/plates/plate8x8.mdl", 170

local function FloodSection(t)
    local kind = "intro"
    for _, sct in ipairs(E.sections) do if t >= sct.t then kind = sct.kind end end
    return kind
end

local function OnStage(p)
    local st = E.stage
    if not IsValid(st) then return false end
    local d = p:GetPos() - st:GetPos()
    return math.abs(d.x) < STAGE_R + 20 and math.abs(d.y) < STAGE_R + 20 and d.z > -20 and d.z < 140
end
local function StageSpot(spread)
    local st = E.stage
    return st:GetPos() + Vector(math.Rand(-spread, spread), math.Rand(-spread, spread), (E.stageTop or 2) + 3) -- (on the deck, not in it)
end
local function Immune(p) return p == E.grigori end

local function Bite(p, how)
    local now = CurTime()
    if not IsValid(p) or p.lcEndTaken or Immune(p) or now < (p.lcBiteAt or 0) then return false end
    p.lcBiteAt = now + 1.5
    p:EmitSound("npc/ichthyosaur/snap.wav", 85)
    if not p:IsPlayer() then -- (one of the crowd, swept off: gone in one)
        if util.Effect and EffectData then local fx = EffectData() fx:SetOrigin(p:GetPos() + Vector(0, 0, 30)) util.Effect("BloodImpact", fx) end
        p.lcEndTaken = true
        p:Remove()
        return true
    end
    p:SetHealth(p:Health() - math.random(6, 10))
    if p.ViewPunch then p:ViewPunch(Angle(math.Rand(-15, 15), math.Rand(-15, 15), 0)) end
    if p:Health() <= 0 then Spectator(p, how or "Something huge comes up out of the dark water. That's the last you see.", Color(20, 40, 90, 230)) end
    return true
end

function LC.IcthyStep(m, dt)
    local s = m.lcIcthy
    if not s or not E or E.id ~= "water" then return end
    local now = CurTime()
    if s.leap then
        local L = s.leap
        local f = math.min(1, (now - L.t0) / L.dur)
        m:SetPos(LerpVector(f, L.from, L.to) + Vector(0, 0, 4 * L.h * f * (1 - f)))
        if f >= 1 then
            s.leap = nil
            local t = s.target
            if IsValid(t) and t:GetPos():DistToSqr(m:GetPos()) < 100 * 100 and Bite(t, "It comes over the edge of the stage at you, jaws first. That's the last you see.") then
                local away = t:GetPos() - E.stage:GetPos()
                away.z = 0
                if t.SetVelocity and not t.lcEndTaken then t:SetVelocity(away:GetNormalized() * 400 + Vector(0, 0, 200)) end
            end
        end
        return
    end
    if not s.goal then return end
    local pos = m:GetPos()
    local to = s.goal - pos
    local dist = to:Length()
    if dist < 8 then return end
    local dir = to * (1 / dist)
    local nextPos = pos + dir * math.min(dist, (s.speed or 200) * (dt or 0.1))
    nextPos.z = math.min(nextPos.z, (E.floodZ or nextPos.z) - 45) -- (under the water, always)
    m:SetPos(nextPos)
    m:SetAngles(Angle(0, dir:Angle().y, 0))
end

function LC.IcthyHurt(m, dmg)
    local s = m.lcIcthy
    if not s then return false end
    s.hp = s.hp - (dmg and dmg.GetDamage and dmg:GetDamage() or 150)
    if s.hp > 0 then return false end
    m:EmitSound("npc/ichthyosaur/die1.wav", 85)
    m:Remove()
    E.nextIcthy = CurTime() + 6
    return true
end

local function SpawnIcthy()
    local st = E.stage
    local a = math.Rand(0, math.pi * 2)
    local pos = st:GetPos() + Vector(math.cos(a), math.sin(a), 0) * math.Rand(600, 900)
    pos.z = E.floodZ - 70
    if not Room() then return end
    local m = ents.Create("lc_icthy")
    if not IsValid(m) then return end
    m:SetModel("models/ichthyosaur.mdl")
    m:SetPos(pos)
    m:Spawn()
    m.lcIcthy = { hp = 150, a = a, dir = math.random() < 0.5 and 1 or -1 }
    E.ents[#E.ents + 1] = m
    E.icthys[#E.icthys + 1] = m
end

SETUP.water = function()
    local now = CurTime()
    E.songEnds = true -- (it is over when the song is)
    E.sections = LC.MarrowSections(cvFloodSections:GetString())
    for _, sct in ipairs(E.sections) do if sct.kind == "end" then E.holdUntil = now + sct.t end end
    E.holdUntil = E.holdUntil or (now + 285)
    E.riseBy = now + 264
    for _, sct in ipairs(E.sections) do if sct.kind == "outro" then E.riseBy = now + sct.t end end
    local lz = E.dream and { { pos = E.dream.pos } } or (LC.PointsOfKind and LC.PointsOfKind("lz")) or {} -- (a dream: round the dream point)
    E.lz = (#lz > 0 and lz[1].pos) or (IsValid(E.by) and E.by:GetPos()) or Centre()
    E.floodBase = E.lz.z - 30
    E.floodZ = E.floodBase
    -- real water, if the map has it: a func_water_analog named lc_flood (the
    -- mapper's own rising water, the way Half-Life 2 does it). Then the engine
    -- does the swimming; otherwise the water is drawn and the swimming is ours.
    local real = not E.dream and ents.FindByName and ents.FindByName("lc_flood")[1] -- (a dream: never the city's own water)
    if IsValid(real) then
        E.realWater = real
        SetGlobal2Bool("lc_flood_real", true)
        real:Fire("Open") -- (func_water_analog rises to its open position; SetPosition below follows the song)
    end
    E.icthys = {}
    LC.TimeStopped = (not E.dream) or nil
    if RunConsoleCommand and not E.dream then RunConsoleCommand("ai_disabled", "1") end -- (a dream: its own NPCs are held instead)
    -- the stage, at the landing zone
    local st = Prop(STAGE_MODEL, E.lz + Vector(0, 0, 4))
    if st then
        if st.PhysicsInit then st:PhysicsInit(SOLID_VPHYSICS) end
        local ph = st.GetPhysicsObject and st:GetPhysicsObject()
        if IsValid(ph) then ph:EnableMotion(false) end
        if st.SetMaterial then st:SetMaterial("phoenix_storms/wood") end
    end
    E.stage = st
    E.stageTop = math.Clamp((IsValid(st) and st.OBBMaxs and st:OBBMaxs().z) or 2, 0, 12) -- (how far the deck is above the stage's middle)
    -- Father Grigori in the middle, everyone round him: the player who ate it,
    -- or (an admin started it) the city's own Father Grigori, or one for the occasion
    local by = E.by
    if IsValid(by) and by:IsPlayer() and by:GetNW2String("lcf_special", "") == "chaplain" and (not E.dream or by.lcDreaming) then
        E.grigori = by
    else
        local g = (not E.dream and IsValid(LC.Grigori)) and LC.Grigori or nil -- (a dream: one of its own, not the city's)
        if not IsValid(g) then
            g = ents.Create("npc_monk")
            if IsValid(g) then
                g:Spawn()
                g:SetNW2String("lc_pname", "Father Grigori")
                E.ents[#E.ents + 1] = g
            end
        end
        if IsValid(g) then
            -- (time's stopped: standing, not the T pose; the headbanging is on each screen)
            StandIdle(g)
            timer.Simple(0.3, function() StandIdle(g) end)
            if IsValid(st) then g:SetPos(st:GetPos() + Vector(0, 0, E.stageTop + 1)) end
            E.grigori = g
        end
    end
    if IsValid(E.grigori) then E.grigori:SetNW2Bool("lc_rocking", true) end
    -- and a crowd up there with him: the Combine's units and the city's people, headbanging along
    E.crowd = {}
    local pool = {}
    for _, n in ipairs(CombineNPCs()) do pool[#pool + 1] = n end
    for _, c in ipairs(CityFolk()) do if c ~= E.grigori then pool[#pool + 1] = c end end
    for i = #pool, 2, -1 do local j = math.random(i) pool[i], pool[j] = pool[j], pool[i] end
    local want = cvFloodCrowd:GetInt()
    for i = 1, want do
        local c = pool[i]
        if not IsValid(c) and IsValid(st) then c = SpawnFolk(StageSpot(STAGE_R - 30), i) end
        if IsValid(c) and IsValid(st) then
            c:SetPos(StageSpot(STAGE_R - 30))
            c:SetAngles(Angle(0, (st:GetPos() - c:GetPos()):Angle().y, 0))
            c:SetNW2Bool("lc_rocking", true)
            c:SetNW2Bool("lc_crowd", true)
            E.crowd[#E.crowd + 1] = c
        end
    end
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.InVehicle and p:InVehicle() and p.ExitVehicle then p:ExitVehicle() end
        if IsValid(st) then p:SetPos(p == E.grigori and (st:GetPos() + Vector(0, 0, E.stageTop + 1)) or StageSpot(STAGE_R - 40)) end
        if p:Health() < 100 then p:SetHealth(100) end
    end
    -- the worst storm the city has seen
    if LC.SetWeather and not E.dream then LC.SetWeather("storm", true) end -- (a dream: no storm over the city)
    if not E.dream then SetGlobal2Bool("lc_storm_max", true) end
    E.dark = not E.dream
    if not E.dream then LC.EndingDark = "e" end
    if LC.ApplyLightStyle and not E.dream then LC.ApplyLightStyle() end
    -- rowboats round the stage, bobbing: somewhere to climb into out of the water
    E.boats = {}
    local nb = cvFloodBoats:GetInt()
    for i = 1, nb do
        local a = (i - 0.5) / math.max(1, nb) * math.pi * 2
        local bp = (IsValid(st) and st:GetPos() or E.lz) + Vector(math.cos(a), math.sin(a), 0) * (STAGE_R + 260)
        local mdl = FirstModel(BOATS)
        local b = Prop(mdl, bp)
        if b then
            if b.PhysicsInit then b:PhysicsInit(SOLID_VPHYSICS) end
            local ph = b.GetPhysicsObject and b:GetPhysicsObject()
            if IsValid(ph) then ph:EnableMotion(false) end
            if string.find(mdl, "plate", 1, true) and b.SetMaterial then b:SetMaterial("phoenix_storms/wood") end
            E.boats[#E.boats + 1] = { e = b, a = a, r = STAGE_R + 260, i = i }
        end
    end
    E.section = "intro"
    -- (the beat Father Grigori headbangs to; stage lights round the deck, sweeping the storm)
    E.client = { bpm = cvFloodBPM:GetFloat(), offset = 0, start = now, spots = IsValid(st) or nil, spotEnt = IsValid(st) and st:EntIndex() or nil,
        spotR = STAGE_R - 10, spotUp = (E.stageTop or 2) + 2, spotN = 6, spotCols = STAGE_LIGHTS, spotCycle = true }
end

TICK.water = function(now)
    local st = E.stage
    if not IsValid(st) then return end
    local t = now - E.phaseT
    local kind = FloodSection(t)
    E.section = kind
    if E.client and E.client.section ~= kind then E.client.section = kind Send() end -- (Father Grigori headbangs the heavy parts and dances the rest)
    local I = INTENSITY[kind] or 0.5
    SetGlobal2Float("lc_flood_slosh", I)
    -- the water rises, and the stage floats on it
    local k = math.Clamp(t / math.max(1, E.riseBy - E.phaseT), 0, 1)
    E.floodZ = E.floodBase + cvFloodRise:GetFloat() * (1 - (1 - k) ^ 2)
    if IsValid(E.realWater) then
        -- the map's own water: raised along its path, and its surface is the water line
        E.realWater:Fire("SetPosition", tostring(1 - (1 - k) ^ 2))
        local top = E.realWater.OBBMaxs and E.realWater:LocalToWorld(E.realWater:OBBMaxs()).z
        if top then E.floodZ = top end
    end
    SetGlobal2Float("lc_flood_z", E.floodZ)
    -- the deck rides a little above the water line, and everyone on it rises with it
    -- (moved up under them otherwise, they'd end up stuck inside it)
    local sp = st:GetPos()
    local deckOff = E.stageTop or 2
    st:SetPos(Vector(sp.x, sp.y, math.max(E.lz.z + 4, E.floodZ + 6 - deckOff)))
    local top = st:GetPos().z + deckOff
    local riders = {}
    for _, p in ipairs(LC.EndingPlayers()) do if not p.lcEndSpectating then riders[#riders + 1] = p end end
    if IsValid(E.grigori) and not E.grigori:IsPlayer() then riders[#riders + 1] = E.grigori end
    for _, c in ipairs(E.crowd or {}) do if IsValid(c) and not c.lcSwept then riders[#riders + 1] = c end end
    for _, p in ipairs(riders) do
        local pp = p:GetPos()
        local d = pp - st:GetPos()
        if math.abs(d.x) < STAGE_R + 16 and math.abs(d.y) < STAGE_R + 16 and pp.z < top + 1 and pp.z > top - 70 then
            p:SetPos(Vector(pp.x, pp.y, top + 1))
        end
    end
    -- the waves: a shove all the time, and a big one now and then
    local wave = Angle(0, (t * 25 + math.sin(t * 0.13) * 120) % 360, 0):Forward()
    local big = now >= (E.nextWave or 0)
    if big then
        E.nextWave = now + math.Rand(6, 10) * (1.2 - I)
        st:EmitSound("ambient/water/wave" .. math.random(1, 6) .. ".wav", 90)
        -- and one of the crowd goes over the side
        local on = {}
        for _, c in ipairs(E.crowd or {}) do if IsValid(c) and not c.lcSwept then on[#on + 1] = c end end
        if #on > 0 and math.random() < 0.35 + 0.5 * I then
            local c = on[math.random(#on)]
            local out = c:GetPos() - st:GetPos()
            out.z = 0
            out = out:Length() > 1 and out:GetNormalized() or Vector(1, 0, 0)
            c.lcSwept = now
            c:SetNW2Bool("lc_rocking", false)
            c:SetPos(st:GetPos() + out * (STAGE_R + 90) + Vector(0, 0, -30))
            c:EmitSound(math.random() < 0.5 and "vo/npc/male01/help01.wav" or "vo/npc/female01/help01.wav", 80)
        end
        if util.ScreenShake then util.ScreenShake(st:GetPos(), 2 + 6 * I, 5, 1.2, 900) end
    end
    local g = E.grigori
    for _, p in ipairs(Living()) do
        if p ~= g then
            if OnStage(p) and p.SetVelocity then
                local push = wave * ((big and (120 + 180 * I) or (10 + 30 * I)) * math.Rand(0.6, 1.2))
                p:SetVelocity(Vector(push.x, push.y, big and 60 or 0))
            end
            -- in the water by the edge: hold Jump and you haul yourself back up onto it
            if not OnStage(p) and p.KeyDown and p:KeyDown(IN_JUMP) then
                local d = p:GetPos() - st:GetPos()
                if math.abs(d.x) < STAGE_R + 90 and math.abs(d.y) < STAGE_R + 90 and p:GetPos().z > E.floodZ - 110 then
                    local inward = Vector(math.Clamp(d.x, -(STAGE_R - 20), STAGE_R - 20), math.Clamp(d.y, -(STAGE_R - 20), STAGE_R - 20), 0)
                    p:SetPos(st:GetPos() + inward + Vector(0, 0, (E.stageTop or 2) + 3))
                    p.lcEndUnder = nil
                end
            end
            -- under the water: you hold your breath, then you drown
            if p:EyePos().z < E.floodZ then
                p.lcEndUnder = p.lcEndUnder or now
                if now - p.lcEndUnder > cvFloodDrown:GetFloat() then
                    Spectator(p, "The water closes over your head. Somewhere above, Father Grigori hits the high note.", Color(20, 40, 90, 230))
                end
            else
                p.lcEndUnder = nil
            end
        end
    end
    -- the swept away: down into the water, and gone
    for _, c in ipairs(E.crowd or {}) do
        if IsValid(c) and c.lcSwept then
            local cp = c:GetPos()
            local g = Ground(cp)
            local z = math.max(E.floodZ - 55, (g and g.z or -math.huge) + 2) -- (under the surface, floundering; not through the ground)
            c:SetPos(Vector(cp.x, cp.y, math.max(z, math.min(cp.z - 6, E.floodZ - 30))))
            if now - c.lcSwept > 8 then c:Remove() end -- (or the ichthyosaurs get them first)
        end
    end
    -- Father Grigori keeps his feet, whatever happens
    if IsValid(g) and not g.lcEndTaken then
        if not OnStage(g) then g:SetPos(st:GetPos() + Vector(0, 0, (E.stageTop or 2) + 1)) end
        if g:Health() < 100 then g:SetHealth(100) end
        -- (he headbangs, mic in hand: cl_livingcity_endings.lua, on the song's beat)
    end
    -- the rowboats: round the stage on the water, bobbing, carrying whoever's in them
    local inBoat = {}
    for _, bt in ipairs(E.boats or {}) do
        local b = bt.e
        if IsValid(b) then
            local was = b:GetPos()
            bt.a = bt.a + 0.004
            local bp = st:GetPos() + Vector(math.cos(bt.a), math.sin(bt.a), 0) * bt.r
            local gr = Ground(Vector(bp.x, bp.y, E.floodZ + 40))
            bp.z = math.max(E.floodZ - 10 + math.sin(t * 1.3 + bt.i) * 3, (gr and gr.z or -math.huge) + 2)
            local delta = bp - was
            for _, p in ipairs(riders) do
                local d = p:GetPos() - was
                if d:Length2D() < 90 and d.z > -30 and d.z < 90 and not OnStage(p) then
                    p:SetPos(p:GetPos() + delta)
                    inBoat[p] = b
                end
            end
            b:SetPos(bp)
            b:SetAngles(Angle(math.sin(t * 0.9 + bt.i) * 4, math.deg(bt.a) + 90, math.cos(t * 1.1 + bt.i) * 5))
            -- in the water next to one, hold Jump to climb in
            for _, p in ipairs(Living()) do
                if p ~= E.grigori and not inBoat[p] and not OnStage(p) and p.KeyDown and p:KeyDown(IN_JUMP) then
                    local d = p:GetPos() - bp
                    if d:Length2D() < 120 and p:GetPos().z > E.floodZ - 110 and p:GetPos().z < bp.z + 40 then
                        p:SetPos(bp + Vector(0, 0, 24))
                        p.lcEndUnder = nil
                        inBoat[p] = b
                    end
                end
            end
        end
    end
    E.inBoat = inBoat
    -- lightning on the big beats
    if (kind == "heavy" or kind == "climax") then
        local beat = math.floor(t * cvFloodBPM:GetFloat() / 60)
        if beat ~= E.lastBeat then
            E.lastBeat = beat
            if beat % (kind == "climax" and 4 or 8) == 0 and math.random() < 0.8 then SetGlobal2Float("lc_flood_flash", now) end
        end
    end
    -- the ichthyosaurs, once there's water enough for them
    local alive = {}
    for _, m in ipairs(E.icthys) do if IsValid(m) then alive[#alive + 1] = m end end
    E.icthys = alive
    local want = math.max(2, math.floor(cvIcthys:GetInt() * I))
    if kind == "last" then want = 0 end
    if E.floodZ - E.floodBase > 60 and #E.icthys < want and now >= (E.nextIcthy or 0) then
        E.nextIcthy = now + 1.5
        SpawnIcthy()
    end
    local swimmers, edge = {}, {}
    for _, p in ipairs(Living()) do
        if p ~= g then
            if not OnStage(p) and p:GetPos().z < E.floodZ - 10 then swimmers[#swimmers + 1] = p
            elseif OnStage(p) and (p:GetPos() - st:GetPos()):Length2D() > STAGE_R * 0.5 then edge[#edge + 1] = p end
        end
    end
    for _, c in ipairs(E.crowd or {}) do
        if IsValid(c) and c.lcSwept then swimmers[#swimmers + 1] = c
        elseif IsValid(c) and (c:GetPos() - st:GetPos()):Length2D() > STAGE_R * 0.5 then edge[#edge + 1] = c end
    end
    for _, m in ipairs(E.icthys) do
        local s = m.lcIcthy
        if not s.leap then
            local best, bd
            for _, p in ipairs(swimmers) do
                local d = p:GetPos():DistToSqr(m:GetPos())
                if d < 1500 * 1500 and (not bd or d < bd) then best, bd = p, d end
            end
            local hunting = t >= cvFloodAttack:GetFloat()
            if best and hunting then
                s.goal, s.speed, s.target = best:GetPos(), 260 + 200 * I, best
                if bd < 100 * 100 then Bite(best) end
            elseif best and bd < 500 * 500 then
                -- (not yet: close enough to scare you, circling, no bite)
                s.a = s.a + s.dir * 0.05
                s.goal = best:GetPos() + Vector(math.cos(s.a), math.sin(s.a), 0) * 260
                s.goal.z = E.floodZ - 70
                s.speed = 200
            else
                -- circling the stage
                s.a = s.a + s.dir * 0.03 * (0.5 + I)
                s.goal = st:GetPos() + Vector(math.cos(s.a), math.sin(s.a), 0) * (STAGE_R + 220)
                s.goal.z = E.floodZ - 70
                s.speed = 160 + 160 * I
                -- and in the worst of it, a leap at whoever's near the edge
                if #edge > 0 and t >= cvFloodAttack:GetFloat() and (kind == "heavy" or kind == "climax") and math.random() < 0.012 * I * 10 and now >= (s.nextLeap or 0) then
                    local v = edge[math.random(#edge)]
                    s.target = v
                    s.nextLeap = now + 6
                    s.leap = { from = m:GetPos(), to = v:GetPos(), t0 = now, dur = 0.9, h = 120 }
                    m:EmitSound("npc/ichthyosaur/attack_growl" .. math.random(1, 3) .. ".wav", 90)
                end
            end
        end
        if not m.lcThinks then LC.IcthyStep(m, 0.1) end
    end
    -- the last note: whoever's still here goes, and Father Grigori last of all
    if kind == "last" and not E.lastDone then
        E.lastDone = true
        for _, c in ipairs(E.crowd or {}) do if IsValid(c) and not c.lcSwept then c.lcSwept = now c:SetNW2Bool("lc_rocking", false) end end
        for _, p in ipairs(Living()) do
            if p ~= g then Spectator(p, "The tide takes you, gently, at the very end.", Color(20, 40, 90, 230)) end
        end
        if IsValid(g) and g:IsPlayer() then Spectator(g, "Father Grigori holds the last note, bows, and the flood takes its encore.", Color(255, 255, 255, 200))
        elseif IsValid(g) then
            g.lcEndTaken = true
            for _, p in ipairs(LC.EndingPlayers()) do p:ChatPrint("Father Grigori holds the last note, bows, and the flood takes its encore.") end
        end
    end
end

------------------------------------------------------------------------
-- The phases
------------------------------------------------------------------------

local function Clear()
    for _, e in ipairs(E and E.ents or {}) do if IsValid(e) then e:Remove() end end
    -- (the city's own people who were in it: back to themselves)
    for _, c in ipairs(E and E.crowd or {}) do if IsValid(c) then c:SetNW2Bool("lc_rocking", false) c:SetNW2Bool("lc_crowd", false) end end
    if E and IsValid(E.grigori) then E.grigori:SetNW2Bool("lc_rocking", false) end
    for _, p in ipairs(LC.EndingPlayers()) do
        if p.lcEndTaken or p.lcEndRide or p.lcEndHang then
            p:Freeze(false)
            p:SetMoveType(MOVETYPE_WALK)
            if p.SetNoDraw then p:SetNoDraw(false) end
            if p.SetNotSolid then p:SetNotSolid(false) end
        end
        if p.lcEndSpectating and not (E and E.reloading) then -- (the map's about to reload: the dead stay down till it does)
            if p.UnSpectate then p:UnSpectate() end
            if p.Spawn then p:Spawn() end
        end
        if p.lcHang then
            p:Freeze(false)
            p:SetMoveType(MOVETYPE_WALK)
            if p.SetMaterial then p:SetMaterial("") end
            if p.SetColor then p:SetColor(Color(255, 255, 255, 255)) end
        end
        p.lcHang, p.lcHangHP = nil, nil
        p:SetNW2Float("lc_hanged", 0)
        p:SetNW2Bool("lc_limp", false)
        p.lcEndTaken, p.lcEndRide, p.lcEndHang, p.lcEndUnder = nil, nil, nil, nil
        p.lcEndSpectating, p.lcEndWatching, p.lcEndRoam = nil, nil, nil
        if p.lcEndModel then p:SetModel(p.lcEndModel) p.lcEndModel = nil end
        p:SetNW2Bool("lc_end_taken", false)
        p:SetNW2Bool("lc_end_spectating", false)
        p:SetNW2Bool("lc_dancing", false)
        p:SetNW2Bool("lc_seated", false)
        p:SetNW2Entity("lc_riding", NULL)
        p.lcBloomUp = nil
        p:SetNW2Bool("lc_rocking", false)
        p:SetNW2Bool("lc_chair", false)
        p:SetNW2Float("lc_fire", 0)
        p:SetNW2Bool("lc_flying", false)
        if p.lcShalom then p:SetMoveType(MOVETYPE_WALK) p.lcShalom = nil end
        if p.lcFire then p:SetMoveType(MOVETYPE_WALK) p.lcFire = nil end
        p.lcHora = nil
    end
    SetGlobal2Float("lc_flood_z", 0)
    SetGlobal2Float("lc_flood_slosh", 0)
    SetGlobal2Bool("lc_storm_max", false)
    SetGlobal2Bool("lc_flood_real", false)
    for _, p in ipairs(LC.EndingPlayers()) do if p.SetGravity then p:SetGravity(1) end p.lcEndUnder = nil end
    for npc in pairs(LC.EndingNPCs()) do
        if IsValid(npc) then
            npc:SetNW2Bool("lc_dancing", false) npc:SetNW2Bool("lc_seated", false) npc.lcBloomUp = nil npc.lcEndRide = nil
            npc:SetNW2Bool("lc_chair", false) npc.lcHora = nil
            npc:SetNW2Float("lc_fire", 0) npc:SetNW2Bool("lc_flying", false)
            if npc.lcHang then npc.lcHang = nil npc:SetNW2Float("lc_hanged", 0) npc:SetNW2Bool("lc_limp", false) end
        end
    end
    if E and E.doorsOpen and LC.ReleaseEveryDoor then LC.ReleaseEveryDoor() end
    -- (the Combine's guns, put down for the hora: back in their hands)
    for _, w in ipairs(E and E.hidWeps or {}) do if IsValid(w) and w.SetNoDraw then w:SetNoDraw(false) end end
    if E and E.dark then
        LC.EndingDark = nil
        if LC.ForceBlackout then LC.ForceBlackout("auto") end
        if LC.ApplyLightStyle then LC.ApplyLightStyle() end
    end
end

-- The map reloads, with the city's layout (characters, standing and credits are kept).
function LC.EndingReload()
    if LC.TestMode then return end
    if RunConsoleCommand then RunConsoleCommand("changelevel", game.GetMap()) end
end

local function GoTo(phase)
    local now = CurTime()
    E.phase = phase
    E.phaseT = now
    if phase == "gman" then
        Freeze(true) -- (the G-Man himself is on each screen, in front of each person: cl_livingcity_endings.lua)
        E.voteEnds = now + math.max(5, cvVote:GetFloat())
        E.votes = {}
        E.lines = {}
        for p in string.gmatch(cvGman:GetString() or "", "[^,]+") do E.lines[#E.lines + 1] = string.Trim(p) end
        All("[???] Time stops. A man in a blue suit is standing in front of you. He'd like a word, and your vote: 1 to let it happen, 2 to skip it.")
        MarkEnding()
    elseif phase == "apocalypse" then
        Freeze(false)
        local songs = LC.EndingSongs(E.id)
        E.song = #songs > 0 and songs[math.random(#songs)] or nil
        if not E.song and LC.Notice then
            for _, p in ipairs(LC.EndingPlayers()) do
                if p:IsSuperAdmin() then
                    LC.Notice(p, "warn", "No song", "No song found for " .. E.id .. ": put " .. E.id .. ".mp3 in garrysmod/sound/livingcity/endings/ on the server " ..
                        "(and sync FastDL). lc_endings shows what it finds.", 12)
                end
            end
        end
        All("[???] So be it. " .. LC.Endings[E.id].say)
        if E.dream and LC.DreamCast then LC.DreamCast(E) end -- (a dream brings its own Combine units: never the city's)
        local ok, err = pcall(SETUP[E.id])
        if not ok then LC.Error("ending setup " .. E.id, err) end
        hook.Run("LivingCityEndingStarted", E.id)
    elseif phase == "reset" then
        for _, p in ipairs(LC.EndingPlayers()) do
            if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.OUT or 2, Color(255, 255, 255, 255), 4, 60) end
        end
        All("[???] The city resets. Everyone you were is still you.")
        hook.Run("LivingCityEndingReset", E.id)
    end
    Send()
end

function LC.TriggerEnding(id, by, now)
    if not LC.Endings[id] then return false, "No such ending." end
    if E then return false, "One's already under way." end
    if not cvOn:GetBool() then return false, "Secret endings are off." end
    if LC.EndingCooldownLeft() > 0 then return false, "Not yet (" .. math.ceil(LC.EndingCooldownLeft() / 60) .. " minutes)." end
    -- (with a dream point placed, the ending waits for tonight's dream: sv_livingcity_dreams.lua)
    if not LC.DreamPending and not LC.EndingClassic and LC.DreamDivert then
        local took, okd, why = LC.DreamDivert(id, by, now)
        if took then return okd, why end
    end
    E = { id = id, by = by, phase = "pending", phaseT = CurTime(), ents = {}, votes = {}, dream = LC.DreamPending }
    LC.DreamPending = nil
    if LC.Event and LC.EndEvent and not E.dream then LC.EndEvent(true) end
    LC.Log("info", "Secret ending triggered: " .. id .. (IsValid(by) and (" by " .. by:Nick()) or ""))
    hook.Run("LivingCityEndingTriggered", id, by)
    if now then
        MarkEnding()
        GoTo("apocalypse")
    end
    return true
end

-- Ends it where it stands (admin, or the reset), without a reload.
function LC.CancelEnding()
    if not E then return false end
    local dream = E.dream
    Freeze(false)
    Clear()
    E = nil
    Send()
    if dream and LC.DreamWake then LC.DreamWake(dream) end -- (a dream: everyone wakes in their bed, with everything they had)
    return true
end

local function Tally()
    local yes, skip = 0, 0
    for p, v in pairs(E.votes) do
        if IsValid(p) then if v then yes = yes + 1 else skip = skip + 1 end end
    end
    hook.Run("LivingCityEndingVote", E.id, yes, skip)
    return yes, skip
end

net.Receive("lc_ending_vote", function(_, ply)
    if not E or E.phase ~= "gman" or not IsValid(ply) then return end
    local yes = net.ReadBool()
    if E.votes[ply] == yes then return end -- (the same vote again changes nothing: nothing to send everyone)
    E.votes[ply] = yes
    Send()
end)
function LC.EndingVote(ply, yes)
    if not E or E.phase ~= "gman" then return false end
    E.votes[ply] = yes and true or false
    Send()
    return true
end

timer.Create("LivingCityEndings", 0.1, 0, function()
    if not E then return end
    local ok, err = pcall(function()
        local now = CurTime()
        if E.phase == "pending" then
            if now - E.phaseT >= cvPause:GetFloat() then GoTo("gman") end
        elseif E.phase == "gman" then
            for _, p in ipairs(LC.EndingPlayers()) do if not p.lcEndFrozen then p.lcEndFrozen = true p:Freeze(true) end end -- (someone just joining)
            if now >= E.voteEnds then
                local yes, skip = Tally()
                if skip > yes then
                    All(string.format("[???] %d to %d. Very well. He straightens his tie, and time starts again.", skip, yes))
                    -- "Not this time." (the owner, 2 November; Episode One's G-Man, where the game has it)
                    if LC.Vision and LC.GmanLine then LC.Vision(E.dream and LC.EndingPlayers() or nil, "voice", LC.GmanLine("notthistime"), "Not this time.") end
                    LC.CancelEnding()
                else
                    All(yes + skip == 0 and "[???] Silence. He takes that as a yes." or string.format("[???] %d to %d.", yes, skip))
                    GoTo("apocalypse")
                end
            end
        elseif E.phase == "apocalypse" then
            if TICK[E.id] then TICK[E.id](now) end
            LC.EndingPollKeys()
            -- (an ending can run to the end of its song even after the last one goes: the dead
            -- watch; and one that lasts its song, with people still in it, ends with the song)
            local songOver = E.holdUntil and now >= E.holdUntil
            if (songOver and (#Living() == 0 or E.songEnds)) or (not E.holdUntil and #Living() == 0)
                or now - E.phaseT > math.max(cvMax:GetFloat(), (E.holdUntil or 0) - E.phaseT + 1) then GoTo("reset") end
        elseif E.phase == "reset" then
            if now - E.phaseT >= 5 then
                local id, dream = E.id, E.dream
                E.reloading = not LC.TestMode and not dream
                LC.CancelEnding()
                if dream then
                    LC.Log("info", "Secret ending " .. id .. " (a dream): the dreamers wake, no reload")
                else
                    LC.Log("info", "Secret ending " .. id .. ": the map reloads")
                    LC.EndingReload()
                end
            end
        end
    end)
    if not ok then LC.Error("endings", err) end
end)

-- Nobody gets hurt while time's stopped or the world ends.
hook.Add("EntityTakeDamage", "LivingCityEndings", function(ent, dmg)
    if E and E.phase ~= "pending" and IsValid(ent) and ent:IsPlayer() and (not E.dream or ent.lcDreaming) then return true end
    -- (the Combine's stray rounds don't hurt anyone in the ring with them)
    if E and IsValid(ent) and ent.lcRing and dmg and dmg.GetAttacker and IsValid(dmg:GetAttacker()) and dmg:GetAttacker().lcRing then return true end
end)
hook.Add("PlayerInitialSpawn", "LivingCityEndings", function(ply)
    timer.Simple(3, function() if IsValid(ply) and E and not E.dream then Send(ply) end end) -- (a dream: someone joining isn't in it)
end)
hook.Add("PlayerDisconnected", "LivingCityEndings", function(ply) if E then E.votes[ply] = nil end end)

------------------------------------------------------------------------
-- Triggers
------------------------------------------------------------------------

-- Father Grigori eats the motherlode.
function LC.EatChip(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_special", "") ~= "chaplain" then return false, "You'd break your teeth." end
    if not (LC.HasItem and LC.HasItem(ply, "master_chip")) then return false, "You've nothing like that to eat." end
    if E then return false, "Not now." end
    if LC.EndingCooldownLeft() > 0 or not cvOn:GetBool() then return false, "It doesn't go down. Not yet." end
    if LC.DreamQueued and LC.DreamQueued() then return false, "It doesn't go down. Something else is coming tonight." end -- (one dream a night: sv_livingcity_dreams.lua)
    LC.TakeItem(ply, "master_chip", 1)
    ply:EmitSound("physics/metal/metal_box_break1.wav", 70)
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():DistToSqr(ply:GetPos()) < 600 * 600 then p:ChatPrint("** Father Grigori swallows a Combine data core whole. His eyes light up.") end
    end
    return LC.TriggerEnding("water", ply)
end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.eatchip = function(ply)
    local ok, why = LC.EatChip(ply)
    if not ok and why then ply:ChatPrint(why) end
end

------------------------------------------------------------------------
-- For the admin
------------------------------------------------------------------------

local function Reply(ply, m) if IsValid(ply) then ply:ChatPrint("[Living City] " .. m) else print("[Living City] " .. m) end end

concommand.Add("lc_endings", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, id in ipairs(LC.EndingOrder) do
        local n = #LC.EndingSongs(id)
        for _, song in ipairs(LC.EndingSongs(id)) do
            local fr = LC.Mp3Frame and string.match(string.lower(song), "%.mp3$") and LC.Mp3Frame(file.Read("sound/" .. song, "GAME"))
            if fr and fr.hz < 32000 then Reply(ply, "  " .. song .. " is a low-quality copy (" .. fr.hz .. " Hz: it plays, but sounds muffled); a better copy would sound much better") end
        end
        Reply(ply, string.format("%s (%s): %s", id, LC.Endings[id].name, n > 0 and (n .. " song(s)") or ("NO SONG FOUND (looking for " .. id .. ".mp3 in garrysmod/sound/" .. ROOT .. ")")))
    end
    -- everything that's actually there, so a file in the wrong place shows
    local files, dirs = file.Find("sound/" .. ROOT .. "*", "GAME")
    files, dirs = files or {}, dirs or {}
    Reply(ply, "In sound/" .. ROOT .. ": " .. (#files + #dirs > 0 and (table.concat(files, ", ") ..
        (#dirs > 0 and ((#files > 0 and "; " or "") .. "folders: " .. table.concat(dirs, ", ")) or "")) or "nothing at all (the server can't see that folder)"))
    for _, d in ipairs(dirs) do
        if not LC.Endings[string.lower(d)] then
            local inside = file.Find("sound/" .. ROOT .. d .. "/*", "GAME") or {}
            if #inside > 0 then Reply(ply, "The folder " .. d .. "/ holds " .. #inside .. " file(s) that never play: move them up one level, straight into sound/" .. ROOT) end
        end
    end
    for _, n in ipairs(files) do
        local ext = string.match(n, "%.([%w]+)$")
        if ext and EXT[string.lower(ext)] and not LC.EndingOfSong(n) then
            Reply(ply, n .. " never plays: name it for its ending (harpies.mp3, bus.mp3 ...)")
        elseif not ext or not EXT[string.lower(ext)] then
            if not string.match(string.lower(n), "%.txt$") then Reply(ply, n .. " isn't a sound the game plays (.mp3, .ogg or .wav)") end
        end
    end
    local left = LC.EndingCooldownLeft()
    Reply(ply, left > 0 and ("Next one possible in " .. math.ceil(left / 60) .. " minutes (lc_ending_reset_cooldown).") or "One can happen now.")
end)

concommand.Add("lc_ending", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local id = string.lower(tostring(args[1] or ""))
    if not LC.Endings[id] then Reply(ply, "lc_ending <" .. table.concat(LC.EndingOrder, "|") .. "> [now]") return end
    LC.EndingClassic = true -- (an admin's: the whole city, as it always was, dream point or not)
    local ok, why = LC.TriggerEnding(id, IsValid(ply) and ply or nil, string.lower(tostring(args[2] or "")) == "now")
    LC.EndingClassic = nil
    Reply(ply, ok and ("Ending triggered: " .. id) or tostring(why))
end)

concommand.Add("lc_ending_cancel", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    Reply(ply, LC.CancelEnding() and "Ending cancelled. Time runs again." or "No ending on.")
end)

concommand.Add("lc_ending_reset_cooldown", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(COOL_FILE, util.TableToJSON({ last = 0 }))
    Reply(ply, "Secret ending cooldown cleared.")
end)

concommand.Add("lc_ending_vote", function(ply, _, args)
    if not IsValid(ply) then return end
    local a = string.lower(tostring(args[1] or ""))
    LC.EndingVote(ply, a == "yes" or a == "1")
end)

-- Settings are saved, so a default changed since would never reach a server that ran
-- the old one: anything still exactly at an old default moves to the new one (once;
-- a value someone chose themselves is left alone).
local RETUNED = {
    { "lc_ending_cooldown", { "60", "45" }, "180" }, -- (1 November: three hours between endings, the owner asked)
    { "lc_afk_minutes", { "5" }, "20" }, -- (2 November: away at 20 minutes, the owner asked; sv_livingcity_cityadmin.lua)
    { "lc_ending_gman_lines", { "vo/citadel/gman_exit01.wav,vo/citadel/gman_exit02.wav" }, "vo/citadel/gman_exit02.wav" }, -- (2 November: exit01 calls everyone "Doctor Freeman")
    { "lc_afk_kick_minutes", { "15" }, "20" },
    { "lc_job_cooldown", { "120" }, "900" }, -- (7 November: one Union job change every 15 minutes, the owner asked; sv_livingcity_work.lua)
    { "lc_ending_marrow_max", { "40", "60" }, "80" },
    { "lc_ending_base_bombs", { "30" }, "60" },
    { "lc_ending_hard_moment_beats", { "16" }, "5" },
    { "lc_ending_flood_drown", { "10" }, "15" },
    { "lc_ending_song_volume", { "harpies=2", "harpies=2,shalom=2" }, "harpies=4,shalom=2" }, -- (20 October: Shalom and the Harpies twice as loud)
    { "lc_ending_base_sections", { "3.5:bomb,14.7:screen,34:zig,126:move,174:justice,212:boom,224:end" }, "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end" },
    { "lc_ending_base_lines", { "2.2=CAPTAIN: What happen ?|3.5=MECHANIC: Somebody set up us the bomb.|6.5=OPERATOR: We get signal.|9.5=CAPTAIN: What !|12.5=OPERATOR: Main screen turn on.|14.7=CAPTAIN: It's you !!|16.4=CATS: How are you gentlemen !!|18.4=CATS: All your base are belong to us.|20.4=CATS: You are on the way to destruction.|21.6=CAPTAIN: What you say !!|23.0=CATS: You have no chance to survive make your time.|26.0=CATS: Ha ha ha ha ....|34=CAPTAIN: Take off every 'ZIG' !!|126=CAPTAIN: Move 'ZIG'.|174=CAPTAIN: For great justice." }, "2.15=CAPTAIN: What happen ?|3.55=MECHANIC: Somebody set up us the bomb.|4.65=OPERATOR: We get signal.|6.5=CAPTAIN: What !|9.5=OPERATOR: Main screen turn on.|11.7=CAPTAIN: It's you !!|12.55=CATS: How are you gentlemen !!|14.7=CATS: All your base are belong to us.|18.45=CATS: You are on the way to destruction.|20.6=CAPTAIN: What you say !!|21.65=CATS: You have no chance to survive make your time.|26.0=CATS: Ha ha ha ha ....|34=CAPTAIN: Take off every 'ZIG' !!|126=CAPTAIN: Move 'ZIG'.|174=CAPTAIN: For great justice." },
}
function LC.EndingRetune()
    local n = 0
    for _, r in ipairs(RETUNED) do
        local cv = GetConVar(r[1])
        if cv then
            for _, old in ipairs(r[2]) do
                if cv:GetString() == old then
                    if cv.SetString then cv:SetString(r[3]) elseif RunConsoleCommand then RunConsoleCommand(r[1], r[3]) end
                    n = n + 1
                    break
                end
            end
        end
    end
    return n
end
LC.EndingRetune()

hook.Add("InitPostEntity", "LivingCityEndings", function()
    for _, id in ipairs(LC.EndingOrder) do LC.EndingSongs(id) end -- (so the songs are sent to joining players)
end)
