--[[
    Living City (client): gas masks on faces, and a hand to the face

    The owner, 13 November: "I kind of hope it might be possible to extract the
    mask portion of the metrocop model and have it as an attachable entity onto
    the face of an NPC/player". Without cutting a new model, the Metrocop's own
    model is drawn on the wearer with every bone but the head folded away, so
    only his helmet and mask show, on the wearer's head and moving with it.
    (A mask on its own would need the model cut apart and rebuilt on a PC.)

    And the hand: a flashbanged NPC covers their eyes with their left hand, and
    anyone in the gas covers their mouth with it (NW2 lc_handface "eyes" or
    "mouth", until lc_handface_until; sv_livingcity_gasmask.lua). Bone by
    bone, on top of whatever else they're doing, like the cuffed pose.

    To adjust by eye in the game (your own client, saved):
      lc_gasmask_show 1/0
      lc_gasmask_fit "forward right up scale"   the mask on the head
      lc_handface_eyes  "raise in twist bend hand"   degrees, the left arm
      lc_handface_mouth "raise in twist bend hand"
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_gasmask_show", "1", true, false, "Show gas masks on people wearing them, and hands over eyes and mouths")
local cvFit = CreateClientConVar("lc_gasmask_fit", "0 0 0 1.08", true, false, "The gas mask on the head: forward, right, up (units) and size")
local cvEyes = CreateClientConVar("lc_handface_eyes", "-80 -30 20 -120 10", true, false, "Left hand over the eyes, in degrees: upper arm raised, in, turned, elbow bend, wrist")
local cvMouth = CreateClientConVar("lc_handface_mouth", "-65 -30 20 -125 15", true, false, "Left hand over the mouth, in degrees: upper arm raised, in, turned, elbow bend, wrist")

local MASK_MODEL = "models/police.mdl"
local HEAD = "ValveBiped.Bip01_Head1"
local ARM = { "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_Hand" }
local ZERO = Angle(0, 0, 0)

local function Nums(cv, n)
    local out = {}
    for w in string.gmatch(cv:GetString(), "[%-%d%.]+") do out[#out + 1] = tonumber(w) or 0 end
    for i = #out + 1, n do out[i] = 0 end
    return out
end

------------------------------------------------------------------------
-- The hand
------------------------------------------------------------------------

-- On the arms (CORE.md): yaw raises an arm forward (minus is up), pitch takes it out to the side (plus for the left
-- arm, so minus brings it in), roll twists it; the forearm bends at the elbow on yaw.
function LC_CL.HandFacePose(kind)
    local p = Nums(kind == "eyes" and cvEyes or cvMouth, 5)
    return {
        [ARM[1]] = Angle(p[2], p[1], p[3]),
        [ARM[2]] = Angle(0, p[4], 0),
        [ARM[3]] = Angle(0, p[5], 0),
    }
end

function LC_CL.HandFace(e)
    if not IsValid(e) or (e.Alive and not e:Alive()) then return nil end
    if e:GetNW2Float("lc_handface_until", 0) <= CurTime() then return nil end
    local k = e:GetNW2String("lc_handface", "")
    return (k == "eyes" or k == "mouth") and k or nil
end

local posed = {} -- [ent] = kind
local function SetPose(e, pose)
    if not e.LookupBone or not e.ManipulateBoneAngles then return end
    for name, ang in pairs(pose) do
        local b = e:LookupBone(name)
        if b then e:ManipulateBoneAngles(b, ang) end
    end
end
local function Unpose(e)
    posed[e] = nil
    if not IsValid(e) then return end
    -- (a cuffed person's arms are the cuffs' to turn: leave them be)
    if LC_CL.IsCuffed and LC_CL.IsCuffed(e) then return end
    SetPose(e, { [ARM[1]] = ZERO, [ARM[2]] = ZERO, [ARM[3]] = ZERO })
end

------------------------------------------------------------------------
-- The mask
------------------------------------------------------------------------

local masks = {} -- [ent] = the clientside model drawn on them
local wearing = {}

local function MaskFor(e)
    local m = masks[e]
    if IsValid(m) then return m end
    if not ClientsideModel then return nil end
    m = ClientsideModel(MASK_MODEL, RENDERGROUP_OPAQUE)
    if not IsValid(m) then return nil end
    m:SetNoDraw(true)
    m.lcHead = m.LookupBone and m:LookupBone(HEAD)
    -- every bone but the head folded into the head, so only the helmet and mask are left to see
    if m.AddCallback then m:AddCallback("BuildBonePositions", function(self, n)
        local wearer = self.lcWearer
        if not IsValid(wearer) or not self.lcHead then return end
        local wb = wearer:LookupBone(HEAD)
        local wm = wb and wearer:GetBoneMatrix(wb)
        if not wm then return end
        local fit = Nums(cvFit, 4)
        local head = Matrix()
        head:Set(wm)
        head:Translate(Vector(fit[1], -fit[2], fit[3]))
        head:Scale(Vector(1, 1, 1) * (fit[4] ~= 0 and fit[4] or 1))
        local gone = Matrix()
        gone:Set(wm)
        gone:Scale(Vector(0.001, 0.001, 0.001))
        for i = 0, n - 1 do
            if i == self.lcHead then self:SetBoneMatrix(i, head) else self:SetBoneMatrix(i, gone) end
        end
    end) end
    masks[e] = m
    return m
end

local function DropMask(e)
    if IsValid(masks[e]) then masks[e]:Remove() end
    masks[e] = nil
end

------------------------------------------------------------------------
-- Who, four times a second
------------------------------------------------------------------------

local nextLook = 0
hook.Add("Think", "LivingCityGasMask", function()
    local now = CurTime()
    if now < nextLook then return end
    nextLook = now + 0.25
    local on = cvShow:GetBool()
    local hands, wear = {}, {}
    if on then
        local function Look(e)
            if not IsValid(e) then return end
            local k = LC_CL.HandFace(e)
            if k then hands[e] = k end
            if e:GetNW2Bool("lc_gasmask_on", false) and (not e.Alive or e:Alive()) then wear[e] = true end
        end
        for _, e in ipairs(player.GetAll()) do Look(e) end
        for _, e in ipairs(ents.FindByClass("npc_*")) do Look(e) end
    end
    for e, k in pairs(hands) do
        if not (LC_CL.IsCuffed and LC_CL.IsCuffed(e)) then
            SetPose(e, LC_CL.HandFacePose(k)) -- (again each time: another pose may have turned the arm back)
            posed[e] = k
        end
    end
    for e in pairs(posed) do if not hands[e] then Unpose(e) end end
    for e in pairs(masks) do if not wear[e] then DropMask(e) end end
    wearing = wear
end)

hook.Add("PostDrawOpaqueRenderables", "LivingCityGasMask", function(depth, sky)
    if sky or next(wearing) == nil then return end
    local me = LocalPlayer()
    for e in pairs(wearing) do
        if IsValid(e) and not (e.IsDormant and e:IsDormant()) and not (e == me and not (me.ShouldDrawLocalPlayer and me:ShouldDrawLocalPlayer())) then
            local m = MaskFor(e)
            local hb = e.LookupBone and e:LookupBone(HEAD)
            if IsValid(m) and hb then
                local pos = e.GetBonePosition and e:GetBonePosition(hb)
                if pos then
                    m.lcWearer = e
                    m:SetPos(pos)
                    if m.SetRenderBounds then m:SetRenderBounds(Vector(-40, -40, -40), Vector(40, 40, 40)) end
                    if m.InvalidateBoneCache then m:InvalidateBoneCache() end
                    if m.SetupBones then m:SetupBones() end
                    m:DrawModel()
                end
            end
        end
    end
end)

-- Your own mask on, in your own view: the edge of the visor, and your breathing through the filter.
local breathAt = 0
hook.Add("HUDPaint", "LivingCityGasMaskView", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() or not me:GetNW2Bool("lc_gasmask_on", false) or (me.ShouldDrawLocalPlayer and me:ShouldDrawLocalPlayer()) then return end
    local w, h = ScrW(), ScrH()
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h * 0.06)
    surface.DrawRect(0, h * 0.94, w, h * 0.06)
    surface.DrawRect(0, 0, w * 0.05, h)
    surface.DrawRect(w * 0.95, 0, w * 0.05, h)
    draw.SimpleTextOutlined("GAS MASK ON", "DermaDefaultBold", w * 0.5, h * 0.06 + 14, Color(170, 210, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    if CurTime() > breathAt then
        breathAt = CurTime() + 2.6
        surface.PlaySound("player/breathe1.wav")
    end
end)
