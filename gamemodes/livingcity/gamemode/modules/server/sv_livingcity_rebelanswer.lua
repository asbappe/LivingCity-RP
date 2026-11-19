--[[
    Living City (server): what becomes of the Resistance's prisoners, and what the city makes of it

    The owner, 12 November: the rebels "would likely imprison, interrogate, then
    either execute or let go", and executions should have consequences inside
    the Resistance, among the people, and from the Administrator. Settled then:
    the people's opinion of the Resistance is never a number, a bar or a chat
    line: "felt and overheard" (what citizens say when you talk to them), and
    only the Resistance's leader has it in words, a sentence on their clipboard.
    Built 19 November ("let's build these now please").

    How the people see the Resistance
        One hidden figure for the city (-100 to 100, kept with the state of the
        city), drifting back towards nothing. Down: executions (a prisoner who had
        done nothing, the most; a unit, less; a confessed informer, hardly), a
        body found. Up: a killer answered for (expelled, demoted, shot), mercy, a
        rebel shot by the Combine's firing squad (a martyr), an exchange, the
        Combine's own brutality. Felt: in what citizens say (the loyal call it
        murder, the bitter call it justice), on the leader's clipboard, in how
        many citizens turn informer and how many sympathize. A cell that has
        shot someone lately frightens informers into silence for a while.
    Letting them go (the cage, as before, for a Fighter or above)
        With a warning: the timid keep quiet; the loyal go straight to a unit
            and tell them where the cage is.
        Blindfolded and walked out: put down somewhere far off; nobody learns
            the way back.
        Turned: likelier the less loyal they are. Turned, they feed the units
            lies (the next raid goes wrong); if not, they go to a unit.
    Exchanges
        A Lieutenant or above offers one of the cage's prisoners for a member of
        the Resistance in the Combine's cells; the Administrator answers (her F2 >
        City orders; with nobody playing her, the city's own, by its mood). She
        can offer one the other way too, as her answer to a killing; the
        Resistance answers at the cage. Refusing her costs them with the people.
    The body
        One of the city's own shot at the cage or the chair leaves a body. Found
        outside rebel ground by a unit or a citizen (or by a unit anywhere), it is
        evidence: the Combine learn where it came from, and the people hear.
        Hauled off and hidden, or burned, nothing comes of it.
    The Administrator answers
        A killing the Combine know of (a body found, or done where citizens saw)
        is named over the PA. Then she chooses (a player: F2 > City orders >
        Answer the killing; else the city's own after a minute): a reprisal (a
        member of the Resistance in the cells to the firing squad,
        sv_livingcity_firingsquad.lua), a raid (Civil Protection sent to retake
        rebel ground, the nearest to what they have learned), the high ground
        (an amnesty, or extra rations), or an exchange offered to the Resistance.

    lc_rebel_answer 1/0
]]

LC = LC or {}

local cvOn = CreateConVar("lc_rebel_answer", "1", FCVAR_ARCHIVE, "What the Resistance's prisoners come to: three ways of letting them go, exchanges, bodies as evidence, how the people see the Resistance, and the Administrator's answer to a killing")

local DRIFT_SECS = 600     -- one point back towards nothing this often
local RUTHLESS_SECS = 1800
local SEEN_RANGE = 700
local OFFER_SECS = 150
local ANSWER_SECS = 300
local CITY_ANSWER_SECS = 60

if util.AddNetworkString then
    util.AddNetworkString("lc_rk_do")
    util.AddNetworkString("lc_xchg_do")
end

local function On() return cvOn:GetBool() end
local function Key(p) return LC.MindsWhoKey and LC.MindsWhoKey(p) or nil end
local function NameOf(e)
    if not IsValid(e) then return "someone" end
    if e:IsPlayer() then return e:Nick() end
    return (LC.NPCStr and LC.NPCStr(e, "lc_pname", "") ~= "" and LC.NPCStr(e, "lc_pname", "")) or (e.lcProfile and e.lcProfile.name) or "a citizen"
end
local function Loyal(npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.rebel then return -1 end
    local p = IsValid(npc) and npc.lcProfile
    if p and LC.Psy and LC.MindOf then
        local ok, t = LC.Try(function() return LC.Psy.Traits(LC.MindOf(p)) end)
        if ok and t then return t.loyal or 0, t end
    end
    return 0
end
local function IsUnitEnt(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return LC.PlayerIsCP ~= nil and LC.PlayerIsCP(e) and e:Alive() end
    local st = LC.NPCs and LC.NPCs[e]
    return st ~= nil and (st.role == "cop" or st.role == "soldier")
end
local function Sees(a, b)
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_OPAQUE })
    return not (tr and tr.Hit)
