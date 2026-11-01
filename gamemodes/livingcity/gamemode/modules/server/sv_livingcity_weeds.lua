--[[
    Living City: weeds, the Groundskeeper, and weedkiller (the owner, 2026-11-01)

    Weeds come up out of the cracks on open ground (somewhere the sky is
    straight overhead), now and then: a tuft, then weeds, then a bush, every
    lc_weed_grow_minutes (8). A bush left alone seeds another nearby. At most
    lc_weeds_max (30) at once.

    The Groundskeeper (a Union job) is issued weedkiller and sprays them: look
    at one and press E (a bigger one takes longer). The city's own
    groundskeepers do it too. Anyone with weedkiller can spray one.

    Weedkiller is poison as well. From your pockets (F2 > Weedkiller >
    Poison food or drink), one canister taints the first food or drink you
    carry: it looks exactly the same, to you and to anyone you give it to,
    and whoever eats or drinks it is poisoned (a unit who sees you do it calls
    it attempted murder). Two canisters cook down into chemicals at the
    Resistance lab, for its recipes. The Union Commissary sells it.

      lc_weeds 0/1 (1), lc_weeds_max (30), lc_weed_grow_minutes (8)
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_weeds", "1", FLAGS, "Weeds grow on open ground, and the Groundskeeper sprays them")
local cvMax  = CreateConVar("lc_weeds_max", "30", FLAGS, "Most weeds growing at once")
local cvGrow = CreateConVar("lc_weed_grow_minutes", "8", FLAGS, "Minutes for a weed to grow a size (a tuft, weeds, a bush)")

-- The first plant that exists. Garry's Mod has shipped with the Episode 2 and Counter-Strike: Source models built in
-- since July 2025, so every player sees these.
local MODELS = { "models/props_foliage/shrub_01a.mdl", "models/props/de_inferno/bushgreensmall.mdl", "models/props/cs_militia/fern01.mdl",
    "models/props/cs_office/plant01.mdl", "models/props_lab/cactus.mdl" }
local chosen
local cvModel = CreateConVar("lc_weed_model", "", FLAGS, "The weeds' model (empty: the first plant the server has, an Episode 2 shrub first)")
function LC.WeedModel()
    local m = cvModel:GetString()
    if m ~= "" and (not util.IsValidModel or util.IsValidModel(m)) then return m end
    if chosen then return chosen end
    for _, m in ipairs(MODELS) do if not util.IsValidModel or util.IsValidModel(m) then chosen = m return m end end
    chosen = MODELS[#MODELS]
    return chosen
end
local SCALE = { 0.35, 0.65, 1.0 }

local function Weeds()
    local out = {}
    for _, e in ipairs(ents.FindByClass("lc_weed")) do if IsValid(e) then out[#out + 1] = e end end
    return out
end
LC.Weeds = Weeds

local function SetStage(e, n)
    e.lcStage = n
    e:SetNW2Int("lc_stage", n)
    if e.SetModelScale then e:SetModelScale(SCALE[n] or 1, 0.5) end
    e.lcGrowAt = CurTime() + math.max(1, cvGrow:GetFloat()) * 60
end

-- Open ground: the sky straight overhead, and not in anyone's camp or a Combine area.
local function OpenGround(pos)
    if not pos then return false end
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
    if not (tr and tr.HitSky) then return false end
    if LC.InNoGo and LC.InNoGo(pos) then return false end
    if LC.InRebelZone and LC.InRebelZone(pos) then return false end
    return true
end
LC.WeedOpenGround = OpenGround

function LC.SpawnWeed(pos, stage)
    if not pos or #Weeds() >= cvMax:GetInt() then return nil end
    local e = ents.Create("lc_weed")
    if not IsValid(e) then return nil end
    e:SetPos(pos)
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    SetStage(e, stage or 1)
    return e
end

local nextSprout = 0
local function WeedTick(now)
    if not cvOn:GetBool() or not LC.Running then return end
    -- growing, and the big ones seeding
    for _, e in ipairs(Weeds()) do
        if now >= (e.lcGrowAt or now + 1) then
            if (e.lcStage or 1) < 3 then
                SetStage(e, (e.lcStage or 1) + 1)
            else
                e.lcGrowAt = now + math.max(1, cvGrow:GetFloat()) * 60
                local p = e:GetPos() + Vector(math.Rand(-150, 150), math.Rand(-150, 150), 0)
                p = LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40)) or p
                if OpenGround(p) then LC.SpawnWeed(p, 1) end
            end
        end
    end
    -- a new one now and then
    if now >= nextSprout then
        nextSprout = now + math.Rand(45, 120)
        local p = LC.RandomWanderPos and LC.RandomWanderPos("citizen")
        if p and OpenGround(p) and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 20))) then LC.SpawnWeed(p, 1) end
    end
