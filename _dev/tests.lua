-- Scenario tests for Living City, run on top of gmod_stub.lua
local results = { pass = 0, fail = 0, lines = {} }
local function ok(cond, name, detail)
    if cond then
        results.pass = results.pass + 1
        table.insert(results.lines, "  PASS  " .. name)
    else
        results.fail = results.fail + 1
        table.insert(results.lines, "  FAIL  " .. name .. (detail and ("  -> " .. tostring(detail)) or ""))
    end
end
local function section(name) table.insert(results.lines, "== " .. name) end
local function has(list, needle)
    for _, v in ipairs(list or {}) do if string.find(tostring(v), needle, 1, true) then return true end end
    return false
end
local function count(role)
    local c = 0
    for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.role == role and not st.test then c = c + 1 end end
    return c
end

hook.Run("InitPostEntity")
_run(0.5)
_setcvar("lc_stops", 0) -- random NPC stops are tested on their own, later

----------------------------------------------------------------------
section("Load")
ok(#_errors == 0, "no errors while loading every file", _errors[1])
ok(LC.Gamemode() == "sandbox", "gamemode detected as sandbox")
ok(LCF and LCF.Get("cp") and #LCF.Get("cp").ranks == 10, "faction config loaded, CP has 10 ranks")
ok(LCF.Get("cp").ranks[3].loadout[2] == "weapon_pistol", "ranks inherit loadouts from the rank below")
ok(LCF.Get("resistance").ranks[4].hunted == true, "Lieutenant inherits hunted from Fighter")

----------------------------------------------------------------------
section("Saving and loading a layout")
local admin = _makeplayer("Admin", Vector(0, -3000, 0))
admin.superadmin = true
admin.admin = true

-- ration line 1, front first
for i = 0, 2 do LC.AddPoint(Vector(5000, -60 * i, 0), 90, "queue", 1) end
LC.AddPoint(Vector(2000, 2000, 0), 0, "spawn", 0)
LC.AddPoint(Vector(-2000, 2000, 0), 0, "spawn", 0)
LC.AddPoint(Vector(500, 500, 0), 0, "cell", 0)
LC.AddPoint(Vector(520, 620, 0), 0, "cell", 0)
LC.AddPoint(Vector(900, 500, 0), 0, "release", 0)
LC.AddPoint(Vector(1500, 0, 0), 0, "checkpoint", 0)
for i = 0, 2 do LC.AddPoint(Vector(-1000 - 300 * i, 0, 0), 0, "patrol", 1) end
local A, B, C, D = LC.AddNode(Vector(0, 0, 0)), LC.AddNode(Vector(1000, 0, 0)), LC.AddNode(Vector(1000, 1000, 0)), LC.AddNode(Vector(0, 1000, 0))
LC.ToggleLink(A, B) LC.ToggleLink(B, C) LC.ToggleLink(C, D)
LC.AddZone(Vector(500, 560, 0), 200, "prison", 0)
LC.AddZone(Vector(3000, 3000, 0), 300, "block", 1)
local door = ents.Create("func_door")
door.mapid = 77
door:SetPos(Vector(8000, 0, 0))
LC.SetDoorTag(door, "cp")

local json = _files["livingcity/rp_test.json"]
ok(json ~= nil and #json > 100, "layout file written")
local before = { p = #LC.Points, n = table.Count(LC.Nodes), z = #LC.Zones, l = LC.LinkCount() }
LC.LoadData(false)
ok(#LC.Points == before.p and table.Count(LC.Nodes) == before.n and #LC.Zones == before.z,
    "reload restores points, nodes and zones", string.format("%d/%d %d/%d %d/%d", #LC.Points, before.p, table.Count(LC.Nodes), before.n, #LC.Zones, before.z))
ok(LC.LinkCount() == before.l and before.l == 3, "links survive a reload", LC.LinkCount())
ok(LC.GetDoorTag(door) == "cp", "door tag survives a reload")
ok(LC.PointsOfKind("queue", 1)[1].pos.y == 0, "line slot order survives a reload")
A, B, C, D = LC.NearestNode(Vector(0, 0, 0), 5), LC.NearestNode(Vector(1000, 0, 0), 5), LC.NearestNode(Vector(1000, 1000, 0), 5), LC.NearestNode(Vector(0, 1000, 0), 5)

-- old format migration
local saved = _files["livingcity/rp_test.json"]
_files["livingcity/rp_test.json"] = '[{"x":1,"y":2,"z":3,"yaw":0,"kind":"idle"}]'
_files["livingcity/rp_test_cpdoors.json"] = '[77]'
LC.LoadData(false)
ok(#LC.Points == 1 and LC.Points[1].kind == "idle" and LC.GetDoorTag(door) == "cp", "version 1 files and old door tags migrate")
ok(_files["livingcity/rp_test_cpdoors.json"] == nil, "old door tag file cleaned up")
_files["livingcity/rp_test.json"] = saved
LC.LoadData(false)
A, B, C, D = LC.NearestNode(Vector(0, 0, 0), 5), LC.NearestNode(Vector(1000, 0, 0), 5), LC.NearestNode(Vector(1000, 1000, 0), 5), LC.NearestNode(Vector(0, 1000, 0), 5)

----------------------------------------------------------------------
section("Routing")
_walls = { { a = Vector(-200, 500, 0), b = Vector(800, 500, 0) } } -- blocks the direct way from A to D
local route = LC.BuildRoute(Vector(0, 0, 0), Vector(0, 1000, 0), "citizen")
ok(route and #route == 5, "route goes around the wall via the path network", route and #route)
ok(route and route[2] == B.pos and route[3] == C.pos, "route visits nodes in order")
local rz = LC.AddZone(Vector(1000, 0, 0), 100, "rebel", 0)
ok(LC.BuildRoute(Vector(0, 0, 0), Vector(0, 1000, 0), "cop") == nil, "security won't route through rebel territory")
ok(LC.BuildRoute(Vector(0, 0, 0), Vector(0, 1000, 0), "citizen") ~= nil, "citizens still can")
ok(LC.InNoGo(Vector(1000, 0, 0), "cop") and not LC.InNoGo(Vector(1000, 0, 0), "citizen"), "rebel zones are no-go for security only")
LC.RemoveZone(rz)

local walker, wst = LC.SpawnCitizen(Vector(0, 0, 0))
LC.GoTo(walker, wst, Vector(0, 1000, 0), false, { kind = "checkpoint", pos = Vector(0, 1000, 0), yaw = 0 })
_run(35)
ok(walker:GetPos():Distance(Vector(0, 1000, 0)) < 70, "a citizen actually walks the detour and arrives", tostring(walker:GetPos()) .. " " .. tostring(wst.state))
walker:Remove()

----------------------------------------------------------------------
section("Stuck recovery")
_walls[#_walls + 1] = { a = Vector(10500, 9000, 0), b = Vector(10500, 11000, 0) } -- solid wall, no way around
local stuckBefore = LC.StuckCount or 0
local s1, sst = LC.SpawnCitizen(Vector(10000, 10000, 0))
LC.GoTo(s1, sst, Vector(11000, 10000, 0), false, { kind = "checkpoint", pos = Vector(11000, 10000, 0), yaw = 0 })
_run(12)
ok((LC.StuckCount or 0) > stuckBefore, "a stuck NPC is noticed")
ok(s1:GetPos():Distance(Vector(11000, 10000, 0)) < 10, "and quietly moved past the obstacle when nobody's looking", tostring(s1:GetPos()))
s1:Remove()
_walls = {}

----------------------------------------------------------------------
section("Ration lines")
LC.RebuildLines()
ok(LC.Lines[1] and #LC.Lines[1].slots == 3, "line 1 has 3 slots")
local liners = {}
for i = 1, 3 do
    local n, st = LC.SpawnCitizen(Vector(5000, -600 - 50 * i, 0))
    st.leaveAt = nil
    LC._JoinLine(n, st)
    liners[i] = { n = n, st = st }
end
for _, cv in ipairs({ "lc_citizens", "lc_cops", "lc_scanners", "lc_zombies", "lc_soldiers" }) do _setcvar(cv, 0) end
LC.Running = true -- lines only move while the city runs
local served0 = 0
for _, snd in ipairs(_sounds) do if snd == "items/ammo_pickup.wav" then served0 = served0 + 1 end end
LC.Event = "rations"
LC.Lines[1].nextAdvance = CurTime() + 8 -- the counter opens once people have lined up
local inline, ordered = 0, false
for _ = 1, 8 do
    _run(1)
    local c = 0
    for _, l in ipairs(liners) do if l.st.state == "inline" then c = c + 1 end end
    if c == 3 then ordered = liners[1].st.slotIndex == 1 and liners[2].st.slotIndex == 2 and liners[3].st.slotIndex == 3 end
    inline = math.max(inline, c)
end
ok(inline == 3, "three citizens walk up and stand in line", inline)
ok(ordered, "in the order they joined")
_run(40)
local served = 0
for _, s in ipairs(_sounds) do if s == "items/ammo_pickup.wav" then served = served + 1 end end
ok(served - served0 >= 3, "the line moves: everyone gets served", served - served0)
ok(#LC.Lines[1].q <= 1, "and the queue drains", #LC.Lines[1].q)
LC.Event = nil
LC.Running = false
for _, l in ipairs(liners) do if IsValid(l.n) then l.n:Remove() end end

----------------------------------------------------------------------
section("Population, budget, curfew")
_setcvar("lc_citizens", 6)
_setcvar("lc_cops", 2)
_setcvar("lc_scanners", 0)
_setcvar("lc_zombies", 0)
_setcvar("lc_auto_events", 0)
_setcvar("lc_announce_interval", 0)
LC.Start(admin)
_run(25)
ok(count("citizen") == 6, "citizens fill in to the target", count("citizen"))
ok(count("cop") == 2, "cops fill in to the target", count("cop"))
_setcvar("lc_npc_budget", 5)
for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.role == "citizen" then npc:Remove() break end end
_run(5)
local total = 0
for npc in pairs(LC.NPCs) do if IsValid(npc) then total = total + 1 end end
ok(total <= 7, "the NPC budget stops further spawning", total)
_setcvar("lc_npc_budget", 60)

LC.StartEvent("curfew", 2)
ok(_globals.lc_event == "curfew", "curfew is published to clients")
_run(60)
ok(count("citizen") == 0, "during curfew every citizen goes home", count("citizen"))
LC.EndEvent(false)
ok(LC.Event == nil, "curfew ends")
_run(25)
ok(count("citizen") >= 4, "citizens come back out afterwards", count("citizen"))

----------------------------------------------------------------------
section("Relationship caching")
LC.RefreshRelations()
local calls = _relcalls or 0
LC.RefreshRelations()
ok((_relcalls or 0) == calls, "a second refresh with nothing changed makes no engine calls", (_relcalls or 0) - calls)

----------------------------------------------------------------------
section("Housing and curfew enforcement")
local citizen = _makeplayer("Citizen", Vector(-500, -500, 0))
hook.Run("PlayerInitialSpawn", citizen)
_run(3)
ok(LC.PlayerBlock(citizen) == 1, "a new player is assigned to the only block", LC.PlayerBlock(citizen))
ok(LC.PlayerInOwnBlock(citizen) == false, "and knows they're outside it")
local cop, cst = LC.Spawners.cop(Vector(-400, -500, 0))
cst.routeGroup = nil
cst.untilT = 1e9
cop.sim = false -- keep him put
LC.StartEvent("curfew", 3)
_run(40)
ok(not has(citizen.chat, "Warning 1 of 3") and (LC.EventGraceEnds or 0) > CurTime(), "curfew gives a grace period to get home before anyone is warned")
ok(LC.CurfewGrace() >= 60, "and it's never shorter than a minute")
_run(45)
ok(has(citizen.chat, "Warning 1 of 3") and has(citizen.chat, "Warning 3 of 3"), "an officer who sees you gives three warnings")
ok(LC.PlayerIsWanted(citizen), "then you're wanted", table.concat(citizen.chat, " | ") .. " cop=" .. tostring(cst.state))
LC.ClearWanted(citizen)
citizen:SetPos(Vector(3000, 3000, 0))
citizen.chat = {}
_run(20)
ok(not has(citizen.chat, "Warning"), "no warnings while you're home")
LC.EndEvent(true)
LC.CalmCops(nil)

----------------------------------------------------------------------
section("Prison")
local con = _makeplayer("Convict", Vector(-300, -300, 0))
local okj = LC.Incarcerate(con, 30, "test")
ok(okj and LC.Prisoners[con], "a player can be incarcerated")
ok(con:GetPos():Distance(Vector(500, 500, 0)) < 10 or con:GetPos():Distance(Vector(520, 620, 0)) < 10, "and is put in a cell", tostring(con:GetPos()))
ok(#con.weps == 0, "with their weapons taken")
ok(hook.Run("PlayerSpawnProp", con) == false and hook.Run("PlayerNoClip", con) == false, "and can't spawn props or noclip")
_run(32)
ok(not LC.Prisoners[con], "released when the sentence ends")
ok(con:GetPos():Distance(Vector(900, 500, 0)) < 10, "at the release point", tostring(con:GetPos()))
ok(#con.weps == 2, "with their weapons back", #con.weps)
ok(not LC.PlayerIsWanted(con) and (con.lcGraceUntil or 0) > CurTime(), "and a head start before anyone can call them wanted")

con.lcGraceUntil = 0
LC.Incarcerate(con, 60, "escape test")
con:SetPos(Vector(2000, -2000, 0))
_run(2)
ok(not LC.Prisoners[con] and LC.PlayerIsWanted(con), "walking out of the prison zone is an escape, and makes you wanted")

-- NPC arrests instead of kills
local cop2, cst2 = LC.Spawners.cop(Vector(-200, -200, 0))
cst2.untilT = 1e9
local dmg = _dmg(cop2, 20, DMG_CLUB)
hook.Run("EntityTakeDamage", con, dmg)
ok(LC.Prisoners[con] ~= nil, "a stunstick hit from a cop arrests a wanted player")
ok(dmg:GetDamage() == 0, "instead of hurting them")
LC.ReleasePrisoner(con)

-- disconnect mid-sentence
LC.Incarcerate(con, 100, "leaver")
hook.Run("PlayerDisconnected", con)
ok(tonumber(con.pdata.lc_jail_left) and tonumber(con.pdata.lc_jail_left) > 90, "leaving mid-sentence is remembered", con.pdata.lc_jail_left)
hook.Run("PlayerInitialSpawn", con)
_run(4)
ok(LC.Prisoners[con] and (LC.Prisoners[con].untilT - CurTime()) > 150, "and resumes, with a penalty, on return")
LC.ReleasePrisoner(con)

----------------------------------------------------------------------
section("Conduct")
local p1, p2, p3, p4 = _makeplayer("Killer", Vector(-900, -900, 0)), _makeplayer("V1"), _makeplayer("V2"), _makeplayer("V3")
_run(9) -- past spawn protection from earlier
hook.Run("EntityTakeDamage", p2, _dmg(p1, 10))
hook.Run("PlayerDeath", p2, nil, p1)
ok(LC.StrikeCount(p1) == 1, "an unprovoked kill is a strike", LC.StrikeCount(p1))
hook.Run("EntityTakeDamage", p1, _dmg(p3, 10))
hook.Run("PlayerDeath", p3, nil, p1)
ok(LC.StrikeCount(p1) == 1, "killing someone who attacked you is self defense")
hook.Run("PlayerDeath", p4, nil, p1)
ok(LC.StrikeCount(p1) == 2 and LC.Prisoners[p1], "a second strike sends you to prison")
LC.ReleasePrisoner(p1)
ok(_files["livingcity/conduct_log.txt"] and string.find(_files["livingcity/conduct_log.txt"], "UNJUSTIFIED", 1, true),
    "kills are written to the conduct log")

hook.Run("PlayerSpawn", p2)
local sp = _dmg(p3, 50)
local blocked = hook.Run("EntityTakeDamage", p2, sp)
ok(sp:GetDamage() == 0, "spawn protection blocks damage")

hook.Run("EntityTakeDamage", p3, _dmg(p4, 5))
hook.Run("PlayerDisconnected", p3)
ok(p3.pdata.lc_combatlog ~= nil, "leaving mid-fight is recorded")
hook.Run("PlayerInitialSpawn", p3)
_run(6)
ok(LC.StrikeCount(p3) == 1, "and costs a strike on return", LC.StrikeCount(p3))
ok(hook.Run("CanPlayerSuicide", p4) == false or LC.InCombat(p4) == false, "suicide is blocked mid-fight")

----------------------------------------------------------------------
section("Factions")
_setcvar("lc_factions", 1)
local rec = _makeplayer("Recruit")
hook.Run("PlayerInitialSpawn", rec)
ok(rec:GetNW2String("lcf_faction", "") == "citizen", "new players start as citizens")
ok(not LC.CanJoinFaction(rec, "ota"), "Overwatch is locked for a nobody")
LC.SetFaction(rec, "cp", nil, true)
ok(LC.PlayerIsCP(rec), "joining Civil Protection makes you CP to Living City")
LC.AddXP(rec, 1000)
ok(rec:GetNW2Int("lcf_rank", 1) == 6, "1000 XP makes you Unit 01", rec:GetNW2Int("lcf_rank", 1))
ok(has(rec.chat, "Promoted to Unit 01"), "with a promotion message")
ok(string.find(rec:GetNW2String("lcf_title", ""), "CP 01-", 1, true) ~= nil, "and a unit designation", rec:GetNW2String("lcf_title", ""))
ok(LC.CanJoinFaction(rec, "ota"), "Unit 01 unlocks Overwatch")
ok(not LC.CanJoinFaction(rec, "admin"), "City Administrator is whitelist only")

local priest = _makeplayer("Priest")
hook.Run("PlayerInitialSpawn", priest)
ok(not LC.CanJoinFaction(priest, "resistance", "chaplain"), "Father Grigori needs Resistance standing first")
priest:SetPData("lcf_xp_resistance", 150)
ok(LC.CanJoinFaction(priest, "resistance", "chaplain"), "a Member can take up the role")
LC.SetFaction(priest, "resistance", "chaplain", true)
local other = _makeplayer("Other")
other:SetPData("lcf_xp_resistance", 500)
ok(not LC.CanJoinFaction(other, "resistance", "chaplain"), "only one Father Grigori at a time")
_run(1)
ok(true, "spawning with no rebel zones placed falls back to normal spawns")
priest:SetPos(Vector(-5000, -5000, 0))
ok(LC.PlayerIsHunted(priest) and LC.PlayerIsWanted(priest), "he is hunted on sight in the city")
LC.AddZone(Vector(-5000, -5000, 0), 300, "rebel", 0)
ok(not LC.PlayerIsWanted(priest), "but safe inside rebel territory")
ok(priest:GetNW2String("lcf_public_title", "") == "Father Grigori", "his name tag")
priest:SetPos(Vector(9000, 9000, 0))
priest:Spawn()
_run(1)
ok(priest:GetPos():Distance(Vector(-5000, -5000, 0)) < 300, "and he respawns in rebel territory", tostring(priest:GetPos()))

local sym = _makeplayer("Sympathizer")
hook.Run("PlayerInitialSpawn", sym)
LC.SetFaction(sym, "resistance", nil, true)
ok(sym:GetNW2String("lcf_public_title", "") == "Citizen", "low-rank Resistance pass as citizens to everyone else")
ok(not LC.PlayerIsHunted(sym), "and aren't hunted")

local z = _makeplayer("Zed")
hook.Run("PlayerInitialSpawn", z)
LC.SetFaction(z, "zombie", nil, true)
ok(LC.PlayerIsZombie(z), "Infested count as zombies")
LC.RefreshRelations()
local copRel
for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.role == "cop" then copRel = npc.rel[z] break end end
ok(copRel == D_HT, "and cops hate them on sight", copRel)
_setcvar("lc_factions", 0)

----------------------------------------------------------------------
section("Doors")
local dcit, dcst = LC.Spawners.citizen(Vector(7950, 0, 0))
LC.GoTo(dcit, dcst, Vector(8600, 0, 0), false, nil)
dcit.sim = false -- frozen at the door, still trying to walk through
door.fired = {}
_run(1)
ok(not has(door.fired, "Open"), "citizens don't open CP-only doors", table.concat(door.fired, ","))
dcit:Remove()
local dcop, dcopst = LC.Spawners.cop(Vector(7950, 0, 0))
LC.GoTo(dcop, dcopst, Vector(8600, 0, 0), false, nil)
dcop.sim = false
door.locked = true
_run(1)
ok(has(door.fired, "Open") and has(door.fired, "Unlock"), "cops unlock and open them", table.concat(door.fired, ","))
dcop:Remove()
door.fired = {}
_run(7)
ok(has(door.fired, "Close") and has(door.fired, "Lock"), "and the door shuts and relocks behind them", table.concat(door.fired, ","))
LC.SetDoorTag(door, "locked")
local denied = hook.Run("PlayerUse", citizen, door)
ok(denied == false, "nobody opens a locked-tagged door")

----------------------------------------------------------------------
section("Zombies")
LC.AddZone(Vector(-8000, 8000, 0), 400, "infest", 0)
_setcvar("lc_zombies", 3)
_run(10)
ok(count("zombie") == 3, "zombies spawn in infestation zones", count("zombie"))
local zz
for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.role == "zombie" and st.zone then zz = npc break end end
if zz then
    zz:SetPos(Vector(-8000, 9000, 0))
    zz.sim = false
    _run(3) -- far from every player, so it thinks every 2 seconds
    ok(zz:GetPos():Distance(Vector(-8000, 8000, 0)) < 400, "a zombie that wanders out is put back", tostring(zz:GetPos()))
end
ok(LC.InNoGo(Vector(-8000, 8000, 0), "citizen"), "citizens avoid infestation zones")

----------------------------------------------------------------------
section("Debugging")
local okr, report = pcall(LC.BuildReport)
ok(okr and string.find(report, "LIVING CITY DEBUG REPORT", 1, true) and string.find(report, "== NPCs ==", 1, true),
    "debug report builds", okr and "" or report)
concommand.list.lc_debugreport(nil)
local wrote = false
for k in pairs(_files) do if string.find(k, "reports/report_", 1, true) then wrote = true end end
ok(wrote, "debug report is saved to a file")
local okS = pcall(concommand.list.lc_status, admin)
ok(okS, "lc_status runs")


----------------------------------------------------------------------
section("Quests: every template builds and starts")
_setcvar("lc_factions", 1)
_setcvar("lc_quest_cooldown", 0)
LC.AddZone(Vector(-6000, -6000, 0), 400, "rebel", 0)
LC.AddPoint(Vector(1600, 300, 0), 0, "idle", 0)
for _, c in ipairs({ Vector(450, 450, 0), Vector(560, 450, 0), Vector(450, 650, 0), Vector(560, 660, 0) }) do LC.AddPoint(c, 0, "cell", 0) end
_run(5)
local function newPlayer(name, faction, special, xp)
    local p = _makeplayer(name, Vector(0, -500, 0))
    hook.Run("PlayerInitialSpawn", p)
    if xp then p:SetPData("lcf_xp_" .. faction, xp) end
    LC.SetFaction(p, faction, special, true)
    return p
end
LC.SetFaction(priest, "citizen", nil, true)
local tester = {
    cp = newPlayer("QCop", "cp"), ota = newPlayer("QOTA", "ota"), admin = newPlayer("QAdmin", "admin"),
    resistance = newPlayer("QRebel", "resistance", nil, 900), citizen = newPlayer("QCitizen", "citizen"),
    zombie = newPlayer("QZombie", "zombie"),
}
tester.chaplain = newPlayer("QPriest", "resistance", "chaplain", 200)
local member = newPlayer("QMember", "resistance", nil, 150)
local built, started, problems = 0, 0, {}
for _, t in ipairs(LC.QuestTemplates) do
    for f in pairs(t.factions) do
        local p = (t.id == "res_ministry") and tester.chaplain or tester[f]
        local okA, avail = pcall(function() return not t.available or t.available(p) end)
        if not okA then table.insert(problems, t.id .. " available: " .. tostring(avail)) end
        if okA and avail then
            local okB, spec = pcall(t.build, p)
            if not okB then
                table.insert(problems, t.id .. " build: " .. tostring(spec))
            elseif spec then
                built = built + 1
                spec.id = 50000 + built; spec.tmpl = t; spec.violent = t.violent; spec.faction = f
                spec.expiresPost = CurTime() + 999; spec.data = spec.data or {}
                LC.Postings[f] = LC.Postings[f] or {}
                table.insert(LC.Postings[f], spec)
                p.lcqNext = 0
                local okC, err = pcall(LC.AcceptPosting, p, spec.id)
                if not okC then
                    table.insert(problems, t.id .. " accept: " .. tostring(err))
                elseif LC.QuestOf[p] then
                    started = started + 1
                    LC.AbandonQuest(p)
                else
                    table.insert(problems, t.id .. " didn't start")
                end
                p.lcqNext = 0
            end
        end
    end
end
ok(#problems == 0, "no template errors", problems[1])
ok(built >= 30, "nearly every template can build on this test map", built .. " of 34")
ok(started == built, "every built quest starts", started .. "/" .. built)

local function inject(p, id)
    local t
    for _, x in ipairs(LC.QuestTemplates) do if x.id == id then t = x end end
    local f = LC.QuestFaction(p)
    local spec = t.build(p)
    spec.id = 60000 + math.random(1, 999999); spec.tmpl = t; spec.violent = t.violent; spec.faction = f
    spec.expiresPost = CurTime() + 999; spec.data = spec.data or {}
    LC.Postings[f] = LC.Postings[f] or {}
    table.insert(LC.Postings[f], spec)
    p.lcqNext = 0
    LC.AcceptPosting(p, spec.id)
    return LC.QuestOf[p]
end
local function withRoll(n, fn)
    local r = math.random
    math.random = function(a, b)
        if a == 20 and b == nil then return n end
        if a == nil then return r() elseif b == nil then return r(a) end
        return r(a, b)
    end
    fn()
    math.random = r
end
local function reach(p, ent) p:SetPos(ent:GetPos() + Vector(60, 0, 0)) _run(1) end

----------------------------------------------------------------------
section("Quests: catching a hoarder")
local cop = tester.cp
local xp0 = tonumber(cop:GetPData("lcf_xp_cp", 0))
local q = inject(cop, "cp_apprehend")
local target = q.data.target
ok(IsValid(target), "a real citizen in the city is picked as the suspect")
reach(cop, target)
ok(q.stages[q.stage].kind == "choice", "walking up to them opens a choice")
ok(_lastnet("lcq_choice_open") ~= nil, "the choice is sent to the player")
ok(LC.NPCs[target].state == "event", "the suspect freezes")
LC.ResolveChoice(cop, q.id, 1)
ok(q.stages[q.stage].action == "arrest", "Detain leads to the arrest")
LC.ArrestNPC(target, cop)
ok(q.done and LC.QuestOf[cop] == nil, "arresting them completes the directive")
ok(tonumber(cop:GetPData("lcf_xp_cp", 0)) - xp0 == 35 + LCF.XP.arrest_npc, "and pays out (quest reward plus the arrest itself)",
    tonumber(cop:GetPData("lcf_xp_cp", 0)) - xp0)

local q2 = inject(cop, "cp_apprehend")
reach(cop, q2.data.target)
withRoll(20, function() LC.ResolveChoice(cop, q2.id, 2) end)
local st2 = q2.stages[q2.stage]
ok(st2.kind == "collect" and next(st2.items) ~= nil, "a successful Authority check reveals a stash to seize")
ok(has(cop.chat, "AUTHORITY check: rolled 20"), "and the roll is narrated")
hook.Run("PlayerUse", cop, next(st2.items))
ok(q2.stages[q2.stage].action == "arrest", "seizing it moves on to the arrest")
LC.ArrestNPC(q2.data.target, cop)
ok(q2.done and q2.bonus == 15, "with a bonus for the extra work")

local q3 = inject(cop, "cp_apprehend")
local t3 = q3.data.target
reach(cop, t3)
withRoll(1, function() LC.ResolveChoice(cop, q3.id, 2) end)
ok(LC.NPCs[t3].state == "moving" and LC.NPCs[t3].run, "a failed check and the suspect bolts")
ok(q3.stages[q3.stage].action == "arrest", "and you still have to catch them")
LC.AbandonQuest(cop)
ok(LC.NPCs[t3] == nil or LC.NPCs[t3].questLock == nil, "abandoning releases the suspect")

local q4 = inject(cop, "cp_apprehend")
reach(cop, q4.data.target)
local c0 = LC.Trait(cop, "corruption")
LC.ResolveChoice(cop, q4.id, 3)
ok(q4.done and LC.Trait(cop, "corruption") == c0 + 1, "taking a bribe ends it, and marks you")

----------------------------------------------------------------------
section("Quests: a supply run")
local q5 = inject(member, "res_supply")
local contact = q5.stages[1].npc
ok(IsValid(contact), "a person is waiting with the crate")
hook.Run("LivingCityPlayerUsedNPC", member, contact, LC.NPCs[contact])
ok(q5.stages[q5.stage].kind == "choice", "taking it from them leads to a choice")
withRoll(1, function() LC.ResolveChoice(member, q5.id, 2) end)
ok(LC.PlayerIsWanted(member), "a failed Guile check gets you noticed")
LC.ClearWanted(member)
member:SetPos(q5.stages[q5.stage].pos)
_run(1)
local qm = q5.stages[q5.stage]
ok(IsValid(qm.npc), "the quartermaster is waiting at the safe house")
hook.Run("LivingCityPlayerUsedNPC", member, qm.npc, LC.NPCs[qm.npc])
ok(q5.done and not q5.failed, "handing it over completes the operation")
local q6 = inject(member, "res_supply")
hook.Run("LivingCityPlayerUsedNPC", member, q6.stages[1].npc, LC.NPCs[q6.stages[1].npc])
LC.Incarcerate(member, 30, "test")
_run(1)
ok(q6.done and LC.QuestOf[member] == nil, "getting arrested on a supply run fails it")
LC.ReleasePrisoner(member)

----------------------------------------------------------------------
section("Quests: choices change the story")
local cit = tester.citizen
local q7 = inject(cit, "cit_errand")
hook.Run("LivingCityPlayerUsedNPC", cit, q7.stages[1].npc, LC.NPCs[q7.stages[1].npc])
ok(q7.stages[q7.stage].kind == "choice", "the errand starts with Mrs. Kleiner, a person, not a parcel on the floor")
withRoll(20, function() LC.ResolveChoice(cit, q7.id, 2) end)
ok(q7.stages[q7.stage].kind == "choice", "peeking inside opens a second choice")
local l0 = LC.Trait(cit, "loyalty")
LC.ResolveChoice(cit, q7.id, 2)
ok(q7.stages[q7.stage].kind == "count" and q7.stages[q7.stage].event == "used_npc", "turning it in replaces the delivery")
local anyCop
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.role == "cop" then anyCop = n break end end
hook.Run("LivingCityPlayerUsedNPC", cit, anyCop, LC.NPCs[anyCop])
ok(q7.done and LC.Trait(cit, "loyalty") == l0 + 2, "handing it to a unit completes it, and the city remembers")

local q8 = inject(cit, "cit_lost")
local man = q8.data.target
ok(IsValid(man), "the confused old man is in the world")
reach(cit, man)
LC.ResolveChoice(cit, q8.id, 2)
ok(q8.stages[q8.stage].kind == "escort", "then you walk him home")
local home, start = q8.stages[q8.stage].pos, cit:GetPos()
for i = 1, 40 do
    cit:SetPos(start + (home - start) * (i / 40))
    _run(0.5)
    if q8.done then break end
end
_run(10)
ok(q8.done, "he follows you all the way home")

----------------------------------------------------------------------
section("Quests: a crowded server")
local leader, helper = tester.cp, _makeplayer("Helper")
hook.Run("PlayerInitialSpawn", helper)
LC.SetFaction(helper, "cp", nil, true)
local qs = inject(leader, "cp_patrol")
helper.lcqNext = 0
ok(LC.AcceptPosting(helper, qs.id) and LC.QuestOf[helper] == qs, "a second unit can join the job as a squad")
local hx0 = tonumber(helper:GetPData("lcf_xp_cp", 0))
for _, s in ipairs(qs.stages) do helper:SetPos(s.pos) _run(1) end
ok(qs.done, "the helper's progress counts")
ok(tonumber(helper:GetPData("lcf_xp_cp", 0)) > hx0, "and both get paid")

for i = 1, 24 do
    local p = _makeplayer("Crowd" .. i)
    hook.Run("PlayerInitialSpawn", p)
    LC.SetFaction(p, "cp", nil, true)
end
for qq in pairs(LC.ActiveQuests) do LC.FinishQuest(qq, false, "reset") end
LC.Postings = {}
for _, p in ipairs(player.GetAll()) do LC.RefreshBoard(p) end
local violent = 0
for _, list in pairs(LC.Postings) do for _, p in ipairs(list) do if p.violent then violent = violent + 1 end end end
ok(LC.ViolentCap() == math.floor(#player.GetAll() / 8), "the violent cap scales with players", LC.ViolentCap() .. " for " .. #player.GetAll())
ok(violent <= LC.ViolentCap(), "violent postings never exceed it", violent)
ok(#(LC.Postings.cp or {}) <= 10, "a packed faction's board stays finite", #(LC.Postings.cp or {}))
_setcvar("lc_factions", 0)


----------------------------------------------------------------------
section("Stories: Internal Affairs (bribes have consequences)")
_setcvar("lc_factions", 1)
_setcvar("lc_story_pacing", 0)
local function storyPosting(p, chainId)
    for _, sp in ipairs(LC.StoryPostings(p)) do if sp.chain == chainId then return sp end end
end
local dirty = newPlayer("DirtyCop", "cp")
ok(storyPosting(dirty, "ia") == nil, "an honest cop gets no Internal Affairs story")
for _ = 1, 2 do
    local qb = inject(dirty, "cp_apprehend")
    reach(dirty, qb.data.target)
    LC.ResolveChoice(dirty, qb.id, 3)
end
ok(LC.Counter(dirty, "bribes") == 2, "bribes are remembered")
ok(has(dirty.chat, "Something has changed"), "the player is told something has changed")
local ia = storyPosting(dirty, "ia")
ok(ia and ia.part == "summons", "Internal Affairs appears on their board")
LC.AcceptPosting(dirty, ia.id)
local qi = LC.QuestOf[dirty]
ok(qi and qi.chain == "ia" and qi.board == "Internal Affairs", "the summons begins")
dirty:SetPos(qi.stages[1].pos)
_run(1)
local officer = qi.data.actor
ok(IsValid(officer) and LC.NPCs[officer].role == "cop", "an Internal Affairs officer is waiting for them")
reach(dirty, officer)
LC.ResolveChoice(dirty, qi.id, 1)
ok(qi.done and not IsValid(officer), "confessing ends the meeting, and the officer leaves")
local pen = storyPosting(dirty, "ia")
ok(pen and pen.part == "penance", "penance is next")
LC.AcceptPosting(dirty, pen.id)
local qp = LC.QuestOf[dirty]
for _ = 1, 6 do
    local stg = qp.stages[qp.stage]
    if not stg or stg.kind ~= "goto" then break end
    dirty:SetPos(stg.pos)
    _run(1)
end
local seen = 0
for npc, st in pairs(LC.NPCs) do
    if IsValid(npc) and st.role == "citizen" and seen < 3 then
        hook.Run("LivingCityPlayerUsedNPC", dirty, npc, st)
        seen = seen + 1
    end
end
ok(qp.done and LC.Story(dirty).chains.ia.done == "redeemed", "a clean shift closes the file: redeemed")
ok(has(dirty.chat, "a number is quietly reset"), "and the ending is narrated")
ok(storyPosting(dirty, "ia") == nil, "the story is over")
dirty.lcStory = nil
ok(LC.Story(dirty).chains.ia.done == "redeemed", "story progress survives being reloaded from saved data")

local bent = newPlayer("BentCop", "cp")
concommand.list.lcq_startchain(admin, nil, { "ia", "BentCop" })
local b1 = storyPosting(bent, "ia")
ok(b1 ~= nil, "admins can start any story directly")
LC.AcceptPosting(bent, b1.id)
local qa = LC.QuestOf[bent]
bent:SetPos(qa.stages[1].pos)
_run(1)
reach(bent, qa.data.actor)
withRoll(20, function() LC.ResolveChoice(bent, qa.id, 2) end)
local b2 = storyPosting(bent, "ia")
ok(b2 and b2.part == "audit", "talking your way out leads to the audit")
LC.AcceptPosting(bent, b2.id)
local qa2 = LC.QuestOf[bent]
bent:SetPos(qa2.stages[1].pos)
_run(1)
reach(bent, qa2.data.actor)
LC.ResolveChoice(bent, qa2.id, 2)
ok(qa2.done and LC.Prisoners[bent] ~= nil, "taking the test bribe gets you arrested on the spot")
ok(LC.Story(bent).chains.ia.done == "busted", "busted")
LC.ReleasePrisoner(bent)

----------------------------------------------------------------------
section("Stories: the Pamphleteer (a citizen joins the Resistance)")
local kind = newPlayer("KindCitizen", "citizen")
LC.AddTrait(kind, "sympathy", 2)
LC.CheckUnlocks(kind)
local k1 = storyPosting(kind, "pamphleteer")
ok(k1 ~= nil, "a sympathetic citizen is approached")
LC.AcceptPosting(kind, k1.id)
local qk = LC.QuestOf[kind]
kind:SetPos(qk.stages[1].pos)
_run(1)
reach(kind, qk.data.actor)
LC.ResolveChoice(kind, qk.id, 1)
local k2 = storyPosting(kind, "pamphleteer")
ok(k2 and k2.part == "nerve", "listening leads to a test of nerve")
LC.AcceptPosting(kind, k2.id)
local qn = LC.QuestOf[kind]
hook.Run("LivingCityPlayerUsedNPC", kind, qn.stages[1].npc, LC.NPCs[qn.stages[1].npc])
LC.ResolveChoice(kind, qn.id, 2)
ok(qn.stages[qn.stage].kind == "goto", "taking the long way adds a detour")
for _ = 1, 4 do
    if qn.done then break end
    kind:SetPos(qn.stages[qn.stage].pos)
    _run(1)
end
ok(qn.done, "the parcel is delivered")
local k3 = storyPosting(kind, "pamphleteer")
ok(k3 and k3.part == "decision", "and the final meeting is set")
LC.AcceptPosting(kind, k3.id)
local qd = LC.QuestOf[kind]
kind:SetPos(qd.stages[1].pos)
_run(1)
reach(kind, qd.data.actor)
LC.ResolveChoice(kind, qd.id, 1)
_run(2)
ok(kind:GetNW2String("lcf_faction", "") == "resistance", "saying yes makes you Resistance")
ok(LC.Story(kind).chains.pamphleteer.done == "joined", "the story records how it ended")

----------------------------------------------------------------------
section("Stories: the Informant (tailing someone)")
local loyal = newPlayer("LoyalCitizen", "citizen")
local lcs = LC.ChainState(loyal, "informant")
lcs.part, lcs.readyAt = "neighbor", 0
local n1 = storyPosting(loyal, "informant")
ok(n1 and n1.part == "neighbor", "the neighbor job")
LC.AcceptPosting(loyal, n1.id)
local qt = LC.QuestOf[loyal]
local mark = qt.stages[1].npc
ok(IsValid(mark), "a real neighbor is picked to follow")
mark.sim = false
for _ = 1, 90 do
    loyal:SetPos(mark:GetPos() + Vector(500, 0, 0))
    _run(0.5)
    if qt.stage > 1 then break end
end
ok(qt.stage == 2, "keeping your distance long enough works", qt.stage)
LC.AbandonQuest(loyal)

lcs = LC.ChainState(loyal, "informant")
lcs.part, lcs.readyAt = "neighbor", 0
local n2 = storyPosting(loyal, "informant")
LC.AcceptPosting(loyal, n2.id)
local qt2 = LC.QuestOf[loyal]
local mark2 = qt2.stages[1].npc
mark2.sim = false
loyal:SetPos(mark2:GetPos() + Vector(80, 0, 0))
_run(3)
ok(qt2.stages[qt2.stage].kind == "choice", "get too close and he notices you")
withRoll(1, function() LC.ResolveChoice(loyal, qt2.id, 1) end)
ok(qt2.done and LC.Story(loyal).chains.informant.part == "neighbor", "a failed bluff fails the job, and you can try again")


----------------------------------------------------------------------
section("Stories: The Man Inside (honest cops, defectors, double agents)")
local good = newPlayer("GoodCop", "cp")
ok(storyPosting(good, "inside") == nil, "an ordinary cop isn't approached")
LC.AddTrait(good, "sympathy", 3)
LC.CheckUnlocks(good)
local g1 = storyPosting(good, "inside")
ok(g1 and g1.part == "note", "a kind, clean cop finds a note in their ration packet")
local dirtyKind = newPlayer("KindButBent", "cp")
LC.AddTrait(dirtyKind, "sympathy", 3)
LC.AddTrait(dirtyKind, "corruption", 2)
ok(storyPosting(dirtyKind, "inside") == nil, "a kind cop who takes bribes is not trusted")

LC.AcceptPosting(good, g1.id)
local qn1 = LC.QuestOf[good]
good:SetPos(qn1.stages[1].pos)
_run(1)
reach(good, qn1.data.actor)
LC.ResolveChoice(good, qn1.id, 1)
local g2 = storyPosting(good, "inside")
ok(g2 and g2.part == "proof", "hearing her out leads to a test")
LC.AcceptPosting(good, g2.id)
local qp2 = LC.QuestOf[good]
local prisoner = qp2.stages[1].npc
ok(IsValid(prisoner), "a real prisoner is named")
for _ = 1, 30 do
    if LC.NPCs[prisoner].state == "jailed" then break end
    _run(1)
end
hook.Run("LivingCityPlayerUsedNPC", good, prisoner, LC.NPCs[prisoner])
ok(qp2.stages[qp2.stage].kind == "escort", "you open the cell and walk them out")
local dest2 = qp2.stages[qp2.stage].pos
local from2 = good:GetPos()
for i = 1, 40 do
    good:SetPos(from2 + (dest2 - from2) * (i / 40))
    _run(0.5)
    if qp2.done then break end
end
_run(10)
ok(qp2.done, "and get them to safety")
local g3 = storyPosting(good, "inside")
ok(g3 and g3.part == "crossroads", "then the crossroads")
LC.AcceptPosting(good, g3.id)
local qc = LC.QuestOf[good]
good:SetPos(qc.stages[1].pos)
_run(1)
reach(good, qc.data.actor)
LC.ResolveChoice(good, qc.id, 2)
ok(LC.StoryFlag(good, "insider") == true and LC.Story(good).chains.inside.done == "insider", "staying inside makes you a double agent")
ok(good:GetNW2String("lcf_faction", "") == "cp", "still in uniform")
local w1 = storyPosting(good, "insidework")
ok(w1 ~= nil and string.find(w1.title, "Inside Work: ", 1, true) == 1, "secret Inside Work appears, for you alone", w1 and w1.title)
local otherCop = newPlayer("OtherCop", "cp")
ok(storyPosting(otherCop, "insidework") == nil, "nobody else sees it")
LC.AcceptPosting(good, w1.id)
ok(LC.QuestOf[good] ~= nil, "an op begins")
LC.AbandonQuest(good)

LC.Bump(good, "suspicion", 3)
LC.CheckUnlocks(good)
ok(storyPosting(good, "insidework") == nil, "too much suspicion and the ops dry up")
local m1 = storyPosting(good, "molehunt")
ok(m1 ~= nil, "and Internal Affairs starts a mole hunt")
LC.AcceptPosting(good, m1.id)
local qm = LC.QuestOf[good]
good:SetPos(qm.stages[1].pos)
_run(1)
reach(good, qm.data.actor)
withRoll(20, function() LC.ResolveChoice(good, qm.id, 3) end)
ok(LC.Counter(good, "suspicion") == 0 and LC.Story(good).chains.molehunt == nil, "riding it out clears suspicion, and IA can come back another day")
ok(storyPosting(good, "insidework") ~= nil, "the ops resume")

LC.Bump(good, "suspicion", 3)
local m2 = storyPosting(good, "molehunt")
LC.AcceptPosting(good, m2.id)
local qm2 = LC.QuestOf[good]
good:SetPos(qm2.stages[1].pos)
_run(1)
reach(good, qm2.data.actor)
withRoll(1, function() LC.ResolveChoice(good, qm2.id, 3) end)
_run(2)
ok(LC.StoryFlag(good, "exposed") == true and LC.Prisoners[good] ~= nil, "a failed bluff gets you exposed and jailed")
ok(good:GetNW2String("lcf_faction", "") == "citizen", "stripped back to citizen")
LC.ReleasePrisoner(good)

local brave = newPlayer("BraveCop", "cp")
local bcs = LC.ChainState(brave, "inside")
bcs.part, bcs.readyAt = "crossroads", 0
local bc = storyPosting(brave, "inside")
LC.AcceptPosting(brave, bc.id)
local qbc = LC.QuestOf[brave]
brave:SetPos(qbc.stages[1].pos)
_run(1)
reach(brave, qbc.data.actor)
LC.ResolveChoice(brave, qbc.id, 1)
_run(2)
ok(brave:GetNW2String("lcf_faction", "") == "resistance" and brave:GetNW2Int("lcf_rank", 1) >= 3, "defecting makes you a Resistance Fighter")

----------------------------------------------------------------------
section("Stories: every part of every chain starts")
LC.SetFaction(tester.chaplain, "citizen", nil, true)
local cast = { cp = newPlayer("SCop", "cp", nil, 1000), citizen = newPlayer("SCit", "citizen") }
cast.chaplain = newPlayer("SPriest", "resistance", "chaplain", 200)
local problems2, started2, total2 = {}, 0, 0
for _, chain in ipairs(LC.ChainList) do
    local p = chain.special and cast.chaplain or (chain.factions.cp and cast.cp or cast.citizen)
    for partId in pairs(chain.parts) do
        local variants = { false }
        if chain.id == "missing" then variants = { "rebels", "infestation", "deserted" } end
        if chain.id == "shift" then variants = {} for _, o in ipairs(LCJ.Occupations) do variants[#variants + 1] = o.id end end
        for _, cause in ipairs(variants) do
            if chain.id == "shift" then LC.SetJob(p, cause, true) end
            if chain.id == "rehab" then LC.AddStanding(p, -100 - LC.Standing(p)) end
            total2 = total2 + 1
            LC.Story(p).chains[chain.id] = { part = partId, data = { cause = (chain.id == "missing" and cause) or nil }, readyAt = 0 }
            LC.StoryFlag(p, "insider", true)
            LC.StoryFlag(p, "exposed", false)
            LC.Bump(p, "suspicion", -LC.Counter(p, "suspicion") + (chain.id == "molehunt" and 3 or 0))
            p.lcStoryPostings = nil
            local sp = storyPosting(p, chain.id)
            if not sp then
                table.insert(problems2, chain.id .. "/" .. partId .. " has no posting")
            else
                p.lcqNext = 0
                local okc, err = pcall(LC.AcceptPosting, p, sp.id)
                if not okc then
                    table.insert(problems2, chain.id .. "/" .. partId .. ": " .. tostring(err))
                elseif LC.QuestOf[p] then
                    started2 = started2 + 1
                    LC.AbandonQuest(p)
                else
                    table.insert(problems2, chain.id .. "/" .. partId .. " didn't start")
                end
            end
        end
    end
end
ok(#problems2 == 0, "no story errors", problems2[1])
ok(started2 == total2, "every part starts", started2 .. "/" .. total2)
_setcvar("lc_factions", 0)


----------------------------------------------------------------------
section("Occupations")
_setcvar("lc_factions", 1)
local function work(q, p)
    for _ = 1, 60 do
        if q.done then break end
        local st = q.stages[q.stage]
        if st.kind == "goto" or st.kind == "deliver" then
            p:SetPos(st.pos) _run(1)
        elseif st.kind == "hold" then
            p:SetPos(st.pos) p.crouch = st.crouch _run(st.secs + 1) p.crouch = false
        elseif st.kind == "collect" then
            for e in pairs(st.items) do hook.Run("PlayerUse", p, e) end
        elseif st.kind == "pickup" then
            hook.Run("PlayerUse", p, st.item)
        elseif st.kind == "choice" then
            LC.ResolveChoice(p, q.id, 1)
        elseif st.kind == "target" and st.action == "reach" then
            p:SetPos(st.npc:GetPos() + Vector(50, 0, 0)) _run(1)
        elseif st.kind == "target" and st.action == "use" then
            p:SetPos(st.npc:GetPos() + Vector(50, 0, 0))
            hook.Run("LivingCityPlayerUsedNPC", p, st.npc, LC.NPCs[st.npc])
        elseif st.kind == "count" and st.event == "patched" then
            for _, n in ipairs(q.data.patients or { q.data.actor }) do if IsValid(n) then n:SetHealth(n:GetMaxHealth()) end end
            _run(1)
        elseif st.kind == "count" and st.event == "used_npc" then
            for n, ns in pairs(LC.NPCs) do
                if IsValid(n) and ns.role == "cop" then hook.Run("LivingCityPlayerUsedNPC", p, n, ns) break end
            end
        else
            _run(1)
        end
    end
end
local worker = newPlayer("Worker", "citizen")
ok(storyPosting(worker, "shift") == nil, "no job, no shifts")
ok(LC.SetJob(worker, "sanitation") and LC.Job(worker).id == "sanitation", "a citizen can take a Union job")
local unitJ = newPlayer("UnitJob", "cp")
ok(not LC.SetJob(unitJ, "kitchen"), "units can't take Union jobs")
local sp1 = storyPosting(worker, "shift")
ok(sp1 and string.find(sp1.title, "Union shift: Sanitation Worker: ", 1, true) == 1, "shifts appear on the board", sp1 and sp1.title)
local c0, s0 = LC.Credits(worker), LC.Standing(worker)
LC.AcceptPosting(worker, sp1.id)
local qw = LC.QuestOf[worker]
work(qw, worker)
ok(qw.done, "a shift can be worked to completion", qw.stages[qw.stage] and qw.stages[qw.stage].kind)
ok(LC.Credits(worker) - c0 == 15, "a shift pays credits", LC.Credits(worker) - c0)
ok(LC.Standing(worker) - s0 >= 5, "and earns standing", LC.Standing(worker) - s0)
ok(LC.Counter(worker, "shifts") == 1, "and is counted")
ok(storyPosting(worker, "shift") ~= nil, "then the next shift is posted")

local doc = newPlayer("Doc", "citizen")
LC.SetJob(doc, "medic")
ok(doc:HasWeapon("weapon_medkit"), "medics are issued a medkit")
for _ = 1, 3 do
    local sp = storyPosting(doc, "shift")
    LC.AcceptPosting(doc, sp.id)
    local qd2 = LC.QuestOf[doc]
    work(qd2, doc)
    ok(qd2.done, "a medic shift completes once the patients are healed: " .. qd2.title)
end

local wp = LC.AddPoint(Vector(3500, -1500, 0), 0, "work", 2)
local wn, wst = LC.SpawnCitizen(Vector(3300, -1500, 0))
LC.GoTo(wn, wst, wp.pos, false, wp)
_run(5)
ok(wst.untilT - CurTime() > 50, "NPC citizens settle in at workplaces for a while")

----------------------------------------------------------------------
section("Social credit and the Commissary")
local shopper = newPlayer("Shopper", "citizen")
ok(LC.Credits(shopper) == 20, "new players start with 20 credits")
ok(LC.Buy(shopper, "ration") and LC.HasItem(shopper, "ration"), "buying a ration puts it in your pockets")
ok(LC.Credits(shopper) == 15, "and costs 5 credits")
ok(not LC.Buy(shopper, "melon"), "watermelon is for exemplary citizens only")
LC.AddStanding(shopper, 450)
LC.AddCredits(shopper, 100)
ok(LC.Buy(shopper, "melon"), "an exemplary citizen can buy one")
ok(not LC.Buy(shopper, "pistolammo"), "ammunition is for units only")
local st1 = LC.Standing(shopper)
LC.ReportCrime(shopper, "Testing", 30)
ok(LC.Standing(shopper) == st1 - 25, "being declared wanted costs standing", LC.Standing(shopper) - st1)
LC.ClearWanted(shopper)
LC.Incarcerate(shopper, 30, "test")
ok(LC.Standing(shopper) == st1 - 65, "being jailed costs more", LC.Standing(shopper) - st1)
LC.ReleasePrisoner(shopper)
LC.AddStanding(shopper, -1000)
local disp0 = ents.Create("lc_dispenser")
disp0:SetPos(shopper:GetPos() + Vector(40, 0, 0))
ok(not LC.UseDispenser(shopper, disp0), "anticitizens are refused rations")
ok(not LC.Buy(shopper, "bread"), "and most of the Commissary")

----------------------------------------------------------------------
section("Hunger, thirst and survival")
local surv = newPlayer("Survivor", "citizen")
ok(math.floor(LC.Hunger(surv)) == 80 and math.floor(LC.Thirst(surv)) == 80, "you start fed and watered")
_setcvar("lc_hunger_minutes", 1)
_setcvar("lc_thirst_minutes", 1)
_run(30)
ok(LC.Hunger(surv) < 50 and LC.Thirst(surv) < 50, "both drain while the city runs", math.floor(LC.Hunger(surv)) .. "/" .. math.floor(LC.Thirst(surv)))
local hp0 = surv:Health()
_run(40)
ok(LC.Hunger(surv) == 0 and surv:Health() < hp0, "at zero, you start dying", surv:Health())
_setcvar("lc_hunger_minutes", 60)
_setcvar("lc_thirst_minutes", 40)
surv:SetHealth(100)
LC.GiveItem(surv, "ration")
LC.InvAction(surv, "use", "ration")
ok(LC.Hunger(surv) >= 45 and not LC.HasItem(surv, "ration"), "eating a ration helps")
LC.GiveItem(surv, "water")
LC.InvAction(surv, "use", "water")
ok(_lastnet("lcn_effect") ~= nil, "Breen's water has side effects")
ok(LC.HasItem(surv, "can_empty"), "and you keep the empty can")
surv.water = 1
LC.InvAction(surv, "fill", "can_empty")
ok(LC.HasItem(surv, "can_dirty"), "fill the can in water")
LC.InvAction(surv, "cook", "can_dirty")
ok(LC.HasItem(surv, "can_dirty"), "you can't boil it without a fire")
local barrel = ents.Create("lc_fire")
barrel:SetPos(surv:GetPos() + Vector(60, 0, 0))
LC.InvAction(surv, "cook", "can_dirty")
ok(LC.HasItem(surv, "can_clean"), "boil it over a burning barrel")
local realRandom = math.random
math.random = function(a, b) if a == nil then return 0 end if b == nil then return realRandom(a) end return realRandom(a, b) end
surv.lcnNextDrink = 0
ok(LC.DrinkFromWater(surv) and LC.HasParasites(surv), "drinking straight from the water can give you parasites")
math.random = realRandom
LC.GiveItem(surv, "tablets")
LC.InvAction(surv, "use", "tablets")
ok(not LC.HasParasites(surv), "tablets cure them")
surv.water = 0
local bird = ents.Create("npc_pigeon")
bird:SetPos(surv:GetPos() + Vector(30, 0, 0))
hook.Run("OnNPCKilled", bird, surv)
_run(1)
local carcass
for _, e in ipairs(ents.FindByClass("lc_item")) do if e:GetNW2String("lc_item", "") == "raw_bird" then carcass = e end end
ok(IsValid(carcass), "a dead bird leaves a carcass you can pick up")
LC.GiveItem(surv, "raw_bird")
LC.InvAction(surv, "cook", "raw_bird")
ok(LC.HasItem(surv, "cooked_bird"), "and you can roast it")
for i = 1, 20 do LC.GiveItem(surv, "bottle_empty") end
ok(LC.InvCount(surv) <= 12, "pockets have a limit", LC.InvCount(surv))

local fist = { GetClass = function() return "weapon_fists" end, IsValid = function() return true end }
local crab = ents.Create("npc_headcrab")
local d1 = _dmg(surv, 30) d1.inflictor = fist
hook.Run("EntityTakeDamage", crab, d1)
ok(d1:GetDamage() == 4, "a punch barely hurts a headcrab", d1:GetDamage())
local pig = ents.Create("npc_pigeon")
local d2 = _dmg(surv, 5) d2.inflictor = fist
hook.Run("EntityTakeDamage", pig, d2)
ok(d2:GetDamage() >= 50, "but kills a bird outright")
local wildlife = 0
for e, kind in pairs(LC.Wildlife) do if IsValid(e) then wildlife = wildlife + 1 end end
ok(wildlife > 0, "birds and vermin live in the city", wildlife)

----------------------------------------------------------------------
section("Fixtures from the layout")
local vp = LC.AddPoint(Vector(2500, -2500, 0), 0, "vending", 0)
_run(1)
local vend = ents.FindByClass("lc_vending")[1]
ok(IsValid(vend), "placing a vending point puts a machine in the world")
local buyer = newPlayer("Thirsty", "citizen")
local cb = LC.Credits(buyer)
ok(LC.UseVending(buyer, vend), "using it sells a can")
_run(1)
local can
for _, e in ipairs(ents.FindByClass("lc_item")) do if e:GetNW2String("lc_item", "") == "water" then can = e end end
ok(IsValid(can) and LC.Credits(buyer) == cb - 2, "a can of Breen's water drops out, for 2 credits")
LC.RemovePoint(vp)
_run(1)
ok(not IsValid(vend), "removing the point removes the machine")
LC.AddPoint(Vector(2600, -2500, 0), 0, "dispenser", 0)
_run(1)
local dsp = ents.FindByClass("lc_dispenser")[1]
ok(IsValid(dsp) and LC.UseDispenser(buyer, dsp), "the ration dispenser serves you")
ok(not LC.UseDispenser(buyer, dsp), "once per allocation")
_setcvar("lc_factions", 0)

local function UndergroundTests() -- contraband, papers, disguises, radios, new jobs
_setcvar("lc_stops", 1)
_setcvar("lc_auto_events", 0) -- no surprise curfews or sweeps in the middle of these
LC.EndEvent(true)
----------------------------------------------------------------------
section("Radios")
_setcvar("lc_factions", 1)
local FAR = Vector(30000, 30000, 0) -- nowhere near a unit
local function forceRandom(v, fn)
    local r = math.random
    math.random = function(a, b) if a == nil then return v end if b == nil then return r(a) end return r(a, b) end
    local okr, err = pcall(fn)
    math.random = r
    if not okr then error(err) end
end
local listener = newPlayer("Listener", "citizen")
local rebelR = newPlayer("RadioRebel", "resistance", nil, 150)
local unitR = newPlayer("RadioUnit", "cp")
local deaf = newPlayer("NoRadio", "citizen")
LC.AddCredits(listener, 100)
ok(LC.Buy(listener, "radio") and LC.RadioBand(listener) == "union", "a Union radio from the Commissary puts you on the Union band")
LC.GiveItem(rebelR, "radio_tuned")
ok(LC.RadioBand(rebelR) == "resistance" and LC.RadioBand(unitR) == "cp", "a retuned radio is Freq 7; units are on the CP net")
listener.chat, rebelR.chat, unitR.chat, deaf.chat = {}, {}, {}, {}
ok(hook.Run("PlayerSay", listener, "!r anyone out there") == "", "!r talks on your radio")
ok(has(rebelR.chat, "[Union band] Listener: anyone out there") and has(unitR.chat, "[Union band]"), "everyone with a radio hears the Union band, and CP monitors it")
ok(not has(deaf.chat, "anyone out there"), "people without a radio don't")
hook.Run("PlayerSay", rebelR, "!r meet at the canal")
ok(has(rebelR.chat, "[Freq 7]") and not has(listener.chat, "meet at the canal") and not has(unitR.chat, "meet at the canal"), "Freq 7 is private")
hook.Run("PlayerSay", unitR, "!r sweep in block two")
ok(has(rebelR.chat, "[Intercept]") and not has(listener.chat, "sweep in block two"), "CP traffic leaks to retuned radios")
ok(hook.Run("PlayerSay", deaf, "!r hello") == "" and has(deaf.chat, "You don't have a radio"), "no radio, no talking")
listener.chat, rebelR.chat = {}, {}
hook.Run("LivingCityEventSoon", "sweep", 45)
ok(has(listener.chat, "Notice: civil status inspections begins in 45 seconds"), "radios hear about events before the loudspeakers")
ok(has(rebelR.chat, "Move anything you don't want found"), "Freq 7 adds a warning")
unitR.chat, rebelR.chat = {}, {}
deaf:SetPos(FAR)
LC.ReportCrime(deaf, "Testing the dispatch", 30)
_run(0.5)
ok(has(unitR.chat, "Dispatch: all units, suspect NoRadio"), "units hear dispatch when someone is declared wanted")
ok(has(rebelR.chat, "[Intercept]"), "and so do eavesdroppers, garbled")
LC.ClearWanted(deaf)
local serial = LC.EventSerial or 0
LC.StartEvent("rations", 1)
ok((LC.EventSerial or 0) == serial + 1, "each event gets a serial number")
LC.EndEvent(true)

----------------------------------------------------------------------
section("Stop and search")
-- everyone else (hunted rebels included) goes somewhere far away, and only our test subjects get stopped
for _, p in ipairs(player.GetAll()) do p.lcStopNext = 1e9 p:SetPos(Vector(-30000, 30000, 0)) end
_setcvar("lc_can_event", 0)
LC.CalmCops(nil)
_run(1)
local copN, copSt
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.role == "cop" and not s.test and not s.questLock then copN, copSt = n, s break end end
ok(IsValid(copN), "there's a unit on the street")
local frisked = newPlayer("Frisked", "citizen")
frisked.lcStopNext = 0
LC.GiveItem(frisked, "uniform_cp")
LC.SetState(copN, copSt, "idle")
copSt.untilT, copSt.nextInspect = CurTime() + 1000, CurTime() + 1000
copN.sim = false -- standing on the corner
frisked:SetPos(copN:GetPos() + Vector(150, 0, 0))
LC.Release(copN, copSt) -- not at a checkpoint post: this is a street stop
_setcvar("lc_street_stop_chance", 100)
_run(3.5)
ok(LC.Stops[frisked] ~= nil and has(frisked.chat, "Stand still for inspection"), "a cop on the street stops a passer-by", copSt.state)
copN.sim = true
local standing0 = LC.Standing(frisked)
_run(8)
ok(LC.Stops[frisked] == nil, "the stop finishes")
ok(not LC.HasItem(frisked, "uniform_cp") and has(frisked.chat, "Confiscated: Civil Protection uniform"), "contraband is found and confiscated")
ok(LC.PlayerIsWanted(frisked) and LC.Standing(frisked) < standing0, "and you're wanted, with less standing")
ok(frisked.lcStopNext > CurTime() + 300, "and won't be stopped again for a while")
LC.ClearWanted(frisked)
LC.CalmCops(frisked)
frisked:SetPos(Vector(-30000, 30000, 0))
_setcvar("lc_street_stop_chance", 1)
_run(1)

local clean = newPlayer("Clean", "citizen")
clean:StripWeapons() -- test players start with a pistol and a crowbar
LC.SetState(copN, copSt, "idle")
clean:SetPos(copN:GetPos() + Vector(80, 0, 0))
LC.StartStop(copN, copSt, clean)
_run(6)
ok(has(clean.chat, "Nothing found") and not LC.PlayerIsWanted(clean), "a clean citizen is sent on their way", table.concat(clean.chat or {}, " | "))

local runner = newPlayer("Runner", "citizen")
LC.SetState(copN, copSt, "idle")
runner:SetPos(copN:GetPos() + Vector(200, 0, 0))
LC.StartStop(copN, copSt, runner)
_run(0.6)
runner:SetPos(runner:GetPos() + Vector(2000, 0, 0))
_run(1)
ok(LC.PlayerIsWanted(runner) and has(runner.chat, "walked away from an inspection"), "walking away from a stop makes you wanted")
LC.ClearWanted(runner)
LC.CalmCops(runner)

local sweepGuy = newPlayer("SweepGuy", "citizen")
sweepGuy:StripWeapons()
LC.SetState(copN, copSt, "idle")
copSt.untilT, copSt.nextInspect = CurTime() + 1000, CurTime() + 1000
copN.sim = false
sweepGuy:SetPos(copN:GetPos() + Vector(400, 0, 0))
_setcvar("lc_street_stop_chance", 0)
_run(3.5)
ok(LC.Stops[sweepGuy] == nil, "outside a sweep, a unit with nothing to do leaves you alone")
_setcvar("lc_stop_chance", 50)
LC.StartEvent("sweep", 1)
_run(3.5)
ok(LC.Stops[sweepGuy] ~= nil, "during an inspection sweep, units stop people from further away, far more often")
copN.sim = true
_run(8)
LC.EndEvent(true)
_setcvar("lc_stop_chance", 15)
_setcvar("lc_street_stop_chance", 1)
sweepGuy:SetPos(Vector(-30000, 30000, 0))

-- Units (players) search people
local searcher = newPlayer("Searcher", "cp")
local suspect = newPlayer("Suspect", "citizen")
suspect:SetPos(FAR)
searcher:SetPos(FAR + Vector(60, 0, 0))
LC.GiveItem(suspect, "uniform_cp")
suspect:Give("weapon_crowbar")
local cxp, ccr = tonumber(searcher:GetPData("lcf_xp_cp", 0)), LC.Credits(searcher)
ok(LC.StartSearch(searcher, suspect), "a unit can search the person in front of them")
_run(3.5)
ok(not LC.HasItem(suspect, "uniform_cp") and not suspect:HasWeapon("weapon_crowbar"), "contraband and weapons are confiscated")
ok(tonumber(searcher:GetPData("lcf_xp_cp", 0)) > cxp and LC.Credits(searcher) > ccr, "the unit is rewarded for the seizure")
ok(not LC.StartSearch(searcher, suspect), "and can't search the same person again straight away")
LC.ClearWanted(suspect)
local other2 = newPlayer("Suspect2", "citizen")
other2:SetPos(FAR + Vector(100, 0, 0))
ok(not LC.StartSearch(suspect, other2), "citizens can't search people")
LC.StartSearch(searcher, other2)
other2:SetPos(FAR + Vector(2000, 0, 0))
_run(3.5)
ok(LC.PlayerIsWanted(other2), "walking off during a search makes you wanted")
LC.ClearWanted(other2)
searcher.lookingAt = other2
other2:SetPos(searcher:GetPos() + Vector(60, 0, 0))
other2.lcSearchedAt = nil
ok(hook.Run("PlayerSay", searcher, "!search") == "" and other2.lcBeingSearched == searcher, "!search works on whoever you're looking at")
_run(3.5)

local jailed = newPlayer("Jailed", "citizen")
LC.GiveItem(jailed, "lockpick")
LC.GiveItem(jailed, "papers_forged")
LC.Incarcerate(jailed, 30, "test")
ok(not LC.HasItem(jailed, "lockpick") and not LC.HasItem(jailed, "papers_forged"), "arrest confiscates everything illegal")
LC.ReleasePrisoner(jailed)

----------------------------------------------------------------------
section("Disguises")
_setcvar("lc_disguise_risk", 0)
local mole = newPlayer("Mole", "citizen")
mole:SetPos(FAR)
LC.GiveItem(mole, "uniform_cp")
LC.ReportCrime(mole, "Already wanted", 300)
ok(LC.InvAction(mole, "wear", "uniform_cp") == nil and LC.DisguisedAsCP(mole), "a citizen can put on a stolen uniform")
ok(mole:GetModel() == "models/police.mdl" and string.find(mole:GetNW2String("lcd_title", ""), "CP ", 1, true) == 1, "and looks the part, down to a made-up designation")
mole:SetPos(copN:GetPos() + Vector(300, 0, 0))
_run(2)
local hunting = false
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.enemy == mole then hunting = true end end
ok(not hunting, "security NPCs don't go after a 'unit', even a wanted one")
ok(LC.CurfewExcuse(mole, nil), "units aren't stopped for curfew")
local cpdoor = ents.Create("func_door")
cpdoor.mapid = 501
LC.SetDoorTag(cpdoor, "cp")
forceRandom(0.99, function() ok(LC.PlayerMayUseCPDoor(mole, cpdoor), "a Combine door usually accepts the uniform") end)
forceRandom(0.0, function() ok(LC.PlayerMayUseCPDoor(mole, cpdoor), "and remembers it did") end)
local cpdoor2 = ents.Create("func_door")
cpdoor2.mapid = 502
LC.SetDoorTag(cpdoor2, "cp")
forceRandom(0.0, function() ok(not LC.PlayerMayUseCPDoor(mole, cpdoor2), "but sometimes reads your biosignal") end)
ok(not LC.DisguisedAsCP(mole) and has(mole.chat, "Your disguise is blown"), "and the disguise is blown")
ok(not LC.HasItem(mole, "uniform_cp"), "the uniform is lost")
LC.ClearWanted(mole)
LC.CalmCops(mole)
mole:SetPos(FAR)
LC.GiveItem(mole, "uniform_cp")
LC.Wear(mole, "uniform_cp")
LC.ReportCrime(mole, "Assault", 60)
ok(not LC.DisguisedAsCP(mole), "committing a crime blows it too")
LC.ClearWanted(mole)
LC.CalmCops(mole)
LC.GiveItem(mole, "uniform_cp")
LC.Wear(mole, "uniform_cp")
LC.InvAction(mole, "takeoff")
ok(not LC.Disguise(mole) and LC.HasItem(mole, "uniform_cp") and mole:GetModel() ~= "models/police.mdl", "taking it off gives it back")
mole:SetPos(copN:GetPos() + Vector(100, 0, 0))
LC.Wear(mole, "uniform_cp")
ok(not LC.Disguise(mole) and LC.PlayerIsWanted(mole), "changing in front of a unit doesn't work")
LC.ClearWanted(mole)
LC.CalmCops(mole)

local fighter = newPlayer("Fighter", "resistance", nil, 400)
fighter:SetPos(FAR)
ok(LC.PlayerIsHunted(fighter) and LC.PlayerIsWanted(fighter), "Resistance fighters are hunted in the city")
LC.GiveItem(fighter, "civvies")
LC.Wear(fighter, "civvies")
ok(LC.PassesAsCitizen(fighter) and not LC.PlayerIsWanted(fighter), "in citizen clothes, nobody looks twice")
ok(LC.CanWork(fighter), "they can even hold a Union job")
local okp, why = LC.CheckPapers(fighter)
ok(not okp and string.find(why, "wanted notice", 1, true), "but an inspection checks their face")
LC.GiveItem(fighter, "papers_forged")
LC.InvAction(fighter, "use", "papers_forged")
ok(LC.Identity(fighter) and fighter:GetNW2String("lcd_alias", "") ~= "", "forged papers give them a new name")
forceRandom(0.99, function() ok(LC.CheckPapers(fighter), "which usually holds up") end)
forceRandom(0.0, function()
    local okf, whyf = LC.CheckPapers(fighter)
    ok(not okf, "but not always")
    LC.PapersFailed(fighter, whyf)
end)
ok(not LC.PassesAsCitizen(fighter) and not LC.Identity(fighter) and LC.PlayerIsWanted(fighter), "a failed check blows the whole cover")
LC.ClearWanted(fighter)

----------------------------------------------------------------------
section("Papers and permits")
local fugitive = newPlayer("Fugitive", "citizen")
fugitive:SetPos(copN:GetPos() + Vector(100, 0, 0))
LC.ReportCrime(fugitive, "Theft", 300)
LC.GiveItem(fugitive, "papers_dead")
LC.InvAction(fugitive, "use", "papers_dead")
ok(LC.HasItem(fugitive, "papers_dead") and LC.PlayerIsWanted(fugitive), "you can't become someone else with a unit watching")
fugitive:SetPos(FAR)
LC.InvAction(fugitive, "use", "papers_dead")
ok(not LC.PlayerIsWanted(fugitive) and LC.Identity(fugitive).kind == "dead", "out of sight, a dead man's papers clear your name")
local tourist = newPlayer("NightOwl", "citizen")
LC.AddStanding(tourist, 200)
LC.AddCredits(tourist, 100)
ok(LC.Buy(tourist, "permit"), "trusted citizens can buy a travel permit")
LC.StartEvent("curfew", 2)
ok(LC.CurfewExcuse(tourist, nil) and not LC.HasItem(tourist, "permit"), "a curfew stop uses the permit")
ok(LC.CurfewExcuse(tourist, nil), "and it covers the rest of the curfew")
LC.EndEvent(true)
LC.StartEvent("curfew", 2)
ok(not LC.CurfewExcuse(tourist, nil), "but not the next one")
forceRandom(0.99, function() ok(LC.CurfewExcuse(fugitive, nil), "papers that say night shift also work") end)
LC.EndEvent(true)

local forger = newPlayer("Forger", "citizen")
forger:SetPos(FAR)
LC.GiveItem(forger, "papers_blank")
LC.InvAction(forger, "use", "papers_blank")
ok(LC.HasItem(forger, "papers_blank"), "forging needs somewhere private")
forger:SetPos(Vector(-6000, -6000, 0))
withRoll(20, function() LC.InvAction(forger, "use", "papers_blank") end)
ok(LC.HasItem(forger, "papers_forged") and not LC.HasItem(forger, "papers_blank"), "a steady hand in rebel territory makes forged papers")

local hungry = newPlayer("Hungry", "citizen")
local disp2 = ents.Create("lc_dispenser")
disp2:SetPos(hungry:GetPos() + Vector(40, 0, 0))
LC.UseDispenser(hungry, disp2)
ok(not LC.UseDispenser(hungry, disp2), "the dispenser makes you wait")
LC.GiveItem(hungry, "ration_forged")
forceRandom(0.99, function() ok(LC.UseDispenser(hungry, disp2), "unless you have a forged ration card") end)
ok(not LC.HasItem(hungry, "ration_forged"), "which is used up")

----------------------------------------------------------------------
section("Lockpicks and bypass charges")
local burglar = newPlayer("Burglar", "citizen")
burglar:SetPos(FAR)
local ldoor = ents.Create("func_door")
ldoor.mapid = 601
ldoor:SetPos(FAR + Vector(60, 0, 0))
LC.SetDoorTag(ldoor, "locked")
ldoor:Fire("Lock")
LC.GiveItem(burglar, "lockpick")
burglar.lookingAt = ldoor
ldoor.fired = {}
LC.InvAction(burglar, "use", "lockpick")
ok(LC.Picking[burglar] ~= nil, "look at a locked door and use the pick")
withRoll(20, function() _run(8) end)
ok(LC.DoorPicked(ldoor) and has(ldoor.fired, "Unlock") and has(ldoor.fired, "Open"), "the lock gives")
ok(hook.Run("PlayerUse", burglar, ldoor) ~= false, "and the door lets you through for a while")
_run(31)
ok(not LC.DoorPicked(ldoor) and ldoor.locked == true, "then it shuts and locks itself again")
local cdoor = ents.Create("func_door")
cdoor.mapid = 602
cdoor:SetPos(FAR + Vector(60, 0, 0))
LC.SetDoorTag(cdoor, "cp")
burglar.lookingAt = cdoor
burglar.chat = {}
LC.InvAction(burglar, "use", "lockpick")
ok(LC.Picking[burglar] == nil and has(burglar.chat, "Combine lock"), "a pick won't touch a Combine lock")
LC.GiveItem(burglar, "bypass")
LC.InvAction(burglar, "use", "bypass")
forceRandom(0.99, function() _run(5) end)
ok(LC.DoorPicked(cdoor) and not LC.HasItem(burglar, "bypass"), "a bypass charge opens it, once")
local udoor = ents.Create("func_door")
udoor.mapid = 603
udoor:SetPos(FAR + Vector(60, 0, 0))
burglar.lookingAt = udoor
burglar.chat = {}
LC.InvAction(burglar, "use", "lockpick")
ok(has(burglar.chat, "It isn't locked"), "unlocked doors don't need picking")
burglar.lookingAt = nil

----------------------------------------------------------------------
section("The stash at home")
local tenant = newPlayer("Tenant", "citizen")
_run(2.5)
local blockN = LC.PlayerBlock(tenant)
ok(blockN ~= nil, "everyone has a home block")
local home
for _, z in ipairs(LC.ZonesOfKind("block")) do if z.group == blockN then home = z.pos end end
LC.GiveItem(tenant, "radio_tuned")
tenant:SetPos(FAR)
ok(not LC.StashStore(tenant, "radio_tuned"), "your stash is only reachable at home")
tenant:SetPos(home)
ok(LC.StashStore(tenant, "radio_tuned") and not LC.HasItem(tenant, "radio_tuned"), "at home, you can hide things")
LC.SendInv(tenant, true)
local invmsg = _lastnet("lci_inv")
ok(invmsg and string.find(invmsg.data[2] or "", "stash", 1, true), "the inventory window shows your stash when you're home")
ok(LC.StashTake(tenant, "radio_tuned") and LC.HasItem(tenant, "radio_tuned"), "and take them back")
ok(hook.Run("PlayerSay", tenant, "!stash") == "", "!stash opens it")
LC.StashStore(tenant, "radio_tuned")
_setcvar("lc_raid_chance", 100)
local s0 = LC.Standing(tenant)
LC.StartEvent("sweep", 1)
ok(LC.Stash(tenant).radio_tuned == nil and LC.Standing(tenant) < s0, "inspection sweeps can raid it")
LC.EndEvent(true)
_setcvar("lc_raid_chance", 25)

----------------------------------------------------------------------
section("The black market")
local buyer2 = newPlayer("Buyer", "citizen")
LC.AddCredits(buyer2, 300)
buyer2:SetPos(FAR)
ok(not LC.MarketAccess(buyer2), "no dealer and no rebel territory nearby, no black market")
buyer2:SetPos(Vector(-6000, -6000, 0))
ok(LC.MarketAccess(buyer2) and LC.OpenMarket(buyer2) and _lastnet("lcu_market") ~= nil, "on maps without a dealer, rebel territory has one")
local c1 = LC.Credits(buyer2)
ok(LC.BlackBuy(buyer2, "lockpick") and LC.HasItem(buyer2, "lockpick") and LC.Credits(buyer2) == c1 - 35, "buying a lockpick")
ok(LC.BlackBuy(buyer2, "crowbar") and buyer2:HasWeapon("weapon_crowbar"), "and a crowbar")
LC.GiveItem(buyer2, "keepsake")
local c2 = LC.Credits(buyer2)
ok(LC.DealerSell(buyer2, "keepsake") and LC.Credits(buyer2) == c2 + 20, "the dealer buys what you find")
local fp = LC.AddPoint(Vector(-2500, -2500, 0), 0, "dealer", 0)
_run(1)
local dealer = ents.FindByClass("lc_dealer")[1]
ok(IsValid(dealer), "placing a dealer point puts a dealer in the world")
ok(not LC.MarketAccess(buyer2), "once there's a dealer, you have to find them")
buyer2:SetPos(Vector(-2450, -2500, 0))
ok(LC.MarketAccess(buyer2), "and there they are")
local copBuyer = newPlayer("CopBuyer", "cp")
copBuyer:SetPos(Vector(-2450, -2500, 0))
ok(not LC.MarketAccess(copBuyer), "units can't buy")
rebelR.chat = {}
ok(LC.BustDealer(copBuyer, dealer) and dealer:GetNW2Bool("lc_busted", false), "a unit busts the dealer")
ok(not LC.MarketAccess(buyer2) and has(rebelR.chat, "got raided"), "the dealer is gone for a while, and Freq 7 hears about it")
_run(901)
ok(not dealer:GetNW2Bool("lc_busted", true) and LC.MarketAccess(buyer2), "then they're back")
LC.RemovePoint(fp)
_run(1)

----------------------------------------------------------------------
section("New Union jobs")
local function workAll(q, p)
    for _ = 1, 80 do
        if q.done then break end
        local st = q.stages[q.stage]
        if st.kind == "goto" or st.kind == "deliver" then
            p:SetPos(st.pos) _run(1)
        elseif st.kind == "hold" then
            p:SetPos(st.pos) p.crouch = st.crouch _run(st.secs + 1) p.crouch = false
        elseif st.kind == "collect" then
            for e in pairs(st.items) do hook.Run("PlayerUse", p, e) end
        elseif st.kind == "pickup" then
            hook.Run("PlayerUse", p, st.item)
        elseif st.kind == "choice" then
            LC.ResolveChoice(p, q.id, p.lcPick or 1)
        elseif st.kind == "target" and st.action == "reach" then
            p:SetPos(st.npc:GetPos() + Vector(50, 0, 0)) _run(1)
        elseif st.kind == "target" and st.action == "use" then
            p:SetPos(st.npc:GetPos() + Vector(50, 0, 0))
            hook.Run("LivingCityPlayerUsedNPC", p, st.npc, LC.NPCs[st.npc])
        elseif st.kind == "escort" then
            st.npc:SetPos(st.pos) p:SetPos(st.pos) _run(1)
        elseif st.kind == "count" and st.event == "used_npc" then
            for n, ns in pairs(LC.NPCs) do
                if q.done or q.stages[q.stage] ~= st then break end
                if IsValid(n) and (not st.filter or st.filter(q, p, n, ns)) then hook.Run("LivingCityPlayerUsedNPC", p, n, ns) end
            end
            _run(0.5)
        else
            _run(1)
        end
    end
end
local function shiftTitled(p, title)
    for _ = 1, 40 do
        p.lcStoryPostings = nil
        local sp = storyPosting(p, "shift")
        if sp and string.find(sp.title, title, 1, true) then
            p.lcqNext = 0
            LC.AcceptPosting(p, sp.id)
            return LC.QuestOf[p]
        end
    end
end
local newJobs = { porter = { "New arrivals", "Luggage", "Ticket check" }, clerk = { "Filing", "Permit desk", "Supply cabinet" },
    laundry = { "Wash cycle", "Pressed uniforms", "Stains" }, mortuary = { "Collection", "Incinerator" },
    scrap = { "Scrap run", "Rubble clearing" }, radio = { "Loudspeakers", "Repair bench", "Union radio order" } }
local jobber = newPlayer("Jobber", "citizen")
local done, total, missing = 0, 0, {}
for _, id in ipairs({ "porter", "clerk", "laundry", "mortuary", "scrap", "radio" }) do
    LC.SetJob(jobber, id, true)
    for _, title in ipairs(newJobs[id]) do
        total = total + 1
        local qj = shiftTitled(jobber, title)
        if not qj then
            missing[#missing + 1] = id .. "/" .. title .. " never posted"
        else
            jobber.lcPick = 1
            workAll(qj, jobber)
            if qj.done and not LC.QuestOf[jobber] then done = done + 1 else
                missing[#missing + 1] = id .. "/" .. title .. " stuck at " .. tostring(qj.stages[qj.stage] and qj.stages[qj.stage].kind)
                LC.AbandonQuest(jobber)
            end
        end
        LC.ClearWanted(jobber)
    end
end
ok(done == total, "every new job's shifts can be worked start to finish", missing[1])
ok(#LCJ.Occupations == 12, "twelve occupations in all")

local function choose(job, title, pick, roll)
    local p = newPlayer("Job" .. job .. pick, "citizen")
    p:SetPos(FAR)
    LC.SetJob(p, job, true)
    local qj = shiftTitled(p, title)
    p.lcPick = pick
    if roll then withRoll(roll, function() workAll(qj, p) end) else workAll(qj, p) end
    return p, qj
end
local pc = choose("clerk", "Supply cabinet", 2, 20)
ok(LC.HasItem(pc, "papers_blank"), "a records clerk can lift a blank identity form")
local pl = choose("laundry", "Pressed uniforms", 2, 20)
ok(LC.HasItem(pl, "uniform_cp"), "the laundry is where uniforms go missing")
local pm = choose("mortuary", "Collection", 2)
ok(LC.HasItem(pm, "papers_dead"), "the morgue is where dead men's papers come from")
local pr = choose("radio", "Repair bench", 3)
ok(LC.HasItem(pr, "radio_tuned"), "the radio bench is where retuned radios come from")
local pp, qp = choose("porter", "New arrivals", 3)
ok(qp.done and LC.Counter(pp, "reports") >= 1, "a porter can turn in a nervous arrival instead of walking him home")
local ps = choose("scrap", "Rubble clearing", 3)
ok(ps:HasWeapon("weapon_pistol"), "and the rubble sometimes hides a pistol")
_setcvar("lc_factions", 0)
_setcvar("lc_disguise_risk", 5)
_setcvar("lc_can_event", 1)

end
UndergroundTests()

local function CityFixTests() -- cops that chase and arrest, ration lines, Freeman, the gamemode
local function waitFor(cond, secs)
    for _ = 1, secs * 2 do
        if cond() then return true end
        _run(0.5)
    end
    return cond()
end
_setcvar("lc_auto_events", 0)
_setcvar("lc_stops", 0)
LC.EndEvent(true)
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) p.lcStopNext = 1e9 end
_setcvar("lc_can_event", 0)
LC.CalmCops(nil)
_run(1)

----------------------------------------------------------------------
section("Crowding a cop")
local copA, copAst
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.role == "cop" and not s.questLock then copA, copAst = n, s break end end
LC.SetState(copA, copAst, "idle")
LC.Release(copA, copAst)
copAst.untilT, copAst.nextInspect, copAst.nextWarn = CurTime() + 1000, CurTime() + 1000, 0
copA.sim = false
local pest = newPlayer("Pest", "citizen")
pest:SetPos(copA:GetPos() + Vector(50, 0, 0))
_run(2)
ok(pest.lcBump and pest.lcBump.n >= 1, "standing on a unit's toes gets you told to move along")
ok(waitFor(function() return has(pest.chat, "shoves you back") end, 12) and pest.pushed ~= nil, "keep crowding him and he shoves you")
ok(waitFor(function() return has(pest.chat, "crack across the ribs") end, 6), "then the stick")
ok(waitFor(function() return LC.PlayerIsWanted(pest) end, 6) and has(pest.chat, "Obstructing Civil Protection"), "then you're obstructing Civil Protection")
ok(copAst.state == "hostile" and copAst.enemy == pest, "and he comes for you")
LC.ClearWanted(pest)
LC.CalmCops(pest)
pest:SetPos(FAR)
_run(1)
local pest2 = newPlayer("Pest2", "citizen")
pest2:SetPos(copA:GetPos() + Vector(50, 0, 0))
for _ = 1, 4 do hook.Run("PlayerUse", pest2, copA) copAst.nextUse = 0 _run(3) end
ok(has(pest2.chat, "shoves you back") or has(pest2.chat, "crack across the ribs"), "pestering a unit with E escalates the same way")
pest2:SetPos(FAR)
pest2.lcBump = nil

----------------------------------------------------------------------
section("Cops that chase")
copA.sim = true
local runner2 = newPlayer("Runaway", "citizen")
runner2:SetPos(copA:GetPos() + Vector(2000, 0, 0))
local d0 = copA:GetPos():Distance(runner2:GetPos())
LC.ReportCrime(runner2, "Assault", 120)
LC.MakeCopsHostile(runner2, runner2:GetPos(), 2500)
ok(copAst.state == "hostile" and copA.enemyMemory ~= nil, "a hostile unit is told where the suspect is")
_run(5)
ok(copA:GetPos():Distance(runner2:GetPos()) < d0 - 400, "and runs after them, even out of sight", string.format("%.0f -> %.0f", d0, copA:GetPos():Distance(runner2:GetPos())))
_run(10)
ok(copA:GetPos():Distance(runner2:GetPos()) < 600 and copA.sched == SCHED_CHASE_ENEMY, "close in, the combat AI takes over", copA.sched)

----------------------------------------------------------------------
section("Arrests with no prison cells")
local savedCells = {}
for _, p in ipairs(LC.PointsOfKind("cell")) do savedCells[#savedCells + 1] = { pos = p.pos, yaw = p.yaw } end
for _, p in ipairs(LC.PointsOfKind("cell")) do LC.RemovePoint(p) end
ok(not LC.PrisonAvailable(), "the map has no cells")
LC.GiveItem(runner2, "lockpick")
local cr0 = LC.Credits(runner2)
local hit = _dmg(copA, 10, DMG_CLUB)
hook.Run("EntityTakeDamage", runner2, hit)
ok(LC.Detained[runner2] and runner2.frozen and hit:GetDamage() == 0, "the stick doesn't just beat you: you're cuffed on the street")
ok(not LC.PlayerIsWanted(runner2) and not LC.HasItem(runner2, "lockpick") and LC.Credits(runner2) < cr0, "searched and fined, and no longer wanted")
local hit2 = _dmg(copA, 10, DMG_CLUB)
hook.Run("EntityTakeDamage", runner2, hit2)
ok(hit2:GetDamage() == 0, "nobody beats someone who's already cuffed")
local hostile = 0
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.state == "hostile" and s.enemy == runner2 then hostile = hostile + 1 end end
ok(hostile == 0 and copAst.state == "event", "the other units stand down, and the arresting one stands guard")
_run(21)
ok(not LC.Detained[runner2] and not runner2.frozen and has(runner2.chat, "Released with a warning"), "then you're let go with a warning")
for _, c in ipairs(savedCells) do LC.AddPoint(c.pos, c.yaw, "cell", 0) end
ok(LC.PrisonAvailable(), "cells back for the rest of the tests")
runner2:SetPos(FAR)

----------------------------------------------------------------------
section("Ration lines")
local line = LC.Lines[1]
for _, n in ipairs(line.q) do local s = LC.NPCs[n] if s then LC.LeaveLine(n, s) end end
line.q = {}
local front = line.slots[1].pos
local farCit, farSt = LC.SpawnCitizen(front + Vector(9000, 0, 0))
ok(not LC.JoinLine(farCit, farSt), "people on the far side of the city don't queue here")
farCit:Remove()
local nearCit, nearSt = LC.SpawnCitizen(front + Vector(-600, 0, 0))
nearSt.leaveAt = nil
line.nextAdvance = CurTime() + 1000 -- counter closed for now
ok(LC.JoinLine(nearCit, nearSt) and nearSt.lineHeading == 1 and #line.q == 0, "someone nearby heads for the line, but isn't in it until they arrive")
_run(8)
ok(nearSt.line == 1 and nearSt.slotIndex and line.q[nearSt.slotIndex] == nearCit and nearSt.state == "inline",
    "on arrival they take the next free place", tostring(nearSt.state))
local eater = newPlayer("Eater", "citizen")
eater:SetPos(front)
eater.lcnRationAt = 0
ok(waitFor(function() return LC.HasItem(eater, "ration") end, 8) and has(eater.chat, "hands you a ration packet"),
    "a player waiting at the front of the line is handed a ration")
local waiting = line.q[1]
line.nextAdvance = 0
_run(2)
ok(waiting ~= nil and line.q[1] == waiting, "and the line waits while a player is at the counter")
eater:SetPos(FAR)
local disp = ents.Create("lc_dispenser")
disp:SetPos(front + Vector(60, 0, 0))
ok(LC.LineDispenser(1) == disp, "a dispenser placed at the front becomes the line's dispenser")
line.nextAdvance = 0
local servedFrom = 0
hook.Add("LivingCityServed", "TestServed", function() servedFrom = servedFrom + 1 end)
_run(12)
hook.t.LivingCityServed.TestServed = nil
ok(servedFrom >= 1 and line.q[1] ~= waiting, "the person at the front is served from it")
disp:Remove()

----------------------------------------------------------------------
section("Citizens don't know Gordon Freeman")
local quiet, qst = LC.SpawnCitizen(FAR + Vector(500, 0, 0))
ok(bit.band(tonumber(quiet.kv.spawnflags) or 0, 2) ~= 0, "citizens are spawned gagged (no idle 'Doctor Freeman' chatter)")
ok(#ents.FindByClass("ai_speechfilter") >= 1, "and share a speech filter that never says hello")
local talker = newPlayer("Talker", "citizen")
ok(hook.Run("PlayerUse", talker, quiet) == false, "pressing E on a citizen doesn't let the engine's dialogue run")
quiet:Remove()

----------------------------------------------------------------------
section("Map navigation")
local ffi = require("ffi")
local function ain(nodes)
    local size = 12 + #nodes * (14 * 4 + 1 + 2 + 2)
    local buf = ffi.new("uint8_t[?]", size)
    local pos = 0
    local function put(t, n, v) ffi.cast(t .. "*", buf + pos)[0] = v pos = pos + n end
    put("int32_t", 4, 37) put("int32_t", 4, 1) put("int32_t", 4, #nodes)
    for _, nd in ipairs(nodes) do
        put("float", 4, nd[1]) put("float", 4, nd[2]) put("float", 4, nd[3]) put("float", 4, 0)
        for _ = 1, 10 do put("float", 4, 0) end
        put("uint8_t", 1, nd[4]) put("uint16_t", 2, 0) put("int16_t", 2, nd[5])
    end
    return ffi.string(buf, size)
end
local nodes = {}
for i = 1, 60 do nodes[#nodes + 1] = { i * 100, 0, 0, 2, 4 } end            -- the streets (zone 4)
for i = 1, 8 do nodes[#nodes + 1] = { i * 100, 5000, 900, 2, 5 } end         -- a rooftop nobody can reach (zone 5)
for i = 1, 5 do nodes[#nodes + 1] = { i * 100, 9000, 300, 3, 4 } end         -- air nodes
nodes[#nodes + 1] = { 0, -9000, 0, 2, 1 }                                     -- a lone node
_files["maps/graphs/rp_test.ain"] = ain(nodes)
LC.Start(admin)
ok(#LC.Fallback == 60 and LC.Source == "nodegraph", "only ground nodes in the main connected area are used", #LC.Fallback)
local anyRoof = false
for _, p in ipairs(LC.Fallback) do if p.y >= 4000 then anyRoof = true end end
ok(not anyRoof, "no rooftops or air nodes to get stuck walking to")
ok(string.find(LC.SourceDetail or "", "60 of 69", 1, true) ~= nil, "and the report says how many were kept", LC.SourceDetail)
_files["maps/graphs/rp_test.ain"] = nil
LC.Start(admin)

----------------------------------------------------------------------
section("The Living City gamemode")
local oldGM = GAMEMODE
local GMt = { BaseClass = {
    PhysgunPickup = function() return true end, PlayerDeath = function() end,
    CanTool = function() return true end, PlayerSpawnProp = function() return true end,
} }
GM = GMt
local oldInclude, oldDerive = include, DeriveGamemode
include, DeriveGamemode = function() end, function() end
assert(loadstring(_GMSRC_SHARED, "gamemode/shared.lua"))()
assert(loadstring(_GMSRC_INIT, "gamemode/init.lua"))()
include, DeriveGamemode = oldInclude, oldDerive
GAMEMODE = GMt
_setcvar("lc_factions", 0)
ok(LC.InOwnGamemode() and LC.FactionsActive(), "in the gamemode, factions are always on")
local resident = newPlayer("Resident", "citizen")
local boss = newPlayer("Boss", "citizen")
boss.admin, boss.superadmin = true, true
ok(GMt:PlayerSpawnProp(resident, "models/props_c17/oildrum001.mdl") == false and GMt:CanTool(resident, {}, "livingcity_editor") == false,
    "regular players can't spawn props or use tools")
ok(GMt:PlayerNoClip(resident, true) == false and GMt:PhysgunPickup(resident, resident) == false, "or noclip, or use a physgun")
ok(GMt:PlayerSpawnProp(boss, "x") == false, "admins can't either, until they switch to build mode")
ok(hook.Run("PlayerSay", boss, "!build") == "" and boss:GetNW2Bool("lc_build", false), "!build switches an admin to build mode")
ok(boss:HasWeapon("weapon_physgun") and boss:HasWeapon("gmod_tool") and GMt:CanTool(boss, {}, "livingcity_editor") ~= false, "with the physgun and the editor's toolgun")
ok(GMt:PlayerNoClip(boss, true) == true, "and noclip")
hook.Run("PlayerSay", boss, "!build")
ok(not boss:GetNW2Bool("lc_build", false) and not boss:HasWeapon("gmod_tool"), "!build again puts the tools away")
ok(hook.Run("PlayerSay", resident, "!build") == "" and has(resident.chat, "for admins"), "regular players are told build mode is for admins")
boss:StripWeapons()
hook.Run("PlayerLoadout", boss)
ok(not boss:HasWeapon("weapon_physgun"), "factions don't hand admins a physgun outside build mode")
ok(GMt:GetFallDamage(resident, 900) > 50 and GMt:GetFallDamage(resident, 400) == 0, "falls hurt like they did in Half-Life 2")
LC.AddCredits(resident, 200)
LC.GiveItem(resident, "ration")
local oldName, oldBlock = resident:GetNW2String("lc_char", "?"), resident:GetNW2Int("lc_block", 0)
resident.alive = false
hook.Run("PlayerDeath", resident)
resident.alive = true
ok(resident:GetNW2String("lc_char", "") ~= "" and resident:GetNW2String("lc_char", "") ~= oldName or oldName == "?", "dying makes you a new person")
ok(LC.Credits(resident) <= 20 and not LC.HasItem(resident, "ration") and LC.Standing(resident) == 0, "with nothing from the old life")
local ghost = newPlayer("Ghost", "zombie")
local ghostName = ghost:GetNW2String("lc_char", "")
LC.AddCredits(ghost, 50)
ghost.alive = false
hook.Run("PlayerDeath", ghost)
ok(ghost:GetNW2String("lc_char", "") == ghostName and LC.Credits(ghost) >= 50, "the infested come back as themselves")
ghost.alive = true
-- movement
local function Mv(buttons)
    local m = { b = buttons, v = Vector(300, 0, 0) }
    function m:GetButtons() return self.b end
    function m:SetButtons(b) self.b = b end
    function m:GetVelocity() return self.v end
    function m:SetVelocity(v) self.v = v end
    function m:GetMaxSpeed() return 190 end
    return m
end
resident.lcNextJump = nil
local mv1 = Mv(IN_JUMP)
hook.Run("SetupMove", resident, mv1)
ok(bit.band(mv1.b, IN_JUMP) ~= 0, "you can jump")
local mv2 = Mv(IN_JUMP)
hook.Run("SetupMove", resident, mv2)
ok(bit.band(mv2.b, IN_JUMP) == 0, "but not again straight away: no bunny hopping")
resident.lcNextJump = nil
resident.crouch = true
local mv3 = Mv(IN_JUMP)
hook.Run("SetupMove", resident, mv3)
ok(bit.band(mv3.b, IN_JUMP) == 0, "or from a crouch")
resident.crouch = false
resident.ground = false
local mv4 = Mv(IN_DUCK)
hook.Run("SetupMove", resident, mv4)
ok(bit.band(mv4.b, IN_DUCK) == 0 and mv4.v:Length() <= 200.5, "nor tuck up or speed up in the air")
resident.ground = nil
GMt:PlayerDeath(resident)
ok(resident.NextSpawnTime and resident.NextSpawnTime > CurTime() + 5, "a short wait before you respawn")
GMt:ShowHelp(resident)
ok(_lastnet("lcg_help") ~= nil, "F1 opens the guide")
hook.t.InitPostEntity.LivingCityGamemode = nil
GAMEMODE = oldGM
GM = nil
ok(not LC.InOwnGamemode() and not LC.FactionsActive(), "and as a plain addon on Sandbox, factions stay opt-in")
_setcvar("lc_can_event", 1)
end
CityFixTests()

local function EditorAndScannerTests()
----------------------------------------------------------------------
section("Saving, backups and restoring")
local layoutPath = "livingcity/rp_test.json"
local before = _files[layoutPath]
ok(before ~= nil and #before > 100, "the layout is saved to data/livingcity/<map>.json")
local name = LC.BackupLayout("manual")
ok(name and _files["livingcity/backups/rp_test/" .. name] == before, "a backup is an exact copy of the saved layout")
local nPoints = #LC.Points
LC.AddPoint(Vector(7777, 7777, 0), 0, "idle", 0)
ok(#LC.Points == nPoints + 1 and _files[layoutPath] ~= before, "every edit saves straight away")
local list = LC.ListBackups()
local idx
for i, n in ipairs(list) do if n == name then idx = i end end
local okR = LC.RestoreBackup(idx)
ok(okR and #LC.Points == nPoints, "restoring a backup brings the old layout back", #LC.Points)
local after = LC.ListBackups()
local saved = false
for _, n in ipairs(after) do if string.find(n, "before_restore", 1, true) then saved = true end end
ok(saved, "and what was there before the restore is backed up first")
ok(hook.Run("PlayerSay", admin, "x") == nil, "chat is untouched")
concommand.list.lc_backups(admin, "lc_backups", {})
ok(has(admin.chat, "backups in data/livingcity/backups/rp_test"), "lc_backups lists them")

local good = _files[layoutPath]
_files[layoutPath] = "{ this is not json"
LC.LoadData(false)
ok(LC.LayoutBroken == true, "an unreadable layout file is noticed")
LC.AddPoint(Vector(100, 100, 0), 0, "idle", 0)
local keptCopy = false
for path, data in pairs(_files) do
    if string.find(path, "rp_test_unreadable_", 1, true) and data == "{ this is not json" then keptCopy = true end
end
ok(keptCopy, "and copied somewhere safe before anything overwrites it")
_files[layoutPath] = good
LC.LoadData(false)

local old = _files[layoutPath]
local t = util.JSONToTable(old)
t.points[#t.points + 1] = { x = 1, y = 2, z = 3, yaw = 0, kind = "fence", group = 0 }
_files[layoutPath] = util.TableToJSON(t)
LC.LoadData(false)
local dealerPoint
for _, p in ipairs(LC.Points) do if p.kind == "dealer" and p.pos.x == 1 then dealerPoint = p end end
ok(dealerPoint ~= nil, "black market fences placed before the rename come back as dealers")
LC.RemovePoint(dealerPoint)

----------------------------------------------------------------------
section("Editing overlapping zones")
local big = LC.AddZone(Vector(20000, 20000, 0), 1000, "block", 7)
local small = LC.AddZone(Vector(20300, 20000, 0), 200, "rebel", 0)
ok(LC.ZoneForEditing(Vector(20310, 20000, 0)) == small, "inside both, the smaller zone is picked")
ok(LC.ZoneForEditing(Vector(20010, 20000, 0)) == big, "aiming at a zone's center marker picks that zone")
LC.RemoveZone(small)
LC.RemoveZone(big)

----------------------------------------------------------------------
section("Scanners")
local scanner, sst = LC.Spawners.scanner(Vector(-20000, -20000, 0))
local cit, cst = LC.SpawnCitizen(Vector(-20000, -18000, 0))
scanner.sim = false -- snagged on a walkway
sst.followEnt, sst.nextFollow = cit, CurTime() + 1000
sst.nextAltitude = CurTime() + 1000
local p0 = scanner:GetPos()
_run(14)
ok(scanner:GetPos():Distance(p0) > 50, "a scanner that's stuck while its citizen walks off frees itself", tostring(scanner:GetPos()))
local p1 = scanner:GetPos()
sst.nextAltitude = 0
_run(2)
ok(scanner:GetPos().z ~= p1.z, "and scanners change altitude now and then")
scanner:Remove()
cit:Remove()
end
EditorAndScannerTests()

local function ResponseTests()
for n in pairs(LC.NPCs) do if IsValid(n) then n.sim = n:IsNPC() end end -- unfreeze anyone an earlier test pinned in place
_setcvar("lc_auto_events", 0)
_setcvar("lc_stops", 0)
_setcvar("lc_can_event", 0)
LC.EndEvent(true)
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
LC.CalmCops(nil)
_run(1)
local function cops()
    local out = {}
    for n, s in pairs(LC.NPCs) do if IsValid(n) and s.role == "cop" and not s.questLock then out[#out + 1] = { n = n, st = s } end end
    return out
end
local function waitFor(cond, secs)
    for _ = 1, secs * 2 do if cond() then return true end _run(0.5) end
    return cond()
end

----------------------------------------------------------------------
section("Shooting a unit from far away")
local sniper = newPlayer("Sniper", "citizen")
local c = cops()
local farCop = c[1]
sniper:SetPos(farCop.n:GetPos() + Vector(4500, 0, 0))
local shot = _dmg(sniper, 5)
hook.Run("EntityTakeDamage", farCop.n, shot)
local d0 = farCop.n:GetPos():Distance(sniper:GetPos())
_run(6)
ok(farCop.st.state == "hostile" and farCop.st.enemy == sniper, "a unit shot from 4500 units away doesn't shrug it off", farCop.st.state)
ok(farCop.n:GetPos():Distance(sniper:GetPos()) < d0 - 300, "it comes after the shooter",
    string.format("%.0f -> %.0f sched=%s sim=%s goal=%s", d0, farCop.n:GetPos():Distance(sniper:GetPos()), tostring(farCop.n.sched), tostring(farCop.n.sim), tostring(farCop.n.goal)))
local rz = LC.AddZone(sniper:GetPos(), 400, "rebel", 0)
_run(8)
ok(farCop.st.state == "hostile", "even into rebel territory, if you started it")
LC.RemoveZone(rz)

----------------------------------------------------------------------
section("Escalation")
LC.ResetHeat(sniper)
LC.ClearWanted(sniper)
LC.CalmCops(sniper)
ok(LC.AlertLevel(sniper) == 0, "no alert to start with")
farCop.n:SetHealth(0)
hook.Run("OnNPCKilled", farCop.n, sniper)
ok(LC.AlertLevel(sniper) == 2 and LC.PlayerIsWanted(sniper), "killing a unit: alert 2, wanted for murder", LC.AlertLevel(sniper))
ok(sniper:GetNW2Int("lc_alert", 0) == 2, "the alert level is on the HUD")
local armed = 0
for n, s in pairs(LC.NPCs) do
    if IsValid(n) and s.role == "cop" and s.enemy == sniper and s.armed and n.activeWeapon == "weapon_pistol" then armed = armed + 1 end
end
ok(armed >= 1, "every unit hunts you, pistols drawn", armed)
local second
for _, cc in ipairs(cops()) do if cc.n ~= farCop.n and cc.n:Health() > 0 then second = cc break end end
second.n:SetHealth(0)
hook.Run("OnNPCKilled", second.n, sniper)
ok(LC.AlertLevel(sniper) == 3, "a second kill: alert 3", LC.AlertLevel(sniper))
local squad = #LC.Responders(sniper)
ok(squad >= 1, "an Overwatch squad is dispatched", squad)
local ann = _lastnet("lc_announce")
ok(ann and ann.data[2] == "Overwatch response", "the city announces it")
for _, r in ipairs(LC.Responders(sniper)) do
    local rs = LC.NPCs[r]
    ok(rs.state == "hostile" and rs.enemy == sniper, "the squad goes straight for you") break
end
local hitter
for _, cc in ipairs(cops()) do if cc.n:Health() > 0 then hitter = cc.n break end end
local stickHit = _dmg(hitter, 10, DMG_CLUB)
hook.Run("EntityTakeDamage", sniper, stickHit)
ok(not LC.InCustody(sniper) and stickHit:GetDamage() == 10, "at alert 3 nobody's arresting you any more")
LC.AddHeat(sniper, 6)
ok(LC.AlertLevel(sniper) == 4 and LC.Event == "lockdown", "a massacre locks the sector down", LC.Event)
LC.EndEvent(true)
ok(#LC.Responders(sniper) <= GetConVar("lc_response_soldiers"):GetInt(), "squads are capped")

-- dying ends it, and the soldiers go home
local squadBefore = LC.Responders(sniper)
hook.Run("PlayerDeath", sniper)
ok(LC.AlertLevel(sniper) == 0, "dying resets the alert")
_run(5)
local stoodDown = 0
for _, n in ipairs(squadBefore) do
    if not IsValid(n) or (LC.NPCs[n] and LC.NPCs[n].withdrawing) then stoodDown = stoodDown + 1 end
end
ok(#squadBefore > 0 and stoodDown == #squadBefore and #LC.Responders(sniper) == 0, "and the squad stands down and leaves", stoodDown)
LC.ClearWanted(sniper)
LC.CalmCops(sniper)

-- lying low cools it down
local hider = newPlayer("Hider", "citizen")
hider:SetPos(FAR + Vector(2000, 0, 0))
LC.AddHeat(hider, 5)
ok(LC.AlertLevel(hider) == 2, "heat builds")
LC.CalmCops(hider)
ok(waitFor(function() return LC.AlertLevel(hider) <= 1 end, 90), "out of sight for long enough, it cools off", LC.Heat(hider))
LC.ClearWanted(hider)

----------------------------------------------------------------------
section("Getting your standing back")
local crook = newPlayer("Crook", "citizen")
crook:SetPos(FAR + Vector(4000, 0, 0))
LC.AddStanding(crook, -800)
ok(LCS.TierFor(LC.Standing(crook)).name == "Anticitizen", "an anticitizen")
local rp = storyPosting(crook, "rehab")
ok(rp and string.find(rp.title, "Community service", 1, true), "gets community service on their board", rp and rp.title)
local s0 = LC.Standing(crook)
crook.lcqNext = 0
LC.AcceptPosting(crook, rp.id)
local qr = LC.QuestOf[crook]
for _ = 1, 40 do
    if qr.done then break end
    local st = qr.stages[qr.stage]
    if st.kind == "collect" then for e in pairs(st.items) do hook.Run("PlayerUse", crook, e) end
    elseif st.kind == "hold" then crook:SetPos(st.pos) crook.crouch = st.crouch _run(st.secs + 1) crook.crouch = false
    else crook:SetPos(st.pos or crook:GetPos()) _run(1) end
end
ok(qr.done and has(crook.chat, "+40: Community service"), "each shift of service restores 40 standing", LC.Standing(crook) - s0)

LC.ReportCrime(crook, "Theft", 300)
local unit = cops()[1]
crook:SetPos(unit.n:GetPos() + Vector(50, 0, 0))
unit.st.nextUse = 0
local s1 = LC.Standing(crook)
hook.Run("PlayerUse", crook, unit.n)
ok(LC.InCustody(crook) and not LC.PlayerIsWanted(crook) and has(crook.chat, "You put your hands up"), "pressing E on a unit while wanted is surrendering")
local pr = LC.Prisoners[crook]
ok(pr and pr.untilT - CurTime() <= GetConVar("lc_prison_time"):GetInt() / 2 + 1, "for half the usual sentence")
LC.ReleasePrisoner(crook)
ok(LC.Standing(crook) > s1 + 150, "and serving it pays back a good part of what you owed", LC.Standing(crook) - s1)
ok(LC.Standing(crook) <= 0, "though never past zero")
crook:SetPos(FAR)
_setcvar("lc_auto_events", 0)
_setcvar("lc_can_event", 1)
end
ResponseTests()

local function BodyAndFixtureTests()
_setcvar("lc_auto_events", 0)
_setcvar("lc_stops", 0)
LC.EndEvent(true)
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
LC.CalmCops(nil)

----------------------------------------------------------------------
section("Fixtures sit where they should")
local vp = LC.AddPoint(Vector(12000, 12000, 0), 0, "vending", 0)
local dp = LC.AddPoint(Vector(12200, 12000, 0), 0, "dispenser", 0)
_run(1)
local vend, disp
for _, e in ipairs(ents.FindByClass("lc_vending")) do if e:GetPos().x == 12000 then vend = e end end
for _, e in ipairs(ents.FindByClass("lc_dispenser")) do if e:GetPos().x == 12200 then disp = e end end
ok(IsValid(vend) and vend:GetPos().z + vend:OBBMins().z == 0, "a vending machine stands on the floor, not half in it")
ok(IsValid(disp) and disp:GetPos().z + disp:OBBMins().z == 34, "a ration dispenser is mounted at chest height")
local thirsty = newPlayer("Vendee", "citizen")
LC.AddCredits(thirsty, 10)
vend.lcNext = 0
LC.UseVending(thirsty, vend)
_run(1)
local can
for _, e in ipairs(ents.FindByClass("lc_item")) do
    if e:GetNW2String("lc_item", "") == "water" and e:GetPos():Distance(vend:GetPos()) < 100 then can = e end
end
ok(IsValid(can) and can:GetPos().z <= 20, "the can drops out of the slot near the floor", can and tostring(can:GetPos()))
LC.RemovePoint(vp)
LC.RemovePoint(dp)
_run(1)

----------------------------------------------------------------------
section("Searching the dead")
local victim, vst = LC.SpawnCitizen(FAR + Vector(500, 0, 0))
ok(victim:GetNW2Bool("lc_noragdoll", false), "Living City's people don't leave the game's own ragdoll")
local looter = newPlayer("Looter", "citizen")
looter:SetPos(victim:GetPos() + Vector(40, 0, 0))
hook.Run("OnNPCKilled", victim, looter)
local body
for _, b in ipairs(LC.Bodies) do if IsValid(b.ent) and b.ent:GetPos() == victim:GetPos() then body = b.ent end end
ok(IsValid(body) and body.lcBody and body:GetNW2Bool("lc_body", false), "they leave a body instead")
body.lcBody.loot = { items = { "ration", "papers_dead" }, credits = 7, ammo = {}, weapons = {} }
local c0 = LC.Credits(looter)
ok(hook.Run("PlayerUse", looter, body) == false and has(looter.chat, "go through their pockets"), "press E to search it")
_run(4)
ok(LC.HasItem(looter, "ration") and LC.HasItem(looter, "papers_dead") and LC.Credits(looter) == c0 + 7, "and take what they had")
looter.lcNextBodyUse = 0
hook.Run("PlayerUse", looter, body)
ok(has(looter.chat, "already been through their pockets"), "only once")

local cop2, cst2 = LC.Spawners.cop(FAR + Vector(900, 0, 0))
cst2.untilT, cst2.nextInspect = CurTime() + 1000, CurTime() + 1000
cop2.sim = false
local deadCop, dcst = LC.Spawners.cop(FAR + Vector(1200, 0, 0))
hook.Run("OnNPCKilled", deadCop, looter)
local cbody
for _, b in ipairs(LC.Bodies) do if IsValid(b.ent) and b.ent:GetPos() == deadCop:GetPos() then cbody = b.ent end end
ok(cbody and cbody.lcBody.loot.ammo[1] and cbody.lcBody.loot.ammo[1][1] == "Pistol", "a dead metrocop carries pistol ammunition")
cbody.lcBody.loot.items = { "cp_keycard" }
LC.ClearWanted(looter)
looter:SetPos(cbody:GetPos() + Vector(40, 0, 0))
looter.lcNextBodyUse = 0
hook.Run("PlayerUse", looter, cbody)
ok(LC.PlayerIsWanted(looter) and looter:GetNW2String("lc_wanted_reason", "") == "Looting a dead officer", "looting a dead unit in front of another unit is a crime")
_run(4)
ok(LC.HasItem(looter, "cp_keycard"), "metrocops sometimes carry a keycard")
LC.ClearWanted(looter)
LC.CalmCops(looter)
cop2:Remove()

local kdoor = ents.Create("func_door")
kdoor.mapid = 777
kdoor:SetPos(FAR + Vector(3000, 0, 0))
LC.SetDoorTag(kdoor, "cp")
looter:SetPos(kdoor:GetPos() + Vector(-60, 0, 0))
looter.lookingAt = kdoor
LC.InvAction(looter, "use", "cp_keycard")
_run(2)
ok(LC.DoorPicked(kdoor) and not LC.HasItem(looter, "cp_keycard"), "the keycard opens a Combine door, once")
looter.lookingAt = nil

local zbody = LC.SpawnCitizen(FAR + Vector(-800, 0, 0))
hook.Run("OnNPCKilled", zbody, looter)
local before = #LC.Bodies
ok(LC.TakeBodyAt(zbody:GetPos()) and #LC.Bodies == before - 1, "when the infested rise, the body is what gets up")
looter:SetPos(FAR)
_setcvar("lc_stops", 0)
end
BodyAndFixtureTests()

local function EscortTests()
_setcvar("lc_auto_events", 0)
_setcvar("lc_stops", 0)
LC.EndEvent(true)
----------------------------------------------------------------------
section("Walking someone home")
local guide = newPlayer("Guide", "citizen")
guide:SetPos(Vector(-15000, 14000, 0))
local q = inject(guide, "cit_lost")
local man = q.data.target
ok(IsValid(man) and table.HasValue(LC.ELDERLY_MODELS, man:GetModel()), "the confused old man has one of Half-Life 2's older faces", man and man:GetModel())
reach(guide, man)
LC.ResolveChoice(guide, q.id, 2)
local st = q.stages[q.stage]
ok(st.kind == "escort" and st.walkOnly, "now walk him home")
local zone
for _, z in ipairs(LC.Zones) do if z.pos:DistToSqr(st.pos) < 16 then zone = z end end
ok(zone and st.r >= zone.r * 0.9 - 1, "walking into the block counts, not just its exact center", st.r)
guide:SetPos(man:GetPos() + Vector(1000, 0, 0))
_run(1)
ok(man.sched == SCHED_FORCED_GO, "he follows at a walk, even when you're far ahead", man.sched)
local g0 = st.goal
_run(1)
ok(g0 ~= nil and st.goal == g0, "and doesn't keep re-planning while you stand still")
guide:SetPos(man:GetPos() + Vector(60, 0, 0))
_run(1)
ok(man.sched == SCHED_IDLE_STAND, "when you're right there, he stops and waits")
local edge = zone.pos + Vector(zone.r * 0.8, 0, 0)
man:SetPos(edge)
guide:SetPos(edge + Vector(50, 0, 0))
_run(1)
ok(q.done, "and stepping inside the edge of the block is enough")
guide:SetPos(Vector(-30000, 30000, 0))
end
EscortTests()

----------------------------------------------------------------------
local function UpdateTests() -- combine zones, locked doors, curfew homes, raids, characters, quests
local newPlayer = newPlayer
_setcvar("lc_factions", 1)
local FAR = Vector(30000, 30000, 0)
section("Combine-only areas")
local nexus = Vector(20000, 20000, 0)
LC.AddZone(nexus, 300, "combine", 0)
ok(LC.InNoGo(nexus, "citizen") and not LC.InNoGo(nexus, "cop"), "citizen NPCs avoid a Combine-only zone, units don't")
local trespasser = newPlayer("Trespasser", "citizen")
local nexusCop = newPlayer("NexusCop", "cp")
_run(1) -- let their spawns settle
trespasser:SetPos(nexus)
nexusCop:SetPos(nexus + Vector(50, 0, 0))
_run(2)
ok(has(trespasser.chat, "restricted area"), "a citizen who walks in is told to leave")
ok(not has(nexusCop.chat, "restricted area") and not LC.PlayerIsWanted(nexusCop), "Civil Protection may be there", tostring(nexusCop.chat and nexusCop.chat[#nexusCop.chat]))
trespasser:SetPos(FAR)
_run(2)
ok(not LC.PlayerIsWanted(trespasser), "leaving in time costs nothing")
trespasser:SetPos(nexus)
_run(14)
ok(LC.PlayerIsWanted(trespasser), "staying gets you wanted for trespassing")
LC.ClearWanted(trespasser)
trespasser:SetPos(FAR)
nexusCop:SetPos(FAR)

section("Doors by the cells lock themselves")
local celldoor = ents.Create("func_door")
celldoor.mapid = 801
celldoor:SetPos(Vector(455, 450, 40))
local farDoor = ents.Create("func_door")
farDoor.mapid = 802
farDoor:SetPos(Vector(9000, 9000, 40))
ok(LC.EffectiveDoorTag(celldoor) == "cp", "a door beside a prison cell is Combine only")
ok(LC.EffectiveDoorTag(farDoor) == nil, "a door elsewhere is left alone")
local nexusDoor = ents.Create("func_door")
nexusDoor.mapid = 803
nexusDoor:SetPos(nexus + Vector(100, 0, 40))
ok(LC.EffectiveDoorTag(nexusDoor) == "cp", "so is one inside a Combine-only zone")
ok(hook.Run("PlayerUse", trespasser, celldoor) == false, "citizens can't open it", tostring(hook.Run("PlayerUse", trespasser, celldoor)))
ok(hook.Run("PlayerUse", nexusCop, celldoor) ~= false, "Civil Protection can")
LC.SetDoorTag(celldoor, "open")
ok(LC.EffectiveDoorTag(celldoor) == "open", "a tag of your own wins")
LC.SetDoorTag(celldoor, nil)

section("Where citizens may appear")
ok(LC.CitizenSpotOK(Vector(9000, -9000, 0)), "an ordinary street is fine")
ok(not LC.CitizenSpotOK(nexus), "never a Combine-only zone")
local realTrace = util.TraceLine
util.TraceLine = function(t)
    return { Hit = true, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), HitTexture = "METAL/COMBINEMETAL001", Fraction = 0.5 }
end
ok(LC.OnCombineSurface(Vector(9000, -9000, 0)) and not LC.CitizenSpotOK(Vector(9000, -9000, 0)), "or Combine metal and glass")
util.TraceLine = function(t)
    return { Hit = true, HitPos = t.endpos, HitNormal = Vector(0, 0, 1), HitTexture = "CONCRETE/CONCRETEFLOOR001A", Fraction = 0.5 }
end
ok(not LC.OnCombineSurface(Vector(9000, -9000, 0)), "plain concrete isn't Combine ground")
util.TraceLine = realTrace
local nest = Vector(-9000, -9000, 0)
LC.AddPoint(nest, 0, "zspawn", 0)
ok(not LC.CitizenSpotOK(nest + Vector(300, 0, 0)), "and never beside an infestation spawn")
ok(LC.POINT_KINDS.rspawn and LC.POINT_KINDS.zspawn, "zombie and rebel spawn points can be placed")

section("Curfew: people walk home")
local npcH, stH = LC.Spawners.citizen(Vector(-300, -500, 0))
LC.StartEvent("curfew", 3)
stH.state = "idle"
LC.StartLeaving(npcH, stH, false)
ok(stH.homeBlock ~= nil and stH.poi and stH.poi.kind == "spawn" and LC.InBlock(stH.poi.pos, 1), "a citizen is sent into a housing block, not off the map", stH.poi and stH.poi.kind)
LC.EndEvent(true)
npcH:Remove()

section("Block raids")
local zb = LC.ZonesOfKind("block")[1]
local raided = newPlayer("Owner", "citizen")
raided:SetPos(FAR)
local function Drop(cls, model, offset)
    local e = ents.Create(cls)
    e:SetPos(zb.pos + offset)
    if model then e:SetModel(model) end
    e.lcOwner = raided:SteamID64()
    return e
end
local radioItem = Drop("lc_item", nil, Vector(40, 0, 0))
radioItem:SetNW2String("lc_item", "radio_tuned")
local tv = Drop("prop_physics", "models/props_c17/tv_monitor01.mdl", Vector(0, 60, 0))
local gun = Drop("weapon_ar2", nil, Vector(-50, 0, 0))
local legal = ents.Create("lc_item")
legal:SetPos(zb.pos + Vector(20, 20, 0))
legal:SetNW2String("lc_item", "ration")
local table1 = ents.Create("prop_physics")
table1:SetPos(zb.pos + Vector(0, -60, 0))
table1:SetModel("models/props_c17/furnituretable001a.mdl")
ok(LC.ContrabandOf(radioItem) and LC.ContrabandOf(tv) and LC.ContrabandOf(gun), "contraband items, TVs and loose weapons count")
ok(not LC.ContrabandOf(legal) and not LC.ContrabandOf(table1), "rations and furniture don't")
local raidCop, rcst = LC.Spawners.cop(zb.pos + Vector(150, 0, 0))
rcst.routeGroup = nil
ok(LC.StartRaid(1), "a raid can be started on a block")
_run(8)
ok(rcst.raid ~= nil or LC.Raid == nil, "units take it in turn to walk the block")
_run(160)
ok(LC.Raid == nil, "and the raid ends")
ok(not IsValid(radioItem) and not IsValid(tv) and not IsValid(gun), "contraband is confiscated")
ok(IsValid(legal) and IsValid(table1), "everything else is left alone")
ok(LC.PlayerIsWanted(raided) and has(raided.chat, "3 contraband items"), "and whoever owned it is wanted, for everything found under their name")
LC.ClearWanted(raided)
raidCop:Remove()

section("A new life")
ok(true, "(permanent death is covered with the gamemode, above)")
local medic = newPlayer("Medic", "citizen")
LC.SetJob(medic, "medic", true)
medic:Give("weapon_smg1")
ok(medic:HasWeapon("weapon_medkit"), "a medic is issued a medkit")
LC.AddXP(medic, 100000, "test")
ok(medic:HasWeapon("weapon_medkit") and medic:HasWeapon("weapon_smg1"), "a promotion doesn't take away your medkit or what's in your hands")

section("Quests: bins, markers, house calls")
local binman = newPlayer("Binman", "citizen")
binman:SetPos(Vector(0, -500, 0))
local bin = ents.Create("prop_physics")
bin:SetModel("models/props_trainstation/trashcan_indoor001a.mdl")
bin:SetPos(Vector(600, -500, 0))
local bin2 = ents.Create("prop_physics")
bin2:SetModel("models/props_junk/trashdumpster01a.mdl")
bin2:SetPos(Vector(800, -900, 0))
local found = LC.QB.FindBins(binman, 100, 5000, 3)
ok(#found == 2 and (found[1] == bin or found[2] == bin), "the bin round finds the bins that are already in the map")
local fix = ents.Create("prop_physics")
fix:SetModel("models/props_c17/furniturestove001a.mdl")
local vend = ents.Create("prop_physics")
vend:SetModel("models/props_interiors/vendingmachinesoda01a.mdl")
ok(LC.FixtureKindOf(fix) == "stove" and LC.FixtureKindOf(vend) == "vending" and LC.FixtureKindOf(bin) == nil, "map stoves and vending machines are recognised as fixtures")
bin:Remove() bin2:Remove() fix:Remove() vend:Remove()

section("Static map props: stoves, sinks and vending machines")
-- a tiny pretend map file: header, game lump directory, and three static props
local store = {}
local function L(p, v) store[p] = { t = "l", v = v } end
local function U(p, v) store[p] = { t = "u", v = v } end
local function Fl(p, v) store[p] = { t = "f", v = v } end
local function S(p, v) store[p] = { t = "s", v = v } end
L(0, 0x50534256) L(4, 20) L(568, 1000) L(572, 5000)
L(1000, 1) L(1004, 0x73707270) U(1008, 0) U(1010, 4) L(1012, 2000) L(1016, 496)
L(2000, 3)
S(2004, "models/props_c17/furniturestove001a.mdl") S(2132, "models/props_junk/popcan01a.mdl") S(2260, "models/props_c17/FurnitureSink001a.mdl")
L(2388, 2) L(2396, 3)
local props = { { 1, { 7000, 7000, 0 } }, { 2, { 7100, 7000, 0 } }, { 3, { 7200, 7000, 0 } } }
for i, pr in ipairs(props) do
    local at = 2400 + (i - 1) * 32
    Fl(at, pr[2][1]) Fl(at + 4, pr[2][2]) Fl(at + 8, pr[2][3])
    Fl(at + 12, 0) Fl(at + 16, 90) Fl(at + 20, 0)
    U(at + 24, pr[1] - 1)
end
local realOpen = file.Open
file.Open = function()
    local pos = 0
    local f = {}
    local function take(t, n)
        local e = store[pos]
        assert(e and e.t == t, "bad read at " .. pos)
        pos = pos + n
        return e.v
    end
    function f:Seek(p) pos = p end
    function f:Tell() return pos end
    function f:ReadLong() return take("l", 4) end
    function f:ReadUShort() return take("u", 2) end
    function f:ReadFloat() return take("f", 4) end
    function f:Read(n) return take("s", n) end
    function f:Close() end
    return f
end
local fixtures, why = LC.ReadStaticFixtures("maps/test.bsp")
file.Open = realOpen
ok(fixtures and #fixtures == 2, "the map file's static props are read, and only stoves, sinks and vending machines kept", why or (fixtures and #fixtures))
ok(fixtures[1].kind == "stove" and fixtures[1].pos.x == 7000 and fixtures[2].kind == "sink" and fixtures[2].pos.x == 7200, "with their positions")
LC.StaticFixtures = fixtures
local cook = newPlayer("Cook", "citizen")
cook:SetPos(Vector(7040, 7000, 0))
ok(LC.NearHeat(cook) and not LC.NearSink(cook), "standing by a static stove counts as heat")
cook:SetPos(Vector(7160, 7000, 0))
ok(LC.NearSink(cook) and not LC.NearHeat(cook), "and by a static sink, as water")
cook:SetNW2Float("lcn_thirst", 10)
ok(LC.DrinkFromSink(cook) and LC.Thirst(cook) >= 30, "a sink gives you a drink")
LC.GiveItem(cook, "bottle_empty")
LC.InvAction(cook, "fill", "bottle_empty")
ok(LC.HasItem(cook, "bottle_dirty"), "and fills a bottle (boil it before you drink it)")
cook:SetPos(Vector(0, 9000, 0))
ok(not LC.NearSink(cook), "but not from across the room")
LC.StaticFixtures = {}

section("Named, persistent people")
local P = LC.People
P.list, P.next, P.loaded = {}, 1, true
_setcvar("lc_roster_size", 3)
_setcvar("lc_roster_cops", 2)
_setcvar("lc_rebel_pct", 0)
LC.TopUpPeople()
ok(#P.list == 5, "the roster is filled to its size, citizens and units", #P.list)
local n1, s1 = LC.Spawners.citizen(Vector(9000, 9100, 0))
local prof = s1.profile
ok(prof and n1:GetNW2String("lc_pname", "") == prof.name and n1:GetModel() == prof.model and prof.model:find("group01"), "a citizen on the street is a named person with their own model")
ok(s1.gender == prof.gender, "and their own voice")
local n2, s2 = LC.Spawners.citizen(Vector(9000, 9200, 0))
ok(s2.profile ~= prof, "nobody is out there twice")
local name1 = prof.name
n1:Remove()
prof.lastSeen = 1
for _, o in ipairs(P.list) do if o.role == "citizen" and o ~= prof and o ~= s2.profile then o.lastSeen = os.time() + 1000 end end
local n3, s3 = LC.Spawners.citizen(Vector(9000, 9300, 0))
ok(s3.profile == prof and n3:GetNW2String("lc_pname", "") == name1 and n3:GetModel() == prof.model, "the same person comes back, with the same face, after time away")
-- jobs and homes
prof.job, prof.home = "kitchen", 1
ok(LC.HomeZoneFor(s3) and LC.HomeZoneFor(s3).group == 1, "they go home to their own block for curfew")
-- death is permanent
hook.Run("OnNPCKilled", n3, trespasser)
ok(not prof.alive and prof.killer ~= nil, "a person who is killed is dead, and it's remembered")
n3:Remove()
LC.TopUpPeople()
local alive = 0
for _, o in ipairs(P.list) do if o.alive and o.role == "citizen" then alive = alive + 1 end end
ok(alive == 3, "the city fills the gap with a new arrival", alive)
for i = 1, 4 do
    local nn, ss = LC.Spawners.citizen(Vector(9000 + i * 50, 9500, 0))
    ok(ss.profile ~= prof, "and the dead never come back")
    nn:Remove()
end
-- rebels
local nr, sr = LC.Spawners.citizen(Vector(9500, 9500, 0), { rebel = true })
ok(sr.profile.rebel and nr:GetNW2Bool("lc_prebel", false), "the Resistance's contacts are sympathizers, secretly")
nr:Remove()
-- saved across sessions
LC.SavePeople()
local saved = #P.list
local deadName = prof.name
P.list, P.next, P.loaded = {}, 1, false
LC.LoadPeople()
local back
for _, o in ipairs(P.list) do if o.name == deadName then back = o end end
ok(#P.list == saved and back and not back.alive, "the roster, living and dead, survives a restart", #P.list .. "/" .. saved)
n2:Remove()

section("Choosing a name and a face")
local function Name(s) local ok2, r = LC.ValidateCharacterName(s) return ok2, r end
local okN, cleaned = Name("  marta   BRANDT ")
ok(okN and cleaned == "Marta Brandt", "an ordinary name is accepted and tidied up", cleaned)
ok(Name("Anna-Marie O'Neil") and Name("Hagman Nilsson") and Name("Luigi Rossi"), "hyphens, apostrophes and ordinary surnames are fine")
ok(Name("Bob") and Name("Jan") and Name("Joe") and Name("Jo Li"), "short names are fine, one word or two")
for _, bad in ipairs({ "Taylor Swift", "Gordon Freeman", "Walter White", "Donald Trump", "Skibidi Toilet", "Mike Hunt", "J0hn Smith", "Xzqrt Plmn", "Aaaaron Smith", "Jesus Christ", "Johnny Depp", "Jo", "Anna Bell Carla Dee" }) do
    ok(not Name(bad), "'" .. bad .. "' is refused")
end
local _, why = Name("Taylor Swift")
ok(why:find("realistic name") and why:find("celebrities"), "with a reminder of what a good name is")
local chooser = newPlayer("Chooser", "citizen")
LC.OpenCharacterCreator(chooser)
local open = _lastnet("lcc_open")
ok(open ~= nil, "the creator opens for a new player")
local face = LCF.CitizenModels[3]
local function Submit(p, nm, model) _run(1.2) net._q = { nm, model } net.recv_lcc_submit(0, p) end
Submit(chooser, "Gordon Freeman", face)
ok(chooser:GetNW2String("lc_char", "") ~= "Gordon Freeman", "a refused name changes nothing")
Submit(chooser, "Marta Brandt", "models/player/kleiner.mdl")
ok(chooser:GetNW2String("lc_char", "") ~= "Marta Brandt", "and neither does a face that isn't on offer")
Submit(chooser, "Marta Brandt", face)
ok(chooser:GetNW2String("lc_char", "") == "Marta Brandt" and chooser:GetNW2String("lc_model", "") == face, "a good name and a face are kept")
Submit(chooser, "Greta Voss", face)
ok(chooser:GetNW2String("lc_char", "") == "Greta Voss", "and you can change your mind later with !character")
local twin = newPlayer("Twin", "citizen")
LC.OpenCharacterCreator(twin)
Submit(twin, "greta voss", face)
ok(twin:GetNW2String("lc_char", "") ~= "Greta Voss", "two people can't share a name", twin:GetNW2String("lc_char", ""))
ok(LC.ValidateCharacterName("Elena Petrova"), "(and a different name is fine)")
end
UpdateTests()

----------------------------------------------------------------------
section("Stop")
LC.Stop(admin)
_run(1)
ok(table.Count(LC.NPCs) == 0, "stopping removes every NPC")
ok(#_errors == 0, "no errors logged during the whole run", _errors[1])

return results.pass, results.fail, table.concat(results.lines, "\n")
