--[[
    Living City: the Administrator's order to flush the sewers

    The owner, 19 November, of the sealed quarter behind the containment wall and its
    tunnel to the sewers (lc_ravenholm.vmf): "I would like the combine to have ways to
    open them, but just giving the administrator a button on her tablet to open them is
    too powerful ... her tablet mentions them and she can trigger a combine wide quest
    to infiltrate the infested quarter you just built and go into the tunnels and open
    the door from the other side. Obviously that would only be practical if the rebels
    are causing trouble and the combine want them flushed out". And of the job: "the
    gate is open for like 60 seconds and the quest has a step to set up a power bank
    and turrets before opening the containment wall, and once they are all inside the
    gate closes. Then they are committed to finishing the quest and when they open the
    sewer door, they have the option to head back out the way they came or push forward
    into the rebel territory to get out".

      The order      F2 > City orders > "Send the units to flush the sewers". Only the
                     City Administrator, once a city day, and only while the Resistance
                     hold ground underground (the owner, 20 November: rebel ground under
                     a roof and below the street at the wall). It opens nothing: it puts
                     one job on both Combine boards.
      The job        "Flush the sewers", one job for Civil Protection and the Overwatch
                     together (up to 8, with the squad a violent job brings):
                       1. the briefing (the owner, 20 November: "This would all need a
                          briefing beforehand"): an officer on the Combine's own ground
                          nearest the wall (at the wall where they have none) says the
                          plan to whoever walks up and uses him;
                       2. put up a power bank and two turrets at the containment wall
                          (F2 > Unit tools: on this job, at the wall, any unit may);
                       3. the wall opens by itself as the last of them goes up, and
                          stays open a minute: get inside. It shuts when every unit on
                          the job is in, or when the minute is up. Whoever is still
                          outside is off the job;
                       4. find the tunnel house in the quarter (the infected are there);
                       5. down the tunnel, rewire the console at the Combine door (the
                          wiring game, for whoever reaches it; if they fall, the next).
                     The door opens: the map sends its zombies into the sewers, the
                     city's own infestation takes hold at the sewer end, and the
                     Resistance lose strength. The door shuts itself ten minutes later.
      Getting out    The job ends as the door opens. Whoever went in may go on through
                     the sewers, or back to the wall: it opens for them as they reach
                     it (and for anyone left inside when a job fails).
      The Resistance Their two jobs with the same quarter (shutting that door again from the
                     quarter's side; their leader's order to open the wall from inside)
                     are in sv_livingcity_breach.lua.
      The map        Nine names, all from lc_ravenholm.vmf (_dev/tools/map_raven.py):
                     the relays lc_raven_gate_open / _shut and lc_raven_door_open /
                     _shut, and the marks lc_raven_post, lc_raven_inside,
                     lc_raven_house, lc_raven_console and lc_raven_sewer. Any missing:
                     the order is not on her tablet. Marks named lc_raven_spawn, if
                     there are any, are where the quarter's infected wait.
      Testing        F4 > Admin testing tools > "Order the sewer flush now" (no waiting
                     for the Resistance or the day; says which names are missing).
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Count, Narrate, Members = Q.Goto, Q.Count, Q.Narrate, Q.Members

LC.Flush = LC.Flush or {}
local F = LC.Flush
F.GATE_TAKES = 12      -- seconds the wall takes to open or shut (the map's: 11.4)
F.GATE_OPEN = 60       -- seconds it stays open for the units to go in
F.OUT_OPEN = 30        -- and for someone coming back out
F.DOOR_OPEN = 600      -- seconds the sewer door stays open
F.TURRETS = 2          -- turrets to put up at the wall, with one power bank
F.POST_R = 700         -- how near the wall they count (a power bank's own reach)
F.NEAR = 500           -- how near a mark by the wall someone is seen to be on that side of it
F.CLEAR = 96           -- how far past the wall counts as in (clear of it as it shuts)
F.CONSOLE_R = 200      -- how near the console starts the rewiring
F.ZOMBIES = 10         -- the quarter's infected, at most (one to a mark)
F.PATCH_R = 400        -- the infested ground that takes hold at the sewer end
F.REWARD = 80          -- XP
F.LIMIT = 1800         -- the job's time
F.AGAIN = 2400         -- seconds before the order can be given again where the ledger keeps no days
F.DEEP = 96            -- how far below the street at the wall rebel ground under a roof counts as underground
F.RESIST = -6          -- what the Resistance lose as the door opens
F.AUTHORITY = -4       -- what the Administrator loses when the job is taken and fails
F.inside = F.inside or {}   -- [ply] = true: went in through the wall, and has not come out or died since
F.gate = F.gate or "shut"
F.door = F.door or "shut"

local NAMES = { "lc_raven_gate_open", "lc_raven_gate_shut", "lc_raven_door_open", "lc_raven_door_shut",
    "lc_raven_post", "lc_raven_inside", "lc_raven_house", "lc_raven_console", "lc_raven_sewer" }
F.NAMES = NAMES

------------------------------------------------------------------------
-- The map's part
------------------------------------------------------------------------

local map, lookedAt
-- What the map has for it, or nil and the names it lacks.
function F.Map()
    if map then
        local whole = true
        for _, e in pairs(map.ents) do if not IsValid(e) then whole = false break end end
        if whole then return map end
        map = nil
    end
    local now = CurTime()
    if lookedAt and now - lookedAt < 10 then return nil, F.missing end
    lookedAt = now
    local found, missing = {}, {}
    for _, n in ipairs(NAMES) do
        local e = ents.FindByName and ents.FindByName(n)[1]
        if IsValid(e) then found[n] = e else missing[#missing + 1] = n end
    end
    F.missing = missing
    if #missing > 0 then return nil, missing end
    local post, inside = found.lc_raven_post:GetPos(), found.lc_raven_inside:GetPos()
    local nx, ny = inside.x - post.x, inside.y - post.y
    local len = math.max(1, math.sqrt(nx * nx + ny * ny))
    map = {
        ents = found, post = post, inside = inside,
        house = found.lc_raven_house:GetPos(), console = found.lc_raven_console:GetPos(), sewer = found.lc_raven_sewer:GetPos(),
        gateConsole = (function()
            local e = ents.FindByName and ents.FindByName("lc_raven_gate_console")[1]
            return IsValid(e) and e:GetPos() or nil
        end)(),
        -- the wall: midway between the two marks, facing in
        midX = (post.x + inside.x) / 2, midY = (post.y + inside.y) / 2, nx = nx / len, ny = ny / len,
    }
    return map
end
function F.MapForget() map, lookedAt = nil, nil end

-- Which side of the wall someone by it is on: true in, false out, nil when they are not by it.
function F.Side(pos, m)
    local d = (pos.x - m.midX) * m.nx + (pos.y - m.midY) * m.ny
    if d > F.CLEAR and pos:DistToSqr(m.inside) < F.NEAR * F.NEAR then return true end
    if d < 0 and pos:DistToSqr(m.post) < F.NEAR * F.NEAR then return false end
    return nil
end

local function Pull(name)
    local m = F.Map()
    if m and IsValid(m.ents[name]) then m.ents[name]:Fire("Trigger") end
end

function F.OpenGate(secs)
    Pull("lc_raven_gate_open")
    F.gate, F.gateShutAt = "open", CurTime() + F.GATE_TAKES + (secs or F.GATE_OPEN)
end
function F.ShutGate()
    if F.gate ~= "open" then return end
    Pull("lc_raven_gate_shut")
    F.gate, F.gateShutAt, F.letOut = "shut", nil, nil
    F.gateNext = CurTime() + F.GATE_TAKES + 5
end

-- One notice to everyone of these sides (the only place this file and sv_livingcity_breach.lua put text on a screen).
function F.Tell(sides, title, text)
    if not LC.Notice then return end
    for _, p in ipairs(player.GetAll()) do
        if sides[LC.QuestFaction and LC.QuestFaction(p) or ""] then LC.Notice(p, "info", title, text) end
    end
end

-- A spot on a side's own ground nearest `pos` (nil: it has none).
function F.OwnGround(kind, pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind(kind) or {}) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    if not best then return nil end
    return LC.SpotInZone and LC.SpotInZone(best) or best.pos
end

-- A briefing first (the owner, 20 November: "This would all need a briefing beforehand"): one of their own stands
-- at posFn() and says the plan, in one line, to whoever on the job walks up and uses them (E). With nobody to
-- give it (no such ground, or he is dead), the job goes straight on.
function F.Briefing(text, role, posFn, line)
    local st = Count("used_npc", 1, text, function(q, _, npc) return npc ~= nil and npc == q.data.briefer end)
    st.untallied = true
    st.onEnter = function(q, s)
        local pos = posFn(q)
        local npc = pos and Q.SpawnActor(q, role, pos, 1800) or nil
        q.data.briefer = IsValid(npc) and npc or nil
        s.npc, s.pos = q.data.briefer, pos
    end
    st.poll = function(q) if not IsValid(q.data.briefer) then Q.Advance(q) end end
    st.onDone = function(q)
        local npc = q.data.briefer
        if not IsValid(npc) then return end
        Narrate(q, line)
        -- (he has said it: he goes about his day, and is not taken away with the job)
        for i, e in ipairs(q.ents) do if e == npc then table.remove(q.ents, i) break end end
        local nst = LC.NPCs and LC.NPCs[npc]
        if nst then nst.unmanaged, nst.eventUntil, nst.leaveAt = nil, CurTime() + 5, CurTime() + 120 end
    end
    return st
end

local function NearestSeed(pos)
    local best, bd
    for _, z in ipairs(LC.TerritorySeeds and LC.TerritorySeeds("infest") or {}) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

-- The Combine door opens: what is behind it pours into the sewers.
function F.OpenDoor(q)
    local m = F.Map()
    if not m then return end
    Pull("lc_raven_door_open")
    F.door, F.doorShutAt = "open", CurTime() + F.DOOR_OPEN
    if LC.LedgerAdd then LC.LedgerAdd("resistance", F.RESIST, nil) end
    if LC.LedgerNews then LC.LedgerNews("The sewers were flushed from the sealed quarter.") end
    -- the city's own infestation takes hold there too, and spreads from there by its own rules
    local seed = NearestSeed(m.sewer)
    if seed and LC.GrowTerritory and LC.TerritoryCanGrow and LC.TerritoryCanGrow(seed) then
        local ok, err = LC.Try(LC.GrowTerritory, seed, m.sewer, F.PATCH_R, "flushed")
        if not ok and LC.Error then LC.Error("sewer flush", err) end
    end
    if q then Narrate(q, "The door is open. Out the way you came, or on through the sewers.") end
    if LC.Breach and LC.Breach.DoorOpened then
        local ok, err = LC.Try(LC.Breach.DoorOpened)
        if not ok and LC.Error then LC.Error("sewer flush", err) end
    end
end
function F.ShutDoor()
    if F.door ~= "open" then return end
    Pull("lc_raven_door_shut")
    F.door, F.doorShutAt = "shut", nil
end

------------------------------------------------------------------------
-- The job
------------------------------------------------------------------------

-- What stands at the wall: a live power bank (1) and turrets fed by one (up to F.TURRETS).
function F.SetUp(post)
    local r2 = F.POST_R * F.POST_R
    local bank = false
    for _, b in ipairs(LC.EntsOf and LC.EntsOf("lc_powerbank") or {}) do
        if IsValid(b) and b:GetPos():DistToSqr(post) < r2 and (not LC.PowerBankLive or LC.PowerBankLive(b)) then bank = true break end
    end
    local n = 0
    for _, t in ipairs(LC.CheckpointTurrets and LC.CheckpointTurrets() or {}) do
        if IsValid(t) and t:GetPos():DistToSqr(post) < r2 and (not LC.TurretSource or IsValid(LC.TurretSource(t))) then n = n + 1 end
    end
    return (bank and 1 or 0) + math.min(n, F.TURRETS), bank, n
end

local function OnJob(ply)
    local q = IsValid(ply) and LC.QuestOf and LC.QuestOf[ply]
    if q and not q.done and q.tmpl and q.tmpl.id == "cmb_flush" then return q end
    return nil
end

-- On this job, at the wall, any unit puts up the bank and the turrets (sv_livingcity_checkpoints.lua).
function LC.FlushKit(ply)
    local q = OnJob(ply)
    local st = q and Q.Stage(q)
    if not st or not st.kit then return false end
    local m = F.Map()
    return m ~= nil and ply:GetPos():DistToSqr(m.post) < F.POST_R * F.POST_R
end

local function KitOff()
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2Bool("lc_flush_kit", false) then p:SetNW2Bool("lc_flush_kit", false) end
    end
end

local function Drop(q, p)
    for i, x in ipairs(q.members) do if x == p then table.remove(q.members, i) break end end
    LC.QuestOf[p] = nil
    if q.owner == p then q.owner = Members(q)[1] end
    if LC.SendQuestState then LC.SendQuestState(p) end
end

-- The wall is open: who is in. It shuts when every living unit on the job is, or when its time is up.
function F.Enter(q, st, m)
    local now = CurTime()
    q.data.went = q.data.went or {}
    local went = q.data.went
    local alive, inN = 0, 0
    for _, p in ipairs(Members(q)) do
        if p:Alive() then
            alive = alive + 1
            local side = F.Side(p:GetPos(), m)
            if side ~= nil then went[p] = side or nil end
            if went[p] then inN = inN + 1 end
        else
            went[p] = nil
        end
    end
    local due = now >= (q.data.gateAt or now) + F.GATE_TAKES + F.GATE_OPEN
    if not due and not (alive > 0 and inN == alive) then return end
    F.ShutGate()
    if inN == 0 then return Q.Finish(q, false, "nobody went in") end
    for _, p in ipairs(Members(q)) do
        if p:Alive() and not went[p] then Drop(q, p) end
    end
    for p in pairs(went) do F.inside[p] = true end
    q.data.committed = true
    if q.posting then q.posting.dead = true end -- (nobody joins from outside now)
    Q.Advance(q)
end

-- The quarter's infected, waiting at the map's marks (out of sight of whoever is coming).
function F.Infest(q)
    q.data.zombies = q.data.zombies or {}
    if not LC.SpawnZombie then return 0 end
    local n = 0
    for _, e in ipairs(ents.FindByName and ents.FindByName("lc_raven_spawn") or {}) do
        if n >= F.ZOMBIES then break end
        local pos = e:GetPos()
        if not (LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 40))) then
            local npc, st = LC.SpawnZombie(pos, nil)
            if IsValid(npc) then
                if st then st.unmanaged = true end -- (the job's own, on top of the city's number)
                q.data.zombies[#q.data.zombies + 1] = npc
                n = n + 1
            end
        end
    end
    return n
end

-- A console at `at`: whoever on the job is at it rewires it. If they fall or walk off, the next one there does.
function F.Wire(q, at)
    if LC.JobGamesOn and not LC.JobGamesOn() or not LC.JobGameStart then
        -- (no job games on this server: reaching it is enough)
        for _, p in ipairs(Members(q)) do
            if p:Alive() and p:GetPos():DistToSqr(at) < F.CONSOLE_R * F.CONSOLE_R then return Q.Advance(q) end
        end
        return
    end
    local who = q.data.wirer
    if IsValid(who) and LC.JobGames and LC.JobGames[who] and LC.JobGames[who].q == q then return end
    q.data.wirer = nil
    local best, bd
    for _, p in ipairs(Members(q)) do
        if p:Alive() and not (LC.JobGames and LC.JobGames[p]) then
            local d = p:GetPos():DistToSqr(at)
            if d < F.CONSOLE_R * F.CONSOLE_R and (not bd or d < bd) then best, bd = p, d end
        end
    end
    if best and LC.JobGameStart(best, "wiring", q, { what = "the terminal", pos = at }) then q.data.wirer = best end
end

local function JobTick(q)
    F.q = q
    local st = Q.Stage(q)
    local kit = st ~= nil and st.kit == true
    for _, p in ipairs(Members(q)) do
        if p:GetNW2Bool("lc_flush_kit", false) ~= kit then p:SetNW2Bool("lc_flush_kit", kit) end
    end
    -- shut in, and nobody who went in is left alive (the dead wake outside the wall)
    if q.data.committed then
        local any = false
        for p in pairs(F.inside) do
            if IsValid(p) and p:Alive() then any = true else F.inside[p] = nil end
        end
        if not any then return Q.Finish(q, false, "the squad was lost") end
    end
end

-- What is left of the infected a job put there wanders off once nobody is looking.
function F.Leftovers(q)
    for _, npc in ipairs(q.data.zombies or {}) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if st then st.surgeExpires = CurTime() + 120 end
    end
end

local function Finished(q, success)
    KitOff()
    if F.gate == "open" and not F.letOut then F.ShutGate() end
    F.Leftovers(q)
    if not success and LC.LedgerAdd then LC.LedgerAdd("authority", F.AUTHORITY, nil) end
    if F.q == q then F.q = nil end
end

LC.QuestTemplates[#LC.QuestTemplates + 1] = {
    -- (never on the boards by itself: only her order puts it there, F.Start)
    id = "cmb_flush", factions = { cp = true, ota = true }, violent = true, squad = 8,
    available = function() return F.offering == true and F.Map() ~= nil end,
    build = function()
        local m = F.Map()
        if not m then return nil end
        local need = 1 + F.TURRETS
        local brief = F.Briefing("Get your briefing from the officer", "cop", function() return F.OwnGround("combine", m.post) or m.post end,
            "A power bank and two turrets at the wall. It opens for a minute. Once it shuts behind you, the only way on is the door under the tunnel house.")
        local prep = Count("flush_prep", need, "Put up a power bank and two turrets at the containment wall (Unit tools)")
        prep.pos, prep.kit = m.post, true
        prep.poll = function(q, st)
            local got = F.SetUp(m.post)
            if got >= need then st.got = got return Q.Advance(q) end
            if got ~= st.got then st.got = got Q.SendStateAll(q) end
        end
        prep.onDone = function(q)
            q.data.gateAt = CurTime()
            F.OpenGate(F.GATE_OPEN)
        end
        local enter = Count("flush_in", 1, "The wall is open: get inside before it shuts")
        enter.pos, enter.untallied = m.inside, true
        enter.poll = function(q, st) F.Enter(q, st, m) end
        local house = Goto(m.house, "Find the tunnel house", 220)
        house.onEnter = function(q) F.Infest(q) end
        local wire = Count("game_done", 1, "Rewire the console at the Combine door, down the tunnel")
        wire.pos, wire.untallied = m.console, true
        wire.poll = function(q) F.Wire(q, m.console) end
        wire.onDone = function(q) F.OpenDoor(q) end
        return {
            title = "Flush the sewers", reward = F.REWARD, limit = F.LIMIT,
            desc = "The Administrator's order. Set up at the containment wall, go in, and open the Combine door under the sealed quarter: "
                .. "what is in there floods the rebels' sewers. Once the wall shuts behind you, that door is the only way on.",
            stages = { brief, prep, enter, house, wire },
            tick = JobTick,
            onFinish = Finished,
        }
    end,
}

------------------------------------------------------------------------
-- The order
------------------------------------------------------------------------

local function Day()
    local s = LC.Ledger and LC.Ledger()
    return s and tonumber(s.day) or nil
end

-- Do the Resistance hold ground underground? (The owner, 20 November, of "only while the Resistance are strong":
-- narrower, "the Resistance holding ground underground".) Rebel ground, placed or grown, with a roof over it
-- and lower than the street at the wall.
function F.Underground()
    local m = F.Map()
    if not m then return false end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if z.pos and z.pos.z < m.post.z - F.DEEP and LC.TerritoryOpenSky and not LC.TerritoryOpenSky(z.pos) then return true end
    end
    return false
end

function F.Units()
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        local f = LC.QuestFaction and LC.QuestFaction(p)
        if f == "cp" or f == "ota" then n = n + 1 end
    end
    return n
end

function F.DoneToday()
    if not F.orderedAt then return false end
    local day = Day()
    if day and F.orderedDay then return day == F.orderedDay end
    return CurTime() - F.orderedAt < F.AGAIN
end

local function Waiting()
    local p = F.posted
    return p ~= nil and not p.dead and not p.q and CurTime() < (p.expiresPost or 0)
end
-- Is the Combine's job up or under way? (sv_livingcity_breach.lua: the wall is theirs for now)
function F.Active() return F.q ~= nil or Waiting() end

local function Busy()
    if LC.SpeechSession and LC.SpeechSession() then return "Not during the Administrator's address." end
    if GetGlobal2String("lc_event", "") ~= "" then return "Not while an event is on." end
    if LC.CollapseActive and LC.CollapseActive() then return "Not now." end
    if F.gate == "open" or (LC.Breach and LC.Breach.Active and LC.Breach.Active()) then return "Not while the wall is in play." end
    return nil
end

-- For her tablet, which greys the order with the reason: "" (no sealed quarter here), "on", "done", "weak",
-- "nounits", "busy" or "ready".
function F.State()
    if not F.Map() then return "" end
    if F.q or Waiting() then return "on" end
    if F.DoneToday() then return "done" end
    if not F.Underground() then return "weak" end
    if F.Units() == 0 then return "nounits" end
    if Busy() then return "busy" end
    return "ready"
end

-- Put the job up: one posting, on both Combine boards. Returns it, or nil and why not.
function F.Start()
    local m, missing = F.Map()
    if not m then return nil, "This map has no sealed quarter: missing " .. table.concat(missing or NAMES, ", ") .. "." end
    if F.q or Waiting() then return nil, "The units are already at it." end
    if not LC.PostDirective then return nil, "No job boards on this server." end
    F.offering = true
    local made = LC.PostDirective("cmb_flush", nil, true)
    F.offering = nil
    local one = made[1]
    if not one then return nil, "No units on duty." end
    for _, f in ipairs({ "cp", "ota" }) do
        LC.Postings[f] = LC.Postings[f] or {}
        local list = LC.Postings[f]
        for i = #list, 1, -1 do
            if list[i] ~= one and list[i].tmpl == one.tmpl and not list[i].q then table.remove(list, i) end
        end
        if not table.HasValue(list, one) then table.insert(list, 1, one) end
    end
    F.posted, F.orderedAt, F.orderedDay = one, CurTime(), Day()
    F.Tell({ cp = true, ota = true }, "Administrator's order", "Flush the sewers: on your board (F4), for every unit.")
    if LC.Log then LC.Log("info", "The Administrator ordered the sewers flushed") end
    return one
end

function LC.OrderFlush(ply)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false, "Only the City Administrator orders that." end
    local s = F.State()
    if s == "" then return false, "This city has no sealed quarter." end
    if s == "on" then return false, "The units are already at it." end
    if s == "done" then return false, "Not again today." end
    if s == "weak" then return false, "The Resistance hold nothing underground." end
    if s == "nounits" then return false, "No units on duty." end
    if s == "busy" then return false, Busy() end
    local one, err = F.Start()
    if not one then return false, err end
    return true
end

-- From her tablet (the menu's own call: no chat command). Her tablet has the order greyed with the reason
-- before she can pick it, so a refusal here is a stale menu: the reason goes back the menu's usual way.
LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.flush = function(ply)
    local ok, why = LC.OrderFlush(ply)
    return ok, why and ("[The office] " .. why) or nil
end

------------------------------------------------------------------------
-- Keeping time: the wall and the door shut themselves, and the wall lets the living back out
------------------------------------------------------------------------

function F.Tick(now)
    now = now or CurTime()
    if F.gate == "open" and F.gateShutAt and now >= F.gateShutAt then F.ShutGate() end
    if F.door == "open" and F.doorShutAt and now >= F.doorShutAt then F.ShutDoor() end
    if F.q and (F.q.done or not (LC.ActiveQuests and LC.ActiveQuests[F.q])) then F.q = nil end -- (a job the city dropped without ending it)
    local m = F.Map()
    if m and not F.q and next(F.inside) then
        for p in pairs(F.inside) do
            if not IsValid(p) or not p:Alive() then
                F.inside[p] = nil
            else
                local side = F.Side(p:GetPos(), m)
                if side == true and F.gate == "shut" and now >= (F.gateNext or 0) then
                    F.OpenGate(F.OUT_OPEN)
                    F.letOut = true
                elseif side == false and F.gate == "open" then
                    F.inside[p] = nil
                end
            end
        end
    end
    local s = F.State()
    if s ~= F.sent then
        F.sent = s
        SetGlobal2String("lc_flush", s)
    end
end

timer.Create("LivingCityFlush", 1, 0, function()
    local ok, err = LC.Try(F.Tick)
    if not ok and LC.Error then LC.Error("sewer flush", err) end
end)

hook.Add("PlayerDeath", "LivingCityFlush", function(ply) F.inside[ply] = nil end)
hook.Add("PlayerDisconnected", "LivingCityFlush", function(ply) F.inside[ply] = nil end)

-- (for the tests: as if nothing had been ordered)
function F.Reset()
    F.q, F.posted, F.orderedAt, F.orderedDay, F.offering, F.sent = nil, nil, nil, nil, nil, nil
    F.gate, F.gateShutAt, F.gateNext, F.letOut = "shut", nil, nil, nil
    F.door, F.doorShutAt = "shut", nil
    F.inside = {}
    F.MapForget()
end
