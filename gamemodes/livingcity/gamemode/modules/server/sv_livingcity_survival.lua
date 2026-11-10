--[[
    Living City: survival

      Hunger and thirst  drain while the city runs. At zero you starve or
                         dehydrate. Prisoners are fed; Overwatch and the
                         Infested don't eat.
      Inventory          F4 or !inv. Eat, drink, cook, fill, drop.
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
local cvDropsKept = CreateConVar("lc_drops_kept", "30", FLAGS, "Things one player has dropped on the ground at once; past that, the oldest is cleared away (stops endless piles)")
local cvStarve   = CreateConVar("lc_starve_damage", "3", FLAGS, "Damage every 5 seconds at zero hunger or thirst")
local cvSize     = CreateConVar("lc_inventory_size", "12", FLAGS, "How many items a person can carry")
local cvWeighed  = CreateConVar("lc_inventory_weight", "1", FLAGS, "Pockets are limited by weight and size (1), or by number of items (0, lc_inventory_size)")
local cvKg       = CreateConVar("lc_carry_kg", "12", FLAGS, "Kilograms a person can carry (a satchel adds more)")
local cvBulky    = CreateConVar("lc_carry_bulky", "1", FLAGS, "Large things (a shotgun, a uniform, a crate) a person can carry at once (a satchel adds one)")
local cvBirds    = CreateConVar("lc_birds", "4", FLAGS, "Birds around the city")
local cvVermin   = CreateConVar("lc_vermin", "2", FLAGS, "Headcrabs roaming the city outside infestation zones")
local cvRation   = CreateConVar("lc_ration_interval", "1500", FLAGS, "Seconds between ration dispenser allocations (halved during rations)")
local cvVend     = CreateConVar("lc_vending_price", "2", FLAGS, "Credits per can from a vending machine")
local cvHackOut  = CreateConVar("lc_machine_hack_out", "5", FLAGS, "The fewest a hacked vending machine or ration dispenser spits out (cans or ration packets)")
local cvHackMax  = CreateConVar("lc_machine_hack_max", "8", FLAGS, "The most a hacked vending machine or ration dispenser spits out (a random number from lc_machine_hack_out to this)")
-- (31 October: 3 became 5 to 8, a risk worth taking. A server still on the old 3 moves to 5 once.)
if cvHackOut:GetString() == "3" then
    if cvHackOut.SetString then cvHackOut:SetString("5") elseif RunConsoleCommand then RunConsoleCommand("lc_machine_hack_out", "5") end
end
local cvHackCool = CreateConVar("lc_machine_hack_cooldown", "10", FLAGS, "Minutes before a hacked vending machine or ration dispenser can be hacked again")
local cvFists    = CreateConVar("lc_give_fists", "1", FLAGS, "Everyone has fists")

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

------------------------------------------------------------------------
-- Spoilage: meat and fish, raw or cooked, go off after one city day
-- (the owner, 7 November: so nobody hoards them). Each unit remembers when
-- it was got (a real-time stamp, so it rots while you're away too), and the
-- pockets screen shows the city hours it has left. Items with spoils = true
-- in LCS.Items.
------------------------------------------------------------------------

LC.SpoilClock = os.time -- (tests set their own)

local function Stamps(ply)
    if ply.lcSpoil then return ply.lcSpoil end
    local raw = ply:GetPData("lci_spoil", "")
    local t = raw ~= "" and util.JSONToTable(raw) or nil
    ply.lcSpoil = istable(t) and t or {}
    return ply.lcSpoil
end
local function SaveStamps(ply) ply:SetPData("lci_spoil", util.TableToJSON(Stamps(ply))) end

function LC.Spoils(id) local it = LCS.Items[id] return it ~= nil and it.spoils == true end

-- One city day in real seconds (lc_day_minutes): how long meat keeps.
function LC.SpoilSecs()
    local cv = GetConVar("lc_day_minutes")
    return math.max(5, cv and cv:GetFloat() or 60) * 60
end

-- City hours left before a unit got at `born` goes off.
function LC.SpoilHoursLeft(born)
    local perHour = LC.SpoilSecs() / 24
    return math.max(0, 24 - (LC.SpoilClock() - (born or LC.SpoilClock())) / perHour)
end

-- The stamps of one kind in their pockets, oldest first, kept in step with the count.
local function StampsOf(ply, id)
    local all = Stamps(ply)
    local s = all[id] or {}
    all[id] = s
    local n = Inv(ply)[id] or 0
    while #s > n do table.remove(s) end              -- (more stamps than units: the newest go)
    while #s < n do s[#s + 1] = LC.SpoilClock() end  -- (a unit with no stamp: from now)
    table.sort(s)
    if n == 0 then all[id] = nil end
    return s
end

-- When the oldest unit of a kind in their pockets was got (nil: it doesn't spoil, or they have none).
function LC.SpoilOldest(ply, id)
    if not LC.Spoils(id) or not Inv(ply)[id] then return nil end
    return StampsOf(ply, id)[1]
end

-- For the pockets screen: id -> city hours the oldest unit has left.
function LC.SpoilView(ply)
    local out, any = {}, false
    for id in pairs(Inv(ply)) do
        local born = LC.SpoilOldest(ply, id)
        if born then out[id] = math.floor(LC.SpoilHoursLeft(born) * 10 + 0.5) / 10 any = true end
    end
    return any and out or nil
end

-- Throw out what has gone off. Returns how many units went.
function LC.SpoilCheck(ply, quiet)
    if LC.Relaxed and LC.Relaxed(ply) then return 0 end -- (Relaxed survival: nothing goes off)
    local inv, gone = Inv(ply), 0
    for id, n in pairs(inv) do
        if LC.Spoils(id) then
            local s, k = StampsOf(ply, id), 0
            while s[1] and LC.SpoilHoursLeft(s[1]) <= 0 do table.remove(s, 1) k = k + 1 end
            if k > 0 then
                inv[id] = n - k
                if inv[id] <= 0 then inv[id] = nil Stamps(ply)[id] = nil end
                gone = gone + k
                if not quiet then
                    local name = string.lower(LCS.Items[id].name)
                    local msg = k == 1 and ("Your " .. name .. " has gone off. You throw it out.")
                        or (k .. " x " .. name .. " have gone off. You throw them out.")
                    ply:ChatPrint("[Pockets] " .. msg)
                    if LC.Notice then LC.Notice(ply, "info", "Gone off", msg) end
                end
            end
        end
    end
    if gone > 0 then
        SaveInv(ply) SaveStamps(ply)
        LC.SendInv(ply)
        hook.Run("LivingCityInventoryChanged", ply)
    end
    return gone
end

timer.Create("LivingCitySpoil", 20, 0, function()
    for _, p in ipairs(player.GetAll()) do
        if p.lcInv then LC.SpoilCheck(p) end
    end
end)

function LC.SendInv(ply, open)
    local t = { items = Inv(ply), size = cvSize:GetInt(), open = open == true }
    if cvWeighed:GetBool() then
        local kg, bulky = LC.CarryLimit(ply)
        t.kg, t.maxKg, t.bulky, t.maxBulky = LC.InvWeight(ply), kg, LC.InvBulky(ply), bulky
    end
    ply:SetNW2Bool("lc_overweight", cvWeighed:GetBool() and t.kg ~= nil and (t.kg > t.maxKg + 0.001 or t.bulky > t.maxBulky))
    if LC.InvExtras then LC.InvExtras(ply, t) end -- stash, disguise, papers (sv_livingcity_underground.lua)
    t.spoil = LC.SpoilView(ply) -- meat and fish: city hours left
    LC.SendCompressed("lci_inv", t, { ply })
end

function LC.InvCount(ply)
    local n = 0
    for id, c in pairs(Inv(ply)) do
        if not (LCS.Items[id] and LCS.Items[id].doc) then n = n + c end -- (your papers take no room)
    end
    return n
end

function LC.HasItem(ply, id, n) return (Inv(ply)[id] or 0) >= (n or 1) end

-- What's in their pockets of a kind (a test on the item's definition): id -> count.
function LC.ItemsWhere(ply, test)
    local out = {}
    for id, n in pairs(Inv(ply)) do
        local it = LCS.Items[id]
        if it and test(it) then out[id] = n end
    end
    return out
end

-- Weight and size -------------------------------------------------------

-- A disguise you have on (a bought uniform, sv_livingcity_underground.lua) still takes its room:
-- it goes back in your pockets when you take it off, so nothing else may fill its place while
-- it's worn (the owner, 7 November: out of the CP uniform, it dropped as a suitcase and wouldn't
-- go back in, however many small things were dropped).
local function Worn(ply, inv)
    if inv and inv ~= Inv(ply) then return nil end
    local id = IsValid(ply) and ply.lcdItem
    return id and LCS.Items[id] and id or nil
end

function LC.InvWeight(ply, inv)
    local kg = 0
    for id, c in pairs(inv or Inv(ply)) do kg = kg + LCS.Weight(id) * c end
    local worn = Worn(ply, inv)
    if worn then kg = kg + LCS.Weight(worn) end
    return math.floor(kg * 100 + 0.5) / 100
end

function LC.InvBulky(ply, inv)
    local n = 0
    for id, c in pairs(inv or Inv(ply)) do if LCS.IsBulky(id) then n = n + c end end
    local worn = Worn(ply, inv)
    if worn and LCS.IsBulky(worn) then n = n + 1 end
    return n
end

-- How much this person can carry: kilograms and large things. The best bag they have counts.
function LC.CarryLimit(ply)
    local kg, bulky = cvKg:GetFloat(), cvBulky:GetInt()
    local bestKg, bestBulky = 0, 0
    for id in pairs(Inv(ply)) do
        local bag = LCS.Items[id] and LCS.Items[id].bag
        if bag then bestKg, bestBulky = math.max(bestKg, bag.kg or 0), math.max(bestBulky, bag.bulky or 0) end
    end
    return kg + bestKg, bulky + bestBulky
end

-- Can they take n more of this? ok, or false and why.
function LC.CanCarry(ply, id, n)
    n = n or 1
    if LCS.Items[id] and LCS.Items[id].doc then return true end -- (your papers always fit)
    if not cvWeighed:GetBool() then
        if cvSize:GetInt() - LC.InvCount(ply) < n then return false, "Your pockets are full." end
        return true
    end
    local inv = Inv(ply)
    local maxKg, maxBulky = LC.CarryLimit(ply)
    local it = LCS.Items[id]
    if it and it.bag then -- a better bag makes room for itself
        maxKg = math.max(maxKg, cvKg:GetFloat() + (it.bag.kg or 0))
        maxBulky = math.max(maxBulky, cvBulky:GetInt() + (it.bag.bulky or 0))
    end
    if LCS.IsBulky(id) and LC.InvBulky(ply, inv) + n > maxBulky then
        return false, "You've no room for something that size."
    end
    if LC.InvWeight(ply, inv) + LCS.Weight(id) * n > maxKg + 0.001 then
        return false, "That's more than you can carry."
    end
    return true
end

-- Why it won't fit, in full: which limit, and the numbers (the owner, 7 November: "pockets full"
-- after dropping three or four small things, when it was the large-things limit all along).
function LC.CarryWhy(ply, id, n)
    n = n or 1
    local ok, why = LC.CanCarry(ply, id, n)
    if ok then return nil end
    if not cvWeighed:GetBool() then return why end
    local inv = Inv(ply)
    local maxKg, maxBulky = LC.CarryLimit(ply)
    local big = LC.InvBulky(ply, inv)
    if LCS.IsBulky(id) and big + n > maxBulky then
        return string.format("No room for something that size: you're carrying %d large thing%s, and can manage %d. Drop or stash something large first (a satchel adds one).",
            big, big == 1 and "" or "s", maxBulky)
            .. (Worn(ply) and LCS.IsBulky(Worn(ply)) and " (The clothes you have on count: they go back in your pockets when you change.)" or "")
    end
    return string.format("Too heavy: you're carrying %.1f of %.1f kg, and it weighs %.1f.", LC.InvWeight(ply, inv), maxKg, LCS.Weight(id) * n)
end

-- How many of something (a half-kilo something, if not said) they can still take.
function LC.InvSpace(ply, id)
    if not cvWeighed:GetBool() then return cvSize:GetInt() - LC.InvCount(ply) end
    local maxKg, maxBulky = LC.CarryLimit(ply)
    local w = id and LCS.Weight(id) or 0.5
    local n = w > 0 and math.floor((maxKg - LC.InvWeight(ply) + 0.001) / w) or 99
    if id and LCS.IsBulky(id) then n = math.min(n, maxBulky - LC.InvBulky(ply)) end
    return math.max(0, n)
end

-- born: when meat or fish was got (a real-time stamp; now when nil), for spoilage.
function LC.GiveItem(ply, id, n, born)
    n = n or 1
    if not LCS.Items[id] or not LC.CanCarry(ply, id, n) then return false end
    local inv = Inv(ply)
    if LC.Spoils(id) then
        local s = StampsOf(ply, id) -- (in step with the count before it grows)
        for _ = 1, n do s[#s + 1] = born or LC.SpoilClock() end
        table.sort(s)
        Stamps(ply)[id] = s
    end
    inv[id] = (inv[id] or 0) + n
    if LC.Spoils(id) then SaveStamps(ply) end
    SaveInv(ply)
    LC.SendInv(ply)
    hook.Run("LivingCityInventoryChanged", ply)
    return true
end

function LC.TakeItem(ply, id, n)
    n = n or 1
    local inv = Inv(ply)
    if (inv[id] or 0) < n then return false end
    if LC.Spoils(id) then
        local s = StampsOf(ply, id)
        for _ = 1, n do table.remove(s, 1) end -- (the oldest go first: you eat, cook or hand over the oldest)
    end
    inv[id] = inv[id] - n
    if inv[id] <= 0 then inv[id] = nil Stamps(ply)[id] = nil end
    if LC.Spoils(id) then SaveStamps(ply) end
    SaveInv(ply)
    LC.SendInv(ply)
    hook.Run("LivingCityInventoryChanged", ply)
    return true
end

function LC.SpawnWorldItem(id, pos, ang, vel, born)
    local e = ents.Create("lc_item")
    if not IsValid(e) then return nil end
    e:SetNW2String("lc_item", id)
    e:SetPos(pos)
    if ang then e:SetAngles(ang) end
    e:Spawn()
    e:Activate()
    e.lcBorn = CurTime()
    if born and LC.Spoils(id) then e.lcBornAt = born end -- (meat keeps its age on the ground)
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
            ply:ChatPrint((LC.CarryWhy(ply, id, 1) or "Your pockets are full.") .. " " .. (LCS.Items[id] and LCS.Items[id].name or id) .. " is on the ground.")
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

local function HasParasites(ply)
    if LC.Relaxed and LC.Relaxed(ply) then return false end -- (Relaxed survival has none: sv_livingcity_survivalmode.lua)
    return ply:GetNW2Float("lcn_parasites", 0) > CurTime()
end
LC.HasParasites = HasParasites

local function Infect(ply)
    if LC.Relaxed and LC.Relaxed(ply) then return end -- (Relaxed survival: no parasites)
    local was = HasParasites(ply)
    ply:SetNW2Float("lcn_parasites", CurTime() + 1e9) -- they don't wear off: only antiparasitic tablets (a medic, the black market) clear them
    if not was then ply:ChatPrint("Your stomach turns. Something in that wasn't clean.") end
end
LC.Infect = Infect

local function Exempt(ply)
    if not ply:Alive() or LC.PlayerIsZombie(ply) then return true end
    if LC.Prisoners and LC.Prisoners[ply] then return true end
    if LCF.IsOverwatch(ply) then return true end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return true end -- (the Combine feed what they keep)
    if LC.EditorHeld and LC.EditorHeld(ply) then return true end -- (an admin at work with the editor tool)
    return false
end

local COUGHS = { "ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav" }

-- Hunger, thirst and parasites wear the body down, not the armor. The engine
-- lets armor soak up most ordinary damage first, which is right for a bullet
-- and wrong for a cough: a Commander's armor took every one while their
-- health barely moved. So the armor is set aside for the hit and put back.
function LC.BodyDamage(ply, amount)
    if not IsValid(ply) or not ply:Alive() or amount <= 0 then return end
    local armor = ply:Armor()
    if armor > 0 then ply:SetArmor(0) end
    ply:TakeDamage(amount, game.GetWorld(), game.GetWorld())
    if armor > 0 and ply:Alive() then ply:SetArmor(armor) end
end

timer.Create("LivingCityNeeds", 5, 0, function()
    local on = cvNeeds:GetBool() and LC.Running
    SetGlobal2Bool("lc_needs_on", on and true or false)
    if not on then return end
    local now = CurTime()
    local hDrain = 100 / math.max(1, cvHunger:GetFloat() * 60) * 5
    local tDrain = 100 / math.max(1, cvThirst:GetFloat() * 60) * 5
    for _, ply in ipairs(player.GetAll()) do
        -- asleep or dreaming: hunger and thirst wait, and never hurt (or wake) them till they're up
        -- (the owner, 8 November: "hunger/food/thirst do not hurt or affect players until they've woken")
        if not Exempt(ply) and not ply.lcSleep and not ply.lcDreaming then
            local mult = (HasParasites(ply) and 2 or 1) * ((LC.IsRested and LC.IsRested(ply)) and 0.75 or 1) -- (a good night's sleep: sv_livingcity_rest.lua)
                * ((LC.SecondWind and LC.SecondWind(ply)) and 0.75 or 1) -- (beat a nightmare: sv_livingcity_vices.lua)
                * (LC.RelaxedNeedsMul and LC.RelaxedNeedsMul(ply) or 1) -- (Relaxed survival: sv_livingcity_survivalmode.lua)
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
                LC.BodyDamage(ply, dmg * cvStarve:GetFloat())
                if now > (ply.lcnStarveMsg or 0) then
                    ply.lcnStarveMsg = now + 30
                    ply:ChatPrint(h <= 0 and t <= 0 and "You are starving and dehydrated." or (h <= 0 and "You are starving." or "You are dehydrated."))
                end
            end

            if HasParasites(ply) and now > (ply.lcnCough or 0) then
                ply.lcnCough = now + 30
                ply:EmitSound(Pick(COUGHS), 70)
                LC.BodyDamage(ply, 1)
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
    if LC.Unbroken and LC.Unbroken(ply) then ply:ChatPrint("It tastes of nothing. Today it can't touch your head.") return end -- (beat a nightmare)
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
    -- food mends you a little as you eat it (a quarter of what it fills you); drinks don't.
    -- Healing comes from eating, sleeping and medicine, nothing else (no slow mending while awake)
    if (it.hunger or 0) > 0 and not it.poison and ply:Health() < ply:GetMaxHealth() then
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + math.max(1, math.floor(it.hunger / 4))))
    end
    if it.cures == "parasites" then
        ply:SetNW2Float("lcn_parasites", 0)
        ply:ChatPrint("The cramps ease.")
    end
    if it.parasite and math.random() < it.parasite then Infect(ply) end
    if it.poison then
        ply:SetHealth(math.max(1, ply:Health() - it.poison))
        ply:ScreenFade(SCREENFADE.IN, Color(90, 120, 0, 120), 1.5, 0.5)
        ply:ChatPrint("It burns all the way down. Your legs go out from under you.")
    end
    if it.breen then BreenWater(ply) end
    if it.uplift then Effect(ply, "coffee") end
    ply:EmitSound((it.thirst and not it.hunger) and "npc/barnacle/barnacle_gulp1.wav" or "npc/barnacle/barnacle_crunch2.wav", 60)
    if it.leaves and not LC.GiveItem(ply, it.leaves, 1) then LC.SpawnWorldItem(it.leaves, Front(ply)) end
    hook.Run("LivingCityConsumed", ply, id)
    return true
end

local function InWater(ply) return ply:WaterLevel() >= 1 end

-- Seeing something, not just being near it. A sink on the far side of a wall
-- (behind the ladder you just pressed E on) is close but not in view, and
-- you can't drink from it. Nothing of a map's own props is an entity to ask,
-- so it's the line from your eye: if the map's walls cross it well short of
-- the spot, something's in the way. (Props don't count as walls here: the
-- sink isn't hiding itself.)
local function ClearLine(ply, pos, slack)
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = pos, mask = MASK_SOLID_BRUSHONLY, filter = ply })
    return not tr.Hit or tr.HitPos:DistToSqr(pos) <= slack * slack
