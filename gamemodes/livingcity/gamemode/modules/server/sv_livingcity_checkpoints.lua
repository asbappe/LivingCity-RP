--[[
    Living City: checkpoints, turrets, and holding the infestation back

    A checkpoint is built round a Combine power bank (an editor fixture, or
    put up by a Civil Protection officer: the actions menu). Turrets and
    forcefields within lc_checkpoint_range (700 units) of it hang off it by a
    cable; a turret with no bank near it can hang off a forcefield instead.
    The bank draws from its district (sv_livingcity_power.lua): when the
    district goes dark, the whole city does, or a multitool shorts the bank
    out, its glow dies and everything on its cables goes down with it. A
    turret with no power folds up and goes quiet.

    Turrets are Half-Life 2's Combine floor turrets. They shoot the infected,
    the wanted, known rebels and the Resistance's fighters, and leave
    ordinary citizens and units alone. Units put them up (the actions menu:
    Civil Protection > Deploy a turret here), lc_turrets_per_unit (2) each,
    lc_turrets_per_post (4) on one bank or forcefield, and pack them up again
    (E on one, or the menu). Only units can pick them up or move them.

    Power banks have a limit: each feeds lc_bank_loads (2) things, turrets
    and forcefields alike (two turrets, a forcefield and a turret, or two
    forcefields), the nearest first; anything past that sits dead until a
    bank with room is near it. A forcefield needs a bank
    (lc_forcefield_needs_bank 1); so does a turret.

    Forcefields take a beating, and give out. Each has lc_forcefield_hp (300)
    of strength that comes back at lc_forcefield_regen (15) a second once it's
    been left alone for a few seconds. Infected pressing against it wear it
    down (6 a second each: two can't get through, five will), and so do
    bullets and explosives. Run it down to nothing and it's overwhelmed:
    offline for lc_forcefield_down seconds (30). Overwhelmed lc_forcefield_breaks
    times (3) inside five minutes, or blown up while it's down, and it's
    broken until it's repaired: a Maintenance Technician (E on it, ten
    seconds, paid), or one of the city's own maintenance crew walks out and
    fixes it (after the players have had their chance); with no crew in the
    city, emergency crews after lc_forcefield_fix_minutes (6).

    Holding the infestation: forcefields stop the infected as well as people,
    the infestation can't spread past a checkpoint that has power, and what
    the turrets kill holds it where it is (quietly: no radio for every kill)
    without pushing it back; units still have to go in for that. Take the
    power away, though, and it's a containment breach: the infestation surges
    over the checkpoint and the infected come pouring out into the city.
]]

if CLIENT then return end

LC = LC or {}
LC.DeployedTurrets = LC.DeployedTurrets or {} -- [turret] = the unit who put it up
LC.DeployedBanks = LC.DeployedBanks or {}     -- [bank] = the officer who put it up
LC.Breaches = LC.Breaches or {}               -- { pos, t }

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRange   = CreateConVar("lc_checkpoint_range", "700", FLAGS, "How far a power bank's cables reach (turrets and forcefields run off the nearest one)")
local cvPerUnit = CreateConVar("lc_turrets_per_unit", "2", FLAGS, "Turrets one unit can have up at once")
local cvPerPost = CreateConVar("lc_turrets_per_post", "4", FLAGS, "Turrets one power bank (or forcefield) can power")
local cvContain = CreateConVar("lc_containment", "1", FLAGS, "A checkpoint with power stops the infestation spreading past it, and losing that power is a breach")
local cvBreach  = CreateConVar("lc_breach_infected", "4", FLAGS, "Infected that come pouring out of a containment breach")
local cvLoads   = CreateConVar("lc_bank_loads", "2", FLAGS, "Things one power bank can feed: turrets and forcefields together")
local cvNeedBank = CreateConVar("lc_forcefield_needs_bank", "1", FLAGS, "Forcefields and turrets need a Combine power bank to run (0: a forcefield runs off its district, a turret off a forcefield)")
local cvFFHP    = CreateConVar("lc_forcefield_hp", "300", FLAGS, "How much punishment a forcefield takes before it's overwhelmed")
local cvFFRegen = CreateConVar("lc_forcefield_regen", "15", FLAGS, "How fast a forcefield's strength comes back, per second, once it's left alone")
local cvFFDown  = CreateConVar("lc_forcefield_down", "30", FLAGS, "Seconds an overwhelmed forcefield stays offline")
local cvFFBreak = CreateConVar("lc_forcefield_breaks", "3", FLAGS, "Times overwhelmed inside five minutes before a forcefield breaks and needs repairing")
local cvFFFix   = CreateConVar("lc_forcefield_fix_minutes", "6", FLAGS, "Minutes before emergency crews repair a broken forcefield when no maintenance crew (player or NPC) has")

