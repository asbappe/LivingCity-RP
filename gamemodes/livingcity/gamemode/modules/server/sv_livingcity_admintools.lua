--[[
    Living City: testing tools for admins

    Give yourself (or anyone) XP, a rank, credits and Civil Standing, switch
    faction without the usual requirements, and wipe it all back to nothing,
    so every rank and role can be tried out without grinding for it.

      !admintools (or !testing, or the button on the F4 screen) opens the panel.

      Chat, for admins. Each acts on you, or on a player named at the end:
        !givexp <n> [name]         XP in your current faction (negative takes it away)
        !setrank <n> [name]        rank by number: 1 is the bottom
        !givecredits <n> [name]
        !givestanding <n> [name]
        !resetxp [name]            XP in every faction back to 0
        !resetcredits [name]       credits to 0
        !resetme                   XP, credits and standing all back to 0
]]

if CLIENT then return end

util.AddNetworkString("lc_admintools")
util.AddNetworkString("lc_admintools_do")

LC = LC or {}

local function FactionOf(ply) return LCF and LCF.Get and LCF.Get(ply:GetNW2String("lcf_faction", "")) or nil end
local function XP(ply, fid) return tonumber(ply:GetPData("lcf_xp_" .. fid, 0)) or 0 end
-- (the Resistance's trust goes with a Fighter's XP or more when staff give it: the owner, 14 November, set to
-- Lieutenant and still a Member. LC.StaffTrust, sv_livingcity_factions.lua)
local function Recompute(ply, why)
    if why and LC.StaffTrust then LC.StaffTrust(ply) end
    if LC.AddXP then LC.AddXP(ply, 0, why) end
end
-- The rank they hold now, by name (what the admin is told: never a rank the player did not get).
local function RankName(ply, f) local r = f.ranks[ply:GetNW2Int("lcf_rank", 1)] return r and r.name or "?" end

local function ResetAllXP(ply)
    for _, f in ipairs(LCF and LCF.Factions or {}) do ply:SetPData("lcf_xp_" .. f.id, 0) end
    Recompute(ply)
end

local function SetCredits(ply, v)
    if not LC.Credits or not LC.AddCredits then return end
    local d = math.max(0, v) - LC.Credits(ply)
    if d ~= 0 then LC.AddCredits(ply, d) end
end

local function SetStanding(ply, v)
    if not LC.Standing or not LC.AddStanding then return end
    local d = math.Clamp(v, -1000, 1000) - LC.Standing(ply)
    if d ~= 0 then LC.AddStanding(ply, d) end
end

