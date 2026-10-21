--[[
    Living City: more work you actually do (the engine is sv_livingcity_jobgames.lua)

      Parcel run (Courier)          Three parcels against the clock. They
          aren't letters. A unit that watches you too long calls you over:
          stand still for the search (and hope), or run. Crouching keeps
          your head down. Faster is better paid.
      Records terminal (Resistance) A timing puzzle on a Civil records
          terminal: stop the needle in the band, four times. A scanner sweeps
          past every few seconds: touch the panel while it's looking and it
          sees you. Twice and the alarm goes.
      Dead drop (Resistance)        Three places to hide the message. Crouch
          at one and keep still; if anyone sees you at it, that place is
          burned and you try another.
      Searching the dead (Mortuary) Before they go in the fire, every pocket.
          Log what you find, keep it, or set it aside for the family. The
          overseer looks in now and then: don't be caught keeping anything.
      Sorting (Uniform Laundry)     Civil Protection uniforms by division into
          the right bins, bloodstained ones to the incident wash. Units leave
          things in their pockets.
      Filing (Records Clerk)        Forms into the right drawer by citizen
          number, and anything that doesn't match the register into the
          discrepancy tray. The cabinet of blank forms is rarely locked.
      Repairs (Radio Repair)        Find the set's station on the dial, then
          turn its three trimmer screws (volume, squelch, alignment) by ear
          until it comes through clean. Now and then the clearest thing on
          the band is Freq 7.
      Pat-down (Civil Protection)   E on a citizen: pat them down, a pocket at
          a time, before they lose their nerve. Then release, confiscate or
          detain. Watch their hands.
      Breach (Civil Protection)     A housing block raid: blow the door, get
          everyone on the floor before they run or flush the evidence, then
          search the place.
]]

if CLIENT then return end

LC = LC or {}
local K = LC.JobGameKit
if not K then return end
local Pick, Shuffle, Mark = K.Pick, K.Shuffle, K.Mark

local function Note(g, s) g.notes[#g.notes + 1] = s end
local function Say(g, tag, s) if IsValid(g.ply) then g.ply:ChatPrint("[" .. tag .. "] " .. s) end end
local function Bar(f, n)
    n = n or 10
    local k = math.Clamp(math.floor(f * n + 0.5), 0, n)
    return "[" .. string.rep("#", k) .. string.rep("-", n - k) .. "]"
end
local function Give(ply, id, n) if LC.GiveOrDrop then LC.GiveOrDrop(ply, id, n or 1) elseif LC.GiveItem then LC.GiveItem(ply, id, n or 1) end end
local function Standing(ply, n, why) if LC.AddStanding then LC.AddStanding(ply, n, why) end end
local function Trait(ply, t, n) if LC.AddTrait then LC.AddTrait(ply, t, n) end end
local function Bump(ply, c) if LC.Bump then LC.Bump(ply, c) end end
local function Ground(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 48), endpos = pos - Vector(0, 0, 200), mask = MASK_SOLID_BRUSHONLY })
    return (tr and tr.Hit and tr.HitPos) or pos
end
local function Around(center, i, n, rmin, rmax)
    local a = (i / n) * math.pi * 2 + math.Rand(-0.4, 0.4)
    local r = math.Rand(rmin, rmax)
    return Ground(center + Vector(math.cos(a) * r, math.sin(a) * r, 0))
end

------------------------------------------------------------------------
-- Parcel run (Courier)
------------------------------------------------------------------------

local PARCELS = {
    { text = "A heavy little box, taped twice. It smells of gun oil.", hot = true },
    { text = "Soft and lumpy, wrapped in newspaper. Something inside sloshes.", hot = true },
    { text = "A flat tin, very light. It rattles when you turn it.", hot = false },
    { text = "A shoebox tied up with wire. It's warm, somehow.", hot = true },
    { text = "Medicine, by the label. The label is in somebody's handwriting.", hot = false },
    { text = "Books, by the weight. Nobody has said the word 'books' out loud in years.", hot = true },
}
local SEARCH_SECS = 5

local function ParcelWay(g)
    local s = g.stops[g.i]
    if s and LC.SetWaypoint then LC.SetWaypoint(g.ply, s.pos, s.name or "The next parcel", 130) end
end

