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
           his voice plays for everyone (lc_ending_gman_lines) and the vote
           comes up on every screen. 1: let it happen. 2: skip it.
        3. lc_ending_vote_secs (30) later: more skips than yeses and he
           straightens his tie, time starts again, and life goes on. Anything
           else (a tie, or nobody voting at all): the apocalypse.
        4. The ending plays out with its song, until everyone's been taken
           (or lc_ending_max seconds), then the world goes white and the map
           reloads.

      The endings (their songs: sound/livingcity/endings/<id>/, any file
      there, .wav, .mp3 or .ogg; they live in the separate sound addon,
      garrysmod/addons/livingcity_sound/sound/livingcity/endings/<id>/,
      so updating the gamemode never touches them)
        harpies    Kleiners, in step, closing in on everyone from all sides
        crazybus   everyone in a bus or van, flying round the city
        nuanua     everyone on an airplane, high over the city
        topsecret  everyone hung by barnacles, one a second
        grigori    a rising flood; Father Grigori rocks out above it, mouthing
                   every word. Triggered by Father Grigori himself eating the
                   motherlode: /eatchip, with a master data core in his pockets.

      Nobody can be hurt during the vote or an ending (and "taken" isn't dead:
      no new character). The city's events wait. One ending (or a skipped one)
      every lc_ending_cooldown minutes (60), remembered across the reload.

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
local cvCool    = CreateConVar("lc_ending_cooldown", "60", FLAGS, "Minutes between secret endings (triggered, voted on or skipped)")
local cvGman    = CreateConVar("lc_ending_gman_lines", "vo/citadel/gman_exit01.wav,vo/citadel/gman_exit02.wav", FLAGS,
    "The G-Man's lines when he stops time, in order (comma-separated sound paths)")
local cvRadius  = CreateConVar("lc_ending_flight_radius", "2200", FLAGS, "How wide the flying endings circle the city")

local ROOT = "livingcity/endings/"
local EXT = { wav = true, mp3 = true, ogg = true }

LC.Endings = {
    harpies   = { name = "The Harpies", say = "Kleiners. Everywhere. In step." },
    crazybus  = { name = "The Crazy Bus", say = "All aboard." },
    nuanua    = { name = "Nua Nua", say = "Please fasten your seatbelts." },
    topsecret = { name = "Top Secret", say = "Look up." },
    grigori   = { name = "The Flood", say = "Father Grigori has eaten the motherlode. The waters rise." },
}
LC.EndingOrder = { "harpies", "crazybus", "nuanua", "topsecret", "grigori" }

local E -- the ending in progress: { id, phase, by, ... }
function LC.EndingSession() return E end
function LC.EndingBusy() return E ~= nil end

local function All(msg) for _, p in ipairs(player.GetAll()) do p:ChatPrint(msg) end end

------------------------------------------------------------------------
-- Songs, and the cooldown (kept in a file: it outlasts the reload)
------------------------------------------------------------------------

