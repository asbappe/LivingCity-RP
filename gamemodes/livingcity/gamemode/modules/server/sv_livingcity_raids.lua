--[[
    Living City: habitation block raids

    The "raid" event (lc_event raid, or one of the automatic events) sends a few
    Civil Protection units into a housing block. They walk it systematically, a
    string of stops spread over the block, and at each one they look around:

      * people in the block are frisked (stand still);
      * anything contraband lying about is confiscated: contraband items,
        loose weapons, and TVs and radios;
      * residents' hidden stashes may be found.

    They come in the way Valve's own raid does it (the owner, 21 November;
    d1_trainstation_03): the team moves up each man in his own lane, two of
    them take the block's nearest door, one knocks while the other kicks it in
    (it opens on the kick itself), the residents run with their arms over their
    heads to a corner and cower, and the beating inside is heard, not seen,
    while the furniture flies. Then the stops.

    Everything found is traced to whoever dropped or spawned it. Each owner
    becomes wanted for contraband, and the more of it was found under their
    name, the longer and the worse. Owners who are offline are wanted when
    they next join.

    Settings: lc_raid_units, lc_raid_stash_chance.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvUnits = CreateConVar("lc_raid_units", "3", FLAGS, "Civil Protection units sent into a block during a raid")
local cvStash = CreateConVar("lc_raid_stash_chance", "60", FLAGS, "Percent chance a raid finds a resident's contraband stash")

local SCAN_RADIUS = 300
local STOP_TIME = 5
local RAID_TIME = 240

------------------------------------------------------------------------
-- What counts as contraband lying around, and whose it is
------------------------------------------------------------------------

local CONTRABAND_MODELS = { "tv_monitor", "television", "radio", "reciever", "receiver" }
local LEGAL_WEAPONS = { weapon_fists = true, weapon_lc_hands = true, weapon_physgun = true, gmod_tool = true, weapon_medkit = true }

-- A short name if the thing is contraband, else nil.
function LC.ContrabandOf(ent)
    if not IsValid(ent) then return nil end
    if ent.lcEvidence then return nil end -- (the evidence pile, waiting for the fire: sv_livingcity_evidence.lua)
    local cls = ent:GetClass()
    if cls == "lc_item" then
        local it = LCS and LCS.Items[ent:GetNW2String("lc_item", "")]
        if it and it.contraband then return it.name, it end
        return nil
    end
    if string.StartWith(cls, "weapon_") or (string.StartWith(cls, "weapon") and cls ~= "weapon") then
        if string.StartWith(cls, "weapon_lc_") or LEGAL_WEAPONS[cls] then return nil end
        if IsValid(ent:GetOwner()) then return nil end -- somebody is holding it
        return (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " "))
    end
    if cls == "prop_physics" then
        local model = string.lower(ent:GetModel() or "")
        for _, pat in ipairs(CONTRABAND_MODELS) do
            if string.find(model, pat, 1, true) then return "a " .. pat:gsub("reciever", "radio"):gsub("receiver", "radio") end
        end
    end
    return nil
end

-- Remember who made a thing, so a raid can come for them.
local function Claim(ply, ent)
    if IsValid(ply) and IsValid(ent) and ply:IsPlayer() then ent.lcOwner = ply:SteamID64() end
end
hook.Add("PlayerSpawnedProp", "LivingCityOwners", function(ply, _, ent) Claim(ply, ent) end)
hook.Add("PlayerSpawnedSENT", "LivingCityOwners", function(ply, ent) Claim(ply, ent) end)
hook.Add("PlayerSpawnedSWEP", "LivingCityOwners", function(ply, ent) Claim(ply, ent) end)
hook.Add("PlayerSpawnedRagdoll", "LivingCityOwners", function(ply, _, ent) Claim(ply, ent) end)
LC.ClaimEntity = Claim

------------------------------------------------------------------------
-- Offenses that wait for someone to come online
------------------------------------------------------------------------

local PENDING_FILE = "livingcity/pending_raid.json"
local pending

local function LoadPending()
    if pending then return pending end
    pending = {}
    local t = LC.SafeReadJSON(PENDING_FILE)
    if istable(t) then pending = t end
    return pending
