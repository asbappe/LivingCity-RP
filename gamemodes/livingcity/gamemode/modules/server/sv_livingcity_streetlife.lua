--[[
    Street life (the owner, 2 November: the lost v2.7 pieces, rebuilt)

    Brandishing   a gun raised (or out at all, with lc_lowered_weapons off) in sight
                  of a unit: "Lower that weapon!", and still up after lc_brandish_grace
                  seconds, wanted for brandishing a weapon (lc_brandish 1). Units, the
                  Overwatch, and the Resistance on their own ground are left alone.
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

local cvBrandish = CreateConVar("lc_brandish", "1", FLAGS, "A raised gun in sight of a unit: a warning, then wanted for brandishing a weapon")
local cvGrace    = CreateConVar("lc_brandish_grace", "5", FLAGS, "Seconds to lower your gun after a unit tells you to")
local cvWanted   = CreateConVar("lc_brandish_wanted", "180", FLAGS, "Seconds wanted for brandishing a weapon")
local cvObit     = CreateConVar("lc_obituary", "1", FLAGS, "When a player character dies, everyone hears it in chat")

------------------------------------------------------------------------
-- Brandishing
------------------------------------------------------------------------

local function GunUp(ply)
    local w = ply:GetActiveWeapon()
    if not IsValid(w) then return false end
    local guns = (LCL and LCL.Guns) or LC.ViolentGuns or {}
    if not (guns[w:GetClass()] or (LC.ViolentGuns and LC.ViolentGuns[w:GetClass()])) then return false end
    if LCL and LCL.Lowered and GetConVar("lc_lowered_weapons") and GetConVar("lc_lowered_weapons"):GetBool() then
        return not LCL.Lowered(ply)
    end
    return true
end
LC.GunUp = GunUp

local function Exempt(ply)
    if not ply:Alive() or LC.TimeStopped then return true end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return true end
    if ply:GetNW2Bool("lc_build", false) then return true end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return true end
    if LC.InRebelZone and LC.InRebelZone(ply:GetPos()) then return true end -- (their own ground)
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return true end -- (already wanted: units deal with them)
    return false
end

function LC.BrandishTick(now)
    if not cvBrandish:GetBool() then return end
    for _, ply in ipairs(player.GetAll()) do
        if Exempt(ply) or not GunUp(ply) then
            ply.lcBrandishWarned = nil
        elseif LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
            if not ply.lcBrandishWarned then
                ply.lcBrandishWarned = now
                -- (a [Civil Protection] line goes on screen as a warning card too: sv_livingcity_notices.lua)
                ply:ChatPrint("[Civil Protection] Lower that weapon! You have " .. math.floor(cvGrace:GetFloat()) .. " seconds (hold R to lower it, or put it away), or you're wanted.")
            elseif now - ply.lcBrandishWarned >= cvGrace:GetFloat() then
                ply.lcBrandishWarned = nil
                if LC.ReportCrime then LC.ReportCrime(ply, "Brandishing a weapon", cvWanted:GetFloat()) end
            end
        end
    end
end
timer.Create("LivingCityBrandish", 1, 0, function()
    local ok, err = pcall(LC.BrandishTick, CurTime())
    if not ok and LC.Error then LC.Error("brandishing", err) end
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
