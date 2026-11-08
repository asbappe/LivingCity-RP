--[[
    Pose Recorder

      Pose a ragdoll with the physgun, snap it as a keyframe (or record it moving), and
      get each bone's angle the way Entity:ManipulateBoneAngles wants it: relative to the
      model standing in its normal idle, so the pose plays back on a live player or NPC.
      A ghost beside the ragdoll plays the keyframes back as a loop, to the beat; copy the
      result to the clipboard, or save it to garrysmod/data/pose_recorder/.

      The tool: Tools, Poser, Pose Recorder (left click: pick a ragdoll; right click: snap
      a keyframe; reload: play the loop or stop). Everything is in its panel; the console
      commands (pose_recorder_*) do the same.

      Smoothing: each keyframe has its own length (beats) and easing into the next (smooth,
      snappy, bouncy, linear); the loop wraps round to the first keyframe or stops on the
      last; mirror swaps left and right. Playing it on yourself or an NPC, seen by everyone,
      and packs of animations in other addons: lua/pose_recorder/play.lua.
]]

AddCSLuaFile()
AddCSLuaFile("pose_recorder/core.lua")
AddCSLuaFile("pose_recorder/play.lua")
include("pose_recorder/core.lua")

local PR = PoseRecorder
PR.Version = "2.0"
include("pose_recorder/play.lua")

if SERVER then
    util.AddNetworkString("pose_recorder_select")

    -- The ragdoll someone's working on: its physics bones (the ones you can pose), by name.
    function PR.Select(ply, ent)
        if not IsValid(ply) or not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return false end
        local names = {}
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local bone = ent:TranslatePhysBoneToBone(i)
            local name = bone and bone >= 0 and ent:GetBoneName(bone)
            if name and name ~= "__INVALIDBONE__" then names[#names + 1] = name end
        end
        net.Start("pose_recorder_select")
        net.WriteEntity(ent)
        net.WriteUInt(#names, 8)
        for _, n in ipairs(names) do net.WriteString(n) end
        net.Send(ply)
        return true
    end

    -- A mannequin: your own model as a ragdoll, standing in front of you, every limb frozen
    -- where it is, ready to pose with the physgun (right click to freeze a limb again).
    concommand.Add("pose_recorder_mannequin", function(ply)
        if not IsValid(ply) then return end
        local model = ply:GetModel()
        if hook.Run("PlayerSpawnRagdoll", ply, model) == false then return end
        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + Angle(0, ply:EyeAngles().y, 0):Forward() * 110, filter = ply })
        local spot = tr.HitPos - Angle(0, ply:EyeAngles().y, 0):Forward() * 20
        local down = util.TraceLine({ start = spot + Vector(0, 0, 40), endpos = spot - Vector(0, 0, 200), filter = ply })
        local rag = ents.Create("prop_ragdoll")
        if not IsValid(rag) then return end
        rag:SetModel(model)
        rag:SetPos((down.Hit and down.HitPos or spot) + Vector(0, 0, 2))
        rag:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        rag:Spawn()
        rag:Activate()
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local ph = rag:GetPhysicsObjectNum(i)
            if IsValid(ph) then ph:EnableMotion(false) ph:Wake() end
        end
        if ply.AddCleanup then ply:AddCleanup("ragdolls", rag) end
        undo.Create("Mannequin")
        undo.AddEntity(rag)
        undo.SetPlayer(ply)
        undo.Finish()
        hook.Run("PlayerSpawnedRagdoll", ply, model, rag)
        PR.Select(ply, rag)
    end)
    return
end

------------------------------------------------------------------------
-- Your screen: the snapshots, the recording, the ghost, the files
------------------------------------------------------------------------

