--[[
    Living City (client): your body tells you before a card does

    Hungry, thirsty or badly hurt, and you feel it first (sv_livingcity_learning.lua
    holds the card back until you seem stuck):
      hungry (below 25)   the colour drains out of the world a little, now and
                          then a wave of weakness, and your stomach (a
                          recording in sound/livingcity/body/stomach*, if
                          there is one)
      thirsty (below 25)  the world goes hazy and warm, and you breathe hard
      hurt (below 35)     the edges of the screen go red, and your heart
                          pounds
    Each player can turn it off: the full menu's Settings (lc_body_signs 0).
]]

LC_CL = LC_CL or {}

local cvBody = CreateClientConVar("lc_body_signs", "1", true, false, "Hunger, thirst and pain shown on screen and in sound before any tip card")

local function Level(me)
    local hunger = me:GetNW2Float("lcn_hunger", 100)
    local thirst = me:GetNW2Float("lcn_thirst", 100)
    local hp = me:Health()
    return math.Clamp((25 - hunger) / 25, 0, 1), math.Clamp((25 - thirst) / 25, 0, 1), (hp > 0 and hp < 35) and math.Clamp((35 - hp) / 35, 0, 1) or 0
end
LC_CL.BodyLevel = Level

local stomach
local nextStomach, nextBreath, nextBeat = 0, 0, 0
local function Stomach()
    if stomach == nil then
        stomach = {}
        for _, n in ipairs(file.Find("sound/livingcity/body/stomach*", "GAME") or {}) do stomach[#stomach + 1] = "livingcity/body/" .. n end
    end
    return #stomach > 0 and stomach[math.random(#stomach)] or nil
end

local function On(me)
    return cvBody:GetBool() and IsValid(me) and me:Alive() and not me:GetNW2Bool("lc_dreaming", false)
end

hook.Add("Think", "LivingCityBodySigns", function()
    local me = LocalPlayer()
    if not On(me) then return end
    local h, t, p = Level(me)
    local now = CurTime()
    if h > 0 and now > nextStomach then
        nextStomach = now + math.Rand(40, 80) * (1.2 - h * 0.6)
        local s = Stomach()
        if s then surface.PlaySound(s) end
        me.lcBodyWobble = now
    end
    if t > 0.4 and now > nextBreath then
        nextBreath = now + math.Rand(30, 60)
        me:EmitSound("player/breathe1.wav", 50, 100, 0.25 + t * 0.3)
        timer.Simple(4, function() if IsValid(me) then me:StopSound("player/breathe1.wav") end end)
    end
    if p > 0 and now > nextBeat then
        nextBeat = now + 1.4 - p * 0.6
        surface.PlaySound("player/heartbeat1.wav")
    end
end)

hook.Add("RenderScreenspaceEffects", "LivingCityBodySigns", function()
    local me = LocalPlayer()
    if not On(me) or not DrawColorModify then return end
    local h, t, p = Level(me)
    if h + t + p <= 0 then return end
    local wob = me.lcBodyWobble and math.max(0, 1 - (CurTime() - me.lcBodyWobble) / 3) or 0
    DrawColorModify({
        ["$pp_colour_addr"] = t * 0.03 + p * 0.04, ["$pp_colour_addg"] = t * 0.015, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.04 * wob, ["$pp_colour_contrast"] = 1 - h * 0.08,
        ["$pp_colour_colour"] = 1 - h * 0.35 - wob * 0.25, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
    })
    if t > 0 and DrawMotionBlur then DrawMotionBlur(0.2, 0.5 * t, 0.01) end
end)

-- the red at the edges when you're badly hurt
hook.Add("HUDPaint", "LivingCityBodySigns", function()
    local me = LocalPlayer()
    if not On(me) then return end
    local _, _, p = Level(me)
    if p <= 0 then return end
    local pulse = 0.6 + 0.4 * math.abs(math.sin(CurTime() * (2 + p * 2)))
    local w, hh = ScrW(), ScrH()
    local a = math.floor(90 * p * pulse)
    for i = 0, 5 do
        local band = math.floor(hh * 0.025)
        surface.SetDrawColor(140, 0, 0, math.floor(a * (1 - i / 6)))
        surface.DrawRect(0, i * band, w, band)
        surface.DrawRect(0, hh - (i + 1) * band, w, band)
        surface.DrawRect(i * band, 0, band, hh)
        surface.DrawRect(w - (i + 1) * band, 0, band, hh)
    end
end)
