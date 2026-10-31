--[[
    Living City: prison

    Mark cells and a release point with the editor (and optionally paint a
    prison zone around the cell block). Then:

      - Security NPCs arrest instead of kill: a stunstick hit, or a hit that
        would take you under 20 health, sends you to a free cell. On a map
        with no cells, you're detained on the street instead: cuffed and made
        to kneel for a while, searched, fined, and let go with a warning.
      - CP players arrest with the Arrest Baton (right click a player or citizen).
      - Prisoners lose their weapons, can't spawn things or noclip, and get them
        back on release at the release point.
      - Leaving the prison zone (or straying far from your cell if there is no
        zone) is an escape: you become wanted and nearby security comes for you.
      - Dying in prison puts you back in your cell. Disconnecting keeps your
        sentence for when you come back, even after a server restart.
      - Inspections sometimes end with an NPC citizen marched to a cell.

    Hooks: LivingCityIncarcerated(ply, seconds, reason, arrester),
           LivingCityReleased(ply), LivingCityEscaped(ply)
]]

if CLIENT then return end

LC = LC or {}
LC.Prisoners = LC.Prisoners or {} -- [ply] = { untilT, cell, reason, weapons }

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvTime    = CreateConVar("lc_prison_time", "180", FLAGS, "Default sentence in seconds")
local cvArrests = CreateConVar("lc_npc_arrests", "1", FLAGS, "Security NPCs arrest players instead of killing them when a cell is free")
local cvEscape  = CreateConVar("lc_escape_wanted", "300", FLAGS, "Seconds an escaped prisoner stays wanted")
local cvBuffer  = CreateConVar("lc_prison_buffer", "150", FLAGS, "Extra distance (Civil Protection units, about 16 per foot) beyond the prison area before leaving counts as escaping")
local cvRejoin  = CreateConVar("lc_rejoin_penalty", "120", FLAGS, "Extra seconds added when someone disconnects mid-sentence and comes back")
local cvStreet  = CreateConVar("lc_street_detention", "20", FLAGS, "Seconds you're held on the street when there are no prison cells")
local cvFine    = CreateConVar("lc_street_fine", "25", FLAGS, "Credits fined on a street detention")

local function Say(ply, msg)
    if IsValid(ply) then ply:ChatPrint("[Living City] " .. msg) else print("[Living City] " .. msg) end
end

local function NotifyCP(msg)
    for _, ply in ipairs(player.GetAll()) do
        if LC.PlayerIsCP(ply) then ply:ChatPrint("[Dispatch] " .. msg) end
    end
end

-- In a cell, or cuffed on the street.
function LC.InCustody(ply)
    return (LC.Prisoners and LC.Prisoners[ply] ~= nil) or (LC.Detained and LC.Detained[ply] ~= nil)
        or (LC.Marching and LC.Marching[ply] ~= nil) -- (being walked to the cells: sv_livingcity_march.lua)
end

function LC.PrisonAvailable()
    return LC.CountPointsOfKind("cell") > 0
end

local function FreeCell(who)
    local free = LC.FreePoints({ cell = true }, who)
    -- the cell they were walked to (sv_livingcity_march.lua), if it's still free
    local want = IsValid(who) and who.lcPreferCell
    if want then
        who.lcPreferCell = nil
        for _, c in ipairs(free) do if c == want then return c end end
    end
    return #free > 0 and LC.Pick(free) or nil
end
LC.FreeCell = FreeCell

local function PutInCell(ply, cell)
    if ply:InVehicle() then ply:ExitVehicle() end
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetPos(cell.pos + Vector(0, 0, 4))
    ply:SetEyeAngles(Angle(0, cell.yaw or 0, 0))
    ply:SetLocalVelocity(Vector(0, 0, 0))
    ply:StripWeapons()
    -- everyone has their fists, even in a cell
    ply:Give("weapon_fists")
    if LC.GiveHands then LC.GiveHands(ply, true) else ply:SelectWeapon("weapon_fists") end
end

------------------------------------------------------------------------
-- Players
------------------------------------------------------------------------

