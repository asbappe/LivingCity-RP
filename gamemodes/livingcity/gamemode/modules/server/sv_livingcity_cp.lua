--[[
    Living City: Civil Protection's toolset

      Records        Every citizen has a record, kept by CID (or by the number
                     on their forged papers, which is the point of them):
                     violations (written in by the city as they happen:
                     wanted, custody, contraband, escape), notes units add,
                     and their loyalty points (Civil Standing). Units read and
                     write it at the records terminal: !records, or bind a key
                     to lc_records. Units can award or deduct loyalty points
                     (10 at a time, 25 for officers), once every two minutes
                     per citizen.

      BOLOs          "Be on the lookout": a unit puts one out on a citizen
                     (from their record) or on a description. Every unit hears
                     it, and a citizen with one out on them shows it on their
                     nametag to units. They expire (30 minutes unless set).

      Zip ties       !tie, looking at someone up close: hands up, down,
                     stopped by a unit, or from behind. Three seconds. Units
                     carry their own; anyone else needs zip ties (Commissary
                     for units, the black market for everyone else). Tied:
                     no weapons, no using anything, walking pace. !drag walks
                     them along with you; the baton's arrest takes them in.
                     !untie (or a unit cuts them free). A tied person left
                     alone can !struggle free (30 seconds, unseen).

      Hands up       !handsup (or /handsup): weapon away, hands where they can
                     be seen. Again to put them down.

      Sociostability Green (nominal), yellow (marginal), red (judgment waiver),
                     city-wide, on everyone's HUD. Set by what's happening
                     (curfew, sweeps, unrest, skirmishes: yellow; lockdown, an
                     outbreak, an Overwatch-level manhunt: red), or by an
                     officer or admin for a while: !socio <green|yellow|red>
                     [minutes], !socio auto. Yellow means half as many stops
                     again; red, twice as many.

      /request       A citizen with a Civil Protection call box (Commissary) calls Civil
                     Protection to where they are: /request <what's wrong>.
                     Units get a marker and the message; with no units on,
                     the nearest Civil Protection NPC walks over. Once a minute.

      Voice lines    Units speak in the mask's voice: !vo for the menu, /vo
                     <word>, or say a line's exact words in chat. Overwatch
                     have their own.

      lc_cp_tools 0/1, lc_bolo_minutes (30), lc_request_cooldown (60),
      lc_tie_seconds (3), lc_struggle_seconds (30)
]]

if CLIENT then return end

util.AddNetworkString("lc_records")
util.AddNetworkString("lc_records_do")
util.AddNetworkString("lc_vo_menu")
util.AddNetworkString("lc_announce")

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_cp_tools", "1", FLAGS, "Civil Protection's toolset: records, BOLOs, cuffs, sociostability, requests, voice lines")
local cvBolo     = CreateConVar("lc_bolo_minutes", "30", FLAGS, "How long a BOLO stays out unless set otherwise")
local cvReqWait  = CreateConVar("lc_request_cooldown", "60", FLAGS, "Seconds between requests from one citizen")
local cvTieSecs  = CreateConVar("lc_tie_seconds", "3", FLAGS, "Seconds to cuff someone")
local cvStruggle = CreateConVar("lc_struggle_seconds", "30", FLAGS, "Seconds for a cuffed person to work themselves free")

local DIR = "livingcity"
local RECORDS_FILE = DIR .. "/records.json"
local BOLO_FILE = DIR .. "/bolos.json"
local MAX_VIOLATIONS, MAX_NOTES = 30, 15

local function On() return cvOn:GetBool() end
local function IsUnit(ply) return IsValid(ply) and ply:IsPlayer() and (LC.PlayerIsCP(ply) or ply:IsAdmin()) end
local function RealUnit(ply) return IsValid(ply) and ply:IsPlayer() and LC.PlayerIsCP(ply) end
local function Faction(ply) return ply:GetNW2String("lcf_faction", "") end
local function Rank(ply) return ply:GetNW2Int("lcf_rank", 1) end
local function Callsign(ply)
    local t = ply:GetNW2String("lcf_title", "")
    return t ~= "" and t or ply:Nick()
end

-- An officer: Civil Protection from Division Leader up (the Overwatch too),
-- the Administrator, or an admin.
function LC.IsCPOfficer(ply)
    if not IsValid(ply) then return false end
    if ply:IsAdmin() then return true end
    local f = Faction(ply)
    return (f == "cp" and Rank(ply) >= 3) or f == "admin"
end

-- Only the Administrator sets sociostability (the owner, 7 November: not recruits, not staff by rank).
function LC.IsAdministrator(ply)
    return IsValid(ply) and ply:IsPlayer() and Faction(ply) == "admin"
end

------------------------------------------------------------------------
-- Records
------------------------------------------------------------------------

LC.Records = LC.Records or nil
local dirty = false

local function LoadRecords()
    if LC.Records then return LC.Records end
    local raw = file.Read(RECORDS_FILE, "DATA")
    LC.Records = raw and util.JSONToTable(raw) or {}
    return LC.Records
end

local function SaveSoon() dirty = true end

timer.Create("LivingCityRecordsSave", 10, 0, function()
    if not dirty or not LC.Records then return end
    dirty = false
    file.CreateDir(DIR)
    file.Write(RECORDS_FILE, util.TableToJSON(LC.Records))
    file.Write(BOLO_FILE, util.TableToJSON(LC.BOLOs or {}))
end)

-- Who the city thinks this is: forged papers win, then the CID, then the account.
function LC.RecordKey(ply)
    local alias = ply:GetNW2String("lcd_alias", "")
    if alias ~= "" then return "alias:" .. alias end
    local cid = ply:GetNW2String("lc_cid", "")
    if cid ~= "" then return cid end
    return "sid:" .. ply:SteamID()
end

local function NameOf(ply)
    local alias = ply:GetNW2String("lcd_alias", "")
    if alias ~= "" then return "Citizen " .. alias end
    return LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
end

