--[[
    Living City: the Civil Protection Commissary (units' supplies)

    Units don't make things (F3 has no crafting for them). They're issued
    what they need at a Civil Protection Commissary ("Fixture: Civil
    Protection Commissary", entities/lc_cpsupply.lua). E there, as a unit:

      Weapons      any their rank carries that they've lost (taken in custody, say)
      Grenades     by rank, as when you go on duty (sv_livingcity_crafting.lua)
      Ammunition   the issued weapons you carry, back up to a full load
      Armour       up to 50 (officers 75, Overwatch 100)
      Bandages     up to two
      A ration     your allocation, once every lc_cpsupply_ration (600) seconds

    Once every lc_cpsupply_cooldown (120) seconds. And at any time (the owner, 7 November):

      Ration vouchers   each one (the duty allocation, sv_livingcity_cp.lua) is a ration packet
      The daily kit     once every city day (lc_day_minutes): a health vial and a bandage
      The vest          standing at it charges a unit's vest, lc_cpsupply_recharge (5) a second, up to
                        their issue (50, officers 75, Overwatch 100)

    Then the Commissary's unit
    counter opens (flashbangs, gas, ammunition and batteries for credits):
    the only place units buy those; the Union Commissary terminals never sell
    them (unless the city has no Civil Protection Commissary).

    A city with no Civil Protection Commissary placed: the Union Commissary
    terminal issues units their supplies instead. F3 points units to the
    nearest one, and marks it on their screen (sv_livingcity_notices.lua).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCool   = CreateConVar("lc_cpsupply_cooldown", "120", FLAGS, "Seconds between a Civil Protection unit's issues at the Civil Protection Commissary")
local cvRation = CreateConVar("lc_cpsupply_ration", "600", FLAGS, "Seconds between the ration a Civil Protection unit is issued at the Civil Protection Commissary")
local cvRecharge = CreateConVar("lc_cpsupply_recharge", "5", FLAGS, "Charge a Civil Protection unit's vest gains each second they stand at a Civil Protection Commissary (0: none)")

-- A full load, by ammunition type, for the weapons that use it.
local LOAD = {
    weapon_pistol = { "Pistol", 72 }, weapon_smg1 = { "SMG1", 180 }, weapon_ar2 = { "AR2", 120 },
    weapon_shotgun = { "Buckshot", 24 }, weapon_357 = { "357", 12 },
}

local function Unit(ply) return LC.PlayerIsCP and LC.PlayerIsCP(ply) end
local function ArmourFor(ply)
    if LCF.IsOverwatch(ply) then return 100 end
    return (LC.IsCPOfficer and LC.IsCPOfficer(ply)) and 75 or 50
end

-- What a unit is issued now: a list of what they got (empty: nothing needed).
function LC.IssueSupplies(ply)
    local got = {}
    if not IsValid(ply) or not Unit(ply) then return got end
    -- grenades by rank
    if LC.Inventory and LC.IssueGrenades then
        local before = {}
        for _, id in ipairs({ "gren_smoke", "gren_flash", "gren_gas" }) do before[id] = LC.Inventory(ply)[id] or 0 end
        LC.IssueGrenades(ply)
        for id, n in pairs(before) do
            local more = (LC.Inventory(ply)[id] or 0) - n
            if more > 0 then got[#got + 1] = more .. " " .. string.lower(LCS.Items[id] and LCS.Items[id].name or id) end
        end
    end
    -- the weapons their rank carries, any that have gone missing (taken in custody, a scene, a test; the
    -- owner, 1 November: a Metrocop with no pistol): issued again
    if LC.RankLoadout then
        for _, cls in ipairs(LC.RankLoadout(ply)) do
            if not ply:HasWeapon(cls) then
                ply:Give(cls)
                local w = weapons and weapons.Get and weapons.Get(cls)
                got[#got + 1] = "a " .. string.lower((w and w.PrintName) or (string.gsub(string.gsub(cls, "^weapon_lc_", ""), "^weapon_", "")))
            end
        end
    end
    -- ammunition for what they carry
    local done = {}
    for cls, load in pairs(LOAD) do
        if ply:HasWeapon(cls) and not done[load[1]] then
            done[load[1]] = true
            local have = ply.GetAmmoCount and ply:GetAmmoCount(load[1]) or 0
            if have < load[2] then
                ply:GiveAmmo(load[2] - have, load[1], true)
                got[#got + 1] = (load[2] - have) .. " " .. string.lower(load[1]) .. " rounds"
            end
        end
    end
    -- armour
    local want = ArmourFor(ply)
    if ply.Armor and ply:Armor() < want then
        ply:SetArmor(want)
        got[#got + 1] = "armour, to " .. want
    end
    -- bandages
    if LC.Inventory and LC.GiveItem and LCS.Items.bandage then
        local b = LC.Inventory(ply).bandage or 0
        if b < 2 and LC.GiveItem(ply, "bandage", 2 - b) then got[#got + 1] = (2 - b) .. " bandage" .. (2 - b > 1 and "s" or "") end
    end
    -- the ration allocation
    if LC.GiveItem and (ply.lcSupplyRationAt or 0) <= CurTime() and LC.GiveItem(ply, "ration") then
        ply.lcSupplyRationAt = CurTime() + cvRation:GetFloat()
        got[#got + 1] = "a ration packet"
    end
    return got
end

-- Ration vouchers in for packets, one each (sv_livingcity_cp.lua). How many were exchanged.
function LC.RedeemRationVouchers(ply)
    local n = 0
    if not IsValid(ply) or not LC.Inventory or not LC.GiveItem then return n end
    for _ = 1, LC.Inventory(ply).ration_voucher or 0 do
        if not LC.GiveItem(ply, "ration", 1) then break end -- (pockets full: the rest wait)
        LC.TakeItem(ply, "ration_voucher", 1)
        n = n + 1
    end
    return n
end

-- The daily kit: a health vial and a bandage, once every city day (kept over a restart).
local function DaySecs() return LC.SpoilSecs and LC.SpoilSecs() or 3600 end
function LC.CPDailyKitDue(ply)
    local last = tonumber(ply:GetPData("lc_cp_daily_at", "")) or 0
    return os.time() >= last + DaySecs(), math.max(0, last + DaySecs() - os.time())
end
function LC.IssueCPDailyKit(ply, ent)
    local got = {}
    if not IsValid(ply) or not Unit(ply) or not LC.CPDailyKitDue(ply) then return got end
    ply:SetPData("lc_cp_daily_at", tostring(os.time()))
    -- into the pockets, for when it's wanted (it used to drop on the floor, where a unit at full health
    -- couldn't pick it up); on the floor only when the pockets are full
    if LC.GiveItem and LCS.Items.health_vial and LC.GiveItem(ply, "health_vial", 1) then
        got[#got + 1] = "a health vial (in your pockets: F3)"
    else
        local vial = ents.Create("item_healthvial")
        if IsValid(vial) then
            local from = IsValid(ent) and ent or ply
            vial:SetPos(from:GetPos() + from:GetForward() * 40 + Vector(0, 0, 20))
            vial:Spawn()
            got[#got + 1] = IsValid(ent) and "a health vial (on the floor in front of the Commissary: your pockets are full)" or "a health vial (on the floor in front of you)"
        end
    end
    if LC.GiveItem and LCS.Items.bandage and LC.GiveItem(ply, "bandage", 1) then got[#got + 1] = "a bandage" end
    return got
end

function LC.UseCPSupply(ply, ent)
    if not IsValid(ply) or not ply:Alive() then return end
    if (ply.lcSupplyUse or 0) > CurTime() then return end
    ply.lcSupplyUse = CurTime() + 0.8
    if not Unit(ply) then
        if IsValid(ent) then ent:EmitSound("buttons/combine_button_locked.wav", 60) end
        ply:ChatPrint("[CP Commissary] Restricted: Civil Protection only.")
        return
    end
    if IsValid(ent) and ent:GetNW2Bool("lc_nopower", false) then
        ply:ChatPrint("[CP Commissary] The screen's dark. No power.")
        return
    end
    -- vouchers, whatever the wait for the next issue
    local v = LC.RedeemRationVouchers(ply)
    if v > 0 then
        if IsValid(ent) then ent:EmitSound("items/ammo_pickup.wav", 65) end
        ply:ChatPrint("[CP Commissary] Issued: " .. (v == 1 and "a ration packet for your voucher" or (v .. " ration packets for your vouchers")) .. ".")
    end
    LC.CPSupplyCuffs(ply) -- (cuffs back up to three, whatever the wait for the next issue)
    local wait = (ply.lcSupplyNext or 0) - CurTime()
    if wait > 0 then
        ply:ChatPrint(string.format("[CP Commissary] Your next issue is in %d seconds. The Civil Protection unit counter is open.", math.ceil(wait)))
    else
        local got = LC.IssueSupplies(ply)
        if #got > 0 then
            ply.lcSupplyNext = CurTime() + cvCool:GetFloat()
            if IsValid(ent) then ent:EmitSound("items/ammo_pickup.wav", 65) end
            ply:ChatPrint("[CP Commissary] Issued: " .. table.concat(got, ", ") .. ".")
        else
            ply:ChatPrint("[CP Commissary] You're fully supplied. The Civil Protection unit counter is open.")
        end
        hook.Run("LivingCitySupplied", ply, got)
    end
    -- the daily kit, on top of the issue (and whatever the wait for the next one)
    local kit = LC.IssueCPDailyKit(ply, ent)
    if #kit > 0 then ply:ChatPrint("[CP Commissary] Today's kit: " .. table.concat(kit, " and ") .. ".") end
    if LC.NightShiftIssue then LC.NightShiftIssue(ply) end -- (on the night shift: a stimulant, once a night; sv_livingcity_bedtime.lua)
    if LC.OpenShop then LC.OpenShop(ply, true) end
end

-- A unit's cuffs, back up to three, free (the owner, 12 November: "CP units should get them automatically
-- when going to a CP Commissary"). How many were given.
function LC.CPSupplyCuffs(ply)
    local n = LC.IssueUnitCuffs and LC.IssueUnitCuffs(ply) or 0
    if n > 0 and LC.Notice then
        LC.Notice(ply, "info", "Cuffs issued", string.format("%d pair%s of cuffs: you carry %d again.", n, n == 1 and "" or "s", LC.CP_CUFFS or 3), 6)
    end
    return n
end

-- Standing at one charges a unit's vest, up to their issue (the owner, 7 November: "automatic recharging of
-- the vest at a CP Commissary would be wonderful too"). Not with the power out.
function LC.CPSupplyRechargeTick()
    local rate = cvRecharge:GetFloat()
    if rate <= 0 then return end
    local sups = LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}
    if #sups == 0 then return end
    for _, ply in ipairs(player.GetAll()) do
        local at = false
        if ply:Alive() and Unit(ply) then
            for _, e in ipairs(sups) do
                if IsValid(e) and not e:GetNW2Bool("lc_nopower", false) and e:GetPos():DistToSqr(ply:GetPos()) < 120 * 120 then at = true break end
            end
        end
        if at then LC.CPSupplyCuffs(ply) end -- (walking up to it is enough for the cuffs)
        local want = at and ArmourFor(ply) or 0
        if at and ply:Armor() < want then
            ply:SetArmor(math.min(want, ply:Armor() + math.ceil(rate)))
            if not ply.lcSupplyCharging then
                ply.lcSupplyCharging = true
                -- (never Half-Life 2's charger hum: that file loops for ever, and did: the owner, 11 November,
                -- "the charging sound NEVER STOPS")
                ply:EmitSound("items/battery_pickup.wav", 55)
                ply:ChatPrint("[CP Commissary] Your vest is charging. Stay here until it's full.")
            end
            if ply:Armor() >= want then
                ply:StopSound("items/suitcharge1.wav") -- (anyone still hearing the old one)
                ply:EmitSound("items/suitchargeok1.wav", 55)
                ply:ChatPrint("[CP Commissary] Vest charged (" .. want .. ").")
            end
        elseif not at then
            ply.lcSupplyCharging = nil
        end
    end
end
timer.Create("LivingCityCPSupplyCharge", 1, 0, function()
    local ok, err = pcall(LC.CPSupplyRechargeTick)
    if not ok and LC.Error then LC.Error("cp supply charge", err) end
end)

-- Is there one in this city? (Without one, the Union Commissary issues units their supplies.)
function LC.HasCPSupply() return #(LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}) > 0 end

-- Standing at one (a unit can buy at the unit counter here).
function LC.NearCPSupply(ply)
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}) do
        if IsValid(e) and e:GetPos():DistToSqr(ply:GetPos()) < 200 * 200 then return true end
    end
    return false
end

-- A Resistance hacker's multitool on the Commissary (the owner, 1 November): ten seconds at it, unseen, and it
-- hands out what it would to a unit, off the books: bandages, pistol rounds, a vest cell, now and then a smoke
-- grenade. Then it's locked down for lc_cpsupply_hack_minutes (10). Seen at it: wanted.
local cvHack = CreateConVar("lc_cpsupply_hack_minutes", "10", FLAGS, "Minutes a Civil Protection Commissary stays locked after a hacker's been at it")
function LC.HackCPSupply(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "lc_cpsupply" then return false end
    if ent:GetNW2Float("lc_hacked_until", 0) > CurTime() then return false, "It's locked down after the last time. Not yet." end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 130 * 130 then return false, "Get up close to it." end
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        LC.ReportCrime(ply, "Tampering with a Civil Protection terminal", 240)
        return false, "A unit saw you at it. You're wanted."
    end
    if not LC.StartTask then return false end
    return LC.StartTask(ply, 10, "Into the Commissary's issue system...", { maxMove = 40, cancelText = "You pull the multitool away.", done = function(p)
        if not IsValid(ent) or (LC.SeenBySecurity and LC.SeenBySecurity(p, 900)) then
            if IsValid(p) and LC.ReportCrime then LC.ReportCrime(p, "Tampering with a Civil Protection terminal", 240) end
            return
        end
        ent:SetNW2Float("lc_hacked_until", CurTime() + math.max(1, cvHack:GetFloat()) * 60)
        local got = {}
        if LC.GiveItem(p, "bandage", 2) then got[#got + 1] = "2 bandages" end
        if LCS.Items.ammo_pistol and LC.GiveItem(p, "ammo_pistol", 1) then got[#got + 1] = "a box of pistol rounds" end
        if LCS.Items.vest_cell and LC.GiveItem(p, "vest_cell", 1) then got[#got + 1] = "a vest cell" end
        if math.random() < 0.4 and LCS.Items.gren_smoke and LC.GiveItem(p, "gren_smoke", 1) then got[#got + 1] = "a smoke grenade" end
        ent:EmitSound("buttons/combine_button2.wav", 60)
        p:ChatPrint("[Resistance] The Commissary thinks you're a unit, for a moment: " .. (#got > 0 and table.concat(got, ", ") or "nothing you can carry") .. ". It locks itself down behind you.")
        if LC.AddXP then LC.AddXP(p, 10, "the Combine's own supplies") end
    end })
end