function LC.Incarcerate(ply, seconds, reason, arrester)
    if not IsValid(ply) or not ply:IsPlayer() then return false, "not a player" end
    seconds = math.max(10, tonumber(seconds) or cvTime:GetInt())

    local pr = LC.Prisoners[ply]
    if pr then
        pr.untilT = pr.untilT + seconds
        ply:SetNW2Float("lc_jail_until", pr.untilT)
        return true
    end

    local cell = FreeCell(ply)
    if not cell then return false, "no free cell (place more with the editor)" end

    local weps = {}
    for _, w in ipairs(ply:GetWeapons()) do weps[#weps + 1] = w:GetClass() end

    LC.Occupied[cell] = ply
    LC.Prisoners[ply] = { untilT = CurTime() + seconds, cell = cell, reason = reason, weapons = weps }
    PutInCell(ply, cell)
    ply:SetNW2Float("lc_jail_until", CurTime() + seconds)
    ply:SetNW2String("lc_jail_reason", reason or "")
    LC.ClearWanted(ply)
    LC.CalmCops(ply)

    Say(ply, string.format("You have been incarcerated for %s. Reason: %s", string.NiceTime(seconds), reason or "none given"))
    NotifyCP(string.format("%s incarcerated (%s).", ply:Nick(), reason or "no reason"))
    LC.Log("info", string.format("Jailed %s for %ds: %s", ply:Nick(), seconds, tostring(reason)))
    hook.Run("LivingCityIncarcerated", ply, seconds, reason, arrester)
    return true
end

-- A free spot at the release point: not inside whoever was let out just before.
local RING = { { 0, 0 }, { 48, 0 }, { -48, 0 }, { 0, 48 }, { 0, -48 }, { 48, 48 }, { -48, -48 }, { 48, -48 }, { -48, 48 },
    { 96, 0 }, { -96, 0 }, { 0, 96 }, { 0, -96 } }
function LC.ReleaseSpot(pos, who)
    for _, o in ipairs(RING) do
        local p = pos + Vector(o[1], o[2], 4)
        local crowded = false
        for _, e in ipairs(ents.FindInSphere(p, 34)) do
            if e ~= who and IsValid(e) and (e:IsPlayer() or e:IsNPC()) then crowded = true break end
        end
        if not crowded then
            local tr = util.TraceHull({ start = p + Vector(0, 0, 2), endpos = p + Vector(0, 0, 2),
                mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 70), mask = MASK_PLAYERSOLID or MASK_SOLID, filter = who })
            if not tr.Hit and not tr.StartSolid then return p end
        end
    end
    return pos + Vector(0, 0, 4)
end

function LC.ReleasePrisoner(ply)
    local pr = LC.Prisoners[ply]
    if not pr then return false end
    LC.Prisoners[ply] = nil
    if LC.Occupied[pr.cell] == ply then LC.Occupied[pr.cell] = nil end
    if not IsValid(ply) then return true end

    ply:SetNW2Float("lc_jail_until", 0)
    ply:RemovePData("lc_jail_left")
    ply.lcGraceUntil = CurTime() + 60 -- nobody gets re-arrested on the steps
    if ply:Alive() then
        local rel = LC.PointsOfKind("release")
        if #rel > 0 then
            local p = LC.Pick(rel)
            ply:SetPos(LC.ReleaseSpot(p.pos, ply))
            ply:SetEyeAngles(Angle(0, p.yaw or 0, 0))
        end
        -- Units get their issue back. Anyone else leaves with nothing the Combine would
        -- call a weapon, and no radio: guns (carried or in the pockets) and radios stay
        -- behind. Their fists are theirs, always.
        local fid = ply:GetNW2String("lcf_faction", "")
        if fid == "cp" or fid == "admin" then
            if hook.Run("LivingCityRestoreLoadout", ply) == nil then
                ply:StripWeapons()
                for _, cls in ipairs(pr.weapons or {}) do ply:Give(cls) end
            end
        else
            ply:StripWeapons()
            local kept = LC.ItemsWhere and LC.ItemsWhere(ply, function(it) return it.use == "arm" or it.radio ~= nil end) or {}
            local lost = 0
            for id, n in pairs(kept) do if LC.TakeItem(ply, id, n) then lost = lost + n end end
            if lost > 0 then ply:ChatPrint("[Civil Protection] Your weapons and radio stay in the evidence locker.") end
        end
        ply:Give("weapon_fists")
        if LC.GiveHands then LC.GiveHands(ply, true) else ply:SelectWeapon("weapon_fists") end
    end
    Say(ply, "You have been released. Behave.")
    hook.Run("LivingCityReleased", ply)
    return true
