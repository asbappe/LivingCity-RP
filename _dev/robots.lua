-- Robot players (run by the RobotTests unit in tests.lua; see _dev/README.md).
--
-- A robot is a fake player who takes a job and does it the way a player would: walks to
-- the place, uses the thing, makes the arrest, answers the choice, holds E on what is to
-- be searched. It never reaches into the job to move it on. A job passes when it finishes
-- and pays. It fails when it sticks (the robot did its part and nothing happened), runs
-- out of time, is called off by the game for want of something, or raises an error.
--
-- What a robot cannot do yet is said so ("the robot can't ..."), never counted as done.
--
-- returns function(T) -> report, where T = { ok, newPlayer, withRoll }
return function(T)
    local R = { rows = {}, lines = {} }
    -- Jobs that do not finish in the robot's city for a reason that is written down and waits on the owner
    -- (TODO.md, "What the robot players found"). They are shown as KNOWN, and do not fail the run. Take one
    -- out of here when it is settled.
    local KNOWN = {
        ["shift/kitchen The counter"] = "waits at the counter for three citizens to be served; nobody came in ten minutes",
        ["inside/proof"] = "called off at once: its target couldn't be found in the robot's city",
    }
    local function say(fmt, ...) R.lines[#R.lines + 1] = string.format(fmt, ...) end
    local USE = IN_USE or 32

    ------------------------------------------------------------------
    -- What a player can do
    ------------------------------------------------------------------
    local function stand(p, pos, off)
        p:SetPos(pos + (off or Vector(0, 0, 0)))
    end
    local function use(p, e)
        stand(p, e:GetPos(), Vector(40, 0, 0))
        p.lookingAt = e
        return hook.Run("PlayerUse", p, e)
    end
    local function holdUse(p, e, secs)
        stand(p, e:GetPos(), Vector(40, 0, 0))
        p.lookingAt = e
        p.keys = p.keys or {}
        p.keys[USE] = true
        hook.Run("PlayerUse", p, e)
        _run(secs)
        p.keys[USE] = nil
    end
    local function kill(p, npc)
        stand(p, npc:GetPos(), Vector(120, 0, 0))
        if npc.SetHealth then npc:SetHealth(0) end
        hook.Run("OnNPCKilled", npc, p, p)
        if npc:IsValid() then npc:Remove() end
    end

    -- People a counting step would take, nearest first.
    local function matching(q, st, p)
        local out = {}
        local say0 = rawget(p, "ChatPrint")
        p.ChatPrint = function() end -- (a rule may say why someone doesn't count: only when E is really pressed)
        for npc, nst in pairs(LC.NPCs) do
            if IsValid(npc) and npc:Health() > 0 and not (st.seen and st.seen[npc]) then
                local okF, yes = pcall(function() return not st.filter or st.filter(q, p, npc, nst) end)
                if okF and yes then out[#out + 1] = npc end
            end
        end
        p.ChatPrint = say0
        local at = p:GetPos()
        table.sort(out, function(a, b)
            local da, db = a:GetPos():DistToSqr(at), b:GetPos():DistToSqr(at)
            if da ~= db then return da < db end
            return a:EntIndex() < b:EntIndex()
        end)
        return out
    end
    -- Everyone of a kind, in a fixed order.
    local function people(role)
        local out = {}
        for npc, nst in pairs(LC.NPCs) do
            if IsValid(npc) and npc:Health() > 0 and nst.role == role then out[#out + 1] = npc end
        end
        table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
        return out
    end
    -- Places a player could walk to: the layout's own points and the middles of its zones.
    local function places()
        local out = {}
        for _, pt in ipairs(LC.Points or {}) do out[#out + 1] = pt.pos end
        for _, z in ipairs(LC.Zones or {}) do out[#out + 1] = z.pos end
        return out
    end
    -- What lies loose within reach is picked up, as a player would.
    local function gather(p, r)
        for _, e in ipairs(ents.FindInSphere(p:GetPos(), r or 200)) do
            if IsValid(e) and e:GetClass() == "lc_item" then p.lookingAt = e hook.Run("PlayerUse", p, e) end
        end
    end

    -- One thing done towards the step the job is on. -> nil (did or is doing it), or why the robot can't.
    local function act(p, q, st, now, mem)
        local k = st.kind
        if k == "goto" or k == "deliver" or k == "hold" then
            stand(p, st.pos)
            p.crouching = st.crouch and true or nil
        elseif k == "survive" then
            -- staying alive; where the job says it doesn't count, walk somewhere it does
            if st.cond and not st.cond(q, p) and now >= (mem.moveAt or 0) then
                mem.moveAt = now + 2
                for _, pos in ipairs(places()) do
                    local was = p:GetPos()
                    stand(p, pos)
                    if st.cond(q, p) then break end
                    stand(p, was)
                end
            end
        elseif k == "choice" then
            if now < (mem.choiceAt or 0) then return end
            mem.choiceAt = now + 1
            local pick
            for i, o in ipairs(st.options) do
                if not o.when or o.when(q) then pick = pick or i if mem.want == "last" then pick = i end end
            end
            if not pick then return "no choice it offers can be taken" end
            T.withRoll(mem.roll or 20, function() LC.ResolveChoice(p, q.id, pick) end)
        elseif k == "target" then
            local npc = st.npc
            if not IsValid(npc) then return end -- (the job calls itself off)
            if st.action == "reach" then
                stand(p, npc:GetPos(), Vector(60, 0, 0))
            elseif st.action == "arrest" then
                stand(p, npc:GetPos(), Vector(60, 0, 0))
                if now >= (mem.arrestAt or 0) then mem.arrestAt = now + 2 LC.ArrestNPC(npc, p) end
            elseif st.action == "use" or st.action == "free" then
                if now >= (mem.useAt or 0) then mem.useAt = now + 3.5 use(p, npc) end
            else
                return "the robot can't do this to a person: " .. tostring(st.action)
            end
        elseif k == "escort" then
            local npc = st.npc
            if not IsValid(npc) then return end
            local npos, ppos = npc:GetPos(), p:GetPos()
            local to = st.pos - ppos
            to.z = 0
            if ppos:DistToSqr(npos) > 400 * 400 and not mem.fetched then
                mem.fetched = true
                stand(p, npos, Vector(60, 0, 0)) -- (walk up to them first)
            elseif ppos:DistToSqr(npos) < 220 * 220 and to:LengthSqr() > 1 then
                local step = math.min(to:Length(), 120)
                stand(p, ppos + to:GetNormalized() * step) -- (a few steps on, they follow)
            end
        elseif k == "tail" then
            local npc = st.npc
            if not IsValid(npc) then return end
            local back = npc:GetForward() * -1
            stand(p, npc:GetPos() + back * ((st.min + st.max) / 2))
        elseif k == "collect" then
            if now < (mem.useAt or 0) then return end
            mem.useAt = now + 0.5
            local e = st.items and next(st.items)
            if IsValid(e) then use(p, e) end
        elseif k == "pickup" then
            if now < (mem.useAt or 0) then return end
            mem.useAt = now + 0.5
            if IsValid(st.item) then use(p, st.item) end
        elseif k == "count" and st.search then
            local e
            for ent in pairs(st.search) do if IsValid(ent) and not st.searched[ent] then e = ent break end end
            if e then holdUse(p, e, (LC.SearchSecs or 2.5) + 0.3) end
        elseif k == "count" and st.event == "killed" then
            if now < (mem.killAt or 0) then return end
            mem.killAt = now + 1
            local list = matching(q, st, p)
            if list[1] then kill(p, list[1]) gather(p) end
        elseif k == "count" and st.event == "near_citizen" then
            -- walk up to someone not yet counted
            for _, npc in ipairs(people("citizen")) do
                if not (st.seen and st.seen[npc]) then stand(p, npc:GetPos(), Vector(60, 0, 0)) break end
            end
        elseif k == "count" and st.poll and st.event ~= "served" then
            -- a step the job watches for itself (meat in the crate, a wound patched): each needs its own doing
            return "the robot can't do this step yet: count / " .. tostring(st.event)
        elseif k == "count" and st.event == "used_npc" then
            if now < (mem.useAt or 0) then return end
            mem.useAt = now + 1
            local list = matching(q, st, p)
            if #list == 0 then
                -- nobody counts from here (a rule about where you stand, or who is watching): try by someone else
                mem.turn = (mem.turn or 0) + 1
                local all = people("citizen")
                if #all > 0 then stand(p, all[(mem.turn - 1) % #all + 1]:GetPos(), Vector(40, 0, 0)) end
                return
            end
            for _, npc in ipairs(list) do
                local nst = LC.NPCs[npc]
                if nst and now >= (nst.nextUse or 0) then use(p, npc) return end
            end
        elseif k == "count" and st.event == "served" then
            if st.pos then stand(p, st.pos) end -- (the line is served while you stand by it)
            mem.waiting = true
        elseif k == "count" and st.event == "game_done" then
            mem.game = true
            local g = LC.JobGames and LC.JobGames[p]
            if g and now - (g.startT or now) >= 3 then
                mem.skipped = (mem.skipped or 0) + 1 -- (the games have their own robots: this one is ended as an admin's test ends it)
                LC.JobGameEnd(p, "test")
            elseif not g then
                mem.noGame = (mem.noGame or 0) + 0.5
                if mem.noGame > 10 then return "the step waits for a game that never started" end
            end
        else
            return "the robot can't do this step yet: " .. tostring(k) .. (st.event and (" / " .. tostring(st.event)) or "")
        end
    end

    ------------------------------------------------------------------
    -- One job, start to finish
    ------------------------------------------------------------------
    local function fresh(f, t)
        local special, xp = nil, 900
        if t.id == "res_ministry" then f, special, xp = "resistance", "chaplain", 200 end
        R.n = (R.n or 0) + 1
        return T.newPlayer("Robot" .. R.n, f, special, xp)
    end
    local function xpOf(p)
        local f = p:GetNW2String("lcf_faction", "")
        return tonumber(p:GetPData("lcf_xp_" .. f, 0)) or 0
    end

    local drive
    local function play(t, f, mode)
        local row = { id = t.id, side = f, mode = mode }
        local p = fresh(f, t)
        -- a job posted only during one of the city's events: the event is on while the robot does it
        local event
        if t.during and not (LC.Event and table.HasValue(t.during, LC.Event)) then
            event = t.during[1]
            if not (LC.StartEvent and LC.StartEvent(event)) then
                row.result, row.why = "not offered", "the city's event it goes with (" .. tostring(event) .. ") would not start here"
                return row, p
            end
            _run(1)
        end
        row.event = event
        local okA, avail = pcall(function() return not t.available or t.available(p) end)
        if not okA then row.result, row.why = "ERROR", "available: " .. tostring(avail) return row, p end
        if not avail then row.result, row.why = "not offered", "its own conditions are not met in the robot's city" return row, p end
        local spec, err
        for _ = 1, 5 do
            local okB, s = pcall(t.build, p)
            if not okB then err = s break end
            if s then spec = s break end
        end
        if err then row.result, row.why = "ERROR", "build: " .. tostring(err) return row, p end
        if not spec then row.result, row.why = "not built", "nothing in the robot's city to build it from" return row, p end

        R.pid = (R.pid or 700000) + 1
        spec.id, spec.tmpl, spec.violent, spec.faction = R.pid, t, t.violent, f
        spec.squad, spec.during = spec.squad or t.squad, t.during
        spec.expiresPost, spec.data = CurTime() + 999, spec.data or {}
        LC.Postings[f] = LC.Postings[f] or {}
        table.insert(LC.Postings[f], spec)
        return drive(p, row, spec, mode), p
    end

    -- Take the posting and do it. Fills in the row: result, why, seconds, pay, how much was said.
    function drive(p, row, spec, mode)
        p.lcqNext = 0
        row.title, row.reward, row.limit = spec.title, spec.reward, spec.limit or 300
        R.pid = (R.pid or 700000) + 1

        local chat0, err0, hid0, xp0, t0 = #(p.chat or {}), #_errors, LC.ErrorsCount and LC.ErrorsCount() or 0, xpOf(p), CurTime()
        local notices, baseNotice = 0, LC.Notice
        LC.Notice = function(who, ...) if who == p then notices = notices + 1 end return baseNotice(who, ...) end
        local finished, success
        local hookId = "Robot" .. R.pid
        hook.Add("LivingCityQuestComplete", hookId, function(who) if who == p then finished, success = true, true end end)
        hook.Add("LivingCityQuestFailed", hookId, function(who) if who == p then finished, success = true, false end end)

        local okC, errC = pcall(LC.AcceptPosting, p, spec.id)
        local q = LC.QuestOf[p]
        local mem = { roll = (mode == "fail") and 1 or 20, want = (mode == "last") and "last" or "first" }
        local path, sig, sigAt, cant = {}, nil, CurTime(), nil
        if not okC then row.result, row.why = "ERROR", "accept: " .. tostring(errC)
        elseif not q then row.result, row.why = "FAILED", "taken, and it did not start"
        else
            local cap = row.limit + 150
            while not finished and CurTime() - t0 < cap do
                local st = q.stages[q.stage]
                if not st then break end
                local label = tostring(st.kind) .. (st.kind == "count" and (st.search and ":search" or (":" .. tostring(st.event))) or "")
                    .. (st.kind == "target" and (":" .. tostring(st.action)) or "")
                if path[#path] ~= label or mem.stage ~= q.stage then
                    path[#path + 1] = label
                    mem.stage, mem.useAt, mem.killAt, mem.arrestAt, mem.fetched, mem.waiting, mem.noGame = q.stage, nil, nil, nil, nil, nil, nil
                end
                local now = CurTime()
                local okD, why = pcall(act, p, q, st, now, mem)
                if not okD then row.result, row.why = "ERROR", "the robot's own step: " .. tostring(why) break end
                if why then cant = why break end
                _run(0.5)
                -- stuck: the same step, nothing counted, for a minute and a half of doing it
                local s2 = string.format("%d|%s|%s", q.stage, tostring(st.got), tostring(st.progress))
                if s2 ~= sig then sig, sigAt = s2, CurTime() end
                local patience = (mem.waiting or st.kind == "survive" or st.kind == "hold") and (row.limit + 100) or 90
                if CurTime() - sigAt > patience and not finished then
                    row.result = "STUCK"
                    row.why = string.format("step %d of %d (%s): \"%s\"", q.stage, #q.stages, label, tostring(st.text))
                    break
                end
            end
        end
        hook.Remove("LivingCityQuestComplete", hookId)
        hook.Remove("LivingCityQuestFailed", hookId)
        LC.Notice = baseNotice
        row.secs = CurTime() - t0
        row.path = table.concat(path, " > ")
        row.chat, row.notices, row.xp = #(p.chat or {}) - chat0, notices, xpOf(p) - xp0
        row.skipped = mem.skipped
        if not row.result then
            if cant then row.result, row.why = "robot can't", cant
            elseif finished and success then row.result = "done"
            elseif finished then
                -- what the game said when it called the job off
                local said = ""
                for i = #(p.chat or {}), math.max(1, chat0), -1 do
                    local l = tostring(p.chat[i])
                    if string.find(l, "Failed:", 1, true) then said = l break end
                end
                row.result, row.why = "FAILED", said
            else row.result, row.why = "TIMED OUT", "still going after " .. math.floor(row.secs) .. " seconds" end
        end
        if KNOWN[row.id] and (row.result == "FAILED" or row.result == "STUCK" or row.result == "TIMED OUT") then
            row.was, row.result, row.why = row.result, "KNOWN", KNOWN[row.id]
        end
        if #_errors > err0 then row.errors = tostring(_errors[#_errors]) end
        if LC.ErrorsCount and LC.ErrorsCount() > hid0 then
            local e = LC.Err.list[#LC.Err.list]
            row.errors = (row.errors and (row.errors .. " | ") or "") .. tostring(e and e.msg)
        end
        if LC.QuestOf[p] then pcall(LC.AbandonQuest, p) end
        if LC.JobGames and LC.JobGames[p] then pcall(LC.JobGameEnd, p, "quit") end
        return row
    end
    local function playAndTidy(t, f, mode)
        local row, p = play(t, f, mode)
        if row.event and LC.Event == row.event and LC.EndEvent then pcall(LC.EndEvent, true) end
        if LC.QuestOf[p] then pcall(LC.AbandonQuest, p) end
        if p and p:IsValid() then pcall(hook.Run, "PlayerDisconnected", p) p:Remove() end
        return row
    end

    -- Did the job go differently the second time (the hooks in the other order)? Only when both
    -- times it was really played: one that wasn't offered, or that the robot can't do, says nothing.
    local PLAYED = { done = true, FAILED = true, STUCK = true, ["TIMED OUT"] = true, ERROR = true }
    local function differs(row, other)
        local a, b = row.was or row.result, other.was or other.result
        if not (PLAYED[a] and PLAYED[b]) or a == b then return nil end
        return b .. (other.why and (" (" .. other.why .. ")") or "")
    end

    ------------------------------------------------------------------
    -- Every job on the boards, for every side it is offered to
    ------------------------------------------------------------------
    for _, t in ipairs(LC.QuestTemplates) do
        local sides = {}
        for f in pairs(t.factions) do sides[#sides + 1] = f end
        table.sort(sides)
        for _, f in ipairs(sides) do
            local row = playAndTidy(t, f, "first")
            R.rows[#R.rows + 1] = row
            -- The same job with the game's hooks answering in the other order. In the game the order two
            -- pieces of code hear of a key press in is not ours to choose, so a job must go the same either way.
            if row.result ~= "not offered" and row.result ~= "not built" then
                _HOOK_REVERSE = true
                local okR, other = pcall(playAndTidy, t, f, "first")
                _HOOK_REVERSE = nil
                if not okR then row.other = "ERROR: " .. tostring(other) else row.other = differs(row, other) end
            end
        end
    end

    ------------------------------------------------------------------
    -- Stories: each chain from its first part to its end
    ------------------------------------------------------------------
    local function gone(p)
        if LC.QuestOf[p] then pcall(LC.AbandonQuest, p) end
        if p:IsValid() then pcall(hook.Run, "PlayerDisconnected", p) p:Remove() end
    end
    local function storyPlayer(chain)
        local sides = {}
        for f in pairs(chain.factions or {}) do sides[#sides + 1] = f end
        table.sort(sides)
        if #sides == 0 then sides = { "resistance", "cp", "citizen", "ota", "admin", "zombie" } end
        for _, f in ipairs(sides) do
            R.n = (R.n or 0) + 1
            local okP, p = pcall(T.newPlayer, "Robot" .. R.n, f, chain.special, 900)
            if okP and p and (not chain.special or p:GetNW2String("lcf_special", "") == chain.special) then return p, f end
            if okP and p then gone(p) end
        end
    end
    local function posting(p, id)
        for _, s in ipairs(LC.StoryPostings(p)) do if s.chain == id then return s end end
    end
    local function runChain(chain, mode)
        local rows = {}
        local p, f = storyPlayer(chain)
        if not p then
            rows[1] = { id = chain.id, side = "?", result = "not offered", why = "the robot could not become who this story is for (" .. tostring(chain.special) .. ")" }
            return rows
        end
        -- (started as an admin starts one: lcq_startchain)
        local s = LC.Story(p)
        s.chains[chain.id] = { part = chain.start, data = {}, readyAt = 0 }
        LC.SaveStory(p)
        p.lcStoryPostings = nil
        local seen = {}
        for _ = 1, 14 do
            local cs = LC.ChainState(p, chain.id)
            if cs.done then break end
            local part = cs.part
            local row = { id = chain.id .. "/" .. tostring(part), side = f, mode = mode }
            rows[#rows + 1] = row
            if seen[part] then row.result, row.why = "done", "(comes round again: " .. tostring(part) .. ")" row.again = true break end
            seen[part] = true
            local spec = posting(p, chain.id)
            if not spec then
                row.result, row.why = "not built", "this part gave the robot's city nothing to build it from (or its gate is shut)"
                break
            end
            drive(p, row, spec, mode)
            if row.result ~= "done" then break end
            cs = LC.ChainState(p, chain.id)
            cs.readyAt = 0 -- (the wait between parts is real hours: skipped)
            p.lcqNext = 0
        end
        local cs = LC.ChainState(p, chain.id)
        if cs.done and rows[#rows] then rows[#rows].ended = tostring(cs.done) end
        gone(p)
        return rows
    end
    for _, chain in ipairs(LC.ChainList) do
        if chain.id ~= "shift" then
            local rows = runChain(chain, "first")
            _HOOK_REVERSE = true
            local okR, other = pcall(runChain, chain, "first")
            _HOOK_REVERSE = nil
            for i, row in ipairs(rows) do
                local o = okR and other[i]
                if not okR then row.other = "ERROR: " .. tostring(other)
                elseif o and o.id == row.id and not row.again then
                    -- (a story that took another turn the second time is another story, not another order)
                    row.other = differs(row, o)
                end
                R.rows[#R.rows + 1] = row
            end
        end
    end

    ------------------------------------------------------------------
    -- Union jobs: every kind of shift each job has
    ------------------------------------------------------------------
    local jobs = {}
    for id in pairs(LCJ and LCJ.ById or {}) do jobs[#jobs + 1] = id end
    table.sort(jobs)
    local shift = LC.Chains and LC.Chains.shift
    for _, jid in ipairs(shift and jobs or {}) do
        local played = {}
        for _, reverse in ipairs({ false, true }) do
            for _ = 1, 10 do
                R.n = (R.n or 0) + 1
                local p = T.newPlayer("Robot" .. R.n, "citizen", nil, 900)
                local okJ = LC.SetJob(p, jid, true)
                p.lcStoryPostings = nil
                local spec = okJ ~= false and posting(p, "shift")
                local key = spec and tostring(spec.title)
                if not spec then
                    if not played["none"] and not reverse then
                        played["none"] = true
                        R.rows[#R.rows + 1] = { id = "shift/" .. jid, side = "citizen", result = "not built",
                            why = "no shift of this job could be built in the robot's city" }
                    end
                elseif not reverse and not played[key] then
                    local row = { id = "shift/" .. jid, side = "citizen", mode = "first" }
                    played[key] = row
                    R.rows[#R.rows + 1] = row
                    row.id = "shift/" .. jid .. " " .. string.gsub(key, "^.-: .-: ", "")
                    drive(p, row, spec, "first")
                elseif reverse and played[key] and not played[key].checked then
                    played[key].checked = true
                    local row = { id = played[key].id, side = "citizen", mode = "first" }
                    _HOOK_REVERSE = true
                    local okD = pcall(drive, p, row, spec, "first")
                    _HOOK_REVERSE = nil
                    if not okD then played[key].other = "ERROR" else played[key].other = differs(played[key], row) end
                end
                gone(p)
            end
        end
    end

    ------------------------------------------------------------------
    -- The report
    ------------------------------------------------------------------
    local counts, order = {}, { "done", "FAILED", "STUCK", "TIMED OUT", "ERROR", "KNOWN", "robot can't", "not offered", "not built" }
    local twoWays = 0
    for _, row in ipairs(R.rows) do
        counts[row.result] = (counts[row.result] or 0) + 1
        if row.other then twoWays = twoWays + 1 end
    end
    say("ROBOT PLAYERS: %d jobs (every job on the boards for each side it is offered to, every part of every story, every Union shift)", #R.rows)
    for _, k in ipairs(order) do if counts[k] then say("  %-12s %d", k, counts[k]) end end
    say("  %-12s %d (a different result with the hooks answering in the other order)", "ORDER", twoWays)
    say("")
    say("%-11s %-34s %-11s %5s %4s %4s %3s  %s", "side", "job", "result", "secs", "xp", "chat", "ntc", "steps, and why")
    for _, row in ipairs(R.rows) do
        say("%-11s %-34s %-11s %5s %4s %4s %3s  %s%s%s%s", row.side, string.sub(row.id, 1, 34), row.result,
            row.secs and string.format("%d", row.secs) or "", row.xp and tostring(row.xp) or "", row.chat and tostring(row.chat) or "",
            row.notices and tostring(row.notices) or "", row.path or "", row.why and ((row.path and "  << " or "") .. row.why) or "",
            row.skipped and "  (game ended as a test)" or "", row.errors and ("  !! " .. row.errors) or "")
        if row.other then say("%-11s %-34s %-11s %s", "", "", "ORDER", "the other way round: " .. row.other) end
    end
    R.counts = counts
    R.text = table.concat(R.lines, "\n")
    return R
end
