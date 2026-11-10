--[[
    Living City: the state of the city, kept from day to day (the owner,
    10 November: "I like all of this, yes please"). Phase one.

    Five numbers, 0 to 100, saved with the map (data/livingcity/<map>_city.json)
    and rolling on from one city day (lc_day_minutes) to the next:
      supply      the city's stores: supply drops add to it, looting and the
                  Administrator's extra rations take from it, every day eats some
      morale      the people's mood: calm days lift it, unrest wears it down,
                  speeches and amnesties lift it, crackdowns crush it
      combine     Civil Protection's strength: arrests of rebels and raids that
                  find things build it, rebel operations wear it down. Above 50,
                  more units walk the streets; below, fewer (lc_ledger_effects)
      resistance  the Resistance's strength: operations that work build it,
                  arrests and raids wear it down, low morale feeds it. Above 50,
                  more fighters in the camps; below, fewer
      authority   the Administrator's hold: amnesties spend it, crackdowns and
                  speeches build it. It decides how many citizens inform
    Every number drifts a little back toward the middle each day, and the city
    goes on drifting while the server is empty (the days it missed, up to a week).

    Districts. Each housing block is a district with an owner: Combine,
    contested or Resistance. Rebel operations that work push the district they
    hit toward the Resistance; block raids push it back. A crackdown marks a
    district for two days; a district liberated by the collapse is the
    Resistance's for three days, and then the Combine counterattacks (a block
    raid).

    The collapse leaves a mark. The Administrator killed: the district nearest
    rebel ground is liberated, the Resistance and morale rise, authority falls.
    The uprising crushed: a crackdown week on every district, authority up,
    the Resistance and morale down. She steps down or ends it: authority starts
    over at 50.

    The news comes the city's own way: each city morning a City Bulletin on
    the city screens and the PA's chat line (no windows), what changed and why;
    and anyone can read the state of the city on F2 > Me > The state of the city.

    The Administrator's tools (F2 > Me > The city's levers), each with its cost:
      - a speech: at a speech stand (editor: "Point: speech stand"; she's taken
        there), words to the city on the screens. Morale +6, authority +3; the
        citizens near the stand +2 standing. Once a city day.
      - an amnesty: every wanted citizen forgiven. Morale +6, authority -8,
        the Resistance +3. Once a city day.
      - a crackdown on a district: a block raid there now and the district
        marked for two days. Authority +5, morale -6, the Resistance +4.
      - extra rations: a ration day now. Supply -15, morale +8 (not below 20 supply).

      lc_ledger 0/1, lc_ledger_effects 0/1
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_ledger", "1", FLAGS, "The state of the city: supply, morale, the Combine's and the Resistance's strength and the Administrator's authority, kept from day to day, and districts with an owner")
local cvEffects = CreateConVar("lc_ledger_effects", "1", FLAGS, "The state of the city changes the streets: more or fewer units and fighters, more or fewer informants")

local NUMS = { "supply", "morale", "combine", "resistance", "authority" }
local NAMES = { supply = "Supply", morale = "Morale", combine = "Civil Protection's strength", resistance = "The Resistance's strength", authority = "The Administrator's authority" }
local CRACKDOWN_DAYS, LIBERATED_DAYS = 2, 3

local L -- the state

local function File() return "livingcity/" .. game.GetMap() .. "_city.json" end
local function Fresh()
    return { supply = 50, morale = 50, combine = 50, resistance = 50, authority = 50, districts = {}, crackdown = {}, liberated = {},
        day = 0, lastSave = os.time(), news = {}, speechDay = -1, amnestyDay = -1 }
end

local function Load()
    if L then return L end
    local t = LC.SafeReadJSON and LC.SafeReadJSON(File())
    L = istable(t) and t or Fresh()
    for k, v in pairs(Fresh()) do if L[k] == nil then L[k] = v end end
    return L
end
LC.Ledger = Load

function LC.LedgerReload() L = nil return Load() end -- (read back from the file)

local dirty = false
local function Save()
    if not file or not file.Write or not L then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    L.lastSave = os.time()
    if LC.SafeWrite then LC.SafeWrite(File(), util.TableToJSON(L)) end
    dirty = false
end
LC.LedgerSave = Save

local function DayLen() local c = GetConVar("lc_day_minutes") return math.max(1, c and c:GetFloat() or 60) * 60 end

