--[[
    Living City: burning the confiscated contraband (the owner, 7 November)

    What units confiscate no longer just vanishes. It goes into the evidence
    stock (kept in memory: a restart or map change empties it):

      Searches          a unit's or a security NPC's search of a player, a
                        unit's pat-down of an NPC citizen, the pat-down game
      Arrest            what processing takes off you
      Raids             what a block inspection finds lying about, and the
                        stashes it turns out; a sweep reaching people's homes
      Odds and ends     a busted dealer's stock, a Resistance supply crate, a
                        confiscated letter

    Burning it. After an inspection sweep or a block raid (with 3 or more
    items in stock), or once 8 or more have built up (at most one automatic
    burn in 10 minutes), the city burns it in public:

      1  Up to three Civil Protection NPCs nearby carry it in boxes to the
         square: in front of a loudspeaker (the PA), else a giant screen, an
         exercise yard, a ration dispenser, a place people stand about or a
         patrol point; the busiest one, by how much of the city is near it.
         With no free unit nearby, two come from out of sight, only while
         there's room under lc_npc_budget (and they go again afterwards).
         None at all: the pile is made anyway.
      2  The pile: each thing lies there as itself (a radio, a gun, papers).
         The PA calls the citizens to assemble, and up to ten of the city's
         citizens nearby come and stand round it. Freq 7 hears where it is.
         For 20 seconds, before it catches, anyone who isn't a unit can press
         E on something in the pile and take it back: wanted for it if a
         unit sees.
      3  It burns: fire and smoke, about 50 seconds. Then everything is gone
         and everyone goes back to what they were doing.

    Never during a secret ending or a dream (LC.EndingBusy), nor in a curfew
    or a lockdown (the citizens are indoors). Seen and started from the menus:
    Unit tools (F2) show the stock, and admins have "Burn it now" there and
    in the admin tools (The city). Admin console extra: lc_burn_evidence.
]]

if CLIENT then return end

LC = LC or {}

local CARRY_LIMIT = 90   -- seconds for the carriers to get there; after that the pile is made anyway
local KINDLE      = 20   -- seconds the pile stands before it catches (the citizens gather; the snatching window)
local BURN        = 50   -- seconds it burns
local AUTO_AT     = 8    -- this many in stock: burned without waiting for a sweep
local AFTER_MIN   = 3    -- after a sweep or a raid: burned if at least this many
local AFTER_DELAY = 25   -- seconds after the sweep or raid ends
local AUTO_GAP    = 600  -- seconds between automatic burns
local MAX_PROPS   = 18   -- things lying in the pile (more still burn, inside it)
local MAX_STOCK   = 150  -- the evidence room keeps at most this many (the oldest go first)
local CARRIERS    = 3
local WATCHERS    = 10
local CARRIER_R   = 5000
local WATCH_R     = 2500
local BOX         = "models/props_junk/cardboard_box001a.mdl"
local LOOSE_BOX   = "models/props_junk/cardboard_box004a.mdl"
local PA_LINE     = "npc/overwatch/cityvoice/f_trainstation_assemble_spkr.wav"
local DROP_ANIM   = { "ACT_PICKUP_GROUND", "ACT_COVER_LOW", "crouchidle" }

LC.EvidenceStock = LC.EvidenceStock or {} -- { key, id, name, model, n, from }
if LC.EvidenceAuto == nil then LC.EvidenceAuto = true end -- (the tests turn the automatic burns off, and test them on their own)

local GUN_MODELS = {
    weapon_pistol = "models/weapons/w_pistol.mdl", weapon_357 = "models/weapons/w_357.mdl", weapon_smg1 = "models/weapons/w_smg1.mdl",
    weapon_ar2 = "models/weapons/w_irifle.mdl", weapon_shotgun = "models/weapons/w_shotgun.mdl", weapon_crowbar = "models/weapons/w_crowbar.mdl",
    weapon_crossbow = "models/weapons/w_crossbow.mdl", weapon_frag = "models/weapons/w_grenade.mdl", weapon_rpg = "models/weapons/w_rocket_launcher.mdl",
    weapon_slam = "models/weapons/w_slam.mdl",
}
-- What an NPC citizen was found with (sv_livingcity_underground.lua), as the item it is, where there's one.
local LOOSE_ID = {
    ["an unregistered radio"] = "radio", ["forged ration coupons"] = "ration_forged", ["a handful of pistol rounds"] = "ammo_pistol",
    ["black market rations"] = "ration", ["a crowbar wrapped in newspaper"] = "w:weapon_crowbar",
}
-- The rest: a model by what it is.
local LOOSE_MODELS = {
    { "radio", "models/props_lab/citizenradio.mdl" }, { "pamphlet", "models/props_c17/paper01.mdl" }, { "leaflet", "models/props_c17/paper01.mdl" },
    { "letter", "models/props_c17/paper01.mdl" }, { "armband", "models/props_c17/paper01.mdl" }, { "coupon", "models/props_c17/paper01.mdl" },
    { "ration", "models/weapons/w_package.mdl" }, { "crowbar", "models/weapons/w_crowbar.mdl" }, { "round", "models/items/boxsrounds.mdl" },
    { "supplies", "models/props_junk/cardboard_box002a.mdl" }, { "stock", "models/props_junk/cardboard_box002a.mdl" },
}

