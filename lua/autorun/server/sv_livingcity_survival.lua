--[[
    Living City: survival

      Hunger and thirst  drain while the city runs. At zero you starve or
                         dehydrate. Prisoners are fed; Overwatch and the
                         Infested don't eat.
      Inventory          F2 or !inv. Eat, drink, cook, fill, drop.
      Water              wade into any water and press E to drink. Untreated
                         water may give you parasites (hungrier, thirstier,
                         coughing fits) until you take antiparasitic tablets.
      Bottles and cans   empty Breen's cans stay in your pocket; glass bottles
                         lying around can be picked up. Fill them in water, then
                         boil them over a stove or fire.
      Cooking            near a stove, fire, oven or burning barrel.
      Wildlife           pigeons, crows and seagulls. Kill one, pocket the
                         carcass, cook it. Headcrabs roam as vermin, and their
                         meat is edible too, if you're desperate.
      Fists              everyone has them. They kill birds, eventually kill a
                         headcrab, and barely bother anything else.
      Fixtures           water vending machines, ration dispensers, commissary
                         terminals, stoves and burning barrels, placed with the
                         editor and spawned with the layout.
]]

if CLIENT then return end

util.AddNetworkString("lci_inv")
util.AddNetworkString("lci_act")
util.AddNetworkString("lcn_effect")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvNeeds    = CreateConVar("lc_needs", "1", FLAGS, "Hunger and thirst (while the city runs)")
local cvHunger   = CreateConVar("lc_hunger_minutes", "60", FLAGS, "Minutes from full to starving")
local cvThirst   = CreateConVar("lc_thirst_minutes", "40", FLAGS, "Minutes from full to dehydrated")
local cvStarve   = CreateConVar("lc_starve_damage", "3", FLAGS, "Damage every 5 seconds at zero hunger or thirst")
local cvSize     = CreateConVar("lc_inventory_size", "12", FLAGS, "How many items a person can carry")
local cvBirds    = CreateConVar("lc_birds", "6", FLAGS, "Birds around the city")
local cvVermin   = CreateConVar("lc_vermin", "2", FLAGS, "Headcrabs roaming the city outside infestation zones")
local cvRation   = CreateConVar("lc_ration_interval", "600", FLAGS, "Seconds between ration dispenser allocations (halved during rations)")
local cvVend     = CreateConVar("lc_vending_price", "2", FLAGS, "Credits per can from a vending machine")
local cvFists    = CreateConVar("lc_give_fists", "1", FLAGS, "Give everyone fists in Sandbox")

local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Inventory (saved by SteamID)
------------------------------------------------------------------------

local function Inv(ply)
    if ply.lcInv then return ply.lcInv end
    local raw = ply:GetPData("lci_inv", "")
    local t = raw ~= "" and util.JSONToTable(raw) or nil
    ply.lcInv = istable(t) and t or {}
    return ply.lcInv
end

local function SaveInv(ply) ply:SetPData("lci_inv", util.TableToJSON(Inv(ply))) end
LC.Inventory = Inv

function LC.SendInv(ply, open)
    local t = { items = Inv(ply), size = cvSize:GetInt(), open = open == true }
    if LC.InvExtras then LC.InvExtras(ply, t) end -- stash, disguise, papers (sv_livingcity_underground.lua)
    LC.SendCompressed("lci_inv", t, { ply })
end

function LC.InvCount(ply)
    local n = 0
    for _, c in pairs(Inv(ply)) do n = n + c end
    return n
end

function LC.InvSpace(ply) return cvSize:GetInt() - LC.InvCount(ply) end
function LC.HasItem(ply, id, n) return (Inv(ply)[id] or 0) >= (n or 1) end

function LC.GiveItem(ply, id, n)
    n = n or 1
    if not LCS.Items[id] or LC.InvSpace(ply) < n then return false end
    local inv = Inv(ply)
    inv[id] = (inv[id] or 0) + n
    SaveInv(ply)
    LC.SendInv(ply)
    return true
