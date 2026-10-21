--[[
    Living City: getting by

      Scavenging    press E on a bin or dumpster and go through it: scrap,
                    bottles, cans, now and then a tin of food or a seed
                    packet. Each bin has to fill up again before it's worth
                    another look. Units don't go through bins.
      Fishing       a fishing line (Commissary) and the canal: stand in the
                    water or look at it, keep still, and wait for a bite.
                    Raw fish needs cooking.
      Gardens       pots in rebel territory. Plant a seed packet, come back
                    in a few minutes, harvest real vegetables. Anyone can
                    harvest a ripe pot (so watch yours). Units uproot them.
      Supplies      every rebel zone keeps a supply crate the Resistance eat
                    from: one tin each every few minutes. It fills slowly by
                    itself, faster with supply runs (a Resistance job) and
                    donations (!donate next to it). A unit who finds it
                    confiscates the lot.
      Graffiti      a spray can and a wall: the lambda goes up for everyone to
                    see. Seen doing it, you're wanted for vandalism. Tags near
                    rebel ground help it spread. Units and loyal citizens scrub
                    them off (E on the tag) for XP or standing.

      lc_scavenge_refill <s>   seconds before a bin is worth searching again (600)
      lc_garden_minutes <m>    minutes for a pot to ripen (8)
      lc_cache_max <n>         most meals a supply crate holds (12)
      lc_cache_trickle <m>     minutes per meal the crate gains by itself (5)
      lc_tag_minutes <m>       how long a tag stays up if nobody cleans it (60)
]]

if CLIENT then return end

util.AddNetworkString("lc_tags")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRefill  = CreateConVar("lc_scavenge_refill", "600", FLAGS, "Seconds before a searched bin is worth searching again")
local cvFridge  = CreateConVar("lc_fridge_refill", "240", FLAGS, "Seconds before a searched fridge has anything in it again")
local cvGarden  = CreateConVar("lc_garden_minutes", "8", FLAGS, "Minutes for a planted pot to ripen")
local cvCacheMax = CreateConVar("lc_cache_max", "12", FLAGS, "Most meals a Resistance supply crate holds")
local cvTrickle = CreateConVar("lc_cache_trickle", "5", FLAGS, "Minutes per meal a supply crate gains on its own")
local cvTagLife = CreateConVar("lc_tag_minutes", "60", FLAGS, "Minutes a graffiti tag stays up if nobody cleans it")

