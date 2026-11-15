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

    Getting her out after an attempt on her life is not built yet: it waits on
    the owner's answers (TODO.md).

    lc_admin_grenade_jump 1/0
    Hook: LivingCityAdminAttempt (her, who, how): someone tried to kill her.
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
