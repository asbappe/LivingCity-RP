--[[
    City Factions (server)

      - Everyone starts as a Citizen. F4, !faction or lcf_menu opens the faction menu.
      - XP is kept separately per faction and saved by SteamID. Ranks are earned
        automatically as XP crosses each threshold (sh_livingcity_factions.lua).
      - Civil Protection is one career: Recruit, Metrocop, Division Leader,
        then the Overwatch ranks, which need the transhuman conditioning first
        (the Overwatch Candidate story; LC.Condition). City Administrator is
        whitelist only. Father Grigori is one player at a time.
      - Each rank sets model, loadout, health, armor and speed.
      - Living City treats CP / Overwatch / Administrator as Civil Protection,
        Infested as zombies, and hunted ranks as anticitizens outside rebel zones.

    Admin: lcf_setfaction <name> <faction> [special], lcf_setxp <name> <xp>,
           lcf_promote <name>, lcf_demote <name>, lcf_whitelist <name> <faction>
]]

if CLIENT then return end

util.AddNetworkString("lcf_menu")
util.AddNetworkString("lc_hub")
util.AddNetworkString("lcf_join")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAdminTools = CreateConVar("lcf_admin_tools", "1", FLAGS, "Admins keep the physgun and toolgun in every faction")
local cvCooldown   = CreateConVar("lcf_switch_cooldown", "60", FLAGS, "Seconds between faction changes")
local cvCPStanding = CreateConVar("lc_cp_min_standing", "100", FLAGS, "Civil Standing needed to join Civil Protection")
-- (the setting keeps its old name, so a server's own number carries over; since 1 November it counts Intake
-- Processor shifts, the Civil Protection path, the owner asked: the Records Clerk is the Administration path now)
local cvCPClerk = CreateConVar("lc_cp_clerk_shifts", "5", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Intake Processor shifts a citizen must finish before Civil Protection takes them (an Infestation Cleanup shift counts double; 0: no need)")

-- Anyone without a faction becomes a Citizen.
local function EnrollEveryone()
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_faction", "") == "" and LC.SetFaction then LC.SetFaction(p, "citizen", nil, true) end
    end
end
LC.EnrollEveryone = EnrollEveryone

local function Tell(ply, msg) ply:ChatPrint("[Factions] " .. msg) end

------------------------------------------------------------------------
-- Per-player state
------------------------------------------------------------------------

local function FactionOf(ply) return LCF.Get(ply:GetNW2String("lcf_faction", "")) end

local function SpecialOf(ply)
    local f = FactionOf(ply)
    local id = ply:GetNW2String("lcf_special", "")
    return f and id ~= "" and f.specialsById[id] or nil
end

local function XP(ply, fid) return tonumber(ply:GetPData("lcf_xp_" .. fid, 0)) or 0 end

-- Had the transhuman conditioning (the Overwatch ranks are open).
local function Conditioned(ply) return ply:GetPData("lcf_transhuman", "0") == "1" end
LC.Conditioned = Conditioned

local function RankOf(ply)
    local f = FactionOf(ply)
    if not f then return nil end
    return f.ranks[ply:GetNW2Int("lcf_rank", 1)] or f.ranks[1]
end

-- What the player currently "is": the special role if they have one, else their rank.
local function Profile(ply)
    return SpecialOf(ply) or RankOf(ply)
end

local function Titles(ply)
    local f, r, s = FactionOf(ply), RankOf(ply), SpecialOf(ply)
    if not f or not r then return "", "" end
    local unit = LCF.UnitNumber(ply:SteamID())
    local true_, public
    if s then
        true_ = s.name
        public = s.name
    elseif f.id == "cp" and r.overwatch then
        true_ = string.format("%s %d", r.short, unit)
        public = true_
    elseif f.id == "cp" then
        true_ = string.format("CP %s-%d", r.short, unit)
        public = true_
    elseif f.id == "resistance" then
        true_ = "Resistance " .. r.name
        public = r.hunted and true_ or "Citizen" -- the low ranks pass for citizens
    else
        true_ = r.name
        public = r.name
    end
    return true_, public
end

local function Publish(ply)
    local t, p = Titles(ply)
    ply:SetNW2String("lcf_title", t)
    ply:SetNW2String("lcf_public_title", p)
    local f = FactionOf(ply)
    ply:SetNW2Int("lcf_xp", f and XP(ply, f.id) or 0)
end

-- Trust before a gun (the owner, 1 November): the Resistance's ranks that carry arms (Fighter and up, the
-- first "hunted" rank) also need lc_fighter_trust_jobs (3) jobs done for it, whatever the XP: put up the
-- posters, run the errands, before the SMG and the gear. (Counted on "res_jobs": any job from the board
-- finished as one of them, but a Union shift.)
local cvTrust = CreateConVar("lc_fighter_trust_jobs", "3", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Jobs a Resistance member must finish for it before they're trusted as a Fighter (with the XP)")
function LC.ResistanceTrust(ply) return LC.Counter and LC.Counter(ply, "res_jobs") or 0, math.max(0, cvTrust:GetInt()) end

-- Proving yourself before you join (the owner, 9 November: "we don't want anyone to just walk into the resistance, they
-- need to prove themselves as citizens"): lc_resistance_join_sympathy (5) sympathy first, earned by helping them (jobs and
-- quests that help them, food for their supply crate, arms sold to their quartermaster, a ration or arms handed to one of
-- their fighters, siding with the vortigaunts in a dream), or invited in by a story (The Pamphleteer's "join", The Man
-- Inside's "defect"). Anyone who has been in the Resistance has proved it already (lcf_res_proven), so no member is ever
-- locked out by it.
local cvJoin = CreateConVar("lc_resistance_join_sympathy", "5", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Sympathy a citizen needs before the Resistance lets them join (0: anyone)")
function LC.ResistanceProven(ply)
    if not IsValid(ply) then return false end
    if ply.GetPData and ply:GetPData("lc_scar", "0") == "1" then return false end -- (a marked rat, never: sv_livingcity_snitches.lua)
    if ply:GetNW2String("lcf_faction", "") == "resistance" or ply:GetPData("lcf_faction", "") == "resistance" or ply:GetPData("lcf_res_proven", "") == "1" then return true end
    if LC.IsBurned and LC.IsBurned(ply) then return false end -- (burned as an informant: sv_livingcity_snitches.lua)
    return (LC.Trait and LC.Trait(ply, "sympathy") or 0) >= math.max(0, cvJoin:GetInt())
end
function LC.ResistanceInvite(ply) if IsValid(ply) then ply:SetPData("lcf_res_proven", "1") end end

-- A gift that counts (the owner): a ration packet (no other food or water), hand-loaded ammunition, a gun or a grenade,
-- handed to a Resistance Fighter or higher (an openly armed rebel). One sympathy for each different rebel, ever.
function LC.ResistanceGift(id)
    local it = LCS and LCS.Items and LCS.Items[id]
    return id == "ration" or (it ~= nil and (it.arms == true or it.use == "throw"))
end
hook.Add("LivingCityGave", "LivingCityResistanceGift", function(giver, target, id)
    if not (IsValid(giver) and IsValid(target)) or not LC.ResistanceGift(id) then return end
    if giver:GetNW2String("lcf_faction", "") == "resistance" or target:GetNW2String("lcf_faction", "") ~= "resistance" then return end
    if target:GetNW2Int("lcf_rank", 1) < 3 then return end -- (Fighter and up)
    local key = tostring(target:SteamID64())
    local list = giver:GetPData("lcf_gifted", "")
    for k in string.gmatch(list, "[^,]+") do if k == key then return end end
    giver:SetPData("lcf_gifted", list == "" and key or (list .. "," .. key))
    if LC.AddTrait then LC.AddTrait(giver, "sympathy", 1) end
    giver:ChatPrint("[Resistance] They take it with a nod. They'll remember that.")
end)
local function RankFor(ply, f, xp)
    local idx = LCF.RankIndexFor(f, xp or XP(ply, f.id), Conditioned(ply))
    if f.id == "resistance" then
        local have, need = LC.ResistanceTrust(ply)
        if have < need then
            for i, r in ipairs(f.ranks) do
                if r.hunted then idx = math.min(idx, math.max(1, i - 1)) break end
            end
        end
    end
    return idx
end
LC.FactionRankFor = RankFor

local function RecomputeRank(ply)
    local f = FactionOf(ply)
    if not f then return false end
    local old = ply:GetNW2Int("lcf_rank", 1)
    ply:SetNW2Bool("lcf_transhuman", Conditioned(ply))
    local new = RankFor(ply, f)
    ply:SetNW2Int("lcf_rank", new)
    Publish(ply)
    return new ~= old, new > old
end

------------------------------------------------------------------------
-- Applying a faction to a body
------------------------------------------------------------------------

-- Is this a woman's model? (the city's citizens, Mossman, Alyx, the female cop)
function LC.IsFemaleModel(model)
    local m = string.lower(tostring(model or ""))
    return string.find(m, "female", 1, true) ~= nil or string.find(m, "mossman", 1, true) ~= nil
        or string.find(m, "alyx", 1, true) ~= nil or string.find(m, "_fem", 1, true) ~= nil
end

-- The model for this rank: the one the player chose, if the rank has it (or its
-- counterpart, such as the same face in the Resistance's clothes); else by unit number.
local function PickModel(ply, models)
    -- a body that isn't the rank's list: a stalker's (sv_livingcity_custody.lua),
    -- an installed Combine pack's (sv_livingcity_combinemodels.lua)
    for _, fn in pairs(LC.ModelOverrides or {}) do
        local m = fn(ply)
        if m then return m end
    end
    local chosen = ply:GetNW2String("lc_model", "")
    -- a rank with a body for each sex (the Administrator: Breen or Mossman) goes by the face the player chose
    if models.byGender then
        local fem = LC.IsFemaleModel(chosen)
        for _, m in ipairs(models) do
            if LC.IsFemaleModel(m) == fem then return m end
        end
    end
    if chosen ~= "" then
        local base = string.match(chosen, "[^/]+$")
        for _, m in ipairs(models) do
            if m == chosen then return m end
        end
        for _, m in ipairs(models) do
            if base and string.match(m, "[^/]+$") == base then return m end
        end
    end
    return models[(LCF.UnitNumber(ply:SteamID()) % #models) + 1]
end

function LC.RefreshModel(ply)
    local prof = Profile(ply)
    local models = prof and prof.models or {}
    if #models > 0 and ply:Alive() then
        ply:SetModel(PickModel(ply, models))
        ply:SetupHands()
    end
end

local function ApplyBody(ply)
    local prof = Profile(ply)
    if not prof then return end
    local models = prof.models or {}
    if #models > 0 then
        ply:SetModel(PickModel(ply, models))
    end
    ply:SetupHands()
    local hp = prof.health or 100
    ply:SetMaxHealth(hp)
    ply:SetHealth(hp)
    ply:SetArmor(prof.armor or 0)
    if LC.IssueVest then LC.IssueVest(ply, prof.armor or 0) end -- (the rank's vest: sv_livingcity_vest.lua)
    -- the city's slower pace, unless the rank sets its own
    local gm = GAMEMODE
    local slow = gm and gm.LCSlowMovement and gm:LCSlowMovement()
    ply:SetWalkSpeed(prof.walk or (slow and gm.cvWalk:GetInt()) or 160)
    ply:SetRunSpeed(prof.run or (slow and gm.cvRun:GetInt()) or 260)
    if slow then ply:SetJumpPower(gm.cvJump:GetInt()) end
end

-- keep: a promotion changes the loadout, it doesn't empty your hands. Only top
-- up what's missing (the medic's medkit, the builder's tools, what you were holding).
local function GiveLoadout(ply, keep)
    local prof = Profile(ply)
    if not prof then return end
    if not keep then ply:StripWeapons() end
    for _, cls in ipairs(prof.loadout or {}) do
        if not (keep and ply:HasWeapon(cls)) then ply:Give(cls) end
    end
    if cvAdminTools:GetBool() and LC.IsBuilder(ply) then -- only in build mode
        ply:Give("weapon_physgun")
        ply:Give("gmod_tool")
    end
    if LC.GiveJobTools then LC.GiveJobTools(ply) end
    if keep then return end
    ply:GiveAmmo(90, "Pistol", true)
    ply:GiveAmmo(180, "SMG1", true)
    ply:GiveAmmo(24, "Buckshot", true)
    ply:GiveAmmo(60, "AR2", true)
    ply:GiveAmmo(12, "357", true)
    local first = prof.loadout and prof.loadout[1]
    if first then ply:SelectWeapon(first) end
    if LC.GiveHands then LC.GiveHands(ply, true) end -- start with your hands down; what you carry is a key away
end

-- The weapons a player's rank (or special role) carries.
function LC.RankLoadout(ply)
    local prof = Profile(ply)
    return prof and prof.loadout or {}
end

-- True if the faction hands you this weapon (so selling it would be free money).
function LC.IsIssuedWeapon(ply, cls)
    local prof = Profile(ply)
    for _, c in ipairs(prof and prof.loadout or {}) do if c == cls then return true end end
    return false
end

hook.Add("PlayerLoadout", "LivingCityFactions", function(ply)
    if not FactionOf(ply) then return end
    if LC.Prisoners and LC.Prisoners[ply] then return true end
    GiveLoadout(ply)
    return true
end)

hook.Add("PlayerSetModel", "LivingCityFactions", function(ply)
    if not FactionOf(ply) then return end
    local prof = Profile(ply)
    local models = prof and prof.models or {}
    if #models == 0 then return end
    ply:SetModel(PickModel(ply, models))
    return true
end)

hook.Add("PlayerSpawn", "LivingCityFactions", function(ply)
    if not FactionOf(ply) then return end
    local spawnedAt = ply:GetPos()
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        ApplyBody(ply)
        if LC.Prisoners and LC.Prisoners[ply] then return end
        -- hunted people spawn at resistance spawn points (or rebel territory), the
        -- infested at theirs (or in their nests); citizens never spawn on Combine ground
        local hunted, zombie = LC.PlayerIsHunted(ply), LC.PlayerIsZombie(ply)
        local kind = hunted and "rebel" or (zombie and "infest") or nil
        local pkind = hunted and "rspawn" or (zombie and "zspawn") or nil
        local pts = pkind and LC.PointsOfKind and LC.PointsOfKind(pkind) or {}
        if #pts > 0 then
            ply:SetPos(pts[math.random(#pts)].pos + Vector(0, 0, 4))
        elseif kind then
            local zones = LC.ZonesOfKind and LC.ZonesOfKind(kind) or {}
            if #zones > 0 then
                local spot = LC.SpotInZone(zones[math.random(#zones)])
                if spot then ply:SetPos(spot + Vector(0, 0, 4)) end
            end
        elseif LC.PlayerIsCP(ply) and not ply:GetNW2Bool("lc_build", false) then
            -- units (and the Overwatch) start at the Combine's own ground: the nexus, the station, wherever
            -- the editor's Combine zones are (the owner: not the train station); failing that, by the
            -- Civil Protection Commissary
            local here = ply:GetPos()
            -- (not if something else has already put them somewhere since they spawned)
            if here:DistToSqr(spawnedAt) < 4 and not (LC.CombineZoneAt and LC.CombineZoneAt(here)) then
                local zones = LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}
                local spot = #zones > 0 and LC.SpotInZone and LC.SpotInZone(zones[math.random(#zones)]) or nil
                if not spot then
                    local sup = LC.EntsOf and LC.EntsOf("lc_cpsupply") or {}
                    local e = sup[math.random(math.max(1, #sup))]
                    if IsValid(e) then spot = (LC.GroundAt and LC.GroundAt(e:GetPos() + e:GetForward() * 70 + Vector(0, 0, 30))) or e:GetPos() + e:GetForward() * 70 end
                end
                if spot then ply:SetPos(spot + Vector(0, 0, 4)) end
            end
        elseif not LC.PlayerIsCP(ply) and not ply:GetNW2Bool("lc_build", false) and LC.SafeCitizenSpot and LC.CitizenSpotOK then
            local here = ply:GetPos()
            if LC.OnCombineSurface(here) or LC.CombineZoneAt(here) then
                local spot = LC.SafeCitizenSpot()
                if spot then ply:SetPos(spot) end
            end
        end
    end)
end)

-- Never stuck inside someone: spawned (or put back where you left off) on top of an NPC or
-- another player, you're moved to the nearest clear spot beside them. Checked after every spawn,
-- and every second (two checks running stuck: moved), so nobody needs noclip to get free.
local function StuckIn(ply, pos)
    local tr = util.TraceHull({ start = pos, endpos = pos, mins = ply:OBBMins(), maxs = ply:OBBMaxs(), filter = ply, mask = MASK_PLAYERSOLID })
    if not tr then return nil end
    local e = tr.Entity
    if tr.StartSolid or tr.AllSolid then
        if IsValid(e) and (e:IsNPC() or e:IsPlayer() or e:GetClass() == "prop_physics") then return e end
        if not IsValid(e) and pos == ply:GetPos() then return game.GetWorld and game.GetWorld() or true end
    end
    return nil
end
function LC.UnstickFromPeople(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local pos = ply:GetPos()
    if not StuckIn(ply, pos) then return false end
    for _, r in ipairs({ 40, 64, 96, 140, 200 }) do
        for i = 0, 7 do
            local a = i / 8 * math.pi * 2
            local p = pos + Vector(math.cos(a) * r, math.sin(a) * r, 4)
            if not StuckIn(ply, p) then
                local wall = util.TraceLine({ start = pos + Vector(0, 0, 36), endpos = p + Vector(0, 0, 36), filter = ply, mask = MASK_PLAYERSOLID_BRUSHONLY })
                local down = util.TraceLine({ start = p, endpos = p - Vector(0, 0, 120), filter = ply, mask = MASK_PLAYERSOLID })
                if wall and not wall.Hit and down and down.Hit then
                    ply:SetPos(down.HitPos + Vector(0, 0, 2))
                    return true
                end
            end
        end
    end
    return false
end
hook.Add("PlayerSpawn", "LivingCityUnstick", function(ply)
    timer.Simple(0.6, function() if IsValid(ply) then LC.UnstickFromPeople(ply) end end)
end)
timer.Create("LivingCityUnstick", 1, 0, function()
    for _, p in ipairs(player.GetAll()) do
        local free = not p:Alive() or (p.GetMoveType and p:GetMoveType() == MOVETYPE_NOCLIP) or (p.InVehicle and p:InVehicle())
            or p:GetNW2Bool("lc_sleeping", false) or (LC.IsTied and LC.IsTied(p)) or (LC.InCustody and LC.InCustody(p))
            or (LC.IsDowned and LC.IsDowned(p)) or p.lcEndFrozen
        local e = not free and StuckIn(p, p:GetPos())
        if e and e ~= true and IsValid(e) and (e:IsNPC() or e:IsPlayer()) then
            p.lcStuckN = (p.lcStuckN or 0) + 1
            if p.lcStuckN >= 2 then p.lcStuckN = 0 LC.UnstickFromPeople(p) end
        else
            p.lcStuckN = 0
        end
    end
end)

hook.Add("LivingCityRestoreLoadout", "LivingCityFactions", function(ply)
    if not FactionOf(ply) then return end
    ApplyBody(ply) -- they may have changed faction while inside
    GiveLoadout(ply)
    return true
end)

------------------------------------------------------------------------
-- Joining
------------------------------------------------------------------------

local function SpecialHolders(fid, sid)
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_faction", "") == fid and p:GetNW2String("lcf_special", "") == sid then n = n + 1 end
    end
    return n
end

-- Returns ok, reason
LC.SideRatio, LC.SideSlack = 2, 4
-- A place on a side kept for someone who drops out (the owner, 9 November: "a grace period in case their computer reboots or their
-- power flickers and they are disconnected for 5-7 ish minutes"): back within LC.SideGrace seconds, they're back on their side
-- whatever the count; and for the first LC.SideGrace seconds after the map starts (a restart: everyone comes back at once).
LC.SideGrace = 7 * 60
LC.SideLeft = LC.SideLeft or {} -- [steamid64] = { side, t }
local SIDE_OF_F = { resistance = "rebels", cp = "combine", ota = "combine" }
hook.Add("PlayerDisconnected", "LivingCitySideGrace", function(ply)
    local side = IsValid(ply) and SIDE_OF_F[ply:GetNW2String("lcf_faction", "")]
    if side then LC.SideLeft[tostring(ply:SteamID64())] = { side = side, t = CurTime() } end
end)
-- The side someone's place is kept on, or nil.
function LC.SideGraceFor(ply)
    if not IsValid(ply) then return nil end
    local left = LC.SideLeft[tostring(ply:SteamID64())]
    if left and CurTime() - left.t <= LC.SideGrace then return left.side end
    if CurTime() <= LC.SideGrace and ply.GetPData then return SIDE_OF_F[ply:GetPData("lcf_faction", "")] end
    return nil
end
local SIDE_OF = { resistance = "rebels", cp = "combine", ota = "combine" }
-- Players on each side now, not counting ply: rebels (the Resistance), combine (Civil Protection and Overwatch).
function LC.SideCounts(ply)
    local n = { rebels = 0, combine = 0 }
    for _, p in ipairs(player.GetAll()) do
        local side = p ~= ply and SIDE_OF[p:GetNW2String("lcf_faction", "")]
        if side then n[side] = n[side] + 1 end
    end
    return n
end
-- May ply join this side, keeping the sides even? True, or false and why not. Already on that side: always.
function LC.SidesEven(ply, fid)
    local side = SIDE_OF[fid]
    if not side or SIDE_OF[ply:GetNW2String("lcf_faction", "")] == side then return true end
    if LC.SideGraceFor(ply) == side then return true end -- (back within a few minutes of dropping out: their place kept)
    local n = LC.SideCounts(ply)
    local other = side == "rebels" and "combine" or "rebels"
    local most = n[other] * LC.SideRatio + LC.SideSlack
    if n[side] + 1 <= most then return true end
    if side == "rebels" then
        return false, string.format("The Resistance is too big for the city's Combine right now (%d fighters, %d of Civil Protection and Overwatch). Wait for more units to come on, or for a place to free up.", n.rebels, n.combine)
    end
    return false, string.format("The Combine is too big for the Resistance right now (%d of Civil Protection and Overwatch, %d fighters). Wait for more rebels to come on, or for a place to free up.", n.combine, n.rebels)
end

function LC.CanJoinFaction(ply, fid, sid)
    local f = LCF.Get(fid)
    if not f then return false, "No such faction." end
    -- a mole who was caught: Resistance for good (sv_livingcity_insider.lua)
    if fid ~= "resistance" and LC.InsiderBarred then
        local why = LC.InsiderBarred(ply, "faction", fid)
        if why then return false, why end
    end
    -- (a stalker is bound even as a superadmin: only death, or lc_unstalker, ends it)
    local bound = LC.BoundTo and (not ply:IsSuperAdmin() or (LC.PlayerIsStalker and LC.PlayerIsStalker(ply))) and LC.BoundTo(ply, fid)
    if bound then return false, bound end -- (careers that can't be undone: sv_livingcity_progress.lua)
    if f.whitelist and not ply:IsSuperAdmin() and ply:GetPData("lcf_wl_" .. fid, "0") ~= "1" then
        return false, "Whitelist only."
    end
    if f.id == "cp" and LC.Standing and not ply:IsAdmin() then
        local need = cvCPStanding:GetInt()
        local have = LC.Standing(ply)
        if have < need then
            return false, string.format("Civil Protection only takes citizens in good standing (%d or more). Yours is %d.", need, have)
        end
        -- and who've come up the Civil Protection path: Intake Processor, or Infestation Cleanup (sv_livingcity_work.lua counts the shifts)
        local shifts = cvCPClerk:GetInt()
        local done = LC.Counter and LC.Counter(ply, "cp_shifts") or 0
        if shifts > 0 and done < shifts and ply:GetNW2String("lcf_faction", "") ~= "cp" then
            return false, string.format("Civil Protection recruits from the train station's Intake Processors and the infestation cleanup crews: finish %d Intake Processor shifts first, or half as many in Infestation Cleanup (F4 > Jobs). You've done %d.", shifts, done)
        end
    end
    -- the sides kept even (the owner, 9 November: "keep the sides even"): neither the Resistance nor the Combine (Civil Protection and
    -- Overwatch together) may grow past double the other side's players, plus 4. Only joining waits: nobody on a side is ever put off it.
    if (fid == "resistance" or fid == "cp" or fid == "ota") and not ply:IsSuperAdmin() then
        local okE, whyE = LC.SidesEven(ply, fid)
        if not okE then return false, whyE end
    end
    if fid == "resistance" and not ply:IsSuperAdmin() and not LC.ResistanceProven(ply) then
        if ply.GetPData and ply:GetPData("lc_scar", "0") == "1" then return false, "The Resistance will never take someone with a rat carved into their face." end -- (sv_livingcity_snitches.lua)
        return false, "The Resistance doesn't trust you yet." -- (the owner: just that; they find out how in roleplay)
    end
    if f.requires then
        local rf = LCF.Get(f.requires.faction)
        if rf and RankFor(ply, rf) < f.requires.rank and not ply:IsSuperAdmin() then
            return false, string.format("Requires %s in %s.", rf.ranks[f.requires.rank].name, rf.name)
        end
    end
    if sid then
        local s = f.specialsById[sid]
        if not s then return false, "No such role." end
        local mine = ply:GetNW2String("lcf_faction", "") == fid and ply:GetNW2String("lcf_special", "") == sid
        if not mine and SpecialHolders(fid, sid) >= (s.max or 1) then return false, "Someone already holds that role." end
        -- (the owner, 7 November: a recruit became Overwatch Commander; the rank is needed, superadmin or not,
        -- and an Overwatch role needs the conditioning like any Overwatch rank)
        if RankFor(ply, f) < (s.minRank or 1) then
            return false, "Requires " .. f.ranks[s.minRank].name .. " in " .. f.name .. "."
        end
        if s.overwatch and not Conditioned(ply) then
            return false, "Overwatch roles need the transhuman conditioning first (the Overwatch Candidate story)."
        end
    end
    return true
end

-- stay: switching by choice from the faction menu, you stay where you are (a new
-- character, a slot or an admin's say-so still starts you at a spawn point).
function LC.SetFaction(ply, fid, sid, quiet, stay)
    if fid == "ota" then -- (Overwatch was its own faction once: now it's Civil Protection's top ranks)
        fid = "cp"
        ply:SetPData("lcf_transhuman", "1")
        local pg = LCF.Get("cp").ranks[4].xp
        if XP(ply, "cp") < pg then ply:SetPData("lcf_xp_cp", pg) end
    end
    ply:SetNW2String("lcf_faction", fid)
    ply:SetNW2String("lcf_special", sid or "")
    ply:SetPData("lcf_faction", fid)
    ply:SetPData("lcf_special", sid or "")
    if fid == "resistance" then ply:SetPData("lcf_res_proven", "1") end -- (once in, proven: free to come back after leaving)
    RecomputeRank(ply)
    if not quiet then
        local f = LCF.Get(fid)
        local s = sid and f.specialsById[sid]
        Tell(ply, "You are now " .. (s and s.name or (f.name .. ", " .. RankOf(ply).name)) .. ".")
    end
    if ply:Alive() and not (LC.Prisoners and LC.Prisoners[ply]) then
        local pos, ang = ply:GetPos(), ply:EyeAngles()
        ply:Spawn()
        if stay and LCF.Get(fid).zombie then stay = nil end -- (the infested rise in their nests, not where a person stood)
        if stay then
            -- (the new uniform and kit, right where you were standing; set again a moment
            -- later in case anything spawning moves you)
            local function Back()
                if not IsValid(ply) or not ply:Alive() then return end
                ply:SetPos(pos)
                if ply.SetEyeAngles then ply:SetEyeAngles(Angle(ang.p, ang.y, 0)) end
            end
            Back()
            timer.Simple(0, Back)
            timer.Simple(0.3, Back) -- (after the spawn hooks that place people: rebels at their spawns, citizens off Combine ground)
        end
    end
    if LC.RefreshRelations then LC.RefreshRelations() end
    hook.Run("LivingCityFactionChanged", ply, fid, sid) -- (sv_livingcity_reconcile.lua: the old faction's job, looks and kit go)
end

net.Receive("lcf_join", function(_, ply)
    local fid = net.ReadString()
    local sid = net.ReadString()
    if sid == "" then sid = nil end
    if LC.Prisoners and LC.Prisoners[ply] then return Tell(ply, "Not while you're in custody.") end
    if LC.PlayerIsWanted(ply) or (LC.InCombat and LC.InCombat(ply)) then return Tell(ply, "Not while you're wanted or in a fight.") end
    if (ply.lcfNextSwitch or 0) > CurTime() and not ply:IsAdmin() then
        return Tell(ply, "You can change faction again in " .. math.ceil(ply.lcfNextSwitch - CurTime()) .. " seconds.")
    end
    local ok, why = LC.CanJoinFaction(ply, fid, sid)
    if not ok then return Tell(ply, why) end
    ply.lcfNextSwitch = CurTime() + cvCooldown:GetFloat()
    LC.SetFaction(ply, fid, sid, nil, true)
end)

local function SendMenu(ply)
    local data = { current = ply:GetNW2String("lcf_faction", ""), special = ply:GetNW2String("lcf_special", ""), factions = {},
        admin = ply:IsAdmin() or nil }
    for _, f in ipairs(LCF.Factions) do
      -- (the owner: a stalker is a punishment, never a choice: not on the screen, unless it's what you are)
      if not f.stalker or data.current == f.id then
        local xp = XP(ply, f.id)
        local ok, why = LC.CanJoinFaction(ply, f.id, nil)
        local entry = { id = f.id, xp = xp, rank = RankFor(ply, f, xp), ok = ok, why = why, specials = {} }
        -- what Civil Protection asks of a citizen, as progress bars on the card (the owner asked)
        if f.id == "cp" and ply:GetNW2String("lcf_faction", "") ~= "cp" then
            entry.reqs = {
                { label = "Civil Standing", have = LC.Standing and LC.Standing(ply) or 0, need = cvCPStanding:GetInt() },
                { label = "Intake Processor shifts finished (F4 > Jobs; Infestation Cleanup counts double)", have = LC.Counter and LC.Counter(ply, "cp_shifts") or 0, need = cvCPClerk:GetInt() },
            }
        end
        if f.id == "resistance" then
            local have, need = LC.ResistanceTrust(ply)
            if need > 0 and have < need then
                entry.reqs = { { label = "Jobs done for the Resistance, to be trusted as a Fighter (their board, F4)", have = have, need = need } }
            end
        end
        for _, s in ipairs(f.specials or {}) do
            local sok, swhy = LC.CanJoinFaction(ply, f.id, s.id)
            entry.specials[#entry.specials + 1] = { id = s.id, ok = sok, why = swhy, taken = SpecialHolders(f.id, s.id) }
        end
        data.factions[#data.factions + 1] = entry
      end
    end
    LC.SendCompressed("lcf_menu", data, { ply })
end

-- F4: one window with tabs, Jobs, Career and Factions (cl_livingcity_hub.lua). (The owner, 7 November:
-- "consolidate F3 and F4".) lc_hub opens it on the tab last looked at; then every tab's content.
function LC.OpenHub(ply)
    if not IsValid(ply) then return end
    net.Start("lc_hub")
    net.Send(ply)
    if LC.SendBoard then LC.SendBoard(ply) end
    SendMenu(ply)
    if LC.SendCareer then LC.SendCareer(ply) end
end
hook.Add("ShowSpare2", "LivingCityFactions", function(ply) LC.OpenHub(ply) end)
concommand.Add("lcf_menu", function(ply) if IsValid(ply) then SendMenu(ply) end end)
hook.Add("PlayerSay", "LivingCityFactionsChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!faction" or t == "!factions" then SendMenu(ply) return "" end
end)

-- Who this person was last time, if they may still be: their faction, and
-- their special role (Hacker, Father Grigori...) if there's still a place for
-- them in it. Nobody holds a place by being offline: if the places filled up
-- while they were away, they're back to their rank (and can take it again
-- from the faction menu when one opens).
-- Returns faction, special (or nil), and if a special was lost: why, and which.
function LC.SavedFaction(ply)
    local fid = ply:GetPData("lcf_faction", "citizen")
    local sid = ply:GetPData("lcf_special", "")
    local f = LCF.Get(fid)
    if not f then return "citizen", nil end
    if sid == "" or not (f.specialsById and f.specialsById[sid]) then sid = nil end
    local lostWhy, lost
    if sid then
        local ok, why = LC.CanJoinFaction(ply, fid, sid)
        if ok then return fid, sid end
        lostWhy, lost = why, sid
    end
    if LC.CanJoinFaction(ply, fid, nil) then return fid, nil, lostWhy, lost end
    return "citizen", nil, lostWhy, lost
end

hook.Add("PlayerInitialSpawn", "LivingCityFactions", function(ply)
    local fid, sid = LC.SavedFaction(ply)
    ply:SetNW2String("lcf_faction", fid)
    ply:SetNW2String("lcf_special", sid or "")
    RecomputeRank(ply)
    -- Admin and superadmin (which can open a role or a whitelisted faction)
    -- often arrive a moment after joining, from the server's admin mod: look
    -- again then, and say what became of a special role.
    local f0, s0 = fid, sid or ""
    timer.Simple(2.5, function()
        if not IsValid(ply) then return end
        -- (changed since they joined, by them or an admin: leave it be)
        if ply:GetNW2String("lcf_faction", "") ~= f0 or ply:GetNW2String("lcf_special", "") ~= s0 then return end
        local f2, s2, why, lost = LC.SavedFaction(ply)
        local inCustody = LC.Prisoners and LC.Prisoners[ply]
        -- only ever to give back what they had (never to take more away)
        if not inCustody and (f2 ~= f0 or (s2 or "") ~= s0) and f2 == ply:GetPData("lcf_faction", "citizen") then
            LC.SetFaction(ply, f2, s2, true)
        else
            f2, s2 = f0, s0 ~= "" and s0 or nil
        end
        local f = LCF.Get(f2)
        local was = ply:GetPData("lcf_faction", "citizen")
        if f2 ~= was and (was == "resistance" or was == "cp" or was == "ota") and LC.SidesEven then
            local okS, whyS = LC.SidesEven(ply, was)
            if not okS then Tell(ply, whyS .. " You're a citizen for now; join again from the faction menu (F4) when there's room. Your rank and experience are kept.") end
        end
        if s2 and f and f.specialsById[s2] then
            Tell(ply, "Welcome back. You're still " .. f.specialsById[s2].name .. ".")
        elseif lost then
            local lf = LCF.Get(ply:GetPData("lcf_faction", "citizen"))
            local ls = lf and lf.specialsById and lf.specialsById[lost]
            local r = RankOf(ply)
            Tell(ply, string.format("You can't be %s right now: %s You're %s for now; take it again from the faction menu (F4) when there's a place.",
                ls and ls.name or lost, string.lower(string.sub(why or "", 1, 1)) .. string.sub(why or "", 2),
                f and r and (f.name .. " " .. r.name) or "back to your rank"))
        end
    end)
end)

------------------------------------------------------------------------
-- XP
------------------------------------------------------------------------

-- The transhuman conditioning: the Overwatch ranks open, and whatever XP
-- you've earned counts at once. There's no undoing it.
function LC.Condition(ply)
    if not IsValid(ply) then return false end
    ply:SetPData("lcf_transhuman", "1")
    ply:SetNW2Bool("lcf_transhuman", true)
    if ply:GetNW2String("lcf_faction", "") == "cp" then LC.AddXP(ply, 0, "the conditioning") end
    return true
end

hook.Add("LivingCityNewCharacter", "LivingCityFactions", function(ply)
    ply:RemovePData("lcf_transhuman")
    ply:SetNW2Bool("lcf_transhuman", false)
end)

function LC.AddXP(ply, amount, why)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (tonumber(amount) or 0) > 0 and LC.SurvivalXPMul then amount = math.floor(amount * LC.SurvivalXPMul(ply) + 0.5) end -- (Realistic survival: sv_livingcity_survivalmode.lua)
    local f = FactionOf(ply)
    if not f or #f.ranks < 2 then return end
    local xp = math.max(0, XP(ply, f.id) + amount)
    ply:SetPData("lcf_xp_" .. f.id, xp)
    local changed, up = RecomputeRank(ply)
    if changed then
        local r = RankOf(ply)
        if up then
            Tell(ply, "Promoted to " .. r.name .. "!" .. (why and (" (" .. why .. ")") or ""))
            hook.Run("LivingCityPromoted", ply, f.id, ply:GetNW2Int("lcf_rank", 1), r)
            ply:EmitSound("buttons/bell1.wav", 60)
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply and p:GetNW2String("lcf_faction", "") == f.id then
                    p:ChatPrint(string.format("[%s] %s has been promoted to %s.", f.name, ply:Nick(), r.name))
                end
            end
        else
            Tell(ply, "Demoted to " .. r.name .. ".")
        end
        if ply:Alive() and not SpecialOf(ply) and not (LC.Prisoners and LC.Prisoners[ply]) then
            ApplyBody(ply)
            GiveLoadout(ply, true)
        end
        hook.Run("LivingCityRankChanged", ply, f.id, ply:GetNW2Int("lcf_rank", 1)) -- (sv_livingcity_reconcile.lua: what the new rank may wear and hold)
    end
end

-- Duty time, only while actually playing
timer.Create("LivingCityFactionsDuty", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local ang = ply:EyeAngles()
        local moved = not ply.lcfLastAng or math.abs(math.AngleDifference(ang.y, ply.lcfLastAng.y)) > 2
            or math.abs(math.AngleDifference(ang.p, ply.lcfLastAng.p)) > 2
        ply.lcfLastAng = ang
        if moved and ply:Alive() then LC.AddXP(ply, LCF.XP.duty_per_minute) end
    end
end)

hook.Add("LivingCityIncarcerated", "LivingCityFactionsXP", function(target, seconds, reason, arrester)
    if not IsValid(arrester) or not arrester:IsPlayer() or not LC.PlayerIsCP(arrester) then return end
    LC.AddXP(arrester, target:IsPlayer() and LCF.XP.arrest_player or LCF.XP.arrest_npc, "arrest")
end)

hook.Add("LivingCityStrike", "LivingCityFactionsXP", function(ply)
    LC.AddXP(ply, -LCF.XP.strike_penalty)
end)

hook.Add("PlayerDeath", "LivingCityFactionsXP", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    if LC.PlayerIsZombie(attacker) and not LC.PlayerIsZombie(victim) then LC.AddXP(attacker, LCF.XP.infect, "infection") end
end)

-- A rebel put down by a Civil Protection or Overwatch player (the owner, 7 November): standing, two
-- credits, and an ammunition allocation (a box of rounds for the gun in hand), so sweeping in on them
-- is worth the danger. (The XP for it: sv_livingcity_rebels.lua.)
local AMMO_BOX = { weapon_pistol = "ammo_pistol", weapon_smg1 = "ammo_smg", weapon_shotgun = "ammo_buckshot", weapon_357 = "ammo_357" }
LCF.XP.rebel_kill_ar2 = 30 -- (no AR2 ammo item: a magazine of AR2 rounds straight in, the owner, 7 November)
LCF.XP.rebel_kill_standing, LCF.XP.rebel_kill_credits = 5, 2
local function RebelKillReward(unit)
    if not IsValid(unit) or not unit:IsPlayer() or not LC.PlayerIsCP(unit) then return end
    if LC.AddStanding then LC.AddStanding(unit, LCF.XP.rebel_kill_standing, "anticitizen neutralized") end
    if LC.AddCredits then LC.AddCredits(unit, LCF.XP.rebel_kill_credits, "anticitizen neutralized") end
    local w = unit.GetActiveWeapon and unit:GetActiveWeapon()
    local box = (IsValid(w) and AMMO_BOX[w:GetClass()]) or "ammo_pistol"
    local got
    if IsValid(w) and w:GetClass() == "weapon_ar2" then
        unit:GiveAmmo(LCF.XP.rebel_kill_ar2, "AR2", true)
        got = LCF.XP.rebel_kill_ar2 .. " AR2 rounds"
    elseif LCS and LCS.Items and LCS.Items[box] and LC.GiveItem and LC.GiveItem(unit, box, 1) then
        got = string.lower(LCS.Items[box].name)
    elseif IsValid(w) and w.GetPrimaryAmmoType and (w:GetPrimaryAmmoType() or -1) >= 0 then
        unit:GiveAmmo(12, w:GetPrimaryAmmoType(), true) -- (pockets full: the rounds go straight in)
        got = "twelve rounds"
    end
    if LC.Notice then
        LC.Notice(unit, "info", "Anticitizen neutralized", string.format("+%d standing, +%d credits%s.", LCF.XP.rebel_kill_standing, LCF.XP.rebel_kill_credits,
            got and (", and an ammunition allocation: " .. got) or ""), 6)
    end
end
LC.RebelKillReward = RebelKillReward
hook.Add("OnNPCKilled", "LivingCityRebelKillReward", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.role == "rebel" and not st.test then RebelKillReward(attacker) end
end)
-- (the side they died on, noted first: permanent death may make them a new citizen before this runs)
hook.Add("DoPlayerDeath", "LivingCityRebelKillReward", function(victim)
    if IsValid(victim) and victim.GetNW2String then victim.lcDiedAs = victim:GetNW2String("lcf_faction", "") end
end)
hook.Add("PlayerDeath", "LivingCityRebelKillReward", function(victim, inflictor, attacker)
    local diedAs = IsValid(victim) and (victim.lcDiedAs or victim:GetNW2String("lcf_faction", "")) or ""
    if IsValid(victim) then victim.lcDiedAs = nil end
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim or not IsValid(victim) then return end
    if diedAs == "resistance" then
        RebelKillReward(attacker)
        -- (the XP, as for an NPC rebel in sv_livingcity_rebels.lua: the owner, 8 November, "5 xp per kill")
        if LC.PlayerIsCP(attacker) and not victim.lcDreaming then LC.AddXP(attacker, LCF.XP.rebel_kill or 5, "anticitizen neutralized") end
    end
end)

hook.Add("OnNPCKilled", "LivingCityInfection", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" then return end
    local byZombie = (IsValid(attacker) and attacker:IsPlayer() and LC.PlayerIsZombie(attacker))
        or (IsValid(attacker) and LC.NPCs[attacker] and LC.NPCs[attacker].role == "zombie")
    if not byZombie then return end
    if IsValid(attacker) and attacker:IsPlayer() then LC.AddXP(attacker, LCF.XP.infect_npc) end
    -- the dead don't stay dead
    local pos = npc:GetPos()
    timer.Simple(4, function()
        if not LC.Running or not LC.SpawnZombie then return end
        local count = 0
        for _, s in pairs(LC.NPCs) do if s.role == "zombie" then count = count + 1 end end
        local cap = (GetConVar("lc_zombies"):GetInt() + 2) * 2
        if count < cap and LC.ClearSpot(pos) then
            if LC.TakeBodyAt then LC.TakeBodyAt(pos) end -- the body is what gets up
            local z, zst = LC.SpawnZombie(pos + Vector(0, 0, 4), nil, "npc_zombie")
            if zst then zst.unmanaged = true end
        end
    end)
end)

------------------------------------------------------------------------
-- What Living City needs to know
------------------------------------------------------------------------

function LC.PlayerIsHunted(ply)
    local prof = Profile(ply)
    return prof ~= nil and prof.hunted == true
end

hook.Add("LivingCityIsCP", "LivingCityFactions", function(ply)
    local f = FactionOf(ply)
    if f then return f.cp == true end
end)

hook.Add("LivingCityIsZombie", "LivingCityFactions", function(ply)
    local f = FactionOf(ply)
    if f then return f.zombie == true end
end)

-- The infested have claws, not guns: they can't pick one up, and anything else they're
-- holding when they turn is dropped from their hands.
local ZOMBIE_HANDS = { weapon_lc_claws = true, weapon_lc_hands = true }
hook.Add("PlayerCanPickupWeapon", "LivingCityInfested", function(ply, wep)
    if LC.PlayerIsZombie(ply) and IsValid(wep) and not ZOMBIE_HANDS[wep:GetClass()] then return false end
end)
function LC.ZombieDisarm(ply)
    if not IsValid(ply) or not LC.PlayerIsZombie(ply) then return 0 end
    local n = 0
    for _, w in ipairs(ply:GetWeapons()) do
        if w and w.GetClass and not ZOMBIE_HANDS[w:GetClass()] then ply:StripWeapon(w:GetClass()) n = n + 1 end
    end
    if n > 0 and ply:HasWeapon("weapon_lc_claws") then ply:SelectWeapon("weapon_lc_claws") end
    return n
end
hook.Add("PlayerSpawn", "LivingCityInfested", function(ply)
    timer.Simple(0.2, function() LC.ZombieDisarm(ply) end)
end)
timer.Create("LivingCityInfested", 2, 0, function()
    for _, p in ipairs(player.GetAll()) do if p:Alive() then LC.ZombieDisarm(p) end end
end)

-- Hunted people are anticitizens on sight, anywhere outside rebel territory.
hook.Add("LivingCityIsWanted", "LivingCityFactions", function(ply)
    if LC.DisguisedAsRebel and LC.DisguisedAsRebel(ply) and not LC.PlayerIsCP(ply)
        and not (LC.InRebelZone and LC.InRebelZone(ply:GetPos())) then
        return true -- dressed as a fighter, treated as one
    end
    if LC.PlayerIsHunted(ply) and not (LC.InRebelZone and LC.InRebelZone(ply:GetPos()))
        and not (LC.PassesAsCitizen and LC.PassesAsCitizen(ply)) then -- citizen clothes: nobody looks twice
        return true
    end
end)

------------------------------------------------------------------------
-- Admin commands
------------------------------------------------------------------------

local function AdminCmd(name, fn)
    concommand.Add(name, function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local target = LC.FindPlayer(args[1])
        local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
        if not target then return out("Player not found.") end
        fn(target, args, out)
    end)
end

AdminCmd("lcf_setfaction", function(target, args, out)
    local f = LCF.Get(args[2] or "")
    if not f then return out("Factions: citizen, resistance, cp, ota, admin, zombie") end
    local sid = args[3]
    if sid and not f.specialsById[sid] then return out("No such special role.") end
    LC.SetFaction(target, f.id, sid)
    out(target:Nick() .. " set to " .. f.name .. ".")
end)

AdminCmd("lcf_setxp", function(target, args, out)
    local f = FactionOf(target)
    local xp = tonumber(args[2])
    if not f or not xp then return out("Usage: lcf_setxp <name> <xp>") end
    target:SetPData("lcf_xp_" .. f.id, math.max(0, xp))
    LC.AddXP(target, 0)
    out(target:Nick() .. " now has " .. xp .. " XP in " .. f.name .. ".")
end)

local function Step(target, dir, out)
    local f = FactionOf(target)
    if not f then return end
    local idx = math.Clamp(target:GetNW2Int("lcf_rank", 1) + dir, 1, #f.ranks)
    if f.ranks[idx].overwatch then target:SetPData("lcf_transhuman", "1") end -- (staff can skip the story)
    target:SetPData("lcf_xp_" .. f.id, f.ranks[idx].xp or 0)
    LC.AddXP(target, 0, "by staff")
    out(target:Nick() .. " is now " .. f.ranks[idx].name .. ".")
end
AdminCmd("lcf_promote", function(t, _, out) Step(t, 1, out) end)
AdminCmd("lcf_demote", function(t, _, out) Step(t, -1, out) end)

AdminCmd("lcf_whitelist", function(target, args, out)
    local f = LCF.Get(args[2] or "")
    if not f then return out("Usage: lcf_whitelist <name> <faction>") end
    local key = "lcf_wl_" .. f.id
    local on = target:GetPData(key, "0") ~= "1"
    target:SetPData(key, on and "1" or "0")
    out(target:Nick() .. (on and " whitelisted for " or " removed from ") .. f.name .. ".")
end)

-- A job done for the Resistance builds their trust; the last one needed makes a Fighter of a member with the XP.
hook.Add("LivingCityQuestComplete", "LivingCityResistanceTrust", function(p, q)
    if not IsValid(p) or not q or q.chain == "shift" or p:GetNW2String("lcf_faction", "") ~= "resistance" then return end
    local before = LC.ResistanceTrust(p)
    if LC.Bump then LC.Bump(p, "res_jobs") end
    local have, need = LC.ResistanceTrust(p)
    if before < need and have >= need then
        p:ChatPrint("[Resistance] You've proved yourself. They trust you now.")
        LC.AddXP(p, 0, "trusted by the Resistance") -- (the rank it earns, now it's trusted)
    elseif have < need then
        p:ChatPrint(string.format("[Resistance] They're starting to trust you: %d of %d jobs before they'd arm you as a Fighter.", have, need))
    end
end)

-- A metrocop's own hands in first person (the owner, 1 November: they had the Overwatch soldier's sleeves,
-- Garry's Mod's own for the police model, which has no metrocop arms of its own, and there's no pack for it).
-- "own" (the default): the unit's own body is the hands model, everything but the arms and hands shrunk away
-- in their own game (cl_livingcity_suit.lua), so it's their own sleeves and gloves. A model path instead: a
-- workshop pack's hands. Empty: Garry's Mod's own. The Overwatch keep Garry's Mod's, which are theirs.
local cvHands = CreateConVar("lc_cp_hands", "own", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "First-person hands for Civil Protection units: own (their own body's arms), a hands model path, or empty (Garry's Mod's)")
hook.Add("PlayerSetHandsModel", "LivingCityCPHands", function(ply, ent)
    local m = cvHands:GetString()
    if m == "" or not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "cp" then return end
    if LCF.IsOverwatch and LCF.IsOverwatch(ply) then return end
    if m == "own" then
        m = ply:GetModel()
        ent:SetModel(m)
        ent:SetSkin(ply:GetSkin() or 0)
        ent:SetNW2Bool("lc_own_hands", true)
        return true
    end
    if util.IsValidModel and not util.IsValidModel(m) then return end
    ent:SetModel(m)
    ent:SetSkin(0)
    ent:SetBodyGroups("0000000")
    return true
end)

-- Team chat (the owner, 9 November: "a U chat that is team only", as in TF2 or Counter-Strike).
-- U (the game's own team chat key, messagemode2) reaches only your own side: Civil Protection,
-- Overwatch and the Administrator together; the Resistance and free vortigaunts together; citizens;
-- the infested; stalkers on their own. Ordinary chat (Y) is untouched.
function LC.TeamChatSide(ply)
    if not IsValid(ply) then return nil end
    if ply:GetNW2String("lcf_faction", "") == "stalker" then return "stalker" end
    return LC.SideOf and LC.SideOf(ply) or ply:GetNW2String("lcf_faction", "citizen")
end
hook.Add("PlayerCanSeePlayersChat", "LivingCityTeamChat", function(text, teamOnly, listener, speaker)
    if not teamOnly or not IsValid(speaker) or not IsValid(listener) then return end
    return LC.TeamChatSide(listener) == LC.TeamChatSide(speaker)
end)
