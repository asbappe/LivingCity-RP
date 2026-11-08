--[[
    Living City: cigarettes, alcohol, stimulants and the shakes, your side (sv_livingcity_vices.lua)

      Smoke from anyone smoking near you. Drunk: the world sways and blurs, more the drunker you
      are. Wired on a stimulant: sharper and brighter. Crashing: grey and heavy. Shaken after a
      lost nightmare: a tremor in your view, and the colour drained out.
]]

LC_CL = LC_CL or {}

-- Someone smoking: a few puffs from their head.
function LC_CL.ViceSmoke(kind, who, strength)
    if kind ~= "smoke" or not IsValid(who) or not ParticleEmitter then return end
    local at = (who.EyePos and who:EyePos() or who:GetPos() + Vector(0, 0, 64)) + who:GetForward() * 6
    local em = ParticleEmitter(at)
    if not em then return end
    for i = 1, 6 + 3 * (strength or 1) do
        local pt = em:Add("particle/particle_smokegrenade", at + VectorRand() * 2)
        if pt then
            pt:SetVelocity(Vector(0, 0, 12) + who:GetForward() * 10 + VectorRand() * 6)
            pt:SetDieTime(2.5 + math.random() * 1.5)
            pt:SetStartAlpha(70)
            pt:SetEndAlpha(0)
            pt:SetStartSize(2)
            pt:SetEndSize(14 + 4 * (strength or 1))
            pt:SetColor(200, 200, 200)
            pt:SetRoll(math.random(0, 360))
        end
    end
    em:Finish()
end

local function Amounts(me)
    local now = CurTime()
    local drunk = math.Clamp(me:GetNW2Int("lc_drunk", 0) / 6, 0, 1)
    local wired = me:GetNW2Float("lc_wired_until", 0) > now and 1 or 0
    local crash = me:GetNW2Float("lc_crash_until", 0) > now and 1 or 0
    local shaken = math.Clamp((me:GetNW2Float("lc_shaken_until", 0) - now) / 30, 0, 1)
    return drunk, wired, crash, shaken
end
LC_CL.ViceAmounts = Amounts

hook.Add("RenderScreenspaceEffects", "LivingCityVices", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local drunk, wired, crash, shaken = Amounts(me)
    if drunk > 0 and DrawMotionBlur then DrawMotionBlur(0.15, 0.6 * drunk, 0.02) end
    local col = 1 + 0.2 * wired - 0.35 * crash - 0.5 * shaken - 0.15 * drunk
    local contrast = 1 + 0.12 * wired - 0.1 * crash
    if (col ~= 1 or contrast ~= 1) and DrawColorModify then
        DrawColorModify({
            ["$pp_colour_addr"] = 0.02 * drunk, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0.02 * wired - 0.03 * crash, ["$pp_colour_contrast"] = contrast, ["$pp_colour_colour"] = math.max(0, col),
            ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })
    end
    if wired > 0 and DrawSharpen then DrawSharpen(1.2, 1.2) end
end)

-- (one of the camera's steps: cl_livingcity_view.lua) the sway of drink, the tremor of the shakes
LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.vices = { order = 41, fn = function(ply, view)
    local drunk, _, _, shaken = Amounts(ply)
    if drunk <= 0 and shaken <= 0 then return end
    local t = CurTime()
    view.angles = view.angles + Angle(math.sin(t * 0.8) * 3 * drunk + math.sin(t * 23) * 0.4 * shaken,
        math.sin(t * 0.5) * 2 * drunk + math.sin(t * 19) * 0.3 * shaken, math.sin(t * 1.1) * 5 * drunk)
end }

-- A Vortigaunt's whisper (beat a nightmare, as a citizen): a place marked for ten minutes.
local whisper
net.Receive("lc_vice", function()
    local kind, who, strength = net.ReadString(), net.ReadEntity(), net.ReadUInt(4)
    if kind == "whisper" then
        whisper = { pos = net.ReadVector(), what = net.ReadString(), untilT = CurTime() + 600 }
        return
    end
    if LC_CL.ViceSmoke then LC_CL.ViceSmoke(kind, who, strength) end
end)
function LC_CL.ViceWhisper() return whisper end
hook.Add("HUDPaint", "LivingCityViceWhisper", function()
    if not whisper or CurTime() > whisper.untilT then whisper = nil return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local sp = whisper.pos:ToScreen()
    if not sp.visible then return end
    local d = math.floor(me:GetPos():Distance(whisper.pos) / 52)
    draw.SimpleTextOutlined(whisper.what .. " (" .. d .. " m)", "DermaDefaultBold", sp.x, sp.y, Color(150, 255, 170, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
end)
