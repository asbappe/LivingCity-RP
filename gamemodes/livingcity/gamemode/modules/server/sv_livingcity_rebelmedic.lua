--[[
    Living City: the Resistance's medic (the owner, 14 November: "can we get a resistance medic in each
    rebel territory that can heal the player and other NPCs? he wouldn't follow or squad up. He might
    charge 3 credits for a small health vial or 8 for a large medkit. Maybe a subtitle explaining 'I hate
    to charge, but these don't grow on trees.'")

    One medic at the heart of each rebel territory (touching zones are one, as for the quartermaster),
    in the Resistance's medic clothes. He keeps his post like the quartermaster (st.quartermaster, with
    st.medic to tell them apart): never follows, never squads up, never goes on raids or errands; led,
    pushed or frightened off, he goes back.

      E on him (anyone the Resistance doesn't take for the Combine): a quick menu (number keys).
        1  A small health vial: LC.MedicVialHeal (10) health for LC.MedicVialPrice (3) credits
        2  A large medkit: LC.MedicKitHeal (40) health for LC.MedicKitPrice (8) credits
      Every few seconds he tends one hurt friendly NPC near him (the Resistance's people, freed
      vortigaunts, citizens on rebel ground): LC.MedicNPCHeal (25) health, free, within LC.MedicReach.
      Killed: another takes his place after LC.MedicRespawn (300) seconds.

      lc_rebel_medic 0/1 (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_rebel_medic", "1", FLAGS, "A Resistance medic in each rebel territory heals players (for a few credits) and hurt friendly NPCs (free)")

LC.MedicVialPrice, LC.MedicVialHeal = 3, 10
LC.MedicKitPrice, LC.MedicKitHeal = 8, 40
LC.MedicNPCHeal, LC.MedicReach, LC.MedicNPCEvery = 25, 500, 6
LC.MedicRespawn = 300
LC.MedicDead = LC.MedicDead or {}

util.AddNetworkString("lc_medic_menu")
util.AddNetworkString("lc_medic_buy")

local function Vo(st, name) return "vo/npc/" .. (st and st.gender or "male") .. "01/" .. name .. ".wav" end

-- The medic's own clothes: the same face, from the medic set.
local function MedicModel(m)
    m = string.lower(m or "")
    local mm = string.gsub(m, "/group03/", "/group03m/")
    if mm ~= m and (not util.IsValidModel or util.IsValidModel(mm)) then return mm end
    return nil
end

-- The medic near a spot, if any (within r).
function LC.MedicNear(pos, r)
    r = r or 220
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.medic and npc:Health() > 0 and npc:GetPos():DistToSqr(pos) < r * r then return npc, st end
    end
    return nil
end

local function Zones() return LC.ZonesOfKindShared and LC.ZonesOfKindShared("rebel") or {} end

function LC.EnsureMedics()
    if not cvOn:GetBool() or not LC.Running or not LC.SpawnRebel then return end
    if GetConVar("lc_rebels") and GetConVar("lc_rebels"):GetInt() <= 0 then return end
    local zones = Zones()
    local have = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.medic and npc:Health() > 0 then
            local lead = st.zone and table.HasValue(zones, st.zone) and LC.RebelLeader and LC.RebelLeader(st.zone)
            if not lead or have[lead] then
                LC.NPCs[npc] = nil
                npc:Remove()
            else
                have[lead] = true
            end
        end
    end
    for _, z in ipairs(zones) do
        if not z.grown and LC.RebelIsLeader and LC.RebelIsLeader(z) and not have[z] and CurTime() > (LC.MedicDead[z] or 0) then
            local p = LC.RebelHiddenSpot and LC.RebelHiddenSpot(z)
            if p then
                local npc, st = LC.ManpowerFree(LC.SpawnRebel, p + Vector(0, 0, 4), z, "weapon_pistol") -- (never from the reserve, as the quartermaster)
                if IsValid(npc) then
                    st.quartermaster, st.medic, st.unmanaged = true, true, true -- (keeps his post: sv_livingcity_rebels.lua)
                    st.qmHome = p + Vector(0, 0, 4)
                    local mm = MedicModel(npc:GetModel())
                    if mm then npc:SetModel(mm) end
                    LC.SetNPCStr(npc, "lc_pname", "Medic " .. LC.NPCStr(npc, "lc_pname", ""))
                    LC.SetNPCStr(npc, "lc_pjob", "Resistance medic: patches people up, for a few credits")
                end
            end
        end
    end
end

hook.Add("OnNPCKilled", "LivingCityRebelMedic", function(npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.medic and st.zone then
        LC.MedicDead[LC.RebelLeader and LC.RebelLeader(st.zone) or st.zone] = CurTime() + LC.MedicRespawn
        if LC.RadioNotice then LC.RadioNotice("resistance", "We lost the medic. Someone will take his bag, give it time.") end
    end
end)

-- E on him: the menu (the Resistance's rules for strangers are checked by the caller).
function LC.UseMedic(ply, npc)
    if not IsValid(ply) or not ply:Alive() or not IsValid(npc) then return false end
    local st = LC.NPCs[npc]
    if not st or not st.medic then return false end
    if LC.Face then LC.Face(npc, ply:GetPos()) end
    local hp, max = ply:Health(), ply:GetMaxHealth()
    if hp >= max then
        if not LC.ResistanceSay(ply, npc, "medic_fine", nil, nil, "[Medic] ") then npc:EmitSound(Vo(st, "hi0" .. math.random(1, 2)), 70) end
        return false
    end
    if not LC.ResistanceSay(ply, npc, "medic_hurt", nil, nil, "[Medic] ") then npc:EmitSound(Vo(st, "health0" .. math.random(1, 5)), 70) end
    net.Start("lc_medic_menu")
    net.WriteEntity(npc)
    net.WriteUInt(LC.MedicVialPrice, 8) net.WriteUInt(LC.MedicVialHeal, 8)
    net.WriteUInt(LC.MedicKitPrice, 8) net.WriteUInt(LC.MedicKitHeal, 8)
    net.WriteUInt(math.max(0, math.floor(LC.Credits and LC.Credits(ply) or 0)), 16)
    net.Send(ply)
    return true
end

-- Buy his care: "vial" or "kit". True, or false and why.
function LC.MedicBuy(ply, what)
    if not IsValid(ply) or not ply:Alive() then return false end
    local npc, st = LC.MedicNear(ply:GetPos(), 220)
    if not IsValid(npc) then return false, "The medic isn't here." end
    local price, heal = LC.MedicVialPrice, LC.MedicVialHeal
    if what == "kit" then price, heal = LC.MedicKitPrice, LC.MedicKitHeal elseif what ~= "vial" then return false end
    local max = ply:GetMaxHealth()
    if ply:Health() >= max then return false, "\"You look fine to me.\"" end
    if not LC.Credits or LC.Credits(ply) < price then
        LC.ResistanceSay(ply, npc, "medic_broke", nil, string.format("(%d credits.)", price), "[Medic] ")
        return false
    end
    LC.AddCredits(ply, -price, "the Resistance's medic")
    ply:SetHealth(math.min(max, ply:Health() + heal))
    ply:EmitSound(what == "kit" and "items/medshot4.wav" or "items/smallmedkit1.wav", 60)
    LC.ResistanceSay(ply, npc, "medic_charge", nil, nil, "[Medic] ")
    hook.Run("LivingCityMedicHealed", ply, npc, what)
    return true
end

net.Receive("lc_medic_buy", function(_, ply)
    local what = net.ReadString()
    if (ply.lcMedicNext or 0) > CurTime() then return end
    ply.lcMedicNext = CurTime() + 0.5
    local ok, why = LC.MedicBuy(ply, what)
    if not ok and why then ply:ChatPrint("[Medic] " .. why) end
end)

-- Hurt friendly NPCs near him are seen to, one at a time, free.
local FRIENDS = { rebel = true, vort = true, vortigaunt = true }
function LC.MedicTendNPCs(now)
    local healed = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.medic and npc:Health() > 0 and now >= (st.medicNext or 0) then
            st.medicNext = now + LC.MedicNPCEvery
            local best, bd
            local here = npc:GetPos()
            for o, os in pairs(LC.NPCs) do
                if o ~= npc and IsValid(o) and o:Health() > 0 and o.GetMaxHealth and o:Health() < o:GetMaxHealth() and not os.foe
                    and (FRIENDS[os.role] or (os.role == "citizen" and LC.InRebelZone and LC.InRebelZone(o:GetPos()))) then
                    local d = o:GetPos():DistToSqr(here)
                    if d < LC.MedicReach * LC.MedicReach and (not bd or d < bd) then best, bd = o, d end
                end
            end
            if best then
                best:SetHealth(math.min(best:GetMaxHealth(), best:Health() + LC.MedicNPCHeal))
                best:EmitSound("items/smallmedkit1.wav", 60)
                if LC.Face then LC.Face(npc, best:GetPos()) end
                healed = healed + 1
            end
        end
    end
    return healed
end

timer.Create("LivingCityRebelMedics", 10, 0, function()
    local ok, err = LC.Try(LC.EnsureMedics)
    if not ok and LC.Error then LC.Error("rebel medics", err) end
end)
timer.Create("LivingCityRebelMedicTend", 2, 0, function()
    if not cvOn:GetBool() or not LC.Running then return end
    local ok, err = LC.Try(LC.MedicTendNPCs, CurTime())
    if not ok and LC.Error then LC.Error("rebel medic tending", err) end
end)
