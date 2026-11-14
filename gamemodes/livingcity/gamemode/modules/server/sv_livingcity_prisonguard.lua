--[[
    Living City: the prison guard's work, and a short rank (the owner, 13 November playtest: "I went
    from metrocop division leader to combine prison guard...but there are no quests related to the
    prison ... interrogation, attempted prison breaks, etc. The prison is just 1 room with little
    cells in it, so we will need it to be a rather short rank/job"; and 14 November: "make it so you
    can be promoted from prison guard to combine soldier after 4 successful quests").

    Four jobs on a Combine Prison Guard's board (F4), only while the map has prison cells:
      Cell inspection        search up to three cells (5 seconds at each)
      Question a prisoner    walk up to someone held in the cells and question them (15 seconds by them)
      A break for it         a prisoner gets out of a cell and runs: catch them and arrest them
      Watch over the cells   stand watch at the cell block for a minute

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

function LC.PrisonGuardTemplates()
    local Q = LC.QB
    local function Avail(ply) return LC.IsPrisonGuard(ply) and #Cells() > 0 end
    return {
        {
            id = "pg_inspect", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local cells = Cells()
                for i = #cells, 2, -1 do local j = math.random(i) cells[i], cells[j] = cells[j], cells[i] end
                local stages = {}
                for i = 1, math.min(3, #cells) do
                    stages[#stages + 1] = Q.Hold(cells[i], 5, "Search cell " .. i .. " (marked): stay in it for 5 seconds", 90)
                end
                stages[#stages].onDone = function(q)
                    Q.Narrate(q, math.random() < 0.5 and "Under a loose tile: a sharpened spoon. Confiscated." or "Nothing hidden. This time.")
                end
                return { title = "Cell inspection", reward = 20, limit = 300, stages = stages,
                    desc = "Search the cells for anything a prisoner shouldn't have: shivs, lockpicks, notes passed in." }
            end,
        },
        {
            id = "pg_question", factions = { cp = true }, prisonGuard = true,
            available = function(ply) return Avail(ply) and Prisoner(ply:GetPos()) ~= nil end,
            build = function(ply)
                local npc = Prisoner(ply:GetPos())
                if not IsValid(npc) then return nil end
                return { title = "Question a prisoner", reward = 25, limit = 300,
                    desc = "Someone in the cells knows more than they've said. Go and ask them, and keep asking.",
                    stages = {
                        { kind = "target", action = "reach", r = 110, text = "Go to the prisoner (marked)",
                          onEnter = function(q, st) Q.Lock(q, npc) q.data.target = npc st.npc = npc end },
                        { kind = "hold", pos = npc:GetPos(), r = 140, secs = 15, text = "Question them: stay by them for 15 seconds",
                          onEnter = function(q, st) if IsValid(q.data.target) then st.pos = q.data.target:GetPos() end end,
                          onDone = function(q)
                              Q.Narrate(q, Q.Pick({ "They give up a name in the end. It goes on the record.",
                                  "Nothing but a stare. That's on the record too.", "They talk about a stash in the blocks. It'll be checked." }))
                          end },
                    } }
            end,
        },
        {
            id = "pg_break", factions = { cp = true }, prisonGuard = true, violent = false, available = Avail,
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
            id = "pg_watch", factions = { cp = true }, prisonGuard = true, available = Avail,
            build = function(ply)
                local block = CellBlock()
                if not block then return nil end
                return { title = "Watch over the cells", reward = 15, limit = 240,
                    desc = "Stand watch over the cell block. Nobody in or out without you seeing it.",
                    stages = { Q.Hold(block, 60, "Stand watch at the cell block for a minute", 300) } }
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
