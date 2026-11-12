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
      - Nobody is kept: after lc_rebel_hold seconds (300) they are let out
        (one not yet questioned, up to twice that). Eight to a cage at most
        (lc_rebel_cage_room); whenever one leaves, the rest are stood in
        their own places again.
      - With a chair near, the cell's own people question everyone held, one
        at a time, by themselves (lc_rebel_auto); what a prisoner admits
        goes on the Resistance's notice board.
      - Someone comes to the cage and talks at those held, every 30 to 60
        seconds (lc_rebel_visitor): Father Grigori if he is alive and free,
        else a settled vortigaunt, else one of the Resistance's own.
      - Being locked up is in the chronicle and in their minds, and their
        friends know who took them.

    Still to come (docs/features/chronicle.md): Civil Protection units and
    players as prisoners (cuffs and an escort), and the Resistance's own
    people taking suspects by themselves.

    lc_rebel_cage 1/0.
]]

LC = LC or {}

local cvOn = CreateConVar("lc_rebel_cage", "1", FCVAR_ARCHIVE, "The Resistance's holding cage: a Fighter or above can take citizens prisoner and hold them in it")
local cvSecs = CreateConVar("lc_rebel_hold", "300", FCVAR_ARCHIVE, "How long the Resistance hold a prisoner in the cage before letting them out, in seconds (one not yet questioned is kept up to twice as long)")
local cvRoom = CreateConVar("lc_rebel_cage_room", "8", FCVAR_ARCHIVE, "How many prisoners fit in one of the Resistance's cages (4 to 8; past six they stand in each other a little)")
local cvAuto = CreateConVar("lc_rebel_auto", "1", FCVAR_ARCHIVE, "The Resistance's own people question everyone in the cage by themselves, one at a time, when a chair is near")
local cvVisit = CreateConVar("lc_rebel_visitor", "1", FCVAR_ARCHIVE, "Father Grigori (or a vortigaunt, or a rebel) comes to the cage and talks at the prisoners, every 30 to 60 seconds")

local REACH = 1500
local function Room() return math.Clamp(math.floor(cvRoom:GetFloat()), 4, 8) end
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
    for _, h in pairs(LC.RebelHeldPly or {}) do if h.cage == cage then n = n + 1 end end -- (players: sv_livingcity_patdown.lua)
    return n
end

function LC.CageNear(pos)
    local best, bd
    for _, c in ipairs(ents.FindByClass("lc_rebelcage")) do
        if IsValid(c) and LC.CageCount(c) < Room() then
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
    for _, h in pairs(LC.RebelHeldPly or {}) do if h.cage == cage and h.slot then used[h.slot] = true end end
    for i = 1, 8 do if not used[i] then return i end end
    return 1
end

