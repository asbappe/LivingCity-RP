--[[
    Pose Recorder: targets (another addon's poses, set by hand on a mannequin)

      An addon that poses people in code (a salute, a pair of cuffs, a broom held in two
      hands) can hand its numbers to the Pose Recorder, to be set by eye instead of typed:

        PoseRecorder.AddTarget({
            id = "myaddon_salute", label = "Salute",
            model = "models/humans/group01/male_07.mdl",   -- the mannequin
            ref = "idle_subtle",                           -- the sequence the pose sits on top of
            get = function() return bones, props end,
            set = function(ply, bones, props) end,         -- (server) return false, "why" to refuse
            can = function(ply) return ply:IsAdmin() end,  -- (optional) who may
            hang = function(name) return "a bone" end,     -- (optional, client) the bone a held thing is measured from
        })

      bones is { [bone name] = { p, y, r } } (or Angles): Entity:ManipulateBoneAngles values
      on top of ref. props is what is held in the pose: { [name] = { model = "models/...",
      bone = "a bone" (none: the spot the model stands on), pos = { x, y, z }, ang = { p, y, r } } }
      (or a Vector and an Angle). get is called in the player's game for the numbers, and on
      the server for the held things' models.

      PoseRecorder.TargetMannequin(ply, id, pos, yaw) on the server (or the console command
      pose_recorder_target <id>, or the tool's panel) stands a ragdoll of the model there,
      already in the pose get gives, every limb frozen, each held thing a frozen prop in its
      place. The player moves limbs and props with the physgun; whatever is let go of stays
      where it is. pose_recorder_take (the panel's "Use this pose") measures it: every bone a
      ragdoll is posed by, relative to ref, and each held thing's place and angle from its
      bone. set is called on the server with them (checked: plain numbers, known names).
      PoseRecorder.TargetRemove(ply) takes the mannequin away; it goes when its player does.
]]

local PR = PoseRecorder
PR.targets = PR.targets or {}

local function Fn(f) return type(f) == "function" and f or nil end

function PR.AddTarget(t)
    if type(t) ~= "table" then return false, "a target is a table" end
    local id = type(t.id) == "string" and #t.id <= PR.LIMITS.name and string.match(t.id, "^[%w_%-]+$")
    if not id then return false, "a target needs an id (letters, digits, _ and -)" end
    if type(t.model) ~= "string" or t.model == "" then return false, "a target needs a model" end
    if not Fn(t.get) then return false, "a target needs get" end
    PR.targets[id] = {
        id = id, label = type(t.label) == "string" and t.label ~= "" and t.label or id, model = t.model,
        ref = type(t.ref) == "string" and t.ref ~= "" and t.ref or "idle_all_01",
        get = t.get, set = Fn(t.set), can = Fn(t.can), hang = Fn(t.hang),
    }
    hook.Run("PoseRecorderTargetsChanged")
    return true
end

function PR.RemoveTarget(id)
    if not PR.targets[id] then return false end
    PR.targets[id] = nil
    hook.Run("PoseRecorderTargetsChanged")
    return true
end

function PR.Target(id) return PR.targets[id] end

-- Every target, by label.
function PR.Targets()
    local out = {}
    for _, t in pairs(PR.targets) do out[#out + 1] = t end
    table.sort(out, function(a, b) if a.label ~= b.label then return a.label < b.label end return a.id < b.id end)
    return out
end

-- Three numbers from { 1, 2, 3 }, or from an Angle or a Vector.
local function Arr(v, a, b, c)
    if v == nil then return { 0, 0, 0 } end
    if type(v) == "table" then return { tonumber(v[1] or v[a]) or 0, tonumber(v[2] or v[b]) or 0, tonumber(v[3] or v[c]) or 0 } end
    return { tonumber(v[1]) or 0, tonumber(v[2]) or 0, tonumber(v[3]) or 0 }
end

-- What a target's get gives, as plain tables: bones { [name] = { p, y, r } } and props
-- { [name] = { model, bone (or nil), pos = { x, y, z }, ang = { p, y, r } } }; nil and why if get fails.
function PR.TargetPose(t)
    local ok, bones, props = pcall(t.get)
    if not ok then return nil, tostring(bones) end
    local B, P = {}, {}
    for name, a in pairs(type(bones) == "table" and bones or {}) do
        if type(name) == "string" then B[name] = Arr(a, "p", "y", "r") end
    end
    for name, o in pairs(type(props) == "table" and props or {}) do
        if type(name) == "string" and type(o) == "table" and type(o.model) == "string" then
            P[name] = { model = o.model, bone = (type(o.bone) == "string" and o.bone ~= "") and o.bone or nil,
                pos = Arr(o.pos, "x", "y", "z"), ang = Arr(o.ang, "p", "y", "r") }
        end
    end
    return B, P
end

local function Real(x) return type(x) == "number" and x == x and x > -1e6 and x < 1e6 end
local function RealThree(t) return type(t) == "table" and Real(t[1]) and Real(t[2]) and Real(t[3]) end

if SERVER then
    util.AddNetworkString("pose_recorder_target") -- server: your mannequin of a target stands here
    util.AddNetworkString("pose_recorder_place")  -- client: where each limb and held thing goes, in that pose
    util.AddNetworkString("pose_recorder_take")   -- client: the pose as it stands now, measured
    util.AddNetworkString("pose_recorder_told")   -- server: a line to say

    PR.mannequins = PR.mannequins or {} -- [ply] = { id, ent, props = { [name] = ent }, phys = { [bone] = index }, origin, yaw }

    local function Tell(ply, msg)
        if not IsValid(ply) or not msg then return end
        net.Start("pose_recorder_told")
        net.WriteString(msg)
        net.Send(ply)
    end
    PR.Tell = Tell

    local function Freeze(ent)
        if not IsValid(ent) or not ent.GetPhysicsObjectCount then return end
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local ph = ent:GetPhysicsObjectNum(i)
            if IsValid(ph) then ph:EnableMotion(false) ph:Wake() end
        end
    end

    -- A player's mannequin of a target, while it stands.
    function PR.TargetOf(ply)
        local m = PR.mannequins[ply]
        if m and IsValid(m.ent) then return m end
        if m then PR.TargetRemove(ply) end
        return nil
    end

    function PR.TargetRemove(ply)
        local m = PR.mannequins[ply]
        PR.mannequins[ply] = nil
        if not m then return false end
        for _, e in pairs(m.props) do if IsValid(e) then e:Remove() end end
        if IsValid(m.ent) then m.ent:Remove() end
        return true
    end

    -- Stand a target's mannequin at pos, facing yaw. Returns the ragdoll, or nil and why.
    function PR.TargetMannequin(ply, id, pos, yaw)
        local t = PR.targets[id]
        if not IsValid(ply) or not t then return nil, "There's no such pose." end
        if t.can and not t.can(ply) then return nil, "You may not set that pose." end
        if hook.Run("PlayerSpawnRagdoll", ply, t.model) == false then return nil, "You can't spawn a ragdoll here." end
        PR.TargetRemove(ply)
        yaw = tonumber(yaw) or 0
        local rag = PR.Mannequin(ply, t.model, pos, yaw)
        if not IsValid(rag) then return nil, "The model " .. t.model .. " has no ragdoll to pose." end
        local m = { id = id, ent = rag, props = {}, phys = {}, origin = Vector(pos.x, pos.y, pos.z), yaw = yaw }
        local names = {}
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local bone = rag:TranslatePhysBoneToBone(i)
            local name = bone and bone >= 0 and rag:GetBoneName(bone)
            if name and name ~= "__INVALIDBONE__" and not m.phys[name] then
                m.phys[name] = i
                names[#names + 1] = name
            end
        end
        local got, props = PR.TargetPose(t)
        local held = {}
        for name, p in pairs(got and props or {}) do
            if #held < PR.TARGET_LIMITS.props and (not util.IsValidModel or util.IsValidModel(p.model)) then
                local e = ents.Create("prop_physics")
                if IsValid(e) then
                    e:SetModel(p.model)
                    e:SetPos(pos + Vector(0, 0, 40))
                    e:Spawn()
                    e:Activate()
                    Freeze(e)
                    e.PoseRecorderHeld = true
                    if rag.DeleteOnRemove then rag:DeleteOnRemove(e) end
                    hook.Run("PlayerSpawnedProp", ply, p.model, e)
                    m.props[name] = e
                    held[#held + 1] = name
                end
            end
        end
        rag.PoseRecorderHeld = true
        PR.mannequins[ply] = m
        net.Start("pose_recorder_target")
        net.WriteString(id)
        net.WriteUInt(rag:EntIndex(), 16)
        net.WriteFloat(pos.x) net.WriteFloat(pos.y) net.WriteFloat(pos.z)
        net.WriteFloat(yaw)
        net.WriteUInt(#names, 8)
        for _, n in ipairs(names) do net.WriteString(n) end
        net.WriteUInt(#held, 4)
        for _, n in ipairs(held) do
            net.WriteString(n)
            net.WriteUInt(m.props[n]:EntIndex(), 16)
        end
        net.Send(ply)
        return rag
    end

    -- The mannequin put in its pose: bones { [name] = { pos = { x, y, z }, ang = { p, y, r } } } for
    -- the limbs, props the same for what is held, all as seen from the spot it stands on.
    function PR.TargetPlace(ply, bones, props)
        local m = PR.TargetOf(ply)
        if not m then return false end
        local frame = PR.FromAngles(0, m.yaw, 0)
        local reach = PR.TARGET_LIMITS.reach
        local function World(at)
            if type(at) ~= "table" or not RealThree(at.pos) or not RealThree(at.ang) then return nil end
            if math.abs(at.pos[1]) > reach or math.abs(at.pos[2]) > reach or math.abs(at.pos[3]) > reach then return nil end
            local w = PR.Rotate(frame, at.pos)
            local p, y, r = PR.ToAngles(PR.Mul(frame, PR.FromAngles(at.ang[1], at.ang[2], at.ang[3])))
            return Vector(m.origin.x + w[1], m.origin.y + w[2], m.origin.z + w[3]), Angle(p, y, r)
        end
        local n = 0
        for name, at in pairs(type(bones) == "table" and bones or {}) do
            local i = m.phys[name]
            local ph = i and m.ent:GetPhysicsObjectNum(i)
            local pos, ang = World(at)
            if IsValid(ph) and pos then
                ph:EnableMotion(false)
                ph:SetPos(pos)
                ph:SetAngles(ang)
                ph:Wake()
                n = n + 1
            end
        end
        for name, at in pairs(type(props) == "table" and props or {}) do
            local e = m.props[name]
            local pos, ang = World(at)
            if IsValid(e) and pos then
                e:SetPos(pos)
                e:SetAngles(ang)
                local ph = e.GetPhysicsObject and e:GetPhysicsObject()
                if IsValid(ph) then
                    ph:EnableMotion(false)
                    ph:SetPos(pos)
                    ph:SetAngles(ang)
                    ph:Wake()
                end
                n = n + 1
            end
        end
        return true, n
    end

    -- The pose as the player's game measured it, checked and handed to the target's set.
    function PR.TargetTake(ply, id, bones, props)
        local m = PR.TargetOf(ply)
        local t = PR.targets[id]
        if not t or not m or m.id ~= id then return false, "Stand that pose's mannequin first." end
        if t.can and not t.can(ply) then return false, "You may not set that pose." end
        if not t.set then return false, "That pose can't be set." end
        local B, why = PR.CleanPose(bones)
        if not B then return false, "The pose was turned down: " .. why .. "." end
        for name in pairs(B) do if not m.phys[name] then B[name] = nil end end -- (only what a ragdoll is posed by)
        local P, why2 = PR.CleanProps(props or {})
        if not P then return false, "The pose was turned down: " .. why2 .. "." end
        for name in pairs(P) do if not m.props[name] then P[name] = nil end end
        local ok, done, said = pcall(t.set, ply, B, P)
        if not ok then return false, "It couldn't be set: " .. tostring(done) end
        if done == false then return false, type(said) == "string" and said or "It was turned down." end
        hook.Run("PoseRecorderTargetSet", ply, id, B, P)
        return true
    end

    local function ReadThree() return { net.ReadFloat(), net.ReadFloat(), net.ReadFloat() } end

    net.Receive("pose_recorder_place", function(_, ply)
        if not IsValid(ply) then return end
        local idx = net.ReadUInt(16)
        local bones, props = {}, {}
        for _ = 1, math.min(net.ReadUInt(8), 128) do
            local name = net.ReadString()
            bones[name] = { pos = ReadThree(), ang = ReadThree() }
        end
        for _ = 1, math.min(net.ReadUInt(4), PR.TARGET_LIMITS.props) do
            local name = net.ReadString()
            props[name] = { pos = ReadThree(), ang = ReadThree() }
        end
        local m = PR.TargetOf(ply)
        if not m or m.ent:EntIndex() ~= idx then return end
        PR.TargetPlace(ply, bones, props)
    end)

    net.Receive("pose_recorder_take", function(_, ply)
        if not IsValid(ply) then return end
        local id = net.ReadString()
        local bones, props = {}, {}
        for _ = 1, math.min(net.ReadUInt(8), 128) do
            local name = net.ReadString()
            bones[name] = ReadThree()
        end
        for _ = 1, math.min(net.ReadUInt(4), PR.TARGET_LIMITS.props) do
            local name = net.ReadString()
            local bone = net.ReadString()
            props[name] = { bone = bone, pos = ReadThree(), ang = ReadThree() }
        end
        local ok, why = PR.TargetTake(ply, id, bones, props)
        local t = PR.targets[id]
        Tell(ply, ok and ((t and t.label or id) .. ": set.") or why)
    end)

    -- Whatever is let go of stays where it is (a limb, or a held thing): no right click needed.
    hook.Add("PhysgunDrop", "PoseRecorderTargets", function(_, ent)
        if IsValid(ent) and ent.PoseRecorderHeld then Freeze(ent) end
    end)

    hook.Add("PlayerDisconnected", "PoseRecorderTargets", function(ply) PR.TargetRemove(ply) end)

    concommand.Add("pose_recorder_target", function(ply, _, args)
        if not IsValid(ply) then return end
        local pos, yaw = PR.Spot(ply)
        local rag, why = PR.TargetMannequin(ply, args and args[1] or "", pos, yaw)
        if not rag then Tell(ply, why) end
    end)
    concommand.Add("pose_recorder_target_remove", function(ply)
        if IsValid(ply) then PR.TargetRemove(ply) end
    end)
    return
end

------------------------------------------------------------------------
-- Your screen: the mannequin put in the pose, and the pose measured
------------------------------------------------------------------------

net.Receive("pose_recorder_told", function() PR.Say(net.ReadString()) end)

net.Receive("pose_recorder_target", function()
    local id = net.ReadString()
    local idx = net.ReadUInt(16)
    local origin = { net.ReadFloat(), net.ReadFloat(), net.ReadFloat() }
    local yaw = net.ReadFloat()
    local phys, props = {}, {}
    for _ = 1, net.ReadUInt(8) do phys[net.ReadString()] = true end
    for _ = 1, net.ReadUInt(4) do
        local name = net.ReadString()
        props[name] = net.ReadUInt(16)
    end
    PR.sel = { idx = idx, ent = Entity and Entity(idx) or nil, phys = phys, target = id, props = props, origin = origin, yaw = yaw }
    PR.PlaceTarget()
    hook.Run("PoseRecorderChanged")
end)

local function Named(ref)
    local by = {}
    for i, b in ipairs(ref.bones) do by[b.name] = i end
    return by
end

-- The picked target's pose as it is now, worked out on the model and sent to the server to
-- put the mannequin's limbs (and what it holds) there.
function PR.PlaceTarget()
    local sel = PR.sel
    local t = sel and sel.target and PR.targets[sel.target]
    if not t then return false end
    local bones, props = PR.TargetPose(t)
    if not bones then PR.Say("That pose couldn't be read: " .. tostring(props)) return false end
    local ref = PR.Reference(t.model, t.ref)
    if not ref or not ref.bones then PR.Say("Couldn't load the model to pose it.") return false end
    local rot, pos = PR.Apply(ref.bones, ref.rel, ref.pos, bones, 0)
    local by = Named(ref)
    local limbs, held = {}, {}
    for name in pairs(sel.phys) do
        local i = by[name]
        if i and #limbs < 128 then
            local p, y, r = PR.ToAngles(rot[i])
            limbs[#limbs + 1] = { name, pos[i], { p, y, r } }
        end
    end
    for name in pairs(sel.props) do
        local p = props[name]
        if p then
            local i = p.bone and by[p.bone]
            local at, turn
            if i then at, turn = PR.Place(rot[i], pos[i], p.pos, p.ang)
            else at, turn = p.pos, PR.FromAngles(p.ang[1], p.ang[2], p.ang[3]) end
            local a, b, c = PR.ToAngles(turn)
            held[#held + 1] = { name, at, { a, b, c } }
        end
    end
    net.Start("pose_recorder_place")
    net.WriteUInt(sel.idx, 16)
    net.WriteUInt(#limbs, 8)
    for _, l in ipairs(limbs) do
        net.WriteString(l[1])
        for k = 1, 3 do net.WriteFloat(l[2][k]) end
        for k = 1, 3 do net.WriteFloat(l[3][k]) end
    end
    net.WriteUInt(#held, 4)
    for _, h in ipairs(held) do
        net.WriteString(h[1])
        for k = 1, 3 do net.WriteFloat(h[2][k]) end
        for k = 1, 3 do net.WriteFloat(h[3][k]) end
    end
    net.SendToServer()
    return true
end

-- Where the mannequin stands now, however it has been dragged about: the spot under it and the
-- way it faces, from its root bone.
local function Standing(sel, t, face)
    local frame = PR.FromAngles(0, face or sel.yaw or 0, 0)
    local ent = sel.ent
    local ref = PR.Reference(t.model, t.ref)
    if ref and ref.bones and IsValid(ent) then
        for i, b in ipairs(ref.bones) do
            if not b.parent and sel.phys[b.name] and ref.pos[i] then
                local id = ent:LookupBone(b.name)
                local m = id and ent:GetBoneMatrix(id)
                local v = m and m.GetTranslation and m:GetTranslation()
                if v then
                    local w = PR.Rotate(frame, ref.pos[i])
                    return frame, { v.x - w[1], v.y - w[2], v.z - w[3] }
                end
            end
        end
    end
    return frame, sel.origin or { 0, 0, 0 }
end

-- "Use this pose": the mannequin measured (its bones relative to the target's sequence, and
-- each held thing from its bone) and sent to the server for the target's set.
function PR.TakeTarget()
    local sel = PR.sel
    local t = sel and sel.target and PR.targets[sel.target]
    if not t then PR.Say("Stand a pose's mannequin first.") return false end
    local bones, face = PR.Snapshot(t.ref)
    if not bones then PR.Say(face) return false end
    local ent = sel.ent
    local got, props = PR.TargetPose(t)
    local held = {}
    for name, idx in pairs(sel.props) do
        local e = Entity and Entity(idx)
        local p = got and props[name]
        if IsValid(e) and p then
            local bone = t.hang and t.hang(name)
            if bone == nil then bone = p.bone end
            if bone == "" then bone = nil end
            local id = bone and ent:LookupBone(bone)
            local m = id and ent:GetBoneMatrix(id)
            local bRot, bPos
            if m and m.GetTranslation then
                local a, v = m:GetAngles(), m:GetTranslation()
                bRot, bPos = PR.FromAngles(a.p, a.y, a.r), { v.x, v.y, v.z }
            else
                bone = nil -- (no such bone on this model: from the spot it stands on)
                bRot, bPos = Standing(sel, t, face)
            end
            local ea, ev = e:GetAngles(), e:GetPos()
            local lp, la = PR.Offset(bRot, bPos, PR.FromAngles(ea.p, ea.y, ea.r), { ev.x, ev.y, ev.z })
            if #held < PR.TARGET_LIMITS.props then held[#held + 1] = { name, bone or "", lp, la } end
        end
    end
    local names = {}
    for name in pairs(bones) do if #names < 128 then names[#names + 1] = name end end
    net.Start("pose_recorder_take")
    net.WriteString(t.id)
    net.WriteUInt(#names, 8)
    for _, name in ipairs(names) do
        net.WriteString(name)
        for k = 1, 3 do net.WriteFloat(bones[name][k]) end
    end
    net.WriteUInt(#held, 4)
    for _, h in ipairs(held) do
        net.WriteString(h[1])
        net.WriteString(h[2])
        for k = 1, 3 do net.WriteFloat(h[3][k]) end
        for k = 1, 3 do net.WriteFloat(h[4][k]) end
    end
    net.SendToServer()
    return true
end

concommand.Add("pose_recorder_take", function() PR.TakeTarget() end)
