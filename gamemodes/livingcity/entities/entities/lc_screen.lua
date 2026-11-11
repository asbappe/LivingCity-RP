--[[
    City screen (Living City). Place it with the Living City Editor ("Fixture:
    city screen"). Shows the City Administrator's latest broadcast.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "City screen"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- Three sizes (the editor's fixture kinds): the Combine's own monitors for the
-- wall screen and the giant Breencast screen (the ones over the station and the
-- plaza), and an apartment's little TV. The first model this install has is used.
local SIZES = {
    screen     = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 1.6 },
    screen_big = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 5 },
    tv         = { models = { "models/props_c17/tv_monitor01.mdl" }, scale = 1 },
}

function ENT:Initialize()
    if CLIENT then return end
    local kind = self.lcFixtureKind or "screen"
    local sz = SIZES[kind] or SIZES.screen
    local m
    for _, c in ipairs(sz.models) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or sz.models[#sz.models])
    self:SetNW2String("lc_screen_kind", kind)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if sz.scale ~= 1 then self:SetModelScale(sz.scale, 0) end
end

if CLIENT then
    -- Where the picture goes: the glass of each model, as fractions of its front
    -- face (centre across from the viewer's left, centre up from the bottom,
    -- how wide, how tall), then how far in front of the model's frontmost point
    -- (the TV's glass sits back behind its frame), and whether the picture is
    -- stretched to fill the glass rather than kept 16:9. The apartment TV's glass
    -- is off to the left, with its speaker and buttons on the right. The picture
    -- is drawn 640 x 360.
    local GLASS = {
        ["models/props_c17/tv_monitor01.mdl"] = { 0.40, 0.55, 0.70, 0.76, -1.2, true },
    }
    local DEFAULT = { 0.5, 0.5, 0.8, 0.8 }
    local function Place(self)
        local mins, maxs = self:GetModelBounds()
        local k = self:GetModelScale() or 1
        mins, maxs = mins * k, maxs * k
        local g = GLASS[string.lower(self:GetModel() or "")] or DEFAULT
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        local sx, sy = wide * g[3] / 640, tall * g[4] / 360
        local scale = math.min(sx, sy)
        local stretch = g[6] and sy / sx or nil -- (taller than it would be at 16:9)
        if stretch then scale = sx end
        return self:LocalToWorld(Vector(maxs.x + (g[5] or 0.5), mins.y + wide * g[1], mins.z + tall * g[2])), scale, stretch
    end

    function ENT:Draw()
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end -- the district's power is out (sv_livingcity_power.lua): a dead screen
        local kind = self:GetNW2String("lc_screen_kind", "screen")
        local far = kind == "screen_big" and 3500 or (kind == "tv" and 700 or 1200)
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > far * far then return end
        if LC_CL and LC_CL.DrawCityScreen then
            local pos, scale, stretch = Place(self)
            local ang = self:GetAngles()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)
            cam.Start3D2D(pos, ang, scale)
                local m = stretch and Matrix and cam.PushModelMatrix and Matrix()
                if m then
                    m:Scale(Vector(1, stretch, 1))
                    cam.PushModelMatrix(m, true)
                end
                LC_CL.DrawCityScreen(self)
                if m then cam.PopModelMatrix() end
            cam.End3D2D()
        end
    end
end
