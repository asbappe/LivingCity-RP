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
        "lc_citizens", "lc_cops", "lc_soldiers", "lc_scanners", "lc_zombies", "lc_rebels", "lc_skirmishes", "lc_skirmish_interval", "lc_rebel_damage", "lc_territory_spread", "lc_rebel_spread_minutes", "lc_infest_spread_minutes", "lc_territory_max", "lc_territory_hits", "lc_scavenge_refill", "lc_garden_minutes", "lc_cache_max", "lc_food_scaling", "lc_food_availability", "lc_food_restock_minutes", "lc_gas_damage", "lc_npc_budget", "lc_lod_distance",
        "lc_autostart", "lc_spawn_mindist", "lc_citizen_lifetime", "lc_npc_arrest_chance", "lc_rebel_pursuit",
        "lc_unlock_doors", "lc_player_doors", "lc_npc_doors", "lc_announce_interval", "lc_auto_events",
        "lc_event_interval", "lc_curfew_citizens", "lc_curfew_enforce", "lc_chatter", "lc_can_event",
        "lc_prison_time", "lc_npc_arrests", "lc_escape_wanted", "lc_rejoin_penalty", "lc_street_detention", "lc_street_fine", "lc_block_name",
        "lc_needs", "lc_hunger_minutes", "lc_thirst_minutes", "lc_birds", "lc_vermin", "lc_economy", "lc_story_pacing",
        "lc_stops", "lc_stop_cooldown", "lc_stop_chance", "lc_street_stop_chance", "lc_search_cooldown", "lc_disguise_risk",
        "lc_identity_minutes", "lc_stash_size", "lc_raid_chance", "lc_search_weapons", "lc_response", "lc_response_soldiers", "lc_squad", "lc_squad_cops", "lc_squad_soldiers", "lc_squad_delay", "lc_garrison", "lc_garrison_cops", "lc_garrison_respawn",
        "lc_quests", "lc_quest_violent_ratio", "lc_quest_squad", "lc_quest_cooldown", "lc_conduct", "lc_rdm_strikes_jail", "lc_rdm_strikes_kick", "lc_spawn_protect", "lc_debug",
        "lc_fov", "lc_eye_height", "lc_view_bob", "lc_view_bob_amount", "lc_quiet_hud", "lc_respawn_secs", "lc_word_gets_around",
        "lc_intake", "lc_intake_secs", "lc_intake_grace",
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
    out[#out + 1] = string.format("version %s | map %s | gamemode %s | %s",
        LC.VERSION or "?", game.GetMap(), engine.ActiveGamemode(), os.date("%Y-%m-%d %H:%M:%S"))
    out[#out + 1] = string.format("players %d/%d | singleplayer %s | dedicated %s | uptime %s",
        #player.GetAll(), game.MaxPlayers(), tostring(game.SinglePlayer()), tostring(game.IsDedicated()),
        string.NiceTime(CurTime()))
    out[#out + 1] = string.format("city %s | event %s",
        LC.Running and ("running for " .. string.NiceTime(CurTime() - (LC.StartedAt or CurTime()))) or "stopped",
        LC.Event or "none")

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
    if LC.GrownCount then
        out[#out + 1] = string.format("territory grown since placed: rebel %d patches, infestation %d patches (lc_territory for details)",
            LC.GrownCount("rebel"), LC.GrownCount("infest"))
    end
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
    do
        local alive, dead, rebels = 0, 0, 0
        for _, p in ipairs(LC.People and LC.People.list or {}) do
            if p.alive then alive = alive + 1 if p.rebel then rebels = rebels + 1 end else dead = dead + 1 end
        end
        out[#out + 1] = string.format("people: %d alive (%d sympathizers), %d dead remembered", alive, rebels, dead)
    end
    if zones("combine") == 0 then warn[#warn + 1] = "no Combine-only zones: citizens can walk into the nexus, offices and armory (doors by the cells still lock)" end
    if count("zspawn") == 0 and zones("infest") > 0 then warn[#warn + 1] = "no infestation spawn points: zombies appear at random spots inside infestation zones" end
    if count("checkpoint") == 0 and count("patrol") == 0 then warn[#warn + 1] = "no checkpoints or patrol beats: cops wander at random" end
    if count("work") == 0 then warn[#warn + 1] = "no workplaces: Union shifts happen out on the streets" end
    do
        local cap = GetConVar("lc_npc_budget") and GetConVar("lc_npc_budget"):GetInt() or 60
        local want = LC.NPCTargetsTotal and LC.NPCTargetsTotal() or 0
        if want > cap then warn[#warn + 1] = string.format("lc_npc_budget (%d) is below what the settings want (%d NPCs): nothing more spawns past it, Civil Protection included (60 is the default)", cap, want) end
    end
    for g in SortedPairs(LC.Lines or {}) do
        if LC.LineDispenser and not IsValid(LC.LineDispenser(g)) then
            warn[#warn + 1] = string.format("line %d has no ration dispenser at its front: NPCs are still served, and players who wait at the front are handed a ration", g)
        end
    end
    -- where the city's recordings are looked for, and what's found in each place (the server's own
    -- view: a player's computer must have the same files, downloaded, to hear them)
    do
        local parts = {}
        for _, root in ipairs(LC.AnnounceRoots or { "livingcity/announce/" }) do
            for _, v in ipairs({ "overwatch", "administrator", "radio" }) do
                local n = #(file.Find("sound/" .. root .. v .. "/*", "GAME") or {})
                if n > 0 then parts[#parts + 1] = "sound/" .. root .. v .. "/ " .. n end
            end
        end
        out[#out + 1] = "recordings: " .. (#parts > 0 and table.concat(parts, ", ") or "none found in sound/livingcity/overwatch/, administrator/, radio/ or under announce/")
        local songs = {}
        for _, id in ipairs(LC.EndingOrder or {}) do
            local n = #(LC.EndingSongs and LC.EndingSongs(id) or {})
            songs[#songs + 1] = id .. " " .. n
        end
        out[#out + 1] = "ending songs (sound/livingcity/endings/): " .. table.concat(songs, ", ")
        local url = GetConVar("sv_downloadurl")
        out[#out + 1] = "downloads: sv_downloadurl \"" .. (url and url:GetString() or "") .. "\" (players get new sounds after a FastDL sync and a map change)"
    end
    out[#out + 1] = "setup notes: " .. (#warn > 0 and "" or "none")
    for _, w in ipairs(warn) do out[#out + 1] = "  - " .. w end
    do -- why people are leaving the city (a developer's question, not a player's)
        local parts, total = {}, 0
        for why, n in pairs(LC.LeaveCounts or {}) do total = total + n parts[#parts + 1] = { why, n } end
        table.sort(parts, function(a, b) return a[2] > b[2] end)
        out[#out + 1] = string.format("people who left since the map started: %d", total)
        for _, p in ipairs(parts) do out[#out + 1] = string.format("  %d: %s", p[2], p[1]) end
    end
    for g, line in SortedPairs(LC.Lines or {}) do
        local coming = 0
        for _, st in pairs(LC.NPCs or {}) do if st.lineHeading == g then coming = coming + 1 end end
        local disp = LC.LineDispenser and LC.LineDispenser(g)
        local dnote = not IsValid(disp) and ", no dispenser by its front (a clerk hands rations out)"
            or (disp:GetNW2Bool("lc_nopower", false) and ", its dispenser has NO POWER: nobody queues for a dead dispenser" or "")
        out[#out + 1] = string.format("line %d: %d slots, %d queued, %d on their way, front waiting %ds%s%s", g, #line.slots, #line.q, coming,
            (line.q[1] and line.frontSince) and math.floor(CurTime() - line.frontSince) or 0, dnote,
            line.reversed and " (placed from the back: turned round so the front is at the dispenser)" or "")
    end

    Section(out, "NPCs")
    do -- vortigaunts: the freed ones in rebel ground, and the shackled ones on the streets
        local freed, slaves = 0, 0
        for v in pairs(LC.RebelVorts or {}) do if IsValid(v) then freed = freed + 1 end end
        for v in pairs(LC.VortSlaves or {}) do if IsValid(v) then slaves = slaves + 1 end end
        local cf, cs = GetConVar("lc_rebel_vorts"), GetConVar("lc_vort_slaves")
        local why = LC.VortHomeWhy and LC.VortHomeWhy()
        out[#out + 1] = string.format("vortigaunts: %d freed in rebel ground (lc_rebel_vorts %s)%s, %d shackled on the streets (lc_vort_slaves %s)",
            freed, cf and cf:GetString() or "?", why and (": " .. why) or "", slaves, cs and cs:GetString() or "?")
    end
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
    local reasons = {}
    for k, c in SortedPairs(LC.StuckReasons or {}) do reasons[#reasons + 1] = k .. " " .. c end
    out[#out + 1] = string.format("stuck: %d moved on a step, %d far trips given up%s", LC.StuckCount or 0, LC.GaveUp or 0,
        #reasons > 0 and (" (" .. table.concat(reasons, ", ") .. ")") or "")
    local ns = LC.NavStats
    local bad = 0
    for _, b in pairs(LC.BadDest or {}) do if b.n >= 2 and b.untilT > CurTime() then bad = bad + 1 end end
    out[#out + 1] = string.format("routes: %s, %d trips not started (unreachable), %d places skipped as hard to reach",
        ns and string.format("%d planned over the nodegraph, %d short enough to walk direct", ns.routes, ns.direct) or "no nodegraph links",
        LC.UnreachableSkips or 0, bad)
    if ns and ns.refined then
        out[#out + 1] = string.format("route repairs: %d legs walked in single steps, %d links found unwalkable (%d avoided right now), %d trips re-planned around them",
            ns.refined, ns.avoided, LC.BadLinkCount and LC.BadLinkCount() or 0, ns.replanned)
    end
    for _, r in ipairs(rows) do out[#out + 1] = r end
    if LC.NPCWorkSummary then out[#out + 1] = LC.NPCWorkSummary() end

    Section(out, "Performance")
    local p = LC.Perf or {}
    out[#out + 1] = string.format("main loop: avg %.2f ms, last %.2f ms, worst %.2f ms over %d ticks",
        (p.samples or 0) > 0 and p.total / p.samples or 0, p.last or 0, p.max or 0, p.samples or 0)
    out[#out + 1] = string.format("server tick interval %.4f, entity count %d", engine.TickInterval(), #ents.GetAll())
    local f = LC.Frame or {}
    if (f.n or 0) > 0 then
        out[#out + 1] = string.format("whole server frame (engine AI, physics, networking): avg %.2f ms, worst %.2f ms, %d of %d ticks late (%.1f%%), a tick should take %.1f ms",
            f.total / f.n, f.worst, f.slow, f.n, 100 * f.slow / f.n, engine.TickInterval() * 1000)
    end
    -- what the entities are, most first
    local byClass, list = {}, {}
    for _, e in ipairs(ents.GetAll()) do
        local c = e:GetClass()
        byClass[c] = (byClass[c] or 0) + 1
    end
    for c, n in pairs(byClass) do list[#list + 1] = { c, n } end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local top = {}
    for i = 1, math.min(15, #list) do top[#top + 1] = list[i][1] .. " " .. list[i][2] end
    out[#out + 1] = "entities by class: " .. table.concat(top, ", ")
    local npcs = 0
    for _, e in ipairs(ents.GetAll()) do if e:IsNPC() then npcs = npcs + 1 end end
    out[#out + 1] = string.format("NPCs on the map (all of them, Living City's and not): %d", npcs)
    if LC.SleepStats then
        local z = LC.SleepStats
        out[#out + 1] = string.format("asleep (far from everyone, engine AI off; lc_npc_sleep %s): %d now; %d times put to sleep, %d woken, %d route stops walked out of sight",
            GetConVar("lc_npc_sleep") and GetConVar("lc_npc_sleep"):GetString() or "?", LC.SleepingCount(), z.slept, z.woke, z.hops)
    end

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
        if LC.RunningStatus then under[#under + 1] = "running check: " .. LC.RunningStatus(pl) end
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