local cvName  = CreateClientConVar("pose_recorder_name", "mydance", true, false, "Pose Recorder: what the recording is called (its file name)")
local cvBPM   = CreateClientConVar("pose_recorder_bpm", "120", true, false, "Pose Recorder: beats per minute, for the loop")
local cvBeats = CreateClientConVar("pose_recorder_beats", "1", true, false, "Pose Recorder: how many beats each new keyframe lasts")
local cvRef   = CreateClientConVar("pose_recorder_ref", "idle_all_01", true, false, "Pose Recorder: the pose the angles are relative to (a sequence name, or reference)")
local cvRate  = CreateClientConVar("pose_recorder_rate", "10", true, false, "Pose Recorder: samples a second while recording")
local cvEase  = CreateClientConVar("pose_recorder_ease", "smooth", true, false, "Pose Recorder: how each new keyframe eases into the next: smooth, snappy, bouncy or linear")
local cvWrap  = CreateClientConVar("pose_recorder_wrap", "1", true, false, "Pose Recorder: 1 the last keyframe eases back into the first, 0 the loop stops on the last")

PR.sel = PR.sel or nil      -- { ent, phys = { [name] = true } }
PR.frames = PR.frames or {} -- the keyframes, or the recording's samples
PR.mode = PR.mode or "keys" -- keys, or rec
PR.face = PR.face or 0

local function Say(msg)
    chat.AddText(Color(120, 200, 255), "[Pose Recorder] ", Color(235, 235, 235), msg)
    surface.PlaySound("buttons/button15.wav")
end
PR.Say = Say