local UP = Vector(0, 0, 50)
local function Pick(t) return t[math.random(#t)] end
local function IsResistance(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end

------------------------------------------------------------------------
-- A few seconds of doing something, keeping still
------------------------------------------------------------------------

local tasks = {} -- [ply] = { untilT, anchor, maxMove, done, cancel, text }

function LC.StartTask(ply, secs, text, opts)
    if tasks[ply] then return false, "You're busy." end
    opts = opts or {}
    local now = CurTime()
    tasks[ply] = { untilT = now + secs, anchor = ply:GetPos(), maxMove = opts.maxMove or 48, done = opts.done, cancel = opts.cancel,
        hp = ply:Health(), cancelText = opts.cancelText }
    ply:SetNW2String("lcu_progress", text)
    ply:SetNW2Float("lcu_pick_start", now)
    ply:SetNW2Float("lcu_pick_until", now + secs)
    return true
end

function LC.Busy(ply) return tasks[ply] ~= nil end

local function EndTask(ply, ok)
    local t = tasks[ply]
    tasks[ply] = nil
    if IsValid(ply) then ply:SetNW2Float("lcu_pick_until", 0) end
    if not t then return end
    if ok then
        if t.done then t.done(ply) end
    else
        if IsValid(ply) and ply:Alive() and t.cancelText then ply:ChatPrint(t.cancelText) end
        if t.cancel then t.cancel(ply) end
    end
end

-- Stop what they're doing (as if they'd walked off).
function LC.CancelTask(ply) if tasks[ply] then EndTask(ply, false) end end

timer.Create("LivingCityTasks", 0.25, 0, function()
    local now = CurTime()
    for ply, t in pairs(tasks) do
        if not IsValid(ply) then
            tasks[ply] = nil
        elseif not ply:Alive() then
            -- died mid-task: cancelled, so anything held for it is settled
            local ok, err = pcall(EndTask, ply, false)
            if not ok then LC.Error("task", err) end
        elseif ply:GetPos():DistToSqr(t.anchor) > t.maxMove * t.maxMove or ply:Health() < t.hp then
            EndTask(ply, false)
        elseif now >= t.untilT then
            local ok, err = pcall(EndTask, ply, true)
            if not ok then LC.Error("task", err) end
        end
    end
end)

------------------------------------------------------------------------
-- Scavenging
------------------------------------------------------------------------

local searched = {} -- [key] = time it's worth searching again

local LOOT = {
    { nil, 30 }, { "scrap", 18 }, { "can_empty", 9 }, { "bottle_empty", 8 }, { "canned_food", 8 },
    { "cloth", 9 }, { "chemicals", 6 }, { "bread", 4 }, { "seeds", 5 }, { "gun_parts", 2 }, { "keepsake", 2 }, { "spraypaint", 2 },
    { "civvies", 3 }, { "cwu_overalls", 2 }, { "uniform_cp", 0.4 }, { "paper", 5 },
}
local REBEL_LOOT = {
    { nil, 18 }, { "scrap", 18 }, { "canned_food", 16 }, { "seeds", 10 }, { "cloth", 8 }, { "chemicals", 8 },
    { "gun_parts", 5 }, { "bottle_empty", 6 }, { "spraypaint", 6 }, { "can_empty", 6 },
    { "civvies", 4 }, { "rebel_gear", 3 },
}

local function Roll(tbl)
    local total = 0
    for _, e in ipairs(tbl) do total = total + e[2] end
    local r = math.random() * total
    for _, e in ipairs(tbl) do
        r = r - e[2]
        if r <= 0 then return e[1] end
    end
    return nil
end
LC.RollScavenge = function(rebel) return Roll(rebel and REBEL_LOOT or LOOT) end

local function IsFridge(model)
    model = string.lower(model or "")
    return string.find(model, "fridge", 1, true) ~= nil or string.find(model, "refrigerator", 1, true) ~= nil
end
LC.IsFridgeModel = IsFridge

-- Is the aim on a map prop at `pos` (its origin, on the floor): close across
-- the floor, and between its foot and about head height?
local function Aimed(pos, hit, r)
    local dx, dy = hit.x - pos.x, hit.y - pos.y
    return dx * dx + dy * dy < r * r and hit.z > pos.z - 10 and hit.z < pos.z + 96
end
local function Flat2(a, b) local dx, dy = a.x - b.x, a.y - b.y return dx * dx + dy * dy end

-- The bin (or fridge) you're looking at: a prop, the editor's bin point, or one
-- of the map's static ones. Only what you're actually aiming at: not the fridge
-- beside the sink you're looking at. Returns key, pos, and "fridge" or "bin".
function LC.BinAt(ply)
    local tr = ply:GetEyeTrace()
    if not tr or not tr.HitPos or tr.HitPos:DistToSqr(ply:EyePos()) > 110 * 110 then return nil end
    local e = tr.Entity
    if IsValid(e) and not (e.IsWorld and e:IsWorld()) then
        -- a prop: it's a bin or it isn't (never the one next to it)
        if not e.lcQuest and not e.lcDressing and LC.IsBinModel and LC.IsBinModel(e:GetModel()) then
            return "e" .. e:EntIndex(), e:GetPos(), IsFridge(e:GetModel()) and "fridge" or "bin"
        end
        return nil
    end
    local hit = tr.HitPos
    local bp = LC.BinPointAt and LC.BinPointAt(hit, 60) -- the editor's bin points (sv_livingcity_salvage.lua)
    if bp then
        return string.format("p%d:%d:%d", math.floor(bp.pos.x), math.floor(bp.pos.y), math.floor(bp.pos.z)), bp.pos, "bin"
    end
    -- the map's static props: the nearest one under your aim, unless a sink or stove is nearer
    local best, bd
    for _, b in ipairs(LC.StaticBins or {}) do
        if Aimed(b.pos, hit, 48) then
            local d = Flat2(b.pos, hit)
            if not bd or d < bd then best, bd = b, d end
        end
    end
    if not best then return nil end
    for _, f in ipairs(LC.StaticFixtures or {}) do
        if Aimed(f.pos, hit, 48) and Flat2(f.pos, hit) < bd then return nil end
    end
    -- (one key per spot, so a prop the map lists twice is still one fridge)
    local p = best.pos
    return string.format("s%d:%d:%d", math.floor(p.x / 48), math.floor(p.y / 48), math.floor(p.z / 48)), p,
        IsFridge(best.model) and "fridge" or "bin"
end

function LC.Scavenge(ply, key, pos, kind)
    local fridge = kind == "fridge"
    -- a fridge at home is yours: your stash, like the stove (not a rummage through someone else's)
    if fridge and LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) and not LC.PlayerIsCP(ply) then
        if LC.SendInv then LC.SendInv(ply, true) end
        ply:ChatPrint("[Home] Your fridge: your stash is in your pockets' window (F2).")
        return true
    end
    if LC.PlayerIsCP(ply) then return false, fridge and "Civil Protection units don't rummage through people's fridges." or "Civil Protection units don't go through bins." end
    if LC.Busy(ply) then return false end
    local now = CurTime()
    if (searched[key] or 0) > now then
        return false, fridge and "Somebody's cleared it out already. Nothing but the smell." or "Somebody's been through this one already. Nothing left."
    end
    if LC.InvSpace(ply) < 1 then return false, "Your pockets are full." end
    return LC.StartTask(ply, 3, fridge and "Going through the fridge..." or "Going through the rubbish...", {
        cancelText = "You leave it.",
        done = function(p)
            searched[key] = CurTime() + (fridge and cvFridge or cvRefill):GetFloat()
            local rebel = LC.InRebelZone and LC.InRebelZone(pos)
            local id = Roll(rebel and REBEL_LOOT or LOOT)
            p:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 7) .. ".wav", 60)
            if not id then
                p:ChatPrint("Nothing worth having.")
            elseif LC.GiveItem(p, id) then
                p:ChatPrint("Found: " .. LCS.Items[id].name .. ".")
                hook.Run("LivingCityScavenged", p, id)
            end
        end,
    })
