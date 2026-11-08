--[[
    Living City (client): a shot-up Resistance lab smokes, and a wrecked one sparks

    Each blown part of the bench (lc_lab_dmg, 0 to 3) trails smoke; wrecked (lc_lab_broken),
    it smokes thick and spits sparks until it's repaired. The server side is
    sv_livingcity_labdamage.lua.
]]

LC_CL = LC_CL or {}

local benches, nextScan, nextPuff = {}, 0, 0
local emitter
local SPOTS = { 0.25, 0.75, 0.5 } -- (where along the bench each part was: the same as the server's)

local function PartPos(b, i)
    local mins, maxs = b:OBBMins(), b:OBBMaxs()
    return b:LocalToWorld(Vector((mins.x + maxs.x) / 2, mins.y + (maxs.y - mins.y) * (SPOTS[i] or 0.5), maxs.z))
end

-- (made once here, not every frame)
local V_0_0_12 = Vector(0, 0, 12)
hook.Add("Think", "LivingCityLabSmoke", function()
    local now = CurTime()
    if now >= nextScan then
        nextScan = now + 2
        benches = {}
        for _, e in ipairs(ents.FindByClass("lc_workbench")) do
            if IsValid(e) and e:GetNW2Int("lc_lab_dmg", 0) > 0 then benches[#benches + 1] = e end
        end
    end
    if #benches == 0 or now < nextPuff or not ParticleEmitter then return end
    nextPuff = now + 0.15
    local eye = EyePos()
    for _, b in ipairs(benches) do
        if IsValid(b) and b:GetPos():DistToSqr(eye) < 2500 * 2500 then
            local dmg, broken = b:GetNW2Int("lc_lab_dmg", 0), b:GetNW2Bool("lc_lab_broken", false)
            if not emitter then emitter = ParticleEmitter(b:GetPos()) end
            if emitter then
                if emitter.SetPos then emitter:SetPos(b:GetPos()) end
                for i = 1, math.min(3, dmg) do
                    local pos = PartPos(b, i)
                    local p = emitter:Add("particle/particle_smokegrenade", pos + Vector(math.Rand(-6, 6), math.Rand(-6, 6), 2))
                    if p then
                        p:SetVelocity(Vector(math.Rand(-8, 8), math.Rand(-8, 8), math.Rand(30, 60)))
                        p:SetDieTime(math.Rand(2.5, 4))
                        p:SetStartAlpha(broken and 170 or 90)
                        p:SetEndAlpha(0)
                        p:SetStartSize(broken and 10 or 6)
                        p:SetEndSize(broken and 64 or 34)
                        p:SetColor(55, 55, 55)
                        p:SetRoll(math.Rand(0, 360))
                        p:SetRollDelta(math.Rand(-0.5, 0.5))
                        p:SetAirResistance(30)
                        p:SetGravity(V_0_0_12)
                    end
                end
            end
            -- wrecked: now and then, sparks off the broken kit
            if broken and math.random() < 0.1 and EffectData then
                local pos = PartPos(b, math.random(1, 3))
                local fx = EffectData()
                fx:SetOrigin(pos)
                fx:SetMagnitude(2)
                fx:SetScale(1)
                util.Effect("ElectricSpark", fx)
                sound.Play("ambient/energy/spark" .. math.random(1, 6) .. ".wav", pos, 65, 100, 0.6)
            end
        end
    end
end)
