--[[
    Living City (shared): broken feet. Someone the city has crippled in custody
    can't run (sv_livingcity_custody.lua); the limit is applied on both sides so
    movement stays smooth.
]]


hook.Add("SetupMove", "LivingCityCrippled", function(ply, mv)
    if ply:GetNW2Float("lc_crippled_until", 0) <= CurTime() then return end
    local walk = ply:GetWalkSpeed()
    if mv:GetMaxClientSpeed() > walk then mv:SetMaxClientSpeed(walk) end
    if mv:GetMaxSpeed() > walk then mv:SetMaxSpeed(walk) end
    if mv:KeyDown(IN_SPEED) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_SPEED))) end
end)

-- Hauling a body (sv_livingcity_mortuary.lua): a slow walk, no running.
hook.Add("SetupMove", "LivingCityHauling", function(ply, mv)
    if not ply:GetNW2Bool("lc_hauling", false) then return end
    local slow = ply:GetWalkSpeed() * 0.75
    if mv:GetMaxClientSpeed() > slow then mv:SetMaxClientSpeed(slow) end
    if mv:GetMaxSpeed() > slow then mv:SetMaxSpeed(slow) end
    if mv:KeyDown(IN_SPEED) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_SPEED))) end
end)

-- Too tired to run (sv_livingcity_rest.lua): no sleep in a whole day.
hook.Add("SetupMove", "LivingCityTired", function(ply, mv)
    if not ply:GetNW2Bool("lc_tired", false) then return end
    local walk = ply:GetWalkSpeed()
    if mv:GetMaxClientSpeed() > walk then mv:SetMaxClientSpeed(walk) end
    if mv:GetMaxSpeed() > walk then mv:SetMaxSpeed(walk) end
    if mv:KeyDown(IN_SPEED) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_SPEED))) end
end)

-- Dazed by a stun baton (sv_livingcity_prison.lua): a stumbling walk for a few seconds.
hook.Add("SetupMove", "LivingCityDazed", function(ply, mv)
    if ply:GetNW2Float("lc_dazed_until", 0) <= CurTime() then return end
    local slow = ply:GetWalkSpeed() * 0.6
    if mv:GetMaxClientSpeed() > slow then mv:SetMaxClientSpeed(slow) end
    if mv:GetMaxSpeed() > slow then mv:SetMaxSpeed(slow) end
    if mv:KeyDown(IN_SPEED) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_SPEED))) end
end)

-- Struggling against an arrest (sv_livingcity_arrest.lua): held where you stand till it's decided.
hook.Add("SetupMove", "LivingCityStruggle", function(ply, mv)
    if ply:GetNW2Float("lc_struggle_until", 0) <= CurTime() then return end
    mv:SetMaxClientSpeed(1)
    mv:SetMaxSpeed(1)
end)
