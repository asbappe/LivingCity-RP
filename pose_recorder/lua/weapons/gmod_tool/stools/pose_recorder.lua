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
    language.Add("tool.pose_recorder.desc", "Record a ragdoll's pose as bone angles for ManipulateBoneAngles, and play it back as a loop")
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

function TOOL.BuildCPanel(cp)
    cp:Help("Pose a ragdoll with the physgun (right click freezes a limb), then snap it as a keyframe. "
        .. "Each bone's angle is worked out the way Entity:ManipulateBoneAngles wants it, relative to the model "
        .. "standing in its normal idle, so the pose plays back on a live player or NPC.")
    cp:Button("Spawn a mannequin (your model, frozen standing)", "pose_recorder_mannequin")
    cp:Help("Or left click any ragdoll to record that one.")
    cp:TextEntry("Name", "pose_recorder_name")
    cp:NumSlider("Beats per minute", "pose_recorder_bpm", 40, 220, 0)
    cp:NumSlider("Beats per new keyframe", "pose_recorder_beats", 0.25, 8, 2)
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
    cp:Help("The result (JSON: each keyframe's beats, and each bone's pitch, yaw and roll):")
    cp:Button("Copy to the clipboard", "pose_recorder_copy")
    cp:Button("Save to data/pose_recorder/<name>.json", "pose_recorder_save")
    cp:Button("Load data/pose_recorder/<name>.json", "pose_recorder_load")
end
