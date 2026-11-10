--[[
    Living City: the state of the city, phase two (the owner, 10 November:
    "I like all of this, yes please"). What the districts and the numbers
    do on the streets, and the acts. Needs sv_livingcity_ledger.lua.

      - A district under a crackdown has a Civil Protection checkpoint: a unit
        posted in the middle of it, stopping and searching whoever passes, for
        as long as the crackdown lasts.
      - A district in the Resistance's hands is dangerous for patrols: a
        Combine unit walking through it may be ambushed (now and then, two
        fighters from out of sight, who melt away afterwards).
      - The Resistance's districts are where the black market is cheapest: a
        quarter off for anyone buying there (never under what he pays back).
      - Supply sets the Commissary's prices: low stores, dearer (up to 40% more
        at nothing left); full stores, cheaper (up to 15% off).
      - Acts: every lc_ledger_act_days (14) real days the act ends. The side
        holding more districts (and stronger) wins it: the bulletin says so,
        and every player of that side online earns 50 experience. Then a soft
        reset: the five numbers back to 50 and every district contested.
        Characters, records and legacy are untouched. 0 turns acts off.

      lc_ledger_act_days (14)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAct = CreateConVar("lc_ledger_act_days", "14", FLAGS, "Real days in an act of the state of the city; at its end the side ahead wins it and the city starts over (0: no acts)")

local AMBUSH_GAP = 120     -- each Resistance district may spring an ambush this often
local AMBUSH_CHANCE = 0.25
local CHECKPOINT_TRIES = 30

local function On()
    local a, b = GetConVar("lc_ledger"), GetConVar("lc_ledger_effects")
    return a and a:GetBool() and b and b:GetBool() and LC.Ledger ~= nil
end
local function Up(npc) return IsValid(npc) and npc:Health() > 0 and LC.NPCs and LC.NPCs[npc] ~= nil end
local function Ground(v) return LC.GroundAt and LC.GroundAt(v) or v end
local function BName(n) return LC.BlockName and LC.BlockName(n) or ("Block " .. tostring(n)) end

------------------------------------------------------------------------
-- Prices
------------------------------------------------------------------------

-- The Commissary (sv_livingcity_economy.lua asks): 1.4 at no supply, 1 at 50, 0.85 at 100.
function LC.LedgerPriceMul()
    if not On() then return 1 end
    local s = LC.Ledger().supply or 50
    if s < 50 then return 1 + (50 - s) / 50 * 0.4 end
    return 1 - (s - 50) / 50 * 0.15
end

local wrapped = false
local function Wrap()
    if wrapped or not LC.MarketPrice then return end
    wrapped = true
    local orig = LC.MarketPrice
    LC.MarketPrice = function(ply, g, ...)
        local p = orig(ply, g, ...)
        if On() and IsValid(ply) and LC.LedgerBlockAt and LC.DistrictOwner then
            local n = LC.InBlock and LC.LedgerBlockAt(ply:GetPos())
            if n and LC.InBlock(ply:GetPos(), n) and LC.DistrictOwner(n) == "resistance" then
                local floor = (g and g.item and LCS and LCS.Items[g.item] and LCS.Items[g.item].sell or 0) + 1
                p = math.max(floor, math.floor(p * 0.75 + 0.5))
            end
        end
        return p
    end
end
Wrap()
hook.Add("Initialize", "LivingCityLedger2", Wrap)

------------------------------------------------------------------------
-- Crackdown checkpoints
------------------------------------------------------------------------

LC.LedgerPosts = LC.LedgerPosts or {} -- [block] = npc

local function FreeUnit(st)
    return st.role == "cop" and not st.test and not st.questLock and not st.marching and not st.holdPos and not st.guardZone
        and not st.unmanaged and not st.tutorPost and not st.tutorBusy and not st.workDetail and not st.raid
        and (st.state == "idle" or st.state == "moving")
end

local function Checkpoints()
    local want = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if select(2, LC.DistrictOwner(n)) == "crackdown" then want[n] = true end
    end
    -- stand down where the crackdown's over
    for n, npc in pairs(LC.LedgerPosts) do
        if not want[n] or not Up(npc) then
            if Up(npc) then local st = LC.NPCs[npc] st.holdPos, st.ledgerPost = nil, nil end
            LC.LedgerPosts[n] = nil
        end
    end
    for n in pairs(want) do
        if not LC.LedgerPosts[n] then
            local c = LC.BlockCenter and LC.BlockCenter(n)
            if c then
                local spot = Ground(c + Vector(0, 0, 16))
                local best, bd
                for npc, st in pairs(LC.NPCs or {}) do
                    if Up(npc) and FreeUnit(st) then
                        local d = npc:GetPos():DistToSqr(spot)
                        if not bd or d < bd then best, bd = npc, d end
                    end
                end
                if best then
                    local st = LC.NPCs[best]
                    st.holdPos, st.ledgerPost = spot, n
                    if LC.GoTo then LC.GoTo(best, st, spot, false) end
                    LC.LedgerPosts[n] = best
                end
            end
        end
    end
end
LC.LedgerCheckpoints = Checkpoints

------------------------------------------------------------------------
-- Ambushes in the Resistance's districts
------------------------------------------------------------------------

local lastAmbush = {}

function LC.LedgerAmbush(unit, n)
    if not Up(unit) or not LC.Spawners or not LC.Spawners.rebel then return false end
    local spots = (LC.QB and LC.QB.HideSpots and LC.QB.HideSpots(unit:GetPos(), 2, 700, true)) or {}
    if #spots == 0 then spots = { unit:GetPos() + Vector(400, 0, 0), unit:GetPos() + Vector(-400, 0, 0) } end
    local made = 0
    for i = 1, 2 do
        local p = spots[i] or spots[1]
        local npc, st = LC.Spawners.rebel(LC.FreeSpawnPos and LC.FreeSpawnPos(p) or p)
        if IsValid(npc) and st then
            made = made + 1
            st.ambush = true
            st.leaveAt = CurTime() + 150 -- (they melt away afterwards)
            if npc.AddEntityRelationship then npc:AddEntityRelationship(unit, D_HT, 99) end
            if npc.SetEnemy then npc:SetEnemy(unit) end
            local ust = LC.NPCs[unit]
            if unit.AddEntityRelationship then unit:AddEntityRelationship(npc, D_HT, 99) end
            if ust and LC.SetState then ust.enemy = npc LC.SetState(unit, ust, "hostile") end
        end
    end
    if made > 0 then
        for _, p in ipairs(player.GetAll()) do
            if LC.PlayerIsCP(p) then p:ChatPrint("[CP net] Unit ambushed in " .. BName(n) .. ". Resistance-held ground: expect contact.") end
        end
        hook.Run("LivingCityAmbush", unit, n, made)
    end
    return made > 0
end

local function Ambushes(now)
    local held = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if LC.DistrictOwner(n) == "resistance" and now - (lastAmbush[n] or -1e9) >= AMBUSH_GAP then held[#held + 1] = n end
    end
    if #held == 0 then return end
    for _, n in ipairs(held) do
        for npc, st in pairs(LC.NPCs or {}) do
            if Up(npc) and (st.role == "cop" or st.role == "soldier") and not st.ledgerPost and st.state ~= "hostile" and LC.InBlock and LC.InBlock(npc:GetPos(), n) then
                lastAmbush[n] = now
                if math.random() < AMBUSH_CHANCE then LC.LedgerAmbush(npc, n) end
                break
            end
        end
    end
end

------------------------------------------------------------------------
-- Acts
------------------------------------------------------------------------

function LC.LedgerEndAct()
    if not LC.Ledger then return nil end
    local s = LC.Ledger()
    local res, com = 0, 0
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local o = LC.DistrictOwner(n)
        if o == "resistance" then res = res + 1 elseif o == "combine" then com = com + 1 end
    end
    local score = (res - com) * 10 + ((s.resistance or 50) - (s.combine or 50))
    local winner = score > 0 and "resistance" or (score < 0 and "combine" or nil)
    local act = (s.act or 1)
    local line = string.format("The end of act %d. %s", act, winner == "resistance" and "The Resistance holds the city's streets."
        or (winner == "combine" and "The Combine's order holds." or "Neither side has the city."))
    for _, p in ipairs(player.GetAll()) do
        local f = p:GetNW2String("lcf_faction", "")
        local side = (f == "resistance" and "resistance") or ((f == "cp" or f == "admin") and "combine") or nil
        if winner and side == winner and LC.AddXP then LC.AddXP(p, 50, "your side won the act") end
        p:ChatPrint("[City Bulletin] " .. line .. string.format(" Act %d begins.", act + 1))
    end
    -- the soft reset: the numbers and the districts start over; people, records and legacy stay
    for _, k in ipairs({ "supply", "morale", "combine", "resistance", "authority" }) do s[k] = 50 end
    s.districts, s.crackdown, s.liberated, s.pendingRaid = {}, {}, {}, nil
    s.act, s.actStart = act + 1, os.time()
    s.news = { line }
    if LC.LedgerSave then LC.LedgerSave() end
    hook.Run("LivingCityActEnded", act, winner)
    return winner
end

local function Acts()
    local days = cvAct:GetFloat()
    if days <= 0 then return end
    local s = LC.Ledger()
    if not s.actStart then s.actStart, s.act = os.time(), s.act or 1 return end
    if os.time() - s.actStart >= days * 86400 then LC.LedgerEndAct() end
end

------------------------------------------------------------------------

local nextCheck = 0
timer.Create("LivingCityLedger2", 10, 0, function()
    local ok, err = pcall(function()
        if not On() then
            for n, npc in pairs(LC.LedgerPosts) do if Up(npc) then local st = LC.NPCs[npc] st.holdPos, st.ledgerPost = nil, nil end end
            LC.LedgerPosts = {}
            return
        end
        local now = CurTime()
        Checkpoints()
        Ambushes(now)
        if now >= nextCheck then nextCheck = now + 60 Acts() end
    end)
    if not ok and LC.Error then LC.Error("ledger2", err) end
end)