end

local Escape
-- Back in their cell (a unit caught them out of it).
function LC.ReturnToCell(ply, msg)
    local pr = LC.Prisoners[ply]
    if not pr or not IsValid(ply) then return false end
    PutInCell(ply, pr.cell)
    pr.grace = CurTime() + 3
    if msg then ply:ChatPrint("[Civil Protection] " .. msg) end
    return true
end

function LC.EscapePrisoner(ply) return Escape(ply) end -- a breakout (sv_livingcity_resistanceops.lua)
Escape = function(ply)
    local pr = LC.Prisoners[ply]
    if not pr then return end
    LC.Prisoners[ply] = nil
    if LC.Occupied[pr.cell] == ply then LC.Occupied[pr.cell] = nil end
    ply:SetNW2Float("lc_jail_until", 0)
    ply:RemovePData("lc_jail_left")
    LC.ReportCrime(ply, "Prison escape", cvEscape:GetInt())
    if LC.Running then LC.MakeCopsHostile(ply, ply:GetPos(), 3000) end
    NotifyCP(ply:Nick() .. " has escaped custody!")
    LC.Log("info", "Escape: " .. ply:Nick())
    Say(ply, "You escaped. Every Civil Protection unit in the sector is looking for you.")
    hook.Run("LivingCityEscaped", ply)
end

timer.Create("LivingCityPrison", 1, 0, function()
    local now = CurTime()
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}
    for ply, pr in pairs(LC.Prisoners) do
        if not IsValid(ply) then
            LC.Prisoners[ply] = nil
        elseif now >= pr.untilT then
            LC.ReleasePrisoner(ply)
        elseif ply:Alive() and not (pr.grace and now < pr.grace) then
            local pos = ply:GetPos()
            local inside = pos:DistToSqr(pr.cell.pos) < 250 * 250 -- anywhere near your own cell is fine
            if not inside then
                if #zones > 0 then
                    -- a margin around the prison area, so a step over its edge isn't an escape
                    local reach = math.max(cvBuffer:GetFloat(), LCZ.Mercy())
                    for _, z in ipairs(zones) do
                        if LCZ.Contains(z, pos, reach) then inside = true break end
                    end
                else
                    inside = pos:DistToSqr(pr.cell.pos) < (500 + cvBuffer:GetFloat()) ^ 2
                end
            end
            if not inside then Escape(ply) end
        end
    end
end)

------------------------------------------------------------------------
-- Street detention: what happens when there's no prison on the map
------------------------------------------------------------------------

LC.Detained = LC.Detained or {} -- [ply] = { untilT, cop }

local function EndDetention(ply, d)
    LC.Detained[ply] = nil
    if not IsValid(ply) then return end
    ply:Freeze(false)
    ply:SetNW2Float("lc_detained_until", 0)
    ply.lcGraceUntil = CurTime() + 60
    local cop = d and d.cop
    local st = IsValid(cop) and LC.NPCs[cop]
    if st and st.state == "event" then
        st.eventUntil = 0
        cop:EmitSound("npc/metropolice/vo/allrightyoucango.wav", 75)
    end
    if ply:Alive() then
        ply:ChatPrint("[Civil Protection] Released with a warning. Move along.")
        hook.Run("LivingCityReleased", ply) -- time served, like any other release
    end
end

