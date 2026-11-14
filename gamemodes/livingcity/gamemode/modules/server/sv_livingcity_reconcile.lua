--[[
    Living City: who you are now, and what goes with it (the owner, 7 November: "when I become a metrocop
    (or any class) ... the fists skin and likewise other class/job/faction unique attributes and
    customisations are checked, and also checked upon connecting to the server")

    One pass, LC.ReconcileAppearance, puts a player's job, looks and kit in line with their faction and
    rank. It runs when they connect, when they spawn, when their faction or rank changes, and when their
    Union job changes. Anyone outside the citizens and the Resistance (a unit, the Overwatch, the City
    Administrator, a vortigaunt, the infested):

      Union job       taken, the saved one too, so a rejoin or a restart doesn't bring it back
      job tools       the Union's sprayer, hoover and medkit go (unless the rank itself carries one)
      job clothes     the rank's own model again, its own skin and plain bodygroups (no suit skin
                      or overalls carried over from the old job onto the uniform)
      hands           set up again from the body they now have (no suit gloves on a unit's hands)

    Citizens and the Resistance keep their job and dress for it as before (sv_livingcity_outfits.lua).
]]

if CLIENT then return end

LC = LC or {}

local HOLDS_JOBS = { citizen = true, resistance = true }

-- May someone of this faction hold a Union job at all?
function LC.FactionHoldsJobs(fid) return HOLDS_JOBS[fid or ""] == true end

-- Every tool any Union job hands out.
local function JobTools()
    local out = {}
    for _, o in ipairs(LCJ and LCJ.Occupations or {}) do
        for _, cls in ipairs(o.tools or {}) do out[cls] = true end
    end
    return out
end

-- Put a player's job, looks and kit in line with who they are now. Returns a list of what changed.
function LC.ReconcileAppearance(ply)
    local done = {}
    if not IsValid(ply) or not ply:IsPlayer() then return done end
    local fid = ply:GetNW2String("lcf_faction", "")
    if fid == "" or HOLDS_JOBS[fid] then return done end
    -- the Union job: the one held now, and the one saved for next time
    local job = LC.Job and LC.Job(ply)
    if job and LC.RevokeUnionJob then
        local f = LCF and LCF.Get and LCF.Get(fid)
        local why = fid == "cp"
            and ("You're a Civil Protection unit now. The Union has taken your job (" .. job.name .. ") and its kit back.")
            or ("You're " .. ((f and f.name) or fid) .. " now. The Union has taken your job (" .. job.name .. ") and its kit back.")
        if LC.RevokeUnionJob(ply, why) then done[#done + 1] = "job" end
    end
    if ply:GetNW2String("lcj_job", "") ~= "" then ply:SetNW2String("lcj_job", "") done[#done + 1] = "job" end
    if ply:GetPData("lcj_job", "") ~= "" then ply:SetPData("lcj_job", "") done[#done + 1] = "saved job" end
    -- the Union's tools (the rank's own loadout stays)
    local issued = {}
    for _, cls in ipairs(LC.RankLoadout and LC.RankLoadout(ply) or {}) do issued[cls] = true end
    for cls in pairs(JobTools()) do
        if not issued[cls] and ply:HasWeapon(cls) then
            ply:StripWeapon(cls)
            done[#done + 1] = cls
        end
    end
    -- no job clothes on duty, and no duty dressing to come back to
    ply.lcDutyDressed = nil
    if not ply:Alive() then return done end
    -- (in a disguise, or taken by a secret ending's dancers: that look is theirs until it ends)
    if ply.lcdOldModel or ply.lcEndTaken then return done end
    -- the rank's own body, its own skin and plain bodygroups: nothing carried over from a job's suit
    if LC.RefreshModel then LC.RefreshModel(ply) end
    if ply.GetSkin and ply:GetSkin() ~= 0 then ply:SetSkin(0) done[#done + 1] = "skin" end
    local bgs = false
    for i = 0, (ply.GetNumBodyGroups and ply:GetNumBodyGroups() or 1) - 1 do
        if ply.GetBodygroup and ply:GetBodygroup(i) ~= 0 then ply:SetBodygroup(i, 0) bgs = true end
    end
    if bgs then done[#done + 1] = "bodygroups" end
    -- the hands, from the body they have now (sv_livingcity_factions.lua: a unit's own sleeves)
    if ply.SetupHands then ply:SetupHands() end
    return done
end

local function Later(ply, secs)
    timer.Simple(secs, function()
        if not IsValid(ply) then return end
        local ok, err = LC.Try(LC.ReconcileAppearance, ply)
        if not ok and LC.Error then LC.Error("reconcile", err) end
    end)
end

-- (after the spawn's own dressing: the body at 0, the job's clothes at 0.3, the job's kit at 0.5)
hook.Add("PlayerSpawn", "LivingCityReconcile", function(ply) Later(ply, 0.7) end)
-- (after the saved job is read back, 1 second in, and the faction looked at again, at 2.5)
hook.Add("PlayerInitialSpawn", "LivingCityReconcile", function(ply) Later(ply, 3) end)
hook.Add("LivingCityFactionChanged", "LivingCityReconcile", function(ply) Later(ply, 0.8) end)
hook.Add("LivingCityRankChanged", "LivingCityReconcile", function(ply) Later(ply, 0.1) end)
hook.Add("LivingCityJobChanged", "LivingCityReconcile", function(ply) Later(ply, 0.1) end)
