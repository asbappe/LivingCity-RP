--[[
    Living City: the stalker's lot

    What the Combine make of the worst anticitizens (sv_livingcity_custody.lua)
    is put to work, below, where only units go: the Combine areas (else the
    prison, else the checkpoints). A story on the board (F3), only for a
    stalker, in five parts:

      1 Processing   report to the Nexus and stand still while an Overwatch
                     technician fits the harness
      2 Floors       sweep the holding floor with a push broom (E on each
                     patch of grime)
      3 Cable        splice the cable into two power banks (a rewiring board
                     at each)
      4 The frame    a Combine ball energizer: carry its four cells over and
                     set them in, then weld its four seams
      5 The charge   route its first charge (a bigger rewiring board). It
                     hums. Nobody's watching.

    At the end you choose. Step into the light, and the stalker that was you is
    gone for good: whatever permanent death is set to, you start over as a new
    person. Or turn away and go back to work: there is no other way out of
    being a stalker. The energizer stays where you built it, humming, and you
    can walk back to it any time (E on it, twice) and step in after all.

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

function LC.StalkerEnergizer(ply, pos, built)
    local e = LC.Energizers[ply]
    if not IsValid(e) then
        if not pos then return nil end
        e = ents.Create("lc_energizer")
        if not IsValid(e) then return nil end
        e:SetPos(pos)
        e:SetAngles(Angle(0, math.random(0, 359), 0))
        e:Spawn()
        e.lcStalker = ply
        LC.Energizers[ply] = e
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

local function Site(ply, data)
    if not data.site then
        local p = LC.StalkerSpot(ply)
        if not p then return nil end
        data.site = { p.x, p.y, p.z }
    end
    return Vector(data.site[1], data.site[2], data.site[3])
end

-- The end of a stalker: into the light, and gone. A new person, whatever
-- permanent death is set to (sv_livingcity_character.lua).
function LC.StalkerStepIn(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local e = LC.Energizers[ply]
    if IsValid(e) then
        e:SetNW2Float("lc_flash", CurTime())
        e:EmitSound("weapons/physcannon/energy_disintegrate4.wav", 90)
        if util.Effect and EffectData then
            local fx = EffectData()
            fx:SetOrigin(e:WorldSpaceCenter())
            util.Effect("cball_explode", fx)
        end
    end
    ply:ScreenFade(SCREENFADE.OUT, Color(255, 255, 255, 255), 0.4, 2)
    ply.lcEndOfLife = "energizer"
    ply.lcDownCause = { "Stepped into the energizer they had built. Nothing came back out.", "combine" }
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
        LC.Notice(ply, "info", "Back to work", "The energizer hums behind you. It will still be there. E on it, twice, if you change your mind.", 8)
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
    if LC.Notice then LC.Notice(ply, "bad", "The light", "It would be very easy. Press E again to step in. There's no coming back.", 5) end
    return true
end
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

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30))) or p end
local function Around(center, n, rmin, rmax)
    local out = {}
    for i = 1, n * 4 do
        if #out >= n then break end
        local a = math.random() * math.pi * 2
        local r = math.Rand(rmin, rmax)
        local p = Ground(center + Vector(math.cos(a) * r, math.sin(a) * r, 0))
        if math.abs(p.z - center.z) < 60 then
            local clear = true
            for _, o in ipairs(out) do if o:DistToSqr(p) < 60 * 60 then clear = false end end
            if clear then out[#out + 1] = p end
        end
    end
    while #out < n do out[#out + 1] = center + Vector(math.random(-120, 120), math.random(-120, 120), 0) end
    return out
end

-- Something held in the stalker's hand (a push broom), on its arm wherever it goes.
local function InHand(ply, model)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(ply:GetPos() + Vector(0, 0, 40))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_NONE) end
    local att = ply.LookupAttachment and ply:LookupAttachment("anim_attachment_RH") or 0
    if att and att > 0 then
        e:SetParent(ply, att)
        if e.SetLocalPos then e:SetLocalPos(Vector(2, -2, -20)) end
        if e.SetLocalAngles then e:SetLocalAngles(Angle(0, 0, 0)) end
    else
        e:SetParent(ply)
        if e.SetLocalPos then e:SetLocalPos(Vector(20, 8, 10)) end
    end
    return e
end

