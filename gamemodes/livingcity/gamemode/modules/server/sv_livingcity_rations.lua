--[[
    Living City: "ration units are being deducted"

    When the Resistance acts (a raid on a checkpoint, the lambda on a wall
    once a unit or scanner has seen it, rebel ground spreading), the PA charges the people nearby with tolerating
    noncompliance, and it's real: every citizen within lc_ration_dock_radius
    (1500) of it loses their next ration allocation. They're told on the spot,
    and again, with the reason, when they go to collect. Units, Overwatch and
    the Resistance's own fighters are not docked (the fighters have no
    ration card to dock).

      lc_ration_dock 0/1, lc_ration_dock_radius (1500), lc_ration_dock_height (150)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_ration_dock", "1", FLAGS, "Citizens near Resistance activity lose their next ration")
local cvRadius = CreateConVar("lc_ration_dock_radius", "1500", FLAGS, "How close to Resistance activity costs you your next ration")

local cvHeight = CreateConVar("lc_ration_dock_height", "150", FLAGS, "How many Civil Protection units above or below Resistance activity (about one floor) still costs you your next ration")

local lastPA = 0

-- Everyone near pos loses their next ration, and the PA says so.
function LC.DockRations(pos, why)
    if not cvOn:GetBool() or not pos then return {} end
    local r, hgt = cvRadius:GetFloat(), cvHeight:GetFloat()
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    local docked = {}
    for _, p in ipairs(player.GetAll()) do
        local exempt = not p:Alive() or LC.PlayerIsCP(p) or (LC.PlayerIsZombie and LC.PlayerIsZombie(p))
            or (LC.PlayerIsHunted and LC.PlayerIsHunted(p))
        if not exempt and p:GetPos():DistToSqr(pos) < r * r and math.abs(p:GetPos().z - pos.z) <= hgt then
            p.lcRationDocked = { why = why, where = where, at = CurTime() }
            p:SetNW2String("lc_ration_docked", why)
            docked[#docked + 1] = p
            p:ChatPrint("[Rations] You were near " .. why .. (where ~= "" and (" " .. where) or "") .. ". Your next ration allocation is forfeit.")
        end
    end
    local now = CurTime()
    if now - lastPA > 60 and LC.Announce then
        lastPA = now
        LC.Announce("ambient", "npc/overwatch/cityvoice/f_rationunitsdeduct_3_spkr.wav",
            "Residents near " .. why .. (where ~= "" and (" " .. where) or "") .. " lose their next ration allocation.")
    end
    hook.Run("LivingCityRationsDocked", pos, why, docked)
    return docked
end

hook.Add("LivingCitySkirmish", "LivingCityRationDock", function(kind, sk)
    if kind == "raid" and sk and sk.target then
        timer.Simple(20, function() LC.DockRations(sk.target, "a Resistance attack") end)
    end
end)
-- Graffiti costs the block its rations only once the Combine knows about it:
-- a unit or scanner sees it go up, or comes across it later. Paint nobody
-- has found costs nobody anything.
local function SeesTag(t)
    local spot = t.pos + (t.normal or Vector(0, 0, 0)) * 8
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.role == "cop" or st.role == "soldier" or st.role == "scanner") then
            local eye = npc.EyePos and npc:EyePos() or (npc:GetPos() + Vector(0, 0, 60))
            if eye:DistToSqr(spot) < 700 * 700 then
                local tr = util.TraceLine({ start = eye, endpos = spot, mask = MASK_SOLID_BRUSHONLY })
                if not (tr and tr.Hit and tr.Fraction < 0.97) then return true end
            end
        end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.PlayerIsCP(p) and p:EyePos():DistToSqr(spot) < 600 * 600 then
            local tr = util.TraceLine({ start = p:EyePos(), endpos = spot, mask = MASK_SOLID_BRUSHONLY })
            if not (tr and tr.Hit and tr.Fraction < 0.97) then return true end
        end
    end
    return false
end
LC.SecuritySeesTag = SeesTag

local function Found(t)
    t.found = true
    LC.DockRations(t.pos, "Resistance graffiti")
end

hook.Add("LivingCityTagged", "LivingCityRationDock", function(ply, t)
    if not (t and t.pos) then return end
    if (LC.SeenBySecurity and LC.SeenBySecurity(ply, 900)) or SeesTag(t) then Found(t) end
end)

timer.Create("LivingCityTagsFound", 5, 0, function()
    if not cvOn:GetBool() then return end
    for _, t in ipairs(LC.Tags or {}) do
        if not t.found and t.pos then
            local ok, seen = pcall(SeesTag, t)
            if ok and seen then Found(t) end
        end
    end
end)
hook.Add("LivingCityTerritoryGrew", "LivingCityRationDock", function(seed, z)
    if z and z.kind == "rebel" then LC.DockRations(z.pos, "Resistance-held ground") end
end)
