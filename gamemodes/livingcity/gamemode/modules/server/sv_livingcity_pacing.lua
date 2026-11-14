--[[
    Living City: who's in a fight, and the Combine's action music

      In a fight (LC.InFight): hurt by, or hurting, anyone (a person or an NPC),
      or firing a gun, in the last 30 seconds. Sleep holds off the eyes closing
      while it lasts (sv_livingcity_rest.lua: the owner, 7 November, "going into a
      sweep with shooting and suddenly my eyes are closing").

      In action (anyone, since 13 November): having fired more than 2 shots, or
      been hurt by someone, in the last 12 seconds. Nothing else is action.
      Their game then plays Half-Life 2's combat music (cl_livingcity_atmos.lua: the owner, 7 November, "as the combine
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

function LC.InFight(ply, secs)
    return IsValid(ply) and (ply.lcFightAt or -1e9) > CurTime() - (secs or FIGHT_SECS)
end
function LC.NoteFight(ply) if IsValid(ply) and ply:IsPlayer() then ply.lcFightAt = CurTime() end end

hook.Add("EntityTakeDamage", "LivingCityPacingFight", function(victim, dmg)
    if not IsValid(victim) or not dmg or dmg:GetDamage() <= 0 then return end
    local att = dmg:GetAttacker()
    if not IsValid(att) or att == victim or att == game.GetWorld() then return end
    if not (att:IsPlayer() or att:IsNPC()) then return end
    if victim:IsPlayer() then LC.NoteFight(victim) LC.NoteShotAt(victim) end
    if att:IsPlayer() and (victim:IsPlayer() or victim:IsNPC()) then
        LC.NoteFight(att)
        if LC.IsEnemyOf(att, victim) then LC.NoteShot(att) end
    end
end)
hook.Add("EntityFireBullets", "LivingCityPacingFight", function(ent)
    if IsValid(ent) and ent:IsPlayer() then ent.lcFightAt = CurTime() end -- (a shot alone is no longer action: LC.NoteShot)
end)

-- An enemy of this player: anyone not on their own side (a person or an NPC). The city's ordinary
-- citizens count too, but never the player's own side.
function LC.IsEnemyOf(ply, victim)
    if not (IsValid(ply) and IsValid(victim)) or ply == victim then return false end
    local mine = LC.SquadSide and LC.SquadSide(ply) or nil
    local theirs
    if victim:IsPlayer() then theirs = LC.SquadSide and LC.SquadSide(victim) or nil
    else theirs = LC.QuestNPCSide and LC.QuestNPCSide(victim) or nil end
    return mine == nil or theirs == nil or mine ~= theirs
end

-- Asleep, lying in bed, or in a dream: never in action, whatever goes on in the city.
function LC.AtRest(ply)
    if not IsValid(ply) then return false end
    if ply:GetNW2Bool("lc_sleeping", false) or ply:GetNW2Bool("lc_dreaming", false) then return true end
    if LC.Dreaming and LC.Dreaming(ply) then return true end
    local top = ply:GetNW2Vector("lc_bed_top", Vector(0, 0, 0))
    return top ~= nil and type(top) ~= "string" and (top.x ~= 0 or top.y ~= 0 or top.z ~= 0) -- (lying in bed)
end

-- The action music's one rule (the owner, 13 November: "action music only plays for a player when
-- they've fired more than 2 bullets and/or when they've been shot", then 14 November: "let's change the
-- 2 shots to 'shooting an enemy twice', so that shooting a shot into the air or as a warning at the
-- ground/wall is not action music worthy"). For everyone, whatever their side: ACTION_SHOTS hits on an
-- enemy inside ACTION_FIGHT seconds (LC.NoteShot, from the damage), or hurt by a person or an NPC.
-- A job, a skirmish or an event nearby is never action on its own any more.
local ACTION_SHOTS = 2
function LC.NoteShot(ply, now)
    if not (IsValid(ply) and ply:IsPlayer()) then return 0 end
    now = now or CurTime()
    local keep = {}
    for _, at in ipairs(ply.lcShotTimes or {}) do if now - at < ACTION_FIGHT then keep[#keep + 1] = at end end
    keep[#keep + 1] = now
    while #keep > 8 do table.remove(keep, 1) end
    ply.lcShotTimes = keep
    if #keep >= ACTION_SHOTS then ply.lcActionAt = now end
    return #keep
end
function LC.NoteShotAt(ply, now)
    if IsValid(ply) and ply:IsPlayer() then ply.lcActionAt = now or CurTime() end
end

-- Why a player is in action now ("fight"), or nil.
function LC.InAction(ply)
    if not IsValid(ply) or not ply:Alive() then return nil end
    if LC.AtRest(ply) then return nil end
    if (ply.lcActionAt or -1e9) > CurTime() - ACTION_FIGHT then return "fight" end
    return nil
end

-- In or within this far of an infestation: the eerie music's ground (cl_livingcity_atmos.lua).
LC.EerieRange = 700
function LC.ByInfest(pos)
    if not pos or not LC.ZonesOfKindShared or not LCZ or not LCZ.Near then return false end
    for _, z in ipairs(LC.ZonesOfKindShared("infest") or {}) do
        if LCZ.Near(z, pos, LC.EerieRange) then return true end
    end
    return false
end

function LC.ActionTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local by = ply:Alive() and LC.ByInfest(ply:GetPos()) or false
        if ply:GetNW2Bool("lc_by_infest", false) ~= by then ply:SetNW2Bool("lc_by_infest", by) end
        local was = ply:GetNW2Float("lc_action_until", 0)
        if LC.InAction(ply) then
            if was < now + ACTION_HOLD - 3 then ply:SetNW2Float("lc_action_until", now + ACTION_HOLD) end
        elseif was > now and LC.AtRest(ply) then
            ply:SetNW2Float("lc_action_until", 0) -- (gone to bed: no more of it)
        end
    end
end
timer.Create("LivingCityAction", 2, 0, function()
    local ok, err = LC.Try(LC.ActionTick, CurTime())
    if not ok and LC.Error then LC.Error("pacing", err) end
end)
