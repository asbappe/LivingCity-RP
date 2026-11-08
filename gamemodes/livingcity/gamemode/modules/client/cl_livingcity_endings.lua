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

-- The Endings menu (cl_livingcity_endingtune.lua) tunes the dances live: a turn added to a
-- bone of one of the moves, and the server's own value for the settings everyone's dance
-- shares (the palms, the headbang, the kippah, the chair). Without it, as they are.
local function Tune(ent, move, name, a) local f = LC_CL.EndingTuneBone return f and f(ent, move, name, a) or a end
local function Tuned(cv) local f = LC_CL.EndingTunedCV return f and f(cv) or cv:GetString() end

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
    return math.Clamp((S and S.songVolume or 1) * loud * cvEndVol:GetFloat(), 0, 6)
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

-- (made once here, not every frame)
local V_0_0_62 = Vector(0, 0, 62)
hook.Add("CalcView", "LivingCityEndingGman", function(me, origin, angles, fov)
    if not S or S.phase ~= "gman" or not gmanAt or not gmanFrom then return end
    local want = ((gmanAt + V_0_0_62) - origin):Angle()
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

-- (made once here, not every frame)
local C_255_120_100 = Color(255, 120, 100)
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
            Text("PHOTOSENSITIVITY WARNING: this one has flashing lights and strobes.", "LCEndText", cx, cy + 200, C_255_120_100)
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
-- (made once here, not every frame)
local A_0_0_0 = Angle(0, 0, 0)
local C_255_255_255_200 = Color(255, 255, 255, 200)
local C_255_255_255_255 = Color(255, 255, 255, 255)
local C_25_60_85_170 = Color(25, 60, 85, 170)
local V_0_0_0 = Vector(0, 0, 0)
local V_0_0_1 = Vector(0, 0, 1)
local V_20000_20000_0 = Vector(20000, 20000, 0)
local V_m20000_m20000_m4000 = Vector(-20000, -20000, -4000)
hook.Add("PostDrawTranslucentRenderables", "LivingCityEndings", function(_, sky)
    if sky or not S or S.id ~= "water" or S.phase ~= "apocalypse" or GetGlobal2Bool("lc_flood_real", false) then return end
    local z = GetGlobal2Float("lc_flood_z", 0)
    if z == 0 then return end
    local eye = EyePos()
    render.SetColorMaterial()
    -- in a dream, only the dream zone fills (lc_flood_min / lc_flood_max: sv_livingcity_dreams.lua)
    local bmin, bmax = GetGlobal2Vector("lc_flood_min", V_0_0_0), GetGlobal2Vector("lc_flood_max", V_0_0_0)
    if bmax.x > bmin.x and bmax.y > bmin.y then
        render.DrawBox(Vector(0, 0, z), A_0_0_0, Vector(bmin.x, bmin.y, -4000), Vector(bmax.x, bmax.y, 0), C_25_60_85_170, true)
        if Material and render.DrawQuadEasy then
            if floodMatName ~= cvFloodMat:GetString() then floodMatName = cvFloodMat:GetString() floodMat = Material(floodMatName) end
            if floodMat and not (floodMat.IsError and floodMat:IsError()) then
                render.SetMaterial(floodMat)
                render.DrawQuadEasy(Vector((bmin.x + bmax.x) / 2, (bmin.y + bmax.y) / 2, z + 1), V_0_0_1, bmax.x - bmin.x, bmax.y - bmin.y, C_255_255_255_200, 0)
            end
        end
        return
    end
    render.DrawBox(Vector(eye.x, eye.y, z), A_0_0_0, V_m20000_m20000_m4000, V_20000_20000_0, C_25_60_85_170, true)
    if Material and render.DrawQuadEasy then
        if floodMatName ~= cvFloodMat:GetString() then floodMatName = cvFloodMat:GetString() floodMat = Material(floodMatName) end
        if floodMat and not (floodMat.IsError and floodMat:IsError()) then
            render.SetMaterial(floodMat)
            for gx = -2, 2 do
                for gy = -2, 2 do
                    render.DrawQuadEasy(Vector(math.floor(eye.x / 2000) * 2000 + gx * 2000, math.floor(eye.y / 2000) * 2000 + gy * 2000, z + 1), V_0_0_1, 2000, 2000, C_255_255_255_255, 0)
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
local FLAP, SWAY = 40, 12
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

-- (the Endings menu shows where the song is, for lining up the sections)
function LC_CL.EndingSongPos() return S and S.client and S.phase == "apocalypse" and SongPos(CurTime()) or nil end

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
    -- the kicks: one leg out on each beat, left then right, the other straight under them
    -- (a knee bent with the thigh left as it is only shortens the leg: the foot leaves the floor)
    R_Thigh = function(w) return Angle(0, -55 * math.max(0, w), 0) end, L_Thigh = function(w) return Angle(0, -55 * math.max(0, -w), 0) end,
}
local RAVE = {
    R_UpperArm = function(w) return Angle(20 * w, -110, 10) end, L_UpperArm = function(w) return Angle(20 * w, -110, -10) end,
    R_Forearm = function(w) return Angle(0, -20 + 30 * w, 0) end, L_Forearm = function(w) return Angle(0, -20 - 30 * w, 0) end,
    Head = function(w, b) return Angle(6 * b, -10 * w, 0) end, Pelvis = function(w) return Angle(0, 0, w * 14) end,
    Spine2 = function(w) return Angle(0, 0, -w * 8) end,
    -- bigger kicks for the rave, high and out to the side
    R_Thigh = function(w) local k = math.max(0, w) return Angle(12 * k, -75 * k, 0) end, L_Thigh = function(w) local k = math.max(0, -w) return Angle(-12 * k, -75 * k, 0) end,
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
-- (The arm bones, as the last playtest showed: yaw raises an arm forward, minus is up;
-- pitch takes it out to the side, minus for the right arm, plus for the left; roll twists
-- it. A forearm bends at the elbow on yaw. Both legs straight under them unless kicking:
-- a bent knee lifts the foot off the floor.)
local HORA = {
    R_UpperArm = Angle(-80, -15, 0), L_UpperArm = Angle(80, -15, 0),
    R_Forearm = Angle(0, -15, 0), L_Forearm = Angle(0, -15, 0),
}
-- Sat on the chair, lifted up (lc_shalom_pose chair <R_Thigh|L_Thigh|R_Calf|L_Calf> <p> <y> <r> to tune it live).
local SEATED = {
    R_Thigh = Angle(0, -85, 0), L_Thigh = Angle(0, -85, 0),
    R_Calf = Angle(0, 85, 0), L_Calf = Angle(0, 85, 0),
}
local function HoraPose(ent, b, beat)
    -- (a stand-in in the Endings menu says its own part of the dance)
    local sec = ent.lcTuneSection or (S and S.client and S.client.section) or "intro"
    if sec == "walk" then beat = beat / 2 end
    local k = math.floor(beat) % 6
    local s = math.sin(math.pi * (beat % 1)) -- (each step: out and back within its beat)
    local chair = ent.lcTuneChair or (ent.GetNW2Bool and ent:GetNW2Bool("lc_chair", false))
    local P = {}
    if sec == "in" or chair then
        P.R_UpperArm, P.L_UpperArm = Angle(-25, -160 + 15 * s, 0), Angle(25, -160 + 15 * s, 0)
        P.R_Forearm, P.L_Forearm = Angle(0, -10, 0), Angle(0, -10, 0)
    else
        P.R_UpperArm, P.L_UpperArm, P.R_Forearm, P.L_Forearm = HORA.R_UpperArm, HORA.L_UpperArm, HORA.R_Forearm, HORA.L_Forearm
    end
    if chair then
        P.R_Thigh, P.L_Thigh, P.R_Calf, P.L_Calf = SEATED.R_Thigh, SEATED.L_Thigh, SEATED.R_Calf, SEATED.L_Calf
        P.Head = Angle(0, 10 * math.sin(beat * math.pi), 0)
    elseif sec == "gather" then
        -- swaying arm in arm: a curve up the back, the feet planted
        local w = math.sin(beat * math.pi)
        P.Spine, P.Spine2, P.Head = Angle(0, 8 * w, 0), Angle(0, 5 * w, 0), Angle(0, -6 * w, 0)
    elseif sec ~= "intro" and sec ~= "end" then
        -- the grapevine: out to the side, cross behind, out, kick, step, kick (one foot always down)
        if k == 0 or k == 2 then P.L_Thigh = Angle(-14 * s, 0, 0)
        elseif k == 1 then P.R_Thigh = Angle(-8 * s, 14 * s, 0)
        elseif k == 3 then P.R_Thigh = Angle(0, -38 * s, 0) P.R_Calf = Angle(0, 20 * s, 0)
        elseif k == 5 then P.L_Thigh = Angle(0, -38 * s, 0) P.L_Calf = Angle(0, 20 * s, 0) end
        P.Head = Angle(6 * s, 0, 0)
    end
    local move = chair and "chair" or (sec == "in" and "hora_in" or "hora")
    for name, id in pairs(b) do ent:ManipulateBoneAngles(id, Tune(ent, move, name, P[name] or Angle(0, 0, 0))) end
end

local function Dance(ent, beat, now, key)
    if not ent.ManipulateBoneAngles then return end
    -- which dance: the ending's (none while previewing Bloom's), or the one a stand-in is given
    key = key or (not preview and S and S.client and S.client.dance) or nil
    local b = Bones(ent)
    local wave = math.sin(beat * math.pi)            -- left, right, a beat each
    local flap = math.sin(beat * math.pi * 2) * FLAP -- the wrists, every beat
    local bounce = math.abs(wave)
    -- the crowd at the rope: both arms up, fists pumping on the beat
    if key == "cheer" then
        if ent.GetNW2Float and ent:GetNW2Float("lc_hanged", 0) > 0 then return end -- (not the hanged: they've their own)
        local CHEER = {
            R_UpperArm = Angle(10, -120 + 25 * bounce, 0), L_UpperArm = Angle(-10, -120 + 25 * (1 - bounce), 0),
            R_Forearm = Angle(0, -20, 0), L_Forearm = Angle(0, -20, 0),
            Head = Angle(-8 * bounce, 0, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, Tune(ent, "cheer", name, CHEER[name] or Angle(0, 0, 0))) end
        danced[ent] = true
        return
    end
    -- numa numa: the webcam dance, arms rolling in front of the face, the head
    -- tipping side to side, a bounce
    if key == "numa" then
        local ph = beat * math.pi
        -- (on the arms yaw raises them forward and the elbow bends on yaw; pitch takes an arm
        -- out to the side, minus for the right, plus for the left)
        local NUMA = {
            R_UpperArm = Angle(8, -55 + 14 * math.sin(ph), 0),
            L_UpperArm = Angle(-8, -55 + 14 * math.sin(ph + math.pi), 0),
            R_Forearm = Angle(0, -65 + 18 * math.cos(ph), 0),
            L_Forearm = Angle(0, -65 + 18 * math.cos(ph + math.pi), 0),
            Head = Angle(4 * bounce, 14 * math.sin(ph / 2), 0),
            Spine2 = Angle(0, 6 * wave, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, Tune(ent, "numa", name, NUMA[name] or Angle(0, 0, 0))) end
        danced[ent] = true
        return
    end
    -- Fire: on the ground, bent over with the behind out (the flames), hips shaking, fists
    -- pumping; up in the air, flying on it, Superman style: the whole body tipped forward
    -- at the hips, arms out in front, legs trailing and fluttering. (On the head and spine
    -- pitch nods, plus forward; the pelvis turns the whole body, fine once off the ground.)
    if key == "fire" then
        local move = (ent.lcTuneFly or (ent.GetNW2Bool and ent:GetNW2Bool("lc_flying", false))) and "fly" or "fire"
        local P
        if move == "fly" then
            P = {
                Pelvis = Angle(80, 0, 0),
                Spine = Angle(-5, 0, 0), Head = Angle(-55, 0, 0),
                R_UpperArm = Angle(-12, -150, 0), L_UpperArm = Angle(12, -150, 0),
                R_Forearm = Angle(0, -10, 0), L_Forearm = Angle(0, -10, 0),
                R_Thigh = Angle(0, 10 * wave, 0), L_Thigh = Angle(0, -10 * wave, 0),
            }
        else
            P = {
                Spine = Angle(22 + 6 * bounce, 0, 0), Spine2 = Angle(12, 0, 0), Head = Angle(-28, 0, 0),
                Pelvis = Angle(0, 0, 18 * wave), -- (a twist at the hips: the shake)
                R_UpperArm = Angle(-10, -45 - 30 * wave, 0), L_UpperArm = Angle(10, -45 + 30 * wave, 0),
                R_Forearm = Angle(0, -75, 0), L_Forearm = Angle(0, -75, 0),
            }
        end
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, Tune(ent, move, name, P[name] or Angle(0, 0, 0))) end
        danced[ent] = true
        return
    end
    if key == "hora" then
        HoraPose(ent, b, beat)
        danced[ent] = true
        return
    end
    -- party hard: two frames, a pose and its mirror image, flipping every half-beat
    if key == "hard" then
        local hold = S.client.section == "break" or S.client.section == "fade"
        local flip = hold and 1 or ((math.floor(beat * 2) % 2 == 0) and 1 or -1)
        local HARD = {
            Pelvis = Angle(0, 0, 40 * flip), -- (a twist at the hips: tipping them lifted the feet off the floor)
            Spine2 = Angle(0, 12 * flip, 0),
            Head = Angle(0, -14 * flip, 0),
            R_UpperArm = flip > 0 and Angle(20, -120, 0) or Angle(0, -10, 0),
            L_UpperArm = flip > 0 and Angle(0, -10, 0) or Angle(-20, -120, 0),
            R_Forearm = flip > 0 and Angle(0, -40, 0) or Angle(0, 0, 0),
            L_Forearm = flip > 0 and Angle(0, 0, 0) or Angle(0, -40, 0),
            R_Thigh = Angle(0, flip > 0 and -20 or 0, 0), L_Thigh = Angle(0, flip > 0 and 0 or -20, 0),
        }
        for name, id in pairs(b) do ent:ManipulateBoneAngles(id, Tune(ent, "hard", name, HARD[name] or Angle(0, 0, 0))) end
        danced[ent] = true
        return
    end
    local style = STYLES[key or ""]
    if style then
        for name, id in pairs(b) do
            local f = style[name]
            ent:ManipulateBoneAngles(id, Tune(ent, key, name, f and f(wave, bounce) or Angle(0, 0, 0)))
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
        -- (the sway: a curve up the back over legs that stay put and straight; turning the
        -- hips, or bending a knee, lifts the feet off the floor)
        -- (and on people, the hands turned right round: palms the right way; tuned in the
        -- Endings menu, 20 October. The Combine's units' bones sit differently: not on them)
        if name == "R_Hand" then a.y = a.y + flap if lift == 1 then a.r = a.r - 180 end
        elseif name == "L_Hand" then a.y = a.y - flap if lift == 1 then a.r = a.r + 180 end
        elseif name == "R_Forearm" then a.r = a.r + (tonumber(Tuned(cvPalm)) or 90)
        elseif name == "L_Forearm" then a.r = a.r - (tonumber(Tuned(cvPalm)) or 90)
        elseif name == "Spine" then a.y = a.y + wave * SWAY
        elseif name == "Spine2" then a.y = a.y + wave * SWAY * 0.5
        elseif name == "Head" then a.y = a.y - wave * SWAY * 0.8
        end
        -- spinning up into the sky
        local t0 = ent.GetNW2Float and ent:GetNW2Float("lc_spin_t0", 0) or 0
        if name == "Pelvis" and t0 > 0 then a.y = a.y + ((now - t0) ^ 2) * 720 % 360 end
        ent:ManipulateBoneAngles(id, Tune(ent, "ears", name, a))
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

-- (made once here, not every frame)
local V_0_0_60 = Vector(0, 0, 60)
local V_0_0_70 = Vector(0, 0, 70)
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
                dl.pos = near[i].e:GetPos() + V_0_0_70
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
            dl.pos = bus:GetPos() + V_0_0_60
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

-- (made once here, not every frame)
local V_0_0_140 = Vector(0, 0, 140)
local V_0_0_40 = Vector(0, 0, 40)
local V_0_0_45 = Vector(0, 0, 45)
local V_0_0_50 = Vector(0, 0, 50)
hook.Add("CalcView", "LivingCityBloom", function(me, origin, angles, fov)
    -- on the party bus: behind it, looking wherever you look
    local on = Party()
    local bus = on and on.bus and Entity(on.bus)
    if IsValid(me) and me:GetNW2Bool("lc_seated", false) and IsValid(bus) then
        local from = bus:GetPos() + V_0_0_140
        return { origin = SafeCam(from, from - angles:Forward() * 520), angles = angles, fov = fov, drawviewer = true }
    end
    -- Fire, flying: behind you and a little above, looking wherever you look
    if IsValid(me) and on and on.fire and me:GetNW2Bool("lc_flying", false) and not me:GetNW2Bool("lc_end_spectating", false) then
        local from = me:GetPos() + V_0_0_50
        return { origin = SafeCam(from, from - angles:Forward() * 240 + V_0_0_40), angles = angles, fov = fov, drawviewer = true }
    end
    if not Dancing(me) then return end
    local a = math.rad(CurTime() * 18)
    local centre = me:GetPos() + V_0_0_45
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

-- (made once here, not every frame)
local C_0_0_0_220 = Color(0, 0, 0, 220)
local C_200_225_255 = Color(200, 225, 255)
hook.Add("HUDPaint", "LivingCityFloodSky", function()
    if not Flood() then return end
    local now = CurTime()
    if now < flashUntil and not Calm() then
        surface.SetDrawColor(225, 235, 255, 200 * (flashUntil - now) / 0.3)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    local me = LocalPlayer()
    if IsValid(me) and not me:GetNW2Bool("lc_end_taken", false) and me:EyePos().z < GetGlobal2Float("lc_flood_z", 0) then
        draw.SimpleTextOutlined("Under the water: hold Jump to swim up", "LCEndText", ScrW() / 2, ScrH() * 0.8, C_200_225_255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_220)
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
    local str = Tuned(cvBang) or ""
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

-- Father Grigori's moves: the headbang in the heavy parts ("bang"), dancing in the rest ("groove")
local function RockPose(ply, beat, sec)
    -- the nod: down on the beat, up between, smoothly (no snapping back: that looked like a twitch)
    local down = (0.5 + 0.5 * math.cos(beat * math.pi * 2)) ^ 1.6
    local pump = math.abs(math.sin(beat * math.pi))
    local bang = BangAngle()
    local heavy = sec == "heavy" or sec == "climax"
    local move = heavy and "bang" or "groove"
    local function Set(name, a) local id = Bone(ply, name) if id then ply:ManipulateBoneAngles(id, Tune(ply, move, name, a)) end end
    local wave = math.sin(beat * math.pi) -- (side to side, a beat each way)
    if heavy then
        -- the heavy parts: headbanging, hard, the whole upper body slamming down on
        -- the beat (head, neck and back each taking some of it), and the fist pumping
        Set("Head", bang * down)
        Set("Neck1", bang * (down * 0.8))
        Set("Spine2", bang * (down * 0.7))
        Set("Spine1", bang * (down * 0.5))
        Set("Spine", Angle(0, 0, 0))
        Set("Pelvis", Angle(0, 0, 0))
        -- (the free arm: up over his head, the fist pumping on the beat; on the arms yaw
        -- raises them forward and up, pitch takes them out to the side, the elbow bends on yaw)
        Set("L_UpperArm", Angle(15, -150 - 20 * pump, 0))
        Set("L_Forearm", Angle(0, -25 * pump, 0))
    else
        -- the rest: dancing, the hips going, the free arm waving over his head
        -- (yaw is side to side on these bones, roll front to back)
        Set("Head", Angle(8 * pump, 10 * wave, 0))
        Set("Neck1", Angle(0, 0, 0))
        Set("Spine1", Angle(0, 0, 0))
        Set("Spine", Angle(0, 8 * wave, 0))
        Set("Spine2", Angle(0, 6 * wave, 0))
        Set("Pelvis", Angle(0, 0, 0))
        Set("L_UpperArm", Angle(25 + 20 * wave, -150, 0))
        Set("L_Forearm", Angle(0, -20, 0))
    end
    -- the mic up at his mouth, all the way through: the upper arm forward and down, a
    -- little out, and the elbow bent right up
    Set("R_UpperArm", Angle(-10, -40, 0))
    Set("R_Forearm", Angle(0, -130, 0))
end

hook.Add("Think", "LivingCityHeadbang", function()
    local now = CurTime()
    local beat = RockBeat(now)
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
            RockPose(ply, beat, S.client and S.client.section or "intro")
        elseif rocked[ply] then
            rocked[ply] = nil
            if IsValid(ply) then
                local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
                if IsValid(w) and w.SetNoDraw then w:SetNoDraw(false) end -- (his gun back)
                if IsValid(ply.lcMic) then ply.lcMic:Remove() ply.lcMic = nil end
            end
            if IsValid(ply) and ply.ManipulateBoneAngles then
                for _, name in ipairs({ "Head", "Neck1", "Spine", "Spine1", "Spine2", "Pelvis", "R_UpperArm", "R_Forearm", "L_UpperArm", "L_Forearm", "R_Calf", "L_Calf" }) do
                    local id = Bone(ply, name)
                    if id then ply:ManipulateBoneAngles(id, A_0_0_0) end
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
-- (the monks are looked up twice a second, not every frame; each is still checked every frame)
local monks, monksAt = {}, -1
hook.Add("PostDrawOpaqueRenderables", "LivingCityHeadbangNPC", function(_, sky)
    if sky or not S or S.id ~= "water" or S.phase ~= "apocalypse" then return end
    local now = CurTime()
    if now >= monksAt or now < monksAt - 0.5 then
        monks, monksAt = ents.FindByClass and ents.FindByClass("npc_monk") or {}, now + 0.5
    end
    for _, n in ipairs(monks) do
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
-- (made once here, not every frame)
local V_0_0_2400 = Vector(0, 0, 2400)
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
    local at = Vector(c.sky.x, c.sky.y, c.sky.z) - V_0_0_2400
    catsModel:SetPos(at)
    catsModel:SetAngles(Angle(0, (eye - at):Angle().y, 0))
    if render.SetColorModulation then render.SetColorModulation(1, 0.25, 0.2) end
    catsModel:SetupBones()
    catsModel:DrawModel()
    if render.SetColorModulation then render.SetColorModulation(1, 1, 1) end
end)

local lastBeep = -1
-- (made once here, not every frame)
local V_0_0_30 = Vector(0, 0, 30)
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
                    dl.pos = b:GetPos() + V_0_0_30
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
-- (made once here, not every frame)
local V_0_0_100 = Vector(0, 0, 100)
local V_0_0_120 = Vector(0, 0, 120)
hook.Add("CalcView", "LivingCityBase", function(me, origin, angles, fov)
    if not (S and S.phase == "apocalypse") or not IsValid(me) or me:GetNW2Bool("lc_end_spectating", false) then return end
    local z = me:GetNW2Entity("lc_riding")
    if not IsValid(z) then return end
    local from = z:GetPos() + V_0_0_120
    return { origin = SafeCam(from, from + V_0_0_100 - angles:Forward() * 700), angles = angles, fov = fov, drawviewer = true }
end)

-- (made once here, not every frame)
local C_235_235_235 = Color(235, 235, 235)
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
        draw.SimpleText(line, "LCArcade", w / 2, h * 0.78 + 30, C_235_235_235, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
            popups[#popups + 1] = { pos = pos + V_0_0_60, t0 = now }
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
                table.insert(tr, 1, z:GetPos() - z:GetForward() * 260 + V_0_0_40)
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
            if s > 4 then render.DrawBox(p, A_0_0_0, Vector(-s, -s, -s), Vector(s, s, s), Color(col.r, col.g, col.b, 200)) end
        end
    end
end)
-- (made once here, not every frame)
local C_255_200_60 = Color(255, 200, 60)
local C_255_255_255 = Color(255, 255, 255)
local C_255_60_40 = Color(255, 60, 40)
hook.Add("HUDPaint", "LivingCityBaseArcade", function()
    local c = Base()
    if not c then return end
    local now = CurTime()
    local w = ScrW()
    draw.SimpleText(string.format("1UP  %07d", baseScore), "LCArcade", 40, 30, C_255_60_40, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("HI-SCORE  %07d", math.max(baseScore, 1000000)), "LCArcade", w / 2, 30, C_255_255_255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if math.floor(now * 2) % 2 == 0 then draw.SimpleText("INSERT COIN", "LCArcade", w - 40, 30, C_255_200_60, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
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

-- (made once here, not every frame)
local C_0_0_0_230 = Color(0, 0, 0, 230)
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
            Color(sp.c[1] or sp.c.r or 255, sp.c[2] or sp.c.g or 255, sp.c[3] or sp.c.b or 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, C_0_0_0_230)
    end
end)

-- and over every dancer's head
-- (made once here, not every frame)
local V_0_0_92 = Vector(0, 0, 92)
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
            local pos = e:GetPos() + V_0_0_92
            local ang = Angle(0, (me:EyePos() - pos):Angle().y + 90, 90)
            cam.Start3D2D(pos, ang, 0.25)
            draw.SimpleTextOutlined("PARTY HARD", "LCPartyHardSmall", 0, 0, Color(c0[1] or 255, c0[2] or 255, c0[3] or 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, C_0_0_0_230)
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

-- (made once here, not every frame)
local C_255_235_120 = Color(255, 235, 120)
local C_255_80_80 = Color(255, 80, 80)
local V_0_0_3 = Vector(0, 0, 3)
local V_0_0_64 = Vector(0, 0, 64)
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
        draw.SimpleTextOutlined(cap, "LCNuma", w / 2, h * 0.2, C_255_235_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, C_0_0_0_230)
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
        local face = att and att.Pos or (me:GetPos() + V_0_0_64)
        local fwd = (att and att.Ang or me:GetAngles()):Forward()
        local camPos = face + fwd * 28 + V_0_0_3
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
        draw.SimpleText((math.floor(now * 2) % 2 == 0 and "o " or "  ") .. "REC   webcam", "DermaDefaultBold", x + 6, y + bh + 12, C_255_80_80, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
            if not calm and frac < 0.12 then render.DrawSprite(base, 140, 140, C_255_255_255_255) end
        end
    end
end)
-- (made once here, not every frame)
local V_0_0_10 = Vector(0, 0, 10)
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
        d.pos = bus:GetPos() + V_0_0_10
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
            render.DrawBeam(Vector(h.a.x, h.a.y, h.a.z), neck, 2, 0, neck:Distance(Vector(h.a.x, h.a.y, h.a.z)) / 32, C_255_255_255)
        end
    end
end)

-- hands at the rope and legs kicking ("hanged"); then limp, head over ("limp")
local function HangPose(e, limp, k)
    local move = limp and "limp" or "hanged"
    local function Set(name, a) local id = e:LookupBone("ValveBiped.Bip01_" .. name) if id then e:ManipulateBoneAngles(id, Tune(e, move, name, a)) end end
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

-- hands at the rope and legs kicking; then limp, head over
hook.Add("Think", "LivingCityStandup", function()
    local c = Standup()
    if not c then
        for e in pairs(hungPosed) do
            if IsValid(e) and e.ManipulateBoneAngles then
                for _, name in ipairs({ "R_UpperArm", "L_UpperArm", "R_Forearm", "L_Forearm", "Head", "R_Calf", "L_Calf", "R_Thigh", "L_Thigh" }) do
                    local id = e:LookupBone("ValveBiped.Bip01_" .. name)
                    if id then e:ManipulateBoneAngles(id, A_0_0_0) end
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
            HangPose(e, limp, k)
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
    return { origin = me:GetPos() + V_0_0_50 - angles:Forward() * 160, angles = angles, fov = fov, drawviewer = true }
end)

-- the white cone hats: pulled down over every hanged head, drawn on the head bone itself
local coneModel, coneWhite
hook.Add("PostDrawOpaqueRenderables", "LivingCityStandupCones", function(_, sky)
    local c = Standup()
    if sky or not c or not ClientsideModel then return end
    if not IsValid(coneModel) then
        coneModel = ClientsideModel("models/props_junk/trafficcone001a.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(coneModel) then return end
        coneModel:SetNoDraw(true)
        if coneModel.SetModelScale then coneModel:SetModelScale(0.85, 0) end
    end
    coneWhite = coneWhite or (render.MaterialOverride and Material and Material("models/debug/debugwhite")) -- (looked up once, not every frame)
    local white = coneWhite
    for _, h in ipairs(c.hangs or {}) do
        local e = Entity(h.e)
        if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then
            local id = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Head1")
            local m = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
            local pos, up = e:GetPos() + V_0_0_62, V_0_0_1
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
-- (made once here, not every frame)
local V_0p14_1p08_1p08 = Vector(0.14, 1.08, 1.08)
local V_0p4_1_1 = Vector(0.4, 1, 1)
hook.Add("PostDrawOpaqueRenderables", "LivingCityShalomKippah", function(_, sky)
    local c = Shalom()
    if sky or not c or not render or not render.DrawSphere or not Matrix or not cam or not cam.PushModelMatrix then return end
    local t = SongPos(CurTime())
    local from = c.gatherAt or 7.4
    if t < from then return end
    local fx, rx, ux = string.match(Tuned(cvKippah) or "", "(%S+)%s+(%S+)%s+(%S+)")
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
                    mat:Scale(part == 1 and V_0p4_1_1 or V_0p14_1p08_1p08)
                    cam.PushModelMatrix(mat)
                    render.DrawSphere(V_0_0_0, 3.6, 14, 8, ((part == 1) == blue) and BLUE or SNOW)
                    cam.PopModelMatrix()
                end
            end
        end
    end
end)

-- The hanukkiah and the flagpoles are built from one small cube model, stretched and drawn
-- many times, in a shiny material the map's light falls on (flat colour glowed like neon).
local block, shiny, chalk
local BLOCK = "models/hunter/blocks/cube025x025x025.mdl"
local BLOCK_SIZE = 11.86
local function Block()
    if IsValid(block) then return block end
    if not ClientsideModel then return nil end
    block = ClientsideModel(BLOCK, RENDERGROUP_OPAQUE)
    if IsValid(block) then block:SetNoDraw(true) else block = nil end
    return block
end
-- A box from its centre, turned `ang`, `size` long, wide and tall, in a colour (shiny gold, metal, wax).
local function Box(centre, ang, size, col, mat)
    local b = Block()
    if not b or not Matrix then
        render.SetColorMaterial()
        render.DrawBox(centre, ang, size * -0.5, size * 0.5, col)
        return
    end
    local m = Matrix()
    m:Scale(Vector(size.x / BLOCK_SIZE, size.y / BLOCK_SIZE, size.z / BLOCK_SIZE))
    b:EnableMatrix("RenderMultiply", m)
    b:SetPos(centre)
    b:SetAngles(ang)
    b:SetupBones()
    if render.MaterialOverride and mat then render.MaterialOverride(mat) end
    if render.SetColorModulation then render.SetColorModulation(col.r / 255, col.g / 255, col.b / 255) end
    b:DrawModel()
    if render.SetColorModulation then render.SetColorModulation(1, 1, 1) end
    if render.MaterialOverride and mat then render.MaterialOverride() end
end
-- The chair whoever's lifted up sits on: drawn right under their hips, wherever they are.
-- (lc_shalom_chair: how far under the hips the chair's foot is, and a turn if it faces the wrong way)
local cvChair = CreateClientConVar("lc_shalom_chair", "21 0", true, false, "Shalom: the chair under whoever's lifted up: how far below their hips its foot is, and a turn (degrees) if it faces the wrong way")
local chairModel
-- (made once here, not every frame)
local V_0_0_38 = Vector(0, 0, 38)
hook.Add("PostDrawOpaqueRenderables", "LivingCityShalomChair", function(_, sky)
    if sky or not (S and S.id == "shalom" and S.phase == "apocalypse") or not ClientsideModel then return end
    for _, e in ipairs(dancers) do
        if IsValid(e) and e:GetNW2Bool("lc_chair", false) and not (e.GetNoDraw and e:GetNoDraw()) then
            if not IsValid(chairModel) then
                chairModel = ClientsideModel("models/props_c17/chair02a.mdl", RENDERGROUP_OPAQUE)
                if not IsValid(chairModel) then return end
                chairModel:SetNoDraw(true)
            end
            local id = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Pelvis")
            local m = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
            local hips = m and m:GetTranslation() or (e:GetPos() + V_0_0_38)
            local drop, turn = string.match(Tuned(cvChair) or "", "(%-?[%d%.]+)%s+(%-?[%d%.]+)")
            chairModel:SetPos(hips - Vector(0, 0, tonumber(drop) or 21))
            chairModel:SetAngles(Angle(0, e:GetAngles().y + (tonumber(turn) or 0), 0))
            chairModel:SetupBones()
            chairModel:DrawModel()
        end
    end
end)

-- A box along a line, from a to b (the hanukkiah's arms and stem).
local function Bar(a, b, th, col, mat)
    local d = b - a
    local len = d:Length()
    if len < 0.01 then return end
    Box(a + d * 0.5, d:Angle(), Vector(len, th * 2, th * 2), col, mat)
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

-- (made once here, not every frame)
local C_170_170_178 = Color(170, 170, 178)
local C_235_240_255 = Color(235, 240, 255)
local V_0_0_m1 = Vector(0, 0, -1)
hook.Add("PostDrawOpaqueRenderables", "LivingCityShalom", function(_, sky)
    local c = Shalom()
    flames = {}
    if sky or not c or not render or not render.DrawBox then return end
    local now = CurTime()
    local t = SongPos(now)
    local eye = EyePos()
    shiny = shiny or (Material and Material("models/shiny"))
    chalk = chalk or (Material and Material("models/debug/debugwhite"))
    -- the hanukkiah: a giant one in the middle of the rings, turned to face you
    local m = c.menorah
    if m and m.pos then
        local base = Vector(m.pos.x, m.pos.y, m.pos.z)
        local w, h = m.w or 180, m.h or 170
        local toEye = Vector(eye.x - base.x, eye.y - base.y, 0)
        if toEye:LengthSqr() < 1 then toEye = Vector(1, 0, 0) end
        toEye:Normalize()
        local right, up = Vector(-toEye.y, toEye.x, 0), V_0_0_1
        local flat = Angle(0, toEye:Angle().y, 0)
        local function P(x, z) return base + right * x + up * z end
        local th = w * 0.02 + 1.5
        local top, sp = h * 0.74, w / 9
        Box(base + up * (h * 0.025), flat, Vector(w * 0.24, w * 0.4, h * 0.05), GOLD2, shiny)
        Bar(P(0, h * 0.05), P(0, h * 0.86), th * 1.4, GOLD, shiny)
        for i = 1, 4 do
            for _, sgn in ipairs({ 1, -1 }) do
                Bar(P(0, top - h * 0.115 * i), P(sgn * i * sp, top), th, GOLD, shiny)
                Box(P(sgn * i * sp, top + th * 0.8), flat, Vector(th * 3.6, th * 3.6, th * 1.6), GOLD2, shiny)
            end
        end
        Box(P(0, h * 0.86 + th * 0.8), flat, Vector(th * 4, th * 4, th * 1.6), GOLD2, shiny)
        -- the candles: the first on the right, each next one to its left; the shamash in the middle, higher, lit from the start
        local lit = 0
        for _, ct in ipairs(c.candles or {}) do if t >= ct then lit = lit + 1 end end
        local ch = h * 0.08
        for k = 0, 8 do
            local x = k == 0 and 0 or (k <= 4 and (5 - k) * sp or -(k - 4) * sp)
            local cb = k == 0 and P(0, h * 0.86 + th * 1.6) or P(x, top + th * 1.6)
            Box(cb + up * (ch * 0.5), flat, Vector(th * 2, th * 2, ch), C_235_240_255, chalk)
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
            Box(foot + Vector(0, 0, PH * 0.5), A_0_0_0, Vector(3, 3, PH), C_170_170_178, shiny)
            render.SetColorMaterial()
            local hoist = math.Clamp((t - 0.4 - (i - 1) * 0.8) / 1.0, 0, 1)
            hoist = hoist * hoist * (3 - 2 * hoist)
            local topZ = foot.z + 50 + (PH - 52) * hoist
            Flag(Vector(foot.x, foot.y, topZ) + WIND * 1.5, WIND, V_0_0_m1, Vector(WIND.y, -WIND.x, 0), 66, 48, now + i, 5, 10)
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
        render.SetColorMaterial()
        Flag(sk - across * (W / 2) + Vector(0, 0, H / 2), across, V_0_0_m1, toEye, W * u, H, now, 22, 16)
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
                dl.pos = flames[1] + V_0_0_10
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
-- (made once here, not every frame)
local C_255_140_40_120 = Color(255, 140, 40, 120)
local C_255_190_90 = Color(255, 190, 90)
hook.Add("PostDrawTranslucentRenderables", "LivingCityShalom", function(_, sky)
    local c = Shalom()
    if sky or not c or not render or not render.DrawSprite then return end
    glow = glow or (Material and Material("sprites/light_glow02_add"))
    if glow then render.SetMaterial(glow) end
    local now = CurTime()
    -- the candle flames, flickering
    for i, f in ipairs(flames) do
        local fl = math.sin(now * 17 + i * 2.1) * 1.5
        render.DrawSprite(f + Vector(0, 0, fl * 0.5), 7, 13 + fl, C_255_190_90)
        render.DrawSprite(f, 26, 26, C_255_140_40_120)
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
        local right, up = Vector(-toEye.y, toEye.x, 0), V_0_0_1
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
-- (the arms in the ring: lc_shalom_pose R_UpperArm -80 -15 0; the legs sat on the chair:
-- lc_shalom_pose chair R_Thigh 0 -85 0. Only on your screen; lc_shalom_pose_print to pass the numbers on.)
concommand.Add("lc_shalom_pose", function(_, _, args)
    local tbl = HORA
    if args[1] == "chair" then tbl = SEATED table.remove(args, 1) end
    local name = args[1]
    if not name or not tbl[name] then
        print("[Living City] lc_shalom_pose <R_UpperArm|L_UpperArm|R_Forearm|L_Forearm> <pitch> <yaw> <roll>")
        print("[Living City] lc_shalom_pose chair <R_Thigh|L_Thigh|R_Calf|L_Calf> <pitch> <yaw> <roll>")
        return
    end
    tbl[name] = Angle(tonumber(args[2]) or 0, tonumber(args[3]) or 0, tonumber(args[4]) or 0)
end)
concommand.Add("lc_shalom_pose_print", function()
    for _, n in ipairs({ "R_UpperArm", "L_UpperArm", "R_Forearm", "L_Forearm" }) do print(string.format("%s = Angle(%g, %g, %g)", n, HORA[n].p, HORA[n].y, HORA[n].r)) end
    for _, n in ipairs({ "R_Thigh", "L_Thigh", "R_Calf", "L_Calf" }) do print(string.format("chair %s = Angle(%g, %g, %g)", n, SEATED[n].p, SEATED[n].y, SEATED[n].r)) end
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

-- The Endings menu's stand-in (cl_livingcity_endingtune.lua): one of the moves, on a model
-- in front of you, only on your screen.
function LC_CL.EndingPoseMove(ent, move, beat)
    if not IsValid(ent) or not ent.ManipulateBoneAngles then return end
    if move == "bang" or move == "groove" then RockPose(ent, beat, move == "bang" and "heavy" or "calm") return end
    if move == "hanged" or move == "limp" then HangPose(ent, move == "limp", CurTime() * 9) return end
    local key = move
    if move == "hora" or move == "hora_in" or move == "chair" then
        key = "hora"
        ent.lcTuneSection = move == "hora_in" and "in" or "dance"
        ent.lcTuneChair = move == "chair"
    end
    if move == "fire" or move == "fly" then
        key = "fire"
        ent.lcTuneFly = move == "fly"
    end
    Dance(ent, beat, CurTime(), key)
    danced[ent] = nil -- (the city's own dancers are let go when nobody dances; this one is the menu's)
end

------------------------------------------------------------------------
-- Fire: the flames out of everyone's behind (sv_livingcity_endings.lua)
------------------------------------------------------------------------
-- Each one burns as hard as the server says (lc_fire: 0 sputtering, 1 lit,
-- up to 3 for the last rocket up): flames and smoke out of the back of the
-- hips, pointing back and down on the ground and straight out behind in the
-- air, a glow over the flames, firelight round the nearest, and the roar of
-- your own. Before they light, a puff of smoke and a spark now and then, on
-- the beat. Only the nearest few dozen get the particles; everyone gets the glow.
do
local emitter
local lastPos = {}   -- [ent] = where they were (which way they're going: the exhaust goes the other way)
local burners, burnersAt = {}, 0
local nextEmit = 0
local lastPuffBeat = -1
local roar, roarFly
local glowMat
local function FireOn() local c = S and S.phase == "apocalypse" and S.client return c and c.fire and c or nil end
LC_CL.EndingFireOn = FireOn

-- Where someone's behind is, and which way the flames go
local function Behind(e)
    local pos = e:GetPos() + Vector(0, 0, 38)
    local bone = e.LookupBone and e:LookupBone("ValveBiped.Bip01_Pelvis")
    if bone and e.GetBonePosition then
        local bp = e:GetBonePosition(bone)
        if bp then pos = bp end
    end
    local yaw = e:GetNW2Float("lc_fly_yaw", 0)
    local flying = e:GetNW2Bool("lc_flying", false)
    local fwd = flying and Angle(0, yaw, 0):Forward() or e:GetForward()
    local dir
    if flying then
        local last = lastPos[e]
        local now = e:GetPos()
        if last and now:DistToSqr(last) > 4 then dir = (last - now):GetNormalized() end
        lastPos[e] = now
        dir = dir or -fwd
    else
        fwd.z = 0
        fwd:Normalize()
        dir = (-fwd * 0.75 + Vector(0, 0, -0.55)):GetNormalized()
    end
    return pos - fwd * 6, dir
end

local function Flame(pos, dir, heat)
    local p = emitter:Add("particles/flamelet" .. math.random(1, 5), pos)
    if not p then return end
    p:SetVelocity(dir * (120 + 140 * heat) + VectorRand() * 20)
    p:SetDieTime(math.Rand(0.2, 0.32 + 0.08 * heat))
    p:SetStartAlpha(255)
    p:SetEndAlpha(0)
    p:SetStartSize(4 + 5 * heat)
    p:SetEndSize(1)
    p:SetRoll(math.Rand(0, 360))
    p:SetRollDelta(math.Rand(-3, 3))
    p:SetColor(255, math.random(170, 230), math.random(90, 140))
end

local function Smoke(pos, dir, size)
    local p = emitter:Add("particle/particle_smokegrenade", pos)
    if not p then return end
    p:SetVelocity(dir * 60 + Vector(0, 0, 25) + VectorRand() * 10)
    p:SetDieTime(math.Rand(1, 1.8))
    p:SetStartAlpha(90)
    p:SetEndAlpha(0)
    p:SetStartSize(size)
    p:SetEndSize(size * 3)
    p:SetRoll(math.Rand(0, 360))
    p:SetColor(70, 65, 60)
end

hook.Add("Think", "LivingCityFire", function()
    local on = FireOn()
    local me = LocalPlayer()
    if not on or not IsValid(me) then
        if roar then roar:Stop() roar = nil end
        if roarFly then roarFly:Stop() roarFly = nil end
        if emitter then emitter:Finish() emitter = nil end
        burners, lastPos = {}, {}
        return
    end
    local now = CurTime()
    if now >= burnersAt then
        burnersAt = now + 1
        burners = {}
        for _, e in ipairs(ents.GetAll and ents.GetAll() or player.GetAll()) do
            if IsValid(e) and e.GetNW2Bool and (e:GetNW2Bool("lc_dancing", false) or e:GetNW2Float("lc_fire", 0) > 0) then burners[#burners + 1] = e end
        end
    end
    -- your own roar, louder in the air
    local heat = me:GetNW2Float("lc_fire", 0)
    if heat > 0 and CreateSound then
        roar = roar or CreateSound(me, "ambient/fire/fire_med_loop1.wav")
        if roar and not roar:IsPlaying() then roar:PlayEx(0.5, 100) end
        if me:GetNW2Bool("lc_flying", false) then
            roarFly = roarFly or CreateSound(me, "thrusters/rocket04.wav")
            if roarFly and not roarFly:IsPlaying() then roarFly:PlayEx(0.45, 100) end
        elseif roarFly then roarFly:Stop() roarFly = nil end
    elseif roar then roar:Stop() roar = nil end
    if now < nextEmit then return end
    nextEmit = now + 1 / 30
    emitter = emitter or (ParticleEmitter and ParticleEmitter(me:GetPos(), false))
    if not emitter then return end
    -- the nearest few dozen
    local near = {}
    local here = me:GetPos()
    for _, e in ipairs(burners) do
        if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then
            local d = e:GetPos():DistToSqr(here)
            if d < 3000 * 3000 then near[#near + 1] = { e = e, d = d } end
        end
    end
    table.sort(near, function(x, y) return x.d < y.d end)
    local beat = math.floor((SongPos(now) - (on.offset or 0)) * (on.bpm or 100) / 60)
    local puff = beat ~= lastPuffBeat
    lastPuffBeat = beat
    for i = 1, math.min(#near, 32) do
        local e = near[i].e
        local h = e:GetNW2Float("lc_fire", 0)
        local pos, dir = Behind(e)
        if h > 0 then
            for _ = 1, math.ceil(1 + h) do Flame(pos, dir, h) end
            if math.random() < 0.12 + 0.05 * h then Smoke(pos + dir * 30, dir, 8 + 4 * h) end
        elseif puff and math.random() < 0.35 then
            -- sputtering: a puff, and now and then a little lick of flame
            Smoke(pos, dir, 6)
            if math.random() < 0.4 then for _ = 1, 3 do Flame(pos, dir, 0.4) end end
        end
        -- firelight on the nearest
        if h > 0 and i <= 8 and DynamicLight then
            local dl = DynamicLight(52400 + i)
            if dl then
                dl.pos = pos + dir * 20
                dl.r, dl.g, dl.b = 255, 140, 40
                dl.brightness = 1.5 + 0.6 * h + math.Rand(-0.4, 0.4)
                dl.size = 180 + 60 * h
                dl.decay = 0
                dl.dietime = now + 0.1
            end
        end
    end
end)

-- the glow over the flames (everyone burning, however far)
-- (made once here, not every frame)
local C_255_150_50_220 = Color(255, 150, 50, 220)
hook.Add("PostDrawTranslucentRenderables", "LivingCityFire", function(_, sky)
    if sky or not FireOn() or not render.DrawSprite then return end
    glowMat = glowMat or (Material and Material("sprites/light_glow02_add"))
    if not glowMat then return end
    render.SetMaterial(glowMat)
    for _, e in ipairs(burners) do
        if IsValid(e) and not (e.GetNoDraw and e:GetNoDraw()) then
            local h = e:GetNW2Float("lc_fire", 0)
            if h > 0 then
                local pos, dir = Behind(e)
                local s = (26 + 14 * h) * math.Rand(0.85, 1.15)
                render.DrawSprite(pos + dir * 10, s, s, C_255_150_50_220)
            end
        end
    end
end)

-- Flying: everyone's body faces the way they fly, whichever way they look
local function FlyFacing(ply)
    if FireOn() and ply:GetNW2Bool("lc_flying", false) and ply.SetRenderAngles then
        ply:SetRenderAngles(Angle(0, ply:GetNW2Float("lc_fly_yaw", 0), 0))
    end
end
hook.Add("UpdateAnimation", "LivingCityFire", function(ply) FlyFacing(ply) end)
hook.Add("PrePlayerDraw", "LivingCityFire", function(ply) FlyFacing(ply) end)
end
