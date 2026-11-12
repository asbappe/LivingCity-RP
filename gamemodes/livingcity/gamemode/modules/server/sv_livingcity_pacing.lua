--[[
    Living City: who's in a fight, and the Combine's action music

      In a fight (LC.InFight): hurt by, or hurting, anyone (a person or an NPC),
      or firing a gun, in the last 30 seconds. Sleep holds off the eyes closing
      while it lasts (sv_livingcity_rest.lua: the owner, 7 November, "going into a
      sweep with shooting and suddenly my eyes are closing").

      In action (a Civil Protection unit, the Overwatch's soldiers included): in a
      fight, on a violent job and near where it happens, or near a skirmish.
      Their game then plays Half-Life 2's combat music, as a wanted rebel's plays
      theirs (cl_livingcity_atmos.lua: the owner, 7 November, "as the combine
      nothing plays at all").

      A city event starting (inspections, a raid, a lockdown) is never action on
      its own, and nobody asleep, in bed or dreaming is ever in action (the owner,
      12 November: inspections started while they were in bed, then 5000 units
      away in a dream, and the action music played: "there's no radius effect,
      I didn't take the job, and no fighting near me at all").
]]

if CLIENT then return end

LC = LC or {}

local FIGHT_SECS = 30   -- (a fight counts this long after the last shot or hurt)
-- (the owner, 11 November: "I killed all of them in about 5 seconds and the music just kept playing as if it has
-- a minimum amount of time": a fight held the action music for 30 seconds and this 20 more. Now about 20 in all.)
local ACTION_HOLD = 8   -- (the music's state is kept this long after the action ends)
local ACTION_FIGHT = 12 -- (for the music, a fight is over this long after the last shot or hurt)
local JOB_NEAR = 1500   -- (a violent job is action once you are this near where it happens)
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

-- Asleep, lying in bed, or in a dream: never in action, whatever goes on in the city.
function LC.AtRest(ply)
    if not IsValid(ply) then return false end
    if ply:GetNW2Bool("lc_sleeping", false) or ply:GetNW2Bool("lc_dreaming", false) then return true end
    if LC.Dreaming and LC.Dreaming(ply) then return true end
    local top = ply:GetNW2Vector("lc_bed_top", Vector(0, 0, 0))
    return top ~= nil and type(top) ~= "string" and (top.x ~= 0 or top.y ~= 0 or top.z ~= 0) -- (lying in bed)
end

-- Why a unit is in action now, or nil.
function LC.InAction(ply)
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2String("lcf_faction", "") ~= "cp" then return nil end
    if LC.AtRest(ply) then return nil end
    if LC.InFight(ply, ACTION_FIGHT) then return "fight" end
    local q = LC.QuestOf and LC.QuestOf[ply]
    if q and q.violent then
        -- (the owner, 11 November: the music started 100 metres away, the moment the job was taken:
        -- "only kick in when I reach the destination and the fighting starts")
        -- (and only near it: where the job is unknown, it isn't action until there's a fight)
        local okAt, at = pcall(function() return q.stages and LC.QuestObjectivePos and LC.QuestObjectivePos(ply) or nil end)
        if okAt and at and ply:GetPos():DistToSqr(at) < JOB_NEAR * JOB_NEAR then return "job" end
    end
    local sk = LC.Skirmish
    if sk then
        local z = sk.zone
        local pos = z and (z.pos or z.center)
        if pos and ply:GetPos():DistToSqr(pos) < SKIRMISH_NEAR * SKIRMISH_NEAR then return "skirmish" end
    end
    return nil
end

function LC.ActionTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local was = ply:GetNW2Float("lc_action_until", 0)
        if LC.InAction(ply) then
            if was < now + ACTION_HOLD - 3 then ply:SetNW2Float("lc_action_until", now + ACTION_HOLD) end
        elseif was > now and (ply:GetNW2String("lcf_faction", "") ~= "cp" or LC.AtRest(ply)) then
            ply:SetNW2Float("lc_action_until", 0) -- (left Civil Protection, or gone to bed: no more of it)
        end
    end
end
timer.Create("LivingCityAction", 2, 0, function()
    local ok, err = pcall(LC.ActionTick, CurTime())
    if not ok and LC.Error then LC.Error("pacing", err) end
end)
