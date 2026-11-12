--[[
    Living City (client): cuffed, as others see it

    The owner, 12 November: "is it possible to apply a 'cuffed' animation for
    NPCs and the players? even a primitive model for cuffs, even if just two
    metal circles wrapped around the wrists? hands would be cuffed behind their
    backs, so no need for viewmodel".

    Anyone cuffed (a player: NW2 lc_tied; a citizen or rebel: NW2 lc_cuffed)
    has their arms turned behind their back, bone by bone, on top of whatever
    they are doing (standing, walking, being dragged), and two steel rings are
    drawn round their wrists with a short link between. While they work at
    the cuffs (a player struggling or picking them, a citizen with a hidden
    pick) the wrists twist and thumb and forefinger fiddle. Nothing is drawn in
    your own first person view.

    To adjust by eye in the game (your own client, saved):
      lc_cuffs_show 1/0
      lc_cuff_pose "back in twist bend hand"   degrees: upper arm back, upper
                   arm in towards the spine, upper arm twist, elbow bend, wrist
      lc_cuff_ring "width thickness"           the rings, as a scale of the tube
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_cuffs_show", "1", true, false, "Show cuffed people with their hands behind their back, and the cuffs")
local cvPose = CreateClientConVar("lc_cuff_pose", "24 10 35 -28 20", true, false, "The cuffed pose, in degrees: upper arm back, in, twist, elbow bend, wrist")
local cvRing = CreateClientConVar("lc_cuff_ring", "0.075 0.035", true, false, "The cuffs' rings: width and thickness (a scale)")

local RING_MODEL = "models/hunter/tubes/tube1x1x1.mdl"
local STEEL = Color(150, 155, 165)
local FAR = 1800

local posed = {}   -- [ent] = true: bones turned
local fiddling     -- (further down: those working at their cuffs this frame)
local rings = {}   -- two clientside models, shared
local chainMat

local function Nums(cv, n)
    local out = {}
    for w in string.gmatch(cv:GetString(), "[%-%d%.]+") do out[#out + 1] = tonumber(w) or 0 end
    for i = #out + 1, n do out[i] = 0 end
    return out
end

function LC_CL.IsCuffed(e)
    return IsValid(e) and (e:GetNW2Bool("lc_tied", false) or e:GetNW2Bool("lc_cuffed", false)) and (not e.Alive or e:Alive())
end

-- The pose: { bone name = Angle }. On the arms, yaw swings an arm forward and back, pitch out to the side (minus for
-- the right arm, plus for the left), roll twists it; a forearm bends at the elbow on yaw.
function LC_CL.CuffPose()
    local p = Nums(cvPose, 5)
    local back, inw, twist, bend, hand = p[1], p[2], p[3], p[4], p[5]
    return {
        ["ValveBiped.Bip01_R_UpperArm"] = Angle(inw, back, -twist),
        ["ValveBiped.Bip01_L_UpperArm"] = Angle(-inw, back, twist),
        ["ValveBiped.Bip01_R_Forearm"] = Angle(0, bend, 0),
        ["ValveBiped.Bip01_L_Forearm"] = Angle(0, bend, 0),
        ["ValveBiped.Bip01_R_Hand"] = Angle(0, hand, 0),
        ["ValveBiped.Bip01_L_Hand"] = Angle(0, hand, 0),
    }
end

local function SetPose(e, pose)
    if not e.LookupBone or not e.ManipulateBoneAngles then return end
    for name, ang in pairs(pose) do
        local b = e:LookupBone(name)
        if b then e:ManipulateBoneAngles(b, ang) end
    end
end

local ZERO = Angle(0, 0, 0)
local function Unpose(e)
    posed[e] = nil
    if not IsValid(e) then return end
    local z = {}
    for name in pairs(LC_CL.CuffPose()) do z[name] = ZERO end
    SetPose(e, z)
end

-- Who is cuffed right now (looked for twice a second), and their arms.
local list, nextLook, lastPose = {}, 0, ""
fiddling = {}
hook.Add("Think", "LivingCityCuffed", function()
    local now = CurTime()
    if now < nextLook then return end
    nextLook = now + 0.5
    local on = cvShow:GetBool()
    local found = {}
    if on then
        for _, e in ipairs(player.GetAll()) do if LC_CL.IsCuffed(e) then found[e] = true end end
        for _, e in ipairs(ents.FindByClass("npc_*")) do if LC_CL.IsCuffed(e) then found[e] = true end end
    end
    local pose = LC_CL.CuffPose()
    local changed = cvPose:GetString() ~= lastPose
    lastPose = cvPose:GetString()
    for e in pairs(found) do
        -- (set again each time: other poses, an act or a dream, may have turned the same bones back)
        if not fiddling[e] then SetPose(e, pose) end
        posed[e] = true
    end
    for e in pairs(posed) do if not found[e] then Unpose(e) end end
    list = found
    if changed then for e in pairs(found) do if not fiddling[e] then SetPose(e, pose) end end end
end)

-- Working at the cuffs (the owner: "a squirming animation where the hands that are cuffed are shuffling around
-- pointer-finger/thumb are fiddling with the cuffs"): a cuffed player busy with a task (working at them, or picking
-- them: sv_livingcity_cp.lua, sv_livingcity_patdown.lua), or a citizen with a hidden pick (NW2 lc_cuff_work_until).
function LC_CL.CuffWorking(e)
    local now = CurTime()
    if e:GetNW2Float("lc_cuff_work_until", 0) > now then return true end
    return e:IsPlayer() and e:GetNW2Bool("lc_tied", false) and e:GetNW2Float("lcu_pick_until", 0) > now
end

local FINGERS = { "Finger0", "Finger01", "Finger1", "Finger11", "Finger12" } -- (thumb, then the index finger's joints)

-- Every frame, only for those at it: the wrists twist against each other, the shoulders work, thumb and finger pick.
hook.Add("Think", "LivingCityCuffSquirm", function()
    if next(list) == nil and next(fiddling) == nil then return end
    local t = CurTime()
    local base
    for e in pairs(list) do
        if IsValid(e) and LC_CL.CuffWorking(e) and e.LookupBone then
            base = base or LC_CL.CuffPose()
            fiddling[e] = true
            local seed = e:EntIndex() * 1.7
            for side, sign in pairs({ R = 1, L = -1 }) do
                local a = t * 5.5 + seed + (side == "L" and 1.9 or 0)
                local hand = base["ValveBiped.Bip01_" .. side .. "_Hand"]
                local b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_Hand")
                if b then e:ManipulateBoneAngles(b, Angle(math.sin(a) * 14 * sign, hand.y + math.sin(a * 0.7) * 10, math.sin(a * 1.3) * 22)) end
                local fore = base["ValveBiped.Bip01_" .. side .. "_Forearm"]
                b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_Forearm")
                if b then e:ManipulateBoneAngles(b, Angle(0, fore.y + math.sin(a * 0.5) * 5, math.sin(a * 0.9) * 8 * sign)) end
                local up = base["ValveBiped.Bip01_" .. side .. "_UpperArm"]
                b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_UpperArm")
                if b then e:ManipulateBoneAngles(b, Angle(up.p, up.y + math.sin(a * 0.4) * 3, up.r + math.sin(a * 0.6) * 4)) end
                for i, f in ipairs(FINGERS) do
                    b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_" .. f)
                    if b then e:ManipulateBoneAngles(b, Angle(0, -18 - math.abs(math.sin(a * 1.6 + i)) * 30, math.sin(a + i) * 6)) end
                end
            end
        elseif fiddling[e] then
            fiddling[e] = nil
            if IsValid(e) and e.LookupBone then
                for _, side in ipairs({ "R", "L" }) do
                    for _, f in ipairs(FINGERS) do
                        local b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_" .. f)
                        if b then e:ManipulateBoneAngles(b, ZERO) end
                    end
                end
                SetPose(e, LC_CL.CuffPose())
            end
        end
    end
    for e in pairs(fiddling) do
        if not list[e] then
            fiddling[e] = nil
            if IsValid(e) and e.LookupBone then
                for _, side in ipairs({ "R", "L" }) do
                    for _, f in ipairs(FINGERS) do
                        local b = e:LookupBone("ValveBiped.Bip01_" .. side .. "_" .. f)
                        if b then e:ManipulateBoneAngles(b, ZERO) end
                    end
                end
            end
        end
    end
end)

local function Ring(i)
    local r = rings[i]
    if IsValid(r) then return r end
    if not ClientsideModel then return nil end
    r = ClientsideModel(RING_MODEL, RENDERGROUP_OPAQUE)
    if not IsValid(r) then return nil end
    r:SetNoDraw(true)
    r:SetMaterial("models/shiny")
    r:SetColor(STEEL)
    rings[i] = r
    return r
end

-- The rings round the wrists, and the link between them.
hook.Add("PostDrawOpaqueRenderables", "LivingCityCuffed", function(depth, sky)
    if sky or not cvShow:GetBool() or next(list) == nil then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local eye = EyePos()
    local size = Nums(cvRing, 2)
    for e in pairs(list) do
        if IsValid(e) and not (e == me and not me:ShouldDrawLocalPlayer()) and not e:IsDormant() and e:GetPos():DistToSqr(eye) < FAR * FAR then
            local wrists = {}
            for i, name in ipairs({ "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand" }) do
                local b = e:LookupBone(name)
                local pos, ang
                if b then pos, ang = e:GetBonePosition(b) end
                local r = pos and Ring(i)
                if r then
                    -- (the tube's hole runs up its own height: stood along the forearm, just above the hand)
                    local a = Angle(ang.p, ang.y, ang.r)
                    a:RotateAroundAxis(a:Right(), 90)
                    local at = pos - ang:Forward() * 1.2
                    local m = Matrix()
                    m:Scale(Vector(size[1], size[1], size[2]))
                    r:EnableMatrix("RenderMultiply", m)
                    r:SetPos(at)
                    r:SetAngles(a)
                    render.SetColorModulation(STEEL.r / 255, STEEL.g / 255, STEEL.b / 255)
                    r:DrawModel()
                    render.SetColorModulation(1, 1, 1)
                    wrists[#wrists + 1] = at
                end
            end
            if #wrists == 2 and render.DrawBeam then
                chainMat = chainMat or Material("cable/cable2")
                render.SetMaterial(chainMat)
                render.DrawBeam(wrists[1], wrists[2], 0.5, 0, 1, STEEL)
            end
        end
    end
end)