end

function LC.TakeItem(ply, id, n)
    n = n or 1
    local inv = Inv(ply)
    if (inv[id] or 0) < n then return false end
    inv[id] = inv[id] - n
    if inv[id] <= 0 then inv[id] = nil end
    SaveInv(ply)
    LC.SendInv(ply)
    return true
end

function LC.SpawnWorldItem(id, pos, ang, vel)
    local e = ents.Create("lc_item")
    if not IsValid(e) then return nil end
    e:SetNW2String("lc_item", id)
    e:SetPos(pos)
    if ang then e:SetAngles(ang) end
    e:Spawn()
    e:Activate()
    if vel then
        local phys = e:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() phys:SetVelocity(vel) end
    end
    return e
end

local function Front(ply, dist) return ply:GetPos() + ply:GetForward() * (dist or 40) + Vector(0, 0, 30) end
LC.InFrontOf = Front

-- Give an item, or drop it at their feet if their pockets are full.
function LC.GiveOrDrop(ply, id, n)
    for _ = 1, n or 1 do
        if not LC.GiveItem(ply, id, 1) then
            LC.SpawnWorldItem(id, Front(ply, 30))
            ply:ChatPrint("Your pockets are full. " .. (LCS.Items[id] and LCS.Items[id].name or id) .. " is on the ground.")
        end
    end
end

------------------------------------------------------------------------
-- Hunger, thirst, parasites
------------------------------------------------------------------------

function LC.Hunger(ply) return ply:GetNW2Float("lcn_hunger", 100) end
function LC.Thirst(ply) return ply:GetNW2Float("lcn_thirst", 100) end

function LC.Feed(ply, hunger, thirst)
    ply:SetNW2Float("lcn_hunger", math.Clamp(LC.Hunger(ply) + (hunger or 0), 0, 100))
    ply:SetNW2Float("lcn_thirst", math.Clamp(LC.Thirst(ply) + (thirst or 0), 0, 100))
end

local function HasParasites(ply) return ply:GetNW2Float("lcn_parasites", 0) > CurTime() end
LC.HasParasites = HasParasites

local function Infect(ply)
    local was = HasParasites(ply)
    ply:SetNW2Float("lcn_parasites", math.max(ply:GetNW2Float("lcn_parasites", 0), CurTime()) + 480)
    if not was then ply:ChatPrint("Your stomach turns. Something in that wasn't clean.") end
end
LC.Infect = Infect

local function Exempt(ply)
    if not ply:Alive() or LC.PlayerIsZombie(ply) then return true end
    if LC.Prisoners and LC.Prisoners[ply] then return true end
    if LC.FactionsActive and LC.FactionsActive() and ply:GetNW2String("lcf_faction", "") == "ota" then return true end
    return false
end

local COUGHS = { "ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav" }

timer.Create("LivingCityNeeds", 5, 0, function()
    local on = cvNeeds:GetBool() and LC.Running
    SetGlobal2Bool("lc_needs_on", on and true or false)
    if not on then return end
    local now = CurTime()
    local hDrain = 100 / math.max(1, cvHunger:GetFloat() * 60) * 5
    local tDrain = 100 / math.max(1, cvThirst:GetFloat() * 60) * 5
    for _, ply in ipairs(player.GetAll()) do
        if not Exempt(ply) then
            local mult = HasParasites(ply) and 2 or 1
            LC.Feed(ply, -hDrain * mult, -tDrain * mult)
            local h, t = LC.Hunger(ply), LC.Thirst(ply)

            for _, need in ipairs({ { "hunger", h, "You're getting hungry.", "You're starving." },
                                    { "thirst", t, "Your mouth is dry.", "You're badly dehydrated." } }) do
                local key = "lcnWarn" .. need[1]
                local level = need[2] <= 0 and 3 or (need[2] < 10 and 2 or (need[2] < 25 and 1 or 0))
                if level > (ply[key] or 0) and level < 3 then ply:ChatPrint(level == 1 and need[3] or need[4]) end
                ply[key] = level
            end

            local dmg = ((h <= 0) and 1 or 0) + ((t <= 0) and 1 or 0)
            if dmg > 0 then
                ply:TakeDamage(dmg * cvStarve:GetFloat(), game.GetWorld(), game.GetWorld())
                if now > (ply.lcnStarveMsg or 0) then
                    ply.lcnStarveMsg = now + 30
                    ply:ChatPrint(h <= 0 and t <= 0 and "You are starving and dehydrated." or (h <= 0 and "You are starving." or "You are dehydrated."))
                end
            end

            if HasParasites(ply) and now > (ply.lcnCough or 0) then
                ply.lcnCough = now + 30
                ply:EmitSound(Pick(COUGHS), 70)
                ply:TakeDamage(1, game.GetWorld(), game.GetWorld())
            end
        end
    end
end)

