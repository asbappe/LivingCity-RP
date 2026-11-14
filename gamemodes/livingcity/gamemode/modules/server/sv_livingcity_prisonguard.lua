--[[
    Living City: the prison guard's work, and a short rank (the owner, 13 November playtest: "I went
    from metrocop division leader to combine prison guard...but there are no quests related to the
    prison ... interrogation, attempted prison breaks, etc. The prison is just 1 room with little
    cells in it, so we will need it to be a rather short rank/job"; and 14 November: "make it so you
    can be promoted from prison guard to combine soldier after 4 successful quests").

    Four jobs on a Combine Prison Guard's board (F4), only while the map has prison cells (and no
    "stand here" in any of them: the owner, 14 November, CORE.md):
      Cell inspection        search the cells by hand (hold E on everything in them: the bunk, the toilet,
                             a terminal, whatever is there; their own uses are off for you meanwhile): one
                             thing in one cell hides a sharpened spoon (sv_livingcity_questsearch.lua)
      Question a prisoner    an interrogation, with the unit's quick menu (sv_livingcity_interrogation.lua's
                             questions): ask, use the baton, call out a lie; they lie and clam up until
                             broken, and the truth ends it (a hideout or supply place is marked for you)
      A break for it         a prisoner gets out of a cell and runs: catch them and arrest them
      Unrest in the cells    prisoners rattle their doors, louder and louder: order them down (E; they may
                             not listen) or use the baton, until they're all quiet; a door that gives fails it
    The cells empty, a prisoner is put in one for the job.

    Every one done counts (LC.PrisonGuardDone); the fourth (LC.PrisonGuardJobsToPromote) makes them a
    Combine Soldier: the experience still owed for that rank is given with it, so the ranks' own
    experience is unchanged (the core). The count starts over with a new character, and once they're
    a soldier.
]]

if CLIENT then return end

LC = LC or {}

LC.PrisonGuardJobsToPromote = 4

local GUARD_RANK, SOLDIER_RANK = "Combine Prison Guard", "Combine Soldier"

local function RankName(ply)
    local f = LCF and LCF.ById and LCF.ById[ply:GetNW2String("lcf_faction", "")]
    local r = f and f.ranks and f.ranks[ply:GetNW2Int("lcf_rank", 1)]
    return r and r.name or nil, f
end
function LC.IsPrisonGuard(ply)
    return IsValid(ply) and ply:IsPlayer() and RankName(ply) == GUARD_RANK
end

