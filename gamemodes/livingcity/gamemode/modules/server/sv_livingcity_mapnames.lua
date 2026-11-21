--[[
    Living City: names the map modules give the game (docs/dev/canal-modules.md; TODO: "nothing uses the
    names the modules give the game yet"). On a map without them nothing here happens.

      lc_sludge_gas        a trigger filling the sludge tunnel's air: "a place for gas masks". Its box
                           is foul air, as a gas cloud is (sv_livingcity_crafting.lua), for as long as
                           the map stands: a gas mask in your pockets goes on by itself, and without one
                           you cough and are hurt; people and units' NPCs get out of it.
      lc_substation_cut    the relay the substation's fuse panel fires when broken (the map stops its
                           hum, puts out its lamps, throws sparks): the district's transformer goes
                           down with it (sv_livingcity_power.lua), as a sabotage would, by whoever
                           broke the panel.
    (The walled garden's lc_garden_plot_N: sv_livingcity_garden.lua.)
]]

if CLIENT then return end

LC = LC or {}
LC.MapNames = LC.MapNames or { gas = {} }
local M = LC.MapNames

-- The map's own gas: one cloud the shape of each lc_sludge_gas trigger, kept while it stands.
function LC.MapGasEnsure()
    if not LC.GasClouds then return 0 end
    local n = 0
    for _, e in ipairs(ents.FindByName("lc_sludge_gas")) do
        if IsValid(e) then
            local g = M.gas[e]
            if not g or not table.HasValue(LC.GasClouds, g) then
                local lo, hi
                if e.WorldSpaceAABB then lo, hi = e:WorldSpaceAABB() end
                if not (lo and hi) then
                    local p, mins, maxs = e:GetPos(), e:OBBMins(), e:OBBMaxs()
                    lo, hi = p + mins, p + maxs
                end
                g = { pos = (lo + hi) * 0.5, r = (hi - lo):Length() * 0.5, box = { lo, hi }, untilT = math.huge, map = "lc_sludge_gas" }
                LC.GasClouds[#LC.GasClouds + 1] = g
                M.gas[e] = g
            end
            n = n + 1
        end
    end
    return n
end
timer.Create("LivingCityMapGas", 10, 0, function() LC.Try(LC.MapGasEnsure) end)
hook.Add("InitPostEntity", "LivingCityMapGas", function() timer.Simple(2, function() LC.Try(LC.MapGasEnsure) end) end)
hook.Add("PostCleanupMap", "LivingCityMapGas", function() M.gas = {} end)

-- The substation's panel broken: its district's transformer goes down.
function LC.SubstationCut(relay, by)
    if not (IsValid(relay) and LC.FeederOf and LC.TransformerDown) then return false end
    local t = LC.FeederOf(relay:GetPos())
    if not IsValid(t) then return false end
    return LC.TransformerDown(t, IsValid(by) and by:IsPlayer() and by or nil, "substation")
end

hook.Add("AcceptInput", "LivingCityMapNames", function(ent, input, activator, caller)
    if not IsValid(ent) or string.lower(input or "") ~= "trigger" then return end
    if (ent.GetName and ent:GetName() or "") ~= "lc_substation_cut" then return end
    local by = (IsValid(activator) and activator:IsPlayer() and activator) or (IsValid(caller) and caller:IsPlayer() and caller) or nil
    LC.Try(LC.SubstationCut, ent, by)
end)
