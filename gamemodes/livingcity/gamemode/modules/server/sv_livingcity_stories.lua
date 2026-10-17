--[[
    Living City: story chains

    Personal, multi-part stories that unlock from what you've actually done.
    They appear at the top of your board (F3) marked as Story, only for you.
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
        stages[i] = Goto(sp, string.format("%s %d of %d, %s", label or "Patrol stop", i, n, Place(sp, ply:GetPos())), 150)
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
        end
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
    Narrate(q, "The window across the street flashes. Internal Affairs was watching the whole time.")
    XP(p, -100)
    if LC.PrisonAvailable() then LC.Incarcerate(p, 120, "Corruption", nil) end
    return "complete"
end

local function RefuseBribe(q, p)
    Trait(p, "loyalty", 1)
    q.data.target = q.data.actor
    q.chainEnd = "cleared"
    Insert(q, { Q.ArrestStage("Arrest him for attempted bribery (right click)") })
end

LC.Chain{
    id = "ia", name = "Internal Affairs", factions = { cp = true, ota = true },
    unlock = function(ply) return LC.Trait(ply, "corruption") >= 2 or LC.Counter(ply, "bribes") >= 2 end,
    start = "summons",
    endings = {
        redeemed = "Your file is closed. Somewhere, a number is quietly reset.",
        cleared = "Internal Affairs found nothing. This time.",
        busted = "Caught in the act. Your record will follow you.",
        informer = "Someone else is paying for what you did.",
        demoted = "You lost your rank. You kept your conscience. In this city that is a bad trade, and you made it anyway.",
        untouchable = "They'll never prove anything. They'll never stop watching.",
        ring = "You work for them now. The money is very good.",
        double = "You played both sides and walked away. For now.",
        burned = "Internal Affairs knows exactly what you did with their crate.",
    },
    parts = {
        summons = { num = 1, build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "A quiet word", reward = 10, limit = 480,
                desc = "You've been summoned " .. Place(pos, ply:GetPos()) .. ". The message didn't say by whom. It didn't have to.",
                stages = {
                    Goto(pos, "Report as summoned", 260),
                    Meet("Speak with the officer waiting for you", "cop", function() return pos end),
                    Choice("The officer doesn't give a Civil Protection unit number. 'Your ration ledger doesn't add up, unit. " ..
                        "Neither do the citizens who keep walking free on your shift.'", {
                        { text = "Confess. Ask for a chance to make it right.", pick = function(q, p)
                            Trait(p, "corruption", -1)
                            Trait(p, "loyalty", 1)
                            Narrate(q, "He nods slowly. 'Then make it right. By the book, every step. We'll be counting.'")
                            q.chainNext = "penance"
                        end },
                        { text = "Explain it away.", check = { "guile", 13 },
                          success = function(q)
                              Narrate(q, "He writes something down. 'We'll be in touch.' It doesn't sound like a dismissal.")
                              q.chainNext = "audit"
                          end,
                          fail = function(q)
                              Narrate(q, "He doesn't even pretend to believe you. 'Someone will be keeping an eye on you, Civil Protection unit.'")
                              q.chainNext = "watched"
                          end },
                        { text = "Offer him a cut.", when = function(q) return LC.Trait(q.owner, "corruption") >= 3 end,
                          pick = function(q, p)
                              Trait(p, "corruption", 1)
                              Narrate(q, "A long pause. Then he laughs, and holds out his hand.")
                              q.chainNext = "ring"
                          end },
                    }),
                },
            }
        end },

        penance = { num = 2, build = function(ply)
            local stages = Patrol(ply, 3, "Clean patrol, stop")
            if not stages then return nil end
            local inspect = Count("used_npc", 3, "Inspect three citizens. Properly.", Q.IsCitizenNPC)
            inspect.onDone = function(q)
                q.chainEnd = "redeemed"
                Trait(q.owner, "corruption", -2)
            end
            return {
                title = "Penance", reward = 40, limit = 600,
                desc = "Internal Affairs wants to see a model officer. Show them one.",
                stages = Append(stages, { inspect }),
            }
        end },

        audit = { num = 2, build = function(ply)
            local spot = Q.Spot(ply, 400, 2000)
            if not spot then return nil end
            return {
                title = "The audit", reward = 30, limit = 480,
                desc = "A routine patrol " .. Place(spot, ply:GetPos()) .. ". Nothing to worry about.",
                stages = {
                    Goto(spot, "Patrol the market", 200),
                    Meet("A citizen is waving you over", "citizen", function() return spot end, nil, nil, "male"),
                    Choice("A citizen presses a bundle of ration units into your hand. 'For your trouble, officer.' " ..
                        "His eyes flick to a window across the street.", {
                        { text = "Refuse, and arrest him for attempted bribery.", pick = RefuseBribe },
                        { text = "Take it.", pick = TakeBribe },
                        { text = "Glance at that window.", check = { "authority", 12 },
                          success = function(q, p)
                              Trait(p, "loyalty", 2)
                              q.bonus = 20
                              q.chainEnd = "cleared"
                              Narrate(q, "A lens glints behind the glass. A test. You hand the bundle back, loudly, and thank him for his loyalty.")
                              return "complete"
                          end,
                          fail = function(q)
                              Narrate(q, "Just a window. The bundle is still in your hand, and he's still waiting.")
                              Insert(q, { Choice("He's still waiting. The bundle is still warm.", {
                                  { text = "Refuse, and arrest him.", pick = RefuseBribe },
                                  { text = "Take it.", pick = TakeBribe },
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
            stages[#stages + 1] = Count("used_npc", 2, "Inspect two citizens while he watches", Q.IsCitizenNPC)
            stages[#stages + 1] = Choice("The Civil Protection unit who has followed you all shift finally speaks. " ..
                "'Name another Civil Protection unit who takes. Or we keep looking at you.'", {
                { text = "Give them a name.", pick = function(q, p)
                    Trait(p, "loyalty", 1)
                    q.chainEnd = "informer"
                    Narrate(q, "Unit 4-17 is reassigned to the canals the next morning. You don't see him again.")
                end },
                { text = "Take the fall.", pick = function(q, p)
                    XP(p, -100)
                    Trait(p, "corruption", -3)
                    q.chainEnd = "demoted"
                end },
                { text = "Stare at the mask until he leaves.", check = { "nerve", 14 },
                  success = function(q, p) Trait(p, "corruption", 1) q.chainEnd = "untouchable" end,
                  fail = function(q, p)
                      Narrate(q, "You blink first.")
                      XP(p, -100)
                      q.chainEnd = "demoted"
                  end },
            })
            return {
                title = "Under watch", reward = 35, limit = 720,
                desc = "Internal Affairs has assigned you a shadow. Do your job. Do it well.",
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
                title = "The ring", reward = 60, limit = 600,
                desc = "Your new friends need something moved. Quietly. Pick it up " .. Place(a, ply:GetPos()) .. ".",
                stages = {
                    Q.Contact("Collect the crate from your new friends (press E)", a, "citizen", "'Careful with that one. It's not what the label says.'"),
                    Choice("The crate rattles. Weapons. Rebel weapons, sold by the people whose job is hunting rebels.", {
                        { text = "Deliver it. Business is business.", pick = function(q, p)
                            Trait(p, "corruption", 1)
                            q.chainEnd = "ring"
                        end },
                        { text = "Dump it in the canal and report it seized.", check = { "guile", 14 },
                          success = function(q, p)
                              Trait(p, "loyalty", 1)
                              Trait(p, "sympathy", 1)
                              q.chainEnd = "double"
                              Narrate(q, "The crate sinks. Your report is a work of art.")
                              return "complete"
                          end,
                          fail = function(q, p)
                              Narrate(q, "Internal Affairs finds out within the hour.")
                              XP(p, -150)
                              if LC.PrisonAvailable() then LC.Incarcerate(p, 90, "Theft from Internal Affairs", nil) end
                              q.reward = 0
                              q.chainEnd = "burned"
                              return "complete"
                          end },
                    }),
                    Q.Contact("Hand the crate to the buyer " .. Place(b, ply:GetPos()) .. " (press E)", b, "citizen", "The buyer doesn't count the money in front of you. That's how you know it's a lot."),
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
        joined = "You are Resistance now. Your old life is a cover story.",
        ally = "A friend of the Resistance. They'll call on you.",
        reported = "The stranger never came back. Neither did the family in 4C.",
        walked_away = "Some doors stay shut.",
    },
    parts = {
        knock = { num = 1, build = function(ply)
            local home, name = HomeOf(ply)
            if not home then return nil end
            return {
                title = "A knock at night", reward = 10, limit = 420,
                desc = "Go home to " .. name .. ". Someone is waiting.",
                stages = {
                    Goto(home, "Go home to " .. name, 260),
                    Meet("Someone is waiting outside your door", "citizen", function() return home end, nil, nil, "male"),
                    Choice("A stranger in a Union jacket that doesn't fit him. He says your name like he's known it for years. " ..
                        "'You've been kind to the wrong people. We noticed. Can you be useful, too?'", {
                        { text = "Listen.", pick = function(q)
                            Narrate(q, "He talks for a long time. Mostly about you.")
                            q.chainNext = "nerve"
                        end },
                        { text = "Report him to Civil Protection.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            LC.Bump(p, "reports")
                            q.chainEnd = "reported"
                            Narrate(q, "He sees it in your face before you move. He's gone by the time you turn around.")
                            Insert(q, { Count("used_npc", 1, "Report the stranger to a Civil Protection unit (press E)", Q.IsCopNPC) })
                        end },
                        { text = "Shut the door.", pick = function(q)
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
                desc = "Carry a parcel across the district. Don't open it. Don't get caught.",
                stages = {
                    Q.Contact("Take the parcel from your contact (press E)", a, "citizen", "'Straight there. Don't open it. Don't be late.'", { rebel = true }),
                    Choice("Two Civil Protection units are checking papers at the corner ahead.", {
                        { text = "Walk past them, calmly.", check = { "guile", 11 },
                          success = function(q) Narrate(q, "One of them looks right at you. Then past you.") end,
                          fail = function(q, p)
                              Narrate(q, "'Citizen! Stop!' You don't.")
                              LC.ReportCrime(p, "Carrying contraband", 120)
                          end },
                        { text = "Take the long way, through the alleys.", pick = function(q)
                            if detour then Insert(q, { Goto(detour, "Take the long way round", 180) }) end
                        end },
                    }),
                    Deliver(b, "Leave it at the dead drop " .. Place(b, ply:GetPos()), 150),
                },
            }
        end, next = "decision" },

        decision = { num = 3, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            return {
                title = "The choice", reward = 25, limit = 600,
                desc = "They want to meet you in " .. where .. ". In person, this time.",
                stages = {
                    Goto(pos, "Go to the meeting in " .. where, r),
                    Meet("Find the stranger", "citizen", function() return pos end),
                    Choice("The stranger is waiting with two others. One of them wears the lambda openly. 'Well?'", {
                        { text = "I'm with you.", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            q.chainEnd = "joined"
                            JoinLater(p, "resistance", 150)
                        end },
                        { text = "Not yet. But I'll help when I can.", pick = function(q, p)
                            Trait(p, "sympathy", 1)
                            q.chainEnd = "ally"
                        end },
                        { text = "I've changed my mind.", pick = function(q) q.chainEnd = "walked_away" end },
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
        failText = "your neighbor isn't out on the streets right now. Try again once the city is busy",
        text = "Follow your neighbor without being noticed",
        onEnter = function(q, st)
            local npc = q.data.target
            if not IsValid(npc) then npc = Q.RandomCitizen() end
            if not npc then return false end
            Q.Lock(q, npc)
            q.data.target = npc
            st.npc = npc
            st.text = Neighbor(q, "Follow your neighbor without being noticed. Not too far, and stay out of {his} sight: the longer {he} sees you, the more suspicious {he} gets")
            local nst = LC.NPCs[npc]
            if nst then nst.eventUntil = 0; LC.GoTo(npc, nst, LC.RandomWanderPos("citizen"), false, nil) end
        end,
        onNoticed = function(q)
            Insert(q, { Choice(Neighbor(q, "{He} stops and turns around. {He} knows exactly who you are."), {
                { text = "Pretend you were heading the other way.", check = { "guile", 12 },
                  success = function(q2)
                      Narrate(q2, Neighbor(q2, "{He} shrugs and walks on. You give {him} a longer leash."))
                      Insert(q2, { TailStage(20) })
                  end,
                  fail = function(q2)
                      Narrate(q2, Neighbor(q2, "{He} doesn't buy it. {He} runs."))
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
        paid = "Double rations. Your neighbors have started saying good morning a little too carefully.",
        brother = "Your brother comes home thinner and quieter, and never asks how.",
        brother_lost = "Now they're watching your brother too. Because of you.",
        zealot = "The city has no truer friend. The city does not have friends.",
    },
    parts = {
        eyes = { num = 1, next = "neighbor", build = function(ply)
            local s = Q.Spot(ply, 400, 2500)
            if not s then return nil end
            return {
                title = "Eyes and ears", reward = 20, limit = 480,
                desc = "The Union asks its friends to keep watch " .. Place(s, ply:GetPos()) .. ".",
                stages = {
                    Goto(s, "Go and keep watch", 180),
                    Hold(s, 15, "Watch the comings and goings", 260),
                    Count("used_npc", 1, "Tell a Civil Protection unit what you saw (press E)", Q.IsCopNPC),
                },
            }
        end },

        neighbor = { num = 2, next = "payment", build = function()
            if not LC.Running or not Q.RandomCitizen() then return nil end -- nobody out to follow yet
            local report = Count("used_npc", 1, "Report your neighbor to a Civil Protection unit (press E)", Q.IsCopNPC)
            report.onEnter = function(q, st) st.text = Neighbor(q, "Report {him} to a Civil Protection unit (press E)") end
            report.onDone = function(q)
                local npc = q.data.target
                local line = Neighbor(q, "By evening, {his} door is sealed with yellow tape.") -- before the arrest takes them away
                if IsValid(npc) and LC.PrisonAvailable() and LC.ArrestNPC then LC.ArrestNPC(npc, nil) end
                Narrate(q, line)
            end
            return {
                title = "The neighbor", reward = 35, limit = 720,
                desc = "Your neighbor has been keeping strange hours. The Union would like to know where they go.",
                stages = { TailStage(40), report },
            }
        end },

        payment = { num = 3, build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Payment", reward = 40, limit = 480,
                desc = "Collect what you're owed " .. Place(pos, ply:GetPos()) .. ".",
                stages = {
                    Goto(pos, "Go to collect your payment", 260),
                    Count("used_npc", 1, "Speak with an officer (press E)", Q.IsCopNPC),
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
                                  if IsValid(npc) and st.state == "jailed" then LC.ReleaseNPCPrisoner(npc, st, CurTime()) break end
                              end
                              Narrate(q, "A name is typed. Somewhere below your feet, a cell door opens.")
                          end,
                          fail = function(q)
                              q.chainEnd = "brother_lost"
                              Narrate(q, "'Your brother? Interesting. We'll look into him too.'")
                          end },
                        { text = "Refuse it. You did it for the city.", pick = function(q, p)
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
    rebels = "Lambda graffiti on the wall, the paint still wet. Drag marks lead toward the canals.",
    infestation = "Headcrab shells, cracked open. A lot of them. His stunstick is bent nearly in half.",
    deserted = "His mask is folded neatly on the ground. Like he took it off himself, and didn't want it damaged.",
}

LC.Chain{
    id = "missing", name = "The Missing Civil Protection unit", factions = { cp = true },
    unlock = function(ply)
        return Q.RankIndex(ply) >= 3 or (tonumber(ply:GetPData("lcq_done", 0)) or 0) >= 4
    end,
    start = "dark",
    endings = {
        silenced = "The radio is silent. So, for a while, is the Resistance.",
        counterintel = "For a week, the Resistance follows your orders. Overwatch notices.",
        mercy = "You file his tags with the others. Nobody asks how he died.",
        left = "Overwatch cleans the area. They don't find him. You don't tell them where to look.",
        brought_in = "He's processed by morning. You never learn what happened to his daughter.",
        let_go = "Your report says killed in action. You'll never be sure that was a kindness.",
        defected = "Somewhere in the canals, a man with a CP haircut is teaching rebels how Civil Protection units think.",
        fled = "He's out there somewhere, and now he knows your face.",
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
                desc = "Unit 6-12 stopped answering dispatch " .. Place(spot, ply:GetPos()) .. ". Find out why.",
                stages = {
                    Goto(spot, "Go to 6-12's last known position", 260),
                    { kind = "collect", spots = Q.HideSpots(spot, 2, 500), need = 2,
                      models = { "models/weapons/w_stunbaton.mdl", "models/props_c17/paper01.mdl" },
                      text = "Search the area for 6-12's things (press E)" },
                    Choice(CAUSE_PROMPTS[data.cause], {
                        { text = "Report it up the chain.", pick = function(q) q.chainNext = nextPart end },
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
                return {
                    title = "What's left of him", reward = 40, limit = 600,
                    desc = "The trail leads into the infestation.",
                    stages = {
                        Goto(z.pos, "Enter the infestation", math.max(200, z.r)),
                        Count("killed", 3, "Fight your way through", function(_, _, npc) return Q.IsZombieNPC(npc) end),
                        Choice("Among the infested, a familiar uniform. His mask is still on.", {
                            { text = "Put him down yourself.", pick = function(q) q.chainEnd = "mercy" end },
                            { text = "Leave him for Overwatch.", pick = function(q) q.chainEnd = "left" end },
                        }),
                    },
                }
            end
            local z = Pick(LC.ZonesOfKind("rebel"))
            local enter = Goto(z.pos, "Enter rebel territory. They'll be waiting", math.max(150, z.r * 0.8))
            -- the people who took him are in there, and they're armed
            enter.onEnter = function() if LC.ReinforceRebels then LC.ReinforceRebels(z, 3) end end
            return {
                title = "Retaliation", reward = 40, limit = 600,
                desc = "The drag marks lead into rebel territory. Go in, and hold long enough to find something. Expect a fight.",
                stages = {
                    enter,
                    { kind = "survive", secs = 45, text = "Search rebel territory (they know you're here)",
                      cond = function(_, p) return LC.InRebelZone(p:GetPos()) end },
                    Choice("You find his radio in a stairwell, still switched on. Someone has been listening to Civil Protection frequencies all week.", {
                        { text = "Smash it.", pick = function(q) q.chainEnd = "silenced" end },
                        { text = "Leave it on, and feed them false orders.", check = { "guile", 13 },
                          success = function(q, p) Trait(p, "loyalty", 2) q.bonus = 30 q.chainEnd = "counterintel" end,
                          fail = function(q)
                              Narrate(q, "They stop transmitting the moment you touch it.")
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
                desc = "A citizen with a Civil Protection haircut was seen " .. Place(spot, ply:GetPos()) .. ".",
                stages = {
                    Meet("Find the man in the stolen coat (marked)", "citizen", function() return spot end, nil, nil, "male"),
                    Choice("It's him. 6-12, in a stolen coat, his haircut already growing out. 'Please. I have a daughter in Block 4.'", {
                        { text = "Bring him in.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            q.chainEnd = "brought_in"
                            if LC.PrisonAvailable() then
                                q.data.target = q.data.actor
                                Insert(q, { Q.ArrestStage("Arrest him (right click)") })
                            end
                        end },
                        { text = "Let him disappear.", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            Trait(p, "corruption", 1)
                            q.chainEnd = "let_go"
                            return "complete"
                        end },
                        { text = "Help him reach the Resistance.", check = { "empathy", 12 },
                          success = function(q, p)
                              Trait(p, "sympathy", 3)
                              q.chainEnd = "defected"
                              Insert(q, { { kind = "escort", pos = dest, r = r, vanish = true, text = "Get him to " .. safe,
                                  onEnter = function(q2, st) st.npc = q2.data.actor end } })
                          end,
                          fail = function(q)
                              Narrate(q, "He doesn't trust you. He runs.")
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
        forgiven = "He weeps through the whole blessing. He never informs again.",
        cast_out = "He leaves without a word. The flock is smaller, and safer.",
        betrayed = "Your chapel is ash by morning. You will find another. You always do.",
        grace = "If he reports you, he'll have to report that too.",
    },
    parts = {
        lost = { num = 1, next = "mass", build = function()
            return {
                title = "Lost sheep", reward = 25, limit = 600,
                desc = "The city is full of frightened people. Find some of them.",
                stages = {
                    Count("used_npc", 3, "Seek out frightened souls and speak with them (press E)", Q.IsCitizenNPC),
                    Count("healed", 2, "Tend to their wounds (The Blessing)", nil, true),
                },
            }
        end },

        mass = { num = 2, build = function(ply)
            local pos, r, where = Q.SafeHouse(ply)
            if not pos then return nil end
            local hold = Hold(pos, 60, "Hold a secret mass", math.max(220, r))
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
                desc = "Gather the faithful in " .. where .. ". Pray quietly. Pray quickly.",
                stages = {
                    Goto(pos, "Go to the hidden chapel in " .. where, math.max(200, r)),
                    hold,
                    Choice("As the last hymn ends, you notice one of your flock counting the others. Quietly. Like a man taking inventory.", {
                        { text = "Find the informant among them.", check = { "empathy", 13 },
                          success = function(q)
                              Insert(q, { Choice("He's young. He's frightened. They have his mother.", {
                                  { text = "Forgive him.", pick = function(q2, p) Trait(p, "sympathy", 2) q2.chainEnd = "forgiven" end },
                                  { text = "Send him away.", pick = function(q2) q2.chainEnd = "cast_out" end },
                              }) })
                          end,
                          fail = function(q, p)
                              Narrate(q, "You can't tell which of them it is. By morning, Civil Protection knows everything.")
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
                        Narrate(q, "Boots on the stairs.")
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
        transhuman = "You don't remember your name. You don't need to.",
        human = "You keep your name, your face, and the nightmares. Overwatch won't ask twice: you'll go no higher than Division Leader.",
    },
    parts = {
        evaluation = { num = 1, next = "conditioning", build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Evaluation", reward = 30, limit = 600,
                desc = "Overwatch is watching your performance. Hold a checkpoint and inspect citizens. Flawlessly.",
                stages = {
                    Goto(pos, "Report to the checkpoint", 260),
                    Hold(pos, 90, "Hold the checkpoint under observation", 280),
                    Count("used_npc", 3, "Inspect three citizens", Q.IsCitizenNPC),
                },
            }
        end },

        conditioning = { num = 2, build = function(ply)
            local zones = LC.ZonesOfKind("prison")
            local pos = #zones > 0 and zones[1].pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "Conditioning", reward = 20, limit = 480,
                desc = "Report " .. Place(pos, ply:GetPos()) .. ". Come alone.",
                stages = {
                    Goto(pos, "Report as ordered", 300),
                    Choice("A technician in a coat that has never been white. 'Transhuman conditioning. " ..
                        "You won't remember your name, Civil Protection unit. You won't need to.'", {
                        { text = "Accept. (The Overwatch ranks open to you: Prison Guard, Soldier, Elite. There's no undoing it.)", pick = function(q, p)
                            q.chainEnd = "transhuman"
                            timer.Simple(1.5, function() if IsValid(p) and LC.Condition then LC.Condition(p) end end)
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
    Narrate(q, why or "Someone saw that. They'll remember.")
    if LC.Counter(p, "suspicion") >= 3 then
        p:ChatPrint("[Story] You have a feeling you're being watched.")
        if LC.CheckUnlocks then LC.CheckUnlocks(p) end
    end
end

-- Watching for witnesses while doing something you shouldn't.
local function Witnessed(kinds, why)
    return function(q)
        if q.data.witnessed or not IsValid(q.owner) then return end
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
    unlock = function(ply)
        return LC.Trait(ply, "corruption") <= 1 and (LC.Trait(ply, "sympathy") >= 3 or LC.Counter(ply, "mercies") >= 2)
    end,
    start = "note",
    endings = {
        loyal = "She was processed by morning. You were commended. You don't sleep well.",
        defected = "You burned your uniform in a canal barrel. The Resistance has a fighter who knows exactly how Civil Protection units think.",
        insider = "You still wear the mask. Now you know who you're wearing it for.",
        walked = "You never answer another note. Some nights you wonder.",
    },
    parts = {
        note = { num = 1, build = function(ply)
            local spot = Q.Spot(ply, 500, 2500)
            if not spot then return nil end
            return {
                title = "A note in your ration packet", reward = 15, limit = 480,
                desc = "Someone slipped a note into your ration packet. One line: a place, " .. Place(spot, ply:GetPos()) .. ", and a time. Now.",
                stages = {
                    Goto(spot, "Go to the place named in the note", 220),
                    Meet("Find whoever left it (marked)", "citizen", function() return spot end, nil, nil, "female"),
                    Choice("A woman with a lambda tattooed on the inside of her wrist. 'People talk about you, officer. " ..
                        "The one who looks the other way. The one who says please.' She doesn't blink. 'We could use someone like that.'", {
                        { text = "Hear her out.", pick = function(q)
                            Narrate(q, "She talks fast and quiet. By the end, you know three names you shouldn't.")
                            q.chainNext = "proof"
                        end },
                        { text = "Arrest her.", pick = function(q, p)
                            Trait(p, "loyalty", 2)
                            q.chainEnd = "loyal"
                            if LC.PrisonAvailable() then
                                q.data.target = q.data.actor
                                Insert(q, { Q.ArrestStage("Arrest her (right click)") })
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
            return {
                title = "Proof of good faith", reward = 35, limit = 720,
                desc = "They want proof. A prisoner, released on your shift, walked to " .. where .. ". Don't let another Civil Protection unit see you.",
                stages = {
                    FreePrisonerStage("Unlock the cell of the prisoner they named (press E)"),
                    { kind = "escort", pos = dest, r = r, vanish = true, text = "Walk them to " .. where .. " like it's routine",
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
                desc = "They want to meet in " .. where .. ". Come out of uniform if you can. Come alone either way.",
                stages = {
                    Goto(pos, "Go to the meeting in " .. where, r),
                    Meet("Find her", "citizen", function() return pos end, nil, nil, "female"),
                    Choice("She's waiting with a man in a lambda armband who doesn't take his hand off his rifle. " ..
                        "'You've proven yourself. So: do you come over, or do you stay where you can do the most good?'", {
                        { text = "Come over. Tonight.", pick = function(q, p)
                            Trait(p, "sympathy", 2)
                            q.chainEnd = "defected"
                            JoinLater(p, "resistance", 400)
                        end },
                        { text = "Stay inside. Be their eyes.", pick = function(q, p)
                            Trait(p, "sympathy", 1)
                            LC.StoryFlag(p, "insider", true)
                            q.chainEnd = "insider"
                            Narrate(q, "He finally lets go of the rifle. 'Then you never met us. Watch your board.'")
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
    local hold = Hold(s, 4, "Leave the patrol schedule at the dead drop (crouch)", 90, true)
    hold.onDone = function(q)
        if LC.SeenBySecurity(q.owner, 800) then Suspect(q, q.owner, "A Civil Protection unit watched you crouch by that drainpipe. He'll wonder why.") end
    end
    return {
        title = "Leak the schedule", reward = 25, limit = 420,
        desc = "Tomorrow's patrol routes, left where the right people will find them " .. Place(s, ply:GetPos()) .. ".",
        stages = { Goto(s, "Go to the dead drop", 150), hold },
    }
end

OPS[#OPS + 1] = function(ply)
    local id = Q.CitizenID()
    local dest, r, where = Q.SafeHouse(ply)
    local warn = {
        kind = "target", action = "use", text = "Warn citizen " .. id .. " before the raid (press E)",
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
        desc = "Citizen " .. id .. " is on tomorrow's list. Get to them first. Quickly.",
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
        desc = "Evidence against a Resistance cell is sitting " .. Place(center, ply:GetPos()) .. ". It should never reach the evidence room.",
        stages = {
            { kind = "collect", spots = Q.HideSpots(center, 2, 500), model = item[2], need = 2, text = "Collect the evidence (press E)" },
            Deliver(dest, "Take it to " .. where .. " instead of HQ", r),
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
        desc = "Someone in the cells knows too much about the Resistance. Get them out before interrogation.",
        stages = {
            FreePrisonerStage("Open their cell (press E)"),
            { kind = "escort", pos = dest, r = 200, vanish = true, text = "Walk them out like it's paperwork",
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
        desc = "Your sector report is due. There was Resistance activity near the canals this week.",
        stages = {
            Goto(pos, "Go to file your sector report", 260),
            Count("used_npc", 1, "Hand your report to an officer (press E)", Q.IsCopNPC),
            Choice("The officer skims your report. 'Canals. Anything to note, Civil Protection unit?'", {
                { text = "The canals were quiet. Completely quiet.", check = { "guile", 12 },
                  success = function(q, p) Trait(p, "sympathy", 1) Narrate(q, "He stamps it without looking up.") end,
                  fail = function(q, p) Suspect(q, p, "He reads it twice, then looks at you for a long moment.") end },
                { text = "Report it honestly. You can't risk it today.", pick = function(q, p)
                    Trait(p, "loyalty", 1)
                    Narrate(q, "Somewhere in the canals, a cell has to move house tonight. They'll understand. Probably.")
                end },
            }),
        },
    }
end

LC.Chain{
    id = "insidework", name = "Inside Work", factions = { cp = true }, flat = true,
    unlock = function(ply) return LC.StoryFlag(ply, "insider") == true end,
    gate = function(ply)
        return LC.StoryFlag(ply, "insider") == true and not LC.StoryFlag(ply, "exposed") and LC.Counter(ply, "suspicion") < 3
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
    Narrate(q, "He picks up your file instead. 'Interesting.'")
    XP(p, -200)
    LC.SetFaction(p, "citizen", nil, true)
    if LC.PrisonAvailable() then LC.Incarcerate(p, 300, "Treason", nil) end
    return "complete"
end

local function ClearSuspicion(p) LC.Bump(p, "suspicion", -LC.Counter(p, "suspicion")) end

LC.Chain{
    id = "molehunt", name = "Mole Hunt", factions = { cp = true },
    unlock = function(ply) return LC.StoryFlag(ply, "insider") == true and LC.Counter(ply, "suspicion") >= 3 end,
    start = "hunt",
    endings = {
        framed = "Unit 3-09 was taken in your place. You tell yourself he probably deserved it.",
        ran = "You ran before they could knock. Every Civil Protection unit in the city has your face now.",
        survived = "The mole hunt moves on to another sector. You breathe again. Carefully.",
        exposed = "Stripped of rank and mask. A citizen again, with a file that will never close.",
    },
    parts = {
        hunt = { num = 1, build = function(ply)
            local cps = LC.PointsOfKind("checkpoint")
            local pos = #cps > 0 and Pick(cps).pos or Q.Spot(ply, 400, 2000)
            if not pos then return nil end
            return {
                title = "The briefing", reward = 30, limit = 480,
                desc = "Internal Affairs believes there's a mole in your division. They want your help finding them.",
                stages = {
                    Goto(pos, "Report for the briefing", 260),
                    Meet("Speak with the Internal Affairs officer", "cop", function() return pos end),
                    Choice("The officer spreads three files across the hood of an APC. One of them is yours. He hasn't noticed. Yet.", {
                        { text = "Steer him toward another Civil Protection unit's file.", check = { "guile", 14 },
                          success = function(q, p)
                              Trait(p, "corruption", 1)
                              ClearSuspicion(p)
                              q.chainEnd = "framed"
                          end,
                          fail = function(q, p) return Expose(q, p) end },
                        { text = "Excuse yourself. Run, tonight.", pick = function(q, p)
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
    if chainId == "molehunt" and (ending == "framed" or ending == "survived") then
        local s = LC.Story(ply)
        s.chains.molehunt = nil
        s.notified.molehunt = nil
        LC.SaveStory(ply)
    end
end)
