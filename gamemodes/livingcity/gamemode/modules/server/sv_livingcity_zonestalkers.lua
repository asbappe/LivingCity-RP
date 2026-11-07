--[[
    Living City: the stalkers of the Combine zones

    Citizens stay out of the Combine-only zones (sv_livingcity_combineground.lua),
    so the Combine keep their own help in there (the owner, 7 November: "the
    stalker is just the worker/laborer/janitor/maintenance/technician for the
    combine only zones"). Every Combine-only zone has lc_zone_stalkers of them
    (1; 0: none, and the work in there is left undone). They appear out of
    sight, and one killed is replaced, out of sight, a couple of minutes later.

    With nothing to do, a stalker stands at a Combine terminal working it, with
    the stalker's own console animation from Episode One:
      - a "Point: stalker terminal" placed with the editor in front of one of
        the map's terminals (stand where the stalker should stand, facing the
        terminal, and aim at the floor at your feet), or else
      - one of the map's own Combine consoles in the zone, read from the map file
        like the sinks and stoves (sv_livingcity_staticprops.lua), or a console prop (combine_interface,
        combine_intmonitor, combine_smallmonitor and the like), or else
      - wherever it stands.
    Which animation that is depends on the stalker model installed: a few
    likely names are tried, then the model's own list is searched for one that
    sounds like console work. The one used is logged and shown in the debug
    report (People section), so it can be checked.

    When there's work in its zone it goes and does it, then back to its
    terminal:
      litter, a dead headcrab   picked up, carried off out of sight, gone
      a body                    dragged off out of sight, gone
      a mess, graffiti          scrubbed off
      a broken streetlight or loudspeaker   repaired, the same as the city's
                                repairmen do it outside (after the same wait
                                for a player, lc_npc_work_grace)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCount = CreateConVar("lc_zone_stalkers", "1", FLAGS, "Stalkers kept in each Combine-only zone: they work its terminals and do its cleaning and repairs (0: none)")
local RESPAWN = 120
local STALKER_MODEL = "models/stalker.mdl"
local UP = Vector(0, 0, 40)

LC.ZoneStalkers = LC.ZoneStalkers or {} -- [npc] = { npc, zone, phase, term, chore, ... }
local residents = LC.ZoneStalkers
local nextSpawn = {} -- [zone] = time

local function Zones() return LC.ZonesOfKindShared and LC.ZonesOfKindShared("combine") or {} end
local function InCombine(pos) return LC.InCombineZone and LC.InCombineZone(pos) end
local function Call(e, m, ...) if IsValid(e) and e[m] then return e[m](e, ...) end end
local function Taken(e) return LC.StalkerTakenItem and LC.StalkerTakenItem(e) end

------------------------------------------------------------------------
-- The terminal animation
------------------------------------------------------------------------

-- Names Episode One's stalker might use for working a console (tried first, in order).
LC.STALKER_CONSOLE_CANDIDATES = { "console_work", "work_console", "consolework", "typing", "type", "console", "buttons", "panel" }
-- Otherwise, the model's own sequences, scored by what's in the name.
local WORDS = { { "console", 4 }, { "type", 3 }, { "typing", 1 }, { "button", 3 }, { "panel", 3 }, { "keyboard", 3 }, { "terminal", 3 }, { "work", 2 } }
local BAD = { "death", "die", "pain", "flinch", "walk", "run", "attack", "beam" }

local seqCache = {} -- [model] = { name, id } or false
LC.StalkerSequenceUsed = LC.StalkerSequenceUsed or nil

local function Score(name)
    local n = string.lower(name)
    for _, b in ipairs(BAD) do if string.find(n, b, 1, true) then return 0 end end
    local s = 0
    for _, w in ipairs(WORDS) do if string.find(n, w[1], 1, true) then s = s + w[2] end end
    return s
end

-- The sequence a stalker works a terminal with: name and index (nil if the model has nothing like it).
function LC.StalkerConsoleSequence(npc, fresh)
    if not IsValid(npc) then return nil end
    local mdl = npc:GetModel() or ""
    if not fresh and seqCache[mdl] ~= nil then
        local c = seqCache[mdl]
        if c then return c.name, c.id end
        return nil
    end
    local name, id
    for _, cand in ipairs(LC.STALKER_CONSOLE_CANDIDATES) do
        local i = npc.LookupSequence and npc:LookupSequence(cand)
        if i and i >= 0 then name, id = cand, i break end
    end
    if not name and npc.GetSequenceList then
        local best, bs = nil, 0
        for i, seq in pairs(npc:GetSequenceList() or {}) do
            local sc = Score(tostring(seq))
            if sc > bs then best, bs = { name = tostring(seq), id = i }, sc end
        end
        if best then
            name = best.name
            local i = npc.LookupSequence and npc:LookupSequence(name)
            id = (i and i >= 0) and i or best.id
        end
    end
    seqCache[mdl] = name and { name = name, id = id } or false
    LC.StalkerSequenceUsed = name or "none found"
    if LC.Log then
        LC.Log("info", name and string.format("stalker terminal animation: '%s' (sequence %s) on %s", name, tostring(id), mdl)
            or ("stalker terminal animation: none found on " .. mdl .. " (they stand at the terminal)"))
    end
    return name, id
end

local function StopLoop(r)
    if IsValid(r.ss) then
        r.ss:Fire("CancelSequence")
        if SafeRemoveEntityDelayed then SafeRemoveEntityDelayed(r.ss, 0.5) else r.ss:Remove() end
    end
    r.ss = nil
end

local function StartLoop(r, pos, yaw)
    StopLoop(r)
    local name = LC.StalkerConsoleSequence(r.npc)
    if not name or not LC.MakeSequence then return false end
    local flags = (SF_SCRIPT_LOOP_IN_POST_IDLE or 16) + (SF_SCRIPT_NO_COMPLAINTS or 128) + (SF_SCRIPT_ALLOW_DEATH or 64)
    local ok, ss = pcall(LC.MakeSequence, r.npc, pos, yaw, name, name, flags, 0, 0)
    if ok and IsValid(ss) then r.ss = ss return true end
    return false
end

------------------------------------------------------------------------
-- Terminals
------------------------------------------------------------------------

-- The map's Combine consoles: the ones built into the map (prop_static, read from the map file like the
-- sinks and stoves: LC.StaticTerminals, sv_livingcity_staticprops.lua), and any that are props.
local PROP_CLASSES = { "prop_physics", "prop_physics_multiplayer", "prop_dynamic", "prop_dynamic_override" }

local function ConsoleModel(m) return LC.IsTerminalModel and LC.IsTerminalModel(m) or false end

local propCache, propAt = {}, -1000
local function ConsoleProps(now)
    if now - propAt > 30 then
        propCache, propAt = {}, now
        for _, cls in ipairs(PROP_CLASSES) do
            for _, e in ipairs(ents.FindByClass(cls)) do
                if IsValid(e) and ConsoleModel(e:GetModel()) then propCache[#propCache + 1] = e end
            end
        end
    end
    return propCache
end
LC.StalkerConsolePropsReset = function() propAt = -1000 end

-- Where a zone's stalkers stand to work: { pos, yaw, key }.
function LC.StalkerTerminals(z, now)
    local out = {}
    for i, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("sterm") or {}) do
        if LCZ.Contains(z, p.pos, 0) then out[#out + 1] = { pos = p.pos, yaw = p.yaw or 0, key = "p" .. i } end
    end
    if #out > 0 then return out end
    local function Front(pos, ang, key)
        local fwd = ang:Forward()
        fwd.z = 0
        if fwd:LengthSqr() < 0.01 then fwd = Vector(1, 0, 0) end
        fwd:Normalize()
        local stand = (LC.GroundAt and LC.GroundAt(pos + fwd * 40)) or (pos + fwd * 40)
        out[#out + 1] = { pos = stand, yaw = (-fwd):Angle().y, key = key }
    end
    for i, t in ipairs(LC.StaticTerminals or {}) do
        if LCZ.Contains(z, t.pos, 0) then Front(t.pos, t.ang or Angle(0, 0, 0), "s" .. i) end
    end
    for _, e in ipairs(ConsoleProps(now or CurTime())) do
        if IsValid(e) and LCZ.Contains(z, e:GetPos(), 0) then Front(e:GetPos(), e:GetAngles(), "e" .. e:EntIndex()) end
    end
    return out
end

local function PickTerminal(r, now)
    local list = LC.StalkerTerminals(r.zone, now)
    if #list == 0 then return nil end
    local used = {}
    for _, o in pairs(residents) do if o ~= r and o.term then used[o.term.key] = true end end
    local best, bd
    for _, t in ipairs(list) do
        local d = t.pos:DistToSqr(r.npc:GetPos()) + (used[t.key] and 1e12 or 0)
        if not bd or d < bd then best, bd = t, d end
    end
    return best
end

------------------------------------------------------------------------
-- The work in a Combine zone
------------------------------------------------------------------------

local function Age(e, now)
    local born = e.lcDroppedAt or e.lcBorn or (e.GetCreationTime and e:GetCreationTime()) or now
    return now - born
end

-- What's in the Combine zones that the city's workers would see to elsewhere.
function LC.CombineChores(now)
    local out = {}
    if #Zones() == 0 then return out end
    local junk = LC.NPCJunkItems or {}
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_item") or {}) do
        if IsValid(e) and not Taken(e) then
            local crab = LC.CrabCarcass and LC.CrabCarcass(e)
            local age = Age(e, now)
            if ((crab and age > 90) or (junk[e:GetNW2String("lc_item", "")] and age > 300)) and InCombine(e:GetPos()) then
                out[#out + 1] = { kind = "item", ent = e, pos = e:GetPos() }
            end
        end
    end
    local grace = LC.NPCWorkGrace and LC.NPCWorkGrace("sanitation") or 60
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_stain") or {}) do
        if IsValid(e) and not e.lcStalkerTaken and now - (e.lcBorn or 0) >= grace and InCombine(e:GetPos()) then
            out[#out + 1] = { kind = "stain", ent = e, pos = e:GetPos() }
        end
    end
    local bodyGrace = math.min(LC.NPCWorkGrace and LC.NPCWorkGrace("mortuary") or 60, 200)
    for _, b in ipairs(LC.Bodies or {}) do
        local e = b.ent
        if IsValid(e) and e.lcBody and not e.lcBody.claimed and not e.lcStalkerTaken and not (LC.HauledBy and LC.HauledBy(e))
            and now - (b.born or now) >= bodyGrace and InCombine(e:GetPos()) then
            out[#out + 1] = { kind = "body", ent = e, pos = e:GetPos() }
        end
    end
    for _, t in ipairs(LC.Tags or {}) do
        if not t.lcStalkerTaken and now - (t.at or 0) >= grace and InCombine(t.pos) then
            out[#out + 1] = { kind = "tag", tag = t, pos = t.pos }
        end
    end
    -- broken streetlights and loudspeakers: after the same wait for a player as outside
    for cls, job in pairs({ lc_streetlight = "maintenance", lc_loudspeaker = "radio" }) do
        local wait = LC.NPCWorkGrace and LC.NPCWorkGrace(job) or 60
        for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or {}) do
            if IsValid(e) and e:GetNW2Bool("lc_broken", false) and not e.lcStalkerTaken and now - (e.lcBrokenAt or 0) >= wait
                and InCombine(e:GetPos()) then
                out[#out + 1] = { kind = "fix", ent = e, pos = e:GetPos(), what = cls == "lc_streetlight" and "streetlight" or "loudspeaker" }
            end
        end
    end
    return out
end

local DOING = { item = "clearing up", stain = "scrubbing up a mess", body = "taking a body away", tag = "scrubbing off graffiti" }
local SECS = { item = 2.5, body = 3, stain = 6, tag = 6, fix = 10 }

local function Free(c)
    if not c then return end
    if c.kind == "body" and IsValid(c.ent) and c.ent.lcBody then c.ent.lcBody.claimed = nil end
    if IsValid(c.ent) then
        c.ent.lcStalkerTaken = nil
        if c.ent.GetParent and IsValid(c.ent:GetParent()) then Call(c.ent, "SetParent", NULL) end
    end
    if c.tag then c.tag.lcStalkerTaken = nil end
end

-- The thing itself, gone (an item, a mess, a body; graffiti off the wall).
local function Dispose(c)
    if IsValid(c.ent) then c.ent:Remove() end
    if c.tag and LC.Tags then
        for k, t in ipairs(LC.Tags) do
            if t == c.tag then table.remove(LC.Tags, k) if LC.SendTags then LC.SendTags() end break end
        end
    end
end

------------------------------------------------------------------------
-- The stalkers themselves
------------------------------------------------------------------------

local function Walk(npc, pos)
    npc:SetLastPosition(pos)
    npc:SetSchedule(SCHED_FORCED_GO)
end

local function SetDoing(r, text) if IsValid(r.npc) then r.npc:SetNW2String("lc_doing", text or "") end end

-- Somewhere in the zone nobody can see.
local function HiddenSpot(z, near)
    for _ = 1, 10 do
        local p = LC.SpotInZone and LC.SpotInZone(z)
        if p and not LC.IsSeen(p + UP) and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 300))
            and (not near or p:DistToSqr(near) > 150 * 150) then return p end
    end
    return nil
end

local function SpawnStalker(pos)
    local npc = ents.Create("npc_stalker")
    if not IsValid(npc) then return nil end
    npc:SetPos(pos + Vector(0, 0, 4))
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    if not util.IsValidModel or util.IsValidModel(STALKER_MODEL) then npc:SetModel(STALKER_MODEL) end
    npc:Spawn()
    npc:Activate()
    -- harmless: no beam, no fights; it's here to work
    for _, rel in ipairs({ "player D_NU 99", "npc_citizen D_NU 99", "npc_metropolice D_NU 99", "npc_combine_s D_NU 99", "npc_vortigaunt D_NU 99" }) do
        Call(npc, "AddRelationship", rel)
    end
    Call(npc, "SetKeyValue", "BeamPower", "0")
    npc:SetName("lc_zonestalker_" .. npc:EntIndex()) -- (a scripted_sequence finds it by name)
    npc.lcStalkerCleaner = true
    npc:SetNW2String("lc_pname", "Stalker")
    return npc
end

local function Count(z)
    local n = 0
    for npc, r in pairs(residents) do if r.zone == z and IsValid(npc) then n = n + 1 end end
    return n
end

local function Retire(r)
    StopLoop(r)
    Free(r.chore)
    residents[r.npc] = nil
    if IsValid(r.npc) then r.npc:Remove() end
end

-- Keep every zone staffed: out of sight, one at a time, a while after one is lost.
function LC.ZoneStalkersStaff(now)
    local want = math.max(0, cvCount:GetInt())
    local live = {}
    for _, z in ipairs(Zones()) do live[z] = true end
    for npc, r in pairs(residents) do
        if not live[r.zone] or want == 0 then Retire(r) end
    end
    if want == 0 then return end
    for _, z in ipairs(Zones()) do
        local n = Count(z)
        if n < want and now >= (nextSpawn[z] or 0) then
            local p = HiddenSpot(z)
            local npc = p and SpawnStalker(p)
            if npc then
                residents[npc] = { npc = npc, zone = z, phase = "idle", born = now, lastPos = npc:GetPos(), lastMoved = now }
                nextSpawn[z] = now + 5
            end
        elseif n > want then
            for npc, r in pairs(residents) do
                if r.zone == z and not r.chore and not LC.IsSeen(npc:GetPos() + UP) then Retire(r) break end
            end
        end
    end
end

-- Give the zone's work to its stalkers: the nearest free one to each job.
function LC.ZoneStalkersAssign(now)
    local jobs = LC.CombineChores(now)
    for _, job in ipairs(jobs) do
        local z = InCombine(job.pos)
        local best, bd
        for npc, r in pairs(residents) do
            if IsValid(npc) and not r.chore and (r.zone == z or LCZ.Contains(r.zone, job.pos, 0)) then
                local d = npc:GetPos():DistToSqr(job.pos)
                if not bd or d < bd then best, bd = r, d end
            end
        end
        if best then
            StopLoop(best)
            best.chore = job
            if IsValid(job.ent) then job.ent.lcStalkerTaken = true end
            if job.tag then job.tag.lcStalkerTaken = true end
            if job.kind == "body" and job.ent.lcBody then job.ent.lcBody.claimed = true end
            best.phase, best.nextLook, best.lastMoved = "to", now, now
            SetDoing(best, job.kind == "fix" and ("repairing a " .. job.what) or DOING[job.kind])
            Walk(best.npc, job.pos)
        end
    end
end

local function TargetPos(c)
    if c.tag then return c.tag.pos end
    return IsValid(c.ent) and c.ent:GetPos() or nil
end

-- Done with the job's hands-on part.
local function DoIt(r, now)
    local c = r.chore
    local e = c.ent
    if c.kind == "fix" then
        if IsValid(e) and LC.RepairStreetFixture and LC.RepairStreetFixture(e) then hook.Run("LivingCityStalkerFixed", r.npc, e, c.what) end
        Free(c)
        r.chore = nil
        return
    elseif c.kind == "stain" or c.kind == "tag" then
        Dispose(c)
        r.chore = nil
        return
    elseif c.kind == "item" and IsValid(e) then
        local phys = e.GetPhysicsObject and e:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        Call(e, "SetMoveType", MOVETYPE_NONE)
        Call(e, "SetNotSolid", true)
        Call(e, "SetParent", r.npc)
        Call(e, "SetLocalPos", Vector(20, 0, 40))
    end
    -- carried (or dragged) off out of sight
    r.away = HiddenSpot(r.zone, r.npc:GetPos())
    r.phase, r.startAway = "away", now
    if r.away then Walk(r.npc, r.away) end
end

-- A body comes along behind, by the shoulders, the way a mortician drags one.
local function Drag(r)
    local c = r.chore
    if not c or c.kind ~= "body" or r.phase ~= "away" or not IsValid(c.ent) or not IsValid(r.npc) then return end
    local phys = c.ent.GetPhysicsObjectNum and c.ent:GetPhysicsObjectNum(0)
    if not IsValid(phys) then return end
    local target = r.npc:GetPos() - Angle(0, r.npc:GetAngles().y, 0):Forward() * 46 + Vector(0, 0, 14)
    local v = (target - phys:GetPos()) * 7
    if v:Length() > 300 then v = v:GetNormalized() * 300 end
    phys:Wake()
    phys:SetVelocity(v)
end

-- Back to the terminal (or wherever it stands, with none).
local function Idle(r, now)
    local npc = r.npc
    r.term = r.term or PickTerminal(r, now)
    if not r.term then
        if r.phase ~= "idle" then npc:SetSchedule(SCHED_IDLE_STAND) end
        r.phase = "idle"
        SetDoing(r, "")
        return
    end
    if npc:GetPos():DistToSqr(r.term.pos) > 40 * 40 then
        if r.phase ~= "toterm" or now - (r.nextLook or 0) > 4 then
            r.phase, r.nextLook = "toterm", now
            Walk(npc, r.term.pos)
        end
        SetDoing(r, "")
        if now - r.lastMoved > 25 then r.term = nil r.phase = "idle" r.lastMoved = now end -- (can't get there: another, or stand)
        return
    end
    if r.phase ~= "working" then
        r.phase = "working"
        npc:SetSchedule(SCHED_IDLE_STAND)
        if LC.FaceYaw then LC.FaceYaw(npc, r.term.yaw) else npc:SetAngles(Angle(0, r.term.yaw, 0)) end
        StartLoop(r, r.term.pos, r.term.yaw)
        SetDoing(r, "working a terminal")
    elseif r.ss == nil or not IsValid(r.ss) then
        StartLoop(r, r.term.pos, r.term.yaw) -- (the loop broke off: again)
    end
end

function LC.ZoneStalkersThink(now)
    for npc, r in pairs(residents) do
        if not IsValid(npc) or npc:Health() <= 0 then
            StopLoop(r)
            Free(r.chore)
            residents[npc] = nil
            nextSpawn[r.zone] = now + RESPAWN -- (another, a while later)
        else
            local pos = npc:GetPos()
            if pos:DistToSqr(r.lastPos) > 16 * 16 then r.lastPos, r.lastMoved = pos, now end
            local stuck = now - r.lastMoved > 25
            local c = r.chore
            if r.phase == "to" then
                local tp = TargetPos(c)
                if not tp or (c.kind == "body" and LC.HauledBy and LC.HauledBy(c.ent))
                    or (c.kind == "fix" and not c.ent:GetNW2Bool("lc_broken", false)) then
                    Free(c) r.chore = nil r.phase = "back" -- (someone else saw to it)
                elseif pos:DistToSqr(tp) < (c.kind == "fix" and 90 or 70) ^ 2 then
                    r.phase, r.untilT = "take", now + (SECS[c.kind] or 3)
                    npc:SetSchedule(SCHED_IDLE_STAND)
                    if LC.Face then LC.Face(npc, tp) end
                elseif stuck then
                    Free(c) r.chore = nil r.phase = "back"
                elseif now - (r.nextLook or 0) > 3 then
                    r.nextLook = now
                    Walk(npc, tp)
                end
            elseif r.phase == "take" then
                if c.kind == "fix" and math.random() < 0.3 and IsValid(c.ent) and util.Effect and EffectData then
                    local fx = EffectData() fx:SetOrigin(c.ent:WorldSpaceCenter()) util.Effect("cball_bounce", fx)
                end
                if now >= r.untilT then
                    DoIt(r, now)
                    if not r.chore then r.phase = "back" end
                end
            elseif r.phase == "away" then
                local there = not r.away or pos:DistToSqr(r.away) < 60 * 60
                local hidden = not LC.IsSeen(pos + UP) and not (IsValid(c.ent) and LC.IsSeen(c.ent:GetPos() + Vector(0, 0, 10)))
                if (there or stuck or now - r.startAway > 120) and hidden then
                    Dispose(c)
                    r.chore = nil
                    r.phase = "back"
                elseif there and now - (r.nextLook or 0) > 4 then
                    -- someone can see it here: somewhere else out of sight
                    r.nextLook = now
                    r.away = HiddenSpot(r.zone, pos)
                    if r.away then Walk(npc, r.away) end
                end
            end
            if r.phase == "back" or r.phase == "idle" or r.phase == "toterm" or r.phase == "working" then
                if r.phase == "back" then r.phase, r.lastMoved = "idle", now end
                Idle(r, now)
            end
        end
    end
end

-- One step of it all (the timer below; the tests call it directly).
function LC.ZoneStalkersTick(now)
    LC.ZoneStalkersStaff(now)
    LC.ZoneStalkersThink(now)
    LC.ZoneStalkersAssign(now)
end

hook.Add("Think", "LivingCityZoneStalkerDrag", function()
    if next(residents) == nil then return end
    for _, r in pairs(residents) do if r.chore then Drag(r) end end
end)

timer.Create("LivingCityZoneStalkers", 1, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.ZoneStalkersTick, CurTime())
    if not ok and LC.Error then LC.Error("zone stalkers", err) end
end)

hook.Add("LivingCityStopped", "LivingCityZoneStalkers", function()
    for _, r in pairs(residents) do Retire(r) end
    nextSpawn = {}
end)

-- In the debug report (People).
function LC.StalkerSummary()
    local n, busy, at = 0, 0, 0
    for npc, r in pairs(residents) do
        if IsValid(npc) then
            n = n + 1
            if r.chore then busy = busy + 1 end
            if r.phase == "working" then at = at + 1 end
        end
    end
    return string.format("Combine zone stalkers: %d (want %d per zone, %d zones), %d on a job, %d at a terminal; terminal animation: %s",
        n, math.max(0, cvCount:GetInt()), #Zones(), busy, at, tostring(LC.StalkerSequenceUsed or "not chosen yet"))
end