LC.JobGameDefine("parcel", {
    start = function(g)
        g.title = "Parcel run"
        g.stops = g.opts.stops or {}
        if #g.stops == 0 then error("no stops") end
        g.i, g.heat, g.searches = 1, 0, 0
        g.parcel = g.opts.parcel or Pick(PARCELS)
        local dist, from = 0, g.ply:GetPos()
        for _, s in ipairs(g.stops) do dist = dist + from:Distance(s.pos) from = s.pos end
        g.limit = CurTime() + 45 + dist / 190
        Say(g, "Courier", g.parcel.text .. " Three to go, against the clock. Civil Protection units stop couriers they get a good look at: crouch past them, or stand still for the search.")
        ParcelWay(g)
        g.hud = function(gg)
            local s = gg.stops[gg.i]
            local left = gg.limit - CurTime()
            local lines = { string.format("Parcel %d of %d: %s", math.min(gg.i, #gg.stops), #gg.stops, s and s.name or "done"),
                left > 0 and string.format("%d seconds", math.ceil(left)) or "LATE",
                "Watched " .. Bar(gg.heat) }
            if gg.stopped then lines[#lines + 1] = string.format("SEARCH: stand still (%d), or run", math.max(0, math.ceil(gg.stopped.untilT - CurTime())))
            elseif gg.watched then lines[#lines + 1] = "A Civil Protection unit is looking at you. Crouch, or get out of sight." end
            return lines
        end
    end,
    tick = function(g, now)
        local ply = g.ply
        if g.stopped then
            local s = g.stopped
            if ply:GetPos():DistToSqr(s.at) > 110 * 110 then
                g.stopped, g.ran = nil, true
                g.cool = now + 20
                if LC.ReportCrime then LC.ReportCrime(ply, "Evading a search", 150) end
                if LC.Notice then LC.Notice(ply, "warn", "You ran", "Every Civil Protection unit in the sector has your description now. Get the parcels there anyway.", 7) end
            elseif now >= s.untilT then
                g.stopped = nil
                g.searches = g.searches + 1
                g.cool = now + 15
                if g.parcel.hot and math.random() < (g.opts.searchFinds or 0.6) then
                    g.seized = true
                    if LC.ReportCrime then LC.ReportCrime(ply, "Carrying contraband", 180) end
                    Note(g, "A Civil Protection unit opened the parcel. It's evidence now, and so are you.")
                    g.pay = 0
                    return LC.JobGameEnd(ply, "done")
                end
                Say(g, "Courier", "The Civil Protection unit turns it over, shakes it, and hands it back. 'Move along.'")
            end
            return
        end
        local w = (not g.cool or now > g.cool) and K.Watcher(ply, 550) or nil
        g.watched = w ~= nil
        if w then g.heat = math.min(1, g.heat + (ply:Crouching() and 0.018 or 0.045))
        else g.heat = math.max(0, g.heat - 0.03) end
        if g.heat >= 1 and IsValid(w) then
            g.heat = 0
            g.stopped = { by = w, at = ply:GetPos(), untilT = now + SEARCH_SECS }
            if LC.Face then LC.Face(w, ply:GetPos()) end
            w:EmitSound("npc/metropolice/vo/holditrightthere.wav", 75)
            if LC.Notice then LC.Notice(ply, "warn", "Halt!", "A Civil Protection unit wants to see the parcel. Stand still for the search, or run.", 5) end
            return
        end
        local s = g.stops[g.i]
        if ply:GetPos():DistToSqr(s.pos) < 130 * 130 then
            g.pay = g.pay + 3
            ply:EmitSound("buttons/button9.wav", 60)
            Say(g, "Courier", "Delivered, " .. (s.name or "here") .. ". Nobody signs for these.")
            g.i = g.i + 1
            if g.i > #g.stops then
                local left = g.limit - now
                if left > 0 then
                    g.pay = g.pay + math.floor(left / 10)
                    Note(g, string.format("%d seconds to spare.", math.floor(left)))
                else
                    Note(g, "Late.")
                end
                if g.searches == 0 and not g.ran then g.pay = g.pay + 2 Note(g, "Never stopped once.") end
                if g.parcel.hot then Note(g, "Whatever was in them, it got there.") end
                return LC.JobGameEnd(ply, "done")
            end
            ParcelWay(g)
        end
        if now > g.limit and not g.lateSaid then
            g.lateSaid = true
            Say(g, "Courier", "You're late. The rest still has to get there.")
        end
    end,
    finish = function(g) if IsValid(g.ply) and LC.SetWaypoint then LC.SetWaypoint(g.ply, nil) end end,
})

------------------------------------------------------------------------
-- Records terminal (Resistance): a timing puzzle while a scanner sweeps
------------------------------------------------------------------------

local HACK_NEED = 4
local SCANNER_MODEL = "models/combine_scanner.mdl"

local function Needle(g, now)
    local ph = ((now - g.t0) * g.speed) % 2
    return ph < 1 and ph or 2 - ph
end

local function HackPanel(g)
    local now = CurTime()
    LC.JobGamePanel(g, { band = g.band, w = g.bandW, speed = g.speed, t = now - g.t0, got = g.got, need = HACK_NEED,
        alarms = g.alarms, sweep = g.sweep or false, warn = g.warn or false, what = g.what })
end

local function NextSweep(g, now)
    g.sweep, g.warn = false, false
    g.warnAt = now + math.Rand(5, 8)
    g.sweepAt = g.warnAt + 2.5
    g.sweepEnd = g.sweepAt + 3
end

LC.JobGameDefine("hack", {
    start = function(g)
        g.title = "Records terminal"
        g.what = g.opts.what or "the records terminal"
        g.center = g.opts.pos or g.ply:GetPos()
        g.t0, g.speed = CurTime(), 0.55
        g.bandW = 0.2
        g.band = math.Rand(0.1, 0.9 - g.bandW)
        g.got, g.alarms, g.misses = 0, 0, 0
        NextSweep(g, CurTime())
        if K.Valid(SCANNER_MODEL) then
            local e = K.Spawn(SCANNER_MODEL, g.center + Vector(0, 0, 400), Angle(0, 0, 0), true)
            if IsValid(e) then
                e:SetNotSolid(true)
                if e.SetNoDraw then e:SetNoDraw(true) end
                g.scanner = e
                g.props[#g.props + 1] = e
            end
        end
        Say(g, "Operations", "Stop the needle in the band (click, or space), four times. When the scanner comes over, keep your hands off the panel.")
        g.hud = function(gg)
            return { string.format("Bypassed: %d of %d", gg.got, HACK_NEED), string.format("Seen by the scanner: %d of 2", gg.alarms),
                gg.sweep and "SCANNER OVERHEAD: hands off" or (gg.warn and "Scanner coming..." or "Clear") }
        end
        HackPanel(g)
    end,
    tick = function(g, now)
        local changed
        if not g.warn and not g.sweep and now >= g.warnAt then
            g.warn, changed = true, true
            if IsValid(g.scanner) then
                local side = VectorRand() side.z = 0
                side = side:GetNormalized()
                g.scanFrom, g.scanTo = g.center + side * 600 + Vector(0, 0, 130), g.center - side * 600 + Vector(0, 0, 130)
                if g.scanner.SetNoDraw then g.scanner:SetNoDraw(false) end
                g.scanner:EmitSound("npc/scanner/scanner_scan1.wav", 70)
            end
        end
        if g.warn and not g.sweep and now >= g.sweepAt then
            g.warn, g.sweep, changed = false, true, true
            if IsValid(g.scanner) then g.scanner:EmitSound("npc/scanner/scanner_photo1.wav", 75) end
        end
        if g.sweep and now >= g.sweepEnd then
            NextSweep(g, now)
            changed = true
            if IsValid(g.scanner) and g.scanner.SetNoDraw then g.scanner:SetNoDraw(true) end
        end
        if IsValid(g.scanner) and g.scanFrom and (g.warn or g.sweep) then
            local f = math.Clamp((now - g.warnAt) / (g.sweepEnd - g.warnAt), 0, 1)
            g.scanner:SetPos(LerpVector(f, g.scanFrom, g.scanTo))
            g.scanner:SetAngles((g.scanTo - g.scanFrom):Angle())
        end
        if changed and g.panelOpen then HackPanel(g) end
    end,
    act = function(g, action, arg)
        if action == "away" then LC.JobGamePanel(g, nil) return true end
        if action ~= "try" then return nil end
        local now = CurTime()
        if g.sweep then
            g.alarms = g.alarms + 1
            if IsValid(g.scanner) then g.scanner:EmitSound("npc/scanner/scanner_alarm1.wav", 80) end
            if g.alarms >= 2 then
                g.tripped = true
                if LC.ReportCrime then LC.ReportCrime(g.ply, "Tampering with a Combine terminal", 180) end
                Note(g, "The scanner saw you twice: the alarm's going. Get out.")
                g.pay = g.got * 2
                LC.JobGameEnd(g.ply, "done")
                return false
            end
            Say(g, "Operations", "The scanner's light catches your hands on the panel. Once more and it calls it in.")
            HackPanel(g)
            return false
        end
        local at = tonumber(arg)
        if not at or at < 0 or at > 1 then at = Needle(g, now) end
        local hit = at >= g.band - 0.01 and at <= g.band + g.bandW + 0.01
        if hit then
            g.got = g.got + 1
            g.ply:EmitSound("buttons/button14.wav", 60)
            if g.got >= HACK_NEED then
                g.pay = 8 + (g.alarms == 0 and 6 or 0) + (g.misses == 0 and 2 or 0)
                if g.alarms == 0 then Note(g, "The scanner never saw a thing.") end
                if g.opts.onDone then pcall(g.opts.onDone, g.ply) end
                LC.JobGameEnd(g.ply, "done")
                return true
            end
            g.speed = g.speed * 1.25
            g.bandW = math.max(0.07, g.bandW * 0.8)
            g.band = math.Rand(0.05, 0.95 - g.bandW)
        else
            g.misses = g.misses + 1
            g.got = math.max(0, g.got - 1)
            g.ply:EmitSound("buttons/button10.wav", 60)
        end
        HackPanel(g)
        return hit
    end,
    use = function(g) if not g.panelOpen then HackPanel(g) return true end end,
})
LC.HackNeedle = Needle

------------------------------------------------------------------------
-- Dead drop (Resistance): hide it where nobody sees you do it
------------------------------------------------------------------------

local DROP_SPOTS = {
    { "models/props_junk/TrashBin01a.mdl", "the bin" }, { "models/props_c17/oildrum001.mdl", "the oil drum" },
    { "models/props_junk/cardboard_box003a.mdl", "the box" }, { "models/props_junk/wood_crate001a.mdl", "the crate" },
}
local HIDE_SECS = 2.5

LC.JobGameDefine("drop", {
    start = function(g)
        g.title = "Dead drop"
        local center = g.opts.pos or g.ply:GetPos()
        g.spots, g.seen, g.maxSeen, g.burned = {}, 0, 0, 0
        local kinds = Shuffle(table.Copy(DROP_SPOTS))
        for i = 1, 3 do
            local k = kinds[i]
            local e = K.Spawn(K.Valid(k[1]) and k[1] or "models/props_junk/cardboard_box003a.mdl", Around(center, i, 3, 90, 240) + Vector(0, 0, 4), Angle(0, math.random(0, 359), 0), true)
            if IsValid(e) then
                e.lcDropName = k[2]
                Mark(e, g.ply, "target")
                g.spots[#g.spots + 1] = e
                g.props[#g.props + 1] = e
            end
        end
        if #g.spots == 0 then error("nowhere to hide it") end
        Say(g, "Operations", "Three places to leave it. E on one, then crouch and keep still. If anyone sees you at it, that one's burned.")
        g.hud = function(gg)
            local lines = { "Seen " .. Bar(gg.seen), string.format("Places burned: %d of %d", gg.burned, #gg.spots) }
            if gg.hiding then lines[#lines + 1] = gg.hiding.paused and "Crouch, close to it, to hide it" or ("Hiding it... " .. math.floor(100 * gg.hiding.t / HIDE_SECS) .. "%")
            else lines[#lines + 1] = "E on a hiding place (outlined)" end
            return lines
        end
    end,
    use = function(g, ent)
        if g.hiding or not ent.lcDropName or ent.lcBurned then return nil end
        for _, e in ipairs(g.spots) do
            if e == ent then
                g.hiding = { ent = ent, t = 0 }
                return true
            end
        end
    end,
    tick = function(g, now)
        local ply = g.ply
        local h = g.hiding
        local w = K.Watcher(ply, 700, true)
        if h and IsValid(h.ent) then
            h.paused = not ply:Crouching() or ply:GetPos():DistToSqr(h.ent:GetPos()) > 110 * 110
            if not h.paused then
                h.t = h.t + 0.1
                if w then g.seen = math.min(1, g.seen + 0.06) end
            end
            g.maxSeen = math.max(g.maxSeen, g.seen)
            if g.seen >= 1 then
                h.ent.lcBurned = true
                Mark(h.ent, ply, "danger")
                g.burned, g.hiding, g.seen = g.burned + 1, nil, 0.4
                if LC.Notice then LC.Notice(ply, "warn", "Burned", "Someone saw you at " .. h.ent.lcDropName .. ". Not that one: try another.", 6) end
                if g.burned >= #g.spots then
                    Note(g, "Every place was watched. The message goes home with you.")
                    g.pay = 0
                    return LC.JobGameEnd(ply, "done")
                end
                return
            end
            if h.t >= HIDE_SECS then
                g.pay = 6 + (g.burned == 0 and 4 or 0) + (g.maxSeen < 0.3 and 2 or 0)
                Note(g, "Left in " .. h.ent.lcDropName .. ".")
                if g.maxSeen < 0.3 then Note(g, "Nobody looked twice.") end
                if g.opts.onDone then pcall(g.opts.onDone, ply) end
                return LC.JobGameEnd(ply, "done")
            end
        else
            g.hiding = nil
            g.seen = math.max(0, g.seen - 0.03)
        end
    end,
})

------------------------------------------------------------------------
-- Searching the dead (Mortuary), before the incinerator
------------------------------------------------------------------------

local POCKETS = { "Coat", "Trouser pockets", "Shoes", "Lining" }
local FINDS = {
    { label = "Identity papers, still valid", item = "papers_dead", value = 2, stolen = true },
    { label = "Ration coupons, two days' worth", item = "ration", value = 1 },
    { label = "A wedding ring", item = "keepsake", value = 1, family = true },
    { label = "Loose pistol rounds", item = "ammo_pistol", value = 2, contraband = true, stolen = true },
    { label = "A folded note: a name and an address", item = "paper", value = 1, family = true },
    { label = "A data chip, sewn into the hem", item = "data_chip", value = 3, contraband = true, stolen = true },
    { label = "A photograph of two children", value = 0, family = true },
}
local BODY_MODELS = { "models/Humans/Group01/male_02.mdl", "models/Humans/Group01/male_07.mdl", "models/Humans/Group01/female_02.mdl",
    "models/Humans/Group01/male_04.mdl", "models/Humans/Group01/female_04.mdl" }
local BODIES = 3

local function SearchPanel(g)
    local p = {}
    for i, k in ipairs(g.pockets or {}) do
        p[i] = { name = k.name, open = k.open, find = k.open and k.find and k.find.label or nil, family = k.find and k.find.family or false, done = k.done }
    end
    LC.JobGamePanel(g, { n = g.n, of = BODIES, pockets = p, watching = g.watching or false })
end

local function NextBody(g)
    g.n = (g.n or 0) + 1
    if g.n > BODIES then return false end
    local pos = g.slab + Vector(math.Rand(-20, 20), math.Rand(-20, 20), 8)
    local body = LC.SpawnBody and LC.SpawnBody(Pick(BODY_MODELS), pos, "citizen")
    if not IsValid(body) then
        body = ents.Create("prop_ragdoll")
        if IsValid(body) then body:SetModel(Pick(BODY_MODELS)) body:SetPos(pos) body:Spawn() end
    end
    if not IsValid(body) then error("no body") end
    body.lcBody = body.lcBody or { role = "citizen" }
    body.lcBody.claimed = true
    Mark(body, g.ply, "target")
    g.body = body
    g.props[#g.props + 1] = body
    g.pockets = {}
    for i, name in ipairs(POCKETS) do
        g.pockets[i] = { name = name, find = math.random() < 0.45 and Pick(FINDS) or nil }
    end
    return true
end

local function Burn(g)
    if IsValid(g.body) then
        for i, e in ipairs(g.props) do if e == g.body then table.remove(g.props, i) break end end
        g.body:Remove()
    end
    local inc = g.opts.inc
    if not IsValid(inc) then
        local best, bd
        for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_incinerator") or {}) do
            local d = e:GetPos():DistToSqr(g.slab)
            if not bd or d < bd then best, bd = e, d end
        end
        inc = best
    end
    if IsValid(inc) then inc:SetNW2Float("lc_burn_until", CurTime() + 8) inc:EmitSound("ambient/fire/ignite.wav", 75) end
    g.burned = (g.burned or 0) + 1
end

LC.JobGameDefine("search", {
    start = function(g)
        g.title = "Searching the dead"
        g.slab = g.opts.pos or (g.ply:GetPos() + g.ply:GetForward() * 70)
        g.logged, g.kept, g.caught = 0, 0, 0
        g.watching = false
        g.watchAt = CurTime() + math.Rand(8, 12)
        NextBody(g)
        Say(g, "Morgue", "Three for the fire tonight. E on the body: every pocket before it goes in. Log it, keep it, or set it aside for the family. The overseer looks in now and then.")
        g.hud = function(gg)
            return { string.format("Body %d of %d", math.min(gg.n, BODIES), BODIES), string.format("Logged: %d    Kept: %d", gg.logged, gg.kept),
                gg.watching and "THE OVERSEER IS WATCHING" or "The overseer is out of the room", "E on the body to search it" }
        end
    end,
    tick = function(g, now)
        if now >= g.watchAt then
            g.watching = not g.watching
            g.watchAt = now + (g.watching and math.Rand(5, 7) or math.Rand(10, 16))
            if g.watching then
                g.ply:EmitSound("doors/door1_move.wav", 60)
                Say(g, "Morgue", "The door opens. The overseer leans on the frame, watching you work.")
            else
                Say(g, "Morgue", "The overseer goes back out. You're alone with them.")
            end
            if g.panelOpen then SearchPanel(g) end
        end
    end,
    use = function(g, ent) if ent == g.body then SearchPanel(g) return true end end,
    act = function(g, action, arg)
        local i = tonumber(arg)
        local k = i and g.pockets[i]
        if action == "open" and k and not k.open then
            k.open = true
            if not k.find then k.done = "empty" end
        elseif (action == "log" or action == "keep" or action == "family") and k and k.open and k.find and not k.done then
            local f = k.find
            if action == "log" then
                k.done = "log"
                g.logged = g.logged + 1
                g.pay = g.pay + f.value
                if f.contraband then Standing(g.ply, 1, "logged contraband from the dead") end
            elseif action == "keep" then
                if g.watching then
                    k.done = "log"
                    g.caught = g.caught + 1
                    g.pay = g.pay - 3
                    Standing(g.ply, -3, "caught stealing from the dead")
                    Say(g, "Morgue", "The overseer clears his throat. 'In the tray.' It goes in the tray, and in his notebook.")
                else
                    k.done = "keep"
                    g.kept = g.kept + 1
                    if f.item then Give(g.ply, f.item, 1) end
                    if f.stolen then Bump(g.ply, "thefts") end
                end
            else
                k.done = "family"
                Trait(g.ply, "sympathy", 1)
            end
        elseif action == "burn" then
            Burn(g)
            if not NextBody(g) then
                if g.caught == 0 then g.pay = g.pay + 3 end
                Note(g, string.format("%d logged, %d kept.", g.logged, g.kept))
                if g.caught > 0 then Note(g, "The overseer wrote your name down.") end
                LC.JobGameEnd(g.ply, "done")
                return true
            end
            Say(g, "Morgue", "Into the fire. The next one's on the slab.")
            LC.JobGamePanel(g, nil)
            return true
        else
            return nil
        end
        SearchPanel(g)
        return true
    end,
})

------------------------------------------------------------------------
-- Sorting (Uniform Laundry)
------------------------------------------------------------------------

local DIVISIONS = { "UNION", "DEFENDER", "HERO", "JURY", "KING", "LINE", "QUICK", "ROLLER", "STICK", "TAP", "VICE", "XRAY" }
local POCKET_FINDS = {
    { "a folded note", "paper" }, { "a pistol magazine", "ammo_pistol" }, { "ration coupons", "ration" },
    { "a door keycard", "cp_keycard" }, { "a ration bar, half eaten", "ration" },
}
local UNIFORMS = 12

local function NextUniform(g)
    g.n = g.n + 1
    if g.n > UNIFORMS then g.u = nil return end
    local div = Pick(g.divs)
    local u = { div = div, tag = string.format("%s-%02d", div, math.random(1, 24)), stain = math.random() < 0.2 }
    if math.random() < 0.25 then local p = Pick(POCKET_FINDS) u.pocket, u.item = p[1], p[2] end
    g.u = u
end

local function LaundryPanel(g)
    local u = g.u or {}
    LC.JobGamePanel(g, { bins = g.bins, tag = u.tag, stain = u.stain, pocket = u.pocket, n = g.n, of = UNIFORMS, secs = math.max(0, math.ceil(g.limit - CurTime())) })
end

LC.JobGameDefine("laundry", {
    start = function(g)
        g.title = "Sorting"
        local divs = Shuffle(table.Copy(DIVISIONS))
        g.divs, g.bins = {}, {}
        for b = 1, 4 do
            local two = { divs[b * 2 - 1], divs[b * 2] }
            g.divs[#g.divs + 1], g.divs[#g.divs + 1] = two[1], two[2]
            g.bins[b] = { label = two[1] .. " / " .. two[2], divs = two }
        end
        g.bins[5] = { label = "Incident wash (bloodstained)", divs = {} }
        g.n, g.right, g.wrong = 0, 0, 0
        g.limit = CurTime() + 100
        NextUniform(g)
        g.hud = function(gg)
            return { string.format("Uniforms: %d of %d", math.min(gg.n, UNIFORMS), UNIFORMS), string.format("Right: %d    Wrong: %d", gg.right, gg.wrong),
                string.format("%d seconds", math.max(0, math.ceil(gg.limit - CurTime()))) }
        end
        LaundryPanel(g)
    end,
    tick = function(g, now)
        if now > g.limit then
            Note(g, "The shift ran out with uniforms still on the pile.")
            g.pay = math.max(0, g.right - g.wrong)
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
    use = function(g) if not g.panelOpen then LaundryPanel(g) return true end end,
    act = function(g, action, arg)
        local u = g.u
        if not u then return nil end
        if action == "pocket" and u.pocket then
            Give(g.ply, u.item, 1)
            if math.random() < 0.25 then
                Standing(g.ply, -2, "a Civil Protection unit's pocket came back short")
                Say(g, "Laundry", "The supervisor counts what comes out of the pockets. Tonight he counts one short, and looks at you.")
            end
            u.pocket = nil
        elseif action == "turnin" and u.pocket then
            g.pay = g.pay + 1
            Standing(g.ply, 1, "turned in what a Civil Protection unit left in a pocket")
            u.pocket = nil
        elseif action == "sort" then
            local b = g.bins[tonumber(arg) or 0]
            if not b then return nil end
            local right
            if u.stain then right = tonumber(arg) == 5
            else right = b.divs[1] == u.div or b.divs[2] == u.div end
            if right then g.right = g.right + 1 g.pay = g.pay + 1 g.ply:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 55)
            else g.wrong = g.wrong + 1 g.pay = g.pay - 1 g.ply:EmitSound("buttons/button10.wav", 55) end
            if u.pocket then Say(g, "Laundry", "Whatever was in the pocket went in with it.") end
            NextUniform(g)
            if not g.u then
                if g.wrong == 0 then g.pay = g.pay + 3 Note(g, "Not one in the wrong bin.") end
                Note(g, string.format("%d of %d sorted right.", g.right, UNIFORMS))
                LC.JobGameEnd(g.ply, "done")
                return right
            end
            LaundryPanel(g)
            return right
        else
            return nil
        end
        LaundryPanel(g)
        return true
    end,
})

------------------------------------------------------------------------
-- Filing (Records Clerk)
------------------------------------------------------------------------

local FILE_NAMES = { "Anya Vasek", "Pavel Orlov", "Mira Kessler", "Tomas Hrabal", "Ilse Brandt", "Jonas Petrov", "Lena Duric",
    "Viktor Sorel", "Hana Novak", "Emil Strand", "Katya Lind", "Oskar Benes", "Rosa Kalnin", "Dmitri Arkov" }
local STATUSES = { "Active", "Relocated", "Detained", "Deceased", "Active", "Relocated" }
local DRAWERS = { "00-24", "25-49", "50-74", "75-99", "Discrepancy" }
local FORMS = 10

local function Misspell(s)
    local i = math.random(2, math.max(2, #s - 2))
    if string.sub(s, i, i) == " " or string.sub(s, i + 1, i + 1) == " " then i = 2 end
    return string.sub(s, 1, i - 1) .. string.sub(s, i + 1, i + 1) .. string.sub(s, i, i) .. string.sub(s, i + 2)
end

local function NextForm(g)
    g.n = g.n + 1
    if g.n > FORMS then g.form = nil return end
    local name = Pick(FILE_NAMES)
    local cid = string.format("%02d-%03d", math.random(0, 99), math.random(100, 999))
    local f = { name = name, cid = cid, status = Pick(STATUSES), regName = name, regCid = cid }
    if math.random() < 0.3 then
        f.bad = true
        if math.random() < 0.5 then
            local m = Misspell(name)
            if m == name then m = name .. "a" end
            f.name = m
        else
            local a, b = string.match(cid, "^(%d)(%d)")
            f.cid = (a == b) and string.format("%02d-%s", (tonumber(a .. b) + 11) % 100, string.sub(cid, 4)) or (b .. a .. string.sub(cid, 3))
        end
    end
    g.form = f
end

local function DrawerOf(cid) return math.floor((tonumber(string.sub(cid, 1, 2)) or 0) / 25) + 1 end
LC.FilingDrawerOf = DrawerOf

local function FilingPanel(g)
    local f = g.form or {}
    LC.JobGamePanel(g, { drawers = DRAWERS, name = f.name, cid = f.cid, status = f.status, regName = f.regName, regCid = f.regCid,
        n = g.n, of = FORMS, secs = math.max(0, math.ceil(g.limit - CurTime())), blank = not g.tookBlank })
end

LC.JobGameDefine("filing", {
    start = function(g)
        g.title = "Filing"
        g.n, g.right, g.wrong = 0, 0, 0
        g.limit = CurTime() + 110
        NextForm(g)
        g.hud = function(gg)
            return { string.format("Forms: %d of %d", math.min(gg.n, FORMS), FORMS), string.format("Right: %d    Wrong: %d", gg.right, gg.wrong),
                string.format("%d seconds", math.max(0, math.ceil(gg.limit - CurTime()))) }
        end
        FilingPanel(g)
    end,
    tick = function(g, now)
        if now > g.limit then
            Note(g, "Forms left in the in-tray. They'll be there tomorrow.")
            g.pay = math.max(0, g.right - g.wrong)
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
    use = function(g) if not g.panelOpen then FilingPanel(g) return true end end,
    act = function(g, action, arg)
        if action == "blank" and not g.tookBlank then
            g.tookBlank = true
            if K.Watcher(g.ply, 600) then
                Standing(g.ply, -4, "caught taking a blank identity form")
                if LC.ReportCrime then LC.ReportCrime(g.ply, "Theft of state forms", 120) end
                Say(g, "Records", "A Civil Protection unit at the counter watches you put it back.")
            else
                Give(g.ply, "papers_blank", 1)
                Bump(g.ply, "thefts")
                Say(g, "Records", "One blank identity form, folded into your sleeve.")
            end
            FilingPanel(g)
            return true
        end
        if action ~= "file" or not g.form then return nil end
        local d = tonumber(arg)
        if not d or d < 1 or d > 5 then return nil end
        local f = g.form
        local right = (f.bad and d == 5) or (not f.bad and d == DrawerOf(f.cid))
        if right then g.right = g.right + 1 g.pay = g.pay + 1 g.ply:EmitSound("physics/wood/wood_box_impact_soft1.wav", 55)
        else g.wrong = g.wrong + 1 g.pay = g.pay - 1 g.ply:EmitSound("buttons/button10.wav", 55) end
        NextForm(g)
        if not g.form then
            if g.wrong == 0 then g.pay = g.pay + 3 Note(g, "A clean in-tray.") end
            Note(g, string.format("%d of %d filed right.", g.right, FORMS))
            LC.JobGameEnd(g.ply, "done")
            return right
        end
        FilingPanel(g)
        return right
    end,
})

------------------------------------------------------------------------
-- Radio repair: a set's trimmer screws, set by ear. Tune it to its station
-- (the dial), then turn the screws with the screwdriver until it comes
-- through clean: the volume trimmer brings the station up, the squelch
-- pushes the static down, the alignment pulls a smeared signal into focus.
-- Sometimes the clearest thing on the band is Freq 7.
------------------------------------------------------------------------

local RADIOS = 4
local SCREWS = { "Volume trimmer", "Squelch", "Alignment" }
local GOOD_SCREW = 0.7 -- (how close each must be: within about a tenth of a turn's range)
-- (seconds for each set: lc_radio_set_secs)
local cvSetSecs = CreateConVar("lc_radio_set_secs", "120", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Radio repair: seconds for each set on the bench before it goes back on the shelf unfixed")

-- How right a screw is: 1 on the spot, 0 a third of the range off.
local function ScrewQ(v, want) return math.Clamp(1 - math.abs((tonumber(v) or 0) - want) / 0.33, 0, 1) end
LC.RadioScrewQuality = ScrewQ
local FREQ7 = {
    "'...this is Freq 7. They count the rations and they count you. Count them back...'",
    "'...the third shift at the station is short two Civil Protection units on Tuesdays. Freq 7, out...'",
    "'...if you can hear this, you are not alone. Freq 7...'",
    "'...the Administrator's broadcasts are recorded. She is not in the city. Freq 7...'",
}

-- What the sets play (sv_livingcity_announcer.lua: sound/livingcity/announce/radio/):
-- the repairer's own screen mixes static and stations by the dial
-- (cl_livingcity_moregames.lua), and so do the screens of whoever is near the bench.
local function Clip(trig) if LC.RadioClip then return LC.RadioClip(trig) end end

-- Everyone near the bench hears the set: the dial and what's on it, a few
-- times a second, to players within earshot (their screens mix it, fading out
-- by about twenty feet: cl_livingcity_moregames.lua).
local BENCH_SEND = 400

local function Bench(g, off)
    local ply = g.ply
    if not IsValid(ply) then return end
    local to = {}
    for _, p in ipairs(player.GetAll()) do
        if p == ply or p:GetPos():DistToSqr(ply:GetPos()) < BENCH_SEND * BENCH_SEND then to[#to + 1] = p end
    end
    g.heardBy = to
    LC.SendCompressed("lc_radio_bench", off and { e = ply:EntIndex(), off = true } or {
        e = ply:EntIndex(), dial = g.dial or 98, t = g.target, f7 = g.f7, heard = g.heard and true or false,
        screws = g.screws, turn = g.turn, static = g.staticClip, union = g.unionClip, clip7 = g.f7clip }, to)
end

local function NewRadio(g)
    g.n = g.n + 1
    if g.n > RADIOS then return false end
    g.target = math.floor(math.Rand(88.5, 107) * 10 + 0.5) / 10
    g.f7, g.f7msg, g.f7clip = nil, nil, nil
    if math.random() < (g.opts.freq7 or 0.25) then
        if LC.Freq7Freqs then -- (always one of the seven: sv_livingcity_freq7.lua)
            g.f7 = LC.Freq7Freqs[math.random(#LC.Freq7Freqs)]
            if math.abs(g.f7 - g.target) <= 3 then g.target = math.floor(math.Rand(88.5, 97) * 10 + 0.5) / 10 end
        else
            repeat g.f7 = math.floor(math.Rand(88.5, 107) * 10 + 0.5) / 10 until math.abs(g.f7 - g.target) > 3
        end
        local path, text = Clip("freq7")
        g.f7clip = path
        g.f7msg = (text and ("'..." .. text .. "...'")) or (path and "A voice comes through the static, on Freq 7.") or Pick(FREQ7)
    end
    g.unionClip = Clip("union")
    -- where each screw should be, and where whoever last opened it left it (well off)
    g.screws, g.turn = {}, {}
    for i = 1, #SCREWS do
        g.screws[i] = math.Rand(0.1, 0.9)
        repeat g.turn[i] = math.Rand(0, 1) until math.abs(g.turn[i] - g.screws[i]) > 0.3
    end
    g.radioEnd = CurTime() + math.max(20, cvSetSecs:GetFloat())
    g.heard = nil
    return true
end

local function RadioPanel(g)
    LC.JobGamePanel(g, { n = g.n, of = RADIOS, t = g.target, f7 = g.f7, heard = g.heard and g.f7msg or nil, dial = g.dial,
        screws = g.screws, turn = g.turn, names = SCREWS, last = g.last,
        static = g.staticClip, union = g.unionClip, clip7 = g.f7clip,
        secs = math.max(0, math.ceil(g.radioEnd - CurTime())) })
end

local function RadioDone(g)
    if not NewRadio(g) then
        if g.fixed == RADIOS then g.pay = g.pay + 3 Note(g, "Every set on the shelf works.") end
        Note(g, string.format("%d of %d fixed.", g.fixed, RADIOS))
        LC.JobGameEnd(g.ply, "done")
        return
    end
    RadioPanel(g)
end

LC.JobGameDefine("radio", {
    start = function(g)
        g.title = "Radio repair"
        g.n, g.fixed = 0, 0
        g.staticClip = Clip("static")
        NewRadio(g)
        g.hud = function(gg)
            return { string.format("Set %d of %d", math.min(gg.n, RADIOS), RADIOS), string.format("Fixed: %d", gg.fixed),
                "Find its station, then the screws: by ear",
                string.format("%d seconds on this one", math.max(0, math.ceil(gg.radioEnd - CurTime()))) }
        end
        RadioPanel(g)
    end,
    tick = function(g, now)
        if (g.benchAt or 0) <= now then g.benchAt = now + 0.25 Bench(g) end
        if now > g.radioEnd and not g.heard then
            Say(g, "Radio", "Out of time: it goes back on the shelf, still hissing.")
            g.last = "timeout"
            RadioDone(g)
        end
    end,
    use = function(g) if not g.panelOpen then RadioPanel(g) return true end end,
    act = function(g, action, arg)
        if action == "dial" then
            local f = tonumber(arg)
            if f then g.dial = math.Clamp(f, 87.5, 108) end
            return true
        end
        if action == "screw" then
            -- { i, v }: a screw turned (so whoever's near hears the set change too)
            local i, v = istable(arg) and tonumber(arg[1]), istable(arg) and tonumber(arg[2])
            if not i or not g.turn[i] or not v then return nil end
            g.turn[i] = math.Clamp(v, 0, 1)
            return true
        end
        if action == "lock" then
            if g.heard then return nil end
            -- the dial, and the screws as they are on the bench: { f = 95.5, s = { ... } } (or just the dial)
            local f = istable(arg) and tonumber(arg.f) or tonumber(arg)
            if not f then return nil end
            if istable(arg) and istable(arg.s) then
                for i in ipairs(g.turn) do if tonumber(arg.s[i]) then g.turn[i] = math.Clamp(tonumber(arg.s[i]), 0, 1) end end
            end
            g.dial = f
            if math.abs(f - g.target) <= 0.3 then
                -- on its station: is it clean?
                local worst, wq = nil, 1
                for i, want in ipairs(g.screws) do
                    local q = ScrewQ(g.turn[i], want)
                    if q < wq then worst, wq = i, q end
                end
                if wq < GOOD_SCREW then
                    g.radioEnd = g.radioEnd - 2
                    g.ply:EmitSound("buttons/button10.wav", 55)
                    Say(g, "Radio", ({ "It's there, but so faint you'd miss it. The volume trimmer.",
                        "It's there, under a wall of hiss. The squelch.", "It's there, but smeared across the dial. The alignment." })[worst])
                    RadioPanel(g)
                    return "adjust"
                end
                g.fixed = g.fixed + 1
                g.pay = g.pay + 3 + math.floor(math.max(0, g.radioEnd - CurTime()) / 10)
                g.ply:EmitSound("buttons/button3.wav", 60)
                g.last = "fixed"
                RadioDone(g)
                return true
            elseif g.f7 and math.abs(f - g.f7) <= 0.3 then
                g.heard = true
                g.radioEnd = g.radioEnd + 10
                RadioPanel(g)
                return "freq7"
            end
            g.radioEnd = g.radioEnd - 3
            g.ply:EmitSound("buttons/button10.wav", 55)
            RadioPanel(g)
            return false
        elseif action == "freq7" and g.heard then
            if arg == "report" then
                g.pay = g.pay + 2
                Standing(g.ply, 2, "reported an illegal broadcast")
                Bump(g.ply, "reports")
                Say(g, "Radio", "You write the frequency on a slip for the Civil Protection units. Somebody will be listening for it now.")
            elseif arg == "note" then
                Trait(g.ply, "sympathy", 1)
                Bump(g.ply, "silences")
                Give(g.ply, "freq7_sheet", 1)
                g.ply.lcFreq7Heard = g.f7
                Say(g, "Radio", "You copy it down where nobody will look: Freq 7, and the seven places on the dial it hides. "
                    .. "A Freq 7 sheet, in your pockets (contraband: pass it on, or burn it).")
            else
                Say(g, "Radio", "You tune past it. Nothing on this band is worth what it costs.")
            end
            g.heard, g.f7, g.f7clip = nil, nil, nil
            RadioPanel(g)
            return true
        end
        return nil
    end,
    finish = function(g) Bench(g, true) end,
})

-- A Freq 7 sheet, read: the rule, and the seven frequencies it gives.
function LC.Freq7SheetText(heard)
    local list = {}
    for _, f in ipairs(LC.Freq7Freqs or {}) do list[#list + 1] = string.format("%.1f", f) end
    return "FREQ 7\n\nThey only broadcast where the digits add up to seven. There are seven places on the dial:\n\n"
        .. table.concat(list, "   ") .. "\n\n"
        .. (heard and string.format("Heard it on %.1f at the repair bench. ", heard) or "")
        .. "When the Combine find it, it moves: try the next one.\n\nListen low. Never where a unit can hear it."
end
function LC.ReadItem(ply, id)
    if id ~= "freq7_sheet" or not LC.HasItem(ply, id) then return false end
    if LC.SendRead then LC.SendRead(ply, { text = LC.Freq7SheetText(ply.lcFreq7Heard), sig = "(in a cramped hand)" }) end
    return true
end

------------------------------------------------------------------------
-- Listening to a radio of your own (the Union radio, or one retuned to
-- Freq 7): Listen, from your pockets. The same dial as the repair bench:
-- static between stations, the station fading in through it, and whoever is
-- within about twenty feet hears it too. The Union band sits where it always
-- does; Freq 7 moves every so often, and a retuned radio knows where to.
-- Freq 7 coming out of your radio where a unit can hear it is a crime.
------------------------------------------------------------------------

local UNION_FREQ = 96.4
local freq7, freq7Until = nil, 0

function LC.RadioStations()
    if LC.Freq7Now then return UNION_FREQ, LC.Freq7Now().f end -- (the seven frequencies, and the Combine hunting it: sv_livingcity_freq7.lua)
    if CurTime() > freq7Until or not freq7 then
        repeat freq7 = math.floor(math.Rand(88.5, 107) * 10 + 0.5) / 10 until math.abs(freq7 - UNION_FREQ) > 3
        freq7Until = CurTime() + 20 * 60
    end
    return UNION_FREQ, freq7
end

LC.Listening = LC.Listening or {} -- [ply] = { dial, item, static, union, clip7, caughtAt }

local function ListenSend(ply, l, off)
    local to = {}
    for _, p in ipairs(player.GetAll()) do
        if p == ply or p:GetPos():DistToSqr(ply:GetPos()) < BENCH_SEND * BENCH_SEND then to[#to + 1] = p end
    end
    if off then return LC.SendCompressed("lc_radio_bench", { e = ply:EntIndex(), off = true }, to) end
    local u, f7 = LC.RadioStations()
    local n = LC.Freq7Now and LC.Freq7Now() or { clip = l.clip7, loop = true }
    LC.SendCompressed("lc_radio_bench", { e = ply:EntIndex(), dial = l.dial, t = u, f7 = f7, heard = false,
        static = l.static, union = l.union, clip7 = n.clip, seq7 = n.seq, once7 = not n.loop }, to)
end

local function ListenOff(ply, why)
    local l = LC.Listening[ply]
    if not l then return end
    LC.Listening[ply] = nil
    if IsValid(ply) then
        ListenSend(ply, l, true)
        net.Start("lc_radio_listen") net.WriteString("{}") net.Send(ply)
        if why then ply:ChatPrint("[Radio] " .. why) end
    end
end
LC.RadioListenOff = ListenOff

-- Listen (already on: the window again, where you left the dial; it has its own off switch).
function LC.RadioListen(ply, id)
    if not IsValid(ply) then return false end
    if LC.InCustody and LC.InCustody(ply) then return false, "Not in here." end
    local u, f7 = LC.RadioStations()
    local l = LC.Listening[ply] or { item = id, dial = (id == "radio_tuned") and f7 or u, static = Clip("static"), union = Clip("union"), clip7 = Clip("freq7"), followed = f7 }
    LC.Listening[ply] = l
    net.Start("lc_radio_listen")
    net.WriteString(util.TableToJSON({ dial = l.dial, t = u, f7 = f7, static = l.static, union = l.union, clip7 = l.clip7,
        tuned = id == "radio_tuned" }))
    net.Send(ply)
    ListenSend(ply, l)
    return true
end

function LC.RadioListenDial(ply, f)
    local l = LC.Listening[ply]
    if not l then return false end
    f = tonumber(f)
    if not f or f <= 0 then ListenOff(ply) return true end
    l.dial = math.Clamp(f, 87.5, 108)
    return true
end

net.Receive("lc_radio_dial", function(_, ply)
    if (ply.lcRadioDialAt or 0) > CurTime() then return end
    ply.lcRadioDialAt = CurTime() + 0.1
    LC.RadioListenDial(ply, net.ReadFloat())
end)

timer.Create("LivingCityRadioListen", 0.25, 0, function()
    for ply, l in pairs(LC.Listening) do
        if not IsValid(ply) then
            LC.Listening[ply] = nil
        elseif not ply:Alive() or (LC.InCustody and LC.InCustody(ply)) then
            ListenOff(ply)
        elseif not LC.HasItem(ply, l.item) then
            ListenOff(ply, "Your radio's gone.")
        else
            -- a Resistance radio follows Freq 7 when it hops (the cell gave you the hop sheet)
            local _, f7 = LC.RadioStations()
            local onAir = not LC.Freq7Now or LC.Freq7Now().onAir
            if l.item == "radio_tuned" and onAir and l.followed ~= f7 then
                if l.followed and math.abs(l.dial - l.followed) <= 0.6 then
                    l.dial = f7
                    net.Start("lc_radio_listen") net.WriteString(util.TableToJSON({ follow = f7 })) net.Send(ply)
                end
                l.followed = f7
            end
            ListenSend(ply, l)
            -- the pirate band, out loud, where a unit can hear it
            if onAir and math.abs(l.dial - f7) <= 0.6 and CurTime() - (l.caughtAt or -999) > 120 and not LC.PlayerIsCP(ply)
                and LC.SeenBySecurity and LC.SeenBySecurity(ply, 300) then
                l.caughtAt = CurTime()
                if LC.ReportCrime then LC.ReportCrime(ply, "Listening to an illegal broadcast", 120) end
                if LC.Notice then LC.Notice(ply, "warn", "A Civil Protection unit heard that", "Freq 7, out loud, in front of Civil Protection. Turn it off, or run.", 6) end
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityRadioListen", function(ply) LC.Listening[ply] = nil end)

------------------------------------------------------------------------
-- Pat-down (Civil Protection)
------------------------------------------------------------------------

local ZONES = { "Coat", "Left pocket", "Right pocket", "Waistband", "Boots", "Bag" }
local TELLS = {
    "They hold their coat closed with one hand.", "Their left hand keeps drifting to their pocket.",
    "They keep their right side turned away from you.", "They won't stop tugging their shirt down.",
    "They shift their weight off one foot.", "They hold the bag tight against them.",
}
local CONTRABAND = { { "a pistol magazine", "ammo_pistol" }, { "a Resistance leaflet", "paper" }, { "a forged ration card", "ration_forged" },
    { "a lockpick", "lockpick" }, { "a data chip", "data_chip" } }

local function PatPanel(g)
    local s = g.subject
    if not s then return LC.JobGamePanel(g, nil) end
    local zones = {}
    for i, z in ipairs(ZONES) do zones[i] = { name = z, done = s.searched[i] and true or false, found = (s.searched[i] and s.hidden == i) and s.what[1] or nil } end
    LC.JobGamePanel(g, { zones = zones, tell = s.tell, nerve = s.nerve, found = s.found and s.what[1] or nil, n = g.done + 1, of = g.need })
end

local function Unhold(g, s, walk)
    if not s or not IsValid(s.npc) then return end
    s.npc:SetNW2String("lc_jg_mark", "")
    if s.st then s.st.questLock = nil s.st.patted = CurTime() s.st.eventUntil = 0 end
    if walk and s.st then
        if LC.SetState then LC.SetState(s.npc, s.st, "idle") end
        s.st.untilT = CurTime() + 2
    end
end

local function Verdict(g, v)
    local s = g.subject
    if not s then return nil end
    local ply = g.ply
    if v == "confiscate" and not s.found then return nil end
    if v == "release" then
        if s.hidden and not s.found then g.missed = g.missed + 1 Say(g, "CP", "They walk off lighter on their feet than they should.")
        elseif s.found then Trait(ply, "sympathy", 1) Say(g, "CP", "You hand it back. They don't say thank you; they don't dare.")
        else g.right = g.right + 1 g.pay = g.pay + 2 end
        Unhold(g, s, true)
    elseif v == "confiscate" then
        g.right = g.right + 1
        g.pay = g.pay + 3
        Say(g, "CP", "Confiscated: " .. s.what[1] .. ". Logged as evidence.")
        Unhold(g, s, true)
    elseif v == "detain" then
        if s.found then
            g.right = g.right + 1
            g.pay = g.pay + 5
            Unhold(g, s, false)
            if LC.ArrestNPC then LC.ArrestNPC(s.npc, ply) end
        else
            g.wrong = g.wrong + 1
            g.pay = g.pay - 3
            Say(g, "CP", "Detained with nothing on them. Dispatch is not impressed, and neither is the street.")
            Unhold(g, s, true)
        end
    else
        return nil
    end
    g.subject = nil
    g.done = g.done + 1
    LC.JobGamePanel(g, nil)
    if g.done >= g.need then
        if g.wrong == 0 and g.missed == 0 then g.pay = g.pay + 3 Note(g, "Every call right.") end
        Note(g, string.format("%d searched, %d right.", g.done, g.right))
        LC.JobGameEnd(ply, "done")
    end
    return true
end
LC.PatdownVerdict = Verdict

LC.JobGameDefine("patdown", {
    start = function(g)
        g.title = "Pat-down"
        g.need = g.opts.need or 3
        g.done, g.right, g.wrong, g.missed, g.bolted = 0, 0, 0, 0, 0
        Say(g, "CP", "Stop citizens on the street: E on one. Pat them down a place at a time before they lose their nerve. Watch their hands.")
        g.hud = function(gg)
            local lines = { string.format("Searched: %d of %d", gg.done, gg.need), string.format("Right calls: %d", gg.right) }
            lines[#lines + 1] = gg.subject and string.format("Their nerve: %s", Bar(gg.subject.nerve / 4, 4)) or "E on a citizen to stop them"
            return lines
        end
    end,
    use = function(g, ent)
        if g.subject then
            if ent == g.subject.npc then PatPanel(g) return true end
            return nil
        end
        local st = LC.NPCs and LC.NPCs[ent]
        if not st or st.role ~= "citizen" or st.questLock or st.test or st.state == "jailed" then return nil end
        if st.patted and CurTime() - st.patted < 300 then Say(g, "CP", "You searched that one already.") return nil end
        st.questLock = true
        if LC.SetState then LC.SetState(ent, st, "event") end
        st.eventUntil = CurTime() + 90
        if ent.SetSchedule then ent:SetSchedule(SCHED_IDLE_STAND) end
        if LC.Face then LC.Face(ent, g.ply:GetPos()) end
        local hidden = math.random() < (g.opts.carry or 0.55) and math.random(#ZONES) or nil
        local tell
        if hidden and math.random() < 0.7 then tell = TELLS[hidden]
        elseif math.random() < 0.5 then tell = Pick(TELLS) end
        g.subject = { npc = ent, st = st, hidden = hidden, what = Pick(CONTRABAND), tell = tell, searched = {}, nerve = 4 }
        Mark(ent, g.ply, "person")
        g.ply:EmitSound("npc/metropolice/vo/apply.wav", 70)
        PatPanel(g)
        return true
    end,
    tick = function(g)
        local s = g.subject
        if s and (not IsValid(s.npc) or s.npc:Health() <= 0) then g.subject = nil LC.JobGamePanel(g, nil) end
    end,
    act = function(g, action, arg)
        local s = g.subject
        if not s then return nil end
        if action == "pat" then
            local i = tonumber(arg)
            if not i or not ZONES[i] or s.searched[i] then return nil end
            s.searched[i] = true
            if s.hidden == i then
                s.found = true
                g.ply:EmitSound("physics/cardboard/cardboard_box_impact_soft1.wav", 55)
            else
                s.nerve = s.nerve - 1
                if s.nerve <= 0 then
                    g.bolted = g.bolted + 1
                    g.done = g.done + 1
                    Unhold(g, s, false)
                    if s.npc.SetLastPosition then
                        s.npc:SetLastPosition(s.npc:GetPos() + VectorRand():GetNormalized() * 900)
                        s.npc:SetSchedule(SCHED_FORCED_GO_RUN)
                    end
                    s.npc:EmitSound("vo/npc/male01/runforyourlife01.wav", 75)
                    Say(g, "CP", "They lose their nerve and bolt.")
                    if s.hidden then Note(g, "One bolted with something on them.") end
                    g.subject = nil
                    LC.JobGamePanel(g, nil)
                    if g.done >= g.need then
                        Note(g, string.format("%d searched, %d right.", g.done, g.right))
                        LC.JobGameEnd(g.ply, "done")
                    end
                    return "bolted"
                end
            end
            PatPanel(g)
            return s.found and s.hidden == i
        elseif action == "verdict" then
            return Verdict(g, tostring(arg))
        end
        return nil
    end,
    finish = function(g) if g.subject then Unhold(g, g.subject, true) end end,
})

------------------------------------------------------------------------
-- Breach (Civil Protection, a housing block raid)
------------------------------------------------------------------------

local STASHES = { "models/props_c17/FurnitureDrawer001a.mdl", "models/props_junk/cardboard_box001a.mdl", "models/props_c17/suitcase001a.mdl",
    "models/props_junk/wood_crate001a.mdl", "models/props_c17/FurnitureDresser001a.mdl" }
local DOOR_CLASSES = { prop_door_rotating = true, func_door_rotating = true, func_door = true }

local function Room(g)
    g.phase = "room"
    g.roomT = CurTime()
    g.limit = CurTime() + 120
    local center = g.inside or g.center
    g.res, g.stash = {}, {}
    for i = 1, math.random(2, 3) do
        local npc = K.Extra(g, Around(center, i, 3, 60, 160), 600)
        if IsValid(npc) then
            g.res[#g.res + 1] = { npc = npc, until_ = CurTime() + 9 + i * 2 }
            Mark(npc, g.ply, "person")
            if LC.Face then LC.Face(npc, g.ply:GetPos()) end
        end
    end
    local models = Shuffle(table.Copy(STASHES))
    local n = 3
    local hot = math.random(1, n)
    for i = 1, n do
        local m = K.Valid(models[i]) and models[i] or "models/props_junk/cardboard_box001a.mdl"
        local e = K.Spawn(m, Around(center, i + 0.5, n, 80, 200) + Vector(0, 0, 4), Angle(0, math.random(0, 359), 0), true)
        if IsValid(e) then
            local has = i == hot or math.random() < 0.35
            e.lcStash = { has = has, what = has and Pick(CONTRABAND)[1] or nil }
            Mark(e, g.ply, "target")
            g.stash[#g.stash + 1] = e
            g.props[#g.props + 1] = e
        end
    end
    g.ply:EmitSound("npc/metropolice/vo/getdown.wav", 80)
    Say(g, "CP", "Everyone on the floor: E on each of them before they run or get rid of something. Then search the place (E on the furniture).")
end

LC.JobGameDefine("breach", {
    start = function(g)
        g.title = "Breach"
        g.center = g.opts.pos or g.ply:GetPos()
        g.secured, g.fled, g.flushed, g.found = 0, 0, 0, 0
        local best, bd
        for _, e in ipairs(ents.FindInSphere(g.center, 700)) do
            if IsValid(e) and DOOR_CLASSES[e:GetClass()] then
                local d = e:GetPos():DistToSqr(g.center)
                if not bd or d < bd then best, bd = e, d end
            end
        end
        if IsValid(best) and not g.opts.noDoor then
            g.door, g.phase = best, "door"
            Mark(best, g.ply, "target")
            Say(g, "CP", "The door's locked. E on it to set the charge, then stand back.")
        else
            Room(g)
        end
        g.hud = function(gg)
            if gg.phase == "door" then return { gg.blowAt and "Charge set: stand back" or "E on the door to set the charge" } end
            local left = 0
            for _, r in ipairs(gg.res or {}) do if not r.done then left = left + 1 end end
            local unsearched = 0
            for _, e in ipairs(gg.stash or {}) do if IsValid(e) and not e.lcStash.searched then unsearched = unsearched + 1 end end
            return { string.format("On the floor: %d    Ran: %d    Still standing: %d", gg.secured, gg.fled, left),
                string.format("Found: %d    Flushed: %d    To search: %d", gg.found, gg.flushed, unsearched),
                string.format("%d seconds", math.max(0, math.ceil((gg.limit or 0) - CurTime()))) }
        end
    end,
    use = function(g, ent)
        if g.phase == "door" then
            if ent ~= g.door or g.blowAt then return nil end
            g.blowAt = CurTime() + 2.5
            ent:EmitSound("buttons/blip1.wav", 70)
            return true
        end
        for _, r in ipairs(g.res or {}) do
            if r.npc == ent and not r.done then
                r.done = "secured"
                g.secured = g.secured + 1
                g.pay = g.pay + 2
                Mark(ent, g.ply, "done")
                ent:EmitSound("vo/npc/male01/ok01.wav", 65)
                return true
            end
        end
        local s = ent.lcStash
        if s and not s.searched then
            s.searched = true
            Mark(ent, g.ply, "done")
            if s.has and not s.flushed then
                g.found = g.found + 1
                g.pay = g.pay + 3
                Say(g, "CP", "Found: " .. s.what .. ".")
            else
                Say(g, "CP", s.flushed and "Ash, and the smell of burnt paper. Too late." or "Nothing.")
            end
            return true
        end
    end,
    tick = function(g, now)
        if g.phase == "door" then
            if g.blowAt and now >= g.blowAt then
                local d = g.door
                if IsValid(d) then
                    d:Fire("Unlock")
                    d:Fire("Open")
                    d:EmitSound("physics/wood/wood_crate_break3.wav", 90)
                    if EffectData then local fx = EffectData() fx:SetOrigin(d:WorldSpaceCenter()) util.Effect("Sparks", fx, true, true) end
                    -- the room's on the far side of the door from where we stood
                    local away = (d:WorldSpaceCenter() - g.ply:GetPos()) away.z = 0
                    g.inside = d:WorldSpaceCenter() + away:GetNormalized() * 160
                end
                Room(g)
            end
            return
        end
        for _, r in ipairs(g.res) do
            if not r.done then
                if not IsValid(r.npc) then r.done = "gone"
                elseif now > r.until_ then
                    local hot
                    for _, e in ipairs(g.stash) do if IsValid(e) and e.lcStash.has and not e.lcStash.searched and not e.lcStash.flushed then hot = e break end end
                    if hot and math.random() < 0.5 then
                        hot.lcStash.flushed = true
                        g.flushed = g.flushed + 1
                        r.done = "flushed"
                        Mark(r.npc, g.ply, "danger")
                        Say(g, "CP", "Somebody's burning something. Whatever it was, it's gone.")
                    else
                        r.done = "fled"
                        g.fled = g.fled + 1
                        g.pay = g.pay - 1
                        K.Release(g, r.npc, r.npc:GetPos() + VectorRand():GetNormalized() * 1200, 15)
                        Say(g, "CP", "One of them's out the back.")
                    end
                end
            end
        end
        local open = 0
        for _, r in ipairs(g.res) do if not r.done then open = open + 1 end end
        for _, e in ipairs(g.stash) do if IsValid(e) and not e.lcStash.searched then open = open + 1 end end
        if open == 0 or now > g.limit then
            if g.fled == 0 and g.flushed == 0 then g.pay = g.pay + 4 Note(g, "Nobody ran, nothing burned.") end
            Note(g, string.format("%d on the floor, %d ran, %d found.", g.secured, g.fled, g.found))
            return LC.JobGameEnd(g.ply, "done")
        end
    end,
})
