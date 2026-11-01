--[[
    Living City: weedkiller against the infestation, and against the Combine (the owner, 2026-11-01)

    Growths in the infestation
      Every infestation (the zones you place, and the patches that grow out of them) has growths in
      it: lumps of Xen growth, nests of glowing grubs, the dead it has taken. They glow a sickly green
      and give off spores, so you can see where the infestation is from the street. Spray one with
      weedkiller (look at it, E) and it shrivels away. Spray every growth in a patch that grew and the
      patch goes: the infestation shrinks. Spray out the zone you placed and nothing grows or spawns
      there for a while. Growths come back, one at a time, every lc_nest_regrow_minutes (6).
      They're Half-Life: Alyx's Xen gunk when the server has the owner's workshop pack (2043900984),
      else built-in Half-Life 2 and Episode 2 models. lc_infest_nest_models: your own (comma separated).
      With that pack, a Combine warning post (sign, lamp, barrel) stands at the edge of each
      infestation (lc_infest_hazard_posts), and the cleanup crew bags up what they spray.

    Infestation Cleanup (a Union job, the 15th)
      Into the infestation in a respirator (it keeps out gas, chlorine and weedkiller alike), with
      weedkiller, to spray the growths. While they're near an infestation on a shift, lc_cleanup_guards
      (2) Civil Protection units or Overwatch soldiers come and guard them, and shoot the infested
      that come for them. The city's own cleanup crews do it too, with a guard of their own. A cleanup
      shift counts as lc_cleanup_shift_counts (2) Records Clerk shifts towards joining Civil
      Protection. With the owner's Infestation Control pack (3185145650) on the server, players on
      the job and the city's own crews wear its hazmat suit ("worker"), a man the male one and a woman
      the female one, each their own skin (lc_cleanup_suit; lc_cleanup_model: another model instead);
      and Morticians, Sanitation Workers and the Reclamation Crew wear its "engineer" overalls.

    Barnacles
      A barnacle eats whatever it pulls up. Drop weedkiller (or anything tainted with it) under one:
      it chews, and dies.

    The firebomb (the Resistance lab: two weedkiller, an empty bottle and a rag)
      Armour doesn't keep out fire. Where it breaks it burns for lc_firebomb_secs (12): it sets alight
      anyone in it, units and soldiers included; it burns out power banks, forcefields and turrets
      for 90 seconds; and it burns growths away.

    Poison gas is the Combine's now (sold to units at the Civil Protection Commissary): a mask keeps
    it out. Sweeps into rebel ground open with a gas bomb now and then (lc_sweep_gas, 0.5).
    An Insider can foul the filter stock at the Commissary (sv_livingcity_insider.lua): for
    lc_fouled_minutes (20) every unit's mask lets gas through, theirs and the Resistance's alike.

      lc_infest_nests 0/1 (1), lc_infest_nests_per_patch (4), lc_nest_regrow_minutes (6),
      lc_infest_nest_models (""), lc_infest_hazard_posts (1), lc_cleanup_guards (2), lc_cleanup_shift_counts (2),
      lc_cleanup_model (""), lc_cleanup_suit (worker), lc_firebomb_secs (12), lc_sweep_gas (0.5), lc_fouled_minutes (20)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvNests   = CreateConVar("lc_infest_nests", "1", FLAGS, "Growths in the infestation, glowing, that weedkiller sprays away (and the infestation shrinks)")
local cvPer     = CreateConVar("lc_infest_nests_per_patch", "4", FLAGS, "Growths in each patch of infestation")
local cvRegrow  = CreateConVar("lc_nest_regrow_minutes", "6", FLAGS, "Minutes for a growth to come back in a patch that's lost one")
local cvModels  = CreateConVar("lc_infest_nest_models", "", FLAGS, "Your own models for the growths, comma separated (empty: the built-in ones)")
local cvGuards  = CreateConVar("lc_cleanup_guards", "2", FLAGS, "Civil Protection units or soldiers who guard a cleanup worker near an infestation")
local cvCounts  = CreateConVar("lc_cleanup_shift_counts", "2", FLAGS, "Records Clerk shifts each Infestation Cleanup shift counts as, towards joining Civil Protection")
local cvModel   = CreateConVar("lc_cleanup_model", "", FLAGS, "A player model for Infestation Cleanup workers (a hazmat suit, say; empty: their own)")
local cvFire    = CreateConVar("lc_firebomb_secs", "12", FLAGS, "Seconds a firebomb burns where it breaks")
local cvSweep   = CreateConVar("lc_sweep_gas", "0.5", FLAGS, "Chance a sweep into rebel ground opens with a poison gas bomb (0 to 1)")
local cvFouled  = CreateConVar("lc_fouled_minutes", "20", FLAGS, "Minutes units' mask filters let gas through after an Insider fouls them")

LC.CleanupShiftCounts = function() return math.max(1, cvCounts:GetInt()) end

------------------------------------------------------------------------
-- Fouled filters
------------------------------------------------------------------------

LC.FouledUntil = LC.FouledUntil or 0
function LC.FiltersFouled() return CurTime() < (LC.FouledUntil or 0) end
function LC.FoulFilters(secs)
    LC.FouledUntil = math.max(LC.FouledUntil or 0, CurTime() + (secs or math.max(1, cvFouled:GetFloat()) * 60))
    return LC.FouledUntil
end

------------------------------------------------------------------------
-- The respirator, and the suit
------------------------------------------------------------------------

local function OnCleanup(ply)
    local job = IsValid(ply) and LC.Job and LC.Job(ply)
    return job and job.id == "cleanup" or false
end
LC.OnCleanupJob = OnCleanup
function LC.CleanupRespirator(ply) return IsValid(ply) and ply:IsPlayer() and OnCleanup(ply) end

-- The Infestation Control crew from Half-Life: Alyx (the owner's workshop pack 3185145650), through Job
-- outfits (sv_livingcity_outfits.lua), so the city's own people in these jobs wear them too: a man the
-- male model, a woman the female one, each their own skin. The owner, 2026-11-01: the "worker" suits are
-- the hazmat suits (filter and air tank), for Infestation Cleanup; the "engineer" ones have neither, for
-- the dirty jobs (Mortician, Sanitation Worker, Reclamation Crew). Only while a job has no outfit of its
-- own: set one in the editor (Job outfits) and that's worn instead. Worn only for the work (the owner): a
-- player on a shift, one of the city's people doing the job; going home, their own clothes. lc_cleanup_suit: the cleanup job's
-- suit (worker); lc_cleanup_model: another player model for it instead.
local function Valid(m) return not util.IsValidModel or util.IsValidModel(m) end
local cvSuit = CreateConVar("lc_cleanup_suit", "worker", FLAGS, "Which Infestation Control suit cleanup workers wear, if the server has the pack: worker (the hazmat suit) or engineer")
local DIRTY = { mortuary = "engineer", sanitation = "engineer", scrap = "engineer" }

local function SuitOutfit(suit)
    local pm, npc = "models/player/" .. suit .. "_{sex}.mdl", "models/npc/" .. suit .. "_{sex}.mdl"
    if not Valid((string.gsub(pm, "{sex}", "male"))) then return nil end
    -- every skin it has, each person their own
    local n = 1
    pcall(function()
        local info = util.GetModelInfo and util.GetModelInfo((string.gsub(npc, "{sex}", "male")))
        n = math.max(1, tonumber(info and info.SkinCount) or 1)
    end)
    local skins = {}
    for i = 0, n - 1 do skins[#skins + 1] = i end
    return { pm = pm, npc = npc, skins = skins }
end
function LC.CleanupOutfit()
    local own = cvModel:GetString()
    if own ~= "" and Valid(own) then return { pm = own } end
    return SuitOutfit(cvSuit:GetString() == "engineer" and "engineer" or "worker")
end
local function EnsureOutfit()
    local all = LC.Outfits or (LC.LoadOutfits and LC.LoadOutfits())
    if not all then return end
    local want = { cleanup = LC.CleanupOutfit() }
    for job, suit in pairs(DIRTY) do want[job] = SuitOutfit(suit) end
    for job, e in pairs(want) do
        local cur = all[job]
        if not cur or cur.lcAuto then -- (never over the owner's own outfit for the job)
            all[job] = e and { list = { e }, lcAuto = true, onDuty = true } or nil -- (worn only for the work)
        end
    end
end
LC.EnsureCleanupOutfit = EnsureOutfit

hook.Add("LivingCityJobChanged", "LivingCityCleanup", function(ply, id)
    if not IsValid(ply) then return end
    EnsureOutfit()
    if id == "cleanup" then
        if LC.GiveItem and not LC.HasItem(ply, "weedkiller") then LC.GiveItem(ply, "weedkiller", 1) end
        ply:ChatPrint("[Union] You're issued a respirator and weedkiller. Shifts take you into the infestation: look at a growth and press E to spray it. Civil Protection will guard you.")
    end
end)
timer.Simple(1, EnsureOutfit)
for _, n in ipairs({ "lc_cleanup_suit", "lc_cleanup_model" }) do
    cvars.AddChangeCallback(n, function() EnsureOutfit() end, "LivingCityCleanup")
end

------------------------------------------------------------------------
-- Growths
------------------------------------------------------------------------

-- { model, scale, colour }: the first of each that the server has
local BUILTIN = {
    { "models/props_wasteland/antlionhill.mdl", 0.22, Color(150, 175, 90) },  -- a lump of Xen growth
    { "models/antlion_grub.mdl", 1.6, Color(170, 230, 120) },               -- grubs (Episode 2)
    { "models/humans/charple01.mdl", 1, Color(120, 140, 90) },               -- what it took
    { "models/props_wasteland/antlionhill.mdl", 0.15, Color(130, 160, 80) },
}
local FALLBACK = { "models/props_junk/garbage_bag001a.mdl", 1.2, Color(120, 170, 80) }
-- Half-Life: Alyx's Xen gunk, from the owner's workshop pack (2043900984): used instead whenever the server has it
local GUNK = "models/hlvr/distillery_gunk/distillerygunk_gunk.mdl"
local GUNKS = { { GUNK, 0.7, Color(255, 255, 255) }, { GUNK, 1, Color(255, 255, 255) }, { GUNK, 1.3, Color(255, 255, 255) } }

local function PickLook()
    local own = {}
    for m in string.gmatch(cvModels:GetString(), "[^,%s]+") do if Valid(m) then own[#own + 1] = m end end
    if #own > 0 then return own[math.random(#own)], 1, Color(255, 255, 255) end
    local ok = {}
    for _, b in ipairs(Valid(GUNK) and GUNKS or BUILTIN) do if Valid(b[1]) then ok[#ok + 1] = b end end
    local b = #ok > 0 and ok[math.random(#ok)] or FALLBACK
    return b[1], b[2], b[3]
end
LC.NestLook = PickLook

local function Nests()
    local out = {}
    for _, e in ipairs(ents.FindByClass("lc_nest")) do if IsValid(e) then out[#out + 1] = e end end
    return out
end
LC.Nests = Nests

local function NestsIn(z)
    local n, list = 0, {}
    for _, e in ipairs(Nests()) do if e.lcZone == z then n = n + 1 list[n] = e end end
    return n, list
end
LC.NestsIn = NestsIn

function LC.SpawnNest(z, pos)
    pos = pos or (LC.SpotInZone and LC.SpotInZone(z))
    if not pos then return nil end
    local e = ents.Create("lc_nest")
    if not IsValid(e) then return nil end
    local m, scale, col = PickLook()
    e.lcModel = m
    e:SetPos(pos)
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    if e.SetModel then e:SetModel(m) end
    if e.SetModelScale then e:SetModelScale(scale or 1, 0) end
    if e.SetColor and col then e:SetColor(col) end
    e.lcZone = z
    z.lcNested = true
    return e
end

------------------------------------------------------------------------
-- The Combine's hazard props (the same workshop pack; nothing if the server hasn't got it): a
-- warning post at the edge of each infestation, and a sprayed growth bagged up for a while.
------------------------------------------------------------------------

local cvPosts = CreateConVar("lc_infest_hazard_posts", "1", FLAGS, "A Combine warning post (sign, lamp, barrel) at the edge of each infestation, if the server has the hazard props")
local HZ = "models/hlvr/combine_hazardprops/combinehazardprops_"
local POST = { { "warningsign", 0, 0 }, { "lamp", 50, 30 }, { "barrel", -45, 25 } } -- (model, sideways, back)

local function Prop(model, pos, ang)
    if not Valid(model) then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(pos)
    e:SetAngles(ang or Angle(0, 0, 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcHazardProp = true
    return e
end

local function Reach(z)
    if z.box then return math.min(z.box.maxs.x - z.box.mins.x, z.box.maxs.y - z.box.mins.y) / 2 end
    return z.r or 300
end

function LC.HazardPost(z)
    if not Valid(HZ .. "warningsign.mdl") then return nil end
    local centre = z.box and (z.box.mins + z.box.maxs) / 2 or z.pos
    for _ = 1, 8 do
        local yaw = math.random(0, 359)
        local dir = Angle(0, yaw, 0):Forward()
        local at = (LC.GroundAt or function(p) return p end)(centre + dir * (Reach(z) + 50) + Vector(0, 0, 30))
        if not (LC.InInfest and LC.InInfest(at)) then
            local face = Angle(0, yaw, 0) -- (the sign faces out, at whoever's walking in)
            local right, back = face:Right(), -dir
            local made = {}
            for _, p in ipairs(POST) do
                local e = Prop(HZ .. p[1] .. ".mdl", at + right * p[2] + back * p[3], face)
                if e then e.lcHazardZone = z made[#made + 1] = e end
            end
            return made
        end
    end
    return nil
end

local function PostTick(zones, alive)
    for _, e in ipairs(ents.FindByClass("prop_physics")) do
        if IsValid(e) and e.lcHazardZone and (not alive[e.lcHazardZone] or not cvPosts:GetBool()) then e:Remove() end
    end
    if not cvPosts:GetBool() then return end
    for _, z in ipairs(zones) do
        if not z.lcPostTried then z.lcPostTried = true LC.HazardPost(z) end
    end
end

-- a sprayed growth, bagged by the cleanup crew, left for collection
local function Bag(pos)
    local e = Prop(HZ .. "trashbag.mdl", pos + Vector(0, 0, 4), Angle(0, math.random(0, 359), 0))
    if e then timer.Simple(90, function() if IsValid(e) then e:Remove() end end) end
    return e
end
LC.HazardBag = Bag

local function InfestZones()
    local out = {}
    for _, z in ipairs(LC.Zones or {}) do if z.kind == "infest" then out[#out + 1] = z end end
    return out
end

-- A growth gone (sprayed, burned): the patch it was in may go with it.
function LC.ClearNest(e, by)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" or e.lcCleared then return false end
    e.lcCleared = true
    local z = e.lcZone
    if IsValid(by) and (by:IsPlayer() and OnCleanup(by) or not by:IsPlayer()) then Bag(e:GetPos()) end -- (the crew bags it up)
    if e.EmitSound then e:EmitSound("npc/barnacle/barnacle_die" .. math.random(1, 2) .. ".wav", 70) end
    e:Remove()
    if IsValid(by) and by:IsPlayer() then
        LC.QuestEvent("nest_cleared", by, e)
        if LC.AddXP then LC.AddXP(by, 3, "Infestation growth cleared") end
    end
    hook.Run("LivingCityNestCleared", by, z)
    if not z then return true end
    z.lcNestNext = CurTime() + math.max(1, cvRegrow:GetFloat()) * 60
    if NestsIn(z) > 0 then return true end
    if z.grown then
        if LC.RecedeTerritory then LC.RecedeTerritory(z, "sprayed out", IsValid(by) and by:IsPlayer() and by or nil) end
    else
        -- the zone you placed is never taken away: it goes quiet for a while instead
        if LC.QuietInfestation then LC.QuietInfestation(z.pos, (z.r or 400) + 200) end
        local s = LC.TerritoryState and LC.TerritoryState[z]
        if s then s.nextGrow = math.max(s.nextGrow or 0, CurTime() + 600) end
        if IsValid(by) and by:IsPlayer() then by:ChatPrint("[Union] The last of the growth here shrivels. It'll be quiet for a while, but it always comes back.") end
    end
    return true
end

-- Spraying one: a few seconds, close up.
function LC.SprayNest(ply, e)
    if not IsValid(e) or e:GetClass() ~= "lc_nest" then return false end
    if not LC.HasItem(ply, "weedkiller") then return false, "You'd need weedkiller to spray it (the Union Commissary sells it)." end
    if (ply.lcSprayNext or 0) > CurTime() then return false end
    ply.lcSprayNext = CurTime() + 0.5
    local function Done(p) LC.ClearNest(e, p) end
    if not LC.StartTask then Done(ply) return true end
    ply:EmitSound("ambient/water/water_spray1.wav", 55)
    return LC.StartTask(ply, 4, "Spraying the growth...", { maxMove = 60, cancelText = "You stop spraying.", done = Done })
end

local function NestTick(now)
    if not cvNests:GetBool() or not LC.Running then
        for _, e in ipairs(Nests()) do e:Remove() end
        return
    end
    local zones, alive = InfestZones(), {}
    for _, z in ipairs(zones) do alive[z] = true end
    for _, e in ipairs(Nests()) do if not alive[e.lcZone] then e:Remove() end end -- (its patch is gone)
    PostTick(zones, alive)
    local per = math.max(0, cvPer:GetInt())
    for _, z in ipairs(zones) do
        local n = NestsIn(z)
        if n < per and not (LC.InfestQuietAt and LC.InfestQuietAt(z.pos)) then
            if not z.lcNestFirst then
                z.lcNestFirst = true
                for _ = n + 1, per do LC.SpawnNest(z) end -- (a new patch arrives with its growths)
            elseif now >= (z.lcNestNext or 0) then
                z.lcNestNext = now + math.max(1, cvRegrow:GetFloat()) * 60 * math.Rand(0.75, 1.25)
                local p = LC.SpotInZone and LC.SpotInZone(z)
                if p and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 30))) then LC.SpawnNest(z, p) end
            end
        end
    end
end
LC.NestTick = NestTick
timer.Create("LivingCityNests", 10, 0, function()
    local ok, err = pcall(NestTick, CurTime())
    if not ok and LC.Error then LC.Error("nests", err) end
end)

------------------------------------------------------------------------
-- Guards for the cleanup crew
------------------------------------------------------------------------

LC.CleanupGuards = LC.CleanupGuards or {} -- [worker] = { units = {}, nextLook }

local FREE = { idle = true, moving = true, working = true }
local function FreeUnit(npc, st, now)
    return IsValid(npc) and LC.IsSecurity(st) and st.role ~= "scanner" and npc:Health() > 0 and FREE[st.state]
        and not st.workEscort and not st.raid and not st.questLock and not st.escortee and not st.subject
        and not st.skirmish and not st.cleanGuard and not st.holdPos and not st.guardZone and (st.stunnedUntil or 0) < now
end

local function Release(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.cleanGuard = nil
    if npc.SetNW2String then npc:SetNW2String("lc_doing", "") end
    if st.state == "cleanguard" then
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 2
    end
end

local function Assign(worker, g, now)
    local want = math.max(0, cvGuards:GetInt())
    local live = {}
    for _, u in ipairs(g.units) do
        local st = IsValid(u) and LC.NPCs[u]
        if st and u:Health() > 0 and st.cleanGuard == worker and st.state == "cleanguard" then live[#live + 1] = u
        elseif st and st.cleanGuard == worker then st.cleanGuard = nil end
    end
    g.units = live
    if #live >= want or now < (g.nextLook or 0) then return end
    g.nextLook = now + 5
    local wpos = worker:GetPos()
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if FreeUnit(npc, st, now) then
            local d = npc:GetPos():DistToSqr(wpos)
            if d < 6000 * 6000 then cands[#cands + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    for i = 1, math.min(#cands, want - #live) do
        local c = cands[i]
        if LC.Release then LC.Release(c.npc, c.st) end
        if LC.NPCWorkReset then LC.NPCWorkReset(c.npc, c.st) end
        c.st.cleanGuard = worker
        c.st.route, c.st.routeTo, c.st.goingTo = nil, nil, nil
        LC.SetState(c.npc, c.st, "cleanguard")
        if c.npc.SetNW2String then c.npc:SetNW2String("lc_doing", "guarding the cleanup crew") end
        g.units[#g.units + 1] = c.npc
        if worker:IsPlayer() and not g.told then
            g.told = true
            worker:ChatPrint("[Union] Civil Protection is sending you a guard. Stay close to them in there.")
        end
    end
end

-- The infested nearest the worker, if any are close.
local function Threat(worker)
    local wpos, best, bd = worker:GetPos(), nil, nil
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "zombie" and npc:Health() > 0 then
            local d = npc:GetPos():DistToSqr(wpos)
            if d < 1100 * 1100 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

local function Drive(worker, g, now)
    local z = Threat(worker)
    for i, u in ipairs(g.units) do
        if IsValid(u) then
            if IsValid(z) then
                -- shoot it
                if u.SetEnemy then u:SetEnemy(z) end
                if u.UpdateEnemyMemory then u:UpdateEnemyMemory(z, z:GetPos()) end
                if u.IsCurrentSchedule and u.SetSchedule and not u:IsCurrentSchedule(SCHED_RANGE_ATTACK1) then
                    u:SetSchedule(u:GetPos():DistToSqr(z:GetPos()) > 700 * 700 and SCHED_CHASE_ENEMY or SCHED_RANGE_ATTACK1)
                end
            else
                -- keep close, one on each side
                local d = u:GetPos():DistToSqr(worker:GetPos())
                if d > 170 * 170 and u.SetLastPosition and u.SetSchedule then
                    local side = (worker.GetRight and worker:GetRight() or Vector(1, 0, 0)) * (i % 2 == 0 and 70 or -70)
                    local back = (worker.GetForward and worker:GetForward() or Vector(0, 1, 0)) * -60
                    u:SetLastPosition(worker:GetPos() + side + back)
                    if not (u.IsCurrentSchedule and (u:IsCurrentSchedule(SCHED_FORCED_GO) or u:IsCurrentSchedule(SCHED_FORCED_GO_RUN))) or d > 600 * 600 then
                        u:SetSchedule(d > 500 * 500 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                    end
                end
            end
        end
    end
end

-- Who needs guarding: a player on a cleanup shift near an infestation, or an NPC worker who asked.
local function NeedsGuard(w, now)
    if not IsValid(w) then return false end
    if w:IsPlayer() then
        if not w:Alive() or not OnCleanup(w) then return false end
        local q = LC.QuestOf and LC.QuestOf[w]
        if not q or q.chain ~= "shift" then return false end
        for _, z in ipairs(InfestZones()) do
            if w:GetPos():DistToSqr(z.pos) < ((z.r or 400) + 1500) ^ 2 then return true end
        end
        return false
    end
    return w:Health() > 0 and (w.lcGuardUntil or 0) > now
end

function LC.CleanupGuard(worker, secs)
    if not IsValid(worker) then return end
    if not worker:IsPlayer() then worker.lcGuardUntil = CurTime() + (secs or 90) end
    LC.CleanupGuards[worker] = LC.CleanupGuards[worker] or { units = {} }
end

local function GuardTick(now)
    -- players who've just walked up to an infestation on a shift
    for _, p in ipairs(player.GetAll()) do
        if not LC.CleanupGuards[p] and NeedsGuard(p, now) then LC.CleanupGuards[p] = { units = {} } end
    end
    for w, g in pairs(LC.CleanupGuards) do
        if not NeedsGuard(w, now) then
            for _, u in ipairs(g.units) do Release(u) end
            LC.CleanupGuards[w] = nil
        else
            Assign(w, g, now)
            Drive(w, g, now)
        end
    end
end
LC.CleanupGuardTick = GuardTick
timer.Create("LivingCityCleanupGuards", 0.5, 0, function()
    local ok, err = pcall(GuardTick, CurTime())
    if not ok and LC.Error then LC.Error("cleanup guards", err) end
end)

-- The city's own cleanup crews: spray the growths, with a guard.
if LC.AddNPCTask then
    LC.AddNPCTask("cleanup", { id = "nests", label = "clearing the infestation", weight = 3, find = function(npc, st, now)
        local best, bd
        for _, e in ipairs(Nests()) do
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 4000 * 4000 and (not bd or d < bd) then best, bd = e, d end
        end
        if not best then return nil end
        local e = best
        return { key = "nest" .. e:EntIndex(), steps = {
            { infest = true, pos = function(n) return LC.NPCWorkBeside and LC.NPCWorkBeside(e:GetPos(), n:GetPos(), 50) or e:GetPos() end,
              face = function() return e:GetPos() end, check = function() return IsValid(e) end, secs = 6, doing = "spraying the infestation",
              onGo = function(n) LC.CleanupGuard(n, 120) end,
              done = function(n) if IsValid(e) then e:EmitSound("ambient/water/water_spray1.wav", 60) LC.ClearNest(e, n) end n.lcGuardUntil = 0 end },
        } }
    end })
end

------------------------------------------------------------------------
-- Barnacles eat weedkiller
------------------------------------------------------------------------

local function Toxic(id) return id == "weedkiller" or string.sub(id, 1, 8) == "tainted_" end

local function BarnacleTick()
    for _, b in ipairs(ents.FindByClass("npc_barnacle")) do
        if IsValid(b) and b:Health() > 0 and not b.lcPoisoned then
            for _, e in ipairs(ents.FindInSphere(b:GetPos(), 80)) do
                if IsValid(e) and e:GetClass() == "lc_item" and Toxic(e:GetNW2String("lc_item", "")) then
                    b.lcPoisoned = true
                    e:Remove()
                    if b.EmitSound then b:EmitSound("npc/barnacle/barnacle_crunch2.wav", 75) end
                    timer.Simple(1.5, function()
                        if not IsValid(b) or b:Health() <= 0 then return end
                        if b.EmitSound then b:EmitSound("npc/barnacle/barnacle_die2.wav", 80) end
                        b:TakeDamage(b:Health() + 100, game.GetWorld(), game.GetWorld())
                    end)
                    break
                end
            end
        end
    end
end
LC.BarnacleTick = BarnacleTick
timer.Create("LivingCityBarnacles", 0.5, 0, function()
    local ok, err = pcall(BarnacleTick)
    if not ok and LC.Error then LC.Error("barnacles", err) end
end)

------------------------------------------------------------------------
-- The firebomb
------------------------------------------------------------------------

local FIRE_R = 170
LC.Fires = LC.Fires or {}

function LC.Firebomb(pos, owner)
    local now, secs = CurTime(), math.max(1, cvFire:GetFloat())
    if sound and sound.Play then
        sound.Play("physics/glass/glass_bottle_break" .. math.random(1, 2) .. ".wav", pos, 80)
        sound.Play("ambient/fire/ignite.wav", pos, 85)
    end
    -- the flames: the engine's own fire
    pcall(function()
        local f = ents.Create("env_fire")
        if not IsValid(f) then return end
        f:SetPos(pos)
        f:SetKeyValue("health", tostring(secs))
        f:SetKeyValue("firesize", "110")
        f:SetKeyValue("fireattack", "1")
        f:SetKeyValue("damagescale", "0")
        f:SetKeyValue("spawnflags", tostring(4 + 128))
        f:Spawn()
        f:Fire("StartFire", "", 0)
        timer.Simple(secs + 1, function() if IsValid(f) then f:Remove() end end)
    end)
    LC.Fires[#LC.Fires + 1] = { pos = pos, untilT = now + secs, owner = owner }
    -- Combine machinery nearby burns out
    for _, e in ipairs(ents.FindInSphere(pos, FIRE_R + 80)) do
        if IsValid(e) and LC.VortZapTech then LC.VortZapTech(nil, e, 90) end
    end
    if IsValid(owner) and owner:IsPlayer() and LC.SeenBySecurity and LC.SeenBySecurity(owner, 900) then
        LC.ReportCrime(owner, "Firebombing", 300)
    end
    hook.Run("LivingCityFirebomb", pos, owner)
end

local function FireTick(now)
    for i = #LC.Fires, 1, -1 do
        local f = LC.Fires[i]
        if now > f.untilT then
            table.remove(LC.Fires, i)
        else
            local attacker = IsValid(f.owner) and f.owner or game.GetWorld()
            for _, e in ipairs(ents.FindInSphere(f.pos, FIRE_R)) do
                if IsValid(e) then
                    if e:GetClass() == "lc_nest" then
                        LC.ClearNest(e, IsValid(f.owner) and f.owner or nil)
                    elseif (e:IsPlayer() and e:Alive()) or (e.IsNPC and e:IsNPC() and e:Health() > 0) then
                        if e.Ignite then e:Ignite(3) end
                        e:TakeDamage(6, attacker, attacker)
                    end
                end
            end
        end
    end
end
LC.FireTick = FireTick
timer.Create("LivingCityFires", 0.5, 0, function()
    local ok, err = pcall(FireTick, CurTime())
    if not ok and LC.Error then LC.Error("fires", err) end
end)

------------------------------------------------------------------------
-- A sweep opens with gas
------------------------------------------------------------------------

hook.Add("LivingCitySweepArrived", "LivingCityCleanupGas", function(sk, u)
    if not sk or not sk.zone or math.random() >= cvSweep:GetFloat() or not LC.Detonate then return end
    -- into the thick of them: the nearest rebel to the unit, else the middle of their ground
    local spot
    if IsValid(u) then
        local bd
        for _, r in ipairs(sk.rebels or {}) do
            if IsValid(r) and r:Health() > 0 then
                local d = r:GetPos():DistToSqr(u:GetPos())
                if not bd or d < bd then spot, bd = r:GetPos(), d end
            end
        end
        if u.EmitSound then u:EmitSound("npc/metropolice/vo/movein.wav", 80) end
    end
    spot = spot or sk.zone.pos
    timer.Simple(1.5, function() LC.Detonate("poison", spot, IsValid(u) and u or nil) end)
end)
