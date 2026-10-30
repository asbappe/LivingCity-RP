--[[
    Living City: supply drops, radio jammers

      Supply drop   a city event ("supply", now and then by itself, or
                    lc_event supply): Union supplies come to a loading dock
                    (the editor's "Point: loading dock"; somewhere on the
                    street if there's none). With open sky over the dock a
                    dropship brings them in, sets a cargo container down and
                    climbs away (and comes back for the container when it's
                    over); under a roof an APC is parked there. Beside it, a
                    stack of crates and the one you can open, for
                    lc_supply_minutes (6). An Overwatch soldier stands guard
                    (lc_supply_guards, 1), turning to look about; he warns
                    anyone hanging about the crates (twice), then they're
                    wanted. Two metrocops (lc_supply_porters, 2) unload it:
                    each walks to the stack, picks up a box in both hands,
                    carries it off to a spot down the street and sets it
                    down, and back again, the whole time: they come and go,
                    and between them is when to sneak in. Units
                    get a directive to guard it; the Resistance get one to raid
                    it. Anyone who isn't a unit can press E on the crate and
                    take a load (eight seconds, keep still): gun parts,
                    ammunition, chemicals, rations, a medkit's worth of
                    bandages. Done quietly; but a unit who sees you at it, at
                    any moment of the eight seconds, stops you and makes you
                    wanted. The
                    crate holds lc_supply_loads loads (5). If any are left when
                    the convoy moves on, every unit within reach of it is paid
                    lc_supply_pay credits (40); if it's emptied, the city hears
                    about it.
      Jammers       a radio jammer (the Resistance lab's scientist makes one
                    from a retuned radio, scrap and chemicals; the black
                    market sells them) is set down from your
                    pockets and hisses for lc_jammer_secs (240). Within
                    lc_jammer_radius (1000): units' radios are static (they
                    can't call a 10-20, backup or talk on the CP band, and what
                    reaches them is garbled), request devices don't get
                    through, and a scanner's photographs never reach Civil
                    Protection. It beeps; units can find it and smash it (E,
                    for XP), and anyone can shoot it.

      lc_supply_minutes (6), lc_supply_loads (5), lc_supply_pay (40),
      lc_jammer_secs (240), lc_jammer_radius (1000)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvLoads   = CreateConVar("lc_supply_loads", "5", FLAGS, "Loads a supply drop's crate holds")
local cvPay     = CreateConVar("lc_supply_pay", "40", FLAGS, "Credits each Civil Protection unit near a supply drop is paid if the convoy leaves with supplies still in it")
local cvGuards  = CreateConVar("lc_supply_guards", "1", FLAGS, "Overwatch soldiers standing guard over a supply drop (they turn to look about, and warn anyone at the crates)")
local cvPorters = CreateConVar("lc_supply_porters", "2", FLAGS, "Metrocops unloading a supply drop: carrying boxes from the stack to a spot down the street, and back, the whole time")
local cvJamSecs = CreateConVar("lc_jammer_secs", "240", FLAGS, "Seconds a radio jammer runs")
local cvJamR    = CreateConVar("lc_jammer_radius", "1000", FLAGS, "How far a radio jammer reaches")

local function Pick(t) return t[math.random(#t)] end
local function Unit(p) return LC.PlayerIsCP and LC.PlayerIsCP(p) end

------------------------------------------------------------------------
-- Supply drops
------------------------------------------------------------------------

LC.Supply = LC.Supply or nil -- { crate, guards = {}, pos, loads, startT, raided = {} }

-- What a load is: one roll, and a second now and then.
local LOADS = {
    { "gun_parts", 18 }, { "ammo_pistol", 14 }, { "ammo_smg", 10 }, { "ammo_buckshot", 6 }, { "chemicals", 14 },
    { "ration", 16 }, { "bandage", 12 }, { "scrap", 6 }, { "gren_smoke", 4 },
}
local function Roll()
    local total = 0
    for _, e in ipairs(LOADS) do total = total + e[2] end
    local r = math.random() * total
    for _, e in ipairs(LOADS) do
        r = r - e[2]
        if r <= 0 then return e[1] end
    end
    return "ration"
end

-- Somewhere on the street, away from rebel ground and the infestation.
local function DropSpot()
    for _ = 1, 30 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("citizen")
        if p and not (LC.InRebelZone and LC.InRebelZone(p)) and not (LC.InfestZoneAt and LC.InfestZoneAt(p))
            and not (LC.CombineZoneAt and LC.CombineZoneAt(p)) then
            return p
        end
    end
    return nil
end
LC.SupplyDropSpot = DropSpot

-- A supply drop comes to a loading dock if the map has one (the editor's
-- "Point: loading dock"), else somewhere on the street.
local function DockSpot()
    local docks = LC.PointsOfKind and LC.PointsOfKind("dock") or {}
    if #docks > 0 then return Pick(docks).pos end
    return nil
end

local CRATES = { "models/items/item_item_crate.mdl", "models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_crate002a.mdl" }
local APC = "models/combine_apc.mdl"

local function Extra(s, model, pos, yaw)
    if util.IsValidModel and not util.IsValidModel(model) then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local mins = e:OBBMins()
    e:SetPos(pos + Vector(0, 0, -(mins and mins.z or 0) + 1))
    e:SetAngles(Angle(0, yaw or math.random(0, 359), 0))
    e:Spawn()
    local phys = e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcDressing = true -- (scenery: not loot, not pocketed)
    s.props[#s.props + 1] = e
    return e
end

-- The crate you loot, a stack of the rest beside it, and the guard round it.
local function Unload(s, ground, side)
    side = side or Vector(1, 0, 0)
    local across = Vector(-side.y, side.x, 0)
    local crate = ents.Create("lc_supply")
    if not IsValid(crate) then return end
    crate:SetPos(ground + side * 140 + Vector(0, 0, 4))
    crate:SetAngles(Angle(0, math.random(0, 359), 0))
    crate:Spawn()
    crate:Activate()
    crate:SetNW2Int("lc_loads", s.loads)
    s.crate = crate
    -- the rest of the load, stacked up beside it
    for i = 1, 4 do
        local at = ground + side * (140 + math.Rand(-20, 20)) + across * ((i <= 2 and 1 or -1) * (60 + (i % 2) * 40))
        local e = Extra(s, Pick(CRATES), LC.GroundAt and LC.GroundAt(at) or at)
        if IsValid(e) and i == 1 then
            -- one on top of another
            local top = Extra(s, Pick(CRATES), e:GetPos() + Vector(0, 0, e:OBBMaxs().z + 1))
            if IsValid(top) then top:SetPos(e:GetPos() + Vector(0, 0, e:OBBMaxs().z - top:OBBMins().z + 1)) end
        end
    end
    -- the guard: a few units standing round it
    local spawner = LC.Spawners and (LC.Spawners.cop or LC.Spawners.soldier)
    -- (never inside the container the dropship set down, or a crate, or a wall)
    local function Free(p)
        local c = s.container
        if IsValid(c) then
            local l, mins, maxs = c:WorldToLocal(p), c:OBBMins(), c:OBBMaxs()
            if l.x > mins.x - 32 and l.x < maxs.x + 32 and l.y > mins.y - 32 and l.y < maxs.y + 32 then return false end
        end
        for _, e in ipairs(s.props) do
            if IsValid(e) and e:GetPos():DistToSqr(p) < 50 * 50 then return false end
        end
        return not LC.ClearSpot or LC.ClearSpot(p)
    end
    local n = cvGuards:GetInt()
    for i = 1, n do
        local gp
        for try = 0, 11 do
            local a = (i / math.max(1, n)) * math.pi * 2 + try * 0.52
            local cand = ground + side * 140 + Vector(math.cos(a) * (130 + (try % 3) * 40), math.sin(a) * (130 + (try % 3) * 40), 4)
            cand = LC.GroundAt and LC.GroundAt(cand) or cand
            if Free(cand) then gp = cand break end
        end
        gp = gp or (ground + side * 260 + Vector(0, 0, 4))
        local ok, npc, st = pcall(function() return (LC.Spawners and LC.Spawners.soldier or spawner)(gp) end)
        if ok and IsValid(npc) and st then
            st.unmanaged = true
            st.supplyGuard = true
            if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
            if LC.SetState then LC.SetState(npc, st, "event") end
            st.eventUntil = CurTime() + 3600
            s.guards[#s.guards + 1] = npc
        end
    end
    -- and the ones unloading it: a box at a time, off down the street and back
    s.porters = {}
    s.dropAt = LC.SupplyDropOff(s, ground + side * 140)
    for i = 1, cvPorters:GetInt() do
        local gp = (LC.GroundAt and LC.GroundAt(ground + side * 140 + across * (i % 2 == 0 and 110 or -110))) or (ground + side * 140)
        local ok, npc, st = pcall(function() return (LC.Spawners and LC.Spawners.cop or spawner)(gp + Vector(0, 0, 4)) end)
        if ok and IsValid(npc) and st then
            st.unmanaged = true
            st.supplyGuard = true
            st.supplyPorter = { phase = "pick", t = CurTime() + i * 3, stack = gp }
            if LC.SetState then LC.SetState(npc, st, "event") end
            st.eventUntil = CurTime() + 3600
            s.guards[#s.guards + 1] = npc
            s.porters[#s.porters + 1] = npc
        end
    end
    hook.Run("LivingCitySupplyUnloaded", s)
end

-- By road, where a dropship can't come down (a dock under a roof): an APC is
-- parked at the dock when nobody's looking, the load beside it.
local function ByRoad(s, tries)
    if LC.Supply ~= s then return end
    tries = tries or 0
    if tries < 15 and LC.IsSeen and LC.IsSeen(s.pos + Vector(0, 0, 60)) then
        timer.Simple(2, function() ByRoad(s, tries + 1) end)
        return
    end
    local yaw = math.random(0, 359)
    local side = Angle(0, yaw, 0):Right()
    local apc = Extra(s, APC, LC.GroundAt and LC.GroundAt(s.pos - side * 60) or s.pos, yaw)
    if IsValid(apc) then apc:EmitSound("ambient/machines/truck_pass_overhead1.wav", 80) end
    Unload(s, s.pos, side)
end

function LC.StartSupplyDrop(pos)
    if LC.Supply then LC.EndSupplyDrop(true) end
    pos = pos or DockSpot() or DropSpot()
    if not pos then return false, "nowhere to put it" end
    local loads = cvLoads:GetInt()
    local s = { guards = {}, props = {}, pos = pos, loads = loads, startT = CurTime(), raided = {} }
    LC.Supply = s
    -- by air if there's open sky over the dock: the container comes down under a dropship
    local ship = LC.FlyDropship and LC.FlyDropship({ pos = pos, cargo = true, hold = 6,
        onLanded = function(sh, ground, container)
            if LC.Supply ~= s then return end
            s.container = container
            Unload(s, ground, sh:GetForward())
        end })
    s.byAir = ship ~= nil
    if not ship then ByRoad(s) end
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    for _, p in ipairs(player.GetAll()) do
        if Unit(p) then
            p:ChatPrint("[CP net] A supply " .. (s.byAir and "dropship is coming down " or "convoy is unloading ") .. where .. ". Guard the drop until it moves on. Directive on your board (F3).")
        end
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "A Combine supply " .. (s.byAir and "dropship, coming down " or "convoy, ") .. where .. ". Guns, ammunition, medicine. Lightly guarded.")
    end
    if LC.SendCompressed then
        local units = {}
        for _, p in ipairs(player.GetAll()) do if Unit(p) then units[#units + 1] = p end end
        if #units > 0 then LC.SendCompressed("lc_cpmark", { name = "SUPPLY DROP", x = pos.x, y = pos.y, z = pos.z, secs = 120 }, units) end
    end
    LC.Log("info", "Supply drop " .. where .. (s.byAir and " (by dropship)" or " (by road)"))
    hook.Run("LivingCitySupplyDrop", s)
    return true, s
end

-- What's left lying about when the convoy moves on: the dropship comes back
-- for its container; the APC and the crates go once nobody's looking.
local leftovers = {}
local function Leave(s)
    if IsValid(s.container) then
        local c = s.container
        local ok = LC.FlyDropship and LC.FlyDropship({ pos = s.pos, pickup = c, hold = 3 })
        if not ok then leftovers[#leftovers + 1] = { ent = c, at = CurTime() } end
    end
    for _, e in ipairs(s.props or {}) do
        if IsValid(e) then leftovers[#leftovers + 1] = { ent = e, at = CurTime() } end
    end
end
timer.Create("LivingCitySupplyLeftovers", 3, 0, function()
    local now = CurTime()
    for i = #leftovers, 1, -1 do
        local l = leftovers[i]
        if not IsValid(l.ent) then
            table.remove(leftovers, i)
        elseif now - l.at > 120 or not (LC.IsSeen and LC.IsSeen(l.ent:GetPos() + Vector(0, 0, 40))) then
            l.ent:Remove()
            table.remove(leftovers, i)
        end
    end
end)

function LC.EndSupplyDrop(silent)
    local s = LC.Supply
    if not s then return end
    LC.Supply = nil
    local left = IsValid(s.crate) and s.crate:GetNW2Int("lc_loads", 0) or (s.crate and 0 or s.loads)
    if not silent then
        if left > 0 then
            local pay = cvPay:GetInt()
            for _, p in ipairs(player.GetAll()) do
                if Unit(p) and p:Alive() and p:GetPos():DistToSqr(s.pos) < 1500 * 1500 then
                    LC.AddCredits(p, pay, "supply drop secured")
                    if LC.AddXP then LC.AddXP(p, 15, "supply drop secured") end
                end
            end
            for _, p in ipairs(player.GetAll()) do
                if Unit(p) then p:ChatPrint(string.format("[CP net] The convoy moves on with %d of %d loads. Drop secured.", left, s.loads)) end
            end
        else
            for _, p in ipairs(player.GetAll()) do
                p:ChatPrint("[City] A Union supply drop was looted. Anyone with information is to report it to Civil Protection.")
            end
            if LC.RadioNotice then LC.RadioNotice("resistance", "The supply drop's empty. Good work.") end
        end
    end
    if IsValid(s.crate) then s.crate:Remove() end
    Leave(s)
    for _, g in ipairs(s.guards) do
        local st = IsValid(g) and LC.NPCs and LC.NPCs[g]
        if st then
            -- the guards walk off with the convoy, and the city takes them back
            if st.supplyPorter and IsValid(st.carry) and LC.NPCDropCarry then LC.NPCDropCarry(g, st) end
            st.unmanaged, st.supplyGuard, st.supplyPorter, st.eventUntil = nil, nil, nil, 0
            st.leaveAt = CurTime() + 60
        end
    end
    hook.Run("LivingCitySupplyEnded", s, left)
end

-- E on the crate: take a load.
function LC.LootSupply(ply, crate)
    local s = LC.Supply
    if not s or s.crate ~= crate or not IsValid(crate) then return false, "Empty, and sealed." end
    if Unit(ply) then return false, "[CP net] Union supplies. Guard them until the convoy moves on." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    if crate:GetNW2Int("lc_loads", 0) <= 0 then return false, "Cleaned out." end
    s.prying = s.prying or {}
    s.prying[ply] = true
    return LC.StartTask(ply, 8, "Prying a load out of the crate... keep still", {
        maxMove = 48, cancelText = "You leave it.",
        cancel = function(p) if s.prying then s.prying[p] = nil end end,
        done = function(p)
            if s.prying then s.prying[p] = nil end
            if LC.Supply ~= s or not IsValid(crate) then return end
            local n = crate:GetNW2Int("lc_loads", 0)
            if n <= 0 then p:ChatPrint("Someone beat you to it.") return end
            crate:SetNW2Int("lc_loads", n - 1)
            local got = {}
            for i = 1, math.random() < 0.4 and 2 or 1 do
                local id = Roll()
                if LC.GiveOrDrop then LC.GiveOrDrop(p, id, 1) else LC.GiveItem(p, id) end
                got[#got + 1] = LCS.Items[id] and LCS.Items[id].name or id
            end
            s.raided[p] = true
            p:ChatPrint("Taken from the supply drop: " .. table.concat(got, ", ") .. ".")
            crate:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 45) -- (quietly)
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, "Looting Union supplies", 240)
                p:ChatPrint("[Civil Protection] A Civil Protection unit saw you at the crate.")
            end
            if LC.QuestEvent then LC.QuestEvent("supply_looted", p, crate) end
            hook.Run("LivingCitySupplyLooted", p, got)
            if n - 1 <= 0 then
                for _, u in ipairs(player.GetAll()) do
                    if Unit(u) then u:ChatPrint("[CP net] The supply drop has been emptied.") end
                end
            end
        end,
    })
end

-- Where the unloaded boxes go: a spot down the street, a walk away from the stack (on the
-- units' own paths, not in rebel ground), else just along from it.
function LC.SupplyDropOff(s, from)
    local best
    for _, p in ipairs(LC.NodePositions and LC.NodePositions("cop") or {}) do
        local d = p:Distance(from)
        if d > 450 and d < 900 and math.abs(p.z - from.z) < 80 and not (LC.InRebelZone and LC.InRebelZone(p)) then
            best = p
            if math.random() < 0.3 then break end
        end
    end
    return best or ((LC.GroundAt and LC.GroundAt(from + Vector(500, 0, 30))) or (from + Vector(500, 0, 0)))
end

local BOXES = { "models/props_junk/cardboard_box001a.mdl", "models/props_junk/cardboard_box002a.mdl", "models/props_junk/cardboard_box003a.mdl" }
local function Walk(npc, pos)
    if not npc.SetLastPosition then return end
    npc:SetLastPosition(pos)
    npc:SetSchedule(SCHED_FORCED_GO)
end

-- A porter's round: to the stack, a box up in both hands, off to the drop, set it down, back.
local function PorterStep(s, npc, st, now)
    local P = st.supplyPorter
    if st.state == "hostile" then
        if IsValid(st.carry) and LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
        return
    end
    if now < (P.t or 0) then return end
    local pos = npc:GetPos()
    local function Stuck(goal)
        if P.lastPos and pos:DistToSqr(P.lastPos) < 20 * 20 then P.still = (P.still or 0) + 1 else P.still = 0 end
        P.lastPos = pos
        if P.still >= 16 and not (LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 40))) then npc:SetPos(goal + Vector(0, 0, 4)) P.still = 0 end
    end
    if P.phase == "pick" then
        if pos:DistToSqr(P.stack) > 80 * 80 then Walk(npc, P.stack) Stuck(P.stack) P.t = now + 0.5 return end
        if LC.Face and IsValid(s.crate) then LC.Face(npc, s.crate:GetPos()) end
        if LC.PlayGesture then LC.PlayGesture(npc, { "ACT_PICKUP_GROUND", "ACT_PICKUP_RACK" }, 1.5) end
        P.phase, P.t = "lift", now + 1.6
    elseif P.phase == "lift" then
        if LC.NPCCarry then LC.NPCCarry(npc, st, BOXES[math.random(#BOXES)]) end
        P.phase, P.t = "carry", now + 0.3
        Walk(npc, s.dropAt)
    elseif P.phase == "carry" then
        if pos:DistToSqr(s.dropAt) > 80 * 80 then Walk(npc, s.dropAt) Stuck(s.dropAt) P.t = now + 0.5 return end
        if LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
        -- set down: a pile that grows at the drop (cleared away with the rest after)
        if #s.props < 30 then
            local n = (s.dropped or 0)
            s.dropped = n + 1
            local at = s.dropAt + Vector((n % 3) * 26 - 26, math.floor(n / 3) % 2 * 26, 0)
            local e = ents.Create("prop_physics")
            if IsValid(e) then
                e:SetModel(BOXES[math.random(#BOXES)])
                e:SetPos(at + Vector(0, 0, 12 + math.floor(n / 6) * 18))
                e:Spawn()
                local ph = e:GetPhysicsObject()
                if IsValid(ph) then ph:EnableMotion(false) end
                e.lcDressing = true
                s.props[#s.props + 1] = e
            end
        end
        P.phase, P.t = "pick", now + 1.2
        Walk(npc, P.stack)
    end
end
LC.SupplyPorterStep = PorterStep

local GUARD_WARN = { "npc/combine_soldier/vo/contained.wav", "npc/combine_soldier/vo/stayalert.wav" }
-- The guard: turns to look about now and then; anyone at the crates (who isn't a unit) is
-- warned off twice, then wanted. Anyone seen prying a load out is stopped there and then.
local function GuardStep(s, now)
    local crate = s.crate
    if not IsValid(crate) then return end
    local cpos = crate:GetPos()
    for _, g in ipairs(s.guards) do
        local st = IsValid(g) and LC.NPCs and LC.NPCs[g]
        if st and not st.supplyPorter and st.state ~= "hostile" and now >= (st.lookNext or 0) then
            st.lookNext = now + math.Rand(3, 6)
            if LC.FaceYaw then LC.FaceYaw(g, g:GetAngles().y + math.random(-110, 110)) end
        end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not Unit(p) and not (LC.DisguisedAsCP and LC.DisguisedAsCP(p)) then
            local seenBy
            for _, g in ipairs(s.guards) do
                if IsValid(g) and g:Health() > 0 and LC.UnitSees and LC.UnitSees(g, p, 700) then
                    local tr = util.TraceLine({ start = g:EyePos(), endpos = p:EyePos(), mask = MASK_OPAQUE, filter = g })
                    if tr.Fraction > 0.97 then seenBy = g break end
                end
            end
            -- caught at it
            if seenBy and s.prying and s.prying[p] then
                s.prying[p] = nil
                if LC.CancelTask then LC.CancelTask(p) end
                seenBy:EmitSound("npc/combine_soldier/vo/contact.wav", 80)
                p:ChatPrint("[Civil Protection] Caught with your hands in the crate.")
                LC.ReportCrime(p, "Looting Union supplies", 240)
                if LC.MakeCopsHostile then LC.MakeCopsHostile(p, cpos, 1200) end
            elseif seenBy and p:GetPos():DistToSqr(cpos) < 260 * 260 and not (LC.PlayerIsWanted and LC.PlayerIsWanted(p)) then
                local w = p.lcSupplyWarn
                if not w or now - w.t > 40 then w = { n = 0, t = 0 } p.lcSupplyWarn = w end
                if now - w.t >= 6 then
                    w.n, w.t = w.n + 1, now
                    if LC.Face then LC.Face(seenBy, p:GetPos()) end
                    if w.n <= 2 then
                        seenBy:EmitSound(GUARD_WARN[w.n], 80)
                        p:ChatPrint(w.n == 1 and "[Overwatch soldier] \"Restricted supply point. Step away from the crates.\""
                            or "[Overwatch soldier] \"Final warning. Step away from the crates.\"")
                    else
                        p:ChatPrint("[Overwatch soldier] \"Noncompliance at the supply point.\" You're wanted.")
                        LC.ReportCrime(p, "Loitering at a Union supply drop", 120)
                        if LC.MakeCopsHostile then LC.MakeCopsHostile(p, cpos, 1200) end
                        p.lcSupplyWarn = nil
                    end
                end
            end
        end
    end
end
LC.SupplyGuardStep = GuardStep

timer.Create("LivingCitySupplyCrew", 0.5, 0, function()
    local s = LC.Supply
    if not s then return end
    local now = CurTime()
    -- (each on its own: a porter tripping over something never stops the guard keeping watch)
    for _, npc in ipairs(s.porters or {}) do
        local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc]
        if st and st.supplyPorter then
            local ok, err = pcall(PorterStep, s, npc, st, now)
            if not ok and LC.Error then LC.Error("supply porter", err) end
        end
    end
    if (s.guardNext or 0) <= now then
        s.guardNext = now + 1
        local ok, err = pcall(GuardStep, s, now)
        if not ok and LC.Error then LC.Error("supply guard", err) end
    end
end)

hook.Add("LivingCityEventStarted", "LivingCitySupply", function(name)
    if name == "supply" then
        local ok, why = LC.StartSupplyDrop()
        if not ok then LC.Log("info", "Supply drop not started: " .. tostring(why)) end
    end
end)
hook.Add("LivingCityEventEnded", "LivingCitySupply", function(name) if name == "supply" then LC.EndSupplyDrop(false) end end)

------------------------------------------------------------------------
-- Radio jammers
------------------------------------------------------------------------

LC.Jammers = LC.Jammers or {}

function LC.Jammed(pos)
    if not pos then return false end
    local r = cvJamR:GetFloat()
    for i = #LC.Jammers, 1, -1 do
        local j = LC.Jammers[i]
        if not IsValid(j) then
            table.remove(LC.Jammers, i)
        elseif j:GetPos():DistToSqr(pos) < r * r then
            return true, j
        end
    end
    return false
end

-- Set one down from your pockets.
function LC.PlaceJammer(ply)
    if Unit(ply) then return false, "Civil Protection units don't jam their own radios." end
    if not LC.HasItem(ply, "jammer") then return false, "You don't have a jammer." end
    local j = ents.Create("lc_jammer")
    if not IsValid(j) then return false end
    LC.TakeItem(ply, "jammer")
    local pos = (LC.InFrontOf and LC.InFrontOf(ply, 30) or ply:GetPos()) - Vector(0, 0, 26)
    j:SetPos(pos)
    j:Spawn()
    j:Activate()
    j.lcOwner = ply
    j.lcUntil = CurTime() + cvJamSecs:GetFloat()
    j:SetNW2Float("lc_jam_until", j.lcUntil)
    table.insert(LC.Jammers, j)
    ply:ChatPrint(string.format("[Jammer] It hisses into life. %d seconds of static for every Civil Protection unit radio within reach.", cvJamSecs:GetInt()))
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
        LC.ReportCrime(ply, "Operating a jamming device", 240)
        ply:ChatPrint("[Civil Protection] A Civil Protection unit saw you set it down.")
    end
    hook.Run("LivingCityJammerPlaced", ply, j)
    return true, j
end

-- A unit smashes it (E), or it runs out.
function LC.SmashJammer(ply, j)
    if not IsValid(j) then return false end
    if not Unit(ply) then return false, "It hisses. Better not to touch it." end
    j:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 75)
    j:Remove()
    if LC.AddXP then LC.AddXP(ply, 15, "jammer destroyed") end
    ply:ChatPrint("[CP net] Jammer destroyed. Radio's clear.")
    return true
end

local anyJammed = false
timer.Create("LivingCityJammers", 1, 0, function()
    local now = CurTime()
    for i = #LC.Jammers, 1, -1 do
        local j = LC.Jammers[i]
        if not IsValid(j) then
            table.remove(LC.Jammers, i)
        elseif now > (j.lcUntil or 0) then
            j:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 70)
            j:Remove()
            table.remove(LC.Jammers, i)
        end
    end
    -- units know when they're in it (their HUD shows the static); with no jammers
    -- anywhere and nobody left jammed, there's nothing to check
    if #LC.Jammers == 0 and not anyJammed then return end
    anyJammed = false
    for _, p in ipairs(player.GetAll()) do
        local jam = Unit(p) and LC.Jammed(p:GetPos()) or false
        if jam then anyJammed = true end
        if p:GetNW2Bool("lc_jammed", false) ~= jam then p:SetNW2Bool("lc_jammed", jam) end
    end
end)
