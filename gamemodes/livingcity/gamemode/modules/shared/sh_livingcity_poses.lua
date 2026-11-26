--[[
    Living City: the hand-made poses, in one place (shared)

    The owner, 15 November: "I need a way to spawn a simulated NPC that is
    cuffed (actually, any/all NPC animations that are custom in this gamemode,
    including vortigaunt sweep animation/pose, etc) ... I should be able to
    select the limbs ... and tweak each limb". And of the street vortigaunt:
    "no the broom is not in its claws."

    Every pose the gamemode makes by turning bones in code is listed here with
    the numbers the code was written with: its bones (a turn for each, the way
    Entity:ManipulateBoneAngles wants it) and the things held in it (a broom:
    which bone it hangs from, and where from that bone). The code that poses
    people reads its numbers from here:

      LC.PoseBones(id)        { [bone name] = Angle }
      LC.PoseProp(id, name)   { model, bone, pos, ang, auto, tuned }

    With nothing tuned these give exactly the built-in numbers. The Miscount
    Poser (Q > Tools > Miscount; lua/weapons/gmod_tool/stools/livingcity_pose.lua)
    stands a mannequin in a pose for the owner to move by hand with the physgun,
    through the Pose Recorder addon when it is installed. What they set is kept
    on the server (sv_livingcity_poses.lua: data/livingcity/poses.json), sent to
    every player's game, and wins over the built-in numbers everywhere at once.
]]

LC = LC or {}

local B = "ValveBiped.Bip01_"
local CITIZEN, CITIZEN_REF = "models/humans/group01/male_07.mdl", "idle_subtle"
local BROOM_MODEL = "models/props_c17/pushbroom.mdl"

LC.Poses = LC.Poses or {}                 -- [id] = the pose as the code has it
LC.PoseOrder = LC.PoseOrder or {}         -- ids, in the order they are listed
-- What the owner has set: [id] = { bones = { [name] = { p, y, r } }, props = { [name] = { bone, pos = { x, y, z }, ang = { p, y, r } } } }
LC.PoseOverrides = LC.PoseOverrides or {}
-- angle: degrees either way; pos: units either way from the bone; same: a turn this close to the built-in is the
-- built-in; bones: how many of one pose may be turned
LC.PoseLimits = { angle = 180, pos = 120, same = 0.25, bones = 40 }

local version = 0
-- (goes up whenever anything is tuned or reset: code that keeps a pose looks again when it changes)
function LC.PoseVersion() return version end

--[[ One pose:
       id, label   its name in the code, and in the Poser's list
       model, ref  the mannequin it is shown on, and the sequence it sits on top of
       bones       { [bone name] = Angle }: the built-in turns
       free        other bones the owner may turn (built-in: not turned)
       any         a pattern instead: every bone whose name fits may be turned (a body whose
                   bones' names the code doesn't list)
       props       { [name] = { model, bone, pos, ang, bones, auto } }: bone "" hangs it from the
                   model's own feet; bones lists what it may hang from; auto means the code works
                   its place out itself until the owner sets one ]]
