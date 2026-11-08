--[[
    Living City (client): the performance debugger's window

    Staff: C > Help > Performance debugger (or lc_perfdebug_menu in the
    console). Start and Stop turn it on and off on the server (and, while the
    window is open, in your own game too, so you can see what costs you
    frames). The figures come every two seconds:

      Summary           what stands out, in plain words; frames, memory, settings
      Hitches           each slow frame, with what ran in it
      Hooks, Timers     the costliest code, by hook and by timer
      Net in, Net out   every message, by count, bytes and time
      Networked values  SetNW / SetNW2 by name: calls, and real changes
      Entities          classes that grew since it started (leaks)
      Players           ping, loss, what the gamemode sends each, their queue
      Who sends         which players send the server the most, their busiest second

    "Server" and "Your game" switch between the two. Copy report puts both
    reports on the clipboard; the server saves its own when it stops.
    lc_perfdebug_print prints them to the console.
]]

LC_CL = LC_CL or {}
local P = LC.PerfDebug

local frame, srv, view = nil, nil, "server"
local lists, summary, hitches, status, startBtn = {}, nil, nil, nil, nil

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Cmd(action, value)
    net.Start("lc_perfdebug_cmd")
    net.WriteString(action)
    net.WriteString(tostring(value or ""))
    net.SendToServer()
end

-- your own game is measured while the server's is on and the window is open
local function FollowServer()
    if not P then return end
    local want = srv and srv.on and IsValid(frame)
    if want and not P.on then P.Start() elseif not want and P.on then P.Stop() end
end

local TABS = {
    { tab = "Hooks", key = "hooks", cols = { { "Hook (event / name)", "k", 260 }, { "% of time", "pct" }, { "Total ms", "ms" }, { "Calls", "n" }, { "Average ms", "avg" }, { "Worst ms", "max" } } },
    { tab = "Timers", key = "timers", cols = { { "Timer (and where it was started)", "k", 260 }, { "% of time", "pct" }, { "Total ms", "ms" }, { "Runs", "n" }, { "Average ms", "avg" }, { "Worst ms", "max" } } },
    { tab = "Net in", key = "recv", cols = { { "Message", "k", 200 }, { "Count", "n" }, { "Bytes", "bytes" }, { "KB/s", "kbs" }, { "Handler ms", "ms" }, { "Worst ms", "max" }, { "Nothing handled it", "unhandled" } } },
    { tab = "Net out", key = "sent", cols = { { "Message", "k", 200 }, { "Sends", "n" }, { "To players", "to" }, { "Bytes", "bytes" }, { "KB/s", "kbs" } } },
    { tab = "Networked values", key = "nw", cols = { { "Value", "k", 240 }, { "Set", "calls" }, { "Changed", "changes" }, { "Changes a second", "cps" } } },
    { tab = "Entities", key = "growth", cols = { { "Class", "k", 240 }, { "At the start", "from" }, { "Now", "to" }, { "Grew by", "diff" } } },
    { tab = "Players", key = "players", server = true, cols = { { "Player", "k", 180 }, { "Ping", "ping" }, { "Packet loss %", "loss" }, { "Gamemode KB/s to them", "kbs" }, { "Bytes waiting to go", "queue" }, { "Loading in", "loading" } } },
    { tab = "Who sends", key = "senders", server = true, cols = { { "Player", "k", 180 }, { "Messages", "n" }, { "Bytes", "bytes" }, { "Busiest second", "peakN" }, { "Bytes in it", "peakBytes" }, { "Mostly", "top" } } },
}

local function Current()
    if view == "client" then return P and P.Snapshot(25) or nil end
    return srv
end

