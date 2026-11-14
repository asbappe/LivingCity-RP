--[[
    Living City: a deeper interrogation (the owner, 10 November: "I LOVE the
    interrogation idea, we already have one ... but it is rather shallow").

    The interrogator (sv_livingcity_custody.lua) now asks three questions,
    one at a time: where the hideout is, names, and where the weapons and
    supplies come from. For each, the prisoner chooses:

      - Tell the truth: real intel. A hideout or supply place is marked for
        every unit; a name is a real Resistance member's. The first truth
        pays the standing he offered, and the Resistance hears they talked.
      - Lie: a false lead, made up to sound right. One of the city's
        interrogators sees through a lie 35% of the time (15% more for each
        one after): another blow, and 2 minutes on the sentence. A lie he
        swallows sends the units the wrong way, and the Resistance hears of
        it (experience for the liar).
      - Say nothing: the baton. Each silence wears down their resolve (3);
        with none left, silence breaks and they tell the truth.
      - Bargain, once: the truth, for a third off the sentence.
      - Tell them everything (as before): a hideout, and it's over.
    No answer in 12 seconds is silence. The baton never takes anyone under
    10 health.

    A Civil Protection player can run it themselves: F2 > "Interrogate this
    prisoner", close to someone in a cell. They pick the questions and use
    the baton; the answers come to them (and only them), true or false, and
    nothing tells them which: they find out by acting on it. Anyone in a
    cell can be questioned this way; a citizen who knows nothing says so
    when they tell the truth.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_intr_q")     -- (server to prisoner: a question and the choices)
util.AddNetworkString("lc_intr_a")     -- (prisoner: the answer)
util.AddNetworkString("lc_intr_cp")    -- (server to the unit asking: the session)
util.AddNetworkString("lc_intr_cp_do") -- (the unit: ask N, baton, done)

local QS = {
    { key = "hideout",  text = "Where is the hideout? Where do they meet?" },
    { key = "names",    text = "Names. Who are your contacts?" },
    { key = "supplies", text = "Who gave you the weapon? Where do the supplies come from?" },
}
LC.InterrogationQuestions = QS
local ANSWER_SECS = 12
local CATCH = 0.35       -- one of the city's interrogators sees through a lie
local CATCH_MORE = 0.15  -- more for each lie after the first
local LIE_COST = 120     -- seconds on the sentence for a lie seen through
local TRUTH_PAY = 15     -- standing for each truth after the first (the first pays the offer)
local MAX_HITS = 8
local REACH = 260        -- a unit asking must stay this close

local function Pick(t) return t[math.random(#t)] end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function Place(pos) return (LC.DescribePlace and LC.DescribePlace(pos)) or "somewhere in the city" end
local function Rebel(ply)
    return ply:GetNW2String("lcf_faction", "") == "resistance" or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply)) == true
        or (LC.Trait and LC.Trait(ply, "sympathy") or 0) >= 3
end

local FAKE_FIRST = { "Viktor", "Anya", "Pavel", "Mira", "Tomas", "Lena", "Gregor", "Ilse", "Marek", "Dasha" }
local FAKE_LAST = { "Halloran", "Brecht", "Novak", "Sorel", "Kaminski", "Varga", "Lindqvist", "Orlov", "Petrov", "Duval" }

-- What they'd say. truth: what's really so (or "I don't know", when they don't); a lie sounds the same.
-- Returns the words, and a place to mark (or nil).
function LC.InterrogationIntel(prisoner, key, truth)
    local knows = Rebel(prisoner)
    if key == "hideout" or key == "supplies" then
        if truth then
            if not knows then return "\"I don't know anything about that. I swear.\"" end
            local spots = {}
            if key == "supplies" then
                for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("dealer") or {}) do spots[#spots + 1] = p.pos end
            end
            if #spots == 0 then for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do spots[#spots + 1] = z.pos end end
            if #spots == 0 then return "\"There's no place. We move around.\"" end
            local pos = Pick(spots)
            return string.format(key == "hideout" and "\"They meet %s.\"" or "\"The supplies come through %s.\"", Place(pos)), pos
        end
        local spots = {}
        for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do spots[#spots + 1] = z.pos end
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("idle") or {}) do spots[#spots + 1] = p.pos end
        if #spots == 0 then return key == "hideout" and "\"Under the old canal bridge.\"" or "\"A man at the train station.\"" end
        local pos = Pick(spots)
        return string.format(key == "hideout" and "\"They meet %s.\"" or "\"The supplies come through %s.\"", Place(pos)), pos
    end
    -- names
    if truth then
        if not knows then return "\"I don't know any names. I'm nobody.\"" end
        local them = {}
        for _, p in ipairs(player.GetAll()) do
            if p ~= prisoner and p:GetNW2String("lcf_faction", "") == "resistance" then them[#them + 1] = p end
        end
        if #them == 0 then return "\"Everyone I knew is dead or gone.\"" end
        local who = Pick(them)
        return "\"" .. Name(who) .. ". That's all I know.\"", nil, who
    end
    local them = {}
    for _, p in ipairs(player.GetAll()) do
        local f = p:GetNW2String("lcf_faction", "")
        if p ~= prisoner and (f == "" or f == "citizen") then them[#them + 1] = p end
    end
    if #them > 0 and math.random() < 0.6 then return "\"" .. Name(Pick(them)) .. ". That's all I know.\"" end
    return "\"" .. Pick(FAKE_FIRST) .. " " .. Pick(FAKE_LAST) .. ". That's all I know.\""
end

------------------------------------------------------------------------
-- The session
------------------------------------------------------------------------

local function Send(ply, name, t)
    if not IsValid(ply) then return end
    net.Start(name)
    net.WriteString(util.TableToJSON(t or {}) or "{}")
    net.Send(ply)
end

local function PushCP(ply, it)
    if not IsValid(it.byPlayer) then return end
    Send(it.byPlayer, "lc_intr_cp", { who = Name(ply), resolve = it.resolve or 0, hits = it.hits or 0,
        waiting = it.waiting and it.waiting.q or 0, answers = it.answers or {}, asked = it.asked or {},
        questions = { QS[1].text, QS[2].text, QS[3].text } })
end
LC.InterrogationPushCP = PushCP

local function Hit(ply, it, n)
    for _ = 1, n or 1 do
        if (it.hits or 0) >= MAX_HITS then return end
        it.hits = (it.hits or 0) + 1
        ply:SetHealth(math.max(10, ply:Health() - 6))
    end
    if ply.ScreenFade then ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 120), 0.4, 0) end
    ply:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 4) .. ".wav", 70)
    if ply.ViewPunch then ply:ViewPunch(Angle(math.random(-8, 8), math.random(-8, 8), 0)) end
end

local function Ask(ply, it, q)
    it.waiting = { q = q, untilT = CurTime() + ANSWER_SECS }
    it.asked = it.asked or {}
    it.asked[q] = true
    local text = QS[q].text
    ply:ChatPrint("[Interrogation] \"" .. text .. "\"")
    if IsValid(it.cop) then it.cop:EmitSound("npc/metropolice/vo/" .. Pick({ "apply", "isaidmovealong", "keepmoving" }) .. ".wav", 70) end
    Send(ply, "lc_intr_q", { q = q, text = text, resolve = it.resolve or 0, bargain = not it.bargained, secs = ANSWER_SECS,
        by = IsValid(it.byPlayer) and Name(it.byPlayer) or "a Civil Protection unit" })
    PushCP(ply, it)
end

-- What they said reaches the Combine: the unit asking (a player), or every unit (one of the city's).
local function Deliver(ply, it, q, words, pos, who)
    it.answers = it.answers or {}
    it.answers[#it.answers + 1] = { q = q, text = words }
    if IsValid(it.byPlayer) then
        it.byPlayer:ChatPrint("[Interrogation] " .. Name(ply) .. ": " .. words)
        PushCP(ply, it)
        return
    end
    local units = {}
    for _, p in ipairs(player.GetAll()) do
        if LC.PlayerIsCP(p) then
            units[#units + 1] = p
            p:ChatPrint("[CP net] A prisoner talked under interrogation: " .. words)
        end
    end
    if pos and LC.SendCompressed and #units > 0 then
        LC.SendCompressed("lc_cpmark", { name = QS[q].key == "supplies" and "SUPPLIES (INFORMANT)" or "HIDEOUT (INFORMANT)",
            x = pos.x, y = pos.y, z = pos.z, secs = 300 }, units)
    end
end

local function Talked(ply, it)
    if it.toldOnce then return end
    it.toldOnce = true
    if LC.AddStanding then LC.AddStanding(ply, LC.InterrogationReward or 50, "cooperated under interrogation") end
    if ply:GetNW2String("lcf_faction", "") == "resistance" or (LC.PlayerIsHunted and LC.PlayerIsHunted(ply)) then
        ply:SetNW2Float("lc_traitor_until", CurTime() + 1800)
        if LC.RadioNotice then LC.RadioNotice("resistance", ply:Nick() .. " talked in custody. Don't trust them.") end
    end
end

local function Finish(ply, it, words)
    local lies = it.liesBelieved or 0
    if lies > 0 and ply:GetNW2String("lcf_faction", "") == "resistance" then
        if LC.AddXP then LC.AddXP(ply, 10 * lies, "fed the interrogator false leads") end
        if LC.RadioNotice then LC.RadioNotice("resistance", ply:Nick() .. " fed the Combine false leads in custody.") end
    end
    if not it.toldOnce and lies == 0 and ply:GetNW2String("lcf_faction", "") == "resistance" and LC.AddXP then
        LC.AddXP(ply, 15, "said nothing under interrogation")
    end
    if IsValid(it.byPlayer) then
        Send(it.byPlayer, "lc_intr_cp", { done = true })
        it.byPlayer:ChatPrint("[Interrogation] You're done with " .. Name(ply) .. ".")
    end
    if LC.EndInterrogation then LC.EndInterrogation(ply, words) end
end

-- The prisoner's answer to the question in front of them: "truth", "lie", "silent" or "bargain".
function LC.InterrogationAnswer(ply, choice)
    local it = LC.Interrogations and LC.Interrogations[ply]
    if not it or not it.waiting then return false end
    local q = it.waiting.q
    it.waiting = nil
    it.next = CurTime() + math.Rand(3, 5)
    if choice == "bargain" and it.bargained then choice = "truth" end
    if choice == "silent" and (it.resolve or 0) <= 0 then
        ply:ChatPrint("[Interrogation] You can't take any more. It comes out of you.")
        choice = "truth"
    end
    if choice == "silent" then
        it.resolve = (it.resolve or 0) - 1
        it.silences = (it.silences or 0) + 1
        Hit(ply, it, 1)
        ply:ChatPrint("[Interrogation] You say nothing. The baton comes down.")
        if IsValid(it.byPlayer) then it.byPlayer:ChatPrint("[Interrogation] " .. Name(ply) .. " says nothing.") PushCP(ply, it) end
    elseif choice == "lie" then
        local words, pos = LC.InterrogationIntel(ply, QS[q].key, false)
        if not IsValid(it.byPlayer) and math.random() < CATCH + CATCH_MORE * (it.lies or 0) then
            it.lies = (it.lies or 0) + 1
            it.resolve = (it.resolve or 0) - 1
            Hit(ply, it, 2)
            local pr = LC.Prisoners and LC.Prisoners[ply]
            if pr then pr.untilT = pr.untilT + LIE_COST ply:SetNW2Float("lc_jail_until", pr.untilT) end
            ply:ChatPrint("[Interrogation] " .. words .. " ... \"Liar.\" He doesn't believe you. Two more minutes in the cell.")
        else
            it.lies = (it.lies or 0) + 1
            it.liesBelieved = (it.liesBelieved or 0) + 1
            ply:ChatPrint("[Interrogation] You tell him " .. words .. " He writes it down.")
            Deliver(ply, it, q, words, pos)
        end
    else -- truth, or a bargain
        local words, pos, who = LC.InterrogationIntel(ply, QS[q].key, true)
        if choice == "bargain" then
            it.bargained = true
            local pr = LC.Prisoners and LC.Prisoners[ply]
            if pr then
                local cut = math.floor(math.max(0, pr.untilT - CurTime()) / 3)
                pr.untilT = pr.untilT - cut
                ply:SetNW2Float("lc_jail_until", pr.untilT)
                ply:ChatPrint(string.format("[Interrogation] A deal: the truth, for %s off your sentence.", string.NiceTime(cut)))
            end
        end
        it.truths = (it.truths or 0) + 1
        if it.toldOnce and LC.AddStanding then LC.AddStanding(ply, TRUTH_PAY, "cooperated under interrogation") end
        Talked(ply, it)
        ply:ChatPrint("[Interrogation] You tell him the truth: " .. words)
        Deliver(ply, it, q, words, pos, who)
    end
    -- one of the city's: all three asked, it's over
    if not IsValid(it.byPlayer) then
        local all = true
        for i = 1, #QS do if not (it.asked and it.asked[i]) then all = false end end
        if all then
            Finish(ply, it, "[Interrogation] \"That will be all.\" The Civil Protection unit leaves.")
        end
    end
    return true
end

-- One of the city's interrogators, each tick (sv_livingcity_custody.lua).
function LC.InterrogationStep(ply, it, now)
    if IsValid(it.byPlayer) then
        -- a unit asking in person: he has to stay with them
        if not it.byPlayer:Alive() or it.byPlayer:GetPos():DistToSqr(ply:GetPos()) > REACH * REACH * 4 then
            it.byPlayer:ChatPrint("[Interrogation] You walked away from " .. Name(ply) .. ".")
            return Finish(ply, it, "[Interrogation] The unit walks away.")
        end
        if it.waiting and now > it.waiting.untilT then LC.InterrogationAnswer(ply, "silent") end
        return
    end
    if it.waiting then
        if now > it.waiting.untilT then LC.InterrogationAnswer(ply, "silent") end
        return
    end
    if now < (it.next or 0) then return end
    it.q = (it.q or 0) + 1
    if it.q > #QS then return Finish(ply, it, "[Interrogation] \"That will be all.\" The Civil Protection unit leaves.") end
    if it.q == 1 then Hit(ply, it, 1) end -- (to show he means it)
    Ask(ply, it, it.q)
end

------------------------------------------------------------------------
-- A Civil Protection player asking
------------------------------------------------------------------------

function LC.StartPlayerInterrogation(cp, prisoner)
    if not IsValid(cp) or not LC.PlayerIsCP(cp) then return false, "Civil Protection only." end
    if not IsValid(prisoner) or not prisoner:IsPlayer() or not (LC.Prisoners and LC.Prisoners[prisoner]) then return false, "Look at someone in a cell." end
    if cp:GetPos():DistToSqr(prisoner:GetPos()) > REACH * REACH then return false, "Get closer to them." end
    local it = LC.Interrogations[prisoner]
    if it and IsValid(it.byPlayer) and it.byPlayer ~= cp then return false, "Someone else is questioning them." end
    if it then
        -- take over from the city's interrogator
        if IsValid(it.cop) then
            if LC.NPCs then LC.NPCs[it.cop] = nil end
            it.cop:Remove()
            it.cop = nil
        end
    else
        it = { hits = 0, resolve = 3 }
        LC.Interrogations[prisoner] = it
        prisoner:SetNW2Bool("lc_interrogated", true)
        hook.Run("LivingCityInterrogation", prisoner)
    end
    it.byPlayer, it.untilT, it.waiting = cp, CurTime() + 600, nil
    prisoner:ChatPrint("[Interrogation] " .. Name(cp) .. " steps into your cell. \"You will answer my questions.\"")
    PushCP(prisoner, it)
    return true
end

function LC.PlayerInterrogationDo(cp, what, n)
    -- (a prison guard questioning a prisoner who isn't a player: sv_livingcity_prisonguard.lua)
    if LC.NPCInterrogationDo and LC.NPCInterrogationDo(cp, what, n) then return true end
    local prisoner, it
    for p, s in pairs(LC.Interrogations or {}) do if s.byPlayer == cp then prisoner, it = p, s break end end
    if not it then return false end
    if what == "ask" then
        if it.waiting then cp:ChatPrint("[Interrogation] Wait for an answer.") return false end
        if not QS[n] then return false end
        Ask(prisoner, it, n)
    elseif what == "baton" then
        if (it.hits or 0) >= MAX_HITS then cp:ChatPrint("[Interrogation] Any more and you'll kill them.") return false end
        it.resolve = math.max(0, (it.resolve or 0) - 1)
        Hit(prisoner, it, 1)
        prisoner:ChatPrint("[Interrogation] The baton comes down.")
        PushCP(prisoner, it)
    elseif what == "done" then
        Finish(prisoner, it, "[Interrogation] " .. Name(cp) .. " leaves your cell.")
    end
    return true
end

net.Receive("lc_intr_a", function(_, ply)
    local c = net.ReadString()
    if c == "everything" then
        if LC.InterrogationTalk then LC.InterrogationTalk(ply) end
        return
    end
    if c == "truth" or c == "lie" or c == "silent" or c == "bargain" then LC.InterrogationAnswer(ply, c) end
end)
net.Receive("lc_intr_cp_do", function(_, ply)
    local what, n = net.ReadString(), net.ReadUInt(3)
    if what == "start" then
        local tr = ply:GetEyeTrace()
        local e = tr and tr.Entity
        local okS, why = LC.StartPlayerInterrogation(ply, e)
        if not okS and why then ply:ChatPrint("[Interrogation] " .. why) end
        return
    end
    LC.PlayerInterrogationDo(ply, what, n)
end)
