--[[
    Living City: the collapse (sociostability BLACK) and the Administrator's last stand
    (the owner, 9 November)

    "Black sociostatus means the server is devolving into chaos and Gman intervenes to influence the
    administrator to do something, like give up or kill herself or resign or something, and if she
    refuses then he starts interferring to accelerate the end so the administrator is killed by the
    populace. ... the boss fight would probably take place in her office in the combine HQ, so a squad
    of elites would be protecting her and likely a blackout would be needed to prevent her from
    protecting herself too much in a breen bubble (it would weaken her breen bubble shield thing)."

    How it goes:

      Chaos       The city's chaos fills while sociostability is red (a quarter as fast at yellow)
                  and drains at green. lc_black_minutes (30) of red, net, and the city collapses.
                  Not with fewer than lc_black_min_players (4) on, during a dream ending, or within
                  lc_black_cooldown_hours (3) of the last collapse. (F2 shows how close it is.)
      Black       Sociostability BLACK: civil collapse, open rebellion. Everything red does, and it
                  stays until this is over. Overwatch's recording socio_black, if there is one.
      The offer   The G-Man comes to the Administrator: step down, or end it yourself, while there's
                  still a choice. lc_black_answer_minutes (5) to answer; no answer is a refusal. With
                  no player as the Administrator, she (the city's own) refuses.
                    Step down       she leaves the post (a citizen again); the city calms.
                    End it yourself she dies by her own hand and leaves the post; the city calms.
                    Refuse          he hastens her end, a step every lc_black_phase_minutes (5):
                                    1 his weapon crates all over the city
                                    2 people waking from sleep with weapons in their hands
                                    3 the grid failing, the whole city dark for a few minutes
                                    4 the last stand
      Last stand  In her office (the editor's "Administrator's desk" point; else beside her office
                  door, else the broadcast studio, else a Combine zone): the Administrator (a player,
                  brought there, or the city's own, with a pulse rifle), lc_black_admin_health (600)
                  health, lc_black_elites (4) Overwatch Elites guarding her, and her shield: it takes
                  every hit until it breaks (lc_black_shield, 1500), throws back anyone who comes too
                  close, and comes back if left alone. Cut the power to her office (sabotage the
                  transformer feeding it; with none, the G-Man keeps the city dark) and the shield is
                  weak: a third as strong, no throwing back, never comes back. lc_black_rebels (8)
                  Resistance fighters storm the office with everyone else. lc_black_stand_minutes (15).
      The end     She dies: the city is the people's tonight (everyone who isn't Combine and was there
                  gets lc_black_reward credits, 200), the post is empty, sociostability as the city
                  makes it, chaos gone. Time runs out: Overwatch crushes the uprising, chaos halved,
                  she keeps the office.

      Heroes      (the owner, 9 November: "as an emergency ending ... like star wars battlefield where a
                  'Hero' is played by one of the soldiers"; "Barney introduced as a first, milder hero and if
                  he doesn't succeed within a certain amount of time, then Freeman is brought in")
                  With lc_black_heroes on (1): lc_black_barney_minutes (5) into the stand with her still
                  standing, a player of the rebellion comes back in rebel territory as Barney Calhoun:
                  the one with the most Civil Protection and Overwatch kills since the collapse began (at
                  least lc_black_hero_kills, 2; else any Resistance player). Half the damage taken, half
                  again the damage dealt, a pistol, an SMG, a shotgun, a pulse rifle and grenades, armour.
                  lc_black_freeman_minutes (5) later, or as soon as Barney falls or leaves, Gordon Freeman:
                  a fifth of the damage, twice the damage dealt, the whole Half-Life 2 arsenal, the HEV
                  suit's armour, and he comes straight back in rebel territory if he dies. Each hero rallies
                  every Resistance fighter in the city to the office, and the stand runs on for
                  lc_black_stand_minutes from Freeman's arrival. No player to be one: Barney comes as the
                  city's own, with more fighters. Freeman's model: lc_black_freeman_model (Garry's Mod has
                  no Gordon of its own; a Workshop one's path goes there). lc_black_reset_map (0): 1 changes
                  to the same map a minute after she falls, a fresh city.

    Admins: the editor's "The collapse" section tests every part (lc_collapse_test).

      lc_black 0/1 (1), lc_black_minutes (30), lc_black_min_players (4), lc_black_cooldown_hours (3),
      lc_black_answer_minutes (5), lc_black_phase_minutes (5), lc_black_stand_minutes (15),
      lc_black_elites (4), lc_black_rebels (8), lc_black_admin_health (600), lc_black_shield (1500),
      lc_black_reward (200), lc_black_heroes 0/1 (1), lc_black_barney_minutes (5), lc_black_freeman_minutes (5),
      lc_black_hero_kills (2), lc_black_freeman_model, lc_black_barney_model, lc_black_reset_map 0/1 (0)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_black", "1", FLAGS, "Sociostability can collapse to BLACK after long red: the G-Man, the Administrator's choice, and her last stand")
local cvMinutes = CreateConVar("lc_black_minutes", "30", FLAGS, "Minutes of red sociostability (net: green drains it) before the city collapses to BLACK")
local cvMinP    = CreateConVar("lc_black_min_players", "4", FLAGS, "Players online before the city can collapse to BLACK")
local cvCool    = CreateConVar("lc_black_cooldown_hours", "3", FLAGS, "Hours after a collapse before the next can start")
local cvAnswer  = CreateConVar("lc_black_answer_minutes", "5", FLAGS, "Minutes the Administrator has to answer the G-Man (no answer: a refusal)")
local cvPhase   = CreateConVar("lc_black_phase_minutes", "5", FLAGS, "Minutes between the G-Man's steps once the Administrator refuses him")
local cvStand   = CreateConVar("lc_black_stand_minutes", "15", FLAGS, "Minutes the Administrator's last stand lasts before Overwatch crushes the uprising")
local cvElites  = CreateConVar("lc_black_elites", "4", FLAGS, "Overwatch Elites guarding the Administrator in her last stand")
local cvRebels  = CreateConVar("lc_black_rebels", "8", FLAGS, "Resistance fighters who storm the Administrator's office in her last stand")
local cvHealth  = CreateConVar("lc_black_admin_health", "600", FLAGS, "The Administrator's health in her last stand")
local cvShield  = CreateConVar("lc_black_shield", "1500", FLAGS, "How much damage the Administrator's shield takes before it breaks")
local cvReward  = CreateConVar("lc_black_reward", "200", FLAGS, "Credits for everyone not Combine who was there when the Administrator fell")

local cvHeroes   = CreateConVar("lc_black_heroes", "1", FLAGS, "Heroes in the Administrator's last stand: Barney, then Gordon Freeman, played by players of the rebellion")
local cvBarneyAt = CreateConVar("lc_black_barney_minutes", "5", FLAGS, "Minutes into the last stand, with the Administrator still standing, before Barney comes")
local cvFreemanAt = CreateConVar("lc_black_freeman_minutes", "5", FLAGS, "Minutes after Barney (or at once, if he falls) before Gordon Freeman comes")
local cvHeroKills = CreateConVar("lc_black_hero_kills", "2", FLAGS, "Civil Protection and Overwatch kills since the collapse began that make a player a hero's first pick")
local cvFreemanMdl = CreateConVar("lc_black_freeman_model", "models/player/group03/male_07.mdl", FLAGS, "Gordon Freeman's player model (Garry's Mod has no Gordon: put a Workshop one's path here)")
local cvBarneyMdl = CreateConVar("lc_black_barney_model", "models/player/barney.mdl", FLAGS, "Barney's player model")
local cvResetMap = CreateConVar("lc_black_reset_map", "0", FLAGS, "1: a minute after the Administrator falls, the server changes to the same map (a fresh city)")

util.AddNetworkString("lc_collapse_offer")   -- the G-Man's offer, to the Administrator
util.AddNetworkString("lc_collapse_answer")  -- her answer: "resign", "end" or "refuse"

local TICK = 5
local SHIELD_WEAK = 1 / 3   -- (its strength with the power cut)
local PULSE_GAP, PULSE_R = 6, 220

LC.Chaos = LC.Chaos or 0
local C = LC.CollapseState or { cooldownUntil = 0, crates = {}, npcs = {}, gifted = {} }
LC.CollapseState = C

local function Now() return CurTime() end
local function Name(p) return IsValid(p) and ((LC.CharacterName and LC.CharacterName(p)) or p:Nick()) or "The Administrator" end
local function AdminName() return (LC.AdministratorName and LC.AdministratorName()) or "The Administrator" end
local function IsAdministrator(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "admin" end
local function Combine(p) return LC.SideOf and LC.SideOf(p) == "combine" end
local function Each(fn) for _, p in ipairs(player.GetAll()) do fn(p) end end
local function NoticeAll(kind, title, text, secs) Each(function(p) if LC.Notice then LC.Notice(p, kind, title, text, secs) end end) end
local function Line(key) return LC.GmanLine and LC.GmanLine(key) or "" end

local function SittingAdministrator()
    for _, p in ipairs(player.GetAll()) do
        if IsAdministrator(p) and not (LC.IsAFK and LC.IsAFK(p)) then return p end
    end
end

function LC.CollapseActive() return C.stage ~= nil end
function LC.CollapseStage() return C.stage end

local function Publish()
    SetGlobal2Bool("lc_collapse", C.stage ~= nil)
    SetGlobal2String("lc_collapse_stage", C.stage or "")
    SetGlobal2Float("lc_chaos", math.Clamp(LC.Chaos, 0, 1))
end

------------------------------------------------------------------------
-- The chaos, filling with red
------------------------------------------------------------------------

function LC.ChaosStep(level, secs)
    local unit = secs / math.max(60, cvMinutes:GetFloat() * 60)
    if level == "red" then LC.Chaos = LC.Chaos + unit
    elseif level == "yellow" then LC.Chaos = LC.Chaos + unit * 0.25
    else LC.Chaos = LC.Chaos - unit end
    LC.Chaos = math.Clamp(LC.Chaos, 0, 1)
    return LC.Chaos
end

-- Can the city collapse right now? (and why not)
function LC.CollapseAllowed()
    if not cvOn:GetBool() then return false, "lc_black is off" end
    if C.stage then return false, "already collapsed" end
    if #player.GetAll() < cvMinP:GetInt() then return false, "too few players" end
    if Now() < (C.cooldownUntil or 0) then return false, "too soon after the last one" end
    if LC.EndingSession and LC.EndingSession() then return false, "a dream ending is on" end
    return true
end

------------------------------------------------------------------------
-- Black
------------------------------------------------------------------------

local Refuse, Resolve, StandBegin

function LC.CollapseBegin(why)
    if C.stage then return false end
    local now = Now()
    C.stage, C.at, C.phase, C.why = "offer", now, 0, why or "chaos"
    C.answerBy = now + math.max(0.5, cvAnswer:GetFloat()) * 60
    C.socioWas = LC.SocioOverride
    LC.SocioOverride = { level = "red", untilT = now + 6 * 3600, by = "open rebellion" }
    if LC.RefreshSocio then LC.RefreshSocio(true) end
    Publish()
    NoticeAll("warn", "SOCIOSTABILITY: BLACK", "Civil collapse. Open rebellion in the streets. Overwatch has lost the city.", 12)
    Each(function(p) p:ChatPrint("[Overwatch] Sociostability: BLACK (civil collapse).") end)
    if LC.CustomAnnounce then LC.CustomAnnounce("overwatch", "socio_black", nil, true) end
    LC.Log("info", "The city collapsed to BLACK (" .. tostring(why or "chaos") .. ")")
    hook.Run("LivingCityCollapse", why)
    -- the G-Man, to the Administrator
    local adm = SittingAdministrator()
    C.offeredTo = adm
    if IsValid(adm) then
        if LC.Vision then LC.Vision(adm, "visit", Line("elected"), "Your city is coming apart, Administrator. There are ... ways out of this, while you still have a choice.") end
        timer.Simple(9, function()
            if C.stage ~= "offer" or not IsValid(adm) then return end
            net.Start("lc_collapse_offer")
            net.WriteFloat(math.max(5, C.answerBy - Now()))
            net.Send(adm)
        end)
    else
        -- the city's own Administrator: she refuses him
        timer.Simple(3, function()
            if C.stage ~= "offer" then return end
            Each(function(p) if LC.Vision then LC.Vision(p, "voice", "", "She was given a choice. She chose ... poorly.") end end)
            Refuse()
        end)
    end
    return true
end

-- her answer
function LC.CollapseAnswer(ply, how)
    if C.stage ~= "offer" or not IsAdministrator(ply) then return false end
    if how == "resign" or how == "end" then Resolve(how, ply) return true end
    Refuse()
    return true
end
net.Receive("lc_collapse_answer", function(_, ply)
    local how = net.ReadString()
    LC.CollapseAnswer(ply, how)
end)

Refuse = function()
    if C.stage ~= "offer" then return end
    C.stage, C.phase = "refused", 0
    C.nextPhase = Now() + 30
    Publish()
    local adm = C.offeredTo
    if IsValid(adm) then
        if LC.Vision then LC.Vision(adm, "visit", Line("first"), "Not for long.") end
        if LC.Notice then LC.Notice(adm, "warn", "You refused him", "He means to hasten your end. Your guards, your office, your shield: you'll need all of them.", 10) end
    end
end

------------------------------------------------------------------------
-- His hand on the city
------------------------------------------------------------------------

local PHASES = {
    function()
        local n = math.max(0, (GetConVar("lc_gman_crates") and GetConVar("lc_gman_crates"):GetInt()) or 6)
        if LC.GmanDropCrates then
            for _, c in ipairs(LC.GmanDropCrates(n) or {}) do C.crates[#C.crates + 1] = c end
        end
        Each(function(p) p:ChatPrint("[???] Crates have turned up around the city. Nobody saw who left them.") end)
    end,
    function()
        C.dreamGifts = true
        C.gifted = {}
        Each(function(p) p:ChatPrint("[Rumour] People are waking up with weapons in their hands. Nobody knows where they come from.") end)
    end,
    function()
        if LC.ForceBlackout then LC.ForceBlackout("on") C.forcedDark = true end
        Each(function(p) p:ChatPrint("[City] The grid is failing, block by block.") end)
        timer.Create("LivingCityCollapseDark", 180, 1, function()
            if C.forcedDark and C.stage ~= "stand" and LC.ForceBlackout then LC.ForceBlackout("auto") C.forcedDark = nil end
        end)
    end,
    function() StandBegin() end,
}
LC.CollapsePhases = PHASES

-- the next step now (the timer, or an admin testing it)
function LC.CollapseNext()
    if C.stage == "offer" then Refuse() return true end
    if C.stage ~= "refused" then return false end
    C.phase = C.phase + 1
    C.nextPhase = Now() + math.max(0.5, cvPhase:GetFloat()) * 60
    local fn = PHASES[C.phase]
    if fn then fn() end
    local adm = C.offeredTo
    if IsValid(adm) and C.phase < #PHASES and LC.Vision then LC.Vision(adm, "voice", "", "Time is running out, Administrator.") end
    return true
end

-- waking with a weapon (step 2): once each, after he's started it
local GIFTS = { "weapon_pistol", "weapon_smg1", "weapon_shotgun", "weapon_357", "weapon_crowbar" }
function LC.CollapseGift(ply)
    if not C.dreamGifts or not IsValid(ply) or C.gifted[ply] or Combine(ply) then return false end
    C.gifted[ply] = true
    local w = GIFTS[math.random(#GIFTS)]
    if ply.Give then ply:Give(w) end
    if LC.Notice then LC.Notice(ply, "event", "Something in your hands", "You wake holding something you didn't go to sleep with.", 7) end
    return w
end
local wakeWas = LC.WakeUp
if wakeWas and not LC.CollapseWrappedWake then
    LC.CollapseWrappedWake = true
    LC.WakeUp = function(ply, ...)
        local r = { wakeWas(ply, ...) }
        LC.CollapseGift(ply)
        return unpack(r)
    end
end
hook.Add("LivingCityDreamWoke", "LivingCityCollapse", function(p) LC.CollapseGift(p) end)

------------------------------------------------------------------------
-- The last stand
------------------------------------------------------------------------

-- Her office: the desk point, else beside her office door, else the studio, else a Combine zone.
function LC.CollapseOffice()
    local function First(kind)
        local pts = LC.PointsOfKind and LC.PointsOfKind(kind) or {}
        return pts[1] and pts[1].pos
    end
    local p = First("desk")
    if p then return p, "desk" end
    for _, d in ipairs(LC.Doors or {}) do
        if d.kind == "office" and d.pos then return d.pos, "door" end
    end
    for _, d in ipairs(LC.OfficeDoors and LC.OfficeDoors() or {}) do
        if IsValid(d) then return d:GetPos(), "door" end
    end
    p = First("studio")
    if p then return p, "studio" end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("combine") or {}) do
        local s = (LC.SpotInZone and LC.SpotInZone(z)) or z.pos
        if s then return s, "combine" end
    end
    return LC.SafeCitizenSpot and LC.SafeCitizenSpot() or nil, "street"
end

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30))) or p end

local function Friendly(npc, boss)
    if not (IsValid(npc) and IsValid(boss) and npc.IsNPC and npc:IsNPC()) then return end
    npc:AddEntityRelationship(boss, D_LI or 3, 99)
    if boss.IsNPC and boss:IsNPC() then boss:AddEntityRelationship(npc, D_LI or 3, 99) end
end

local function SpawnHer(pos)
    local mdl = GetConVar("lc_administrator_model") and string.Trim(GetConVar("lc_administrator_model"):GetString()) or ""
    if mdl == "" or (util.IsValidModel and not util.IsValidModel(mdl)) then mdl = "models/mossman.mdl" end
    local npc = ents.Create("npc_citizen")
    if not IsValid(npc) then return nil end
    npc:SetModel(mdl)
    npc:SetPos(pos + Vector(0, 0, 4))
    npc:SetKeyValue("additionalequipment", "weapon_ar2")
    npc:SetKeyValue("spawnflags", tostring((SF_NPC_FADE_CORPSE or 512)))
    npc:Spawn()
    npc:Activate()
    if LC.SetNPCStr then
        LC.SetNPCStr(npc, "lc_pname", AdminName())
        LC.SetNPCStr(npc, "lc_pjob", "City Administrator")
    end
    npc.lcCollapseBoss = true
    return npc
end

StandBegin = function()
    if C.stage == "stand" then return false end
    local now = Now()
    local office = LC.CollapseOffice()
    if not office then return false end
    office = Ground(office)
    C.stage, C.office, C.standUntil, C.nextPulse, C.standAt = "stand", office, now + math.max(1, cvStand:GetFloat()) * 60, now + PULSE_GAP, now
    C.heroStage, C.freemanAt, C.npcBarney = nil, nil, nil
    C.there = {}
    -- her: the player, brought to her office, or the city's own
    local adm = SittingAdministrator()
    local boss
    if IsValid(adm) then
        boss = adm
        adm:SetPos(office + Vector(0, 0, 4))
        if LC.Notice then LC.Notice(adm, "warn", "Your last stand", "He's put you where you belong: your office. Hold out " .. math.floor(cvStand:GetFloat()) .. " minutes. Keep the power on: it's your shield.", 12) end
    else
        boss = SpawnHer(office)
        if IsValid(boss) then C.npcs[#C.npcs + 1] = boss end
    end
    if not IsValid(boss) then C.stage = "refused" return false end
    C.boss = boss
    local hp = math.max(1, cvHealth:GetInt())
    if boss.SetMaxHealth then boss:SetMaxHealth(hp) end
    boss:SetHealth(hp)
    C.shield, C.shieldMax, C.lastHit = cvShield:GetFloat(), cvShield:GetFloat(), 0
    boss:SetNW2Float("lc_shield_frac", 1)
    SetGlobal2Entity("lc_collapse_boss", boss)
    SetGlobal2Vector("lc_collapse_office", office)
    SetGlobal2Float("lc_collapse_until", C.standUntil)
    -- her Elites, round the desk
    local n = math.max(0, cvElites:GetInt())
    for i = 1, n do
        local a = (i / math.max(1, n)) * math.pi * 2
        local at = Ground(office + Vector(math.cos(a) * 110, math.sin(a) * 110, 0))
        local npc, st
        if LC.ManpowerFree and LC.SpawnSoldier then npc, st = LC.ManpowerFree(LC.SpawnSoldier, at, "elite")
        elseif LC.SpawnSoldier then npc, st = LC.SpawnSoldier(at, "elite") end
        if IsValid(npc) then
            if st then st.unmanaged, st.questLock, st.collapseGuard = true, true, at end
            Friendly(npc, boss)
            C.npcs[#C.npcs + 1] = npc
        end
    end
    -- the Resistance, on its way
    local from = (LC.SafeCitizenSpot and LC.SafeCitizenSpot()) or office + Vector(1200, 0, 0)
    for i = 1, math.max(0, cvRebels:GetInt()) do
        local at = Ground(from + Vector(math.cos(i) * 80, math.sin(i) * 80, 0))
        local npc, st
        if LC.SpawnRebel then npc, st = LC.ManpowerFree and LC.ManpowerFree(LC.SpawnRebel, at, nil, i % 3 == 0 and "weapon_shotgun" or "weapon_ar2") or LC.SpawnRebel(at) end
        if IsValid(npc) then
            st = st or (LC.NPCs and LC.NPCs[npc])
            if st then st.unmanaged, st.questLock, st.collapseStorm = true, true, true end
            if npc.AddEntityRelationship then npc:AddEntityRelationship(boss, D_HT or 1, 99) end
            C.npcs[#C.npcs + 1] = npc
        end
    end
    -- with nothing feeding her office, he keeps the city dark (or she'd be untouchable)
    if LC.FeederOf and not LC.FeederOf(office) and LC.ForceBlackout then
        LC.ForceBlackout("on")
        C.forcedDark = true
    elseif C.forcedDark and LC.ForceBlackout then
        timer.Remove("LivingCityCollapseDark")
        LC.ForceBlackout("auto")
        C.forcedDark = nil
    end
    Publish()
    Each(function(p)
        if not LC.Notice then return end
        if Combine(p) and p ~= boss then
            LC.Notice(p, "warn", "Defend the Administrator", "Her office is under attack. Hold it, and keep its power on.", 12)
        elseif p ~= boss then
            LC.Notice(p, "event", "The last stand", AdminName() .. " is in her office. End it. Cut the power to her office first: it weakens her shield.", 12)
        end
    end)
    hook.Run("LivingCityLastStand", boss, office)
    return true
end
LC.CollapseStand = function() return StandBegin() end

-- The shield's strength now: full, or a third with her office's power cut.
function LC.CollapseShieldWeak()
    if not IsValid(C.boss) then return false end
    return LC.PoweredAt ~= nil and not LC.PoweredAt(C.boss:GetPos())
end
local function ShieldCap() return C.shieldMax * (LC.CollapseShieldWeak() and SHIELD_WEAK or 1) end

hook.Add("EntityTakeDamage", "LivingCityCollapseShield", function(victim, dmg)
    if C.stage ~= "stand" or victim ~= C.boss then return end
    local att = dmg:GetAttacker()
    if IsValid(att) and att ~= victim and (Combine(att) or (att.IsNPC and att:IsNPC() and LC.NPCs and LC.NPCs[att] and LC.IsSecurity and LC.IsSecurity(LC.NPCs[att]))) then
        dmg:SetDamage(0)
        return true
    end
    if IsValid(att) and att:IsPlayer() then C.there[att] = true end
    local ha = IsValid(att) and att.lcHero and LC.CollapseHeroes and LC.CollapseHeroes[att.lcHero]
    if ha then dmg:ScaleDamage(ha.dealt) end
    C.shield = math.min(C.shield or 0, ShieldCap())
    if C.shield > 0 then
        C.shield = C.shield - dmg:GetDamage()
        C.lastHit = Now()
        if C.shield <= 0 then
            C.shield = 0
            NoticeAll("event", "Her shield is down", AdminName() .. "'s shield has broken. Now.", 5)
            if victim.EmitSound then victim:EmitSound("ambient/energy/powerdown2.wav", 90) end
        end
        victim:SetNW2Float("lc_shield_frac", C.shieldMax > 0 and C.shield / C.shieldMax or 0)
        dmg:SetDamage(0)
        return true
    end
end)

-- her death: the people's night
local function BossDied(victim, attacker)
    if C.stage ~= "stand" or victim ~= C.boss then return end
    if IsValid(attacker) and attacker:IsPlayer() then C.there[attacker] = true end
    Resolve("killed", victim, attacker)
end
hook.Add("PlayerDeath", "LivingCityCollapse", function(victim, _, attacker) BossDied(victim, attacker) end)
hook.Add("OnNPCKilled", "LivingCityCollapse", function(npc, attacker) BossDied(npc, attacker) end)
hook.Add("PlayerDisconnected", "LivingCityCollapse", function(p)
    if C.stage == "stand" and p == C.boss then Resolve("fled", p)
    elseif C.stage == "offer" and p == C.offeredTo then Refuse() end
end)

-- each second of the stand: the shield, its pulse, the guards and the storm
function LC.CollapseStandTick(now)
    if C.stage ~= "stand" then return end
    local boss = C.boss
    if not IsValid(boss) or boss:Health() <= 0 then return end
    if now >= C.standUntil then
        -- (heroes on: Freeman before Overwatch can call it over)
        if cvHeroes:GetBool() and C.heroStage ~= "freeman" then LC.HeroBegin("freeman") else Resolve("crushed") return end
    end
    LC.HeroTick(now)
    local weak, cap = LC.CollapseShieldWeak(), ShieldCap()
    if C.shield > cap then C.shield = cap end
    -- left alone for 8 seconds with the power on, it comes back (a twentieth a second)
    if not weak and now - (C.lastHit or 0) > 8 and C.shield < cap then C.shield = math.min(cap, C.shield + C.shieldMax * 0.05) end
    boss:SetNW2Float("lc_shield_frac", C.shieldMax > 0 and C.shield / C.shieldMax or 0)
    boss:SetNW2Bool("lc_shield_weak", weak)
    -- the pulse: anyone not Combine too close is thrown back (not with the power cut, nor once it's broken)
    if not weak and C.shield > 0 and now >= C.nextPulse then
        C.nextPulse = now + PULSE_GAP
        local hit = false
        for _, e in ipairs(ents.FindInSphere(boss:GetPos(), PULSE_R)) do
            if IsValid(e) and e ~= boss and (e:IsPlayer() or (e.IsNPC and e:IsNPC())) and not Combine(e)
                and not (e.IsNPC and e:IsNPC() and LC.NPCs and LC.NPCs[e] and LC.IsSecurity and LC.IsSecurity(LC.NPCs[e])) then
                local d = e:GetPos() - boss:GetPos()
                d.z = 0
                if d:LengthSqr() < 1 then d = Vector(1, 0, 0) end
                d:Normalize()
                if e.SetVelocity then e:SetVelocity(d * 650 + Vector(0, 0, 250)) end
                if e.TakeDamage then e:TakeDamage(10, boss, boss) end
                if e:IsPlayer() then C.there[e] = true end
                hit = true
            end
        end
        if hit and boss.EmitSound then boss:EmitSound("ambient/levels/labs/electric_explosion1.wav", 85) end
        if hit and util.ScreenShake then util.ScreenShake(boss:GetPos(), 6, 5, 1, 500) end
    end
    -- who's there (for the reward), the Combine kept friendly to her, the storm kept moving
    for _, p in ipairs(player.GetAll()) do
        if p ~= boss and p:Alive() and p:GetPos():DistToSqr(C.office) < 900 * 900 and not Combine(p) then C.there[p] = true end
        if boss.AddEntityRelationship and boss:IsNPC() then boss:AddEntityRelationship(p, Combine(p) and (D_LI or 3) or (D_HT or 1), 99) end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity and LC.IsSecurity(st) and not st.lcCollapseFriend then
            st.lcCollapseFriend = true
            Friendly(npc, boss)
        end
    end
    for _, npc in ipairs(C.npcs) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if st and npc:Health() > 0 and npc.SetLastPosition then
            local goal = st.collapseGuard or (st.collapseStorm and C.office)
            if goal and npc:GetPos():DistToSqr(goal) > (st.collapseGuard and 160 or 260) ^ 2 and not (npc.GetEnemy and IsValid(npc:GetEnemy())) then
                npc:SetLastPosition(goal)
                npc:SetSchedule(SCHED_FORCED_GO_RUN)
            end
        end
    end
end

------------------------------------------------------------------------
-- Heroes: Barney, then Freeman
------------------------------------------------------------------------

local HEROES = {
    barney = { name = "Barney Calhoun", taken = 0.5, dealt = 1.5, armor = 60, model = cvBarneyMdl,
        weapons = { "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_shotgun", "weapon_ar2", "weapon_frag" },
        ammo = { Pistol = 150, SMG1 = 300, Buckshot = 60, AR2 = 180, Grenade = 4, SMG1_Grenade = 2, AR2AltFire = 2 } },
    freeman = { name = "Gordon Freeman", taken = 0.2, dealt = 2, armor = 100, model = cvFreemanMdl,
        weapons = { "weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_357", "weapon_smg1", "weapon_ar2", "weapon_shotgun",
            "weapon_crossbow", "weapon_frag", "weapon_rpg", "weapon_bugbait" },
        ammo = { Pistol = 150, ["357"] = 36, SMG1 = 300, AR2 = 180, Buckshot = 60, XBowBolt = 20, Grenade = 5, RPG_Round = 6, SMG1_Grenade = 3, AR2AltFire = 3 } },
}
LC.CollapseHeroes = HEROES

function LC.HeroOf(p) return IsValid(p) and p.lcHero and HEROES[p.lcHero] or nil end

-- kills of Civil Protection and Overwatch since the collapse began (the heroes' first picks)
local function NoteKill(victim, att)
    if not C.stage or not (IsValid(att) and att:IsPlayer()) or Combine(att) then return end
    local unit = (victim:IsPlayer() and Combine(victim)) or (victim.IsNPC and victim:IsNPC() and LC.NPCs and LC.NPCs[victim] and LC.IsSecurity and LC.IsSecurity(LC.NPCs[victim]))
    if unit then C.kills = C.kills or {} C.kills[att] = (C.kills[att] or 0) + 1 end
end
hook.Add("PlayerDeath", "LivingCityCollapseKills", function(victim, _, att) NoteKill(victim, att) end)
hook.Add("OnNPCKilled", "LivingCityCollapseKills", function(npc, att) NoteKill(npc, att) end)

-- who: the rebellion's best killer of units (at least lc_black_hero_kills), else any Resistance player
function LC.HeroPick(exclude)
    local best, bestN = nil, -1
    local need = math.max(0, cvHeroKills:GetInt())
    for p, n in pairs(C.kills or {}) do
        if IsValid(p) and p ~= exclude and not p.lcHero and not Combine(p) and p ~= C.boss and n >= need and not (LC.IsAFK and LC.IsAFK(p))
            and (n > bestN or (n == bestN and math.random() < 0.5)) then best, bestN = p, n end
    end
    if best then return best end
    local pool = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= exclude and not p.lcHero and p ~= C.boss and LC.SideOf and LC.SideOf(p) == "resistance" and not (LC.IsAFK and LC.IsAFK(p)) then pool[#pool + 1] = p end
    end
    return pool[1] and pool[math.random(#pool)] or nil
end

local function RebelGround()
    local pts = LC.PointsOfKind and LC.PointsOfKind("rspawn") or {}
    if #pts > 0 then return pts[math.random(#pts)].pos end
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        local s = (LC.SpotInZone and LC.SpotInZone(z)) or z.pos
        if s then return s end
    end
    return LC.SafeCitizenSpot and LC.SafeCitizenSpot() or nil
end

-- dressed, armed and placed: on becoming one, and again each time a hero comes back
local function Kit(p)
    local h = LC.HeroOf(p)
    if not h then return end
    local at = RebelGround()
    if at then p:SetPos(Ground(at) + Vector(0, 0, 4)) end
    timer.Simple(1, function()
        if not IsValid(p) or LC.HeroOf(p) ~= h then return end
        local mdl = h.model:GetString()
        if mdl ~= "" and (not util.IsValidModel or util.IsValidModel(mdl)) and p.SetModel then p:SetModel(mdl) end
        for _, w in ipairs(h.weapons) do if p.Give and not (p.HasWeapon and p:HasWeapon(w)) then p:Give(w) end end
        for kind, n in pairs(h.ammo) do if p.GiveAmmo then p:GiveAmmo(n, kind, true) end end
        if p.SetArmor then p:SetArmor(h.armor) end
        p:SetHealth(math.max(p:Health(), 100))
        p:SetNW2String("lc_char", h.name)
    end)
end

-- the city's Resistance fighters, all of them, to the office
local function Rally()
    C.rallied = C.rallied or {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and st.role == "rebel" and not st.collapseStorm then
            st.collapseStorm, st.unmanaged, st.lcCollapseRallied = true, true, true
            if IsValid(C.boss) and npc.AddEntityRelationship then npc:AddEntityRelationship(C.boss, D_HT or 1, 99) end
            C.rallied[#C.rallied + 1] = npc
        end
    end
end

-- kind: "barney" or "freeman"; p: who (nil: picked by LC.HeroPick). The hero, or nil.
function LC.HeroBegin(kind, p)
    local h = HEROES[kind]
    if not h or C.stage ~= "stand" then return nil end
    p = p or LC.HeroPick() or (kind == "freeman" and IsValid(C.hero) and C.hero) or nil -- (nobody else: Barney's player becomes Freeman)
    C.heroStage, C.heroAt = kind, Now()
    if kind == "freeman" then
        C.standUntil = math.max(C.standUntil, Now() + math.max(1, cvStand:GetFloat()) * 60)
        SetGlobal2Float("lc_collapse_until", C.standUntil)
        C.freemanAt = nil
    else
        C.freemanAt = Now() + math.max(0.5, cvFreemanAt:GetFloat()) * 60
    end
    SetGlobal2String("lc_collapse_hero", kind)
    if IsValid(p) then
        -- (whoever was the last hero is themselves again first)
        for _, q in ipairs(player.GetAll()) do if q.lcHero and q ~= p then LC.HeroEnd(q) end end
        p.lcHeroWas = p.lcHeroWas or { char = p:GetNW2String("lc_char", ""), model = p:GetModel(), weapons = {} }
        if p.GetWeapons and not p.lcHero then for _, w in ipairs(p:GetWeapons()) do p.lcHeroWas.weapons[w:GetClass()] = true end end
        p.lcHero = kind
        p:SetNW2String("lc_hero", kind)
        C.hero = p
        if p:Alive() then Kit(p) else p:Spawn() end
        if LC.Notice then LC.Notice(p, "event", "You are " .. h.name, "Back in rebel territory, armed for it. Rally the Resistance and take the Administrator's office." .. (kind == "freeman" and " You come straight back if you fall." or ""), 12) end
    else
        -- nobody to play him: the city's own Barney, with more fighters
        C.hero = nil
        if kind == "barney" then
            local at = RebelGround()
            local npc = at and ents.Create("npc_barney")
            if IsValid(npc) then
                npc:SetPos(Ground(at) + Vector(0, 0, 4))
                npc:SetKeyValue("additionalequipment", "weapon_ar2")
                npc:Spawn()
                npc:Activate()
                npc:SetHealth(400)
                if IsValid(C.boss) and npc.AddEntityRelationship then npc:AddEntityRelationship(C.boss, D_HT or 1, 99) end
                C.npcs[#C.npcs + 1] = npc
                C.npcBarney = npc
            end
        end
        for i = 1, math.max(0, cvRebels:GetInt()) do
            local at = RebelGround()
            local npc, st
            if at and LC.SpawnRebel then npc, st = LC.ManpowerFree and LC.ManpowerFree(LC.SpawnRebel, Ground(at) + Vector(math.cos(i) * 60, math.sin(i) * 60, 0), nil, "weapon_ar2") or LC.SpawnRebel(at) end
            if IsValid(npc) then
                st = st or (LC.NPCs and LC.NPCs[npc])
                if st then st.unmanaged, st.questLock, st.collapseStorm = true, true, true end
                C.npcs[#C.npcs + 1] = npc
            end
        end
    end
    Rally()
    local who = IsValid(p) and (" (" .. (p:GetPData("lc_char", "") ~= "" and p:GetPData("lc_char", "") or p:Nick()) .. ")") or ""
    Each(function(q)
        if not LC.Notice or q == p then return end
        if Combine(q) then LC.Notice(q, "warn", h.name .. " is in the city", "Stop him before he reaches the Administrator.", 10)
        else LC.Notice(q, "event", h.name .. " is here" .. who, "Rally to him. Every fighter in the city is moving on the Administrator's office.", 10) end
    end)
    hook.Run("LivingCityHero", kind, p)
    return p or C.npcBarney
end

-- back to themselves: their name, their model, only what they had
function LC.HeroEnd(p)
    if not IsValid(p) or not p.lcHero then return end
    local was = p.lcHeroWas or {}
    p.lcHero, p.lcHeroWas = nil, nil
    p:SetNW2String("lc_hero", "")
    if was.char then p:SetNW2String("lc_char", was.char) end
    if was.model and p.SetModel then p:SetModel(was.model) end
    if p.GetWeapons and p.StripWeapon then
        for _, w in ipairs(p:GetWeapons()) do
            local c = w:GetClass()
            if not (was.weapons or {})[c] then p:StripWeapon(c) end
        end
    end
    if p.SetArmor then p:SetArmor(0) end
    if C.hero == p then C.hero = nil end
end

-- a hero falls: Freeman comes back as Freeman; a fallen Barney brings Freeman now
hook.Add("PlayerDeath", "LivingCityCollapseHero", function(victim)
    if C.stage ~= "stand" or not victim.lcHero then return end
    if victim.lcHero == "barney" then
        LC.HeroEnd(victim)
        timer.Simple(3, function() if C.stage == "stand" and C.heroStage == "barney" then LC.HeroBegin("freeman") end end)
    end
end)
hook.Add("PlayerSpawn", "LivingCityCollapseHero", function(p)
    if p.lcHero and C.stage == "stand" then timer.Simple(0.2, function() if IsValid(p) and p.lcHero then Kit(p) end end) end
end)
hook.Add("PlayerDisconnected", "LivingCityCollapseHero", function(p)
    if not p.lcHero then return end
    local kind = p.lcHero
    p.lcHero = nil
    if C.stage ~= "stand" then return end
    timer.Simple(1, function()
        if C.stage ~= "stand" then return end
        LC.HeroBegin("freeman") -- (Barney gone, or Freeman's player gone: Freeman, played by someone else)
    end)
end)
-- their damage: taken and dealt (the Administrator's own is in her shield, above)
hook.Add("EntityTakeDamage", "LivingCityCollapseHeroDamage", function(victim, dmg)
    if not C.stage then return end
    local hv = victim.lcHero and HEROES[victim.lcHero]
    if hv then dmg:ScaleDamage(hv.taken) end
    if victim == C.boss then return end
    local att = dmg:GetAttacker()
    local ha = IsValid(att) and att.lcHero and HEROES[att.lcHero]
    if ha then dmg:ScaleDamage(ha.dealt) end
end)

-- each second: when the next hero comes
function LC.HeroTick(now)
    if C.stage ~= "stand" or not cvHeroes:GetBool() then return end
    if not C.heroStage and now >= (C.standAt or now) + math.max(0, cvBarneyAt:GetFloat()) * 60 then LC.HeroBegin("barney") return end
    if C.heroStage == "barney" then
        local gone = (C.hero == nil and not IsValid(C.npcBarney)) or (C.npcBarney ~= nil and not IsValid(C.npcBarney))
            or (IsValid(C.npcBarney) and C.npcBarney:Health() <= 0)
        if gone or now >= (C.freemanAt or math.huge) then LC.HeroBegin("freeman") end
    end
end

------------------------------------------------------------------------
-- How it ends
------------------------------------------------------------------------

local function Calm()
    for _, c in ipairs(C.crates) do if IsValid(c) then c:Remove() end end
    C.crates = {}
    if C.forcedDark and LC.ForceBlackout then LC.ForceBlackout("auto") end
    C.forcedDark = nil
    timer.Remove("LivingCityCollapseDark")
    C.dreamGifts, C.gifted = nil, {}
    local leftovers = C.npcs
    C.npcs = {}
    timer.Simple(60, function() for _, npc in ipairs(leftovers) do if IsValid(npc) and npc:Health() > 0 then npc:Remove() end end end)
    if IsValid(C.boss) then C.boss:SetNW2Float("lc_shield_frac", 0) end
    for _, st in pairs(LC.NPCs or {}) do
        st.lcCollapseFriend = nil
        if st.lcCollapseRallied then st.lcCollapseRallied, st.collapseStorm, st.unmanaged = nil, nil, nil end
    end
    for _, p in ipairs(player.GetAll()) do if p.lcHero then LC.HeroEnd(p) end end
    C.rallied, C.kills, C.hero, C.heroStage, C.freemanAt, C.npcBarney = nil, nil, nil, nil, nil, nil
    SetGlobal2String("lc_collapse_hero", "")
    if LC.SocioOverride and LC.SocioOverride.by == "open rebellion" then LC.SocioOverride = C.socioWas end
    C.stage, C.boss, C.offeredTo, C.office, C.socioWas = nil, nil, nil, nil, nil
    SetGlobal2Entity("lc_collapse_boss", NULL)
    C.cooldownUntil = Now() + math.max(0, cvCool:GetFloat()) * 3600
    Publish()
    if LC.RefreshSocio then LC.RefreshSocio(false, true) end
end

local function LeavePost(p)
    if not IsValid(p) or not p:IsPlayer() then return end
    p:SetPData("lcf_wl_admin", "0")
    if LC.SetFaction then LC.SetFaction(p, "citizen", nil, true) end
end

-- how: "resign", "end" (by her own hand), "killed" (the people), "crushed" (time ran out), "fled", "off" (an admin)
Resolve = function(how, who, by)
    if not C.stage then return false end
    local boss = C.boss
    if how == "resign" then
        LeavePost(who)
        NoticeAll("event", "The Administrator steps down", Name(who) .. " has resigned as City Administrator. The office is empty.", 12)
        LC.Chaos = 0
    elseif how == "end" then
        NoticeAll("event", "The Administrator is dead", Name(who) .. " is dead, by her own hand. The office is empty.", 12)
        LC.Chaos = 0
        local p = who
        timer.Simple(0, function() LeavePost(p) end)
        if IsValid(who) and who.Kill and who:Alive() then who:Kill() end
    elseif how == "killed" then
        local reward = math.max(0, cvReward:GetInt())
        for p in pairs(C.there or {}) do
            if IsValid(p) and not Combine(p) and p ~= who then
                if reward > 0 and LC.AddCredits then LC.AddCredits(p, reward, "the Administrator's fall") end
                if LC.Notice then LC.Notice(p, "event", "She's dead", "The city is yours tonight." .. (reward > 0 and (" (" .. reward .. " credits)") or ""), 10) end
            end
        end
        NoticeAll("event", "The Administrator is dead", (IsValid(who) and who:IsPlayer() and Name(who) or AdminName()) .. " has fallen in her office. The people have the Nexus tonight.", 12)
        if IsValid(who) and who:IsPlayer() then local p = who timer.Simple(0, function() LeavePost(p) end) end
        LC.Chaos = 0
        if cvResetMap:GetBool() and game and game.GetMap then
            NoticeAll("info", "A fresh city", "The server starts the city over in a minute.", 10)
            timer.Create("LivingCityCollapseReset", 60, 1, function() RunConsoleCommand("changelevel", game.GetMap()) end)
        end
    elseif how == "crushed" then
        NoticeAll("event", "The uprising is crushed", "Overwatch has retaken the Nexus. " .. (IsValid(boss) and boss:IsPlayer() and Name(boss) or AdminName()) .. " keeps the office.", 12)
        LC.Chaos = 0.5
        if IsValid(boss) and boss:IsPlayer() and boss.SetMaxHealth then boss:SetMaxHealth(100) boss:SetHealth(math.min(boss:Health(), 100)) end
    elseif how == "fled" then
        NoticeAll("event", "The Administrator has fled", "The office is empty. Overwatch pulls back to the Nexus.", 12)
        LC.Chaos = 0
        LeavePost(who)
    else
        LC.Chaos = 0
    end
    LC.Log("info", "The collapse ended: " .. tostring(how))
    Calm()
    hook.Run("LivingCityCollapseOver", how, who)
    return true
end
LC.CollapseResolve = function(how, who, by) return Resolve(how, who, by) end

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

function LC.CollapseTick(now)
    now = now or Now()
    if not C.stage then
        if not cvOn:GetBool() then LC.Chaos = 0 Publish() return end
        LC.ChaosStep(LC.Socio or "green", TICK)
        if LC.Chaos >= 1 and LC.CollapseAllowed() then LC.CollapseBegin("chaos") end
        Publish()
        return
    end
    if C.stage == "offer" and now >= (C.answerBy or 0) then Refuse() end
    if C.stage == "refused" and now >= (C.nextPhase or 0) then LC.CollapseNext() end
    Publish()
end
timer.Create("LivingCityCollapse", TICK, 0, function() if LC.Running ~= false then pcall(LC.CollapseTick, CurTime()) end end)
timer.Create("LivingCityCollapseStand", 1, 0, function() if C.stage == "stand" then pcall(LC.CollapseStandTick, CurTime()) end end)

------------------------------------------------------------------------
-- Admins: test every part (the editor's "The collapse" section)
------------------------------------------------------------------------

-- what: "black" (collapse now), "next" (his next step now), "stand" (the last stand now), "off" (end it), "chaos" (half full)
function LC.CollapseTest(what)
    if what == "black" then
        if C.stage then return false, "Already collapsed." end
        LC.Chaos = 1
        return LC.CollapseBegin("an admin's test"), "The city collapses to BLACK."
    elseif what == "next" then
        if not C.stage then return false, "Not collapsed: push it to black first." end
        return LC.CollapseNext(), "The G-Man's next step."
    elseif what == "stand" then
        if not C.stage then LC.Chaos = 1 LC.CollapseBegin("an admin's test") end
        C.stage = "refused"
        return StandBegin(), "Her last stand begins."
    elseif what == "off" then
        if not C.stage then LC.Chaos = 0 C.cooldownUntil = 0 Publish() return true, "Chaos cleared." end
        Resolve("off")
        C.cooldownUntil = 0
        return true, "Back to normal."
    elseif what == "barney" or what == "freeman" or what == "mebarney" or what == "mefreeman" then
        if C.stage ~= "stand" then return false, "Start her last stand first." end
        local kind = string.gsub(what, "^me", "")
        local who = LC.HeroBegin(kind, string.sub(what, 1, 2) == "me" and LC.CollapseTester or nil)
        return who ~= nil, (HEROES[kind] and HEROES[kind].name or kind) .. (who ~= nil and " is in the city." or ": nobody to play him.")
    elseif what == "chaos" then
        LC.Chaos = 0.5
        Publish()
        return true, "Chaos set to half."
    end
    return false, "lc_collapse_test black | next | stand | barney | freeman | mebarney | mefreeman | off | chaos"
end
concommand.Add("lc_collapse_test", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    LC.CollapseTester = IsValid(ply) and ply or nil
    local ok, why = LC.CollapseTest(string.lower(args[1] or ""))
    if IsValid(ply) then ply:ChatPrint("[Collapse] " .. tostring(why)) else print("[Collapse] " .. tostring(why)) end
end)
