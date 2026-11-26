--[[
    Living City (client): the old-timer's face (sv_livingcity_oldtimer.lua)

    His body stays an ordinary citizen in citizen's clothes; his head is Lost
    Coast's old fisherman (lc_oldtimer_face). Half-Life 2 can't swap heads,
    so the fisherman is laid over the citizen: every frame each of his bones
    is put where the citizen's bone of the same name is, his head and neck
    at full size and everything else shrunk to nothing, and the citizen's
    own head shrunk away beneath it (to 0.01). Not parented, not bone-merged
    (26 November: a parent out of view let go, and the head floated).

    Only on this player's screen, and only if they have the model (Lost
    Coast's files, which come with Garry's Mod): without it, the citizen
    keeps his own face, never an error model.

    "Have the model" is asked of the files, not of util.IsValidModel (the
    owner, 14 November: he was "a black citizen with a beanie", his own
    face): on a player's game that says no for any model the server has not
    loaded yet, and nothing in the city is ever the fisherman, so the face
    was never put on. LC_CL.OldTimerFaceUsable.
]]

LC_CL = LC_CL or {}

local faces = {} -- [npc] = the head model laid over him
local nextLook = 0

-- Can this game draw that head? Its file is there (in a mounted game, loaded or not).
function LC_CL.OldTimerFaceUsable(model)
    if not model or model == "" then return false end
    if file and file.Exists and file.Exists(model, "GAME") then return true end
    return util.IsValidModel(model) and true or false
end

local function Keep(name)
    name = string.lower(name or "")
    return string.find(name, "head", 1, true) or string.find(name, "neck", 1, true)
end

-- every head laid with LC_CL.HeadOn: [head] = the body it sits on
local heads = setmetatable({}, { __mode = "k" })

-- That bone's matrix at full size: its direction and place kept, its scale put back to 1. Nil if it has none.
local function FullSize(m)
    local f, r, u = m:GetForward(), m:GetRight(), m:GetUp()
    if f:LengthSqr() < 1e-12 or r:LengthSqr() < 1e-12 or u:LengthSqr() < 1e-12 then return nil end
    f:Normalize() r:Normalize() u:Normalize()
    m:SetForward(f) m:SetRight(r) m:SetUp(u)
    return m
end

-- A bone shrunk to nothing at that matrix's place.
local function Nothing(at)
    local z = Matrix()
    z:SetTranslation(at:GetTranslation())
    z:Scale(Vector(0, 0, 0))
    return z
end

local function Restore(npc)
    local f = faces[npc]
    if IsValid(f) then f:Remove() end
    if f then heads[f] = nil end
    faces[npc] = nil
    if IsValid(npc) then
        local hb = npc:LookupBone("ValveBiped.Bip01_Head1")
        if hb then npc:ManipulateBoneScale(hb, Vector(1, 1, 1)) end
    end
end

-- That head laid over any citizen-boned model (an NPC, or a model on this screen only such as the Colonel):
-- returns the head, or nil. The body's own head is shrunk away beneath it.
--
-- (the owner, 26 November: "the old timer still has no head and leaves a shrunken mutated ragdoll NPC thing
-- floating in the air in a random spot".) It used to be parented to him and bone-merged, but the game lets
-- go of a parent that walks out of a player's view: the head (his body shrunk to nothing around it) stayed
-- floating where he had been, and he walked on with his own head shrunk. Now nothing is parented: every
-- frame each of the head's bones is put where the body's bone of the same name is (head and neck at full
-- size, the rest shrunk to nothing inside him), and it is drawn only while its body is there to be drawn.
-- The body's own head is shrunk only once this one has been drawn, so if it never can be, he keeps his own.
function LC_CL.HeadOn(body, model, group)
    if util.PrecacheModel then util.PrecacheModel(model) end
    local f = ClientsideModel(model, group or RENDERGROUP_OPAQUE)
    if not IsValid(f) then return nil end
    local map, keep, kept = {}, {}, 0
    for i = 0, (f:GetBoneCount() or 0) - 1 do
        local name = f:GetBoneName(i)
        map[i] = body:LookupBone(name or "")
        keep[i] = Keep(name) and true or false
        if keep[i] and map[i] then kept = kept + 1 end
    end
    if kept == 0 then f:Remove() return nil end -- (no head or neck in common: he keeps his own face)
    local hb = body:LookupBone("ValveBiped.Bip01_Head1")
    f:SetPos(body:GetPos())
    f:SetAngles(body:GetAngles())
    if f.SetRenderBounds then f:SetRenderBounds(Vector(-48, -48, -8), Vector(48, 48, 96)) end
    if f.AddCallback then
        f:AddCallback("BuildBonePositions", function(e, n)
            if not IsValid(body) then return end
            local headAt = hb and body:GetBoneMatrix(hb)
            for i = 0, (n or e:GetBoneCount() or 0) - 1 do
                local m = map[i] and body:GetBoneMatrix(map[i])
                if keep[i] and m then
                    m = FullSize(m) -- (his own head is shrunk; this one isn't)
                    if m then e:SetBoneMatrix(i, m) end
                elseif m or headAt then
                    e:SetBoneMatrix(i, Nothing(m or headAt))
                end
            end
        end)
    end
    local shrunk = false
    f.RenderOverride = function(self, flags)
        if not IsValid(body) or (body.IsDormant and body:IsDormant()) or (body.GetNoDraw and body:GetNoDraw()) then return end
        if body.SetupBones then body:SetupBones() end
        self:DrawModel(flags)
        if not shrunk and hb then
            shrunk = true
            -- (to almost nothing, never to nothing: a bone shrunk to nothing has lost its direction too)
            body:ManipulateBoneScale(hb, Vector(0.01, 0.01, 0.01))
        end
    end
    heads[f] = body
    f.lcModel = model
    return f
end

-- every frame, each head goes where its body is (so it is drawn when he is in view), and its bones are built afresh
hook.Add("Think", "LivingCityHeadsFollow", function()
    for f, body in pairs(heads) do
        if not IsValid(f) then heads[f] = nil
        elseif IsValid(body) and not (body.IsDormant and body:IsDormant()) then
            f:SetPos(body:GetPos())
            f:SetAngles(body:GetAngles())
            if f.InvalidateBoneCache then f:InvalidateBoneCache() end
        end
    end
end)

local function Dress(npc, model)
    local f = LC_CL.HeadOn(npc, model)
    if not f then return end
    faces[npc] = f
end

hook.Add("Think", "LivingCityOldTimerFace", function()
    local now = CurTime()
    if now < nextLook then return end
    nextLook = now + 1
    local model = GetGlobal2String("lc_oldtimer_face", "")
    local usable = LC_CL.OldTimerFaceUsable(model)
    -- forget anyone who's gone, isn't him any more, or wears a face we no longer use
    for npc, f in pairs(faces) do
        if not IsValid(npc) or not npc:GetNW2Bool("lc_oldtimer", false) or not usable or not IsValid(f) or f.lcModel ~= model then Restore(npc) end
    end
    if not usable then return end
    for _, npc in ipairs(ents.FindByClass("npc_citizen")) do
        if npc:GetNW2Bool("lc_oldtimer", false) and not faces[npc] then Dress(npc, model) end
    end
end)
