--[[
    Living City (server): the patdown, lockpicks on cuffs, and players in the Resistance's cage

    The owner, 12 November: "we need a patdown when being brought into prison,
    both CP and resistance, or at least the option of one ... if it's a
    firefight or dangerous then the arresting party can choose to skip it, and
    maybe nobody remembers to do it later, meaning lockpicks and other useful
    items could be snuck into prison", and "prisoners should be able to 'work
    at cuffs' ... and if they happen to have a lockpick can try to use it on
    the cuffs, and ... on the prison cell door".

    Before this, cuffing took what was in the hands and nothing from the
    pockets; that is still what happens when nobody pats the prisoner down.

    The patdown   Whoever cuffs a player gets a quick menu (the owner: no mouse
                  windows): pat them down, drag them, uncuff, or leave it. It
                  takes a few seconds beside them and finds every weapon, radio
                  and tool (lockpicks, bypasses, keycards) in their pockets. A
                  unit bags it as evidence; anyone else keeps it. It can also be
                  done later (F1, looking at them) for as long as they're cuffed.
                  A city unit that walks a prisoner in pats them down first,
                  unless it's in a firefight.
    The cuffs     With a lockpick: F1 > Pick the cuffs. Quicker than working at
                  them, but the pick can snap, and a captor who sees it takes it.
    The cage      A Fighter or above dragging a cuffed player to the Resistance's
                  cage puts them in it (as a unit's drag to a cell does). Held
                  lc_rebel_hold seconds, then let out and uncuffed. Hands free,
                  a lockpick opens the padlock: F1 > Pick the cage's padlock.

    lc_patdown 1/0 (0: no patdown offered, and city units don't do one).
]]

LC = LC or {}

local cvOn = CreateConVar("lc_patdown", "1", FCVAR_ARCHIVE, "A patdown can be done on a cuffed player (weapons, radios and tools in their pockets are taken); city units do one before walking a prisoner in")

local PAT_SECS, PAT_REACH = 4, 130
local PICK_OK, PICK_SNAP = 0.65, 0.4
local WATCH = 450

LC.Patted = LC.Patted or {} -- [ply] = true: patted down while cuffed, this time
LC.RebelHeldPly = LC.RebelHeldPly or {} -- [ply] = { cage, by, at, slot }
local HP = LC.RebelHeldPly

if util.AddNetworkString then util.AddNetworkString("lc_custody") end

local function On() return cvOn:GetBool() end
local function Nick(p) return IsValid(p) and p:Nick() or "someone" end
local function Roll() return LC.PatdownRoll and LC.PatdownRoll() or math.random() end
local function IsUnit(p)
    local f = IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") or ""
    return f == "cp" or f == "ota" or f == "admin"
end
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < 600 * 600 then ply:ChatPrint("** " .. text) end
    end
end

------------------------------------------------------------------------
-- The patdown
------------------------------------------------------------------------

local function Finds(it) return it.use == "arm" or it.radio ~= nil or it.tool ~= nil end

-- What a patdown would find in their pockets: { id = how many }.
function LC.PatdownFinds(target)
    return LC.ItemsWhere and LC.ItemsWhere(target, Finds) or {}
end

-- How likely one of these is found by hands going over a coat. times: which search of this prisoner it is (1, 2...).
function LC.PatdownChance(it, times)
    if not it then return 0 end
    local c
    if it.use == "arm" then c = 0.97
    elseif it.tool == "lockpick" then c = 0.5
    elseif it.tool == "keycard" then c = 0.6
    elseif it.radio ~= nil then c = 0.9
    else c = 0.85 end
    if c < 0.9 and (times or 1) > 1 then c = c * 0.5 ^ ((times or 1) - 1) end
    return c
end

-- ok, or false and why.
function LC.MayPatDown(by, target)
    if not On() then return false, "Not on this server." end
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return false, "Look at someone cuffed, up close." end
    if not IsValid(by) or by == target then return false end
    local t = LC.Tied and LC.Tied[target]
    if not t then return false, "Their hands aren't cuffed." end
    if LC.IsTied(by) then return false, "Your own hands are cuffed." end
    if by:GetPos():DistToSqr(target:GetPos()) > PAT_REACH * PAT_REACH then return false, "Get closer." end
    if not (IsUnit(by) or by:IsAdmin() or t.by == by or (LC.RebelMayHold and LC.RebelMayHold(by))) then
        return false, "They aren't yours to search."
    end
    return true
end

-- The patdown itself: takes what it finds. by: a player, an NPC unit, or nil. Returns the names of what was taken.
function LC.PatdownDo(by, target)
    local t = LC.Tied and LC.Tied[target]
    if not IsValid(target) or not t then return nil end
    -- A gun is nearly impossible to hide; a lockpick is a toss-up, each one by itself, so some may be left (the owner,
    -- 12 November). Searching again can turn up more, but what was missed once is hidden well: half the odds each time.
    local times = (tonumber(LC.Patted[target]) or 0) + 1
    LC.Patted[target] = times
    local keeps = IsValid(by) and by:IsPlayer() and not IsUnit(by)
    local names = {}
    for id, have in pairs(LC.PatdownFinds(target)) do
        local chance = LC.PatdownChance(LCS and LCS.Items and LCS.Items[id], times)
        local n = 0
        for _ = 1, have do if Roll() < chance then n = n + 1 end end
        if n > 0 and LC.TakeItem(target, id, n) then
            local it = LCS and LCS.Items and LCS.Items[id]
            names[#names + 1] = (n > 1 and (n .. " x ") or "") .. (it and it.name or id)
            if keeps and LC.GiveItem then LC.GiveItem(by, id, n)
            else hook.Run("LivingCityPatdownBagged", id, n, target, by) end -- (the evidence locker: sv_livingcity_evidence.lua)
        end
    end
    table.sort(names)
    -- what was taken out of their hands when they were cuffed is found too: it isn't handed back
    local had = #t.weapons
    t.weapons = {}
    local what = #names > 0 and table.concat(names, ", ") or nil
    if what then
        target:ChatPrint("[Miscount] Hands go through your pockets. Taken: " .. what .. ".")
    else
        target:ChatPrint("[Miscount] Hands go through your pockets, and find nothing.")
    end
    if IsValid(by) and by:IsPlayer() then
        by:ChatPrint(what and ("You find: " .. what .. (keeps and ". You keep it." or ". Bagged as evidence."))
            or ("Nothing in their pockets" .. (had > 0 and ": only what you took from their hands." or ".")))
    end
    hook.Run("LivingCityPattedDown", target, by, names)
    return names
end

function LC.PatdownStart(by, target)
    local ok, why = LC.MayPatDown(by, target)
    if not ok then return false, why end
    target:ChatPrint("[Miscount] " .. "You're being patted down.")
    if not LC.StartTask then LC.PatdownDo(by, target) return true end
    return LC.StartTask(by, PAT_SECS, "Patting them down...", {
        maxMove = 40, cancelText = "You leave their pockets alone.",
        done = function(p)
            if not IsValid(target) or not (LC.Tied and LC.Tied[target]) or p:GetPos():DistToSqr(target:GetPos()) > (PAT_REACH + 40) ^ 2 then
                return p:ChatPrint("They're out of your hands.")
            end
            LC.PatdownDo(p, target)
        end,
    })
end

-- Cuffed by a player: that player's quick menu for it (cl_livingcity_patdown.lua).
hook.Add("LivingCityTied", "LivingCityPatdown", function(target, tier)
    LC.Patted[target] = nil
    if not On() or not IsValid(tier) or not tier:IsPlayer() or not IsValid(target) then return end
    net.Start("lc_custody")
    net.WriteEntity(target)
    net.WriteString(target:Nick())
    net.Send(tier)
end)

hook.Add("LivingCityUntied", "LivingCityPatdown", function(target) if target then LC.Patted[target] = nil end end)

-- A city unit walks them in: it pats them down first, unless it's in a fight (sv_livingcity_march.lua).
hook.Add("LivingCityMarchStarted", "LivingCityPatdown", function(ply, m)
    if not On() or not IsValid(ply) or not (LC.Tied and LC.Tied[ply]) then return end
    local unit = m and (m.unit or m.lead or m.npc)
    if IsValid(unit) and LC.CopInFirefight and LC.CopInFirefight(unit) then
        ply:ChatPrint("[Miscount] No time to search you: the unit shoves you along.")
        return
    end
    LC.PatdownDo(IsValid(unit) and unit or nil, ply)
end)

------------------------------------------------------------------------
-- Citizens and rebels (NPCs) in custody: what they hide, and what happens when nobody looks
------------------------------------------------------------------------

local NPC_SLIP = 75 -- seconds in a cell or the cage before a hidden pick is used

-- What this one has on them, worked out once each time they're taken: { what = a thing (or nil), picks = how many
-- lockpicks }. Who carries one (the owner, 12 November: not everyone, not nobody; "a resistance sympathizer would more
-- often have a lockpick, and resistance members almost always"): an ordinary citizen now and then (6 in 100, one),
-- a sympathizer about one time in three (one or two), a rebel nearly always (85 in 100, one to three).
function LC.NPCHides(npc, st)
    st = st or (LC.NPCs and LC.NPCs[npc])
    if not st then return nil end
    if st.lcHidden == nil then
        local odds, most = 0.06, 1
        if st.role == "rebel" then odds, most = 0.85, 3 elseif st.rebel then odds, most = 0.35, 2 end
        local picks = 0
        if Roll() < odds then picks = 1 + math.floor(Roll() * most * 0.999) end
        st.lcHidden = { what = LC.SearchNPCRoll and LC.SearchNPCRoll(st) or nil, picks = picks }
    end
    return st.lcHidden
end

local function NPCHeld(npc)
    return (LC.NPCCustody and LC.NPCCustody[npc] ~= nil) or (LC.RebelHeld and LC.RebelHeld[npc] ~= nil and not LC.RebelHeld[npc].walking)
end

function LC.MayPatDownNPC(by, npc)
    if not On() then return false, "Not on this server." end
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st or not NPCHeld(npc) then return false, "They aren't in anyone's hands." end
    if IsValid(by) and by:IsPlayer() then
        if not (IsUnit(by) or by:IsAdmin() or (LC.RebelMayHold and LC.RebelMayHold(by))) then return false, "They aren't yours to search." end
        if by:GetPos():DistToSqr(npc:GetPos()) > 220 * 220 then return false, "Get closer." end
    end
    return true
end

-- by: a player, an NPC unit, or nil. Returns the names of what was found.
function LC.PatdownNPC(by, npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return nil end
    local h = LC.NPCHides(npc, st)
    st.lcPatted = (tonumber(st.lcPatted) or 0) + 1
    local byPlayer = IsValid(by) and by:IsPlayer()
    local keeps = byPlayer and not IsUnit(by)
    local names = {}
    -- (only a player unit's finds go to the evidence room: the city's own arrests would fill it and set off burnings)
    -- (each lockpick is a toss-up, and less each time they're searched again: some may be left)
    local chance = LC.PatdownChance({ tool = "lockpick" }, st.lcPatted)
    local got = 0
    for _ = 1, (h.picks or 0) do if Roll() < chance then got = got + 1 end end
    if got > 0 then
        h.picks = h.picks - got
        names[#names + 1] = got > 1 and (got .. " lockpicks") or "a lockpick"
        if keeps and LC.GiveItem then LC.GiveItem(by, "lockpick", got) elseif byPlayer then hook.Run("LivingCityPatdownBagged", "lockpick", got, npc, by) end
    end
    if h.what then
        names[#names + 1] = tostring(h.what)
        if byPlayer and not keeps and LC.EvidenceAdd then LC.EvidenceAdd(nil, 1, "arrest", h.what) end
    end
    h.what = nil
    if IsValid(by) and by:IsPlayer() then
        by:ChatPrint(#names > 0 and ("You find: " .. table.concat(names, ", ") .. (keeps and "." or ". Bagged as evidence.")) or "Nothing on them.")
    end
    hook.Run("LivingCityPattedDown", npc, by, names)
    return names
end

function LC.PatdownNPCStart(by, npc)
    local ok, why = LC.MayPatDownNPC(by, npc)
    if not ok then return false, why end
    if not LC.StartTask then LC.PatdownNPC(by, npc) return true end
    return LC.StartTask(by, PAT_SECS, "Patting them down...", {
        maxMove = 40, cancelText = "You leave their pockets alone.",
        done = function(p) if LC.MayPatDownNPC(p, npc) then LC.PatdownNPC(p, npc) end end,
    })
end

-- Cuffed by Civil Protection: a fresh start; a city unit searches unless it's in a fight; a player gets the quick menu.
hook.Add("LivingCityIncarcerated", "LivingCityPatdownNPC", function(npc, _, _, arrester)
    if not IsValid(npc) or npc:IsPlayer() then return end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.lcHidden, st.lcPatted, st.lcHeldSince, st.lcCuffSecs, st.lcCuffCue = nil, nil, nil, nil, nil
    if not On() then return end
    if IsValid(arrester) and arrester:IsPlayer() then
        net.Start("lc_custody")
        net.WriteEntity(npc)
        net.WriteString("Your prisoner")
        net.Send(arrester)
    elseif not (IsValid(arrester) and LC.CopInFirefight and LC.CopInFirefight(arrester)) then
        LC.PatdownNPC(IsValid(arrester) and arrester or nil, npc)
    end
end)

local function NameOfNPC(npc)
    return (LC.NPCStr and LC.NPCStr(npc, "lc_pname", "") ~= "" and LC.NPCStr(npc, "lc_pname", "")) or (npc.lcProfile and npc.lcProfile.name) or "A prisoner"
end

-- Nobody looked, and they had a pick: out of the cell, or out of the cage.
function LC.NPCSlipTick(now)
    now = now or CurTime()
    if not On() then return 0 end
    local out = 0
    for npc, h in pairs(LC.RebelHeld or {}) do
        local st = h.st
        if IsValid(npc) and st and not h.walking then
            if st.lcHideFor ~= h then st.lcHideFor, st.lcHidden, st.lcPatted = h, nil, nil end
            local hid = LC.NPCHides(npc, st)
            if (hid.picks or 0) > 0 and now - h.at > NPC_SLIP then
                hid.picks = hid.picks - 1
                if LC.RebelMoodPush then LC.RebelMoodPush(1, 0) end
                local name, cage = NameOfNPC(npc), h.cage
                if LC.CageFree then LC.CageFree(npc) end
                if IsValid(cage) then Scene(cage:GetPos(), "The cage's padlock is hanging open. " .. name .. " is gone.") end
                local p = npc.lcProfile
                if p and p.id and LC.ChronicleAdd then LC.ChronicleAdd({ k = "escaped", s = p.id, sn = name, pred = "picked the padlock of the Resistance's cage and got away", pos = npc:GetPos(), w = 3 }) end
                out = out + 1
            end
        end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if st.state == "jailed" and st.lcHidden and (st.lcHidden.picks or 0) > 0 and IsValid(npc) then
            st.lcHeldSince = st.lcHeldSince or now
            if now - st.lcHeldSince > NPC_SLIP then
                st.lcHidden.picks, st.lcHeldSince = st.lcHidden.picks - 1, nil
                local name = NameOfNPC(npc)
                if LC.ReleaseNPCPrisoner then LC.ReleaseNPCPrisoner(npc, st, now, true) end
                if LC.RadioNotice then LC.RadioNotice("cp", "A prisoner has picked a cell door and walked out. Nobody searched them.") end
                local p = npc.lcProfile
                if p and p.id and LC.ChronicleAdd then LC.ChronicleAdd({ k = "escaped", s = p.id, sn = name, pred = "picked the lock of a cell and walked out of the prison", pos = npc:GetPos(), w = 3 }) end
                out = out + 1
            end
        end
    end
    return out
end
if timer and timer.Create then timer.Create("LivingCityNPCSlip", 5, 0, function() LC.NPCSlipTick(CurTime()) end) end

-- Cuffed and being walked in, with a pick nobody found (the owner, 12 November: "do NPCs who may have a lockpick hide
-- them and attempt to get out of cuffs? yes please!"). They work at the cuffs only while no captor is looking at them:
-- CUFF_WORK seconds of that, then a try (the same odds as a player's). A captor who looks while they're at it may
-- catch the movement: the cue to pat them down. Out of the cuffs, they run.
local CUFF_WORK, CUFF_TICK = 20, 2

-- Is a captor looking at this cuffed one? Returns the player who is (or true for a city unit), or nil.
function LC.NPCCuffsWatched(npc, c)
    local L = c and c.leader
    if IsValid(L) and not L:IsPlayer() then
        if not (LC.CopInFirefight and LC.CopInFirefight(L)) and L:GetPos():DistToSqr(npc:GetPos()) < 300 * 300 then return true end
    end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and (IsUnit(p) or p == L) and p:GetPos():DistToSqr(npc:GetPos()) < 400 * 400 then
            local to = npc:GetPos() - p:GetPos()
            to.z = 0
            if to:LengthSqr() > 1 then to:Normalize() end
            local aim = p:EyeAngles():Forward()
            if aim:Dot(to) > 0.5 and (not LC.LineOfSight or LC.LineOfSight(p:EyePos(), npc:GetPos() + Vector(0, 0, 40), p, npc)) then return p end
        end
    end
    return nil
end

function LC.NPCCuffTick(now)
    now = now or CurTime()
    if not On() then return 0 end
    local out = 0
    for npc, c in pairs(LC.NPCCustody or {}) do
        local st = c.st
        if IsValid(npc) and st and LC.NPCs[npc] == st and st.state == "detained" then
            local hid = LC.NPCHides(npc, st)
            if (hid.picks or 0) > 0 then
                local seen = LC.NPCCuffsWatched(npc, c)
                if seen then
                    -- caught at it, now and then: only once they have really started
                    if (st.lcCuffSecs or 0) > 0 and seen ~= true and now >= (st.lcCuffCue or 0) and Roll() < 0.3 then
                        st.lcCuffCue = now + 15
                        seen:ChatPrint("** " .. NameOfNPC(npc) .. "'s hands are busy behind their back. Something glints.")
                    end
                else
                    st.lcCuffSecs = (st.lcCuffSecs or 0) + CUFF_TICK
                    npc:SetNW2Float("lc_cuff_work_until", now + CUFF_TICK + 0.5) -- (their hands fiddle: cl_livingcity_cuffed.lua)
                    if st.lcCuffSecs >= CUFF_WORK then
                        if Roll() < PICK_OK then
                            hid.picks, st.lcCuffSecs = hid.picks - 1, nil
                            local name, from = NameOfNPC(npc), IsValid(c.leader) and c.leader or npc:GetPos()
                            Scene(npc:GetPos(), name .. "'s cuffs drop to the ground. They run.")
                            npc:EmitSound("physics/metal/metal_solid_impact_soft1.wav", 65)
                            npc:SetNW2Bool("lc_cuffed", false)
                            if LC.Release then LC.Release(npc, st) end
                            st.jailUntil = nil
                            if LC.SetState then LC.SetState(npc, st, "idle") end
                            st.untilT = now + 1
                            if LC.NPCFlee then LC.NPCFlee(npc, from, 40) end
                            local p = npc.lcProfile
                            if p and p.id and LC.ChronicleAdd then LC.ChronicleAdd({ k = "escaped", s = p.id, sn = name, pred = "picked their cuffs on the way to the cells and ran", pos = npc:GetPos(), w = 3 }) end
                            out = out + 1
                        elseif Roll() < PICK_SNAP then
                            hid.picks, st.lcCuffSecs = hid.picks - 1, nil -- (the pick snapped: with another, they start again)
                        else
                            st.lcCuffSecs = CUFF_WORK - 10 -- (it wouldn't give: another go in a while)
                        end
                    end
                end
            end
        end
    end
    return out
end
if timer and timer.Create then timer.Create("LivingCityNPCCuffs", CUFF_TICK, 0, function() LC.NPCCuffTick(CurTime()) end) end

------------------------------------------------------------------------
-- A lockpick on the cuffs
------------------------------------------------------------------------

-- A captor who can see their hands: a unit, a Fighter or above, or whoever cuffed them.
function LC.CuffsWatched(ply)
    local t = LC.Tied and LC.Tied[ply]
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and p:GetPos():DistToSqr(ply:GetPos()) < WATCH * WATCH
            and (IsUnit(p) or (LC.RebelMayHold and LC.RebelMayHold(p)) or (t and t.by == p))
            and (not LC.LineOfSight or LC.LineOfSight(p:EyePos(), ply:EyePos(), p)) then
            return p
        end
    end
    return nil
end

local function PickFails(ply, lock)
    if Roll() < PICK_SNAP then
        LC.TakeItem(ply, "lockpick", 1)
        ply:EmitSound("physics/metal/metal_solid_impact_soft1.wav", 60)
        ply:ChatPrint("Your pick snaps in the " .. lock .. ".")
    else
        ply:ChatPrint("The " .. lock .. " won't give. Try again.")
    end
end

function LC.PickCuffsDone(p)
    local t = LC.Tied and LC.Tied[p]
    if not t or not LC.HasItem(p, "lockpick") then return false end
    local seen = IsValid(t.escort) and t.escort or LC.CuffsWatched(p)
    if seen then
        LC.TakeItem(p, "lockpick", 1)
        p:ChatPrint("[Miscount] They see the pick in your fingers, and take it off you.")
        if seen:IsPlayer() then seen:ChatPrint(Nick(p) .. " had a lockpick in their cuffs. You take it.") end
        return false
    end
    if Roll() >= PICK_OK then PickFails(p, "cuffs") return false end
    if LC.WearOut then LC.WearOut(p, "lockpick", "The pick's bent out of true: it won't do another lock.") end
    LC.Untie(p, p, true)
    p:ChatPrint("[Miscount] The cuffs click open. Your hands are free.")
    return true
end

function LC.StartPickCuffs(ply)
    local t = LC.Tied and LC.Tied[ply]
    if not t then return false, "Your hands aren't cuffed." end
    if not LC.HasItem(ply, "lockpick") then return false, "You've nothing to pick them with." end
    if IsValid(t.escort) or hook.Run("LivingCityCanStruggle", ply) == false then return false, "Not while they've got hold of you." end
    if not LC.StartTask then return LC.PickCuffsDone(ply) end
    return LC.StartTask(ply, 10, "Working the pick into the cuffs...", {
        maxMove = 30, cancelText = "You palm the pick again.",
        done = function(p) LC.PickCuffsDone(p) end,
    })
end

------------------------------------------------------------------------
-- Players in the Resistance's cage
------------------------------------------------------------------------

local function HoldSecs()
    local cv = GetConVar("lc_rebel_hold")
    return cv and cv:GetFloat() or 300
end

function LC.CagePlayers(cage)
    local out = {}
    for ply, h in pairs(HP) do if h.cage == cage and IsValid(ply) then out[#out + 1] = ply end end
    table.sort(out, function(a, b) return (HP[a].slot or 0) < (HP[b].slot or 0) end)
    return out
end

local function FreeSlot(cage)
    local used = {}
    for _, h in pairs(LC.RebelHeld or {}) do if h.cage == cage and h.slot then used[h.slot] = true end end
    for _, h in pairs(HP) do if h.cage == cage then used[h.slot] = true end end
    for i = 1, 8 do if not used[i] then return i end end
    return 1
end

function LC.CagePutPlayer(ply, cage, by)
    if not IsValid(ply) or not IsValid(cage) or HP[ply] or not (LC.Tied and LC.Tied[ply]) then return false end
    LC.Tied[ply].escort = nil
    local h = { cage = cage, by = by, at = CurTime(), slot = FreeSlot(cage) }
    HP[ply] = h
    ply:SetPos(cage.Slot and cage:Slot(h.slot) or cage:GetPos())
    ply:SetLocalVelocity(Vector(0, 0, 0))
    ply:SetNW2Entity("lc_rebel_cage_in", cage)
    if cage.SetOpen then cage:SetOpen(false) end
    Scene(cage:GetPos(), ply:Nick() .. " is pushed into the cage, and the gate is shut on them.")
    ply:ChatPrint("[Miscount] You're in the Resistance's cage. They don't keep anyone long.")
    local key, okey = IsValid(by) and LC.MindsWhoKey and LC.MindsWhoKey(by), LC.MindsWhoKey and LC.MindsWhoKey(ply)
    if key and okey and LC.ChronicleAdd then
        LC.ChronicleAdd({ k = "caged", s = key, o = okey, pred = "locked " .. ply:Nick() .. " in the Resistance's cage", pos = ply:GetPos(), w = 3 })
    end
    hook.Run("LivingCityRebelCaged", ply, cage, by)
    return true
end

-- Out of the cage. how: "free" (let out and uncuffed), "out" (got out by themselves), nil (only forgotten).
function LC.CageFreePlayer(ply, how)
    local h = HP[ply]
    if not h then return false end
    HP[ply] = nil
    if not IsValid(ply) then return true end
    ply:SetNW2Entity("lc_rebel_cage_in", NULL)
    if how == "free" and ply:Alive() then
        if IsValid(h.cage) and h.cage.Outside then ply:SetPos(h.cage:Outside()) end
        if LC.IsTied(ply) then LC.Untie(ply, nil, true) end
        ply:ChatPrint("[Miscount] The gate opens, the cuffs come off, and you're shoved out. 'Go on. And remember who let you walk.'")
    elseif how == "out" then
        ply:ChatPrint("[Miscount] You're out of the cage. Don't be here when they look.")
    end
    return true
end

function LC.RebelPrisonerTick(now)
    now = now or CurTime()
    if not LC.CageNear then return end
    -- walked up to a cage by a Fighter or above: in they go
    for ply, t in pairs(LC.Tied or {}) do
        local e = t.escort
        if IsValid(ply) and not HP[ply] and IsValid(e) and LC.RebelMayHold and LC.RebelMayHold(e) and not (LC.ArrestHolds and LC.ArrestHolds[ply]) then
            local cage = LC.CageNear(ply:GetPos())
            if IsValid(cage) and cage:GetPos():DistToSqr(ply:GetPos()) < 220 * 220 then
                LC.CagePutPlayer(ply, cage, e)
                e:ChatPrint("You put " .. ply:Nick() .. " in the cage.")
            end
        end
    end
    for ply, h in pairs(HP) do
        local cage = h.cage
        if not IsValid(ply) or not ply:Alive() then LC.CageFreePlayer(ply)
        elseif not IsValid(cage) then LC.CageFreePlayer(ply, "out")
        elseif now - h.at > HoldSecs() then
            Scene(cage:GetPos(), ply:Nick() .. " is let out of the cage.")
            LC.CageFreePlayer(ply, "free")
        else
            local far = ply:GetPos():DistToSqr(cage:GetPos()) > ((cage.lcHalf or 60) + 45) ^ 2
            local tied = LC.IsTied(ply)
            if tied and IsValid(LC.Tied[ply].escort) then LC.CageFreePlayer(ply) -- (taken out by the arm)
            elseif far and cage.IsOpen and cage:IsOpen() then LC.CageFreePlayer(ply, "out")
            elseif far then ply:SetPos(cage.Slot and cage:Slot(h.slot) or cage:GetPos()) end
        end
    end
end
if timer and timer.Create then timer.Create("LivingCityRebelPrisoners", 0.5, 0, function() LC.RebelPrisonerTick(CurTime()) end) end

-- The cage's quick menu, for a player held in it: "free" or "pat". Returns what's said.
function LC.CagePlayerDo(by, cage, what, ply)
    local h = IsValid(ply) and HP[ply]
    if not h or h.cage ~= cage then return nil end
    if what == "free" then
        Scene(cage:GetPos(), ply:Nick() .. " is let out of the cage.")
        LC.CageFreePlayer(ply, "free")
        return "You let them go."
    elseif what == "pat" then
        local ok, why = LC.PatdownStart(by, ply)
        return (not ok) and why or nil
    elseif what == "chair" then
        return LC.ChairPlayerTake and LC.ChairPlayerTake(by, ply, cage) or nil
    elseif what == "execute" or what == "askleave" or what == "execnoleave" then
        return LC.RebelExecDo and LC.RebelExecDo(by, ply, what) or nil
    end
    return nil
end

function LC.PickCageDone(p)
    local h = HP[p]
    if not h or not IsValid(h.cage) or LC.IsTied(p) or not LC.HasItem(p, "lockpick") then return false end
    local seen = LC.CuffsWatched(p)
    if seen then
        LC.TakeItem(p, "lockpick", 1)
        p:ChatPrint("[Miscount] A hand comes through the chain link and takes the pick off you.")
        if seen:IsPlayer() then seen:ChatPrint(Nick(p) .. " was at the cage's padlock with a pick. You take it.") end
        return false
    end
    if Roll() >= PICK_OK then PickFails(p, "padlock") return false end
    if LC.WearOut then LC.WearOut(p, "lockpick", "The pick's bent out of true: it won't do another lock.") end
    if h.cage.SetOpen then h.cage:SetOpen(true) end
    p:ChatPrint("[Miscount] The padlock drops open. The gate swings.")
    return true
end

function LC.StartPickCage(ply)
    local h = HP[ply]
    if not h or not IsValid(h.cage) then return false, "You aren't in the cage." end
    if LC.IsTied(ply) then return false, "Not with your hands cuffed. The cuffs first." end
    if h.cage.IsOpen and h.cage:IsOpen() then return false, "The gate's open." end
    if not LC.HasItem(ply, "lockpick") then return false, "You've nothing to pick it with." end
    if not LC.StartTask then return LC.PickCageDone(ply) end
    return LC.StartTask(ply, 8, "Working at the padlock...", {
        maxMove = 30, cancelText = "You palm the pick again.",
        done = function(p) LC.PickCageDone(p) end,
    })
end

hook.Add("PlayerDeath", "LivingCityRebelPrisoners", function(ply) if HP[ply] then LC.CageFreePlayer(ply) end LC.Patted[ply] = nil end)
hook.Add("PlayerDisconnected", "LivingCityRebelPrisoners", function(ply) HP[ply] = nil LC.Patted[ply] = nil end)
-- locked up by Civil Protection instead (a raid on the camp): theirs now
hook.Add("LivingCityIncarcerated", "LivingCityRebelPrisoners", function(ply) if HP[ply] then LC.CageFreePlayer(ply) end end)

------------------------------------------------------------------------
-- The menus' actions (F1, and the quick menu that comes with the cuffs)
------------------------------------------------------------------------

LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.patdown = function(ply, target)
    if IsValid(target) and not target:IsPlayer() then return LC.PatdownNPCStart(ply, target) end
    return LC.PatdownStart(ply, target)
end
LC.TargetActions.pickcuffs = function(ply) return LC.StartPickCuffs(ply) end
LC.TargetActions.pickcage = function(ply) return LC.StartPickCage(ply) end
