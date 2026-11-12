--[[
    Living City: the Resistance's interrogation chair (lc_interrochair)

    The owner, 12 November: "resistance interrogations force people into a
    chair entity and the resistance members use their fists to beat them",
    "a harsh bright spotlight above the chair ... to borderline blind the
    person", and on the risk: "the resistance can then also be morally gray
    and push good people towards CP and loyalism".

    This first part is a Resistance player questioning a citizen:

      - With a chair within 1200 units, the talk window (E on a citizen) has
        "Take them to the chair". They walk to it, are pushed down into it,
        and the lamp comes on.
      - E on the chair: ask what they've done, ask what they've seen, hit
        them, or let them go. Nobody talks at first. Each blow (fists, 6 at
        most, never under 10 health) wears down their resolve, which comes
        from who they are: the brave, the proud and the tough hold out.
      - When they break, what comes out is from the chronicle
        (sv_livingcity_chronicle.lua): something they really did (informing
        included: this is how the secrets come out) or really saw.
      - The risk: beat someone twice or more who has done nothing, and it's
        for nothing. They and their friends turn on you, a sympathizer stops
        being one, and the grudge is the kind the minds inform over.
      - Every beating in the chair is in the chronicle, and on the street's
        lips if a named person saw it.

    Still to come (docs/features/chronicle.md): the Resistance's own people
    doing this by themselves, players in the chair (with a way to cuff and
    escort), and Civil Protection's side with the baton.

    lc_chair 1/0.
]]

LC = LC or {}

local cvOn = CreateConVar("lc_chair", "1", FCVAR_ARCHIVE, "The Resistance's interrogation chair: a Resistance player can take a citizen to it and question them (what they tell comes from the chronicle)")

local REACH = 1200     -- a free chair this near, and a rebel may take someone to it
local STAY = 320       -- the one asking stays this close, or they're let go
local ARRIVE = 80
local WALK_SECS = 90
local SESSION = 240
local MAX_HITS = 6
local WRONG_HITS = 2   -- this many blows on someone with nothing to tell, and it was for nothing

LC.Chairs = LC.Chairs or {} -- chair -> session
local S = LC.Chairs

if util.AddNetworkString then
    util.AddNetworkString("lc_chair")
    util.AddNetworkString("lc_chair_do")
end

