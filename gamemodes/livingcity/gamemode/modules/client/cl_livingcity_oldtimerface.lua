--[[
    Living City (client): the old-timer's face (sv_livingcity_oldtimer.lua)

    His body stays an ordinary citizen in citizen's clothes; his head is Lost
    Coast's old fisherman (lc_oldtimer_face). Half-Life 2 can't swap heads,
    so this is the usual trick: the fisherman is laid over the citizen,
    following his every bone (bone merge), with everything but his head and
    neck shrunk to nothing, and the citizen's own head shrunk away beneath it.

    Only on this player's screen, and only if they have the model (Lost
    Coast installed): without it, the citizen keeps his own face, never an
    error model.
]]

LC_CL = LC_CL or {}

local faces = {} -- [npc] = the head model laid over him
local nextLook = 0

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

local function Dress(npc, model)
    local f = ClientsideModel(model, RENDERGROUP_OPAQUE)
    if not IsValid(f) then return end
    f:SetParent(npc)
    f:AddEffects(EF_BONEMERGE)
    f:SetPos(npc:GetPos())
    for i = 0, (f:GetBoneCount() or 0) - 1 do
        if not Keep(f:GetBoneName(i)) then f:ManipulateBoneScale(i, Vector(0, 0, 0)) end
    end
    local hb = npc:LookupBone("ValveBiped.Bip01_Head1")
    if hb then npc:ManipulateBoneScale(hb, Vector(0, 0, 0)) end
    faces[npc] = f
    f.lcModel = model
end

hook.Add("Think", "LivingCityOldTimerFace", function()
    local now = CurTime()
    if now < nextLook then return end
    nextLook = now + 1
    local model = GetGlobal2String("lc_oldtimer_face", "")
    local usable = model ~= "" and util.IsValidModel(model)
    -- forget anyone who's gone, isn't him any more, or wears a face we no longer use
    for npc, f in pairs(faces) do
        if not IsValid(npc) or not npc:GetNW2Bool("lc_oldtimer", false) or not usable or not IsValid(f) or f.lcModel ~= model then Restore(npc) end
    end
    if not usable then return end
    for _, npc in ipairs(ents.FindByClass("npc_citizen")) do
        if npc:GetNW2Bool("lc_oldtimer", false) and not faces[npc] then Dress(npc, model) end
    end
end)