end

------------------------------------------------------------------------
-- How the people see the Resistance
------------------------------------------------------------------------

local function L() return LC.Ledger and LC.Ledger() or nil end

function LC.RebelStanding()
    local l = L()
    return l and tonumber(l.rebstanding) or 0
end

function LC.RebelStandingPush(d, why)
    local l = L()
    if not l or not On() then return 0 end
    l.rebstanding = math.Clamp((tonumber(l.rebstanding) or 0) + d, -100, 100)
    if LC.MindsNote then LC.MindsNote("REBSTANDING", string.format("%+d (%s): now %d", d, tostring(why or "?"), l.rebstanding)) end
    return l.rebstanding
end

function LC.RebelRuthless() return (LC.RebelRuthlessUntil or 0) > CurTime() end

-- (sv_livingcity_snitches.lua: how many new citizens turn informer)
function LC.RebelStandingSnitchMul()
    if not On() then return 1 end
    return math.Clamp(1 - LC.RebelStanding() / 200, 0.5, 1.5) * (LC.RebelRuthless() and 0.7 or 1)
end
-- (sv_livingcity_people.lua: how many new citizens sympathize)
function LC.RebelStandingSympathyMul()
    if not On() then return 1 end
    return math.Clamp(1 + LC.RebelStanding() / 200, 0.5, 1.5)
end

-- The leader's clipboard (sv_livingcity_rebelrule.lua): the general feeling, in words, never a figure.
function LC.RebelSentiment()
    if not On() then return nil end
    local s = LC.RebelStanding()
    local line
    if s <= -40 then line = "People are afraid of us, and a few are starting to talk to the units."
    elseif s <= -15 then line = "People are wary of us. Doors close when we come by."
    elseif s < 15 then line = "People keep their heads down. Nobody is sure about us yet."
    elseif s < 40 then line = "People are warming to us. Some leave food out."
    else line = "The people are with us. They hide our fighters and look the other way." end
    if LC.RebelRuthless() then line = line .. " The informers have gone quiet: they've heard what we do." end
    return line
end

