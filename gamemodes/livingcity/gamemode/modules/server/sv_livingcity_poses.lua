--[[
    Living City: the poses the owner has set by hand, kept and sent (server)

      sh_livingcity_poses.lua lists every hand-made pose with its built-in
      numbers. What the owner sets with the Miscount Poser is checked here
      (a superadmin, a pose that exists, its own bones and props, numbers
      within reach), kept in data/livingcity/poses.json, and sent to every
      player's game when they join and whenever one changes, so everybody sees
      the same cuffed arms and the same broom in the same claws.

      LC.PoseSet(ply, id, bones, props)   set one (the Pose Recorder's mannequin, measured)
      LC.PoseReset(ply, id)               back to the built-in
      LC.PoseMannequin(ply, id, pos)      the Poser's left click: the mannequin, through the Pose Recorder
]]

LC = LC or {}

util.AddNetworkString("lc_poses")      -- server: everything that is set, to one player or everyone
util.AddNetworkString("lc_pose_reset") -- client: this pose back to the built-in (the Poser's button)

local FILE = "livingcity/poses.json"
LC.PoseFile = FILE -- (core: CORE.md)

function LC.PoseLoad()
    local t = LC.SafeReadJSON(FILE)
    return LC.PoseOverridesSet(istable(t) and t.poses or {})
end

function LC.PoseSaveNow()
    return LC.SafeWrite(FILE, util.TableToJSON({ poses = LC.PoseOverrides }, true))
end
local function Save()
    timer.Create("LivingCityPosesSave", 1, 1, function() LC.PoseSaveNow() end)
end

local function Send(to)
    net.Start("lc_poses")
    net.WriteTable(LC.PoseOverrides)
    if to then net.Send(to) else net.Broadcast() end
end
LC.PoseSend = Send

-- Who may change a pose: whoever may edit the layout (superadmins; the server's own console).
function LC.PoseMay(ply)
    return LC.CanEdit(ply) == true
end

local function Put(id, o)
    local all = {}
    for k, v in pairs(LC.PoseOverrides) do all[k] = v end
    all[id] = o
    LC.PoseOverridesSet(all)
    Save()
    Send()
end

-- bones: { [name] = { p, y, r } }, props: { [name] = { bone, pos = { x, y, z }, ang = { p, y, r } } }.
-- The bones given are the pose's bones from now on (nil: left as they are); a held thing that is
-- given and passes replaces its hold, one not given or turned down keeps the hold it had (Reset
-- is what takes a hold away). Returns true and what is kept, or false and why.
function LC.PoseSet(ply, id, bones, props)
    if not LC.PoseMay(ply) then return false, "Only superadmins can change a pose." end
    local clean, why = LC.PoseClean(id, bones, props)
    if not clean then return false, why end
    local was = LC.PoseOverrides[id]
    if bones == nil and was and was.bones then clean.bones = was.bones end
    for name, o in pairs(was and was.props or {}) do
        if clean.props[name] == nil then clean.props[name] = o end
    end
    Put(id, (next(clean.bones) ~= nil or next(clean.props) ~= nil) and clean or nil)
    return true, clean
end

function LC.PoseReset(ply, id)
    if not LC.PoseMay(ply) then return false, "Only superadmins can change a pose." end
    if not (isstring(id) and LC.Poses[id]) then return false, "no such pose" end
    Put(id, nil)
    return true
end

net.Receive("lc_pose_reset", function(_, ply)
    if not IsValid(ply) then return end
    LC.PoseReset(ply, net.ReadString())
end)

hook.Add("PlayerInitialSpawn", "LivingCityPoses", function(ply)
    if next(LC.PoseOverrides) == nil then return end
    timer.Simple(3, function() if IsValid(ply) then Send(ply) end end)
end)

------------------------------------------------------------------------
-- The mannequin (the Pose Recorder addon stands and measures it)
------------------------------------------------------------------------

function LC.PoseRecorderHere()
    return PoseRecorder ~= nil and PoseRecorder.AddTarget ~= nil and PoseRecorder.TargetMannequin ~= nil
end

-- The Poser's left click: the pose's mannequin at pos, facing the player. Clicking again moves
-- it (one each). Returns the ragdoll, or nil and why.
function LC.PoseMannequin(ply, id, pos)
    if not LC.PoseMay(ply) then return nil, "Only superadmins can use the Miscount Poser." end
    if not LC.Poses[id] then return nil, "Pick a pose in the tool's list first." end
    if not LC.PoseRecorderHere() then return nil, "The Pose Recorder addon isn't installed." end
    LC.PoseBridge()
    local yaw = IsValid(ply) and (ply:EyeAngles().y + 180) or 0
    local rag, why = PoseRecorder.TargetMannequin(ply, LC.PoseTargetId(id), pos, yaw)
    if not IsValid(rag) then return nil, why end
    -- (never part of the map: not saved with the layout, not kept by the game's own persistence)
    local m = PoseRecorder.TargetOf(ply)
    for _, e in pairs(m and m.props or {}) do e.lcPoseStandIn = true end
    rag.lcPoseStandIn = true
    return rag
end

function LC.PoseMannequinOf(ply)
    if not LC.PoseRecorderHere() then return nil end
    local m = PoseRecorder.TargetOf(ply)
    local id = m and LC.PoseFromTargetId(m.id)
    if not id then return nil end
    return m.ent, id, m
end

function LC.PoseMannequinRemove(ply)
    if not LC.PoseMannequinOf(ply) then return false end
    return PoseRecorder.TargetRemove(ply)
end

LC.PoseLoad()
