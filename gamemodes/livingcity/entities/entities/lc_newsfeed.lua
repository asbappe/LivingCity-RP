--[[
    News feed (Living City). Place it with the Living City Editor:
      "Fixture: Civil Protection incident feed"  a Combine monitor scrolling what
                                                 was formally reported: arrests,
                                                 reports received, units attacked
      "Fixture: Resistance notice board"         a board of what the cell's own
                                                 people have seen and heard
    What's on them comes from the chronicle (sv_livingcity_chronicle.lua,
    LC.ChronicleFeeds); cl_livingcity_feeds.lua draws it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "News feed"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

-- The first model this install has is used.
local KINDS = {
    cpfeed     = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 1.6 },
    rebelboard = { models = { "models/props_lab/corkboard001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 1 },
}

function ENT:Initialize()
    if CLIENT then return end
    local kind = KINDS[self.lcFixtureKind or ""] and self.lcFixtureKind or "cpfeed"
    local k = KINDS[kind]
    local m
    for _, c in ipairs(k.models) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or k.models[#k.models])
    self:SetNW2String("lc_feed_kind", kind)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if k.scale ~= 1 then self:SetModelScale(k.scale, 0) end
end

if CLIENT then
    -- The picture is drawn 640 x 360 around its centre, just off a face of the model.
    -- yaw: which face (0 the model's front, 180 its back, 90 and 270 its sides).
    local function Place(self, yaw, fill)
        local mins, maxs = self:GetModelBounds()
        local k = self:GetModelScale() or 1
        mins, maxs = mins * k, maxs * k
        local c = (mins + maxs) / 2
        local alongX = yaw == 0 or yaw == 180
        local half = alongX and (maxs.x - mins.x) / 2 or (maxs.y - mins.y) / 2
        local wide = alongX and (maxs.y - mins.y) or (maxs.x - mins.x)
        local tall = maxs.z - mins.z
        local r = math.rad(yaw)
        local n = Vector(math.cos(r), math.sin(r), 0)
        local scale = math.min(wide * fill / 640, tall * fill / 360)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), yaw + 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        return self:LocalToWorld(c + n * (half + 0.6)), ang, scale
    end

    function ENT:Draw()
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 900 * 900 then return end
        if not (LC_CL and LC_CL.DrawFeed) then return end
        local kind = self:GetNW2String("lc_feed_kind", "cpfeed")
        -- the monitor has one glass, at its front; a board is flat, so both of its broad faces
        -- (whichever way the model was made, one is against the wall)
        local faces = { 0 }
        if kind == "rebelboard" then
            local mins, maxs = self:GetModelBounds()
            faces = (maxs.x - mins.x) <= (maxs.y - mins.y) and { 0, 180 } or { 90, 270 }
        end
        for _, yaw in ipairs(faces) do
            local pos, ang, scale = Place(self, yaw, kind == "rebelboard" and 0.92 or 0.8)
            cam.Start3D2D(pos, ang, scale)
                LC_CL.DrawFeed(kind)
            cam.End3D2D()
        end
    end
end
