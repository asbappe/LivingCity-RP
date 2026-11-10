--[[
    Living City: catching something

    The owner, 10 November: "a framework for illness that can be contracted
    such as a bad cough and vomiting and other things; it shouldn't be
    horrifically annoying and can fit into the Realistic survival mechanics".

    Realistic survival only (sv_livingcity_survivalmode.lua): Relaxed
    characters never fall ill. Every illness passes by itself; Union medicine
    (the Commissary, the black market) gets rid of the ones it treats at once.
    Once you've had one, you can't catch it again for a while.

      A cold (a bad cough)  caught out in the rain, or from someone coughing
                            next to you. You cough now and then (everyone near
                            hears it, and might catch it), and get thirsty a
                            little faster. 20 minutes; Union medicine cures it.
                            Left alone, it can turn into a fever.
      A stomach bug         raw meat, dirty water, now and then something from
                            a bin. Every few minutes you double over and
                            vomit: a little hunger and thirst gone, a mess on
                            the floor. 10 minutes; a drink of clean water
                            shortens it.
      A fever               from a cold left untreated. The world swims a
                            little, and you can't get your health above 60
                            until it breaks. 12 minutes; Union medicine cures it.

    Adding one: a row in LC.Illnesses below (name, how long, what cures it,
    what it does now and then), and somewhere it's caught (LC.CatchIllness).

    The tip card ("ill") waits until you seem stuck, like the others
    (sv_livingcity_learning.lua): the coughing and the screen come first
    (cl_livingcity_bodysigns.lua reads lc_ill).

    Settings: lc_illness (1; 0 and nobody falls ill), lc_illness_rate (1:
    how likely catching anything is; 0.5 is half as likely).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_illness", "1", FLAGS, "Realistic-survival characters can catch a cold, a stomach bug or a fever (each passes by itself; Union medicine helps)")
local cvRate = CreateConVar("lc_illness_rate", "1", FLAGS, "How likely catching an illness is (1 normal, 0.5 half as likely)")

local COUGHS = { "ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav" }
local IMMUNE_SECS = 1800

local function Near(ply, r, fn)
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and p:GetPos():DistToSqr(ply:GetPos()) < r * r then fn(p) end
    end
end

-- id = { name, seconds, cured by medicine, what happens now and then (every..every2 seconds), what you feel when it starts }
LC.Illnesses = {
    cold = { name = "a cold", secs = 1200, medicine = true, every = 45, every2 = 90,
        start = "Your throat's raw and your nose is running. You're coming down with something.",
        tick = function(ply, ill)
            ply:EmitSound(COUGHS[math.random(#COUGHS)], 70)
            if LC.Feed then LC.Feed(ply, 0, -2) end
            -- a cough close by can pass it on
            Near(ply, 150, function(p) if math.random() < 0.04 then LC.CatchIllness(p, "cold") end end)
            -- left alone, it can get worse (once)
            if not ill.worsened and LC.IllnessLeft(ply, "cold") < 600 then
                ill.worsened = true
                if math.random() < 0.3 then LC.CatchIllness(ply, "fever", true) end
            end
        end },
    stomach = { name = "a stomach bug", secs = 600, every = 120, every2 = 200,
        start = "Your stomach lurches. Something you ate is fighting back.",
        tick = function(ply)
            ply:EmitSound("npc/barnacle/barnacle_die2.wav", 65, 120)
            if LC.Feed then LC.Feed(ply, -8, -8) end
            ply:ScreenFade(SCREENFADE.IN, Color(70, 90, 20, 90), 1, 0.3)
            if util.Decal and util.TraceLine then
                local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 60 + Vector(0, 0, -90), filter = ply })
                if tr and tr.Hit then util.Decal("YellowBlood", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal) end
            end
            ply:ChatPrint("You double over and vomit.")
        end },
    fever = { name = "a fever", secs = 720, medicine = true, every = 20, every2 = 20,
        start = "You're burning up, and shivering at the same time. A fever.",
        tick = function(ply)
            if ply:Health() > 60 then ply:SetHealth(ply:Health() - 1) end
        end },
}

local function Ills(ply)
    ply.lcIll = ply.lcIll or {}
    return ply.lcIll
end

local function Sync(ply)
    local ids = {}
    for id in pairs(Ills(ply)) do ids[#ids + 1] = id end
    table.sort(ids)
    ply:SetNW2String("lc_ill", table.concat(ids, ","))
end

function LC.IsIll(ply, id)
    local t = IsValid(ply) and ply.lcIll
    if not t then return false end
    if id then return t[id] ~= nil end
    return next(t) ~= nil
end

function LC.IllnessLeft(ply, id)
    local ill = ply.lcIll and ply.lcIll[id]
    return ill and math.max(0, ill.untilT - CurTime()) or 0
end

-- Can this person fall ill at all?
local function Susceptible(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LC.Relaxed and LC.Relaxed(ply) then return false end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return false end
    if LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end
    return true
end
LC.IllnessSusceptible = Susceptible

-- Catch it (true if they did). sure: no chance roll (and the rate setting doesn't apply).
function LC.CatchIllness(ply, id, sure, chance)
    local def = LC.Illnesses[id]
    if not def or not Susceptible(ply) then return false end
    if LC.IsIll(ply, id) then return false end
    ply.lcImmune = ply.lcImmune or {}
    if (ply.lcImmune[id] or 0) > CurTime() then return false end
    if not sure and math.random() >= (chance or 1) * cvRate:GetFloat() then return false end
    local now = CurTime()
    Ills(ply)[id] = { untilT = now + def.secs, nextT = now + math.Rand(def.every * 0.5, def.every) }
    Sync(ply)
    ply:ChatPrint(def.start)
    hook.Run("LivingCityFellIll", ply, id)
    return true
end

-- Better (cured, or it ran its course).
function LC.RecoverIllness(ply, id, how)
    local t = ply.lcIll
    if not t or not t[id] then return false end
    t[id] = nil
    ply.lcImmune = ply.lcImmune or {}
    ply.lcImmune[id] = CurTime() + IMMUNE_SECS
    Sync(ply)
    local def = LC.Illnesses[id]
    ply:ChatPrint(how == "medicine" and ("The medicine works. " .. (def and ("You're over " .. def.name .. ".") or ""))
        or ("You feel better. " .. (def and ("You're over " .. def.name .. ".") or "")))
    hook.Run("LivingCityRecovered", ply, id, how)
    return true
end

-- Union medicine (an item that cures = "illness", sv_livingcity_survival.lua): every illness it treats.
function LC.CureIllness(ply)
    local any = false
    for id in pairs(table.Copy(Ills(ply))) do
        if LC.Illnesses[id] and LC.Illnesses[id].medicine then any = LC.RecoverIllness(ply, id, "medicine") or any end
    end
    if not any then ply:ChatPrint("Bitter. If anything was wrong with you, it wasn't that.") end
    return any
end

local function Clear(ply)
    if not IsValid(ply) then return end
    ply.lcIll = nil
    ply:SetNW2String("lc_ill", "")
end
LC.ClearIllness = Clear

timer.Create("LivingCityIllness", 5, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local t = ply.lcIll
        if t and next(t) then
            if not Susceptible(ply) then
                Clear(ply)
            else
                for id, ill in pairs(table.Copy(t)) do
                    local def = LC.Illnesses[id]
                    if not def or now >= ill.untilT then
                        LC.RecoverIllness(ply, id, "time")
                    elseif now >= ill.nextT then
                        t[id].nextT = now + math.Rand(def.every, def.every2)
                        if def.tick then def.tick(ply, t[id]) end
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- Where it's caught
------------------------------------------------------------------------

-- out in the rain, a minute at a time
timer.Create("LivingCityIllnessRain", 60, 0, function()
    if not cvOn:GetBool() or not LC.Weather then return end
    local w = LC.Weather()
    if w ~= "rain" and w ~= "storm" then return end
    for _, ply in ipairs(player.GetAll()) do
        if Susceptible(ply) and (not LC.UnderSky or LC.UnderSky(ply:GetPos())) then
            LC.CatchIllness(ply, "cold", false, w == "storm" and 0.05 or 0.03)
        end
    end
end)

-- what you eat and drink
hook.Add("LivingCityConsumed", "LivingCityIllness", function(ply, id)
    local it = LCS and LCS.Items[id]
    if not it or not IsValid(ply) then return end
    if string.sub(id, 1, 4) == "raw_" then LC.CatchIllness(ply, "stomach", false, 0.25)
    elseif it.parasite then LC.CatchIllness(ply, "stomach", false, 0.15) end
    -- clean water settles a stomach bug: half of what's left
    if (it.thirst or 0) > 0 and not it.parasite and LC.IsIll(ply, "stomach") then
        local ill = ply.lcIll.stomach
        ill.untilT = CurTime() + LC.IllnessLeft(ply, "stomach") * 0.5
    end
end)

-- rummaging in bins
hook.Add("LivingCityScavenged", "LivingCityIllness", function(ply)
    if IsValid(ply) and ply:IsPlayer() then LC.CatchIllness(ply, "stomach", false, 0.03) end
end)

-- a new life starts healthy
hook.Add("PlayerDeath", "LivingCityIllness", Clear)
hook.Add("LivingCitySurvivalMode", "LivingCityIllness", function(ply) if LC.Relaxed and LC.Relaxed(ply) then Clear(ply) end end)

-- the tip card, held back like the others until they seem stuck (sv_livingcity_learning.lua)
local function AddHint()
    if not LC.HINTS then return end
    LC.HINTS.ill = { title = "You're ill",
        text = { default = "You've caught something. It will pass on its own. Union medicine (the Commissary) cures a cold or a fever at once; clean water settles a stomach bug. Stay out of the rain, cook your meat and boil your water." } }
    if LC.HintWaits then LC.HintWaits.ill = true end
end
AddHint()
hook.Add("Initialize", "LivingCityIllnessHint", AddHint)
hook.Add("LivingCityFellIll", "LivingCityIllnessHint", function(ply) if LC.Hint then LC.Hint(ply, "ill") end end)
