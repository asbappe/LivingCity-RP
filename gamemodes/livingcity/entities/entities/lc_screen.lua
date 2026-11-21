--[[
    City screen (Living City). Place it with the Living City Editor ("Street:
    Breencast screen, small"). Shows the City Administrator's latest broadcast.
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

-- Four sizes (the editor's fixture kinds): the Combine's own monitors for the
-- wall screen, the giant Breencast screen (the ones over the station and the
-- plaza) and the medium one (half the giant, for indoors), and an apartment's little TV. The first model this install has is used.
local SIZES = {
    screen     = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 1.6 },
    screen_big = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 5 },
    -- (the owner, 14 November: "a medium breencast screen that is 1/2 the size and much lower. I can't place
    -- the giant one inside any buildings, even this giant administrator's office")
    screen_mid = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 2.5 },
    tv         = { models = { "models/props_c17/tv_monitor01.mdl" }, scale = 1 },
    -- (the owner, 21 November: the giant screen at the start of Valve's train station, as an editor entry) Valve's
    -- own shape, no model: a curved screen of 13 strips, 184 wide and 321 tall, leaning forward at the top
    screen_station = { models = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }, scale = 1, station = true },
}

ENT.ScreenSizes = SIZES

-- The station screen's strips, read from Valve's d1_trainstation_01 (monitor_breencast_jumbotron3): for each of the
-- 14 edges between strips, across (y), the foot's depth and height (x, z) and the top's. The origin is the foot of
-- the middle; +x is toward whoever watches. It is 6 thick (Valve's six layers).
local STATION = {
    { 92.0, -27.1, 6.4, 70.2, 327.5 }, { 77.9, -19.3, 4.6, 78.0, 325.7 }, { 63.7, -13.5, 3.2, 83.8, 324.3 },
    { 49.5, -7.8, 1.8, 89.6, 323.0 }, { 35.4, -3.9, 0.9, 93.4, 322.0 }, { 21.2, -2.0, 0.5, 95.4, 321.6 },
    { 7.1, 0, 0, 97.3, 321.1 }, { -7.1, 0, 0, 97.3, 321.1 }, { -21.2, -2.0, 0.5, 95.4, 321.6 },
    { -35.4, -3.9, 0.9, 93.4, 322.0 }, { -49.5, -7.8, 1.8, 89.6, 323.0 }, { -63.7, -13.5, 3.2, 83.8, 324.3 },
    { -77.9, -19.3, 4.6, 78.0, 325.7 }, { -92.0, -27.1, 6.4, 70.2, 327.5 },
}
local STATION_THICK = 6
local STATION_MINS, STATION_MAXS = Vector(-34, -93, -1), Vector(98, 93, 328)
ENT.StationStrips = STATION

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
    if sz.station and self.PhysicsInitBox then      -- (no model of its own: a box round the strips to stand in for it)
        self:PhysicsInitBox(STATION_MINS, STATION_MAXS)
        self:SetCollisionBounds(STATION_MINS, STATION_MAXS)
        self:SetMoveType(MOVETYPE_NONE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        return
    end
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

    -- The station screen: the broadcast is drawn into a tall picture (a render target) a few times a second, and the
    -- strips show it, so it bends round the curve as Valve's does.
    local stationMat, stationRT, stationAt, stationEnt
    local BACK = Material("models/props_combine/metal_combinebridge001")
    local function StationPicture()
        if stationMat ~= nil then return stationMat end
        if not (GetRenderTarget and CreateMaterial) then stationMat = false return false end
        stationRT = GetRenderTarget("lc_station_screen", 512, 1024)
        stationMat = CreateMaterial("lc_station_screen", "UnlitGeneric", { ["$basetexture"] = stationRT:GetName() })
        return stationMat
    end
    hook.Add("PreRender", "LivingCityStationScreen", function()
        local e = stationEnt
        if not (IsValid(e) and stationRT and LC_CL and LC_CL.DrawCityScreen) or CurTime() - (stationAt or 0) < 0.1 then return end
        stationAt = CurTime()
        render.PushRenderTarget(stationRT)
        render.Clear(10, 14, 18, 255)
        cam.Start2D()
            local m = Matrix()
            m:Translate(Vector(256, 512, 0))
            m:Scale(Vector(0.8, 0.8, 1))
            cam.PushModelMatrix(m)
            LC_CL.DrawCityScreen(e)
            cam.PopModelMatrix()
        cam.End2D()
        render.PopRenderTarget()
    end)
    local function Quad(a, b, c, d, n, ua, ub, va, vb)
        for _, q in ipairs({ { a, ua, va }, { b, ub, va }, { c, ub, vb }, { d, ua, vb } }) do
            mesh.Position(q[1])
            mesh.Normal(n)
            mesh.TexCoord(0, q[2], q[3])
            mesh.AdvanceVertex()
        end
    end
    local function DrawStation(self, live)
        local n = #STATION - 1
        local fwd = Vector(1, 0, 0)
        cam.PushModelMatrix(self:GetWorldTransformMatrix())
        -- the glass: the picture when live, else the dark metal of its back
        local pic = live and StationPicture()
        if pic then stationEnt = self end
        render.SetMaterial(pic or BACK)
        mesh.Begin(MATERIAL_QUADS, n)
        for i = 1, n do
            local a, b = STATION[i], STATION[i + 1]
            local ua, ub = (92 - a[1]) / 184, (92 - b[1]) / 184
            Quad(Vector(a[4], a[1], a[5]), Vector(b[4], b[1], b[5]), Vector(b[2], b[1], b[3]), Vector(a[2], a[1], a[3]), fwd, ua, ub, 0, 1)
        end
        mesh.End()
        -- its back, top, foot and ends
        local t = STATION_THICK
        render.SetMaterial(BACK)
        mesh.Begin(MATERIAL_QUADS, n * 3 + 2)
        for i = 1, n do
            local a, b = STATION[i], STATION[i + 1]
            Quad(Vector(b[4] - t, b[1], b[5]), Vector(a[4] - t, a[1], a[5]), Vector(a[2] - t, a[1], a[3]), Vector(b[2] - t, b[1], b[3]), -fwd, 0, 1, 0, 1)
            Quad(Vector(a[4] - t, a[1], a[5]), Vector(b[4] - t, b[1], b[5]), Vector(b[4], b[1], b[5]), Vector(a[4], a[1], a[5]), Vector(0, 0, 1), 0, 1, 0, 0.05)
            Quad(Vector(a[2], a[1], a[3]), Vector(b[2], b[1], b[3]), Vector(b[2] - t, b[1], b[3]), Vector(a[2] - t, a[1], a[3]), Vector(0, 0, -1), 0, 1, 0, 0.05)
        end
        for _, c in ipairs({ { STATION[1], 1 }, { STATION[#STATION], -1 } }) do
            local a, sgn = c[1], c[2]
            Quad(Vector(a[4] - t, a[1], a[5]), Vector(a[4], a[1], a[5]), Vector(a[2], a[1], a[3]), Vector(a[2] - t, a[1], a[3]), Vector(0, sgn, 0), 0, 0.05, 0, 1)
        end
        mesh.End()
        cam.PopModelMatrix()
    end

    function ENT:Think()
        if not self.lcBounds and self:GetNW2String("lc_screen_kind", "") == "screen_station" then
            self:SetRenderBounds(STATION_MINS, STATION_MAXS)
            self.lcBounds = true
        end
    end

    function ENT:Draw()
        if self:GetNW2String("lc_screen_kind", "screen") == "screen_station" then
            local near = LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 3500 * 3500
            DrawStation(self, near and not self:GetNW2Bool("lc_nopower", false))
            return
        end
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end -- the district's power is out (sv_livingcity_power.lua): a dead screen
        local kind = self:GetNW2String("lc_screen_kind", "screen")
        local far = kind == "screen_big" and 3500 or (kind == "screen_mid" and 2200 or (kind == "tv" and 700 or 1200))
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
