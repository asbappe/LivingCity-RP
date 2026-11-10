--[[
    Living City (client): the Colonel (sv_livingcity_colonel.lua)

    Drawn only here, only for the Resistance: Odessa Cubbage's face, standing
    by the quartermaster. He's a model on your own screen and nowhere else:
    nothing to bump into, bullets go through him, and when the Combine come
    into the camp he isn't there. E while looking at him talks to him. His
    voice (if recorded) is heard by you alone.

    How he looks is yours alone too (lc_colonel_ghost, 0 to 1, from the
    server: the jobs you've done for him and how often you've come by). At
    0 he's a solid old man with a shadow. As it climbs he loses the shadow,
    turns see-through and cold-tinted, and starts to fade in and out and
    flicker. LC_CL.ColonelLook(g, t) gives the look for a ghostliness.
]]

LC_CL = LC_CL or {}

local MODEL = "models/odessa.mdl"
local REACH = 140
local colonel

-- The look for a ghostliness g (0 solid, 1 a ghost) at time t: red, green, blue, alpha
-- (before any flicker), the chance of a flicker each frame, and whether he has a shadow.
function LC_CL.ColonelLook(g, t)
    g = math.Clamp(g or 0, 0, 1)
    local a = Lerp(g, 255, 110) + 30 * g * math.sin((t or 0) * 0.8)
    return Lerp(g, 255, 215), Lerp(g, 255, 225), 255, math.Clamp(math.floor(a), 30, 255), 0.02 * g, g < 0.05
end

local function Mine()
    local me = LocalPlayer()
    if not IsValid(me) or me:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    if me:GetNW2Bool("lc_dreaming", false) then return false end
    return GetGlobal2Bool("lc_colonel_here", false)
end

local function Remove()
    if IsValid(colonel) then colonel:Remove() end
    colonel = nil
end

hook.Add("Think", "LivingCityColonel", function()
    if not Mine() then Remove() return end
    local pos = GetGlobal2Vector("lc_colonel_pos", Vector(0, 0, 0))
    if pos == Vector(0, 0, 0) then Remove() return end
    if not IsValid(colonel) then
        colonel = ClientsideModel(MODEL, RENDERGROUP_TRANSLUCENT)
        if not IsValid(colonel) then return end
        colonel.lcGhost = LocalPlayer():GetNW2Float("lc_colonel_ghost", 0)
        local seq = colonel:SelectWeightedSequence(ACT_IDLE)
        if not seq or seq < 0 then seq = colonel:LookupSequence("idle_subtle") end
        if seq and seq >= 0 then colonel:ResetSequence(seq) end
        colonel.lcCycle = 0
    end
    colonel:SetPos(pos)
    colonel:SetAngles(Angle(0, GetGlobal2Float("lc_colonel_yaw", 0), 0))
    -- his idle, played by hand (a client model doesn't animate by itself)
    local dur = colonel:SequenceDuration() or 3
    colonel.lcCycle = ((colonel.lcCycle or 0) + FrameTime() / math.max(dur, 0.5)) % 1
    colonel:SetCycle(colonel.lcCycle)
    -- solid at first; the more you've done for him, the fainter and less steady he is
    -- (the owner, 10 November: "he slowly looks more and more ghostly for the player").
    -- A change eases in over a few seconds rather than snapping.
    colonel.lcGhost = math.Approach(colonel.lcGhost or 0, LocalPlayer():GetNW2Float("lc_colonel_ghost", 0), FrameTime() * 0.05)
    local r, g, b, a, flick, shadow = LC_CL.ColonelLook(colonel.lcGhost, CurTime())
    if math.random() < flick then a = math.max(a - 60, 30) end
    colonel:DrawShadow(shadow)
    colonel:SetRenderMode(a >= 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSCOLOR)
    colonel:SetColor(Color(r, g, b, a))
    -- he looks at you
    local me = LocalPlayer()
    local d = me:EyePos() - (pos + Vector(0, 0, 64))
    local yaw = math.NormalizeAngle(d:Angle().y - colonel:GetAngles().y)
    colonel:SetPoseParameter("head_yaw", math.Clamp(yaw, -60, 60))
    colonel:InvalidateBoneCache()
end)

local function LookingAt()
    local me = LocalPlayer()
    if not IsValid(colonel) or not IsValid(me) then return false end
    local center = colonel:GetPos() + Vector(0, 0, 48)
    local eye = me:EyePos()
    if eye:Distance(center) > REACH then return false end
    local to = (center - eye):GetNormalized()
    return me:GetAimVector():Dot(to) > 0.94
end
LC_CL.LookingAtColonel = LookingAt

hook.Add("KeyPress", "LivingCityColonel", function(ply, key)
    if key ~= IN_USE or ply ~= LocalPlayer() or not LookingAt() then return end
    net.Start("lc_colonel_use") net.SendToServer()
end)

hook.Add("HUDPaint", "LivingCityColonel", function()
    if not LookingAt() then return end
    draw.SimpleText("The Colonel", "DermaDefaultBold", ScrW() / 2, ScrH() / 2 + 40, Color(220, 210, 190, 200), TEXT_ALIGN_CENTER)
    draw.SimpleText("[E] talk", "DermaDefault", ScrW() / 2, ScrH() / 2 + 58, Color(200, 200, 200, 160), TEXT_ALIGN_CENTER)
end)

net.Receive("lc_colonel_say", function()
    local clip = net.ReadString()
    local pos = IsValid(colonel) and (colonel:GetPos() + Vector(0, 0, 64)) or LocalPlayer():EyePos()
    sound.Play(clip, pos, 70, 100, 1)
end)