local function SummaryText(snap)
    if not snap then return "No figures yet." end
    local L = {}
    if snap.side == "server" then
        L[#L + 1] = string.format("Server: %s. Map %s, %d players, tick rate %s, city NPCs %d.", snap.on and "measuring" or "off",
            tostring(snap.map), snap.playerCount or 0, tostring(snap.tickRate or "?"), snap.cityNPCs or 0)
        if snap.on then
            L[#L + 1] = string.format("Started by %s, %d s ago%s.", tostring(snap.startedBy or "?"), snap.secs or 0,
                snap.left and string.format("; it turns itself off in %d min", math.ceil(snap.left / 60)) or "")
        end
        if snap.lastFile then L[#L + 1] = "Last report saved: " .. snap.lastFile end
    else
        L[#L + 1] = string.format("Your game: %s, for %d s.", snap.on and "measuring" or "off", snap.secs or 0)
    end
    L[#L + 1] = ""
    L[#L + 1] = "What stands out:"
    for _, line in ipairs(P.Findings(snap)) do L[#L + 1] = "  - " .. line end
    local f = snap.frames or {}
    local b = f.buckets or { 0, 0, 0, 0 }
    L[#L + 1] = ""
    L[#L + 1] = string.format("Frames: %d, average %.2f ms (should be %.2f), worst %.1f ms.", f.n or 0, f.avg or 0, f.base or 0, f.max or 0)
    L[#L + 1] = string.format("  on time %d, late %d, slow %d, hitches %d (a hitch is %d ms or more: %d in all).", b[1], b[2], b[3], b[4], snap.spikeMs or 0, snap.spikeCount or 0)
    L[#L + 1] = string.format("Lua it can see: %.1f%% of the time. %d hooks timed.", snap.luaPct or 0, snap.hooksWrapped or 0)
    L[#L + 1] = string.format("Lua memory: %.1f MB now, %.1f MB at most, about %.0f KB taken a second.", (snap.mem or 0) / 1024, (snap.memPeak or 0) / 1024, snap.allocKBs or 0)
    if snap.npcLoop then L[#L + 1] = string.format("City NPC loop: %.2f ms average, %.2f ms worst.", snap.npcLoop.avg, snap.npcLoop.max) end
    local h = snap.history and snap.history[#snap.history]
    if h then L[#L + 1] = string.format("Entities %d, NPCs %d%s.", h.ents, h.npcs or 0, h.edicts and (", edicts " .. h.edicts .. " of 8176") or "") end
    if snap.netcfg then
        local n = snap.netcfg
        L[#L + 1] = string.format("Server net settings: split rate %s, max rate %s, min rate %s.", tostring(n.net_splitpacket_maxrate), tostring(n.sv_maxrate), tostring(n.sv_minrate))
    end
    if snap.cityTimers and #snap.cityTimers > 0 then
        L[#L + 1] = ""
        L[#L + 1] = "The city's repeating timers since the server started (costliest):"
        for i = 1, math.min(6, #snap.cityTimers) do
            local t = snap.cityTimers[i]
            L[#L + 1] = string.format("  %s: %.0f ms in all, %.2f ms average, %.1f ms worst", t.k, t.ms, t.avg, t.max)
        end
    end
    return table.concat(L, "\n")
end

local function HitchText(snap)
    if not snap or #(snap.spikes or {}) == 0 then return "No hitches yet (a frame of " .. tostring(snap and snap.spikeMs or "?") .. " ms or more)." end
    local L = { "The newest last. \"Lua seen\" is how much of the frame was code it timed; the rest is the engine (physics, entities) or code outside hooks.", "" }
    for _, sp in ipairs(snap.spikes) do
        L[#L + 1] = string.format("%s  %.0f ms  (Lua seen %.1f ms, %d players)", sp.at, sp.ms, sp.lua, sp.players or 0)
        for _, t in ipairs(sp.top or {}) do L[#L + 1] = string.format("      %s  %.2f ms", t.k, t.ms) end
    end
    return table.concat(L, "\n")
end

local function Refresh()
    if not IsValid(frame) then return end
    local snap = Current()
    if IsValid(status) then
        local on = srv and srv.on
        status:SetText((on and "Measuring on the server" or "Off on the server") .. "   |   showing: " .. (view == "server" and "Server" or "Your game"))
    end
    if IsValid(startBtn) then startBtn:SetText((srv and srv.on) and "Stop (and save)" or "Start") end
    if IsValid(summary) then summary:SetText(SummaryText(snap)) end
    if IsValid(hitches) then hitches:SetText(HitchText(snap)) end
    for _, t in ipairs(TABS) do
        local lv = lists[t.key]
        if IsValid(lv) then
            lv:Clear()
            for _, row in ipairs((snap and snap[t.key]) or {}) do
                local vals = {}
                for i, c in ipairs(t.cols) do vals[i] = row[c[2]] == nil and "" or row[c[2]] end
                local line = lv:AddLine(unpack(vals))
                if line and line.SetSortValue then
                    for i, v in ipairs(vals) do if type(v) == "number" then line:SetSortValue(i, v) end end
                end
            end
        end
    end
end
LC_CL.PerfDebugRefresh = Refresh

local function Text(parent)
    local e = vgui.Create("DTextEntry", parent)
    e:Dock(FILL)
    e:SetMultiline(true)
    e:SetEditable(false)
    e:SetVerticalScrollbarEnabled(true)
    e:SetFont("DermaDefault")
    return e
end

function LC_CL.PerfDebugReports()
    local parts = {}
    if srv then parts[#parts + 1] = P.ReportText(srv) end
    if P and (P.on or (P.stats and P.stats.frames.n > 0)) then parts[#parts + 1] = P.ReportText(P.Snapshot(25)) end
    return table.concat(parts, "\n\n" .. string.rep("-", 60) .. "\n\n")
end

function LC_CL.PerfDebugMenu()
    if IsValid(frame) then frame:Remove() end
    lists = {}
    frame = vgui.Create("DFrame")
    frame:SetTitle("Performance debugger (staff)")
    frame:SetSize(math.min(ScrW() - 40, 980), math.min(ScrH() - 40, 640))
    frame:Center()
    frame:MakePopup()
    frame.OnRemove = function()
        Cmd("unwatch")
        frame = nil
        FollowServer()
    end

    local bar = vgui.Create("DPanel", frame)
    bar:Dock(TOP)
    bar:SetTall(26)
    bar:DockMargin(0, 0, 0, 4)
    bar.Paint = nil
    local function Btn(text, w, fn)
        local b = vgui.Create("DButton", bar)
        b:Dock(LEFT)
        b:SetWide(w)
        b:DockMargin(0, 0, 4, 0)
        b:SetText(text)
        b.DoClick = fn
        return b
    end
    startBtn = Btn("Start", 110, function() Cmd((srv and srv.on) and "off" or "on") end)
    Btn("Reset", 60, function() Cmd("reset") if P and P.on then P.Reset() end end)
    Btn("Save report", 90, function() Cmd("save") end)
    Btn("Copy report", 90, function()
        SetClipboardText(LC_CL.PerfDebugReports())
        chat.AddText(Color(150, 200, 255), "[Performance debugger] ", color_white, "Both reports copied to the clipboard.")
    end)
    Btn("Server / Your game", 130, function()
        view = view == "server" and "client" or "server"
        Refresh()
    end)
    local spike = vgui.Create("DComboBox", bar)
    spike:Dock(LEFT)
    spike:SetWide(150)
    spike:DockMargin(0, 0, 4, 0)
    spike:SetValue("Hitch at " .. tostring(srv and srv.spikeMs or 60) .. " ms")
    for _, ms in ipairs({ 30, 60, 100, 250 }) do spike:AddChoice("Hitch at " .. ms .. " ms", ms) end
    spike.OnSelect = function(_, _, _, ms)
        Cmd("spike", ms)
        if P then P.spikeMs = ms end
    end
    local mins = vgui.Create("DComboBox", bar)
    mins:Dock(LEFT)
    mins:SetWide(150)
    mins:DockMargin(0, 0, 4, 0)
    mins:SetValue("Turns off after " .. tostring(srv and srv.minutes or 30) .. " min")
    for _, m in ipairs({ 15, 30, 60, 120 }) do mins:AddChoice("Turns off after " .. m .. " min", m) end
    mins:AddChoice("Never turns itself off", 0)
    mins.OnSelect = function(_, _, _, m) Cmd("minutes", m) end

    status = vgui.Create("DLabel", frame)
    status:Dock(TOP)
    status:SetTall(18)
    status:DockMargin(2, 0, 0, 4)
    status:SetText("Asking the server...")

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    local sp = vgui.Create("DPanel", sheet)
    sp.Paint = nil
    summary = Text(sp)
    sheet:AddSheet("Summary", sp, "icon16/chart_line.png")
    local hp = vgui.Create("DPanel", sheet)
    hp.Paint = nil
    hitches = Text(hp)
    sheet:AddSheet("Hitches", hp, "icon16/error.png")
    for _, t in ipairs(TABS) do
        local p = vgui.Create("DPanel", sheet)
        p.Paint = nil
        local lv = vgui.Create("DListView", p)
        lv:Dock(FILL)
        lv:SetMultiSelect(false)
        for _, c in ipairs(t.cols) do
            local col = lv:AddColumn(c[1])
            if c[3] and col and col.SetMinWidth then col:SetMinWidth(c[3]) end
        end
        lv.OnRowRightClick = function(_, _, line)
            if line and line.GetColumnText then SetClipboardText(tostring(line:GetColumnText(1))) end
        end
        lists[t.key] = lv
        sheet:AddSheet(t.tab, p)
    end
    Cmd("watch")
    Refresh()
end

concommand.Add("lc_perfdebug_menu", function() LC_CL.PerfDebugMenu() end)

concommand.Add("lc_perfdebug_print", function()
    local text = LC_CL.PerfDebugReports()
    if text == "" then print("[Performance debugger] Nothing yet: open it (C > Help > Performance debugger) and press Start.") return end
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do print(line) end
end)

net.Receive("lc_perfdebug", function()
    local t = ReadCompressed()
    if not t then return end
    srv = t
    LC_CL.PerfDebugServer = t
    FollowServer()
    Refresh()
end)

-- your game's figures move between the server's
timer.Create("LivingCityPerfDebugView", 2, 0, function()
    if IsValid(frame) and view == "client" then Refresh() end
end)
