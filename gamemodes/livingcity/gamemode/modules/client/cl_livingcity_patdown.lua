--[[
    Living City (client): the quick menu that comes with cuffing someone (sv_livingcity_patdown.lua)

    The owner, 12 November: an optional patdown at arrest, and no mouse windows:
    "a special hidden menu that appears for these situations similar to the F1 and
    F2 quick menus". It comes up by itself when you cuff a player and goes when
    they're out of your reach; 0 closes it (the patdown is skipped, and can still
    be done later from F1 while they're cuffed).
]]

LC_CL = LC_CL or {}

local function Send(...) if LC_CL.SendAction then LC_CL.SendAction(...) end end

net.Receive("lc_custody", function()
    local target, name = net.ReadEntity(), net.ReadString()
    if not IsValid(target) or not LC_CL.OpenSituation then return end
    local npc = not target:IsPlayer()
    local items = {
        { label = "Pat them down", run = function() Send("patdown", "", target) end },
        { label = "No time: walk them along / let go", run = function() Send("drag") end },
    }
    if not npc then items[3] = { label = "Take the cuffs off", run = function() Send("untie") end } end
    LC_CL.OpenSituation({ id = "custody", title = name .. ", cuffed", items = items,
        note = npc and "Search them now, or nobody may: what they hide goes into the cell with them."
            or "A patdown finds weapons, radios and tools in their pockets. Skip it and they keep what they carry.",
        stay = function()
            local me = LocalPlayer()
            return IsValid(target) and IsValid(me) and target:GetNW2Bool(npc and "lc_cuffed" or "lc_tied", false)
                and me:GetPos():DistToSqr(target:GetPos()) < 250 * 250
        end })
end)

