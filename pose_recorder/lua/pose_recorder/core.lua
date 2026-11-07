--[[
    Pose Recorder: the maths (shared, plain Lua, no engine calls, so it can be tested anywhere)

      A rotation is a 3x3 table, m[row][col], built the way Source builds one from an
      angle (AngleMatrix): its columns are the forward, left and up directions.

      The point of it all, PoseRecorder.Delta: given a model's bones as they stand in a
      reference pose (its idle, say) and as they stand posed on a ragdoll, the angle for
      each bone that Entity:ManipulateBoneAngles needs to turn the reference into the pose
      (the angle is applied in the bone's own frame, on top of whatever it's animating).
]]

PoseRecorder = PoseRecorder or {}
local PR = PoseRecorder
local rad, deg, sin, cos, sqrt = math.rad, math.deg, math.sin, math.cos, math.sqrt
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

function PR.FromAngles(p, y, r)
    local sp, cp = sin(rad(p)), cos(rad(p))
    local sy, cy = sin(rad(y)), cos(rad(y))
    local sr, cr = sin(rad(r)), cos(rad(r))
    return {
        { cp * cy, sr * sp * cy - cr * sy, cr * sp * cy + sr * sy },
        { cp * sy, sr * sp * sy + cr * cy, cr * sp * sy - sr * cy },
        { -sp,     sr * cp,                cr * cp },
    }
end

