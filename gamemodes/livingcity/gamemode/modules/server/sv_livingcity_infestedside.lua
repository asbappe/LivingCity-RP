--[[
    Living City: the infested, a hidden side (the owner, 13 November playtest: off the F4 menu and every
    other menu, never chosen. "Going down to a zombie or a headcrab in an infestation turns you, unless a
    squad member or a player gets you up while you bleed out; with no revive you come back as one of the
    infested, in the infestation.")

      - Nobody chooses it: the Infested aren't on F4's Factions (but for whoever is one), and joining is
        refused (LC.CanJoinFaction). An admin can still set it.
      - Put down (bleeding out) by a zombie, a headcrab or an infested player, inside an infestation
        zone: you're turning (told so). Got up: it passes. Bled out or gave up: no close call is used;
        you come back as one of the infested, in their nest (LC.TurnInfested).
      - The way back: killed while infested, the headcrab dies with you. That costs a close call, and
        you wake at the clinic as yourself, on the side you were on (LC.InfestedFreed). With none left,
        it's the end of you, as any death would be.
      Vortigaunts and stalkers never turn.
]]

if CLIENT then return end

LC = LC or {}

function LC.InInfestZone(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("infest") or {}) do
        if LCZ and LCZ.Contains and LCZ.Contains(z, pos, 0) then return true end
    end
    return false
end

function LC.InfestedAttacker(att)
    if not IsValid(att) then return false end
    if att:IsPlayer() then return LC.PlayerIsZombie ~= nil and LC.PlayerIsZombie(att) == true end
    local c = att.GetClass and att:GetClass() or ""
    return string.find(c, "zombie", 1, true) ~= nil or string.find(c, "headcrab", 1, true) ~= nil
end

local function CanTurn(ply)
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end
    if LC.IsVortChar and LC.IsVortChar(ply) then return false end
    return true
end

hook.Add("LivingCityDowned", "LivingCityInfestedSide", function(ply, attacker)
    if not IsValid(ply) or not LC.InfestedAttacker(attacker) or not LC.InInfestZone(ply:GetPos()) or not CanTurn(ply) then return end
    ply.lcTurning = true
    ply:ChatPrint("[Miscount] Something is in the wound. If nobody gets you up, you'll turn.")
end)
hook.Add("LivingCityRevived", "LivingCityInfestedSide", function(ply) if IsValid(ply) then ply.lcTurning = nil end end)
hook.Add("PlayerSpawn", "LivingCityInfestedSide", function(ply) ply.lcTurning = nil end)

-- They turn (called as they die, from sv_livingcity_character.lua): their side is kept for the way back.
function LC.TurnInfested(ply)
    if not IsValid(ply) then return false end
    local was = ply:GetNW2String("lcf_faction", "citizen") .. ":" .. ply:GetNW2String("lcf_special", "")
    ply:SetPData("lc_infested_from", was)
    if LC.SetFaction then LC.SetFaction(ply, "zombie", nil, true) end
    ply:ChatPrint("[Miscount] You turned. You come back as one of the infested, in the nest. Killed like this, the headcrab dies with you.")
    hook.Run("LivingCityTurned", ply)
    return true
end

-- Freed by death (called as they die): back to the side they were on.
function LC.InfestedFreed(ply)
    if not IsValid(ply) then return false end
    local was = ply:GetPData("lc_infested_from", "citizen:")
    local fid, sid = string.match(was, "^([^:]*):?(.*)$")
    if not fid or fid == "" or fid == "zombie" or not (LCF and LCF.Get and LCF.Get(fid)) then fid, sid = "citizen", "" end
    ply:RemovePData("lc_infested_from")
    if LC.SetFaction then LC.SetFaction(ply, fid, sid ~= "" and sid or nil, true) end
    ply:ChatPrint("[Miscount] The headcrab died with you. You come back as yourself.")
    hook.Run("LivingCityFreedOfInfestation", ply)
    return true
end