hook.Add("PlayerSpawn", "LivingCityNeeds", function(ply)
    if not ply.lcnInit then
        ply.lcnInit = true
        ply:SetNW2Float("lcn_hunger", 80)
        ply:SetNW2Float("lcn_thirst", 80)
    elseif ply.lcnDied then
        ply.lcnDied = nil
        ply:SetNW2Float("lcn_hunger", math.max(LC.Hunger(ply), 60))
        ply:SetNW2Float("lcn_thirst", math.max(LC.Thirst(ply), 60))
    end
end)
hook.Add("PlayerDeath", "LivingCityNeeds", function(ply) ply.lcnDied = true end)
hook.Add("LivingCityIncarcerated", "LivingCityNeeds", function(target)
    if IsValid(target) and target:IsPlayer() then
        target:SetNW2Float("lcn_hunger", math.max(LC.Hunger(target), 50))
        target:SetNW2Float("lcn_thirst", math.max(LC.Thirst(target), 50))
    end
end)

------------------------------------------------------------------------
-- Eating and drinking
------------------------------------------------------------------------

local function Effect(ply, kind, forget)
    net.Start("lcn_effect")
    net.WriteString(kind)
    net.WriteBool(forget == true)
    net.Send(ply)
end

local function BreenWater(ply)
    local forget = math.random() < 0.35
    Effect(ply, "breen", forget)
    if forget then
        ply.lcForgetUntil = CurTime() + 60
        ply:ChatPrint("Where were you going again?")
        if LC.SendQuestState then
            LC.SendQuestState(ply)
            timer.Simple(61, function() if IsValid(ply) and LC.SendQuestState then LC.SendQuestState(ply) end end)
        end
    end
end

function LC.Consume(ply, id)
    local it = LCS.Items[id]
    if not it or not (it.hunger or it.thirst or it.cures) then return false end
    LC.Feed(ply, it.hunger or 0, it.thirst or 0)
    if it.cures == "parasites" then
        ply:SetNW2Float("lcn_parasites", 0)
        ply:ChatPrint("The cramps ease.")
    end
    if it.parasite and math.random() < it.parasite then Infect(ply) end
    if it.breen then BreenWater(ply) end
    if it.uplift then Effect(ply, "coffee") end
    ply:EmitSound((it.thirst and not it.hunger) and "npc/barnacle/barnacle_gulp1.wav" or "npc/barnacle/barnacle_crunch2.wav", 60)
    if it.leaves and not LC.GiveItem(ply, it.leaves, 1) then LC.SpawnWorldItem(it.leaves, Front(ply)) end
    hook.Run("LivingCityConsumed", ply, id)
    return true
end

local function InWater(ply) return ply:WaterLevel() >= 1 end

function LC.DrinkFromWater(ply)
    if not InWater(ply) then return false end
    if (ply.lcnNextDrink or 0) > CurTime() then return false end
    ply.lcnNextDrink = CurTime() + 2
    LC.Feed(ply, 0, 20)
    ply:EmitSound("npc/barnacle/barnacle_gulp2.wav", 60)
    if math.random() < 0.35 then Infect(ply) end
    return true
