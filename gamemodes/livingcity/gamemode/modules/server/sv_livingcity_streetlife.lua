--[[
    Street life (the owner, 2 November: the lost v2.7 pieces, rebuilt)

    Guns          a citizen seen by a unit with a gun in hand on the streets is wanted;
                  on rebel ground (everyone) and the Combine's (recruits and metrocops) guns
                  are carried lowered: a raised one draws their guns, then fire (lc_brandish 1).
    Obituaries    when a player character dies, the city hears it in chat (chat only, no card): their name,
                  their citizen number, and how (lc_obituary 1).
    Detentions    held on the street (no prison cells), the longer you were wanted the
                  longer you're held: lc_street_detention, plus lc_street_detention_per_minute
                  for each minute wanted, at most lc_street_detention_max (sv_livingcity_prison.lua).
    Finding by number   admin commands that take a player also take their citizen number
                  (LC.FindPlayer, sv_livingcity_prison.lua).
    Gunfire       a shot within lc_gunfire_fear (700) units: the citizens who hear it run from
                  the shooter, and some drop and cover their heads first (the owner, 7 November).
]]

LC = LC or {}
local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)

local cvBrandish = CreateConVar("lc_brandish", "1", FLAGS, "Guns: a citizen seen with one on the streets is wanted; on rebel ground (everyone) and the Combine's (recruits and metrocops) guns are carried lowered, and a raised one draws their guns, then fire")
local cvGrace    = CreateConVar("lc_brandish_grace", "10", FLAGS, "Seconds a raised gun is put up with on rebel ground (or the Combine's, for recruits and metrocops) before they open fire")
local cvWanted   = CreateConVar("lc_brandish_wanted", "180", FLAGS, "Seconds a citizen is wanted for being seen with a gun")
local cvObit     = CreateConVar("lc_obituary", "1", FLAGS, "When a player character dies, everyone hears it in chat")

------------------------------------------------------------------------
-- Guns (the owner, 2 November): a gun is contraband, and the Combine won't have anyone else
-- carrying one.
--   Out on the streets: a citizen seen by a unit with a gun in hand, raised or not: wanted at once.
--   Rebel ground (everyone), and the Combine's ground (Civil Protection's recruits and
--   metrocops: they haven't had the Overwatch's conditioning, and the Combine don't wholly trust
--   them; not the Overwatch, nor Division Leaders): walking in, a card says to lower your gun
--   (hold R). While it's up, the fighters (or the Overwatch's soldiers) who can see you stand to
--   and face you, guns on you; still up after lc_brandish_grace (10) seconds, they open fire.
--   Only ever at players: the city's NPCs carry their own way, and never take each other for it.
------------------------------------------------------------------------

local function GunInHand(ply)
    local w = ply:GetActiveWeapon()
    if not IsValid(w) then return false end
    local cls = w:GetClass()
    return (LCL and LCL.Guns and LCL.Guns[cls]) or (LC.ViolentGuns and LC.ViolentGuns[cls]) or false
end
LC.GunInHand = GunInHand
local function Raised(ply) return GunInHand(ply) and not (LCL and LCL.Lowered and LCL.Lowered(ply)) end
LC.GunUp = Raised

local function IsUnit(ply) return LC.PlayerIsCP and LC.PlayerIsCP(ply) end
local function IsOverwatch(ply) return LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply) end
-- a recruit or a metrocop (Civil Protection's first two ranks, no special post)
local function Untrusted(ply)
    return IsUnit(ply) and not IsOverwatch(ply) and ply:GetNW2Int("lcf_rank", 1) <= 2 and ply:GetNW2String("lcf_special", "") == ""
end

-- Where guns are carried lowered for this player: "rebel", "combine" or nil. From the edge in
-- (lc_zone_mercy short of it), so there's time to lower before walking in; second: really inside.
function LC.LoweredGround(ply)
    if not ply:Alive() then return nil end
    local pos = ply:GetPos()
    if (LC.NearRebelZone or LC.InRebelZone)(pos) then return "rebel", LC.InRebelZone(pos) end
    if Untrusted(ply) and (LC.NearCombineZone or LC.CombineZoneAt)(pos) then return "combine", LC.CombineZoneAt(pos) ~= nil end
    return nil
end
function LC.MustCarryLowered(ply) return LC.LoweredGround(ply) ~= nil end

local function Off(ply)
    return not ply:Alive() or LC.TimeStopped or ply:GetNW2Bool("lc_build", false)
        or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply))
