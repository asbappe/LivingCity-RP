--[[
    Living City (client): the old-timer's face (sv_livingcity_oldtimer.lua)

    His body stays an ordinary citizen in citizen's clothes; his head is Lost
    Coast's old fisherman (lc_oldtimer_face). Half-Life 2 can't swap heads,
    so this is the usual trick: the fisherman is laid over the citizen,
    following his every bone (bone merge), with everything but his head and
    neck shrunk to nothing, and the citizen's own head shrunk away beneath it
    (to 0.01, with the fisherman's head put back to full size after the
    merge: at 0 the merge shrank the fisherman's head too, 15 November).

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

local function Restore(npc)
    local f = faces[npc]
    if IsValid(f) then f:Remove() end
    faces[npc] = nil
    if IsValid(npc) then
        local hb = npc:LookupBone("ValveBiped.Bip01_Head1")
        if hb then npc:ManipulateBoneScale(hb, Vector(1, 1, 1)) end
    end
end

-- That head laid over any citizen-boned model (an NPC, or a model on this screen only such as the Colonel):
-- returns the head, or nil. The body's own head is shrunk away beneath it.
function LC_CL.HeadOn(body, model, group)
    if util.PrecacheModel then util.PrecacheModel(model) end
    local f = ClientsideModel(model, group or RENDERGROUP_OPAQUE)
    if not IsValid(f) then return nil end
    f:SetParent(body)
    f:AddEffects(EF_BONEMERGE)
    f:SetPos(body:GetPos())
    local keep = {}
    for i = 0, (f:GetBoneCount() or 0) - 1 do
        if Keep(f:GetBoneName(i)) then keep[#keep + 1] = i else f:ManipulateBoneScale(i, Vector(0, 0, 0)) end
    end
    -- The body's own head is shrunk to almost nothing, never to nothing at all: a bone-merged model copies the
    -- body's bones as they are, scale and all, so the fisherman's head shrank away with it and he had no head
    -- (the owner, 15 November: "citizen old timer has no head"). Once his bones are copied, his head and neck
    -- are put back to full size (a bone shrunk to nothing has lost its direction too, so 0.01, not 0).
    if f.AddCallback then
        f:AddCallback("BuildBonePositions", function(e)
            for _, i in ipairs(keep) do
                local m = e:GetBoneMatrix(i)
                if m then m:SetScale(Vector(1, 1, 1)) e:SetBoneMatrix(i, m) end
            end
        end)
    end
    local hb = body:LookupBone("ValveBiped.Bip01_Head1")
    if hb then body:ManipulateBoneScale(hb, Vector(0.01, 0.01, 0.01)) end
    f.lcModel = model
    return f
end

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
