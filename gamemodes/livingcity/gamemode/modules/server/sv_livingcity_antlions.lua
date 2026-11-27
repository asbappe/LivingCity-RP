--[[
    Living City: antlions at a stopped thumper (the owner's long-term list, 18 November, 5: "thumpers keep
    them off (the Combine's, which a saboteur can switch off), they come up through sand or soft ground").
    The first small piece of it, and only where a map has the thumper module (docs/dev/canal-modules.md):

      lc_thumper_head    the thumper (prop_thumper). The map's button stops and starts it (Disable, Enable).
      lc_thumper_burrow  the burrow's mouth near it: where they come up.

    A map may have several copies of the module (27 November: four on the canal ring). The first keeps these names;
    the others have a number after "thumper" (lc_thumper2_head, lc_thumper2_burrow, ...). Every name is read as
    ^lc_thumper(%d*)_(%w+)$, and a copy's parts go together by that number ("" for the first).

    While a thumper stands still (the owner, 27 November: "a few (NOT a continuous relentless swarm, but like 1/5
    the HL2 amount) ... at a small trickle (basically one at a time) at a random player/NPC in that part of the canal,
    until the thumper is turned back on ... one every 15 seconds with a max or 2 alive at a time"): every 15 seconds
    one antlion digs up near a random player or person in that thumper's stretch of the canal, and goes for them;
    two alive at most from each thumper. Its stretch: within 3500 units of the thumper, in the canal's basin (from 64
    under its burrow's floor to 192 over it: the canal's floor and the thumper's terrace, never the street 256 up).
    Where the map marks it (lc_thumper_area, lc_thumper2_area, ...: the canal ring's generator puts two at the opposite
    corners of the straight run the thumper stands on, between the turns round it, the owner's "that west end of the
    canal"), the box the marks span instead.
    Nobody there, none come. Each thumper on its own: two stopped, two trickles.
    Started again, the thumper drives off what is left (the game does that itself), and a minute later its antlions
    still alive dig themselves away. They go for everyone (while the Swarm's pheropods are out, they are its allies:
    sv_livingcity_swarm.lua). Nothing is written on anyone's screen.
    On a map without these names nothing here happens.
]]

LC = LC or {}
LC.Antlions = LC.Antlions or { stopped = {}, out = {} }
local A = LC.Antlions
A.calm = A.calm or {} -- [thumper] = when it was started again (its antlions dig away a minute later)

local EVERY, OUT_MAX, REACH, STRETCH, BASIN_DOWN, BASIN_UP, CALM = 15, 2, 2000, 3500, 64, 192, 60
A.EVERY, A.OUT_MAX, A.STRETCH = EVERY, OUT_MAX, STRETCH
-- (what they never come up for: their own kind, the invisible and what flies)
local NOT_PREY = { npc_antlion = true, npc_antlionguard = true, npc_antlion_worker = true, npc_antlion_grub = true, npc_bullseye = true,
    npc_grenade_bugbait = true, npc_cscanner = true, npc_clawscanner = true, npc_manhack = true, npc_turret_floor = true, npc_turret_ceiling = true,
    npc_turret_ground = true, npc_combine_camera = true, npc_helicopter = true, npc_combinegunship = true, npc_combinedropship = true, npc_strider = true }

local function NameOf(e) return string.lower(tostring(e.GetName and e:GetName() or "")) end

-- A thumper module's name read: its copy's number ("" for the first) and the part ("head", "burrow", "button",
-- "start", "stop" ...). nil for any other name.
function A.Parse(name)
    local n, part = string.match(string.lower(tostring(name or "")), "^lc_thumper(%d*)_(%w+)$")
    return n, part
end

-- Every thumper on the map (each copy's head).
function A.Heads()
    local out = {}
    for _, e in ipairs(ents.FindByName and ents.FindByName("lc_thumper*") or {}) do
        local _, part = A.Parse(NameOf(e))
        if IsValid(e) and part == "head" then out[#out + 1] = e end
    end
    return out
end

-- A part of the same copy as ent (a thumper, or any part of it): the one of that number nearest to it, within reach.
function A.PartOf(ent, part)
    if not IsValid(ent) then return nil end
    local n = A.Parse(NameOf(ent))
    if not n then return nil end
    local best, bd
    for _, t in ipairs(ents.FindByName and ents.FindByName("lc_thumper" .. n .. "_" .. part) or {}) do
        if IsValid(t) then
            local d = t:GetPos():DistToSqr(ent:GetPos())
            if d <= REACH * REACH and (not bd or d < bd) then best, bd = t, d end
        end
    end
    return best
end

function A.BurrowOf(thumper) return A.PartOf(thumper, "burrow") end

-- The map tells its thumper to stop or start: remembered here.
function A.Set(thumper, running)
    if not IsValid(thumper) then return end
    local s = A.stopped[thumper]
    if running then
        if s then A.stopped[thumper] = nil A.calm[thumper] = CurTime() end
    elseif not s then
        A.stopped[thumper] = { since = CurTime(), nextAt = CurTime() + EVERY }
        A.calm[thumper] = nil
    end
end

hook.Add("AcceptInput", "LivingCityAntlions", function(ent, input)
    if not IsValid(ent) then return end
    local what = string.lower(input or "")
    if what ~= "enable" and what ~= "disable" then return end
    local _, part = A.Parse(NameOf(ent))
    if part ~= "head" then return end
    LC.Try(A.Set, ent, what == "enable")
end)

-- How many of this thumper's are alive.
function A.OutOf(thumper)
    local n = 0
    for e in pairs(A.out) do
        if not (IsValid(e) and e:Health() > 0) then A.out[e] = nil elseif e.lcThumper == thumper then n = n + 1 end
    end
    return n
end

-- The stretch the map marks for this thumper: the box its lc_thumperN_area marks span (a little wider and lower, so
-- the canal's floor and walls are in it), or nil on a map without them. (Kept once found: the marks never move.)
A.areas = A.areas or {}
function A.AreaOf(thumper)
    if not IsValid(thumper) then return nil end
    local got = A.areas[thumper]
    if got ~= nil then return got ~= false and got[1] or nil, got ~= false and got[2] or nil end
    local n = A.Parse(NameOf(thumper))
    local lo, hi, k = nil, nil, 0
    for _, m in ipairs(n and ents.FindByName and ents.FindByName("lc_thumper" .. n .. "_area") or {}) do
        local _, part = A.Parse(NameOf(m))
        if IsValid(m) and part == "area" then
            local p = m:GetPos()
            k = k + 1
            if not lo then
                lo, hi = Vector(p.x, p.y, p.z), Vector(p.x, p.y, p.z)
            else
                lo = Vector(math.min(lo.x, p.x), math.min(lo.y, p.y), math.min(lo.z, p.z))
                hi = Vector(math.max(hi.x, p.x), math.max(hi.y, p.y), math.max(hi.z, p.z))
            end
        end
    end
    if k < 2 then A.areas[thumper] = false return nil end
    lo, hi = lo - Vector(48, 48, 64), hi + Vector(48, 48, 16)
    A.areas[thumper] = { lo, hi }
    return lo, hi
end

-- In this thumper's stretch of the canal: near it, and down in the basin (not on the street over it); or in the box
-- the map marks for it.
function A.InStretch(thumper, pos)
    local lo, hi = A.AreaOf(thumper)
    if lo then
        return pos.x >= lo.x and pos.x <= hi.x and pos.y >= lo.y and pos.y <= hi.y and pos.z >= lo.z and pos.z <= hi.z
    end
    local tp = thumper:GetPos()
    if (pos.x - tp.x) ^ 2 + (pos.y - tp.y) ^ 2 > STRETCH * STRETCH then return false end
    local burrow = A.BurrowOf(thumper)
    local floor = burrow and burrow:GetPos().z or (tp.z - 128)
    return pos.z >= floor - BASIN_DOWN and pos.z <= floor + BASIN_UP
end

-- Who is in its stretch: living players and people (any creature it would go for).
function A.Prey(thumper)
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not p:GetNW2Bool("lc_build", false) and A.InStretch(thumper, p:GetPos()) then out[#out + 1] = p end
    end
    local lo, hi = A.AreaOf(thumper)
    local reach = lo and math.max(STRETCH, (hi - lo):Length() + 1024) or STRETCH      -- (a marked stretch can be longer than 3500)
    for _, e in ipairs((lo and ents.FindInBox and ents.FindInBox(lo, hi)) or (ents.FindInSphere and ents.FindInSphere(thumper:GetPos(), reach)) or {}) do
        if IsValid(e) and e:IsNPC() and e:Health() > 0 and not NOT_PREY[e:GetClass()] and A.InStretch(thumper, e:GetPos()) then out[#out + 1] = e end
    end
    return out
end

-- A spot on the floor a few steps from someone, that they could see (else nil).
local function SpotNear(pos)
    if not util.TraceLine then return nil end
    for _ = 1, 8 do
        local a, r = math.Rand(0, math.pi * 2), math.Rand(150, 300)
        local at = pos + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        local tr = util.TraceLine({ start = at + Vector(0, 0, 64), endpos = at - Vector(0, 0, 128), mask = MASK_SOLID_BRUSHONLY })
        if tr and tr.Hit and math.abs(tr.HitPos.z - pos.z) < 64 then
            local los = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = tr.HitPos + Vector(0, 0, 40), mask = MASK_SOLID_BRUSHONLY })
            if not (los and los.Hit) then return tr.HitPos end
        end
    end
    return nil
end

function A.Spawn(pos, thumper)
    local e = ents.Create("npc_antlion")
    if not IsValid(e) then return nil end
    local a, d = math.Rand(0, math.pi * 2), math.Rand(0, 48)
    e:SetPos(pos + Vector(math.cos(a) * d, math.sin(a) * d, 4))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:SetKeyValue("startburrowed", "1")
    e:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE or 512))
    e:Spawn()
    if e.Activate then e:Activate() end
    if e.Fire then e:Fire("Unburrow", "", 0.1) end
    e.lcThumperAntlion, e.lcThumper = true, thumper
    A.out[e] = true
    if A.OnSpawn then LC.Try(A.OnSpawn, e) end -- (the Swarm's, while its pheropods are out)
    return e
end

function A.Tick()
    local now = CurTime()
    for th, s in pairs(A.stopped) do
        if not IsValid(th) then
            A.stopped[th] = nil
        elseif now >= s.nextAt then
            s.nextAt = now + EVERY
            if A.OutOf(th) < OUT_MAX then
                local prey = A.Prey(th)
                if #prey > 0 then
                    local who = prey[math.random(#prey)]
                    local burrow = A.BurrowOf(th)
                    local at = SpotNear(who:GetPos()) or (burrow and burrow:GetPos())
                    local e = at and A.Spawn(at, th)
                    if e and not (A.FriendOf and A.FriendOf(who)) then
                        if e.AddEntityRelationship then e:AddEntityRelationship(who, D_HT, 99) end
                        if e.SetEnemy then e:SetEnemy(who) end
                        if e.UpdateEnemyMemory then e:UpdateEnemyMemory(who, who:GetPos()) end
                    end
                end
            end
        end
    end
    -- a thumper running again for a minute: its antlions still alive dig themselves away
    for th, t in pairs(A.calm) do
        if now - t >= CALM then
            A.calm[th] = nil
            for e in pairs(A.out) do
                if e.lcThumper == th or not IsValid(e.lcThumper) then
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
    A.stopped, A.out, A.calm, A.areas = {}, {}, {}, {}
end
hook.Add("LivingCityStopped", "LivingCityAntlions", Forget)
hook.Add("PostCleanupMap", "LivingCityAntlions", function() A.stopped, A.out, A.calm, A.areas = {}, {}, {}, {} end)