end

local function SavePending()
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    LC.SafeWrite(PENDING_FILE, util.TableToJSON(LoadPending()))
end

-- Charge someone with what was found under their name.
local function Charge(ply, count, block)
    local where = block and (" in " .. LC.BlockName(block)) or ""
    local reason = count >= 5 and "Weapons and contraband cache" or "Possession of contraband"
    ply:ChatPrint(string.format("[Civil Protection] %d contraband item%s found%s under your name. You are wanted.", count, count == 1 and "" or "s", where))
    if LC.AddStanding then LC.AddStanding(ply, -25 * count, "Contraband found in your block") end
    LC.ReportCrime(ply, reason, math.min(900, 120 + 60 * count))
    if count >= 5 and LC.MakeCopsHostile then LC.MakeCopsHostile(ply, ply:GetPos(), 1500) end
    hook.Run("LivingCityBlockRaidCharge", ply, count, block)
end
LC.RaidCharge = Charge

hook.Add("PlayerInitialSpawn", "LivingCityRaidPending", function(ply)
    timer.Simple(12, function()
        if not IsValid(ply) then return end
        local p = LoadPending()
        local rec = p[ply:SteamID64()]
        if rec then
            p[ply:SteamID64()] = nil
            SavePending()
            Charge(ply, rec.count or 1, rec.block)
        end
    end)
end)

------------------------------------------------------------------------
-- The raid
------------------------------------------------------------------------

LC.Raid = nil -- { block, zones, units, found = { [owner] = n }, seen, startT, ... }

