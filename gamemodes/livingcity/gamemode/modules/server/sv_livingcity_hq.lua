--[[
    Living City: the Resistance's headquarters, its later stages (the owner, 22 November, of the HQ's
    first stage, sv_livingcity_base.lua: "yes to all of" the services; the Combine not knowing where it is,
    "but a player must inform ... only players will be leaving the city", and scanners only so long as
    "random scanners aren't flying around all the time outside the city"; the raid order; and of a
    ransack's intel only the sympathizers named).

      What only the live HQ does
        Respawn      a Resistance player last nearest the live HQ (its ground) comes back there, as at the
                     rebel spawn point they were last nearest (sv_livingcity_factions.lua).
        The lab      bypass charges and IEDs are made only by a scientist whose lab stands on the HQ's
                     ground (sv_livingcity_lab.lua, LC.LabHQOnly); with no HQ up, nobody makes them.
        The wounded  rebel NPCs on the HQ's ground heal, a little every few seconds.
      What the Combine know of it (a hidden figure for this site, 0 to 100, back to nothing when the base
      moves; never shown as a number: the Administrator reads "nothing", "rumours", "a district",
      "the street", "the building"). Only players move it:
        Informing    a player who has been on the HQ's ground tells a unit (the Inform list).
        Questioning  a Resistance player in the cells who has been there tells the truth about the hideout
                     (sv_livingcity_interrogation.lua): the HQ is the place they name.
        Scouting     a unit's job (F4): search a rebel territory by hand; if it is the HQ's, they learn.
        A scanner    a unit sends one from the radio's own menu ("Send a scanner to scout"): it flies to
                     where they aim, for a minute and a half; with the HQ's pole in its sight it learns.
                     The city's own scanners never do.
      The raid      at "the building": the Administrator's F2 > City orders > the Resistance's headquarters >
                    Raid it (with nobody playing her, the city's own, once its authority is 50 or more).
                    Every unit gets "Raid the Resistance headquarters" (F4), the nearest NPC units go too
                    and tear the flag down if no rebel is by it; the Resistance's lookouts warn them on Freq 7
                    and they get "Defend the headquarters". Beaten off (the raiders dead, no unit left on the
                    ground) or not done in LC.HQRaidSecs: it fails, and costs the Administrator authority.
      A ransack     papers in the office name up to three sympathizers: they are suspects from then on
                    (a unit's search finds things on them far more often).
]]

if CLIENT then return end

LC = LC or {}
LC.HQ = LC.HQ or { know = 0 }
local H = LC.HQ

util.AddNetworkString("lc_hq_raid")
util.AddNetworkString("lc_hq_scan")

LC.HQRaidSecs, LC.HQRaidGap, LC.HQCityWait = 480, 1200, 120
LC.HQLearnFrom = { informed = 50, questioned = 35, scouted = 30 }
LC.HQScanPerSec, LC.HQScanMost, LC.HQScanSecs, LC.HQScanGap, LC.HQScanSight = 2, 40, 90, 300, 1400
local WORDS = { { 100, "the building" }, { 75, "the street" }, { 50, "a district" }, { 25, "rumours" }, { 0, "nothing" } }

local function Core() local cv = GetConVar("lc_base_core") return cv and cv:GetFloat() or 700 end
local function Faction(p) return IsValid(p) and p.GetNW2String and p:GetNW2String("lcf_faction", "") or "" end
local function UnitPly(p) local f = Faction(p) return IsValid(p) and p:IsPlayer() and (f == "cp" or f == "ota") end
local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end

-- The live HQ's pole, its territory, and this site's key (nil: no HQ up).
function LC.HQPos()
    local z = LC.BaseLive and LC.BaseLive()
    local s = LC.Base and LC.Base.S
    if not (z and s and s.pos) then return nil end
    return s.pos, z, string.format("%d %d %d", math.floor(s.pos.x), math.floor(s.pos.y), math.floor(s.pos.z))
end

-- On the live HQ's ground: near its pole, or in its territory.
function LC.HQGround(pos)
    local hp, z = LC.HQPos()
    if not (hp and pos) then return false end
    if pos:DistToSqr(hp) < Core() ^ 2 then return true end
    return z ~= nil and LCZ ~= nil and LCZ.Contains ~= nil and LCZ.Contains(z, pos) == true
end

------------------------------------------------------------------------
-- What the Combine know
------------------------------------------------------------------------

function LC.HQKnowWords()
    for _, w in ipairs(WORDS) do if (H.know or 0) >= w[1] then return w[2] end end
    return "nothing"
end

local function Publish()
    local hp = LC.HQPos()
    local t = hp and { words = LC.HQKnowWords(), can = (H.know or 0) >= 100 and not H.raid and CurTime() >= (H.raidNext or 0), raid = H.raid ~= nil } or nil
    local js = t and util.TableToJSON(t) or ""
    if js ~= H.sent then H.sent = js SetGlobal2String("lc_hq", js) end
end
LC.HQPublish = Publish

-- The Combine learn n of it (how: "informed", "questioned", "scouted", "scanner"). -> true if it moved.
function LC.HQLearn(n, how, by)
    local hp, _, site = LC.HQPos()
    if not hp or (n or 0) <= 0 or H.site ~= site then return false end
    local was = H.know or 0
    H.know = math.Clamp(was + n, 0, 100)
    if H.know == was then return false end
    if LC.Log then LC.Log("info", string.format("The Combine learn of the Resistance's headquarters (%s): %s", tostring(how), LC.HQKnowWords())) end
    if H.know >= 100 and was < 100 then H.knownAt = CurTime() hook.Run("LivingCityHQKnown", hp, how, by) end
    Publish()
    return true
end

local function NewSite()
    local hp, _, site = LC.HQPos()
    H.site, H.know, H.knownAt, H.seen, H.told, H.raid = site, 0, nil, {}, {}, nil
    Publish()
end
hook.Add("LivingCityBaseLive", "LivingCityHQ", function() LC.Try(NewSite) end)
hook.Add("LivingCityBaseGone", "LivingCityHQ", function() H.site, H.know, H.knownAt, H.raid = nil, 0, nil, nil Publish() end)

-- Who has been on its ground (players only: they can tell).
function LC.HQSaw(ply) return IsValid(ply) and H.site ~= nil and H.seen and H.seen[ply] == H.site end

-- Informing: a player who has been there tells a unit.
if LC.InformKindAdd then
    LC.InformKindAdd({
        id = "hq", order = 40,
        label = "Where the Resistance's headquarters is",
        available = function(ply)
            if not LC.HQSaw(ply) or (H.know or 0) >= 100 or (H.told and H.told[ply] == H.site) then return nil end
            return H.site
        end,
        start = function(ply, unit, site)
            if site ~= H.site then return false, "That place is gone." end
            H.told[ply] = H.site
            LC.HQLearn(LC.HQLearnFrom.informed, "informed", ply)
            if LC.AddCredits then LC.AddCredits(ply, 40, "information") end
            ply.lcInformWaits = ply.lcInformWaits or {}
            ply.lcInformWaits.hq = CurTime() + 1800
            return true
        end,
    })
end

-- Questioning: a Resistance player in the cells who has been there, telling the truth about the hideout. -> the
-- HQ's pole (the place they name), or nil (sv_livingcity_interrogation.lua).
function LC.HQFromPrisoner(prisoner)
    if not (IsValid(prisoner) and prisoner:IsPlayer() and LC.HQSaw(prisoner)) then return nil end
    local hp = LC.HQPos()
    if not (H.told and H.told[prisoner] == H.site) then
        H.told[prisoner] = H.site
        LC.HQLearn(LC.HQLearnFrom.questioned, "questioned", prisoner)
    end
    return hp
end

------------------------------------------------------------------------
-- A scanner a unit sends to scout (only these: never the city's own)
------------------------------------------------------------------------

H.scanners = H.scanners or {}  -- [scanner] = { by, untilT, learnt, told, target }

function LC.HQScanWhyNot(ply)
    if not UnitPly(ply) or not ply:Alive() then return "Only Civil Protection and the Overwatch send scanners." end
    if LC.RadioHeld and not LC.RadioHeld(ply) then return "Get your radio out first." end
    local wait = (ply.lcHQScanNext or 0) - CurTime()
    if wait > 0 then return string.format("Your last scanner's still out (%ds).", math.ceil(wait)) end
    return nil
end

function LC.HQScan(ply, to)
    local why = LC.HQScanWhyNot(ply)
    if why then return false, why end
    if not to then
        local tr = ply:GetEyeTrace()
        to = tr and tr.HitPos or ply:GetPos()
    end
    local d = to - ply:GetPos()
    if d:Length() > 4000 then to = ply:GetPos() + d:GetNormalized() * 4000 end
    local sc = not (LC.ChapterReversed and LC.ChapterReversed()) and ents.Create("npc_cscanner") or nil -- (dead with the rest: sv_livingcity_chapter.lua)
    if not IsValid(sc) then return false, "HQ has no scanner to send." end
    sc:SetPos(ply:GetPos() + Vector(0, 0, 120))
    sc:Spawn()
    sc:Activate()
    local mark = ents.Create("info_target")
    if IsValid(mark) then
        mark:SetPos(to + Vector(0, 0, 150))
        mark:SetName("lc_hqscan_" .. sc:EntIndex())
        mark:Spawn()
        sc:Fire("SetFollowTarget", mark:GetName(), 0.2)
    end
    local st = LC.RegisterNPC and LC.RegisterNPC(sc, "scanner")
    if st then st.unmanaged, st.scoutBy, st.scoutTo = true, ply, to end
    ply.lcHQScanNext = CurTime() + LC.HQScanGap
    ply:SetNW2Float("lc_hqscan_next", ply.lcHQScanNext)
    H.scanners[sc] = { by = ply, untilT = CurTime() + LC.HQScanSecs, learnt = 0, target = mark }
    return true
end

net.Receive("lc_hq_scan", function(_, ply)
    if (ply.lcHQScanAsk or 0) > CurTime() then return end
    ply.lcHQScanAsk = CurTime() + 1
    LC.HQScan(ply) -- (why it can't: greyed on the radio's menu, from lc_hqscan_next)
end)

local function Sees(sc, pos)
    local tr = util.TraceLine({ start = sc:GetPos(), endpos = pos + Vector(0, 0, 60), mask = MASK_SOLID_BRUSHONLY })
    return not tr or not tr.Hit or (tr.Fraction or 0) > 0.97
end

function LC.HQScannerTick(dt)
    dt = dt or 1
    local hp = LC.HQPos()
    local now = CurTime()
    for sc, s in pairs(H.scanners) do
        if not IsValid(sc) or now > s.untilT or (sc.Health and sc:Health() <= 0) then
            if IsValid(sc) then LC.NPCs[sc] = nil sc:Remove() end
            if IsValid(s.target) then s.target:Remove() end
            H.scanners[sc] = nil
        elseif hp and sc:GetPos():DistToSqr(hp) < LC.HQScanSight ^ 2 and Sees(sc, hp) and s.learnt < LC.HQScanMost then
            local n = math.min(LC.HQScanMost - s.learnt, LC.HQScanPerSec * dt)
            s.learnt = s.learnt + n
            LC.HQLearn(n, "scanner", s.by)

        end
    end
end

------------------------------------------------------------------------
-- The raid
------------------------------------------------------------------------

function LC.HQRaidWhyNot(by)
    if IsValid(by) and Faction(by) ~= "admin" then return "Only the Administrator orders that." end
    local hp = LC.HQPos()
    if not hp then return "The Resistance have no headquarters up." end
    if (H.know or 0) < 100 then return "We don't know where it is yet: " .. LC.HQKnowWords() .. "." end
    if H.raid then return "A raid is under way." end
    if CurTime() < (H.raidNext or 0) then return "Not so soon after the last one." end
    return nil
end

-- The nearest free NPC units, armed and running at the pole.
local function SendUnits(hp, n)
    local near = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and (st.role == "cop" or st.role == "soldier") and not st.questLock
            and not st.workEscort and not st.test then
            near[#near + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(hp) }
        end
    end
    table.sort(near, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(n, #near) do
        local c = near[i]
        if LC.ArmUnit then LC.ArmUnit(c.npc, c.st) end
        c.st.unmanaged, c.st.hqRaid = true, true
        if LC.GoTo then LC.GoTo(c.npc, c.st, hp + Vector(math.random(-60, 60), math.random(-60, 60), 0), true, nil) end
        out[#out + 1] = c.npc
    end
    return out
end

function LC.HQRaidOrder(by)
    local why = LC.HQRaidWhyNot(by)
    if why then return false, why end
    local hp = LC.HQPos()
    local now = CurTime()
    H.raid = { at = now, untilT = now + LC.HQRaidSecs, by = by, npcs = SendUnits(hp, 6) }
    Radio("cp", "Dispatch: raid the Resistance's headquarters " .. Where(hp) .. ". All units. Tear their flag down.")
    Radio("resistance", "Lookouts: units moving on the headquarters!")
    if LC.PostDirective then LC.PostDirective("cp_raidhq", nil, true) LC.PostDirective("res_defendhq", nil, true) end
    Publish()
    hook.Run("LivingCityHQRaid", by, hp)
    return true
end

net.Receive("lc_hq_raid", function(_, ply)
    if (ply.lcHQRaidAsk or 0) > CurTime() then return end
    ply.lcHQRaidAsk = CurTime() + 1
    LC.HQRaidOrder(ply) -- (why it can't: greyed on her City orders, from lc_hq)
end)

local function RaidOver(won)
    local r = H.raid
    if not r then return end
    H.raid, H.raidNext = nil, CurTime() + LC.HQRaidGap
    for _, npc in ipairs(r.npcs or {}) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st then st.unmanaged, st.hqRaid = nil, nil end
    end
    if won then
        if LC.LedgerAdd then LC.LedgerAdd("authority", 2, "the Resistance's headquarters raided") end
    else
        if LC.LedgerAdd then LC.LedgerAdd("authority", -4, "a raid on the Resistance's headquarters beaten off") end
        Radio("cp", "Dispatch: the raid on the headquarters is called off.")
        if LC.QuestEvent then for _, p in ipairs(player.GetAll()) do if Faction(p) == "resistance" then LC.QuestEvent("hq_defended", p) end end end
    end
    Publish()
    hook.Run("LivingCityHQRaidOver", won)
end
LC.HQRaidOver = RaidOver

function LC.HQRaidTick()
    local r = H.raid
    if not r then return end
    local hp = LC.HQPos()
    if not hp then return RaidOver(true) end -- (the flag came down)
    local now = CurTime()
    -- the raid's own NPC units tear it down when they reach it with no rebel by it
    local alive = 0
    for _, npc in ipairs(r.npcs) do
        if IsValid(npc) and npc:Health() > 0 then
            alive = alive + 1
            if LC.BaseTearNPC then LC.BaseTearNPC(npc) end
        end
    end
    local unitsThere = 0
    for _, p in ipairs(player.GetAll()) do if UnitPly(p) and p:Alive() and p:GetPos():DistToSqr(hp) < (Core() * 2) ^ 2 then unitsThere = unitsThere + 1 end end
    if alive == 0 and unitsThere == 0 and now - r.at > 30 then
        r.clearSince = r.clearSince or now
        if now - r.clearSince >= 20 then return RaidOver(false) end
    else
        r.clearSince = nil
    end
    if now >= r.untilT then return RaidOver(false) end
end

hook.Add("LivingCityBaseRansacked", "LivingCityHQ", function(zone, credits, unit)
    LC.Try(function()
        if LC.QuestEvent then for _, p in ipairs(player.GetAll()) do if UnitPly(p) then LC.QuestEvent("hq_torn", p) end end end
        LC.HQRansackPapers()
        if H.raid then RaidOver(true) end
    end)
end)

-- The city's own Administrator orders it, once the building is known and its authority is high enough.
function LC.HQCityTick()
    if H.raid or not H.knownAt or (H.know or 0) < 100 then return end
    for _, p in ipairs(player.GetAll()) do if Faction(p) == "admin" then return end end
    if CurTime() - H.knownAt < LC.HQCityWait then return end
    local l = LC.Ledger and LC.Ledger() or {}
    if (tonumber(l.authority) or 50) >= 50 then LC.HQRaidOrder(nil) end
end

------------------------------------------------------------------------
-- A ransack's papers: sympathizers named
------------------------------------------------------------------------

function LC.HQRansackPapers(most)
    most = most or 3
    local pool = {}
    for _, p in ipairs(LC.People and LC.People.list or {}) do
        if p.alive and p.role == "citizen" and p.rebel and not p.suspect then pool[#pool + 1] = p end
    end
    local named = {}
    while #named < most and #pool > 0 do
        local p = table.remove(pool, math.random(#pool))
        p.suspect = true
        named[#named + 1] = p.name
        local st = IsValid(p.npc) and LC.NPCs[p.npc]
        if st then st.suspect = true end
    end
    if #named > 0 then
        if LC.MarkPeopleDirty then LC.MarkPeopleDirty() end
        Radio("cp", "Dispatch: papers from the headquarters name sympathizers: " .. table.concat(named, ", ") .. ". Search them on sight.")
    end
    return named
end

------------------------------------------------------------------------
-- Every second
------------------------------------------------------------------------

function LC.HQTick()
    local hp, _, site = LC.HQPos()
    if hp and H.site ~= site then NewSite() end
    if hp then
        for _, p in ipairs(player.GetAll()) do
            if p:Alive() and LC.HQGround(p:GetPos()) then H.seen[p] = H.site end
        end
    end
    LC.HQScannerTick(1)
    LC.HQRaidTick()
    LC.HQCityTick()
    Publish()
end
timer.Create("LivingCityHQ", 1, 0, function() LC.Try(LC.HQTick) end)

-- The wounded heal at the HQ, and named suspects stay suspects whenever they are out.
timer.Create("LivingCityHQSlow", 5, 0, function()
    LC.Try(function()
        local hp = LC.HQPos()
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and npc:Health() > 0 then
                if hp and st.role == "rebel" and npc:Health() < npc:GetMaxHealth() and LC.HQGround(npc:GetPos()) then
                    npc:SetHealth(math.min(npc:GetMaxHealth(), npc:Health() + 5))
                end
                if st.profile and st.profile.suspect then st.suspect = true end
            end
        end
    end)
end)

-- A Resistance player last nearest the live HQ comes back there (sv_livingcity_factions.lua). -> a spot, or nil.
function LC.HQSpawnFor(ply)
    local key = IsValid(ply) and (ply.lcRSpawn or ply:GetPData("lc_rspawn", ""))
    if key ~= "hq" then return nil end
    local hp = LC.HQPos()
    if not hp then return nil end
    local at = hp + Vector(math.random(-160, 160), math.random(-160, 160), 0)
    return LC.ReleaseSpot and LC.ReleaseSpot(at, ply) or at + Vector(0, 0, 4)
end

------------------------------------------------------------------------
-- The jobs: the units' scouting and raid, the Resistance's defence
------------------------------------------------------------------------

do
    local Q = LC.QB
    if Q and LC.QuestTemplates then
        local T = function(def) def.factions = def.factions or {} LC.QuestTemplates[#LC.QuestTemplates + 1] = def end
        T{
            id = "cp_scouthq", factions = { cp = true, ota = true }, squad = 2,
            available = function() return LC.HQPos() ~= nil and (H.know or 0) < 100 and #(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) > 0 end,
            build = function(ply)
                local _, hz = LC.HQPos()
                local zones = LC.ZonesOfKind("rebel")
                local z = zones[math.random(#zones)]
                if not z then return nil end
                local where = Q.Place(z.pos, ply:GetPos())
                local search = LC.QuestSearchStage and LC.QuestSearchStage({ pos = z.pos, r = 220, min = 3,
                    text = "Search the rebel ground for signs of their headquarters (hold E on each)" })
                if not search then return nil end
                search.onDone = function(q)
                    if z == hz or (hz and LCZ and LCZ.Contains and LCZ.Contains(hz, z.pos)) then
                        LC.HQLearn(LC.HQLearnFrom.scouted, "scouted", q.owner)
                        Q.Narrate(q, "Fresh boot prints, cable run off into the dark, the smell of a cook fire. Something big is here.")
                    else
                        Q.Narrate(q, "Nothing here but the usual.")
                    end
                end
                return {
                    title = "Scout rebel ground " .. where, reward = 30, limit = 600,
                    desc = "Dispatch wants to know where the anticitizens keep their headquarters. Go over the rebel ground " .. where .. " by hand.",
                    stages = { Q.Goto(z.pos, "Get to the rebel ground " .. where .. " (marked)", math.max(200, z.r or 200)), search },
                }
            end,
        }
        T{
            id = "cp_raidhq", factions = { cp = true, ota = true }, violent = true, squad = 8,
            available = function() return H.raid ~= nil and LC.HQPos() ~= nil end,
            build = function(ply)
                local hp = LC.HQPos()
                if not hp then return nil end
                local tear = Q.Count("hq_torn", 1, "Tear their flag down (E at the pole, with no rebel by it)")
                tear.pos = hp
                return {
                    title = "Raid the Resistance headquarters", reward = 60, limit = LC.HQRaidSecs,
                    desc = "Their headquarters " .. Q.Place(hp, ply:GetPos()) .. ". Get in, clear it, and tear their flag down.",
                    stages = { Q.Goto(hp, "Get to the Resistance's headquarters (marked)", 500), tear },
                    tick = function(q) if not H.raid and not q.done then Q.Finish(q, false, "the raid is over") end end,
                }
            end,
        }
        T{
            id = "res_defendhq", factions = { resistance = true }, violent = true, squad = 8, brings = false,
            available = function() return H.raid ~= nil and LC.HQPos() ~= nil end,
            build = function(ply)
                local hp = LC.HQPos()
                if not hp then return nil end
                local beat = Q.Count("hq_defended", 1, "Beat the raid off: keep them from the flag")
                beat.pos = hp
                return {
                    title = "Defend the headquarters", reward = 50, limit = LC.HQRaidSecs + 60,
                    desc = "Civil Protection are moving on the headquarters. Get there and keep them off the flag.",
                    stages = { Q.Goto(hp, "Get to the headquarters (marked)", 500), beat },
                    tick = function(q) if not LC.HQPos() and not q.done then Q.Finish(q, false, "the flag came down") end end,
                }
            end,
        }
    end
end
