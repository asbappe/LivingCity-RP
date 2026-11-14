--[[
    Living City: manpower, what each side has left to send

    The owner, 7 November: "if these NPCs are attacking a CP activity and are all killed, there
    needs to be a real hit to the resistance that is actually visible and tangible, as in they
    aren't just magically replaced 15, or 120, seconds later ... there need to be actual manpower
    counters/trackers and a longer/realistic timer for respawning either rebels or CP units".

    Three pools, each the people that side has in reserve (lc_npc_budget still caps how many
    are out in the city at once):
      rebel   the Resistance's fighters
      cp      Civil Protection's street units
      ota     Overwatch soldiers (their own small pool: they come from outside the city, and an
              Overwatch drop brings a batch of them)

    Every fighter, unit or soldier the city brings out (rebel territory's own top-up,
    LC.ReinforceRebels, raid parties and the swaps for them, lookout posts, waves, quest allies;
    patrols, posts, sweep teams, responders, backup, cleanup guards, garrisons, convoys, drops)
    takes one from that side's reserve, in SpawnCop, SpawnSoldier and SpawnRebel themselves. An
    empty reserve: nobody comes until it refills. Killed: lost. Gone home, or taken away, alive:
    back in the reserve. Not counted (LC.ManpowerFree): the quartermaster, a quest's own
    characters, the Administrator's guard, the interrogator and the stalker technician; dreams,
    endings and stories make their own NPCs and never touch a pool.

    Refilling, slowly: the Resistance recruit from the city, faster for each of the Commissary's
    restrictions (lc_manpower_restrict_pct each), for citizens' sympathy and for every patch of
    rebel territory past the first, slower after heavy losses (6 or more in the last hour). Civil
    Protection get a steady trickle from the Combine; Overwatch a slower one, and a drop's soldiers
    on top. Each pool has a most it holds (lc_manpower_*_max).

    Seen: the Resistance's numbers on their F2 Resistance page and the C menu's Resistance menu;
    the Combine's on the unit tools (F2) and the Administrator's F2. After a big loss (three or
    more in a fight) that side's radio says so, and the other side hears it as good news. While a
    side's reserve is below lc_manpower_hold, its raids (or sweeps) wait, and its own hear why.
    Saved per map: data/livingcity/<map>_manpower.json.

      lc_manpower 0/1               on (1)
      lc_manpower_rebel_max <n>     most fighters the Resistance hold in reserve (20)
      lc_manpower_rebel_minutes <m> minutes per recruit at the ordinary rate (8)
      lc_manpower_cp_max <n>        most Civil Protection units in reserve (20)
      lc_manpower_cp_minutes <m>    minutes per new unit (5)
      lc_manpower_ota_max <n>       most Overwatch soldiers in reserve (12)
      lc_manpower_ota_minutes <m>   minutes per soldier, drops aside (20)
      lc_manpower_restrict_pct <p>  faster recruiting per Commissary restriction, percent (15)
      lc_manpower_hold <n>          raids and sweeps wait while that side has fewer in reserve (3)
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_manpower")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_manpower", "1", FLAGS, "Each side's NPCs come from a reserve that refills slowly: the dead aren't replaced at once (0: off)")
local cvRebMax  = CreateConVar("lc_manpower_rebel_max", "20", FLAGS, "Most Resistance fighters held in reserve")
local cvRebMin  = CreateConVar("lc_manpower_rebel_minutes", "8", FLAGS, "Minutes per new Resistance recruit at the ordinary rate")
local cvCpMax   = CreateConVar("lc_manpower_cp_max", "20", FLAGS, "Most Civil Protection units held in reserve")
local cvCpMin   = CreateConVar("lc_manpower_cp_minutes", "5", FLAGS, "Minutes per new Civil Protection unit from the Combine")
local cvOtaMax  = CreateConVar("lc_manpower_ota_max", "12", FLAGS, "Most Overwatch soldiers held in reserve")
local cvOtaMin  = CreateConVar("lc_manpower_ota_minutes", "20", FLAGS, "Minutes per new Overwatch soldier (an Overwatch drop brings a batch on top)")
local cvRestr   = CreateConVar("lc_manpower_restrict_pct", "15", FLAGS, "Faster Resistance recruiting for each of the Commissary's restrictions, in percent")
local cvHold    = CreateConVar("lc_manpower_hold", "3", FLAGS, "Raids (or sweeps) wait while that side has fewer than this in reserve")

local BIG_LOSS = 3         -- this many lost in one fight: the radio says so
local FIGHT_GAP = 20       -- seconds without another loss: that fight's over
local HEAVY = 6            -- lost in the last hour: recruiting slows
local HOLD_GAP = 600       -- seconds between "we can't spare anyone" lines

local SIDES = { "rebel", "cp", "ota" }
local MAXCV = { rebel = cvRebMax, cp = cvCpMax, ota = cvOtaMax }
local MINCV = { rebel = cvRebMin, cp = cvCpMin, ota = cvOtaMin }
local ROLE_SIDE = { rebel = "rebel", cop = "cp", soldier = "ota" }

LC.Manpower = LC.Manpower or {}
LC.ManpowerOut = LC.ManpowerOut or {} -- [npc] = side, for everyone out now who came from a pool
local freeDepth = 0
local dirty = false

local function Today() return os.date("%Y-%m-%d") end
-- The Combine grows with the Resistance's players (the owner, 9 November: "if there were 40 rebel players, they could wipe
-- out the CP units in a firefight or two ... we may need to ... adjust so that the CP/overwatch don't become too weak"):
-- for every Resistance player online past LC.ManpowerRebelsFree (4), Civil Protection's reserve holds 2 more, Overwatch's 1
-- more, and both refill 5% faster.
LC.ManpowerRebelsFree, LC.ManpowerPerRebel, LC.ManpowerFasterPerRebel = 4, { cp = 2, ota = 1 }, 0.05
function LC.ManpowerRebelPlayers()
    local n = 0
    for _, ply in ipairs(player.GetAll()) do if ply:GetNW2String("lcf_faction", "") == "resistance" then n = n + 1 end end
    return n
end
function LC.ManpowerExtraRebels() return math.max(0, LC.ManpowerRebelPlayers() - LC.ManpowerRebelsFree) end
local function Max(side)
    local base = math.max(0, MAXCV[side]:GetInt())
    local per = LC.ManpowerPerRebel[side]
    if per and base > 0 then base = base + per * LC.ManpowerExtraRebels() end
    return base
end
LC.ManpowerMax = Max

function LC.ManpowerPool(side)
    local p = LC.Manpower[side]
    if not p then
        p = { reserve = Max(side), progress = 0, lost = 0, day = Today(), recent = {}, fight = {} }
        LC.Manpower[side] = p
    end
    if p.day ~= Today() then p.day, p.lost = Today(), 0 end
    return p
end

function LC.ManpowerOn() return cvOn:GetBool() end
function LC.ManpowerSideOf(role) return ROLE_SIDE[role] end

-- Spawns inside fn take nobody from a pool (characters with rules of their own).
function LC.ManpowerFree(fn, ...)
    freeDepth = freeDepth + 1
    local res = { LC.Try(fn, ...) }
    freeDepth = freeDepth - 1
    if not res[1] then error(res[2], 0) end
    return unpack(res, 2)
end

-- May one more of this side come out now?
function LC.ManpowerCan(side)
    if not side or not cvOn:GetBool() or freeDepth > 0 then return true end
    return LC.ManpowerPool(side).reserve >= 1
end

-- One has come out: from the reserve, and watched until they're home or dead.
function LC.ManpowerTake(npc, st, side)
    if not side or not IsValid(npc) then return end
    if not cvOn:GetBool() or freeDepth > 0 then
        if st then st.manpowerFree = true end
        return
    end
    local p = LC.ManpowerPool(side)
    p.reserve = math.max(0, p.reserve - 1)
    LC.ManpowerOut[npc] = side
    dirty = true
end

-- Killed: a loss, for the day, the hour, and this fight.
function LC.ManpowerLost(npc, pos)
    local side = LC.ManpowerOut[npc]
    if not side then return false end
    LC.ManpowerOut[npc] = nil
    local p = LC.ManpowerPool(side)
    local now = CurTime()
    p.lost = p.lost + 1
    p.recent[#p.recent + 1] = now
    p.fight[#p.fight + 1] = { t = now, pos = pos or (IsValid(npc) and npc:GetPos()) or nil }
    dirty = true
    return true
end

-- Gone home, or taken away, alive: back in the reserve.
function LC.ManpowerReturn(npc)
    local side = LC.ManpowerOut[npc]
    if not side then return false end
    LC.ManpowerOut[npc] = nil
    local p = LC.ManpowerPool(side)
    p.reserve = math.min(math.max(p.reserve, Max(side)), p.reserve + 1)
    dirty = true
    return true
end

hook.Add("OnNPCKilled", "LivingCityManpower", function(npc)
    if LC.ManpowerOut[npc] then LC.ManpowerLost(npc, npc:GetPos()) end
end)
hook.Add("EntityRemoved", "LivingCityManpower", function(ent)
    if not LC.ManpowerOut[ent] then return end
    if ent.Health and ent:Health() > 0 then LC.ManpowerReturn(ent) else LC.ManpowerLost(ent, ent:GetPos()) end
end)

-- An Overwatch drop brings its soldiers with it: they're added, then they step off.
hook.Add("LivingCityOverwatchDrop", "LivingCityManpower", function(d)
    if not cvOn:GetBool() or not d then return end
    local p = LC.ManpowerPool("ota")
    p.reserve = p.reserve + math.max(0, tonumber(d.expected) or 0)
    dirty = true
end)

------------------------------------------------------------------------
-- Refilling
------------------------------------------------------------------------

local function LostInHour(p, now)
    local n, keep = 0, {}
    for _, t in ipairs(p.recent) do
        if now - t < 3600 then n = n + 1 keep[#keep + 1] = t end
    end
    p.recent = keep
    return n
end

-- How fast the Resistance recruit just now (1: the ordinary rate), and why (+ faster, - slower).
function LC.ManpowerRebelRate()
    local rate, why = 1, {}
    local restr = LC.MarketRestrictedCount and LC.MarketRestrictedCount() or 0
    if restr > 0 then
        rate = rate + restr * math.max(0, cvRestr:GetFloat()) / 100
        why[#why + 1] = "+Commissary restrictions"
    end
    -- citizens' sympathy (the city's players, on average)
    local sum, n = 0, 0
    for _, ply in ipairs(player.GetAll()) do
        local f = ply:GetNW2String("lcf_faction", "")
        if (f == "citizen" or f == "" or f == "resistance") and LC.Trait then sum, n = sum + (LC.Trait(ply, "sympathy") or 0), n + 1 end
    end
    local symp = n > 0 and math.Clamp(sum / n * 0.05, 0, 0.5) or 0
    if symp >= 0.1 then why[#why + 1] = "+sympathy" end
    rate = rate + symp
    local zones = LC.ZonesOfKind and #LC.ZonesOfKind("rebel") or 0
    if zones > 1 then rate = rate + math.min(0.5, (zones - 1) * 0.1) end
    if LostInHour(LC.ManpowerPool("rebel"), CurTime()) >= HEAVY then
        rate = rate * 0.6
        why[#why + 1] = "-heavy losses"
    end
    return math.Clamp(rate, 0.25, 3), why
end

-- Seconds each new one takes, for this side, now.
function LC.ManpowerInterval(side)
    local secs = math.max(0.1, MINCV[side]:GetFloat()) * 60
    if side == "rebel" then secs = secs / LC.ManpowerRebelRate()
    elseif LC.ManpowerPerRebel[side] then secs = secs / (1 + LC.ManpowerFasterPerRebel * LC.ManpowerExtraRebels()) end -- (more rebel players, faster reinforcements)
    return secs
end

-- dt seconds of recruiting, on every side.
function LC.ManpowerTick(dt)
    if not cvOn:GetBool() then return end
    for _, side in ipairs(SIDES) do
        local p = LC.ManpowerPool(side)
        if p.reserve >= Max(side) then
            p.progress = 0
        else
            p.progress = p.progress + dt
            local need = LC.ManpowerInterval(side)
            while p.progress >= need and p.reserve < Max(side) do
                p.progress = p.progress - need
                p.reserve = p.reserve + 1
                dirty = true
            end
            if p.reserve >= Max(side) then p.progress = 0 end
        end
    end
end

------------------------------------------------------------------------
-- Raids and sweeps wait while a side is depleted
------------------------------------------------------------------------

local function IsCombineSide(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "ota" or f == "admin" or (LC.PlayerIsCP and LC.PlayerIsCP(ply)) == true
end

local holdSaidAt = {}
local function TellSide(side, title, text)
    for _, ply in ipairs(player.GetAll()) do
        local mine = (side == "rebel" and ply:GetNW2String("lcf_faction", "") == "resistance") or (side ~= "rebel" and IsCombineSide(ply))
        if mine and LC.Notice then LC.Notice(ply, "event", title, text, 10) end
    end
end

-- Why that side's raid (rebel) or sweep (cp) can't go now, or nil. Its own are told, now and then.
function LC.ManpowerHold(side)
    if not cvOn:GetBool() then return nil end
    local p = LC.ManpowerPool(side)
    if p.reserve >= math.max(0, cvHold:GetInt()) then return nil end
    local why
    if side == "rebel" then
        why = string.format("only %d fighter%s left in reserve", p.reserve, p.reserve == 1 and "" or "s")
    else
        why = string.format("Civil Protection reserves at %d unit%s", p.reserve, p.reserve == 1 and "" or "s")
    end
    if CurTime() >= (holdSaidAt[side] or 0) then
        holdSaidAt[side] = CurTime() + HOLD_GAP
        if side == "rebel" then
            if LC.RadioNotice then LC.RadioNotice("resistance", "No raids for now: we're down to " .. p.reserve .. " in reserve. We wait for new recruits.") end
            TellSide("rebel", "Raids postponed", "We can't spare anyone for a raid: " .. why .. ". They wait until new recruits come in (F2 > Resistance).")
        else
            if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: sweeps postponed. " .. why .. ". Awaiting replacements.") end
            TellSide("cp", "Sweeps postponed", "No sweep teams for now: " .. why .. ". They wait for replacements (F2 > Unit tools).")
        end
    end
    return why
end

------------------------------------------------------------------------
-- After a big loss: that side's radio, and the other side's good news
------------------------------------------------------------------------

local WORDS = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve" }
local function Word(n) return WORDS[n] or tostring(n) end

-- What each side hears after side lost n where: theirs, then the other side's.
function LC.ManpowerLossLines(side, n, where, left)
    where = (where and where ~= "") and (" " .. where) or ""
    if side == "rebel" then
        return "We lost " .. Word(n) .. " fighters" .. where .. ". We're stretched thin: " .. left .. " left in reserve.",
            "Dispatch: " .. Word(n) .. " anticitizens neutralized" .. where .. ". Resistance strength reduced."
    elseif side == "cp" then
        return "Dispatch: " .. Word(n) .. " units lost" .. where .. ". Reserves stretched: " .. left .. " in reserve.",
            "The Combine lost " .. Word(n) .. " units" .. where .. ". They're stretched thin."
    end
    return "Dispatch: " .. Word(n) .. " Overwatch soldiers lost" .. where .. ". " .. left .. " in reserve.",
        "Overwatch lost " .. Word(n) .. " soldiers" .. where .. ". That hurts them."
end

function LC.ManpowerFightsOver(now)
    for _, side in ipairs(SIDES) do
        local p = LC.ManpowerPool(side)
        local f = p.fight
        if #f > 0 and now - f[#f].t >= FIGHT_GAP then
            if #f >= BIG_LOSS and LC.RadioNotice then
                local where = f[1].pos and LC.DescribePlace and LC.DescribePlace(f[1].pos) or ""
                local ours, theirs = LC.ManpowerLossLines(side, #f, where, p.reserve)
                LC.RadioNotice(side == "rebel" and "resistance" or "cp", ours)
                LC.RadioNotice(side == "rebel" and "cp" or "resistance", theirs)
                hook.Run("LivingCityManpowerLoss", side, #f, where)
            end
            p.fight = {}
        end
    end
end

------------------------------------------------------------------------
-- What each side sees
------------------------------------------------------------------------

local function Mins(secs)
    local m = math.ceil(secs / 60)
    if m <= 1 then return "in under a minute" end
    return "in about " .. m .. " minutes"
end

local function PoolLine(label, side)
    local p = LC.ManpowerPool(side)
    return string.format("%s: %d in reserve (of %d), %d lost today", label, p.reserve, Max(side), p.lost)
end
local function NextLine(side, noun)
    local p = LC.ManpowerPool(side)
    if p.reserve >= Max(side) then return "The reserve is full" end
    return "Next " .. noun .. " " .. Mins(LC.ManpowerInterval(side) - p.progress)
end

-- The lines a side's players see: "rebel" (the Resistance) or "combine" (units and the Administrator).
function LC.ManpowerReadout(which)
    if not cvOn:GetBool() then return {} end
    if which == "rebel" then
        local out = { PoolLine("Fighters", "rebel"), NextLine("rebel", "recruit") }
        local _, why = LC.ManpowerRebelRate()
        local fast, slow = {}, {}
        for _, w in ipairs(why) do
            if string.sub(w, 1, 1) == "+" then fast[#fast + 1] = string.sub(w, 2) else slow[#slow + 1] = string.sub(w, 2) end
        end
        local parts = {}
        if #fast > 0 then parts[#parts + 1] = "faster (" .. table.concat(fast, ", ") .. ")" end
        if #slow > 0 then parts[#parts + 1] = "slower (" .. table.concat(slow, ", ") .. ")" end
        if #parts > 0 then out[#out + 1] = "Recruiting " .. table.concat(parts, ", ") end
        if LC.ImbalanceSide == "rebels" and LC.ImbalanceLine then out[#out + 1] = LC.ImbalanceLine() end -- (sv_livingcity_imbalance.lua)
        return out
    end
    local out = { PoolLine("Civil Protection", "cp"), NextLine("cp", "unit"), PoolLine("Overwatch", "ota"), NextLine("ota", "soldier") }
    if LC.ImbalanceSide == "combine" and LC.ImbalanceLine then out[#out + 1] = LC.ImbalanceLine() end
    local desp = LC.DesperationLine and LC.DesperationLine() -- (sv_livingcity_desperation.lua)
    if desp then out[#out + 1] = desp end
    return out
end

function LC.ManpowerReadoutFor(ply)
    if ply:GetNW2String("lcf_faction", "") == "resistance" then return LC.ManpowerReadout("rebel") end
    if IsCombineSide(ply) then return LC.ManpowerReadout("combine") end
    return {}
end

function LC.ManpowerSend(ply)
    local list = IsValid(ply) and { ply } or player.GetAll()
    for _, p in ipairs(list) do
        net.Start("lc_manpower")
        net.WriteString(table.concat(LC.ManpowerReadoutFor(p), "\n"))
        net.Send(p)
    end
end

------------------------------------------------------------------------
-- Saved per map
------------------------------------------------------------------------

local function File() return "livingcity/" .. game.GetMap() .. "_manpower.json" end
LC.ManpowerFile = File

function LC.ManpowerSave()
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    local outNow, out = {}, {}
    for npc, side in pairs(LC.ManpowerOut) do
        if IsValid(npc) and npc:Health() > 0 then outNow[side] = (outNow[side] or 0) + 1 end
    end
    for _, side in ipairs(SIDES) do
        local p = LC.ManpowerPool(side)
        -- (whoever is out alive now comes home with the restart)
        out[side] = { reserve = math.min(math.max(p.reserve, Max(side)), p.reserve + (outNow[side] or 0)),
            progress = math.floor(p.progress), lost = p.lost, day = p.day }
    end
    LC.SafeWrite(File(), util.TableToJSON(out))
    dirty = false
end

function LC.ManpowerLoad()
    LC.Manpower = {}
    LC.ManpowerOut = {}
    local t = LC.SafeReadJSON(File())
    for _, side in ipairs(SIDES) do
        local p = LC.ManpowerPool(side)
        local s = type(t) == "table" and t[side]
        if type(s) == "table" then
            p.reserve = math.Clamp(math.floor(tonumber(s.reserve) or p.reserve), 0, Max(side))
            p.progress = math.max(0, tonumber(s.progress) or 0)
            if s.day == Today() then p.lost = math.max(0, math.floor(tonumber(s.lost) or 0)) end
        end
    end
end
LC.ManpowerLoad()

hook.Add("ShutDown", "LivingCityManpower", function() LC.ManpowerSave() end)
hook.Add("PlayerInitialSpawn", "LivingCityManpower", function(ply)
    timer.Simple(5, function() if IsValid(ply) then LC.ManpowerSend(ply) end end)
end)

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

local lastTick, nextSend, nextSave = nil, 0, 0
timer.Create("LivingCityManpower", 5, 0, function()
    local ok, err = LC.Try(function()
        local now = CurTime()
        local dt = lastTick and math.Clamp(now - lastTick, 0, 60) or 0
        lastTick = now
        -- someone dead the hooks missed
        for npc in pairs(LC.ManpowerOut) do
            if not IsValid(npc) then LC.ManpowerOut[npc] = nil
            elseif npc:Health() <= 0 then LC.ManpowerLost(npc, npc:GetPos()) end
        end
        if not LC.Running then return end
        LC.ManpowerTick(dt)
        LC.ManpowerFightsOver(now)
        if now >= nextSend then
            nextSend = now + 15
            LC.ManpowerSend()
        end
        if dirty and now >= nextSave then
            nextSave = now + 60
            LC.ManpowerSave()
        end
    end)
    if not ok and LC.Error then LC.Error("manpower", err) end
end)
