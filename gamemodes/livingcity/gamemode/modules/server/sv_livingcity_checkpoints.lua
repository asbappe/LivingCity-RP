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

-- Whether a forcefield has power: off its bank if it has one, else its district.
-- (sv_livingcity_power.lua asks this for every forcefield.)
function LC.FieldOff(f)
    local b = LC.BankFor(f:GetPos())
    if IsValid(b) then return not LC.PowerBankLive(b) end
    return LC.PowerDarkAt and LC.PowerDarkAt(f:GetPos()) or false
end

-- What a turret's cable runs to: a bank, else a forcefield.
function LC.TurretSource(t)
    local p, r = t:GetPos(), cvRange:GetFloat()
    return Nearest("lc_powerbank", p, r) or Nearest("lc_forcefield", p, r)
end
local function SourceLive(s)
    if not IsValid(s) then return false end
    if s:GetClass() == "lc_powerbank" then return LC.PowerBankLive(s) end
    return FieldUp(s)
end

-- The city's turrets: the editor's and the ones units put up (not whatever else the map has).
local function Turrets()
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
    -- forcefields: a bank's short comes and goes
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do
        local off = LC.FieldOff(f)
        if f:GetNW2Bool("lc_nopower", false) ~= off then
            f:SetNW2Bool("lc_nopower", off)
            if LC.FieldRulesChanged then LC.FieldRulesChanged(f) end
        end
        local b = LC.BankFor(f:GetPos())
        if f:GetNW2Entity("lc_cable") ~= (b or NULL) then f:SetNW2Entity("lc_cable", b or NULL) end
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
    local src = Nearest("lc_powerbank", pos, r) or Nearest("lc_forcefield", pos, r)
    if not src then
        return false, "No power here: turrets go up at a checkpoint, near a Combine power bank or a forcefield."
    end
    local n = 0
    for _, t in ipairs(Turrets()) do if LC.TurretSource(t) == src then n = n + 1 end end
    if n >= cvPerPost:GetInt() then return false, "That checkpoint is powering all the turrets it can." end
    local t = SpawnTurret(pos, Angle(0, ply:EyeAngles().y, 0))
    if not IsValid(t) then return false, "The turret won't deploy." end
    LC.DeployedTurrets[t] = ply
    t.lcDeployedBy = ply
    ply.lcTurretNext = CurTime() + 5
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
        return false, "Officers put up power banks (OfC and up). Any unit can deploy turrets at one."
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
    for _, f in ipairs(LC.EntsOf("lc_forcefield")) do if LC.BankFor(f:GetPos()) == b then fields = fields + 1 end end
    if b:GetNW2Float("lc_short_until", 0) > CurTime() then return false, "It spits sparks. Shorted out." end
    if LC.PlayerIsCP(ply) then
        return true, string.format("Power bank: %s. Feeding %d turret%s and %d forcefield%s.", LC.PowerBankLive(b) and "live" or "DEAD (no power)",
            turrets, turrets == 1 and "" or "s", fields, fields == 1 and "" or "s")
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
