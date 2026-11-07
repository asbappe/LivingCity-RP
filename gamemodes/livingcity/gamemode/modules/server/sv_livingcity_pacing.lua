--[[
    Living City: who's in a fight, and the Combine's action music

      In a fight (LC.InFight): hurt by, or hurting, anyone (a person or an NPC),
      or firing a gun, in the last 30 seconds. Sleep holds off the eyes closing
      while it lasts (sv_livingcity_rest.lua: the owner, 7 November, "going into a
      sweep with shooting and suddenly my eyes are closing").

      In action (a Civil Protection unit, the Overwatch's soldiers included): in a
      fight, on a violent job, or on duty in a raid, a sweep or a lockdown, or
      near a skirmish. Their game then plays Half-Life 2's combat music, as a
      wanted rebel's plays theirs (cl_livingcity_atmos.lua: the owner, 7 November,
      "as the combine nothing plays at all").
]]

if CLIENT then return end

LC = LC or {}

local FIGHT_SECS = 30   -- (a fight counts this long after the last shot or hurt)
local ACTION_HOLD = 20  -- (the music's state is kept this long after the action ends)
local SKIRMISH_NEAR = 3000

function LC.InFight(ply, secs)
    return IsValid(ply) and (ply.lcFightAt or -1e9) > CurTime() - (secs or FIGHT_SECS)
end
function LC.NoteFight(ply) if IsValid(ply) and ply:IsPlayer() then ply.lcFightAt = CurTime() end end

hook.Add("EntityTakeDamage", "LivingCityPacingFight", function(victim, dmg)
    if not IsValid(victim) or not dmg or dmg:GetDamage() <= 0 then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or att == victim or att == game.GetWorld() then return end
    if not (att:IsPlayer() or att:IsNPC()) then return end
    if victim:IsPlayer() then LC.NoteFight(victim) end
    if att:IsPlayer() and (victim:IsPlayer() or victim:IsNPC()) then LC.NoteFight(att) end
end)
hook.Add("EntityFireBullets", "LivingCityPacingFight", function(ent)
    if IsValid(ent) and ent:IsPlayer() then ent.lcFightAt = CurTime() end
end)

local ACTION_EVENTS = { sweep = true, raid = true, lockdown = true }

-- Why a unit is in action now, or nil.
function LC.InAction(ply)
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2String("lcf_faction", "") ~= "cp" then return nil end
    if LC.InFight(ply) then return "fight" end
    local q = LC.QuestOf and LC.QuestOf[ply]
    if q and q.violent then return "job" end
    if LC.Event and ACTION_EVENTS[LC.Event] then return LC.Event end
    local sk = LC.Skirmish
    if sk then
        local z = sk.zone
        local pos = z and (z.pos or z.center)
        if not pos or ply:GetPos():DistToSqr(pos) < SKIRMISH_NEAR * SKIRMISH_NEAR then return "skirmish" end
    end
    return nil
end

function LC.ActionTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local was = ply:GetNW2Float("lc_action_until", 0)
        if LC.InAction(ply) then
            if was < now + ACTION_HOLD - 3 then ply:SetNW2Float("lc_action_until", now + ACTION_HOLD) end
        elseif was > now and ply:GetNW2String("lcf_faction", "") ~= "cp" then
            ply:SetNW2Float("lc_action_until", 0) -- (left Civil Protection: no more of it)
        end
    end
end
timer.Create("LivingCityAction", 2, 0, function()
    local ok, err = pcall(LC.ActionTick, CurTime())
    if not ok and LC.Error then LC.Error("pacing", err) end
end)
