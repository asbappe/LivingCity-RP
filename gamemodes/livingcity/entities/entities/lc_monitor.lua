--[[
    Combine monitor (Living City). Place it with the Living City Editor
    ("Fixture: Combine monitor"), and the cameras it shows with "Point: Combine
    camera". A monitor shows what one camera sees; E steps it to the next
    camera, for everyone looking at it.

    Each live picture draws the world a second time, so only one monitor is
    live for you at a time: the nearest you face from its front. The others
    show no signal. In a blacked-out district it is dead, like the city screens.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine monitor"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- The one Combine monitor: the small one that hangs from an arm in Nova Prospekt (the editor's
-- "Fixture: Combine monitor", point kind monitor_hang). The wall monitor that came first is gone (the owner,
-- 15 November: "The model is wrong, just delete it and keep the hanging combine monitor entity as the only
-- one"; the hanging one "looks GREAT"). The first of these this install has is used: the wall models are
-- only there so an install without the small one never shows an error model.
local HANG = { "models/props_combine/combine_smallmonitor001.mdl", "models/props_combine/combine_intmonitor003.mdl",
    "models/props_combine/combine_intmonitor001.mdl" }
local SCALE = 1
-- A camera sees from this far above its point, tipped this far down, the way the point faces.
local CAM_UP, CAM_PITCH = 70, 15

ENT.MonitorModels = HANG
ENT.HangingModels = HANG

function ENT:Initialize()
    if CLIENT then return end
    local m
    local list = HANG
    for _, c in ipairs(list) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or list[1])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if SCALE ~= 1 then self:SetModelScale(SCALE, 0) end
    if LC and LC.MonitorTune then LC.MonitorTune(self) end -- (it starts on the camera nearest to it)
    -- (then the camera saved with the layout, once the spawner has said which point made it)
    timer.Simple(0, function() if IsValid(self) and LC and LC.MonitorRestore then LC.MonitorRestore(self) end end)
end

if SERVER then
    LC = LC or {}

    local WATCH = 800 -- a player this near a monitor is sent what its camera sees (the picture is live within 700)
    local CLICK = "buttons/lightswitch2.wav"

    -- The cameras, in the order they were placed (the editor's camera points).
    function LC.MonitorCameras()
        local out = {}
        for _, p in ipairs(LC.Points or {}) do
            if p.kind == "camera" then out[#out + 1] = p end
        end
        return out
    end

    -- Which camera a monitor shows: its number in that list and the point, or 0 and nil.
    function LC.MonitorCamera(e, cams)
        local p = IsValid(e) and e.lcCamPoint
        if not p then return 0, nil end
        for i, c in ipairs(cams or LC.MonitorCameras()) do
            if c == p then return i, c end
        end
        return 0, nil
    end

    -- Every viewer sees the same camera on a monitor: its number, and where it looks from.
    local function Show(e, i, p)
        e.lcCamPoint = p
        e.lcCamEye = p and (p.pos + Vector(0, 0, CAM_UP)) or nil
        e:SetNW2Int("lc_cam", p and i or 0)
        if p then
            e:SetNW2Vector("lc_cam_pos", e.lcCamEye)
            e:SetNW2Float("lc_cam_yaw", p.yaw or 0)
        end
    end

    -- A monitor keeps its camera for as long as that camera is there. With none
    -- (it is new, or its camera was taken away) it goes to the nearest one.
    -- No cameras on the map: no signal.
    function LC.MonitorTune(e, cams)
        if not IsValid(e) then return 0 end
        cams = cams or LC.MonitorCameras()
        local i, p = LC.MonitorCamera(e, cams)
        if not p then
            local at, bd = e:GetPos(), nil
            for n, c in ipairs(cams) do
                local d = c.pos:DistToSqr(at)
                if not bd or d < bd then i, p, bd = n, c, d end
            end
        end
        Show(e, i, p)
        return i
    end

    -- The camera a monitor is on is kept with the layout (the owner, 15 November: "yes please save with the
    -- layout"): its number in the cameras' list is the monitor point's own number (the "group" every point
    -- has), 0 for none chosen yet. True when it changed.
    local function Keep(e, i)
        local p = IsValid(e) and e.lcFixturePoint
        if not p or (p.group or 0) == (i or 0) then return false end
        p.group = i or 0
        return true
    end

    -- As it spawns: the camera its point remembers, if that camera is still there; else the nearest.
    function LC.MonitorRestore(e)
        if not IsValid(e) then return 0 end
        local p, cams = e.lcFixturePoint, LC.MonitorCameras()
        local n = p and (p.group or 0) or 0
        if n > 0 and cams[n] then
            Show(e, n, cams[n])
            return n
        end
        return LC.MonitorTune(e, cams)
    end

    local saving
    function LC.MonitorsRefresh()
        local cams = LC.MonitorCameras()
        local changed = false
        for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_monitor") or ents.FindByClass("lc_monitor")) do
            local i = LC.MonitorTune(e, cams)
            -- (a camera taken away earlier in the list moves the numbers: what is saved follows)
            if e.lcFixturePoint and (e.lcFixturePoint.group or 0) > 0 and Keep(e, i) then changed = true end
        end
        if changed and not saving and LC.SaveData then saving = true LC.SaveData() saving = false end
    end

    -- E: the next camera, and after the last the first again.
    function LC.MonitorStep(e)
        if not IsValid(e) or e:GetNW2Bool("lc_nopower", false) then return 0 end
        local cams = LC.MonitorCameras()
        if #cams == 0 then
            Show(e, 0, nil)
            return 0
        end
        local i = LC.MonitorCamera(e, cams) % #cams + 1
        Show(e, i, cams[i])
        e:EmitSound(CLICK, 55)
        if Keep(e, i) and LC.SaveData and not saving then saving = true LC.SaveData() saving = false end
        return i
    end

    -- E on it. Only a unit steps it for now (the owner, 15 November: "stepping cameras for CP only right
    -- now"); for anyone else it is locked: a sound, nothing said.
    function LC.MonitorUse(e, ply)
        if not (IsValid(e) and IsValid(ply) and ply:IsPlayer()) then return false end
        if not (LC.PlayerIsCP and LC.PlayerIsCP(ply)) then
            e:EmitSound("buttons/combine_button_locked.wav", 55)
            return false
        end
        return LC.MonitorStep(e) > 0
    end

    function ENT:Use(activator)
        if LC.MonitorUse then LC.MonitorUse(self, activator) end
    end

    -- A camera placed or taken away: no monitor is left pointing at nothing.
    hook.Add("LivingCityLayoutChanged", "LivingCityMonitors", function()
        local ok, err = LC.Try(LC.MonitorsRefresh)
        if not ok and LC.Error then LC.Error("monitors", err) end
    end)

    -- Whoever stands at a monitor also needs the people in its camera's room:
    -- that room joins their view of the world (as the broadcast camera's does).
    hook.Add("SetupPlayerVisibility", "LivingCityMonitors", function(ply)
        local list = LC.EntsOf and LC.EntsOf("lc_monitor") or {}
        if #list == 0 then return end
        local at = ply:GetPos()
        for _, e in ipairs(list) do
            if IsValid(e) and e.lcCamEye and not e:GetNW2Bool("lc_nopower", false) and e:GetPos():DistToSqr(at) < WATCH * WATCH then
                AddOriginToPVS(e.lcCamEye)
            end
        end
    end)
end

if CLIENT then
    LC_CL = LC_CL or {}

    -- Up to three monitors are live for you at once, each with its own camera (the owner, 15 November: "can I make 2 or 3
    -- different ones with different feeds?"; it was one): one 512 x 512 texture each, drawn in turn, 8 pictures a second
    -- for one, 18 a second shared between two or three.
    local SIZE = 512 -- each picture: one 512 x 512 texture
    local NEAR = 700 -- only a monitor this near is live for you
    local FAR = 1500 -- past this the glass is left alone (the model only)
    local RATE = 8   -- pictures a second, for each live monitor
    local MOST = 18  -- pictures a second, all live monitors together
    local LIVE = 3   -- monitors live at once
    local FOV = 80

    local rts, mats = {}, {}
    local drawing = false -- a camera's view is being drawn right now: nothing starts another inside it
    local lives = {}      -- the monitors that show their camera for you, nearest first
    local slotOf = {}     -- [monitor] = which texture is its
    local shown = {}      -- [monitor] = true once its texture holds its own picture
    local turn = 0
    local nextFrame = 0

    local function Ensure(i)
        if mats[i] then return true end
        if not GetRenderTarget or not CreateMaterial then return false end
        local rt = GetRenderTarget(i == 1 and "lc_monitor_rt" or ("lc_monitor_rt" .. i), SIZE, SIZE)
        if not rt then return false end
        local mat = CreateMaterial(i == 1 and "lc_monitor_mat" or ("lc_monitor_mat" .. i), "UnlitGeneric", { ["$basetexture"] = rt:GetName(), ["$model"] = "0" })
        if not mat then return false end
        rts[i], mats[i] = rt, mat
        return true
    end

    -- Where the picture goes: the glass of each model, as fractions of its front
    -- face (centre across from the viewer's left, centre up from the bottom, how
    -- wide, how tall), then how far in front of the model's frontmost point. Read
    -- off the model's own bounds, as lc_screen.lua does. Gives the middle of the
    -- glass in the world, and its width and height.
    local GLASS = {}
    local DEFAULT = { 0.5, 0.5, 0.8, 0.8, 0.5 }
    local function Glass(self)
        local mins, maxs = self:GetModelBounds()
        local k = self:GetModelScale() or 1
        mins, maxs = mins * k, maxs * k
        local g = GLASS[string.lower(self:GetModel() or "")] or DEFAULT
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        return self:LocalToWorld(Vector(maxs.x + g[5], mins.y + wide * g[1], mins.z + tall * g[2])), wide * g[3], tall * g[4]
    end

    -- The monitors that are live for you: the nearest within reach with a camera
    -- and power, that you stand in front of and look toward (up to LIVE).
    local function Pick(eye, fwd)
        local found = {}
        for _, e in ipairs(ents.FindByClass("lc_monitor")) do
            if IsValid(e) and e:GetNW2Int("lc_cam", 0) > 0 and e:GetNW2Vector("lc_cam_pos") and not e:GetNW2Bool("lc_nopower", false)
                and not (e.IsDormant and e:IsDormant()) then
                local to = e:WorldSpaceCenter() - eye
                local d = to:LengthSqr()
                if d < NEAR * NEAR and to:Dot(fwd) > 0.5 * math.sqrt(d) and to:Dot(e:GetForward()) < 0 then
                    found[#found + 1] = { e = e, d = d }
                end
            end
        end
        table.sort(found, function(a, b) return a.d < b.d end)
        local out = {}
        for i = 1, math.min(LIVE, #found) do out[i] = found[i].e end
        return out
    end

    -- Each live monitor keeps its texture while it stays live; a new one takes a free texture (and shows no
    -- signal until its first picture is in it).
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
    local function Forget() lives, slotOf, shown = {}, {}, {} end

    -- One picture of a live monitor's camera, into its texture, the live monitors in turn, a few
    -- times a second. It runs before the scene is drawn and never inside itself: the camera's view
    -- draws the whole world again, monitors and all.
    function LC_CL.MonitorFeed(eye, ang)
        if drawing or LC_CL.LiveCamRendering or CurTime() < nextFrame then return false end
        lives = Pick(eye or EyePos(), (ang or EyeAngles()):Forward())
        Assign(lives)
        nextFrame = CurTime() + 1 / math.min(RATE * math.max(1, #lives), MOST)
        if #lives == 0 then return false end
        turn = turn + 1
        local live = lives[(turn - 1) % #lives + 1]
        local i = slotOf[live]
        if not (i and Ensure(i)) then Forget() return false end
        local at, yaw = live:GetNW2Vector("lc_cam_pos"), live:GetNW2Float("lc_cam_yaw", 0)
        local _, wide, tall = Glass(live)
        drawing = true
        -- (what stays out of the broadcast camera's picture stays out of this one: the editor's
        -- markers, the infestation's haze: cl_livingcity_livecam.lua)
        LC_CL.LiveCamRendering = true
        local pushed = false
        local ok = LC.Try(function()
            render.PushRenderTarget(rts[i])
            pushed = true
            render.Clear(0, 0, 0, 255, true, true)
            -- (the picture is as wide for its height as the glass is, so filling the glass with it doesn't stretch anyone)
            render.RenderView({
                origin = at, angles = Angle(CAM_PITCH, yaw, 0),
                x = 0, y = 0, w = SIZE, h = SIZE, fov = FOV, aspectratio = wide / math.max(tall, 1),
                drawviewmodel = false, drawviewer = true, drawhud = false, dopostprocess = false, drawmonitors = false,
            })
            render.PopRenderTarget()
            pushed = false
        end)
        if pushed then render.PopRenderTarget() end -- (an error mid-picture mustn't leave the game drawing into the texture)
        drawing = false
        LC_CL.LiveCamRendering = false
        if not ok then Forget() return false end
        shown[live] = true
        return true
    end
    -- the nearest live monitor (nil: none)
    LC_CL.MonitorLive = function() return lives[1] end
    LC_CL.MonitorsLive = function() return lives end

    hook.Add("RenderScene", "LivingCityMonitors", function(eye, ang) LC_CL.MonitorFeed(eye, ang) end)

    -- In the picture you are there like everyone else, when you stand in front of the camera.
    hook.Add("ShouldDrawLocalPlayer", "LivingCityMonitors", function() if drawing then return true end end)

    -- No signal: dark glass and a few thin lines of static that jump about. No words.
    local function NoSignal(self, h)
        surface.SetDrawColor(6, 12, 16, 255)
        surface.DrawRect(-SIZE / 2, -h / 2, SIZE, h)
        surface.SetDrawColor(120, 170, 190, 36)
        local t, id = math.floor(CurTime() * 6), self:EntIndex() or 0
        for i = 1, 4 do
            local y = ((id * 31 + t * 17 + i * i * 53) % 97) / 97
            surface.DrawRect(-SIZE / 2, -h / 2 + y * (h - 3), SIZE, 3)
        end
    end

    function ENT:Draw()
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end -- the district's power is out (sv_livingcity_power.lua): a dead screen
        local me = LocalPlayer()
        if not IsValid(me) or me:GetPos():DistToSqr(self:GetPos()) > FAR * FAR then return end
        local pos, wide, tall = Glass(self)
        if (EyePos() - pos):Dot(self:GetForward()) <= 0 then return end -- from behind, the model's own back and nothing else
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        local k = wide / SIZE
        local h = tall / k
        cam.Start3D2D(pos, ang, k)
            local i = slotOf[self]
            if i and shown[self] and not drawing and mats[i] then
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(mats[i])
                surface.DrawTexturedRect(-SIZE / 2, -h / 2, SIZE, h)
            else
                NoSignal(self, h)
            end
        cam.End3D2D()
    end
end
