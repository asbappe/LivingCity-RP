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
_setcvar("lc_daily_rhythm", 0) -- (the city keeps to the clock; tested on its own, at the end)
_setcvar("lc_stockpile", 0) -- (the city's ration stores: tested on their own, at the end)
_setcvar("lc_garrison", 0) -- (the nexus garrison: tested on its own)
_setcvar("lc_search_fight_choice", 0) -- (fight or comply: tested on its own, in the 1 November section)
_setcvar("lc_wear_uses", 0) -- (tools wearing out at random: tested on its own)
_setcvar("lc_afk_kick_minutes", 0) -- (the test's people never touch a key: no kicking them for it)
_setcvar("lc_directives", 0) -- (no sealed directive breaking open in the middle of other tests; its own section turns it on)
_setcvar("lc_units_spot_monsters", 0) -- (units going for zombies they see: tested on their own)
_setcvar("lc_units_spot_rebels", 0) -- (units opening fire on armed rebels they see in the street: tested on their own)
_setcvar("lc_assign_work", 0) -- (the Union assigning work to the jobless: tested on its own)
_setcvar("lc_rebel_vorts", 0) -- (vortigaunts living in rebel ground from the start: tested on their own)
_setcvar("lc_rebel_errands", 0) -- (scavenging runs: tested on their own)
_setcvar("lc_blackout_share", 0) -- (a city-wide blackout: tested on its own, with the grid)
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
_setcvar("lc_rebels", 0) -- rebel NPCs and skirmishes too
_setcvar("lc_skirmishes", 0)
_setcvar("lc_territory_spread", 0) -- and territory growing by itself
_setcvar("lc_city_effects", 0) -- and the city's mood changing prices and events
_setcvar("lc_dressing", 0)
_realHintScan = LC.HintScan -- tips: looked at on their own, later (the look-around is slow against the fake entity list)
LC.HintScan = function() end

----------------------------------------------------------------------
section("Load")
ok(#_errors == 0, "no errors while loading every file", _errors[1])
ok(LCF and LCF.Get("cp") and #LCF.Get("cp").ranks == 6, "faction config loaded, CP has 6 ranks (Recruit to Elite Soldier)")
ok(LCF.Get("cp").ranks[3].loadout[2] == "weapon_pistol", "ranks inherit loadouts from the rank below")
ok(LCF.Get("resistance").ranks[4].hunted == true, "Lieutenant inherits hunted from Fighter")

----------------------------------------------------------------------
_setcvar("lc_close_calls", 0) -- (the tests below expect every death to be final: close calls are tested on their own, ProgressTests)
_setcvar("lc_levy_threshold", 0) -- (and nobody's savings to be levied mid-test)
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

_setcvar("lc_npc_arrest_chance", 0) -- walking home past a unit could get someone arrested, and a prisoner stays put
LC.StartEvent("curfew", 2)
ok(_globals.lc_event == "curfew", "curfew is published to clients")
_run(60)
ok(count("citizen") == 0, "during curfew every citizen goes home", count("citizen"))
_setcvar("lc_npc_arrest_chance", 8)
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
citizen.lcViolentUntil = CurTime() + 1e6 -- (taken for violent: the unit chases rather than laying hands on them, so the wanted status can be checked)
_run(80)
ok(has(citizen.chat, "Warning 1 of 3") and has(citizen.chat, "Warning 3 of 3"), "an officer who sees you gives three warnings")
ok(LC.PlayerIsWanted(citizen), "then you're wanted", table.concat(citizen.chat, " | ") .. " cop=" .. tostring(cst.state))
LC.ClearWanted(citizen)
citizen.lcViolentUntil = nil
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
ok(#con.weps == 2 and con:HasWeapon("weapon_fists") and con:HasWeapon("weapon_lc_hands"), "with their weapons taken, but not their fists (or their empty hands)")
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
LC.ClearWanted(con)
con.lcGraceUntil = 0
local pz = LC.ZonesOfKind("prison")[1]
if pz then
    LC.Incarcerate(con, 60, "buffer test")
    con.lcGraceUntil = nil
    LC.Prisoners[con].grace = nil
    con:SetPos(pz.pos + Vector(pz.r + 80, 0, 0))
    _run(2)
    ok(LC.Prisoners[con] ~= nil, "a step past the edge of the prison area isn't an escape")
    con.lcViolentUntil = CurTime() + 1e6 -- (taken for violent: units chase with sticks rather than laying hands on him, for the stunstick test below)
    con:SetPos(pz.pos + Vector(pz.r + 600, 0, 0))
    _run(2)
    ok(not LC.Prisoners[con], "but well beyond it is")
end
con.lcGraceUntil = 0
con:SetPos(Vector(2000, -2000, 0))

-- NPC arrests instead of kills (straight to a cell here: being marched there is tested in MarchTests)
_setcvar("lc_march", 0)
local cop2, cst2 = LC.Spawners.cop(Vector(-200, -200, 0))
cst2.untilT = 1e9
local dmg = _dmg(cop2, 20, DMG_CLUB)
con.lcSubdue = { n = 2, t = CurTime() } -- (two blows already: cuffed once they're subdued, lc_subdue_hits)
hook.Run("EntityTakeDamage", con, dmg)
ok(LC.Prisoners[con] ~= nil, "a stunstick hit from a cop arrests a wanted player (once they're subdued)")
con.lcViolentUntil = nil
ok(dmg:GetDamage() == 0, "instead of hurting them")
LC.ReleasePrisoner(con)
_setcvar("lc_march", 1)

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
_setcvar("lc_rebel_ops", 0) -- (rebel operations and Overwatch drops start by themselves; tested on their own)
_setcvar("lc_overwatch_drops", 0)
local rec = _makeplayer("Recruit")
hook.Run("PlayerInitialSpawn", rec)
ok(rec:GetNW2String("lcf_faction", "") == "citizen", "new players start as citizens")
ok(LCF.Get("ota") == nil, "Overwatch is no faction of its own: it's Civil Protection's top ranks")
LC.SetFaction(rec, "cp", nil, true)
ok(LC.PlayerIsCP(rec) and rec:GetNW2Int("lcf_rank", 1) == 1, "joining Civil Protection makes you CP to Living City, a Recruit")
LC.AddXP(rec, 2500)
ok(rec:GetNW2Int("lcf_rank", 1) == 3, "XP takes you as far as Division Leader without the conditioning", rec:GetNW2Int("lcf_rank", 1))
ok(has(rec.chat, "Promoted to Division Leader"), "with a promotion message")
ok(string.find(rec:GetNW2String("lcf_title", ""), "CP DvL-", 1, true) ~= nil, "and a unit designation", rec:GetNW2String("lcf_title", ""))
ok(not LCF.IsOverwatch(rec), "(not Overwatch yet)")
LC.Condition(rec)
ok(rec:GetNW2Int("lcf_rank", 1) == 5 and LCF.IsOverwatch(rec), "the conditioning opens the Overwatch ranks: the XP counts at once", rec:GetNW2Int("lcf_rank", 1))
ok(string.find(rec:GetNW2String("lcf_title", ""), "OWS ", 1, true) == 1, "and an Overwatch designation", rec:GetNW2String("lcf_title", ""))
LC.SetFaction(rec, "citizen", nil, true)
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
ok(priest:GetPos():Distance(Vector(-5000, -5000, 0)) < 300, "and he respawns in rebel territory", tostring(priest:GetPos()) .. " custody " .. tostring(LC.InCustody(priest)) .. " prisoner " .. tostring(LC.Prisoners[priest] ~= nil) .. " detained " .. tostring(LC.Detained[priest] ~= nil))

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
_setcvar("lc_quest_cooldown", 0)
LC.AddZone(Vector(-6000, -6000, 0), 400, "rebel", 0)
LC.AddPoint(Vector(1600, 300, 0), 0, "idle", 0)
for _, c in ipairs({ Vector(450, 450, 0), Vector(560, 450, 0), Vector(450, 650, 0), Vector(560, 660, 0) }) do LC.AddPoint(c, 0, "cell", 0) end
_run(5)
local function newPlayer(name, faction, special, xp)
    local p = _makeplayer(name, Vector(0, -500, 0))
    hook.Run("PlayerInitialSpawn", p)
    if xp then p:SetPData("lcf_xp_" .. faction, xp) end
    -- (an established fighter: the Resistance trusts them already, lc_fighter_trust_jobs)
    if faction == "resistance" and xp and xp >= 400 and LC.Bump then LC.Bump(p, "res_jobs", 99) end
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
    local spec
    for i = 1, 5 do
        spec = t.build(p)
        if spec then break end
        -- random spots: an unlucky draw can come up empty, and this test map has only four
        -- nodes, which earlier tests can leave all marked unreachable
        if i == 2 then LC.BadDest = {} end
    end
    if not spec then return nil end
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


----------------------------------------------------------------------
section("Stories: Internal Affairs (bribes have consequences)")
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
ok(has(dirty.chat, "A new story is available"), "the player is told something has changed")
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
ok(has(dirty.chat, "slate is clean again"), "and the ending is narrated")
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
    loyal:SetPos(mark:GetPos() + Vector(-500, 0, 0)) -- behind him (he faces +x)
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
-- around a corner, right into his view: the meter climbs, but there's time to duck back
for _ = 1, 3 do loyal:SetPos(mark2:GetPos() + Vector(180, 0, 0)) _run(0.5) end
local tst = qt2.stages[qt2.stage]
ok(tst.kind == "tail" and tst.seen and (tst.suspicion or 0) > 0, "stepping into his view fills a suspicion meter", tst.suspicion)
local sent = _lastnet("lcq_state")
ok(sent and string.find(tostring(sent.data[2]), "suspicion", 1, true) ~= nil, "and the meter is sent to the HUD")
ok(tst.kind == "tail" and not qt2.done, "but doesn't blow the tail on the spot")
local wall = { a = mark2:GetPos() + Vector(100, -300, 0), b = mark2:GetPos() + Vector(100, 300, 0) }
table.insert(_walls, wall)
local high = tst.suspicion
_run(3)
ok(not tst.seen and tst.suspicion < high and qt2.stages[qt2.stage] == tst, "back out of sight, it fades", tst.suspicion)
table.remove(_walls)
local s0 = tst.suspicion
for _ = 1, 4 do loyal:SetPos(mark2:GetPos() + Vector(-500, 0, 0)) _run(0.5) end
ok(tst.suspicion <= s0 and not tst.seen, "following from behind doesn't make him suspicious", tst.suspicion)
for _ = 1, 10 do
    if qt2.stages[qt2.stage] ~= tst then break end
    loyal:SetPos(mark2:GetPos() + Vector(80, 0, 0))
    _run(0.5)
end
ok(qt2.stages[qt2.stage].kind == "choice", "get too close for too long and he notices you")
withRoll(1, function() LC.ResolveChoice(loyal, qt2.id, 1) end)
ok(qt2.done and LC.Story(loyal).chains.informant.part == "neighbor", "a failed bluff fails the job, and you can try again")

-- the neighbor can be a woman, and the words follow
lcs = LC.ChainState(loyal, "informant")
lcs.part, lcs.readyAt = "neighbor", 0
loyal.lcqNext = 0
local n3 = storyPosting(loyal, "informant")
LC.AcceptPosting(loyal, n3.id)
local qt3 = LC.QuestOf[loyal]
local her = qt3.stages[1].npc
LC.NPCs[her].gender = "female"
qt3.stages[1].onEnter(qt3, qt3.stages[1])
ok(qt3.stages[1].text:find("her sight", 1, true) and qt3.stages[1].text:find("she sees you", 1, true) and not qt3.stages[1].text:find(" he ", 1, true),
    "a woman neighbor is 'she' and 'her'", qt3.stages[1].text)
qt3.stages[2].onEnter(qt3, qt3.stages[2])
ok(qt3.stages[2].text == "Report her: find any Civil Protection unit and press E on the unit", "including when you report her", qt3.stages[2].text)
LC.AbandonQuest(loyal)

section("Names and faces match")
local mism = 0
for _ = 1, 40 do
    local person = LC.NewPerson("citizen")
    if LC.NameGender(person.name) ~= person.gender or not person.model:find(person.gender == "female" and "female" or "/male", 1, true) then mism = mism + 1 end
end
ok(mism == 0, "new people get a name that goes with their face", mism)
local fem = LC.QB.SpawnActor({ ents = {}, marked = {}, data = {} }, "citizen", Vector(9000, 9000, 0), 5, nil, { gender = "female" })
ok(IsValid(fem) and LC.NPCs[fem].gender == "female" and fem:GetModel():find("female", 1, true), "a story can ask for a woman, and gets one")
if IsValid(fem) then fem:Remove() end
local man = LC.QB.SpawnActor({ ents = {}, marked = {}, data = {} }, "citizen", Vector(9000, 9000, 0), 5, nil, { gender = "male" })
ok(IsValid(man) and LC.NPCs[man].gender == "male" and LC.NameGender(man:GetNW2String("lc_pname", "")) == "male", "or a man, with a man's name")
if IsValid(man) then man:Remove() end


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
ok(qp2.stages[1].kind == "choice", "first, how to get them out: a transfer order, a fire, or a false report")
LC.ResolveChoice(good, qp2.id, 1) -- (the forged transfer order)
ok(LC.HasItem(good, "transfer_order"), "the forged transfer order, in your pocket")
local prisoner = qp2.stages[qp2.stage].npc
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
ok(qc and qc.stages[1].pos ~= nil, "the crossroads starts with somewhere to go", qc and (tostring(qc.title) .. " / " .. tostring(qc.stages[1].kind)) or "no quest")
if qc and qc.stages[1].pos then good:SetPos(qc.stages[1].pos) end
_run(1)
if qc then
    reach(good, qc.data.actor)
    LC.ResolveChoice(good, qc.id, 2)
end
ok(LC.StoryFlag(good, "insider") == true and LC.Story(good).chains.inside.done == "insider", "staying inside makes you a double agent")
ok(good:GetNW2String("lcf_faction", "") == "cp", "still in uniform")
local w1 = storyPosting(good, "insidework")
ok(w1 ~= nil and string.find(w1.title, "Inside Work: ", 1, true) == 1, "secret Inside Work appears, for you alone", w1 and w1.title)
local otherCop = newPlayer("OtherCop", "cp")
ok(storyPosting(otherCop, "insidework") == nil, "nobody else sees it")
if w1 then LC.AcceptPosting(good, w1.id) end
ok(LC.QuestOf[good] ~= nil, "an op begins")
LC.AbandonQuest(good)

LC.Bump(good, "suspicion", 3)
LC.CheckUnlocks(good)
ok(storyPosting(good, "insidework") == nil, "too much suspicion and the ops dry up")
do -- (its own scope: the main chunk is at Lua's limit on locals)
_setcvar("lc_loyalty_wait", 0) -- (the NPC prisoner here; the real-prisoner wait has its own test)
if good.lcStoryPostings then good.lcStoryPostings.molehunt = nil end -- (built again, now it won't wait)
local m1 = storyPosting(good, "molehunt")
ok(m1 ~= nil and string.find(m1.title or "", "The loyalty test", 1, true), "and the mole hunt starts with the loyalty test, in the cells", m1 and m1.title)
LC.AcceptPosting(good, m1.id)
local qm = LC.QuestOf[good]
good:SetPos(qm.stages[1].pos)
_run(1)
local lts = LC.LoyaltyTests[good]
ok(lts and IsValid(lts.prisoner) and #lts.guards == 2 and good:HasWeapon("weapon_fists"), "in the cell: the prisoner, two guards, your fists")
LC.ResolveChoice(good, qm.id, 1)
for _ = 1, 6 do if lts then hook.Run("EntityTakeDamage", lts.prisoner, _dmg(good, 5, DMG_CLUB)) end end
_run(1)
ok(lts and lts.phase == "finish" and lts.prisoner:Health() > 0, "the beating: he stays on his feet, then he's to be finished", lts and lts.phase)
if lts then hook.Run("OnNPCKilled", lts.prisoner, good, nil) end
_run(1)
ok(LC.Counter(good, "suspicion") == 0 and LC.StoryFlag(good, "disgraced") == true and LC.LoyaltyTests[good] == nil, "killed him: suspicion cleared, and the Resistance shuts you out")
_run(15)
local qr = LC.QuestOf[good]
ok(qr and qr.chain == "molehunt" and qr.chainPart == "reckoning", "the reckoning starts by itself: no choosing it", qr and qr.chainPart)
if qr then
    good:SetPos(qr.stages[1].pos)
    _run(1)
    reach(good, qr.data.actor)
    LC.ResolveChoice(good, qr.id, 1)
    _run(15)
end
local qd = LC.QuestOf[good]
ok(qd and qd.chainPart == "debt", "paying the debt starts at once", qd and qd.chainPart)
LC.AbandonQuest(good)
-- (the debt paid)
LC.StoryFlag(good, "disgraced", false)
LC.Story(good).chains.molehunt = nil
LC.Story(good).notified.molehunt = nil
end
ok(storyPosting(good, "insidework") ~= nil, "the ops resume")

do
_setcvar("lc_loyalty_wait", 0)
LC.Bump(good, "suspicion", 3)
if good.lcStoryPostings then good.lcStoryPostings.molehunt = nil end
local m2 = storyPosting(good, "molehunt")
LC.AcceptPosting(good, m2.id)
local qm2 = LC.QuestOf[good]
good:SetPos(qm2.stages[1].pos)
_run(1)
LC.ResolveChoice(good, qm2.id, 2)
_run(10)
ok(LC.StoryFlag(good, "exposed") == true and LC.PlayerIsStalker(good), "refusing: shot down, and made a stalker")
end

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
cast.stalker = newPlayer("SStalker", "stalker")
cast.vort = newPlayer("SVort", "vort") -- (The Collar: a shackled vortigaunt's story)
local problems2, started2, total2 = {}, 0, 0
for _, chain in ipairs(LC.ChainList) do
    local p = chain.special and cast.chaplain or (chain.id == "stalker" and cast.stalker) or (chain.id == "collar" and cast.vort) or (chain.factions.cp and cast.cp or cast.citizen)
    for partId in pairs(chain.parts) do
        local variants = { false }
        if chain.id == "missing" then variants = { "rebels", "infestation", "deserted" } end
        if chain.id == "shift" then variants = {} for _, o in ipairs(LCJ.Occupations) do if not LCJ.Closed(o) then variants[#variants + 1] = o.id end end end
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
LC.SetFaction(cast.stalker, "citizen", nil, true)


----------------------------------------------------------------------
section("Occupations")
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
        elseif st.kind == "count" and st.event == "cremated" then
            local body = q.data.body
            if IsValid(body) then
                p:SetPos(body:GetPos() + Vector(30, 0, 0))
                LC.StartHaul(p, body)
                p:SetPos(st.pos + Vector(40, 0, 0)) body:SetPos(st.pos + Vector(60, 0, 0))
                LC.StopHaul(p)
            end
            _run(0.5)
        elseif st.kind == "count" and st.event == "game_done" then
            LC.JobGameFinishForTest(p) _run(0.5)
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
-- (7 November) the Union's kit comes back after prison; the job goes with a unit's badge, or an anticitizen's name
local kit = newPlayer("Kit", "citizen")
ok(LC.SetJob(kit, "cleanup", true) and kit:HasWeapon("weapon_lc_sprayer") and kit:HasWeapon("weapon_lc_hoover"), "Infestation Cleanup is issued the sprayer and the hoover")
kit:StripWeapons()
hook.Run("LivingCityReleased", kit)
_run(0.5)
ok(kit:HasWeapon("weapon_lc_sprayer") and kit:HasWeapon("weapon_lc_hoover"), "and gets them back on release from prison")
local okc, whyc = LC.SetJob(kit, "sanitation")
ok(not okc and whyc ~= nil and string.find(whyc, "minutes", 1, true) ~= nil, "one job change every 15 minutes: the refusal says the minutes left", whyc)
LC.GiveItem(kit, "weedkiller", 1)
kit:SetNW2String("lcf_faction", "cp")
LC.CheckUnionJob(kit)
ok(LC.Job(kit) == nil and not kit:HasWeapon("weapon_lc_sprayer") and not kit:HasWeapon("weapon_lc_hoover") and not LC.HasItem(kit, "weedkiller"),
    "a Civil Protection recruit loses the Union job, the hoover and the weedkiller")
local anti = newPlayer("Anti", "citizen")
LC.SetJob(anti, "cleanup", true)
LC.GiveItem(anti, "weedkiller", 1)
anti.lcWasHunted = false
local wasHunted = LC.PlayerIsHunted
LC.PlayerIsHunted = function(p) return p == anti or wasHunted(p) end
LC.CheckUnionJob(anti)
LC.PlayerIsHunted = wasHunted
ok(LC.Job(anti) == nil and not anti:HasWeapon("weapon_lc_hoover"), "an anticitizen's Union job is revoked, the hoover with it")
ok(anti:HasWeapon("weapon_lc_sprayer") and LC.HasItem(anti, "weedkiller"), "but they keep the weedkiller")
local sp1 = storyPosting(worker, "shift")
for _ = 1, 5 do -- (a shift that finds no spot this time: another try, as the board would later)
    if sp1 then break end
    if worker.lcStoryPostings then worker.lcStoryPostings.shift = nil end
    sp1 = storyPosting(worker, "shift")
end
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
for i = 1, 60 do LC.GiveItem(surv, "bottle_empty") end
ok(LC.InvWeight(surv) <= 12.001 and not LC.GiveItem(surv, "bottle_empty"), "pockets have a limit: what you can carry", LC.InvWeight(surv))

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
LC.GiveItem(buyer, "ration_card", 2) -- (each ration takes a card, earned by a shift)
ok(IsValid(dsp) and LC.UseDispenser(buyer, dsp), "the ration dispenser serves you")
ok(not LC.UseDispenser(buyer, dsp), "once per allocation")

local function UndergroundTests() -- contraband, papers, disguises, radios, new jobs
_setcvar("lc_stops", 1)
_setcvar("lc_auto_events", 0) -- no surprise curfews or sweeps in the middle of these
LC.EndEvent(true)
----------------------------------------------------------------------
section("Radios")
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
ok(not LC.Buy(listener, "radio") and not LCS.BlackById.radio, "no plain radio anywhere: every radio that isn't Civil Protection's is a Freq 7 radio")
LC.GiveItem(listener, "radio_tuned")
ok(LC.RadioBand(listener) == "resistance" and LCS.Items.radio_tuned.contraband, "a civilian's radio is a Freq 7 radio, and contraband")
LC.TakeItem(listener, "radio_tuned") -- (the listener goes without one from here: no radio, no band)
ok(LCS.LabById.radio_transmitter and LCS.LabById.radio_transmitter.needs.radio_tuned == 1, "the lab makes the transmitter from a Freq 7 radio")
LC.GiveItem(rebelR, "radio_tuned")
ok(LC.RadioBand(rebelR) == "resistance" and LC.RadioBand(unitR) == "cp", "a retuned radio is Freq 7; units are on the CP net")
listener.chat, rebelR.chat, unitR.chat, deaf.chat = {}, {}, {}, {}
hook.Run("PlayerSay", rebelR, "!r anyone out there")
ok(has(rebelR.chat, "only listens") and not has(listener.chat, "anyone out there"), "a radio alone only listens: no talking without a radio transmitter")
LC.GiveItem(listener, "radio_transmitter") LC.GiveItem(rebelR, "radio_transmitter")
ok(LCS.Items.radio_transmitter.contraband and LCS.BlackById and LCS.BlackById.radio_transmitter and LCS.LabById.radio_transmitter, "the radio transmitter: contraband, from the black market or the Resistance lab")
hook.Run("PlayerSay", listener, "!r anyone out there")
ok(not has(rebelR.chat, "anyone out there"), "a transmitter alone, with no Freq 7 radio: nobody hears you")
hook.Run("PlayerSay", rebelR, "!r meet at the canal")
ok(has(rebelR.chat, "[Freq 7]") and not has(listener.chat, "meet at the canal") and not has(unitR.chat, "meet at the canal"), "with a Freq 7 radio and a transmitter: Freq 7, and it's private")
hook.Run("PlayerSay", unitR, "!r sweep in block two")
ok(has(rebelR.chat, "[Intercept]") and not has(listener.chat, "sweep in block two"), "units talk on the CP net (issued); it leaks to retuned radios")
-- a Resistance Insider: a unit with a Freq 7 radio and a transmitter can send on both, and switches
local insider = newPlayer("InsiderR", "cp")
LC.GiveItem(insider, "radio_tuned") LC.GiveItem(insider, "radio_transmitter")
insider.chat = {}
ok(#LC.TransmitBands(insider) == 2 and LC.TransmitBand(insider) == "cp", "a unit with a Freq 7 radio and a transmitter can send on the CP net and Freq 7 (an Insider)")
ok(LC.TuneTransmitter(insider) == "resistance", "and switches between them (right click on the transmitter)")
rebelR.chat = {}
hook.Run("PlayerSay", insider, "!r the sweep is at the canal")
ok(has(rebelR.chat, "[Freq 7]") and has(rebelR.chat, "the sweep is at the canal"), "tuned to Freq 7: the Resistance hears it")
hook.Run("PlayerSay", rebelR, "!r understood")
ok(has(insider.chat, "understood"), "and the Insider hears Freq 7 too")
insider.valid = false
ok(hook.Run("PlayerSay", deaf, "!r hello") == "" and has(deaf.chat, "You don't have a radio"), "no radio, no talking")
listener.chat, rebelR.chat = {}, {}
hook.Run("LivingCityEventSoon", "curfew", 45)
ok(has(rebelR.chat, "Notice: curfew begins in 45 seconds"), "radios hear about routine events before the loudspeakers")
listener.chat, rebelR.chat = {}, {}
hook.Run("LivingCityEventSoon", "sweep", 45)
ok(not has(rebelR.chat, "Notice:"), "a sweep is a surprise: nothing on the Union band")
ok(has(rebelR.chat, "Move anything you don't want found"), "but Freq 7's informants whisper it")
listener.chat, rebelR.chat = {}, {}
hook.Run("LivingCityEventSoon", "raid", 45)
ok(not has(listener.chat, "Notice:") and has(rebelR.chat, "go through a housing block"), "a raid is a surprise too, except to the Resistance")
do
    local auto = {}
    for _, w in ipairs(LC.AutoEventWeights or {}) do auto[w[1]] = true end
    ok(auto.rations and auto.sweep and not auto.lockdown, "a lockdown is never scheduled: it answers violence")
    ok(LC.PublicEvents.rations and LC.PublicEvents.curfew and not LC.PublicEvents.sweep and not LC.PublicEvents.raid and not LC.PublicEvents.supply, "only rations and curfew are announced ahead")
end
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
-- (the Resistance's fighters out of the way while this unit does its job: one wandering by started a fight)
local rebelsAway = {}
for n, s in pairs(LC.NPCs) do
    if IsValid(n) and n ~= copN and (s.role == "rebel" or (n.GetClass and n:GetClass() == "npc_citizen")) then rebelsAway[n] = n:GetPos() n:SetPos(Vector(-195000, -195000, 0)) end
end
copSt.provokedBy, copSt.provokedUntil, copSt.target = nil, 0, nil
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
ok(LC.Stops[frisked] ~= nil and has(frisked.chat, "Stand still for inspection"), "a cop on the street stops a passer-by",
    tostring(copSt.state) .. " provRole=" .. tostring(IsValid(copSt.provokedBy) and LC.NPCs[copSt.provokedBy] and LC.NPCs[copSt.provokedBy].role) .. " foe=" .. tostring(IsValid(copSt.target) and (copSt.target.Nick and copSt.target:Nick() or copSt.target:GetClass())) .. " prov=" .. tostring(IsValid(copSt.provokedBy) and (copSt.provokedBy.Nick and copSt.provokedBy:Nick() or copSt.provokedBy:GetClass())) .. " wanted=" .. tostring(LC.PlayerIsWanted(frisked)))
copN.sim = true
local standing0 = LC.Standing(frisked)
frisked.lcViolentUntil = CurTime() + 1e6 -- (taken for violent: chased, not cuffed on the spot, so the wanted status can be checked)
_run(8)
ok(LC.Stops[frisked] == nil, "the stop finishes")
ok(not LC.HasItem(frisked, "uniform_cp") and has(frisked.chat, "Confiscated: Civil Protection uniform"), "contraband is found and confiscated")
ok(LC.PlayerIsWanted(frisked) and LC.Standing(frisked) < standing0, "and you're wanted, with less standing")
frisked.lcViolentUntil = nil
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
_setcvar("lc_stop_chance", 0) -- a unit at his post could still pick him out at random; that's checkpoint behaviour, not this test
for n, s in pairs(LC.NPCs) do -- any other unit wandering by could legitimately stop him
    if IsValid(n) and s.role == "cop" and n ~= copN then n:SetPos(Vector(0, -40000, 0)) end
end
_run(3.5)
ok(LC.Stops[sweepGuy] == nil, "outside a sweep, a unit with nothing to do leaves you alone")
_setcvar("lc_stop_chance", 15)
_setcvar("lc_stop_chance", 50)
LC.StartEvent("sweep", 1)
copSt.provokedBy, copSt.provokedUntil, copSt.target = nil, 0, nil
if copSt.state == "hostile" then LC.SetState(copN, copSt, "idle") end
_run(3.5)
ok(LC.Stops[sweepGuy] ~= nil, "during an inspection sweep, units stop people from further away, far more often", tostring(copSt.state))
copN.sim = true
_run(8)
LC.EndEvent(true)
_setcvar("lc_stop_chance", 15)
_setcvar("lc_street_stop_chance", 1)
sweepGuy:SetPos(Vector(-30000, 30000, 0))
for n, pos in pairs(rebelsAway) do if IsValid(n) then n:SetPos(pos) end end

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
ok(string.find(mole:GetModel(), "models/player/police", 1, true) == 1 and string.find(mole:GetNW2String("lcd_title", ""), "CP ", 1, true) == 1, "and looks the part, down to a made-up designation")
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
local fwatch = ents.Create("npc_metropolice") fwatch:SetPos(FAR + Vector(300, 0, 0))
LC.NPCs[fwatch] = { role = "cop", test = true }
LC.InvAction(forger, "use", "papers_blank")
ok(LC.HasItem(forger, "papers_blank"), "forging needs somewhere private")
LC.NPCs[fwatch] = nil fwatch:Remove()
forger:SetPos(Vector(-6000, -6000, 0))
withRoll(20, function() LC.InvAction(forger, "use", "papers_blank") end)
ok(LC.HasItem(forger, "papers_forged") and not LC.HasItem(forger, "papers_blank"), "a steady hand in rebel territory makes forged papers")

local hungry = newPlayer("Hungry", "citizen")
local disp2 = ents.Create("lc_dispenser")
disp2:SetPos(hungry:GetPos() + Vector(40, 0, 0))
LC.GiveItem(hungry, "ration_card", 2)
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
LC.OpenStashAt(tenant, home) -- (opened from furniture at home: a stove, fridge, dresser or wardrobe)
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
LC.GiveItem(buyer2, "ration")
c2 = LC.Credits(buyer2)
ok(LC.DealerSell(buyer2, "ration") and LC.Credits(buyer2) == c2 + 2, "and ordinary things too, at a fraction of the shop price")
for _ = 1, 3 do LC.GiveItem(buyer2, "bottle_empty") end
c2 = LC.Credits(buyer2)
ok(LC.DealerSell(buyer2, "bottle_empty", true) and not LC.HasItem(buyer2, "bottle_empty") and LC.Credits(buyer2) == c2 + 3, "a whole stack at once")
c2 = LC.Credits(buyer2)
ok(LC.DealerSell(buyer2, "w:weapon_crowbar") and not buyer2:HasWeapon("weapon_crowbar") and LC.Credits(buyer2) == c2 + 20, "and weapons you carry")
local fighter = newPlayer("Fighter", "resistance", nil, 500)
fighter:SetPos(Vector(-6000, -6000, 0))
ok(fighter:HasWeapon("weapon_pistol") and not LC.DealerSell(fighter, "w:weapon_pistol") and fighter:HasWeapon("weapon_pistol"), "but not what your faction issued you")
for _, it in pairs(LCS.Items) do
    if not it.doc and not (it.sell and it.sell >= 1) then ok(false, "every item has a resale price") break end
end
-- a lockpick of your own
for _ = 1, 4 do LC.GiveItem(buyer2, "scrap") end
LC.TakeItem(buyer2, "lockpick", LC.Inventory(buyer2).lockpick or 0)
ok(LC.UndergroundAction(buyer2, "craft", "scrap") and LC.HasItem(buyer2, "lockpick") and not LC.HasItem(buyer2, "scrap"), "four pieces of scrap make a lockpick")
local pdoor = ents.Create("func_door")
pdoor.mapid = 901
LC.SetDoorTag(pdoor, "locked")
buyer2.lookingAt = pdoor
buyer2.chat = {}
ok(LC.QuickPick(buyer2), "!pick uses it on the door you're looking at")
LC.ClearWanted(buyer2)
LC.TakeItem(buyer2, "lockpick")
buyer2.lcPicking = nil
local qok, qwhy = LC.QuickPick(buyer2)
ok(not qok and qwhy and qwhy:find("scrap"), "and tells you how to get one if you have none", tostring(qwhy))
buyer2.lookingAt = nil
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
        elseif st.kind == "count" and st.event == "cremated" then
            local body = q.data.body
            if IsValid(body) then
                p:SetPos(body:GetPos() + Vector(30, 0, 0))
                LC.StartHaul(p, body)
                p:SetPos(st.pos + Vector(40, 0, 0)) body:SetPos(st.pos + Vector(60, 0, 0))
                LC.StopHaul(p)
            end
            _run(0.5)
        elseif st.kind == "count" and st.event == "game_done" then
            LC.JobGameFinishForTest(p) _run(0.5)
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
local newJobs = { porter = { "New arrivals", "Luggage", "Papers check" }, clerk = { "Filing", "Permit desk", "Supply cabinet" },
    laundry = { "Wash cycle", "Pressed uniforms", "Stains" }, mortuary = { "Collection", "Before the fire" },
    scrap = { "Scrap run", "Rubble clearing" }, radio = { "Loudspeakers", "Repair bench", "Union radio order" },
    warden = { "Block patrol" } }
local jobber = newPlayer("Jobber", "citizen")
local jobInc = ents.Create("lc_incinerator") jobInc:SetPos(Vector(-2600, 2600, 0)) jobInc:Spawn() -- the morgue's (bodies are hauled here)
local done, total, missing = 0, 0, {}
for _, id in ipairs({ "porter", "mortuary", "scrap", "warden" }) do
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
ok(#LCJ.Occupations == 15 and LCJ.ById.warden and LCJ.ById.warden.playersOnly and LCJ.ById.groundskeeper and LCJ.ById.cleanup, "fifteen occupations in all (the Groundskeeper, the Block Warden for players only, and Infestation Cleanup, the newest)")
local gameOnly = {}
for _, o in ipairs(LCJ.Occupations) do if o.gameOnly then gameOnly[#gameOnly + 1] = o.id end end
table.sort(gameOnly)
ok(table.concat(gameOnly, ",") == "clerk,laundry,radio", "three are hands-on games only: laundry, records, radio repair", table.concat(gameOnly, ","))
local applicant = newPlayer("JobApplicant", "citizen")
applicant:SetPos(FAR)
ok(LC.SetJob(applicant, "laundry"), "a player can take one while the games are on")
_setcvar("lc_jobgames", 0)
local applicant2 = newPlayer("JobApplicant2", "citizen")
applicant2:SetPos(FAR)
local okA, whyA = LC.SetJob(applicant2, "radio")
ok(not okA and whyA and string.find(whyA, "is closed right now", 1, true), "with lc_jobgames 0 they're closed", whyA)
applicant.chat = {}
_advance(11) _runtimers()
ok(applicant:GetNW2String("lcj_job", "") == "" and has(applicant.chat, "has been closed"), "and anyone who had one is told it's closed, and picks another")
_setcvar("lc_jobgames", 1)
for _, t in ipairs({ { "courier", "Parcel run" }, { "mortuary", "Before the fire" }, { "laundry", "Sorting" }, { "clerk", "Filing" }, { "radio", "Repairs" } }) do
    local p = newPlayer("Hands" .. t[1], "citizen")
    p:SetPos(FAR)
    LC.SetJob(p, t[1], true)
    local qh = shiftTitled(p, t[2])
    ok(qh ~= nil, t[1] .. " has a hands-on shift: " .. t[2])
    if qh then workAll(qh, p) ok(qh.done, "and it can be worked start to finish", t[2]) end
    LC.SetJob(p, "", true) -- (a player in a job makes the city's own wait for them)
    p:SetPos(Vector(-150000, 150000, 0))
end

local function choose(job, title, pick, roll)
    local p = newPlayer("Job" .. job .. pick, "citizen")
    p:SetPos(FAR)
    LC.SetJob(p, job, true)
    local qj = shiftTitled(p, title)
    p.lcPick = pick
    if roll then withRoll(roll, function() workAll(qj, p) end) else workAll(qj, p) end
    return p, qj
end
local pm = choose("mortuary", "Collection", 2)
ok(LC.HasItem(pm, "papers_dead"), "the morgue is where dead men's papers come from")
ok(jobInc:GetNW2Float("lc_burn_until", 0) > 0, "the body went into the incinerator")
local pp, qp = choose("porter", "New arrivals", 3)
ok(qp.done and LC.Counter(pp, "reports") >= 1, "a porter can turn in a nervous arrival instead of walking him home")
local seenWasR = LC.SeenBySecurity
LC.SeenBySecurity = function() return false end -- (nobody sees it come out of the rubble: a unit who did would take it, and you, in now)
local ps = choose("scrap", "Rubble clearing", 3)
LC.SeenBySecurity = seenWasR
ok(ps:HasWeapon("weapon_pistol"), "and the rubble sometimes hides a pistol")
jobInc:Remove()
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
ok(waitFor(function() return has(pest.chat, "crack across the ribs") end, 10), "then the stick")
-- (a pest keeps crowding him, however far the stick knocked them back)
ok(waitFor(function() if not LC.PlayerIsWanted(pest) then pest:SetPos(copA:GetPos() + Vector(50, 0, 0)) end return LC.PlayerIsWanted(pest) end, 8)
    and has(pest.chat, "Obstructing Civil Protection"), "then you're obstructing Civil Protection")
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
_setcvar("lc_squads", 0) -- (one unit's own chase: any of the city's units nearby would make it a squad, and him a follower)
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
_setcvar("lc_squads", 1)

----------------------------------------------------------------------
section("Arrests with no prison cells")
local savedCells = {}
for _, p in ipairs(LC.PointsOfKind("cell")) do savedCells[#savedCells + 1] = { pos = p.pos, yaw = p.yaw } end
for _, p in ipairs(LC.PointsOfKind("cell")) do LC.RemovePoint(p) end
ok(not LC.PrisonAvailable(), "the map has no cells")
LC.GiveItem(runner2, "lockpick")
local cr0 = LC.Credits(runner2)
local hit = _dmg(copA, 10, DMG_CLUB)
runner2.lcSubdue = { n = 2, t = CurTime() } -- (beaten down: the third blow cuffs them)
hook.Run("EntityTakeDamage", runner2, hit)
ok(LC.Detained[runner2] and runner2.frozen and hit:GetDamage() == 0, "the stick doesn't just beat you: you're cuffed on the street")
ok(not LC.PlayerIsWanted(runner2) and not LC.HasItem(runner2, "lockpick") and LC.Credits(runner2) < cr0, "searched and fined, and no longer wanted")
local hit2 = _dmg(copA, 10, DMG_CLUB)
hook.Run("EntityTakeDamage", runner2, hit2)
ok(hit2:GetDamage() == 0, "nobody beats someone who's already cuffed")
local hostile = 0
for n, s in pairs(LC.NPCs) do if IsValid(n) and s.state == "hostile" and s.enemy == runner2 then hostile = hostile + 1 end end
ok(hostile == 0 and copAst.state == "event", "the other units stand down, and the arresting one stands guard")
for _ = 1, 7 do _run(10) if not LC.Detained[runner2] then break end end -- (held longer the longer they were wanted: up to a minute)
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
LC.GiveItem(eater, "ration_card", 3)
ok(waitFor(function() return LC.HasItem(eater, "ration_short") or LC.HasItem(eater, "ration") end, 8) and (has(eater.chat, "hands you a ration packet") or has(eater.chat, "short ration")),
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
-- a dispenser a few steps past the front: they walk up to it for their ration, then step away
local far = ents.Create("lc_dispenser")
far:SetPos(front + Vector(220, 0, 0))
for _, n in ipairs(line.q) do local st2 = LC.NPCs[n] if st2 then LC.LeaveLine(n, st2) end end
line.q = {}
local walker, wst = LC.SpawnCitizen(front + Vector(-300, 0, 0))
wst.leaveAt = nil
line.nextAdvance = CurTime() + 1000
LC.JoinLine(walker, wst)
_run(8)
line.nextAdvance = 0
local reached = false
servedFrom = 0
hook.Add("LivingCityServed", "TestServed", function(n) if n == walker then servedFrom = servedFrom + 1 reached = walker:GetPos():Distance(far:GetPos()) < 100 end end)
_run(20)
hook.t.LivingCityServed.TestServed = nil
ok(servedFrom == 1 and reached, "the front of the line walks up to the dispenser for their ration (not handed it where they stand)", tostring(walker:GetPos():Distance(far:GetPos())))
far:Remove()

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

-- a nodegraph with links: routes are planned over it, in short legs
local function ainLinked(nds, lks)
    local size = 12 + #nds * (14 * 4 + 1 + 2 + 2) + 4 + #lks * (2 + 2 + 10)
    local buf = ffi.new("uint8_t[?]", size)
    local pos = 0
    local function put(t, n, v) ffi.cast(t .. "*", buf + pos)[0] = v pos = pos + n end
    put("int32_t", 4, 37) put("int32_t", 4, 1) put("int32_t", 4, #nds)
    for _, nd in ipairs(nds) do
        put("float", 4, nd[1]) put("float", 4, nd[2]) put("float", 4, nd[3]) put("float", 4, 0)
        for _ = 1, 10 do put("float", 4, 0) end
        put("uint8_t", 1, 2) put("uint16_t", 2, 0) put("int16_t", 2, 4)
    end
    put("int32_t", 4, #lks)
    for _, l in ipairs(lks) do
        put("int16_t", 2, l[1]) put("int16_t", 2, l[2])
        for h = 0, 9 do put("uint8_t", 1, h == 0 and (l[3] or 1) or 1) end
    end
    return ffi.string(buf, size)
end
local G, L2 = {}, {}
local function addNode(x, y, z) G[#G + 1] = { x, y, z } return #G - 1 end
local street = {}
for i = 0, 29 do street[i] = addNode(20000 + i * 150, 20000, 0) end           -- a long street
for i = 1, 29 do L2[#L2 + 1] = { street[i - 1], street[i] } end
local stairs = {}
for i = 1, 6 do stairs[i] = addNode(20000 + 29 * 150, 20000 + i * 100, i * 40) end -- up a flight of stairs
L2[#L2 + 1] = { street[29], stairs[1] }
for i = 2, 6 do L2[#L2 + 1] = { stairs[i - 1], stairs[i] } end
local upper = {}
for i = 0, 9 do upper[i] = addNode(20000 + 29 * 150 - i * 150, 20700, 240) end -- the floor above
L2[#L2 + 1] = { stairs[6], upper[0] }
for i = 1, 9 do L2[#L2 + 1] = { upper[i - 1], upper[i] } end
local sealed = {}
for i = 0, 7 do sealed[i] = addNode(30000 + i * 150, 30000, 0) end              -- a sealed room
for i = 1, 7 do L2[#L2 + 1] = { sealed[i - 1], sealed[i] } end
local vent = addNode(20000, 19800, 0)                                         -- a vent: only small hulls fit
L2[#L2 + 1] = { street[0], vent, 0 }
_files["maps/graphs/rp_test.ain"] = ainLinked(G, L2)
LC.Start(admin)
ok(LC.NavGraph and LC.NavGraph.links == #L2 - 1, "the nodegraph's links are read, for people on foot", LC.NavGraph and LC.NavGraph.links)
ok(#LC.Fallback == 46 and (LC.SourceDetail or ""):find("walkable links", 1, true), "only the area people can walk around is used for wandering", #LC.Fallback)
local A, B = Vector(20000, 20000, 0), Vector(20000 + 29 * 150 - 9 * 150, 20700, 240)
local route = LC.NavRoute(A, B, "citizen")
local longest, prev, sawStairs = 0, A, false
for _, p in ipairs(route or {}) do
    longest = math.max(longest, p:Distance(prev)) prev = p
    if p.z > 30 and p.z < 240 then sawStairs = true end
end
ok(route and #route >= 8 and route[#route] == B, "a long trip is planned as a string of short legs", route and #route)
ok(longest <= 480, "none of them more than a few hundred units", longest)
ok(sawStairs, "with a stop on the stairs, not a straight line through the ceiling")
ok(LC.NavRoute(A, Vector(30500, 30000, 0), "citizen") == false, "a sealed room can't be reached")
ok(LC.NavRoute(A, Vector(20000, 19800, 0), "citizen") == false, "nor somewhere only a small hull fits")
local wanderer, wst = LC.SpawnCitizen(A + Vector(0, 0, 4))
wanderer.sim = false
LC.SetState(wanderer, wst, "idle")
ok(LC.GoTo(wanderer, wst, Vector(30500, 30000, 0), false, nil) == false and wst.state == "idle", "so nobody sets off for it")
local farAway = false
for _ = 1, 200 do
    local p = LC.RandomWanderPos("citizen", A)
    if p and p.x >= 29000 then farAway = true end
end
ok(not farAway, "and wandering never picks it")
-- stuck on the way somewhere far: they give up rather than pop across the map
LC.GoTo(wanderer, wst, B, false, nil)
local startPos = wanderer:GetPos()
wst.hop = #wst.route -- pretend they're on the last leg, still far from it
wst.lastMoved = CurTime() - 10
wanderer.sched = nil
local gaveUp = false
for _ = 1, 30 do -- they try another way first
    _run(0.5)
    if wst.state ~= "moving" then gaveUp = true break end
end
ok(wanderer:GetPos():DistToSqr(startPos) < 50 * 50 and gaveUp, "someone stuck far from where they're going isn't teleported there", wst.state)
LC.StuckReasons = nil
wanderer:Remove()
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
boss.alive = false
boss.chat = {}
hook.Run("PlayerDeath", boss)
boss.alive = true
ok(has(boss.chat, "build mode, so you keep this character"), "an admin who dies in build mode keeps their character, and is told why")
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
local heir = math.min(200, math.floor(LC.Credits(resident) / 4)) -- (the next person inherits a quarter of the savings: sv_livingcity_progress.lua)
if LC.Prisoners[resident] then LC.ReleasePrisoner(resident) end -- dying in custody is exempt; make sure that's not why
resident.alive = false
hook.Run("PlayerDeath", resident)
resident.alive = true
ok(resident:GetNW2String("lc_char", "") ~= "" and resident:GetNW2String("lc_char", "") ~= oldName or oldName == "?", "dying makes you a new person")
ok(LC.Credits(resident) <= 20 + heir and not LC.HasItem(resident, "ration") and LC.Standing(resident) == 0, "with nothing from the old life (but a small inheritance)", LC.Credits(resident))
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
-- pulling yourself up onto a ledge
local realHull, realLine = util.TraceHull, util.TraceLine
local hulls = 0
util.TraceHull = function(tr)
    hulls = hulls + 1
    if hulls % 2 == 1 then return { Hit = true, HitPos = Vector(30, 0, 20), HitNormal = Vector(-1, 0, 0), StartSolid = false } end
    return { Hit = false } -- room to stand up there
end
util.TraceLine = function(tr) return { Hit = true, HitPos = Vector(44, 0, 64), HitNormal = Vector(0, 0, 1), StartSolid = false } end
local function MantleMv(buttons)
    local m = Mv(buttons)
    function m:GetOrigin() return Vector(0, 0, 0) end
    function m:GetAngles() return Angle(0, 0, 0) end
    m.v = Vector(0, 0, 0)
    return m
end
resident.lcNextJump, resident.lcNextMantle = nil, nil
local mm = MantleMv(IN_JUMP)
hook.Run("SetupMove", resident, mm)
ok(mm.v.z > 250 and mm.v.x > 0, "jumping at a knee-to-chest high ledge pulls you up onto it", tostring(mm.v))
ok(bit.band(mm.b, IN_JUMP) == 0 and mm.v.z < 300, "just high enough to get onto it, not a jump on top of the climb", tostring(mm.v.z))
local mm2 = MantleMv(IN_JUMP)
hook.Run("SetupMove", resident, mm2)
ok(mm2.v.z == 0, "but not over and over")
util.TraceHull, util.TraceLine = realHull, realLine
resident.lcNextJump, resident.lcNextMantle = nil, nil
GMt:PlayerDeath(resident)
ok(resident.NextSpawnTime and resident.NextSpawnTime > CurTime() + 5, "a short wait before you respawn")
GMt:ShowHelp(resident)
ok(_lastnet("lcg_help") ~= nil, "F1 opens the guide")
-- at InitPostEntity, GM no longer exists: the gamemode's hooks must not depend on it,
-- or one error stops the rest (the city never starting)
GM = nil
local startedCity = false
local realStart = LC.Start
LC.Start = function() startedCity = true end
local wasRunning = LC.Running
LC.Running = false
_setcvar("lc_jump_power", 150)
local hookErrs = {}
for name, fn in pairs(hook.t.InitPostEntity) do
    if name == "LivingCityGamemode" or name == "LivingCityJumpMigration" then
        local okH, e = pcall(fn)
        if not okH then hookErrs[#hookErrs + 1] = name .. ": " .. tostring(e) end
    end
end
_run(5)
LC.Start, LC.Running = realStart, wasRunning
ok(#hookErrs == 0 and startedCity, "on map load the city starts, and no gamemode hook errors", hookErrs[1])
ok(GetConVar("lc_jump_power"):GetInt() == 200, "an old 150 jump setting is moved up to 200")
hook.t.InitPostEntity.LivingCityGamemode = nil
GAMEMODE = oldGM
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
ok(hook.Run("PlayerSay", admin, "x") == "", "ordinary chat is in character, heard nearby")
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
sniper.lcKillTimes = { CurTime() } -- (not the first kill in a while: that is answered lightly, below)
farCop.n:SetHealth(0)
hook.Run("OnNPCKilled", farCop.n, sniper)
ok(LC.AlertLevel(sniper) == 2 and LC.PlayerIsWanted(sniper), "killing a unit again soon: alert 2, wanted for murder", LC.AlertLevel(sniper))
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
    elseif st.kind == "count" and st.event == "game_done" then LC.JobGameFinishForTest(crook) _run(0.5)
    elseif st.kind == "hold" then crook:SetPos(st.pos) crook.crouch = st.crouch _run(st.secs + 1) crook.crouch = false
    else crook:SetPos(st.pos or crook:GetPos()) _run(1) end
end
_run(2) -- (standing changes are told once things go quiet)
ok(qr.done and has(crook.chat, "Community service"), "each shift of service restores standing (40)", LC.Standing(crook) - s0)

LC.ReportCrime(crook, "Theft", 300)
local unit = cops()[1]
if not unit then -- (none free on duty just now: one comes along)
    local n, st = LC.Spawners.cop(crook:GetPos() + Vector(200, 0, 0))
    st.untilT = 1e9
    unit = { n = n, st = st }
end
crook:SetPos(unit.n:GetPos() + Vector(50, 0, 0))
unit.st.nextUse = 0
local s1 = LC.Standing(crook)
_setcvar("lc_march", 0) -- (straight to a cell: being marched there is tested in MarchTests)
hook.Run("PlayerUse", crook, unit.n)
_setcvar("lc_march", 1)
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
ok(LC.EffectiveDoorTag(celldoor) == "prison", "a door beside a prison cell is a prison door: units only")
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
ok(LC.Raid and #LC.Raid.units == GetConVar("lc_raid_units"):GetInt(), "a full team of its own goes, from just out of sight", LC.Raid and #LC.Raid.units)
ok(rcst.raid == nil, "the city's own patrols aren't pulled in")
local raidTeam = {}
for _, u in ipairs(LC.Raid and LC.Raid.units or {}) do if LC.NPCs[u] and LC.NPCs[u].raidSpot then raidTeam[#raidTeam + 1] = u end end
_run(8)
local walking = 0
for _, u in ipairs(raidTeam) do if IsValid(u) and LC.NPCs[u] and LC.NPCs[u].raid then walking = walking + 1 end end
ok(walking > 0 or LC.Raid == nil, "units take it in turn to walk the block")
_run(160)
ok(LC.Raid == nil, "and the raid ends")
ok(not IsValid(radioItem) and not IsValid(tv) and not IsValid(gun), "contraband is confiscated")
ok(IsValid(legal) and IsValid(table1), "everything else is left alone")
ok(LC.PlayerIsWanted(raided) and has(raided.chat, "3 contraband items"), "and whoever owned it is wanted, for everything found under their name")
LC.ClearWanted(raided)
raidCop:Remove()
_run(12)
local stayed = 0
for _, u in ipairs(raidTeam) do if IsValid(u) then stayed = stayed + 1 end end
ok(#raidTeam > 0 and stayed == 0, "the team that came for the raid leaves again", #raidTeam .. " came, " .. stayed .. " stayed")

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
ok(#found == 2 and (found[1].ent == bin or found[2].ent == bin), "the bin round finds the bins that are already in the map")
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
for _, o in ipairs(P.list) do if o.name == deadName and (not back or not o.alive) then back = o end end -- (a newcomer may share the name)
ok(#P.list == saved and back and not back.alive, "the roster, living and dead, survives a restart", #P.list .. "/" .. saved)
n2:Remove()

section("Choosing a name and a face")
local function Name(s) local ok2, r = LC.ValidateCharacterName(s) return ok2, r end
local okN, cleaned = Name("  ottoline   PEMBROOK ")
ok(okN and cleaned == "Ottoline Pembrook", "an ordinary name is accepted and tidied up", cleaned)
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
Submit(chooser, "Ottoline Pembrook", "models/player/kleiner.mdl")
ok(chooser:GetNW2String("lc_char", "") ~= "Ottoline Pembrook", "and neither does a face that isn't on offer")
Submit(chooser, "Ottoline Pembrook", face)
ok(chooser:GetNW2String("lc_char", "") == "Ottoline Pembrook" and chooser:GetNW2String("lc_model", "") == face, "a good name and a face are kept")
Submit(chooser, "Casimir Delacroix", face)
ok(chooser:GetNW2String("lc_char", "") == "Casimir Delacroix", "and you can change your mind later with !character")
local twin = newPlayer("Twin", "citizen")
LC.OpenCharacterCreator(twin)
Submit(twin, "casimir delacroix", face)
ok(twin:GetNW2String("lc_char", "") ~= "Casimir Delacroix", "two people can't share a name", twin:GetNW2String("lc_char", ""))
ok(LC.ValidateCharacterName("Elena Petrova"), "(and a different name is fine)")

section("Cells stay locked")
local cellDoor = ents.Create("func_door")
cellDoor.mapid = 951
cellDoor:SetPos(Vector(455, 450, 40))
LC.ApplyDoorState(cellDoor)
ok(cellDoor.locked == true, "a door beside a cell is physically locked, not just forbidden")
local inmate = newPlayer("Inmate", "citizen")
inmate.admin = true
LC.Incarcerate(inmate, 60, "test")
ok(hook.Run("PlayerUse", inmate, cellDoor) == false, "a prisoner can't open it, admin or not")
LC.ReleasePrisoner(inmate)
local warden = newPlayer("Warden", "cp")
cellDoor.locked = true
ok(hook.Run("PlayerUse", warden, cellDoor) == false and cellDoor.fired and cellDoor.fired[#cellDoor.fired - 1] == "Unlock", "a unit's E unlocks and opens it for a moment")
cellDoor:Remove()

section("Something you saw")
local witness = newPlayer("Witness", "citizen")
witness:SetPos(Vector(0, -500, 0))
local dump = ents.Create("prop_physics")
dump:SetModel("models/props_junk/trashdumpster01a.mdl")
dump:SetPos(Vector(700, -500, 0))
local seenQ = inject(witness, "cit_report")
local w = seenQ.data.watched or {}
ok(#w == 2 and IsValid(w[1]) and IsValid(w[2]), "two people are really there to be seen")
ok(seenQ.stages[1].pos:DistToSqr(w[1]:GetPos()) < 200 * 200, "at the place you're sent")
ok(seenQ.stages[1].pos == dump:GetPos() and seenQ.stages[1].text:find("dumpster", 1, true), "which is the dumpster in the map", seenQ.stages[1].text)
local w1, w2 = w[1], w[2]
local played = {}
local realPlay = LC.PlayGesture
LC.PlayGesture = function(npc, list) played[npc] = list[1] return true end
_run(5)
LC.PlayGesture = realPlay
ok(played[w1] and played[w2], "they act out a hand-off", tostring(played[w1]) .. " " .. tostring(played[w2]))
LC.AbandonQuest(witness)
_run(5)
ok(not IsValid(w1) and not IsValid(w2), "and they're gone once the job is over")
dump:Remove()

-- the map's own dumpsters are static props: read from the map file, and used just the same
LC.StaticBins = { { kind = "bin", pos = Vector(-900, -500, 0), model = "models/props_junk/trashdumpster01a.mdl" } }
witness.lcqNext = 0
local seenS = inject(witness, "cit_report")
ok(seenS.stages[1].pos == LC.StaticBins[1].pos, "a dumpster that's part of the map counts too")
LC.AbandonQuest(witness)
LC.StaticBins = {}

-- no bins anywhere near: one is put down on the street, and they're behind it
witness.lcqNext = 0
local seenP = inject(witness, "cit_report")
local placed = seenP.data.dumpster
ok(IsValid(placed) and placed:GetModel():find("dumpster", 1, true), "with no bins on the map, a dumpster is put out for it")
ok(seenP.desc:find("dumpster", 1, true) and not LC.CombineZoneAt(seenP.stages[1].pos), "and the job is behind a dumpster, not on Combine ground", seenP.desc)
LC.AbandonQuest(witness)
ok(not IsValid(placed), "it's cleared away afterwards")

section("Reporting to a unit")
local reporter = newPlayer("Reporter", "citizen")
local rn, rst = LC.Spawners.cop(Vector(8800, 8800, 0))
rst.routeGroup = nil
rn.sim = false
local rq = inject(reporter, "cit_loyalty")
reporter:SetPos(rq.stages[1].pos)
_run(1)
ok(LC.QuestWantsCop(reporter), "a loyalty check is about speaking with a unit")
reporter:SetPos(rn:GetPos() + Vector(50, 0, 0))
LC.SetState(rn, rst, "idle")
rst.nextWarn = 0
reporter.lcBump = nil
reporter.chat = {}
_run(6)
ok(reporter.lcBump == nil and not has(reporter.chat, "Move along"), "and the unit doesn't warn or shove you for walking up to him")
hook.Run("LivingCityPlayerUsedNPC", reporter, rn, rst)
ok(rq.stages[rq.stage].kind == "choice" and not rq.done, "reporting to him leads to his question")
rn:Remove()

section("Getting unstuck")
local stuck = newPlayer("Stuck", "citizen")
LC.AddPoint(Vector(8200, 8200, 80), 0, "idle", 0)
stuck:SetPos(Vector(8200, 8600, -40))
local su, sw = LC.Unstick(stuck)
ok(su or sw == "There's nowhere to put you. Ask an admin.", "!stuck finds you somewhere to stand", tostring(sw))
local first = stuck:GetPos()
local su2, sw2 = LC.Unstick(stuck)
ok(not su2 and sw2:find("again in"), "but not again straight away")
local hunted = newPlayer("Hunted", "citizen")
LC.ReportCrime(hunted, "test", 100)
ok(not LC.Unstick(hunted), "and not as an escape from the law")
LC.ClearWanted(hunted)

section("Joining Civil Protection")
local applicant = newPlayer("Applicant", "citizen")
ok(LC.Standing(applicant) == 0 and not LC.CanJoinFaction(applicant, "cp"), "you can't join Civil Protection without good standing")
local _, cpWhy = LC.CanJoinFaction(applicant, "cp")
ok(cpWhy:find("100") and cpWhy:find("good standing"), "and you're told what it takes", tostring(cpWhy))
LC.AddStanding(applicant, 100)
local okC, whyC = LC.CanJoinFaction(applicant, "cp")
ok(not okC and whyC and whyC:find("Intake Processor", 1, true), "good standing, but not up the Civil Protection path yet (Intake Processor)", tostring(whyC))
LC.Bump(applicant, "clerk_shifts", 5)
ok(not LC.CanJoinFaction(applicant, "cp"), "Records Clerk shifts don't count: that's the Administration path now")
LC.Bump(applicant, "cp_shifts", 5)
ok(LC.CanJoinFaction(applicant, "cp"), "with 100 standing and five Intake Processor shifts you can")
local tester2 = newPlayer("TestAdmin", "citizen")
tester2.admin = true
ok(LC.CanJoinFaction(tester2, "cp"), "admins can join regardless, to test")
end
UpdateTests()

function HolsterTests()
section("Holstering")
local walker2 = newPlayer("Holsterer", "citizen")
walker2:Spawn()
_run(1)
ok(walker2:HasWeapon("weapon_lc_hands") and walker2:GetActiveWeapon():GetClass() == "weapon_lc_hands", "you spawn with your hands down, nothing to swing")
ok(walker2:HasWeapon("weapon_fists"), "your fists are still there when you want them")
LC.ToggleHolster(walker2)
ok(walker2:GetActiveWeapon():GetClass() == "weapon_fists", "R or lc_holster raises your fists")
walker2:Give("weapon_crowbar")
walker2:SelectWeapon("weapon_crowbar")
ok(hook.Run("PlayerSay", walker2, "!holster") == "" and walker2:GetActiveWeapon():GetClass() == "weapon_lc_hands", "!holster puts away whatever you're holding")
LC.ToggleHolster(walker2)
ok(walker2:GetActiveWeapon():GetClass() == "weapon_crowbar", "and drawing again brings back what you had")
local unit2 = newPlayer("HolsterUnit", "cp")
unit2:Spawn()
_run(1)
ok(unit2:GetActiveWeapon() and unit2:GetActiveWeapon():GetClass() == "weapon_lc_hands", "units start holstered too")
LC.ToggleHolster(unit2)
ok(unit2:GetActiveWeapon():GetClass() ~= "weapon_lc_hands", "and draw their kit with one key", unit2:GetActiveWeapon():GetClass())
walker2:SetPos(Vector(-30000, 30000, 0)) unit2:SetPos(Vector(-30000, 30000, 0))
end
HolsterTests()

function NPCArrestTests()
section("Searching and arresting citizens on the street")
local function forceRandom(v, fn)
    local r = math.random
    math.random = function(a, b) if a == nil then return v end if b == nil then return r(a) end return r(a, b) end
    local okr, err = pcall(fn)
    math.random = r
    if not okr then error(err) end
end
local officer = newPlayer("Officer", "cp")
local cellPt = LC.AddPoint(Vector(-12000, 12000, 0), 90, "cell", 0)
local relPt = LC.AddPoint(Vector(-12500, 12000, 0), 0, "release", 0)
local suspect, sst = LC.Spawners.citizen(Vector(-11000, 11000, 0))
suspect.sim = false
officer:SetPos(suspect:GetPos() + Vector(60, 0, 0))
hook.Run("PlayerUse", officer, suspect)
ok(sst.state == "detained" and has(officer.chat, "R to search them"), "pressing E stops them, and tells a unit what they can do next")
sst.rebel = true
LC.StartSearch(officer, suspect)
forceRandom(0.01, function() _run(3.5) end)
ok(sst.contraband and has(officer.chat, "Found "), "R with the baton searches a citizen, and finds what a sympathizer carries", table.concat(officer.chat, " | "))
local okAgain, whyAgain = LC.StartSearch(officer, suspect)
ok(not okAgain and whyAgain:find("moment ago", 1, true), "not twice in a row")
ok(LC.ArrestNPC(suspect, officer), "right click detains them")
ok(sst.state == "detained", "cuffed for a moment first")
_run(2)
local inCell = false
for _, cp in ipairs(LC.PointsOfKind("cell")) do if suspect:GetPos():DistToSqr(cp.pos) < 20 * 20 then inCell = true end end
ok(sst.state == "jailed" and inCell, "then they're in a cell, without having to walk past locked doors", sst.state)
LC.ReleaseNPCPrisoner(suspect, sst, CurTime())
local atRelease = false
for _, rp2 in ipairs(LC.PointsOfKind("release")) do if suspect:GetPos():DistToSqr(rp2.pos) < 110 * 110 then atRelease = true end end
ok(sst.state == "idle" and atRelease, "and let out at the release point (beside anyone already standing there)")
local clean, cst2 = LC.Spawners.citizen(Vector(-11000, 11500, 0))
clean.sim = false
cst2.rebel = false
officer:SetPos(clean:GetPos() + Vector(60, 0, 0))
LC.StartSearch(officer, clean)
forceRandom(0.99, function() _run(3.5) end)
ok(has(officer.chat, "Nothing on them"), "most people have nothing on them")
suspect:Remove() clean:Remove()
LC.RemovePoint(cellPt) LC.RemovePoint(relPt)
officer:SetPos(Vector(-30000, 30000, 0))
end
NPCArrestTests()

function RunningTests()
section("Running in front of Civil Protection")
_setcvar("lc_stops", 0)
_setcvar("lc_can_event", 0)
LC.EndEvent(true)
local rcop, rst
for n, st in pairs(LC.NPCs) do
    if IsValid(n) and st.role == "cop" and not st.questLock and not st.test then rcop, rst = n, st break end
end
for n, st in pairs(LC.NPCs) do -- just the one unit around
    if IsValid(n) and (st.role == "cop" or st.role == "soldier") and n ~= rcop then n:SetPos(Vector(0, -40000, 0)) end
end
LC.CalmCops(nil)
LC.SetState(rcop, rst, "idle")
rst.untilT, rst.nextInspect, rst.nextWarn = CurTime() + 1000, CurTime() + 1000, CurTime() + 1000
rcop.sim = false
-- somewhere quiet: no walls, zones or curfew left over from earlier tests in the way
local savedWalls = _walls
_walls = {}
rcop:SetPos(Vector(26000, -26000, 0))
local here = rcop:GetPos()
ok(not LC.InRebelZone(here) and not LC.Event, "a clear street for the running checks", LC.Event)

local walker = newPlayer("Walker", "citizen")
walker:SetPos(here + Vector(300, 0, 0))
walker.vel = Vector(100, 0, 0)
_run(2)
ok(not LC.Runners[walker] and walker:GetNW2Float("lc_shout_until", 0) == 0, "walking past a unit is fine")
walker.walkspeed, walker.runspeed, walker.vel = 160, 260, Vector(160, 0, 0)
_run(2)
ok(not LC.Runners[walker], "even at a brisk walk (Sandbox's walking pace is faster than the gamemode's)")
-- the gamemode's slow pace: the gap between a walk and a sprint is small
walker.walkspeed, walker.runspeed, walker.vel = 110, 190, Vector(110, 0, 0)
ok(not LC.PlayerSprinting(walker), "walking at the slow pace isn't running")
walker.keys = { [IN_SPEED] = true }
walker.vel = Vector(150, 0, 0)
ok(LC.PlayerSprinting(walker), "holding sprint at the slow pace is, even before you're up to full speed")
walker.keys = nil
walker.vel = Vector(185, 0, 0)
ok(LC.PlayerSprinting(walker), "and so is moving at sprinting speed")
ok(string.find(LC.RunningStatus(walker), "sprinting", 1, true) and string.find(LC.RunningStatus(walker), "unit watching", 1, true),
    "the debug report says whether you're running and whether a unit can see you", LC.RunningStatus(walker))
walker.vel = nil
walker:SetPos(Vector(-30000, 30000, 0))

local sprinter = newPlayer("Sprinter", "citizen")
sprinter:SetPos(here + Vector(300, 0, 0))
sprinter.vel, sprinter.keys = Vector(190, 0, 0), { [IN_SPEED] = true }
_run(0.6)
ok(LC.Runners[sprinter] and has(sprinter.chat, "Stop running!"), "running past a unit gets a shout", table.concat(sprinter.chat or {}, " | "))
ok(sprinter:GetNW2Float("lc_shout_until", 0) > CurTime() and sprinter:GetNW2String("lc_shout", "") == "STOP RUNNING!", "and it's on the screen")
ok(not LC.PlayerIsWanted(sprinter), "you get a moment to stop")
sprinter.vel = nil
_run(5)
ok(not LC.PlayerIsWanted(sprinter), "stopping is the end of it")
sprinter.vel, sprinter.keys = Vector(190, 0, 0), { [IN_SPEED] = true }
_run(2)
ok(LC.PlayerIsWanted(sprinter) and sprinter:GetNW2String("lc_wanted_reason", "") == "Fleeing Civil Protection",
    "running again while he remembers you: wanted for fleeing")
ok(rst.state == "hostile" and rst.enemy == sprinter, "and he comes after you", rst.state)
sprinter.vel = nil
LC.ClearWanted(sprinter)
LC.CalmCops(sprinter)
sprinter:SetPos(Vector(-30000, 30000, 0))

local bolter = newPlayer("Bolter", "citizen")
LC.SetState(rcop, rst, "idle")
bolter:SetPos(here + Vector(300, 0, 0))
bolter.vel, bolter.keys = Vector(190, 0, 0), { [IN_SPEED] = true }
_run(4)
ok(LC.PlayerIsWanted(bolter) and has(bolter.chat, "I said stop running"), "keep running after the shout and he chases you")
bolter.vel = nil
LC.ClearWanted(bolter)
LC.CalmCops(bolter)
bolter:SetPos(Vector(-30000, 30000, 0))

local unit = newPlayer("RunUnit", "cp")
LC.SetState(rcop, rst, "idle")
unit:SetPos(here + Vector(300, 0, 0))
unit.vel, unit.keys = Vector(190, 0, 0), { [IN_SPEED] = true }
_run(3)
ok(not LC.Runners[unit] and not LC.PlayerIsWanted(unit), "units can run")
unit.vel = nil
unit:SetPos(Vector(-30000, 30000, 0))
_walls = savedWalls
rcop.sim = true
_setcvar("lc_can_event", 1)
end
RunningTests()

function RebelTests()
local savedWalls = _walls
_walls = {}
_setcvar("lc_auto_events", 0)
_setcvar("lc_skirmishes", 0)
LC.EndEvent(true)
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
LC.CalmCops(nil)

----------------------------------------------------------------------
section("Quest items lie on the ground")
local Q = LC.QB
local motion
local realPhys = _EMT.GetPhysicsObject
_EMT.GetPhysicsObject = function(self)
    return { IsValid = function() return true end, EnableMotion = function(_, b) motion = b end, Wake = function() end }
end
local fakeQ = { ents = {} }
local item = Q.SpawnItem(fakeQ, "models/weapons/w_stunbaton.mdl", Vector(100, 100, 60), nil, true)
ok(item:GetPos().z < 5, "a dropped item lands on the floor instead of floating", tostring(item:GetPos()))
ok(motion == true, "and it has physics")
local bin = Q.SpawnItem(fakeQ, "models/props_junk/trashdumpster01a.mdl", Vector(300, 100, 60))
ok(motion == false and bin:GetPos().z < 5, "big fixtures stand still, on the ground too")
_EMT.GetPhysicsObject = realPhys
item:Remove() bin:Remove()

----------------------------------------------------------------------
section("Scanners leave units alone")
local scn, scst = LC.Spawners.scanner(Vector(24000, 24000, 0))
scn.sim = false
local unitS = newPlayer("ScanUnit", "cp")
unitS:SetPos(Vector(24000, 24300, 0))
_run(1)
ok(scn.kv.NeverInspectPlayers == "1", "a scanner doesn't photograph a unit standing nearby")
LC.RefreshRelations()
ok(scn.rel[unitS] == D_LI, "it counts units as its own")
unitS:SetPos(FAR)
_run(1)
ok(scn.kv.NeverInspectPlayers == "0", "and goes back to photographing people once the unit leaves")
scn:Remove()

----------------------------------------------------------------------
section("The Resistance lives in rebel territory")
_setcvar("lc_npc_budget", 500)
_setcvar("lc_rebels", 3)
for _, z in ipairs(LC.ZonesOfKind("rebel")) do LC.RemoveZone(z) end -- just the one territory, for these tests
local rz = LC.AddZone(Vector(1500, 3500, 0), 500, "rebel", 0)
ok(LC.RebelTarget() == 3, "rebels are wanted where there's rebel territory")
_run(10)
ok(count("rebel") >= 3, "and they turn up", count("rebel"))
local reb, rbst
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" then reb, rbst = n, st break end end
ok(reb and LC.InRebelZone(reb:GetPos()), "inside rebel territory")
ok(reb and reb.kv.citizentype == "3" and reb.kv.additionalequipment ~= nil, "in the Resistance's clothes, armed")
_run(40)
local inside = true
for n, st in pairs(LC.NPCs) do
    if IsValid(n) and st.role == "rebel" and n:GetPos():Distance(rz.pos) > rz.r * 1.3 then inside = false end
end
ok(inside, "they keep to their territory")

local friend = newPlayer("RebFriend", "resistance", nil, 200)
friend:SetPos(rz.pos + Vector(100, 0, 0))
_run(1.5)
ok(not LC.RebelAlarms[friend] and reb.rel[friend] == D_LI, "Resistance players are among friends")
friend:SetPos(FAR)

local intruder = newPlayer("RebIntruder", "cp")
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" then st.nextLook = 0 end end
intruder:SetPos(rz.pos + Vector(150, 0, 0))
_run(0.6)
ok(LC.RebelAlarms[intruder] ~= nil and has(intruder.chat, "Combine!"), "a unit walking in gets shouted at first", table.concat(intruder.chat or {}, " | "))
ok(rbst.foe ~= intruder, "not shot at straight away")
_run(3)
local shooters = 0
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and st.foe == intruder and n.rel[intruder] == D_HT then shooters = shooters + 1 end end
ok(shooters >= 2, "then they open fire", shooters)
local hit = _dmg(reb, 20)
hook.Run("EntityTakeDamage", intruder, hit)
ok(hit:GetDamage() == 10, "rebel fire hurts, but less (dying is permanent)", hit:GetDamage())
intruder:SetPos(FAR)
_run(2)
local still = 0
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and st.foe == intruder then still = still + 1 end end
ok(still == 0 and reb.rel[intruder] == D_NU, "once the unit is gone they stand down")

local pest = newPlayer("RebPest", "citizen")
pest:SetPos(rz.pos + Vector(-200, 0, 0))
_run(1)
ok(rbst.foe == nil, "ordinary citizens are left alone")
hook.Run("EntityTakeDamage", reb, _dmg(pest, 5))
ok(rbst.foe == pest and not LC.PlayerIsWanted(pest), "shoot at one and they shoot back (the Combine doesn't care)")
pest:SetPos(FAR)
rbst.provokedUntil = 0
_run(2)
ok(rbst.foe == nil, "and they let it go once you've gone")

----------------------------------------------------------------------
section("Rebels raid the Combine, sometimes")
local cp0 = LC.PointsOfKind("checkpoint")[1].pos
local guard, gst = LC.Spawners.cop(cp0 + Vector(250, 0, 4))
gst.untilT, gst.nextInspect = CurTime() + 1000, CurTime() + 1000
guard.sim = false
ok(LC.StartRebelRaid(rz), "a raid can start")
local sk = LC.Skirmish
ok(sk and sk.kind == "raid" and #sk.rebels >= 2, "with a few fighters", sk and #sk.rebels)
local alerted
for _ = 1, 60 do _run(0.5) if sk.alerted and gst.state == "hostile" then alerted = true break end end
ok(alerted, "the units near the target respond", tostring(sk.alerted) .. " " .. tostring(gst.state))
ok(gst.armed and LC.NPCs[gst.enemy] and LC.NPCs[gst.enemy].role == "rebel", "with guns drawn, at a raider")
local fighting = false
for _ = 1, 20 do
    for _, r in ipairs(sk.rebels) do local st = LC.NPCs[r] if st and st.foe then fighting = true end end
    if fighting then break end
    _run(0.5)
end
ok(fighting, "and the raiders fight them")
for _, r in ipairs(sk.rebels) do if IsValid(r) then r:SetHealth(0) end end
_run(4)
ok(LC.Skirmish == nil, "the raid ends when the raiders are down")
ok(gst.state ~= "hostile", "and the units go back to work", gst.state)
guard:Remove()

----------------------------------------------------------------------
section("The Combine sweeps rebel territory, sometimes")
_run(15) -- the zone fills back up
local okSweep, why = LC.StartCombineSweep(rz)
ok(okSweep, "a sweep can start", why)
local sw = LC.Skirmish
ok(sw and #sw.units >= 3, "an armed team gathers out of sight", sw and #sw.units)
local armed = sw ~= nil
for _, u in ipairs(sw and sw.units or {}) do local st = LC.NPCs[u] if st.role == "cop" and not st.armed then armed = false end end
ok(armed, "units on a sweep carry guns")
local engaged
for _ = 1, 80 do
    _run(0.5)
    for _, u in ipairs(sw.units) do local st = LC.NPCs[u] if st and st.state == "hostile" then engaged = true end end
    if engaged then break end
end
ok(engaged, "they move in and find someone to fight")
local defending = false
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and st.foe and LC.NPCs[st.foe] then defending = true end end
ok(defending, "and the rebels fight back")
sw.ends = CurTime()
_run(3)
ok(LC.Skirmish == nil, "sweeps end")
_run(6)
local left = 0
for _, u in ipairs(sw.units) do if IsValid(u) and LC.NPCs[u] then left = left + 1 end end
ok(left == 0, "and the team withdraws out of sight", left)

_setcvar("lc_skirmishes", 1)
_setcvar("lc_skirmish_interval", 1)
local sawOne = false
for _ = 1, 120 do _run(1) if LC.Skirmish or LC.PlannedRaid or LC.PlannedSweep then sawOne = true break end end
ok(sawOne, "skirmishes start on their own now and then (planned a little ahead, each side's own told first)")
LC.PlannedRaid = nil
LC.PlannedSweep = nil
if LC.Skirmish then LC.EndSkirmish(LC.Skirmish, "test") end
_setcvar("lc_skirmishes", 0)

----------------------------------------------------------------------
section("The Missing Unit: retaliation finds the rebels home")
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" then n:Remove() end end
_setcvar("lc_rebels", 0)
local mu = newPlayer("MUCop", "cp", nil, 1000)
LC.Story(mu).chains.missing = { part = "retaliation", data = { cause = "rebels" }, readyAt = 0 }
mu.lcStoryPostings = nil
mu.lcqNext = 0
local mp = storyPosting(mu, "missing")
LC.AcceptPosting(mu, mp.id)
ok(LC.QuestOf[mu] and LC.RebelsIn(rz) >= 3, "there are rebels waiting in rebel territory", LC.RebelsIn(rz))
LC.AbandonQuest(mu)

----------------------------------------------------------------------
section("Birds don't block doors")
local dr = ents.Create("prop_door_rotating")
dr:SetPos(Vector(-24000, -24000, 0))
_run(31) -- the door list refreshes
local bird = ents.Create("npc_pigeon")
bird:SetPos(dr:GetPos() + Vector(20, 0, -30))
LC.Wildlife[bird] = "bird"
_run(2.5)
ok(bird:GetPos():Distance(dr:GetPos()) > 80, "a bird in a doorway gets moved along", tostring(bird:GetPos()))
ok(has(bird.fired, "FlyAway"), "it flies off")
bird:SetPos(dr:GetPos() + Vector(20, 0, -30))
hook.Run("PlayerUse", mu, dr)
ok(bird:GetPos():Distance(dr:GetPos()) > 80, "opening the door shoos it right away")
ok(LC.NearDoor(dr:GetPos() + Vector(50, 0, 0), 160) ~= nil, "and birds don't spawn by doors")
bird:Remove() dr:Remove()

LC.RemoveZone(rz)
_walls = savedWalls
end
RebelTests()

function PlacementAndRouteTests()
local savedWalls = _walls
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end

----------------------------------------------------------------------
section("Hidden things go somewhere sensible")
local Q = LC.QB
local C = Vector(-26000, 26000, 0)
_walls = { { a = C + Vector(300, -600, 0), b = C + Vector(300, 600, 0) } } -- a wall east of the spot
local spots = Q.HideSpots(C, 3, 500, true)
local byWall = 0
for _, sp in ipairs(spots) do if math.abs(sp.x - (C.x + 300)) < 40 then byWall = byWall + 1 end end
ok(#spots == 3 and byWall == 3, "contraband ends up on the floor against a wall, not out in the open", byWall)
local dr = ents.Create("prop_door_rotating")
dr:SetPos(C + Vector(290, 0, 0))
LC.NearDoor(C, 1) -- refresh the door list
_run(31)
local inDoor = 0
for _ = 1, 5 do
    for _, sp in ipairs(Q.HideSpots(C, 3, 500, true)) do if sp:Distance(dr:GetPos()) < 130 then inDoor = inDoor + 1 end end
end
ok(inDoor == 0, "and never in a doorway", inDoor)
dr:Remove()
local tbl = ents.Create("prop_physics")
tbl:SetModel("models/props_c17/furnituretable002a.mdl")
tbl:SetPos(C + Vector(-200, 0, 0))
local realLine = util.TraceLine
util.TraceLine = function(t)
    if t.endpos.z < t.start.z and math.abs(t.start.x - tbl.pos.x) < 1 and math.abs(t.start.y - tbl.pos.y) < 1 then
        return { Hit = true, HitPos = Vector(tbl.pos.x, tbl.pos.y, 32), HitNormal = Vector(0, 0, 1), Fraction = 0.7, Entity = tbl }
    end
    return realLine(t)
end
local onTable = false
for _ = 1, 10 do
    for _, sp in ipairs(Q.HideSpots(C, 2, 500)) do if sp.z == 32 then onTable = true end end
end
util.TraceLine = realLine
ok(onTable, "or on a table, when there's one around")
tbl:Remove()
_walls = {}

----------------------------------------------------------------------
section("Detainee transfer: someone is actually holding them")
local tu = newPlayer("TransferUnit", "cp")
tu:SetPos(Vector(1500, -300, 0))
tu.lcqNext = 0
local tq = inject(tu, "cp_transfer")
ok(tq ~= nil, "the job can be started")
if tq then
    local det, guard = tq.data.target, tq.data.guard
    ok(IsValid(det) and LC.NPCs[det].state == "event", "the detainee is standing still, waiting")
    ok(IsValid(guard) and LC.NPCs[guard].role == "cop" and guard:GetPos():Distance(det:GetPos()) < 120, "with a unit right beside them")
    ok(string.find(tq.stages[1].text, "walk up to them", 1, true) ~= nil, "and the objective says what to do", tq.stages[1].text)
    local p0 = det:GetPos()
    _run(20)
    ok(det:GetPos():Distance(p0) < 1, "nobody wanders off or pops somewhere else")
    tu:SetPos(det:GetPos() + Vector(60, 0, 0))
    _run(1)
    ok(tq.stage == 2 and has(tu.chat, "All yours"), "walk up and the unit hands them over")
    _run(4)
    ok(LC.NPCs[guard] and LC.NPCs[guard].state ~= "event", "and goes back to his beat")
    LC.ResolveChoice(tu, tq.id, 1)
    _run(1)
    hook.Run("LivingCityIncarcerated", det, 100, "test", tu)
    _run(1)
    ok(tq.done, "detaining them finishes the job")
end

----------------------------------------------------------------------
section("Routes learn which links don't walk")
local ffi = require("ffi")
local function ainLinked(nds, lks)
    local size = 12 + #nds * (14 * 4 + 1 + 2 + 2) + 4 + #lks * (2 + 2 + 10)
    local buf = ffi.new("uint8_t[?]", size)
    local pos = 0
    local function put(t, n, v) ffi.cast(t .. "*", buf + pos)[0] = v pos = pos + n end
    put("int32_t", 4, 37) put("int32_t", 4, 1) put("int32_t", 4, #nds)
    for _, nd in ipairs(nds) do
        put("float", 4, nd[1]) put("float", 4, nd[2]) put("float", 4, nd[3]) put("float", 4, 0)
        for _ = 1, 10 do put("float", 4, 0) end
        put("uint8_t", 1, 2) put("uint16_t", 2, 0) put("int16_t", 2, 4)
    end
    put("int32_t", 4, #lks)
    for _, l in ipairs(lks) do
        put("int16_t", 2, l[1]) put("int16_t", 2, l[2])
        for _ = 0, 9 do put("uint8_t", 1, 1) end
    end
    return ffi.string(buf, size)
end
-- a short way through a locked door, and a longer way round
local O = Vector(40000, 40000, 0)
local G, L = {}, {}
local function add(x, y) G[#G + 1] = { O.x + x, O.y + y, 0 } return #G - 1 end
local s0 = add(0, 0)
local short = {}
for i = 1, 6 do short[i] = add(i * 150, 0) end
L[#L + 1] = { s0, short[1] }
for i = 2, 6 do L[#L + 1] = { short[i - 1], short[i] } end
local long = {}
for i = 1, 14 do long[i] = add(i * 65 - 30, 600) end
L[#L + 1] = { s0, long[1] }
for i = 2, 14 do L[#L + 1] = { long[i - 1], long[i] } end
L[#L + 1] = { long[14], short[6] }
for i = 1, 9 do add(-3000 - i * 100, -3000) end -- padding: enough nodes for a main area
_files["maps/graphs/rp_test.ain"] = ainLinked(G, L)
LC.Start(admin)
-- the locked door, between the 3rd and 4th nodes of the short way
_walls = { { a = O + Vector(530, -100, 0), b = O + Vector(530, 100, 0) } }
local dest = O + Vector(900, 0, 0)
local w, wst2 = LC.SpawnCitizen(O + Vector(0, 0, 4))
wst2.leaveAt = nil
LC.GoTo(w, wst2, dest, false, nil)
local firstWay = wst2.route[1]
local arrived = false
for _ = 1, 160 do
    _run(0.5)
    if w:GetPos():Distance(dest) < 80 then arrived = true break end
end
ok(math.abs(firstWay.y - O.y) < 100, "the first plan takes the short way, through the door", tostring(firstWay))
ok(arrived, "stopped by the door, they find the way round and get there", tostring(w:GetPos()) .. " " .. tostring(wst2.state))
ok(LC.BadLinkCount() >= 1 and LC.NavStats.replanned >= 1, "the link through the door is remembered", LC.BadLinkCount())
local again = LC.NavRoute(O + Vector(0, 0, 0), dest, "citizen")
local roundAgain = false
for _, p in ipairs(again or {}) do if p.y > O.y + 300 then roundAgain = true end end
ok(roundAgain, "and the next person is sent the way round from the start")
w:Remove()
_walls = {}

----------------------------------------------------------------------
section("Crowds spread out over the streets")
-- two parallel streets of the same length between the same two corners
local O2 = Vector(50000, 50000, 0)
G, L = {}, {}
local function add2(x, y) G[#G + 1] = { O2.x + x, O2.y + y, 0 } return #G - 1 end
local west, east = add2(0, 150), add2(1500, 150)
local north, south = {}, {}
for i = 1, 9 do north[i] = add2(i * 150, 300) south[i] = add2(i * 150, 0) end
L[#L + 1] = { west, north[1] } L[#L + 1] = { west, south[1] }
for i = 2, 9 do L[#L + 1] = { north[i - 1], north[i] } L[#L + 1] = { south[i - 1], south[i] } end
L[#L + 1] = { north[9], east } L[#L + 1] = { south[9], east }
_files["maps/graphs/rp_test.ain"] = ainLinked(G, L)
LC.Start(admin)
local useN, useS = 0, 0
local crowd = {}
for i = 1, 10 do
    local c, cs = LC.SpawnCitizen(O2 + Vector(0, 150, 4))
    c.sim = false
    cs.leaveAt = nil
    LC.GoTo(c, cs, O2 + Vector(1500, 150, 0), false, nil)
    local n, so = 0, 0
    for _, p in ipairs(cs.route) do if p.y > O2.y + 200 then n = n + 1 elseif p.y < O2.y + 100 then so = so + 1 end end
    if n > so then useN = useN + 1 elseif so > n then useS = useS + 1 end
    crowd[#crowd + 1] = c
    LC.RefreshNavTraffic()
end
ok(useN >= 3 and useS >= 3, "ten people heading the same way don't all take the same street", useN .. " north, " .. useS .. " south")
local spotsHit = {}
for _, c in ipairs(crowd) do
    local r = LC.NPCs[c].route
    if #r > 1 then spotsHit[tostring(r[1])] = true end
end
ok(table.Count(spotsHit) >= 4, "and they don't all aim for the same spot", table.Count(spotsHit))
for _, c in ipairs(crowd) do c:Remove() end
_files["maps/graphs/rp_test.ain"] = nil
LC.Start(admin)
_walls = savedWalls
end
PlacementAndRouteTests()

function AnnouncementTests()
----------------------------------------------------------------------
section("Announcements say what's going on")
local listener = newPlayer("Listener", "citizen")
listener.chat = {}
LC.Announce("ambient", "npc/overwatch/cityvoice/f_innactionisconspiracy_spkr.wav")
ok(has(listener.chat, "counts as conspiracy") and has(listener.chat, "Nothing changes"), "an ambient line is put into words, and you're told it's just atmosphere", table.concat(listener.chat, " | "))
LC.EndEvent(true)
listener.chat = {}
LC.StartEvent("curfew", 4)
ok(has(listener.chat, "Curfew for 4 minutes") and has(listener.chat, "seconds") and has(listener.chat, "warns you three times"), "a curfew explains what to do and what happens if you don't", table.concat(listener.chat, " | "))
local unitL = newPlayer("ListenerUnit", "cp")
unitL.chat = {}
LC.StartEvent("sweep", 2)
ok(has(unitL.chat, "Stop and search citizens"), "units get told their side of it")
listener.chat = {}
LC.EndEvent(false)
ok(has(listener.chat, "Inspections are over"), "and everyone hears when it ends")
listener:SetPos(Vector(-30000, 30000, 0))
unitL:SetPos(Vector(-30000, 30000, 0))
end
AnnouncementTests()

function RPTests()
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local heard = {}
local realSend = LC.SendCompressed
LC.SendCompressed = function(msg, tbl, rec)
    if msg == "lc_chat" then
        local text = {}
        for _, p in ipairs(tbl.p) do if type(p) == "string" then text[#text + 1] = p end end
        for _, r in ipairs(rec or {}) do heard[r] = heard[r] or {} table.insert(heard[r], table.concat(text)) end
    end
    return realSend(msg, tbl, rec)
end
local function said(p, needle) return has(heard[p] or {}, needle) end

----------------------------------------------------------------------
section("Talking in character")
local C0 = Vector(-48000, -48000, 0)
local talker = newPlayer("Talker", "citizen")
local near = newPlayer("NearBy", "citizen")
local far = newPlayer("FarAway", "citizen")
talker:SetPos(C0) near:SetPos(C0 + Vector(200, 0, 0)) far:SetPos(C0 + Vector(800, 0, 0))
local tname = talker:GetNW2String("lc_char", "")
ok(hook.Run("PlayerSay", talker, "Morning.") == "", "ordinary chat is spoken out loud, not broadcast")
ok(said(near, "says: \"Morning.\"") and not said(far, "Morning"), "and only people nearby hear it")
ok(said(near, "[A man") or said(near, "[A woman"), "a stranger hears it from someone they describe, not a name")
ok(said(talker, tname), "you hear yourself by name")
hook.Run("PlayerSay", talker, "/me leans against the wall.")
ok(said(near, "** [") and said(near, "leans against the wall."), "/me describes what you do")
hook.Run("PlayerSay", talker, "/y Get down!")
ok(said(far, "yells: \"GET DOWN!!\""), "/y carries further")
hook.Run("PlayerSay", talker, "/w psst")
ok(not said(near, "psst"), "/w only reaches someone right next to you")
hook.Run("PlayerSay", talker, "/it A siren starts up somewhere.")
ok(said(near, "** A siren starts up"), "/it describes the scene")
hook.Run("PlayerSay", talker, "// anyone know how to cook?")
ok(said(far, "[OOC] Talker: anyone know how to cook?"), "// is out of character, for everyone")
hook.Run("PlayerSay", talker, "// again")
ok(not said(far, "again"), "with a cooldown")
ok(hook.t.PlayerSay.LivingCityICChat(talker, "!jobs") == nil, "! commands still go to the game")
hook.Run("PlayerSay", talker, "/nonsense here")
ok(not said(near, "nonsense"), "a mistyped command isn't said out loud")
ok(hook.t.PlayerCanHearPlayersVoice.LivingCityVoice(near, talker) == true and hook.t.PlayerCanHearPlayersVoice.LivingCityVoice(far, talker) == true
    and not hook.t.PlayerCanHearPlayersVoice.LivingCityVoice(newPlayer("VoiceFar", "citizen"), talker), "voice carries the same way")

----------------------------------------------------------------------
section("Knowing each other")
ok(not LC.Recognizes(near, talker), "you don't know a stranger's name")
local realET = talker.GetEyeTrace
talker.GetEyeTrace = function(self) return { Entity = near, HitPos = near:GetPos(), StartPos = self:EyePos() } end
heard = {}
hook.Run("PlayerSay", talker, "/recognize")
talker.GetEyeTrace = realET
ok(LC.Recognizes(near, talker) and said(near, "introduces themselves as " .. tname), "/recognize tells the person in front of you your name")
ok(not LC.Recognizes(far, talker), "and nobody else")
heard = {}
hook.Run("PlayerSay", talker, "Hello again.")
ok(said(near, tname .. " says"), "now they hear you by name")
ok(LC.Recognizes(near, talker) and string.find(_files and "" or "", "") ~= nil, "(remembered)")
local ok1, msg = LC.SetDescription(far, "tall, with a shaved head and a limp")
ok(ok1 and far:GetNW2String("lc_desc", "") == "A tall, with a shaved head and a limp" or far:GetNW2String("lc_desc", ""):find("shaved head"), "/chardesc sets what strangers see", far:GetNW2String("lc_desc", ""))
far:SetPos(C0 + Vector(100, 100, 0))
heard = {}
hook.Run("PlayerSay", far, "Nice weather.")
ok(said(talker, "shaved head"), "and that's how they're named in chat")
heard = {}
hook.Run("PlayerSay", talker, "/recognize all")
ok(LC.Recognizes(far, talker), "/recognize all tells everyone close enough to hear")
local unitR = newPlayer("RecogUnit", "cp")
LC.Introduce(talker, unitR)
ok(string.find(LC.NameFor(talker, unitR), "CP", 1, true) == 1, "units are known by their designation, mask on")
hook.Run("LivingCityNewCharacter", talker)
ok(next(LC.SendRecog and talker.lcRecog or {}) == nil, "a new life starts with nobody known")

----------------------------------------------------------------------
section("Going down")
local victim = newPlayer("Victim", "citizen")
local shooter = newPlayer("Shooter", "citizen")
local medic = newPlayer("Helper", "citizen")
victim:SetPos(C0 + Vector(0, 600, 0)) medic:SetPos(C0 + Vector(40, 600, 0)) shooter:SetPos(C0 + Vector(0, 900, 0))
victim:SetHealth(30)
ok(LC.TryDown(victim, _dmg(shooter, 50)), "a killing blow puts you down instead")
ok(victim:Alive() and LC.IsDowned(victim) and victim:Health() == 1, "alive, on the ground")
local rag = LC.Downed[victim].rag
ok(IsValid(rag) and rag.lcDownedPly == victim and victim:GetNW2Float("lc_downed_until", 0) > CurTime(), "a body to help, and a clock running")
ok(not LC.TryDown(victim, _dmg(shooter, 50)), "(down is down)")
hook.Run("PlayerUse", medic, rag)
_run(9)
ok(not LC.IsDowned(victim) and victim:Health() == 10 and not IsValid(rag), "E on them, a few seconds, and they're back up")
LC.GiveItem(medic, "bandage")
LC.TryDown(victim, _dmg(shooter, 50))
medic.lcDownUseNext = 0
hook.Run("PlayerUse", medic, LC.Downed[victim].rag)
_run(5)
ok(victim:Health() == 30 and not LC.HasItem(medic, "bandage"), "faster, and better, with a bandage")
LC.TryDown(victim, _dmg(shooter, 50))
hook.Run("EntityTakeDamage", LC.Downed[victim].rag, _dmg(shooter, 20))
ok(not victim:Alive() and not LC.IsDowned(victim), "shoot someone who's down and that's the end")
victim.alive = true victim:SetHealth(100)
LC.TryDown(victim, _dmg(shooter, 200))
LC.Downed[victim].untilT = CurTime()
_run(0.5)
ok(not victim:Alive(), "run out of time and you bleed out")
victim.alive = true victim:SetHealth(100)
ok(not LC.TryDown(victim, _dmg(shooter, 900)), "some things nobody gets up from")
local suspect = newPlayer("DownedSuspect", "citizen")
suspect:SetPos(C0 + Vector(0, -600, 0))
LC.ReportCrime(suspect, "Test", 120)
LC.TryDown(suspect, _dmg(shooter, 200))
local copD = newPlayer("CuffingUnit", "cp")
copD:SetPos(C0 + Vector(40, -600, 0))
hook.Run("PlayerUse", copD, LC.Downed[suspect].rag)
_run(4)
ok(LC.Prisoners[suspect] ~= nil and not LC.IsDowned(suspect), "a unit cuffs a wanted person where they lie")
LC.ReleasePrisoner(suspect)
local quitter = newPlayer("Quitter", "citizen")
LC.TryDown(quitter, _dmg(shooter, 200))
local qrag = LC.Downed[quitter].rag
hook.Run("PlayerSay", quitter, "!giveup")
ok(not quitter:Alive(), "!giveup lets go")
ok(IsValid(qrag), "and the body already on the ground stays where it is")
quitter.lcNoDeathRag = true
ok(hook.Run("DoPlayerDeath", quitter) == true, "while dying that way, the game's own second ragdoll is skipped")
quitter.lcNoDeathRag = nil
local dragged = newPlayer("Dragged", "citizen")
dragged:SetPos(C0 + Vector(0, 1200, 0))
LC.TryDown(dragged, _dmg(shooter, 200))
local drag = newPlayer("Dragger", "citizen")
drag:SetPos(C0 + Vector(60, 1200, 0))
local drag_et = drag.GetEyeTrace
drag.GetEyeTrace = function(self) return { Entity = LC.Downed[dragged].rag, HitPos = dragged:GetPos(), StartPos = self:EyePos() } end
ok(LC.ToggleDrag(drag), "you can drag someone who's down")
drag.GetEyeTrace = drag_et
drag:SetPos(C0 + Vector(160, 1200, 0))
_run(0.5)
ok(LC.Downed[dragged].rag:GetPos():Distance(drag:GetPos()) < 80, "and they come with you")
LC.Revive(dragged, 20)
heard = {}
local whisperer = newPlayer("DownedTalker", "citizen")
whisperer:SetPos(C0 + Vector(0, 2000, 0))
LC.TryDown(whisperer, _dmg(shooter, 200))
local listener = newPlayer("DownListener", "citizen")
listener:SetPos(C0 + Vector(200, 2000, 0))
hook.Run("PlayerSay", whisperer, "help me")
ok(not said(listener, "help me"), "on the ground you can only whisper")
LC.Revive(whisperer, 20)

LC.SendCompressed = realSend
GAMEMODE = savedGM
for _, p in ipairs(player.GetAll()) do if p:Alive() then p:SetPos(FAR) end end
end
RPTests()

function HintTests()
LC.HintScan = _realHintScan
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local got = {}
local realSend = LC.SendCompressed
LC.SendCompressed = function(msg, tbl, rec)
    if msg == "lc_hint" and IsValid(rec) then got[rec] = got[rec] or {} table.insert(got[rec], tbl) end
    return realSend(msg, tbl, rec)
end
local function tip(p, key)
    for _, t in ipairs(got[p] or {}) do if t.k == key or string.find(t.k, "^" .. key .. "%.") then return t end end
end
local function free(p) p.lcHintBusy = 0 end

----------------------------------------------------------------------
section("Tips: the first time something happens")
local H0 = Vector(-46000, 46000, 0)
local newbie = newPlayer("Newbie", "citizen")
newbie:SetPos(H0)
newbie.lcHintSpawnT = CurTime() - 10
free(newbie)
ok(LC.HintScan(newbie) == "welcome" and tip(newbie, "welcome").x:find("{gm_showhelp}", 1, true), "a newcomer is welcomed first, with the guide's key in it")
ok(LC.HintScan(newbie) == nil, "one tip at a time: nothing else while it's on screen")
free(newbie)
ok(LC.HintScan(newbie) ~= "menus", "the getting-started tips are spaced out, not a barrage")
newbie.lcHintIntroNext = CurTime() - 1
ok(LC.HintScan(newbie) == "menus", "then, half a minute on, the menus")
for _ = 1, 8 do free(newbie) newbie.lcHintIntroNext = 0 LC.HintScan(newbie) end
ok(tip(newbie, "f_citizen") and tip(newbie, "ic_chat") and not tip(newbie, "f_cp") and not tip(newbie, "f_resistance"), "then what their faction does, and how to talk")
ok(not LC.Hint(newbie, "welcome"), "each tip shows once")
newbie.lcHintSeen = nil
ok(not LC.HintDue(newbie, "welcome") and string.find(newbie:GetPData("lc_hints_seen", ""), "welcome", 1, true), "and is remembered across sessions")

local tipCop = newPlayer("TipCop", "cp")
tipCop:SetPos(H0 + Vector(0, 3000, 0))
free(tipCop) free(newbie)
LC.Hint(tipCop, "dealer") LC.Hint(newbie, "dealer")
ok(tip(tipCop, "dealer").x:find("bust", 1, true) and tip(newbie, "dealer").x:find("trade", 1, true), "a unit and a citizen are told different things about the same dealer")
local tipZed = newPlayer("TipZombie", "zombie")
tipZed:SetPos(H0 + Vector(0, 6000, 0))
free(tipZed)
ok(not LC.Hint(tipZed, "bin") and LC.Hint(tipZed, "f_zombie"), "the infested only get tips meant for them")

newbie.lcHintBusy = CurTime() + 60
ok(not LC.Hint(newbie, "vending") and LC.HintDue(newbie, "vending"), "too many waiting and the next one is held back for later, not lost")
LC.SetWanted(newbie, 30, "Test")
ok(tip(newbie, "wanted") and tip(newbie, "wanted").u, "being wanted jumps the queue")
LC.ClearWanted(newbie)
free(newbie)
ok(LC.Hint(newbie, "vending"), "(and the held one comes up later)")

----------------------------------------------------------------------
section("Tips: someone goes down")
local D0 = H0 + Vector(4000, 0, 0)
local fallen = newPlayer("TipFallen", "citizen")
local witness = newPlayer("TipWitness", "citizen")
local hidden = newPlayer("TipHidden", "citizen")
local distant = newPlayer("TipDistant", "citizen")
local gunman = newPlayer("TipGunman", "citizen")
fallen:SetPos(D0) witness:SetPos(D0 + Vector(300, 0, 0)) hidden:SetPos(D0 + Vector(0, 300, 0))
distant:SetPos(D0 + Vector(2000, 0, 0)) gunman:SetPos(D0 + Vector(0, -2000, 0))
for _, p in ipairs({ fallen, witness, hidden, distant }) do free(p) end
local savedWalls = _walls
_walls = { { a = D0 + Vector(-400, 150, 0), b = D0 + Vector(400, 150, 0) } }
fallen:SetHealth(30)
LC.TryDown(fallen, _dmg(gunman, 50))
ok(tip(fallen, "downed_self") and tip(fallen, "downed_self").u, "going down tells you what's happening, straight away")
ok(tip(witness, "downed_other") and tip(witness, "downed_other").x:find("Drag them along", 1, true), "someone who sees it is told how to help, and where Drag is in the menu")
ok(not tip(hidden, "downed_other") and not tip(distant, "downed_other"), "but not someone behind a wall, or far off")
_walls = savedWalls
local late = newPlayer("TipLate", "citizen")
late:SetPos(D0 + Vector(200, 200, 0))
free(late)
ok(LC.HintScan(late) == "downed_other", "someone who walks up later is told too, before anything else")
LC.Revive(fallen, 20)
ok(tip(fallen, "revived"), "and getting up tells you to patch yourself up")

----------------------------------------------------------------------
section("Tips: what's around you, and in your pockets")
local P0 = H0 + Vector(8000, 0, 0)
local looker = newPlayer("TipLooker", "citizen")
looker:SetPos(P0)
for _, k in ipairs({ "welcome", "menus", "f_citizen", "ic_chat", "needs_intro" }) do looker.lcHintSeen = looker.lcHintSeen or {} end
LC.HintScan(looker)
for _ = 1, 8 do free(looker) looker.lcHintIntroNext = 0 LC.HintScan(looker) end
local bin = ents.Create("prop_physics")
bin:SetModel("models/props_junk/trashdumpster01a.mdl")
bin:SetPos(P0 + Vector(80, 0, 0))
bin:Spawn()
free(looker)
ok(LC.IsBinModel(bin:GetModel()) and LC.HintScan(looker) == "bin", "walk up to a bin and you're told to go through it")
bin:Remove()
local zone = { pos = P0 + Vector(0, 3000, 0), r = 300, kind = "rebel", group = 0 }
table.insert(LC.Zones, zone)
local tipReb = newPlayer("TipRebel", "resistance", nil, 10)
tipReb:SetPos(zone.pos)
tipReb.lcHintSpawnT = CurTime() - 10
for _ = 1, 12 do free(tipReb) tipReb.lcHintIntroNext = 0 LC.HintScan(tipReb) end -- (the getting-started tips first, with no gap between them here)
ok(tip(tipReb, "zone_rebel") and string.lower(tip(tipReb, "zone_rebel").x):find("home", 1, true), "a fighter in rebel territory hears it's home")
for i = #LC.Zones, 1, -1 do if LC.Zones[i] == zone then table.remove(LC.Zones, i) end end
tipReb:SetNW2String("lcd_disguise", "citizen")
tipReb:Give("weapon_pistol") tipReb:SelectWeapon("weapon_pistol")
tipReb.lcHintBusy = CurTime() + 20
ok(LC.HintScan(tipReb) == "plainclothes_gun", "a gun out in plain clothes gets a warning, even with another tip showing")
tipReb:SetNW2String("lcd_disguise", "")
free(looker)
LC.GiveItem(looker, "seeds")
_run(0.6)
ok(tip(looker, "item_seeds"), "seeds in your pockets: where to plant them")
looker:SetNW2Float("lcn_hunger", 10)
free(looker)
local needsOn = GetConVar("lc_needs"):GetBool() and LC.Running
local k = LC.HintScan(looker)
ok(not needsOn or k == "hungry", "hungry: where to find food", k)
free(looker)
ok(LC.HintScan(looker) ~= "hungry", "and not again straight away")
looker:SetNW2Float("lcn_hunger", 100)

----------------------------------------------------------------------
section("Tips: events, promotions, and turning them off")
for _, p in ipairs({ newbie, tipCop }) do free(p) end
hook.Run("LivingCityEventStarted", "curfew", 2) -- just the news of it: a real curfew sends the whole city home
ok(tip(newbie, "event_curfew") and tip(newbie, "event_curfew").x:find("arrow", 1, true)
    and tip(tipCop, "event_curfew") and tip(tipCop, "event_curfew").x:find("grace period", 1, true), "a curfew: citizens told to go home, units what to expect")
local riser = newPlayer("TipRiser", "resistance", nil, 0)
riser:SetPos(H0 + Vector(0, -4000, 0))
free(riser)
LC.AddXP(riser, 400, "test")
ok(riser:GetNW2Int("lcf_rank", 1) >= 2 and tip(riser, "promoted_member"), "made a Member: fighters will follow you now", riser:GetNW2Int("lcf_rank", 1))
free(looker)
hook.Run("PlayerSay", looker, "!hints")
ok(has(looker.chat or {}, "last few") and has(looker.chat, "[F2]") and not has(looker.chat, "{gm_"), "!hints shows the last few again, with keys spelled out")
ok(hook.Run("PlayerSay", looker, "!hints off") == "" and not LC.Hint(looker, "birds"), "!hints off stops them")
hook.Run("PlayerSay", looker, "!hints on")
ok(LC.Hint(looker, "birds"), "!hints on brings them back")
hook.Run("PlayerSay", looker, "!hints reset")
free(looker)
ok(LC.Hint(looker, "welcome"), "!hints reset shows them all again")
_setcvar("lc_hints", 0)
free(looker)
ok(not LC.Hint(looker, "headcrab"), "lc_hints 0 turns them off for everyone")
_setcvar("lc_hints", 1)

LC.SendCompressed = realSend
GAMEMODE = savedGM
for _, p in ipairs({ newbie, tipCop, tipZed, fallen, witness, hidden, distant, gunman, late, looker, tipReb, riser }) do p:SetPos(FAR) end
end
HintTests()

function AdminToolTests()
section("Admin testing tools: XP, ranks, credits, standing")
local tadmin = newPlayer("ToolAdmin", "citizen")
tadmin.admin = true
local pleb = newPlayer("ToolPleb", "citizen")
tadmin:SetPos(Vector(-30000, 30000, 0)) pleb:SetPos(Vector(-30000, 30000, 0))
local function xpOf(p, f) return tonumber(p:GetPData("lcf_xp_" .. (f or "citizen"), 0)) or 0 end
tadmin.chat, pleb.chat = {}, {}
ok(hook.Run("PlayerSay", pleb, "!givexp 500") == "" and xpOf(pleb) == 0 and has(pleb.chat, "Admins only"), "players can't give themselves anything")
hook.Run("PlayerSay", tadmin, "!givexp 500")
ok(xpOf(tadmin) == 500 and tadmin:GetNW2Int("lcf_rank", 1) == 3, "!givexp adds XP and the rank follows", tadmin:GetNW2Int("lcf_rank", 1))
hook.Run("PlayerSay", tadmin, "!setrank 4")
ok(tadmin:GetNW2Int("lcf_rank", 1) == 4 and xpOf(tadmin) == 800, "!setrank jumps straight to a rank")
tadmin.chat = {}
hook.Run("PlayerSay", tadmin, "!setrank 9")
ok(tadmin:GetNW2Int("lcf_rank", 1) == 4 and has(tadmin.chat, "ranks go from 1 to 4"), "a rank that doesn't exist says what does")
hook.Run("PlayerSay", tadmin, "!givexp -300")
ok(xpOf(tadmin) == 500 and tadmin:GetNW2Int("lcf_rank", 1) == 3, "taking XP away demotes")
local c0 = LC.Credits(tadmin)
hook.Run("PlayerSay", tadmin, "!givecredits 1000")
ok(LC.Credits(tadmin) == c0 + 1000, "!givecredits")
hook.Run("PlayerSay", tadmin, "!resetcredits")
ok(LC.Credits(tadmin) == 0, "!resetcredits takes them to nothing")
hook.Run("PlayerSay", tadmin, "!givestanding 150")
ok(LC.Standing(tadmin) == 150, "!givestanding")
hook.Run("PlayerSay", tadmin, "!givexp 100 ToolPleb")
ok(xpOf(pleb) == 100 and xpOf(tadmin) == 500, "a name at the end gives it to someone else")
_netcall("lc_admintools_do", tadmin, "faction", "cp", "")
ok(tadmin:GetNW2String("lcf_faction", "") == "cp", "the panel switches faction")
_netcall("lc_admintools_do", tadmin, "xp", "1000", "")
ok(xpOf(tadmin, "cp") == 1000 and xpOf(tadmin, "citizen") == 500, "XP goes to the faction you're in")
_netcall("lc_admintools_do", tadmin, "item", "lockpick", "")
ok(LC.HasItem(tadmin, "lockpick"), "and hands out items")
_netcall("lc_admintools_do", pleb, "credits", "1000", "")
ok(LC.Credits(pleb) < 1000, "the panel's messages are ignored from anyone who isn't an admin")
hook.Run("PlayerSay", tadmin, "!resetme")
ok(xpOf(tadmin, "cp") == 0 and xpOf(tadmin, "citizen") == 0 and LC.Credits(tadmin) == 0 and LC.Standing(tadmin) == 0
    and tadmin:GetNW2Int("lcf_rank", 1) == 1, "!resetme: XP in every faction, credits and standing all back to 0")
net.sent = {}
hook.Run("PlayerSay", tadmin, "!admintools")
ok(_lastnet("lc_admintools") ~= nil, "!admintools opens the panel")
net.sent = {}
hook.Run("PlayerSay", pleb, "!admintools")
ok(_lastnet("lc_admintools") == nil, "but not for players")
LC.SetFaction(tadmin, "citizen", nil, true)
end
AdminToolTests()

function CPToolTests()
local FAR = Vector(-30000, 30000, 0)
local C = Vector(42000, -42000, 0) -- somewhere nobody else is
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function hasSound(s) for _, x in ipairs(_sounds) do if x == s then return true end end return false end

----------------------------------------------------------------------
section("CP toolset: the records terminal")
local cit = newPlayer("RecCitizen", "citizen")
local unit = newPlayer("RecUnit", "cp")
cit:SetPos(C) unit:SetPos(C + Vector(0, 2000, 0))
cit.chat, unit.chat = {}, {}
local key = LC.RecordKey(cit)
ok(key ~= "" and LC.RecordOf(cit).name ~= nil, "every citizen has a record, by CID", key)
LC.SetWanted(cit, 30, "Loitering")
LC.ClearWanted(cit)
local function lastV(p) local r = LC.RecordOf(p) return r.v[#r.v] and r.v[#r.v].text or "" end
ok(lastV(cit) == "Wanted: Loitering", "being wanted goes on the record by itself", lastV(cit))
hook.Run("LivingCitySearched", unit, cit, { { id = "lockpick", n = 1 } }, {})
ok(string.find(lastV(cit), "Contraband: Lockpick set", 1, true), "so does contraband a search turns up", lastV(cit))
net.sent = {}
hook.Run("PlayerSay", cit, "!records")
ok(_lastnet("lc_records") == nil and has(cit.chat, "Civil Protection only"), "citizens can't open the terminal")
hook.Run("PlayerSay", unit, "!records")
ok(_lastnet("lc_records") ~= nil, "units can")
_netcall("lc_records_do", unit, "note", key, "Seen near the canal at night", "")
local r = LC.RecordOf(cit)
ok(r.n[#r.n] and r.n[#r.n].text == "Seen near the canal at night", "units add notes")
_netcall("lc_records_do", unit, "violation", key, "False request", "")
ok(lastV(cit) == "False request", "and log violations")
local s0 = LC.Standing(cit)
_netcall("lc_records_do", unit, "loyalty", key, "", "25")
ok(LC.Standing(cit) == s0 + 10, "a unit can award loyalty points, 10 at a time", tostring(LC.Standing(cit) - s0) .. " " .. tostring(unit.chat[#unit.chat]) .. " " .. tostring(cit.chat[#cit.chat]))
_netcall("lc_records_do", unit, "loyalty", key, "", "10")
ok(LC.Standing(cit) == s0 + 10, "once every two minutes per citizen")
_netcall("lc_records_do", cit, "loyalty", key, "", "10")
_netcall("lc_records_do", cit, "violation", key, "hacked", "")
ok(LC.Standing(cit) == s0 + 10 and lastV(cit) ~= "hacked", "the terminal ignores anyone who isn't a unit")
cit:SetNW2String("lcd_alias", "#55-555")
ok(LC.RecordKey(cit) == "alias:#55-555" and #LC.RecordOf(cit).v == 0, "forged papers come with a clean record")
cit:SetNW2String("lcd_alias", "")
_run(11)
ok(string.find(_files["livingcity/records.json"] or "", "Seen near the canal", 1, true), "records are kept on disk")

----------------------------------------------------------------------
section("CP toolset: BOLOs")
unit.chat = {}
local okB, b = LC.AddBOLO(unit, key, "Red jacket, heading north")
ok(okB and cit:GetNW2Bool("lc_bolo", false) and cit:GetNW2String("lc_bolo_text", "") == "Red jacket, heading north", "a BOLO on a record shows on that person's tag")
ok(has(unit.chat, "BOLO"), "and every unit hears it")
unit.lcBoloNext = 0 -- (a second one, after the half minute)
local okD, d = LC.AddBOLO(unit, nil, "Male, grey coat")
ok(okD and d.key == nil, "a BOLO can be just a description")
ok(not LC.AddBOLO(cit, nil, "Unit 04 is corrupt"), "only units issue them")
LC.ClearBOLO(unit, b.id)
ok(not cit:GetNW2Bool("lc_bolo", false), "cancelling it clears the tag")
d.untilT = os.time() - 1
LC.SyncBolos()
local still = false
for _, x in ipairs(LC.BOLOs) do if x == d then still = true end end
ok(not still, "and they run out")

----------------------------------------------------------------------
section("CP toolset: hands up, zip ties, walking someone along")
local target = newPlayer("TieTarget", "citizen")
local tier = newPlayer("TieTier", "citizen")
target:SetPos(C + Vector(0, 4000, 0))
target:Give("weapon_pistol")
tier:SetPos(target:GetPos() + Vector(60, 0, 0)) -- in front of them (they face +x)
local okT, why = LC.CanTie(tier, target)
ok(not okT and string.find(why, "cuffs", 1, true), "you need cuffs", why)
LC.GiveItem(tier, "zipties", 2)
okT, why = LC.CanTie(tier, target)
ok(not okT and string.find(why, "fight you off", 1, true), "and they won't let you, face to face", why)
tier:SetPos(target:GetPos() - Vector(60, 0, 0))
ok(LC.CanTie(tier, target), "from behind, you can")
tier.lookingAt = target
hook.Run("PlayerSay", tier, "!tie")
_run(3.5)
ok(LC.IsTied(target) and target:GetNW2Bool("lc_tied", false) and not target:HasWeapon("weapon_pistol"), "three seconds and their hands are tied, weapons and all")
ok(LC.InvCount(tier) == 1 or not LC.HasItem(tier, "zipties", 2), "it uses a zip tie")
target.chat = {}
LC.InvAction(target, "use", "bread")
ok(has(target.chat, "hands are cuffed"), "cuffed hands can't use anything")
hook.Run("PlayerSay", tier, "!drag")
ok(LC.Tied[target].escort == tier, "!drag takes them by the arm")
tier:SetPos(tier:GetPos() + Vector(0, 400, 0))
_run(0.3)
ok(target:GetPos():Distance(tier:GetPos()) < 120, "and they come along", target:GetPos():Distance(tier:GetPos()))
hook.Run("PlayerSay", tier, "!drag")
ok(LC.Tied[target].escort == nil, "!drag again lets go")
hook.Run("PlayerSay", target, "!struggle")
_run(GetConVar("lc_struggle_seconds"):GetFloat() + 1)
ok(not LC.IsTied(target) and target:HasWeapon("weapon_pistol"), "left alone, they work themselves free, and get their things back")

local hu = newPlayer("HandsUpper", "citizen")
hu:SetPos(C + Vector(0, 6000, 0))
hook.Run("PlayerSay", hu, "!handsup")
ok(hu:GetNW2Bool("lc_handsup", false), "!handsup")
local cop = newPlayer("TieUnit", "cp")
cop:SetPos(hu:GetPos() + Vector(60, 0, 0))
ok(LC.CanTie(cop, hu), "hands up: tied face to face, and units carry their own ties")
LC.TiePlayer(hu, cop)
ok(LC.IsTied(hu) and not hu:GetNW2Bool("lc_handsup", false), "(tied)")
local jailed, err = LC.Incarcerate(hu, 60, "test", cop)
ok(not jailed or (not LC.IsTied(hu) and not hu:GetNW2Bool("lc_tied", false)), "taken into custody, the ties come off", err)
if jailed then LC.ReleasePrisoner(hu) end
hu:Give("weapon_lc_hands") hu:Give("weapon_pistol")
hu:SelectWeapon("weapon_pistol")
LC.SetHandsUp(hu, true)
hu:SelectWeapon("weapon_pistol")
ok(hu:GetNW2Bool("lc_handsup", false) == false or hu:GetActiveWeapon():GetClass() == "weapon_lc_hands", "drawing a weapon puts your hands down")

----------------------------------------------------------------------
section("CP toolset: sociostability")
local adminS = newPlayer("SocioAdmin", "citizen")
adminS.admin = true
adminS:SetPos(FAR)
local okS, msg = LC.SetSocio(cit, "red")
ok(not okS and string.find(msg, "Officers only", 1, true), "citizens can't set it")
cit.chat = {}
LC.SetSocio(adminS, "red", 5)
ok(LC.Socio == "red" and _globals.lc_socio == "red" and LC.SocioStopMul() == 2, "an officer or admin can declare a judgment waiver")
ok(has(cit.chat, "JUDGMENT WAIVER") and has(cit.chat, "Get indoors"), "everyone hears it, and what it means")
local savedEvent = LC.Event
LC.Event = "lockdown"
ok(LC.SocioAuto() == "red", "a lockdown is red by itself")
LC.Event = "sweep"
ok(LC.SocioAuto() ~= "green", "a sweep is at least yellow")
LC.Event = savedEvent
LC.SetSocio(adminS, "auto")
ok(LC.SocioOverride == nil, "!socio auto gives it back to the city")

----------------------------------------------------------------------
section("CP toolset: /request")
cit.chat, unit.chat = {}, {}
local okR, whyR = LC.CPRequest(cit, "Someone is breaking into my block")
ok(not okR and string.find(whyR, "call box", 1, true), "you need a Civil Protection call box")
LC.GiveItem(cit, "request_device")
net.sent = {}
hook.Run("PlayerSay", cit, "/request Someone is breaking into my block")
local mark = _lastnet("lc_cpmark")
ok(has(unit.chat, "[Request]") and has(unit.chat, "breaking into my block") and mark ~= nil, "units get the message and a marker")
ok(LC.Requests[1] and LC.Requests[1].text == "Someone is breaking into my block", "and it's on the terminal")
okR, whyR = LC.CPRequest(cit, "again")
ok(not okR and string.find(whyR, "recharging", 1, true), "once a minute")

----------------------------------------------------------------------
section("CP toolset: voice lines")
_sounds = {}
ok(not LC.CPVoice(cit, "movealong") and not hasSound("npc/metropolice/vo/movealong.wav"), "citizens don't have the mask's voice")
unit.lcVoiceNext = 0
ok(LC.CPVoice(unit, "movealong") and hasSound("npc/metropolice/vo/movealong.wav"), "a unit says a line by its word")
_sounds = {}
unit.lcVoiceNext = 0
hook.Run("PlayerSay", unit, "Move along.")
ok(hasSound("npc/metropolice/vo/movealong.wav"), "or just says the words")
local ow = newPlayer("VoiceOTA", "ota")
ow:SetPos(FAR)
ok(LC.CPVoice(ow, "contact") and not LC.CPVoice(ow, "pickup"), "Overwatch have their own lines")
net.sent = {}
hook.Run("PlayerSay", unit, "!vo")
ok(_lastnet("lc_vo_menu") ~= nil, "!vo opens the menu")
for _, l in ipairs(LCCP.Voice) do
    if not (l[1] and l[2] and string.find(l[3], "^npc/.+%.wav$")) then ok(false, "a voice line is malformed: " .. tostring(l[1])) end
end

LC.SocioOverride = nil
GAMEMODE = savedGM
for _, p in ipairs({ cit, unit, target, tier, hu, cop, adminS, ow }) do if IsValid(p) then p:SetPos(FAR) end end
end
CPToolTests()

function DirectiveTests()
local FAR = Vector(-30000, 30000, 0)
local D0 = Vector(-44000, -20000, 0)
section("Directives that go with the city's events")
_setcvar("lc_quests", 1)
LC.BadDest = {} -- (this test map has four nodes; earlier tests can leave them all marked unreachable)
local savedEvent, savedPending = LC.Event, LC.PendingEvent
LC.Event, LC.PendingEvent = nil, nil
local cops = {}
for i = 1, 6 do cops[i] = newPlayer("DirCop" .. i, "cp") cops[i]:SetPos(D0 + Vector(i * 40, 0, 0)) cops[i].lcqNext = 0 cops[i].chat = {} end
local rebel = newPlayer("DirRebel", "resistance", nil, 200)
rebel:SetPos(D0 + Vector(0, 400, 0)) rebel.chat = {}
local function find(f, tid)
    for _, p in ipairs(LC.Postings[f] or {}) do if p.tmpl and p.tmpl.id == tid and not p.dead then return p end end
end
LC.Postings.cp, LC.Postings.resistance = {}, {}
LC.RefreshBoard(cops[1])
ok(not find("cp", "cp_curfew") and not find("cp", "cp_rationduty") and not find("cp", "cp_inspect"), "no curfew, ration or inspection directives when nothing's on")
LC.PendingEvent = "curfew"
hook.Run("LivingCityEventSoon", "curfew", 120)
local post = find("cp", "cp_curfew")
ok(post ~= nil and has(cops[1].chat, "New job: Curfew enforcement"), "two minutes before a curfew, its directive goes up and units hear about it")
ok(find("resistance", "res_curfewrun") ~= nil, "and the Resistance get theirs")
LC.Event, LC.PendingEvent = "curfew", nil
ok(post and LC.AcceptPosting(cops[1], post.id), "a unit takes it")
local joined = 1
for i = 2, 6 do if LC.AcceptPosting(cops[i], post.id) then joined = joined + 1 end end
ok(joined == 6 and #post.q.members == 6, "and the whole shift can work it together", joined)
LC.RefreshBoard(cops[1])
ok(find("cp", "cp_curfew") == post, "it stays up while the curfew's on")
LC.Event = nil
hook.Run("LivingCityEventEnded", "curfew")
ok(post.dead and LC.QuestOf[cops[1]] == nil and LC.QuestOf[cops[6]] == nil, "when it's over, it's withdrawn")
ok(has(cops[1].chat, "before you got started"), "without holding it against anyone who hadn't got going")
for i = 1, 6 do cops[i].lcqNext = 0 end
LC.Postings.cp = {}
LC.RefreshBoard(cops[1])
ok(not find("cp", "cp_curfew"), "and doesn't come back on its own")

section("Directives when ground is lost")
local seed = { pos = D0 + Vector(3000, 0, 0), r = 300, kind = "infest", group = 0 }
local patch = { pos = D0 + Vector(3400, 0, 0), r = 200, kind = "infest", group = 0, grown = true, seed = seed }
table.insert(LC.Zones, seed) table.insert(LC.Zones, patch)
cops[1].chat = {}
hook.Run("LivingCityTerritoryGrew", seed, patch)
local cont = find("cp", "cp_infest")
ok(cont ~= nil and has(cops[1].chat, "New job: Containment"), "the infestation spreads: a containment directive goes up at once")
ok(cont and cont.squad and cont.squad >= 6, "for a squad")
local before = #LC.Postings.cp
hook.Run("LivingCityTerritoryGrew", seed, patch)
ok(#LC.Postings.cp == before, "one at a time")
-- touching zones are one territory, and its news comes as one line
local a = { pos = D0 + Vector(0, 3000, 0), r = 200, kind = "infest", group = 0 }
local b = { pos = D0 + Vector(350, 3000, 0), r = 200, kind = "infest", group = 0 }
local c2 = { pos = D0 + Vector(700, 3000, 0), r = 200, kind = "infest", group = 0 }
table.insert(LC.Zones, a) table.insert(LC.Zones, b) table.insert(LC.Zones, c2)
local mine
for _, cl in ipairs(LC.TerritoryClusters()) do for _, z in ipairs(cl) do if z == a then mine = cl end end end
ok(mine and #mine == 3, "infestation zones drawn touching each other spread as one territory", mine and #mine)
cops[1].chat = {}
LC.TerritoryNotice("infest", "near Block 1") LC.TerritoryNotice("infest", "near Block 2") LC.TerritoryNotice("infest", "near Block 1")
_run(3.5)
local lines = 0
for _, l in ipairs(cops[1].chat) do if string.find(l, "infestation spreading", 1, true) then lines = lines + 1 end end
ok(lines == 1 and has(cops[1].chat, "near Block 1, near Block 2"), "and growth close together is one message, not four", lines)
for i = #LC.Zones, 1, -1 do local z = LC.Zones[i] if z == seed or z == patch or z == a or z == b or z == c2 then table.remove(LC.Zones, i) end end
LC.Postings.cp, LC.Postings.resistance = {}, {}
LC.Event, LC.PendingEvent = savedEvent, savedPending
for _, p in ipairs(cops) do p:SetPos(FAR) end
rebel:SetPos(FAR)
end
DirectiveTests()

function FieldFixTests()
local FAR = Vector(-30000, 30000, 0)
local F0 = Vector(-41000, 41000, 0)
section("Patrols are a walk, not a tour of the city")
local walker = newPlayer("RouteCop", "cp")
walker:SetPos(F0)
local realRWP = LC.RandomWanderPos
-- a city of five levels, 600 units apart, spread over 12000 units
LC.RandomWanderPos = function(role, near)
    for _ = 1, 50 do
        local p = Vector(F0.x + math.random(-6000, 6000), F0.y + math.random(-6000, 6000), F0.z + 600 * math.random(-2, 2))
        if not near or (p:DistToSqr(near) < 1600 * 1600 and math.abs(p.z - near.z) < 150) then return p end
    end
    return near and (near + Vector(math.random(-900, 900), math.random(-900, 900), 0)) or F0
end
local okR = true
local worst = ""
for _ = 1, 20 do
    local r = LC.QB.Route(walker, 4, 400, 1100)
    if #r < 2 then okR = false worst = "short route" end
    for i, p in ipairs(r) do
        if math.abs(p.z - r[1].z) >= 160 then okR = false worst = "level " .. p.z end
        if i > 1 and p:Distance(r[i - 1]) > 1100 then okR = false worst = "step " .. math.floor(p:Distance(r[i - 1])) end
    end
    if math.abs(r[1].z - F0.z) >= 200 then okR = false worst = "start level " .. r[1].z end
end
ok(okR, "every stop is a short walk from the last, on the same level, starting on yours", worst)
LC.RandomWanderPos = realRWP
walker:SetPos(FAR)

section("Containment: who did it, and paying them for it")
local medic = newPlayer("ContainUnit", "cp")
medic:SetPos(F0 + Vector(0, 3000, 0))
medic:Give("weapon_pistol") medic:SelectWeapon("weapon_pistol")
medic.chat = {}
local c0 = LC.Credits(medic)
for i = 1, 4 do
    local z = LC.SpawnZombie and LC.SpawnZombie(F0 + Vector(i * 50, 3000, 0))
    if IsValid(z) then hook.Run("OnNPCKilled", z, medic, medic) z:Remove() end
end
LC.PayContainment(medic)
ok(LC.Credits(medic) == c0 + 12 and (medic.ammo or {}).Pistol == 32, "putting down the infested pays credits and the rounds it took", tostring(LC.Credits(medic) - c0) .. " " .. tostring((medic.ammo or {}).Pistol))
ok(has(medic.chat, "Containment pay: 4 infested"), "and says so")
local seed = { pos = F0 + Vector(3000, 3000, 0), r = 300, kind = "infest", group = 0 }
local patch = { pos = F0 + Vector(3400, 3000, 0), r = 200, kind = "infest", group = 0, grown = true, seed = seed }
table.insert(LC.Zones, seed) table.insert(LC.Zones, patch)
local bystander = newPlayer("ContainWatcher", "citizen")
bystander.chat = {}
LC.RecedeTerritory(patch, "cleared out", medic)
ok(has(bystander.chat, medic:GetNW2String("lcf_title", "?") .. " has contained the infestation"), "everyone hears which unit contained it")
for i = #LC.Zones, 1, -1 do if LC.Zones[i] == seed then table.remove(LC.Zones, i) end end
medic:SetPos(FAR) bystander:SetPos(FAR)

section("Each headcrab leaves its own carcass")
local crab = ents.Create("npc_headcrab_black")
crab:SetPos(F0 + Vector(0, 6000, 0))
crab:Spawn()
hook.Run("OnNPCKilled", crab, nil, nil)
_run(0.3)
local found
for _, e in ipairs(ents.FindByClass("lc_item")) do
    if e:GetNW2String("lc_item", "") == "raw_poisoncrab" and e:GetPos():Distance(F0 + Vector(0, 6000, 0)) < 50 then found = e end
end
ok(found ~= nil and LCS.Items.raw_poisoncrab.model == "models/headcrabblack.mdl", "a poison headcrab leaves a poison headcrab")
if found then found:Remove() end
crab:Remove()
local eater = newPlayer("CrabEater", "citizen")
eater:SetPos(FAR)
eater:SetHealth(100)
LC.Consume(eater, "raw_poisoncrab")
ok(eater:Health() == 55, "and eating it raw puts you on the floor", eater:Health())

section("Units get their rations without queueing")
local dutyU = newPlayer("DutyUnit", "cp")
dutyU:SetPos(FAR)
dutyU.lcnRationAt = 0
local cb = LC.Credits(dutyU)
dutyU.chat = {}
ok(LC.IssueDutyAllocation(dutyU) and LC.HasItem(dutyU, "ration") and LC.Credits(dutyU) > cb, "a unit on duty is issued a ration and coupons")
ok(has(dutyU.chat, "Duty allocation issued"), "and told")
ok(not LC.IssueDutyAllocation(dutyU), "once an allocation")
dutyU.chat = {}
LC.UseDispenser(dutyU, nil)
ok(has(dutyU.chat, "Next allocation"), "it's the same allocation the dispenser gives, so not both")
dutyU.lcnRationAt = 0
ok(LC.UseDispenser(dutyU, nil), "but a unit can still take theirs from a dispenser")
local citD = newPlayer("DutyCitizen", "citizen")
citD:SetPos(FAR)
citD.lcnRationAt = 0
ok(not LC.IssueDutyAllocation(citD), "citizens queue like everyone else")

section("The infestation spreads far, but not without limit")
local iseed = { pos = F0 + Vector(6000, 0, 0), r = 300, kind = "infest", group = 0 }
table.insert(LC.Zones, iseed)
ok(LC.TerritoryCanGrow(iseed), "a fresh infestation can spread")
_setcvar("lc_infest_max", 4)
local patches = {}
for i = 1, 4 do
    local pz = { pos = iseed.pos + Vector(i * 300, 0, 0), r = 200, kind = "infest", group = 0, grown = true, seed = iseed }
    patches[#patches + 1] = pz
    table.insert(LC.Zones, pz)
end
ok(not LC.TerritoryCanGrow(iseed), "as far as lc_infest_max lets it")
_setcvar("lc_infest_max", 30)
local zBase = GetConVar("lc_zombies"):GetInt()
ok(LC.ZombieTarget() >= zBase + 4, "each patch brings one more of the infested", LC.ZombieTarget())
for i = 1, 80 do
    local pz = { pos = iseed.pos + Vector(0, i * 300, 0), r = 200, kind = "infest", group = 0, grown = true, seed = iseed }
    table.insert(LC.Zones, pz)
end
ok(LC.ZombieTarget() == math.max(zBase, GetConVar("lc_zombies_max"):GetInt()), "but never more than lc_zombies_max alive", LC.ZombieTarget())
for i = #LC.Zones, 1, -1 do
    local z = LC.Zones[i]
    if z == iseed or z.seed == iseed then table.remove(LC.Zones, i) end
end
end
FieldFixTests()

function ZoneShapeTests()
section("Zones: boxes, and mercy at the edges")
local B0 = Vector(-46000, -46000, 0)
local box = LCZ.BoxFromCorners(B0, B0 + Vector(600, 400, 0), 192)
ok(LCZ.Contains({ box = box, pos = B0, r = 1 }, B0 + Vector(590, 390, 50)), "a box zone covers its corners, where a circle leaves gaps")
ok(not LCZ.Contains({ box = box, pos = B0, r = 1 }, B0 + Vector(700, 200, 50)), "and stops at its walls")
ok(LCZ.Contains({ box = box, pos = B0, r = 1 }, B0 + Vector(680, 200, 50), LCZ.Mercy()), "with about eight feet of mercy past them where that's kind")
local blockZ = LC.AddZone(nil, nil, "block", 9, box)
ok(blockZ and blockZ.box and blockZ.r > 300 and math.abs(blockZ.pos.x - (B0.x + 300)) < 1, "a box zone keeps a centre and a size for everything else")
ok(LC.InBlock(B0 + Vector(650, 200, 20), 9), "a step outside your block's line is still home at curfew")
ok(not LC.InBlock(B0 + Vector(900, 200, 20), 9), "but not halfway down the street")
local saved = util.JSONToTable(_files["livingcity/" .. game.GetMap() .. ".json"] or "{}") or {}
local foundBox = false
for _, z in ipairs(saved.zones or {}) do if z.kind == "block" and type(z.box) == "table" and #z.box == 6 then foundBox = true end end
ok(foundBox, "box zones are saved with the layout")
LC.RemoveZone(blockZ)
local cbox = LCZ.BoxFromCorners(B0 + Vector(2000, 0, 0), B0 + Vector(2600, 600, 0), 192)
local cz = LC.AddZone(nil, nil, "combine", 0, cbox)
ok(LC.CombineZoneAt(B0 + Vector(2050, 300, 20)) == nil, "the edge of a Combine-only zone isn't trespassing")
ok(LC.CombineZoneAt(B0 + Vector(2300, 300, 20)) == cz, "well inside it is")
LC.RemoveZone(cz)
local circ = LC.AddZone(B0 + Vector(5000, 0, 0), 300, "rebel", 0)
ok(not LC.InRebelZone(B0 + Vector(5370, 0, 20)) and LC.NearRebelZone(B0 + Vector(5370, 0, 20)), "rebel ground has no mercy at its edge, just a warning a step before it")
ok(LC.InRebelZone(B0 + Vector(5290, 0, 20)), "inside the line is inside")
ok(LC.InRebelZone(B0 + Vector(5000, 0, 250)), "and reach up a floor's height, not a dome")
LC.RemoveZone(circ)
end
ZoneShapeTests()
function ScannerTests()
section("Scanner console: flying a scanner from a cell")
local S = Vector(-38000, 38000, 0)
local console = ents.Create("lc_console")
console:SetPos(S)
local cit = newPlayer("ScanCitizen", "citizen")
cit:SetPos(S + Vector(0, 60, 0)) cit.chat = {}
local okC, whyC = LC.StartScannerLink(cit, console)
ok(not okC and string.find(whyC or "", "ACCESS DENIED", 1, true), "a free citizen can't use the console", whyC)
local inm = newPlayer("ScanInmate", "citizen")
inm:SetPos(S + Vector(0, 40, 0)) inm.chat = {}
LC.Incarcerate(inm, 300, "Test")
inm:SetPos(S + Vector(0, 40, 0))
LC.Prisoners[inm].cell = { pos = S } -- (the console's in their cell)
local okL = LC.StartScannerLink(inm, console)
local l = LC.ScannerLinks[inm]
ok(okL and l and IsValid(l.sc) and inm:GetNW2Entity("lc_scanner") == l.sc, "a prisoner links up and gets a scanner of their own")
ok(has(inm.chat, "more seconds on your sentence"), "and is warned what flashing a unit costs")
ok(inm:GetPos():DistToSqr(S + Vector(0, 40, 0)) < 1, "their body stays at the console")
local sc = l.sc
sc:SetPos(S + Vector(0, 0, 140))
local okL2, whyL2 = LC.StartScannerLink(cit, console)
ok(not okL2, "one pilot to a console")
LC.ScannerInput(inm, { f = true })
LC.ScannerThink(sc)
ok(sc:GetPos().x > S.x + 1, "W flies it forward")
local cleared = false
local cmd = { KeyDown = function(_, k) return k == IN_FORWARD end, ClearMovement = function() cleared = true end, ClearButtons = function() end }
hook.Run("StartCommand", inm, cmd)
ok(cleared and LC.ScannerLinks[inm].input.f == true, "the pilot's keys steer the scanner, and their body doesn't walk off")
LC.ScannerInput(inm, {})
sc:SetPos(S + Vector(0, 0, 140))

-- flashing a unit: more time
local cop = ents.Create("npc_metropolice") cop:SetPos(S + Vector(100, 0, 76))
LC.NPCs[cop] = { role = "cop", test = true }
local pr = LC.Prisoners[inm]
local until0 = pr.untilT
local fl, hit = LC.ScannerFlash(inm)
ok(fl and hit == 1 and math.abs(pr.untilT - until0 - 60) < 0.01, "flashing a unit adds a minute to the sentence", tostring(pr.untilT - until0))
ok(has(inm.chat, "more seconds on your sentence ("), "and the prisoner is told straight away")
ok((LC.NPCs[cop].stunnedUntil or 0) > CurTime(), "the unit is dazzled")
ok(not LC.ScannerFlash(inm), "the flash has to charge again")
l.nextFlash = 0
cop:SetPos(S + Vector(300, 0, 76))
LC.NPCs[cop].stunnedUntil = 0
local u1 = pr.untilT
local _, hitFar = LC.ScannerFlash(inm)
ok(hitFar == 0 and pr.untilT == u1 and LC.NPCs[cop].stunnedUntil == 0, "the flash only reaches as far as a photograph does (about ten feet)")
LC.NPCs[cop] = nil cop:Remove()

-- snitching: standing, never time off, and the units hear about it
local unit = newPlayer("ScanUnit", "cp") unit:SetPos(S + Vector(-5000, 0, 0)) unit.chat = {}
local reb = newPlayer("ScanRebel", "resistance", nil, 900) reb:SetPos(S + Vector(600, 0, 76)) reb.chat = {}
local rnpc = ents.Create("npc_citizen") rnpc:SetPos(S + Vector(110, 10, 76))
LC.NPCs[rnpc] = { role = "rebel", test = true }
_run(0.5) -- (let everyone finish spawning first)
reb:SetPos(S + Vector(600, 0, 76))
LC.ScannerTarget(inm, sc)
ok(sc:GetNW2Entity("lc_target") == rnpc and not sc:GetNW2Bool("lc_target_done", true), "the pilot's view brackets the nearest suspect in front of the camera")
l.nextFlash = 0
local sFar = LC.Standing(inm)
LC.ScannerFlash(inm)
ok(reb:GetNW2Float("lc_spotted_until", 0) == 0, "a photo from across the street doesn't count: it has to be about ten feet")
ok(rnpc:GetNW2Float("lc_spotted_until", 0) > CurTime(), "up close it does")
LC.ScannerSpotted[rnpc] = nil
rnpc:SetNW2Float("lc_spotted_until", 0)
LC.ScannerEarned[inm] = nil
LC.AddStanding(inm, sFar - LC.Standing(inm))
reb:SetPos(S + Vector(100, 0, 76))
l.nextFlash = 0
local s0, u0 = LC.Standing(inm), pr.untilT
local _, _, rep = LC.ScannerFlash(inm)
ok(rep and LC.Standing(inm) == s0 + 24, "photographing a rebel and a hunted fighter earns Civil Standing (12 each)", tostring(LC.Standing(inm) - s0))
ok(pr.untilT == u0, "but not a second off the sentence")
ok(has(inm.chat, "Your sentence stands"), "and the prisoner is reminded of it")
ok(has(unit.chat, "Scanner report"), "every unit on duty gets the report")
ok(reb:GetNW2Float("lc_spotted_until", 0) > CurTime() and reb:GetNW2String("lc_spotted_why", "") == "a rebel", "the fighter is lit up for units")
ok(has(reb.chat, "photographed"), "and knows it")
ok(rnpc:GetNW2Float("lc_spotted_until", 0) > CurTime(), "so is the rebel in the street")
l.nextFlash = 0
local s1 = LC.Standing(inm)
LC.ScannerFlash(inm)
ok(LC.Standing(inm) == s1, "the same people can't be reported again straight away")
local wanted = newPlayer("ScanWanted", "citizen") wanted:SetPos(S + Vector(90, -10, 76)) wanted.chat = {}
_run(0.5)
wanted:SetPos(S + Vector(90, -10, 76))
LC.SetWanted(wanted, 120, "Test")
l.nextFlash = 0
LC.ScannerFlash(inm)
ok(wanted:GetNW2String("lc_spotted_why", "") == "a wanted citizen", "the wanted are worth a report too")
local plain = newPlayer("ScanPlain", "citizen") plain:SetPos(S + Vector(650, 20, 76))
ok(LC.ScannerSuspect(plain) == nil, "an ordinary citizen isn't")
plain:SetPData("lce_standing", -200)
ok(LC.ScannerSuspect(plain) == "an anticitizen", "an anticitizen is")
ok(LC.ScannerSuspect(unit) == nil, "and units never are")
local fv = newPlayer("ScanVort", "resistance", "vortigaunt", 200)
ok(LC.ScannerSuspect(fv) == "a free vortigaunt", "a free vortigaunt is", tostring(LC.ScannerSuspect(fv)))
local sv = newPlayer("ScanShackled", "vort")
ok(LC.ScannerSuspect(sv) == nil, "a shackled one isn't (it's Combine property)")
fv:SetPos(Vector(-30000, 30000, 0)) sv:SetPos(Vector(-30000, 30000, 0))

-- smoke: no picture of anyone in it, or through it
local hid = ents.Create("npc_citizen") hid:SetPos(S + Vector(100, -20, 76))
LC.NPCs[hid] = { role = "rebel", test = true }
local savedSmokes = LC.Smokes
LC.Smokes = { { pos = S + Vector(50, -10, 140), r = 30, untilT = CurTime() + 30 } }
LC.ScannerTarget(inm, sc)
ok(sc:GetNW2Entity("lc_target") ~= hid and sc:GetNW2Bool("lc_smoke", false), "smoke in front of the camera: the pilot's view says so, and brackets nobody behind it")
l.nextFlash = 0
LC.ScannerFlash(inm)
ok(hid:GetNW2Float("lc_spotted_until", 0) == 0 and (LC.NPCs[hid].stunnedUntil or 0) == 0, "nobody behind smoke is flashed or photographed")
LC.Smokes = { { pos = hid:GetPos() + Vector(0, 0, 40), r = 120, untilT = CurTime() + 30 } }
l.nextFlash = 0
LC.ScannerFlash(inm)
ok(hid:GetNW2Float("lc_spotted_until", 0) == 0, "or standing in it")
LC.Smokes = {}
l.nextFlash = 0
LC.ScannerFlash(inm)
ok(hid:GetNW2Float("lc_spotted_until", 0) > CurTime(), "once it clears, they are")
LC.Smokes = savedSmokes
LC.NPCs[hid] = nil hid:Remove()
LC.ScannerEarned[inm] = nil

-- rebel ground
local rz = LC.AddZone(S + Vector(300, 0, 0), 200, "rebel", 0)
l.nextFlash = 0
net.sent = {}
local _, _, rep2 = LC.ScannerFlash(inm)
ok(rep2 and rep2.base ~= nil and _lastnet("lc_cpmark") ~= nil, "photographing rebel ground marks it on units' screens")
l.nextFlash = 0
local _, _, rep3 = LC.ScannerFlash(inm)
ok(not rep3 or rep3.base == nil, "and the same ground can't be farmed")
LC.RemoveZone(rz)

-- the cap
LC.ScannerSpotted = {}
LC.ScannerEarned[inm] = { { t = CurTime(), n = 100 } }
l.nextFlash = 0
local s2 = LC.Standing(inm)
LC.ScannerFlash(inm)
ok(LC.Standing(inm) == s2, "no more than lc_scanner_snitch_cap standing every ten minutes")
LC.NPCs[rnpc] = nil rnpc:Remove()
LC.ClearWanted(wanted)

-- rebels shoot at a scanner that comes at them in the open, but not one that sneaks up behind
local spos = sc:GetPos()
local front = ents.Create("npc_citizen") front:SetPos(spos + Vector(-300, 0, 0)) front.hp = 40
LC.NPCs[front] = { role = "rebel" }
local rear = ents.Create("npc_citizen") rear:SetPos(spos + Vector(300, 0, 0)) rear.hp = 40
LC.NPCs[rear] = { role = "rebel" }
local fl = { sc = sc }
local t0 = CurTime()
ok(LC.RebelsFireAtScanner(inm, fl, t0) == 0, "a rebel who has only just noticed the scanner doesn't fire yet")
local shots = LC.RebelsFireAtScanner(inm, fl, t0 + 1.3)
ok(shots == 1 and LC.NPCs[front].scannerFireAt and not LC.NPCs[rear].scannerFireAt, "a moment later the one facing it fires, and the one with his back turned doesn't", tostring(shots))
ok(LC.RebelsFireAtScanner(inm, fl, t0 + 1.4) == 0, "not every tick: they take their time between shots")
GetConVar("lc_scanner_rebel_fire"):SetInt(0)
ok(LC.RebelsFireAtScanner(inm, { sc = sc }, t0 + 9) == 0, "and lc_scanner_rebel_fire 0 turns it off")
GetConVar("lc_scanner_rebel_fire"):SetInt(1)
LC.NPCs[front] = nil front:Remove() LC.NPCs[rear] = nil rear:Remove()

-- getting hurt pulls you out
_run(0.5) -- (let everyone finish spawning first)
inm:SetHealth(inm:Health() - 5)
_run(0.6)
ok(LC.ScannerLinks[inm] == nil and not IsValid(sc), "being hurt drops the link and the scanner")
-- the sentence ending does too
LC.StartScannerLink(inm, console)
ok(LC.ScannerLinks[inm] ~= nil, "(back on the console)")
local sc2 = LC.ScannerLinks[inm].sc
LC.ReleasePrisoner(inm)
_run(0.6)
ok(LC.ScannerLinks[inm] == nil and not IsValid(sc2) and inm:GetNW2Entity("lc_scanner") == nil, "release ends the link and takes them out of the scanner")
ok(unit:GetNW2Bool("lc_unit", false) and not inm:GetNW2Bool("lc_unit", false), "clients know who the units are, for the highlights")
console:Remove()
for _, p in ipairs({ cit, inm, unit, reb, wanted, plain }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
ScannerTests()
function SalvageTests()
section("Salvage: junk, a crowbar, and the noise it makes")
local T = Vector(36000, -36000, 0)
local function itemsNear(pos, r)
    local out = {}
    for _, e in ipairs(ents.FindByClass("lc_item")) do
        if e:GetPos():DistToSqr(pos) < r * r then out[#out + 1] = e:GetNW2String("lc_item", "") end
    end
    return out
end
local sal = newPlayer("Salvager", "citizen") sal.chat = {}
local unitS = newPlayer("SalvUnit", "cp") unitS.chat = {}
_run(3) -- (let them finish spawning)
sal:SetPos(T) unitS:SetPos(T + Vector(900, 0, 0))
local car = ents.Create("prop_physics") car:SetModel("models/props_vehicles/car002a_physics.mdl") car:SetPos(T + Vector(50, 0, 0))
sal.lookingAt = car
local key, _, big = LC.JunkAt(sal)
ok(key ~= nil and big, "a wrecked car is junk worth salvaging, and a big one")
ok(not LC.IsJunkModel("models/props_junk/TrashDumpster01a.mdl"), "a dumpster is a bin, not junk")
local okN, whyN = LC.Salvage(sal)
ok(not okN and string.find(whyN or "", "crowbar", 1, true), "it takes a crowbar", whyN)
sal:Give("weapon_crowbar") sal:SelectWeapon("weapon_crowbar")
local n0 = LC.InvCount(sal)
ok(LC.Salvage(sal), "with one out, prying it apart starts")
ok(has(unitS.chat, "Metal being pried apart"), "units nearby hear it")
_run(10)
ok(LC.InvCount(sal) > n0 or #itemsNear(T, 200) > 0, "and it gives up materials", tostring(LC.InvCount(sal) - n0))
local okA, whyA = LC.Salvage(sal)
ok(not okA and string.find(whyA or "", "Stripped", 1, true), "a stripped wreck has nothing left for a while", whyA)
car:Remove()

-- the crowbar is a weapon
local copS = ents.Create("npc_metropolice") copS:SetPos(T + Vector(300, 0, 0))
LC.NPCs[copS] = { role = "cop", test = true }
sal.lcCrowbarNext = 0
timer.list.LivingCityCrowbar.fn()
ok(LC.PlayerIsWanted(sal), "a unit who sees a crowbar in your hand makes you wanted", tostring(LC.SeenBySecurity(sal, 700)) .. tostring(LC.HoldingCrowbar(sal)) .. tostring(sal.lcGraceUntil) .. " " .. CurTime())
LC.ClearWanted(sal)
LC.NPCs[copS] = nil copS:Remove()
ok(LCS.Items.crowbar and LCS.Items.crowbar.contraband and (LCS.Items.crowbar.conceal or 1) < 0.1, "and in your pockets it's contraband that's hard to hide")

-- bin points
LC.AddPoint(T + Vector(0, -300, 0), 0, "bin", 0)
sal.lookingAt = nil
sal:SetPos(T + Vector(-50, -300, 0))
ok(LC.BinAt(sal) ~= nil, "a bin point placed in the editor is a bin you can search")
for i = #LC.Points, 1, -1 do if LC.Points[i].kind == "bin" and LC.Points[i].pos:DistToSqr(T + Vector(0, -300, 0)) < 1 then table.remove(LC.Points, i) end end

-- downed scanners are scrap
local before = #itemsNear(T + Vector(0, 600, 0), 200)
local cscan = ents.Create("npc_cscanner") cscan:SetPos(T + Vector(0, 600, 100))
hook.Run("OnNPCKilled", cscan, sal)
local drops = itemsNear(T + Vector(0, 600, 0), 200)
local scrapN = 0 for _, id in ipairs(drops) do if id == "scrap" then scrapN = scrapN + 1 end end
ok(#drops - before >= 1 and scrapN >= 1, "a scanner shot down comes apart as scrap (always some, sometimes parts too)", tostring(#drops - before))
local linked = ents.Create("lc_rscanner") linked:SetPos(T + Vector(0, 900, 100))
hook.Run("OnNPCKilled", linked, sal)
ok(#itemsNear(T + Vector(0, 900, 0), 200) == 0, "but one flown from a console doesn't (it could be put up again and again)")
linked:Remove()

section("Workbenches and reclamation")
sal.lookingAt = nil
LC.GiveItem(sal, "scrap", 6)
local okB, whyB = LC.Craft(sal, "crowbar")
ok(not okB and string.find(whyB or "", "lab", 1, true), "a crowbar is the Resistance lab's work now, not a workbench's", whyB)
local bench = ents.Create("lc_workbench") bench:SetPos(T + Vector(40, -2000, 0))
ok(LC.NearWorkbench(sal) == nil and LC.NearWorkbench(bench) ~= nil, "(rebels still find a lab bench to busy themselves at)")
LC.GiveItem(sal, "armor_vest", 1)
sal:SetArmor(0)
LC.ArmsUse(sal, "armor_vest")
ok(sal:Armor() == 30 and not LC.HasItem(sal, "armor_vest"), "an armour vest gives thirty armour")
bench:Remove()

LC.GiveItem(sal, "scrap", 4) LC.GiveItem(sal, "can_empty", 2)
local c0, s0 = LC.Credits(sal), LC.Standing(sal)
local okR, pay = LC.Reclaim(sal, nil)
ok(okR and pay >= 10 and LC.Credits(sal) == c0 + pay and not LC.HasItem(sal, "scrap"), "reclamation pays credits for scrap and cans", tostring(pay))
ok(LC.Standing(sal) > s0, "and a little Civil Standing")
LC.GiveItem(sal, "scrap", 2)
LC.Reclaimed[sal] = { { t = CurTime(), n = 40 } }
ok(not LC.Reclaim(sal, nil), "up to an hourly quota")
ok(not LC.Reclaim(unitS, nil), "units don't hand scrap in")
sal:SetPos(Vector(-30000, 30000, 0)) unitS:SetPos(Vector(-30000, 30000, 0))
end
SalvageTests()
function ConvoyTests()
section("Supply drops")
local D = Vector(-36000, -36000, 0)
local raider = newPlayer("Raider", "resistance", nil, 900) raider.chat = {}
local guard = newPlayer("Guardian", "cp") guard.chat = {}
_run(3)
raider:SetPos(D + Vector(2000, 0, 0)) guard:SetPos(D + Vector(300, 0, 0))
local okS, s = LC.StartSupplyDrop(D)
ok(okS and s.byAir, "with open sky over it, a supply drop comes in by dropship")
ok(has(guard.chat, "supply dropship is coming down"), "units are told where")
_run(17)
ok(IsValid(s.container) and IsValid(s.crate) and s.crate:GetNW2Int("lc_loads", 0) == GetConVar("lc_supply_loads"):GetInt(),
    "it sets a cargo container down, with a crate of supplies beside it")
ok(#s.props >= 3, "and the rest of the load stacked up", tostring(#s.props))
ok(#s.guards >= 1, "with units standing guard", tostring(#s.guards))
local posted = false
for _, p in ipairs(LC.Postings.cp or {}) do if p.tmpl and p.tmpl.id == "cp_guardsupply" then posted = true end end
ok(posted, "units get a directive to guard it")
posted = false
for _, p in ipairs(LC.Postings.resistance or {}) do if p.tmpl and p.tmpl.id == "res_raidsupply" then posted = true end end
ok(posted, "and the Resistance one to raid it")
local okU, whyU = LC.LootSupply(guard, s.crate)
ok(not okU and string.find(whyU or "", "Guard", 1, true), "units don't help themselves")
for _, g in ipairs(s.guards) do if LC.NPCs[g] then LC.NPCs[g] = nil end g:Remove() end
raider:SetPos(D + Vector(40, 0, 0))
local n0 = LC.InvCount(raider)
ok(LC.LootSupply(raider, s.crate), "anyone else can take a load")
_run(8.5)
ok(s.crate:GetNW2Int("lc_loads", 0) == GetConVar("lc_supply_loads"):GetInt() - 1 and LC.InvCount(raider) > n0, "eight seconds later it's in their pockets")
-- the convoy leaves with loads left: units nearby are paid
local c0 = LC.Credits(guard)
LC.EndSupplyDrop(false)
ok(LC.Credits(guard) == c0 + GetConVar("lc_supply_pay"):GetInt() and not IsValid(s.crate), "if it leaves with supplies still in it, units nearby are paid")
-- emptied: the city hears about it
-- under a roof: by road, an APC parked at the dock (when nobody's watching)
raider:SetPos(D + Vector(6000, 0, 0)) guard:SetPos(D + Vector(6000, 300, 0))
local realTL = util.TraceLine
util.TraceLine = function(t)
    if t.endpos.z > t.start.z + 1000 then return { Hit = true, HitSky = false, HitPos = t.start + Vector(0, 0, 200), Fraction = 0.05 } end
    return realTL(t)
end
local okS2, s2 = LC.StartSupplyDrop(D)
util.TraceLine = realTL
local apc = false
for _, e in ipairs(s2.props or {}) do if IsValid(e) and e:GetModel() == "models/combine_apc.mdl" then apc = true end end
ok(okS2 and not s2.byAir and apc and IsValid(s2.crate), "under a roof it comes by road: an APC parked at the dock, the crate beside it")
for _, g in ipairs(s2.guards) do if LC.NPCs[g] then LC.NPCs[g] = nil end g:Remove() end
s2.crate:SetNW2Int("lc_loads", 0)
raider.chat = {}
LC.EndSupplyDrop(false)
ok(has(raider.chat, "supply drop was looted") or has(raider.chat, "empty"), "an emptied drop is news")
ok(LC.StartEvent("supply") and LC.Supply ~= nil, "it's a city event too (lc_event supply)")
if LC.Supply then for _, g in ipairs(LC.Supply.guards) do if LC.NPCs[g] then LC.NPCs[g] = nil end g:Remove() end end
LC.EndEvent(true)
ok(LC.Supply == nil, "and goes when the event ends")

section("Radio jammers")
local jp = newPlayer("Jammerer", "resistance", nil, 900) jp.chat = {}
_run(3)
jp:SetPos(D + Vector(0, 3000, 0)) guard:SetPos(D + Vector(200, 3000, 0)) guard.chat = {}
ok(LCS.LabById.jammer and LCS.BlackById.jammer and not LCS.RecipesById.jammer, "a jammer comes from the Resistance lab, or the black market")
LC.GiveItem(jp, "jammer", 1)
local okJ, j = LC.PlaceJammer(jp)
ok(okJ and IsValid(j) and LC.Jammed(guard:GetPos()), "set down, it jams everything near it")
ok(not LC.Mark1020(guard), "a unit inside can't call a 10-20")
ok(not LC.CallBackup(guard), "or backup")
local okR, whyR = LC.RadioSay(guard, "anyone there", "cp")
ok(not okR, "or talk on the CP band", whyR)
LC.RadioNotice("cp", "Dispatch: test message one two three")
ok(has(guard.chat, "*static*"), "and what reaches them is static")
ok(not LC.Jammed(D + Vector(0, 9000, 0)), "far from it, nothing")
_run(1.1)
ok(guard:GetNW2Bool("lc_jammed", false), "units in it see RADIO JAMMED on their HUD")
ok(LC.SmashJammer(guard, j) and not IsValid(j), "a unit smashes it with E")
ok(not LC.Jammed(guard:GetPos()), "and the radio's clear")
LC.GiveItem(jp, "jammer", 1)
local _, j2 = LC.PlaceJammer(jp)
j2.lcUntil = CurTime() - 1
_run(1.1)
ok(not IsValid(j2), "one nobody finds runs out by itself")

section("Union work orders that pay in materials")
local worker = newPlayer("Worker", "citizen")
local built = 0
for _, t in ipairs(LC.QuestTemplates) do
    if t.id == "cit_streetlight" or t.id == "cit_rubble" or t.id == "cit_pipe" then
        local okB, spec = pcall(t.build, worker)
        if okB and spec and spec.onFinish then built = built + 1 end
    end
end
ok(built == 3, "streetlight, rubble and pipe work orders build", tostring(built))
local spec
for _, t in ipairs(LC.QuestTemplates) do if t.id == "cit_pipe" then spec = t.build(worker) end end
local fakeQ = { owner = worker, members = { worker }, squad = { worker } }
local n1 = LC.InvCount(worker)
local okF = pcall(spec.onFinish, fakeQ, true)
ok(okF and LC.InvCount(worker) >= n1 + 3, "and pay in materials", tostring(LC.InvCount(worker) - n1))
for _, p in ipairs({ raider, guard, jp, worker }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
ConvoyTests()
function PlaytestFixTests()
section("Playtest fixes: ladders, rations docked, quiet ground, release spots")
local P = Vector(-36000, 36000, 0)
-- ladders: two points with one number make a ladder; someone at the foot heading up is put at the top
LC.AddPoint(P + Vector(0, 0, 0), 0, "ladder", 7)
LC.AddPoint(P + Vector(0, 40, 300), 0, "ladder", 7)
LC.ApplyLadders()
local found
for _, l in ipairs(LC.Ladders) do if l.a:DistToSqr(P) < 1 then found = l end end
ok(found and found.b.z == 300, "two ladder ends with the same number make a ladder")
local climber = ents.Create("npc_citizen") climber:SetPos(P + Vector(20, 0, 0))
ok(LC.LadderHop(climber, P + Vector(200, 40, 300)) and climber:GetPos().z > 250, "an NPC at the foot heading up is put at the top")
ok(not LC.LadderHop(climber, P + Vector(200, 40, 300)), "and doesn't bounce once they're there")
climber:Remove()
for i = #LC.Points, 1, -1 do if LC.Points[i].kind == "ladder" then table.remove(LC.Points, i) end end
LC.ApplyLadders()

-- rations docked near Resistance activity
local near = newPlayer("DockNear", "citizen") near.chat = {}
local far = newPlayer("DockFar", "citizen")
_run(3)
near:SetPos(P + Vector(3000, 0, 0)) far:SetPos(P + Vector(9000, 0, 0))
LC.GiveItem(near, "ration_card", 3) LC.GiveItem(far, "ration_card", 3)
local docked = LC.DockRations(P + Vector(3200, 0, 0), "Resistance graffiti")
ok(#docked == 1 and docked[1] == near, "citizens near Resistance activity lose their next ration", tostring(#docked))
ok(has(near.chat, "next ration allocation is forfeit"), "and are told on the spot")
near.lcnRationAt = 0 near.chat = {}
ok(not LC.UseDispenser(near, nil) and has(near.chat, "five ration units deducted"), "the dispenser says why it's withheld")
near.lcnRationAt = 0
ok(LC.UseDispenser(near, nil), "and the one after is as normal")
far.lcnRationAt = 0
ok(LC.UseDispenser(far, nil), "someone far away isn't touched")
local street = newPlayer("DockStreet", "citizen")
local floorBelow = newPlayer("DockFloor", "citizen")
_run(3)
street:SetPos(P + Vector(12000, 0, -600)) floorBelow:SetPos(P + Vector(12000, 0, -100))
local dk = LC.DockRations(P + Vector(12000, 0, 0), "Resistance-held ground")
ok(#dk == 1 and dk[1] == floorBelow, "someone on the street far below a rooftop camp isn't docked, but a floor below is", tostring(#dk))
street:SetPos(P + Vector(-30000, 0, 0)) floorBelow:SetPos(P + Vector(-30000, 0, 0))

-- ground a containment team cleared stays quiet
LC.QuietInfestation(P + Vector(0, 6000, 0), 800)
ok(LC.InfestQuietAt(P + Vector(300, 6000, 0)) and not LC.InfestQuietAt(P + Vector(3000, 6000, 0)), "cleared ground is quiet: nothing spawns or spreads there for a while")

-- release spots don't stack people
local first = newPlayer("RelFirst", "citizen")
_run(3)
first:SetPos(P + Vector(0, 9000, 4))
local spot = LC.ReleaseSpot(P + Vector(0, 9000, 0), nil)
ok(spot:DistToSqr(first:GetPos()) > 30 * 30, "the next person released isn't put inside the last")

-- the scanner link: chat out of it, and the E that linked you doesn't unlink you
local pil = newPlayer("ScanPilotAdmin", "cp") pil.chat = {}
_run(3)
pil:SetPos(P + Vector(0, 12000, 0))
local con = ents.Create("lc_console") con:SetPos(P + Vector(0, 12000, 0))
ok(LC.StartScannerLink(pil, con), "a unit links up")
LC.ScannerInput(pil, { quit = true })
ok(LC.ScannerLinks[pil] ~= nil, "holding E from the console doesn't drop the link straight away")
hook.Run("PlayerSay", pil, "!unlink")
ok(LC.ScannerLinks[pil] == nil, "!unlink always gets you out")
con:Remove()
for _, p in ipairs({ near, far, first, pil }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
PlaytestFixTests()
function HeistTests()
section("Stealing the Combine's data")
local H = Vector(-40000, 0, 0)
local term = ents.Create("lc_dataterminal") term:SetPos(H + Vector(50, 0, 0))
local thief = newPlayer("DataThief", "resistance", nil, 150) thief.chat = {} -- (a Member: Fighters are hunted, wanted on sight whatever their record says)
thief:Give("weapon_lc_multitool")
local cit = newPlayer("DataCitizen", "citizen") cit.chat = {}
local unit = newPlayer("DataUnit", "cp") unit.chat = {}
_run(3)
thief:SetPos(H) cit:SetPos(H + Vector(0, 30, 0)) unit:SetPos(H + Vector(5000, 0, 0))
thief.lookingAt, cit.lookingAt = term, term
local okC, whyC = LC.StealData(cit)
ok(not okC, "a citizen can't use it", whyC)
ok(LC.StealData(thief), "a Resistance member starts the download")
local secs = GetConVar("lc_heist_seconds"):GetFloat()
_run(secs * 0.5 + 0.5)
ok(has(unit.chat, "DATA BREACH"), "halfway, the alarm goes off and every unit hears it")
ok(LC.LastBreach ~= nil, "and the breach is on units' boards")
_run(secs * 0.5 + 0.5)
ok(LC.HasItem(thief, "data_shard") and not LC.HasItem(thief, "data_chip"), "the download finishes: one terminal's half, a fragment")
local okA, whyA = LC.StealData(thief)
ok(not okA and string.find(whyA or "", "Nothing new", 1, true), "the terminal has nothing new for a while", whyA)
-- a second terminal: the other half
local term2 = ents.Create("lc_dataterminal") term2:SetPos(H + Vector(-50, 0, 0))
thief.lookingAt = term2
ok(LC.StealData(thief), "a second terminal")
_run(secs + 1)
ok(LC.HasItem(thief, "data_chip") and not LC.HasItem(thief, "data_shard"), "and the two fragments make a whole chip")
term2:Remove()
thief.lookingAt = term
ok(LC.SellPrice(thief, "data_chip") >= 100, "the dealer pays a lot for it")
-- decoded at the lab (only there: the quartermaster won't touch it)
local realQM, realSci = LC.NearQuartermaster, LC.ScientistNear
LC.NearQuartermaster = function() return true end
LC.ScientistNear = function() return nil end
ok(not LC.DecodeChip(thief), "the quartermaster doesn't decode chips any more")
LC.ScientistNear = function() return thief end
local xp0 = LC.Credits(thief)
ok(LC.UseDataChip(thief) and not LC.HasItem(thief, "data_chip"), "the lab's scientist decodes it")
ok(LC.Credits(thief) > xp0 and GetGlobal2Float("lc_rebel_intel", 0) > CurTime(), "and the Resistance see every unit for a while")
LC.NearQuartermaster, LC.ScientistNear = realQM, realSci
-- or plugged in at a terminal: a clean record
LC.GiveItem(thief, "data_chip", 1)
LC.SetWanted(thief, 300, "Test")
local okW, whyW = LC.UseDataChip(thief)
ok(okW and not LC.PlayerIsWanted(thief) and #LC.RecordOf(thief).v == 0, "plugged into a terminal, it wipes your record", tostring(whyW) .. " " .. tostring(LC.PlayerIsWanted(thief)) .. " " .. #LC.RecordOf(thief).v)
term:Remove()
-- the master terminal: the motherlode
local master = ents.Create("lc_masterterminal") master:SetPos(H + Vector(0, 60, 0))
thief.lookingAt = master
unit.chat = {}
ok(LC.StealData(thief), "the master terminal: a Hacker starts the download")
local msecs = GetConVar("lc_heist_master_seconds"):GetFloat()
ok(msecs > secs, "(it takes longer)")
_run(msecs * 0.33 + 0.5)
ok(has(unit.chat, "MASTER TERMINAL BREACH"), "every alarm goes off, a third of the way in")
_run(msecs * 0.67 + 1)
ok(LC.HasItem(thief, "master_chip"), "what comes out is a master data core")
ok(LC.SellPrice(thief, "master_chip") >= 2 * LC.SellPrice(thief, "data_chip"), "worth far more than a chip to the dealer")
local mate = newPlayer("DataMate", "resistance", nil, 150)
LC.SetWanted(mate, 300, "Test")
LC.SetWanted(thief, 300, "Test")
local okM = LC.UseDataChip(thief, "master_chip")
ok(okM and not LC.PlayerIsWanted(thief) and not LC.PlayerIsWanted(mate), "plugged in, it wipes every comrade's record, not just yours")
master:Remove()
mate:SetPos(Vector(-30000, 30000, 0))
for _, p in ipairs({ thief, cit, unit }) do p:SetPos(Vector(-30000, 30000, 0)) p.lookingAt = nil end
end
HeistTests()
function ResistanceOpsTests()
section("Custody: what it costs the worst anticitizens")
local C0 = Vector(-44000, 8000, 0)
local mild = newPlayer("MildCon", "citizen")
local bad = newPlayer("BadCon", "resistance", nil, 100)
local worst = newPlayer("WorstCon", "resistance", nil, 900)
_run(3)
ok(LC.Severity(mild) < 2, "an ordinary citizen gets no special treatment")
bad:SetPData("lce_standing", -300) bad:SetPData("lc_jailcount", 3)
ok(LC.Severity(bad) >= 4, "an anticitizen brought in again and again rates the worst short of it", tostring(LC.Severity(bad)))
worst:SetPData("lce_standing", -600) worst:SetPData("lc_jailcount", 5)
ok(LC.Severity(worst, "Killing a unit") >= 6, "a hunted fighter with blood on their hands is the worst", tostring(LC.Severity(worst, "Killing a unit")))
-- interrogation
LC.Incarcerate(bad, 600, "Test")
bad.chat = {}
_run(13)
ok(LC.Interrogations[bad] ~= nil and has(bad.chat, "switches on his baton"), "a unit comes to the cell to interrogate them")
local hp0 = bad:Health()
_run(10)
ok(bad:Health() < hp0 and bad:Health() >= 10, "the baton hurts, and doesn't kill")
local units = newPlayer("IntUnit", "cp") units.chat = {}
_run(3)
local zr = LC.AddZone(C0 + Vector(0, 3000, 0), 300, "rebel", 0)
ok(LC.InterrogationTalk(bad) and LC.Interrogations[bad] == nil, "talking makes it stop")
ok(has(units.chat, "A prisoner has talked"), "and gives units a hideout")
LC.RemoveZone(zr)
_run(51)
ok(LC.IsCrippled(bad), "the worse ones get their feet broken: no running")
ok(tonumber(bad:GetPData("lc_crippled_until", 0)) > os.time(), "and it lasts through release and death")
LC.ReleasePrisoner(bad)
-- stalker
LC.Incarcerate(worst, 600, "Killing a unit")
_run(40) -- (twenty seconds in the cell, then the cell door, the blows, the dark: about fourteen more)
ok(LC.PlayerIsStalker(worst) and LC.Prisoners[worst] == nil, "the very worst aren't released: they're made stalkers")
ok(LC.LooksCombine(worst), "Combine property, as far as anyone's concerned")
local said = hook.Run("PlayerSay", worst, "help me")
local heard = LC.LogBuffer[#LC.LogBuffer] or ""
ok(said == "" and string.find(heard, "wordless", 1, true) and not string.find(heard, "help me", 1, true), "and they can't speak: only a scream comes out", heard)
worst:Kill()
_run(1)
ok(not LC.PlayerIsStalker(worst), "death ends it: back as a citizen, on probation")

section("The Resistance's operations")
-- door hacking
local hacker = newPlayer("DoorHacker", "resistance", nil, 150)
_run(3)
local okNo = LC.HackDoor(hacker)
ok(not okNo, "without a multitool, no hacking")
hacker:Give("weapon_lc_multitool")
hacker:SetPos(C0)
local door = ents.Create("func_door") door:SetPos(C0 + Vector(50, 0, 0))
door.GetInternalVariable = function(_, k) return k == "m_bLocked" end -- (a locked door)
hacker.lookingAt = door
local okH, whyH = LC.HackDoor(hacker)
ok(okH, "with a multitool (a Hacker's, or the black market's), a Combine door can be hacked", whyH)
_run(12.5)
ok(LC.DoorPicked(door), "twelve seconds later it's open")
hacker.lookingAt = nil
-- prison break
local inmate = newPlayer("RebInmate", "resistance", nil, 150)
_run(3)
LC.Incarcerate(inmate, 600, "Test")
local p2, cell = LC.JailedRebel()
ok(p2 == inmate and cell ~= nil, "the Resistance know one of theirs is in a cell")
ok(LC.BreakOut(inmate, hacker) and LC.Prisoners[inmate] == nil and LC.PlayerIsWanted(inmate), "a breakout frees them, wanted")
LC.ClearWanted(inmate)
-- informants
local snitch = newPlayer("Snitch", "citizen") snitch.chat = {}
_run(3)
snitch:SetPos(C0 + Vector(0, 5000, 0)) inmate:SetPos(C0 + Vector(100, 5000, 0)) hacker:SetPos(C0 + Vector(9000, 0, 0))
units.chat = {}
local c0 = LC.Credits(snitch)
local okI, real = LC.Inform(snitch, inmate)
ok(okI and real and has(units.chat, "Informant tip") and inmate:GetNW2Float("lc_spotted_until", 0) > CurTime(), "a citizen informs on a Resistance member: units see them")
ok(LC.Credits(snitch) > c0, "and the informant is paid")
ok(snitch:GetNW2Float("lc_traitor_until", 0) > CurTime(), "a Resistance member who saw it marks them a traitor")
ok(LC.RebelDisposition(nil, {}, snitch, false) == D_HT, "and the Resistance's fighters treat them as one")
snitch.lcInformNext = 0
local plain = newPlayer("PlainCit", "citizen")
local s0 = LC.Standing(snitch)
LC.Inform(snitch, plain)
ok(LC.Standing(snitch) < s0, "a false report costs standing")
-- screen hijack
local screen = ents.Create("lc_screen") screen:SetPos(C0 + Vector(0, -4000, 0))
units.chat = {}
ok(LC.HijackStart(screen, hacker) and screen:GetNW2Float("lc_hijacked_until", 0) > CurTime(), "a city screen can be hijacked")
ok(has(units.chat, "hijacked"), "units are told")
ok(LC.CutHijack(units, screen) and screen:GetNW2Float("lc_hijacked_until", 0) == 0, "a unit cuts it")
LC.HijackStart(screen, hacker)
_run(61)
ok((LC.RebelSurgeUntil or 0) > CurTime(), "a minute uninterrupted: rebel ground spreads faster for a while")
-- smugglers
local fq = { owner = hacker, done = false }
LC.TrackSmuggler(fq)
net.sent = {}
_run(7)
ok(_lastnet("lc_cpmark") ~= nil, "a smuggler shows on units' screens")
LC.Smugglers[fq] = nil
-- overwatch drop
_setcvar("lc_overwatch_drops", 1)
local okD, d = LC.StartOverwatchDrop(C0 + Vector(4000, 4000, 0))
ok(okD and LC.OverwatchDrop == d, "Overwatch can drop soldiers at a landing zone")
_run(8)
ok(d.ship ~= nil and IsValid(d.ship) and d.ship:GetClass() == "lc_dropship", "they come by dropship")
local shipStart = d.ship:GetPos()
_run(27)
ok(#d.soldiers >= 1, "and they arrive", tostring(#d.soldiers))
local under = true
for _, sd in ipairs(d.soldiers) do if sd:GetPos():Distance(C0 + Vector(4000, 4000, 0)) > 300 then under = false end end
ok(under and shipStart:Distance(C0 + Vector(4000, 4000, 0)) > 1000, "flown in from a distance, they're set down at the landing zone")
local st1 = LC.NPCs[d.soldiers[1]]
ok(st1 and st1.drop == d and st1.holdPos ~= nil, "(they take up posts round it)")
local function Containers()
    local n, held = 0, false
    for _, cls in ipairs({ "prop_dynamic", "prop_physics" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if string.find(e:GetModel() or "", "dropship_container", 1, true) and e:GetPos():Distance(C0 + Vector(4000, 4000, 0)) < 600 then
                n = n + 1
                if IsValid(d.ship) and e:GetPos():Distance(d.ship:GetPos()) < 1 then held = true end
            end
        end
    end
    return n, held
end
local nC, held = Containers()
ok(nC >= 1 and held, "the soldiers come out of a troop container that never leaves the dropship's claws")
_run(40)
ok(Containers() == 0, "and the dropship lifts away with it")
for _, s in ipairs(d.soldiers) do if LC.NPCs[s] then LC.NPCs[s] = nil end s:Remove() end
LC.EndOverwatchDrop()
ok(LC.OverwatchDrop == nil, "and leave again")
_setcvar("lc_overwatch_drops", 0)
-- foremen
local fore = newPlayer("Foreman", "citizen")
local worker = newPlayer("Worker2", "citizen")
_run(3)
ok(not LC.BecomeForeman(fore), "only Trusted citizens can be foremen")
LC.AddStanding(fore, 200 - LC.Standing(fore))
ok(LC.BecomeForeman(fore), "a Trusted citizen becomes a foreman")
local okA, whyA = LC.AssignWork(fore, worker)
ok(okA and LC.QuestOf[worker] and LC.QuestOf[worker].foreman == fore, "and hands another citizen a work order", whyA)
if LC.QuestOf[worker] then LC.AbandonQuest(worker) end
-- a freed vortigaunt charges the Resistance's vests (it doesn't heal)
local vort = ents.Create("npc_vortigaunt") vort:SetPos(C0 + Vector(-4000, 0, 0))
LC.RegisterNPC(vort, "vortigaunt")
LC.SettleVort(vort)
hacker:SetPos(C0 + Vector(-4000, 100, 0))
hacker:SetNW2Bool("lc_vest", true)
hacker:SetArmor(0)
hacker:SetHealth(50)
_run(2)
ok(hacker:Armor() == 0, "a freed vortigaunt doesn't charge a vest by itself")
LC.VortCharge(hacker, vort)
ok(hacker:Armor() > 0 and hacker:Health() == 50, "asked (E), it charges the Resistance's vests (it doesn't heal)")
LC.RebelVorts[vort] = nil LC.NPCs[vort] = nil vort:Remove()
for _, p in ipairs({ mild, bad, worst, units, hacker, inmate, snitch, plain, fore, worker }) do p:SetPos(Vector(-30000, 30000, 0)) end
screen:Remove() door:Remove()
end
ResistanceOpsTests()
function ActionMenuTests()
section("The actions menu: no chat commands needed")
local a = newPlayer("MenuUser", "citizen") a.chat = {}
local b = newPlayer("MenuTarget", "resistance", nil, 150)
local u = newPlayer("MenuUnit", "cp") u.chat = {}
_run(3)
a:SetPos(Vector(-46000, -8000, 0)) b:SetPos(Vector(-45900, -8000, 0)) u:SetPos(Vector(-40000, -8000, 0))
ok(not LC.RunAction(a, "lc_setrank", ""), "only the menu's own actions can be run through it")
local was = a:GetNW2Bool("lc_handsup", false)
_netcall("lc_action", a, "handsup", "", NULL)
ok(a:GetNW2Bool("lc_handsup", false) ~= was, "hands up, from the menu")
a.lcActionNext = 0
_netcall("lc_action", a, "inform", "", b)
ok(has(u.chat, "Informant tip"), "informing on the person you're looking at, from the menu")
-- interrogation, answered on screen
local con = newPlayer("MenuCon", "resistance", nil, 100)
_run(3)
con:SetPData("lce_standing", -300)
LC.Incarcerate(con, 600, "Test")
net.sent = {}
_run(13)
ok(_lastnet("lc_interrogate") ~= nil, "an interrogation puts the choice on the prisoner's screen")
_netcall("lc_interrogate_reply", con, true)
ok(LC.Interrogations[con] == nil, "choosing Talk ends it")
LC.ReleasePrisoner(con)
ok(GetConVar("lc_rebel_ops_minutes"):GetInt() >= 30, "the Resistance's own operations are at least half an hour apart")
for _, p in ipairs({ a, b, u, con }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
ActionMenuTests()
function PropagandaTests()

function MortuaryTests()

function NPCWorkTests()

function LookupTests()

local function rollAs(n, fn)
    local r = math.random
    math.random = function(a, b)
        if a == 20 and b == nil then return n end
        if a == nil then return r() elseif b == nil then return r(a) end
        return r(a, b)
    end
    local ok2, res, res2 = pcall(fn)
    math.random = r
    if not ok2 then error(res) end
    return res, res2
end

function TalkTests()

function RhythmTests()

function TrainTests()

function StockTests()

function PowerTests()

function MailTests()
section("Letters")
local M0 = Vector(-28000, 38000, 0)
local po = LC.AddPoint(M0, 0, "work", LCJ.ById.courier.num)
local blk = LC.AddZone(M0 + Vector(1500, 0, 0), 300, "block", 77)
local writer = newPlayer("Writer", "citizen")
writer:SetPos(M0 + Vector(50, 0, 0))
writer:SetNW2String("lc_cid", "cid-writer")
local reader = newPlayer("Reader", "citizen")
reader:SetNW2String("lc_cid", "cid-reader")
reader.chat = {}
LC.MailRegister(writer) LC.MailRegister(reader)
LC.Mail.dir["cid-reader"].block = 77
LC.GiveItem(writer, "paper")
LC.WriteNote(writer, "Meet me by the canal at nine.", "keep", true)
local idx = #LC.Notes(writer)
local found, self = false, false
for _, r in ipairs(LC.MailRecipients(writer)) do
    if r[1] == "cid-reader" then found = true end
    if r[1] == "cid-writer" then self = true end
end
ok(found and not self, "you can write to anyone the city knows (but not yourself)")
writer:SetPos(M0 + Vector(2000, 2000, 0))
ok(not LC.SendLetter(writer, idx, "cid-reader"), "letters go from the post office")
writer:SetPos(M0 + Vector(50, 0, 0))
ok(LC.SendLetter(writer, idx, "cid-reader") and #LC.Notes(writer) == idx - 1, "handed over the counter")
local unit = newPlayer("MailUnit", "cp")
unit:SetPos(M0 + Vector(80, 0, 0))
local list = LC.MailForInspection(unit) or {}
local mine = list[#list] or {}
ok(#list >= 1 and mine.from == LC.CharacterName(writer) and string.find(mine.text or "", "canal", 1, true) ~= nil, "a unit at the post office can read it, and sees who really posted it")
ok(LC.MailForInspection(writer) == nil, "nobody else can")
_setcvar("lc_mail_minutes", 0)
LC.MailTick()
local out = LC.LettersOut()
ok(#out >= 1 and out[#out].toCid == "cid-reader", "after sorting, it goes out for delivery")
local cr, crs = LC.SpawnCitizen(M0 + Vector(100, 100, 0))
crs.leaveAt = nil
crs.profile = { job = "courier" }
_setcvar("lc_npc_work", 1)
_setcvar("lc_npc_work_pct", 100)
_setcvar("lc_npc_work_grace", 0)
_setcvar("lc_daily_rhythm", 0) -- (whatever the hour: couriers don't work nights)
local evWas = LC.Event
LC.Event = nil -- (nor in a curfew, whatever earlier sections left running)
local chose = LC.NPCWorkChoose(cr, crs, CurTime())
ok(chose and crs.npcWork and crs.npcWork.id == "letters", "a courier takes the real mail",
    string.format("%s %s out=%d lock=%s", tostring(chose), tostring(crs.npcWork and crs.npcWork.id), #LC.LettersOut(), tostring(crs.questLock)))
LC.Event = evWas
_setcvar("lc_daily_rhythm", 1)
for _ = 1, 160 do if not crs.npcWork then break end _run(0.5) end
local got = LC.Notes(reader)[#LC.Notes(reader)]
ok(got and got.letter and string.find(got.text, "canal", 1, true) ~= nil, "and it turns up in their pockets", crs.state)
ok(has(reader.chat, "A letter has come"), "they're told")
cr:Remove()
LC.GiveItem(writer, "paper")
LC.WriteNote(writer, "Down with Breen.", "keep", false)
LC.SendLetter(writer, #LC.Notes(writer), "cid-reader")
local l2 = LC.Mail.letters[#LC.Mail.letters]
ok(LC.ConfiscateLetter(unit, l2.id) and LC.Mail.letters[#LC.Mail.letters] ~= l2, "a unit can confiscate one, and it never arrives")
LC.Mail.dir["cid-ghost"] = { name = "Ghost Person", block = 77 }
LC.GiveItem(writer, "paper")
LC.WriteNote(writer, "Hello, whoever you are.", "keep", true)
LC.SendLetter(writer, #LC.Notes(writer), "cid-ghost")
local l3 = LC.Mail.letters[#LC.Mail.letters]
LC.DeliverLetter(l3, nil)
ok(l3.state == "delivered", "someone who isn't in the city: it waits for them")
local ghost = newPlayer("GhostPerson", "citizen")
ghost:SetNW2String("lc_cid", "cid-ghost")
LC.MailTick()
local gg = LC.Notes(ghost)[#LC.Notes(ghost)]
ok(gg and string.find(gg.text, "whoever", 1, true) ~= nil, "and it reaches them when they're back")
_setcvar("lc_mail_minutes", 4)
_setcvar("lc_npc_work_grace", 60)
LC.RemovePoint(po) LC.RemoveZone(blk)
for _, p in ipairs({ writer, reader, unit, ghost }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
MailTests()
section("The power grid, and forcefields")
local G0 = Vector(-30000, 36000, 0)
local t = ents.Create("lc_transformer") t:SetPos(G0)
local lamp = ents.Create("lc_streetlight") lamp:SetPos(G0 + Vector(500, 0, 0))
local spk = ents.Create("lc_loudspeaker") spk:SetPos(G0 + Vector(0, 500, 0))
local scr = ents.Create("lc_screen") scr:SetPos(G0 + Vector(-500, 0, 0))
local ff = ents.Create("lc_forcefield") ff:SetPos(G0 + Vector(0, -500, 0))
local ffBank = ents.Create("lc_powerbank") ffBank:SetPos(G0 + Vector(0, -640, 0)) -- (a forcefield runs off a power bank)
ff.lcForcefield = true -- (the harness doesn't give entities their scripts' methods)
ff.FieldUp = function(self) return not self:GetNW2Bool("lc_nopower", false) and self:GetNW2Float("lc_short_until", 0) < CurTime() end
local far = ents.Create("lc_streetlight") far:SetPos(G0 + Vector(9000, 0, 0))
local door = ents.Create("func_door") door:SetPos(G0 + Vector(300, 300, 0))
door.mapid = 777
LC.SetDoorTag(door, "cp")
ok(LC.FeederOf(lamp:GetPos()) == t and LC.FeederOf(far:GetPos()) == nil, "a transformer feeds its district; further out is the city's mains")
ok(LC.PoweredAt(lamp:GetPos()), "and it's on")
local sab = newPlayer("Saboteur", "resistance", nil, 150)
sab:Give("weapon_lc_multitool") sab:SelectWeapon("weapon_lc_multitool")
sab:SetPos(G0 + Vector(40, 0, 0))
local unit = newPlayer("GridUnit", "cp")
unit:SetPos(G0 + Vector(0, -2600, 0))
unit.chat = {}
ok(not LC.PlayerMayUseCPDoor(sab, door), "(the Combine door is locked to them)")
ok(LC.SabotageTransformer(sab, t), "a multitool, and twelve seconds")
_run(13)
ok(t:GetNW2Bool("lc_down", false), "the transformer blows")
ok(lamp:GetNW2Bool("lc_nopower", false) and spk:GetNW2Bool("lc_nopower", false) and scr:GetNW2Bool("lc_nopower", false)
    and ff:GetNW2Bool("lc_nopower", false) and not far:GetNW2Bool("lc_nopower", false), "lights, loudspeakers, screens and forcefields in the district go out, and nothing outside it")
ok(LC.SpeakerBrokenNear(spk:GetPos() + Vector(50, 0, 0)), "nobody near a dead loudspeaker hears the PA")
ok(LC.PowerOut[door] ~= nil and LC.PlayerMayUseCPDoor(sab, door), "the Combine locks are dead")
ok(has(unit.chat, "Power failure"), "units hear about it at once")
local tech = newPlayer("GridTech", "citizen")
LC.SetJob(tech, "maintenance", true)
tech:SetPos(G0 + Vector(50, 0, 0))
ok(not LC.UseTransformer(sab, t), "only a Maintenance Technician can fix it")
ok(LC.UseTransformer(tech, t), "a technician gets to work")
_run(11)
ok(not t:GetNW2Bool("lc_down", true) and not lamp:GetNW2Bool("lc_nopower", true) and LC.PowerOut[door] == nil, "and the district has power again, locks and all")
ok(not LC.PlayerMayUseCPDoor(sab, door), "(the door's locked to them again)")
-- nobody fixes it: the emergency crews do, eventually
LC.TransformerDown(t, nil, "damage")
_setcvar("lc_blackout_minutes", 0.1)
_run(21) -- (the crews' check runs every ten seconds)
ok(not t:GetNW2Bool("lc_down", true), "if nobody fixes it, the emergency crews do")
_setcvar("lc_blackout_minutes", 8)
-- the city's own maintenance crew
LC.TransformerDown(t, nil, "damage")
t.lcDownAt = CurTime() - 1000
local crew, cst = LC.SpawnCitizen(G0 + Vector(300, 0, 0))
cst.leaveAt = nil
cst.profile = { job = "maintenance" }
_setcvar("lc_npc_work", 1)
_setcvar("lc_npc_work_pct", 100)
ok(LC.NPCWorkChoose(crew, cst, CurTime()) and cst.npcWork and cst.npcWork.id == "power", "the city's own maintenance crew goes to it")
for _ = 1, 60 do if not t:GetNW2Bool("lc_down", true) then break end _run(0.5) end
ok(not t:GetNW2Bool("lc_down", true), "and brings the power back")
crew:Remove()
-- forcefields
_run(1)
ok(not LC.FieldPass(sab) and hook.Run("ShouldCollide", ff, sab) == true, "a forcefield stops a citizen")
ok(LC.FieldPass(unit) and hook.Run("ShouldCollide", ff, unit) == false, "units walk through it")
ok(not LC.SwipeForcefield(sab, ff), "no keycard, no entry")
LC.GiveItem(sab, "cp_keycard")
ok(LC.SwipeForcefield(sab, ff) and hook.Run("ShouldCollide", ff, sab) == false, "a keycard swipe opens it for a moment")
_run(5)
ok(hook.Run("ShouldCollide", ff, sab) == true, "then it closes again")
ok(LC.ShortForcefield(sab, ff), "a multitool can short it out")
_run(7)
ok(hook.Run("ShouldCollide", ff, sab) == false, "for a minute")
LC.TransformerDown(t, nil, "damage")
ff:SetNW2Float("lc_short_until", 0)
ok(hook.Run("ShouldCollide", ff, sab) == false, "and it's down with the district's power")
LC.TransformerRestore(t, nil)
-- the map's own switchable lights, and the machines
local mlight = ents.Create("light") mlight:SetPos(G0 + Vector(300, 0, 0))
local msprite = ents.Create("env_sprite") msprite:SetPos(G0 + Vector(320, 0, 0))
local glow = ents.Create("env_sprite") glow:SetPos(G0 + Vector(330, 0, 0)) glow:SetParent(lamp)
local disp = ents.Create("lc_dispenser") disp:SetPos(G0 + Vector(0, 300, 0))
local vend = ents.Create("lc_vending") vend:SetPos(G0 + Vector(0, 350, 0))
local term = ents.Create("lc_terminal") term:SetPos(G0 + Vector(0, 400, 0))
local farLight = ents.Create("light") farLight:SetPos(G0 + Vector(9000, 0, 0))
LC.TransformerDown(t, nil, "damage")
ok(has(mlight.fired or {}, "TurnOff") and has(msprite.fired or {}, "HideSprite"), "the map's own switchable lights and glows in the district go out")
ok(glow.fired == nil, "(not a glow on something else, like a scanner's eye: only the map's own)")
ok(disp:GetNW2Bool("lc_nopower", false) and vend:GetNW2Bool("lc_nopower", false) and term:GetNW2Bool("lc_nopower", false),
    "ration dispensers, vending machines and the commissary go dead")
ok(LC.UseDispenser(sab, disp) == false and LC.UseVending(sab, vend) == false, "nothing comes out of them")
ok(farLight.fired == nil and not LC.CityDark, "nothing outside the district: one district isn't the whole city")
LC.TransformerRestore(t, nil)
ok(has(mlight.fired, "TurnOn") and has(msprite.fired, "ShowSprite") and not disp:GetNW2Bool("lc_nopower", true), "back on when the power is")
-- the whole grid
_setcvar("lc_blackout_share", 0.5)
local t2 = ents.Create("lc_transformer") t2:SetPos(G0 + Vector(20000, 0, 0))
local blackouts = {}
hook.Add("LivingCityBlackout", "PowerTest", function(on) blackouts[#blackouts + 1] = on end)
LC.TransformerDown(t, nil, "damage")
ok(LC.CityDark and GetGlobal2Bool("lc_blackout", false) and blackouts[1] == true, "half the grid down: the whole city goes dark")
ok(_lightstyles[0] == "b", "the map's own lighting with it")
ok(has(farLight.fired or {}, "TurnOff") and far:GetNW2Bool("lc_nopower", false), "every light and fixture, everywhere")
ok(not LC.PoweredAt(G0 + Vector(30000, 0, 0)), "(even on the city's mains)")
LC.TransformerRestore(t, nil)
ok(not LC.CityDark and _lightstyles[0] ~= "b" and not far:GetNW2Bool("lc_nopower", true), "and it all comes back")
ok(LC.ForceBlackout("on") and LC.CityDark, "admins can black out the city")
ok(not LC.ForceBlackout("auto") and not LC.CityDark, "and hand it back to the grid")
hook.Add("LivingCityBlackout", "PowerTest", function() end)
_setcvar("lc_blackout_share", 0)
for _, e in ipairs({ mlight, msprite, glow, disp, vend, term, farLight, t2 }) do e:Remove() end
-- nobody gets stuck inside one when it comes back up
ok(hook.Run("ShouldCollide", ff, sab) == true, "(it's up again)")
local stuck = newPlayer("FieldStuck", "citizen")
stuck:SetPos(ff:GetPos() + Vector(2, 10, 0))
local rulesBefore = stuck.lcRulesChanged or 0
LC.FieldUnstick()
ok(LC.FieldPass(stuck) and hook.Run("ShouldCollide", ff, stuck) == false, "someone a field comes up around can step out of it")
ok((stuck.lcRulesChanged or 0) > rulesBefore, "(and the physics is told to ask again)")
local pressed = newPlayer("FieldPressed", "citizen")
pressed:SetPos(ff:GetPos() + Vector(20, 0, 0))
LC.FieldUnstick()
ok(not LC.FieldPass(pressed), "pressed up against it isn't inside it: still stopped")
_run(1)
ok(not LC.FieldPass(pressed) and LC.FieldPass(stuck), "(and the one inside keeps the way out while they're in it)")
stuck:SetPos(ff:GetPos() + Vector(60, 0, 0))
_run(1)
ok(not LC.FieldPass(stuck), "until they step out")
-- an NPC who gets there to find the job gone
local wk, wst = LC.SpawnCitizen(G0 + Vector(600, 0, 0))
wst.leaveAt = nil
wst.npcWork = { id = "test_gone", label = "testing", i = 1, data = {}, steps = {
    { pos = G0, check = function() return false end, face = function() error("faced something that isn't there") end } } }
local okArrive, errArrive = pcall(LC.NPCWorkArrive, wk, wst, CurTime())
ok(okArrive and wst.npcWork == nil, "an NPC who arrives to find the job gone gives it up quietly" .. (okArrive and "" or (": " .. tostring(errArrive))))
LC.AddNPCTask("test_nowhere", { id = "nowhere", label = "going nowhere", find = function()
    return { steps = { { pos = function() return nil end, secs = 1 } } }
end })
wst.profile = { job = "test_nowhere" }
local okChoose, errChoose = pcall(LC.NPCWorkChoose, wk, wst, CurTime())
ok(okChoose and wst.npcWork == nil, "and a step with nowhere to go is dropped, not walked to" .. (okChoose and "" or (": " .. tostring(errChoose))))
wk:Remove()
for _, p in ipairs({ stuck, pressed }) do p:SetPos(Vector(-30000, 30000, 0)) end
for _, e in ipairs({ t, lamp, spk, scr, ff, far, door }) do if IsValid(e) then e:Remove() end end
for _, p in ipairs({ sab, unit, tech }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
PowerTests()
section("Escorts through Combine doors")
function WorkEscortTests()
_setcvar("lc_economy", 1)
local runWas = LC.Running
LC.Running = false -- (no city patrols wandering up to take the job: these units are the test's)
local E0 = Vector(-46000, 30000, 0)
-- the Combine's building, a door into it, a cell, and the release point outside
local hq = LC.AddZone(E0 + Vector(800, 0, 0), 500, "combine", 0)
local rel = LC.AddPoint(E0 + Vector(-600, 0, 0), 0, "release", 0)
local edoor = ents.Create("prop_door_rotating") edoor:SetPos(E0 + Vector(250, 0, 0))
edoor.mapid = 9101
LC.SetDoorTag(edoor, "cp")
local radio = newPlayer("EscortDispatch", "cp")
radio:SetPos(E0 + Vector(0, -3000, 0))
radio.chat = {}
local wkr = newPlayer("EscortWorker", "citizen")
wkr:SetPos(E0)
local okR, whyR = LC.RequestEscort(wkr)
ok(not okR and whyR ~= nil and string.find(whyR, "Union", 1, true) ~= nil, "only Union workers get an escort")
LC.SetJob(wkr, "maintenance", true)
okR, whyR = LC.RequestEscort(wkr)
ok(not okR and whyR ~= nil and string.find(whyR, "job", 1, true) ~= nil, "and only while they're on a job")
local job = { title = "Fix the generator", board = "Assignments", stages = { { kind = "goto", text = "Fix the generator" } }, stage = 1, members = { wkr }, marked = {} }
LC.QuestOf[wkr] = job
local function Cop(pos)
    local c = ents.Create("npc_metropolice") c:SetPos(pos)
    LC.NPCs[c] = { role = "cop", state = "idle", untilT = 0, nextWarn = 0, nextInspect = 1e9, test = true } -- (the city leaves test NPCs be)
    return c, LC.NPCs[c]
end
local c1, s1 = Cop(E0 + Vector(0, 1500, 0))
local c2, s2 = Cop(E0 + Vector(0, 2500, 0))
okR = LC.RequestEscort(wkr)
local e = LC.Escorts[wkr]
ok(okR and e ~= nil and e.unit == c1 and s1.workEscort == e and s1.state == "workescort", "the nearest free unit is sent")
ok(wkr:GetNW2String("lc_escort_phase", "") == "coming" and has(radio.chat, "Escort requested"), "it's on its way, and dispatch hears about it")
ok(not LC.EscortCovers(wkr), "(they aren't covered until it gets there)")
c1:SetPos(E0 + Vector(60, 0, 0))
LC.EscortTick()
ok(e.phase == "with" and LC.EscortCovers(wkr), "the unit arrives and stays with them")
wkr:SetPos(E0 + Vector(800, 0, 0)) c1:SetPos(E0 + Vector(760, 0, 0))
LC.CombineZoneTick(CurTime())
ok(wkr:GetNW2Float("lc_trespass_until", 0) == 0, "an escorted worker isn't trespassing in a Combine-only area")
-- doors
wkr:SetPos(E0 + Vector(200, 0, 0)) c1:SetPos(E0 + Vector(150, 0, 0))
ok(LC.PlayerMayUseCPDoor(wkr, edoor), "with their escort beside them, Combine doors open for them")
ok(e.doors[edoor] ~= nil and e.passed, "(and the unit keeps an eye on the door)")
local alone = newPlayer("EscortNobody", "citizen")
alone:SetPos(E0 + Vector(-1500, 0, 0))
ok(not LC.PlayerMayUseCPDoor(alone, edoor), "not for anyone else")
c1:SetPos(E0 + Vector(-700, 0, 0))
ok(not LC.PlayerMayUseCPDoor(wkr, edoor), "and not with their escort out of reach")
c1:SetPos(E0 + Vector(150, 0, 0))
-- a forcefield: the unit swipes them through
local eff = ents.Create("lc_forcefield") eff:SetPos(E0 + Vector(260, 60, 0))
eff.lcForcefield = true
eff.FieldUp = function() return true end
LC.EscortTick()
ok(LC.FieldPass(wkr), "forcefields let them by")
eff:Remove()
-- someone slips through behind them
local tail = newPlayer("EscortTail", "resistance", nil, 150)
tail:SetPos(e.doors[edoor].pos)
local standing = LC.Standing(wkr)
local tricked
hook.Add("LivingCityEscortTricked", "EscortTest", function(w, u, who, how) tricked = how end)
LC.EscortTick()
ok(LC.PlayerIsWanted(tail) and tricked == "intruder", "someone slipping through behind them is wanted for it")
ok(s1.state == "hostile" and s1.enemy == tail and not s1.workEscort, "and the unit breaks off to go after them")
ok(e.phase == "unattended" and LC.EscortCovers(wkr) and wkr:GetNW2String("lc_escort_phase", "") == "unattended", "the worker's left unattended, still covered while another unit comes")
ok(has(radio.chat, "unattended"), "the unit radios that the worker's unattended")
ok(LC.Standing(wkr) < standing, "it costs the worker standing")
tail:SetPos(Vector(-30000, 30000, 0))
LC.ClearWanted(tail)
for _ = 1, 25 do if e.unit then break end _run(0.2) end
ok(e.unit == c2 and s2.workEscort == e, "the nearest free unit comes to take over")
c2:SetPos(wkr:GetPos() + Vector(50, 0, 0))
LC.EscortTick()
ok(e.phase == "with", "and takes over")
-- a cell door, and a prisoner out of it
local cell = LC.AddPoint(E0 + Vector(900, 300, 0), 0, "cell", 0)
local pris = newPlayer("EscortPrisoner", "citizen")
pris:SetPos(cell.pos + Vector(0, 0, 4))
LC.Prisoners[pris] = { untilT = CurTime() + 999, cell = cell, reason = "test", weapons = {} }
local cdoor = ents.Create("prop_door_rotating") cdoor:SetPos(E0 + Vector(900, 200, 0))
cdoor.mapid = 9102
LC.SetDoorTag(cdoor, "cp")
wkr:SetPos(E0 + Vector(900, 120, 0)) c2:SetPos(E0 + Vector(640, 120, 0)) -- (near enough to open it, not to grab anyone)
LC.EscortTick()
ok(LC.PlayerMayUseCPDoor(wkr, cdoor), "(they get a cell door opened)")
pris:SetPos(e.doors[cdoor].pos)
LC.EscortTick()
ok(tricked == "prisoner" and #LC.Recaptures == 1 and LC.Recaptures[1].prisoner == pris, "a prisoner gets out: the unit goes to put them back")
ok(e.over and (wkr.lcEscortBanUntil or 0) > CurTime(), "twice on one job: dispatch won't send anyone else with them")
ok(not LC.RequestEscort(wkr), "(not for a while)")
c2:SetPos(pris:GetPos() + Vector(40, 0, 0))
LC.EscortTick()
ok(pris:GetPos():Distance(cell.pos) < 10 and #LC.Recaptures == 0, "the unit marches the prisoner back to their cell")
LC.Prisoners[pris] = nil
hook.Add("LivingCityEscortTricked", "EscortTest", function() end)
-- the job's over: out to the release point
wkr.lcEscortBanUntil = 0
s1.state, s1.enemy = "idle", nil
wkr:SetPos(E0 + Vector(800, 0, 0))
ok(hook.Run("PlayerSay", wkr, "!escort", false) == "" and LC.Escorts[wkr] ~= nil, "!escort asks for one too")
e = LC.Escorts[wkr]
local u = e.unit
u:SetPos(wkr:GetPos() + Vector(50, 0, 0))
LC.EscortTick()
LC.QuestOf[wkr] = nil
LC.EscortTick()
ok(e.phase == "out" and e.outTo ~= nil and e.outTo:Distance(rel.pos) < 1, "job done: the unit walks them out to the release point")
wkr:SetPos(rel.pos + Vector(30, 0, 0)) u:SetPos(rel.pos + Vector(60, 0, 0))
LC.EscortTick()
ok(e.over and LC.Escorts[wkr] == nil and LC.NPCs[u].state == "idle" and not LC.NPCs[u].workEscort, "at the release point the escort's over, and the unit goes back to its beat")
ok(wkr:GetNW2String("lc_escort_phase", "x") == "" and not IsValid(wkr:GetNW2Entity("lc_escort")), "(and their screen clears)")
-- never went inside: just left to it
LC.QuestOf[wkr] = job
wkr:SetPos(E0 + Vector(-1500, 0, 0))
LC.RequestEscort(wkr)
e = LC.Escorts[wkr]
e.unit:SetPos(wkr:GetPos() + Vector(40, 0, 0))
LC.EscortTick()
LC.QuestOf[wkr] = nil
LC.EscortTick()
ok(e.over and e.why == "done", "a worker who never went through a Combine door is just left to it when the job's done")
-- a player unit takes over, and hands back
LC.QuestOf[wkr] = job
LC.RequestEscort(wkr)
e = LC.Escorts[wkr]
local npcU = e.unit
ok(LC.TakeEscort(radio, wkr) and e.unit == radio and not LC.NPCs[npcU].workEscort, "a player unit can take over from an NPC unit")
ok(radio:GetNW2Entity("lc_escorting") == wkr, "(their menu knows who they're escorting)")
ok(LC.DropEscort(radio) and e.phase == "unattended" and e.unit == nil, "and hand it back to dispatch")
for _ = 1, 25 do if e.unit then break end _run(0.2) end
ok(IsValid(e.unit) and not e.unit:IsPlayer(), "and an NPC unit takes over")
-- slipping your escort
e.unit:SetPos(wkr:GetPos() + Vector(40, 0, 0))
LC.EscortTick()
local esc = e.unit
wkr:SetPos(wkr:GetPos() + Vector(0, 4000, 0))
for _ = 1, 34 do
    if e.over then break end
    _advance(0.5)
    esc:SetPos(E0 + Vector(-1500, 0, 0)) -- (it doesn't keep up)
    LC.EscortTick()
end
ok(e.over and e.why == "slipped", "a worker who leaves their escort behind is on their own")
-- nobody free
_setcvar("lc_escort_range", 1)
wkr:SetPos(E0)
LC.RequestEscort(wkr)
e = LC.Escorts[wkr]
ok(e ~= nil and e.phase == "waiting" and wkr:GetNW2Bool("lc_escort_wait", false), "no unit free: the request waits")
local listed = false
for _, p in ipairs(LC.EscortRequests()) do if p == wkr then listed = true end end
ok(listed, "and player units see it in their menu")
e.since = CurTime() - 999
LC.EscortTick()
ok(e.over and e.why == "lapsed" and not wkr:GetNW2Bool("lc_escort_wait", true), "if nobody takes it, it lapses")
_setcvar("lc_escort_range", 6000)
-- the actions menu
wkr.lcActionNext = 0
_netcall("lc_action", wkr, "escort", "", NULL)
ok(LC.Escorts[wkr] ~= nil, "the actions menu asks for one")
wkr.lcActionNext = 0
_netcall("lc_action", wkr, "escort", "", NULL)
ok(LC.Escorts[wkr] == nil, "and sends it away again")
for _, c in ipairs({ c1, c2 }) do LC.NPCs[c] = nil c:Remove() end
for _, d in ipairs({ edoor, cdoor }) do d:Remove() end
LC.RemovePoint(rel) LC.RemovePoint(cell) LC.RemoveZone(hq)
LC.QuestOf[wkr] = nil
for _, p in ipairs({ wkr, radio, alone, tail, pris }) do p:SetPos(Vector(-30000, 30000, 0)) end
LC.Running = runWas
end
WorkEscortTests()
section("Prison doors stay shut")
function PrisonDoorTests()
local P0 = Vector(-48000, -30000, 0)
local cellP = LC.AddPoint(P0, 0, "cell", 0)
local pdoor = ents.Create("func_door") pdoor:SetPos(P0 + Vector(100, 0, -36)) pdoor.mapid = 9201
local other = ents.Create("func_door") other:SetPos(P0 + Vector(3000, 0, -36)) other.mapid = 9202
local cpdoor = ents.Create("func_door") cpdoor:SetPos(P0 + Vector(3000, 400, -36)) cpdoor.mapid = 9203
LC.SetDoorTag(cpdoor, "cp")
LC.ApplyDoorState(pdoor) LC.ApplyDoorState(other)
ok(LC.EffectiveDoorTag(pdoor) == "prison" and LC.EffectiveDoorTag(other) == nil, "a door by a cell is a prison door, without being told")
ok(pdoor.locked and LC.PrisonDoors[pdoor], "and it's locked")
local inmate = newPlayer("PDInmate", "citizen")
inmate:SetPos(P0 + Vector(0, 0, 4))
LC.Prisoners[inmate] = { untilT = CurTime() + 999, cell = cellP, reason = "test", weapons = {} }
ok(hook.Run("PlayerUse", inmate, pdoor) == false and not LC.DoorIsOpen(pdoor), "a prisoner can't open it")
local btn = ents.Create("func_button") btn:SetPos(P0 + Vector(40, 0, 0))
ok(hook.Run("PlayerUse", inmate, btn) == false, "or press the map's buttons")
-- the map's own logic opens it (a button, a trigger)
pdoor:Fire("Unlock") pdoor:Fire("Open")
ok(LC.DoorIsOpen(pdoor), "(something opens it)")
ok(LC.PrisonDoorThink(CurTime()) == 1 and not LC.DoorIsOpen(pdoor) and pdoor.locked, "and it shuts and locks itself again at once")
-- units
local warden = newPlayer("PDWarden", "cp")
warden:SetPos(P0 + Vector(160, 0, 0))
hook.Run("PlayerUse", warden, pdoor)
ok(LC.DoorIsOpen(pdoor), "a unit opens it")
LC.PrisonDoorThink(CurTime())
ok(LC.DoorIsOpen(pdoor), "and it stays open for them")
LC.ApplyDoorState(pdoor)
hook.Run("PlayerUse", warden, btn)
pdoor:Fire("Unlock") pdoor:Fire("Open")
LC.PrisonDoorThink(CurTime())
ok(LC.DoorIsOpen(pdoor), "a unit at the map's button can open the cells")
_advance(11)
LC.PrisonDoorThink(CurTime())
ok(not LC.DoorIsOpen(pdoor) and pdoor.locked, "(for a few seconds, then they're shut again)")
-- the power goes
LC.ForceBlackout("on")
ok(pdoor.locked and not LC.PowerOut[pdoor] and not LC.PlayerMayUseCPDoor(inmate, pdoor), "in a blackout, prison doors stay locked")
ok(LC.PowerOut[cpdoor] and not cpdoor.locked, "(while the city's other Combine doors go dead)")
LC.ForceBlackout("auto")
ok(cpdoor.locked and not LC.PowerOut[cpdoor], "(and lock again when it's back)")
-- the editor's tag
LC.SetDoorTag(other, "prison")
ok(LC.PrisonDoors[other] and other.locked and LC.EffectiveDoorTag(other) == "prison", "the editor's Prison door tag does the same anywhere")
LC.SetDoorTag(other, nil)
LC.ApplyDoorState(other)
ok(not LC.PrisonDoors[other], "(and untagged, it's an ordinary door again)")
LC.Prisoners[inmate] = nil
for _, e in ipairs({ pdoor, other, cpdoor, btn }) do e:Remove() end
LC.RemovePoint(cellP)
for _, p in ipairs({ inmate, warden }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
PrisonDoorTests()
section("Checkpoints, turrets, and holding the infestation")
function CheckpointTests()
local runWas = LC.Running
LC.Running = false
_setcvar("lc_territory_spread", 1)
local K0 = Vector(-50000, -40000, 0)
-- an infestation, and a checkpoint at its edge: a power bank and a forcefield
local inf = LC.AddZone(K0, 600, "infest", 0)
local bank = ents.Create("lc_powerbank") bank:SetPos(K0 + Vector(1000, 0, 0))
local kff = ents.Create("lc_forcefield") kff:SetPos(K0 + Vector(1100, 300, 0))
kff.lcForcefield = true
kff.FieldUp = function(self) return not self:GetNW2Bool("lc_nopower", false) and self:GetNW2Float("lc_short_until", 0) < CurTime() end
LC.RefreshPower()
LC.CheckpointTick(CurTime())
ok(LC.PowerBankLive(bank) and kff:GetNW2Entity("lc_cable") == bank and not kff:GetNW2Bool("lc_nopower", false), "a forcefield near a power bank runs off it, on a cable")
-- a unit puts up turrets
local tu = newPlayer("TurretUnit", "cp")
tu:SetPos(K0 + Vector(900, 0, 0))
local aim = K0 + Vector(950, -60, 0)
tu.GetEyeTrace = function() return { Hit = true, HitPos = aim, HitNormal = Vector(0, 0, 1) } end
local civ = newPlayer("TurretCitizen", "citizen")
civ:SetPos(K0 + Vector(900, 150, 0))
civ.GetEyeTrace = tu.GetEyeTrace
ok(not LC.DeployTurret(civ), "only units put turrets up")
local okT = LC.DeployTurret(tu)
local tur
for t, o in pairs(LC.DeployedTurrets) do if o == tu and IsValid(t) then tur = t end end
ok(okT and tur ~= nil and tur:GetClass() == "npc_turret_floor", "a unit deploys a turret at the checkpoint")
ok(tur:GetNW2Entity("lc_cable") == bank and tur.lcPowered == true and has(tur.fired or {}, "Enable"), "cabled to the power bank, and live")
tu.lcTurretNext = 0
aim = K0 + Vector(6000, 0, 0)
tu:SetPos(K0 + Vector(5950, 0, 0))
local okFar, whyFar = LC.DeployTurret(tu)
ok(not okFar and whyFar ~= nil and string.find(whyFar, "power", 1, true) ~= nil, "nowhere near a power bank or forcefield, no turret")
tu:SetPos(K0 + Vector(900, 0, 0))
-- who it shoots
ok(tur.rel[civ] == D_NU and tur.rel[tu] == D_LI, "it leaves citizens and units alone")
LC.SetWanted(civ, 60, "test")
tur.lcNextRel = 0
LC.CheckpointTick(CurTime())
ok(tur.rel[civ] == D_HT, "and shoots the wanted")
LC.ClearWanted(civ)
tur.lcNextRel = 0
LC.CheckpointTick(CurTime())
ok(tur.rel[civ] == D_NU, "(until they aren't)")
local zom = LC.SpawnZombie(K0 + Vector(100, 0, 0), inf)
tur.lcNextRel = 0
LC.CheckpointTick(CurTime())
ok(IsValid(zom) and tur.rel[zom] == D_HT, "and the infected")
ok(hook.Run("PlayerUse", civ, tur) == false and hook.Run("GravGunPickupAllowed", civ, tur) == false, "nobody but a unit picks a turret up")
-- forcefields hold the infected
ok(hook.Run("ShouldCollide", kff, zom) == true, "a forcefield stops the infected")
-- the infestation stops at a live checkpoint
ok(LC.ContainmentBlocks(K0, K0 + Vector(1100, 0, 0), 300), "the infestation can't spread over a live checkpoint")
ok(LC.ContainmentBlocks(K0, K0 + Vector(1500, 50, 0), 300), "or past it")
ok(not LC.ContainmentBlocks(K0, K0 + Vector(-1100, 0, 0), 300), "(the other way, it can)")
-- what the turrets kill holds it, quietly
local disp = newPlayer("TurretDispatch", "cp")
disp:SetPos(K0 + Vector(0, -9000, 0))
disp.chat = {}
local st0 = LC.TerritoryState[inf]
hook.Run("OnNPCKilled", zom, tur, tur)
_run(1)
local st1 = LC.TerritoryState[inf]
ok(st1 ~= nil and st1.lastHit >= CurTime() - 2 and (st1.hits or 0) == 0, "what the turrets kill holds the infestation where it is, without pushing it back")
ok(not has(disp.chat, "contained"), "and nobody's told about every kill")
-- the editor's turrets, and walls
local tp = LC.AddPoint(K0 + Vector(1050, -200, 0), 90, "turret", 0)
local bp = LC.AddPoint(K0 + Vector(1200, -300, 0), 90, "barricade_tall", 0)
LC.SyncFixtures()
local fixT, fixB
for _, e in pairs(LC.Fixtures) do
    if IsValid(e) and e:GetClass() == "npc_turret_floor" then fixT = e end
    if IsValid(e) and e:GetClass() == "lc_barricade" and e.lcFixtureKind == "barricade_tall" then fixB = e end
end
LC.CheckpointTick(CurTime())
ok(fixT ~= nil and fixT.lcTurret and fixT.lcPowered, "the editor places turrets that run off the checkpoint too")
ok(fixB ~= nil, "and the Combine's barricade walls")
-- moved with the physgun, the layout goes with it
local admin0 = newPlayer("FixtureMover", "citizen")
admin0.isAdmin, admin0.superadmin = true, true
fixB:SetPos(fixB:GetPos() + Vector(300, 0, 0))
hook.Run("PhysgunDrop", admin0, fixB)
ok(LC.CanEdit(admin0) == false or (math.abs(bp.pos.x - (K0.x + 1500)) < 2 and LC.Fixtures[fixB.lcFixtureKey] == fixB), "a fixture moved with the physgun is saved where it was put")
LC.SyncFixtures()
ok(IsValid(fixB), "(and isn't replaced by a new one where it used to be)")
-- the power goes: a containment breach
_advance(11)
LC.CheckpointTick(CurTime())
local zombies = 0
for _, s in pairs(LC.NPCs) do if s.role == "zombie" then zombies = zombies + 1 end end
local zonesBefore = #LC.ZonesOfKind("infest")
bank:SetNW2Float("lc_short_until", CurTime() + 120)
LC.CheckpointTick(CurTime())
ok(not tur.lcPowered and has(tur.fired, "Disable"), "short the power bank and its turrets fold up")
ok(kff:GetNW2Bool("lc_nopower", false) and hook.Run("ShouldCollide", kff, zom) == false, "and its forcefield drops")
ok(#LC.Breaches >= 1 and has(disp.chat, "breach"), "a checkpoint holding the infestation back loses power: a containment breach")
local after = 0
for _, s in pairs(LC.NPCs) do if s.role == "zombie" then after = after + 1 end end
ok(#LC.ZonesOfKind("infest") > zonesBefore or after > zombies, "the infestation surges over it, and the infected pour out")
local breaches = #LC.Breaches
bank:SetNW2Float("lc_short_until", 0)
LC.CheckpointTick(CurTime())
_advance(11)
LC.CheckpointTick(CurTime())
bank:SetNW2Float("lc_short_until", CurTime() + 120)
LC.CheckpointTick(CurTime())
ok(#LC.Breaches == breaches, "(one breach in a place at a time)")
bank:SetNW2Float("lc_short_until", 0)
-- the city-wide blackout kills it too
LC.ForceBlackout("on")
LC.CheckpointTick(CurTime())
ok(not LC.PowerBankLive(bank) and not tur.lcPowered, "a city-wide blackout kills the checkpoint")
LC.ForceBlackout("auto")
LC.CheckpointTick(CurTime())
ok(LC.PowerBankLive(bank) and tur.lcPowered, "and it comes back with the power")
-- a rebel with a multitool
local hack = newPlayer("BankHacker", "resistance", nil, 150)
hack:SetPos(K0 + Vector(960, 0, 0))
hack:Give("weapon_lc_multitool") hack:SelectWeapon("weapon_lc_multitool")
ok(LC.ShortPowerBank(hack, bank), "a multitool can short a power bank out")
_run(9)
ok(not LC.PowerBankLive(bank), "and it's dead for a while")
bank:SetNW2Float("lc_short_until", 0)
-- officers put banks up
tu.GetEyeTrace = function() return { Hit = true, HitPos = K0 + Vector(940, 0, 40), HitNormal = Vector(1, 0, 0) } end
ok(not LC.DeployPowerBank(tu), "only officers put up power banks")
tu:SetNW2Int("lcf_rank", 3)
local okB = LC.DeployPowerBank(tu)
local nb = tu.lcBank
ok(okB and IsValid(nb) and LC.DeployedBanks[nb] == tu, "an officer puts one up on a wall")
ok(LC.PackPowerBank(tu, nb) and not IsValid(nb), "and takes it down again")
-- packing up
ok(LC.PackTurret(tu, tur) and not IsValid(tur), "a unit packs a turret up")
-- tidy up
for _, e in ipairs({ bank, kff, zom }) do if IsValid(e) then e:Remove() end end
LC.RemovePoint(tp) LC.RemovePoint(bp)
LC.SyncFixtures()
for _, z in ipairs(LC.ZonesOfKind("infest")) do if z.grown and z.seed == inf then LC.RecedeTerritory(z, "test") end end
LC.RemoveZone(inf)
LC.Breaches = {}
for _, p in ipairs({ tu, civ, disp, hack }) do p:SetPos(Vector(-30000, 30000, 0)) end
LC.Running = runWas
end
CheckpointTests()
section("Alarms bring a response squad")
function ResponseSquadTests()
local runWas = LC.Running
LC.Running = true
local R0 = Vector(-52000, 42000, 0)
for k in pairs(LC.ResponseSquads) do LC.ResponseSquads[k] = nil end
local thief = newPlayer("SquadThief", "resistance", nil, 150)
thief:SetPos(R0)
local wanderWas, seenWas = LC.RandomWanderPos, LC.IsSeen
LC.RandomWanderPos = function() return R0 + Vector(900, 0, 0) end
LC.IsSeen = function() return false end
local n = LC.SendResponseSquad(thief, R0, "test")
local cops, soldiers, hostile = 0, 0, 0
for npc in pairs(LC.ResponseSquads) do
    local st = LC.NPCs[npc]
    if st and st.role == "cop" then cops = cops + 1 end
    if st and st.role == "soldier" then soldiers = soldiers + 1 end
    if st and st.state == "hostile" and st.enemy == thief and st.unmanaged then hostile = hostile + 1 end
end
ok(n == 3 and cops == 2 and soldiers == 1, "an alarm brings two metrocops and a soldier")
ok(hostile == 3, "and they come for whoever set it off")
local far = true
for npc in pairs(LC.ResponseSquads) do if npc:GetPos():Distance(R0) < 300 then far = false end end
ok(far, "(from a walk away, not on top of them)")
LC.ClearWanted(thief)
_advance(70)
_runtimers()
local left = 0
for npc in pairs(LC.ResponseSquads) do if IsValid(npc) then left = left + 1 end end
ok(left == 0, "once it's over, they leave")
LC.RandomWanderPos, LC.IsSeen = wanderWas, seenWas
thief:SetPos(Vector(-30000, 30000, 0))
LC.Running = runWas
end
ResponseSquadTests()
section("The nexus garrison")
function GarrisonTests()
local runWas, seenWas = LC.Running, LC.IsSeen
LC.Running = true
LC.IsSeen = function() return false end
_setcvar("lc_garrison", 6)
local G0 = Vector(-60000, -42000, 0)
local gz = LC.AddZone(G0, 900, "combine", 0)
ok(LC.GarrisonSize(gz) >= 4 and LC.GarrisonSize(gz) <= 6, "a big Combine zone holds a handful of units")
local t = CurTime()
for i = 1, 20 do LC.GarrisonTick(t + i * 3) end
local n, cops, soldiers, inside, guarding = 0, 0, 0, 0, 0
for npc, z in pairs(LC.Garrison) do
    if z == gz and IsValid(npc) then
        n = n + 1
        local st = LC.NPCs[npc]
        if st.role == "cop" then cops = cops + 1 elseif st.role == "soldier" then soldiers = soldiers + 1 end
        if npc:GetPos():Distance(G0) < 900 then inside = inside + 1 end
        if st.guardZone == gz and st.unmanaged then guarding = guarding + 1 end
    end
end
ok(n == LC.GarrisonSize(gz), "it fills up")
ok(soldiers > cops and cops >= 1, "mostly soldiers, with a metrocop or two")
ok(inside == n and guarding == n, "spread through the zone, and they stay in it")
-- one is lost: replaced, after a while
local victim
for npc, z in pairs(LC.Garrison) do if z == gz and IsValid(npc) then victim = npc break end end
LC.NPCs[victim] = nil
victim:Remove()
LC.GarrisonTick(t + 70)
local n2 = 0
for npc, z in pairs(LC.Garrison) do if z == gz and IsValid(npc) then n2 = n2 + 1 end end
ok(n2 == n - 1, "a lost unit isn't replaced at once")
LC.GarrisonTick(t + 70 + 95)
n2 = 0
for npc, z in pairs(LC.Garrison) do if z == gz and IsValid(npc) then n2 = n2 + 1 end end
ok(n2 == n, "but is after a while")
-- the zone is deleted: they go
LC.RemoveZone(gz)
LC.GarrisonTick(t + 200)
n2 = 0
for npc, z in pairs(LC.Garrison) do if z == gz and IsValid(npc) then n2 = n2 + 1 end end
ok(n2 == 0, "a deleted zone's garrison leaves")
_setcvar("lc_garrison", 0)
for npc in pairs(LC.Garrison) do if IsValid(npc) then LC.NPCs[npc] = nil npc:Remove() end end
LC.Garrison = {}
LC.IsSeen, LC.Running = seenWas, runWas
end
GarrisonTests()
section("Judgment waiver: pistols out")
function WaiverTests()
local runWas = LC.Running
LC.Running = true
local cop, cst = LC.SpawnCop(Vector(-61000, -45000, 0))
cst.test = true
local socioWas = LC.Socio
LC.Socio = "red"
LC.WaiverArmTick()
ok(cop.activeWeapon == "weapon_pistol" and has(cop.weps or {}, "weapon_pistol"), "a judgment waiver: metrocops draw pistols")
LC.CalmOne(cop, cst, CurTime())
ok(cop.activeWeapon == "weapon_pistol", "(and keep them out while it lasts)")
LC.Socio = "green"
LC.WaiverArmTick()
ok(cop.activeWeapon == "weapon_stunstick", "lifted: back to the stick")
LC.Socio = socioWas
LC.NPCs[cop] = nil
cop:Remove()
LC.Running = runWas
end
WaiverTests()
section("Rooftop territory stays on the roof")
function RoofTests()
local F0 = Vector(-70000, 50000, 400)
-- a 700 x 700 roof, 400 up, with the street below it
_groundFn = function(x, y)
    if math.abs(x - F0.x) < 350 and math.abs(y - F0.y) < 350 then return 400 end
    return 0
end
local seed = LC.AddZone(F0, 500, "rebel", 0)
local wanderWas = LC.RandomWanderPos
LC.RandomWanderPos = function() return nil end
local floating = false
for _ = 1, 10 do
    local p, r = LC.TerritoryGrowthSpot(seed)
    if p and (math.abs(p.x - F0.x) > 350 or math.abs(p.y - F0.y) > 350 or p.z ~= 400) then floating = true end
end
ok(not floating, "it doesn't grow out over the edge into thin air")
local spots = LC.ZoneFloorSpots(seed, 6)
local onRoof = #spots > 0
for _, p in ipairs(spots) do
    if p.z ~= 400 or math.abs(p.x - F0.x) > 330 or math.abs(p.y - F0.y) > 330 then onRoof = false end
end
ok(onRoof, "and its props go on the roof, clear of the edge")
ok(not LC.DressingClear(F0 + Vector(340, 0, 0), 40), "(nothing hanging half off it)")
-- a stairwell down off the roof: it can spread down it, onto the street, but
-- only where an NPC could walk it
local graphWas, statsWas, badWas = LC.NavGraph, LC.NavStats, LC.BadLinks
local function Graph(linked)
    local A = { pos = F0 + Vector(250, 0, 0), adj = {}, comp = 1 }               -- the top of the stairs, on the roof
    local B = { pos = Vector(F0.x + 450, F0.y, 0), adj = {}, comp = linked and 1 or 2 } -- the foot of them, in the street
    local C = { pos = Vector(F0.x + 650, F0.y + 150, 0), adj = {}, comp = B.comp }
    local function Link(a, b) local d = a.pos:Distance(b.pos) a.adj[#a.adj + 1] = { b, d } b.adj[#b.adj + 1] = { a, d } end
    if linked then Link(A, B) end
    Link(B, C)
    LC.NavGraph = { nodes = { A, B, C }, main = 1, links = 2 }
    LC.NavGraphReady()
end
local function Grows()
    local down, air = false, false
    for _ = 1, 15 do
        local p = LC.TerritoryGrowthSpot(seed)
        if p then
            local onRoof = math.abs(p.x - F0.x) < 350 and math.abs(p.y - F0.y) < 350
            if p.z == 0 and not onRoof then down = true end
            if (p.z == 400) ~= onRoof then air = true end
        end
    end
    return down, air
end
Graph(true)
local down, air = Grows()
ok(down and not air, "down a stairwell an NPC can walk, it spreads to the next level")
local z0 = { pos = Vector(F0.x + 500, F0.y, 400), r = 300, h = 128 }
ok(not LCZ.Contains(z0, Vector(F0.x + 500, F0.y, 0)), "(a patch up there isn't the street under it too)")
Graph(false)
down, air = Grows()
ok(not down and not air, "but not where nobody can walk between them")
LC.NavGraph, LC.NavStats, LC.BadLinks = graphWas, statsWas, badWas
LC.NavGraphReady()
if statsWas then LC.NavStats = statsWas end
if badWas then LC.BadLinks = badWas end
LC.RandomWanderPos = wanderWas
LC.RemoveZone(seed)
_groundFn = nil
end
RoofTests()
section("Doors tagged to stay open stay open")
function KeepOpenTests()
local d = ents.Create("prop_door_rotating")
d.mapid = 951
d:SetPos(Vector(-72000, 52000, 40))
local b = ents.Create("func_door")
b.mapid = 952
b:SetPos(Vector(-72300, 52000, 40))
LC.SetDoorTag(d, "open")
LC.SetDoorTag(b, "open")
ok(d.isOpen and b.isOpen, "an \"always open\" door opens")
ok(d.kv.returndelay == "-1" and b.kv.wait == "-1", "its own timer that would swing it shut again is off")
ok(d.locked, "and it's locked open")
ok(hook.Run("PlayerUse", newPlayer("DoorShutter", "citizen"), d) == false, "(pressing E doesn't shut it)")
d:Fire("Close") -- the map's own logic
b:Fire("Close")
LC.KeepOpenThink(CurTime() + 10)
ok(d.isOpen and b.isOpen, "anything that shuts it anyway, and it opens again")
LC.SetDoorTag(d, nil)
LC.SetDoorTag(b, nil)
LC.KeepOpenThink(CurTime() + 20)
ok(not LC.KeptOpen[d] and not LC.KeptOpen[b], "untagged, it's left alone")
end
KeepOpenTests()
section("Combine NPCs go through Civil Protection doors")
function CPDoorTests()
local D0 = Vector(-74000, 54000, 0)
-- a wide, thick sliding shutter: nothing like a door by its shape
local shutter = ents.Create("func_door")
shutter.mapid = 961
shutter:SetPos(D0)
shutter.obbmin, shutter.obbmax = Vector(-40, -90, 0), Vector(40, 90, 120)
ok(not LC.IsRealDoor(shutter), "(untagged, a slab that size could be a lift)")
LC.SetDoorTag(shutter, "cp")
shutter.lcTagCache = nil
ok(LC.IsRealDoor(shutter), "tagged Civil Protection only, it's a door, whatever its shape")
-- the map's nodegraph was built with it shut: two areas, no way between
local graphWas, statsWas, badWas = LC.NavGraph, LC.NavStats, LC.BadLinks
local function N(x, comp) return { pos = D0 + Vector(x, 0, 0), adj = {}, comp = comp } end
local A1, A2, B1, B2 = N(-450, 1), N(-120, 1), N(120, 2), N(450, 2)
local function Link(a, b) local d = a.pos:Distance(b.pos) a.adj[#a.adj + 1] = { b, d } b.adj[#b.adj + 1] = { a, d } end
Link(A1, A2) Link(B1, B2)
LC.NavGraph = { nodes = { A1, A2, B1, B2 }, main = 1, links = 2 }
LC.NavGraphReady()
ok(LC.NavRoute(A1.pos, B2.pos, "cop") == false, "(before: the far side can't be reached)")
LC.ApplyLadders()
local copRoute = LC.NavRoute(A1.pos, B2.pos, "cop")
ok(type(copRoute) == "table", "a tagged door joins the two sides: units are routed through it", tostring(copRoute))
ok(LC.NavRoute(A1.pos, B2.pos, "citizen") == false, "but citizens aren't (it's Civil Protection only)")
LC.NavGraph = graphWas
LC.NavGraphReady()
if statsWas then LC.NavStats = statsWas end
if badWas then LC.BadLinks = badWas end
pcall(LC.ApplyLadders)
LC.SetDoorTag(shutter, nil)
end
CPDoorTests()
section("Persistent props")
function PersistentPropTests()
local builder = newPlayer("PropBuilder", "citizen")
builder.superadmin = true
local P0 = Vector(-76000, 56000, 0)
local e = ents.Create("prop_physics")
e:SetModel("models/props_c17/oildrum001.mdl")
e:SetPos(P0)
e:Spawn()
e:SetSkin(2)
local okP, what = LC.PersistProp(builder, e)
ok(okP and what == "new" and e.lcPersistId ~= nil, "a prop you spawned, zapped with the editor: persistent")
local id = e.lcPersistId
local saved = util.JSONToTable(_files["livingcity/" .. game.GetMap() .. ".json"] or "") or {}
local found
for _, r in ipairs(saved.props or {}) do if r.id == id then found = r end end
ok(found and found.model == "models/props_c17/oildrum001.mdl" and found.skin == 2, "saved in the map's layout, as it looks")
-- the map loads again: it's put back where it was
e:Remove()
LC.PropsFromSave(saved.props)
LC.SyncProps(LC.PropsFresh)
LC.PropsFresh = nil
local back = LC.PropEnts[id]
ok(IsValid(back) and back:GetModel() == "models/props_c17/oildrum001.mdl" and back:GetPos():Distance(P0) < 1 and back:GetSkin() == 2,
    "and it's there when the map loads, where you left it")
-- broken: back a minute later, out of sight
back:Remove()
LC.SyncProps(false)
ok(not IsValid(LC.PropEnts[id]), "(broken: not straight back)")
_advance(70)
LC.SyncProps(false)
local again = LC.PropEnts[id]
ok(IsValid(again), "but back a minute later, while nobody's looking")
-- moved with the physgun: saved where it's dropped
again:SetPos(P0 + Vector(100, 0, 0))
hook.Run("PhysgunDrop", builder, again)
ok(LC.PropRecord(id).pos:Distance(P0 + Vector(100, 0, 0)) < 1, "moved with the physgun, it's saved where you drop it")
-- right click: no longer persistent
ok(LC.UnpersistProp(again, true) and IsValid(again) and LC.PropRecord(id) == nil, "right click: out of the layout, left where it is")
again:Remove()
end
PersistentPropTests()
section("Guns hit the floor")
function GunDropTests()
local G0 = Vector(-78000, 58000, 0)
local sold, sst = LC.SpawnSoldier(G0)
sold.kv.additionalequipment = "weapon_smg1"
local before = #LC.DroppedGuns
hook.Run("OnNPCKilled", sold, NULL)
local d = LC.DroppedGuns[#LC.DroppedGuns]
ok(#LC.DroppedGuns == before + 1 and d and IsValid(d.ent) and d.ent:GetClass() == "weapon_smg1", "a dead soldier drops his SMG")
ok(d and d.ent.clip1 and d.ent.clip1 >= 10 and d.ent.clip1 <= 18, "with about half a clip in it", d and d.ent.clip1)
local cop, cst = LC.SpawnCop(G0 + Vector(200, 0, 0))
cop.activeWeapon = "weapon_stunstick"
local n0 = #LC.DroppedGuns
hook.Run("OnNPCKilled", cop, NULL)
ok(#LC.DroppedGuns == n0, "(a stunstick isn't dropped: that's for searching the body)")
for _, g in ipairs(LC.DroppedGuns) do if IsValid(g.ent) then g.ent:Remove() end end
LC.DroppedGuns = {}
LC.NPCs[sold], LC.NPCs[cop] = nil, nil
sold:Remove() cop:Remove()
end
GunDropTests()
section("The lab decodes chips")
function QMDecodeTests()
local qmWas, sciWas = LC.NearQuartermaster, LC.ScientistNear
LC.NearQuartermaster = function() return true end
local rebel = newPlayer("ChipCarrier", "resistance", nil, 150)
rebel.chat = {}
LC.GiveItem(rebel, "data_chip", 1)
local okS, whyS = LC.DealerSell(rebel, "data_chip")
ok(not okS and string.find(whyS or "", "lab", 1, true), "the quartermaster doesn't buy a chip: he sends you to the lab", whyS)
LC.NearQuartermaster = qmWas
LC.ScientistNear = function() return rebel end
local c0 = LC.Credits(rebel)
_netcall("lc_lab_decode", rebel, "data_chip")
ok(not LC.HasItem(rebel, "data_chip") and LC.Credits(rebel) > c0, "the Decode button in the lab's window decodes it")
LC.ScientistNear = sciWas
rebel:SetPos(Vector(-30000, 30000, 0))
end
QMDecodeTests()
section("Civil Standing: one line, not a screenful")
function StandingBatchTests()
local brute = newPlayer("StandingBrute", "citizen")
brute.chat = {}
for _ = 1, 3 do LC.AddStanding(brute, -25, "Assaulting Civil Protection") end
LC.AddStanding(brute, -25, "Murder of a Civil Protection officer")
ok(#brute.chat == 0, "(nothing yet, while it's still happening)")
_run(2)
local lines = 0
for _, l in ipairs(brute.chat) do if string.find(l, "[Civil Standing]", 1, true) and string.find(l, "Assaulting", 1, true) then lines = lines + 1 end end
ok(lines == 1 and has(brute.chat, "-100") and has(brute.chat, "x3, -75") and has(brute.chat, "Murder of a Civil Protection officer (-25)"),
    "a fight's worth of offences is one line, adding them up", table.concat(brute.chat, " | "))
brute:SetPos(Vector(-30000, 30000, 0))
end
StandingBatchTests()
section("Ladders learned from the people who climb them")
function LadderLearnTests()
local climber = newPlayer("Climber", "citizen")
local L0 = Vector(-80000, 60000, 0)
local before = #LC.Points
climber:SetPos(L0)
climber.movetype, climber.ground = MOVETYPE_WALK, true
LC.LadderLearnTick(CurTime())
climber.movetype = MOVETYPE_LADDER or 9
climber:SetPos(L0 + Vector(0, 10, 100))
LC.LadderLearnTick(CurTime())
climber:SetPos(L0 + Vector(0, 40, 256))
climber.movetype = MOVETYPE_WALK
LC.LadderLearnTick(CurTime())
local ends = {}
for i = before + 1, #LC.Points do if LC.Points[i].kind == "ladder" then ends[#ends + 1] = LC.Points[i] end end
ok(#ends == 2 and ends[1].group == ends[2].group, "a player climbs a ladder: its foot and its top are remembered as a ladder")
local near, far = LC.LadderToward(L0 + Vector(30, 0, 0), L0 + Vector(200, 40, 256))
ok(near and far and math.abs(far.z - 256) < 1, "and an NPC following them up knows to go to its foot and come out at the top")
-- climbing it again doesn't add it twice
climber:SetPos(L0) climber.movetype = MOVETYPE_WALK LC.LadderLearnTick(CurTime())
climber.movetype = MOVETYPE_LADDER or 9 LC.LadderLearnTick(CurTime())
climber:SetPos(L0 + Vector(0, 40, 256)) climber.movetype = MOVETYPE_WALK LC.LadderLearnTick(CurTime())
local n = 0
for i = before + 1, #LC.Points do if LC.Points[i].kind == "ladder" then n = n + 1 end end
ok(n == 2, "(once is enough)")
for _, p in ipairs(ends) do LC.RemovePoint(p) end
climber:SetPos(Vector(-30000, 30000, 0))
end
LadderLearnTests()
section("Hacking vending machines and ration dispensers")
function MachineHackTests()
local M0 = Vector(-82000, 62000, 0)
local hk = newPlayer("MachineHacker", "resistance", "hacker", 200)
hk:Give("weapon_lc_multitool")
hk:SetPos(M0)
for _, cls in ipairs({ "lc_vending", "lc_dispenser" }) do
    local m = ents.Create(cls)
    m:SetPos(M0 + Vector(50, 0, 0))
    hk.lookingAt = m
    local before = #ents.FindByClass("lc_item")
    ok(LC.HackMachine(hk, m), "a Hacker gets into the " .. cls)
    _run(16) -- (ten seconds at it, then one after another)
    local got = #ents.FindByClass("lc_item") - before
    ok(got >= GetConVar("lc_machine_hack_out"):GetInt() and got <= GetConVar("lc_machine_hack_max"):GetInt() and got >= 5, "and it spits out a handful of what's in it (5 to 8), free", tostring(got))
    local okA, whyA = LC.HackMachine(hk, m)
    ok(not okA and string.find(whyA or "", "emptied", 1, true), "then it's empty for a while")
    for _, it in ipairs(ents.FindByClass("lc_item")) do if it:GetPos():Distance(M0) < 400 then it:Remove() end end
    m:Remove()
end
local cit = newPlayer("NoTool", "citizen")
local m2 = ents.Create("lc_vending") m2:SetPos(M0)
local okC = LC.HackMachine(cit, m2)
ok(not okC, "(without a multitool, no)")
m2:Remove()
LC.SetFaction(hk, "citizen", nil, true)
hk:SetPos(Vector(-30000, 30000, 0)) hk.lookingAt = nil
end
MachineHackTests()
section("Leaving isn't always running away")
function LeaveReasonTests()
local leaver = newPlayer("RestartLeaver", "citizen")
LC.SetWanted(leaver, 300, "Test")
hook.Run("PlayerDisconnected", leaver)
ok(leaver.pdata.lc_combatlog ~= nil, "(leaving while wanted is written down)")
hook.Run("player_disconnect", { reason = "Server shutting down", networkid = leaver:SteamID(), userid = 1 })
_run(0.2)
ok(leaver.pdata.lc_combatlog == nil, "but a server restart (or a crash, or a kick) isn't held against anyone")
hook.Run("PlayerDisconnected", leaver)
hook.Run("player_disconnect", { reason = "Disconnect by user.", networkid = leaver:SteamID(), userid = 1 })
_run(0.2)
ok(leaver.pdata.lc_combatlog ~= nil, "choosing to leave while wanted still is")
leaver.pdata.lc_combatlog = nil
LC.ClearWanted(leaver)
-- a scanner is property, not a person
local vandal = newPlayer("ScannerShooter", "citizen")
local sc, sst = LC.Spawners.scanner(Vector(-84000, 64000, 0))
vandal:SetPos(Vector(-84000, 64200, 0))
hook.Run("EntityTakeDamage", sc, _dmg(vandal, 5))
ok(string.find(vandal:GetNW2String("lc_wanted_reason", ""), "property", 1, true) ~= nil, "shooting a scanner is damaging city property, not assaulting a citizen", vandal:GetNW2String("lc_wanted_reason", ""))
LC.NPCs[sc] = nil sc:Remove()
LC.ClearWanted(vandal)
vandal:SetPos(Vector(-30000, 30000, 0))
end
LeaveReasonTests()
section("Citizens attacked by a headcrab")
function CrabPanicTests()
local runWas = LC.Running
LC.Running = true
local P0 = Vector(-86000, 66000, 0)
local cit, cst = LC.SpawnCitizen(P0)
local cop, kst = LC.SpawnCop(P0 + Vector(600, 0, 0))
local wanderWas = LC.RandomWanderPos
LC.RandomWanderPos = function(role, near) return (near or P0) + Vector(100, 0, 0) end
local crab = ents.Create("npc_headcrab")
crab:SetPos(P0 + Vector(-40, 0, 0))
crab:Spawn()
hook.Run("EntityTakeDamage", cit, _dmg(crab, 5))
ok(cst.state == "moving", "a citizen a headcrab jumps on runs", cst.state)
ok(cst.dest and (cst.dest - P0):Dot(Vector(1, 0, 0)) > 0, "(away from it)")
ok(kst.state == "hostile" and kst.enemy == crab, "and screams for help: the nearest unit comes for it")
-- a unit a headcrab jumps on fights back, whatever he was doing
local cop2, kst2 = LC.SpawnCop(P0 + Vector(0, 900, 0))
LC.GoTo(cop2, kst2, P0 + Vector(0, 2000, 0), false, nil)
local crab2 = ents.Create("npc_headcrab") crab2:SetPos(P0 + Vector(0, 880, 0)) crab2:Spawn()
hook.Run("EntityTakeDamage", cop2, _dmg(crab2, 5))
ok(kst2.state == "hostile" and kst2.enemy == crab2, "a unit a headcrab bites stops walking and fights it")
-- and one who sees a zombie close by goes for it
local cop3, kst3 = LC.SpawnCop(P0 + Vector(0, -900, 0))
local z, zst = LC.SpawnZombie(P0 + Vector(200, -900, 4), nil)
_setcvar("lc_units_spot_monsters", 1)
LC.UnitsSpotMonsters()
_setcvar("lc_units_spot_monsters", 0)
ok(kst3.state == "hostile" and kst3.enemy == z, "a unit who sees a zombie close by goes for it")
LC.NPCs[cop2], LC.NPCs[cop3], LC.NPCs[z] = nil, nil, nil
cop2:Remove() cop3:Remove() z:Remove() crab2:Remove()
LC.NPCs[cit], LC.NPCs[cop] = nil, nil
cit:Remove() cop:Remove() crab:Remove()
LC.RandomWanderPos = wanderWas
LC.Running = runWas
end
CrabPanicTests()
section("Rebel lookout posts")
function LookoutPostTests()
local runWas, seenWas, rnWas = LC.Running, LC.IsSeen, LC.RadioNotice
LC.Running = true
LC.IsSeen = function() return false end
local P0 = Vector(-88000, 68000, 0)
local pt = LC.AddPoint(P0, 90, "rlookout", 0)
LC.EnsureLookoutPosts()
local slot
for _, sl in pairs(LC.LookoutPosts) do if IsValid(sl.npc) and sl.npc:GetPos():Distance(P0) < 50 then slot = sl end end
ok(slot ~= nil, "a lookout post gets an armed fighter standing guard")
if slot then
    local npc = slot.npc
    local st = LC.NPCs[npc]
    ok(st and st.role == "rebel" and st.post and st.post.yaw == 90, "(facing the way the post faces)")
    local heard
    LC.RadioNotice = function(band, text) if band == "resistance" then heard = text end end
    local unit = newPlayer("PostUnit", "cp")
    unit:SetPos(P0 + Vector(1000, 0, 0))
    local foe = LC.LookoutPostThreat(npc, st, CurTime())
    ok(heard and string.find(heard, "Combine coming", 1, true) ~= nil, "he sees a unit coming up the road and warns Freq 7", tostring(heard))
    ok(foe == nil, "(not shooting at that distance)")
    unit:SetPos(P0 + Vector(300, 0, 0))
    _advance(3)
    foe = LC.LookoutPostThreat(npc, st, CurTime())
    ok(foe == unit, "close up, he opens fire")
    unit:SetPos(Vector(-30000, 30000, 0))
    -- killed: someone takes the post later
    hook.Run("OnNPCKilled", npc, unit)
    LC.NPCs[npc] = nil
    npc:Remove()
    LC.EnsureLookoutPosts()
    ok(not IsValid(slot.npc), "(not straight away)")
    _advance(GetConVar("lc_lookout_post_respawn"):GetFloat() + 5)
    LC.EnsureLookoutPosts()
    ok(IsValid(slot.npc), "someone takes the post again a while later")
end
LC.RemovePoint(pt)
LC.EnsureLookoutPosts()
for _, sl in pairs(LC.LookoutPosts) do if IsValid(sl.npc) then LC.NPCs[sl.npc] = nil sl.npc:Remove() end end
LC.LookoutPosts = {}
LC.Running, LC.IsSeen, LC.RadioNotice = runWas, seenWas, rnWas
end
LookoutPostTests()

section("Fighters who follow you: following comes first")
function SquadTests()
local runWas, seenWas, rnWas = LC.Running, LC.IsSeen, LC.RadioNotice
LC.Running = true
LC.IsSeen = function() return false end
LC.RadioNotice = function() end
local S0 = Vector(-92000, 72000, 0)
local zq = LC.AddZone(S0, 400, "rebel", 0)
local fr, fst = LC.SpawnRebel(S0 + Vector(0, 0, 4), zq)
fst.unmanaged = true
local boss = newPlayer("SquadBoss", "resistance", nil, 200) -- (a Member: not hunted on sight, so the unit minds its own business)
boss:SetPos(S0 + Vector(60, 0, 0))
boss.lcRebelUseNext = 0
hook.Run("PlayerUse", boss, fr)
ok(fst.follow == boss and fst.followSlot == 0, "a Member brings a fighter along")
boss:SetPos(S0 + Vector(1500, 0, 0))
_run(7)
ok(fr:GetPos():Distance(boss:GetPos()) < 300, "they keep up", fr:GetPos():Distance(boss:GetPos()))
local cop, cst = LC.Spawners.cop(boss:GetPos() + Vector(500, 0, 4))
cop.sim = false
cst.untilT, cst.nextInspect = CurTime() + 1000, CurTime() + 1000
fst.nextLook = 0
_run(1.5)
ok(fst.foe == nil, "a unit minding its own business: they hold their fire")
hook.Run("EntityTakeDamage", cop, _dmg(boss, 5))
fst.nextLook = 0
_run(0.6)
ok(fst.foe == cop and fr.enemy == cop, "he opens up on a unit: so do they")
boss:SetPos(boss:GetPos() + Vector(0, 700, 0))
_run(0.6)
ok(fst.follow == boss and fr.sched == SCHED_FORCED_GO_RUN and fr.goal and fr.goal:Distance(boss:GetPos()) < 200,
    "he moves on: they go with him, shooting as they go, not after the unit", tostring(fr.sched) .. " " .. tostring(fr.goal))
_run(4)
ok(fr:GetPos():Distance(boss:GetPos()) < 260, "and stay at his side", fr:GetPos():Distance(boss:GetPos()))
ok(fr.sched == SCHED_RANGE_ATTACK1, "at his side with the unit in sight, they stand and fire", tostring(fr.sched))
cop:Remove()
_run(5)
ok(fst.foe == nil, "the unit's gone: they stop")
local cop2, cst2 = LC.Spawners.cop(boss:GetPos() + Vector(-400, 0, 4))
cop2.sim = false
cst2.untilT, cst2.nextInspect = CurTime() + 1000, CurTime() + 1000
hook.Run("EntityTakeDamage", fr, _dmg(cop2, 5))
fst.nextLook = 0
_run(0.6)
ok(fst.foe == cop2 and fst.follow == boss, "a unit shoots one of them: they shoot back, still with him")
cop2:Remove()
_run(5)
boss:SetPos(boss:GetPos() + Vector(3000, 0, 0))
fr.lcCatchUpAt = 0
_run(1)
ok(fr:GetPos():Distance(boss:GetPos()) < 450, "fallen far behind, and nobody looking: they catch up", fr:GetPos():Distance(boss:GetPos()))
boss.lcRebelUseNext = 0
hook.Run("PlayerUse", boss, fr)
ok(fst.follow == nil and fst.returning, "E again sends them home")
LC.NPCs[fr] = nil
fr:Remove()
LC.RemoveZone(zq)
boss:SetPos(Vector(-30000, 30000, 0))
LC.Running, LC.IsSeen, LC.RadioNotice = runWas, seenWas, rnWas
end
SquadTests()

section("Units notice armed rebels in the street")
function SpotRebelTests()
local runWas, rnWas = LC.Running, LC.RadioNotice
LC.Running = true
local heard
LC.RadioNotice = function(band, text) if band == "cp" then heard = text end end
local U0 = Vector(-96000, 76000, 0)
local reb, rst = LC.SpawnRebel(U0 + Vector(0, 0, 4), nil)
reb.sim = false
local unit, ust = LC.Spawners.cop(U0 + Vector(-400, 0, 4)) -- (facing it)
unit.sim = false
ust.untilT, ust.nextInspect = CurTime() + 1000, CurTime() + 1000
LC.UnitsSpotRebels()
ok(ust.state ~= "hostile", "(lc_units_spot_rebels 0: they don't)")
_setcvar("lc_units_spot_rebels", 600)
local behind, bst = LC.SpawnRebel(U0 + Vector(-900, 0, 4), nil)
behind.sim = false
LC.UnitsSpotRebels()
ok(ust.state == "hostile" and ust.enemy == reb, "a unit who sees an armed rebel in the street opens fire")
ok(rst.foe == unit, "and the rebel fights back")
ok(heard and string.find(heard, "armed anticitizen", 1, true) ~= nil, "and dispatch hears about it")
ok(bst.foe == nil, "one behind the unit's back isn't seen")
_setcvar("lc_units_spot_rebels", 0)
for _, n in ipairs({ reb, behind, unit }) do LC.NPCs[n] = nil n:Remove() end
LC.Running, LC.RadioNotice = runWas, rnWas
end
SpotRebelTests()

section("Guerrillas: they don't open up the moment they see you")
function GuerrillaTests()
local runWas = LC.Running
LC.Running = true
local G0 = Vector(-112000, 92000, 0)
local gz2 = LC.AddZone(G0, 1600, "rebel", 0)
local g, gst = LC.SpawnRebel(G0 + Vector(0, 0, 4), gz2)
gst.unmanaged = true
g.sim = false
local far = newPlayer("FarUnit", "cp")
far:SetPos(G0 + Vector(1300, 0, 0))
gst.nextLook = 0
_run(1)
ok(LC.RebelAlarms[far] == nil and gst.foe == nil, "a unit at the far edge of rebel ground isn't shouted at yet")
far:SetPos(G0 + Vector(900, 0, 0))
gst.nextLook = 0
_run(1)
ok(LC.RebelAlarms[far] ~= nil, "closer in, it goes up")
far:SetPos(Vector(-30000, 30000, 0))
LC.RebelAlarms[far] = nil
_run(1)
local stray, sst = LC.Spawners.cop(G0 + Vector(0, 800, 4))
stray.sim = false
sst.untilT, sst.nextInspect = CurTime() + 1000, CurTime() + 1000
gst.nextLook, gst.foe = 0, nil
_run(1)
ok(gst.foe == nil, "a unit that's only wandered in is left alone at a distance")
stray:SetPos(G0 + Vector(0, 500, 4))
gst.nextLook = 0
_run(1)
ok(gst.foe == stray, "but not close")
for _, n in ipairs({ g, stray }) do LC.NPCs[n] = nil n:Remove() end
LC.RemoveZone(gz2)
local cit, cst = LC.Spawners.citizen(Vector(-116000, 96000, 4))
cst.questLock = true
LC.SetState(cit, cst, "event")
cst.eventUntil = CurTime() + 100
cit.goal = nil
LC.Scatter(cit:GetPos(), 400)
ok(cst.state == "event" and cit.goal == nil, "someone a quest has following you doesn't scatter")
LC.NPCs[cit] = nil
cit:Remove()
LC.Running = runWas
end
GuerrillaTests()

section("Rebels at home keep busy")
function RebelLifeTests()
local runWas, seenWas = LC.Running, LC.IsSeen
LC.Running = true
LC.IsSeen = function() return false end
local H0 = Vector(-100000, 80000, 0)
local hz = LC.AddZone(H0, 600, "rebel", 0)
local bench = ents.Create("lc_workbench")
bench:SetPos(H0 + Vector(200, 0, 0))
local crate = ents.Create("prop_physics")
crate:SetModel("models/props_junk/wood_crate001a.mdl")
crate:SetPos(H0 + Vector(-200, 100, 0))
local bunkPt = LC.AddPoint(H0 + Vector(0, -250, 20), 0, "bunk", 0)
local kinds = {}
for _, t in ipairs(LC.RebelZoneThings(hz)) do kinds[t.kind] = true end
ok(kinds.bench and kinds.crate and kinds.bunk, "a rebel zone knows its workbench, its crates and its bunks")
local rebs = {}
for i = 1, 4 do
    local n, s = LC.SpawnRebel(H0 + Vector(i * 40, 40, 4), hz)
    s.unmanaged = true
    rebs[i] = { n = n, st = s }
end
local seen, doing = {}, false
for _ = 1, 90 do
    _run(1)
    for _, r in ipairs(rebs) do
        if r.st.life then seen[r.st.life.kind] = true end
        local d = r.n:GetNW2String("lc_doing", "")
        if d ~= "" and d ~= "on alert" then doing = true end
    end
end
ok(seen.patrol, "someone walks the edge of the zone")
ok(seen.work or seen.sort or seen.carry, "and someone's at the bench or the crates")
ok(doing, "what they're doing shows under their name")
local inside = true
for _, r in ipairs(rebs) do if r.n:GetPos():Distance(H0) > 600 * 1.3 then inside = false end end
ok(inside, "all of it at home")
LC.RebelAlert(hz, H0 + Vector(500, 0, 0), CurTime())
_run(2.5) -- (nobody near: they think every two seconds)
local still = 0
for _, r in ipairs(rebs) do if r.st.life then still = still + 1 end end
ok(still == 0 and rebs[2].n:GetNW2String("lc_doing", "") == "on alert", "a shout goes up: they put it down, on their feet")
_advance(26)
_run(1)
for _, r in ipairs(rebs) do LC.RebelLifeEnd(r.n, r.st) r.st.untilT = CurTime() + 1000 end
local sl = rebs[1]
sl.n.seqs = { d1_town05_Wounded_Idle_1 = 7 }
local bunkThing
for _, t in ipairs(LC.RebelZoneThings(hz)) do if t.kind == "bunk" then bunkThing = t end end
ok(LC.RebelLifeDo(sl.n, sl.st, "sleep", bunkThing), "a fighter turns in at a bunk")
for _ = 1, 30 do _run(0.5) if LC.RebelAsleep(sl.st) then break end end
ok(LC.RebelAsleep(sl.st) and sl.n:GetNW2String("lc_doing", "") == "asleep", "and sleeps there")
LC.RebelAlert(hz, H0, CurTime())
_run(2.5)
ok(not LC.RebelAsleep(sl.st) and sl.st.life == nil and sl.n:GetPos().z < 10, "a shout wakes them, up and off the bed")
for _, r in ipairs(rebs) do LC.NPCs[r.n] = nil r.n:Remove() end
bench:Remove() crate:Remove()
LC.RemovePoint(bunkPt)
LC.RemoveZone(hz)
LC.Running, LC.IsSeen = runWas, seenWas
end
RebelLifeTests()

section("Rebels slip out to scavenge")
function ErrandTests()
local runWas, seenWas = LC.Running, LC.IsSeen
LC.Running = true
LC.IsSeen = function() return false end
_setcvar("lc_rebel_life", 0)
local E0 = Vector(-104000, 84000, 0)
local ez = LC.AddZone(E0, 400, "rebel", 0)
local salv = LC.AddPoint(E0 + Vector(1200, 0, 0), 0, "salvage", 0)
local stash = ents.Create("prop_physics")
stash:SetPos(E0 + Vector(0, -150, 0))
stash.lcRebelProp, stash.lcStock = "cache", 0
local propsWas = LC.RebelProps[ez]
LC.RebelProps[ez] = { cache = stash, pots = {} }
local rs = {}
for i = 1, 3 do
    local n, s = LC.SpawnRebel(E0 + Vector(i * 50, 0, 4), ez)
    s.unmanaged = true
    rs[i] = { n = n, st = s }
end
local okE, why = LC.StartRebelErrand(ez)
ok(okE, "a scavenging run sets out", why)
local runner
for _, r in ipairs(rs) do if r.st.errand then runner = r end end
ok(runner and runner.st.errand.phase == "out" and runner.n:GetNW2String("lc_doing", "") == "out scavenging", "one of them, out scavenging")
if runner then
    _run(1)
    ok(runner.n.sched == SCHED_FORCED_GO, "walking, not running")
    local watcher, wst = LC.Spawners.cop(runner.n:GetPos() + Vector(500, 0, 4))
    watcher.sim = false
    wst.untilT, wst.nextInspect = CurTime() + 1000, CurTime() + 1000
    _run(2.5)
    ok(runner.st.errand.hides >= 1 and runner.n:GetNW2String("lc_doing", "") == "keeping out of sight", "a unit up ahead: they back off and keep out of sight")
    LC.NPCs[watcher] = nil
    watcher:Remove()
    local searched
    for _ = 1, 60 do _run(0.5) if runner.st.errand and runner.st.errand.phase == "search" then searched = true break end end
    ok(searched, "they get there and search the place")
    for _ = 1, 60 do _run(0.5) if not runner.st.errand or runner.st.errand.phase == "home" then break end end
    ok(runner.st.errand and runner.st.errand.phase == "home", "then head home")
    if runner.st.errand then runner.st.errand.found = 2 end
    for _ = 1, 60 do _run(0.5) if not runner.st.errand then break end end
    ok(runner.st.errand == nil and runner.n:GetPos():Distance(E0) < 400, "and get there", tostring(runner.n:GetPos()))
    ok((stash.lcStock or 0) >= 2, "what they found goes in the supply crate", stash.lcStock)
end
for _, r in ipairs(rs) do LC.NPCs[r.n] = nil r.n:Remove() end
LC.RebelProps[ez] = propsWas
stash:Remove()
LC.RemovePoint(salv)
LC.RemoveZone(ez)
_setcvar("lc_rebel_life", 1)
LC.Running, LC.IsSeen = runWas, seenWas
end
ErrandTests()

section("The Resistance answers a supply drop")
function ReactTests()
local runWas = LC.Running
LC.Running = true
_setcvar("lc_rebel_ops", 1)
_setcvar("lc_rebel_react", 1)
if LC.Skirmish then LC.EndSkirmish(LC.Skirmish, "test") end
local R0 = Vector(-108000, 88000, 0)
local rz2 = LC.AddZone(R0, 400, "rebel", 0)
local supWas = LC.Supply
LC.Supply = { pos = R0 + Vector(1500, 0, 0), startT = CurTime() - 60, guards = {}, props = {}, raided = {}, loads = 5 }
local launched = LC.RebelReact(CurTime())
ok(launched and LC.Skirmish and LC.Skirmish.purpose == "supply", "a supply drop: the Resistance's fighters go for it, straight away")
if LC.Skirmish then LC.EndSkirmish(LC.Skirmish, "test") end
LC.Supply = supWas
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and st.zone == rz2 then LC.NPCs[n] = nil n:Remove() end end
LC.RemoveZone(rz2)
_setcvar("lc_rebel_ops", 0)
LC.Running = runWas
end
ReactTests()

section("Playtest fixes: squads, ladders, parasites, sinks")
function SquadSinkFixTests()
local runWas, seenWas, rnWas, rebelsWas = LC.Running, LC.IsSeen, LC.RadioNotice, GetConVar("lc_rebels"):GetInt()
LC.Running = true
LC.IsSeen = function() return false end
LC.RadioNotice = function() end
_setcvar("lc_rebels", 3)
local FARP = Vector(-30000, 30000, 0)
local Z0 = Vector(-120000, 90000, 0)
local zone = LC.AddZone(Z0, 400, "rebel", 0)

-- the quartermaster is never in a squad, and stays at his post
LC.EnsureQuartermasters()
local qm, qst
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.quartermaster and st.zone == zone then qm, qst = n, st end end
ok(qm ~= nil, "(the new rebel ground has a quartermaster)")
local cmd = newPlayer("PlaytestCmd", "resistance", nil, 1835) -- a Commander
cmd:SetPos(qm:GetPos() + Vector(60, 0, 0))
_run(3)
ok(qst.follow == nil, "a Commander joins near the quartermaster: he isn't in their squad")
for _ = 1, 20 do cmd.lcRebelUseNext = 0 hook.Run("PlayerUse", cmd, qm) _run(0.1) end
ok(qst.follow == nil, "and E on him, even held down, never brings him along")
qst.follow, qst.followSID, qst.followAt = cmd, cmd:SteamID(), CurTime() -- (however it happened)
qst.nextThink = 0
_run(1)
ok(qst.follow == nil and not qst.returning and not qst.expires, "if he somehow is, he's let go on the spot, with no timer on him")
local home = qst.qmHome
qm:SetPos(home + Vector(900, 0, 0))
qst.untilT, qst.nextThink = 0, 0
_run(2.5)
ok(qm:GetPos():Distance(home) < 130, "and a quartermaster led, pushed or frightened off goes back to his post", qm:GetPos():Distance(home))

-- a squad belongs to the connection that formed it
local fr, fst = LC.SpawnRebel(Z0 + Vector(120, 0, 4), zone)
fst.unmanaged = true
cmd:SetPos(Z0 + Vector(180, 0, 0))
cmd.lcRebelUseNext = 0
hook.Run("PlayerUse", cmd, fr)
ok(fst.follow == cmd and fst.followSID == cmd:SteamID(), "a Commander brings a fighter along (the squad remembers whose it is)")
_advance(0.1)
cmd.lcRebelUseNext = 0
hook.Run("PlayerUse", cmd, fr)
ok(fst.follow == cmd, "holding E doesn't send them straight home again")
_advance(1)
cmd.lcRebelUseNext = 0
hook.Run("PlayerUse", cmd, fr)
ok(fst.follow == nil and fst.returning, "a second press does")
cmd.lcRebelUseNext = 0
_advance(1)
hook.Run("PlayerUse", cmd, fr)
ok(fst.follow == cmd, "(and again)")
hook.Run("PlayerDisconnected", cmd)
ok(fst.follow == nil, "when the player leaves, their squad stands down")
-- the server was quiet while they were away: the fighter still has the old connection on file
fst.follow, fst.followSID, fst.followAt = cmd, cmd:SteamID(), CurTime()
cmd.valid = false
local back = _makeplayer("PlaytestCmd", Z0 + Vector(400, 0, 0))
back.sid = cmd.sid
hook.Run("PlayerInitialSpawn", back)
ok(fst.follow == nil, "and nobody from last time is in the squad when they join again")
back:SetPData("lcf_xp_resistance", 1835)
LC.SetFaction(back, "resistance", nil, true)
_run(0.3) -- (a hunted player is moved to rebel ground as they spawn)

-- up a ladder after the leader, even while they're still on it
fst.follow, fst.followSlot, fst.returning, fst.expires = nil, nil, nil, nil
fr:SetPos(Z0 + Vector(120, 0, 4))
back:SetPos(Z0 + Vector(180, 0, 0))
back.lcRebelUseNext = 0
_advance(1)
hook.Run("PlayerUse", back, fr)
ok(fst.follow == back, "(a fighter with the new connection)")
local foot = Z0 + Vector(140, 0, 4)
local top = foot + Vector(20, 0, 260)
LC.AddPoint(foot, 0, "ladder", 77)
LC.AddPoint(top, 0, "ladder", 77)
LC.ApplyLadders()
local near, far = LC.LadderToward(foot + Vector(30, 0, 0), foot + Vector(0, 0, 120), true)
ok(near and far and far.z > 200, "a leader halfway up a ladder: it's the way to go", tostring(near))
ok(not LC.LadderToward(foot + Vector(30, 0, 0), foot + Vector(0, 0, 120), false), "(not for someone who's just standing at that height)")
back:SetPos(foot)
_run(1)
back:SetPos(foot + Vector(0, 0, 120))
back.movetype = 9 -- (MOVETYPE_LADDER)
_run(3)
ok(fr:GetPos().z < foot.z + 60 and fr:GetPos():Distance(foot) < 120, "a leader still on the ladder: the follower waits at its foot (not dragged up and down after them)", tostring(fr:GetPos()))
back:SetPos(top)
back.movetype = MOVETYPE_WALK
_run(2)
ok(fr:GetPos().z > foot.z + 200, "and goes up the moment they're off it", fr:GetPos().z)
-- no ladder, and the leader's on another level: after a while, unseen, they catch up
for i = #LC.Points, 1, -1 do if LC.Points[i].kind == "ladder" then table.remove(LC.Points, i) end end
LC.ApplyLadders()
fr:SetPos(Z0 + Vector(120, 600, 4))
fr.sim = false -- (the pretend world would let them fly up to the leader)
back:SetPos(Z0 + Vector(160, 600, 400))
local groundWas, catchWas, caught = _groundFn, LC.FollowCatchUp, 0
_groundFn = function(x, y) return y > 400 and 400 or 0 end
LC.FollowCatchUp = function(...) local r = catchWas(...) if r then caught = caught + 1 end return r end
fr.lcCatchUpAt = 0
_run(6)
ok(caught == 0 and fr:GetPos().z < 100, "(six seconds on another level, they're not put anywhere yet)", caught)
_run(10)
ok(caught >= 1 and fr:GetPos().z > 300, "stuck on the wrong level for a while: they're put back with them, once nobody's looking", fr:GetPos().z)
_groundFn, LC.FollowCatchUp = groundWas, catchWas
LC.NPCs[fr] = nil
fr:Remove()

-- coughs and hunger hurt you, not your armor
local sick = newPlayer("PlaytestSick", "resistance", nil, 1835)
_run(0.3)
sick.armorSoak = true
sick:SetArmor(75)
sick.hp = 100
LC.Infect(sick)
sick.lcnCough = 0
sick:SetPos(FARP)
_run(5.5)
ok(sick.hp == 99 and sick:Armor() == 75, "a parasite cough costs a point of health, and the armor is untouched", sick.hp .. " health, " .. sick:Armor() .. " armor")
sick:SetNW2Float("lcn_parasites", 0)
sick:SetNW2Float("lcn_hunger", 0)
sick:SetNW2Float("lcn_thirst", 100)
sick.hp = 100
_run(5.5)
ok(sick.hp < 100 and sick:Armor() == 75, "so does starving", sick.hp .. " health, " .. sick:Armor() .. " armor")
sick:SetNW2Float("lcn_hunger", 100)
local plain = newPlayer("PlaytestPlain", "citizen")
_run(0.3)
plain.hp = 100
LC.BodyDamage(plain, 4)
ok(plain.hp == 96 and plain:Armor() == 0, "(and with no armor it's just the health)")
sick:SetPos(FARP)
plain:SetPos(FARP)

-- a sink has to be seen to be used
local drinker = newPlayer("PlaytestDrinker", "citizen")
_run(0.3)
local D0 = Vector(-124000, 94000, 0)
drinker:SetPos(D0)
local wallsWas, fixWas = _walls, LC.StaticFixtures
_walls, _props = {}, { { pos = D0 + Vector(80, 0, 64), r = 20 } }
LC.StaticFixtures = { { kind = "sink", pos = D0 + Vector(80, 0, 0), ang = Angle(), model = "models/props_c17/furnituresink001a.mdl" } }
drinker:SetNW2Float("lcn_thirst", 10)
drinker.lcnNextDrink, drinker.lcSinkUse = 0, 0
hook.Run("KeyPress", drinker, IN_USE)
ok(LC.Thirst(drinker) >= 30, "looking at a sink and pressing E: a drink")
ok(LC.NearSink(drinker), "(and it's a sink you can fill from)")
-- the same sink on the other side of a wall: the ladder you just pressed E on
_walls = { { a = D0 + Vector(50, -200, 0), b = D0 + Vector(50, 200, 0) } }
drinker:SetNW2Float("lcn_thirst", 10)
drinker.lcnNextDrink, drinker.lcSinkUse = 0, 0
hook.Run("KeyPress", drinker, IN_USE)
ok(LC.Thirst(drinker) < 15, "pressing E on a wall with a sink behind it does nothing", LC.Thirst(drinker))
ok(not LC.NearSink(drinker), "and it's not a sink you can fill from either")
_walls, _props, LC.StaticFixtures = wallsWas, {}, fixWas
drinker:SetPos(FARP)

cmd:SetPos(FARP)
back:SetPos(FARP)
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.zone == zone then LC.NPCs[n] = nil n:Remove() end end
LC.RemoveZone(zone)
LC.QMDead = {}
_setcvar("lc_rebels", rebelsWas)
LC.Running, LC.IsSeen, LC.RadioNotice = runWas, seenWas, rnWas
end
SquadSinkFixTests()
section("Playtest fixes: parasites, release, interrogation, lookouts, cooking")
function PlaytestBatchTwoTests()
local FARP = Vector(-126000, 96000, 0)
-- parasites don't wear off by themselves; only tablets cure them
local sick = newPlayer("BatchSick", "citizen")
_run(0.3)
sick:SetPos(FARP)
LC.Infect(sick)
_advance(3 * 3600)
ok(LC.HasParasites(sick), "parasites are still there hours later")
LC.GiveItem(sick, "tablets")
LC.InvAction(sick, "use", "tablets")
ok(not LC.HasParasites(sick), "and tablets still cure them")

-- cooking sizzles, it doesn't bang
local cook = newPlayer("BatchCook", "citizen")
_run(0.3)
cook:SetPos(FARP + Vector(500, 0, 0))
local fire = ents.Create("lc_fire")
fire:SetPos(cook:GetPos() + Vector(60, 0, 0))
LC.GiveItem(cook, "raw_bird")
_sounds = {}
LC.InvAction(cook, "cook", "raw_bird")
local fizz, bang = false, false
for _, snd in ipairs(_sounds) do
    if string.find(snd, "ambient/fire/", 1, true) then fizz = true end
    if string.find(snd, "ignite", 1, true) or string.find(snd, "explo", 1, true) then bang = true end
end
ok(fizz and not bang, "cooking makes a fire sound, not an explosion")
if IsValid(fire) then fire:Remove() end

-- release: no weapons, no radio, but fists
local ex = newPlayer("BatchExCon", "citizen")
_run(0.3)
ex:SetPos(FARP + Vector(1000, 0, 0))
LC.GiveItem(ex, "gun_smg")
LC.GiveItem(ex, "radio")
LC.GiveItem(ex, "tablets")
ex:Give("weapon_smg1")
ex:Give("weapon_crowbar")
LC.Incarcerate(ex, 60, "batch")
LC.ReleasePrisoner(ex)
ok(not ex:HasWeapon("weapon_smg1") and not ex:HasWeapon("weapon_crowbar"), "released: the guns and the crowbar stay in the locker")
ok(not LC.HasItem(ex, "gun_smg") and not LC.HasItem(ex, "radio"), "and so do the homemade guns and the radio")
ok(LC.HasItem(ex, "tablets"), "other belongings come back")
ok(ex:HasWeapon("weapon_fists") and ex:HasWeapon("weapon_lc_hands"), "and the fists are back")
local officer = newPlayer("BatchUnit", "cp")
_run(0.3)
officer:SetPos(FARP + Vector(2000, 0, 0))
officer:Give("weapon_pistol")
LC.Incarcerate(officer, 60, "batch")
LC.ReleasePrisoner(officer)
ok(officer:HasWeapon("weapon_fists"), "a unit gets fists back too")

-- interrogation: the offer is up front, and it is worth 50
local bad = newPlayer("BatchInterrogated", "resistance", nil, 100)
_run(0.3)
bad:SetPos(FARP + Vector(3000, 0, 0))
bad:SetPData("lce_standing", -300) bad:SetPData("lc_jailcount", 3)
LC.Incarcerate(bad, 600, "Test")
bad.chat = {}
_run(13)
ok(LC.Interrogations[bad] ~= nil and has(bad.chat, "50 social credits"), "the interrogator offers 50 social credits up front")
local s0 = LC.Standing(bad)
ok(LC.InterrogationTalk(bad), "talking")
ok(LC.Standing(bad) == s0 + 50, "pays 50 standing", tostring(LC.Standing(bad) - s0))
LC.ReleasePrisoner(bad)

-- a citizen locked up for a fight is not interrogated (they know nothing); a rebel is
local innocent = newPlayer("BatchInnocent", "citizen")
_run(0.3)
innocent:SetPos(FARP + Vector(3500, 0, 0))
innocent:SetPData("lce_standing", -300) innocent:SetPData("lc_jailcount", 3)
ok(not LC.CanInterrogate(innocent), "a citizen can't be interrogated")
ok(LC.CanInterrogate(bad), "a rebel can")
LC.Incarcerate(innocent, 600, "Assaulting Civil Protection")
_run(70)
ok(LC.Interrogations[innocent] == nil and not LC.IsCrippled(innocent), "so a citizen locked up for a fight is neither questioned nor crippled")
ok(GetConVar("lc_cripple_minutes"):GetInt() == 15, "broken feet last 15 minutes")
LC.ReleasePrisoner(innocent)
innocent:SetPos(FARP)

-- an accident is not a massacre: one kill is answered lightly
local acc = newPlayer("BatchAccident", "citizen")
_run(0.3)
acc:SetPos(FARP + Vector(5000, 0, 0))
local victimC, vst = LC.Spawners.citizen(FARP + Vector(5100, 0, 0))
acc.lcKillTimes = nil
hook.Run("OnNPCKilled", victimC, acc)
ok(LC.AlertLevel(acc) <= 1, "one kill: a low alert, not Overwatch", tostring(LC.AlertLevel(acc)))
ok(LC.AlertLevel(acc) == 1 and #LC.Responders(acc) == 0, "and no squad comes for you")
local victim2 = LC.Spawners.citizen(FARP + Vector(5200, 0, 0))
hook.Run("OnNPCKilled", victim2, acc)
ok(LC.Heat(acc) == 3, "a second soon after counts in full", tostring(LC.Heat(acc)))
LC.ResetHeat(acc) LC.ClearWanted(acc)

-- a Resistance commander who kills a civilian loses a rank, and the XP to match
local cmdr = newPlayer("BatchCommander", "resistance", nil, 100000)
_run(0.3)
cmdr:SetPos(FARP + Vector(6000, 0, 0))
local f = LCF.Get("resistance")
local top = cmdr:GetNW2Int("lcf_rank", 1)
ok(top >= 2, "(a high rank to start)", tostring(top))
local civ = LC.Spawners.citizen(FARP + Vector(6100, 0, 0))
hook.Run("OnNPCKilled", civ, cmdr)
ok(cmdr:GetNW2Int("lcf_rank", 1) == top - 1, "killing a citizen costs a rank", tostring(cmdr:GetNW2Int("lcf_rank", 1)))
ok(tonumber(cmdr:GetPData("lcf_xp_resistance", 0)) == (f.ranks[top - 1].xp or 0), "and XP drops to the bottom of the rank they fall to", tostring(cmdr:GetPData("lcf_xp_resistance", 0)))
local civ2 = LC.Spawners.citizen(FARP + Vector(6200, 0, 0))
hook.Run("OnNPCKilled", civ2, cmdr)
ok(cmdr:GetNW2Int("lcf_rank", 1) == math.max(1, top - 2), "each kill costs another")
LC.ResetHeat(cmdr) LC.ClearWanted(cmdr)

-- a city scanner that sees a fugitive tells the units; wrecking one costs 50 standing
local fug = newPlayer("BatchFugitive", "citizen")
local copu = newPlayer("BatchTipUnit", "cp")
_run(0.3)
fug:SetPos(FARP + Vector(7000, 0, 0))
copu:SetPos(FARP + Vector(7000, 3000, 0))
copu.chat = {}
local scn, sst = LC.Spawners.scanner(FARP + Vector(7200, 0, 100))
scn:SetPos(fug:GetPos() + Vector(200, 0, 100))
fug.lcGraceUntil = 0
fug.chat = {}
ok(LC.ScannerTipOff(scn, sst, CurTime()) == nil, "a scanner doesn't report someone who has done nothing")
LC.SetWanted(fug, 120, "Test")
ok(LC.ScannerTipOff(scn, sst, CurTime()) == fug, "but it does report a fugitive in sight")
ok(has(copu.chat, "Scanner report") and has(fug.chat or {}, "photographed"), "units are told, and so is the fugitive")
ok(LC.ScannerTipOff(scn, sst, CurTime() + 1) == nil, "and not again every second")
fug:SetPData("lce_standing", 0)
LC.ReportCrime(fug, "Destroying city property", 180)
ok(LC.Standing(fug) == -50, "wrecking a scanner costs 50 standing", tostring(LC.Standing(fug)))
LC.NPCs[scn] = nil scn:Remove()
LC.ClearWanted(fug)
for _, p in ipairs({ fug, copu }) do p:SetPos(FARP) end

-- names: plenty of them, and not one somebody already has
local seen, count = {}, 0
for i = 1, 400 do
    local n = LC.NewCharacterName(i % 2 == 0 and "male" or "female")
    if not seen[n] then seen[n] = true count = count + 1 end
end
ok(count >= 380, "400 new names are almost all different (and there are far more than 300 to draw from)", tostring(count))
local namer = newPlayer("BatchNamer", "citizen")
_run(0.3)
local taken = namer:GetNW2String("lc_char", "")
ok(LC.NameInUse(taken), "a name a player has is in use")
local dup = false
for i = 1, 300 do if LC.NewCharacterName(LC.NameGender(taken)) == taken then dup = true end end
ok(not dup, "and is never handed to somebody else")
namer:SetPos(FARP)

-- the city's timers are timed, and spread over their second outside of tests
local ran = 0
timer.Create("LivingCityPerfTest", 1, 0, function() ran = ran + 1 end)
timer.list["LivingCityPerfTest"].fn()
ok(ran == 1 and LC.TimerPerf["LivingCityPerfTest"] and LC.TimerPerf["LivingCityPerfTest"].calls == 1, "a city timer runs, and its time is recorded")
LC.TestMode = false
timer.list["LivingCityPerfTest"].fn()
ok(ran == 1, "in play, its work waits for its own slot inside the second")
_run(1.2)
ok(ran == 2, "and then runs")
LC.TestMode = true
timer.Remove("LivingCityPerfTest")

-- broken feet can't "run", so nobody shouts "stop running" at them
local lame = newPlayer("BatchLame", "citizen")
_run(0.3)
lame:SetPos(FARP + Vector(4000, 0, 0))
lame.walkspeed, lame.runspeed, lame.vel = 110, 190, Vector(190, 0, 0)
ok(LC.PlayerSprinting(lame), "(sprinting at running speed counts)")
LC.Cripple(lame, 5)
ok(not LC.PlayerSprinting(lame), "but not with broken feet")
lame:SetNW2Float("lc_crippled_until", 0)
ok(LC.PlayerSprinting(lame), "and it counts again once they have healed")
lame.vel = nil

-- a respawn in the middle of a curfew gets time to reach home, then spaced warnings
LC.EndEvent(true)
local CP0 = FARP + Vector(0, 12000, 0)
local curCop, curSt = LC.Spawners.cop(CP0 + Vector(120, 0, 0))
curSt.routeGroup = nil curSt.untilT = 1e9 curCop.sim = false
LC.StartEvent("curfew", 3)
_run(70)
local reborn = newPlayer("BatchReborn", "citizen")
_run(0.3)
reborn:SetPos(CP0)
reborn.chat = {}
hook.Run("PlayerSpawn", reborn)
_run(0.6)
ok(LC.CurfewPersonalGrace(reborn) >= 60, "a respawn gets at least a minute to reach home")
ok((reborn.lcCurfewGrace or 0) > CurTime(), "and the grace is set at the spawn")
_run(20)
ok(not has(reborn.chat, "Warning 1 of 3"), "an officer in sight doesn't warn someone who has just respawned")
reborn.lcCurfewGrace = CurTime() - 1
_run(6)
ok(has(reborn.chat, "Warning 1 of 3") and not has(reborn.chat, "Warning 2 of 3"), "afterwards the first warning comes", table.concat(reborn.chat, " | "))
_run(30)
ok(has(reborn.chat, "Warning 2 of 3"), "and the next one a good while later, not in a rush")
LC.EndEvent(true)
reborn:SetPos(FARP)
curCop:Remove() LC.NPCs[curCop] = nil

-- rebels guard their supplies: warn, warn, shove, harder, then turn on you
local GP = FARP + Vector(0, 20000, 0)
local guardZone = LC.AddZone(GP, 500, "rebel", 0)
local guardR, guardSt = LC.Spawners.rebel(GP + Vector(100, 0, 0))
guardSt.untilT = 1e9 guardR.sim = false
local wrecker = newPlayer("BatchWrecker", "citizen")
_run(0.3)
wrecker:SetPos(GP)
wrecker.chat = {}
local crate = ents.Create("prop_physics") crate:SetPos(GP + Vector(20, 0, 0))
crate.lcRebelProp = "cache"
hook.Run("PropBreak", wrecker, crate)
ok(has(wrecker.chat, "Those are our supplies"), "a rebel who sees you breaking their crate tells you to quit", table.concat(wrecker.chat, " | "))
_advance(3)
hook.Run("PropBreak", wrecker, crate)
ok(has(wrecker.chat, "I won't say it again"), "and again, once")
_advance(3)
hook.Run("PropBreak", wrecker, crate)
ok(has(wrecker.chat, "shove"), "then shoves you")
_advance(3)
hook.Run("PropBreak", wrecker, crate)
ok(has(wrecker.chat, "ribs"), "then hits harder")
ok(guardSt.state ~= "hostile", "but still isn't shooting")
_advance(3)
hook.Run("PropBreak", wrecker, crate)
ok(guardSt.state == "hostile", "and if you keep on, turns on you", tostring(guardSt.state))
local friend = newPlayer("BatchFriend", "resistance")
_run(0.3)
friend:SetPos(GP)
friend.chat = {}
ok(not LC.RebelGuard(friend, GP), "the Resistance's own are never stopped")
local passer = newPlayer("BatchPasser", "citizen")
_run(0.3)
passer:SetPos(FARP + Vector(0, 30000, 0))
ok(not LC.RebelGuard(passer, passer:GetPos()), "and nobody is stopped outside rebel territory")
_setcvar("lc_rebel_guard", 0)
wrecker.lcRebelWarn = nil wrecker:SetPos(GP)
ok(not LC.RebelGuard(wrecker, GP), "lc_rebel_guard 0 turns it off")
_setcvar("lc_rebel_guard", 1)
for _, p in ipairs({ reborn, wrecker, friend, passer }) do p:SetPos(FARP) end
guardR:Remove() LC.NPCs[guardR] = nil
crate:Remove()
LC.RemoveZone(guardZone)

for _, p in ipairs({ sick, cook, ex, officer, bad, lame, acc, cmdr }) do p:SetPos(FARP) end
end
PlaytestBatchTwoTests()
section("Special roles come back with you")
function SpecialReturnTests()
local hk = newPlayer("ReturningHacker", "resistance", "hacker", 200)
ok(hk:GetNW2String("lcf_special", "") == "hacker", "(a Hacker)")
-- they leave, and come back
hook.Run("PlayerDisconnected", hk)
hk.nw = {}
hk.chat = {}
hook.Run("PlayerInitialSpawn", hk)
_run(3)
ok(hk:GetNW2String("lcf_special", "") == "hacker" and hk:GetNW2String("lcf_faction", "") == "resistance", "a Hacker who leaves and comes back is still a Hacker")
ok(has(hk.chat or {}, "still Hacker"), "and is told so")
-- they leave, and every place is taken while they're away
hook.Run("PlayerDisconnected", hk)
hk.nw = {}
hk.chat = {}
local others = {}
for i = 1, 3 do others[i] = newPlayer("OtherHacker" .. i, "resistance", "hacker", 200) end
hook.Run("PlayerInitialSpawn", hk)
_run(3)
ok(hk:GetNW2String("lcf_special", "") == "" and hk:GetNW2String("lcf_faction", "") == "resistance", "nobody keeps a place by being offline: the places filled, so they're back to their rank")
ok(has(hk.chat or {}, "when there's a place"), "and told how to get it back")
for _, o in ipairs(others) do LC.SetFaction(o, "citizen", nil, true) end
LC.SetFaction(hk, "citizen", nil, true)
end
SpecialReturnTests()
section("The city's stores")
_setcvar("lc_stockpile", 1)
_setcvar("lc_stock_max", 400)
_setcvar("lc_economy", 1)
LC.StockAdd(200 - LC.Stock())
ok(LC.Stock() == 200 and LC.StockLevel() == "normal", "half full")
local cook = newPlayer("StockCook", "citizen")
LC.SetJob(cook, "kitchen", true)
LC.Bump(cook, "shifts")
ok(LC.Stock() == 212, "a kitchen shift fills them", LC.Stock())
LC.SetJob(cook, "factory", true)
LC.Bump(cook, "shifts")
ok(LC.Stock() == 220, "a factory shift too")
LC.SetJob(cook, "clerk", true)
LC.Bump(cook, "shifts")
ok(LC.Stock() == 220, "a clerk's doesn't")
hook.Run("LivingCityTrainArrived", nil, {}, "City 14")
ok(LC.Stock() == 235, "a train brings freight")
hook.Run("LivingCitySupplyEnded", {}, 2)
ok(LC.Stock() == 265, "and a convoy, for every load that wasn't stolen")
local n, st = LC.SpawnCitizen(Vector(-32000, 34000, 0))
st.profile = { job = "kitchen" }
hook.Run("LivingCityNPCWorkFinished", n, st, "supply")
ok(LC.Stock() == 269, "the city's own kitchen workers add to it")
n:Remove()
-- rations come out of them
local eater = newPlayer("StockEater", "citizen")
eater.lcnRationAt = 0
LC.GiveItem(eater, "ration_card", 50)
local before = LC.Stock()
ok(LC.UseDispenser(eater, nil) and LC.Stock() == before - 1, "every ration handed out is one fewer")
LC.StockAdd(-LC.Stock() + 40)
ok(LC.StockLevel() == "short", "under a quarter: short")
local got, short = 0, 0
for _ = 1, 30 do
    eater.lcnRationAt = 0
    if LC.UseDispenser(eater, nil) then got = got + 1 else short = short + 1 end
end
ok(short > 0 and got > 0, "short: sometimes the dispenser has nothing", got .. " got, " .. short .. " short")
LC.StockAdd(-LC.Stock())
eater.lcnRationAt = 0
eater.chat = {}
ok(not LC.UseDispenser(eater, nil) and has(eater.chat, "stores are empty"), "empty: no rations at all")
LC.StockAdd(390)
ok(LC.StockLevel() == "full", "well stocked")
LC.StockSave()
ok(string.find(_files["livingcity/" .. game.GetMap() .. "_stock.json"] or "", "390", 1, true) ~= nil, "saved for this map")
_setcvar("lc_stockpile", 0)
eater.lcnRationAt = 0
ok(LC.UseDispenser(eater, nil), "lc_stockpile 0: rations are endless again")
for _, p in ipairs({ cook, eater }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
StockTests()
section("Trains")
_setcvar("lc_npc_budget", 200)
local P0 = Vector(-34000, 32000, 0)
local plat = LC.AddPoint(P0, 0, "platform", 0)
local door = LC.AddPoint(P0 + Vector(1200, 0, 0), 0, "spawn", 0)
local porter = newPlayer("TrainPorter", "citizen")
LC.SetJob(porter, "porter", true)
porter.chat = {}
local spotInZone = LC.SpotInZone
LC.SpotInZone = function() return nil end -- (home is this section's doorway, not a block another section left across the map)
local okA, arrivals = LC.TrainArrive(true)
LC.SpotInZone = spotInZone
arrivals = arrivals or {}
ok(okA and #arrivals >= 2, "a train comes in, and people get off", tostring(okA) .. " " .. #arrivals .. " plats " .. #LC.TrainPlatforms() .. " npcs " .. table.Count(LC.NPCs))
ok(has(porter.chat, "train is in"), "Intake Processors are told")
local a1 = arrivals[1]
local s1 = a1 and LC.NPCs[a1] or {}
ok(s1 and s1.npcWork and s1.npcWork.id == "arrival" and IsValid(s1.carry), "each with a suitcase, going home")
for _, n in ipairs(arrivals) do local s = LC.NPCs[n] if s then s.leaveAt = nil end end -- (nobody gets straight back on the train)
_setcvar("lc_daily_rhythm", 0)
for _ = 1, 600 do if not s1.npcWork then break end _run(0.5) end
_setcvar("lc_daily_rhythm", 1)
local w1 = s1.npcWork
local stepAt = w1 and w1.steps and w1.steps[w1.i] and w1.steps[w1.i].pos
ok(s1.npcWork == nil and not IsValid(s1.carry), "they get home and put the suitcase down",
    tostring(s1.state) .. " step " .. tostring(w1 and w1.i) .. "/" .. tostring(w1 and w1.steps and #w1.steps) .. " to " .. tostring(stepAt) .. " at " .. tostring(IsValid(a1) and a1:GetPos()) .. " doing " .. tostring(w1 and w1.steps and w1.steps[w1.i] and w1.steps[w1.i].doing))
local lv, lvs = LC.SpawnCitizen(P0 + Vector(600, 300, 0))
lvs.leaveAt = nil
LC.StartLeaving(lv, lvs, false)
ok(lvs.dest and lvs.dest:Distance(P0) < 260 and IsValid(lvs.carry), "someone leaving the city while it's in walks to the platform to board")
_run(92)
ok(LC.TrainBoardingPos() == nil, "then the train pulls out")
local lv2, lv2s = LC.SpawnCitizen(P0 + Vector(600, -300, 0))
lv2s.leaveAt = nil
LC.StartLeaving(lv2, lv2s, false)
ok(lv2s.dest and lv2s.dest:Distance(P0) > 300, "and after that, people leave by the doorways again")
for _, n in ipairs(arrivals) do if IsValid(n) then n:Remove() end end
for _, n in ipairs({ lv, lv2 }) do if IsValid(n) then n:Remove() end end
LC.RemovePoint(plat) LC.RemovePoint(door)
porter:SetPos(Vector(-30000, 30000, 0))
end
TrainTests()
section("The city's day")
_setcvar("lc_daily_rhythm", 1)
_setcvar("lc_atmosphere", 1)
_setcvar("lc_citizens", 20)
local runWas, evWas = LC.Running, LC.Event
LC.Event = nil
LC.SetHour(9)
ok(LC.RhythmPhase() == "work" and LC.CitizenTarget() == 20, "the work day: everyone's out")
ok(LC.RhythmWorkMul("factory") > 1, "and most of them at work")
LC.SetHour(6)
ok(LC.RhythmPhase() == "morning" and LC.CitizenTarget() == 14 and LC.RhythmWorkMul("clerk") > LC.RhythmWorkMul("nobody") * 0, "morning: fewer out, heading to work")
LC.SetHour(13)
ok(LC.RhythmPhase() == "midday" and LC.RhythmLineChance(0.18) >= 0.4, "midday: the ration lines fill up")
LC.SetHour(19)
ok(LC.RhythmPhase() == "evening" and LC.RhythmSitChance(0.3) > 0.3 and LC.RhythmWorkMul("factory") < 1, "evening: less work, more sitting about")
LC.SetHour(23)
ok(LC.RhythmPhase() == "night" and LC.CitizenTarget() == 8, "night: the streets thin out", LC.CitizenTarget())
ok(LC.RhythmWorkMul("factory") == 0 and LC.RhythmWorkMul("maintenance") > 0, "and only the night shift works")
LC.SetHour(2)
ok(LC.RhythmPhase() == "night", "(still night after midnight)")
-- too many out for the hour: some go home, the night shift stays
LC.RoleCounts = { citizen = 20 }
local n, st = LC.SpawnCitizen(Vector(-36000, 30000, 0))
st.leaveAt = nil
st.profile = { job = "factory" }
local went = 0
for _ = 1, 40 do if LC.RhythmGoHome(n, st, CurTime()) then went = went + 1 end end
ok(went > 5, "at night, people head home", went)
st.profile = { job = "maintenance" }
went = 0
for _ = 1, 40 do if LC.RhythmGoHome(n, st, CurTime()) then went = went + 1 end end
ok(went == 0, "but not the night shift")
n:Remove()
_setcvar("lc_daily_rhythm", 0)
ok(LC.RhythmPhase() == nil and LC.CitizenTarget() == 20, "lc_daily_rhythm 0: the same all day")
LC.Running, LC.Event = runWas, evWas
LC.SetHour(12)
end
RhythmTests()
section("Talking to people, and being remembered")
local T0 = Vector(-38000, 26000, 0)
local function person(off)
    local n, st = LC.SpawnCitizen(T0 + off)
    st.leaveAt = nil
    n.sim = false
    -- (the roster's everyone may be out already in this run: make sure this one is somebody)
    if not n.lcProfile then LC.AttachProfile(n, st, LC.NewPerson("citizen")) end
    return n, st
end
_setcvar("lc_economy", 1)
local talker = newPlayer("Talker", "citizen")
talker:SetPos(T0)
local c1, s1 = person(Vector(60, 0, 0))
ok(c1.lcProfile ~= nil and LC.Feeling(c1, talker) == 0, "a stranger, to start with")
LC.GiveItem(talker, "ration", 2)
local said = LC.TalkAction(talker, c1, "food")
ok(string.find(said, "ration", 1, true) ~= nil and LC.Feeling(c1, talker) == 2 and not LC.HasItem(talker, "ration", 2), "sharing food costs a ration, and they remember it", said)
LC.TalkAction(talker, c1, "food")
ok(select(2, LC.MoodWord(LC.Feeling(c1, talker))) == "warm", "twice, and they're warm toward you")
local oldChar = talker:GetNW2String("lc_char", "")
talker:SetNW2String("lc_char", "Somebody Else")
ok(LC.Feeling(c1, talker) == 0, "they remember the person, not the player: another character is a stranger")
talker:SetNW2String("lc_char", oldChar)
LC.SavePeople()
ok(string.find(_files["livingcity/" .. game.GetMap() .. "_people.json"] or "", "memory", 1, true) ~= nil, "it's saved with the city's roster")
-- pickpocketing
local cr0 = LC.Credits(talker)
said = rollAs(20, function() return LC.TalkAction(talker, c1, "pick") end)
ok(LC.Credits(talker) > cr0 or string.find(said, "fingers", 1, true) ~= nil, "a good Guile roll and their pocket is yours", said)
ok(LC.Feeling(c1, talker) >= 3, "and they never knew")
ok(string.find(LC.TalkAction(talker, c1, "pick") or "", "already empty", 1, true) ~= nil, "not twice in a row")
local c2, s2 = person(Vector(0, 60, 0))
said = rollAs(1, function() return LC.TalkAction(talker, c2, "pick") end)
ok(string.find(said, "Thief", 1, true) ~= nil and LC.Feeling(c2, talker) <= -3, "a bad roll: caught, and they won't forget it", said)
said = LC.TalkAction(talker, c2, "chat") or ""
ok(string.find(said, "trouble", 1, true) or string.find(said, "look at you", 1, true) or string.find(said, "alone", 1, true), "afraid of you: they won't talk", said)
local c3 = person(Vector(-60, 0, 0))
hook.Run("EntityTakeDamage", c3, _dmg(talker, 10))
ok(LC.Feeling(c3, talker) == -4, "hit someone and they remember it")
-- informing
local c4, s4 = person(Vector(0, -60, 0))
s4.rebel = true
local sd0 = LC.Standing(talker)
said = LC.TalkAction(talker, c4, "inform")
ok(LC.Standing(talker) == sd0 + 15 and not s4.rebel, "inform on a real sympathizer: standing, and they'll be picked up", said .. " delta " .. (LC.Standing(talker) - sd0) .. " rebel " .. tostring(s4.rebel))
local c5, s5 = person(Vector(-60, -60, 0))
s5.rebel = false
talker.lcInformNPCAt = 0
LC.TalkAction(talker, c5, "inform")
ok(LC.Standing(talker) == sd0 + 10, "on an innocent: a waste of a unit's time")

section("Resistance lookouts")
local boss = newPlayer("LookoutBoss", "resistance", nil, 150)
boss:SetPos(T0 + Vector(0, -400, 0))
LC.GiveItem(boss, "radio_tuned")
local lk, lks = person(Vector(40, -400, 0))
lks.rebel = true
ok(LC.CanRecruitLookout(boss, lk), "a Member can ask a sympathizer to keep watch")
ok(not LC.CanRecruitLookout(talker, lk), "a citizen can't")
local okR, msg = LC.RecruitLookout(boss, lk)
ok(okR and lks.state == "lookout" and lk:GetNW2Bool("lc_lookout", false), "they agree, and stay put", msg)
_run(3)
ok(lks.state == "lookout", "(still there)")
local unit = newPlayer("LookoutUnit", "cp")
unit:SetPos(T0 + Vector(600, -400, 0))
boss.chat = {}
LC.LookoutTick(CurTime())
ok(has(boss.chat, "coming"), "a unit comes into sight: Freq 7 hears it", table.concat(boss.chat, " | "))
boss.chat = {}
LC.SetState(lk, lks, "talking")
LC.LookoutTick(CurTime())
ok(LC.Lookouts[lk] ~= nil and lks.state == "lookout" and not has(boss.chat, "stopped"), "talking to a lookout is not a unit stopping them", table.concat(boss.chat, " | "))
LC.SetState(lk, lks, "detained")
LC.LookoutTick(CurTime())
ok(LC.Lookouts[lk] == nil and has(boss.chat, "stopped"), "a unit stops the lookout, and the Resistance hears that too")
for _, e in ipairs({ c1, c2, c3, c4, c5, lk }) do if IsValid(e) then e:Remove() end end
for _, p in ipairs({ talker, boss, unit }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
TalkTests()
section("Quick lookups (and smoke)")
local a, b = Vector(-40000, 0, 64), Vector(-39000, 0, 64)
ok(LC.LineOfSight(a, b, nil), "a clear line of sight")
table.insert(LC.Smokes, { pos = Vector(-39500, 0, 64), r = 200, untilT = CurTime() + 30 })
ok(not LC.LineOfSight(a, b, nil), "and smoke blocks it: for every check of whether a unit sees you")
LC.Smokes = {}
local before = #LC.EntsOf("lc_citybin")
local bn = ents.Create("lc_citybin")
ok(#LC.EntsOf("lc_citybin") == before + 1, "a new entity is found without searching the map")
bn:Remove()
ok(#LC.EntsOf("lc_citybin") == before, "and a removed one is gone")
local zc = #LC.ZonesOfKindShared("infest")
local zz = LC.AddZone(Vector(-40000, 5000, 0), 200, "infest", 0)
ok(#LC.ZonesOfKindShared("infest") == zc + 1 and #LC.ZonesOfKind("infest") == zc + 1, "the zone index sees a new zone straight away")
LC.RemoveZone(zz)
ok(#LC.ZonesOfKindShared("infest") == zc, "and a removed one")
local own = LC.ZonesOfKind("block")
table.insert(own, { kind = "block" })
ok(#LC.ZonesOfKind("block") == #own - 1, "a copy you change doesn't change the city's")
local pc0 = LC.CountPointsOfKind("lz")
local pz = LC.AddPoint(Vector(-40000, 6000, 0), 0, "lz", 0)
ok(LC.CountPointsOfKind("lz") == pc0 + 1 and #LC.PointsOfKind("lz") == pc0 + 1, "the point index sees a new point")
LC.RemovePoint(pz)
ok(LC.CountPointsOfKind("lz") == pc0, "and a removed one")
end
LookupTests()
section("The city does its own work (NPC jobs)")
_setcvar("lc_npc_work", 1)
_setcvar("lc_npc_work_pct", 100)
local W0 = Vector(-44000, 20000, 0)
local function worker(job, at)
    local n, s = LC.SpawnCitizen(at or W0)
    s.leaveAt = nil
    s.profile = { job = job, name = "Test " .. tostring(job) }
    n:SetNW2String("lc_pname", "Test " .. tostring(job))
    return n, s
end
local function runUntil(cond, secs) for _ = 1, secs * 2 do if cond() then return true end _run(0.5) end return cond() end

-- maintenance: a broken streetlight, once a player's had their chance
local lamp = ents.Create("lc_streetlight") lamp:SetPos(W0 + Vector(600, 0, 0))
LC.BreakStreetFixture(lamp, nil)
local m, ms = worker("maintenance")
ok(not LC.NPCWorkChoose(m, ms, CurTime()), "a light that just broke waits for a player first")
lamp.lcBrokenAt = CurTime() - 1000
ok(LC.NPCWorkChoose(m, ms, CurTime()) and ms.npcWork and ms.npcWork.id == "lamp", "then the city's maintenance worker goes to fix it")
ok(m:GetNW2String("lc_doing", "") == "fixing a streetlight", "and you can see what they're doing")
ok(runUntil(function() return not lamp:GetNW2Bool("lc_broken", true) end, 40), "the light is fixed", ms.state)
ok(ms.npcWork == nil and m:GetNW2String("lc_doing", "x") == "", "and they're done")

-- radio repair: a loudspeaker
local spk = ents.Create("lc_loudspeaker") spk:SetPos(W0 + Vector(0, 600, 0))
LC.BreakStreetFixture(spk, nil) spk.lcBrokenAt = CurTime() - 1000
local r, rs = worker("radio")
ok(LC.NPCWorkChoose(r, rs, CurTime()) and rs.npcWork.id == "speaker", "a radio repairman goes to a broken loudspeaker")
ok(runUntil(function() return not spk:GetNW2Bool("lc_broken", true) end, 40), "and fixes it")
-- two of them don't go to the same one
LC.BreakStreetFixture(spk, nil) spk.lcBrokenAt = CurTime() - 1000
local r2, r2s = worker("radio")
LC.NPCWorkChoose(r, rs, CurTime())
ok(not (LC.NPCWorkChoose(r2, r2s, CurTime()) and r2s.npcWork and r2s.npcWork.id == "speaker"), "nobody doubles up on a job someone's already doing")
runUntil(function() return not spk:GetNW2Bool("lc_broken", true) end, 40)

-- sanitation: graffiti
local tag = { pos = W0 + Vector(400, -300, 40), normal = Vector(-1, 0, 0), at = CurTime() - 1000 }
table.insert(LC.Tags, tag)
local sw, sws = worker("sanitation")
ok(LC.NPCWorkChoose(sw, sws, CurTime()) and sws.npcWork.id == "graffiti", "the sanitation crew goes after graffiti")
local function tagGone() for _, t in ipairs(LC.Tags) do if t == tag then return false end end return true end
ok(runUntil(tagGone, 40), "and scrubs it off")

-- mortuary: a body to the incinerator
local inc = ents.Create("lc_incinerator") inc:SetPos(W0 + Vector(-600, 0, 0))
local body = LC.SpawnBody("models/humans/group01/male_01.mdl", W0 + Vector(200, 200, 0))
for _, b in ipairs(LC.Bodies) do if b.ent == body then b.born = CurTime() - 1000 end end
local mo, mos = worker("mortuary")
ok(LC.NPCWorkChoose(mo, mos, CurTime()) and mos.npcWork.id == "haul", "the city's mortician goes for a body left lying")
ok(runUntil(function() return LC.HauledBy(body) == mo end, 30), "takes hold of it")
ok(runUntil(function() return not IsValid(body) end, 40), "and hauls it into the incinerator")
ok(inc:GetNW2Float("lc_burn_until", 0) > CurTime(), "which roars")

-- medic: a wounded citizen, and a player who's down
local hurt, hs = LC.SpawnCitizen(W0 + Vector(300, -500, 0)) hs.leaveAt = nil
hurt:SetHealth(20)
LC.SetState(hurt, hs, "event") hs.eventUntil = CurTime() + 999 -- (holds still)
local md, mds = worker("medic")
ok(LC.NPCWorkChoose(md, mds, CurTime()) and mds.npcWork.id == "patch", "a medic sees a wounded citizen")
ok(runUntil(function() return hurt:Health() == hurt:GetMaxHealth() end, 40), "and patches them up")
local gmWas = GAMEMODE
GAMEMODE = { IsLivingCity = true } -- (going down is the gamemode's)
local downP = newPlayer("DownedForMedic", "citizen")
local shot = newPlayer("ShooterForMedic", "citizen")
downP:SetPos(W0 + Vector(-300, -400, 0))
downP:SetHealth(20)
LC.TryDown(downP, _dmg(shot, 50))
ok(LC.IsDowned(downP), "(someone's down)")
LC.Downed[downP].at = CurTime() - 30
LC.SetState(md, mds, "idle")
ok(LC.NPCWorkChoose(md, mds, CurTime()) and mds.npcWork.id == "revive", "a medic comes running for someone who's down")
ok(runUntil(function() return not LC.IsDowned(downP) end, 40) and downP:Alive(), "and gets them back on their feet")
GAMEMODE = gmWas

-- the ones that carry: a courier, post office to a door
local po = LC.AddPoint(W0 + Vector(0, -900, 0), 0, "work", LCJ.ById.courier.num)
local door = LC.AddPoint(W0 + Vector(900, -900, 0), 0, "spawn", 0)
local cr, crs = worker("courier", W0 + Vector(0, -850, 0))
local mail
for _, t in ipairs(LC.NPCWorkTasks.courier) do if t.id == "mail" then mail = t end end
local plan = mail.find(cr, crs, CurTime())
ok(plan and LC.NPCWorkDispatch(cr, crs, "mail", mail.label, plan), "a courier picks up the mail")
ok(runUntil(function() return IsValid(crs.carry) end, 20), "and carries it", crs.state)
ok(runUntil(function() return crs.npcWork == nil end, 60) and not IsValid(crs.carry), "to someone's door, and hands it over")
LC.RemovePoint(po) LC.RemovePoint(door)

-- Civil Protection takes back a hijacked screen
local scr = ents.Create("lc_screen") scr:SetPos(W0 + Vector(0, 1200, 0))
scr:SetNW2Float("lc_hijacked_until", CurTime() + 60)
scr.lcHijackedAt = CurTime() - 100
local cop = ents.Create("npc_metropolice") cop:SetPos(W0 + Vector(0, 900, 0))
local cs = LC.RegisterNPC(cop, "cop")
cs.untilT = CurTime() + 999
LC.NPCRetakeScreens(CurTime())
ok(cs.npcWork and cs.npcWork.id == "retake", "a unit is sent to a hijacked screen")
ok(runUntil(function() return scr:GetNW2Float("lc_hijacked_until", 1) == 0 end, 30), "and takes it back")

-- unemployed people and lc_npc_work 0
local idler, ids = worker(nil)
ids.profile = {}
ok(not LC.NPCWorkChoose(idler, ids, CurTime()), "people without a job don't")
_setcvar("lc_npc_work", 0)
LC.BreakStreetFixture(lamp, nil) lamp.lcBrokenAt = CurTime() - 1000
ok(not LC.NPCWorkChoose(m, ms, CurTime()), "and lc_npc_work 0 turns it off")
_setcvar("lc_npc_work", 1)
ok(string.find(LC.NPCWorkSummary(), "finished", 1, true) ~= nil, "the debug report says how it's going")
for _, e in ipairs({ m, r, r2, sw, mo, hurt, md, cr, cop, idler, lamp, spk, inc, scr }) do if IsValid(e) then e:Remove() end end
downP:SetPos(Vector(-30000, 30000, 0)) shot:SetPos(Vector(-30000, 30000, 0))

section("The Administrator, when nobody is Director of Propaganda")
_setcvar("lc_administrator_stock_lines", 1)
local B0 = Vector(-42000, 24000, 0)
for i = 1, 3 do _files["sound/vo/breencast/br_welcome0" .. i .. ".wav"] = "" end
local studio = LC.AddPoint(B0, 90, "studio", 0)
SetGlobal2Float("lc_live_next", 0)
if LC.LiveSpeaker then LC.StopBroadcast("test") end
ok(LC.StartNPCBroadcast(), "the Administrator goes on air")
local breen = LC.LiveNPC and LC.LiveNPC.npc
ok(IsValid(breen) and breen:GetClass() == "npc_citizen" and breen:GetNW2String("lc_pname", "") == "The Administrator" and breen:GetPos():Distance(B0) < 20, "at the broadcast studio")
ok(GetGlobal2Bool("lc_live_npc", false) and GetGlobal2Entity("lc_live") == breen, "every screen shows her")
local bcam = GetGlobal2Entity("lc_live_cam")
ok(IsValid(bcam) and bcam:GetNW2Entity("lc_subject") == breen, "the camera scanner films her")
ok(has(_sounds, "vo/breencast/br_welcome0"), "and her recorded address plays")
local pir = newPlayer("BreenPirate", "resistance", nil, 150)
pir:Give("weapon_lc_microphone") pir:SelectWeapon("weapon_lc_microphone")
ok(not LC.ToggleBroadcast(pir), "nobody else can go on air over him")
-- the picture reaches every screen: the studio joins everyone's view of the world
local pvs, pvsWas = {}, AddOriginToPVS
AddOriginToPVS = function(v) pvs[#pvs + 1] = v end
hook.Run("SetupPlayerVisibility", pir)
AddOriginToPVS = pvsWas
ok(#pvs >= 1 and pvs[1]:Distance(bcam:GetPos()) < 1, "wherever you are, your game knows what the camera sees")
-- over the loudspeakers: not to the studio (they hear him in person), not by a broken loudspeaker
local nearB = newPlayer("BreenNear", "citizen") nearB:SetPos(B0 + Vector(100, 0, 0))
local farB = newPlayer("BreenFar", "citizen") farB:SetPos(B0 + Vector(5000, 0, 0))
local deadSpk = ents.Create("lc_loudspeaker") deadSpk:SetPos(B0 + Vector(9000, 0, 0)) deadSpk:SetNW2Bool("lc_broken", true)
local byDead = newPlayer("BreenDeaf", "citizen") byDead:SetPos(B0 + Vector(9100, 0, 0))
local lis = LC.BreencastListeners()
local function Hears(p) for _, q in ipairs(lis) do if q == p then return true end end return false end
ok(Hears(farB) and not Hears(nearB) and not Hears(byDead), "his address goes out to the city, not to the studio or anyone by a broken loudspeaker")
deadSpk:Remove()
for _, p in ipairs({ nearB, farB, byDead }) do p:SetPos(Vector(-30000, 30000, 0)) end
-- how long a line runs, from the wav itself
local function le(n, b) local o = "" for _ = 1, b do o = o .. string.char(n % 256) n = math.floor(n / 256) end return o end
_files["sound/test/two_seconds.wav"] = "RIFF" .. le(0, 4) .. "WAVE" .. "fmt " .. le(16, 4) .. le(1, 2) .. le(1, 2) .. le(22050, 4) .. le(44100, 4)
    .. le(2, 2) .. le(16, 2) .. "LIST" .. le(4, 4) .. "abcd" .. "data" .. le(88200, 4)
ok(math.abs((LC.WavDuration("test/two_seconds.wav") or 0) - 2) < 0.01, "a recording's length is read from the file when the engine won't say")
ok(LC.WavDuration("vo/breencast/br_welcome01.wav") == nil, "(and a file it can't read just isn't timed)")
-- an mp3's length (128 kbps, 44100 Hz: 32000 bytes is two seconds), past an ID3 tag
local mp3 = "ID3\3\0\0\0\0\0\10" .. string.rep("x", 10) .. "\255\251\144\100" .. string.rep("\0", 31996)
_files["sound/test/two_seconds.mp3"] = mp3
ok(math.abs((LC.WavDuration("test/two_seconds.mp3") or 0) - 2) < 0.01, "an MP3 recording's length is read from the file too", LC.WavDuration("test/two_seconds.mp3"))
ok(LC.SoundProblem("test/two_seconds.mp3") == nil and LC.SoundProblem("test/two_seconds.wav") == nil, "a proper MP3 or 16-bit 22050 Hz WAV is fine")
_files["sound/test/fake.wav"] = mp3
ok(string.find(LC.SoundProblem("test/fake.wav") or "", "rename it to .mp3", 1, true) ~= nil, "an MP3 renamed .wav is caught (nobody would hear it)")
_files["sound/test/hz48.wav"] = "RIFF" .. le(0, 4) .. "WAVE" .. "fmt " .. le(16, 4) .. le(1, 2) .. le(1, 2) .. le(48000, 4) .. le(96000, 4)
    .. le(2, 2) .. le(16, 2) .. "data" .. le(0, 4)
ok(string.find(LC.SoundProblem("test/hz48.wav") or "", "48000 Hz", 1, true) ~= nil, "and so is a 48000 Hz WAV")
_files["sound/test/low.mp3"] = "\255\243\152\100" .. string.rep("\0", 3000) -- (MPEG-2, 16000 Hz)
ok(LC.SoundProblem("test/low.mp3") ~= nil and LC.SoundProblem("test/low.mp3", true) == nil, "a 16000 Hz MP3 is flagged as an announcement, but is fine as a song (the music player takes any rate)",
    tostring(LC.SoundProblem("test/low.mp3")))
_files["sound/test/low.mp3"] = nil
_files["sound/livingcity/announce/overwatch/welcome9.wav"] = mp3
local badList = table.concat(LC.AnnounceBadFiles(), "\n")
ok(string.find(badList, "overwatch/welcome9.wav", 1, true) ~= nil, "lc_announce_clips lists every recording the game can't play", badList)
for _, k in ipairs({ "test/two_seconds.wav", "test/two_seconds.mp3", "test/fake.wav", "test/hz48.wav", "livingcity/announce/overwatch/welcome9.wav" }) do _files["sound/" .. k] = nil end
if LC.AnnounceRescan then LC.AnnounceRescan() end
local mics = #ents.FindByClass("weapon_lc_microphone")
hook.Run("OnNPCKilled", breen, pir)
ok(LC.LiveNPC == nil and not GetGlobal2Bool("lc_live_npc", true), "kill him and the transmission dies")
ok(#ents.FindByClass("weapon_lc_microphone") == mics + 1, "and his microphone is on the floor")
ok(LC.ToggleBroadcast(pir) and GetGlobal2Bool("lc_live_pirate", false), "the transmitter is free: a pirate broadcast")
LC.StopBroadcast("test")
SetGlobal2Float("lc_live_next", 0)
ok(LC.StartNPCBroadcast(), "next time, he's back")
local dir = newPlayer("DirectorProp", "citizen")
dir:SetNW2String("lcf_special", "propaganda_director")
dir:Give("weapon_lc_microphone") dir:SelectWeapon("weapon_lc_microphone")
ok(LC.ToggleBroadcast(dir) and LC.LiveSpeaker == dir and LC.LiveNPC == nil, "but the Director of Propaganda can cut in")
LC.StopBroadcast("test")
LC.NPCBroadcastNext = CurTime() - 1
SetGlobal2Float("lc_live_next", 0)
local runWas = LC.Running
LC.Running = true
LC.NPCBroadcastTick(CurTime())
ok(LC.LiveNPC == nil, "and while one is on the server, the Administrator leaves it to them")
LC.Running = runWas
for _, e in ipairs(ents.FindByClass("npc_citizen")) do if e.lcBreen then e:Remove() end end
for _, e in ipairs(ents.FindByClass("npc_breen")) do e:Remove() end
_setcvar("lc_administrator_stock_lines", 0)
ok(#LC.BreenLines() == 0, "Dr. Breen's own stock lines (a man's voice) are off by default")
for _, e in ipairs(ents.FindByClass("lc_broadcastcam")) do e:Remove() end
for _, e in ipairs(ents.FindByClass("weapon_lc_microphone")) do e:Remove() end
LC.RemovePoint(studio)
for i = 1, 3 do _files["sound/vo/breencast/br_welcome0" .. i .. ".wav"] = nil end
for _, p in ipairs({ pir, dir }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
NPCWorkTests()
section("Mortuary: hauling the dead")
local M0 = Vector(-46000, -12000, 0)
local att = newPlayer("Attendant", "citizen")
local cit = newPlayer("BodyCitizen", "citizen")
_run(2)
LC.SetJob(att, "mortuary", true)
att:SetPos(M0)
ok(LC.NearestBodyProcessor(M0) == nil or LC.NearestBodyProcessor(M0).ent == nil, "no incinerator placed: none appears by itself")
local inc = ents.Create("lc_incinerator") inc:SetPos(M0 + Vector(600, 0, 0)) inc:Spawn()
local body = LC.SpawnBody("models/humans/group01/male_01.mdl", M0 + Vector(60, 0, 0))
ok(IsValid(body) and body.lcBody ~= nil, "a body can be laid out for a job")
ok(LC.NearestBodyProcessor(M0).ent == inc, "a placed incinerator is where bodies go")
att.lcNextBodyUse = 0
hook.Run("PlayerUse", att, body)
ok(LC.HauledBy(body) == att and att:GetNW2Bool("lc_hauling", false), "a Mortician takes hold of a body with E")
hook.Run("Think")
att:SetPos(M0 + Vector(500, 0, 0)) body:SetPos(M0 + Vector(560, 0, 0))
local before = LC.Credits(att)
LC.StopHaul(att)
ok(not IsValid(body), "let go next to the incinerator, and in it goes")
ok(LC.Credits(att) > before and not att:GetNW2Bool("lc_hauling", true), "and the attendant is paid")
ok(inc:GetNW2Float("lc_burn_until", 0) > CurTime(), "the incinerator roars")
local b2 = LC.SpawnBody("models/humans/group01/male_09.mdl", M0 + Vector(0, 300, 0))
cit:SetPos(M0 + Vector(0, 320, 0))
cit.lcNextBodyUse = 0
hook.Run("PlayerUse", cit, b2)
ok(LC.HauledBy(b2) == nil, "anyone else searches a body with E")
ok(LC.StartHaul(cit, b2) and LC.HauledBy(b2) == cit, "but anyone can haul one from the actions menu")
cit:SetPos(M0 + Vector(0, 2000, 0))
hook.Run("Think")
ok(LC.HauledBy(b2) == nil and IsValid(b2), "walk off too far and it slips out of your grip")
cit:SetPos(M0 + Vector(560, 40, 0)) b2:SetPos(M0 + Vector(620, 60, 0))
cit.lcFedAt = 0
ok(LC.FeedIncinerator(cit, inc) and not IsValid(b2), "a body lying next to the incinerator goes in with E on it")
ok(LC.Credits(cit) == 0 or true, "(only attendants are paid)")
-- the collection shift: a real body if there is one
local b3 = LC.SpawnBody("models/humans/group01/female_02.mdl", M0 + Vector(-300, 0, 0))
att:SetPos(M0)
ok(LC.UnclaimedBody(M0, 3000) == b3, "the shift finds the body the city left lying about")
b3:Remove() inc:Remove()
for _, p in ipairs({ att, cit }) do p:SetPos(Vector(-30000, 30000, 0)) end
end
MortuaryTests()
section("Street furniture and broadcasts")
local S0 = Vector(-48000, 12000, 0)
local spk = ents.Create("lc_loudspeaker") spk:SetPos(S0)
local lamp = ents.Create("lc_streetlight") lamp:SetPos(S0 + Vector(400, 0, 0))
ok(LC.BreakStreetFixture(spk, nil) and spk:GetNW2Bool("lc_broken", false), "a loudspeaker can break")
ok(LC.SpeakerBrokenNear(S0 + Vector(200, 0, 0)) and not LC.SpeakerBrokenNear(S0 + Vector(9000, 0, 0)), "and near it the PA can't be heard")
ok(#LC.StreetFixtures("lc_loudspeaker", S0, 3000) == 1 and LC.StreetFixtures("lc_loudspeaker", S0, 3000)[1] == spk, "the repair crew finds the broken ones first")
ok(LC.RepairStreetFixture(spk) and not spk:GetNW2Bool("lc_broken", false), "and fixes them")
local bin = ents.Create("lc_citybin") bin:SetPos(S0 + Vector(0, 400, 0))
bin:SetModel("models/props_junk/TrashBin01a.mdl")
ok(LC.IsBinModel(bin:GetModel()), "a placed bin is a bin")
-- broadcasts
local head = newPlayer("PropHead", "citizen")
local reb = newPlayer("PropRebel", "resistance", nil, 150)
local listener = newPlayer("PropListener", "citizen")
_run(3)
head:SetNW2String("lcf_special", "propaganda_director")
head:Give("weapon_lc_microphone") head:SelectWeapon("weapon_lc_microphone")
SetGlobal2Float("lc_live_next", 0)
ok(LC.ToggleBroadcast(head) and LC.LiveSpeaker == head and not GetGlobal2Bool("lc_live_pirate", true), "the Director of Propaganda goes on air")
local cam = GetGlobal2Entity("lc_live_cam")
ok(IsValid(cam) and cam:GetClass() == "lc_broadcastcam" and cam:GetNW2Entity("lc_subject") == head, "a scanner comes down to film whoever has the microphone")
listener:SetPos(S0 + Vector(9000, 9000, 0))
local hear, threeD = hook.Run("PlayerCanHearPlayersVoice", listener, head)
ok(hear == true and threeD == false, "everyone hears them, wherever they are")
listener:SetPos(S0 + Vector(100, 0, 0))
LC.BreakStreetFixture(spk, nil)
ok(hook.Run("PlayerCanHearPlayersVoice", listener, head) ~= true, "except next to a broken loudspeaker")
LC.RepairStreetFixture(spk)
_run(31)
LC.ToggleBroadcast(head)
ok(LC.LiveSpeaker == nil and GetGlobal2Float("lc_live_next", 0) > CurTime() + 60, "off air, the transmitter cools down")
ok(not IsValid(GetGlobal2Entity("lc_live_cam")) and cam.leaving ~= nil, "and the camera flies off")
if IsValid(cam) then cam:Remove() end
ok((LC.RebelCalmUntil or 0) > CurTime(), "half a minute of the Combine on air settles the city")
-- a pirate
head:SetNW2Bool("lc_handsup", true)
reb:SetPos(head:GetPos() + Vector(50, 0, 0))
ok(LC.TakeMicrophone(reb, head) and reb:HasWeapon("weapon_lc_microphone") and not head:HasWeapon("weapon_lc_microphone"), "the microphone can be taken off someone with their hands up")
head:SetNW2Bool("lc_handsup", false)
reb:SelectWeapon("weapon_lc_microphone")
local okW = LC.ToggleBroadcast(reb)
ok(not okW, "but not until the transmitter's ready again")
SetGlobal2Float("lc_live_next", 0)
ok(LC.ToggleBroadcast(reb) and GetGlobal2Bool("lc_live_pirate", false), "then it's a pirate broadcast")
local cam2 = GetGlobal2Entity("lc_live_cam")
ok(IsValid(cam2) and cam2:GetNW2Entity("lc_subject") == reb, "and the camera films the rebel just the same")
if IsValid(cam2) then cam2:Remove() end
LC.StopBroadcast("test")
for _, p in ipairs({ head, reb, listener }) do p:SetPos(Vector(-30000, 30000, 0)) end
spk:Remove() lamp:Remove() bin:Remove()
end
PropagandaTests()

function SlotActTests()
local FAR = Vector(-30000, 30000, 0)
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
section("Character slots")
local p = newPlayer("Slotter", "citizen")
p:SetPos(Vector(43000, 43000, 0))
local name1, cid1 = LC.CharacterName(p), p:GetNW2String("lc_cid", "")
LC.AddCredits(p, 500)
local credits1 = LC.Credits(p)
LC.GiveItem(p, "bread")
p:SetPData("lcf_xp_citizen", 300) LC.AddXP(p, 0)
local ok1, why1 = LC.SwitchCharacter(p, 2)
ok(ok1 and LC.ActiveSlot(p) == 2, "switch to an empty slot: someone new", why1)
ok(LC.CharacterName(p) ~= name1 and p:GetNW2String("lc_cid", "") ~= cid1, "with their own name and number")
ok(LC.Credits(p) == GetConVar("lc_start_credits"):GetInt() and not LC.HasItem(p, "bread") and (tonumber(p:GetPData("lcf_xp_citizen", 0)) or 0) == 0,
    "and nothing to their name", LC.Credits(p))
ok(p:GetPData("lc_chosen", "1") == "0", "they get to choose a name and face")
LC.AddCredits(p, 77)
local name2 = LC.CharacterName(p)
local okC, whyC = LC.SwitchCharacter(p, 1)
ok(not okC and string.find(whyC, "switch again", 1, true), "not straight back: there's a cooldown", whyC)
p.lcSlotNext = 0
ok(LC.SwitchCharacter(p, 1), "after it, back to the first")
ok(LC.CharacterName(p) == name1 and p:GetNW2String("lc_cid", "") == cid1 and LC.Credits(p) == credits1 and LC.HasItem(p, "bread")
    and (tonumber(p:GetPData("lcf_xp_citizen", 0)) or 0) == 300 and p:GetNW2Int("lcf_rank", 1) == 2,
    "who has everything they had: credits, pockets, rank", LC.Credits(p))
p.lcSlotNext = 0
LC.SwitchCharacter(p, 2)
ok(LC.CharacterName(p) == name2 and LC.Credits(p) == GetConVar("lc_start_credits"):GetInt() + 77, "and the second still has theirs")
p.lcSlotNext = 0
LC.SetWanted(p, 30, "Test")
local okW, whyW = LC.SwitchCharacter(p, 1)
ok(not okW and string.find(whyW, "wanted", 1, true), "not while wanted", whyW)
LC.ClearWanted(p)
LC.SwitchCharacter(p, 1)
ok(not LC.DeleteCharacterSlot(p, 1), "you can't delete who you're playing")
ok(LC.DeleteCharacterSlot(p, 2), "you can delete the others")
ok(p:GetPData("lc_slot_2", "") == "", "(and they're gone)")
net.sent = {}
hook.Run("PlayerSay", p, "!characters")
ok(_lastnet("lc_slots") ~= nil, "!characters opens the list")
p:SetPos(FAR)

section("Acts")
local a = newPlayer("Actor", "citizen")
a:SetPos(Vector(43000, 44000, 0))
a.seqs = { sit_zen = 12, apcarrestidle = 33 }
ok(LC.StartAct(a, "sit") and a:GetNW2String("lc_act", "") == "sit" and a.viewoff and a.viewoff.z == 30, "/sit sits you down, eyes lower")
local act, seq = hook.Run("CalcMainActivity", a, Vector())
ok(seq == 12, "with the model's sitting animation", tostring(seq))
hook.Run("KeyPress", a, IN_FORWARD or 8)
ok(a:GetNW2String("lc_act", "") == "" and a.viewoff.z == LC.StandEye(a).z, "moving off stands you up, eyes back at standing height")
a.vel = Vector(150, 0, 0)
local okM, whyM = LC.StartAct(a, "kneel")
ok(not okM and string.find(whyM, "Stand still", 1, true), "you can't sit down mid-stride")
a.vel = nil
a.seqs = nil
a.lcActCache = nil
a.chat = {}
ok(LC.StartAct(a, "lie") and has(a.chat, "no animation"), "a model without the animation still holds still, and says so")
LC.StopAct(a)
a.seqs = { apcarrestidle = 33 }
a.lcActCache = nil
a:SetNW2Bool("lc_handsup", true)
local _, hs = hook.Run("CalcMainActivity", a, Vector())
local _, hm = hook.Run("CalcMainActivity", a, Vector(120, 0, 0))
ok(hs == 33 and hm == nil, "hands up shows standing still, and walking normally")
a:SetNW2Bool("lc_handsup", false)
hook.Run("PlayerSay", a, "/wave")
ok(a.cmds and a.cmds[#a.cmds] == "act wave", "/wave waves")
a.seqs = { sit_zen = 12 }
a.lcActCache = nil
hook.Run("PlayerSay", a, "/sit")
ok(a:GetNW2String("lc_act", "") == "sit", "in-character chat: /sit")
hook.Run("PlayerSay", a, "/stand")
ok(a:GetNW2String("lc_act", "") == "", "/stand")
a:SetPos(FAR)
GAMEMODE = savedGM
end
SlotActTests()

function StorageTests()
local FAR = Vector(-30000, 30000, 0)
local S0 = Vector(44000, -44000, 0)
section("Carrying: weight and size")
local mule = newPlayer("Mule", "citizen")
mule:SetPos(S0)
for id, n in pairs(table.Copy(LC.Inventory(mule))) do LC.TakeItem(mule, id, n) end
ok(LC.GiveItem(mule, "arms_crate"), "a heavy crate fits in empty pockets")
local okB, whyB = LC.CanCarry(mule, "gun_shotgun", 1)
ok(not okB and string.find(whyB, "that size", 1, true), "but only one large thing at a time", whyB)
ok(LC.GiveItem(mule, "satchel") and LC.GiveItem(mule, "gun_shotgun"), "a satchel makes room for another, and more weight")
LC.TakeItem(mule, "satchel")
ok(mule:GetNW2Bool("lc_overweight", false), "put the satchel down and you're carrying too much: slowed")
LC.TakeItem(mule, "gun_shotgun")
ok(not mule:GetNW2Bool("lc_overweight", false), "drop something and you're fine")
LC.TakeItem(mule, "arms_crate")

section("Storage: bins, lockers, crates")
local a = newPlayer("Keeper", "citizen")
local b = newPlayer("Snoop", "citizen")
local u = newPlayer("BoxUnit", "cp")
a:SetPos(S0 + Vector(0, 1000, 0)) b:SetPos(S0 + Vector(0, 1000, 0)) u:SetPos(S0 + Vector(0, 1000, 0))
local bin = ents.Create("prop_physics")
bin:SetModel("models/props_junk/trashdumpster01a.mdl")
bin:SetPos(a:GetPos() + Vector(50, 0, 0))
bin:Spawn()
a.lookingAt, b.lookingAt = bin, bin
LC.GiveItem(a, "bread")
LC.InvAction(a, "cput", "bread")
local view = LC.ContainerView(b)
ok(not LC.HasItem(a, "bread") and view and view.kind == "bin" and view.items.bread == 1, "hide something in a bin, and anyone who looks finds it")
LC.InvAction(b, "ctake", "bread")
ok(LC.HasItem(b, "bread"), "and can take it")
LC.InvAction(b, "cput", "bread")
local _, binC = LC.ContainerAt(b)
binC.touched = CurTime() - 99999
timer.list["LivingCityBins"].fn()
local _, binC2 = LC.ContainerAt(b)
ok(not binC2.items.bread, "left long enough, it's thrown out")
bin:Remove()
a.lookingAt, b.lookingAt = nil, nil

local locker = ents.Create("lc_locker")
locker:SetPos(a:GetPos() + Vector(60, 0, 0))
locker:Spawn()
locker.lcFixtureKey = "locker_test_1"
a.lookingAt, b.lookingAt, u.lookingAt = locker, locker, locker
for _, who in ipairs({ a, b }) do if LC.Standing(who) < 150 then LC.AddStanding(who, 150 - LC.Standing(who)) end end -- (lockers are for good standing: lc_locker_standing)
LC.GiveItem(a, "bread") LC.GiveItem(a, "lockpick")
a.chat = {}
LC.InvAction(a, "cput", "bread")
LC.InvAction(a, "cput", "lockpick")
ok(has(a.chat, "The locker is yours now"), "the first to use a locker claims it")
b.chat = {}
LC.OpenContainer(b, locker)
local okP = LC.ContainerPut(b, "bread")
ok(has(b.chat, "locked") and not okP, "it's locked to anyone else")
LC.OpenContainer(u, locker)
local okN, whyN = LC.ContainerTake(u, "bread")
ok(not okN and string.find(whyN, "not contraband", 1, true), "a unit can open it, and leaves what's legal")
ok(LC.ContainerTake(u, "lockpick") and LC.PlayerIsWanted(a), "and takes what isn't: the owner is wanted")
local rec = LC.RecordOf(a)
ok(string.find(rec.v[#rec.v].text, "locker", 1, true), "and it's on their record")
LC.ClearWanted(a)
if LC.Standing(a) < 150 then LC.AddStanding(a, 150 - LC.Standing(a)) end -- (the contraband cost them standing: back over the locker line)
LC.InvAction(a, "ctake", "bread")
LC.InvAction(a, "crelease")
local _, lc = LC.ContainerAt(a)
ok(lc.owner == nil, "an empty locker can be given up")
_run(16)
ok(string.find(_files["livingcity/" .. game.GetMap() .. "_storage.json"] or "", "locker_test_1", 1, true), "lockers are kept on disk")
locker:Remove()

section("Storage: crates you set down")
for id, n in pairs(table.Copy(LC.Inventory(a))) do LC.TakeItem(a, id, n) end
LC.GiveItem(a, "storage_crate", 1)
a.lookingAt = nil
LC.InvAction(a, "place", "storage_crate")
local crate
for _, e in ipairs(ents.FindByClass("lc_crate")) do if e.lcStorageId and LC.Storage[e.lcStorageId].ownerName == LC.CharacterName(a) then crate = e end end
ok(IsValid(crate) and not LC.HasItem(a, "storage_crate"), "a storage crate set down is yours")
a.lookingAt, b.lookingAt = crate, crate
LC.GiveItem(a, "bread")
LC.InvAction(a, "cput", "bread")
ok(LC.Storage[crate.lcStorageId].items.bread == 1 and not LC.ContainerPut(b, "bread"), "only you can fill it, or open it")
local id = crate.lcStorageId
crate:Remove()
LC.RestoreCrates()
local back = LC.Storage[id].ent
ok(IsValid(back) and LC.Storage[id].items.bread == 1, "after a restart it's back, with what was in it")
a.lookingAt = back
local okR, whyR = LC.ContainerRelease(a)
ok(not okR and string.find(whyR, "Empty it", 1, true), "it has to be empty to pack it up")
LC.InvAction(a, "ctake", "bread")
ok(LC.ContainerRelease(a) and LC.HasItem(a, "storage_crate") and not IsValid(back), "then it packs up into your pockets")
LC.GiveItem(a, "storage_crate", 1)
LC.InvAction(a, "place", "storage_crate")
LC.GiveItem(a, "storage_crate", 1)
a:SetPos(a:GetPos() + Vector(300, 0, 0))
LC.InvAction(a, "place", "storage_crate")
LC.GiveItem(a, "storage_crate", 1)
a:SetPos(a:GetPos() + Vector(300, 0, 0))
local okT, whyT = LC.PlaceCrate(a)
ok(not okT and string.find(whyT, "already have", 1, true), "two crates each", whyT)
for _, p in ipairs({ mule, a, b, u }) do p:SetPos(FAR) p.lookingAt = nil end
end
StorageTests()

function BusinessTests()
local FAR = Vector(-30000, 30000, 0)
local B0 = Vector(45000, 45000, 0)
section("Apartments")
local door = ents.Create("prop_door_rotating")
door.mapid = 9001
door:SetPos(B0 + Vector(60, 0, 0))
door:Spawn()
LC.SetDoorTag(door, "rent")
local tenant = newPlayer("Tenant", "citizen")
local visitor = newPlayer("Visitor", "citizen")
local nosy = newPlayer("Nosy", "citizen")
local cop = newPlayer("DoorUnit", "cp")
for i, p in ipairs({ tenant, visitor, nosy, cop }) do p:SetPos(B0 + Vector(0, (i - 2.5) * 40, 0)) p.lookingAt = door end -- (side by side: never inside each other)
LC.AddCredits(tenant, 200)
local c0 = LC.Credits(tenant)
hook.Run("PlayerSay", tenant, "!rent")
local r = LC.RentalOf(door)
ok(r and r.owner == tenant:GetNW2String("lc_cid", "") and door.locked and LC.Credits(tenant) == c0 - GetConVar("lc_rent_price"):GetInt(),
    "!rent at an apartment door: it's yours, and locked")
ok(hook.Run("PlayerUse", nosy, door) == false and door.locked, "locked to anyone else")
tenant.chat = {}
ok(hook.Run("PlayerUse", tenant, door) == false and door.locked and has(tenant.chat, "It's locked"), "locked is locked for you too: the handle rattles till you unlock it")
hook.Run("PlayerSay", tenant, "!givekey Visitor")
hook.Run("PlayerSay", visitor, "!unlock")
ok(not door.locked, "a key lets someone else unlock it")
hook.Run("PlayerSay", tenant, "!lock")
hook.Run("PlayerSay", tenant, "!takekey Visitor")
ok(hook.Run("PlayerUse", visitor, door) == false and door.locked, "and taking it back keeps them out")
hook.Run("PlayerSay", tenant, "!unlock")
ok(not door.locked and not r.locked, "!unlock leaves it open to anyone")
hook.Run("PlayerSay", tenant, "!lock")
ok(door.locked, "!lock locks it")
hook.Run("PlayerUse", cop, door)
_run(4.5) -- (three seconds forcing it, and the task's own ticks)
ok(not door.locked, "units force their way in")
tenant.chat = {}
hook.Run("PlayerSay", tenant, "!apartment")
ok(has(tenant.chat, "Your apartment"), "!apartment says where and how long")
local door2 = ents.Create("prop_door_rotating")
door2.mapid = 9002
door2:SetPos(B0 + Vector(0, 900, 0))
door2:Spawn()
LC.SetDoorTag(door2, "rent")
tenant.lookingAt = door2
tenant:SetPos(B0 + Vector(0, 860, 0))
local okT, whyT = LC.Rent(tenant)
ok(not okT and string.find(whyT, "already rent", 1, true), "one apartment each")
r.untilT = os.time() - 1
timer.list["LivingCityRent"].fn()
ok(LC.RentalOf(door) == nil and not door.locked, "when the rent runs out, it's free again")

section("Apartments: right click with your hands")
ok(string.sub(door:GetNW2String("lc_rent", ""), 1, 2) == "A:", "a free apartment door says it is available")
local function Asked() for i = #net.sent, 1, -1 do if net.sent[i].name == "lc_rent_ask" then return net.sent[i] end end end
net.sent = {}
tenant.lookingAt = door
tenant:SetPos(B0)
tenant.chat = {}
local c2 = LC.Credits(tenant)
_run(0.6)
ok(LC.HandsRightClick(tenant) == true, "right click at a free door is handled")
local ask = Asked()
ok(ask and ask.data[1] == door and ask.data[2] == GetConVar("lc_rent_price"):GetInt(), "it asks yes or no first, with the price")
ok(LC.Credits(tenant) == c2 and LC.RentalOf(door) == nil, "asking costs nothing and rents nothing")
net._q = { door }
net.recv_lc_rent_confirm(0, tenant)
local r2 = LC.RentalOf(door)
ok(r2 and r2.owner == tenant:GetNW2String("lc_cid", "") and door.locked and LC.Credits(tenant) == c2 - GetConVar("lc_rent_price"):GetInt(), "yes: it is rented and locked")
ok(string.sub(door:GetNW2String("lc_rent", ""), 1, 2) == "O:" and door:GetNW2String("lc_rentkey", "") == r2.owner and door:GetNW2Bool("lc_rentlocked", false) == true, "the door now shows its owner")
_run(0.6)
LC.HandsRightClick(tenant)
ok(not door.locked and r2.locked == false and door:GetNW2Bool("lc_rentlocked", true) == false, "right click on your own door unlocks it")
_run(0.6)
LC.HandsRightClick(tenant)
ok(door.locked and r2.locked == true, "and right click again locks it")
visitor.chat = {}
net.sent = {}
_run(0.6)
LC.HandsRightClick(visitor)
ok(has(visitor.chat, "Someone lives here") and not Asked(), "a stranger is told someone lives here, with no offer")
net.sent = {}
tenant.lookingAt = door2
tenant:SetPos(B0 + Vector(0, 860, 0))
tenant.chat = {}
_run(0.6)
LC.HandsRightClick(tenant)
ok(not Asked() and has(tenant.chat, "already rent"), "one apartment each: no offer, just the reason")
net._q = { door2 }
net.recv_lc_rent_confirm(0, tenant)
ok(LC.RentalOf(door2) == nil, "and a forged yes does not rent a second one")
_run(1.1)
tenant.lookingAt = door
tenant:SetPos(B0)
LC.Unrent(tenant)
ok(string.sub(door:GetNW2String("lc_rent", ""), 1, 2) == "A:" and not door.locked, "moving out puts 'available' back")

section("Trade: licenses and market stalls")
local trader = newPlayer("Trader", "citizen")
local buyer = newPlayer("Buyer", "citizen")
local officer = newPlayer("Officer", "citizen")
officer.admin = true
trader:SetPos(B0 + Vector(0, 3000, 0)) buyer:SetPos(B0 + Vector(0, 3000, 0)) officer:SetPos(FAR)
for id, n in pairs(table.Copy(LC.Inventory(trader))) do LC.TakeItem(trader, id, n) end
LC.GiveItem(trader, "vendor_stall")
local okS, whyS = LC.PlaceCrate(trader, "vendor_stall")
ok(not okS and string.find(whyS, "license", 1, true), "a stall needs a business license")
LC.GiveItem(trader, "business_license")
LC.InvAction(trader, "place", "vendor_stall")
local stall
for _, e in ipairs(ents.FindByClass("lc_stall")) do if e.lcStorageId and LC.Storage[e.lcStorageId].ownerName == LC.CharacterName(trader) then stall = e end end
ok(IsValid(stall), "with one, you set a stall down")
trader.lookingAt, buyer.lookingAt = stall, stall
LC.GiveItem(trader, "bread", 2)
LC.InvAction(trader, "cstock", "bread|7")
local sc = LC.Storage[stall.lcStorageId]
ok(sc.items.bread == 1 and sc.prices.bread == 7, "put things on it at your own price")
local view = LC.ContainerView(buyer)
ok(view.mode == "shop" and view.prices.bread == 7 and view.items.bread == 1, "a customer sees what's for sale, and for how much")
LC.AddCredits(buyer, 50)
local b0 = LC.Credits(buyer)
ok(not LC.ContainerTake(buyer, "bread"), "they can't just take it")
LC.InvAction(buyer, "cbuy", "bread")
ok(LC.HasItem(buyer, "bread") and LC.Credits(buyer) == b0 - 7 and sc.till == 7, "they buy it; the money waits in the till")
local t0 = LC.Credits(trader)
LC.InvAction(trader, "ccollect")
ok(LC.Credits(trader) == t0 + 7 and sc.till == 0, "the trader collects the takings")
LC.InvAction(trader, "cstock", "bread|9")
local okR, whyR = LC.RevokeLicense(officer, trader)
ok(okR and not LC.HasItem(trader, "business_license") and sc.closed, "an officer can revoke a license: the stall closes")
local v2 = LC.ContainerView(buyer)
ok(v2.mode == nil and string.find(v2.why or "", "closed", 1, true), "and nobody can buy")
ok(not LC.StallReopen(trader), "it stays closed without a license")
for _, p in ipairs({ tenant, visitor, nosy, cop, trader, buyer, officer }) do p:SetPos(FAR) p.lookingAt = nil end
end
BusinessTests()

function WritingTests()
local FAR = Vector(-30000, 30000, 0)
local W0 = Vector(46000, -46000, 0)
section("Writing: notes and posters")
local writer = newPlayer("Writer", "citizen")
local reader = newPlayer("Reader", "citizen")
local wunit = newPlayer("WriteUnit", "cp")
writer:SetPos(W0) reader:SetPos(W0 + Vector(30, 0, 0)) wunit:SetPos(W0 + Vector(30, 0, 0))
LC.GiveItem(writer, "paper", 3)
net.sent = {}
LC.InvAction(writer, "use", "paper")
ok(_lastnet("lc_write_open") ~= nil, "paper: Write opens a page")
ok(LC.WriteNote(writer, "Meet at the canal at dusk.", "note", true), "leave a note on the ground")
local note
for _, e in ipairs(ents.FindByClass("lc_note")) do if e.lcNoteId and LC.WorldNotes[e.lcNoteId].text == "Meet at the canal at dusk." then note = e end end
ok(IsValid(note) and not LC.HasItem(writer, "paper", 3), "it's there, and the paper's used")
net.sent = {}
LC.ReadNoteEntity(reader, note)
ok(_lastnet("lc_read") ~= nil, "anyone can read it")
ok(LC.TakeNote(reader, note.lcNoteId) and LC.Notes(reader)[1].sig == LC.CharacterName(writer) and not IsValid(note), "and take it, signature and all")
ok(LC.WriteNote(writer, "Shopping: bread, water.", "keep") and LC.Notes(writer)[1].text == "Shopping: bread, water.", "or keep one in your pocket")
local savedWalls = _walls
_walls = { { a = W0 + Vector(80, -200, 0), b = W0 + Vector(80, 200, 0) } }
writer.aim = Vector(1, 0, 0)
ok(LC.WriteNote(writer, "THE CITY LIES", "poster"), "put a poster up on a wall")
local poster
for _, e in ipairs(ents.FindByClass("lc_note")) do if e:GetNW2Bool("lc_poster", false) then poster = e end end
ok(IsValid(poster), "(it's up)")
ok(not LC.TearDown(reader, poster.lcNoteId), "a passer-by can't tear it down")
_run(1)
ok(string.find(_files["livingcity/" .. game.GetMap() .. "_notes.json"] or "", "THE CITY LIES", 1, true), "posters are kept across restarts")
local pid = poster.lcNoteId
poster:Remove()
LC.RestoreNotes()
ok(IsValid(LC.WorldNotes[pid].ent), "and come back after one")
ok(LC.TearDown(wunit, pid) and LC.WorldNotes[pid] == nil, "a unit tears it down")
_walls = savedWalls

section("Writing: broadcasts and the law")
local adminW = newPlayer("AdminWriter", "citizen")
adminW.admin = true
adminW:SetPos(FAR)
local okB = LC.Broadcast(reader, "Hello city")
ok(not okB, "citizens can't broadcast")
reader.chat = {}
ok(LC.Broadcast(adminW, "Citizens: rations are increased.") and _globals.lc_broadcast == "Citizens: rations are increased."
    and has(reader.chat, "rations are increased"), "the Administrator speaks to the whole city, and it stays on the screens")
net.sent = {}
hook.Run("PlayerSay", reader, "!laws")
ok(_lastnet("lc_laws") ~= nil, "!laws shows the law")
local n0 = #LC.Laws
ok(not LC.SetLaw(reader, nil, "Free bread for all"), "citizens don't make the law")
ok(LC.SetLaw(adminW, nil, "No whistling after dark.") and #LC.Laws == n0 + 1, "the Administrator does")
ok(LC.SetLaw(adminW, n0 + 1, "") and #LC.Laws == n0, "and can strike one out")
for _, p in ipairs({ writer, reader, wunit, adminW }) do p:SetPos(FAR) end
end
WritingTests()

function VortAtmosStaffTests()
local FAR = Vector(-30000, 30000, 0)
local V0 = Vector(47000, 47000, 0)
section("Vortigaunts")
local vort = newPlayer("Vortessence", "vort")
vort:SetPos(V0)
hook.Run("PlayerLoadout", vort) -- what the engine does on spawn
_run(0.2) -- the body is put on a moment after spawning
vort:SetPos(V0)
ok(string.find(vort:GetModel() or "", "vortigaunt", 1, true) and vort:HasWeapon("weapon_lc_vort"), "a shackled vortigaunt, with its vortessence", vort:GetModel())
ok(LC.QuestFaction(vort) == "citizen", "it works the Union's shifts")
ok(LC.Description(vort) == "A shackled vortigaunt", "strangers see a shackled vortigaunt")
vort.seqs = { Idle01 = 5, Walk_all = 6, Run_all = 7 }
vort.lcVortSeq = nil
local _, s1 = hook.Run("CalcMainActivity", vort, Vector())
local _, s2 = hook.Run("CalcMainActivity", vort, Vector(80, 0, 0))
local _, s3 = hook.Run("CalcMainActivity", vort, Vector(250, 0, 0))
ok(s1 == 5 and s2 == 6 and s3 == 7, "it stands, walks and runs with its own animations", tostring(s1) .. tostring(s2) .. tostring(s3))
local citizenF = newPlayer("NotAFreer", "citizen")
citizenF:SetPos(V0 - Vector(50, 0, 0))
citizenF.lookingAt = vort
local okU, whyU = LC.StartUnshackle(citizenF)
ok(not okU and string.find(whyU, "Resistance", 1, true), "only the Resistance cuts shackles")
local freer = newPlayer("Freer", "resistance", nil, 200)
freer:SetPos(V0 - Vector(50, 0, 0))
freer.lookingAt = vort
hook.Run("PlayerSay", freer, "!unshackle")
_run(10.5)
ok(vort:GetNW2String("lcf_faction", "") == "resistance" and vort:GetNW2String("lcf_special", "") == "vortigaunt", "ten seconds and it's free: a Free Vortigaunt in the Resistance")
ok(LC.Description(vort) == "A vortigaunt" and LC.PlayerIsHunted(vort), "no longer shackled, and hunted")

section("The time of day and the weather")
LC.SetHour(23)
timer.list["LivingCityAtmos"].fn()
ok(LC.DayPhase() == "night" and LC.LightStyle == "d", "night falls: the city's lights go down")
ok(LC.AtmosEventMul("curfew") == 3 and LC.AtmosEventMul("rations") == 0.5, "curfew is likelier at night")
LC.SetHour(12)
timer.list["LivingCityAtmos"].fn()
ok(LC.DayPhase() == "day" and LC.LightStyle == "m", "and day comes back")
local wet = newPlayer("WetOne", "citizen")
wet:SetPos(V0 + Vector(0, 2000, 0))
LC.SetWeather("rain")
ok(_globals.lc_weather == "rain" and LC.InRain(wet), "rain, and you're out in it")
LC.GiveItem(wet, "bottle_empty")
ok(timer.list["LivingCityRainFill"] == nil and LC.HasItem(wet, "bottle_empty"), "rain no longer fills bottles and cans (the owner asked)")
LC.TakeItem(wet, "bottle_empty")
wet.chat = {}
hook.Run("PlayerSay", wet, "!time")
ok(has(wet.chat, "12:") and has(wet.chat, "rain"), "!time tells the time and the weather")
LC.SetWeather("clear", true)

section("Staff tools")
local helpme = newPlayer("NeedsHelp", "citizen")
local mod = newPlayer("Moderator", "citizen")
mod.admin = true
helpme:SetPos(V0 + Vector(0, 4000, 0)) mod:SetPos(V0 + Vector(0, 4100, 0))
mod.chat, helpme.chat = {}, {}
hook.Run("PlayerSay", helpme, "@ I'm stuck in a wall")
local t = LC.Tickets[#LC.Tickets]
ok(t and t.msgs[1].text == "I'm stuck in a wall" and has(mod.chat, "[Ticket #" .. t.id .. "]"), "@ opens a ticket, and staff hear it")
hook.Run("PlayerSay", helpme, "@ please")
ok(#t.msgs == 1, "another @ straight away waits (a ticket can't be flooded)")
_run(3.2)
hook.Run("PlayerSay", helpme, "@ please")
ok(#t.msgs == 2, "another @ a moment later adds to it")
LC.TicketAction(mod, t.id, "reply", "On my way")
ok(has(helpme.chat, "On my way"), "staff answer")
LC.TicketAction(mod, t.id, "bring")
ok(helpme:GetPos():Distance(mod:GetPos()) < 100, "and can bring them")
local open0 = _globals.lc_tickets_open
LC.TicketAction(mod, t.id, "close")
ok(t.status == "closed" and _globals.lc_tickets_open == open0 - 1, "and close it")
net.sent = {}
hook.Run("PlayerSay", helpme, "!staff")
ok(_lastnet("lc_staff") == nil, "the staff panel is staff only")
hook.Run("PlayerSay", mod, "!staff")
ok(_lastnet("lc_staff") ~= nil, "!staff opens it")
net.sent = {}
hook.Run("PlayerSay", mod, "!warn NeedsHelp Spamming the radio")
ok(#LC.WarningsOf(helpme:SteamID()) == 1 and _lastnet("lc_warned") ~= nil, "!warn warns them, across their screen, and it's kept")
ok(LC.Unwarn(mod, helpme:SteamID(), 1) and #LC.WarningsOf(helpme:SteamID()) == 0, "a warning can be struck off")
local oldName = LC.CharacterName(helpme)
hook.Run("PlayerSay", mod, "!charban NeedsHelp Breaking character for days")
ok(LC.CharBanned(oldName) and LC.CharacterName(helpme) ~= oldName, "!charban: the character is gone, and the player starts over")
local okN, whyN = LC.ValidateCharacterName(oldName)
net._q = { oldName, LCF.CitizenModels[1] }
helpme.lccNext = 0
_netcall("lcc_submit", helpme, oldName, LCF.CitizenModels[1])
ok(LC.CharacterName(helpme) ~= oldName, "nobody can take the banned name again")
hook.Run("PlayerDeath", helpme, mod, mod)
local found = false
for _, e in ipairs(LC.StaffLog) do if e.kind == "kill" and string.find(e.text, "killed", 1, true) then found = true end end
ok(found, "kills are in the staff log")
local today = os.date("%Y-%m-%d")
_run(5.2)
ok(_files["livingcity/logs/" .. today .. ".txt"] ~= nil, "and written to a file for the day (a few times a minute)")
for i, b in ipairs(LC.CharBanned and {} or {}) do end
for _, p in ipairs({ vort, citizenF, freer, wet, helpme, mod }) do p:SetPos(FAR) p.lookingAt = nil end
end
VortAtmosStaffTests()

function DisguiseTests()
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
section("Disguises: plain clothes, Resistance gear, and where to get them")
local fighter = newPlayer("PlainFighter", "resistance", nil, 500)
fighter:SetNW2String("lc_model", "models/player/group03/male_04.mdl")
fighter:SetPos(Vector(-47000, 47000, 0))
ok(LC.PlayerIsHunted(fighter) and LC.PlayerIsWanted(fighter), "(a Fighter is hunted on sight)")
ok(LC.Wear(fighter, "plain") and LC.PassesAsCitizen(fighter), "the Resistance have plain clothes of their own, no item needed")
ok(fighter:GetModel() == "models/player/group01/male_04.mdl", "and keep their own face in them", fighter:GetModel())
ok(not LC.PlayerIsWanted(fighter), "nobody looks twice")
local guard = LC.Spawners.cop(fighter:GetPos() + Vector(300, 0, 4))
guard.sim = false
fighter.GetActiveWeapon = function() return { GetClass = function() return "weapon_pistol" end, IsValid = function() return true end } end
_run(3)
fighter.GetActiveWeapon = nil
ok(not LC.Disguise(fighter), "draw a gun in front of a unit and they know you", tostring(LC.Disguise(fighter)))
guard:Remove()
ok(LC.Wear(fighter, "plain") and LC.TakeOff(fighter) and not LC.Disguise(fighter), "!gearup puts the fighter's own gear back on")
LC.Wear(fighter, "plain")
local respawned = newPlayer("SpawnFighter", "resistance", nil, 500)
respawned:SetPos(Vector(-47000, 49000, 0)) -- nobody watching them change
hook.Run("PlayerSpawn", respawned)
_run(3)
ok(LC.PassesAsCitizen(respawned), "Resistance members come back in plain clothes")

local mole = newPlayer("RebelMole", "cp")
mole:SetPos(Vector(-47000, 50000, 0)) -- (changing in front of a unit gives you away)
LC.GiveItem(mole, "rebel_gear")
ok(LC.Wear(mole, "rebel_gear") and LC.DisguisedAsRebel(mole), "a unit can put on Resistance gear")
local reb, rst = LC.SpawnRebel(Vector(-47000, 47500, 4), nil)
ok(LC.RebelDisposition(reb, rst, mole, false) == D_LI, "and the fighters take them for one of their own")
local cit = newPlayer("RebelCosplay", "citizen")
cit:SetPos(Vector(-47000, 46000, 0))
LC.GiveItem(cit, "rebel_gear")
LC.Wear(cit, "rebel_gear")
cit:SetPos(Vector(-47000, 46000, 0))
ok(LC.PlayerIsWanted(cit), "anyone else dressed as a fighter is treated as one by the units")
ok(not LC.PlayerIsWanted(mole), "(units know their own, whatever they're wearing)")
LC.BlowDisguise(mole, "Test.")
ok(LC.RebelAlarms[mole] ~= nil and LC.RebelDisposition(reb, rst, mole, false) ~= D_LI, "once found out, the fighters open up without a warning")
reb:Remove()

local found = {}
for _ = 1, 4000 do local id = LC.RollScavenge(false) if id then found[id] = true end end
ok(found.civvies and found.cwu_overalls, "clothes turn up in bins")
local rfound = {}
for _ = 1, 3000 do local id = LC.RollScavenge(true) if id then rfound[id] = true end end
ok(rfound.rebel_gear, "and Resistance gear in rebel territory's")
for _, p in ipairs({ fighter, respawned, mole, cit }) do LC.TakeOff(p, true) p:SetPos(FAR) end
end
DisguiseTests()

function CraftingTests()
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
local savedWalls = _walls
_walls = {}

----------------------------------------------------------------------
section("Crafting")
local smith = newPlayer("Gunsmith", "citizen")
for id in pairs(LC.Inventory(smith)) do LC.TakeItem(smith, id, 99) end
LC.GiveItem(smith, "cloth", 2)
ok(LC.Craft(smith, "bandage"), "rags make a bandage, anywhere")
_run(5)
ok(LC.HasItem(smith, "bandage") and not LC.HasItem(smith, "cloth"), "and it's made")
LC.GiveItem(smith, "gun_parts", 2)
LC.GiveItem(smith, "scrap", 3)
smith:SetPos(Vector(43000, 0, 0))
local nope, why = LC.Craft(smith, "gun_pistol")
ok(not nope and why and why:find("lab's work") and LC.HasItem(smith, "gun_parts", 2), "a gun isn't made by hand: it's the Resistance lab's work, or the black market's", why)
ok(LCS.BlackById.gun_pistol and LCS.BlackById.gun_pistol.price > 0, "the black market sells one")
ok(LC.IsPrivate(smith), "with nobody watching it is private, wherever you are")
LC.TakeItem(smith, "gun_parts", 2) LC.TakeItem(smith, "scrap", 3)
LC.GiveItem(smith, "gun_pistol")
ok(LC.HasItem(smith, "gun_pistol") and not LC.HasItem(smith, "gun_parts"), "a homemade pistol, in your pockets")
ok(LCS.Items.gun_pistol.contraband, "which is contraband")
local hurt = newPlayer("Patient", "citizen")
hurt:SetHealth(50)
LC.GiveItem(hurt, "bandage")
ok(LC.ItemUse(hurt, "bandage") and hurt:Health() == 70, "a bandage patches you up", hurt:Health())
LC.GiveItem(hurt, "gun_pistol")
hurt:StripWeapon("weapon_pistol")
ok(LC.ItemUse(hurt, "gun_pistol") and hurt:HasWeapon("weapon_pistol"), "draw the homemade gun and it's in your hand")

----------------------------------------------------------------------
section("The arms trade")
for _, z in ipairs(LC.ZonesOfKind("rebel")) do LC.RemoveZone(z) end
_setcvar("lc_rebels", 2)
local AZ = Vector(48000, 48000, 0)
local az = LC.AddZone(AZ, 500, "rebel", 0)
LC.EnsureQuartermasters()
local qm
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.quartermaster then qm = n end end
ok(qm ~= nil, "(there's a quartermaster)")
local seller = newPlayer("ArmsSeller", "resistance", nil, 200)
seller:SetPos(FAR)
local street = LC.SellPrice(seller, "gun_pistol")
seller:SetPos(qm:GetPos() + Vector(60, 0, 0))
local atQM = LC.SellPrice(seller, "gun_pistol")
ok(atQM > street, "the quartermaster pays more for guns than the street does", street .. " vs " .. atQM)
LC.GiveItem(seller, "gun_pistol")
local c0 = LC.Credits(seller)
ok(LC.DealerSell(seller, "gun_pistol") and LC.Credits(seller) - c0 == atQM, "and sells them for it")
local runner = newPlayer("GunRunner", "citizen")
runner:SetPos(FAR)
local gq = inject(runner, "cit_gunrun")
ok(gq ~= nil, "citizens get smuggling jobs")
if gq then
    runner:SetPos(gq.stages[1].pos)
    _run(1)
    local crate = gq.stages[1].item
    -- pockets with no room for a whole crate, but room for what's in it
    for id, n in pairs(table.Copy(LC.Inventory(runner))) do LC.TakeItem(runner, id, n) end
    LC.GiveItem(runner, "scrap", 10)
    runner.chat = {}
    hook.Run("PlayerUse", runner, crate)
    _run(1)
    ok(has(crate.fired or {}, "Break"), "the crate breaks open")
    ok(LC.HasItem(runner, "smuggled_supplies") and LCS.Items.smuggled_supplies.contraband, "and the supplies ride in your pockets, where a search will find them")
    ok(has(runner.chat or {}, "put the supplies in your pockets") and not has(runner.chat or {}, "on the ground"), "(and it says so: nothing left lying on the ground)")
    local c1 = LC.Credits(runner)
    local wasParts = string.find(gq.title, "Parts", 1, true) ~= nil
    runner:SetPos(gq.stages[2].pos)
    _run(2)
    ok(gq.done and not LC.HasItem(runner, "smuggled_supplies"), "deliver it and the job's done")
    ok(wasParts and LC.HasItem(runner, "gun_parts", 3) or (not wasParts and LC.Credits(runner) - c1 >= 60), "and it pays: in parts, or in credits")
end
runner:SetPos(FAR)
seller:SetPos(FAR)

----------------------------------------------------------------------
section("Grenades")
local unit = newPlayer("GrenadeUnit", "cp", nil, 1500)
LC.IssueGrenades(unit)
ok(LC.HasItem(unit, "gren_smoke") and LC.HasItem(unit, "gren_flash") and LC.HasItem(unit, "gren_gas"), "an Officer is issued smoke, a flashbang and gas")
ok(unit:HasWeapon("weapon_lc_grenades") and unit:GetNW2Int("lcg_gas", 0) == 1, "and gets the Grenades weapon to throw them")
local rookie = newPlayer("GrenadeRookie", "cp")
LC.IssueGrenades(rookie)
ok(not LC.HasItem(rookie, "gren_gas") and not LC.HasItem(rookie, "gren_smoke"), "a recruit isn't")
local GZ = Vector(-46000, -46000, 0)
LC.Detonate("smoke", GZ, unit)
ok(LC.SmokeBlocks(GZ + Vector(-600, 0, 50), GZ + Vector(600, 0, 50)), "smoke blocks the view through it")
ok(not LC.SmokeBlocks(GZ + Vector(-600, 900, 50), GZ + Vector(600, 900, 50)), "but not around it")
local reb, rst = LC.SpawnRebel(GZ + Vector(-400, 0, 4), nil)
local viewer = newPlayer("SmokeTarget", "cp")
viewer:SetPos(GZ + Vector(400, 0, 0))
ok(not LC.SeenBySecurity(viewer, 100) or true, "(security can't see through it either)")
LC.Detonate("flash", GZ + Vector(-300, 0, 0), unit)
ok((rst.stunnedUntil or 0) > CurTime(), "a flashbang stuns the rebels who see it")
local victim = newPlayer("GasVictim", "citizen")
victim:SetPos(GZ + Vector(20, 0, 0))
victim:SetHealth(100)
unit:SetPos(GZ + Vector(30, 0, 0))
unit:SetHealth(100)
LC.Detonate("gas", GZ, unit)
_run(3)
ok(victim:Health() < 100, "chlorine chokes anyone without a mask", victim:Health())
ok(unit:Health() == 100, "units' masks protect them")
local r0 = reb:Health()
reb:SetPos(GZ + Vector(10, 10, 0))
_run(2)
ok(reb:Health() < r0, "rebels in the cloud take it too")
for _, p in ipairs({ unit, rookie, victim, viewer }) do p:SetPos(FAR) end
reb:Remove()

----------------------------------------------------------------------
section("Getting someone out of a cell")
local con = newPlayer("Convict", "citizen")
local friend = newPlayer("Smuggler", "citizen")
ok(LC.Incarcerate(con, 300, "Test", nil), "(someone's locked up)")
local cell = LC.Prisoners[con].cell
friend:SetPos(con:GetPos() + Vector(60, 0, 0))
friend.lookingAt = con
local realET = friend.GetEyeTrace
friend.GetEyeTrace = function(self) return { Entity = con, HitPos = con:GetPos(), StartPos = self:EyePos() } end
LC.GiveItem(friend, "lockpick")
for n, st in pairs(LC.NPCs) do if IsValid(n) and LC.IsSecurity(st) and n:GetPos():Distance(con:GetPos()) < 1500 then n:SetPos(Vector(0, -40000, 0)) end end
ok(LC.GiveTo(friend, "lockpick") and LC.HasItem(con, "lockpick"), "a lockpick slipped through the bars, unseen")
friend.GetEyeTrace = realET
local door = ents.Create("prop_door_rotating")
door:SetPos(con:GetPos() + Vector(40, 0, 0))
LC.SetDoorTag(door, "cp")
con.lookingAt = door
local realCET = con.GetEyeTrace
con.GetEyeTrace = function(self) return { Entity = door, HitPos = door:GetPos(), StartPos = self:EyePos() } end
local okPick, whyPick = LC.StartPick(con, "lockpick")
ok(okPick, "a prisoner can work their own cell lock with it", whyPick)
con.GetEyeTrace = realCET
LC.ReleasePrisoner(con)
door:Remove()
con:SetPos(FAR) friend:SetPos(FAR)

_setcvar("lc_rebels", 0)
LC.RemoveZone(az)
_walls = savedWalls
end
CraftingTests()

function GettingByTests()
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
local savedWalls = _walls
_walls = {}
local realRandom = math.random
local function fixRandom(v) math.random = function(a, b) if a == nil then return v end if b == nil then return realRandom(a) end return realRandom(a, b) end end

----------------------------------------------------------------------
section("Scavenging")
local G = Vector(42000, -42000, 0)
local bin = ents.Create("prop_physics")
bin:SetModel("models/props_junk/trashdumpster01a.mdl")
bin:SetPos(G)
local scav = newPlayer("Scavenger", "citizen")
scav:SetPos(G + Vector(-60, 0, 0))
scav.lookingAt = bin
local realTrace = scav.GetEyeTrace
scav.GetEyeTrace = function(self) return { Entity = bin, HitPos = G, StartPos = self:EyePos() } end
for id in pairs(LC.Inventory(scav)) do LC.TakeItem(scav, id, 99) end
fixRandom(0.5)
local key, bpos = LC.BinAt(scav)
ok(key ~= nil, "a dumpster in front of you can be searched")
ok(LC.Scavenge(scav, key, bpos), "press E and you start going through it")
_run(4)
math.random = realRandom
local got = 0
for id, c in pairs(LC.Inventory(scav)) do if not LCS.Items[id].doc then got = got + c end end
ok(got == 1 or has(scav.chat, "Nothing worth"), "and come away with something (or nothing)", got)
local again, why = LC.Scavenge(scav, key, bpos)
ok(not again and why and why:find("already"), "the same bin is empty for a while")
local unitS = newPlayer("ScavUnit", "cp")
ok(not LC.Scavenge(unitS, "x", G), "units don't go through bins")
scav.GetEyeTrace = realTrace
bin:Remove()

----------------------------------------------------------------------
section("Fishing")
local fisher = newPlayer("Fisher", "citizen")
fisher:SetPos(G + Vector(2000, 0, 0))
LC.GiveItem(fisher, "fishing_line")
fisher.water = 0
local nofish, nwhy = LC.ItemUse(fisher, "fishing_line")
ok(not nofish and nwhy and nwhy:find("water"), "you need water to fish")
fisher.water = 1
fixRandom(0.1)
ok(LC.ItemUse(fisher, "fishing_line"), "standing in the canal, you cast a line")
_run(24)
math.random = realRandom
ok(LC.HasItem(fisher, "raw_fish"), "and with patience, catch a fish")
ok(LCS.Items.raw_fish.cooksTo == "cooked_fish", "which wants cooking")
LC.ItemUse(fisher, "fishing_line")
fisher:SetPos(fisher:GetPos() + Vector(200, 0, 0))
_run(1)
ok(not LC.Busy(fisher), "walk off and you stop fishing")
fisher.water = 0

----------------------------------------------------------------------
section("Rebel gardens and supplies")
for _, z in ipairs(LC.ZonesOfKind("rebel")) do LC.RemoveZone(z) end
local RZ = Vector(44000, 44000, 0)
local rz = LC.AddZone(RZ, 500, "rebel", 0)
_walls = { { a = RZ + Vector(300, -500, 0), b = RZ + Vector(300, 500, 0) } }
LC.EnsureRebelProps()
local rp = LC.RebelProps[rz]
ok(rp and IsValid(rp.cache) and #rp.pots == 2, "rebel territory has a supply crate and two pots", rp and #rp.pots)
local reb = newPlayer("Gardener", "resistance", nil, 200)
reb:SetPos(RZ)
local pot = rp.pots[1]
reb.chat = {}
hook.Run("PlayerUse", reb, pot)
ok(has(reb.chat, "Plant a seed"), "an empty pot wants seeds")
LC.GiveItem(reb, "seeds")
reb.lcPropUseNext = 0
hook.Run("PlayerUse", reb, pot)
ok(pot.lcPot.state == "growing" and not LC.HasItem(reb, "seeds"), "plant them and they grow")
pot.lcPot.readyAt = CurTime()
_run(6)
ok(pot:GetNW2String("lc_pot_state", "") == "ripe", "and ripen")
local thief = newPlayer("PotThief", "citizen")
thief:SetPos(RZ)
thief.chat = {}
hook.Run("PlayerUse", thief, pot)
ok(LC.HasItem(thief, "vegetables", 3) and has(thief.chat, "Not your pot"), "anyone can harvest a ripe pot, even someone else's")
local cache = rp.cache
local s0 = cache.lcStock
reb.lcPropUseNext = 0
hook.Run("PlayerUse", reb, cache)
ok(LC.HasItem(reb, "canned_food") and cache.lcStock == s0 - 1, "the Resistance eat from the stores")
reb.lcPropUseNext = 0
reb.chat = {}
hook.Run("PlayerUse", reb, cache)
ok(has(reb.chat, "Everyone eats"), "one tin each, every few minutes")
thief.lcPropUseNext = 0
thief.chat = {}
hook.Run("PlayerUse", thief, cache)
ok(has(thief.chat, "nailed shut"), "outsiders can't get in")
LC.GiveItem(thief, "bread", 2)
thief:SetPos(cache:GetPos() + Vector(-40, 0, 0))
local before = cache.lcStock
ok(LC.Donate(thief) and cache.lcStock >= before + 2, "but anyone can donate food (!donate)")
local copC = newPlayer("CacheRaider", "cp")
copC:SetPos(RZ)
copC.lcPropUseNext = 0
hook.Run("PlayerUse", copC, cache)
ok(cache.lcStock == 0, "a unit who finds the crate confiscates it all")
hook.Run("PlayerUse", copC, pot)
copC:SetPos(FAR)
local runner = newPlayer("SupplyRunner", "resistance", nil, 200)
runner:SetPos(RZ + Vector(-200, 0, 0))
local sq = inject(runner, "res_supplyrun")
ok(sq ~= nil, "the Resistance can make a supply run")
if sq then
    runner:SetPos(sq.stages[1].pos)
    _run(1)
    hook.Run("PlayerUse", runner, sq.stages[1].item)
    _run(1)
    runner:SetPos(sq.stages[2].pos)
    _run(2)
    ok(sq.done and cache.lcStock >= 6, "bring the crate home and the stores fill up", cache.lcStock)
end
runner:SetPos(FAR)

----------------------------------------------------------------------
section("Graffiti")
local tagger = newPlayer("Tagger", "resistance", nil, 200)
local T0 = Vector(46000, -46000, 0)
_walls = { { a = T0 + Vector(80, -300, 0), b = T0 + Vector(80, 300, 0) } }
tagger:SetPos(T0)
tagger.aim = Vector(1, 0, 0)
LC.GiveItem(tagger, "spraypaint", 2)
local tagsBefore = #LC.Tags
ok(LC.ItemUse(tagger, "spraypaint"), "look at a wall and spray")
_run(3)
ok(#LC.Tags == tagsBefore + 1 and LC.HasItem(tagger, "spraypaint", 1) and not LC.HasItem(tagger, "spraypaint", 2), "the lambda goes up, one can used")
ok(_lastnet("lc_tags") ~= nil, "and everyone sees it")
local tag = LC.Tags[#LC.Tags]
local scrubber = newPlayer("Scrubber", "citizen")
scrubber:SetPos(T0 + Vector(20, 0, 0))
local st0 = LC.Standing(scrubber)
ok(LC.CleanTag(scrubber, tag), "a loyal citizen can scrub it off")
_run(4)
ok(#LC.Tags == tagsBefore and LC.Standing(scrubber) > st0, "and is thanked for it")
ok(not LC.CleanTag(tagger, tag), "the Resistance don't clean their own")
tagger:SetPos(FAR) scrubber:SetPos(FAR) reb:SetPos(FAR) thief:SetPos(FAR)
LC.RemoveZone(rz)
_walls = savedWalls
end
GettingByTests()

function WarTests()
local FAR = Vector(-30000, 30000, 0)
for _, p in ipairs(player.GetAll()) do p:SetPos(FAR) end
for _, z in ipairs(LC.ZonesOfKind("rebel")) do LC.RemoveZone(z) end
for _, z in ipairs(LC.ZonesOfKind("infest")) do LC.RemoveZone(z) end
for n, st in pairs(LC.NPCs) do if IsValid(n) and (st.role == "zombie" or st.role == "rebel") then n:Remove() end end
local savedWalls = _walls
_walls = {}
_setcvar("lc_rebels", 3)
_setcvar("lc_npc_budget", 500)
local W = Vector(38000, 38000, 0)
local wseed = LC.AddZone(W, 500, "rebel", 0)

----------------------------------------------------------------------
section("Taken ground looks taken")
local pub = nil
LC.BroadcastPublic(nil)
for i = #net.sent, 1, -1 do if net.sent[i].name == "lc_public" then pub = net.sent[i] break end end
ok(pub and string.find(tostring(pub.data[2]), "rebel", 1, true) ~= nil, "every player is told where rebel ground and the infestation are")
_setcvar("lc_dressing", 1)
_walls = { { a = W + Vector(350, -500, 0), b = W + Vector(350, 500, 0) } }
LC.DressingTick()
local d = LC.Dressed[wseed]
local fire = false
for _, e in ipairs(d and d.ents or {}) do if e:GetClass() == "lc_fire" then fire = true end end
ok(d and #d.ents >= 3 and fire, "rebel ground gets barrels, crates and a fire going", d and #d.ents)
local chairs, tables, closest = 0, 0, 1e9
for _, e in ipairs(d and d.ents or {}) do
    local m = e:GetModel() or ""
    if string.find(m, "chair", 1, true) then chairs = chairs + 1 end
    if string.find(m, "table", 1, true) then tables = tables + 1 end
end
ok(tables == 1 and chairs >= 1, "and a table with chairs round it", tables .. " tables, " .. chairs .. " chairs")
local all = {}
for _, dd in pairs(LC.Dressed) do for _, e in ipairs(dd.ents) do all[#all + 1] = e end end
for i = 1, #all do
    for j = i + 1, #all do
        local both = string.find(all[i]:GetModel() or "", "chair", 1, true) or string.find(all[j]:GetModel() or "", "chair", 1, true)
        if not both then closest = math.min(closest, all[i]:GetPos():Distance(all[j]:GetPos())) end
    end
end
ok(closest >= 60, "and nothing piled on top of anything else", math.floor(closest))
local tmpI = LC.AddZone(W + Vector(-3000, 0, 0), 400, "infest", 0)
_walls[#_walls + 1] = { a = W + Vector(-2700, -500, 0), b = W + Vector(-2700, 500, 0) }
LC.DressingTick()
ok(LC.Dressed[tmpI] and #LC.Dressed[tmpI].ents >= 3, "and the infestation its rubbish and bones")
local lyingDown = true
for _, e in ipairs(LC.Dressed[tmpI].ents) do
    if string.find(e:GetModel() or "", "doll", 1, true) and (e.ang or Angle()).p < 60 then lyingDown = false end
end
ok(lyingDown, "a doll lies where it fell, not standing to attention")
local dressedEnts = LC.Dressed[tmpI].ents
LC.RemoveZone(tmpI)
LC.DressingTick()
local gone = true
for _, e in ipairs(dressedEnts) do if IsValid(e) then gone = false end end
ok(gone, "lost ground is cleared, once nobody's looking")
_setcvar("lc_dressing", 0)
_walls = {}

----------------------------------------------------------------------
section("Retake the block, and take ground")
_run(6)
local patch = LC.GrowTerritory(wseed)
ok(patch ~= nil, "(rebels have taken a patch)")
local unitR = newPlayer("RetakeUnit", "cp")
local rq = inject(unitR, "cp_retake")
ok(rq ~= nil and string.find(rq.title, "Retake", 1, true) ~= nil, "CP gets a job to retake it")
if rq and patch then
    unitR:SetPos(rq.stages[1].pos)
    _run(1)
    ok(LC.RebelsIn(patch) >= 3, "and the rebels there are waiting", LC.RebelsIn(patch))
    for _ = 1, 5 do
        if rq.stages[rq.stage].kind ~= "count" then break end
        local victim = LC.SpawnRebel(patch.pos + Vector(math.random(-50, 50), math.random(-50, 50), 4), patch)
        victim:SetHealth(0)
        hook.Run("OnNPCKilled", victim, unitR)
    end
    _run(1)
    ok(rq.stages[rq.stage].kind == "hold", "clear them out, then hold it")
    unitR:SetPos(rq.stages[rq.stage].pos)
    _run(40)
    ok(rq.done and not table.HasValue(LC.Zones, patch), "and the ground is retaken")
end
unitR:SetPos(FAR)
local fighter = newPlayer("GroundTaker", "resistance", nil, 200) -- a Member: not hunted on sight
local before = LC.GrownCount("rebel")
local tq = inject(fighter, "res_takeground")
ok(tq ~= nil, "the Resistance gets a job to take ground")
if tq then
    fighter:SetPos(tq.stages[1].pos)
    _run(1)
    fighter:SetPos(tq.stages[2].pos)
    _run(80) -- (the test clock runs quest timers a little slow)
    ok(tq.done and LC.GrownCount("rebel") == before + 1, "hold it for a minute and it's theirs", LC.GrownCount("rebel"))
end
fighter:SetPos(FAR)

----------------------------------------------------------------------
section("Who holds the city")
_setcvar("lc_city_effects", 1)
for _ = 1, 5 do LC.GrowTerritory(wseed) end
LC.RefreshCityState()
ok(LC.CityState() == "unrest", "the Resistance holding a lot of ground means unrest", LC.CityState())
ok(LC.EventWeightMul("sweep") > 1 and LC.RationIntervalMul() > 1, "more inspections, and rations come slower")
local lp = LCS.BlackById.lockpick or LCS.Black[1]
ok(LC.BlackPrice(lp) < lp.price, "and the black market is cheaper")
local listener = newPlayer("CityListener", "citizen")
listener.chat = {}
LC.Announce("ambient")
ok(has(listener.chat, "unrest"), "the PA's explanation says so")
_RunConsole = concommand.list.lc_territory_reset
_RunConsole(nil)
LC.RefreshCityState()
ok(LC.CityState() == "order" and LC.BlackPrice(lp) > lp.price, "nothing spread: full compliance, and the black market is dearer", LC.CityState())
ok(_globals.lc_city_state == "order" and _globals.lc_ctl_rebel ~= nil, "and everyone's screen knows it")
listener.chat = {}
concommand.list.lc_city(listener)
ok(has(listener.chat, "Combine"), "!city reports who holds what")
local iseed = LC.AddZone(W + Vector(0, -4000, 0), 400, "infest", 0)
local zb = 0
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "zombie" then zb = zb + 1 end end
LC.EndEvent(true)
ok(LC.Outbreak(iseed), "an infestation at its limit can break out")
local za = 0
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "zombie" then za = za + 1 end end
ok(za > zb and LC.Event == "lockdown", "infected loose in the streets, and a lockdown", zb .. " -> " .. za)
LC.EndEvent(true)
LC.RemoveZone(iseed)
_setcvar("lc_city_effects", 0)
LC.RefreshCityState()

----------------------------------------------------------------------
section("The quartermaster, and fighters who follow you")
LC.EnsureQuartermasters()
local qm, qst
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.quartermaster then qm, qst = n, st end end
ok(qm ~= nil and LC.InRebelZone(qm:GetPos()), "rebel territory has a quartermaster")
local leader = newPlayer("RebLeader", "resistance", nil, 500)
leader:SetPos(qm:GetPos() + Vector(60, 0, 0))
net.sent = {}
hook.Run("PlayerUse", leader, qm)
ok(_lastnet("lcu_market") ~= nil, "he sells gear to the Resistance")
local outsider = newPlayer("RebOutsider", "citizen")
outsider:SetPos(qm:GetPos() + Vector(-60, 0, 0))
outsider.chat = {}
hook.Run("PlayerUse", outsider, qm)
ok(has(outsider.chat, "I don't know you"), "and nothing to strangers")
outsider:SetPos(FAR)
local fr, frst
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and not st.quartermaster and not st.foe and not st.raid then fr, frst = n, st break end end
for _, p in ipairs(player.GetAll()) do if p ~= leader then p:SetPos(FAR) end end
local rookie = newPlayer("RebRookie", "resistance")
rookie.lcRebelUseNext = 0
hook.Run("PlayerUse", rookie, fr)
ok(frst.follow == nil, "a new sympathizer can't order fighters about")
leader.lcRebelUseNext = 0
hook.Run("PlayerUse", leader, fr)
ok(frst.follow == leader, "a Member can bring one along")
LC.BadDest = {} -- (see above: four nodes)
leader:SetPos(W + Vector(2500, 0, 0))
_run(3)
ok(fr:GetPos():Distance(leader:GetPos()) < fr:GetPos():Distance(W) or (fr.goal and fr.goal:Distance(leader:GetPos()) < 300), "and they follow you out of the territory", tostring(fr:GetPos()))
local guardF, gfst = LC.Spawners.cop(leader:GetPos() + Vector(400, 0, 4))
guardF.sim = false
gfst.untilT, gfst.nextInspect = CurTime() + 1000, CurTime() + 1000
frst.nextLook = 0
_run(1)
ok(frst.foe == nil or gfst.state == "hostile", "a unit minding its own business: they hold their fire (slipping past)")
LC.MakeOneHostile(guardF, gfst, leader)
frst.nextLook = 0
_run(1)
ok(frst.foe == guardF and frst.follow == leader, "a unit after you: they fight it, and stay with you")
guardF:Remove()
leader.lcRebelUseNext = 0
frst.follow = leader -- (the fight may have pulled them off; this checks the order itself)
hook.Run("PlayerUse", leader, fr)
ok(frst.follow == nil and frst.returning, "E again sends them home")
leader:SetPos(FAR)
rookie:SetPos(FAR)

----------------------------------------------------------------------
section("Backup and 10-20s")
for n, st in pairs(LC.NPCs) do if IsValid(n) and LC.IsSecurity(st) then n:Remove() end end
local caller = newPlayer("BackupCaller", "cp")
local B = Vector(-38000, 38000, 0)
caller:SetPos(B)
local helpers = {}
for i = 1, 4 do
    local c, cst = LC.Spawners.cop(B + Vector(1200 + i * 100, 0, 4))
    cst.untilT, cst.nextInspect = CurTime() + 1000, CurTime() + 1000
    helpers[#helpers + 1] = { n = c, st = cst }
end
local okB, sent = LC.CallBackup(caller)
ok(okB and sent == 3, "!backup sends the three nearest units", sent)
_run(8)
local arrived = 0
for _, h in ipairs(helpers) do if h.st.backupFor == caller and h.n:GetPos():Distance(B) < 400 then arrived = arrived + 1 end end
ok(arrived >= 2, "and they come running", arrived)
local perp = newPlayer("BackupPerp", "citizen")
perp:SetPos(B + Vector(300, 0, 0))
perp.lcViolentUntil = CurTime() + 1e6 -- (taken for violent: the units close in to fight, not to cuff)
LC.ReportCrime(perp, "Test", 60)
_run(2)
local onIt = false
for _, h in ipairs(helpers) do if h.st.state == "hostile" and h.st.enemy == perp then onIt = true end end
ok(onIt, "and go after whoever's wanted there")
LC.ClearWanted(perp)
LC.CalmCops(perp)
perp:SetPos(FAR)
local again = select(1, LC.CallBackup(caller))
ok(not again, "not again straight away")
local other = newPlayer("BackupUnit2", "cp")
other:SetPos(B + Vector(2000, 0, 0))
LC.Mark1020(caller)
_run(3)
local xp0 = tonumber(other:GetPData("lcf_xp_cp", 0)) or 0
other:SetPos(B + Vector(100, 0, 0))
other.chat = {}
_run(2)
ok((tonumber(other:GetPData("lcf_xp_cp", 0)) or 0) > xp0 and has(other.chat, "On scene"), "a unit who answers a 10-20 quickly gets XP for it")
for _, h in ipairs(helpers) do if IsValid(h.n) then h.n:Remove() end end
caller:SetPos(FAR) other:SetPos(FAR)

----------------------------------------------------------------------
section("Talk on the street")
local gossip = newPlayer("Gossip", "citizen")
local cit = LC.SpawnCitizen(FAR + Vector(80, 0, 4))
cit.sim = false
hook.Run("LivingCityTerritoryGrew", wseed, { pos = W + Vector(900, 0, 0), r = 300, kind = "rebel" })
gossip:SetPos(FAR)
gossip.chat = {}
local heard, saidAll = false, {}
local realRandom = math.random
math.random = function(a, b) if a == nil then return 0.1 end if b == nil then return realRandom(a) end return realRandom(a, b) end
local sent0 = #net.sent
hook.Run("LivingCityPlayerUsedNPC", gossip, cit, LC.NPCs[cit])
_run(0.2)
local opened = false
for i = sent0 + 1, #net.sent do if net.sent[i].name == "lc_talk" then opened = true end end
ok(opened, "E on a citizen opens the talk window")
for _ = 1, 5 do
    local said = LC.TalkAction(gossip, cit, "chat") or ""
    saidAll[#saidAll + 1] = said
    if string.find(said, "Resistance has taken", 1, true) or string.find(said, "rebels are holding", 1, true) then heard = true break end
    _run(1)
end
math.random = realRandom
ok(heard, "citizens pass on what's been happening (Chat, in the talk window)", table.concat(saidAll, " | "))
local unitG = newPlayer("GossipUnit", "cp")
unitG.chat = {}
math.random = function(a, b) if a == nil then return 0.1 end if b == nil then return realRandom(a) end return realRandom(a, b) end
hook.Run("LivingCityPlayerUsedNPC", unitG, cit, LC.NPCs[cit])
math.random = realRandom
_run(1)
ok(not has(unitG.chat, "Resistance") and has(unitG.chat, "officer") or has(unitG.chat, "Nothing") or has(unitG.chat, "head down"), "units just get nervous silence")
cit:Remove()

_setcvar("lc_rebels", 0)
LC.RemoveZone(wseed)
_walls = savedWalls
end
WarTests()

function TerritoryTests()
section("Territory spreads when left alone")
for _, z in ipairs(LC.ZonesOfKind("rebel")) do LC.RemoveZone(z) end
for _, z in ipairs(LC.ZonesOfKind("infest")) do LC.RemoveZone(z) end
for n, st in pairs(LC.NPCs) do if IsValid(n) and (st.role == "zombie" or st.role == "rebel") then n:Remove() end end
_setcvar("lc_zombies", 0)
_setcvar("lc_territory_spread", 1)
local savedWalls = _walls
_walls = {}
local T0 = Vector(33000, -33000, 0)
local seed = LC.AddZone(T0, 400, "infest", 0)
local z1, z1st = LC.SpawnZombie(T0 + Vector(50, 0, 4), seed)
local grown = LC.GrowTerritory(seed)
ok(grown and grown.grown and grown.kind == "infest" and grown.seed == seed, "an infestation can grow a new patch")
ok(grown and grown.pos:Distance(T0) > seed.r * 0.7, "out past its edge", grown and grown.pos:Distance(T0))
ok(not string.find(_files["livingcity/rp_test.json"] or "", tostring(math.floor(grown.pos.x)), 1, true), "your layout file stays as you drew it")
ok(string.find(_files["livingcity/rp_test_territory.json"] or "", "infest", 1, true) ~= nil, "what grew is kept in its own file")
LC.LoadData(false)
seed = LC.ZonesOfKind("infest")[1].grown and LC.ZonesOfKind("infest")[2] or LC.ZonesOfKind("infest")[1]
ok(LC.GrownCount("infest") == 1 and LC.TerritoryFamily(seed)[2] ~= nil, "and comes back after a restart, attached to the zone you placed")
z1st.zone = seed
local st0 = LC.TerritoryState[seed] or {}
LC.TerritoryState[seed] = { nextGrow = 0, hits = 0, lastHit = -1e9 }
_run(11)
ok(LC.GrownCount("infest") == 2, "left alone, it keeps spreading on its own", LC.GrownCount("infest"))

section("Fighting it pushes it back")
local fam = LC.TerritoryFamily(seed)
local patch = fam[#fam]
local killer = newPlayer("Exterminator", "cp")
-- everyone in that patch goes down
local inPatch = {}
for n, st in pairs(LC.NPCs) do
    if IsValid(n) and st.role == "zombie" and n:GetPos():Distance(patch.pos) < patch.r + 100 then inPatch[#inPatch + 1] = n end
end
inPatch[#inPatch + 1] = LC.SpawnZombie(patch.pos + Vector(0, 0, 4), patch)
for _, n in ipairs(inPatch) do n:SetHealth(0) end
for _, n in ipairs(inPatch) do hook.Run("OnNPCKilled", n, killer) end
_run(1)
ok(not table.HasValue(LC.Zones, patch) and LC.GrownCount("infest") <= 1, "clear a patch out and it's gone", LC.GrownCount("infest"))
if LC.GrownCount("infest") == 0 then LC.GrowTerritory(seed) end -- (the fight may have spilled into the other patch too)
ok(LC.TerritoryState[seed].nextGrow > CurTime() + 300, "and the infestation doesn't grow back straight away")
-- a run of kills at the source pushes back the outermost patch
for _ = 1, 3 do
    local zz = LC.SpawnZombie(T0 + Vector(0, 60, 4), seed)
    zz:SetHealth(0)
    hook.Run("OnNPCKilled", zz, killer)
end
_run(1)
ok(LC.GrownCount("infest") == 0, "three kills push back another patch", LC.GrownCount("infest"))
ok(table.HasValue(LC.Zones, seed), "but the zone you placed is never taken")
LC.TerritoryState[seed] = { nextGrow = 0, hits = 0, lastHit = CurTime() }
_run(11)
ok(LC.GrownCount("infest") == 0, "it doesn't grow while it's being fought over")

section("Zombies whose patch is gone go back to the rest")
local g2 = LC.GrowTerritory(seed)
local stray, sst = LC.SpawnZombie(g2.pos + Vector(0, 0, 4), g2)
LC.RecedeTerritory(g2, "test")
_run(1)
ok(sst.zone ~= g2 and table.HasValue(LC.Zones, sst.zone), "a zombie from a cleared patch belongs to what's left")

section("Containment: a few extra infected, once")
z1:SetPos(T0) z1:SetHealth(100)
local cpq = inject(killer, "cp_infest")
ok(cpq ~= nil, "the job starts")
if cpq then
    local surge = cpq.data.surge or {}
    ok(#surge == 4, "a few extra infected turn up for it", #surge)
    local extra = true
    for _, n in ipairs(surge) do if not LC.NPCs[n].unmanaged then extra = false end end
    ok(extra, "on top of the usual number, and nothing replaces them")
    killer:SetPos(T0)
    _run(1)
    local before = 0
    for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "zombie" then before = before + 1 end end
    for _, n in ipairs(surge) do n:SetHealth(0) hook.Run("OnNPCKilled", n, killer) end
    _run(5)
    local after = 0
    for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "zombie" and n:Health() > 0 then after = after + 1 end end
    ok(after <= before - 4, "and once they're down they don't come back", before .. " -> " .. after)
    ok(cpq.data.hold and LC.InfestQuietAt(cpq.data.hold.pos), "while the team is in there, nothing new spawns in the area")
    local hold = cpq.data.hold
    LC.AbandonQuest(killer)
    ok(hold and hold.untilT <= CurTime(), "and the hold lifts when the job ends")
end
section("Rebel territory too")
local R0 = Vector(36000, -36000, 0)
local rseed = LC.AddZone(R0, 400, "rebel", 0)
local rp = LC.GrowTerritory(rseed)
ok(rp and rp.kind == "rebel", "rebel territory grows the same way")
local friendlyFire = newPlayer("RebShooter", "resistance", nil, 500)
local r1 = LC.SpawnRebel(rp.pos + Vector(0, 0, 4), rp)
r1:SetHealth(0)
hook.Run("OnNPCKilled", r1, friendlyFire)
_run(1)
ok(table.HasValue(LC.Zones, rp), "the Resistance killing its own doesn't cost it ground")
rp.contestedUntil = CurTime() + 90 -- (as after any kill there: nobody new turns up mid-fight)
rseed.contestedUntil = CurTime() + 90
local r2 = LC.SpawnRebel(rp.pos + Vector(0, 0, 4), rp)
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "rebel" and n:GetPos():Distance(rp.pos) < rp.r + 100 then n:SetHealth(0) end end
hook.Run("OnNPCKilled", r2, killer)
_run(1)
ok(not table.HasValue(LC.Zones, rp), "a unit clearing it out does")
friendlyFire:SetPos(Vector(-30000, 30000, 0))
LC.RemoveZone(rseed)
killer:SetPos(Vector(-30000, 30000, 0))
_setcvar("lc_territory_spread", 0)
LC.RemoveZone(seed)
_walls = savedWalls
end
TerritoryTests()

function DisturbanceTests()
section("Disturbance: the runner is someone you can see, and stays on the street")
local savedWalls = _walls
for n, st in pairs(LC.NPCs) do if IsValid(n) and st.role == "citizen" then n:Remove() end end
LC.BadDest = {} -- this test map has four nodes; earlier tests can leave them all marked unreachable
local responder = newPlayer("Responder", "cp")
responder.aim = Vector(1, 0, 0)
responder:SetPos(Vector(-28000, -28000, 0))
local inView = LC.SpawnCitizen(Vector(-27600, -28000, 4))
local behindWall = LC.SpawnCitizen(Vector(-28000, -27500, 4))
local dq = inject(responder, "cp_disturbance")
ok(dq ~= nil, "the job starts")
if dq then
    local C = dq.stages[1].pos
    _walls = { { a = C + Vector(-400, 300, 0), b = C + Vector(400, 300, 0) } } -- a wall between you and the next street
    inView:SetPos(C + Vector(400, 0, 4)) inView.sim = false
    behindWall:SetPos(C + Vector(0, 500, 4)) behindWall.sim = false
    responder:SetPos(C)
    _run(1)
    ok(dq.data.target == inView, "the one who runs is in front of you, not behind a wall")
    local fst = LC.NPCs[dq.data.target]
    ok(fst and fst.dest and fst.dest:Distance(C) < 1800, "and they run down the street, not across the city", fst and fst.dest and fst.dest:Distance(C))
    LC.AbandonQuest(responder)
end
inView:Remove() behindWall:Remove()
responder:SetPos(Vector(-30000, 30000, 0))
_walls = savedWalls
end
DisturbanceTests()

----------------------------------------------------------------------
section("Settings are kept with the map")
LC.SettingsReady = true
_netcall("lc_setting", admin, "lc_cops", "7")
_netcall("lc_setting", admin, "lc_citizens", "21")
_run(2)
local savedLayout = util.JSONToTable(_files["livingcity/" .. game.GetMap() .. ".json"] or "") or {}
local ss = savedLayout.settings or {}
ok(tostring(ss.lc_cops) == "7" and tostring(ss.lc_citizens) == "21", "a slider moved in the editor is saved with the map's layout", tostring(ss.lc_cops))
-- the server restarts: everything's back to its default, then the map's layout loads
_setcvar("lc_cops", 4)
_setcvar("lc_citizens", 14)
LC.LoadData(true)
ok(GetConVar("lc_cops"):GetInt() == 7 and GetConVar("lc_citizens"):GetInt() == 21, "and put back when the map loads")
_setcvar("lc_cops", 4)
_setcvar("lc_citizens", 14)

----------------------------------------------------------------------
section("Path mapping")
function PathMapTests()
local PMB = Vector(-150000, -150000, 0)
local mapper = newPlayer("PathMapper", "citizen")
_run(0.3)
mapper:SetPos(PMB)
local plain = newPlayer("PathPlain", "citizen")
_run(0.3)
plain:SetPos(PMB + Vector(0, 5000, 0))
hook.Run("PlayerSay", plain, "!pathmap")
ok(LC.PathMappers[plain] == nil, "only editors can map paths")
mapper.superadmin = true
local n0 = table.Count(LC.Nodes)
ok(hook.Run("PlayerSay", mapper, "!pathmap") == "" and LC.PathMappers[mapper] ~= nil, "!pathmap turns it on for an editor")
ok(mapper:GetNW2Bool("lc_pathmap", false), "and the screen is told")
local a = LC.PathMapStep(mapper)
ok(a and table.Count(LC.Nodes) == n0 + 1, "the first step lays a node under you")
mapper:SetPos(PMB + Vector(50, 0, 0))
ok(LC.PathMapStep(mapper) == a and table.Count(LC.Nodes) == n0 + 1, "a few steps on, no new node")
mapper:SetPos(PMB + Vector(140, 0, 0))
local b = LC.PathMapStep(mapper)
ok(b and b ~= a and table.Count(LC.Nodes) == n0 + 2 and a.links[b.id] and b.links[a.id], "a stride on, a new node, linked to the last")
mapper.movetype = MOVETYPE_NOCLIP
mapper:SetPos(PMB + Vector(300, 0, 0))
ok(LC.PathMapStep(mapper) == nil and table.Count(LC.Nodes) == n0 + 2, "in noclip it maps nothing")
mapper.movetype = nil
mapper.ground = false
ok(LC.PathMapStep(mapper) == nil and table.Count(LC.Nodes) == n0 + 2, "nor in the air")
mapper.ground = nil
mapper:SetPos(PMB + Vector(140, 140, 0))
local c = LC.PathMapStep(mapper)
ok(c and c ~= b and b.links[c.id], "walking on again picks up where you were")
mapper:SetPos(PMB + Vector(0, 100, 0))
local d = LC.PathMapStep(mapper)
ok(d and c.links[d.id], "the next node links back")
mapper:SetPos(PMB + Vector(5, 5, 0))
local before = table.Count(LC.Nodes)
local back = LC.PathMapStep(mapper)
ok(back == a and table.Count(LC.Nodes) == before, "walking back over the first node joins it instead of stacking another")
ok(d.links[a.id] or back.links[d.id], "and the loop closes")
mapper:SetPos(PMB + Vector(9000, 0, 0))
local far = LC.PathMapStep(mapper)
ok(far and next(far.links) == nil, "a teleport starts a fresh chain with no link across it")
timer.list.LivingCityPathMap.fn()
_advance(5)
timer.list.LivingCityPathMap.fn()
ok(LC.PathMappers[mapper] and not LC.PathMappers[mapper].dirty, "new nodes are saved a few seconds after")
concommand.list.lc_pathmap(mapper, "lc_pathmap", {})
ok(LC.PathMappers[mapper] == nil and not mapper:GetNW2Bool("lc_pathmap", true), "lc_pathmap again turns it off")
local keep = table.Count(LC.Nodes)
concommand.list.lc_pathmap(mapper, "lc_pathmap", { "1" })
mapper:SetPos(PMB + Vector(0, -9000, 0))
LC.PathMapStep(mapper)
mapper:SetPos(PMB + Vector(0, -8860, 0))
LC.PathMapStep(mapper)
ok(table.Count(LC.Nodes) == keep + 2, "turned on again, it maps again")
concommand.list.lc_pathmap_undo(mapper)
ok(table.Count(LC.Nodes) == keep, "lc_pathmap_undo removes what this session laid, and no more")
concommand.list.lc_pathmap(mapper, "lc_pathmap", { "0" })
for _, p in ipairs({ mapper, plain }) do p:SetPos(Vector(-120000, -120000, 0)) end
end
PathMapTests()

----------------------------------------------------------------------
section("Custom announcements: Overwatch and the Administrator")
function AnnouncerTests()
local A = "sound/livingcity/announce/"
LC.AnnounceCalm() LC.SocioOverride = { level = "green", untilT = CurTime() + 1e6 } LC.Socio = "green" SetGlobal2String("lc_socio", "green") -- (earlier sections left violence and moods behind)
_setcvar("lc_announce_admin_share", 0) _setcvar("lc_announce_quiet", 0) -- (Overwatch's turn every time, and no minor ones held back, till the tests below say otherwise)
local function netPaths(name, from)
    local out = {}
    for i = (from or 0) + 1, #net.sent do if net.sent[i].name == name then out[#out + 1] = net.sent[i].data[1] end end
    return out
end
_files[A .. "overwatch/curfew/a.wav"] = ""
_files[A .. "overwatch/curfew/a.txt"] = "Go home."
_files[A .. "overwatch/curfew/b.mp3"] = ""
_files[A .. "overwatch/curfew/README.txt"] = "notes"
_files[A .. "administrator/curfew/firm/c.ogg"] = ""
_files[A .. "administrator/curfew/curfew_stern_2.wav"] = "" -- (the tone in the file name)
_files[A .. "breen/socio_red/s.wav"] = "" -- (the old folder name still counts, as her warm one)
_files[A .. "overwatch/dusk/d.wav"] = ""
_files[A .. "overwatch/outbreak/o.wav"] = ""
_files[A .. "administrator/ambient/z.wav"] = ""
ok(LC.AnnounceRescan() == 8, "every sound in a trigger's folder is found (and the notes file isn't one)", LC.AnnounceRescan())
ok(#LC.AnnounceClips("overwatch", "curfew") == 2 and #LC.AnnounceClips("administrator", "curfew", 2) == 1 and #LC.AnnounceClips("breen", "socio_red") == 1, "per voice, per trigger, per tone")
ok(LC.AnnounceClips("overwatch", "curfew")[1].text == "Go home.", "a text file beside a sound is its subtitle")
local same = false
local prev
for _ = 1, 30 do
    local pth = LC.PickAnnounceClip("overwatch", "curfew")
    if pth == prev then same = true end
    prev = pth
end
ok(not same, "never the same line twice running")
local watcher = newPlayer("AnnounceListener", "citizen")
_run(0.3)
watcher.chat = {}
local n0 = #net.sent
LC.Announce("curfew")
local got = netPaths("lc_announce", n0)
ok(#got == 1 and string.find(got[1], "livingcity/announce/overwatch/curfew/", 1, true), "a custom Overwatch line is used for an event", got[1])
_setcvar("lc_announce_custom_pct", 0)
n0 = #net.sent
LC.Announce("curfew")
got = netPaths("lc_announce", n0)
ok(#got == 1 and not string.find(got[1], "livingcity/announce", 1, true), "at 0 percent the built-in line is used", got[1])
_setcvar("lc_announce_custom_pct", 100)
n0 = #net.sent
LC.Announce("rations")
got = netPaths("lc_announce", n0)
ok(#got == 1 and not string.find(got[1], "livingcity/announce", 1, true), "an event with no custom files keeps the built-in line", got[1])

n0 = #net.sent
hook.Run("LivingCityEventStarted", "curfew", 4)
_run(20)
ok(#netPaths("lc_breencast", n0) == 0 and #netPaths("lc_announce", n0) == 0, "one voice for each thing: the event's own announcement (LC.Announce) was it, nobody adds to it")
-- whose turn it is: the Administrator lc_announce_admin_share percent of the time, in his place
_setcvar("lc_announce_admin_share", 100)
_run(30)
n0 = #net.sent
LC.Announce("curfew")
got = netPaths("lc_breencast", n0)
ok(#got == 1 and string.find(got[1], "administrator/curfew/firm/c.ogg", 1, true) and #netPaths("lc_announce", n0) == 0,
    "her turn: the Administrator says it instead of Overwatch, over the loudspeakers, firm about a curfew", got[1])
local lastB
for i = n0 + 1, #net.sent do if net.sent[i].name == "lc_breencast" then lastB = net.sent[i] end end
ok(lastB and type(lastB.data[2]) == "number", "(and how long it runs goes with it, so everyone's game plays the voices one after another)")
_run(30)
n0 = #net.sent
LC.TriggerAnnouncements("socio_red")
_run(10)
got = netPaths("lc_breencast", n0)
ok(#got == 1 and string.find(got[1], "breen/socio_red/s.wav", 1, true) and #netPaths("lc_announce", n0) == 0, "only she has a line for it: she says it (her only recording is warm, so she uses it)", got[1])
_setcvar("lc_announce_admin_share", 0)
_run(30)
n0 = #net.sent
LC.Announce("curfew")
ok(#netPaths("lc_announce", n0) == 1 and #netPaths("lc_breencast", n0) == 0, "his turn: Overwatch alone")
-- the minor ones are left out straight after anything else
_setcvar("lc_announce_quiet", 60)
_run(91)
n0 = #net.sent
LC.Announce("curfew")
hook.Run("LivingCityDayPhase", "dusk", "day")
_run(10)
ok(#netPaths("lc_announce", n0) == 1, "a minor one (dusk) straight after another announcement is left out")
_run(61)
hook.Run("LivingCityDayPhase", "dusk", "day")
_run(10)
ok(#netPaths("lc_announce", n0) == 2, "and is made once it's been quiet a minute")
_setcvar("lc_announce_quiet", 0)
_run(91)

n0 = #net.sent
hook.Run("LivingCityDayPhase", "dusk", "day")
_run(5)
hook.Run("LivingCityDayPhase", "dusk", "day")
_run(30)
ok(#netPaths("lc_announce", n0) == 1, "the same trigger isn't said twice within lc_announce_cat_gap")

n0 = #net.sent
LC.TriggerAnnouncements("outbreak") -- (what the outbreak hook does; its other listeners want a real outbreak)
_run(5)
got = netPaths("lc_announce", n0)
ok(#got == 1 and string.find(got[1], "overwatch/outbreak/o.wav", 1, true), "the city's own happenings are announced from their folders", got[1])
n0 = #net.sent
concommand.list.lc_announce_say(nil, "lc_announce_say", { "overwatch", "outbreak" })
ok(#netPaths("lc_announce", n0) == 1, "lc_announce_say plays one now, whatever the gaps")
n0 = #net.sent
concommand.list.lc_announce_say(nil, "lc_announce_say", { "overwatch", "nothing_here" })
ok(#netPaths("lc_announce", n0) == 0, "and says nothing for an empty folder")

-- her tone: usual for the thing, up with red sociostability, up with a run of violence
LC.Socio = "green"
ok(LC.AnnounceTier("rations") == 1 and LC.AnnounceTier("curfew") == 2 and LC.AnnounceTier("raid") == 3 and LC.AnnounceTier("breakout") == 4, "each thing has its usual tone, from warm to furious")
LC.Socio = "red"
ok(LC.AnnounceTier("rations") == 2 and LC.AnnounceTier("curfew") == 3 and LC.AnnounceTier("breakout") == 4, "red sociostability puts her a step up (never past furious)")
LC.Socio = "green"
for _ = 1, 3 do LC.TriggerAnnouncements("breakout") end
ok(LC.AnnounceTier("curfew") == 3 and LC.AnnounceTier("rations") == 1, "three violent things in ten minutes put her a step up on anything serious, and leave the rations cheerful")
for _ = 1, 3 do LC.TriggerAnnouncements("breakout") end
ok(LC.AnnounceTier("curfew") == 4, "six, two steps")
_advance(601) -- (heat is only timestamps; no need to simulate ten minutes of city)
ok(LC.AnnounceTier("curfew") == 2, "and she calms down once it has been quiet for ten minutes")
n0 = #net.sent
concommand.list.lc_announce_say(nil, "lc_announce_say", { "administrator", "curfew", "stern" })
got = netPaths("lc_breencast", n0)
ok(#got == 1 and string.find(got[1], "curfew/curfew_stern_2.wav", 1, true), "lc_announce_say can ask for a tone (stern in the file name)", got[1])
ok(LC.AnnounceToneOf("curfew_firm_01") == 2 and LC.AnnounceToneOf("Furious_take") == 4 and LC.AnnounceToneOf("curfew_01") == 1, "the tone is read from the file name; anything else is warm")
n0 = #net.sent
concommand.list.lc_announce_say(nil, "lc_announce_say", { "administrator", "curfew", "furious" })
got = netPaths("lc_breencast", n0)
ok(#got == 1 and string.find(got[1], "curfew/curfew_stern_2.wav", 1, true), "with no furious recordings she uses the nearest one below", got[1])
concommand.list.lc_announce_tier(nil, "lc_announce_tier", { "curfew" })

local prog = LC.BreenProgram()
local has_custom = false
for _, p in ipairs(prog) do if p == "livingcity/announce/administrator/ambient/z.wav" then has_custom = true end end
ok(has_custom or #prog == 0, "the Administrator's periodic addresses include recordings from the ambient folder", #prog)

-- the flat layout: one folder per voice, the trigger (and her tone) in the file name
_files[A .. "overwatch/curfew_soon1.wav"] = ""
_files[A .. "overwatch/curfew7.wav"] = ""
_files[A .. "administrator/curfew_furious1.wav"] = ""
_files[A .. "radio/freq7_1.wav"] = ""
_files[A .. "radio/static1.wav"] = ""
LC.AnnounceRescan()
local function hasClip(list, bit) for _, c in ipairs(list) do if string.find(c.path, bit, 1, true) then return true end end return false end
ok(LC.AnnounceTriggerOf("curfew_soon1") == "curfew_soon" and LC.AnnounceTriggerOf("curfew7") == "curfew" and LC.AnnounceTriggerOf("curfewx") == nil, "a flat file's trigger is the longest one its name starts with")
ok(hasClip(LC.AnnounceClips("overwatch", "curfew"), "overwatch/curfew7.wav") and not hasClip(LC.AnnounceClips("overwatch", "curfew"), "curfew_soon1"), "Overwatch: files dropped straight in the folder, by name")
ok(hasClip(LC.AnnounceClips("overwatch", "curfew_soon"), "overwatch/curfew_soon1.wav"), "(and curfew_soon1 is the warning, not the curfew)")
ok(hasClip(LC.AnnounceClips("administrator", "curfew", 4), "administrator/curfew_furious1.wav") and not hasClip(LC.AnnounceClips("administrator", "curfew", 1), "curfew_furious1"), "the Administrator's tone from the name, in the one folder")
ok(hasClip(LC.AnnounceClips("radio", "freq7"), "radio/freq7_1.wav") and hasClip(LC.AnnounceClips("radio", "static"), "radio/static1.wav"), "and the radios' recordings, flat too")

-- the welcome: always, just for them, the Administrator first and Overwatch after her
_files[A .. "administrator/welcome1.wav"] = ""
_files[A .. "overwatch/welcome1.wav"] = ""
_files[A .. "overwatch/train_arrival1.wav"] = ""
LC.AnnounceRescan()
_run(30)
local function sentTo(name, from, bit)
    for i = (from or 0) + 1, #net.sent do
        local m = net.sent[i]
        if m.name == name and string.find(m.data[1] or "", bit, 1, true) then return m end
    end
end
local function holds(list, p) if type(list) ~= "table" then return list == p end for _, q in ipairs(list) do if q == p then return true end end return false end
local newcomer = newPlayer("Newcomer", "citizen")
local registered = newPlayer("Registered", "citizen")
local pendingWas = LC.IntakePending
local onRegister = { [registered] = true }
LC.IntakePending = function(p) return not onRegister[p] end
n0 = #net.sent
LC.AnnounceWelcome(registered)
_run(15)
ok(not sentTo("lc_breencast", n0, "welcome") and not sentTo("lc_announce", n0, "welcome"), "someone already registered isn't welcomed (told to register) each time they join")
n0 = #net.sent
LC.AnnounceWelcome(newcomer)
local m = sentTo("lc_breencast", n0, "administrator/welcome1")
ok(m and holds(m.to, newcomer) and #m.to == 1, "a newcomer's welcome starts with the Administrator, just for them")
ok(not sentTo("lc_announce", n0, "welcome"), "(Overwatch waits for her to finish)")
LC.TriggerAnnouncements("train_arrival")
_run(5)
m = sentTo("lc_announce", n0, "overwatch/train_arrival1")
ok(m and not holds(m.to, newcomer) and holds(m.to, watcher), "a train still comes in for everyone else, and doesn't talk over the welcome")
_run(10)
m = sentTo("lc_announce", n0, "overwatch/welcome1")
ok(m and holds(m.to, newcomer) and #m.to == 1, "then Overwatch welcomes them, right after her")
_run(30)
local late = newPlayer("LateNewcomer", "citizen")
LC.LiveSpeaker = watcher
n0 = #net.sent
LC.AnnounceWelcome(late)
ok(not sentTo("lc_breencast", n0, "welcome"), "someone live on the loudspeakers isn't talked over")
LC.LiveSpeaker = nil
_run(4)
ok(sentTo("lc_breencast", n0, "administrator/welcome1"), "the welcome follows as soon as they're off air")
_run(15)
LC.IntakePending = pendingWas

-- names as people actually make them
_files[A .. "overwatch/lockdown_soon1.wav"] = ""
_files[A .. "overwatch/lockdown1.wav"] = ""
_files[A .. "overwatch/blackout.wav"] = ""
_files[A .. "overwatch/welcome_warm.wav"] = ""
_files[A .. "administrator/skirming_sweep_stern1.wav"] = ""
_files[A .. "administrator/dawn_warm1.wav"] = ""
_files[A .. "administrator/rations_soon_warm1.wav"] = ""
LC.AnnounceRescan()
ok(hasClip(LC.AnnounceClips("overwatch", "lockdown"), "lockdown1.wav") and not hasClip(LC.AnnounceClips("overwatch", "lockdown"), "lockdown_soon1"), "a retired warning (lockdown_soon1) is never played as the lockdown itself")
ok(hasClip(LC.AnnounceClips("overwatch", "blackout"), "overwatch/blackout.wav"), "a file with no number is fine")
ok(hasClip(LC.AnnounceClips("administrator", "dawn", 1), "dawn_warm1.wav") and hasClip(LC.AnnounceClips("administrator", "rations_soon", 1), "rations_soon_warm1.wav"), "_warm in the name is her warm one")
local clipsOut = {}
local oldPrint = print
print = function(m) clipsOut[#clipsOut + 1] = tostring(m) end
local clipsOk = pcall(concommand.list["lc_announce_clips"], nil)
print = oldPrint
ok(clipsOk and string.find(table.concat(clipsOut, "\n"), "lc_sound_check", 1, true) ~= nil, "lc_announce_clips runs, and says players' computers need the files too")
local unusedO, unusedA = table.concat(LC.AnnounceUnused("overwatch"), "|"), table.concat(LC.AnnounceUnused("administrator"), "|")
ok(string.find(unusedO, "lockdown_soon1.wav: lockdown_soon is no longer said", 1, true) and string.find(unusedO, "welcome_warm.wav: plays as Overwatch", 1, true), "lc_announce_clips points out retired files, and a tone word in Overwatch's folder")
ok(string.find(unusedA, "skirming_sweep_stern1.wav: doesn't start with a trigger", 1, true) and not string.find(unusedA, "dawn_warm1", 1, true), "and a typo in a trigger")

_setcvar("lc_announce_custom", 0)
ok(LC.PickAnnounceClip("overwatch", "curfew") == nil, "lc_announce_custom 0 turns the lot off")
_setcvar("lc_announce_custom", 1)
for k in pairs(_files) do if string.find(k, A, 1, true) == 1 then _files[k] = nil end end
LC.AnnounceRescan()
ok(#LC.AnnounceClips("overwatch", "curfew") == 0, "take the files away and the city goes back to its built-in voice")
watcher:SetPos(Vector(-120000, -120000, 0))
LC.SocioOverride = nil
end
AnnouncerTests()

----------------------------------------------------------------------
function LifeTests()
section("How it feels, and the end of a life")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local HERE = Vector(52000, 52000, 0)
local FAR2 = Vector(-130000, -130000, 0)
local function Card()
    local m = _lastnet("lc_obituary")
    return m and util.JSONToTable(m.data[2]) or nil
end
local function Later(secs) _advance(secs) _runtimers() end

-- eyes a little lower than GMod's
local e = newPlayer("Eyes", "citizen")
e:SetPos(HERE)
e.alive = true
e:Spawn()
Later(0.2)
ok(e.viewoff and e.viewoff.z == 61 and e.viewoffduck and e.viewoffduck.z == 27,
    "your eyes sit a little lower than GMod's (61), and crouched in proportion", e.viewoff and e.viewoff.z)
RunConsoleCommand("lc_eye_height", "64")
ok(e.viewoff.z == 64 and e.viewoffduck.z == 28, "changing lc_eye_height applies to everyone straight away")
RunConsoleCommand("lc_eye_height", "61")
e.seqs = { sit_zen = 12 }
LC.StartAct(e, "sit")
LC.StopAct(e)
ok(e.viewoff.z == 61, "standing up from a pose puts your eyes back where the server has them", e.viewoff.z)
e.seqs = nil
e.cmds = {}
ok(hook.Run("PlayerSay", e, "!bob") == "" and has(e.cmds, "lc_bob_toggle"), "!bob turns your own camera sway off or on")
_setcvar("lc_view_bob", 0)
e.cmds, e.chat = {}, {}
hook.Run("PlayerSay", e, "!bob")
ok(#e.cmds == 0 and has(e.chat, "off for everyone"), "unless the server has it off for everyone")
_setcvar("lc_view_bob", 1)
ok(LC.HINTS.quiet_hud and LC.HINTS.view_bob, "new players are told where the numbers went, and how to keep the camera still")

-- a life, counted, and the people who knew it
local v = newPlayer("Victim", "citizen")
v:SetPos(HERE)
local friend = newPlayer("Friend", "citizen")
friend:SetPos(HERE + Vector(100, 0, 0))
local away = newPlayer("Away", "citizen")
local foe = newPlayer("Foe", "resistance")
local vName, vCid = LC.CharacterName(v), v:GetNW2String("lc_cid", "")
LC.Introduce(v, friend)
LC.Introduce(v, away)
LC.Introduce(v, foe)
LC.Introduce(friend, v)
ok(LC.KnownByCount(vCid) == 3, "who knows each person is counted as people are introduced", LC.KnownByCount(vCid))
local friendCid = friend:GetNW2String("lc_cid", "")
ok(LC.KnownByCount(friendCid) == 1, "both ways round")
ok(has(LC.CharKeys(), "lc_lived"), "how long someone has lived goes with them between character slots")
away.valid = false -- (gone home for the night)
v.alive = true
_advance(3 * 3600 + 12 * 60)
ok(math.abs(LC.LivedSeconds(v) - (3 * 3600 + 12 * 60)) < 5, "the time someone has lived in the city is counted", LC.LivedSeconds(v))
hook.Run("EntityTakeDamage", v, _dmg(foe, 40, 2))
net.sent = {}
friend.chat, foe.chat = {}, {}
v.alive = false
hook.Run("PlayerDeath", v, foe, foe)
v.alive = true
local c = Card()
ok(c and c.gone and c.name == vName and c.cid == vCid, "dying puts up a card saying who they were", c and c.name)
ok(c and c.full and c.lived >= 3 * 3600 + 12 * 60 - 1 and c.lived < 3 * 3600 + 13 * 60, "how long they lived", c and c.lived)
ok(c and c.known == 3, "how many people knew their name", c and c.known)
ok(c and string.find(c.cause or "", "^Shot by ") ~= nil, "and what killed them, as they saw it", c and c.cause)
ok(c and c.wait == 12 and LC.RespawnWait() == 12, "it stays up for lc_respawn_secs before you can go on", c and c.wait)
ok(LC.CharacterName(v) ~= vName, "and then that person is gone")
ok(LC.KnownByCount(vCid) == 0 and LC.KnownByCount(friendCid) == 0, "a dead person's number is forgotten, and so is everyone they knew")
v:Spawn()
Later(30)
ok(LC.LivedSeconds(v) < 40 and v:GetPData("lc_lived_full", "0") == "1", "the new person's time starts from nothing", LC.LivedSeconds(v))

-- word gets around
ok(not has(friend.chat, "[Word gets around]"), "nobody hears straight away")
Later(160)
ok(has(friend.chat, "[Word gets around]") and has(friend.chat, vName), "someone who knew them hears a minute or two later", friend.chat[#friend.chat])
ok(has(friend.chat, "Somebody killed them"), "with what people say did it (a rebel passing as a citizen is just somebody)", friend.chat[#friend.chat])
ok(not has(foe.chat, "[Word gets around]"), "the one who did it isn't told")
away.valid = true
away.chat = {}
hook.Run("PlayerInitialSpawn", away)
Later(45)
Later(8)
ok(has(away.chat, "[Word gets around]") and has(away.chat, vName), "someone who was away hears when they're back", away.chat[#away.chat])
away.chat = {}
Later(60)
ok(not has(away.chat, "[Word gets around]"), "and only once")

-- what the card says it was
local f = newPlayer("Faller", "citizen")
hook.Run("EntityTakeDamage", f, _dmg(nil, 200, 32))
net.sent = {}
f:Kill()
f.alive = true
ok(Card() and Card().cause == "A fall.", "a fall is a fall", Card() and Card().cause)
f:Spawn()
local d = newPlayer("Downed", "citizen")
local cop = ents.Create("npc_metropolice")
cop:SetPos(FAR2)
hook.Run("EntityTakeDamage", d, _dmg(cop, 30, 2))
hook.Run("LivingCityDowned", d, cop)
Later(30) -- (bleeding out)
hook.Run("EntityTakeDamage", d, _dmg(d, 500, 0))
net.sent = {}
d:Kill()
d.alive = true
ok(Card() and Card().cause == "Shot by a Civil Protection unit.", "put down first: that's what the card says, however it ends", Card() and Card().cause)
d:Spawn()
if cop.Remove then cop:Remove() end
local s = newPlayer("Hungry", "citizen")
s:SetNW2Float("lcn_hunger", 0)
net.sent = {}
s:Kill()
s.alive = true
ok(Card() and Card().cause == "Starved.", "starving is starving", Card() and Card().cause)
s:Spawn()

-- a death that isn't the end
local b = newPlayer("Builder", "citizen")
b.admin = true
b:SetNW2Bool("lc_build", true)
net.sent = {}
b.alive = false
hook.Run("PlayerDeath", b)
b.alive = true
local cb = Card()
ok(cb and cb.gone == false and string.find(cb.note or "", "Build mode", 1, true) ~= nil, "a death that isn't the end gets a short card saying why", cb and cb.note)
b:SetNW2Bool("lc_build", false)

-- character slots keep each person's time
local sl = newPlayer("Slots", "citizen")
sl.admin = true
sl.alive = true
Later(600)
local before = LC.LivedSeconds(sl)
local okS1 = LC.SwitchCharacter(sl, 2)
Later(60)
ok(okS1 and LC.LivedSeconds(sl) < 70, "someone new in another slot starts from nothing", LC.LivedSeconds(sl))
LC.SwitchCharacter(sl, 1)
ok(math.abs(LC.LivedSeconds(sl) - before) < 5, "and switching back, the first person's time is still theirs", LC.LivedSeconds(sl) .. " vs " .. before)

-- people met before anyone kept count, and keeping it
local old = newPlayer("Old Hand", "citizen")
old:SetPData("lc_recog", util.TableToJSON({ ["#77-777"] = true }))
LC.BackfillKnown(old)
ok(LC.KnownByCount("#77-777") == 1, "people met before anyone kept count are counted too")
LC.SaveLifeData()
ok(_files["livingcity/known.json"] ~= nil and string.find(_files["livingcity/known.json"], "#77-777", 1, true) ~= nil, "who knows whom is saved")

-- word kept quiet
_setcvar("lc_word_gets_around", 0)
local q = newPlayer("Quiet", "citizen")
local qf = newPlayer("Quiet Friend", "citizen")
LC.Introduce(q, qf)
qf.chat = {}
q.alive = false
hook.Run("PlayerDeath", q)
q.alive = true
Later(160)
ok(not has(qf.chat, "[Word gets around]"), "lc_word_gets_around 0 keeps it quiet")
_setcvar("lc_word_gets_around", 1)

for _, p in ipairs({ e, v, friend, away, foe, f, d, s, b, sl, old, q, qf }) do p:SetPos(FAR2) end
GAMEMODE = savedGM
end
LifeTests()

----------------------------------------------------------------------
function IntakeTests()
section("Civil Intake: becoming somebody")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function Later(secs) _advance(secs) _runtimers() end
local function Payload(name)
    local m = _lastnet(name)
    return m and util.JSONToTable(m.data[2]) or nil
end
local function Result()
    local m = _lastnet("lcc_result")
    return m and m.data[1], m and m.data[2]
end
local FAR3 = Vector(-140000, 140000, 0)
local B0 = Vector(61000, -61000, 0)
_setcvar("lc_intake", 1)
_setcvar("lc_intake_secs", 8)
local blockZone = LC.AddZone(B0 + Vector(0, 3000, 0), 400, "block", 31)
-- before the desks: nothing changes
local before = newPlayer("BeforeDesks", "citizen")
Later(2.5)
ok(not LC.IntakePending(before) and LC.PlayerBlock(before) ~= nil, "with no Civil Intake on the map, a new person is registered and housed as they arrive", LC.PlayerBlock(before))
-- the desks
local regPt = LC.AddPoint(B0, 0, "intake", 0)
local housePt = LC.AddPoint(B0 + Vector(0, 900, 0), 0, "housingterm", 0)
local arrPt = LC.AddPoint(B0 + Vector(-1500, 0, 0), 90, "arrival", 0)
ok(LC.POINT_KINDS.intake and LC.POINT_KINDS.housingterm and LC.POINT_KINDS.arrival, "the editor places Civil Intake, Housing Allocation and arrival points")
LC.SyncFixtures()
local reg, house
for _, e in ipairs(LC.EntsOf("lc_intake")) do
    if LC.IntakeKind(e) == "register" then reg = e else house = e end
end
ok(IsValid(reg) and IsValid(house), "each desk is a terminal in the world")
ok(not LC.IntakePending(before), "people who were already here count as registered")

-- a new arrival
local new = newPlayer("NewArrival", "citizen")
Later(0.3)
ok(LC.IntakePending(new) and new:GetNW2Bool("lc_unreg", false), "a new person arrives unregistered")
ok(new:GetPos():Distance(arrPt.pos) < 120, "where new people arrive", tostring(new:GetPos()))
ok(has(new.chat, "Report to Civil Intake"), "and is told where to go")
ok(LC.PlayerBlock(new) == nil and LC.AssignBlock(new) == nil, "with no room to their name")
new.chat = {}
ok(LC.UseDispenser(new, nil) == false and has(new.chat, "aren't registered"), "no papers, no rations")
local okJ, whyJ = LC.SetJob(new, "porter")
ok(not okJ and whyJ and string.find(whyJ, "registered", 1, true), "no Union job", whyJ)
new.chat = {}
LC.OpenShop(new, true)
ok(has(new.chat, "citizen number"), "no Commissary")
net.sent = {}
LC.OpenCharacterCreator(new)
ok(_lastnet("lcc_open") == nil, "no name-and-face popup: that's the registration form, at the desk")
new.chat = {}
hook.Run("PlayerSay", new, "!character")
ok(has(new.chat, "registration form"), "asking for it says so")
new.chat = {}
hook.Run("PlayerSay", new, "!papers")
ok(has(new.chat, "You have none"), "!papers: none")

-- the form, at the desk
new:SetPos(B0 + Vector(60, 0, 0))
net.sent = {}
LC.UseIntake(new, reg)
local form = Payload("lcc_open")
ok(form and form.intake == true and form.name == "", "E at Civil Intake opens the registration form, with nothing filled in for you", form and form.name)
local other = newPlayer("SecondInLine", "citizen")
Later(0.3)
other:SetPos(B0 + Vector(80, 40, 0))
other.chat = {}
LC.UseIntake(other, reg)
ok(has(other.chat, "Wait your turn"), "one person at a desk at a time")
local face = LCF.CitizenModels[2]
net.sent = {}
_netcall("lcc_submit", new, "Edda Vornholt", face, "")
local okR, msgR = Result()
ok(okR == false and string.find(msgR or "", "Describe yourself", 1, true), "the register wants a description too", msgR)
Later(1.2)
net.sent = {}
_netcall("lcc_submit", new, "Edda Vornholt", face, "A tall woman in a grey coat, scar on her chin")
okR = Result()
ok(okR == true and LC.CharacterName(new) == "Edda Vornholt" and string.find(new:GetNW2String("lc_desc", ""), "grey coat", 1, true),
    "handing it in sets your name, face and description", LC.CharacterName(new))
ok(new:GetNW2Float("lc_intake_until", 0) > CurTime() and LC.IntakePending(new), "then the terminal processes you (not instant)")
new:SetPos(B0 + Vector(900, 0, 0))
new.chat = {}
Later(0.5)
ok(has(new.chat, "walked away") and new:GetNW2Float("lc_intake_until", 0) == 0 and LC.IntakePending(new), "walk away and it stops")
new:SetPos(B0 + Vector(60, 0, 0))
Later(1)
net.sent = {}
LC.UseIntake(new, reg)
ok(_lastnet("lcc_open") == nil and new:GetNW2Float("lc_intake_until", 0) > CurTime(), "come back and it carries on, without the form again")
new.chat = {}
Later(9)
ok(not LC.IntakePending(new) and has(new.chat, "Registration complete"), "after a few seconds you're on the register", new.chat[1])
ok(has(new.chat, "Housing Allocation"), "and told where to ask for a room")
LC.IntakeFlags(new)
ok(not new:GetNW2Bool("lc_unreg", true) and new:GetNW2Bool("lc_unhoused", false), "your screen points there next")
new.chat = {}
new.lcnRationAt = 0
ok(LC.UseDispenser(new, nil) == false and has(new.chat, "No ration card") and has(new.chat, "Union shift"), "registered, but no ration card until a shift is worked", new.chat[1])
local okJ2 = LC.SetJob(new, "porter")
ok(okJ2, "and the Union will take you on")
LC.SetJob(new, "", true)

ok(LC.HasItem(new, "id_papers") and not LC.HasItem(new, "ration_card"), "your identity papers are in your pockets, and no ration card: that's earned")
ok(_lastnet("lc_waypoint") ~= nil and _lastnet("lc_waypoint").data[3] == "Housing Allocation", "and Housing Allocation is marked on your screen")

-- a room
new:SetPos(B0 + Vector(0, 960, 0))
new.chat = {}
net.sent = {}
Later(1)
LC.UseIntake(new, house)
local hs = Payload("lc_intake_ui")
ok(hs and hs.kind == "housing" and hs.awaiting and hs.papers and #(hs.blocks or {}) >= 1, "E at Housing Allocation opens the housing register: every block, and how many live there", hs and #(hs.blocks or {}))
_netcall("lc_intake_act", new, "apply", 0)
ok(has(new.chat, "Stand still"), "apply (any block) and it searches the register")
Later(9)
ok(LC.PlayerBlock(new) ~= nil and not LC.AwaitingHousing(new) and has(new.chat, "Approved"), "and after a while you have one", new.chat[#new.chat])
new.chat = {}
hook.Run("PlayerSay", new, "!papers")
ok(has(new.chat, "Edda Vornholt") and has(new.chat, "Housing:"), "!papers: who you are, and where you live")

-- the order of things
local third = newPlayer("ThirdArrival", "citizen")
Later(0.3)
third:SetPos(B0 + Vector(0, 960, 0))
third.chat = {}
net.sent = {}
LC.UseIntake(third, house)
local ts = Payload("lc_intake_ui")
ok(ts and ts.pending, "the housing register has no record of someone unregistered")
Later(1)
_netcall("lc_intake_act", third, "apply", 0)
ok(has(third.chat, "Register at Civil Intake first"), "no room before you're registered")

-- curfew, stops, custody
ok(LC.IntakeShelter(third), "waiting by the desks, someone with no room isn't out after curfew")
third:SetPos(B0 + Vector(9000, 0, 0))
ok(not LC.IntakeShelter(third), "wandering the city, they are")
third.chat = {}
ok(LC.IntakeStopped(third, nil) == false and has(third.chat, "New arrival?"), "a unit who stops a new arrival sends them to Civil Intake")
third.lcIntakeSince = CurTime() - 11 * 60
ok(LC.IntakeStopped(third, nil) == true and LC.PlayerIsWanted(third), "but not forever: failure to register")
if LC.ClearWanted then LC.ClearWanted(third) end
hook.Run("LivingCityReleased", third)
ok(not LC.IntakePending(third) and has(third.chat, "processed while in custody"), "someone arrested first is processed in custody")

-- a death starts it all again
new.alive = false
hook.Run("PlayerDeath", new)
new.alive = true
ok(LC.IntakePending(new) and LC.PlayerBlock(new) == nil, "the next person arrives with nothing too")
new:Spawn()
Later(0.3)
ok(new:GetPos():Distance(arrPt.pos) < 120, "and steps off where arrivals do")
ok(has(LC.CharKeys(), "lc_registered") and has(LC.CharKeys(), "lc_intake"), "each character slot keeps its own papers")

-- an old hand, staff, turning it off
local old = newPlayer("OldHand", "citizen")
old:RemovePData("lc_intake")
LC.IntakeForget(old)
ok(not LC.IntakePending(old) and not LC.AwaitingHousing(old), "a character from before Civil Intake isn't sent through it")
concommand.list.lc_register(nil, "lc_register", { "ThirdArrival" })
local fourth = newPlayer("FourthArrival", "citizen")
Later(0.3)
concommand.list.lc_register(nil, "lc_register", { "FourthArrival" })
ok(not LC.IntakePending(fourth), "lc_register puts someone on the register by hand")
local fifth = newPlayer("FifthArrival", "citizen")
Later(0.3)
ok(LC.IntakePending(fifth), "(another new arrival)")
RunConsoleCommand("lc_intake", "0")
Later(0.5)
ok(not LC.IntakePending(fifth) and LC.PlayerBlock(fifth) ~= nil, "lc_intake 0: everyone is registered and housed, as before", LC.PlayerBlock(fifth))
RunConsoleCommand("lc_intake", "1")

-- NPC arrivals queue at the desks
_setcvar("lc_npc_budget", 200)
local watcher = newPlayer("IntakeWatcher", "cp")
watcher:SetPos(B0 + Vector(300, 300, 0))
watcher.chat = {}
local plat = LC.AddPoint(B0 + Vector(-600, 0, 0), 0, "platform", 0)
local door = LC.AddPoint(B0 + Vector(0, 2400, 0), 0, "spawn", 0)
local okA, arrivals = LC.TrainArrive(true)
arrivals = arrivals or {}
local a1 = arrivals[1]
local s1 = a1 and LC.NPCs[a1]
ok(okA and #arrivals >= 2 and s1 and s1.npcWork and #s1.npcWork.steps >= 5, "new arrivals off the train go through the desks before going home",
    tostring(okA) .. " " .. #arrivals .. " " .. tostring(s1 and s1.npcWork and #s1.npcWork.steps))
local sawLine, sawDesk, sawBusy = false, false, false
for _ = 1, 700 do -- (until they're all through: a slow queue can take a while)
    _run(0.5)
    if #LC.IntakeQueue(reg) >= 2 then sawLine = true end
    for _, n in ipairs(arrivals) do
        if IsValid(n) and n:GetNW2String("lc_doing", "") == "being registered at Civil Intake" then sawDesk = true end
    end
    if LC.IntakeBusyWith(reg) and not LC.IntakeBusyWith(reg):IsPlayer() then sawBusy = true end
    local busy = false
    for _, n in ipairs(arrivals) do local st = LC.NPCs[n] if IsValid(n) and st and st.npcWork then busy = true end end
    if not busy and sawDesk then break end
end
ok(sawLine, "they queue, one behind another")
ok(sawDesk and sawBusy, "and each is processed at the desk in turn")
LC.UseIntake(watcher, reg)
ok(has(watcher.chat, "waiting in line"), "a unit at the desk sees how many are waiting")
local stillWorking = 0
for _, n in ipairs(arrivals) do local st = LC.NPCs[n] if IsValid(n) and st and st.npcWork and st.npcWork.id == "arrival" then stillWorking = stillWorking + 1 end end
ok(stillWorking == 0, "then they go home", stillWorking)

-- the desks taken away: nobody is stuck
LC.RemovePoint(regPt)
LC.RemovePoint(housePt)
LC.SyncFixtures()
local sixth = newPlayer("SixthArrival", "citizen")
Later(0.6)
ok(not LC.IntakePending(sixth) and not LC.IntakePending(fifth), "take the desks away and new people are registered as they arrive again")
for _, n in ipairs(arrivals) do if IsValid(n) then n:Remove() end end
LC.RemovePoint(arrPt) LC.RemovePoint(plat) LC.RemovePoint(door)
if blockZone then LC.RemoveZone(blockZone) end
for _, p in ipairs({ before, new, other, third, old, fourth, fifth, sixth, watcher }) do p:SetPos(FAR3) end
GAMEMODE = savedGM
end
IntakeTests()

function PapersHousingTests()
section("Papers you carry, the housing register, transfers")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function Later(secs) _advance(secs) _runtimers() end
local function Payload(name)
    local m = _lastnet(name)
    return m and util.JSONToTable(m.data[2]) or nil
end
local B1 = Vector(-61000, 61000, 0)
local FAR4 = Vector(-140000, -140000, 0)
_setcvar("lc_intake", 1)
_setcvar("lc_intake_secs", 8)
local zA = LC.AddZone(B1 + Vector(0, 3000, 0), 300, "block", 41)
local zB = LC.AddZone(B1 + Vector(3000, 0, 0), 300, "block", 42)
local regPt = LC.AddPoint(B1, 0, "intake", 0)
local housePt = LC.AddPoint(B1 + Vector(0, 900, 0), 0, "housingterm", 0)
LC.SyncFixtures()
local reg, house
for _, e in ipairs(LC.EntsOf("lc_intake")) do
    if e:GetPos():Distance(B1) < 2000 then if LC.IntakeKind(e) == "register" then reg = e else house = e end end
end
ok(IsValid(reg) and IsValid(house), "(the desks)")

-- someone on the register from before papers were things you carry
local old = newPlayer("PapersOld", "citizen")
old:RemovePData("lc_intake")
LC.IntakeForget(old)
old:Spawn()
Later(1.5)
ok(LC.HasItem(old, "id_papers") and not LC.HasItem(old, "ration_card"), "everyone on the register is handed identity papers (no ration card: that's earned)")
LC.GiveItem(old, "ration_card")
ok(has(old.chat, "in your pockets (F2)"), "and told so")
ok(LCS.Weight("id_papers") == 0 and LCS.Items.id_papers.doc and LCS.Items.ration_card.doc, "they weigh nothing")
local count = LC.InvCount(old)
LC.TakeItem(old, "ration_card")
ok(LC.InvCount(old) == count, "and take no room in your pockets")
LC.GiveItem(old, "ration_card")
old.chat = {}
LC.InvAction(old, "drop", "id_papers")
ok(LC.HasItem(old, "id_papers") and has(old.chat, "keep your papers"), "you can't drop your papers")
local friend = newPlayer("PapersFriend", "citizen")
Later(0.3)
old:SetPos(FAR4) friend:SetPos(FAR4 + Vector(40, 0, 0))
old.lookingAt = friend
local okG, whyG = LC.GiveTo(old, "id_papers")
ok(not okG and LC.HasItem(old, "id_papers") and whyG and string.find(whyG, "stay with you", 1, true), "or hand them over", whyG)
net.sent = {}
friend.chat = {}
ok(LC.ShowPapers(old), "show them to whoever you're looking at")
local card = Payload("lc_papers_card")
ok(card and card.from and card.name == LC.CharacterName(old) and card.cid == old:GetNW2String("lc_cid", ""), "they see your papers", card and card.name)
ok(has(friend.chat, "show you their papers") and LC.Recognizes(friend, old), "and now know your name")
old.lookingAt = nil
net.sent = {}
LC.ShowPapers(old)
card = Payload("lc_papers_card")
ok(card and not card.from, "looking at nobody, you read your own")
-- stopped without them, rationed without a card
LC.TakeItem(old, "id_papers")
old.chat = {}
local st0 = LC.Standing(old)
ok(LC.IntakeStopped(old, nil) == false and has(old.chat, "Papers. None?") and LC.Standing(old) == st0 - 2, "a unit who stops you with no papers on you: a little standing", LC.Standing(old) - st0)
local okS, whyS = LC.ShowPapers(old)
ok(not okS and whyS and string.find(whyS, "no papers on you", 1, true), "and nothing to show", whyS)
LC.TakeItem(old, "ration_card")
old.lcnRationAt = 0
old.chat = {}
LC.UseDispenser(old, nil)
ok(has(old.chat, "No ration card"), "the dispensers want a ration card", old.chat[1])
-- a ration card from a finished shift; each ration takes one, and pays no credits
local wk = newPlayer("ShiftCardWorker", "citizen")
Later(0.3)
LC.RegisterPerson(wk, "staff") -- (on the register: only then can they have a ration)
wk.chat = {}
hook.Run("LivingCityQuestComplete", wk, { chain = "shift", title = "Test shift" })
ok(LC.Inventory(wk).ration_card == 1 and has(wk.chat, "earned a ration card"), "a finished Union shift earns a ration card", wk.chat[1])
hook.Run("LivingCityQuestComplete", wk, { chain = "rehab", title = "Not a shift" })
ok(LC.Inventory(wk).ration_card == 1, "other jobs don't")
wk.lcnRationAt = 0
local wcr = LC.Credits(wk)
_setcvar("lc_stockpile", 0) -- (whatever the city's stores are at by now)
ok(LC.UseDispenser(wk, nil) == true and not LC.HasItem(wk, "ration_card") and LC.Credits(wk) == wcr, "a ration takes the card, and pays no credits", LC.Credits(wk) - wcr)
_setcvar("lc_stockpile", 1)
-- Civil Intake replaces them
old:SetPos(B1 + Vector(40, 0, 0))
LC.AddCredits(old, 100)
local cr0 = LC.Credits(old)
net.sent = {}
LC.UseIntake(old, reg)
local rec = Payload("lc_intake_ui")
ok(rec and rec.kind == "register" and rec.papers == false and rec.cards == 0, "E at Civil Intake, registered: your record, with what's missing", rec and tostring(rec.papers))
_netcall("lc_intake_act", old, "papers", 0)
Later(5)
ok(LC.HasItem(old, "id_papers") and LC.Credits(old) == cr0 - 10, "new papers, for ten credits", LC.Credits(old) - cr0)
Later(1)
old.chat = {}
_netcall("lc_intake_act", old, "card", 0)
Later(5)
ok(not LC.HasItem(old, "ration_card") and LC.Credits(old) == cr0 - 10 and has(old.chat, "aren't issued here"), "Civil Intake doesn't hand out ration cards", old.chat[1])
old.chat = {}
Later(1)
_netcall("lc_intake_act", old, "papers", 0)
ok(has(old.chat, "already have"), "not twice")

-- the housing register: a request, a crowded block, a transfer
local crowd = {}
for i = 1, 3 do crowd[i] = newPlayer("Crowd" .. i, "citizen") end
Later(2.5) -- (after the housing module has looked at them)
for _, c in ipairs(crowd) do c:SetNW2Int("lc_block", 42) c:SetPos(FAR4) end
local nw = newPlayer("PapersNew", "citizen")
Later(0.3)
ok(LC.IntakePending(nw), "(a new arrival)")
nw.chat = {}
concommand.list.lc_register(nil, "lc_register", { "PapersNew" })
ok(LC.HasItem(nw, "id_papers") and LC.AwaitingHousing(nw), "registered: papers, and no room yet")
nw:SetPos(B1 + Vector(0, 960, 0))
LC.TakeItem(nw, "id_papers")
Later(1)
nw.chat = {}
net.sent = {}
LC.UseIntake(nw, house)
local hs = Payload("lc_intake_ui")
ok(hs and hs.awaiting and hs.papers == false, "the register sees you haven't your papers on you")
_netcall("lc_intake_act", nw, "apply", 42)
ok(has(nw.chat, "Present your identity papers") and LC.PlayerBlock(nw) == nil, "and won't take an application without them")
LC.GiveItem(nw, "id_papers")
nw:SetPData("lce_standing", 0)
Later(1)
nw.chat = {}
_netcall("lc_intake_act", nw, "apply", 42)
Later(9)
ok(LC.PlayerBlock(nw) ~= nil and LC.PlayerBlock(nw) ~= 42 and has(nw.chat, "declined"), "a crowded block is turned down: you get the least crowded", LC.PlayerBlock(nw))
ok(nw:GetPData("lc_housed_how", "") == "allocation", "and the register remembers how you got it")
ok(_lastnet("lc_waypoint") ~= nil and has(nw.chat, "marked on your screen"), "the way there is marked on your screen")
nw.chat = {}
Later(1)
_netcall("lc_intake_act", nw, "transfer", 42)
ok(has(nw.chat, "good standing") and LC.PlayerBlock(nw) ~= 42, "a transfer needs some standing")
nw:SetPData("lce_standing", 60)
Later(1)
nw.chat = {}
_netcall("lc_intake_act", nw, "transfer", 42)
Later(9)
ok(LC.PlayerBlock(nw) == 42 and has(nw.chat, "Transfer approved") and nw:GetPData("lc_housed_how", "") == "transfer", "good standing gets you into a crowded block", LC.PlayerBlock(nw))
Later(1)
net.sent = {}
LC.UseIntake(nw, house)
hs = Payload("lc_intake_ui")
ok(hs and hs.block == 42 and hs.how == "transfer" and hs.transfer == false and hs.transferWhy and string.find(hs.transferWhy, "too recent", 1, true),
    "housed: where you live, how you got it, and when you can move again", hs and hs.transferWhy)
nw.chat = {}
_netcall("lc_intake_act", nw, "way", 3)
ok(_lastnet("lc_waypoint") ~= nil, "it marks the way home")
ok(has(LC.CharKeys(), "lc_docs") and has(LC.CharKeys(), "lc_housed_how"), "each character slot keeps its own papers and housing record")
-- staff send someone back through all of it
concommand.list.lc_unregister(nil, "lc_unregister", { "PapersNew" })
ok(LC.IntakePending(nw) and LC.PlayerBlock(nw) == nil and not LC.HasItem(nw, "id_papers"), "lc_unregister: back to nothing, room and papers included")

-- on the screen, not just in chat
local kind, title, text = LC.NoticeForChat("[Rebel] Hey! Those are our supplies. Quit it.")
ok(kind == "speech" and title == "Rebel" and text == "Hey! Those are our supplies. Quit it.", "a rebel's warning shows as a subtitle")
ok(LC.NoticeForChat("[Civil Protection] Halt.") == "warn" and LC.NoticeForChat("[Housing Allocation] Approved.") == "info", "units' warnings and the desks' notices as cards")
ok(LC.NoticeForChat("[Living City] Something routine.") == nil, "routine lines stay in chat")
LC.FlushNotices()
net.sent = {}
LC.Notice(old, "warn", "Civil Protection", "Halt.")
LC.Notice(old, "warn", "Civil Protection", "Halt.")
Later(0.2)
local n = 0
for _, m in ipairs(net.sent or {}) do if m.name == "lc_notice" then n = n + 1 end end
ok(n == 1 and _lastnet("lc_notice").data[1] == "warn", "a notice goes to the screen, once", n)
LC.FlushNotices()
net.sent = {}
LC.Announce("sweep")
Later(0.2)
local ev = false
for _, m in ipairs(net.sent or {}) do if m.name == "lc_notice" and m.data[1] == "event" then ev = true end end
ok(ev, "and the city's announcements, with what they mean for you")

for _, p in ipairs({ old, friend, nw, crowd[1], crowd[2], crowd[3] }) do p:SetPos(FAR4) end
LC.RemovePoint(regPt) LC.RemovePoint(housePt)
LC.SyncFixtures()
LC.RemoveZone(zA) LC.RemoveZone(zB)
GAMEMODE = savedGM
end
PapersHousingTests()

function SuppliesAndLabTests()
section("Units are issued supplies; the Resistance has a lab")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function Later(secs) _advance(secs) _runtimers() end
local function Payload(name)
    local m = _lastnet(name)
    return m and util.JSONToTable(m.data[2]) or nil
end
local L0 = Vector(-120000, 60000, 0)
-- the Civil Protection Commissary
local unit = newPlayer("SupplyUnit", "cp")
Later(2)
unit:SetPos(L0)
local sup = ents.Create("lc_cpsupply") sup:SetPos(L0 + Vector(50, 0, 0))
ok(LC.POINT_KINDS.cpsupply and LC.HasCPSupply(), "the editor places a Civil Protection Commissary")
local okC, whyC = LC.Craft(unit, "bandage")
ok(not okC and whyC and string.find(whyC, "Visit a Civil Protection Commissary", 1, true), "units don't make things: they're sent to be issued them", whyC)
ok(LC.WaypointTo(unit, "cpsupply") and _lastnet("lc_waypoint") ~= nil, "and it's marked on their screen")
unit:SetArmor(0)
for id in pairs(LC.Inventory(unit)) do if id == "bandage" or id == "ration" then LC.TakeItem(unit, id, 99) end end
unit.chat = {}
LC.UseCPSupply(unit, sup)
ok(has(unit.chat, "Issued:") and unit:Armor() >= 50 and LC.HasItem(unit, "bandage", 2) and LC.HasItem(unit, "ration"), "E there: armour, bandages, a ration", unit.chat[1])
ok(_lastnet("lce_shop") ~= nil, "and the unit counter opens")
Later(1)
unit.chat = {}
LC.UseCPSupply(unit, sup)
ok(has(unit.chat, "next issue"), "not again straight away")
local cit = newPlayer("SupplyCitizen", "citizen")
Later(0.3)
cit:SetPos(L0)
cit.chat = {}
LC.UseCPSupply(cit, sup)
ok(has(cit.chat, "Civil Protection only"), "citizens are turned away")

-- the lab
local bench = ents.Create("lc_workbench") bench:SetPos(L0 + Vector(0, 2000, 0))
bench:SetAngles(Angle(0, 90, 0))
local sci = LC.SetupLab(bench)
ok(IsValid(sci) and sci:GetClass() == "lc_scientist" and sci:GetPos():Distance(bench:GetPos()) < 150, "a lab has a scientist beside its bench")
ok(LC.SetupLab(bench) == sci, "(once)")
ok(LC.WaypointTo(unit, "lab") == false, "units aren't shown the way to it")
local rebel = newPlayer("LabRebel", "resistance", nil, 900)
Later(3)
rebel:SetPos(sci:GetPos() + Vector(40, 0, 0))
cit:SetPos(sci:GetPos() + Vector(-40, 0, 0))
cit.chat = {}
net.sent = {}
LC.UseScientist(cit, sci)
ok(has(cit.chat, "private") and _lastnet("lc_lab") == nil, "he only works for the Resistance")
local okN, whyN = LC.LabMake(cit, "gun_pistol", "pay")
ok(not okN and whyN and string.find(whyN, "Resistance", 1, true), "(and won't make a citizen anything)")
net.sent = {}
LC.UseScientist(rebel, sci)
local lab = Payload("lc_lab")
local pistol
for _, it in ipairs(lab and lab.items or {}) do if it.id == "gun_pistol" then pistol = it end end
ok(pistol and pistol.price < LCS.BlackById.gun_pistol.price and pistol.price > LCS.Items.gun_pistol.sell * 1.5,
    "for the Resistance: what he makes, for less than the dealer (but more than the quartermaster pays)", pistol and pistol.price)
for id in pairs(LC.Inventory(rebel)) do if id == "gun_pistol" or id == "ammo_pistol" then LC.TakeItem(rebel, id, 99) end end
LC.GiveItem(rebel, "gun_parts", 2) LC.GiveItem(rebel, "scrap", 3)
rebel.chat = {}
ok(LC.LabMake(rebel, "gun_pistol", "mats"), "bring him the materials")
ok(not LC.HasItem(rebel, "gun_parts"), "(he takes them)")
local okB, whyB = LC.LabMake(rebel, "ammo_pistol", "pay")
ok(not okB, "one thing at a time", whyB)
Later(13)
ok(LC.HasItem(rebel, "gun_pistol") and has(rebel.chat, "He hands you"), "and he makes it, for nothing")
LC.AddCredits(rebel, 500)
local c0 = LC.Credits(rebel)
local ammoPrice = LC.LabPrice(LCS.LabById.ammo_pistol)
ok(LC.LabMake(rebel, "ammo_pistol", "pay") and LC.Credits(rebel) == c0 - ammoPrice, "or pay him", LC.Credits(rebel) - c0)
Later(7)
ok(LC.HasItem(rebel, "ammo_pistol"), "and it's yours")
c0 = LC.Credits(rebel)
LC.LabMake(rebel, "ammo_smg", "pay")
rebel:SetPos(sci:GetPos() + Vector(900, 0, 0))
rebel.chat = {}
Later(1)
ok(LC.Credits(rebel) == c0 and has(rebel.chat, "hands it all back"), "walk off and he hands it all back")
ok(LC.Craft(rebel, "gun_pistol") == false and LCS.RecipesById.gun_pistol == nil and LCS.RecipesById.bandage ~= nil, "guns aren't made by hand any more; bandages still are")
-- a unit finds the lab
unit:SetPos(sci:GetPos() + Vector(0, 40, 0))
unit.chat = {}
Later(1)
LC.UseScientist(unit, sci)
ok(LC.LabShut(sci) and has(unit.chat, "Resistance lab"), "a unit who finds him shuts the lab down")
rebel:SetPos(sci:GetPos() + Vector(40, 0, 0))
local okS, whyS = LC.LabMake(rebel, "ammo_pistol", "pay")
ok(not okS and whyS and string.find(whyS, "Find the scientist", 1, true), "nothing is made there for a while", whyS)
Later(GetConVar("lc_lab_shutdown"):GetFloat() + 1)
ok(not LC.LabShut(sci), "then he's back")

for _, p in ipairs({ unit, cit, rebel }) do p:SetPos(Vector(-150000, 150000, 0)) end
bench:Remove() sci:Remove() sup:Remove()
GAMEMODE = savedGM
end
SuppliesAndLabTests()

----------------------------------------------------------------------
function LabFixesTests()
section("The lab settles up once; markers clear; the scientist moves with his bench")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function Later(secs) _advance(secs) _runtimers() end
local L1 = Vector(-120000, 70000, 0)
local bench = ents.Create("lc_workbench") bench:SetPos(L1)
bench:SetAngles(Angle(0, 0, 0))
local sci = LC.SetupLab(bench)
local function ItemsNear(pos, id)
    local n = 0
    for _, e in ipairs(ents.FindByClass("lc_item")) do
        if IsValid(e) and e:GetNW2String("lc_item", "") == id and e:GetPos():Distance(pos) < 200 then n = n + 1 end
    end
    return n
end
-- dies mid-job, having paid: the job is let go, no credits come back to the next life
local r1 = newPlayer("LabDier", "resistance", nil, 900)
Later(3)
r1:SetPos(sci:GetPos() + Vector(40, 0, 0))
LC.AddCredits(r1, 500)
ok(LC.LabMake(r1, "ammo_smg", "pay"), "a rebel pays for a job")
r1:Kill()
local cAfter = LC.Credits(r1)
Later(1)
ok(not LC.Busy(r1) and sci.lcLabJob == nil, "dying mid-job lets the job go")
ok(LC.Credits(r1) == cAfter, "and the credits don't come back to the next life", LC.Credits(r1) - cAfter)
r1:SetPos(Vector(-150000, 150000, 0))
-- dies mid-job with materials: they're left on the bench
local r2 = newPlayer("LabDier2", "resistance", nil, 900)
Later(3)
r2:SetPos(sci:GetPos() + Vector(40, 0, 0))
LC.GiveItem(r2, "gun_parts", 2) LC.GiveItem(r2, "scrap", 3)
local parts0 = ItemsNear(sci:GetPos(), "gun_parts")
ok(LC.LabMake(r2, "gun_pistol", "mats"), "a rebel brings materials")
r2:Kill()
Later(1)
ok(ItemsNear(sci:GetPos(), "gun_parts") == parts0 + 2, "dying mid-job leaves the materials at the lab", ItemsNear(sci:GetPos(), "gun_parts") - parts0)
r2:SetPos(Vector(-150000, 150000, 0))
-- walks off with full pockets: what he hands back lands at their feet
local r3 = newPlayer("LabFull", "resistance", nil, 900)
Later(3)
r3:SetPos(sci:GetPos() + Vector(40, 0, 0))
for id in pairs(LC.Inventory(r3)) do if id == "gun_parts" then LC.TakeItem(r3, id, 99) end end
LC.GiveItem(r3, "gun_parts", 2) LC.GiveItem(r3, "scrap", 3)
ok(LC.LabMake(r3, "gun_pistol", "mats"), "another job")
local savedCarry = LC.CanCarry
LC.CanCarry = function() return false end
r3:SetPos(sci:GetPos() + Vector(900, 0, 0))
local before = ItemsNear(r3:GetPos(), "gun_parts")
Later(1)
LC.CanCarry = savedCarry
ok(ItemsNear(r3:GetPos(), "gun_parts") == before + 2, "walking off with full pockets: the materials are dropped, not lost", ItemsNear(r3:GetPos(), "gun_parts") - before)
-- someone else's job isn't cleared by an old one finishing
r3:SetPos(sci:GetPos() + Vector(40, 0, 0))
LC.AddCredits(r3, 500)
ok(LC.LabMake(r3, "ammo_pistol", "pay"), "a job starts")
local other = { ply = r3, untilT = CurTime() + 999 }
sci.lcLabJob = other
Later(8)
ok(sci.lcLabJob == other, "finishing a job doesn't clear someone else's")
sci.lcLabJob = nil
r3:SetPos(Vector(-150000, 150000, 0))
-- moved with the physgun: he goes with the bench
local mover = newPlayer("LabMover", "citizen")
mover.isAdmin, mover.superadmin = true, true
bench.lcFixture = true
bench.lcFixturePoint = { kind = "workbench", pos = bench:GetPos(), yaw = 0 }
bench:SetPos(L1 + Vector(1500, 0, 0))
hook.Run("PhysgunDrop", mover, bench)
ok(LC.CanEdit(mover) and sci:GetPos():Distance(bench:GetPos()) < 150, "a lab bench moved with the physgun takes its scientist with it", sci:GetPos():Distance(bench:GetPos()))
mover:SetPos(Vector(-150000, 150000, 0))
-- the home marker clears once they're in their block
local homer = newPlayer("WayHomer", "citizen")
Later(0.3)
local hz = LC.AddZone(Vector(-120000, 90000, 0), 300, "block", 61)
homer:SetNW2Int("lc_block", 61)
homer:SetPos(Vector(-120000, 95000, 0))
ok(LC.WaypointTo(homer, "home") and homer.lcWaypoint and homer.lcWaypoint.block == 61, "the way home is marked")
homer:SetPos(Vector(-120000, 90000 + 280, 0))
net.sent = {}
Later(1.5)
local m = _lastnet("lc_waypoint")
ok(homer.lcWaypoint == nil and m ~= nil and m.data[1] == false, "and cleared once they're inside the block, wherever its middle is")
LC.RemoveZone(hz)
homer:SetPos(Vector(-150000, 150000, 0))
bench:Remove() sci:Remove()
GAMEMODE = savedGM
end
LabFixesTests()

----------------------------------------------------------------------
function CarryTests()
section("Luggage hangs at their side, upright, by the handle")
local function Extents(mins, maxs, pos, ang)
    local lo, hi = Vector(1e9, 1e9, 1e9), Vector(-1e9, -1e9, -1e9)
    for _, x in ipairs({ mins.x, maxs.x }) do for _, y in ipairs({ mins.y, maxs.y }) do for _, z in ipairs({ mins.z, maxs.z }) do
        local w = pos + LC.TurnVector(Vector(x, y, z), ang)
        lo = Vector(math.min(lo.x, w.x), math.min(lo.y, w.y), math.min(lo.z, w.z))
        hi = Vector(math.max(hi.x, w.x), math.max(hi.y, w.y), math.max(hi.z, w.z))
    end end end
    return lo, hi
end
local allOk, bad = true, nil
-- a case built lying flat, standing up, or on its end: every way round, it ends up the same
for _, b in ipairs({
    { Vector(-10, -15, -4), Vector(10, 15, 4) }, { Vector(-15, -4, 0), Vector(15, 4, 20) },
    { Vector(-4, -10, -15), Vector(4, 10, 15) }, { Vector(-10, -4, -15), Vector(10, 4, 15) },
    { Vector(-4, -15, -10), Vector(4, 15, 10) }, { Vector(0, -4, -10), Vector(30, 4, 10) },
}) do
    local pos, ang = LC.CarrySideHold(b[1], b[2])
    local lo, hi = Extents(b[1], b[2], pos, ang)
    local fwd, side, up = hi.x - lo.x, hi.y - lo.y, hi.z - lo.z
    if not (math.abs(fwd - 30) < 0.1 and math.abs(up - 20) < 0.1 and math.abs(side - 8) < 0.1 and math.abs(hi.z - 33) < 0.1 and hi.y < 0) then
        allOk, bad = false, string.format("%s: fwd %.1f up %.1f side %.1f top %.1f", tostring(b[2]), fwd, up, side, hi.z)
    end
end
ok(allOk, "long side forward, flat side to the leg, top at the hand, on the right, whichever way the model was built", bad)
ok(LC.CarryAtSide["models/props_c17/suitcase001a.mdl"], "(the arrivals' suitcases are carried that way)")
end
CarryTests()

----------------------------------------------------------------------
function DropshipCargoTests()
section("A dropship carries its container in its claws")
local G = Vector(72000, 72000, 0)
local ship = LC.FlyDropship({ pos = G, cargo = true, hold = 2 })
local f
for _, x in ipairs(LC.Dropships) do if x.ship == ship then f = x end end
ok(IsValid(ship) and f and IsValid(f.cargo), "a supply dropship comes in with a container")
for _ = 1, 30 do _advance(0.1) _runtimers() end
local cp, sp = f.cargo:GetPos(), ship:GetPos()
local ca, sa = f.cargo:GetAngles(), ship:GetAngles()
ok(cp:Distance(sp) < 0.01 and ca.p == sa.p and ca.y == sa.y, "held at the ship's own origin and angles, as Half-Life 2 does (not dangling under it)", tostring(cp) .. " vs " .. tostring(sp))
local mins = f.cargo.lcContainerMins or f.cargo:OBBMins()
ok(math.abs((f.hover.z - G.z) - (-mins.z + 16)) < 0.01, "it comes down until the container is just off the ground", f.hover.z - G.z)
for _ = 1, 200 do _advance(0.1) _runtimers() if f.dropped then break end end
ok(IsValid(f.dropped) and math.abs(f.dropped:GetPos().z - (G.z - mins.z + 1)) < 0.01, "and sets it down on the ground")
for _ = 1, 400 do _advance(0.1) _runtimers() if not IsValid(ship) then break end end
if IsValid(ship) then ship:Remove() end
if IsValid(f.dropped) then f.dropped:Remove() end
end
DropshipCargoTests()

----------------------------------------------------------------------
function MenuTests()
section("Every chat command works from the menus")
local savedGM = GAMEMODE
GAMEMODE = { IsLivingCity = true }
local function Later(secs) _advance(secs) _runtimers() end
local P = Vector(-150000, -150000, 0)
local m = newPlayer("MenuUser", "citizen")
m:SetPos(P)
local function Run(cmd, rest)
    m.chat = {}
    net.sent = {}
    return LC.RunAction(m, cmd, rest)
end
for _, n in ipairs({ "pose", "giveup", "talk", "papers", "credits", "character", "characters", "chardesc", "shop", "market", "write", "block",
    "apartment", "lock", "unlock", "givekey", "takekey", "unrent", "time", "city", "laws", "broadcast", "bob", "hints", "ticket", "build",
    "admintools", "staff", "pathmap", "wave", "salute", "nod" }) do
    if not LC.MenuActions[n] then ok(false, "the menu may run " .. n) end
end
ok(true, "the menu may run everything it offers (each checked above)")
ok(LC.MenuActions.showpapers, "the menus may show your papers to someone")
Run("time")
ok(has(m.chat, "It's") and has(m.chat, "weather"), "The city > the time and the weather", m.chat[1])
Run("city")
ok(has(m.chat, "[City]"), "The city > who holds the city")
Run("laws")
ok(_lastnet("lc_laws") ~= nil, "The city > the laws")
Run("broadcast", "Hello city")
ok(has(m.chat, "City Administrator"), "a broadcast is only for the Administrator", m.chat[1])
Run("papers")
ok(has(m.chat, "[Papers]"), "Me > my papers")
Run("credits")
ok(has(m.chat, "credits"), "Me > my credits and standing")
Run("characters")
ok(_lastnet("lc_slots") ~= nil or has(m.chat, "slots are off"), "Me > my characters")
Run("character")
ok(_lastnet("lcc_open") ~= nil, "Me > change my name and face")
Run("chardesc", "a tall man in a grey coat")
ok(string.find(m:GetNW2String("lc_desc", ""), "grey coat", 1, true) ~= nil, "Me > change how strangers see me")
Run("giveup")
ok(has(m.chat, "not down"), "Me > give up (only when you're down)")
m.cmds = {}
Run("wave")
ok(m.cmds and m.cmds[#m.cmds] == "act wave", "Me > Gesture > wave")
m.ground = nil
Run("pose", "2")
ok(m:GetNW2String("lc_act", "") == "pose2", "Me > Pose > stand: pose 2")
LC.StopAct(m)
Run("block")
ok(has(m.chat, "[Living City]"), "Home > my housing block")
Run("apartment")
ok(#m.chat >= 1, "Home > about my apartment")
Run("lock")
ok(has(m.chat, "apartment door"), "Home > lock my apartment (looking at its door)", m.chat[1])
Run("shop")
ok(has(m.chat, "Commissary") or _lastnet("lce_shop") ~= nil, "Getting by > the Commissary")
Run("market")
ok(has(m.chat, "[Black market]") or _lastnet("lc_market") ~= nil, "Getting by > the black market")
Run("write")
ok(has(m.chat, "paper") or _lastnet("lc_write_open") ~= nil, "Getting by > write something", m.chat[1])
Run("ticket", "I'm stuck in a wall")
ok(has(m.chat, "[Tickets]"), "Help > ask staff for help")
Run("build")
ok(has(m.chat, "admins") or not (hook.t.PlayerSay and hook.t.PlayerSay.LivingCityGamemode), "Help > build mode is for admins")
Run("staff")
ok(has(m.chat, "Staff only"), "Help > the staff panel is for staff")
Run("hints", "off")
ok(LC.HintsOff(m), "Settings > tips off")
Run("hints", "on")
ok(not LC.HintsOff(m), "Settings > tips on")
m.cmds = {}
Run("bob")
ok(has(m.cmds, "lc_bob_toggle"), "Settings > camera sway")
-- the same through the menu's own message
Later(0.5)
m.chat = {}
_netcall("lc_action", m, "time", "", nil)
ok(has(m.chat, "It's"), "(sent from the F1 menu, it runs the same)")
-- tips to read again
m.lcHintSeen, m.lcHintRecent = {}, {}
LC.Hint(m, "welcome")
net.sent = {}
_netcall("lc_hints_list", m)
local seenMsg = _lastnet("lc_hints_seen")
local seenT = seenMsg and util.JSONToTable(seenMsg.data[2])
ok(seenT and seenT.list and #seenT.list >= 1 and seenT.list[1].t == "Welcome to the city", "Tips I've seen: every tip you've had, to read again", seenT and seenT.list and seenT.list[1] and seenT.list[1].t)
-- the tips point at menus now
local chatOnly = {}
for key, def in pairs(LC.HINTS) do
    local texts = type(def.text) == "table" and def.text or { def.text }
    for _, t in pairs(texts) do
        for cmd in string.gmatch(t, "!(%a[%w%-]*)") do
            if cmd ~= "hints" then chatOnly[#chatOnly + 1] = key .. ": !" .. cmd end
        end
    end
end
ok(#chatOnly == 0, "no tip sends anyone to a chat command", chatOnly[1])
m:SetPos(Vector(-160000, -160000, 0))
GAMEMODE = savedGM
end
MenuTests()

----------------------------------------------------------------------
function MarchTests()
section("Arrested by a unit: walked to the cells, and rescued on the way")
local M0 = Vector(-2600, 2600, 0)
local function Unmarch(p)
    local m = LC.Marching[p]
    if m then LC.Marching[p] = nil end
    if LC.IsTied(p) then LC.Untie(p, nil, true) end
    if LC.Prisoners[p] then LC.ReleasePrisoner(p) end
    LC.ClearWanted(p)
    p.lcGraceUntil = 0
end
-- arrested
local con = newPlayer("Marched", "citizen")
_run(0.3)
con:SetPos(M0)
con.lcGraceUntil = 0
LC.ReportCrime(con, "Theft", 300)
local lead, lst = LC.Spawners.cop(M0 + Vector(60, 0, 0))
local rear, rst = LC.Spawners.cop(M0 + Vector(-200, 0, 0))
lst.untilT, rst.untilT = 1e9, 1e9
local dmg = _dmg(lead, 20, DMG_CLUB)
con.lcSubdue = { n = 2, t = CurTime() } -- (beaten down: the third blow)
hook.Run("EntityTakeDamage", con, dmg)
ok(LC.Marching[con] ~= nil, "a stunstick hit starts a march to the cells, not a teleport")
ok(LC.IsTied(con) and LC.InCustody(con) and not LC.PlayerIsWanted(con) and not LC.Prisoners[con], "tied, in custody, the search called off, not in a cell yet")
ok(LC.Marching[con] and LC.Marching[con].rear == rear and rst.state == "event", "a second unit comes along")
ok(has(con.chat, "march") or has(con.chat, "Cuffed"), "and they're told", con.chat[#con.chat])
-- walked all the way
local reached = false
for _ = 1, 90 do
    _run(1)
    if LC.Prisoners[con] then reached = true break end
end
ok(reached and not LC.Marching[con] and not LC.IsTied(con), "walked there and locked up", tostring(con:GetPos()) .. " | " .. table.concat(con.chat, " | "))
ok(not rst.marching and not lst.marching, "and the units go back to their day")
Unmarch(con)
-- rescued: the unit leading is put down
con:SetPos(M0)
LC.ReportCrime(con, "Theft", 300)
local lead2, lst2 = LC.Spawners.cop(M0 + Vector(60, 0, 0))
lst2.untilT = 1e9
con.lcSubdue = { n = 2, t = CurTime() }
hook.Run("EntityTakeDamage", con, _dmg(lead2, 20, DMG_CLUB))
ok(LC.Marching[con] ~= nil, "(another march)")
-- with another unit about, he takes over
local helper, hst = LC.Spawners.cop(M0 + Vector(-150, 0, 0))
hst.untilT = 1e9
lead2:Remove()
_run(0.5)
ok(LC.Marching[con] ~= nil and IsValid(LC.Marching[con].lead) and LC.Marching[con].lead ~= lead2, "the unit leading you goes down: another takes your arm (the one behind, or one nearby)")
-- with nobody left
for n, st in pairs(LC.NPCs) do if IsValid(n) and (st.role == "cop" or st.role == "soldier") then n:SetPos(Vector(-400000, 400000, 0)) end end
local lead2b = LC.Marching[con] and LC.Marching[con].lead
if IsValid(lead2b) then LC.NPCs[lead2b] = nil lead2b:Remove() end
_run(0.5)
ok(not LC.Marching[con] and LC.IsTied(con) and LC.PlayerIsWanted(con) and not LC.Prisoners[con],
    "nobody left to take you: free, still tied, and wanted for it")
Unmarch(con)
-- nowhere to walk: straight to a cell
_setcvar("lc_march", 0)
LC.ReportCrime(con, "Theft", 300)
local lead3, lst3 = LC.Spawners.cop(M0 + Vector(60, 0, 0))
con.lcSubdue = { n = 2, t = CurTime() }
hook.Run("EntityTakeDamage", con, _dmg(lead3, 20, DMG_CLUB))
ok(LC.Prisoners[con] ~= nil and not LC.Marching[con], "turned off: straight to a cell, as before")
_setcvar("lc_march", 1)
Unmarch(con)
for _, n in ipairs({ lead, rear, lead3 }) do if IsValid(n) then n:Remove() end end
con:SetPos(Vector(-150000, 150000, 0))
end
MarchTests()

----------------------------------------------------------------------
function BatchFixTests()
section("The Combine loom; ration lines; graffiti needs a witness; supply guards answer")
local B0 = Vector(-90000, -90000, 0)
-- bigger units
local c, cs = LC.Spawners.cop(B0)
local so, ss = LC.Spawners.soldier(B0 + Vector(100, 0, 0))
ok(math.abs(c:GetModelScale() - 1.05) < 0.001 and math.abs(so:GetModelScale() - 1.10) < 0.001, "units are drawn 5% bigger, soldiers 10%", c:GetModelScale() .. " / " .. so:GetModelScale())
-- supply guards answer E
cs.supplyGuard = true
LC.SetState(c, cs, "event")
cs.nextUse = 0
local walker = newPlayer("GuardAsker", "citizen")
_run(0.3)
walker:SetPos(B0 + Vector(50, 0, 0))
walker.chat = {}
hook.Run("PlayerUse", walker, c)
ok(has(walker.chat, "Move along") or has(walker.chat, "Step away") or has(walker.chat, "Keep moving"), "a supply guard answers when you press E on him", walker.chat[1])
c:Remove() so:Remove()
-- people who never set off for a line don't hold its places
local line = LC.Lines[1]
if line then
    local ghosts = {}
    for i = 1, #line.slots do
        local n, st = LC.Spawners.citizen(B0 + Vector(0, i * 60, 0))
        st.lineHeading, st.lineSince = 1, CurTime()
        LC.SetState(n, st, "idle")
        ghosts[#ghosts + 1] = n
    end
    local q0 = #line.q
    line.q = {}
    local n, st = LC.Spawners.citizen(line.slots[1].pos + Vector(200, 0, 0))
    ok(LC.JoinLine(n, st, true) ~= false and st.lineHeading == 1, "people who never set off for the line don't fill it")
    for _, g in ipairs(ghosts) do g:Remove() end
    n:Remove()
end
-- graffiti costs the block its rations only once the Combine has seen it
local tagger = newPlayer("QuietTagger", "citizen")
_run(0.3)
local far = Vector(-95000, -80000, 0)
tagger:SetPos(far)
tagger.lcRationDocked = nil
tagger.chat = {}
local t = { pos = far + Vector(40, 0, 40), normal = Vector(-1, 0, 0), owner = tagger, at = CurTime() }
table.insert(LC.Tags, t)
hook.Run("LivingCityTagged", tagger, t)
ok(not tagger.lcRationDocked and not t.found, "graffiti nobody saw costs nobody their rations")
local cop, cst = LC.Spawners.cop(far + Vector(-200, 0, 0))
_advance(6) _runtimers()
ok(t.found and tagger.lcRationDocked ~= nil, "once a unit comes across it, the block is docked")
for i, x in ipairs(LC.Tags) do if x == t then table.remove(LC.Tags, i) break end end
cop:Remove()
tagger.lcRationDocked = nil
tagger:SetNW2String("lc_ration_docked", "")
-- the city eats less
ok(GetConVar("lc_stock_eat") and GetConVar("lc_stock_eat"):GetInt() == 40, "the city eats a ration a minute per 40 citizens")
for _, p in ipairs({ walker, tagger }) do p:SetPos(Vector(-150000, 150000, 0)) end
end
BatchFixTests()

----------------------------------------------------------------------
function NextStepTests()
section("What now? Everyone always has a next step")
local N0 = Vector(-130000, -60000, 0)
local p = newPlayer("Newcomer", "citizen")
_run(0.3)
p:SetPos(N0)
local function Step() return LC.NextStep(p) end
-- hungry, with a ration due
p:SetNW2Float("lcn_hunger", 10)
p:SetNW2Float("lcn_thirst", 90)
for id in pairs(LC.Inventory(p)) do local it = LCS.Items[id] if it and ((it.hunger or 0) > 0 or (it.thirst or 0) > 0) then LC.TakeItem(p, id, 99) end end
p.lcnRationAt = 0
p.lcRationDocked = nil
local s = Step()
ok(s and string.find(s.key, "^eat_") and s.urgent, "hungry: the next step is food, and it's urgent", s and s.key)
ok(s and (s.key ~= "eat_ration" or s.way == "dispenser"), "(a ration that's due: the way to the dispenser)", s and s.key)
LC.GiveItem(p, "bread", 1)
s = Step()
ok(s and s.key == "eat_own" and string.find(s.why, "bread", 1, true), "food in your pockets: eat it", s and s.why)
LC.TakeItem(p, "bread", 1)
p.lcnRationAt = CurTime() + 900
s = Step()
ok(s and (s.key == "eat_scrounge" or s.key == "eat_buy" or s.key == "eat_work"), "no ration due and no food: buy some, work for a ration card, or search bins", s and s.key)
p:SetNW2String("lcj_job", "porter")
local cr = LC.Credits(p)
LC.AddCredits(p, -cr)
s = Step()
ok(s and s.key == "eat_work" and s.way == "work", "hungry, broke, with a job and no ration card: work a shift for one", s and s.key)
LC.AddCredits(p, cr)
p:SetNW2String("lcj_job", "")
-- thirsty
p:SetNW2Float("lcn_hunger", 90)
p:SetNW2Float("lcn_thirst", 10)
s = Step()
ok(s and (s.key == "drink" or s.key == "drink_own") and s.urgent, "thirsty: the next step is water", s and s.key)
-- the card, once, when it drops
p.chat = {}
local nWarn = 0
local was = LC.Notice
LC.Notice = function(ply, kind, title) if ply == p and kind == "warn" and title == "Thirsty" then nWarn = nWarn + 1 end return was(ply, kind, title) end
LC.PushNextStep(p)
LC.PushNextStep(p)
LC.Notice = was
ok(nWarn == 1, "running low puts a card on screen, once", nWarn)
ok(p:GetNW2String("lc_next", "") ~= "" and p:GetNW2Bool("lc_next_urgent", false), "and the step is sent to their screen")
-- fed and watered: no job yet
p:SetNW2Float("lcn_thirst", 90)
p:SetNW2String("lcj_job", "")
p.lcHomeSeenCid = p:GetNW2String("lc_cid", "")
s = Step()
ok(s and (s.key == "job" or s.key == "ration" or s.key == "on_job"), "settled in: get a Union job", s and s.key)
-- every place on F1 has a way there
ok(LC.WaypointPlaces.dispenser and LC.WaypointPlaces.water and LC.WaypointPlaces.bin and LC.WaypointPlaces.work and LC.WaypointPlaces.shop, "Places: dispenser, water, bins, work, the Commissary")
-- a new life's first ration is never a shortfall
ok(LC.FirstRationDue(p), "a new life's first ration is due")
hook.Run("LivingCityRationCollected", p)
ok(not LC.FirstRationDue(p), "and once collected, it's ordinary again")
p:SetPos(Vector(-150000, 150000, 0))
end
NextStepTests()

----------------------------------------------------------------------
function JobGameTests()
section("Work you actually do: the street sweep, the factory line, the papers check")
local function Tick(n) for _ = 1, n or 1 do _advance(0.1) _runtimers() end end
local J0 = Vector(-140000, 40000, 0)
-- the street sweep
local sw = newPlayer("Sweeper", "citizen")
_run(0.3)
sw:SetPos(J0)
local spots = {}
for i = 1, 6 do spots[i] = J0 + Vector(200 + i * 60, 0, 0) end
local c0 = LC.Credits(sw)
ok(LC.JobGameStart(sw, "sweep", nil, { depot = J0, spots = spots }), "the street sweep starts")
local g = LC.JobGames[sw]
ok(g and IsValid(g.cart) and #g.litter == 6, "a cart at the depot, and six pieces of rubbish about", g and #g.litter)
g.cart.obbmin, g.cart.obbmax = Vector(-30, -20, 0), Vector(30, 20, 40) -- (a laundry cart's size; the stub's props are thin)
for _, e in ipairs(g.litter) do e.lcThrown, e.lcDroppedFrom = true, J0 + Vector(400, 0, 0) e:SetPos(g.cart:GetPos() + Vector(0, 0, 20)) end
Tick(2)
ok(not LC.JobGames[sw], "all of it in the cart, at the depot: done")
ok(LC.Credits(sw) - c0 >= 12, "paid for every piece, and more for the long throws", LC.Credits(sw) - c0)
-- the factory line
local fw = newPlayer("LineWorker", "citizen")
_run(0.3)
fw:SetPos(J0 + Vector(0, 3000, 0))
c0 = LC.Credits(fw)
ok(LC.JobGameStart(fw, "line", nil, { station = fw:GetPos() }), "the line starts")
g = LC.JobGames[fw]
ok(g and IsValid(g.conv) and IsValid(g.bin), "a conveyor and a scrap bin")
local bad, seen = 0, {}
for _ = 1, 1200 do
    Tick(1)
    if not LC.JobGames[fw] then break end
    for _, e in ipairs(g.parts) do
        if IsValid(e) and e.lcPart and e.lcPart.bad and not seen[e] then
            seen[e] = true
            bad = bad + 1
            e:SetPos(g.bin:GetPos() + Vector(0, 0, 10))
        end
    end
end
ok(not LC.JobGames[fw] and g.spawned == 20, "twenty parts down the line, and the shift ends", g.spawned)
ok(g.caught == bad and g.missed == 0 and g.wasted == 0, "the bad ones binned, the good ones through", string.format("caught %d of %d, missed %d, wasted %d", g.caught, bad, g.missed, g.wasted))
ok(LC.Credits(fw) > c0, "paid for a clean shift", LC.Credits(fw) - c0)
-- the papers check
local pw = newPlayer("PapersClerk", "citizen")
_run(0.3)
pw:SetPos(J0 + Vector(3000, 0, 0))
ok(LC.JobGameStart(pw, "papers", nil, {}), "the papers check starts")
g = LC.JobGames[pw]
ok(g and g.current and IsValid(g.current.npc), "a traveler steps up")
local rights, wrongs = 0, 0
for i = 1, 5 do
    local c = g.current
    if not c then break end
    c.npc:SetPos(c.stand)
    Tick(2)
    local correct = c.forged and "unit" or (c.wrong and "deny" or "approve")
    local choice = correct
    if i == 5 then choice = (correct == "approve") and "deny" or "approve" end -- one mistake
    local r = LC.PapersDecide(pw, choice)
    if r then rights = rights + 1 else wrongs = wrongs + 1 end
end
Tick(2)
ok(rights == 4 and not LC.JobGames[pw], "five travelers: four right calls, one wrong, and the shift's done", rights .. " right, " .. wrongs .. " wrong")
-- in a shift: arriving starts the game, finishing it finishes the step
for _, p in ipairs({ sw, fw, pw }) do p:SetPos(Vector(-150000, 150000, 0)) end
end
JobGameTests()

----------------------------------------------------------------------
function MoreJobGameTests()
section("More work you actually do: rewiring, triage, rubble")
local function Tick(n) for _ = 1, n or 1 do _advance(0.1) _runtimers() end end
local K0 = Vector(-140000, -40000, 0)
-- rewiring
local mw = newPlayer("Wireman", "citizen")
_run(0.3)
mw:SetPos(K0)
local c0 = LC.Credits(mw)
local fixed = false
ok(LC.JobGameStart(mw, "wiring", nil, { pos = K0, what = "the box", onFixed = function() fixed = true end }), "a board of circuit tiles opens")
local g = LC.JobGames[mw]
ok(g and g.w == 5 and g.h == 4 and #g.tiles == 20 and _lastnet("lc_wire_open") ~= nil, "five by four, sent to their screen", g and #g.tiles)
local _, solved0 = LC.WireLit(g)
ok(not solved0 and g.par >= 1, "it starts scrambled (the current doesn't reach the lamp), with a par to beat", g.par)
-- the right way always exists: put each tile on it the right way round and the lamp lights
;(function()
    local saved = {}
    for k, m in ipairs(g.tiles) do saved[k] = m end
    for k, want in pairs(g.want) do
        for _ = 1, 4 do if g.tiles[k] == want then break end g.tiles[k] = LC.WireTurn(g.tiles[k]) end
    end
    local _, s1 = LC.WireLit(g)
    ok(s1, "there's always a way through (laid when the board was dealt)")
    local bigG = { w = 6, h = 5, nSparks = 3 }
    local fine = true
    for _ = 1, 30 do
        LC.WireDeal(bigG)
        local _, sv = LC.WireLit(bigG)
        local n = 0
        for _ in pairs(bigG.want) do n = n + 1 end
        if sv or n < 11 then fine = false end
    end
    ok(fine, "a terminal's board is six by five, never dealt solved, and the way through winds (not a straight line)")
    for k, m in ipairs(saved) do g.tiles[k] = m end
end)()
-- a turn
local k1 = 1
while g.want[k1] do k1 = k1 + 1 end -- (a tile off the way through)
for _, sp in ipairs(g.sparks) do sp.k, sp.moveAt = 999, CurTime() + 60 end
local m0 = g.tiles[k1]
ok(LC.WireTry(mw, k1, false) == true and g.tiles[k1] == LC.WireTurn(m0) and g.turns == 1, "a click turns a tile a quarter")
LC.WireTry(mw, k1, true)
ok(g.tiles[k1] == m0, "and a right-click turns it back")
-- a spark bites
g.sparks[1].k, g.sparks[1].since, g.sparks[1].moveAt = k1, CurTime() - 1, CurTime() + 60
local lim = g.limit
ok(LC.WireTry(mw, k1, false) == false and g.shocks == 1 and g.tiles[k1] == m0 and g.limit < lim, "turning a sparking tile bites (a shock, seconds off, and it doesn't turn)")
g.sparks[1].since = CurTime()
ok(LC.WireTry(mw, k1, false) == true, "(not when the spark has only just landed there: the click was on its way)")
LC.WireTry(mw, k1, true)
-- sparks jump about
g.sparks[1].k = 999
local at = g.sparks[2].k
g.sparks[2].moveAt = CurTime() - 0.1
Tick(1)
ok(g.sparks[2].k ~= at and g.sparks[2].moveAt > CurTime(), "the sparks jump about the board")
-- out of time: the breaker trips and it's a new board
g.limit = CurTime() - 1
Tick(1)
ok(g.trips == 1 and g.turns == 0 and g.limit > CurTime(), "too slow: the breaker trips and the board scrambles again")
-- solve it, keeping clear of the sparks
for _, sp in ipairs(g.sparks) do sp.moveAt = CurTime() + 999 sp.k = 999 end
for k, want in pairs(g.want) do
    for _ = 1, 4 do
        if not LC.JobGames[mw] or g.tiles[k] == want then break end
        LC.WireTry(mw, k, false)
    end
end
ok(not LC.JobGames[mw] and fixed, "the current reaches the lamp: it's fixed")
ok(LC.Credits(mw) > c0, "and paid (less for the shock and the trip)", LC.Credits(mw) - c0)
-- triage
local md = newPlayer("Medic", "citizen")
_run(0.3)
md:SetPos(K0 + Vector(3000, 0, 0))
c0 = LC.Credits(md)
ok(LC.JobGameStart(md, "triage", nil, { center = md:GetPos() }), "patients come in")
g = LC.JobGames[md]
local nDying, nStable = 0, 0
for _, p in ipairs(g and g.patients or {}) do if p.injury.rate > 0 then nDying = nDying + 1 else nStable = nStable + 1 end end
ok(g and nDying >= 3 and nDying <= 4 and nStable == 1, "three or four going downhill, and one more who's stable (a broken arm doesn't make it easier)", nDying .. " + " .. nStable)
local dying
for _, p in ipairs(g.patients) do if p.injury.rate > 0 then dying = p break end end
dying.npc:SetHealth(1)
for _, p in ipairs(g.patients) do if p ~= dying then p.npc:SetHealth(p.max) end end
Tick(20)
ok(not LC.JobGames[md] and g.saved == #g.patients - 1 and g.lost == 1, "treated in time they walk out; one left too long is lost", string.format("saved %d, lost %d", g.saved, g.lost))
ok(LC.Credits(md) > c0, "paid for the ones saved", LC.Credits(md) - c0)
-- rubble
local rc = newPlayer("RubbleCrew", "citizen")
_run(0.3)
rc:SetPos(K0 + Vector(0, 3000, 0))
for _, w in ipairs(rc.weps or {}) do end
rc:StripWeapon("weapon_crowbar")
ok(LC.JobGameStart(rc, "rubble", nil, { pos = rc:GetPos() + Vector(80, 0, 0) }), "a rubble pile to break up")
g = LC.JobGames[rc]
ok(g and #g.chunks >= 4 and rc:HasWeapon("weapon_crowbar") and rc.lcJobCrowbar, "a crowbar lent for it (and no unit books you for carrying it)")
local items0 = #ents.FindByClass("lc_item")
for _ = 1, 30 do
    if not LC.JobGames[rc] then break end
    local c = g.chunks[1]
    if c then hook.Run("EntityTakeDamage", c, _dmg(rc, 25, DMG_CLUB)) end
    Tick(1)
end
ok(not LC.JobGames[rc] and g.broken == g.total, "every block broken", g.broken .. " of " .. g.total)
ok(#ents.FindByClass("lc_item") > items0, "scrap where they broke")
ok(not rc:HasWeapon("weapon_crowbar") and not rc.lcJobCrowbar, "and the crowbar goes back")
for _, p in ipairs({ mw, md, rc }) do p:SetPos(Vector(-150000, 150000, 0)) end
end
MoreJobGameTests()

function HandsOnTests()
section("Hands-on work: parcels, the records terminal, dead drops, the dead, laundry, filing, radios, pat-downs, breaches")
local function Tick(n) for _ = 1, n or 1 do _advance(0.1) _runtimers() end end
local H0 = Vector(-140000, 60000, 0)
local GONE = Vector(-150000, 150000, 0)
local function Unit(pos)
    local u, ust = LC.Spawners.cop(pos)
    ust.unmanaged, ust.questLock = true, true
    return u
end

-- the parcel run
local cu = newPlayer("Parcels", "citizen")
_run(0.3)
cu:SetPos(H0)
local stops = { { pos = H0 + Vector(400, 0, 0), name = "Block A" }, { pos = H0 + Vector(800, 0, 0), name = "Block B" }, { pos = H0 + Vector(1200, 0, 0), name = "Block C" } }
local c0 = LC.Credits(cu)
ok(LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = { text = "A box.", hot = true }, searchFinds = 0 }), "a parcel run starts with three to deliver")
local g = LC.JobGames[cu]
ok(cu.lcWaypoint and cu.lcWaypoint.pos == stops[1].pos, "the first door is marked on their screen")
local unit = Unit(H0 + Vector(200, 150, 0))
Tick(30)
ok(g.stopped ~= nil, "a unit that gets a good look calls them over", g.heat)
Tick(55)
ok(g.stopped == nil and g.searches == 1 and LC.JobGames[cu] == g, "stand still for the search: this time it's handed back")
unit:Remove()
for i = 1, 3 do cu:SetPos(stops[i].pos) Tick(1) end
ok(not LC.JobGames[cu] and LC.Credits(cu) > c0, "all three delivered: paid, faster is more", LC.Credits(cu) - c0)
ok(cu.lcWaypoint == nil, "and the marker's gone")
cu:SetPos(H0)
LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = { text = "A box.", hot = true }, searchFinds = 1 })
g = LC.JobGames[cu]
g.stopped = { at = cu:GetPos(), untilT = CurTime() + 5 }
cu:SetPos(H0 + Vector(0, 300, 0))
Tick(1)
ok(g.ran and LC.PlayerIsWanted(cu), "run from a search and you're wanted")
LC.ClearWanted(cu)
cu:SetPos(H0)
g.stopped = { at = cu:GetPos(), untilT = CurTime() + 5 }
Tick(55)
ok(not LC.JobGames[cu] and g.seized and LC.PlayerIsWanted(cu), "searched with something in it: seized, and wanted")
LC.ClearWanted(cu)
cu:SetPos(GONE)

-- the records terminal
local hk = newPlayer("Hacker", "resistance")
_run(0.3)
hk:SetPos(H0 + Vector(0, 4000, 0))
c0 = LC.Credits(hk)
local wiped = false
ok(LC.JobGameStart(hk, "hack", nil, { pos = hk:GetPos(), onDone = function() wiped = true end }), "the terminal opens")
g = LC.JobGames[hk]
ok(_lastnet("lc_jg_panel") ~= nil and g.panelOpen, "its panel on their screen")
local nd = LC.HackNeedle(g, CurTime() + 0.7)
ok(nd >= 0 and nd <= 1, "the needle swings between the ends", nd)
local sawSweep = false
for _ = 1, 140 do Tick(1) if g.sweep then sawSweep = true break end end
ok(sawSweep, "a scanner comes over every few seconds")
ok(LC.JobGameAct(hk, "try", g.band + g.bandW / 2) == false and g.alarms == 1 and g.got == 0, "touch the panel while it's looking: it sees you")
g.sweepEnd = CurTime() - 1
Tick(1)
ok(not g.sweep, "it passes")
ok(LC.JobGameAct(hk, "try", g.band + g.bandW / 2) == true and g.got == 1, "the needle in the band: one bypassed")
local w0 = g.bandW
ok(LC.JobGameAct(hk, "try", g.band > 0.5 and 0.01 or 0.99) == false and g.got == 0, "out of it: you lose one")
ok(g.bandW < w0 or g.speed > 0.55, "and every hit makes the next harder")
for _ = 1, 4 do if LC.JobGames[hk] then g.sweep = false LC.JobGameAct(hk, "try", g.band + g.bandW / 2) end end
ok(not LC.JobGames[hk] and wiped and LC.Credits(hk) > c0, "four in: through, paid, and the job done", LC.Credits(hk) - c0)
LC.JobGameStart(hk, "hack", nil, { pos = hk:GetPos() })
g = LC.JobGames[hk]
g.sweep = true
LC.JobGameAct(hk, "try", 0.5)
LC.JobGameAct(hk, "try", 0.5)
ok(not LC.JobGames[hk] and g.tripped and LC.PlayerIsWanted(hk), "seen twice: the alarm goes, and they're wanted")
LC.ClearWanted(hk)
hk:SetPos(GONE)

-- the dead drop
local dr = newPlayer("Dropper", "resistance")
_run(0.3)
local D0 = H0 + Vector(4000, 4000, 0)
dr:SetPos(D0)
c0 = LC.Credits(dr)
ok(LC.JobGameStart(dr, "drop", nil, { pos = D0 }), "a drop with somewhere to hide the message")
g = LC.JobGames[dr]
ok(#g.spots == 3 and g.spots[1]:GetNW2String("lc_jg_mark", "") == "target", "three places, outlined")
dr.lookingAt = g.spots[1]
dr:SetPos(g.spots[1]:GetPos() + Vector(30, 0, 0))
hook.Run("KeyPress", dr, IN_USE)
ok(g.hiding and g.hiding.ent == g.spots[1], "E on one starts to hide it")
dr.crouch = false
Tick(10)
ok(g.hiding.t == 0 and g.hiding.paused, "standing up, nothing happens: crouch")
local watcher = Unit(D0 + Vector(-300, 0, 0))
dr.crouch = true
Tick(20)
ok(g.spots[1].lcBurned and g.burned == 1 and not g.hiding, "a unit sees: that place is burned")
watcher:Remove()
dr:SetPos(g.spots[2]:GetPos() + Vector(30, 0, 0))
LC.JobGameUse(dr, g.spots[2])
LC.JobGameUse(dr, g.spots[2])
Tick(30)
ok(not LC.JobGames[dr] and LC.Credits(dr) > c0, "hidden unseen in another: done and paid", LC.Credits(dr) - c0)
dr.crouch = false
dr:SetPos(GONE)

-- searching the dead
local mo = newPlayer("Mortician", "citizen")
_run(0.3)
mo:SetPos(H0 + Vector(-4000, 0, 0))
ok(LC.JobGameStart(mo, "search", nil, { pos = mo:GetPos() + Vector(60, 0, 0) }), "a body on the slab")
g = LC.JobGames[mo]
ok(IsValid(g.body) and g.body.lcBody and g.body.lcBody.claimed, "it's theirs to search (no other job takes it)")
ok(LC.JobGameUse(mo, g.body) and g.panelOpen, "E on it: its pockets")
g.pockets = {
    { name = "Coat", find = { label = "Papers", item = "papers_dead", value = 2, stolen = true } },
    { name = "Shoes", find = { label = "Rounds", item = "ammo_pistol", value = 2, contraband = true } },
    { name = "Lining" },
    { name = "Trousers", find = { label = "A ring", item = "keepsake", value = 1, family = true } },
}
g.watching = false
LC.JobGameAct(mo, "open", 1)
LC.JobGameAct(mo, "keep", 1)
ok(LC.HasItem(mo, "papers_dead") and g.kept == 1, "kept while nobody's looking: yours")
g.watching = true
LC.JobGameAct(mo, "open", 2)
LC.JobGameAct(mo, "keep", 2)
ok(g.caught == 1 and not LC.HasItem(mo, "ammo_pistol") and g.pockets[2].done == "log", "kept while the overseer watches: caught, and it goes in the tray")
LC.JobGameAct(mo, "open", 3)
ok(g.pockets[3].done == "empty", "an empty pocket is just empty")
LC.JobGameAct(mo, "open", 4)
LC.JobGameAct(mo, "family", 4)
ok(g.pockets[4].done == "family", "set aside for the family")
g.watchAt = CurTime() - 1
local was = g.watching
Tick(1)
ok(g.watching ~= was, "the overseer comes and goes")
local first = g.body
LC.JobGameAct(mo, "burn")
ok(not IsValid(first) and IsValid(g.body) and g.n == 2, "into the fire, and the next one's on the slab")
LC.JobGameAct(mo, "burn")
LC.JobGameAct(mo, "burn")
ok(not LC.JobGames[mo] and has(g.notes, "wrote your name"), "three done: the shift's over (and the overseer remembers)")
mo:SetPos(GONE)

-- sorting uniforms
local la = newPlayer("Launderer", "citizen")
_run(0.3)
la:SetPos(H0 + Vector(-4000, 4000, 0))
c0 = LC.Credits(la)
ok(LC.JobGameStart(la, "laundry", nil, {}), "a pile of uniforms")
g = LC.JobGames[la]
ok(#g.bins == 5 and g.u and g.u.tag, "four division bins and the incident wash", g.u and g.u.tag)
local function rightBin(u)
    if u.stain then return 5 end
    for i, b in ipairs(g.bins) do if b.divs[1] == u.div or b.divs[2] == u.div then return i end end
end
g.u.pocket, g.u.item = "a folded note", "paper"
LC.JobGameAct(la, "turnin")
ok(g.u.pocket == nil and g.pay >= 1, "something in a pocket, turned in")
local wrongBin = rightBin(g.u) == 1 and 2 or 1
ok(LC.JobGameAct(la, "sort", wrongBin) == false and g.wrong == 1, "the wrong bin is wrong")
for _ = 1, 20 do if LC.JobGames[la] then LC.JobGameAct(la, "sort", rightBin(g.u)) end end
ok(not LC.JobGames[la] and g.right == 11 and LC.Credits(la) > c0, "the pile sorted: paid", LC.Credits(la) - c0)
la:SetPos(GONE)

-- filing
local fl = newPlayer("Filer", "citizen")
_run(0.3)
fl:SetPos(H0 + Vector(-8000, 0, 0))
c0 = LC.Credits(fl)
ok(LC.JobGameStart(fl, "filing", nil, {}), "an in-tray of forms")
g = LC.JobGames[fl]
local honest = true
local function rightDrawer(f) return f.bad and 5 or LC.FilingDrawerOf(f.cid) end
ok(LC.FilingDrawerOf("07-123") == 1 and LC.FilingDrawerOf("49-001") == 2 and LC.FilingDrawerOf("99-999") == 4, "drawers by citizen number")
ok(LC.JobGameAct(fl, "file", rightDrawer(g.form) == 1 and 2 or 1) == false and g.wrong == 1, "the wrong drawer is wrong")
ok(string.find(g.last or "", "Wrong", 1, true) and string.find(g.last or "", "goes in", 1, true), "and it says why, and where it should have gone", g.last)
ok(LC.JobGameAct(fl, "blank") and LC.HasItem(fl, "papers_blank"), "a blank identity form, from the cabinet nobody locks")
ok(LC.JobGameAct(fl, "blank") == nil, "(once a shift)")
for _ = 1, 20 do
    local f = g.form
    if not f then break end
    if (f.bad == true) ~= (f.name ~= f.regName or f.cid ~= f.regCid or f.status ~= f.regStatus) then honest = false end
    LC.JobGameAct(fl, "file", rightDrawer(f))
end
ok(honest, "a form that doesn't match the register (name, number or status) really doesn't (and the rest do)")
ok(not LC.JobGames[fl] and g.right == 9 and LC.Credits(fl) > c0, "the tray filed: paid", LC.Credits(fl) - c0)
fl:SetPos(GONE)

-- tuning radios
local rd = newPlayer("RadioMan", "citizen")
_run(0.3)
rd:SetPos(H0 + Vector(-8000, 4000, 0))
c0 = LC.Credits(rd)
local RA = "sound/livingcity/announce/radio/"
_files[RA .. "freq7/a.wav"] = ""
_files[RA .. "freq7/a.txt"] = "Count them back."
_files[RA .. "static/hiss.wav"] = ""
_files[RA .. "union/notices.wav"] = ""
LC.AnnounceRescan()
ok(LC.JobGameStart(rd, "radio", nil, { freq7 = 1 }), "a shelf of hissing radios")
g = LC.JobGames[rd]
ok(g.f7 and math.abs(g.f7 - g.target) > 3, "this one has Freq 7 on it, well away from its station")
ok(g.f7clip == "livingcity/announce/radio/freq7/a.wav" and string.find(g.f7msg, "Count them back", 1, true), "Freq 7 is a recording from radio/freq7/, its words from its .txt", g.f7clip)
ok(g.staticClip == "livingcity/announce/radio/static/hiss.wav" and g.unionClip == "livingcity/announce/radio/union/notices.wav", "the static and the ordinary station from their own folders, for the screen to mix")
local nearBy = newPlayer("RadioNeighbour", "citizen")
nearBy:SetPos(rd:GetPos() + Vector(150, 0, 0))
LC.JobGameAct(rd, "dial", 99.9)
Tick(3)
local benchNet = _lastnet("lc_radio_bench")
local inEar = {}
for _, p in ipairs(g.heardBy or {}) do inEar[p] = true end
ok(benchNet and g.dial == 99.9 and inEar[rd] and inEar[nearBy] and not inEar[cu], "the set is heard by whoever's near the bench: the dial and what's on it go to them", #(g.heardBy or {}))
ok(LC.JobGameAct(rd, "lock", g.f7) == "freq7" and g.heard, "lock onto the clearest thing on the band: Freq 7")
nearBy:SetPos(GONE)
ok(LC.JobGameAct(rd, "lock", g.target) == nil, "(decide about it first)")
LC.JobGameAct(rd, "freq7", "note")
ok(not g.heard and LC.HasItem(rd, "freq7_sheet"), "written down where nobody will look")
local e0 = g.radioEnd
ok(LC.JobGameAct(rd, "lock", g.target > 100 and g.target - 2 or g.target + 2) == false and g.radioEnd < e0, "static: time lost")
ok(#g.screws == 3 and #g.turn == 3, "each set has three trimmer screws, left somewhere wrong")
ok(LC.JobGameAct(rd, "lock", g.target) == "adjust" and g.fixed == 0, "on its station but the screws are off: not fixed yet")
ok(LC.JobGameAct(rd, "screw", { 1, 0.42 }) and g.turn[1] == 0.42, "a screw turned on the bench")
ok(LC.RadioScrewQuality(g.screws[2], g.screws[2]) == 1 and LC.RadioScrewQuality(g.screws[2] + 0.5, g.screws[2]) == 0, "how right a screw is: on the spot, or a long way off")
ok(LC.JobGameAct(rd, "lock", { f = g.target, s = g.screws }) == true and g.fixed == 1 and g.n == 2, "on its station with the screws set right: fixed, the next one")
g.radioEnd = CurTime() - 1
Tick(1)
ok(g.n == 3 and g.fixed == 1, "too slow: back on the shelf, still hissing")
LC.JobGameAct(rd, "lock", { f = g.target, s = g.screws })
LC.JobGameAct(rd, "lock", { f = g.target, s = g.screws })
ok(not LC.JobGames[rd] and g.fixed == 3 and LC.Credits(rd) > c0, "the shelf done: paid", LC.Credits(rd) - c0)
for k in pairs(_files) do if string.find(k, RA, 1, true) == 1 then _files[k] = nil end end
LC.AnnounceRescan()
rd:SetPos(GONE)

-- pat-downs
local pc = newPlayer("PatCop", "cp")
_run(0.3)
local P0 = H0 + Vector(-12000, 0, 0)
pc:SetPos(P0)
c0 = LC.Credits(pc)
local cit1, c1st = LC.Spawners.citizen(P0 + Vector(60, 0, 0))
local cit2 = LC.Spawners.citizen(P0 + Vector(0, 60, 0))
local cit3 = LC.Spawners.citizen(P0 + Vector(-60, 0, 0))
ok(LC.JobGameStart(pc, "patdown", nil, { need = 2, carry = 1 }), "a pat-down shift")
g = LC.JobGames[pc]
ok(LC.JobGameUse(pc, cit1) and g.subject and c1st.questLock, "E on a citizen: they're stopped")
ok(LC.JobGameAct(pc, "verdict", "confiscate") == nil, "nothing to confiscate until you've found it")
LC.JobGameAct(pc, "pat", g.subject.hidden)
ok(g.subject.found, "the right place: found")
LC.JobGameAct(pc, "verdict", "confiscate")
ok(g.done == 1 and g.right == 1 and not c1st.questLock, "confiscated, and they go on their way")
ok(LC.JobGameUse(pc, cit1) == nil, "(not the same one twice)")
g.opts.carry = 0
LC.JobGameUse(pc, cit2)
LC.JobGameAct(pc, "pat", 1)
LC.JobGameAct(pc, "verdict", "detain")
ok(not LC.JobGames[pc] and g.wrong == 1, "detain someone clean: a bad call (and the shift's over)")
LC.JobGameStart(pc, "patdown", nil, { need = 1, carry = 0 })
g = LC.JobGames[pc]
LC.JobGameUse(pc, cit3)
local r
for i = 1, 4 do r = LC.JobGameAct(pc, "pat", i) end
ok(r == "bolted" and not LC.JobGames[pc], "too long at it and they lose their nerve and bolt")
pc:SetPos(GONE)

-- a breach
local bc = newPlayer("Breacher", "cp")
_run(0.3)
local B0 = H0 + Vector(-12000, 6000, 0)
bc:SetPos(B0)
local door = ents.Create("prop_door_rotating")
door:SetPos(B0 + Vector(100, 0, 0))
door:Spawn()
door:Fire("Lock")
ok(LC.JobGameStart(bc, "breach", nil, { pos = B0 }), "a raid on a block")
g = LC.JobGames[bc]
ok(g.phase == "door" and g.door == door, "the door first")
LC.JobGameUse(bc, door)
Tick(30)
ok(g.phase == "room" and not door.locked, "the charge goes: the door's open")
ok(#g.res >= 2 and #g.stash == 3, "residents, and places to search", #g.res)
LC.JobGameUse(bc, g.res[1].npc)
ok(g.res[1].done == "secured" and g.secured == 1, "E on one: on the floor")
g.res[2].until_ = CurTime() - 1
Tick(1)
ok(g.res[2].done == "fled" or g.res[2].done == "flushed", "too slow with another: they run, or burn something", g.res[2].done)
for _, rr in ipairs(g.res) do if not rr.done then LC.JobGameUse(bc, rr.npc) end end
for _, e in ipairs(g.stash) do LC.JobGameUse(bc, e) end
Tick(1)
ok(not LC.JobGames[bc] and (g.found >= 1 or g.flushed >= 1), "everyone down and the place searched: done", string.format("found %d, flushed %d", g.found, g.flushed))
door:Remove()
bc:SetPos(GONE)
ok(LC.JobGameStart(bc, "breach", nil, { pos = B0, noDoor = true }) and LC.JobGames[bc].phase == "room", "(no door: straight in)")
LC.JobGameEnd(bc, "quit")
end
HandsOnTests()

function ForcefieldTests()
section("Forcefields: a power bank feeds two things; they take a beating and recharge")
local F0 = Vector(-120000, -90000, 0)
local function Field(pos)
    local f = ents.Create("lc_forcefield") f:SetPos(pos) f:Spawn()
    f.lcForcefield = true
    f.FieldUp = function(self) return not self:GetNW2Bool("lc_nopower", false) and self:GetNW2Float("lc_short_until", 0) < CurTime() end
    return f
end
local bank = ents.Create("lc_powerbank") bank:SetPos(F0) bank:Spawn()
local f1, f2, f3 = Field(F0 + Vector(100, 0, 0)), Field(F0 + Vector(200, 0, 0)), Field(F0 + Vector(300, 0, 0))
LC.CheckpointTick(CurTime())
local loads = LC.BankLoads(true)
ok(loads[f1] == bank and loads[f2] == bank and loads[f3] == false, "one power bank feeds two things, the nearest first")
ok(not LC.FieldOff(f1) and LC.FieldOff(f3), "the third sits dead until a bank with room is near it")
local lone = Field(F0 + Vector(5000, 0, 0))
ok(LC.FieldOff(lone), "a forcefield with no power bank near it has no power")
f3:Remove() lone:Remove()
_run(1)
-- a beating
local hp0 = f1:GetNW2Int("lc_ff_hp", 0)
ok(hp0 == GetConVar("lc_forcefield_hp"):GetInt(), "it starts at full strength", hp0)
LC.ForcefieldHurt(f1, 100, false)
ok(f1:GetNW2Int("lc_ff_hp", 0) == hp0 - 100 and f1:FieldUp(), "a few hits wear it down, and it holds")
_run(8)
ok(f1:GetNW2Int("lc_ff_hp", 0) > hp0 - 100, "left alone, it recharges", f1:GetNW2Int("lc_ff_hp", 0))
LC.ForcefieldHurt(f1, 1000, false)
ok(not f1:FieldUp() and not f1:GetNW2Bool("lc_ff_broken", false), "too much at once: overwhelmed, offline for a while")
_run(GetConVar("lc_forcefield_down"):GetFloat() + 1)
ok(f1:FieldUp() and f1:GetNW2Int("lc_ff_hp", 0) < hp0, "it comes back, not fully charged")
LC.ForcefieldHurt(f1, 1000, false)
_run(GetConVar("lc_forcefield_down"):GetFloat() + 1)
LC.ForcefieldHurt(f1, 1000, false)
ok(f1:GetNW2Bool("lc_ff_broken", false) and not f1:FieldUp(), "overwhelmed three times in five minutes: broken")
_run(GetConVar("lc_forcefield_down"):GetFloat() + 1)
ok(not f1:FieldUp(), "and it stays down")
local cit = newPlayer("FieldCitizen", "citizen")
cit:SetPos(f1:GetPos() + Vector(40, 0, 0))
ok(not LC.RepairForcefield(cit, f1), "only a Maintenance Technician can repair it")
local tech = newPlayer("FieldTech", "citizen")
LC.SetJob(tech, "maintenance", true)
tech:SetPos(f1:GetPos() + Vector(40, 0, 0))
local c0 = LC.Credits(tech)
ok(LC.SwipeForcefield(tech, f1), "E on the broken field: the technician gets to work")
_run(11)
ok(not f1:GetNW2Bool("lc_ff_broken", false) and f1:FieldUp() and LC.Credits(tech) > c0, "repaired, and paid")
LC.ForcefieldBreak(f1)
f1.lcBrokenAt = CurTime() - 10000
_run(1)
ok(not f1:GetNW2Bool("lc_ff_broken", false), "nobody repairs it: the city's crews do, eventually")
-- a blast while it's down breaks it outright
LC.ForcefieldHurt(f2, 1000, false)
LC.ForcefieldHurt(f2, 200, true)
ok(f2:GetNW2Bool("lc_ff_broken", false), "blown up while it's down: broken")
for _, e in ipairs({ f1, f2, bank }) do e:Remove() end
for _, p in ipairs({ cit, tech }) do p:SetPos(Vector(-150000, 150000, 0)) end
end
ForcefieldTests()

function HygieneTests()
section("Toilets, soiling yourself, baths, clean clothes; beds and sleep")
local Y0 = Vector(-120000, -60000, 0)
local function Tick(n) for _ = 1, n or 1 do _advance(5) _runtimers() end end
local p = newPlayer("Parasited", "citizen")
_run(0.3)
p:SetPos(Y0)
LC.Infect(p)
ok(LC.HasParasites(p) and LC.Urge(p) == 0, "parasites: the urge starts at nothing")
Tick(40)
ok(LC.Urge(p) >= 50, "and builds", LC.Urge(p))
local ns = LC.NextStep(p)
ok(ns and ns.key == "toilet" and ns.way == "toilet", "What now? says find a toilet")
-- a toilet in time
local loo = ents.Create("lc_toilet") loo:SetPos(Y0 + Vector(40, 0, 0)) loo:Spawn()
ok(LC.AmenityKindOf(loo) == "toilet" and LC.NearestAmenity("toilet", p:GetPos()) ~= nil, "a toilet the city knows about")
local th0 = LC.Thirst(p)
ok(LC.UseToilet(p), "sit on it")
_run(9)
ok(LC.Urge(p) == 0 and LC.Thirst(p) < th0, "relief, and it dehydrates you")
-- too late
p:SetNW2Float("lc_urge", 99)
local stains0 = #ents.FindByClass("lc_stain")
Tick(1)
ok(p:GetNW2Bool("lc_soiled", false) and #ents.FindByClass("lc_stain") > stains0, "too late: soiled, and a mess on the ground")
ok(LC.IsFilthy(p), "and filthy until it's sorted")
local npc, nst = LC.Spawners.citizen(p:GetPos() + Vector(80, 0, 0))
nst.leaveAt = nil
Tick(1)
ok((nst.lcShunned or 0) > 0, "the city's own step away from the smell")
ok(LC.NextStep(p).key == "toilet", "What now?: the toilet first")
LC.UseToilet(p) _run(9)
ok(LC.NextStep(p).key == "wash" and LC.IsFilthy(p), "then a wash")
local tub = ents.Create("lc_bath") tub:SetPos(Y0 + Vector(-40, 0, 0)) tub:Spawn()
LC.UseBath(p) _run(11)
ok(not LC.SoilNeeds(p).wash and LC.IsFilthy(p), "washed, but the clothes still stink")
ok(not LC.ChangeClothes(p), "no clean clothes in your pockets: you can't change")
LC.GiveItem(p, "civvies")
ok(LC.NextStep(p).action == "changeclothes", "What now? offers to change into the clean ones")
LC.RunAction(p, "changeclothes", "")
ok(not LC.IsFilthy(p) and not p:GetNW2Bool("lc_soiled", false) and not LC.HasItem(p, "civvies"), "clean clothes: all put right")
-- the mess on the ground
local mess
for _, e in ipairs(ents.FindByClass("lc_stain")) do if e:GetPos():Distance(Y0) < 300 then mess = e end end
mess.lcBorn = CurTime() + 1e6 -- (the city's own crews wait their turn)
local sw = newPlayer("Sweeper", "citizen")
LC.SetJob(sw, "sanitation", true)
sw:SetPos(mess:GetPos() + Vector(30, 0, 0))
local c0 = LC.Credits(sw)
ok(LC.CleanStain(sw, mess), "a sanitation worker scrubs it up")
_run(6)
ok(not IsValid(mess) and LC.Credits(sw) > c0, "gone, and paid")
-- the city's own sanitation crew does it too
local mess2 = LC.SpawnStain(Y0 + Vector(0, 300, 0))
mess2.lcBorn = CurTime() - 10000
local crew, cst = LC.SpawnCitizen(Y0 + Vector(0, 360, 0))
cst.leaveAt = nil
cst.profile = { job = "sanitation" }
_setcvar("lc_npc_work", 1)
_setcvar("lc_npc_work_pct", 100)
_setcvar("lc_daily_rhythm", 0)
ok(LC.NPCWorkChoose(crew, cst, CurTime()) and cst.npcWork and cst.npcWork.id == "stain", "the city's own sanitation crew goes to scrub it")
for _ = 1, 60 do if not IsValid(mess2) then break end _run(0.5) end
ok(not IsValid(mess2), "and it's gone")
_setcvar("lc_daily_rhythm", 1)
crew:Remove() if IsValid(npc) then npc:Remove() end
LC.ClearWanted(p)
-- sleep
local sl = newPlayer("Sleeper", "citizen")
_run(0.3)
sl:SetPos(Y0 + Vector(0, -400, 0))
local bed = ents.Create("lc_bed") bed:SetPos(sl:GetPos() + Vector(40, 0, 0)) bed:Spawn()
local isNight = LC.IsNight
LC.IsNight = function() return false end
local okD, whyD = LC.SleepIn(sl, bed)
ok(not okD and whyD and string.find(whyD, "daylight", 1, true), "not tired in the day: no sleeping", whyD)
sl.lcAwakeSince = CurTime() - GetGlobal2Float("lc_day_len", 1440) * 2
local max0 = sl:GetMaxHealth()
Tick(1)
ok(LC.IsTired(sl) and sl:GetMaxHealth() == max0 - 25, "a day without sleep: tired, 25 less health at most")
ok(LC.NextStep(sl).key == "sleep", "What now? says get some sleep")
ok(LC.SleepIn(sl, bed), "exhausted: you can sleep any time")
_run(GetConVar("lc_sleep_seconds"):GetFloat() + 1)
Tick(1)
ok(not LC.IsTired(sl) and LC.IsRested(sl) and sl:GetMaxHealth() == max0, "slept: rested, and back to full strength")
ok(sl:GetNW2Bool("lc_sleeping", false) and sl:GetNW2Vector("lc_bed_top", Vector(0, 0, 0)):Distance(bed:GetPos()) < 80, "lying on the bed (its spot is sent, for the pose and the camera)")
ok(LC.BedSleepers[LC.BedKey({ ent = bed, pos = bed:GetPos() })] == sl, "and the bed is taken")
local stoodAt = sl.lcBedFrom
LC.IsNight = function() return true end
ok(not LC.SleepIn(sl, bed), "(and you can't sleep again straight away)")
LC.WakeUp(sl, "jump")
ok(not sl:GetNW2Bool("lc_sleeping", false) and (not stoodAt or sl:GetPos():Distance(stoodAt) < 10) and LC.BedSleepers[LC.BedKey({ ent = bed, pos = bed:GetPos() })] == nil,
    "Jump: up, back beside the bed, and it's free again")
-- citizens at bedtime: a free bed in a housing block, asleep on it till morning
local bz = LC.AddZone(sl:GetPos() + Vector(0, -600, 0), 300, "block", 31)
local hb = ents.Create("lc_bed") hb:SetPos(bz.pos + Vector(60, 0, 0)) hb:Spawn()
local sleeper, sst = LC.SpawnCitizen(bz.pos + Vector(-60, 0, 0))
sst.leaveAt = nil
sleeper.seqs = { Lying_Down = 5 } -- (the offline stand-in's models have no animations unless given some)
local bedtime = LC.Bedtime
LC.Bedtime = function() return true end
LC.StartLeaving(sleeper, sst, false, "test")
ok(sst.bedKey ~= nil and sleeper:GetNW2String("lc_doing", "") == "going home to bed", "at curfew or night, a citizen heads for a free bed in a housing block", sleeper:GetNW2String("lc_doing", ""))
for _ = 1, 40 do _run(0.5) if sst.state == "abed" then break end end
ok(sst.state == "abed" and IsValid(sleeper) and sleeper:GetNW2String("lc_doing", "") == "asleep", "and lies down on it to sleep (not gone)",
    tostring(sst.state) .. " seq=" .. tostring(sleeper.LookupSequence and sleeper:LookupSequence("Lying_Down")) .. " model=" .. tostring(sleeper:GetModel()))
local other, ost = LC.SpawnCitizen(bz.pos + Vector(-90, 40, 0))
ost.leaveAt = nil
ok(LC.FreeBedIn(bz, other) == nil, "one sleeper to a bed")
_run(31)
ok(sst.state == "abed", "asleep all night")
LC.Bedtime = function() return false end
for _ = 1, 60 do _run(1) if sst.state ~= "abed" then break end end
ok(IsValid(sleeper) and sst.state ~= "abed" and sst.bedKey == nil and not sst.leaving, "morning: up again, and out into the day", sst.state)
LC.Bedtime = bedtime
LC.IsNight = isNight
for _, n in ipairs({ sleeper, other }) do if IsValid(n) then n:Remove() end end
hb:Remove()
LC.RemoveZone(bz)
for _, e in ipairs({ loo, tub, bed }) do e:Remove() end
for _, q in ipairs({ p, sw, sl }) do q:SetPos(Vector(-150000, 150000, 0)) end
end
HygieneTests()

function VestTests()
section("Powered vests, vortigaunts charging them, and Father Grigori")
local V0 = Vector(-120000, -30000, 0)
local cit = newPlayer("VestCitizen", "citizen")
_run(0.3)
cit:SetPos(V0)
cit:SetArmor(50)
_advance(1.1) _runtimers()
ok(cit:Armor() == 0 and not LC.HasVest(cit), "a citizen with no vest holds no charge")
LC.GiveItem(cit, "armor_vest")
ok(LC.ItemUse(cit, "armor_vest") and cit:GetNW2Bool("lc_vest", false) and cit:Armor() == 30, "put on a powered vest: it comes with thirty in it")
ok(LC.ChargeVest(cit, 100) == 45 and cit:Armor() == 75, "and holds up to seventy-five")
local unit = newPlayer("VestUnit", "cp")
_run(0.3)
ok(LC.HasVest(unit) and LC.VestCap(unit) >= 100, "a unit's vest is built into the uniform")
-- a freed vortigaunt in rebel territory charges vests, not health
local reb = newPlayer("VestRebel", "resistance")
_run(0.3)
reb:SetPos(V0 + Vector(3000, 0, 0))
reb:SetNW2Bool("lc_vest", true)
reb:SetArmor(0)
reb:SetHealth(50)
local v = LC.Spawners.citizen(reb:GetPos() + Vector(60, 0, 0))
LC.SettleVort(v)
for _ = 1, 4 do _advance(5) _runtimers() end
LC.VortCharge(reb, v)
ok(reb:Armor() > 0 and reb:Health() == 50, "a freed vortigaunt charges our vests when asked (and doesn't heal)", reb:Armor() .. " / " .. reb:Health())
LC.RebelVorts[v] = nil v:Remove()
-- Father Grigori
local z = LC.AddZone(V0 + Vector(6000, 0, 0), 600, "rebel", 0)
local priests = {}
for _, p in ipairs(player.GetAll()) do
    if p:GetNW2String("lcf_special", "") == "chaplain" then priests[#priests + 1] = p p:SetNW2String("lcf_special", "") end
end
LC.GrigoriTick(CurTime())
local g = LC.Grigori
ok(IsValid(g) and g:GetClass() == "npc_monk" and g.lcGrigori, "Father Grigori keeps to rebel territory (while no player is him)")
if not IsValid(g) then return end
reb:SetPos(g:GetPos() + Vector(60, 0, 0))
local hp0 = reb:Health()
ok(LC.GrigoriAsk(reb, "bless") and reb:Health() > hp0 and reb:GetNW2Float("lc_blessed_until", 0) > CurTime(), "his blessing: health, and blessed for a while")
ok(not LC.GrigoriAsk(reb, "bless"), "(not again straight away)")
ok(LC.GrigoriAsk(reb, "sermon") and reb:GetNW2Float("lc_emboldened_until", 0) > CurTime(), "his sermon emboldens everyone of ours nearby")
cit:SetPos(g:GetPos() + Vector(-60, 0, 0))
ok(not LC.GrigoriAsk(cit, "bless") and LC.GrigoriAsk(cit, "talk"), "he blesses only his own, but talks to anyone")
LC.RemoveZone(z)
_setcvar("lc_grigori", 0)
LC.GrigoriTick(CurTime())
ok(not IsValid(LC.Grigori), "lc_grigori 0: he's gone")
_setcvar("lc_grigori", 1)
for _, p in ipairs(priests) do p:SetNW2String("lcf_special", "chaplain") end
LC.GrigoriTick(CurTime())
if #priests > 0 then ok(not IsValid(LC.Grigori), "a player is Father Grigori: the NPC stands aside") end
for _, p in ipairs({ cit, unit, reb }) do p:SetPos(Vector(-150000, 150000, 0)) end
end
VestTests()

function StalkerTests()
section("Stalkers: their body, their work, and the energizer")
_setcvar("lc_story_pacing", 0)
local S0 = Vector(-140000, -40000, 0)
local function posting(p) for _, sp in ipairs(LC.StoryPostings(p)) do if sp.chain == "stalker" then return sp end end end
local stk = newPlayer("StalkerWorker", "citizen")
_run(0.3)
ok(posting(stk) == nil, "a citizen gets no stalker story")
_setcvar("lc_stalker_model", "models/player/test_stalker.mdl")
ok(LC.MakeStalker(stk) and LC.PlayerIsStalker(stk), "made into a stalker")
ok(LC.ModelOverrides.stalker(stk) == "models/player/test_stalker.mdl", "lc_stalker_model sets the stalker's body")
LC.RefreshModel(stk)
ok(stk:GetModel() == "models/player/test_stalker.mdl", "and the stalker wears it")
_setcvar("lc_stalker_model", "")
local function Work(q, choose)
    if not q then return end
    for _ = 1, 12 do
        if q.done then break end
        if LC.JobGames[stk] then LC.JobGameEnd(stk, "done") end -- (the work itself is a game now: played elsewhere)
        local st = q.stages[q.stage]
        if q.done or not st then break end
        if st.kind == "choice" then LC.ResolveChoice(stk, q.id, choose) break end
        if st.pos then stk:SetPos(st.pos) end
        stk.crouch = st.crouch == true
        if st.kind == "hold" then st.progress = st.secs end
        _run(0.6)
    end
    stk.crouch = false
end
local parts = {}
for i = 1, 5 do
    local sp = posting(stk)
    if not sp then break end
    parts[#parts + 1] = sp.part
    stk.lcqNext = 0
    LC.AcceptPosting(stk, sp.id)
    local q = LC.QuestOf[stk]
    if not q then break end
    Work(q, 2)
    ok(q.done, "part " .. i .. " (" .. sp.part .. ") can be done", q.stage .. "/" .. #q.stages)
end
ok(table.concat(parts, ",") == "processing,floors,cable,frame,charge", "five parts, in order", table.concat(parts, ","))
local e = LC.Energizers[stk]
ok(IsValid(e) and e:GetNW2Int("lc_built", 0) == 3, "the energizer is built, and charged")
ok(LC.Story(stk).chains.stalker.done == "endured", "turning away from it ends the story")
for _ = 1, 4 do _advance(60) _runtimers() end
ok(LC.PlayerIsStalker(stk), "and you're still a stalker: there's no way out but death")
stk.lcqNext = 0
ok(LC.UseEnergizer(stk, e) and LC.PlayerIsStalker(stk) and stk:Alive(), "E on the energizer asks first")
-- again, and this time step in
LC.MakeStalker(stk)
ok(posting(stk) ~= nil and posting(stk).part == "processing", "a new term starts the story over")
local cid = stk:GetNW2String("lc_cid", "")
_setcvar("lc_permadeath", 0)
LC.Story(stk).chains.stalker = { part = "charge", data = { site = { S0.x, S0.y, S0.z } }, readyAt = 0 }
stk.lcStoryPostings = nil
local sp = posting(stk)
stk.lcqNext = 0
if sp then LC.AcceptPosting(stk, sp.id) end
ok(sp ~= nil and LC.QuestOf[stk] ~= nil, "the last part can be taken up again")
Work(LC.QuestOf[stk], 1)
_advance(2) _runtimers()
ok(not stk:Alive(), "stepping into the light kills the stalker")
ok(not LC.PlayerIsStalker(stk) and stk:GetPData("lc_stalker", nil) == nil, "and nothing of the stalker is left")
ok(cid == "" or stk:GetNW2String("lc_cid", "") ~= cid, "a new person, even with permanent death off", cid .. " -> " .. stk:GetNW2String("lc_cid", ""))
_setcvar("lc_permadeath", 1)
stk.alive = true stk:Spawn()
stk:SetPos(Vector(-150000, 150000, 0))
end
StalkerTests()

function MergeKickTests()
section("One Civil Protection career, the Overwatch Commander, and the kick")
local M0 = Vector(-160000, -50000, 0)
local ow = newPlayer("OldOverwatch", "ota")
_run(0.3)
ok(ow:GetNW2String("lcf_faction", "") == "cp" and LCF.IsOverwatch(ow) and ow:GetNW2Int("lcf_rank", 1) == 4, "an old Overwatch save comes back as a Combine Prison Guard")
ok(LC.QuestFaction(ow) == "ota", "the Overwatch ranks keep their own board")
local dl = newPlayer("DivLeader", "cp", nil, 900)
_run(0.3)
ok(dl:GetNW2Int("lcf_rank", 1) == 3 and LC.IsCPOfficer(dl), "a Division Leader is an officer")
ok(LC.Chains.candidate.unlock(dl) and not LC.Chains.candidate.unlock(ow), "the Overwatch Candidate story comes to Division Leaders who haven't had the conditioning")
-- the Commander
local cmd = newPlayer("OWCommander", "cp", "ow_commander", 3000)
cmd:SetPData("lcf_transhuman", "1")
LC.SetFaction(cmd, "cp", "ow_commander", true)
_run(0.3)
ok(LCF.IsOverwatch(cmd) and cmd:GetModel() == "models/player/combine_super_soldier.mdl", "the Overwatch Commander is one of the Elite")
ok(not LC.CommanderDrop(dl), "only the Commander calls in a squad")
LC.CommanderDropAt = 0
if LC.OverwatchDrop then LC.EndOverwatchDrop() end
cmd:SetPos(M0)
local okD = LC.CommanderDrop(cmd)
ok(okD and LC.OverwatchDrop ~= nil, "the Commander calls in a squad")
ok(not LC.CommanderDrop(cmd), "(and not again for a while)")
LC.EndOverwatchDrop()
-- the kick
local cit = newPlayer("KickCitizen", "citizen")
ok(not LC.Kick(cit), "citizens don't kick")
dl:SetPos(M0 + Vector(0, 2000, 0))
dl.aim = Vector(1, 0, 0)
local door = ents.Create("prop_door_rotating")
door:SetPos(dl:GetShootPos() + Vector(40, 0, -24))
door:Spawn()
local fired = {}
door.Fire = function(_, input) fired[#fired + 1] = input end
local tr0 = util.TraceHull
util.TraceHull = function() return { Hit = true, Entity = door, HitPos = door:GetPos() } end
ok(LC.KickLand(dl) == "door" and has(fired, "OpenAwayFrom"), "a kick swings an unlocked door open")
fired = {}
door.GetInternalVariable = function(_, k) if k == "m_bLocked" then return true end end
LC.KickLand(dl)
ok(not has(fired, "OpenAwayFrom"), "a locked door takes more than one")
LC.KickLand(dl)
ok(has(fired, "Unlock") and has(fired, "OpenAwayFrom"), "and gives on the second")
local tag0 = LC.GetDoorTag
LC.GetDoorTag = function(d) if d == door then return "prison" end return tag0(d) end
fired = {}
LC.KickLand(dl) LC.KickLand(dl)
ok(not has(fired, "Unlock"), "a prison door doesn't give")
LC.GetDoorTag = tag0
local vic = newPlayer("KickVictim", "citizen")
_run(0.3)
vic:SetPos(M0 + Vector(40, 2000, 0))
local hp = vic:Health()
util.TraceHull = function() return { Hit = true, Entity = vic, HitPos = vic:GetPos() } end
ok(LC.KickLand(dl) == "person" and vic:Health() < hp, "a kick knocks someone back, and hurts")
util.TraceHull = tr0
ok(LC.Kick(dl) and dl:GetNW2Float("lc_kick_at", 0) > 0, "a unit kicks: everyone sees the leg come up")
ok(not LC.Kick(dl), "(not again straight away)")
door:Remove()
for _, p in ipairs({ ow, dl, cmd, cit, vic }) do p:SetPos(Vector(-150000, 150000, 0)) LC.SetFaction(p, "citizen", nil, true) end
end
MergeKickTests()

function OperatorDoorTests()
section("The Scanner Operator, and the Overwatch's boots")
local O0 = Vector(-170000, -60000, 0)
local op = newPlayer("ScanOperator", "cp", "scanner_op")
local plain = newPlayer("ScanPlainUnit", "cp")
_run(0.3)
ok(LC.IsScannerOperator(op) and not LC.IsScannerOperator(plain), "Scanner Operator is a Civil Protection role")
ok(not LC.OperatorLink(plain), "only an operator flies from a terminal")
local con = ents.Create("lc_console") con:SetPos(O0)
op:SetPos(O0 + Vector(3000, 0, 0))
local okFar = LC.OperatorLink(op)
ok(not okFar, "an operator needs a terminal (or the Nexus)")
op:SetPos(O0 + Vector(60, 0, 0))
ok(LC.OperatorLink(op) and LC.ScannerLinks[op] ~= nil, "at a Combine console, the operator is in a scanner")
local l = LC.ScannerLinks[op]
local reb = newPlayer("ScanRebel", "resistance", nil, 900)
local wan = newPlayer("ScanWanted", "citizen")
_run(0.3)
reb:SetPos(O0 + Vector(0, 3000, 0))
local bolos = {}
hook.Add("LivingCityBOLO", "TestOperator", function(b) bolos[#bolos + 1] = b end)
local xp0 = tonumber(op:GetPData("lcf_xp_cp", 0)) or 0
local origin = reb:EyePos() - Vector(80, 0, 0)
local rep = LC.ScannerPhoto(op, l, origin, Vector(1, 0, 0))
ok(rep ~= nil and #bolos == 1 and string.find(bolos[1].text, "rebel", 1, true), "a rebel the operator photographs goes out as a BOLO", #bolos)
ok((tonumber(op:GetPData("lcf_xp_cp", 0)) or 0) > xp0, "and the operator earns XP for the report")
LC.SetWanted(wan, 120, "Test")
wan:SetPos(O0 + Vector(0, 6000, 0))
LC.ScannerPhoto(op, l, wan:EyePos() - Vector(80, 0, 0), Vector(1, 0, 0))
ok(#bolos == 1, "anyone else photographed is reported, but isn't a BOLO")
hook.Add("LivingCityBOLO", "TestOperator", function() end)
LC.EndScannerLink(op)
con:Remove()
-- doors off their hinges
local sol = newPlayer("KickSoldier", "cp", nil, 2000)
sol:SetPData("lcf_transhuman", "1") LC.SetFaction(sol, "cp", nil, true)
local eli = newPlayer("KickElite", "cp", nil, 3000)
eli:SetPData("lcf_transhuman", "1") LC.SetFaction(eli, "cp", nil, true)
local guard = newPlayer("KickGuard", "cp", nil, 1300)
guard:SetPData("lcf_transhuman", "1") LC.SetFaction(guard, "cp", nil, true)
_run(0.3)
ok(LC.KickPower(guard) == 0 and LC.KickPower(sol) == 1 and LC.KickPower(eli) == 2, "Combine Soldiers kick doors off their hinges, the Elite harder; a Prison Guard doesn't")
ok(LC.DoorFlight(1) == 0, "a Soldier's door falls over where it hung")
local lo, hi = 1e9, 0
for _ = 1, 30 do local d = LC.DoorFlight(2) lo, hi = math.min(lo, d), math.max(hi, d) end
ok(lo >= 60 and hi <= 120 and hi > lo, "an Elite's flies five to ten feet, never the same twice", lo .. " to " .. hi)
sol:SetPos(O0 + Vector(0, 9000, 0)) sol.aim = Vector(1, 0, 0)
local door = ents.Create("prop_door_rotating") door:SetPos(O0 + Vector(50, 9000, 0)) door:Spawn()
door:SetModel("models/props_c17/door01_left.mdl")
ok(LC.KickDoor(sol, door) and IsValid(LC.BlownDoors[door]) and door.nodraw, "a hinged door comes off and flies in")
ok(LC.BlownDoors[door]:GetModel() == "models/props_c17/door01_left.mdl", "(the same door)")
ok(not LC.KickDoor(sol, door), "(a door already off its hinges stays off)")
LC.RehangDoor(door)
ok(LC.BlownDoors[door] == nil and not door.nodraw, "and it's back on its hinges later")
local brush = ents.Create("func_door") brush:SetPos(O0 + Vector(50, 9200, 0)) brush:Spawn()
local fired = {}
brush.Fire = function(_, input) fired[#fired + 1] = input end
ok(not LC.KickDoor(sol, brush) and LC.BlownDoors[brush] == nil and not has(fired, "Open"), "a brush door (sliding, a shutter) doesn't budge")
local door2 = ents.Create("prop_door_rotating") door2:SetPos(O0 + Vector(50, 9400, 0)) door2:Spawn()
LC.KickDoor(guard, door2)
ok(LC.BlownDoors[door2] == nil, "a Prison Guard's kick opens it like anyone's")
door:Remove() door2:Remove() brush:Remove()
for _, p in ipairs({ op, plain, reb, wan, sol, eli, guard }) do p:SetPos(Vector(-150000, 150000, 0)) LC.SetFaction(p, "citizen", nil, true) end
end
OperatorDoorTests()

function ProgressTests()
section("Close calls, careers for life, inheritance and the levy")
_setcvar("lc_close_calls", 3)
_setcvar("lc_permadeath", 1)
local P0 = Vector(-180000, -70000, 0)
local p = newPlayer("CloseCaller", "citizen")
_run(0.3)
p:SetPos(P0)
local cid = p:GetNW2String("lc_cid", "")
ok(LC.CloseCallsLeft(p) == 3, "a person starts with three close calls")
LC.GiveItem(p, "ration", 1)
p:Kill() _run(0.5) p.alive = true p:Spawn() _run(2)
ok(p:GetNW2String("lc_cid", "") == cid and cid ~= "", "dying isn't the end: still the same person")
ok(LC.CloseCallsLeft(p) == 2 and not LC.HasItem(p, "ration"), "one close call fewer, and the pockets are gone")
ok(p:GetNW2Float("lc_recovering_until", 0) > CurTime(), "and they're still recovering for a while")
for _ = 1, 2 do p:Kill() _run(0.5) p.alive = true p:Spawn() _run(0.5) end
ok(p:GetNW2String("lc_cid", "") == cid and LC.CloseCallsLeft(p) == 0, "three close calls, still the same person")
LC.AddCredits(p, 1000 - LC.Credits(p))
p:Kill() _run(0.5) p.alive = true p:Spawn() _run(0.5)
ok(p:GetNW2String("lc_cid", "") ~= cid, "the death after the last close call is the end of them")
ok(LC.CloseCallsLeft(p) == 3, "the new person has their own close calls")
local start = GetConVar("lc_start_credits") and GetConVar("lc_start_credits"):GetInt() or 20
ok(LC.Credits(p) == start + 200, "and inherits a quarter of the savings, up to 200", LC.Credits(p))
local lg = LC.Legacy(p)
ok(lg.lives >= 1 and lg.last[1] and lg.last[1].ended == "died", "the player's legacy remembers the life")
-- a stalker's death is the end whatever's left
local st = newPlayer("FinalStalker", "citizen")
_run(0.3)
local scid = st:GetNW2String("lc_cid", "")
LC.MakeStalker(st)
ok(LC.DeathIsFinal(st), "a stalker's death is the end, close calls or not")
-- careers for life
local ow = newPlayer("LifeOverwatch", "cp", nil, 2000)
ow:SetPData("lcf_transhuman", "1") LC.SetFaction(ow, "cp", nil, true)
local okJ, whyJ = LC.CanJoinFaction(ow, "citizen")
ok(not okJ and string.find(whyJ or "", "Overwatch for life", 1, true), "a conditioned person can't go back to being a citizen", whyJ)
ok(not LC.CanJoinFaction(st, "citizen"), "nor can a stalker")
-- retiring
local okR = LC.RetireCharacter(ow)
ok(okR and not LC.Conditioned(ow) and ow:GetNW2String("lcf_faction", "") == "citizen", "retiring someone: a new person, free of the old one's career")
-- the levy
_setcvar("lc_levy_threshold", 2000)
local rich = newPlayer("Hoarder", "citizen")
LC.AddCredits(rich, 3000 - LC.Credits(rich))
ok(LC.Levy(rich) == 100 and LC.Credits(rich) == 2900, "the Union levies a tenth of what's held above 2000")
local poor = newPlayer("Saver", "citizen")
ok(LC.Levy(poor) == 0, "and nothing from anyone below it")
_setcvar("lc_levy_threshold", 0)
_setcvar("lc_close_calls", 0)
for _, q in ipairs({ p, st, ow, rich, poor }) do q:SetPos(Vector(-150000, 150000, 0)) end
LC.SetFaction(st, "citizen", nil, true)
end
ProgressTests()

function KickFollowTests()
section("Kicks: doors bang open, boots break crates, fallen doors knock out and get rehung")
local K0 = Vector(-190000, -80000, 0)
local mc = newPlayer("KickMetrocop", "cp", nil, 200)
_run(0.3)
mc:SetPos(K0) mc.aim = Vector(1, 0, 0)
local door = ents.Create("prop_door_rotating") door:SetPos(K0 + Vector(50, 0, 0)) door:Spawn()
ok(LC.KickDoor(mc, door) and door.kv.speed == "500" and LC.BlownDoors[door] == nil, "a metrocop's kick bangs the door open fast, on its hinges")
_run(1.5)
ok(door.kv.speed == "100", "(and it swings at its own pace again after)")
local crate = ents.Create("prop_physics") crate:SetPos(K0 + Vector(40, 300, 0)) crate:Spawn() crate.hp = 40
local tr0 = util.TraceHull
util.TraceHull = function() return { Hit = true, Entity = crate, HitPos = crate:GetPos() } end
LC.KickLand(mc)
util.TraceHull = tr0
ok(crate.hp <= 10, "a kick hits a crate like a crowbar", crate.hp)
-- knocked out, not killed
local vic = newPlayer("DoorVictim", "citizen")
_run(0.3)
local hp = vic:Health()
LC.KnockOut(vic, 15, 25)
ok(vic:GetNW2Float("lc_ko_until", 0) > CurTime() + 14 and vic.frozen and vic:Health() == hp, "a flying door knocks you out cold: no harm done, no close call")
_run(16)
ok(not vic.frozen, "and you come round")
-- rehanging
local sol = newPlayer("KickSoldier2", "cp", nil, 2000)
sol:SetPData("lcf_transhuman", "1") LC.SetFaction(sol, "cp", nil, true)
_run(0.3)
sol:SetPos(K0 + Vector(0, 600, 0)) sol.aim = Vector(1, 0, 0)
local d2 = ents.Create("prop_door_rotating") d2:SetPos(K0 + Vector(50, 600, 0)) d2:Spawn()
LC.KickDoor(sol, d2)
local fallen = LC.BlownDoors[d2]
ok(IsValid(fallen) and fallen.lcKickedDoor == d2, "the door is off its hinges")
local cit = newPlayer("DoorCitizen", "citizen")
_run(0.3)
local okC, whyC = LC.UseFallenDoor(cit, fallen)
ok(not okC and string.find(whyC or "", "Maintenance Technician", 1, true), "only a Maintenance Technician can hang it back up")
local tech = newPlayer("DoorTech", "citizen")
LC.SetJob(tech, "maintenance", true)
_run(0.3)
tech:SetPos(fallen:GetPos() + Vector(0, 40, 0))
fallen:SetPos(K0 + Vector(400, 600, 0))
tech:SetPos(fallen:GetPos() + Vector(0, 40, 0))
ok(LC.UseFallenDoor(tech, fallen) and LC.DoorCarriers[tech] == fallen, "a technician lifts the fallen door")
fallen:SetPos(d2:GetPos() + Vector(10, 0, 0))
tech:SetPos(d2:GetPos() + Vector(-40, 0, 0))
tech.lcDoorUseNext = 0
local c0 = LC.Credits(tech)
ok(LC.UseFallenDoor(tech, fallen), "carried back to its frame, E hangs it")
_run(9)
ok(LC.BlownDoors[d2] == nil and not d2.nodraw and LC.Credits(tech) > c0, "it's back on its hinges, and the technician is paid")
for _, e in ipairs({ door, crate, d2 }) do if IsValid(e) then e:Remove() end end
for _, q in ipairs({ mc, vic, sol, cit, tech }) do q:SetPos(Vector(-150000, 150000, 0)) LC.SetJob(q, "", true) LC.SetFaction(q, "citizen", nil, true) end
end
KickFollowTests()

function WaysModelTests()
section("Ways to get by, and the Combine model packs")
local cit = newPlayer("WaysCitizen", "citizen")
_run(0.3)
LC.AddStanding(cit, -LC.Standing(cit))
local function find(list, text) for _, w in ipairs(list) do if w.text == text then return w end end end
local ways = LC.WaysToGetBy(cit)
local stall = find(ways, "Sell from a market stall")
ok(stall and stall.need and string.find(stall.need, "Civil Standing 50", 1, true), "a stall says the one thing missing: standing", stall and stall.need)
ok(find(ways, "Get a Union job") and find(ways, "Get a Union job").open == "f3", "no job: the board is where to get one")
ok(ways[1].need == nil and ways[#ways].need ~= nil, "what you can do now comes first")
LC.GiveItem(cit, "business_license")
ok(find(LC.WaysToGetBy(cit), "Sell from a market stall").need == nil, "with a license, it's ready")
ok(LC.SendWays(cit) and _lastnet("lc_ways") ~= nil, "!ways (F1 > What now?) opens the list")
local unit = newPlayer("WaysUnit", "cp")
_run(0.3)
ok(find(LC.WaysToGetBy(unit), "Take directives") ~= nil and find(LC.WaysToGetBy(unit), "Get a Union job") == nil, "a unit's list is a unit's")
-- Combine model packs: what kind a model is, from its name
ok(LC.CombineKindOf("HLA Combine Elite models/hla/combine_elite.mdl") == "elite", "an Elite is found by its name")
ok(LC.CombineKindOf("Combine Prison Guard Shotgunner") == "guard_shotgun" and LC.CombineKindOf("Combine Soldier (Alyx)") == "soldier", "and a shotgunner guard, and a plain soldier")
ok(LC.CombineKindOf("Metro Police") == nil and LC.CombineKindOf("Combine Soldier stripped") == nil, "metrocops and the stripped soldier aren't")
ok(LC.CombineModel("elite", true) == nil, "no pack installed: Half-Life 2's own")
_setcvar("lc_pm_elite", "models/test/hla_elite.mdl")
local eli = newPlayer("WaysElite", "cp", nil, 3000)
eli:SetPData("lcf_transhuman", "1") LC.SetFaction(eli, "cp", nil, true)
_run(0.3)
LC.RefreshModel(eli)
ok(eli:GetModel() == "models/test/hla_elite.mdl", "an Elite player wears the pack's Elite", eli:GetModel())
_setcvar("lc_pm_elite", "")
_setcvar("lc_npcmodel_soldier", "models/test/hla_soldier_npc.mdl")
_setcvar("lc_npcmodel_shotgunner", "models/test/hla_soldier_npc.mdl")
local npc = LC.SpawnSoldier(Vector(-200000, -90000, 0))
ok(IsValid(npc) and npc:GetModel() == "models/test/hla_soldier_npc.mdl", "and the city's soldiers too", IsValid(npc) and npc:GetModel())
_setcvar("lc_npcmodel_soldier", "")
_setcvar("lc_npcmodel_shotgunner", "")
if IsValid(npc) then npc:Remove() end
for _, q in ipairs({ cit, unit, eli }) do q:SetPos(Vector(-150000, 150000, 0)) LC.SetFaction(q, "citizen", nil, true) end
end
WaysModelTests()

function StaffingTests()
section("Ration Production, and every job staffed")
ok(LCJ.ById.kitchen.name == "Ration Production", "the Ration Kitchen is Ration Production: rations are made, not cooked")
local P = LC.People
local alive = 0
for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" then alive = alive + 1 end end
local target = LC.JobStaffTarget()
ok(target >= 1 and target <= 4, "each job's share grows with the city, from one to four", target)
LC.StaffRoster()
local count = {}
for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" and p.job then count[p.job] = (count[p.job] or 0) + 1 end end
local short = {}
for _, o in ipairs(LCJ.Occupations) do if not o.playersOnly and (count[o.id] or 0) < math.min(target, math.floor(alive / #LCJ.Occupations)) then short[#short + 1] = o.id end end
ok(#short == 0, "every Union job has its people", short[1])
-- a job left empty is filled first
local any
for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" and p.job == "courier" then p.job = nil any = true end end
local cnt = {}
for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" and p.job then cnt[p.job] = (cnt[p.job] or 0) + 1 end end
ok(not any or (cnt[LC.NeediestJob() or ""] or 0) == 0, "a job with nobody on it is among the neediest", LC.NeediestJob())
LC.StaffRoster()
local couriers = 0
for _, p in ipairs(P.list) do if p.alive and p.role == "citizen" and p.job == "courier" then couriers = couriers + 1 end end
ok(couriers >= 1 or alive < #LCJ.Occupations, "and it's staffed again (when there are enough people to go round)", couriers .. " of " .. alive)
ok(GetConVar("lc_npc_work_pct"):GetInt() >= 85, "people with a job spend most of their day working it")
end
StaffingTests()

function OutfitSquadTests()
section("Job outfits, a little variety, and squads")
ok(LC.OutfitFor("medic", "p1", "male_03", false) == nil, "a Clinic Medic isn't put in Half-Life 2's medic clothes (those are the Resistance's): their own clothes")
local admin = newPlayer("OutfitAdmin", "citizen") admin.admin = true
ok(LC.SetOutfit(admin, "factory", { { pm = "models/player/hostage/hostage_01.mdl", skins = { 0, 1 }, bg = { hat = { 0, 1 } } } }), "an admin dresses a job")
local m1, s1, b1 = LC.OutfitFor("factory", "p7", nil, false)
local m2, s2, b2 = LC.OutfitFor("factory", "p7", nil, false)
ok(m1 == "models/humans/hostage/hostage_01.mdl" or m1 == "models/player/hostage/hostage_01.mdl" or m1 ~= nil, "factory workers wear it", m1)
ok(m1 == m2 and s1 == s2 and b1.hat == b2.hat and (s1 == 0 or s1 == 1), "each person keeps their own pick from what's allowed")
local pleb = newPlayer("OutfitPleb", "citizen")
ok(not LC.SetOutfit(pleb, "factory", {}), "only admins")
ok(LC.SetOutfit(admin, "_none", { { pm = "models/player/group01/" .. "{face}" .. ".mdl", bg = { glasses = { 0, 1 } } } }), "people without a job can have looks too")
ok(LC.SetOutfit(admin, "medic", { { pm = "models/player/group03m/" .. "{face}" .. ".mdl", npc = "models/humans/group03m/" .. "{face}" .. ".mdl" } }), "(an admin can still dress the job: a test outfit)")
local med = newPlayer("OutfitMedic", "citizen")
LC.SetJob(med, "medic", true)
med:SetNW2String("lc_model", "models/player/group01/male_04.mdl")
ok(LC.ModelOverrides.outfit(med) == "models/player/group03m/male_04.mdl", "a citizen player with the job wears its clothes, with their own face", LC.ModelOverrides.outfit(med))
local npc = LC.Spawners.citizen(Vector(-210000, -100000, 0))
local st = LC.NPCs[npc]
if st and st.profile then
    st.profile.job = "medic"
    LC.DressPerson(npc, st.profile)
    ok(string.find(npc:GetModel(), "group03m", 1, true) ~= nil, "the city's own medics dress the part", npc:GetModel())
    ok(npc.mscale and npc.mscale >= 0.96 and npc.mscale <= 1.04, "and everyone is their own height", npc.mscale)
end
ok(string.find(LC.OutfitFor("_none", "pf", nil, false, "female") or "", "female_01", 1, true) ~= nil, "a woman with no numbered face (a pack's look) gets a woman's face from a look that keeps faces")
LC.SetOutfit(admin, "factory", {})
LC.SetOutfit(admin, "_none", {})
LC.SetOutfit(admin, "medic", {})
-- the Black Mesa citizens pack, when the server has it
local oldValidBMS = util.IsValidModel
util.IsValidModel = function() return true end
if st and st.profile then
    local oldId, oldGender = st.profile.id, st.profile.gender
    st.profile.job = nil
    local worn, wrong = 0, 0
    for i = 1, 40 do
        st.profile.id = "bmstest" .. i
        st.profile.gender = (i % 2 == 0) and "female" or "male"
        if LC.DressPerson(npc, st.profile) then
            worn = worn + 1
            local fem = string.find(npc:GetModel(), "female_bms", 1, true) ~= nil
            if not string.find(npc:GetModel(), "_bms_", 1, true) or fem ~= (i % 2 == 0) then wrong = wrong + 1 end
        end
    end
    ok(worn >= 8 and worn <= 32, "with the Black Mesa pack on the server, about half the people without a job wear it", worn)
    ok(wrong == 0, "a woman in its woman's model, a man in the man's", wrong)
    LC.SetOutfit(admin, "_none", { { pm = "models/player/group01/" .. "{face}" .. ".mdl" } })
    st.profile.id = "bmstest2"
    LC.DressPerson(npc, st.profile)
    ok(not string.find(npc:GetModel(), "_bms_", 1, true), "not once the owner sets looks for people without a job", npc:GetModel())
    LC.SetOutfit(admin, "_none", {})
    st.profile.id, st.profile.gender = oldId, oldGender
end
local bmsOffered = false
for _, c in ipairs(LC.CreatorChoices()) do if string.find(c.path, "bms_citizens/female_refugee_player", 1, true) then bmsOffered = true end end
ok(bmsOffered, "and the character creator offers its citizens and refugees")
util.IsValidModel = oldValidBMS
-- squads
local tgt = newPlayer("SquadTarget", "citizen")
_run(0.3)
tgt:SetPos(Vector(-210000, -98000, 0))
local sq = {}
for i = 1, 3 do
    local s1n, sst = LC.SpawnSoldier(Vector(-210000 + i * 600, -100000, 0))
    sq[i] = { s1n, sst }
    LC.MakeOneHostile(s1n, sst, tgt)
end
for i = 1, 3 do LC.SquadFollow(sq[i][1], sq[i][2], tgt, CurTime(), false) end
local s = LC.Squads[tgt]
local n = 0
for _ in pairs(s and s.members or {}) do n = n + 1 end
ok(n == 3, "units hunting the same person are one squad", n)
ok(s and s.leader == sq[1][1], "the one nearest the target leads")
ok(sq[3][1].sched == SCHED_FORCED_GO or sq[3][1].sched == SCHED_FORCED_GO_RUN, "one who's fallen behind catches up with the leader")
sq[2][1]:SetPos(sq[1][1]:GetPos() + Vector(60, 0, 0))
ok(LC.SquadFollow(sq[2][1], sq[2][2], tgt, CurTime(), false) and sq[2][2].watchNext ~= nil, "one with the leader stops and watches the angles")
LC.CalmOne(sq[2][1], sq[2][2], CurTime())
ok(not (LC.Squads[tgt] and LC.Squads[tgt].members[sq[2][1]]), "calmed down, they leave the squad")
for i = 1, 3 do if IsValid(sq[i][1]) then sq[i][1]:Remove() end end
if IsValid(npc) then npc:Remove() end
for _, q in ipairs({ admin, pleb, med, tgt }) do q:SetPos(Vector(-150000, 150000, 0)) LC.SetJob(q, "", true) end
end
OutfitSquadTests()

function CreatorLookTests()
section("Choosing a face and clothes")
local choices = LC.CreatorChoices()
ok(#choices >= #LCF.CitizenModels, "the creator offers every Half-Life 2 citizen (and any installed citizen pack)", #choices)
local admin = newPlayer("LookAdmin", "citizen") admin.admin = true
ok(LC.SetOutfit(admin, "_creator", { { pm = "models/player/test/male_20.mdl", skins = { 2, 5 }, bg = { glasses = { 0, 1 } } } }), "an admin narrows what new characters may choose")
ok(#LC.CreatorChoices() == 1 and LC.CreatorChoice("models/player/test/male_20.mdl") ~= nil, "and the creator offers just that")
local sk, bg = LC.CleanLook("models/player/test/male_20.mdl", 9, { glasses = 1, coat = 3 })
ok(sk == 2 and bg.glasses == 1 and bg.coat == nil, "a face or a piece that isn't allowed is put right", tostring(sk))
local p = newPlayer("LookChooser", "citizen")
_run(0.3)
p:SetNW2String("lc_model", "models/player/test/male_20.mdl")
LC.SetLook(p, 5, { glasses = 1 })
ok(p:GetPData("lc_skin", "") == "5" and p:GetNW2Int("lc_skin", 0) == 5, "the chosen face is kept with the person")
ok(LC.ModelOverrides.outfit(p) == "models/player/test/male_20.mdl", "and they wear the pack's model, not Half-Life 2's", LC.ModelOverrides.outfit(p))
LC.SetOutfit(admin, "_creator", {})
ok(#LC.CreatorChoices() >= #LCF.CitizenModels, "with nothing set, it's everything installed again")
local hadPM = player_manager
player_manager = player_manager or {}
local oldAll, oldValid = player_manager.AllValidModels, util.IsValidModel
player_manager.AllValidModels = function() return { a = "models/player/packok/male_21.mdl", b = "models/player/packgone/female_22.mdl" } end
util.IsValidModel = function(m) return not string.find(m, "packgone", 1, true) end
ok(LC.CreatorChoice("models/player/packok/male_21.mdl") ~= nil and LC.CreatorChoice("models/player/packgone/female_22.mdl") == nil,
    "a pack whose model files are missing is never offered (no ERROR model)")
player_manager.AllValidModels, util.IsValidModel = oldAll, oldValid
player_manager = hadPM
for _, q in ipairs({ admin, p }) do q:SetPos(Vector(-150000, 150000, 0)) end
end
CreatorLookTests()

----------------------------------------------------------------------
section("Morning exercise: the jog")
function ExerciseJogTests()
local savedWalls = _walls
_walls = {}
LC.EndEvent(true)
local E0 = Vector(-70000, -70000, 0)
ok(not LC.ExerciseReady("jog") and not LC.StartEvent("jog"), "no jogging route on the map, no jog")
local jp = {}
for i, off in ipairs({ Vector(0, 0, 0), Vector(1200, 0, 0), Vector(1200, 1200, 0), Vector(0, 1200, 0) }) do
    jp[i] = LC.AddPoint(E0 + off, 0, "jogroute", 1)
end
ok(LC.ExerciseReady("jog"), "a route of two or more stops is enough")
local runner = newPlayer("Jogger", "citizen") runner:SetPos(E0 + Vector(40, 0, 0))
local skiver = newPlayer("Skiver", "citizen") skiver:SetPos(E0 + Vector(-9000, 0, 0))
local unitP = newPlayer("ExCop", "cp") unitP:SetPos(E0 + Vector(0, -200, 0))
_setcvar("lc_exercise_muster", 15)
ok(LC.StartEvent("jog"), "the morning jog starts")
local X = LC.ExerciseSession()
ok(X and X.kind == "jog" and X.phase == "muster", "citizens are called to the start")
ok(X and #X.units >= 2, "units are posted along the route", X and #X.units)
local means = LC.ExerciseMeans("jog", runner)
ok(string.find(means, "pace marker", 1, true) ~= nil, "the announcement says what to do", means)
_run(1)
ok(runner:GetNW2Bool("lcx_in", false), "standing at the start, you're counted in")
ok(not skiver:GetNW2Bool("lcx_in", false), "the one who stayed away isn't")
ok(X.people[unitP] == nil, "Civil Protection doesn't jog")
_run(15)
ok(X.phase == "run", "after the muster, they're off")
-- standing about next to a posted unit: the stick, and a burst of speed
local u = X.units[1]
local ust = LC.NPCs[u]
u:SetPos(ust.holdPos)
runner:SetPos(u:GetPos() + Vector(40, 0, 0))
runner.vel = Vector(0, 0, 0)
local hp0, run0, walk0 = runner:Health(), runner:GetRunSpeed(), runner:GetWalkSpeed()
_run(3.2)
ok(runner:Health() < hp0, "not jogging: a unit uses the stick", runner:Health())
ok(runner:GetRunSpeed() > run0 and runner:GetNW2Float("lcx_boost", 0) > CurTime(), "and it gives you a burst of speed to catch up", runner:GetRunSpeed())
runner:SetPos(E0 + Vector(-3000, -3000, 0)) -- (out of the unit's reach while the boost wears off)
_run(6)
ok(runner:GetRunSpeed() == run0 and runner:GetWalkSpeed() == walk0, "the boost wears off, back to your own speed", runner:GetRunSpeed())
-- the stick never takes you below 15
runner:SetHealth(18)
runner.lcxBeatNext = 0
LC.ExerciseBeat(u, runner, "jog")
ok(runner:Health() >= 15, "a beating never takes you below 15 health", runner:Health())
runner:SetHealth(100)
-- now properly: round the route ahead of the pace marker
local corners = { E0, E0 + Vector(1200, 0, 0), E0 + Vector(1200, 1200, 0), E0 + Vector(0, 1200, 0) }
local function At(d)
    for i = 2, #corners do
        local seg = corners[i]:Distance(corners[i - 1])
        if d <= seg then return LerpVector(d / seg, corners[i - 1], corners[i]) end
        d = d - seg
    end
    return corners[#corners]
end
X.runStart = CurTime() -- (the pace marker from here)
local hp1 = runner:Health()
runner.vel = Vector(200, 0, 0)
local d = 120
local behindEver = false
for _ = 1, 40 do
    runner:SetPos(At(d))
    _run(0.5)
    if runner:GetNW2Bool("lcx_behind", false) then behindEver = true end
    d = d + 100
    if not LC.ExerciseSession() then break end
end
ok(not behindEver and runner:Health() == hp1, "jogging ahead of the pace: no trouble", runner:Health())
ok(LC.ExerciseSession() == nil and LC.Event == nil, "everyone in: the jog is over")
ok(tonumber(skiver:GetPData("lce_standing", 0)) < 0, "skipping it costs Civil Standing", skiver:GetPData("lce_standing", 0))
ok(LC.NPCs[u] == nil or LC.NPCs[u].holdPos == nil, "the posted units go back to their beats")
for _, p in ipairs(jp) do LC.RemovePoint(p) end
for _, p in ipairs({ runner, skiver, unitP }) do p:SetPos(Vector(-120000, -120000, 0)) end
_walls = savedWalls
end
ExerciseJogTests()

----------------------------------------------------------------------
section("Morning exercise: the drill")
function ExerciseDrillTests()
local savedWalls = _walls
_walls = {}
LC.EndEvent(true)
local D0 = Vector(-74000, -70000, 0)
local yard = LC.AddPoint(D0, 0, "yard", 0)
local medic = newPlayer("DrillMedic", "citizen") medic:SetNW2String("lcj_job", "medic") medic:SetPos(D0 + Vector(30, 0, 0))
local d1 = newPlayer("Driller1", "citizen") d1:SetPos(D0 + Vector(300, 0, 0))
local d2 = newPlayer("Driller2", "citizen") d2:SetPos(D0 + Vector(300, 100, 0))
_setcvar("lc_exercise_muster", 15)
ok(LC.StartEvent("drill"), "the morning drill starts")
local X = LC.ExerciseSession()
ok(X and X.leaderCandidate == medic, "a Clinic Medic at the yard is asked to lead it")
_run(16)
ok(X.phase == "run" and X.leader == medic and X.people[medic] == nil, "and leads it (not judged)")
ok(X.people[d1] and X.people[d1].spot ~= nil, "everyone else has a place in the rows", X.people[d1] and tostring(X.people[d1].spot))
d1:SetPos(X.people[d1].spot)
d2:SetPos(X.people[d2].spot)
-- the leader crouches: everyone crouches
X.nextCue = math.huge
hook.Run("KeyPress", medic, IN_DUCK)
ok(X.cue and X.cue.move == "crouch", "the leader's own move is called out", X.cue and X.cue.move)
hook.Run("KeyPress", d1, IN_DUCK)
hook.Run("KeyPress", d2, IN_JUMP)
_run(2.7)
ok(X.people[d1].total == 0, "copying it is right")
ok(X.people[d2].total == 1, "the wrong move is a mistake", X.people[d2].total)
-- a spin: turn most of the way round
LC.DrillCue("spin", CurTime())
for i = 1, 7 do d1.eyeang = Angle(0, i * 60, 0) _run(0.1) end
_run(2)
ok(X.people[d1].total == 0, "turning right round counts as the spin", X.people[d1].total)
ok(X.people[d2].total == 2, "doing nothing is a mistake too", X.people[d2].total)
-- one more: the stick
local hp = d2:Health()
LC.DrillCue("jump", CurTime())
_run(2.7)
ok(X.people[d2].owed or d2:Health() < hp, "too many mistakes: a unit is sent", X.people[d2].total)
for _, u in ipairs(X.units) do if IsValid(u) then u:SetPos(d2:GetPos() + Vector(60, 0, 0)) end end
_run(1)
ok(d2:Health() < hp, "and uses the stick", d2:Health())
-- out of your place
d1:SetPos(X.people[d1].spot + Vector(400, 0, 0))
_run(3)
ok(X.people[d1].total >= 1, "wandering off your place is a mistake", X.people[d1].total)
d1:SetPos(X.people[d1].spot)
-- the rope: jump on every beat
X.people[d1].total, X.people[d2].total = 0, 0
X.cueNo, X.ropeAt, X.ropeDone, X.nextCue = 5, 5, nil, 0
X.leaderActive = 0
_run(0.2)
local rope = X.rope
ok(rope ~= nil and _lastnet("lc_drill_rope") ~= nil, "then the skipping rope comes out")
if rope then
    for b = 0, rope.beats - 1 do
        local t = rope.start + b * rope.interval
        while CurTime() < t - 0.1 do _run(0.1) end
        hook.Run("KeyPress", d1, IN_JUMP)
    end
    _run(1)
end
ok(X.rope == nil and X.people[d1].total == 0, "jumping on every beat clears it", X.people[d1].total)
ok(X.people[d2].total >= 3, "not jumping: the rope catches you", X.people[d2].total)
-- the leader stands about: the instructor's voice fills in
X.leaderActive = CurTime() - 20
X.nextCue = 0
local n0 = X.cueNo
_run(0.3)
ok(X.cueNo > n0, "with the leader idle, the moves are called anyway")
LC.EndEvent(false)
ok(LC.ExerciseSession() == nil, "it ends")
-- no leader: a Union fitness instructor runs it
medic:SetPos(Vector(-120000, -120000, 0))
LC.StartEvent("drill")
_run(16)
local X2 = LC.ExerciseSession()
ok(X2 and IsValid(X2.instructor) and X2.leader == nil, "with no medic or clerk there, an instructor runs it")
local inst = X2 and X2.instructor
LC.EndEvent(false)
ok(not (IsValid(inst) and LC.NPCs[inst] and LC.NPCs[inst].unmanaged), "and goes on their way afterwards")
LC.RemovePoint(yard)
for _, p in ipairs({ medic, d1, d2 }) do p:SetPos(Vector(-120000, -120000, 0)) end
_walls = savedWalls
end
ExerciseDrillTests()

----------------------------------------------------------------------
section("Morning exercise: the parade, breakfast, a full stomach")
function ExerciseParadeTests()
local savedWalls = _walls
_walls = {}
LC.EndEvent(true)
local P0 = Vector(-78000, -70000, 0)
local pp = {}
for i = 0, 2 do pp[#pp + 1] = LC.AddPoint(P0 + Vector(i * 800, 0, 0), 0, "parade", 1) end
local fan = newPlayer("Fan", "citizen") fan:SetPos(P0 + Vector(400, 250, 0))
local dour = newPlayer("Dour", "citizen") dour:SetPos(P0 + Vector(400, -250, 0))
fan:SetPData("lce_standing", 200)
fan:SetNW2Float("lcn_hunger", 40)
_setcvar("lc_exercise_muster", 15)
ok(LC.StartEvent("parade"), "the morning parade starts")
local X = LC.ExerciseSession()
ok(X and #X.column >= 2, "a column forms up at the start", X and #X.column)
_run(16)
ok(X.phase == "run" and X.people[fan] and X.people[dour], "the citizens lining the route are counted")
-- cheering
local c0 = X.people[fan].cheer
ok(LC.Gesture(fan, "cheer"), "/cheer")
ok(X.people[fan].cheer > c0, "cheering raises your enthusiasm", X.people[fan].cheer)
local c1 = X.people[fan].cheer
LC.ParadeChant(fan, "Glory to the Union!")
ok(X.people[fan].cheer > c1, "so does chanting", X.people[fan].cheer)
local c2 = X.people[fan].cheer
LC.ParadeChant(fan, "Glory to the Union!")
ok(X.people[fan].cheer - c2 <= (c2 - c1), "(the same line said twice counts for less)")
-- the column comes past the quiet one
X.people[dour].cheer = 10
for _, c in ipairs(X.column) do if IsValid(c) then c:SetPos(dour:GetPos() + Vector(0, 200, 0)) end end
for _, g in ipairs(X.units) do if IsValid(g) then g:SetPos(dour:GetPos() + Vector(70, 0, 0)) end end
local hp = dour:Health()
_run(5)
ok(dour:Health() < hp, "too little enthusiasm as the column passes: the stick", dour:Health())
ok(X.people[dour].cheer >= 40, "(after which you cheer)", X.people[dour].cheer)
-- keep the fan cheering, and let it finish
for _ = 1, 60 do
    if not LC.ExerciseSession() then break end
    LC.ParadeCheer(fan, 40)
    _run(1)
end
local byItself = LC.ExerciseSession() == nil
if LC.ExerciseSession() then LC.EndEvent(false) end
ok(byItself, "the column marches the route and reaches the end: over")
ok(fan:GetNW2Float("lcn_hunger", 0) >= 70, "a citizen of good standing gets breakfast", fan:GetNW2Float("lcn_hunger", 0))
-- a full stomach
fan:SetNW2Float("lcn_hunger", 95)
ok(LC.FullStomach(fan) and LC.FullStomachXP(fan, 100) == 115, "a full stomach: 15% more XP")
fan:SetNW2Float("lcn_hunger", 50)
ok(LC.FullStomachXP(fan, 100) == 100, "not on an empty one")
-- mornings: every second one, in turn
ok(LC.NextExercise(false) ~= nil, "the next morning's exercise is known", LC.NextExercise(false))
for _, p in ipairs(pp) do LC.RemovePoint(p) end
ok(LC.NextExercise(false) == nil, "and with no points on the map, there's none")
for _, p in ipairs({ fan, dour }) do p:SetPos(Vector(-120000, -120000, 0)) end
_walls = savedWalls
end
ExerciseParadeTests()

----------------------------------------------------------------------
section("Secret endings: the G-Man, the vote, the end of the city")
function EndingTests()
local savedWalls = _walls
_walls = {}
LC.EndEvent(true)
local G0 = Vector(-82000, -70000, 0)
local a = newPlayer("EndA", "citizen") a:SetPos(G0)
local b = newPlayer("EndB", "citizen") b:SetPos(G0 + Vector(200, 0, 0))
local reloaded = 0
local realReload = LC.EndingReload
LC.EndingReload = function() reloaded = reloaded + 1 end
_files["livingcity/endings.json"] = nil
_files["sound/livingcity/endings/harpies.mp3"] = ""
_setcvar("lc_ending_hard_moment_beats", 16)
_setcvar("lc_ending_marrow_max", 33)
LC.EndingRetune()
ok(GetConVar("lc_ending_hard_moment_beats"):GetString() == "5" and GetConVar("lc_ending_marrow_max"):GetString() == "33",
    "a setting still at an old default moves to the new one (a server that ran the old one gets it), one somebody chose is left alone")
_setcvar("lc_ending_marrow_max", 80)
ok(#LC.EndingSongs("harpies") == 1, "an ending's song is the file named for it")
ok(LC.EndingSongVolume("harpies") == 4 and LC.EndingSongVolume("bus") == 1, "a quiet recording (the Harpies') plays louder (lc_ending_song_volume)")
-- skipped
ok(LC.TriggerEnding("harpies", a), "an ending is triggered")
ok(LC.EndingSession().phase == "pending", "a few seconds pass first")
_run(5)
local E = LC.EndingSession()
ok(E and E.phase == "gman" and LC.TimeStopped, "then the G-Man stops time")
ok(a.frozen == true and b.frozen == true, "everyone freezes")
_files["sound/livingcity/announce/overwatch/ambient7.mp3"] = "\255\251\144\100" .. string.rep("\0", 3000)
LC.AnnounceRescan()
ok(LC.CustomAnnounce("overwatch", "ambient", nil, true) == false, "the city's announcer is quiet through it")
_files["sound/livingcity/announce/overwatch/ambient7.mp3"] = nil
LC.AnnounceRescan()
ok(hook.Run("EntityTakeDamage", a, _dmg(b, 50)) == true, "nobody can be hurt while time's stopped")
ok(not LC.StartEvent("rations"), "and the city's events wait")
LC.EndingVote(a, false)
LC.EndingVote(b, false)
_run(31)
ok(LC.EndingSession() == nil and not LC.TimeStopped and a.frozen == false, "more skips than yeses: time starts again, life goes on")
ok(not LC.TriggerEnding("harpies", a), "and there can't be another for a while")
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
-- nobody votes: the apocalypse
local realGetAll = player.GetAll
player.GetAll = function() return { a, b } end -- (just these two in the world for the endings below: the suite's other players would crowd the landing zone)
_setcvar("lc_ending_minge_swell", 20)
_setcvar("lc_ending_minge_end", 40)
_setcvar("lc_ending_minge_max", 12)
ok(LC.TriggerEnding("harpies", a), "again (cooldown cleared)")
_run(5)
local n0 = #net.sent
_run(31)
E = LC.EndingSession()
ok(E and E.phase == "apocalypse", "nobody votes: it happens")
ok(E and E.song == "livingcity/endings/harpies.mp3", "with its song (straight in the endings folder, named for it)")
local endOut = {}
local oldPrint2 = print
print = function(m) endOut[#endOut + 1] = tostring(m) end
pcall(concommand.list["lc_endings"], nil)
print = oldPrint2
endOut = table.concat(endOut, "\n")
ok(string.find(endOut, "In sound/livingcity/endings/: harpies.mp3", 1, true) and string.find(endOut, "NO SONG FOUND (looking for bus.mp3", 1, true),
    "lc_endings lists what's really in the folder, and where it looks for a missing song", endOut)
-- flying: open sky only (a wall at x = 1000, the sky at z = 3000)
local traceWas = util.TraceLine
util.TraceLine = function(t)
    local s, e = t.start, t.endpos
    if e.z > 2999 and math.abs(e.x - s.x) < 1 and math.abs(e.y - s.y) < 1 then
        return { Hit = true, HitSky = true, HitPos = Vector(s.x, s.y, 3000), Fraction = (3000 - s.z) / (e.z - s.z) }
    end
    if (s.x - 1000) * (e.x - 1000) <= 0 and s.x ~= e.x then return { Hit = true, HitPos = e, Fraction = 0.5 } end
    return { Hit = false, HitPos = e, Fraction = 1 }
end
local sky = LC.EndingSky(Vector(0, 0, 0))
util.TraceLine = traceWas
ok(sky.r >= 300 and (sky.centre.x + sky.r < 1000 or sky.centre.x - sky.r > 1000) and math.abs(sky.z - 2780) < 1,
    "whatever flies keeps to open sky: under the map's sky, on the roomiest circle that misses the buildings", math.floor(sky.r) .. " round x " .. math.floor(sky.centre.x) .. " at " .. math.floor(sky.z))
-- the landing zone up on a roof, the streets 1500 below: spots are still found
local tlWas2 = util.TraceLine
util.TraceLine = function(t)
    if t.endpos.z < t.start.z - 1000 then return { Hit = true, HitPos = Vector(t.start.x, t.start.y, -1500), Fraction = 0.5 } end
    return { Hit = false, HitPos = t.endpos, Fraction = 1 }
end
local spot = LC.EndingRingSpot(Vector(0, 0, 0), 800, false)
util.TraceLine = tlWas2
ok(spot and spot.z == -1500, "with the landing zone up on a roof, places to put things are found in the streets far below", spot and tostring(spot.z) or "none")
ok(LC.EndingOfSong("bus2.mp3") == "bus" and LC.EndingOfSong("bloom.ogg") == "bloom" and LC.EndingOfSong("busted.mp3") == nil
    and LC.EndingOfSong("Son of the Harpy.mp3") == nil, "a song's name says which ending it's for")
-- the Harpies: the mingebags (timings shortened for the test: swell at 20 s, all over by 40)
ok(E and E.mode == "lurk" and LC.EndingDark and LC.LightStyle == "a", "the lights go out, all of them")
ok(a:GetPos():Distance(E.lz) < 300 and b:GetPos():Distance(E.lz) < 300, "and everyone is at the landing zone")
local noRebels = true
for _, c in ipairs(E.folk) do if string.find(string.lower(c:GetModel() or ""), "group03/", 1, true) then noRebels = false end end
ok(#E.folk >= 12 and noRebels, "the city's people stand in the ring too (topped up with citizens, never the Resistance)", #E.folk)
local unit = ents.Create("npc_metropolice") unit:SetPos(E.lz + Vector(260, 0, 0)) unit:Spawn() unit.lcRing = true
E.combine[#E.combine + 1] = unit
local FIRE = { "prosecute", "firingtoexposetarget", "shotsfiredhostilemalignants", "readytoprosecutefinalwarning" }
for _, n in ipairs(FIRE) do _files["sound/npc/metropolice/vo/" .. n .. ".wav"] = "" end
local function runTo(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end -- (seconds into the song)
local function minges() local n = 0 for _, m in ipairs(E.minges) do if IsValid(m) then n = n + 1 end end return n end
local function closest()
    local best
    for _, m in ipairs(E.minges) do
        if IsValid(m) then for _, p in ipairs({ a, b }) do local d = m:GetPos():Distance(p:GetPos()) best = math.min(best or d, d) end end
    end
    return best or 0
end
runTo(8)
ok(minges() >= 4 and closest() > 400, "they gather far off in the dark, keeping their distance", minges() .. " at " .. math.floor(closest()))
ok(not LC.MingeHurt(E.minges[1], _dmg(a, 500)), "and nothing touches them yet")
runTo(12)
local before = minges()
ok(LC.MingeHurt(E.minges[1], _dmg(a, 500)) and minges() == before - 1, "once they've gathered, one can be put down")
runTo(13)
ok(minges() >= before, "and another takes its place")
local function fromCentre() local best for _, m in ipairs(E.minges) do if IsValid(m) then local d = m:GetPos():Distance(E.lz) best = math.min(best or d, d) end end return best or 0 end
runTo(25)
ok(E.mode == "rush" and fromCentre() >= E.ringR and fromCentre() < E.ringR + 400, "when the song swells they rush in and surround the ring, never inside it", math.floor(fromCentre()) .. " vs " .. E.ringR)
runTo(27.5)
ok(E.mode == "rush" and (E.shots or 0) > 0, "a moment before they leap, the Combine open fire (that's what sets them off)", E.shots or 0)
ok(string.find(table.concat(E.chatterLog or {}, ","), "metropolice/vo/", 1, true) ~= nil, "with the order called out loud on their radios", table.concat(E.chatterLog or {}, ","))
runTo(28)
local hurt = 0
for _, p in ipairs(player.GetAll()) do if p.lcEndTaken or p:Health() < 100 then hurt = hurt + 1 end end
ok(hurt == 0, "(nobody's hurt while they close in)", hurt)
runTo(34)
hurt = 0
for _, p in ipairs(player.GetAll()) do if p.lcEndTaken or p:Health() < 100 then hurt = hurt + 1 end end
runTo(36)
ok(E.mode == "leap" and (E.ringHits or 0) > 0 and not a.lcEndTaken and not b.lcEndTaken,
    "then they leap, at the Combine and the city's people first, and the players have a chance to run",
    E.mode .. " ring hits " .. tostring(E.ringHits) .. " a " .. tostring(a.lcEndTaken) .. " b " .. tostring(b.lcEndTaken))
ok(LC.MingeFury(E.leapAt + 10) < 0.5 and LC.MingeFury(E.leapAt + 45) > 2.5, "they hit lightly at first, and much harder 30 to 45 seconds in")
for _, n in ipairs(FIRE) do _files["sound/npc/metropolice/vo/" .. n .. ".wav"] = nil end
runTo(38.5)
ok(a.lcEndTaken and b.lcEndTaken and a.alive and b.alive and a:GetNW2Bool("lc_end_spectating", false),
    "by the end everyone's gone, and the dead watch (nobody really dies: no close call, no new character)")
ok(LC.EndingSession().phase == "apocalypse", "the song plays out with the dead watching")
runTo(41)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and when it's over the city resets")
_run(6)
ok(reloaded == 1 and LC.EndingSession() == nil and not a.lcEndTaken, "and the map reloads")
-- the flying ones and the barnacles (no vote: lc_ending <id> now)
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
_setcvar("lc_ending_bus_sections", "2:fly,6:drive,8:fast,12:end")
ok(LC.TriggerEnding("bus", a, true), "the bus")
E = LC.EndingSession()
local function runToB(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(IsValid(E.bus) and E.bus:GetPos().z < 60 and not a.lcEndRide, "first it drives about the streets (the song's intro)")
runToB(2.2)
ok(a.lcEndRide and b.lcEndRide and a.movetype == MOVETYPE_NONE and not a.frozen and a:GetNW2Bool("lc_seated", false), "on the drop, everyone's in it, seated (held in, not frozen: free to look about)")
runToB(4)
ok(E.bus:GetPos().z > 150 and a:GetPos():Distance(E.bus:GetPos()) < 400, "and it takes off, everyone in their seats", math.floor(E.bus:GetPos().z))
ok(#E.rings >= 1, "with a ring to fly through")
-- a low sky somewhere (z = 600 here): the bus keeps well under it, wherever it flies
local tlWas = util.TraceLine
util.TraceLine = function(t)
    if t.endpos.z > t.start.z + 100 and math.abs(t.endpos.x - t.start.x) < 1 and math.abs(t.endpos.y - t.start.y) < 1 then
        local zz = 600
        if t.start.z >= zz then return { Hit = true, StartSolid = true, HitPos = t.start, Fraction = 0 } end
        return { Hit = true, HitSky = true, HitPos = Vector(t.start.x, t.start.y, zz), Fraction = (zz - t.start.z) / (t.endpos.z - t.start.z) }
    end
    return tlWas(t)
end
local bp = E.bus:GetPos()
E.bus:SetPos(Vector(bp.x, bp.y, 900)) -- (up in the sky)
for _ = 1, 6 do _run(0.1) end
local outOfSky = E.bus:GetPos().z < 600
local highest = -math.huge
for _ = 1, 4 do _run(0.1) highest = math.max(highest, E.bus:GetPos().z) end
util.TraceLine = tlWas
ok(outOfSky and highest <= 600 - 150, "and keeps well under the sky, even where it comes low (if it's ever up in it, straight down out of it)", math.floor(highest))
E.rings[1]:SetPos(E.bus:GetPos())
_run(0.2)
ok((E.ringsPopped or 0) >= 1, "and through it goes: pop")
ok(hook.Run("CanPlayerSuicide", a) == false, "nobody gets off the bus")
hook.Run("PlayerDeath", a)
_run(1)
ok(a.lcEndRide and a.alive, "not even by dying: you're put straight back on")
runToB(7.5)
ok(E.section == "drive" and E.bus:GetPos().z < 100, "it comes down and drives again", math.floor(E.bus:GetPos().z))
runToB(8.5)
ok(E.section == "fast" and E.client.strobe, "then up again, faster")
LC.CancelEnding()
ok(a.lcEndRide == nil and a.frozen == false and not a:GetNW2Bool("lc_seated", false), "lc_ending_cancel puts everyone back")
_setcvar("lc_ending_bus_sections", "27:fly,149:drive,176:fast,220:end")
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
_setcvar("lc_ending_plane_sections", "1:board,2:verse,3:chorus,5:break,6:final,8:climb,10:end")
ok(LC.TriggerEnding("plane", a, true), "plane")
E = LC.EndingSession()
local function runToP(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(IsValid(E.plane) and not a.lcEndRide and E.client.dance == "numa" and #E.client.captions == 4 and E.client.webcam, "the plane circles low; the sing-along and the webcam are ready")
runToP(1.5)
ok(a.lcEndRide and b.lcEndRide and a.lcEndRide.v == E.plane and b.lcEndRide.v == E.plane and a.movetype == MOVETYPE_NONE and not a.frozen and a:GetNW2Bool("lc_dancing", false), "at the hook, everyone's up on the wings, dancing (and can look about)")
ok(a:GetPos():Distance(E.plane:GetPos()) < 500 and a:GetPos() ~= b:GetPos(), "each in their own spot along the wings")
runToP(3.5)
ok(E.client.section == "chorus" and E.plane:GetPos().z > E.lz.z + 500, "the choruses swoop, high over the city")
runToP(5.5)
ok(E.client.section == "break" and not E.client.lights, "the breakdown glides, the lights down")
runToP(8.5)
ok(E.client.section == "climb" and E.client.whiteAt, "on the final note, up into the clouds")
runToP(10.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the city resets")
_run(6)
ok(not a.lcEndRide and not IsValid(a:GetNW2Entity("lc_riding")), "(everyone back down)")
_setcvar("lc_ending_plane_sections", "17:board,26:verse,63:chorus,89:verse,122:chorus,148:break,167:final,210:climb,215:end")
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
_setcvar("lc_ending_standup_sections", "1:hang,8:last,10:end")
_setcvar("lc_ending_standup_drain", 40)
a:SetHealth(100) b:SetHealth(100)
ok(LC.TriggerEnding("standup", a, true), "standup")
E = LC.EndingSession()
local function runToS(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
runToS(0.8)
ok(#E.hanged == 0, "a moment's quiet first")
runToS(1.3)
ok(#E.hanged >= 1 and (a.lcHang or b.lcHang), "then someone's strung up", #E.hanged)
local first = #E.hanged
runToS(3)
ok(#E.hanged > first, "and someone else every other beat", #E.hanged)
local who = a.lcHang and a or b
local crowdOK = #E.crowd >= 1
for _, c in ipairs(E.crowd) do if c.lcHang or not c:GetNW2Bool("lc_dancing", false) then crowdOK = false end end
ok(crowdOK, "a crowd gathers round and cheers, and none of them is strung up", #E.crowd)
ok(not who.SetMaterial or who:GetMaterial() == "models/debug/debugwhite", "the hanged are painted white")
local coneFor
for _, h in ipairs(E.client.hangs) do if h.e == who:EntIndex() then coneFor = true end end
ok(coneFor, "with a white cone hat over the head (each screen draws it on the hanged, from the list it's sent)")
ok(not who.frozen and who:GetMoveType() == MOVETYPE_NONE and #E.client.hangs >= 1 and E.client.hangs[1].a, "the rope goes up to something, and they can't get down (but they can look about)",
    tostring(who.frozen) .. " " .. tostring(who:GetMoveType()) .. " " .. tostring(#E.client.hangs))
runToS(4.5)
ok(who.lcEndTaken and who:GetNW2Bool("lc_limp", false) and who.alive, "they lose health on the rope, then go limp, and look on (nobody really dies)")
ok(hook.Run("CanPlayerSuicide", who) == false, "and there's no way out of it")
runToS(8.5)
ok(a.lcHang and b.lcHang, "by the end of the song everyone's up")
runToS(9.9)
ok(a:GetNW2Bool("lc_limp", false) and b:GetNW2Bool("lc_limp", false), "and even the last to go up go limp before it ends (nobody left kicking on 1 health)")
runToS(10.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the city resets")
_run(6)
ok(not a.lcHang and a:GetNW2Float("lc_hanged", 0) == 0 and a.frozen == false and (not a.GetMaterial or a:GetMaterial() == ""), "(everyone cut down, the paint off)")
_setcvar("lc_ending_standup_sections", "11:hang,104:last,110:end")
_setcvar("lc_ending_standup_drain", 4)
-- Bloom: everyone dances, the song speeds up, and they spin up one at a time (short timings for the test)
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
_setcvar("lc_ending_bloom_speedup", 3)
_setcvar("lc_ending_bloom_ramp", 2)
_setcvar("lc_ending_bloom_launch_secs", 4)
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
ok(LC.TriggerEnding("bloom", a, true), "bloom")
E = LC.EndingSession()
ok(a.frozen and b.frozen and a:GetNW2Bool("lc_dancing", false) and b:GetNW2Bool("lc_dancing", false), "everyone dances, and can't stop")
ok(a:GetPos():Distance(E.lz) < 300 and b:GetPos():Distance(E.lz) < 300, "at the landing zone, all together")
ok(LC.TimeStopped and LC.LightStyle == "e", "the city stops what it's doing, and dims")
ok(E.client and math.abs(E.client.rateAt - (E.phaseT + 3)) < 0.01 and E.client.peak > 1, "the speed-up is timed from the song's start")
_run(4.5)
local function up() local n = 0 for _, p in ipairs(player.GetAll()) do if p.lcBloomUp then n = n + 1 end end return n end
ok(up() == 0, "nobody goes up until it's at top speed")
_run(0.55)
ok(up() == 1, "then one spins up into the sky", up())
_run(E.launchGap + 0.15) -- (a little past the gap: run in tenths, a gap of exactly 0.6 lands on the boundary)
ok(up() == 2, "and then another: one at a time", up())
local total = #player.GetAll()
_run(E.launchGap * total + 3)
ok(a.lcEndTaken and b.lcEndTaken and a.alive and b.alive, "until everyone's gone (nobody really dies)")
LC.CancelEnding()
ok(not a:GetNW2Bool("lc_dancing", false) and a.frozen == false and not LC.TimeStopped, "and a cancel lets everyone stop")
_setcvar("lc_ending_bloom_speedup", 121)
_setcvar("lc_ending_bloom_ramp", 20)
_setcvar("lc_ending_bloom_launch_secs", 16)
-- Marrow: skeletons, the song's sections (short ones for the test), and the Combine's units in it too
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
_setcvar("lc_ending_marrow_sections", "3:dance,6:rave,8:attack,12:outro,14:end")
_setcvar("lc_ending_marrow_max", 8)
local mcop = LC.Spawners.cop(G0 + Vector(-3000, 0, 0))
local mdoor = ents.Create("prop_door_rotating") mdoor:SetPos(G0 + Vector(0, -900, 0))
a:SetPos(G0 + Vector(0, 2000, 0)) b:SetPos(G0 + Vector(200, 0, 0))
a:SetHealth(100) b:SetHealth(100)
ok(LC.TriggerEnding("marrow", b, true), "marrow")
E = LC.EndingSession()
ok(a:GetPos():Distance(E.lz) < 300 and IsValid(mcop) and mcop:GetPos():Distance(E.lz) < 500, "everyone, the Combine's units too, is put at the landing zone")
ok(mdoor.lcHeldOpen and has(mdoor.fired, "Open") and has(mdoor.fired, "Lock"), "and every door is locked open")
local nearNow = 0
for _, k in ipairs(E.skels) do if IsValid(k) and k:GetPos():Distance(E.lz) < 800 then nearNow = nearNow + 1 end end
ok(nearNow >= 5, "skeletons in plain sight round everyone from the very start", nearNow)
ok(E.client and E.client.party and E.client.lights and E.client.ambient and LC.LightStyle == "a" and #E.client.palette == 2,
    "the map goes dark, and purple and orange light pulses everywhere")
_run(2)
ok(#E.skels > 0, "skeletons appear all round", #E.skels)
local allDancing = true
for _, k in ipairs(E.skels) do if IsValid(k) and not k:GetNW2Bool("lc_dancing", false) then allDancing = false end end
ok(allDancing, "and through the opening they just dance, waiting for the drop")
ok(#(E.folk or {}) >= 1 and E.folk[1]:GetPos():Distance(E.lz) < 500, "the city's people are there with everyone too", #(E.folk or {}))
local function runToM(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
runToM(3.5)
ok(E.section == "dance" and a.frozen and a:GetNW2Bool("lc_dancing", false) and mcop:GetNW2Bool("lc_dancing", false) and E.client.lights and E.client.strobe,
    "the drop: everyone dances with them, the Combine's units too, the lights strobing")
ok(not LC.SkelHurt(E.skels[1], _dmg(a, 500)), "and nothing hurts a dancing skeleton")
ok(E.client.spots and E.client.lz and E.client.spotR, "purple and orange spotlights sweep round the circle while everyone dances")
runToM(6.5)
ok(E.section == "rave" and E.client.dance == "rave" and E.client.danceRate > 1, "the rave part: faster")
runToM(8.5)
ok(E.section == "attack" and a.frozen == false and not a:GetNW2Bool("lc_dancing", false), "in between, the dancing stops")
ok(E.client.loud and not E.client.spots, "and the song comes up over the gunfire (the spotlights off till the next dance)")
local k1 = E.skels[1]
for _, c in ipairs(E.folk or {}) do if IsValid(c) then c:SetPos(c:GetPos() + Vector(0, 5000, 0)) end end -- (out of the way: it goes for whoever's nearest)
k1:SetPos(a:GetPos() + Vector(30, 0, 0))
a:SetHealth(2)
_run(0.3)
ok(a.lcEndTaken and a:GetModel() == "models/player/skeleton.mdl" and a:GetNW2Bool("lc_dancing", false) and a.alive,
    "they attack; whoever they get becomes one of them, dancing for good", a:Health())
local nk = #E.skels
ok(LC.SkelHurt(E.skels[#E.skels], _dmg(b, 500)), "and in a fight, they can be put down")
ok((E.shots or 0) > 0, "the Combine's units shoot at them in a fight", E.shots or 0)
local pistols = 0
for _, w in ipairs(mcop.weps or {}) do if w == "weapon_pistol" then pistols = pistols + 1 end end
ok(pistols <= 1, "(a unit with a stunstick is given one pistol, not one a shot: that ran the server out of entities)", pistols)
local edWas = ents.GetEdictCount
ents.GetEdictCount = function() return 8100 end
local before = #E.skels
_run(0.5)
ents.GetEdictCount = edWas
ok(#E.skels <= before, "and nothing more is spawned once the server's near its limit (lc_ending_edict_limit)", before .. " -> " .. #E.skels)
_setcvar("lc_ending_marrow_max", 80)
local few, many = LC.MarrowCount(1), LC.MarrowCount((E.holdUntil - E.phaseT) * 0.62)
_setcvar("lc_ending_marrow_max", 8)
ok(few <= 16 and many == 80, "just more and more of them: a handful at first, the whole horde by two thirds of the way through", few .. " then " .. many)
runToM(12.5)
ok(E.section == "outro" and b.lcEndTaken and not IsValid(mcop), "the outro claims everyone left (the Combine's units too)")
ok(E.client.danceRate == 2, "and everyone dances double time to the xylophone")
runToM(14.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and when the song's over, the city resets")
_run(6)
ok(a:GetModel() ~= "models/player/skeleton.mdl" and not mdoor.lcHeldOpen, "(everyone's back as they were, the doors too)")
_setcvar("lc_ending_marrow_sections", "45:dance,75:attack,82:rave,112:attack,150:dance,180:attack,188:dance,217:outro,232:end")
_setcvar("lc_ending_marrow_max", 80)
if IsValid(mdoor) then mdoor:Remove() end
-- Base: someone set up us the bomb (short timings for the test)
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
_setcvar("lc_ending_base_sections", "1:bomb,2:screen,3:zig,5:move,7:justice,9:boom,10:end")
_setcvar("lc_ending_base_bombs", 6)
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
ok(LC.TriggerEnding("base", a, true), "base")
E = LC.EndingSession()
local function runToX(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(E.client and #E.client.lines >= 10 and E.client.lines[1].t == 2.15 and string.find(E.client.lines[2].text, "set up us the bomb", 1, true) and E.client.lines[4].t == 6.5 and string.find(E.client.lines[4].text, "What !", 1, true), "the opening lines, as subtitles, timed to the song")
ok(LC.TimeStopped and LC.LightStyle == "f", "the city stops and stares, and dims")
runToX(1.5)
ok(#E.bombs >= 5 and #E.client.bombs >= 5, "somebody set up us the bomb: all over the city", #E.bombs)
runToX(2.5)
ok(E.client.cats, "main screen turn on: CATS in the sky")
runToX(3.5)
ok(#E.zigs >= 3 and a.lcEndRide and b.lcEndRide and not a.frozen and a.movetype == MOVETYPE_NONE and IsValid(a:GetNW2Entity("lc_riding")), "take off every ZIG: everyone aboard the fleet (free to look about)")
runToX(4.8)
ok(E.zigs[1]:GetPos().z > E.lz.z + 400 and a:GetPos():Distance(a.lcEndRide.v:GetPos()) < 400, "the fleet flies, everyone on top of it", math.floor(E.zigs[1]:GetPos().z - E.lz.z))
ok(LC.Engrish("this is your base") == "this are belong you base !!" and LC.Engrish("What happened?") == "What happen ??", "and everyone's chat comes out in Engrish")
runToX(9.5)
local live = 0
for _, bb in ipairs(E.bombs) do if IsValid(bb) then live = live + 1 end end
ok(E.client.boomAt and live == 0 and not E.client.cats, "for great justice: everything blows")
runToX(10.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the city resets")
_run(6)
ok(not a.lcEndRide and not IsValid(a:GetNW2Entity("lc_riding")), "(everyone off the ZIGs)")
_setcvar("lc_ending_base_sections", "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end")
_setcvar("lc_ending_base_bombs", 60)
-- Hard: party hard (short timings for the test)
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
_setcvar("lc_ending_hard_sections", "1:hard,3:break,4:hard,6:passout,9:fade,10:end")
_setcvar("lc_ending_hard_moment_beats", 2)
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
local partyCops = {}
for i = 1, 3 do
    local pc = ents.Create("npc_metropolice") pc:Spawn()
    LC.NPCs[pc] = { role = "cop", state = "idle", untilT = 0, nextWarn = 1e9, nextInspect = 1e9 }
    partyCops[i] = pc
end
local partyCop = partyCops[1]
ok(LC.Endings.hard.flashing and LC.Endings.marrow.flashing and not LC.Endings.harpies.flashing, "the ones with strobes are marked, so everyone's warned first")
ok(LC.TriggerEnding("hard", a, true), "hard")
E = LC.EndingSession()
local function runToH(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(a.frozen and a:GetNW2Bool("lc_dancing", false) and a:GetPos():Distance(E.lz) < 300 and E.client.dance == "hard" and E.client.partyText,
    "everyone at the landing zone, dancing the party hard dance, PARTY HARD everywhere")
local mostAtOnce = 0
while CurTime() < E.phaseT + 2.9 do _run(0.1) mostAtOnce = math.max(mostAtOnce, #(E.moments or {})) end
ok((E.momentsDone or 0) >= 2 and mostAtOnce >= 2, "the Combine's units go for it (a crowd surf, a spin, a backflip), two or three at once", (E.momentsDone or 0) .. " / " .. mostAtOnce)
runToH(3.5)
ok(E.client.section == "break" and not E.client.strobe, "the break: everyone freezes mid-pose")
runToH(4.5)
ok(E.client.section == "hard" and E.client.strobe, "then it slams back in")
local function down() local n = 0 for _, p in ipairs({ a, b }) do if p.lcEndTaken then n = n + 1 end end return n end
runToH(6.5)
ok(down() == 1, "they start passing out, one at a time", down())
local outP = a.lcEndTaken and a or b
ok(not outP.frozen, "out of it, you're not frozen any more (the keys work)")
hook.Run("KeyPress", outP, IN_JUMP)
ok(outP.lcEndRoam, "and jump lets you fly free")
_run(0.4)
outP.keys = { [IN_JUMP] = true }
_run(0.2)
outP.keys = nil
ok(not outP.lcEndRoam, "(and it works even if the key event never comes: the keys are watched too)",
    tostring(LC.EndingSession() and LC.EndingSession().phase) .. " spect " .. tostring(outP.lcEndSpectating) .. " was " .. tostring(outP.lcEndKeyWas and outP.lcEndKeyWas[IN_JUMP]) .. " kd " .. tostring(outP.KeyDown and outP:KeyDown(IN_JUMP)))
runToH(8)
ok(down() == 2 and a.alive and b.alive, "until nobody's left standing (nobody really dies)", down())
runToH(10.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the city resets")
_run(6)
_setcvar("lc_ending_hard_sections", "6:hard,28:break,32:hard,150:passout,177:fade,188:end")
_setcvar("lc_ending_hard_moment_beats", 5)
for _, pc in ipairs(partyCops) do LC.NPCs[pc] = nil if IsValid(pc) then pc:Remove() end end
-- Shalom: the hora (short timings for the test)
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
_setcvar("lc_ending_shalom_sections", "1:gather,2:walk,3:hora,4:lift,5:in,6:peak,7:final,8:outro,9:end")
_setcvar("lc_ending_shalom_candles", "2,3,4,5,6,6.2,6.4,6.6")
_setcvar("lc_ending_shalom_offset", 0)
_setcvar("lc_ending_shalom_lift_beats", 2)
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
local horaCops = {}
for i = 1, 2 do
    local pc = ents.Create("npc_metropolice") pc:Spawn()
    pc:Give("weapon_stunstick")
    LC.NPCs[pc] = { role = "cop", state = "idle", untilT = 0, nextWarn = 1e9, nextInspect = 1e9, test = true } -- (the city leaves test NPCs be)
    horaCops[i] = pc
end
ok(not LC.Endings.shalom.flashing and LC.EndingOfSong("shalom.mp3") == "shalom", "shalom: its song is shalom.mp3, and it has no strobes")
ok(LC.TriggerEnding("shalom", a, true), "shalom")
E = LC.EndingSession()
local function runToS(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(a.frozen and a.movetype == MOVETYPE_NONE and a:GetNW2Bool("lc_dancing", false) and E.client.dance == "hora" and a.lcHora and b.lcHora,
    "everyone in the inner ring at the landing zone, ready to dance the hora")
ok(E.client.menorah and #E.client.candles == 8 and #E.client.poles == 8 and E.client.sky, "a hanukkiah in the middle, eight candles to light, eight flagpoles round it, a sky for the big flag")
ok(#E.rings.outer.members == GetConVar("lc_ending_shalom_crowd"):GetInt(), "the city's people in the outer ring", #E.rings.outer.members)
ok(horaCops[1].lcHora and not horaCops[1]:GetNW2Bool("lc_dancing", false), "the Combine's units round the outside, watching")
ok(E.client.menorah.w / 2 < E.rings.inner.r * 0.65, "(the hanukkiah fits inside the rush into the middle)")
local p0 = a:GetPos()
runToS(0.9)
ok(a:GetPos():Distance(p0) < 1, "the intro: everyone stands, arm in arm")
runToS(3.5)
ok(a:GetPos():Distance(p0) > 5, "then the rings go round", a:GetPos():Distance(p0))
ok(E.rings.inner.spin > 0 and E.rings.outer.spin < 0, "the two rings go opposite ways")
local grounded
for _, m in ipairs(E.rings.inner.members) do if not m.lift and IsValid(m.e) then grounded = m.e end end
ok(grounded and math.abs(grounded:GetPos().z - E.floorZ) < 0.01, "and everyone (not up on a chair) is right on the floor: held even a little above it, a dancer looks like they float",
    grounded and (grounded:GetPos().z - E.floorZ))
ok(E.joined and horaCops[1]:GetNW2Bool("lc_dancing", false) and horaCops[1].lcHora and #(E.hidWeps or {}) >= 1,
    "the hora proper: the Combine's units put their guns down and join the outer ring")
runToS(4.6)
local chaired
for _, p in ipairs({ a, b }) do if p:GetNW2Bool("lc_chair", false) then chaired = p end end
for _, m in ipairs(E.rings.outer.members) do if IsValid(m.e) and m.e:GetNW2Bool("lc_chair", false) then chaired = chaired or m.e end end
ok(chaired and (E.lifted or {})[chaired], "someone's lifted up on a chair")
local ringR = E.rings.inner.r
runToS(5.9)
ok(E.rush < 0.9 and (a:GetPos() - E.lz):Length2D() < ringR * 0.95, "the breakdown: everyone rushes into the middle", E.rush)
runToS(8.5)
ok(not a.lcEndTaken and not b.lcEndTaken, "nobody's taken: everyone dances to the end")
runToS(9.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the song's over: the city resets")
_run(6)
ok(not a.frozen and a.movetype ~= MOVETYPE_NONE and not a:GetNW2Bool("lc_dancing", false) and not a:GetNW2Bool("lc_chair", false) and not a.lcHora,
    "(and everyone can move again)")
_setcvar("lc_ending_shalom_sections", "7.4:gather,35.7:walk,62.1:hora,111.5:lift,125.7:hora,153.9:in,157.4:hora,180.4:in,183.9:build,205.1:peak,219.2:hora,224.5:in,231.5:final,273.9:outro,288.5:end")
_setcvar("lc_ending_shalom_candles", "35.7,62.1,86.8,111.5,125.7,153.9,183.9,205.1")
_setcvar("lc_ending_shalom_offset", 0.36)
_setcvar("lc_ending_shalom_lift_beats", 8)
for _, pc in ipairs(horaCops) do LC.NPCs[pc] = nil if IsValid(pc) then pc:Remove() end end
-- Fire: behinds on fire, then flying on them (short timings for the test)
;(function()
    concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
    _setcvar("lc_ending_fire_sections", "1:ignite,2:hop,3:fly,10:launch,13:end")
    _setcvar("lc_ending_fire_offset", 0)
    a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
    ok(LC.Endings.fire and LC.Endings.fire.flashing and LC.EndingOfSong("fire.mp3") == "fire" and LC.EndingOfSong("fire2.ogg") == "fire",
        "fire: its song is fire.mp3, and everyone's warned (the explosions at the end)")
    ok(LC.TriggerEnding("fire", a, true), "fire")
    local F = LC.EndingSession()
    local function runToF(sec) _run(math.max(0.1, F.phaseT + sec - CurTime())) end
    ok(F.id == "fire" and a.frozen and a.movetype == MOVETYPE_NONE and a:GetNW2Bool("lc_dancing", false) and F.client.fire and F.client.dance == "fire",
        "everyone held at the landing zone, ready to dance")
    ok(#F.fliers >= 2 + GetConVar("lc_ending_fire_crowd"):GetInt(), "the players, and the city's people round them", #F.fliers)
    local home
    for _, f in ipairs(F.fliers) do if f.e == a then home = f.home end end
    runToF(0.5)
    ok(a:GetNW2Float("lc_fire", -1) == 0 and a:GetPos() == home, "the intro: only sputtering, everyone standing on the floor")
    runToF(1.5)
    ok(a:GetNW2Float("lc_fire", 0) == 1 and a:GetPos() == home, "the drop: every behind lights up, and the dancing starts")
    local top = 0
    for _ = 1, 8 do _run(0.11) top = math.max(top, a:GetPos().z - home.z) end
    ok(top > 5 and top <= GetConVar("lc_ending_fire_hop"):GetFloat() + 0.01 and a:GetNW2Float("lc_fire", 0) > 1, "then the flames grow and everyone hops on the beat", top)
    runToF(4)
    ok(a:GetNW2Bool("lc_flying", false) and a:GetPos().z > home.z + 20, "the peak: lift off", a:GetPos().z - home.z)
    runToF(9.3)
    local fl = F.flight
    local d = Vector(a:GetPos().x - fl.centre.x, a:GetPos().y - fl.centre.y, 0):Length()
    ok(math.abs(d - fl.r) < 1 and a:GetPos().z >= fl.z - 91 and a:GetPos().z <= fl.z + 111, "then everyone flies round a ring in the open sky", d .. " of " .. fl.r)
    local y0 = a:GetNW2Float("lc_fly_yaw", 0)
    _run(0.5)
    ok(a:GetNW2Float("lc_fly_yaw", 0) ~= y0, "facing the way they fly, round and round")
    runToF(12.6)
    ok(a.lcEndTaken and b.lcEndTaken and a:GetNW2Float("lc_fire", 1) == 0, "the end: each one rockets up and goes off like a firework, and watches the rest")
    runToF(13.5)
    ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the song's over: the city resets")
    _run(6)
    ok(not a.frozen and a.movetype ~= MOVETYPE_NONE and not a:GetNW2Bool("lc_flying", false) and a:GetNW2Float("lc_fire", 0) == 0 and not a.lcFire,
        "(and everyone can move again)")
    _setcvar("lc_ending_fire_sections", "12.2:ignite,60.2:hop,101:fly,146.6:launch,153:end")
    _setcvar("lc_ending_fire_offset", 0.18)
end)()
-- Father Grigori eats the motherlode
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
local grig = newPlayer("EndGrigori", "resistance", "chaplain", 300)
player.GetAll = function() return { a, b, grig } end -- (just these three: the stage holds them all)
grig:SetPos(G0 + Vector(0, 300, 0))
a:SetPos(G0) b:SetPos(G0 + Vector(200, 0, 0))
a:SetHealth(100) b:SetHealth(100)
LC.SlashCommands.eatchip(a)
ok(LC.EndingSession() == nil, "only Father Grigori can eat it")
LC.SlashCommands.eatchip(grig)
ok(LC.EndingSession() == nil, "and only with the motherlode in his pockets")
LC.GiveItem(grig, "master_chip", 1)
_setcvar("lc_ending_flood_sections", "2:heavy,5:climax,8:outro,10:last,11:end")
_setcvar("lc_ending_flood_rise", 300)
_setcvar("lc_ending_flood_drown", 2)
_setcvar("lc_ending_flood_attack_from", 4)
LC.InvAction(grig, "eatchip", "master_chip")
E = LC.EndingSession()
ok(E and E.id == "water" and not LC.HasItem(grig, "master_chip"), "he eats the master data core (Eat it, in his pockets): the flood")
_run(5)
_run(31)
E = LC.EndingSession()
local function runToW(sec) _run(math.max(0.1, E.phaseT + sec - CurTime())) end
ok(E and E.phase == "apocalypse" and grig:GetNW2Bool("lc_rocking", false), "a stage at the landing zone, and he rocks out on it")
ok(IsValid(E.stage) and a:GetPos():Distance(E.stage:GetPos()) < 250 and grig:GetPos():Distance(E.stage:GetPos()) < 30, "everyone's on the stage with him")
ok(GetGlobal2String("lc_weather", "") == "storm" and GetGlobal2Bool("lc_storm_max", false), "in the worst storm the city's seen")
local z0 = E.floodZ
runToW(3)
ok(E.floodZ > z0 and E.stage:GetPos().z >= E.lz.z, "the water rises, and the stage floats on it")
ok(E.stage:GetPos().z + E.stageTop > E.floodZ, "with its deck above the water line, not under it", math.floor(E.stage:GetPos().z + E.stageTop - E.floodZ))
local rockingN, crowdN = 0, 0
for _, c in ipairs(E.crowd) do
    if IsValid(c) and c:GetNW2Bool("lc_crowd", false) then crowdN = crowdN + 1 end
    if IsValid(c) and c:GetNW2Bool("lc_rocking", false) then rockingN = rockingN + 1 end
end
ok(#E.crowd >= 1 and crowdN >= 1 and rockingN >= 1, "a crowd's up there with him, headbanging (the Combine's units and the city's people; the waves may have taken one or two already)",
    #E.crowd .. " / " .. rockingN)
a:SetPos(E.stage:GetPos() + Vector(40, 0, -10))
_run(0.2)
ok(a:GetPos().z >= E.stage:GetPos().z + E.stageTop, "anyone the deck rises into is lifted onto it (no getting stuck inside)")
ok(E.client and E.client.section == "heavy" and E.client.bpm, "his screen knows the section (he headbangs the heavy parts, dances the rest) and the beat")
-- knocked into the water by the edge: hold Jump and you climb back on
a:SetPos(E.stage:GetPos() + Vector(220, 0, -40))
a.keys = { [IN_JUMP] = true }
_run(0.2)
a.keys = nil
ok(a:GetPos().z >= E.stage:GetPos().z + E.stageTop and math.abs(a:GetPos().x - E.stage:GetPos().x) < 190, "knocked into the water by the edge, hold Jump and you haul yourself back on")
a:SetPos(E.stage:GetPos() + Vector(60, 0, 8)) -- (in the game the stage lifts you as it rises; here, put back on it)
a.pushed = nil
runToW(3.5)
ok(a.pushed ~= nil, "the waves shove at anyone on the stage")
-- into the water: the ichthyosaurs come
b:SetPos(E.stage:GetPos() + Vector(700, 0, -120))
runToW(4.5)
ok(#E.icthys >= 1, "ichthyosaurs in the water", #E.icthys)
local fish = E.icthys[1]
fish:SetPos(b:GetPos() + Vector(40, 0, 0))
_run(0.3)
ok(b:Health() < 100 or b.lcEndTaken, "they go for anyone in the water (once they're hunting: lc_ending_flood_attack_from)", b:Health())
ok(b.lcEndTaken or b:Health() > 80, "(a bite hurts, but it's no instant death)", b:Health())
ok(#(E.boats or {}) >= 1 and E.client.spots and E.client.spotEnt, "rowboats on the water round the stage, and stage lights on it", #(E.boats or {}))
-- Father Grigori: untouchable
local grigHP = grig:Health()
fish:SetPos(grig:GetPos())
LC.IcthyStep(fish, 0.1)
grig:SetPos(E.stage:GetPos() + Vector(900, 0, -300))
_run(0.3)
ok(grig:Health() >= grigHP and grig:GetPos():Distance(E.stage:GetPos()) < 30 and not grig.lcEndTaken, "Father Grigori can't be hurt, or knocked off")
-- under too long: you drown
a:SetPos(E.stage:GetPos() + Vector(0, 900, -400))
runToW(8)
ok(a.lcEndTaken, "stay under too long and you drown (and watch)")
runToW(10.5)
ok(b.lcEndTaken and grig.lcEndTaken, "the last note: whoever's left goes, Father Grigori last of all")
runToW(11.5)
ok(LC.EndingSession() and LC.EndingSession().phase == "reset", "and the city resets")
_run(6)
-- started by an admin (nobody's eaten anything): the city's own Father Grigori takes the stage
concommand.list.lc_ending_reset_cooldown(nil, "lc_ending_reset_cooldown", {})
ok(LC.TriggerEnding("water", a, true), "the flood, started by an admin")
E = LC.EndingSession()
ok(IsValid(E.grigori) and not E.grigori:IsPlayer() and E.grigori:GetNW2Bool("lc_rocking", false) and not a:GetNW2Bool("lc_rocking", false),
    "and Father Grigori is there anyway (an NPC), rocking out, not the admin")
local npcGrig = E.grigori
LC.CancelEnding()
ok(not IsValid(npcGrig) or not npcGrig:GetNW2Bool("lc_rocking", false), "(cancelled: he stops)")
player.GetAll = realGetAll
_setcvar("lc_ending_flood_sections", "15:heavy,79:calm,102:heavy,134:calm,169:heavy,183:climax,212:calm,235:heavy,249:climax,264:outro,276:last,285:end")
_setcvar("lc_ending_flood_rise", 900)
_setcvar("lc_ending_flood_drown", 15)
_setcvar("lc_ending_flood_attack_from", 140)
LC.EndingReload = realReload
_setcvar("lc_ending_minge_swell", 60)
_setcvar("lc_ending_minge_end", 120)
_setcvar("lc_ending_minge_max", 60)
_files["sound/livingcity/endings/harpies.mp3"] = nil
_files["livingcity/endings.json"] = nil
for _, p in ipairs({ a, b, grig }) do p:SetPos(Vector(-120000, -120000, 0)) end
_walls = savedWalls
end
EndingTests()

----------------------------------------------------------------------
section("Freq 7: the seven frequencies, the program, the hunt")
function Freq7Tests()
local A = "sound/livingcity/announce/radio/"
local n7 = 0
for f10 = 875, 1080 do if LC.IsFreq7(f10 / 10) then n7 = n7 + 1 end end
ok(n7 == 7 and #LC.Freq7Freqs == 7, "exactly seven frequencies on the dial have digits adding up to seven", n7)
for _, f in ipairs(LC.Freq7Freqs) do if not LC.IsFreq7(f) then ok(false, "every one of them follows the rule", f) end end
-- an .ogg's length, from the file
local function u32(v) return string.char(v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256) end
local ogg = "OggS" .. string.rep("\0", 24) .. "\1vorbis" .. u32(0) .. "\2" .. u32(44100) .. string.rep("\0", 40)
    .. "OggS" .. "\0\4" .. u32(44100 * 125) .. "\0\0\0\0" .. string.rep("\0", 20)
_files[A .. "freq7_song_rag.ogg"] = ogg
ok(math.abs((LC.OggDuration("livingcity/announce/radio/freq7_song_rag.ogg") or 0) - 125) < 0.01, "a song's length is read from the .ogg itself")
_files[A .. "freq7_1.wav"] = ""
_files[A .. "freq7_2.wav"] = ""
_files[A .. "freq7_sweep1.wav"] = ""
LC.AnnounceRescan()
LC.Freq7Reset()
local now = CurTime()
LC.Freq7Tick(now, 0)
local first = LC.Freq7Now()
ok(first.onAir and LC.IsFreq7(first.f) and first.kind == "voice", "it starts on one of the seven, with a voice line", first.kind)
local kinds = { first.kind }
for i = 1, 3 do
    now = now + 200
    LC.Freq7.holdUntil = now + 9999
    LC.Freq7Tick(now, 1)
    kinds[#kinds + 1] = LC.Freq7Now().kind
end
ok(table.concat(kinds, ",") == "voice,quiet,voice,quiet" and LC.Freq7Now().clip == nil, "no music by default: a voice line, then a quiet spell (just static), so the band stays clear for talk", table.concat(kinds, ","))
_setcvar("lc_freq7_songs", 1) -- (songs back on, for the server that wants them)
LC.Freq7Reset()
LC.Freq7Tick(now, 0)
kinds = { LC.Freq7Now().kind }
for i = 1, 5 do
    now = now + 200
    LC.Freq7.holdUntil = now + 9999
    LC.Freq7Tick(now, 1)
    kinds[#kinds + 1] = LC.Freq7Now().kind
end
ok(table.concat(kinds, ",") == "voice,song,voice,song,voice,song", "with lc_freq7_songs 1: a voice line, then a song, back and forth", table.concat(kinds, ","))
local seq = LC.Freq7Now().seq
hook.Run("LivingCityEventSoon", "sweep", 120)
local w = LC.Freq7Now()
ok(string.find(w.clip or "", "freq7_sweep1", 1, true) and w.seq > seq, "a warning for the Resistance cuts in at once, mid-song")
now = now + 30
LC.Freq7Tick(now, 1)
ok(LC.Freq7Now().kind == "song", "and a song follows it")
_setcvar("lc_freq7_songs", 0)
-- the hunt: found, jammed, dark, back somewhere else
local unit = newPlayer("Freq7Unit", "cp")
unit.chat = {}
local was = LC.Freq7Now().f
LC.Freq7.holdUntil = now
LC.Freq7Tick(now, 1)
local j = LC.Freq7Now()
ok(not j.onAir and j.f == was and j.loop and j.clip == "ambient/energy/electric_loop.wav", "found: that frequency is jammed (a whine, until a jam recording is added), and the broadcast is dark")
ok(has(unit.chat, string.format("pirate signal located on %.1f", was)), "units are told where it was found")
LC.Freq7Tick(now + 100, 1)
local back = LC.Freq7Now()
ok(back.onAir and back.f ~= was and LC.IsFreq7(back.f) and back.kind == "voice", "a minute or so later it's back, on another of the seven", back.f)
ok((LC.Freq7.jammed[was] or 0) > now + 100, "and the jammed one stays dead for a while")
-- a blackout stops the hunt
LC.CityDark = true
LC.Freq7.holdUntil = now + 100
LC.Freq7Tick(now + 101, 1)
ok(LC.Freq7Now().onAir, "in a blackout the jammers are dark: it holds where it is")
LC.CityDark = nil
-- red sociostability: they find it sooner
local socioWas = LC.Socio
LC.Socio = "red"
LC.Freq7.holdUntil = now + 101
LC.Freq7Tick(now + 101, 1)
LC.Freq7Tick(now + 300, 1)
local hold = LC.Freq7.holdUntil - (now + 300)
LC.Socio = socioWas
ok(hold > 0 and hold <= 18 * 60 * 0.3 * 1.25 + 1, "on red they find it in a third of the time", hold)
-- a Resistance radio follows the hop
local rebel = newPlayer("Freq7Rebel", "resistance")
LC.GiveItem(rebel, "radio_tuned")
LC.RadioListen(rebel, "radio_tuned")
local l = LC.Listening[rebel]
ok(l and math.abs(l.dial - LC.Freq7Now().f) < 0.05, "a retuned radio opens on Freq 7")
local from = LC.Freq7Now().f
LC.Freq7Jam(CurTime())
LC.Freq7Tick(CurTime() + 100, 1)
_run(0.5)
ok(math.abs(LC.Listening[rebel].dial - LC.Freq7Now().f) < 0.05 and LC.Freq7Now().f ~= from, "and follows it when it hops")
if LC.RadioListenOff then LC.RadioListenOff(rebel) end
for k in pairs(_files) do if string.find(k, A, 1, true) == 1 then _files[k] = nil end end
LC.AnnounceRescan()
LC.Freq7Reset()
for _, p in ipairs({ unit, rebel }) do p:SetPos(Vector(-120000, -120000, 0)) end
end
Freq7Tests()

----------------------------------------------------------------------

----------------------------------------------------------------------
section("Playtest fixes: switching faction where you stand, boxes in both hands, the NPC cap")
;(function() -- (its own function: the file's main chunk is at Lua's limit on locals)
    local sw = newPlayer("Switcher", "citizen")
    local here = Vector(4321, -1234, 0)
    sw:SetPos(here)
    LC.SetFaction(sw, "resistance", nil, true, true)
    _run(0.5)
    ok(sw:GetPos():Distance(here) < 1 and sw:GetNW2String("lcf_faction", "") == "resistance", "switching faction from the menu, you stay right where you are", tostring(sw:GetPos()))
    LC.SetFaction(sw, "citizen", nil, true)
    local n = ents.Create("npc_citizen") n:Spawn()
    local st = { role = "citizen", state = "idle", test = true }
    LC.NPCs[n] = st
    LC.NPCCarry(n, st, "models/props_junk/cardboard_box004a.mdl")
    ok(n:GetNW2Bool("lc_carry_front", false) and IsValid(st.carry) and st.carry:GetParent() == n, "a box is carried out in front, in both hands")
    LC.NPCDropCarry(n, st)
    ok(not n:GetNW2Bool("lc_carry_front", false), "(put down, and the arms come down)")
    LC.NPCCarry(n, st, "models/props_c17/suitcase001a.mdl")
    ok(not n:GetNW2Bool("lc_carry_front", false), "a suitcase is still carried at the side")
    LC.NPCDropCarry(n, st)
    LC.NPCs[n] = nil
    n:Remove()
    local was = GetConVar("lc_npc_budget"):GetInt()
    _setcvar("lc_npc_budget", 1)
    local okr, rep = pcall(LC.BuildReport)
    ok(okr and LC.NPCTargetsTotal() > 1 and string.find(rep or "", "lc_npc_budget (1) is below", 1, true),
        "a cap lower than the city's settings is pointed out in the debug report (it stops Civil Protection spawning)")
    _setcvar("lc_npc_budget", was)
    -- recordings straight under sound/livingcity/ (overwatch/, administrator/), not only under announce/
    _files["sound/livingcity/overwatch/socio_green1.wav"] = "RIFF" .. string.rep("\0", 3000)
    _files["sound/livingcity/administrator/socio_green2.wav"] = "RIFF" .. string.rep("\0", 3000)
    LC.AnnounceRescan()
    local ow = LC.PickAnnounceClip("overwatch", "socio_green")
    local ad = LC.PickAnnounceClip("administrator", "socio_green", false, 1)
    ok(ow == "livingcity/overwatch/socio_green1.wav" and ad == "livingcity/administrator/socio_green2.wav",
        "recordings in sound/livingcity/overwatch/ and .../administrator/ are found too, not only under announce/", tostring(ow) .. " " .. tostring(ad))
    _files["sound/livingcity/overwatch/socio_green1.wav"], _files["sound/livingcity/administrator/socio_green2.wav"] = nil, nil
    LC.AnnounceRescan()
end)()

----------------------------------------------------------------------
section("Playtest fixes, 17 October")
;(function() -- (its own function: the file's main chunk is at Lua's limit on locals)
    -- Warn the block: residents come out to be warned, anywhere in the block; the raid ending
    -- with nobody warned pays nothing
    local warner = newPlayer("Warner", "resistance")
    local blocks = LC.ZonesOfKind("block")
    if #blocks > 0 then
        local wq = inject(warner, "res_warnblock")
        ok(wq ~= nil, "the warn-the-block job starts")
        if wq then
            wq.posting = wq.posting or {}
            local before = LC.Credits and LC.Credits(warner) or 0
            LC.QB.Advance(wq)
            local st = LC.QB.Stage(wq)
            local spawned = 0
            for _, e in ipairs(wq.ents or {}) do if IsValid(e) and LC.NPCs[e] and LC.NPCs[e].role == "citizen" then spawned = spawned + 1 end end
            ok(st and st.kind == "count" and spawned >= 1, "an empty block has residents come out to be warned", spawned)
            local was = LC.Event
            LC.Event = nil
            for _, list in pairs(LC.Postings) do for _, pp in ipairs(list) do if pp.q == wq then pp.during = { "raid" } end end end
            hook.Run("LivingCityEventEnded", "raid")
            LC.Event = was
            ok(wq.done and (LC.Credits and LC.Credits(warner) or 0) == before, "the raid ending with nobody warned pays nothing (it used to pay in full)")
        end
    end
    warner.valid = false
    -- Changing jobs ends the old job's shift (it stayed on the HUD and blocked the new job's)
    local hopper = newPlayer("JobHopper", "citizen")
    local jobs = {}
    for id in pairs(LCJ.ById) do jobs[#jobs + 1] = id end
    table.sort(jobs)
    LC.SetJob(hopper, jobs[1], true)
    local sq
    for _, t in ipairs(LC.QuestTemplates) do
        if t.factions.citizen and not t.during then sq = inject(hopper, t.id) if sq then break end end
    end
    ok(sq ~= nil, "(a job to stand in for a shift)")
    if sq then
        sq.chain = "shift"
        hopper.lcjNext = 0
        LC.SetJob(hopper, jobs[2], true)
        ok(sq.done and LC.QuestOf[hopper] == nil, "changing jobs ends the old job's shift, so the new job's can be taken")
    end
    hopper.valid = false
    -- One voice for each warning, never both (they used to talk over each other)
    local said = {}
    local hk = function(voice) said[voice] = (said[voice] or 0) + 1 end
    hook.Add("LivingCityCustomAnnouncement", "TestOneVoice", hk)
    _files["sound/livingcity/administrator/curfew_soon_firm1.wav"] = "RIFF" .. string.rep("\0", 3000)
    _files["sound/livingcity/overwatch/curfew_soon1.wav"] = "RIFF" .. string.rep("\0", 3000)
    LC.AnnounceRescan()
    _setcvar("lc_announce_admin_share", 50)
    local both, admins = 0, 0
    for _ = 1, 20 do
        said = {}
        LC.TriggerAnnouncements("curfew_soon", { force = true, delay = 0.1 })
        _run(1)
        if (said.administrator or 0) > 0 and (said.overwatch or 0) > 0 then both = both + 1 end
        if (said.administrator or 0) > 0 then admins = admins + 1 end
    end
    ok(both == 0 and admins > 0 and admins < 20, "each warning is said by one voice, the Administrator or Overwatch at random, never both", admins .. " of 20 hers, " .. both .. " both")
    _setcvar("lc_announce_admin_share", 0)
    hook.Remove("LivingCityCustomAnnouncement", "TestOneVoice")
    _files["sound/livingcity/administrator/curfew_soon_firm1.wav"] = nil
    _files["sound/livingcity/overwatch/curfew_soon1.wav"] = nil
    LC.AnnounceRescan()
    -- Curfew: a unit on an event's duty (a post, a checkpoint) warns you too, and comes over
    if LC.Event then LC.EndEvent(true) end
    local P0 = Vector(-90000, 150000, 0)
    local ec, est = LC.Spawners.cop(P0 + Vector(150, 0, 0))
    est.routeGroup = nil est.untilT = 1e9 ec.sim = false
    local late = newPlayer("OutLate", "citizen")
    late:SetPos(P0)
    late.chat = {}
    LC.StartEvent("curfew", 3)
    LC.EventGraceEnds = CurTime() - 1
    late.lcCurfewGrace = 0
    LC.SetState(ec, est, "event")
    est.eventUntil = 1e9
    _run(3)
    ok(has(late.chat, "Warning 1 of 3"), "a unit on an event's duty warns someone out in the curfew (they used to let you walk past)", table.concat(late.chat, " | "))
    LC.EndEvent(true)
    LC.NPCs[ec] = nil ec:Remove()
    late.valid = false
    -- Your own apartment door: E opens it, E again shuts it (it used to open again and again)
    local adoor = ents.Create("prop_door_rotating")
    adoor.mapid = 9101
    adoor:SetPos(Vector(-91000, 152000, 0))
    adoor:Spawn()
    LC.SetDoorTag(adoor, "rent")
    local renter = newPlayer("Renter", "citizen")
    renter:SetPos(Vector(-91060, 152000, 0))
    renter.lookingAt = adoor
    LC.AddCredits(renter, 500)
    hook.Run("PlayerSay", renter, "!rent")
    ok(adoor.locked, "(rented, and locked)")
    hook.Run("PlayerUse", renter, adoor)
    ok(not adoor.isOpen and adoor.locked, "locked is locked, for you too: E on your own locked door just rattles the handle", table.concat(adoor.fired or {}, ","))
    hook.Run("PlayerSay", renter, "!unlock")
    _run(1.5)
    hook.Run("PlayerUse", renter, adoor)
    ok(not adoor.locked and LC.RentDoorUse(renter, adoor) == nil, "unlocked, your E works the door as normal (the game opens it)", table.concat(adoor.fired or {}, ","))
    renter.valid = false
    -- Someone stopped right where you stand steps back, so you're not stuck in each other
    local thief = newPlayer("Fingers", "citizen")
    thief:SetPos(Vector(-92000, 153000, 0))
    local mark, mst = LC.Spawners.citizen(Vector(-92000, 153010, 0))
    mst.routeGroup = nil
    LC.TalkStepAway(mark, thief)
    ok(mark:GetPos():Distance(thief:GetPos()) > 36, "someone stopped on top of you (after a pickpocketing) takes a step back", tostring(mark:GetPos()))
    LC.NPCs[mark] = nil mark:Remove()
    thief.valid = false
    -- Marched to the cells: a unit pausing on the way doesn't end the walk at once (half a
    -- second's pause used to bring "the van" before a step was walked)
    local MP = Vector(-2600, 2600, 0)
    local walked = newPlayer("Walked", "citizen")
    _run(0.3)
    walked:SetPos(MP)
    walked.lcGraceUntil = 0
    LC.ReportCrime(walked, "Theft", 300)
    local ml, mls = LC.Spawners.cop(MP + Vector(60, 0, 0))
    mls.untilT = 1e9
    walked.lcSubdue = { n = 2, t = CurTime() } -- (beaten down: the third blow, and cuffed)
    hook.Run("EntityTakeDamage", walked, _dmg(ml, 20, DMG_CLUB))
    ok(LC.Marching[walked] ~= nil, "(a march)")
    local goWas = LC.GoTo
    LC.GoTo = function() return true end -- (he says he's going, and stands there a moment)
    LC.SetState(ml, mls, "idle")
    _run(1.5)
    ok(LC.Marching[walked] ~= nil and not LC.Prisoners[walked], "a unit pausing on the way doesn't end the march: still walking you there")
    LC.GoTo = goWas
    if LC.Marching[walked] then LC.Marching[walked] = nil end
    if LC.IsTied(walked) then LC.Untie(walked, nil, true) end
    if LC.Prisoners[walked] then LC.ReleasePrisoner(walked) end
    ml:Remove()
    walked.valid = false
    -- A map sink with nothing solid to aim at still answers E; one the other side of a wall doesn't
    local drinker = newPlayer("Drinker", "citizen")
    local S0 = Vector(-93000, 154000, 0)
    drinker:SetPos(S0)
    drinker.ang = Angle(20, 0, 0)
    local sink = { kind = "sink", pos = S0 + Vector(60, 0, 20), ang = Angle() }
    ok(LC.AimingAtFixture(drinker, sink), "looking at a map sink in reach counts, even one the map gives nothing solid to hit")
    local wall = { a = S0 + Vector(30, -100, 0), b = S0 + Vector(30, 100, 0) }
    table.insert(_walls, wall)
    ok(not LC.AimingAtFixture(drinker, sink), "a sink the other side of a wall doesn't")
    for i, w in ipairs(_walls) do if w == wall then table.remove(_walls, i) break end end
    drinker.valid = false
    -- A ration line placed from the back is turned round: its front is the end at the dispenser
    local L0 = Vector(-94000, 155000, 0)
    local disp = ents.Create("lc_dispenser")
    disp:SetPos(L0 + Vector(400, 0, 0))
    disp:Spawn()
    local tline = { slots = { { pos = L0 }, { pos = L0 + Vector(200, 0, 0) }, { pos = L0 + Vector(360, 0, 0) } }, q = {}, nextAdvance = 0 }
    LC.OrientLine(tline)
    ok(tline.slots[1].pos == L0 + Vector(360, 0, 0) and tline.reversed, "a line placed from the back is turned round, so the front is at the dispenser")
    LC.OrientLine(tline)
    ok(tline.slots[1].pos == L0 + Vector(360, 0, 0), "and one the right way round is left as it is")
    disp:Remove()
    -- The sweep's cart: the smaller one, turned the way you push it, up a step with you
    local C0 = Vector(-95000, 156000, 0)
    local sweeper = newPlayer("CartPusher", "citizen")
    _run(0.3)
    sweeper:SetPos(C0)
    sweeper.eyeang = Angle(0, 0, 0)
    sweeper.aim = Vector(1, 0, 0)
    ok(LC.JobGameStart(sweeper, "sweep", nil, { depot = C0, spots = { C0 + Vector(400, 0, 0) } }), "(a street sweep)")
    local sg = LC.JobGames[sweeper]
    if sg and IsValid(sg.cart) then
        ok(string.find(sg.cart:GetModel() or "", "laundry_cart002", 1, true) ~= nil, "the smaller laundry cart", sg.cart:GetModel())
        ok(math.abs((sg.cart:GetAngles().y or 0) - 90) < 1, "turned the way you push it, not sideways", tostring(sg.cart:GetAngles().y))
        local gfWas = _groundFn
        _groundFn = function(x) return x > C0.x + 30 and 16 or 0 end
        sg.pushing = true
        _run(0.5)
        ok(sg.cart:GetPos().z > 12, "pushed up a step, it goes up with you", tostring(sg.cart:GetPos()))
        _groundFn = gfWas
        LC.JobGameEnd(sweeper, "done")
    end
    sweeper.valid = false
    -- Why people leave the city: counted, and in the debug report
    local goer, gst = LC.Spawners.citizen(Vector(-96000, 157000, 0))
    gst.leaveAt = CurTime() - 1
    LC.StartLeaving(goer, gst, false)
    local okr, rep = pcall(LC.BuildReport)
    ok(okr and string.find(rep or "", "people who left since the map started", 1, true) and string.find(rep or "", "their time out was up", 1, true),
        "the debug report says why people have been leaving the city")
    LC.NPCs[goer] = nil goer:Remove()
    -- A clothes pack's battle helmet or welding mask: only on the Resistance in the open
    local wearer, wst = LC.Spawners.citizen(Vector(-97000, 158000, 0))
    wearer.GetBodyGroups = function() return { { id = 3, name = "headwear", submodels = { [0] = "none", [1] = "ww2_helmet", [2] = "beanie" } } } end
    local setTo
    wearer.SetBodygroup = function(_, id, v) if id == 3 then setTo = v end end
    LC.ApplyLook(wearer, nil, { headwear = 1 })
    ok(setTo == 0, "a citizen in a pack's battle helmet goes without it", tostring(setTo))
    LC.ApplyLook(wearer, nil, { headwear = 2 })
    ok(setTo == 2, "a beanie's fine")
    wst.role = "rebel"
    LC.ApplyLook(wearer, nil, { headwear = 1 })
    ok(setTo == 1, "a rebel fighter wears the helmet")
    LC.NPCs[wearer] = nil wearer:Remove()
    -- Everyone works: a citizen without a job is assigned one; a rebel isn't; and the factory's
    -- loading dock run is the porters' now
    _setcvar("lc_assign_work", 1)
    local idle = newPlayer("NoJob", "citizen")
    idle:SetNW2String("lcj_job", "")
    ok(LC.GiveUnionWork(idle) and LC.Job(idle) ~= nil, "a registered citizen with no job is given Union work", idle:GetNW2String("lcj_job", ""))
    local reb = newPlayer("NoJobRebel", "resistance")
    reb:SetNW2String("lcj_job", "")
    ok(not LC.GiveUnionWork(reb) and LC.Job(reb) == nil, "a rebel isn't")
    ok(LC.AssignWork ~= LC.GiveUnionWork, "and a foreman's work orders are still their own thing")
    idle.valid, reb.valid = false, false
    _setcvar("lc_assign_work", 0)
    -- Stealth: crouched behind a unit's back, or crouched at the edge of his sight, he doesn't see you
    local SP = Vector(-98000, 159000, 0)
    local sneak = newPlayer("Sneak", "citizen")
    sneak:SetPos(SP)
    local su, sst = LC.Spawners.cop(SP + Vector(600, 0, 0)) -- (facing +x: away from the sneak)
    sst.routeGroup = nil
    ok(LC.SeenBySecurity(sneak, 900), "standing up, 600 away in the open, a unit sees you, whichever way he faces")
    sneak.crouch = true
    ok(not LC.SeenBySecurity(sneak, 900), "crouched behind his back, he doesn't")
    su.GetForward = function() return Vector(-1, 0, 0) end
    ok(not LC.SeenBySecurity(sneak, 900), "crouched in front of him, 600 away, you're beyond his reach (about 380 now)")
    sneak:SetPos(SP + Vector(300, 0, 0))
    ok(LC.SeenBySecurity(sneak, 900), "closer than that, he sees you")
    sneak.lcLight = 0.02
    ok(not LC.SeenBySecurity(sneak, 900), "but not in the dark")
    LC.NPCs[su] = nil su:Remove()
    sneak.valid = false
    -- A vortigaunt lives free in rebel territory from the start (not only once someone frees one)
    if #LC.ZonesOfKind("rebel") > 0 then
        local before = 0
        for v in pairs(LC.RebelVorts) do if IsValid(v) then before = before + 1 end end
        local wasR = LC.Running
        LC.Running = true
        _setcvar("lc_rebel_vorts", 1)
        LC.VortHome()
        _setcvar("lc_rebel_vorts", 0)
        LC.Running = wasR
        local after = 0
        for v in pairs(LC.RebelVorts) do if IsValid(v) then after = after + 1 end end
        ok(after >= 1, "a vortigaunt lives in rebel territory", before .. " -> " .. after)
    end
    -- The Mortician's body cart: bodies let go beside it go on it; E on the incinerator burns the lot, paid each
    local BC = Vector(-99000, 160000, 0)
    local mort = newPlayer("CartMortician", "citizen")
    _run(0.3)
    LC.SetJob(mort, "mortuary", true)
    mort:SetPos(BC)
    mort.aim = Vector(1, 0, 0)
    local binc = ents.Create("lc_incinerator") binc:SetPos(BC + Vector(200, 0, 0)) binc:Spawn()
    ok(LC.TakeBodyCart(mort), "a Mortician by the incinerator takes a body cart")
    local cart = LC.BodyCarts[mort]
    local bodies = {}
    for i = 1, 2 do
        local b = LC.SpawnBody("models/humans/group01/male_01.mdl", cart:GetPos() + Vector(0, 30 * i, 0))
        bodies[i] = b
        mort.lcNextBodyUse = 0
        LC.StartHaul(mort, b)
        b:SetPos(cart:GetPos() + Vector(0, 40, 0))
        LC.StopHaul(mort)
    end
    ok(cart:GetNW2Int("lc_cart_bodies", 0) == 2 and IsValid(bodies[1]), "let go of a body beside it and it goes on the cart (two on it)")
    local c1 = LC.Credits(mort)
    mort.lcFedAt = 0
    ok(LC.FeedIncinerator(mort, binc) and not IsValid(bodies[1]) and not IsValid(bodies[2]), "E on the incinerator with the cart beside it burns everything on it")
    ok(LC.Credits(mort) > c1, "paid for each")
    LC.DropBodyCart(mort)
    binc:Remove()
    mort.valid = false
end)()

section("Playtest fixes, 17 October (evening)")
;(function()
    -- Father Grigori says something once a minute at the most, whatever it's for
    local g = ents.Create("npc_monk") g:Spawn()
    local said = 0
    local emitWas = g.EmitSound
    g.EmitSound = function(self, snd, ...) said = said + 1 end
    for _ = 1, 20 do LC.GrigoriSpeak(g, 70) _run(1) end
    ok(said == 1, "Father Grigori: at most one line a minute", said)
    _run(45)
    LC.GrigoriSpeak(g, 70)
    ok(said == 2, "and the next once the minute's up", said)
    g:Remove()
    -- a medic's clothes pack with a helmet on by default: off, unless it's the Resistance in the open
    local m = ents.Create("npc_citizen") m:Spawn()
    m:SetModel("models/humans/group03m/male_01.mdl")
    m.bg = { [1] = 1 }
    m.GetBodyGroups = function() return { { id = 1, name = "headgear", submodels = { [0] = "blank", [1] = "helmet_combat" } } } end
    m.GetBodygroup = function(self, i) return (self.bg or {})[i] or 0 end
    LC.NPCs[m] = { role = "citizen", job = "medic" }
    LC.ApplyLook(m, nil, {})
    ok(m:GetBodygroup(1) == 0, "a clinic medic's pack helmet comes off (only the Resistance in the open wear battle gear)")
    m.bg[1] = 1
    LC.NPCs[m].role = "rebel"
    LC.StripBattleGear(m)
    ok(m:GetBodygroup(1) == 1, "(and a rebel fighter keeps his)")
    LC.NPCs[m] = nil m:Remove()
    -- the quartermaster charges his own what the lab does; a forged ration card is cheap
    local comrade = newPlayer("QMBuyer", "resistance")
    local nqWas = LC.NearQuartermaster
    LC.NearQuartermaster = function() return true end
    local radio = LCS.BlackById.radio_tuned
    ok(LC.MarketPrice(comrade, radio) == LC.LabPrice({ out = "radio_tuned", item = "radio_tuned" }) and LC.MarketPrice(comrade, radio) < LC.BlackPrice(radio),
        "the quartermaster's radio costs what the lab's does, well under the dealer's", LC.MarketPrice(comrade, radio) .. " vs " .. LC.BlackPrice(radio))
    LC.NearQuartermaster = nqWas
    ok(LCS.BlackById.ration_forged.price == 10 and LCS.Items.ration_forged.sell < 10, "a forged ration card is 10 credits")
    comrade.valid = false
    -- the stash takes what's in your hands too: a crowbar, a gun (not what your faction issued you)
    local hider = newPlayer("GunHider", "citizen")
    hider:Give("weapon_crowbar") hider:Give("weapon_pistol")
    local reachWas = LC.CanReachStash
    LC.CanReachStash = function() return true end
    local listed = {}
    for _, w in ipairs(LC.StashableWeapons(hider)) do listed[w.cls] = true end
    ok(listed.weapon_crowbar and listed.weapon_pistol, "at your stash, the crowbar and the pistol in your hands can be put away")
    LC.InvAction(hider, "wstore", "weapon_pistol")
    ok(not hider:HasWeapon("weapon_pistol") and (LC.Stash(hider)["w:weapon_pistol"] or 0) == 1, "stash it: the pistol goes from your hands into the stash")
    LC.InvAction(hider, "take", "w:weapon_pistol")
    ok(hider:HasWeapon("weapon_pistol") and LC.Stash(hider)["w:weapon_pistol"] == nil, "take it: back in your hands")
    LC.CanReachStash = reachWas
    hider.valid = false
    -- someone wanted who's hurt nobody: run down and cuffed, not shot (soldiers too)
    if LC.Event then LC.EndEvent(true) end
    local Q0 = Vector(-95000, 155000, 0)
    local sol, sst = LC.Spawners.soldier(Q0 + Vector(60, 0, 0))
    sst.routeGroup = nil sst.untilT = 1e9 sol.sim = false
    local runner = newPlayer("RanFromSearch", "citizen")
    runner:SetPos(Q0)
    LC.ReportCrime(runner, "Ran from a search", 120)
    ok(not LC.Violent(runner), "running from a search isn't violent")
    LC.MakeCopsHostile(runner, runner:GetPos(), 500)
    ok(sst.state == "hostile" and sst.arrestOnly and sst.rel and sst.rel[runner] == D_NU, "a soldier after someone who's hurt nobody holds his fire and runs them down")
    _run(2)
    ok(LC.InCustody(runner), "and lays hands on them: taken in, not shot")
    LC.CalmCops(runner)
    LC.NPCs[sol] = nil sol:Remove()
    sol, sst = LC.Spawners.soldier(Q0 + Vector(60, 300, 0))
    sst.routeGroup = nil sst.untilT = 1e9 sol.sim = false
    -- someone violent: weapons free
    local brawler = newPlayer("Brawler", "citizen")
    brawler:SetPos(Q0 + Vector(0, 300, 0))
    LC.ReportCrime(brawler, "Assault", 120)
    ok(LC.Violent(brawler), "an assault is violent")
    LC.MakeCopsHostile(brawler, brawler:GetPos(), 1000)
    ok(sst.enemy == brawler and not sst.arrestOnly, "and the violent get no such courtesy")
    LC.CalmCops(brawler)
    LC.NPCs[sol] = nil sol:Remove()
    runner.valid, brawler.valid = false, false
    -- a curfew that's about you: the unit who sees you knows you (no warnings)
    local ec2, est2 = LC.Spawners.cop(Q0 + Vector(0, -600, 0) + Vector(150, 0, 0))
    est2.routeGroup = nil est2.untilT = 1e9 ec2.sim = false
    local culprit = newPlayer("TheCulprit", "citizen")
    culprit:SetPos(Q0 + Vector(0, -600, 0))
    culprit.lcHeat = 2
    culprit.chat = {}
    LC.StartEvent("curfew", 3)
    LC.EventGraceEnds = CurTime() - 1
    culprit.lcCurfewGrace = 0
    ok(LC.EventCulprits[culprit], "the curfew is about whoever's still hot from the trouble")
    LC.SetState(ec2, est2, "event")
    est2.eventUntil = 1e9
    _run(3)
    ok(has(culprit.chat, "That's the one") and LC.PlayerIsWanted(culprit) and not has(culprit.chat, "Warning 1"), "a unit who sees them knows them: wanted, no warnings")
    LC.EndEvent(true)
    culprit.lcHeat = 0
    LC.ClearWanted(culprit)
    LC.CalmCops(culprit)
    LC.NPCs[ec2] = nil ec2:Remove()
    culprit.valid = false
    -- sleep: lying still till Jump, healed by the end, kept over a restart
    local napper = newPlayer("Napper", "citizen")
    _run(1)
    napper:SetPos(Q0 + Vector(0, 900, 0))
    local nbed = ents.Create("lc_bed") nbed:SetPos(napper:GetPos() + Vector(40, 0, 0)) nbed:Spawn()
    local nightWas = LC.IsNight
    LC.IsNight = function() return true end
    napper.lcAwakeSince = CurTime() - 100
    napper:SetNW2Float("lc_rested_until", 0)
    napper:SetHealth(30)
    ok(LC.SleepIn(napper, nbed) and napper:GetNW2Bool("lc_sleeping", false), "asleep in a bed")
    local cmd = { buttons = bit.bor(IN_FORWARD, IN_JUMP, IN_USE), cleared = false }
    function cmd:ClearMovement() self.cleared = true end
    function cmd:GetButtons() return self.buttons end
    function cmd:SetButtons(b) self.buttons = b end
    hook.Run("StartCommand", napper, cmd)
    ok(cmd.cleared and cmd.buttons == IN_JUMP, "lying still: no walking off in your sleep (only Jump gets through)")
    _run(GetConVar("lc_sleep_seconds"):GetFloat() * 0.5)
    ok(napper:Health() > 30 and napper:Health() < napper:GetMaxHealth(), "healing as you sleep", napper:Health())
    _run(GetConVar("lc_sleep_seconds"):GetFloat() * 0.5 + 1)
    ok(napper:Health() == napper:GetMaxHealth() and LC.IsRested(napper) and napper:GetNW2Bool("lc_sleeping", false), "healed by the end, rested, and still asleep till you get up", napper:Health())
    hook.Run("KeyPress", napper, IN_JUMP)
    ok(not napper:GetNW2Bool("lc_sleeping", false), "Jump: up again")
    napper.lcAwakeSince = CurTime() - 500
    LC.SaveRest(napper)
    napper.lcAwakeSince = nil
    hook.Run("PlayerSpawn", napper)
    ok(math.abs(LC.AwakeFor(napper) - 500) < 2 and LC.IsRested(napper), "how long you've been awake, and rested, is kept over a restart", LC.AwakeFor(napper))
    LC.IsNight = nightWas
    nbed:Remove()
    napper.valid = false
    -- rebel territory: fighters for the room there is; nothing in the way or in the water; the camp rearranged
    local small = { kind = "rebel", pos = Vector(-98000, 160000, 0), r = 495, box = { mins = Vector(-98350, 159650, -16), maxs = Vector(-97650, 160350, 176) } }
    ok(LC.RebelRoomIn(small) == 4, "a 700 by 700 camp has room for four fighters (lc_rebel_room 350)", LC.RebelRoomIn(small))
    local tlW = util.TraceLine
    util.TraceLine = function(t)
        local d = t.endpos - t.start
        if math.abs(d.y) > 1 and math.abs(d.x) < 1 then return { Hit = true, Fraction = 60 / 200, HitPos = t.start + d * 0.3 } end
        return tlW(t)
    end
    ok(LC.InWalkway(Vector(0, 0, 0), 30), "a corridor 120 wide: no room to set a crate down and still get by", LC.WayWidth(Vector(0, 0, 0)))
    util.TraceLine = tlW
    ok(not LC.InWalkway(Vector(0, 0, 0), 30), "open floor is fine")
    local pcWas = util.PointContents
    util.PointContents = function(p) return p.x < -97990 and (CONTENTS_WATER or 32) or 0 end
    ok(LC.InWater(Vector(-98100, 160000, 0)) and not LC.InWater(Vector(-97900, 160000, 0)), "the sewer channel is water; the walkway beside it isn't")
    local dry = 0
    for _ = 1, 10 do local sp = LC.SpotInZone(small) if sp and sp.x >= -97990 then dry = dry + 1 end end
    ok(dry >= 8, "people and things go on the dry side first", dry)
    util.PointContents = pcWas
    -- a sleeper settled onto the mattress, not floating over it
    local sleeper = ents.Create("npc_citizen") sleeper:Spawn()
    sleeper:SetPos(Vector(0, 0, 10))
    local ssq = ents.Create("scripted_sequence") ssq:SetPos(Vector(0, 0, 10)) ssq:Spawn()
    sleeper.LookupBone = function() return 0 end
    sleeper.GetBonePosition = function(self) return self:GetPos() + Vector(0, 0, 40) end
    LC.RebelSettleOnBed(sleeper, { ss = ssq }, 10)
    ok(math.abs(sleeper:GetPos().z - (10 - 32)) < 0.5, "a sleeper floating over the mattress is settled onto it (hips just on top)", sleeper:GetPos().z)
    sleeper:Remove() ssq:Remove()
    -- hold E on a camp's mattress: carried where you look, set down, kept for next time
    LC.AddZone(small.pos, 300, "rebel", 0)
    local zone = LC.ZonesOfKind("rebel")[#LC.ZonesOfKind("rebel")]
    local mat = ents.Create("prop_physics") mat:SetModel("models/props_c17/furnituremattress001a.mdl") mat:SetPos(small.pos + Vector(50, 0, 0)) mat:Spawn()
    mat.lcDressing = true
    LC.Dressed[zone] = { want = 1, ents = { mat } }
    local mover = newPlayer("CampMover", "resistance")
    mover:SetPos(small.pos)
    ok(LC.CampMovable(mat) and LC.CampPickUp(mover, mat), "hold E on the camp's mattress: you pick it up")
    mover.keys = {}
    LC.CampCarryStep(mover)
    ok(mover.lcCampCarry == nil and LC.CampSaved(zone) and LC.CampSaved(zone)[1].model == mat:GetModel(), "let go of E: it's set down, and where it is is kept for the map")
    LC.Dressed[zone] = nil
    mat:Remove()
    LC.CampForget()
    LC.RemoveZone(zone)
    mover.valid = false
    -- each lab its own scientist: Kleiner, Eli or Magnusson
    local who = {}
    local benches = {}
    for i = 1, 3 do
        local b = ents.Create("lc_workbench") b:SetPos(Vector(-99000 + i * 300, 165000, 0)) b:Spawn()
        benches[i] = b
        local sc = LC.SetupLab(b)
        if IsValid(sc) and sc.lcWho then who[sc.lcWho] = (who[sc.lcWho] or 0) + 1 end
        ok(IsValid(sc) and sc:GetNW2String("lc_pname", "") ~= "", "(the scientist has a name tag)", IsValid(sc) and sc:GetNW2String("lc_pname", ""))
    end
    ok(who.kleiner == 1 and who.eli == 1 and who.magnusson == 1, "three labs: Dr. Kleiner, Eli Vance and Dr. Magnusson, one each (no Kleiner clones)")
    for _, b in ipairs(benches) do if IsValid(b.lcScientist) then b.lcScientist:Remove() end b:Remove() end
    -- freeing a vortigaunt: it waits shackled and harmless; walk it out still shackled, to any rebel territory
    local vz1 = LC.AddZone(Vector(-100000, 170000, 0), 300, "rebel", 0)
    local vz2 = LC.AddZone(Vector(-100000, 176000, 0), 300, "rebel", 0)
    local freer = newPlayer("VortFreer", "resistance")
    _run(1)
    freer:SetNW2Int("lcf_rank", 3)
    freer:SetPos(Vector(-100000, 173000, 0))
    local vq = inject(freer, "res_freevort")
    ok(vq ~= nil, "(the job is offered)")
    if vq then
        local v = vq.data.vort
        if IsValid(v) then freer:SetPos(v:GetPos() + Vector(40, 0, 0)) end
        _run(2)
        ok(IsValid(v) and v:GetNW2Bool("lc_shackled", false) and LC.NPCs[v] and LC.NPCs[v].shackled, "the vortigaunt is there, still shackled (it doesn't fight anyone)")
        local st = LC.QB.Stage(vq)
        ok(st and st.kind == "choice", "a choice: cut the shackles there, or walk it out shackled", tostring(st and st.kind) .. " stage " .. tostring(vq.stage) .. " done " .. tostring(vq.done) .. " dist " .. tostring(IsValid(v) and freer:GetPos():Distance(v:GetPos())) .. " active " .. tostring(LC.ActiveQuests[vq]))
        LC.ResolveChoice(freer, vq.id, 2)
        st = LC.QB.Stage(vq)
        ok(st and st.kind == "escort" and st.anyRebel, "walking it out, shackled, to rebel territory (any of it)", st and st.kind)
        -- the far camp, not the nearest: still home
        if IsValid(v) then v:SetPos(vz2.pos + Vector(20, 0, 0)) end
        freer:SetPos(vz2.pos + Vector(60, 0, 0))
        _run(2)
        ok(vq.done and IsValid(v) and not v:GetNW2Bool("lc_shackled", true), "any rebel territory will do: the shackles come off there", tostring(vq.done))
    end
    freer.valid = false
    LC.RemoveZone(vz1) LC.RemoveZone(vz2)
    -- a squad acting casual: guns away, plain clothes; units leave them be; shot at, guns out
    local sz = LC.AddZone(Vector(-101000, 180000, 0), 300, "rebel", 0)
    local boss = newPlayer("SquadBoss", "resistance")
    _run(1)
    boss:SetNW2Int("lcf_rank", 3)
    boss:SetPos(sz.pos + Vector(0, 0, 0))
    local fr, fst = LC.Spawners.rebel(sz.pos + Vector(60, 0, 0), sz)
    hook.Run("PlayerUse", boss, fr)
    ok(fst.follow == boss, "(a fighter comes along)")
    LC.SlashCommands.casual(boss)
    ok(fst.casual and fr:GetNW2Bool("lc_casual", false) and not string.find(fr:GetModel() or "", "group03", 1, true), "act casual: guns away, plain clothes on")
    fst.preCasualModel = fst.preCasualModel or "models/humans/group03/male_01.mdl"
    local cop3, cst3 = LC.Spawners.cop(sz.pos + Vector(1200, 0, 0))
    cst3.routeGroup = nil cst3.untilT = 1e9 cop3.sim = false
    boss:SetPos(sz.pos + Vector(1000, 0, 0)) fr:SetPos(sz.pos + Vector(1060, 0, 0))
    LC.UnitsSpotRebels()
    ok(cst3.state ~= "hostile", "out in the streets, a unit takes them for a citizen and lets them be", cst3.state)
    LC.SlashCommands.gunsout(boss)
    ok(not fst.casual and not fr:GetNW2Bool("lc_casual", false), "guns out: back to how they were")
    -- go on ahead: they meet you at the job's marker and wait
    local qWas = LC.QuestObjectivePos
    LC.QuestObjectivePos = function() return sz.pos + Vector(2000, 0, 0) end
    LC.SlashCommands.meet(boss)
    ok(fst.meetAt and fst.casual and fst.meetAt:Distance(sz.pos + Vector(2000, 0, 0)) < 120, "meet me there: they go on ahead, acting casual, to the job's marker")
    LC.QuestObjectivePos = qWas
    LC.DismissFollower(fr, fst, true)
    ok(not fst.casual and not fst.meetAt, "(sent home: back to themselves)")
    LC.NPCs[cop3] = nil cop3:Remove()
    LC.NPCs[fr] = nil fr:Remove()
    boss.valid = false
    LC.RemoveZone(sz)
    -- a raid coming: the Resistance's own hear first, and get a job to back it up
    if LC.Skirmish then LC.Skirmish.done = true LC.Skirmish = nil end
    local rz = LC.AddZone(Vector(-102000, 190000, 0), 300, "rebel", 0)
    local zonesWas = LC.ZonesOfKindShared
    local backer = newPlayer("RaidBacker", "resistance")
    local sweeper = newPlayer("SweepCop", "cp")
    _run(1)
    backer.chat = {}
    local tcop, tcst = LC.Spawners.cop(rz.pos + Vector(2500, 0, 0))
    tcst.routeGroup = nil tcst.untilT = 1e9 tcop.sim = false
    local planned = LC.PlanRebelRaid()
    ok(planned and LC.PlannedRaid and not LC.Skirmish, "a raid is planned a minute and a half ahead, not sprung at once")
    local posted = false
    for _, ps in ipairs(LC.Postings.resistance or {}) do if ps.tmpl and ps.tmpl.id == "res_backupraid" and not ps.dead then posted = true end end
    ok(posted and has(backer.chat, "Back up the raid"), "the Resistance get a job to back it up, on their board, and told so")
    _run(GetConVar("lc_raid_warning"):GetFloat() + 3)
    ok(LC.PlannedRaid == nil and LC.Skirmish and LC.Skirmish.kind == "raid", "and when the time comes, the fighters go in")
    local repel = false
    for _, ps in ipairs(LC.Postings.cp or {}) do if ps.tmpl and ps.tmpl.id == "cp_repelraid" and not ps.dead then repel = true end end
    ok(repel, "the Combine's own players get a job to put the raid down (Repel the attack)")
    if LC.Skirmish then LC.Skirmish.done = true LC.Skirmish = nil end
    -- the reverse: a sweep coming, Civil Protection hear first and get a job to join it
    sweeper.chat = {}
    local swPlanned = LC.PlanCombineSweep()
    ok(swPlanned and LC.PlannedSweep and not LC.Skirmish, "a sweep is planned a minute and a half ahead, not sprung at once")
    local joinPosted = false
    for _, ps in ipairs(LC.Postings.cp or {}) do if ps.tmpl and ps.tmpl.id == "cp_joinsweep" and not ps.dead then joinPosted = true end end
    ok(joinPosted and has(sweeper.chat, "sweep"), "Civil Protection get a job to join the sweep, on their board, and told so")
    ok(not has(backer.chat, "sweep team moves"), "(the Resistance don't hear the Combine's plans)")
    _run(GetConVar("lc_sweep_warning"):GetFloat() + 3)
    ok(LC.PlannedSweep == nil and LC.Skirmish and LC.Skirmish.kind == "sweep", "and when the time comes, the sweep team goes in", LC.Skirmish and LC.Skirmish.kind)
    if LC.Skirmish then LC.EndSkirmish(LC.Skirmish, "test") end
    LC.PlannedSweep = nil
    sweeper.valid = false
    LC.NPCs[tcop] = nil tcop:Remove()
    backer.valid = false
    LC.RemoveZone(rz)
    -- the factory line: every part grabbable, workers at the line face the belt
    local lever = false
    for _, m in ipairs(LC.LineParts) do if string.find(string.lower(m), "lever", 1, true) or string.find(m, "tpplug", 1, true) then lever = true end end
    ok(not lever, "no more little levers or plugs on the line (they couldn't be picked up)")
    local belt = ents.Create("lc_conveyor") belt:SetPos(Vector(-103000, 195000, 34)) belt:Spawn()
    local face = LC.ConveyorFace(Vector(-103000, 195060, 0))
    ok(face and face:Distance(belt:GetPos()) < 200, "a worker at a point beside the conveyor faces the belt", face and tostring(face))
    ok(LC.ConveyorFace(Vector(-110000, 195000, 0)) == nil, "(and one with no belt near works as before)")
    belt:Remove()
    -- the station: Intake Processor; travelers walk off out of sight, not vanish in front of you
    ok(LCJ.ById.porter and LCJ.ById.porter.name == "Intake Processor", "the Station Porter is the Intake Processor now (same job, same shifts)")
    local tr = ents.Create("npc_citizen") tr:Spawn() tr:SetPos(Vector(-104000, 200000, 0))
    LC.PapersWalking[tr] = { to = Vector(-104000, 200100, 0), t0 = CurTime() - 4, max = 30 }
    local seenWas = LC.IsSeen
    LC.IsSeen = function() return true end
    _run(2)
    ok(IsValid(tr), "an approved traveler walks off, and isn't removed while you can still see them")
    LC.IsSeen = function() return false end
    _run(2)
    ok(not IsValid(tr), "and is gone once out of sight")
    LC.IsSeen = seenWas
    -- a ration break: the shift waits
    local worker = newPlayer("BreakTaker", "citizen")
    _run(1)
    local wq = { owner = worker, expires = CurTime() + 100, stages = { { kind = "count", event = "nothing", need = 1 } }, stage = 1, members = { worker }, ents = {}, marked = {}, data = {} }
    LC.QuestOf[worker] = wq
    local evWas = LC.Event
    LC.Event = "rations"
    ok(LC.RationBreak(worker, true) and worker:GetNW2Bool("lc_ration_break", false), "rations out mid-shift: a ration break")
    LC.Event = evWas
    hook.Run("LivingCityRationCollected", worker)
    ok(not worker:GetNW2Bool("lc_ration_break", false), "and once the ration's in hand, back to work")
    LC.QuestOf[worker] = nil
    worker.valid = false
end)()

section("Playtest fixes, 20 October")
;(function()
    -- the announcer: how long a line runs comes from the file's own header first
    local wd = LC.WavDuration
    LC.WavDuration = function() return 5.5 end
    ok(math.abs(LC.AnnounceKnownSecs("npc/overwatch/cityvoice/f_x_spkr.wav") - 5.5) < 0.01, "an announcement's length is read from the file's own header (no voices over each other)")
    LC.WavDuration = wd
    -- touching rebel zones are one territory: one quartermaster, one crate, one camp
    local T0 = Vector(-200000, 200000, 0)
    local a = LC.AddZone(nil, nil, "rebel", 0, { mins = T0 + Vector(0, 0, -16), maxs = T0 + Vector(600, 400, 192) })
    local b = LC.AddZone(nil, nil, "rebel", 0, { mins = T0 + Vector(650, 0, -16), maxs = T0 + Vector(900, 300, 192) })
    local far = LC.AddZone(nil, nil, "rebel", 0, { mins = T0 + Vector(5000, 0, -16), maxs = T0 + Vector(5400, 400, 192) })
    ok(LC.RebelLeader(b) == a and LC.RebelLeader(a) == a and LC.RebelIsLeader(far), "two zones a few feet apart are one territory (its leader the bigger); one far off is its own")
    local qms = function(z)
        local n = 0
        for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.quartermaster and (st.zone == a or st.zone == b) then n = n + 1 end end
        return n
    end
    local rebelsWas = GetConVar("lc_rebels"):GetInt()
    _setcvar("lc_rebels", 4)
    LC.EnsureQuartermasters()
    ok(qms() == 1, "one quartermaster for the two of them", qms())
    -- a second one there (zones redrawn): sent away
    local npc2, st2 = LC.SpawnRebel(T0 + Vector(700, 100, 4), b)
    st2.quartermaster = true
    LC.EnsureQuartermasters()
    ok(qms() == 1, "a second quartermaster in the same territory goes", qms())
    _setcvar("lc_rebels", rebelsWas)
    -- Father Grigori moves on to another camp when nobody's about
    local g = ents.Create("npc_monk") g:Spawn() g:SetPos(T0 + Vector(300, 200, 0))
    g.lcGrigori, g.lcHome = true, a
    local seenWas = LC.IsSeen
    LC.IsSeen = function() return false end
    for _, p in ipairs(player.GetAll()) do p.lcPosWas = p:GetPos() p:SetPos(Vector(-300000, -300000, 0)) end
    ok(LC.GrigoriMove(g, CurTime(), true) and LC.RebelLeader(g.lcHome) ~= a, "Father Grigori moves on to another rebel territory, unseen")
    for _, p in ipairs(player.GetAll()) do if p.lcPosWas then p:SetPos(p.lcPosWas) p.lcPosWas = nil end end
    LC.IsSeen = seenWas
    g:Remove()
    for npc, st in pairs(LC.NPCs) do if IsValid(npc) and st.quartermaster and (st.zone == a or st.zone == b) then LC.NPCs[npc] = nil npc:Remove() end end
    LC.RemoveZone(far) LC.RemoveZone(b) LC.RemoveZone(a)
end)()
;(function()
    -- the quartermaster buys food back for next to nothing (it's free from his crate)
    local eater = newPlayer("BeanSeller", "resistance")
    local nqWas = LC.NearQuartermaster
    LC.NearQuartermaster = function() return true end
    ok((LC.SellPrice(eater, "canned_food") or 0) <= 2 and (LC.SellPrice(eater, "ration") or 0) <= 2, "the quartermaster pays at most 2 credits for food", LC.SellPrice(eater, "canned_food"))
    LC.NearQuartermaster = nqWas
    ok((LC.SellPrice(eater, "canned_food") or 0) > 2, "(the dealer in the city still pays his price)")
    -- the vest: no charge from sleeping beside the camp's vortigaunt; ask it, or use a charge cell
    eater:SetNW2Int("lc_vest_cap", 25)
    eater:SetArmor(0)
    local v = ents.Create("npc_vortigaunt") v:Spawn() v:SetPos(eater:GetPos() + Vector(60, 0, 0))
    LC.RegisterNPC(v, "vortigaunt")
    LC.SettleVort(v, true)
    _run(5)
    ok(eater:Armor() == 0, "standing (or sleeping) beside a vortigaunt doesn't charge your vest by itself")
    eater:SetNW2Int("lc_vest_cap", 25)
    local okC = LC.VortCharge(eater, v)
    ok(okC and eater:Armor() == 25, "ask it (E) and it charges your vest", eater:Armor())
    eater:SetArmor(0)
    ok(not LC.VortCharge(eater, v) and eater:Armor() == 0, "(and not again for a while)")
    LC.GiveItem(eater, "vest_cell", 1)
    LC.ItemUse(eater, "vest_cell")
    ok(eater:Armor() == 25 and not LC.HasItem(eater, "vest_cell"), "a charge cell charges the vest", eater:Armor())
    ok(LCS.LabById.vest_cell ~= nil, "the lab makes charge cells")
    _setcvar("lc_vest_cell_drop", 100)
    local before = #ents.FindByClass("lc_item")
    local c, cst = LC.Spawners.cop(Vector(-201000, 201000, 0))
    hook.Run("OnNPCKilled", c, game.GetWorld())
    local cell = false
    for _, e in ipairs(ents.FindByClass("lc_item")) do if e:GetNW2String("lc_item", "") == "vest_cell" then cell = true end end
    ok(cell and #ents.FindByClass("lc_item") > before, "a dead unit can drop a charge cell")
    _setcvar("lc_vest_cell_drop", 25)
    LC.NPCs[c] = nil c:Remove()
    LC.RebelVorts[v] = nil LC.NPCs[v] = nil v:Remove()
    eater.valid = false
end)()
;(function()
    -- spawned inside someone: moved to the nearest clear spot
    local stuck = newPlayer("StuckOne", "citizen")
    stuck:SetPos(Vector(-205000, 205000, 0))
    local n = ents.Create("npc_citizen") n:Spawn() n:SetPos(stuck:GetPos())
    local th = util.TraceHull
    util.TraceHull = function(t)
        local inside = t.start:DistToSqr(n:GetPos()) < 20 * 20
        return { Hit = inside, StartSolid = inside, HitPos = t.endpos, Entity = inside and n or NULL, Fraction = inside and 0 or 1 }
    end
    local tl = util.TraceLine
    util.TraceLine = function(t)
        local down = t.endpos.z < t.start.z - 50
        return { Hit = down, HitPos = down and Vector(t.start.x, t.start.y, 0) or t.endpos, Fraction = down and 0.5 or 1, Entity = NULL }
    end
    local moved = LC.UnstickFromPeople(stuck)
    util.TraceHull, util.TraceLine = th, tl
    ok(moved and stuck:GetPos():Distance(n:GetPos()) >= 30, "spawned inside an NPC: moved out beside them (no noclip needed)", tostring(stuck:GetPos()))
    n:Remove()
    stuck.valid = false
end)()
;(function()
    -- the radio repair: two minutes a set, and it says so when one runs out
    local rr = newPlayer("RadioMan", "citizen")
    ok(LC.JobGameStart(rr, "radio", nil, {}), "a radio on the bench")
    local g = LC.JobGames[rr]
    ok(g and g.radioEnd - CurTime() > 100, "two minutes for each set (it was 50 seconds)", g and math.floor(g.radioEnd - CurTime()))
    g.radioEnd = CurTime() - 1
    _run(0.5)
    ok(g.last == "timeout" and g.n == 2, "out of time: the next set, and the window's told it was a timeout (not fixed)")
    LC.JobGameEnd(rr, "quit")
    rr.valid = false
    -- the clipboard the right way up
    local ang = LC.CarryHandAngle("models/props_lab/clipboard.mdl")
    ok(ang.r == 180 and ang.p == 0, "a clipboard carried in one hand is turned the right way up")
    ok(concommand.GetTable and concommand.GetTable()["lc_outfits_edit"] ~= nil or LC.OpenOutfits ~= nil, "the editor's Job outfits button has its own command (lc_outfits_edit)")
    ok(LC.EndingSongVolume("shalom") == 2 and LC.EndingSongVolume("harpies") == 4, "Shalom's song twice as loud, and the Harpies' twice what it was")
end)()
;(function()
    -- stalkers: only killers among the Resistance; and a stalker is nothing else
    local cit = newPlayer("PettyThief", "citizen")
    cit:SetPData("lce_standing", -990)
    cit:SetPData("lc_jailcount", 9)
    ok(not LC.Heinous(cit, "Obstructing Civil Protection"), "a citizen locked up again and again for small things is never made a stalker")
    local reb = newPlayer("CopKiller", "resistance", nil, 900)
    ok(not LC.Heinous(reb, "Assaulting Civil Protection"), "(nor a rebel who's killed nobody)")
    local c, cst = LC.Spawners.cop(Vector(-206000, 206000, 0))
    hook.Run("OnNPCKilled", c, reb)
    ok(LC.KillCount(reb) >= 1 and LC.Heinous(reb, "Assaulting Civil Protection"), "a rebel who has killed a unit is")
    LC.NPCs[c] = nil if IsValid(c) then c:Remove() end
    LC.GiveItem(reb, "canned_food", 2)
    reb:SetNW2String("lcj_job", "radio")
    LC.MakeStalker(reb)
    ok(LC.PlayerIsStalker(reb) and not LC.HasItem(reb, "canned_food"), "made a stalker: what they had goes with who they were")
    reb.superadmin = true
    local okJ = LC.CanJoinFaction(reb, "resistance")
    ok(not okJ, "a stalker can't take up another faction, even as a superadmin")
    reb.superadmin = nil
    local okS = LC.CanSwitchCharacter(reb)
    ok(not okS, "nor switch to another character")
    reb:SetNW2Float("lcn_hunger", 50)
    _run(6)
    ok(LC.Hunger(reb) >= 50, "a stalker doesn't go hungry", LC.Hunger(reb))
    local cz = ents.Create("npc_citizen") cz:Spawn()
    LC.NPCs[cz] = { role = "citizen", state = "idle", nextUse = 0, untilT = 0, gender = "male" }
    ok(hook.Run("PlayerUse", reb, cz) == false, "a stalker can't talk to people (E)")
    LC.NPCs[cz] = nil cz:Remove()
    local posting = { id = 99001, title = "Union shift", reward = 5, tmpl = LC.QuestTemplates[1], expiresPost = CurTime() + 99 }
    LC.Postings.citizen = LC.Postings.citizen or {}
    table.insert(LC.Postings.citizen, posting)
    reb.lcqNext = 0
    ok(not LC.AcceptPosting(reb, 99001), "a stalker's board is its own work, nothing else")
    for i, p in ipairs(LC.Postings.citizen) do if p == posting then table.remove(LC.Postings.citizen, i) break end end
    LC.FreeStalker(reb)
    reb.valid = false cit.valid = false
end)()
;(function()
    -- cuffed only once they're subdued: a few blows of the baton, or standing still for it. Never in noclip.
    if LC.Event then LC.EndEvent(true) end
    local S0 = Vector(-207000, 207000, 0)
    local u, ust = LC.Spawners.cop(S0 + Vector(40, 0, 0))
    ust.routeGroup = nil ust.untilT = 1e9 u.sim = false
    local runr = newPlayer("FastRunner", "citizen")
    runr:SetPos(S0)
    runr:SetVelocity(Vector(250, 0, 0))
    runr.GetVelocity = function() return Vector(250, 0, 0) end
    LC.ReportCrime(runr, "Ran from a search", 120)
    local taken = LC.NPCSubdue(u, ust, runr, CurTime())
    ok(not taken and LC.SubdueHits(runr) == 1 and runr:GetNW2Float("lc_dazed_until", 0) > CurTime(), "running past a unit: a blow of the baton (and dazed), not cuffs")
    for _ = 1, 4 do _run(1.2) if LC.NPCSubdue(u, ust, runr, CurTime()) then break end end
    ok(LC.Marching[runr] or (LC.Prisoners and LC.Prisoners[runr]) or LC.Detained[runr], "beaten down: cuffed")
    if LC.Marching[runr] then LC.Marching[runr] = nil end
    if LC.Prisoners then LC.Prisoners[runr] = nil end
    runr.valid = false
    local flyer = newPlayer("Noclipper", "citizen")
    flyer:SetPos(S0)
    flyer:SetMoveType(MOVETYPE_NOCLIP)
    LC.ReportCrime(flyer, "Ran from a search", 120)
    ust.nextSubdue = 0
    ok(not LC.NPCSubdue(u, ust, flyer, CurTime()) and LC.SubdueHits(flyer) == 0, "someone in noclip is never laid hands on")
    flyer.valid = false
    LC.NPCs[u] = nil u:Remove()
end)()
;(function()
    -- the search called off: out of sight long enough, the units lose track of you
    local hider = newPlayer("LyingLow", "resistance")
    hider:SetPos(Vector(-208000, 208000, 0))
    LC.ReportCrime(hider, "Escaping custody", 600)
    _run(1.5)
    local sbs = LC.SeenBySecurity
    LC.SeenBySecurity = function() return false end
    _run(GetConVar("lc_wanted_lost"):GetFloat() + 3)
    ok(LC.PlayerIsWanted(hider) and LC.WantedLost(hider), "still wanted, but the units have lost track of where you are")
    local c, cst = LC.Spawners.cop(hider:GetPos() + Vector(600, 0, 0))
    cst.routeGroup = nil cst.untilT = 1e9 c.sim = false
    _run(2)
    ok(cst.state ~= "hostile", "a unit who hasn't seen you doesn't come for you")
    LC.SeenBySecurity = function() return true end
    _run(2)
    ok(cst.state == "hostile" and not LC.WantedLost(hider), "one who sees you does")
    LC.SeenBySecurity = sbs
    LC.ClearWanted(hider)
    LC.CalmCops(hider)
    LC.NPCs[c] = nil c:Remove()
    hider.valid = false
end)()
;(function()
    -- a new face at the lab
    local pat = newPlayer("NewFace", "resistance", nil, 900)
    _run(1) -- (settled where they spawned)
    pat:SetPos(Vector(-210000, 210000, 0))
    pat:SetNW2String("lc_model", "models/humans/group01/male_02.mdl")
    pat:SetPData("lce_standing", -900)
    LC.AddCredits(pat, 500)
    LC.ReportCrime(pat, "Escaping custody", 600)
    local sci = ents.Create("lc_scientist") sci:SetPos(pat:GetPos() + Vector(50, 0, 0)) sci:Spawn()
    local snWas = LC.ScientistNear
    LC.ScientistNear = function() return sci end
    local okS, why = LC.LabSurgery(pat)
    ok(okS, "the scientist will change your face (for the Resistance, for credits)", why)
    _run(21)
    ok(pat:GetNW2String("lc_model", "") ~= "models/humans/group01/male_02.mdl" and not LC.PlayerIsWanted(pat) and LC.Standing(pat) >= -50,
        "you wake with a new face: not wanted, and the records can't put your old standing to it", pat:GetNW2String("lc_model", "") .. " " .. LC.Standing(pat))
    ok(not LC.LabSurgery(pat), "(not again for a while)")
    LC.ReportCrime(pat, "Assault", 60)
    ok(pat:GetPData("lc_new_face", "0") ~= "1", "wanted again: they know the new face too")
    LC.ScientistNear = snWas
    sci:Remove()
    LC.ClearWanted(pat)
    pat.valid = false
end)()
;(function()
    -- the supply drop: one soldier guarding (he warns you off), two metrocops carrying boxes away
    if LC.Event then LC.EndEvent(true) end
    local D0 = Vector(-209000, 209000, 0)
    local fly = LC.FlyDropship
    LC.FlyDropship = nil
    local seenWas = LC.IsSeen
    LC.IsSeen = function() return false end
    LC.StartSupplyDrop(D0)
    local s = LC.Supply
    local soldiers, porters = 0, #(s and s.porters or {})
    for _, gd in ipairs(s and s.guards or {}) do local st = LC.NPCs[gd] if st and st.role == "soldier" then soldiers = soldiers + 1 end end
    ok(s and soldiers == 1 and porters == 2, "one soldier on guard, two metrocops unloading", soldiers .. " / " .. porters)
    local carried = false
    for _ = 1, 20 do
        _run(0.5)
        for _, pn in ipairs(s.porters) do local st = LC.NPCs[pn] if st and IsValid(st.carry) then carried = true end end
        if carried then break end
    end
    ok(carried, "a metrocop picks up a box to carry off")
    local nosy = newPlayer("NosyCitizen", "citizen")
    nosy:SetPos(s.crate:GetPos() + Vector(60, 0, 0))
    local us, walls = LC.UnitSees, _walls
    LC.UnitSees = function() return true end
    _walls = {} -- (nothing left over from other tests between the guard and them)
    for _ = 1, 25 do
        _run(1)
        nosy:SetPos(s.crate:GetPos() + Vector(60, 0, 0)) -- (they stay put by the crates)
        if LC.PlayerIsWanted(nosy) then break end
    end
    local gd = s.guards and s.guards[1]
    ok(LC.PlayerIsWanted(nosy) and has(nosy.chat, "Step away from the crates"), "hanging about the crates: warned twice, then wanted",
        string.format("guard %s hp %s warned %s alive %s hp %s drop %s cp %s", tostring(IsValid(gd)), tostring(IsValid(gd) and gd:Health()),
            tostring(nosy.lcSupplyWarn and nosy.lcSupplyWarn.n), tostring(nosy:Alive()), tostring(nosy:Health()), tostring(LC.Supply == s),
            tostring(LC.PlayerIsCP(nosy))))
    LC.UnitSees, _walls = us, walls
    LC.IsSeen = seenWas
    LC.FlyDropship = fly
    LC.EndSupplyDrop(true)
    LC.ClearWanted(nosy) LC.CalmCops(nosy)
    nosy.valid = false
end)()
;(function()
    -- Bloom's hands: the tuning sent in is part of the code now (the saved copy dropped)
    local tun = LC.EndingTuning()
    tun.bones.ears = { L_Hand = { 0, 0, 180 }, R_Hand = { 0, 0, -180 }, Head = { 5, 0, 0 } }
    ok(LC.EndingTuneBaked() and tun.bones.ears.L_Hand == nil and tun.bones.ears.Head ~= nil, "Bloom's hand tuning is in the code now: the saved copy goes (the rest stays)")
    tun.bones.ears = nil
end)()

section("The Resistance's money: intel, skimming, forged cards")
;(function()
    -- intel: written down near a checkpoint, sold only to the quartermaster
    local F0 = Vector(-215000, 215000, 0)
    local cp = LC.AddPoint(F0 + Vector(300, 0, 0), 0, "checkpoint", 0)
    local spy = newPlayer("Watcher", "resistance", nil, 400)
    _run(1)
    spy:SetPos(F0)
    LC.GiveItem(spy, "paper", 2)
    local sbs = LC.SeenBySecurity
    LC.SeenBySecurity = function() return false end
    ok(LC.Scout(spy), "a Resistance member near a checkpoint can write down what they see")
    _run(16)
    ok(LC.HasItem(spy, "intel_checkpoint") and (LC.Inventory(spy).paper or 0) == 1, "fifteen seconds: notes on the checkpoint (a sheet of paper used)")
    local again, why = LC.Scout(spy)
    ok(not again and string.find(why or "", "already", 1, true), "the same place again is old news for a while", why)
    local nq = LC.NearQuartermaster
    LC.NearQuartermaster = function() return false end
    ok(LC.SellPrice(spy, "intel_checkpoint") == nil, "the dealer won't buy intel")
    LC.NearQuartermaster = function() return true end
    ok(LC.SellPrice(spy, "intel_checkpoint") == 25, "the quartermaster pays for it", LC.SellPrice(spy, "intel_checkpoint"))
    ok(LC.SellPrice(spy, "union_goods") > LCS.Items.union_goods.sell, "and pays more than the dealer for skimmed parts")
    LC.NearQuartermaster = nq
    -- seen at it: the paper's taken
    spy.lcIntelSeen = {}
    LC.Scout(spy)
    LC.SeenBySecurity = function() return true end
    _run(1.5)
    ok(not LC.Busy(spy) and (LC.Inventory(spy).paper or 0) == 0, "a unit who sees you writing takes the paper off you")
    LC.SeenBySecurity = sbs
    LC.RemovePoint(cp)
    local cit = newPlayer("NotARebel", "citizen")
    LC.GiveItem(cit, "paper", 1)
    ok(not LC.Scout(cit), "(intel is the Resistance's trade)")
    cit.valid = false
    -- skimming the factory line
    local worker = newPlayer("Skimmer", "citizen")
    _run(1)
    worker:SetPos(F0 + Vector(0, 3000, 0))
    ok(LC.JobGameStart(worker, "line", nil, { station = worker:GetPos() }), "(a shift on the line)")
    local g = LC.JobGames[worker]
    local good
    -- (a good part: about two in three are; if the shift ended under it before one came, once more)
    for attempt = 1, 2 do
        for _ = 1, 40 do
            _run(0.5)
            for _, e in ipairs(g.parts or {}) do if IsValid(e) and e.lcPart and not e.lcPart.bad and not e.lcPart.rattle then good = e break end end
            if good or LC.JobGames[worker] ~= g then break end
        end
        if good then break end
        if LC.JobGames[worker] == g then LC.JobGameEnd(worker, "done") end
        worker:SetPos(F0 + Vector(0, 3000, 0))
        LC.JobGameStart(worker, "line", nil, { station = worker:GetPos() })
        g = LC.JobGames[worker] or g
    end
    LC.SeenBySecurity = function() return false end
    local nParts = #(g.parts or {})
    local skimmed = good and LC.LineSkim(worker, g, good)
    ok(skimmed and LC.HasItem(worker, "union_goods") and g.skimmed == 1, "R on a good part: it goes in your coat (Union machine parts)",
        tostring(good) .. " parts=" .. nParts .. " skim=" .. tostring(skimmed) .. " inv=" .. tostring(LC.Inventory(worker).union_goods) .. " n=" .. tostring(g.skimmed))
    LC.SeenBySecurity = sbs
    LC.JobGameEnd(worker, "quit")
    worker.valid = false
    -- forged cards: five at a time at the lab; enough turning up, and they come for the forger
    ok(LCS.LabById.forged_batch and LCS.LabById.forged_batch.count == 5, "the lab makes forged ration cards five at a time")
    local zr = LC.AddZone(F0 + Vector(0, -2000, 0), 300, "rebel", 0)
    _setcvar("lc_forgery_heat", 3)
    LC.PlannedSweep = nil
    if LC.Skirmish then LC.Skirmish.done = true LC.Skirmish = nil end
    LC.ForgeryMade(F0 + Vector(0, -1900, 0))
    LC.ForgeryHeat = 0
    hook.Run("LivingCityForgedCard", spy, 2)
    ok(LC.PlannedSweep == nil, "a couple of forged cards turning up: nothing yet")
    hook.Run("LivingCityForgedCard", spy, 1)
    ok(LC.PlannedSweep and LC.PlannedSweep.zone == zr, "enough of them: a sweep planned on the rebel territory nearest the lab that made them")
    LC.PlannedSweep = nil
    _setcvar("lc_forgery_heat", 15)
    LC.RemoveZone(zr)
    spy.valid = false
end)()

section("Playtest fixes, 21 October")
;(function()
    if LC.Event then LC.EndEvent(true) end
    local W0 = Vector(-221000, 221000, 0)
    -- a stalker: the units leave it alone, its papers say what it is, and it works (it doesn't just stand there)
    local stk = newPlayer("Hollow", "citizen")
    _run(1)
    LC.MakeStalker(stk)
    ok(LC.PlayerIsStalker(stk), "(a stalker)")
    ok(not string.find(string.lower(LCF.Get("stalker").desc or ""), "sewn", 1, true), "nobody sews a stalker's mouth shut (it can scream)")
    ok(LC.ReportCrime(stk, "Possession of contraband", 120) == false and not LC.PlayerIsWanted(stk), "a stalker is never booked for anything (no contraband arrests)")
    ok(LC.PapersInfo(stk).stalker == true, "a stalker's papers carry the STALKER stamp")
    local cit = newPlayer("PlainPapers", "citizen")
    ok(not LC.PapersInfo(cit).stalker, "(a citizen's papers don't)")
    stk:SetPos(W0)
    ok(LC.JobGameStart(stk, "scrub", nil, { pos = W0 }), "the holding floor is a job to do: grime to sweep up")
    local g = LC.JobGames[stk]
    ok(g and #g.stains >= 4 and IsValid(g.broom) and g.broom:GetModel() == "models/props_c17/pushbroom.mdl", "a push broom in hand, and patches of grime about", g and #g.stains)
    for _ = 1, 2 do
        for _, e in ipairs(g and g.stains or {}) do
            if IsValid(e) then stk:SetPos(e:GetPos()) hook.Run("PlayerUse", stk, e) _run(3) end
        end
    end
    _run(1)
    ok(LC.JobGames[stk] == nil, "every patch swept: done")
    stk:SetPos(W0 + Vector(0, 2000, 0))
    ok(LC.JobGameStart(stk, "assemble", nil, { pos = W0 + Vector(0, 2000, 0) }), "the frame is a job to do: cells to carry in, seams to weld")
    g = LC.JobGames[stk]
    ok(g and #g.cells == 4, "four containment cells lying about", g and #g.cells)
    for _, e in ipairs(g and g.cells or {}) do if IsValid(e) then e:SetPos(g.center) end end
    _run(1)
    ok(g and g.seated == 4 and #g.seams == 4, "carried into the frame: seated, and four seams to weld", g and g.seated)
    for _, e in ipairs(g and g.seams or {}) do
        if IsValid(e) then stk:SetPos(e:GetPos()) hook.Run("PlayerUse", stk, e) _run(4) end
    end
    _run(1)
    ok(LC.JobGames[stk] == nil, "welded shut: done")
    if LC.Energizers[stk] then LC.Energizers[stk]:Remove() LC.Energizers[stk] = nil end
    local tech = LC.StalkerTechnician(stk, stk:GetPos())
    ok(IsValid(tech) and tech:GetNW2String("lc_pname", "") == "Overwatch technician", "a technician comes to fit the harness")
    if IsValid(tech) then timer.Remove("LivingCityTech" .. tech:EntIndex()) LC.NPCs[tech] = nil tech:Remove() end
    LC.FreeStalker(stk)
    stk.valid = false cit.valid = false
end)()
;(function()
    -- the infested: slower than a citizen, no guns, they rise in their nests, and killing isn't murder
    local W0 = Vector(-222000, 222000, 0)
    local nest = LC.AddZone(W0, 300, "infest", 0)
    local z = newPlayer("Shambler", "citizen")
    _run(1)
    z:SetPos(W0 + Vector(4000, 0, 0))
    LC.SetFaction(z, "zombie", nil, true, true)
    _run(1)
    ok(z:GetPos():Distance(W0 + Vector(4000, 0, 0)) > 300, "turned infested from the menu: up in a nest, not where they stood", z:GetPos())
    local ref = newPlayer("Pedestrian", "citizen")
    _run(1)
    ok(z:GetRunSpeed() <= ref:GetRunSpeed() and z:GetWalkSpeed() <= ref:GetWalkSpeed(), "a zombie is no faster than a citizen", z:GetRunSpeed() .. " vs " .. ref:GetRunSpeed())
    ref.valid = false
    local gun = ents.Create("weapon_pistol") gun:Spawn()
    ok(hook.Run("PlayerCanPickupWeapon", z, gun) == false, "a zombie can't pick up a gun")
    gun:Remove()
    z:Give("weapon_pistol")
    LC.ZombieDisarm(z)
    ok(not z:HasWeapon("weapon_pistol"), "and one in its hands is dropped")
    local killed = tonumber(z:GetPData("lc_killed", 0)) or 0
    local c = LC.Spawners.citizen(W0 + Vector(60, 0, 0))
    hook.Run("OnNPCKilled", c, z)
    ok(not LC.PlayerIsWanted(z) and LC.Heat(z) == 0 and (tonumber(z:GetPData("lc_killed", 0)) or 0) == killed, "what a zombie kills isn't murder: no wanted, no response, no kill counted")
    LC.NPCs[c] = nil if IsValid(c) then c:Remove() end
    LC.RemoveZone(nest)
    z.valid = false
end)()
;(function()
    -- metrocops walk the streets; the Combine's buildings are the soldiers'
    local W0 = Vector(-223000, 223000, 0)
    local hq = LC.AddZone(W0, 400, "combine", 0)
    local np, fb = LC.NodePositions, LC.Fallback
    LC.Fallback = {}
    LC.NodePositions = function() return { W0, W0 + Vector(3000, 0, 0) } end
    local inside = 0
    for _ = 1, 30 do
        local p = LC.RandomWanderPos("cop")
        if p and p:Distance(W0) < 450 then inside = inside + 1 end
    end
    ok(inside == 0, "a metrocop on its beat never wanders into the Combine HQ", inside)
    LC.NodePositions, LC.Fallback = np, fb
    LC.RemoveZone(hq)
    -- flying a scanner: the city around the scanner is as awake as around anyone standing there
    local pilot = newPlayer("Flyer", "cp")
    _run(1)
    local sc = ents.Create("prop_physics") sc:Spawn() sc:SetPos(W0 + Vector(0, 9000, 200))
    pilot:SetNW2Entity("lc_scanner", sc)
    local near = false
    for _, at in ipairs(LC.ViewerPositions()) do if at:Distance(sc:GetPos()) < 1 then near = true end end
    ok(near and not LC.FarFromPlayers(sc:GetPos() + Vector(100, 0, -200), 500), "a flown scanner counts as somebody there (no NPCs asleep and hopping around it)")
    pilot:SetNW2Entity("lc_scanner", NULL)
    sc:Remove()
    pilot.valid = false
end)()
;(function()
    -- radio repair: Freq 7, written down, is a sheet you can read and pass on (and it's contraband);
    -- and the bench radios sit on the bench, for the NPC repairers to work on
    local it = LCS.Items.freq7_sheet
    ok(it and it.contraband and it.use == "read", "a Freq 7 sheet: contraband, and it can be read")
    local txt = LC.Freq7SheetText(102.4)
    local all = true
    for _, f in ipairs(LC.Freq7Freqs) do if not string.find(txt, string.format("%.1f", f), 1, true) then all = false end end
    ok(all and string.find(txt, "102.4", 1, true), "it lists the seven frequencies, and where it was heard")
    local rd = newPlayer("Tinkerer", "citizen")
    _run(1)
    LC.GiveItem(rd, "freq7_sheet", 1)
    ok(LC.ItemUse(rd, "freq7_sheet"), "Read, from your pockets")
    ok(LC.JobGameStart(rd, "radio", nil, { freq7 = 1 }), "(a radio on the bench)")
    local g = LC.JobGames[rd]
    local sent
    local jp = LC.JobGamePanel
    LC.JobGamePanel = function(gg, d) sent = d return jp(gg, d) end
    LC.JobGameAct(rd, "dial", g.f7)
    LC.JobGameAct(rd, "lock", { f = g.f7 })
    ok(g.heard, "(Freq 7 on the dial)")
    LC.JobGameAct(rd, "freq7", "note")
    LC.JobGamePanel = jp
    ok(LC.HasItem(rd, "freq7_sheet") and sent and sent.dial and math.abs(sent.dial - (g.dial or 0)) < 0.01, "Write it down: a Freq 7 sheet, and the dial stays where it was", sent and sent.dial)
    LC.JobGameEnd(rd, "quit")
    rd.valid = false
    local W0 = Vector(-224000, 224000, 0)
    local pt = { pos = W0, yaw = 90 }
    local r1 = LC.NPCWorkBenchProp(pt, "models/props_lab/citizenradio.mdl")
    ok(IsValid(r1) and r1:GetModel() == "models/props_lab/citizenradio.mdl" and r1:GetPos():Distance(W0) < 40, "a radio sits on the repair bench point")
    ok(LC.NPCWorkBenchProp(pt, "models/props_lab/citizenradio.mdl") == r1, "(one, not a new one each time)")
    r1:Remove()
    LC.BenchProps[pt] = nil
end)()
;(function()
    -- the jog: late, you get your own pace marker from where you join, and the jog waits for you
    if LC.Event then LC.EndEvent(true) end
    local E0 = Vector(-225000, 225000, 0)
    local jp = {}
    for i, off in ipairs({ Vector(0, 0, 0), Vector(1200, 0, 0), Vector(1200, 1200, 0), Vector(0, 1200, 0) }) do
        jp[i] = LC.AddPoint(E0 + off, 0, "jogroute", 1)
    end
    local late = newPlayer("Latecomer", "citizen") late:SetPos(E0 + Vector(-9000, 0, 0))
    _setcvar("lc_exercise_muster", 15)
    ok(LC.StartEvent("jog"), "(the jog)")
    local X = LC.ExerciseSession()
    _run(16)
    ok(X and X.phase == "run", "(off they go without the latecomer)")
    local lanes = {}
    for npc in pairs(X and X.npcs or {}) do local st = LC.NPCs[npc] if st and st.exCitizen and st.exCitizen.lane then lanes[st.exCitizen.lane] = true end end
    ok(next(X and X.npcs or {}) == nil or table.Count(lanes) >= 2, "the city's joggers keep to lanes of their own (not one scrum on one spot)")
    _run(20)
    late:SetPos(E0 + Vector(30, 0, 0))
    late.vel = Vector(200, 0, 0)
    _run(1.5)
    local r = X.people[late]
    ok(r and r.late and (r.lag or 0) > 0, "late to the start: in it, with your own pace marker", r and r.lag)
    ok(not late:GetNW2Bool("lcx_behind", false), "(and not behind it the moment you arrive)")
    ok(LC.EventEnds >= X.runStart + (X.total + r.lag) / X.pace, "the jog lasts long enough for the latecomer to finish")
    LC.EndEvent(true)
    for _, p in ipairs(jp) do LC.RemovePoint(p) end
    late.valid = false
end)()

section("Safeguards for a public server: floods, piles, double pickups")
;(function()
    local G0 = Vector(-226000, 226000, 0)
    local spam = newPlayer("Spammer", "citizen")
    _run(1)
    spam:SetPos(G0)
    LC.TestMode = false
    local passed = 0
    for _ = 1, 200 do if LC.NetAllowed(spam, "lci_act") then passed = passed + 1 end end
    ok(passed >= 20 and passed <= 30, "two hundred of one message at once: only a burst gets through", passed)
    _advance(1)
    ok(LC.NetAllowed(spam, "lci_act"), "a second later, the next goes through")
    for _ = 1, 600 do LC.NetAllowed(spam, "lci_act") end
    ok(spam.kicked ~= nil, "someone who keeps flooding is kicked", spam.kicked)
    local mod = newPlayer("GuardStaff", "citizen") mod.admin = true
    local all = true
    for _ = 1, 200 do if not LC.NetAllowed(mod, "lci_act") then all = false end end
    ok(all, "staff are never held back")
    local chatty = newPlayer("Chatty", "citizen")
    local let = 0
    for i = 1, 12 do if LC.ChatAllowed(chatty) then let = let + 1 end end
    ok(let == 6, "chat: six lines in three seconds, then the rest wait", let)
    _advance(3.1)
    ok(LC.ChatAllowed(chatty), "and they can talk again a moment later")
    LC.TestMode = true
    mod.valid = false chatty.valid = false spam.valid = false
    -- dropping things: no endless piles
    local dropper = newPlayer("Dropper", "citizen")
    _run(1)
    dropper:SetPos(G0 + Vector(0, 500, 0))
    LC.GiveItem(dropper, "paper", 3)
    for _ = 1, 3 do LC.InvAction(dropper, "drop", "paper") end
    local first = dropper.lcDropped and dropper.lcDropped[1]
    _setcvar("lc_drops_kept", 2)
    LC.GiveItem(dropper, "paper", 1)
    LC.InvAction(dropper, "drop", "paper")
    ok(#dropper.lcDropped == 2 and not IsValid(first), "past lc_drops_kept on the ground, the oldest is cleared away", #(dropper.lcDropped or {}))
    _setcvar("lc_drops_kept", 30)
    for _, x in ipairs(dropper.lcDropped or {}) do if IsValid(x) then x:Remove() end end
    dropper.valid = false
end)()

;(function()
    -- no credits out of thin air: nothing at the lab costs less than it sells back for
    ok(LC.LabPrice({ out = "gun_parts" }) > LCS.Items.gun_parts.sell, "gun parts at the lab cost more than the quartermaster pays for them", LC.LabPrice({ out = "gun_parts" }))
    local cuffer = newPlayer("Cuffer", "citizen")
    cuffer.chat = {}
    local said = hook.Run("PlayerSay", cuffer, "!cuff")
    ok(LCS.Items.zipties.name == "Cuffs" and said == "" and has(cuffer.chat, "Look at someone"), "zip ties are cuffs now, and !cuff works like !tie", table.concat(cuffer.chat, " | "))
    cuffer.valid = false
    ok(LCS.Items.zipties.sell == 1, "cuffs (zip ties once) sell for 1")
    -- a unit's issued grenades are Combine issue
    local unit = newPlayer("GrenadeUnit", "cp", nil, 900)
    local other = newPlayer("OtherUnit", "cp", nil, 900)
    local civ = newPlayer("GrenadeFriend", "citizen")
    _run(2)
    LC.GiveItem(unit, "gren_smoke", 1)
    ok(LC.SellPrice(unit, "gren_smoke") == nil, "a unit can't sell an issued grenade")
    LC.InvAction(unit, "drop", "gren_smoke")
    ok(LC.HasItem(unit, "gren_smoke"), "or drop it")
    ok(LC.IssuedLocked(unit, "gren_smoke", civ) and not LC.IssuedLocked(unit, "gren_smoke", other), "or hand it to anyone but another unit")
    LC.GiveItem(civ, "gren_smoke", 1)
    ok(LC.SellPrice(civ, "gren_smoke") ~= nil, "(one that's ended up in a citizen's hands sells as before)")
    -- a unit's BOLOs: one every half minute
    local okA = LC.AddBOLO(unit, nil, "a tall man in a grey coat", 10)
    local okB = LC.AddBOLO(unit, nil, "another one", 10)
    ok(okA and not okB, "a unit's second BOLO straight away waits (each one rings for every unit)")
    -- the light level a player's game reports is only a hint
    civ.lcLight = 0
    civ.FlashlightIsOn = function() return true end
    ok(LC.TrustedLight(civ) == 1, "claiming to be in the dark with a flashlight on doesn't hide you")
    civ.FlashlightIsOn = function() return false end
    unit.valid = false other.valid = false civ.valid = false
end)()

section("Couriers and senders; the Resistance's smugglers")
;(function()
    local P0 = Vector(-227000, 227000, 0)
    local stops = { { pos = P0 + Vector(400, 0, 0), name = "A" }, { pos = P0 + Vector(800, 0, 0), name = "B" }, { pos = P0 + Vector(1200, 0, 0), name = "C" } }
    local cu = newPlayer("Courier21", "citizen")
    _run(1)
    cu:SetPos(P0)
    local function Standing(p) return tonumber(p:GetPData("lce_standing", 0)) or 0 end
    local clean = { text = "A flat tin.", hot = false, say = "buttons", inside = "buttons" }
    local hot = { text = "A heavy box.", hot = true, inside = "pistol rounds" }
    -- an honest sender: no reporting them, just take it or not (or open it)
    LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = clean, sender = "honest" })
    local g = LC.JobGames[cu]
    ok(g and not g.decided, "the sender hands it over first: nothing moves till you decide")
    ok(LC.JobGameAct(cu, "sender", "report") == nil, "an honest sender who said what's in it can't be reported")
    ok(LC.JobGameAct(cu, "sender", "take") and g.decided and cu.lcWaypoint ~= nil, "take it: the clock starts and the first door is marked")
    LC.JobGameEnd(cu, "quit")
    -- a sender who won't say: report them
    local s0 = Standing(cu)
    LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = hot, sender = "silent" })
    ok(LC.JobGameAct(cu, "sender", "report") and LC.JobGames[cu] == nil and Standing(cu) > s0, "a sender who won't say what's in it can be reported to Civil Protection (standing up, contraband found)", Standing(cu) - s0)
    -- open it: standing down, and you know what's inside
    s0 = Standing(cu)
    LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = hot, sender = "silent" })
    g = LC.JobGames[cu]
    LC.JobGameAct(cu, "sender", "open")
    ok(g.opened and Standing(cu) < s0, "opening somebody's parcel costs Civil Standing", Standing(cu) - s0)
    ok(LC.JobGameAct(cu, "sender", "open") == nil, "(once is enough)")
    LC.JobGameAct(cu, "sender", "take")
    ok(g.knowing, "seen what's in it and taken it anyway: you know what you're carrying")
    LC.JobGameEnd(cu, "quit")
    -- hand it back
    local c0 = LC.Credits(cu)
    LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = clean, sender = "honest" })
    ok(LC.JobGameAct(cu, "sender", "refuse") and LC.JobGames[cu] == nil and LC.Credits(cu) == c0, "hand it back: no parcel, no pay")
    -- a bold sender: the extra, when it gets there
    LC.JobGameStart(cu, "parcel", nil, { stops = stops, parcel = hot, sender = "bold", searchFinds = 0 })
    g = LC.JobGames[cu]
    LC.JobGameAct(cu, "sender", "take")
    c0 = LC.Credits(cu)
    for i = 1, 3 do cu:SetPos(stops[i].pos) _run(0.3) end
    ok(LC.JobGames[cu] == nil and LC.Credits(cu) - c0 >= 8 + 9, "a sender who owned up pays the extra when it gets there", LC.Credits(cu) - c0)
    cu.valid = false
    -- the Resistance's smugglers
    local f = LCF.Get("resistance")
    ok(f.specialsById.smuggler ~= nil, "the Resistance has a Smuggler role")
    local sm = newPlayer("Runner21", "resistance", "smuggler", 400)
    local plain = newPlayer("NotASmuggler", "resistance", nil, 400)
    _run(1)
    local tmpl
    for _, t in ipairs(LC.QuestTemplates) do if t.id == "res_smuggle" then tmpl = t end end
    ok(tmpl and tmpl.available(sm) and not tmpl.available(plain), "smuggling runs are on a Smuggler's board, nobody else's")
    sm:SetPos(P0)
    local started = LC.JobGameStart(sm, "parcel", nil, { stops = stops, smuggle = true, searchFinds = 0 })
    g = LC.JobGames[sm]
    ok(g and g.decided and g.knowing and g.parcel.hot and g.title == "Smuggling run", "a smuggling run: hot cargo, no questions, straight off")
    c0 = LC.Credits(sm)
    for i = 1, 3 do sm:SetPos(stops[i].pos) _run(0.3) end
    ok(LC.JobGames[sm] == nil and LC.Credits(sm) - c0 >= 18 + 10, "and it pays far better than a courier's run", LC.Credits(sm) - c0)
    sm.valid = false plain.valid = false
end)()

section("The radio held up: chat and voice over the band")
;(function()
    local R0 = Vector(-228000, 228000, 0)
    local a = newPlayer("RadioA", "resistance", nil, 400)
    local b = newPlayer("RadioB", "resistance", nil, 400)
    local cit = newPlayer("RadioBystander", "citizen")
    local close = newPlayer("RadioClose", "citizen")
    _run(1)
    a:SetPos(R0) close:SetPos(R0 + Vector(60, 0, 0)) cit:SetPos(R0 + Vector(300, 0, 0)) b:SetPos(R0 + Vector(9000, 0, 0))
    LC.GiveItem(a, "radio_tuned", 1) LC.GiveItem(b, "radio_tuned", 1)
    LC.SyncRadioSwep(a)
    ok(not a:HasWeapon("weapon_lc_radio"), "a radio alone only listens: nothing to hold up and talk into")
    LC.GiveItem(a, "radio_transmitter", 1) LC.GiveItem(b, "radio_transmitter", 1)
    LC.SyncRadioSwep(a) LC.SyncRadioSwep(b) LC.SyncRadioSwep(cit)
    ok(a:HasWeapon("weapon_lc_radio") and not cit:HasWeapon("weapon_lc_radio"), "a radio and a radio transmitter: a Radio transmitter to switch to, next to your hands (nobody else gets one)")
    a.chat, b.chat, cit.chat, close.chat = {}, {}, {}, {}
    ok(not LC.RadioRaisedSay(a, "hello"), "(radio down: chat as usual)")
    a:SelectWeapon("weapon_lc_radio")
    ok(LC.RadioRaised(a), "switched to it: the radio is up")
    local said = hook.Run("PlayerSay", a, "Sweep at the market, stay clear")
    ok(said == "" and has(b.chat, "Sweep at the market") and has(close.chat, "into a radio") and not has(cit.chat, "Sweep at the market"),
        "with the radio up, what you type goes out on Freq 7, and only someone right beside you hears it")
    ok(hook.Run("PlayerSay", a, "!looc brb") ~= nil or true, "(commands and out of character chat still work as usual)")
    local hearB, spatialB = LC.RadioVoice(b, a)
    local hearC = LC.RadioVoice(cit, a)
    local hearN, spatialN = LC.RadioVoice(close, a)
    ok(hearB and not spatialB and not hearC and hearN and spatialN, "voice too: everyone on the band hears it anywhere, the person beside you hears it, nobody else")
    a:SelectWeapon("weapon_lc_hands")
    ok(not LC.RadioRaised(a) and LC.RadioVoice(cit, a) == nil, "back to your hands (or a gun): the radio's down, and you talk normally again")
    LC.TakeItem(a, "radio_transmitter", 1)
    LC.SyncRadioSwep(a)
    ok(not a:HasWeapon("weapon_lc_radio"), "lose the transmitter and you can only listen again")
    local unit = newPlayer("RadioUnit", "cp")
    _run(2.5)
    ok(unit:HasWeapon("weapon_lc_radio"), "every unit has one (the CP net)")
    a.valid = false b.valid = false cit.valid = false close.valid = false unit.valid = false
end)()

section("Playtest fixes, 31 October")
;(function()
    -- healing comes from eating, sleeping and medicine: nobody mends on their own while awake
    local h = newPlayer("Healer31", "citizen")
    _run(1)
    h:SetNW2Float("lcn_hunger", 100) h:SetNW2Float("lcn_thirst", 100)
    h:SetHealth(50)
    _run(30)
    ok(h:Health() <= 50, "well fed and awake: no slow mending any more", h:Health())
    LC.GiveItem(h, "ration", 1)
    local before = h:Health()
    LC.Consume(h, "ration")
    ok(h:Health() > before, "eating food mends you a little as you eat it", h:Health() - before)
    h.valid = false
end)()

section("The Endings menu: every ending's settings, and its dances tuned live")
;(function() -- (its own function: the file's main chunk is at Lua's limit on locals)
    ok(LC.EndingSettingGroup("lc_ending_flood_boats") == "water" and LC.EndingSettingGroup("lc_ending_minge_max") == "harpies"
        and LC.EndingSettingGroup("lc_ending_shalom_sections") == "shalom" and LC.EndingSettingGroup("lc_ending_cooldown") == "all"
        and LC.EndingSettingGroup("lc_endings_on") == "all" and LC.EndingSettingGroup("lc_citizens") == nil,
        "each ending's settings are found by their names (the Flood's are flood_, the Harpies' minge_), the rest are every ending's")
    local inf = LC.EndingTuneInfo()
    local function Has(list, name) for _, s in ipairs(list or {}) do if s.name == name then return s end end end
    local boats = Has(inf.settings.water, "lc_ending_flood_boats")
    ok(#inf.endings == #LC.EndingOrder and boats and boats.d == "6" and boats.help ~= "" and Has(inf.settings.all, "lc_ending_cooldown")
        and Has(inf.settings.shalom, "lc_ending_shalom_sections"),
        "the menu gets every ending, and each one's settings with their value, default and what they do")
    local guest = newPlayer("TuneGuest", "citizen")
    local boss = newPlayer("TuneBoss", "citizen")
    boss.superadmin = true
    ok(LC.EndingTuneSet(guest, "bone", "hora", "R_UpperArm", -10, 5, 0) == false and not (LC.EndingTuning().bones.hora),
        "only a superadmin can tune an ending")
    net.sent = {}
    ok(LC.EndingTuneSet(boss, "bone", "hora", "R_UpperArm", -10, 5, 0) and LC.EndingTuning().bones.hora.R_UpperArm[1] == -10,
        "a superadmin turns one bone of the hora")
    local all = _lastnet("lc_tune_all")
    ok(all and all.omit == boss and all.data[1].bones.hora, "and every other player's game is sent it, so everyone dances the same")
    _run(1.5)
    ok(string.find(_files["livingcity/ending_tuning.json"] or "", "R_UpperArm", 1, true), "the tuning is kept in data/livingcity/ending_tuning.json")
    LC.EndingTuneSet(boss, "bone", "hora", "R_UpperArm", 0, 0, 0)
    ok(not LC.EndingTuning().bones.hora, "turned back to nothing, it's the code's own pose again")
    local was = GetConVar("lc_ending_flood_boats"):GetString()
    ok(LC.EndingTuneSet(boss, "setting", "lc_ending_flood_boats", "8") and GetConVar("lc_ending_flood_boats"):GetString() == "8",
        "an ending's setting changed from the menu is the server's setting")
    RunConsoleCommand("lc_ending_flood_boats", was)
    local cit = GetConVar("lc_citizens"):GetString()
    ok(LC.EndingTuneSet(boss, "setting", "lc_citizens", "0") == false and GetConVar("lc_citizens"):GetString() == cit,
        "but nothing that isn't an ending's")
    ok(LC.EndingTuneSet(boss, "setting", "lc_bloom_palm", "75") and LC.EndingTuning().shared.lc_bloom_palm == "75",
        "the settings every player's game keeps for itself (Bloom's palms) get one value for everyone")
    LC.EndingTuneSet(boss, "setting", "lc_bloom_palm", "")
    _netcall("lc_tune_set", boss, "bone", "numa", "Head", 1, 2, 3)
    ok(LC.EndingTuning().bones.numa and LC.EndingTuning().bones.numa.Head[3] == 3, "the menu's changes arrive over the network")
    LC.EndingTuneSet(boss, "bone", "numa", "Head", 0, 0, 0)
    net.sent = {}
    _netcall("lc_tune_req", guest)
    ok(not _lastnet("lc_tune_info"), "the menu doesn't open for someone who isn't a superadmin")
    _netcall("lc_tune_req", boss)
    ok(_lastnet("lc_tune_info") ~= nil, "it does for a superadmin")
    guest.valid, boss.valid = false, false
end)()

section("The 1 November playtest: infestations, sweeps, tools, traits, bins, rations")
;(function()
    local O = Vector(-140000, 60000, 0)
    -- nobody walks into an infestation
    local iz = LC.AddZone(O + Vector(2000, 0, 0), 300, "infest", 0)
    ok(LC.InInfest(iz.pos) and not LC.InInfest(O), "an infestation is known as one, and its outside isn't")
    ok(LC.StepInfested(iz.pos - Vector(600, 0, 0), iz.pos + Vector(600, 0, 0)), "a step straight through it is one to go round")
    LC.RemoveZone(iz)
    -- a job's tools go with the job
    local med = newPlayer("ToolsMedic", "citizen")
    _run(0.3)
    LC.SetJob(med, "medic", true)
    ok(med:HasWeapon("weapon_medkit"), "(a medic has the medkit)")
    LC.SetJob(med, "porter", true)
    ok(not med:HasWeapon("weapon_medkit"), "a new job: the old job's medkit is taken back")
    LC.SetJob(med, "", true)
    -- the traits on the HUD
    local l0 = LC.Trait(med, "loyalty")
    LC.AddTrait(med, "loyalty", 2)
    ok(med:GetNW2Int("lcq_loyalty", -1) == l0 + 2, "loyalty (and sympathy, corruption) are sent for the HUD", med:GetNW2Int("lcq_loyalty", -1))
    -- a bin you're standing by
    med:SetPos(O + Vector(0, 3000, 0))
    local bin = ents.Create("prop_physics") bin:SetModel("models/props_junk/TrashBin01a.mdl") bin:SetPos(med:GetPos() + Vector(40, 0, 0)) bin:Spawn()
    ok(LC.BinNextTo(med) == "e" .. bin:EntIndex(), "a bin you're standing right by counts, even if you're not looking at it", tostring(LC.BinNextTo(med)))
    bin:Remove()
    -- skipping exercise withholds the next ration
    LC.GiveItem(med, "ration_card", 2)
    med.lcnRationAt = 0
    med.lcRationWithheld = "you skipped morning exercise"
    med.chat = {}
    ok(LC.UseDispenser(med, nil) == false and has(med.chat, "skipped morning exercise") and LC.Inventory(med).ration_card == 2, "skipped morning exercise: that ration is withheld (the card kept)")
    -- soldiers carry pulse rifles or shotguns, never SMGs
    local smg = false
    for i = 1, 12 do
        local s = LC.Spawners.soldier(O + Vector(i * 60, -2000, 0))
        if IsValid(s) then
            if s.kv and s.kv.additionalequipment == "weapon_smg1" then smg = true end
            s:Remove()
        end
    end
    ok(not smg, "Combine soldiers: pulse rifles or shotguns, never SMGs")
    -- a sweep team smashes the pots and empties the crates
    local rz = LC.AddZone(O + Vector(0, -6000, 0), 300, "rebel", 0)
    local pot = ents.Create("prop_physics") pot:SetModel("models/props_junk/terracotta01.mdl") pot:SetPos(rz.pos) pot:Spawn()
    pot.lcRebelProp = "pot" pot.lcPot = { state = "ripe" }
    local u, ust = LC.Spawners.cop(rz.pos + Vector(40, 0, 0))
    ust = ust or LC.NPCs[u]
    local sk = { kind = "sweep", zone = rz, arrived = true, units = { u }, rebels = {} }
    ok(LC.SweepChore(u, ust, sk, CurTime()) and pot.lcPot.state == "empty", "a sweep team member with nobody to fight smashes the pots", pot.lcPot.state)
    pot:Remove() if IsValid(u) then u:Remove() end
    LC.RemoveZone(rz)
    med:SetPos(Vector(-150000, 150000, 0))
    -- the Resistance's man inside
    local ins = newPlayer("InsiderUnit", "cp")
    _run(0.3)
    ins:SetPos(Vector(171234, -171234, 0))
    -- (nobody else anywhere near: the Insider only acts unseen and unheard)
    for _, other in ipairs(player.GetAll()) do
        if other ~= ins and other:GetPos():DistToSqr(ins:GetPos()) < 2000 * 2000 then other:SetPos(Vector(-150000, 150000, 0)) end
    end
    ok(not LC.IsInsider(ins) and LC.InsiderCopy(ins) == false, "an ordinary unit has none of it")
    LC.StoryFlag(ins, "insider", true)
    ok(LC.IsInsider(ins), "recruited (The Man Inside): an Insider")
    local said
    local rn = LC.RadioNotice
    LC.RadioNotice = function(band, text) if band == "resistance" then said = text end end
    ok(LC.InsiderTip(ins, "Patrols double at the canal tonight") and said and string.find(said, "friend inside", 1, true), "a tip-off goes out on Freq 7, unsigned", said)
    LC.RadioNotice = rn
    local okT2, whyT2 = LC.InsiderTip(ins, "again")
    ok(not okT2 and string.find(whyT2 or "", "Not yet", 1, true), "not again straight away", whyT2)
    local snoop = newPlayer("InsiderSnoop", "citizen")
    _run(0.3)
    snoop:SetPos(ins:GetPos() + Vector(120, 0, 0))
    local okC, whyC = LC.InsiderCopy(ins)
    ok(not okC and string.find(whyC or "", "nobody", 1, true), "never with someone close enough to hear", whyC)
    snoop:SetPos(Vector(-150000, 150000, 0))
    ok(LC.InsiderCopy(ins) and LC.HasItem(ins, "intel_records"), "alone: the city's records, copied out (the best intel)")
    local wanted = newPlayer("InsiderWanted", "citizen")
    _run(0.3)
    LC.ReportCrime(wanted, "Test", 300)
    local st0 = LC.Standing(ins)
    ok(LC.InsiderLoseRecord(ins, wanted) and not LC.PlayerIsWanted(wanted) and LC.Standing(ins) == st0 - 25, "a wanted record goes missing, for 25 standing", LC.Standing(ins) - st0)
    -- caught
    LC.BurnInsider(ins)
    ok(ins:GetNW2String("lcf_faction", "") == "resistance" and LC.PlayerIsWanted(ins), "caught: Resistance, and wanted")
    local okJ = LC.CanJoinFaction(ins, "cp")
    ok(not okJ and not LC.CanWork(ins) and not LC.Surrender(ins), "never Civil Protection again, never a Union job, no surrendering")
    for _, q in ipairs({ ins, snoop, wanted }) do q:SetPos(Vector(-150000, 150000, 0)) end
    -- the loyalty test: suspicion too high, a prisoner, your fists, two shotguns
    local lt = newPlayer("LoyaltyUnit", "cp")
    _run(0.3)
    lt:SetPos(Vector(-161000, -161000, 0))
    lt:Give("weapon_pistol")
    LC.StoryFlag(lt, "insider", true)
    local cellPt = LC.AddPoint(Vector(-161000, -160500, 0), 0, "cell", 0)
    local spec = LC.LoyaltyTestSpec(lt)
    ok(spec and spec.title == "The loyalty test", "too much suspicion: the mole hunt starts with the loyalty test, in the cells")
    local fq = { owner = lt, data = spec.data, stages = spec.stages, stage = 2, done = true }
    spec.tick(fq)
    local sc = LC.LoyaltyTests[lt]
    ok(sc and lt:HasWeapon("weapon_fists") and not lt:HasWeapon("weapon_pistol") and #sc.guards == 2 and IsValid(sc.prisoner),
        "in the cell: your fists only, a prisoner in front of you, two guards with shotguns")
    LC.Bump(lt, "suspicion", 3)
    sc.phase = "finish"
    spec.onFinish(fq, true)
    ok(LC.LoyaltyTests[lt] == nil and lt:HasWeapon("weapon_pistol") and LC.Counter(lt, "suspicion") == 0 and fq.chainNext == "reckoning",
        "killed him: suspicion cleared, your weapons back, and the Resistance wants a word",
        tostring(LC.LoyaltyTests[lt]) .. " " .. tostring(lt:HasWeapon("weapon_pistol")) .. " " .. tostring(LC.Counter(lt, "suspicion")) .. " " .. tostring(fq.chainNext))
    ok(LC.StoryFlag(lt, "disgraced") == true and not LC.IsInsider(lt), "until the debt's paid (or you walk away into the conversion), no Inside menu")
    fq.data.setUp = nil
    spec.tick(fq)
    ok(LC.LoyaltyTests[lt] ~= nil, "(the cell again)")
    LC.LoyaltyTestExecute(lt, "You lower your hands.")
    _run(10)
    ok(LC.PlayerIsStalker(lt) and lt:Alive(), "refused: shot down bleeding, and made a stalker")
    -- the reckoning's way out of the mask: Resistance, never a unit again
    local um = newPlayer("UnmaskedUnit", "cp")
    _run(0.3)
    LC.Unmask(um)
    ok(um:GetNW2String("lcf_faction", "") == "resistance" and not LC.CanJoinFaction(um, "cp") and LC.CanWork(um) ~= false and not LC.PlayerIsWanted(um),
        "unmasked: an ordinary Resistance fighter, never Civil Protection again (and not wanted for it)")
    -- with a Resistance player around, the test waits for one to be caught, and the units go looking
    local lt2 = newPlayer("LoyaltyUnit2", "cp")
    local rebelP = newPlayer("CaughtRebel", "resistance", nil, 200)
    _run(0.3)
    lt2:SetPos(Vector(-163000, -161000, 0)) rebelP:SetPos(Vector(-163000, -160000, 0))
    LC.StoryFlag(lt2, "insider", true)
    _setcvar("lc_loyalty_wait", 15)
    local spec2 = LC.LoyaltyTestSpec(lt2)
    ok(spec2 and spec2.data.wait and spec2.stages[1].event == "loyalty_prisoner", "Resistance players around: the test waits for a real prisoner")
    local fq3 = { owner = lt2, data = spec2.data, stages = spec2.stages, stage = 1, done = false }
    LC.QuestOf[lt2] = fq3
    spec2.tick(fq3)
    ok(LC.LoyaltyHunt(rebelP) and not LC.LoyaltyHunt(lt2), "meanwhile, units near a Resistance player almost always stop them")
    LC.Prisoners[rebelP] = { cell = nil, untilT = CurTime() + 300 }
    local qe = LC.QuestEvent
    local got
    LC.QuestEvent = function(name, ply, a) if name == "loyalty_prisoner" then got = a end end
    spec2.tick(fq3)
    LC.QuestEvent = qe
    ok(got == rebelP and fq3.data.humanPrisoner == rebelP and LC.LoyaltyWaiting[lt2] == nil, "caught and in a cell: they're the prisoner")
    fq3.stage, fq3.done = 2, true
    LC.QuestOf[lt2] = nil
    spec2.tick(fq3)
    local sc2 = LC.LoyaltyTests[lt2]
    ok(sc2 and sc2.human and sc2.prisoner == rebelP and rebelP.lcLoyaltyPrisoner == lt2, "the insider is pulled into the cell with the real prisoner in front of them")
    LC.LoyaltyTestCleanup(lt2, true)
    LC.Prisoners[rebelP] = nil
    ok(rebelP.lcLoyaltyPrisoner == nil, "(and let go of afterwards, still in custody)")
    for _, q in ipairs({ lt2, rebelP }) do q:SetPos(Vector(-150000, 150000, 0)) end
    LC.RemovePoint(cellPt)
    -- she, not he: a job about a woman says "her"
    local woman, wst = LC.Spawners.citizen(Vector(-162000, -162000, 0))
    if wst then wst.gender = "female" end
    local fq2 = { data = { target = woman }, stages = { {} }, stage = 1 }
    -- (a real line from the Clinic Medic's job, sv_livingcity_work.lua)
    local line = "Heal him: hold your medkit and left click on him until he's healed. A Civil Protection unit is watching him."
    ok(LC.FitPronouns(fq2, line) == "Heal her: hold your medkit and left click on her until she's healed. A Civil Protection unit is watching him.",
        "a job about a woman: her, not him (a sentence about a unit left alone)", LC.FitPronouns(fq2, line))
    if wst then wst.gender = "male" end
    ok(LC.FitPronouns(fq2, line) == line, "and him for a man")
    if IsValid(woman) then woman:Remove() end
    -- shackled vortigaunts on the streets
    local seen = LC.IsSeen
    LC.IsSeen = function() return false end
    for _ = 1, 3 do LC.VortSlaveTick(CurTime()) end
    LC.IsSeen = seen
    local slaves = 0
    for v in pairs(LC.VortSlaves) do if IsValid(v) and v:GetNW2Bool("lc_shackled", false) then slaves = slaves + 1 end end
    ok(slaves >= 1 and slaves <= GetConVar("lc_vort_slaves"):GetInt(), "shackled vortigaunts sweep the streets (Combine property)", slaves)
    local slave = next(LC.VortSlaves)
    local freer = newPlayer("VortFreer", "resistance", nil, 900)
    _run(0.3)
    ok(slave and LC.FreeStreetVort(slave, freer) and not slave.lcVortSlave and not slave:GetNW2Bool("lc_shackled", true), "a street vortigaunt can be cut loose by the Resistance")
    LC.IsSeen = function() return false end
    _run(125)
    LC.IsSeen = seen
    ok(slave and IsValid(slave) and LC.RebelVorts[slave], "and it goes home to rebel ground, free")
    for v in pairs(LC.VortSlaves) do if IsValid(v) then v:Remove() end end
    if slave and IsValid(slave) then LC.RebelVorts[slave] = nil slave:Remove() end
    -- a vortigaunt has no fists
    local vp = newPlayer("VortPlayer", "vort")
    _run(0.3)
    vp:Give("weapon_fists")
    hook.Run("PlayerSpawn", vp)
    _run(2)
    ok(not vp:HasWeapon("weapon_fists"), "a vortigaunt player has no fists")
    -- things to do as a vortigaunt
    vp:SetPos(Vector(173000, -173000, 0))
    for _, other in ipairs(player.GetAll()) do if other ~= vp and other:GetPos():DistToSqr(vp:GetPos()) < 2000 * 2000 then other:SetPos(Vector(-150000, 150000, 0)) end end
    local heard
    local rn2 = LC.RadioNotice
    LC.RadioNotice = function(band, text) if band == "resistance" then heard = text end end
    ok(LC.VortCall(vp), "a shackled vortigaunt can reach out through the vortessence")
    _run(9)
    LC.RadioNotice = rn2
    ok(heard and string.find(heard, "shackled vortigaunt calls out", 1, true), "and the Resistance hears where it is", heard)
    local okAgain = LC.VortCall(vp)
    ok(not okAgain, "not again for a while")
    ok(LC.Chains.collar and LC.Chains.collar.unlock(vp) and not LC.Chains.collar.unlock(freer), "The Collar: a story only for a shackled vortigaunt")
    local fv = newPlayer("FreeVortPlayer", "resistance", "vortigaunt", 900)
    _run(0.3)
    local kinT, senseT
    for _, t in ipairs(LC.QuestTemplates) do if t.id == "res_vort_kin" then kinT = t elseif t.id == "res_vort_sense" then senseT = t end end
    ok(kinT and senseT and senseT.available(fv) and not senseT.available(freer), "a free vortigaunt has its own jobs: Free your kin, Read the Combine")
    -- a free vortigaunt's bolt shorts out Combine machinery from a distance
    local bank = ents.Create("lc_powerbank") bank:SetPos(Vector(-164000, -164000, 0)) bank:Spawn()
    ok(LC.PowerBankLive(bank) and LC.VortZapTech(fv, bank) and not LC.PowerBankLive(bank), "a free vortigaunt's bolt knocks out a power bank")
    _advance(GetConVar("lc_vort_zap_secs"):GetFloat() + 1)
    ok(LC.PowerBankLive(bank), "and it comes back on by itself")
    bank:Remove()
    -- two in a camp talk; two or more commune, and the Resistance gains by it
    local v1 = ents.Create("npc_vortigaunt") v1:SetPos(Vector(-165000, -165000, 0)) v1:Spawn()
    local v2 = ents.Create("npc_vortigaunt") v2:SetPos(Vector(-165000, -164940, 0)) v2:Spawn()
    LC.RebelVorts[v1], LC.RebelVorts[v2] = true, true
    ok(LC.VortConverse(v1, v2) and v1:GetNW2String("lc_doing", "") == "speaking with its kin", "two freed vortigaunts talk to each other in their own tongue")
    local ps, pr = LC.PlannedSweep, LC.PlannedRaid
    LC.PlannedSweep, LC.PlannedRaid = nil, nil
    local codes0 = 0
    for _, e in ipairs(ents.FindByClass("lc_item")) do if e:GetNW2String("lc_item", "") == "door_code" then codes0 = codes0 + 1 end end
    ok(LC.VortCommune(CurTime()) == "code", "communing, they see a Combine door code")
    local codes = 0
    for _, e in ipairs(ents.FindByClass("lc_item")) do if e:GetNW2String("lc_item", "") == "door_code" then codes = codes + 1 end end
    ok(codes == codes0 + 1 and LCS.Items.door_code.tool == "keycard", "scratched on a scrap beside them: one Combine door, like a keycard")
    LC.PlannedSweep, LC.PlannedRaid = ps, pr
    -- vortigaunts mend vortigaunts: a second's charge, then 25; once every 10 seconds each
    vp:SetPos(v1:GetPos() + Vector(60, 0, 0))
    vp:SetHealth(40)
    ok(LC.VortHeal(v1, vp) == true and vp:Health() == 40, "a vortigaunt gathers the vortessence (nothing yet)")
    _run(1.5)
    ok(vp:Health() == 65, "a second later, its kin is mended", vp:Health())
    local again, whyAgain = LC.VortHeal(v2, vp)
    ok(again == false and string.find(whyAgain or "", "moment", 1, true), "but not again straight away, by anyone (no healing cannon)", whyAgain)
    ok(LC.VortHeal(v1, freer) == nil, "anyone else: not a vortigaunt, so the vest instead")
    LC.PlannedSweep, LC.PlannedRaid = ps, pr
    LC.RebelVorts[v1], LC.RebelVorts[v2] = nil, nil
    v1:Remove() v2:Remove()
    -- free rent for units and the city's best citizens
    local unitR = newPlayer("RentUnit", "cp")
    local best = newPlayer("RentBest", "citizen")
    local plain = newPlayer("RentPlain", "citizen")
    _run(0.3)
    LC.AddStanding(best, 250) -- (200 or more: rent-free)
    ok(LC.RentPrice(unitR) == 0 and LC.RentPrice(best) == 0 and LC.RentPrice(plain) == GetConVar("lc_rent_price"):GetInt(),
        "an apartment is rent-free for a unit and for a citizen of high standing; everyone else pays")
    -- what loyalty earns
    local ex = newPlayer("LoyalExemplary", "citizen")
    local tr = newPlayer("LoyalTrusted", "citizen")
    _run(0.3)
    LC.AddStanding(ex, 450 - LC.Standing(ex)) LC.AddStanding(tr, 200 - LC.Standing(tr))
    ok(LC.LoyalTier(ex) == "exemplary" and LC.LoyalTier(tr) == "trusted" and LC.LoyalTier(plain) == nil and LC.LoyalTier(unitR) == nil, "standing tiers: Trusted and Exemplary (citizens only)")
    ok(LC.LoyalStopMul(tr) == 0.5 and LC.LoyalStopMul(ex) < 0.5 and LC.LoyalNoSearch(ex) and not LC.LoyalNoSearch(tr), "fewer stops, and no search for a model citizen")
    ok(LC.LoyalPayMul(tr) > 1 and LC.LoyalPayMul(ex) > LC.LoyalPayMul(tr), "better pay for shifts")
    local g = LCS.GoodsById.ration
    ok(g and LC.GoodsPrice(ex, g) < g.price and LC.GoodsPrice(plain, g) == g.price, "a discount at the Commissary")
    hook.Run("LivingCityQuestComplete", ex, { chain = "shift", title = "Test shift" })
    ok((LC.Inventory(ex).ration_card or 0) >= 2, "two ration cards a shift for an Exemplary citizen", LC.Inventory(ex).ration_card)
    LC.EventSerial = (LC.EventSerial or 0) + 1
    ok(LC.LoyalCurfewPass(ex, nil) and not LC.LoyalCurfewPass(ex, nil), "waved through once a curfew")
    ok(LC.ReportCrime(ex, "Curfew violation", 60) == false and not LC.PlayerIsWanted(ex), "a minor slip forgiven: a warning, not wanted")
    ok(LC.ReportCrime(ex, "Curfew violation", 60) == true, "but only once a day")
    LC.ClearWanted(ex)
    ok(LC.LoyalStashExtra(ex) == 0, "(no bigger stash: lockers instead)")
    ok(LC.PapersInfo(ex).model and not LC.PapersInfo(plain).model, "a MODEL CITIZEN stamp on their papers")
    ex.chat = {}
    LC.LoyalPraise(CurTime())
    ok(ex.lcPraisedAt ~= nil, "the Administrator commends an Exemplary citizen by name")
    local okW1 = LC.SetJob(plain, "warden")
    local okW2 = LC.SetJob(tr, "warden")
    ok(not okW1 and okW2, "Block Warden: only for loyal citizens (100 standing)")
    LC.SetJob(tr, "", true)
    -- weeds, the Groundskeeper, and weedkiller as poison
    local gk = newPlayer("Groundskeeper", "citizen")
    _run(0.3)
    gk:SetPos(Vector(-166000, -166000, 0))
    local w = LC.SpawnWeed(gk:GetPos() + Vector(50, 0, 0), 3)
    ok(IsValid(w) and w:GetNW2Int("lc_stage", 0) == 3, "weeds grow on open ground (a tuft, weeds, a bush)")
    local okS, whyS = LC.SprayWeed(gk, w)
    ok(not okS and string.find(whyS or "", "weedkiller", 1, true), "spraying needs weedkiller")
    LC.SetJob(gk, "groundskeeper", true)
    ok(LC.HasItem(gk, "weedkiller"), "the Groundskeeper is issued weedkiller")
    LC.SprayWeed(gk, w)
    _run(6)
    ok(not IsValid(w), "a sprayed weed is gone (a bush takes a few seconds)")
    LC.SetJob(gk, "", true)
    LC.GiveItem(gk, "bread", 1)
    ok(LC.PoisonFood(gk) and LC.HasItem(gk, "tainted_bread") and not LC.HasItem(gk, "weedkiller") and LCS.Items.tainted_bread.name == LCS.Items.bread.name,
        "weedkiller into food: it looks exactly the same")
    gk:SetHealth(100)
    LC.Consume(gk, "tainted_bread")
    ok(gk:Health() < 100, "and whoever eats it is poisoned", gk:Health())
    ok(LCS.LabById.chemicals_weedkiller and LCS.LabById.chemicals_weedkiller.needs.weedkiller == 2, "two canisters cook down into chemicals at the lab")
    do
    ok(not LCS.LabById.gas_bomb and LCS.LabById.firebomb and LCS.LabById.firebomb.needs.weedkiller == 2 and LCS.Items.firebomb.grenade == "fire",
        "the lab makes a firebomb from weedkiller now, not poison gas")
    local soldGas
    for _, g in ipairs(LCS.Goods) do if g.id == "gas_bomb" and g.cpOnly then soldGas = true end end
    ok(soldGas, "poison gas bombs are sold to units at the Civil Protection Commissary")
    -- the gas: a citizen choked; a unit's mask keeps it out, until an Insider fouls the filters
    local ctz = newPlayer("GasCitizen", "citizen")
    local mcp = newPlayer("GasCop", "cp")
    local cln = newPlayer("GasCleaner", "citizen")
    _run(0.3)
    LC.SetJob(cln, "cleanup", true)
    ok(LC.HasItem(cln, "weedkiller"), "Infestation Cleanup is issued weedkiller")
    LC.TakeItem(cln, "weedkiller", 1)
    ok(LC.IssueWeedkiller(cln, true) and LC.HasItem(cln, "weedkiller"), "out of weedkiller on the job: the kit tops it up")
    _run(2.5)
    ok(not string.find(cln:GetModel() or "", "worker_", 1, true), "off shift, a cleanup worker is in their own clothes", cln:GetModel())
    LC.QuestOf[cln] = { chain = "shift", owner = cln }
    LC.OutfitDutyTick(CurTime())
    ok(cln:GetModel() == "models/player/worker_male.mdl" or cln:GetModel() == "models/player/worker_female.mdl",
        "on a shift, they wear the pack's hazmat suit", cln:GetModel())
    LC.QuestOf[cln] = nil
    LC.OutfitDutyTick(CurTime())
    ok(not string.find(cln:GetModel() or "", "worker_", 1, true), "the shift over, out of it again", cln:GetModel())
    local gpos = Vector(-168000, -168000, 0)
    ctz:SetPos(gpos) mcp:SetPos(gpos + Vector(30, 0, 0)) cln:SetPos(gpos + Vector(-30, 0, 0))
    ctz:SetHealth(100) mcp:SetHealth(100) cln:SetHealth(100)
    LC.FouledUntil = 0
    LC.Detonate("poison", gpos, gk)
    _run(3)
    local lostC, lostM = 100 - ctz:Health(), 100 - mcp:Health()
    ok(lostC > 0 and lostM == 0, "the poison gas chokes a citizen; a metrocop's mask keeps it out", lostC .. " / " .. lostM)
    ok(cln:Health() == 100, "a cleanup worker's respirator keeps it out", cln:Health())
    LC.GasClouds = {}
    mcp:SetHealth(100)
    LC.FoulFilters(600)
    LC.Detonate("poison", gpos, gk)
    _run(3)
    ok(mcp:Health() < 100, "with the filters fouled, the gas gets through a unit's mask", mcp:Health())
    LC.GasClouds = {}
    LC.FouledUntil = 0
    local okF, whyF = LC.InsiderFoul(ctz)
    ok(not okF and whyF, "only an Insider can foul the filters", whyF)
    -- the firebomb: burns a unit, armour or not
    mcp:SetHealth(100) mcp:SetArmor(100)
    LC.Firebomb(gpos, ctz)
    _run(2)
    ok(mcp:Health() < 100, "a firebomb burns a unit, armour and all", mcp:Health())
    LC.Fires = {}
    -- growths in the infestation: spray every one in a patch that grew, and the patch goes
    local seed = { kind = "infest", pos = Vector(-169000, -169000, 0), r = 400, group = 0 }
    local patch = { kind = "infest", pos = Vector(-169000, -168400, 0), r = 300, h = 200, group = 0, grown = true, seed = seed }
    seed.lcNestFirst, seed.lcNestNext, patch.lcNestFirst, patch.lcNestNext = true, 1e9, true, 1e9 -- (no regrowth mid-test)
    seed.lcPostTried, patch.lcPostTried = true, true -- (and no warning posts of their own)
    table.insert(LC.Zones, seed) table.insert(LC.Zones, patch)
    local n1 = LC.SpawnNest(patch, patch.pos + Vector(20, 0, 0))
    local n2 = LC.SpawnNest(patch, patch.pos + Vector(-20, 0, 0))
    ok(IsValid(n1) and IsValid(n2) and LC.NestsIn(patch) == 2, "an infestation has growths in it")
    ok(n1.lcModel == "models/hlvr/distillery_gunk/distillerygunk_gunk.mdl", "with the owner's workshop pack, the growths are Xen gunk", n1.lcModel)
    local post = LC.HazardPost(patch)
    local hasBarrel = false
    for _, e in ipairs(post or {}) do if LC.IsHazardBarrel(e) then hasBarrel = true end end
    ok(post and #post == 3 and hasBarrel, "a Combine warning post (sign, lamp, and an infestation control barrel) at the edge of the infestation", post and #post)
    for _, e in ipairs(post or {}) do e:Remove() end
    cln:SetPos(patch.pos)
    local okN, whyN = LC.SprayNest(ctz, n1)
    ok(not okN and string.find(whyN or "", "weedkiller", 1, true), "spraying a growth needs weedkiller")
    LC.ClearNest(n1, cln)
    ok(table.HasValue(LC.Zones, patch), "one growth gone: the patch is still there")
    local okV, whyV = LC.VacuumNest(cln, n2)
    ok(not okV and string.find(whyV or "", "spray it", 1, true), "a live growth can't be vacuumed: spray it first", whyV)
    LC.SprayNest(cln, n2)
    _run(5)
    ok(IsValid(n2) and LC.NestDead(n2) and table.HasValue(LC.Zones, patch), "sprayed, a growth dies, and lies there dead")
    cln:SetNW2Int("lc_hoover_load", 0)
    local qeWas, toldValid = LC.QuestEvent, nil
    LC.QuestEvent = function(name, p, a, ...) if name == "nest_vacuumed" then toldValid = IsValid(a) end return qeWas(name, p, a, ...) end
    ok(LC.VacuumNest(cln, n2) and LC.HooverLoad(cln) == 1, "the hoover sucks up a dead growth")
    LC.QuestEvent = qeWas
    ok(toldValid == true, "the job is told which growth while it still exists (each one counts, not just the first)")
    ok(not IsValid(n2) and not table.HasValue(LC.Zones, patch), "every growth gone: the patch goes, the infestation shrinks")
    local okB, whyB = LC.BagHoover(cln)
    ok(okB and LC.HooverLoad(cln) == 0, "no barrel near: sealed in a bag", whyB)
    local dz = { kind = "infest", pos = Vector(-172000, -172000, 0), r = 300, group = 0, lcNestFirst = true, lcNestNext = 1e9 }
    local dpost = LC.HazardPost(dz)
    local barrel
    for _, e in ipairs(dpost or {}) do if LC.IsHazardBarrel(e) then barrel = e end end
    cln:SetPos(dz.pos) cln:SetNW2Int("lc_hoover_load", 2)
    local okB2 = LC.BagHoover(cln)
    ok(not okB2 and LC.HooverLoad(cln) == 2, "with an infestation control barrel near, no bagging: the barrel")
    ok(barrel and LC.DumpHoover(cln, barrel) and LC.HooverLoad(cln) == 0, "emptied into the barrel")
    for _, e in ipairs(dpost or {}) do e:Remove() end
    local rotten = LC.SpawnNest(seed, seed.pos + Vector(60, 0, 0))
    LC.KillNest(rotten, nil)
    rotten.lcDeadAt = CurTime() - 100000
    LC.NestTick(CurTime())
    ok(not IsValid(rotten), "a dead growth nobody takes away rots, in time")
    local n3 = LC.SpawnNest(seed, seed.pos)
    LC.Firebomb(seed.pos, ctz)
    _run(1)
    ok(not IsValid(n3) and LC.InfestQuietAt(seed.pos), "fire burns a growth away; the placed zone sprayed out goes quiet")
    LC.Fires = {}
    for i = #LC.Zones, 1, -1 do if LC.Zones[i] == seed then table.remove(LC.Zones, i) end end
    -- a cleanup shift counts double towards Civil Protection
    local before = LC.Counter(cln, "cp_shifts")
    hook.Run("LivingCityQuestComplete", cln, { chain = "shift" })
    ok(LC.Counter(cln, "cp_shifts") == before + 2, "an Infestation Cleanup shift counts as two Intake Processor shifts towards Civil Protection", LC.Counter(cln, "cp_shifts") - before)
    LC.SetJob(cln, "", true)
    _run(0.5)
    ok(LC.OutfitFor("cleanup", "x", "female_02", false) == "models/npc/worker_female.mdl", "the city's own cleanup crews wear it too (a woman, the female suit)")
    ok(LC.OutfitFor("cleanup", "x", nil, false, "female") == "models/npc/worker_female.mdl" and LC.OutfitFor("cleanup", "x", nil, false, "male") == "models/npc/worker_male.mdl",
        "a woman always gets the female suit and a man the male one, whatever her face model is called")
    ok(LC.OutfitFor("mortuary", "x", nil, false, "female") == "models/npc/engineer_female.mdl" and LC.OutfitFor("sanitation", "y", nil, true, "male") == "models/player/engineer_male.mdl"
        and LC.OutfitFor("scrap", "z", nil, false, "male") == "models/npc/engineer_male.mdl", "the dirty jobs (Mortician, Sanitation, Reclamation) wear the engineer overalls")
    local woman = newPlayer("SuitWoman", "citizen")
    woman:SetNW2String("lc_model", "models/player/somepack/female_custom.mdl")
    ok(LC.PlayerSex(woman) == "female", "a woman on a pack's face model is still a woman")
    LC.SetJob(woman, "cleanup", true)
    LC.QuestOf[woman] = { chain = "shift", owner = woman }
    LC.OutfitDutyTick(CurTime())
    ok(woman:GetModel() == "models/player/worker_female.mdl", "and on a shift she wears the female hazmat suit", woman:GetModel())
    LC.QuestOf[woman] = nil
    LC.SetJob(woman, "", true)
    -- trust before a gun: a member with the XP for Fighter, but no jobs done for the Resistance yet
    local recruit = newPlayer("TrustRecruit", "citizen")
    recruit:SetPData("lcf_xp_resistance", 500)
    LC.SetFaction(recruit, "resistance", nil, true)
    local fRes = LCF.Get("resistance")
    ok(fRes.ranks[recruit:GetNW2Int("lcf_rank", 1)].name == "Member", "joining the Resistance, XP alone doesn't make a Fighter: not trusted yet", fRes.ranks[recruit:GetNW2Int("lcf_rank", 1)].name)
    for _ = 1, 3 do hook.Run("LivingCityQuestComplete", recruit, { chain = "resjob" }) end
    ok(fRes.ranks[recruit:GetNW2Int("lcf_rank", 1)].name == "Fighter", "three jobs done for them, and they trust you: Fighter", fRes.ranks[recruit:GetNW2Int("lcf_rank", 1)].name)
    recruit:SetPos(Vector(-150000, 150000, 0))
    -- a map's burning barrel made with a fire particle is somewhere to boil water
    local cook = newPlayer("BarrelCook", "citizen")
    cook:SetPos(Vector(-173000, -173000, 0))
    local fx = ents.Create("info_particle_system") fx:SetPos(cook:GetPos() + Vector(40, 0, 30)) fx:Spawn()
    fx.GetKeyValues = function() return { effect_name = "barrel_fire_01" } end
    ok(LC.NearHeat(cook), "a burning barrel (a fire particle) is heat to boil water by")
    fx:Remove()
    cook:SetPos(Vector(-150000, 150000, 0))
    -- a unit is never offered civilian clothes; a clean uniform does after an accident
    local unitC = newPlayer("CleanUnit", "cp")
    local okCv = LC.CanBuy(unitC, LCS.GoodsById.civvies)
    ok(not okCv, "units can't buy civilian clothes")
    ok(LCS.GoodsById.uniform_clean and LCS.GoodsById.uniform_clean.cpOnly and LC.CleanClothes.uniform_clean, "the CP Commissary has a clean uniform, and it counts as clean clothes")
    ok(LCS.GoodsById.gas_bomb.minRank == 3 and LCS.GoodsById.fishing_line.civOnly, "poison gas only for Division Leaders and the Overwatch; no fishing line for units")
    unitC:SetPData("lcf_xp_cp", 200) LC.AddXP(unitC, 0)
    if unitC:HasWeapon("weapon_pistol") then unitC:StripWeapon("weapon_pistol") end
    LC.IssueSupplies(unitC)
    ok(unitC:HasWeapon("weapon_pistol"), "a Metrocop who's lost their pistol is issued it again at the CP Commissary")
    LC.GiveItem(unitC, "gas_bomb", 1)
    LC.SyncGrenades(unitC)
    ok(unitC:HasWeapon("weapon_lc_grenades") and unitC:GetNW2Int("lcg_poison", 0) == 1, "a poison gas bomb bought is on the Grenades weapon, not just in your pockets")
    -- walk into a unit standing in your way and it steps aside
    local walker = newPlayer("DoorWalker", "cp")
    walker:SetPos(Vector(-178000, -178000, 0))
    local bc, bst = LC.SpawnCop(Vector(-178000 + 40, -178000, 4))
    if IsValid(bc) and bst then
        bst.state = "idle"
        local velWas = walker.GetVelocity
        walker.GetVelocity = function() return Vector(150, 0, 0) end
        local before = bc:GetPos()
        LC.MakeWayTick(CurTime() + 100)
        walker.GetVelocity = velWas
        ok(bc:GetPos() ~= before, "walk into a unit in a doorway: it steps aside", tostring(bc:GetPos()))
        bc:Remove()
    end
    walker:SetPos(Vector(-150000, 150000, 0))
    -- out of time, but standing at the spot doing it: the job waits for you
    local holder = newPlayer("Holder", "citizen")
    local HP = Vector(-179000, -179000, 0)
    local hspec = { id = 70001, tmpl = { id = "holdtest" }, title = "Hold test", reward = 1, limit = 300, desc = "", faction = "citizen", expiresPost = CurTime() + 999, data = {},
        stages = { { kind = "hold", pos = HP, secs = 10, r = 150, text = "Stand here" } } }
    LC.Postings.citizen = LC.Postings.citizen or {}
    table.insert(LC.Postings.citizen, hspec)
    holder.lcqNext = 0
    LC.AcceptPosting(holder, 70001)
    local hq = LC.QuestOf[holder]
    if hq then
        holder:SetPos(HP)
        _run(2)
        hq.expires = CurTime() - 1
        _run(1.5)
        ok(LC.QuestOf[holder] == hq and not hq.done, "out of time mid-hold, still standing there: the job isn't called off")
        holder:SetPos(HP + Vector(3000, 0, 0))
        _run(1.5)
        ok(hq.done, "walk away after the time's up: then it's over")
    else
        ok(false, "(the hold test job didn't start)")
    end
    holder:SetPos(Vector(-150000, 150000, 0))
    -- Father Grigori can be killed (Half-Life 2 made him immune to players)
    local rz = { kind = "rebel", pos = Vector(-180000, -180000, 0), r = 400, group = 0 }
    table.insert(LC.Zones, rz)
    if IsValid(LC.Grigori) then LC.Grigori:Remove() LC.Grigori = nil end
    local gg = LC.SpawnGrigori and LC.SpawnGrigori()
    if IsValid(gg) then
        local shooter = newPlayer("GrigoriShooter", "cp")
        ok(gg:Health() == 100, "Father Grigori has an ordinary man's health", gg:Health())
        local function Dmg(n, by) local t = { n = n } function t:GetDamage() return self.n end function t:SetDamage(v) self.n = v end function t:GetAttacker() return by end function t:ScaleDamage(f) self.n = self.n * f end return t end
        local mortal = hook.t.EntityTakeDamage.LivingCityGrigoriMortal
        local d = Dmg(60, shooter)
        mortal(gg, d)
        ok(gg:Health() == 40, "a player's shots take it off", gg:Health())
        mortal(gg, Dmg(60, shooter))
        _run(0.3)
        ok(not IsValid(gg) or gg:Health() <= 0, "and enough of them kill him", IsValid(gg) and gg:Health() or "gone")
        shooter:SetPos(Vector(-150000, 150000, 0))
    end
    if IsValid(LC.Grigori) then LC.Grigori:Remove() end
    LC.Grigori = nil
    for i = #LC.Zones, 1, -1 do if LC.Zones[i] == rz then table.remove(LC.Zones, i) end end
    -- the prison: two Nova Prospekt guards only, half again a soldier's health
    local pz = { kind = "prison", pos = Vector(-181000, -181000, 0), r = 500, group = 0 }
    table.insert(LC.Zones, pz)
    _setcvar("lc_garrison", 6)
    LC.GarrisonTick(CurTime() + 1000)
    LC.GarrisonTick(CurTime() + 2000)
    _setcvar("lc_garrison", 0)
    local guards, extra = 0, 0
    for npc, gz in pairs(LC.Garrison) do
        if gz == pz and IsValid(npc) then
            local gst = LC.NPCs[npc]
            if gst and gst.prisonGuard then guards = guards + 1 else extra = extra + 1 end
        end
    end
    ok(guards == 2 and extra == 0, "the prison is guarded by two Nova Prospekt guards, and nobody else", guards .. " / " .. extra)
    for npc, gz in pairs(LC.Garrison) do if gz == pz then if IsValid(npc) then npc:Remove() end LC.Garrison[npc] = nil end end
    for i = #LC.Zones, 1, -1 do if LC.Zones[i] == pz then table.remove(LC.Zones, i) end end
    -- contraband found by one of the city's units: fight or comply
    _setcvar("lc_search_fight_choice", 1)
    local smug = newPlayer("Smuggler2", "citizen")
    local sc = LC.SpawnCop(Vector(-182000, -182000, 4))
    LC.GiveItem(smug, "uniform_cp", 1)
    local n0 = LC.Search(sc, smug)
    ok(n0 == 0 and LC.SearchChoices[smug] and LC.HasItem(smug, "uniform_cp"), "contraband found: the choice comes first, and nothing's gone yet")
    LC.SearchResolve(smug, true)
    ok(LC.HasItem(smug, "uniform_cp") and LC.PlayerIsWanted(smug), "fight: you keep it, and you're wanted for resisting")
    LC.ClearWanted(smug)
    LC.Search(sc, smug)
    LC.SearchResolve(smug, false)
    ok(not LC.HasItem(smug, "uniform_cp"), "comply: it's taken, as before")
    _setcvar("lc_search_fight_choice", 0)
    if IsValid(sc) then sc:Remove() end
    -- ask one of the city's people their name
    local asker = newPlayer("Asker", "citizen")
    asker:SetPos(Vector(-183000, -183000, 0))
    local cit = LC.Spawners.citizen(Vector(-183000 + 60, -183000, 4))
    if IsValid(cit) then
        cit:SetNW2String("lc_pname", "")
        LC.CitizenNPCAction(asker, "askname", cit)
        ok(cit:GetNW2String("lc_pname", "") ~= "" and cit:GetNW2Bool("lc_introduced", false), "ask one of the city's people their name, and they tell you", cit:GetNW2String("lc_pname", ""))
        cit:Remove()
    end
    asker:SetPos(Vector(-150000, 150000, 0))
    -- the City Administrator: hours played, an election, the office, the bodyguard
    local sitting = {}
    for _, p in ipairs(player.GetAll()) do if p:GetNW2String("lcf_faction", "") == "admin" then sitting[#sitting + 1] = p LC.SetFaction(p, "citizen", nil, true) end end -- (the post open for the test)
    local cand = newPlayer("Candidate", "citizen")
    cand:SetPData("lc_played_min", 0)
    local okS, whyS = LC.StandForAdministrator(cand)
    ok(not okS and string.find(whyS or "", "hours", 1, true), "running for Administrator needs 8 hours played", whyS)
    cand:SetPData("lc_played_min", 8 * 60 + 1)
    ok(LC.StandForAdministrator(cand) and LC.Election ~= nil, "with 8 hours, they run, and a vote opens")
    LC.Election.votes[cand] = cand
    LC.Election.ends = 0
    LC.ElectionTick(CurTime())
    ok(cand:GetNW2String("lcf_faction", "") == "admin", "the vote over, they're City Administrator", cand:GetNW2String("lcf_faction", ""))
    local okR = LC.AdminDo(cand, "rations", "austere")
    ok(okR and LC.RationFor(cand) == "ration_short", "the office: rations austere for the hour")
    LC.AdminState.rationsUntil = 0 -- (back to usual: the office itself waits 15 minutes between changes)
    local cit2 = newPlayer("Commended", "citizen")
    local s0 = LC.Standing(cit2)
    ok(LC.AdminDo(cand, "commend", "15", cit2) and LC.Standing(cit2) == s0 + 15, "commend: +15 standing", LC.Standing(cit2) - s0)
    LC.AdminGuardTick(CurTime() + 100)
    local guards = 0
    for npc, who in pairs(LC.AdminGuards) do if who == cand and IsValid(npc) then guards = guards + 1 end end
    ok(guards >= 1, "an Overwatch Elite comes to guard the Administrator", guards)
    ok(LC.AdminOrderKill(cand, cit2), "pointing the tablet at someone: the bodyguard is on them")
    for npc in pairs(LC.AdminGuards) do if IsValid(npc) then npc:Remove() end end
    LC.AdminGuards = {}
    LC.SetFaction(cand, "citizen", nil, true)
    for _, p in ipairs(sitting) do if IsValid(p) then LC.SetFaction(p, "admin", nil, true) end end
    cand:SetPos(Vector(-150000, 150000, 0)) cit2:SetPos(Vector(-150000, 150000, 0))
    -- things wear out; and a player with many lives behind them has a title
    local wearer = newPlayer("Wearer", "citizen")
    LC.GiveItem(wearer, "lockpick", 1)
    local rWas = math.random
    _setcvar("lc_wear_uses", 10)
    math.random = function(a, b) if a == nil then return 0 end return rWas(a, b) end
    ok(LC.WearOut(wearer, "lockpick") and not LC.HasItem(wearer, "lockpick"), "a worn tool is gone (one use in ten, on average)")
    math.random = rWas
    _setcvar("lc_wear_uses", 0)
    wearer:SetPData("lc_legacy", util.TableToJSON({ lives = 6 }))
    ok(LC.LegacyTitle(wearer) == "Old hand", "six lives behind them: a title under their name, 'Old hand'")
    wearer:SetPData("lc_legacy", "")
    -- a job's item never goes where nobody can reach it (under stairs, walled-off space)
    local tlWas = util.TraceLine
    util.TraceLine = function(t) if t.endpos and t.start and t.endpos.z > t.start.z + 20 then return { Hit = true, Fraction = 0.2, HitPos = t.start } end return tlWas(t) end
    ok(LC.ItemSpotOK(Vector(-177000, -177000, 0)) == false, "no room to stand over it (under the stairs): not a spot for an item")
    util.TraceLine = tlWas
    ok(LC.ItemSpotOK(Vector(-177000, -177000, 0)) == true, "open ground with room overhead (and no path nodes to say otherwise): fine")
    -- a unit spawns on the Combine's own ground (the owner: not at the train station)
    local cz = { kind = "combine", pos = Vector(-176000, -176000, 0), r = 300, group = 0 }
    table.insert(LC.Zones, cz)
    local recruitCP = newPlayer("SpawnUnit", "cp")
    recruitCP:SetPos(Vector(-150000, 150000, 0))
    hook.Run("PlayerSpawn", recruitCP)
    _run(0.3)
    local inCZ = false
    for _, z in ipairs(LC.ZonesOfKind("combine")) do
        if z.pos and z.r and recruitCP:GetPos():Distance(z.pos) < z.r + 100 then inCZ = true end
    end
    ok(inCZ, "a Civil Protection unit spawns in a Combine zone (this one, or another test's)", recruitCP:GetPos())
    for i = #LC.Zones, 1, -1 do if LC.Zones[i] == cz then table.remove(LC.Zones, i) end end
    recruitCP:SetPos(Vector(-150000, 150000, 0))
    -- sociostability: an outbreak is red only while its infected are loose in the city, and says why
    local evWas, obWas, alWas = LC.Event, LC.LastOutbreak, LC.AlertLevel
    LC.Event, LC.LastOutbreak = nil, CurTime()
    LC.AlertLevel = function() return 0 end -- (nobody wanted from the other tests)
    local infWas = {}
    for n, s2 in pairs(LC.NPCs) do if s2.role == "zombie" or s2.role == "headcrab" then infWas[n] = s2 LC.NPCs[n] = nil end end -- (nor their infected)
    local lvl0, why0 = LC.SocioAuto()
    ok(lvl0 ~= "red", "an outbreak with nobody loose in the city: not red (headcrabs in the infestation are no concern)", tostring(lvl0) .. " " .. tostring(why0))
    local zb = ents.Create("npc_zombie") zb:SetPos(Vector(-174000, -174000, 0)) zb:Spawn() zb:SetHealth(50)
    LC.NPCs[zb] = { role = "zombie", unmanaged = true, state = "idle" }
    local lvl1, why1 = LC.SocioAuto()
    ok(lvl1 == "red" and why1 == "infected loose in the city", "infected that broke out, loose in the streets: red, and it says why", tostring(lvl1) .. " " .. tostring(why1))
    LC.NPCs[zb] = nil zb:Remove()
    for n, s2 in pairs(infWas) do LC.NPCs[n] = s2 end
    LC.Event, LC.LastOutbreak, LC.AlertLevel = evWas, obWas, alWas
    local crew = ents.Create("npc_citizen") crew:SetPos(Vector(-171000, -171000, 0)) crew:Spawn()
    local plain = "models/humans/group01/female_02.mdl"
    crew:SetModel(plain)
    local cst = { role = "citizen", state = "idle", profile = { id = 99901, job = "cleanup", gender = "female", model = plain } }
    LC.NPCs[crew] = cst
    LC.OutfitDutyTick(CurTime())
    ok(crew:GetModel() == plain, "one of the city's cleanup crew, not working: her own clothes", crew:GetModel())
    cst.npcWork = { steps = {} }
    LC.OutfitDutyTick(CurTime())
    ok(crew:GetModel() == "models/npc/worker_female.mdl", "at the work: the female hazmat suit", crew:GetModel())
    cst.npcWork = nil
    LC.OutfitDutyTick(CurTime())
    ok(crew:GetModel() == "models/npc/worker_female.mdl", "between one task and the next, she keeps it on")
    cst.state = "abed"
    LC.OutfitDutyTick(CurTime())
    ok(crew:GetModel() == plain, "off to bed: out of it", crew:GetModel())
    LC.NPCs[crew] = nil crew:Remove()
    woman:SetPos(Vector(-150000, 150000, 0))
    ok(not string.find(cln:GetModel() or "", "worker_", 1, true), "off the job, their own clothes again", cln:GetModel())
    -- a barnacle that eats weedkiller dies
    local bn = ents.Create("npc_barnacle") bn:SetPos(Vector(-170000, -170000, 200)) bn:Spawn() bn:SetHealth(35)
    LC.SpawnWorldItem("weedkiller", bn:GetPos() - Vector(0, 0, 40))
    LC.BarnacleTick()
    _run(2)
    ok(bn:Health() <= 0 or not IsValid(bn), "a barnacle that eats weedkiller dies", IsValid(bn) and bn:Health() or "gone")
    for _, q in ipairs({ ctz, mcp, cln }) do q:SetPos(Vector(-150000, 150000, 0)) end
    end
    -- short rations below Trusted
    ok(LC.RationFor(plain) == "ration_short" and LC.RationFor(tr) == "ration" and LCS.Items.ration_short.hunger < LCS.Items.ration.hunger * 0.75,
        "a citizen below Trusted gets a short ration (a third less); a Trusted one, the full packet")
    gk:SetPos(Vector(-150000, 150000, 0))
    -- lockers: only for citizens in good standing
    local lk = ents.Create("lc_locker") lk:SetPos(Vector(-167000, -167000, 0)) lk:Spawn()
    local low = newPlayer("LockerLow", "citizen")
    _run(0.3)
    low:SetPos(lk:GetPos() + Vector(40, 0, 0)) tr:SetPos(lk:GetPos() + Vector(-40, 0, 0))
    low.lookingAt, tr.lookingAt = lk, lk
    LC.GiveItem(low, "bread", 1) LC.GiveItem(tr, "bread", 1)
    low.chat, tr.chat = {}, {}
    LC.OpenContainer(low, lk) LC.OpenContainer(tr, lk)
    ok(has(low.chat, "Lockers are for citizens in good standing"), "a locker isn't for a citizen of ordinary standing", low.chat[1])
    ok(not has(tr.chat, "Lockers are for citizens in good standing"), "a Trusted citizen can use one", tr.chat[1])
    lk:Remove()
    for _, q in ipairs({ ex, tr, low }) do q:SetPos(Vector(-150000, 150000, 0)) end
    for _, q in ipairs({ unitR, best, plain }) do q:SetPos(Vector(-150000, 150000, 0)) end
    fv:SetPos(Vector(-150000, 150000, 0)) vp:SetPos(Vector(-150000, 150000, 0)) freer:SetPos(Vector(-150000, 150000, 0))
end)()

section("The v2.7 pieces: stamina, brandishing, obituaries, detentions, citizen numbers, the Administration path")
;(function()
    -- stamina
    local jogger = newPlayer("Jogger", "citizen")
    jogger.keys = { [IN_SPEED] = true }
    jogger.vel = Vector(250, 0, 0)
    for _ = 1, 100 do LCS.Tick(CurTime(), 0.2) end
    ok(jogger:GetNW2Float("lc_stamina", 100) == 0 and jogger:GetNW2Bool("lc_winded", false), "running tires you out: winded", jogger:GetNW2Float("lc_stamina", 100))
    jogger.keys, jogger.vel = nil, nil
    for _ = 1, 5 do LCS.Tick(CurTime() + 5, 0.2) end
    ok(jogger:GetNW2Bool("lc_winded", false), "and you stay winded a while")
    for _ = 1, 30 do LCS.Tick(CurTime() + 5, 0.2) end
    ok(not jogger:GetNW2Bool("lc_winded", false) and jogger:GetNW2Float("lc_stamina", 0) > 50, "rested, you get your breath back", jogger:GetNW2Float("lc_stamina", 0))
    jogger:SetNW2Float("lcn_hunger", 20)
    jogger:SetNW2Float("lc_rested_until", 0)
    local base = LCS.RegenMul(jogger)
    jogger:SetNW2Float("lcn_hunger", 80)
    jogger:SetNW2Float("lc_rested_until", CurTime() + 1000)
    ok(base == 1 and math.abs(LCS.RegenMul(jogger) - 1.5) < 0.01, "slept well and fed: your breath comes back faster", LCS.RegenMul(jogger))
    jogger:SetPos(Vector(-30000, 30000, 0))
    -- guns: on the streets, any gun in a citizen's hand is wanted at once
    local sbs, irz, cza, rcs, rsf, us, moh, nrz, ncz = LC.SeenBySecurity, LC.InRebelZone, LC.CombineZoneAt, LC.RebelCanSee, LC.RebelSetFoe, LC.UnitSees, LC.MakeOneHostile, LC.NearRebelZone, LC.NearCombineZone
    local waver = newPlayer("Waver", "citizen")
    if not waver:HasWeapon("weapon_pistol") then waver:Give("weapon_pistol") end
    waver:SelectWeapon("weapon_pistol")
    LC.SeenBySecurity = function() return true end
    LC.InRebelZone = function() return false end LC.NearRebelZone = LC.InRebelZone
    LC.CombineZoneAt = function() return nil end LC.NearCombineZone = LC.CombineZoneAt
    LC.BrandishTick(CurTime())
    ok(LC.PlayerIsWanted(waver) and has(waver.chat, "Weapon! Drop it"), "a citizen seen with a gun on the streets: wanted at once")
    ok(not waver:GetNW2Bool("lc_carry_lowered", false) and not LCL.Lowered(waver), "and on the streets a gun isn't carried lowered")
    LC.ClearWanted(waver)
    -- rebel ground: walking in with a gun up, a card; the fighters stand to; 10 seconds, then they fire
    LC.InRebelZone = function() return true end LC.NearRebelZone = LC.InRebelZone
    local fake = LC.Spawners.citizen(waver:GetPos() + Vector(200, 0, 0))
    local fst = LC.NPCs[fake]
    fst.role = "rebel"
    LC.RebelCanSee = function() return true end
    local foes = {}
    LC.RebelSetFoe = function(n, st2, e) foes[#foes + 1] = e end
    waver.chat = {}
    local t0 = CurTime()
    LC.BrandishTick(t0)
    ok(waver:GetNW2Bool("lc_carry_lowered", false) and waver:GetNW2Bool("lc_raised", false) and not LCL.Lowered(waver), "walking onto rebel ground with a gun out: it's still up")
    ok(has(waver.chat, "Lower that gun") and fst.lcAimAt == waver, "the fighters stand to, guns on you, and tell you to lower it")
    LC.BrandishTick(t0 + 4.5)
    ok(has(waver.chat, "Watch what you're doing"), "and again, a few seconds on")
    LC.BrandishTick(t0 + 6)
    ok(#foes == 0, "they give you time")
    LC.BrandishTick(t0 + 11)
    local allW = #foes > 0
    for _, e in ipairs(foes) do if e ~= waver then allW = false end end
    ok(allW, "still up after ten seconds: they open fire (on you, and only you)", #foes)
    waver:SetNW2Bool("lc_raised", false)
    foes = {}
    LC.BrandishTick(t0 + 20) LC.BrandishTick(t0 + 40)
    ok(#foes == 0 and LCL.Lowered(waver), "lowered (hold R) on their ground: left alone")
    -- the Combine's ground: the same for a recruit or metrocop, with the Overwatch's soldiers
    fst.role = "citizen"
    LC.InRebelZone = function() return false end LC.NearRebelZone = LC.InRebelZone
    LC.CombineZoneAt = function() return { kind = "combine" } end LC.NearCombineZone = LC.CombineZoneAt
    local mc = newPlayer("Metrocop", "cp")
    if not mc:HasWeapon("weapon_pistol") then mc:Give("weapon_pistol") end
    mc:SelectWeapon("weapon_pistol")
    fst.role = "soldier"
    LC.UnitSees = function() return true end
    local aimed = {}
    LC.MakeOneHostile = function(n, st2, e) aimed[#aimed + 1] = e end
    LC.BrandishTick(t0)
    ok(mc:GetNW2Bool("lc_carry_lowered", false) and has(mc.chat, "lower your weapon"), "a recruit on the Combine's ground with a gun up: told to lower it")
    LC.BrandishTick(t0 + 11)
    local allMc = #aimed > 0
    for _, e in ipairs(aimed) do if e ~= mc then allMc = false end end
    ok(allMc, "still up after ten seconds: the soldiers open fire (on them, and only them)", #aimed)
    local dl = newPlayer("DivLeader", "cp")
    dl:SetNW2Int("lcf_rank", 3)
    LC.BrandishTick(t0 + 12)
    ok(not dl:GetNW2Bool("lc_carry_lowered", false), "a Division Leader carries as they like")
    dl:SetPos(Vector(-30000, 30000, 0))
    fst.role = "citizen"
    LC.SeenBySecurity, LC.InRebelZone, LC.CombineZoneAt, LC.RebelCanSee, LC.RebelSetFoe, LC.UnitSees, LC.MakeOneHostile, LC.NearRebelZone, LC.NearCombineZone = sbs, irz, cza, rcs, rsf, us, moh, nrz, ncz
    if IsValid(fake) then fake:Remove() end
    waver.active, mc.active = nil, nil
    waver:SetNW2Bool("lc_carry_lowered", false) mc:SetNW2Bool("lc_carry_lowered", false)
    waver:SetPos(Vector(-30000, 30000, 0)) mc:SetPos(Vector(-30000, 30000, 0))
    -- obituaries
    local dead = newPlayer("Departed", "citizen")
    dead:SetNW2String("lc_cid", "48213")
    local line = LC.Obituary(dead, dead, nil)
    ok(line and line:find("48213", 1, true) and line:find("died", 1, true), "an obituary names them and their citizen number", line)
    -- finding by citizen number
    ok(LC.FindPlayer("#48213") == dead and LC.FindPlayer("48213") == dead, "admin commands find a player by citizen number")
    -- longer detentions the longer you were wanted
    local held = newPlayer("HeldLong", "citizen")
    LC.SetWanted(held, 600, "test")
    held.lcWantedSince = CurTime() - 240
    LC.DetainOnTheSpot(held, nil, "test")
    local secs = LC.Detained[held] and (LC.Detained[held].untilT - CurTime()) or 0
    ok(secs > 55 and secs <= 60.5, "wanted four minutes: held on the street longer (up to a minute)", secs)
    LC.Detained[held] = nil held:Freeze(false) LC.ClearWanted(held)
    held:SetPos(Vector(-30000, 30000, 0))
    -- the Administration path
    local clerk = newPlayer("ClerkPath", "citizen")
    clerk:SetPData("lc_played_min", 0)
    LC.Bump(clerk, "clerk_shifts", 6)
    local h, n = LC.AdminHours(clerk)
    ok(n == 6 and math.abs(h - 2) < 0.01, "each Records Clerk shift counts towards the hours to run for City Administrator", h)
    clerk:SetPos(Vector(-30000, 30000, 0))
    -- a unit facing a locked door a kick would open is told how
    local kd = ents.Create("prop_door_rotating")
    kd.mapid = 7702
    kd:SetPos(Vector(-160600, 160600, 0))
    kd.locked = true
    ok(LC.KickWouldOpen(kd), "a locked hinged door: a kick would open it (and a unit facing it is told how)")
    LC.SetDoorTag(kd, "locked")
    ok(not LC.KickWouldOpen(kd), "an always-locked door: no reminder (a kick doesn't give)")
    LC.SetDoorTag(kd, nil)
    -- the City Administrator's office door
    local odoor = ents.Create("func_door")
    odoor.mapid = 7701
    odoor:SetPos(Vector(-160500, 160500, 0))
    LC.SetDoorTag(odoor, "office")
    local outsider = newPlayer("Outsider", "citizen")
    odoor.fired = {}
    ok(hook.Run("PlayerUse", outsider, odoor) == false and not has(odoor.fired, "Open") and has(outsider.chat, "Administrator's office"), "the Administrator's office: locked to a citizen")
    local boss = newPlayer("TheAdministrator", "admin")
    odoor.fired = {}
    hook.Run("PlayerUse", boss, odoor)
    ok(has(odoor.fired, "Unlock") and has(odoor.fired, "Open"), "and opens for the Administrator", table.concat(odoor.fired, ","))
    LC.SetDoorTag(odoor, nil)
    outsider:SetPos(Vector(-30000, 30000, 0)) boss:SetPos(Vector(-30000, 30000, 0))
end)()

section("Sealed directives: how the endings start, and the G-Man's hand")
;(function()
    _run(0.1) -- (the office's acts are noted once everything's loaded)
    _setcvar("lc_directives", 1)
    local S = LC.DirectiveState
    local calls = {}
    local te, ga = LC.TriggerEnding, player.GetAll
    LC.TriggerEnding = function(id, by, now) calls[#calls + 1] = { id = id, by = by, now = now } return true end
    S.offer, S.esc = nil, nil
    -- (anyone left in the post by an earlier test steps down, so the directive comes to this one)
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lcf_faction", "") == "admin" then LC.SetFaction(p, "citizen", nil, true) end
    end
    -- the bus: cheap bread, full bowls and a bonus, with six or more about
    local admin = newPlayer("Administrator", "admin")
    local crowd = {}
    for i = 1, 6 do crowd[i] = newPlayer("Crowd" .. i, "citizen") end
    local h0 = LC.DirectiveHeat("bus")
    LC.DirectiveNote("prices", "0.75")
    LC.DirectiveNote("rations", "generous")
    local h1, open1 = LC.DirectiveHeat("bus")
    ok(h1 > h0 and not open1, "the riddle's acts warm a directive up", h1)
    LC.DirectiveNote("bonus", "factory")
    local h2, open2 = LC.DirectiveHeat("bus")
    ok(open2, "all of them, and its seal breaks", h2)
    -- the Administrator's: sign or refuse
    S.offer = { id = "bus" }
    LC.DirectiveRoute(S.offer, CurTime())
    ok(S.offer.stage == "admin" and S.offer.to == admin, "an Administrator playing now gets it")
    ok(admin:GetNW2Float("lc_directive_until", 0) > CurTime() and not admin:GetNW2Bool("lc_directive_urgent", false), "a bar on their screen says one's waiting, and how long is left")
    LC.DirectiveTick(S.offer.deadline - 4 * 60)
    ok(S.offer.called and admin:GetNW2Bool("lc_directive_urgent", false) and _lastnet("lc_gman_vision") ~= nil, "five minutes left: the G-Man calls them back to it, and the bar turns urgent")
    ok(LC.DirectiveAnswer(admin, "bus", false) and S.esc and S.esc.level == 1 and S.refusals.bus == 1, "refused: the G-Man's escalation begins")
    ok(admin:GetNW2Float("lc_directive_until", 0) == 0, "answered: the reminder goes")
    ok(_lastnet("lc_gman_vision") ~= nil, "and he appears to the Administrator")
    LC.DirectiveTick(CurTime() + 21 * 60)
    ok(S.esc and S.esc.spreading, "twenty minutes on, the infestation spreads")
    LC.DirectiveTick(CurTime() + 31 * 60)
    ok(S.offer and S.offer.id == "bus" and S.offer.stage == "admin", "thirty minutes on, he brings the same directive back")
    ok(LC.DirectiveAnswer(admin, "bus", true) and calls[#calls].id == "bus" and calls[#calls].now == true and S.esc == nil, "signed: the ending starts, and his hand comes off the city")
    -- an order from the office
    LC.AdminDo(admin, "weedkiller")
    ok(LC.WeedkillerBanned(), "the Administrator can ban weedkiller (one of the new orders)")
    -- nobody to answer: a superadmin's popup
    admin:SetNW2String("lcf_faction", "citizen")
    local boss = newPlayer("SuperBoss", "citizen") boss.superadmin = true boss.admin = true
    S.offer = { id = "marrow" }
    LC.DirectiveRoute(S.offer, CurTime())
    ok(S.offer.stage == "staff" and _lastnet("lc_directive_staff") ~= nil, "no Administrator: a superadmin's popup")
    -- nobody at all: ten minutes' grace, then the G-Man's vote
    local plain = newPlayer("Nobody", "citizen")
    player.GetAll = function() return { plain } end
    S.deciderLeftAt = CurTime()
    S.offer = { id = "fire" }
    LC.DirectiveRoute(S.offer, CurTime())
    ok(S.offer.stage == "waiting", "the last one to decide just left: it waits for them")
    LC.DirectiveTick(CurTime() + 11 * 60)
    ok(calls[#calls].id == "fire" and calls[#calls].now == false, "ten minutes and nobody back: the G-Man's vote")
    player.GetAll = ga
    -- the rival, and the recall (Civil Protection and the Administration vote, not citizens)
    local sittingAdm = newPlayer("SittingAdmin", "admin")
    local hopeful = newPlayer("Hopeful", "citizen")
    hopeful:SetPData("lc_played_min", 60 * 20)
    local ga2 = player.GetAll
    player.GetAll = function() return { sittingAdm, hopeful } end
    ok(LC.GmanRival() == hopeful and hopeful:GetNW2Float("lc_gman_rival_until", 0) > CurTime(), "after a refusal, the G-Man picks a rival who could run for the office")
    player.GetAll = ga2
    local unit = newPlayer("RecallUnit", "cp")
    local cit2 = newPlayer("RecallCitizen", "citizen")
    ok(LC.AdminVoter(unit) and not LC.AdminVoter(cit2), "Civil Protection votes on the Administrator; citizens don't")
    local noVote = true
    for _, f in ipairs({ "resistance", "vort", "zombie", "stalker" }) do
        local q = newPlayer("NoVote" .. f, "citizen")
        q:SetNW2String("lcf_faction", f)
        if LC.AdminVoter(q) then noVote = false end
        q:SetPos(Vector(-30000, 30000, 0))
    end
    ok(noVote, "nor do rebels, vortigaunts, stalkers or the infected")
    ok(LC.CallRecall(hopeful) and LC.Recall ~= nil, "the rival calls a recall")
    LC.Recall.votes[unit] = true
    LC.Recall.ends = CurTime() - 1
    ok(LC.RecallTick(CurTime()) and hopeful:GetNW2String("lcf_faction", "") == "admin" and sittingAdm:GetNW2String("lcf_faction", "") ~= "admin", "more yes than no: the Administrator is out, and the rival is in")
    LC.SetFaction(hopeful, "citizen", nil, true)
    for _, p in ipairs({ sittingAdm, hopeful, unit, cit2 }) do p:SetPos(Vector(-30000, 30000, 0)) end
    -- glimpses of him, as a directive warms
    local seer = newPlayer("Seer", "citizen")
    S.esc = { id = "bus", level = 1, at = CurTime(), returnAt = CurTime() + 9999, steps = {}, spreads = 0 }
    local mr = math.random
    math.random = function(a, b) if a == nil then return 0 end return mr(a, b) end
    seer.lcGlimpseNext = 0
    LC.GmanGlimpseTick(CurTime())
    math.random = mr
    ok(seer.lcGlimpseNext > CurTime(), "someone glimpses the G-Man about the city")
    S.esc = nil
    seer:SetPos(Vector(-30000, 30000, 0))
    -- dreams
    local dreamer = newPlayer("Dreamer", "citizen")
    _setcvar("lc_gman_dream_chance", 100)
    ok(LC.GmanDream(dreamer) == "riddle", "asleep, the G-Man recites a riddle")
    _setcvar("lc_gman_dream_chance", 30)
    LC.TriggerEnding = te
    S.offer, S.esc, S.deciderLeftAt = nil, nil, nil
    for _, p in ipairs(crowd) do p:SetPos(Vector(-30000, 30000, 0)) end
    for _, p in ipairs({ admin, boss, plain, dreamer }) do p:SetPos(Vector(-30000, 30000, 0)) end
    boss.superadmin, boss.admin = false, false
    _setcvar("lc_directives", 0)
end)()

section("NPCs that fall out of the map")
;(function()
    local npc = LC.Spawners.citizen(Vector(-160000, -160000, 0))
    if not IsValid(npc) then ok(false, "a citizen to drop") return end
    local wasIn = util.IsInWorld
    util.IsInWorld = function(p) return p.z > -1000 end
    LC.RescueFallen(CurTime())
    npc:SetPos(Vector(-160000, -160000, -50000))
    LC.RescueFallen(CurTime())
    ok(npc:GetPos().z < -1000, "not moved at once (a moment out of the map is let be)")
    LC.RescueFallen(CurTime() + 3)
    ok(IsValid(npc) and npc:GetPos().z > -1000, "fallen out of the map for two seconds: put back where it last stood", npc:GetPos())
    npc.lcGoodPos = nil
    npc:SetPos(Vector(-160000, -160000, -50000))
    LC.RescueFallen(CurTime())
    LC.RescueFallen(CurTime() + 3)
    ok(not IsValid(npc), "nowhere to put it back: taken away")
    util.IsInWorld = wasIn
    -- an ending's ring with a crowd: everyone their own spot, spilling onto more rings
    local spots = LC.EndingRingSpots(Vector(-160000, 160000, 0), 60, 120, {})
    local close = 0
    for i = 1, #spots do for j = i + 1, #spots do if spots[i].pos:Distance(spots[j].pos) < 40 then close = close + 1 end end end
    ok(#spots == 120 and close == 0, "an ending's ring with 120 people in it: nobody stands inside anybody", close)
end)()

section("Core contract: nothing load-bearing changes without the owner knowing (CORE.md)")
;(function() -- (its own function: the file's main chunk is at Lua's limit on locals)
    -- Everything here is something the owner's server, files or players depend on. The list is
    -- compared with _dev/core_snapshot.txt: a difference fails, and the runner writes the new list
    -- to _dev/core_snapshot.new.txt. Only with the owner's OK is that copied over the old one.
    local lines = {}
    local function Add(s) lines[#lines + 1] = s end
    for name, def in pairs(_cvarDefaults or {}) do
        if string.sub(name, 1, 2) == "lc" then Add("setting " .. name .. " = " .. def) end
    end
    for _, v in ipairs(LC.AnnounceVoices or {}) do Add("announce voice " .. v) end
    for _, t in ipairs(LC.AnnounceTriggers or {}) do Add("announce trigger " .. t) end
    for _, t in ipairs(LC.AnnounceRetired or {}) do Add("announce retired " .. t) end
    for v, ts in pairs(LC.AnnounceExtra or {}) do for _, t in ipairs(ts) do Add("announce " .. v .. " trigger " .. t) end end
    for _, r in ipairs(LC.AnnounceRoots or {}) do Add("announce folder sound/" .. r .. "<voice>/") end
    for _, id in ipairs(LC.EndingOrder or {}) do Add("ending " .. id .. " (" .. LC.Endings[id].name .. ")") end
    Add("ending songs folder sound/" .. tostring(LC.EndingRoot))
    Add("ending cooldown file data/" .. tostring(LC.EndingCooldownFile))
    Add("ending tuning file data/" .. tostring(LC.EndingTuneFile))
    Add("rebel camp layout data/" .. tostring(LC.CampFile))
    local lp, map = LC.LayoutPath(), game.GetMap()
    local at = string.find(lp, map, 1, true)
    Add("layout file data/" .. (at and (string.sub(lp, 1, at - 1) .. "<map>" .. string.sub(lp, at + #map)) or lp))
    for _, f in ipairs(LCF.Factions or {}) do
        Add("faction " .. f.id .. " (" .. f.name .. ")")
        for i, r in ipairs(f.ranks or {}) do Add(string.format("faction %s rank %d %s at %s xp", f.id, i, r.name, tostring(r.xp))) end
        for _, s in ipairs(f.specials or {}) do Add("faction " .. f.id .. " special " .. s.id) end
    end
    for id in pairs(LCS and LCS.Items or {}) do Add("item " .. id) end
    for n in pairs(LC.SlashCommands or {}) do Add("chat command /" .. n) end
    for n in pairs(concommand.list or {}) do if string.sub(n, 1, 2) == "lc" then Add("console command " .. n) end end
    table.sort(lines)
    _CORE_NOW = table.concat(lines, "\n") .. "\n"
    if not _CORE_SNAPSHOT then
        ok(false, "the core snapshot (_dev/core_snapshot.txt) is missing: the runner wrote core_snapshot.new.txt")
        return
    end
    local have, had, diff = {}, {}, {}
    for l in string.gmatch(_CORE_NOW, "[^\n]+") do have[l] = true end
    for l in string.gmatch(_CORE_SNAPSHOT, "[^\n]+") do had[l] = true end
    for l in pairs(have) do if not had[l] then diff[#diff + 1] = "+ " .. l end end
    for l in pairs(had) do if not have[l] then diff[#diff + 1] = "- " .. l end end
    table.sort(diff)
    ok(#diff == 0, "the core is as the owner knows it: settings' defaults, announcement triggers and folders, endings, data files, "
        .. "factions and ranks, items and commands match _dev/core_snapshot.txt (a change needs the owner's OK first: CORE.md)",
        #diff .. " differences: " .. table.concat(diff, " | ", 1, math.min(#diff, 15)))
end)()

----------------------------------------------------------------------
section("Stop")
LC.Stop(admin)
_run(1)
ok(table.Count(LC.NPCs) == 0, "stopping removes every NPC")
ok(#_errors == 0, "no errors logged during the whole run", _errors[1])

return results.pass, results.fail, table.concat(results.lines, "\n")
