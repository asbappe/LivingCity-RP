--[[
    Living City: habitation block raids

    The "raid" event (lc_event raid, or one of the automatic events) sends a few
    Civil Protection units into a housing block. They walk it systematically, a
    string of stops spread over the block, and at each one they look around:

      * people in the block are frisked (stand still);
      * anything contraband lying about is confiscated: contraband items,
        loose weapons, and TVs and radios;
      * residents' hidden stashes may be found.

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
    if file and file.Exists and file.Exists(PENDING_FILE, "DATA") then
        local t = util.JSONToTable(file.Read(PENDING_FILE, "DATA") or "")
        if istable(t) then pending = t end
    end
    return pending
end

local function SavePending()
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(PENDING_FILE, util.TableToJSON(LoadPending()))
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

-- Units already standing about near the block (not ones walking over from the far
-- side of the map: they'd turn up after it was over).
local NEAR_COPS = 1500
local function FreeCops(center)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and not st.test and not st.raid and not st.questLock
            and st.state == "idle" and npc:GetPos():DistToSqr(center) < NEAR_COPS * NEAR_COPS then
            out[#out + 1] = npc
        end
    end
    return out
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
    if LC.Release then pcall(LC.Release, npc, st) end
    return true
end

-- The rest of the team comes from nearby, out of sight, so the raid really
-- happens where it was announced. They leave the same way when it's over.
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

local function Recruit(raid)
    local want = cvUnits:GetInt()
    if #raid.units >= want then return end
    local center = raid.zones[1].pos
    local cops = FreeCops(center)
    table.sort(cops, function(a, b) return a:GetPos():DistToSqr(center) < b:GetPos():DistToSqr(center) end)
    for _, npc in ipairs(cops) do
        if #raid.units >= want then break end
        GiveStops(raid, npc, LC.NPCs[npc], want)
    end
end

local function Confiscate(ent)
    if not IsValid(ent) then return end
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
            ply:ChatPrint("[Civil Protection] Block inspection. Stand still and cooperate.")
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
    Recruit(raid)
    SpawnTeam(raid, cvUnits:GetInt())
    if #raid.units == 0 then
        LC.Raid = nil
        return false, "No Civil Protection units could get to " .. LC.BlockName(block) .. "."
    end
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
    if now - raid.startT < 30 then Recruit(raid) end
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
