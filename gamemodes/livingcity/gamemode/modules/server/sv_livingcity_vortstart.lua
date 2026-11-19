--[[
    Living City: being born a vortigaunt (the owner, 14 November)

    "A human resistance member should not be able to spawn as a free vortigaunt; you have to select that
    at the beginning of the game ... then you spawn as a vortigaunt slave and have to do menial tasks and
    are either saved by humans after using the vortessence (like 3-5 minutes later) or a scripted event
    happens after 10 minutes to save you if the first fails or never happens."

      The choice        At the start of every new life (a first visit, after a permanent death, a fresh
                        character slot), before anything else, a window asks: a citizen of the city (the
                        train and Civil Intake, as before) or a vortigaunt. LC.OfferRace.
      The shackles      A vortigaunt starts in the Vortigaunt faction: Combine property, collared, put to
                        the city's dirtiest labour (The Collar story on F4, the Union's shifts). No Civil
                        Intake for it, no human name: a laborer's designation.
      Reaching out      From lc_vort_reach_minutes (4) after the shackles go on, it can reach out through
                        the vortessence (F2, the radial menu, !vortcall: sv_livingcity_vortwork.lua) and
                        the Resistance hears where it is. They cut the shackles (!unshackle).
      Rescue            Still shackled lc_vort_rescue_minutes (10) after the shackles went on (online
                        time), a Resistance team comes for it: two fighters slip out of sight nearby and
                        walk to it; reaching it (or a minute later, whatever happens) the shackles are cut
                        and it is a Free Vortigaunt of the Resistance. Only while it stands somewhere a
                        unit isn't looking; otherwise the team waits for that.

    A vortigaunt never becomes human, and a human never becomes a vortigaunt (LC.IsVortChar,
    LC.CanJoinFaction, sv_livingcity_factions.lua).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_vort_start", "1", FLAGS, "A new life can be a vortigaunt, chosen at the start (1), or only a citizen (0)")
local cvReach = CreateConVar("lc_vort_reach_minutes", "4", FLAGS, "Minutes a new shackled vortigaunt works before it can first reach out through the vortessence")
local cvRescue = CreateConVar("lc_vort_rescue_minutes", "10", FLAGS, "Minutes (online) a shackled vortigaunt stays shackled before a Resistance team comes to free it (0: never)")

util.AddNetworkString("lc_race_pick")
util.AddNetworkString("lc_race_chosen")

local function Shackled(ply) return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "vort" end

-- A laborer's designation, not a name: "Laborer VLB-4-117".
function LC.VortDesignation()
    return string.format("Laborer VLB-%d-%03d", math.random(1, 9), math.random(0, 999))
end

-- Ask at the start of a new life. True if the window went out (the character screen waits for the answer).
function LC.OfferRace(ply)
    if not IsValid(ply) or not cvOn:GetBool() then return false end
    if LC.IsVortChar and LC.IsVortChar(ply) then return false end
    local key = ply:GetNW2String("lc_cid", "") .. "|" .. ply:GetNW2String("lc_char", "")
    if ply.lcRaceAskedFor == key then return false end
    ply.lcRaceAskedFor = key
    net.Start("lc_race_pick")
    net.Send(ply)
    return true
end

-- The shackles go on: a vortigaunt's new life.
function LC.BecomeVortSlave(ply)
    if not IsValid(ply) then return false end
    local name = LC.VortDesignation()
    if LC.SetCharacter then LC.SetCharacter(ply, name, "models/vortigaunt.mdl") end
    ply:SetPData("lc_chosen", "1")
    ply.lcArrive = nil -- (no train, no Civil Intake)
    if LC.IntakeForget then LC.IntakeForget(ply) end
    LC.SetFaction(ply, "vort", nil, true)
    ply:SetNW2Bool("lc_unreg", false)
    local now = CurTime()
    ply.lcVortSince, ply.lcVortShackledFor, ply.lcVortRescue = now, 0, nil
    ply.lcVortCallNext = now + cvReach:GetFloat() * 60
    if ply:Alive() and ply.Spawn then ply:Spawn() end
    timer.Simple(1.5, function()
        if not IsValid(ply) then return end
        if LC.Notice then
            LC.Notice(ply, "info", "A shackled vortigaunt",
                string.format("You are %s: Combine property, collared, put to the city's dirtiest work. Do it: your board (F4) has The Collar. In about %d minutes the vortessence stirs enough to reach out to the Resistance (F2 > Reach out through the vortessence). Freedom comes from them.",
                    name, math.ceil(cvReach:GetFloat())), 14)
        end
        ply:ChatPrint("[Miscount] You are " .. name .. ", a shackled vortigaunt. Work, keep your head down, and in a few minutes reach out through the vortessence (F2).")
    end)
    hook.Run("LivingCityBornVort", ply)
    LC.Log("info", ply:Nick() .. " began a new life as a shackled vortigaunt (" .. name .. ")")
    return true
end

net.Receive("lc_race_chosen", function(_, ply)
    if not IsValid(ply) or (ply.lcRaceNext or 0) > CurTime() then return end
    ply.lcRaceNext = CurTime() + 1
    local pick = net.ReadString()
    if ply.lcRaceAskedFor == nil then return end -- (never asked)
    if pick == "vort" and cvOn:GetBool() and not (LC.IsVortChar and LC.IsVortChar(ply)) then
        LC.BecomeVortSlave(ply)
        return
    end
    -- a citizen: the character screen as before (or the train and Civil Intake first)
    if LC.OpenCharacterCreator then LC.OpenCharacterCreator(ply, { afterRace = true }) end
end)

------------------------------------------------------------------------
-- Rescue, if nobody comes
------------------------------------------------------------------------

local RESCUE_WAIT = 60 -- (seconds the team has to reach it before the shackles are cut all the same)

local function Free(ply, team)
    if not Shackled(ply) then return end
    LC.SetFaction(ply, "resistance", "vortigaunt", true, true)
    ply:ChatPrint("[Miscount] A fighter kneels at your collar and it falls away. \"Come on, friend. You're with us now.\" The vortessence is yours again: left click strikes, right click charges a vest.")
    if LC.Notice then LC.Notice(ply, "info", "Free", "The Resistance came for you. You are a Free Vortigaunt: the Combine will hunt you on sight outside rebel ground.", 10) end
    if LC.RadioNotice then LC.RadioNotice("resistance", "A team cut a vortigaunt loose " .. ((LC.DescribePlace and LC.DescribePlace(ply:GetPos())) or "") .. ". Welcome it.") end
    hook.Run("LivingCityVortFreed", ply, nil)
    -- the team slips away
    for _, npc in ipairs(team or {}) do
        if IsValid(npc) then
            local st = LC.NPCs and LC.NPCs[npc]
            if st then st.leaveAt = CurTime() + 20 end
            timer.Simple(30, function() if IsValid(npc) and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then npc:Remove() end end)
        end
    end
end
LC.VortRescueFree = Free

-- Two fighters, from out of sight near it, walking to it.
function LC.VortRescueStart(ply)
    if not Shackled(ply) or ply.lcVortRescue then return false end
    local team = {}
    if LC.SpawnRebel and LC.RandomWanderPos then
        for _ = 1, 30 do
            if #team >= 2 then break end
            local p = LC.RandomWanderPos("citizen", ply:GetPos())
            if p and p:DistToSqr(ply:GetPos()) > 400 * 400 and p:DistToSqr(ply:GetPos()) < 1500 * 1500
                and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40))) then
                local npc, st = LC.SpawnRebel(p + Vector(0, 0, 4), nil, "weapon_pistol")
                if IsValid(npc) and st then
                    st.vortRescue = ply
                    team[#team + 1] = npc
                    if LC.GoTo then LC.GoTo(npc, st, ply:GetPos(), true, nil) end
                end
            end
        end
    end
    ply.lcVortRescue = { team = team, untilT = CurTime() + RESCUE_WAIT }
    ply:ChatPrint("[Vortessence] Someone is coming for you. Stay where no unit can see.")
    return true
end

function LC.VortRescueTick(now)
    if cvRescue:GetFloat() <= 0 then return end
    for _, ply in ipairs(player.GetAll()) do
        if Shackled(ply) and ply:Alive() then
            ply.lcVortShackledFor = (ply.lcVortShackledFor or 0) + 1
            local r = ply.lcVortRescue
            if not r then
                if ply.lcVortShackledFor >= cvRescue:GetFloat() * 60 then LC.VortRescueStart(ply) end
            else
                local seen = LC.SeenBySecurity and LC.SeenBySecurity(ply, 900)
                local there = false
                for _, npc in ipairs(r.team) do
                    if IsValid(npc) and npc:GetPos():DistToSqr(ply:GetPos()) < 150 * 150 then there = true end
                    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
                    if st and math.floor(now) % 4 == 0 and LC.GoTo then LC.GoTo(npc, st, ply:GetPos(), true, nil) end
                end
                if not seen and (there or now >= r.untilT) then
                    ply.lcVortRescue = nil
                    Free(ply, r.team)
                end
            end
        elseif not Shackled(ply) then
            ply.lcVortShackledFor, ply.lcVortRescue = nil, nil
        end
    end
end

timer.Create("LivingCityVortRescue", 1, 0, function()
    local ok, err = LC.Try(LC.VortRescueTick, CurTime())
    if not ok and LC.Error then LC.Error("vortigaunt rescue", err) end
end)

-- Back on the server, still shackled: the first reach is a little way off again, not straight away.
hook.Add("PlayerInitialSpawn", "LivingCityVortStart", function(ply)
    timer.Simple(5, function()
        if Shackled(ply) and not ply.lcVortCallNext then ply.lcVortCallNext = CurTime() + cvReach:GetFloat() * 60 end
    end)
end)