function LC.DetainOnTheSpot(ply, cop, reason)
    if not IsValid(ply) or LC.Detained[ply] or LC.Prisoners[ply] then return false end
    local secs = math.max(5, cvStreet:GetFloat())
    LC.Detained[ply] = { untilT = CurTime() + secs, cop = cop, reason = reason }
    ply:Freeze(true)
    ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 230), 1.5, 0.5)
    ply:SetNW2Float("lc_detained_until", CurTime() + secs)
    LC.ClearWanted(ply)
    LC.CalmCops(ply)
    local st = IsValid(cop) and LC.NPCs[cop]
    if st then
        LC.SetState(cop, st, "event")
        st.eventUntil = CurTime() + secs + 2
        cop:SetSchedule(SCHED_IDLE_STAND)
        LC.Face(cop, ply:GetPos())
        cop:EmitSound(LC.Pick(LC.Sounds.COP_ARREST), 78)
    end
    ply:ChatPrint(string.format("[Civil Protection] Detained: %s. You're cuffed and made to kneel.", reason or "malcompliance"))
    local fine = math.min(cvFine:GetInt(), LC.Credits and LC.Credits(ply) or 0)
    if fine > 0 then LC.AddCredits(ply, -fine, "fined") end
    if LC.CanEdit(ply) and #LC.PointsOfKind("cell") == 0 then
        ply:ChatPrint("[Living City] This map has no prison cells yet, so arrests happen on the street. Place cells (and a release spot) with the Living City Editor for real ones.")
    end
    LC.Log("info", string.format("Detained %s on the street for %ds: %s", ply:Nick(), secs, tostring(reason)))
    hook.Run("LivingCityIncarcerated", ply, secs, reason, cop) -- searched and processed like any arrest
    return true
end

timer.Create("LivingCityDetention", 0.5, 0, function()
    local now = CurTime()
    for ply, d in pairs(LC.Detained) do
        if not IsValid(ply) or not ply:Alive() or now >= d.untilT then
            EndDetention(ply, d)
        elseif IsValid(d.cop) then
            LC.Face(d.cop, ply:GetPos())
        end
    end
end)

hook.Add("PlayerDeath", "LivingCityDetention", function(ply)
    if LC.Detained[ply] then EndDetention(ply, LC.Detained[ply]) end
end)
hook.Add("PlayerDisconnected", "LivingCityDetention", function(ply) LC.Detained[ply] = nil end)

------------------------------------------------------------------------
-- Giving yourself up: walk up to a unit and press E (or !surrender).
-- A shorter sentence, the search called off, and serving it pays back more
-- of your Civil Standing.
------------------------------------------------------------------------

function LC.Surrender(ply, unit)
    if not IsValid(ply) or not ply:Alive() or LC.InCustody(ply) then return false, "Not now." end
    if LC.PlayerIsCP(ply) then return false, "Civil Protection units don't surrender." end
    local barred = LC.InsiderBarred and LC.InsiderBarred(ply, "surrender") -- (a caught mole: sv_livingcity_insider.lua)
    if barred then return false, barred end
    local reason = ply:GetNW2String("lc_wanted_reason", "")
    reason = "Surrendered" .. (reason ~= "" and (": " .. reason) or "")
    ply.lcSurrendered = true
    if IsValid(unit) then unit:EmitSound(LC.Pick(LC.Sounds.COP_ARREST), 78) end
    ply:ChatPrint("[Civil Protection] You put your hands up.")
    local done
    if LC.PrisonAvailable() then
        local secs = math.max(30, math.floor(cvTime:GetInt() / 2))
        -- to a unit NPC: he walks you there (sv_livingcity_march.lua)
        done = (LC.MarchToPrison and LC.MarchToPrison(ply, unit, secs, reason)) or LC.Incarcerate(ply, secs, reason, unit)
    end
    if not done then done = LC.DetainOnTheSpot(ply, unit, reason) end
    if not done then ply.lcSurrendered = nil return false, "Nobody's taking you in right now." end
    return true
end

hook.Add("PlayerSay", "LivingCitySurrender", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!surrender" then return end
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < 400 * 400 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and LC.PlayerIsCP(p) then
            local d = p:GetPos():DistToSqr(ply:GetPos())
            if d < 400 * 400 and (not bd or d < bd) then best, bd = p, d end
        end
    end
    if not best then
        ply:ChatPrint("[Civil Protection] There's no Civil Protection unit close enough to surrender to.")
    else
        local ok, why = LC.Surrender(ply, best)
        if not ok and why then ply:ChatPrint("[Civil Protection] " .. why) end
    end
    return ""
end)