end

-- Press E while standing in water with nothing in front of you to drink.
hook.Add("KeyPress", "LivingCityDrink", function(ply, key)
    if key ~= IN_USE or not InWater(ply) then return end
    local tr = ply:GetEyeTrace()
    if IsValid(tr.Entity) and tr.HitPos:DistToSqr(ply:EyePos()) < 100 * 100 then return end
    LC.DrinkFromWater(ply)
end)

------------------------------------------------------------------------
-- Cooking and filling
------------------------------------------------------------------------

local HEAT_CLASSES = { lc_stove = true, lc_fire = true, env_fire = true, entityflame = true }

function LC.NearHeat(ply)
    for _, e in ipairs(ents.FindInSphere(ply:GetPos(), 150)) do
        if HEAT_CLASSES[e:GetClass()] then return true end
        local m = string.lower(e:GetModel() or "")
        if m ~= "" and (string.find(m, "stove", 1, true) or string.find(m, "furnace", 1, true) or string.find(m, "oven", 1, true)) then
            return true
        end
        if e.IsOnFire and e:IsOnFire() then return true end
    end
    return false
end

function LC.InvAction(ply, action, id)
    local it = id and LCS.Items[id]
    if LC.UndergroundAction and LC.UndergroundAction(ply, action, id) then return end -- wear, papers, tools, stash
    if action == "drinkwater" then
        if not LC.DrinkFromWater(ply) then ply:ChatPrint("You need to be standing in water.") end
        return
    end
    if not it or not LC.HasItem(ply, id) then return end

    if action == "use" then
        if not (it.hunger or it.thirst or it.cures) then return ply:ChatPrint("You can't eat that.") end
        LC.TakeItem(ply, id)
        LC.Consume(ply, id)
    elseif action == "cook" then
        if not it.cooksTo then return ply:ChatPrint("Cooking won't help that.") end
        if not LC.NearHeat(ply) then return ply:ChatPrint("You need a stove or a fire.") end
        LC.TakeItem(ply, id)
        LC.GiveItem(ply, it.cooksTo)
        ply:EmitSound("ambient/fire/ignite.wav", 60)
        ply:ChatPrint(it.name .. " becomes " .. string.lower(LCS.Items[it.cooksTo].name) .. ".")
    elseif action == "fill" then
        if not it.fillTo then return end
        if not InWater(ply) then return ply:ChatPrint("Stand in water to fill it.") end
        LC.TakeItem(ply, id)
        LC.GiveItem(ply, it.fillTo)
        ply:EmitSound("ambient/water/water_splash1.wav", 60)
    elseif action == "drop" then
        LC.TakeItem(ply, id)
        LC.SpawnWorldItem(id, Front(ply))
    end
end

net.Receive("lci_act", function(_, ply)
    local action, id = net.ReadString(), net.ReadString()
    LC.InvAction(ply, action, id ~= "" and id or nil)
    LC.SendInv(ply, true)
end)

hook.Add("ShowTeam", "LivingCityInventory", function(ply) LC.SendInv(ply, true) end)
concommand.Add("lci_inv", function(ply) if IsValid(ply) then LC.SendInv(ply, true) end end)
hook.Add("PlayerSay", "LivingCityInventoryChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!inv" or t == "!inventory" then LC.SendInv(ply, true) return "" end
end)
hook.Add("PlayerInitialSpawn", "LivingCityInventory", function(ply)
    timer.Simple(3, function() if IsValid(ply) then LC.SendInv(ply) end end)
end)

