--[[
    Living City: the stalker's lot

    What the Combine make of the worst anticitizens (sv_livingcity_custody.lua)
    is put to work, below, where only units go: the Combine areas (else the
    prison, else the checkpoints). A story on the board (F3), only for a
    stalker, in five parts:

      1 Processing   report to the Nexus and stand still while they fit you
      2 Floors       scrub the holding floors, on your knees
      3 Cable        splice the cable at the power banks
      4 The frame    a Combine ball energizer: seat its cells, weld it shut
      5 The charge   feed it its first charge. It hums. Nobody's watching.

    At the end you choose. Step into the light, and the stalker that was you is
    gone for good: whatever permanent death is set to, you start over as a new
    person. Or turn away and go back to work, and the city, pleased with its
    property, lets you go a little early (on probation).

    Your term doesn't run out in the middle of a part. The stalker playermodel
    is Workshop 268895264 (lc_stalker_model in sv_livingcity_custody.lua).
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Hold, Choice, Narrate, Pick = Q.Goto, Q.Hold, Q.Choice, Q.Narrate, Q.Pick

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

-- Turned away: the city is pleased with its property, and lets it go soon.
function LC.StalkerEndure(ply)
    if not IsValid(ply) or not Stalker(ply) then return false end
    local left = 120
    ply:SetNW2Float("lc_stalker_until", CurTime() + left)
    ply:SetPData("lc_stalker_until", os.time() + left)
    if LC.Notice then
        LC.Notice(ply, "info", "Two more minutes", "The energizer hums behind you. A unit marks something on a pad. In two minutes they let you go, on probation.", 8)
    end
    Unbuild(ply, 300)
    return true
end

hook.Add("PlayerDisconnected", "LivingCityStalkerWork", function(ply) Unbuild(ply) end)
hook.Add("LivingCityStalkerFreed", "LivingCityStalkerWork", function(ply) Unbuild(ply, 300) end)
hook.Add("LivingCityNewCharacter", "LivingCityStalkerWork", function(ply) Unbuild(ply, 60) end)

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
        endured = "You turned away from it, and went back to work. In a little while they let you go.",
    },
    parts = {
        processing = { num = 1, next = "floors", build = function(ply)
            local pos = LC.StalkerSpot(ply)
            if not pos then return nil end
            return {
                title = "Processing", reward = 0, limit = 600,
                desc = "They brought you up from below with your mouth sewn shut and a number where your name was. Report where you're kept. Stand still while they finish you.",
                stages = {
                    Goto(pos, "Report to the Nexus, where they keep you", 200),
                    Then(Hold(pos, 20, "Stand still while they fit the harness", 160), function(q)
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
                desc = "The holding floors are never clean. That's what you're for now.",
                stages = {
                    Hold(a, 12, "Scrub the floor here, on your knees (crouch)", 160, true),
                    Hold(b, 12, "And here (crouch)", 160, true),
                    Then(Hold(c, 12, "And here, where the drain is (crouch)", 160, true), function(q)
                        Narrate(q, "A unit steps over you without looking down. You are furniture that moves.")
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
                    Hold(spots[1], 15, "Splice the cable into the power bank", 160),
                    Then(Hold(spots[2], 15, "And into the next one", 160), function(q)
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
            return {
                title = "The frame", reward = 0, limit = 900,
                desc = "A Combine ball energizer, they call it on the work order. A frame of black metal, waiting for you.",
                stages = {
                    go,
                    Then(Hold(site, 20, "Seat the containment cells", 160), function(q)
                        LC.StalkerEnergizer(q.owner, site, 1)
                        Narrate(q, "The cells click home. A faint light wakes in the middle of the frame.")
                    end),
                    Then(Hold(site, 20, "Weld the housing shut", 160), function(q)
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
            return {
                title = "The charge", reward = 0, limit = 900,
                desc = "It needs its first charge. Then it's finished, and so are you, one way or another.",
                stages = {
                    go,
                    Then(Hold(site, 25, "Feed it its first charge", 160), function(q)
                        LC.StalkerEnergizer(q.owner, site, 3)
                        Narrate(q, "It hums. A ball of white light turns slowly inside it, and it is the most beautiful thing you have seen since they took you.")
                    end),
                    Choice("The units have stopped watching you. The light turns, and turns. It would be very easy to step inside, and then there would be no more stalker.", {
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

-- True while a stalker is in the middle of a part (their term waits for it).
function LC.StalkerWorking(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    return q ~= nil and not q.done and q.chain == "stalker"
end
