--[[
    Living City: Resistance supplies thrown down from a roof

    The owner, 21 November, approving valve-npc-supply-drop (Valve's d3_c17_03 and d3_c17_12: a rebel on
    a roof calls down and throws crates; resupply comes between waves, as things in the world).

      When      a wave of units is wiped out while the Resistance hold ground (Take ground,
                LC.HoldWaveTick's onWiped), twice a hold at most.
      Where     the map's own roof spots first (an info_target named lc_drop_<anything>) within
                LC.RoofDropReach of the fight; else a spot of the map's navigation at least
                LC.RoofDropRise above the fight, near it, with a clear line down to it. Neither:
                nothing comes.
      What      a rebel appears there, calls "heads up", and throws down LC.RoofDropThrows bundles,
                each a box of rounds and a bandage or a health vial (lc_item: E picks them up), at
                whoever is holding the ground. He goes after a while.
      Nothing on screen: the call and the boxes are the message.
]]

if CLIENT then return end

LC = LC or {}
LC.RoofDropReach, LC.RoofDropRise, LC.RoofDropThrows, LC.RoofDropStay = 1500, 128, 2, 25
local AMMO = { "ammo_smg", "ammo_pistol", "ammo_buckshot" }
local HEAL = { "bandage", "health_vial" }
local UP = Vector(0, 0, 40)

local function Clear(a, b)
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID_BRUSHONLY })
    return not tr or not tr.Hit or (tr.Fraction or 0) > 0.97
end

-- A roof edge over the fight. -> a position, or nil.
function LC.RoofDropSpot(center)
    local best, bd
    for _, e in ipairs(ents.FindByName("lc_drop_*")) do
        local d = IsValid(e) and e:GetPos():DistToSqr(center)
        if d and d < LC.RoofDropReach ^ 2 and (not bd or d < bd) then best, bd = e:GetPos(), d end
    end
    if best then return best end
    for _, nd in ipairs(LC.Fallback or {}) do
        local p = (istable(nd) and nd.pos) or nd -- (a nav spot, or a bare position)
        if p and p.z and p.z >= center.z + LC.RoofDropRise then
            local flat = Vector(p.x - center.x, p.y - center.y, 0):Length()
            if flat > 200 and flat < 1200 and Clear(center + UP, p + UP) then
                local d = flat
                if not bd or d < bd then best, bd = p, d end
            end
        end
    end
    return best
end

local function Toss(from, to, id)
    local t = 1.1
    local d = to - from
    local vel = Vector(d.x / t, d.y / t, (d.z + 0.5 * 600 * t * t) / t)
    return LC.SpawnWorldItem and LC.SpawnWorldItem(id, from + Vector(0, 0, 50), Angle(0, math.random(0, 359), 0), vel)
end

-- Throw supplies down to whoever is holding center. -> the thrower, or nil (nowhere to throw from).
function LC.RoofResupply(center, holders)
    if not LC.SpawnRebel then return nil end
    local spot = LC.RoofDropSpot(center)
    if not spot then return nil end
    local npc, st = LC.SpawnRebel(spot + Vector(0, 0, 4), nil)
    if not (IsValid(npc) and st) then return nil end
    st.unmanaged, st.thrower = true, true
    st.expires = CurTime() + LC.RoofDropStay
    npc:EmitSound("vo/npc/" .. (st.gender or "male") .. "01/headsup0" .. math.random(1, 2) .. ".wav", 90)
    local function Target()
        local live = {}
        for _, p in ipairs(holders or {}) do if IsValid(p) and p:Alive() then live[#live + 1] = p end end
        local p = live[math.random(math.max(1, #live))]
        return IsValid(p) and p:GetPos() or center
    end
    for i = 1, LC.RoofDropThrows do
        timer.Simple(1 + (i - 1) * 2.5, function()
            if not (IsValid(npc) and npc:Health() > 0) then return end
            local to = Target() + Vector(math.random(-60, 60), math.random(-60, 60), 0)
            Toss(npc:GetPos(), to, AMMO[math.random(#AMMO)])
            Toss(npc:GetPos(), to + Vector(20, 0, 0), HEAL[math.random(#HEAL)])
        end)
    end
    timer.Simple(LC.RoofDropStay, function()
        if IsValid(npc) and npc:Health() > 0 and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + UP)) then
            LC.NPCs[npc] = nil
            npc:Remove()
        end
    end)
    return npc
end
