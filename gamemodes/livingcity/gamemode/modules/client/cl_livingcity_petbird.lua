--[[
    Living City (client): a pet bird on someone's shoulder
    (sv_livingcity_status.lua, NW lc_pet_bird). A pigeon perched on the right
    shoulder, facing the way they face, bobbing now and then. Where it sits:
    lc_petbird_pos (forward, right, up from the shoulder).
]]

LC_CL = LC_CL or {}

local cvPos = GetConVar("lc_petbird_pos") or CreateConVar("lc_petbird_pos", "-1 3 5", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Where a pet bird sits on the shoulder: forward right up")
local birds = {} -- [ply] = clientside model

local function Nums()
    local v = {}
    for w in string.gmatch(cvPos and cvPos:GetString() or "", "%S+") do v[#v + 1] = tonumber(w) or 0 end
    return v[1] or -1, v[2] or 3, v[3] or 5
end

local function Bird(ply)
    local b = birds[ply]
    if IsValid(b) then return b end
    if not ClientsideModel then return nil end
    b = ClientsideModel("models/pigeon.mdl", RENDERGROUP_OPAQUE)
    if not IsValid(b) then return nil end
    b:SetNoDraw(true)
    local seq = b.LookupSequence and b:LookupSequence("Idle01")
    if seq and seq >= 0 and b.ResetSequence then b:ResetSequence(seq) end
    birds[ply] = b
    return b
end

function LC_CL.DrawPetBird(ply)
    if not IsValid(ply) or not ply:Alive() or not ply:GetNW2Bool("lc_pet_bird", false) then return end
    local bone = ply.LookupBone and ply:LookupBone("ValveBiped.Bip01_R_Clavicle")
    if not bone then return end
    local pos = ply:GetBonePosition(bone)
    if not pos then return end
    local b = Bird(ply)
    if not IsValid(b) then return end
    local f, r, u = Nums()
    local face = Angle(0, ply:EyeAngles().y, 0)
    local bob = math.max(0, math.sin(CurTime() * 2 + ply:EntIndex())) ^ 8 * 1.5 -- (now and then, a little hop)
    b:SetPos(pos + face:Forward() * f + face:Right() * r + face:Up() * (u + bob))
    b:SetAngles(face)
    if b.FrameAdvance then b:FrameAdvance() end
    b:DrawModel()
end
hook.Add("PostPlayerDraw", "LivingCityPetBird", LC_CL.DrawPetBird)

-- gone with whoever had it
timer.Create("LivingCityPetBirds", 5, 0, function()
    for ply, b in pairs(birds) do
        if not IsValid(ply) or not ply:GetNW2Bool("lc_pet_bird", false) then
            if IsValid(b) then b:Remove() end
            birds[ply] = nil
        end
    end
end)
LC_CL.PetBirds = birds