end

-- who's watching: the fighters on rebel ground, the Overwatch's soldiers on the Combine's
local function Watchers(ply, ground, dist)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        local mine = (ground == "rebel" and st.role == "rebel") or (ground == "combine" and st.role == "soldier")
        if mine and IsValid(npc) and npc:Health() > 0 and npc:GetPos():DistToSqr(ply:GetPos()) < dist * dist
            and not (LC.RebelAsleep and LC.RebelAsleep(st)) then
            local sees
            if ground == "rebel" then sees = not LC.RebelCanSee or LC.RebelCanSee(npc, ply, dist)
            else sees = not LC.UnitSees or LC.UnitSees(npc, ply, dist) end
            if sees then out[#out + 1] = { npc, st } end
        end
    end
    return out
end

-- standing to: facing them, gun on them (no fight: nothing changes in how they feel about anyone)
local function StandTo(npc, st, ply, now)
    if st.state == "hostile" or st.foe or (st.lcAimNext or 0) > now then return end
    st.lcAimNext = now + 1
    st.lcAimAt = ply
    if npc.SetTarget then npc:SetTarget(ply) end
    if npc.SetSchedule and SCHED_TARGET_FACE then npc:SetSchedule(SCHED_TARGET_FACE) end
end

-- What they say over the ten seconds (Half-Life 2's own lines), at about 0, 40% and 80% of the grace;
-- the subtitle goes on screen with each. A woman fighter's from female01. Missing files are skipped.
local LINES = {
    rebel = {
        { "vo/npc/male01/headsup01.wav", "[Rebel] Heads up! Lower that gun, now!" },
        { "vo/npc/male01/watchwhat.wav", "[Rebel] Watch what you're doing! Put it down!" },
        { "vo/npc/male01/uhoh.wav", "[Rebel] Last chance. Lower it!" },
    },
    combine = {
        { "npc/combine_soldier/vo/prepforcontact.wav", "[Overwatch] Unit: lower your weapon. You are not cleared to bear arms here." },
        { "npc/combine_soldier/vo/weaponsoffsafeprepforcontact.wav", "[Overwatch] Weapons off safe. Lower it, unit." },
        { "npc/combine_soldier/vo/contact.wav", "[Overwatch] Final warning." },
    },
}
LC.GunWarnLines = LINES
local function Say(ply, ground, i, npc)
    local l = LINES[ground] and LINES[ground][i]
    if not l then return end
    ply:ChatPrint(l[2])
    if IsValid(npc) then
        local snd = l[1]
        if ground == "rebel" and LC.ModelIsFemale and LC.ModelIsFemale(npc:GetModel()) then snd = string.gsub(snd, "/male01/", "/female01/") end
        if not LC.SoundExists or LC.SoundExists(snd) then npc:EmitSound(snd, 80) end
    end
end

function LC.BrandishTick(now)
    local grace = math.max(1, cvGrace:GetFloat())
    for _, ply in ipairs(player.GetAll()) do
        local ground, inside
        if cvBrandish:GetBool() and not Off(ply) then ground, inside = LC.LoweredGround(ply) end
        local was = ply:GetNW2String("lc_lowered_ground", "")
        if (ground or "") ~= was then
            ply:SetNW2String("lc_lowered_ground", ground or "")
            ply:SetNW2Bool("lc_carry_lowered", ground ~= nil)
            -- walking up to it: whatever's in your hand is as it was (up); the prompt on screen says
            -- what to do until it's lowered (sh_livingcity_lowered.lua)
            if ground then ply:SetNW2Bool("lc_raised", GunInHand(ply) and true or false) end
            ply.lcRaisedSince, ply.lcRaisedSaid = nil, nil
        end
        if not cvBrandish:GetBool() or Off(ply) then
            ply.lcRaisedSince, ply.lcRaisedSaid = nil, nil
        elseif ground then
            local seers = Raised(ply) and Watchers(ply, ground, 1200) or {}
            if #seers == 0 then
                ply.lcRaisedSince, ply.lcRaisedSaid = nil, nil
            else
                ply.lcRaisedSince = ply.lcRaisedSince or now
                -- the warnings, spread over the grace, from the nearest of them
                local said = ply.lcRaisedSaid or 0
                local due = 1 + math.floor((now - ply.lcRaisedSince) / (grace * 0.4))
                if due > said and due <= 3 then
                    ply.lcRaisedSaid = due
                    local near, nd
                    for _, ns in ipairs(seers) do
                        local d = ns[1]:GetPos():DistToSqr(ply:GetPos())
                        if not nd or d < nd then near, nd = ns[1], d end
                    end
                    Say(ply, ground, due, near)
                end
                for _, ns in ipairs(seers) do StandTo(ns[1], ns[2], ply, now) end
                -- (at the edge, they only stand to: they fire once you're really in)
                if inside and now - ply.lcRaisedSince >= grace then
                    ply.lcRaisedSince, ply.lcRaisedSaid = nil, nil
                    for _, ns in ipairs(seers) do
                        local npc, st = ns[1], ns[2]
                        st.lcAimAt = nil
                        if ground == "rebel" then
                            if LC.RebelSetFoe then LC.RebelSetFoe(npc, st, ply, now) end
                        else
                            if LC.ArmUnit then LC.ArmUnit(npc, st) end
                            if LC.MakeOneHostile then LC.MakeOneHostile(npc, st, ply) end
                            st.provokedBy, st.provokedUntil = ply, now + 30
                        end
                    end
                end
            end
        else
            ply.lcRaisedSince, ply.lcRaisedSaid = nil, nil
            -- out on the streets: any gun in a citizen's hand, seen by a unit, is the end of it
            if not IsUnit(ply) and GunInHand(ply) and not (LC.PlayerIsWanted and LC.PlayerIsWanted(ply))
                and LC.SeenBySecurity and LC.SeenBySecurity(ply, 800) then
                ply:ChatPrint("[Civil Protection] Weapon! Drop it! (You're wanted: carrying a weapon.)")
                if LC.ReportCrime then LC.ReportCrime(ply, "Armed: carrying a weapon", cvWanted:GetFloat()) end
            end
        end
    end
end
timer.Create("LivingCityBrandish", 0.5, 0, function()
    local ok, err = pcall(LC.BrandishTick, CurTime())
    if not ok and LC.Error then LC.Error("guns", err) end
end)

------------------------------------------------------------------------
-- Obituaries
------------------------------------------------------------------------

local function How(victim, attacker, inflictor)
    if not IsValid(attacker) or attacker == victim or (attacker.IsWorld and attacker:IsWorld()) then return "died" end
    if attacker:IsPlayer() then
        if LC.PlayerIsCP and LC.PlayerIsCP(attacker) then return "was killed by Civil Protection" end
        return "was killed"
    end
    local st = LC.NPCs and LC.NPCs[attacker]
    if st and LC.IsSecurity and LC.IsSecurity(st) then return "was killed by Civil Protection" end
    local cls = attacker:GetClass()
    if string.find(cls, "zombie", 1, true) or string.find(cls, "headcrab", 1, true) or (st and st.role == "zombie") then return "was taken by the infestation" end
    if st and st.role == "rebel" then return "was killed by anticitizens" end
    return "was killed"
end
LC.ObituaryHow = How

function LC.Obituary(victim, attacker, inflictor)
    if not cvObit:GetBool() or not IsValid(victim) then return nil end
    if LC.TimeStopped then return nil end -- (an ending: nobody really dies)
    local name = LC.CharacterName and LC.CharacterName(victim) or victim:Nick()
    local cid = victim:GetNW2String("lc_cid", "")
    local line = "[Obituary] " .. name .. (cid ~= "" and (", citizen #" .. cid) or "") .. ", " .. How(victim, attacker, inflictor) .. "."
    for _, p in ipairs(player.GetAll()) do p:ChatPrint(line) end
    return line
end
hook.Add("PlayerDeath", "LivingCityObituary", function(victim, inflictor, attacker)
    local ok, err = pcall(LC.Obituary, victim, attacker, inflictor)
    if not ok and LC.Error then LC.Error("obituary", err) end
end)

------------------------------------------------------------------------
-- Gunfire (the owner, 7 November: "when firearms are being shot and bullets flying, we need nearby
-- citizens to run in terror, some to squat and cover their heads"). Any gun fired, a player's or an
-- NPC's: the citizens within lc_gunfire_fear who aren't spoken for (held, in a cell, under escort, in
-- an event, asleep) run from the shooter, and about a third drop and cover their heads for a few
-- seconds first. A citizen reacts once every ten seconds or so, a gun is heard once every second and
-- a half, so a firefight doesn't send them off again every shot.
------------------------------------------------------------------------

local cvFear = CreateConVar("lc_gunfire_fear", "700", FLAGS, "How far citizens hear a gun and run from it, some covering their heads first (0: they don't react)")
local FEAR_BUSY = { detained = true, jailed = true, escorted = true, event = true, abed = true, hostile = true, working = true }
local COWER = { "ACT_COWER", "Fear_Reaction", "photo_react_startle" }
local CRIES = { "help01", "runforyourlife01", "runforyourlife02", "runforyourlife03", "gethellout", "watchout", "uhoh", "no01", "no02" }
local function Cry(npc, st)
    npc:EmitSound("vo/npc/" .. (st.gender == "female" and "female01" or "male01") .. "/" .. CRIES[math.random(#CRIES)] .. ".wav", 80, math.random(96, 108))
end

-- Off, away from where the shots came from (not just anywhere).
local function RunFrom(npc, st, from, now)
    local npos = npc:GetPos()
    local away = npos - from
    away.z = 0
    if away:LengthSqr() < 1 then away = VectorRand() away.z = 0 end
    away:Normalize()
    local dest
    for _ = 1, 8 do
        local p = LC.RandomWanderPos("citizen", npos + away * 700)
        if p and (p - npos):GetNormalized():Dot(away) > 0.2 then dest = p break end
    end
    dest = dest or LC.RandomWanderPos("citizen", npos)
    if not dest then return false end
    if LC.CancelBusy then LC.CancelBusy(npc, st) end
    LC.LeaveLine(npc, st)
    LC.Release(npc, st)
    if not LC.GoTo(npc, st, dest, true, nil) then return false end
    st.untilT = now + 6
    return true
end

-- Down, head covered, then off.
local function Cower(npc, st, from, now)
    if LC.CancelBusy then LC.CancelBusy(npc, st) end
    LC.LeaveLine(npc, st)
    LC.Release(npc, st)
    if npc.SetSchedule then npc:SetSchedule(SCHED_IDLE_STAND) end
    st.dest, st.route = nil, nil
    LC.SetState(npc, st, "idle")
    st.untilT = now + 4 -- (nothing new till they've got up)
    st.nextChat = math.max(st.nextChat or 0, now + 12)
    npc:SetNW2String("lc_doing", "head down")
    if LC.PlayGesture then LC.PlayGesture(npc, COWER, 4) end
    timer.Simple(math.Rand(3, 4), function()
        if not IsValid(npc) or LC.NPCs[npc] ~= st or npc:Health() <= 0 then return end
        npc:SetNW2String("lc_doing", "")
        if not FEAR_BUSY[st.state] then RunFrom(npc, st, from, CurTime()) end
    end)
    return true
end

function LC.GunfireFear(shooter, src, now)
    local r = cvFear:GetFloat()
    if r <= 0 then return 0 end
    now = now or CurTime()
    local n = 0
    for npc, st in pairs(LC.NPCs) do
        if IsValid(npc) and st.role == "citizen" and not st.test and not st.questLock and not st.subject and not FEAR_BUSY[st.state]
            and npc:Health() > 0 and npc ~= shooter and (st.nextFear or 0) < now and npc:GetPos():DistToSqr(src) < r * r then
            st.nextFear = now + math.Rand(9, 13)
            local done
            if math.random() < 0.35 then done = Cower(npc, st, src, now) else done = RunFrom(npc, st, src, now) end
            if done then
                n = n + 1
                if math.random() < 0.5 then Cry(npc, st) end
            end
        end
    end
    return n
end

hook.Add("EntityFireBullets", "LivingCityGunfireFear", function(ent, data)
    if not IsValid(ent) or cvFear:GetFloat() <= 0 then return end
    local now = CurTime()
    if (ent.lcShotHeardAt or 0) > now then return end
    ent.lcShotHeardAt = now + 1.5
    local src = data and data.Src or ent:GetPos()
    local ok, err = pcall(LC.GunfireFear, ent, src, now)
    if not ok and LC.Error then LC.Error("gunfire fear", err) end
end)
