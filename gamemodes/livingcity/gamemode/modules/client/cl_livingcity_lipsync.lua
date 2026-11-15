--[[
    Living City: mouths that move with the recorded voices (the owner, 12 November: "With the new
    voices, can we get the NPCs' mouths to move? HL2 has auto lip sync of a sort, can we just use
    that?").

    Source's own lip sync reads the phonemes stored in Half-Life 2's clips; the owner's recordings
    have none, so the face stayed still. The server marks whoever says one of them talking, and for
    how long ("lc_talk_from", "lc_talk_until": sv_livingcity_lines.lua, LC.MarkTalking). Here, for
    those near you (LC.LipSyncRange), the jaw and lips are worked in a talking pattern for the
    length of the line, then closed. Only a face that has a jaw (found by name): a metrocop's mask
    or a soldier's helmet has none, and is left alone. Half-Life 2's own clips keep the engine's.

    A recording by itself cannot move a mouth: the game's own lines move it from phoneme data
    written into each .wav by Valve's Faceposer, and a plain recording has none. So the jaw is
    worked here. Two things kept it still on the server (the owner, 14 November: "the NPC's mouth
    doesn't move with the voice lines"):
      - it was set in Think, and the game then smooths every networked NPC's face back to what the
        server last sent, just before it draws. It is set again at draw time now
        (PreDrawOpaqueRenderables), after that smoothing: what is drawn is ours;
      - a speaker was noticed only through EntityNetworkedVarChanged, which a game does not always
        call. Whoever is marked talking near you is also looked for four times a second.
]]

LC = LC or {}

LC.LipSyncRange = 900

-- The face's controls, by name, for each model: false when it has no jaw.
local JAW = { "jaw_drop", "jaw_open", "mouth_open", "jaw" }
local LIPS = { "right_part", "left_part", "right_mouth_drop", "left_mouth_drop" }
local faces = {}

function LC.LipSyncFace(ent)
    local m = ent.GetModel and ent:GetModel()
    if not m then return false end
    if faces[m] ~= nil then return faces[m] end
    local f = false
    if ent.GetFlexNum and (ent:GetFlexNum() or 0) > 0 and ent.GetFlexIDByName then
        local jaw
        for _, n in ipairs(JAW) do
            jaw = ent:GetFlexIDByName(n)
            if jaw then break end
        end
        if jaw then
            f = { jaw = jaw, lips = {} }
            for _, n in ipairs(LIPS) do
                local id = ent:GetFlexIDByName(n)
                if id then f.lips[#f.lips + 1] = id end
            end
        end
    end
    faces[m] = f
    return f
end

-- How open the mouth is, t seconds into a line that ends at `left` seconds from now: a quick flap
-- of syllables, louder and softer by turns, with short pauses between words (0 to 1).
function LC.LipSyncOpen(t, left, seed)
    seed = seed or 0
    local syll = 0.5 + 0.5 * math.sin(t * 15.7 + seed)
    local word = 0.55 + 0.45 * math.sin(t * 3.3 + seed * 1.7)
    local gap = math.sin(t * 1.9 + seed * 0.6) > 0.82 and 0.15 or 1
    local v = syll * word * gap
    -- opening at the start, closing at the end
    v = v * math.Clamp(t / 0.08, 0, 1) * math.Clamp(left / 0.15, 0, 1)
    return math.Clamp(v, 0, 1)
end

local talking = {} -- [ent] = { face, rest = { [id] = weight before } }

local function Range(id, ent)
    if ent.GetFlexBounds then
        local lo, hi = ent:GetFlexBounds(id)
        if lo and hi and hi > lo then return lo, hi end
    end
    return 0, 1
end

local function Close(ent, t)
    if IsValid(ent) and t.rest and ent.SetFlexWeight then
        for id, w in pairs(t.rest) do ent:SetFlexWeight(id, w) end
    end
    talking[ent] = nil
end

local function Start(ent)
    if talking[ent] or not IsValid(ent) then return end
    local face = LC.LipSyncFace(ent)
    if not face then return end
    local rest = {}
    if ent.GetFlexWeight then
        rest[face.jaw] = ent:GetFlexWeight(face.jaw) or 0
        for _, id in ipairs(face.lips) do rest[id] = ent:GetFlexWeight(id) or 0 end
    end
    talking[ent] = { face = face, rest = rest, seed = (ent.EntIndex and ent:EntIndex() or 0) % 7 }
end

-- The server marks a speaker (lc_talk_until): start working their face.
hook.Add("EntityNetworkedVarChanged", "LivingCityLipSync", function(ent, name, _, new)
    if name ~= "lc_talk_until" or not IsValid(ent) then return end
    if type(new) == "number" and new > CurTime() then Start(ent) end
end)

-- Anyone near you the server has marked talking, whether or not the hook above was called.
local nextScan = 0
function LC.LipSyncScan(now)
    local me = LocalPlayer and LocalPlayer()
    if not IsValid(me) or not ents.FindInSphere then return 0 end
    local n = 0
    for _, ent in ipairs(ents.FindInSphere(me:EyePos(), LC.LipSyncRange)) do
        if IsValid(ent) and not talking[ent] and ent.GetNW2Float and not (ent.IsPlayer and ent:IsPlayer())
            and ent:GetNW2Float("lc_talk_until", 0) > now then
            Start(ent)
            if talking[ent] then n = n + 1 end
        end
    end
    return n
end

-- The faces at work: every frame, and again as the frame is drawn (see the top of this file).
local function Work()
    local now = CurTime()
    if now >= nextScan then
        nextScan = now + 0.25
        LC.LipSyncScan(now)
    end
    if next(talking) == nil then return end
    local me = LocalPlayer and LocalPlayer()
    local eye = IsValid(me) and me:EyePos() or nil
    local range = LC.LipSyncRange * LC.LipSyncRange
    for ent, t in pairs(talking) do
        if not IsValid(ent) then
            talking[ent] = nil
        else
            local untilT = ent:GetNW2Float("lc_talk_until", 0)
            local from = ent:GetNW2Float("lc_talk_from", now)
            local alive = not ent.Health or ent:Health() > 0
            if now >= untilT or not alive then
                Close(ent, t)
            elseif eye and ent:GetPos():DistToSqr(eye) <= range and not (ent.IsDormant and ent:IsDormant()) then
                local open = LC.LipSyncOpen(now - from, untilT - now, t.seed)
                local lo, hi = Range(t.face.jaw, ent)
                ent:SetFlexWeight(t.face.jaw, lo + (hi - lo) * open * 0.7)
                for i, id in ipairs(t.face.lips) do
                    local l2, h2 = Range(id, ent)
                    ent:SetFlexWeight(id, l2 + (h2 - l2) * open * (i <= 2 and 0.6 or 0.35))
                end
            end
        end
    end
end
hook.Add("Think", "LivingCityLipSync", Work)
hook.Add("PreDrawOpaqueRenderables", "LivingCityLipSync", function(depth, sky)
    if depth or sky then return end -- (once a frame, for the view itself)
    if next(talking) ~= nil then Work() end
end)