-- The holding floor: grime here and there; a push broom (no kneeling: a stalker hasn't the legs
-- for it). E on each patch sweeps it up (a couple of seconds).
local SCRUB_N = 6
LC.JobGameDefine("scrub", {
    start = function(g)
        g.title = "The holding floor"
        g.stains, g.swept = {}, 0
        for _, p in ipairs(Around(g.opts.pos or g.ply:GetPos(), SCRUB_N, 80, 320)) do
            local e = ents.Create("lc_stain")
            if IsValid(e) then
                e:SetPos(p + Vector(0, 0, 1))
                e:SetAngles(Angle(0, math.random(0, 359), 0))
                e:Spawn()
                e.lcScrubFor = g.ply
                g.stains[#g.stains + 1] = e
                g.props[#g.props + 1] = e
            end
        end
        g.broom = InHand(g.ply, "models/props_c17/pushbroom.mdl")
        if IsValid(g.broom) then g.props[#g.props + 1] = g.broom end
        g.ply:ChatPrint("[Stalker] A push broom, and the floor. Walk to each patch of grime and sweep it up (E).")
        g.hud = function(gg) return { string.format("Swept: %d of %d", gg.swept, #gg.stains), "E on the grime sweeps it up" } end
    end,
    tick = function(g)
        -- (gone however it went: swept, or a city cleaner got there first)
        local left = 0
        for _, e in ipairs(g.stains) do if IsValid(e) then left = left + 1 end end
        g.swept = #g.stains - left
        if #g.stains > 0 and left == 0 then LC.JobGameEnd(g.ply, "done") end
    end,
})
hook.Add("PlayerUse", "LivingCityStalkerScrub", function(ply, ent)
    if not (IsValid(ent) and ent.lcScrubFor == ply) then return end
    local g = LC.JobGames and LC.JobGames[ply]
    if not g or g.kind ~= "scrub" or (LC.Busy and LC.Busy(ply)) or ent.lcSweeping then return false end
    ent.lcSweeping = true
    ply:EmitSound("physics/cardboard/cardboard_box_scrape_rough_loop1.wav", 55)
    LC.StartTask(ply, 2.5, "Sweeping it up...", { maxMove = 70,
        cancel = function() if IsValid(ent) then ent.lcSweeping = nil end end,
        done = function(p)
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

-- A technician who comes to fit the harness: walks up behind the stalker and works on its spine
-- while it stands still (sparks, the hiss of a welder), then goes.
function LC.StalkerTechnician(ply, pos)
    if not IsValid(ply) or not (LC.Spawners and LC.Spawners.cop) then return nil end
    local from = (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos)) or (pos + Vector(math.random(-300, 300), math.random(-300, 300), 0))
    local ok, npc, st = pcall(LC.Spawners.cop, from)
    if not (ok and IsValid(npc) and st) then return nil end
    st.unmanaged, st.questLock = true, true
    if LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = CurTime() + 120
    npc:SetNW2String("lc_pname", "Overwatch technician")
    npc.lcTechFor = ply
    local name = "LivingCityTech" .. npc:EntIndex()
    timer.Create(name, 1, 120, function()
        if not IsValid(npc) or not IsValid(ply) then timer.Remove(name) return end
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
local function TechGone(npc)
    if not IsValid(npc) then return end
    timer.Remove("LivingCityTech" .. npc:EntIndex())
    local st = LC.NPCs and LC.NPCs[npc]
    if st then st.unmanaged, st.questLock, st.eventUntil = nil, nil, 0 end
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
        light = "You stepped into the light you made. Nothing of the stalker came back out.",
        endured = "You turned away from it, and went back to work. It's still down there, humming. So are you.",
    },
    parts = {
        processing = { num = 1, next = "floors", build = function(ply)
            local pos = LC.StalkerSpot(ply)
            if not pos then return nil end
            return {
                title = "Processing", reward = 0, limit = 600,
                desc = "They brought you up from below with a number where your name was, and a voice that can only scream. Report where you're kept. Stand still while they finish you.",
                stages = {
                    Then(Goto(pos, "Report to the Nexus, where they keep you", 200), function(q)
                        if IsValid(q.owner) then q.data.tech = LC.StalkerTechnician(q.owner, pos) end
                        Narrate(q, "An Overwatch technician comes for you, tools in hand.")
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
            local site = Site(ply, data)
            if not site then return nil end
            local go = Goto(site, "Go to the frame they've set up", 200)
            go.onEnter = function(q) if IsValid(q.owner) then LC.StalkerEnergizer(q.owner, site, 0) end end
            go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, "assemble", q, { pos = site }) end end
            return {
                title = "The frame", reward = 0, limit = 900,
                desc = "A Combine ball energizer, they call it on the work order. A frame of black metal, waiting for you.",
                stages = {
                    go,
                    Then(GameStage("Carry the four containment cells to the frame and set them in (E), then weld the four seams (E on each)"), function(q)
                        LC.StalkerEnergizer(q.owner, site, 2)
                        Narrate(q, "Sparks, and then it's sealed. The light inside is brighter now. It doesn't flicker.")
                    end),
                },
            }
        end },

        charge = { num = 5, build = function(ply, data)
            local site = Site(ply, data)
            if not site then return nil end
            local go = Goto(site, "Go back to the energizer", 200)
            go.onEnter = function(q) if IsValid(q.owner) then LC.StalkerEnergizer(q.owner, site, 2) end end
            go.onDone = function(q) if IsValid(q.owner) then LC.JobGameStart(q.owner, "wiring", q, { pos = site, what = "the terminal" }) end end
            return {
                title = "The charge", reward = 0, limit = 900,
                desc = "It needs its first charge. Then it's finished, and so are you, one way or another.",
                stages = {
                    go,
                    Then(GameStage("Route its first charge through the regulator: turn the tiles till the current reaches it"), function(q)
                        LC.StalkerEnergizer(q.owner, site, 3)
                        Narrate(q, "It hums. A ball of white light turns slowly inside it, and it is the most beautiful thing you have seen since they took you.")
                    end),
                    Choice("The Civil Protection units have stopped watching you. The light turns, and turns. It would be very easy to step inside, and then there would be no more stalker.", {
                        { text = "Step into the light. (This person ends for good: you start over as someone new.)", pick = function(q, p)
                            q.chainEnd = "light"
                            Narrate(q, "You step forward. It's warm.")
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

