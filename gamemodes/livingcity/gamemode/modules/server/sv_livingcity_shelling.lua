--[[
    Living City: headcrab shelling (the owner, 18 November, the long-term plan,
    item 2: "The Combine shell a district the Resistance hold; it raises that
    district's infestation for everyone, so it costs the Combine too")

    Half-Life 2's own headcrab canisters (env_headcrabcanister) come down on a
    district the Resistance hold (sv_livingcity_ledger.lua: a housing block in
    the Resistance's hands): SHELLS of them on open ground with sky above,
    landing within a few seconds of each other. Each one lets out its headcrabs
    and leaves a patch of the infestation where it came down (a patch of the
    nearest infestation placed in the editor, so everything that fights the
    infestation fights it). The district's infestation rises for everyone who
    lives there (sv_livingcity_districtinfest.lua), and past 50 it leaks next
    door, the Combine's blocks too.

    Who orders it: a player City Administrator, on F2 > City orders (morale and
    the Resistance's strength fall); else the city's own Combine, about every
    CITY_MINUTES while the Resistance hold a district (lc_shelling 0 stops the
    city's own; her order stays). Never two within COOLDOWN_MINUTES, never
    during her address, an event or the collapse.

    What players get: the canisters' scream and smoke, the headcrabs, and
    Civil Protection's usual radio line about the infestation spreading. No
    new line of text (house rule 10). Superadmins: F4 > Admin testing tools >
    Testing alone > Shell a district now.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_shelling", "1", FLAGS, "The city's own Combine shell a district the Resistance hold with headcrab canisters now and then (a player Administrator can order it either way)")

local SHELLS = 3            -- canisters in one shelling
local CRABS = 3             -- headcrabs in each
local GAP = 1.2             -- seconds between landings (all inside the radio's one line)
local FLIGHT = 4            -- seconds from the launch to the landing
local COOLDOWN_MINUTES = 45 -- the next shelling, the city's own or hers, no sooner
local CITY_MINUTES = 60     -- the city's own: about this often while the Resistance hold a district
local ADOPT = 30            -- seconds to look for a canister's headcrabs once it is down
local PITCH = 60            -- the canister's way down, degrees below the horizon
local HEIGHT = 2000         -- launched this far above where it lands
local DAMAGE, RADIUS = 75, 250 -- what the landing does to whoever is under it
local KINDS = { { 0, 6 }, { 1, 3 }, { 2, 1 } } -- the canister's headcrabs: normal, fast, poison (weights)
local CLASS_OF = { [0] = "npc_headcrab", [1] = "npc_headcrab_fast", [2] = "npc_headcrab_poison" }
local CRAB = { npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_poison = true, npc_headcrab_black = true }
local MORALE, RESIST = -5, -3 -- her order's cost, as the crackdown's

LC.ShellingConst = { SHELLS = SHELLS, CRABS = CRABS, GAP = GAP, FLIGHT = FLIGHT, COOLDOWN_MINUTES = COOLDOWN_MINUTES,
    CITY_MINUTES = CITY_MINUTES, ADOPT = ADOPT, MORALE = MORALE, RESIST = RESIST }

local function BName(n) return LC.BlockName and LC.BlockName(n) or ("Block " .. tostring(n)) end
local function BlockAt(pos) return LC.LedgerBlockAt and LC.LedgerBlockAt(pos) end

LC.ShellNext = LC.ShellNext or 0        -- no shelling before this (CurTime)
LC.ShellCityAt = LC.ShellCityAt or nil  -- the city's own next one
local landings = {}                     -- canisters down and their headcrabs being looked for

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

-- The canister itself. Returns the entity (or nil when the game has none).
local function Fire(pos, kind)
    local can = ents.Create("env_headcrabcanister")
    if not IsValid(can) then return nil end
    can:SetPos(pos)
    can:SetAngles(Angle(PITCH, math.random(0, 359), 0))
    can:SetKeyValue("HeadcrabType", tostring(kind))
    can:SetKeyValue("HeadcrabCount", tostring(CRABS))
    can:SetKeyValue("FlightSpeed", "3000")
    can:SetKeyValue("FlightTime", tostring(FLIGHT))
    can:SetKeyValue("StartingHeight", tostring(HEIGHT))
    can:SetKeyValue("Damage", tostring(DAMAGE))
    can:SetKeyValue("DamageRadius", tostring(RADIUS))
    can:SetKeyValue("SmokeLifetime", "30")
    can:Spawn()
    can:Fire("FireCanister", "", 0)
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

-- One canister down at pos: the patch, then its headcrabs looked for (or let out by hand).
local function Landed(l)
    l.down = true
    if l.seed and LC.TerritoryCanGrow and LC.TerritoryCanGrow(l.seed) and LC.GrowTerritory then
        l.z = LC.GrowTerritory(l.seed, l.pos, l.r, "shelled")
        if LC.DistrictInfestForget then LC.DistrictInfestForget() end
    end
    timer.Simple(ADOPT, function()
        for i, q in ipairs(landings) do if q == l then table.remove(landings, i) break end end
        -- none came out (no canister in this game, or it never opened): they're let out where it came down
        if l.got == 0 and LC.SpawnZombie then
            for i = 1, CRABS do
                local a = i * math.pi * 2 / CRABS
                LC.SpawnZombie(l.pos + Vector(math.cos(a) * 40, math.sin(a) * 40, 8), l.z, CLASS_OF[l.kind] or "npc_headcrab")
            end
        end
        hook.Run("LivingCityShellCrabs", l.pos, l.z, l.got)
    end)
end

-- Shell district n now. by: the Administrator who ordered it (nil: the city's own, or staff).
-- Returns the number of canisters on their way, or nil and why not.
function LC.ShellDistrict(n, by)
    n = tonumber(n)
    if not n or not (LC.BlockCenter and LC.BlockCenter(n)) then return nil, "Which district?" end
    if not LC.TerritoryShellSpot then return nil, "No territory here." end
    local seed = SeedFor(n)
    local spots = {}
    local function Apart(p)
        if BlockAt(p) ~= n then return false end
        for _, s in ipairs(spots) do if s.pos:DistToSqr(p) < 600 * 600 then return false end end
        return true
    end
    for _ = 1, SHELLS do
        local pos, r = LC.TerritoryShellSpot(seed, LC.BlockCenter(n), Apart)
        if pos then spots[#spots + 1] = { pos = pos, r = r } end
    end
    if #spots == 0 then return nil, "Nowhere in the open in " .. BName(n) .. " for a shell to come down." end
    SetNext(CurTime() + COOLDOWN_MINUTES * 60)
    for i, s in ipairs(spots) do
        local l = { pos = s.pos, r = s.r, seed = seed, kind = PickKind(), got = 0, n = n }
        landings[#landings + 1] = l
        timer.Simple((i - 1) * GAP, function()
            Fire(l.pos, l.kind)
            timer.Simple(FLIGHT, function() Landed(l) end)
        end)
    end
    LC.Log("info", string.format("Shelling: %d canister(s) on %s (%s)%s", #spots, BName(n), IsValid(by) and by:Nick() or "the city's own",
        seed and "" or ", no infestation placed in the editor: headcrabs only"))
    hook.Run("LivingCityShelled", n, by, #spots)
    return #spots
end

-- Her order (F2 > City orders).
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
-- (the order itself arrives with her other orders: sv_livingcity_ledger.lua's PlayerSay)

-- The city's own: while the Resistance hold a district and no player is the Administrator.
local function PlayerAdministrator()
    for _, p in ipairs(player.GetAll()) do if LC.IsAdministrator and LC.IsAdministrator(p) then return p end end
    return nil
end
timer.Create("LivingCityShelling", 60, 0, function()
    local ok, err = LC.Try(function()
        if not LC.Running or not cvOn:GetBool() then LC.ShellCityAt = nil return end
        local targets = LC.ShellTargets()
        if #targets == 0 or PlayerAdministrator() then LC.ShellCityAt = nil return end
        local now = CurTime()
        if not LC.ShellCityAt then LC.ShellCityAt = now + CITY_MINUTES * 60 * math.Rand(0.75, 1.25) return end
        if now < LC.ShellCityAt or now < LC.ShellNext or Busy() then return end
        LC.ShellDistrict(targets[1], nil)
        LC.ShellCityAt = now + CITY_MINUTES * 60 * math.Rand(0.75, 1.25)
    end)
    if not ok and LC.Error then LC.Error("shelling", err) end
end)

-- For the admin panel and lc_territory: when the next can come, and the city's own.
function LC.ShellingStatus()
    local now = CurTime()
    local t = {}
    if LC.ShellNext > now then t[#t + 1] = string.format("Shelling: the canisters are ready in about %d min.", math.ceil((LC.ShellNext - now) / 60)) end
    if LC.ShellCityAt then t[#t + 1] = string.format("Shelling: the city's own in about %d min.", math.max(0, math.ceil((LC.ShellCityAt - now) / 60))) end
    return t
end