local TURRET = "npc_turret_floor"
local BREACH_NEAR = 1500    -- a checkpoint this close to the infestation is containing it
local BREACH_COOLDOWN = 300 -- one breach in a place every five minutes, at most

local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end
local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end

------------------------------------------------------------------------
-- What runs off what
------------------------------------------------------------------------

function LC.PowerBankLive(b)
    return IsValid(b) and not b:GetNW2Bool("lc_nopower", false) and b:GetNW2Float("lc_short_until", 0) < CurTime()
end
local function FieldUp(f)
    return IsValid(f) and not f:GetNW2Bool("lc_nopower", false) and f:GetNW2Float("lc_short_until", 0) < CurTime()
end

local function Nearest(cls, pos, r)
    local best, bd, r2 = nil, nil, r * r
    for _, e in ipairs(LC.EntsOf(cls)) do
        local d = e:GetPos():DistToSqr(pos)
        if d < r2 and (not bd or d < bd) then best, bd = e, d end
    end
    return best
end

-- The bank something hangs off, if there's one in reach.
function LC.BankFor(pos) return Nearest("lc_powerbank", pos, cvRange:GetFloat()) end

local Turrets -- (below)

-- Who each bank feeds: at most lc_bank_loads things, the nearest first.
-- [thing] = its bank, or false (in reach of a bank, but the bank is full).
local loads, loadsAt = {}, -1
function LC.BankLoads(force)
    local now = CurTime()
    if not force and loadsAt == now then return loads end
    loadsAt = now
    local cands = {}
    local function Add(e)
        local b = LC.BankFor(e:GetPos())
        if b then cands[#cands + 1] = { e = e, b = b, d = e:GetPos():DistToSqr(b:GetPos()) } end
    end
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do Add(f) end
    for _, t in ipairs(Turrets()) do Add(t) end
    table.sort(cands, function(a, b) if a.d ~= b.d then return a.d < b.d end return a.e:EntIndex() < b.e:EntIndex() end)
    local used, out, cap = {}, {}, cvLoads:GetInt()
    for _, c in ipairs(cands) do
        if (used[c.b] or 0) < cap then used[c.b] = (used[c.b] or 0) + 1 out[c.e] = c.b else out[c.e] = false end
    end
    loads = out
    return out
end

-- How many things a bank is feeding.
function LC.BankLoad(b)
    local n = 0
    for _, bank in pairs(LC.BankLoads()) do if bank == b then n = n + 1 end end
    return n
end

-- Whether a forcefield has power: off its bank (if the bank has room for it).
-- With lc_forcefield_needs_bank 0, off its bank if it has one, else its district.
-- (sv_livingcity_power.lua asks this for every forcefield.)
function LC.FieldOff(f)
    if cvNeedBank:GetBool() then
        local b = LC.BankLoads()[f]
        return not (b and LC.PowerBankLive(b))
    end
    local b = LC.BankFor(f:GetPos())
    if IsValid(b) then return not LC.PowerBankLive(b) end
    return LC.PowerDarkAt and LC.PowerDarkAt(f:GetPos()) or false
end

-- What a turret's cable runs to: its bank (if the bank has room for it).
-- With lc_forcefield_needs_bank 0: a bank, else a forcefield.
function LC.TurretSource(t)
    if cvNeedBank:GetBool() then return LC.BankLoads()[t] or nil end
    local p, r = t:GetPos(), cvRange:GetFloat()
    return Nearest("lc_powerbank", p, r) or Nearest("lc_forcefield", p, r)
end
local function SourceLive(s)
    if not IsValid(s) then return false end
    if s:GetClass() == "lc_powerbank" then return LC.PowerBankLive(s) end
    return FieldUp(s)
end

-- The city's turrets: the editor's and the ones units put up (not whatever else the map has).
function Turrets()
    local out = {}
    for _, t in ipairs(LC.EntsOf(TURRET)) do
        if IsValid(t) and (t.lcFixture or LC.DeployedTurrets[t]) then out[#out + 1] = t end
    end
    return out
end
LC.CheckpointTurrets = Turrets

function LC.IsCheckpointTurret(e) return IsValid(e) and e.lcTurret == true end

------------------------------------------------------------------------
-- Who a turret shoots
------------------------------------------------------------------------

local function PlayerRel(p)
    if not p:Alive() then return D_NU end
    if LC.PlayerIsCP(p) or (LC.FoolsSecurity and LC.FoolsSecurity(p)) then return D_LI end
    if LC.InCustody and LC.InCustody(p) then return D_NU end
    if LC.PlayerIsZombie(p) or LC.PlayerIsWanted(p) then return D_HT end
    if p:GetNW2String("lcf_faction", "") == "resistance" and LC.PlayerIsHunted and LC.PlayerIsHunted(p)
        and not (LC.PassesAsCitizen and LC.PassesAsCitizen(p)) then return D_HT end
    return D_NU
end
LC.TurretAttitude = PlayerRel

local NPC_REL = { zombie = "hate", rebel = "hate", citizen = "ignore", vort = "ignore", vortigaunt = "ignore" }
local function NPCRel(st)
    local r = NPC_REL[st.role]
    if r == "hate" then return D_HT elseif r == "ignore" then return D_NU end
    return D_LI -- the Combine's own
end

local function Init(t)
    if t.lcTurret then return end
    t.lcTurret = true
    -- held still until it has power: an unpowered turret is a folded-up tripod
    -- and would just topple over on its own. Once it's powered it stands on its
    -- legs, and can be knocked over again (that's how you beat one).
    local phys = t:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    t.lcRel = {}
    -- not the player's enemy, nor the citizens', until it's told otherwise
    if t.AddRelationship then
        t:AddRelationship("player D_NU 99")
        t:AddRelationship("npc_citizen D_NU 99")
    end
    t.lcNextRel = 0
end

local function Relationships(t, now)
    if (t.lcNextRel or 0) > now then return end
    t.lcNextRel = now + 1
    local rel = t.lcRel
    for _, p in ipairs(player.GetAll()) do
        local r = PlayerRel(p)
        if rel[p] ~= r then rel[p] = r t:AddEntityRelationship(p, r, 99) end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) then
            local r = NPCRel(st)
            if rel[npc] ~= r then rel[npc] = r t:AddEntityRelationship(npc, r, 99) end
        end
    end
end

hook.Add("OnEntityCreated", "LivingCityCheckpoints", function(e)
    if not IsValid(e) or e:GetClass() ~= TURRET then return end
    timer.Simple(0, function()
        if IsValid(e) and (e.lcFixture or LC.DeployedTurrets[e]) then Init(e) end
    end)
end)

------------------------------------------------------------------------
-- Containment: the infestation stops at a checkpoint with power
------------------------------------------------------------------------

-- Every live piece of a checkpoint.
function LC.ContainmentPosts()
    local out = {}
    for _, b in ipairs(LC.EntsOf("lc_powerbank")) do if LC.PowerBankLive(b) then out[#out + 1] = b end end
    for _, t in ipairs(Turrets()) do if t.lcPowered then out[#out + 1] = t end end
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do if FieldUp(f) then out[#out + 1] = f end end
    return out
end

-- Squared distance, across the ground, from p to the segment a-b.
local function SegDist2(p, a, b)
    local ax, ay, bx, by = a.x, a.y, b.x, b.y
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    local t = len2 > 0 and math.Clamp(((p.x - ax) * dx + (p.y - ay) * dy) / len2, 0, 1) or 0
    local cx, cy = ax + dx * t - p.x, ay + dy * t - p.y
    return cx * cx + cy * cy
end

-- Would a new patch of infestation at `to` (radius r), grown out from `from`,
-- reach a checkpoint or get past one?
function LC.ContainmentBlocks(from, to, r)
    if not cvContain:GetBool() then return false end
    for _, e in ipairs(LC.ContainmentPosts()) do
        local p = e:GetPos()
        if p:DistToSqr(to) < (r + 250) ^ 2 or SegDist2(p, from, to) < 300 * 300 then return true end
    end
    return false
end

local function InfestNear(pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("infest") or {}) do
        if LCZ.Contains(z, pos, BREACH_NEAR) then
            local d = z.pos:DistToSqr(pos)
            if not bd or d < bd then best, bd = z, d end
        end
    end
    return best
end
LC.InfestNear = InfestNear

-- The power's gone at a checkpoint holding the infestation back.
function LC.ContainmentBreach(post, z)
    local pos = post:GetPos()
    local now = CurTime()
    for i = #LC.Breaches, 1, -1 do
        local b = LC.Breaches[i]
        if now - b.t > BREACH_COOLDOWN then table.remove(LC.Breaches, i)
        elseif b.pos:DistToSqr(pos) < BREACH_NEAR * BREACH_NEAR then return false end
    end
    LC.Breaches[#LC.Breaches + 1] = { pos = pos, t = now }
    local where = Where(pos)
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[City] Containment failure" .. (where ~= "" and (" " .. where) or "") .. "! The infected are breaking out.")
    end
    Radio("cp", "Dispatch: containment breach" .. (where ~= "" and (" " .. where) or "") .. ". All units, hold the line.")
    -- the infestation surges over the checkpoint...
    local seed = z.grown and z.seed or z
    local grew = seed and LC.GrowTerritory and LC.GrowTerritory(seed, pos, 450, "breach") or nil
    -- ...and out they come
    local into = grew or z
    for _ = 1, math.max(0, cvBreach:GetInt()) do
        local spot = LC.SpotInZone and LC.SpotInZone(into)
        if spot and LC.SpawnZombie then LC.SpawnZombie(spot + Vector(0, 0, 4), into) end
    end
    if sound and sound.Play then sound.Play("ambient/alarms/klaxon1.wav", pos, 90) end
    hook.Run("LivingCityBreach", post, z)
    return true
end

------------------------------------------------------------------------
-- Every second
------------------------------------------------------------------------

local function Track(post, live, now)
    if live then
        post.lcLiveSince = post.lcLiveSince or now
        post.lcWasLive = true
        return
    end
    if post.lcWasLive and now - (post.lcLiveSince or now) >= 10 and cvContain:GetBool() then
        local z = InfestNear(post:GetPos())
        if z then LC.ContainmentBreach(post, z) end
    end
    post.lcWasLive, post.lcLiveSince = false, nil
end

function LC.CheckpointTick(now)
    LC.BankLoads(true)
    -- forcefields: a bank's short comes and goes
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do
        local off = LC.FieldOff(f)
        if f:GetNW2Bool("lc_nopower", false) ~= off then
            f:SetNW2Bool("lc_nopower", off)
            if LC.FieldRulesChanged then LC.FieldRulesChanged(f) end
        end
        local b = cvNeedBank:GetBool() and LC.BankLoads()[f] or LC.BankFor(f:GetPos())
        if f:GetNW2Entity("lc_cable") ~= (b or NULL) then f:SetNW2Entity("lc_cable", b or NULL) end
        f:SetNW2Bool("lc_bank_full", LC.BankLoads()[f] == false)
        Track(f, FieldUp(f), now)
    end
    for _, b in ipairs(LC.EntsOf("lc_powerbank")) do Track(b, LC.PowerBankLive(b), now) end
    -- turrets: power, and who they shoot
    for _, t in ipairs(Turrets()) do
        if not t.lcTurret then Init(t) end
        local src = LC.TurretSource(t)
        if t:GetNW2Entity("lc_cable") ~= (src or NULL) then t:SetNW2Entity("lc_cable", src or NULL) end
        local on = src ~= nil and SourceLive(src)
        if t.lcPowered ~= on then
            t.lcPowered = on
            t:Fire(on and "Enable" or "Disable")
            t:SetNW2Bool("lc_nopower", not on)
            local phys = t:GetPhysicsObject()
            if IsValid(phys) and not (t.IsPlayerHolding and t:IsPlayerHolding()) then
                phys:EnableMotion(on)
                if on then phys:Wake() end
            end
        end
        Relationships(t, now)
        Track(t, on, now)
    end
end

timer.Create("LivingCityCheckpoints", 1, 0, function()
    local ok, err = pcall(LC.CheckpointTick, CurTime())
    if not ok and LC.Error then LC.Error("checkpoints", err) end
end)

-- The editor's turrets come back when they've been knocked over or blown up (out of sight).
timer.Create("LivingCityCheckpointTurrets", 60, 0, function()
    if not LC.Running or not LC.Fixtures or not LC.SyncFixtures then return end
    for key, e in pairs(LC.Fixtures) do
        if not IsValid(e) and string.sub(key, 1, 7) == "turret_" then
            local x, y, z = string.match(key, "^turret_(%-?%d+)_(%-?%d+)_(%-?%d+)$")
            local spot = x and Vector(tonumber(x), tonumber(y), tonumber(z) + 40)
            if spot and not (LC.IsSeen and LC.IsSeen(spot)) then
                local ok, err = pcall(LC.SyncFixtures)
                if not ok and LC.Error then LC.Error("fixtures", err) end
                return
            end
        end
    end
end)

------------------------------------------------------------------------
-- Units put turrets up, and take them down
------------------------------------------------------------------------

local function SpawnTurret(pos, ang)
    local t = ents.Create(TURRET)
    if not IsValid(t) then return nil end
    t:SetPos(pos + Vector(0, 0, 2))
    t:SetAngles(ang)
    t:Spawn()
    t:Activate()
    Init(t)
    return t
end

local function Owned(ply)
    local n = 0
    for t, o in pairs(LC.DeployedTurrets) do
        if not IsValid(t) then LC.DeployedTurrets[t] = nil elseif o == ply then n = n + 1 end
    end
    return n
end

function LC.DeployTurret(ply)
    if not LC.PlayerIsCP(ply) then return false, "Units only." end
    if (ply.lcTurretNext or 0) > CurTime() then return false, "Give it a moment." end
    if Owned(ply) >= cvPerUnit:GetInt() then
        return false, "You've got " .. cvPerUnit:GetInt() .. " turrets up already. Pack one up first (E on it)."
    end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:DistToSqr(ply:EyePos()) > 260 * 260 or (tr.HitNormal and tr.HitNormal.z or 0) < 0.7 then
        return false, "Look at the ground in front of you, close by."
    end
    local pos = tr.HitPos
    local hull = util.TraceHull({ start = pos + Vector(0, 0, 4), endpos = pos + Vector(0, 0, 4),
        mins = Vector(-14, -14, 0), maxs = Vector(14, 14, 60), mask = MASK_SOLID, filter = ply })
    if hull and (hull.Hit or hull.StartSolid) then return false, "Not enough room there." end
    local r = cvRange:GetFloat()
    local src
    if cvNeedBank:GetBool() then
        src = Nearest("lc_powerbank", pos, r)
        if not src then return false, "No power here: turrets go up near a Combine power bank." end
        if LC.BankLoad(src) >= cvLoads:GetInt() then
            return false, string.format("That power bank is feeding %d things already (turrets and forcefields): put up another bank.", cvLoads:GetInt())
        end
    else
        src = Nearest("lc_powerbank", pos, r) or Nearest("lc_forcefield", pos, r)
        if not src then
            return false, "No power here: turrets go up at a checkpoint, near a Combine power bank or a forcefield."
        end
        local n = 0
        for _, t in ipairs(Turrets()) do if LC.TurretSource(t) == src then n = n + 1 end end
        if n >= cvPerPost:GetInt() then return false, "That checkpoint is powering all the turrets it can." end
    end
    local t = SpawnTurret(pos, Angle(0, ply:EyeAngles().y, 0))
    if not IsValid(t) then return false, "The turret won't deploy." end
    LC.DeployedTurrets[t] = ply
    t.lcDeployedBy = ply
    ply.lcTurretNext = CurTime() + 5
    LC.BankLoads(true)
    LC.CheckpointTick(CurTime())
    hook.Run("LivingCityTurretDeployed", ply, t, src)
    return true, "Turret deployed, cabled to the " .. (src:GetClass() == "lc_powerbank" and "power bank" or "forcefield")
        .. ". It goes quiet if the power does."
end

function LC.PackTurret(ply, t)
    if not LC.PlayerIsCP(ply) then return false, "Units only." end
    if not IsValid(t) or t:GetClass() ~= TURRET or not LC.DeployedTurrets[t] then return false, "Look at a turret a unit put up." end
    if t:GetPos():DistToSqr(ply:GetPos()) > 160 * 160 then return false, "Get closer." end
    LC.DeployedTurrets[t] = nil
    t:Remove()
    return true, "You fold the turret up and take it with you."
end

-- Officers put up a power bank: on the wall they're looking at.
function LC.DeployPowerBank(ply)
    if not (LC.IsCPOfficer and LC.IsCPOfficer(ply)) then
        return false, "Officers put up power banks (Division Leader and up). Any unit can deploy turrets at one."
    end
    if IsValid(ply.lcBank) then return false, "You've one up already. Take it down first (the actions menu, looking at it)." end
    local tr = ply:GetEyeTrace()
    local n = tr.HitNormal
    if not tr.Hit or tr.HitPos:DistToSqr(ply:EyePos()) > 180 * 180 or not n or math.abs(n.z) > 0.35 then
        return false, "Look at a wall, close by."
    end
    local b = ents.Create("lc_powerbank")
    if not IsValid(b) then return false, "It won't go up." end
    b:SetAngles(n:Angle())
    b:SetPos(tr.HitPos)
    b:Spawn()
    b:Activate()
    local mins = b:OBBMins()
    b:SetPos(tr.HitPos + n * (1 - (mins and mins.x or 0)))
    LC.DeployedBanks[b] = ply
    b.lcDeployedBy = ply
    ply.lcBank = b
    if LC.RefreshPower then LC.RefreshPower() end
    LC.CheckpointTick(CurTime())
    return true, "Power bank up. Turrets and forcefields near it run off it now."
end

function LC.PackPowerBank(ply, b)
    if not IsValid(b) or b:GetClass() ~= "lc_powerbank" or not LC.DeployedBanks[b] then return false, "That one's the city's, not yours to take down." end
    if LC.DeployedBanks[b] ~= ply and not (LC.IsCPOfficer and LC.IsCPOfficer(ply)) then return false, "Officers only." end
    if b:GetPos():DistToSqr(ply:GetPos()) > 180 * 180 then return false, "Get closer." end
    LC.DeployedBanks[b] = nil
    if IsValid(b.lcDeployedBy) then b.lcDeployedBy.lcBank = nil end
    b:Remove()
    return true, "You take the power bank down."
end

-- E on a bank: units read what it's powering. (The multitool's primary fire shorts it out.)
function LC.UsePowerBank(ply, b)
    local turrets, fields = 0, 0
    for _, t in ipairs(Turrets()) do if LC.TurretSource(t) == b then turrets = turrets + 1 end end
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do if LC.BankLoads()[f] == b then fields = fields + 1 end end
    if b:GetNW2Float("lc_short_until", 0) > CurTime() then return false, "It spits sparks. Shorted out." end
    if LC.PlayerIsCP(ply) then
        return true, string.format("Power bank: %s. Feeding %d turret%s and %d forcefield%s (it can feed %d).", LC.PowerBankLive(b) and "live" or "DEAD (no power)",
            turrets, turrets == 1 and "" or "s", fields, fields == 1 and "" or "s", cvLoads:GetInt())
    end
    return false, LC.PowerBankLive(b) and "It hums. A Combine power bank." or "Dead. No power."
end

-- A multitool: eight seconds, and it's dead for two minutes, with everything on its cables.
function LC.ShortPowerBank(ply, b)
    if not LC.CanHack or not LC.CanHack(ply) then return false, "You need a multitool." end
    if not IsValid(b) or b:GetClass() ~= "lc_powerbank" then return false, "Look at a power bank." end
    if not LC.PowerBankLive(b) then return false, "It's already dead." end
    return LC.StartTask(ply, 8, "Shorting the power bank...", {
        maxMove = 40, cancelText = "You pull your hands back.",
        done = function(p)
            if not IsValid(b) then return end
            b:SetNW2Float("lc_short_until", CurTime() + 120)
            b:EmitSound("ambient/energy/zap9.wav", 80)
            if EffectData then
                local fx = EffectData()
                fx:SetOrigin(b:WorldSpaceCenter())
                util.Effect("Sparks", fx, true, true)
            end
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then LC.ReportCrime(p, "Sabotage", 240) end
            if p:GetNW2String("lcf_faction", "") == "resistance" and LC.AddXP then LC.AddXP(p, 10, "a checkpoint") end
            LC.CheckpointTick(CurTime())
            hook.Run("LivingCityPowerBankShorted", b, p)
        end,
    })
end

-- Only units handle turrets: nobody else picks one up, carries it off or knocks it over by hand.
hook.Add("PlayerUse", "LivingCityTurrets", function(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= TURRET or not ent.lcTurret then return end
    if (ply.lcTurretUseNext or 0) > CurTime() then return false end
    ply.lcTurretUseNext = CurTime() + 0.6
    if LC.PlayerIsCP(ply) and LC.DeployedTurrets[ent] then
        local _, msg = LC.PackTurret(ply, ent)
        if msg then ply:ChatPrint(msg) end
    end
    return false
end)
local function UnitsOnly(ply, ent)
    if IsValid(ent) and ent.lcTurret and not LC.PlayerIsCP(ply) then return false end
end
hook.Add("GravGunPickupAllowed", "LivingCityTurrets", UnitsOnly)
hook.Add("GravGunPunt", "LivingCityTurrets", UnitsOnly)

hook.Add("PlayerDisconnected", "LivingCityCheckpoints", function(ply)
    for t, o in pairs(LC.DeployedTurrets) do if o == ply then if IsValid(t) then t:Remove() end LC.DeployedTurrets[t] = nil end end
    for b, o in pairs(LC.DeployedBanks) do if o == ply then if IsValid(b) then b:Remove() end LC.DeployedBanks[b] = nil end end
end)

-- The actions menu: deploy, pack up, put up a bank, take it down, short one out.
function LC.CheckpointAction(ply, what, target)
    local ok, why
    if what == "turret" then ok, why = LC.DeployTurret(ply)
    elseif what == "pack" then ok, why = LC.PackTurret(ply, target)
    elseif what == "bank" then ok, why = LC.DeployPowerBank(ply)
    elseif what == "packbank" then ok, why = LC.PackPowerBank(ply, target)
    elseif what == "short" then
        if IsValid(target) and target:GetPos():DistToSqr(ply:GetPos()) < 200 * 200 then ok, why = LC.ShortPowerBank(ply, target) end
    elseif what == "status" then
        if IsValid(target) and target:GetClass() == "lc_powerbank" then ok, why = LC.UsePowerBank(ply, target) end
    end
    if why then ply:ChatPrint(why) end
    return ok
end

------------------------------------------------------------------------
-- Forcefields under attack: strength that recharges, overwhelmed, broken
------------------------------------------------------------------------

local ZOMBIE_PUSH = 6     -- strength a second each infected leaning on it takes off
local OVERWHELM_WINDOW = 300

local function FFUp(f) return FieldUp(f) and not f:GetNW2Bool("lc_ff_broken", false) end

local function FFInit(f)
    if f.lcHP then return end
    f.lcHP, f.lcLastHit, f.lcOverwhelms = cvFFHP:GetFloat(), 0, {}
    f:SetNW2Int("lc_ff_hpmax", cvFFHP:GetInt())
    f:SetNW2Int("lc_ff_hp", cvFFHP:GetInt())
end

local function Techs()
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        local job = LC.Job and LC.Job(p)
        if job and job.id == "maintenance" then out[#out + 1] = p end
    end
    return out
end

function LC.ForcefieldBreak(f)
    if not IsValid(f) or f:GetNW2Bool("lc_ff_broken", false) then return end
    f:SetNW2Bool("lc_ff_broken", true)
    f:SetNW2Float("lc_short_until", CurTime() + 1e6)
    f.lcBrokenAt = CurTime()
    f.lcHP = 0
    f:SetNW2Int("lc_ff_hp", 0)
    if LC.FieldRulesChanged then LC.FieldRulesChanged(f) end
    f:EmitSound("ambient/energy/powerdown2.wav", 85)
    if EffectData then local fx = EffectData() fx:SetOrigin(f:WorldSpaceCenter()) fx:SetMagnitude(4) util.Effect("Sparks", fx, true, true) end
    local where = Where(f:GetPos())
    for _, p in ipairs(Techs()) do
        if LC.Notice then LC.Notice(p, "warn", "A forcefield is broken", "The forcefield " .. where .. " is broken. E on it to repair it (ten seconds, paid).", 8) end
    end
    for _, p in ipairs(player.GetAll()) do if LC.PlayerIsCP(p) then p:ChatPrint("[CP net] The forcefield " .. where .. " is broken. Maintenance has been told.") end end
    hook.Run("LivingCityForcefieldBroken", f)
end

function LC.ForcefieldRepaired(f, ply)
    if not IsValid(f) then return end
    f:SetNW2Bool("lc_ff_broken", false)
    f:SetNW2Float("lc_short_until", 0)
    f.lcHP, f.lcOverwhelms, f.lcBrokenAt = cvFFHP:GetFloat(), {}, nil
    f:SetNW2Int("lc_ff_hp", cvFFHP:GetInt())
    if LC.FieldRulesChanged then LC.FieldRulesChanged(f) end
    f:EmitSound("ambient/machines/thumper_startup1.wav", 70)
    if IsValid(ply) then
        if LC.AddCredits then LC.AddCredits(ply, 15, "Forcefield repaired") end
        if LC.Notice then LC.Notice(ply, "info", "Forcefield repaired", "It hums back up. 15 credits.", 5) end
    end
end

-- Overwhelmed: offline for a while; too often, and it breaks.
local function Overwhelm(f, now)
    local keep = {}
    for _, t in ipairs(f.lcOverwhelms) do if now - t < OVERWHELM_WINDOW then keep[#keep + 1] = t end end
    keep[#keep + 1] = now
    f.lcOverwhelms = keep
    if #keep >= cvFFBreak:GetInt() then return LC.ForcefieldBreak(f) end
    f:SetNW2Float("lc_short_until", now + cvFFDown:GetFloat())
    f.lcHP = 0
    if LC.FieldRulesChanged then
        LC.FieldRulesChanged(f)
        timer.Simple(cvFFDown:GetFloat() + 0.05, function() if IsValid(f) then LC.FieldRulesChanged(f) end end)
    end
    f:EmitSound("ambient/energy/zap9.wav", 85)
    if EffectData then local fx = EffectData() fx:SetOrigin(f:WorldSpaceCenter()) util.Effect("Sparks", fx, true, true) end
    hook.Run("LivingCityForcefieldOverwhelmed", f)
end

function LC.ForcefieldHurt(f, amount, blast)
    if not IsValid(f) or amount <= 0 then return end
    FFInit(f)
    local now = CurTime()
    if not FFUp(f) then
        -- blown up while it's down: that's it broken
        if blast and amount >= 100 and not f:GetNW2Bool("lc_ff_broken", false) and f:GetNW2Float("lc_short_until", 0) > now then LC.ForcefieldBreak(f) end
        return
    end
    f.lcHP = f.lcHP - amount * (blast and 1.5 or 1)
    f.lcLastHit = now
    if f.lcHP <= 0 then Overwhelm(f, now) end
    f:SetNW2Int("lc_ff_hp", math.max(0, math.floor(f.lcHP)))
end

hook.Add("EntityTakeDamage", "LivingCityForcefieldHurt", function(ent, dmg)
    if not IsValid(ent) or ent:GetClass() ~= "lc_forcefield" then return end
    LC.ForcefieldHurt(ent, dmg:GetDamage(), dmg:IsDamageType(DMG_BLAST))
    return true
end)

-- The infected leaning on it.
local function Leaning(f)
    local n = 0
    local w, h = (f.HalfWidth or 64) + 20, f.Height or 112
    local function Near(pos)
        local l = f:WorldToLocal(pos)
        return math.abs(l.x) < 60 and math.abs(l.y) < w and l.z > -20 and l.z < h
    end
    local c = f:GetPos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "zombie" and npc:GetPos():DistToSqr(c) < 300 * 300 and Near(npc:GetPos()) then n = n + 1 end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.PlayerIsZombie and LC.PlayerIsZombie(p) and p:GetPos():DistToSqr(c) < 300 * 300 and Near(p:GetPos()) then n = n + 1 end
    end
    return n
end
LC.ForcefieldLeaning = Leaning

local FF_DT = 0.5
function LC.ForcefieldTick(now)
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do
        FFInit(f)
        if f:GetNW2Bool("lc_ff_broken", false) then
            -- (the city's maintenance crews normally get there first: the task at the end)
            if now - (f.lcBrokenAt or now) > cvFFFix:GetFloat() * 60 then
                LC.ForcefieldRepaired(f, nil)
                for _, p in ipairs(player.GetAll()) do if LC.PlayerIsCP(p) then p:ChatPrint("[CP net] City crews have repaired the forcefield " .. Where(f:GetPos()) .. ".") end end
            end
        elseif FFUp(f) then
            if f.lcHP <= 0 then f.lcHP = cvFFHP:GetFloat() * 0.4 end -- (back from being overwhelmed, not fully charged)
            local n = Leaning(f)
            if n > 0 then LC.ForcefieldHurt(f, n * ZOMBIE_PUSH * FF_DT, false) end
            if n == 0 and now - f.lcLastHit > 3 then f.lcHP = math.min(cvFFHP:GetFloat(), f.lcHP + cvFFRegen:GetFloat() * FF_DT) end
            f:SetNW2Int("lc_ff_hp", math.max(0, math.floor(f.lcHP)))
            f:SetNW2Int("lc_ff_hpmax", cvFFHP:GetInt())
        end
    end
end

timer.Create("LivingCityForcefieldHealth", FF_DT, 0, function()
    local ok, err = pcall(LC.ForcefieldTick, CurTime())
    if not ok and LC.Error then LC.Error("forcefield health", err) end
end)

-- E on a broken one: a Maintenance Technician repairs it.
function LC.RepairForcefield(ply, f)
    if not IsValid(f) or not f:GetNW2Bool("lc_ff_broken", false) then return false end
    local job = LC.Job and LC.Job(ply)
    if not (job and job.id == "maintenance") then return false, "It's broken: sparks and a dead hum. A Maintenance Technician could fix it." end
    if not LC.StartTask then LC.ForcefieldRepaired(f, ply) return true end
    return LC.StartTask(ply, 10, "Repairing the forcefield...", {
        maxMove = 60, cancelText = "You leave it half done.",
        done = function(p) if IsValid(f) then LC.ForcefieldRepaired(f, p) end end,
    })
end

-- The city's own maintenance crews walk out and repair a broken forcefield
-- (after the players have had their chance); the timer above is only for a
-- city with no crew to send.
if LC.AddNPCTask then
    LC.AddNPCTask("maintenance", { id = "forcefield", label = "repairing a forcefield", urgent = true, find = function(npc, st, now)
        local grace = LC.NPCWorkGrace and LC.NPCWorkGrace("maintenance") or 60
        local best, bd
        for _, f in ipairs(LC.EntsOf("lc_forcefield")) do
            if f:GetNW2Bool("lc_ff_broken", false) and now - (f.lcBrokenAt or now) >= grace and not (LC.NPCWorkClaimed and LC.NPCWorkClaimed("field" .. f:EntIndex())) then
                local d = f:GetPos():DistToSqr(npc:GetPos())
                if d < 5000 * 5000 and (not bd or d < bd) then best, bd = f, d end
            end
        end
        if not best then return nil end
        local f = best
        return { key = "field" .. f:EntIndex(), steps = {
            { pos = function(n) return LC.NPCWorkBeside(f:GetPos(), n:GetPos(), 70) end, face = function() return f:WorldSpaceCenter() end,
              check = function() return IsValid(f) and f:GetNW2Bool("lc_ff_broken", false) end,
              secs = 10, anim = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" },
              sound = { "ambient/energy/spark1.wav", "ambient/energy/spark2.wav", "ambient/energy/spark3.wav" }, doing = "repairing a forcefield",
              done = function() LC.ForcefieldRepaired(f, nil) end },
        } }
    end })
end
