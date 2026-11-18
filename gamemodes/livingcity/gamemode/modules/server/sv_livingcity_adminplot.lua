--[[
    Living City: the plot against the Administrator, a coordinated attack and not a lone wolf

    The owner, 17 November: "if the attempted assassin is a resistance member that was
    ordered by a resistance leader, or given a job by the resistance leader, to
    assassinate her, I would love for a few resistance/rebel fighters to appear all over
    the place, maybe like 7 or 8, so it looks like a coordinated rebel attack and not a
    lone wolf. However if it is just a lone wolf, then none of that happens."

    The order   The owner, 18 November: "a resistance human player with the role of
                resistance leader can assign the quest to certain resistance members of
                their discretion and it advises them to speak with that player in
                private." The leader is a Commander who is playing; a Lieutenant when no
                Commander is ("Commanders, else Lieutenants"). Their F2 > Resistance has
                "Order: kill the Administrator": the Resistance's players who are Fighters
                or higher, the leader among them. At any time, her address on or not.
                A name sends for that member; the same name again says they have spoken;
                once more takes it back. Nothing when it is taken back, nothing to anyone
                else, nothing on the radio, nothing a unit could hear of. A leader who
                picks themselves has the order at once and reads nothing.
                It replaced the plan on the planning board of 17 November, which the whole
                Resistance heard of on its radio (the owner: "Assignment replaces the
                radio plan").
    Sent for    The owner, 18 November: the private line "should trigger a quest/job that
                the player is auto-enrolled in and becomes active with no time limit; it
                should need to be fulfilled before being able to take any other
                job/quest/work: this also means it needs to be FOOLPROOF and have triple
                layers of checks to make sure it doesn't glitch out or get stuck and
                un-finishable". The member reads one line, alone: "[Freq 7] <the leader>
                wants a word with you, in private.", and is put straight in a job of their
                own: "A word with <the leader>", "Speak with <the leader>, in private.",
                no time limit, its marker on the leader, nothing paid. It is done by an
                act, never by standing anywhere: the member presses E at the leader within
                reach, or the leader at the member, or the leader picks their name again.
                Who else is near is never asked: "in private" is theirs to see to. Only
                then is the order theirs. Until then every door that work comes through
                is shut to them ("<the leader> wants a word with you first."): the board
                (a job, a story's part, a Union shift, a job over the radio, a foreman's
                work order), a Union job and the Labor Assignment terminal, planning or
                joining an operation, a stall owner's offer. They cannot drop it.
                Someone sent for while they hold another job keeps that job and is put in
                this one the moment it ends.
    Never stuck 1. What happens to them or the leader ends it at once, with no line, no
                mark against them and no wait: the leader takes it back; the member is
                arrested, someone new, out of the Resistance or below a Fighter; the
                leader is gone from the server, dead for good, out of the Resistance or
                a leader no more (then it is whoever leads now they speak with, title
                and marker following; with nobody leading they are free).
                2. Every two seconds everyone sent for is looked at: what is kept with
                the character and the job must agree. A record with no job (the quest
                system lost it): the job is put back, and if that fails twice the record
                goes. A job with no record: ended. A leader no longer one: as above.
                Older than an hour: ended, whatever became of the leader.
                3. The leader's list takes it back by the record, whatever has become of
                the job. Everything here runs in LC.Try: an error frees whoever it was
                about and is written in the errors file.
                It is kept with the character (PData lc_adminplot_order: "word" sent for,
                "1" under the order) over a reconnect and a restart of the server, and
                they come back pointed at whoever leads now.
    Its price   The owner, 18 November: "the resistance leader can only order this if
                they've saved up enough money themselves to put into this extra pay, or
                have gathered enough funds in a Resistance fund". Each member sent for
                costs lc_resistance_order_cost credits (300; 0: free), charged at the
                moment they are sent for: out of the Resistance's fund when it holds
                enough (sv_livingcity_resistancefund.lua), else out of the leader's own
                credits; when neither can pay, nobody is sent for and the leader reads
                one line. A leader who picks themselves pays the same. Where it came
                from is kept with the order (PData lc_adminplot_price: "300:fund", or
                "300:<the leader's SteamID64>:<their citizen number>"), so a reconnect
                or a restart loses nothing. An order that ends before that member has
                made the attempt (taken back, arrested, someone new, out of the
                Resistance, below a Fighter, an hour gone by unspoken, nobody leading)
                gives it back where it came from: the fund, or the leader who paid if
                they are still that person, of the Resistance and playing, else the
                fund. Made, the attempt spends it for good. Nothing is said of any of
                it. The job on the board costs nothing.
    Under it    Each member's order is their own: it ends when they make the attempt
                (paid what the job pays; anyone after the first at one address, half),
                when the leader takes it back, when they are arrested, are someone new,
                are out of the Resistance or below a Fighter. It does not need the
                leader to stay.
    The job     "Kill the Administrator" is on the Resistance's board (Operations), and
                nobody else's, from the moment the city is called to her address until
                someone tries, and only while nobody leads: with a Commander or a
                Lieutenant playing it is not offered, and the order comes from them alone
                (whoever holds it already keeps it). Its one step is making the attempt at
                her address. Taken by one and only one (the owner, 18 November): Fighters
                and up, and nobody below that rank sees it on the board (the owner,
                17 November: "fighters and up only"). It pays when the attempt is made
                (the owner: "xp should be 250 for trying, 250 more if successful, plus a
                100 credit stipend": 250 experience, 100 credits in all, 250 more
                experience if she dies of it, then or after the roll in her office) and
                ends there. Nobody is told it has gone up (the owner: "it should just go
                on the board. Keep as minimal a chance of CP/overwatch/administrator
                finding out about it"). It also ends when her address is over, and as any
                job does: dropped, arrested, a new character, gone from the server.
    Half after  The owner, 18 November: "Only the first should be paid that high, the
    the first   rest maybe 1/2 or less." At one address the first under orders whose
                attempt counts (the job or the order) is paid in full. Anyone else
                under the leader's order whose attempt counts there (a hit on her, or
                marked by her guards as an attacker once they have her) is paid half of
                each part: 125 experience, 50 credits, and 125 more if she dies of it.
                Her next address starts again. The fighters still come once.
    Ordered     An attempt on her life at her address (LC.AdminAttempt,
                sv_livingcity_adminsecurity.lua) by someone who holds the job or the
                order. Anyone else's (a lone wolf, a rogue unit, a citizen) brings
                nobody: that is as it was.
    The attack  Seven or eight Resistance fighters (fewer when the Resistance's reserve
                is short, none when it is empty: sv_livingcity_manpower.lua) come out
                round the stand at once, each from one of the city's own walking spots or
                doorways that no player can see at that moment, one from each direction
                first and never two close together (where there are too few such spots, two
                or three from one, a step apart). They are the city's own fighters
                (LC.SpawnRebel: the same people, guns and health) and fire on her guards,
                the units there and the Combine's players; never on citizens or the
                Resistance, whom their fire cannot hurt. Her guards may hurt them
                (LC.AdminTargets). They are on top of the city's own numbers, as her
                guards are.
    Leaving     When she is gone (and they have fought at least forty seconds), or after
                ninety seconds, the living break off, run back the way they came and are
                taken out of the city once nobody can see them: back in the reserve. The
                dead are lost to it, as in any skirmish.
    Told        nobody, in words. The fighters arriving are the news.

    Hooks heard: LivingCityAdminExfil (her guards are getting her out: who set it off),
    LivingCityAdminAttempt (a grenade by her), her own hurt and death at her address, and
    LivingCitySpeechCalled and LivingCitySpeechEnded (the job goes on the board, and comes
    off it), LivingCityNewCharacter, LivingCityIncarcerated, LivingCityFactionChanged,
    LivingCityRankChanged, PlayerDisconnected and PlayerInitialSpawn (an order or a summons
    is no longer theirs, or its leader no longer one), LivingCityQuestComplete and
    LivingCityQuestFailed (a job of theirs is over: the one they were sent for begins), and
    KeyPress (E at each other). Nothing is answered to any of them. One setting,
    lc_resistance_order_cost (300); the other numbers are the constants below. The
    leader's list and the price reach F2, and the name picked comes back, by F2's own
    way (sv_livingcity_quickmore.lua). The job is given and taken
    back by LC.GiveQuest and LC.WithdrawQuest (sv_livingcity_quests.lua), and every door
    that work comes through asks LC.AdminPlotBusy.
]]

if CLIENT then return end

LC = LC or {}

local JOB = "res_regicide"
local TITLE = "Kill the Administrator"
local LINE = "At her address. Our fighters open fire when you do."
local WORD_LINE = "[Freq 7] %s wants a word with you, in private." -- all the chosen member is told: who, and not what about
local JOB_TITLE = "A word with %s"            -- the job they are put in: its title,
local JOB_LINE = "Speak with %s, in private." -- and its one line
local BUSY = "%s wants a word with you first." -- what every other door that work comes through says until then
local ORDER_KEY = "lc_adminplot_order" -- PData: "word" (sent for by a leader, not spoken with yet) or "1" (under the order)
local PRICE_KEY = "lc_adminplot_price" -- PData, with the order until the attempt: what was paid for it and out of what ("300:fund", or "300:<the leader's SteamID64>:<their citizen number>")
local SHORT = "Neither the fund nor you can pay %d credits." -- all a leader reads when the price cannot be paid
local LEADER, DEPUTY = 5, 4    -- who gives the order: a Commander; a Lieutenant when no Commander is playing
local WITHIN = 130             -- how near E at each other counts as having spoken
local WATCH = 2                -- seconds between two looks at everyone sent for
local CAP = 3600               -- nobody is kept from other work by it longer than this, whatever became of the leader
local REWARD = 250             -- experience, when the attempt is made (the owner, 17 November)
local KILL_BONUS = 250         -- more, if she dies of it
local STIPEND = 100            -- credits with the job, in all (the board's usual pay for a job is part of it)
local LATER = 0.5              -- of each part, for anyone under the order after the first at one address (the owner, 18 November)
local MIN_RANK = 3             -- Fighters and up (Sympathizer, Member, Fighter, Lieutenant, Commander)
local FIGHTERS = { 7, 8 }      -- how many come (fewer when the reserve is short)
local RING_MIN, RING_MAX = 400, 1500 -- how far from the stand they come out
local LEVEL = 300              -- and how far above or below it
local APART = 260              -- never two of them closer together than this
local BESIDE = 90              -- (few such spots there: a second and a third man this far from one already chosen)
local SECTORS = 8              -- one from each of these directions first
local CHECKS = 300             -- spots looked at, at most
local NEAR_PLAYER = 250        -- never this near a player, seen or not
local FIGHT_MIN, FIGHT_MAX = 40, 90 -- seconds they fight: at least, and at most
local LEAVE_MAX = 180          -- a fighter still watched this long after breaking off goes anyway
local REACH = 2500             -- the Combine this near the stand are theirs to fight
local HOLD = 3600              -- (the city leaves a fighter of the attack alone this long at most: the "event" state)
local UP = Vector(0, 0, 50)
local TAKEN = { detained = true, escorted = true, jailed = true }

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCost = CreateConVar("lc_resistance_order_cost", "300", FLAGS, "Credits for each member the Resistance's leader sends for to kill the Administrator: out of the Resistance's fund, else the leader's own (0: free)")

local P       -- the attack under way, or nil
local state = setmetatable({}, { __mode = "k" })   -- [player] = "word", "order" or false: what is kept with the character, once read
local words = setmetatable({}, { __mode = "k" })   -- [player sent for] = { leader, since, q (their job), tries }
local leaving = setmetatable({}, { __mode = "k" }) -- [player] = true from the moment they are going from the server
local lesser = setmetatable({}, { __mode = "k" })  -- [player paid for an attempt after the first] = the part they had (her death pays them that part too)
local nextWatch = 0 -- when everyone sent for is looked at next
local led     -- whether anyone who may give the order was playing, when last looked (the job on the board follows it)
local TEMPLATE

function LC.AdminPlot() return P end

local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function RankIndex(p) return p:GetNW2Int("lcf_rank", 1) end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or p:Nick() end
local function Ours(p) return IsValid(p) and p:IsPlayer() and not leaving[p] and Faction(p) == "resistance" end
local function Administrator(p) return LC.IsAdministrator ~= nil and LC.IsAdministrator(p) == true end
local function Exit() return LC.AdminExfil and LC.AdminExfil() or nil end
local function Living(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return e:Alive() end
    return e:Health() > 0
end

-- Her, while her address is on (from the call until it ends): a player Administrator, or the city's own at the
-- stand. And the address.
local function AtAddress()
    local S = LC.SpeechSession and LC.SpeechSession()
    if not S then return nil end
    local her = (IsValid(S.by) and S.by) or (IsValid(S.her) and S.her) or nil
    if not her or (her:IsPlayer() and not her:Alive()) then return nil end
    return her, S
end

-- Her address is on, and nobody has tried yet: the job is on the board (while nobody leads).
function LC.AdminPlotOpen()
    local her, S = AtAddress()
    return her ~= nil and not S.plotted and Exit() == nil
end

------------------------------------------------------------------------
-- Who leads, and who is under orders
------------------------------------------------------------------------

local function Fighter(p) return Ours(p) and RankIndex(p) >= MIN_RANK end

-- May they give the order? A Commander; a Lieutenant when no Commander is playing (the owner, 18 November:
-- "Commanders, else Lieutenants").
function LC.AdminPlotLeader(ply)
    if not Ours(ply) then return false end
    local r = RankIndex(ply)
    if r >= LEADER then return true end
    if r < DEPUTY then return false end
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and Ours(p) and RankIndex(p) >= LEADER then return false end
    end
    return true
end
-- Is anyone playing who may give it? Then the job is not on the board: the order comes from them alone.
function LC.AdminPlotLeading()
    for _, p in ipairs(player.GetAll()) do
        if Ours(p) and RankIndex(p) >= DEPUTY then return true end
    end
    return false
end
-- A leader for this member to speak with: someone else who may give the order and is playing now.
local function Leads(l, member) return l ~= member and LC.AdminPlotLeader(l) end
local function LeaderFor(member)
    for _, p in ipairs(player.GetAll()) do
        if Leads(p, member) then return p end
    end
    return nil
end

local function JobOf(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    if q and not q.done and q.tmpl == TEMPLATE then return q end
    return nil
end
-- What is kept with the character: "word" (sent for by a leader, and not spoken with yet), "order" (under the
-- order) or false. Theirs only as a Fighter or higher of the Resistance.
local function Has(ply)
    if not Fighter(ply) then return false end
    local has = state[ply]
    if has == nil then
        local kept = ply.GetPData and ply:GetPData(ORDER_KEY, "") or ""
        has = (kept == "1" and "order") or (kept == "word" and "word") or false
        state[ply] = has
    end
    return has
end
-- "job", "order" or nil: what makes an attempt of theirs an ordered one. (Sent for and not spoken with yet: nil.)
function LC.AdminPlotHolds(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return nil end
    if JobOf(ply) then return "job" end
    if Has(ply) == "order" then return "order" end
    return nil
end
-- Sent for, and not spoken with yet: the leader they are to speak with (true while nobody is named yet), or nil.
function LC.AdminPlotSentFor(ply)
    if not (IsValid(ply) and ply:IsPlayer()) or Has(ply) ~= "word" then return nil end
    local rec = words[ply]
    return rec and rec.leader or true
end

------------------------------------------------------------------------
-- Sent for: the job to speak with the leader (the owner, 18 November)
------------------------------------------------------------------------

-- The record (what is kept with the character) is what counts; the job is how the member sees it, and what
-- keeps other work shut. Never on a board (it is not among the templates), no time limit, nothing paid, and not
-- theirs to drop (kept: LC.DropQuest).
local WORD = { id = "res_word", factions = { resistance = true }, kept = true }

-- Its title, its one line and its marker are the leader's.
local function Point(q, l)
    local st = q.stages and q.stages[1]
    if not st or st.npc == l then return end
    st.npc = l
    q.title = string.format(JOB_TITLE, Name(l))
    st.text = string.format(JOB_LINE, Name(l))
end

-- The job is taken out of the quest system without a word; by hand if that fails, so it is never left on them.
local function Withdraw(q)
    if not istable(q) then return end
    if LC.WithdrawQuest then LC.Try(LC.WithdrawQuest, q) end
    q.done = true
    if LC.ActiveQuests then LC.ActiveQuests[q] = nil end
    for p, held in pairs(LC.QuestOf or {}) do
        if held == q then
            LC.QuestOf[p] = nil
            if IsValid(p) and LC.SendQuestState then LC.Try(LC.SendQuestState, p) end
        end
    end
end
-- Whatever of the job they have, gone.
local function Unjob(ply, rec)
    local q = LC.QuestOf and LC.QuestOf[ply]
    if istable(q) and q.tmpl == WORD then Withdraw(q) end
    if rec and istable(rec.q) and rec.q ~= q and not rec.q.done then Withdraw(rec.q) end
end

-- The price of sending for one member (the owner, 18 November): lc_resistance_order_cost credits, 0 for free.
function LC.AdminPlotCost() return math.max(0, math.floor(cvCost:GetFloat())) end

-- Charged at the moment they are sent for: out of the Resistance's fund when it holds enough, else out of the
-- leader's own credits. What is kept with the order (where it came from), "" when it costs nothing, or nil:
-- neither can pay. Nothing is said.
local function Charge(leader)
    local cost = LC.AdminPlotCost()
    if cost <= 0 then return "" end
    if LC.ResistanceFundTake and LC.ResistanceFundTake(cost, "the leader's order") then return cost .. ":fund" end
    if LC.Credits and LC.AddCredits and LC.Credits(leader) >= cost then
        LC.AddCredits(leader, -cost)
        return string.format("%d:%s:%s", cost, tostring(leader:SteamID64() or ""), leader:GetNW2String("lc_cid", ""))
    end
    return nil
end
-- The order ended before the attempt: the price goes back where it came from. The fund; or the leader who paid it
-- out of their own credits, if they are still that person, of the Resistance and playing; else the fund.
local function Refund(ply)
    if not ply.GetPData then return end
    local kept = ply:GetPData(PRICE_KEY, "") or ""
    if kept == "" then return end
    ply:RemovePData(PRICE_KEY)
    local n, rest = string.match(kept, "^(%d+):(.*)$")
    n = tonumber(n) or 0
    if n <= 0 then return end
    local from, cid = string.match(rest, "^(.*):([^:]*)$") -- (who paid, and as whom; nil when it was the fund)
    if rest ~= "fund" and from and LC.AddCredits then
        for _, p in ipairs(player.GetAll()) do
            if Ours(p) and tostring(p:SteamID64() or "") == from and p:GetNW2String("lc_cid", "") == cid then
                LC.AddCredits(p, n)
                return
            end
        end
    end
    if LC.ResistanceFundAdd then LC.ResistanceFundAdd(n, "an order ended before the attempt") end
end
-- The attempt is made: the price is spent for good.
local function Spend(ply)
    if IsValid(ply) and ply.RemovePData then ply:RemovePData(PRICE_KEY) end
end

-- Free of it altogether, the record and the job: taken back, or no longer theirs. What was paid for it goes back
-- where it came from. Nothing is said.
local function Free(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    Refund(ply)
    local rec = words[ply]
    words[ply] = nil
    state[ply] = false
    if ply.RemovePData then ply:RemovePData(ORDER_KEY) end
    Unjob(ply, rec)
end

-- They have spoken (E on the leader, the leader's E on them, or the leader's list): the job is done and the order
-- is theirs. Nothing is said: the job leaves their screen with the sound a finished job makes.
local function Spoken(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return false end
    local rec = words[ply]
    words[ply] = nil
    state[ply] = "order"
    if ply.SetPData then ply:SetPData(ORDER_KEY, "1") end
    Unjob(ply, rec)
    if ply.EmitSound then ply:EmitSound("buttons/bell1.wav", 60) end
    return true
end

-- Put in the job, or back in it. The job; or nil, and true when that is no failure: they hold another job, and
-- this one waits for it to end.
local function Enrol(ply, rec)
    local held = LC.QuestOf and LC.QuestOf[ply]
    if istable(held) and held.done then -- (a finished job still on them is nobody's: off)
        LC.QuestOf[ply] = nil
        held = nil
    end
    if istable(held) and held.tmpl == WORD then
        Point(held, rec.leader)
        return held
    end
    if held then return nil, true end
    if not LC.GiveQuest then return nil end
    local l = rec.leader
    return LC.GiveQuest(ply, {
        tmpl = WORD, title = string.format(JOB_TITLE, Name(l)), reward = 0, limit = false,
        -- (one step, and an act: E on the leader, the leader's E on them, or the leader's list. Never a place to
        -- stand, and nothing about who else is near: "in private" is theirs to see to.)
        stages = { { kind = "count", event = "plot_word", need = 1, untallied = true, text = string.format(JOB_LINE, Name(l)), npc = l } },
    })
end

-- One of those sent for, looked at: the record and the job must agree.
local function Watch1(ply, now)
    if leaving[ply] then return end
    if state[ply] and not Fighter(ply) then return Free(ply) end -- (neither a Fighter nor of the Resistance any more)
    if Has(ply) ~= "word" then
        words[ply] = nil
        return
    end
    local rec = words[ply]
    if not rec then -- (back from what is kept with the character: a reconnect, the server started again)
        rec = { since = now, tries = 0 }
        words[ply] = rec
    end
    -- the leader has gone, or leads no more: whoever leads now; nobody: free
    if not Leads(rec.leader, ply) then
        local l = LeaderFor(ply)
        if not l then return Free(ply) end
        rec.leader = l
    end
    -- nobody is kept from other work longer than this, whatever became of the leader
    if now - rec.since > CAP then return Free(ply) end
    local q, waits = Enrol(ply, rec)
    if q then
        rec.q, rec.tries = q, 0
        if LC.SendQuestState then LC.SendQuestState(ply) end -- (the marker follows the leader)
    elseif waits then
        rec.q = nil
    else
        -- the quest system would not take it: once more at the next look, then free
        rec.q = nil
        rec.tries = (rec.tries or 0) + 1
        if rec.tries >= 2 then return Free(ply) end
    end
end

-- Everyone sent for, looked at: every couple of seconds, and at once when something happens to a member or a
-- leader. An error frees whoever it was about, and is written down: nobody is left locked.
function LC.AdminPlotWatch(now)
    now = now or CurTime()
    for _, p in ipairs(player.GetAll()) do
        local okW, err = LC.Try(Watch1, p, now)
        if not okW then
            if LC.Error then LC.Error("a leader's summons", err) end
            if not LC.Try(Free, p) then state[p], words[p] = false, nil end
        end
    end
    -- a job with no record behind it: ended
    for q in pairs(LC.ActiveQuests or {}) do
        if q.tmpl == WORD and not q.done then
            local p = q.owner
            local rec = IsValid(p) and words[p] or nil
            if not (rec and state[p] == "word" and rec.q == q) then LC.Try(Withdraw, q) end
        end
    end
end
local function Look() LC.Try(LC.AdminPlotWatch) end

-- No other work until that word is had (the owner, 18 November: "it should need to be fulfilled before being
-- able to take any other job/quest/work"). What every door that work comes through says instead, or nil. By the
-- record, not the job: a job the quest system has lost shuts the doors all the same until it is put back.
function LC.AdminPlotBusy(ply)
    if not (IsValid(ply) and ply:IsPlayer()) or Has(ply) ~= "word" then return nil end
    local rec = words[ply]
    if not (rec and Leads(rec.leader, ply)) then
        -- (nobody named to speak with at this moment: looked into now, so no door is shut on nobody's account)
        if not LC.Try(Watch1, ply, CurTime()) then LC.Try(Free, ply) end
        rec = words[ply]
        if Has(ply) ~= "word" or not (rec and Leads(rec.leader, ply)) then return nil end
    end
    return string.format(BUSY, Name(rec.leader))
end

-- Pressing E at each other, within reach: the member at the leader, or the leader at the member.
local function At(a, b)
    if not (IsValid(a) and IsValid(b)) or a == b or not a:Alive() or not b:Alive() then return false end
    local to = b:GetPos() - a:GetPos()
    if to:LengthSqr() > WITHIN * WITHIN then return false end
    local tr = a:GetEyeTrace()
    if tr and tr.Entity == b then return true end
    -- (not looking straight at them: roughly their way will do)
    local aim = a:GetAimVector()
    local flat, way = Vector(to.x, to.y, 0), Vector(aim.x, aim.y, 0)
    if flat:LengthSqr() < 1 or way:LengthSqr() < 0.01 then return true end
    flat:Normalize()
    way:Normalize()
    return flat:Dot(way) >= 0.6
end
local function Pressed(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    local rec = words[ply]
    if rec and Has(ply) == "word" and Leads(rec.leader, ply) and At(ply, rec.leader) then
        Spoken(ply)
        return
    end
    for member, r in pairs(words) do
        if r.leader == ply and IsValid(member) and Has(member) == "word" and LC.AdminPlotLeader(ply) and At(ply, member) then
            Spoken(member)
            return
        end
    end
end
hook.Add("KeyPress", "LivingCityAdminPlot", function(ply, key)
    if key ~= IN_USE or next(words) == nil then return end
    local okP, err = LC.Try(Pressed, ply)
    if not okP and LC.Error then LC.Error("a word with the leader", err) end
end)

------------------------------------------------------------------------
-- The leader's list
------------------------------------------------------------------------

-- F2 > Resistance > Order: kill the Administrator: the Resistance's players who are Fighters or higher, the leader
-- among them, and what each has ("word": sent for; "order"). Nil for anyone who may not give it.
function LC.AdminPlotList(leader)
    if not LC.AdminPlotLeader(leader) then return nil end
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if Fighter(p) then
            out[#out + 1] = { id = p:EntIndex(), name = Name(p), has = Has(p) or nil }
        end
    end
    table.sort(out, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    return out
end

-- The leader picks a name that has nothing: that member is sent for. They read one line, alone, that says who and
-- not what about, and are put in the job to speak with the leader; the order is theirs once they have. Nothing is
-- said to anyone else or on the radio. A leader who picks themselves has the order at once, and reads nothing.
-- True: sent for. False: nothing new (sent for or under the order already). False and a line: neither the
-- Resistance's fund nor the leader can pay for it (the one thing a leader is ever told). Nil: not theirs to give,
-- or not someone it can be given to (nothing is said of that either).
function LC.AdminPlotAssign(leader, member)
    if not LC.AdminPlotLeader(leader) or not Fighter(member) then return nil end
    if Has(member) then return false end
    -- the price, a leader's own order too: the fund's when it holds enough, else the leader's, else nobody is sent for
    local paid = Charge(leader)
    if not paid then return false, string.format(SHORT, LC.AdminPlotCost()) end
    if paid ~= "" then member:SetPData(PRICE_KEY, paid) else member:RemovePData(PRICE_KEY) end
    if member == leader then
        state[member] = "order"
        if member.SetPData then member:SetPData(ORDER_KEY, "1") end
        return true
    end
    local rec = { leader = leader, since = CurTime(), tries = 0 }
    state[member] = "word"
    if member.SetPData then member:SetPData(ORDER_KEY, "word") end
    words[member] = rec
    member:ChatPrint(string.format(WORD_LINE, Name(leader)))
    local okE, q, waits = LC.Try(Enrol, member, rec)
    if okE and q then
        rec.q = q
    elseif not (okE and waits) then
        rec.tries = 1 -- (the quest system would not take it: the watch tries once more, then frees them)
    end
    return true
end
-- The leader marks someone sent for as spoken with (their name on the list again). True: the order is theirs now.
-- False: they were not waiting on a word. Nil: not a leader's to say.
function LC.AdminPlotSpoken(leader, member)
    if not LC.AdminPlotLeader(leader) or not (IsValid(member) and member:IsPlayer()) then return nil end
    if Has(member) ~= "word" then return false end
    return Spoken(member)
end
-- The leader takes it back, whatever they had of it (their name on the list once more). It always works: by the
-- record, whatever has become of the job. Nothing is said. Nil: not a leader's to take.
function LC.AdminPlotTakeBack(leader, member)
    if not LC.AdminPlotLeader(leader) or not (IsValid(member) and member:IsPlayer()) then return nil end
    Free(member)
    return true
end
-- The name picked on F2, as its number on the list and what the list showed of them: "give" (nothing), "spoken"
-- (sent for) or "back" (under the order). A list out of date does no harm: each does only what it says
-- (sv_livingcity_quickmore.lua). True when it was theirs to pick; false and a line when the price cannot be paid.
function LC.AdminPlotPick(leader, arg)
    local id, what = string.match(tostring(arg or ""), "^(%d+):(%a+)$")
    id = tonumber(id)
    if not id then return false end
    for _, p in ipairs(player.GetAll()) do
        if p:EntIndex() == id then
            if what == "give" then
                local sent, short = LC.AdminPlotAssign(leader, p)
                if sent == false and short then return false, short end
                return sent ~= nil
            end
            if what == "spoken" then return LC.AdminPlotSpoken(leader, p) ~= nil end
            if what == "back" then return LC.AdminPlotTakeBack(leader, p) ~= nil end
            return false
        end
    end
    return false
end

-- No longer theirs: someone new, in a cell, out of the Resistance, or below a Fighter. And whatever happens to a
-- leader (gone from the server, dead for good, out of the Resistance, a leader no more) is looked into at once:
-- those sent for by them speak with whoever leads now, or are free.
local function Off(ply)
    if not LC.Try(Free, ply) and IsValid(ply) then state[ply], words[ply] = false, nil end
end
hook.Add("LivingCityNewCharacter", "LivingCityAdminPlot", function(ply)
    Off(ply)
    Look()
end)
hook.Add("LivingCityIncarcerated", "LivingCityAdminPlot", function(ply) Off(ply) end)
hook.Add("LivingCityFactionChanged", "LivingCityAdminPlot", function(ply, fid)
    if fid ~= "resistance" then Off(ply) end
    Look()
end)
hook.Add("LivingCityRankChanged", "LivingCityAdminPlot", function(ply, fid, rank)
    if fid == "resistance" and (tonumber(rank) or 1) < MIN_RANK then Off(ply) end
    Look()
end)
-- Gone from the server: what is kept with their character stays (they come back still sent for, or still under
-- the order); as a leader they lead nobody from this moment.
hook.Add("PlayerDisconnected", "LivingCityAdminPlot", function(ply)
    if not IsValid(ply) then return end
    leaving[ply] = true
    words[ply], state[ply] = nil, nil
    Look()
end)
hook.Add("PlayerInitialSpawn", "LivingCityAdminPlot", function(ply) leaving[ply] = nil end)
-- A job of theirs is over: someone sent for while they held it is put in this one now.
local function Next(ply)
    if not (IsValid(ply) and state[ply] == "word") then return end
    timer.Simple(0, Look)
end
hook.Add("LivingCityQuestFailed", "LivingCityAdminPlot", function(ply) Next(ply) end)

------------------------------------------------------------------------
-- The job, on the Resistance's board
------------------------------------------------------------------------

TEMPLATE = {
    id = JOB, factions = { resistance = true }, first = true, recheck = true,
    -- (only while nobody leads: with a Commander or a Lieutenant playing, the order comes from them alone)
    available = function(ply) return LC.AdminPlotOpen() and not LC.AdminPlotLeading() and (not IsValid(ply) or RankIndex(ply) >= MIN_RANK) end,
    -- (not on the board of anyone below a Fighter, nor of anyone while someone leads; whoever holds it keeps it)
    sees = function(ply) return IsValid(ply) and RankIndex(ply) >= MIN_RANK and (JobOf(ply) ~= nil or not LC.AdminPlotLeading()) end,
    solo = true, -- (one holder at a time: the owner, 18 November, "maybe only one can at a time")
    -- (her address over, and nobody getting her out: there is nothing left to try. No reason in words: it shows.)
    over = function()
        if not AtAddress() and not Exit() then return false end
    end,
    build = function()
        local her, S = AtAddress()
        if not her then return nil end
        return {
            title = TITLE, reward = REWARD, limit = 600, failOnArrest = true, desc = LINE,
            -- (one step, and not a place to stand: the attempt itself. The marker is the stand.)
            stages = { { kind = "count", event = "admin_attempt", need = 1, untallied = true, text = LINE, pos = S.stand.pos } },
        }
    end,
}
if LC.QuestTemplates then
    for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == JOB then table.remove(LC.QuestTemplates, i) end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = TEMPLATE
end
-- On the board from the moment the city is called, whatever else is on it. Nobody is told in words: the call
-- to her address is heard by everyone.
hook.Add("LivingCitySpeechCalled", "LivingCityAdminPlot", function()
    if LC.PostDirective then LC.Try(LC.PostDirective, JOB, nil, true) end
end)
-- A job nobody took comes off the board.
local function Unpost()
    for _, p in ipairs(LC.Postings and LC.Postings.resistance or {}) do
        if p.tmpl == TEMPLATE and not p.q then p.dead = true end
    end
end
-- Her address is over (or her guards have begun: then it is the same address still, and whoever tries from here
-- on is not the first at it).
hook.Add("LivingCitySpeechEnded", "LivingCityAdminPlot", function(S)
    Unpost()
    local A = Exit()
    if istable(S) and S.plotPaid and A then A.plotPaid = true end
end)
-- Leaders come and go (they join, leave, are promoted): with one playing the job nobody took comes off the
-- board, and with none left it is back while her address is on. Nobody is told either way.
local function Board()
    local now = LC.AdminPlotLeading()
    if now == led then return end
    led = now
    if now then
        Unpost()
    elseif LC.AdminPlotOpen() and LC.PostDirective then
        LC.Try(LC.PostDirective, JOB, nil, true)
    end
end

------------------------------------------------------------------------
-- Where they come out
------------------------------------------------------------------------

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Nobody can see it at this moment, nobody is standing by it, and a person fits there and can walk to the stand.
local function Hidden(p, centre)
    if LC.FarFromPlayers and not LC.FarFromPlayers(p, NEAR_PLAYER) then return false end
    if LC.IsSeen and (LC.IsSeen(p + UP) or LC.IsSeen(p + Vector(0, 0, 12))) then return false end
    if LC.InNoGo and LC.InNoGo(p, "rebel") then return false end
    if LC.DestIsBad and LC.DestIsBad(p) then return false end
    if LC.ClearSpot and not LC.ClearSpot(p) then return false end
    if LC.NavReachable and not LC.NavReachable(p, centre) then return false end
    return true
end

-- Up to `want` spots round `centre`: the city's doorways (where its people come out) and its own walking
-- spots, between RING_MIN and RING_MAX of it and about on its level. One from each of eight directions first,
-- then round again, and never two within APART of each other: all round, not in one clump. Where the place has
-- too few of those (one doorway, a path with few points), a second and then a third man comes out beside one
-- already chosen, a step away and as unseen as he is: never more than three at one spot. Fewer than asked when
-- there is no more room nobody can see.
function LC.AdminPlotSpots(centre, want)
    local bySector, taken, n = {}, {}, 0
    local function add(p)
        if not p then return end
        local dx, dy = p.x - centre.x, p.y - centre.y
        local d2 = dx * dx + dy * dy
        if d2 < RING_MIN * RING_MIN or d2 > RING_MAX * RING_MAX or math.abs(p.z - centre.z) > LEVEL then return end
        local key = math.floor(p.x / 48) .. ":" .. math.floor(p.y / 48) .. ":" .. math.floor(p.z / 48)
        if taken[key] then return end
        taken[key] = true
        local s = math.floor((math.atan2(dy, dx) + math.pi) / (2 * math.pi) * SECTORS) % SECTORS
        bySector[s] = bySector[s] or {}
        bySector[s][#bySector[s] + 1] = p
        n = n + 1
    end
    for _, pt in ipairs(LC.PointsOfKind and LC.PointsOfKind("spawn") or {}) do add(pt.pos) end
    for _, p in ipairs(LC.NodePositions and LC.NodePositions("rebel") or {}) do add(p) end
    for _, p in ipairs(LC.Fallback or {}) do add(p) end
    local sectors = {}
    for s, list in pairs(bySector) do
        Shuffle(list)
        sectors[#sectors + 1] = s
    end
    table.sort(sectors)
    Shuffle(sectors)
    local out, checks, more = {}, 0, n > 0
    while #out < want and more and checks < CHECKS do
        more = false
        for _, s in ipairs(sectors) do
            if #out >= want or checks >= CHECKS then break end
            local list = bySector[s]
            while #list > 0 and checks < CHECKS do
                local p = table.remove(list)
                local apart = true
                for _, o in ipairs(out) do if o:DistToSqr(p) < APART * APART then apart = false break end end
                if apart then
                    checks = checks + 1
                    if Hidden(p, centre) then
                        out[#out + 1] = p
                        more = true
                        break
                    end
                end
            end
        end
    end
    -- still short: beside the ones chosen, once round and then once more
    local first = #out
    for ring = 1, 2 do
        for i = 1, first do
            if #out >= want or checks >= CHECKS then break end
            local a = math.random() * math.pi * 2
            for k = 0, 3 do
                local q = out[i] + Vector(math.cos(a + k * math.pi / 2), math.sin(a + k * math.pi / 2), 0) * (BESIDE * ring)
                local free = true
                for _, o in ipairs(out) do if o:DistToSqr(q) < (BESIDE * 0.9) ^ 2 then free = false break end end
                if free and checks < CHECKS then
                    checks = checks + 1
                    if Hidden(q, centre) then
                        out[#out + 1] = q
                        break
                    end
                end
            end
        end
    end
    return out
end

------------------------------------------------------------------------
-- The fighters
------------------------------------------------------------------------

-- Whom a fighter of the attack never hurts: citizens, the Resistance, anyone who is not the Combine's.
local function Spared(ent)
    if ent:IsPlayer() then
        return not ((LC.PlayerIsCP and LC.PlayerIsCP(ent)) or Administrator(ent) or (LC.PlayerIsZombie and LC.PlayerIsZombie(ent)))
    end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and (st.role == "citizen" or st.role == "rebel")
end
LC.AdminPlotSpares = Spared

-- The Combine within reach of the stand: her guards, the city's units, the Combine's players. Never her.
local function Foes(at, her)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc ~= her and npc:Health() > 0 and not st.test and LC.IsSecurity(st)
            and npc:GetPos():DistToSqr(at) < REACH * REACH then
            out[#out + 1] = npc
        end
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= her and ply:Alive() and not Administrator(ply) and LC.RebelLooksCombine and LC.RebelLooksCombine(ply)
            and ply:GetPos():DistToSqr(at) < REACH * REACH then
            out[#out + 1] = ply
        end
    end
    return out
end

local function Sees(npc, e)
    if LC.RebelCanSee then return LC.RebelCanSee(npc, e, REACH) end
    return npc:GetPos():DistToSqr(e:GetPos()) < REACH * REACH
end

-- The nearest of them (sighted: the nearest he can see).
local function Nearest(npc, foes, sighted)
    local pos, best, bd = npc:GetPos(), nil, nil
    for _, e in ipairs(foes) do
        if Living(e) then
            local d = e:GetPos():DistToSqr(pos)
            if (not bd or d < bd) and (not sighted or Sees(npc, e)) then best, bd = e, d end
        end
    end
    return best
end

-- Whom he is fighting. A fighter of the attack is never without a foe as the rest of the city's code sees it:
-- one of the city's own fighters with none, hit by a unit, turns on it and has it sent after him
-- (sv_livingcity_rebels.lua), and her guards are hers to move. With nobody to fight his foe is himself:
-- nobody's enemy.
local function FoeOf(npc, st)
    local e = st.foe
    if e == npc then return nil end
    return e
end

-- Back to neutral with whoever he was fighting.
local function Drop(npc, st)
    local e = FoeOf(npc, st)
    st.foe = npc
    if IsValid(e) then
        if e:IsPlayer() then
            if LC.SetRel and LC.RebelDisposition then
                LC.SetRel(npc, st, e, LC.RebelDisposition(npc, st, e, LC.PlayerIsZombie and LC.PlayerIsZombie(e)))
            end
        else
            npc:AddEntityRelationship(e, D_NU, 99)
        end
    end
    npc:SetEnemy(NULL)
    if npc.ClearEnemyMemory then npc:ClearEnemyMemory() end
end

-- One of the Combine is his to fight: the fighter hates him, and a unit hates him back, as with any fighter
-- who shoots at one (LC.UnitHatesRebel, sv_livingcity_rebels.lua). Nobody is made to walk anywhere by it:
-- her guards are hers to move.
local function Engage(npc, st, e, now)
    if FoeOf(npc, st) then Drop(npc, st) end
    st.foe, st.foeSince, st.goingTo = e, now, nil
    if e:IsPlayer() then
        if LC.SetRel then LC.SetRel(npc, st, e, D_HT) end
    else
        npc:AddEntityRelationship(e, D_HT, 99)
        local est = LC.NPCs and LC.NPCs[e]
        if est and LC.UnitHatesRebel then LC.UnitHatesRebel(e, est, npc, now) end
    end
end

-- He keeps at him: in sight he shoots; out of sight he runs to where he is.
local function Press(npc, st, e, now)
    if npc:GetEnemy() ~= e then npc:SetEnemy(e) end
    if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(e, e:GetPos()) end
    if not Sees(npc, e) then
        if now - (st.lastChase or 0) > 3 then
            st.lastChase = now
            npc:SetLastPosition(e:GetPos())
            npc:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    elseif npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
        npc:SetSchedule(SCHED_CHASE_ENEMY) -- (a walking schedule ignores enemies)
    end
end

local function Run(npc, st, to)
    if LC.RebelHeadFor then return LC.RebelHeadFor(npc, st, to, true) end
    npc:SetLastPosition(to)
    npc:SetSchedule(SCHED_FORCED_GO_RUN)
end

local function Fight(alive, now)
    local foes = Foes(P.at, P.her)
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        local e = FoeOf(npc, st)
        if e and not (Living(e) and e:GetPos():DistToSqr(P.at) < REACH * REACH) then
            Drop(npc, st)
            e = nil
        end
        -- (nobody yet, or the one he has is out of sight: someone he can see, now and then)
        if now >= (st.plotLook or 0) and (not e or not Sees(npc, e)) then
            st.plotLook = now + 2
            local seen = Nearest(npc, foes, true)
            if seen and seen ~= e then
                Engage(npc, st, seen, now)
                e = seen
            end
        end
        if e then
            Press(npc, st, e, now)
        else
            -- nobody in sight: toward the nearest of them, or where she stood
            local near = Nearest(npc, foes, false)
            local to = near and near:GetPos() or P.at
            if npc:GetPos():DistToSqr(to) > 300 * 300 then Run(npc, st, to) end
        end
    end
end

local function BreakOff(alive, now)
    P.phase, P.leftAt = "leave", now
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        Drop(npc, st)
        st.goingTo, st.plotOut = nil, nil
    end
    if LC.Log then LC.Log("info", string.format("The attack at the Administrator's address breaks off: %d of %d fighters left", #alive, P.came)) end
end

local function Leave(alive, now)
    for _, npc in ipairs(alive) do
        local st = LC.NPCs[npc]
        local pos = npc:GetPos()
        local since = now - P.leftAt
        if since >= 2 and (since > LEAVE_MAX or not (LC.IsSeen and LC.IsSeen(pos + UP))) then
            LC.AdminTargets[npc] = nil
            npc:Remove() -- (alive: back in the Resistance's reserve, sv_livingcity_manpower.lua)
        else
            -- back the way he came; watched there too, on to somewhere nobody is looking
            local to = st.plotOut
            if not to then
                to = st.plotFrom
            elseif pos:DistToSqr(to) < 120 * 120 and now >= (st.plotOutAt or 0) then
                to = (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos)) or st.plotFrom
            end
            if to ~= st.plotOut then st.plotOut, st.plotOutAt, st.goingTo = to, now + 3, nil end
            if to then Run(npc, st, to) end
        end
    end
end

-- She is no longer at her address, and nobody is getting her out.
local function Gone()
    if Exit() then return false end
    local her = AtAddress()
    return her == nil or her ~= P.her
end

-- The fighters come. How many (0: nobody to send, or nowhere to come from unseen).
function LC.AdminPlotStart(her, who)
    if P or LC.Running == false or not LC.SpawnRebel or not IsValid(her) then return 0 end
    local now = CurTime()
    local want = math.random(FIGHTERS[1], FIGHTERS[2])
    if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
        want = math.min(want, math.floor(LC.ManpowerPool("rebel").reserve))
    end
    if want <= 0 then return 0 end -- (the reserve is spent: the assassin is on their own)
    local centre = her:GetPos()
    local spots = LC.AdminPlotSpots(centre, want)
    local plot = { her = her, by = who, at = centre, t0 = now, fighters = {}, phase = "fight", came = 0 }
    for _, pos in ipairs(spots) do
        local okS, npc, st = LC.Try(LC.SpawnRebel, pos + Vector(0, 0, 4))
        if okS and IsValid(npc) and st then
            -- (on top of the city's own numbers, and nobody else's to move, lead or send home meanwhile)
            st.unmanaged, st.questLock, st.zone, st.leaveAt = true, true, nil, nil
            st.plotFrom = pos
            st.foe = npc -- (nobody yet: FoeOf)
            st.eventUntil = now + HOLD
            LC.SetState(npc, st, "event")
            npc.lcAdminPlot = true
            LC.AdminTargets[npc] = true -- (her guards may hurt him)
            npc:SetAngles(Angle(0, math.deg(math.atan2(centre.y - pos.y, centre.x - pos.x)), 0))
            plot.fighters[#plot.fighters + 1] = npc
        end
    end
    plot.came = #plot.fighters
    if plot.came == 0 then return 0 end
    P = plot
    if LC.Log then
        LC.Log("info", string.format("An ordered attempt on the Administrator by %s: %d Resistance fighters come out round the stand",
            IsValid(who) and who:IsPlayer() and who:Nick() or "?", plot.came))
    end
    return plot.came
end

-- It is over at once: whoever is left is taken out of the city where they stand (the city stopped; tests).
function LC.AdminPlotEnd()
    local plot = P
    P = nil
    if not plot then return end
    for _, npc in ipairs(plot.fighters) do
        if IsValid(npc) then
            LC.AdminTargets[npc] = nil
            npc:Remove()
        end
    end
end

------------------------------------------------------------------------
-- The attempt
------------------------------------------------------------------------

-- Someone tried to kill her at her address. Under orders: the fighters come, and the job and the order are
-- done and paid: the first at this address in full, anyone under the leader's order after them a part (the owner,
-- 18 November: "Only the first should be paid that high, the rest maybe 1/2 or less"). Anyone else: nothing. True
-- when it was an ordered one.
function LC.AdminPlotAttempt(her, who, killed)
    if not (IsValid(who) and who:IsPlayer()) or not IsValid(her) then return false end
    local q, own = JobOf(who), Has(who) == "order"
    if not q and not own then return false end
    -- once for an address, and once for an exit
    local _, S = AtAddress()
    local A = Exit()
    local again = (S and S.plotted) or (A and A.plotted)
    local part = ((S and S.plotPaid) or (A and A.plotPaid)) and LATER or 1 -- (someone under orders was paid here already)
    if S then S.plotted, S.plotPaid = true, true end
    if A then A.plotted, A.plotPaid = true, true end
    if not again then
        local okS, err = LC.Try(LC.AdminPlotStart, her, who)
        if not okS and LC.Error then LC.Error("the attack at the Administrator's address", err) end
    end
    if q then
        if killed then q.bonus = (q.bonus or 0) + KILL_BONUS else LC.AdminPlotPaid[who] = CurTime() end
        LC.Try(LC.QuestEvent, "admin_attempt", who)
    end
    if own then
        -- (under a leader's order: whoever makes the attempt is paid what the job pays, the owner, 18 November: "yes it
        -- should pay the extra". Their order is done, and what was paid for it is spent; another member's stands.)
        Spend(who)
        Off(who)
        if not q then
            if LC.AddXP then LC.AddXP(who, math.floor(REWARD * part) + (killed and math.floor(KILL_BONUS * part) or 0), TITLE) end
            if LC.AddCredits then LC.AddCredits(who, math.floor(STIPEND * part), "paid quietly") end
            if not killed then
                LC.AdminPlotPaid[who] = CurTime()
                lesser[who] = part < 1 and part or nil
            end
        end
    end
    return true
end

-- The stipend: 100 credits in all for the job from the board (the order's is paid where the attempt is made; never a lone wolf). The board's
-- usual pay for a finished job (lc_directive_pay, sv_livingcity_economy.lua) is part of it, so this adds the rest.
hook.Add("LivingCityQuestComplete", "LivingCityAdminPlot", function(ply, q)
    Next(ply) -- (sent for while they held this job: put in that one now)
    if not (IsValid(ply) and q and q.tmpl == TEMPLATE and LC.AddCredits) then return end
    local eco, usual = GetConVar("lc_economy"), GetConVar("lc_directive_pay")
    local had = (not eco or eco:GetBool()) and usual and usual:GetInt() or 0
    if STIPEND - had > 0 then LC.AddCredits(ply, STIPEND - had, "paid quietly") end
end)

-- She died of it after all, later: hit with no close calls left she is taken out alive, and the roll in her office
-- went against her (the owner, 17 November; sv_livingcity_adminsecurity.lua says so here). Whoever was paid for the
-- job at that address in the last ten minutes gets what they would have had if she had died at the stand (anyone
-- paid a part for the attempt, that part of it). Nothing is said. How many were paid.
LC.AdminPlotPaid = LC.AdminPlotPaid or setmetatable({}, { __mode = "k" }) -- [holder] = when the job paid them
function LC.AdminPlotDied()
    local n, now = 0, CurTime()
    for who, at in pairs(LC.AdminPlotPaid) do
        LC.AdminPlotPaid[who] = nil
        local part = lesser[who] or 1
        lesser[who] = nil
        if IsValid(who) and who:IsPlayer() and now - at <= 600 and LC.AddXP then
            LC.AddXP(who, math.floor(KILL_BONUS * part), "Kill the Administrator")
            n = n + 1
        end
    end
    return n
end

-- At her address: her address is on and it is her, or her guards are getting her out.
local function Hers(her)
    if not IsValid(her) then return false end
    local A = Exit()
    if A and A.her == her then return true end
    local S = LC.SpeechSession and LC.SpeechSession()
    return S ~= nil and (S.by == her or S.her == her)
end

-- Her guards are getting her out: whoever set it off. (Most attempts come this way: a hit, a near miss.)
hook.Add("LivingCityAdminExfil", "LivingCityAdminPlot", function(her, who)
    LC.Try(LC.AdminPlotAttempt, her, who)
end)
-- A grenade by her (it may be heard before her guards have begun, or with them switched off).
hook.Add("LivingCityAdminAttempt", "LivingCityAdminPlot", function(her, who)
    if Hers(her) then LC.Try(LC.AdminPlotAttempt, her, who) end
end)
-- A hit she took at her address with her guards' exit switched off, or one she died of.
hook.Add("PostEntityTakeDamage", "LivingCityAdminPlot", function(ent, dmg, took)
    if not took or not IsValid(ent) or not Hers(ent) then return end
    local att = dmg:GetAttacker()
    if IsValid(att) and att:IsPlayer() and att ~= ent and LC.AdminPlotHolds(att) then
        LC.Try(LC.AdminPlotAttempt, ent, att, ent:IsPlayer() and not ent:Alive())
    end
end)
hook.Add("PlayerDeath", "LivingCityAdminPlot", function(victim, _, attacker)
    if not IsValid(victim) or not Hers(victim) then return end
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and LC.AdminPlotHolds(attacker) then
        LC.Try(LC.AdminPlotAttempt, victim, attacker, true)
    end
end)

-- A fighter of the attack never hurts a citizen or one of the Resistance, whatever his bullets find.
hook.Add("EntityTakeDamage", "LivingCityAdminPlot", function(ent, dmg)
    local att = dmg:GetAttacker()
    if IsValid(att) and att.lcAdminPlot and IsValid(ent) and Spared(ent) then return true end
end)

------------------------------------------------------------------------
-- Twice a second
------------------------------------------------------------------------

function LC.AdminPlotThink(now)
    now = now or CurTime()
    Board()
    -- everyone sent for or under the order, looked at: still theirs, and the job and the record agree
    if now >= nextWatch then
        nextWatch = now + WATCH
        LC.AdminPlotWatch(now)
    end
    -- someone under orders who joined in once her guards had begun (marked by them as an attacker): the first brings
    -- the fighters; anyone else under the leader's order who joins in after is paid their part, and their order is done
    local A = Exit()
    if A and P then A.plotted = true end -- (once for an exit, however it was set off)
    if A then
        for who in pairs(A.attackers or {}) do
            if IsValid(who) and who:IsPlayer() then
                if not A.plotted then
                    if LC.AdminPlotHolds(who) then LC.AdminPlotAttempt(A.her, who) end
                elseif Has(who) == "order" then
                    LC.AdminPlotAttempt(A.her, who)
                end
            end
        end
    end
    if not P then return end
    local alive = {}
    for i = #P.fighters, 1, -1 do
        local npc = P.fighters[i]
        local st = IsValid(npc) and npc:Health() > 0 and LC.NPCs[npc] or nil
        if not st then
            table.remove(P.fighters, i)
        elseif TAKEN[st.state] or st.jailUntil then
            -- cuffed or in a cell: the Combine's prisoner now, as any fighter taken alive
            table.remove(P.fighters, i)
            LC.AdminTargets[npc] = nil
            st.unmanaged, st.questLock, st.eventUntil = nil, nil, nil
            if st.foe == npc then st.foe = nil end
        else
            -- (still the attack's own, whatever else has tried to send him somewhere)
            st.eventUntil = now + HOLD
            if st.state ~= "event" then LC.SetState(npc, st, "event") end
            table.insert(alive, 1, npc)
        end
    end
    if #alive == 0 then
        P = nil
        return
    end
    if P.phase == "fight" then
        local t = now - P.t0
        if t >= FIGHT_MAX or (t >= FIGHT_MIN and Gone()) then BreakOff(alive, now) else Fight(alive, now) end
    end
    if P.phase == "leave" then Leave(alive, now) end
end

timer.Create("LivingCityAdminPlot", 0.5, 0, function()
    local okT, err = LC.Try(LC.AdminPlotThink, CurTime())
    if not okT and LC.Error then LC.Error("admin plot", err) end
end)

hook.Add("LivingCityStopped", "LivingCityAdminPlot", function() LC.AdminPlotEnd() end)
