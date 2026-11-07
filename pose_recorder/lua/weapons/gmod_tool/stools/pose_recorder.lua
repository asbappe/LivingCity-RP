--[[
    Pose Recorder: the tool (Tools, Poser, Pose Recorder). The work is done in
    lua/autorun/pose_recorder.lua; this is the toolgun's clicks and its panel.
]]

TOOL.Category = "Poser"
TOOL.Name = "#tool.pose_recorder.name"
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.pose_recorder.name", "Pose Recorder")
    language.Add("tool.pose_recorder.desc", "Record a ragdoll's pose as bone angles, smooth it, and play it on yourself or an NPC for everyone to see")
    language.Add("tool.pose_recorder.left", "Pick a ragdoll to record")
    language.Add("tool.pose_recorder.right", "Snap a keyframe of how it's posed now")
    language.Add("tool.pose_recorder.reload", "Play the loop beside it, or stop")
end

function TOOL:LeftClick(tr)
    local e = tr.Entity
    if not IsValid(e) or e:GetClass() ~= "prop_ragdoll" then return false end
    if CLIENT then return true end
    return PoseRecorder.Select(self:GetOwner(), e)
end

-- (the snapshot is taken on your own screen, where the bones are)
function TOOL:RightClick()
    if SERVER then self:GetOwner():ConCommand("pose_recorder_snap") end
    return false
end

function TOOL:Reload()
    if SERVER then self:GetOwner():ConCommand("pose_recorder_preview") end
    return false
end

-- A list in the panel (a DListView), kept up to date by a hook while the panel exists.
local function List(cp, tall, columns, multi)
    local lv = vgui.Create("DListView")
    lv:SetTall(tall)
    lv:SetMultiSelect(multi)
    for _, c in ipairs(columns) do lv:AddColumn(c) end
    cp:AddItem(lv)
    return lv
end

local function Picked(lv)
    local out = {}
    for _, line in ipairs(lv:GetSelected() or {}) do if line.prIndex then out[line.prIndex] = true end end
    return out
end