end

-- Can your eye see some part of a fixture standing at pos (its base, middle, top)?
function LC.CanSeeFixture(ply, pos)
    return ClearLine(ply, pos + Vector(0, 0, 20), 8) or ClearLine(ply, pos + Vector(0, 0, 40), 8) or ClearLine(ply, pos, 8)
end

-- Is what you're pointing at (the trace you aimed with) a prop, not a bare wall?
-- A wall hides what's behind it; a prop stands in front of it. Looking at the
-- world itself (a ladder, a wall with a sink the other side) hits the same
-- point whether or not props are counted.
function LC.AimedAtProp(ply, tr)
    local eye = ply:EyePos()
    local dir = tr.HitPos - eye
    local dist = dir:Length()
    if dist < 1 then return true end
    dir:Normalize()
    local brush = util.TraceLine({ start = eye, endpos = eye + dir * (dist + 4), mask = MASK_SOLID_BRUSHONLY, filter = ply })
    return not (brush.Hit and brush.HitPos:DistToSqr(tr.HitPos) < 3 * 3)
end

-- Pointing at one of the map's static props, even one it draws with nothing solid to hit
-- (many sinks): your aim passes close by it, within reach, and nothing but air between
-- your eyes and it (a sink the other side of a wall is behind brushwork, so not this).
function LC.AimingAtFixture(ply, fx)
    local eye = ply:EyePos()
    local fwd = ply:EyeAngles():Forward()
    for _, h in ipairs({ 10, 20, 30, 40 }) do
        local c = fx.pos + Vector(0, 0, h)
        local v = c - eye
        local along = v:Dot(fwd)
        if along > 0 and along < 110 and (v - fwd * along):Length() < 26 then
            local tr = util.TraceLine({ start = eye, endpos = c, mask = MASK_SOLID_BRUSHONLY, filter = ply })
            if not tr.Hit or tr.HitPos:DistToSqr(c) < 4 * 4 then return true end
        end
    end
    return false
