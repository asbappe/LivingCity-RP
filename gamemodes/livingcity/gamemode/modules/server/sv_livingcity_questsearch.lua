--[[
    Living City: searching things with your hands, as a job's step (the owner, 14 November: "go to each
    cell and search any props (including those spawned by entities) by holding E on them ... all
    functions for entities, such as lying on the bed, using the toilet, or operating the scanner terminal,
    will be disabled by the quest holder ... and one of them will have a sharpened spoon hidden inside").

    LC.QuestSearchStage(opts) makes a job stage:
      opts.pos      where (marked)                    opts.r     how far round it things count (130)
      opts.text     the objective line                 opts.min   at least this many things to search (3)
      opts.junk     models to put down when there are fewer than min (put on the floor near pos)
      opts.hide     true: one of the things hides what's wanted (else the stage is only searched through)
      opts.found    function(q, st, ent, ply): what was found (say it); the stage ends there (return true
                    when it has ended the job itself, with LC.QB.Finish)
      opts.empty    words for a thing with nothing in it (a list, one picked)
    While the stage is on, the job holder's E on any of those things searches it instead of using it
    (the bed, the toilet, a terminal: E does nothing else for them). Searching is holding E on it for
    LC.SearchSecs (2.5) seconds, looking at it, within reach: let go or look away and it stops.
    Everything searched with nothing found also ends the stage.

    The same hold of E does other work by hand (emptying a bin, pasting a flyer, patching a pipe):
    LC.QuestHandsStage{ pos, text, model (a thing put down at pos to work on) or ent (the thing itself,
    or a function(q, st) giving it), ghost (the thing is see-through), busy (the words by the bar) }.
    Nothing is said in chat for those.
]]

if CLIENT then return end

LC = LC or {}

LC.SearchSecs = 2.5
local REACH = 110
local DEFAULT_JUNK = { "models/props_junk/cardboard_box002a.mdl", "models/props_junk/garbage_bag001a.mdl", "models/props_c17/furnituredrawer001a.mdl",
    "models/props_junk/plasticbucket001a.mdl", "models/props_c17/furnituremattress001a.mdl" }
local EMPTY = { "Nothing in it.", "Nothing. Just dust.", "Nothing hidden there.", "You turn it over: nothing." }

-- What counts as a thing to search near pos: props and the gamemode's own fixtures, never people,
-- doors, walls, weapons or what lies loose as an item to pick up.
local function Searchable(e)
    if not IsValid(e) or e:IsPlayer() or e:IsNPC() or e:IsWeapon() then return false end
    local c = e:GetClass()
    if string.find(c, "door", 1, true) or string.find(c, "func_", 1, true) == 1 or c == "lc_item" or c == "worldspawn" then return false end
    if IsValid(e:GetParent()) and (e:GetParent():IsNPC() or e:GetParent():IsPlayer()) then return false end
    return string.find(c, "prop_", 1, true) == 1 or string.find(c, "lc_", 1, true) == 1
end
LC.QuestSearchable = Searchable

