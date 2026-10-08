--[[
    Living City (client): the lag monitor

    C > Help > Lag monitor (staff), or lc_lagwatch in the console. A panel
    at the right of the screen, once a second, with what the server measured
    (sv_livingcity_lagwatch.lua) and what this game sees:

      - your frames per second, and your slowest frame
      - the server's frame time as your game hears it
      - how regularly the server's updates arrive: the longest wait between
        two (NPCs walking show it: their networked position changes once
        per update). Long waits mean NPCs freeze and then jump.
      - NPCs snapping on your screen: jumps, and steps back the way they came
      - your interpolation and rate settings

    and a line saying which of those looks like the cause. lc_lagwatch_print
    prints the last half minute to the console, to copy and send on.
]]

LC_CL = LC_CL or {}

local on = false
local srv           -- the last second from the server
local hist = {}     -- the last 30 seconds, for printing
local cur = { frames = 0, worstFrame = 0, worstUpdate = 0, snaps = 0, backs = 0, snapBy = {} }
local lastAnyChange, seen = nil, {} -- [npc] = { net = Vector, pos = Vector, delta = Vector }

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function CV(name)
    local c = GetConVar(name)
    return c and c:GetString() or "?"
end

function LC_CL.SetLagWatch(want)
    if want == nil then want = not on end
    on = want and true or false
    net.Start("lc_lagwatch_on")
    net.WriteBool(on)
    net.SendToServer()
    if not on then srv = nil end
    chat.AddText(Color(150, 200, 255), "[Lag monitor] ", color_white, on and "On. It's at the right of your screen. (lc_lagwatch_print copies the last half minute to the console.)" or "Off.")
end
function LC_CL.LagWatchOn() return on end

concommand.Add("lc_lagwatch", function() LC_CL.SetLagWatch() end)

------------------------------------------------------------------------
-- What this game sees, every frame
------------------------------------------------------------------------

-- What a big update carries: networked values changed, by name, and
-- entities moved, by class, in the single busiest frame of the second.
local nwThisFrame, nwBy = 0, {}
hook.Add("EntityNetworkedVarChanged", "LivingCityLagWatch", function(ent, name)
    if not on then return end
    nwThisFrame = nwThisFrame + 1
    nwBy[name] = (nwBy[name] or 0) + 1
end)

local lastOrigin = {}
local function BusiestFrame()
    local moved, byClass = 0, {}
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and not e:IsPlayer() then
            local o = e.GetNetworkOrigin and e:GetNetworkOrigin() or e:GetPos()
            local was = lastOrigin[e]
            if was and was ~= o then
                moved = moved + 1
                local c = e:GetClass()
                byClass[c] = (byClass[c] or 0) + 1
            end
            lastOrigin[e] = o
        end
    end
    for e in pairs(lastOrigin) do if not IsValid(e) then lastOrigin[e] = nil end end
    if moved > (cur.peakMoved or 0) then cur.peakMoved, cur.peakBy = moved, byClass end
    if nwThisFrame > (cur.peakNW or 0) then cur.peakNW, cur.peakNWBy = nwThisFrame, nwBy end
    nwThisFrame, nwBy = 0, {}
end