end

-- A sink: one the map has as a prop (dynamic or static), within reach and in view.
function LC.NearSink(ply)
    local at = ply:GetPos() + Vector(0, 0, 40)
    local fx = LC.StaticFixtureNear and LC.StaticFixtureNear(at, "sink", 110)
    if fx and LC.CanSeeFixture(ply, fx.pos) then return true end
    for _, e in ipairs(ents.FindInSphere(at, 110)) do
        if LC.FixtureKindOf and LC.FixtureKindOf(e) == "sink" and LC.CanSeeFixture(ply, e:GetPos()) then return true end
    end
    return false
end

-- Tap water: cleaner than a puddle, still not something to trust.
function LC.DrinkFromSink(ply)
    if (ply.lcnNextDrink or 0) > CurTime() then return false end
    ply.lcnNextDrink = CurTime() + 2
    LC.Feed(ply, 0, 20)
    ply:EmitSound("ambient/water/water_spray1.wav", 55)
    if math.random() < 0.15 then Infect(ply) end
    return true
end

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

-- (a map's burning barrel can be any of these: the engine's fire, its smoke and source, a fire particle)
local HEAT_CLASSES = { lc_stove = true, lc_fire = true, env_fire = true, entityflame = true, env_firesource = true, _firesmoke = true, env_fire_trail = true }

