--[[
    City Factions (server)

      - Everyone starts as a Citizen. F4, !faction or lcf_menu opens the faction menu.
      - XP is kept separately per faction and saved by SteamID. Ranks are earned
        automatically as XP crosses each threshold (sh_livingcity_factions.lua).
      - Overwatch requires reaching Unit 01 in Civil Protection. City Administrator
        is whitelist only. Father Grigori is one player at a time.
      - Each rank sets model, loadout, health, armor and speed.
      - Living City treats CP / Overwatch / Administrator as Civil Protection,
        Infested as zombies, and hunted ranks as anticitizens outside rebel zones.

    Admin: lcf_setfaction <name> <faction> [special], lcf_setxp <name> <xp>,
           lcf_promote <name>, lcf_demote <name>, lcf_whitelist <name> <faction>
]]

if CLIENT then return end

util.AddNetworkString("lcf_menu")
util.AddNetworkString("lcf_join")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAdminTools = CreateConVar("lcf_admin_tools", "1", FLAGS, "Admins keep the physgun and toolgun in every faction")
local cvCooldown   = CreateConVar("lcf_switch_cooldown", "60", FLAGS, "Seconds between faction changes")
local cvCPStanding = CreateConVar("lc_cp_min_standing", "100", FLAGS, "Civil Standing needed to join Civil Protection")

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
    elseif f.id == "cp" then
        true_ = string.format("CP %s-%d", r.short, unit)
        public = true_
    elseif f.id == "ota" then
        true_ = string.format("%s %d", r.short, unit)
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

local function RecomputeRank(ply)
    local f = FactionOf(ply)
    if not f then return false end
    local old = ply:GetNW2Int("lcf_rank", 1)
    local new = LCF.RankIndexFor(f, XP(ply, f.id))
    ply:SetNW2Int("lcf_rank", new)
    Publish(ply)
    return new ~= old, new > old
end

------------------------------------------------------------------------
-- Applying a faction to a body
------------------------------------------------------------------------

-- The model for this rank: the one the player chose, if the rank has it (or its
-- counterpart, such as the same face in the Resistance's clothes); else by unit number.
local function PickModel(ply, models)
    if LC.ModelOverride then -- (a stalker's body: sv_livingcity_custody.lua)
        local m = LC.ModelOverride(ply)
        if m then return m end
    end
    local chosen = ply:GetNW2String("lc_model", "")
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
        elseif not LC.PlayerIsCP(ply) and not ply:GetNW2Bool("lc_build", false) and LC.SafeCitizenSpot and LC.CitizenSpotOK then
            local here = ply:GetPos()
            if LC.OnCombineSurface(here) or LC.CombineZoneAt(here) then
                local spot = LC.SafeCitizenSpot()
                if spot then ply:SetPos(spot) end
            end
        end
    end)
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
function LC.CanJoinFaction(ply, fid, sid)
    local f = LCF.Get(fid)
    if not f then return false, "No such faction." end
    if f.whitelist and not ply:IsSuperAdmin() and ply:GetPData("lcf_wl_" .. fid, "0") ~= "1" then
        return false, "Whitelist only."
    end
    if f.id == "cp" and LC.Standing and not ply:IsAdmin() then
        local need = cvCPStanding:GetInt()
        local have = LC.Standing(ply)
        if have < need then
            return false, string.format("Civil Protection only takes citizens in good standing (%d or more). Yours is %d.", need, have)
        end
    end
    if f.requires then
        local rf = LCF.Get(f.requires.faction)
        if rf and LCF.RankIndexFor(rf, XP(ply, rf.id)) < f.requires.rank and not ply:IsSuperAdmin() then
            return false, string.format("Requires %s in %s.", rf.ranks[f.requires.rank].name, rf.name)
        end
    end
    if sid then
        local s = f.specialsById[sid]
        if not s then return false, "No such role." end
        local mine = ply:GetNW2String("lcf_faction", "") == fid and ply:GetNW2String("lcf_special", "") == sid
        if not mine and SpecialHolders(fid, sid) >= (s.max or 1) then return false, "Someone already holds that role." end
        if LCF.RankIndexFor(f, XP(ply, fid)) < (s.minRank or 1) and not ply:IsSuperAdmin() then
            return false, "Requires " .. f.ranks[s.minRank].name .. " in " .. f.name .. "."
        end
    end
    return true
end

function LC.SetFaction(ply, fid, sid, quiet)
    ply:SetNW2String("lcf_faction", fid)
    ply:SetNW2String("lcf_special", sid or "")
    ply:SetPData("lcf_faction", fid)
    ply:SetPData("lcf_special", sid or "")
    RecomputeRank(ply)
    if not quiet then
        local f = LCF.Get(fid)
        local s = sid and f.specialsById[sid]
        Tell(ply, "You are now " .. (s and s.name or (f.name .. ", " .. RankOf(ply).name)) .. ".")
    end
    if ply:Alive() and not (LC.Prisoners and LC.Prisoners[ply]) then ply:Spawn() end
    if LC.RefreshRelations then LC.RefreshRelations() end
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
    LC.SetFaction(ply, fid, sid)
end)

local function SendMenu(ply)
    local data = { current = ply:GetNW2String("lcf_faction", ""), special = ply:GetNW2String("lcf_special", ""), factions = {},
        admin = ply:IsAdmin() or nil }
    for _, f in ipairs(LCF.Factions) do
        local xp = XP(ply, f.id)
        local ok, why = LC.CanJoinFaction(ply, f.id, nil)
        local entry = { id = f.id, xp = xp, rank = LCF.RankIndexFor(f, xp), ok = ok, why = why, specials = {} }
        for _, s in ipairs(f.specials or {}) do
            local sok, swhy = LC.CanJoinFaction(ply, f.id, s.id)
            entry.specials[#entry.specials + 1] = { id = s.id, ok = sok, why = swhy, taken = SpecialHolders(f.id, s.id) }
        end
        data.factions[#data.factions + 1] = entry
    end
    LC.SendCompressed("lcf_menu", data, { ply })
end

hook.Add("ShowSpare2", "LivingCityFactions", function(ply) SendMenu(ply) end)
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

function LC.AddXP(ply, amount, why)
    if not IsValid(ply) or not ply:IsPlayer() then return end
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
