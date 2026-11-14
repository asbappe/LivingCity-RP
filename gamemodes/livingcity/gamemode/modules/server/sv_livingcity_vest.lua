--[[
    Living City: powered vests ("suit power")

    Nobody in the city wears an HEV suit. What the engine calls armour is the
    charge in a powered vest: kevlar plates with charge cells that stiffen
    under a hit. You hold only as much as your vest can take:

      Combine units   built into the uniform: their rank's armour is its
                      capacity (and the Civil Protection Commissary tops it up)
      the Resistance  a fighter's rank comes with one (Fighter 25, Lieutenant
                      50, Commander 75)
      anyone else     none, unless they put one on: a powered vest, made in the
                      Resistance lab (or bought on the black market), holds
                      lc_vest_capacity (75) and comes fully charged

    No vest, no charge: a suit battery or a charger does nothing for you.
    Charging, and nothing else (sleeping doesn't): the Combine's suit
    batteries and chargers, the Commissary for units, charge cells (made in
    the Resistance lab, or found on a dead Combine unit, lc_vest_cell_drop
    25%, or a downed scanner, 50%), and vortigaunts, whose vortessence charges
    a vest when you ask (E on a freed one in rebel territory: once every
    lc_vort_charge_minutes, 10; a vortigaunt player's right click charges
    whoever they look at). A worn vest is lost when you die.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCap = CreateConVar("lc_vest_capacity", "75", FLAGS, "How much charge a powered vest from the lab or the black market holds")

-- How much charge someone can hold right now.
function LC.VestCap(ply)
    if not IsValid(ply) then return 0 end
    local issued = ply:GetNW2Int("lc_vest_cap", 0)
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then issued = math.max(issued, 100) end
    local worn = ply:GetNW2Bool("lc_vest", false) and cvCap:GetInt() or 0
    return math.max(issued, worn)
end

function LC.HasVest(ply) return LC.VestCap(ply) > 0 end

-- Charge someone's vest by n (to its capacity). The charge added.
function LC.ChargeVest(ply, n)
    local cap = LC.VestCap(ply)
    if cap <= 0 then return 0 end
    local before = ply:Armor()
    ply:SetArmor(math.min(cap, before + n))
    return ply:Armor() - before
end

-- Put on a powered vest from your pockets. True, or false and why.
function LC.PutOnVest(ply, id)
    if ply:GetNW2Bool("lc_vest", false) then return false, "You're already wearing one." end
    if ply:GetNW2Int("lc_vest_cap", 0) >= cvCap:GetInt() then return false, "Your own gear has a vest at least as good." end
    LC.TakeItem(ply, id)
    ply:SetNW2Bool("lc_vest", true)
    -- fully charged as it goes on (the owner, 14 November: "if I buy a powered vest, it needs to be
    -- fully charged when I receive it and put it on")
    LC.ChargeVest(ply, LC.VestCap(ply))
    ply:EmitSound("items/battery_pickup.wav", 55)
    if LC.Notice then LC.Notice(ply, "info", "Powered vest", "On, fully charged. Vortigaunts, suit batteries and chargers top it up.", 6) end
    return true
end

-- What a rank issues (sv_livingcity_factions.lua calls this as it equips them).
function LC.IssueVest(ply, armor)
    ply:SetNW2Int("lc_vest_cap", math.max(0, armor or 0))
end

hook.Add("PlayerSpawn", "LivingCityVest", function(ply)
    ply:SetNW2Bool("lc_vest", false) -- (a worn vest goes with the life it was worn in)
end)

-- Charge cells off the Combine: a dead unit sometimes has one, a downed scanner often.
local cvCellDrop = CreateConVar("lc_vest_cell_drop", "25", FLAGS, "Percent chance a dead Combine unit drops a charge cell for a powered vest (a downed scanner: twice that)")
hook.Add("OnNPCKilled", "LivingCityVestCells", function(npc)
    if not IsValid(npc) or not LC.SpawnWorldItem then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.test then return end
    local cls = npc:GetClass()
    local scanner = cls == "npc_cscanner" or cls == "npc_clawscanner" or (st and st.role == "scanner")
    local unit = (st and (st.role == "cop" or st.role == "soldier")) or cls == "npc_metropolice" or cls == "npc_combine_s"
    if not (scanner or unit) then return end
    if math.random(100) > cvCellDrop:GetFloat() * (scanner and 2 or 1) then return end
    LC.SpawnWorldItem("vest_cell", npc:GetPos() + Vector(0, 0, 16), nil, Vector(math.random(-40, 40), math.random(-40, 40), 60))
end)

-- Nobody holds more charge than their vest can.
timer.Create("LivingCityVest", 1, 0, function()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() then
            local cap = LC.VestCap(p)
            if p:Armor() > cap then p:SetArmor(cap) end
        end
    end
end)
