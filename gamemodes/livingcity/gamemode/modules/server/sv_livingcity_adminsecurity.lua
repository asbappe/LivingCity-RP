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
    With no APC point by the stand: the ring and the screen for twelve seconds.
    The other way out the owner described (every Combine there running her to
    her office as a shield) is not built: TODO.md.

    lc_admin_grenade_jump 1/0, lc_admin_exfil 1/0
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
    timer.Simple(t + 0.2, function() Boom(g, rag, at) end)
    -- an attempt on her life
    if IsValid(who) and who:IsPlayer() and LC.ReportCrime then LC.ReportCrime(who, "Threat to the City Administrator", 300) end
    hook.Run("LivingCityAdminAttempt", her, who, "grenade")
    return true
end

function LC.AdminGrenadeWatch(g)
    if IsValid(g) and GRENADES[g:GetClass()] then watch[g] = CurTime() end
end
hook.Add("OnEntityCreated", "LivingCityAdminGrenade", function(e)
    if not cvJump:GetBool() or not IsValid(e) or not GRENADES[e:GetClass()] then return end
    watch[e] = CurTime()
end)

-- Each grenade in the air or on the ground: by her, landed, and not the Combine's own, somebody goes.
function LC.AdminGrenadeThink(now)
    for g, since in pairs(watch) do
        if not IsValid(g) or g.lcJumped or now - since > 12 then
            watch[g] = nil
        elseif cvJump:GetBool() and now - since > 0.15 then
            local at = g:GetPos()
            local vel = g.GetVelocity and g:GetVelocity() or Vector(0, 0, 0)
            if vel:Length() < SLOW or now - since > AIR then
                local her = Her(at)
                if her and not Theirs(Thrower(g)) then
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

-- An attacker: wanted, and every one of her guards on him.
local function Mark(who)
    if not (A and IsValid(who)) or A.attackers[who] or Theirs(who) then return end
    A.attackers[who] = true
    if who:IsPlayer() and LC.ReportCrime then LC.ReportCrime(who, "Threat to the City Administrator", 300) end
    if LC.MakeCopsHostile then LC.Try(LC.MakeCopsHostile, who, who:GetPos(), 2500) end
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
    A = { her = her, attackers = {}, guards = guards, guardSet = {}, glass = {}, t0 = now, last = now, phase = "close",
          apc = IsValid(S.apc) and S.apc or nil, at = her:GetPos() }
    for _, g in ipairs(guards) do A.guardSet[g] = true end
    S.apc = nil
    if her:IsPlayer() then
        if her.GodEnable then her:GodEnable() end
        her:SetNW2Bool("lc_exfil", true)
    else
        her.lcExfilHer = true
    end
    Screen(S.stand.pos, S.crowd.pos)
    LC.EndSpeech() -- (the crowd is let go; the podium goes)
    Mark(who)
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
        her:Remove() -- (the city's own: away in the APC)
        return
    end
    her:SetNW2Bool("lc_exfil", false)
    if her.SetNoDraw then her:SetNoDraw(false) end
    if her.SetNotSolid then her:SetNotSolid(false) end
    if deliver then
        local desk = LC.PointsOfKind and LC.PointsOfKind("desk")[1]
        local to = desk and desk.pos or a.at
        her:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(to + Vector(0, 0, 8))) or to)
        if her.ScreenFade then her:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(0, 0, 0, 255), 1.5, 0.3) end
        hook.Run("LivingCityAdminMoved", her, to)
    end
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

function LC.AdminExfilThink(now)
    if not A then return end
    local her = A.her
    if not IsValid(her) or (her:IsPlayer() and not her:Alive()) then return Done(false) end
    local dt = math.Clamp(now - A.last, 0, 0.25)
    A.last = now
    local t = now - A.t0
    if A.phase == "close" then
        MoveGuards(her:GetPos(), dt)
        if t >= CLOSE_SECS then A.phase = IsValid(A.apc) and "carry" or "hold" end
    elseif A.phase == "hold" then
        MoveGuards(her:GetPos(), dt)
        if t >= HOLD_SECS then return Done(false) end
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

-- Who is hurt: she no longer; by her guards' fire only the attackers; whoever hurts her guards is an attacker.
-- Before any of it: a shot at her at her address is what sets it off (a player takes that shot: the assassin's
-- one chance; the city's own is never hurt).
hook.Add("EntityTakeDamage", "LivingCityAdminExfil", function(ent, dmg)
    local att = dmg:GetAttacker()
    if A then
        if ent == A.her then return true end
        if IsValid(att) and A.guardSet[att] and not A.attackers[ent] then return true end
        if (A.guardSet[ent] or ent == A.apc) and IsValid(att) and (att:IsPlayer() or att:IsNPC()) then Mark(att) end
        if ent == A.apc then return true end
        return
    end
    if not cvExfil:GetBool() then return end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or not IsValid(ent) or (ent ~= S.by and ent ~= S.her) then return end
    if not IsValid(att) or not (att:IsPlayer() or att:IsNPC()) or att == ent or Theirs(att) then return end
    if (dmg:GetDamage() or 0) <= 0 then return end
    local her = ent
    timer.Simple(0, function()
        if IsValid(her) and (not her:IsPlayer() or her:Alive()) then LC.AdminAttempt(her, att, "shot") end
    end)
    if not her:IsPlayer() then return true end
end)
-- (which hook hears a hit first is not promised: one that answered before ours would hide the shot from it. So the
-- hit itself, once taken, sets it off too.)
hook.Add("PostEntityTakeDamage", "LivingCityAdminExfil", function(ent, dmg, took)
    if A or not took or not cvExfil:GetBool() then return end
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S or ent ~= S.by then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or not (att:IsPlayer() or att:IsNPC()) or att == ent or Theirs(att) then return end
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
