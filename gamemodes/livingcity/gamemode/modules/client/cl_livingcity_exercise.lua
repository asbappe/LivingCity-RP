--[[
    Living City: morning exercise, on your screen (sv_livingcity_exercise.lua)

      Where to report, and how long you have; then for the jog the next
      marker and the pace marker, for the drill the move to copy, your place
      in the rows and the skipping rope's beat, and for the parade your
      enthusiasm.
]]

if SERVER then return end

LC_CL = LC_CL or {}

if surface and surface.CreateFont then
    surface.CreateFont("LCExTitle", { font = "Trebuchet MS", size = 22, weight = 700 })
    surface.CreateFont("LCExText", { font = "Trebuchet MS", size = 17, weight = 600 })
    surface.CreateFont("LCExCue", { font = "Trebuchet MS", size = 46, weight = 800 })
end

local NAMES = { jog = "MORNING JOG", drill = "MORNING DRILL", parade = "MORNING PARADE" }
local GOAL = { jog = "the start of the jogging route", drill = "the exercise yard", parade = "the parade route" }
local MOVE_SAY = { crouch = "CROUCH", jump = "JUMP", spin = "TURN AROUND", step_left = "STEP LEFT", step_right = "STEP RIGHT",
    step_forward = "STEP FORWARD", step_back = "STEP BACK" }
local WHITE, RED, GREEN, AMBER, SHADOW = Color(235, 235, 235), Color(235, 80, 70), Color(110, 220, 140), Color(240, 190, 80), Color(0, 0, 0, 220)

local EX, cue, rope
local cum

net.Receive("lc_exercise", function()
    local kind = net.ReadString()
    if kind == "" then EX, cue, rope = nil, nil, nil return end
    local phase = net.ReadString()
    local musterEnds, ends = net.ReadFloat(), net.ReadFloat()
    local t = net.ReadTable() or {}
    EX = { kind = kind, phase = phase, musterEnds = musterEnds, ends = ends, center = t.center, route = t.route,
        pace = t.pace, runStart = t.runStart, total = t.total, yard = t.yard, yardYaw = t.yardYaw }
    cum = nil
    if EX.route and #EX.route > 1 then
        cum = { 0 }
        for i = 2, #EX.route do
            local a, b = EX.route[i - 1], EX.route[i]
            cum[i] = cum[i - 1] + Vector(b.x - a.x, b.y - a.y, 0):Length()
        end
    end
    if phase == "muster" then surface.PlaySound("ambient/alarms/warningbell1.wav") end
end)

net.Receive("lc_drill_cue", function()
    local move = net.ReadString()
    local deadline = net.ReadFloat()
    local leader = net.ReadBool()
    cue = { move = move, deadline = deadline, leader = leader, t = CurTime() }
    surface.PlaySound("buttons/blip1.wav")
end)

net.Receive("lc_drill_rope", function()
    rope = { start = net.ReadFloat(), interval = net.ReadFloat(), beats = net.ReadUInt(8), played = 0 }
end)

function LC_CL.Exercise() return EX end