function LC.NearHeat(ply)
    local at = ply:GetPos() + Vector(0, 0, 40)
    if LC.StaticFixtureNear and (LC.StaticFixtureNear(at, "stove", 150) or LC.StaticFixtureNear(at, "fire", 150)) then return true end
    for _, e in ipairs(ents.FindInSphere(at, 170)) do
        local cls = e:GetClass()
        if HEAT_CLASSES[cls] then return true end
        if cls == "info_particle_system" and e.GetKeyValues then
            local fx = string.lower(tostring((e:GetKeyValues() or {}).effect_name or ""))
            if string.find(fx, "fire", 1, true) or string.find(fx, "flame", 1, true) or string.find(fx, "burn", 1, true) then return true end
        end
        local m = string.lower(e:GetModel() or "")
        if m ~= "" and (string.find(m, "stove", 1, true) or string.find(m, "furnace", 1, true) or string.find(m, "oven", 1, true)) then
            return true
        end
        if e.IsOnFire and e:IsOnFire() then return true end
    end
    return false
end

function LC.InvAction(ply, action, id)
    if LC.IsTied and LC.IsTied(ply) then ply:ChatPrint("Your hands are cuffed.") return end
    -- bins, lockers and crates (sv_livingcity_storage.lua)
    local STORAGE = { cput = true, ctake = true, crelease = true, place = true, cstock = true, cbuy = true, ccollect = true, creopen = true }
    if STORAGE[action] and LC.StorageAction then
        return LC.StorageAction(ply, action, id)
    end
    local it = id and LCS.Items[id]
    -- fishing line, seeds, spray cans (sv_livingcity_scavenge.lua)
    if action == "use" and it and it.use and LC.HasItem(ply, id) and LC.ItemUse then
        local ok, why = LC.ItemUse(ply, id)
        if not ok and why then ply:ChatPrint(why) end
        return
    end
    -- making something (sv_livingcity_crafting.lua); id is the recipe
    if action == "make" and LC.Craft then
        local ok, why = LC.Craft(ply, id)
        if not ok and why then ply:ChatPrint(why) end
        return
    end
    if action == "give" and it and LC.GiveTo then
        local ok, why = LC.GiveTo(ply, id)
        if not ok and why then ply:ChatPrint(why) end
        return
    end
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
        -- a crackle and sizzle (the ignite sound was a small bang). Half-Life 2's fire sounds loop
        -- forever, so it's stopped after a moment (it used to keep crackling wherever you went)
        local crackle = "ambient/fire/fire_small" .. math.random(1, 3) .. ".wav"
        ply:EmitSound(crackle, 60)
        timer.Simple(1.5, function() if IsValid(ply) and ply.StopSound then ply:StopSound(crackle) end end)
        ply:ChatPrint(it.name .. " becomes " .. string.lower(LCS.Items[it.cooksTo].name) .. ".")
    elseif action == "fill" then
        if not it.fillTo then return end
        if not InWater(ply) and not LC.NearSink(ply) then return ply:ChatPrint("Stand in water, or by a sink, to fill it.") end
        local atSink = not InWater(ply)
        LC.TakeItem(ply, id)
        LC.GiveItem(ply, it.fillTo)
        -- the tap running into it (a splash was too loud for a sink); dipped in water, a soft slosh
        if atSink then ply:EmitSound("ambient/water/water_spray1.wav", 55, 115, 0.6) else ply:EmitSound("ambient/water/water_splash2.wav", 50, 100, 0.5) end
    elseif action == "drop" then
        if it.doc then return ply:ChatPrint("[Papers] You keep your papers on you. (Stash them at home if you must.)") end
        if LC.IssuedLocked and LC.IssuedLocked(ply, id) then return ply:ChatPrint("That's Combine issue: it stays with you (or another unit).") end
        local born = LC.SpoilOldest(ply, id)
        LC.TakeItem(ply, id)
        local dropped = LC.SpawnWorldItem(id, Front(ply), nil, nil, born)
        if dropped and LC.ClaimEntity then LC.ClaimEntity(ply, dropped) end -- a raid traces it back to you
        -- no endless piles: past lc_drops_kept of your own on the ground, the oldest is cleared away
        if IsValid(dropped) then
            local mine = {}
            for _, e in ipairs(ply.lcDropped or {}) do if IsValid(e) then mine[#mine + 1] = e end end
            mine[#mine + 1] = dropped
            while #mine > math.max(1, cvDropsKept:GetInt()) do
                local old = table.remove(mine, 1)
                if IsValid(old) then old:Remove() end
            end
            ply.lcDropped = mine
        end
    end
end

net.Receive("lci_act", function(_, ply)
    local action, id = net.ReadString(), net.ReadString()
    LC.InvAction(ply, action, id ~= "" and id or nil)
    LC.SendInv(ply, true)
end)

-- F3 (the owner, 7 November: pockets moved from F2 to F3)
hook.Add("ShowSpare1", "LivingCityInventory", function(ply) LC.SendInv(ply, true) end)
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
        ply:ChatPrint(LC.CarryWhy(ply, id) or "Your pockets are full.")
    end
    return false
end)

------------------------------------------------------------------------
-- Wildlife and vermin
------------------------------------------------------------------------

LC.Wildlife = LC.Wildlife or {}
local BIRDS = { "npc_pigeon", "npc_crow", "npc_seagull" }
local BIRD_CLASS = { npc_pigeon = true, npc_crow = true, npc_seagull = true }
-- each bird leaves its own carcass (its own model; the owner, 7 November: a crow left a pigeon)
local BIRD_ITEM = { npc_pigeon = "raw_bird", npc_crow = "raw_crow", npc_seagull = "raw_gull" }
-- each kind of headcrab leaves its own carcass (its own model, and the poison one its venom)
local CRAB_CLASS = { npc_headcrab = "raw_headcrab", npc_headcrab_fast = "raw_fastcrab", npc_headcrab_black = "raw_poisoncrab", npc_headcrab_poison = "raw_poisoncrab" }

local function Unseen(pos)
    return LC.FarFromPlayers(pos, 600) and not LC.IsSeen(pos + Vector(0, 0, 30))
end

-- Open sky overhead (nothing but the skybox straight up): where birds belong
-- (the owner, 7 November: none indoors or underground).
function LC.UnderOpenSky(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 8), endpos = pos + Vector(0, 0, 8192), mask = MASK_SOLID_BRUSHONLY })
    return not tr or tr.HitSky == true or not tr.Hit
end