end

------------------------------------------------------------------------
-- Fishing
------------------------------------------------------------------------

local function WaterAhead(ply)
    if ply:WaterLevel() >= 1 then return true end
    local eye = ply:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + ply:GetAimVector() * 300, mask = MASK_WATER, filter = ply })
    return tr and tr.Hit and not tr.StartSolid
end
LC.WaterAhead = WaterAhead

local CATCH = { { "raw_fish", 58 }, { nil, 30 }, { "can_empty", 6 }, { "scrap", 4 }, { "keepsake", 2 } }

local function Fish(ply)
    if not WaterAhead(ply) then return false, "You need water: stand in the canal, or look at it." end
    if LC.InvSpace(ply) < 1 then return false, "Your pockets are full." end
    local secs = math.Rand(10, 22)
    ply:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 55)
    return LC.StartTask(ply, secs, "Fishing... keep still", {
        maxMove = 40, cancelText = "You reel in. The fish can wait.",
        done = function(p)
            local id = Roll(CATCH)
            if not id then
                p:ChatPrint("Nothing bites. The canal keeps its secrets.")
            elseif LC.GiveItem(p, id) then
                p:EmitSound("ambient/water/water_splash1.wav", 60)
                p:ChatPrint(id == "raw_fish" and "A bite! A fish, of a kind. Cook it." or ("You reel in... " .. string.lower(LCS.Items[id].name) .. "."))
                hook.Run("LivingCityFished", p, id)
            end
        end,
    })
