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
    -- his idle (the model's own), and the tie he straightens now and then
    local idle = gman.SelectWeightedSequence and ACT_IDLE and gman:SelectWeightedSequence(ACT_IDLE) or -1
    if not idle or idle < 0 then
        for _, name in ipairs({ "idle_subtle", "idle", "Idle01", "standing_idle" }) do
            idle = gman:LookupSequence(name)
            if idle and idle >= 0 then break end
        end
    end
    gman.lcIdle = idle
    for _, name in ipairs({ "tiefidget", "Tie_Adjust", "adjust_tie" }) do
        local f = gman:LookupSequence(name)
        if f and f >= 0 then gman.lcFidget = f break end
    end
    gman.lcNextFidget = CurTime() + math.Rand(3, 6)
    if idle and idle >= 0 then gman:ResetSequence(idle) gman.lcSeqT0 = CurTime() end
end
LC_CL.EndingGmanAt = function() return gmanAt end

-- (a model drawn only on your screen doesn't animate by itself: he's moved along by the
-- clock, the only thing in the world still moving)
hook.Add("Think", "LivingCityEndingGman", function()
    if not IsValid(gman) then return end
    local now = CurTime()
    local fidgeting = gman.lcFidgetUntil and now < gman.lcFidgetUntil
    if not fidgeting and gman.lcFidget and now >= (gman.lcNextFidget or math.huge) then
        local d = gman.SequenceDuration and gman:SequenceDuration(gman.lcFidget) or 0
        gman.lcFidgetUntil = now + ((d and d > 0) and d or 3)
        gman.lcNextFidget = gman.lcFidgetUntil + math.Rand(5, 9)
        fidgeting = true
    end
    local seq = fidgeting and gman.lcFidget or gman.lcIdle
    if seq and seq >= 0 then
        if gman.GetSequence and gman:GetSequence() ~= seq then gman:ResetSequence(seq) gman.lcSeqT0 = now end
        local d = gman.SequenceDuration and gman:SequenceDuration(seq) or 0
        if not d or d <= 0 then d = 3 end
        if gman.SetCycle then gman:SetCycle(((now - (gman.lcSeqT0 or now)) / d) % 1) end
    end
    -- and his mouth, while he speaks
    if gman.GetFlexIDByName then
        local talking = LC_CL.gmanTalkUntil and now < LC_CL.gmanTalkUntil
        local w = talking and (math.abs(math.sin(now * 11)) * (0.35 + 0.65 * math.abs(math.sin(now * 3.7)))) or 0
        for _, name in ipairs({ "jaw_drop", "right_part", "left_part" }) do
            local id = gman:GetFlexIDByName(name)
            if id then gman:SetFlexWeight(id, w) end
        end
    end
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
    d = (d and d > 0.2) and d or 4
    lineNext = CurTime() + d + 0.6
    LC_CL.gmanTalkUntil = CurTime() + d -- (his mouth moves while he speaks)
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
    Pelvis = Angle(0, 0, 0), Spine = Angle(0, 0, 0), Spine2 = Angle(0, 0, 0), Head = Angle(0, 0, 0),
    R_Thigh = Angle(0, 0, 0), L_Thigh = Angle(0, 0, 0), R_Calf = Angle(0, 0, 0), L_Calf = Angle(0, 0, 0),
}
local FLAP, SWAY, KNEE = 40, 12, 18
-- (the palms turned to face forward, a twist of the forearm: lc_bloom_palm -90 if they face back)
local cvPalm = CreateClientConVar("lc_bloom_palm", "90", true, false, "Bloom's dance: how far the forearms twist to turn the palms forward (-90 if they end up facing back)")
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

-- Shalom's hora: arms out on the neighbours' shoulders, and the grapevine on the beat
-- (out to the side, cross behind, out, kick and hop, step, kick the other); the arms go up
-- for the rush into the middle; up on a chair, sat down, arms waving. The walk is the same
-- step at half speed; at the very start everyone just stands arm in arm, then sways.
-- Tune the arms live: lc_shalom_pose <R_UpperArm|L_UpperArm|R_Forearm|L_Forearm> <p> <y> <r>.
local HORA = {
    R_UpperArm = Angle(-30, -75, 0), L_UpperArm = Angle(30, -75, 0),
    R_Forearm = Angle(-15, 0, 0), L_Forearm = Angle(15, 0, 0),
}
local function HoraPose(ent, b, beat)
    local sec = S.client.section or "intro"
    if sec == "walk" then beat = beat / 2 end
    local k = math.floor(beat) % 6
    local s = math.sin(math.pi * (beat % 1)) -- (each step: out and back within its beat)
    local chair = ent.GetNW2Bool and ent:GetNW2Bool("lc_chair", false)
    local P = {}
    if sec == "in" or chair then
        P.R_UpperArm, P.L_UpperArm = Angle(-10, -140 + 15 * s, 0), Angle(10, -140 + 15 * s, 0)
        P.R_Forearm, P.L_Forearm = Angle(0, 0, 0), Angle(0, 0, 0)
    else
        P.R_UpperArm, P.L_UpperArm, P.R_Forearm, P.L_Forearm = HORA.R_UpperArm, HORA.L_UpperArm, HORA.R_Forearm, HORA.L_Forearm
    end
    if chair then
        P.R_Thigh, P.L_Thigh = Angle(0, -85, 0), Angle(0, -85, 0)
        P.R_Calf, P.L_Calf = Angle(0, 85, 0), Angle(0, 85, 0)
        P.Head = Angle(0, 10 * math.sin(beat * math.pi), 0)
    elseif sec == "gather" then
        P.Pelvis = Angle(0, 10 * math.sin(beat * math.pi), 0)
        P.Spine = Angle(0, -10 * math.sin(beat * math.pi), 0)
        P.R_Calf, P.L_Calf = Angle(0, 12 * s, 0), Angle(0, 12 * s, 0)
    elseif sec ~= "intro" and sec ~= "end" then
        if k == 0 or k == 2 then P.L_Thigh = Angle(-14 * s, 0, 0)
        elseif k == 1 then P.R_Thigh = Angle(-8 * s, 14 * s, 0)
        elseif k == 3 then P.R_Thigh = Angle(0, -38 * s, 0) P.L_Calf = Angle(0, 14 * s, 0)
        elseif k == 4 then P.R_Calf = Angle(0, 10 * s, 0)
        else P.L_Thigh = Angle(0, -38 * s, 0) P.R_Calf = Angle(0, 14 * s, 0) end
        P.Head = Angle(6 * s, 0, 0)
    end
    for name, id in pairs(b) do ent:ManipulateBoneAngles(id, P[name] or Angle(0, 0, 0)) end
end

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
        -- (on the arms pitch swings forward and back, mirrored: the right arm forward is minus,
        -- the left plus; the elbow bends on pitch too; yaw raises an arm out to the side)
        local NUMA = {
            R_UpperArm = Angle(-60 + 18 * math.sin(ph), -20 + 10 * math.cos(ph), 0),
            L_UpperArm = Angle(60 + 18 * math.sin(ph + math.pi), -20 + 10 * math.cos(ph + math.pi), 0),
            R_Forearm = Angle(-70 + 20 * math.sin(ph * 2), 0, 0),
            L_Forearm = Angle(70 + 20 * math.sin(ph * 2 + math.pi), 0, 0),
            Head = Angle(4 * bounce, 14 * math.sin(ph / 2), 0),
            Spine2 = Angle(0, 6 * wave, 0),
            Pelvis = Angle(0, 8 * wave, 0),
            R_Calf = Angle(0, 14 * bounce, 0), L_Calf = Angle(0, 14 * bounce, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, NUMA[name] or Angle(0, 0, 0)) end
        danced[ent] = true
        return
    end
    if S and S.client and S.client.dance == "hora" and not preview then
        HoraPose(ent, b, beat)
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
    -- hands higher above the head (they clip it otherwise): about 6 inches for a person,
    -- about 12 for the Combine's units, whose helmets and gear stand out further
    local mdl = string.lower(ent.GetModel and ent:GetModel() or "")
    local lift = (string.find(mdl, "police", 1, true) or string.find(mdl, "combine", 1, true) or string.find(mdl, "soldier", 1, true)) and 2 or 1
    for name, id in pairs(b) do
        local a = Angle(POSE[name].p, POSE[name].y, POSE[name].r)
        if name == "R_UpperArm" or name == "L_UpperArm" then a.y = a.y - 12 * lift
        elseif name == "R_Forearm" or name == "L_Forearm" then a.y = a.y + 10 * lift
        end
        -- (on these models a bone's yaw is side to side and its roll front to back: the hips
        -- swing side to side under a chest that leans against them, and the hands bend at
        -- the wrist like ears flapping, rather than twisting)
        -- (the sway: a curve up the back over legs that stay put, the knees dipping in turn;
        -- turning the hips themselves swung the legs and lifted the feet off the floor)
        if name == "R_Hand" then a.y = a.y + flap
        elseif name == "L_Hand" then a.y = a.y - flap
        elseif name == "R_Forearm" then a.r = a.r + cvPalm:GetFloat()
        elseif name == "L_Forearm" then a.r = a.r - cvPalm:GetFloat()
        elseif name == "Spine" then a.y = a.y + wave * SWAY
        elseif name == "Spine2" then a.y = a.y + wave * SWAY * 0.5
        elseif name == "Head" then a.y = a.y - wave * SWAY * 0.8
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

local cvBang = CreateClientConVar("lc_headbang_angle", "35 0 0", true, false, "Father Grigori's headbang: how far his head goes down on each beat (pitch yaw roll; the neck and upper back follow it; \"-35 0 0\" if he bangs backwards)")
local MIC = "models/props_lab/reciever01d.mdl"
local rocked = {}

local function BangAngle()
    local str = cvBang:GetString() or ""
    -- (the old settings turned the head the wrong way: "0 48 0" side to side, "0 0 30" a twist)
    if str == "0 48 0" or str == "0 0 30" then str = "35 0 0" end
    local p, y, r = string.match(str, "(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)")
    return Angle(tonumber(p) or 35, tonumber(y) or 0, tonumber(r) or 0)
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
    -- the nod: down on the beat, up between, smoothly (no snapping back: that looked like a twitch)
    local down = (0.5 + 0.5 * math.cos(beat * math.pi * 2)) ^ 1.6
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
                -- (the free arm: forward and up over his head, the fist pumping on the beat; on the
                -- arms pitch swings forward and back, yaw raises out to the side, roll twists)
                Set("L_UpperArm", Angle(110 + 35 * pump, -15, 0))
                Set("L_Forearm", Angle(25 * pump, 0, 0))
                Set("R_Calf", Angle(0, 12 * pump, 0))
                Set("L_Calf", Angle(0, 12 * pump, 0))
            else
                -- the rest: dancing, the hips going, the free arm waving over his head
                -- (yaw is side to side on these bones, roll front to back)
                Set("Head", Angle(8 * pump, 10 * wave, 0))
                Set("Neck1", Angle(0, 0, 0))
                Set("Spine1", Angle(0, 0, 0))
                Set("Spine2", Angle(0, -10 * wave, 0))
                Set("Pelvis", Angle(0, 14 * wave, 0))
                Set("L_UpperArm", Angle(140, -20 + 25 * wave, 0))
                Set("L_Forearm", Angle(15, 0, 0))
                Set("R_Calf", Angle(0, 20 * pump * (wave > 0 and 1 or 0.3), 0))
                Set("L_Calf", Angle(0, 20 * pump * (wave < 0 and 1 or 0.3), 0))
            end
            -- the mic up at his mouth, all the way through: the upper arm forward and down,
            -- the elbow bent right up (the elbow bends on pitch; yaw folded it sideways, a chicken wing)
            Set("R_UpperArm", Angle(-40, -10, 0))
            Set("R_Forearm", Angle(-125, 0, 0))
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

-- Base, the arcade: a score at the top that climbs with every bomb that goes off (a
-- "1000" popping up where it was), and blocky exhaust trails behind every ZIG.
local baseScore, bombsSeen, popups, trails = 0, {}, {}, {}
local TRAIL_COLS = { Color(255, 60, 40), Color(255, 200, 60), Color(255, 255, 255) }
hook.Add("Think", "LivingCityBaseArcade", function()
    local c = Base()
    if not c then baseScore, bombsSeen, popups, trails = 0, {}, {}, {} return end
    local now = CurTime()
    local live = {}
    for _, idx in ipairs(c.bombs or {}) do
        local b = Entity(idx)
        if IsValid(b) then live[idx] = b:GetPos() end
    end
    for idx, pos in pairs(bombsSeen) do
        if not live[idx] and not IsValid(Entity(idx)) then
            baseScore = baseScore + 1000
            popups[#popups + 1] = { pos = pos + Vector(0, 0, 60), t0 = now }
            bombsSeen[idx] = nil
        end
    end
    for idx, pos in pairs(live) do bombsSeen[idx] = pos end
    if c.boomAt and not c.boomScored then c.boomScored = true baseScore = baseScore + 50000 end
    -- the trails: where each ZIG has been, a few times a second
    for _, idx in ipairs(c.zigs or {}) do
        local z = Entity(idx)
        if IsValid(z) then
            local tr = trails[idx] or { at = 0 }
            trails[idx] = tr
            if now >= tr.at then
                tr.at = now + 0.06
                table.insert(tr, 1, z:GetPos() - z:GetForward() * 260 + Vector(0, 0, 40))
                while #tr > 24 do table.remove(tr) end
            end
        end
    end
    local keep = {}
    for _, pp in ipairs(popups) do if now - pp.t0 < 1.5 then keep[#keep + 1] = pp end end
    popups = keep
end)
hook.Add("PostDrawTranslucentRenderables", "LivingCityBaseArcade", function(_, sky)
    local c = Base()
    if sky or not c or not render or not render.SetColorMaterial then return end
    render.SetColorMaterial()
    local now = CurTime()
    for _, tr in pairs(trails) do
        for i, p in ipairs(tr) do
            local col = TRAIL_COLS[(i + math.floor(now * 8)) % #TRAIL_COLS + 1]
            local s = 34 - i
            if s > 4 then render.DrawBox(p, Angle(0, 0, 0), Vector(-s, -s, -s), Vector(s, s, s), Color(col.r, col.g, col.b, 200)) end
        end
    end
end)
hook.Add("HUDPaint", "LivingCityBaseArcade", function()
    local c = Base()
    if not c then return end
    local now = CurTime()
    local w = ScrW()
    draw.SimpleText(string.format("1UP  %07d", baseScore), "LCArcade", 40, 30, Color(255, 60, 40), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("HI-SCORE  %07d", math.max(baseScore, 1000000)), "LCArcade", w / 2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if math.floor(now * 2) % 2 == 0 then draw.SimpleText("INSERT COIN", "LCArcade", w - 40, 30, Color(255, 200, 60), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    for _, pp in ipairs(popups) do
        local sp = (pp.pos + Vector(0, 0, (now - pp.t0) * 60)):ToScreen()
        if sp.visible then draw.SimpleText("1000", "LCArcade", sp.x, sp.y, Color(255, 255, 255, 255 * (1 - (now - pp.t0) / 1.5)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
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
-- Spotlights round the circle (Marrow while everyone dances, purple and
-- orange; Hard's in every colour; the Flood's on the stage), their beams
-- sweeping the dark, faster in the wilder parts. c.spotEnt: they ride on it.
------------------------------------------------------------------------

local SPOT_COLS = { { 170, 60, 255 }, { 255, 130, 20 } }
local SPOT_FAST = { rave = 1.8, outro = 2.4, hard = 1.5, heavy = 1.5, climax = 2.2 }
local function Spots()
    local c = S and S.phase == "apocalypse" and S.client
    if not c or not c.spots or not (c.lz or c.spotEnt) then return nil end
    return c
end
local function SpotCentre(c)
    local e = c.spotEnt and Entity(c.spotEnt)
    if IsValid(e) then return e:GetPos() + Vector(0, 0, c.spotUp or 0) end
    return c.lz and Vector(c.lz.x, c.lz.y, c.lz.z) or nil
end
local beamMat, glowMat
hook.Add("PostDrawTranslucentRenderables", "LivingCityMarrowSpots", function(_, sky)
    local c = Spots()
    if sky or not c or not render or not render.DrawBeam then return end
    local lz = SpotCentre(c)
    if not lz then return end
    beamMat = beamMat or (Material and Material("effects/lamp_beam"))
    glowMat = glowMat or (Material and Material("sprites/light_glow02_add"))
    local now = CurTime()
    local speed = SPOT_FAST[c.section or ""] or 1
    local R = c.spotR or 300
    local cols = c.spotCols or SPOT_COLS
    local n = c.spotN or 8
    for i = 1, n do
        local a = (i / n) * math.pi * 2
        local base = lz + Vector(math.cos(a) * R, math.sin(a) * R, 8)
        local c0 = cols[(c.spotCycle and (i + math.floor(now * 2)) or i) % #cols + 1]
        local col = Color(c0[1] or c0.r, c0[2] or c0.g, c0[3] or c0.b, 200)
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
    local c = Spots()
    if not c or not DynamicLight then return end
    local lz = SpotCentre(c)
    if not lz then return end
    local R = c.spotR or 300
    local cols = c.spotCols or SPOT_COLS
    local n = c.spotN or 8
    for i = 1, n, 2 do -- (every other lamp lights the ground round it: enough for the colour, light on the frame rate)
        local a = (i / n) * math.pi * 2
        local d = DynamicLight(52400 + i)
        if d then
            local c0 = cols[i % #cols + 1]
            d.pos = lz + Vector(math.cos(a) * R, math.sin(a) * R, 40)
            d.r, d.g, d.b = c0[1] or c0.r, c0[2] or c0.g, c0[3] or c0.b
            d.brightness = 3
            d.size = 420
            d.decay = 1000
            d.dietime = CurTime() + 0.2
        end
    end
end)

------------------------------------------------------------------------
-- The party bus: a light rig on the roof, spotlights sweeping every colour,
-- strobes on the beat, and an underglow (steady, with lc_ending_calm 1)
------------------------------------------------------------------------

local busBeam, busGlow
-- Six lamps along the roof's edges: front, middle and back, either side.
local function Rig(bus)
    local mins, maxs = bus:OBBMins(), bus:OBBMaxs()
    local out = {}
    for _, fx in ipairs({ 0.9, 0.5, 0.1 }) do
        for _, fy in ipairs({ 0.1, 0.9 }) do
            out[#out + 1] = bus:LocalToWorld(Vector(Lerp(fx, mins.x, maxs.x), Lerp(fy, mins.y, maxs.y), maxs.z + 6))
        end
    end
    return out
end
hook.Add("PostDrawTranslucentRenderables", "LivingCityBusRig", function(_, sky)
    local c = Party()
    local bus = c and c.bus and Entity(c.bus)
    if sky or not IsValid(bus) or not render or not render.DrawBeam or not bus.OBBMaxs then return end
    busBeam = busBeam or (Material and Material("effects/lamp_beam"))
    busGlow = busGlow or (Material and Material("sprites/light_glow02_add"))
    local now = CurTime()
    local beat = Beat(now)
    local frac = beat % 1
    local calm = Calm()
    local pulse = calm and 0.7 or (0.45 + 0.55 * (1 - frac) ^ 1.5)
    local ang = bus:GetAngles()
    for i, base in ipairs(Rig(bus)) do
        local col = HSVToColor((beat * 40 + i * 60) % 360, 0.9, 1)
        -- each sweeps round on its own, out of step with the next, tilting up and down
        local yaw = ang.y + (i % 2 == 0 and 1 or -1) * (now * 70 + i * 60)
        local pitch = -25 + math.sin(now * 1.3 + i) * 35
        local dir = Angle(pitch, yaw, 0):Forward()
        if busBeam then
            render.SetMaterial(busBeam)
            render.DrawBeam(base, base + dir * 900, 70, 0, 0.95, Color(col.r, col.g, col.b, 200 * pulse))
        end
        if busGlow and render.DrawSprite then
            render.SetMaterial(busGlow)
            render.DrawSprite(base, 50, 50, Color(col.r, col.g, col.b, 255))
            -- the strobes: a white flash at every lamp on the beat
            if not calm and frac < 0.12 then render.DrawSprite(base, 140, 140, Color(255, 255, 255, 255)) end
        end
    end
end)
hook.Add("Think", "LivingCityBusRig", function()
    local c = Party()
    local bus = c and c.bus and Entity(c.bus)
    if not IsValid(bus) or not DynamicLight then return end
    local now = CurTime()
    local beat = Beat(now)
    local col = HSVToColor((beat * 40 + 180) % 360, 0.9, 1)
    -- the underglow, the colours going round
    local d = DynamicLight(52300)
    if d then
        d.pos = bus:GetPos() + Vector(0, 0, 10)
        d.r, d.g, d.b = col.r, col.g, col.b
        d.brightness = Calm() and 3 or (2 + 4 * (1 - beat % 1))
        d.size = 700
        d.decay = 0
        d.dietime = now + 0.15
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
-- (and the standing idle itself, named, so it's never the bind pose with the arms out)
hook.Add("CalcMainActivity", "LivingCityStandup", function(ply)
    if Standup() and IsValid(ply) and ply:GetNW2Float("lc_hanged", 0) > 0 then
        local seq = ply.LookupSequence and ply:LookupSequence("idle_all_01") or -1
        if not seq or seq < 0 then seq = ply.LookupSequence and ply:LookupSequence("idle_all_02") or -1 end
        return ACT_MP_STAND_IDLE, seq or -1
    end
end)
-- You can look about from the rope, but the body doesn't turn its head after you:
-- kicking, it's the struggle; limp, it hangs.
hook.Add("UpdateAnimation", "LivingCityStandup", function(ply)
    if not Standup() or not IsValid(ply) or ply:GetNW2Float("lc_hanged", 0) <= 0 or not ply.SetPoseParameter then return end
    for _, pp in ipairs({ "head_yaw", "head_pitch", "aim_yaw", "aim_pitch" }) do ply:SetPoseParameter(pp, 0) end
end)

-- strung up: you see yourself from a little way off, and can look about
hook.Add("CalcView", "LivingCityStandup", function(me, origin, angles, fov)
    if not Standup() or not IsValid(me) or me:GetNW2Float("lc_hanged", 0) <= 0 then return end
    return { origin = me:GetPos() + Vector(0, 0, 50) - angles:Forward() * 160, angles = angles, fov = fov, drawviewer = true }
end)

-- the white cone hats: pulled down over every hanged head, drawn on the head bone itself
local coneModel
hook.Add("PostDrawOpaqueRenderables", "LivingCityStandupCones", function(_, sky)
    local c = Standup()
    if sky or not c or not ClientsideModel then return end
    if not IsValid(coneModel) then
        coneModel = ClientsideModel("models/props_junk/trafficcone001a.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(coneModel) then return end
        coneModel:SetNoDraw(true)
        if coneModel.SetModelScale then coneModel:SetModelScale(0.85, 0) end
    end
    local white = render.MaterialOverride and Material and Material("models/debug/debugwhite")
    for _, h in ipairs(c.hangs or {}) do
        local e = Entity(h.e)
        if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then
            local id = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Head1")
            local m = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
            local pos, up = e:GetPos() + Vector(0, 0, 62), Vector(0, 0, 1)
            if m then pos, up = m:GetTranslation(), m:GetAngles():Forward() end -- (the head bone points up out of the top of the head)
            local ang = up:Angle()
            ang.p = ang.p + 90
            coneModel:SetPos(pos - up * 5)
            coneModel:SetAngles(ang)
            coneModel:SetupBones()
            if white then render.MaterialOverride(white) end
            if render.SetColorModulation then render.SetColorModulation(0.96, 0.96, 0.96) end
            coneModel:DrawModel()
            if render.SetColorModulation then render.SetColorModulation(1, 1, 1) end
            if white then render.MaterialOverride() end
        end
    end
end)

------------------------------------------------------------------------
-- Shalom: the hanukkiah, the flags, kippahs, the sayings, the fireworks
------------------------------------------------------------------------

if surface and surface.CreateFont then
    -- (extended: Hebrew letters are outside a font's usual range)
    surface.CreateFont("LCShalom", { font = "Arial", size = 40, weight = 800, extended = true })
    surface.CreateFont("LCShalomBig", { font = "Arial", size = 110, weight = 800, extended = true })
end
local function Shalom() return S and S.id == "shalom" and S.phase == "apocalypse" and S.client end
local BLUE, SNOW, GOLD, GOLD2 = Color(0, 56, 184), Color(250, 250, 250), Color(212, 168, 60), Color(170, 128, 40)

-- Hebrew reads right to left, and the game only draws left to right: its letters go in backwards.
function LC_CL.Hebrew(s)
    if not s or not string.find(s, "\215", 1, true) then return s end
    local chars = {}
    for ch in string.gmatch(s, "[^\128-\191][\128-\191]*") do table.insert(chars, 1, ch) end
    return table.concat(chars)
end

local SAYINGS = {
    "Oy vey!", "Oy gevalt!", "Mazel tov!", "L'chaim!", "Shalom!", "Chutzpah!", "Nu?", "Mensch!", "Kvetch, kvetch", "Schlep!",
    "Bubbeleh!", "Zei gezunt!", "Yalla!", "Sababa!", "Achla!", "Balagan!", "Tachles!", "Kapara!", "Kol hakavod!", "Oy li!",
    "Shkoyach!", "Mishpacha!", "Hava nagila!", "Am Yisrael chai!", "Toda raba!", "Ein ba'aya!", "Chag sameach!", "Shabbat shalom!",
    "Ma nishma?", "Yasher koach!", "Kvell!", "Nosh!", "Schmooze!", "Oy, mamaleh!", "Hakol beseder!", "Tov me'od!", "Ahalan!", "Baruch HaShem!",
    "שלום", "לחיים", "מזל טוב", "יאללה", "סבבה", "אחלה", "שבת שלום", "הבה נגילה", "עם ישראל חי", "תודה רבה", "כל הכבוד", "בלגן",
    "חג שמח", "אין בעיה", "בסדר",
}
LC_CL.ShalomSayings = SAYINGS
-- (the same on every screen: a number from 0 to 1 for a pair of numbers)
local function Hash(a, b) local x = math.sin(a * 12.9898 + b * 78.233) * 43758.5453 return x - math.floor(x) end

-- the sayings, over heads: each person says something new every two bars, floating up a little
hook.Add("PostDrawTranslucentRenderables", "LivingCityShalomSayings", function(_, sky)
    local c = Shalom()
    if sky or not c or not cam or not cam.Start3D2D then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now = CurTime()
    local t = SongPos(now)
    if t < (c.gatherAt or 7.4) or t >= (c.outroAt or math.huge) then return end
    local beat = Beat(now)
    local list = SAYINGS
    if c.sayings then
        list = {}
        for _, x in ipairs(SAYINGS) do list[#list + 1] = x end
        for _, x in ipairs(c.sayings) do list[#list + 1] = x end
    end
    local n = 0
    for _, e in ipairs(dancers) do
        if IsValid(e) and n < 24 and e:GetPos():DistToSqr(me:GetPos()) < 1500 * 1500 and not (e.GetNoDraw and e:GetNoDraw()) then
            local id = e:EntIndex()
            local cyc = (beat + (id * 3) % 8) / 8
            local k = math.floor(cyc)
            local f = cyc - k
            if f < 0.65 then
                n = n + 1
                local text = LC_CL.Hebrew(list[math.floor(Hash(id, k) * #list) % #list + 1])
                local alpha = 255 * math.Clamp(math.min(f * 8, (0.65 - f) * 8), 0, 1)
                local pos = e:GetPos() + Vector(0, 0, 88 + f * 14 + (e:GetNW2Bool("lc_chair", false) and 70 or 0))
                local ang = Angle(0, (me:EyePos() - pos):Angle().y + 90, 90)
                local blue = Hash(id, k + 0.5) < 0.5
                cam.Start3D2D(pos, ang, 0.22)
                draw.SimpleTextOutlined(text, "LCShalom", 0, 0, blue and Color(BLUE.r, BLUE.g, BLUE.b, alpha) or Color(255, 255, 255, alpha),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, blue and Color(255, 255, 255, alpha) or Color(BLUE.r, BLUE.g, BLUE.b, alpha))
                cam.End3D2D()
            end
        end
    end
end)

-- Kippahs: a flattened dome on top of every dancer's head, blue with a white rim or
-- white with a blue one, going on one head after another from when everyone gathers.
-- (Where it sits: lc_shalom_kippah, forward right up from the head bone, forward being
-- up out of the top of the head.)
local cvKippah = CreateClientConVar("lc_shalom_kippah", "6.5 0 -1", true, false, "Shalom: where the kippah sits on a head (forward right up from the head bone; forward is up out of the top of the head)")
hook.Add("PostDrawOpaqueRenderables", "LivingCityShalomKippah", function(_, sky)
    local c = Shalom()
    if sky or not c or not render or not render.DrawSphere or not Matrix or not cam or not cam.PushModelMatrix then return end
    local t = SongPos(CurTime())
    local from = c.gatherAt or 7.4
    if t < from then return end
    local fx, rx, ux = string.match(cvKippah:GetString() or "", "(%S+)%s+(%S+)%s+(%S+)")
    fx, rx, ux = tonumber(fx) or 6.5, tonumber(rx) or 0, tonumber(ux) or -1
    local eye = EyePos()
    render.SetColorMaterial()
    local n = 0
    for _, e in ipairs(dancers) do
        if IsValid(e) and n < 40 and e:GetNW2Bool("lc_dancing", false) and not (e.GetNoDraw and e:GetNoDraw())
            and e:GetPos():DistToSqr(eye) < 2500 * 2500 then
            local id = e:EntIndex()
            local bone = t >= from + (id % 16) * 0.44 and e.LookupBone and e:LookupBone("ValveBiped.Bip01_Head1")
            local m = bone and e.GetBoneMatrix and e:GetBoneMatrix(bone)
            if m then
                n = n + 1
                local mdl = string.lower(e.GetModel and e:GetModel() or "")
                local helmet = (string.find(mdl, "police", 1, true) or string.find(mdl, "combine", 1, true) or string.find(mdl, "soldier", 1, true)) and 2.5 or 0
                local ang = m:GetAngles()
                local pos = m:GetTranslation() + ang:Forward() * (fx + helmet) + ang:Right() * rx + ang:Up() * ux
                local blue = id % 2 == 0
                for part = 1, 2 do
                    local mat = Matrix()
                    mat:Translate(part == 1 and pos or (pos - ang:Forward() * 0.5))
                    mat:Rotate(ang)
                    mat:Scale(part == 1 and Vector(0.4, 1, 1) or Vector(0.14, 1.08, 1.08))
                    cam.PushModelMatrix(mat)
                    render.DrawSphere(Vector(0, 0, 0), 4.4, 14, 8, ((part == 1) == blue) and BLUE or SNOW)
                    cam.PopModelMatrix()
                end
            end
        end
    end
end)

-- A box along a line, from a to b (the hanukkiah's arms and stem).
local function Bar(a, b, th, col)
    local d = b - a
    local len = d:Length()
    if len < 0.01 then return end
    render.DrawBox(a, d:Angle(), Vector(0, -th, -th), Vector(len, th, th), col)
end

-- The flag of Israel on a waving surface: the white field, a blue stripe at the top and the
-- bottom, the Star of David in the middle. `across` and `down` are its edges, `normal` the way
-- it ripples (more towards the free end); drawn on both sides.
local function Flag(origin, across, down, normal, W, H, t, amp, cols)
    local function At(u, v, lift)
        return origin + across * (u * W) + down * (v * H) + normal * (math.sin(u * 7 - t * 4.5) * amp * u + (lift or 0))
    end
    local function Quad(a, b, c2, d, col) render.DrawQuad(a, b, c2, d, col) render.DrawQuad(d, c2, b, a, col) end
    local bands = { { 0, 0.094, SNOW }, { 0.094, 0.25, BLUE }, { 0.25, 0.75, SNOW }, { 0.75, 0.906, BLUE }, { 0.906, 1, SNOW } }
    for i = 0, cols - 1 do
        local u0, u1 = i / cols, (i + 1) / cols
        for _, bd in ipairs(bands) do Quad(At(u0, bd[1]), At(u1, bd[1]), At(u1, bd[2]), At(u0, bd[2]), bd[3]) end
    end
    -- the star: two triangles' outlines, a hair off the cloth on each side (in flag units: x across, y down)
    local R, th = 0.2 * H, 0.034 * H
    for tri = 0, 1 do
        for edge = 0, 2 do
            local a1, a2 = math.rad(-90 + tri * 180 + edge * 120), math.rad(-90 + tri * 180 + (edge + 1) * 120)
            local x1, y1 = W / 2 + math.cos(a1) * R, H / 2 + math.sin(a1) * R
            local x2, y2 = W / 2 + math.cos(a2) * R, H / 2 + math.sin(a2) * R
            local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
            local nx, ny = -(y2 - y1) / len * th / 2, (x2 - x1) / len * th / 2
            for seg = 0, 2 do
                local f0, f1 = seg / 3, (seg + 1) / 3
                local ax, ay = x1 + (x2 - x1) * f0, y1 + (y2 - y1) * f0
                local bx, by = x1 + (x2 - x1) * f1, y1 + (y2 - y1) * f1
                for _, side in ipairs({ 0.4, -0.4 }) do
                    local p1, p2 = At((ax + nx) / W, (ay + ny) / H, side), At((bx + nx) / W, (by + ny) / H, side)
                    local p3, p4 = At((bx - nx) / W, (by - ny) / H, side), At((ax - nx) / W, (ay - ny) / H, side)
                    if side > 0 then render.DrawQuad(p1, p2, p3, p4, BLUE) else render.DrawQuad(p4, p3, p2, p1, BLUE) end
                end
            end
        end
    end
end
LC_CL.ShalomFlag = Flag

-- (where the candle flames are this frame, for the glow; and how many were lit last frame)
local flames, litWas = {}, 0
local WIND = Vector(math.cos(0.6), math.sin(0.6), 0)

hook.Add("PostDrawOpaqueRenderables", "LivingCityShalom", function(_, sky)
    local c = Shalom()
    flames = {}
    if sky or not c or not render or not render.DrawBox then return end
    local now = CurTime()
    local t = SongPos(now)
    local eye = EyePos()
    render.SetColorMaterial()
    -- the hanukkiah: a giant one in the middle of the rings, turned to face you
    local m = c.menorah
    if m and m.pos then
        local base = Vector(m.pos.x, m.pos.y, m.pos.z)
        local w, h = m.w or 180, m.h or 170
        local toEye = Vector(eye.x - base.x, eye.y - base.y, 0)
        if toEye:LengthSqr() < 1 then toEye = Vector(1, 0, 0) end
        toEye:Normalize()
        local right, up = Vector(-toEye.y, toEye.x, 0), Vector(0, 0, 1)
        local flat = Angle(0, toEye:Angle().y, 0)
        local function P(x, z) return base + right * x + up * z end
        local th = w * 0.02 + 1.5
        local top, sp = h * 0.74, w / 9
        render.DrawBox(base, flat, Vector(-w * 0.2, -w * 0.12, 0), Vector(w * 0.2, w * 0.12, h * 0.05), GOLD2)
        Bar(P(0, h * 0.05), P(0, h * 0.86), th * 1.4, GOLD)
        for i = 1, 4 do
            for _, sgn in ipairs({ 1, -1 }) do
                Bar(P(0, top - h * 0.115 * i), P(sgn * i * sp, top), th, GOLD)
                render.DrawBox(P(sgn * i * sp, top), flat, Vector(-th * 1.8, -th * 1.8, 0), Vector(th * 1.8, th * 1.8, th * 1.6), GOLD2)
            end
        end
        render.DrawBox(P(0, h * 0.86), flat, Vector(-th * 2, -th * 2, 0), Vector(th * 2, th * 2, th * 1.6), GOLD2)
        -- the candles: the first on the right, each next one to its left; the shamash in the middle, higher, lit from the start
        local lit = 0
        for _, ct in ipairs(c.candles or {}) do if t >= ct then lit = lit + 1 end end
        local ch = h * 0.08
        for k = 0, 8 do
            local x = k == 0 and 0 or (k <= 4 and (5 - k) * sp or -(k - 4) * sp)
            local cb = k == 0 and P(0, h * 0.86 + th * 1.6) or P(x, top + th * 1.6)
            render.DrawBox(cb, flat, Vector(-th, -th, 0), Vector(th, th, ch), Color(235, 240, 255))
            if k <= lit then flames[#flames + 1] = cb + up * (ch + 3) end
        end
        if lit > litWas and sound and sound.Play then sound.Play("ambient/fire/ignite.wav", P(0, top), 80, 100, 1) end
        litWas = lit
    end
    -- the flags on their poles round the outside, run up one after another on the intro's hit
    for i, pole in ipairs(c.poles or {}) do
        local foot = Vector(pole.x, pole.y, pole.z)
        if foot:DistToSqr(eye) < 3500 * 3500 then
            local PH = 200
            render.DrawBox(foot, Angle(0, 0, 0), Vector(-1.5, -1.5, 0), Vector(1.5, 1.5, PH), Color(225, 225, 230))
            local hoist = math.Clamp((t - 0.4 - (i - 1) * 0.8) / 1.0, 0, 1)
            hoist = hoist * hoist * (3 - 2 * hoist)
            local topZ = foot.z + 50 + (PH - 52) * hoist
            Flag(Vector(foot.x, foot.y, topZ) + WIND * 1.5, WIND, Vector(0, 0, -1), Vector(WIND.y, -WIND.x, 0), 66, 48, now + i, 5, 10)
        end
    end
    -- at the key change, a giant one unfurls across the sky, facing you
    if c.sky and c.peakAt and t >= c.peakAt then
        local u = math.Clamp((t - c.peakAt) / 2.5, 0, 1)
        u = 1 - (1 - u) ^ 3
        local sk = Vector(c.sky.x, c.sky.y, c.sky.z)
        local toEye = Vector(eye.x - sk.x, eye.y - sk.y, 0)
        if toEye:LengthSqr() < 1 then toEye = Vector(1, 0, 0) end
        toEye:Normalize()
        local across = Vector(-toEye.y, toEye.x, 0)
        local W, H = 660, 480
        Flag(sk - across * (W / 2) + Vector(0, 0, H / 2), across, Vector(0, 0, -1), toEye, W * u, H, now, 22, 16)
    end
end)

-- Star of David fireworks, in the sky over everyone: every four beats at the key change,
-- every eight in the last run (the same bursts on every screen).
local bursts, burstBeat = {}, nil
local BURST_COLS = { Color(80, 140, 255), Color(255, 255, 255), Color(255, 210, 110) }
hook.Add("Think", "LivingCityShalom", function()
    local c = Shalom()
    if not c then bursts, burstBeat, litWas = {}, nil, 0 return end
    local now = CurTime()
    local beat = math.floor(Beat(now))
    local every = c.section == "peak" and 4 or (c.section == "final" and 8 or nil)
    if every and c.sky and beat ~= burstBeat and beat % every == 0 then
        burstBeat = beat
        local sk = Vector(c.sky.x, c.sky.y, c.sky.z)
        local pos = sk + Vector((Hash(beat, 1) - 0.5) * 1000, (Hash(beat, 2) - 0.5) * 1000, -Hash(beat, 3) * 220)
        bursts[#bursts + 1] = { t0 = now, pos = pos, col = BURST_COLS[beat % #BURST_COLS + 1], size = 150 + Hash(beat, 4) * 120 }
        if sound and sound.Play then sound.Play("ambient/explosions/explode_" .. (beat % 3 + 7) .. ".wav", pos, 100, 150, 0.6) end
    end
    local keep = {}
    for _, b in ipairs(bursts) do if now - b.t0 < 2.6 then keep[#keep + 1] = b end end
    bursts = keep
    -- the warm glow of the lit candles, and a flash of light for each burst
    if DynamicLight then
        if #flames > 0 then
            local dl = DynamicLight(52300)
            if dl then
                dl.pos = flames[1] + Vector(0, 0, 10)
                dl.r, dl.g, dl.b = 255, 170, 80
                dl.brightness = 2 + 0.4 * math.sin(now * 13)
                dl.size = 260 + 40 * #flames
                dl.decay = 0
                dl.dietime = now + 0.15
            end
        end
        if not Calm() then
            for i, b in ipairs(bursts) do
                if now - b.t0 < 0.4 then
                    local dl = DynamicLight(52310 + i)
                    if dl then
                        dl.pos = b.pos
                        dl.r, dl.g, dl.b = b.col.r, b.col.g, b.col.b
                        dl.brightness = 4
                        dl.size = 1400
                        dl.decay = 0
                        dl.dietime = now + 0.1
                    end
                end
            end
        end
    end
end)

local glow
hook.Add("PostDrawTranslucentRenderables", "LivingCityShalom", function(_, sky)
    local c = Shalom()
    if sky or not c or not render or not render.DrawSprite then return end
    glow = glow or (Material and Material("sprites/light_glow02_add"))
    if glow then render.SetMaterial(glow) end
    local now = CurTime()
    -- the candle flames, flickering
    for i, f in ipairs(flames) do
        local fl = math.sin(now * 17 + i * 2.1) * 1.5
        render.DrawSprite(f + Vector(0, 0, fl * 0.5), 7, 13 + fl, Color(255, 190, 90))
        render.DrawSprite(f, 26, 26, Color(255, 140, 40, 120))
    end
    -- the fireworks: the star's outline spreading out from the burst, then drifting down and fading
    local eye = EyePos()
    for _, b in ipairs(bursts) do
        local age = now - b.t0
        local e = 1 - (1 - math.min(age / 0.7, 1)) ^ 3
        local alpha = 255 * math.Clamp(1 - (age - 1.2) / 1.4, 0, 1)
        local toEye = eye - b.pos
        toEye.z = 0
        if toEye:LengthSqr() < 1 then toEye = Vector(1, 0, 0) end
        toEye:Normalize()
        local right, up = Vector(-toEye.y, toEye.x, 0), Vector(0, 0, 1)
        local droop = up * (-30 * age * age)
        local col = Color(b.col.r, b.col.g, b.col.b, alpha)
        for tri = 0, 1 do
            for edge = 0, 2 do
                local a1, a2 = math.rad(90 + tri * 180 + edge * 120), math.rad(90 + tri * 180 + (edge + 1) * 120)
                for s = 0, 5 do
                    local f = s / 6
                    local x = math.cos(a1) + (math.cos(a2) - math.cos(a1)) * f
                    local y = math.sin(a1) + (math.sin(a2) - math.sin(a1)) * f
                    render.DrawSprite(b.pos + (right * x + up * y) * (b.size * e) + droop, 34, 34, col)
                end
            end
        end
        if age < 0.25 and not Calm() then render.DrawSprite(b.pos, 320, 320, Color(b.col.r, b.col.g, b.col.b, 200 * (1 - age / 0.25))) end
    end
end)

-- the end: Am Yisrael chai, then Shalom
hook.Add("HUDPaint", "LivingCityShalom", function()
    local c = Shalom()
    if not c or not c.outroAt then return end
    local t = SongPos(CurTime())
    local x0 = t - c.outroAt
    if x0 < 0 then return end
    local w, h = ScrW(), ScrH()
    local first = x0 < 7
    local a = 255 * math.Clamp(first and math.min(x0 / 1.5, (7 - x0) / 1) or (x0 - 7) / 1.5, 0, 1)
    local big = first and "עם ישראל חי" or "שלום"
    draw.SimpleTextOutlined(LC_CL.Hebrew(big), "LCShalomBig", w / 2, h * 0.42, Color(255, 255, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(BLUE.r, BLUE.g, BLUE.b, a))
    draw.SimpleTextOutlined(first and "Am Yisrael chai" or "Shalom", "LCShalom", w / 2, h * 0.42 + 80, Color(BLUE.r, BLUE.g, BLUE.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(255, 255, 255, a))
end)

-- tuning the hora's arms (only on your screen)
concommand.Add("lc_shalom_pose", function(_, _, args)
    local name = args[1]
    if not name or not HORA[name] then print("[Living City] lc_shalom_pose <R_UpperArm|L_UpperArm|R_Forearm|L_Forearm> <pitch> <yaw> <roll>") return end
    HORA[name] = Angle(tonumber(args[2]) or 0, tonumber(args[3]) or 0, tonumber(args[4]) or 0)
end)
concommand.Add("lc_shalom_pose_print", function()
    for _, n in ipairs({ "R_UpperArm", "L_UpperArm", "R_Forearm", "L_Forearm" }) do print(string.format("%s = Angle(%g, %g, %g)", n, HORA[n].p, HORA[n].y, HORA[n].r)) end
end)

-- Anyone an ending moves about (dancing in a ring, riding the plane, a ZIG or the bus) is
-- moved every tick, which the game takes for running: they stand instead, and the dance is
-- the bones on top (the standing idle named, so it's never the bind pose).
hook.Add("CalcMainActivity", "LivingCityEndingStand", function(ply)
    if not S or S.phase ~= "apocalypse" or not IsValid(ply) then return end
    if not (ply:GetNW2Bool("lc_dancing", false) or IsValid(ply:GetNW2Entity("lc_riding", NULL)) or ply:GetNW2Bool("lc_seated", false)) then return end
    if ply:GetNW2Bool("lc_end_spectating", false) then return end
    local seq = ply.LookupSequence and ply:LookupSequence("idle_all_01") or -1
    if not seq or seq < 0 then seq = ply.LookupSequence and ply:LookupSequence("idle_all_02") or -1 end
    return ACT_MP_STAND_IDLE, seq or -1
end)