-- A killed bird or roaming headcrab is replaced only after a gap, at most one
-- of a kind per WILDLIFE_GAP seconds (the owner, 7 November: food scarcity,
-- docs/dev/scarcity-audit.md; it was every 4 s, endless). Filling the city
-- up (a start, or birds shooed away) is as quick as before.
local WILDLIFE_GAP = 90
LC.WildlifeOwed = LC.WildlifeOwed or {}   -- kind = kills not yet replaced
LC.WildlifeNextAt = LC.WildlifeNextAt or {} -- kind = the soonest a replacement may come
hook.Add("OnNPCKilled", "LivingCityWildlifeGap", function(npc)
    local kind = IsValid(npc) and LC.Wildlife[npc]
    if not kind then return end
    LC.WildlifeOwed[kind] = (LC.WildlifeOwed[kind] or 0) + 1
    LC.WildlifeNextAt[kind] = math.max(LC.WildlifeNextAt[kind] or 0, CurTime() + WILDLIFE_GAP)
end)

timer.Create("LivingCityWildlife", 4, 0, function()
    if not LC.Running then LC.WildlifeOwed = {} return end
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
        local pos
        for _ = 1, kind == "bird" and 8 or 1 do -- (a bird needs open sky: a few tries)
            local p = LC.RandomWanderPos("citizen")
            if p and Unseen(p) and not LC.NearDoor(p, 160) and (kind ~= "bird" or LC.UnderOpenSky(p)) then pos = p break end
        end
        if not pos then return false end
        local e = ents.Create(class)
        if not IsValid(e) then return false end
        e:SetPos(pos + Vector(0, 0, 8))
        e:SetAngles(Angle(0, math.random(0, 359), 0))
        e:Spawn()
        e:Activate()
        LC.Wildlife[e] = kind
        return true
    end
    -- (one spawn a tick; a kind owed a replacement for a kill waits for its gap)
    local now = CurTime()
    -- Ready: nil (full), "fill" (short for some other reason) or "replace" (a kill's gap is over)
    local function Ready(kind, have, cap)
        if have >= cap then LC.WildlifeOwed[kind] = nil return nil end
        local owed = math.min(LC.WildlifeOwed[kind] or 0, cap - have)
        LC.WildlifeOwed[kind] = owed > 0 and owed or nil
        if have + owed < cap then return "fill" end
        return now >= (LC.WildlifeNextAt[kind] or 0) and "replace" or nil
    end
    local function Go(class, kind, how)
        if not Spawn(class, kind) or how ~= "replace" then return end
        local owed = (LC.WildlifeOwed[kind] or 1) - 1
        LC.WildlifeOwed[kind] = owed > 0 and owed or nil
        LC.WildlifeNextAt[kind] = now + WILDLIFE_GAP
    end
    local hb = Ready("bird", birds, cvBirds:GetInt())
    local hv = not hb and Ready("vermin", vermin, cvVermin:GetInt())
    if hb then Go(Pick(BIRDS), "bird", hb)
    elseif hv then Go("npc_headcrab", "vermin", hv) end
end)

-- Birds in doorways. A pigeon standing in a door's swing blocks it (the door
-- just stops), so birds never spawn by a door, get shooed out of one when
-- someone opens it, and are moved along if they wander into one.
local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true }
local doorCache, doorCacheAt = {}, -1000

local function Doors()
    if CurTime() - doorCacheAt > 30 then
        doorCache, doorCacheAt = {}, CurTime()
        for cls in pairs(DOOR_CLASSES) do
            for _, d in ipairs(ents.FindByClass(cls)) do doorCache[#doorCache + 1] = d end
        end
    end
    return doorCache
end

local function DoorCenter(d) return d.WorldSpaceCenter and d:WorldSpaceCenter() or d:GetPos() end

-- The door near pos (its middle or its hinge), if any.
function LC.NearDoor(pos, r)
    for _, d in ipairs(Doors()) do
        if IsValid(d) and (DoorCenter(d):DistToSqr(pos) < r * r or d:GetPos():DistToSqr(pos) < r * r) then return d end
    end
    return nil
end

local function Shoo(bird, door)
    local pos = bird:GetPos()
    -- flap off; crows, pigeons and gulls all know how
    bird:Fire("FlyAway", "")
    -- and get out of the swing either way: a few steps away from the door, or
    -- with nobody looking, somewhere else entirely
    local away = pos - DoorCenter(door)
    away.z = 0
    if away:LengthSqr() < 1 then away = Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) end
    away = away:GetNormalized()
    for _, dist in ipairs({ 140, 200, 90 }) do
        local to = pos + away * dist
        local tr = util.TraceHull({ start = pos + Vector(0, 0, 8), endpos = to + Vector(0, 0, 8),
            mins = Vector(-8, -8, 0), maxs = Vector(8, 8, 16), mask = MASK_NPCSOLID, filter = bird })
        if not tr.Hit and not tr.StartSolid then
            bird:SetPos(to + Vector(0, 0, 4))
            return
        end
    end
    if not LC.IsSeen(pos + Vector(0, 0, 20)) then
        local spot = LC.RandomWanderPos("citizen")
        if spot and not LC.NearDoor(spot, 160) and LC.UnderOpenSky(spot) then bird:SetPos(spot + Vector(0, 0, 8)) return end
    end
    bird:Remove() -- nowhere to put it; another bird turns up somewhere sensible
end
LC.ShooBird = Shoo

timer.Create("LivingCityBirdDoors", 1, 0, function()
    for e, kind in pairs(LC.Wildlife) do
        if IsValid(e) and kind == "bird" and e:Health() > 0 then
            local door = LC.NearDoor(e:GetPos(), 80)
            if door then
                e.lcDoorTicks = (e.lcDoorTicks or 0) + 1
                if e.lcDoorTicks >= 2 then e.lcDoorTicks = 0 Shoo(e, door) end -- not just passing through
            else
                e.lcDoorTicks = 0
            end
        end
    end
end)

-- Opening a door scares off any bird in its way, right away.
hook.Add("PlayerUse", "LivingCityBirdDoors", function(ply, ent)
    if not IsValid(ent) or not DOOR_CLASSES[ent:GetClass()] then return end
    for e, kind in pairs(LC.Wildlife) do
        if IsValid(e) and kind == "bird" and e:Health() > 0
            and (DoorCenter(ent):DistToSqr(e:GetPos()) < 110 * 110 or ent:GetPos():DistToSqr(e:GetPos()) < 110 * 110) then
            Shoo(e, ent)
        end
    end
end)

-- Every dead bird or headcrab leaves something you can pick up and cook.
hook.Add("OnNPCKilled", "LivingCityCarcass", function(npc)
    local cls = npc:GetClass()
    local id = BIRD_ITEM[cls] or CRAB_CLASS[cls] or nil
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
        if not IsValid(ply) or LC.PlayerIsZombie(ply) then return end
        if cvFists:GetBool() and not ply:HasWeapon("weapon_fists") then ply:Give("weapon_fists") end
        LC.GiveHands(ply, true) -- you start out with your hands down
    end)
end)

------------------------------------------------------------------------
-- Holstering: empty hands, nothing in view, nothing to swing
------------------------------------------------------------------------

local HANDS = "weapon_lc_hands"

function LC.GiveHands(ply, select)
    if not IsValid(ply) or not ply:Alive() or LC.PlayerIsZombie(ply) then return end
    if not ply:HasWeapon(HANDS) then ply:Give(HANDS) end
    if select then ply:SelectWeapon(HANDS) end
end

-- Remember what you were holding, so drawing again brings it back.
hook.Add("PlayerSwitchWeapon", "LivingCityHolster", function(ply, old, new)
    if IsValid(old) and old:GetClass() ~= HANDS then ply.lcLastWeapon = old:GetClass() end
end)