-- What a citizen says about the Resistance when you talk to them (sv_livingcity_talk.lua), now and then.
local GOSSIP = {
    low = {
        loyal = { "Those rebels shot someone in that cage of theirs. Murderers, the lot of them.", "If you know where they hide, tell a unit. I would." },
        bitter = { "They shot someone. Maybe they had it coming. Maybe not.", "The Resistance used to stand for something." },
        plain = { "People say the rebels kill their own prisoners. I don't want to know.", "I keep away from anyone who talks about the Resistance." },
    },
    high = {
        loyal = { "Some fools here think the rebels are heroes. They'll learn.", "The rebels hand out food to buy us. Don't take it." },
        bitter = { "The Resistance look after their own. And some of us.", "They got one of theirs out of the cells, I heard. Good." },
        plain = { "The rebels left tins on the stairs in our block. Nobody saw anything.", "People talk about the Resistance more kindly these days." },
    },
}
function LC.RebelGossip(npc, st)
    if not On() or math.random() > 0.4 then return nil end
    local s = LC.RebelStanding()
    local band = s <= -15 and "low" or (s >= 15 and "high" or nil)
    if not band then return nil end
    local loyal = Loyal(npc)
    local kind = (loyal or 0) > 0.3 and "loyal" or ((loyal or 0) < -0.3 and "bitter" or "plain")
    local pool = GOSSIP[band][kind]
    return pool[math.random(#pool)]
end

local function DriftTick()
    local l = L()
    if not l then return end
    local s = tonumber(l.rebstanding) or 0
    if s > 0 then l.rebstanding = s - 1 elseif s < 0 then l.rebstanding = s + 1 end
end

------------------------------------------------------------------------
-- The killing, its body, and who knows of it
------------------------------------------------------------------------

LC.RebelBodies = LC.RebelBodies or {} -- [body] = { name, from, t }
LC.RebelIntel = LC.RebelIntel or nil  -- { pos, t, why }: where the Combine think the Resistance keep their prisoners
LC.RebelLies = LC.RebelLies or 0      -- false reports from turned prisoners still in the units' heads

function LC.RebelIntelAdd(pos, why)
    if not pos then return end
    if LC.RebelLies > 0 then
        -- (a turned prisoner's lies come first: the units chase the wrong place)
        LC.RebelLies = LC.RebelLies - 1
        return
    end
    LC.RebelIntel = { pos = pos, t = CurTime(), why = why }
end

local function KindOfVictim(t)
    if IsUnitEnt(t) then return "unit" end
    local st = (not t:IsPlayer()) and LC.NPCs and LC.NPCs[t] or nil
    if (LC.IsBurned and LC.IsBurned(t)) or (st and (st.snitch or st.informer)) then return "informer" end
    return "innocent"
end

local function Witnessed(pos)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and not st.rebel and npc:GetPos():DistToSqr(pos) < 800 * 800
            and Sees(npc:EyePos(), pos + Vector(0, 0, 40)) then return true end
    end
    for _, p in ipairs(player.GetAll()) do
        local f = p:GetNW2String("lcf_faction", "")
        if p:Alive() and f ~= "resistance" and f ~= "vort" and p:GetPos():DistToSqr(pos) < 800 * 800 and Sees(p:EyePos(), pos + Vector(0, 0, 40)) then return true end
    end
    return false
end

hook.Add("LivingCityExecuted", "LivingCityRebelAnswer", function(by, target, approved, final)
    if not On() or not IsValid(target) then return end
    local kind = KindOfVictim(target)
    LC.RebelStandingPush(kind == "innocent" and -8 or (kind == "unit" and -3 or -1), "an execution (" .. kind .. ")")
    LC.RebelRuthlessUntil = CurTime() + RUTHLESS_SECS
    local name, pos = NameOf(target), target:GetPos()
    -- in front of people: word gets to the Combine within the minute
    if Witnessed(pos) then
        timer.Simple(60, function() if LC.RebelKillingKnown then LC.RebelKillingKnown(name, "witnesses", pos) end end)
    end
    -- one of the city's own leaves a body: mark it once it's there
    if not target:IsPlayer() then
        timer.Simple(1, function()
            for _, e in ipairs(ents.FindInSphere(pos, 160)) do
                if IsValid(e) and e.lcBody and not LC.RebelBodies[e] then
                    LC.RebelBodies[e] = { name = name, from = pos, t = CurTime() }
                    break
                end
            end
        end)
    end
end)

hook.Add("LivingCityExecJudged", "LivingCityRebelAnswer", function(killer, what)
    local d = ({ expel = 4, demote = 2, execute = 5 })[what]
    if d then LC.RebelStandingPush(d, "a killer answered for (" .. what .. ")") end
end)

hook.Add("LivingCityFiringSquadDone", "LivingCityRebelAnswer", function(t, how)
    if how == "shot" and IsValid(t) and ((t:IsPlayer() and t:GetNW2String("lcf_faction", "") == "resistance") or (not t:IsPlayer())) then
        LC.RebelStandingPush(5, "a martyr")
    elseif how == "rescued" then
        LC.RebelStandingPush(2, "a rescue from the wall")
    end
end)

-- the Combine's own brutality: a citizen killed by a unit
hook.Add("OnNPCKilled", "LivingCityRebelAnswer", function(npc, attacker)
    if not On() or not IsValid(npc) or not IsUnitEnt(attacker) then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.role == "citizen" and not st.rebel then LC.RebelStandingPush(1, "a citizen killed by a unit") end
end)

local function Hauled(body)
    for _, p in ipairs(player.GetAll()) do if p:GetNW2Entity("lc_haul_body") == body then return true end end
    return false
end

-- A body seen: by a unit anywhere, or by a citizen outside rebel ground (while someone is hauling it, nobody looks twice).
function LC.RebelBodyTick()
    for body, b in pairs(LC.RebelBodies) do
        if not IsValid(body) then
            LC.RebelBodies[body] = nil
        elseif not Hauled(body) then
            local pos = body:GetPos()
            local rebelGround = LC.InRebelZone and LC.InRebelZone(pos)
            local found
            for _, p in ipairs(player.GetAll()) do
                if IsUnitEnt(p) and p:GetPos():DistToSqr(pos) < SEEN_RANGE * SEEN_RANGE and Sees(p:EyePos(), pos + Vector(0, 0, 10)) then found = true break end
            end
            if not found then
                for npc, st in pairs(LC.NPCs or {}) do
                    if IsValid(npc) and npc:GetPos():DistToSqr(pos) < SEEN_RANGE * SEEN_RANGE
                        and (st.role == "cop" or st.role == "soldier" or (st.role == "citizen" and not st.rebel and not rebelGround))
                        and Sees(npc:EyePos(), pos + Vector(0, 0, 10)) then found = true break end
                end
            end
            if found then
                LC.RebelBodies[body] = nil
                LC.RebelStandingPush(-3, "a body found")
                LC.RebelIntelAdd(b.from, "a body found")
                LC.RebelKillingKnown(b.name, "body", pos)
                hook.Run("LivingCityRebelBodyFound", body, b)
            end
        end
    end
end

------------------------------------------------------------------------
-- Letting them go (the cage: sv_livingcity_rebelhold.lua calls this)
------------------------------------------------------------------------

local function FarSpot(from)
    for _ = 1, 30 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("citizen", from)
        if p and p:DistToSqr(from) > 1500 * 1500 and not (LC.InRebelZone and LC.InRebelZone(p)) and not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40))) then return p end
    end
    return nil
