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

-- Where a loop of keyframes is at `beat` (beats from the start): each keyframe held for its
-- own number of beats while easing into the next, round to the first again at the end.
-- Returns { [name] = { p, y, r } }.
local function Wrap(a) return (a + 180) % 360 - 180 end
function PR.Sample(frames, beat)
    local n = #frames
    if n == 0 then return {} end
    if n == 1 then return frames[1].bones end
    local total = 0
    for _, f in ipairs(frames) do total = total + (f.beats or 1) end
    local b = beat % total
    local i, at = 1, 0
    while i < n and b >= at + (frames[i].beats or 1) do at = at + (frames[i].beats or 1) i = i + 1 end
    local f = (b - at) / (frames[i].beats or 1)
    f = f * f * (3 - 2 * f)
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

return PR
