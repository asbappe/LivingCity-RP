--[[
    Living City: a vortigaunt charging a vest, as you see it

    While a vortigaunt charges someone's vest (sv_livingcity_resistanceops.lua,
    LC.VortChargeShow), "lc_vort_charge_to" on it is who, until
    "lc_vort_charge_until": a green beam from its raised hand to their chest,
    pulsing, with sparks along it and a green light, as in Half-Life 2.
]]

if SERVER then return end

LC_CL = LC_CL or {}

local BEAM = Material("sprites/physbeam")
local GLOW = Material("sprites/light_glow02_add")
local HANDS = { "ValveBiped.hand1_R", "ValveBiped.Bip01_R_Hand", "ValveBiped.hand1_L", "ValveBiped.Bip01_L_Hand" }
local found, nextScan = {}, 0

-- Where the energy leaves it: a hand, or about where one would be.
function LC_CL.VortChargeHand(v)
    for _, name in ipairs(HANDS) do
        local b = v.LookupBone and v:LookupBone(name)
        if b then
            local pos = v:GetBonePosition(b)
            if pos and pos ~= v:GetPos() then return pos end
        end
    end
    return v:GetPos() + v:GetForward() * 22 + Vector(0, 0, 52)
end

-- The beam's points now: from the hand to the chest, wavering.
function LC_CL.VortChargeBeam(from, to, now)
    local pts, n = {}, 8
    local dir = to - from
    for i = 0, n do
        local f = i / n
        local sway = math.sin(f * math.pi) * 6 -- (none at either end)
        pts[#pts + 1] = from + dir * f + Vector(math.sin(now * 13 + i * 1.7) * sway, math.cos(now * 11 + i * 2.3) * sway, math.sin(now * 17 + i) * sway)
    end
    return pts
end

hook.Add("PostDrawTranslucentRenderables", "LivingCityVortCharge", function(depth, sky)
    if depth or sky then return end
    local now = CurTime()
    if now >= nextScan then
        nextScan = now + 0.5
        found = {}
        for _, e in ipairs(ents.FindByClass("npc_vortigaunt")) do
            if e:GetNW2Float("lc_vort_charge_until", 0) > now then found[#found + 1] = e end
        end
    end
    for _, v in ipairs(found) do
        local to = IsValid(v) and not v:IsDormant() and v:GetNW2Float("lc_vort_charge_until", 0) > now and v:GetNW2Entity("lc_vort_charge_to")
        if to and IsValid(to) then
            local from = LC_CL.VortChargeHand(v)
            local chest = to:WorldSpaceCenter()
            local pts = LC_CL.VortChargeBeam(from, chest, now)
            local pulse = 0.6 + 0.4 * math.abs(math.sin(now * 9))
            render.SetMaterial(BEAM)
            render.StartBeam(#pts)
            for i, p in ipairs(pts) do render.AddBeam(p, 9 * pulse, i / #pts + now * 2, Color(70, 255, 90, 230)) end
            render.EndBeam()
            render.SetMaterial(GLOW)
            render.DrawSprite(from, 34 * pulse, 34 * pulse, Color(80, 255, 100, 255))
            render.DrawSprite(chest, 46 * pulse, 46 * pulse, Color(80, 255, 100, 220))
            local dl = DynamicLight and DynamicLight(v:EntIndex())
            if dl then
                dl.pos = chest
                dl.r, dl.g, dl.b = 60, 255, 90
                dl.brightness = 3 * pulse
                dl.Decay = 600
                dl.Size = 200
                dl.DieTime = now + 0.2
            end
        end
    end
end)
