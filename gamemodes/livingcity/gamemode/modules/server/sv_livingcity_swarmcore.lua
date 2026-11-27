--[[
    Living City: the suppression core under the Nexus, the Swarm's second gate (the owner, 27 November, agreed: the
    city's own Citadel-style thumper; in Half-Life 2 the Citadel works as a giant thumper). docs/features/the-swarm.md,
    "The suppression core".

      The heartbeat  while it runs, everyone in the city (the Swarm's own test, W.InCity: never the forests or the caves)
                     hears a low, deep thud every 4 to 6 seconds, quiet, with a very faint shake (cl_livingcity_swarm.lua).
                     Stopped, it stops for everyone: the silence is the message. Nothing written.
      The gate       the swarm comes up into the city, and the city falls to it, only with every canal thumper stopped
                     AND the core stopped (W.DefencesDown, sv_livingcity_swarm.lua). The canals' trickle is not its.
      Shut down      a Resistance player's E at one of its three consoles (the map's lc_core_panel_1 to _3, within reach)
                     is the wiring game; each one finished cuts that console. All three within 10 minutes of the first:
                     the core winds down (the map's lc_core_stop, a huge wind-down at the machine). Not in time: the
                     cut ones are whole again. Any time, the pheropods out or not; nothing to stand through.
      Restarted      while it is stopped the Combine's board has "Restart the suppression core" (cmb_core): down by
                     their way (lc_core_combine_way), each console mended (the wiring game), then its button. A Combine
                     player's E at a cut console mends it too, and the button (lc_core_button: lc_core_start) starts it
                     for whoever presses it once all three are whole; with one still cut it only fizzles. A Resistance
                     player's E at a mended console cuts it again. After the city falls to the swarm the Resistance hold
                     it: they mend the consoles and start it, inside "Restart the thumpers" (res_thumpers).
    The map gives it by name: lc_core_machine (only that the map has a core, and where: Valve's digger, a func_tracktrain,
    or an info_target at it; never driven from here), lc_core_stop and lc_core_start (logic_relays: everything the machine
    does), lc_core_panel_1 to _3 (info_targets in front of the consoles), lc_core_button, lc_core_room (the chamber's
    centre), lc_core_combine_way. On a map without lc_core_machine nothing here happens, and the Swarm is as it was.
    It works whatever lc_swarm says (like the nest's guardians). Saved in the Swarm's own file
    (data/livingcity/<map>_swarm.json, W.ClockSave): running or not, which consoles are cut, how long the ten minutes
    have run. Staff: F4 > Factions > Admin: testing tools > The city ("Core: stop it", "Core: start it").
]]

if CLIENT then return end

LC = LC or {}
LC.Swarm = LC.Swarm or {}
local W = LC.Swarm

util.AddNetworkString("lc_core_thud")

W.CORE_PANELS = 3          -- its consoles: lc_core_panel_1 to _3
W.CORE_REACH = 110         -- how near a console's mark an E works
W.CORE_WINDOW = 600        -- every console cut within this of the first, or the cut ones are whole again
W.CORE_BEAT = { 4, 6 }     -- seconds between the heartbeat's thuds
W.CORE_REWARD = 70         -- the Combine's job (experience)

local COMBINE = { cp = true, ota = true, admin = true }

local function Named(name)
    for _, e in ipairs(ents.FindByName and ents.FindByName(name) or {}) do if IsValid(e) then return e end end
    return nil
end
local function Faction(p) return (IsValid(p) and p:IsPlayer()) and p:GetNW2String("lcf_faction", "") or "" end
-- A sound at a place (the consoles are info_targets: nothing of theirs reaches a client to sound from).
local function SoundAt(pos, path, level, pitch)
    if pos and sound and sound.Play then sound.Play(path, pos, level or 75, pitch or 100, 1) end
end
local function Relay(name, by)
    local r = Named(name)
    if IsValid(r) then r:Fire("Trigger", "", 0, IsValid(by) and by or nil) end
end
local function Save() if W.ClockSave then W.ClockSave() end end
local function Ours() return W.CityOurs ~= nil and W.CityOurs() == true end

------------------------------------------------------------------------
-- The map's pieces, and the state
------------------------------------------------------------------------

function W.CoreMachine() return Named("lc_core_machine") end
function W.HasCore() return IsValid(W.CoreMachine()) end
function W.CorePanel(i) return Named("lc_core_panel_" .. i) end
-- The consoles the map has: { i, ent }.
function W.CorePanels()
    local out = {}
    for i = 1, W.CORE_PANELS do
        local e = W.CorePanel(i)
        if IsValid(e) then out[#out + 1] = { i = i, ent = e } end
    end
    return out
end
-- Where it is: the chamber's centre, else the machine (a brush's own origin can be anywhere: its middle).
function W.CorePos()
    local room = Named("lc_core_room")
    if IsValid(room) then return room:GetPos() end
    local m = W.CoreMachine()
    if not IsValid(m) then return nil end
    return m.WorldSpaceCenter and m:WorldSpaceCenter() or m:GetPos()
end

-- running (the map's machine runs when the map starts), cut[i] (that console cut), firstAt (the first cut's time).
local function Fresh() return { running = true, cut = {} } end
function W.CoreRunning() return W.HasCore() and W.core.running ~= false end
function W.CoreDown() return W.HasCore() and W.core.running == false end
function W.CoreCutCount()
    local n = 0
    for _, pn in ipairs(W.CorePanels()) do if W.core.cut[pn.i] then n = n + 1 end end
    return n
end

-- What the Swarm's file keeps of it (W.ClockSave), and reading it back.
function W.CoreData()
    local c = W.core or Fresh()
    local cut = {}
    for i = 1, W.CORE_PANELS do if c.cut[i] then cut[#cut + 1] = i end end
    return { running = c.running ~= false, cut = cut, cutFor = c.firstAt and math.floor(CurTime() - c.firstAt) or nil }
end
function W.CoreLoad()
    local t = LC.SafeReadJSON and LC.SafeReadJSON("livingcity/" .. game.GetMap() .. "_swarm.json")
    local saved = (istable(t) and istable(t.core)) and t.core or {}
    local c = Fresh()
    c.running = saved.running ~= false
    for _, i in ipairs(istable(saved.cut) and saved.cut or {}) do
        i = math.floor(tonumber(i) or 0)
        if i >= 1 and i <= W.CORE_PANELS then c.cut[i] = true end
    end
    if c.running and next(c.cut) ~= nil then c.firstAt = CurTime() - math.Clamp(tonumber(saved.cutFor) or 0, 0, W.CORE_WINDOW) end
    W.core = c
    return c
end
W.core = W.core or W.CoreLoad()

------------------------------------------------------------------------
-- Stopped and started
------------------------------------------------------------------------

-- It winds down. heard: the map's own relay said so (it has done its part already).
function W.CoreStop(by, heard)
    local c = W.core
    if c.running == false or not W.HasCore() then return false end
    c.running, c.firstAt, c.thudAt = false, nil, nil
    if not heard then
        Relay("lc_core_stop", by)
        local at = W.CorePos()
        SoundAt(at, "ambient/machines/thumper_shutdown1.wav", 120, 55)
        SoundAt(at, "ambient/machines/spindown.wav", 110, 60)
        if util.ScreenShake and at then util.ScreenShake(at, 5, 3, 4, 2000) end
    end
    Save()
    if not Ours() and LC.PostDirective then LC.PostDirective("cmb_core", nil, true) end -- (quietly: the silence says it)
    if LC.Log then LC.Log("info", "swarm: the suppression core is stopped") end
    return true
end

-- It runs again (whoever starts it has every console whole).
function W.CoreStart(by, heard)
    local c = W.core
    if c.running ~= false or not W.HasCore() then return false end
    c.running, c.cut, c.firstAt = true, {}, nil
    c.thudAt = CurTime() + 3
    if not heard then
        Relay("lc_core_start", by)
        local at = W.CorePos()
        SoundAt(at, "ambient/machines/thumper_startup1.wav", 110, 60)
        SoundAt(at, "ambient/machines/spinup.wav", 100, 60)
    end
    Save()
    if LC.Log then LC.Log("info", "swarm: the suppression core runs again") end
    return true
end

------------------------------------------------------------------------
-- The consoles
------------------------------------------------------------------------

-- What console i's wiring game would do for this player now: "cut", "mend", or nil (nothing).
-- The city the Combine's: the Resistance cut a whole one, the Combine mend a cut one. The city the Resistance's (after
-- the fall): they mend it.
function W.CoreTask(p, i)
    if not W.HasCore() then return nil end
    local f, cut = Faction(p), W.core.cut[i] == true
    if f == "resistance" then
        if Ours() then return cut and "mend" or nil end
        return (not cut) and "cut" or nil
    elseif COMBINE[f] and not Ours() then
        return cut and "mend" or nil
    end
    return nil
end

-- A console's wiring done (by whoever's game, a job's or an E's): cut, or mended.
function W.CoreWired(p, i, what)
    local c = W.core
    local pn = W.CorePanel(i)
    if not (W.HasCore() and IsValid(pn)) then return false end
    if what == "cut" then
        if c.cut[i] then return false end
        c.cut[i] = true
        SoundAt(pn:GetPos(), "ambient/energy/powerdown2.wav", 75, 90)
        if c.running ~= false then
            c.firstAt = c.firstAt or CurTime()
            if W.CoreCutCount() >= #W.CorePanels() then return W.CoreStop(p) end
        end
    elseif what == "mend" then
        if not c.cut[i] then return false end
        c.cut[i] = nil
        SoundAt(pn:GetPos(), "buttons/combine_button1.wav", 70, 100)
        if next(c.cut) == nil then c.firstAt = nil end
    else
        return false
    end
    Save()
    return true
end

-- E within reach of a console's mark: its wiring game, if there is something to do there (else a dead click).
-- The button is its own (E on it is the button's).
function W.CoreUse(p)
    if not (IsValid(p) and p:Alive() and W.HasCore()) or (LC.JobGames and LC.JobGames[p]) then return false end
    local tr = p.GetEyeTrace and p:GetEyeTrace()
    if tr and IsValid(tr.Entity) and tr.Entity == Named("lc_core_button") then return false end
    local at, best, bd = p:GetPos(), nil, nil
    for _, pn in ipairs(W.CorePanels()) do
        local d = pn.ent:GetPos():DistToSqr(at)
        if d <= W.CORE_REACH * W.CORE_REACH and (not bd or d < bd) then best, bd = pn, d end
    end
    if not best then return false end
    if CurTime() < (p.lcCoreUseAt or 0) then return true end
    p.lcCoreUseAt = CurTime() + 1
    local what = W.CoreTask(p, best.i)
    local pos = best.ent:GetPos()
    if not what then SoundAt(pos, "buttons/combine_button_locked.wav", 65, 100) return true end
    if LC.JobGameStart and LC.JobGameStart(p, "wiring", nil, { what = "the console", pos = pos, lcCore = best.i, lcCoreDo = what, quiet = true }) then
        return true
    end
    W.CoreWired(p, best.i, what) -- (no games on this server: done at once)
    return true
end

-- The button: with the core stopped and every console whole, it starts (whoever presses it); a cut one, a fizzle.
function W.CorePress(p, btn)
    if not W.HasCore() or W.core.running ~= false then return false end
    if CurTime() < (p.lcCorePressAt or 0) then return false end
    p.lcCorePressAt = CurTime() + 1
    if W.CoreCutCount() > 0 then
        if IsValid(btn) then btn:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 70, 100) end
        return false
    end
    return W.CoreStart(p)
end

------------------------------------------------------------------------
-- Every half second: the map told how it stands, the ten minutes, the heartbeat
------------------------------------------------------------------------

function W.CoreTick(now)
    if not W.HasCore() then return end
    local c = W.core
    if not c.applied then -- (the map starts with it running: saved stopped, it is stopped again)
        c.applied = true
        if c.running == false then Relay("lc_core_stop") end
    end
    if c.running == false then return end
    if c.firstAt and now - c.firstAt >= W.CORE_WINDOW then -- (not all in time: the cut ones are whole again)
        for i in pairs(c.cut) do
            local pn = W.CorePanel(i)
            if IsValid(pn) then SoundAt(pn:GetPos(), "buttons/combine_button1.wav", 70, 100) end
        end
        c.cut, c.firstAt = {}, nil
        Save()
    end
    if now >= (c.thudAt or 0) then
        c.thudAt = now + math.Rand(W.CORE_BEAT[1], W.CORE_BEAT[2])
        local who = {}
        for _, p in ipairs(player.GetAll()) do
            if p:Alive() and W.InCity and W.InCity(p:GetPos()) then who[#who + 1] = p end
        end
        if #who > 0 then
            net.Start("lc_core_thud")
            net.Send(who)
        end
    end
end

timer.Create("LivingCitySwarmCore", 0.5, 0, function()
    if LC.Running == false then return end
    local ok, err = LC.Try(W.CoreTick, CurTime())
    if not ok and LC.Error then LC.Error("suppression core", err) end
end)

------------------------------------------------------------------------
-- What the game tells us
------------------------------------------------------------------------

hook.Add("KeyPress", "LivingCitySwarmCore", function(p, key)
    if key == IN_USE then LC.Try(W.CoreUse, p) end
end)

hook.Add("PlayerUse", "LivingCitySwarmCore", function(p, ent)
    if IsValid(ent) and string.lower(tostring(ent.GetName and ent:GetName() or "")) == "lc_core_button" then LC.Try(W.CorePress, p, ent) end
end)

-- The relays, however they are triggered (ours, the map's own, staff's ent_fire): remembered. A start while a console
-- is still cut does nothing (as a broken thumper's).
hook.Add("AcceptInput", "LivingCitySwarmCore", function(ent, input, activator)
    if not IsValid(ent) or string.lower(input or "") ~= "trigger" then return end
    local name = string.lower(tostring(ent.GetName and ent:GetName() or ""))
    if name ~= "lc_core_stop" and name ~= "lc_core_start" then return end
    local by = (IsValid(activator) and activator:IsPlayer()) and activator or nil
    if name == "lc_core_stop" then
        LC.Try(W.CoreStop, by, true)
    elseif W.HasCore() and W.CoreCutCount() > 0 then
        return true
    else
        LC.Try(W.CoreStart, by, true)
    end
end)

hook.Add("LivingCityJobGameEnded", "LivingCitySwarmCore", function(p, kind, how, opts)
    if kind ~= "wiring" or not istable(opts) or not opts.lcCore or (how ~= "done" and how ~= "test") then return end
    LC.Try(W.CoreWired, p, opts.lcCore, opts.lcCoreDo)
end)

hook.Add("PostCleanupMap", "LivingCitySwarmCore", function() W.core.applied = nil end)
hook.Add("ShutDown", "LivingCitySwarmCore", function() if W.core.firstAt or W.core.running == false then Save() end end)

------------------------------------------------------------------------
-- Restarting it: the Combine's job, and the steps res_thumpers takes after the fall
------------------------------------------------------------------------

local Q = LC.QB

-- Each cut console (nearest first from `from`): get there, its wiring; then the button.
function W.CoreStages(from)
    if not Q then return {} end
    local left, stages, at = {}, {}, from or W.CorePos() or Vector(0, 0, 0)
    for _, pn in ipairs(W.CorePanels()) do if W.core.cut[pn.i] then left[#left + 1] = pn end end
    while #left > 0 do
        local bi, bd
        for k, pn in ipairs(left) do
            local d = pn.ent:GetPos():DistToSqr(at)
            if not bd or d < bd then bi, bd = k, d end
        end
        local pn = table.remove(left, bi)
        local pos = pn.ent:GetPos()
        stages[#stages + 1] = Q.GameGo(pos, "Get to the core's console (marked)", "wiring", { what = "the console", pos = pos, lcCore = pn.i, lcCoreDo = "mend" }, W.CORE_REACH)
        stages[#stages + 1] = Q.GameStage("Mend its wiring")
        at = pos
    end
    local btn = Named("lc_core_button")
    local press = Q.Count("core_started", 1, "Start the core with its button")
    press.pos = IsValid(btn) and btn:WorldSpaceCenter() or W.CorePos()
    press.untallied, press.button, press.relay = true, btn, Named("lc_core_start")
    press.poll = function(q) if W.CoreRunning() then Q.Advance(q) end end
    stages[#stages + 1] = press
    return stages
end

if Q and LC.QuestTemplates then
    LC.QuestTemplates[#LC.QuestTemplates + 1] = {
        id = "cmb_core", factions = { cp = true, ota = true }, squad = 4, recheck = true,
        available = function() return W.CoreDown() and not Ours() end,
        over = function()
            if Ours() then return false, "the city has fallen" end
            if not W.CoreDown() then return true end -- (it runs again, whoever pressed the button: it pays)
        end,
        build = function(ply)
            if not W.CoreDown() then return nil end
            local stages, from = {}, IsValid(ply) and ply:GetPos() or nil
            local way = Named("lc_core_combine_way")
            if IsValid(way) then
                stages[1] = Q.Goto(way:GetPos(), "Go down to the suppression core (marked)", 150)
                from = way:GetPos()
            end
            for _, st in ipairs(W.CoreStages(from)) do stages[#stages + 1] = st end
            return {
                title = "Restart the suppression core", reward = W.CORE_REWARD, limit = 1200,
                desc = "The core under the Nexus has stopped. Mend its consoles and start it again.",
                stages = stages,
            }
        end,
    }
end

------------------------------------------------------------------------
-- Staff: F4 > Factions > Admin: testing tools > The city, beside the Swarm's (sv_livingcity_admintools.lua)
------------------------------------------------------------------------

-- How it stands, for the Swarm's line (nil: no core on this map).
function W.CoreStatus()
    if not W.HasCore() then return nil end
    local c, n, cut = W.core, #W.CorePanels(), W.CoreCutCount()
    local line
    if c.running == false then
        line = string.format("The core is stopped: %d of %d consoles whole.", n - cut, n)
    elseif cut > 0 then
        local left = math.max(1, math.ceil((W.CORE_WINDOW - (CurTime() - (c.firstAt or CurTime()))) / 60))
        line = string.format("The core runs: %d of %d consoles cut (whole again in %d min).", cut, n, left)
    else
        line = "The core runs."
    end
    return { running = c.running ~= false, cut = cut, n = n, line = line }
end

if LC.ADMIN_ACTIONS then
    LC.ADMIN_ACTIONS.core = function(_, v, admin)
        if IsValid(admin) and not admin:IsSuperAdmin() then return false, "Superadmins only." end
        if not W.HasCore() then return false, "This map has no suppression core." end
        if v == "stop" then -- (as the Resistance leave it: every console cut)
            for _, pn in ipairs(W.CorePanels()) do W.core.cut[pn.i] = true end
            if not W.CoreStop(admin) then Save() return true, "The core is stopped already." end
            return true, "The core winds down."
        elseif v == "start" then
            if not W.CoreStart(admin) then return true, "The core runs already." end
            return true, "The core runs again."
        end
        return false, "Core: stop or start?"
    end
end
