--[[
    Living City: the Resistance's prisoners (the holding cage, lc_rebelcage)

    The owner, 12 November: "They should have a holding cell that is a cage
    (the chain link fences in a tight square) ... it functions as a door that
    can opened/closed by the resistance but is permanently locked to anyone in
    custody. it should more or less mirror the CP prison/jail system", and "I
    want Resistance fighters and above to be able to interrogate citizens,
    sympathizers, loyalists, and even CP units".

    This part: a Resistance Fighter or above taking citizens (sympathizers,
    loyalists and informants are citizens too) prisoner.

      - With a cage with room (four at most) within 1500 units, the talk
        window (E on a citizen) has "Take them prisoner (to the holding
        cage)". They walk to it and are locked in.
      - E on the cage, as a Fighter or above: open or shut the gate, send one
        of those held to the interrogation chair (sv_livingcity_chair.lua),
        or let one go. From the chair they can be sent back to the cage.
      - Nobody is held for ever: after lc_rebel_hold seconds (1200) they are
        let out.
      - Being locked up is in the chronicle and in their minds, and their
        friends know who took them.

    Still to come (docs/features/chronicle.md): Civil Protection units and
    players as prisoners (cuffs and an escort), and the Resistance's own
    people taking suspects by themselves.

    lc_rebel_cage 1/0.
]]

LC = LC or {}

local cvOn = CreateConVar("lc_rebel_cage", "1", FCVAR_ARCHIVE, "The Resistance's holding cage: a Fighter or above can take citizens prisoner and hold them in it")
local cvSecs = CreateConVar("lc_rebel_hold", "1200", FCVAR_ARCHIVE, "How long the Resistance hold a prisoner in the cage before letting them out, in seconds")

local REACH = 1500
local ROOM = 4
local ARRIVE = 150
local WALK_SECS = 120
local MIN_RANK = 3 -- Fighter

LC.RebelHeld = LC.RebelHeld or {} -- npc -> { cage, st, by, at, walking, slot }
local H = LC.RebelHeld

if util.AddNetworkString then
    util.AddNetworkString("lc_cage")
    util.AddNetworkString("lc_cage_do")
end

local function On() return cvOn:GetBool() end
local function NameOf(npc) return (LC.NPCStr and LC.NPCStr(npc, "lc_pname", "") ~= "" and LC.NPCStr(npc, "lc_pname", "")) or (npc.lcProfile and npc.lcProfile.name) or "the citizen" end
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < 600 * 600 then ply:ChatPrint("** " .. text) end
    end
end

