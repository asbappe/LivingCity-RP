--[[
    Living City: units at their posts (the owner, 21 November: "build ALL of the
    ideas" read from Valve's own maps, docs/dev/valve-npc-notes.md, section 5)

      A unit at each Combine door   one of a Combine-only zone's garrison metrocops
                                    stands just outside each door into it (up to 3
                                    a zone), and keeps within 96 of his spot
                                    (Valve's police posts: 32 to 128). Someone with
                                    no business there who comes to the door is
                                    warned three times, in his own voice: at the
                                    first a scanner photographs them, at the second
                                    he raises his hand, at the third he shoves them
                                    back. Whoever gets past him, through the door,
                                    is beaten down (never to death: the beating stops
                                    at 25 health) and comes to outside the door; a
                                    second time within five minutes, they're wanted
                                    for trespassing. This replaces the chat lines of
                                    the trespass countdown near a guarded door; the
                                    countdown stays for anyone deeper in
                                    (sv_livingcity_security.lua).
      Guards at ease                a unit standing post (a door, the garrison's
                                    posts, a checkpoint) leans on the wall behind
                                    him, crouches or rests his baton, and comes up
                                    the moment he hears someone close or running,
                                    a shot, is hurt, or a door near him opens.
      More posts than men           a Combine-only zone keeps 1.75 posts for every
                                    unit of its garrison (Valve: 1.5 to 2); they
                                    move between the free ones, each facing out.

    No new setting: lc_garrison 0 (no garrison) leaves the doors unguarded too.
]]

if CLIENT then return end

LC = LC or {}

local POST_OUT = 48        -- the post: this far out from the door (Valve: 32 to 64)
local POST_RADIUS = 96     -- he keeps within this of it
local WARN_NEAR = 150      -- someone this near the doorway or him is warned
local BOX_REACH = 360      -- inside the zone, this near the doorway: past him, and in his reach
local WARN_EVERY = 2.5
local WARN_RESET = 45
local KO_AGAIN = 300       -- beaten again within this: wanted for trespassing
local HEALTH_FLOOR = 25    -- the beating never takes anyone below this
local MOST_DOORS = 3
local POSTS_PER_UNIT = 1.75
local SIDE_PROBE = 72      -- how far either side of a door is looked at to tell in from out

local LOOP, NOCOMPLAIN, MAYDIE = 256, 2048, 4096

local MP = "npc/metropolice/vo/"
local WARN_LINES = { MP .. "firstwarningmove.wav", MP .. "secondwarning.wav", MP .. "finalwarning.wav" }
local AGAIN_LINES = { MP .. "movealong3.wav", MP .. "moveit.wav", MP .. "keepmoving.wav" }
local BLOWS = { "weapons/stunstick/stunstick_fleshhit1.wav", "weapons/stunstick/stunstick_fleshhit2.wav" }

local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Doors into a Combine-only zone
------------------------------------------------------------------------

-- Which way a door faces: its thinnest side (flat; a brush door's own box too).
function LC.DoorNormal(door)
    local mins, maxs = door:OBBMins(), door:OBBMaxs()
    local n = ((maxs.x - mins.x) <= (maxs.y - mins.y)) and door:GetForward() or door:GetRight()
    n = Vector(n.x, n.y, 0)
    if n:LengthSqr() < 0.01 then n = Vector(1, 0, 0) end
    n:Normalize()
    return n
end

-- The floor in the doorway, moved `dist` out along its facing (sign 1 or -1).
function LC.DoorFloor(door, sign, dist)
    local c = door:WorldSpaceCenter()
    local p = c + LC.DoorNormal(door) * ((sign or 0) * (dist or 0))
    local tr = util.TraceLine({ start = p, endpos = p - Vector(0, 0, 200), mask = MASK_NPCSOLID_BRUSHONLY })
    if tr and tr.Hit then p = Vector(p.x, p.y, tr.HitPos.z) else p = Vector(p.x, p.y, c.z - 48) end
    return p
end

local SKIP_TAGS = { prison = true, locked = true, ignore = true }
local doorCache = setmetatable({}, { __mode = "k" }) -- [zone] = { t, posts }

-- The doors into zone z, each with a post outside it: { door, doorPos, pos, yaw, out, zone }.
function LC.CombineDoorPosts(z, now)
    now = now or CurTime()
    local c = doorCache[z]
    if c and now < c.t then return c.posts end
    local posts = {}
    if z and not z.cells and LC.IsDoorEntity then
        local center, reach
        if z.box then
            center = (z.box.mins + z.box.maxs) * 0.5
            reach = (z.box.maxs - z.box.mins):Length2D() * 0.5 + 150
        else
            center, reach = z.pos, (z.r or 300) + 150
        end
        local found = {}
        for _, door in ipairs(ents.FindInSphere(center, reach)) do
            if LC.IsDoorEntity(door) and not door.lcBlown and not SKIP_TAGS[LC.GetDoorTag and LC.GetDoorTag(door) or ""] then
                local a, b = LC.DoorFloor(door, 1, SIDE_PROBE), LC.DoorFloor(door, -1, SIDE_PROBE)
                local inA, inB = LCZ.Contains(z, a, 0), LCZ.Contains(z, b, 0)
                if inA ~= inB then
                    local sign = inA and -1 or 1 -- (outward)
                    local doorPos = LC.DoorFloor(door, 0, 0)
                    local twin = false -- (a double door is one way in)
                    for _, f in ipairs(found) do if f.doorPos:DistToSqr(doorPos) < 160 * 160 then twin = true break end end
                    if not twin then
                        local out = LC.DoorNormal(door) * sign
                        found[#found + 1] = { door = door, doorPos = doorPos, pos = LC.DoorFloor(door, sign, POST_OUT),
                            yaw = out:Angle().y, out = out, zone = z, d = doorPos:DistToSqr(center) }
                    end
                end
            end
        end
        table.sort(found, function(x, y) return x.d < y.d end)
        for i = 1, math.min(MOST_DOORS, #found) do posts[i] = found[i] end
    end
    doorCache[z] = { t = now + 30, posts = posts }
    return posts
end
hook.Add("LivingCityLayoutChanged", "LivingCityUnitPosts", function() doorCache = setmetatable({}, { __mode = "k" }) end)

-- The garrison's metrocops hold the doors first (called by LC.GarrisonTick for each Combine-only zone).
function LC.PostDoorGuards(z, posts)
    local held = {}
    for npc, gz in pairs(LC.Garrison or {}) do
        local st = gz == z and IsValid(npc) and LC.NPCs[npc]
        if st and st.doorPost then
            local mine
            for _, p in ipairs(posts) do if p.door == st.doorPost.door and not held[p] then mine = p break end end
            st.doorPost = mine
            if mine then held[mine] = npc end
        end
    end
    for _, p in ipairs(posts) do
        if not held[p] then
            local best, bd
            for npc, gz in pairs(LC.Garrison or {}) do
                local st = gz == z and IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc]
                if st and st.role == "cop" and not st.doorPost and st.state ~= "hostile" then
                    local d = npc:GetPos():DistToSqr(p.pos)
                    if not bd or d < bd then best, bd = npc, d end
                end
            end
            if best then
                LC.NPCs[best].doorPost = p
                held[p] = best
            end
        end
    end
    return held
end

------------------------------------------------------------------------
-- At ease until alarmed
------------------------------------------------------------------------

local RELAX = {
    cop = { wall = { "plazalean" }, open = { "Crouch_idle_pistol", "harrassidle", "batonidle1", "busyidle1" } },
    soldier = { wall = { "CrouchIdle" }, open = { "CrouchIdle", "crouchidle_AB" } },
}
LC.RELAX_SEQS = RELAX
LC.Relaxed = LC.Relaxed or {} -- [npc] = { ss, pos, doors = { [door] = shut }, at }

local function Has(npc, name) local s = npc.LookupSequence and npc:LookupSequence(name) return s ~= nil and s >= 0 end

local function DoorShut(door)
    local cls = door:GetClass()
    if cls == "prop_door_rotating" then return (door:GetInternalVariable("m_eDoorState") or 0) == 0 end
    if cls == "func_door" or cls == "func_door_rotating" then return (door:GetInternalVariable("m_toggle_state") or 1) == 1 end
    return true
end

-- Settle into an easy pose where he stands, facing yaw. False if he can't (none of the poses, or alert).
function LC.RelaxAtPost(npc, st, yaw, now)
    now = now or CurTime()
    if not IsValid(npc) or (st.alertUntil or 0) > now or LC.Relaxed[npc] or IsValid(npc.lcGesture) then return false end
    local set = RELAX[st.role]
    if not set or not LC.MakeSequence then return false end
    yaw = yaw or npc:GetAngles().y
    local eye = npc:GetPos() + Vector(0, 0, 40)
    local tr = util.TraceLine({ start = eye, endpos = eye - Angle(0, yaw, 0):Forward() * 40, mask = MASK_SOLID_BRUSHONLY, filter = npc })
    local list = (tr and tr.Hit) and set.wall or set.open
    local start, name = math.random(#list), nil
    for i = 0, #list - 1 do
        local c = list[(start + i - 1) % #list + 1]
        if Has(npc, c) then name = c break end
    end
    if not name and list ~= set.open then
        for _, c in ipairs(set.open) do if Has(npc, c) then name = c break end end
    end
    if not name then return false end
    local ok, ss = LC.Try(LC.MakeSequence, npc, npc:GetPos(), yaw, name, name, LOOP + NOCOMPLAIN + MAYDIE, 0, 0)
    if not ok or not IsValid(ss) then return false end
    npc.lcGesture = ss -- (anyone who goes for him cancels it: LC.MakeOneHostile)
    local doors = {}
    for _, d in ipairs(ents.FindInSphere(npc:GetPos(), 400)) do
        if LC.IsDoorEntity and LC.IsDoorEntity(d) then doors[d] = DoorShut(d) end
    end
    LC.Relaxed[npc] = { ss = ss, pos = npc:GetPos(), doors = doors, at = now, name = name }
    return true
end

-- Up again: why = what alarmed him (nil when he just moves on), from = where it came from.
function LC.RelaxEnd(npc, st, why, from)
    local r = LC.Relaxed[npc]
    LC.Relaxed[npc] = nil
    if r and IsValid(r.ss) then
        r.ss:Fire("CancelSequence")
        SafeRemoveEntityDelayed(r.ss, 0.2)
        if npc.lcGesture == r.ss then npc.lcGesture = nil end
    end
    if why and st then
        st.alertUntil = CurTime() + 20
        if from and IsValid(npc) and LC.Face then LC.Face(npc, from) end
        hook.Run("LivingCityGuardAlarmed", npc, why)
    end
    return r ~= nil
end

local lastShot -- { pos, t }
hook.Add("EntityFireBullets", "LivingCityGuardsHear", function(ent, data)
    if IsValid(ent) then lastShot = { pos = ent:GetPos(), t = CurTime() } end
end)
hook.Add("EntityTakeDamage", "LivingCityGuardsHurt", function(ent)
    if LC.Relaxed[ent] then
        local st = LC.NPCs and LC.NPCs[ent]
        LC.RelaxEnd(ent, st, "hurt")
    end
end)

-- What would bring a relaxed guard up, or nil.
local function Alarm(npc, r, now)
    local pos = npc:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not (LC.LooksCombine and LC.LooksCombine(ply)) then
            local d2 = ply:GetPos():DistToSqr(pos)
            local running = ply:GetVelocity():Length2D() > 200 and not ply:Crouching()
            if d2 < 220 * 220 or (running and d2 < 700 * 700) then return "heard", ply:GetPos() end
        end
    end
    if lastShot and now - lastShot.t < 1.5 and lastShot.pos:DistToSqr(pos) < 1500 * 1500 then return "gunfire", lastShot.pos end
    for d, shut in pairs(r.doors) do
        if IsValid(d) and shut and not DoorShut(d) then return "door", d:WorldSpaceCenter() end
    end
    return nil
end

function LC.RelaxTick(now)
    for npc, r in pairs(LC.Relaxed) do
        local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc]
        if not st or not IsValid(r.ss) or (st.state ~= "idle" and st.state ~= "post") or npc:GetPos():DistToSqr(r.pos) > 48 * 48 then
            LC.RelaxEnd(npc, st)
        else
            local why, from = Alarm(npc, r, now)
            if why then LC.RelaxEnd(npc, st, why, from) end
        end
    end
end

------------------------------------------------------------------------
-- The garrison's posts: more posts than men
------------------------------------------------------------------------

local zonePosts = setmetatable({}, { __mode = "k" }) -- [zone] = { {pos, yaw, holder} }

function LC.GarrisonPosts(z)
    local size = LC.GarrisonSize and LC.GarrisonSize(z) or 2
    local want = math.max(2, math.ceil(size * POSTS_PER_UNIT))
    local list = zonePosts[z] or {}
    local center = z.box and (z.box.mins + z.box.maxs) * 0.5 or z.pos
    for _ = 1, want * 4 do
        if #list >= want then break end
        local p = (LC.GuardPostSpot and LC.GuardPostSpot(z)) or (LC.SpotInZone and LC.SpotInZone(z))
        if p then
            local apart = true
            for _, q in ipairs(list) do if q.pos:DistToSqr(p) < 120 * 120 then apart = false break end end
            if apart then
                local out = p - center
                out.z = 0
                list[#list + 1] = { pos = p, yaw = out:LengthSqr() > 1 and out:Angle().y or math.random(0, 359) } -- (facing out, at what comes)
            end
        end
    end
    zonePosts[z] = list
    return list
end

-- A free post for this unit, not the one he's leaving; it's his until he takes another.
function LC.GarrisonPost(npc, st)
    local list = LC.GarrisonPosts(st.guardZone)
    local free, mine = {}, st.gpost
    for _, p in ipairs(list) do
        local h = p.holder
        local taken = IsValid(h) and h ~= npc and LC.NPCs[h] and LC.NPCs[h].gpost == p
        if not taken and p ~= mine then free[#free + 1] = p end
    end
    if mine and mine.holder == npc then mine.holder = nil end
    st.gpost = nil
    if #free == 0 then return nil end
    local p = Pick(free)
    p.holder, st.gpost = npc, p
    return p
end

------------------------------------------------------------------------
-- The unit at the door
------------------------------------------------------------------------

local function ZoneLive(z) return z and table.HasValue(LC.Zones or {}, z) end

local function MayEnter(ply)
    if LC.MayEnterCombine then return LC.MayEnterCombine(ply) end
    return LC.PlayerIsCP(ply)
end

local function InBox(p, pos) return LCZ.Contains(p.zone, pos, 0) and pos:DistToSqr(p.doorPos) < BOX_REACH * BOX_REACH end
local function AtDoor(p, pos)
    if LCZ.Contains(p.zone, pos, 0) then return false end
    return math.abs(pos.z - p.pos.z) < 100 and (pos:DistToSqr(p.doorPos) < WARN_NEAR * WARN_NEAR or pos:DistToSqr(p.pos) < WARN_NEAR * WARN_NEAR)
end

-- A door's guard on his post, or nil.
local function GuardOf(p)
    for npc, gz in pairs(LC.Garrison or {}) do
        local st = gz == p.zone and IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc]
        if st and st.doorPost and st.doorPost.door == p.door and st.state == "post" then return npc, st end
    end
    return nil
end

-- Someone past a guarded door, in his reach: he deals with them, so no countdown (sv_livingcity_security.lua).
function LC.PostCovers(ply, now)
    local pos = ply:GetPos()
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        if LCZ.Contains(z, pos, 0) then
            for _, p in ipairs(LC.CombineDoorPosts(z, now)) do
                if InBox(p, pos) and GuardOf(p) then return true end
            end
        end
    end
    return false
end

-- The first warning: the nearest scanner comes and photographs them.
function LC.PostPhotograph(ply, now)
    local best, bst, bd
    for n, s in pairs(LC.NPCs or {}) do
        if IsValid(n) and s.role == "scanner" then
            local d = n:GetPos():DistToSqr(ply:GetPos())
            if d < 3000 * 3000 and (not bd or d < bd) then best, bst, bd = n, s, d end
        end
    end
    if not best then return nil end
    if ply:GetName() == "" then ply:SetName("lc_suspect_" .. ply:EntIndex()) end
    best:Fire("SetFollowTarget", ply:GetName())
    bst.followEnt, bst.nextFollow = ply, (now or CurTime()) + 25
    timer.Simple(2, function()
        if IsValid(best) and IsValid(ply) then
            best:Fire("InspectTargetPhoto", ply:GetName())
            best:EmitSound("npc/scanner/scanner_photo1.wav", 75)
        end
    end)
    return best
end

-- A shove back the way they came.
function LC.PostShove(npc, ply, away)
    if LC.PlayGesture then LC.PlayGesture(npc, { "pushplayer", "ACT_PUSH_PLAYER" }, 1.5) end
    away = away or (ply:GetPos() - npc:GetPos())
    away.z = 0
    if away:LengthSqr() < 1 then away = npc:GetForward() end
    away = away:GetNormalized()
    ply:SetVelocity(away * 350 + Vector(0, 0, 110))
    ply:ViewPunch(Angle(-10, math.Rand(-6, 6), 0))
    npc:EmitSound("physics/body/body_medium_impact_soft3.wav", 70)
end

-- A blow with the stick that never kills (and never takes them under HEALTH_FLOOR).
function LC.UnitBlow(npc, ply)
    if not IsValid(npc) or not IsValid(ply) or not ply:Alive() then return 0 end
    if LC.PlayGesture then LC.PlayGesture(npc, { "swing", "ACT_MELEE_ATTACK_SWING", "ACT_MELEE_ATTACK1" }, 1) end
    npc:EmitSound(Pick(BLOWS), 80)
    ply:ViewPunch(Angle(-12, math.Rand(-8, 8), 0))
    local dmg = math.min(12, ply:Health() - HEALTH_FLOOR)
    if dmg > 0 then ply:TakeDamage(dmg, npc, npc) end
    if ply:Alive() and ply:Health() < HEALTH_FLOOR then ply:SetHealth(math.min(HEALTH_FLOOR, ply:GetMaxHealth())) end
    return math.max(0, dmg)
end

-- Past him: beaten down, then they come to outside the door. A second time within KO_AGAIN, wanted.
function LC.PostKnockOut(npc, st, p, ply, now)
    if (ply.lcPostKOBusy or 0) > now then return false end
    ply.lcPostKOBusy = now + 3
    LC.RelaxEnd(npc, st)
    if LC.Face then LC.Face(npc, ply:GetPos()) end
    npc:EmitSound(MP .. "holdit.wav", 80)
    for i = 0, 2 do
        timer.Simple(0.3 + i * 0.45, function() LC.UnitBlow(npc, ply) end)
    end
    timer.Simple(1.5, function()
        if IsValid(ply) and ply:Alive() then ply:ScreenFade(SCREENFADE.OUT, color_black, 0.4, 1.4) end
    end)
    timer.Simple(2.1, function()
        if not IsValid(ply) or not ply:Alive() then return end
        ply:SetPos(p.pos + p.out * 70 + Vector(0, 0, 4))
        if ply.SetLocalVelocity then ply:SetLocalVelocity(Vector(0, 0, 0)) end
        ply:ScreenFade(SCREENFADE.IN, color_black, 1.2, 0)
    end)
    ply.lcPostWarn = nil
    local again = ply.lcPostKO and now - ply.lcPostKO < KO_AGAIN
    ply.lcPostKO = now
    if again then
        LC.ReportCrime(ply, "Trespassing in a Combine area", 240)
        if LC.MakeCopsHostile then timer.Simple(2.3, function() if IsValid(ply) then LC.MakeCopsHostile(ply, ply:GetPos(), 1500) end end) end
    end
    hook.Run("LivingCityPostKnockOut", npc, ply, again)
    return true
end

-- At the door: warned three times, then shoved; each warning sets something off.
function LC.PostWarn(npc, st, p, ply, now)
    local w = ply.lcPostWarn
    if not w or w.door ~= p.door or now - w.last > WARN_RESET then
        w = { door = p.door, n = 0, last = -1e9 }
        ply.lcPostWarn = w
    end
    if now - w.last < WARN_EVERY then return w.n end
    w.n, w.last = w.n + 1, now
    LC.RelaxEnd(npc, st)
    if LC.Face then LC.Face(npc, ply:GetPos()) end
    npc:EmitSound(WARN_LINES[w.n] or Pick(AGAIN_LINES), 80)
    if w.n == 1 then
        if LC.PlayGesture then LC.PlayGesture(npc, LC.FRISK_ANIMS or { "harassfront1" }, 2) end
        LC.PostPhotograph(ply, now)
    elseif w.n == 2 then
        if LC.PlayGesture then LC.PlayGesture(npc, { "plazahalt", "ACT_SIGNAL_HALT" }, 2) end
    else
        LC.PostShove(npc, ply, p.out)
    end
    hook.Run("LivingCityPostWarning", npc, ply, w.n)
    return w.n
end

-- His think while on post (sv_livingcity.lua sends state "post" here).
function LC.UnitPostThink(npc, st, now)
    local p = st.doorPost
    if not p or not IsValid(p.door) or not ZoneLive(p.zone) then
        st.doorPost = nil
        LC.RelaxEnd(npc, st)
        LC.SetState(npc, st, "idle")
        st.untilT = now + 1
        return
    end
    if npc:GetPos():DistToSqr(p.pos) > (POST_RADIUS + 32) ^ 2 then -- (pushed off it, or followed someone)
        LC.RelaxEnd(npc, st)
        LC.SetState(npc, st, "idle")
        st.untilT = 0
        return
    end
    local inside, insideD, outside, outsideD -- (whoever is past him first, else the nearest at the door)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not MayEnter(ply) and not (LC.EditorHeld and LC.EditorHeld(ply))
            and not (LC.IsAdministrator and LC.IsAdministrator(ply)) then
            local pos = ply:GetPos()
            local d = pos:DistToSqr(p.doorPos)
            if InBox(p, pos) then
                if not insideD or d < insideD then inside, insideD = ply, d end
            elseif AtDoor(p, pos) then
                if not outsideD or d < outsideD then outside, outsideD = ply, d end
            end
        end
    end
    if inside then LC.PostKnockOut(npc, st, p, inside, now) return end
    if outside then LC.PostWarn(npc, st, p, outside, now) return end
    if not LC.Relaxed[npc] and (st.alertUntil or 0) < now and not IsValid(npc.lcGesture) then
        if npc.SetIdealYawAndUpdate then npc:SetIdealYawAndUpdate(p.yaw) end
        LC.RelaxAtPost(npc, st, p.yaw, now)
    end
end

function LC.UnitPostArrive(npc, st, now, poi)
    if st.doorPost and poi and poi.pos and st.doorPost.pos:DistToSqr(poi.pos) < 4 then
        LC.SetState(npc, st, "post")
        if LC.FaceYaw then LC.FaceYaw(npc, st.doorPost.yaw) end
        return true
    end
    return false
end

-- Before ChooseSecurityTask picks something: a lane to walk (sv_livingcity_unitmoves.lua), his door,
-- or one of the garrison's posts. True if it gave him something to do.
function LC.UnitChoose(npc, st, now)
    LC.RelaxEnd(npc, st)
    if st.lane and LC.LaneStep and LC.LaneStep(npc, st, now) then return true end
    local p = st.doorPost
    if p then
        if not IsValid(p.door) or not ZoneLive(st.guardZone) then st.doorPost = nil return false end
        if npc:GetPos():DistToSqr(p.pos) > POST_RADIUS * POST_RADIUS then
            if LC.GoTo(npc, st, p.pos, LC.Event == "lockdown", { kind = "unitpost", pos = p.pos, yaw = p.yaw }) then return true end
            st.doorPost = nil -- (no way to it: he goes back to the garrison's posts)
            return false
        end
        LC.SetState(npc, st, "post")
        return true
    end
    if st.guardZone and ZoneLive(st.guardZone) and not st.prisonGuard and math.random() < 0.7 then
        local gp = LC.GarrisonPost(npc, st)
        if gp and LC.GoTo(npc, st, gp.pos, LC.Event == "lockdown", { kind = "guardpost", pos = gp.pos, yaw = gp.yaw }) then return true end
    end
    return false
end

-- Arrivals (sv_livingcity.lua's Arrive asks these first): true when handled in full.
LC.ArriveHandlers = LC.ArriveHandlers or {}
LC.ArriveHandlers.unitpost = function(npc, st, now, poi) return LC.UnitPostArrive(npc, st, now, poi) end
LC.ArriveHandlers.guardpost = function(npc, st, now, poi)
    st.untilT = now + math.Rand(20, 60) -- (then on to another free post)
    LC.RelaxAtPost(npc, st, poi.yaw, now)
    return true
end
LC.ArriveHandlers.checkpoint = function(npc, st, now, poi)
    if st.role == "cop" or st.role == "soldier" then LC.RelaxAtPost(npc, st, poi.yaw, now) end
    return false -- (the checkpoint's own wait goes on as before)
end

LC.SecurityStates = LC.SecurityStates or {}
LC.SecurityStates.post = function(npc, st, now) return LC.UnitPostThink(npc, st, now) end

timer.Create("LivingCityUnitPosts", 0.5, 0, function()
    if not LC.Running then return end
    local ok, err = LC.Try(LC.RelaxTick, CurTime())
    if not ok and LC.Error then LC.Error("unit posts", err) end
end)

hook.Add("PlayerDeath", "LivingCityUnitPosts", function(ply) ply.lcPostWarn = nil end)
hook.Add("LivingCityStopped", "LivingCityUnitPosts", function()
    LC.Relaxed = {}
    zonePosts = setmetatable({}, { __mode = "k" })
    doorCache = setmetatable({}, { __mode = "k" })
end)
