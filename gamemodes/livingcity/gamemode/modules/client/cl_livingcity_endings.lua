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

-- Photosensitivity: lc_ending_calm 1 turns the strobes into a steady glow and
-- leaves out the screen flashes, the lightning and the static (the music,
-- the dancing and the rest stay). The endings that flash warn first.
local cvCalm = CreateClientConVar("lc_ending_calm", "0", true, false, "Secret endings without strobes or screen flashes (for photosensitivity)")
local function Calm() return cvCalm:GetBool() end

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
        if t.flashing and not Calm() and LC_CL.FlashWarning then LC_CL.FlashWarning() end
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
        if S.flashing then
            Text("PHOTOSENSITIVITY WARNING: this one has flashing lights and strobes.", "LCEndText", cx, cy + 200, Color(255, 120, 100))
            Text(Calm() and "You've turned the flashing off (lc_ending_calm 0 turns it back on)." or "Type lc_ending_calm 1 in the console to leave the flashing out, just for you.", "LCEndText", cx, cy + 224, WHITE)
        end
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

-- the flood: drawn as water (unless the map's own water is rising: lc_flood).
-- A murky body of it, and a rippling surface on top in one of Half-Life 2's
-- own water-ish materials (lc_flood_material).
local cvFloodMat = CreateClientConVar("lc_flood_material", "models/shadertest/shader3", true, false, "The surface the flood is drawn with (a refracting material)")
local floodMat, floodMatName
hook.Add("PostDrawTranslucentRenderables", "LivingCityEndings", function(_, sky)
    if sky or not S or S.id ~= "water" or S.phase ~= "apocalypse" or GetGlobal2Bool("lc_flood_real", false) then return end
    local z = GetGlobal2Float("lc_flood_z", 0)
    if z == 0 then return end
    local eye = EyePos()
    render.SetColorMaterial()
    render.DrawBox(Vector(eye.x, eye.y, z), Angle(0, 0, 0), Vector(-20000, -20000, -4000), Vector(20000, 20000, 0), Color(25, 60, 85, 170), true)
    if Material and render.DrawQuadEasy then
        if floodMatName ~= cvFloodMat:GetString() then floodMatName = cvFloodMat:GetString() floodMat = Material(floodMatName) end
        if floodMat and not (floodMat.IsError and floodMat:IsError()) then
            render.SetMaterial(floodMat)
            for gx = -2, 2 do
                for gy = -2, 2 do
                    render.DrawQuadEasy(Vector(math.floor(eye.x / 2000) * 2000 + gx * 2000, math.floor(eye.y / 2000) * 2000 + gy * 2000, z + 1), Vector(0, 0, 1), 2000, 2000, Color(255, 255, 255, 255), 0)
                end
            end
        end
    end
end)

-- Father Grigori mouths the words: his jaw follows the song's loudness
local MOUTH = { "jaw_drop", "right_part", "left_part", "right_mouth_drop", "left_mouth_drop" }
hook.Add("MouthMoveAnimation", "LivingCityEndings", function(ply)
    local singing = ply:GetNW2Bool("lc_rocking", false) or (S and S.client and S.client.lipsync and ply:GetNW2Bool("lc_dancing", false))
    if not IsValid(ply) or not singing or not channel or not channel.GetLevel then return end
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
    -- numa numa: the webcam dance, arms rolling in front of the face, the head
    -- tipping side to side, a bounce
    if S and S.client and S.client.dance == "numa" and not preview then
        local ph = beat * math.pi
        local NUMA = {
            R_UpperArm = Angle(28 * math.sin(ph), -75 + 22 * math.cos(ph), 0),
            L_UpperArm = Angle(-28 * math.sin(ph + math.pi), -75 + 22 * math.cos(ph + math.pi), 0),
            R_Forearm = Angle(0, -95 + 20 * math.sin(ph * 2), 0),
            L_Forearm = Angle(0, -95 + 20 * math.sin(ph * 2 + math.pi), 0),
            Head = Angle(0, 8 * bounce, 14 * math.sin(ph / 2)),
            Spine2 = Angle(0, 0, 6 * wave),
            Pelvis = Angle(0, 0, 8 * wave),
            R_Calf = Angle(0, 14 * bounce, 0), L_Calf = Angle(0, 14 * bounce, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, NUMA[name] or Angle(0, 0, 0)) end
        danced[ent] = true
        return
    end
    -- party hard: two frames, a pose and its mirror image, flipping every half-beat
    if S and S.client and S.client.dance == "hard" and not preview then
        local hold = S.client.section == "break" or S.client.section == "fade"
        local flip = hold and 1 or ((math.floor(beat * 2) % 2 == 0) and 1 or -1)
        local HARD = {
            Pelvis = Angle(0, 0, 0) + Angle(0, 40 * flip, 0),
            Spine2 = Angle(0, 0, 12 * flip),
            Head = Angle(0, 0, -14 * flip),
            R_UpperArm = flip > 0 and Angle(20, -120, 0) or Angle(0, -10, 0),
            L_UpperArm = flip > 0 and Angle(0, -10, 0) or Angle(-20, -120, 0),
            R_Forearm = flip > 0 and Angle(0, -40, 0) or Angle(0, 0, 0),
            L_Forearm = flip > 0 and Angle(0, 0, 0) or Angle(0, -40, 0),
            R_Thigh = Angle(0, flip > 0 and -20 or 0, 0), L_Thigh = Angle(0, flip > 0 and 0 or -20, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, HARD[name] or Angle(0, 0, 0)) end
        danced[ent] = true
        return
    end
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
    local strobe = on.strobe and not Calm()
    local frac = Calm() and 0.5 or ((beat * (strobe and 2 or 1)) % 1)
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
                dl.brightness = strobe and ((frac < 0.25) and 5 or 0.3) or (1 + 3 * (1 - frac))
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
            dl.brightness = strobe and ((frac < 0.25) and 6 or 1) or (2 + 4 * (1 - frac))
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
                        dl.brightness = strobe and ((frac < 0.25) and 4 or 0.4) or (0.6 + 2.4 * (1 - frac))
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
    local pulse = Calm() and 0.4 or (1 - (beat % 1))
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

------------------------------------------------------------------------
-- The Flood: the stage pitching under you, swimming, the water over your
-- head, and the lightning
------------------------------------------------------------------------

local function Flood() return S and S.id == "water" and S.phase == "apocalypse" end

hook.Add("SetupMove", "LivingCityFlood", function(p, mv)
    if not Flood() or p ~= LocalPlayer() or p:GetNW2Bool("lc_end_taken", false) or GetGlobal2Bool("lc_flood_real", false) then return end
    local z = GetGlobal2Float("lc_flood_z", 0)
    if z == 0 or p:GetPos().z + 40 >= z then return end
    local v = mv:GetVelocity()
    v.x, v.y = v.x * 0.9, v.y * 0.9
    v.z = math.max(v.z * 0.9, -50)
    if mv:KeyDown(IN_JUMP) then v.z = 220 end
    mv:SetVelocity(v)
end)

hook.Add("CalcView", "LivingCityFlood", function(me, origin, angles, fov)
    if not Flood() or not IsValid(me) or me:GetNW2Bool("lc_end_spectating", false) then return end
    local slosh = GetGlobal2Float("lc_flood_slosh", 0)
    local t = CurTime()
    local roll = math.sin(t * 1.1) * 9 * slosh + math.sin(t * 2.3) * 3 * slosh
    local pitch = math.sin(t * 0.8) * 4 * slosh
    return { origin = origin, angles = Angle(angles.p + pitch, angles.y, angles.r + roll), fov = fov }
end)

local flashSeen, flashUntil = 0, 0
local THUNDER = { "ambient/atmosphere/thunder1.wav", "ambient/atmosphere/thunder2.wav", "ambient/atmosphere/thunder3.wav", "ambient/atmosphere/thunder4.wav" }
hook.Add("Think", "LivingCityFloodSky", function()
    if not Flood() then return end
    local f = GetGlobal2Float("lc_flood_flash", 0)
    if f ~= flashSeen then
        flashSeen = f
        flashUntil = CurTime() + 0.3
        surface.PlaySound(THUNDER[math.random(#THUNDER)])
    end
end)

hook.Add("HUDPaint", "LivingCityFloodSky", function()
    if not Flood() then return end
    local now = CurTime()
    if now < flashUntil and not Calm() then
        surface.SetDrawColor(225, 235, 255, 200 * (flashUntil - now) / 0.3)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    local me = LocalPlayer()
    if IsValid(me) and not me:GetNW2Bool("lc_end_taken", false) and me:EyePos().z < GetGlobal2Float("lc_flood_z", 0) then
        draw.SimpleTextOutlined("Under the water: hold Jump to swim up", "LCEndText", ScrW() / 2, ScrH() * 0.8, Color(200, 225, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
    end
end)

hook.Add("RenderScreenspaceEffects", "LivingCityFloodSky", function()
    if not Flood() or not DrawColorModify then return end
    local me = LocalPlayer()
    if not IsValid(me) or me:EyePos().z >= GetGlobal2Float("lc_flood_z", 0) then return end
    DrawColorModify({ ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.03, ["$pp_colour_addb"] = 0.12, ["$pp_colour_brightness"] = -0.15,
        ["$pp_colour_contrast"] = 0.9, ["$pp_colour_colour"] = 0.5, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
end)

------------------------------------------------------------------------
-- Father Grigori on stage, the mic up at his mouth the whole time (his jaw
-- follows the song: MouthMoveAnimation above): headbanging hard on every
-- beat in the heavy parts, fist pumping; dancing in the rest, hips going,
-- the free arm waving. Tune the nod: lc_headbang_angle "p y r".
------------------------------------------------------------------------

local cvBang = CreateClientConVar("lc_headbang_angle", "0 48 0", true, false, "Father Grigori's headbang: how far his head goes down on each beat (pitch yaw roll)")
local MIC = "models/props_lab/reciever01d.mdl"
local rocked = {}

local function BangAngle()
    local p, y, r = string.match(cvBang:GetString() or "", "(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)")
    return Angle(tonumber(p) or 0, tonumber(y) or 48, tonumber(r) or 0)
end

local function RockBeat(now)
    local c = S and S.client
    if not c or not c.bpm then return now * 150 / 60 end
    local pos = (channel and channel.GetTime and channel:GetTime()) or (now - (c.start or now))
    return (pos - (c.offset or 0)) * c.bpm / 60
end

local function Bone(ply, name) return ply.LookupBone and ply:LookupBone("ValveBiped.Bip01_" .. name) end

hook.Add("Think", "LivingCityHeadbang", function()
    local now = CurTime()
    local beat = RockBeat(now)
    -- the nod: slammed down on the beat, back up between
    local down = (1 - (beat % 1)) ^ 2.2
    local pump = math.abs(math.sin(beat * math.pi))
    local bang = BangAngle()
    for _, ply in ipairs(player.GetAll()) do
        local on = IsValid(ply) and ply:GetNW2Bool("lc_rocking", false) and S and S.phase == "apocalypse"
        if on and ply.ManipulateBoneAngles then
            rocked[ply] = true
            local function Set(name, a) local id = Bone(ply, name) if id then ply:ManipulateBoneAngles(id, a) end end
            local sec = S.client and S.client.section or "intro"
            local wave = math.sin(beat * math.pi) -- (side to side, a beat each way)
            if sec == "heavy" or sec == "climax" then
                -- the heavy parts: headbanging, hard, and the fist pumping
                Set("Head", bang * down)
                Set("Neck1", bang * (down * 0.6))
                Set("Spine2", bang * (down * 0.35))
                Set("Pelvis", Angle(0, 0, 0))
                Set("L_UpperArm", Angle(-10, -60 - 50 * pump, 0))
                Set("L_Forearm", Angle(0, -60, 0))
                Set("R_Calf", Angle(0, 12 * pump, 0))
                Set("L_Calf", Angle(0, 12 * pump, 0))
            else
                -- the rest: dancing, the hips going, the free arm waving over his head
                Set("Head", Angle(0, 6 * pump, 10 * wave))
                Set("Neck1", Angle(0, 0, 0))
                Set("Spine2", Angle(0, 0, -8 * wave))
                Set("Pelvis", Angle(0, 0, 12 * wave))
                Set("L_UpperArm", Angle(25 * wave, -115, -10))
                Set("L_Forearm", Angle(0, -25 + 25 * wave, 0))
                Set("R_Calf", Angle(0, 20 * pump * (wave > 0 and 1 or 0.3), 0))
                Set("L_Calf", Angle(0, 20 * pump * (wave < 0 and 1 or 0.3), 0))
            end
            -- the mic up at his mouth, all the way through
            Set("R_UpperArm", Angle(10, -70, 0))
            Set("R_Forearm", Angle(0, -115, 0))
        elseif rocked[ply] then
            rocked[ply] = nil
            if IsValid(ply) then
                local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
                if IsValid(w) and w.SetNoDraw then w:SetNoDraw(false) end -- (his gun back)
                if IsValid(ply.lcMic) then ply.lcMic:Remove() ply.lcMic = nil end
            end
            if IsValid(ply) and ply.ManipulateBoneAngles then
                for _, name in ipairs({ "Head", "Neck1", "Spine2", "Pelvis", "R_UpperArm", "R_Forearm", "L_UpperArm", "L_Forearm", "R_Calf", "L_Calf" }) do
                    local id = Bone(ply, name)
                    if id then ply:ManipulateBoneAngles(id, Angle(0, 0, 0)) end
                end
            end
        end
    end
end)

-- his gun put away; the mic in his hand
hook.Add("PrePlayerDraw", "LivingCityHeadbang", function(ply)
    if not ply:GetNW2Bool("lc_rocking", false) then return end
    local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
    if IsValid(w) and w.SetNoDraw then w:SetNoDraw(true) end
end)
hook.Add("PostPlayerDraw", "LivingCityHeadbang", function(ply)
    if not ply:GetNW2Bool("lc_rocking", false) or not ClientsideModel then return end
    if not IsValid(ply.lcMic) then
        ply.lcMic = ClientsideModel(MIC, RENDERGROUP_OPAQUE)
        if not IsValid(ply.lcMic) then return end
        ply.lcMic:SetNoDraw(true)
        if ply.lcMic.SetModelScale then ply.lcMic:SetModelScale(0.6, 0) end
    end
    local id = Bone(ply, "R_Hand")
    local m = id and ply.GetBoneMatrix and ply:GetBoneMatrix(id)
    if not m then return end
    local pos, ang = m:GetTranslation(), m:GetAngles()
    ply.lcMic:SetPos(pos + ang:Forward() * 3 + ang:Right() * 1.5)
    ply.lcMic:SetAngles(ang)
    ply.lcMic:SetupBones()
    ply.lcMic:DrawModel()
end)

------------------------------------------------------------------------
-- Base: the opening lines as arcade subtitles, CATS in the sky, the bombs
-- blinking and beeping, the view from your ZIG, and the end of everything
------------------------------------------------------------------------

local function Base() return S and S.id == "base" and S.phase == "apocalypse" and S.client end
if surface and surface.CreateFont then
    surface.CreateFont("LCArcade", { font = "Courier New", size = 30, weight = 900, antialias = false })
end

local function SongTime(now)
    local c = S and S.client
    if channel and channel.GetTime then return channel:GetTime() end
    return now - ((c and c.start) or now)
end

local catsModel, catsSeen
hook.Add("PostDrawOpaqueRenderables", "LivingCityBase", function(_, sky)
    local c = Base()
    if sky or not c or not c.cats or not c.sky or not ClientsideModel then return end
    if not IsValid(catsModel) then
        catsModel = ClientsideModel("models/gman_high.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(catsModel) then return end
        catsModel:SetNoDraw(true)
        if catsModel.SetModelScale then catsModel:SetModelScale(40, 0) end
    end
    local now = CurTime()
    catsSeen = catsSeen or now
    if now - catsSeen < 1.2 and math.random() < 0.5 then return end -- (main screen turn on: it flickers in)
    local eye = EyePos()
    local at = Vector(c.sky.x, c.sky.y, c.sky.z) - Vector(0, 0, 2400)
    catsModel:SetPos(at)
    catsModel:SetAngles(Angle(0, (eye - at):Angle().y, 0))
    if render.SetColorModulation then render.SetColorModulation(1, 0.25, 0.2) end
    catsModel:SetupBones()
    catsModel:DrawModel()
    if render.SetColorModulation then render.SetColorModulation(1, 1, 1) end
end)

local lastBeep = -1
hook.Add("Think", "LivingCityBase", function()
    local c = Base()
    if not c then
        catsSeen = nil
        if IsValid(catsModel) then catsModel:Remove() catsModel = nil end
        return
    end
    local now = CurTime()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local beat = SongTime(now) * (c.bpm or 150) / 60
    local frac = beat % 1
    -- the bombs: a red light blinking on each, and a beep from the nearest
    local near, nd = nil, nil
    local n = 0
    for _, idx in ipairs(c.bombs or {}) do
        local b = Entity(idx)
        if IsValid(b) then
            local d = b:GetPos():DistToSqr(me:GetPos())
            if not nd or d < nd then near, nd = b, d end
            if DynamicLight and n < 10 and d < 2000 * 2000 then
                n = n + 1
                local dl = DynamicLight(52300 + n)
                if dl then
                    dl.pos = b:GetPos() + Vector(0, 0, 30)
                    dl.r, dl.g, dl.b = 255, 30, 20
                    dl.brightness = Calm() and 1.2 or (frac < 0.3 and 3 or 0)
                    dl.size = 160
                    dl.decay = 0
                    dl.dietime = now + 0.12
                end
            end
        end
    end
    if near and nd < 600 * 600 and math.floor(beat) ~= lastBeep then
        lastBeep = math.floor(beat)
        if sound and sound.Play then sound.Play("buttons/blip1.wav", near:GetPos(), 70, 120, 0.6) end
    end
end)

-- on your ZIG: the view from behind it
hook.Add("CalcView", "LivingCityBase", function(me, origin, angles, fov)
    if not (S and S.phase == "apocalypse") or not IsValid(me) or me:GetNW2Bool("lc_end_spectating", false) then return end
    local z = me:GetNW2Entity("lc_riding")
    if not IsValid(z) then return end
    return { origin = z:GetPos() + Vector(0, 0, 220) - angles:Forward() * 700, angles = angles, fov = fov, drawviewer = true }
end)

hook.Add("HUDPaint", "LivingCityBase", function()
    local c = Base()
    if not c then return end
    local now = CurTime()
    local w, h = ScrW(), ScrH()
    -- the lines, the way the game showed them
    local st = SongTime(now)
    local line
    for i, l in ipairs(c.lines or {}) do
        local nxt = c.lines[i + 1]
        if st >= l.t and st < math.min(l.t + 4, nxt and nxt.t or l.t + 4) then line = l.text end
    end
    if line then
        surface.SetDrawColor(0, 0, 0, 230)
        surface.DrawRect(w * 0.1, h * 0.78, w * 0.8, 60)
        draw.SimpleText(line, "LCArcade", w / 2, h * 0.78 + 30, Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    -- main screen turn on: static, a moment
    if catsSeen and now - catsSeen < 1.2 and not Calm() then
        for _ = 1, 120 do
            local g = math.random(60, 220)
            surface.SetDrawColor(g, g, g, 140)
            surface.DrawRect(math.random(0, w), math.random(0, h), math.random(20, 120), 2)
        end
    end
    -- for great justice: the white
    if c.boomAt and now - c.boomAt < 3 then
        surface.SetDrawColor(255, 255, 255, 255 * math.Clamp(1 - (now - c.boomAt) / 3, 0, 1))
        surface.DrawRect(0, 0, w, h)
    end
end)

-- Base: the whole screen blocky, like the old arcade game (the subtitles stay
-- sharp: they're drawn after). lc_pixel_size: how big the blocks are.
local cvPixel = CreateClientConVar("lc_pixel_size", "6", true, false, "How big the blocks are in the Base ending's arcade look (1: off)")
local pixRT, pixMat, pixW, pixH
hook.Add("RenderScreenspaceEffects", "LivingCityBasePixels", function()
    if not Base() or not render or not render.UpdateScreenEffectTexture or not GetRenderTarget or not CreateMaterial then return end
    local size = math.Clamp(cvPixel:GetInt(), 1, 32)
    if size <= 1 then return end
    local w, h = math.max(16, math.floor(ScrW() / size)), math.max(16, math.floor(ScrH() / size))
    if not pixRT or pixW ~= w or pixH ~= h then
        pixW, pixH = w, h
        pixRT = GetRenderTarget("lc_pixels_" .. w .. "x" .. h, w, h)
        pixMat = CreateMaterial("lc_pixels_mat_" .. w .. "x" .. h, "UnlitGeneric", { ["$basetexture"] = pixRT:GetName(), ["$ignorez"] = 1, ["$vertexcolor"] = 1 })
    end
    render.UpdateScreenEffectTexture()
    local screen = render.GetScreenEffectTexture()
    render.PushRenderTarget(pixRT)
    render.DrawTextureToScreen(screen) -- (squeezed down: the detail goes)
    render.PopRenderTarget()
    render.PushFilterMag(TEXFILTER.POINT)
    render.PushFilterMin(TEXFILTER.POINT)
    render.SetMaterial(pixMat)
    render.DrawScreenQuad() -- (and back up, no smoothing: blocks)
    render.PopFilterMin()
    render.PopFilterMag()
end)

------------------------------------------------------------------------
-- Hard: PARTY HARD, everywhere, flashing
------------------------------------------------------------------------

if surface and surface.CreateFont then
    surface.CreateFont("LCPartyHard", { font = "Impact", size = 72, weight = 900 })
    surface.CreateFont("LCPartyHardSmall", { font = "Impact", size = 40, weight = 900 })
end
local partySpots, partyBeat = {}, -1
local function Hard() return S and S.id == "hard" and S.phase == "apocalypse" and S.client end

hook.Add("HUDPaint", "LivingCityHard", function()
    local c = Hard()
    if not c then return end
    local now = CurTime()
    local beat = Beat(now)
    local half = math.floor(beat * 2)
    local pal = c.palette or PALETTE
    local w, h = ScrW(), ScrH()
    -- the whole screen flashes a colour on the beat
    if c.strobe and not Calm() and (beat % 1) < 0.18 then
        local c0 = pal[math.floor(beat) % #pal + 1]
        surface.SetDrawColor(c0[1] or c0.r or 255, c0[2] or c0.g or 255, c0[3] or c0.b or 255, 45)
        surface.DrawRect(0, 0, w, h)
    end
    if not c.partyText then return end
    -- PARTY HARD, somewhere new every half-beat
    if Calm() then half = math.floor(beat / 4) end -- (calm: it moves every few beats, not every half)
    if half ~= partyBeat then
        partyBeat = half
        partySpots = {}
        for i = 1, math.random(4, 8) do
            partySpots[i] = { x = math.random(80, w - 80), y = math.random(60, h - 60), c = pal[math.random(#pal)], big = math.random() < 0.4 }
        end
    end
    for _, sp in ipairs(partySpots) do
        draw.SimpleTextOutlined("PARTY HARD", sp.big and "LCPartyHard" or "LCPartyHardSmall", sp.x, sp.y,
            Color(sp.c[1] or sp.c.r or 255, sp.c[2] or sp.c.g or 255, sp.c[3] or sp.c.b or 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, Color(0, 0, 0, 230))
    end
end)

-- and over every dancer's head
hook.Add("PostDrawTranslucentRenderables", "LivingCityHard", function(_, sky)
    local c = Hard()
    if sky or not c or not c.partyText or not cam or not cam.Start3D2D then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local beat = Beat(CurTime())
    local pal = c.palette or PALETTE
    local n = 0
    for _, e in ipairs(dancers) do
        if IsValid(e) and n < 20 and e:GetPos():DistToSqr(me:GetPos()) < 1500 * 1500 and not (e.GetNoDraw and e:GetNoDraw()) then
            n = n + 1
            local c0 = pal[(math.floor(beat * 2) + n) % #pal + 1]
            local pos = e:GetPos() + Vector(0, 0, 92)
            local ang = Angle(0, (me:EyePos() - pos):Angle().y + 90, 90)
            cam.Start3D2D(pos, ang, 0.25)
            draw.SimpleTextOutlined("PARTY HARD", "LCPartyHardSmall", 0, 0, Color(c0[1] or 255, c0[2] or 255, c0[3] or 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 230))
            cam.End3D2D()
        end
    end
end)

------------------------------------------------------------------------
-- The warning, as a flashing ending starts: leave the flashing out, or not
------------------------------------------------------------------------

local warnFrame
function LC_CL.FlashWarning()
    if not vgui or not vgui.Create then return end
    if IsValid(warnFrame) then warnFrame:Remove() end
    local f = vgui.Create("DFrame")
    warnFrame = f
    f:SetTitle("Photosensitivity warning")
    f:SetSize(460, 170)
    f:Center()
    f:MakePopup()
    local l = vgui.Create("DLabel", f)
    l:Dock(TOP)
    l:DockMargin(10, 6, 10, 6)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    l:SetText("What's about to happen has flashing lights, strobes and screen flashes. If that could be a problem for you, leave them out: the music, the dancing and everything else stay. (lc_ending_calm in the console changes it any time.)")
    local calm = vgui.Create("DButton", f)
    calm:Dock(BOTTOM)
    calm:DockMargin(10, 4, 10, 8)
    calm:SetTall(30)
    calm:SetText("Reduce flashing")
    calm.DoClick = function() RunConsoleCommand("lc_ending_calm", "1") f:Remove() end
    local fine = vgui.Create("DButton", f)
    fine:Dock(BOTTOM)
    fine:DockMargin(10, 4, 10, 0)
    fine:SetTall(26)
    -- (doing nothing is "I'm fine": it goes by itself after 8 seconds)
    local closeAt = CurTime() + 8
    fine:SetText("I'm fine, keep it (8)")
    fine.DoClick = function() f:Remove() end
    fine.Think = function(b)
        local left = math.ceil(closeAt - CurTime())
        if left <= 0 then f:Remove() return end
        b:SetText("I'm fine, keep it (" .. left .. ")")
    end
end

------------------------------------------------------------------------
-- Plane: the sing-along, the webcam, and up into the clouds
------------------------------------------------------------------------

if surface and surface.CreateFont then surface.CreateFont("LCNuma", { font = "Impact", size = 64, weight = 900 }) end
local function Plane() return S and S.id == "plane" and S.phase == "apocalypse" and S.client end
local camRT, camMat

hook.Add("HUDPaint", "LivingCityPlane", function()
    local c = Plane()
    if not c then return end
    local now = CurTime()
    local w, h = ScrW(), ScrH()
    local st = SongTime(now)
    -- the sing-along: the captions, and NUMA NUMA IEI on the choruses
    local cap
    for _, l in ipairs(c.captions or {}) do if st >= l.t and st < l.t + 1.1 then cap = l.text end end
    if not cap and (c.section == "chorus" or c.section == "final" or c.section == "board") then
        local beat = st * (c.bpm or 130) / 60
        if beat % 16 < 3 then cap = "NUMA NUMA IEI!" end
    end
    if cap then
        draw.SimpleTextOutlined(cap, "LCNuma", w / 2, h * 0.2, Color(255, 235, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, Color(0, 0, 0, 230))
    end
    -- your webcam: a grainy little box in the corner, your own face, mouthing along
    local me = LocalPlayer()
    if c.webcam and IsValid(me) and IsValid(me:GetNW2Entity("lc_riding")) and render and render.RenderView and GetRenderTarget and CreateMaterial then
        if not camRT then
            camRT = GetRenderTarget("lc_webcam_rt", 128, 96)
            camMat = CreateMaterial("lc_webcam_mat", "UnlitGeneric", { ["$basetexture"] = camRT:GetName(), ["$ignorez"] = 1, ["$vertexcolor"] = 1 })
        end
        local eyes = me.LookupAttachment and me:LookupAttachment("eyes")
        local att = eyes and eyes > 0 and me:GetAttachment(eyes)
        local face = att and att.Pos or (me:GetPos() + Vector(0, 0, 64))
        local fwd = (att and att.Ang or me:GetAngles()):Forward()
        local camPos = face + fwd * 28 + Vector(0, 0, 3)
        render.PushRenderTarget(camRT)
        render.RenderView({ origin = camPos, angles = (face - camPos):Angle(), x = 0, y = 0, w = 128, h = 96, fov = 60, drawviewer = true, drawhud = false })
        render.PopRenderTarget()
        local bw, bh = 256, 192
        local x, y = w - bw - 24, h - bh - 140
        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawRect(x - 6, y - 6, bw + 12, bh + 30)
        render.PushFilterMag(TEXFILTER.POINT)
        render.PushFilterMin(TEXFILTER.POINT)
        surface.SetMaterial(camMat)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x, y, bw, bh)
        render.PopFilterMin()
        render.PopFilterMag()
        draw.SimpleText((math.floor(now * 2) % 2 == 0 and "o " or "  ") .. "REC   webcam", "DermaDefaultBold", x + 6, y + bh + 12, Color(255, 80, 80), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    -- the climb: up into the clouds, and white
    if c.whiteAt then
        local a = math.Clamp((now - (c.whiteAt - 3)) / 3, 0, 1)
        surface.SetDrawColor(255, 255, 255, 255 * a)
        surface.DrawRect(0, 0, w, h)
    end
end)