end

-- They go to a unit with what they know (the cage's place), unless they don't live that long.
local function Talks(npc, from)
    timer.Simple(40, function()
        if IsValid(npc) and npc:Health() > 0 and not (LC.RebelHeld and LC.RebelHeld[npc]) then LC.RebelIntelAdd(from, "a released prisoner talked") end
    end)
end

-- how: "warn", "blind" or "turn". Returns what's said to the one who did it.
function LC.RebelReleaseHow(ply, cage, npc, how)
    if not On() or not (LC.RebelHeld and LC.RebelHeld[npc]) or not LC.CageFree then return nil end
    local from = IsValid(cage) and cage:GetPos() or npc:GetPos()
    local loyal = Loyal(npc) or 0
    LC.CageFree(npc)
    if how == "blind" then
        local spot = FarSpot(from)
        if spot then npc:SetPos(spot) end
        LC.RebelStandingPush(2, "a prisoner let go, blindfolded")
        return "A sack over their head, a long walk, and they're left somewhere they won't find the way back from."
    elseif how == "turn" then
        local chance = math.Clamp(0.5 - loyal * 0.4, 0.1, 0.9)
        if math.random() < chance then
            LC.RebelLies = LC.RebelLies + 1
            local st = LC.NPCs and LC.NPCs[npc]
            if st then st.snitch = false end
            npc.lcTurned = true
        else
            Talks(npc, from)
        end
        return "They swear they'll feed the units what we tell them. Time will show if they meant it."
    end
    -- a warning: the loyal go straight to a unit
    LC.RebelStandingPush(1, "a prisoner let go with a warning")
    if loyal > 0.2 then Talks(npc, from) end
    return "'Say a word about this place and we'll find you.' They nod, and go."
end

------------------------------------------------------------------------
-- Exchanges
------------------------------------------------------------------------

LC.Exchange = LC.Exchange or nil -- { from = "resistance" or "combine", held = the cage's prisoner, rebel = in the cells, t, by }

-- A member of the Resistance in the Combine's cells (a player, or one of the city's own).
function LC.ExchangeRebel()
    if LC.JailedRebel then
        local p = LC.JailedRebel()
        if IsValid(p) then return p end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.state == "jailed" and (st.rebel or st.role == "rebel") then return npc end
    end
    return nil
end
local function HeldAny()
    for npc in pairs(LC.RebelHeld or {}) do if IsValid(npc) then return npc end end
    return nil
end

local function Publish()
    local x = LC.Exchange
    SetGlobal2String("lc_xchg", x and util.TableToJSON({ from = x.from, a = NameOf(x.held), b = NameOf(x.rebel) }) or "")
end

function LC.ExchangeOffer(from, by, held, rebel)
    if not On() or LC.Exchange then return false, "An exchange is already on the table." end
    held, rebel = held or HeldAny(), rebel or LC.ExchangeRebel()
    if not (IsValid(held) and LC.RebelHeld and LC.RebelHeld[held]) then return false, "The Resistance hold nobody." end
    if not IsValid(rebel) then return false, "None of ours is in the Combine's cells." end
    LC.Exchange = { from = from, held = held, rebel = rebel, t = CurTime(), by = by }
    Publish()
    local a, b = NameOf(held), NameOf(rebel)
    if LC.RadioNotice then
        if from == "resistance" then
            LC.RadioNotice("cp", "The Resistance offer " .. a .. " for " .. b .. ". The Administrator decides.")
        else
            LC.RadioNotice("resistance", "The Combine offer " .. b .. " for " .. a .. ". The answer is given at the cage.")
        end
    end
    return true, from == "resistance" and ("You send word: " .. a .. " for " .. b .. ".") or nil
end

function LC.ExchangeAnswer(yes, by)
    local x = LC.Exchange
    if not x then return false end
    LC.Exchange = nil
    Publish()
    if not (IsValid(x.held) and IsValid(x.rebel)) then return false end
    local a, b = NameOf(x.held), NameOf(x.rebel)
    if yes then
        if x.rebel:IsPlayer() then
            if LC.ReleasePrisoner and LC.Prisoners and LC.Prisoners[x.rebel] then LC.ReleasePrisoner(x.rebel) end
        else
            local st = LC.NPCs and LC.NPCs[x.rebel]
            if st and LC.ReleaseNPCPrisoner then LC.ReleaseNPCPrisoner(x.rebel, st, CurTime(), true) end
        end
        if LC.CageFree and LC.RebelHeld and LC.RebelHeld[x.held] then LC.CageFree(x.held) end
        LC.RebelStandingPush(2, "an exchange")
        if LC.RadioNotice then LC.RadioNotice("resistance", "The exchange is done: " .. b .. " is coming home.") end
        if LC.ChronicleAdd then
            local s = x.rebel:IsPlayer() and Key(x.rebel) or (x.rebel.lcProfile and x.rebel.lcProfile.id)
            if s then LC.ChronicleAdd({ k = "exchanged", s = s, pred = "was exchanged for " .. a, pos = x.rebel:GetPos(), w = 3 }) end
        end
    elseif x.from == "resistance" then
        LC.RebelStandingPush(1, "the Combine refused an exchange")
        if LC.LedgerAdd then LC.LedgerAdd("morale", -2, "an exchange refused") end
        if LC.RadioNotice then LC.RadioNotice("resistance", "The Combine said no. " .. b .. " stays in the cells.") end
    else
        LC.RebelStandingPush(-3, "the Resistance refused an exchange")
    end
    hook.Run("LivingCityExchange", x, yes)
    return true
end

------------------------------------------------------------------------
-- The Administrator answers
------------------------------------------------------------------------

LC.RebelAnswerPending = LC.RebelAnswerPending or nil -- { name, how, t, pos, player = a player Administrator was asked }

local function PlayerAdministrator()
    for _, p in ipairs(player.GetAll()) do if p:GetNW2String("lcf_faction", "") == "admin" and p:Alive() then return p end end
    return nil
end

-- What she could do now: { reprisal = target or nil, raid = zone or true, high = true, exchange = true }
function LC.RebelAnswerOptions()
    local o = { high = true }
    if LC.FiringSquadWall and LC.FiringSquadWall() and not LC.FiringSquad and LC.FiringSquadCandidates then
        for _, c in ipairs(LC.FiringSquadCandidates()) do if c.why == "the Resistance" then o.reprisal = c.ent break end end
    end
    local grown, best, bd = false, nil, nil
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if z.grown then
            grown = true
            local i = LC.RebelIntel
            if i and CurTime() - i.t < 1800 then
                local d = z.pos:DistToSqr(i.pos)
                if not bd or d < bd then best, bd = z, d end
            end
        end
    end
    if grown then o.raid = best or true end
    if not LC.Exchange and HeldAny() and LC.ExchangeRebel() then o.exchange = true end
    return o
end

local function PublishAnswer()
    local a = LC.RebelAnswerPending
    if not a or not a.player then SetGlobal2String("lc_rk_answer", "") return end
    local o = LC.RebelAnswerOptions()
    SetGlobal2String("lc_rk_answer", util.TableToJSON({ name = a.name, reprisal = o.reprisal ~= nil, raid = o.raid ~= nil, exchange = o.exchange == true }))
end

function LC.RebelKillingKnown(name, how, pos)
    if not On() then return false end
    local a = LC.RebelAnswerPending
    if a and CurTime() - a.t < 600 then return false end -- (one answer at a time)
    local her = PlayerAdministrator()
    LC.RebelAnswerPending = { name = name, how = how, t = CurTime(), pos = pos, player = IsValid(her) or nil }
    -- her word to the city, in her own slogan (the owner's, 14 November: never reworded)
    if LC.Announce then LC.Announce("rebel_killing", nil, "The Resistance murdered " .. tostring(name) .. ". Love your neighbour, hate the traitor.") end
    PublishAnswer()
    hook.Run("LivingCityRebelKillingKnown", name, how, pos)
    return true
end

-- what: "reprisal", "raid", "high", "exchange". by: her (a player), or nil (the city's own).
function LC.RebelAnswer(by, what)
    local a = LC.RebelAnswerPending
    if not a or not On() then return false, "There's nothing to answer." end
    if IsValid(by) and by:GetNW2String("lcf_faction", "") ~= "admin" then return false end
    local o = LC.RebelAnswerOptions()
    if what == "reprisal" then
        if not o.reprisal or not LC.FiringSquadOrder then return false, "There's nobody to shoot for it, or no wall." end
        local ok, why = LC.FiringSquadOrder(by, o.reprisal, "reprisal")
        if not ok then return false, why end
    elseif what == "raid" then
        if not o.raid or not LC.PostDirective then return false, "The Resistance hold no ground to retake." end
        LC.PostDirective("cp_retake", o.raid ~= true and o.raid or nil)
        if LC.LedgerAdd then LC.LedgerAdd("authority", 2, "a raid for a killing") end
    elseif what == "exchange" then
        if not o.exchange then return false, "There's nobody to exchange." end
        local ok, why = LC.ExchangeOffer("combine", by)
        if not ok then return false, why end
    else
        what = "high"
        -- the moral high ground: an amnesty, or extra rations
        local done = false
        if IsValid(by) then
            if LC.Amnesty then done = LC.Amnesty(by) end
            if not done and LC.ExtraRations then done = LC.ExtraRations(by) end
        elseif LC.LedgerAdd then
            LC.LedgerAdd("morale", 6, "an amnesty for a killing") LC.LedgerAdd("authority", -4, "an amnesty for a killing")
            done = true
        end
        LC.RebelStandingPush(-4, "the Administrator took the high ground")
    end
    LC.RebelAnswerPending = nil
    PublishAnswer()
    hook.Run("LivingCityRebelAnswered", what, by)
    return true, what
end

-- With nobody playing her (or her not answering in time): the city's own, by the state of things.
function LC.RebelAnswerCity()
    local o = LC.RebelAnswerOptions()
    local l = L() or {}
    if o.reprisal and (tonumber(l.authority) or 50) >= 45 then return LC.RebelAnswer(nil, "reprisal") end
    if o.raid then return LC.RebelAnswer(nil, "raid") end
    if o.exchange and math.random() < 0.5 then return LC.RebelAnswer(nil, "exchange") end
    return LC.RebelAnswer(nil, "high")
end

function LC.RebelAnswerTick(now)
    local a = LC.RebelAnswerPending
    if a then
        local wait = a.player and ANSWER_SECS or CITY_ANSWER_SECS
        if now - a.t >= wait then LC.RebelAnswerCity() end
    end
    local x = LC.Exchange
    if x then
        if not (IsValid(x.held) and IsValid(x.rebel) and LC.RebelHeld and LC.RebelHeld[x.held]) then
            LC.Exchange = nil Publish()
        elseif now - x.t >= OFFER_SECS then
            if x.from == "resistance" then
                LC.ExchangeAnswer(math.random() < 0.5, nil) -- (the city's own)
            else
                local mood = LC.RebelAtmosphere and LC.RebelAtmosphere() or "calm"
                LC.ExchangeAnswer(mood == "calm" or mood == "wary", nil) -- (the cell's own, by its mood)
            end
        end
    end
end

net.Receive("lc_rk_do", function(_, ply)
    local what = net.ReadString()
    if (ply.lcRkNext or 0) > CurTime() then return end
    ply.lcRkNext = CurTime() + 1
    LC.RebelAnswer(ply, what) -- (what can't be done is greyed on her menu, with why)
end)

net.Receive("lc_xchg_do", function(_, ply)
    local yes = net.ReadBool()
    local x = LC.Exchange
    if not x then return end
    if x.from == "resistance" and ply:GetNW2String("lcf_faction", "") ~= "admin" then return end
    if x.from == "combine" and not (LC.RebelMayOrder and LC.RebelMayOrder(ply)) then return end
    LC.ExchangeAnswer(yes, ply)
end)

timer.Create("LivingCityRebelAnswer", 1, 0, function()
    if not On() then return end
    local now = CurTime()
    local ok, err = LC.Try(LC.RebelAnswerTick, now)
    if not ok and LC.Error then LC.Error("the Administrator's answer", err) end
    if math.floor(now) % 3 == 0 then
        ok, err = LC.Try(LC.RebelBodyTick)
        if not ok and LC.Error then LC.Error("the Resistance's bodies", err) end
    end
end)
timer.Create("LivingCityRebelStandingDrift", DRIFT_SECS, 0, function() if On() then LC.Try(DriftTick) end end)
