--[[
    Living City (shared): a barnacle lifts the player it has caught.

    On a multiplayer server Half-Life 2's barnacle catches a player (the tongue
    sticks, the sound plays) and then never pulls them up: the game moves the
    player back down between the barnacle's pulls (the owner, 22 November: "their
    tongues stick to me and they make the sound, they just don't pull me up").
    So the server notes which barnacle holds whom, and the player's own movement
    (on both sides, so it is smooth) carries them up to its mouth. If the barnacle
    then does not bite by itself, the server bites for it. Kill the barnacle, or
    have someone kill it, and you drop.
]]

LC = LC or {}

local HELD = EFL_IS_BEING_LIFTED_BY_BARNACLE or 1048576
local PULL = 80 -- (units a second, about Half-Life 2's own)
local MOUTH = 94 -- (the player's feet this far under the barnacle: their eyes at its mouth)
local zero = Vector(0, 0, 0)

-- Where a held player's feet should be next, given where they are and where the barnacle hangs.
function LC.BarnacleStep(pos, mouth, dt)
    local want = Vector(mouth.x, mouth.y, mouth.z - MOUTH)
    local d = want - pos
    local len = d:Length()
    local step = PULL * dt
    if len <= step or len < 0.01 then return want, true end
    return pos + d * (step / len), false
end

hook.Add("Move", "LivingCityBarnacleLift", function(ply, mv)
    local b = ply:GetNW2Entity("lc_barnacle")
    if not IsValid(b) then return end
    local pos = mv:GetOrigin()
    local to = LC.BarnacleStep(pos, b:GetPos(), FrameTime())
    local tr = util.TraceHull({ start = pos, endpos = to, mins = ply:OBBMins(), maxs = ply:OBBMaxs(), mask = MASK_PLAYERSOLID,
        filter = function(e) return e ~= ply and e ~= b end })
    if tr and tr.HitPos and not tr.StartSolid then to = tr.HitPos end
    mv:SetOrigin(to)
    mv:SetVelocity(zero)
    return true
end)

if CLIENT then return end

local function HolderOf(ply)
    local best, bestD
    local pos = ply:GetPos()
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("npc_barnacle") or ents.FindByClass("npc_barnacle")) do
        if IsValid(b) and b:Health() > 0 then
            if b.GetEnemy and b:GetEnemy() == ply then return b end
            local bp = b:GetPos()
            local flat = math.sqrt((bp.x - pos.x) ^ 2 + (bp.y - pos.y) ^ 2)
            if bp.z > pos.z and flat < 96 and (not bestD or flat < bestD) then best, bestD = b, flat end
        end
    end
    return best
end

-- Ten times a second: who is held, by which barnacle; and the bite, if the barnacle never bites.
function LC.BarnacleHoldTick()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        local held = ply:Alive() and ply.IsEFlagSet and ply:IsEFlagSet(HELD) or false
        local b = held and HolderOf(ply) or nil
        if IsValid(b) then
            if ply:GetNW2Entity("lc_barnacle") ~= b then
                ply:SetNW2Entity("lc_barnacle", b)
                ply.lcBarnHealth, ply.lcBarnSince = ply:Health(), nil
            end
            local top = b:GetPos().z - MOUTH
            if ply:GetPos().z >= top - 6 then
                if ply:Health() < (ply.lcBarnHealth or 0) then ply.lcBarnSince = now end -- (it bites by itself)
                ply.lcBarnHealth = ply:Health()
                ply.lcBarnSince = ply.lcBarnSince or now
                if now - ply.lcBarnSince >= 2 then
                    ply.lcBarnSince = now - 1 -- (then once a second)
                    ply:TakeDamage(20, b, b)
                    if b.EmitSound then b:EmitSound("npc/barnacle/barnacle_crunch" .. math.random(2, 3) .. ".wav", 75) end
                    ply.lcBarnHealth = ply:Health()
                end
            end
        elseif IsValid(ply:GetNW2Entity("lc_barnacle")) or ply.lcBarnSince then
            ply:SetNW2Entity("lc_barnacle", NULL)
            ply.lcBarnSince, ply.lcBarnHealth = nil, nil
        end
    end
end

timer.Create("LivingCityBarnacleHold", 0.1, 0, function()
    local ok, err = LC.Try(LC.BarnacleHoldTick)
    if not ok and LC.Error then LC.Error("barnacle hold", err) end
end)