-- Nobody is cuffed till they're subdued: beaten (lc_subdue_hits blows of the baton, each one
-- leaving them dazed, slow for a few seconds), shot or hurt down to under 20 health, downed, or
-- giving up (standing still for them, hands where they can see them). Someone in noclip (an
-- admin flying about) is never laid hands on at all.
local cvSubdue = CreateConVar("lc_subdue_hits", "3", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Blows of the stun baton before a unit can cuff someone who's still on their feet and running")
local function Flying(ply) return ply.GetMoveType and ply:GetMoveType() == MOVETYPE_NOCLIP end
LC.NoclipFlying = Flying
function LC.SubdueHits(ply)
    local s = ply.lcSubdue
    if not s or CurTime() - s.t > 25 then return 0 end
    return s.n
end
function LC.Subdued(ply)
    if not IsValid(ply) or not ply:Alive() or Flying(ply) then return false end
    if LC.IsDowned and LC.IsDowned(ply) then return true end
    if ply:Health() < 20 then return true end
    if LC.SubdueHits(ply) >= math.max(1, cvSubdue:GetInt()) then return true end
    -- given up: standing still for them, a second or more
    local v = ply:GetVelocity()
    if Vector(v.x, v.y, 0):Length() < 40 then
        ply.lcStillSince = ply.lcStillSince or CurTime()
        return CurTime() - ply.lcStillSince >= 1.2
    end
    ply.lcStillSince = nil
    return false
end
-- A blow of the baton: counted, and they stumble.
function LC.SubdueBlow(ply)
    local s = ply.lcSubdue
    if not s or CurTime() - s.t > 25 then s = { n = 0 } ply.lcSubdue = s end
    s.n, s.t = s.n + 1, CurTime()
    ply:SetNW2Float("lc_dazed_until", CurTime() + 2.5)
    if ply.ViewPunch then ply:ViewPunch(Angle(math.random(6, 10), math.random(-6, 6), 0)) end
end
-- A unit right beside someone they're to bring in: cuffs them if they're subdued, or else a blow
-- of the baton (a swing a second at most). True when they've been taken in.
function LC.NPCSubdue(unit, st, ply, now)
    if not IsValid(ply) or not ply:IsPlayer() or Flying(ply) then return false end
    if LC.Subdued(ply) then return LC.NPCTakesIn(unit, ply) end
    if (st.nextSubdue or 0) > now then return false end
    st.nextSubdue = now + 1.1
    if LC.Face then LC.Face(unit, ply:GetPos()) end
    if unit.SetSchedule and SCHED_MELEE_ATTACK1 then unit:SetSchedule(SCHED_MELEE_ATTACK1) end
    local d = DamageInfo and DamageInfo()
    if d then
        d:SetDamage(math.min(8, math.max(0, ply:Health() - 15)))
        d:SetDamageType(DMG_CLUB)
        d:SetAttacker(unit)
        d:SetInflictor(unit)
        ply.lcSubdueHit = true
        ply:TakeDamageInfo(d)
        ply.lcSubdueHit = nil
    end
    LC.SubdueBlow(ply)
    unit:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 2) .. ".wav", 75)
    return false
end

-- Security NPCs arrest instead of kill.
hook.Add("EntityTakeDamage", "LivingCityNPCArrest", function(victim, dmg)
    if not victim:IsPlayer() or not cvArrests:GetBool() then return end
    local attacker = dmg:GetAttacker()
    local st = LC.NPCs and LC.NPCs[attacker]
    if not st or not LC.IsSecurity(st) then return end
    if LC.Prisoners[victim] or LC.Detained[victim] or (LC.Marching and LC.Marching[victim]) or (LC.PlayerIsZombie and LC.PlayerIsZombie(victim)) then
        if LC.Detained[victim] then dmg:SetDamage(0) return true end
        return
    end
    if st.enemy ~= victim and not LC.PlayerIsWanted(victim) then return end
    if LC.AlertLevel and LC.AlertLevel(victim) >= 3 then return end -- lethal force authorized
    if Flying(victim) or victim.lcSubdueHit then return end

    local inflictor = dmg:GetInflictor()
    local club = dmg:IsDamageType(DMG_CLUB) or (IsValid(inflictor) and inflictor:GetClass() == "weapon_stunstick")
    -- a blow of the baton counts toward subduing them (and they stumble); cuffed once they're down
    if club then LC.SubdueBlow(victim) end
    if victim:Health() - dmg:GetDamage() > 20 and not LC.Subdued(victim) then return end

    if LC.NPCTakesIn(attacker, victim) then
        dmg:SetDamage(0)
        return true
    end
end)

