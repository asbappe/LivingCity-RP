--[[
    Living City: how the dreams' figures move (sv_livingcity_dreamstandins.lua, sv_livingcity_dreamstage.lua)

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
      regal   her figure: chin up, a hand lifted now and then
      scorn   her figure: pointing at a dreamer who has just lost a life
      bless   her figure: a hand held out over a dreamer who has won
      gloat   a hunter: a fist raised and shaken over someone it caught
      slump   a hunter, beaten: head hung

    The same goes for the dream's own figures and for the other dreamers' bodies (flinch, cower,
    cheer): anything with "lc_dream_actor" set. An act with "lc_dream_act_end" is over at that
    time. When the dream is over, or something stops acting, its bones go back as they were.
    Also here: the opening and the finish (the dream's name, or who made it through, between two
    black bars).

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
    elseif act == "regal" then
        -- her figure: chin up, a slow breath, one hand lifted a little now and then
        local lift = math.max(0, sin(t * 0.5)) ^ 3
        return { Head1 = Angle(0, -8, sin(t * 0.35) * 14), Spine2 = Angle(0, -3 + sin(t * 0.9) * 1.5, 0),
            R_UpperArm = Angle(-10 * lift, -40 * lift, 0), R_Forearm = Angle(0, -50 * lift, 0) }
    elseif act == "scorn" then
        -- pointing at someone: the arm straight out, a lean towards them
        local k = math.Clamp(t / 0.25, 0, 1)
        return { R_UpperArm = Angle(-6 * k, -88 * k, 0), R_Forearm = Angle(0, -4 * k, 0), Spine2 = Angle(0, 7 * k, 0), Head1 = Angle(0, 8 * k, 0) }
    elseif act == "bless" then
        -- a hand held out, palm down, over someone who has pleased her
        local k = math.Clamp(t / 0.5, 0, 1)
        return { R_UpperArm = Angle(-14 * k, -70 * k, 0), R_Forearm = Angle(0, -18 * k, 0), Head1 = Angle(0, 12 * k, 0), Spine2 = Angle(0, 5 * k, 0) }
    elseif act == "gloat" then
        -- a hunter over someone it caught: a fist raised and shaken
        return { R_UpperArm = Angle(8, -128 + 12 * sin(t * 11), 0), R_Forearm = Angle(0, -45, 0), Head1 = Angle(0, 12, 0), Spine2 = Angle(0, 6, 0) }
    elseif act == "slump" then
        -- beaten: head hung, shoulders down
        return { Head1 = Angle(0, 24, sin(t * 0.8) * 5), Spine2 = Angle(0, 12, 0), R_UpperArm = Angle(4, 6, 0), L_UpperArm = Angle(-4, 6, 0) }
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
    local till = e:GetNW2Float("lc_dream_act_end", 0)
    if till > 0 and now >= till then act = "" end -- (a timed act, over)
    -- (each in their own time: a row of admirers doesn't move as one)
    local phase = (e.EntIndex and (e:EntIndex() % 17) * 0.37) or 0
    local t = math.max(0, now - e:GetNW2Float("lc_dream_act_t", now))
    local pose = LC_CL.DreamActPose(act, (act == "flinch" or act == "scorn" or act == "bless") and t or (t + phase), e:GetNW2Bool("lc_dream_act_own", false))
    local k = math.Clamp((dt or 0.015) * 9, 0, 1)
    for name, id in pairs(st.ids) do
        local a = Approach(st.cur[name], pose[name] or ZERO, k)
        st.cur[name] = a
        e:ManipulateBoneAngles(id, a)
    end
end
-- Everything back as it was (the dream's over, or it isn't acting any more).
function LC_CL.DreamActRest(e)
    local st = state[e]
    state[e] = nil
    if not st or not e or (e.IsValid and not e:IsValid()) or not e.ManipulateBoneAngles then return end
    for _, id in pairs(st.ids) do e:ManipulateBoneAngles(id, Angle(0, 0, 0)) end
end

-- The figures to move: looked for once a second, only while you dream. The stand-ins, the dream's own
-- figures (sv_livingcity_dreamstage.lua) and the other dreamers' bodies.
local list, nextScan = {}, 0
local function Acting(e)
    return IsValid(e) and e.GetNW2Bool and (e:GetNW2Bool("lc_dream_standin", false) or e:GetNW2Bool("lc_dream_actor", false))
end
local function Scan()
    local was = list
    list = {}
    local seen = {}
    for _, e in ipairs(ents.FindByClass and ents.FindByClass("prop_dynamic") or {}) do
        if Acting(e) then list[#list + 1] = e seen[e] = true end
    end
    for _, p in ipairs(player.GetAll and player.GetAll() or {}) do
        if Acting(p) then list[#list + 1] = p seen[p] = true end
    end
    for _, e in ipairs(was) do if not seen[e] then LC_CL.DreamActRest(e) end end
end
LC_CL.DreamActFigures = function() return list end
LC_CL.DreamActScan = Scan

hook.Add("Think", "LivingCityDreamActing", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then
        if #list > 0 then
            for _, e in ipairs(list) do LC_CL.DreamActRest(e) end
            list = {}
        end
        return
    end
    local now = CurTime()
    if now >= nextScan then nextScan = now + 1 Scan() end
    local dt = FrameTime and FrameTime() or 0.015
    for _, e in ipairs(list) do
        if IsValid(e) then LC_CL.DreamActApply(e, now, dt) end
    end
end)

------------------------------------------------------------------------
-- The opening and the finish: the dream's name, or who made it, between two black bars
------------------------------------------------------------------------

local card -- { k, title, sub, t0, secs, col }
local CARDCOL = { happy = Color(255, 230, 170), neutral = Color(215, 205, 255), nightmare = Color(230, 120, 120), propaganda = Color(255, 200, 120) }
local OPENSUB = { happy = "A happy dream", neutral = "A strange dream", nightmare = "A nightmare", propaganda = "A dream of her" }
net.Receive("lc_dream_stage", function()
    local t = net.ReadTable() or {}
    local me = LocalPlayer()
    if t.k == "open" then
        card = { k = "open", title = tostring(t.name or ""), sub = OPENSUB[t.mood or ""] or "A dream", t0 = CurTime(), secs = tonumber(t.secs) or 3.5, col = CARDCOL[t.mood or ""] }
    elseif t.k == "finish" then
        local mine = IsValid(me) and me.SteamID64 and t.sid ~= nil and me:SteamID64() == t.sid
        card = { k = "finish", title = mine and "You made it through" or (tostring(t.who or "Someone") .. " made it through"),
            sub = (t.first and "First through " or "Through ") .. tostring(t.name or "the dream"), t0 = CurTime(), secs = tonumber(t.secs) or 3.5, col = Color(255, 225, 130) }
    end
end)
LC_CL.DreamStageCard = function() return card end
hook.Add("HUDPaint", "LivingCityDreamStage", function()
    if not card then return end
    local me = LocalPlayer()
    local t = CurTime() - card.t0
    if t > card.secs or not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then card = nil return end
    -- (in over a third of a second, out over the last two thirds of one)
    local a = math.Clamp(t / 0.35, 0, 1) * math.Clamp((card.secs - t) / 0.65, 0, 1)
    local w, h = ScrW(), ScrH()
    local bar = math.floor(h * 0.11 * a)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, bar)
    surface.DrawRect(0, h - bar, w, bar)
    local c = card.col or Color(235, 235, 235)
    local y = card.k == "open" and h * 0.36 or h * 0.2
    draw.SimpleTextOutlined(card.title, "DermaLarge", w / 2, y, Color(c.r, c.g, c.b, math.floor(255 * a)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, math.floor(220 * a)))
    draw.SimpleTextOutlined(card.sub, "DermaDefaultBold", w / 2, y + 30, Color(230, 230, 235, math.floor(220 * a)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, math.floor(200 * a)))
end)
