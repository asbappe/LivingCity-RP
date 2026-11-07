--[[
    Living City: talking to people

    Press E on one of the city's citizens (when no job of yours needs that
    press for something else) and a little window opens: who they are, what
    they're doing, how they feel about you, and what you can do:

      Chat              whatever they've heard (the city's rumours), or small talk
      Share some food   one of your rations, bread, a can: they remember it
      Pick their pocket a Guile check. Credits, now and then something better.
                        Fail and they shout, back away, and a unit who saw it
                        makes you wanted for theft
      Inform on them    tell Civil Protection they're a sympathizer. If they
                        are, they're taken in and you're paid in standing; if
                        they aren't, you've wasted a unit's time
      Ask them to keep watch   (the Resistance, a sympathizer): a lookout
                        (sv_livingcity_lookouts.lua)

    They remember you. Every citizen keeps how each of your characters has
    treated them, saved with the city's roster: hurt them, rob them, report
    them and they're afraid of you (they won't talk, and they back away when
    you come near); help them (food, a medic's care) and they're warm (they
    greet you, and tell you what they know). Units are units: Civil
    Protection players still stop citizens with E.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_talk")
util.AddNetworkString("lc_talk_do")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvTalk = CreateConVar("lc_talk", "1", FLAGS, "E on a citizen opens a talk window (chat, share food, pickpocket, inform)")
local cvPickDC = CreateConVar("lc_pickpocket_dc", "12", FLAGS, "Guile check to pick a citizen's pocket (d20 + Guile)")

local function Pick(t) return t[math.random(#t)] end
local function Vo(gender, name) return "vo/npc/" .. (gender or "male") .. "01/" .. name .. ".wav" end

------------------------------------------------------------------------
-- Memory: how each of your characters has treated them
------------------------------------------------------------------------

local WARM, AFRAID = 3, -3

-- Who you are to them: this character of yours, not just your account.
function LC.MemoryKey(ply)
    return ply:SteamID() .. "|" .. ply:GetNW2String("lc_char", "")
end

function LC.Feeling(npc, ply)
    local p = IsValid(npc) and npc.lcProfile
    local m = p and p.memory
    return m and m[LC.MemoryKey(ply)] or 0
end

function LC.Remember(npc, ply, d)
    local p = IsValid(npc) and npc.lcProfile
    if not p or not IsValid(ply) or not ply:IsPlayer() or d == 0 then return 0 end
    p.memory = p.memory or {}
    local k = LC.MemoryKey(ply)
    local v = math.Clamp((p.memory[k] or 0) + d, -10, 10)
    p.memory[k] = v ~= 0 and v or nil
    -- not forever, and not everyone: the strongest twenty
    local n = 0
    for _ in pairs(p.memory) do n = n + 1 end
    if n > 20 then
        local weakest, wv
        for key, val in pairs(p.memory) do
            if not wv or math.abs(val) < wv then weakest, wv = key, math.abs(val) end
        end
        if weakest then p.memory[weakest] = nil end
    end
    if LC.MarkPeopleDirty then LC.MarkPeopleDirty() end
    return v
end

function LC.MoodWord(v)
    if v >= 6 then return "glad to see you", "warm"
    elseif v >= WARM then return "friendly", "warm"
    elseif v <= -6 then return "terrified of you", "afraid"
    elseif v <= AFRAID then return "wary of you", "afraid" end
    return "a stranger", "neutral"
end

-- What a person does to them, they remember.
hook.Add("EntityTakeDamage", "LivingCityMemory", function(ent, dmg)
    local st = LC.NPCs and LC.NPCs[ent]
    if not st or st.role ~= "citizen" then return end
    local a = dmg:GetAttacker()
    if IsValid(a) and a:IsPlayer() and dmg:GetDamage() > 0 and (ent.lcHurtBy ~= a or (ent.lcHurtAt or 0) < CurTime() - 5) then
        ent.lcHurtBy, ent.lcHurtAt = a, CurTime()
        LC.Remember(ent, a, -4)
    end
end)
hook.Add("LivingCityHealed", "LivingCityMemory", function(healer, target)
    local st = LC.NPCs and IsValid(target) and LC.NPCs[target]
    if st and st.role == "citizen" and IsValid(healer) and healer:IsPlayer() then LC.Remember(target, healer, 2) end
end)

------------------------------------------------------------------------
-- The window
------------------------------------------------------------------------

-- Anything you'd eat yourself (not raw meat): the plainest first.
local FOOD
local function FoodToGive(ply)
    if not FOOD then
        FOOD = {}
        for id, it in pairs(LCS and LCS.Items or {}) do
            if (it.hunger or 0) > 0 and not it.parasite and not it.poison then FOOD[#FOOD + 1] = id end
        end
        table.sort(FOOD, function(a, b) return (LCS.Items[a].hunger or 0) > (LCS.Items[b].hunger or 0) end)
    end
    for _, id in ipairs(FOOD) do if LC.HasItem and LC.HasItem(ply, id) then return id end end
    return nil
end

-- A sympathizer who likes you: where the Resistance gathers.
function LC.SafeHouseHint(ply)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("rebel") or {}) do
        local d = z.pos:DistToSqr(ply:GetPos())
        if not bd or d < bd then best, bd = z, d end
    end
    if not best then return nil end
    local where = LC.DescribePlace and LC.DescribePlace(best.pos) or "out past the checkpoints"
    return "If you're looking for people who think like you, they're " .. where .. ". Ask for the quartermaster."
end

local SMALL_TALK = {
    "'Another day. Keep your head down and it's another day.'", "'The water tastes of something again.'",
    "'They moved the line again this morning. Nobody knows why.'", "'I don't sleep much. Nobody does.'",
    "'Have you seen my neighbour? Since Tuesday, nobody has.'", "'The trains are always full coming in. Never going out.'",
    "'Don't stand under the scanners. They don't like it.'", "'They say the rations will be bigger next month. They always say that.'",
}
local AFRAID_LINES = { "They won't look at you.", "They step back, hands up: 'I don't want any trouble.'", "'Please. Just leave me alone.'" }

local function Usable(ply, npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.role ~= "citizen" or st.test then return nil end
    if not IsValid(ply) or not ply:Alive() or ply:GetPos():DistToSqr(npc:GetPos()) > 160 * 160 then return nil end
    if st.state == "detained" or st.state == "jailed" or st.state == "escorted" or st.state == "event" then return nil end
    return st
end

local function Doing(npc)
    local d = npc:GetNW2String("lc_doing", "")
    if d ~= "" then return d end
    local st = LC.NPCs[npc]
    if st and st.state == "inline" then return "waiting in the ration line" end
    if st and st.state == "busy" then return "resting" end
    return ""
end

local function Options(ply, npc, st)
    local unit = LC.PlayerIsCP(ply)
    local rebel = ply:GetNW2String("lcf_faction", "") == "resistance"
    return {
        chat = true,
        food = FoodToGive(ply) ~= nil,
        pick = not unit and (npc.lcPickedAt or 0) < CurTime() - 600,
        inform = not unit and not rebel,
        recruit = rebel and st.rebel == true and LC.CanRecruitLookout ~= nil and (LC.CanRecruitLookout(ply, npc)),
    }
end

-- Someone stopped for you right where you stand: they take a step back, so neither of you
-- is stuck inside the other (it happened after a pickpocketing)
local function StepAway(npc, ply)
    if not (IsValid(npc) and IsValid(ply)) then return end
    local d = npc:GetPos() - ply:GetPos()
    d.z = 0
    if d:Length() > 36 then return end
    if d:Length() < 1 then d = ply:GetForward() d.z = 0 end
    d:Normalize()
    local from = npc:GetPos() + Vector(0, 0, 4)
    local tr = util.TraceHull({ start = from, endpos = from + d * 44, mins = npc:OBBMins(), maxs = npc:OBBMaxs(), filter = { npc, ply }, mask = MASK_NPCSOLID })
    if tr and not tr.StartSolid then npc:SetPos(tr.HitPos - Vector(0, 0, 4)) end
end
LC.TalkStepAway = StepAway

function LC.OpenTalk(ply, npc, said)
    local st = Usable(ply, npc)
    if not st then return false end
    local feel = LC.Feeling(npc, ply)
    local mood, kind = LC.MoodWord(feel)
    if kind == "afraid" and not said then said = Pick(AFRAID_LINES) end
    net.Start("lc_talk")
    net.WriteEntity(npc)
    net.WriteString(npc:GetNW2String("lc_pname", "A citizen"))
    net.WriteString(npc:GetNW2String("lc_pjob", ""))
    net.WriteString(Doing(npc))
    net.WriteString(mood)
    net.WriteString(kind)
    net.WriteString(said or "")
    local o = Options(ply, npc, st)
    net.WriteBool(o.chat and kind ~= "afraid")
    net.WriteBool(o.food)
    net.WriteBool(o.pick)
    net.WriteBool(o.inform)
    net.WriteBool(o.recruit == true)
    net.Send(ply)
    -- they stop for you
    StepAway(npc, ply)
    LC.Face(npc, ply:GetPos())
    if st.state == "moving" then npc:SetSchedule(SCHED_IDLE_STAND) LC.SetState(npc, st, "idle") end
    if st.state == "idle" then st.untilT = math.max(st.untilT or 0, CurTime() + 8) end
    return true
end

------------------------------------------------------------------------
-- What you can do
------------------------------------------------------------------------

local function Chat(ply, npc, st)
    local feel = LC.Feeling(npc, ply)
    if feel <= AFRAID then return Pick(AFRAID_LINES) end
    npc:EmitSound(Vo(st.gender, string.format("question%02d", math.random(1, 20))), 65)
    -- a rumour if they've heard one (warm, they always share it)
    local line = (feel >= WARM or math.random() < 0.7) and LC.TakeRumor and LC.TakeRumor(ply)
    -- a sympathizer who likes you: where the Resistance can be found
    if not line and st.rebel and feel >= WARM and LC.SafeHouseHint then line = LC.SafeHouseHint(ply) end
    return line and ("'" .. line .. "'") or Pick(SMALL_TALK)
end

local function ShareFood(ply, npc, st)
    local id = FoodToGive(ply)
    if not id or not LC.TakeItem(ply, id) then return "You've nothing to give." end
    local v = LC.Remember(npc, ply, 2)
    if LC.AddTrait then LC.AddTrait(ply, "sympathy", 1) end
    npc:EmitSound(Vo(st.gender, Pick({ "hi01", "hi02" })), 65)
    hook.Run("LivingCitySharedFood", ply, npc, id)
    local name = LCS and LCS.Items[id] and string.lower(LCS.Items[id].name) or "food"
    if v >= 6 then return "They take the " .. name .. " with both hands. 'I won't forget this. I mean it.'" end
    return "They take the " .. name .. " and hide it in their coat. 'Thank you.'"
end

-- What's in a citizen's pockets (a little; rarely something good).
local function Pocket()
    local r = math.random()
    if r < 0.08 then return "papers_dead" end
    if r < 0.2 then return "ration" end
    if r < 0.3 then return "water" end
    return nil, math.random(2, 9)
end

local function PickPocket(ply, npc, st)
    if (npc.lcPickedAt or 0) > CurTime() - 600 then return "Their pockets are already empty." end
    npc.lcPickedAt = CurTime()
    local roll = math.random(20) + (LC.SkillMod and LC.SkillMod(ply, "guile") or 0)
    LC.Bump(ply, "thefts")
    if roll >= cvPickDC:GetInt() then
        local item, credits = Pocket()
        if item and LC.GiveItem and LC.GiveItem(ply, item, 1) then
            hook.Run("LivingCityPickpocket", ply, npc, true)
            return "Your fingers come out with " .. string.lower(LCS.Items[item] and LCS.Items[item].name or item) .. ". They didn't feel a thing."
        end
        credits = credits or math.random(2, 9)
        if LC.AddCredits then LC.AddCredits(ply, credits) end
        hook.Run("LivingCityPickpocket", ply, npc, true)
        return string.format("%d credits, and they didn't feel a thing.", credits)
    end
    -- caught
    LC.Remember(npc, ply, -3)
    npc:EmitSound(Vo(st.gender, "gethellout"), 75)
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        LC.ReportCrime(ply, "Theft", 120)
        ply:ChatPrint("[Civil Protection] A Civil Protection unit saw that.")
    end
    if LC.Scatter then
        timer.Simple(0.5, function() if IsValid(npc) and LC.NPCs[npc] then LC.Scatter(npc:GetPos(), 60) end end)
    end
    hook.Run("LivingCityPickpocket", ply, npc, false)
    return "They feel your hand and spin round. 'Thief! Get away from me!'", true
end

local function Inform(ply, npc, st)
    if (ply.lcInformNPCAt or 0) > CurTime() - 120 then return "You reported someone a moment ago. Don't push your luck." end
    ply.lcInformNPCAt = CurTime()
    LC.Remember(npc, ply, -4)
    if st.rebel then
        LC.Bump(ply, "reports") -- (reports earn +10 standing: sv_livingcity_economy.lua)
        if LC.AddStanding then LC.AddStanding(ply, 5) end
        if LC.AddTrait then LC.AddTrait(ply, "loyalty", 1) end
        st.rebel = false
        if npc.lcProfile then npc.lcProfile.rebel = nil end
        npc:SetNW2Bool("lc_prebel", false)
        timer.Simple(math.Rand(20, 40), function()
            if IsValid(npc) and LC.NPCs[npc] and LC.ArrestNPC then LC.ArrestNPC(npc, nil) end
        end)
        hook.Run("LivingCityInformedOnNPC", ply, npc, true)
        return "You give their name to a Civil Protection unit. He writes it down. (+15 standing) They'll be picked up.", true
    end
    if LC.AddStanding then LC.AddStanding(ply, -5) end
    hook.Run("LivingCityInformedOnNPC", ply, npc, false)
    return "You give their name to a Civil Protection unit. He checks it and looks at you instead. 'Waste of time.' (-5 standing)", true
end

net.Receive("lc_talk_do", function(_, ply)
    local npc, what = net.ReadEntity(), net.ReadString()
    if (ply.lcTalkNext or 0) > CurTime() then return end
    ply.lcTalkNext = CurTime() + 0.4
    local st = IsValid(npc) and Usable(ply, npc)
    if not st then return end
    local said, close
    if what == "chat" then said = Chat(ply, npc, st)
    elseif what == "food" then said = ShareFood(ply, npc, st)
    elseif what == "pick" and not LC.PlayerIsCP(ply) then said, close = PickPocket(ply, npc, st)
    elseif what == "inform" and not LC.PlayerIsCP(ply) then said, close = Inform(ply, npc, st)
    elseif what == "recruit" and LC.RecruitLookout then
        local ok, msg = LC.RecruitLookout(ply, npc)
        said, close = msg, ok
    else return end
    StepAway(npc, ply)
    if close then
        if said then ply:ChatPrint(said) end
        net.Start("lc_talk") net.WriteEntity(NULL) net.Send(ply) -- (closes the window)
    else
        LC.OpenTalk(ply, npc, said)
    end
end)
LC.TalkAction = function(ply, npc, what) -- (for tests)
    local st = Usable(ply, npc)
    if not st then return nil end
    if what == "chat" then return Chat(ply, npc, st) end
    if what == "food" then return ShareFood(ply, npc, st) end
    if what == "pick" then return PickPocket(ply, npc, st) end
    if what == "inform" then return Inform(ply, npc, st) end
end

-- E on a citizen, if nothing else wants that press.
hook.Add("LivingCityPlayerUsedNPC", "LivingCityTalk", function(ply, npc, st)
    if not cvTalk:GetBool() or not st or st.role ~= "citizen" then return end
    if LC.PlayerIsCP(ply) then return end -- units stop citizens with E (sv_livingcity.lua)
    if LC.QuestWantsNPC and LC.QuestWantsNPC(ply, npc) then return end
    timer.Simple(0, function() if IsValid(ply) and IsValid(npc) then LC.OpenTalk(ply, npc) end end)
end)

------------------------------------------------------------------------
-- Afraid of you, or glad to see you
------------------------------------------------------------------------

timer.Create("LivingCityMemory", 2, 0, function()
    if not LC.Running or not cvTalk:GetBool() then return end
    local now = CurTime()
    for _, ply in LC.Players() do
        if ply:Alive() then
            for _, npc in ipairs(ents.FindInSphere(ply:GetPos(), 220)) do
                local st = LC.NPCs[npc]
                if st and st.role == "citizen" and npc.lcProfile and npc.lcProfile.memory and (st.state == "idle" or st.state == "moving") then
                    local feel = LC.Feeling(npc, ply)
                    if feel <= AFRAID and (npc.lcFleeAt or 0) < now then
                        -- back off from the one who hurt them
                        npc.lcFleeAt = now + 6
                        local away = npc:GetPos() + (npc:GetPos() - ply:GetPos()):GetNormalized() * 300
                        if LC.GoTo(npc, st, away, true, nil) then npc:EmitSound(Vo(st.gender, Pick({ "sorry01", "sorry02" })), 65) end
                    elseif feel >= WARM and (npc.lcGreetAt or 0) < now then
                        npc.lcGreetAt = now + 90
                        LC.Face(npc, ply:GetPos())
                        npc:EmitSound(Vo(st.gender, Pick({ "hi01", "hi02" })), 65)
                    end
                end
            end
        end
    end
end)