-- Everyone still held in a cage is stood in their own place again (the owner, 12 November: crammed in, "they can
-- clip into each other a bit, so long as when prisoners are released or taken for interrogation, it ... places
-- everyone again"). Returns how many times this cage has been set straight.
local function Reseat(cage)
    if not IsValid(cage) then return end
    for npc, h in pairs(H) do
        if h.cage == cage and not h.walking and h.slot and IsValid(npc) then
            npc:SetPos(cage.Slot and cage:Slot(h.slot) or cage:GetPos())
            if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
        end
    end
    cage.lcReseats = (cage.lcReseats or 0) + 1
end
function LC.CageReseats(cage) return IsValid(cage) and cage.lcReseats or 0 end

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
    H[npc] = { cage = cage, st = st, by = ply, at = old or CurTime(), walking = CurTime(), told = back and true or nil, questioned = back and true or nil }
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
    if not h.walking then Reseat(h.cage) end
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
        elseif now - h.at > cvSecs:GetFloat() * ((h.questioned or not cvAuto:GetBool()) and 1 or 2) then
            Scene(cage:GetPos(), NameOf(npc) .. " is let out of the cage, and doesn't look back.")
            LC.CageFree(npc)
        else
            st.untilT = now + 60 -- (held)
            if st.state ~= "detained" then LC.SetState(npc, st, "detained") end
        end
    end
end

-- The cell's own people question whoever hasn't been yet, one at a time, when a chair near the cage is free.
function LC.CageAutoNext(cage, now)
    if not cvAuto:GetBool() or not LC.ChairNear or not LC.ChairTake then return false end
    local pick
    for npc, h in pairs(H) do
        if h.cage == cage and not h.walking and not h.questioned and now - h.at >= 15 and IsValid(npc) then
            if not pick or (h.slot or 0) < (H[pick].slot or 0) then pick = npc end
        end
    end
    if not pick or not LC.ChairNear(cage:GetPos()) then return false end
    local h = H[pick]
    LC.CageFree(pick, true)
    local _, ok = LC.ChairTake(nil, pick, { cage = cage, at = h.at }, true)
    if not ok then LC.CageTake(nil, pick, cage, { cage = cage, at = h.at }) end
    return ok == true
end

------------------------------------------------------------------------
-- Someone at the cage (the owner, 12 November: "I would LOVE for Father Gregori to walk up to the jail and start
-- preaching at the prisoners ... If Father Gregori is dead or busy, a vortigaunt walks up and starts talking to
-- them. If no vortigaunt around, then a rebel walks up and starts taunting them or insulting them sporadically
-- (please don't have it be a barrage of nonstop noise, it can be every 30-60 seconds)")
------------------------------------------------------------------------
local SAY = {
    grigori = {
        "'Repent, my children! The cage is a mercy. The pit is not!'",
        "'I have buried better than you. I have buried worse. The Lord sorts them, not I.'",
        "'You served the shepherds of wolves. Now hear a shepherd of sheep!'",
        "'Confess it! A light conscience weighs nothing on the way down.'",
        "'Do you smell it? That is fear. Fear is where wisdom begins, my child.'",
        "'Be glad it is my voice you hear, and not the things that walk at night.'",
    },
    vort = {
        "'The caged one fears us. It need not. We remember cages.'",
        "'We see the cord that binds this one to the Combine. It is thinner than it believes.'",
        "'Speak truly to them, and the lamp will be brief.'",
        "'We were slaves also. We do not gloat. We observe.'",
        "'This one's heart is loud. We hear it from here.'",
    },
    rebel = {
        "'Comfortable in there? Your friends in the masks aren't coming.'",
        "'Should've kept your mouth shut. Too late for that now.'",
        "'Look at me when I'm talking to you. That's better.'",
        "'You'll get your turn under the lamp. Everybody does.'",
        "'How many rations did they give you for it? Was it worth it?'",
    },
}
local WHO = { grigori = "Father Grigori", vort = "A vortigaunt", rebel = "A rebel" }

local function GoNear(ent, pos)
    local st = LC.NPCs and LC.NPCs[ent]
    if st and not st.unmanaged and LC.GoTo and st.role ~= "rebel" then LC.GoTo(ent, st, pos, false) return end
    if ent.SetLastPosition and SCHED_FORCED_GO then
        ent:SetLastPosition(pos)
        ent:SetSchedule(SCHED_FORCED_GO)
    end
end

-- Who comes to this cage: Father Grigori (he's simply there: he knows these camps), else a settled vortigaunt
-- within 4000 units, else one of the Resistance's own within 3000. Returns the kind and who.
local function Visitor(cage)
    local pos = cage:GetPos()
    local g = LC.Grigori
    if IsValid(g) and g:Health() > 0 then
        local busy = false -- (someone is talking to him somewhere else)
        if g:GetPos():DistToSqr(pos) > 500 * 500 then
            for _, p in ipairs(player.GetAll()) do if p:GetPos():DistToSqr(g:GetPos()) < 250 * 250 then busy = true end end
        end
        if not busy then return "grigori", g end
    end
    local best, bd
    for v in pairs(LC.RebelVorts or {}) do
        if IsValid(v) and v:Health() > 0 then
            local d = v:GetPos():DistToSqr(pos)
            if d < 4000 * 4000 and (not bd or d < bd) then best, bd = v, d end
        end
    end
    if best then return "vort", best end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and st.state ~= "hostile" then
            local d = npc:GetPos():DistToSqr(pos)
            if d < 3000 * 3000 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    if best then return "rebel", best end
    return nil
end

-- Called every second for a cage with someone in it. Returns the kind of visitor there is ("grigori", "vort",
-- "rebel" or nil), and the line just said, if one was.
function LC.CageVisit(cage, now)
    if not cvVisit:GetBool() then return nil end
    local v = cage.lcVisit
    if not v or not IsValid(v.ent) or v.ent:Health() <= 0 or now >= (v.recheck or 0) then
        local kind, ent = Visitor(cage)
        if not kind then cage.lcVisit = nil return nil end
        if not v or v.ent ~= ent then v = { kind = kind, ent = ent, nextAt = now + 3 } end
        v.recheck = now + 30
        cage.lcVisit = v
    end
    local ent, spot = v.ent, (cage.Outside and cage:Outside() or cage:GetPos()) + Vector(40, 40, 0)
    local far = ent:GetPos():DistToSqr(cage:GetPos()) > 350 * 350
    if v.kind == "grigori" then
        ent.lcPreachUntil = now + 20
        if far then ent:SetPos(spot) far = false end
    elseif far and now >= (v.goAt or 0) then
        v.goAt = now + 15
        GoNear(ent, spot)
    end
    if far or now < v.nextAt then return v.kind end
    v.nextAt = now + math.Rand(30, 60)
    if LC.Face then LC.Face(ent, cage:GetPos()) end
    local line = SAY[v.kind][math.random(#SAY[v.kind])]
    if v.kind == "grigori" and LC.GrigoriSpeak then LC.GrigoriSpeak(ent, 75) end
    Scene(cage:GetPos(), WHO[v.kind] .. ", at the cage: " .. line)
    return v.kind, line
end

timer.Create("LivingCityRebelHold", 1, 0, function()
    if LC.TimeStopped or not next(H) then return end
    local now = CurTime()
    local ok, err = pcall(LC.CageTick, now)
    if not ok and LC.Error then LC.Error("rebel hold", err) end
    local seen = {}
    for _, h in pairs(H) do
        local cage = h.cage
        if IsValid(cage) and not h.walking and not seen[cage] then
            seen[cage] = true
            local ok2, err2 = pcall(function() LC.CageAutoNext(cage, now) LC.CageVisit(cage, now) end)
            if not ok2 and LC.Error then LC.Error("rebel hold (cage)", err2) end
        end
    end
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
    local plys = LC.CagePlayers and LC.CagePlayers(cage) or {}
    net.WriteUInt(math.min(15, #list + #plys), 4)
    for _, npc in ipairs(list) do net.WriteEntity(npc) net.WriteString(NameOf(npc)) end
    for i = 1, math.min(#plys, 15 - #list) do net.WriteEntity(plys[i]) net.WriteString(plys[i]:Nick()) end
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
    if IsValid(npc) and npc:IsPlayer() then return LC.CagePlayerDo and LC.CagePlayerDo(ply, cage, what, npc) or nil end
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
        -- (h is off the list now; they come back from the chair as questioned)
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
