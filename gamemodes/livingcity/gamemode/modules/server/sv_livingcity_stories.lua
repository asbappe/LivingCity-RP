--[[
    Living City: story chains

    Personal, multi-part stories that unlock from what you've actually done.
    They appear at the top of your board (F4) marked as Story, only for you.
    Choices in each part decide which part comes next, and how it ends.

      Internal Affairs        cops who take bribes get noticed
      The Pamphleteer         a kind citizen is approached by the Resistance
      The Informant           a loyal citizen is asked to watch a neighbor
      The Missing Unit        a unit goes dark; three different truths
      Father Grigori's Flock  a secret mass, and a traitor among the faithful
      The Overwatch Candidate the best units are offered something permanent

    Try any of them right away: lcq_startchain <id> (admin).
    Inspect someone's story: lcq_story <name>. Start over: lcq_resetstory <name>.
]]

if CLIENT then return end

LC = LC or {}
local Q = LC.QB
if not Q then return end

local Goto, Deliver, Hold, Count, Choice = Q.Goto, Q.Deliver, Q.Hold, Q.Count, Q.Choice
local Narrate, Insert, Pick, Place = Q.Narrate, Q.InsertStages, Q.Pick, Q.Place

local function Trait(p, name, d) LC.AddTrait(p, name, d) end
local function XP(p, n) if LC.AddXP then LC.AddXP(p, n) end end

-- A stage that places a story character in the world and has you walk up to them.
-- gender ("male" or "female") makes sure they look like the person the story describes.
local function Meet(text, role, posFn, hold, r, gender)
    return {
        kind = "target", action = "reach", r = r or 150, text = text,
        onEnter = function(q, st)
            local npc = Q.SpawnActor(q, role, posFn(q), hold or 600, nil, gender and { gender = gender } or nil)
            if not IsValid(npc) then return false end
            q.data.actor = npc
            st.npc = npc
        end,
    }
end

local function Patrol(ply, n, label)
    local stages = {}
    for i = 1, n do
        local sp = Q.Spot(ply, 500, 2500)
        if not sp then return nil end
        stages[i] = Goto(sp, string.format("%s %d of %d, %s", label or "Go to patrol stop", i, n, Place(sp, ply:GetPos())), 150)
    end
    return stages
end

