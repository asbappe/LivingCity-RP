--[[
    Living City: the Civil Protection Commissary (units' supplies)

    Units don't make things (F2 has no crafting for them). They're issued
    what they need at a Civil Protection Commissary ("Fixture: Civil
    Protection Commissary", entities/lc_cpsupply.lua). E there, as a unit:

      Weapons      any their rank carries that they've lost (taken in custody, say)
      Grenades     by rank, as when you go on duty (sv_livingcity_crafting.lua)
      Ammunition   the issued weapons you carry, back up to a full load
      Armour       up to 50 (officers 75, Overwatch 100)
      Bandages     up to two
      A ration     your allocation, once every lc_cpsupply_ration (600) seconds

    Once every lc_cpsupply_cooldown (120) seconds. Then the Commissary's unit
    counter opens (flashbangs, gas, ammunition and batteries for credits):
    the only place units buy those; the Union Commissary terminals never sell
    them (unless the city has no Civil Protection Commissary).

    A city with no Civil Protection Commissary placed: the Union Commissary
    terminal issues units their supplies instead. F2 points units to the
    nearest one, and marks it on their screen (sv_livingcity_notices.lua).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCool   = CreateConVar("lc_cpsupply_cooldown", "120", FLAGS, "Seconds between a Civil Protection unit's issues at the Civil Protection Commissary")
local cvRation = CreateConVar("lc_cpsupply_ration", "600", FLAGS, "Seconds between the ration a Civil Protection unit is issued at the Civil Protection Commissary")

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
    if LC.OpenShop then LC.OpenShop(ply, true) end
end

-- Is there one in this city? (Without one, the Union Commissary issues units their supplies.)
function LC.HasCPSupply() return #(LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}) > 0 end

-- Standing at one (a unit can buy at the unit counter here).
function LC.NearCPSupply(ply)
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}) do
        if IsValid(e) and e:GetPos():DistToSqr(ply:GetPos()) < 200 * 200 then return true end
    end
    return false
end