local function BlockZones(n)
    local out = {}
    for _, z in ipairs(LC.ZonesOfKind("block")) do if (z.group or 0) == n then out[#out + 1] = z end end
    return out
end

-- Stops spread over the block, walked in a sensible order from where the unit starts.
local function Waypoints(zones, from)
    local pts = {}
    for _, z in ipairs(zones) do
        local want = math.Clamp(math.floor(z.r / 120), 3, 12)
        for _ = 1, want * 3 do
            if #pts >= want * #zones then break end
            local p = LC.SpotInZone(z)
            if p then
                local ok = true
                for _, q in ipairs(pts) do if q:DistToSqr(p) < 150 * 150 then ok = false break end end
                if ok then pts[#pts + 1] = p end
            end
        end
    end
    local ordered, cur = {}, from
    while #pts > 0 do
        local bi, bd
        for i, p in ipairs(pts) do
            local d = p:DistToSqr(cur)
            if not bd or d < bd then bi, bd = i, d end
        end
        cur = table.remove(pts, bi)
        ordered[#ordered + 1] = cur
    end
    return ordered
end

local function GiveStops(raid, npc, st, want)
    local pts = Waypoints(raid.zones, npc:GetPos())
    if #pts == 0 then return false end
    -- each unit takes its own share of the stops
    local share = {}
    for i = #raid.units % math.max(1, want) + 1, #pts, math.max(1, want) do share[#share + 1] = pts[i] end
    if #share == 0 then share = pts end
    st.raid = { owner = raid, pts = share, i = 0, phase = "start" }
    st.untilT = 0
    raid.units[#raid.units + 1] = npc
    if LC.Release then LC.Try(LC.Release, npc, st) end
    return true
end

-- The team comes from nearby, out of sight, so the raid really happens where
-- it was announced. (Not the city's own patrols: they were often too far away,
-- or had no way there, and the raid was over before anyone arrived.) They leave the same way when it's over.
LC.RaidLeaving = LC.RaidLeaving or {} -- [npc] = { spot, since }
local function SpawnTeam(raid, want)
    if not LC.SpawnCop or #raid.units >= want then return end
    local center = raid.zones[1].pos
    local spot = LC.AlarmSquadSpot and LC.AlarmSquadSpot(center)
    if not spot then
        -- nowhere a walk away: a corner of the block itself nobody's looking at (or, failing that, any)
        local any
        for _ = 1, 12 do
            local z = raid.zones[math.random(#raid.zones)]
            local p = LC.SpotInZone(z)
            if p then
                any = any or p
                if not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40))) then spot = p break end
            end
        end
        spot = spot or any
    end
    if not spot then return end
    local n = 0
    while #raid.units < want and n < want * 2 do
        n = n + 1
        local npc, st = LC.SpawnCop(spot + Vector(math.cos(n * 2) * 40, math.sin(n * 2) * 40, 4))
        if IsValid(npc) and st then
            st.unmanaged, st.leaveAt, st.routeGroup = true, nil, nil -- (on top of the city's own numbers)
            st.raidSpot = spot
            if not GiveStops(raid, npc, st, want) then npc:Remove() break end
        end
    end
end

local function Confiscate(ent)
    if not IsValid(ent) then return end
    if LC.EvidenceFromEntity then LC.EvidenceFromEntity(ent, "raid") end -- (into the evidence stock, to be burned: sv_livingcity_evidence.lua)
    if sound and sound.Play then sound.Play("physics/cardboard/cardboard_box_break1.wav", ent:GetPos(), 60) end
    ent:Remove()
end

-- A unit standing at a stop looks around.
local function Scan(npc, raid, pos)
    for _, ent in ipairs(ents.FindInSphere(pos, SCAN_RADIUS)) do
        if not raid.seen[ent] then
            local name = LC.ContrabandOf(ent)
            if name then
                raid.seen[ent] = true
                local owner = ent.lcOwner or "unknown"
                raid.found[owner] = (raid.found[owner] or 0) + 1
                raid.names[#raid.names + 1] = name
                Confiscate(ent)
            end
        end
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not raid.frisked[ply] and ply:GetPos():DistToSqr(pos) < (SCAN_RADIUS + 50) ^ 2
            and LC.InBlock(ply:GetPos(), raid.block) and not LC.PlayerIsCP(ply)
            and not (LC.InCustody and LC.InCustody(ply)) and not (LC.EditorHeld and LC.EditorHeld(ply)) then
            raid.frisked[ply] = true
            npc:EmitSound("npc/metropolice/vo/dontmove.wav", 75) -- (he says it: no line of text)
            ply:SetNW2Float("lcu_stop_until", CurTime() + 4)
            if LC.Search then LC.Search(npc, ply) end
        end
    end
end

local function Finish(raid)
    if LC.Raid ~= raid then return end
    LC.Raid = nil
    for _, npc in ipairs(raid.units) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st then
            st.raid = nil
            if st.raidSpot then -- the team that came for it walks back off
                LC.RaidLeaving[npc] = { spot = st.raidSpot, since = CurTime() }
                if LC.GoTo then LC.GoTo(npc, st, st.raidSpot, false) end
            end
        end
    end

    -- hidden stashes of the block's residents
    if LC.Stash and LCS then
        for _, ply in ipairs(player.GetAll()) do
            if LC.PlayerBlock(ply) == raid.block and math.random() * 100 < cvStash:GetFloat() then
                local st = LC.Stash(ply)
                for id, n in pairs(table.Copy(st)) do
                    if LCS.Items[id] and LCS.Items[id].contraband then
                        raid.found[ply:SteamID64()] = (raid.found[ply:SteamID64()] or 0) + n
                        raid.names[#raid.names + 1] = LCS.Items[id].name .. (n > 1 and (" x" .. n) or "") .. " (stash)"
                        if LC.EvidenceAdd then LC.EvidenceAdd(id, n, "raid") end
                        st[id] = nil
                    end
                end
                ply:SetPData("lci_stash_" .. game.GetMap(), util.TableToJSON(st))
            end
        end
    end

    local total = 0
    for owner, n in pairs(raid.found) do
        total = total + n
        if owner ~= "unknown" then
            local ply
            for _, p in ipairs(player.GetAll()) do if p:SteamID64() == owner then ply = p break end end
            if IsValid(ply) then
                Charge(ply, n, raid.block)
            else
                local p = LoadPending()
                local rec = p[owner] or { count = 0 }
                rec.count, rec.block = (rec.count or 0) + n, raid.block
                p[owner] = rec
                SavePending()
            end
        end
    end
    for _, ply in ipairs(player.GetAll()) do
        if LC.InBlock(ply:GetPos(), raid.block) or LC.PlayerBlock(ply) == raid.block then
            ply:ChatPrint(total > 0
                and string.format("[Civil Protection] Block inspection complete. %d item%s confiscated.", total, total == 1 and "" or "s")
                or "[Civil Protection] Block inspection complete. Carry on.")
        end
    end
    LC.Log("info", string.format("Raid on block %d finished: %d item(s) found", raid.block, total))
    hook.Run("LivingCityBlockRaided", raid.block, raid.found, raid.names)
end
LC.FinishRaid = Finish

------------------------------------------------------------------------
-- The breach (the owner, 21 November: Valve's apartment raid, d1_trainstation_03)
------------------------------------------------------------------------

local LOOP, NOCOMPLAIN, MAYDIE = 256, 2048, 4096
local KICK_AT, KICK_HIT = 1.6, 0.67 -- (adoorkick's foot lands at frame 20, at 30 a second)
local BEAT = { "weapons/stunstick/stunstick_fleshhit1.wav", "weapons/stunstick/stunstick_fleshhit2.wav",
    "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard3.wav",
    "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav" }
local PAIN = { "vo/npc/male01/pain07.wav", "vo/npc/male01/pain08.wav", "vo/npc/male01/pain09.wav" }
local THROW_AT = { 2.1, 3, 4.1, 5.6, 7.1 } -- (Valve's physics explosions in the flat)
local COWER = { "cower_Idle", "Fear_Reaction_Idle" }

local function Has(npc, name) local s = IsValid(npc) and npc.LookupSequence and npc:LookupSequence(name) return s ~= nil and s >= 0 end

-- The block's door nearest where the team comes from: a hinged door, not a cell's or one tagged shut.
function LC.RaidBreachDoor(raid, from)
    local best, bd
    for _, z in ipairs(raid.zones) do
        for _, door in ipairs(ents.FindInSphere(z.pos, (z.r or 300) + 150)) do
            if IsValid(door) and door:GetClass() == "prop_door_rotating" and not door.lcBlown then
                local tag = LC.GetDoorTag and LC.GetDoorTag(door)
                local auto = not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) or nil
                if tag ~= "prison" and tag ~= "locked" and tag ~= "open" and auto ~= "prison"
                    and LC.InBlock(door:WorldSpaceCenter(), raid.block) then
                    local d = door:WorldSpaceCenter():DistToSqr(from)
                    if not bd or d < bd then best, bd = door, d end
                end
            end
        end
    end
    return best
end

-- Two to the door (one to kick it, one to knock), the rest covering behind them, each in his lane.
function LC.RaidBreachPlan(raid)
    local team = {}
    for _, u in ipairs(raid.units) do if IsValid(u) and LC.NPCs[u] and LC.NPCs[u].raid then team[#team + 1] = u end end
    if #team == 0 then return end
    local from = team[1]:GetPos()
    local door = LC.DoorNormal and LC.RaidBreachDoor(raid, from)
    if not door then
        -- no door to take: each man still goes up in his own lane, to his own first stop
        for i, u in ipairs(team) do
            local st = LC.NPCs[u]
            if st.raid.pts[1] and LC.LaneOne then LC.LaneOne(u, st, st.raid.pts[1], from, i, #team, { spot = st.raid.pts[1], run = true }) end
        end
        return
    end
    local n = LC.DoorNormal(door)
    local side = ((from - door:WorldSpaceCenter()):Dot(n) >= 0) and 1 or -1
    local out = n * side
    local across = Vector(out.y, -out.x, 0)
    local yaw = (-out):Angle().y -- (facing the door)
    local kick = LC.DoorFloor(door, side, 40)
    local b = { door = door, out = out, yaw = yaw, t0 = CurTime(), phase = "coming",
        kick = kick, knock = kick + across * 44, inside = LC.DoorFloor(door, -side, 120),
        kicker = team[1], knocker = team[2] }
    raid.breach = b
    local spots = { b.kick, b.knock }
    if #team > 2 and LC.LaneSpots then
        for _, p in ipairs(LC.LaneSpots(kick + out * 110, from, #team - 2)) do spots[#spots + 1] = p end
    end
    if LC.LaneMove then
        LC.LaneMove(team, kick, { spots = spots, run = true, from = from, yaw = yaw,
            done = function(npc, st) if st.raid then st.raid.atDoor = true end end })
    end
end

local function Play(npc, pos, yaw, name, loop, moveTo)
    if not Has(npc, name) or not LC.MakeSequence then return nil end
    local ok, ss = LC.Try(LC.MakeSequence, npc, pos, yaw, name, loop and name or nil, (loop and LOOP or 0) + NOCOMPLAIN + MAYDIE, moveTo or 0, 0)
    if not ok or not IsValid(ss) then return nil end
    if IsValid(npc.lcGesture) then npc.lcGesture:Fire("CancelSequence") SafeRemoveEntityDelayed(npc.lcGesture, 0.2) end
    npc.lcGesture = ss
    SafeRemoveEntityDelayed(ss, 8)
    return ss
end

-- Kicked open: it bangs open, away from the boot, on the kick itself.
function LC.RaidKickOpen(door, kicker)
    if not IsValid(door) then return false end
    local locked = door:GetInternalVariable("m_bLocked") == true
    local rental = LC.RentalOf and LC.RentalOf(door)
    if rental and rental.locked then locked = true end
    door:Fire("Unlock")
    local kv = door.GetKeyValues and door:GetKeyValues() or {}
    local was = tonumber(kv.speed)
    door:SetKeyValue("speed", tostring(math.max(500, (was or 100) * 5)))
    timer.Simple(1.2, function() if IsValid(door) then door:SetKeyValue("speed", tostring(was or 100)) end end)
    if IsValid(kicker) then door:Fire("OpenAwayFrom", "!activator", 0, kicker, kicker) else door:Fire("Open") end
    door:EmitSound(locked and "physics/wood/wood_crate_break3.wav" or "physics/wood/wood_panel_impact_hard1.wav", 85)
    if LC.OpenedDoors then LC.OpenedDoors[door] = CurTime() + 8 end
    if locked and LC.Relock then LC.Relock[door] = true end
    return true
end

-- The residents run, arms over their heads, to the far side of the block, and cower there.
function LC.RaidScatter(raid, door)
    local dpos = door:WorldSpaceCenter()
    local now, ran = CurTime(), {}
    for cit, ist in pairs(LC.NPCs) do
        if IsValid(cit) and ist.role == "citizen" and not ist.test and cit:Health() > 0
            and (ist.state == "idle" or ist.state == "moving" or ist.state == "busy")
            and cit:GetPos():DistToSqr(dpos) < 900 * 900 and LC.InBlock(cit:GetPos(), raid.block) then
            local best, bd
            for _ = 1, 6 do
                local p = LC.SpotInZone(raid.zones[math.random(#raid.zones)])
                local d = p and p:DistToSqr(dpos)
                if d and d > 250 * 250 and (not bd or d > bd) then best, bd = p, d end
            end
            if best then
                if IsValid(ist.ss) then ist.ss:Fire("CancelSequence") SafeRemoveEntityDelayed(ist.ss, 0.2) ist.ss, ist.busyKind = nil, nil end
                LC.SetState(cit, ist, "event")
                ist.eventUntil = now + 18
                local name
                for _, c in ipairs(COWER) do if Has(cit, c) then name = c break end end
                name = name or (LC.BusySeqName and LC.BusySeqName(cit, "ACT_COWER"))
                local ss = name and Play(cit, best, (dpos - best):Angle().y, name, true, 2)
                if ss then SafeRemoveEntityDelayed(ss, 18) else cit:SetLastPosition(best) cit:SetSchedule(SCHED_FORCED_GO_RUN) end
                if cit.SetMovementActivity and ACT_RUN_PROTECTED then
                    timer.Simple(0.5, function() if IsValid(cit) then cit:SetMovementActivity(ACT_RUN_PROTECTED) end end)
                end
                ran[#ran + 1] = cit
            end
        end
    end
    return ran
end

local function Throw(at)
    local n = 0
    for _, e in ipairs(ents.FindInSphere(at, 260)) do
        if n >= 2 then break end
        if IsValid(e) and e:GetClass() == "prop_physics" and not e.lcCan and not e.lcEvidence then
            local phys = e:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() then
                phys:Wake()
                phys:ApplyForceCenter((VectorRand() * 0.6 + Vector(0, 0, 0.7)):GetNormalized() * phys:GetMass() * 260)
                n = n + 1
            end
        end
    end
end

-- Heard, not seen: blows on two random timers (0.4 to 1.5 s) for 6 and 8 seconds, and the furniture going over.
function LC.RaidBeating(raid, src, at)
    local b = raid.breach
    local fired = 0
    local function Chain(t, limit)
        local d = math.Rand(0.4, 1.5)
        if t + d > limit then return end
        timer.Simple(d, function()
            if LC.Raid ~= raid then return end
            local e = (IsValid(src) and src) or (b and IsValid(b.door) and b.door)
            if not e then return end
            e:EmitSound(math.random() < 0.25 and PAIN[math.random(#PAIN)] or BEAT[math.random(#BEAT)], 75)
            fired = fired + 1
            Chain(t + d, limit)
        end)
    end
    Chain(0, math.Rand(6, 7))
    Chain(0, math.Rand(7, 8))
    for _, t in ipairs(THROW_AT) do timer.Simple(t, function() if LC.Raid == raid then Throw(at) end end) end
    return function() return fired end
end

local function Breach(raid, b)
    b.phase = "breaching"
    local kicker = IsValid(b.kicker) and LC.NPCs[b.kicker] and b.kicker or nil
    local knocker = IsValid(b.knocker) and LC.NPCs[b.knocker] and b.knocker or nil
    if knocker then Play(knocker, b.knock, b.yaw, "adoorknock", false, 0) end
    if kicker then Play(kicker, b.kick, b.yaw, "adooridle", true, 0) end
    timer.Simple(KICK_AT, function() if IsValid(kicker) then Play(kicker, b.kick, b.yaw, "adoorkick", false, 0) end end)
    timer.Simple(KICK_AT + KICK_HIT, function()
        if LC.Raid ~= raid or not IsValid(b.door) then b.phase = "done" return end
        LC.RaidKickOpen(b.door, kicker)
        b.ran = LC.RaidScatter(raid, b.door)
        b.opened = CurTime()
    end)
    timer.Simple(KICK_AT + 1.2, function() if IsValid(knocker) then Play(knocker, b.knock, b.yaw, "adoorenter", false, 0) end end)
    timer.Simple(KICK_AT + 2.2, function()
        if LC.Raid ~= raid then return end
        local st = IsValid(knocker) and LC.NPCs[knocker]
        if st then
            if IsValid(knocker.lcGesture) then knocker.lcGesture:Fire("CancelSequence") end
            LC.GoTo(knocker, st, b.inside, false, { kind = "raidpoint", pos = b.inside, yaw = b.yaw })
        end
        b.heard = LC.RaidBeating(raid, knocker, b.inside)
    end)
    timer.Simple(KICK_AT + 3, function() b.phase = "done" end)
end

-- The team at the door waits for the two to be at their marks (at most 40 s), then the knock and the kick.
function LC.RaidBreachThink(raid, b, npc, st, now)
    if b.phase == "coming" then
        local ready = true
        for _, u in ipairs({ b.kicker, b.knocker }) do
            local ust = IsValid(u) and LC.NPCs[u]
            if ust and ust.raid and (ust.lane or not ust.raid.atDoor) then ready = false end
        end
        if ready or now - b.t0 > 40 then Breach(raid, b) end
    end
    st.untilT = now + 0.5
    return true
end

-- Pick the block: one with people in it first, else any.
function LC.StartRaid(block)
    if LC.Raid then return false, "A raid is already in progress." end
    local numbers = LC.BlockNumbers and LC.BlockNumbers() or {}
    if #numbers == 0 then return false, "This map has no housing blocks." end
    if not block then
        local weighted = {}
        for _, n in ipairs(numbers) do
            weighted[#weighted + 1] = n
            for _, ply in ipairs(player.GetAll()) do
                if LC.PlayerBlock(ply) == n or LC.InBlock(ply:GetPos(), n) then weighted[#weighted + 1] = n end
            end
        end
        block = weighted[math.random(#weighted)]
    end
    local zones = BlockZones(block)
    if #zones == 0 then return false, "No such block." end
    local raid = { block = block, zones = zones, units = {}, found = {}, names = {}, seen = {}, frisked = {}, startT = CurTime() }
    LC.Raid = raid
    LC.ExtraCops = math.max(LC.ExtraCops or 0, 2)
    SpawnTeam(raid, cvUnits:GetInt())
    if #raid.units == 0 then
        LC.Raid = nil
        return false, "No Civil Protection units could get to " .. LC.BlockName(block) .. "."
    end
    LC.Try(LC.RaidBreachPlan, raid)
    LC.Log("info", string.format("Raid on block %d: %d unit(s) sent", block, #raid.units))
    for _, ply in ipairs(player.GetAll()) do
        if LC.PlayerBlock(ply) == block then
            ply:ChatPrint("[Civil Protection] Inspection of " .. LC.BlockName(block) .. " is under way. Stay in your residence.")
        end
    end
    return true
end

function LC.EndRaid() if LC.Raid then Finish(LC.Raid) end end

-- Called from the security NPC think when this unit is idle. Returns true if it
-- took charge of the unit this tick.
function LC.RaidThink(npc, st, now)
    local r = st.raid
    if not r then return false end
    local raid = r.owner
    if LC.Raid ~= raid then st.raid = nil return false end
    if st.lane and LC.LaneStep and LC.LaneStep(npc, st, now) then return true end -- (moving up, in his lane)
    local b = raid.breach
    if b and b.phase ~= "done" then return LC.RaidBreachThink(raid, b, npc, st, now) end

    if r.phase == "scanning" then
        Scan(npc, raid, npc:GetPos())
        r.phase = "searched"
        st.untilT = now + STOP_TIME
        if LC.PlayGesture then LC.PlayGesture(npc, { "harassfront_idle", "plazathreat1", "plazathreat2" }, STOP_TIME) end
        return true
    end

    r.i = r.i + 1
    local pt = r.pts[r.i]
    if not pt then
        r.done = true
        st.raid = nil
        local active = false
        for _, u in ipairs(raid.units) do
            local ust = IsValid(u) and LC.NPCs[u]
            if ust and ust.raid and not ust.raid.done then active = true end
        end
        if not active then Finish(raid) end
        return false
    end
    r.phase = "scanning"
    if not LC.GoTo(npc, st, pt, r.i == 1, { kind = "raidpoint", pos = pt, yaw = npc:GetAngles().y }) then
        r.phase = "searched" -- can't reach this stop; try the next
        st.untilT = now + 0.5
    end
    return true
end

timer.Create("LivingCityRaids", 2, 0, function()
    local now = CurTime()
    -- the team that came for a raid is gone once it's out of sight
    for npc, l in pairs(LC.RaidLeaving) do
        if not IsValid(npc) then
            LC.RaidLeaving[npc] = nil
        elseif now - l.since > 4 and not (LC.Raid and LC.NPCs[npc] and LC.NPCs[npc].raid)
            and (not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) or now - l.since > 180) then
            LC.RaidLeaving[npc] = nil
            npc:Remove()
        end
    end
    local raid = LC.Raid
    if not raid then return end
    if raid.breach and raid.breach.phase ~= "done" and now - raid.breach.t0 > 60 then raid.breach.phase = "done" end -- (never held up by it)
    local alive = false
    for _, u in ipairs(raid.units) do
        if IsValid(u) and LC.NPCs[u] and LC.NPCs[u].raid then alive = true end
    end
    if (not alive and now - raid.startT > 30) or now - raid.startT > RAID_TIME then Finish(raid) end
end)

hook.Add("LivingCityEventEnded", "LivingCityRaids", function(name) if name == "raid" then LC.EndRaid() end end)
hook.Add("LivingCityEventStarted", "LivingCityRaids", function(name)
    if name == "raid" then
        local ok, why = LC.StartRaid()
        if not ok then
            -- nobody to send: no raid, and no announcement of one (sv_livingcity_events.lua checks)
            LC.Log("info", "Raid not started: " .. tostring(why))
            if LC.EndEvent then LC.EndEvent(true) end
        end
    end
end)