-- (the tool's panel redraws its keyframe list when they change)
local function Changed() hook.Run("PoseRecorderChanged") end
local function Ease() return PR.Ease[cvEase:GetString()] and cvEase:GetString() or "smooth" end

net.Receive("pose_recorder_select", function()
    local ent = net.ReadEntity()
    local phys = {}
    for _ = 1, net.ReadUInt(8) do phys[net.ReadString()] = true end
    PR.sel = { ent = ent, phys = phys }
    if IsValid(ent) then Say("Picked " .. string.GetFileFromFilename(ent:GetModel() or "a ragdoll") .. ". Pose it, then snap a keyframe (right click).") end
end)

-- The reference: the same model standing in that pose, measured once (per model and pose).
local refs = {}
local function Reference(model, seqName)
    local key = model .. "|" .. seqName
    if refs[key] then return refs[key] end
    local cm = ClientsideModel(model, RENDERGROUP_OPAQUE)
    if not IsValid(cm) then return nil end
    cm:SetNoDraw(true)
    cm:SetPos(Vector(0, 0, 0))
    cm:SetAngles(Angle(0, 0, 0))
    local seq = seqName == "reference" and 0 or cm:LookupSequence(seqName)
    if not seq or seq < 0 then
        for _, n in ipairs({ "idle_all_01", "idle_subtle", "idle_unarmed", "idle", "Idle01" }) do
            seq = cm:LookupSequence(n)
            if seq and seq >= 0 then break end
        end
    end
    if (not seq or seq < 0) and ACT_IDLE then seq = cm:SelectWeightedSequence(ACT_IDLE) end
    if not seq or seq < 0 then seq = 0 end
    cm:ResetSequence(seq)
    cm:SetCycle(0)
    cm:SetPlaybackRate(0)
    cm:InvalidateBoneCache()
    cm:SetupBones()
    local rel = {}
    for i = 0, cm:GetBoneCount() - 1 do
        local m = cm:GetBoneMatrix(i)
        if m then local a = m:GetAngles() rel[i + 1] = PR.FromAngles(a.p, a.y, a.r) end
    end
    cm:Remove()
    refs[key] = { rel = rel, seq = seq }
    return refs[key]
end
PR.Reference = Reference

-- The ragdoll as it's posed right now: an angle for every bone you can pose.
function PR.Snapshot()
    local sel = PR.sel
    local ent = sel and sel.ent
    if not IsValid(ent) then return nil, "Pick a ragdoll first (left click on one), or spawn a mannequin." end
    local ref = Reference(ent:GetModel(), cvRef:GetString())
    if not ref then return nil, "Couldn't load the model to measure it." end
    ent:InvalidateBoneCache()
    ent:SetupBones()
    local bones, posed, record = {}, {}, {}
    for i = 0, ent:GetBoneCount() - 1 do
        local parent = ent:GetBoneParent(i)
        local name = ent:GetBoneName(i)
        bones[i + 1] = { name = name, parent = (parent and parent >= 0) and (parent + 1) or nil }
        local m = ent:GetBoneMatrix(i)
        if m then local a = m:GetAngles() posed[i + 1] = PR.FromAngles(a.p, a.y, a.r) end
        record[i + 1] = sel.phys[name] or false
    end
    local out, face = PR.Delta(bones, ref.rel, posed, record)
    PR.face = face -- (which way the pose faces: the ghost stands the same way)
    return out, face
end

function PR.Snap()
    if PR.mode == "rec" and #PR.frames > 0 then Say("That's a recording: clear it first to make keyframes.") return end
    local bones, err = PR.Snapshot()
    if not bones then Say(err) return end
    PR.mode = "keys"
    PR.frames[#PR.frames + 1] = { beats = math.max(0.25, cvBeats:GetFloat()), ease = Ease(), bones = bones }
    Say("Keyframe " .. #PR.frames .. " (" .. cvBeats:GetFloat() .. " beat" .. (cvBeats:GetFloat() == 1 and "" or "s") .. ", " .. Ease() .. ").")
    Changed()
end

function PR.ToggleRecord()
    if PR.recording then
        PR.recording = nil
        Say("Stopped: " .. #PR.frames .. " samples over " .. string.format("%.1f", PR.frames[#PR.frames] and PR.frames[#PR.frames].t or 0) .. " seconds.")
        Changed()
        return
    end
    if not (PR.sel and IsValid(PR.sel.ent)) then Say("Pick a ragdoll first (left click on one), or spawn a mannequin.") return end
    PR.frames, PR.mode = {}, "rec"
    PR.recording = { t0 = CurTime(), next = 0 }
    Say("Recording. Move it with the physgun; Record again to stop.")
end

function PR.Data()
    local ent = PR.sel and PR.sel.ent
    return {
        tool = "Pose Recorder " .. PR.Version,
        format = PR.FORMAT,
        name = cvName:GetString(),
        model = IsValid(ent) and ent:GetModel() or PR.model,
        ref = cvRef:GetString(),
        bpm = cvBPM:GetFloat(),
        mode = PR.mode,
        wrap = cvWrap:GetBool(),
        note = "Angles are Entity:ManipulateBoneAngles values (pitch, yaw, roll), relative to the model standing in its ref pose.",
        frames = PR.frames,
    }
end

-- The ghost: the same model beside the ragdoll, in its reference pose, playing the loop.
local ghost
local function GhostGone() if IsValid(ghost) then ghost:Remove() end ghost = nil end
function PR.TogglePreview()
    if PR.previewing then PR.previewing = nil GhostGone() Say("Preview off.") return end
    if #PR.frames == 0 then Say("Nothing to play yet: snap a keyframe or two first.") return end
    local ent = PR.sel and PR.sel.ent
    local model = IsValid(ent) and ent:GetModel() or PR.model
    if not model then Say("Pick a ragdoll first.") return end
    local ref = Reference(model, cvRef:GetString())
    GhostGone()
    ghost = ClientsideModel(model, RENDERGROUP_OPAQUE)
    if not IsValid(ghost) then return end
    ghost.RenderOverride = function(self)
        render.SetColorModulation(0.6, 0.85, 1)
        self:DrawModel()
        render.SetColorModulation(1, 1, 1)
    end
    ghost.lcSeq = ref and ref.seq or 0
    ghost:ResetSequence(ghost.lcSeq)
    PR.previewing = { t0 = CurTime(), model = model }
    Say("Playing the loop (beside the ragdoll, in blue). Preview again to stop.")
end

local BoneId = PR.BoneId

hook.Add("Think", "PoseRecorder", function()
    local now = CurTime()
    -- recording: a sample every so often
    local rec = PR.recording
    if rec and now >= rec.next then
        rec.next = now + 1 / math.Clamp(cvRate:GetFloat(), 1, 30)
        local bones = PR.Snapshot()
        if bones then PR.frames[#PR.frames + 1] = { t = math.floor((now - rec.t0) * 1000 + 0.5) / 1000, bones = bones }
        else PR.recording = nil end
    end
    -- the ghost, playing the loop
    if PR.previewing and IsValid(ghost) then
        local ent = PR.sel and PR.sel.ent
        local base = IsValid(ent) and ent:GetPos() or LocalPlayer():GetPos()
        local face = PR.face or 0
        local right = Angle(0, face, 0):Right()
        local spot = base + right * 70
        local tr = util.TraceLine({ start = spot + Vector(0, 0, 60), endpos = spot - Vector(0, 0, 200), filter = { LocalPlayer(), ent } })
        ghost:SetPos(tr.Hit and tr.HitPos or spot)
        ghost:SetAngles(Angle(0, face, 0))
        ghost:SetCycle(0) -- (held in the reference pose itself, so what you see is exactly what was measured)
        local pose = PR.mode == "rec" and PR.SampleRecording(PR.frames, now - PR.previewing.t0)
            or PR.Sample(PR.frames, (now - PR.previewing.t0) * cvBPM:GetFloat() / 60, cvWrap:GetBool())
        for name, a in pairs(pose) do
            local id = BoneId(ghost, name)
            if id then ghost:ManipulateBoneAngles(id, Angle(a[1], a[2], a[3])) end
        end
    elseif ghost and not PR.previewing then
        GhostGone()
    end
end)

function PR.Copy()
    if #PR.frames == 0 then Say("Nothing to copy yet.") return end
    SetClipboardText(util.TableToJSON(PR.Data(), true))
    Say("Copied " .. #PR.frames .. " " .. (PR.mode == "rec" and "samples" or "keyframes") .. " to the clipboard.")
end

local function FileName() return "pose_recorder/" .. string.gsub(string.lower(cvName:GetString()), "[^%w_%-]", "_") .. ".json" end
function PR.Save()
    if #PR.frames == 0 then Say("Nothing to save yet.") return end
    file.CreateDir("pose_recorder")
    file.Write(FileName(), util.TableToJSON(PR.Data(), true))
    Say("Saved to garrysmod/data/" .. FileName())
end
-- (any version: a file from the first Pose Recorder loads with smooth easing, wrapping round)
function PR.Load()
    local raw = file.Read(FileName(), "DATA")
    if not raw then Say("No " .. FileName() .. " in your data folder.") return end
    local t, err = PR.Decode(raw)
    if not t then Say("Couldn't load " .. FileName() .. ": " .. tostring(err) .. ".") return end
    PR.frames, PR.mode, PR.model = t.frames, t.mode, t.model
    RunConsoleCommand("pose_recorder_bpm", tostring(t.bpm))
    RunConsoleCommand("pose_recorder_wrap", t.wrap and "1" or "0")
    Say("Loaded " .. #PR.frames .. " " .. (PR.mode == "rec" and "samples" or "keyframes") .. " from " .. FileName())
    Changed()
end

-- Which keyframes a change is for: "all", a keyframe's number, or (with neither) the ones
-- picked in the panel's list, or every one when none are picked.
PR.picked = PR.picked or {}
local function Targets(which)
    local out = {}
    if which == "all" then
        for i = 1, #PR.frames do out[#out + 1] = i end
    elseif tonumber(which) then
        local i = math.floor(tonumber(which))
        if PR.frames[i] then out[1] = i end
    else
        for i in pairs(PR.picked) do if PR.frames[i] then out[#out + 1] = i end end
        if #out == 0 then for i = 1, #PR.frames do out[#out + 1] = i end end
    end
    table.sort(out)
    return out
end
local function Which(list) return #list == #PR.frames and "every keyframe" or ("keyframe" .. (#list == 1 and " " or "s ") .. table.concat(list, ", ")) end

function PR.SetBeats(beats, which)
    beats = tonumber(beats)
    if PR.mode == "rec" then Say("A recording has real times, not beats: make keyframes to set their lengths.") return end
    if not beats then Say("How many beats?") return end
    beats = math.Clamp(beats, 0.25, 16)
    local list = Targets(which)
    if #list == 0 then Say("No keyframes yet.") return end
    for _, i in ipairs(list) do PR.frames[i].beats = beats end
    Say(Which(list) .. ": " .. beats .. " beat" .. (beats == 1 and "" or "s") .. " each.")
    Changed()
end

function PR.SetEase(ease, which)
    if PR.mode == "rec" then Say("A recording plays straight from sample to sample: make keyframes to ease them.") return end
    if not PR.Ease[ease or ""] then Say("Easing is smooth, snappy, bouncy or linear.") return end
    local list = Targets(which)
    if #list == 0 then Say("No keyframes yet.") return end
    for _, i in ipairs(list) do PR.frames[i].ease = ease end
    Say(Which(list) .. ": " .. ease .. ".")
    Changed()
end

-- Mirror: left and right swapped on the picked keyframes (or all of them); or a mirrored
-- copy of the whole loop added on the end (a wave with the right hand, then the left).
function PR.Mirror(which)
    local list = Targets(which)
    if #list == 0 then Say("Nothing to mirror yet.") return end
    for _, i in ipairs(list) do PR.frames[i].bones = PR.MirrorPose(PR.frames[i].bones) end
    Say("Mirrored " .. Which(list) .. ": left and right swapped.")
    Changed()
end

function PR.MirrorAdd()
    local n = #PR.frames
    if n == 0 then Say("Nothing to mirror yet.") return end
    local copy = PR.MirrorFrames(PR.frames)
    local shift = PR.mode == "rec" and (PR.frames[n].t or 0) + 1 / math.Clamp(cvRate:GetFloat(), 1, 30) or 0
    for _, f in ipairs(copy) do
        if f.t then f.t = f.t + shift end
        PR.frames[#PR.frames + 1] = f
    end
    Say("Added a mirrored copy: " .. #PR.frames .. " " .. (PR.mode == "rec" and "samples" or "keyframes") .. " now.")
    Changed()
end

-- What you're making, on you, seen by everyone (sent to the server; it needn't be saved).
function PR.PlayMine()
    if #PR.frames == 0 then Say("Nothing to play yet: snap a keyframe or two first.") return end
    PR.RequestPlay(LocalPlayer(), cvName:GetString(), nil, nil, PR.Data())
end

concommand.Add("pose_recorder_snap", PR.Snap)
concommand.Add("pose_recorder_record", PR.ToggleRecord)
concommand.Add("pose_recorder_preview", PR.TogglePreview)
concommand.Add("pose_recorder_copy", PR.Copy)
concommand.Add("pose_recorder_save", PR.Save)
concommand.Add("pose_recorder_load", PR.Load)
concommand.Add("pose_recorder_mirror", function(_, _, args) PR.Mirror(args[1]) end)
concommand.Add("pose_recorder_mirror_add", PR.MirrorAdd)
concommand.Add("pose_recorder_key_beats", function(_, _, args) PR.SetBeats(args[1], args[2]) end)
concommand.Add("pose_recorder_key_ease", function(_, _, args) PR.SetEase(args[1], args[2]) end)
concommand.Add("pose_recorder_play_mine", PR.PlayMine)
concommand.Add("pose_recorder_undo", function()
    if #PR.frames == 0 then return end
    table.remove(PR.frames)
    PR.picked = {}
    Say(#PR.frames .. " left.")
    Changed()
end)
concommand.Add("pose_recorder_clear", function()
    PR.frames, PR.mode, PR.recording, PR.picked = {}, "keys", nil, {}
    Say("Cleared.")
    Changed()
end)

-- What it's doing, while the tool's in your hand.
hook.Add("HUDPaint", "PoseRecorder", function()
    local me = LocalPlayer()
    local w = IsValid(me) and me:GetActiveWeapon()
    if not (IsValid(w) and w:GetClass() == "gmod_tool" and w.GetMode and w:GetMode() == "pose_recorder") and not PR.recording then return end
    local ent = PR.sel and PR.sel.ent
    local lines = {
        "Pose Recorder: " .. (IsValid(ent) and string.GetFileFromFilename(ent:GetModel() or "") or "no ragdoll picked"),
        #PR.frames .. " " .. (PR.mode == "rec" and "samples" or "keyframes") .. "   " .. cvBPM:GetInt() .. " BPM   relative to " .. cvRef:GetString(),
    }
    if PR.recording then lines[#lines + 1] = (math.floor(CurTime() * 2) % 2 == 0 and "o " or "  ") .. "RECORDING" end
    if PR.previewing then lines[#lines + 1] = "playing the loop" end
    for i, l in ipairs(lines) do
        draw.SimpleTextOutlined(l, "DermaDefaultBold", 24, ScrH() * 0.3 + (i - 1) * 18, i == 3 and PR.recording and Color(255, 80, 80) or Color(235, 235, 235),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200))
    end
end)