end
LC.WeedTick = WeedTick
timer.Create("LivingCityWeeds", 5, 0, function()
    local ok, err = pcall(WeedTick, CurTime())
    if not ok and LC.Error then LC.Error("weeds", err) end
end)

-- Spraying one: a moment for a tuft, longer for a bush.
function LC.SprayWeed(ply, e)
    if not IsValid(e) or e:GetClass() ~= "lc_weed" then return false end
    if not LC.HasItem(ply, "weedkiller") then return false, "You'd need weedkiller (the Union Commissary sells it; the Groundskeeper is issued it)." end
    if (ply.lcSprayNext or 0) > CurTime() then return false end
    ply.lcSprayNext = CurTime() + 0.5
    local secs = ({ 1.5, 3, 5 })[e.lcStage or 1] or 3
    local function Done(p)
        if not IsValid(e) then return end
        e:EmitSound("ambient/water/water_spray1.wav", 60)
        e:Remove()
        LC.QuestEvent("weed_killed", p, e)
        hook.Run("LivingCityWeedKilled", p)
    end
    if not LC.StartTask then Done(ply) return true end
    ply:EmitSound("ambient/water/water_spray1.wav", 55)
    return LC.StartTask(ply, secs, "Spraying the weeds...", { maxMove = 50, cancelText = "You stop spraying.", done = Done })
end

------------------------------------------------------------------------
-- Weedkiller as poison
------------------------------------------------------------------------

function LC.PoisonFood(ply)
    if not LC.HasItem(ply, "weedkiller") then return false, "You've no weedkiller." end
    local pick
    for id, n in pairs(LC.Inventory(ply) or {}) do
        local it = LCS.Items[id]
        if n > 0 and LCS.Items["tainted_" .. id] and not it.tainted then pick = id break end
    end
    if not pick then return false, "You've nothing to eat or drink to put it in." end
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 600) then
        LC.ReportCrime(ply, "Attempted murder: poisoning food", 300)
        return false, "A Civil Protection unit saw you tip it in. You're wanted."
    end
    LC.TakeItem(ply, "weedkiller", 1)
    LC.TakeItem(ply, pick, 1)
    LC.GiveItem(ply, "tainted_" .. pick, 1)
    ply:ChatPrint(string.format("[Pockets] A few drops of weedkiller into the %s. It looks no different, and nobody will taste it until it's too late.", string.lower(LCS.Items[pick].name)))
    return true
end
LC.SlashCommands.poison = function(ply) local ok, why = LC.PoisonFood(ply) if not ok and why then ply:ChatPrint(why) end end
if LC.MenuActions then LC.MenuActions.poison = true end

------------------------------------------------------------------------
-- The Groundskeeper: issued weedkiller; their shifts and the city's own
------------------------------------------------------------------------

hook.Add("LivingCityJobChanged", "LivingCityWeeds", function(ply, id)
    if id == "groundskeeper" and IsValid(ply) and not LC.HasItem(ply, "weedkiller") then
        LC.GiveItem(ply, "weedkiller", 1)
        ply:ChatPrint("[Union] You're issued a canister of weedkiller. Look at a weed and press E to spray it.")
    end
end)

if LC.AddNPCTask then
    LC.AddNPCTask("groundskeeper", { id = "weeds", label = "spraying weeds", weight = 3, find = function(npc, st, now)
        local best, bd
        for _, e in ipairs(Weeds()) do
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 3000 * 3000 and (not bd or d < bd) then best, bd = e, d end
        end
        if not best then return nil end
        local e = best
        return { key = "weed" .. e:EntIndex(), steps = {
            { pos = function(n) return LC.NPCWorkBeside and LC.NPCWorkBeside(e:GetPos(), n:GetPos(), 40) or e:GetPos() end,
              face = function() return e:GetPos() end, check = function() return IsValid(e) end, secs = 4, doing = "spraying weeds",
              done = function() if IsValid(e) then e:EmitSound("ambient/water/water_spray1.wav", 60) e:Remove() end end },
        } }
    end })
end
