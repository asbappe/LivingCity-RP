--[[
    Living City: a unit's search as a short pat-down (the owner, 7 November).

    When a Civil Protection player searches someone (baton reload, !search,
    F1/F2, C > Unit tools), a small window opens for the unit: a body with
    four spots, Jacket, Waist, Legs and Boots. Whatever today's search would
    find on them (sv_livingcity_underground.lua: LC.SearchPockets and
    LC.SearchWeapons, worked out but not taken) is spread over the four spots
    at random. Clicking a spot checks it for a second; what was there is
    taken. "Done", closing the window or walking off ends it, and everything
    found goes through LC.SearchOutcome exactly as a search always has (the
    messages, standing, the crime, the reward, the evidence stock). A spot
    never checked keeps what's in it.

    The person searched (a player) sees the four spots, which one is being
    checked, and "Stand still". Once per search they may press R to slip
    one thing from an unchecked spot into one already checked: SLIP_CHANCE
    it works, otherwise the unit feels it and it's found there and then.
    Walking off is evading a search, as before.

    An NPC citizen: the same window, with the same odds of carrying something
    as before (LC.SearchNPCRoll), put in one spot.

    With lc_jobgames off, or if the unit's window never opens (it answers
    within the three seconds the search has always taken), the search is the
    old one. Nothing a spot holds is sent to the unit before it's checked.
]]

local SLIP_CHANCE = 0.6 -- (the person searched slipping something into a checked spot)
local CHECK_SECS = 1    -- (checking one spot)
local MIN_GAP = 0.8     -- (the least time between two checks the server accepts)
local REACH = 140       -- (further apart than this, the search is over)
local MOVED = 80        -- (the person searched moved this far from where they stood: evading)
local MOST_SECS = 30    -- (a search left open this long is done)
local SPOTS = { "Jacket", "Waist", "Legs", "Boots" }
LC.PatSearchSpots = SPOTS
LC.PatSearchSlipChance = SLIP_CHANCE

