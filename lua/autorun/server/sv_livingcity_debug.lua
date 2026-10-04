--[[
    Living City: debugging

    lc_debugreport   Builds a full report: version, map, gamemode, every lc_ setting,
                     layout stats, what each NPC is doing, performance timings, and
                     the last errors and warnings. Saves it to
                     garrysmod/data/livingcity/reports/ and, when run by a player,
                     opens it on their screen with a Copy button.

    lc_debug 1       Prints every log line to the server console as it happens.

    Lua errors that mention Living City are captured automatically, including
    errors on players' clients (rate limited).
]]

if CLIENT then return end

util.AddNetworkString("lc_report")
util.AddNetworkString("lc_clerror")

LC = LC or {}

CreateConVar("lc_debug", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Print every Living City log line to the console")

local function Mentions(text)
    text = string.lower(tostring(text or ""))
    return string.find(text, "livingcity", 1, true) or string.find(text, "living city", 1, true)
        or string.find(text, "lc_", 1, true) or string.find(text, "weapon_lc_", 1, true)
end

-- Server-side Lua errors (hook exists on current Garry's Mod builds)
hook.Add("OnLuaError", "LivingCityCapture", function(err, realm, stack, name)
    local where = ""
    if istable(stack) and stack[1] then where = tostring(stack[1].File or "") .. ":" .. tostring(stack[1].Line or "") end
    if Mentions(err) or Mentions(where) or Mentions(name) then
        LC.Log("error", string.format("lua %s error: %s (%s)", tostring(realm), tostring(err), where))
    end
end)

-- Errors reported by clients
local lastClientError = {}
net.Receive("lc_clerror", function(_, ply)
    if (lastClientError[ply] or 0) > CurTime() then return end
    lastClientError[ply] = CurTime() + 5
    local msg = string.sub(net.ReadString(), 1, 400)
    if Mentions(msg) then LC.Log("error", "client " .. ply:Nick() .. ": " .. msg) end
end)

------------------------------------------------------------------------
-- Report
------------------------------------------------------------------------

local function Section(out, title) out[#out + 1] = ""; out[#out + 1] = "== " .. title .. " ==" end

local function Settings()
    local out = {}
    local names = {}
    for _, name in ipairs({
        "lc_citizens", "lc_cops", "lc_soldiers", "lc_scanners", "lc_zombies", "lc_npc_budget", "lc_lod_distance",
        "lc_autostart", "lc_spawn_mindist", "lc_citizen_lifetime", "lc_npc_arrest_chance", "lc_rebel_pursuit",
        "lc_unlock_doors", "lc_player_doors", "lc_npc_doors", "lc_announce_interval", "lc_auto_events",
        "lc_event_interval", "lc_curfew_citizens", "lc_curfew_enforce", "lc_chatter", "lc_can_event",
        "lc_prison_time", "lc_npc_arrests", "lc_escape_wanted", "lc_rejoin_penalty", "lc_street_detention", "lc_street_fine", "lc_block_name",
        "lc_needs", "lc_hunger_minutes", "lc_thirst_minutes", "lc_birds", "lc_vermin", "lc_economy", "lc_story_pacing",
        "lc_stops", "lc_stop_cooldown", "lc_stop_chance", "lc_street_stop_chance", "lc_search_cooldown", "lc_disguise_risk",
        "lc_identity_minutes", "lc_stash_size", "lc_raid_chance", "lc_search_weapons", "lc_response", "lc_response_soldiers",
        "lc_factions", "lc_quests", "lc_quest_violent_ratio", "lc_quest_squad", "lc_quest_cooldown", "lc_conduct", "lc_rdm_strikes_jail", "lc_rdm_strikes_kick", "lc_spawn_protect", "lc_debug",
    }) do names[#names + 1] = name end
    for _, name in ipairs(names) do
        local cv = GetConVar(name)
        if cv then out[#out + 1] = name .. " = " .. cv:GetString() end
    end
    return out
end

function LC.BuildReport()
    local out = {}
    out[#out + 1] = "LIVING CITY DEBUG REPORT"
    local systems = LC.Gamemode and LC.Gamemode() or "?"
    systems = (systems == "sandbox") and "Living City's own systems" or (systems .. "'s systems")
    out[#out + 1] = string.format("version %s | map %s | gamemode %s%s, using %s | %s",
        LC.VERSION or "?", game.GetMap(), engine.ActiveGamemode(),
        (LC.InOwnGamemode and LC.InOwnGamemode()) and " (the Living City gamemode)" or " (Living City as an addon)",
        systems, os.date("%Y-%m-%d %H:%M:%S"))
    out[#out + 1] = string.format("players %d/%d | singleplayer %s | dedicated %s | uptime %s",
        #player.GetAll(), game.MaxPlayers(), tostring(game.SinglePlayer()), tostring(game.IsDedicated()),
        string.NiceTime(CurTime()))
    out[#out + 1] = string.format("city %s | event %s | factions %s",
        LC.Running and ("running for " .. string.NiceTime(CurTime() - (LC.StartedAt or CurTime()))) or "stopped",
        LC.Event or "none", (LC.FactionsActive and LC.FactionsActive()) and "on" or "off")

    Section(out, "Settings")
    for _, l in ipairs(Settings()) do out[#out + 1] = l end

    Section(out, "Layout")
    local kinds = {}
    for _, p in ipairs(LC.Points or {}) do
        local k = p.kind .. (((p.group or 0) > 0) and ("#" .. p.group) or "")
        kinds[k] = (kinds[k] or 0) + 1
    end
    local kl = {}
    for k, c in SortedPairs(kinds) do kl[#kl + 1] = k .. " x" .. c end
    out[#out + 1] = "points: " .. (#kl > 0 and table.concat(kl, ", ") or "none")
    out[#out + 1] = string.format("path nodes %d (usable %d), links %d, unlinked %d",
        table.Count(LC.Nodes or {}), LC.NodeCount and LC.NodeCount() or 0,
        LC.LinkCount and LC.LinkCount() or 0, LC.OrphanNodes and #LC.OrphanNodes() or 0)
    local zk = {}
    for _, z in ipairs(LC.Zones or {}) do
        local k = z.kind .. (((z.group or 0) > 0) and ("#" .. z.group) or "")
        zk[k] = (zk[k] or 0) + 1
    end
    local zl = {}
    for k, c in SortedPairs(zk) do zl[#zl + 1] = k .. " x" .. c end
    out[#out + 1] = "zones: " .. (#zl > 0 and table.concat(zl, ", ") or "none")
    local dt = {}
    for _, tag in pairs(LC.DoorTags or {}) do dt[tag] = (dt[tag] or 0) + 1 end
    local dl = {}
    for k, c in SortedPairs(dt) do dl[#dl + 1] = k .. " x" .. c end
    out[#out + 1] = "door tags: " .. (#dl > 0 and table.concat(dl, ", ") or "none")
    out[#out + 1] = string.format("map navigation: %d spots from %s%s", #(LC.Fallback or {}), LC.Source or "none",
        LC.SourceDetail and (" (" .. LC.SourceDetail .. ")") or "")
    local warn = {}
    local function count(kind) return #(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) end
    local function zones(kind) return #(LC.ZonesOfKind and LC.ZonesOfKind(kind) or {}) end
    if count("cell") == 0 then warn[#warn + 1] = "no prison cells: arrests become street detentions (cuffed, searched, fined, released)" end
    if count("spawn") == 0 then warn[#warn + 1] = "no spawn/exit doorways: NPCs appear out of sight and leave into blocks or wander off" end
    if zones("block") == 0 then warn[#warn + 1] = "no housing blocks: curfew can't send anyone home, and nobody has a stash" end
    do
        local counts = {}
        for _, fx in ipairs(LC.StaticFixtures or {}) do counts[fx.kind] = (counts[fx.kind] or 0) + 1 end
        local parts = {}
        for k, n in pairs(counts) do parts[#parts + 1] = n .. " " .. k end
        out[#out + 1] = "static map fixtures: " .. (#parts > 0 and table.concat(parts, ", ") or "none")
            .. (LC.StaticScanNote and (" (scan failed: " .. tostring(LC.StaticScanNote) .. ")") or "")
    end
    if zones("combine") == 0 then warn[#warn + 1] = "no Combine-only zones: citizens can walk into the nexus, offices and armory (doors by the cells still lock)" end
    if count("zspawn") == 0 and zones("infest") > 0 then warn[#warn + 1] = "no infestation spawn points: zombies appear at random spots inside infestation zones" end
    if count("checkpoint") == 0 and count("patrol") == 0 then warn[#warn + 1] = "no checkpoints or patrol beats: cops wander at random" end
    if count("work") == 0 then warn[#warn + 1] = "no workplaces: Union shifts happen out on the streets" end
    for g in SortedPairs(LC.Lines or {}) do
        if LC.LineDispenser and not IsValid(LC.LineDispenser(g)) then
            warn[#warn + 1] = string.format("line %d has no ration dispenser at its front: NPCs are still served, and players who wait at the front are handed a ration", g)
        end
    end
    out[#out + 1] = "setup notes: " .. (#warn > 0 and "" or "none")
    for _, w in ipairs(warn) do out[#out + 1] = "  - " .. w end
    for g, line in SortedPairs(LC.Lines or {}) do
        local coming = 0
        for _, st in pairs(LC.NPCs or {}) do if st.lineHeading == g then coming = coming + 1 end end
        out[#out + 1] = string.format("line %d: %d slots, %d queued, %d on their way, front waiting %ds", g, #line.slots, #line.q, coming,
            (line.q[1] and line.frontSince) and math.floor(CurTime() - line.frontSince) or 0)
    end

    Section(out, "NPCs")
    local byRole, byState = {}, {}
    local rows = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) then
            byRole[st.role] = (byRole[st.role] or 0) + 1
            local key = st.role .. ":" .. tostring(st.state)
            byState[key] = (byState[key] or 0) + 1
            if #rows < 40 then
                local chasing = ""
                if st.state == "hostile" and IsValid(st.enemy) then
                    chasing = string.format(" chasing %s at %.0fu", st.enemy:IsPlayer() and st.enemy:Nick() or st.enemy:GetClass(),
                        st.enemy:GetPos():Distance(npc:GetPos()))
                end
                rows[#rows + 1] = string.format("  %-8s %-16s hp %3d recov %d err %d hop %s/%s pos %s%s%s%s",
                    st.role, tostring(st.state), npc:Health(), st.recoveries or 0, st.errors or 0,
                    tostring(st.hop or "-"), tostring(st.route and #st.route or "-"),
                    string.format("%.0f %.0f %.0f", npc:GetPos().x, npc:GetPos().y, npc:GetPos().z),
                    st.routeGroup and (" beat " .. st.routeGroup) or "",
                    st.line and (" line " .. st.line .. " slot " .. tostring(st.slotIndex)) or (st.lineHeading and (" heading to line " .. st.lineHeading) or ""), chasing)
            end
        end
    end
    local rl, sl = {}, {}
    for k, c in SortedPairs(byRole) do rl[#rl + 1] = k .. " " .. c end
    for k, c in SortedPairs(byState) do sl[#sl + 1] = k .. " " .. c end
    out[#out + 1] = "by role: " .. (#rl > 0 and table.concat(rl, ", ") or "none")
    out[#out + 1] = "by state: " .. (#sl > 0 and table.concat(sl, ", ") or "none")
    out[#out + 1] = "stuck recoveries since load: " .. (LC.StuckCount or 0)
    for _, r in ipairs(rows) do out[#out + 1] = r end

    Section(out, "Performance")
    local p = LC.Perf or {}
    out[#out + 1] = string.format("main loop: avg %.2f ms, last %.2f ms, worst %.2f ms over %d ticks",
        (p.samples or 0) > 0 and p.total / p.samples or 0, p.last or 0, p.max or 0, p.samples or 0)
    out[#out + 1] = string.format("server tick interval %.4f, entity count %d", engine.TickInterval(), #ents.GetAll())

    Section(out, "Quests")
    local nq = 0
    for q in pairs(LC.ActiveQuests or {}) do
        nq = nq + 1
        if nq <= 20 then
            local names = {}
            for _, m in ipairs(q.members or {}) do if IsValid(m) then names[#names + 1] = m:Nick() end end
            out[#out + 1] = string.format("  %s [%s] step %d/%d (%s) %ds left: %s", q.title, q.tmpl and q.tmpl.id or "?",
                q.stage or 0, #(q.stages or {}), q.stages and q.stages[q.stage] and q.stages[q.stage].kind or "?",
                math.floor((q.expires or 0) - CurTime()), table.concat(names, ", "))
        end
    end
    out[#out + 1] = string.format("active %d | violent cap %d", nq, LC.ViolentCap and LC.ViolentCap() or 0)

    Section(out, "People")
    local prisoners = 0
    for pl in pairs(LC.Prisoners or {}) do if IsValid(pl) then prisoners = prisoners + 1 end end
    local held = 0
    for pl in pairs(LC.Detained or {}) do if IsValid(pl) then held = held + 1 end end
    out[#out + 1] = "prisoners: " .. prisoners .. " | detained on the street: " .. held
    local stops = 0
    for pl in pairs(LC.Stops or {}) do if IsValid(pl) then stops = stops + 1 end end
    out[#out + 1] = "stops in progress: " .. stops .. " | next event: " .. tostring(LC.PendingEvent or "-")
    for _, pl in ipairs(player.GetAll()) do
        if #out > 400 then break end
        local illegal = 0
        if LC.Inventory and LCS then
            for id, n in pairs(LC.Inventory(pl)) do if LCS.Items[id] and LCS.Items[id].contraband then illegal = illegal + n end end
        end
        local under = {}
        if pl:GetNW2String("lcd_disguise", "") ~= "" then under[#under + 1] = "disguise " .. pl:GetNW2String("lcd_disguise", "") end
        if pl:GetNW2String("lcd_alias", "") ~= "" then under[#under + 1] = "alias " .. pl:GetNW2String("lcd_alias", "") end
        if pl:GetNW2String("lcu_band", "") ~= "" then under[#under + 1] = "radio " .. pl:GetNW2String("lcu_band", "") end
        if illegal > 0 then under[#under + 1] = "contraband " .. illegal end
        if LC.AlertLevel and LC.Heat(pl) > 0 then
            under[#under + 1] = string.format("alert %d (heat %d, %d soldiers after them)", LC.AlertLevel(pl), LC.Heat(pl), #LC.Responders(pl))
        end
        under[#under + 1] = string.format("at %.0f %.0f %.0f%s", pl:GetPos().x, pl:GetPos().y, pl:GetPos().z,
            (LC.InRebelZone and LC.InRebelZone(pl:GetPos())) and " (rebel territory)" or "")
        out[#out + 1] = string.format("  %s | %s | job %s | block %s | cp %s | wanted %s | hunger %d thirst %d | credits %s standing %s%s%s",
            pl:Nick(), pl:GetNW2String("lcf_title", "-"), pl:GetNW2String("lcj_job", "-"),
            tostring(LC.PlayerBlock and LC.PlayerBlock(pl) or "-"),
            tostring(LC.PlayerIsCP(pl)), tostring(LC.PlayerIsWanted(pl)),
            math.floor(pl:GetNW2Float("lcn_hunger", 100)), math.floor(pl:GetNW2Float("lcn_thirst", 100)),
            tostring(LC.Credits and LC.Credits(pl) or "-"), tostring(LC.Standing and LC.Standing(pl) or "-"),
            #under > 0 and (" | " .. table.concat(under, ", ")) or "",
            (LC.ConductSummary and (" | " .. LC.ConductSummary(pl))) or "")
    end

    Section(out, "Recent log (newest last)")
    local buf = LC.LogBuffer or {}
    for i = math.max(1, #buf - 80), #buf do out[#out + 1] = buf[i] end
    if #buf == 0 then out[#out + 1] = "(empty)" end

    return table.concat(out, "\n")
end

concommand.Add("lc_debugreport", function(ply)
    if IsValid(ply) and not (ply:IsAdmin() or LC.CanEdit(ply)) then return end
    local ok, report = pcall(LC.BuildReport)
    if not ok then report = "Report failed to build: " .. tostring(report) .. "\n\nLog:\n" .. table.concat(LC.LogBuffer or {}, "\n") end

    file.CreateDir("livingcity/reports")
    local name = "livingcity/reports/report_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    file.Write(name, report)

    if IsValid(ply) then
        LC.SendCompressed("lc_report", { text = report, file = "garrysmod/data/" .. name }, { ply })
    else
        print(report)
        print("Saved to garrysmod/data/" .. name)
    end
end)
