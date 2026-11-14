--[[
    Living City: the Cremator

    The owner, 10 November: "for now they can just be an NPC that roams around
    burning bodies and if a rebel/enemy is nearby they can attack it". The
    Mortician job is left exactly as it was.

    lc_cremators of them (1; 0: none) walk the streets. One appears out of
    sight, and one killed is replaced, out of sight, five minutes later.

    GUARDIANS OF THE INFESTATION (the owner, 12 November): with an infestation
    marked, each guards one (the one with the fewest, then the nearest),
    walking between spots inside it or a little outside it, and burns only the
    dead in or near an infestation: the city's dead are the morticians', and
    no mortician goes into an infestation. When a cleanup crew is under guard
    there (a player on a shift, or one of the city's crews), the nearest free
    Cremator walks with them and burns what comes for them, then goes back to
    its post. With no infestation marked it walks the streets as before.

      a body          one that has lain lc_cremator_grace seconds (90) and that
                      nobody is hauling or has claimed: it walks over, burns it
                      where it lies, and the body is gone. Not while the
                      Administrator has stood the morticians down, and not on
                      Resistance ground.
      an enemy        whoever the units would shoot (LC.Violent: a gun in hand,
                      hurt someone lately, hunted), a zombie, one of the
                      Resistance's people out in the open, a headcrab or a
                      zombie, and anyone who attacks it: it walks at them and
                      burns them from FLAME units away. Civil Protection, the
                      Administration and an admin at work with the editor are
                      never enemies unless they attack it.

    THE MODEL comes from a Workshop addon on the server; the gamemode ships
    none. It is found by itself (LC.CrematorModel): lc_cremator_model if set,
    then any NPC an addon lists with "cremator" in its name, a few likely
    paths, a search of models/ for a *cremator*.mdl, and last a Cremator
    playermodel. With none there are no Cremators, and the debug report says so.

    HOW IT IS BUILT: nobody here knows which animations the installed model
    has, so the walking is done by an unseen npc_stalker (slow, Combine, and
    already proven on this gamemode's streets by the zone stalkers; its own
    animation is run lc_cremator_speed (2) times faster so it keeps up with
    the model's walk, LC.CrematorPace) and the
    Cremator seen is a prop_dynamic carried on it, playing whichever of the
    model's own sequences sounds like standing, walking and firing
    (LC.CrematorSequence: likely names first, then the model's list, scored).
    The ones used are logged and shown in the debug report.

    The flame is drawn by cl_livingcity_cremator.lua from "lc_flame_to" on the
    prop.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCount = CreateConVar("lc_cremators", "1", FLAGS, "Cremators walking the streets, burning the dead where they lie (0: none; needs a Cremator model from the Workshop on the server)")
local cvModel = CreateConVar("lc_cremator_model", "", FLAGS, "The Cremator's model (empty: found by itself among the server's addons)")
local cvGrace = CreateConVar("lc_cremator_grace", "90", FLAGS, "Seconds a body lies before a Cremator may burn it")
local cvSpeed = CreateConVar("lc_cremator_speed", "2", FLAGS, "How fast the Cremator walks, times the slow pace of the walker underneath (1: that pace; 0.5 to 4)")

-- The Workshop addons the owner chose (10 November): the NPC's, and the playermodel's.
LC.CREMATOR_WORKSHOP = { npc = "2090972521", player = "3329322225" }
-- Likely places for the model (tried after what the addons list themselves).
LC.CREMATOR_MODEL_CANDIDATES = { "models/cremator.mdl", "models/cremator_npc.mdl", "models/npc/cremator.mdl",
    "models/cremator/cremator.mdl", "models/hl2beta/cremator.mdl", "models/beta/cremator.mdl", "models/humans/cremator.mdl",
    "models/player/cremator.mdl", "models/player/cremator/cremator.mdl" }

local MAX = 4
local RESPAWN = 300
local HEALTH = 400
local SPOT, LOSE, FLAME = 520, 1000, 280
local BODY_RANGE, BODY_REACH, BURN_SECS = 3500, 150, 5
local UP = Vector(0, 0, 40)
local WEDGE_SECS, WEDGE_DIST = 20, 80 -- (getting nowhere: less than this far in this long, while trying to walk)

LC.Cremators = LC.Cremators or {} -- [carrier npc] = { npc, vis, phase, body, foe, ... }
local residents = LC.Cremators
local nextSpawn = 0

local function Call(e, m, ...) if IsValid(e) and e[m] then return e[m](e, ...) end end
local function Lower(s) return string.lower(tostring(s or "")) end
local function Has(s, word) return string.find(Lower(s), word, 1, true) ~= nil end

------------------------------------------------------------------------
-- The model
------------------------------------------------------------------------

local NOT_A_BODY = { "arms", "hands", "gib", "head", "ragdoll", "weapon", "immolator", "prop" }

local function Usable(m)
    if not isstring(m) or m == "" then return false end
    if not file.Exists(m, "GAME") then return false end
    return not util.IsValidModel or util.IsValidModel(m) ~= false
end

local function Search(dir, depth, out)
    local files, dirs = file.Find(dir .. "*", "GAME")
    for _, f in ipairs(files or {}) do
        if string.sub(f, -4) == ".mdl" and Has(f, "cremator") then out[#out + 1] = dir .. f end
    end
    for _, d in ipairs(dirs or {}) do
        if depth > 0 or Has(d, "cremator") then Search(dir .. d .. "/", Has(d, "cremator") and math.max(depth - 1, 1) or depth - 1, out) end
    end
end

-- Every Cremator model the server seems to have, best first.
function LC.CrematorModelsFound()
    local out, seen = {}, {}
    local function Add(m)
        if not isstring(m) then return end
        m = string.lower(m)
        if seen[m] then return end
        seen[m] = true
        local file_ = string.match(m, "([^/]+)$") or m
        for _, bad in ipairs(NOT_A_BODY) do if string.find(file_, bad, 1, true) then return end end
        if Usable(m) then out[#out + 1] = m end
    end
    local function AddAny(m) if istable(m) then for _, v in pairs(m) do Add(v) end else Add(m) end end
    -- an NPC an addon lists
    for key, t in pairs(list and list.Get and list.Get("NPC") or {}) do
        if istable(t) and (Has(key, "cremator") or Has(t.Name, "cremator") or Has(t.Class, "cremator")) then
            AddAny(t.Model)
            local stored = scripted_ents and scripted_ents.GetStored and t.Class and scripted_ents.GetStored(t.Class)
            if stored and istable(stored.t) then AddAny(stored.t.Model) end
        end
    end
    for _, m in ipairs(LC.CREMATOR_MODEL_CANDIDATES) do if not Has(m, "/player") then Add(m) end end
    if #out == 0 then
        local found = {}
        pcall(Search, "models/", 2, found)
        table.sort(found, function(a, b)
            local pa, pb = Has(a, "/player"), Has(b, "/player")
            if pa ~= pb then return pb end
            if #a ~= #b then return #a < #b end
            return a < b
        end)
        for _, m in ipairs(found) do Add(m) end
    end
    -- last, a playermodel (its walk needs the move_x pose, which the prop is given)
    for name, m in pairs(player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}) do
        if Has(name, "cremator") or Has(m, "cremator") then Add(m) end
    end
    for _, m in ipairs(LC.CREMATOR_MODEL_CANDIDATES) do Add(m) end
    return out
end

local modelCache -- { key, model or false }
function LC.CrematorModel(fresh)
    local want = string.Trim(cvModel:GetString())
    if LC.CrematorModelOverride then return LC.CrematorModelOverride end -- (the tests)
    if not fresh and modelCache and modelCache.key == want then return modelCache.model or nil end
    local model
    if want ~= "" and Usable(string.lower(want)) then model = string.lower(want) end
    if not model then model = LC.CrematorModelsFound()[1] end
    modelCache = { key = want, model = model or false }
    if LC.Log then
        LC.Log("info", model and ("cremator model: " .. model)
            or ("cremator model: none found" .. (want ~= "" and (" (lc_cremator_model '" .. want .. "' isn't on the server)") or "") .. "; no Cremators"))
    end
    return model
end

-- Players who join download the addon the model came from.
local function SendAddons()
    if not (engine and engine.GetAddons and resource and resource.AddWorkshop) then return end
    local have = {}
    for _, a in ipairs(engine.GetAddons() or {}) do
        if a.mounted ~= false then have[tostring(a.wsid or "")] = true end
    end
    local W = LC.CREMATOR_WORKSHOP
    if have[W.npc] then resource.AddWorkshop(W.npc)
    elseif have[W.player] then resource.AddWorkshop(W.player) end
end
SendAddons()
hook.Add("InitPostEntity", "LivingCityCrematorAddons", SendAddons)

------------------------------------------------------------------------
-- The animations
------------------------------------------------------------------------

local KINDS = {
    idle = { first = { "idle", "idle01", "idle_all_01", "idle_subtle", "idle1" },
        words = { { "idle", 4 }, { "stand", 2 } },
        bad = { "death", "die", "pain", "flinch", "walk", "run", "attack", "fire", "crouch", "swim", "jump", "sit", "angry", "weapon", "melee", "pistol", "smg", "ar2", "shotgun", "rpg", "grenade" } },
    walk = { first = { "walk", "walk01", "walk_all", "walk1", "walk_unarmed" },
        words = { { "walk", 4 } },
        bad = { "death", "die", "pain", "flinch", "crouch", "swim", "hurt", "aim", "fire", "attack", "melee", "pistol", "smg", "ar2", "shotgun", "rpg", "grenade", "hold" } },
    fire = { first = { "fire", "fireinout", "fire_loop", "attack", "attack1", "range_attack", "shoot" },
        words = { { "fire", 4 }, { "flame", 4 }, { "immolat", 4 }, { "burn", 3 }, { "attack", 3 }, { "shoot", 3 }, { "range", 2 }, { "aim", 1 } },
        bad = { "death", "die", "pain", "flinch", "walk", "run", "melee", "crouch", "swim", "jump", "reload" } },
}

local function Score(kind, name)
    local n = string.lower(name)
    for _, b in ipairs(kind.bad) do if string.find(n, b, 1, true) then return 0 end end
    local s = 0
    for _, w in ipairs(kind.words) do if string.find(n, w[1], 1, true) then s = s + w[2] end end
    -- the plainest name wins a tie ("walk" over "walk_panicked_all")
    return s > 0 and (s + 1 / (1 + #n)) or 0
end

local seqCache = {} -- [model] = { idle = name or false, ... }
LC.CrematorSequencesUsed = LC.CrematorSequencesUsed or nil

-- The model's own sequence for "idle", "walk" or "fire" (nil if it has nothing like it).
function LC.CrematorSequence(ent, what, fresh)
    local kind = KINDS[what]
    if not IsValid(ent) or not kind then return nil end
    local mdl = ent:GetModel() or ""
    seqCache[mdl] = seqCache[mdl] or {}
    local c = seqCache[mdl]
    if not fresh and c[what] ~= nil then return c[what] or nil end
    local name
    for _, cand in ipairs(kind.first) do
        local i = ent.LookupSequence and ent:LookupSequence(cand)
        if i and i >= 0 then name = cand break end
    end
    if not name and ent.GetSequenceList then
        local bs = 0
        for _, seq in pairs(ent:GetSequenceList() or {}) do
            local sc = Score(kind, tostring(seq))
            if sc > bs then name, bs = tostring(seq), sc end
        end
    end
    c[what] = name or false
    LC.CrematorSequencesUsed = string.format("idle '%s', walk '%s', fire '%s'", tostring(c.idle or "none"), tostring(c.walk or "none"), tostring(c.fire or "none"))
    if LC.Log then LC.Log("info", string.format("cremator %s animation: %s on %s", what, name and ("'" .. name .. "'") or "none found", mdl)) end
    return name
end

local function SetAnim(r, what)
    if r.anim == what or not IsValid(r.vis) then return end
    r.anim = what
    local name = LC.CrematorSequence(r.vis, what) or (what ~= "idle" and LC.CrematorSequence(r.vis, "idle")) or nil
    Call(r.vis, "SetPoseParameter", "move_x", what == "walk" and 1 or 0)
    if not name or r.seq == name then return end
    r.seq = name
    r.vis:Fire("SetDefaultAnimation", name)
    r.vis:Fire("SetAnimation", name)
end

------------------------------------------------------------------------
-- Friend and foe
------------------------------------------------------------------------

local function Combine(ply)
    if ply:GetNW2String("lcf_faction", "") == "cp" then return true end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return true end
    return LC.IsAdministrator ~= nil and LC.IsAdministrator(ply) == true
end

local function Alive(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return e:Alive() end
    return e.Health ~= nil and e:Health() > 0
end

-- Would this Cremator go for e?
function LC.CrematorEnemy(r, e, now)
    if not Alive(e) or e == r.npc then return false end
    if residents[e] then return false end
    now = now or CurTime()
    if r.gaveUp and (r.gaveUp[e] or 0) > now then return false end -- (it couldn't get to them)
    if e:IsPlayer() then
        if LC.EditorHeld and LC.EditorHeld(e) then return false end
        if e.GetMoveType and MOVETYPE_NOCLIP and e:GetMoveType() == MOVETYPE_NOCLIP then return false end
        if (r.provoked[e] or 0) > now then return true end
        if LC.PlayerIsZombie and LC.PlayerIsZombie(e) then return true end
        if Combine(e) then return false end
        return LC.Violent ~= nil and LC.Violent(e) == true
    end
    if not e:IsNPC() then return false end
    if (r.provoked[e] or 0) > now then return true end
    local st = LC.NPCs and LC.NPCs[e]
    if st then
        if st.test then return false end
        if st.role == "rebel" then return not st.casual end -- (acting casual: just a citizen, to them)
        return st.role == "zombie"
    end
    return LC.IsMonster ~= nil and LC.IsMonster(e) == true
end

local function Sees(r, e)
    if not r.npc.Visible then return true end
    return r.npc:Visible(e) == true
end

local function FindFoe(r, pos, now, blind)
    local best, bd
    for _, e in ipairs(ents.FindInSphere(pos, SPOT)) do
        if (e:IsPlayer() or e:IsNPC()) and LC.CrematorEnemy(r, e, now) and (blind or Sees(r, e)) then
            local d = e:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end

------------------------------------------------------------------------
-- The flame
------------------------------------------------------------------------

local function SetFlame(r, target, now)
    local t = IsValid(target) and target or NULL
    if r.flame == t then return end
    r.flame = t
    if IsValid(r.vis) then
        r.vis:SetNW2Entity("lc_flame_to", t)
        if IsValid(t) then r.vis:EmitSound("ambient/fire/gascan_ignite1.wav", 75, 110) end
    end
    r.nextHiss = (now or CurTime()) + 0.8
end

local function Hiss(r, now)
    if now < (r.nextHiss or 0) or not IsValid(r.vis) then return end
    r.nextHiss = now + 1.1
    r.vis:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(95, 115))
end

-- Small prey isn't set alight: the engine's fire stayed with what a headcrab or
-- bird left behind and sizzled on for minutes (the owner, 11 November). The
-- stream and the burn damage are enough for them.
local SMALL = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true,
    npc_pigeon = true, npc_crow = true, npc_seagull = true, npc_manhack = true }
function LC.CrematorIgnites(e)
    return IsValid(e) and e.Ignite ~= nil and not SMALL[e:GetClass()]
end

local function Scorch(r, e, now)
    if LC.CrematorIgnites(e) then e:Ignite(3, 0) end
    if DamageInfo and e.TakeDamageInfo then
        local d = DamageInfo()
        d:SetDamage(8)
        d:SetDamageType(DMG_BURN or 8)
        d:SetAttacker(r.npc)
        d:SetInflictor(r.npc)
        d:SetDamagePosition(e:WorldSpaceCenter())
        e:TakeDamageInfo(d)
    elseif e.TakeDamage then
        e:TakeDamage(8, r.npc, r.npc)
    end
    Hiss(r, now)
end

------------------------------------------------------------------------
-- The Cremators themselves
------------------------------------------------------------------------

local NEUTRAL = { "player", "npc_citizen", "npc_metropolice", "npc_combine_s", "npc_vortigaunt", "npc_stalker", "npc_zombie", "npc_zombie_torso",
    "npc_fastzombie", "npc_fastzombie_torso", "npc_poisonzombie", "npc_zombine", "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black",
    "npc_headcrab_poison", "npc_antlion", "npc_manhack", "npc_rollermine", "npc_turret_floor", "npc_cscanner", "npc_barnacle" }

-- Its pace (the owner, 11 November: "at least 2x faster in movement speed (not
-- animation speed)"). The unseen walker's own animation runs faster, and an NPC
-- moves as far as its animation carries it, so it covers the ground faster; the
-- model seen keeps its own walk at its own speed.
function LC.CrematorPace()
    return math.Clamp(cvSpeed:GetFloat(), 0.5, 4)
end

local function Pace(r)
    local rate = LC.CrematorPace()
    local now = Call(r.npc, "GetPlaybackRate")
    if now and math.abs(now - rate) < 0.01 then return end
    Call(r.npc, "SetPlaybackRate", rate)
end

-- The owner, 13 November: still slow ("INCREASE THEIR MOVEMENT SPEED! I requested both a few
-- days ago and it seems nothing has changed"): the engine goes on moving the walker at its own
-- pace whatever its animation's rate. So the ground it should cover is measured: every frame
-- it is walking, whatever it fell short of lc_cremator_speed times its own pace is made up
-- along the way it is going (never through a wall, never off a ledge or up a step too high).
local BASE_PACE = 45 -- (units a second: the walker's own slow walk)
function LC.CrematorBoost(r, dt)
    local npc = r.npc
    if not IsValid(npc) or r.dead or dt <= 0 or dt > 0.5 then return 0 end
    local pos = npc:GetPos()
    local last = r.boostPos
    r.boostPos = pos
    if not last then return 0 end
    local step = pos - last
    step.z = 0
    local went = step:Length()
    if went < 0.05 or went > 200 then return 0 end -- (standing, or set down somewhere else)
    local want = BASE_PACE * LC.CrematorPace() * dt
    local short = math.min(want - went, want)
    if short <= 0.05 then return 0 end
    local dir = step / went
    local up = Vector(0, 0, 18)
    local mins, maxs = Vector(-12, -12, 0), Vector(12, 12, 60)
    local fwd = util.TraceHull({ start = pos + up, endpos = pos + up + dir * short, mins = mins, maxs = maxs,
        filter = { npc, r.vis }, mask = MASK_NPCSOLID or MASK_SOLID })
    if not fwd or fwd.Hit or fwd.StartSolid then return 0 end
    local down = util.TraceHull({ start = fwd.HitPos or (pos + up + dir * short), endpos = (fwd.HitPos or (pos + up + dir * short)) - Vector(0, 0, 40),
        mins = mins, maxs = maxs, filter = { npc, r.vis }, mask = MASK_NPCSOLID or MASK_SOLID })
    if not down or not down.Hit or down.StartSolid then return 0 end
    local to = down.HitPos
    npc:SetPos(to)
    r.boostPos = to
    return short
end

hook.Add("Think", "LivingCityCrematorPace", function()
    if not LC.Running or not next(residents) then return end
    local dt = FrameTime()
    for npc, r in pairs(residents) do
        if IsValid(npc) then
            local ok, err = pcall(LC.CrematorBoost, r, dt)
            if not ok and LC.Error then LC.Error("cremator pace", err) end
        end
    end
end)

local function Walk(npc, pos)
    npc:SetLastPosition(pos)
    npc:SetSchedule(SCHED_FORCED_GO)
end

local function Stand(r)
    if r.standing then return end
    r.standing = true
    r.npc:SetSchedule(SCHED_IDLE_STAND)
end

local function Go(r, pos, now, every)
    if now < (r.nextWalk or 0) then return end
    r.nextWalk = now + (every or 3)
    r.standing = nil
    Walk(r.npc, pos)
end

local function SetDoing(r, text)
    if r.doing == text or not IsValid(r.npc) then return end
    r.doing = text
    if LC.SetNPCStr then LC.SetNPCStr(r.npc, "lc_doing", text or "") end
end

local Claim -- (with the bodies, below: Unclaim called a global Claim that isn't there, and errored)

local function Unclaim(r, skip)
    local b = r.body
    r.body = nil
    if IsValid(b) then
        Claim(b, false)
        if skip then b.lcCrematorSkip = CurTime() + 180 end
        if b.Extinguish and r.phase == "burn" then b:Extinguish() end
    end
end

-- A Cremator at pos: the unseen walker and the model on it. Returns its record.
function LC.SpawnCremator(pos, model, now)
    model = model or LC.CrematorModel()
    if not model then return nil end
    now = now or CurTime()
    local npc = ents.Create("npc_stalker")
    if not IsValid(npc) then return nil end
    npc:SetPos(pos + Vector(0, 0, 4))
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:Spawn()
    npc:Activate()
    for _, cls in ipairs(NEUTRAL) do Call(npc, "AddRelationship", cls .. " D_NU 99") end
    Call(npc, "SetKeyValue", "BeamPower", "0")
    Call(npc, "SetMaxHealth", HEALTH)
    Call(npc, "SetHealth", HEALTH)
    -- unseen: the model on it is the Cremator
    Call(npc, "SetRenderMode", RENDERMODE_TRANSALPHA or 4)
    Call(npc, "SetColor", Color(255, 255, 255, 0))
    Call(npc, "DrawShadow", false)
    Call(npc, "SetBloodColor", DONT_BLEED or -1)
    npc.lcCremator = true
    npc.lcNoBody = true
    npc:SetNW2Bool("lc_noragdoll", true)
    if LC.SetNPCStr then LC.SetNPCStr(npc, "lc_pname", "Cremator") end

    if util.PrecacheModel then util.PrecacheModel(model) end
    local vis = ents.Create("prop_dynamic")
    if not IsValid(vis) then npc:Remove() return nil end
    vis:SetModel(model)
    vis:SetPos(npc:GetPos())
    vis:SetAngles(npc:GetAngles())
    Call(vis, "SetKeyValue", "solid", "0")
    vis:Spawn()
    vis:Activate()
    Call(vis, "SetParent", npc)
    Call(vis, "SetLocalPos", Vector(0, 0, 0))
    Call(vis, "SetLocalAngles", Angle(0, 0, 0))
    vis:SetNW2Bool("lc_cremator", true)
    vis.lcCrematorOf = npc

    local r = { npc = npc, vis = vis, model = model, phase = "roam", provoked = setmetatable({}, { __mode = "k" }), calmed = setmetatable({}, { __mode = "k" }),
        lastPos = npc:GetPos(), lastMoved = now, pauseUntil = now + 2 }
    residents[npc] = r
    Pace(r)
    SetAnim(r, "idle")
    return r
end

local function Retire(r)
    Unclaim(r)
    residents[r.npc] = nil
    if IsValid(r.vis) then r.vis:Remove() end
    if IsValid(r.npc) then r.npc:Remove() end
end

-- Killed: the model falls where it stood, and another comes later.
function LC.CrematorDie(r, attacker)
    if r.dead then return end
    r.dead = true
    local npc, vis = r.npc, r.vis
    local pos = IsValid(npc) and npc:GetPos() or nil
    if pos then
        if sound and sound.Play then sound.Play("physics/metal/metal_canister_impact_hard3.wav", pos, 80, 90) end
        if util.IsValidRagdoll and util.IsValidRagdoll(r.model) then
            local rag = ents.Create("prop_ragdoll")
            if IsValid(rag) then
                rag:SetModel(r.model)
                rag:SetPos(pos)
                rag:SetAngles(npc:GetAngles())
                rag:Spawn()
                Call(rag, "SetCollisionGroup", COLLISION_GROUP_DEBRIS or 1)
                if SafeRemoveEntityDelayed then SafeRemoveEntityDelayed(rag, 90) end
            end
        end
    end
    nextSpawn = CurTime() + RESPAWN
    Retire(r)
    if pos then hook.Run("LivingCityCrematorKilled", attacker, pos) end
    if LC.Log then LC.Log("info", "a cremator was killed" .. (IsValid(attacker) and attacker:IsPlayer() and (" by " .. attacker:Nick()) or "")) end
end

------------------------------------------------------------------------
-- Guardians of the infestation (the owner, 12 November: "Cremators hang
-- around the infection area, whether a little bit outside or inside of it
-- ... morticians never go into the infested zones. Cremators are sort of
-- guardians of the infested zones, cleanup for them, and can escort the
-- infestation cleanup crews in too.")
------------------------------------------------------------------------

local TURF = 1200       -- this far outside an infestation is still its ground: the dead there are the Cremators'
local POST_OUT = 500    -- it stands guard inside one, or up to this far outside it
local ESCORT_NEAR, ESCORT_FAR, ESCORT_TAKE = 160, 300, 9000

local function Infests() return LC.ZonesOfKindShared and LC.ZonesOfKindShared("infest") or {} end

-- The infestation pos is in or near (the Cremators' ground), or nil.
function LC.CrematorTurf(pos)
    if not pos then return nil end
    for _, z in ipairs(Infests()) do
        if LCZ.Near(z, pos, TURF) then return z end
    end
    return nil
end

local function ZoneLive(z)
    if not z then return false end
    for _, o in ipairs(Infests()) do if o == z then return true end end
    return false
end

-- Which infestation it guards: the one with the fewest Cremators at it, then the nearest.
-- A placed zone before the patches grown out of it (those are beside it anyway).
function LC.CrematorPickZone(r, pos)
    local zs = Infests()
    if #zs == 0 then return nil end
    local count = {}
    for _, o in pairs(residents) do
        if o ~= r and o.zone then count[o.zone] = (count[o.zone] or 0) + 1 end
    end
    local best, bs
    for pass = 1, 2 do
        for _, z in ipairs(zs) do
            if pass == 2 or not z.grown then
                local s = (count[z] or 0) * 1e12 + (pos and z.pos and z.pos:DistToSqr(pos) or 0)
                if not bs or s < bs then best, bs = z, s end
            end
        end
        if best then break end
    end
    return best
end

-- Somewhere to stand guard: a path node in the infestation or a little outside it
-- (never on Resistance ground), else somewhere inside it. Kept half a minute per zone.
function LC.CrematorPostSpot(z)
    if not z then return nil end
    local now = CurTime()
    if not z.lcCremPosts or now > (z.lcCremPostsT or 0) then
        local picks = {}
        for _, n in pairs(LC.Nodes or {}) do
            local p = n.pos
            if p and LCZ.Near(z, p, POST_OUT) and not (LC.InRebelZone and LC.InRebelZone(p)) then picks[#picks + 1] = p end
        end
        z.lcCremPosts, z.lcCremPostsT = picks, now + 30
    end
    local picks = z.lcCremPosts
    if #picks > 0 then return picks[math.random(#picks)] end
    return LCZ.RandomInside and LCZ.RandomInside(z, 0.8) or z.pos
end

-- The path node nearest infestation z that ok(pos) allows (never on Resistance ground),
-- looking no further than `reach` (3000) from it.
function LC.CrematorNearestNode(z, ok, reach)
    if not (z and z.pos) then return nil end
    reach = reach or 3000
    local best, bd
    for _, n in pairs(LC.Nodes or {}) do
        local p = n.pos
        if p then
            local d = p:DistToSqr(z.pos)
            if d < reach * reach and (not bd or d < bd) and not (LC.InRebelZone and LC.InRebelZone(p)) and (not ok or ok(p)) then
                best, bd = p, d
            end
        end
    end
    return best
end

-- A street spot nobody can see (by an infestation, when there is one).
local function HiddenSpot(z)
    z = z or LC.CrematorPickZone(nil, nil)
    if z then
        for _ = 1, 12 do
            local p = LC.CrematorPostSpot(z)
            if p and not (LC.IsSeen and LC.IsSeen(p + UP)) and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 600)) then return p end
        end
    end
    -- still none: the path nodes nearest the infestation, nearest first (the owner, 13 November:
    -- "spawn right at the entrance/path nodes nearest the infestation zone"), before anywhere else
    if z and z.pos then
        local p = LC.CrematorNearestNode(z, function(q)
            return not (LC.IsSeen and LC.IsSeen(q + UP)) and (not LC.FarFromPlayers or LC.FarFromPlayers(q, 300))
        end)
        if p then return p end
    end
    if not LC.RandomWanderPos then return nil end
    for _ = 1, 12 do
        local p = LC.RandomWanderPos("cop")
        if p and not (LC.IsSeen and LC.IsSeen(p + UP)) and (not LC.FarFromPlayers or LC.FarFromPlayers(p, 600))
            and not (LC.InRebelZone and LC.InRebelZone(p)) then return p end
    end
    return nil
end

local function Count()
    local n = 0
    for npc in pairs(residents) do if IsValid(npc) then n = n + 1 end end
    return n
end

-- Keep the streets staffed: out of sight, one at a time.
function LC.CrematorsStaff(now)
    local want = math.Clamp(cvCount:GetInt(), 0, MAX)
    local model = want > 0 and LC.CrematorModel() or nil
    if not model then want = 0 end
    local n = Count()
    if n > want then
        for _, r in pairs(residents) do
            if n <= want then break end
            Retire(r)
            n = n - 1
        end
    elseif n < want and now >= nextSpawn then
        nextSpawn = now + 15
        local pos = HiddenSpot()
        if pos then LC.SpawnCremator(pos, model, now) end
    end
end

-- The body it would see to next.
-- What a dead headcrab or bird leaves is an item, not a body: the Cremator burns those too
-- (the owner, 11 November: it never came for the headcrabs it had killed).
local CARCASS = { raw_bird = true, raw_crow = true, raw_gull = true }
function LC.CrematorCarcass(e)
    if not IsValid(e) or e:GetClass() ~= "lc_item" then return false end
    return (LC.CrabCarcass and LC.CrabCarcass(e)) or CARCASS[e:GetNW2String("lc_item", "")] == true
end

function Claim(body, on)
    if body.lcBody then body.lcBody.claimed = on or nil else body.lcBagging = on or nil end
end

function LC.CrematorBody(pos, now)
    if LC.MorticiansSuspended and LC.MorticiansSuspended() then return nil end -- (stood down: the dead wait)
    local grace = math.max(0, cvGrace:GetFloat())
    local best, bd = nil, BODY_RANGE * BODY_RANGE
    -- with an infestation on the map, the dead in the city are the morticians'; the Cremators
    -- see to those in or near the infestation (where no mortician goes)
    local turfOnly = #Infests() > 0
    for _, b in ipairs(LC.Bodies or {}) do
        local e = b.ent
        if IsValid(e) and e.lcBody and not e.lcBody.claimed and not e.lcOnCart and not (LC.HauledBy and LC.HauledBy(e))
            and now - (b.born or now) >= grace and (e.lcCrematorSkip or 0) <= now
            and not (LC.InRebelZone and LC.InRebelZone(e:GetPos())) and (not turfOnly or LC.CrematorTurf(e:GetPos())) then
            local d = e:GetPos():DistToSqr(pos)
            if d < bd then best, bd = e, d end
        end
    end
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_item") or {}) do
        if LC.CrematorCarcass(e) and not e.lcBagging and not e.lcStalkerTaken and not (e.GetParent and IsValid(e:GetParent()))
            and now - (e.lcBorn or now) >= grace and (e.lcCrematorSkip or 0) <= now
            and not (LC.InRebelZone and LC.InRebelZone(e:GetPos())) and (not turfOnly or LC.CrematorTurf(e:GetPos())) then
            local d = e:GetPos():DistToSqr(pos)
            if d < bd then best, bd = e, d end
        end
    end
    return best
end

local function Burnt(r, body)
    local pos = body:GetPos()
    r.body = nil
    if util.Decal then util.Decal("Scorch", pos + Vector(0, 0, 12), pos - Vector(0, 0, 40), body) end
    if sound and sound.Play then sound.Play("ambient/fire/ignite.wav", pos, 70, 80) end
    if body.Extinguish then body:Extinguish() end -- (or its fire's sound can stay behind)
    body:Remove()
    r.burnt = (r.burnt or 0) + 1
    LC.CrematorsBurnt = (LC.CrematorsBurnt or 0) + 1
    hook.Run("LivingCityCremated", r.npc, body, nil)
end

local function Fight(r, foe, pos, now)
    local npc = r.npc
    SetDoing(r, "burning out a threat")
    -- (the walker underneath never fights for itself)
    if npc.AddEntityRelationship then npc:AddEntityRelationship(foe, D_NU, 99) end
    local fp = foe:GetPos()
    if pos:DistToSqr(fp) < FLAME * FLAME and Sees(r, foe) then
        Stand(r)
        if LC.Face then LC.Face(npc, fp) end
        SetAnim(r, "fire")
        SetFlame(r, foe, now)
        Scorch(r, foe, now)
    else
        SetFlame(r, nil, now)
        SetAnim(r, "walk")
        Go(r, fp, now, 1.5)
    end
end

-- Is pos close enough to an infestation for a Cremator to walk with a crew there?
function LC.CrematorEscortHere(pos)
    if not pos then return false end
    for _, z in ipairs(Infests()) do
        if LCZ.Near(z, pos, TURF * 1.5) then return true end
    end
    return false
end

-- A cleanup worker under guard (sv_livingcity_cleanup.lua: a player on a shift by an
-- infestation, or one of the city's crews at it) that no other Cremator walks with.
function LC.CrematorEscortWanted(r, pos)
    local best, bd
    for w in pairs(LC.CleanupGuards or {}) do
        if Alive(w) then
            local taken = false
            for _, o in pairs(residents) do
                if o ~= r and o.escort == w then taken = true break end
            end
            local d = w:GetPos():DistToSqr(pos)
            -- only a crew at an infestation (the owner, 13 November: one walked "escorting" as far
            -- from the infestation as the map goes, with nobody there)
            if not taken and LC.CrematorEscortHere(w:GetPos()) and d < ESCORT_TAKE * ESCORT_TAKE and (not bd or d < bd) then best, bd = w, d end
        end
    end
    return best
end

-- Walking with the crew: close behind them, its flame on whatever comes for them.
local function Escort(r, pos, now, moved)
    local w = r.escort
    SetFlame(r, nil, now)
    SetDoing(r, "escorting the cleanup crew")
    local wp = w:GetPos()
    local d = pos:DistToSqr(wp)
    if d > ESCORT_FAR * ESCORT_FAR or (d > ESCORT_NEAR * ESCORT_NEAR and not r.standing) then
        SetAnim(r, "walk")
        local away = pos - wp
        away.z = 0
        local len = away:Length()
        local spot = len > 1 and (wp + away * (ESCORT_NEAR * 0.7 / len)) or wp
        Go(r, spot, now, 1.5)
    else
        Stand(r)
        SetAnim(r, moved and "walk" or "idle")
        if LC.Face then LC.Face(r.npc, wp) end
        if d > ESCORT_FAR * ESCORT_FAR * 0.5 then r.standing = nil end -- (falling behind: catch up)
    end
end

local function Think(r, now)
    local npc = r.npc
    Pace(r) -- again each time: the walker's AI may set its animation back
    local pos = npc:GetPos()
    local moved = pos:DistToSqr(r.lastPos) > 3 * 3
    if moved then r.lastPos, r.lastMoved = pos, now end
    -- Pushing at something it can't get round (a barricade set down with the editor: the owner,
    -- 11 November, watched one walk into them for 15 minutes) still shuffles a little, so
    -- "hasn't moved" misses it: every 20 seconds, has it got anywhere?
    local wanting = r.foe ~= nil or r.phase == "tobody" or (r.phase == "roam" and r.dest ~= nil)
    local wedged = false
    if not r.anchor or now - r.anchorT >= WEDGE_SECS then
        wedged = r.anchor ~= nil and wanting and not r.standing and pos:DistToSqr(r.anchor) < WEDGE_DIST * WEDGE_DIST
        r.anchor, r.anchorT = pos, now
        r.wedgedN = wedged and (r.wedgedN or 0) + 1 or nil
    end
    local stuck = now - r.lastMoved > 20 or wedged
    if wedged then
        -- give up on what it was after, and after a while start again somewhere else
        if r.foe then r.gaveUp = r.gaveUp or setmetatable({}, { __mode = "k" }) r.gaveUp[r.foe] = now + 60 r.foe = nil end
        local n = r.wedgedN or 0
        if n >= 2 and (n >= 6 or not (LC.IsSeen and LC.IsSeen(pos + UP))) then
            local p = HiddenSpot(ZoneLive(r.zone) and r.zone or nil)
            if p then
                if r.body then Unclaim(r, true) end
                npc:SetPos(p + Vector(0, 0, 4))
                r.phase, r.dest, r.wedgedN, r.anchor, r.lastPos, r.lastMoved = "roam", nil, nil, nil, p, now
                SetFlame(r, nil, now)
                return
            end
        end
    end

    -- an enemy comes before everything
    local foe = r.foe
    if foe and not (LC.CrematorEnemy(r, foe, now) and foe:GetPos():DistToSqr(pos) < LOSE * LOSE) then foe = nil end
    if not foe and now >= (r.nextLook or 0) then
        r.nextLook = now + 1
        foe = FindFoe(r, pos, now)
        -- walking with a cleanup crew: whatever comes for them too, seen or not (it goes round to it)
        if not foe and Alive(r.escort) then foe = FindFoe(r, r.escort:GetPos(), now, true) end
    end
    if foe ~= r.foe then r.foe, r.nextWalk = foe, 0 end
    if foe then
        if r.phase == "burn" then r.phase = "tobody" end
        Fight(r, foe, pos, now)
        return
    end

    -- a cleanup crew going in: the nearest free Cremator walks with them, then back to its post
    if r.phase == "roam" and now >= (r.nextEscortLook or 0) then
        r.nextEscortLook = now + 2
        if r.escort and not (Alive(r.escort) and LC.CleanupGuards and LC.CleanupGuards[r.escort]
            and LC.CrematorEscortHere(r.escort:GetPos())) then
            r.escort, r.dest, r.pauseUntil = nil, nil, now + 2
        end
        if not r.escort then
            local w = LC.CrematorEscortWanted(r, pos)
            if w then
                r.escort, r.dest, r.nextWalk, r.standing = w, nil, 0, nil
                r.escorted = (r.escorted or 0) + 1
                if w:IsPlayer() and LC.Notice then
                    LC.Notice(w, "info", "A Cremator", "A Cremator is coming to walk with you. It burns whatever comes for you while you work.")
                end
            end
        end
    end
    if r.escort and not Alive(r.escort) then r.escort, r.dest = nil, nil end -- (gone between two looks: a NULL entity, 13 November)
    if r.phase == "roam" and r.escort then
        Escort(r, pos, now, moved)
        return
    end

    if r.phase == "roam" and now >= (r.nextBody or 0) then
        r.nextBody = now + 3
        local body = LC.CrematorBody(pos, now)
        if body then
            Claim(body, true)
            r.body, r.phase, r.nextWalk, r.lastMoved = body, "tobody", 0, now
        end
    end

    if r.phase == "tobody" then
        local body = r.body
        SetFlame(r, nil, now)
        if not IsValid(body) or (LC.HauledBy and LC.HauledBy(body)) or body.lcOnCart then
            Unclaim(r) r.phase = "roam" -- (someone else saw to it)
        elseif pos:DistToSqr(body:GetPos()) < BODY_REACH * BODY_REACH then
            r.phase, r.untilT = "burn", now + BURN_SECS
            Stand(r)
            if LC.Face then LC.Face(npc, body:GetPos()) end
            if body.Ignite then body:Ignite(BURN_SECS + 2, 0) end
        elseif stuck then
            Unclaim(r, true) r.phase, r.lastMoved = "roam", now
        else
            SetDoing(r, "going to a body")
            SetAnim(r, moved and "walk" or "idle")
            Go(r, body:GetPos(), now, 3)
        end
    elseif r.phase == "burn" then
        local body = r.body
        if not IsValid(body) or (LC.HauledBy and LC.HauledBy(body)) then
            SetFlame(r, nil, now)
            Unclaim(r) r.phase = "roam"
        else
            SetDoing(r, "burning a body")
            SetAnim(r, "fire")
            SetFlame(r, body, now)
            Hiss(r, now)
            if now >= r.untilT then
                SetFlame(r, nil, now)
                Burnt(r, body)
                r.phase, r.pauseUntil, r.dest = "roam", now + 3, nil
            end
        end
    end

    if r.phase == "roam" then
        -- its infestation (gone, or none yet: the one most in need of a guard)
        if not ZoneLive(r.zone) then r.zone, r.dest = LC.CrematorPickZone(r, pos), nil end
        SetFlame(r, nil, now)
        SetDoing(r, r.zone and "guarding the infestation" or "")
        SetAnim(r, moved and "walk" or "idle")
        local there = r.dest and pos:DistToSqr(r.dest) < 90 * 90
        if there then r.dest, r.pauseUntil = nil, now + math.Rand(4, 12) Stand(r) end
        if r.dest and stuck then r.dest, r.lastMoved = nil, now end
        if not r.dest and now >= (r.pauseUntil or 0) then
            if r.zone then
                r.dest = LC.CrematorPostSpot(r.zone)
            elseif LC.RandomWanderPos then
                r.dest = LC.RandomWanderPos("cop", pos) or LC.RandomWanderPos("cop")
            end
            r.nextWalk, r.lastMoved = 0, now
        end
        if r.dest then Go(r, r.dest, now, 5) end
    end
end

-- The city's own people take no notice of it (the Resistance's do).
local function Calm(r)
    for other, st in pairs(LC.NPCs or {}) do
        if IsValid(other) and not r.calmed[other] and st.role ~= "rebel" and other.AddEntityRelationship then
            r.calmed[other] = true
            other:AddEntityRelationship(r.npc, D_NU, 99)
        end
    end
end

function LC.CrematorsThink(now)
    for npc, r in pairs(residents) do
        if not IsValid(npc) or not IsValid(r.vis) or npc:Health() <= 0 then
            if not r.dead then
                nextSpawn = now + RESPAWN
                Retire(r)
            end
        else
            Think(r, now)
            if now >= (r.nextCalm or 0) then
                r.nextCalm = now + 10
                Calm(r)
            end
        end
    end
end

-- One step of it all (the timer below; the tests call it directly).
function LC.CrematorsTick(now)
    LC.CrematorsStaff(now)
    LC.CrematorsThink(now)
end

timer.Create("LivingCityCremators", 0.5, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.CrematorsTick, CurTime())
    if not ok and LC.Error then LC.Error("cremators", err) end
end)

hook.Add("LivingCityStopped", "LivingCityCremators", function()
    for _, r in pairs(residents) do Retire(r) end
    nextSpawn = 0
end)

-- Fire does nothing to it; whoever hurts it is an enemy, and the units nearby come.
-- Nothing it killed goes on burning (the fire's sound stayed with the dead).
hook.Add("OnNPCKilled", "LivingCityCrematorFire", function(npc, attacker)
    if IsValid(npc) and IsValid(attacker) and attacker.lcCremator and npc.Extinguish then npc:Extinguish() end
end)

hook.Add("EntityTakeDamage", "LivingCityCremator", function(victim, dmg)
    local r = residents[victim]
    if not r or r.dead then return end
    if dmg:IsDamageType(DMG_BURN or 8) then return true end
    local a = dmg:GetAttacker()
    local now = CurTime()
    if IsValid(a) and a ~= victim and (a:IsPlayer() or a:IsNPC()) and not residents[a] then
        r.provoked[a] = now + 90
        if a:IsPlayer() and not Combine(a) and LC.MakeCopsHostile and now >= (r.nextAlarm or 0) then
            r.nextAlarm = now + 10
            LC.MakeCopsHostile(a, victim:GetPos(), 1200)
        end
    end
    if victim:Health() - dmg:GetDamage() <= 0 then
        LC.CrematorDie(r, a)
        return true
    end
end)

-- In the debug report (People).
function LC.CrematorSummary()
    local n, busy, foes, guarding, escorting, streets = 0, 0, 0, 0, 0, 0
    for npc, r in pairs(residents) do
        if IsValid(npc) then
            n = n + 1
            if r.body then busy = busy + 1 end
            if r.foe then foes = foes + 1 end
            if r.escort then escorting = escorting + 1
            elseif ZoneLive(r.zone) then guarding = guarding + 1
            else streets = streets + 1 end
        end
    end
    local model = LC.CrematorModel()
    return string.format("Cremators: %d (want %d), %d guarding the infestation, %d escorting a cleanup crew, %d on the streets (%d infestations marked), %d at a body, %d fighting, %d bodies burnt; model: %s; animations: %s",
        n, math.Clamp(cvCount:GetInt(), 0, MAX), guarding, escorting, streets, #Infests(), busy, foes, LC.CrematorsBurnt or 0,
        model or "none found (add a Cremator model from the Workshop, or set lc_cremator_model)", tostring(LC.CrematorSequencesUsed or "not chosen yet"))
end

-- An extra for admins: one where you're looking, and what was found.
concommand.Add("lc_cremator_spawn", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local function Say(t) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, t .. "\n") ply:ChatPrint(t) else print(t) end end
    local model = LC.CrematorModel(true)
    if not model then
        Say("No Cremator model was found on the server. Add one from the Workshop to the server's collection, or set lc_cremator_model to its path.")
        return
    end
    if not IsValid(ply) then Say("Cremator model: " .. model) return end
    local r = LC.SpawnCremator(ply:GetEyeTrace().HitPos, model)
    Say(r and ("A Cremator, model " .. model .. "; animations: " .. tostring(LC.CrematorSequencesUsed)) or "The Cremator couldn't be made.")
    -- for sending back when it looks wrong: every model found, and every animation this one has (console only)
    ply:PrintMessage(HUD_PRINTCONSOLE, "[cremator] models found: " .. table.concat(LC.CrematorModelsFound(), ", ") .. "\n")
    if r and IsValid(r.vis) and r.vis.GetSequenceList then
        local names = {}
        for _, n in pairs(r.vis:GetSequenceList() or {}) do names[#names + 1] = tostring(n) end
        table.sort(names)
        for i = 1, #names, 12 do
            ply:PrintMessage(HUD_PRINTCONSOLE, "[cremator] animations: " .. table.concat(names, ", ", i, math.min(i + 11, #names)) .. "\n")
        end
    end
end)
