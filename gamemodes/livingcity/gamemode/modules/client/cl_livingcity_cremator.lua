--[[
    Living City: the Cremator's flame

    A Cremator (sv_livingcity_cremator.lua) is a prop_dynamic marked
    "lc_cremator"; while it burns something, "lc_flame_to" is what. The stream
    is drawn here: flame sprites thrown from its nozzle to the target, tinted
    the Immolator's green, and a light.
]]

if SERVER then return end

LC_CL = LC_CL or {}

local found, nextScan = {}, 0
local emitter
local NOZZLES = { "muzzle", "flame", "nozzle", "immolator", "weapon", "anim_attachment_RH" }

-- Where the flame leaves it: one of the model's attachments, or about where the hands are.
function LC_CL.CrematorNozzle(e)
    local id = e.lcNozzle
    if id == nil then
        id = false
        for _, n in ipairs(NOZZLES) do
            local a = e.LookupAttachment and e:LookupAttachment(n)
            if a and a > 0 then id = a break end
        end
        e.lcNozzle = id
    end
    if id then
        local a = e:GetAttachment(id)
        if a and a.Pos then return a.Pos end
    end
    return e:GetPos() + e:GetForward() * 34 + Vector(0, 0, 50)
end

function LC_CL.CrematorFlame(e, to, now)
    if (e.lcNextPuff or 0) > now then return end
    e.lcNextPuff = now + 0.03
    local from = LC_CL.CrematorNozzle(e)
    local dir = to:WorldSpaceCenter() - from
    local dist = dir:Length()
    if dist < 1 then return end
    dir:Normalize()
    if not emitter and ParticleEmitter then emitter = ParticleEmitter(from) end
    if emitter then
        for _ = 1, 3 do
            local p = emitter:Add("particles/flamelet" .. math.random(1, 5), from)
            if p then
                p:SetVelocity(dir * (dist / 0.45) + VectorRand() * 30)
                p:SetDieTime(0.45 + math.Rand(0, 0.15))
                p:SetStartAlpha(230)
                p:SetEndAlpha(0)
                p:SetStartSize(4)
                p:SetEndSize(26)
                p:SetRoll(math.Rand(0, 360))
                p:SetRollDelta(math.Rand(-2, 2))
                p:SetColor(160, 255, 140)
                p:SetGravity(Vector(0, 0, 40))
                p:SetAirResistance(40)
            end
        end
    end
    local dl = DynamicLight and DynamicLight(e:EntIndex())
    if dl then
        dl.pos = from + dir * (dist * 0.5)
        dl.r, dl.g, dl.b = 120, 255, 110
        dl.brightness = 2
        dl.Decay = 800
        dl.Size = 220
        dl.DieTime = now + 0.15
    end
end

hook.Add("Think", "LivingCityCrematorFlame", function()
    local now = CurTime()
    if now >= nextScan then
        nextScan = now + 1
        found = {}
        for _, e in ipairs(ents.FindByClass("prop_dynamic")) do
            if e:GetNW2Bool("lc_cremator", false) then found[#found + 1] = e end
        end
    end
    for _, e in ipairs(found) do
        if IsValid(e) and not e:IsDormant() then
            local to = e:GetNW2Entity("lc_flame_to")
            if IsValid(to) then LC_CL.CrematorFlame(e, to, now) end
        end
    end
end)