function LC.ToggleHolster(ply)
    if not IsValid(ply) or not ply:Alive() or LC.PlayerIsZombie(ply) then return end
    local cur = ply:GetActiveWeapon()
    if IsValid(cur) and cur:GetClass() == HANDS then
        local back = ply.lcLastWeapon
        if not back or not ply:HasWeapon(back) then back = ply:HasWeapon("weapon_fists") and "weapon_fists" or nil end
        if back then ply:SelectWeapon(back) end
    else
        if IsValid(cur) then ply.lcLastWeapon = cur:GetClass() end
        LC.GiveHands(ply, true)
    end
end

-- The R that put something away into your hands (the radio's) mustn't draw it straight back out while it's
-- still held down: the hands' own R waits until it's let go.
function LC.HoldReload(ply) if IsValid(ply) then ply.lcReloadHeld = true end end
function LC.ReloadHeld(ply)
    if not IsValid(ply) or ply.lcReloadHeld ~= true then return false end
    if ply.KeyDown and not ply:KeyDown(IN_RELOAD or 8192) then ply.lcReloadHeld = nil return false end -- (let go, whatever was missed)
    return true
end
hook.Add("KeyRelease", "LivingCityHolsterReload", function(ply, key)
    if key == (IN_RELOAD or 8192) and IsValid(ply) then ply.lcReloadHeld = nil end
end)

concommand.Add("lc_holster", function(ply) LC.ToggleHolster(ply) end)
hook.Add("PlayerSay", "LivingCityHolster", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!holster" or t == "/holster" then LC.ToggleHolster(ply) return "" end
end)

------------------------------------------------------------------------
-- Fixtures: vending machines, dispensers, terminals, stoves, fires
------------------------------------------------------------------------

LC.Fixtures = LC.Fixtures or {}

-- How high each fixture's bottom sits above the spot you placed it on. The
-- ration dispenser is wall-mounted at about chest height; everything else
-- stands on the floor. (Models have their origin in different places, so the
-- model's own bounds are used to put its bottom exactly here.)
local FIXTURE_LIFT = { conveyor = 34, dispenser = 34, screen = 60, lawboard = 30, civposter = 50, screen_big = 140, loudspeaker = 180, powerbank = 40 }

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
    dealer = "lc_dealer", locker = "lc_locker", screen = "lc_screen", lawboard = "lc_lawboard", infodesk = "lc_infoclerk", civposter = "lc_civposter", console = "lc_console",
    workbench = "lc_workbench", recycler = "lc_recycler", dataterm = "lc_dataterminal", masterterm = "lc_masterterminal", incinerator = "lc_incinerator",
    hazbarrel = "lc_hazbarrel", -- (sv_livingcity_cleanup.lua)
    transformer = "lc_transformer", forcefield = "lc_forcefield",
    suppressor = "lc_suppressor", -- the Nexus mortar, in BLACK (sv_livingcity_collapse.lua)
    adminpower = "lc_adminpower", -- the Administrator's power: her shield in her last stand (sv_livingcity_collapse.lua)
    powerbank = "lc_powerbank", turret = "npc_turret_floor", -- checkpoints (sv_livingcity_checkpoints.lua)
    barricade_low = "lc_barricade", barricade = "lc_barricade", barricade_tall = "lc_barricade",
    citybin = "lc_citybin", streetlight = "lc_streetlight", loudspeaker = "lc_loudspeaker", screen_big = "lc_screen", tv = "lc_screen",
    intake = "lc_intake", housingterm = "lc_intake", -- Civil Intake and Housing Allocation (sv_livingcity_intake.lua)
    laborterm = "lc_intake", -- Labor Assignment: Union work is given out here (sv_livingcity_labor.lua)
    cpsupply = "lc_cpsupply", -- units are issued supplies here (sv_livingcity_cpsupply.lua)
    conveyor = "lc_conveyor", -- the factory line (sv_livingcity_jobgames.lua)
    bed = "lc_bed", toilet = "lc_toilet", bath = "lc_bath", -- (sv_livingcity_rest.lua, sv_livingcity_hygiene.lua)
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
                e.lcFixtureKind = w.p.kind -- (one class, several kinds: the city screens)
                e:Spawn()
                e:Activate()
                LC.SeatFixture(e, w.p.pos, w.p.kind)
                e.lcFixture = true
                e.lcFixtureKey = key
                e.lcFixturePoint = w.p
                LC.Fixtures[key] = e
            end
        end
    end
end

-- Moved with the physgun (in build mode): the layout moves with it, so it's
-- there next time, and the editor's marker goes where the prop went.
hook.Add("PhysgunDrop", "LivingCityFixtures", function(ply, e)
    if not IsValid(e) or not e.lcFixture or not e.lcFixturePoint then return end
    if not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local p = e.lcFixturePoint
    -- stood upright where it was dropped (a top-heavy generator isn't left leaning), on the floor under it
    e:SetAngles(Angle(0, e:GetAngles().y, 0))
    if not FIXTURE_LIFT[p.kind] and LC.GroundAt then LC.SeatFixture(e, LC.GroundAt(e:WorldSpaceCenter()), p.kind) end
    local mins = e:OBBMins()
    p.pos = e:GetPos() + Vector(0, 0, (mins and mins.z or 0) - (FIXTURE_LIFT[p.kind] or 0))
    p.yaw = e:GetAngles().y
    local key = string.format("%s_%d_%d_%d", p.kind, math.floor(p.pos.x), math.floor(p.pos.y), math.floor(p.pos.z))
    if LC.Fixtures[e.lcFixtureKey] == e then LC.Fixtures[e.lcFixtureKey] = nil end
    LC.Fixtures[key] = e
    e.lcFixtureKey = key
    local phys = e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if IsValid(e.lcScientist) and LC.PlaceScientist then LC.PlaceScientist(e) end -- a lab's scientist goes with it
    LC.SaveData()
    ply:ChatPrint("[Living City] Moved: the " .. p.kind .. " is saved where you put it.")
end)

hook.Add("LivingCityLayoutChanged", "LivingCityFixtures", function()
    timer.Simple(0, function() local ok, err = pcall(LC.SyncFixtures) if not ok then LC.Error("fixtures", err) end end)
end)

function LC.UseVending(ply, ent)
    if IsValid(ent) and ent:GetNW2Bool("lc_nopower", false) then return false end -- (no power: sv_livingcity_power.lua)
    if (ent.lcNext or 0) > CurTime() then return false end
    ent.lcNext = CurTime() + 1.5
    local price = cvVend:GetInt()
    local econ = GetConVar("lc_economy")
    if econ and econ:GetBool() and price > 0 then
        if LC.Credits(ply) < price then
            ent:EmitSound("buttons/button10.wav", 65)
            if not (LC.MachineSpeak and LC.MachineSpeak(ent, ply, "[Vending] Insert " .. price .. " credits.", false)) then ply:ChatPrint("[Vending] Insert " .. price .. " credits.") end
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

-- Stoves, sinks and vending machines the map already has act like the editor's
-- fixtures: press E on one. Dynamic props are found as entities; static ones from
-- the map file (sv_livingcity_staticprops.lua).
local MODEL_KINDS = {
    { "stove", "stove" }, { "furnace", "stove" }, { "oven", "stove" },
    { "sink", "sink" },
    { "toilet", "toilet" }, { "bathtub", "bath" }, { "bath_tub", "bath" }, { "shower", "bath" }, -- (sv_livingcity_hygiene.lua)
    { "vendingmachine", "vending" }, { "vending_machine", "vending" }, { "vending", "vending" },
}

function LC.FixtureKindOf(ent)
    if not IsValid(ent) then return nil end
    local cls = ent:GetClass()
    if cls == "lc_stove" then return "stove" elseif cls == "lc_vending" then return "vending" end
    if string.StartWith(cls, "lc_") then return nil end
    local m = string.lower(ent:GetModel() or "")
    if m == "" then return nil end
    for _, k in ipairs(MODEL_KINDS) do
        if string.find(m, k[1], 1, true) then return k[2] end
    end
    return nil
end

-- A vending machine that's part of the map's geometry: the can rolls out in front of it.
function LC.UseStaticVending(ply, fx)
    if (fx.lcNext or 0) > CurTime() then return false end
    fx.lcNext = CurTime() + 1.5
    local price = cvVend:GetInt()
    local econ = GetConVar("lc_economy")
    if econ and econ:GetBool() and price > 0 then
        if LC.Credits(ply) < price then
            ply:EmitSound("buttons/button10.wav", 65)
            if not (LC.MachineSpeak and LC.MachineSpeak(nil, ply, "[Vending] Insert " .. price .. " credits.", false)) then ply:ChatPrint("[Vending] Insert " .. price .. " credits.") end
            return false
        end
        LC.AddCredits(ply, -price)
    end
    ply:EmitSound("buttons/button4.wav", 65)
    timer.Simple(0.6, function()
        local fwd = fx.ang:Forward()
        LC.SpawnWorldItem("water", fx.pos + fwd * 26 + Vector(0, 0, 14), nil, fwd * 70 + Vector(0, 0, 30))
    end)
    return true
end

local function UseFixture(ply, kind, ent, fx)
    if kind == "vending" then
        if ent then LC.UseVending(ply, ent) else LC.UseStaticVending(ply, fx) end
    elseif kind == "stove" and (ply.lcStoveUse or 0) < CurTime() then
        ply.lcStoveUse = CurTime() + 1
        local home = LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) and not LC.PlayerIsCP(ply)
        local at = (IsValid(ent) and ent:GetPos()) or (fx and fx.pos) or ply:GetPos()
        if home and LC.OpenStashAt then LC.OpenStashAt(ply, at) elseif LC.SendInv then LC.SendInv(ply, true) end
        ply:ChatPrint(home and "[Stove] Cook from your pockets (F3). Your stash is open there too, while you stand by the stove." or "[Stove] Cook from your pockets (F3).")
    elseif kind == "sink" then
        if (ply.lcSinkUse or 0) < CurTime() then
            ply.lcSinkUse = CurTime() + 1
            ply:ChatPrint("[Sink] Fill bottles and cans from your pockets (F3). Boil them before you drink.")
        end
        LC.DrinkFromSink(ply)
    elseif kind == "toilet" and LC.UseToilet then
        LC.UseToilet(ply)
    elseif kind == "bath" and LC.UseBath then
        LC.UseBath(ply)
    end
end

hook.Add("KeyPress", "LivingCityMapFixtures", function(ply, key)
    if key ~= IN_USE or not ply:Alive() then return end
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100, filter = ply })
    local ent = tr.Entity
    if IsValid(ent) and ent ~= game.GetWorld() then
        if string.StartWith(ent:GetClass(), "lc_") then return end -- ours handle themselves
        local kind = LC.FixtureKindOf(ent)
        if kind then UseFixture(ply, kind, ent) end
        return
    end
    -- the map's own static props: the nearest one to where you're pointing,
    -- and only if you're looking at the prop itself. A bare wall (the ladder
    -- you just pressed E on) with a sink the other side of it is not a sink.
    local fx = LC.StaticFixtureNear and tr.Hit and LC.StaticFixtureNear(tr.HitPos, nil, 75)
    if fx and ((LC.AimedAtProp(ply, tr) and LC.CanSeeFixture(ply, fx.pos)) or LC.AimingAtFixture(ply, fx)) then
        UseFixture(ply, fx.kind, nil, fx)
    end