local function Top3(t)
    local list = {}
    for k, v in pairs(t or {}) do list[#list + 1] = { k, v } end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local out = {}
    for i = 1, math.min(3, #list) do out[i] = list[i][1] .. " " .. list[i][2] end
    return table.concat(out, ", ")
end

hook.Add("Think", "LivingCityLagWatch", function()
    if not on then return end
    BusiestFrame()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local now, dt = SysTime(), FrameTime()
    cur.frames = cur.frames + 1
    if dt * 1000 > cur.worstFrame then cur.worstFrame = dt * 1000 end
    local mypos = me:GetPos()
    local anyMoving = false
    for _, npc in ipairs(ents.FindInSphere(mypos, 2500)) do
        if IsValid(npc) and npc:IsNPC() then
            local s = seen[npc]
            local netPos = npc.GetNetworkOrigin and npc:GetNetworkOrigin() or npc:GetPos()
            local pos = npc:GetPos()
            if s then
                -- an update arrived: its networked position moved
                if netPos ~= s.net then lastAnyChange = now end
                if npc:GetVelocity():Length2DSqr() > 400 then anyMoving = true end
                -- on screen: a jump, or a step back the way it came
                local d = pos - s.pos
                local len = d:Length()
                local speed = math.max(npc:GetVelocity():Length(), 60)
                if len > math.max(64, speed * dt * 4) then
                    cur.snaps = cur.snaps + 1
                    local c = npc:GetClass()
                    cur.snapBy[c] = (cur.snapBy[c] or 0) + 1
                elseif len > 4 and s.delta and s.delta:Length() > 4 and d:GetNormalized():Dot(s.delta:GetNormalized()) < -0.6 then
                    cur.backs = cur.backs + 1
                end
                s.delta = d
                s.pos, s.net = pos, netPos
            else
                seen[npc] = { pos = pos, net = netPos }
            end
        end
    end
    if anyMoving and lastAnyChange then
        local wait = (now - lastAnyChange) * 1000
        if wait > cur.worstUpdate then cur.worstUpdate = wait end
    end
    for npc in pairs(seen) do if not IsValid(npc) then seen[npc] = nil end end
end)

timer.Create("LivingCityLagWatchSecond", 1, 0, function()
    if not on then return end
    local sft, sdev = 0, 0
    if engine.ServerFrameTime then sft, sdev = engine.ServerFrameTime() end
    local row = {
        t = os.date("%H:%M:%S"), fps = cur.frames, worstFrame = cur.worstFrame, worstUpdate = cur.worstUpdate,
        snaps = cur.snaps, backs = cur.backs, sft = (sft or 0) * 1000, sdev = (sdev or 0) * 1000, srv = srv,
        peakMoved = cur.peakMoved or 0, peakBy = Top3(cur.peakBy), peakNW = cur.peakNW or 0, peakNWBy = Top3(cur.peakNWBy),
    }
    table.insert(hist, row)
    while #hist > 30 do table.remove(hist, 1) end
    LC_CL.LagWatchRow = row
    cur = { frames = 0, worstFrame = 0, worstUpdate = 0, snaps = 0, backs = 0, snapBy = {} }
end)

net.Receive("lc_lagwatch", function()
    local t = ReadCompressed()
    if t then
        srv = t
        -- your usual ping: the lowest lately, drifting up slowly
        if t.ping and t.ping > 0 then
            local b = LC_CL.LagWatchPingBase
            LC_CL.LagWatchPingBase = (not b or t.ping < b) and t.ping or (b + (t.ping - b) * 0.02)
        end
    end
end)

------------------------------------------------------------------------
-- Which looks like the cause
------------------------------------------------------------------------

local function Verdict(r)
    local s = r.srv
    local tickMs = s and s.rate and s.rate > 0 and (1000 / s.rate) or 30
    if s and s.tele and s.tele > 3 then
        local top = s.teleBy and s.teleBy[1]
        return "The gamemode is teleporting NPCs (" .. s.tele .. " this second" .. (top and (", most from " .. top.k) or "") .. ").", Color(255, 120, 90)
    end
    if s and (s.worstGap > tickMs * 4 or (s.ticks and s.rate and s.ticks < s.rate * 0.8)) then
        return string.format("The server is hitching: %.0f ms between two frames (it should be %.0f).", s.worstGap, tickMs), Color(255, 120, 90)
    end
    -- ping well above its usual: data queueing somewhere between you and the server
    local base = LC_CL.LagWatchPingBase
    if s and s.ping and base and s.ping > math.max(base * 2, base + 50) then
        return string.format("Your ping jumped from about %d to %d ms with the server keeping up: something on the connection (a download, another device, the host's upload).", base, s.ping), Color(255, 160, 90)
    end
    if s and s.loss and s.loss > 2 then
        return string.format("Packets are being lost between you and the server (%d%%): the connection or the host.", s.loss), Color(255, 120, 90)
    end
    if r.worstUpdate > 250 then
        return string.format("The server's updates reach you late (a %.0f ms wait): the network, or the server sending you too much (choke). Check net_graph 3.", r.worstUpdate), Color(255, 200, 90)
    end
    if r.worstFrame > 100 then
        return string.format("Your own game is stalling (a %.0f ms frame): addons, or the graphics.", r.worstFrame), Color(255, 200, 90)
    end
    if r.snaps + r.backs > 3 then
        return "NPCs are snapping, but nothing measured here explains it yet. Send lc_lagwatch_print.", Color(255, 200, 90)
    end
    return "Nothing wrong this second.", Color(150, 230, 150)
end

local BG, INK, DIM = Color(10, 12, 16, 215), Color(225, 225, 225), Color(150, 155, 165)

hook.Add("HUDPaint", "LivingCityLagWatch", function()
    if not on then return end
    local r = LC_CL.LagWatchRow
    local w, x, y = 420, ScrW() - 436, 90
    local lines = {}
    local function L(text, col) lines[#lines + 1] = { text, col or INK } end
    L("LAG MONITOR (C > Help to turn off)", Color(150, 200, 255))
    if not r then
        L("measuring...", DIM)
    else
        local s = r.srv
        if s then
            L(string.format("Server: %d of %d ticks, longest gap %.0f ms, NPC loop %.2f ms", s.ticks or 0, s.rate or 0, s.worstGap or 0, s.luaMax or 0))
            L(string.format("NPC teleports by the gamemode: %d%s", s.tele or 0,
                (s.teleBy and s.teleBy[1]) and ("  (" .. s.teleBy[1].k .. " x" .. s.teleBy[1].v .. ")") or ""))
            local nb = {}
            for _, b in ipairs(s.netBy or {}) do nb[#nb + 1] = b.k .. " " .. math.floor(b.v / 1024 * 10) / 10 .. "k" end
            L(string.format("Gamemode net: %.1f KB/s  %s", (s.netBytes or 0) / 1024, table.concat(nb, ", ")), DIM)
            L(string.format("Entities %d, edicts %d of 8176, NPCs %d (city %d, asleep %d)", s.ents or 0, s.edicts or 0, s.allNPCs or 0, s.npcs or 0, s.asleep or 0), DIM)
            L(string.format("You: ping %d ms, packet loss %d%%", s.ping or 0, s.loss or 0))
        else
            L("Server: no figures yet (staff only)", DIM)
        end
        L(string.format("Your game: %d fps, slowest frame %.0f ms; server frame as heard %.1f ms (+/- %.1f)", r.fps, r.worstFrame, r.sft, r.sdev))
        L(string.format("Longest wait for a server update: %.0f ms", r.worstUpdate))
        L(string.format("NPCs snapping on screen: %d jumps, %d steps back", r.snaps, r.backs))
        L(string.format("Busiest update: %d things moved (%s); %d values changed (%s)", r.peakMoved, r.peakBy ~= "" and r.peakBy or "-", r.peakNW, r.peakNWBy ~= "" and r.peakNWBy or "-"), DIM)
        if r.srv and r.srv.netcfg then
            local n = r.srv.netcfg
            L(string.format("Server net: split rate %s, max rate %s, min rate %s", n.net_splitpacket_maxrate or "?", n.sv_maxrate or "?", n.sv_minrate or "?"), DIM)
        end
        L(string.format("cl_interp %s, cl_interp_ratio %s, cl_updaterate %s, rate %s", CV("cl_interp"), CV("cl_interp_ratio"), CV("cl_updaterate"), CV("rate")), DIM)
        local v, col = Verdict(r)
        L(v, col)
    end
    surface.SetFont("DermaDefault")
    local h = #lines * 15 + 10
    draw.RoundedBox(4, x, y, w, h, BG)
    for i, l in ipairs(lines) do
        local t = l[1]
        while #t > 4 and surface.GetTextSize(t) > w - 14 do t = string.sub(t, 1, #t - 4) .. "..." end
        draw.SimpleText(t, "DermaDefault", x + 7, y + 5 + (i - 1) * 15, l[2])
    end
end)

concommand.Add("lc_lagwatch_print", function()
    if #hist == 0 then print("[Lag monitor] Nothing yet: turn it on with lc_lagwatch and wait a few seconds.") return end
    print("[Lag monitor] the last " .. #hist .. " seconds (copy from here)")
    for _, r in ipairs(hist) do
        local s = r.srv or {}
        local tb = s.teleBy and s.teleBy[1] and (s.teleBy[1].k .. " x" .. s.teleBy[1].v) or "-"
        local nb = {}
        for _, b in ipairs(s.netBy or {}) do nb[#nb + 1] = b.k .. ":" .. b.v end
        print(string.format("%s | srv ticks %s/%s gap %sms lua %sms tele %s (%s) net %sB [%s] ents %s edicts %s npcs %s asleep %s ping %s loss %s | fps %d worst %.0fms srvframe %.1f+/-%.1f update-wait %.0fms snaps %d backs %d | %s",
            r.t, tostring(s.ticks), tostring(s.rate), tostring(s.worstGap), tostring(s.luaMax), tostring(s.tele), tb, tostring(s.netBytes), table.concat(nb, " "),
            tostring(s.ents), tostring(s.edicts), tostring(s.allNPCs), tostring(s.asleep), tostring(s.ping), tostring(s.loss),
            r.fps, r.worstFrame, r.sft, r.sdev, r.worstUpdate, r.snaps, r.backs, (Verdict(r))))
        print(string.format("         busiest update: %d moved [%s] | %d values changed [%s]", r.peakMoved or 0, r.peakBy or "", r.peakNW or 0, r.peakNWBy or ""))
    end
    local n = hist[#hist].srv and hist[#hist].srv.netcfg
    if n then print(string.format("server net: net_splitpacket_maxrate %s sv_maxrate %s sv_minrate %s", n.net_splitpacket_maxrate or "?", n.sv_maxrate or "?", n.sv_minrate or "?")) end
    print(string.format("settings: cl_interp %s cl_interp_ratio %s cl_updaterate %s cl_cmdrate %s rate %s", CV("cl_interp"), CV("cl_interp_ratio"), CV("cl_updaterate"), CV("cl_cmdrate"), CV("rate")))
end)