-- the pace marker: this far along the route
local function Along(d)
    if not cum then return nil end
    for i = 2, #EX.route do
        if cum[i] >= d then
            local seg = cum[i] - cum[i - 1]
            local t = seg > 0 and (d - cum[i - 1]) / seg or 0
            return LerpVector(t, EX.route[i - 1], EX.route[i])
        end
    end
    return EX.route[#EX.route]
end

local function Clock(secs)
    secs = math.max(0, math.floor(secs))
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

local function Text(s, font, x, y, col)
    draw.SimpleTextOutlined(s, font, x, y, col or WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, SHADOW)
end

-- the rope: a whoosh on every beat
hook.Add("Think", "LivingCityExerciseRope", function()
    if not rope then return end
    local now = CurTime()
    local due = math.floor((now - rope.start) / rope.interval) + 1
    if now >= rope.start and due > rope.played and rope.played < rope.beats then
        rope.played = due
        surface.PlaySound("weapons/iceaxe/iceaxe_swing1.wav")
    end
    if now > rope.start + rope.interval * rope.beats + 1 then rope = nil end
end)

hook.Add("HUDPaint", "LivingCityExercise", function()
    if not EX then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now = CurTime()
    local cx, y = ScrW() / 2, ScrH() * 0.15
    local inIt = me:GetNW2Bool("lcx_in", false)
    local leader = me:GetNW2Bool("lcx_leader", false)
    local citizen = me:GetNW2String("lcf_faction", "") == "citizen"

    if EX.phase == "muster" then
        Text(NAMES[EX.kind] .. "   " .. Clock(EX.musterEnds - now), "LCExTitle", cx, y, AMBER)
        if citizen then
            if inIt then
                Text("You're here. Wait for the start.", "LCExText", cx, y + 24, GREEN)
            elseif EX.center then
                local m = math.floor(me:GetPos():Distance(EX.center) * 0.019)
                Text("Report to " .. GOAL[EX.kind] .. " (the marker), " .. m .. " m away. It's mandatory.", "LCExText", cx, y + 24, WHITE)
            end
        end
        return
    end

    Text(NAMES[EX.kind], "LCExTitle", cx, y, AMBER)
    if not citizen and not leader then return end
    if not inIt and not leader then
        Text("You're missing it. Report to " .. GOAL[EX.kind] .. " (the marker), before a unit finds you.", "LCExText", cx, y + 24, RED)
        return
    end

    if EX.kind == "jog" then
        local cp = me:GetNW2Int("lcx_cp", 0)
        local n = EX.route and #EX.route or 0
        if cp > n then
            Text("Finished.", "LCExText", cx, y + 24, GREEN)
        else
            Text(string.format("Marker %d of %d", math.max(1, cp - 1), math.max(1, n - 1)), "LCExText", cx, y + 24, WHITE)
            if me:GetNW2Bool("lcx_behind", false) then
                Text("BEHIND THE PACE: RUN", "LCExText", cx, y + 46, RED)
            end
            if me:GetNW2Float("lcx_boost", 0) > now then Text("SPEED BOOST", "LCExText", cx, y + 68, GREEN) end
        end
    elseif EX.kind == "drill" then
        if leader then
            Text("You lead: crouch, jump, turn around or step, one every few seconds. They copy you.", "LCExText", cx, y + 24, GREEN)
        else
            local m = me:GetNW2Int("lcx_mistakes", 0)
            Text("Copy every move. Stay on your place (the ring).   Mistakes: " .. m, "LCExText", cx, y + 24, m > 0 and AMBER or WHITE)
        end
        if cue and now < cue.deadline + 0.4 then
            local left = math.max(0, cue.deadline - now)
            Text(MOVE_SAY[cue.move] or string.upper(cue.move), "LCExCue", cx, ScrH() * 0.30, WHITE)
            local w = 220 * math.Clamp(left / math.max(0.1, cue.deadline - cue.t), 0, 1)
            surface.SetDrawColor(240, 190, 80, 220)
            surface.DrawRect(cx - 110, ScrH() * 0.30 + 30, w, 6)
        end
        if rope and now < rope.start + rope.interval * rope.beats then
            if now < rope.start then
                Text("SKIPPING: jump on every beat", "LCExText", cx, ScrH() * 0.30 + 50, AMBER)
            else
                local phase = ((now - rope.start) % rope.interval) / rope.interval
                local near = phase < 0.2 or phase > 0.75
                Text(near and "JUMP!" or "...", "LCExCue", cx, ScrH() * 0.30, near and GREEN or WHITE)
            end
        end
    elseif EX.kind == "parade" then
        local c = me:GetNW2Float("lcx_cheer", 0)
        local min = GetConVar("lc_parade_min") and GetConVar("lc_parade_min"):GetFloat() or 35
        local w, h = 300, 14
        local x0, y0 = cx - w / 2, y + 22
        surface.SetDrawColor(0, 0, 0, 170)
        surface.DrawRect(x0 - 2, y0 - 2, w + 4, h + 4)
        local col = c < min and RED or (c < 60 and AMBER or GREEN)
        surface.SetDrawColor(col.r, col.g, col.b, 230)
        surface.DrawRect(x0, y0, w * math.Clamp(c / 100, 0, 1), h)
        surface.SetDrawColor(255, 255, 255, 200)
        surface.DrawRect(x0 + w * min / 100, y0 - 3, 2, h + 6)
        Text("ENTHUSIASM   (/cheer, /salute, chant in chat, jump)", "LCExText", cx, y0 + h + 14, c < min and RED or WHITE)
    end
end)

-- markers in the world
local UP = Vector(0, 0, 300)
local function Beam(pos, col)
    render.DrawLine(pos, pos + UP, col, false)
    render.DrawWireframeBox(pos, Angle(0, 0, 0), Vector(-24, -24, 0), Vector(24, 24, 8), col, false)
end

hook.Add("PostDrawTranslucentRenderables", "LivingCityExercise", function(depth, sky)
    if sky or not EX then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    if me:GetNW2String("lcf_faction", "") ~= "citizen" and not me:GetNW2Bool("lcx_leader", false) then return end
    local inIt = me:GetNW2Bool("lcx_in", false)
    if (EX.phase == "muster" or not inIt) and EX.center then Beam(EX.center, AMBER) end
    if EX.phase ~= "run" then return end
    if EX.kind == "jog" and EX.route then
        local cp = me:GetNW2Int("lcx_cp", 0)
        if EX.route[cp] then Beam(EX.route[cp], GREEN) end
        if EX.runStart and EX.pace then
            local p = Along(math.min(EX.total or 0, (CurTime() - EX.runStart) * EX.pace))
            if p then render.DrawWireframeBox(p, Angle(0, 0, 0), Vector(-12, -12, 0), Vector(12, 12, 72), RED, false) end
        end
    elseif EX.kind == "drill" then
        local spot = me:GetNW2Vector("lcx_spot", nil)
        if spot and spot ~= Vector(0, 0, 0) then
            local prev
            for i = 0, 16 do
                local a = i / 16 * math.pi * 2
                local p = spot + Vector(math.cos(a) * 44, math.sin(a) * 44, 3)
                if prev then render.DrawLine(prev, p, GREEN, false) end
                prev = p
            end
        end
        if me:GetNW2Bool("lcx_leader", false) and EX.yard then Beam(EX.yard, GREEN) end
    end
end)