function LC.EndingSongs(id)
    local out = {}
    local dir = "sound/" .. ROOT .. id
    local names = file.Find(dir .. "/*", "GAME") or {}
    table.sort(names)
    for _, n in ipairs(names) do
        local ext = string.match(n, "%.([%w]+)$")
        if ext and EXT[string.lower(ext)] then
            out[#out + 1] = ROOT .. id .. "/" .. n
            if resource and resource.AddFile then resource.AddFile("sound/" .. ROOT .. id .. "/" .. n) end
        end
    end
    return out
end

local COOL_FILE = "livingcity/endings.json"
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

local function Send(to)
    net.Start("lc_ending")
    if not E then
        net.WriteTable({})
    else
        local yes, skip = 0, 0
        for _, v in pairs(E.votes or {}) do if v then yes = yes + 1 else skip = skip + 1 end end
        net.WriteTable({ id = E.id, phase = E.phase, name = LC.Endings[E.id].name, say = LC.Endings[E.id].say,
            voteEnds = E.voteEnds, yes = yes, skip = skip, song = E.song, lines = E.lines, grigori = E.grigori,
            floodZ = E.floodZ })
    end
    if to then net.Send(to) else net.Broadcast() end
end

------------------------------------------------------------------------
-- Stopping time
------------------------------------------------------------------------

local function Freeze(on)
    LC.TimeStopped = on or nil
    SetGlobal2Bool("lc_timestop", on and true or false)
    if RunConsoleCommand then RunConsoleCommand("ai_disabled", on and "1" or "0") end
    for _, p in ipairs(player.GetAll()) do
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

local function SpawnGman(near)
    local by = IsValid(near) and near or player.GetAll()[1]
    if not IsValid(by) then return nil end
    local fwd = by.GetForward and by:GetForward() or Vector(1, 0, 0)
    fwd.z = 0
    fwd = fwd:GetNormalized()
    local pos = by:GetPos() + fwd * 90
    local g = ents.Create("npc_gman")
    if not IsValid(g) then return nil end
    g:SetPos(pos)
    g:SetAngles(Angle(0, (by:GetPos() - pos):Angle().y, 0))
    g:Spawn()
    g:Activate()
    return g
end

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
    for _, p in ipairs(player.GetAll()) do if p:Alive() and not p.lcEndTaken then out[#out + 1] = p end end
    return out
end

local function Centre()
    local sum, n = Vector(0, 0, 0), 0
    for _, p in ipairs(player.GetAll()) do sum = sum + p:GetPos() n = n + 1 end
    return n > 0 and sum * (1 / n) or Vector(0, 0, 0)
end

local function FirstModel(list)
    for _, m in ipairs(list) do if not util.IsValidModel or util.IsValidModel(m) then return m end end
    return list[#list]
end

local function Prop(model, pos, scale)
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
local function Board(vehicle, riders, offsets)
    for i, p in ipairs(riders) do
        p:Freeze(true)
        p:SetMoveType(MOVETYPE_NONE)
        p.lcEndRide = { v = vehicle, off = offsets[i] or Vector(0, 0, 40) }
    end
end

local function Ride(now)
    for _, p in ipairs(player.GetAll()) do
        local r = p.lcEndRide
        if r and IsValid(r.v) then p:SetPos(r.v:GetPos() + r.off) end
    end
end

local SETUP, TICK = {}, {}

-- the Harpies: Kleiners close in from all sides, in step
SETUP.harpies = function()
    E.kleiners = {}
    E.nextWave = 0
end
TICK.harpies = function(now)
    local living = Living()
    if now >= E.nextWave and #E.kleiners < 60 then
        E.nextWave = now + 10
        for _, p in ipairs(living) do
            for i = 1, 3 do
                local a = (i / 3 + math.random() * 0.2) * math.pi * 2
                local pos = p:GetPos() + Vector(math.cos(a) * 900, math.sin(a) * 900, 8)
                local k = ents.Create("npc_kleiner")
                if not IsValid(k) then
                    k = ents.Create("npc_citizen")
                    if IsValid(k) then k:SetModel("models/kleiner.mdl") end
                end
                if IsValid(k) then
                    k:SetPos(pos)
                    k:Spawn()
                    k:Activate()
                    k.lcEndTarget = p
                    E.ents[#E.ents + 1] = k
                    E.kleiners[#E.kleiners + 1] = k
                end
            end
        end
    end
    -- in step: every one of them re-aims on the same beat
    if now >= (E.step or 0) then
        E.step = now + 0.5
        for _, k in ipairs(E.kleiners) do
            if IsValid(k) then
                local t = k.lcEndTarget
                if not IsValid(t) or t.lcEndTaken then t = living[math.random(math.max(1, #living))] k.lcEndTarget = t end
                if IsValid(t) then
                    k:SetLastPosition(t:GetPos())
                    k:SetSchedule(SCHED_FORCED_GO)
                    if k:GetPos():DistToSqr(t:GetPos()) < 70 * 70 then Take(t, "A Kleiner reaches you. Then another. Then all of them.") end
                end
            end
        end
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
    local r = cvRadius:GetFloat()
    for i, f in ipairs(E.flights or {}) do
        if IsValid(f.v) then
            local a = f.phase + (now - E.started) * f.speed
            local pos = E.centre + Vector(math.cos(a) * r, math.sin(a) * r, f.height + math.sin(a * 3 + i) * 120)
            f.v:SetPos(pos)
            f.v:SetAngles(Angle(math.sin(a * 2) * 12, math.deg(a) + 90, math.cos(a * 3) * 18))
        end
    end
    Ride(now)
    -- the ride lasts the song, more or less, and then nobody ever gets off
    if now - E.started > (E.flightSecs or 80) then
        for _, p in ipairs(Living()) do Take(p, E.id == "nuanua" and "The plane climbs into the clouds and keeps climbing." or "The bus doesn't stop. It never stops.") end
    end
end

SETUP.crazybus = function()
    Fly({ "models/props_vehicles/bus01_2.mdl", "models/props_vehicles/van001a_physics.mdl", "models/props_vehicles/car002a_physics.mdl" }, 6, 700, 0.35, nil, 75)
end
TICK.crazybus = FlyTick

SETUP.nuanua = function()
    Fly({ "models/xqm/jetbody3.mdl", "models/xqm/airplanewing1.mdl", "models/props_vehicles/van001a_physics.mdl" }, 64, 1600, 0.2, 3, 90)
end
TICK.nuanua = FlyTick

-- Top Secret: barnacles, one victim a second
SETUP.topsecret = function()
    E.nextHang = CurTime() + 1
    E.hanging = {}
end
TICK.topsecret = function(now)
    if now >= E.nextHang then
        E.nextHang = now + 1
        for _, p in ipairs(Living()) do
            if not p.lcEndHang then
                p.lcEndHang = { t = now, from = p:GetPos() }
                p:Freeze(true)
                p:SetMoveType(MOVETYPE_NONE)
                Prop("models/barnacle.mdl", p:GetPos() + Vector(0, 0, 260))
                p:EmitSound("npc/barnacle/barnacle_tongue_pull1.wav", 80)
                E.hanging[#E.hanging + 1] = p
                break
            end
        end
    end
    for _, p in ipairs(E.hanging) do
        local h = IsValid(p) and p.lcEndHang
        if h and not p.lcEndTaken then
            local t = now - h.t
            p:SetPos(h.from + Vector(0, 0, math.min(1, t / 2.5) * 180))
            if t > 3.5 then
                p:EmitSound("npc/barnacle/barnacle_crunch2.wav", 80)
                Take(p, "Up you go.")
            end
        end
    end
end

-- the Flood: the water rises; Grigori rocks out above it
SETUP.grigori = function()
    local low
    for _, p in ipairs(player.GetAll()) do low = math.min(low or p:GetPos().z, p:GetPos().z) end
    E.floodZ = (low or 0) - 40
    E.floodStart = CurTime()
    if IsValid(E.by) then
        E.grigori = E.by
        E.by:SetNW2Bool("lc_rocking", true)
    end
end
TICK.grigori = function(now)
    E.floodZ = E.floodZ + 22 * 0.1
    SetGlobal2Float("lc_flood_z", E.floodZ)
    local g = E.grigori
    if IsValid(g) and now >= (E.nextDance or 0) then
        E.nextDance = now + 5
        g:ConCommand("act " .. (math.random() < 0.5 and "dance" or "muscle"))
    end
    for _, p in ipairs(Living()) do
        if p ~= g then
            local under = p:EyePos().z < E.floodZ
            if under then
                p.lcEndUnder = p.lcEndUnder or now
                if now - p.lcEndUnder > 6 then Take(p, "The water closes over your head. Somewhere above, Father Grigori hits the high note.") end
            else
                p.lcEndUnder = nil
            end
        end
    end
    -- Grigori is the last to go, once he's alone
    if IsValid(g) and not g.lcEndTaken and #Living() <= 1 and now - E.floodStart > 20 then
        Take(g, "Father Grigori bows. The flood takes its encore.")
    end
end

------------------------------------------------------------------------
-- The phases
------------------------------------------------------------------------

local function Clear()
    for _, e in ipairs(E and E.ents or {}) do if IsValid(e) then e:Remove() end end
    for _, p in ipairs(player.GetAll()) do
        if p.lcEndTaken or p.lcEndRide or p.lcEndHang then
            p:Freeze(false)
            p:SetMoveType(MOVETYPE_WALK)
            if p.SetNoDraw then p:SetNoDraw(false) end
            if p.SetNotSolid then p:SetNotSolid(false) end
        end
        p.lcEndTaken, p.lcEndRide, p.lcEndHang, p.lcEndUnder = nil, nil, nil, nil
        p:SetNW2Bool("lc_end_taken", false)
        p:SetNW2Bool("lc_rocking", false)
    end
    SetGlobal2Float("lc_flood_z", 0)
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
        Freeze(true)
        E.gman = SpawnGman(E.by)
        if IsValid(E.gman) then E.ents[#E.ents + 1] = E.gman end
        E.voteEnds = now + math.max(5, cvVote:GetFloat())
        E.votes = {}
        E.lines = {}
        for p in string.gmatch(cvGman:GetString() or "", "[^,]+") do E.lines[#E.lines + 1] = string.Trim(p) end
        All("[???] Time stops. A man in a blue suit is standing in front of you. He'd like a word, and your vote: 1 to let it happen, 2 to skip it.")
        MarkEnding()
    elseif phase == "apocalypse" then
        Freeze(false)
        if IsValid(E.gman) then E.gman:Remove() end
        local songs = LC.EndingSongs(E.id)
        E.song = #songs > 0 and songs[math.random(#songs)] or nil
        All("[???] So be it. " .. LC.Endings[E.id].say)
        local ok, err = pcall(SETUP[E.id])
        if not ok then LC.Error("ending setup " .. E.id, err) end
        hook.Run("LivingCityEndingStarted", E.id)
    elseif phase == "reset" then
        for _, p in ipairs(player.GetAll()) do
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
    E = { id = id, by = by, phase = "pending", phaseT = CurTime(), ents = {}, votes = {} }
    if LC.Event and LC.EndEvent then LC.EndEvent(true) end
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
    Freeze(false)
    Clear()
    E = nil
    Send()
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
    E.votes[ply] = net.ReadBool()
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
            for _, p in ipairs(player.GetAll()) do if not p.lcEndFrozen then p.lcEndFrozen = true p:Freeze(true) end end -- (someone just joining)
            if now >= E.voteEnds then
                local yes, skip = Tally()
                if skip > yes then
                    All(string.format("[???] %d to %d. Very well. He straightens his tie, and time starts again.", skip, yes))
                    LC.CancelEnding()
                else
                    All(yes + skip == 0 and "[???] Silence. He takes that as a yes." or string.format("[???] %d to %d.", yes, skip))
                    GoTo("apocalypse")
                end
            end
        elseif E.phase == "apocalypse" then
            if TICK[E.id] then TICK[E.id](now) end
            if #Living() == 0 or now - E.phaseT > cvMax:GetFloat() then GoTo("reset") end
        elseif E.phase == "reset" then
            if now - E.phaseT >= 5 then
                local id = E.id
                LC.CancelEnding()
                LC.Log("info", "Secret ending " .. id .. ": the map reloads")
                LC.EndingReload()
            end
        end
    end)
    if not ok then LC.Error("endings", err) end
end)

-- Nobody gets hurt while time's stopped or the world ends.
hook.Add("EntityTakeDamage", "LivingCityEndings", function(ent)
    if E and E.phase ~= "pending" and IsValid(ent) and ent:IsPlayer() then return true end
end)
hook.Add("PlayerInitialSpawn", "LivingCityEndings", function(ply)
    timer.Simple(3, function() if IsValid(ply) and E then Send(ply) end end)
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
    LC.TakeItem(ply, "master_chip", 1)
    ply:EmitSound("physics/metal/metal_box_break1.wav", 70)
    for _, p in ipairs(player.GetAll()) do
        if p:GetPos():DistToSqr(ply:GetPos()) < 600 * 600 then p:ChatPrint("** Father Grigori swallows a Combine data core whole. His eyes light up.") end
    end
    return LC.TriggerEnding("grigori", ply)
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
        Reply(ply, string.format("%s (%s): %s", id, LC.Endings[id].name, n > 0 and (n .. " song(s)") or "no song yet: sound/" .. ROOT .. id .. "/"))
    end
    local left = LC.EndingCooldownLeft()
    Reply(ply, left > 0 and ("Next one possible in " .. math.ceil(left / 60) .. " minutes (lc_ending_reset_cooldown).") or "One can happen now.")
end)

concommand.Add("lc_ending", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local id = string.lower(tostring(args[1] or ""))
    if not LC.Endings[id] then Reply(ply, "lc_ending <" .. table.concat(LC.EndingOrder, "|") .. "> [now]") return end
    local ok, why = LC.TriggerEnding(id, IsValid(ply) and ply or nil, string.lower(tostring(args[2] or "")) == "now")
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

hook.Add("InitPostEntity", "LivingCityEndings", function()
    for _, id in ipairs(LC.EndingOrder) do LC.EndingSongs(id) end -- (so the songs are sent to joining players)
end)