function TOOL.BuildCPanel(cp)
    local PR = PoseRecorder
    cp:Help("Pose a ragdoll with the physgun (right click freezes a limb), then snap it as a keyframe. "
        .. "Each bone's angle is worked out the way Entity:ManipulateBoneAngles wants it, relative to the model "
        .. "standing in its normal idle, so the pose plays back on a live player or NPC.")
    cp:Button("Spawn a mannequin (your model, frozen standing)", "pose_recorder_mannequin")
    cp:Help("Or left click any ragdoll to record that one.")
    cp:TextEntry("Name", "pose_recorder_name")
    cp:NumSlider("Beats per minute", "pose_recorder_bpm", 40, 220, 0)
    cp:NumSlider("Beats per new keyframe", "pose_recorder_beats", 0.25, 8, 2)
    local ease = cp:ComboBox("Easing for new keyframes", "pose_recorder_ease")
    ease:AddChoice("Smooth (eases out and in)", "smooth")
    ease:AddChoice("Snappy (quick, then settles)", "snappy")
    ease:AddChoice("Bouncy (swings past, settles back)", "bouncy")
    ease:AddChoice("Linear (an even speed)", "linear")
    local ref = cp:ComboBox("Relative to", "pose_recorder_ref")
    ref:AddChoice("Standing idle (players: idle_all_01)", "idle_all_01")
    ref:AddChoice("NPC idle (idle_unarmed)", "idle_unarmed")
    ref:AddChoice("The model's reference pose", "reference")
    cp:Help("Keyframes: pose, snap, pose, snap. The loop eases from one to the next, each held for its beats.")
    cp:Button("Snap a keyframe (right click)", "pose_recorder_snap")
    cp:Button("Undo the last keyframe", "pose_recorder_undo")
    cp:Help("Or record it moving, sampled as you go:")
    cp:NumSlider("Samples a second", "pose_recorder_rate", 1, 30, 0)
    cp:Button("Record / stop", "pose_recorder_record")
    cp:Button("Play the loop beside it / stop (reload)", "pose_recorder_preview")
    cp:Button("Clear", "pose_recorder_clear")

    -- Smoothing: the keyframes, each one's length and easing; wrap or stop; mirror
    cp:Help("Smoothing. Pick keyframes in the list (none picked: all of them), then change them:")
    local keys = List(cp, 150, { "#", "Length", "Easing into the next" }, true)
    local function FillKeys()
        if not IsValid(keys) then return end
        local was = PR.picked or {}
        keys:Clear()
        for i, f in ipairs(PR.frames or {}) do
            local line = keys:AddLine(i, PR.mode == "rec" and string.format("%.2f s", f.t or 0) or ((f.beats or 1) .. " beats"),
                PR.mode == "rec" and "straight (a recording)" or (f.ease or "smooth"))
            if line then
                line.prIndex = i
                if was[i] then keys:SelectItem(line) end
            end
        end
    end
    keys.OnRowSelected = function() PR.picked = Picked(keys) end
    hook.Add("PoseRecorderChanged", keys, FillKeys)
    FillKeys()
    local function ForPicked(fn) return function() PR.picked = Picked(keys) fn() end end
    local b = cp:Button("Give them the beats per new keyframe (above)")
    b.DoClick = ForPicked(function() PR.SetBeats(GetConVar("pose_recorder_beats"):GetFloat()) end)
    b = cp:Button("Give them the easing for new keyframes (above)")
    b.DoClick = ForPicked(function() PR.SetEase(GetConVar("pose_recorder_ease"):GetString()) end)
    b = cp:Button("Mirror them (left and right swapped)")
    b.DoClick = ForPicked(function() PR.Mirror() end)
    cp:Button("Add a mirrored copy of the whole loop on the end", "pose_recorder_mirror_add")
    cp:CheckBox("Wrap: the last keyframe eases back into the first (off: it stops on the last)", "pose_recorder_wrap")

    -- Playing it: on you or an NPC, and everyone sees it
    cp:Help("Play it on yourself, seen by everyone (it doesn't need saving first):")
    local mode = cp:ComboBox("How it plays", "pose_recorder_playmode")
    mode:AddChoice("Loop (round and round)", "loop")
    mode:AddChoice("Once (then back to normal)", "once")
    mode:AddChoice("Hold (stays in the last pose)", "hold")
    cp:NumSlider("Speed", "pose_recorder_speed", 0.1, 4, 2)
    cp:Button("Play what I'm making on me", "pose_recorder_play_mine")
    cp:Help("Or one of your saved animations, or the server's:")
    local lib = List(cp, 130, { "Animation" }, false)
    local function FillLib()
        if not IsValid(lib) then return end
        lib:Clear()
        for _, n in ipairs(PR.Choices and PR.Choices() or {}) do
            local line = lib:AddLine(n)
            if line then line.prName = n end
        end
    end
    hook.Add("PoseRecorderLibraryChanged", lib, FillLib)
    hook.Add("PoseRecorderChanged", lib, FillLib)
    FillLib()
    b = cp:Button("Play the picked one on me")
    b.DoClick = function()
        local line = (lib:GetSelected() or {})[1]
        if not line or not line.prName then PR.Say("Pick an animation in the list first.") return end
        PR.RequestPlay(LocalPlayer(), line.prName)
    end
    cp:Button("Stop mine", "pose_stop")
    b = cp:Button("Refresh the list")
    b.DoClick = FillLib
    cp:Help("On an NPC: hold the context menu key (C), right click the NPC, Play animation. "
        .. "Console extras: pose_play <name> [loop|once|hold] [speed], pose_stop.")

    -- Sharing
    cp:Help("The result (JSON: each keyframe's beats and easing, and each bone's pitch, yaw and roll):")
    cp:Button("Copy to the clipboard", "pose_recorder_copy")
    cp:Button("Save to data/pose_recorder/<name>.json", "pose_recorder_save")
    cp:Button("Load data/pose_recorder/<name>.json", "pose_recorder_load")
    cp:Help("Sharing: send someone your garrysmod/data/pose_recorder/<name>.json to put in theirs. "
        .. "A pack: put the files in your own addon's data_static/pose_recorder/ folder; every server and player "
        .. "with that addon gets them in this list and the context menu. Lua: PoseRecorder.Play(ent, \"<name>\").")
    cp:Help("These are bone turns on top of the model's own idle, not compiled animations: they can't change walking or running.")
end