function LC.PoseAdd(def)
    if not LC.Poses[def.id] then LC.PoseOrder[#LC.PoseOrder + 1] = def.id end
    def.bones = def.bones or {}
    def.props = def.props or {}
    def.known = {}
    for name in pairs(def.bones) do def.known[name] = true end
    for _, name in ipairs(def.free or {}) do def.known[name] = true end
    LC.Poses[def.id] = def
    return def
end

-- Is this one of the pose's own bones?
local function Knows(def, name)
    if not isstring(name) then return false end
    if def.known[name] then return true end
    return def.any ~= nil and #name <= 64 and string.match(name, def.any) ~= nil
end

-- A pose whose built-in numbers are a setting's (lc_cuff_pose, lc_broom_hold): the code that owns
-- the setting says how to read it. bones: function() return { [name] = Angle } end
function LC.PoseBuilt(id, bones)
    local def = LC.Poses[id]
    if def then def.built = bones end
end
function LC.PosePropBuilt(id, name, fn)
    local p = LC.Poses[id] and LC.Poses[id].props[name]
    if p then p.built = fn end
end

function LC.PoseList()
    local out = {}
    for _, id in ipairs(LC.PoseOrder) do out[#out + 1] = LC.Poses[id] end
    return out
end

function LC.PoseTuned(id)
    local o = LC.PoseOverrides[id]
    return o ~= nil and LC.Poses[id] ~= nil and ((o.bones and next(o.bones) ~= nil) or (o.props and next(o.props) ~= nil)) or false
end

-- The pose's bones as they are to be used now: the built-in turns (or built, when the caller
-- has just worked them out from its own setting), with whatever the owner has set on top.
function LC.PoseBones(id, built)
    local def = LC.Poses[id]
    local out = {}
    if not built and def and def.built then built = def.built() end
    for name, a in pairs(built or (def and def.bones) or {}) do out[name] = Angle(a.p, a.y, a.r) end
    local o = def and LC.PoseOverrides[id]
    if o and o.bones then
        for name, a in pairs(o.bones) do
            if Knows(def, name) then out[name] = Angle(a[1], a[2], a[3]) end
        end
    end
    return out
end

-- Something held in a pose. bone "" is the model's own feet. auto: the code places it itself
-- (the street vortigaunt's broom, worked out from its hands and the floor). tuned: the owner set it.
function LC.PoseProp(id, name, built)
    local def = LC.Poses[id]
    local p = def and def.props[name]
    if not p then return nil end
    local o = LC.PoseOverrides[id]
    o = o and o.props and o.props[name]
    if o then
        return { model = p.model, bone = o.bone or "", pos = Vector(o.pos[1], o.pos[2], o.pos[3]),
            ang = Angle(o.ang[1], o.ang[2], o.ang[3]), auto = false, tuned = true }
    end
    if not built and p.built then built = p.built() end
    local pos, ang = built and built.pos or p.pos, built and built.ang or p.ang
    return { model = p.model, bone = p.bone or "", pos = Vector(pos.x, pos.y, pos.z), ang = Angle(ang.p, ang.y, ang.r),
        auto = p.auto == true, tuned = false }
end

------------------------------------------------------------------------
-- Checking what is sent in (the server keeps only what passes; LC.PoseSet)
------------------------------------------------------------------------

local function Number(x)
    x = tonumber(x)
    if not x or x ~= x or x == math.huge or x == -math.huge then return nil end
    return x
end
local function Round(x) return math.floor(x * 10 + 0.5) / 10 end
-- (an angle is the same turn every 360 degrees: brought round to within 180 either way)
local function Degrees(x)
    x = Number(x)
    if not x then return nil end
    local lim = LC.PoseLimits.angle
    return math.Clamp(Round((x + 180) % 360 - 180), -lim, lim)
end
local function Units(x)
    x = Number(x)
    if not x then return nil end
    local lim = LC.PoseLimits.pos
    return Round(math.Clamp(x, -lim, lim))
end
local function Apart(a, b) return math.abs((a - b + 180) % 360 - 180) end

function LC.PosePropBone(id, name, bone)
    local p = LC.Poses[id] and LC.Poses[id].props[name]
    if not p or not isstring(bone) then return false end
    if bone == (p.bone or "") then return true end
    for _, b in ipairs(p.bones or {}) do if b == bone then return true end end
    return false
end

-- bones: { [name] = { p, y, r } }, props: { [name] = { bone, pos = { x, y, z }, ang = { p, y, r } } }.
-- Returns the same with only this pose's own bones and props, every number real and within
-- reach; a bone left as the code has it is left out. nil and why when there is no such pose.
function LC.PoseClean(id, bones, props)
    local def = isstring(id) and LC.Poses[id]
    if not def then return nil, "no such pose" end
    local out = { bones = {}, props = {} }
    local same = LC.PoseLimits.same
    if istable(bones) then
        local n = 0
        for name, a in pairs(bones) do
            if n < LC.PoseLimits.bones and Knows(def, name) and istable(a) then
                local p, y, r = Degrees(a[1]), Degrees(a[2]), Degrees(a[3])
                if p and y and r then
                    local b = def.bones[name]
                    local asBuilt = Apart(p, b and b.p or 0) <= same and Apart(y, b and b.y or 0) <= same and Apart(r, b and b.r or 0) <= same
                    if not asBuilt then out.bones[name] = { p, y, r } n = n + 1 end
                end
            end
        end
    end
    if istable(props) then
        for name, o in pairs(props) do
            if isstring(name) and def.props[name] and istable(o) and istable(o.pos) and istable(o.ang) then
                local bone = isstring(o.bone) and o.bone or (def.props[name].bone or "")
                local x, y, z = Units(o.pos[1]), Units(o.pos[2]), Units(o.pos[3])
                local ap, ay, ar = Degrees(o.ang[1]), Degrees(o.ang[2]), Degrees(o.ang[3])
                if LC.PosePropBone(id, name, bone) and x and y and z and ap and ay and ar then
                    out.props[name] = { bone = bone, pos = { x, y, z }, ang = { ap, ay, ar } }
                end
            end
        end
    end
    return out
end

-- Everything the owner has set, put in place (the server's saved file read in; a player's game
-- told by the server). Poses this version doesn't know are kept as they came, and not used.
function LC.PoseOverridesSet(all)
    local out = {}
    for id, o in pairs(istable(all) and all or {}) do
        if isstring(id) and istable(o) then
            if LC.Poses[id] then
                local clean = LC.PoseClean(id, o.bones, o.props)
                if clean and (next(clean.bones) ~= nil or next(clean.props) ~= nil) then out[id] = clean end
            else
                out[id] = o
            end
        end
    end
    LC.PoseOverrides = out
    version = version + 1
    hook.Run("LivingCityPosesChanged")
    return out
end

-- The numbers as text, for a coder to make the new built-in ("Copy the numbers").
function LC.PoseText(id)
    local def = LC.Poses[id]
    if not def then return "" end
    local function N(x) return tostring(Round(x)) end
    local lines = { string.format("%s (%s)%s", id, def.label, LC.PoseTuned(id) and "" or ", as built in") }
    local bones, names = LC.PoseBones(id), {}
    for name in pairs(bones) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local a = bones[name]
        lines[#lines + 1] = string.format("  [\"%s\"] = Angle(%s, %s, %s),", name, N(a.p), N(a.y), N(a.r))
    end
    names = {}
    for name in pairs(def.props) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local p = LC.PoseProp(id, name)
        lines[#lines + 1] = string.format("  %s: %s, from %s, Vector(%s, %s, %s), Angle(%s, %s, %s)", name,
            p.auto and "placed by the code" or "held", p.bone == "" and "its feet" or ("\"" .. p.bone .. "\""),
            N(p.pos.x), N(p.pos.y), N(p.pos.z), N(p.ang.p), N(p.ang.y), N(p.ang.r))
    end
    return table.concat(lines, "\n")
end

------------------------------------------------------------------------
-- The poses, with the numbers the code was written with
------------------------------------------------------------------------

local ARMS = { B .. "R_UpperArm", B .. "R_Forearm", B .. "R_Hand", B .. "L_UpperArm", B .. "L_Forearm", B .. "L_Hand" }
local function With(list, more)
    local out = {}
    for _, n in ipairs(list) do out[#out + 1] = n end
    for _, n in ipairs(more) do out[#out + 1] = n end
    return out
end
local UPPER = With(ARMS, { B .. "Spine2", B .. "Head1" })

-- Cuffed: the arms behind the back (cl_livingcity_cuffed.lua; its own setting, lc_cuff_pose, is the built-in)
LC.PoseAdd({
    id = "cuffed", label = "Cuffed", model = CITIZEN, ref = CITIZEN_REF,
    bones = {
        [B .. "R_UpperArm"] = Angle(6, 40, 75), [B .. "L_UpperArm"] = Angle(-6, 40, -75),
        [B .. "R_Forearm"] = Angle(0, -75, 0), [B .. "L_Forearm"] = Angle(0, -75, 0),
        [B .. "R_Hand"] = Angle(0, 10, 0), [B .. "L_Hand"] = Angle(0, 10, 0),
    },
    free = { B .. "Spine2", B .. "Head1" },
})

-- The shackled vortigaunt sweeping the street (sv_livingcity_resistanceops.lua). Its broom is worked
-- out from its hands and the floor every tick until the owner puts it in its claws by hand; then it
-- hangs from that claw. The place given here is only where the mannequin's broom starts.
LC.PoseAdd({
    id = "vort_sweep", label = "Vortigaunt sweeping", model = "models/vortigaunt_slave.mdl", modelElse = "models/vortigaunt.mdl", ref = "sweep",
    any = "^ValveBiped%.[%w_]+$", -- (its own skeleton, not a person's: whichever of its bones the mannequin can turn)
    props = {
        broom = { model = BROOM_MODEL, auto = true, bone = "ValveBiped.hand1_R", pos = Vector(4, 0, 0), ang = Angle(0, 0, 0),
            bones = { "ValveBiped.hand1_R", "ValveBiped.hand1_L", "" } },
    },
})

-- A stalker's push broom (sv_livingcity_stalkerwork.lua; its own setting, lc_broom_hold, is the built-in)
LC.PoseAdd({
    id = "stalker_sweep", label = "Stalker sweeping", model = "models/stalker.mdl", ref = "idle01",
    props = {
        broom = { model = BROOM_MODEL, bone = "", pos = Vector(34, -6, 2), ang = Angle(-35, 0, 0),
            bones = { "", B .. "R_Hand", B .. "L_Hand" } },
    },
})

-- A hand over the eyes or the mouth (cl_livingcity_gasmask.lua; lc_handface_eyes and lc_handface_mouth are the built-in)
LC.PoseAdd({
    id = "hand_eyes", label = "Hand over the eyes", model = CITIZEN, ref = CITIZEN_REF,
    bones = { [B .. "L_UpperArm"] = Angle(-30, -80, 20), [B .. "L_Forearm"] = Angle(0, -120, 0), [B .. "L_Hand"] = Angle(0, 10, 0) },
})
LC.PoseAdd({
    id = "hand_mouth", label = "Hand over the mouth", model = CITIZEN, ref = CITIZEN_REF,
    bones = { [B .. "L_UpperArm"] = Angle(-30, -65, 20), [B .. "L_Forearm"] = Angle(0, -125, 0), [B .. "L_Hand"] = Angle(0, 15, 0) },
})

-- The morning drill's jump: both arms up (sv_livingcity_exercise.lua)
LC.PoseAdd({
    id = "drill_arms_up", label = "Drill: arms up", model = CITIZEN, ref = CITIZEN_REF,
    bones = { [B .. "R_UpperArm"] = Angle(10, -120, 0), [B .. "L_UpperArm"] = Angle(-10, -120, 0),
        [B .. "R_Forearm"] = Angle(0, -20, 0), [B .. "L_Forearm"] = Angle(0, -20, 0) },
    free = With(UPPER, {}),
})

-- A salute in a crowd (sv_livingcity_exercise.lua, LC.CrowdSalute): a smart one; a limp one is part of it
LC.PoseAdd({
    id = "salute_crowd", label = "Salute (crowd)", model = CITIZEN, ref = CITIZEN_REF,
    bones = { [B .. "R_UpperArm"] = Angle(-35, -75, 0), [B .. "R_Forearm"] = Angle(0, -115, 0) },
    free = { B .. "R_Hand", B .. "Spine2", B .. "Head1" },
})

-- Careless Talk's salute (sv_livingcity_propagandamore.lua)
LC.PoseAdd({
    id = "salute_talk", label = "Salute (Careless Talk)", model = CITIZEN, ref = CITIZEN_REF,
    bones = { [B .. "R_UpperArm"] = Angle(-70, -30, -20), [B .. "R_Forearm"] = Angle(0, -125, 0), [B .. "R_Hand"] = Angle(0, 0, -40) },
    free = { B .. "Spine2", B .. "Head1" },
})

-- A unit's bow at the Administrator's review (sv_livingcity_quests.lua)
LC.PoseAdd({
    id = "review_bow", label = "Unit's bow", model = "models/police.mdl", ref = "idle",
    bones = { [B .. "Head1"] = Angle(0, 25, 0), [B .. "Spine2"] = Angle(0, 10, 0) },
    free = With(ARMS, {}),
})

------------------------------------------------------------------------
-- The Pose Recorder (a separate addon), when it is installed: every pose here is one of its
-- "targets", so its mannequin can be stood in the pose, moved by hand with the physgun, and
-- measured. Without the addon nothing here runs, and every pose plays as it always did.
------------------------------------------------------------------------

function LC.PoseTargetId(id) return "livingcity_" .. id end
function LC.PoseFromTargetId(tid)
    local id = isstring(tid) and string.match(tid, "^livingcity_(.+)$")
    return id and LC.Poses[id] and id or nil
end

-- The pose as the Pose Recorder takes it: plain tables of numbers.
function LC.PoseForRecorder(id)
    local bones, props = {}, {}
    for name, a in pairs(LC.PoseBones(id)) do bones[name] = { a.p, a.y, a.r } end
    for name in pairs(LC.Poses[id] and LC.Poses[id].props or {}) do
        local p = LC.PoseProp(id, name)
        props[name] = { model = p.model, bone = p.bone ~= "" and p.bone or nil,
            pos = { p.pos.x, p.pos.y, p.pos.z }, ang = { p.ang.p, p.ang.y, p.ang.r } }
    end
    return bones, props
end

-- (the Poser's "hangs from" choice, in the game of whoever is posing: [pose id][prop name] = bone)
LC.PoseHangChoice = LC.PoseHangChoice or {}

local function May(ply)
    if SERVER then return LC.PoseMay ~= nil and LC.PoseMay(ply) end
    return (game.SinglePlayer ~= nil and game.SinglePlayer()) or (IsValid(ply) and ply:IsSuperAdmin())
end
LC.PoseMayHere = May

function LC.PoseBridge()
    local PR = PoseRecorder
    if not (PR and PR.AddTarget) then return false end
    for _, def in ipairs(LC.PoseList()) do
        local id = def.id
        -- (a server without the shackled vortigaunt's model: the plain one, as the street sweepers themselves fall back.
        -- Only the server is asked: a player's game says no to a model it hasn't loaded yet, and is told the model anyway)
        local model = def.model
        if SERVER and def.modelElse and util.IsValidModel and not util.IsValidModel(model) then model = def.modelElse end
        PR.AddTarget({
            id = LC.PoseTargetId(id), label = "Miscount: " .. def.label, model = model, ref = def.ref,
            can = May,
            get = function() return LC.PoseForRecorder(id) end,
            -- (server) what was measured on the mannequin: checked there, kept, sent to everyone
            set = function(ply, bones, props)
                if not LC.PoseSet then return false, "Only the server can keep a pose." end
                for _, o in pairs(props or {}) do o.bone = o.bone or "" end
                return LC.PoseSet(ply, id, bones, props)
            end,
            hang = function(name)
                local c = LC.PoseHangChoice[id]
                return c and c[name] or nil
            end,
        })
    end
    return true
end
LC.PoseBridge()
hook.Add("InitPostEntity", "LivingCityPoseBridge", function() LC.PoseBridge() end)

-- A player's game: what the owner has set, as the server keeps it (on joining, and at every change).
if CLIENT then
    net.Receive("lc_poses", function() LC.PoseOverridesSet(net.ReadTable()) end)
end