-- The evidence locker (sv_livingcity_evidence.lua): E on it. Locked: pick it or pry it. Open: what's inside.
net.Receive("lc_evlocker", function()
    local ent, open = net.ReadEntity(), net.ReadBool()
    local list = {}
    for _ = 1, net.ReadUInt(4) or 0 do list[#list + 1] = { key = net.ReadString(), label = net.ReadString() } end
    if not IsValid(ent) or not LC_CL.OpenSituation then return end
    local function Do(what, key)
        net.Start("lc_evlocker_do")
        net.WriteEntity(ent)
        net.WriteString(what)
        net.WriteString(key or "")
        net.SendToServer()
    end
    local items, note = {}, nil
    if not open then
        items[1] = { label = "Pick the lock (needs a lockpick)", run = function() Do("pick") end }
        items[2] = { label = "Pry it open (needs a crowbar: loud)", run = function() Do("pry") end }
        note = "Locked. What Civil Protection takes off people is in here."
    else
        for _, e in ipairs(list) do items[#items + 1] = { label = "Take: " .. e.label, run = function() Do("take", e.key) end } end
        if #items == 0 then note = "Empty shelves. Nothing has been confiscated lately, or it has been burned." end
    end
    LC_CL.OpenSituation({ id = "evlocker", title = "The evidence locker", items = items, note = note,
        stay = function()
            local me = LocalPlayer()
            return IsValid(ent) and IsValid(me) and me:GetPos():DistToSqr(ent:GetPos()) < 180 * 180
        end })
end)

------------------------------------------------------------------------
-- Executions, the prisoner's answers, and the leader's clipboard (sv_livingcity_rebelrule.lua,
-- sv_livingcity_chairplayer.lua). All quick menus: number keys, no mouse.
------------------------------------------------------------------------

-- The "Execution" page at the cage and the chair. A Lieutenant or above does it; a Fighter asks leave, or doesn't.
function LC_CL.ExecutionPage(Do, target)
    return function()
        local me = LocalPlayer()
        local items = {}
        if me:GetNW2Int("lcf_rank", 1) >= 4 then
            items[1] = { label = "Execute them", run = function() Do("execute") end }
        elseif IsValid(target) and me:GetNW2Entity("lc_exec_leave") == target then
            items[1] = { label = "Execute them (you have permission)", run = function() Do("execute") end }
        else
            items[1] = { label = "Ask permission to execute them", run = function() Do("askleave") end }
            items[2] = { label = "Execute them without permission", run = function() Do("execnoleave") end }
        end
        return { title = "Execution", items = items }
    end
end

-- In the chair yourself: each question, and your answer.
net.Receive("lc_chair_q", function()
    local chair, question = net.ReadEntity(), net.ReadString()
    if not IsValid(chair) then
        if LC_CL.CloseSituation then LC_CL.CloseSituation("chairq") end
        return
    end
    if not LC_CL.OpenSituation then return end
    local function Answer(how)
        net.Start("lc_chair_a")
        net.WriteString(how)
        net.SendToServer()
    end
    LC_CL.OpenSituation({ id = "chairq", title = "They ask", note = question,
        items = {
            { label = "Tell the truth", run = function() Answer("truth") end },
            { label = "Lie", run = function() Answer("lie") end },
            { label = "Say nothing", run = function() Answer("silent") end },
        },
        stay = function() local me = LocalPlayer() return IsValid(me) and IsValid(me:GetNW2Entity("lc_chair_in")) end })
end)

-- A Fighter asks leave (to every Lieutenant and above who is on).
net.Receive("lc_exec_ask", function()
    local by, who, name = net.ReadEntity(), net.ReadString(), net.ReadString()
    if not LC_CL.OpenSituation then return end
    local function Answer(yes)
        net.Start("lc_exec_answer")
        net.WriteEntity(by)
        net.WriteBool(yes)
        net.SendToServer()
    end
    LC_CL.OpenSituation({ id = "execask", title = who .. " asks permission", note = who .. " asks permission to execute " .. name .. ".",
        items = {
            { label = "Give permission", run = function() Answer(true) end },
            { label = "Refuse", run = function() Answer(false) end },
        } })
end)

-- A prisoner was killed without leave: the highest-ranked member answers for the cell.
net.Receive("lc_exec_judge", function()
    local who, name, refused = net.ReadString(), net.ReadString(), net.ReadBool()
    if not LC_CL.OpenSituation then return end
    local function Judge(what)
        net.Start("lc_exec_judged")
        net.WriteString(what)
        net.SendToServer()
    end
    LC_CL.OpenSituation({ id = "execjudge", title = "Without permission",
        note = who .. " killed " .. name .. (refused and " after permission was refused." or " without permission.") .. " The cell waits for your answer.",
        items = {
            { label = "Expel them", run = function() Judge("expel") end },
            { label = "Break them in rank", run = function() Judge("demote") end },
            { label = "Order their execution", run = function() Judge("execute") end },
            { label = "Stand by them", run = function() Judge("stand") end },
        } })
end)

-- The clipboard: paper and boxes. Only the leader's pencil marks it.
net.Receive("lc_rebelclip", function()
    local leader, brutal, execute, symp = net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()
    local priority, mood, word = net.ReadString(), net.ReadString(), net.ReadString()
    if not LC_CL.OpenSituation then return end
    local function Set(key)
        return function()
            net.Start("lc_rebelclip_do")
            net.WriteString(key)
            net.SendToServer()
        end
    end
    local function Box(on) return on and "[x] " or "[  ] " end
    LC_CL.OpenSituation({ id = "rebelclip", title = leader and "The cell's rules" or "The cell's rules (the leader's to change)", note = word,
        items = {
            { label = Box(brutal) .. "Hands may be laid on prisoners", run = Set("brutal"), disabled = not leader },
            { label = Box(execute) .. "Prisoners may be executed, with permission", run = Set("execute"), disabled = not leader },
            { label = Box(symp) .. "Sympathizers who turn are fair game", run = Set("sympathizers"), disabled = not leader },
            { label = "Priority: " .. priority, run = Set("priority"), disabled = not leader },
            { label = "Mood: " .. (mood == "" and "as events make it" or mood), run = Set("mood"), disabled = not leader },
        } })
end)