local function Append(list, more) for _, s in ipairs(more) do list[#list + 1] = s end return list end

local function HomeOf(ply)
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    if n then
        for _, z in ipairs(LC.ZonesOfKind("block")) do
            if z.group == n then return z.pos, LC.BlockName(n) end
        end
    end
    local spawns = LC.PointsOfKind("spawn")
    if #spawns > 0 then
        local p = Pick(spawns).pos
        return p, Place(p, ply:GetPos())
    end
    local p = Q.Spot(ply, 300, 1500)
    return p, p and Place(p, ply:GetPos()) or "home"
end

local function JoinLater(ply, faction, minXP)
    timer.Simple(1.5, function()
        if not IsValid(ply) then return end
        if minXP then
            local key = "lcf_xp_" .. faction
            ply:SetPData(key, math.max(tonumber(ply:GetPData(key, 0)) or 0, minXP))
            -- (a story that makes someone a Fighter has proved them: the Resistance trusts them already)
            if faction == "resistance" and LC.ResistanceTrust and LC.Bump then
                local have, need = LC.ResistanceTrust(ply)
                if have < need then LC.Bump(ply, "res_jobs", need - have) end
            end
        end
        if faction == "resistance" and LC.ResistanceInvite then LC.ResistanceInvite(ply) end -- (invited in by the story: no sympathy needed)
        LC.SetFaction(ply, faction, nil)
    end)
end

------------------------------------------------------------------------
-- Internal Affairs
------------------------------------------------------------------------

local function TakeBribe(q, p)
    Trait(p, "corruption", 1)
    LC.Bump(p, "bribes")
    q.reward = 0
    q.chainEnd = "busted"
    Narrate(q, "A camera flashes in the window across the street. Internal Affairs was watching the whole time, and saw you take the bribe.")
    XP(p, -100)
    if LC.PrisonAvailable() then LC.Incarcerate(p, 120, "Corruption", nil) end
    return "complete"
end

local function RefuseBribe(q, p)
    Trait(p, "loyalty", 1)
    q.data.target = q.data.actor
    q.chainEnd = "cleared"
    Insert(q, { Q.ArrestStage("Arrest him for attempted bribery with the Arrest Baton (right click)") })
end

LC.Chain{
    id = "ia", name = "Internal Affairs", factions = { cp = true, ota = true },
    unlock = function(ply) return LC.Trait(ply, "corruption") >= 2 or LC.Counter(ply, "bribes") >= 2 end,
    start = "summons",
    endings = {
        redeemed = "Internal Affairs closes your file. As far as they're concerned, your slate is clean again.",
        cleared = "Internal Affairs found nothing on you. This time.",
        busted = "Internal Affairs caught you taking a bribe. It stays on your record and will follow you.",
        informer = "You named another unit, and now he's paying for what you did.",
        demoted = "You took the blame and lost 100 XP. You kept your conscience. In this city that is a bad trade, and you made it anyway.",
        untouchable = "You stared them down. Internal Affairs can't prove anything, but they'll never stop watching you.",
        ring = "You work for the crooked officers now. The money is very good.",
        double = "You sank the ring's weapons and reported them seized. You played both sides and got away with it. For now.",
        burned = "Internal Affairs knows you dumped their crate of weapons in the canal.",
    },
    parts = {
        summons = { num = 1, build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "A quiet word", reward = 10, limit = 480,
                desc = "You've been summoned " .. Place(pos, ply:GetPos()) .. ". The message isn't signed, but you can guess who sent it: Internal Affairs.",
                stages = {
                    Goto(pos, "Go to the marked spot where you were summoned", 260),
                    Meet("Walk up to the officer waiting for you there", "cop", function() return pos end),
                    Choice("The officer won't give his unit number: he's Internal Affairs, and he knows about the bribes. 'Your ration ledger doesn't add up, unit. " ..
                        "Neither do the citizens who keep walking free on your shift.'", {
                        { text = "Confess to the bribes, and ask for a chance to make it right.", pick = function(q, p)
                            Trait(p, "corruption", -1)
                            Trait(p, "loyalty", 1)
                            Narrate(q, "He nods slowly. 'Then make it right. Your next patrol goes by the book, every step. We'll be counting.'")
                            q.chainNext = "penance"
                        end },
                        { text = "Talk your way out of it.", check = { "guile", 13 },
                          success = function(q)
                              Narrate(q, "He writes something down. 'We'll be in touch.' It doesn't sound like you're off the hook.")
                              q.chainNext = "audit"
                          end,
                          fail = function(q)
                              Narrate(q, "He doesn't believe a word of it. 'From now on, someone will be watching you, Civil Protection unit.'")
                              q.chainNext = "watched"
                          end },
                        { text = "Offer him a share of your bribes.", when = function(q) return LC.Trait(q.owner, "corruption") >= 3 end,
                          pick = function(q, p)
                              Trait(p, "corruption", 1)
                              Narrate(q, "A long pause. Then he laughs, and holds out his hand for the money. He's as crooked as you are.")
                              q.chainNext = "ring"
                          end },
                    }),
                },
            }
        end },

        penance = { num = 2, build = function(ply)
            local stages = Patrol(ply, 3, "Patrol by the book: go to stop")
            if not stages then return nil end
            local inspect = Count("used_npc", 3, "Inspect three different citizens by the book: walk up to each one and press E", Q.IsCitizenNPC)
            inspect.onDone = function(q)
                q.chainEnd = "redeemed"
                Trait(q.owner, "corruption", -2)
            end
            return {
                title = "Penance", reward = 40, limit = 600,
                desc = "Internal Affairs wants to see a model officer. Patrol three stops and inspect three citizens, all by the book, while they watch.",
                stages = Append(stages, { inspect }),
            }
        end },

        audit = { num = 2, build = function(ply)
            local spot = Q.Spot(ply, 400, 2000)
            if not spot then return nil end
            return {
                title = "The audit", reward = 30, limit = 480,
                desc = "You've been sent on a routine patrol " .. Place(spot, ply:GetPos()) .. ". Nothing to worry about, they say.",
                stages = {
                    Goto(spot, "Go to the marked spot and patrol there", 200),
                    Meet("A citizen is waving you over: walk up to him", "citizen", function() return spot end, nil, nil, "male"),
                    Choice("A citizen presses a bundle of ration units into your hand: a bribe. 'For your trouble, officer.' " ..
                        "His eyes flick to a window across the street.", {
                        { text = "Refuse, and arrest him for attempted bribery.", pick = RefuseBribe },
                        { text = "Take the bribe.", pick = TakeBribe },
                        { text = "Look at the window he glanced at.", check = { "authority", 12 },
                          success = function(q, p)
                              Trait(p, "loyalty", 2)
                              q.bonus = 20
                              q.chainEnd = "cleared"
                              Narrate(q, "A camera lens glints behind the glass: this is an Internal Affairs test. You hand the bundle back, loudly, and thank him for his loyalty.")
                              return "complete"
                          end,
                          fail = function(q)
                              Narrate(q, "You see nothing but a window. The bundle is still in your hand, and he's still waiting for your answer.")
                              Insert(q, { Choice("He's still waiting for you to decide. The bribe is still in your hand.", {
                                  { text = "Refuse, and arrest him.", pick = RefuseBribe },
                                  { text = "Take the bribe.", pick = TakeBribe },
                              }) })
                          end },
                    }),
                },
            }
        end },

        watched = { num = 2, build = function(ply)
            local stages = Patrol(ply, 3)
            if not stages then return nil end
            stages[1].onEnter = function(q)
                local p = q.owner
                q.data.shadow = Q.SpawnActor(q, "cop", p:GetPos() - p:GetForward() * 400, 5)
            end
            stages[#stages + 1] = Count("used_npc", 2, "Inspect two different citizens while he watches (walk up to each one and press E)", Q.IsCitizenNPC)
            stages[#stages + 1] = Choice("The Civil Protection unit who has followed you all shift finally speaks. " ..
                "'Give us the name of another Civil Protection unit who takes bribes. Or we keep looking at you.'", {
                { text = "Give them another unit's name.", pick = function(q, p)
                    Trait(p, "loyalty", 1)
                    q.chainEnd = "informer"
                    Narrate(q, "Unit 4-17 is reassigned to the canals the next morning. You never see him again.")
                end },
                { text = "Take the blame yourself (you lose 100 XP).", pick = function(q, p)
                    XP(p, -100)
                    Trait(p, "corruption", -3)
                    q.chainEnd = "demoted"
                end },
                { text = "Say nothing. Stare at his mask until he gives up and leaves.", check = { "nerve", 14 },
                  success = function(q, p) Trait(p, "corruption", 1) q.chainEnd = "untouchable" end,
                  fail = function(q, p)
                      Narrate(q, "You look away first. That's all the answer he needs.")
                      XP(p, -100)
                      q.chainEnd = "demoted"
                  end },
            })
            return {
                title = "Under watch", reward = 35, limit = 720,
                desc = "Internal Affairs has put a unit on your tail, and he'll follow you all shift. Patrol three stops and inspect two citizens, and do it well.",
                stages = stages,
                tick = function(q)
                    local npc, p = q.data.shadow, q.owner
                    local st = IsValid(npc) and LC.NPCs[npc]
                    if not st or not IsValid(p) then return end
                    LC.SetState(npc, st, "event")
                    st.eventUntil = CurTime() + 2
                    local d = npc:GetPos():Distance(p:GetPos())
                    if d > 320 then
                        npc:SetLastPosition(p:GetPos() - p:GetForward() * 200)
                        npc:SetSchedule(d > 900 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                    end
                    if d > 2500 and not LC.IsSeen(npc:GetPos() + Vector(0, 0, 50)) then
                        npc:SetPos(p:GetPos() - p:GetForward() * 300) -- they always find you
                    end
                end,
            }
        end },

        ring = { num = 2, build = function(ply)
            local a, b = Q.Spot(ply, 400, 2000), Q.Spot(ply, 800, 3000)
            if not a or not b then return nil end
            return {
                title = "The smuggling ring", reward = 60, limit = 600,
                desc = "Your new friends, the crooked officers, need a crate moved quietly. Pick it up " .. Place(a, ply:GetPos()) .. ".",
                stages = {
                    Q.Contact("Collect the crate: walk up to your contact and press E", a, "citizen", "'Careful with that one. It's not what the label says.'"),
                    Choice("The crate rattles. It's full of guns for the rebels, sold by the very officers whose job is hunting them.", {
                        { text = "Deliver it to the buyer. Business is business.", pick = function(q, p)
                            Trait(p, "corruption", 1)
                            q.chainEnd = "ring"
                        end },
                        { text = "Dump it in the canal and report it seized.", check = { "guile", 14 },
                          success = function(q, p)
                              Trait(p, "loyalty", 1)
                              Trait(p, "sympathy", 1)
                              q.chainEnd = "double"
                              Narrate(q, "The crate sinks. Your report says it was seized, and it's convincing.")
                              return "complete"
                          end,
                          fail = function(q, p)
                              Narrate(q, "Internal Affairs finds out what you did within the hour.")
                              XP(p, -150)
                              if LC.PrisonAvailable() then LC.Incarcerate(p, 90, "Theft from Internal Affairs", nil) end
                              q.reward = 0
                              q.chainEnd = "burned"
                              return "complete"
                          end },
                    }),
                    Q.Contact("Take the crate to the buyer " .. Place(b, ply:GetPos()) .. " and press E on him", b, "citizen", "The buyer doesn't count the money in front of you. That's how you know it's a lot."),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- The Pamphleteer
------------------------------------------------------------------------

LC.Chain{
    id = "pamphleteer", name = "The Pamphleteer", factions = { citizen = true },
    unlock = function(ply)
        return LC.Trait(ply, "sympathy") >= 2 or (LC.Counter(ply, "silences") + LC.Counter(ply, "pamphlets")) >= 2
    end,
    start = "knock",
    endings = {
        joined = "You've joined the Resistance. Your old life is just a cover story now.",
        ally = "You're a friend of the Resistance, not a member. They'll call on you when they need help.",
        reported = "You reported the stranger. He never came back. Neither did the family in 4C.",
        walked_away = "You shut the door on the Resistance. Some doors stay shut.",
    },
    parts = {
        knock = { num = 1, build = function(ply)
            local home, name = HomeOf(ply)
            if not home then return nil end
            return {
                title = "A knock at night", reward = 10, limit = 420,
                desc = "Go home (" .. name .. "). Someone is waiting for you there.",
                stages = {
                    Goto(home, "Go home (" .. name .. ")", 260),
                    Meet("Someone is waiting outside your door: walk up to him", "citizen", function() return home end, nil, nil, "male"),
                    Choice("A stranger in a Union jacket that doesn't fit him. He says your name like he's known it for years. " ..
                        "'You've been kind to the people the Combine hunt. We noticed. Can you be useful to us, too?'", {
                        { text = "Listen.", pick = function(q)
                            Narrate(q, "He talks for a long time, about the Resistance and what you could do for it. Mostly about you.")
                            q.chainNext = "nerve"
                        end },
                        { text = "Report him to Civil Protection.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            LC.Bump(p, "reports")
                            q.chainEnd = "reported"
                            Narrate(q, "He sees it in your face before you move. He's gone by the time you turn around.")
                            Insert(q, { Count("used_npc", 1, "Find a Civil Protection unit and press E on him to report the stranger", Q.IsCopNPC) })
                        end },
                        { text = "Shut the door on him.", pick = function(q)
                            q.chainDecline = true
                            q.reward = 0
                            Narrate(q, "You lean against the door until his footsteps fade.")
                            return "complete"
                        end },
                    }),
                },
            }
        end },

        nerve = { num = 2, build = function(ply)
            local a, b, detour = Q.Spot(ply, 400, 2000), Q.Spot(ply, 800, 3000), Q.Spot(ply, 600, 2500)
            if not a or not b then return nil end
            return {
                title = "Proof of nerve", reward = 30, limit = 600, failOnArrest = true,
                desc = "The Resistance is testing you: carry a parcel across the district to a dead drop. Don't open it, and don't get arrested on the way, or the job fails.",
                stages = {
                    Q.Contact("Walk up to your contact and press E to take the parcel", a, "citizen", "'Straight there. Don't open it. Don't be late.'", { rebel = true }),
                    Choice("Two Civil Protection units are checking papers at the corner ahead, and you're carrying the parcel.", {
                        { text = "Walk past them, calmly.", check = { "guile", 11 },
                          success = function(q) Narrate(q, "One of them looks right at you. Then past you. You're through.") end,
                          fail = function(q, p)
                              Narrate(q, "'Citizen! Stop!' You keep walking, and now you're wanted for carrying contraband.")
                              LC.ReportCrime(p, "Carrying contraband", 120)
                          end },
                        { text = "Take the long way, through the alleys.", pick = function(q)
                            if detour then Insert(q, { Goto(detour, "Take the long way round: go to the marked spot first", 180) }) end
                        end },
                    }),
                    Deliver(b, "Take the parcel to the dead drop " .. Place(b, ply:GetPos()), 150),
                },
            }
        end, next = "decision" },

        decision = { num = 3, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            return {
                title = "The choice", reward = 25, limit = 600,
                desc = "The Resistance wants to meet you in person this time (" .. where .. ").",
                stages = {
                    Goto(pos, "Go to the meeting place (" .. where .. ")", r),
                    Meet("Walk up to the stranger", "citizen", function() return pos end),
                    Choice("The stranger is waiting with two others. One of them wears the Resistance's lambda openly. 'Well? Are you with us?'", {
                        { text = "I'm with you. (You join the Resistance.)", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            q.chainEnd = "joined"
                            JoinLater(p, "resistance", 150)
                        end },
                        { text = "Not yet. But I'll help when I can. (You stay a citizen, as a friend of the Resistance.)", pick = function(q, p)
                            Trait(p, "sympathy", 1)
                            q.chainEnd = "ally"
                        end },
                        { text = "I've changed my mind. (You turn them down.)", pick = function(q) q.chainEnd = "walked_away" end },
                    }),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- The Informant
------------------------------------------------------------------------

-- The neighbor is whoever is out on the street: the words follow them.
local PRONOUNS = {
    male = { he = "he", him = "him", his = "his", He = "He", His = "His" },
    female = { he = "she", him = "her", his = "her", He = "She", His = "Her" },
}
local function Neighbor(q, text)
    local st = IsValid(q.data.target) and LC.NPCs[q.data.target]
    local p = PRONOUNS[st and st.gender or "male"] or PRONOUNS.male
    return (string.gsub(text, "{(%a+)}", function(k) return p[k] or k end))
end

local function TailStage(secs)
    return {
        kind = "tail", min = 200, max = 1100, lost = 1700, secs = secs,
        failText = "your neighbor isn't out on the streets right now. Try again later, when the city is busier",
        text = "Follow your neighbor (marked) without being noticed",
        onEnter = function(q, st)
            local npc = q.data.target
            if not IsValid(npc) then npc = Q.RandomCitizen() end
            if not npc then return false end
            Q.Lock(q, npc)
            q.data.target = npc
            st.npc = npc
            st.text = Neighbor(q, "Follow your neighbor (marked) without being noticed. Don't fall too far behind, and stay out of {his} sight: the longer {he} sees you, the more suspicious {he} gets")
            local nst = LC.NPCs[npc]
            if nst then nst.eventUntil = 0; LC.GoTo(npc, nst, LC.RandomWanderPos("citizen"), false, nil) end
        end,
        onNoticed = function(q)
            Insert(q, { Choice(Neighbor(q, "{He} stops and turns around. {He} has spotted you, and knows exactly who you are."), {
                { text = "Pretend you were heading the other way.", check = { "guile", 12 },
                  success = function(q2)
                      Narrate(q2, Neighbor(q2, "{He} shrugs and walks on. Keep following, but give {him} more room this time."))
                      Insert(q2, { TailStage(20) })
                  end,
                  fail = function(q2)
                      Narrate(q2, Neighbor(q2, "{He} doesn't believe you. {He} runs off, and the job has failed."))
                      Q.Flee(q2)
                      return "fail"
                  end },
                { text = Neighbor(q, "Confront {him}."), pick = function(q2, p)
                    Trait(p, "loyalty", 1)
                    Narrate(q2, Neighbor(q2, "'You're one of them now? You?' {He} doesn't run. {He} just looks tired."))
                end },
            }) })
            Q.Advance(q)
        end,
    }
end

LC.Chain{
    id = "informant", name = "The Informant", factions = { citizen = true },
    unlock = function(ply, story)
        local p = story.chains.pamphleteer
        return LC.Trait(ply, "loyalty") >= 3 or LC.Counter(ply, "reports") >= 2 or (p and p.done == "reported")
    end,
    start = "eyes",
    endings = {
        paid = "You took the double rations. Your neighbors have started saying good morning a little too carefully.",
        brother = "Your brother is released. He comes home thinner and quieter, and never asks how.",
        brother_lost = "Now they're watching your brother too. Because of you.",
        zealot = "You refused any reward. The city has no truer friend. The city does not have friends.",
    },
    parts = {
        eyes = { num = 1, next = "neighbor", build = function(ply)
            local s = Q.Spot(ply, 400, 2500)
            if not s then return nil end
            return {
                title = "Eyes and ears", reward = 20, limit = 480,
                desc = "The Union wants you to keep watch " .. Place(s, ply:GetPos()) .. ", then report what you saw to Civil Protection.",
                stages = {
                    Goto(s, "Go to the marked lookout spot", 180),
                    Hold(s, 15, "Stay near the spot for 15 seconds and watch who comes and goes", 260),
                    Count("used_npc", 1, "Report what you saw: find any Civil Protection unit and press E on him", Q.IsCopNPC),
                },
            }
        end },

        neighbor = { num = 2, next = "payment", build = function()
            if not LC.Running or not Q.RandomCitizen() then return nil end -- nobody out to follow yet
            local report = Count("used_npc", 1, "Report your neighbor: find any Civil Protection unit and press E on him", Q.IsCopNPC)
            report.onEnter = function(q, st) st.text = Neighbor(q, "Report {him}: find any Civil Protection unit and press E on the unit") end
            report.onDone = function(q)
                local npc = q.data.target
                local line = Neighbor(q, "Civil Protection comes for your neighbor. By evening, {his} door is sealed with yellow tape.") -- before the arrest takes them away
                if IsValid(npc) and LC.PrisonAvailable() and LC.ArrestNPC then LC.ArrestNPC(npc, nil) end
                Narrate(q, line)
            end
            return {
                title = "The neighbor", reward = 35, limit = 720,
                desc = "Your neighbor has been keeping strange hours. The Union wants you to follow them without being seen, then report them to Civil Protection.",
                stages = { TailStage(40), report },
            }
        end },

        payment = { num = 3, build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Payment", reward = 40, limit = 480,
                desc = "Collect your reward for informing " .. Place(pos, ply:GetPos()) .. ".",
                stages = {
                    Goto(pos, "Go to the marked spot to collect your payment", 260),
                    Count("used_npc", 1, "Walk up to a Civil Protection officer and press E", Q.IsCopNPC),
                    Choice("The officer slides a ration card across. 'Double rations. The Union appreciates its friends.'", {
                        { text = "Take the card.", pick = function(q, p)
                            Trait(p, "loyalty", 1)
                            Trait(p, "corruption", 1)
                            q.chainEnd = "paid"
                        end },
                        { text = "Ask for your brother's release instead.", check = { "empathy", 13 },
                          success = function(q, p)
                              Trait(p, "sympathy", 1)
                              q.chainEnd = "brother"
                              for npc, st in pairs(LC.NPCs) do
                                  if IsValid(npc) and st.state == "jailed" then LC.ReleaseNPCPrisoner(npc, st, CurTime(), true) break end
                              end
                              Narrate(q, "A name is typed. Somewhere below your feet, a cell door opens: your brother is free.")
                          end,
                          fail = function(q)
                              q.chainEnd = "brother_lost"
                              Narrate(q, "'Your brother? Interesting. We'll look into him too.'")
                          end },
                        { text = "Refuse the reward. You did it for the city.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            q.chainEnd = "zealot"
                        end },
                    }),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- The Missing Unit
------------------------------------------------------------------------

local CAUSE_PROMPTS = {
    rebels = "Lambda graffiti on the wall, the paint still wet, and drag marks leading toward the canals. Rebels took him.",
    infestation = "Headcrab blood, smeared up the wall and splattered across the floor. A lot of it. His stunstick is bent nearly in half. The infestation got him.",
    deserted = "His mask is folded neatly on the ground, as if he took it off himself and didn't want it damaged. It looks like he deserted.",
}

LC.Chain{
    id = "missing", name = "The Missing Civil Protection unit", factions = { cp = true },
    unlock = function(ply)
        return Q.RankIndex(ply) >= 3 or (tonumber(ply:GetPData("lcq_done", 0)) or 0) >= 4
    end,
    start = "dark",
    endings = {
        silenced = "The radio is dead. For a while, the Resistance goes quiet too.",
        counterintel = "For a week, the Resistance follows your false orders. Overwatch notices your work.",
        mercy = "You put 6-12 down yourself and file his tags with the others. Nobody asks how he died.",
        left = "A cleanup crew clears the area. They log him as one more zombine. You don't tell them his number.",
        brought_in = "He's processed by morning. You never learn what happened to his daughter.",
        let_go = "You let him go and report him killed in action. You'll never be sure that was a kindness.",
        defected = "6-12 made it to the Resistance. Somewhere in the canals, he's teaching rebels how Civil Protection units think.",
        fled = "6-12 got away. He's out there somewhere, and now he knows your face.",
    },
    parts = {
        dark = { num = 1, build = function(ply, data)
            data.cause = data.cause or Pick({ "rebels", "infestation", "deserted" })
            if data.cause == "infestation" and #LC.ZonesOfKind("infest") == 0 then data.cause = "deserted" end
            if data.cause == "rebels" and #LC.ZonesOfKind("rebel") == 0 then data.cause = "deserted" end
            local spot = Q.Spot(ply, 600, 3000)
            if not spot then return nil end
            local nextPart = data.cause == "deserted" and "deserter" or "retaliation"
            return {
                title = "Gone dark", reward = 25, limit = 600,
                desc = "Unit 6-12 stopped answering dispatch " .. Place(spot, ply:GetPos()) .. ". Go there and find out what happened to him.",
                stages = {
                    Goto(spot, "Go to 6-12's last known position (marked)", 260),
                    { kind = "collect", spots = Q.HideSpots(spot, 2, 500), need = 2,
                      models = { "models/weapons/w_stunbaton.mdl", "models/props_c17/paper01.mdl" },
                      text = "Search the area: find 2 of 6-12's belongings and press E on each" },
                    Choice(CAUSE_PROMPTS[data.cause], {
                        { text = "Report it to your superiors.", pick = function(q) q.chainNext = nextPart end },
                        { text = "Keep it quiet and look into it yourself.", pick = function(q)
                            q.chainData.quiet = true
                            q.bonus = 5
                            q.chainNext = nextPart
                        end },
                    }),
                },
            }
        end },

        retaliation = { num = 2, build = function(ply, data)
            if data.cause == "infestation" then
                local z = Pick(LC.ZonesOfKind("infest"))
                if not z then return nil end
                -- (the owner, 7 November: a choice popping up mid-fight took over the cursor in a zombie-infested
                -- zone) no choice window here: a zombine in his uniform comes at you, the screen says who it must be,
                -- and what you do decides it. Kill him (mercy), or walk out of the infestation (left).
                local fight = Count("killed", 3, "Fight your way through: kill 3 zombies or headcrabs", function(_, _, npc) return Q.IsZombieNPC(npc) end)
                -- (400 past its edge, and you've left the infestation: grown ground by its cells, LCZ.Near)
                local him = {
                    kind = "count", event = "killed", need = 1, untallied = true,
                    text = "That zombine is 6-12. Kill him to end his suffering, or leave the infestation and let a cleanup crew deal with him",
                    filter = function(q, _, npc) return npc == q.data.zombine end,
                    onEnter = function(q, st)
                        local npc = LC.SpawnMissingZombine and LC.SpawnMissingZombine(q, z)
                        if not IsValid(npc) then return false end
                        st.npc = npc
                        for _, p in ipairs(Q.Members(q)) do
                            if LCZ.Near(z, p:GetPos(), 400) then q.data.wentIn = true end
                            if LC.Notice then
                                LC.Notice(p, "warn", "This must be 6-12", "A zombine in a Civil Protection uniform, a headcrab where his face used to be. Kill him to end his suffering, " ..
                                    "or leave the infestation and let a cleanup crew deal with him.", 10)
                            end
                        end
                    end,
                    poll = function(q, st)
                        local npc = q.data.zombine
                        if not IsValid(npc) or npc:Health() <= 0 then
                            q.chainEnd = "mercy"
                            return Q.Advance(q)
                        end
                        local inside = false
                        for _, p in ipairs(Q.Members(q)) do
                            if p:Alive() and LCZ.Near(z, p:GetPos(), 400) then inside = true end
                        end
                        if inside then q.data.wentIn = true st.away = 0 return end
                        if not q.data.wentIn then return end
                        st.away = (st.away or 0) + 0.5
                        if st.away >= 2 then
                            q.chainEnd = "left"
                            Narrate(q, "You leave him to the infestation. A cleanup crew will find what's left of him.")
                            Q.Advance(q)
                        end
                    end,
                    onDone = function(q)
                        if q.chainEnd == nil then q.chainEnd = "mercy" end
                        if q.chainEnd == "mercy" then Narrate(q, "6-12 goes down for the last time. His suffering is over.") end
                    end,
                }
                return {
                    title = "What's left of him", reward = 40, limit = 600,
                    desc = "The trail leads into the infestation. Go in and find 6-12.",
                    stages = {
                        Goto(z.pos, "Go into the infestation (marked)", math.max(200, z.r)),
                        fight,
                        him,
                    },
                }
            end
            local z = Pick(LC.ZonesOfKind("rebel"))
            local enter = Goto(z.pos, "Go into rebel territory (marked). Armed rebels will be waiting", math.max(150, z.r * 0.8))
            -- the people who took him are in there, and they're armed
            enter.onEnter = function() if LC.ReinforceRebels then LC.ReinforceRebels(z, 3) end end
            return {
                title = "Retaliation", reward = 40, limit = 600,
                desc = "The drag marks lead into rebel territory. Go in and stay inside for 45 seconds to search it. Armed rebels will fight you.",
                stages = {
                    enter,
                    { kind = "survive", secs = 45, text = "Stay alive inside rebel territory for 45 seconds while you search (the rebels know you're here)",
                      cond = function(_, p) return LC.InRebelZone(p:GetPos()) end },
                    Choice("You find his radio in a stairwell, still switched on. Someone has been listening to Civil Protection frequencies all week.", {
                        { text = "Smash the radio.", pick = function(q) q.chainEnd = "silenced" end },
                        { text = "Leave it on, and feed them false orders.", check = { "guile", 13 },
                          success = function(q, p) Trait(p, "loyalty", 2) q.bonus = 30 q.chainEnd = "counterintel" end,
                          fail = function(q)
                              Narrate(q, "They stop transmitting the moment you touch it. The trick won't work now.")
                              q.chainEnd = "silenced"
                          end },
                    }),
                },
            }
        end },

        deserter = { num = 2, build = function(ply)
            local spot = Q.Spot(ply, 800, 3500)
            if not spot then return nil end
            local dest, r, safe = Q.SafeHouse(ply)
            return {
                title = "The man in the stolen coat", reward = 45, limit = 600,
                desc = "A man in citizen's clothes with a Civil Protection haircut was seen " .. Place(spot, ply:GetPos()) .. ". It might be 6-12.",
                stages = {
                    Meet("Find the man in the stolen coat (marked) and walk up to him", "citizen", function() return spot end, nil, nil, "male"),
                    Choice("It's him: 6-12, in a stolen coat, his haircut already growing out. 'Please. I have a daughter in Block 4.'", {
                        { text = "Arrest him and bring him in.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            q.chainEnd = "brought_in"
                            if LC.PrisonAvailable() then
                                q.data.target = q.data.actor
                                Insert(q, { Q.ArrestStage("Arrest him with the Arrest Baton (right click)") })
                            end
                        end },
                        { text = "Let him go, and say nothing.", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            Trait(p, "corruption", 1)
                            q.chainEnd = "let_go"
                            return "complete"
                        end },
                        { text = "Help him reach the Resistance.", check = { "empathy", 12 },
                          success = function(q, p)
                              Trait(p, "sympathy", 3)
                              q.chainEnd = "defected"
                              Insert(q, { { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead him to safety (" .. safe .. "). He follows you",
                                  onEnter = function(q2, st) st.npc = q2.data.actor end } })
                          end,
                          fail = function(q)
                              Narrate(q, "He doesn't trust you. He runs, and he's gone.")
                              q.data.target = q.data.actor
                              Q.Flee(q)
                              q.chainEnd = "fled"
                              return "complete"
                          end },
                    }),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- Father Grigori's Flock
------------------------------------------------------------------------

LC.Chain{
    id = "flock", name = "Father Grigori's Flock", special = "chaplain",
    unlock = function() return true end,
    start = "lost",
    endings = {
        forgiven = "You forgave the informant. He weeps through the whole blessing, and never informs again.",
        cast_out = "You sent the informant away. He leaves without a word. The flock is smaller, and safer.",
        betrayed = "The informant talked, and your chapel is burned to ash by morning. You will find another. You always do.",
        grace = "You blessed the informant with the rest. If he reports you, he'll have to report that too.",
    },
    parts = {
        lost = { num = 1, next = "mass", build = function()
            return {
                title = "Lost sheep", reward = 25, limit = 600,
                desc = "The city is full of frightened people. Speak with three citizens, then heal two wounded people with The Blessing.",
                stages = {
                    Count("used_npc", 3, "Speak with 3 different citizens: walk up to each one and press E", Q.IsCitizenNPC),
                    Count("healed", 2, "Heal 2 wounded people with The Blessing (left click on someone who is hurt)", nil, true),
                },
            }
        end },

        mass = { num = 2, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            local hold = Hold(pos, 60, "Hold a secret mass: stay at the chapel for 60 seconds, out of sight of Civil Protection", math.max(220, r))
            hold.onEnter = function(q)
                q.data.flock = {}
                for _ = 1, 3 do
                    local npc = Q.RandomCitizen()
                    if npc then
                        Q.Lock(q, npc)
                        local st = LC.NPCs[npc]
                        st.eventUntil = 0
                        local spot = pos + Vector(math.random(-120, 120), math.random(-120, 120), 0)
                        -- they gather, face the priest, and stay for the service
                        LC.GoTo(npc, st, spot, false, { kind = "queue", pos = spot, yaw = (pos - spot):Angle().y })
                        q.data.flock[#q.data.flock + 1] = npc
                    end
                end
            end
            return {
                title = "The secret mass", reward = 50, limit = 720,
                desc = "Gather the faithful for a secret mass (" .. where .. "). Pray quietly, pray quickly, and keep out of sight of Civil Protection.",
                stages = {
                    Goto(pos, "Go to the hidden chapel (" .. where .. ")", math.max(200, r)),
                    hold,
                    Choice("As the last hymn ends, you notice one of your flock quietly counting the others, like a man taking notes for Civil Protection. There's an informant among you.", {
                        { text = "Work out which of them is the informant.", check = { "empathy", 13 },
                          success = function(q)
                              Insert(q, { Choice("You find him. He's young and frightened: they're holding his mother.", {
                                  { text = "Forgive him.", pick = function(q2, p) Trait(p, "sympathy", 2) q2.chainEnd = "forgiven" end },
                                  { text = "Send him away.", pick = function(q2) q2.chainEnd = "cast_out" end },
                              }) })
                          end,
                          fail = function(q, p)
                              Narrate(q, "You can't tell which of them it is. By morning, Civil Protection knows everything, and you're wanted for unlawful worship.")
                              LC.ReportCrime(p, "Unlawful worship", 300)
                              q.chainEnd = "betrayed"
                          end },
                        { text = "Bless them all, the informant too.", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            q.chainEnd = "grace"
                        end },
                    }),
                },
                tick = function(q)
                    if q.data.seen or not IsValid(q.owner) then return end
                    local st = q.stages[q.stage]
                    if st and st.kind == "hold" and LC.SeenBySecurity(q.owner, 900) then
                        q.data.seen = true
                        Narrate(q, "Boots on the stairs: Civil Protection saw the mass. You're wanted for unlawful worship.")
                        LC.ReportCrime(q.owner, "Unlawful worship", 240)
                    end
                end,
            }
        end },
    },
}

------------------------------------------------------------------------
-- The Overwatch Candidate
------------------------------------------------------------------------

LC.Chain{
    id = "candidate", name = "The Overwatch Candidate", factions = { cp = true },
    unlock = function(ply) return Q.RankIndex(ply) >= 3 and not (LC.Conditioned and LC.Conditioned(ply)) end, -- (Division Leaders)
    start = "evaluation",
    endings = {
        transhuman = "You accepted the conditioning. You don't remember your name. You don't need to.",
        human = "You keep your name, your face, and the nightmares. Overwatch won't ask twice: you'll go no higher than Division Leader.",
    },
    parts = {
        evaluation = { num = 1, next = "conditioning", build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Evaluation", reward = 30, limit = 600,
                desc = "Overwatch is judging whether you're fit for more. Hold a checkpoint for 90 seconds, then inspect three citizens. No mistakes.",
                stages = {
                    Goto(pos, "Go to the marked checkpoint", 260),
                    Hold(pos, 90, "Stay at the checkpoint for 90 seconds while Overwatch observes you", 280),
                    Count("used_npc", 3, "Inspect 3 different citizens (walk up to each one and press E)", Q.IsCitizenNPC),
                },
            }
        end },

        conditioning = { num = 2, build = function(ply)
            local zones = LC.ZonesOfKind("prison")
            local pos = #zones > 0 and zones[1].pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Conditioning", reward = 20, limit = 480,
                desc = "You've been ordered to report " .. Place(pos, ply:GetPos()) .. ". Come alone.",
                stages = {
                    Goto(pos, "Go to the marked spot as ordered", 300),
                    Choice("A technician in a coat that has never been white. 'Transhuman conditioning. It will make you Overwatch. " ..
                        "You won't remember your name, Civil Protection unit. You won't need to.'", {
                        { text = "Accept. (You become Overwatch, a Combine Prison Guard at once: the Soldier and Elite ranks open to you. There's no undoing it.)", pick = function(q, p)
                            q.chainEnd = "transhuman"
                            if LC.ConditioningScene then LC.ConditioningScene(p) end -- (black screen, machines, and out of it Overwatch)
                        end },
                        { text = "Decline. You like your name. (You'll rise no higher than Division Leader.)", pick = function(q)
                            q.bonus = 50
                            q.chainEnd = "human"
                        end },
                    }),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- The Man Inside: honest, kind cops get an offer
------------------------------------------------------------------------

local function Suspect(q, p, why)
    if not IsValid(p) then return end
    LC.Bump(p, "suspicion")
    Narrate(q, why or "Someone saw that, and they'll remember. Suspicion of you is growing.")
    if LC.Counter(p, "suspicion") >= 3 then
        p:ChatPrint("[Story] Too many people have seen you acting strangely. You have a feeling you're being watched.")
        if LC.CheckUnlocks then LC.CheckUnlocks(p) end
    end
end

-- Watching for witnesses while doing something you shouldn't.
local function Witnessed(kinds, why)
    return function(q)
        if q.data.witnessed or not IsValid(q.owner) then return end
        -- the guards drawn off (a fire, a false report): nobody's looking
        if (q.data.distractedUntil or 0) > CurTime() then return end
        -- a transfer order: it looks like paperwork, mostly (one unit in six looks closer, once)
        if q.data.order then
            if q.data.orderChecked or not LC.SeenBySecurity(q.owner, 700) then return end
            q.data.orderChecked = true
            if math.random() > 1 / 6 then return end
            why = "A unit looked closely at your transfer order. The stamp's wrong, and he knows it."
        end
        local st = q.stages[q.stage]
        if st and kinds[st.kind] and LC.SeenBySecurity(q.owner, 700) then
            q.data.witnessed = true
            Suspect(q, q.owner, why)
        end
    end
end

local function FreePrisonerStage(text)
    return {
        kind = "target", action = "free", text = text,
        onEnter = function(q, st)
            local npc
            for n, s in pairs(LC.NPCs) do if IsValid(n) and s.state == "jailed" and not s.questLock then npc = n break end end
            if not npc then
                npc = Q.RandomCitizen()
                if not npc or not LC.ArrestNPC(npc, nil) then return false end
            end
            Q.Lock(q, npc)
            q.data.target = npc
            st.npc = npc
        end,
    }
end

LC.Chain{
    id = "inside", name = "The Man Inside", factions = { cp = true },
    -- the Resistance doesn't reach out to a unit who's been killing them (the owner, 1 November: it stayed on
    -- the board after a dozen dead rebels): three in the last half hour, and it's off the board
    gate = function(ply) return LC.RecentRebelKills == nil or LC.RecentRebelKills(ply) < 3 end,
    unlock = function(ply)
        return LC.Trait(ply, "corruption") <= 1 and (LC.Trait(ply, "sympathy") >= 3 or LC.Counter(ply, "mercies") >= 2)
    end,
    start = "note",
    endings = {
        loyal = "You arrested her. She was processed by morning, and you were commended. You don't sleep well.",
        defected = "You joined the Resistance and burned your uniform in a canal barrel. They now have a fighter who knows exactly how Civil Protection units think.",
        insider = "You stay in Civil Protection as a Resistance spy. You still wear the mask, but now you know who you're wearing it for.",
        walked = "You walked away from both sides and never answer another note. Some nights you wonder.",
    },
    parts = {
        note = { num = 1, build = function(ply)
            local spot = Q.Spot(ply, 500, 2500)
            if not spot then return nil end
            return {
                title = "A note in your ration packet", reward = 15, limit = 480,
                desc = "Someone slipped a note into your ration packet. It names a place, " .. Place(spot, ply:GetPos()) .. ", and a time: now.",
                stages = {
                    Goto(spot, "Go to the place named in the note (marked)", 220),
                    Meet("Find whoever left the note (marked) and walk up to them", "citizen", function() return spot end, nil, nil, "female"),
                    Choice("A woman with the Resistance's lambda tattooed on the inside of her wrist. 'People talk about you, officer. " ..
                        "The one who looks the other way. The one who says please.' She doesn't blink. 'We could use someone like that.'", {
                        { text = "Hear her out.", pick = function(q)
                            Narrate(q, "She talks fast and quiet. By the end, you know the names of three rebels, names you shouldn't know.")
                            q.chainNext = "proof"
                        end },
                        { text = "Arrest her.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            q.chainEnd = "loyal"
                            if LC.PrisonAvailable() then
                                q.data.target = q.data.actor
                                Insert(q, { Q.ArrestStage("Arrest her with the Arrest Baton (right click)") })
                            end
                        end },
                        { text = "Pretend you never saw her.", pick = function(q)
                            q.chainDecline = true
                            q.reward = 0
                            Narrate(q, "You walk away. You keep the note.")
                            return "complete"
                        end },
                    }),
                },
            }
        end },

        proof = { num = 2, next = "crossroads", build = function(ply)
            if #LC.PointsOfKind("cell") == 0 then return nil end
            local dest, r, where = Q.SafeHouse(ply)
            -- (the owner, 1 November: walking a prisoner out of a prison full of guards couldn't be done) a way
            -- in: a forged transfer order, or the guards drawn off by a fire or a false report
            local cells = LC.PointsOfKind("cell")
            local cellAt = cells[1].pos
            local function FarSpot()
                for _ = 1, 30 do
                    local p = LC.RandomWanderPos and LC.RandomWanderPos("citizen", cellAt)
                    if p then local d = p:Distance(cellAt) if d > 700 and d < 2200 then return p end end
                end
                return cellAt + Vector(900, 0, 0)
            end
            local function Distract(q, spot, secs)
                q.data.distractedUntil = CurTime() + secs
                for npc, st in pairs(LC.NPCs or {}) do
                    if IsValid(npc) and LC.IsSecurity(st) and st.state ~= "hostile" and npc:GetPos():DistToSqr(cellAt) < 2500 * 2500 then
                        st.holdPos = spot
                        if LC.GoTo then LC.GoTo(npc, st, spot, true, nil) end
                        timer.Simple(secs, function() if IsValid(npc) and st.holdPos == spot then st.holdPos = nil end end)
                    end
                end
                if IsValid(q.owner) then q.owner:ChatPrint(string.format("[The Man Inside] The guards are off to look. You've about %d seconds.", secs)) end
            end
            local how = Choice("Your contact's note: 'Two ways in. Pick one.'", {
                { text = "A forged transfer order: walk them out like it's paperwork.", pick = function(q, p)
                    q.data.order = true
                    if LC.GiveOrDrop then LC.GiveOrDrop(p, "transfer_order", 1) end
                    Narrate(q, "A transfer order, stamped and signed, in your pocket. To anyone who glances at it, you're moving a prisoner. Hope nobody looks closer.")
                end },
                { text = "Set a fire at the far end of the block (marked): the guards will go to it.", pick = function(q, p)
                    local spot = FarSpot()
                    local go = Goto(spot, "Get to the spot (marked) and set the fire", 120)
                    go.onDone = function(qq)
                        if LC.Firebomb then LC.Firebomb(spot, nil) end
                        Distract(qq, spot, 90)
                    end
                    Q.InsertStages(q, { go })
                end },
                { text = "Call in a false report on the Civil Protection net: they'll all go to look.", pick = function(q, p)
                    local spot = FarSpot()
                    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: shots fired " .. (LC.DescribePlace and LC.DescribePlace(spot) or "nearby") .. ". All units respond.") end
                    Distract(q, spot, 60)
                end },
            })
            return {
                title = "Proof of good faith", reward = 35, limit = 720,
                desc = "The Resistance wants proof you're on their side: free a prisoner from the cells and walk them to safety (" .. where .. "). Don't let another Civil Protection unit see you.",
                stages = {
                    how,
                    FreePrisonerStage("Go to the cells and press E on the marked prisoner to unlock their cell"),
                    { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead the prisoner to safety (" .. where .. "). They follow you: act like it's routine",
                      onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
                },
                tick = Witnessed({ escort = true }, "A Civil Protection unit saw you walking a prisoner out of the block. He'll remember."),
            }
        end },

        crossroads = { num = 3, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            return {
                title = "The crossroads", reward = 30, limit = 600,
                desc = "The Resistance wants to meet you (" .. where .. "). Come out of uniform if you can. Come alone either way.",
                stages = {
                    Goto(pos, "Go to the meeting place (" .. where .. ")", r),
                    Meet("Find the woman from the note and walk up to her", "citizen", function() return pos end, nil, nil, "female"),
                    Choice("She's waiting with a man in a lambda armband who doesn't take his hand off his rifle. " ..
                        "'You've proven yourself. So: do you join us, or stay in Civil Protection where you can do the most good?'", {
                        { text = "Come over. Tonight. (You join the Resistance.)", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            q.chainEnd = "defected"
                            JoinLater(p, "resistance", 400)
                        end },
                        { text = "Stay inside. Be their eyes. (You stay in Civil Protection as their spy.)", pick = function(q, p)
                            Trait(p, "sympathy", 1)
                            LC.StoryFlag(p, "insider", true)
                            q.chainEnd = "insider"
                            Narrate(q, "He finally lets go of the rifle. 'Then you never met us. Watch your job board (F4): we'll send you work there.'")
                        end },
                        { text = "Walk away from all of it.", pick = function(q) q.chainEnd = "walked" end },
                    }),
                },
            }
        end },
    },
}

------------------------------------------------------------------------
-- Inside Work: repeatable secret jobs for a double agent
------------------------------------------------------------------------

local OPS = {}

OPS[#OPS + 1] = function(ply)
    local s = Q.Spot(ply, 500, 2500)
    if not s then return nil end
    local hold = Hold(s, 4, "Crouch at the dead drop for 4 seconds to leave the patrol schedule", 90, true)
    hold.onDone = function(q)
        if LC.SeenBySecurity(q.owner, 800) then Suspect(q, q.owner, "A Civil Protection unit watched you crouch by that drainpipe. He'll wonder why.") end
    end
    return {
        title = "Leak the schedule", reward = 25, limit = 420,
        desc = "Leave tomorrow's patrol routes at a Resistance dead drop " .. Place(s, ply:GetPos()) .. ". Don't let other units see you.",
        stages = { Goto(s, "Go to the dead drop (marked)", 150), hold },
    }
end

OPS[#OPS + 1] = function(ply)
    local id = Q.CitizenID()
    local dest, r, where = Q.SafeHouse(ply)
    local warn = {
        kind = "target", action = "use", text = "Find citizen " .. id .. " (marked) and press E to warn them before the raid",
        onEnter = function(q, st)
            local npc = Q.RandomCitizen()
            if not npc then return false end
            Q.Lock(q, npc)
            q.data.target = npc
            st.npc = npc
        end,
        onDone = function(q)
            local npc = q.data.target
            local st = IsValid(npc) and LC.NPCs[npc]
            if st then
                st.eventUntil = 0
                LC.GoTo(npc, st, dest, true, nil)
                SafeRemoveEntityDelayed(npc, 25)
            end
            Narrate(q, "They go pale, then they go. By the time the raid comes, the apartment is empty.")
        end,
    }
    return {
        title = "Warn them first", reward = 30, limit = 240,
        desc = "Citizen " .. id .. " is on tomorrow's raid list. Warn them before Civil Protection gets there, and be quick.",
        stages = { warn },
        tick = Witnessed({ target = true }, "Another Civil Protection unit saw you whispering to someone on the list."),
    }
end

OPS[#OPS + 1] = function(ply)
    local center = Q.Spot(ply, 500, 2000)
    if not center then return nil end
    local dest, r, where = Q.SafeHouse(ply)
    local item = Pick(Q.CONTRABAND)
    return {
        title = "Lose the evidence", reward = 30, limit = 480,
        desc = "Evidence against a Resistance cell is lying " .. Place(center, ply:GetPos()) .. ". Collect it and take it to the Resistance instead of the evidence room.",
        stages = {
            { kind = "collect", spots = Q.HideSpots(center, 2, 500), model = item[2], need = 2, text = "Find the 2 pieces of evidence and press E on each" },
            Deliver(dest, "Take the evidence to the marked spot (" .. where .. "), not to HQ", r),
        },
        tick = Witnessed({ deliver = true }, "A Civil Protection unit saw you heading the wrong way with an evidence bag."),
    }
end

OPS[#OPS + 1] = function(ply)
    if #LC.PointsOfKind("cell") == 0 then return nil end
    local rel = LC.PointsOfKind("release")
    local dest = #rel > 0 and Pick(rel).pos or select(1, Q.SafeHouse(ply))
    return {
        title = "A quiet release", reward = 35, limit = 600,
        desc = "Someone in the cells knows too much about the Resistance. Free them and walk them out before they're interrogated.",
        stages = {
            FreePrisonerStage("Press E on the marked prisoner to open their cell"),
            { kind = "escort", pos = dest, r = 200, vanish = true, text = "Lead the prisoner to the marked spot (they follow you). Act like it's routine paperwork",
              onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
        },
        tick = Witnessed({ escort = true }, "The desk officer is going to remember that release had no paperwork."),
    }
end

OPS[#OPS + 1] = function(ply)
    local cps = LC.PointsOfKind("checkpoint")
    local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
    if not pos then return nil end
    return {
        title = "Misdirection", reward = 20, limit = 420,
        desc = "Your sector report is due, and there was Resistance activity near the canals this week. Hand it in, and decide whether to cover for them.",
        stages = {
            Goto(pos, "Go to the marked spot to file your sector report", 260),
            Count("used_npc", 1, "Walk up to a Civil Protection officer and press E to hand in your report", Q.IsCopNPC),
            Choice("The officer skims your report. 'Canals. Anything to note, Civil Protection unit?'", {
                { text = "Lie: the canals were quiet. Completely quiet.", check = { "guile", 12 },
                  success = function(q, p) Trait(p, "sympathy", 1) Narrate(q, "He stamps it without looking up. The lie worked.") end,
                  fail = function(q, p) Suspect(q, p, "He reads it twice, then looks at you for a long moment. He doesn't believe you.") end },
                { text = "Report it honestly. You can't risk it today.", pick = function(q, p)
                    Trait(p, "loyalty", 1)
                    Narrate(q, "Because of your report, a Resistance cell in the canals has to move tonight. They'll understand. Probably.")
                end },
            }),
        },
    }
end

LC.Chain{
    id = "insidework", name = "Inside Work", factions = { cp = true }, flat = true,
    unlock = function(ply) return LC.StoryFlag(ply, "insider") == true end,
    gate = function(ply)
        return LC.StoryFlag(ply, "insider") == true and not LC.StoryFlag(ply, "exposed") and not LC.StoryFlag(ply, "disgraced") and LC.Counter(ply, "suspicion") < 3
    end,
    start = "op",
    parts = {
        op = { num = 1, next = "op", build = function(ply)
            local order = {}
            for i = 1, #OPS do order[i] = i end
            for _, i in ipairs(Q.Shuffle(order)) do
                local spec = OPS[i] and OPS[i](ply)
                if spec then
                    local done = spec.stages[#spec.stages]
                    local prev = done.onDone
                    done.onDone = function(q, st)
                        if prev then prev(q, st) end
                        LC.Bump(q.owner, "ops")
                    end
                    return spec
                end
            end
            return nil
        end },
    },
}

------------------------------------------------------------------------
-- Mole Hunt: when suspicion catches up with you
------------------------------------------------------------------------

local function Expose(q, p)
    LC.StoryFlag(p, "exposed", true)
    LC.StoryFlag(p, "insider", false)
    q.chainEnd = "exposed"
    q.reward = 0
    Narrate(q, "He picks up your file instead. 'Interesting.' You've been exposed as the mole.")
    XP(p, -200)
    -- out of the system for good: wanted, no surrender, Resistance for life (sv_livingcity_insider.lua)
    timer.Simple(1, function() if IsValid(p) and LC.BurnInsider then LC.BurnInsider(p) end end)
    return "complete"
end

local function ClearSuspicion(p) LC.Bump(p, "suspicion", -LC.Counter(p, "suspicion")) end

------------------------------------------------------------------------
-- The loyalty test (the owner, 2026-11-01): suspicion too high, and the mole
-- hunt starts in a cell. A Resistance prisoner, your fists and nothing else,
-- and two prison guards with shotguns either side of you. Beat him for
-- answers and then kill him (suspicion cleared), or refuse and be executed.
-- Leaving the cell or raising a hand to a guard is refusing.
------------------------------------------------------------------------

local LT = {} -- [ply] = the scene: { q, spot, from, weps, ammo, prisoner, guards, phase }
LC.LoyaltyTests = LT
local cvWait = CreateConVar("lc_loyalty_wait", "15", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Minutes a loyalty test waits for a Resistance player to be caught and put in a cell (they're the prisoner then), before it uses an NPC")
LC.LoyaltyWaiting = LC.LoyaltyWaiting or {} -- [insider] = the job, while it waits for a real prisoner

local function RealRebel(p, notThis)
    return IsValid(p) and p:IsPlayer() and p ~= notThis and p:Alive() and p:GetNW2String("lcf_faction", "") == "resistance"
end
-- While a loyalty test waits, Civil Protection goes looking: a unit near a Resistance player almost always
-- stops and searches them (sv_livingcity_underground.lua asks). Nobody's told why.
function LC.LoyaltyHunt(ply)
    if not RealRebel(ply) then return false end
    for ins, q in pairs(LC.LoyaltyWaiting) do
        if IsValid(ins) and q and not q.done and ins ~= ply then return true end
        if not IsValid(ins) or not q or q.done then LC.LoyaltyWaiting[ins] = nil end
    end
    return false
end

local function LTCleanup(ply, restore)
    local sc = LT[ply]
    if not sc then return end
    LT[ply] = nil
    for _, g in ipairs(sc.guards or {}) do if IsValid(g) then SafeRemoveEntityDelayed(g, restore and 0.2 or 6) end end
    if sc.human then
        -- a real prisoner (if still alive) is let go of here and stays in custody
        if IsValid(sc.prisoner) then sc.prisoner:Freeze(false) sc.prisoner.lcLoyaltyPrisoner = nil end
    elseif IsValid(sc.prisoner) then
        SafeRemoveEntityDelayed(sc.prisoner, 8)
    end
    if not IsValid(ply) or not restore or not ply:Alive() then return end
    -- everything back as it was: their own gear, and where they came from
    ply:StripWeapons()
    for _, cls in ipairs(sc.weps or {}) do ply:Give(cls) end
    for id, n in pairs(sc.ammo or {}) do ply:SetAmmo(n, id) end
    if ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end
    if sc.from then ply:SetPos(sc.from) end
end
LC.LoyaltyTestCleanup = LTCleanup

-- Refused: the guards open up, and you go down bleeding on the cell floor. They don't let you die:
-- you're carried out, and the Combine make a stalker of you (the owner, 2026-11-01).
local function LTExecute(ply, why)
    local sc = LT[ply]
    if not sc or sc.phase == "executed" then return end
    sc.phase = "executed"
    if IsValid(ply) then ply:ChatPrint("[Loyalty test] " .. (why or "You refuse.") .. " The guards raise their shotguns.") end
    for _, g in ipairs(sc.guards) do
        if IsValid(g) then
            g:AddEntityRelationship(ply, D_HT, 99)
            if g.SetEnemy then g:SetEnemy(ply) end
            if g.SetSchedule then g:SetSchedule(SCHED_RANGE_ATTACK1 or 0) end
            g:EmitSound("weapons/shotgun/shotgun_fire" .. math.random(6, 7) .. ".wav", 90)
        end
    end
    LC.StoryFlag(ply, "insider", false)
    LC.StoryFlag(ply, "exposed", true)
    local q = sc.q
    if q and not q.done then q.chainEnd = "stalker" q.reward = 0 if LC.FinishQuest then LC.FinishQuest(q, true) end end
    timer.Simple(1.2, function()
        if not IsValid(ply) or not ply:Alive() then LTCleanup(ply, false) return end
        ply:SetHealth(math.min(ply:Health(), 5))
        ply:ViewPunch(Angle(-20, math.Rand(-10, 10), 0))
        ply:ScreenFade(SCREENFADE.OUT, Color(120, 0, 0, 200), 0.3, 2)
        ply:ChatPrint("[Loyalty test] You're down on the cell floor, bleeding out. They don't let you die. Someone lifts you by the arms.")
        ply:Freeze(true)
    end)
    timer.Simple(4, function()
        if IsValid(ply) then ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 6) ply:EmitSound("ambient/machines/spinup.wav", 70) end
    end)
    timer.Simple(9, function()
        LTCleanup(ply, false)
        if not IsValid(ply) or not ply:Alive() then return end
        ply:Freeze(false)
        ply:SetHealth(ply:GetMaxHealth())
        if LC.MakeStalker then LC.MakeStalker(ply) end
    end)
end
LC.LoyaltyTestExecute = LTExecute

-- The scene: in the cell, stripped to your fists, the prisoner in front, a guard either side.
local function LTSetup(q)
    local ply = q.owner
    if not IsValid(ply) then return end
    local spot = q.data.cell
    local fwd = Angle(0, q.data.yaw or 0, 0):Forward()
    local right = Vector(fwd.y, -fwd.x, 0)
    local sc = { q = q, spot = spot, from = q.data.from, phase = "choose", guards = {} }
    sc.weps = {}
    for _, w in ipairs(ply:GetWeapons()) do if w and w.GetClass then sc.weps[#sc.weps + 1] = w:GetClass() end end
    sc.ammo = ply.GetAmmo and ply:GetAmmo() or {}
    LT[ply] = sc
    ply:StripWeapons()
    ply:Give("weapon_fists")
    ply:SelectWeapon("weapon_fists")
    ply:SetPos(spot)
    ply:SetEyeAngles(Angle(0, q.data.yaw or 0, 0))
    -- a real prisoner: a Resistance player out of their cell and into this one, in front of the unit
    local hp = q.data.humanPrisoner
    if RealRebel(hp, ply) then
        hp:SetPos(spot + fwd * 60)
        hp:SetEyeAngles(Angle(0, (q.data.yaw or 0) + 180, 0))
        hp:Freeze(true)
        hp.lcLoyaltyPrisoner = ply
        sc.prisoner, sc.human = hp, true
        q.data.target = hp
        if LC.Notice then
            LC.Notice(hp, "warn", "Interrogation", "The Civil Protection unit in front of you is another player, and Internal Affairs is watching them. "
                .. "They've been told to get answers out of you, and then to finish you. Beg for your life, bargain, or refuse to say a word: it's up to you, and to them.", 16)
            LC.Notice(ply, "warn", "The prisoner is a player", "The prisoner in front of you is a real person, from the Resistance. Talk to them. Beat answers out of them, then finish it, or refuse.", 12)
        end
    end
    -- the prisoner: Resistance, bloodied, unarmed, kept on his feet through the beating
    local pnpc = (not sc.human) and LC.Spawners and LC.Spawners.citizen and LC.Spawners.citizen(spot + fwd * 60)
    if IsValid(pnpc) then
        local pst = LC.NPCs[pnpc]
        if pst then LC.SetState(pnpc, pst, "event") pst.eventUntil, pst.questLock, pst.unmanaged = CurTime() + 900, true, true end
        if pnpc.SetMaxHealth then pnpc:SetMaxHealth(100) end
        pnpc:SetHealth(100)
        if pnpc.SetSchedule then pnpc:SetSchedule(SCHED_IDLE_STAND) end
        LC.Face(pnpc, spot)
        LC.SetNPCStr(pnpc, "lc_doing", "a Resistance prisoner")
        pnpc.lcLoyaltyPrisoner = ply
        sc.prisoner = pnpc
        q.data.target = pnpc
    end
    -- the guards: Nova Prospekt's, shotguns, either side of you, not yet aiming at you
    for _, side in ipairs({ 1, -1 }) do
        local g = ents.Create("npc_combine_s")
        if IsValid(g) then
            local m = LC.CombineModel and LC.CombineModel("guard_shotgun", false) or "models/combine_soldier_prisonguard.mdl"
            if m and (not util.IsValidModel or util.IsValidModel(m)) then g:SetModel(m) end
            g:SetPos(spot + right * (55 * side) - fwd * 10)
            g:SetAngles(Angle(0, q.data.yaw or 0, 0))
            g:SetKeyValue("additionalequipment", "weapon_shotgun")
            g:Spawn()
            g:Activate()
            g:AddEntityRelationship(ply, D_LI, 99)
            if IsValid(pnpc) then g:AddEntityRelationship(pnpc, D_NU, 99) end
            g.lcLoyaltyGuard = ply
            sc.guards[#sc.guards + 1] = g
        end
    end
    ply:ChatPrint("[Loyalty test] The cell door shuts behind you. Your weapons are on a table outside. A guard either side of you, shotguns held low.")
end

hook.Add("EntityTakeDamage", "LivingCityLoyaltyTest", function(ent, dmg)
    local att = dmg:GetAttacker()
    -- shot down for refusing: bleeding, not dead (they want what's left of you)
    if IsValid(ent) and ent:IsPlayer() and LT[ent] and LT[ent].phase == "executed" then
        dmg:SetDamage(math.min(dmg:GetDamage(), math.max(0, ent:Health() - 5)))
        return
    end
    -- a hand raised to a guard: that's the answer
    if ent.lcLoyaltyGuard and IsValid(att) and att == ent.lcLoyaltyGuard then
        dmg:SetDamage(0)
        LTExecute(att, "You turn on the guard.")
        return true
    end
    local ply = ent.lcLoyaltyPrisoner
    local sc = ply and LT[ply]
    if not sc or att ~= ply then return end
    if sc.phase ~= "finish" then
        -- the interrogation: he takes the beating, and stays on his feet
        dmg:SetDamage(math.min(dmg:GetDamage(), math.max(0, ent:Health() - 25)))
        if sc.phase == "beat" then LC.QuestEvent("loyalty_hit", ply, ent) end
    end
end)
hook.Add("OnNPCKilled", "LivingCityLoyaltyTest", function(npc, attacker)
    local ply = npc.lcLoyaltyPrisoner
    local sc = ply and LT[ply]
    if sc and attacker == ply and sc.phase == "finish" then LC.QuestEvent("loyalty_kill", ply, npc) end
end)
hook.Add("PlayerDeath", "LivingCityLoyaltyTest", function(ply, _, attacker)
    -- the real prisoner, finished by the unit
    local ins = ply.lcLoyaltyPrisoner
    local sc = ins and LT[ins]
    if sc and attacker == ins and sc.phase == "finish" then ply.lcLoyaltyPrisoner = nil LC.QuestEvent("loyalty_kill", ins, ply) end
    if LT[ply] then LTCleanup(ply, false) end
end)
hook.Add("PlayerDisconnected", "LivingCityLoyaltyTest", function(ply) if LT[ply] then LTCleanup(ply, false) end end)

-- No ignoring it: after the loyalty test, the reckoning starts by itself, and so does the debt (the owner:
-- the Resistance would want answers). Whatever job they're on is dropped for it.
-- The soldier conversion, forced: the transhuman conditioning and the Soldier rank, for good.
function LC.MoleConvert(p)
    if not IsValid(p) then return end
    if LC.Condition then LC.Condition(p) end
    local f = LCF and LCF.Get and LCF.Get("cp")
    local need = f and f.ranks and f.ranks[5] and f.ranks[5].xp
    if need and (tonumber(p:GetPData("lcf_xp_cp", 0)) or 0) < need then p:SetPData("lcf_xp_cp", need) end
    if LC.AddXP then LC.AddXP(p, 0, "the conversion") end
    if LC.Notice then LC.Notice(p, "warn", "The conversion", "You proved your loyalty, so Overwatch wants all of you. They come for you that night: the surgery is done before you wake. A soldier now, and there's no going back.", 14) end
end

local function ForceMoleHunt(ply, tries)
    tries = tries or 0
    if not IsValid(ply) or tries > 20 then return end
    local cs = LC.ChainState(ply, "molehunt")
    if not cs or not cs.part or cs.done or (cs.part ~= "reckoning" and cs.part ~= "debt" and cs.part ~= "raid") then return end
    local busy = LC.QuestOf and LC.QuestOf[ply]
    if busy and not busy.done and busy.chain == "molehunt" then return end
    if not ply:Alive() or (LC.InCustody and LC.InCustody(ply)) then
        timer.Simple(30, function() ForceMoleHunt(ply, tries + 1) end)
        return
    end
    if busy and not busy.done and LC.AbandonQuest then LC.AbandonQuest(ply) ply.lcqNext = 0 end
    cs.readyAt = 0
    if ply.lcStoryPostings then ply.lcStoryPostings.molehunt = nil end
    if LC.StoryPostings then LC.StoryPostings(ply) end
    local post = ply.lcStoryPostings and ply.lcStoryPostings.molehunt
    if not post or not LC.AcceptPosting or not LC.AcceptPosting(ply, post.id) then
        timer.Simple(30, function() ForceMoleHunt(ply, tries + 1) end)
        return
    end
    if LC.Notice then
        LC.Notice(ply, "warn", "The Resistance wants answers", cs.part == "debt" and "The debt starts now. They're watching." or (cs.part == "raid" and "Overwatch wants proof. A sweep team is waiting for you." or "A note in your locker: they know what you did in that cell. They want to see you, now."), 10)
    end
end
LC.ForceMoleHunt = ForceMoleHunt
hook.Add("LivingCityQuestComplete", "LivingCityMoleHuntForced", function(p, q)
    if q and q.chain == "molehunt" and (q.chainNext == "reckoning" or q.chainNext == "debt" or q.chainNext == "raid") then
        timer.Simple(12, function() ForceMoleHunt(p) end)
    end
end)
hook.Add("LivingCityQuestFailed", "LivingCityMoleHuntForced", function(p, q)
    if q and q.chain == "molehunt" and (q.chainPart == "reckoning" or q.chainPart == "debt" or q.chainPart == "raid") then
        timer.Simple(20, function() ForceMoleHunt(p) end)
    end
end)

local function TestSpec(ply)
    local cells = LC.PointsOfKind("cell")
    if #cells == 0 then return nil end
    local c = Pick(cells)
    local spot = LC.GroundAt and LC.GroundAt(c.pos + Vector(0, 0, 30)) or c.pos
    -- with Resistance players in the city, the test waits for one of them to be caught (the owner: a real
    -- person in the chair); the units go looking meanwhile. Otherwise, or if nobody's caught in time, an NPC.
    local rebels = 0
    for _, p in ipairs(player.GetAll()) do if RealRebel(p, ply) then rebels = rebels + 1 end end
    local wait = rebels > 0 and cvWait:GetFloat() > 0
    local first = wait and Count("loyalty_prisoner", 1, "Internal Affairs is bringing a Resistance prisoner in. Carry on, and wait to be called to the cells")
        or Goto(spot, "Report to the cells (marked)", 220)
    return {
        title = "The loyalty test", reward = 40, limit = wait and (cvWait:GetFloat() * 60 + 420) or 420,
        desc = "Internal Affairs has a prisoner from the Resistance, and a question about you." .. (wait and " You'll be called to the cells." or (" Report to the cells " .. Place(spot, ply:GetPos()) .. ".")),
        data = { cell = spot, yaw = c.yaw or 0, wait = wait, waitUntil = wait and (CurTime() + cvWait:GetFloat() * 60) or nil },
        stages = {
            first,
            Choice("The prisoner looks up at you through one swollen eye. The guard on your left speaks without looking at you: 'He knows who the mole is. "
                .. "Get it out of him. Then finish it.' The other guard's shotgun is pointed at the floor. For now.", {
                { text = "Interrogate him. With your fists.", pick = function(q, p)
                    local sc = LT[p]
                    if sc then sc.phase = "beat" end
                    Narrate(q, "You close your fists. He knows what's coming.")
                    Insert(q, {
                        Count("loyalty_hit", 6, "Beat answers out of him (punch him, 6 times)", nil, false),
                        Count("loyalty_kill", 1, "He's told you everything he will. Finish it: kill him"),
                    })
                end },
                { text = "Refuse. You won't do it.", pick = function(q, p) LTExecute(p, "You lower your hands.") end },
            }),
        },
        tick = function(q)
            local p = q.owner
            -- waiting for a real prisoner: the first Resistance player in a cell; or, out of time, an NPC
            if q.data.wait and q.stage == 1 and IsValid(p) then
                if not LC.LoyaltyWaiting[p] then
                    LC.LoyaltyWaiting[p] = q
                    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: Internal Affairs wants a member of the Resistance taken alive and put in the cells.") end
                end
                local caught
                for _, r in ipairs(player.GetAll()) do
                    if RealRebel(r, p) and LC.Prisoners and LC.Prisoners[r] and not r.lcLoyaltyPrisoner then caught = r break end
                end
                if caught or CurTime() > (q.data.waitUntil or 0) then
                    LC.LoyaltyWaiting[p] = nil
                    q.data.humanPrisoner = caught
                    q.data.from = p:GetPos()
                    LC.QuestEvent("loyalty_prisoner", p, caught or p)
                end
                return
            end
            if IsValid(p) then LC.LoyaltyWaiting[p] = nil end
            local sc = IsValid(p) and LT[p]
            if not sc and q.stage >= 2 and IsValid(p) and not q.data.setUp then q.data.setUp = true LTSetup(q) return end
            if not sc then return end
            -- after the beating, the last of it
            if sc.phase == "beat" and q.stages[q.stage] and q.stages[q.stage].event == "loyalty_kill" then
                sc.phase = "finish"
                Narrate(q, "He gives you a name. It's yours, though he doesn't know it. Then nothing more. 'Finish it,' says the guard.")
            end
            -- leaving the cell is refusing
            if sc.phase ~= "executed" and p:GetPos():DistToSqr(sc.spot) > 140 * 140 then LTExecute(p, "You try to leave.") end
        end,
        onFinish = function(q, success)
            local p = q.owner
            local sc = IsValid(p) and LT[p]
            if not sc then return end
            if success and sc.phase == "finish" then
                ClearSuspicion(p)
                Trait(p, "loyalty", 2)
                -- you killed one of theirs: the Resistance wants a word (the reckoning, next on your board)
                LC.StoryFlag(p, "disgraced", true)
                q.chainNext = "reckoning"
                p:ChatPrint("[Loyalty test] The guard lowers his shotgun. 'Welcome back, officer.' Your weapons are handed back at the door.")
                LTCleanup(p, true)
            elseif sc.phase ~= "executed" then
                LTExecute(p, "You took too long.")
            end
        end,
    }
end
LC.LoyaltyTestSpec = TestSpec

LC.Chain{
    id = "molehunt", name = "Mole Hunt", factions = { cp = true },
    unlock = function(ply) return LC.StoryFlag(ply, "insider") == true and LC.Counter(ply, "suspicion") >= 3 end,
    start = "hunt",
    endings = {
        passed = "You passed their test. The prisoner's blood is on your hands, and nobody in Civil Protection doubts you now.",
        converted = "You let the Combine have all of you. The surgery took the rest: a soldier of Overwatch now, and nothing you were before. There's no going back.",
        redeemed = "The debt is paid. They don't forget what you did in that cell, but they let you back in. The Resistance has its man inside again.",
        executed = "You wouldn't do it. The guards did their duty. They found the mole, in the end.",
        stalker = "You wouldn't do it. They shot you down on the cell floor and didn't let you die. What's left of you belongs to the Combine now.",
        unmasked = "You took off the mask for good. No more lies: you fight with the Resistance in the open now, and Civil Protection will never have you back.",
        framed = "Unit 3-09 was taken in your place. You tell yourself he probably deserved it.",
        ran = "You fled to the Resistance before they could knock. Every Civil Protection unit in the city has your face now.",
        survived = "The mole hunt moves on to another sector. You breathe again. Carefully.",
        exposed = "Exposed as the mole, you're stripped of rank and mask. A citizen again, with a file that will never close.",
    },
    parts = {
        -- after the loyalty test: you killed one of theirs, and the Resistance knows
        reckoning = { num = 2, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            return {
                title = "The reckoning", reward = 0, limit = 900,
                desc = "Word reaches you through a note in your locker: the Resistance knows what you did in that cell. They want to see you (" .. where .. "). Until this is settled, they won't work with you.",
                stages = {
                    Goto(pos, "Go to the meeting place (" .. where .. ")", r),
                    Meet("Find the woman from the note and walk up to her", "citizen", function() return pos end, nil, nil, "female"),
                    Choice("She doesn't sit down. 'He was one of ours. You beat him, and then you killed him, to keep your mask. Maybe you had to.' "
                        .. "Her hand doesn't leave her pocket. 'We want answers. Are you still with us? Then you'll pay for him. Or are you theirs now?'", {
                        { text = "Pay the debt. Whatever it takes. (It starts at once.)", pick = function(q)
                            Narrate(q, "'Then listen.' She tells you what it will cost.")
                            q.chainNext = "debt"
                        end },
                        { text = "Take off the mask for good: leave Civil Protection and fight with the Resistance in the open. (You'll never be a unit, or anyone's man inside, again.)", pick = function(q, p)
                            q.chainEnd = "unmasked"
                            LC.StoryFlag(p, "insider", false)
                            LC.StoryFlag(p, "disgraced", false)
                            timer.Simple(1.5, function() if IsValid(p) and LC.Unmask then LC.Unmask(p) end end)
                        end },
                        { text = "Tell her you're done with the Resistance. (You stay with the Combine. They'll want proof, and then all of you.)", pick = function(q, p)
                            LC.StoryFlag(p, "insider", false)
                            LC.StoryFlag(p, "disgraced", false)
                            if #(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) > 0 then
                                Narrate(q, "You walk out. Before morning, Overwatch has orders for you: they want proof.")
                                q.chainNext = "raid"
                            else
                                q.chainEnd = "converted"
                                timer.Simple(1.5, function() if IsValid(p) then LC.MoleConvert(p) end end)
                            end
                        end },
                    }),
                },
            }
        end },

        -- done with the Resistance: the Combine want proof first. In with a sweep team, two of their fighters down,
        -- and then the conversion (the owner: they'd push you further before they took all of you)
        raid = { num = 4, build = function(ply)
            local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
            if #zones == 0 then return nil end
            local z = zones[math.random(#zones)]
            local go = Goto(z.pos, "Join the sweep team at the edge of anticitizen territory (marked)", math.max(500, (z.r or 300) + 300))
            go.onEnter = function() if not LC.Skirmish and LC.StartCombineSweep then pcall(LC.StartCombineSweep, z) end end
            local zr = (z.r or 300) + 800
            return {
                title = "Proof", reward = 40, limit = 900,
                desc = "You told the Resistance you're done with them. Overwatch wants proof: go in with the sweep team on their ground " .. Place(z.pos, ply:GetPos()) .. ", and put down two of their fighters.",
                stages = {
                    go,
                    Count("killed", 2, "Take down two of the Resistance's fighters there", function(_, _, npc)
                        local st = LC.NPCs[npc]
                        return st ~= nil and st.role == "rebel" and IsValid(npc) and npc:GetPos():DistToSqr(z.pos) < zr * zr
                    end),
                },
                onFinish = function(q, success)
                    if not success then return end
                    q.chainEnd = "converted"
                    local p = q.owner
                    timer.Simple(3, function() if IsValid(p) then LC.MoleConvert(p) end end)
                end,
            }
        end },

        -- the blood debt: a life for a life, out of the cells
        debt = { num = 3, build = function(ply)
            local dest, r, where = Q.SafeHouse(ply)
            if not dest then return nil end
            if #LC.PointsOfKind("cell") > 0 then
                return {
                    title = "A blood debt", reward = 40, limit = 720,
                    desc = "A life for a life: get one of theirs out of the cells and walk them to safety (" .. where .. "). Don't let another Civil Protection unit see you.",
                    stages = {
                        FreePrisonerStage("Go to the cells and press E on the marked prisoner to unlock their cell"),
                        { kind = "escort", pos = dest, r = r, vanish = true, text = "Lead the prisoner to safety (" .. where .. "). They follow you: act like it's routine",
                          onEnter = function(q, st) st.npc = q.data.target; if not IsValid(st.npc) then return false end end },
                    },
                    tick = Witnessed({ escort = true }, "A Civil Protection unit saw you walking a prisoner out. He'll remember."),
                    onFinish = function(q, success) if success then q.chainEnd = "redeemed" LC.StoryFlag(q.owner, "disgraced", false) end end,
                }
            end
            local center = Q.Spot(ply, 500, 2000)
            if not center then return nil end
            local item = Pick(Q.CONTRABAND)
            return {
                title = "A blood debt", reward = 40, limit = 600,
                desc = "Make it right: what Civil Protection seized from the Resistance this week is lying " .. Place(center, ply:GetPos()) .. ". Get it back to them (" .. where .. ").",
                stages = {
                    { kind = "collect", spots = Q.HideSpots(center, 3, 500), model = item[2], need = 3, text = "Find the 3 seized crates and press E on each" },
                    Deliver(dest, "Take them to the Resistance (" .. where .. ")", r),
                },
                tick = Witnessed({ deliver = true }, "A Civil Protection unit saw you heading the wrong way with seized goods."),
                onFinish = function(q, success) if success then q.chainEnd = "redeemed" LC.StoryFlag(q.owner, "disgraced", false) end end,
            }
        end },

        hunt = { num = 1, build = function(ply)
            -- the loyalty test, in the cells; a map with no cells has the briefing instead
            local test = TestSpec(ply)
            if test then return test end
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "The briefing", reward = 30, limit = 480,
                desc = "Internal Affairs believes there's a mole in your division, and wants your help finding them. The mole is you.",
                stages = {
                    Goto(pos, "Go to the marked spot for the briefing", 260),
                    Meet("Walk up to the Internal Affairs officer", "cop", function() return pos end),
                    Choice("The officer spreads three files across the hood of an APC. One of them is yours. He hasn't noticed. Yet.", {
                        { text = "Steer him toward another Civil Protection unit's file, so they take the blame.", check = { "guile", 14 },
                          success = function(q, p)
                              Trait(p, "corruption", 1)
                              ClearSuspicion(p)
                              q.chainEnd = "framed"
                          end,
                          fail = function(q, p) return Expose(q, p) end },
                        { text = "Excuse yourself. Run to the Resistance tonight (you'll be wanted for desertion).", pick = function(q, p)
                            q.chainEnd = "ran"
                            LC.StoryFlag(p, "insider", false)
                            JoinLater(p, "resistance", 400)
                            timer.Simple(3, function() if IsValid(p) then LC.ReportCrime(p, "Desertion", 600) end end)
                        end },
                        { text = "Keep your head down and ride it out.", check = { "nerve", 13 },
                          success = function(q, p)
                              ClearSuspicion(p)
                              q.chainEnd = "survived"
                          end,
                          fail = function(q, p) return Expose(q, p) end },
                    }),
                },
            }
        end },
    },
}

-- If you live through a mole hunt, Internal Affairs can always come back.
hook.Add("LivingCityStoryEnded", "LivingCityMoleHuntReturns", function(ply, chainId, ending)
    if chainId == "molehunt" and (ending == "framed" or ending == "survived" or ending == "redeemed") then
        local s = LC.Story(ply)
        s.chains.molehunt = nil
        s.notified.molehunt = nil
        LC.SaveStory(ply)
    end
end)

-- Rebels a unit has killed lately (The Man Inside's gate).
function LC.RecentRebelKills(ply)
    local n, now = 0, CurTime()
    for _, t in ipairs(ply.lcRebelKills or {}) do if now - t < 1800 then n = n + 1 end end
    return n
end
hook.Add("OnNPCKilled", "LivingCityRebelKillsTally", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "rebel" or not IsValid(attacker) or not attacker:IsPlayer() or not LC.PlayerIsCP(attacker) then return end
    attacker.lcRebelKills = attacker.lcRebelKills or {}
    table.insert(attacker.lcRebelKills, CurTime())
    while #attacker.lcRebelKills > 10 do table.remove(attacker.lcRebelKills, 1) end
    if LC.RecentRebelKills(attacker) >= 3 and attacker.lcStoryPostings then attacker.lcStoryPostings.inside = nil end
end)