util.AddNetworkString("lc_pat_open")  -- (server to client: the window, or what's in it now)
util.AddNetworkString("lc_pat_check") -- (unit: check spot N; 0 means the window is open)
util.AddNetworkString("lc_pat_slip")  -- (the person searched: try to slip something)
util.AddNetworkString("lc_pat_close") -- (either way: it's over)
util.AddNetworkString("lc_pat_papers") -- (unit: done searching, their papers now)

LC.PatSearches = LC.PatSearches or {} -- [target] = the search
LC.PatSearchByCop = LC.PatSearchByCop or {} -- [unit] = target
local PAT, BYCOP = LC.PatSearches, LC.PatSearchByCop

local function Ok(e) return IsValid(e) end
local function Nick(e) return (Ok(e) and e.Nick and e:Nick()) or "them" end

local function ItemName(it)
    if it.gun then return LC.SearchDescribe({}, { it.gun }) end
    if it.npc then return it.npc end
    local def = LCS.Items[it.id]
    return ((def and def.name) or tostring(it.id)) .. ((it.n or 1) > 1 and (" x" .. it.n) or "")
end
LC.PatSearchItemName = ItemName

local function Send(ply, t)
    if not Ok(ply) or not ply:IsPlayer() then return end
    net.Start("lc_pat_open")
    net.WriteString(util.TableToJSON(t) or "{}")
    net.Send(ply)
end

-- What each side may see: the unit only what's been checked; the person searched, their own pockets.
local function Push(S)
    local now = CurTime()
    local u = { role = "unit", who = Nick(S.target), live = S.live, checking = S.checking, secs = CHECK_SECS, spots = {}, papers = S.papers }
    for i, sp in ipairs(S.spots) do
        u.spots[i] = { name = sp.name, state = sp.done and 2 or (S.checking == i and 1 or 0), text = sp.done and sp.result or nil }
    end
    if S.flash and now - S.flashAt < 3 then u.flash, u.flashId = S.flash, S.flashId end
    Send(S.cop, u)
    if S.live and not S.npc and Ok(S.target) then
        local anyDone = false
        for _, sp in ipairs(S.spots) do if sp.done then anyDone = true end end
        local t = { role = "target", who = Nick(S.cop), checking = S.checking, key = "R", spots = {},
            slip = S.slipUsed and "used" or (anyDone and "ready" or "wait") }
        for i, sp in ipairs(S.spots) do
            local mine = {}
            for _, it in ipairs(sp.items) do mine[#mine + 1] = ItemName(it) end
            t.spots[i] = { name = sp.name, state = sp.done and 2 or (S.checking == i and 1 or 0), mine = table.concat(mine, ", ") }
        end
        Send(S.target, t)
    end
end
LC.PatSearchPush = Push

local function Close(ply)
    if not Ok(ply) or not ply:IsPlayer() then return end
    net.Start("lc_pat_close")
    net.Send(ply)
end

-- What someone has in their hands, as the search window calls it (nil: nothing).
function LC.PatSearchCarried(target, st)
    local e = st and st.carry
    if not Ok(e) then return nil end
    local m = string.lower(e:GetModel() or "")
    if string.find(m, "suitcase", 1, true) then return "Suitcase" end
    if string.find(m, "clipboard", 1, true) then return nil end -- (nothing to hide in a clipboard)
    if string.find(m, "box", 1, true) or string.find(m, "crate", 1, true) or string.find(m, "cardboard", 1, true) then return "Parcel" end
    return "What they carry"
end

-- A unit starts a search: offer the window. Returns the search (nil: the old search, as it always was).
function LC.PatSearchOffer(cop, target)
    if not (LC.JobGamesOn and LC.JobGamesOn()) then return nil end
    if not Ok(cop) or not cop:IsPlayer() or not Ok(target) then return nil end
    if BYCOP[cop] and PAT[BYCOP[cop]] then LC.PatSearchEnd(PAT[BYCOP[cop]], "done") end
    if PAT[target] then LC.PatSearchEnd(PAT[target], "done") end
    local S = { cop = cop, target = target, npc = not target:IsPlayer(), offeredAt = CurTime(), live = false, spots = {},
        lastCheck = -1e9, found = {}, guns = {}, flashId = 0 }
    if S.npc then S.st = LC.NPCs and LC.NPCs[target] end
    for i, name in ipairs(SPOTS) do S.spots[i] = { name = name, items = {} } end
    -- What they carry is searched too (the owner, 11 November: "I searched someone holding a suitcase and
    -- another holding a box/parcel and I would like those to be searchable"): a fifth spot, named for it.
    local carried = LC.PatSearchCarried(target, S.st)
    if carried then S.spots[#S.spots + 1] = { name = carried, items = {}, carried = true } end
    S.papers = S.npc and S.st ~= nil and S.st.role == "citizen" or nil
    PAT[target], BYCOP[cop] = S, target
    Push(S)
    return S
end

-- The unit's window is open: hands on. What a search would find is worked out now and spread over the spots.
function LC.PatSearchGoLive(S)
    if not S or S.live or S.ended then return false end
    local target = S.target
    if not Ok(target) or not Ok(S.cop) then return false end
    S.live, S.liveAt, S.origin = true, CurTime(), target:GetPos()
    if S.npc then
        local what = S.st and LC.SearchNPCRoll(S.st)
        -- (what they carry is where half of it is: a case or a parcel is the obvious place)
        local where = math.random(#S.spots)
        if S.spots[#S.spots].carried and math.random() < 0.5 then where = #S.spots end
        if what then table.insert(S.spots[where].items, { npc = what }) end
    else
        target.lcSearchedAt = CurTime()
        target:SetNW2Float("lcu_stop_until", 0) -- (the panel says it instead)
        if LC.DisguisedAsCP(target) then LC.BlowDisguise(target, "Hands on, the uniform is obviously a costume.") end
        for _, f in ipairs(LC.SearchPockets(target, 0.1, true)) do
            table.insert(S.spots[math.random(#S.spots)].items, { id = f.id, n = f.n })
        end
        for _, cls in ipairs(LC.SearchWeapons(target, 0.1, true)) do
            table.insert(S.spots[math.random(#S.spots)].items, { gun = cls })
        end
    end
    Push(S)
    return true
end

-- Take one thing (if they still have it). Returns true when it was taken.
local function Take(S, it)
    local target = S.target
    if S.npc then
        if Ok(S.cop) and S.st then LC.SearchNPCFound(S.cop, target, S.st, it.npc) end
        S.npcFound = true
        return true
    end
    if it.gun then
        if not target:HasWeapon(it.gun) then return false end
        target:StripWeapon(it.gun)
        S.guns[#S.guns + 1] = it.gun
        return true
    end
    local n = math.min(it.n or 1, (LC.Inventory(target) or {})[it.id] or 0)
    if n <= 0 then return false end
    LC.TakeItem(target, it.id, n)
    for _, f in ipairs(S.found) do
        if f.id == it.id then f.n = f.n + n return true end
    end
    S.found[#S.found + 1] = { id = it.id, n = n }
    it.n = n
    return true
end

-- The unit checks a spot (it takes CHECK_SECS; the tick finishes it).
function LC.PatSearchCheck(cop, i)
    local S = BYCOP[cop] and PAT[BYCOP[cop]]
    if not S or S.cop ~= cop then return false, "not searching" end
    i = tonumber(i) or -1
    if i == 0 then return LC.PatSearchGoLive(S) end
    if not S.live then return false, "not open" end
    local sp = S.spots[i]
    if not sp or sp.done then return false, "no such spot" end
    if S.checking then return false, "busy" end
    local now = CurTime()
    if now - S.lastCheck < MIN_GAP then return false, "too fast" end
    if not Ok(S.target) or S.target:GetPos():DistToSqr(cop:GetPos()) > REACH * REACH then return false, "too far" end
    S.checking, S.checkAt, S.lastCheck = i, now, now
    Push(S)
    return true
end

local function Finish(S, i)
    local sp = S.spots[i]
    S.checking = nil
    sp.done = true
    local got = {}
    local keep = {}
    for _, it in ipairs(sp.items) do
        if it.slipped then keep[#keep + 1] = it -- (slipped in after it was checked: never felt)
        elseif Take(S, it) then got[#got + 1] = ItemName(it) end
    end
    sp.items = keep
    sp.result = #got > 0 and table.concat(got, ", ") or "Nothing."
    Push(S)
end

-- The person searched tries to slip one thing from an unchecked spot into a checked one. Once a search.
function LC.PatSearchSlip(target)
    local S = PAT[target]
    if not S or not S.live or S.npc or S.ended then return false end
    if S.slipUsed then return false end
    local done, from = {}, {}
    for i, sp in ipairs(S.spots) do
        if sp.done then done[#done + 1] = i
        elseif S.checking ~= i then
            for k, it in ipairs(sp.items) do from[#from + 1] = { i = i, k = k, it = it } end
        end
    end
    if #done == 0 then
        target:ChatPrint("[Search] Nothing's been checked yet: wait until a spot is done.")
        return false
    end
    if #from == 0 then
        target:ChatPrint("[Search] Nothing left to move.")
        return false
    end
    S.slipUsed = true
    local pick = from[math.random(#from)]
    table.remove(S.spots[pick.i].items, pick.k)
    local name = ItemName(pick.it)
    if math.random() < SLIP_CHANCE then
        local into = S.spots[done[math.random(#done)]]
        pick.it.slipped = true
        table.insert(into.items, pick.it)
        target:ChatPrint("[Search] You ease the " .. name .. " into your " .. string.lower(into.name) .. ". They didn't notice.")
    else
        local taken = Take(S, pick.it)
        S.flash, S.flashAt, S.flashId = "They tried to move something: " .. name, CurTime(), S.flashId + 1
        if Ok(S.cop) then S.cop:ChatPrint("[Search] " .. Nick(target) .. " tried to move something: " .. name .. (taken and ". Found." or ".")) end
        target:ChatPrint("[Search] They felt it. The " .. name .. " is found.")
    end
    Push(S)
    return true
end

-- Over: how = "done" (the unit's Done, or the window closed), "away" (the unit walked off), "evade"
-- (the person searched walked off), "gone" (someone died or left).
function LC.PatSearchEnd(S, how)
    if not S or S.ended then return end
    S.ended = true
    if PAT[S.target] == S then PAT[S.target] = nil end
    if BYCOP[S.cop] == S.target then BYCOP[S.cop] = nil end
    Close(S.cop)
    if not S.live then return end -- (dropped: the old search has the person from here)
    local target = S.target
    if not S.npc then
        Close(target)
        if Ok(target) then target.lcBeingSearched = nil target:SetNW2Float("lcu_stop_until", 0) end
    end
    if S.npc then
        if S.st then S.st.beingSearched = nil end
        if not S.npcFound and Ok(S.cop) and S.st then LC.SearchNPCClean(S.cop, S.st) end
        return
    end
    if not Ok(target) then return end
    if how == "evade" and Ok(S.cop) then S.cop:ChatPrint("[Search] " .. Nick(target) .. " walked away.") end
    LC.SearchOutcome(S.cop, target, S.found, S.guns)
    if how == "evade" then LC.ReportCrime(target, "Evading a search", 180) end
end

-- The window never opened in time (the old search runs instead), or the unit closed it before it did.
function LC.PatSearchDrop(S)
    if not S or S.live or S.ended then return end
    LC.PatSearchEnd(S, "dropped")
end

function LC.PatSearchOf(ent) return PAT[ent] end

local function Tick()
    local now = CurTime()
    for target, S in pairs(PAT) do
        local cop = S.cop
        if not S.live then
            if now - S.offeredAt > 5 then LC.PatSearchDrop(S) end
        elseif not Ok(cop) or not cop:Alive() or not Ok(target) or (not S.npc and not target:Alive())
            or (S.npc and not (LC.NPCs and LC.NPCs[target])) then
            LC.PatSearchEnd(S, "gone")
        elseif target:GetPos():DistToSqr(cop:GetPos()) > REACH * REACH then
            local moved = not S.npc and S.origin and target:GetPos():DistToSqr(S.origin) > MOVED * MOVED
            LC.PatSearchEnd(S, moved and "evade" or "away")
        else
            if S.checking and now >= S.checkAt + CHECK_SECS then Finish(S, S.checking) end
            if not S.ended and now - S.liveAt > MOST_SECS then LC.PatSearchEnd(S, "done") end
            if S.npc and S.st and not S.ended then S.st.untilT = math.max(S.st.untilT or 0, now + 3) end
        end
    end
end
LC.PatSearchTick = Tick
timer.Create("LivingCityPatSearch", 0.2, 0, Tick)

net.Receive("lc_pat_check", function(_, ply)
    local i = net.ReadUInt(3)
    local target = BYCOP[ply]
    if not target or not PAT[target] then
        if i == 0 then Close(ply) end -- (too late: the old search already ran)
        return
    end
    LC.PatSearchCheck(ply, i)
end)
net.Receive("lc_pat_slip", function(_, ply) LC.PatSearchSlip(ply) end)
net.Receive("lc_pat_close", function(_, ply)
    local S = BYCOP[ply] and PAT[BYCOP[ply]]
    if not S then return end
    if S.live then LC.PatSearchEnd(S, "done") else LC.PatSearchDrop(S) end
end)

-- "Check papers" in the unit's window: the search is done as it stands, and their papers come up
-- (LC.StreetPapers, sv_livingcity_jobgames.lua).
function LC.PatSearchPapers(cop)
    local S = BYCOP[cop] and PAT[BYCOP[cop]]
    local npc = S and S.npc and S.target
    if S then LC.PatSearchEnd(S, "done") end
    if not Ok(npc) or not LC.StreetPapers then return false end
    local st = LC.NPCs and LC.NPCs[npc]
    if st then st.questLock = nil end
    local ok, why = LC.StreetPapers(cop, npc)
    if not ok and why then cop:ChatPrint("[CP net] " .. why) end
    return ok
end
net.Receive("lc_pat_papers", function(_, ply) LC.PatSearchPapers(ply) end)

hook.Add("PlayerDisconnected", "LivingCityPatSearch", function(ply)
    local S = PAT[ply] or (BYCOP[ply] and PAT[BYCOP[ply]])
    if S then LC.PatSearchEnd(S, "gone") end
end)