-- (back to pitch, yaw, roll: Source's MatrixAngles)
function PR.ToAngles(m)
    local fx, fy, fz = m[1][1], m[2][1], m[3][1]
    local lz, uz = m[3][2], m[3][3]
    local xy = sqrt(fx * fx + fy * fy)
    if xy > 0.001 then
        return deg(atan2(-fz, xy)), deg(atan2(fy, fx)), deg(atan2(lz, uz))
    end
    return deg(atan2(-fz, xy)), deg(atan2(-m[1][2], m[2][2])), 0
end

function PR.Mul(a, b)
    local o = { {}, {}, {} }
    for i = 1, 3 do
        for j = 1, 3 do o[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j] end
    end
    return o
end

-- (a rotation's inverse is its transpose)
function PR.T(a)
    return { { a[1][1], a[2][1], a[3][1] }, { a[1][2], a[2][2], a[3][2] }, { a[1][3], a[2][3], a[3][3] } }
end

local function Round(x) return math.floor(x * 10 + 0.5) / 10 end

--[[ The angles that turn the reference into the pose.
     bones:    { { name = "ValveBiped.Bip01_Pelvis", parent = nil }, { name = ..., parent = 1 }, ... }
               in the model's own order (a bone's parent always comes before it)
     refRel:   [i] = the bone's rotation in the reference pose, relative to the model itself
     posed:    [i] = the bone's rotation on the posed ragdoll, in the world
     record:   [i] = true for the bones to record (a ragdoll's physics bones: the ones you can pose)
   Returns { [name] = { p, y, r } } for the recorded bones, and the yaw the pose faces
   (the root's own lean and twist are recorded; which way it faces is not). Bones that
   aren't recorded stay as the reference has them, and the ones below them are worked out
   from there, so the result looks right on a model that's animating normally. ]]
function PR.Delta(bones, refRel, posed, record)
    local refL = {}
    for i, b in ipairs(bones) do
        local r = refRel[i] or PR.FromAngles(0, 0, 0)
        local pr = b.parent and (refRel[b.parent] or PR.FromAngles(0, 0, 0))
        refL[i] = pr and PR.Mul(PR.T(pr), r) or r
    end
    -- the frame the pose stands in: upright, facing the way its root faces
    local root
    for i, b in ipairs(bones) do if not b.parent and record[i] and posed[i] then root = i break end end
    local face = 0
    if root then
        local _, y = PR.ToAngles(PR.Mul(posed[root], PR.T(refL[root])))
        face = y
    end
    local frame = PR.FromAngles(0, face, 0)
    local final, out = {}, {}
    for i, b in ipairs(bones) do
        local base = PR.Mul(b.parent and final[b.parent] or frame, refL[i])
        if record[i] and posed[i] then
            local R = PR.Mul(PR.T(base), posed[i])
            local p, y, r = PR.ToAngles(R)
            out[b.name] = { Round(p), Round(y), Round(r) }
            final[i] = posed[i]
        else
            final[i] = base
        end
    end
    return out, face
end

-- Easing: how a keyframe moves into the next (f goes 0 to 1 across the keyframe's beats).
--   smooth: eases out and in (the tool's original, and the default)
--   snappy: off the mark at once, settling gently into the next pose
--   bouncy: swings a little past the next pose and settles back
--   linear: an even speed all the way
PR.EASES = { "smooth", "snappy", "bouncy", "linear" }
PR.Ease = {
    smooth = function(f) return f * f * (3 - 2 * f) end,
    snappy = function(f) local g = 1 - f return 1 - g * g * g * g end,
    bouncy = function(f) local g = f - 1 return 1 + 2.70158 * g * g * g + 1.70158 * g * g end,
    linear = function(f) return f end,
}

-- A loop's length in beats: every keyframe's own beats added up.
function PR.Length(frames)
    local total = 0
    for _, f in ipairs(frames) do total = total + (f.beats or 1) end
    return total
end

-- Where a loop of keyframes is at `beat` (beats from the start): each keyframe held for its
-- own number of beats while easing into the next with its own easing, round to the first
-- again at the end. With wrap false the last keyframe holds still for its beats instead of
-- easing back into the first. Returns { [name] = { p, y, r } }.
local function Wrap(a) return (a + 180) % 360 - 180 end
PR.WrapAngle = Wrap
function PR.Sample(frames, beat, wrap)
    local n = #frames
    if n == 0 then return {} end
    if n == 1 then return frames[1].bones end
    local total = PR.Length(frames)
    local b = beat % total
    local i, at = 1, 0
    while i < n and b >= at + (frames[i].beats or 1) do at = at + (frames[i].beats or 1) i = i + 1 end
    if i == n and wrap == false then return frames[n].bones end
    local f = (b - at) / (frames[i].beats or 1)
    f = (PR.Ease[frames[i].ease or "smooth"] or PR.Ease.smooth)(math.min(1, math.max(0, f)))
    local A, B = frames[i].bones, frames[i % n + 1].bones
    local out = {}
    for name, a in pairs(A) do
        local c = B[name] or { 0, 0, 0 }
        out[name] = { a[1] + Wrap(c[1] - a[1]) * f, a[2] + Wrap(c[2] - a[2]) * f, a[3] + Wrap(c[3] - a[3]) * f }
    end
    for name, c in pairs(B) do
        if not A[name] then out[name] = { c[1] * f, c[2] * f, c[3] * f } end
    end
    return out
end

-- The same along a recording (real seconds, not beats): straight between the samples.
function PR.SampleRecording(frames, t)
    local n = #frames
    if n == 0 then return {} end
    local len = frames[n].t or 0
    if len <= 0 then return frames[1].bones end
    t = t % len
    local i = 1
    while i < n and frames[i + 1].t <= t do i = i + 1 end
    if i >= n then return frames[n].bones end
    local f = (t - frames[i].t) / math.max(0.001, frames[i + 1].t - frames[i].t)
    local A, B, out = frames[i].bones, frames[i + 1].bones, {}
    for name, a in pairs(A) do
        local c = B[name] or a
        out[name] = { a[1] + Wrap(c[1] - a[1]) * f, a[2] + Wrap(c[2] - a[2]) * f, a[3] + Wrap(c[3] - a[3]) * f }
    end
    return out
end


------------------------------------------------------------------------
-- Playing an animation on an entity: where it is after t seconds
------------------------------------------------------------------------

-- anim is a whole animation, as saved (and cleaned by PR.Sanitize): { mode = "keys" or "rec",
-- bpm = 120, wrap = true, frames = { ... } }.
PR.PLAY_MODES = { "loop", "once", "hold" }
PR.FADE = 0.2 -- (seconds to ease in from the model's own idle, and back out when "once" ends)

-- One pass, in seconds, at normal speed.
function PR.Duration(anim)
    local frames = anim.frames or {}
    local n = #frames
    if n == 0 then return 0 end
    if anim.mode == "rec" then return frames[n].t or 0 end
    return PR.Length(frames) * 60 / math.max(1, anim.bpm or 120)
end

-- When the last keyframe is reached (where "hold" stops), in seconds at normal speed.
function PR.LastKeyTime(anim)
    local frames = anim.frames or {}
    local n = #frames
    if n <= 1 then return 0 end
    if anim.mode == "rec" then return frames[n].t or 0 end
    local beats = 0
    for i = 1, n - 1 do beats = beats + (frames[i].beats or 1) end
    return beats * 60 / math.max(1, anim.bpm or 120)
end

-- The pose `s` seconds into the animation (looping round).
function PR.PoseAt(anim, s)
    if anim.mode == "rec" then return PR.SampleRecording(anim.frames, s) end
    return PR.Sample(anim.frames, s * math.max(1, anim.bpm or 120) / 60, anim.wrap ~= false)
end

--[[ Where an animation is, t real seconds after it started.
     opts.mode: "loop" (round and round), "once" (one pass, then back to the model's own idle)
                or "hold" (to the last keyframe, then stays in that pose)
     opts.speed: 1 is as made, 2 twice as fast, 0.5 half
   Returns the pose ({ [name] = { p, y, r } }), how much of it to apply (0 to 1: it eases in
   over PR.FADE seconds, and a "once" eases back out), and true once it's over. ]]
function PR.Evaluate(anim, t, opts)
    opts = opts or {}
    local speed = math.min(4, math.max(0.1, tonumber(opts.speed) or 1))
    local mode = opts.mode
    t = math.max(0, t or 0)
    local s = t * speed
    local w = PR.FADE > 0 and math.min(1, t / PR.FADE) or 1
    local frames = anim.frames or {}
    local n = #frames
    if n == 0 then return {}, 0, true end
    if mode == "hold" then
        if s >= PR.LastKeyTime(anim) then return frames[n].bones, w, false end
        return PR.PoseAt(anim, s), w, false
    elseif mode == "once" then
        local dur = PR.Duration(anim)
        if s < dur then return PR.PoseAt(anim, s), w, false end
        -- over: the pose it ended in (the first keyframe again if it wraps), easing out
        local last = (anim.mode ~= "rec" and anim.wrap ~= false) and frames[1].bones or frames[n].bones
        local out = PR.FADE > 0 and (1 - ((s - dur) / speed) / PR.FADE) or 0
        if out <= 0 then return last, 0, true end
        return last, math.min(w, out), false
    end
    return PR.PoseAt(anim, s), w, false
end

------------------------------------------------------------------------
-- Mirroring: left and right swapped
------------------------------------------------------------------------

-- A bone's partner on the other side (ValveBiped.Bip01_L_Hand <-> ValveBiped.Bip01_R_Hand),
-- or the same name for a bone down the middle (the pelvis, the spine, the head).
function PR.MirrorName(name)
    local s = name:gsub("_L_", "\1"):gsub("_R_", "_L_"):gsub("\1", "_R_")
    if s ~= name then return s end
    for _, pair in ipairs({ { "_L$", "_R" }, { "_R$", "_L" }, { "%.L$", ".R" }, { "%.R$", ".L" }, { "Left", "Right" }, { "Right", "Left" } }) do
        local r, n = name:gsub(pair[1], pair[2])
        if n > 0 then return r end
    end
    return name
end

--[[ Which of a bone's three angles keeps its sign in the mirror (the other two flip).
     From the owner's screenshots of the ValveBiped skeleton: on the arms yaw raises an arm
     forward the same way on both sides (minus is up) while pitch takes it out to the side
     with opposite signs (minus for the right arm, plus for the left), so a limb keeps yaw;
     on the head and spine pitch nods, yaw tilts side to side and roll twists, so a bone down
     the middle keeps pitch. (Two of the three always flip together: a mirrored turn is a
     turn the other way about two of the bone's axes.) PR.MirrorKeep[name] = "p", "y" or "r"
     overrides it for one bone. ]]
PR.MirrorKeep = PR.MirrorKeep or {}
function PR.MirrorAngles(name, a)
    local keep = PR.MirrorKeep[name] or (PR.MirrorName(name) ~= name and "y" or "p")
    local p, y, r = a[1], a[2], a[3]
    if keep == "p" then return { p, -y, -r } end
    if keep == "r" then return { -p, -y, r } end
    return { -p, y, -r }
end

-- A whole pose mirrored: each bone's turn moved to its partner, the signs flipped.
function PR.MirrorPose(bones)
    local out = {}
    for name, a in pairs(bones) do
        local m = PR.MirrorAngles(name, a)
        out[PR.MirrorName(name)] = { Wrap(m[1]) + 0, Wrap(m[2]) + 0, Wrap(m[3]) + 0 }
    end
    return out
end

-- Every keyframe mirrored (their beats, easing and times kept).
function PR.MirrorFrames(frames)
    local out = {}
    for i, f in ipairs(frames) do
        local c = {}
        for k, v in pairs(f) do c[k] = v end
        c.bones = PR.MirrorPose(f.bones or {})
        out[i] = c
    end
    return out
end

------------------------------------------------------------------------
-- Files: checking one before it's used (they come from other players and other addons)
------------------------------------------------------------------------

PR.FORMAT = 2 -- (1: the first Pose Recorder, with no "format" field; 2: adds wrap, and ease on each keyframe)
PR.LIMITS = {
    frames = 600,       -- keyframes or samples
    bones = 80,         -- bones in one keyframe
    boneName = 64,      -- characters
    name = 48,          -- characters in an animation's name
    beats = { 0.05, 64 },
    bpm = { 10, 400 },
    seconds = 600,      -- a recording's length
    bytes = 262144,     -- a file, as text
}

-- An animation's name as a file name: lower case, letters, digits, _ and - only.
function PR.CleanName(s)
    if type(s) ~= "string" then return nil end
    s = string.lower(s):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[^%w_%-]", "_")
    s = string.sub(s, 1, PR.LIMITS.name)
    if s == "" or s:match("^_+$") then return nil end
    return s
end

local function Finite(x)
    return type(x) == "number" and x == x and x > -1e9 and x < 1e9
end

local function Text(s, max, pattern)
    if type(s) ~= "string" or #s > max or (pattern and not s:match(pattern)) then return nil end
    return s
end

local function Round2(x) return math.floor(x * 100 + 0.5) / 100 end

--[[ A loaded file (a table from JSON) made safe to play, or nil and what's wrong with it.
     Reads every version: a file without "format" is the first Pose Recorder's, which had no
     easing (smooth everywhere) and always wrapped. Unknown fields are dropped; anything that
     isn't a plain number where a number belongs, or is too big, turns the file down. ]]
function PR.Sanitize(t)
    local L = PR.LIMITS
    if type(t) ~= "table" then return nil, "it isn't an animation" end
    if type(t.frames) ~= "table" then return nil, "it has no keyframes" end
    local mode = t.mode == "rec" and "rec" or "keys"
    local out = {
        format = PR.FORMAT,
        tool = Text(t.tool, 64),
        name = PR.CleanName(t.name),
        model = Text(t.model, 160, "^[%w_%-%./]+$"),
        ref = Text(t.ref, 64, "^[%w_%-%.]+$"),
        bpm = Finite(t.bpm) and math.min(L.bpm[2], math.max(L.bpm[1], t.bpm)) or 120,
        mode = mode,
        wrap = t.wrap ~= false,
        frames = {},
    }
    local n = 0
    for k in pairs(t.frames) do
        n = n + 1
        if n > L.frames then return nil, "it has more than " .. L.frames .. " keyframes" end
        if type(k) ~= "number" then return nil, "its keyframes aren't a list" end
    end
    if n == 0 then return nil, "it has no keyframes" end
    local lastT = 0
    for i = 1, n do
        local f = t.frames[i]
        if type(f) ~= "table" or type(f.bones) ~= "table" then return nil, "keyframe " .. i .. " is broken" end
        local bones, count = {}, 0
        for name, a in pairs(f.bones) do
            count = count + 1
            if count > L.bones then return nil, "keyframe " .. i .. " has more than " .. L.bones .. " bones" end
            if not Text(name, L.boneName, "^[%w_%-%. ]+$") then return nil, "keyframe " .. i .. " has a bad bone name" end
            if type(a) ~= "table" or not (Finite(a[1]) and Finite(a[2]) and Finite(a[3])) then
                return nil, "keyframe " .. i .. " has a bad angle on " .. name
            end
            bones[name] = { Round2(Wrap(a[1])) + 0, Round2(Wrap(a[2])) + 0, Round2(Wrap(a[3])) + 0 }
        end
        local c = { bones = bones }
        if mode == "rec" then
            if not Finite(f.t) or f.t < lastT or f.t > L.seconds then return nil, "sample " .. i .. " has a bad time" end
            c.t, lastT = f.t, f.t
        else
            c.beats = Finite(f.beats) and math.min(L.beats[2], math.max(L.beats[1], f.beats)) or 1
            c.ease = (type(f.ease) == "string" and PR.Ease[f.ease]) and f.ease or "smooth"
        end
        out.frames[i] = c
    end
    return out
end

return PR