-- A unit takes someone in: walked to a cell, or cuffed on the street where there's none.
-- (A stunstick hit does it, a hit that would take them under 20 health, or a unit who's run a
-- non-violent suspect down and laid hands on them: sv_livingcity.lua.)
function LC.NPCTakesIn(unit, victim)
    if not IsValid(unit) or not IsValid(victim) or not victim:Alive() or not cvArrests:GetBool() then return false end
    if LC.Prisoners[victim] or LC.Detained[victim] or (LC.Marching and LC.Marching[victim]) then return false end
    local reason = victim:GetNW2String("lc_wanted_reason", "")
    if reason == "" then reason = "Resisting Civil Protection" end
    local done
    if LC.PrisonAvailable() then
        -- walked there by the unit who took you down, and another (sv_livingcity_march.lua)
        done = (LC.MarchToPrison and LC.MarchToPrison(victim, unit, cvTime:GetInt(), reason))
            or LC.Incarcerate(victim, cvTime:GetInt(), reason, unit)
    end
    if not done then
        -- no cell (or no free one): cuffed on the street instead
        done = LC.DetainOnTheSpot(victim, unit, reason)
    end
    if done then unit:EmitSound("npc/metropolice/vo/affirmative.wav", 75) end
    return done and true or false
end

-- Prisoners can't build their way out.
local function Blocked(ply) if LC.Prisoners[ply] then return false end end
for _, h in ipairs({
    "PlayerNoClip", "PlayerSpawnProp", "PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerGiveSWEP",
    "PlayerSpawnNPC", "PlayerSpawnVehicle", "PlayerSpawnRagdoll", "PlayerSpawnEffect", "PlayerSpawnObject",
    "CanTool", "PlayerCanPickupWeapon",
}) do
    hook.Add(h, "LivingCityPrisonBlock", Blocked)
end

-- Dying doesn't end a sentence.
hook.Add("PlayerSpawn", "LivingCityPrisonRespawn", function(ply)
    local pr = LC.Prisoners[ply]
    if not pr then return end
    pr.grace = CurTime() + 3
    timer.Simple(0.1, function()
        if IsValid(ply) and LC.Prisoners[ply] then PutInCell(ply, pr.cell) end
    end)
end)

-- Disconnecting doesn't either.
hook.Add("PlayerDisconnected", "LivingCityPrisonLeave", function(ply)
    local pr = LC.Prisoners[ply]
    if not pr then return end
    local left = math.max(0, pr.untilT - CurTime())
    ply:SetPData("lc_jail_left", math.floor(left))
    if LC.Occupied[pr.cell] == ply then LC.Occupied[pr.cell] = nil end
    LC.Prisoners[ply] = nil
    NotifyCP(ply:Nick() .. " disconnected while in custody. Their sentence will resume when they return.")
end)

hook.Add("PlayerInitialSpawn", "LivingCityPrisonReturn", function(ply)
    local left = tonumber(ply:GetPData("lc_jail_left", 0)) or 0
    if left <= 0 then return end
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        local total = left + cvRejoin:GetInt()
        local ok = LC.Incarcerate(ply, total, "Returned mid-sentence", nil)
        if ok then
            ply:RemovePData("lc_jail_left")
            Say(ply, "You left in the middle of your sentence. It resumes now, with " .. cvRejoin:GetInt() .. " extra seconds.")
        else
            LC.ReportCrime(ply, "Absconded from custody", cvEscape:GetInt())
        end
    end)
end)

------------------------------------------------------------------------
-- NPC prisoners
------------------------------------------------------------------------

function LC.OnNPCReachedCell(npc, st, now)
    LC.SetState(npc, st, "jailed")
    st.untilT = st.jailUntil or (now + 90)
end

