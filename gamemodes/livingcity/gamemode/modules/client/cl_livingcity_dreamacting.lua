--[[
    Living City: how the dreams' stand-ins move (sv_livingcity_dreamstandins.lua)

    The owner, 10 November: better animation for the dreams' scenes.

    The city's people who dream along with the players are plain figures playing one of the
    model's own sequences. The server says what each is doing (NW2 string "lc_dream_act" on the
    figure: cower, flinch, cheer, wave, look, kneel, plead, sway, panic), and here, on each
    dreamer's screen, their arms, head and back are moved on top of that sequence, every frame:

      cower   hands over the head, hunched, trembling
      flinch  arms thrown up and a lean back, gone in a second
      cheer   both arms up, fists pumping
      wave    one arm up, the forearm waving
      look    a glance over one shoulder, then the other
      kneel   on their knees to her: arms held out, face lifted to her
      plead   on their knees: hands together, head bowed, rocking
      sway    shifting their weight, as people standing about do
      panic   running with a look back over the shoulder, the arms loose

    When the model has a sequence of its own for the act ("lc_dream_act_own"), only the small
    things are added (the trembling, the turn of the head): the sequence does the rest. Every
    move eases into the next, so nothing snaps.

    How the bones turn (as the endings' dances found, cl_livingcity_endings.lua): on an upper arm
    yaw raises it forward (minus is up) and pitch takes it out to the side (minus for the right
    arm, plus for the left); a forearm bends at the elbow on yaw (minus). On the back and the
    head, yaw bends forward (plus) or back (minus) and roll turns to the side.
]]

LC_CL = LC_CL or {}

local BONES = { "R_UpperArm", "L_UpperArm", "R_Forearm", "L_Forearm", "Spine2", "Head1" }
local ZERO = Angle(0, 0, 0)

-- The pose for an act, t seconds into it. own: the model's own sequence is doing the act.
-- A table of bone name = Angle (bones left out are at rest).
function LC_CL.DreamActPose(act, t, own)
    local sin = math.sin
    if act == "cower" then
        local tr = sin(t * 31) * 2.5 -- (trembling)
        if own then return { Head1 = Angle(0, 6 + tr * 0.6, sin(t * 2.3) * 8), R_Forearm = Angle(0, tr, 0), L_Forearm = Angle(0, -tr, 0) } end
        return {
            R_UpperArm = Angle(20, -125 + tr, 0), L_UpperArm = Angle(-20, -125 - tr, 0),
            R_Forearm = Angle(0, -105 + tr, 0), L_Forearm = Angle(0, -105 - tr, 0),
            Spine2 = Angle(0, 14, 0), Head1 = Angle(0, 20, sin(t * 2.3) * 6),
        }
    elseif act == "flinch" then
        if own then return {} end
        local k = math.Clamp(1 - t / 0.9, 0, 1)
        k = k * k
        return {
            R_UpperArm = Angle(15 * k, -85 * k, 0), L_UpperArm = Angle(-15 * k, -85 * k, 0),
            R_Forearm = Angle(0, -95 * k, 0), L_Forearm = Angle(0, -95 * k, 0),
            Spine2 = Angle(0, -10 * k, 0), Head1 = Angle(0, -8 * k, 0),
        }
    elseif act == "cheer" then
        if own then return {} end
        local b = math.abs(sin(t * 7.5))
        return {
            R_UpperArm = Angle(10, -120 + 25 * b, 0), L_UpperArm = Angle(-10, -120 + 25 * (1 - b), 0),
            R_Forearm = Angle(0, -20, 0), L_Forearm = Angle(0, -20, 0),
            Head1 = Angle(0, -8 * b, 0),
        }
    elseif act == "wave" then
        if own then return {} end
        return { R_UpperArm = Angle(-25, -115, 0), R_Forearm = Angle(0, -35 + 28 * sin(t * 9), 0), Head1 = Angle(0, -4, 0) }
    elseif act == "look" then
        local turn = sin(t * 1.6) * (own and 18 or 40)
        return { Head1 = Angle(0, 0, turn), Spine2 = Angle(0, 0, turn * 0.3) }
    elseif act == "kneel" then
        local lift = sin(t * 1.3) * 8
        return {
            R_UpperArm = Angle(-18, -72 + lift, 0), L_UpperArm = Angle(18, -72 + lift, 0),
            R_Forearm = Angle(0, -25, 0), L_Forearm = Angle(0, -25, 0),
            Head1 = Angle(0, -16, 0),
        }
    elseif act == "plead" then
        local rock = sin(t * 1.9) * 5
        return {
            R_UpperArm = Angle(22, -42, 0), L_UpperArm = Angle(-22, -42, 0),
            R_Forearm = Angle(0, -100, 0), L_Forearm = Angle(0, -100, 0),
            Spine2 = Angle(0, 8 + rock, 0), Head1 = Angle(0, 16, 0),
        }
    elseif act == "sway" then
        local w = sin(t * 1.2)
        return { Spine2 = Angle(4 * w, 0, 3 * w), Head1 = Angle(-3 * w, 0, sin(t * 0.7) * 10) }
    elseif act == "panic" then
        local f = sin(t * 13) * 14
        return { Head1 = Angle(0, 0, sin(t * 2.6) * 30), R_Forearm = Angle(0, -18 + f, 0), L_Forearm = Angle(0, -18 - f, 0) }
    end
    return {}
end

local state = setmetatable({}, { __mode = "k" }) -- [figure] = { ids = { name = bone id }, cur = { name = Angle } }

local function Approach(a, b, k)
    return Angle(a.p + (b.p - a.p) * k, a.y + (b.y - a.y) * k, a.r + (b.r - a.r) * k)
end

-- Move one figure's bones towards what its act calls for now. dt: the frame's seconds.
function LC_CL.DreamActApply(e, now, dt)
    if not e.ManipulateBoneAngles or not e.LookupBone then return end
    local st = state[e]
    if not st then
        st = { ids = {}, cur = {} }
        for _, name in ipairs(BONES) do
            local id = e:LookupBone("ValveBiped.Bip01_" .. name)
            if id and id >= 0 then st.ids[name], st.cur[name] = id, Angle(0, 0, 0) end
        end
        state[e] = st
    end
    local act = e:GetNW2String("lc_dream_act", "")
    local pose = LC_CL.DreamActPose(act, math.max(0, now - e:GetNW2Float("lc_dream_act_t", now)), e:GetNW2Bool("lc_dream_act_own", false))
    local k = math.Clamp((dt or 0.015) * 9, 0, 1)
    for name, id in pairs(st.ids) do
        local a = Approach(st.cur[name], pose[name] or ZERO, k)
        st.cur[name] = a
        e:ManipulateBoneAngles(id, a)
    end
end

-- The figures to move: looked for once a second, only while you dream.
local list, nextScan = {}, 0
local function Scan()
    list = {}
    for _, e in ipairs(ents.FindByClass and ents.FindByClass("prop_dynamic") or {}) do
        if IsValid(e) and e.GetNW2Bool and e:GetNW2Bool("lc_dream_standin", false) then list[#list + 1] = e end
    end
end
LC_CL.DreamActFigures = function() return list end

hook.Add("Think", "LivingCityDreamActing", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then
        if #list > 0 then list = {} end
        return
    end
    local now = CurTime()
    if now >= nextScan then nextScan = now + 1 Scan() end
    local dt = FrameTime and FrameTime() or 0.015
    for _, e in ipairs(list) do
        if IsValid(e) then LC_CL.DreamActApply(e, now, dt) end
    end
end)
