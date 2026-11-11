--[[
    Living City: the rope a stalker tows a body on

    A stalker dragging a body out of a Combine zone (sv_livingcity_zonestalkers.lua)
    marks it "lc_roped_to" itself. Drawn here: a rope from the stalker's hand
    to the body's chest, sagging a little (the owner, 11 November: "a rope
    effect tied between the stalker's hand and the dead body").
]]

if SERVER then return end

LC_CL = LC_CL or {}

local ROPE = Material("cable/rope")
local HANDS = { "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand" }
local found, nextScan = {}, 0

local function Hand(npc)
    for _, name in ipairs(HANDS) do
        local b = npc.LookupBone and npc:LookupBone(name)
        local pos = b and npc:GetBonePosition(b)
        if pos and pos ~= npc:GetPos() then return pos end
    end
    return npc:GetPos() + Vector(0, 0, 36)
end

-- The rope's points from a to b: a shallow sag in the middle.
function LC_CL.DragRopePoints(a, b, n)
    n = n or 8
    local out = {}
    local sag = math.min(14, a:Distance(b) * 0.12)
    for i = 0, n do
        local f = i / n
        out[#out + 1] = a + (b - a) * f - Vector(0, 0, math.sin(f * math.pi) * sag)
    end
    return out
end

hook.Add("PostDrawOpaqueRenderables", "LivingCityDragRope", function(depth, sky)
    if depth or sky then return end
    local now = CurTime()
    if now >= nextScan then
        nextScan = now + 1
        found = {}
        for _, e in ipairs(ents.FindByClass("prop_ragdoll")) do
            if IsValid(e:GetNW2Entity("lc_roped_to")) then found[#found + 1] = e end
        end
    end
    for _, body in ipairs(found) do
        local npc = IsValid(body) and body:GetNW2Entity("lc_roped_to")
        if npc and IsValid(npc) and not npc:IsDormant() and not body:IsDormant() then
            local pts = LC_CL.DragRopePoints(Hand(npc), body:WorldSpaceCenter())
            render.SetMaterial(ROPE)
            render.StartBeam(#pts)
            for i, p in ipairs(pts) do render.AddBeam(p, 1.6, i * 0.6, Color(255, 255, 255, 255)) end
            render.EndBeam()
        end
    end
end)
