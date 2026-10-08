--[[
    Living City: supply drops, radio jammers

      Supply drop   a city event ("supply", now and then by itself, or
                    lc_event supply): Union supplies come to a loading dock
                    (the editor's "Point: loading dock"; somewhere on the
                    street if there's none). With open sky over the dock a
                    dropship brings them in, sets a cargo container down and
                    climbs away (and comes back for the container when it's
                    over); under a roof an APC is parked there. Beside it, a
                    stack of crates and the one you can open, with a few
                    units standing guard, for lc_supply_minutes (6). Units
                    get a directive to guard it; the Resistance get one to raid
                    it. Anyone who isn't a unit can press E on the crate and
                    take a load (eight seconds, keep still): gun parts,
                    ammunition, chemicals, rations, a medkit's worth of
                    bandages. A unit who sees you at it makes you wanted. The
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
local cvPay     = CreateConVar("lc_supply_pay", "40", FLAGS, "Credits each unit near a supply drop is paid if the convoy leaves with supplies still in it")
local cvGuards  = CreateConVar("lc_supply_guards", "3", FLAGS, "Units standing guard over a supply drop")
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
        local ok, npc, st = pcall(function() return (i == 1 and LC.Spawners and LC.Spawners.soldier or spawner)(gp) end)
        if ok and IsValid(npc) and st then
            st.unmanaged = true
            st.supplyGuard = true
            if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
            if LC.SetState then LC.SetState(npc, st, "event") end
            st.eventUntil = CurTime() + 3600
            s.guards[#s.guards + 1] = npc
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
            st.unmanaged, st.supplyGuard, st.eventUntil = nil, nil, 0
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
    return LC.StartTask(ply, 8, "Prying a load out of the crate... keep still", {
        maxMove = 48, cancelText = "You leave it.",
        done = function(p)
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
            crate:EmitSound("physics/wood/wood_box_break" .. math.random(1, 2) .. ".wav", 70)
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, "Looting Union supplies", 240)
                p:ChatPrint("[Civil Protection] A unit saw you at the crate.")
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
    if Unit(ply) then return false, "Units don't jam their own radios." end
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
    ply:ChatPrint(string.format("[Jammer] It hisses into life. %d seconds of static for every unit radio within reach.", cvJamSecs:GetInt()))
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
        LC.ReportCrime(ply, "Operating a jamming device", 240)
        ply:ChatPrint("[Civil Protection] A unit saw you set it down.")
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