-- Cells sit behind doors that lock themselves, which NPCs can't walk through,
-- so prisoners are moved in and out the way players are: put straight there.
function LC.ReleaseNPCPrisoner(npc, st, now)
    LC.Release(npc, st)
    st.jailUntil = nil
    local rel = LC.PointsOfKind("release")
    if #rel > 0 then
        local p = LC.Pick(rel)
        npc:SetPos(LC.ReleaseSpot(p.pos, npc))
        if LC.FaceYaw and p.yaw then LC.FaceYaw(npc, p.yaw) end
    end
    LC.SetState(npc, st, "idle")
    st.untilT = now + math.Rand(2, 5)
    -- out, and off home: they don't hang about outside the prison
    st.leaveAt = now + math.Rand(4, 10)
    st.leaveWhy = "let out of prison, and gone home"
end

-- Used by the Arrest Baton on NPC citizens (and by quests): cuffed, then a
-- moment later they're in a cell, the same way an arrested player is.
function LC.ArrestNPC(npc, arrester)
    local st = LC.NPCs[npc]
    if not st or st.role ~= "citizen" then return false, "only citizens can be arrested" end
    local cell = FreeCell(npc)
    if not cell then return false, "no free cell" end
    if LC.LeaveLine then LC.LeaveLine(npc, st) end
    if IsValid(st.ss) then st.ss:Fire("CancelSequence"); st.ss:Remove(); st.ss = nil end
    LC.Release(npc, st)
    LC.Claim(npc, st, cell)
    st.jailUntil = CurTime() + math.Rand(90, 240)
    st.contraband = nil
    npc:EmitSound(LC.Sounds.Vo(st.gender or "male", "no02"), 70)
    npc:SetSchedule(SCHED_IDLE_STAND)
    LC.SetState(npc, st, "detained") -- cuffed, standing still
    st.untilT = CurTime() + 10
    st.poi = cell
    timer.Simple(1.5, function()
        if not IsValid(npc) or LC.NPCs[npc] ~= st or st.state ~= "detained" then return end
        npc:SetPos(cell.pos + Vector(0, 0, 4))
        if LC.FaceYaw and cell.yaw then LC.FaceYaw(npc, cell.yaw) end
        LC.OnNPCReachedCell(npc, st, CurTime())
    end)
    hook.Run("LivingCityIncarcerated", npc, st.jailUntil - CurTime(), "NPC arrest", arrester)
    return true
end

function LC.BatonMayArrest(ply)
    if game.SinglePlayer() or ply:IsAdmin() or LC.PlayerIsCP(ply) then return true end
    return false, "Only Civil Protection can make arrests."
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function FindPlayer(name)
    if not name or name == "" then return nil end
    name = string.lower(name)
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), name, 1, true) then return p end
    end
    return nil
end
LC.FindPlayer = FindPlayer

local function AdminOnly(ply) return not IsValid(ply) or ply:IsAdmin() or LC.CanEdit(ply) end

concommand.Add("lc_jail", function(ply, _, args)
    if not AdminOnly(ply) then return end
    local target = FindPlayer(args[1])
    if not target then return Say(ply, "Usage: lc_jail <name> [seconds] [reason]") end
    local secs = tonumber(args[2]) or cvTime:GetInt()
    local reason = table.concat(args, " ", 3)
    local ok, err = LC.Incarcerate(target, secs, reason ~= "" and reason or "Administrative detention", ply)
    Say(ply, ok and (target:Nick() .. " jailed.") or ("Couldn't: " .. tostring(err)))
end)

concommand.Add("lc_unjail", function(ply, _, args)
    if not AdminOnly(ply) then return end
    local target = FindPlayer(args[1])
    if not target then return Say(ply, "Usage: lc_unjail <name>") end
    Say(ply, LC.ReleasePrisoner(target) and (target:Nick() .. " released.") or (target:Nick() .. " isn't in custody."))
end)

concommand.Add("lc_prisoners", function(ply)
    if not AdminOnly(ply) then return end
    local any = false
    for p, pr in pairs(LC.Prisoners) do
        if IsValid(p) then
            any = true
            Say(ply, string.format("%s: %s left (%s)", p:Nick(), string.NiceTime(math.max(0, pr.untilT - CurTime())), pr.reason or ""))
        end
    end
    if not any then Say(ply, "Nobody is in custody.") end
end)