end

------------------------------------------------------------------------
-- Rebel gardens and supply crates
------------------------------------------------------------------------

LC.RebelProps = LC.RebelProps or {} -- [zone] = { cache = ent, pots = { ents } }

local function Prop(model, pos, kind)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local ground = LC.GroundAt and LC.GroundAt(pos) or pos
    local lift = e.OBBMins and -e:OBBMins().z or 0
    e:SetPos(ground + Vector(0, 0, math.max(0, lift) + 1))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcRebelProp = kind
    e:SetNW2String("lc_label_kind", kind)
    return e
end

local function SetPot(e, state, readyAt)
    e.lcPot = e.lcPot or {}
    e.lcPot.state, e.lcPot.readyAt = state, readyAt or 0
    e:SetNW2String("lc_pot_state", state)
    e:SetNW2Float("lc_pot_ready", readyAt or 0)
end

local function SetStock(e, n)
    e.lcStock = math.Clamp(n, 0, cvCacheMax:GetInt())
    e:SetNW2Int("lc_cache_stock", e.lcStock)
end

local function EnsureRebelProps()
    if not LC.Running then return end
    local live = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if not z.grown and (not LC.RebelIsLeader or LC.RebelIsLeader(z)) then -- (one crate for a whole territory)
            live[z] = true
            local r = LC.RebelProps[z] or { pots = {} }
            LC.RebelProps[z] = r
            for i = #r.pots, 1, -1 do if not IsValid(r.pots[i]) then table.remove(r.pots, i) end end
            local need = (IsValid(r.cache) and 0 or 1) + math.max(0, 2 - #r.pots)
            if need > 0 then
                -- where the players last set them down (sv_livingcity_campmove.lua)
                for _, it in ipairs(LC.CampSaved and LC.CampSaved(z) or {}) do
                    local p = Vector(it.x, it.y, it.z)
                    if it.prop == "cache" and not IsValid(r.cache) then
                        r.cache = Prop("models/items/item_item_crate.mdl", p, "cache")
                        if IsValid(r.cache) then SetStock(r.cache, r.stock or 4) r.cache:SetAngles(Angle(0, it.yaw or 0, 0)) end
                    elseif it.prop == "pot" and #r.pots < 2 then
                        local pot = Prop("models/props_junk/terracotta01.mdl", p, "pot")
                        if IsValid(pot) then SetPot(pot, "empty") r.pots[#r.pots + 1] = pot end
                    end
                end
                need = (IsValid(r.cache) and 0 or 1) + math.max(0, 2 - #r.pots)
            end
            if need > 0 then
                -- on the zone's own floor (a rooftop camp keeps its crate on the roof: sv_livingcity_war.lua)
                local spots = LC.ZoneFloorSpots and LC.ZoneFloorSpots(z, need * 2)
                    or (LC.QB and LC.QB.HideSpots and LC.QB.HideSpots(z.pos, need * 2, z.r * 0.7, true)) or {}
                for _, p in ipairs(spots) do
                    if p:DistToSqr(z.pos) < (z.r * 0.8) ^ 2 and not LC.IsSeen(p + Vector(0, 0, 30))
                        and (not LC.DressingClear or LC.DressingClear(p, 35)) then -- not inside the dressing, or each other
                        if not IsValid(r.cache) then
                            r.cache = Prop("models/items/item_item_crate.mdl", p, "cache")
                            if IsValid(r.cache) then SetStock(r.cache, r.stock or 4) end
                        elseif #r.pots < 2 then
                            local pot = Prop("models/props_junk/terracotta01.mdl", p, "pot")
                            if IsValid(pot) then SetPot(pot, "empty") r.pots[#r.pots + 1] = pot end
                        end
                    end
                end
            end
            if IsValid(r.cache) then r.stock = r.cache.lcStock end
        end
    end
    for z, r in pairs(LC.RebelProps) do
        if not live[z] then
            if IsValid(r.cache) then r.cache:Remove() end
            for _, p in ipairs(r.pots) do if IsValid(p) then p:Remove() end end
            LC.RebelProps[z] = nil
        end
    end
end
LC.EnsureRebelProps = EnsureRebelProps

function LC.CacheNear(pos, r)
    for _, rp in pairs(LC.RebelProps) do
        if IsValid(rp.cache) and rp.cache:GetPos():DistToSqr(pos) < (r or 200) ^ 2 then return rp.cache end
    end
    return nil
end

function LC.AddToCache(cache, n)
    if not IsValid(cache) then return 0 end
    local before = cache.lcStock or 0
    SetStock(cache, before + n)
    return cache.lcStock - before
end

local function UseCache(ply, cache)
    if LC.PlayerIsCP(ply) then
        local n = cache.lcStock or 0
        SetStock(cache, 0)
        if n > 0 then
            if LC.AddXP then LC.AddXP(ply, 10, "confiscated Resistance supplies") end
            ply:ChatPrint(string.format("[Civil Protection] Confiscated: %d meals' worth of hoarded supplies.", n))
            if LC.RadioNotice then LC.RadioNotice("resistance", "The Combine found our supplies. Everything's gone.") end
            hook.Run("LivingCityCacheRaided", ply, cache, n)
        else
            ply:ChatPrint("[Civil Protection] Empty. They've eaten it already.")
        end
        return
    end
    if not IsResistance(ply) then
        ply:ChatPrint("The crate is nailed shut. Whoever it belongs to isn't here.")
        return
    end
    local now = CurTime()
    if (ply.lcCacheNext or 0) > now then
        ply:ChatPrint(string.format("[Resistance] Everyone eats. Come back in %d minute%s.", math.ceil((ply.lcCacheNext - now) / 60), math.ceil((ply.lcCacheNext - now) / 60) == 1 and "" or "s"))
        return
    end
    if (cache.lcStock or 0) <= 0 then
        ply:ChatPrint("[Resistance] The crate's empty. Somebody needs to make a supply run (F3), or bring food (C > Resistance > Donate food).")
        return
    end
    if not LC.GiveItem(ply, "canned_food") then ply:ChatPrint("Your pockets are full.") return end
    SetStock(cache, cache.lcStock - 1)
    ply.lcCacheNext = now + 240
    ply:ChatPrint(string.format("[Resistance] A tin from the stores. %d left.", cache.lcStock))
end

local function UsePot(ply, pot)
    local s = pot.lcPot or {}
    local now = CurTime()
    if LC.PlayerIsCP(ply) then
        if s.state ~= "empty" then
            SetPot(pot, "empty")
            if LC.AddXP then LC.AddXP(ply, 3, "uprooted an illegal garden") end
            ply:ChatPrint("[Civil Protection] Unlicensed agriculture. You pull it up by the roots.")
        else
            ply:ChatPrint("An empty pot.")
        end
        return
    end
    if s.state == "empty" then
        if not LC.HasItem(ply, "seeds") then
            ply:ChatPrint("An empty pot. Plant a seed packet in it (the black market, or rubbish bins, if you're lucky).")
            return
        end
        LC.TakeItem(ply, "seeds")
        SetPot(pot, "growing", now + cvGarden:GetFloat() * 60)
        pot.lcPot.planter = ply
        ply:ChatPrint(string.format("You plant the seeds. Back in %d minutes.", math.ceil(cvGarden:GetFloat())))
        hook.Run("LivingCityPlanted", ply, pot)
    elseif s.state == "growing" then
        if now >= s.readyAt then
            SetPot(pot, "ripe")
            return UsePot(ply, pot)
        end
        ply:ChatPrint(string.format("Green shoots. Ripe in %d:%02d.", math.floor((s.readyAt - now) / 60), math.floor((s.readyAt - now) % 60)))
    elseif s.state == "ripe" then
        if LC.InvSpace(ply) < 1 then ply:ChatPrint("Your pockets are full.") return end
        local n = math.min(3, LC.InvSpace(ply, "vegetables"))
        LC.GiveItem(ply, "vegetables", n)
        local planter = s.planter
        SetPot(pot, "empty")
        ply:ChatPrint(string.format("You pick %d lot%s of vegetables.%s", n, n == 1 and "" or "s",
            (IsValid(planter) and planter ~= ply) and " Not your pot. Somebody will be annoyed." or ""))
        if IsValid(planter) and planter ~= ply then planter:ChatPrint("Someone's harvested your pot in rebel territory.") end
        hook.Run("LivingCityHarvested", ply, pot, n)
    end
end

-- pots ripen, crates refill
local nextTrickle = 0
timer.Create("LivingCityRebelSupplies", 5, 0, function()
    local ok, err = pcall(function()
        EnsureRebelProps()
        local now = CurTime()
        for _, r in pairs(LC.RebelProps) do
            for _, pot in ipairs(r.pots) do
                if IsValid(pot) and pot.lcPot and pot.lcPot.state == "growing" and now >= pot.lcPot.readyAt then SetPot(pot, "ripe") end
            end
        end
        if now >= nextTrickle then
            if nextTrickle > 0 then
                for _, r in pairs(LC.RebelProps) do if IsValid(r.cache) then SetStock(r.cache, (r.cache.lcStock or 0) + 1) end end
            end
            nextTrickle = now + math.max(0.5, cvTrickle:GetFloat()) * 60
        end
    end)
    if not ok then LC.Error("rebel supplies", err) end
end)

hook.Add("LivingCityStopped", "LivingCityRebelSupplies", function()
    for _, r in pairs(LC.RebelProps) do
        if IsValid(r.cache) then r.cache:Remove() end
        for _, p in ipairs(r.pots) do if IsValid(p) then p:Remove() end end
    end
    LC.RebelProps = {}
end)

local FOOD = {}
for id, it in pairs(LCS and LCS.Items or {}) do if it.hunger and it.hunger >= 25 then FOOD[id] = true end end

function LC.Donate(ply)
    local cache = LC.CacheNear(ply:GetPos(), 200)
    if not cache then return false, "Stand by a Resistance supply crate to donate food." end
    if LC.PlayerIsCP(ply) then return false, "That's not how confiscation works." end
    local given = 0
    for id in pairs(FOOD) do
        while LC.HasItem(ply, id) and (cache.lcStock or 0) < cvCacheMax:GetInt() do
            LC.TakeItem(ply, id)
            LC.AddToCache(cache, 1)
            given = given + 1
        end
    end
    if given == 0 then
        return false, (cache.lcStock or 0) >= cvCacheMax:GetInt() and "The crate's full. Eat something." or "You've no proper food to give (rations, tins, bread, vegetables, cooked meat)."
    end
    if IsResistance(ply) and LC.AddXP then LC.AddXP(ply, 2 * given, "fed the Resistance") end
    if LC.AddTrait then LC.AddTrait(ply, "sympathy", 1) end
    ply:ChatPrint(string.format("[Resistance] You add %d meal%s to the stores. %d in the crate.", given, given == 1 and "" or "s", cache.lcStock))
    return true
end

------------------------------------------------------------------------
-- Graffiti
------------------------------------------------------------------------

LC.Tags = LC.Tags or {}
local MAX_TAGS = 60

local function SendTags(target)
    local list = {}
    for _, t in ipairs(LC.Tags) do
        list[#list + 1] = { x = t.pos.x, y = t.pos.y, z = t.pos.z, nx = t.normal.x, ny = t.normal.y, nz = t.normal.z }
    end
    LC.SendCompressed("lc_tags", { tags = list }, IsValid(target) and { target } or player.GetAll())
end
LC.SendTags = SendTags

local function WallAhead(ply)
    local eye = ply:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + ply:GetAimVector() * 110, mask = MASK_SOLID, filter = ply })
    if not tr or not tr.Hit or not tr.HitNormal or math.abs(tr.HitNormal.z) > 0.4 then return nil end
    if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then return nil end
    return tr.HitPos, Vector(tr.HitNormal.x, tr.HitNormal.y, tr.HitNormal.z)
end

local function TagNear(pos, r)
    for i, t in ipairs(LC.Tags) do
        if t.pos:DistToSqr(pos) < r * r then return t, i end
    end
    return nil
end
LC.TagNear = TagNear

local function Spray(ply)
    local pos, normal = WallAhead(ply)
    if not pos then return false, "Look at a wall, up close." end
    if TagNear(pos, 60) then return false, "There's already one here." end
    return LC.StartTask(ply, 2.5, "Spraying the lambda... keep looking at the wall", {
        maxMove = 30, cancelText = "You stop, half done, and the paint runs.",
        done = function(p)
            if not LC.TakeItem(p, "spraypaint") then return end
            p:EmitSound("ambient/water/water_spray3.wav", 60)
            local t = { pos = pos + normal * 0.5, normal = normal, owner = p, at = CurTime() }
            table.insert(LC.Tags, t)
            while #LC.Tags > MAX_TAGS do table.remove(LC.Tags, 1) end
            SendTags()
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, "Vandalism", 90)
                p:ChatPrint("[Civil Protection] A Civil Protection unit saw that.")
            elseif IsResistance(p) and LC.AddXP then
                LC.AddXP(p, 3, "graffiti")
            end
            -- near rebel ground it rallies people: it spreads sooner
            for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
                if pos:DistToSqr(z.pos) < (z.r + 1500) ^ 2 then
                    local seed = z.grown and z.seed or z
                    local s = LC.TerritoryState and LC.TerritoryState[seed]
                    if s then s.nextGrow = math.max(CurTime() + 30, s.nextGrow - 120) end
                    break
                end
            end
            hook.Run("LivingCityTagged", p, t)
        end,
    })
end

function LC.CleanTag(ply, tag)
    if IsResistance(ply) then return false, "Paint over our own? No." end
    return LC.StartTask(ply, 3, "Scrubbing it off...", {
        maxMove = 40, cancelText = "You leave it half scrubbed.",
        done = function(p)
            for i, t in ipairs(LC.Tags) do
                if t == tag then
                    table.remove(LC.Tags, i)
                    SendTags()
                    p:EmitSound("ambient/water/water_spray1.wav", 55)
                    if LC.PlayerIsCP(p) then
                        if LC.AddXP then LC.AddXP(p, 4, "cleaned up anticitizen graffiti") end
                        p:ChatPrint("[Civil Protection] Gone. As if it never was.")
                    else
                        if LC.AddStanding then LC.AddStanding(p, 3) end
                        if LC.AddTrait then LC.AddTrait(p, "loyalty", 1) end
                        p:ChatPrint("You scrub it off. Someone from the Union nods at you. +3 standing.")
                    end
                    hook.Run("LivingCityTagCleaned", p, t)
                    return
                end
            end
        end,
    })
end

timer.Create("LivingCityTags", 30, 0, function()
    local life = cvTagLife:GetFloat() * 60
    local changed = false
    for i = #LC.Tags, 1, -1 do
        if CurTime() - LC.Tags[i].at > life then table.remove(LC.Tags, i) changed = true end
    end
    if changed then SendTags() end
end)

hook.Add("PlayerInitialSpawn", "LivingCityTags", function(ply)
    timer.Simple(4, function() if IsValid(ply) and #LC.Tags > 0 then SendTags(ply) end end)
end)

------------------------------------------------------------------------
-- Using things from your pockets, and pressing E on things
------------------------------------------------------------------------

function LC.ItemUse(ply, id)
    local it = LCS.Items[id]
    if not it or not it.use then return false end
    if it.use == "fish" then return Fish(ply) end
    if it.use == "spray" then return Spray(ply) end
    if it.use == "write" and LC.OpenWriter then return LC.OpenWriter(ply) end -- sv_livingcity_writing.lua
    if it.use == "papers" and LC.ShowPapers then return LC.ShowPapers(ply) end -- sv_livingcity_intake.lua
    if it.use == "listen" and LC.RadioListen then return LC.RadioListen(ply, id) end -- sv_livingcity_moregames.lua
    if it.use == "read" and LC.ReadItem then return LC.ReadItem(ply, id) end -- sv_livingcity_moregames.lua (a Freq 7 sheet)
    if it.use == "plant" then
        local tr = ply:GetEyeTrace()
        local pot = tr and tr.Entity
        if not (IsValid(pot) and pot.lcRebelProp == "pot") then
            for _, r in pairs(LC.RebelProps) do
                for _, p in ipairs(r.pots) do
                    if IsValid(p) and p:GetPos():DistToSqr(ply:GetPos()) < 120 * 120 then pot = p end
                end
            end
        end
        if not (IsValid(pot) and pot.lcRebelProp == "pot") then return false, "Find an empty pot in rebel territory." end
        if pot.lcPot.state ~= "empty" then return false, "Something's already growing in that one." end
        UsePot(ply, pot)
        return true
    end
    if LC.ArmsUse then return LC.ArmsUse(ply, id) end -- bandages, ammo, guns, grenades (sv_livingcity_crafting.lua)
    return false
end

hook.Add("PlayerUse", "LivingCityRebelProps", function(ply, ent)
    if not ent.lcRebelProp then return end
    if (ply.lcPropUseNext or 0) > CurTime() then return false end
    ply.lcPropUseNext = CurTime() + 0.6
    if ent.lcRebelProp == "cache" then UseCache(ply, ent) elseif ent.lcRebelProp == "pot" then UsePot(ply, ent) end
    return false
end)

-- E on a bin, or on a tag on the wall
hook.Add("KeyPress", "LivingCityScavenge", function(ply, key)
    if key ~= IN_USE or not ply:Alive() or LC.Busy(ply) then return end
    if (ply.lcScavNext or 0) > CurTime() then return end
    local tr = ply:GetEyeTrace()
    if tr and tr.HitPos and tr.HitPos:DistToSqr(ply:EyePos()) < 110 * 110 then
        local tag = TagNear(tr.HitPos, 50)
        if tag then
            ply.lcScavNext = CurTime() + 0.6
            local ok, why = LC.CleanTag(ply, tag)
            if not ok and why then ply:ChatPrint(why) end
            return
        end
    end
    local key2, pos, kind = LC.BinAt(ply)
    if not key2 then return end
    ply.lcScavNext = CurTime() + 0.6
    local ok, why = LC.Scavenge(ply, key2, pos, kind)
    if not ok and why then ply:ChatPrint(why) end
end)

hook.Add("PlayerSay", "LivingCityScavengeChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!donate" then
        local ok, why = LC.Donate(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
    if t == "!fish" then
        if not LC.HasItem(ply, "fishing_line") then ply:ChatPrint("You need a fishing line (the Commissary sells them).") return "" end
        local ok, why = Fish(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
end)

hook.Add("LivingCityTagged", "LivingCityRumorsTags", function(ply, t)
    if LC.AddRumor then
        LC.AddRumor({ "Someone painted the lambda up " .. (LC.DescribePlace and LC.DescribePlace(t.pos) or "on a wall") .. ". Bold.",
            "There's a lambda on the wall " .. (LC.DescribePlace and LC.DescribePlace(t.pos) or "") .. ". Civil Protection will have it off by morning." }, t.pos)
    end
end)
