--[[
    Living City: jobs that come with supply drops, and Union work orders that
    pay in materials

      Supply drop    (sv_livingcity_convoy.lua) units get "Guard the supply
                     drop" on their Directives board, the Resistance "Raid the
                     supply drop" on their Operations board.
      Work orders    citizens' Assignments sometimes include odd jobs for the
                     Union whose pay is the offcuts: fix a streetlight (scrap,
                     chemicals), clear rubble (scrap, rags), patch a leaking
                     pipe (chemicals, rags, scrap). A little XP, and materials
                     in your pockets at the end.
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Hold, Count, Narrate, Place, Spot, HideSpots = Q.Goto, Q.Hold, Q.Count, Q.Narrate, Q.Place, Q.Spot, Q.HideSpots

local function T(def)
    def.factions = def.factions or {}
    LC.QuestTemplates[#LC.QuestTemplates + 1] = def
end

-- Hand everyone on the job their share of the materials.
local function PayIn(items, line)
    return function(q, success)
        if not success then return end
        for _, p in ipairs(Q.Members(q)) do
            if IsValid(p) then
                local got = {}
                for id, n in pairs(items) do
                    if LC.GiveOrDrop then LC.GiveOrDrop(p, id, n) else LC.GiveItem(p, id, n) end
                    got[#got + 1] = (n > 1 and (n .. " ") or "") .. string.lower(LCS.Items[id] and LCS.Items[id].name or id)
                end
                table.sort(got)
                p:ChatPrint("[Assignments] " .. line .. " You keep: " .. table.concat(got, ", ") .. ".")
            end
        end
    end
end

------------------------------------------------------------------------
-- Supply drops
------------------------------------------------------------------------

T{
    id = "cp_guardsupply", factions = { cp = true, ota = true }, during = { "supply" }, squad = 8,
    available = function() return LC.Supply ~= nil end, -- (from the moment it's on its way)
    build = function(ply)
        local s = LC.Supply
        if not s then return nil end
        return {
            title = "Guard the supply drop " .. Place(s.pos, ply:GetPos()), reward = 40, limit = 600,
            desc = (s.byAir and "A dropship is setting Union supplies down " or "A convoy is unloading Union supplies ") .. Place(s.pos, ply:GetPos()) .. ". Anticitizens will want them. Nobody touches that crate.",
            stages = { Goto(s.pos, "Get to the supply drop", 400), Hold(s.pos, 150, "Guard the crate until the convoy moves on", 600) },
        }
    end,
}

T{
    id = "res_raidsupply", factions = { resistance = true }, during = { "supply" }, squad = 6, violent = true,
    available = function() return LC.Supply ~= nil end, -- (from the moment it's on its way)
    build = function(ply)
        local s = LC.Supply
        if not s then return nil end
        return {
            title = "Raid the supply drop " .. Place(s.pos, ply:GetPos()), reward = 45, limit = 600,
            desc = (s.byAir and "A Combine dropship is bringing guns, ammunition and medicine down " or "A Combine convoy is unloading guns, ammunition and medicine ") .. Place(s.pos, ply:GetPos()) .. ". Get in, take what you can carry from the open crate, get out.",
            stages = {
                Goto(s.pos, "Get to the supply drop", 500),
                Count("supply_looted", 2, "Take loads from the crate (press E on it)", nil, false),
            },
        }
    end,
}

-- The supply event posts these once the crate is actually down.
hook.Add("LivingCitySupplyDrop", "LivingCitySideJobs", function()
    if LC.PostDirective then
        LC.PostDirective("cp_guardsupply")
        LC.PostDirective("res_raidsupply")
    end
end)

------------------------------------------------------------------------
-- Union work orders that pay in materials
------------------------------------------------------------------------

local RUBBLE = {
    "models/props_debris/concrete_chunk05g.mdl", "models/props_debris/wood_chunk03a.mdl",
    "models/props_junk/rock001a.mdl", "models/props_debris/concrete_chunk03a.mdl",
}

T{
    id = "cit_streetlight", factions = { citizen = true },
    build = function(ply)
        -- a real broken streetlight if there is one (sv_livingcity_propaganda.lua)
        local lamp
        for _, e in ipairs(LC.StreetFixtures and LC.StreetFixtures("lc_streetlight", ply:GetPos(), 3000) or {}) do
            if e:GetNW2Bool("lc_broken", false) then lamp = e break end
        end
        -- the map has streetlights and none are out: nothing to fix
        if not lamp and #LC.EntsOf("lc_streetlight") > 0 then return nil end
        local p = lamp and lamp:GetPos() or Spot(ply, 300, 2000)
        if not p then return nil end
        if lamp then
            local spec = {
                title = "Work order: fix a streetlight", reward = 12, limit = 420,
                desc = "A streetlight is out " .. Place(p, ply:GetPos()) .. ". Rewire it. Keep what's left over.",
                stages = { Goto(p, "Find the dead streetlight", 160), Hold(p, 12, "Rewire it (stay close)", 150) },
                onFinish = PayIn({ scrap = 1, chemicals = 1 }, "The light flickers on."),
            }
            spec.stages[2].onDone = function() if LC.RepairStreetFixture then LC.RepairStreetFixture(lamp) end end
            return spec
        end
        return {
            title = "Work order: fix a streetlight", reward = 12, limit = 420,
            desc = "A streetlight is out " .. Place(p, ply:GetPos()) .. ". Rewire it. Keep what's left over.",
            stages = { Goto(p, "Find the dead streetlight", 150), Hold(p, 12, "Rewire it (stay close)", 140) },
            onFinish = PayIn({ scrap = 1, chemicals = 1 }, "The light flickers on."),
        }
    end,
}

T{
    id = "cit_rubble", factions = { citizen = true },
    build = function(ply)
        local center = (LC.MarkedSpot and LC.MarkedSpot("rubble", ply)) or Spot(ply, 300, 2000)
        if not center then return nil end
        return {
            title = "Work order: clear rubble", reward = 15, limit = 480,
            desc = "Rubble is blocking the way " .. Place(center, ply:GetPos()) .. ". Clear it. Anything salvageable is yours.",
            stages = { { kind = "collect", spots = HideSpots(center, 4, 600, true), models = RUBBLE, need = 4,
                text = "Clear the rubble (press E)" } },
            onFinish = PayIn({ scrap = 2, cloth = 1 }, "The way is clear."),
        }
    end,
}

T{
    id = "cit_pipe", factions = { citizen = true },
    build = function(ply)
        local p = (LC.MarkedSpot and LC.MarkedSpot("pipe", ply)) or Spot(ply, 300, 2000)
        if not p then return nil end
        return {
            title = "Work order: patch a leaking pipe", reward = 12, limit = 420,
            desc = "A pipe is leaking " .. Place(p, ply:GetPos()) .. ". Get down and patch it.",
            stages = { Goto(p, "Find the leak", 150), Hold(p, 15, "Patch the pipe (crouch beside it)", 140, true) },
            onFinish = PayIn({ chemicals = 1, cloth = 1, scrap = 1 }, "The leak stops."),
        }
    end,
}

------------------------------------------------------------------------
-- The Combine's data (sv_livingcity_heist.lua)
------------------------------------------------------------------------

-- Two terminals, each with half the picture: a fragment from each, and the two make a chip.
T{
    id = "res_dataheist", factions = { resistance = true }, violent = true, squad = 4,
    available = function(ply)
        if not LC.ReadyTerminals or not (LC.CanHack and LC.CanHack(ply)) then return false end -- a Hacker's job (the multitool)
        return #LC.ReadyTerminals(false) >= 2
    end,
    build = function(ply)
        local ready = LC.ReadyTerminals(false)
        if #ready < 2 then return nil end
        local here = ply:GetPos()
        table.sort(ready, function(a, b) return a.pos:DistToSqr(here) < b.pos:DistToSqr(here) end)
        local t1, t2 = ready[1], ready[2]
        local first = function(q, p, key, master)
            if master then return false end
            q.data.firstKey = key
            return true
        end
        local second = function(q, p, key, master) return not master and key ~= q.data.firstKey end
        return {
            title = "Steal the Combine's data " .. Place(t1.pos, here), reward = 60, limit = 1200,
            desc = "Each Combine terminal only holds half the picture. Hit two: one " .. Place(t1.pos, here) .. ", then another " ..
                Place(t2.pos, ply:GetPos()) .. ". Aim the multitool at each, left click, and stay with it while it downloads. Each sounds the alarm halfway, and a squad comes. The two fragments make a chip: the lab's scientist decodes it, or the dealer pays for it.",
            stages = {
                Goto(t1.pos, "Get to the first terminal", 200),
                Count("data_stolen", 1, "Download its half (aim the multitool and left click; stay close)", first, false),
                Goto(t2.pos, "Get to the second terminal", 200),
                Count("data_stolen", 1, "Download the other half (a different terminal)", second, false),
            },
        }
    end,
}

-- The master terminal: the motherlode.
T{
    id = "res_motherlode", factions = { resistance = true }, violent = true, squad = 4,
    available = function(ply)
        if not LC.ReadyTerminals or not (LC.CanHack and LC.CanHack(ply)) then return false end
        return #LC.ReadyTerminals(true) >= 1
    end,
    build = function(ply)
        local ready = LC.ReadyTerminals(true)
        if #ready == 0 then return nil end
        local t = ready[1]
        return {
            title = "The master terminal " .. Place(t.pos, ply:GetPos()), reward = 120, limit = 900,
            desc = "The Combine's master terminal " .. Place(t.pos, ply:GetPos()) .. ": everything they know, in one place. It takes a full minute to download, every alarm in the nexus goes off a third of the way in, and they'll send more than a squad. Bring the core home: the quartermaster's decoding marks every Civil Protection unit for ten minutes, the dealer pays a fortune, or it wipes every comrade's record.",
            stages = {
                Goto(t.pos, "Get to the master terminal", 200),
                Count("master_stolen", 1, "Download the master terminal (aim the multitool and left click; hold on for a minute)", nil, false),
            },
        }
    end,
}

T{
    id = "cp_databreach", factions = { cp = true, ota = true }, squad = 8, violent = true,
    available = function() return LC.LastBreach ~= nil and CurTime() - LC.LastBreach.at < 300 end,
    build = function(ply)
        local b = LC.LastBreach
        if not b then return nil end
        return {
            title = "Data breach " .. Place(b.pos, ply:GetPos()), reward = 45, limit = 480,
            desc = "Anticitizens are inside Combine systems. Get there, stop them, and secure the terminal.",
            stages = { Goto(b.pos, "Get to the breach", 400), Hold(b.pos, 30, "Secure the terminal", 450) },
        }
    end,
}

------------------------------------------------------------------------
-- The Resistance's operations, and the city's answers (sv_livingcity_resistanceops.lua)
------------------------------------------------------------------------

T{
    id = "res_breakout", factions = { resistance = true }, violent = true, squad = 4,
    available = function(ply) return LC.JailedRebel and LC.JailedRebel() ~= nil and LC.JailedRebel() ~= ply end,
    build = function(ply)
        local prisoner, cell = LC.JailedRebel()
        if not prisoner or prisoner == ply then return nil end
        local hold = Hold(cell, 20, "Get the cell open (stay at the door while the alarm goes)", 170)
        hold.onEnter = function() if LC.PrisonBreakAlarm then LC.PrisonBreakAlarm(cell) end end
        hold.onDone = function(q) if LC.BreakOut then LC.BreakOut(prisoner, q.owner) end end
        return {
            title = "Break " .. prisoner:Nick() .. " out", reward = 60, limit = 900,
            desc = prisoner:Nick() .. " is in a cell " .. Place(cell, ply:GetPos()) .. ". Get in (a keycard, a bypass charge, or a Hacker's multitool on the Combine doors), get the cell open, get them out.",
            stages = { Goto(cell, "Get to the cells", 220), hold },
        }
    end,
}

T{
    id = "cp_prisonbreak", factions = { cp = true, ota = true }, violent = true, squad = 8,
    available = function() return LC.LastPrisonBreak ~= nil and CurTime() - LC.LastPrisonBreak.at < 300 end,
    build = function(ply)
        local b = LC.LastPrisonBreak
        if not b then return nil end
        return {
            title = "Prison break " .. Place(b.pos, ply:GetPos()), reward = 45, limit = 480,
            desc = "Anticitizens are at the cells. Get there and hold them.",
            stages = { Goto(b.pos, "Get to the cells", 300), Hold(b.pos, 30, "Hold the cells", 400) },
        }
    end,
}

T{
    id = "cp_intercept", factions = { cp = true, ota = true }, violent = true, squad = 6,
    available = function() return LC.Smugglers ~= nil and next(LC.Smugglers) ~= nil end,
    build = function()
        return {
            title = "Intercept the smuggler", reward = 40, limit = 600,
            desc = "Stolen Union supplies are on the move. Follow the SMUGGLER marker and stop the carrier: arrest or kill.",
            stages = { Count("smuggler_stopped", 1, "Stop the smuggler (follow the SMUGGLER marker)", nil, false) },
        }
    end,
}

T{
    id = "cp_retakescreen", factions = { cp = true, ota = true }, squad = 6,
    available = function() return LC.LastHijack ~= nil and CurTime() - LC.LastHijack.at < 70 end,
    build = function(ply)
        local h = LC.LastHijack
        if not h then return nil end
        return {
            title = "Retake the city screen " .. Place(h.pos, ply:GetPos()), reward = 30, limit = 120,
            desc = "The Resistance have hijacked a city screen. Get there inside a minute and cut it (E on the screen).",
            stages = { Count("screen_retaken", 1, "Cut the broadcast (E on the screen)", nil, false) },
        }
    end,
}

T{
    id = "cp_securelz", factions = { cp = true, ota = true }, squad = 8,
    available = function() return LC.OverwatchDrop ~= nil end,
    build = function(ply)
        local d = LC.OverwatchDrop
        if not d then return nil end
        return {
            title = "Secure the landing zone " .. Place(d.pos, ply:GetPos()), reward = 40, limit = 420,
            desc = "Overwatch reinforcements are coming down. Hold the ground around the landing zone.",
            stages = { Goto(d.pos, "Get to the landing zone", 400), Hold(d.pos, 60, "Hold the landing zone", 600) },
        }
    end,
}

T{
    id = "res_ambushlz", factions = { resistance = true }, violent = true, squad = 6,
    available = function() return LC.OverwatchDrop ~= nil end,
    build = function(ply)
        local d = LC.OverwatchDrop
        if not d then return nil end
        local need = math.max(1, math.min(3, d.expected or 3))
        return {
            title = "Ambush the landing " .. Place(d.pos, ply:GetPos()), reward = 60, limit = 480,
            desc = "A dropship is bringing Overwatch soldiers down at the landing zone. Be there when it comes in, and hit the landing party while they're still on the ground.",
            stages = {
                Goto(d.pos, "Get to the landing zone before the dropship does", 800),
                Count("killed", need, "Bring down the landing party (the soldiers off the dropship)", function(_, _, npc)
                    local st = LC.NPCs[npc]
                    return st ~= nil and st.drop == d -- (these soldiers: not any soldier anywhere)
                end),
            },
        }
    end,
}

-- The Combine's side of it: a sweep team about to move into rebel territory (join it), and
-- the Resistance hitting the Combine (put it down). sv_livingcity_rebels.lua posts these.
local function RebelNear(pos, r)
    return function(_, _, npc)
        local st = LC.NPCs[npc]
        return st ~= nil and st.role == "rebel" and IsValid(npc) and npc:GetPos():DistToSqr(pos) < r * r
    end
end
T{
    id = "cp_joinsweep", factions = { cp = true, ota = true }, violent = true, squad = 8,
    available = function() return LC.PlannedSweep ~= nil or (LC.Skirmish ~= nil and LC.Skirmish.kind == "sweep") end,
    build = function(ply)
        local s = LC.PlannedSweep or LC.Skirmish
        local z = s and s.zone
        if not z then return nil end
        return {
            title = "Join the sweep " .. Place(z.pos, ply:GetPos()), reward = 55, limit = 420,
            desc = "A sweep team is moving into anticitizen territory " .. Place(z.pos, ply:GetPos()) .. ". Join it, and take down the anticitizens who resist.",
            stages = {
                Goto(z.pos, "Join the sweep team at the edge of anticitizen territory", math.max(500, (z.r or 300) + 300)),
                Count("killed", 2, "Take down two armed anticitizens there", RebelNear(z.pos, (z.r or 300) + 800)),
            },
        }
    end,
}
T{
    id = "cp_repelraid", factions = { cp = true, ota = true }, violent = true, squad = 8,
    available = function() return LC.Skirmish ~= nil and LC.Skirmish.kind == "raid" end,
    build = function(ply)
        local r = LC.Skirmish
        if not r or not r.target then return nil end
        return {
            title = "Repel the attack " .. Place(r.target, ply:GetPos()), reward = 50, limit = 360,
            desc = "Armed anticitizens are attacking Civil Protection units " .. Place(r.target, ply:GetPos()) .. ". Get there and put it down.",
            stages = {
                Goto(r.target, "Get to the attack", 700),
                Count("killed", 2, "Take down two of the attackers", RebelNear(r.target, 1400)),
            },
        }
    end,
}

-- The Resistance's fighters are about to hit the Combine (sv_livingcity_rebels.lua): be there,
-- and back them up.
T{
    id = "res_backupraid", factions = { resistance = true }, violent = true, squad = 6,
    available = function() return LC.PlannedRaid ~= nil or (LC.Skirmish ~= nil and LC.Skirmish.kind == "raid") end,
    build = function(ply)
        local r = LC.PlannedRaid or LC.Skirmish
        if not r or not r.target then return nil end
        local target = r.target
        return {
            title = "Back up the raid " .. Place(target, ply:GetPos()), reward = 55, limit = 420,
            desc = "Our fighters are hitting the Combine " .. Place(target, ply:GetPos()) .. ". Get there, and help them: take down the units they're fighting.",
            stages = {
                Goto(target, "Meet our fighters at the target", 600),
                Count("killed", 2, "Back them up: take down two of the Combine's units there", function(_, _, npc)
                    local st = LC.NPCs[npc]
                    return st ~= nil and LC.IsSecurity(st) and IsValid(npc) and npc:GetPos():DistToSqr(target) < 1400 * 1400
                end),
            },
        }
    end,
}

-- A shackled vortigaunt, at a Combine work site. It waits, shackled and harmless,
-- with its keepers. Cut the shackles there (they may see), or lead it off still
-- shackled as if you were moving Combine property, and cut them in rebel
-- territory (any of it): unless a unit stops you and asks where you're taking it.
local SECURITY_NPC = { "npc_metropolice", "npc_combine_s", "npc_hunter", "npc_strider", "npc_cscanner", "npc_turret_floor", "npc_manhack" }
local function Peaceful(v, on)
    for _, cls in ipairs(SECURITY_NPC) do v:AddRelationship(cls .. (on and " D_NU 99" or " D_HT 99")) end
    v:AddRelationship("player " .. (on and "D_NU" or "D_LI") .. " 99")
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role ~= "rebel" and st.role ~= "citizen" and npc.AddEntityRelationship then npc:AddEntityRelationship(v, on and D_NU or D_HT, 99) end
    end
end
LC.QuestVortPeaceful = Peaceful
-- (hurt by one of them, it defends itself against that one; it doesn't go looking for a fight)
hook.Add("EntityTakeDamage", "LivingCityQuestVort", function(v, dmg)
    if not v.lcQuestVort then return end
    local a = dmg:GetAttacker()
    if IsValid(a) and a:IsNPC() and v.AddEntityRelationship then v:AddEntityRelationship(a, D_HT, 99) end
end)
T{
    id = "res_freevort", factions = { resistance = true }, violent = true, squad = 4,
    available = function(ply)
        if ply:GetNW2Int("lcf_rank", 1) < 2 or #LC.ZonesOfKind("rebel") == 0 then return false end
        local n = 0
        for _ in pairs(LC.RebelVorts or {}) do n = n + 1 end
        return n < 2
    end,
    build = function(ply)
        local site = Spot(ply, 800, 3000)
        if not site then return nil end
        if #LC.ZonesOfKind("rebel") == 0 then return nil end
        local find = {
            kind = "target", action = "reach", r = 160, text = "Find the shackled vortigaunt at the work site",
            onEnter = function(q, st)
                local v = ents.Create("npc_vortigaunt")
                if not IsValid(v) then return false end
                if not util.IsValidModel or util.IsValidModel("models/vortigaunt_slave.mdl") then v:SetModel("models/vortigaunt_slave.mdl") end
                v:SetPos(site + Vector(0, 0, 4))
                v:Spawn()
                v:Activate()
                local vst = LC.RegisterNPC and LC.RegisterNPC(v, "vortigaunt")
                if vst then vst.unmanaged = true vst.shackled = true end
                v:SetNW2Bool("lc_shackled", true)
                v.lcQuestVort = true
                Peaceful(v, true) -- (shackled: it harms nobody, and nobody harms it)
                Q.Lock(q, v)
                Q.Freeze(v, 900)
                q.data.vort = v
                q.ents[#q.ents + 1] = v -- (gone again if the job fails)
                st.npc = v
                -- its keepers
                for i = 1, 2 do
                    local c = Q.SpawnActor(q, "cop", site + Vector(i == 1 and 120 or -120, 60, 0), 900)
                    if IsValid(c) and c.AddEntityRelationship then c:AddEntityRelationship(v, D_NU, 99) end
                end
            end,
        }
        local function Home(text, shackled)
            local e = { kind = "escort", anyRebel = true, pos = LC.ZonesOfKind("rebel")[1].pos, r = 200, text = text,
                onEnter = function(q, st) st.npc = q.data.vort if not IsValid(st.npc) then return false end end }
            if shackled then
                -- a unit who sees you leading it may stop you and ask (once): then it's a fight
                e.watch = function(q, st)
                    local p = q.owner
                    if q.data.questioned or not IsValid(p) or (st.nextAsk or 0) > CurTime() then return end
                    st.nextAsk = CurTime() + 4
                    if LC.SeenBySecurity and LC.SeenBySecurity(p, 700) and math.random(100) <= 12 then
                        q.data.questioned = true
                        Narrate(q, "A Civil Protection unit steps into your way: \"Where are you taking that?\" No answer will do. Run, or fight.")
                        LC.ReportCrime(p, "Theft of Combine property", 180)
                        if IsValid(q.data.vort) then Peaceful(q.data.vort, false) end
                    end
                end
            end
            e.onDone = function(q)
                local v = q.data.vort
                if IsValid(v) then
                    q.marked[v] = nil
                    for i, ent in ipairs(q.ents) do if ent == v then table.remove(q.ents, i) break end end
                    if q.data.shackled then Narrate(q, "In rebel territory, the shackles come off. It breathes in, slowly, and looks round at its new home.") end
                    v:SetNW2Bool("lc_shackled", false)
                    if LC.SettleVort then LC.SettleVort(v) end
                end
            end
            return e
        end
        local cut = Hold(site, 12, "Cut the shackles (stay beside it)", 140)
        cut.onDone = function(q)
            local p = q.owner
            if IsValid(p) and LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then LC.ReportCrime(p, "Theft of Combine property", 180) end
            if IsValid(q.data.vort) then q.data.vort:SetNW2Bool("lc_shackled", false) end
            Narrate(q, "The shackles fall. It looks at you, and waits. Lead it home.")
        end
        local choose = Q.Choice("The vortigaunt waits, its collar humming. Cut it loose here, or walk it out as if it were still the Combine's?", {
            { text = "Cut the shackles here (twelve seconds beside it; its keepers may see), then lead it home.",
              pick = function(q) Q.InsertStages(q, { cut, Home("Lead it home to rebel territory (any of it)") }) return "next" end },
            { text = "Lead it off still shackled, like Combine property on the move; cut them in rebel territory (a unit may stop you and ask).",
              pick = function(q) q.data.shackled = true Q.InsertStages(q, { Home("Walk it to rebel territory (any of it), still shackled", true) }) return "next" end },
        })
        return {
            title = "Free a vortigaunt " .. Place(site, ply:GetPos()), reward = 70, limit = 1200,
            desc = "The Combine are working a shackled vortigaunt " .. Place(site, ply:GetPos()) .. ". Free it and bring it to rebel territory: it will heal our wounded.",
            stages = { find, choose },
        }
    end,
}
