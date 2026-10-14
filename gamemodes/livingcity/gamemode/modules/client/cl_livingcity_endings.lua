--[[
    Living City: secret endings, on your screen (sv_livingcity_endings.lua)

      Time stopped: the colour drains out, the G-Man speaks, and the vote is
      on screen (1: let it happen, 2: skip it). The ending: its song, the
      flood's water, Father Grigori mouthing along. The reset: white.
]]

if SERVER then return end

LC_CL = LC_CL or {}

if surface and surface.CreateFont then
    surface.CreateFont("LCEndBig", { font = "Trebuchet MS", size = 40, weight = 800 })
    surface.CreateFont("LCEndText", { font = "Trebuchet MS", size = 20, weight = 600 })
end

local S = nil      -- what the server last said
local channel      -- the ending's song, playing
local lineQueue, lineNext = nil, 0
local myVote
local resetAt

local function StopSong()
    if channel and channel.Stop then pcall(channel.Stop, channel) end
    channel = nil
end

local function PlaySong(path)
    StopSong()
    if not path or path == "" then return end
    if sound and sound.PlayFile then
        sound.PlayFile("sound/" .. path, "noblock", function(ch)
            if IsValid(ch) then
                if S and S.phase == "apocalypse" then channel = ch ch:Play() else ch:Stop() end
            end
        end)
    elseif surface and surface.PlaySound then
        surface.PlaySound(path)
    end
end

