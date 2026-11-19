--[[
    Living City: headcrab shelling (the owner, 18 November, the long-term plan,
    item 2: "The Combine shell a district the Resistance hold; it raises that
    district's infestation for everyone, so it costs the Combine too")

    Half-Life 2's own headcrab canisters (env_headcrabcanister: their scream
    coming in, the impact, the pop as they open, the hot hiss and the smoke are
    the game's own) come down on a district, SHELLS of them, landing within a
    few seconds of each other, never two closer than APART. Each one lets out
    its headcrabs and leaves a patch of the infestation where it came down (a
    patch of the nearest infestation placed in the editor, so everything that
    fights the infestation fights it): the district's infestation rises for
    everyone who lives there (sv_livingcity_districtinfest.lua), and past 50 it
    leaks next door, the Combine's blocks too.

    Where they come down, in this order:
      - the Resistance's ground in the open: a patch of rebel ground grown
        under open sky. The headcrabs drive them off it: that patch is lost to
        them and the infestation takes it;
      - the district's own open ground with sky above (as clear of housing
        blocks, Combine zones, prisons, checkpoints, queues, cells and spawns
        as any patch);
      - under cover (the owner, 19 November: "most of the resistance is
        literally underground in tunnels and sewers or inside of buildings",
        with a habitation block or a Combine zone often on the streets above):
        the tunnels, sewers or rooms of the district nearest its rebel ground,
        as if it crawled down the drains: the patch and the headcrabs appear
        there as the canister lands. That canister comes down on the open
        ground nearest the district, never in a block the Combine hold, and is
        empty and harmless (the crash, the pop, the hiss and the smoke only).
        With no such ground near, no canister: the headcrabs are just there.

    Who orders it (the owner, 19 November: "only by a player administrator OR
    if the resistance has spread to open-air areas and is taking lots of
    ground"): a player City Administrator, on F2 > City orders, on a district
    the Resistance hold (morale and the Resistance's strength fall); and the
    city's own Combine only when OPEN_GROUND or more patches of rebel ground
    have grown under open sky in districts the Resistance hold, on the one with
    the most, aimed at that ground only, at most once in CITY_MINUTES. Never two within COOLDOWN_MINUTES, never during her address,
    an event or the collapse.

    What players get: the canisters, the headcrabs, Civil Protection's usual
    radio line about the infestation spreading; a line in the next City
    Bulletin ("The Combine shelled X with headcrabs."); the PA's "shelled" as
    they come in (hers or Overwatch's, only where recorded); and Colonel
    Cubbage cutting in on Freq 7 a minute later (cubbage/answer_shelled*.wav,
    only where recorded). VOICE_SCRIPTS.md has the lines. Superadmins: F4 >
    Admin testing tools > Testing alone > Shell a district now.
]]

if CLIENT then return end

LC = LC or {}

local SHELLS = 3            -- canisters in one shelling
local CRABS = 3             -- headcrabs in each
local GAP = 1.2             -- seconds between landings (all inside the radio's one line)
local FLIGHT = 4            -- seconds from the launch to the landing
local COOLDOWN_MINUTES = 45 -- the next shelling, the city's own or hers, no sooner
local CITY_MINUTES = 60     -- the city's own, at most this often
local OPEN_GROUND = 4       -- patches of rebel ground under open sky before the city's own shell it
local ADOPT = 30            -- seconds to look for a canister's headcrabs once it is down
local CUBBAGE_AFTER = 60    -- seconds before Cubbage answers on Freq 7
local PITCH = 60            -- the canister's way down, degrees below the horizon
local HEIGHT = 2000         -- launched this far above where it lands
local DAMAGE, RADIUS = 75, 250 -- what a loaded canister's landing does to whoever is under it
local LAND_HERE = 8192      -- spawnflag: land exactly where it is put
local KINDS = { { 0, 6 }, { 1, 3 }, { 2, 1 } } -- the canister's headcrabs: normal, fast, poison (weights)
local CLASS_OF = { [0] = "npc_headcrab", [1] = "npc_headcrab_fast", [2] = "npc_headcrab_poison" }
local CRAB = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_poison = true, npc_headcrab_black = true }
local MORALE, RESIST = -5, -3 -- her order's cost, as the crackdown's
local APART = 600           -- canisters, and what goes under cover, at least this far apart

LC.ShellingConst = { SHELLS = SHELLS, CRABS = CRABS, GAP = GAP, FLIGHT = FLIGHT, COOLDOWN_MINUTES = COOLDOWN_MINUTES,
    CITY_MINUTES = CITY_MINUTES, OPEN_GROUND = OPEN_GROUND, ADOPT = ADOPT, CUBBAGE_AFTER = CUBBAGE_AFTER, MORALE = MORALE, RESIST = RESIST }

local function BName(n) return LC.BlockName and LC.BlockName(n) or ("Block " .. tostring(n)) end
local function BlockAt(pos) return LC.LedgerBlockAt and LC.LedgerBlockAt(pos) end
local function OpenSky(p) return not LC.TerritoryOpenSky or LC.TerritoryOpenSky(p) end

LC.ShellNext = LC.ShellNext or 0         -- no shelling before this (CurTime)
LC.ShellCityNext = LC.ShellCityNext or 0 -- the city's own, not before this
local landings = {}                      -- canisters down and their headcrabs being looked for

local function SetNext(t)
    LC.ShellNext = t
    SetGlobal2Float("lc_shell_next", t) -- (her F2 greys the order until then)
end

-- The districts the Resistance hold, most firmly theirs first.
function LC.ShellTargets()
    local out = {}
    for _, n in ipairs(LC.BlockNumbers and LC.BlockNumbers() or {}) do
        if LC.DistrictOwner and LC.DistrictOwner(n) == "resistance" then out[#out + 1] = n end
    end
    table.sort(out, function(a, b) return (LC.DistrictControl and LC.DistrictControl(a) or 0) > (LC.DistrictControl and LC.DistrictControl(b) or 0) end)
    return out
end

-- Rebel ground grown under open sky: { [block] = { patch, ... } } and how many in all.
function LC.ShellOpenRebelGround()
    local by, total = {}, 0
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if z.grown and z.pos and OpenSky(z.pos) then
            local n = BlockAt(z.pos)
            if n then
                by[n] = by[n] or {}
                table.insert(by[n], z)
                total = total + 1
            end
        end
    end
    return by, total
end

-- The infestation placed in the editor nearest district n (what the patches belong to), or nil.
local function SeedFor(n)
    local c = LC.BlockCenter and LC.BlockCenter(n)
    if not c then return nil end
    local best, bd
    for _, z in ipairs(LC.TerritorySeeds and LC.TerritorySeeds("infest") or {}) do
        local d = z.pos:DistToSqr(c)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

-- Why it can't happen now (nil: it can).
local function Busy()
    if LC.SpeechSession and LC.SpeechSession() then return "Not during the Administrator's address." end
    if GetGlobal2String("lc_event", "") ~= "" then return "Not while an event is on." end
    if LC.CollapseActive and LC.CollapseActive() then return "Not now." end
    return nil
end

-- The canister itself (the game's own, with its own sounds and smoke). loaded false: empty and
-- harmless (the one for what goes under cover), opened by hand so it still pops and hisses.
local function Fire(pos, kind, loaded)
    local can = ents.Create("env_headcrabcanister")
    if not IsValid(can) then return nil end
    can:SetPos(pos + Vector(0, 0, 4))
    can:SetAngles(Angle(PITCH, math.random(0, 359), 0))
    can:SetKeyValue("spawnflags", tostring(LAND_HERE))
    can:SetKeyValue("HeadcrabType", tostring(kind))
    can:SetKeyValue("HeadcrabCount", tostring(loaded and CRABS or 0))
    can:SetKeyValue("FlightSpeed", "3000")
    can:SetKeyValue("FlightTime", tostring(FLIGHT))
    can:SetKeyValue("StartingHeight", tostring(HEIGHT))
    can:SetKeyValue("Damage", tostring(loaded and DAMAGE or 0))
    can:SetKeyValue("DamageRadius", tostring(loaded and RADIUS or 0))
    can:SetKeyValue("SmokeLifetime", "30")
    can:Spawn()
    can:Fire("FireCanister", "", 0)
    if not loaded then can:Fire("OpenCanister", "", FLIGHT + 1) end
    -- (the empty canister stays a while as wreckage, then goes)
    timer.Simple(FLIGHT + 180, function() if IsValid(can) then can:Remove() end end)
    return can
end

local function PickKind()
    local total = 0
    for _, k in ipairs(KINDS) do total = total + k[2] end
    local r = math.random() * total
    for _, k in ipairs(KINDS) do
        r = r - k[2]
        if r <= 0 then return k[1] end
    end
    return 0
end

-- The canister's headcrabs are the infestation's own (counted, cleared and hunted like any).
hook.Add("OnEntityCreated", "LivingCityShelling", function(e)
    if not next(landings) or not IsValid(e) or not CRAB[e:GetClass()] then return end
    timer.Simple(0, function()
        if not IsValid(e) or (LC.NPCs and LC.NPCs[e]) then return end
        local pos = e:GetPos()
        for _, l in ipairs(landings) do
            if l.down and pos:DistToSqr(l.pos) < 500 * 500 and LC.RegisterNPC then
                local st = LC.RegisterNPC(e, "zombie")
                if st then st.zone = l.z end
                l.got = l.got + 1
                return
            end
        end
    end)
end)

-- The patch where it came down (rebel ground there is lost to them first).
local function Patch(l)
    if l.rebel and LC.RecedeTerritory then LC.RecedeTerritory(l.rebel, "shelled") end
    if l.seed and LC.TerritoryCanGrow and LC.TerritoryCanGrow(l.seed) and LC.GrowTerritory then
        l.z = LC.GrowTerritory(l.seed, l.pos, l.r, "shelled")
    end
    if LC.DistrictInfestForget then LC.DistrictInfestForget() end
end

local function LetOut(l)
    if not LC.SpawnZombie then return end
    for i = 1, CRABS do
        local a = i * math.pi * 2 / CRABS
        LC.SpawnZombie(l.pos + Vector(math.cos(a) * 40, math.sin(a) * 40, 8), l.z, CLASS_OF[l.kind] or "npc_headcrab")
    end
end

-- A loaded canister down: the patch, then its headcrabs looked for (or let out by hand).
local function Landed(l)
    l.down = true
    Patch(l)
    timer.Simple(ADOPT, function()
        for i, q in ipairs(landings) do if q == l then table.remove(landings, i) break end end
        -- none came out (no canister in this game, or it never opened): they're let out where it came down
        if l.got == 0 then LetOut(l) end
        hook.Run("LivingCityShellCrabs", l.pos, l.z, l.got)
    end)
end

-- What went under cover: the patch and the headcrabs there, as its canister lands.
local function Below(l)
    Patch(l)
    LetOut(l)
    hook.Run("LivingCityShellCrabs", l.pos, l.z, CRABS)
end

-- The district's rebel ground (a rebel zone in it), to put what goes under cover near.
local function RebelGround(n)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if BlockAt(z.pos) == n then return z.pos end
    end
    return nil
end

-- What follows a shelling: the bulletin, the PA, Cubbage on Freq 7.
local function Aftermath(n)
    if LC.LedgerNews then LC.LedgerNews(string.format("The Combine shelled %s with headcrabs.", BName(n))) end
    if LC.TriggerAnnouncements then LC.TriggerAnnouncements("shelled", { delay = 1 }) end
    timer.Simple(CUBBAGE_AFTER, function()
        local path = LC.CubbageClip and LC.CubbageClip("shelled")
        local words = LC.SpeechAnswerLines and LC.SpeechAnswerLines.shelled
        if path and words and LC.Freq7CutIn then LC.Freq7CutIn(path, words) end
    end)
end

-- Plan and send a shelling on district n. aimRebel: only the Resistance's ground in the open (the
-- city's own). Returns how many come down, how many canisters, how many under cover; or nil and why not.
local function Shell(n, by, aimRebel)
    local seed = SeedFor(n)
    local center = LC.BlockCenter(n)
    local plan, taken, opens = {}, {}, {} -- (taken: everything placed; opens: where canisters come down)
    local function Free(p, list)
        for _, t in ipairs(list or taken) do if t:DistToSqr(p) < APART * APART then return false end end
        return true
    end
    local function Add(entry)
        taken[#taken + 1] = entry.pos
        if not entry.below then opens[#opens + 1] = entry.pos end
        plan[#plan + 1] = entry
    end
    -- the Resistance's ground in the open first
    local open = LC.ShellOpenRebelGround()
    for _, z in ipairs(open[n] or {}) do
        if #plan >= SHELLS then break end
        if Free(z.pos) then Add({ pos = z.pos, r = math.Clamp(z.r or 300, 200, 500), rebel = z }) end
    end
    if not aimRebel then
        local function InDistrict(p) return BlockAt(p) == n and Free(p) end
        -- the district's own open ground
        while #plan < SHELLS do
            local pos, r = LC.TerritoryShellSpot(seed, center, InDistrict)
            if not pos then break end
            Add({ pos = pos, r = r })
        end
        -- the rest under cover (tunnels, sewers, rooms) nearest its rebel ground
        local near = RebelGround(n) or center
        while #plan < SHELLS do
            local pos, r = LC.TerritoryShellSpot(seed, near, InDistrict, "covered")
            if not pos then break end
            Add({ pos = pos, r = r, below = true })
        end
    end
    if #plan == 0 then return nil, "Nowhere in " .. BName(n) .. " for them to take root." end
    -- their canisters on the open ground nearest the district, never in a block the Combine hold
    local function Safe(p)
        local b = BlockAt(p)
        if b and LC.DistrictOwner and LC.DistrictOwner(b) == "combine" then return false end
        return Free(p, opens) -- (right above a tunnel is fine: it brings nothing down with it)
    end
    local landed, covered = 0, 0
    for _, sp in ipairs(plan) do
        if sp.below then
            covered = covered + 1
            sp.land = LC.TerritoryShellSpot(nil, center, Safe, "nearest")
            if sp.land then opens[#opens + 1] = sp.land end
        end
        if not sp.below or sp.land then landed = landed + 1 end
    end
    SetNext(CurTime() + COOLDOWN_MINUTES * 60)
    for i, sp in ipairs(plan) do
        local l = { pos = sp.pos, r = sp.r, seed = seed, kind = PickKind(), got = 0, n = n, below = sp.below, land = sp.land, rebel = sp.rebel }
        if not l.below then landings[#landings + 1] = l end
        timer.Simple((i - 1) * GAP, function()
            if l.below then
                if l.land then Fire(l.land, l.kind, false) end
                timer.Simple(FLIGHT, function() Below(l) end)
            else
                Fire(l.pos, l.kind, true)
                timer.Simple(FLIGHT, function() Landed(l) end)
            end
        end)
    end
    Aftermath(n)
    LC.Log("info", string.format("Shelling: %d on %s (%s), %d under cover, %d canister(s)%s", #plan, BName(n), IsValid(by) and by:Nick() or "the city's own",
        covered, landed, seed and "" or ", no infestation placed in the editor: headcrabs only"))
    hook.Run("LivingCityShelled", n, by, #plan)
    return #plan, landed, covered
end

-- Shell district n now. by: the Administrator who ordered it (nil: staff).
function LC.ShellDistrict(n, by)
    n = tonumber(n)
    if not n or not (LC.BlockCenter and LC.BlockCenter(n)) then return nil, "Which district?" end
    if not LC.TerritoryShellSpot then return nil, "No territory here." end
    return Shell(n, by, false)
end

-- The city's own: when the Resistance hold districts and their ground there has spread into the open,
-- OPEN_GROUND patches or more in all, the one of those districts with the most.
function LC.ShellRebelGround()
    local by = LC.ShellOpenRebelGround()
    local total, best, bn = 0, nil, nil
    for n, list in pairs(by) do
        if LC.DistrictOwner and LC.DistrictOwner(n) == "resistance" then
            total = total + #list
            if not bn or #list > bn then best, bn = n, #list end
        end
    end
    if total < OPEN_GROUND then return nil, "not enough of the Resistance's ground in the open" end
    return Shell(best, nil, true)
end

-- Her order (F2 > City orders; it arrives with her other orders: sv_livingcity_ledger.lua's PlayerSay).
function LC.OrderShelling(ply, n)
    if not (LC.IsAdministrator and LC.IsAdministrator(ply)) then return false, "Only the City Administrator orders a shelling." end
    n = tonumber(n)
    if not n then return false, "Which district?" end
    if LC.DistrictOwner and LC.DistrictOwner(n) ~= "resistance" then return false, BName(n) .. " isn't in the Resistance's hands." end
    if CurTime() < LC.ShellNext then return false, "The canisters aren't ready yet." end
    local why = Busy()
    if why then return false, why end
    local k, err = LC.ShellDistrict(n, ply)
    if not k then return false, err end
    if LC.LedgerAdd then LC.LedgerAdd("morale", MORALE, nil) LC.LedgerAdd("resistance", RESIST, nil) end
    return true
end

hook.Add("Initialize", "LivingCityShelling", function() if LC.MenuActions then LC.MenuActions.shell = true end end)
if LC.MenuActions then LC.MenuActions.shell = true end

timer.Create("LivingCityShelling", 60, 0, function()
    local ok, err = LC.Try(function()
        if not LC.Running then return end
        local now = CurTime()
        if now < LC.ShellNext or now < LC.ShellCityNext or Busy() then return end
        if LC.ShellRebelGround() then LC.ShellCityNext = now + CITY_MINUTES * 60 end
    end)
    if not ok and LC.Error then LC.Error("shelling", err) end
end)

-- For lc_territory: when the next can come, and the rebel ground in the open.
function LC.ShellingStatus()
    local now = CurTime()
    local t = {}
    if LC.ShellNext > now then t[#t + 1] = string.format("Shelling: the canisters are ready in about %d min.", math.ceil((LC.ShellNext - now) / 60)) end
    local _, total = LC.ShellOpenRebelGround()
    t[#t + 1] = string.format("Shelling: %d patch(es) of rebel ground in the open (the city's own shell it from %d).", total, OPEN_GROUND)
    return t
end
