--[[
    Living City (client): the infestation, up close

      - putrid stains across the ground of it (decals your own game paints,
        once, as the infestation appears or grows)
      - a sickly yellow haze while you're in it (cl_livingcity_atmos.lua draws
        it with the weather's fog)
      - a geiger counter that clicks faster the deeper you go

    lc_infest_ambience 0/1 (yours to turn off).
]]

LC_CL = LC_CL or {}

local cvOn = CreateClientConVar("lc_infest_ambience", "1", true, false, "The infestation's stains on the ground, its haze and the geiger counter")

LC_CL.InfestHaze = LC_CL.InfestHaze or 0 -- 0 to 1, eased (the fog reads it)

-- How deep into the infestation pos is: 0 outside it (a little past its edge
-- already counts for something), up to 1 well inside.
local function Depth(pos)
    local best = 0
    for _, z in ipairs(LC_CL.territory or {}) do
        if z.kind == "infest" then
            if LCZ.Contains(z, pos, -150) then return 1 end
            if LCZ.Contains(z, pos, 0) then best = math.max(best, 0.85)
            elseif LCZ.Contains(z, pos, 150) then best = math.max(best, 0.55)
            elseif LCZ.Contains(z, pos, 400) then best = math.max(best, 0.25) end
        end
    end
    return best
end
LC_CL.InfestDepth = Depth

local target, nextDepth, nextClick = 0, 0, 0

hook.Add("Think", "LivingCityInfest", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now = CurTime()
    if now > nextDepth then
        nextDepth = now + 0.5
        target = (cvOn:GetBool() and me:Alive()) and Depth(me:GetPos()) or 0
    end
    LC_CL.InfestHaze = math.Approach(LC_CL.InfestHaze, target, FrameTime() * 0.8)
    if LC_CL.InfestHaze > 0.05 then LC_CL.InfestMotes(me, LC_CL.InfestHaze, now) end
    -- the geiger counter: a click now and then at the edge, a rattle in the middle of it
    if target > 0 and now > nextClick then
        local rate = 1.5 + target * 12
        nextClick = now + math.Rand(0.3, 1.7) / rate
        me:EmitSound("player/geiger" .. math.random(1, 3) .. ".wav", 55, 100, 0.25 + target * 0.35)
    end
end)

-- The air itself: a yellow cast over everything, and motes of it drifting past you.
hook.Add("RenderScreenspaceEffects", "LivingCityInfestTint", function()
    local h = LC_CL.InfestHaze or 0
    if h <= 0.02 or not DrawColorModify or LC_CL.LiveCamRendering then return end
    DrawColorModify({
        ["$pp_colour_addr"] = 0.07 * h, ["$pp_colour_addg"] = 0.06 * h, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.02 * h, ["$pp_colour_contrast"] = 1 - 0.08 * h,
        ["$pp_colour_colour"] = 1 - 0.35 * h,
        ["$pp_colour_mulr"] = 0.4 * h, ["$pp_colour_mulg"] = 0.35 * h, ["$pp_colour_mulb"] = 0,
    })
end)

local emitter, nextMote = nil, 0
function LC_CL.InfestMotes(me, h, now)
    if now < nextMote or not ParticleEmitter then return end
    nextMote = now + 0.12
    local eye = me:EyePos()
    emitter = emitter or ParticleEmitter(eye)
    if not emitter then return end
    for _ = 1, math.ceil(h * 4) do
        local p = emitter:Add("particle/particle_smokegrenade", eye + VectorRand() * 260 + Vector(0, 0, math.Rand(-60, 40)))
        if p then
            p:SetVelocity(VectorRand() * 6 + Vector(0, 0, math.Rand(-2, 4)))
            p:SetDieTime(math.Rand(3, 6))
            p:SetStartAlpha(0)
            p:SetEndAlpha(math.floor(70 * h))
            p:SetStartSize(math.Rand(30, 60))
            p:SetEndSize(math.Rand(80, 140))
            p:SetRoll(math.Rand(0, 360))
            p:SetRollDelta(math.Rand(-0.2, 0.2))
            p:SetColor(200, 195, 60)
            p:SetAirResistance(20)
        end
    end
end

------------------------------------------------------------------------
-- Stains on the ground
------------------------------------------------------------------------

-- Yellow, putrid, and some of it burnt in. Only what this install has.
local STAINS = { "decals/yblood1", "decals/yblood2", "decals/yblood3", "decals/yblood4", "decals/yblood5", "decals/yblood6" }
local SCORCH = { "decals/scorch1", "decals/scorch2" }
local stainMats, scorchMats

local function Mats(list)
    local out = {}
    for _, n in ipairs(list) do
        local m = Material(n)
        if m and not m:IsError() then out[#out + 1] = m end
    end
    return out
end

local STAIN_COL, SCORCH_COL = Color(225, 255, 40, 255), Color(80, 100, 25, 255)
local stained = {} -- [zone] = true

-- Paint one zone, thickly: the ground of it gone bad all over, overlapping
-- splotches of yellow ooze and burnt patches (up to 180 of them, well inside
-- the decal budget).
function LC_CL.StainZone(z)
    stainMats = stainMats or Mats(STAINS)
    scorchMats = scorchMats or Mats(SCORCH)
    if #stainMats + #scorchMats == 0 or not util.DecalEx then return 0 end
    local area = z.box and ((z.box.maxs.x - z.box.mins.x) * (z.box.maxs.y - z.box.mins.y)) or math.pi * z.r * z.r
    local n, painted = math.Clamp(math.floor(area / 9000), 24, 180), 0
    local world = game.GetWorld()
    for _ = 1, n do
        local p = LCZ.RandomInside(z, 0.95)
        local tr = util.TraceLine({ start = p + Vector(0, 0, 120), endpos = p - Vector(0, 0, 300), mask = MASK_SOLID_BRUSHONLY })
        if tr.Hit and tr.HitWorld and tr.HitNormal.z > 0.6 then
            local scorch = #scorchMats > 0 and (#stainMats == 0 or math.random() < 0.3)
            local m = scorch and scorchMats[math.random(#scorchMats)] or stainMats[math.random(#stainMats)]
            local s = scorch and math.Rand(3, 6) or math.Rand(4, 8)
            util.DecalEx(m, world, tr.HitPos, tr.HitNormal, scorch and SCORCH_COL or STAIN_COL, s, s)
            painted = painted + 1
        end
    end
    return painted
end

-- Each patch once, as it turns up (the server sends the territory as it changes).
timer.Create("LivingCityInfestStains", 2, 0, function()
    if not cvOn:GetBool() then return end
    for _, z in ipairs(LC_CL.territory or {}) do
        if z.kind == "infest" then
            local key = string.format("%d_%d_%d_%d", math.floor(z.pos.x), math.floor(z.pos.y), math.floor(z.pos.z), math.floor(z.r))
            if not stained[key] then
                stained[key] = true
                local ok, err = pcall(LC_CL.StainZone, z)
                if not ok then print("[Living City] infestation stains: " .. tostring(err)) end
            end
        end
    end
end)