end)

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
-- (the owner, 2026-11-01) a citizen below Trusted gets a short ration: a third less, cutting it close,
-- so birds and headcrabs make up the rest; good standing, or joining the Resistance, is the way out
local cvFullRation = CreateConVar("lc_ration_full_standing", "150", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Civil Standing for the full ration at a dispenser (below it, a short ration: a third less food; 0: everyone gets the full one)")
function LC.RationFor(ply)
    local need = cvFullRation:GetInt()
    if need <= 0 or not IsValid(ply) or (LC.PlayerIsCP and LC.PlayerIsCP(ply)) then return "ration" end
    return (LC.Standing and LC.Standing(ply) >= need) and "ration" or "ration_short"
end
local function Dispense(ent, ply)
    local id = LC.RationFor(ply)
    if IsValid(ent) then
        LC.DispenserAnimate(ent)
        timer.Simple(0.8, function()
            if IsValid(ent) then
                local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                LC.SpawnWorldItem(id, FrontSlot(ent, (maxs.z - mins.z) * 0.3, 6), nil, ent:GetForward() * 40)
            end
        end)
    elseif IsValid(ply) then
        ply:EmitSound("items/ammo_pickup.wav", 60)
        LC.GiveOrDrop(ply, id)
        ply:ChatPrint(id == "ration" and "[Rations] The clerk at the counter hands you a ration packet."
            or "[Rations] The clerk hands you a short ration: a third less than the full one. Good standing (Trusted) earns the full packet.")
    end
end

------------------------------------------------------------------------
-- Hacking them (the multitool): a vending machine spits out its water, a
-- ration dispenser its packets (5 to 8 of them), no credits and no coupon. Ten seconds, keep
-- still; a unit who sees you at it makes you wanted. Then it's empty for
-- lc_machine_hack_cooldown minutes (10).
------------------------------------------------------------------------

local HACKABLE = { lc_vending = "the vending machine", lc_dispenser = "the ration dispenser" }

function LC.HackMachine(ply, ent)
    if not IsValid(ent) or not HACKABLE[ent:GetClass()] then return false, "Aim at a vending machine or a ration dispenser." end
    if not (LC.CanHack and LC.CanHack(ply)) then return false, "You need a multitool to get into it." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    if ent:GetNW2Bool("lc_nopower", false) then return false, "It's dead: no power. Nothing to get out of it." end
    local now = CurTime()
    if (ent.lcHackedUntil or 0) > now then
        return false, string.format("Someone's already emptied it. It'll be restocked in about %d minutes.", math.ceil((ent.lcHackedUntil - now) / 60))
    end
    local name = HACKABLE[ent:GetClass()]
    ent:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 65)
    return LC.StartTask(ply, 10, "Hacking " .. name .. "... keep still", {
        maxMove = 60, cancelText = "You leave it.",
        done = function(p)
            if not IsValid(ent) or (ent.lcHackedUntil or 0) > CurTime() then return end
            ent.lcHackedUntil = CurTime() + cvHackCool:GetFloat() * 60
            ent:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 70)
            local lo = math.max(1, cvHackOut:GetInt())
            local n = math.random(lo, math.max(lo, cvHackMax:GetInt()))
            local dispenser = ent:GetClass() == "lc_dispenser"
            for i = 1, n do
                timer.Simple(0.5 + (i - 1) * 0.6, function()
                    if not IsValid(ent) then return end
                    if dispenser then
                        LC.DispenserAnimate(ent)
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        LC.SpawnWorldItem("ration", FrontSlot(ent, (maxs.z - mins.z) * 0.3, 6), nil, ent:GetForward() * 40 + VectorRand() * 15)
                    else
                        LC.SpawnWorldItem("water", FrontSlot(ent, 14, 6), nil, ent:GetForward() * 70 + Vector(0, 0, 30) + VectorRand() * 20)
                        ent:EmitSound("physics/metal/soda_can_impact_hard1.wav", 65)
                    end
                end)
            end
            p:ChatPrint(dispenser and string.format("[Resistance] The dispenser chokes, and spits out %d ration packets. No coupon, no record.", n)
                or string.format("[Resistance] The machine shudders and drops %d cans. Free water, for once.", n))
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, "Tampering with Union property", 120)
                p:ChatPrint("[Civil Protection] A Civil Protection unit saw you at it.")
            end
            if LC.QuestEvent then LC.QuestEvent("machine_hacked", p, ent) end
            hook.Run("LivingCityMachineHacked", p, ent)
        end,
    })
