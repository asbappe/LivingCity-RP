--[[
    Living City: secret endings, on your screen (sv_livingcity_endings.lua)

      Time stopped: the colour drains out, the G-Man appears right in front
      of you (on your screen, wherever you were looking) and your view turns
      to him and stays there, he speaks, and the vote is on screen (1: let it
      happen, 2: skip it). The ending: its song, the
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

local songAt -- (when the song really started playing, by the clock)
local cvEndVol = CreateClientConVar("lc_ending_volume", "1", true, false, "How loud the secret endings' songs are for you (0 to 2)")
-- The song's volume: the server's for this song (a quiet recording), up by half in a
-- fight so it carries over the gunfire, times your own lc_ending_volume.
function LC_CL.EndingSongVolume()
    local loud = S and S.client and S.client.loud and 1.5 or 1
    return math.Clamp((S and S.songVolume or 1) * loud * cvEndVol:GetFloat(), 0, 3)
end
local songVolSet
hook.Add("Think", "LivingCityEndingSongVolume", function()
    if not channel or not channel.SetVolume then songVolSet = nil return end
    local v = LC_CL.EndingSongVolume()
    if v ~= songVolSet then songVolSet = v pcall(channel.SetVolume, channel, v) end
end)
local function StopSong()
    if channel and channel.Stop then pcall(channel.Stop, channel) end
    channel, songAt = nil, nil
end
-- How far into the song it is: by the clock from when it started, not the
-- player's own idea of it (for a variable-bitrate .mp3 that's an estimate
-- from the bitrate, and it drifts further off the longer it plays).
local function SongClock(now)
    if channel and songAt then return (now or CurTime()) - songAt end
    return nil
end

local function PlaySong(path)
    StopSong()
    if not path or path == "" then return end
    if LC_CL.SoundTrouble then LC_CL.SoundTrouble(path) end
    if sound and sound.PlayFile then
        sound.PlayFile("sound/" .. path, "noblock", function(ch, err, errName)
            if IsValid(ch) then
                if S and S.phase == "apocalypse" then
                    channel = ch
                    -- (the server's volume for this song, for a quiet recording, times your own)
                    if ch.SetVolume then ch:SetVolume(LC_CL.EndingSongVolume()) end
                    ch:Play()
                    songAt = CurTime()
                else ch:Stop() end
            elseif file.Exists("sound/" .. path, "GAME") and LC_CL.SoundTrouble then
                LC_CL.SoundTrouble(path, "the game can't open it (" .. tostring(errName or err) .. "): is it really the format its name says?")
            end
        end)
    elseif surface and surface.PlaySound then
        surface.PlaySound(path)
    end
end

-- The G-Man: on each person's own screen, standing right in front of
-- wherever they were looking when time stopped, and the view turns to him and
-- stays on him for the vote (the mouse can't look away).
local gman, gmanAt, gmanFrom
local function GmanGone()
    if IsValid(gman) then gman:Remove() end
    gman, gmanAt, gmanFrom = nil, nil, nil
end
local function GmanPlace()
    GmanGone()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local eye = me:EyePos()
    local ang = me:EyeAngles()
    local fwd = Angle(0, ang.y, 0):Forward()
    local tr = util.TraceLine({ start = eye, endpos = eye + fwd * 90, filter = me })
    local dist = math.Clamp((tr.Fraction or 1) * 90 - 20, 30, 90) -- (not into a wall)
    local spot = eye + fwd * dist
    local down = util.TraceLine({ start = spot, endpos = spot - Vector(0, 0, 300), filter = me })
    gmanAt = (down.Hit and down.HitPos) or (me:GetPos() + fwd * dist)
    gmanFrom = { ang = ang, t = CurTime() }
    if not ClientsideModel then return end
    gman = ClientsideModel("models/gman_high.mdl", RENDERGROUP_OPAQUE)
    if not IsValid(gman) then gman = nil return end
    gman:SetPos(gmanAt)
    gman:SetAngles(Angle(0, ang.y + 180, 0))
    for _, name in ipairs({ "idle_subtle", "idle" }) do
        local seq = gman:LookupSequence(name)
        if seq and seq >= 0 then gman:ResetSequence(seq) break end
    end
end
LC_CL.EndingGmanAt = function() return gmanAt end

hook.Add("Think", "LivingCityEndingGman", function()
    if IsValid(gman) and gman.FrameAdvance then gman:FrameAdvance() end -- (the only thing still moving)
end)

hook.Add("CalcView", "LivingCityEndingGman", function(me, origin, angles, fov)
    if not S or S.phase ~= "gman" or not gmanAt or not gmanFrom then return end
    local want = ((gmanAt + Vector(0, 0, 62)) - origin):Angle()
    local k = math.Clamp((CurTime() - gmanFrom.t) / 0.8, 0, 1)
    k = k * k * (3 - 2 * k)
    return { origin = origin, angles = LerpAngle(k, gmanFrom.ang, want), fov = fov, drawviewer = false }
end)

hook.Add("InputMouseApply", "LivingCityEndingGman", function(cmd)
    if S and S.phase == "gman" and gmanAt then
        cmd:SetMouseX(0) cmd:SetMouseY(0)
        return true
    end
end)

net.Receive("lc_ending", function()
    local t = net.ReadTable() or {}
    local was = S and S.phase
    if t.phase ~= "gman" then GmanGone() end
    if not t.phase then
        S, lineQueue, myVote, resetAt = nil, nil, nil, nil
        StopSong()
        return
    end
    S = t
    if t.phase == "gman" and was ~= "gman" then
        myVote = nil
        GmanPlace()
        if LC_CL.ClearVoices then LC_CL.ClearVoices() end
        if LC_CL.StopBreencast then LC_CL.StopBreencast() end
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

-- Who's Father Grigori, rocking out: a player, or the city's own (an NPC)
local function Rockers()
    local out = {}
    for _, p in ipairs(player.GetAll()) do out[#out + 1] = p end
    for _, n in ipairs(ents.FindByClass and ents.FindByClass("npc_*") or {}) do
        if IsValid(n) and n:GetNW2Bool("lc_rocking", false) then out[#out + 1] = n end
    end
    return out
end

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
local FLAP, SWAY, KNEE = 40, 14, 18
local PALETTE = { Color(255, 110, 200), Color(220, 90, 255), Color(100, 190, 255), Color(110, 255, 190), Color(255, 235, 110) }
local preview = false
local danced = {}   -- [ent] = true: someone we've turned bones on
local bonesOf = {}  -- [model] = { name = id }

-- A dancing ending (bloom, marrow): what the server says about it (the dance, the light, the beat).
local function Party() return S and S.phase == "apocalypse" and S.client and S.client.party and S.client or nil end
local Bloom = Party

-- How far into the song we are (the song itself if it's playing; else the clock, sped up the same way).
local function SongPos(now)
    local clock = SongClock(now)
    if clock then return clock end
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
    -- the kicks: one leg out straight on each beat, the other knee bent, left then right
    R_Thigh = function(w) return Angle(0, -55 * math.max(0, w), 0) end, L_Thigh = function(w) return Angle(0, -55 * math.max(0, -w), 0) end,
    R_Calf = function(w) return Angle(0, 26 * math.max(0, -w), 0) end, L_Calf = function(w) return Angle(0, 26 * math.max(0, w), 0) end,
}
local RAVE = {
    R_UpperArm = function(w) return Angle(20 * w, -110, 10) end, L_UpperArm = function(w) return Angle(20 * w, -110, -10) end,
    R_Forearm = function(w) return Angle(0, -20 + 30 * w, 0) end, L_Forearm = function(w) return Angle(0, -20 - 30 * w, 0) end,
    Head = function(w, b) return Angle(0, -10 * b, w * 8) end, Pelvis = function(w) return Angle(0, 0, w * 14) end,
    Spine2 = function(w) return Angle(0, 0, -w * 8) end,
    -- bigger kicks for the rave, high and out to the side
    R_Thigh = function(w) local k = math.max(0, w) return Angle(12 * k, -75 * k, 0) end, L_Thigh = function(w) local k = math.max(0, -w) return Angle(-12 * k, -75 * k, 0) end,
    R_Calf = function(w) return Angle(0, 34 * math.max(0, -w), 0) end, L_Calf = function(w) return Angle(0, 34 * math.max(0, w), 0) end,
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
    -- the crowd at the rope: both arms up, fists pumping on the beat
    if S and S.client and S.client.dance == "cheer" and not preview then
        if ent.GetNW2Float and ent:GetNW2Float("lc_hanged", 0) > 0 then return end -- (not the hanged: they've their own)
        local CHEER = {
            R_UpperArm = Angle(10, -120 + 25 * bounce, 0), L_UpperArm = Angle(-10, -120 + 25 * (1 - bounce), 0),
            R_Forearm = Angle(0, -20, 0), L_Forearm = Angle(0, -20, 0),
            Head = Angle(0, -12 * bounce, 0), R_Calf = Angle(0, 16 * bounce, 0), L_Calf = Angle(0, 16 * bounce, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, CHEER[name] or Angle(0, 0, 0)) end
        danced[ent] = true
        return
    end
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
        -- (on these models a bone's yaw is side to side and its roll front to back: the hips
        -- swing side to side under a chest that leans against them, and the hands bend at
        -- the wrist like ears flapping, rather than twisting)
        if name == "R_Hand" then a.y = a.y + flap
        elseif name == "L_Hand" then a.y = a.y - flap
        elseif name == "Pelvis" then a.y = a.y + wave * SWAY
        elseif name == "Spine2" then a.y = a.y - wave * SWAY * 0.8
        elseif name == "Head" then a.y = a.y + wave * 4
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
-- A chase camera that stops at a wall instead of going through it (and out
-- into the void past the map): from what it follows, out to where it wants to be.
local function SafeCam(from, to)
    if not util or not util.TraceHull then return to end
    local tr = util.TraceHull({ start = from, endpos = to, mins = Vector(-10, -10, -10), maxs = Vector(10, 10, 10), mask = MASK_SOLID_BRUSHONLY })
    if not tr or tr.StartSolid or not tr.Hit then return to end
    return tr.HitPos + (from - to):GetNormalized() * 12
end
LC_CL.EndingSafeCam = SafeCam

hook.Add("CalcView", "LivingCityBloom", function(me, origin, angles, fov)
    -- on the party bus: behind it, looking wherever you look
    local on = Party()
    local bus = on and on.bus and Entity(on.bus)
    if IsValid(me) and me:GetNW2Bool("lc_seated", false) and IsValid(bus) then
        local from = bus:GetPos() + Vector(0, 0, 140)
        return { origin = SafeCam(from, from - angles:Forward() * 520), angles = angles, fov = fov, drawviewer = true }
    end
    if not Dancing(me) then return end
    local a = math.rad(CurTime() * 18)
    local centre = me:GetPos() + Vector(0, 0, 45)
    local eye = SafeCam(centre, centre + Vector(math.cos(a) * 120, math.sin(a) * 120, 30))
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

local cvBang = CreateClientConVar("lc_headbang_angle", "0 0 30", true, false, "Father Grigori's headbang: how far his head goes down on each beat (pitch yaw roll; the neck and upper back follow it; \"0 0 -30\" if he bangs backwards)")
local MIC = "models/props_lab/reciever01d.mdl"
local rocked = {}

local function BangAngle()
    local str = cvBang:GetString() or ""
    if str == "0 48 0" then str = "0 0 30" end -- (the old setting nodded on the wrong axis: side to side)
    local p, y, r = string.match(str, "(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)")
    return Angle(tonumber(p) or 0, tonumber(y) or 0, tonumber(r) or 30)
end

local function RockBeat(now)
    local c = S and S.client
    if not c or not c.bpm then return now * 150 / 60 end
    local pos = SongClock(now) or (now - (c.start or now))
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
    for _, ply in ipairs(Rockers()) do
        local on = IsValid(ply) and ply:GetNW2Bool("lc_rocking", false) and S and S.phase == "apocalypse"
        -- (an NPC Grigori mouths the words here: players do it in MouthMoveAnimation)
        if on and not ply:IsPlayer() and channel and channel.GetLevel and ply.GetFlexIDByName then
            local l, r = channel:GetLevel()
            local w = math.Clamp(((l or 0) + (r or 0)) * 1.6, 0, 1)
            for _, name in ipairs(MOUTH) do
                local id = ply:GetFlexIDByName(name)
                if id then ply:SetFlexWeight(id, w) end
            end
        end
        if on and ply.ManipulateBoneAngles then
            rocked[ply] = true
            local function Set(name, a) local id = Bone(ply, name) if id then ply:ManipulateBoneAngles(id, a) end end
            local sec = S.client and S.client.section or "intro"
            local wave = math.sin(beat * math.pi) -- (side to side, a beat each way)
            if sec == "heavy" or sec == "climax" then
                -- the heavy parts: headbanging, hard, the whole upper body slamming down on
                -- the beat (head, neck and back each taking some of it), and the fist pumping
                Set("Head", bang * down)
                Set("Neck1", bang * (down * 0.8))
                Set("Spine2", bang * (down * 0.7))
                Set("Spine1", bang * (down * 0.5))
                Set("Pelvis", Angle(0, 0, 0))
                Set("L_UpperArm", Angle(-10, -60 - 50 * pump, 0))
                Set("L_Forearm", Angle(0, -60, 0))
                Set("R_Calf", Angle(0, 12 * pump, 0))
                Set("L_Calf", Angle(0, 12 * pump, 0))
            else
                -- the rest: dancing, the hips going, the free arm waving over his head
                -- (yaw is side to side on these bones, roll front to back)
                Set("Head", Angle(0, 10 * wave, 6 * pump))
                Set("Neck1", Angle(0, 0, 0))
                Set("Spine1", Angle(0, 0, 0))
                Set("Spine2", Angle(0, -10 * wave, 0))
                Set("Pelvis", Angle(0, 14 * wave, 0))
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
                for _, name in ipairs({ "Head", "Neck1", "Spine1", "Spine2", "Pelvis", "R_UpperArm", "R_Forearm", "L_UpperArm", "L_Forearm", "R_Calf", "L_Calf" }) do
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
local function DrawMic(ply)
    if not ply:GetNW2Bool("lc_rocking", false) or ply:GetNW2Bool("lc_crowd", false) or not ClientsideModel then return end -- (the mic's his alone)
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
end
hook.Add("PostPlayerDraw", "LivingCityHeadbang", DrawMic)
-- (the city's own Father Grigori, an NPC, gets his mic here)
hook.Add("PostDrawOpaqueRenderables", "LivingCityHeadbangNPC", function(_, sky)
    if sky or not S or S.id ~= "water" or S.phase ~= "apocalypse" then return end
    for _, n in ipairs(ents.FindByClass and ents.FindByClass("npc_monk") or {}) do
        if IsValid(n) and n:GetNW2Bool("lc_rocking", false) then DrawMic(n) end
    end
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
    local clock = SongClock(now)
    if clock then return clock end
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
    local from = z:GetPos() + Vector(0, 0, 120)
    return { origin = SafeCam(from, from + Vector(0, 0, 100) - angles:Forward() * 700), angles = angles, fov = fov, drawviewer = true }
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
    -- (doing nothing is "I'm fine": it goes by itself after 15 seconds, time enough to read it)
    local closeAt = CurTime() + 15
    fine:SetText("I'm fine, keep it (15)")
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

------------------------------------------------------------------------
-- Marrow: spotlights round the circle while everyone dances, purple and
-- orange, their beams sweeping the dark (faster in the rave)
------------------------------------------------------------------------

local beamMat, glowMat
hook.Add("PostDrawTranslucentRenderables", "LivingCityMarrowSpots", function(_, sky)
    local c = Party()
    if sky or not c or not c.spots or not c.lz or not render or not render.DrawBeam then return end
    beamMat = beamMat or (Material and Material("effects/lamp_beam"))
    glowMat = glowMat or (Material and Material("sprites/light_glow02_add"))
    local now = CurTime()
    local speed = (c.section == "rave" and 1.8) or (c.section == "outro" and 2.4) or 1
    local lz = Vector(c.lz.x, c.lz.y, c.lz.z)
    local R = c.spotR or 300
    for i = 1, 8 do
        local a = (i / 8) * math.pi * 2
        local base = lz + Vector(math.cos(a) * R, math.sin(a) * R, 8)
        local col = (i % 2 == 0) and Color(170, 60, 255, 200) or Color(255, 130, 20, 200)
        -- each one sweeps round and tilts on its own, out of step with the next
        local yaw = math.deg(a) + 180 + math.sin(now * 0.9 * speed + i) * 70
        local pitch = -50 + math.sin(now * 0.6 * speed + i * 1.7) * 25
        local dir = Angle(pitch, yaw, 0):Forward()
        if beamMat then
            render.SetMaterial(beamMat)
            render.DrawBeam(base, base + dir * 1100, 90, 0, 0.95, col)
            render.DrawBeam(base, base + dir * 500, 40, 0, 0.95, Color(col.r, col.g, col.b, 255))
        end
        if glowMat and render.DrawSprite then
            render.SetMaterial(glowMat)
            render.DrawSprite(base, 70, 70, Color(col.r, col.g, col.b, 255))
        end
    end
end)
hook.Add("Think", "LivingCityMarrowSpots", function()
    local c = Party()
    if not c or not c.spots or not c.lz or not DynamicLight then return end
    local lz = Vector(c.lz.x, c.lz.y, c.lz.z)
    local R = c.spotR or 300
    for i = 1, 8, 2 do -- (four lamps light the ground round them: enough for the colour, light on the frame rate)
        local a = (i / 8) * math.pi * 2
        local d = DynamicLight(52000 + i)
        if d then
            local purple = i % 4 == 1
            d.pos = lz + Vector(math.cos(a) * R, math.sin(a) * R, 40)
            d.r, d.g, d.b = purple and 170 or 255, purple and 60 or 130, purple and 255 or 20
            d.brightness = 3
            d.size = 420
            d.decay = 1000
            d.dietime = CurTime() + 0.2
        end
    end
end)

------------------------------------------------------------------------
-- Standup: the ropes, the struggling, and the view from the end of one
------------------------------------------------------------------------

local function Standup() return S and S.id == "standup" and S.phase == "apocalypse" and S.client end
local ropeMat
local hungPosed = {}

local function NeckOf(e)
    local id = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Head1")
    local m = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
    if m then return m:GetTranslation() end
    return e:GetPos() + Vector(0, 0, 62)
end

hook.Add("PostDrawTranslucentRenderables", "LivingCityStandup", function(_, sky)
    local c = Standup()
    if sky or not c or not render or not render.DrawBeam then return end
    ropeMat = ropeMat or (Material and Material("cable/rope"))
    if ropeMat then render.SetMaterial(ropeMat) end
    for _, h in ipairs(c.hangs or {}) do
        local e = Entity(h.e)
        if IsValid(e) and h.a then
            local neck = NeckOf(e)
            render.DrawBeam(Vector(h.a.x, h.a.y, h.a.z), neck, 2, 0, neck:Distance(Vector(h.a.x, h.a.y, h.a.z)) / 32, Color(255, 255, 255))
        end
    end
end)

-- hands at the rope and legs kicking; then limp, head over
hook.Add("Think", "LivingCityStandup", function()
    local c = Standup()
    if not c then
        for e in pairs(hungPosed) do
            if IsValid(e) and e.ManipulateBoneAngles then
                for _, name in ipairs({ "R_UpperArm", "L_UpperArm", "R_Forearm", "L_Forearm", "Head", "R_Calf", "L_Calf", "R_Thigh", "L_Thigh" }) do
                    local id = e:LookupBone("ValveBiped.Bip01_" .. name)
                    if id then e:ManipulateBoneAngles(id, Angle(0, 0, 0)) end
                end
            end
        end
        hungPosed = {}
        return
    end
    local now = CurTime()
    for _, h in ipairs(c.hangs or {}) do
        local e = Entity(h.e)
        if IsValid(e) and e.ManipulateBoneAngles then
            hungPosed[e] = true
            local limp = e:GetNW2Bool("lc_limp", false)
            local k = now * 9 + h.e
            local function Set(name, a) local id = e:LookupBone("ValveBiped.Bip01_" .. name) if id then e:ManipulateBoneAngles(id, a) end end
            if limp then
                Set("R_UpperArm", Angle(0, 0, 0)) Set("L_UpperArm", Angle(0, 0, 0))
                Set("R_Forearm", Angle(0, 0, 0)) Set("L_Forearm", Angle(0, 0, 0))
                Set("Head", Angle(0, 30, 25))
                Set("R_Calf", Angle(0, 8, 0)) Set("L_Calf", Angle(0, 8, 0))
                Set("R_Thigh", Angle(0, 0, 0)) Set("L_Thigh", Angle(0, 0, 0))
            else
                Set("R_UpperArm", Angle(15, -110, 0)) Set("L_UpperArm", Angle(-15, -110, 0))
                Set("R_Forearm", Angle(0, -120, 0)) Set("L_Forearm", Angle(0, -120, 0))
                Set("Head", Angle(0, -10, 10 * math.sin(k * 0.5)))
                Set("R_Thigh", Angle(0, -25 * math.max(0, math.sin(k)), 0)) Set("L_Thigh", Angle(0, -25 * math.max(0, -math.sin(k)), 0))
                Set("R_Calf", Angle(0, 40 * math.max(0, math.sin(k)), 0)) Set("L_Calf", Angle(0, 40 * math.max(0, -math.sin(k)), 0))
            end
        end
    end
end)

-- On the rope you're moved along it every tick, which the game takes for
-- running: stand still instead (the kicking and the limp are the bones, above).
hook.Add("CalcMainActivity", "LivingCityStandup", function(ply)
    if Standup() and IsValid(ply) and ply:GetNW2Float("lc_hanged", 0) > 0 then return ACT_MP_STAND_IDLE, -1 end
end)

-- strung up: you see yourself from a little way off, and can look about
hook.Add("CalcView", "LivingCityStandup", function(me, origin, angles, fov)
    if not Standup() or not IsValid(me) or me:GetNW2Float("lc_hanged", 0) <= 0 then return end
    return { origin = me:GetPos() + Vector(0, 0, 50) - angles:Forward() * 160, angles = angles, fov = fov, drawviewer = true }
end)

-- the hanged: a white cone hat over the head
local CONE = "models/props_junk/trafficcone001a.mdl"
local cones = {}
hook.Add("PostDrawOpaqueRenderables", "LivingCityStandupHats", function(_, sky)
    if sky then return end -- (the 3D skybox's pass: nothing to draw there, and the hats stay)
    local c = Standup()
    if not c or not ClientsideModel then
        for e, m in pairs(cones) do if IsValid(m) then m:Remove() end end
        cones = {}
        return
    end
    for _, h in ipairs(c.hangs or {}) do
        local e = Entity(h.e)
        if IsValid(e) then
            local m = cones[e]
            if not IsValid(m) then
                m = ClientsideModel(CONE, RENDERGROUP_OPAQUE)
                if IsValid(m) then
                    m:SetNoDraw(true)
                    if m.SetMaterial then m:SetMaterial("models/debug/debugwhite") end
                    if m.SetModelScale then m:SetModelScale(0.9, 0) end
                    cones[e] = m
                end
            end
            if IsValid(m) then
                local id = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Head1")
                local mat = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
                local head = mat and mat:GetTranslation() or (e:GetPos() + Vector(0, 0, 64))
                m:SetPos(head - Vector(0, 0, 9)) -- (pulled down over the head)
                m:SetAngles(Angle(0, e:GetAngles().y, 0))
                if render.SetColorModulation then render.SetColorModulation(0.96, 0.96, 0.96) end
                m:SetupBones()
                m:DrawModel()
                if render.SetColorModulation then render.SetColorModulation(1, 1, 1) end
            end
        end
    end
end)
