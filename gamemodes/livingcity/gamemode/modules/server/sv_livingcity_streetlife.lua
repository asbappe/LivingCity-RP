--[[
    Street life (the owner, 2 November: the lost v2.7 pieces, rebuilt)

    Guns          a citizen seen by a unit with a gun in hand is wanted; rebel ground
                  and (for metrocops) the Combine's ground are where guns are carried
                  lowered, and raising one there draws a warning, then fire (lc_brandish 1).
    Obituaries    when a player character dies, the city hears it in chat (chat only, no card): their name,
                  their citizen number, and how (lc_obituary 1).
    Detentions    held on the street (no prison cells), the longer you were wanted the
                  longer you're held: lc_street_detention, plus lc_street_detention_per_minute
                  for each minute wanted, at most lc_street_detention_max (sv_livingcity_prison.lua).
    Finding by number   admin commands that take a player also take their citizen number
                  (LC.FindPlayer, sv_livingcity_prison.lua).
]]

LC = LC or {}
local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)

local cvBrandish = CreateConVar("lc_brandish", "1", FLAGS, "Guns: a citizen seen with one is wanted; on rebel ground (anyone) and the Combine's (metrocops) guns are carried lowered, and raising one draws a warning, then fire")
local cvGrace    = CreateConVar("lc_brandish_grace", "5", FLAGS, "Seconds to lower your gun after the rebels or the Overwatch tell you to")
local cvWanted   = CreateConVar("lc_brandish_wanted", "180", FLAGS, "Seconds a citizen is wanted for being seen with a gun")
local cvObit     = CreateConVar("lc_obituary", "1", FLAGS, "When a player character dies, everyone hears it in chat")

------------------------------------------------------------------------
-- Guns (the owner, 2 November): a gun is contraband, and the Combine won't have anyone else
-- carrying one. Carrying lowered is for rebel ground (anyone) and, for Civil Protection's
-- metrocops and recruits, the Combine's own ground: they haven't had the Overwatch's
-- conditioning, and the Combine don't wholly trust them.
--   Out on the streets: a citizen seen by a unit with a gun in hand, raised or not: wanted at once.
--   Rebel ground: anyone who isn't the Resistance raising a gun where the fighters can see it
--     is told to lower it; still up after lc_brandish_grace seconds, they open fire.
--   The Combine's ground: a metrocop or recruit raising a gun where the Overwatch's soldiers can
--     see it is told to lower it; still up after the grace: a mark against them (lc_cp_raise_xp
--     XP) and the soldiers turn their guns on them.
------------------------------------------------------------------------

local cvRaiseXP = CreateConVar("lc_cp_raise_xp", "25", FLAGS, "XP a metrocop or recruit loses for keeping a gun raised on the Combine's ground after the Overwatch told them to lower it")

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
local function Resistance(ply) return ply:GetNW2String("lcf_faction", "") == "resistance" end

-- Who must carry lowered here (sh_livingcity_lowered.lua reads it on both sides)
function LC.MustCarryLowered(ply)
    if not ply:Alive() then return false end
    local pos = ply:GetPos()
    if LC.InRebelZone and LC.InRebelZone(pos) then return true end
    if IsUnit(ply) and not IsOverwatch(ply) and LC.CombineZoneAt and LC.CombineZoneAt(pos) then return true end
    return false
end

local function Off(ply)
    return not ply:Alive() or LC.TimeStopped or ply:GetNW2Bool("lc_build", false)
        or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply))
end

-- A warning, then (still up after the grace) what follows; nil when the gun's down or unseen
local function Warned(ply, key, seen, now, say)
    ply.lcGunWarn = ply.lcGunWarn or {}
    if not seen then ply.lcGunWarn[key] = nil return false end
    local at = ply.lcGunWarn[key]
    if not at then
        ply.lcGunWarn[key] = now
        ply:ChatPrint(say)
        return false
    end
    if now - at >= cvGrace:GetFloat() then ply.lcGunWarn[key] = nil return true end
    return false
end

local function RebelsSeeing(ply, dist)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and npc:GetPos():DistToSqr(ply:GetPos()) < dist * dist
            and (not LC.RebelCanSee or LC.RebelCanSee(npc, ply, dist)) then out[#out + 1] = { npc, st } end
    end
    return out
end
local function SoldiersSeeing(ply, dist)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "soldier" and npc:Health() > 0 and npc:GetPos():DistToSqr(ply:GetPos()) < dist * dist
            and (not LC.UnitSees or LC.UnitSees(npc, ply, dist)) then out[#out + 1] = { npc, st } end
    end
    return out
end

function LC.BrandishTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local must = cvBrandish:GetBool() and not Off(ply) and LC.MustCarryLowered(ply) or false
        -- walking onto ground where it counts, the gun goes down
        if must ~= ply:GetNW2Bool("lc_carry_lowered", false) then
            ply:SetNW2Bool("lc_carry_lowered", must)
            if must and ply:GetNW2Bool("lc_raised", false) then ply:SetNW2Bool("lc_raised", false) end
        end
        if not cvBrandish:GetBool() or Off(ply) then
            ply.lcGunWarn = nil
        else
            local pos = ply:GetPos()
            local rebelGround = LC.InRebelZone and LC.InRebelZone(pos)
            if rebelGround then
                -- rebel ground: a stranger's raised gun is a threat (the Combine's own are fought anyway)
                local stranger = not Resistance(ply) and not IsUnit(ply)
                local seers = (stranger and Raised(ply)) and RebelsSeeing(ply, 900) or {}
                if Warned(ply, "rebel", #seers > 0, now, "[Rebel] Whoa! Lower that gun, now, or we drop you!") then
                    for _, ns in ipairs(seers) do if LC.RebelSetFoe then LC.RebelSetFoe(ns[1], ns[2], ply, now) end end
                end
            elseif IsUnit(ply) then
                -- a metrocop or recruit on the Combine's ground, gun up where the Overwatch can see it
                local seers = (not IsOverwatch(ply) and ply:GetNW2Bool("lc_carry_lowered", false) and Raised(ply)) and SoldiersSeeing(ply, 900) or {}
                if Warned(ply, "overwatch", #seers > 0, now, "[Overwatch] Unit: lower your weapon. You are not cleared to bear arms here.") then
                    if LC.AddXP and cvRaiseXP:GetInt() > 0 then LC.AddXP(ply, -cvRaiseXP:GetInt(), "noncompliance on Overwatch ground") end
                    ply:ChatPrint("[Overwatch] Noncompliance logged. Weapons on the unit.")
                    for _, ns in ipairs(seers) do
                        if LC.ArmUnit then LC.ArmUnit(ns[1], ns[2]) end
                        if LC.MakeOneHostile then LC.MakeOneHostile(ns[1], ns[2], ply) end
                        ns[2].provokedBy, ns[2].provokedUntil = ply, now + 20
                    end
                end
            else
                -- out on the streets: any gun in a citizen's hand, seen by a unit, is the end of it
                ply.lcGunWarn = nil
                local wanted = LC.PlayerIsWanted and LC.PlayerIsWanted(ply)
                if GunInHand(ply) and not wanted and LC.SeenBySecurity and LC.SeenBySecurity(ply, 800) then
                    ply:ChatPrint("[Civil Protection] Weapon! Drop it! (You're wanted: carrying a weapon.)")
                    if LC.ReportCrime then LC.ReportCrime(ply, "Armed: carrying a weapon", cvWanted:GetFloat()) end
                end
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