local function GunName(cls) return (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " ")) end

local function GunModel(cls)
    if GUN_MODELS[cls] then return GUN_MODELS[cls] end
    local w = weapons and weapons.Get and weapons.Get(cls)
    return (w and w.WorldModel and w.WorldModel ~= "") and w.WorldModel or LOOSE_BOX
end

local function Tell(ply, kind, text)
    if not IsValid(ply) then print("[Evidence] " .. text) return end
    if LC.Notice then LC.Notice(ply, kind, "Evidence", text) end
    ply:ChatPrint("[Evidence] " .. text)
end

------------------------------------------------------------------------
-- The stock
------------------------------------------------------------------------

function LC.EvidenceTotal()
    local n = 0
    for _, e in ipairs(LC.EvidenceStock) do n = n + e.n end
    return n
end

local function Summary(list, most)
    local names = {}
    for i, e in ipairs(list) do
        if i > (most or 6) then names[#names + 1] = string.format("and %d more kinds", #list - (most or 6)) break end
        names[#names + 1] = e.name .. (e.n > 1 and (" x" .. e.n) or "")
    end
    return table.concat(names, ", ")
end

-- One line for the menus: what's in the evidence room, and any burn going on.
function LC.EvidenceStatus()
    local n = LC.EvidenceTotal()
    local s = n > 0 and string.format("In the evidence room: %d item%s (%s).", n, n == 1 and "" or "s", Summary(LC.EvidenceStock))
        or "The evidence room is empty."
    local b = LC.EvidenceBurn
    if b then s = s .. " Being burned now " .. b.place .. "." end
    return s
end

local function Publish()
    SetGlobal2Int("lc_evidence_n", LC.EvidenceTotal())
    SetGlobal2String("lc_evidence_list", #LC.EvidenceStock > 0 and Summary(LC.EvidenceStock) or "")
    local b = LC.EvidenceBurn
    SetGlobal2String("lc_evidence_burn", b and (({ carry = "being carried to the fire ", pile = "piled up ", burning = "burning " })[b.phase] or "") .. b.place or "")
end
LC.EvidencePublish = Publish

-- Into the stock. id: an item id, or "w:<weapon class>", or nil with a name (what an NPC had).
function LC.EvidenceAdd(id, n, from, name, model)
    n = math.floor(tonumber(n) or 1)
    if n < 1 then return false end
    if not id and name and LOOSE_ID[name] then id = LOOSE_ID[name] end
    if isstring(id) and string.sub(id, 1, 2) == "w:" then
        local cls = string.sub(id, 3)
        name, model = GunName(cls), model or GunModel(cls)
    elseif id and LCS and LCS.Items and LCS.Items[id] then
        local it = LCS.Items[id]
        name, model = it.name or id, model or it.model
    else
        id = nil
        name = tostring(name or "something")
        if not model then
            local low = string.lower(name)
            for _, m in ipairs(LOOSE_MODELS) do if string.find(low, m[1], 1, true) then model = m[2] break end end
        end
    end
    local key = id or ("loose:" .. name)
    local entry
    for _, e in ipairs(LC.EvidenceStock) do if e.key == key then entry = e break end end
    if entry then
        entry.n = entry.n + n
    else
        entry = { key = key, id = id, name = name, model = model or LOOSE_BOX, n = n, from = from or "search" }
        LC.EvidenceStock[#LC.EvidenceStock + 1] = entry
    end
    -- the evidence room isn't bottomless: the oldest goes first
    local over = LC.EvidenceTotal() - MAX_STOCK
    while over > 0 and #LC.EvidenceStock > 0 do
        local e = LC.EvidenceStock[1]
        local take = math.min(e.n, over)
        e.n, over = e.n - take, over - take
        if e.n <= 0 then table.remove(LC.EvidenceStock, 1) end
    end
    Publish()
    return true
end

-- A list as the searches give it: { { id, n } }, and the guns taken (classes).
function LC.EvidenceAddList(found, guns, from)
    for _, f in ipairs(found or {}) do LC.EvidenceAdd(f.id, f.n, from) end
    for _, cls in ipairs(guns or {}) do LC.EvidenceAdd("w:" .. cls, 1, from) end
end

-- Something a raid found lying about (sv_livingcity_raids.lua), just before it's taken away.
function LC.EvidenceFromEntity(ent, from)
    if not IsValid(ent) or ent.lcEvidence then return false end
    local cls = ent:GetClass()
    if cls == "lc_item" then return LC.EvidenceAdd(ent:GetNW2String("lc_item", ""), 1, from) end
    if string.StartWith(cls, "weapon") then return LC.EvidenceAdd("w:" .. cls, 1, from) end
    local name = LC.ContrabandOf and LC.ContrabandOf(ent) or "something"
    return LC.EvidenceAdd(nil, 1, from, name, ent:GetModel())
end

------------------------------------------------------------------------
-- Where: the square
------------------------------------------------------------------------

-- The candidate with the most of the city's placed points around it: the busiest, the square more or less.
local function Busiest(cands)
    if #cands <= 1 then return cands[1] end
    local best, bn
    for _, c in ipairs(cands) do
        local n = 0
        for _, p in ipairs(LC.Points or {}) do if p.pos and p.pos:DistToSqr(c.pos) < 1200 * 1200 then n = n + 1 end end
        if not bn or n > bn then best, bn = c, n end
    end
    return best
end

local function Ground(v) return LC.GroundAt and LC.GroundAt(v) or v end

-- Where the pile goes: pos, yaw. nil when the city has nowhere at all.
function LC.EvidenceSpot()
    local function FromEnts(cls, out)
        local c = {}
        for _, e in ipairs(LC.EntsOf and LC.EntsOf(cls) or ents.FindByClass(cls)) do
            if IsValid(e) then
                local yaw = (e:GetAngles() or Angle()).y or 0
                c[#c + 1] = { pos = e:GetPos() + Angle(0, yaw, 0):Forward() * out, yaw = yaw }
            end
        end
        return c
    end
    local function FromPoints(kind, out)
        local c = {}
        for _, p in ipairs(LC.Points or {}) do
            if p.kind == kind and p.pos then c[#c + 1] = { pos = p.pos + Angle(0, p.yaw or 0, 0):Forward() * out, yaw = p.yaw or 0 } end
        end
        return c
    end
    local tries = {
        function() return FromEnts("lc_loudspeaker", 160) end, -- the PA
        function() return FromEnts("lc_screen", 220) end,      -- a Breencast screen
        function() return FromPoints("yard", 300) end,         -- the exercise yard
        function() return FromEnts("lc_dispenser", 200) end,   -- where the rations are handed out
        function() return FromPoints("idle", 0) end,
        function() return FromPoints("patrol", 0) end,
    }
    for _, t in ipairs(tries) do
        local c = Busiest(t())
        if c then return Ground(c.pos), c.yaw end
    end
    return nil
end

------------------------------------------------------------------------
-- The burn
------------------------------------------------------------------------

local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "in the square" end

local function Ring(b, i, of, r)
    return Ground(b.pos + Angle(0, b.yaw + i * (360 / math.max(1, of)), 0):Forward() * r)
end

local function PileSpot(b, i)
    local a = math.rad(i * 137.5)
    local r = 6 + 7 * math.sqrt(i)
    return b.pos + Vector(math.cos(a) * r, math.sin(a) * r, 2 + (i % 3) * 3)
end

local function SpawnProp(b, entry)
    if #b.props >= MAX_PROPS then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(entry.model or LOOSE_BOX)
    e:SetPos(PileSpot(b, #b.props + 1))
    e:SetAngles(Angle(math.random(-20, 20), math.random(0, 359), math.random(-30, 30)))
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if e.SetCollisionGroup then e:SetCollisionGroup(COLLISION_GROUP_DEBRIS or 1) end
    e.lcEvidence = { burn = b, entry = entry }
    e:SetNW2Bool("lc_evidence", true)
    b.props[#b.props + 1] = e
    return e
end

-- A carrier got there (or never will): what they carried goes on the pile.
local function Deliver(b, c)
    if c.delivered then return end
    c.delivered = true
    for _, entry in ipairs(c.share) do
        if not entry.placed then entry.placed = true SpawnProp(b, entry) end
    end
    if sound and sound.Play then sound.Play("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", b.pos, 65) end
end

local function Seen(ply)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 1500) then return true end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p) and p:GetPos():DistToSqr(ply:GetPos()) < 900 * 900 then
            local tr = util.TraceLine({ start = p:EyePos(), endpos = ply:EyePos(), mask = MASK_OPAQUE, filter = p })
            if not tr.Hit or tr.Fraction > 0.97 then return true end
        end
    end
    return false
end

-- Units for the carrying, citizens to watch: free ones, nearest first.
local function Free(npc, st, role)
    if not IsValid(npc) or npc:Health() <= 0 or st.role ~= role or st.test or st.unmanaged or st.questLock or st.npcWork
        or st.raid or st.skirmish or (st.state ~= "idle" and st.state ~= "moving") then return false end
    if LC.EventSpare then return LC.EventSpare(npc, st, role) end
    return true
end

local function Nearest(role, pos, r, want)
    local list = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if Free(npc, st, role) then
            local d = npc:GetPos():DistToSqr(pos)
            if d < r * r then list[#list + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(list, function(a, c) return a.d < c.d end)
    while #list > want do table.remove(list) end
    return list
end

local function Budget()
    local cv = GetConVar("lc_npc_budget")
    return cv and cv:GetInt() or 60
end

local function CityCount()
    if LC.CityNPCCount then return LC.CityNPCCount() end
    return table.Count(LC.NPCs or {})
end

local function SendCarrier(b, c, i, of)
    local npc, st = c.npc, c.st
    if not LC.NPCWorkDispatch then return false end
    return LC.NPCWorkDispatch(npc, st, "evidence_carry", "carrying confiscated contraband to the fire", {
        onStart = function(n, s) if LC.NPCCarry then LC.NPCCarry(n, s, BOX) end end,
        steps = {
            { pos = Ring(b, i, of, 60), face = b.pos, secs = 2, anim = DROP_ANIM, doing = "putting confiscated contraband on the pile",
              check = function() return LC.EvidenceBurn == b end,
              done = function(n, s) if LC.NPCDropCarry then LC.NPCDropCarry(n, s) end Deliver(b, c) end },
            { pos = Ring(b, i + 0.5, of, 170), face = b.pos, secs = CARRY_LIMIT + KINDLE + BURN + 60, doing = "guarding the fire",
              check = function() return LC.EvidenceBurn == b end },
        },
    })
end

-- What's in stock goes to the fire. why: "auto", "admin". Returns ok, message.
function LC.EvidenceCanBurn()
    if LC.EvidenceBurn then return false, "Something is already being burned." end
    if LC.EndingBusy and LC.EndingBusy() or LC.TimeStopped then return false, "Not during an ending or a dream." end
    if not LC.Running then return false, "The city isn't running." end
    if LC.Event == "curfew" or LC.Event == "lockdown" then return false, "Not in a curfew or a lockdown: wait till it's over." end
    if #LC.EvidenceStock == 0 then return false, "The evidence room is empty: nothing to burn." end
    return true
end

function LC.EvidenceStartBurn(why)
    local ok, whyNot = LC.EvidenceCanBurn()
    if not ok then return false, whyNot end
    local pos, yaw = LC.EvidenceSpot()
    if not pos then
        return false, "Nowhere to burn it: place a loudspeaker, a giant screen, an exercise yard or a ration dispenser with the editor."
    end
    local now = CurTime()
    local b = { phase = "carry", pos = pos, yaw = yaw or 0, place = Where(pos), entries = LC.EvidenceStock, props = {}, fx = {},
        carriers = {}, watchers = {}, spawned = {}, t0 = now, why = why or "auto" }
    LC.EvidenceStock = {}
    LC.EvidenceBurn = b
    -- the carriers: free units nearby, else two from out of sight while there's room under the cap
    local units = Nearest("cop", pos, CARRIER_R, CARRIERS)
    if #units == 0 and LC.SpawnCop then
        for k = 1, 2 do
            if CityCount() >= Budget() then break end
            local from = LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos) or nil
            if not from then break end
            local npc, st = LC.SpawnCop(from + Vector(k * 30, 0, 4))
            if IsValid(npc) and st then
                st.unmanaged, st.eventNPC, st.leaveAt, st.routeGroup = true, true, nil, nil -- (counted against lc_npc_budget till they go)
                b.spawned[npc] = from
                units[#units + 1] = { npc = npc, st = st }
            end
        end
    end
    for i, u in ipairs(units) do b.carriers[i] = { npc = u.npc, st = u.st, share = {} } end
    for i, entry in ipairs(b.entries) do
        local c = #b.carriers > 0 and b.carriers[(i - 1) % #b.carriers + 1]
        if c then c.share[#c.share + 1] = entry end
    end
    for i, c in ipairs(b.carriers) do
        if not SendCarrier(b, c, i, #b.carriers) then Deliver(b, c) end -- (no way there: it's on the pile anyway)
    end
    Publish()
    LC.Log("info", string.format("Evidence burn (%s) %s: %d item(s), %d carrier(s)", b.why, b.place, LC.EvidenceTotalOf(b.entries), #b.carriers))
    hook.Run("LivingCityEvidenceBurnStarted", b)
    return true, string.format("%d item%s going to the fire %s.", LC.EvidenceTotalOf(b.entries), LC.EvidenceTotalOf(b.entries) == 1 and "" or "s", b.place)
end

function LC.EvidenceTotalOf(list)
    local n = 0
    for _, e in ipairs(list or {}) do n = n + e.n end
    return n
end

-- The pile is made: everyone hears, the citizens come to watch.
local function BuildPile(b, now)
    for _, c in ipairs(b.carriers) do Deliver(b, c) end
    for _, entry in ipairs(b.entries) do if not entry.placed then entry.placed = true SpawnProp(b, entry) end end
    b.phase, b.pileAt, b.igniteAt = "pile", now, now + KINDLE
    local list = Summary(b.entries, 4)
    if LC.Announce then
        LC.Announce("evidence_burn", PA_LINE, string.format("Confiscated contraband (%s) is being burned %s. Citizens: assemble and witness.", list, b.place))
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "They've piled up what they confiscated to burn it " .. b.place
            .. ". Before it catches, E on something in the pile takes it back. Don't let a unit see you.")
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and not (LC.PlayerIsCP and LC.PlayerIsCP(p)) and p:GetPos():DistToSqr(b.pos) < 1500 * 1500 then
            Tell(p, "info", "Confiscated contraband is piled up here to be burned. Before it catches, press E on something in the pile to take it back (wanted, if a unit sees you).")
        end
    end
    local cits = Nearest("citizen", b.pos, WATCH_R, WATCHERS)
    for i, u in ipairs(cits) do
        local spot = Ring(b, i + math.Rand(-0.3, 0.3), #cits, math.Rand(230, 330))
        if LC.NPCWorkDispatch and LC.NPCWorkDispatch(u.npc, u.st, "evidence_watch", "watching the contraband burn", {
            steps = { { pos = spot, face = b.pos, secs = KINDLE + BURN + 60, doing = "watching the contraband burn",
                check = function() return LC.EvidenceBurn == b end } } }) then
            b.watchers[#b.watchers + 1] = u.npc
        end
    end
    Publish()
end

local function Ignite(b, now)
    b.phase, b.endAt = "burning", now + BURN
    if sound and sound.Play then sound.Play("ambient/fire/ignite.wav", b.pos, 85) end
    pcall(function()
        local f = ents.Create("env_fire")
        if not IsValid(f) then return end
        f:SetPos(b.pos)
        f:SetKeyValue("health", tostring(BURN + 5))
        f:SetKeyValue("firesize", "110")
        f:SetKeyValue("fireattack", "2")
        f:SetKeyValue("damagescale", "0")
        f:SetKeyValue("spawnflags", tostring(4 + 128))
        f:Spawn()
        f:Fire("StartFire", "", 0)
        b.fx[#b.fx + 1] = f
    end)
    pcall(function()
        local s = ents.Create("env_smokestack")
        if not IsValid(s) then return end
        s:SetPos(b.pos + Vector(0, 0, 30))
        for k, v in pairs({ InitialState = "1", BaseSpread = "18", SpreadSpeed = "12", Speed = "70", StartSize = "30", EndSize = "140",
            Rate = "14", JetLength = "380", WindAngle = "0 0 0", WindSpeed = "0", SmokeMaterial = "particle/SmokeStack.vmt",
            rendercolor = "45 45 45", renderamt = "200" }) do s:SetKeyValue(k, v) end
        s:Spawn()
        if s.Activate then s:Activate() end
        s:Fire("TurnOn", "", 0)
        b.fx[#b.fx + 1] = s
    end)
    for _, e in ipairs(b.props) do
        if IsValid(e) then
            if e.Ignite then e:Ignite(BURN) end
            if e.SetColor then e:SetColor(Color(90, 80, 70, 255)) end
        end
    end
    hook.Run("LivingCityEvidenceIgnited", b)
    Publish()
end

-- Over (or called off: aborted, and what's left goes back in the stock).
local function Finish(b, aborted)
    if LC.EvidenceBurn ~= b then return end
    b.phase = "done"
    LC.EvidenceBurn = nil
    for _, e in ipairs(b.props) do if IsValid(e) then e:Remove() end end
    for _, e in ipairs(b.fx) do if IsValid(e) then e:Remove() end end
    local burned = LC.EvidenceTotalOf(b.entries)
    if aborted then
        for _, entry in ipairs(b.entries) do entry.placed = nil LC.EvidenceAdd(entry.id, entry.n, entry.from, entry.name, entry.model) end
    end
    -- everyone back to what they were doing
    local now = CurTime()
    local people = {}
    for _, c in ipairs(b.carriers) do people[#people + 1] = c.npc end
    for _, n in ipairs(b.watchers) do people[#people + 1] = n end
    for _, npc in ipairs(people) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        local w = st and st.npcWork
        if w and (w.id == "evidence_carry" or w.id == "evidence_watch") then
            if LC.NPCWorkDrop then LC.NPCWorkDrop(npc, st) end
            if LC.SetState then LC.SetState(npc, st, "idle") end
            st.untilT = now + math.Rand(1, 4)
        end
    end
    -- the units who came for it walk back off, and go
    for npc, from in pairs(b.spawned) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if st and LC.NPCWorkDispatch then
            LC.NPCWorkDispatch(npc, st, "evidence_leave", "going back to the station", {
                steps = { { pos = from, secs = 1, done = function(n) if IsValid(n) then n:Remove() end end } } })
        end
        timer.Simple(120, function() if IsValid(npc) then npc:Remove() end end)
    end
    if not aborted then LC.EvidenceNextAuto = now + AUTO_GAP end
    Publish()
    LC.Log("info", string.format("Evidence burn %s %s: %d item(s)", aborted and "called off" or "done", b.place, burned))
    hook.Run(aborted and "LivingCityEvidenceBurnCalledOff" or "LivingCityEvidenceBurned", b, burned)
end
LC.EvidenceFinish = Finish

local function Step(b, now)
    if (LC.EndingBusy and LC.EndingBusy()) or LC.TimeStopped or not LC.Running then return Finish(b, true) end
    if b.phase == "carry" then
        local all = true
        for _, c in ipairs(b.carriers) do if not c.delivered then all = false break end end
        if all or now - b.t0 >= CARRY_LIMIT then BuildPile(b, now) end
    elseif b.phase == "pile" then
        if now >= b.igniteAt then Ignite(b, now) end
    elseif b.phase == "burning" then
        if now >= b.endAt then Finish(b, false) end
    end
end

function LC.EvidenceTick(now)
    now = now or CurTime()
    local b = LC.EvidenceBurn
    if b then return Step(b, now) end
    if not LC.EvidenceAuto then return end
    local total = LC.EvidenceTotal()
    if LC.EvidenceAfterAt and total < AFTER_MIN then LC.EvidenceAfterAt = nil end
    local after = LC.EvidenceAfterAt and now >= LC.EvidenceAfterAt
    local enough = total >= AUTO_AT and now >= (LC.EvidenceNextAuto or 0)
    if not after and not enough then return end
    if LC.EvidenceStartBurn("auto") then LC.EvidenceAfterAt = nil end
end
timer.Create("LivingCityEvidence", 1, 0, function()
    local ok, err = pcall(LC.EvidenceTick, CurTime())
    if not ok and LC.Error then LC.Error("evidence", err) end
end)

-- Burn it now (an admin, from the menus or the console). Returns ok, message.
function LC.EvidenceBurnNow(admin)
    if IsValid(admin) and not admin:IsAdmin() then return false, "Admins only." end
    local ok, msg = LC.EvidenceStartBurn("admin")
    if ok and IsValid(admin) and LC.Log then LC.Log("info", admin:Nick() .. " had the evidence burned") end
    return ok, msg
end

concommand.Add("lc_burn_evidence", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then ply:ChatPrint("Admins only.") return end
    local _, msg = LC.EvidenceBurnNow(ply)
    Tell(ply, "info", msg .. " " .. LC.EvidenceStatus())
end)

------------------------------------------------------------------------
-- Snatching it back before it catches
------------------------------------------------------------------------

function LC.EvidenceSnatch(ply, ent)
    local tag = IsValid(ent) and ent.lcEvidence
    local b = tag and tag.burn
    if not b or LC.EvidenceBurn ~= b or not IsValid(ply) then return false end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return false, "Confiscated contraband, waiting for the fire. It stays where it is." end
    if b.phase == "burning" then return false, "Too late: it's burning." end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 140 * 140 then return false, "Get closer." end
    if ply:GetNW2Bool("lc_tied", false) or (LC.InCustody and LC.InCustody(ply)) then return false, "Not with your hands tied." end
    local entry = tag.entry
    if not entry.id then return false, "Nothing in that worth saving." end
    local n
    if string.sub(entry.id, 1, 2) == "w:" then
        n = 1
        ply:Give(string.sub(entry.id, 3))
    else
        n = entry.n
        if LC.CanCarry and not LC.CanCarry(ply, entry.id, n) then n = 1 end
        if LC.GiveItem(ply, entry.id, n) == false then return false, "Your pockets are full." end
    end
    entry.n = entry.n - n
    if entry.n <= 0 then
        for i, e in ipairs(b.entries) do if e == entry then table.remove(b.entries, i) break end end
        for i, e in ipairs(b.props) do if e == ent then table.remove(b.props, i) break end end
        ent:Remove()
    end
    local what = entry.name .. (n > 1 and (" x" .. n) or "")
    local seen = Seen(ply)
    if seen and LC.ReportCrime then LC.ReportCrime(ply, "Stealing confiscated contraband", 240) end
    hook.Run("LivingCityEvidenceSnatched", ply, entry.id, n, seen)
    Publish()
    if seen then return true, "You snatch " .. what .. " out of the pile, and a unit saw you: you're wanted." end
    return true, "You snatch " .. what .. " out of the pile before it catches. Nobody saw."
end

hook.Add("PlayerUse", "LivingCityEvidenceSnatch", function(ply, ent)
    if not IsValid(ent) or not ent.lcEvidence then return end
    if (ply.lcEvidenceUseAt or 0) > CurTime() then return false end
    ply.lcEvidenceUseAt = CurTime() + 0.6
    local ok, msg = LC.EvidenceSnatch(ply, ent)
    if msg then Tell(ply, ok and "info" or "warn", msg) end
    return false
end)

------------------------------------------------------------------------
-- What goes in
------------------------------------------------------------------------

hook.Add("LivingCitySearched", "LivingCityEvidence", function(_, _, found, guns) LC.EvidenceAddList(found, guns, "search") end)
hook.Add("LivingCityStashRaided", "LivingCityEvidence", function(_, found) LC.EvidenceAddList(found, nil, "raid") end)
hook.Add("LivingCityCacheRaided", "LivingCityEvidence", function() LC.EvidenceAdd(nil, 1, "raid", "a crate of hoarded Resistance supplies") end)
hook.Add("LivingCityLetterConfiscated", "LivingCityEvidence", function() LC.EvidenceAdd(nil, 1, "mail", "a confiscated letter") end)

-- after a sweep or a block raid, what it turned up is burned (once there's a little of it)
hook.Add("LivingCityEventEnded", "LivingCityEvidence", function(was)
    if was == "sweep" or was == "raid" then LC.EvidenceAfterAt = CurTime() + AFTER_DELAY end
end)
hook.Add("LivingCityBlockRaided", "LivingCityEvidence", function() LC.EvidenceAfterAt = CurTime() + AFTER_DELAY end)

hook.Add("LivingCityStopped", "LivingCityEvidence", function()
    if LC.EvidenceBurn then Finish(LC.EvidenceBurn, true) end
end)

Publish()
