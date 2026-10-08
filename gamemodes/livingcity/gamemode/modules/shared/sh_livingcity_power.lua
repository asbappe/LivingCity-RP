--[[
    Living City (shared): who a Combine forcefield lets through

    Decided the same way on the server and on your own machine, from things
    both can see (whether you're a unit, in build mode, or just swiped a
    keycard), so walking into a field doesn't stutter. Units, and admins in
    build mode, walk through; a keycard swipe opens it for you for a few
    seconds; nobody else gets through while it's up. The infected (zombies,
    headcrabs) are stopped too; other NPCs and everything else aren't.
    (entities/lc_forcefield.lua, sv_livingcity_power.lua)
]]

LC = LC or {}

function LC.FieldPass(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if ply:GetNW2Bool("lc_unit", false) or ply:GetNW2Bool("lc_build", false) then return true end
    return ply:GetNW2Float("lc_ffpass_until", 0) > CurTime()
end

hook.Add("ShouldCollide", "LivingCityForcefield", function(a, b)
    local f, o
    if a.lcForcefield then f, o = a, b
    elseif b.lcForcefield then f, o = b, a
    else return end
    if not f.FieldUp or not f:FieldUp() then return false end
    if IsValid(o) and o:IsPlayer() then return not LC.FieldPass(o) end
    -- the infected don't get through either: a forcefield holds the infestation back
    if IsValid(o) and o:IsNPC() and LC.InfestedClass(o:GetClass()) then return true end
    return false
end)

function LC.InfestedClass(cls)
    return cls ~= nil and (string.find(cls, "zombie", 1, true) ~= nil or string.find(cls, "headcrab", 1, true) ~= nil)
end

-- The physics engine remembers the answer above for each pair, so whenever it
-- could change (a field loses power or is shorted, a pass is given or runs out,
-- someone becomes a unit or goes into build mode) it has to be told to ask again,
-- on both sides. A pass or a short that runs out is asked about again when it does.
local FIELD_VARS = { lc_nopower = true, lc_short_until = true, lc_ffpass_until = true, lc_unit = true, lc_build = true }

function LC.FieldRulesChanged(e)
    if IsValid(e) and e.CollisionRulesChanged then e:CollisionRulesChanged() end
end

hook.Add("EntityNetworkedVarChanged", "LivingCityForcefield", function(e, name, old, new)
    if not FIELD_VARS[name] or not IsValid(e) then return end
    if not (e.lcForcefield or (e.IsPlayer and e:IsPlayer())) then return end
    -- (the new value isn't in place yet while this runs)
    timer.Simple(0, function() LC.FieldRulesChanged(e) end)
    if isnumber(new) and new > CurTime() then
        timer.Simple(new - CurTime() + 0.05, function() LC.FieldRulesChanged(e) end)
    end
end)