-- Loose cans and glass bottles in the world can be pocketed.
local POCKETABLE = {
    ["models/props_junk/popcan01a.mdl"] = "can_empty",
    ["models/props_junk/garbage_glassbottle001a.mdl"] = "bottle_empty",
    ["models/props_junk/garbage_glassbottle002a.mdl"] = "bottle_empty",
    ["models/props_junk/garbage_glassbottle003a.mdl"] = "bottle_empty",
    ["models/props_junk/glassbottle01a.mdl"] = "bottle_empty",
}
hook.Add("PlayerUse", "LivingCityPocket", function(ply, ent)
    if ent:GetClass() ~= "prop_physics" or ent.lcQuest or ent.lcCan then return end
    local id = POCKETABLE[string.lower(ent:GetModel() or "")]
    if not id then return end
    if (ply.lcnNextPocket or 0) > CurTime() then return false end
    ply.lcnNextPocket = CurTime() + 0.5
    if LC.GiveItem(ply, id) then
        ent:Remove()
        ply:ChatPrint("Picked up: " .. LCS.Items[id].name)
    else
        ply:ChatPrint("Your pockets are full.")
    end
    return false
end)

------------------------------------------------------------------------
-- Wildlife and vermin
------------------------------------------------------------------------

LC.Wildlife = LC.Wildlife or {}
local BIRDS = { "npc_pigeon", "npc_crow", "npc_seagull" }
local BIRD_CLASS = { npc_pigeon = true, npc_crow = true, npc_seagull = true }
local CRAB_CLASS = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true }

local function Unseen(pos)
    return LC.FarFromPlayers(pos, 600) and not LC.IsSeen(pos + Vector(0, 0, 30))
end

timer.Create("LivingCityWildlife", 4, 0, function()
    if not LC.Running then return end
    local birds, vermin = 0, 0
    for e, kind in pairs(LC.Wildlife) do
        if not IsValid(e) or e:Health() <= 0 then
            LC.Wildlife[e] = nil
        elseif kind == "bird" then
            birds = birds + 1
        else
            vermin = vermin + 1
        end
    end
    local function Spawn(class, kind)
        local pos = LC.RandomWanderPos("citizen")
        if not pos or not Unseen(pos) then return end
        local e = ents.Create(class)
        if not IsValid(e) then return end
        e:SetPos(pos + Vector(0, 0, 8))
        e:SetAngles(Angle(0, math.random(0, 359), 0))
        e:Spawn()
        e:Activate()
        LC.Wildlife[e] = kind
    end
    if birds < cvBirds:GetInt() then Spawn(Pick(BIRDS), "bird")
    elseif vermin < cvVermin:GetInt() then Spawn("npc_headcrab", "vermin") end
end)

-- Every dead bird or headcrab leaves something you can pick up and cook.
hook.Add("OnNPCKilled", "LivingCityCarcass", function(npc)
    local cls = npc:GetClass()
    local id = BIRD_CLASS[cls] and "raw_bird" or (CRAB_CLASS[cls] and "raw_headcrab") or nil
    if not id then return end
    local pos = npc:GetPos() + Vector(0, 0, 6)
    timer.Simple(0.2, function() LC.SpawnWorldItem(id, pos) end)
end)

------------------------------------------------------------------------
-- Fists: everyone has them, and they're pathetic
------------------------------------------------------------------------

local FIST_CLASSES = { weapon_fists = true }

hook.Add("EntityTakeDamage", "LivingCityFists", function(victim, dmg)
    local inflictor = dmg:GetInflictor()
    local attacker = dmg:GetAttacker()
    local wep = IsValid(inflictor) and inflictor
    if IsValid(attacker) and attacker:IsPlayer() and wep == attacker then wep = attacker:GetActiveWeapon() end
    if not IsValid(wep) or not FIST_CLASSES[wep:GetClass()] then return end
    local cls = victim:GetClass()
    if BIRD_CLASS[cls] then
        dmg:SetDamage(50)          -- one punch
    elseif CRAB_CLASS[cls] then
        dmg:SetDamage(4)           -- a few punches
    else
        dmg:SetDamage(2)           -- people barely notice
    end
end)

