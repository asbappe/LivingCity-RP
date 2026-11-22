--[[
    Living City: a Resistance squad topped up at each stage of a fight, one of them a medic

    The owner, 21 November, approving valve-npc-squad-topup (Valve's City 17: ai_ally_manager, up to 4
    allies, one a medic, replenished at each checkpoint, the newcomers arriving out of sight).

      When      a violent job moves on to its next step (LivingCityQuestAdvanced), each Resistance player
                on it who already leads at least one fighter.
      How many  up to LC.SquadTopUpMost (4), never past their squad limit (sv_livingcity_squads.lua),
                only for the places missing; from rebel territory, seen by nobody, put out of sight
                between it and the leader (LC.RebelTerritoryBackup), running in. Not when the Resistance
                can't spare fighters (lc_manpower).
      The medic one of the squad, if none is yet: in the medic's clothes. Every few seconds he patches
                up the leader or a squad mate near him who is badly hurt (LC.SquadMedicHeal health,
                once every LC.SquadMedicEvery seconds).
      Nothing on screen: they come running.
]]

if CLIENT then return end

LC = LC or {}
LC.SquadTopUpMost, LC.SquadMedicHeal, LC.SquadMedicEvery, LC.SquadMedicReach = 4, 20, 12, 160

local function Vo(st, name) return "vo/npc/" .. (st and st.gender or "male") .. "01/" .. name .. ".wav" end

local function MedicModel(m)
    m = string.lower(m or "")
    local mm = string.gsub(m, "/group03/", "/group03m/")
    if mm ~= m and (not util.IsValidModel or util.IsValidModel(mm)) then return mm end
    return nil
end

local function MakeMedic(npc, st)
    st.squadMedic = true
    local mm = MedicModel(npc:GetModel())
    if mm then npc:SetModel(mm) end
end

-- Top up one leader's squad. -> how many came.
function LC.SquadTopUp(ply)
    if not (IsValid(ply) and ply:Alive()) or not LC.FollowersOf or not LC.RebelRecruit or not LC.RebelTerritoryBackup then return 0 end
    if LC.QuestFaction and LC.QuestFaction(ply) ~= "resistance" then return 0 end
    local have = LC.FollowersOf(ply)
    if #have == 0 then return 0 end -- (only a squad that exists)
    local limit = LC.SquadLimit and (LC.SquadLimit(ply)) or LC.SquadTopUpMost
    local need = math.min(LC.SquadTopUpMost, limit) - #have
    if need <= 0 then return 0 end
    if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
        local hold = GetConVar("lc_manpower_hold")
        if LC.ManpowerPool("rebel").reserve < (hold and hold:GetInt() or 3) then return 0 end
    end
    local medic = false
    for _, f in ipairs(have) do local fst = LC.NPCs[f] if fst and fst.squadMedic then medic = true end end
    local came = 0
    local say = rawget(ply, "ChatPrint")
    ply.ChatPrint = function() end -- (each newcomer's own "is with you" line: they come running instead)
    for _, c in ipairs(LC.RebelTerritoryBackup(ply, need)) do
        LC.Try(LC.RebelRecruit, ply, c.npc, c.st)
        if c.st.follow == ply then
            came = came + 1
            if not medic then MakeMedic(c.npc, c.st) medic = true end
        end
    end
    ply.ChatPrint = say
    if came > 0 and LC.Log then LC.Log("info", string.format("%s's squad topped up with %d", ply:Nick(), came)) end
    return came
end

hook.Add("LivingCityQuestAdvanced", "LivingCitySquadTopUp", function(q)
    if not (q and (q.violent or (q.tmpl and q.tmpl.violent))) or not LC.QB then return end
    for _, p in ipairs(LC.QB.Members(q)) do LC.Try(LC.SquadTopUp, p) end
end)

-- The squad's medic patches up whoever near him is badly hurt: the leader first.
function LC.SquadMedicTick(now)
    now = now or CurTime()
    for npc, st in pairs(LC.NPCs or {}) do
        local lead = st.squadMedic and st.follow
        if IsValid(npc) and npc:Health() > 0 and IsValid(lead) and now >= (st.medicNext or 0) then
            local hurt
            if lead:Alive() and lead:Health() < lead:GetMaxHealth() * 0.75 and lead:GetPos():DistToSqr(npc:GetPos()) < LC.SquadMedicReach ^ 2 then
                hurt = lead
            else
                for _, f in ipairs(LC.FollowersOf and LC.FollowersOf(lead) or {}) do
                    if f ~= npc and IsValid(f) and f:Health() > 0 and f:Health() < f:GetMaxHealth() * 0.6
                        and f:GetPos():DistToSqr(npc:GetPos()) < LC.SquadMedicReach ^ 2 then hurt = f break end
                end
            end
            if hurt then
                st.medicNext = now + LC.SquadMedicEvery
                hurt:SetHealth(math.min(hurt:GetMaxHealth(), hurt:Health() + LC.SquadMedicHeal))
                npc:EmitSound(Vo(st, "health0" .. math.random(1, 5)), 70)
                if hurt.EmitSound then hurt:EmitSound("items/smallmedkit1.wav", 60) end
            end
        end
    end
end
timer.Create("LivingCitySquadMedic", 2, 0, function() LC.Try(LC.SquadMedicTick) end)
