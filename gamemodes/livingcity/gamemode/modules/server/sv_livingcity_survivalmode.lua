--[[
    Living City: Realistic or Relaxed survival, chosen per character
    (the owner, 10 November: "a realistic mode and relaxed survival needs
    mode ... we just need buffs/incentives to give to anyone who chooses
    realistic").

      Realistic (the default; everything as it has always been): hunger,
        thirst, parasites, the toilet and washing, food going off. For it:
        +lc_realistic_bonus (20%) on shift pay and on experience, and the
        title "Hardened" under your name.
      Relaxed: hunger and thirst come on at lc_relaxed_needs (a third of)
        the speed; no parasites, no toilet or washing, nothing goes off.

    Chosen on the characters screen (C > Your characters, the character
    you're playing) or F2 > Me; switching is allowed once every
    lc_survival_switch_hours (3). lc_survival_modes 0: everyone Realistic,
    with no bonus, exactly as before.

      lc_survival_modes 0/1, lc_survival_switch_hours (3),
      lc_realistic_bonus (0.2), lc_relaxed_needs (0.33)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_survival_modes", "1", FLAGS, "Each character chooses Realistic survival (bonus pay and experience) or Relaxed (slower hunger and thirst, no parasites, toilet, washing or spoiling)")
local cvHours  = CreateConVar("lc_survival_switch_hours", "3", FLAGS, "Hours between switches of survival mode")
local cvBonus  = CreateConVar("lc_realistic_bonus", "0.2", FLAGS, "Extra shift pay and experience for Realistic survival (0.2 = 20% more)")
local cvRelax  = CreateConVar("lc_relaxed_needs", "0.33", FLAGS, "How fast hunger and thirst come on in Relaxed survival (1 = as fast as Realistic)")

function LC.SurvivalMode(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply.GetPData then return "realistic" end
    if not ply.lcSurvMode then ply.lcSurvMode = ply:GetPData("lc_survival", "realistic") == "relaxed" and "relaxed" or "realistic" end
    return ply.lcSurvMode
end
function LC.Relaxed(ply) return LC.SurvivalMode(ply) == "relaxed" end

-- How fast hunger and thirst come on (sv_livingcity_survival.lua).
function LC.RelaxedNeedsMul(ply) return LC.Relaxed(ply) and math.Clamp(cvRelax:GetFloat(), 0, 1) or 1 end
-- Realistic's reward: shift pay (sv_livingcity_economy.lua, sv_livingcity_jobgames.lua) and experience (sv_livingcity_factions.lua).
function LC.SurvivalPayMul(ply)
    if not cvOn:GetBool() or not IsValid(ply) or LC.Relaxed(ply) then return 1 end
    return 1 + math.max(0, cvBonus:GetFloat())
end
LC.SurvivalXPMul = LC.SurvivalPayMul

local function Show(ply)
    if not IsValid(ply) then return end
    ply:SetNW2String("lc_survival", cvOn:GetBool() and LC.SurvivalMode(ply) or "")
    if LC.LegacyTitle then ply:SetNW2String("lc_legacy_title", (LC.LegacyTitle(ply))) end
end
LC.ShowSurvivalMode = Show

-- Seconds until they may switch again (0: now).
function LC.SurvivalSwitchWait(ply)
    local at = tonumber(ply:GetPData("lc_survival_at", 0)) or 0
    return math.max(0, at + cvHours:GetFloat() * 3600 - os.time())
end

function LC.SetSurvivalMode(ply, mode, force)
    if not cvOn:GetBool() then return false, "Survival modes are off on this server." end
    if mode ~= "relaxed" and mode ~= "realistic" then return false, "Realistic or Relaxed?" end
    if LC.SurvivalMode(ply) == mode then return false, "You're on " .. (mode == "relaxed" and "Relaxed" or "Realistic") .. " already." end
    local wait = LC.SurvivalSwitchWait(ply)
    if wait > 0 and not force then
        return false, string.format("You can switch again in %s.", string.NiceTime(wait))
    end
    ply:SetPData("lc_survival", mode)
    ply:SetPData("lc_survival_at", os.time())
    ply.lcSurvMode = mode
    if mode == "relaxed" then
        -- what Relaxed leaves out goes now: parasites, the urge, the dirt
        ply:SetNW2Float("lcn_parasites", 0)
        if LC.HygieneClear then LC.HygieneClear(ply) end
    end
    Show(ply)
    local text = mode == "relaxed"
        and "Relaxed survival: hunger and thirst come on slowly; no parasites, toilet, washing or food going off. (Realistic pays more.)"
        or string.format("Realistic survival: every need, as the city really is. %d%% more shift pay and experience, and the title \"Hardened\".", math.floor(cvBonus:GetFloat() * 100 + 0.5))
    if LC.Notice then LC.Notice(ply, "info", mode == "relaxed" and "Relaxed survival" or "Realistic survival", text, 10) else ply:ChatPrint(text) end
    hook.Run("LivingCitySurvivalMode", ply, mode)
    return true
end

-- "Hardened" under the name of anyone on Realistic.
local wrapped = false
local function Wrap()
    if LC.MenuActions then LC.MenuActions.survival = true end
    if wrapped or not LC.LegacyTitle then return end
    wrapped = true
    local orig = LC.LegacyTitle
    LC.LegacyTitle = function(ply, ...)
        local t, lives = orig(ply, ...)
        if cvOn:GetBool() and IsValid(ply) and not LC.Relaxed(ply) then
            t = (t and t ~= "") and ("Hardened, " .. t) or "Hardened"
        end
        return t, lives
    end
end
Wrap()
hook.Add("Initialize", "LivingCitySurvivalMode", Wrap)

hook.Add("LivingCityCharacterSwitched", "LivingCitySurvivalMode", function(ply)
    if IsValid(ply) then ply.lcSurvMode = nil timer.Simple(0.5, function() Show(ply) end) end
end)
hook.Add("PlayerInitialSpawn", "LivingCitySurvivalMode", function(ply)
    timer.Simple(4, function() Show(ply) end)
end)

hook.Add("PlayerSay", "LivingCitySurvivalMode", function(ply, text)
    local arg = string.match(string.lower(string.Trim(tostring(text or ""))), "^[!/]survival%s*(%a*)$")
    if arg == nil then return end
    if arg == "" then arg = LC.Relaxed(ply) and "realistic" or "relaxed" end
    local ok, why = LC.SetSurvivalMode(ply, arg)
    if not ok and why then ply:ChatPrint("[Survival] " .. why) end
    return ""
end)
