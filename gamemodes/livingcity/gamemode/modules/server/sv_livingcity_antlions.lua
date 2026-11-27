--[[
    Living City: antlions while a thumper stands still (the owner's long-term list, 18 November, 5: "thumpers keep
    them off (the Combine's, which a saboteur can switch off), they come up through sand or soft ground"; and 27
    November, of the canal ring's four thumpers: "if the thumper on the west side of the canal is shut off, then that
    west end of the canal will have antlions spawning in at a small trickle ... at a random player/NPC in that part of
    the canal, until the thumper is turned back on", "one every 15 seconds with a max of 2 alive at a time").
    Only where a map has the thumper module (docs/dev/canal-modules.md). Every copy has names of its own:

      lc_thumper_head, lc_thumper2_head, ...    the thumper (prop_thumper). Its button stops and starts it (Disable, Enable).
      lc_thumper_area, lc_thumper2_area, ...    marks: the box they span is the stretch of canal it guards (the map
                                                generator's thumper_areas). Without them, 2000 round the thumper.
      lc_thumper_burrow, ...                    the burrow's mouth near it: where one comes up when no spot near anyone will do.

    While a thumper stands still, one antlion digs up every 15 seconds (the first 15 seconds after it stops) near
    someone in its stretch, a player or a person of the city chosen at random, and goes for them: never more than two
    of that thumper's out at once. Nobody in the stretch, nobody comes. Started again, no more come; the thumper drives
    off those near it (the game does that itself) and after a minute its antlions still alive dig themselves away.
    Nothing is written on anyone's screen. On a map without these names nothing here happens.
]]

LC = LC or {}
LC.Antlions = LC.Antlions or { stopped = {}, out = {}, calm = {} }
local A = LC.Antlions
A.calm = A.calm or {}

local GRACE, EVERY, OUT_MAX, REACH, CALM = 15, 15, 2, 2000, 60
local NEAR_MIN, NEAR_MAX, TRIES = 192, 448, 10
-- (what an antlion is never sent at: its own kind, and what flies, stands fixed or is too small to matter)
local NOT_PREY = { "antlion", "bullseye", "scanner", "manhack", "turret", "camera", "helicopter", "gunship", "dropship",
    "strider", "rollermine", "barnacle", "crow", "pigeon", "seagull", "headcrab", "cscanner" }

local function NameOf(e) return string.lower(tostring(e.GetName and e:GetName() or "")) end

-- "lc_thumper3_head" gives "lc_thumper3", the start of that copy's other names; anything else, nil.
function A.Prefix(e)
    if not IsValid(e) then return nil end
    return string.match(NameOf(e), "^(lc_thumper%d*)_head$")
end

function A.BurrowOf(thumper)
    local pre = A.Prefix(thumper) or "lc_thumper"
    for _, name in ipairs({ pre .. "_burrow", "lc_thumper_burrow" }) do
        local best, bd
        for _, t in ipairs(ents.FindByName and ents.FindByName(name) or {}) do
            if IsValid(t) then
                local d = t:GetPos():DistToSqr(thumper:GetPos())
                if d <= REACH * REACH and (not bd or d < bd) then best, bd = t, d end
            end
        end
        if best then return best end
    end
end

-- The stretch a thumper guards: the box its marks span (a little wider and lower, so the canal's floor and walls
-- are in it), or REACH round it on a map without them.
function A.AreaOf(thumper)
    local pre = A.Prefix(thumper)
    local lo, hi, n = nil, nil, 0
    for _, m in ipairs(pre and ents.FindByName and ents.FindByName(pre .. "_area") or {}) do
        if IsValid(m) then
            local p = m:GetPos()
            n = n + 1
            if not lo then
                lo, hi = Vector(p.x, p.y, p.z), Vector(p.x, p.y, p.z)
            else
                lo = Vector(math.min(lo.x, p.x), math.min(lo.y, p.y), math.min(lo.z, p.z))
                hi = Vector(math.max(hi.x, p.x), math.max(hi.y, p.y), math.max(hi.z, p.z))
            end
        end
    end
    if n >= 2 then return { lo = lo - Vector(48, 48, 64), hi = hi + Vector(48, 48, 16) } end
    return { center = thumper:GetPos(), r = REACH }
end

function A.Inside(area, pos)
    if area.lo then
        return pos.x >= area.lo.x and pos.x <= area.hi.x and pos.y >= area.lo.y and pos.y <= area.hi.y and pos.z >= area.lo.z and pos.z <= area.hi.z
    end
    return pos:DistToSqr(area.center) <= area.r * area.r
end

local function Prey(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return e:Alive() and not (e.GetMoveType and e:GetMoveType() == MOVETYPE_NOCLIP) end
    if not (e.IsNPC and e:IsNPC()) or e:Health() <= 0 then return false end
    local c = string.lower(e:GetClass())
    for _, w in ipairs(NOT_PREY) do
        if string.find(c, w, 1, true) then return false end
    end
    return true
end

-- Everyone in a stretch an antlion may be sent at: players, and the city's people and units.
function A.PreyIn(area)
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if Prey(p) and A.Inside(area, p:GetPos()) then out[#out + 1] = p end
    end
    local list = (area.lo and ents.FindInBox and ents.FindInBox(area.lo, area.hi)) or (area.center and ents.FindInSphere and ents.FindInSphere(area.center, area.r)) or ents.GetAll()
    for _, e in ipairs(list) do
        if IsValid(e) and not e:IsPlayer() and Prey(e) and A.Inside(area, e:GetPos()) then out[#out + 1] = e end
    end
    return out
end

-- Where one can dig up near someone: ground a few steps from them, in the same stretch, in the open (room for an
-- antlion), with no wall between them and it. Nil if ten tries find none.
function A.SpotNear(area, who)
    local base = who:GetPos()
    for _ = 1, TRIES do
        local a, d = math.Rand(0, math.pi * 2), math.Rand(NEAR_MIN, NEAR_MAX)
        local p = base + Vector(math.cos(a) * d, math.sin(a) * d, 0)
        local down = util.TraceLine({ start = p + Vector(0, 0, 64), endpos = p - Vector(0, 0, 256), mask = MASK_SOLID_BRUSHONLY })
        if down.Hit and not down.StartSolid and (not down.HitNormal or down.HitNormal.z >= 0.7) then
            local g = down.HitPos
            if A.Inside(area, g + Vector(0, 0, 8)) then
                local room = util.TraceHull({ start = g + Vector(0, 0, 8), endpos = g + Vector(0, 0, 9), mins = Vector(-20, -20, 0), maxs = Vector(20, 20, 64), mask = MASK_NPCSOLID })
                local wall = util.TraceLine({ start = base + Vector(0, 0, 40), endpos = g + Vector(0, 0, 40), mask = MASK_SOLID_BRUSHONLY })
                if not room.StartSolid and not room.Hit and not wall.Hit then return g end
            end
        end
    end
end

-- The map tells a thumper to stop or start: remembered here.
function A.Set(thumper, running)
    if not IsValid(thumper) then return end
    if running then
        if A.stopped[thumper] then
            A.stopped[thumper] = nil
            A.calm[thumper] = CurTime()
        end
    elseif not A.stopped[thumper] then
        A.calm[thumper] = nil
        A.stopped[thumper] = { since = CurTime(), nextAt = CurTime() + GRACE, area = A.AreaOf(thumper) }
    end
end

hook.Add("AcceptInput", "LivingCityAntlions", function(ent, input)
    if not IsValid(ent) then return end
    local what = string.lower(input or "")
    if (what ~= "enable" and what ~= "disable") or not A.Prefix(ent) then return end
    LC.Try(A.Set, ent, what == "enable")
end)

-- How many of one thumper's antlions are alive (all of them, without a thumper).
function A.Living(thumper)
    local n = 0
    for e, th in pairs(A.out) do
        if not (IsValid(e) and e:Health() > 0) then
            A.out[e] = nil
        elseif thumper == nil or th == thumper then
            n = n + 1
        end
    end
    return n
end

-- One antlion digging up at pos, for a thumper, going for who.
function A.Spawn(pos, thumper, who, jitter)
    local e = ents.Create("npc_antlion")
    if not IsValid(e) then return nil end
    local a, d = math.Rand(0, math.pi * 2), math.Rand(0, jitter or 0)
    e:SetPos(pos + Vector(math.cos(a) * d, math.sin(a) * d, 4))
    local yaw = math.random(0, 359)
    if IsValid(who) then
        local to = who:GetPos() - pos
        yaw = math.deg(math.atan2(to.y, to.x))
    end
    e:SetAngles(Angle(0, yaw, 0))
    e:SetKeyValue("startburrowed", "1")
    e:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE or 512))
    e:Spawn()
    if e.Activate then e:Activate() end
    if e.Fire then e:Fire("Unburrow", "", 0.1) end
    if IsValid(who) then
        if e.SetEnemy then e:SetEnemy(who) end
        if e.UpdateEnemyMemory then e:UpdateEnemyMemory(who, who:GetPos()) end
    end
    e.lcThumperAntlion = true
    A.out[e] = thumper or true
    return e
end

function A.Tick()
    local now = CurTime()
    for th, s in pairs(A.stopped) do
        if not IsValid(th) then
            A.stopped[th] = nil
        elseif now >= s.nextAt and A.Living(th) < OUT_MAX then
            local prey = A.PreyIn(s.area)
            if #prey > 0 then
                local who = prey[math.random(#prey)]
                local spot, jitter = A.SpotNear(s.area, who), 0
                if not spot then
                    local burrow = A.BurrowOf(th)
                    if burrow and A.Inside(s.area, burrow:GetPos()) then spot, jitter = burrow:GetPos(), 48 end
                end
                if spot and A.Spawn(spot, th, who, jitter) then s.nextAt = now + EVERY end
            end
        end
    end
    -- a thumper running again for a minute: its antlions still alive dig themselves away
    for th, at in pairs(A.calm) do
        if now - at >= CALM then
            A.calm[th] = nil
            for e, owner in pairs(A.out) do
                if owner == th then
                    if IsValid(e) and e:Health() > 0 then
                        if e.Fire then e:Fire("BurrowAway", "", 0) else e:Remove() end
                    end
                    A.out[e] = nil
                end
            end
        end
    end
end

timer.Create("LivingCityAntlions", 2, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(A.Tick)
    if not ok and LC.Error then LC.Error("antlions", err) end
end)
local function Forget()
    for e in pairs(A.out) do if IsValid(e) then e:Remove() end end
    A.stopped, A.out, A.calm = {}, {}, {}
end
hook.Add("LivingCityStopped", "LivingCityAntlions", Forget)
hook.Add("PostCleanupMap", "LivingCityAntlions", function() A.stopped, A.out, A.calm = {}, {}, {} end)
