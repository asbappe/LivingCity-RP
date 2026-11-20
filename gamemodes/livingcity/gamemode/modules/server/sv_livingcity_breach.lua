--[[
    Living City: the Resistance and the sealed quarter

    The owner, 20 November. Of the Combine's door from the sealed quarter into the
    sewers (sv_livingcity_flush.lua), and whether the Resistance may shut it: "yes
    but it can only be shut from the infested quarter side in the tunnel, so it's
    very dangerous and they have to hack or rewire the combine console". And: "there
    should be a resistance quest set by the resistance leader to open the infested
    quarter's gate to wreak havoc on the city and weaken the combine. Which they can
    reach via our little bypass air vent in the sewer. They have to open the
    containment gate on the street from inside the infested quarter".

      Shut the sewer door   On the Resistance's Operations board (F4) from the moment
                            the Combine door opens, for as long as it is open, with one
                            notice. No briefing: there is no time. To the sewer end,
                            through the air vent that goes round the door (or through
                            the door itself, against what is coming out of it), and
                            rewire the Combine console on the quarter's side (the
                            wiring game, for whoever reaches it). The door shuts on
                            whatever is in it; the Resistance win back some strength.
                            If the door shuts by itself first, the job is over.
      Open the sealed       The leader's order (a Commander; a Lieutenant when no
      quarter               Commander is playing): F2 > Resistance > "Send the cell to
                            open the sealed quarter's wall". Once a city day; not while
                            the Combine's own job there is up or the wall is open. One
                            job on the Operations board, told to every member once:
                              1. the plan, from the cell's runner on rebel ground
                                 nearest the sewer end (nobody there: straight on);
                              2. into the tunnel by the sewer vent;
                              3. up the tunnel and out by the tunnel house (the
                                 quarter's infected are waiting);
                              4. across the quarter, rewire the wall's console on the
                                 inside (the wiring game).
                            The wall opens for five minutes: the map sends what is in
                            the quarter out into the city, the city's own infestation
                            takes hold in the street outside, the Combine lose strength
                            and the city morale. They leave by the open wall or the way
                            they came.
      The map               What sv_livingcity_flush.lua reads, and for the second job
                            lc_raven_gate_console (the console inside the wall). An
                            lc_ravenholm.vmf without it: that order is not offered.
      Testing               F4 > Admin testing tools > "Open the sewer door now" and
                            "Order the wall opened from inside now".
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
local F = LC.Flush
if not Q or not F then return end

local Goto, Count = Q.Goto, Q.Count

LC.Breach = LC.Breach or {}
local B = LC.Breach
B.HAVOC = 300          -- seconds the wall stays open once the Resistance open it
B.SEAL_REWARD = 50     -- XP for shutting the door
B.REWARD = 80          -- XP for opening the wall
B.LIMIT = 1800         -- the second job's time
B.AGAIN = 2400         -- seconds before the order can be given again where the ledger keeps no days
B.RESIST = 4           -- what the Resistance win back by shutting the door
B.COMBINE = -6         -- what the Combine lose as the wall opens
B.MORALE = -4          -- and the city's morale
B.PATCH_R = 400        -- the infested ground that takes hold outside the wall

local REBELS = { resistance = true }

------------------------------------------------------------------------
-- Shutting the Combine's door again, from the quarter's side
------------------------------------------------------------------------

LC.QuestTemplates[#LC.QuestTemplates + 1] = {
    -- (not a "violent" job: fighters could not follow through the vent)
    id = "res_sealdoor", brings = false, factions = REBELS, squad = 4,
    available = function() return F.door == "open" and F.Map() ~= nil end,
    over = function() if F.door ~= "open" then return false, "the door has shut" end end,
    build = function()
        local m = F.Map()
        if not m or F.door ~= "open" then return nil end
        local go = Goto(m.sewer, "Get to the sewer end: the vent in the wall goes round their door", 300)
        local wire = Count("game_done", 1, "Rewire their console on the far side, in the tunnel")
        wire.pos, wire.untallied = m.console, true
        wire.poll = function(q) F.Wire(q, m.console) end
        wire.onDone = function()
            F.ShutDoor()
            if LC.LedgerAdd then LC.LedgerAdd("resistance", B.RESIST, nil) end
        end
        return {
            title = "Shut the sewer door", reward = B.SEAL_REWARD, limit = math.max(120, math.ceil((F.doorShutAt or 0) - CurTime())),
            desc = "The Combine have opened the sealed quarter into our sewers. Their door only shuts from the far side: "
                .. "round it by the air vent, and rewire their console.",
            stages = { go, wire },
        }
    end,
}

-- The door has opened (sv_livingcity_flush.lua): the answer goes up at once, and the Resistance are told.
function B.DoorOpened()
    if not LC.PostDirective then return nil end
    local made = LC.PostDirective("res_sealdoor", nil, true)
    if #made == 0 then return nil end
    F.Tell(REBELS, "Resistance", "The sealed quarter is open into the sewers. Shut their door: on your board (F4).")
    return made[1]
end

------------------------------------------------------------------------
-- The leader's order: open the wall from inside
------------------------------------------------------------------------

local function NearestSeed(pos)
    local best, bd
    for _, z in ipairs(LC.TerritorySeeds and LC.TerritorySeeds("infest") or {}) do
        local d = z.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

-- The wall opens from the inside: what the quarter holds walks out into the city.
function B.Opened()
    local m = F.Map()
    if not m then return end
    F.OpenGate(B.HAVOC)
    if LC.LedgerAdd then
        LC.LedgerAdd("combine", B.COMBINE, nil)
        LC.LedgerAdd("morale", B.MORALE, nil)
    end
    if LC.LedgerNews then LC.LedgerNews("The sealed quarter's wall was opened from the inside.") end
    local seed = NearestSeed(m.post)
    if seed and LC.GrowTerritory and LC.TerritoryCanGrow and LC.TerritoryCanGrow(seed) then
        local ok, err = LC.Try(LC.GrowTerritory, seed, m.post, B.PATCH_R, "breached")
        if not ok and LC.Error then LC.Error("sealed quarter", err) end
    end
end

LC.QuestTemplates[#LC.QuestTemplates + 1] = {
    -- (never on the board by itself: only the leader's order puts it there, B.Start)
    id = "res_breach", brings = false, factions = REBELS, squad = 6,
    available = function()
        local m = F.Map()
        return B.offering == true and m ~= nil and m.gateConsole ~= nil
    end,
    build = function()
        local m = F.Map()
        if not m or not m.gateConsole then return nil end
        local brief = F.Briefing("Get the plan from the cell's runner", LC.Spawners and LC.Spawners.rebel and "rebel" or "citizen",
            function() return F.OwnGround("rebel", m.sewer) end,
            "In by the vent in the sewer wall, up the tunnel, across the quarter. The wall's console is on the inside.")
        local vent = Goto(m.console, "Into the tunnel by the sewer vent", 260)
        local house = Goto(m.house, "Up the tunnel and out by the tunnel house", 220)
        house.onEnter = function(q) F.Infest(q) end
        local wire = Count("game_done", 1, "Cross the quarter and rewire the wall's console")
        wire.pos, wire.untallied = m.gateConsole, true
        wire.poll = function(q) F.Wire(q, m.gateConsole) end
        wire.onDone = function() B.Opened() end
        return {
            title = "Open the sealed quarter", reward = B.REWARD, limit = B.LIMIT,
            desc = "The leader's order. In through the sewer vent, up through the infested quarter, and open its wall from the inside: "
                .. "let the city have what the Combine locked away.",
            stages = { brief, vent, house, wire },
            tick = function(q) B.q = q end,
            onFinish = function(q)
                F.Leftovers(q)
                if B.q == q then B.q = nil end
            end,
        }
    end,
}

local function Day()
    local s = LC.Ledger and LC.Ledger()
    return s and tonumber(s.day) or nil
end

local function Waiting()
    local p = B.posted
    return p ~= nil and not p.dead and not p.q and CurTime() < (p.expiresPost or 0)
end
-- Is the Resistance's job on the wall up or under way? (sv_livingcity_flush.lua: the wall is theirs for now)
function B.Active() return B.q ~= nil or Waiting() end

function B.DoneToday()
    if not B.orderedAt then return false end
    local day = Day()
    if day and B.orderedDay then return day == B.orderedDay end
    return CurTime() - B.orderedAt < B.AGAIN
end

-- For the leader's F2, which greys the order with the reason: "" (this map has no console inside the wall),
-- "on", "done", "busy" or "ready".
function B.State()
    local m = F.Map()
    if not m or not m.gateConsole then return "" end
    if B.Active() then return "on" end
    if B.DoneToday() then return "done" end
    if F.gate == "open" or F.Active() then return "busy" end
    return "ready"
end

-- Put the job up. Returns the posting, or nil and why not.
function B.Start()
    local m, missing = F.Map()
    if not m then return nil, "This map has no sealed quarter: missing " .. table.concat(missing or F.NAMES, ", ") .. "." end
    if not m.gateConsole then return nil, "This map's sealed quarter has no console inside its wall: missing lc_raven_gate_console." end
    if B.Active() then return nil, "The cell is already at it." end
    if not LC.PostDirective then return nil, "No job boards on this server." end
    B.offering = true
    local made = LC.PostDirective("res_breach", nil, true)
    B.offering = nil
    local one = made[1]
    if not one then return nil, "Nobody to send." end
    B.posted, B.orderedAt, B.orderedDay = one, CurTime(), Day()
    F.Tell(REBELS, "The leader's order", "Open the sealed quarter: on your board (F4).")
    if LC.Log then LC.Log("info", "The Resistance's leader ordered the sealed quarter opened") end
    return one
end

function LC.OrderBreach(ply)
    if not (LC.AdminPlotLeader and LC.AdminPlotLeader(ply)) then return false, "Only the Resistance's leader gives that order." end
    local s = B.State()
    if s == "" then return false, "This city has no sealed quarter." end
    if s == "on" then return false, "The cell is already at it." end
    if s == "done" then return false, "Not again today." end
    if s == "busy" then return false, "Not while the Combine are at the wall." end
    local one, err = B.Start()
    if not one then return false, err end
    return true
end

-- From the leader's F2 (the menu's own call: no chat command; a stale menu is told why not, the menu's usual way).
LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.breach = function(ply)
    local ok, why = LC.OrderBreach(ply)
    return ok, why and ("[Resistance] " .. why) or nil
end

function B.Tick()
    if B.q and (B.q.done or not (LC.ActiveQuests and LC.ActiveQuests[B.q])) then B.q = nil end
    local s = B.State()
    if s ~= B.sent then
        B.sent = s
        SetGlobal2String("lc_breach", s)
    end
    -- (who sees the order on their F2: whoever may give it)
    if s ~= "" and LC.AdminPlotLeader then
        for _, p in ipairs(player.GetAll()) do
            local leads = LC.AdminPlotLeader(p) == true
            if p:GetNW2Bool("lc_res_leads", false) ~= leads then p:SetNW2Bool("lc_res_leads", leads) end
        end
    end
end

timer.Create("LivingCityBreach", 1, 0, function()
    local ok, err = LC.Try(B.Tick)
    if not ok and LC.Error then LC.Error("sealed quarter", err) end
end)

-- (for the tests: as if nothing had been ordered)
function B.Reset()
    B.q, B.posted, B.orderedAt, B.orderedDay, B.offering, B.sent = nil, nil, nil, nil, nil, nil
end