local function Gather(pos, r)
    local out = {}
    for _, e in ipairs(ents.FindInSphere(pos, r)) do
        if Searchable(e) and math.abs(e:GetPos().z - pos.z) < 100 then out[#out + 1] = e end
    end
    return out
end

function LC.QuestSearchStage(opts)
    local Q = LC.QB
    local st = { kind = "count", need = 1, text = opts.text or "Search everything there (hold E on each)", pos = opts.pos, r = opts.r or 130 }
    st.search = {}
    st.onEnter = function(q, s)
        local list = {}
        if opts.things then
            local got = opts.things(q, s)
            for _, e in ipairs(IsValid(got) and { got } or (type(got) == "table" and got or {})) do if IsValid(e) then list[#list + 1] = e end end
        elseif not opts.only then
            list = Gather(s.pos, s.r)
        end
        local junk = opts.junk or DEFAULT_JUNK
        local want = opts.things and (#list == 0 and 1 or 0) or (opts.min or 3)
        local tries = 0
        while #list < want and tries < 8 do
            tries = tries + 1
            local a = math.rad(math.random(0, 359))
            local spot = want == 1 and s.pos or (s.pos + Vector(math.cos(a) * math.random(20, 60), math.sin(a) * math.random(20, 60), 0))
            local e = Q and Q.SpawnItem and Q.SpawnItem(q, junk[math.random(#junk)], spot)
            if IsValid(e) then
                list[#list + 1] = e
                if opts.ghost and e.SetRenderMode then e:SetRenderMode(RENDERMODE_TRANSCOLOR or 1) e:SetColor(Color(255, 255, 255, 110)) end
            end
        end
        s.quiet, s.busy = opts.quiet, opts.busy
        s.search, s.searched, s.got = {}, {}, 0
        for _, e in ipairs(list) do s.search[e] = true end
        s.need = math.max(1, #list)
        s.hidden = (opts.hide and #list > 0) and list[math.random(#list)] or nil
        s.foundFn, s.emptyWords = opts.found, opts.empty or EMPTY
    end
    return st
end

-- Work done by hand on one thing: the same hold of E, with nothing said in chat.
function LC.QuestHandsStage(opts)
    local ent = opts.ent
    return LC.QuestSearchStage({ pos = opts.pos, text = opts.text, r = opts.r, quiet = true, only = true, min = 1, ghost = opts.ghost,
        busy = opts.busy or "Working... (keep holding E)", junk = opts.model and { opts.model } or nil,
        things = ent and function(q, st)
            if type(ent) == "function" then return ent(q, st) end
            return ent
        end or nil })
end

-- The stage the holder is on, if it's a search, and the thing is in it.
local function SearchOf(ply, ent)
    local q = LC.QuestOf and LC.QuestOf[ply]
    local st = q and q.stages and q.stages[q.stage]
    if st and st.search and st.search[ent] then return q, st end
    return nil
end
LC.QuestSearchOf = SearchOf

LC.Searching = LC.Searching or {} -- [ply] = { ent, q, st, untilT }

local function Clear(ply)
    LC.Searching[ply] = nil
    if IsValid(ply) then
        ply:SetNW2String("lcu_progress", "")
        ply:SetNW2Float("lcu_pick_until", 0)
    end
end

-- E on a thing: start searching it (and nothing else happens: its own use is off for the job holder).
hook.Add("PlayerUse", "LivingCityQuestSearch", function(ply, ent)
    local q, st = SearchOf(ply, ent)
    if not q then return end
    if st.searched[ent] then
        if not st.quiet and (ply.lcSearchSaid or 0) < CurTime() then ply.lcSearchSaid = CurTime() + 1 ply:ChatPrint("[Search] You've searched that already.") end
        return false
    end
    if not LC.Searching[ply] then
        local now = CurTime()
        LC.Searching[ply] = { ent = ent, q = q, st = st, untilT = now + LC.SearchSecs }
        ply:SetNW2String("lcu_progress", st.busy or "Searching... (keep holding E)")
        ply:SetNW2Float("lcu_pick_start", now)
        ply:SetNW2Float("lcu_pick_until", now + LC.SearchSecs)
    end
    return false
end)

-- Done searching one thing.
function LC.QuestSearchDone(ply, q, st, ent)
    if st.searched[ent] then return end
    st.searched[ent] = true
    st.got = (st.got or 0) + 1
    local Q = LC.QB
    if ent == st.hidden then
        local handled = false
        if st.foundFn then
            local ok, r = LC.Try(st.foundFn, q, st, ent, ply)
            handled = ok and r == true -- (true: the job was ended there, nothing more to do)
        end
        if not handled and not q.done and Q and Q.Advance then Q.Advance(q) end
        return
    end
    if not st.quiet then ply:ChatPrint("[Search] " .. st.emptyWords[math.random(#st.emptyWords)]) end
    if st.got >= st.need then
        if Q and Q.Advance then Q.Advance(q) end
    elseif Q and Q.SendStateAll then
        Q.SendStateAll(q)
    end
end

function LC.QuestSearchTick(now)
    for ply, s in pairs(LC.Searching) do
        local q = IsValid(ply) and LC.QuestOf and LC.QuestOf[ply]
        local holding = IsValid(ply) and ply:Alive() and ply.KeyDown and ply:KeyDown(IN_USE)
        local tr = holding and ply:GetEyeTrace()
        local looking = tr and tr.Entity == s.ent and tr.HitPos:DistToSqr(ply:EyePos()) < REACH * REACH
        if not IsValid(s.ent) or q ~= s.q or not (s.q.stages and s.q.stages[s.q.stage] == s.st) then
            Clear(ply)
        elseif not holding or not looking then
            Clear(ply)
            if not s.st.quiet then ply:ChatPrint("[Search] You stop searching. (Hold E on it until it's done.)") end
        elseif now >= s.untilT then
            Clear(ply)
            LC.QuestSearchDone(ply, s.q, s.st, s.ent)
        end
    end
end
timer.Create("LivingCityQuestSearch", 0.1, 0, function()
    local ok, err = LC.Try(LC.QuestSearchTick, CurTime())
    if not ok and LC.Error then LC.Error("quest search", err) end
end)
hook.Add("PlayerDisconnected", "LivingCityQuestSearch", function(ply) LC.Searching[ply] = nil end)
