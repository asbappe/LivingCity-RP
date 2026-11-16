--[[
    Living City: the Administrator's security (the owner, 15 November)

    A grenade thrown at her, at an address or anywhere in the city: the Combine
    soldier nearest it throws himself on it ("SHIT"), the others call it
    ("BOUNCER"), and it goes off under him: a blast that hurts nobody, except
    that it kills him and throws what is left of him. The owner: "a combine
    soldier nearest any grenade thrown at the administrator to leap onto the
    grenade as a ragdoll (throw themselves on the grenade) yelling the combine
    SHIT line and others yelling BOUNCER ... a harmless explosion that doesn't
    hurt anyone except kill the combine that jumped on the grenade. The
    jumper's corpse flying is a bonus."

    Her address's own guards (the row of three in front of the stand, and the
    detail round her within 20 feet) are in sv_livingcity_speech.lua.

    An attempt on her life at her address (the owner, 15 November: "get the
    administrator out ASAP, as in like within 1 second if someone tries to
    kill them ... an APC point/entity and the administrator is thrown into the
    APC? It spawns just for speeches?"; then "just do the APC escort"):
      - an APC stands at the editor's "Point: Administrator's APC" nearest the
        stand (within 2000 units) for as long as the address lasts;
      - she is shot at (or a grenade lands by her): within a second she can no
        longer be hurt and is held in a crouch, a Combine glass screen stands
        between the stand and the crowd, every guard of the address (the row,
        the detail, her own elites) closes into a ring round her facing out,
        the address is over, the attackers are wanted and the city locks down;
      - the ring runs her to the APC, moved by script so nothing stops them
        (straight through anything in the way), she is put in, it drives off
        the way its point faces and she is set down at her desk;
      - her guards' fire hurts only the attackers.
    A player Administrator can be killed by the first shot (the assassin's one
    chance); the city's own at her address is never hurt, only carried out.
    With no APC point by the stand, the shield run (the owner, 15 November:
    "ALL the combine forming a shield around her back to her office ...
    literally unstoppable ... never stop moving"): the ring, her guards and
    every Combine NPC of the city within 1200 units of the stand, or of the
    shell as it passes, run her to the editor's Administrator's desk point at
    450 units a second, as one body moved by script along the city's own
    routes (straight there where they have none): through doors (opened ahead
    of them where they may be), walls, props and people, legs running, firing
    at any marked attacker in sight within 1500 units. At her desk she is set
    down, the address's guards fight on thirty seconds and go, the city's
    units get back what was changed on them and return to their beats.
    With no desk point either: the ring and the screen for twelve seconds.

    What sets it off (the owner, 15 November: "any bullet or projectile landing
    within 20 feet of obviously hitting her counts"): a hit on her; a bullet
    from anyone not of the Combine that lands within 320 units of her or passes
    that near her; a bolt, rocket, energy ball or grenade that comes that near.
    One of the Combine's own (the owner, 16 November: "what if the insider
    attempts it? or even a metrocop or combine unit gone rogue? ... it would
    only count if the bullet actually hit the administrator by them"): a unit
    player's near miss is nothing; their hit on her at her address is an
    attempt like anyone's, and they are thrown out of the Combine first, the
    way a caught Insider is (LC.BurnInsider), then marked. While her guards
    have her, a unit player's second hit on her within ten seconds does the
    same. Their grenade by her: the first in sixty minutes is let off, a
    second makes them a traitor (smoke and a flash never count). A Combine
    NPC never counts. Only a grenade that explodes is jumped on: a firebomb,
    gas, smoke or a flash is left to do what it does.
    The hit itself is a close call, never a kill ("make it a close call, but
    she is still escorted all the same"), and uses one of her close calls up
    (the owner, 16 November: "it should use up a close call, just please make
    sure the player is aware of that when and after it happens"): she is told
    at the hit; set down in her office, between its door and her desk, she
    faints, her screen goes dark, she is told how many are left, a medic of
    the city's heals her and leaves by the office door, opened for them once.
    With none left the hit stands. Where close calls are not counted
    (lc_close_calls 0, lc_permadeath 0) she simply lives.

    Whoever does it ("wanted as the most egregious violation, instant -999
    standing, crime never forgotten for that character"): Civil Standing set
    to -999 at once, wanted for attempted murder of the City Administrator
    (the longest sentence there is), and it is kept with the character: free,
    they are wanted for the rest of that character's life (a new character
    starts clean; staff wiping a record forgets it).

    Keep back ("anyone attempting to walk up to her is warned once and killed
    if they get too close"): at her address a player not of the Combine, or one
    of the Resistance's fighters, who comes inside the warning line hears one
    "final warning" from the nearest guard; inside the inner line her guards
    shoot them until they are dead. Staff in build mode, anyone in custody and
    the city's own citizens are left alone.

    After it (the owner, 16 November: "an administrator announcement response
    to the assassination attempt and as lines for her next speech"; "20 seconds
    is way too soon; it should be like 3-5 minutes"): three to five minutes
    later the city hears of it (the announcement "attempt": hers with
    nobody playing her, Overwatch's with a player in the post), and it is kept
    with the state of the city until her next address of her own, which is
    then all about it (LC.SpeechPieces, the attempt_ pieces): whether a soldier
    died on the grenade, and whether the attacker is dead or in the cells by
    then.

    lc_admin_grenade_jump 1/0, lc_admin_exfil 1/0, lc_speech_keepback 1/0
    Hooks: LivingCityAdminAttempt (her, who, how): someone tried to kill her.
           LivingCityAdminExfil (her, who): her guards are getting her out.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvJump = CreateConVar("lc_admin_grenade_jump", "1", FLAGS, "A grenade thrown at the Administrator: the nearest Combine soldier throws himself on it, and it hurts nobody else (0: off)")

local NEAR_HER = 450 -- a grenade this near her is one thrown at her
local REACH = 600    -- a soldier this near the grenade can get to it
local SLOW = 350     -- it has landed (or nearly): slower than this, or in the air longer than AIR seconds
local AIR = 0.6
local SHIT = "npc/metropolice/vo/shit.wav"
local BOUNCER = "npc/combine_soldier/vo/bouncerbouncer.wav"
local GRENADES = { npc_grenade_frag = true, lc_grenade = true }
-- (what counts as shot at her without hitting: these coming within NEAR_MISS of her)
local PROJECTILES = { npc_grenade_frag = true, lc_grenade = true, crossbow_bolt = true, rpg_missile = true, grenade_ar2 = true, prop_combine_ball = true }
local NEAR_MISS = 320 -- 20 feet

local watch = {} -- [grenade] = when it was thrown
LC.AdminGrenades = watch

local function Thrower(g)
    if IsValid(g.lcOwner) then return g.lcOwner end
    local t = g.GetInternalVariable and g:GetInternalVariable("m_hThrower")
    if IsValid(t) then return t end
    local o = g.GetOwner and g:GetOwner()
    return IsValid(o) and o or nil
end

-- The Combine's own don't throw grenades at her: one of theirs landing by her is left to go off as it would.
local function Theirs(who)
    if not IsValid(who) then return false end
    if who:IsPlayer() then return (LC.PlayerIsCP and LC.PlayerIsCP(who)) or (LC.IsAdministrator and LC.IsAdministrator(who)) or false end
    local st = LC.NPCs and LC.NPCs[who]
    return st ~= nil and LC.IsSecurity ~= nil and LC.IsSecurity(st) == true
end

-- Her, if this spot is within reach of her: a player Administrator, or the city's own at her address.
local function Her(pos)
    for _, p in ipairs(player.GetAll()) do
        if LC.IsAdministrator and LC.IsAdministrator(p) and p:Alive() and p:GetPos():DistToSqr(pos) < NEAR_HER * NEAR_HER then return p end
    end
    local S = LC.SpeechSession and LC.SpeechSession()
    if S and IsValid(S.her) and S.her:GetPos():DistToSqr(pos) < NEAR_HER * NEAR_HER then return S.her end
    return nil
end

-- One of the Combine's own, a player, who turns on her (the owner, 16 November: "what if the insider attempts
-- it? or even a metrocop or combine unit gone rogue? (both of these by a human player obviously) I guess for
-- these it would only count if the bullet actually hit the administrator by them"): thrown out of the Combine
-- the way a caught Insider is (LC.BurnInsider, sv_livingcity_insider.lua: out of the system for good, the
-- Resistance's from then on, wanted for treason, the dispatch on the units' radio), an Insider and any other
-- unit alike. From then on they are no longer one of theirs: they can be marked for the attempt, and her guards
-- fire on them. True when who may be marked now (never one of theirs, or just thrown out).
local function Turn(who)
    if not IsValid(who) then return false end
    if not Theirs(who) then return true end
    if not who:IsPlayer() or (LC.IsAdministrator and LC.IsAdministrator(who)) or not LC.BurnInsider then return false end
    LC.Try(LC.BurnInsider, who, not (LC.IsInsider and LC.IsInsider(who))) -- (a unit who was never the Insider is told so in words that are true)
    return not Theirs(who)
end
LC.AdminTurn = Turn
-- Whoever tried: marked for it (standing -999, wanted, never forgotten), and at her address her guards get her out.
local function Attempted(her, who, how)
    if LC.AdminAttacker then LC.AdminAttacker(who) end
    hook.Run("LivingCityAdminAttempt", her, who, how)
end

-- Which grenades a soldier throws himself on: the ones that explode (the owner, 16 November: "firebombs nor
-- poison gas grenades, someone jumping on those doesn't really do anything since it's not an explosion").
-- Half-Life 2's frag grenade, and any kind of the gamemode's own that is not one of these.
local NO_BLAST = { smoke = true, flash = true, gas = true, fire = true }
local COVER = { smoke = true, flash = true } -- (units use these for cover: never held against them)
local function Explosive(g)
    local cls = g:GetClass()
    return cls == "npc_grenade_frag" or (cls == "lc_grenade" and not NO_BLAST[g.lcKind or "smoke"])
end
LC.AdminGrenadeExplosive = Explosive

-- A unit player's grenade by her (the owner, 16 November: "make it so one grenade is an exception (one every 60
-- minutes), but a second triggers the assassin designation for the thrower"): the first in sixty minutes is let
-- off; a second from the same player within sixty minutes of it makes them a traitor. A frag, a firebomb and gas
-- count; smoke and a flash never. Each grenade is counted once. True when this one is the second.
local GRENADE_GRACE = 3600
local function UnitPlayer(who)
    return IsValid(who) and who:IsPlayer() and Theirs(who) and not (LC.IsAdministrator and LC.IsAdministrator(who))
end
local function UnitGrenade(who, g, now)
    if g.lcAdminCounted then return false end
    g.lcAdminCounted = true
    if g:GetClass() == "lc_grenade" and COVER[g.lcKind or "smoke"] then return false end
    local first = who.lcAdminGrenadeAt
    if first and now - first < GRENADE_GRACE then return true end
    who.lcAdminGrenadeAt = now
    return false
end

-- The one who goes: the nearest soldier within reach (a Civil Protection unit only with no soldier there).
local function Jumper(at)
    local best, bd, bestCop, cd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and LC.IsSecurity(st) and not npc.lcGrenadeJumper then
            local d = npc:GetPos():DistToSqr(at)
            if d < REACH * REACH then
                if npc:GetClass() == "npc_combine_s" then
                    if not bd or d < bd then best, bd = npc, d end
                elseif not cd or d < cd then
                    bestCop, cd = npc, d
                end
            end
        end
    end
    return best or bestCop
end

-- It goes off under him: the look and the noise of it, and no harm to anyone. What is left of him is thrown.
local function Boom(g, rag, at)
    if IsValid(g) then
        at = g:GetPos()
        g:Remove()
    end
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(at)
        util.Effect("Explosion", fx, true, true)
    end
    if sound and sound.Play then sound.Play("weapons/explode" .. math.random(3, 5) .. ".wav", at, 100, 100, 1) end
    if util.ScreenShake then util.ScreenShake(at, 8, 150, 1, 700) end
    if util.Decal then util.Decal("Scorch", at + Vector(0, 0, 8), at - Vector(0, 0, 24)) end
    if IsValid(rag) and rag.GetPhysicsObjectCount then
        local kick = Vector(math.Rand(-160, 160), math.Rand(-160, 160), math.Rand(480, 680))
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local ph = rag:GetPhysicsObjectNum(i)
            if IsValid(ph) then
                ph:Wake()
                ph:SetVelocity(kick + Vector(math.Rand(-60, 60), math.Rand(-60, 60), math.Rand(-40, 80)))
                if ph.AddAngleVelocity then ph:AddAngleVelocity(Vector(math.Rand(-400, 400), math.Rand(-400, 400), math.Rand(-400, 400))) end
            end
        end
    end
    hook.Run("LivingCityGrenadeSmothered", at, rag)
end

-- He throws himself on it. True when he did.
function LC.GrenadeJump(npc, g, her)
    if not (IsValid(npc) and IsValid(g)) or g.lcJumped then return false end
    g.lcJumped = true
    npc.lcGrenadeJumper = true
    local from, at = npc:GetPos(), g:GetPos()
    local who = Thrower(g)
    npc:EmitSound(SHIT, 95, 100)
    -- the others call it
    local called = 0
    for other, st in pairs(LC.NPCs or {}) do
        if called < 2 and other ~= npc and IsValid(other) and other:Health() > 0 and LC.IsSecurity(st) and other:GetPos():DistToSqr(at) < 900 * 900 then
            called = called + 1
            local o = other
            timer.Simple(0.15 * called, function() if IsValid(o) then o:EmitSound(BOUNCER, 90, 100) end end)
        end
    end
    -- it no longer goes off by itself (it goes off under him, below)
    g.lcDone = true -- (lc_grenade: entities/lc_grenade.lua)
    if g:GetClass() == "npc_grenade_frag" and g.Fire then g:Fire("SetTimer", "30") end
    local gp = g.GetPhysicsObject and g:GetPhysicsObject()
    if IsValid(gp) then gp:SetVelocity(Vector(0, 0, 0)) end
    -- down on it, limp
    local t = math.Clamp(from:Distance(at) / 750, 0.25, 0.55)
    local rag = ents.Create("prop_ragdoll")
    if IsValid(rag) then
        rag:SetModel(npc:GetModel() or "models/combine_soldier.mdl")
        rag:SetPos(from)
        rag:SetAngles(npc:GetAngles())
        if npc.GetSkin and rag.SetSkin then rag:SetSkin(npc:GetSkin() or 0) end
        rag:Spawn()
        if rag.Activate then rag:Activate() end
        if rag.SetCollisionGroup then rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS or 1) end -- (nobody trips over him)
        local v = (at - from) * (1 / t) + Vector(0, 0, 0.5 * 600 * t + 40)
        if rag.GetPhysicsObjectCount then
            for i = 0, rag:GetPhysicsObjectCount() - 1 do
                local ph = rag:GetPhysicsObjectNum(i)
                if IsValid(ph) then
                    -- (as he stood, limb for limb, where the model lets us)
                    local bone = rag.TranslatePhysBoneToBone and rag:TranslatePhysBoneToBone(i)
                    local bp, ba
                    if bone and npc.GetBonePosition then bp, ba = npc:GetBonePosition(bone) end
                    if bp and ba then ph:SetPos(bp) ph:SetAngles(ba) end
                    ph:Wake()
                    ph:SetVelocity(v)
                end
            end
        end
        if SafeRemoveEntityDelayed then SafeRemoveEntityDelayed(rag, 90) end
    end
    npc:Remove()
    LC.AdminHeroAt = CurTime() -- (a soldier died for her: her next address says so)
    local pend = LC.AdminAttemptPending and LC.AdminAttemptPending()
    if pend then pend.hero = true end
    timer.Simple(t + 0.2, function() Boom(g, rag, at) end)
    -- an attempt on her life, whoever threw it. One of the Combine's own, a player: smothered all the same, the
    -- first in sixty minutes let off, a second making them a traitor (thrown out, then marked like anyone).
    if IsValid(who) and Theirs(who) then
        if UnitPlayer(who) and UnitGrenade(who, g, CurTime()) and Turn(who) then Attempted(her, who, "grenade") end
    else
        Attempted(her, who, "grenade")
    end
    return true
end

function LC.AdminGrenadeWatch(g)
    if IsValid(g) and PROJECTILES[g:GetClass()] then watch[g] = CurTime() end
end
hook.Add("OnEntityCreated", "LivingCityAdminGrenade", function(e)
    if not IsValid(e) or not PROJECTILES[e:GetClass()] then return end
    watch[e] = CurTime()
end)

local function Landed(g, now, since)
    local vel = g.GetVelocity and g:GetVelocity() or Vector(0, 0, 0)
    return vel:Length() < SLOW or now - since > AIR
end

-- Each grenade in the air or on the ground: an explosive one by her, landed, and not a Combine NPC's: somebody goes.
function LC.AdminGrenadeThink(now)
    for g, since in pairs(watch) do
        if not IsValid(g) or g.lcJumped or now - since > 12 then
            watch[g] = nil
        elseif not GRENADES[g:GetClass()] or not cvJump:GetBool() or not Explosive(g) then
            -- a bolt, a rocket, an energy ball, or a grenade nobody jumps on (a firebomb, gas, smoke or a flash, left
            -- to do what it does; any grenade with the jump off): near her at her address it is an attempt, from
            -- anyone not of the Combine. A unit player's by her counts toward their one in sixty minutes.
            local who = Thrower(g)
            if LC.AdminNearMiss and LC.AdminNearMiss(g:GetPos(), who) then
                watch[g] = nil
            elseif GRENADES[g:GetClass()] and not g.lcAdminCounted and UnitPlayer(who) and now - since > 0.15 and Landed(g, now, since) then
                local her = Her(g:GetPos())
                if her and UnitGrenade(who, g, now) and Turn(who) then Attempted(her, who, "grenade") end
            end
        elseif now - since > 0.15 then
            local at = g:GetPos()
            if Landed(g, now, since) then
                -- (whoever threw it, a Combine player too: the owner, 16 November, "no matter who threw it, because all
                -- grenades should do damage to her". Not a Combine NPC's: those cannot hurt her at all, "NPC
                -- combine/overwatch/CP grenades should not hurt her", LC.AdministratorImmune.)
                local her = Her(at)
                local who = Thrower(g)
                if her and not (IsValid(who) and who:IsNPC() and Theirs(who)) then
                    local npc = Jumper(at)
                    if npc then LC.GrenadeJump(npc, g, her) end
                end
            end
        end
    end
end
local nextLook = 0
hook.Add("Think", "LivingCityAdminGrenade", function()
    if next(watch) == nil then return end
    local now = CurTime()
    if now < nextLook then return end
    nextLook = now + 0.1
    local ok, err = LC.Try(LC.AdminGrenadeThink, now)
    if not ok and LC.Error then LC.Error("admin grenade", err) end
end)

------------------------------------------------------------------------
-- Whoever tries to kill her: the worst crime there is, and never forgotten
------------------------------------------------------------------------

local CRIME = "Attempted murder of the City Administrator"
LC.AdminCrime = CRIME

-- Who her guards' fire may hurt (attackers, and whoever came too close): nobody else, ever.
LC.AdminTargets = LC.AdminTargets or setmetatable({}, { __mode = "k" })

function LC.AdminNeverForgotten(ply)
    return IsValid(ply) and ply:IsPlayer() and ply.GetPData ~= nil and (ply:GetPData("lc_regicide", "") or "") ~= ""
end
function LC.AdminForget(ply)
    if not IsValid(ply) or not ply.RemovePData then return end
    ply:RemovePData("lc_regicide")
    ply:SetNW2Bool("lc_regicide", false)
end
-- Civil Standing to -999 at once, wanted for it, and it is kept with the character. True when it was a player's doing.
function LC.AdminAttacker(who)
    if not (IsValid(who) and who:IsPlayer()) or Theirs(who) then return false end
    if who.SetPData then who:SetPData("lc_regicide", tostring(os.time())) end
    who:SetNW2Bool("lc_regicide", true)
    if LC.ReportCrime then LC.ReportCrime(who, CRIME, 3600) end
    -- (after the crime is booked, which costs standing of its own: -999 it is, whatever it was)
    if LC.AddStanding and LC.Standing then
        local st = LC.Standing(who)
        if st ~= -999 then LC.AddStanding(who, -999 - st, "an attempt on the Administrator's life") end
    end
    return true
end
-- Never forgotten: free, they are wanted, for as long as that character lives.
hook.Add("LivingCityIsWanted", "LivingCityAdminSecurity", function(ply)
    if not LC.AdminNeverForgotten(ply) then return end
    if (LC.InCustody and LC.InCustody(ply)) or (LC.HeldByCombine and LC.HeldByCombine(ply)) then return end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return end -- (made a stalker for it: the Combine's own property now)
    return true
end)
hook.Add("LivingCityNewCharacter", "LivingCityAdminSecurity", function(ply) LC.AdminForget(ply) end)
hook.Add("PlayerInitialSpawn", "LivingCityAdminSecurity", function(ply)
    timer.Simple(2, function() if IsValid(ply) then ply:SetNW2Bool("lc_regicide", LC.AdminNeverForgotten(ply)) end end)
end)

------------------------------------------------------------------------
-- An attempt on her life at her address: the ring, the screen, and out by APC
------------------------------------------------------------------------

local cvExfil = CreateConVar("lc_admin_exfil", "1", FLAGS, "An attempt on the Administrator's life at her address: her guards close round her and she is taken out by APC (the editor's Administrator's APC point, by the stand; 0: off)")

local APC_MODEL = "models/combine_apc.mdl"
local APC_YAW = -90      -- the model's nose against the way its point faces (to turn it: this number)
local APC_REACH = 2000   -- the APC point must be this near the stand
local RING = 52          -- how close they stand round her
local CLOSE_SECS = 0.8   -- the ring closes
local CARRY_SPEED = 450  -- units a second, to the APC (about five times a walk)
local GUARD_SPEED = 700  -- how fast a guard gets to his place in the ring
local DRIVE_SECS = 5     -- then the APC is gone and she is at her desk
local DRIVE_TOP = 620
local HOLD_SECS = 12     -- with no APC: the ring and the screen this long

local A -- the exit under way, or nil
function LC.AdminExfil() return A end
local StartRun, RunThink, EndRun -- (the shield run, further down)
local C -- her close call's scene under way (she faints, a medic sees to her), or nil
local Faint, OfficeDoor, OfficeSpot -- (that scene, further down)

-- What her next address will make of it: kept with the state of the city (LC.Ledger) until she has said it.
--   hero: a soldier died on a grenade for her; caught: the attacker is dead or in the cells; by: who (SteamID64s).
LC.AdminAnnounceAfter = { 180, 300 } -- (seconds after an attempt: somewhere between these)
function LC.AdminAttemptPending()
    local L = LC.Ledger and LC.Ledger()
    return L and L.attempt or nil
end
function LC.AdminAttemptSpoken()
    local L = LC.Ledger and LC.Ledger()
    if L then L.attempt = nil end
end
function LC.AdminAttemptRemember()
    local L = LC.Ledger and LC.Ledger()
    if not L then return nil end
    local a = L.attempt or { by = {} }
    a.by = a.by or {}
    a.t = os.time()
    a.caught = nil
    if LC.AdminHeroAt and CurTime() - LC.AdminHeroAt < 5 then a.hero = true end
    L.attempt = a
    return a
end
local function Caught(sid)
    local a = LC.AdminAttemptPending()
    if a and a.by and sid and a.by[tostring(sid)] then a.caught = true end
end
hook.Add("PlayerDeath", "LivingCityAdminAttempt", function(victim) if IsValid(victim) and victim.SteamID64 then Caught(victim:SteamID64()) end end)
hook.Add("LivingCityIncarcerated", "LivingCityAdminAttempt", function(ply) if IsValid(ply) and ply.SteamID64 then Caught(ply:SteamID64()) end end)
hook.Add("OnNPCKilled", "LivingCityAdminAttempt", function(npc)
    local a = LC.AdminAttemptPending()
    if a and IsValid(npc) and LC.AdminTargets[npc] then a.caught = true end
end)

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40))) or p end

local function ApcPoint(stand)
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("adminapc") or {}) do
        local d = p.pos:DistToSqr(stand)
        if d < APC_REACH * APC_REACH and (not bd or d < bd) then best, bd = p, d end
    end
    return best
end

-- The APC stands by for as long as she speaks.
hook.Add("LivingCitySpeechCalled", "LivingCityAdminSecurity", function(_, S)
    if not cvExfil:GetBool() or not (S and S.stand) then return end
    local p = ApcPoint(S.stand.pos)
    if not p or (util.IsValidModel and not util.IsValidModel(APC_MODEL)) then return end
    local apc = ents.Create("prop_dynamic")
    if not IsValid(apc) then return end
    apc:SetModel(APC_MODEL)
    apc:SetPos(Ground(p.pos))
    apc:SetAngles(Angle(0, (p.yaw or 0) + APC_YAW, 0))
    apc:Spawn()
    if apc.SetSolid then apc:SetSolid(SOLID_VPHYSICS or 6) end
    apc.lcDriveYaw = p.yaw or 0
    S.apc = apc
end)
hook.Add("LivingCitySpeechEnded", "LivingCityAdminSecurity", function(S)
    if S and IsValid(S.apc) and not (A and A.apc == S.apc) then S.apc:Remove() end
end)

-- The city's units go after him: all but those running her out (the shield run), who shoot from where they are.
local function Rouse(who)
    if not LC.MakeCopsHostile then return end
    local R = A.run
    if not R then
        LC.Try(LC.MakeCopsHostile, who, who:GetPos(), 2500)
        return
    end
    if not LC.MakeOneHostile or (LC.EditorHeld and LC.EditorHeld(who)) then return end
    local at = who:GetPos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and not R.set[npc] and LC.IsSecurity(st) and st.enemy ~= who and npc:GetPos():DistToSqr(at) < 2500 * 2500 then
            LC.Try(LC.MakeOneHostile, npc, st, who)
        end
    end
end

-- An attacker: wanted, and every one of her guards on him.
local function Mark(who)
    if not (A and IsValid(who)) or A.attackers[who] or Theirs(who) then return end
    A.attackers[who] = true
    LC.AdminTargets[who] = true
    if who:IsNPC() then who.lcRegicide = true end -- (put in a cell, it is hers to question, then a stalker: sv_livingcity_adminquestioning.lua)
    LC.AdminAttacker(who)
    local pend = LC.AdminAttemptPending()
    if pend and who:IsPlayer() and who.SteamID64 then pend.by[tostring(who:SteamID64())] = true end
    Rouse(who)
    for _, g in ipairs(A.guards) do
        if IsValid(g) then
            if g.AddEntityRelationship then g:AddEntityRelationship(who, D_HT or 1, 99) end
            if g.SetEnemy then g:SetEnemy(who) end
            if g.UpdateEnemyMemory then g:UpdateEnemyMemory(who, who:GetPos()) end
        end
    end
end

-- The screen between the stand and the crowd: three panes of the Combine's glass (entities/lc_adminglass.lua).
local function Screen(stand, crowd)
    local toward = crowd - stand
    toward.z = 0
    if toward:LengthSqr() < 1 then return end
    toward:Normalize()
    local side = Vector(-toward.y, toward.x, 0)
    local ang = Angle(0, math.deg(math.atan2(toward.y, toward.x)), 0)
    for k = -1, 1 do
        local g = ents.Create("lc_adminglass")
        if IsValid(g) then
            g:SetPos(Ground(stand + toward * 70 + side * (k * 180)))
            g:SetAngles(ang)
            g:Spawn()
            A.glass[#A.glass + 1] = g
        end
    end
    if A.glass[1] then A.glass[1]:EmitSound("ambient/machines/thumper_startup1.wav", 85, 140) end
end

local function Begin(S, her, who)
    local guards = LC.SpeechHandOver()
    for npc, admin in pairs(LC.AdminGuards or {}) do
        if admin == her and IsValid(npc) then
            guards[#guards + 1] = npc
            npc.lcExfilElite = true
        end
    end
    local now = CurTime()
    A = { her = her, attackers = {}, guards = guards, guardSet = {}, glass = {}, strays = {}, t0 = now, last = now, phase = "close",
          apc = IsValid(S.apc) and S.apc or nil, at = her:GetPos() }
    for _, g in ipairs(guards) do A.guardSet[g] = true end
    S.apc = nil
    if her:IsPlayer() then
        -- (the hit that set it off would have killed her: a close call, used up when she is set down)
        A.closeCall = (her.lcAdminCloseHit ~= nil and now - her.lcAdminCloseHit < 2) or nil
        her.lcAdminCloseHit = nil
        if her.GodEnable then her:GodEnable() end
        her:SetNW2Bool("lc_exfil", true)
    else
        her.lcExfilHer = true
    end
    Screen(S.stand.pos, S.crowd.pos)
    LC.EndSpeech() -- (the crowd is let go; the podium goes)
    LC.AdminAttemptRemember()
    -- (the city's own does not speak again today: her next address is tomorrow's)
    if LC.Ledger then LC.SpeechCityDay = LC.Ledger().day or 0 end
    Mark(who)
    -- her word to the city, once she is away (or Overwatch's, with a player in the post)
    timer.Simple(math.Rand(LC.AdminAnnounceAfter[1], LC.AdminAnnounceAfter[2]), function()
        if LC.TriggerAnnouncements then LC.Try(LC.TriggerAnnouncements, "attempt", { force = true }) end
    end)
    -- (no notice of its own: the screen, the gunfire, the APC and the lockdown's own call say it; house rule 10)
    if LC.StartEvent and (LC.Event == nil or LC.Event == "") then LC.Try(LC.StartEvent, "lockdown") end
    hook.Run("LivingCityAdminExfil", her, who)
end

-- Someone tried to kill her: at her address, her guards get her out. True when they are (or already were).
function LC.AdminAttempt(her, who, how)
    if A then
        Mark(who)
        return true
    end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not cvExfil:GetBool() or not S or not IsValid(her) then return false end
    if her ~= S.by and her ~= S.her then return false end
    Begin(S, her, who)
    return true
end
hook.Add("LivingCityAdminAttempt", "LivingCityAdminExfil", function(her, who, how) LC.AdminAttempt(her, who, how) end)

local function Done(deliver)
    local a = A
    if not a then return end
    A = nil
    EndRun(a) -- (the shield run: everyone gets back what was changed on him)
    for _, g in ipairs(a.glass) do if IsValid(g) then g:Remove() end end
    if IsValid(a.apc) then
        if a.apc.StopSound then a.apc:StopSound("vehicles/apc/apc_cruise_loop3.wav") end
        a.apc:Remove()
    end
    -- the address's own guards fight on a little, then go; her elites find her again by themselves
    for _, g in ipairs(a.guards) do
        if IsValid(g) and not g.lcExfilElite then
            if SafeRemoveEntityDelayed then SafeRemoveEntityDelayed(g, 30) else g:Remove() end
        end
        if IsValid(g) then g.lcExfilElite = nil end
    end
    local her = a.her
    if not IsValid(her) then return end
    if not her:IsPlayer() then
        her:Remove() -- (the city's own: away in the APC, or in her office)
        return
    end
    her:SetNW2Bool("lc_exfil", false)
    if her.SetNoDraw then her:SetNoDraw(false) end
    if her.SetNotSolid then her:SetNotSolid(false) end
    -- badly hit when it began (a close call): where she is set down she faints, and a medic sees to her
    local fainting = a.closeCall and her:Alive()
    local door
    if deliver then
        local desk = LC.PointsOfKind and LC.PointsOfKind("desk")[1]
        local to = desk and desk.pos or a.at
        if fainting and desk then -- (inside her office, between its door and her desk)
            door = OfficeDoor(desk.pos)
            if door then to = OfficeSpot(door, desk.pos) end
        end
        her:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(to + Vector(0, 0, 8))) or to)
        -- (out of the APC her screen comes up from black; run there, she saw the way)
        if her.ScreenFade and not a.ran and not fainting then her:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(0, 0, 0, 255), 1.5, 0.3) end
        hook.Run("LivingCityAdminMoved", her, to)
    end
    if fainting then return Faint(her, door) end -- (nothing can hurt her until that is over)
    -- (a few seconds more before anything can hurt her again)
    timer.Simple(4, function() if IsValid(her) and her.GodDisable and not (A and A.her == her) then her:GodDisable() end end)
end
LC.AdminExfilEnd = Done

-- Guard k of n: his place in the ring round her, and the way he faces (out).
local function RingSpot(centre, k, n)
    local per = math.min(n, 8)
    local ring = math.floor((k - 1) / 8)
    local a = ((k - 1) % 8) / per * math.pi * 2 + ring * 0.4
    local dir = Vector(math.cos(a), math.sin(a), 0)
    return centre + dir * (RING + ring * 40), math.deg(a)
end

local function MoveGuards(centre, dt)
    local n = 0
    for _, g in ipairs(A.guards) do if IsValid(g) and g:Health() > 0 then n = n + 1 end end
    local k = 0
    for _, g in ipairs(A.guards) do
        if IsValid(g) and g:Health() > 0 then
            k = k + 1
            local spot, yaw = RingSpot(centre, k, n)
            local to = spot - g:GetPos()
            local d = to:Length()
            if d > 4 then
                local step = math.min(d, GUARD_SPEED * dt)
                g:SetPos(g:GetPos() + to * (step / d))
            end
            if not (g.GetEnemy and IsValid(g:GetEnemy())) then g:SetAngles(Angle(0, yaw, 0)) end
        end
    end
end

------------------------------------------------------------------------
-- The shield run: no APC by the stand, so every Combine there runs her to her office
------------------------------------------------------------------------
-- (the owner, 15 November: "crowd the administrator and have her crouch (or force the human player to crouch)
-- and use the prison escort concept but at 5x speed with ALL the combine forming a shield around her back to
-- her office ... literally unstoppable and go straight through doors all of them without a hitch, all in a
-- group, while shooting at the attackers and never stop moving and go through other NPCs")
--
-- Her in the middle, her guards in rings of eight round her, the city's units falling in on the outside. The
-- whole shell is one body moved along the way by script every tick: nobody walks, so nothing in the way (a
-- door, a corner, a crowd) can stop it. Their legs: each is held in his run by a scripted sequence, the way
-- someone on a bench is held in his sitting (LC.MakeSequence), and is not the game's to move meanwhile
-- (MOVETYPE_NONE: the run's own steps, and the game's smoothing of an NPC's steps, would fight the script).
-- Their fire on the way is the script's too: a sound, a tracer, and a hit only on a marked attacker in sight.

local JOIN_REACH = 1200 -- a unit of the city's this near the stand, or the shell as it passes, falls in
local DOOR_AHEAD = 250  -- a door this far on along the way is opened for them
local FIRE_REACH = 1500 -- an attacker this near, and in sight, is shot at
local RUN = {
    hold = 3600, -- (the city leaves a unit in the shell alone this long at most: the "event" state, sv_livingcity.lua)
    -- scripted_sequence: no interruptions (32), whatever he was doing (64), no teleport at the end (128),
    -- loop (256), no complaints (2048), may die (4096)
    flags = 32 + 64 + 128 + 256 + 2048 + 4096,
    rate = 1.5, -- (their legs a little faster than a run: the shell covers ground at about twice one)
    hit = 0.4,  -- (how many of their shots on the move find him)
    joins = { idle = true, moving = true, busy = true, hostile = true }, -- (what a unit may be called from)
    keeps = { hostile = true, adminguard = true, speechguard = true },   -- (the states handed back as they were)
    -- the model's own run, weapon up: the first of these it has (a sequence's name, or an activity's)
    rifle = { "RunAIMALL1", "ACT_RUN_AIM_RIFLE", "ACT_RUN_AIM", "ACT_RUN_RIFLE", "ACT_RUN" },
    pistol = { "ACT_RUN_AIM_PISTOL", "ACT_RUN_PISTOL", "ACT_RUN_AIM", "ACT_RUN" },
    her = { "crouchRUNALL1", "ACT_RUN_CROUCH", "Crouch_walk_all", "ACT_WALK_CROUCH", "run_protected_all", "ACT_RUN_PROTECTED", "ACT_RUN" },
    -- sound, tracer, damage, seconds between one man's shots
    guns = {
        weapon_ar2 = { "Weapon_AR2.NPC_Single", "AR2Tracer", 8, 0.3 },
        weapon_smg1 = { "Weapon_SMG1.NPC_Single", "Tracer", 5, 0.25 },
        weapon_pistol = { "Weapon_Pistol.NPC_Single", "Tracer", 8, 0.5 },
        weapon_shotgun = { "Weapon_Shotgun.NPC_Single", "Tracer", 30, 1 },
    },
}

-- The floor under a spot, near the height the way is at there (not a roof above it, nor a pit below).
local function Floor(p, z)
    local g = LC.GroundAt and LC.GroundAt(Vector(p.x, p.y, z)) or nil
    if g and math.abs(g.z - z) < 80 then z = g.z end
    return Vector(p.x, p.y, z)
end

local function RunSeq(g, list)
    for _, c in ipairs(list) do
        if string.sub(c, 1, 4) == "ACT_" then
            local name = LC.BusySeqName and LC.BusySeqName(g, c)
            if name then return name end
        elseif g.LookupSequence then
            local s = g:LookupSequence(c)
            if s and s >= 0 then return c end
        end
    end
    return nil
end

-- One of the shell under the script's hand: people and NPCs go through him (bullets still find him), the game
-- does not move him, and his legs run. What is changed on him is kept in m, and put back by Give.
local function Take(m, list)
    local g = m.ent
    if g.GetCollisionGroup and g.SetCollisionGroup then
        m.group = g:GetCollisionGroup()
        g:SetCollisionGroup(COLLISION_GROUP_DEBRIS or 1)
    end
    if g.GetMoveType and g.SetMoveType then
        m.move = g:GetMoveType()
        g:SetMoveType(MOVETYPE_NONE or 0)
    end
    if IsValid(g.lcGesture) then
        g.lcGesture:Fire("CancelSequence")
        g.lcGesture:Remove()
    end
    local seq = LC.MakeSequence and RunSeq(g, list)
    if not seq then return end -- (then the parade's way, in RunThink)
    if (g:GetName() or "") == "" then g:SetName("lc_shield_" .. g:EntIndex()) end
    local ok, ss = LC.Try(LC.MakeSequence, g, g:GetPos(), g:GetAngles().y, seq, seq, RUN.flags, 0, 0)
    if ok and IsValid(ss) then m.ss, m.check = ss, CurTime() + 1 end
end
local function Give(m)
    if IsValid(m.ss) then
        m.ss:Fire("CancelSequence")
        SafeRemoveEntityDelayed(m.ss, 0.5)
    end
    local g = m.ent
    if not IsValid(g) then return end
    if m.group and g.SetCollisionGroup then g:SetCollisionGroup(m.group) end
    if m.move and g.SetMoveType then g:SetMoveType(m.move) end
    if g.SetPlaybackRate then g:SetPlaybackRate(1) end
end

-- A unit of the city's that falls in: not one in something scripted, walking a prisoner in, or a player's job's.
local function MayJoin(npc, st)
    return IsValid(npc) and LC.IsSecurity(st) and RUN.joins[st.state] == true and npc:Health() > 0
        and not (st.test or st.questLock or st.eventNPC or st.marching or npc.lcGrenadeJumper)
end

-- One more in the shell: his place is the next one out, and it is his until it is over.
local function Enlist(g, now, joined)
    local R = A.run
    if R.set[g] then return end
    R.slots = R.slots + 1
    local m = { ent = g, slot = R.slots, joined = joined, from = g:GetPos() }
    R.set[g] = m
    R.members[#R.members + 1] = m
    local st = LC.NPCs and LC.NPCs[g]
    if st then
        -- (the city leaves him alone meanwhile)
        m.st, m.state, m.lock, m.evUntil = st, st.state, st.questLock, st.eventUntil
        if st.state == "busy" and LC.EndBusy then LC.EndBusy(g, st, false) end
        if LC.Release then LC.Release(g, st) end
        st.questLock, st.eventUntil = true, now + RUN.hold
        LC.SetState(g, st, "event")
    end
    if joined then A.guardSet[g] = true end -- (his fire hurts only her attackers; whoever hurts him is one)
    local wep = g.GetActiveWeapon and g:GetActiveWeapon()
    local cls = IsValid(wep) and wep:GetClass() or ""
    Take(m, (cls == "weapon_ar2" or cls == "weapon_smg1" or cls == "weapon_shotgun") and RUN.rifle or RUN.pistol)
end

-- The spot this far on along the way.
local function Ahead(R, far)
    local at, leg = R.at, R.leg
    while leg <= #R.path do
        local to = R.path[leg] - at
        local d = to:Length()
        if d >= far then return at + to * (far / d) end
        far, at, leg = far - d, R.path[leg], leg + 1
    end
    return at
end

-- A door on the way opens for them as it does for a unit walking up to it (sv_livingcity_doors.lua: the
-- Combine's own doors too, shut and locked again behind them). One a player locked, or tagged locked, stays
-- shut: they go through it all the same.
local function OpenDoor(door, now)
    if not (LC.IsRealDoor and LC.IsRealDoor(door) and LC.OpenedDoors and LC.Relock) then return false end
    if LC.OpenedDoors[door] then
        LC.OpenedDoors[door] = math.max(LC.OpenedDoors[door], now + 8)
        return true
    end
    local tag = LC.EffectiveDoorTag and LC.EffectiveDoorTag(door) or nil
    if tag == "locked" or tag == "open" or tag == "ignore" then return false end
    local locked = door.GetInternalVariable ~= nil and door:GetInternalVariable("m_bLocked") == true
    if locked and not (LC.UnitsOnlyDoorTag and LC.UnitsOnlyDoorTag(tag)) then return false end
    if locked then
        LC.Relock[door] = true
        door:Fire("Unlock")
    end
    door:Fire("Open")
    LC.OpenedDoors[door] = now + 8
    return true
end

local function Sees(R, from, who)
    if not util.TraceLine then return true end
    local tr = util.TraceLine({ start = from, endpos = who:WorldSpaceCenter(), mask = MASK_SHOT or MASK_SOLID,
        filter = function(e) return e ~= A.her and not R.set[e] end }) -- (not through each other: past them)
    return not tr or not tr.Hit or tr.Entity == who or (tr.Fraction or 0) >= 0.98
end

-- Shooting on the move: whoever has a gun ready and one of her attackers in sight fires, two of them at most at
-- a time. A hit is real and on him only (the rule under "Who is hurt"); the rest is the sound and the tracer.
local function Volley(R, now, centre)
    local targets = {}
    for who in pairs(A.attackers) do
        if IsValid(who) and who:GetPos():DistToSqr(centre) < FIRE_REACH * FIRE_REACH then
            if who:IsPlayer() then
                if who:Alive() and not (LC.HeldByCombine and LC.HeldByCombine(who)) then targets[#targets + 1] = who end
            elseif who:Health() > 0 then
                targets[#targets + 1] = who
            end
        end
    end
    local n = #R.members
    if #targets == 0 or n == 0 then return end
    local fired = 0
    for _ = 1, n do
        R.turn = R.turn % n + 1
        local m = R.members[R.turn]
        local g = m.ent
        if IsValid(g) and g:Health() > 0 and now >= (m.nextShot or 0) then
            local wep = g.GetActiveWeapon and g:GetActiveWeapon()
            local G = RUN.guns[IsValid(wep) and wep:GetClass() or ""]
            if not G then
                m.nextShot = now + 5 -- (a stunstick: nothing to fire)
            else
                m.nextShot = now + G[4] * math.Rand(0.6, 1.4)
                local who = targets[math.random(#targets)]
                local src = g:GetPos() + Vector(0, 0, 56)
                if Sees(R, src, who) then
                    local to = who:WorldSpaceCenter()
                    local hit = math.random() < RUN.hit
                    -- (he turns to fire, and is back facing the way they go a moment later)
                    m.faceUntil, m.faceYaw = now + 0.4, math.deg(math.atan2(to.y - src.y, to.x - src.x))
                    g:EmitSound(G[1], 85, math.random(96, 104))
                    if util.Effect and EffectData then
                        if IsValid(wep) and wep.LookupAttachment then
                            local id = wep:LookupAttachment("muzzle")
                            local at = id and id > 0 and wep:GetAttachment(id)
                            if at and at.Pos then src = at.Pos end
                        end
                        local fx = EffectData()
                        fx:SetStart(src)
                        fx:SetOrigin(hit and to or (to + VectorRand() * 60))
                        fx:SetScale(6000)
                        util.Effect(G[2], fx)
                    end
                    R.shots = R.shots + 1
                    if hit then
                        R.hits = R.hits + 1
                        if DamageInfo and who.TakeDamageInfo then
                            local d = DamageInfo()
                            d:SetDamage(G[3])
                            d:SetAttacker(g)
                            d:SetInflictor(IsValid(wep) and wep or g)
                            d:SetDamageType(DMG_BULLET or 2)
                            d:SetDamagePosition(to)
                            who:TakeDamageInfo(d)
                        elseif who.TakeDamage then
                            who:TakeDamage(G[3], g, g)
                        end
                    end
                    fired = fired + 1
                    if fired >= 2 then break end
                end
            end
        end
    end
end

-- It sets off: the way to her desk (the city's own routes; straight there where they have none), and everyone
-- of hers in his place. False with no desk to run to.
function StartRun(now)
    local desk = LC.PointsOfKind and LC.PointsOfKind("desk")[1]
    if not desk then return false end
    local her = A.her
    local from = her:GetPos()
    local path = {}
    if LC.BuildRoute then
        local ok, route = LC.Try(LC.BuildRoute, from, desk.pos, "soldier")
        if ok and type(route) == "table" then
            for _, p in ipairs(route) do path[#path + 1] = p end
        end
    end
    if #path == 0 or path[#path]:DistToSqr(desk.pos) > 24 * 24 then path[#path + 1] = desk.pos end
    if A.closeCall then -- (badly hit: the run ends inside her office, short of her desk, where she faints)
        local door = OfficeDoor(desk.pos)
        if door then path[#path] = OfficeSpot(door, desk.pos) end
    end
    local first = path[1] - from
    local R = { path = path, leg = 1, at = from, yaw = math.deg(math.atan2(first.y, first.x)), desk = desk.pos,
        members = {}, set = {}, slots = 0, turn = 0, shots = 0, hits = 0, doors = {}, nextJoin = 0, nextDoor = 0, nextFire = 0 }
    A.run = R
    for _, g in ipairs(A.guards) do
        if IsValid(g) and g:Health() > 0 then Enlist(g, now, false) end
    end
    R.per = math.Clamp(R.slots, 1, 8)
    if not her:IsPlayer() then -- (the city's own: crouched and running, as a player is held crouched)
        R.her = { ent = her }
        Take(R.her, RUN.her)
    end
    return true
end

-- A tick of it. True when she is at her desk.
function RunThink(now, dt)
    local R, her = A.run, A.her
    -- on along the way, never stopping
    local left = CARRY_SPEED * dt
    while left > 0 and R.leg <= #R.path do
        local to = R.path[R.leg] - R.at
        local d = to:Length()
        if d <= left then
            R.at, R.leg, left = R.path[R.leg], R.leg + 1, left - d
        else
            R.at, left = R.at + to * (left / d), 0
        end
    end
    local toNext = R.path[R.leg] and (R.path[R.leg] - R.at) or nil
    if toNext and toNext.x * toNext.x + toNext.y * toNext.y > 1 then -- (the shell turns with the way it goes)
        -- (half a second to come round a corner: faster, and those on the outside of it would be swung back)
        R.yaw = R.yaw + math.Clamp(math.AngleDifference(math.deg(math.atan2(toNext.y, toNext.x)), R.yaw), -180 * dt, 180 * dt)
    end
    local centre = Floor(R.at, R.at.z)
    her:SetPos(centre)
    if not her:IsPlayer() then her:SetAngles(Angle(0, R.yaw, 0)) end
    local turn = math.rad(R.yaw)
    for _, m in ipairs(R.members) do
        local g = m.ent
        if IsValid(g) and g:Health() > 0 then
            local st = m.st
            if st and st.state ~= "event" then -- (something of the city's took him back: he is the shell's until it is over)
                st.eventUntil = now + RUN.hold
                LC.SetState(g, st, "event")
            end
            -- his place: her own guards share the first ring; past it, eight to a ring, each ring further out
            local k, ring, per = m.slot - 1, 0, R.per
            if m.slot > R.per then
                k = m.slot - R.per - 1
                ring, per = 1 + math.floor(k / 8), 8
            end
            local a = turn + (k % 8) / per * math.pi * 2 + ring * 0.4
            local p = g:GetPos()
            local to = centre + Vector(math.cos(a), math.sin(a), 0) * (RING + ring * 40) - p
            to.z = 0
            local d = to:Length()
            if d > 0.5 then p = p + to * (math.min(d, (CARRY_SPEED + GUARD_SPEED) * dt) / d) end
            g:SetPos(Floor(p, p.z + math.Clamp(centre.z - p.z, -600 * dt, 600 * dt)))
            local face = (m.faceUntil or 0) > now and m.faceYaw or R.yaw
            g:SetAngles(Angle(0, face, 0))
            -- (his legs go the way the shell goes, whichever way he is turned: the run's own blend)
            if g.SetPoseParameter then g:SetPoseParameter("move_yaw", math.AngleDifference(R.yaw, face)) end
            if m.ss and m.check and now >= m.check then -- (once: did the sequence take him? If not, the parade's way)
                m.check = nil
                if g.GetNPCState and NPC_STATE_SCRIPT and g:GetNPCState() ~= NPC_STATE_SCRIPT then
                    if IsValid(m.ss) then m.ss:Remove() end
                    m.ss = nil
                end
            end
            if m.ss then
                if g.SetPlaybackRate then g:SetPlaybackRate(RUN.rate) end
            elseif g.SetIdealActivity and ACT_RUN and now >= (m.actAt or 0) then
                -- (no sequence could be made for him: the parade's way, sv_livingcity_exercise.lua)
                m.actAt = now + 0.5
                if not g.GetIdealActivity or g:GetIdealActivity() ~= ACT_RUN then g:SetIdealActivity(ACT_RUN) end
            end
        end
    end
    if R.leg > #R.path then return true end
    -- the city's units near the stand, or near the shell as it passes, fall in on the outside
    if now >= R.nextJoin then
        R.nextJoin = now + 0.3
        for npc, st in pairs(LC.NPCs or {}) do
            if not R.set[npc] and MayJoin(npc, st) then
                local p = npc:GetPos()
                if p:DistToSqr(A.at) < JOIN_REACH * JOIN_REACH or p:DistToSqr(centre) < JOIN_REACH * JOIN_REACH then Enlist(npc, now, true) end
            end
        end
    end
    if now >= R.nextDoor then
        R.nextDoor = now + 0.15
        for _, e in ipairs(ents.FindInSphere(Ahead(R, DOOR_AHEAD * 0.5) + Vector(0, 0, 40), DOOR_AHEAD * 0.65)) do
            if IsValid(e) and R.doors[e] == nil and LC.IsDoorEntity and LC.IsDoorEntity(e) then R.doors[e] = OpenDoor(e, now) end
        end
    end
    if now >= R.nextFire then
        R.nextFire = now + 0.12
        Volley(R, now, centre)
    end
    return false
end

-- Over (at her desk, or cut short): everyone gets back what was changed on him. The city's units go back to
-- their beats; the address's own and her elites are Done's to see to.
function EndRun(a)
    local R = a.run
    if not R then return end
    a.run = nil
    local now = CurTime()
    if R.her then Give(R.her) end
    for _, m in ipairs(R.members) do
        Give(m)
        local g, st = m.ent, m.st
        if IsValid(g) and g:Health() > 0 then
            -- (set down where there is room to stand: the way went through walls)
            if LC.FreeSpawnPos then g:SetPos(LC.FreeSpawnPos(g:GetPos()) or g:GetPos()) end
            if st and LC.NPCs and LC.NPCs[g] == st then
                st.questLock, st.eventUntil = m.lock, m.evUntil
                local back = RUN.keeps[m.state] and m.state or "idle"
                LC.SetState(g, st, back)
                if back == "idle" then
                    -- a moment to come out of his run, then back to where he was called from
                    st.untilT = now + 3
                    local from = m.from
                    timer.Simple(1, function()
                        if IsValid(g) and g:Health() > 0 and LC.NPCs[g] == st and st.state == "idle" and LC.GoTo then LC.Try(LC.GoTo, g, st, from, false) end
                    end)
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- A close call at her address: in her office she faints, and a medic sees to her
------------------------------------------------------------------------
-- (the owner, 16 November: "it should use up a close call, just please make sure the player is aware of that
-- when and after it happens and that they see the whole scene unfold as they are escorted/rescued away from the
-- speech point; maybe when they get to their office and inside (between the administrator door and their desk)
-- they faint and fade to black and get the close call text on screen, then a medic NPC spawns in their office
-- and heals them, then leaves the office (able to open the administrator door this one time: when leaving)")
--
-- By the second, from when she is set down: 0 she is held still and her screen goes dark; 1.5 the close call is
-- counted (LC.CloseCallSurvived: her pockets stay, no infirmary) and she is told, and a medic is beside her;
-- 3 and 4.8 the sound of treatment; 6 her health is back; 6.5 her screen comes back and she can move; 7.5 the
-- medic goes, the office door opening for them this once; 10.5 she can be hurt again. The medic is gone once out
-- of sight (at 20 whatever). Where the exit ends anywhere else (no APC and no desk: the ring holds, then lets
-- go) it happens there, and the medic walks off.

local SCENE = { dark = 1.5, heal = 6, wake = 6.5, go = 7.5, guard = 4, last = 20 }

-- Her office's door: the editor's "Door: Administrator's office" nearest her desk (within 1500 units of it).
function OfficeDoor(desk)
    local best, bd
    for id, tag in pairs(LC.DoorTags or {}) do
        if tag == "office" and ents.GetMapCreatedEntity then
            local d = ents.GetMapCreatedEntity(id)
            if IsValid(d) then
                local dist = d:WorldSpaceCenter():DistToSqr(desk)
                if dist < 1500 * 1500 and (not bd or dist < bd) then best, bd = d, dist end
            end
        end
    end
    return best
end
-- Inside it: half way between that door and her desk, on the floor.
function OfficeSpot(door, desk)
    local c = door:WorldSpaceCenter()
    return Ground(Vector((c.x + desk.x) / 2, (c.y + desk.y) / 2, desk.z))
end

-- The close call is used up, and she is told (in the dark).
local function SceneCount(c)
    c.counted = true
    local her = c.her
    local left = LC.CloseCallSurvived and LC.CloseCallSurvived(her) or 0
    c.left = left
    if LC.Notice then
        LC.Notice(her, "bad", "A close call", "You were hit at your address. Your guards got you out. " ..
            (left > 0 and string.format("%d close call%s left.", left, left == 1 and "" or "s") or "That was the last one: the next death is the end of you."), 12)
    end
end
local function SceneHeal(c)
    c.healed = true
    c.her:SetHealth(c.her:GetMaxHealth()) -- (full, less what recovering takes)
end
local function SceneWake(c, now)
    c.woke, c.held, c.wokeAt = true, false, now
    local her = c.her
    if her.ScreenFade then
        her:ScreenFade(bit.bor(SCREENFADE and SCREENFADE.IN or 1, SCREENFADE and SCREENFADE.PURGE or 16), Color(0, 0, 0, 255), 1.5, 0)
    end
end

-- A medic beside her: one of the city's people, in what the clinic's medics wear (their own clothes where the
-- server has no look for the Clinic Medic). Nothing happens without one: she is healed all the same.
local function SceneMedic(c, now)
    if not LC.SpawnCitizen then return end
    local her = c.her
    local at = her:GetPos()
    local side = IsValid(c.door) and (c.door:WorldSpaceCenter() - at) or her:GetForward()
    side.z = 0
    if side:LengthSqr() < 1 then side = Vector(1, 0, 0) end
    side:Normalize()
    local pos = Ground(at + side * 48)
    pos = (LC.FreeSpawnPos and LC.FreeSpawnPos(pos + Vector(0, 0, 4))) or pos
    local ok, npc, st = LC.Try(LC.SpawnCitizen, pos)
    if not (ok and IsValid(npc) and st) then return end
    -- (the scene's own: not one of the city's numbers, and the city leaves them alone)
    st.unmanaged, st.questLock, st.eventUntil = true, true, now + 120
    LC.SetState(npc, st, "event")
    if LC.OutfitFor then
        local key = "p" .. tostring(st.profile and st.profile.id or npc:EntIndex())
        local path, skin, bg = LC.OutfitFor("medic", key, LC.FaceOf and LC.FaceOf(npc:GetModel()) or nil, false, st.gender)
        if path and (not util.IsValidModel or util.IsValidModel(path)) then
            npc:SetModel(path)
            if npc.SetBodyGroups then npc:SetBodyGroups("000000000000000") end
            if LC.ApplyLook then LC.ApplyLook(npc, skin, bg) end
        end
    end
    npc:SetAngles(Angle(0, math.deg(math.atan2(-side.y, -side.x)), 0))
    if LC.PlayGesture then LC.PlayGesture(npc, { "ACT_CIT_HEAL", "Crouch_idleD", "ACT_COVER_LOW" }, 5) end
    c.medic = npc
end

-- The office door opens for the medic, this once: shut and locked again behind them by the doors' own code, as
-- when the Administrator uses it (sv_livingcity_doors.lua).
local function SceneDoor(door, now)
    if not (LC.OpenedDoors and LC.Relock) then return end
    if not LC.OpenedDoors[door] then
        if door.GetInternalVariable and door:GetInternalVariable("m_bLocked") == true then
            LC.Relock[door] = true
            door:Fire("Unlock")
        end
        door:Fire("Open", "", 0.1)
    end
    LC.OpenedDoors[door] = math.max(LC.OpenedDoors[door] or 0, now + 4)
end

local function SceneEnd()
    local c = C
    if not c then return end
    C = nil
    timer.Remove("LivingCityAdminCloseCall")
    if IsValid(c.medic) then c.medic:Remove() end
    local her = c.her
    if not (IsValid(her) and her:Alive()) then return end
    -- (cut short: she is counted, healed and freed all the same)
    if not c.counted then SceneCount(c) end
    if not c.healed then SceneHeal(c) end
    if not c.woke then SceneWake(c, CurTime()) end
    if c.safe then
        timer.Simple(SCENE.guard, function()
            if IsValid(her) and her.GodDisable and not (A and A.her == her) and not (C and C.her == her) then her:GodDisable() end
        end)
    end
end

local function Scene(now)
    local c = C
    if not c then return end
    local her = c.her
    if not IsValid(her) or not her:Alive() then return SceneEnd() end
    local t = now - c.t0
    if t >= SCENE.dark and not c.counted then
        SceneCount(c)
        SceneMedic(c, now)
    end
    if t >= 3 and not c.s1 then
        c.s1 = true
        her:EmitSound("items/medshot4.wav", 70, 100)
    end
    if t >= 4.8 and not c.s2 then
        c.s2 = true
        her:EmitSound("items/smallmedkit1.wav", 70, 100)
    end
    if t >= SCENE.heal and not c.healed then SceneHeal(c) end
    if t >= SCENE.wake and not c.woke then SceneWake(c, now) end
    if c.woke and c.safe and now >= c.wokeAt + SCENE.guard then
        c.safe = false
        if her.GodDisable and not (A and A.her == her) then her:GodDisable() end
    end
    local med = c.medic
    if IsValid(med) and t >= SCENE.go then
        if not c.out then
            if IsValid(med.lcGesture) then
                med.lcGesture:Fire("CancelSequence")
                med.lcGesture:Remove()
            end
            local from = her:GetPos()
            local door = IsValid(c.door) and c.door:WorldSpaceCenter() or nil
            local away = (door or med:GetPos()) - from
            away.z = 0
            if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
            away:Normalize()
            -- (through the door and on a little; with no door, off the way they stand from her)
            c.out = door and Ground(Vector(door.x, door.y, from.z) + away * 170) or Ground(med:GetPos() + away * 350)
        end
        local p = med:GetPos()
        local out = p:DistToSqr(c.out) < 80 * 80
        if not out and now >= (c.nextGo or 0) then
            c.nextGo = now + 1.5
            if IsValid(c.door) then SceneDoor(c.door, now) end
            med:SetLastPosition(c.out)
            med:SetSchedule(SCHED_FORCED_GO)
        end
        if t >= SCENE.last or ((out or t >= SCENE.go + 6) and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40)))) then med:Remove() end
    end
    if c.woke and not c.safe and not IsValid(c.medic) then return SceneEnd() end
end

-- She faints where she was set down (door: her office's, when she is in it).
function Faint(her, door)
    if C then SceneEnd() end
    C = { her = her, door = door, t0 = CurTime(), held = true, safe = true }
    if her.GodEnable then her:GodEnable() end
    if her.ScreenFade then
        her:ScreenFade(bit.bor(SCREENFADE and SCREENFADE.OUT or 2, SCREENFADE and SCREENFADE.STAYOUT or 8), Color(0, 0, 0, 255), SCENE.dark, 0)
    end
    timer.Create("LivingCityAdminCloseCall", 0.1, 0, function()
        local ok, err = LC.Try(Scene, CurTime())
        if not ok then
            if LC.Error then LC.Error("admin close call", err) end
            LC.Try(SceneEnd) -- (never left in the dark)
        end
    end)
end
function LC.AdminCloseCallScene() return C end
LC.AdminCloseCallEnd = SceneEnd
-- Held still while she is out.
hook.Add("StartCommand", "LivingCityAdminCloseCall", function(ply, cmd)
    if not (C and C.held and ply == C.her) then return end
    cmd:ClearMovement()
    cmd:SetButtons(IN_DUCK or 4)
end)
hook.Add("PlayerDisconnected", "LivingCityAdminCloseCall", function(p) if C and C.her == p then SceneEnd() end end)

function LC.AdminExfilThink(now)
    if not A then return end
    local her = A.her
    if not IsValid(her) or (her:IsPlayer() and not her:Alive()) then return Done(false) end
    local dt = math.Clamp(now - A.last, 0, 0.25)
    A.last = now
    local t = now - A.t0
    if A.phase == "close" then
        MoveGuards(her:GetPos(), dt)
        if t >= CLOSE_SECS then
            -- an APC by the stand: out by APC. None, and a desk to run to: the shield run. Neither: they hold.
            if IsValid(A.apc) then A.phase = "carry"
            elseif StartRun(now) then A.phase = "run"
            else A.phase = "hold" end
        end
    elseif A.phase == "hold" then
        MoveGuards(her:GetPos(), dt)
        if t >= HOLD_SECS then return Done(false) end
    elseif A.phase == "run" then
        if RunThink(now, dt) then
            A.ran = true
            return Done(true)
        end
    elseif A.phase == "carry" then
        if not IsValid(A.apc) then A.phase = "hold" return end
        -- to the APC's side, straight there, through whatever is in the way
        local side = Angle(0, A.apc.lcDriveYaw or 0, 0):Right()
        local door = A.apc:GetPos() + side * 90
        local pos = her:GetPos()
        local to = door - pos
        to.z = 0
        local d = to:Length()
        if d <= 40 then
            A.phase, A.driveT0 = "drive", now
            if her:IsPlayer() then
                if her.SetNoDraw then her:SetNoDraw(true) end
                if her.SetNotSolid then her:SetNotSolid(true) end
            elseif her.SetNoDraw then
                her:SetNoDraw(true)
            end
            A.apc:EmitSound("doors/door_metal_medium_close1.wav", 90, 90)
            A.apc:EmitSound("vehicles/apc/apc_cruise_loop3.wav", 90, 100)
            if A.apc.SetSolid then A.apc:SetSolid(SOLID_NONE or 0) end -- (it drives through anything)
        else
            local step = math.min(d, CARRY_SPEED * dt)
            local nextPos = Ground(pos + to * (step / d))
            her:SetPos(nextPos)
            MoveGuards(nextPos, dt)
        end
    elseif A.phase == "drive" then
        if not IsValid(A.apc) then return Done(true) end
        local dtv = now - A.driveT0
        local speed = math.min(DRIVE_TOP, DRIVE_TOP * dtv / 1.5)
        local fwd = Angle(0, A.apc.lcDriveYaw or 0, 0):Forward()
        local p = A.apc:GetPos() + fwd * (speed * dt)
        local g = Ground(p)
        if math.abs(g.z - p.z) < 80 then p.z = g.z end -- (it follows the road, not a roof or a pit)
        A.apc:SetPos(p)
        her:SetPos(p + Vector(0, 0, 30))
        -- (the ring is free: they fight whoever attacked her)
        if dtv >= DRIVE_SECS or (dtv >= 2.5 and LC.IsSeen and not LC.IsSeen(p + Vector(0, 0, 40))) then return Done(true) end
    end
end
hook.Add("Think", "LivingCityAdminExfil", function()
    if not A then return end
    local ok, err = LC.Try(LC.AdminExfilThink, CurTime())
    if not ok then
        if LC.Error then LC.Error("admin exfil", err) end
        LC.Try(Done, true) -- (never left half way)
    end
end)

-- Held in a crouch, and not walking off, while they have her.
hook.Add("StartCommand", "LivingCityAdminExfil", function(ply, cmd)
    if not A or ply ~= A.her then return end
    cmd:ClearMovement()
    cmd:SetButtons(bit.bor(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP or 2)), IN_DUCK or 4))
end)

-- A hit on a player Administrator that sets her guards off: one that would kill her is a close call, never a
-- kill: it leaves her a breath, and she is taken out all the same. Where close calls are counted (lc_close_calls
-- above 0, lc_permadeath 1) it uses one of hers up (the owner, 16 November: "it should use up a close call, just
-- please make sure the player is aware of that when and after it happens"): she is told at once, and again when
-- she is set down (the scene above). With none left the hit stands, as it would anywhere. Where they are not
-- counted she simply lives, as before.
local function CloseCallsCount()
    local calls, perma = GetConVar("lc_close_calls"), GetConVar("lc_permadeath")
    return LC.CloseCallsLeft ~= nil and calls ~= nil and calls:GetInt() > 0 and (perma == nil or perma:GetBool())
end
local function CloseHit(her, dmg)
    local hp = her:Health()
    if (dmg:GetDamage() or 0) < hp then return end
    if CloseCallsCount() then
        if LC.CloseCallsLeft(her) <= 0 then return end
        her.lcAdminCloseHit = CurTime()
        if LC.Notice then LC.Notice(her, "bad", "A close call", "You are badly hit. Your guards are getting you out.", 6) end
        if her.ScreenFade then her:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(150, 0, 0, 170), 1.5, 0.3) end
    end
    dmg:SetDamage(math.max(0, hp - 1))
end

-- Who is hurt: she no longer; by her guards' fire only the attackers; whoever hurts her guards is an attacker.
-- Before any of it: a shot at her at her address is what sets it off (a player takes that shot: the assassin's
-- one chance; the city's own is never hurt).
hook.Add("EntityTakeDamage", "LivingCityAdminExfil", function(ent, dmg)
    local att = dmg:GetAttacker()
    -- her address's guards (and, while they have her, her own) hurt only who they are after, and monsters
    if IsValid(att) and (att.lcSpeechGuard or (A and A.guardSet[att])) and IsValid(ent) and not LC.AdminTargets[ent]
        and not (LC.IsMonster and LC.IsMonster(ent)) then
        return true
    end
    if C and C.safe and ent == C.her then return true end -- (fainted in her office: not until she is up)
    if A then
        if ent == A.her then
            -- (one of the Combine's own, a player, hitting her while they have her: no harm, and one stray round in
            -- a firefight brands nobody. A second from the same player within ten seconds does.)
            if UnitPlayer(att) and (dmg:GetDamage() or 0) > 0 then
                local now, last = CurTime(), A.strays[att]
                A.strays[att] = now
                if last and now > last and now - last < 10 and Turn(att) then Mark(att) end
            end
            return true
        end
        -- (her guards or the APC hit: whoever did it is an attacker, but never one of the Combine's own)
        if (A.guardSet[ent] or ent == A.apc) and IsValid(att) and (att:IsPlayer() or att:IsNPC()) then Mark(att) end
        if ent == A.apc then return true end
        return
    end
    -- (a guard of her address shot at: they may shoot back)
    if IsValid(ent) and ent.lcSpeechGuard and IsValid(att) and (att:IsPlayer() or att:IsNPC()) and not Theirs(att) then LC.AdminTargets[att] = true end
    if not cvExfil:GetBool() then return end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or not IsValid(ent) or (ent ~= S.by and ent ~= S.her) then return end
    if not IsValid(att) or not (att:IsPlayer() or att:IsNPC()) or att == ent then return end
    if (dmg:GetDamage() or 0) <= 0 then return end
    -- one of the Combine's own: an NPC's fire never counts (it cannot hurt her: sv_livingcity_cp.lua). A player's
    -- hit on her is an attempt like anyone's, and they are thrown out before they are marked for it.
    if Theirs(att) then
        if not att:IsPlayer() then return end
        Turn(att)
    end
    local her = ent
    timer.Simple(0, function()
        if IsValid(her) and (not her:IsPlayer() or her:Alive()) then LC.AdminAttempt(her, att, "shot") end
    end)
    if not her:IsPlayer() then return true end
    CloseHit(her, dmg)
end)

-- A shot that does not hit her: a bullet that lands within 20 feet of her, or passes that near, is an attempt
-- all the same; so is a bolt, a rocket or an energy ball that comes that near (LC.AdminGrenadeThink).
function LC.AdminNearMiss(pos, who)
    if A or not cvExfil:GetBool() then return false end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S then return false end
    local her = (IsValid(S.by) and S.by) or (IsValid(S.her) and S.her) or nil
    if not her or who == her or Theirs(who) or (IsValid(who) and who.lcSpeechGuard) then return false end
    if pos:DistToSqr(her:GetPos() + Vector(0, 0, 40)) > NEAR_MISS * NEAR_MISS then return false end
    return LC.AdminAttempt(her, who, "near miss")
end
function LC.AdminBulletCheck(shooter, data)
    if A or not cvExfil:GetBool() or not IsValid(shooter) or not (shooter:IsPlayer() or shooter:IsNPC()) then return false end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or Theirs(shooter) or shooter.lcSpeechGuard then return false end
    local her = (IsValid(S.by) and S.by) or (IsValid(S.her) and S.her) or nil
    local src, dir = data and data.Src, data and data.Dir
    if not (her and src and dir) or shooter == her then return false end
    local far = src + dir * (data.Distance or 8192)
    local hit = far
    if util.TraceLine then
        local tr = util.TraceLine({ start = src, endpos = far, filter = shooter, mask = MASK_SHOT or MASK_SOLID })
        if tr and tr.Hit and tr.HitPos then hit = tr.HitPos end
    end
    -- where it lands, or the nearest it comes to her on the way
    local target = her:GetPos() + Vector(0, 0, 40)
    local seg = hit - src
    local len2 = seg:LengthSqr()
    local t = len2 > 0 and math.Clamp((target - src):Dot(seg) / len2, 0, 1) or 0
    local nearest = src + seg * t
    if hit:DistToSqr(target) > NEAR_MISS * NEAR_MISS and nearest:DistToSqr(target) > NEAR_MISS * NEAR_MISS then return false end
    timer.Simple(0, function() if IsValid(her) and IsValid(shooter) then LC.AdminAttempt(her, shooter, "near miss") end end)
    return true
end
hook.Add("EntityFireBullets", "LivingCityAdminExfil", function(ent, data)
    LC.Try(LC.AdminBulletCheck, ent, data) -- (nothing is answered: the bullet flies as it would)
end)

------------------------------------------------------------------------
-- Keep back: nobody walks up to her at her address
------------------------------------------------------------------------

local cvKeep = CreateConVar("lc_speech_keepback", "1", FLAGS, "At her address, anyone not of the Combine who walks up to her is warned once by a guard and shot if they come closer (0: off)")
local WARNING = "npc/metropolice/vo/finalwarning.wav"

-- The warning line and the inner line, from her: inside her row of guards is too close (nearer in when the
-- crowd stands close to the stand, so nobody in the crowd is ever inside them).
function LC.SpeechLines(S)
    local gap = (S.crowd.pos - S.stand.pos):Length2D()
    local warn = math.Clamp(gap - 170, 110, 230)
    return warn, math.max(60, warn - 100)
end
local function LeftAlone(e, her)
    if e == her or Theirs(e) or e.lcSpeechGuard then return true end
    if e:IsPlayer() then
        if not e:Alive() then return true end
        if e:GetNW2Bool("lc_build", false) or (LC.EditorHeld and LC.EditorHeld(e)) then return true end -- (staff at work)
        if LC.HeldByCombine and LC.HeldByCombine(e) then return true end
        if e.GetMoveType and MOVETYPE_NOCLIP and e:GetMoveType() == MOVETYPE_NOCLIP then return true end
        return false
    end
    local st = LC.NPCs and LC.NPCs[e]
    return not (st and st.role == "rebel" and e:Health() > 0) -- (of the city's NPCs, only the Resistance's fighters)
end
function LC.AdminPerimeterThink(now)
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or A or not cvKeep:GetBool() then return end
    local her = (IsValid(S.by) and S.by) or (IsValid(S.her) and S.her) or nil
    if not her then return end
    local guards = {}
    for _, l in ipairs({ S.guards or {}, S.detail or {} }) do
        for _, g in ipairs(l) do if IsValid(g) and g:Health() > 0 then guards[#guards + 1] = g end end
    end
    if #guards == 0 then return end
    local function Nearest(pos)
        local best, bd
        for _, g in ipairs(guards) do
            local d = g:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = g, d end
        end
        return best
    end
    S.warnedOff, S.intruders = S.warnedOff or {}, S.intruders or {}
    local warn, kill = LC.SpeechLines(S)
    local at = her:GetPos()
    for _, e in ipairs(ents.FindInSphere(at, warn)) do
        if IsValid(e) and (e:IsPlayer() or e:IsNPC()) and not LeftAlone(e, her) then
            local d = e:GetPos():DistToSqr(at)
            if d < kill * kill then
                if not S.intruders[e] then
                    S.intruders[e] = now
                    LC.AdminTargets[e] = true
                    for _, g in ipairs(guards) do
                        if g.AddEntityRelationship then g:AddEntityRelationship(e, D_HT or 1, 99) end
                        if g.SetEnemy then g:SetEnemy(e) end
                    end
                end
            elseif not S.warnedOff[e] then
                S.warnedOff[e] = true
                local g = Nearest(e:GetPos())
                g:EmitSound(WARNING, 90, 100)
                if LC.FaceYaw then LC.FaceYaw(g, (e:GetPos() - g:GetPos()):Angle().y) end
            end
        end
    end
    -- whoever came too close is shot until dead, wherever they run to within sight of the stand
    if now < (S.nextKeepShot or 0) then return end
    for e in pairs(S.intruders) do
        local alive = IsValid(e) and ((e:IsPlayer() and e:Alive()) or (e:IsNPC() and e:Health() > 0))
        if not alive then
            S.intruders[e] = nil
        elseif e:GetPos():DistToSqr(at) < 900 * 900 then
            local g = Nearest(e:GetPos())
            g:EmitSound("Weapon_AR2.NPC_Single")
            if e.TakeDamage then e:TakeDamage(34, g, g) end
            S.nextKeepShot = now + 0.35
        end
    end
end
local nextKeep = 0
hook.Add("Think", "LivingCityAdminKeepBack", function()
    local now = CurTime()
    if now < nextKeep then return end
    nextKeep = now + 0.25
    if not (LC.SpeechSession and LC.SpeechSession()) then return end
    local ok, err = LC.Try(LC.AdminPerimeterThink, now)
    if not ok and LC.Error then LC.Error("admin keep back", err) end
end)
-- (which hook hears a hit first is not promised: one that answered before ours would hide the shot from it. So the
-- hit itself, once taken, sets it off too.)
hook.Add("PostEntityTakeDamage", "LivingCityAdminExfil", function(ent, dmg, took)
    if A or not took or not cvExfil:GetBool() then return end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or ent ~= S.by then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or not (att:IsPlayer() or att:IsNPC()) or att == ent then return end
    if Theirs(att) then
        if not att:IsPlayer() then return end
        Turn(att) -- (a unit player's hit: thrown out, then an attempt like anyone's)
    end
    if ent:Alive() then LC.AdminAttempt(ent, att, "shot") end
end)
hook.Add("PlayerDisconnected", "LivingCityAdminExfil", function(p) if A and A.her == p then Done(false) end end)

-- The Resistance killing the Administrator at her address is no random killing (sv_livingcity_conduct.lua): it
-- is the one chance an assassin has.
hook.Add("LivingCityJudgeKill", "LivingCityAdminExfil", function(attacker, victim)
    if not IsValid(attacker) or attacker:GetNW2String("lcf_faction", "") ~= "resistance" then return end
    local S = LC.SpeechSession and LC.SpeechSession()
    if (S and S.by == victim) or (A and A.her == victim) then return true end
end)
