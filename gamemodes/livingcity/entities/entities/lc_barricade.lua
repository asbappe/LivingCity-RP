--[[ Combine barricade (Living City): a section of the Combine's wall, for a
     checkpoint (around the infestation, say) or a gate. Placed with the editor
     ("Fixture: Combine barricade", low, medium or tall), facing you. Solid to
     everyone and everything, the infected included: put a forcefield in the
     gap. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine barricade"
ENT.Author = "Miscount"
ENT.Spawnable = false

-- The Combine's own walls, then anything that will stand in for them.
local MODELS = {
    barricade_low  = { "models/props_combine/combine_barricade_short01a.mdl", "models/props_combine/combine_barricade_short02a.mdl", "models/props_c17/concrete_barrier001a.mdl" },
    barricade      = { "models/props_combine/combine_barricade_med01a.mdl", "models/props_combine/combine_barricade_med02a.mdl",
                       "models/props_combine/combine_barricade_short01a.mdl", "models/props_c17/concrete_barrier001a.mdl" },
    barricade_tall = { "models/props_combine/combine_barricade_tall01a.mdl", "models/props_combine/combine_barricade_tall02a.mdl",
                       "models/props_combine/combine_barricade_med01a.mdl", "models/props_c17/concrete_barrier001a.mdl" },
}

function ENT:Initialize()
    if CLIENT then return end
    local list = MODELS[self.lcFixtureKind or "barricade"] or MODELS.barricade
    local m
    for _, c in ipairs(list) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or list[#list])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end
