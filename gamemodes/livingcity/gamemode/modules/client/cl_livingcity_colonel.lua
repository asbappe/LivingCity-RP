--[[
    Living City (client): the Colonel (sv_livingcity_colonel.lua)

    Drawn only here, only for the Resistance: Odessa Cubbage's face, standing
    by the quartermaster. He's a model on your own screen and nowhere else,
    faintly see-through and cold-tinted, fading in and out a little: no shadow, nothing to bump into, bullets go through him, and when the
    Combine come into the camp he isn't there. E while looking at him talks
    to him. His voice (if recorded) is heard by you alone.
]]

LC_CL = LC_CL or {}

local MODEL = "models/odessa.mdl"
local REACH = 140
local colonel

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
        colonel:DrawShadow(false)
        -- see-through, like a ghost (the owner, 10 November: "slightly transparent ... so he looks sort of ghostly")
        colonel:SetRenderMode(RENDERMODE_TRANSCOLOR)
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
    -- faint, and never quite steady: a slow breath of fading, now and then a flicker
    local t = CurTime()
    local a = 110 + 30 * math.sin(t * 0.8) + (math.random() < 0.02 and -60 or 0)
    colonel:SetColor(Color(215, 225, 255, math.Clamp(math.floor(a), 30, 160)))
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
