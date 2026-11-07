--[[
    Living City: staff tools

      Logs          Everything worth knowing, kept for staff: chat (in and out of
                    character), kills and who did them, arrests, wanted, warnings,
                    tickets, staff actions, connections. The last 2000 lines in the
                    staff panel; every line also goes to
                    garrysmod/data/livingcity/logs/<date>.txt.

      Tickets       Players ask for help: @ <message>, or !ticket <message>. Staff
                    online hear it; the staff panel lists them to claim, answer,
                    go to, bring, and close. Another @ adds to your open ticket.

      Warnings      !warn <name> <reason>. The player sees it across their screen;
                    it's kept (garrysmod/data/livingcity/warnings.json) and shown
                    in the staff panel, where it can be struck off.

      Character     !charban <name> <reason>: that person (not the player) is gone
      bans          for good: the character is wiped like a death, and nobody can
                    take their name again. Lifted from the staff panel.

      !staff opens the panel (admins).
]]

if CLIENT then return end

util.AddNetworkString("lc_staff")
util.AddNetworkString("lc_staff_do")
util.AddNetworkString("lc_warned")

LC = LC or {}

local DIR = "livingcity"
local WARN_FILE = DIR .. "/warnings.json"
local BAN_FILE = DIR .. "/charbans.json"
local MAX_LOG = 2000

local function IsStaff(ply) return not IsValid(ply) or ply:IsAdmin() end
local function CharName(ply) return LC.CharacterName and LC.CharacterName(ply) or ply:Nick() end
local function Who(ply) return IsValid(ply) and string.format("%s (%s)", ply:Nick(), CharName(ply)) or "console" end

------------------------------------------------------------------------
-- Logs
------------------------------------------------------------------------

LC.StaffLog = LC.StaffLog or {}

