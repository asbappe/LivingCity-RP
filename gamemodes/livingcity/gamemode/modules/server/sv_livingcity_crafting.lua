--[[
    Living City: making things, grenades, the arms trade, and getting people out

      Crafting      F3 lists what you can make by hand from what you're
                    carrying, anywhere: lockpicks and bandages. Everything
                    with more to it (guns, ammunition, armour, jammers, bypass
                    charges, smoke bombs, a radio tuned to Freq 7) the
                    Resistance gets from the scientist in its lab
                    (sv_livingcity_lab.lua), and everyone else buys at the
                    black market. Units make nothing: they're issued it
                    (sv_livingcity_cpsupply.lua). Materials come from bins,
                    bodies, salvage, downed scanners and the black market.
      The trade     homemade guns and ammo sell at the black market, and for
                    half as much again to the Resistance quartermaster. So
                    there's money in carrying them across the city (searches
                    find them). Citizens get gun runs on their board.
                    (The lab never charges less than the quartermaster pays.)
      Grenades      units: smoke, flashbangs, and (officers and Overwatch)
                    chlorine gas. They're issued by rank and sold at the
                    Commissary, and carried in your pockets: the Grenades
                    weapon throws them (R picks which). Smoke hides you from
                    units and rebels; a flashbang blinds and deafens; gas
                    chokes anyone without a mask.
      Passing it on !give, or F3 > Give, hands one of something to the person
                    you're looking at. Slipping a prisoner a lockpick under a
                    guard's nose is a crime; unseen, they can pick their own
                    cell door (it takes a while).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvQMBonus = CreateConVar("lc_quartermaster_arms_bonus", "1.5", FLAGS, "What the Resistance quartermaster pays for arms, times the black market price")
local cvQMFood = CreateConVar("lc_qm_food_price", "2", FLAGS, "The most the Resistance quartermaster pays for food or drink (he gives it out free from the supply crate; 0: he won't buy it)")
local cvGasDmg  = CreateConVar("lc_gas_damage", "6", FLAGS, "Poison gas damage per second to anyone without a mask")

local function Pick(t) return t[math.random(#t)] end
local function IsResistance(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end
-- "Private" means nobody is watching: no unit (street or player) has you in
-- sight. A tunnel, a back room or a dead end counts as much as your own block.
local function Private(ply)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 800) then return false end
    for _, o in ipairs(player.GetAll()) do
        if o ~= ply and o:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(o) and o:GetPos():DistToSqr(ply:GetPos()) < 800 * 800 then
            local tr = util.TraceLine({ start = o:EyePos(), endpos = ply:EyePos(), mask = MASK_OPAQUE, filter = o })
            if tr.Fraction > 0.97 then return false end
        end
    end
    return true
end
LC.IsPrivate = Private

------------------------------------------------------------------------
-- Crafting
------------------------------------------------------------------------

function LC.CanCraft(ply, r)
    for id, n in pairs(r.needs) do
        if not LC.HasItem(ply, id, n) then return false, "You need " .. n .. " " .. string.lower(LCS.Items[id].name) .. "." end
    end
    if r.private and not Private(ply) then return false, "Not with someone watching. Get out of sight first." end
    return true
end

function LC.Craft(ply, rid)
    local r = LCS.RecipesById[rid]
    if not r then
        if LCS.LabById and LCS.LabById[rid] then return false, "That's the lab's work: the Resistance's scientist makes it. Everyone else buys it at the black market." end
        return false
    end
    if LC.PlayerIsCP(ply) then return false, "[CP Commissary] Visit a Civil Protection Commissary to be issued supplies." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local ok, why = LC.CanCraft(ply, r)
    if not ok then return false, why end
    local out = LCS.Items[r.out]
    return LC.StartTask(ply, r.secs, "Making " .. string.lower(out.name) .. "... keep still", {
        maxMove = 40, cancelText = "You put it down, half finished.",
        done = function(p)
            local ok2, why2 = LC.CanCraft(p, r)
            if not ok2 then p:ChatPrint(why2) return end
            for id, n in pairs(r.needs) do LC.TakeItem(p, id, n) end
            if not LC.GiveItem(p, r.out) and LC.SpawnWorldItem then LC.SpawnWorldItem(r.out, p:GetPos() + p:GetForward() * 30 + Vector(0, 0, 20)) end
            p:EmitSound("physics/metal/metal_solid_impact_soft" .. math.random(1, 3) .. ".wav", 60)
            p:ChatPrint("Made: " .. out.name .. ".")
            if out.contraband and LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then
                LC.ReportCrime(p, out.arms and "Manufacturing weapons" or "Manufacturing contraband", out.arms and 240 or 120)
                p:ChatPrint("[Civil Protection] A Civil Protection unit saw what you were making.")
            end
            hook.Run("LivingCityCrafted", p, r.out)
        end,
    })
end

------------------------------------------------------------------------
-- Selling arms
------------------------------------------------------------------------

-- What the black market pays for an item, here (nil: they won't buy it).
function LC.SellPrice(ply, id)
    local it = LCS.Items[id]
    if not it or not it.sell or it.sell <= 0 then return nil end
    if LC.IssuedLocked and LC.IssuedLocked(ply, id) then return nil end -- (a unit's issued grenades)
    local price = it.sell
    if it.arms and IsResistance(ply) and LC.NearQuartermaster and LC.NearQuartermaster(ply) then
        price = math.floor(price * cvQMBonus:GetFloat() + 0.5)
    end
    -- intel: only the quartermaster buys it
    if it.intel and not (LC.NearQuartermaster and LC.NearQuartermaster(ply)) then return nil end
    -- the quartermaster pays more for what's in demand or short in the city, never what anyone could
    -- buy it for (sv_livingcity_market.lua)
    if IsResistance(ply) and LC.NearQuartermaster and LC.NearQuartermaster(ply) and not (it.hunger or it.thirst) and LC.MarketBuyback then
        price = LC.MarketBuyback(id, price)
    end
    -- food and drink: the quartermaster hands it out free from the supply crate, so he
    -- buys it back for next to nothing (lc_qm_food_price, 2)
    if (it.hunger or it.thirst) and LC.NearQuartermaster and LC.NearQuartermaster(ply) then
        price = math.min(price, math.max(0, cvQMFood:GetInt()))
        if price <= 0 then return nil end
    end
    return price
end

------------------------------------------------------------------------
-- Using things
------------------------------------------------------------------------

function LC.ArmsUse(ply, id)
    local it = LCS.Items[id]
    if it.use == "heal" then
        if ply:Health() >= ply:GetMaxHealth() then return false, "You're not hurt." end
        LC.TakeItem(ply, id)
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + (it.heal or 15)))
        ply:EmitSound("items/medshot4.wav", 55)
        return true
    elseif it.use == "datachip" then
        return LC.UseDataChip and LC.UseDataChip(ply, id) or false
    elseif it.use == "poison" then
        return LC.PoisonFood and LC.PoisonFood(ply) or false -- (weedkiller into food or drink: sv_livingcity_weeds.lua)
    elseif it.use == "jammer" then
        return LC.PlaceJammer and LC.PlaceJammer(ply) or false
    elseif it.use == "armor" then
        if LC.PutOnVest then return LC.PutOnVest(ply, id) end -- (a powered vest: sv_livingcity_vest.lua)
        if ply:Armor() >= 100 then return false, "You can't wear any more." end
        LC.TakeItem(ply, id)
        ply:SetArmor(math.min(100, ply:Armor() + (it.armor or 25)))
        ply:EmitSound("items/battery_pickup.wav", 55)
        return true
    elseif it.use == "charge" then
        if not (LC.HasVest and LC.HasVest(ply)) then return false, "You've no powered vest on to charge." end
        if ply:Armor() >= LC.VestCap(ply) then return false, "Your vest is fully charged." end
        LC.TakeItem(ply, id)
        LC.ChargeVest(ply, it.charge or 25)
        ply:EmitSound("items/battery_pickup.wav", 55)
        return true
    elseif it.use == "ammo" then
        -- full already: the box stays in the pocket (the owner, 13 November: "it lets me, and tells me,
        -- that I can load them infinitely no matter if my ammo is already full")
        local room = LC.AmmoRoom and LC.AmmoRoom(ply, it.ammo[1]) or nil
        if room ~= nil and room <= 0 then return false, "You can't carry any more of those rounds. The box stays in your pocket." end
        LC.TakeItem(ply, id)
        ply:GiveAmmo(room and math.min(room, it.ammo[2]) or it.ammo[2], it.ammo[1])
        ply:EmitSound("items/ammo_pickup.wav", 55)
        return true
    elseif it.use == "arm" then
        if ply:HasWeapon(it.weapon) then return false, "You've already got one in your hand." end
        LC.TakeItem(ply, id)
        ply:Give(it.weapon)
        if ply.SelectWeapon then ply:SelectWeapon(it.weapon) end
        if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) and not LC.PlayerIsCP(ply) then
            LC.ReportCrime(ply, "Brandishing a weapon", 180)
        end
        return true
    elseif it.use == "throw" then
        return LC.ThrowGrenade(ply, id)
    end
    return false
end

------------------------------------------------------------------------
-- Grenades
------------------------------------------------------------------------

LC.Smokes = LC.Smokes or {} -- { pos, r, untilT }
LC.GasClouds = LC.GasClouds or {}

local SMOKE_R, GAS_R, FLASH_R = 240, 260, 700
local FLASH_NEAR = 300 -- (this close to a flashbang, nothing in the way saves you; it was 150)

-- Does smoke stand between a and b?
function LC.SmokeBlocks(a, b)
    local now = CurTime()
    for i = #LC.Smokes, 1, -1 do
        local s = LC.Smokes[i]
        if now > s.untilT then
            table.remove(LC.Smokes, i)
        else
            -- distance from the cloud's centre to the segment a-b
            local ab = b - a
            local len2 = ab:LengthSqr()
            local t = len2 > 0 and math.Clamp((s.pos - a):Dot(ab) / len2, 0, 1) or 0
            local closest = a + ab * t
            if closest:DistToSqr(s.pos) < s.r * s.r then return true end
        end
    end
    return false
end

-- The cloud itself is drawn by each player's game (cl_livingcity_war.lua) as
-- real smoke particles: grey and opaque for smoke, a sickly green for gas. (The
-- engine's smokestack glowed white like the sun.) kind: "smoke" or "gas".
util.AddNetworkString("lc_cloud")
local function Cloud(pos, kind, secs)
    net.Start("lc_cloud")
    net.WriteVector(pos)
    net.WriteString(kind)
    net.WriteFloat(secs)
    net.WriteFloat(kind == "gas" and GAS_R or SMOKE_R)
    net.Broadcast()
end
LC.SmokeCloud = Cloud

-- A unit's mask, with its filter (fouled by an Insider, sv_livingcity_cleanup.lua: it lets the gas through);
-- a Union cleanup worker's respirator; a zombie doesn't breathe.
local function Masked(ply)
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return true end
    if LC.CleanupRespirator and LC.CleanupRespirator(ply) then return true end
    -- a gas mask in their pockets: on it goes by itself (the owner, 13 November; sv_livingcity_gasmask.lua)
    if ply.Alive and ply:Alive() and LC.GasMaskPlayer and LC.InGasCloud and LC.InGasCloud(ply:GetPos()) and LC.GasMaskPlayer(ply) then return true end
    local unit = LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
    if unit and LC.FiltersFouled and LC.FiltersFouled() then return false, true end
    return unit
end
LC.GasMasked = Masked

-- The gas cloud someone is standing in, or nil.
function LC.InGasCloud(pos)
    local now = CurTime()
    for _, g in ipairs(LC.GasClouds or {}) do
        if now <= g.untilT and pos:DistToSqr(g.pos) < g.r * g.r then return g end
    end
    return nil
end

local function LOS(a, b, filter)
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_OPAQUE, filter = filter })
    return tr.Fraction > 0.97
end

function LC.Detonate(kind, pos, owner)
    local now = CurTime()
    if kind == "smoke" then
        Cloud(pos, "smoke", 22)
        LC.Smokes[#LC.Smokes + 1] = { pos = pos + Vector(0, 0, 40), r = SMOKE_R, untilT = now + 22 }
        if sound and sound.Play then sound.Play("weapons/smokegrenade/sg_explode.wav", pos, 75) end
        -- anyone hunting someone inside it loses them
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.state == "hostile" and IsValid(st.enemy) and st.enemy:GetPos():DistToSqr(pos) < SMOKE_R * SMOKE_R then
                st.lostSince = now - 4
            end
        end
    elseif kind == "flash" then
        -- (thrown by a desperate Combine unit: their own flashbang spares their own, sv_livingcity_desperation.lua)
        local ost = IsValid(owner) and LC.NPCs and LC.NPCs[owner]
        local byCombine = ost and LC.IsSecurity and LC.IsSecurity(ost)
        if sound and sound.Play then sound.Play("weapons/flashbang/flashbang_explode2.wav", pos, 95) end
        local fx = EffectData and EffectData()
        if fx then fx:SetOrigin(pos) util.Effect("cball_explode", fx, true, true) end
        for _, ply in ipairs(player.GetAll()) do
            local d = ply:GetPos():Distance(pos)
            if ply:Alive() and d < FLASH_R and not (byCombine and (LC.PlayerIsCP(ply) or ply:GetNW2String("lcf_faction", "") == "ota")) and LOS(ply:EyePos(), pos + Vector(0, 0, 10), ply) then
                local dir = (pos - ply:EyePos()):GetNormalized()
                local facing = dir:Dot(ply:GetAimVector())
                local strength = math.Clamp((1 - d / FLASH_R) * (facing > 0.3 and 1 or 0.45), 0.2, 1)
                ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1 + 3 * strength, 1 + 2 * strength)
                if ply.SetDSP then ply:SetDSP(37, false) end
                timer.Simple(2 + 3 * strength, function() if IsValid(ply) and ply.SetDSP then ply:SetDSP(0, false) end end)
            end
        end
        -- (the owner, 7 November: a flashbang in a raid, and the rebels didn't even blink) everyone in sight of it,
        -- or right beside it, is blinded for 4 to 9 seconds each: hands to their eyes, stumbling, not shooting
        -- (LC.FlashStun, sv_livingcity_fieldops.lua)
        -- (anyone within FLASH_NEAR is caught whatever is in the way: in a cluster they stood in each other's light)
        local blinded = 0
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.role ~= "zombie" and st.role ~= "scanner" and not (byCombine and LC.IsSecurity(st)) then
                local d2 = npc:GetPos():DistToSqr(pos)
                if d2 < (FLASH_R * 0.8) ^ 2 and (d2 < FLASH_NEAR * FLASH_NEAR or LOS(npc:EyePos(), pos + Vector(0, 0, 10), npc)
                    or LOS(npc:EyePos(), pos + Vector(0, 0, 40), npc)) then
                    blinded = blinded + 1
                    if LC.FlashStun then
                        LC.FlashStun(npc, st, math.Rand(4, 9))
                    else
                        st.stunnedUntil = now + 4
                        npc:SetEnemy(NULL)
                        npc:SetSchedule(SCHED_IDLE_STAND)
                    end
                end
            end
        end
        -- whoever threw it is told what it did (and if it ever says "nobody", that is worth knowing)
        if IsValid(owner) and owner:IsPlayer() then
            owner:ChatPrint(blinded > 0 and string.format("[Flashbang] %d blinded: they can't shoot until it wears off.", blinded)
                or "[Flashbang] Nobody was caught in it.")
        end
        LC.LastFlash = { at = now, pos = pos, blinded = blinded }
    elseif kind == "gas" then
        Cloud(pos, "gas", 18)
        LC.GasClouds[#LC.GasClouds + 1] = { pos = pos + Vector(0, 0, 30), r = GAS_R, untilT = now + 18, owner = owner }
        if sound and sound.Play then sound.Play("ambient/gas/steam2.wav", pos, 80) end
    elseif kind == "poison" then
        -- the Combine's weedkiller gas (sv_livingcity_cleanup.lua): the same green cloud, half as bad again as chlorine.
        -- A unit's mask keeps it out, unless an Insider has fouled the filters.
        Cloud(pos, "gas", 16)
        LC.GasClouds[#LC.GasClouds + 1] = { pos = pos + Vector(0, 0, 30), r = GAS_R, untilT = now + 16, owner = owner, poison = true }
        if sound and sound.Play then sound.Play("ambient/gas/steam2.wav", pos, 80) end
    elseif kind == "fire" then
        if LC.Firebomb then LC.Firebomb(pos, owner) end -- (the Resistance's firebomb: sv_livingcity_cleanup.lua)
    end
    hook.Run("LivingCityGrenade", kind, pos, owner)
end

local COUGHS = { "ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav" }

timer.Create("LivingCityGas", 1, 0, function()
    local now = CurTime()
    for i = #LC.GasClouds, 1, -1 do
        local g = LC.GasClouds[i]
        if now > g.untilT then
            table.remove(LC.GasClouds, i)
        else
            local r2 = g.r * g.r
            local attacker = IsValid(g.owner) and g.owner or game.GetWorld()
            for _, ply in ipairs(player.GetAll()) do
                -- a mask keeps it out (chlorine and poison alike), unless its filter has been fouled
                local masked, fouled = Masked(ply)
                local mul = masked and 0 or 1
                if fouled and ply:Alive() and ply:GetPos():DistToSqr(g.pos) < r2 and (ply.lcFouledTold or 0) < now then
                    ply.lcFouledTold = now + 30
                    if LC.Notice then LC.Notice(ply, "warn", "Your filter", "The gas is coming straight through your mask: the filter's no good. Get out of it!", 6) end
                end
                if ply:Alive() and ply:GetPos():DistToSqr(g.pos) < r2 and mul > 0 then
                    local dmg = DamageInfo and DamageInfo()
                    if dmg then
                        dmg:SetDamage(cvGasDmg:GetFloat() * mul * (g.poison and 1.5 or 1)) -- (weedkiller gas is worse than chlorine)
                        dmg:SetDamageType(DMG_NERVEGAS or 65536)
                        dmg:SetAttacker(attacker)
                        dmg:SetInflictor(attacker)
                        ply:TakeDamageInfo(dmg)
                    else
                        ply:TakeDamage(cvGasDmg:GetFloat() * mul * (g.poison and 1.5 or 1), attacker, attacker)
                    end
                    ply:EmitSound(Pick(COUGHS), 70)
                    if LC.HandToFace then LC.HandToFace(ply, "mouth", 1.6) end -- (a hand over the mouth, as others see it)
                    if ply.ViewPunch then ply:ViewPunch(Angle(math.Rand(2, 5), math.Rand(-2, 2), 0)) end
                end
            end
            local spots -- (where the Combine units are, looked up once a cloud, only if someone has to run)
            for npc, st in pairs(LC.NPCs or {}) do
                local nmul = 1
                if LC.IsSecurity(st) then nmul = (LC.FiltersFouled and LC.FiltersFouled()) and 1 or 0 end -- (masked, unless an Insider fouled the filters)
                -- a Resistance fighter with a gas mask puts it on; anyone else covers their mouth and coughs
                -- (the owner, 13 November; sv_livingcity_gasmask.lua)
                if nmul > 0 and IsValid(npc) and npc:Health() > 0 and LC.GasNPC and npc:GetPos():DistToSqr(g.pos) < r2
                    and LC.GasNPC(npc, st, g, now) then nmul = 0 end
                if IsValid(npc) and npc:Health() > 0 and nmul > 0 and st.role ~= "scanner"
                    and npc:GetPos():DistToSqr(g.pos) < r2 then
                    npc:TakeDamage((cvGasDmg:GetFloat() + 2) * nmul * (g.poison and 1.5 or 1), attacker, attacker)
                    -- get out of it: a way out clear of Combine units first (LC.GasFlee)
                    if npc:Health() > 0 and LC.GasFlee and st.role ~= "zombie" then
                        spots = spots or (LC.GasCombineSpots and LC.GasCombineSpots()) or {}
                        LC.GasFlee(npc, st, g, now, spots)
                    elseif npc:Health() > 0 and npc.SetLastPosition then
                        local away = npc:GetPos() - g.pos
                        away.z = 0
                        if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
                        npc:SetLastPosition(npc:GetPos() + away:GetNormalized() * (g.r + 200))
                        npc:SetSchedule(SCHED_FORCED_GO_RUN)
                    end
                end
            end
        end
    end
end)

function LC.ThrowGrenade(ply, id)
    local it = LCS.Items[id]
    if not it or not it.grenade or not LC.HasItem(ply, id) then return false end
    if LC.InCustody and LC.InCustody(ply) then return false, "Not with your hands cuffed." end
    if (ply.lcThrowNext or 0) > CurTime() then return false end
    ply.lcThrowNext = CurTime() + 1.2
    LC.TakeItem(ply, id)
    local e = ents.Create("lc_grenade")
    if IsValid(e) then
        e.lcKind = it.grenade
        e.lcOwner = ply
        e:SetPos(ply:EyePos() + ply:GetAimVector() * 18)
        e:Spawn()
        local phys = e.GetPhysicsObject and e:GetPhysicsObject()
        if IsValid(phys) then phys:SetVelocity(ply:GetAimVector() * 750 + Vector(0, 0, 120)) end
    else
        LC.Detonate(it.grenade, ply:GetPos() + ply:GetAimVector() * 300, ply)
    end
    ply:EmitSound("weapons/slam/throw.wav", 60)
    if LC.SyncGrenades then LC.SyncGrenades(ply) end
    return true
end

-- What the Grenades weapon shows: how many of each you're carrying.
-- (the owner, 1 November: a poison gas bomb bought at the Commissary was only throwable from F3. Everything
-- you throw is on the Grenades weapon now: the poison gas bomb and the firebomb too)
local KINDS = { { "gren_smoke", "smoke" }, { "smokebomb", "smoke" }, { "gren_flash", "flash" },
    { "gas_bomb", "poison" }, { "firebomb", "fire" } }
function LC.SyncGrenades(ply)
    if not IsValid(ply) then return end
    local any = false
    local counts = { smoke = 0, flash = 0, gas = 0, poison = 0, fire = 0 }
    local inv = LC.Inventory and LC.Inventory(ply) or {}
    for _, k in ipairs(KINDS) do
        local n = inv[k[1]] or 0
        counts[k[2]] = counts[k[2]] + n
        if n > 0 then any = true end
    end
    for kind, n in pairs(counts) do ply:SetNW2Int("lcg_" .. kind, n) end
    if any and not ply:HasWeapon("weapon_lc_grenades") then
        ply:Give("weapon_lc_grenades")
    elseif not any and ply:HasWeapon("weapon_lc_grenades") then
        ply:StripWeapon("weapon_lc_grenades")
    end
end

-- The Grenades weapon asks for one of a kind
function LC.ThrowKind(ply, kind)
    local order = kind == "smoke" and { "gren_smoke", "smokebomb" } or (kind == "flash" and { "gren_flash" })
        or (kind == "fire" and { "firebomb" }) or { "gas_bomb" }
    for _, id in ipairs(order) do
        if LC.HasItem(ply, id) then return LC.ThrowGrenade(ply, id) end
    end
    return false, "None left."
end

concommand.Add("lc_throw", function(ply, _, args)
    if not IsValid(ply) then return end
    local ok, why = LC.ThrowKind(ply, string.lower(args[1] or "smoke"))
    if not ok and why then ply:ChatPrint(why) end
end)

-- issued by rank, topped up when a unit spawns
local ISSUE = {
    { faction = "cp", rank = 2, item = "gren_smoke", n = 1 },  -- Metrocop
    { faction = "cp", rank = 3, item = "gren_flash", n = 1 },  -- Division Leader
    { faction = "cp", rank = 3, item = "gas_bomb", n = 1 },
    { faction = "cp", rank = 4, item = "gas_bomb", n = 2 },    -- the Overwatch
}
-- A unit's issued grenades are Combine issue: kept, thrown, or handed to another unit; never
-- sold, dropped, stashed or passed to anyone else (they came back free with every respawn).
local ISSUED_ITEM = {}
for _, is in ipairs(ISSUE) do ISSUED_ITEM[is.item] = true end
ISSUED_ITEM.zipties = true -- (a unit's cuffs are issue too, free at a CP Commissary: sv_livingcity_cp.lua)
-- A Resistance Fighter's Freq 7 radio and transmitter (the owner, 13 November: "resistance fighters should just get one
-- by default though when they are promoted [to resistance fighter] and have one as standard issue (un-sellable, cannot
-- unequip, same as CP radios)"): from Fighter up, one of each, topped up at every spawn and on promotion. That one of
-- each stays with them: never sold, dropped, stashed or handed over (a spare can be).
LC.REBEL_ISSUE = { "radio_tuned", "radio_transmitter" }
local REBEL_ISSUED = { radio_tuned = true, radio_transmitter = true }
local REBEL_ISSUE_RANK = 3 -- (Fighter)
local function RebelIssued(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "resistance" and ply:GetNW2Int("lcf_rank", 1) >= REBEL_ISSUE_RANK
end
LC.RebelIssued = RebelIssued
function LC.IssueRebelRadio(ply)
    if not RebelIssued(ply) or not LC.Inventory or not LC.GiveItem then return 0 end
    local n = 0
    for _, id in ipairs(LC.REBEL_ISSUE) do
        if (LC.Inventory(ply)[id] or 0) < 1 and LC.GiveItem(ply, id, 1) then n = n + 1 end
    end
    return n
end
hook.Add("PlayerSpawn", "LivingCityRebelRadio", function(ply)
    timer.Simple(1.6, function() if IsValid(ply) then LC.IssueRebelRadio(ply) end end)
end)
hook.Add("LivingCityFactionChanged", "LivingCityRebelRadio", function(ply) -- (back to a Fighter's rank without a respawn)
    timer.Simple(0.5, function() if IsValid(ply) then LC.IssueRebelRadio(ply) end end)
end)
hook.Add("LivingCityRankChanged", "LivingCityRebelRadio", function(ply, fid)
    if fid ~= "resistance" or not IsValid(ply) then return end
    if LC.IssueRebelRadio(ply) > 0 and LC.Notice then
        LC.Notice(ply, "info", "Freq 7", "You're issued a Freq 7 radio and a radio transmitter: yours to keep. Switch to the radio transmitter (next to Hands) to talk on Freq 7.", 8)
    end
end)

function LC.IssuedLocked(ply, id, to)
    if REBEL_ISSUED[id] and RebelIssued(ply) and LC.Inventory and (LC.Inventory(ply)[id] or 0) <= 1 then return true end
    if not (IsValid(ply) and ISSUED_ITEM[id] and LC.PlayerIsCP(ply)) then return false end
    if IsValid(to) and LC.PlayerIsCP(to) then return false end
    return true
end
local ISSUED_WHY = "That's Combine issue: it stays with you (or another unit)."
-- Why it can't go: a unit's Combine issue, or a Fighter's Freq 7 kit.
function LC.IssuedWhy(ply, id)
    if REBEL_ISSUED[id] and RebelIssued(ply) then return "That's your issued Freq 7 kit: it stays with you." end
    return ISSUED_WHY
end

function LC.IssueGrenades(ply)
    if not IsValid(ply) or not LC.Inventory then return end
    local f, rank = ply:GetNW2String("lcf_faction", ""), ply:GetNW2Int("lcf_rank", 1)
    -- the chlorine gas grenade is gone (13 November): any still carried are poison gas bombs now
    local old = LC.Inventory(ply).gren_gas or 0
    if old > 0 then
        LC.Inventory(ply).gren_gas = nil
        LC.GiveItem(ply, "gas_bomb", old)
    end
    for _, is in ipairs(ISSUE) do
        if is.faction == f and rank >= is.rank then
            local have = LC.Inventory(ply)[is.item] or 0
            if have < is.n then LC.GiveItem(ply, is.item, is.n - have) end
        end
    end
    LC.SyncGrenades(ply)
end

hook.Add("PlayerSpawn", "LivingCityGrenades", function(ply)
    timer.Simple(1.5, function() if IsValid(ply) then LC.IssueGrenades(ply) end end)
end)
hook.Add("LivingCityInventoryChanged", "LivingCityGrenades", function(ply) LC.SyncGrenades(ply) end)

------------------------------------------------------------------------
-- Passing things on (and smuggling them into a cell)
------------------------------------------------------------------------

function LC.GiveTo(ply, id)
    local tr = ply:GetEyeTrace()
    local target = tr and tr.Entity
    if not (IsValid(target) and target:IsPlayer() and target:Alive()) or target:GetPos():DistToSqr(ply:GetPos()) > 110 * 110 then
        return false, "Look at the person you want to give it to, up close."
    end
    if not LC.HasItem(ply, id) then return false end
    if LCS.Items[id] and LCS.Items[id].doc then return false, "Your papers stay with you. (Show them instead: Use.)" end
    if LC.IssuedLocked(ply, id, target) then return false, LC.IssuedWhy(ply, id) end
    if not LC.CanCarry(target, id, 1) then return false, "They can't carry any more." end
    local it = LCS.Items[id]
    local prisoner = LC.Prisoners and LC.Prisoners[target]
    if prisoner and not LC.PlayerIsCP(ply) and LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        LC.TakeItem(ply, id)
        LC.ReportCrime(ply, "Smuggling contraband into custody", 240)
        ply:ChatPrint("[Civil Protection] A guard saw you pass something through the bars. It's confiscated, and so is your freedom.")
        return true
    end
    LC.TakeItem(ply, id)
    LC.GiveItem(target, id)
    ply:ChatPrint("You hand over: " .. it.name .. ".")
    target:ChatPrint((ply:GetNW2String("lc_char", "") ~= "" and ply:GetNW2String("lc_char", "") or ply:Nick()) .. " slips you: " .. it.name .. "." ..
        (prisoner and id == "lockpick" and " Pick your cell door with it (look at it, F3 > Use). Don't let a guard see." or ""))
    hook.Run("LivingCityGave", ply, target, id)
    return true
end

hook.Add("PlayerSay", "LivingCityCraftChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    local what = string.match(t, "^!give%s+(.+)$")
    if what then
        local id
        for iid, it in pairs(LCS.Items) do
            if LC.HasItem(ply, iid) and (iid == what or string.find(string.lower(it.name), what, 1, true)) then id = iid break end
        end
        if not id then ply:ChatPrint("You don't have anything like that.") return "" end
        local ok, why = LC.GiveTo(ply, id)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
    if t == "!craft" then LC.SendInv(ply, true) return "" end
end)

-- dead units carry parts worth taking
hook.Add("LivingCityBodyLoot", "LivingCityCrafting", function(role, loot)
    if (role == "cop" or role == "soldier") and math.random() < 0.35 then loot.items[#loot.items + 1] = "gun_parts" end
end)