local function Cells()
    local out = {}
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("cell") or {}) do out[#out + 1] = p.pos end
    return out
end
local function CellBlock()
    local c = Cells()
    if #c == 0 then return nil end
    local sum = Vector(0, 0, 0)
    for _, p in ipairs(c) do sum = sum + p end
    return sum / #c
end

-- Someone held in the cells: an NPC prisoner, or a player. The entity, or nil.
local function Prisoner(near)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.state == "jailed" then
            local d = npc:GetPos():DistToSqr(near)
            if not bd or d < bd then best, bd = npc, d end
        end
    end
    return best
end

-- A prisoner put in a cell for a job, when the cells are empty: a citizen, held there (sv_livingcity_prison.lua).
local function JailOne(q, at)
    local Q = LC.QB
    local npc, st = LC.Spawners and LC.Spawners.citizen and LC.Spawners.citizen(at + Vector(0, 0, 4))
    if not IsValid(npc) then return nil end
    st = st or (LC.NPCs and LC.NPCs[npc])
    if st then
        st.jailUntil = CurTime() + 900
        if LC.OnNPCReachedCell then LC.OnNPCReachedCell(npc, st, CurTime()) end
    end
    if Q and Q.Lock then Q.Lock(q, npc) end
    return npc
end
LC.PrisonGuardJailOne = JailOne

------------------------------------------------------------------------
-- Questioning a prisoner who isn't a player: the same questions and the same quick menu as a unit's
-- interrogation of a player (sv_livingcity_interrogation.lua, LC.InterrogationQuestions), the prisoner
-- answering for themself. Under resolve they say nothing or lie; the baton and catching a lie wear it
-- down; broken, the truth comes out (what they really know, or that they don't). A truth called a lie
-- stiffens them. Nothing says which answer was which, except that the truth ends the job.
------------------------------------------------------------------------
LC.NPCInterrogations = LC.NPCInterrogations or {} -- [guard] = session
local MAX_HITS, REACH = 6, 260
local FAKE = { "Viktor Halloran", "Anya Brecht", "Pavel Novak", "Mira Sorel", "Tomas Varga", "Lena Orlov", "Gregor Duval" }
local function Place(pos) return (LC.DescribePlace and LC.DescribePlace(pos)) or "somewhere in the city" end
local function NameOf(npc) return (LC.NPCStr and LC.NPCStr(npc, "lc_pname", "") ~= "" and LC.NPCStr(npc, "lc_pname", "")) or "the prisoner" end

local function Words(s, key, truth)
    local function anyOf(list) return list[math.random(#list)] end
    if truth then
        if not s.knows then
            return key == "names" and "\"I don't know any names. I'm nobody.\"" or "\"I don't know anything about that. I swear.\""
        end
        if key == "names" then
            local them = {}
            for _, p in ipairs(player.GetAll()) do if p:GetNW2String("lcf_faction", "") == "resistance" then them[#them + 1] = p end end
            return "\"" .. (#them > 0 and ((LC.CharacterName and LC.CharacterName(anyOf(them))) or anyOf(them):Nick()) or anyOf(FAKE)) .. ". That's all I know.\""
        end
        local spots = {}
        if key == "supplies" then for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("dealer") or {}) do spots[#spots + 1] = p.pos end end
        if #spots == 0 then for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do spots[#spots + 1] = z.pos end end
        if #spots == 0 then return "\"There's no place. We move around.\"" end
        local pos = anyOf(spots)
        return string.format(key == "hideout" and "\"They meet %s.\"" or "\"The supplies come through %s.\"", Place(pos)), pos
    end
    if key == "names" then return "\"" .. anyOf(FAKE) .. ". That's all I know.\"" end
    local spots = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do spots[#spots + 1] = z.pos end
    if #spots == 0 then return key == "hideout" and "\"Under the old canal bridge.\"" or "\"A man at the train station.\"" end
    return string.format(key == "hideout" and "\"They meet %s.\"" or "\"The supplies come through %s.\"", Place(anyOf(spots)))
end

local function Push(guard, s)
    if not IsValid(guard) then return end
    local qs = LC.InterrogationQuestions or {}
    net.Start("lc_intr_cp")
    net.WriteString(util.TableToJSON({ who = NameOf(s.npc), resolve = s.resolve, hits = s.hits, waiting = s.waiting and s.waiting.q or 0,
        answers = s.answers, asked = s.asked, canCall = s.last ~= nil and s.last ~= "silent" and not s.called or nil,
        questions = { qs[1] and qs[1].text, qs[2] and qs[2].text, qs[3] and qs[3].text } }) or "{}")
    net.Send(guard)
end

-- Start questioning npc (someone held in the cells). q: the job it belongs to (the truth ends it).
function LC.NPCInterrogationStart(guard, npc, q)
    if not IsValid(guard) or not IsValid(npc) then return false end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.state ~= "jailed" then return false, "They aren't held in a cell." end
    local s = LC.NPCInterrogations[guard]
    if not (s and s.npc == npc) then
        -- how much they hold out: who they are (the brave, the proud and the tough longer)
        local resolve = 2
        local prof = st.profile or {}
        for _, t in ipairs({ "brave", "proud", "tough", "stubborn" }) do if prof[t] or (prof.traits and prof.traits[t]) then resolve = resolve + 1 end end
        s = { npc = npc, q = q, resolve = math.min(5, resolve + math.random(0, 1)), hits = 0, asked = {}, answers = {},
              knows = st.rebelPrisoner or st.role == "rebel" or math.random() < 0.55 }
        LC.NPCInterrogations[guard] = s
    end
    guard:ChatPrint("[Interrogation] You step into " .. NameOf(npc) .. "'s cell. \"You will answer my questions.\"")
    Push(guard, s)
    return true
end

local function End(guard, s, why)
    LC.NPCInterrogations[guard] = nil
    if IsValid(guard) then
        net.Start("lc_intr_cp") net.WriteString(util.TableToJSON({ done = true })) net.Send(guard)
        if why then guard:ChatPrint("[Interrogation] " .. why) end
    end
end

-- The prisoner answers question qn (after a moment).
local function Answer(guard, s, qn)
    s.waiting = nil
    local key = (LC.InterrogationQuestions[qn] or {}).key or "hideout"
    local kind
    if s.resolve <= 0 then kind = "truth" else kind = math.random() < 0.5 and "silent" or "lie" end
    s.last, s.called = kind, nil
    if kind == "silent" then
        guard:ChatPrint("[Interrogation] " .. NameOf(s.npc) .. " says nothing.")
        s.answers[#s.answers + 1] = { q = qn, text = "(nothing)" }
    else
        local words, pos = Words(s, key, kind == "truth")
        s.answers[#s.answers + 1] = { q = qn, text = words }
        guard:ChatPrint("[Interrogation] " .. NameOf(s.npc) .. ": " .. words)
        if kind == "truth" then
            if pos and LC.SendCompressed then
                LC.SendCompressed("lc_cpmark", { name = key == "supplies" and "SUPPLIES (INFORMANT)" or "HIDEOUT (INFORMANT)", x = pos.x, y = pos.y, z = pos.z, secs = 300 }, { guard })
            end
            if s.q and not s.q.done then
                s.q.data.talked = true
                if LC.QB and LC.QB.Narrate then LC.QB.Narrate(s.q, "They're broken. That was the truth, and it goes on the record.") end
            end
            hook.Run("LivingCityNPCInterrogated", guard, s.npc, key)
            return End(guard, s, "They've told you what they know.")
        end
    end
    Push(guard, s)
end

-- The guard's choice in the quick menu: "ask" (n), "baton", "call" (that's a lie), "done". True if it was ours.
function LC.NPCInterrogationDo(guard, what, n)
    local s = LC.NPCInterrogations[guard]
    if not s then return false end
    if not IsValid(s.npc) or guard:GetPos():DistToSqr(s.npc:GetPos()) > REACH * REACH * 4 then
        End(guard, s, "You walked away from them.")
        return true
    end
    if what == "ask" then
        if s.waiting then guard:ChatPrint("[Interrogation] Wait for an answer.") return true end
        local qd = LC.InterrogationQuestions and LC.InterrogationQuestions[n]
        if not qd then return true end
        s.asked[n] = true
        guard:ChatPrint("[Interrogation] \"" .. qd.text .. "\"")
        s.waiting = { q = n }
        timer.Simple(1.5, function() if LC.NPCInterrogations[guard] == s and s.waiting then Answer(guard, s, n) end end)
        Push(guard, s)
    elseif what == "baton" then
        if s.hits >= MAX_HITS then guard:ChatPrint("[Interrogation] Any more and you'll kill them.") return true end
        s.hits = s.hits + 1
        s.resolve = math.max(0, s.resolve - 1)
        s.npc:SetHealth(math.max(10, s.npc:Health() - 6))
        s.npc:EmitSound("weapons/stunstick/stunstick_impact" .. math.random(1, 4) .. ".wav", 70)
        guard:ChatPrint("[Interrogation] The baton comes down.")
        Push(guard, s)
    elseif what == "call" then
        if not s.last or s.last == "silent" or s.called then return true end
        s.called = true
        if s.last == "lie" then
            s.resolve = math.max(0, s.resolve - 1)
            guard:ChatPrint("[Interrogation] \"Liar.\" They flinch, and look away.")
        else
            s.resolve = s.resolve + 1
            guard:ChatPrint("[Interrogation] \"Liar.\" They glare back at you: \"I told you the truth.\"")
        end
        Push(guard, s)
    elseif what == "done" then
        End(guard, s)
    end
    return true
end

------------------------------------------------------------------------
-- Unrest in the cells: prisoners rattling their doors, louder and louder (a riot meter each), until
-- every one of them is quiet at once. E on one: order them down (they may not listen, and get louder);
-- the baton on one: quiet for sure. Left too long, a door gives and it's a breakout: the job fails.
------------------------------------------------------------------------
LC.RiotStep, LC.RiotBreak, LC.RiotRelapse = 8, 100, 0.15
local RIOT_NOISE = { "physics/metal/metal_box_impact_hard1.wav", "physics/metal/metal_box_impact_hard2.wav", "physics/metal/metal_box_impact_hard3.wav",
    "physics/metal/metal_grate_impact_hard1.wav", "physics/metal/metal_grate_impact_hard2.wav" }
local RIOT_SHOUT = { "vo/npc/male01/gethellout.wav", "vo/npc/male01/letmegohome.wav", "vo/npc/male01/no02.wav", "vo/npc/male01/help01.wav" }

local function RiotPoll(q, st)
    local Q = LC.QB
    local quiet, any = 0, 0
    for npc, r in pairs(st.rioters or {}) do
        if IsValid(npc) then
            any = any + 1
            if r.quiet then
                quiet = quiet + 1
                if math.random() < LC.RiotRelapse * 0.5 then r.quiet, r.noise = false, 40 Q.Narrate(q, NameOf(npc) .. " starts up again!") end
            else
                r.noise = r.noise + LC.RiotStep * 0.5 * (st.rate or 1)
                if math.random() < 0.35 then npc:EmitSound(RIOT_NOISE[math.random(#RIOT_NOISE)], 75) end
                if math.random() < 0.08 then npc:EmitSound(RIOT_SHOUT[math.random(#RIOT_SHOUT)], 75) end
                if r.noise >= 50 and not r.said50 then r.said50 = true Q.Narrate(q, NameOf(npc) .. " is kicking the cell door now.") end
                if r.noise >= 80 and not r.said80 then r.said80 = true Q.Narrate(q, NameOf(npc) .. "'s door is giving: the hinges are going!") end
                if r.noise >= LC.RiotBreak then return Q.Finish(q, false, NameOf(npc) .. " broke the door down: the block's in uproar") end
            end
        end
    end
    st.got = quiet
    if any > 0 and quiet >= any then return Q.Advance(q) end
    if Q.SendStateAll then Q.SendStateAll(q) end
end

-- E on a rioter, or the baton on one: true if it was a rioter of this guard's job.
function LC.RiotQuiet(guard, npc, how)
    local q = LC.QuestOf and LC.QuestOf[guard]
    local st = q and q.stages and q.stages[q.stage]
    local r = st and st.rioters and st.rioters[npc]
    if not r then return false end
    if r.quiet then return true end
    if how == "baton" or math.random() < 0.6 then
        r.quiet, r.noise, r.said50, r.said80 = true, 0, nil, nil
        guard:ChatPrint(how == "baton" and ("[Prison] " .. NameOf(npc) .. " drops back onto the bunk, holding their arm.") or ("[Prison] \"Sit down. Now.\" " .. NameOf(npc) .. " sits down."))
    else
        r.noise = math.min(LC.RiotBreak - 5, r.noise + 20)
        guard:ChatPrint("[Prison] " .. NameOf(npc) .. " laughs in your face and rattles the door harder. (The baton won't be argued with.)")
    end
    return true
end
hook.Add("PlayerUse", "LivingCityPrisonRiot", function(ply, ent)
    if (ply.lcRiotUse or 0) > CurTime() then return end
    if LC.RiotQuiet(ply, ent, "order") then ply.lcRiotUse = CurTime() + 0.8 return false end
end)
hook.Add("EntityTakeDamage", "LivingCityPrisonRiot", function(ent, dmg)
    local a = dmg:GetAttacker()
    if IsValid(a) and a:IsPlayer() and ent:IsNPC() then
        local w = a:GetActiveWeapon()
        if IsValid(w) and w:GetClass() == "weapon_lc_baton" then LC.RiotQuiet(a, ent, "baton") end
    end
end)
-- E on the prisoner during "Question a prisoner": the questioning (again).
hook.Add("PlayerUse", "LivingCityPrisonQuestion", function(ply, ent)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and q.stages and q.stages[q.stage]
    if st and st.interrogate and q.data.target == ent then
        if (ply.lcIntrUse or 0) > CurTime() then return false end
        ply.lcIntrUse = CurTime() + 1
        LC.NPCInterrogationStart(ply, ent, q)
        return false
    end
end)

function LC.PrisonGuardTemplates()
    local Q = LC.QB
    local function Avail(ply) return LC.IsPrisonGuard(ply) and #Cells() > 0 end
    local SPOON = { "Taped under it: a sharpened spoon, filed to a point. Confiscated.", "Inside, wrapped in a sock: a spoon ground down to a blade. Confiscated.",
        "Pushed deep into it: a spoon sharpened on the floor. Confiscated." }
    return {
        {
            id = "pg_inspect", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local cells = Cells()
                for i = #cells, 2, -1 do local j = math.random(i) cells[i], cells[j] = cells[j], cells[i] end
                local n = math.min(3, #cells)
                local spoonAt = math.random(n)
                local stages = {}
                for i = 1, n do
                    stages[#stages + 1] = LC.QuestSearchStage({
                        pos = cells[i], r = 130, min = 3, hide = (i == spoonAt),
                        text = "Search cell " .. i .. " (marked): hold E on everything in it, the bunk, the toilet, the lot",
                        found = function(q, st, ent, p)
                            p:ChatPrint("[Search] " .. SPOON[math.random(#SPOON)])
                            hook.Run("LivingCityContrabandFound", p, "shiv")
                            Q.Finish(q, true, "you found the shiv")
                            return true
                        end,
                    })
                end
                return { title = "Cell inspection", reward = 20, limit = 420, stages = stages,
                    desc = "Word is someone in the cells has made a weapon. Search the cells by hand, everything in them, until you find it." }
            end,
        },
        {
            id = "pg_question", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local cells = Cells()
                return { title = "Question a prisoner", reward = 25, limit = 420,
                    desc = "Someone in the cells knows more than they've said. Question them: they'll lie, and they'll clam up. Use the baton, catch them lying, and get the truth.",
                    stages = {
                        { kind = "target", action = "reach", r = 120, text = "Go to the prisoner (marked)",
                          onEnter = function(q, st)
                              local npc = Prisoner(ply:GetPos())
                              if not IsValid(npc) then npc = JailOne(q, cells[math.random(#cells)]) end
                              if not IsValid(npc) then return false end
                              Q.Lock(q, npc) q.data.target = npc st.npc = npc
                          end },
                        { kind = "count", need = 1, interrogate = true,
                          text = "Question them (it opens by itself; E on them to start again): ask, use the baton, call out a lie, until they tell the truth",
                          onEnter = function(q, st) st.npc = q.data.target if IsValid(q.owner) then LC.NPCInterrogationStart(q.owner, q.data.target, q) end end,
                          poll = function(q, st)
                              if not IsValid(q.data.target) then return Q.Finish(q, false, "the prisoner is gone") end
                              if q.data.talked then return Q.Advance(q) end
                          end },
                    } }
            end,
        },
        {
            id = "pg_break", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local block = CellBlock()
                if not block then return nil end
                return { title = "A break for it", reward = 30, limit = 240,
                    desc = "A prisoner has slipped out of a cell. Catch them before they're out of the building.",
                    stages = {
                        Q.Goto(block, "Get to the cell block (marked)", 260),
                        { kind = "target", action = "arrest", text = "Catch the escaping prisoner and arrest them with the Arrest Baton (right click)",
                          onEnter = function(q, st)
                              local npc = LC.Spawners and LC.Spawners.citizen and LC.Spawners.citizen(block + Vector(math.random(-60, 60), math.random(-60, 60), 4))
                              if not IsValid(npc) then return false end
                              Q.Lock(q, npc)
                              q.data.target = npc
                              st.npc = npc
                              if LC.SetNPCStr then LC.SetNPCStr(npc, "lc_pjob", "Escaped prisoner") end
                              Q.Flee(q)
                          end,
                          narrate = "There! In the prison greys, running for the door." },
                    } }
            end,
        },
        {
            id = "pg_riot", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local cells = Cells()
                local block = CellBlock()
                if not block then return nil end
                return { title = "Unrest in the cells", reward = 25, limit = 300,
                    desc = "The cells are kicking off: prisoners rattling their doors, louder by the minute. Quiet every one of them before a door gives.",
                    stages = {
                        Q.Goto(block, "Get to the cell block (marked)", 300),
                        { kind = "count", need = 3, pos = block,
                          text = "Quiet them all: E to order one down (they may not listen), or the baton (left click). Don't let a door give",
                          onEnter = function(q, st)
                              st.rioters = {}
                              local n = 0
                              for i = 1, math.min(3, #cells) do
                                  local npc = Prisoner(cells[i])
                                  if not (IsValid(npc) and npc:GetPos():DistToSqr(cells[i]) < 160 * 160 and not st.rioters[npc]) then npc = JailOne(q, cells[i]) end
                                  if IsValid(npc) and not st.rioters[npc] then
                                      Q.Lock(q, npc)
                                      st.rioters[npc] = { noise = math.random(10, 35), quiet = false }
                                      n = n + 1
                                  end
                              end
                              if n == 0 then return false end
                              st.need = n
                              st.npc = next(st.rioters)
                          end,
                          poll = RiotPoll,
                          narrate = "Metal on metal, all down the block. Someone's shouting to be let out." },
                    } }
            end,
        },
    }
end

-- (added once the quest machinery is loaded; this file comes after it)
if LC.QuestTemplates and LC.QB then
    for _, t in ipairs(LC.PrisonGuardTemplates()) do
        for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == t.id then table.remove(LC.QuestTemplates, i) end end
        LC.QuestTemplates[#LC.QuestTemplates + 1] = t
    end
end

-- How many prison jobs this character has done as a guard.
function LC.PrisonGuardDone(ply)
    return IsValid(ply) and (tonumber(ply:GetPData("lc_pg_jobs", 0)) or 0) or 0
end

-- One more done; the fourth makes them a soldier. True if promoted.
function LC.PrisonGuardJobDone(ply)
    if not LC.IsPrisonGuard(ply) then return false end
    local n = LC.PrisonGuardDone(ply) + 1
    ply:SetPData("lc_pg_jobs", n)
    if n < LC.PrisonGuardJobsToPromote then
        if LC.Notice then LC.Notice(ply, "info", "Prison duty", string.format("%d of %d prison jobs done: then you join the soldiers.", n, LC.PrisonGuardJobsToPromote), 6) end
        return false
    end
    local _, f = RankName(ply)
    local need
    for _, r in ipairs(f and f.ranks or {}) do if r.name == SOLDIER_RANK then need = r.xp end end
    if not need or not LC.AddXP then return false end
    local have = tonumber(ply:GetPData("lcf_xp_" .. f.id, 0)) or 0
    ply:SetPData("lc_pg_jobs", 0)
    LC.AddXP(ply, math.max(1, need - have), "four prison jobs done")
    return RankName(ply) == SOLDIER_RANK
end

hook.Add("LivingCityQuestComplete", "LivingCityPrisonGuard", function(ply, q)
    if q and q.tmpl and q.tmpl.prisonGuard then LC.PrisonGuardJobDone(ply) end
end)
hook.Add("LivingCityNewCharacter", "LivingCityPrisonGuard", function(ply) if IsValid(ply) then ply:SetPData("lc_pg_jobs", 0) end end)
