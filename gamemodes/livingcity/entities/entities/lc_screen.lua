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

    -- The station screen shows one thing only (the owner, 21 November): the scanner's picture of the Administrator or
    -- the Director of Propaganda on air (cl_livingcity_livecam.lua), cut to its tall shape round their face, as Valve's
    -- shows Breen. No written broadcasts, no pirates: otherwise its glass is dark.
    -- Valve's look (the owner, 23 November: "it's just a curved black brush ... where is the effect of the combine
    -- hologram screen?"). Valve's jumbotron (d1_trainstation_01) is six func_monitor sheets 1 unit apart, each faced
    -- with dev/dev_combinemonitor_3 in front (the Combine monitor: a camera's picture under its scanlines) and
    -- dev/dev_combinemonitor_b behind, its edges nodraw. Garry's Mod has both materials: each is copied here as it is,
    -- fed our picture instead of Valve's camera (_rt_Camera), and its second texture scrolled as Valve's proxy would.
    -- With nobody on air the sheets glow the Combine's dim blue under the scanlines; dark only with the power out.
    local OFF = Material("tools/toolsblack")
    local LAYERS, LAYER_GAP = 6, 1
    local CROP = (184 / 321) / (16 / 9) -- (how much of the 16:9 picture's width the tall screen shows)
    local function CopyOf(name, src)
        local m = Material(src)
        if not m or m:IsError() or not CreateMaterial then return nil end
        local c = CreateMaterial(name, (string.gsub(m:GetShader() or "UnlitTwoTexture", "_[Dd][Xx]%d+$", "")), {})
        if not c then return nil end
        for k, v in pairs(m:GetKeyValues() or {}) do
            local t = type(v)
            if t == "ITexture" then c:SetTexture(k, v)
            elseif t == "number" then if math.floor(v) == v then c:SetInt(k, v) else c:SetFloat(k, v) end
            elseif t == "Vector" then c:SetVector(k, v)
            elseif t == "VMatrix" then c:SetMatrix(k, v)
            elseif t == "string" then c:SetString(k, v) end
        end
        if c.Recompute then c:Recompute() end
        return c
    end
    local mats -- { front, back, idle texture, refilled at }
    local function Mats()
        if mats ~= nil then return mats or nil end
        mats = false
        local front, back = CopyOf("lc_station_front", "dev/dev_combinemonitor_3"), CopyOf("lc_station_back", "dev/dev_combinemonitor_b")
        local idle = GetRenderTarget and GetRenderTarget("lc_station_idle", 16, 16)
        if not front or not idle then return nil end
        mats = { front = front, back = back or front, idle = idle, filled = 0 }
        return mats
    end
    local IDLE = Color(10, 34, 46) -- (the Combine's blue, dim: six sheets of it add up)
    local function Feed(m, pic)
        local now = CurTime()
        if not pic and now >= m.filled then -- (a render target can be lost with the window: filled again now and then)
            render.PushRenderTarget(m.idle)
            render.Clear(IDLE.r, IDLE.g, IDLE.b, 255, true, true)
            render.PopRenderTarget()
            m.filled = now + 5
        end
        local tex = pic and pic:GetTexture("$basetexture") or m.idle
        local scroll = Matrix and Matrix()
        if scroll then scroll:Translate(Vector(0, (now * 0.12) % 1, 0)) end
        for _, mat in ipairs({ m.front, m.back }) do
            mat:SetTexture("$basetexture", tex)
            if scroll and mat:GetTexture("$texture2") then mat:SetMatrix("$texture2transform", scroll) end
        end
    end
    local function OfficialPicture()
        if GetGlobal2Bool("lc_live_pirate", false) or not LC_CL or not LC_CL.LiveCamPicture then return nil end
        return LC_CL.LiveCamPicture()
    end
    local function Quad(a, b, c, d, n, ua, ub, va, vb)
        for _, q in ipairs({ { a, ua, va }, { b, ub, va }, { c, ub, vb }, { d, ua, vb } }) do
            mesh.Position(q[1])
            mesh.Normal(n)
            mesh.TexCoord(0, q[2], q[3])
            mesh.AdvanceVertex()
        end
    end
    -- One sheet, dx toward the viewer (0 the front, -5 the back), facing them (or, back = true, away from them).
    local function Sheet(dx, back, u0, umax, v1)
        local n = #STATION - 1
        local fwd = Vector(back and -1 or 1, 0, 0)
        mesh.Begin(MATERIAL_QUADS, n)
        for i = 1, n do
            local a, b = STATION[i], STATION[i + 1]
            local ua, ub = u0 + umax * CROP * (92 - a[1]) / 184, u0 + umax * CROP * (92 - b[1]) / 184
            local ta, tb, fa, fb = Vector(a[4] + dx, a[1], a[5]), Vector(b[4] + dx, b[1], b[5]), Vector(a[2] + dx, a[1], a[3]), Vector(b[2] + dx, b[1], b[3])
            if back then Quad(tb, ta, fa, fb, fwd, ub, ua, 0, v1) else Quad(ta, tb, fb, fa, fwd, ua, ub, 0, v1) end
        end
        mesh.End()
    end
    local function DrawStation(self, live, near)
        cam.PushModelMatrix(self:GetWorldTransformMatrix())
        local m = live and Mats()
        if not m then
            -- the power out (or Valve's material missing): a dead, dark screen
            render.SetMaterial(OFF)
            Sheet(0, false, 0, 1, 1)
            Sheet(-(LAYERS - 1) * LAYER_GAP, true, 0, 1, 1)
        else
            local pic, umax, vmax
            if near then pic, umax, vmax = OfficialPicture() end -- (from afar, the glow alone)
            Feed(m, pic)
            umax, vmax = umax or 1, vmax or 1
            local u0 = umax * (0.5 - CROP / 2)
            render.SetMaterial(m.front)
            for i = LAYERS - 1, 0, -1 do Sheet(-i * LAYER_GAP, false, u0, umax, vmax) end -- (back to front)
            render.SetMaterial(m.back)
            Sheet(-(LAYERS - 1) * LAYER_GAP, true, u0, umax, vmax)
        end
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
            DrawStation(self, not self:GetNW2Bool("lc_nopower", false), near)
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