-- Move a number (clamped 0 to 100), with a line for the bulletin.
function LC.LedgerAdd(what, d, why)
    if not cvOn:GetBool() then return end
    local s = Load()
    if s[what] == nil then return end
    s[what] = math.Clamp((s[what] or 50) + d, 0, 100)
    if why then
        s.news[#s.news + 1] = why
        while #s.news > 12 do table.remove(s.news, 1) end
    end
    dirty = true
    hook.Run("LivingCityLedger", what, d, why)
end
local Add = LC.LedgerAdd

local function News(line)
    local s = Load()
    s.news[#s.news + 1] = line
    while #s.news > 12 do table.remove(s.news, 1) end
    dirty = true
end

------------------------------------------------------------------------
-- Districts
------------------------------------------------------------------------

local function BlockAt(pos)
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if LC.InBlock and LC.InBlock(pos, n) then return n end
    end
    -- not in a block: the nearest one's
    local best, bd
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local c = LC.BlockCenter and LC.BlockCenter(n)
        if c then
            local d = c:DistToSqr(pos)
            if not bd or d < bd then best, bd = n, d end
        end
    end
    return best
end
LC.LedgerBlockAt = BlockAt

local function BName(n) return LC.BlockName and LC.BlockName(n) or ("Block " .. tostring(n)) end

function LC.DistrictControl(n) return (Load().districts[tostring(n)] or 0) end

-- "combine", "contested", "resistance" (and whether it's liberated or under a crackdown).
function LC.DistrictOwner(n)
    local s = Load()
    local k = tostring(n)
    if (s.liberated[k] or 0) > s.day then return "resistance", "liberated" end
    if (s.crackdown[k] or 0) > s.day then return "combine", "crackdown" end
    local c = s.districts[k] or 0
    if c >= 30 then return "resistance" elseif c <= -30 then return "combine" end
    return "contested"
end

function LC.DistrictPush(n, d, why)
    if not n or not cvOn:GetBool() then return end
    local s = Load()
    local k = tostring(n)
    local before = LC.DistrictOwner(n)
    s.districts[k] = math.Clamp((s.districts[k] or 0) + d, -100, 100)
    dirty = true
    local after = LC.DistrictOwner(n)
    if after ~= before then News(string.format("%s is %s now.", BName(n), after == "contested" and "contested" or ("in " .. (after == "resistance" and "the Resistance's" or "the Combine's") .. " hands"))) end
    if why then News(why) end
end

------------------------------------------------------------------------
-- What moves it
------------------------------------------------------------------------

hook.Add("LivingCityRebelOpDone", "LivingCityLedger", function(purpose, sk)
    local where = sk and sk.target and BlockAt(sk.target)
    Add("resistance", 4, nil) Add("combine", -2, nil) Add("authority", -2, nil)
    LC.DistrictPush(where, 15, string.format("The Resistance struck %s.", where and ("in " .. BName(where)) or "the city"))
end)
hook.Add("LivingCityBlockRaided", "LivingCityLedger", function(block, found)
    local n = 0
    for _, c in pairs(found or {}) do n = n + (tonumber(c) or 0) end
    LC.DistrictPush(block, -10, string.format("Civil Protection raided %s%s.", BName(block), n > 0 and (": " .. n .. " things confiscated") or ""))
    if n > 0 then Add("resistance", -2, nil) Add("authority", 1, nil) end
    Add("combine", 1, nil)
end)
hook.Add("LivingCityIncarcerated", "LivingCityLedger", function(ply, secs, reason, arrester)
    if IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "resistance" then
        Add("resistance", -1, nil) Add("combine", 1, nil)
    end
end)
hook.Add("LivingCitySupplyEnded", "LivingCityLedger", function() Add("supply", 8, "A supply drop came in.") end)
hook.Add("LivingCitySupplyLooted", "LivingCityLedger", function() Add("supply", -2, nil) Add("resistance", 1, "Looters got into the supply drop.") end)
hook.Add("OnNPCKilled", "LivingCityLedger", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if st and (st.role == "cop" or st.role == "soldier") and IsValid(attacker) and attacker:IsPlayer() and not LC.PlayerIsCP(attacker) then
        Add("combine", -1, nil)
    end
end)

hook.Add("LivingCityCollapseOver", "LivingCityLedger", function(how)
    local s = Load()
    if how == "killed" then
        -- the district nearest rebel ground is theirs for a while
        local best, bd
        for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
            local n = BlockAt(z.pos)
            if n then
                local d = (LC.BlockCenter and LC.BlockCenter(n) or z.pos):DistToSqr(z.pos)
                if not bd or d < bd then best, bd = n, d end
            end
        end
        if best then
            s.liberated[tostring(best)] = s.day + LIBERATED_DAYS
            s.districts[tostring(best)] = 100
        end
        Add("resistance", 15, nil) Add("morale", 10, nil) Add("authority", -25, nil) Add("combine", -10, nil)
        News("The Administrator has fallen." .. (best and (" " .. BName(best) .. " is liberated.") or ""))
    elseif how == "crushed" then
        for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do s.crackdown[tostring(n)] = s.day + 7 end
        Add("authority", 15, nil) Add("resistance", -15, nil) Add("morale", -10, nil) Add("combine", 10, nil)
        News("The uprising is crushed. A week of crackdowns in every district.")
    elseif how == "resign" or how == "end" then
        s.authority = 50
        Add("morale", 5, "A new Administrator will take the office.")
    end
    dirty = true
end)

------------------------------------------------------------------------
-- The days
------------------------------------------------------------------------

local function Drift(s)
    for _, k in ipairs(NUMS) do
        local v = s[k] or 50
        if v > 50 then s[k] = math.max(50, v - 2) elseif v < 50 then s[k] = math.min(50, v + 2) end
    end
    s.supply = math.Clamp(s.supply - 4, 0, 100)                    -- (the city eats)
    if s.morale < 30 then s.resistance = math.min(100, s.resistance + 2) end -- (despair feeds the Resistance)
    if s.supply < 20 then s.morale = math.max(0, s.morale - 3) end
    for k, c in pairs(s.districts) do
        if (s.liberated[k] or 0) <= s.day and (s.crackdown[k] or 0) <= s.day then
            if c > 0 then s.districts[k] = math.max(0, c - 5) elseif c < 0 then s.districts[k] = math.min(0, c + 5) end
        end
    end
end

-- Words for a number.
local function Word(v)
    if v >= 80 then return "very high" elseif v >= 60 then return "high" elseif v > 40 then return "steady"
    elseif v > 20 then return "low" end
    return "very low"
end
LC.LedgerWord = Word

function LC.LedgerLines()
    local s = Load()
    local lines = {}
    for _, k in ipairs(NUMS) do lines[#lines + 1] = string.format("%s: %s (%d).", NAMES[k], Word(s[k] or 50), s[k] or 50) end
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local owner, mark = LC.DistrictOwner(n)
        lines[#lines + 1] = string.format("%s: %s%s.", BName(n), owner == "contested" and "contested" or (owner == "resistance" and "the Resistance's" or "the Combine's"),
            mark == "liberated" and " (liberated)" or (mark == "crackdown" and " (under a crackdown)" or ""))
    end
    return lines
end

local function Bulletin(s)
    local parts = { string.format("City Bulletin, day %d.", s.day) }
    for _, line in ipairs(s.news) do parts[#parts + 1] = line end
    parts[#parts + 1] = string.format("Supply %s. Morale %s.", Word(s.supply), Word(s.morale))
    local crack = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if select(2, LC.DistrictOwner(n)) == "crackdown" then crack[#crack + 1] = BName(n) end
    end
    if #crack > 0 then parts[#parts + 1] = "Under a crackdown: " .. table.concat(crack, ", ") .. "." end
    local text = table.concat(parts, " ")
    s.news = {}
    if LC.SetGlobalLong then LC.SetGlobalLong("lc_broadcast", string.sub(text, 1, 590)) end
    SetGlobal2String("lc_broadcast_by", "City Bulletin")
    SetGlobal2Float("lc_broadcast_at", CurTime())
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City Bulletin] " .. text) end
    SetGlobal2String("lc_city_bulletin", string.sub(text, 1, 590))
    hook.Run("LivingCityBulletin", text)
    return text
end
LC.LedgerBulletin = function() return Bulletin(Load()) end

-- A new city day: the drift, the marks that run out, the bulletin.
function LC.LedgerNewDay(quiet)
    local s = Load()
    s.day = s.day + 1
    Drift(s)
    for k, until_ in pairs(table.Copy(s.liberated)) do
        if until_ <= s.day then
            -- the liberation ends: the Combine come back for it (on the next morning someone's here to see it)
            s.liberated[k] = nil
            s.districts[k] = 0
            News(BName(tonumber(k) or k) .. " is the Combine's to retake. Civil Protection moves in.")
            s.pendingRaid = k
        end
    end
    if s.pendingRaid and not quiet then
        local k = s.pendingRaid
        s.pendingRaid = nil
        if LC.StartRaid then pcall(LC.StartRaid, tonumber(k) or k) end
    end
    dirty = true
    if not quiet then Bulletin(s) end
    Save()
end

-- The days the city missed while the server was empty (up to a week), drifted through quietly.
function LC.LedgerCatchUp()
    local s = Load()
    local missed = math.min(7, math.floor((os.time() - (s.lastSave or os.time())) / DayLen()))
    for _ = 1, missed do LC.LedgerNewDay(true) end
    if missed > 0 then News(string.format("%d day%s passed while the streets were quiet.", missed, missed == 1 and "" or "s")) end
    return missed
end

-- The effects on the streets.
local function Effects()
    local s = Load()
    if not cvOn:GetBool() or not cvEffects:GetBool() then
        LC.LedgerCops, LC.LedgerRebels, LC.LedgerSnitchMul = 0, 0, 1
        return
    end
    LC.LedgerCops = math.floor(((s.combine or 50) - 50) / 12)             -- (-4 to +4 units)
    LC.LedgerRebels = math.floor(((s.resistance or 50) - 50) / 12)        -- (-4 to +4 fighters)
    LC.LedgerSnitchMul = 0.5 + (s.authority or 50) / 100                   -- (half as many informants to half again)
end
LC.LedgerEffects = Effects

------------------------------------------------------------------------
-- The Administrator's levers
------------------------------------------------------------------------

local function IsAdministrator(ply) return IsValid(ply) and (ply:GetNW2String("lcf_faction", "") == "admin" or (LC.IsAdministrator and LC.IsAdministrator(ply))) end

local function SpeechStand(from)
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("speech") or {}) do
        local d = p.pos:DistToSqr(from)
        if not bd or d < bd then best, bd = p, d end
    end
    return best
end

function LC.GoToSpeechStand(ply)
    if not IsAdministrator(ply) then return false, "Only the City Administrator speaks from the stand." end
    local p = SpeechStand(ply:GetPos())
    if not p then return false, "There's no speech stand in this city. (Staff: Living City Editor > Point: speech stand.)" end
    ply:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(p.pos + Vector(0, 0, 8))) or p.pos)
    if ply.SetEyeAngles then ply:SetEyeAngles(Angle(0, p.yaw or 0, 0)) end
    ply:ChatPrint("[The office] You're at the speech stand. F2 > Me > The city's levers > Give a speech, when you're ready.")
    -- her guards come with her (sv_livingcity_admguard.lua or wherever they follow her)
    hook.Run("LivingCityAdminMoved", ply, p.pos)
    return true
end

function LC.GiveSpeech(ply, text)
    if not IsAdministrator(ply) then return false, "Only the City Administrator gives speeches." end
    local s = Load()
    if s.speechDay == s.day then return false, "You've spoken to the city today. Tomorrow." end
    text = string.Trim(tostring(text or ""))
    if #text < 10 then return false, "Say something to the city (at least a sentence)." end
    local stand = SpeechStand(ply:GetPos())
    if stand and ply:GetPos():DistToSqr(stand.pos) > 400 * 400 then return false, "Speak from the speech stand: F2 > Me > The city's levers > Go to the speech stand." end
    s.speechDay = s.day
    local who = (LC.CharacterName and LC.CharacterName(ply)) or ply:Nick()
    if LC.SetGlobalLong then LC.SetGlobalLong("lc_broadcast", string.sub(text, 1, 590)) end
    SetGlobal2String("lc_broadcast_by", "The City Administrator")
    SetGlobal2Float("lc_broadcast_at", CurTime())
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[The City Administrator, from the stand] " .. text) end
    local heard = 0
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:GetPos():DistToSqr(ply:GetPos()) < 1200 * 1200 then
            local f = p:GetNW2String("lcf_faction", "")
            if (f == "" or f == "citizen") and LC.AddStanding then LC.AddStanding(p, 2, "heard the Administrator speak") heard = heard + 1 end
        end
    end
    Add("morale", 6, nil) Add("authority", 3, nil)
    News(string.format("%s addressed the city%s.", who, heard > 0 and (" before a crowd of " .. heard) or ""))
    Save()
    return true
end

function LC.Amnesty(ply)
    if not IsAdministrator(ply) then return false, "Only the City Administrator grants an amnesty." end
    local s = Load()
    if s.amnestyDay == s.day then return false, "One amnesty a day." end
    s.amnestyDay = s.day
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsWanted and LC.PlayerIsWanted(p) and not LC.PlayerIsCP(p) then LC.ClearWanted(p) n = n + 1 end
    end
    Add("morale", 6, nil) Add("authority", -8, nil) Add("resistance", 3, nil)
    News("The Administrator declared an amnesty" .. (n > 0 and (": " .. n .. " forgiven") or "") .. ".")
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[The City Administrator] An amnesty: the wanted are forgiven. Do not make the city regret it.") end
    Save()
    return true
end

function LC.Crackdown(ply, block)
    if not IsAdministrator(ply) then return false, "Only the City Administrator orders a crackdown." end
    block = tonumber(block)
    if not block then return false, "Which district?" end
    local s = Load()
    s.crackdown[tostring(block)] = s.day + CRACKDOWN_DAYS
    s.districts[tostring(block)] = math.min(s.districts[tostring(block)] or 0, -40)
    Add("authority", 5, nil) Add("morale", -6, nil) Add("resistance", 4, nil)
    News("A crackdown on " .. BName(block) .. ".")
    if LC.StartRaid then pcall(LC.StartRaid, block) end
    for _, p in ipairs(player.GetAll()) do p:ChatPrint("[The City Administrator] A crackdown on " .. BName(block) .. ". Residents: cooperate.") end
    Save()
    return true
end

function LC.ExtraRations(ply)
    if not IsAdministrator(ply) then return false, "Only the City Administrator orders extra rations." end
    local s = Load()
    if s.supply < 20 then return false, "The stores are too low for extra rations." end
    Add("supply", -15, nil) Add("morale", 8, nil)
    News("The Administrator ordered extra rations.")
    if LC.StartEvent then pcall(LC.StartEvent, "rations") end
    Save()
    return true
end

------------------------------------------------------------------------
-- What the menus show
------------------------------------------------------------------------

local function Sync()
    if not cvOn:GetBool() then SetGlobal2String("lc_ledger", "") return end
    local s = Load()
    local d = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        local owner, mark = LC.DistrictOwner(n)
        d[#d + 1] = { n = n, name = BName(n), owner = owner, mark = mark }
    end
    SetGlobal2String("lc_ledger", util.TableToJSON({ day = s.day, supply = s.supply, morale = s.morale, combine = s.combine, resistance = s.resistance,
        authority = s.authority, districts = d, spoke = s.speechDay == s.day or nil, amnesty = s.amnestyDay == s.day or nil,
        stand = (LC.CountPointsOfKind and LC.CountPointsOfKind("speech") or 0) > 0 or nil }) or "")
end
LC.LedgerSync = Sync

-- The days pass on the city's clock; while the server was empty, the days it missed (up to a week).
local lastDayAt
local function Tick()
    if not cvOn:GetBool() then return end
    local s = Load()
    local now = CurTime()
    if not lastDayAt then
        lastDayAt = now
        LC.LedgerCatchUp()
    end
    if now - lastDayAt >= DayLen() then
        lastDayAt = now
        LC.LedgerNewDay(false)
    end
    -- unrest wears morale down; calm lifts it (a little, every five minutes)
    if LC.CityState and (s.lastMood or 0) + 300 <= now then
        s.lastMood = now
        local st = LC.CityState()
        if st == "unrest" then Add("morale", -1, nil) Add("authority", -1, nil) elseif st == "calm" then Add("morale", 0.5, nil) end
    end
    Effects()
    Sync()
    if dirty and (s.savedAt or 0) + 60 <= now then s.savedAt = now Save() end
end
timer.Create("LivingCityLedger", 5, 0, function()
    local ok, err = pcall(Tick)
    if not ok and LC.Error then LC.Error("ledger", err) end
end)
hook.Add("ShutDown", "LivingCityLedger", function() if L then Save() end end)

-- The menu's actions (F2 > Me).
local function Wrap()
    if LC.MenuActions then
        LC.MenuActions.speechstand, LC.MenuActions.speech, LC.MenuActions.amnesty, LC.MenuActions.crackdown, LC.MenuActions.extrarations = true, true, true, true, true
    end
end
Wrap()
hook.Add("Initialize", "LivingCityLedger", Wrap)
hook.Add("PlayerSay", "LivingCityLedger", function(ply, text)
    local cmd, rest = string.match(string.Trim(tostring(text or "")), "^[!/](%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local ok, why
    if cmd == "speechstand" then ok, why = LC.GoToSpeechStand(ply)
    elseif cmd == "speech" then ok, why = LC.GiveSpeech(ply, rest)
    elseif cmd == "amnesty" then ok, why = LC.Amnesty(ply)
    elseif cmd == "crackdown" then ok, why = LC.Crackdown(ply, rest)
    elseif cmd == "extrarations" then ok, why = LC.ExtraRations(ply)
    else return end
    if not ok and why then ply:ChatPrint("[The office] " .. why) end
    return ""
end)
