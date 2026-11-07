--[[
    Living City: the stalker's lot

    What the Combine make of the worst anticitizens (sv_livingcity_custody.lua)
    is put to work, below, where only units go: the Combine areas (else the
    prison, else the checkpoints). A story on the board (F4), only for a
    stalker, in five parts:

      1 Processing   report to the Nexus, where an Overwatch technician is
                     waiting with the harness, and stand still while it's fitted
      2 Floors       sweep the holding floor with a push broom (E on each
                     patch of grime; lc_broom_hold tunes where the broom sits)
      3 Cable        splice the cable into two power banks (a rewiring board
                     at each)
      4 The frame    a second power transformer, built right beside one of
                     the city's own (the owner, 2026-11-01): carry its four
                     cells over and set them in, then weld its four seams
      5 The charge   route its first charge (a bigger rewiring board). The
                     current jumps the gap between the two. Nobody's watching.

    At the end you choose. Walk into the gap between the two transformers, and
    the current takes you at once: the stalker that was you is gone for good
    (whatever permanent death is set to, you start over as a new person). Or
    turn away and go back to work: there is no other way out of being a
    stalker. The transformer stays where you built it, arcing, and you can
    walk back into the gap any time (or E on it, twice).

    The stalker playermodel is Workshop 268895264 (lc_stalker_model in
    sv_livingcity_custody.lua).
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Hold, Choice, Narrate, Pick, Count = Q.Goto, Q.Hold, Q.Choice, Q.Narrate, Q.Pick, Q.Count

local function Stalker(ply) return LC.PlayerIsStalker ~= nil and LC.PlayerIsStalker(ply) end

------------------------------------------------------------------------
-- Where a stalker works
------------------------------------------------------------------------

local function Ground(pos) return (LC.GroundAt and LC.GroundAt(pos)) or pos end

-- Somewhere below: a Combine area, else the prison, else a checkpoint.
function LC.StalkerSpot(ply, avoid)
    local zs = {}
    for _, kind in ipairs({ "combine", "prison" }) do
        for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind(kind) or {}) do zs[#zs + 1] = z end
        if #zs > 0 then break end
    end
    if #zs > 0 then
        local pos
        for _ = 1, 6 do
            local z = Pick(zs)
            pos = (LC.SpotInZone and LC.SpotInZone(z)) or z.pos
            if pos and not (avoid and avoid:DistToSqr(pos) < 250 * 250) then break end
        end
        return pos and Ground(pos)
    end
    local cps = LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}
    if #cps > 0 then return Pick(cps).pos end
    return Q.Spot(ply, 300, 1500)
end

local function Banks(ply, n)
    local out = {}
    local list = {}
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("lc_powerbank") or {}) do list[#list + 1] = b end
    for _, b in ipairs(Q.Shuffle(list)) do
        if #out >= n then break end
        out[#out + 1] = b:GetPos() + b:GetForward() * 40
    end
    while #out < n do
        local p = LC.StalkerSpot(ply, out[#out])
        if not p then return nil end
        out[#out + 1] = p
    end
    return out
end

------------------------------------------------------------------------
-- The energizer
------------------------------------------------------------------------

LC.Energizers = LC.Energizers or {}

function LC.StalkerEnergizer(ply, pos, built, yaw, partner)
    local e = LC.Energizers[ply]
    if not IsValid(e) then
        if not pos then return nil end
        e = ents.Create("lc_energizer")
        if not IsValid(e) then return nil end
        e:SetPos(pos)
        e:SetAngles(Angle(0, yaw or math.random(0, 359), 0))
        e:Spawn()
        e.lcStalker = ply
        LC.Energizers[ply] = e
        -- the city's own transformer beside it: the current jumps between the two (lc_energizer.lua draws it)
        if IsValid(partner) then e:SetNW2Entity("lc_partner", partner) e.lcPartner = partner end
    end
    if built then e:SetNW2Int("lc_built", built) end
    return e
end

-- Taken away (after delay seconds: it stands there humming a while first).
local function Unbuild(ply, delay)
    local e = LC.Energizers[ply]
    if not IsValid(e) then LC.Energizers[ply] = nil return end
    local function Gone()
        if LC.Energizers[ply] == e then LC.Energizers[ply] = nil end
        if IsValid(e) then e:Remove() end
    end
    if delay and delay > 0 then timer.Simple(delay, Gone) else Gone() end
end

-- Where it's built: right beside one of the city's own power transformers (the nearest to the stalker's
-- work), turned the same way, with a gap between them a person could walk into. With no transformer in
-- the city, wherever the stalker works.
local GAP = 46
local function Site(ply, data)
    if not data.site then
        local base = LC.StalkerSpot(ply) or ply:GetPos()
        local best, bd
        for _, t in ipairs(LC.EntsOf and LC.EntsOf("lc_transformer") or {}) do
            if IsValid(t) then
                local d = t:GetPos():DistToSqr(base)
                if not bd or d < bd then best, bd = t, d end
            end
        end
        if IsValid(best) then
            local mn, mx = best:OBBMins(), best:OBBMaxs()
            local width = math.max(20, math.abs(mx.y - mn.y))
            local p = Ground(best:GetPos() + best:GetRight() * (width + GAP) + Vector(0, 0, 20))
            data.site, data.yaw, data.partner = { p.x, p.y, p.z }, best:GetAngles().y, best:EntIndex()
        else
            local p = base
            if not p then return nil end
            data.site = { p.x, p.y, p.z }
        end
    end
    return Vector(data.site[1], data.site[2], data.site[3]), data.yaw, data.partner and Entity(data.partner) or nil
end

-- The end of a stalker: into the light, and gone. A new person, whatever
-- permanent death is set to (sv_livingcity_character.lua).
function LC.StalkerStepIn(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local e = LC.Energizers[ply]
    if IsValid(e) then
        e:SetNW2Float("lc_flash", CurTime())
        e:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 95)
        ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 90)
        if util.Effect and EffectData then
            local fx = EffectData()
            fx:SetOrigin(ply:WorldSpaceCenter())
            fx:SetMagnitude(8) fx:SetScale(2) fx:SetRadius(40)
            util.Effect("ElectricSpark", fx)
            util.Effect("cball_explode", fx)
        end
    end
    ply:ScreenFade(SCREENFADE.OUT, Color(200, 230, 255, 255), 0.2, 2)
    ply.lcEndOfLife = "energizer"
    ply.lcDownCause = { "Walked into the gap between two power transformers. The current took them before they hit the floor.", "combine" }
    ply:Kill()
    ply.lcEndOfLife = nil
    Unbuild(ply, 60)
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply then p:ChatPrint("[City] A flash below the Nexus. Combine property has been written off.") end
    end
    hook.Run("LivingCityStalkerEnded", ply)
    return true
end

-- Turned away: back to work. The energizer stays, and so does the way out.
function LC.StalkerEndure(ply)
    if not IsValid(ply) or not Stalker(ply) then return false end
    if LC.Notice then
        LC.Notice(ply, "info", "Back to work", "The current snaps across the gap behind you. It will still be there: walk into it, or E on it twice, if you change your mind.", 8)
    end
    return true
end

-- E on a finished energizer: its stalker steps in (the second press, within
-- five seconds, so nobody does it by accident).
function LC.UseEnergizer(ply, e)
    if not IsValid(e) or LC.Energizers[ply] ~= e or not Stalker(ply) then return false end
    if e:GetNW2Int("lc_built", 0) < 3 then return false end
    if LC.QuestOf and LC.QuestOf[ply] and not LC.QuestOf[ply].done then return false end -- (the story asks you itself)
    if (ply.lcEnergizerArmed or 0) > CurTime() then
        ply.lcEnergizerArmed = nil
        return LC.StalkerStepIn(ply)
    end
    ply.lcEnergizerArmed = CurTime() + 5
    if LC.Notice then LC.Notice(ply, "bad", "The current", "It would be very easy. Press E again to step into the gap. There's no coming back.", 5) end
    return true
end
-- Walking into the gap: the current takes you at once (the stalker who built it; the story asks first, while it's running).
timer.Create("LivingCityStalkerGap", 0.2, 0, function()
    for ply, e in pairs(LC.Energizers) do
        local partner = IsValid(e) and e.lcPartner
        if IsValid(ply) and ply:Alive() and IsValid(partner) and e:GetNW2Int("lc_built", 0) >= 3 and Stalker(ply)
            and not (LC.QuestOf and LC.QuestOf[ply] and not LC.QuestOf[ply].done) then
            local a, b = e:GetPos(), partner:GetPos()
            local mid = (a + b) * 0.5
            local pos = ply:GetPos()
            local half = a:Distance(b) * 0.5
            local dir = (b - a):GetNormalized()
            local along = (pos - mid):Dot(dir)
            local side = (pos - mid) - dir * along
            side.z = 0
            if math.abs(along) < half * 0.45 and side:Length() < 40 and math.abs(pos.z - mid.z) < 60 then LC.StalkerStepIn(ply) end
        end
    end
end)
hook.Add("PlayerDisconnected", "LivingCityStalkerWork", function(ply) Unbuild(ply) end)
hook.Add("LivingCityStalkerFreed", "LivingCityStalkerWork", function(ply) Unbuild(ply, 300) end)
hook.Add("LivingCityNewCharacter", "LivingCityStalkerWork", function(ply) Unbuild(ply, 60) end)

------------------------------------------------------------------------
-- The work, as games (a stalker doesn't just stand there)
------------------------------------------------------------------------

-- A game started on arrival; the stage after it waits for the game to be done.
local function GameGo(pos, text, kind, opts)
    local go = Goto(pos, text, 200)
    go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, kind, q, opts) end end
    return go
end
local function GameStage(text) return Count("game_done", 1, text) end

-- Spots of floor around a center that can be walked to from it (the owner, 7 November: a patch
-- of grime spawned in a wall or under the floor, and the job couldn't be finished). Each is on
-- the ground (a trace down that lands, not one started inside something), level enough, at about
-- the center's height, with nothing solid between it and the center, and clear of the others.
-- Returns the spot and the floor's normal there, or nothing.
local function FloorSpot(center, rmin, rmax, taken)
    for _ = 1, 30 do
        local a = math.random() * math.pi * 2
        local r = math.Rand(rmin, rmax)
        local p = center + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        local tr = util.TraceLine({ start = p + Vector(0, 0, 48), endpos = p - Vector(0, 0, 160), mask = MASK_NPCSOLID_BRUSHONLY })
        local n = (tr and tr.HitNormal) or Vector(0, 0, 1)
        if tr and tr.Hit and not tr.StartSolid and n.z > 0.7 and math.abs(tr.HitPos.z - center.z) < 60
            and (not LC.Walkable or LC.Walkable(center, tr.HitPos)) then
            local clear = true
            for _, o in ipairs(taken) do if o:DistToSqr(tr.HitPos) < 60 * 60 then clear = false break end end
            if clear then return tr.HitPos, n end
        end
    end
end
-- Up to n such spots (fewer in a cramped place: never one that can't be reached). Also the
-- floor's normal under each, by the same index.
local function Around(center, n, rmin, rmax)
    local out, normals = {}, {}
    for _ = 1, n do
        local p, nm = FloorSpot(center, rmin, rmax, out)
        if not p then p, nm = FloorSpot(center, rmin * 0.5, rmax * 0.6, out) end -- (a small room: closer in)
        if p then out[#out + 1] = p normals[#out] = nm end
    end
    return out, normals
end

-- Laid flat along the floor whatever its slope (the owner, 7 November: grime on a ramp hung
-- level, floating off it): the angle whose up is the floor's normal, turned to the yaw given.
local function SlopeAngle(normal, yaw)
    local flat = Angle(0, yaw or 0, 0)
    if not normal or normal.z > 0.999 or not normal.AngleEx then return flat end
    local f = flat:Forward()
    f = f - normal * f:Dot(normal)
    if f:LengthSqr() < 0.001 then return flat end
    f:Normalize()
    return f:AngleEx(normal)
end

-- Where the push broom sits (the owner, 7 November: hung from the hand it was upside down and off
-- to the side, hardly in view): held out in front, the head on the floor ahead and the handle up
-- toward the hands, from the stalker's feet. lc_broom_hold tunes it in game.
local cvBroom = CreateConVar("lc_broom_hold", "34 -6 2 -35 0 0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Where a stalker holds the push broom, from its feet: forward left up pitch yaw roll (roll 180 turns it over)")
local function BroomHold()
    local v = {}
    for w in string.gmatch(cvBroom:GetString(), "%S+") do v[#v + 1] = tonumber(w) or 0 end
    return Vector(v[1] or 34, v[2] or -6, v[3] or 2), Angle(v[4] or -35, v[5] or 0, v[6] or 0)
end

-- Something held in the stalker's hands (the push broom), out in front wherever it goes.
local function InHand(ply, model)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(ply:GetPos() + Vector(0, 0, 40))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_NONE) end
    e:SetParent(ply)
    local pos, ang = BroomHold()
    if e.SetLocalPos then e:SetLocalPos(pos) end
    if e.SetLocalAngles then e:SetLocalAngles(ang) end
    return e
end

-- The broom swings as the stalker walks, and harder while it sweeps (E held on the grime); still
-- when it stands still.
local function SwayBroom(g)
    local e, ply = g.broom, g.ply
    if not IsValid(e) or not IsValid(ply) then return end
    local vel = ply.GetVelocity and ply:GetVelocity()
    local moving = vel ~= nil and vel:Length2DSqr() > 20 * 20
    local sweeping = (ply.lcSweepingUntil or 0) > CurTime()
    local pos, ang = BroomHold()
    if moving or sweeping then
        local s = math.sin(CurTime() * (sweeping and 7 or 5))
        pos = pos + Vector(s * (sweeping and 14 or 8), 0, 0)
        ang = Angle(ang.p + s * 6, ang.y + s * (sweeping and 10 or 4), ang.r)
    end
    if e.SetLocalPos then e:SetLocalPos(pos) end
    if e.SetLocalAngles then e:SetLocalAngles(ang) end
end

-- A patch of grime, laid along the floor.
local function Stain(g, p, normal)
    local e = ents.Create("lc_stain")
    if not IsValid(e) then return nil end
    e:SetPos(p + (normal or Vector(0, 0, 1)))
    e:SetAngles(SlopeAngle(normal, math.random(0, 359)))
    e:Spawn()
    e.lcScrubFor = g.ply
    g.stains[#g.stains + 1] = e
    g.props[#g.props + 1] = e
    return e
end

-- The holding floor: grime here and there; a push broom (no kneeling: a stalker hasn't the legs
-- for it). E on each patch sweeps it up (a couple of seconds).
local SCRUB_N = 6
local SCRUB_WAIT = 75 -- seconds without a sweep before a patch nobody can find comes to the stalker
LC.JobGameDefine("scrub", {
    start = function(g)
        g.title = "The holding floor"
        g.stains, g.swept, g.lastSweep = {}, 0, CurTime()
        local spots, normals = Around(g.opts.pos or g.ply:GetPos(), SCRUB_N, 80, 320)
        for i, p in ipairs(spots) do Stain(g, p, normals[i]) end
        g.broom = InHand(g.ply, "models/props_c17/pushbroom.mdl")
        if IsValid(g.broom) then g.props[#g.props + 1] = g.broom end
        g.ply:ChatPrint("[Stalker] A push broom, and the floor. Walk to each patch of grime and sweep it up (hold E on it).")
        g.hud = function(gg) return { string.format("Swept: %d of %d", gg.swept, #gg.stains), "E on the grime sweeps it up" } end
    end,
    tick = function(g)
        SwayBroom(g)
        -- (gone however it went: swept, or a city cleaner got there first)
        local left = {}
        for _, e in ipairs(g.stains) do if IsValid(e) then left[#left + 1] = e end end
        local swept = #g.stains - #left
        if swept ~= g.swept then g.swept, g.lastSweep = swept, CurTime() end
        if #left == 0 then LC.JobGameEnd(g.ply, "done") return end
        -- the last patch or two that nobody can find (the owner, 7 November: five of six, and the
        -- sixth nowhere): after a while without a sweep they're moved to the floor near the stalker
        if #left <= 2 and CurTime() - g.lastSweep > SCRUB_WAIT and IsValid(g.ply) then
            g.lastSweep = CurTime()
            local near, normals = Around(g.ply:GetPos(), #left, 90, 200)
            local moved = false
            for i, e in ipairs(left) do
                if near[i] and not e.lcSweeping then
                    e:SetPos(near[i] + (normals[i] or Vector(0, 0, 1)))
                    e:SetAngles(SlopeAngle(normals[i], math.random(0, 359)))
                    moved = true
                end
            end
            if moved then g.ply:ChatPrint("[Stalker] The grime you couldn't find: there's a patch of it just here.") end
        end
    end,
})
hook.Add("PlayerUse", "LivingCityStalkerScrub", function(ply, ent)
    if not (IsValid(ent) and ent.lcScrubFor == ply) then return end
    local g = LC.JobGames and LC.JobGames[ply]
    if not g or g.kind ~= "scrub" or (LC.Busy and LC.Busy(ply)) or ent.lcSweeping then return false end
    ent.lcSweeping = true
    ply.lcSweepingUntil = CurTime() + 2.5 -- (the broom swings while it sweeps: SwayBroom)
    ply:EmitSound("physics/cardboard/cardboard_box_scrape_rough_loop1.wav", 55)
    LC.StartTask(ply, 2.5, "Sweeping it up...", { maxMove = 70,
        cancel = function()
            if IsValid(ent) then ent.lcSweeping = nil end
            if IsValid(ply) then
                ply.lcSweepingUntil = nil
                if ply.StopSound then ply:StopSound("physics/cardboard/cardboard_box_scrape_rough_loop1.wav") end -- (a loop: stopped either way)
            end
        end,
        done = function(p)
            p.lcSweepingUntil = nil
            if p.StopSound then p:StopSound("physics/cardboard/cardboard_box_scrape_rough_loop1.wav") end
            if IsValid(ent) then ent:Remove() end
        end })
    return false
end)

-- The frame: four containment cells to carry over and seat in it (pick each up with E, set it in
-- the frame), then the housing welded shut at four seams (E on each, a few seconds of sparks).
local CELL = "models/items/combine_rifle_ammo01.mdl"
local SEAM = "models/props_lab/tpplug.mdl"
LC.JobGameDefine("assemble", {
    start = function(g)
        g.title = "The frame"
        g.frame = LC.StalkerEnergizer(g.ply, g.opts.pos, 0)
        local c = IsValid(g.frame) and g.frame:WorldSpaceCenter() or (g.opts.pos or g.ply:GetPos())
        g.center = c
        g.cells, g.seated, g.seams, g.welded = {}, 0, {}, 0
        for _, p in ipairs(Around(g.opts.pos or g.ply:GetPos(), 4, 180, 320)) do
            local e = ents.Create("prop_physics")
            if IsValid(e) then
                e:SetModel(CELL)
                e:SetPos(p + Vector(0, 0, 12))
                e:Spawn()
                local ph = e:GetPhysicsObject()
                if IsValid(ph) and ph.SetMass then ph:SetMass(10) end
                e.lcCell = g.ply
                g.cells[#g.cells + 1] = e
                g.props[#g.props + 1] = e
            end
        end
        g.ply:ChatPrint("[Stalker] Four containment cells lie about. Carry each one to the frame (E to pick it up) and set it in.")
        g.hud = function(gg)
            if gg.seated < #gg.cells then return { string.format("Cells seated: %d of %d", gg.seated, #gg.cells), "E picks a cell up; set it in the frame" } end
            return { string.format("Seams welded: %d of %d", gg.welded, #gg.seams), "E on each glowing seam" }
        end
    end,
    tick = function(g)
        if g.seated < #g.cells then
            for _, e in ipairs(g.cells) do
                if IsValid(e) and not e.lcSeated and e:GetPos():DistToSqr(g.center) < 70 * 70 then
                    e.lcSeated = true
                    e:Remove()
                    g.seated = g.seated + 1
                    g.ply:EmitSound("items/battery_pickup.wav", 60)
                    if g.seated >= #g.cells then
                        LC.StalkerEnergizer(g.ply, g.opts.pos, 1)
                        g.ply:ChatPrint("[Stalker] The cells click home. Now the housing: weld the four seams (E on each).")
                        for i = 1, 4 do
                            local a = i / 4 * math.pi * 2
                            local p = g.center + Vector(math.cos(a) * 34, math.sin(a) * 34, math.random(-10, 20))
                            local s = ents.Create("prop_dynamic")
                            if IsValid(s) then
                                s:SetModel(SEAM)
                                s:SetPos(p)
                                s:Spawn()
                                s:SetColor(Color(255, 160, 40))
                                s.lcSeamFor = g.ply
                                g.seams[#g.seams + 1] = s
                                g.props[#g.props + 1] = s
                            end
                        end
                    end
                end
            end
        elseif #g.seams > 0 and g.welded >= #g.seams then
            LC.StalkerEnergizer(g.ply, g.opts.pos, 2)
            LC.JobGameEnd(g.ply, "done")
        end
    end,
})
hook.Add("PlayerUse", "LivingCityStalkerWeld", function(ply, ent)
    if not (IsValid(ent) and ent.lcSeamFor == ply) then return end
    local g = LC.JobGames and LC.JobGames[ply]
    if not g or g.kind ~= "assemble" or (LC.Busy and LC.Busy(ply)) or ent.lcWelding then return false end
    ent.lcWelding = true
    local sparks = timer.Create and ("LivingCityWeld" .. ent:EntIndex())
    if sparks then
        timer.Create(sparks, 0.4, 8, function()
            if IsValid(ent) and EffectData then
                local fx = EffectData() fx:SetOrigin(ent:GetPos()) util.Effect("Sparks", fx, true, true)
                ent:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60)
            end
        end)
    end
    LC.StartTask(ply, 3, "Welding the seam...", { maxMove = 70,
        cancel = function() if IsValid(ent) then ent.lcWelding = nil end if sparks then timer.Remove(sparks) end end,
        done = function()
            if sparks then timer.Remove(sparks) end
            if IsValid(ent) then ent:Remove() end
            g.welded = g.welded + 1
        end })
    return false
end)

-- The harness the technician brings: the owner's pick when the server has the model, else a
-- technician's wrench.
local HARNESS, HARNESS_PLAIN = "models/galmastu/prop_tom/male_vest.mdl", "models/props_c17/tools_wrench01a.mdl"
local function HarnessModel()
    if file.Exists and file.Exists(HARNESS, "GAME") then return HARNESS end
    return HARNESS_PLAIN
end
local TECH_SECS = 660 -- (the part's time limit, and a minute over)
local TechGone

-- A technician waiting at the spot, harness in hand, watching the stalker come (the owner,
-- 7 November: nobody was there when you arrived, you stood in an empty space). When the stalker
-- gets there they step round behind it and work on its spine while it stands still (sparks, the
-- hiss of a welder), then go.
function LC.StalkerTechnician(ply, pos)
    if not IsValid(ply) or not (LC.Spawners and LC.Spawners.cop) then return nil end
    local ok, npc, st = pcall(LC.Spawners.cop, pos)
    if not (ok and IsValid(npc) and st) then return nil end
    st.unmanaged, st.questLock = true, true
    if LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = CurTime() + TECH_SECS
    npc:SetNW2String("lc_pname", "Overwatch technician")
    npc.lcTechFor = ply
    if LC.NPCCarry then pcall(LC.NPCCarry, npc, st, HarnessModel()) end
    if LC.Face then LC.Face(npc, ply:GetPos()) end
    local name = "LivingCityTech" .. npc:EntIndex()
    local working, ticks = false, 0
    timer.Create(name, 1, TECH_SECS, function()
        ticks = ticks + 1
        if not IsValid(npc) or not IsValid(ply) or ticks >= TECH_SECS then TechGone(npc) return end
        if not working then
            -- waiting: eyes on the stalker as it comes
            if ply:GetPos():DistToSqr(pos) > 200 * 200 then
                if LC.Face then LC.Face(npc, ply:GetPos()) end
                return
            end
            working = true
            if LC.NPCDropCarry then pcall(LC.NPCDropCarry, npc, st) end -- (the harness goes on the stalker now)
        end
        local behind = ply:GetPos() - ply:GetForward() * 38
        if npc:GetPos():DistToSqr(behind) > 60 * 60 then
            npc:SetLastPosition(behind)
            npc:SetSchedule(SCHED_FORCED_GO)
        else
            if LC.Face then LC.Face(npc, ply:GetPos()) end
            if LC.PlayGesture and math.random() < 0.5 then LC.PlayGesture(npc, { "ACT_PICKUP_RACK", "ACT_GESTURE_MELEE_ATTACK_SWING", "ACT_MELEE_ATTACK_SWING_GESTURE" }, 1) end
            if EffectData then
                local fx = EffectData() fx:SetOrigin(ply:GetPos() + Vector(0, 0, 50) - ply:GetForward() * 10) util.Effect("Sparks", fx, true, true)
            end
            npc:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60)
        end
    end)
    return npc
end
TechGone = function(npc)
    if not IsValid(npc) then return end
    timer.Remove("LivingCityTech" .. npc:EntIndex())
    local st = LC.NPCs and LC.NPCs[npc]
    if st then
        if LC.NPCDropCarry then pcall(LC.NPCDropCarry, npc, st) end
        st.unmanaged, st.questLock, st.eventUntil = nil, nil, 0
    end
    if LC.StartLeaving and st then LC.StartLeaving(npc, st, false, "an Overwatch technician going back") else npc:Remove() end
end

------------------------------------------------------------------------
-- The story
------------------------------------------------------------------------

local function Then(st, fn) local prev = st.onDone st.onDone = function(q, s) if prev then prev(q, s) end fn(q, s) end return st end

LC.Chain{
    id = "stalker", name = "The Stalker's Lot", factions = { citizen = true },
    unlock = Stalker, gate = Stalker, pace = 15,
    start = "processing",
    endings = {
        light = "You walked into the gap between the transformers. The current took the stalker that was you, all at once.",
        endured = "You turned away from it, and went back to work. It's still down there, humming. So are you.",
    },
    parts = {
        processing = { num = 1, next = "floors", build = function(ply)
            local pos = LC.StalkerSpot(ply)
            if not pos then return nil end
            -- the technician is there before you are, harness in hand (the owner, 7 November)
            local go = Goto(pos, "Report to the technician waiting where they keep you", 200)
            go.onEnter = function(q) if IsValid(q.owner) then q.data.tech = LC.StalkerTechnician(q.owner, pos) end end
            return {
                title = "Processing", reward = 0, limit = 600,
                desc = "They brought you up from below with a number where your name was, and a voice that can only scream. Report where you're kept: a technician is waiting there with the harness. Stand still while they finish you.",
                stages = {
                    Then(go, function(q)
                        if IsValid(q.owner) and not IsValid(q.data.tech) then q.data.tech = LC.StalkerTechnician(q.owner, pos) end
                        Narrate(q, "The Overwatch technician has been waiting for you, the harness in their hands. They step round behind you.")
                    end),
                    Then(Hold(pos, 20, "Stand still while the technician fits the harness", 160), function(q)
                        TechGone(q.data.tech)
                        Narrate(q, "Cold metal on your spine. A click. Your legs are yours to walk with, and nothing else.")
                    end),
                },
            }
        end },

        floors = { num = 2, next = "cable", build = function(ply)
            local a = LC.StalkerSpot(ply)
            local b = a and LC.StalkerSpot(ply, a)
            local c = b and LC.StalkerSpot(ply, b)
            if not c then return nil end
            return {
                title = "Floors", reward = 0, limit = 900,
                desc = "The holding floors are never clean. That's what you're for now: a push broom, and the grime.",
                stages = {
                    GameGo(a, "Go to the holding floor: your push broom's waiting", "scrub", { pos = a }),
                    Then(GameStage("Sweep up every patch of grime (E on each)"), function(q)
                        Narrate(q, "A Civil Protection unit steps over the broom without looking down. You are furniture that moves.")
                    end),
                },
            }
        end },

        cable = { num = 3, next = "frame", build = function(ply)
            local spots = Banks(ply, 2)
            if not spots then return nil end
            return {
                title = "Cable", reward = 0, limit = 900,
                desc = "Something new is going in below the Nexus, and it needs power. The cable runs from the banks. You run the cable.",
                stages = {
                    GameGo(spots[1], "Go to the power bank", "wiring", { pos = spots[1], what = "the power bank" }),
                    GameStage("Splice the cable in: turn the tiles till the current reaches the bank (a sparking tile bites)"),
                    GameGo(spots[2], "Now the next power bank", "wiring", { pos = spots[2], what = "the power bank" }),
                    Then(GameStage("Splice it in"), function(q)
                        Narrate(q, "The banks drop and surge. Somewhere under your feet, something drinks.")
                    end),
                },
            }
        end },

        frame = { num = 4, next = "charge", build = function(ply, data)
            local site, yaw, partner = Site(ply, data)
            if not site then return nil end
            local go = Goto(site, "Go to the frame they've set up, beside the power transformer", 200)
            go.onEnter = function(q) if IsValid(q.owner) then LC.StalkerEnergizer(q.owner, site, 0, yaw, partner) end end
            go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, "assemble", q, { pos = site }) end end
            return {
                title = "The frame", reward = 0, limit = 900,
                desc = "A second power transformer, to stand beside the city's own. A frame of black metal, waiting for you.",
                stages = {
                    go,
                    Then(GameStage("Carry the four containment cells to the frame and set them in (E), then weld the four seams (E on each)"), function(q)
                        LC.StalkerEnergizer(q.owner, site, 2)
                        Narrate(q, "Sparks, and then it's sealed. It stands beside the other one like a twin, a body's width apart.")
                    end),
                },
            }
        end },

        charge = { num = 5, build = function(ply, data)
            local site, yaw, partner = Site(ply, data)
            if not site then return nil end
            local go = Goto(site, "Go back to the transformer you built", 200)
            go.onEnter = function(q) if IsValid(q.owner) then LC.StalkerEnergizer(q.owner, site, 2, yaw, partner) end end
            go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, "wiring", q, { pos = site, what = "the terminal" }) end end
            return {
                title = "The charge", reward = 0, limit = 900,
                desc = "It needs its first charge. Then it's finished, and so are you, one way or another.",
                stages = {
                    go,
                    Then(GameStage("Route its first charge through the regulator: turn the tiles till the current reaches it"), function(q)
                        LC.StalkerEnergizer(q.owner, site, 3)
                        Narrate(q, "It hums, and then the current jumps the gap: a blue-white arc between the two transformers, snapping, never still. It is the most beautiful thing you have seen since they took you.")
                    end),
                    Choice("The Civil Protection units have stopped watching you. The arc snaps across the gap, and snaps again. It would be very easy to walk into it, and then there would be no more stalker.", {
                        { text = "Walk into the gap. (This person ends for good: you start over as someone new.)", pick = function(q, p)
                            q.chainEnd = "light"
                            Narrate(q, "You step into the gap.")
                            timer.Simple(1.5, function() if IsValid(p) then LC.StalkerStepIn(p) end end)
                        end },
                        { text = "Turn away, and go back to work.", pick = function(q, p)
                            q.chainEnd = "endured"
                            Narrate(q, "You turn your back on it. Behind you it hums, and hums.")
                            LC.StalkerEndure(p)
                        end },
                    }),
                },
            }
        end },
    },
}

-- A new term starts the story again from the top.
hook.Add("LivingCityStalker", "LivingCityStalkerWork", function(ply)
    if not LC.Story then return end
    local s = LC.Story(ply)
    if s.chains then s.chains.stalker = nil end
    if s.notified then s.notified.stalker = nil end
    if ply.lcStoryPostings then ply.lcStoryPostings.stalker = nil end
    Unbuild(ply)
    if LC.CheckUnlocks then LC.CheckUnlocks(ply) end
end)