end

-- ent may be nil: a line with no dispenser placed at its front.
function LC.UseDispenser(ply, ent)
    if IsValid(ent) and ent:GetNW2Bool("lc_nopower", false) then return false end -- (no power: sv_livingcity_power.lua)
    -- a unit's ration voucher (their duty allocation, sv_livingcity_cp.lua): a packet, no card and no wait
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) and LC.HasItem(ply, "ration_voucher") and not (LC.StockLevel and LC.StockLevel() == "empty") then
        LC.TakeItem(ply, "ration_voucher", 1)
        if LC.StockTake then LC.StockTake(1) end
        ply:ChatPrint("[Rations] Voucher accepted.")
        Dispense(ent, ply)
        hook.Run("LivingCityRationCollected", ply)
        return true
    end
    local econ = GetConVar("lc_economy")
    local refused
    if LC.IntakePending and LC.IntakePending(ply) then
        refused = "[Rations] You aren't registered, so you can't have a ration card. Register at Civil Intake, then work a Union shift to earn one." -- (sv_livingcity_intake.lua)
    elseif LC.LacksRationCard and LC.LacksRationCard(ply) then
        refused = "[Rations] No ration card. You earn one for each Union shift you finish (your board, F4), and each ration takes one card."
    elseif econ and econ:GetBool() and LC.Standing(ply) < -50 then
        refused = "[Rations] Your ration privileges have been suspended."
    elseif CurTime() < (ply.lcnRationAt or 0) then
        refused = string.format("[Rations] Next allocation in %d seconds.", math.ceil(ply.lcnRationAt - CurTime()))
    elseif ply.lcRationWithheld then
        -- a reprimand (skipping morning exercise: sv_livingcity_exercise.lua): this one allocation
        local why = ply.lcRationWithheld
        ply.lcRationWithheld = nil
        ply.lcnRationAt = CurTime() + cvRation:GetFloat() * (LC.Event == "rations" and 0.5 or 1)
        refused = "[Rations] Allocation withheld: " .. why .. ". Your next allocation is as normal."
    elseif ply.lcRationDocked then
        -- the PA said it: tolerating noncompliance costs this allocation (sv_livingcity_rations.lua).
        -- (A new life's first ration is docked like any other: the owner, 7 November, said no to skipping it.)
        local d = ply.lcRationDocked
        ply.lcRationDocked = nil
        ply:SetNW2String("lc_ration_docked", "")
        ply.lcnRationAt = CurTime() + cvRation:GetFloat() * (LC.Event == "rations" and 0.5 or 1)
        refused = "[Rations] Allocation withheld: five ration units deducted for tolerating noncompliance"
            .. (d.where and d.where ~= "" and (" (" .. d.why .. " " .. d.where .. ")") or (" (" .. d.why .. ")"))
            .. ". Your next allocation is as normal."
    end
    -- the city's stores (sv_livingcity_stockpile.lua): empty, nothing; low, sometimes nothing
    local lvl = not refused and LC.StockLevel and LC.StockLevel() or nil
    if lvl == "empty" then
        refused = "[Rations] Distribution suspended: the city's stores are empty."
    elseif lvl == "short" and math.random() < 0.35 and not (LC.FirstRationDue and LC.FirstRationDue(ply)) then -- (a new life's first meal is never short: sv_livingcity_nextstep.lua)
        ply.lcnRationAt = CurTime() + 60
        refused = "[Rations] Supply shortfall. The dispenser whirs and gives nothing. Try again in a minute (the stores are low: kitchen and factory shifts, trains and supply drops fill them)."
    end
    local beeper = IsValid(ent) and ent or ply
    if refused and LC.HasItem(ply, "ration_forged") and lvl ~= "empty" then
        -- a forged card: no questions, usually
        LC.TakeItem(ply, "ration_forged")
        hook.Run("LivingCityForgedCard", ply, 1)
        if math.random() < 0.15 then
            beeper:EmitSound("buttons/combine_button_locked.wav", 65)
            ply:ChatPrint("[Rations] Card invalid. This incident has been logged.")
            LC.ReportCrime(ply, "Ration fraud", 120)
            return false
        end
        ply:ChatPrint("[Rations] Card accepted.")
        if LC.StockTake then LC.StockTake(1) end
        Dispense(ent, ply)
        hook.Run("LivingCityRationCollected", ply)
        return true
    end
    if refused then
        -- the dispenser says it (sv_livingcity_machines.lua), or the old way
        if not (LC.MachineSpeak and LC.MachineSpeak(beeper, ply, refused)) then
            beeper:EmitSound("buttons/combine_button_locked.wav", 65)
            ply:ChatPrint(refused)
        end
        return false
    end
    local base = cvRation:GetFloat()
    -- a unit's allocation stays every 10 minutes (the owner, 7 November: only citizens feel the slower dispenser)
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) and LC.DUTY_ALLOCATION_SECONDS then base = math.min(base, LC.DUTY_ALLOCATION_SECONDS) end
    local interval = base * (LC.Event == "rations" and 0.5 or 1) * (LC.RationIntervalMul and LC.RationIntervalMul() or 1) -- cuts during unrest
        * (LC.StockIntervalMul and LC.StockIntervalMul() or 1) -- and while the stores are low
    ply.lcnRationAt = CurTime() + interval
    if LC.StockTake then LC.StockTake(1) end
    -- each ration takes one ration card, earned by finishing a Union shift (sv_livingcity_work.lua);
    -- no credits come with it (the owner: workers need to work)
    if LC.CarriesPapers and LC.CarriesPapers(ply) and LC.TakeItem then LC.TakeItem(ply, "ration_card", 1) end
    Dispense(ent, ply)
    if LC.AddStanding then LC.AddStanding(ply, 1) end
    hook.Run("LivingCityRationCollected", ply)
    return true
end

-- Players at the head of a ration line get served too: stand at the counter
-- for a few seconds. The NPCs behind you wait their turn while you're being
-- served; once you've been (or been refused) and just stand there, they go
-- on past you to the dispenser. (The owner, 7 November: refused at the
-- counter, they stood watching the citizen in spot 1, who never moved: the
-- line waited for them for as long as they stayed.)
function LC.ServePlayersAtLine(g, line, now)
    local front = line.slots[1] and line.slots[1].pos
    if not front then return false end
    local busy = false
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetPos():DistToSqr(front) < 80 * 80 and not (LC.InCustody and LC.InCustody(ply)) then
            if ply.lcCounterLine ~= g then
                ply.lcCounterLine, ply.lcCounterAt = g, now + 3
                ply.lcCounterHold = now + 3.5
                ply:ChatPrint("[Rations] Wait at the counter.")
            elseif now >= ply.lcCounterAt then
                -- served: not again for a while; refused: not until they step away and come back
                -- (it used to try again by itself, and a ration dropped out for someone gone AFK)
                local served = LC.UseDispenser(ply, LC.LineDispenser and LC.LineDispenser(g) or nil)
                ply.lcCounterAt = served and (now + 30) or math.huge
                ply.lcCounterHold = now + 5 -- (the packet comes out; then the line moves on round them)
            end
            if now < (ply.lcCounterHold or 0) then busy = true end
        elseif ply.lcCounterLine == g then
            ply.lcCounterLine = nil
        end
    end
    return busy
end
