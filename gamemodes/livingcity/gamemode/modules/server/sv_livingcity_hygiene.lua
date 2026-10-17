--[[
    Living City: toilets, baths and what happens without them

    Parasites (sv_livingcity_survival.lua) don't just make you hungry and
    thirsty. They build an urge (lc_urge_minutes, 6, from nothing to
    can't-hold-it). Sit on a toilet (E on one: the map's own, or the editor's
    "Fixture: toilet") for a few seconds and it's gone, for now, but it
    dehydrates you: drink something after. Only antiparasitic tablets end it.

    Leave it too long and you soil yourself: a stain on your trousers and on
    the ground under you. Then, until you've seen to all three, you're filthy:
      - the toilet, still
      - a wash (E on a bathtub or a shower: the map's, or "Fixture: bathtub")
      - clean clothes (put on spare citizen clothes or Union overalls from
        your pockets, or F1 > What now? > Change into clean clothes)
    Filthy, you stink: flies follow you, people step back from you (the city's
    own and the players near you are told why), and anyone who stays close
    may catch your parasites (lc_stink_spread, 3% every five seconds).

    The stain on the ground stays until somebody scrubs it: a Sanitation
    Worker (E on it, paid, and they risk catching something), anyone else
    (unpaid, same risk), or the city's own sanitation crews.

      lc_hygiene 0/1, lc_urge_minutes (6), lc_stink_spread (0.03)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_hygiene", "1", FLAGS, "Parasites make you need a toilet; ignore it and you soil yourself (a wash and clean clothes to put it right)")
local cvUrge   = CreateConVar("lc_urge_minutes", "6", FLAGS, "Minutes for parasites to take you from fine to can't-hold-it")
local cvSpread = CreateConVar("lc_stink_spread", "0.03", FLAGS, "Chance every five seconds that someone close to a filthy person catches their parasites")

local CLOTHES = { civvies = true, cwu_overalls = true }

local function Pick(t) return t[math.random(#t)] end
local function Notice(ply, kind, title, text, secs) if LC.Notice then LC.Notice(ply, kind, title, text, secs) else ply:ChatPrint(title .. ": " .. text) end end
local function Exempt(ply) return not ply:Alive() or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) or ply:GetNW2String("lcf_faction", "") == "admin" end

------------------------------------------------------------------------
-- Toilets, baths and beds: the editor's, and the map's own
------------------------------------------------------------------------

local CLASS_KIND = { lc_toilet = "toilet", lc_bath = "bath", lc_bed = "bed" }
local MODEL_KIND = { { "toilet", "toilet" }, { "bathtub", "bath" }, { "bath_tub", "bath" }, { "shower", "bath" } }

function LC.AmenityKindForModel(model)
    model = string.lower(model or "")
    if model == "" then return nil end
    for _, k in ipairs(MODEL_KIND) do if string.find(model, k[1], 1, true) then return k[2] end end
    if LC.RestKindForModel and LC.RestKindForModel(model) == "bed" then return "bed" end
    return nil
end

function LC.AmenityKindOf(ent)
    if not IsValid(ent) then return nil end
    local k = CLASS_KIND[ent:GetClass()]
    if k then return k end
    if string.StartWith(ent:GetClass(), "lc_") or ent:IsPlayer() or ent:IsNPC() then return nil end
    return LC.AmenityKindForModel(ent:GetModel())
end

-- Every one of a kind the city knows of: { pos, ent? }
function LC.Amenities(kind)
    local out = {}
    for cls, k in pairs(CLASS_KIND) do
        if k == kind then for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or {}) do out[#out + 1] = { pos = e:GetPos(), ent = e } end end
    end
    for _, fx in ipairs(LC.StaticFixtures or {}) do if fx.kind == kind then out[#out + 1] = { pos = fx.pos } end end
    if kind == "bed" then
        for _, r in ipairs(LC.StaticRest or {}) do if r.kind == "bed" then out[#out + 1] = { pos = r.pos } end end
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("bunk") or {}) do out[#out + 1] = { pos = p.pos } end
    end
    -- loose ones the map placed as props (looked for once a minute, not every time)
    LC.AmenityProps = LC.AmenityProps or {}
    if (LC.AmenityPropsAt or 0) < CurTime() then
        LC.AmenityPropsAt = CurTime() + 60
        local found = { toilet = {}, bath = {}, bed = {} }
        for _, cls in ipairs({ "prop_physics", "prop_physics_multiplayer", "prop_dynamic", "prop_static" }) do
            for _, e in ipairs(ents.FindByClass(cls)) do
                local k = LC.AmenityKindForModel(e:GetModel())
                if k and found[k] then found[k][#found[k] + 1] = e end
            end
        end
        LC.AmenityProps = found
    end
    for _, e in ipairs(LC.AmenityProps[kind] or {}) do if IsValid(e) then out[#out + 1] = { pos = e:GetPos(), ent = e } end end
    return out
end

function LC.NearestAmenity(kind, pos)
    local best, bd
    for _, a in ipairs(LC.Amenities(kind)) do
        local d = a.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = a, d end
    end
    return best
end

-- Waypoints: F1 > What now? > Places, and the next step (sv_livingcity_notices.lua)
local function Way(kind, label, none)
    return function(ply)
        local a = LC.NearestAmenity(kind, ply:GetPos())
        if a then return a.pos, label end
        return nil, none
    end
end
local function RegisterPlaces()
    if not LC.WaypointPlaces then return end
    LC.WaypointPlaces.toilet = Way("toilet", "Toilet", "No toilets found in this city.")
    LC.WaypointPlaces.bath = Way("bath", "Bathtub", "No bathtubs or showers found in this city.")
    LC.WaypointPlaces.bed = Way("bed", "Bed", "No beds found in this city.")
    LC.WaypointPlaces.stain = function(ply)
        local best, bd
        for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_stain") or {}) do
            local d = e:GetPos():DistToSqr(ply:GetPos())
            if not bd or d < bd then best, bd = e, d end
        end
        if best then return best:GetPos(), "A mess to clean" end
        return nil, "Nothing to clean up right now."
    end
end
hook.Add("Initialize", "LivingCityHygienePlaces", RegisterPlaces)
hook.Add("InitPostEntity", "LivingCityHygienePlaces", RegisterPlaces)
RegisterPlaces()

------------------------------------------------------------------------
-- The urge, and the state you're in
------------------------------------------------------------------------

function LC.Urge(ply) return ply:GetNW2Float("lc_urge", 0) end
local function SetUrge(ply, v) ply:SetNW2Float("lc_urge", math.Clamp(v, 0, 100)) end

-- What a soiled person still has to do: "toilet", "wash", "clothes"
local function Needs(ply)
    ply.lcSoil = ply.lcSoil or {}
    return ply.lcSoil
end
local function Sync(ply)
    local n = Needs(ply)
    local left = {}
    for _, k in ipairs({ "toilet", "wash", "clothes" }) do if n[k] then left[#left + 1] = k end end
    ply:SetNW2String("lc_soil_need", table.concat(left, ","))
    ply:SetNW2Bool("lc_stink", n.wash == true or n.clothes == true)
    if #left == 0 then ply:SetNW2Bool("lc_soiled", false) end
end
function LC.IsFilthy(ply) return ply:GetNW2Bool("lc_stink", false) end
function LC.SoilNeeds(ply) return Needs(ply) end

local function Clear(ply)
    ply.lcSoil = {}
    ply.lcUrgeWarn = 0
    SetUrge(ply, 0)
    ply:SetNW2Bool("lc_soiled", false)
    Sync(ply)
    if ply.RemoveAllDecals then ply:RemoveAllDecals() end
end
LC.HygieneClear = Clear

-- A stain where they stood.
function LC.SpawnStain(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 20), endpos = pos - Vector(0, 0, 120), mask = MASK_SOLID_BRUSHONLY })
    local at = (tr and tr.Hit) and tr.HitPos or pos
    local e = ents.Create("lc_stain")
    if not IsValid(e) then return nil end
    e:SetPos(at + Vector(0, 0, 1))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    e.lcBorn = CurTime()
    -- Sanitation is told
    for _, p in ipairs(player.GetAll()) do
        local job = LC.Job and LC.Job(p)
        if job and job.id == "sanitation" then
            Notice(p, "info", "A mess to clean up", "Someone soiled themselves " .. (LC.DescribePlace and LC.DescribePlace(at) or "in the street") .. ". E on it to scrub it up (paid). F1 > Places marks it.", 7)
        end
    end
    return e
end

function LC.Soil(ply)
    if not IsValid(ply) or Exempt(ply) then return false end
    local n = Needs(ply)
    n.toilet, n.wash, n.clothes = true, true, true
    ply:SetNW2Bool("lc_soiled", true)
    SetUrge(ply, 0)
    ply.lcUrgeWarn = 0
    Sync(ply)
    -- on the trousers, and on the ground
    local hips = ply:GetPos() + Vector(0, 0, 34)
    local back = -ply:GetForward()
    if util.Decal then util.Decal("BeerSplash", hips + back * 24, hips - back * 6, nil) end
    LC.SpawnStain(ply:GetPos())
    ply:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70)
    Notice(ply, "warn", "You couldn't hold it", "You've soiled yourself. A toilet, a wash (a bathtub or shower) and clean clothes, or people will keep their distance (and you may make them ill).", 10)
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:GetPos():DistToSqr(ply:GetPos()) < 500 * 500 then
            p:ChatPrint("[Living City] Someone nearby has soiled themselves. The smell reaches you a moment later.")
        end
    end
    if LC.Bump then LC.Bump(ply, "soiled") end
    hook.Run("LivingCitySoiled", ply)
    return true
end

------------------------------------------------------------------------
-- Toilets, baths, clean clothes
------------------------------------------------------------------------

function LC.UseToilet(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not LC.StartTask then return false end
    local had = LC.HasParasites and LC.HasParasites(ply)
    ply:SetNW2Bool("lc_on_toilet", true)
    ply:EmitSound("physics/plastic/plastic_box_impact_soft" .. math.random(1, 4) .. ".wav", 55)
    return LC.StartTask(ply, 8, "On the toilet...", {
        maxMove = 40, cancelText = "You get up before you're done.",
        cancel = function(p) if IsValid(p) then p:SetNW2Bool("lc_on_toilet", false) end end,
        done = function(p)
            if not IsValid(p) then return end
            p:SetNW2Bool("lc_on_toilet", false)
            p:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 60)
            -- then the flush (your own recording, sound/livingcity/flush1.wav, if the server has one)
            timer.Simple(1.2, function()
                if not IsValid(p) then return end
                local own = file.Exists("sound/livingcity/flush1.wav", "GAME") and "livingcity/flush1.wav"
                p:EmitSound(own or "ambient/water/wave3.wav", 62)
            end)
            local urged = LC.Urge(p) > 1
            SetUrge(p, 0)
            p.lcUrgeWarn = 0
            Needs(p).toilet = nil
            Sync(p)
            if had or urged then
                if LC.Feed then LC.Feed(p, 0, -30) end -- (it takes it out of you)
                Notice(p, "info", "That's better", had and "For now. It drained you, though: drink something. Only antiparasitic tablets will stop it coming back."
                    or "It drained you, though: drink something.", 7)
            else
                Notice(p, "info", "That's better", "Nothing much to it.", 4)
            end
            if p:GetNW2Bool("lc_soiled", false) then
                local left = p:GetNW2String("lc_soil_need", "")
                if left ~= "" then p:ChatPrint("[Living City] Still to do: " .. string.gsub(string.gsub(left, "wash", "a wash (bathtub or shower)"), "clothes", "clean clothes") .. ".") end
            end
        end,
    })
end

function LC.UseBath(ply)
    if not IsValid(ply) or not ply:Alive() or not LC.StartTask then return false end
    ply:EmitSound("ambient/water/water_flow_loop1.wav", 55, 100, 0.4)
    return LC.StartTask(ply, 10, "Washing...", {
        maxMove = 50, cancelText = "You step out half washed.",
        cancel = function(p) if IsValid(p) and p.StopSound then p:StopSound("ambient/water/water_flow_loop1.wav") end end,
        done = function(p)
            if not IsValid(p) then return end
            if p.StopSound then p:StopSound("ambient/water/water_flow_loop1.wav") end
            local was = Needs(p).wash
            Needs(p).wash = nil
            Sync(p)
            if p.RemoveAllDecals then p:RemoveAllDecals() end
            if was then
                Notice(p, "info", "Clean", Needs(p).clothes and "Clean skin, filthy clothes: change into clean ones (spare clothes or overalls from your pockets)." or "Scrubbed clean.", 7)
            else
                Notice(p, "info", "Clean", "You wash. You feel almost human.", 4)
            end
        end,
    })
end

-- Into clean clothes: spare citizen clothes or Union overalls from your pockets.
-- id: which (else whichever you have). True, or false and why.
function LC.ChangeClothes(ply, id)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not Needs(ply).clothes then return false, "Your clothes are clean enough." end
    if not id then for c in pairs(CLOTHES) do if LC.HasItem(ply, c) then id = c break end end end
    if not id or not CLOTHES[id] or not LC.HasItem(ply, id) then
        return false, "You need clean clothes: spare citizen clothes or Union overalls (the Commissary sells them)."
    end
    LC.TakeItem(ply, id)
    Needs(ply).clothes = nil
    Sync(ply)
    if ply.RemoveAllDecals then ply:RemoveAllDecals() end
    ply:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 55)
    Notice(ply, "info", "Clean clothes", Needs(ply).wash and "Better. You still need a wash: a bathtub or a shower." or "Better. The old ones can go in the bin.", 6)
    return true
end
LC.CleanClothes = CLOTHES

LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.changeclothes = function(ply)
    local ok, why = LC.ChangeClothes(ply)
    if not ok and why then ply:ChatPrint(why) end
end

------------------------------------------------------------------------
-- The stain on the ground
------------------------------------------------------------------------

function LC.CleanStain(ply, e)
    if not IsValid(e) or e:GetClass() ~= "lc_stain" or not LC.StartTask then return false end
    local job = LC.Job and LC.Job(ply)
    local paid = job and job.id == "sanitation"
    return LC.StartTask(ply, 5, "Scrubbing it up...", {
        maxMove = 50, cancelText = "You leave it half done.",
        done = function(p)
            if not IsValid(e) then return end
            e:Remove()
            if not IsValid(p) then return end
            p:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 60)
            if paid and LC.AddCredits then LC.AddCredits(p, 5, "Cleaned up a mess") end
            if math.random() < 0.2 and LC.Infect and not (LC.HasParasites and LC.HasParasites(p)) then
                LC.Infect(p)
                Notice(p, "warn", "Something got on you", "Scrubbing that up, something got on your hands. Your stomach turns.", 6)
            elseif paid then
                Notice(p, "info", "Cleaned up", "5 credits. Wash your hands.", 4)
            end
        end,
    })
end

------------------------------------------------------------------------
-- Every five seconds: the urge grows, the filthy stink
------------------------------------------------------------------------

local NPC_SAY = { "vo/npc/male01/ohno.wav", "vo/npc/female01/ohno.wav", "vo/npc/male01/question20.wav", "vo/npc/female01/gethellout.wav" }

local function Shun(ply, now)
    local pos = ply:GetPos()
    -- the city's own step away
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and not st.questLock and not st.unmanaged and npc:GetPos():DistToSqr(pos) < 200 * 200 then
            if (st.lcShunned or 0) < now and LC.GoTo then
                st.lcShunned = now + 8
                local away = npc:GetPos() - pos away.z = 0
                if away:LengthSqr() < 1 then away = VectorRand() away.z = 0 end
                local to = npc:GetPos() + away:GetNormalized() * 280
                pcall(LC.GoTo, npc, st, to, false, nil)
                if math.random() < 0.4 then npc:EmitSound(Pick(NPC_SAY), 65) end
            end
        end
    end
    -- people nearby smell it, and may catch it
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and p:GetPos():DistToSqr(pos) < 150 * 150 then
            if (p.lcSmelled or 0) < now then
                p.lcSmelled = now + 60
                p:ChatPrint("[Living City] Someone near you reeks. Flies, and worse. You'd step back if you were sensible.")
            end
            if math.random() < cvSpread:GetFloat() and LC.Infect and LC.HasParasites and not LC.HasParasites(p) then LC.Infect(p) end
        end
    end
end

function LC.HygieneTick(now)
    if not cvOn:GetBool() then return end
    local step = 100 / math.max(10, cvUrge:GetFloat() * 60) * 5
    for _, ply in ipairs(player.GetAll()) do
        if not Exempt(ply) then
            if LC.HasParasites and LC.HasParasites(ply) and not ply:GetNW2Bool("lc_on_toilet", false) and not (LC.InCustody and LC.InCustody(ply) and LC.Urge(ply) > 90) then
                SetUrge(ply, LC.Urge(ply) + step)
                local u = LC.Urge(ply)
                local warn = u >= 80 and 2 or (u >= 50 and 1 or 0)
                if warn > (ply.lcUrgeWarn or 0) then
                    ply.lcUrgeWarn = warn
                    if warn == 1 then Notice(ply, "warn", "Your stomach cramps", "You need a toilet. Soon. (F1 > What now? shows the nearest.)", 6)
                    else Notice(ply, "warn", "Find a toilet. NOW.", "You can't hold it much longer.", 8) end
                end
                if u >= 100 then LC.Soil(ply) end
            end
            if LC.IsFilthy(ply) then Shun(ply, now) end
        end
    end
end

timer.Create("LivingCityHygiene", 5, 0, function()
    local ok, err = pcall(LC.HygieneTick, CurTime())
    if not ok and LC.Error then LC.Error("hygiene", err) end
end)

hook.Add("PlayerSpawn", "LivingCityHygiene", function(ply) Clear(ply) end)

-- What now? (sv_livingcity_nextstep.lua asks this first)
function LC.HygieneStep(ply)
    if not cvOn:GetBool() then return nil end
    local n = Needs(ply)
    if n.toilet or LC.Urge(ply) >= 50 then
        return { key = "toilet", text = "Find a toilet", why = n.toilet and "You've soiled yourself. A toilet first, then a wash and clean clothes."
            or "Your stomach's cramping (parasites): sit on a toilet before it's too late. Antiparasitic tablets stop it for good.", way = "toilet", urgent = true }
    end
    if n.wash then
        return { key = "wash", text = "Get washed", why = "You reek. A bathtub or a shower: press E on it.", way = "bath", urgent = true }
    end
    if n.clothes then
        local have
        for c in pairs(CLOTHES) do if LC.HasItem(ply, c) then have = c break end end
        if have then return { key = "clothes", text = "Change into clean clothes", why = "Your clothes are filthy. Choose this to change into the clean ones in your pockets.", action = "changeclothes", urgent = true } end
        return { key = "clothes", text = "Get clean clothes", why = "Your clothes are filthy. The Commissary sells spare clothes; then change into them.", way = "shop", urgent = true }
    end
    return nil
end
