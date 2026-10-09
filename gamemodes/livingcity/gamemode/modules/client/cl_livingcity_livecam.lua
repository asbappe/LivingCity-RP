--[[
    Living City (client): the broadcast picture

    While someone is on air, the broadcast camera (a scanner, entities/
    lc_broadcastcam.lua) is rendered into a texture the way Garry's Mod's own
    camera and TV tools do it, and every city screen and TV shows that texture
    (cl_livingcity_resistance.lua draws the screens).

    It only renders while a screen that shows it is actually being drawn,
    at most lc_livecam_fps times a second (12; 0 turns the picture off for you).
]]

LC_CL = LC_CL or {}

local cvVol = CreateClientConVar("lc_breencast_volume", "0.5", true, false, "How loud the Administrator's addresses over the loudspeakers are for you (0 to 1)")
local cvFps = CreateClientConVar("lc_livecam_fps", "12", true, false, "Frames a second for the broadcast picture on city screens (0 = off)")

local W, H = 512, 288 -- 16:9, in the top of a 512 x 512 texture
local rt, mat
local rendering = false
local nextFrame = 0
LC_CL.LiveCamWanted = 0

local function Ensure()
    if mat then return true end
    if not GetRenderTarget or not CreateMaterial then return false end
    rt = GetRenderTarget("lc_livecam_rt", 512, 512)
    if not rt then return false end
    mat = CreateMaterial("lc_livecam_mat", "UnlitGeneric", { ["$basetexture"] = rt:GetName(), ["$model"] = "0" })
    return mat ~= nil
end

-- The picture, if there is one: the material and how much of it to use (u, v).
function LC_CL.LiveCamPicture()
    local cam = GetGlobal2Entity("lc_live_cam")
    if not IsValid(cam) or cvFps:GetFloat() <= 0 or rendering then return nil end
    if not Ensure() then return nil end
    LC_CL.LiveCamWanted = CurTime()
    return mat, 1, H / 512
end

hook.Add("RenderScene", "LivingCityLiveCam", function()
    if rendering then return end
    local cam = GetGlobal2Entity("lc_live_cam")
    if not IsValid(cam) or CurTime() - (LC_CL.LiveCamWanted or 0) > 0.5 then return end
    local fps = cvFps:GetFloat()
    if fps <= 0 or CurTime() < nextFrame then return end
    nextFrame = CurTime() + 1 / math.Clamp(fps, 1, 60)
    if not Ensure() then return end
    rendering = true
    LC_CL.LiveCamRendering = true
    local pushed = false
    local ok, err = pcall(function()
        render.PushRenderTarget(rt)
        pushed = true
        render.Clear(0, 0, 0, 255, true, true)
        render.RenderView({
            origin = cam:LocalToWorld(Vector(16, 0, 0)), angles = cam:GetAngles(),
            x = 0, y = 0, w = W, h = H, fov = 46, aspectratio = W / H,
            drawviewmodel = false, drawhud = false, dopostprocess = false, drawmonitors = false,
        })
        render.PopRenderTarget()
        pushed = false
    end)
    if pushed then render.PopRenderTarget() end -- (an error mid-frame mustn't leave the screen drawing into the texture)
    rendering = false
    LC_CL.LiveCamRendering = false
    if not ok then print("[Living City] broadcast picture: " .. tostring(err)) end
end)

-- In the picture, you're in it like everyone else (even if you're the one on air).
hook.Add("ShouldDrawLocalPlayer", "LivingCityLiveCam", function() if rendering then return true end end)

-- The Administrator's recorded addresses (sv_livingcity_propaganda.lua): over the
-- loudspeakers. The server only sends them to people who'd hear them (not
-- next to a broken or powerless loudspeaker, not in the studio with her).
net.Receive("lc_breencast", function()
    local path = net.ReadString()
    local me = LocalPlayer()
    if path == "" or not IsValid(me) then return end
    local vol = math.Clamp(cvVol:GetFloat(), 0, 1)
    if vol <= 0 then return end
    -- (level 0: everywhere at once, like the PA, at the volume you've set)
    me:EmitSound(path, 0, 100, vol, CHAN_VOICE2)
end)