local function CIDOf(ply)
    local alias = ply:GetNW2String("lcd_alias", "")
    if alias ~= "" then return alias end
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and cid or "unregistered"
end

function LC.RecordOf(ply)
    local recs = LoadRecords()
    local key = LC.RecordKey(ply)
    local r = recs[key]
    if not r then
        r = { v = {}, n = {} }
        recs[key] = r
    end
    r.name, r.cid, r.seen = NameOf(ply), CIDOf(ply), os.time()
    return r, key
end

local function Push(list, entry, max)
    list[#list + 1] = entry
    while #list > max do table.remove(list, 1) end
end

function LC.AddViolation(ply, text, by)
    if not On() or not IsValid(ply) or not ply:IsPlayer() or not text or text == "" then return end
    local r = LC.RecordOf(ply)
    local last = r.v[#r.v]
    if last and last.text == text and os.time() - (last.t or 0) < 30 then return end -- the same thing, reported twice
    Push(r.v, { t = os.time(), text = text, by = by }, MAX_VIOLATIONS)
    SaveSoon()
end

function LC.AddRecordNote(unit, key, text)
    local r = LoadRecords()[key]
    if not r then return false, "No such record." end
    text = string.Trim(tostring(text or ""))
    if #text < 2 then return false, "Write something." end
    Push(r.n, { t = os.time(), text = string.sub(text, 1, 160), by = Callsign(unit) }, MAX_NOTES)
    SaveSoon()
    return true
end

-- The city writes the record as things happen.
hook.Add("LivingCityWanted", "LivingCityRecords", function(ply, reason)
    if IsValid(ply) and ply:IsPlayer() then LC.AddViolation(ply, "Wanted: " .. tostring(reason or "unspecified")) end
end)
hook.Add("LivingCityIncarcerated", "LivingCityRecords", function(ply, secs, reason, arrester)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    LC.AddViolation(ply, string.format("Custody, %d min: %s", math.max(1, math.floor((tonumber(secs) or 60) / 60)), tostring(reason or "")),
        IsValid(arrester) and arrester:IsPlayer() and Callsign(arrester) or nil)
end)
hook.Add("LivingCitySearched", "LivingCityRecords", function(searcher, target, found, guns)
    if not (IsValid(target) and target:IsPlayer()) then return end
    local names = {}
    for _, f in ipairs(found or {}) do
        local it = LCS and LCS.Items[f.id]
        names[#names + 1] = (f.n or 1) > 1 and ((it and it.name or f.id) .. " x" .. f.n) or (it and it.name or f.id)
    end
    for _, g in ipairs(guns or {}) do names[#names + 1] = (string.gsub(g, "^weapon_", "")) end
    if #names > 0 then
        LC.AddViolation(target, "Contraband: " .. table.concat(names, ", "), IsValid(searcher) and searcher:IsPlayer() and Callsign(searcher) or nil)
    end
end)
hook.Add("LivingCityEscaped", "LivingCityRecords", function(ply)
    if IsValid(ply) and ply:IsPlayer() then LC.AddViolation(ply, "Escaped custody") end
end)
hook.Add("PlayerInitialSpawn", "LivingCityRecords", function(ply)
    timer.Simple(5, function() if IsValid(ply) and On() then LC.RecordOf(ply) SaveSoon() end end)
end)

-- Loyalty points: units award or deduct Civil Standing.
local loyaltyNext = {} -- ["unit|target"] = time
function LC.AdjustLoyalty(unit, target, n)
    if not IsUnit(unit) then return false, "Civil Protection units only." end
    if not IsValid(target) or not target:IsPlayer() then return false, "They're not in the city right now." end
    if target == unit then return false, "Not on yourself." end
    local cap = LC.IsCPOfficer(unit) and 25 or 10
    n = math.Clamp(math.floor(tonumber(n) or 0), -cap, cap)
    if n == 0 then return false, "Nothing to change." end
    local k = tostring(unit:SteamID()) .. "|" .. LC.RecordKey(target)
    if (loyaltyNext[k] or 0) > CurTime() and not unit:IsAdmin() then
        return false, string.format("You've already adjusted their points. Again in %ds.", math.ceil(loyaltyNext[k] - CurTime()))
    end
    loyaltyNext[k] = CurTime() + 120
    if LC.AddStanding then LC.AddStanding(target, n, (n > 0 and "loyalty points awarded by " or "loyalty points deducted by ") .. Callsign(unit)) end
    local r = LC.RecordOf(target)
    Push(r.n, { t = os.time(), text = string.format("Loyalty points %+d", n), by = Callsign(unit) }, MAX_NOTES)
    SaveSoon()
    return true, string.format("%s: %+d loyalty points.", NameOf(target), n)
end

------------------------------------------------------------------------
-- BOLOs
------------------------------------------------------------------------

LC.BOLOs = LC.BOLOs or nil
local function Bolos()
    if not LC.BOLOs then
        local raw = file.Read(BOLO_FILE, "DATA")
        LC.BOLOs = raw and util.JSONToTable(raw) or {}
    end
    return LC.BOLOs
end

local function Units()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if RealUnit(p) then out[#out + 1] = p end end
    return out
end

local function TellUnits(msg) for _, p in ipairs(Units()) do p:ChatPrint(msg) end end

-- Mark who's on a BOLO, so units see it on their nametag.
function LC.SyncBolos()
    local now = os.time()
    local list = Bolos()
    for i = #list, 1, -1 do if (list[i].untilT or 0) < now then table.remove(list, i) dirty = true end end
    SetGlobal2Float("lc_bolos", #list)
    local byKey = {}
    for _, b in ipairs(list) do if b.key then byKey[b.key] = b end end
    for _, p in ipairs(player.GetAll()) do
        local b = byKey[LC.RecordKey(p)]
        p:SetNW2Bool("lc_bolo", b ~= nil)
        p:SetNW2String("lc_bolo_text", b and b.text or "")
    end
end

function LC.AddBOLO(unit, key, text, minutes)
    if not IsUnit(unit) then return false, "Civil Protection units only." end
    text = string.Trim(tostring(text or ""))
    if #text < 3 then return false, "Say who or what to look out for." end
    -- one every half minute (each one is a call and a sound for every unit)
    if IsValid(unit) and not unit:IsAdmin() and (unit.lcBoloNext or 0) > CurTime() then
        return false, string.format("You sent one just now. Wait %d seconds.", math.ceil(unit.lcBoloNext - CurTime()))
    end
    if IsValid(unit) then unit.lcBoloNext = CurTime() + 30 end
    minutes = math.Clamp(math.floor(tonumber(minutes) or cvBolo:GetFloat()), 5, 240)
    local r = key and LoadRecords()[key]
    local list = Bolos()
    local id = (LC.BoloSerial or 0) + 1
    LC.BoloSerial = id
    local b = { id = id .. "-" .. os.time(), key = r and key or nil, name = r and r.name or nil, cid = r and r.cid or nil,
        text = string.sub(text, 1, 120), by = Callsign(unit), at = os.time(), untilT = os.time() + minutes * 60 }
    list[#list + 1] = b
    while #list > 40 do table.remove(list, 1) end
    dirty = true
    LC.SyncBolos()
    TellUnits(string.format("[CP net] BOLO (be on the lookout) from %s: %s%s (%d min)", b.by, b.name and (b.name .. ", " .. (b.cid or "") .. ": ") or "", b.text, minutes))
    for _, p in ipairs(Units()) do p:EmitSound("npc/overwatch/radiovoice/on1.wav", 50) end
    if r then Push(r.n, { t = os.time(), text = "BOLO: " .. b.text, by = b.by }, MAX_NOTES) SaveSoon() end
    hook.Run("LivingCityBOLO", b, unit)
    return true, b
end

function LC.ClearBOLO(unit, id)
    if not IsUnit(unit) then return false, "Civil Protection units only." end
    local list = Bolos()
    for i, b in ipairs(list) do
        if b.id == id then
            table.remove(list, i)
            dirty = true
            LC.SyncBolos()
            TellUnits(string.format("[CP net] BOLO cancelled by %s: %s", Callsign(unit), b.text))
            return true
        end
    end
    return false, "No such BOLO."
end

-- Every BOLO on this record, gone (a data chip wiping it, sv_livingcity_heist.lua)
function LC.DropBolosFor(key)
    local list = Bolos()
    for i = #list, 1, -1 do if list[i].key == key then table.remove(list, i) dirty = true end end
    LC.SyncBolos()
end

timer.Create("LivingCityBolos", 5, 0, function() if On() then LC.SyncBolos() end end)

------------------------------------------------------------------------
-- The records terminal
------------------------------------------------------------------------

local function Pack(key, r, online)
    local out = { key = key, name = r.name, cid = r.cid, seen = r.seen, v = {}, n = {} }
    for i = math.max(1, #r.v - 14), #r.v do out.v[#out.v + 1] = r.v[i] end
    for i = math.max(1, #r.n - 9), #r.n do out.n[#out.n + 1] = r.n[i] end
    out.violations = #r.v
    if IsValid(online) then
        out.online = true
        out.standing = LC.Standing and LC.Standing(online) or nil
        out.tier = LCS and LC.Standing and LCS.TierFor(LC.Standing(online)).name or nil
        out.wanted = LC.PlayerIsWanted(online) or nil
        out.custody = (LC.InCustody and LC.InCustody(online)) or nil
        out.tied = online:GetNW2Bool("lc_tied", false) or nil
        out.license = (LC.HasItem and LC.HasItem(online, "business_license")) or nil
    end
    return out
end

function LC.SendRecords(unit, search)
    if not IsUnit(unit) then return false end
    local recs = LoadRecords()
    local data = { people = {}, bolos = {}, requests = {}, officer = LC.IsCPOfficer(unit) or nil, socioctl = LC.IsAdministrator(unit) or nil, socio = LC.Socio or "green" }
    local shown = {}
    for _, p in ipairs(player.GetAll()) do
        if not RealUnit(p) or p == unit then
            local r, key = LC.RecordOf(p)
            if not shown[key] then
                shown[key] = true
                data.people[#data.people + 1] = Pack(key, r, p)
            end
        end
    end
    -- people not on right now: the most recent, or what was searched for
    search = string.lower(string.Trim(tostring(search or "")))
    local rest = {}
    for key, r in pairs(recs) do
        if not shown[key] then
            if search == "" or string.find(string.lower(r.name or ""), search, 1, true) or string.find(string.lower(r.cid or ""), search, 1, true) then
                rest[#rest + 1] = { key = key, r = r }
            end
        end
    end
    table.sort(rest, function(a, b) return (a.r.seen or 0) > (b.r.seen or 0) end)
    for i = 1, math.min(40, #rest) do data.people[#data.people + 1] = Pack(rest[i].key, rest[i].r, nil) end
    for _, b in ipairs(Bolos()) do data.bolos[#data.bolos + 1] = b end
    for _, q in ipairs(LC.Requests or {}) do data.requests[#data.requests + 1] = q end
    data.search = search
    LC.SendCompressed("lc_records", data, unit)
    return true
end

local function OpenRecords(ply)
    if not On() then return ply:ChatPrint("The records terminal is off on this server.") end
    if not IsUnit(ply) then
        if LC.DisguisedAsCP and LC.DisguisedAsCP(ply) then
            ply:ChatPrint("[Records] Access denied: this terminal is for Civil Protection only.")
        else
            ply:ChatPrint("Civil Protection only.")
        end
        return
    end
    LC.SendRecords(ply)
end
LC.OpenRecords = OpenRecords

concommand.Add("lc_records", function(ply) if IsValid(ply) then OpenRecords(ply) end end)

local function FindOnline(key)
    for _, p in ipairs(player.GetAll()) do if LC.RecordKey(p) == key then return p end end
    return nil
end

net.Receive("lc_records_do", function(_, ply)
    if not IsValid(ply) or not IsUnit(ply) or not On() then return end
    local action, key, text, num = net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString()
    local ok, msg = true, nil
    if action == "note" then
        ok, msg = LC.AddRecordNote(ply, key, text)
    elseif action == "violation" then
        local r = LoadRecords()[key]
        if r and #string.Trim(text) > 1 then
            Push(r.v, { t = os.time(), text = string.sub(string.Trim(text), 1, 160), by = Callsign(ply) }, MAX_VIOLATIONS)
            SaveSoon()
        else ok, msg = false, "Write the violation." end
    elseif action == "loyalty" then
        ok, msg = LC.AdjustLoyalty(ply, FindOnline(key), tonumber(num))
    elseif action == "bolo" then
        local b
        ok, b = LC.AddBOLO(ply, key ~= "" and key or nil, text, tonumber(num))
        if not ok then msg = b end
    elseif action == "clearbolo" then
        ok, msg = LC.ClearBOLO(ply, key)
    elseif action == "revoke" then
        ok, msg = LC.RevokeLicense and LC.RevokeLicense(ply, FindOnline(key))
    elseif action == "socio" then
        ok, msg = LC.SetSocio(ply, key, tonumber(num))
    end
    if msg and not ok then ply:ChatPrint("[Records] " .. msg) elseif msg then ply:ChatPrint("[Records] " .. msg) end
    LC.SendRecords(ply, action == "search" and text or nil)
end)

------------------------------------------------------------------------
-- Hands up, zip ties, and walking someone along
------------------------------------------------------------------------

LC.Tied = LC.Tied or {} -- [ply] = { by, weapons, walk, run, escort }

function LC.IsTied(ply) return LC.Tied[ply] ~= nil end

function LC.SetHandsUp(ply, up)
    if up == nil then up = not ply:GetNW2Bool("lc_handsup", false) end
    if up and (LC.IsTied(ply) or (LC.IsDowned and LC.IsDowned(ply)) or not ply:Alive()) then return false end
    ply:SetNW2Bool("lc_handsup", up)
    if up then
        if ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end
        ply:ChatPrint("[Living City] Hands up. (F1 > Lower my hands.)")
    end
    return true
end

-- Putting your weapon back in hand puts your hands down.
hook.Add("PlayerSwitchWeapon", "LivingCityHandsUp", function(ply, old, new)
    if ply:GetNW2Bool("lc_handsup", false) and IsValid(new) and new:GetClass() ~= "weapon_lc_hands" then ply:SetNW2Bool("lc_handsup", false) end
end)

local function Behind(tier, target)
    local to = tier:GetPos() - target:GetPos()
    to.z = 0
    if to:LengthSqr() < 1 then return false end
    to:Normalize()
    local yaw = target:EyeAngles().y
    local fwd = Angle(0, yaw, 0):Forward()
    return fwd:Dot(to) < -0.3
end

-- Can this person tie that one up? ok, or false and why.
function LC.CanTie(tier, target)
    if not On() then return false, "Cuffs are off on this server." end
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return false, "Look at someone, up close." end
    if tier == target then return false, "Not yourself." end
    if LC.IsTied(tier) then return false, "Your hands are cuffed." end
    if LC.IsTied(target) then return false, "Their hands are already cuffed." end
    if LC.Prisoners and LC.Prisoners[target] then return false, "They're already in custody." end
    if tier:GetPos():DistToSqr(target:GetPos()) > 110 * 110 then return false, "Get closer." end
    if not RealUnit(tier) and not (LC.HasItem and LC.HasItem(tier, "zipties")) then return false, "You need cuffs." end
    local willing = target:GetNW2Bool("lc_handsup", false) or (LC.IsDowned and LC.IsDowned(target))
        or (LC.Stops and LC.Stops[target]) or (LC.Detained and LC.Detained[target])
    if not willing and not Behind(tier, target) then
        return false, "They'd fight you off. You can only cuff someone with their hands up, knocked down, stopped by a Civil Protection unit, or from behind."
    end
    return true
end

function LC.TiePlayer(target, tier)
    if LC.IsTied(target) then return false end
    if LC.IsDowned and LC.IsDowned(target) then LC.Revive(target, math.max(10, target:Health()), tier) end
    local t = { by = tier, weapons = {}, walk = target:GetWalkSpeed(), run = target:GetRunSpeed(), at = CurTime() }
    for _, w in ipairs(target:GetWeapons()) do t.weapons[#t.weapons + 1] = w:GetClass() end
    target:StripWeapons()
    target:SetWalkSpeed(80)
    target:SetRunSpeed(80)
    target:SetNW2Bool("lc_tied", true)
    target:SetNW2Bool("lc_handsup", false)
    LC.Tied[target] = t
    if IsValid(tier) and not RealUnit(tier) and LC.TakeItem then LC.TakeItem(tier, "zipties", 1) end
    target:EmitSound("physics/plastic/plastic_box_impact_soft2.wav", 60)
    target:ChatPrint("[Living City] Your hands are cuffed, so you can't use anything. To try to get free: F1 > Work at the cuffs, when nobody's looking.")
    if IsValid(tier) then tier:ChatPrint("Cuffed. Look at them and press F1 to drag them along or take the cuffs off.") end
    hook.Run("LivingCityTied", target, tier)
    return true
end

-- giveBack: hand their weapons back (not when they're being locked up).
function LC.Untie(target, by, giveBack)
    local t = LC.Tied[target]
    if not t then return false end
    LC.Tied[target] = nil
    if not IsValid(target) then return true end
    target:SetNW2Bool("lc_tied", false)
    target:SetWalkSpeed(t.walk or 110)
    target:SetRunSpeed(t.run or 190)
    if giveBack ~= false and target:Alive() then
        for _, c in ipairs(t.weapons) do target:Give(c) end
    end
    target:EmitSound("physics/plastic/plastic_box_break1.wav", 55)
    hook.Run("LivingCityUntied", target, by)
    return true, t
end

local function EyeTarget(ply, range)
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:IsPlayer() and e:GetPos():DistToSqr(ply:GetPos()) < (range or 110) ^ 2 then return e end
    return nil
end
LC.CPEyeTarget = EyeTarget

function LC.StartTie(ply, target)
    target = target or EyeTarget(ply)
    local ok, why = LC.CanTie(ply, target)
    if not ok then return false, why end
    target:ChatPrint("[Living City] Someone is putting cuffs on you.")
    return LC.StartTask(ply, cvTieSecs:GetFloat(), "Cuffing them...", {
        maxMove = 40, cancelText = "You let go.",
        done = function(p)
            if not IsValid(target) or not target:Alive() or p:GetPos():DistToSqr(target:GetPos()) > 130 * 130 then
                return p:ChatPrint("They got away from you.")
            end
            if LC.IsTied(target) then return end
            LC.TiePlayer(target, p)
        end,
    })
end

function LC.StartUntie(ply, target)
    target = target or EyeTarget(ply)
    if not IsValid(target) or not LC.IsTied(target) then return false, "Look at someone whose hands are cuffed, up close." end
    if LC.IsTied(ply) then return false, "Your own hands are cuffed." end
    if RealUnit(ply) then
        LC.Untie(target, ply, true)
        target:ChatPrint("[Living City] A Civil Protection unit takes your cuffs off.")
        return true
    end
    return LC.StartTask(ply, 4, "Uncuffing them...", {
        maxMove = 40, cancelText = "You stop.",
        done = function(p)
            if IsValid(target) and LC.IsTied(target) and p:GetPos():DistToSqr(target:GetPos()) < 130 * 130 then
                LC.Untie(target, p, true)
                target:ChatPrint("[Living City] Someone gets your cuffs off. You're free.")
            end
        end,
    })
end

local function UnitSees(ply, range)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, range) then return true end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and RealUnit(p) and p:Alive() and p:GetPos():DistToSqr(ply:GetPos()) < range * range then
            if LC.LineOfSight(p:EyePos(), ply:EyePos(), p) then return true end
        end
    end
    return false
end

function LC.StartStruggle(ply)
    local t = LC.Tied[ply]
    if not t then return false, "Your hands aren't cuffed." end
    if IsValid(t.escort) or hook.Run("LivingCityCanStruggle", ply) == false then return false, "Not while they've got hold of you." end
    return LC.StartTask(ply, cvStruggle:GetFloat(), "Working at the cuffs...", {
        maxMove = 30, cancelText = "You stop working at the cuffs.",
        done = function(p)
            local tt = LC.Tied[p]
            if not tt then return end
            if IsValid(tt.escort) or UnitSees(p, 700) then
                p:ChatPrint("[Living City] They see you working at the cuffs, and tighten them.")
                return
            end
            LC.Untie(p, p, true)
            p:ChatPrint("[Living City] The cuffs give. Your hands are free.")
        end,
    })
end

-- !drag on someone tied: walk them along. Returns nil when it's not about a tied person.
function LC.TryEscort(ply)
    -- a cuffed NPC: walked to the cells (sv_livingcity_arrest.lua)
    if LC.NPCCustodyDrag then
        local handled, why = LC.NPCCustodyDrag(ply)
        if handled ~= nil then return handled, why end
    end
    for target, t in pairs(LC.Tied) do
        if t.escort == ply then
            t.escort = nil
            ply:ChatPrint("You let go of them.")
            return true
        end
    end
    local target = EyeTarget(ply, 130)
    if not target or not LC.IsTied(target) then return nil end
    if LC.IsTied(ply) then return false, "Your hands are cuffed." end
    LC.Tied[target].escort = ply
    ply:ChatPrint("You take them by the arm. (F1 > Drag them along again to let go.)")
    target:ChatPrint("[Living City] You're being walked along.")
    return true
end

timer.Create("LivingCityEscort", 0.1, 0, function()
    for target, t in pairs(LC.Tied) do
        if not IsValid(target) or not target:Alive() then
            LC.Tied[target] = nil
            if IsValid(target) then target:SetNW2Bool("lc_tied", false) end
        elseif t.escort ~= nil then
            local e = t.escort
            if not IsValid(e) or not e:Alive() or LC.IsTied(e) or (LC.IsDowned and LC.IsDowned(e))
                or e:GetPos():DistToSqr(target:GetPos()) > 450 * 450 then
                t.escort = nil
            else
                local fwd = e:GetForward()
                fwd.z = 0
                local want = e:GetPos() - fwd * 55
                local d = want - target:GetPos()
                d.z = 0
                local dist = d:Length()
                if dist > 200 then
                    -- caught on something: brought round to where they should be
                    local tr = util.TraceLine({ start = e:GetPos() + Vector(0, 0, 36), endpos = want + Vector(0, 0, 36), mask = MASK_PLAYERSOLID or MASK_SOLID, filter = { e, target } })
                    local spot = tr.Hit and (tr.HitPos - (want - e:GetPos()):GetNormalized() * 20) or (want + Vector(0, 0, 36))
                    target:SetPos(Vector(spot.x, spot.y, e:GetPos().z + 2))
                elseif dist > 40 then
                    local v = target:GetVelocity()
                    local speed = math.min(dist * 5, 260)
                    target:SetVelocity(d:GetNormalized() * speed - Vector(v.x, v.y, 0))
                end
            end
        end
    end
end)

-- Tied hands can't hold or use anything.
hook.Add("PlayerCanPickupWeapon", "LivingCityTied", function(ply) if LC.IsTied(ply) then return false end end)
hook.Add("PlayerUse", "LivingCityTied", function(ply) if LC.IsTied(ply) then return false end end)
hook.Add("PlayerSpawn", "LivingCityTied", function(ply)
    if LC.Tied[ply] then LC.Tied[ply] = nil end
    ply:SetNW2Bool("lc_tied", false)
    ply:SetNW2Bool("lc_handsup", false)
end)
hook.Add("PlayerDisconnected", "LivingCityTied", function(ply) LC.Tied[ply] = nil end)
-- taken into custody: the ties come off, and what they carried goes with the rest of their things
hook.Add("LivingCityIncarcerated", "LivingCityTied", function(ply)
    if not (IsValid(ply) and ply:IsPlayer()) or not LC.Tied[ply] then return end
    local _, t = LC.Untie(ply, nil, false)
    local pr = LC.Prisoners and LC.Prisoners[ply]
    if pr and t then
        pr.weapons = pr.weapons or {}
        for _, c in ipairs(t.weapons) do pr.weapons[#pr.weapons + 1] = c end
    end
end)

------------------------------------------------------------------------
-- Sociostability
------------------------------------------------------------------------

LC.Socio = LC.Socio or "green"
LC.SocioOverride = LC.SocioOverride or nil -- { level, untilT, by }

local CV = "npc/overwatch/cityvoice/"
local SOCIO_VOICE = {
    green = CV .. "f_sociostabilizationrestored_spkr.wav",
    yellow = CV .. "f_unrestprocedure1_spkr.wav",
    red = CV .. "f_protectionresponse_1_spkr.wav",
}
local SOCIO_MEANS = {
    green = { "Things are back to normal. Ordinary stops, ordinary days.", "Back to ordinary patrols." },
    yellow = { "More stop-and-searches on the street. Keep your papers ready and nothing on you you'd want found.",
        "Half as many stops again as usual. Keep an eye out." },
    red = { "Civil Protection units may shoot to kill as they see fit, and stop twice as many people. Get indoors and stay out of sight.",
        "Twice as many stops. You may shoot to kill as you see fit: make it count." },
}

-- Infected that broke out of an infestation (sv_livingcity_war.lua's outbreak) still loose in the city:
-- out of every infestation zone. The ordinary infested, in their own ground, are no concern of the city's.
local function LooseInfected()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "zombie" and st.unmanaged and npc:Health() > 0
            and not (LC.InInfest and LC.InInfest(npc:GetPos())) then return true end
    end
    return false
end
LC.LooseInfected = LooseInfected

-- The level, and why (said with it when it changes: the owner, 1 November, couldn't tell why it fell).
function LC.SocioAuto()
    if LC.Event == "lockdown" then return "red", "lockdown" end
    local now = CurTime()
    -- an outbreak: red only while its infected are actually loose in the city (at most 5 minutes);
    -- headcrabs and zombies in the infestation itself don't touch it
    if LC.LastOutbreak and now - LC.LastOutbreak < 300 and LooseInfected() then return "red", "infected loose in the city" end
    local why
    if LC.Event == "curfew" or LC.Event == "sweep" or LC.Event == "raid" then why = LC.Event
    elseif LC.CityState and LC.CityState() == "unrest" then why = "civil unrest"
    elseif LC.Skirmish ~= nil then why = "fighting in the streets" end
    for _, p in ipairs(player.GetAll()) do
        local lvl = LC.AlertLevel and LC.AlertLevel(p) or 0
        if lvl >= 3 then return "red", "an anticitizen at large" end
        if lvl >= 2 then why = why or "a wanted anticitizen" end
    end
    return why and "yellow" or "green", why
end

function LC.SocioStopMul()
    if not On() then return 1 end
    return (LC.Socio == "red" and 2) or (LC.Socio == "yellow" and 1.5) or 1
end

local function AnnounceSocio(level, by)
    local info = LCCP.Socio[level]
    local custom, subtitle = nil, nil
    local trig = "socio_" .. tostring(level)
    -- one voice for it: Overwatch, or (some of the time) the Administrator in his place (sv_livingcity_announcer.lua)
    local herTurn = LC.AnnounceVoiceFor and LC.AnnounceVoiceFor(trig, true) == "administrator" and LC.CustomAnnounce and LC.CustomAnnounce("administrator", trig, nil, true)
    LC.LastPA = CurTime()
    if not herTurn then
        if LC.PickAnnounceClip then custom, subtitle = LC.PickAnnounceClip("overwatch", trig, true) end -- (sv_livingcity_announcer.lua)
        if LC.OverwatchSpeaks then LC.OverwatchSpeaks(custom or SOCIO_VOICE[level]) end
        net.Start("lc_announce")
        net.WriteString(custom or SOCIO_VOICE[level])
        net.WriteString(info.long)
        net.WriteFloat(LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(custom or SOCIO_VOICE[level]) or 0)
        net.Broadcast()
    end
    if subtitle then for _, p in ipairs(player.GetAll()) do p:ChatPrint("[Overwatch] \"" .. subtitle .. "\"") end end
    for _, p in ipairs(player.GetAll()) do
        local unit = LC.PlayerIsCP(p)
        p:ChatPrint(string.format("[Overwatch] Sociostability: %s.%s", info.name, by and (" (" .. by .. ")") or ""))
        p:ChatPrint("  > " .. SOCIO_MEANS[level][unit and 2 or 1])
    end
end

function LC.RefreshSocio(quiet, force)
    local o = LC.SocioOverride
    if o and o.untilT <= CurTime() then LC.SocioOverride, o = nil, nil end
    local auto, why = LC.SocioAuto()
    local level = (o and o.level) or auto
    SetGlobal2String("lc_socio", level)
    if level ~= LC.Socio or force then
        local old = LC.Socio or "green"
        LC.Socio = level
        if not quiet then AnnounceSocio(level, (o and o.by) or why) end
        LC.Log("info", "Sociostability: " .. old .. " -> " .. level)
        hook.Run("LivingCitySocioChanged", level, old)
    end
    return level
end

function LC.SetSocio(ply, level, minutes)
    if IsValid(ply) and not LC.IsAdministrator(ply) then return false, "Only the Administrator sets sociostability." end
    level = string.lower(tostring(level or ""))
    if level == "auto" then
        LC.SocioOverride = nil
        LC.RefreshSocio()
        return true, "Sociostability is back to what the city makes it."
    end
    if not LCCP.Socio[level] then return false, "Pick green, yellow, red, or auto (the city decides)." end
    -- (announced to the whole city each time: not more than once every half minute)
    if IsValid(ply) and not ply:IsAdmin() and (ply.lcSocioNext or 0) > CurTime() then
        return false, string.format("You only just set it. Wait %d seconds.", math.ceil(ply.lcSocioNext - CurTime()))
    end
    if IsValid(ply) then ply.lcSocioNext = CurTime() + 30 end
    minutes = math.Clamp(math.floor(tonumber(minutes) or 10), 1, 120)
    LC.SocioOverride = { level = level, untilT = CurTime() + minutes * 60, by = IsValid(ply) and Callsign(ply) or "Overwatch" }
    LC.RefreshSocio(false, true) -- announced even if it was already this
    return true, string.format("Sociostability set to %s for %d minutes.", LCCP.Socio[level].name, minutes)
end

hook.Add("LivingCityOutbreak", "LivingCitySocio", function() LC.LastOutbreak = CurTime() end)
timer.Create("LivingCitySocio", 5, 0, function() if On() then LC.RefreshSocio() end end)
hook.Add("InitPostEntity", "LivingCitySocio", function() LC.RefreshSocio(true) end)

------------------------------------------------------------------------
-- Requests
------------------------------------------------------------------------

LC.Requests = LC.Requests or {}

function LC.CPRequest(ply, text)
    if not On() then return false, "Requests are off on this server." end
    text = string.Trim(tostring(text or ""))
    if RealUnit(ply) then return false, "You're a Civil Protection unit. Use the radio, or !backup." end
    if not (LC.HasItem and LC.HasItem(ply, "request_device")) then return false, "You need a Civil Protection call box (the Union Commissary sells them)." end
    if #text < 3 then return false, "Say what's wrong: /request <what's wrong>" end
    if LC.Jammed and LC.Jammed(ply:GetPos()) then return false, "The call box crackles. Nothing gets through: something nearby is jamming it." end
    local now = CurTime()
    if (ply.lcRequestNext or 0) > now then
        return false, string.format("The device is still recharging (%ds).", math.ceil(ply.lcRequestNext - now))
    end
    ply.lcRequestNext = now + cvReqWait:GetFloat()
    text = string.sub(text, 1, 120)
    local pos = ply:GetPos()
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    local q = { name = NameOf(ply), cid = CIDOf(ply), key = LC.RecordKey(ply), text = text, where = where, t = os.time() }
    table.insert(LC.Requests, 1, q)
    while #LC.Requests > 20 do table.remove(LC.Requests) end
    local units = Units()
    if #units > 0 then
        LC.SendCompressed("lc_cpmark", { name = "REQUEST: " .. q.name, x = pos.x, y = pos.y, z = pos.z, secs = 120 }, units)
        TellUnits(string.format("[Request] %s (%s), %s: \"%s\"", q.name, q.cid, where, text))
    end
    -- nobody on duty: the nearest unit on the street walks over
    local sent = false
    if #units == 0 then
        local best, bd
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and LC.IsSecurity(st) and not st.questLock and not st.raid and not st.skirmish
                and st.state ~= "hostile" and st.state ~= "escort" and st.state ~= "event" and not st.workEscort then
                local d = npc:GetPos():DistToSqr(pos)
                if d < 4000 * 4000 and (not bd or d < bd) then best, bd = npc, d end
            end
        end
        if best and LC.GoTo then
            local st = LC.NPCs[best]
            if LC.AbandonTask then LC.AbandonTask(best, st, now) end
            sent = LC.GoTo(best, st, pos, false, nil) and true or false
        end
    end
    ply:EmitSound("buttons/combine_button1.wav", 55)
    ply:ChatPrint(#units > 0 and "[Request] Sent. Civil Protection has your location."
        or (sent and "[Request] Sent. A Civil Protection unit is on the way." or "[Request] Sent. Nobody answers."))
    LC.Log("info", string.format("request from %s: %s", ply:Nick(), text))
    hook.Run("LivingCityRequest", ply, q)
    return true
end

------------------------------------------------------------------------
-- Voice lines
------------------------------------------------------------------------

local function Squash(s) return (string.gsub(string.lower(s or ""), "[^%w]", "")) end

local function CanUseVoice(ply)
    return LC.PlayerIsCP(ply) or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
end

local function VoiceList(ply)
    return LCCP.VoiceFor(ply)
end

local function FindLine(ply, word)
    local list = VoiceList(ply)
    local n = tonumber(word)
    if n and list[n] then return list[n] end
    local w = Squash(word)
    for _, l in ipairs(list) do if Squash(l[1]) == w then return l end end
    for _, l in ipairs(list) do if Squash(l[2]) == w then return l end end
    return nil
end

local function PlayLine(ply, line, loud)
    ply:EmitSound(line[3], loud and 90 or 80, 100)
end

-- Play a line and say it. word: the line's short word, its number, or its words.
function LC.CPVoice(ply, word)
    if not On() then return false end
    if not CanUseVoice(ply) then return false, "Only Civil Protection units have the mask's voice." end
    if not ply:Alive() or LC.IsTied(ply) then return false end
    local line = FindLine(ply, word)
    if not line then return false, "No such line. !vo opens the list." end
    if (ply.lcVoiceNext or 0) > CurTime() then return false end
    ply.lcVoiceNext = CurTime() + 1.2
    PlayLine(ply, line)
    if LC.Speak and LC.ICChatActive and LC.ICChatActive() then
        LC.Speak(ply, "say", line[2])
    else
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():DistToSqr(ply:GetPos()) < 600 * 600 then p:ChatPrint(Callsign(ply) .. ": " .. line[2]) end
        end
    end
    return true
end

-- Said out loud in chat, word for word: the mask says it too.
function LC.VoiceForText(ply, text, kind)
    if not On() or not CanUseVoice(ply) then return false end
    local w = Squash(text)
    if w == "" then return false end
    for _, l in ipairs(VoiceList(ply)) do
        if Squash(l[2]) == w then
            if (ply.lcVoiceNext or 0) > CurTime() then return false end
            ply.lcVoiceNext = CurTime() + 1.2
            PlayLine(ply, l, kind == "yell")
            return true
        end
    end
    return false
end

concommand.Add("lc_vo", function(ply, _, args)
    if not IsValid(ply) then return end
    local ok, why = LC.CPVoice(ply, table.concat(args or {}, " "))
    if not ok and why then ply:ChatPrint(why) end
end)

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

local function Reply(ply, ok, why) if why and why ~= "" then ply:ChatPrint(why) end end

local COMMANDS = {
    records = function(ply) OpenRecords(ply) end,
    tie = function(ply) Reply(ply, LC.StartTie(ply)) end,
    untie = function(ply) Reply(ply, LC.StartUntie(ply)) end,
    cuff = function(ply) Reply(ply, LC.StartTie(ply)) end, -- (the same as !tie and !untie: they're cuffs now)
    uncuff = function(ply) Reply(ply, LC.StartUntie(ply)) end,
    struggle = function(ply) Reply(ply, LC.StartStruggle(ply)) end,
    handsup = function(ply) LC.SetHandsUp(ply) end,
    request = function(ply, rest) local ok, why = LC.CPRequest(ply, rest) if not ok then ply:ChatPrint(why) end end,
    vo = function(ply, rest)
        if string.Trim(rest or "") == "" then
            if not CanUseVoice(ply) then return ply:ChatPrint("Only Civil Protection units have the mask's voice.") end
            net.Start("lc_vo_menu") net.Send(ply)
            return
        end
        local ok, why = LC.CPVoice(ply, rest)
        if not ok and why then ply:ChatPrint(why) end
    end,
    socio = function(ply, rest)
        local level, mins = string.match(string.lower(rest or ""), "^(%a+)%s*(%d*)")
        if not level then
            local info = LCCP.Socio[LC.Socio or "green"]
            local o = LC.SocioOverride
            ply:ChatPrint(string.format("[Overwatch] Sociostability: %s%s", info.name,
                o and string.format(" (set by %s, %d min left)", o.by, math.ceil((o.untilT - CurTime()) / 60)) or ""))
            return
        end
        local ok, msg = LC.SetSocio(ply, level, tonumber(mins))
        ply:ChatPrint(msg)
    end,
    bolo = function(ply, rest)
        if string.Trim(rest or "") == "" then return OpenRecords(ply) end
        local ok, b = LC.AddBOLO(ply, nil, rest)
        if not ok then ply:ChatPrint(b) end
    end,
}
COMMANDS.hu = COMMANDS.handsup
COMMANDS.ziptie = COMMANDS.tie
COMMANDS.cut = COMMANDS.untie
for name, fn in pairs(COMMANDS) do LC.SlashCommands[name] = fn end

hook.Add("PlayerSay", "LivingCityCPChat", function(ply, text)
    local raw = string.Trim(text or "")
    local lead = string.sub(raw, 1, 1)
    if lead ~= "!" and lead ~= "/" then return end
    -- slash commands go through in-character chat when it's on
    if lead == "/" and LC.ICChatActive and LC.ICChatActive() then return end
    local cmd, rest = string.match(raw, "^[!/](%S+)%s*(.*)$")
    local fn = cmd and COMMANDS[string.lower(cmd)]
    if not fn then return end
    fn(ply, rest or "")
    return ""
end)

concommand.Add("lc_tie", function(ply) if IsValid(ply) then Reply(ply, LC.StartTie(ply)) end end)
concommand.Add("lc_handsup", function(ply) if IsValid(ply) then LC.SetHandsUp(ply) end end)

------------------------------------------------------------------------
-- Duty allocation: units don't queue with the citizens. Every allocation
-- period (lc_ration_interval) a unit on duty is issued a ration packet and
-- their ration coupons as credits (lc_cp_coupons, plus one per rank). It
-- shares the dispenser's allocation, so a unit can still take theirs from a
-- dispenser instead, just not both. Overwatch don't eat: coupons only.
------------------------------------------------------------------------

local cvCoupons = CreateConVar("lc_cp_coupons", "8", FLAGS, "Credits in ration coupons a Civil Protection unit is issued each allocation (plus one per rank)")

function LC.IssueDutyAllocation(ply)
    if not On() or not RealUnit(ply) or not ply:Alive() then return false end
    if LC.InCustody and LC.InCustody(ply) then return false end
    local now = CurTime()
    if now < (ply.lcnRationAt or 0) then return false end
    local rv = GetConVar("lc_ration_interval")
    ply.lcnRationAt = now + (rv and rv:GetFloat() or 600)
    local credits = math.max(0, cvCoupons:GetInt()) + math.max(0, Rank(ply) - 1)
    local eats = not LCF.IsOverwatch(ply) -- (the Overwatch are fed through the suit)
    local got = {}
    if eats and LC.GiveItem then
        if LC.GiveItem(ply, "ration", 1) then got[#got + 1] = "a ration packet" else got[#got + 1] = "a ration packet (your pockets are full: collect it from a dispenser)" ply.lcnRationAt = now end
    end
    if credits > 0 and LC.AddCredits then LC.AddCredits(ply, credits) got[#got + 1] = credits .. " credits in ration coupons" end
    if #got > 0 then ply:ChatPrint("[Civil Protection] Duty allocation issued: " .. table.concat(got, " and ") .. ".") end
    return true
end

timer.Create("LivingCityDutyAllocation", 20, 0, function()
    if not On() or not LC.Running then return end
    for _, p in ipairs(player.GetAll()) do
        -- a little while into the shift, not the moment you put the uniform on
        if RealUnit(p) then
            p.lcDutySince = p.lcDutySince or CurTime()
            if CurTime() - p.lcDutySince > 60 then LC.IssueDutyAllocation(p) end
        else
            p.lcDutySince = nil
        end
    end
end)