net.Receive("lc_ending", function()
    local t = net.ReadTable() or {}
    local was = S and S.phase
    if not t.phase then
        S, lineQueue, myVote, resetAt = nil, nil, nil, nil
        StopSong()
        return
    end
    S = t
    if t.phase == "gman" and was ~= "gman" then
        myVote = nil
        lineQueue, lineNext = {}, CurTime() + 0.5
        for _, l in ipairs(t.lines or {}) do lineQueue[#lineQueue + 1] = l end
        surface.PlaySound("ambient/levels/citadel/strange_talk1.wav")
    elseif t.phase == "apocalypse" and was ~= "apocalypse" then
        lineQueue = nil
        PlaySong(t.song)
    elseif t.phase == "reset" and was ~= "reset" then
        resetAt = CurTime()
    end
end)

function LC_CL.Ending() return S end

-- the G-Man's lines, one after another
hook.Add("Think", "LivingCityEndings", function()
    if not lineQueue or #lineQueue == 0 or CurTime() < lineNext then return end
    local l = table.remove(lineQueue, 1)
    surface.PlaySound(l)
    local d = SoundDuration and SoundDuration(l) or 0
    lineNext = CurTime() + ((d and d > 0.2) and d or 4) + 0.6
end)

-- the vote: 1 or 2 (the weapon slots), or lc_ending_vote yes|skip
local function Vote(yes)
    myVote = yes
    net.Start("lc_ending_vote")
    net.WriteBool(yes)
    net.SendToServer()
    surface.PlaySound("buttons/button14.wav")
end
LC_CL.EndingVote = Vote

hook.Add("PlayerBindPress", "LivingCityEndings", function(_, bind, pressed)
    if not S or S.phase ~= "gman" or not pressed then return end
    if string.find(bind, "slot1", 1, true) then Vote(true) return true end
    if string.find(bind, "slot2", 1, true) then Vote(false) return true end
end)

-- time stopped: the colour goes
hook.Add("RenderScreenspaceEffects", "LivingCityEndings", function()
    if not S or not DrawColorModify then return end
    if S.phase == "gman" then
        DrawColorModify({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0.02, ["$pp_colour_brightness"] = -0.02,
            ["$pp_colour_contrast"] = 1.1, ["$pp_colour_colour"] = 0.05, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
    end
end)

local WHITE, AMBER, SHADOW = Color(235, 235, 235), Color(240, 190, 80), Color(0, 0, 0, 230)
local function Text(s, font, x, y, col)
    draw.SimpleTextOutlined(s, font, x, y, col or WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, SHADOW)
end

hook.Add("HUDPaint", "LivingCityEndings", function()
    if not S then return end
    local cx, cy = ScrW() / 2, ScrH() * 0.25
    local now = CurTime()
    if S.phase == "gman" then
        Text("TIME HAS STOPPED", "LCEndBig", cx, cy, AMBER)
        Text("The man in the blue suit would like your decision: " .. (S.name or "the end of the city") .. ".", "LCEndText", cx, cy + 40)
        Text("[1] LET IT HAPPEN          [2] SKIP IT", "LCEndBig", cx, cy + 90, WHITE)
        local left = math.max(0, math.floor((S.voteEnds or now) - now))
        Text(string.format("%d seconds.   Let it happen: %d   Skip it: %d   (no votes at all: it happens)", left, S.yes or 0, S.skip or 0), "LCEndText", cx, cy + 135)
        if myVote ~= nil then Text(myVote and "You chose: let it happen." or "You chose: skip it.", "LCEndText", cx, cy + 162, AMBER) end
    elseif S.phase == "apocalypse" then
        Text(string.upper(S.name or ""), "LCEndBig", cx, ScrH() * 0.1, AMBER)
        local me = LocalPlayer()
        if IsValid(me) and me:GetNW2Bool("lc_end_spectating", false) then
            Text("You're dead. Watch the end of the city.", "LCEndText", cx, ScrH() * 0.85, WHITE)
            Text("Left / right click: someone else      Jump: fly free", "LCEndText", cx, ScrH() * 0.85 + 26, AMBER)
        end
    elseif S.phase == "reset" and resetAt then
        local a = math.Clamp((now - resetAt) / 4, 0, 1) * 255
        surface.SetDrawColor(255, 255, 255, a)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        Text("The city resets.", "LCEndBig", cx, ScrH() / 2, Color(60, 60, 60, a))
    end
end)

-- the flood
hook.Add("PostDrawTranslucentRenderables", "LivingCityEndings", function(_, sky)
    if sky or not S or S.id ~= "grigori" or S.phase ~= "apocalypse" then return end
    local z = GetGlobal2Float("lc_flood_z", 0)
    if z == 0 then return end
    local eye = EyePos()
    render.SetColorMaterial()
    render.DrawBox(Vector(eye.x, eye.y, z), Angle(0, 0, 0), Vector(-20000, -20000, -4000), Vector(20000, 20000, 0), Color(40, 80, 110, 150), true)
end)

-- Father Grigori mouths the words: his jaw follows the song's loudness
local MOUTH = { "jaw_drop", "right_part", "left_part", "right_mouth_drop", "left_mouth_drop" }
hook.Add("MouthMoveAnimation", "LivingCityEndings", function(ply)
    if not IsValid(ply) or not ply:GetNW2Bool("lc_rocking", false) or not channel or not channel.GetLevel then return end
    local l, r = channel:GetLevel()
    local w = math.Clamp(((l or 0) + (r or 0)) * 1.6, 0, 1)
    for _, name in ipairs(MOUTH) do
        local id = ply:GetFlexIDByName(name)
        if id then ply:SetFlexWeight(id, w) end
    end
    return true
end)

------------------------------------------------------------------------
-- Bloom: everyone dances, nobody stops (sv_livingcity_endings.lua)
------------------------------------------------------------------------

-- The dance, as bone turns on top of whatever the model's doing: both hands
-- up on the head, the wrists flapping in turn, the hips swaying with the
-- beat, a bounce in the knees. Tune it live: lc_bloom_preview (dance on the
-- spot yourself), lc_bloom_pose <bone> <p> <y> <r>, lc_bloom_pose_print.
local POSE = {
    R_UpperArm = Angle(25, -95, 10),  R_Forearm = Angle(-15, -110, 0), R_Hand = Angle(0, 0, 0),
    L_UpperArm = Angle(-25, -95, -10), L_Forearm = Angle(15, -110, 0), L_Hand = Angle(0, 0, 0),
    Pelvis = Angle(0, 0, 0), Spine2 = Angle(0, 0, 0), Head = Angle(0, 0, 0),
    R_Thigh = Angle(0, 0, 0), L_Thigh = Angle(0, 0, 0), R_Calf = Angle(0, 0, 0), L_Calf = Angle(0, 0, 0),
}
local FLAP, SWAY, KNEE = 35, 12, 18
local PALETTE = { Color(255, 110, 200), Color(220, 90, 255), Color(100, 190, 255), Color(110, 255, 190), Color(255, 235, 110) }
local preview = false
local danced = {}   -- [ent] = true: someone we've turned bones on
local bonesOf = {}  -- [model] = { name = id }

-- A dancing ending (bloom, marrow): what the server says about it (the dance, the light, the beat).
local function Party() return S and S.phase == "apocalypse" and S.client and S.client.party and S.client or nil end
local Bloom = Party

-- How far into the song we are (the song itself if it's playing; else the clock, sped up the same way).
local function SongPos(now)
    if channel and channel.GetTime then return channel:GetTime() end
    local c = S and S.client
    if not c then return 0 end
    local t = now - (c.start or now)
    local a = (c.rateAt or math.huge) - (c.start or now)
    if t <= a then return t end
    local x = math.min(t - a, c.rateDur or 1)
    local ramp = x + (c.peak - 1) * x * x / (2 * (c.rateDur or 1))
    return a + ramp + math.max(0, t - a - (c.rateDur or 1)) * c.peak
end

local function Rate(now)
    local c = S and S.client
    if not c or now < (c.rateAt or math.huge) then return 1 end
    return 1 + ((c.peak or 1) - 1) * math.Clamp((now - c.rateAt) / (c.rateDur or 1), 0, 1)
end

local function Beat(now)
    if preview and not Party() then return now * 165 / 60 end
    local c = S.client
    return (SongPos(now) - (c.offset or 0)) * (c.bpm or 165) / 60 * (c.danceRate or 1)
end

local function Bones(ent)
    local m = ent:GetModel() or ""
    local b = bonesOf[m]
    if not b then
        b = {}
        for name in pairs(POSE) do
            local id = ent.LookupBone and ent:LookupBone("ValveBiped.Bip01_" .. name)
            if id then b[name] = id end
        end
        bonesOf[m] = b
    end
    return b
end

-- The other dances (marrow's club and rave): turns added to a standing pose.
local CLUB = {
    R_UpperArm = function(w, b) return Angle(0, -40 - 45 * b, 0) end, L_UpperArm = function(w, b) return Angle(0, -40 - 45 * (1 - b), 0) end,
    R_Forearm = function() return Angle(0, -70, 0) end, L_Forearm = function() return Angle(0, -70, 0) end,
    Head = function(w, b) return Angle(0, -14 * b, 0) end,
    Spine2 = function(w) return Angle(0, 0, w * 10) end, Pelvis = function(w) return Angle(0, 0, w * 8) end,
    R_Calf = function(w, b) return Angle(0, 22 * b, 0) end, L_Calf = function(w, b) return Angle(0, 22 * b, 0) end,
}
local RAVE = {
    R_UpperArm = function(w) return Angle(20 * w, -110, 10) end, L_UpperArm = function(w) return Angle(20 * w, -110, -10) end,
    R_Forearm = function(w) return Angle(0, -20 + 30 * w, 0) end, L_Forearm = function(w) return Angle(0, -20 - 30 * w, 0) end,
    Head = function(w, b) return Angle(0, -10 * b, w * 8) end, Pelvis = function(w) return Angle(0, 0, w * 14) end,
    Spine2 = function(w) return Angle(0, 0, -w * 8) end,
    R_Calf = function(w, b) return Angle(0, 30 * b, 0) end, L_Calf = function(w, b) return Angle(0, 30 * b, 0) end,
}
-- On the bus: sat down (crammed in), arms in the air.
local BUS = {
    R_UpperArm = RAVE.R_UpperArm, L_UpperArm = RAVE.L_UpperArm, R_Forearm = RAVE.R_Forearm, L_Forearm = RAVE.L_Forearm,
    Head = RAVE.Head, Spine2 = function(w) return Angle(0, 0, -w * 6) end,
    R_Thigh = function() return Angle(0, -85, 0) end, L_Thigh = function() return Angle(0, -85, 0) end,
    R_Calf = function(w, b) return Angle(0, 85 + 6 * b, 0) end, L_Calf = function(w, b) return Angle(0, 85 + 6 * b, 0) end,
}
local STYLES = { club = CLUB, rave = RAVE, bus = BUS }

local function Dance(ent, beat, now)
    if not ent.ManipulateBoneAngles then return end
    local b = Bones(ent)
    local wave = math.sin(beat * math.pi)            -- left, right, a beat each
    local flap = math.sin(beat * math.pi * 2) * FLAP -- the wrists, every beat
    local bounce = math.abs(wave)
    local style = STYLES[S and S.client and S.client.dance or ""]
    if style and not preview then
        for name, id in pairs(b) do
            local f = style[name]
            ent:ManipulateBoneAngles(id, f and f(wave, bounce) or Angle(0, 0, 0))
        end
        danced[ent] = true
        return
    end
    for name, id in pairs(b) do
        local a = Angle(POSE[name].p, POSE[name].y, POSE[name].r)
        if name == "R_Hand" then a.r = a.r + flap
        elseif name == "L_Hand" then a.r = a.r - flap
        elseif name == "Pelvis" then a.r = a.r + wave * SWAY
        elseif name == "Spine2" then a.r = a.r - wave * SWAY * 0.6
        elseif name == "Head" then a.r = a.r - wave * 6
        elseif name == "R_Calf" then a.y = a.y + bounce * KNEE * (wave > 0 and 1 or 0.3)
        elseif name == "L_Calf" then a.y = a.y + bounce * KNEE * (wave < 0 and 1 or 0.3)
        end
        -- spinning up into the sky
        local t0 = ent.GetNW2Float and ent:GetNW2Float("lc_spin_t0", 0) or 0
        if name == "Pelvis" and t0 > 0 then a.y = a.y + ((now - t0) ^ 2) * 720 % 360 end
        ent:ManipulateBoneAngles(id, a)
    end
    danced[ent] = true
end

local function Undance(ent)
    if IsValid(ent) and ent.ManipulateBoneAngles then
        for _, id in pairs(Bones(ent)) do ent:ManipulateBoneAngles(id, Angle(0, 0, 0)) end
    end
    danced[ent] = nil
end

local dancers, dancersAt = {}, 0
local props = {}

hook.Add("Think", "LivingCityBloom", function()
    local now = CurTime()
    local on = Bloom()
    if not on and not preview then
        if next(danced) then for e in pairs(danced) do Undance(e) end end
        for e in pairs(props) do if IsValid(e) and e.DisableMatrix then e:DisableMatrix("RenderMultiply") end end
        props = {}
        return
    end
    local beat = Beat(now)
    if on and channel and channel.SetPlaybackRate then channel:SetPlaybackRate(Rate(now)) end
    -- who's dancing (looked up once a second)
    if now >= dancersAt then
        dancersAt = now + 1
        dancers = {}
        for _, e in ipairs(ents.GetAll and ents.GetAll() or player.GetAll()) do
            if IsValid(e) and e.GetNW2Bool and e:GetNW2Bool("lc_dancing", false) then dancers[#dancers + 1] = e end
        end
    end
    local me = LocalPlayer()
    if preview and IsValid(me) then Dance(me, beat, now) end
    for _, e in ipairs(dancers) do
        if IsValid(e) and e:GetNW2Bool("lc_dancing", false) and not (e.GetNoDraw and e:GetNoDraw()) then Dance(e, beat, now)
        elseif danced[e] then Undance(e) end
    end
    if not on then return end
    -- coloured light, pulsing on the beat, round the dancers nearest you
    local frac = (beat * (on.strobe and 2 or 1)) % 1
    if DynamicLight and IsValid(me) and on.lights then
        local near = {}
        for _, e in ipairs(dancers) do if IsValid(e) then near[#near + 1] = { e = e, d = e:GetPos():DistToSqr(me:GetPos()) } end end
        table.sort(near, function(x, y) return x.d < y.d end)
        for i = 1, math.min(#near, 24) do
            local pal = on.palette or PALETTE
            local c0 = pal[(math.floor(beat) + i) % #pal + 1]
            local col = Color(c0.r or c0[1] or 255, c0.g or c0[2] or 255, c0.b or c0[3] or 255)
            local dl = DynamicLight(52000 + i)
            if dl then
                dl.pos = near[i].e:GetPos() + Vector(0, 0, 70)
                dl.r, dl.g, dl.b = col.r, col.g, col.b
                dl.brightness = on.strobe and ((frac < 0.25) and 5 or 0.3) or (1 + 3 * (1 - frac))
                dl.size = 320
                dl.decay = 0
                dl.dietime = now + 0.15
            end
        end
    end
    -- the party bus: the light inside it, pulsing through the colours
    local bus = on.bus and Entity(on.bus)
    if DynamicLight and IsValid(bus) then
        local pal = on.palette or PALETTE
        local c0 = pal[math.floor(beat) % #pal + 1]
        local dl = DynamicLight(52200)
        if dl then
            dl.pos = bus:GetPos() + Vector(0, 0, 60)
            dl.r, dl.g, dl.b = c0.r or c0[1] or 255, c0.g or c0[2] or 255, c0.b or c0[3] or 255
            dl.brightness = on.strobe and ((frac < 0.25) and 6 or 1) or (2 + 4 * (1 - frac))
            dl.size = 600
            dl.decay = 0
            dl.dietime = now + 0.15
        end
    end
    -- light everywhere: a grid of it across the ground round you, pulsing on the beat
    if DynamicLight and IsValid(me) and on.lights and on.ambient then
        local pal = on.palette or PALETTE
        local here = me:GetPos()
        local gx, gy = math.floor(here.x / 500), math.floor(here.y / 500)
        local n = 0
        for dx = -3, 3 do
            for dy = -3, 3 do
                if n < 24 and dx * dx + dy * dy <= 10 then
                    n = n + 1
                    local cx, cy = gx + dx, gy + dy
                    local c0 = pal[(cx + cy + math.floor(beat)) % #pal + 1]
                    local dl = DynamicLight(52100 + n)
                    if dl then
                        dl.pos = Vector(cx * 500 + 250, cy * 500 + 250, here.z + 90)
                        dl.r, dl.g, dl.b = c0.r or c0[1] or 255, c0.g or c0[2] or 255, c0.b or c0[3] or 255
                        dl.brightness = on.strobe and ((frac < 0.25) and 4 or 0.4) or (0.6 + 2.4 * (1 - frac))
                        dl.size = 520
                        dl.decay = 0
                        dl.dietime = now + 0.15
                    end
                end
            end
        end
    end
    -- the props hop
    for _, idx in ipairs(on.props or {}) do
        local e = Entity(idx)
        if IsValid(e) and e.EnableMatrix and Matrix then
            local m = Matrix()
            m:Translate(Vector(0, 0, 6 * math.abs(math.sin(beat * math.pi))))
            m:Rotate(Angle(0, 10 * math.sin(beat * math.pi), 0))
            e:EnableMatrix("RenderMultiply", m)
            props[e] = true
        end
    end
end)

-- You watch yourself dance: the camera circles you.
local function Dancing(me)
    return IsValid(me) and (preview or (Bloom() and me:GetNW2Bool("lc_dancing", false) and not me:GetNW2Bool("lc_end_spectating", false)))
end
hook.Add("CalcView", "LivingCityBloom", function(me, origin, angles, fov)
    -- on the party bus: behind it, looking wherever you look
    local on = Party()
    local bus = on and on.bus and Entity(on.bus)
    if IsValid(me) and me:GetNW2Bool("lc_seated", false) and IsValid(bus) then
        local eye = bus:GetPos() + Vector(0, 0, 140) - angles:Forward() * 520
        return { origin = eye, angles = angles, fov = fov, drawviewer = true }
    end
    if not Dancing(me) then return end
    local a = math.rad(CurTime() * 18)
    local centre = me:GetPos() + Vector(0, 0, 45)
    local eye = centre + Vector(math.cos(a) * 120, math.sin(a) * 120, 30)
    return { origin = eye, angles = (centre - eye):Angle(), fov = fov, drawviewer = true }
end)
hook.Add("ShouldDrawLocalPlayer", "LivingCityBloom", function(me) if Dancing(me) then return true end end)

-- The screen: a slow sunburst of pink and blue behind it all, sparkles
-- rising, and the colour pulsing on the beat.
local sparkles = {}
hook.Add("HUDPaint", "LivingCityBloom", function()
    local on = Party()
    if not on or on.overlay ~= "bloom" then sparkles = {} return end
    local now = CurTime()
    local w, h = ScrW(), ScrH()
    local cx, cy = w / 2, h / 2
    if draw.NoTexture and surface.DrawPoly then
        draw.NoTexture()
        local r = math.max(w, h)
        local spin = math.rad(now * 12)
        for i = 0, 15 do
            local a1, a2 = spin + i * math.pi / 8, spin + (i + 1) * math.pi / 8
            local col = i % 2 == 0 and PALETTE[1] or PALETTE[3]
            surface.SetDrawColor(col.r, col.g, col.b, 18)
            surface.DrawPoly({ { x = cx, y = cy }, { x = cx + math.cos(a1) * r, y = cy + math.sin(a1) * r }, { x = cx + math.cos(a2) * r, y = cy + math.sin(a2) * r } })
        end
    end
    if #sparkles < 60 and math.random() < 0.5 then
        sparkles[#sparkles + 1] = { x = math.random(0, w), y = h + 10, v = math.random(60, 160), s = math.random(4, 10), c = PALETTE[math.random(#PALETTE)], spin = math.random(0, 90) }
    end
    local keep = {}
    local dt = FrameTime and FrameTime() or 0.016
    for _, p in ipairs(sparkles) do
        p.y = p.y - p.v * dt
        if p.y > -20 then
            surface.SetDrawColor(p.c.r, p.c.g, p.c.b, 200)
            if surface.DrawTexturedRectRotated then surface.DrawTexturedRectRotated(p.x, p.y, p.s, p.s, p.spin + now * 90)
            else surface.DrawRect(p.x, p.y, p.s, p.s) end
            keep[#keep + 1] = p
        end
    end
    sparkles = keep
end)

hook.Add("RenderScreenspaceEffects", "LivingCityBloom", function()
    local on = Party()
    if not on or not on.lights or not DrawColorModify then return end
    local beat = Beat(CurTime())
    local pulse = 1 - (beat % 1)
    local pal = on.palette or PALETTE
    local c0 = pal[math.floor(beat) % #pal + 1]
    local r, g, b = (c0.r or c0[1] or 255) / 255, (c0.g or c0[2] or 255) / 255, (c0.b or c0[3] or 255) / 255
    DrawColorModify({ ["$pp_colour_addr"] = 0.06 * pulse * r, ["$pp_colour_addg"] = 0.06 * pulse * g, ["$pp_colour_addb"] = 0.06 * pulse * b,
        ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1.05, ["$pp_colour_colour"] = 1.35,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
end)

-- tuning the dance (anyone can preview it on themselves; it's only on your screen)
concommand.Add("lc_bloom_preview", function()
    preview = not preview
    if not preview and IsValid(LocalPlayer()) then Undance(LocalPlayer()) end
    print("[Living City] Dance preview " .. (preview and "on (lc_bloom_preview again to stop)" or "off"))
end)
concommand.Add("lc_bloom_pose", function(_, _, args)
    local name = args[1]
    if not name or not POSE[name] then
        local names = {}
        for n in pairs(POSE) do names[#names + 1] = n end
        table.sort(names)
        print("[Living City] lc_bloom_pose <" .. table.concat(names, "|") .. "> <pitch> <yaw> <roll>")
        return
    end
    POSE[name] = Angle(tonumber(args[2]) or 0, tonumber(args[3]) or 0, tonumber(args[4]) or 0)
    bonesOf = {}
end)
concommand.Add("lc_bloom_pose_print", function()
    local names = {}
    for n in pairs(POSE) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do print(string.format("%s = Angle(%g, %g, %g)", n, POSE[n].p, POSE[n].y, POSE[n].r)) end
end)
