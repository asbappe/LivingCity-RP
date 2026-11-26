--[[
    A live camera screen placed in the map (Living City). The forest bunker's door camera (the owner,
    25 November: by each emergency button that shuts the bunker's front doors, "an additional screen that has
    a camera showing from the inside of the bunker looking at the front doors so that if people press the
    button they can clearly see the doors are closing"; two screens live side by side, so this one is drawn
    by the gamemode: the map's own screens show only one camera at a time).

    In the map: a point entity of this class at the middle of the picture, its forward pointing out of the
    screen at the viewer, with keyvalues "camera" (the name of a marker, an info_target, placed where the
    camera sees from and turned the way it looks), "width" and "height" (the picture's size in units) and,
    if wanted, "fov" (75 unless given). Under any other gamemode the class does not exist: nothing else
    depends on it.

    Each picture draws the world a second time, so only a screen near you that you face from its front is
    live, a few pictures a second; the others show dark glass.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Camera screen"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.DefaultFov = 75

function ENT:KeyValue(k, v)
    k = string.lower(tostring(k or ""))
    if k == "camera" then
        self.lcCamName = tostring(v or "")
    elseif k == "width" then
        self.lcW = tonumber(v)
    elseif k == "height" then
        self.lcH = tonumber(v)
    elseif k == "fov" then
        self.lcFov = tonumber(v)
    end
end

-- Where its camera sees from and how it looks, from the marker the map names (it may spawn after the screen:
-- looked for again until found). True once found.
function ENT:FindCamera()
    if not self.lcCamName or self.lcCamName == "" then return false end
    local cam = ents.FindByName(self.lcCamName)[1]
    if not IsValid(cam) then return false end
    local a = cam:GetAngles()
    self:SetNW2Vector("lc_scr_cam", cam:GetPos())
    self:SetNW2Vector("lc_scr_camang", Vector(a.p, a.y, a.r))
    self:SetNW2Bool("lc_scr_live", true)
    return true
end

function ENT:Initialize()
    if CLIENT then
        if self.SetRenderBounds then self:SetRenderBounds(Vector(-8, -128, -128), Vector(8, 128, 128)) end
        return
    end
    self:SetNW2Float("lc_scr_w", self.lcW or 64)
    self:SetNW2Float("lc_scr_h", self.lcH or 48)
    self:SetNW2Float("lc_scr_fov", self.lcFov or 0)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    self.lcTries = 0
end

function ENT:Think()
    if CLIENT or self:GetNW2Bool("lc_scr_live", false) then return end
    self.lcTries = (self.lcTries or 0) + 1
    if self:FindCamera() or self.lcTries > 30 then
        self:NextThink(CurTime() + 3600)
        return true
    end
    self:NextThink(CurTime() + 1)
    return true
end

if CLIENT then
    LC_CL = LC_CL or {}
    local SIZE_W, SIZE_H = 512, 384 -- each picture's texture
    local NEAR = 900                -- only a screen this near is live for you
    local RATE = 10                 -- pictures a second, for each live screen
    local LIVE = 2                  -- screens live at once
    local SCALE = 0.1               -- drawn at ten texture pixels to a unit

    local rts, mats = {}, {}
    local drawing = false
    local lives, slotOf, shown = {}, {}, {}
    local nextFrame, turn = 0, 0

    local function Ensure(i)
        if mats[i] then return true end
        if not GetRenderTarget or not CreateMaterial then return false end
        local rt = GetRenderTarget("lc_cctvscreen_rt" .. i, SIZE_W, SIZE_H)
        if not rt then return false end
        local mat = CreateMaterial("lc_cctvscreen_mat" .. i, "UnlitGeneric", { ["$basetexture"] = rt:GetName(), ["$model"] = "0" })
        if not mat then return false end
        rts[i], mats[i] = rt, mat
        return true
    end

    local function Size(e)
        return math.max(e:GetNW2Float("lc_scr_w", 0), 1), math.max(e:GetNW2Float("lc_scr_h", 0), 1)
    end

    -- the screens live for you: near, found their camera, and you stand in front of them looking toward them
    local function Pick(eye, fwd)
        local found = {}
        for _, e in ipairs(ents.FindByClass("lc_cctv_screen")) do
            if IsValid(e) and e:GetNW2Bool("lc_scr_live", false) and not (e.IsDormant and e:IsDormant()) then
                local to = e:GetPos() - eye
                local d = to:LengthSqr()
                if d < NEAR * NEAR and to:Dot(fwd) > 0.3 * math.sqrt(d) and to:Dot(e:GetForward()) < 0 then
                    found[#found + 1] = { e = e, d = d }
                end
            end
        end
        table.sort(found, function(a, b) return a.d < b.d end)
        local out = {}
        for i = 1, math.min(LIVE, #found) do out[i] = found[i].e end
        return out
    end

    local function Assign(list)
        local keep, used = {}, {}
        for _, e in ipairs(list) do keep[e] = true if slotOf[e] then used[slotOf[e]] = true end end
        for e in pairs(slotOf) do if not keep[e] then slotOf[e], shown[e] = nil, nil end end
        for _, e in ipairs(list) do
            if not slotOf[e] then
                for i = 1, LIVE do if not used[i] then slotOf[e], shown[e], used[i] = i, nil, true break end end
            end
        end
    end

    -- One picture of a live screen's camera into its texture, before the scene is drawn, never inside
    -- another camera's picture (the camera's view draws the world again, screens and monitors and all).
    function LC_CL.CCTVScreenFeed(eye, ang)
        if drawing or LC_CL.LiveCamRendering or CurTime() < nextFrame then return false end
        lives = Pick(eye or EyePos(), (ang or EyeAngles()):Forward())
        Assign(lives)
        nextFrame = CurTime() + 1 / (RATE * math.max(1, #lives))
        if #lives == 0 then return false end
        turn = turn + 1
        local live = lives[(turn - 1) % #lives + 1]
        local i = slotOf[live]
        if not (i and Ensure(i)) then lives, slotOf, shown = {}, {}, {} return false end
        local at, a = live:GetNW2Vector("lc_scr_cam"), live:GetNW2Vector("lc_scr_camang") or Vector()
        local w, h = Size(live)
        local fov = live:GetNW2Float("lc_scr_fov", 0)
        drawing, LC_CL.LiveCamRendering = true, true
        local pushed = false
        local ok = LC.Try(function()
            render.PushRenderTarget(rts[i])
            pushed = true
            render.Clear(0, 0, 0, 255, true, true)
            render.RenderView({
                origin = at, angles = Angle(a.x, a.y, a.z), x = 0, y = 0, w = SIZE_W, h = SIZE_H,
                fov = fov > 0 and fov or live.DefaultFov or 75, aspectratio = w / h,
                drawviewmodel = false, drawviewer = true, drawhud = false, dopostprocess = false, drawmonitors = false,
            })
            render.PopRenderTarget()
            pushed = false
        end)
        if pushed then render.PopRenderTarget() end
        drawing, LC_CL.LiveCamRendering = false, false
        if not ok then lives, slotOf, shown = {}, {}, {} return false end
        shown[live] = true
        return true
    end
    LC_CL.CCTVScreensLive = function() return lives end

    hook.Add("RenderScene", "LivingCityCCTVScreens", function(eye, ang) LC_CL.CCTVScreenFeed(eye, ang) end)
    hook.Add("ShouldDrawLocalPlayer", "LivingCityCCTVScreens", function() if drawing then return true end end)

    function ENT:Draw()
        if drawing then return end -- (a screen in its own camera's picture shows nothing new)
        local w, h = Size(self)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        local pw, ph = w / SCALE, h / SCALE
        cam.Start3D2D(self:GetPos(), ang, SCALE)
        local i = slotOf[self]
        if i and shown[self] and mats[i] then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mats[i])
            surface.DrawTexturedRect(-pw / 2, -ph / 2, pw, ph)
        else
            surface.SetDrawColor(6, 12, 16, 255) -- (dark glass: not live for you)
            surface.DrawRect(-pw / 2, -ph / 2, pw, ph)
        end
        cam.End3D2D()
    end
end
