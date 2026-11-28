--[[
    Living City: the suppression core under the Nexus, the Swarm's second gate (the owner, 27 November, agreed: the
    city's own Citadel-style thumper; in Half-Life 2 the Citadel works as a giant thumper). docs/features/the-swarm.md,
    "The suppression core".

      The heartbeat  while it runs, everyone in the city (the Swarm's own test, W.InCity: never the forests or the caves)
                     hears a low, deep thud every 4 to 6 seconds, quiet, with a very faint shake (cl_livingcity_swarm.lua).
                     Stopped, it stops for everyone: the silence is the message. Nothing written.
      The gate       the swarm comes up into the city, and the city falls to it, only with every canal thumper stopped
                     AND the core stopped (W.DefencesDown, sv_livingcity_swarm.lua). The canals' trickle is not its.
      Shut down      (the owner, 28 November: sabotage, and it lasts) each of its three consoles (the map's
                     lc_core_panel_1 to _3) is cut one of two ways: a Resistance Hacker (the multitool) by E or the
                     multitool's left click within reach of its mark, which is the needle game "hack"; or an IED's blast
                     within W.CORE_BLAST of the console, whoever set it. A cut console smokes and sparks, and stays cut.
                     All three cut: the core winds down (the map's lc_core_stop, a huge wind-down at the machine) and
                     the whole city goes dark (LC.CheckCityGrid, sv_livingcity_power.lua: every Combine door's lock
                     dies). A Resistance player without a multitool: a dead click. Nothing to stand through.
      Restarted      the Combine can mend a cut console only W.CORE_MEND_AFTER (45 minutes) after it was cut: before
                     that their E is a dead click. Once the core is down and every cut console can be mended, their
                     board has "Restart the suppression core" (cmb_core): down by their way (lc_core_combine_way), each
                     console mended (the wiring game), then its button. The button (lc_core_button: lc_core_start)
                     starts it for whoever presses it once all three are whole; with one still cut it only fizzles. A
                     mended console can be cut again, the same two ways. After the city falls to the swarm the
                     Resistance hold it: they mend the consoles at once and start it, inside "Restart the thumpers"
                     (res_thumpers).
    The map gives it by name: lc_core_machine (only that the map has a core, and where: Valve's digger, a func_tracktrain,
    or an info_target at it; never driven from here), lc_core_stop and lc_core_start (logic_relays: everything the machine
    does: its beams, the reactor's look, the pistons), lc_core_panel_1 to _3 (info_targets 72 out from the consoles,
    facing them), lc_core_button, lc_core_room (the chamber's centre), lc_core_combine_way. On a map without lc_core_machine nothing here happens, and the Swarm is as it was.
    It works whatever lc_swarm says (like the nest's guardians). Saved in the Swarm's own file
    (data/livingcity/<map>_swarm.json, W.ClockSave): running or not, which consoles are cut and for how long.
    Staff: F4 > Factions > Admin: testing tools > The city ("Core: stop it", "Core: start it").
]]

if CLIENT then return end

LC = LC or {}
LC.Swarm = LC.Swarm or {}
local W = LC.Swarm

util.AddNetworkString("lc_core_thud")

W.CORE_PANELS = 3          -- its consoles: lc_core_panel_1 to _3
W.CORE_REACH = 110         -- how near a console's mark an E works
W.CORE_BLAST = 220         -- an IED's blast this near a console wrecks it
W.CORE_MEND_AFTER = 45 * 60 -- how long a console stays cut before the Combine can mend it (seconds)
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
-- The whole city is dark while the core is down (sv_livingcity_power.lua looks at W.CoreDown).
local function Grid() if LC.CheckCityGrid then LC.Try(LC.CheckCityGrid) end end

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
-- Where console i itself stands: 72 in front of its mark (the mark faces it), at the height of its screen.
function W.CoreConsolePos(i)
    local pn = W.CorePanel(i)
    if not IsValid(pn) then return nil end
    return pn:GetPos() + pn:GetForward() * 72 + Vector(0, 0, 40)
end
-- Where it is: the chamber's centre, else the machine (a brush's own origin can be anywhere: its middle).
function W.CorePos()
    local room = Named("lc_core_room")
    if IsValid(room) then return room:GetPos() end
    local m = W.CoreMachine()
    if not IsValid(m) then return nil end
    return m.WorldSpaceCenter and m:WorldSpaceCenter() or m:GetPos()
end

-- running (the map's machine runs when the map starts), cut[i] (that console cut), cutAt[i] (when it was cut: the
-- Combine's mending waits from then).
local function Fresh() return { running = true, cut = {}, cutAt = {} } end
function W.CoreRunning() return W.HasCore() and W.core.running ~= false end
function W.CoreDown() return W.HasCore() and W.core.running == false end
function W.CoreCutCount()
    local n = 0
    for _, pn in ipairs(W.CorePanels()) do if W.core.cut[pn.i] then n = n + 1 end end
    return n
end


-- When console i was cut (a cut one nobody timed, as an older table's: from now).
local function CutAt(i)
    local c = W.core
    c.cutAt = c.cutAt or {}
    if c.cut[i] and not c.cutAt[i] then c.cutAt[i] = CurTime() end
    return c.cut[i] and c.cutAt[i] or nil
end
-- Cut long enough ago for the Combine to mend it?
function W.CoreMendable(i)
    local at = CutAt(i)
    return at ~= nil and CurTime() - at >= W.CORE_MEND_AFTER
end
-- Is a cut console still too fresh for them?
function W.CoreWaiting()
    for _, pn in ipairs(W.CorePanels()) do
        if W.core.cut[pn.i] and not W.CoreMendable(pn.i) then return true end
    end
    return false
end

-- What the Swarm's file keeps of it (W.ClockSave), and reading it back. cutAge[k]: how long console cut[k] has been
-- cut, in seconds (a restart does not shorten the Combine's wait).
function W.CoreData()
    local c = W.core or Fresh()
    local cut, age = {}, {}
    for i = 1, W.CORE_PANELS do
        if c.cut[i] then
            cut[#cut + 1] = i
            age[#age + 1] = math.max(0, math.floor(CurTime() - (c.cutAt and c.cutAt[i] or CurTime())))
        end
    end
    return { running = c.running ~= false, cut = cut, cutAge = age }
end
function W.CoreLoad()
    local t = LC.SafeReadJSON and LC.SafeReadJSON("livingcity/" .. game.GetMap() .. "_swarm.json")
    local saved = (istable(t) and istable(t.core)) and t.core or {}
    local ages = istable(saved.cutAge) and saved.cutAge or {} -- (an older file has none: cut as of now)
    local c = Fresh()
    c.running = saved.running ~= false
    for k, i in ipairs(istable(saved.cut) and saved.cut or {}) do
        i = math.floor(tonumber(i) or 0)
        if i >= 1 and i <= W.CORE_PANELS then
            c.cut[i] = true
            c.cutAt[i] = CurTime() - math.max(0, tonumber(ages[k]) or 0)
        end
    end
    W.core = c
    return c
end
W.core = W.core or W.CoreLoad()

------------------------------------------------------------------------
-- A cut console smokes and sparks for as long as it is cut
------------------------------------------------------------------------

W.coreFx = W.coreFx or {} -- [i] = what was made at console i (ours, never the map's)

local function FxMake(cls, pos, kv, on)
    local e = ents.Create and ents.Create(cls)
    if not IsValid(e) then return nil end
    e:SetPos(pos)
    for k, v in pairs(kv) do e:SetKeyValue(k, tostring(v)) end
    e:Spawn()
    if e.Activate then e:Activate() end
    if e.Fire then e:Fire(on) end
    return e
end
local function FxOff(i)
    for _, e in ipairs(W.coreFx[i] or {}) do if IsValid(e) then e:Remove() end end
    W.coreFx[i] = nil
end
local function FxOn(i)
    local pos = W.CoreConsolePos(i)
    if not pos then return end
    local have = W.coreFx[i]
    if have and IsValid(have[1]) then return end
    FxOff(i)
    local list = {}
    -- (env_spark: 64 starts on, 128 glows)
    list[#list + 1] = FxMake("env_spark", pos, { spawnflags = 192, MaxDelay = 3, Magnitude = 2, TrailLength = 2 }, "StartSpark")
    list[#list + 1] = FxMake("env_smokestack", pos, { InitialState = 1, BaseSpread = 6, SpreadSpeed = 8, Speed = 22, StartSize = 8,
        EndSize = 34, Rate = 7, JetLength = 110, twist = 6, roll = 8, WindAngle = 0, WindSpeed = 0,
        SmokeMaterial = "particle/SmokeStack.vmt", rendercolor = "34 32 30", renderamt = 190 }, "TurnOn")
    W.coreFx[i] = list
end
-- Each console as it stands now: smoke and sparks at the cut ones, nothing at the whole ones.
function W.CoreFx()
    local has = W.HasCore()
    for i = 1, W.CORE_PANELS do LC.Try((has and W.core.cut[i]) and FxOn or FxOff, i) end
end
-- A blown one is scorched too: its face, and the floor under it.
local function Scorch(i)
    local pos, pn = W.CoreConsolePos(i), W.CorePanel(i)
    if not (pos and IsValid(pn) and util.Decal) then return end
    local f = pn:GetForward()
    util.Decal("Scorch", pos - f * 60, pos + f * 40)
    util.Decal("Scorch", pos, pos - Vector(0, 0, 120))
end

------------------------------------------------------------------------
-- Stopped and started
------------------------------------------------------------------------

-- It winds down. heard: the map's own relay said so (it has done its part already).
function W.CoreStop(by, heard)
    local c = W.core
    if c.running == false or not W.HasCore() then return false end
    c.running, c.thudAt, c.posted = false, nil, nil
    if not heard then
        Relay("lc_core_stop", by)
        local at = W.CorePos()
        SoundAt(at, "ambient/machines/thumper_shutdown1.wav", 120, 55)
        SoundAt(at, "ambient/machines/spindown.wav", 110, 60)
        if util.ScreenShake and at then util.ScreenShake(at, 5, 3, 4, 2000) end
    end
    Save()
    Grid()
    if LC.Log then LC.Log("info", "swarm: the suppression core is stopped") end
    return true
end

-- It runs again (whoever starts it has every console whole).
function W.CoreStart(by, heard)
    local c = W.core
    if c.running ~= false or not W.HasCore() then return false end
    c.running, c.cut, c.cutAt, c.posted = true, {}, {}, nil
    c.thudAt = CurTime() + 3
    W.CoreFx()
    if not heard then
        Relay("lc_core_start", by)
        local at = W.CorePos()
        SoundAt(at, "ambient/machines/thumper_startup1.wav", 110, 60)
        SoundAt(at, "ambient/machines/spinup.wav", 100, 60)
    end
    Save()
    Grid()
    if LC.Log then LC.Log("info", "swarm: the suppression core runs again") end
    return true
end

------------------------------------------------------------------------
-- The consoles
------------------------------------------------------------------------

-- What this player can do at console i now: "cut", "mend", or nil (nothing).
-- The city the Combine's: a Resistance Hacker (the multitool) cuts a whole one; the Combine mend a cut one, but only
-- W.CORE_MEND_AFTER after it was cut. The city the Resistance's (after the fall): they mend it, at once.
function W.CoreTask(p, i)
    if not W.HasCore() then return nil end
    local f, cut = Faction(p), W.core.cut[i] == true
    if f == "resistance" then
        if Ours() then return cut and "mend" or nil end
        return (not cut and LC.CanHack ~= nil and LC.CanHack(p) == true) and "cut" or nil
    elseif COMBINE[f] and not Ours() then
        return (cut and W.CoreMendable(i)) and "mend" or nil
    end
    return nil
end

-- A console cut (a Hacker's game done, or blown: an IED's blast) or mended (the wiring game, a job's or an E's).
function W.CoreWired(p, i, what, blown)
    local c = W.core
    local pn = W.CorePanel(i)
    if not (W.HasCore() and IsValid(pn)) then return false end
    if what == "cut" then
        if c.cut[i] then return false end
        c.cutAt = c.cutAt or {}
        c.cut[i], c.cutAt[i] = true, CurTime()
        SoundAt(pn:GetPos(), "ambient/energy/powerdown2.wav", 75, 90)
        LC.Try(FxOn, i)
        if blown then LC.Try(Scorch, i) end
        if c.running ~= false and W.CoreCutCount() >= #W.CorePanels() then return W.CoreStop(p) end
    elseif what == "mend" then
        if not c.cut[i] then return false end
        if not Ours() and not W.CoreMendable(i) then return false end -- (the Combine's mending waits)
        c.cut[i] = nil
        if c.cutAt then c.cutAt[i] = nil end
        SoundAt(pn:GetPos(), "buttons/combine_button1.wav", 70, 100)
        LC.Try(FxOff, i)
    else
        return false
    end
    Save()
    return true
end

-- The console whose mark this player is within reach of (the nearest): { i, ent }, or nil.
local function Nearest(p)
    local at, best, bd = p:GetPos(), nil, nil
    for _, pn in ipairs(W.CorePanels()) do
        local d = pn.ent:GetPos():DistToSqr(at)
        if d <= W.CORE_REACH * W.CORE_REACH and (not bd or d < bd) then best, bd = pn, d end
    end
    return best
end

-- The work at a console begins: cutting it is the Hacker's needle game, mending it the wiring game.
local function Begin(p, pn, what)
    local opts = { what = "the console", pos = pn.ent:GetPos(), lcCore = pn.i, lcCoreDo = what, quiet = true }
    local kind = "wiring"
    if what == "cut" then
        kind, opts.title = "hack", "The core's console"
        opts.onDone = function() opts.lcCoreIn = true end -- (the needle game ends "done" when its alarm trips too: only this is in)
    end
    if LC.JobGameStart and LC.JobGameStart(p, kind, nil, opts) then return true end
    W.CoreWired(p, pn.i, what) -- (no games on this server: done at once)
    return true
end

-- E within reach of a console's mark: its game, if there is something for this player to do there (else a dead click).
-- The button is its own (E on it is the button's).
function W.CoreUse(p)
    if not (IsValid(p) and p:Alive() and W.HasCore()) or (LC.JobGames and LC.JobGames[p]) then return false end
    local tr = p.GetEyeTrace and p:GetEyeTrace()
    if tr and IsValid(tr.Entity) and tr.Entity == Named("lc_core_button") then return false end
    local best = Nearest(p)
    if not best then return false end
    if CurTime() < (p.lcCoreUseAt or 0) then return true end
    p.lcCoreUseAt = CurTime() + 1
    local what = W.CoreTask(p, best.i)
    if not what then SoundAt(best.ent:GetPos(), "buttons/combine_button_locked.wav", 65, 100) return true end
    return Begin(p, best, what)
end

-- The multitool's left click within reach of a whole console (weapon_lc_multitool.lua): the same hack as a Hacker's E.
-- false: nothing of the core's here for this player (the multitool goes on to what it is pointed at).
function W.CoreHack(p)
    if not (IsValid(p) and p:Alive() and W.HasCore()) or (LC.JobGames and LC.JobGames[p]) then return false end
    local best = Nearest(p)
    if not best or W.CoreTask(p, best.i) ~= "cut" then return false end
    return Begin(p, best, "cut")
end

-- An IED's blast by a console wrecks it (sv_livingcity_ied.lua), whoever set it, at any time. How many it took.
function W.CoreBlast(pos, by)
    if not (pos and W.HasCore()) then return 0 end
    local n = 0
    for _, pn in ipairs(W.CorePanels()) do
        local at = W.CoreConsolePos(pn.i)
        if at and not W.core.cut[pn.i] and at:DistToSqr(pos) <= W.CORE_BLAST * W.CORE_BLAST then
            W.CoreWired(IsValid(by) and by or nil, pn.i, "cut", true)
            n = n + 1
        end
    end
    return n
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
-- Every half second: the map told how it stands, the Combine's job once they can mend, the heartbeat
------------------------------------------------------------------------

function W.CoreTick(now)
    if not W.HasCore() then return end
    local c = W.core
    if not c.applied then -- (the map starts with it running and whole: saved stopped or cut, it is so again)
        c.applied = true
        if c.running == false then Relay("lc_core_stop") end
        W.CoreFx()
        Grid()
    end
    -- (the multitool's own line says so while its holder stands at a console to cut: weapon_lc_multitool.lua)
    local ours = Ours()
    for _, p in ipairs(player.GetAll()) do
        local at = false
        if not ours and p:Alive() and Faction(p) == "resistance" then
            local pn = Nearest(p)
            at = pn ~= nil and W.CoreTask(p, pn.i) == "cut"
        end
        if p:GetNW2Bool("lc_core_console", false) ~= at then p:SetNW2Bool("lc_core_console", at) end
    end
    if c.running == false then
        -- (the Combine's job, once every cut console can be mended: posted quietly, the silence said it long ago)
        if not c.posted and not ours and not W.CoreWaiting() then
            c.posted = true
            if LC.PostDirective then LC.PostDirective("cmb_core", nil, true) end
        end
        return
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
    if not istable(opts) or not opts.lcCore then return end
    local done = false
    if kind == "wiring" then
        done = how == "done" or how == "test"
    elseif kind == "hack" then -- (its alarm ends it "done" as well: in only when the needle game was won)
        done = how == "test" or (how == "done" and opts.lcCoreIn == true)
    end
    if done then LC.Try(W.CoreWired, p, opts.lcCore, opts.lcCoreDo) end
end)

hook.Add("LivingCityIED", "LivingCitySwarmCore", function(pos, by) LC.Try(W.CoreBlast, pos, by) end)

-- (the cleanup took the smoke and sparks with it: the tick makes them again)
hook.Add("PostCleanupMap", "LivingCitySwarmCore", function() W.core.applied = nil end)
hook.Add("ShutDown", "LivingCitySwarmCore", function() if next(W.core.cut) ~= nil or W.core.running == false then Save() end end)

-- A map prop drawn at another size: the key lc_scale (the map sets the engine's own modelscale as well; this is the
-- guarantee). Nothing is returned: the key stays as the map wrote it.
hook.Add("EntityKeyValue", "LivingCityScale", function(ent, key, value)
    if string.lower(tostring(key)) ~= "lc_scale" then return end
    local s = tonumber(value)
    if not s or s < 0.05 or s > 10 or not IsValid(ent) then return end
    ent.lcScale = s
    timer.Simple(0, function()
        LC.Try(function() if IsValid(ent) and ent.SetModelScale then ent:SetModelScale(s, 0) end end)
    end)
end)

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
        available = function() return W.CoreDown() and not Ours() and not W.CoreWaiting() end, -- (not while a console is too fresh to mend)
        over = function()
            if Ours() then return false, "the city has fallen" end
            if not W.CoreDown() then return true end -- (it runs again, whoever pressed the button: it pays)
        end,
        build = function(ply)
            if not W.CoreDown() or W.CoreWaiting() then return nil end
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
    local line, wait = nil, 0
    for _, pn in ipairs(W.CorePanels()) do
        local at = CutAt(pn.i)
        if at then wait = math.max(wait, W.CORE_MEND_AFTER - (CurTime() - at)) end
    end
    local tail = (wait > 0 and not Ours()) and string.format(" (the Combine can mend in %d min)", math.max(1, math.ceil(wait / 60))) or ""
    if c.running == false then
        line = string.format("The core is stopped: %d of %d consoles whole%s.", n - cut, n, tail)
    elseif cut > 0 then
        line = string.format("The core runs: %d of %d consoles cut%s.", cut, n, tail)
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
            for _, pn in ipairs(W.CorePanels()) do
                W.core.cut[pn.i] = true
                CutAt(pn.i)
            end
            W.CoreFx()
            if not W.CoreStop(admin) then
                -- (pressed again while it is stopped: the Combine's wait is over, so their job can be tried)
                for _, pn in ipairs(W.CorePanels()) do W.core.cutAt[pn.i] = CurTime() - W.CORE_MEND_AFTER end
                Save()
                return true, "The core is stopped already: the Combine can mend it now."
            end
            return true, "The core winds down."
        elseif v == "start" then
            if not W.CoreStart(admin) then return true, "The core runs already." end
            return true, "The core runs again."
        end
        return false, "Core: stop or start?"
    end
end