local function On() return cvOn:GetBool() end
local function Pick(t) return t[math.random(#t)] end
local function IsRebel(ply) return IsValid(ply) and ply:IsPlayer() and ply:GetNW2String("lcf_faction", "") == "resistance" end
local function NameOf(npc) return (LC.NPCStr and LC.NPCStr(npc, "lc_pname", "") ~= "" and LC.NPCStr(npc, "lc_pname", "")) or (npc.lcProfile and npc.lcProfile.name) or "the citizen" end
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < 600 * 600 then ply:ChatPrint("** " .. text) end
    end
end

local function SessionOfNPC(npc)
    for _, s in pairs(S) do if s.npc == npc then return s end end
    return nil
end

-- The nearest chair nobody is in, within reach of pos.
function LC.ChairNear(pos)
    local best, bd
    for _, c in ipairs(ents.FindByClass("lc_interrochair")) do
        if IsValid(c) and not S[c] then
            local d = c:GetPos():DistToSqr(pos)
            if d < REACH * REACH and (not bd or d < bd) then best, bd = c, d end
        end
    end
    return best
end

-- The chair this rebel could take this citizen to (nil: not a rebel, no chair near, or they're already bound for one).
function LC.ChairFor(ply, npc)
    if not On() or not IsRebel(ply) or not IsValid(npc) then return nil end
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" or SessionOfNPC(npc) then return nil end
    return LC.ChairNear(npc:GetPos())
end

-- How many blows before they talk: 1 to 5, from who they are.
local function Resolve(npc)
    local p, Psy = npc.lcProfile, LC.Psy
    if not (p and Psy and Psy.Traits) then return 2 end
    local t = Psy.Traits(p)
    return math.Clamp(math.floor(2.5 + 1.5 * (t.brave or 0) + (t.pride or 0) + (t.resilience or 0)), 1, 5)
end

local function Release(s, why)
    local npc, st, chair = s.npc, s.st, s.chair
    if IsValid(chair) then
        S[chair] = nil
        if chair.SetLamp then chair:SetLamp(false) end
        chair:SetNW2Entity("lc_chair_sitter", NULL)
    else
        for c, v in pairs(S) do if v == s then S[c] = nil end end
    end
    if st then
        if IsValid(st.ss) and s.seated then
            st.ss:Fire("CancelSequence")
            SafeRemoveEntityDelayed(st.ss, 0.5)
            st.ss, st.busyKind = nil, nil
        end
        st.questLock = nil
        if IsValid(npc) and LC.NPCs[npc] == st and (st.state == "detained" or st.state == "moving") then
            LC.SetState(npc, st, "idle")
            st.untilT = CurTime() + 2
        end
    end
    if IsValid(s.asker) then
        net.Start("lc_chair") net.WriteEntity(NULL) net.Send(s.asker)
        if why then s.asker:ChatPrint("[Miscount] " .. why) end
    end
end
function LC.ChairGone(chair) local s = S[chair] if s then Release(s) end S[chair] = nil end

local function Seat(s)
    local npc, st, chair = s.npc, s.st, s.chair
    s.seated, s.seatedAt, s.farSince = true, CurTime(), nil
    s.resolve = Resolve(npc)
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    local pos, yaw = chair:GetPos(), chair:GetAngles().y
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, yaw, 0))
    LC.SetState(npc, st, "detained")
    st.untilT = CurTime() + SESSION + 30
    -- sat down, as on any chair in the city (sv_livingcity.lua)
    if LC.MakeSequence and LC.BusySeqName and SF_SCRIPT_LOOP_IN_POST_IDLE then
        local loop = LC.BusySeqName(npc, "ACT_BUSY_SIT_CHAIR")
        if loop then
            local ok, ss = pcall(LC.MakeSequence, npc, pos, yaw, LC.BusySeqName(npc, "ACT_BUSY_SIT_CHAIR_ENTRY") or loop, loop,
                SF_SCRIPT_LOOP_IN_POST_IDLE + SF_SCRIPT_NO_COMPLAINTS + SF_SCRIPT_ALLOW_DEATH, 1, 0)
            if ok and IsValid(ss) then st.ss, st.busyKind = ss, "sitchair" end
        end
    end
    if chair.SetLamp then chair:SetLamp(true) end
    chair:SetNW2Entity("lc_chair_sitter", npc)
    Scene(pos, NameOf(npc) .. " is pushed down into the chair. The lamp comes on.")
end

-- "Take them to the chair" in the talk window (sv_livingcity_talk.lua). Returns what's said, and whether the window closes.
function LC.ChairTake(ply, npc)
    local chair = LC.ChairFor(ply, npc)
    if not chair then return "There's no chair near enough for that.", false end
    local st = LC.NPCs[npc]
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    local s = { chair = chair, npc = npc, st = st, asker = ply, at = CurTime(), hits = 0, told = {} }
    S[chair] = s
    st.questLock = true
    if LC.Remember then LC.Remember(npc, ply, -2) end
    if LC.GoTo then LC.GoTo(npc, st, chair:GetPos(), true) end
    return "You take them by the arm. 'Walk. We need to talk.'", true
end

local REFUSE = {
    "They stare at the floor and say nothing.", "'I haven't done anything. I haven't!'", "'I don't know what you want from me.'",
    "They squint up into the lamp, and shake their head.", "'Please. I just want to go home.'",
}
local BLOW = {
    "You hit them. Their head snaps to the side.", "Your fist lands. They gasp, and the chair creaks.",
    "You hit them again. Blood on your knuckles, not yours.", "A blow to the stomach. They fold as far as the chair allows.",
}
local NOTHING = { "'I don't know anything. I swear it.' You believe them.", "'There's nothing. There was never anything.' It sounds true." }

local function Wronged(s, ply)
    s.wronged = true
    local npc, st = s.npc, s.st
    local p = npc.lcProfile
    local Psy, key = LC.Psy, LC.MindsWhoKey and LC.MindsWhoKey(ply)
    local m = p and LC.MindOf and LC.MindOf(p)
    if m and Psy and key and LC.MindsOn and LC.MindsOn() then
        Psy.Bond(m, key, -8)
        for _, q in pairs(LC.Minds.byId) do
            if q ~= m and q.psy and Psy.Tie(q, m.id) >= 3 then
                Psy.Think(q, "friend_beaten", CurTime(), key)
                Psy.Bond(q, key, -4)
            end
        end
    end
    -- whatever they thought of the Resistance, it's gone
    if p then p.rebel = false end
    st.rebel = false
    if LC.Remember then LC.Remember(npc, ply, -6) end
    if LC.ChronicleAdd and key and p and p.id then
        LC.ChronicleAdd({ k = "chair_wrong", s = key, o = p.id, pred = "beat " .. NameOf(npc) .. " in the chair for nothing", pos = npc:GetPos(), w = 4 })
    end
end

-- What the one asking does: "done", "seen", "hit" or "free". Returns what happens, in words.
function LC.ChairDo(ply, chair, what)
    local s = IsValid(chair) and S[chair]
    if not s or not s.seated or s.asker ~= ply or not IsValid(s.npc) then return nil end
    local npc = s.npc
    local id = npc.lcProfile and npc.lcProfile.id
    if what == "free" then
        Scene(chair:GetPos(), NameOf(npc) .. " is let out of the chair.")
        Release(s)
        return "You let them go."
    end
    if what == "hit" then
        if s.hits >= MAX_HITS then return "Any more and you'd kill them." end
        s.hits = s.hits + 1
        s.resolve = (s.resolve or 2) - 1
        npc:SetHealth(math.max(10, npc:Health() - 6))
        npc:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75)
        if ply.DoAnimationEvent and ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST then ply:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST) end
        if ply.ViewPunch then ply:ViewPunch(Angle(2, math.random(-2, 2), 0)) end
        if LC.MindsHurt then LC.MindsHurt(npc, ply, 6) end
        if LC.Remember then LC.Remember(npc, ply, -3) end
        local key = LC.MindsWhoKey and LC.MindsWhoKey(ply)
        if s.hits == 1 and LC.ChronicleAdd and key and id then
            LC.ChronicleAdd({ k = "chair", s = key, o = id, pred = "beat " .. NameOf(npc) .. " in the chair", pos = npc:GetPos(), w = 3 })
        end
        return Pick(BLOW) .. ((s.resolve or 0) <= 0 and " Something in them gives." or "")
    end
    if what ~= "done" and what ~= "seen" then return nil end
    if (s.resolve or 0) > 0 then return Pick(REFUSE) end
    local e = id and LC.ChronicleKnows and LC.ChronicleKnows(id, what, s.told)
    if e then
        s.told[e.n] = true
        return (what == "done" and "It comes out of them: " or "They saw something: ") .. e.sn .. " " .. e.pred .. "."
    end
    if what == "done" and s.hits >= WRONG_HITS and not s.wronged and next(s.told) == nil then
        Wronged(s, ply)
        return Pick(NOTHING) .. " Whatever they thought of the Resistance, it's gone now."
    end
    return Pick(NOTHING)