function LC.StaffLogAdd(kind, text, ply)
    local e = { t = os.time(), kind = kind, text = tostring(text), sid = IsValid(ply) and ply:SteamID() or nil }
    local log = LC.StaffLog
    log[#log + 1] = e
    if #log > MAX_LOG then table.remove(log, 1) end
    local ok, day = pcall(os.date, "%Y-%m-%d", e.t)
    local ok2, clock = pcall(os.date, "%H:%M:%S", e.t)
    -- written to the day's file a few times a minute, not once a line (a flood of chat is a flood of disk writes)
    local f = DIR .. "/logs/" .. (ok and day or "log") .. ".txt"
    LC.StaffLogPending = LC.StaffLogPending or {}
    local pend = LC.StaffLogPending
    pend[f] = (pend[f] or "") .. string.format("[%s] %-8s %s\n", ok2 and clock or "", kind, string.sub(e.text, 1, 600))
end
function LC.StaffLogFlush()
    local pend = LC.StaffLogPending
    if not pend or next(pend) == nil then return end
    LC.StaffLogPending = {}
    file.CreateDir(DIR .. "/logs")
    for f, text in pairs(pend) do file.Append(f, text) end
end
timer.Create("LivingCityStaffLogFlush", 5, 0, function() LC.StaffLogFlush() end)
hook.Add("ShutDown", "LivingCityStaffLogFlush", function() LC.StaffLogFlush() end)

-- Everything the game already logs comes here too.
local baseLog = LC.Log
if baseLog and not LC.StaffLogWrapped then
    LC.StaffLogWrapped = true
    LC.Log = function(level, msg)
        baseLog(level, msg)
        local kind = level == "chat" and "chat" or (level == "error" and "error" or "system")
        local s = tostring(msg)
        if string.find(s, "^admin tools") or string.find(s, "^broadcast") then kind = "admin" end
        LC.StaffLogAdd(kind, s)
    end
end

hook.Add("PlayerSay", "LivingCityStaffLog", function(ply, text)
    -- commands and out-of-character chat (in-character speech is logged where it's spoken)
    local first = string.sub(text or "", 1, 1)
    if first == "!" or first == "/" or first == "@" or not (LC.ICChatActive and LC.ICChatActive()) then
        LC.StaffLogAdd("chat", Who(ply) .. ": " .. text, ply)
    end
end)
hook.Add("PlayerInitialSpawn", "LivingCityStaffLog", function(ply) LC.StaffLogAdd("connect", ply:Nick() .. " (" .. ply:SteamID() .. ") joined", ply) end)
hook.Add("PlayerDisconnected", "LivingCityStaffLog", function(ply) LC.StaffLogAdd("connect", ply:Nick() .. " (" .. ply:SteamID() .. ") left", ply) end)
hook.Add("PlayerDeath", "LivingCityStaffLog", function(victim, inflictor, attacker)
    local how = IsValid(inflictor) and inflictor.GetClass and inflictor:GetClass() or "?"
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local w = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
        how = IsValid(w) and w:GetClass() or how
        LC.StaffLogAdd("kill", Who(attacker) .. " killed " .. Who(victim) .. " with " .. how, attacker)
    else
        LC.StaffLogAdd("kill", Who(victim) .. " died (" .. (IsValid(attacker) and attacker.GetClass and attacker:GetClass() or how) .. ")", victim)
    end
end)
hook.Add("LivingCityIncarcerated", "LivingCityStaffLog", function(ply, secs, reason, arrester)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    LC.StaffLogAdd("arrest", Who(ply) .. " jailed " .. math.floor(tonumber(secs) or 0) .. "s: " .. tostring(reason or "")
        .. (IsValid(arrester) and arrester:IsPlayer() and (" by " .. Who(arrester)) or ""), ply)
end)
hook.Add("LivingCityWanted", "LivingCityStaffLog", function(ply, reason)
    if IsValid(ply) and ply:IsPlayer() then LC.StaffLogAdd("arrest", Who(ply) .. " wanted: " .. tostring(reason or ""), ply) end
end)
hook.Add("LivingCityStrike", "LivingCityStaffLog", function(ply, n, reason)
    if IsValid(ply) then LC.StaffLogAdd("warning", Who(ply) .. " conduct strike " .. tostring(n) .. ": " .. tostring(reason or ""), ply) end
end)

------------------------------------------------------------------------
-- Tickets
------------------------------------------------------------------------

LC.Tickets = LC.Tickets or {}
local ticketSerial = 0

local function Staff()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if p:IsAdmin() then out[#out + 1] = p end end
    return out
end

local function OpenCount()
    local n = 0
    for _, t in ipairs(LC.Tickets) do if t.status ~= "closed" then n = n + 1 end end
    SetGlobal2Float("lc_tickets_open", n)
    return n
end

function LC.OpenTicket(ply, text)
    text = string.Trim(tostring(text or ""))
    if #text < 2 then return false, "Say what you need: @ <message>" end
    if not ply:IsAdmin() and (ply.lcTicketNext or 0) > CurTime() then return false, "Give staff a moment to read that before you add more." end
    ply.lcTicketNext = CurTime() + 3
    text = string.sub(text, 1, 300)
    for _, t in ipairs(LC.Tickets) do
        if t.sid == ply:SteamID() and t.status ~= "closed" then
            if #t.msgs >= 30 then return false, "Your ticket is already long. Staff will read it: wait for an answer." end
            t.msgs[#t.msgs + 1] = { from = ply:Nick(), text = text, t = os.time() }
            for _, s in ipairs(Staff()) do s:ChatPrint(string.format("[Ticket #%d] %s adds: %s", t.id, ply:Nick(), text)) end
            LC.StaffLogAdd("ticket", "#" .. t.id .. " " .. Who(ply) .. ": " .. text, ply)
            return true, "Added to your ticket. Staff will be with you."
        end
    end
    ticketSerial = ticketSerial + 1
    local t = { id = ticketSerial, sid = ply:SteamID(), name = ply:Nick(), char = CharName(ply), status = "open",
        msgs = { { from = ply:Nick(), text = text, t = os.time() } }, t = os.time() }
    table.insert(LC.Tickets, t)
    while #LC.Tickets > 60 do table.remove(LC.Tickets, 1) end
    OpenCount()
    local staff = Staff()
    for _, s in ipairs(staff) do
        s:ChatPrint(string.format("[Ticket #%d] %s: %s  (C > Help > Staff panel to answer)", t.id, ply:Nick(), text))
        s:EmitSound("buttons/blip1.wav", 50)
    end
    LC.StaffLogAdd("ticket", "#" .. t.id .. " opened by " .. Who(ply) .. ": " .. text, ply)
    return true, #staff > 0 and "Your ticket is in. Staff will be with you." or "Your ticket is in. No staff are on right now; it'll wait."
end

local function TicketById(id) for _, t in ipairs(LC.Tickets) do if t.id == id then return t end end end
local function TicketPlayer(t) for _, p in ipairs(player.GetAll()) do if p:SteamID() == t.sid then return p end end end

function LC.TicketAction(admin, id, action, text)
    if not IsStaff(admin) then return false end
    local t = TicketById(tonumber(id))
    if not t then return false, "No such ticket." end
    local p = TicketPlayer(t)
    local me = IsValid(admin) and admin:Nick() or "Staff"
    if action == "claim" then
        t.status, t.claimedBy = "claimed", me
        if IsValid(p) then p:ChatPrint("[Staff] " .. me .. " is looking at your ticket.") end
    elseif action == "reply" then
        text = string.Trim(tostring(text or ""))
        if text == "" then return false end
        t.msgs[#t.msgs + 1] = { from = me, text = text, t = os.time(), staff = true }
        if IsValid(p) then p:ChatPrint("[Staff] " .. me .. ": " .. text) end
    elseif action == "close" then
        t.status = "closed"
        if IsValid(p) then p:ChatPrint("[Staff] Your ticket was closed by " .. me .. ".") end
    elseif action == "goto" then
        if not IsValid(p) or not IsValid(admin) then return false, "They're not on." end
        admin:SetPos(p:GetPos() + p:GetForward() * 60 + Vector(0, 0, 4))
    elseif action == "bring" then
        if not IsValid(p) or not IsValid(admin) then return false, "They're not on." end
        p:SetPos(admin:GetPos() + admin:GetForward() * 60 + Vector(0, 0, 4))
    else
        return false
    end
    OpenCount()
    LC.StaffLogAdd("ticket", string.format("#%d %s by %s%s", t.id, action, me, text and text ~= "" and (": " .. text) or ""), admin)
    return true
end

------------------------------------------------------------------------
-- Warnings
------------------------------------------------------------------------

local warnings
local function Warnings()
    if not warnings then
        warnings = LC.SafeReadJSON(WARN_FILE) or {}
    end
    return warnings
end
local function SaveWarnings() LC.SafeWrite(WARN_FILE, util.TableToJSON(Warnings())) end

function LC.WarnPlayer(admin, target, reason)
    if not IsStaff(admin) then return false, "Staff only." end
    if not IsValid(target) then return false, "Player not found." end
    reason = string.Trim(tostring(reason or ""))
    if reason == "" then return false, "Give a reason: !warn <name> <reason>" end
    local key = target:SteamID()
    local all = Warnings()
    all[key] = all[key] or { name = target:Nick(), list = {} }
    all[key].name = target:Nick()
    table.insert(all[key].list, { t = os.time(), reason = reason, by = IsValid(admin) and admin:Nick() or "console" })
    SaveWarnings()
    net.Start("lc_warned")
    net.WriteString(reason)
    net.WriteString(IsValid(admin) and admin:Nick() or "Staff")
    net.WriteUInt(#all[key].list, 8)
    net.Send(target)
    target:ChatPrint(string.format("[Staff] You have been warned: %s (warning %d)", reason, #all[key].list))
    LC.StaffLogAdd("warning", Who(target) .. " warned by " .. (IsValid(admin) and admin:Nick() or "console") .. ": " .. reason, target)
    return true, target:Nick() .. " warned (" .. #all[key].list .. " in total)."
end

function LC.WarningsOf(sid) local w = Warnings()[sid] return w and w.list or {} end

function LC.Unwarn(admin, sid, idx)
    if not IsStaff(admin) then return false end
    local w = Warnings()[sid]
    if not w or not w.list[idx] then return false, "No such warning." end
    table.remove(w.list, idx)
    SaveWarnings()
    LC.StaffLogAdd("warning", "warning " .. idx .. " struck off " .. (w.name or sid) .. " by " .. (IsValid(admin) and admin:Nick() or "console"))
    return true, "Struck off."
end

------------------------------------------------------------------------
-- Character bans
------------------------------------------------------------------------

local bans
local function Bans()
    if not bans then
        bans = LC.SafeReadJSON(BAN_FILE) or {}
    end
    return bans
end
local function SaveBans() LC.SafeWrite(BAN_FILE, util.TableToJSON(Bans())) end

-- Is this name (a character's) banned?
function LC.CharBanned(name)
    local low = string.lower(string.Trim(tostring(name or "")))
    for _, b in ipairs(Bans()) do if string.lower(b.name or "") == low then return b end end
    return nil
end

function LC.CharBan(admin, target, reason)
    if not IsStaff(admin) then return false, "Staff only." end
    if not IsValid(target) then return false, "Player not found." end
    reason = string.Trim(tostring(reason or ""))
    if reason == "" then return false, "Give a reason: !charban <name> <reason>" end
    local name, cid = CharName(target), target:GetNW2String("lc_cid", "")
    table.insert(Bans(), { name = name, cid = cid, sid = target:SteamID(), player = target:Nick(), reason = reason,
        by = IsValid(admin) and admin:Nick() or "console", t = os.time() })
    SaveBans()
    if LC.NewCharacter then
        target.lcNoPermadeath = true
        LC.NewCharacter(target, "charban")
        target.lcNoPermadeath = nil
        if target:Alive() then target:Spawn() end
    end
    target:ChatPrint(string.format("[Staff] %s is gone, by staff decision: %s. You're someone new.", name, reason))
    LC.StaffLogAdd("charban", name .. " (" .. cid .. ", " .. Who(target) .. ") banned by " .. (IsValid(admin) and admin:Nick() or "console") .. ": " .. reason, target)
    return true, name .. " is banned. " .. target:Nick() .. " starts over as someone new."
end

function LC.CharUnban(admin, idx)
    if not IsStaff(admin) then return false end
    local b = Bans()[idx]
    if not b then return false, "No such ban." end
    table.remove(Bans(), idx)
    SaveBans()
    LC.StaffLogAdd("charban", "ban on " .. (b.name or "?") .. " lifted by " .. (IsValid(admin) and admin:Nick() or "console"))
    return true, "The ban on " .. (b.name or "them") .. " is lifted."
end

------------------------------------------------------------------------
-- The staff panel
------------------------------------------------------------------------

function LC.SendStaff(admin)
    if not IsValid(admin) or not admin:IsAdmin() then return false end
    local players = {}
    for _, p in ipairs(player.GetAll()) do
        players[#players + 1] = { sid = p:SteamID(), name = p:Nick(), char = CharName(p), cid = p:GetNW2String("lc_cid", ""),
            faction = p:GetNW2String("lcf_title", ""), warnings = #LC.WarningsOf(p:SteamID()) }
    end
    local warns = {}
    for sid, w in pairs(Warnings()) do
        for i, x in ipairs(w.list or {}) do warns[#warns + 1] = { sid = sid, name = w.name, idx = i, t = x.t, reason = x.reason, by = x.by } end
    end
    table.sort(warns, function(a, b) return (a.t or 0) > (b.t or 0) end)
    while #warns > 200 do table.remove(warns) end
    local logs = {}
    local from = math.max(1, #LC.StaffLog - 1499)
    for i = from, #LC.StaffLog do logs[#logs + 1] = LC.StaffLog[i] end
    LC.SendCompressed("lc_staff", { tickets = LC.Tickets, players = players, warnings = warns, bans = Bans(), logs = logs }, admin)
    return true
end

local function FindBySid(sid) for _, p in ipairs(player.GetAll()) do if p:SteamID() == sid then return p end end end

net.Receive("lc_staff_do", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local action, a, b = net.ReadString(), net.ReadString(), net.ReadString()
    local ok, msg
    if action == "ticket" then
        local id, what = string.match(a, "^(%d+)|(%a+)$")
        ok, msg = LC.TicketAction(ply, id, what, b)
    elseif action == "warn" then ok, msg = LC.WarnPlayer(ply, FindBySid(a), b)
    elseif action == "unwarn" then ok, msg = LC.Unwarn(ply, a, tonumber(b))
    elseif action == "charban" then ok, msg = LC.CharBan(ply, FindBySid(a), b)
    elseif action == "unban" then ok, msg = LC.CharUnban(ply, tonumber(a))
    elseif action == "goto" or action == "bring" then
        local p = FindBySid(a)
        if IsValid(p) then
            if action == "goto" then ply:SetPos(p:GetPos() + p:GetForward() * 60 + Vector(0, 0, 4))
            else p:SetPos(ply:GetPos() + ply:GetForward() * 60 + Vector(0, 0, 4)) end
            LC.StaffLogAdd("admin", ply:Nick() .. " " .. action .. " " .. p:Nick(), ply)
        end
    end
    if msg then ply:ChatPrint("[Staff] " .. msg) end
    LC.SendStaff(ply)
end)

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

hook.Add("PlayerSay", "LivingCityStaffChat", function(ply, text)
    local raw = string.Trim(text or "")
    local ticketText = string.match(raw, "^@%s*(.+)$") or string.match(raw, "^[!/]ticket%s+(.+)$")
    if ticketText then
        local ok, msg = LC.OpenTicket(ply, ticketText)
        ply:ChatPrint("[Tickets] " .. msg)
        return ""
    end
    local cmd, rest = string.match(raw, "^!(%a+)%s*(.*)$")
    cmd = cmd and string.lower(cmd)
    if cmd == "staff" or cmd == "tickets" or cmd == "logs" then
        if not LC.SendStaff(ply) then ply:ChatPrint("Staff only. Need help? @ <message>") end
        return ""
    end
    if cmd == "warn" or cmd == "charban" then
        if not ply:IsAdmin() then ply:ChatPrint("Staff only.") return "" end
        local name, reason = string.match(rest or "", "^(%S+)%s*(.*)$")
        local target = name and LC.FindPlayer and LC.FindPlayer(name)
        local ok, msg
        if cmd == "warn" then ok, msg = LC.WarnPlayer(ply, target, reason) else ok, msg = LC.CharBan(ply, target, reason) end
        ply:ChatPrint("[Staff] " .. tostring(msg))
        return ""
    end
end)

concommand.Add("lc_staff", function(ply) if IsValid(ply) and not LC.SendStaff(ply) then ply:ChatPrint("Staff only.") end end)