hook.Add("PlayerSpawn", "LivingCityFists", function(ply)
    timer.Simple(0.6, function()
        if not IsValid(ply) or not cvFists:GetBool() or LC.IsRP() then return end
        if LC.PlayerIsZombie(ply) then return end
        if not ply:HasWeapon("weapon_fists") then ply:Give("weapon_fists") end
    end)
end)

------------------------------------------------------------------------
-- Fixtures: vending machines, dispensers, terminals, stoves, fires
------------------------------------------------------------------------

LC.Fixtures = LC.Fixtures or {}

-- How high each fixture's bottom sits above the spot you placed it on. The
-- ration dispenser is wall-mounted at about chest height; everything else
-- stands on the floor. (Models have their origin in different places, so the
-- model's own bounds are used to put its bottom exactly here.)
local FIXTURE_LIFT = { dispenser = 34 }

function LC.SeatFixture(e, ground, kind)
    local mins = e:OBBMins()
    e:SetPos(ground + Vector(0, 0, (FIXTURE_LIFT[kind] or 0) - (mins and mins.z or 0)))
end

-- A spot just outside the front of a fixture, `up` units above its bottom.
local function FrontSlot(ent, up, out)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    return ent:LocalToWorld(Vector(maxs.x + (out or 8), 0, mins.z + up))
end
local FIXTURE_CLASS = {
    vending = "lc_vending", dispenser = "lc_dispenser", terminal = "lc_terminal", stove = "lc_stove", fire = "lc_fire",
    dealer = "lc_dealer",
}

function LC.SyncFixtures()
    local want = {}
    for _, p in ipairs(LC.Points or {}) do
        local cls = FIXTURE_CLASS[p.kind]
        if cls then
            local key = string.format("%s_%d_%d_%d", p.kind, math.floor(p.pos.x), math.floor(p.pos.y), math.floor(p.pos.z))
            want[key] = { cls = cls, p = p }
        end
    end
    for key, e in pairs(LC.Fixtures) do
        if not want[key] or not IsValid(e) then
            if IsValid(e) then e:Remove() end
            LC.Fixtures[key] = nil
        end
    end
    for key, w in pairs(want) do
        if not LC.Fixtures[key] then
            local e = ents.Create(w.cls)
            if IsValid(e) then
                e:SetPos(w.p.pos)
                e:SetAngles(Angle(0, w.p.yaw or 0, 0))
                e:Spawn()
                e:Activate()
                LC.SeatFixture(e, w.p.pos, w.p.kind)
                e.lcFixture = true
                LC.Fixtures[key] = e
            end
        end
    end
end

hook.Add("LivingCityLayoutChanged", "LivingCityFixtures", function()
    timer.Simple(0, function() local ok, err = pcall(LC.SyncFixtures) if not ok then LC.Error("fixtures", err) end end)
end)

function LC.UseVending(ply, ent)
    if (ent.lcNext or 0) > CurTime() then return false end
    ent.lcNext = CurTime() + 1.5
    local price = cvVend:GetInt()
    local econ = GetConVar("lc_economy")
    if econ and econ:GetBool() and price > 0 then
        if LC.Credits(ply) < price then
            ent:EmitSound("buttons/button10.wav", 65)
            ply:ChatPrint("[Vending] Insert " .. price .. " credits.")
            return false
        end
        LC.AddCredits(ply, -price)
    end
    ent:EmitSound("buttons/button4.wav", 65)
    timer.Simple(0.6, function()
        if not IsValid(ent) then return end
        -- out of the slot at the bottom, about a foot off the ground, rolling gently forward
        LC.SpawnWorldItem("water", FrontSlot(ent, 14, 6), nil, ent:GetForward() * 70 + Vector(0, 0, 30))
        ent:EmitSound("physics/metal/soda_can_impact_hard1.wav", 65)
    end)
    return true
end

-- The dispenser's own animation, if the model has one.
function LC.DispenserAnimate(ent)
    if not IsValid(ent) then return end
    ent:EmitSound("buttons/combine_button1.wav", 65)
    if ent.LookupSequence then
        local seq = ent:LookupSequence("dispense_package")
        if seq and seq >= 0 then
            ent:ResetSequence(seq)
            ent:SetCycle(0)
            timer.Simple(2.5, function()
                local idle = IsValid(ent) and ent:LookupSequence("idle")
                if idle and idle >= 0 then ent:ResetSequence(idle) end
            end)
        end
    end
end

-- From a dispenser, the packet drops out in front of it. Without one, the
-- ration clerk at the counter hands it straight to you.
local function Dispense(ent, ply)
    if IsValid(ent) then
        LC.DispenserAnimate(ent)
        timer.Simple(0.8, function()
            if IsValid(ent) then
                local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                LC.SpawnWorldItem("ration", FrontSlot(ent, (maxs.z - mins.z) * 0.3, 6), nil, ent:GetForward() * 40)
            end
        end)
    elseif IsValid(ply) then
        ply:EmitSound("items/ammo_pickup.wav", 60)
        LC.GiveOrDrop(ply, "ration")
        ply:ChatPrint("[Rations] The clerk at the counter hands you a ration packet.")
    end
end

-- ent may be nil: a line with no dispenser placed at its front.
function LC.UseDispenser(ply, ent)
    local econ = GetConVar("lc_economy")
    local refused
    if econ and econ:GetBool() and LC.Standing(ply) < -50 then
        refused = "[Rations] Your ration privileges have been suspended."
    elseif CurTime() < (ply.lcnRationAt or 0) then
        refused = string.format("[Rations] Next allocation in %d seconds.", math.ceil(ply.lcnRationAt - CurTime()))
    end
    local beeper = IsValid(ent) and ent or ply
    if refused and LC.HasItem(ply, "ration_forged") then
        -- a forged card: no questions, usually
        LC.TakeItem(ply, "ration_forged")
        if math.random() < 0.15 then
            beeper:EmitSound("buttons/combine_button_locked.wav", 65)
            ply:ChatPrint("[Rations] Card invalid. This incident has been logged.")
            LC.ReportCrime(ply, "Ration fraud", 120)
            return false
        end
        ply:ChatPrint("[Rations] Card accepted.")
        Dispense(ent, ply)
        hook.Run("LivingCityRationCollected", ply)
        return true
    end
    if refused then
        beeper:EmitSound("buttons/combine_button_locked.wav", 65)
        ply:ChatPrint(refused)
        return false
    end
    local interval = cvRation:GetFloat() * (LC.Event == "rations" and 0.5 or 1)
    ply.lcnRationAt = CurTime() + interval
    Dispense(ent, ply)
    if LC.AddStanding then LC.AddStanding(ply, 1) end
    if LC.AddCredits then LC.AddCredits(ply, 2, "ration coupon") end
    hook.Run("LivingCityRationCollected", ply)
    return true
end

-- Players at the head of a ration line get served too: stand at the counter
-- for a few seconds. The NPCs behind you wait their turn.
function LC.ServePlayersAtLine(g, line, now)
    local front = line.slots[1] and line.slots[1].pos
    if not front then return false end
    local busy = false
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetPos():DistToSqr(front) < 80 * 80 and not (LC.InCustody and LC.InCustody(ply)) then
            busy = true
            if ply.lcCounterLine ~= g then
                ply.lcCounterLine, ply.lcCounterAt = g, now + 3
                ply:ChatPrint("[Rations] Wait at the counter.")
            elseif now >= ply.lcCounterAt then
                ply.lcCounterAt = now + 30 -- served (or refused); don't keep asking
                LC.UseDispenser(ply, LC.LineDispenser and LC.LineDispenser(g) or nil)
            end
        elseif ply.lcCounterLine == g then
            ply.lcCounterLine = nil
        end
    end
    return busy
end