-- A Resistance Fighter or above: who may take prisoners and use the chair.
function LC.RebelMayHold(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "resistance" and ply:GetNW2Int("lcf_rank", 1) >= MIN_RANK
end

function LC.CageCount(cage)
    local n = 0
    for _, h in pairs(H) do if h.cage == cage then n = n + 1 end end
    return n
end

function LC.CageNear(pos)
    local best, bd
    for _, c in ipairs(ents.FindByClass("lc_rebelcage")) do
        if IsValid(c) and LC.CageCount(c) < ROOM then
            local d = c:GetPos():DistToSqr(pos)
            if d < REACH * REACH and (not bd or d < bd) then best, bd = c, d end
        end
    end
    return best
end

function LC.CageFor(ply, npc)
    if not On() or not LC.RebelMayHold(ply) or not IsValid(npc) or H[npc] then return nil end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" then return nil end
    if LC.ChairHas and LC.ChairHas(npc) then return nil end
    return LC.CageNear(npc:GetPos())
end

local function FreeSlot(cage)
    local used = {}
    for _, h in pairs(H) do if h.cage == cage and h.slot then used[h.slot] = true end end
    for i = 1, ROOM do if not used[i] then return i end end
    return 1
end

local function Put(npc, h)
    local st, cage = h.st, h.cage
    h.walking, h.slot = nil, FreeSlot(cage)
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    npc:SetPos(cage.Slot and cage:Slot(h.slot) or cage:GetPos())
    LC.SetState(npc, st, "detained")
    st.untilT = CurTime() + 60
    if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
    if h.told then return end -- (back from the chair: already told)
    h.told = true
    Scene(cage:GetPos(), NameOf(npc) .. " is pushed into the cage, and the gate is shut on them.")
    if cage.SetOpen then cage:SetOpen(false) end
    local key = IsValid(h.by) and LC.MindsWhoKey and LC.MindsWhoKey(h.by) or nil
    local p = npc.lcProfile
    if p and p.id and key then
        if LC.ChronicleAdd then LC.ChronicleAdd({ k = "caged", s = key, o = p.id, pred = "locked " .. NameOf(npc) .. " in the Resistance's cage", pos = npc:GetPos(), w = 3 }) end
        local Psy, m = LC.Psy, LC.MindOf and LC.MindOf(p)
        if Psy and m and LC.MindsOn and LC.MindsOn() then
            Psy.Think(m, "arrested", CurTime(), key)
            Psy.Bond(m, key, -4)
            for _, q in pairs(LC.Minds.byId) do
                if q ~= m and q.psy and Psy.Tie(q, m.id) >= 3 then Psy.Think(q, "friend_taken", CurTime(), m.id) Psy.Bond(q, key, -2) end
            end
        end
    end
end

-- "Take them prisoner" in the talk window, or back from the chair (cage given, told: no second telling).
function LC.CageTake(ply, npc, cage, back)
    cage = cage or LC.CageFor(ply, npc)
    if not IsValid(cage) then return "There's no cage with room near enough for that.", false end
    local st = LC.NPCs[npc]
    if not st then return nil end
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    local old = back and back.at or nil
    H[npc] = { cage = cage, st = st, by = ply, at = old or CurTime(), walking = CurTime(), told = back and true or nil }
    st.questLock = true
    if not back and LC.Remember then LC.Remember(npc, ply, -3) end
    if LC.GoTo then LC.GoTo(npc, st, cage.Outside and cage:Outside() or cage:GetPos(), true) end
    return "You take them by the collar. 'You're coming with us.'", true
end

-- Out of the cage: let go (free), or only taken off the cage's list (for the chair).
function LC.CageFree(npc, toChair)
    local h = H[npc]
    if not h then return nil end
    H[npc] = nil
    local st = h.st
    if IsValid(npc) and LC.NPCs[npc] == st then
        if IsValid(h.cage) and not h.walking and h.cage.Outside then npc:SetPos(h.cage:Outside()) end
        if st.state == "detained" or st.state == "moving" then
            LC.SetState(npc, st, "idle")
            st.untilT = CurTime() + 2
        end
        if not toChair then st.questLock = nil end
    end
    return h
end
function LC.CageGone(cage)
    for npc, h in pairs(H) do if h.cage == cage then LC.CageFree(npc) end end
end

function LC.CageTick(now)
    now = now or CurTime()
    for npc, h in pairs(H) do
        local st, cage = h.st, h.cage
        if not IsValid(npc) or npc:Health() <= 0 or LC.NPCs[npc] ~= st then H[npc] = nil
        elseif not IsValid(cage) or st.state == "hostile" or st.state == "jailed" or st.state == "escorted" then LC.CageFree(npc)
        elseif h.walking then
            if npc:GetPos():DistToSqr(cage:GetPos()) < ARRIVE * ARRIVE then Put(npc, h)
            elseif now - h.walking > WALK_SECS then LC.CageFree(npc)
            elseif st.state ~= "moving" and now >= (h.next or 0) then
                h.next = now + 3
                if LC.GoTo then LC.GoTo(npc, st, cage.Outside and cage:Outside() or cage:GetPos(), true) end
            end
        elseif now - h.at > cvSecs:GetFloat() then
            Scene(cage:GetPos(), NameOf(npc) .. " is let out of the cage, and doesn't look back.")
            LC.CageFree(npc)
        else
            st.untilT = now + 60 -- (held)
            if st.state ~= "detained" then LC.SetState(npc, st, "detained") end
        end
    end
end

timer.Create("LivingCityRebelHold", 1, 0, function()
    if LC.TimeStopped or not next(H) then return end
    local ok, err = pcall(LC.CageTick, CurTime())
    if not ok and LC.Error then LC.Error("rebel hold", err) end
end)

-- Those held in a cage (not those still on their way), in the order they were put in.
function LC.CageList(cage)
    local out = {}
    for npc, h in pairs(H) do if h.cage == cage and not h.walking and IsValid(npc) then out[#out + 1] = npc end end
    table.sort(out, function(a, b) return (H[a].slot or 0) < (H[b].slot or 0) end)
    return out
end

local function SendMenu(ply, cage)
    local list = LC.CageList(cage)
    net.Start("lc_cage")
    net.WriteEntity(cage)
    net.WriteBool(cage.IsOpen and cage:IsOpen() or false)
    net.WriteBool(LC.ChairNear ~= nil and LC.ChairNear(cage:GetPos()) ~= nil)
    net.WriteUInt(#list, 4)
    for _, npc in ipairs(list) do net.WriteEntity(npc) net.WriteString(NameOf(npc)) end
    net.Send(ply)
end

-- E on any side of a cage.
function LC.CageUse(ply, cage)
    if not On() or not IsValid(ply) or not IsValid(cage) then return end
    if not LC.RebelMayHold(ply) then
        ply:ChatPrint(ply:GetNW2String("lcf_faction", "") == "resistance" and "[Miscount] The cage is for Fighters and above to open." or "[Miscount] Chain link, and a padlock. It doesn't give.")
        return
    end
    SendMenu(ply, cage)
end

-- "gate", "free" or "chair" (with the one meant). Returns what's said.
function LC.CageDo(ply, cage, what, npc)
    if not On() or not IsValid(cage) or not LC.RebelMayHold(ply) then return nil end
    if what == "gate" then
        local open = not (cage.IsOpen and cage:IsOpen())
        if cage.SetOpen then cage:SetOpen(open) end
        return open and "You swing the gate open." or "You shut the gate."
    end
    local h = IsValid(npc) and H[npc]
    if not h or h.cage ~= cage or h.walking then return nil end
    if what == "free" then
        Scene(cage:GetPos(), NameOf(npc) .. " is let out of the cage.")
        LC.CageFree(npc)
        return "You let them go."
    end
    if what == "chair" then
        local chair = LC.ChairNear and LC.ChairNear(cage:GetPos())
        if not chair or not LC.ChairTake then return "There's no free chair near enough." end
        LC.CageFree(npc, true)
        local said = LC.ChairTake(ply, npc, { cage = cage, at = h.at })
        return said
    end
    return nil
end

net.Receive("lc_cage_do", function(_, ply)
    local cage, what, npc = net.ReadEntity(), net.ReadString(), net.ReadEntity()
    if (ply.lcCageNext or 0) > CurTime() then return end
    ply.lcCageNext = CurTime() + 0.5
    if not IsValid(cage) or ply:GetPos():DistToSqr(cage:GetPos()) > 350 * 350 then return end
    local said = LC.CageDo(ply, cage, what, npc)
    if said then ply:ChatPrint(said) end
    if IsValid(cage) then SendMenu(ply, cage) end
end)

hook.Add("PlayerUse", "LivingCityRebelCage", function(ply, ent)
    local cage = IsValid(ent) and ent.lcCage
    if not IsValid(cage) then return end
    if (ply.lcCageUseNext or 0) <= CurTime() then
        ply.lcCageUseNext = CurTime() + 1
        LC.CageUse(ply, cage)
    end
    return false
end)