end

local function SendMenu(ply, s, said)
    net.Start("lc_chair")
    net.WriteEntity(s.chair)
    net.WriteString(NameOf(s.npc))
    net.WriteString(said or "")
    net.WriteUInt(s.hits, 4)
    net.WriteUInt(MAX_HITS, 4)
    net.Send(ply)
end

-- E on the chair.
function LC.ChairUse(ply, chair)
    if not On() or not IsValid(ply) or not IsValid(chair) then return end
    local s = S[chair]
    if not IsRebel(ply) then
        ply:ChatPrint(s and s.seated and "[Miscount] This is none of your business. Walk on." or "[Miscount] A chair, under a lamp. Not yours.")
        return
    end
    if not s then
        ply:ChatPrint("[Miscount] The chair is empty. To question someone: press E on a citizen nearby, then \"Take them to the chair\".")
        return
    end
    if not s.seated then ply:ChatPrint("[Miscount] They're on their way to the chair.") return end
    if s.asker ~= ply and (not IsValid(s.asker) or s.asker:GetPos():DistToSqr(chair:GetPos()) > STAY * STAY) then s.asker = ply end
    if s.asker ~= ply then ply:ChatPrint("[Miscount] Someone else is asking the questions.") return end
    SendMenu(ply, s, "They squint up at you through the light.")
end

net.Receive("lc_chair_do", function(_, ply)
    local chair, what = net.ReadEntity(), net.ReadString()
    if (ply.lcChairNext or 0) > CurTime() then return end
    ply.lcChairNext = CurTime() + 0.6
    if not IsValid(chair) or ply:GetPos():DistToSqr(chair:GetPos()) > STAY * STAY then return end
    local s = S[chair]
    local said = LC.ChairDo(ply, chair, what)
    if said and S[chair] == s and s then SendMenu(ply, s, said) elseif said then ply:ChatPrint(said) end
end)

function LC.ChairTick(now)
    now = now or CurTime()
    for chair, s in pairs(S) do
        local npc, st = s.npc, s.st
        if not IsValid(chair) or not IsValid(npc) or npc:Health() <= 0 or LC.NPCs[npc] ~= st or st.state == "hostile" or st.state == "jailed" or st.state == "escorted" then
            Release(s)
        elseif not s.seated then
            if npc:GetPos():DistToSqr(chair:GetPos()) < ARRIVE * ARRIVE then Seat(s)
            elseif now - s.at > WALK_SECS then Release(s, "They slipped away before you got them to the chair.")
            elseif st.state ~= "moving" and now >= (s.next or 0) then
                s.next = now + 3
                if LC.GoTo then LC.GoTo(npc, st, chair:GetPos(), true) end
            end
        else
            local near = IsValid(s.asker) and s.asker:GetPos():DistToSqr(chair:GetPos()) < STAY * STAY
            if near then s.farSince = nil else s.farSince = s.farSince or now end
            if now - s.seatedAt > SESSION or (s.farSince and now - s.farSince > 20) then
                Scene(chair:GetPos(), NameOf(npc) .. " gets up out of the chair, unsteadily.")
                Release(s)
            end
        end
    end
end

timer.Create("LivingCityChair", 1, 0, function()
    if LC.TimeStopped or not next(S) then return end
    local ok, err = pcall(LC.ChairTick, CurTime())
    if not ok and LC.Error then LC.Error("chair", err) end
end)