-- Everything the panel can do. Returns ok, and a line to tell the admin.
local ACTIONS = {
    refresh = function() return true, nil end,
    xp = function(t, v)
        local f = FactionOf(t)
        if not f or #f.ranks < 2 then return false, "That faction has no ranks to climb." end
        local n = math.floor(tonumber(v) or 0)
        t:SetPData("lcf_xp_" .. f.id, math.max(0, XP(t, f.id) + n))
        Recompute(t, "by staff")
        return true, string.format("%s: %d XP in %s (%s).", t:Nick(), XP(t, f.id), f.name, RankName(t, f))
    end,
    rank = function(t, v)
        local f = FactionOf(t)
        local i = math.floor(tonumber(v) or 0)
        if not f or #f.ranks < 2 then return false, "That faction has no ranks." end
        if i < 1 or i > #f.ranks then return false, string.format("%s ranks go from 1 to %d.", f.name, #f.ranks) end
        if f.ranks[i].overwatch then t:SetPData("lcf_transhuman", "1") end -- (staff skip the Overwatch Candidate story)
        t:SetPData("lcf_xp_" .. f.id, f.ranks[i].xp or 0)
        Recompute(t, "by staff")
        return true, string.format("%s is now %s (%d XP).", t:Nick(), RankName(t, f), f.ranks[i].xp or 0)
    end,
    resetxp = function(t)
        ResetAllXP(t)
        return true, t:Nick() .. ": XP back to 0 in every faction."
    end,
    credits = function(t, v)
        if not LC.Credits then return false, "The economy is off." end
        SetCredits(t, LC.Credits(t) + math.floor(tonumber(v) or 0))
        return true, string.format("%s: %d credits.", t:Nick(), LC.Credits(t))
    end,
    resetcredits = function(t)
        SetCredits(t, 0)
        return true, t:Nick() .. ": credits back to 0."
    end,
    standing = function(t, v)
        if not LC.Standing then return false, "The economy is off." end
        SetStanding(t, LC.Standing(t) + math.floor(tonumber(v) or 0))
        return true, string.format("%s: Civil Standing %d.", t:Nick(), LC.Standing(t))
    end,
    setstanding = function(t, v)
        if not LC.Standing then return false, "The economy is off." end
        SetStanding(t, math.floor(tonumber(v) or 0))
        return true, string.format("%s: Civil Standing %d.", t:Nick(), LC.Standing(t))
    end,
    resetme = function(t)
        ResetAllXP(t)
        SetCredits(t, 0)
        SetStanding(t, 0)
        if LC.RapClear then LC.RapClear(t) end -- (and nothing left on their record for a later sentence)
        return true, t:Nick() .. ": XP, credits and standing all back to 0."
    end,
    faction = function(t, v)
        local f = LCF and LCF.Get and LCF.Get(v or "")
        if not f or not LC.SetFaction then return false, "No such faction." end
        LC.SetFaction(t, f.id)
        return true, t:Nick() .. " is now " .. f.name .. "."
    end,
    clearwanted = function(t)
        if LC.ClearWanted then LC.ClearWanted(t) end
        if LC.CalmCops then LC.CalmCops(t) end
        if LC.SetAlert then LC.Try(LC.SetAlert, t, 0) end
        return true, t:Nick() .. " is no longer wanted."
    end,
    -- out of custody at once: a struggle, the cuffs, a march, a street detention, a cell (sv_livingcity_prison.lua)
    free = function(t)
        if not LC.FreeFromCustody then return false, "No prison here." end
        LC.FreeFromCustody(t)
        return true, t:Nick() .. " is out of custody."
    end,
    pardon = function(t)
        if not LC.PardonStrikes then return false, "No conduct tracking here." end
        LC.PardonStrikes(t)
        return true, t:Nick() .. ": conduct strikes cleared."
    end,
    needs = function(t)
        if LC.Feed then LC.Feed(t, 100, 100) end
        t:SetNW2Float("lcn_parasites", 0)
        t:SetHealth(math.max(t:Health(), t:GetMaxHealth() or 100))
        return true, t:Nick() .. ": fed, watered, healed."
    end,
    -- the city, not the player: a city-wide blackout (sv_livingcity_power.lua)
    blackout = function(_, v)
        if not LC.ForceBlackout then return false, "No power grid here." end
        local on = LC.ForceBlackout(v)
        return true, "City-wide blackout: " .. (on and "ON" or "off") .. (v == "auto" and " (following the grid again)" or " (until you set it back to the grid)") .. "."
    end,
    -- territory: grow rebel ground or the infestation now, for testing (superadmins; sv_livingcity_territory.lua)
    territory = function(_, v, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        if v ~= "rebel" and v ~= "infest" then return false, "Grow which: rebel or infest?" end
        if not LC.TerritoryGrowNow then return false, "Territory doesn't spread on this server." end
        local z, why = LC.TerritoryGrowNow(v)
        local what = v == "rebel" and "Rebel ground" or "The infestation"
        if not z then return false, what .. " couldn't grow: " .. tostring(why) .. "." end
        return true, what .. " grew " .. (z.where or "") .. (z.cells and string.format(", along the path nodes (%d cells, saved as %d rectangles)", z.n or 0, #(z.rects or {})) or ", as a round patch (no path nodes near it)") .. "."
    end,
    -- the city, not the player: burn the confiscated contraband now (sv_livingcity_evidence.lua)
    evidence = function(_, _, admin)
        if not LC.EvidenceBurnNow then return false, "No evidence stock here." end
        local ok, msg = LC.EvidenceBurnNow(admin)
        return ok, msg
    end,
    -- save files that couldn't be read are kept as they are; a superadmin lets the city save over them (sv_livingcity_safefile.lua)
    savefiles = function(_, _, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        if not LC.SafeFileAllow then return false, "Nothing to do." end
        local n = LC.SafeFileAllow()
        if n == 0 then return true, "Every save file reads fine." end
        return true, n .. " save file(s) may be saved over again (each unreadable one is kept as <name>.unreadable.txt when it is)."
    end,
    -- Testing alone (the owner, 18 November: "I am the only player and just need ways to test these things in game
    -- before attempting to bring in other players"): what one player can't set off by themselves (superadmins).
    solo = function(t, v, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        v = tostring(v or "")
        if v == "bot" then
            if #player.GetAll() >= game.MaxPlayers() then return false, "The server is full." end
            RunConsoleCommand("bot")
            return true, "A stand-in player (a bot) joins in a moment: pick it under Acting on to give it a faction or a rank."
        elseif v == "address" or v == "assassin" then
            local note = ""
            if v == "assassin" then
                local f = LCF and LCF.Get and LCF.Get("resistance")
                if not f or not LC.SetFaction then return false, "No Resistance here." end
                if t:GetNW2String("lcf_faction", "") ~= "resistance" then LC.SetFaction(t, "resistance") end
                local r = (LC.AdminPlotMinRank and LC.AdminPlotMinRank()) or 3
                if f.ranks[r] then t:SetPData("lcf_xp_resistance", math.max(tonumber(t:GetPData("lcf_xp_resistance", 0)) or 0, f.ranks[r].xp or 0)) Recompute(t, "by staff") end
                note = " " .. t:Nick() .. " is a " .. RankName(t, f) .. ": take Kill the Administrator from the Resistance's board (F4 > Jobs) while she speaks."
            end
            if not LC.CallSpeech then return false, "No address on this server." end
            if LC.SpeechSession and LC.SpeechSession() then return true, "Her address is already on." .. note end
            local ok, why = LC.CallSpeech(nil, nil)
            if not ok then return false, tostring(why) end
            return true, "The city's own Administrator is called to the stand; she speaks once the city has gathered (lc_speech_muster)." .. note
        elseif v == "endaddress" then
            if not (LC.SpeechSession and LC.SpeechSession()) then return false, "No address is on." end
            LC.EndSpeech()
            return true, "The address is over."
        elseif v == "black" or v == "next" or v == "stand" or v == "mebarney" or v == "mefreeman" or v == "off" then
            if not LC.CollapseTest then return false, "No collapse on this server." end
            LC.CollapseTester = IsValid(admin) and admin or t
            return LC.CollapseTest(v)
        elseif v == "leak" then
            if not LC.DistrictLeak then return false, "No districts here." end
            local best, bv
            for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
                local d = LC.DistrictInfest(n)
                if d > 0 and (not bv or d > bv) then best, bv = n, d end
            end
            if not best then return false, "No district has any infestation (grow some first)." end
            local z, m = LC.DistrictLeak(best)
            if not z then return false, "It couldn't leak: " .. tostring(m) .. "." end
            return true, string.format("The infestation leaked from %s to %s.", LC.BlockName and LC.BlockName(best) or best, LC.BlockName and LC.BlockName(m) or m)
        elseif v == "shell" then
            -- (sv_livingcity_shelling.lua: a district the Resistance hold, else the one you stand in; no waiting for the canisters)
            if not LC.ShellDistrict then return false, "No shelling on this server." end
            local n = (LC.ShellTargets and LC.ShellTargets() or {})[1] or (LC.LedgerBlockAt and IsValid(admin) and LC.LedgerBlockAt(admin:GetPos()))
            if not n then return false, "No district here (place housing blocks in the editor)." end
            local k, landed, covered = LC.ShellDistrict(n, nil)
            if not k then return false, tostring(landed) end
            return true, string.format("Shelling %s: %d canister(s) coming down, %d lot(s) of headcrabs under cover; in about %d seconds.", LC.BlockName and LC.BlockName(n) or n,
                landed, covered, LC.ShellingConst.FLIGHT)
        elseif v == "flush" then
            -- (sv_livingcity_flush.lua: the job on both Combine boards now, whatever the day or the Resistance's strength)
            if not (LC.Flush and LC.Flush.Start) then return false, "No sewer flush on this server." end
            LC.Flush.MapForget()
            local one, why = LC.Flush.Start()
            if not one then return false, tostring(why) end
            return true, "Flush the sewers: on the Combine's boards (F4). Take it as a unit."
        elseif string.sub(v, 1, 6) == "event:" then
            if not LC.Running then return false, "Start the city first." end
            if not (LC.StartEvent and LC.StartEvent(string.sub(v, 7))) then return false, "That event can't start now (another may be on)." end
            return true, "Started: " .. string.sub(v, 7) .. "."
        elseif v == "endevent" then
            if GetGlobal2String("lc_event", "") == "" then return false, "No event is on." end
            LC.EndEvent(false)
            return true, "The event is over."
        end
        return false, "Unknown test."
    end,
    item = function(t, v)
        local it = LCS and LCS.Items and LCS.Items[v or ""]
        if not it or not LC.GiveItem then return false, "No such item." end
        if not LC.GiveItem(t, v, 1) then return false, t:Nick() .. "'s pockets are full." end
        return true, t:Nick() .. ": " .. it.name .. "."
    end,
}
LC.ADMIN_ACTIONS = ACTIONS

function LC.AdminTool(admin, target, action, value)
    if IsValid(admin) and not admin:IsAdmin() then return false, "Admins only." end
    if not IsValid(target) then target = admin end
    if not IsValid(target) or not target:IsPlayer() then return false, "Nobody to do that to." end
    local fn = ACTIONS[action or ""]
    if not fn then return false, "Unknown action." end
    local ok, a, b = LC.Try(fn, target, value, admin)
    if not ok then return false, "That failed: " .. tostring(a) end
    if a and action ~= "refresh" and IsValid(admin) and LC.Log then
        LC.Log("info", string.format("admin tools: %s used %s %s on %s", admin:Nick(), action, tostring(value or ""), target:Nick()))
    end
    return a, b
end

-- What the panel shows.
local function Snapshot(admin, target)
    local t = IsValid(target) and target or admin
    local data = { target = t:SteamID() .. "|" .. t:Nick(), faction = t:GetNW2String("lcf_faction", ""), xp = {},
        credits = LC.Credits and LC.Credits(t) or nil, standing = LC.Standing and LC.Standing(t) or nil, players = {} }
    for _, f in ipairs(LCF and LCF.Factions or {}) do data.xp[f.id] = XP(t, f.id) end
    for _, p in ipairs(player.GetAll()) do data.players[#data.players + 1] = { id = p:SteamID() .. "|" .. p:Nick(), name = p:Nick() } end
    data.evidence = LC.EvidenceStatus and LC.EvidenceStatus() or nil -- (the confiscated contraband: sv_livingcity_evidence.lua)
    -- how the city's territory is doing (superadmins can grow it from the panel)
    if admin:IsSuperAdmin() then
        local sp = LC.SpeechSession and LC.SpeechSession()
        data.solo = { address = sp and true or false, places = (LC.SpeechPlaces and LC.SpeechPlaces()) and true or false,
            event = GetGlobal2String("lc_event", ""), collapse = GetGlobal2String("lc_collapse_stage", "") }
    end
    if admin:IsSuperAdmin() and LC.TerritoryStatus then
        data.superadmin = true
        data.territory = LC.TerritoryStatus()
        for _, l in ipairs(LC.DistrictInfestStatus and LC.DistrictInfestStatus() or {}) do data.territory[#data.territory + 1] = l end -- (how infested each district is)
    end
    if admin:IsSuperAdmin() and LC.SafeFileBlocked then
        local names = {}
        for p in pairs(LC.SafeFileBlocked()) do names[#names + 1] = "data/" .. p end
        table.sort(names)
        if #names > 0 then data.savefiles = names end
    end
    return data
end

local function FindTarget(id)
    if not id or id == "" then return nil end
    local sid, nick = string.match(id, "^(.-)|(.*)$")
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == sid and p:Nick() == nick then return p end
    end
    for _, p in ipairs(player.GetAll()) do if p:Nick() == nick then return p end end
    return nil
end

function LC.OpenAdminTools(admin, target)
    if not IsValid(admin) or not admin:IsAdmin() then return false end
    LC.SendCompressed("lc_admintools", Snapshot(admin, target), admin)
    return true
end

concommand.Add("lc_admintools", function(ply)
    if IsValid(ply) and not LC.OpenAdminTools(ply) then ply:ChatPrint("Admins only.") end
end)

net.Receive("lc_admintools_do", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local action, value, tid = net.ReadString(), net.ReadString(), net.ReadString()
    local target = FindTarget(tid) or ply
    local ok, msg = LC.AdminTool(ply, target, action, value)
    if msg then ply:ChatPrint("[Admin tools] " .. msg) end
    LC.SendCompressed("lc_admintools", Snapshot(ply, target), ply)
end)

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

local CHAT = {
    givexp = { "xp", true }, setrank = { "rank", true }, givecredits = { "credits", true }, givestanding = { "standing", true },
    resetxp = { "resetxp", false }, resetcredits = { "resetcredits", false }, resetme = { "resetme", false },
}

hook.Add("PlayerSay", "LivingCityAdminTools", function(ply, text)
    local t = string.Trim(text or "")
    local cmd, rest = string.match(t, "^!(%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    if cmd == "admintools" or cmd == "testing" then
        if not LC.OpenAdminTools(ply) then ply:ChatPrint("Admins only.") end
        return ""
    end
    local c = CHAT[cmd]
    if not c then return end
    if not ply:IsAdmin() then ply:ChatPrint("Admins only.") return "" end
    local value, name = nil, rest
    if c[2] then
        value, name = string.match(rest, "^(%-?%d+)%s*(.*)$")
        if not value then
            ply:ChatPrint("Usage: !" .. cmd .. " <number> [player]")
            return ""
        end
    end
    local target = ply
    if cmd ~= "resetme" and name and name ~= "" then
        target = LC.FindPlayer and LC.FindPlayer(name)
        if not target then ply:ChatPrint("Player not found: " .. name) return "" end
    end
    local _, msg = LC.AdminTool(ply, target, c[1], value)
    if msg then ply:ChatPrint("[Admin tools] " .. msg) end
    return ""
end)
