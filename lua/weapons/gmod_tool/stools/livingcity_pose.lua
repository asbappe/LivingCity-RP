--[[
    Miscount Poser (toolgun)
    Q menu > Tools > Miscount > Miscount Poser (below the Miscount Editor)

    The owner, 15 November: "I need a way to spawn a simulated NPC that is
    cuffed (actually, any/all NPC animations that are custom in this gamemode,
    including vortigaunt sweep animation/pose, etc) ... please add a new
    Miscount category tool via the tool menu, put it below the editor tool".
    And then: "it might be easier for me to adjust the limbs with the physgun
    using the pose recorder tool than using sliders."

    Left click   the picked pose's mannequin where you aim: a ragdoll of the
                 right model, already in the pose the game uses now, what it
                 holds (a broom) in place, every limb frozen. Again: it is
                 stood there instead.
    Physgun      move its limbs, and what it holds. Whatever you let go of
                 stays where it is.
    Right click  on the mannequin: use this pose. It is measured, kept on the
                 server (data/livingcity/poses.json) and every real one in the
                 game changes at once.
    Reload       take the mannequin away

    The panel lists the gamemode's hand-made poses (sh_livingcity_poses.lua),
    with Reset this pose (back to the built-in numbers) and Copy the numbers
    (as text, for a coder to make the new built-in). The mannequin and the
    measuring are the Pose Recorder addon's (its "targets"); without it the
    panel says so and the poses play as they always did. Superadmins only.
]]

-- Only in the Living City gamemode (elsewhere it isn't listed)
if engine.ActiveGamemode() ~= "livingcity" then TOOL.AddToMenu = false return end

TOOL.Category = "Miscount"
TOOL.Name = "#tool.livingcity_pose.name"
TOOL.ClientConVar = { id = "cuffed" }
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.livingcity_pose.name", "Miscount Poser")
    language.Add("tool.livingcity_pose.desc", "Set Miscount's hand-made poses by hand, on a mannequin")
    language.Add("tool.livingcity_pose.left", "Stand the pose's mannequin here")
    language.Add("tool.livingcity_pose.right", "Use this pose (aim at the mannequin)")
    language.Add("tool.livingcity_pose.reload", "Take the mannequin away")
end

local function Tell(ply, msg)
    if not (IsValid(ply) and msg) then return end
    if LC and LC.Notice then LC.Notice(ply, "info", "Miscount Poser", msg) else ply:ChatPrint("[Miscount] " .. msg) end
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not (LC and LC.PoseMannequin) then return false end
    local rag, why = LC.PoseMannequin(ply, self:GetClientInfo("id"), trace.HitPos)
    if not IsValid(rag) then Tell(ply, why) return false end
    return true
end

-- (the pose is measured in your own game, where the bones are: the Pose Recorder's pose_recorder_take)
function TOOL:RightClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not (LC and LC.PoseMannequinOf) then return false end
    local rag, _, m = LC.PoseMannequinOf(ply)
    if not IsValid(rag) then Tell(ply, "Left click first, to stand the pose's mannequin.") return false end
    local e = trace.Entity
    local mine = e == rag
    for _, held in pairs(m.props or {}) do if e == held then mine = true end end
    if not mine then Tell(ply, "Aim at the mannequin.") return false end
    ply:ConCommand("pose_recorder_take")
    return true
end

function TOOL:Reload()
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not (LC and LC.PoseMannequinRemove) then return false end
    return LC.PoseMannequinRemove(ply) == true
end

if CLIENT then
    local ORANGE = Color(255, 150, 40)

    local function Picked()
        local cv = GetConVar("livingcity_pose_id")
        local id = cv and cv:GetString() or ""
        return LC.Poses and LC.Poses[id] and id or nil
    end
    TOOL.PickedPose = Picked

    -- Which pose is picked, and whether the owner has set it: one short line.
    function TOOL:DrawHUD()
        local id = Picked()
        if not id then return end
        draw.SimpleTextOutlined(LC.Poses[id].label .. (LC.PoseTuned(id) and ", set by hand" or ""), "DermaDefaultBold",
            ScrW() / 2, ScrH() * 0.62, ORANGE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end

    -- What a held thing may hang from, as the list shows it.
    local function BoneLabel(bone)
        if bone == "" then return "Its feet" end
        return (string.gsub(string.gsub(bone, "^ValveBiped%.Bip01_", ""), "^ValveBiped%.", ""))
    end
    TOOL.BoneLabel = BoneLabel

    function TOOL.BuildCPanel(panel)
        if not (PoseRecorder and PoseRecorder.AddTarget) then
            panel:Help("The Pose Recorder addon isn't installed.")
        end

        local poses = vgui.Create("DListView")
        poses:SetTall(190)
        poses:SetMultiSelect(false)
        poses:AddColumn("Pose")
        poses:AddColumn("Set by hand")
        panel:AddItem(poses)

        -- the one held thing a pose has (a broom), and the bone it is to be measured from
        local hang = panel:ComboBox("Held from")
        local function FillHang()
            if not IsValid(hang) then return end
            hang:Clear()
            local id = Picked()
            local def = id and LC.Poses[id]
            local name = def and next(def.props)
            if not name then return end
            local chosen = (LC.PoseHangChoice[id] and LC.PoseHangChoice[id][name]) or LC.PoseProp(id, name).bone
            for _, bone in ipairs(def.props[name].bones or { def.props[name].bone or "" }) do
                hang:AddChoice(BoneLabel(bone), bone, bone == chosen)
            end
        end
        hang.OnSelect = function(_, _, _, bone)
            local id = Picked()
            local name = id and next(LC.Poses[id].props)
            if name and isstring(bone) then LC.PoseHangChoice[id] = { [name] = bone } end
        end

        local function Fill()
            if not IsValid(poses) then return end
            local now = Picked()
            poses:Clear()
            for _, def in ipairs(LC.PoseList()) do
                local line = poses:AddLine(def.label, LC.PoseTuned(def.id) and "yes" or "")
                if line then
                    line.lcPose = def.id
                    if def.id == now and poses.SelectItem then poses:SelectItem(line) end
                end
            end
            FillHang()
        end
        poses.OnRowSelected = function(_, _, line)
            if not (line and line.lcPose) or line.lcPose == Picked() then return end
            RunConsoleCommand("livingcity_pose_id", line.lcPose)
            -- (the setting changes a moment later: the held thing's list is filled then)
            timer.Simple(0.1, FillHang)
        end
        hook.Add("LivingCityPosesChanged", poses, Fill)
        Fill()

        local b = panel:Button("Reset this pose")
        b.DoClick = function()
            local id = Picked()
            if not id then return end
            net.Start("lc_pose_reset")
            net.WriteString(id)
            net.SendToServer()
        end
        b = panel:Button("Copy the numbers")
        b.DoClick = function()
            local id = Picked()
            if not id then return end
            local text = LC.PoseText(id)
            SetClipboardText(text)
            print(text)
        end
    end
end
