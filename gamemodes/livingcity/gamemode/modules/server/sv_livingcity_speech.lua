--[[
    The Administrator's address, attended (the owner, 13 November: "do crowds gather to listen? that should
    be mandatory, and anyone found not at the speech is beaten until they black out, then teleported to the
    speech where the administrator is giving it").

    Two points in the editor: the speech stand (where she stands, behind a podium put there for the address)
    and the speech crowd (where the city gathers to listen). With both on the map:

      - A player Administrator's F2 > Me > The city's levers > Give a speech... calls the city: Overwatch
        announces it (speech_soon, his custom voice), every citizen is told where to go, NPC citizens walk
        there and stand in rows facing the stand, and she is taken behind the podium. Her words are spoken
        when the muster is over (lc_speech_muster seconds).
      - With nobody playing her, the city's own Administrator gives one on the days with no morning exercise
        (at lc_speech_city_hour), announced in her own voice (speech_soon), standing at the podium herself.
        Her speech is stitched together from short recordings of hers (LC.SpeechCompose): an opening, up to
        three pieces on what happened lately (the chronicle's last lc_speech_lookback minutes, and the state
        of the city), one on the city's mood (the minds), and a closing. Each piece is speech_<id>1.wav in
        sound/livingcity/administrator/ (VOICE_LINES.md lists them all, with words); its words show either way.
      - Citizens found away from it by a unit (from halfway through the muster to the end): a warning, then
        the stick, again and again until they black out (lc_speech_beatings), and they come to standing in
        the crowd.
      - When she speaks the loyal cheer and salute; Resistance sympathizers salute half-heartedly, a beat
        late, and mutter it flat (LC.CrowdCheer, sv_livingcity_exercise.lua).

    With no crowd point, a speech is as it always was: her words at once, from the stand.

      lc_speech_muster 120, lc_speech_after 45, lc_speech_radius 650, lc_speech_beatings 3, lc_speech_npcs 18,
      lc_speech_city 1, lc_speech_city_hour 12, lc_speech_lookback 240, lc_speech_podium (model)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMuster  = CreateConVar("lc_speech_muster", "120", FLAGS, "Seconds the city has to gather before the Administrator's address begins")
local cvAfter   = CreateConVar("lc_speech_after", "45", FLAGS, "Seconds the crowd stays after she has spoken")
local cvRadius  = CreateConVar("lc_speech_radius", "650", FLAGS, "How close to the speech crowd point counts as being at the address")
local cvBeats   = CreateConVar("lc_speech_beatings", "3", FLAGS, "Blows with the stick before someone who skipped the address blacks out (and comes to in the crowd)")
local cvNPCs    = CreateConVar("lc_speech_npcs", "0", FLAGS, "How many of the city's own citizens gather for an address (0: every one of them)")
local cvCity    = CreateConVar("lc_speech_city", "1", FLAGS, "With nobody playing the Administrator, the city's own Administrator gives an address on the days with no morning exercise")
local cvLook    = CreateConVar("lc_speech_lookback", "240", FLAGS, "Minutes of the chronicle the city's own Administrator looks back over for her address")
local cvCityHr  = CreateConVar("lc_speech_city_hour", "12", FLAGS, "The city hour the city's own Administrator gives her address")
local cvDetail  = CreateConVar("lc_speech_detail", "4", FLAGS, "Soldiers and Civil Protection units posted round her at an address, within 20 feet, facing outward (0: none, up to 6; the row of three in front of the stand is apart from these)")
local cvPodium  = CreateConVar("lc_speech_podium", "models/props_combine/breenconsole.mdl", FLAGS, "The podium put in front of the speech stand for an address")

local S -- the address under way, or nil
function LC.SpeechSession() return S end

-- Her speech with nobody playing her, stitched from short pieces (the owner, 13 November: "lines for the
-- speeches that can be dynamically stitched together regarding how the past few days went, any big events").
-- Each piece is a recording of hers, speech_<id>1.wav (in her usual tone; a stern take, speech_<id>_stern1.wav,
-- is used when the city is tense). part: open, event (the chronicle), state (the state of the city), mood
-- (the minds), close. when: what brings it up (for VOICE_LINES.md).
LC.SpeechPieces = {
    { id = "open", part = "open", when = "the opening", tier = 1,
      words = "Citizens. Thank you for coming to hear me. Let us talk about the days behind us." },
    { id = "ev_deaths", part = "event", when = "people were killed lately", tier = 2,
      words = "Blood has been spilled in our streets. Every life lost to violence is stolen from all of us. Violence solves nothing. It only invites more." },
    { id = "ev_arrests", part = "event", when = "people were taken to the cells", tier = 2,
      words = "Civil Protection has been busy. No one taken to the cells was taken at random. They chose disorder, and disorder has a price." },
    { id = "ev_informers", part = "event", when = "citizens informed (she knows who)", tier = 1,
      words = "To those of you who came forward and told us what you saw: thank you. You know who you are, and so do I. Your loyalty will not be forgotten." },
    { id = "ev_informer_hurt", part = "event", when = "the Resistance hurt an informer", tier = 3,
      words = "Some of you were hurt for helping the city, beaten in the dark by cowards who call themselves liberators. Look at what they do to their own neighbours, and ask who your friends really are." },
    { id = "ev_taken", part = "event", when = "the Resistance took someone (the cage, the chair, an execution)", tier = 3,
      words = "Citizens have been taken, dragged off by the so-called Resistance and questioned like animals. That is the freedom they offer you: a cage, and a chair." },
    { id = "ev_escape", part = "event", when = "someone escaped", tier = 3,
      words = "Some who were held have run from where they belong. They will be found. And whoever hides them will stand beside them when they are." },
    { id = "ev_posters", part = "event", when = "the city's posters were defaced", tier = 2,
      words = "Someone has been defacing the city's notices. A poster costs the Union very little. Replacing it will cost you your rations." },
    { id = "ev_theft", part = "event", when = "there was stealing", tier = 2,
      words = "There has been stealing, from the city and from each other. A thief steals from everyone standing in this square." },
    { id = "ev_defiance", part = "event", when = "people shouted at units or accused each other (a mind breaking)", tier = 2,
      words = "Voices have been raised at the officers who keep you safe. I understand frustration. I will not tolerate it in the street." },
    { id = "ev_sabotage", part = "event", when = "someone sabotaged the city's work (a mind breaking)", tier = 3,
      words = "Machines have been broken and the city's work undone. Sabotage hurts no one but you. It is your water, your light, your bread." },
    { id = "ev_heavyhand", part = "event", when = "a unit was brutal (a mind breaking)", tier = 2,
      words = "Some of you have seen our officers act firmly. Firmness is a kindness, in the end. It ends trouble before trouble ends you." },
    { id = "ev_drink", part = "event", when = "people took to drink (a mind breaking)", tier = 1,
      words = "I hear some of you have found comfort in a bottle. I do not blame you. But a clear head is a loyal head." },
    { id = "ev_kindness", part = "event", when = "people shared food or steadied each other (a mind breaking)", tier = 1,
      words = "And I have seen good things too: neighbours sharing their bread, calming each other's nerves. That is the city I am proud of." },
    { id = "ev_despair", part = "event", when = "people gave up hope (a mind breaking)", tier = 1,
      words = "Some of you have lost hope. Do not. Hope is not something you are given. It is something you choose, every morning." },
    { id = "unrest", part = "state", when = "the Resistance is strong", tier = 3,
      words = "There are those among you who whisper of freedom and mean only chaos. Every one of them you shelter is a debt your whole block will pay." },
    { id = "hunger", part = "state", when = "supply is low", tier = 1,
      words = "I know the rations have been thin. I feel every empty bowl as if it were my own. Work your shifts, keep your quotas, and the trains will come." },
    { id = "order", part = "state", when = "her authority is low", tier = 2,
      words = "Let me be clear, so no one can say they were not told. The rules of this city are not suggestions, and my authority is not in question." },
    { id = "morale", part = "state", when = "morale is low", tier = 1,
      words = "I see tired faces, and I understand. But the lights are on, the streets are swept, and not one of you is alone." },
    { id = "calm", part = "state", when = "nothing much happened (a quiet few days)", tier = 1,
      words = "These have been quiet days, days of order and honest work. The Union sees it. I see it." },
    { id = "mood_afraid", part = "mood", when = "the city's people are frightened (the minds: stress high)", tier = 1,
      words = "I can see fear in your faces. You have nothing to fear from me. Only from those who would set you against me." },
    { id = "mood_restless", part = "mood", when = "the city's people are restless (the minds: unrest high)", tier = 2,
      words = "There is a restlessness in this city. I feel it. Restlessness can be turned into work, or into ruin. Choose work." },
    { id = "mood_content", part = "mood", when = "the city's people are at ease (the minds: stress low)", tier = 1,
      words = "You look well: rested, fed and calm. Good. Keep it so." },
    -- After an attempt on her life her whole next address is about it (the owner, 16 November: "lines for her next
    -- speech: she will need to ham this up and take full advantage of it from every angle"): herself the martyr, the
    -- shot aimed at everyone, her guards (or the soldier who died on the grenade), the enemy, the hunt (or the traitor
    -- dealt with), what it will cost the city, and that she is not going anywhere. In this order, then her slogan.
    { id = "attempt_open", part = "attempt", when = "after an attempt on her life: the opening", tier = 3,
      words = "Citizens. Look at me. I am still here. Not long ago, on this very spot, someone tried to kill your Administrator." },
    { id = "attempt_martyr", part = "attempt", when = "after an attempt on her life: herself", tier = 3,
      words = "I felt how close it came. I will carry that moment for the rest of my life. And do you know what I thought of? Not myself. I thought of you, and of who would look after you if I were gone." },
    { id = "attempt_you", part = "attempt", when = "after an attempt on her life: it was aimed at everyone", tier = 3,
      words = "That shot was not meant for me alone. It was aimed at your rations, your homes and your safety. Whoever strikes at me strikes at every one of you." },
    { id = "attempt_hero", part = "attempt", when = "after an attempt on her life: a soldier died on the grenade", tier = 3,
      words = "A soldier threw himself on a grenade that was meant for me. He did not hesitate. Ask yourselves whether you would have done the same, and remember him tonight." },
    { id = "attempt_guards", part = "attempt", when = "after an attempt on her life: her guards (no soldier died)", tier = 3,
      words = "My guards did not hesitate. They put themselves between me and death, as they do for you every day. Thank them when you pass them. Loudly." },
    { id = "attempt_enemy", part = "attempt", when = "after an attempt on her life: who did it", tier = 3,
      words = "And who did this? A coward. One of the so-called Resistance, who call themselves your liberators and shoot at a woman giving a speech. That is their courage. That is all they have to offer you." },
    { id = "attempt_caught", part = "attempt", when = "after an attempt on her life: the attacker is dead or in the cells", tier = 3,
      words = "The traitor has been dealt with. There was no mercy, and there will be none for the next one." },
    { id = "attempt_hunt", part = "attempt", when = "after an attempt on her life: the attacker is still free", tier = 3,
      words = "The traitor is still among you. Someone here knows the face, the name, the door. Tell Civil Protection and your block will eat well. Stay silent and your block will answer for it." },
    { id = "attempt_measures", part = "attempt", when = "after an attempt on her life: what it costs the city", tier = 3,
      words = "I never wanted checkpoints. I never wanted searches or curfews. But I will not apologise for keeping this city safe, and neither should you. Blame the ones who made it necessary." },
    { id = "attempt_resolve", part = "attempt", when = "after an attempt on her life: she is not going anywhere", tier = 3,
      words = "They wanted me afraid. They wanted this stand empty. I will stand here again tomorrow, and the day after, for as long as you need me. I am not going anywhere." },
    -- (the owner's own slogan, 14 November: "THIS IS GOLD, SAVE THIS SOMEWHERE AS A SLOGAN"; never reword it)
    { id = "slogan", part = "slogan", when = "her slogan, before the closing, every time", tier = 1,
      words = "Love your neighbour, hate the traitor." },
    { id = "close", part = "close", when = "the closing", tier = 1,
      words = "Now go back to your work, and remember: this city is only as strong as each one of you. Glory to the Union." },
}
local PIECE = {}
for _, p in ipairs(LC.SpeechPieces) do PIECE[p.id] = p end
LC.SpeechPiece = PIECE

-- Which piece each thing in the chronicle brings up (its kind; a mind breaking is "did:<kind>").
LC.SpeechEventOf = {
    killed = "ev_deaths", died = "ev_deaths", killing = "ev_deaths",
    arrest = "ev_arrests", ["did:inform"] = "ev_informers", snitch = "ev_informer_hurt",
    caged = "ev_taken", chair = "ev_taken", chair_wrong = "ev_taken", executed = "ev_taken",
    escaped = "ev_escape", poster = "ev_posters", robbed = "ev_theft",
    ["did:tantrum"] = "ev_defiance", ["did:defy"] = "ev_defiance", ["did:accuse"] = "ev_defiance",
    ["did:sabotage"] = "ev_sabotage", ["did:brutal"] = "ev_heavyhand",
    ["did:drink"] = "ev_drink", ["did:binge"] = "ev_drink",
    ["did:share"] = "ev_kindness", ["did:steady"] = "ev_kindness", ["did:despair"] = "ev_despair",
}
-- (she hears of informing, which nobody else does; the rest only if the street saw it)
local SHE_KNOWS = { ["did:inform"] = true }

-- What happened lately, from the chronicle: { [piece id] = weight }.
function LC.SpeechEvents(since)
    local out = {}
    local C = LC.Chron
    if not (C and C.list) then return out end
    if LC.ChronicleLoad and not C.loaded then LC.Try(LC.ChronicleLoad) end
    for i = #C.list, 1, -1 do
        local e = C.list[i]
        if e.t < since then break end
        local id = LC.SpeechEventOf[e.k]
        if id and (not e.sec or SHE_KNOWS[e.k]) then out[id] = (out[id] or 0) + (e.w or 1) end
    end
    return out
end
-- The city's mood, from the minds: average stress (0 to 40) and unrest (0 to 1) of the roster's citizens.
function LC.SpeechMood()
    local M = LC.Minds
    local n, stress, roster = 0, 0, {}
    for _, m in pairs(M and M.byId or {}) do
        if m.psy and m.role == "citizen" and not m.dead then
            n = n + 1
            stress = stress + (m.psy.stress or 0)
            roster[#roster + 1] = m
        end
    end
    if n == 0 then return nil end
    local unrest = (LC.Psy and LC.Psy.Unrest and LC.Psy.Unrest(roster)) or 0
    return { stress = stress / n, unrest = unrest }
end
-- Her speech, as pieces in order: an opening, up to three on what happened (the weightiest), one on the mood,
-- a closing. state: the state of the city (LC.Ledger()); events: LC.SpeechEvents; mood: LC.SpeechMood.
function LC.SpeechCompose(state, events, mood, attempt)
    state = state or {}
    -- attempt: there was one on her life since she last spoke ({ hero = a soldier died on the grenade, caught = the
    -- attacker is dead or in the cells }; LC.AdminAttemptPending): her whole address is about it, stern throughout.
    if attempt then
        return { PIECE.attempt_open, PIECE.attempt_martyr, PIECE.attempt_you,
            attempt.hero and PIECE.attempt_hero or PIECE.attempt_guards, PIECE.attempt_enemy,
            attempt.caught and PIECE.attempt_caught or PIECE.attempt_hunt,
            PIECE.attempt_measures, PIECE.attempt_resolve, PIECE.slogan, PIECE.close }, true
    end
    local w = {}
    for id, v in pairs(events or {}) do w[id] = v end
    if (state.resistance or 50) >= 65 then w.unrest = (w.unrest or 0) + 4 end
    if (state.supply or 50) <= 30 then w.hunger = (w.hunger or 0) + 4 end
    if (state.authority or 50) <= 35 then w.order = (w.order or 0) + 3 end
    if (state.morale or 50) <= 35 then w.morale = (w.morale or 0) + 3 end
    local ids = {}
    for id, v in pairs(w) do if PIECE[id] and v > 0 then ids[#ids + 1] = id end end
    table.sort(ids, function(a, b) if w[a] ~= w[b] then return w[a] > w[b] end return a < b end)
    local out = { PIECE.open }
    for i = 1, math.min(3, #ids) do out[#out + 1] = PIECE[ids[i]] end
    if #ids == 0 then out[#out + 1] = PIECE.calm end
    if mood then
        local m = (mood.stress >= 14 and "mood_afraid") or (mood.unrest >= 0.5 and "mood_restless") or (mood.stress <= 4 and "mood_content") or nil
        if m then out[#out + 1] = PIECE[m] end
    end
    out[#out + 1] = PIECE.slogan
    out[#out + 1] = PIECE.close
    -- (tense: she takes the stern line throughout, where she has one)
    local tense = (state.resistance or 50) >= 65 or LC.Socio == "red" or (w.ev_taken or 0) > 0 or (w.ev_sabotage or 0) > 0
    return out, tense
end
-- (old name, kept: what the state of the city alone would have her say)
function LC.SpeechTopicFor(state)
    local pieces = LC.SpeechCompose(state, {}, nil)
    return pieces[2]
end
-- The announcement and her speeches, as recordings (sv_livingcity_announcer.lua finds them by name).
LC.SpeechSoonWords = {
    overwatch = "Attention, all residents: the City Administrator will address the city. Report to the assembly point immediately. Attendance is mandatory.",
    administrator = "My dear citizens, I am going to speak to you all in a few minutes. Come and gather in front of the stand. I would so hate to miss anyone.",
}

local function Points(kind)
    return (LC.PointsOfKind and LC.PointsOfKind(kind)) or {}
end
local function Nearest(kind, from)
    local best, bd
    for _, p in ipairs(Points(kind)) do
        local d = from and p.pos:DistToSqr(from) or 0
        if not bd or d < bd then best, bd = p, d end
    end
    return best
end
-- Both points, the crowd's and the nearest stand to it: nil when the map has no crowd point.
function LC.SpeechPlaces(from)
    local crowd = Nearest("speechcrowd", from)
    if not crowd then return nil end
    local stand = Nearest("speech", crowd.pos)
    if not stand then return nil end
    return stand, crowd
end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "the speech stand" end

-- The i-th place in the crowd: rows of six facing the stand (cols: wider rows, for a whole city of them).
local function SpotFor(c, st, i, cols)
    cols = cols or 6
    local toward = st - c
    toward.z = 0
    if toward:LengthSqr() < 1 then toward = Vector(1, 0, 0) end
    toward:Normalize()
    local side = Vector(-toward.y, toward.x, 0)
    local row, col = math.floor((i - 1) / cols), (i - 1) % cols
    local pos = c + side * ((col - (cols - 1) / 2) * 56) - toward * (row * 60)
    pos = (LC.GroundAt and LC.GroundAt(pos + Vector(0, 0, 30))) or pos
    return pos, math.deg(math.atan2(toward.y, toward.x))
end
function LC.SpeechSpot(i)
    if not S then return nil end
    return SpotFor(S.crowd.pos, S.stand.pos, i, S.cols)
end

local function AtSpeech(p)
    return S and IsValid(p) and p:GetPos():DistToSqr(S.crowd.pos) < cvRadius:GetFloat() ^ 2
end
LC.AtSpeech = AtSpeech

local function MustAttend(p)
    if not IsValid(p) or p == S.by then return false end
    if LC.ExerciseEligible then return LC.ExerciseEligible(p) end
    return p:GetNW2String("lcf_faction", "") == "citizen"
end

-- The podium, and (the city's own address) her, behind it.
local function Dress()
    local yaw = S.stand.yaw or 0
    local fwd = Angle(0, yaw, 0):Forward()
    local pod = ents.Create("prop_dynamic")
    if IsValid(pod) then
        local mdl = cvPodium:GetString()
        if util.IsValidModel and not util.IsValidModel(mdl) then mdl = "models/props_combine/breenconsole.mdl" end
        pod:SetModel(mdl)
        pod:SetPos(S.stand.pos + fwd * 30)
        pod:SetAngles(Angle(0, yaw + 180, 0))
        pod:Spawn()
        S.podium = pod
    end
    if not IsValid(S.by) then
        local mdl = GetConVar("lc_administrator_model") and string.Trim(GetConVar("lc_administrator_model"):GetString()) or ""
        if mdl == "" or (util.IsValidModel and not util.IsValidModel(mdl)) then mdl = "models/mossman.mdl" end
        local her = ents.Create("npc_citizen")
        if IsValid(her) then
            her:SetModel(mdl)
            her:SetPos(S.stand.pos + Vector(0, 0, 4))
            her:SetAngles(Angle(0, yaw, 0))
            her:Spawn()
            if her.Activate then her:Activate() end
            if LC.SetNPCStr then
                LC.SetNPCStr(her, "lc_pname", (LC.AdministratorName and LC.AdministratorName()) or "The City Administrator")
                LC.SetNPCStr(her, "lc_pjob", "City Administrator")
            end
            her.lcSpeechHer = true
            S.her = her
        end
    end
end

-- Who of the city's own can be called to it, and how they drop what they were doing (the owner, 15 November:
-- "please make sure all the citizen NPCs show up, they seem to not show up to scripted events like this"). Only
-- the idle and the walking used to be asked, once, and at most 18 of them: at most hours nearly everyone is
-- sitting, working, in a line or at home. The same rule as the morning exercise's (sv_livingcity_exercise.lua):
-- whatever they are doing, by day out of bed too; never one in a player's job, held, going home or in something
-- scripted already.
local CALL = { idle = true, moving = true, busy = true, inline = true, working = true }
local function Callable(npc, st, wake)
    if LC.ExerciseDraftable then return LC.ExerciseDraftable(npc, st, wake) end
    if not IsValid(npc) or st.role ~= "citizen" or st.test or st.unmanaged or st.questLock or st.leaving or st.exCitizen then return false end
    if st.carry and not st.npcWork then return false end
    if st.state == "abed" then return wake == true end
    return CALL[st.state] == true
end
local function CallAway(npc, st)
    if LC.ExerciseCallAway then return LC.ExerciseCallAway(npc, st) end
    if st.state == "abed" and LC.NPCBedUp then LC.NPCBedUp(npc, st) end
    if st.state == "busy" and LC.EndBusy then LC.EndBusy(npc, st, false) end
    if st.line and LC.LeaveLine then LC.LeaveLine(npc, st) end
    if st.npcWork and LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
    if LC.Release then LC.Release(npc, st) end
end
local function Candidates()
    local wake = not (LC.DayPhase and LC.DayPhase() == "night")
    local now = CurTime()
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if not S.npcs[npc] and not st.addressCrowd and now >= (st.speechNoWay or 0) and Callable(npc, st, wake) then
            cands[#cands + 1] = { npc = npc, st = st, d = npc:GetPos():DistToSqr(S.crowd.pos) }
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    return cands
end

-- The city's own citizens walk to the crowd: every one of them (lc_speech_npcs 0), nearest first. Asked again
-- every few seconds until she speaks, so those who were held up or came out later come too.
local function Gather()
    local cap = cvNPCs:GetInt()
    S.npcs = S.npcs or {}
    S.spots = S.spots or 0
    local now = CurTime()
    for _, c in ipairs(Candidates()) do
        if cap > 0 and S.spots >= cap then break end
        local pos, yaw = LC.SpeechSpot(S.spots + 1)
        if not pos then break end
        local was = c.st.state
        CallAway(c.npc, c.st)
        if LC.GoTo and LC.GoTo(c.npc, c.st, pos, c.d > 1500 * 1500, { kind = "speech", pos = pos, yaw = yaw }) then
            c.st.speechYaw = yaw
            S.npcs[c.npc] = true
            S.spots = S.spots + 1
        else
            c.st.speechNoWay = now + 120 -- (no way there from where they are: not asked again for a while)
            if was ~= "idle" and was ~= "moving" then
                LC.SetState(c.npc, c.st, "idle")
                c.st.untilT = now + 2
            end
        end
    end
    return S.spots
end

-- And those at home come out for it, by day: a few at each ask, from a doorway out of sight near the crowd
-- (always one of the city's own people, never a nameless extra: sv_livingcity_people.lua).
local function ComeOut(most)
    if LC.DayPhase and LC.DayPhase() == "night" then return 0 end
    local sp = LC.Spawners and LC.Spawners.citizen
    if not (sp and LC.PersonAvailable and LC.AlarmSquadSpot) then return 0 end
    if LC.PeopleCallOut then LC.PeopleCallOut("citizen") end
    local cap, n = cvNPCs:GetInt(), 0
    while n < most and (cap <= 0 or S.spots < cap) and LC.PersonAvailable("citizen") do
        local pos, yaw = LC.SpeechSpot(S.spots + 1)
        local from = pos and LC.AlarmSquadSpot(pos)
        if not from then break end
        local ok, npc, st = LC.Try(sp, from)
        if not (ok and IsValid(npc) and st) then break end
        n = n + 1
        if LC.GoTo and LC.GoTo(npc, st, pos, true, { kind = "speech", pos = pos, yaw = yaw }) then
            st.speechYaw = yaw
            S.npcs[npc] = true
            S.spots = S.spots + 1
        end
    end
    return n
end

-- Three soldiers in a row in front of the stand, facing the crowd (the owner, 15 November: "can we have a row
-- of 3 combine soldiers stand facing the speech crowd?"). The address's own: never from Overwatch's reserve,
-- gone when it ends. One drawn off by a fight walks back to his place.
local GUARD_OUT, GUARD_GAP = 110, 70
-- The detail round her (the owner, 15 November: "sprinkle a couple of soldiers and metro cops around the radius of
-- the administrator, within 20 feet. I want it to look like a high security event"): a Civil Protection unit at
-- each side of her and soldiers behind, each looking outward. ang: round from the way the crowd is; out: how far
-- from the stand (20 feet is 320 units).
local DETAIL = {
    { ang = 80, out = 180, cop = true }, { ang = -80, out = 180, cop = true },
    { ang = 140, out = 270 }, { ang = -140, out = 270 },
    { ang = 180, out = 310 }, { ang = 110, out = 300, cop = true },
}
local function PostOne(make, weapon, pos, yaw, doing)
    local ok, npc, st
    if LC.ManpowerFree then ok, npc, st = LC.Try(LC.ManpowerFree, make, pos + Vector(0, 0, 4), weapon)
    else ok, npc, st = LC.Try(make, pos + Vector(0, 0, 4), weapon) end
    if not (ok and IsValid(npc) and st) then return nil end
    st.unmanaged, st.questLock = true, true
    LC.SetState(npc, st, "speechguard")
    npc:SetAngles(Angle(0, yaw, 0))
    if LC.SetNPCStr then LC.SetNPCStr(npc, "lc_doing", doing) end
    npc.lcSpeechGuard = { pos = pos, yaw = yaw }
    return npc
end
local function PostGuards()
    S.guards, S.detail = {}, {}
    if not LC.SpawnSoldier then return end
    local toward = S.crowd.pos - S.stand.pos
    toward.z = 0
    if toward:LengthSqr() < 1 then toward = Angle(0, S.stand.yaw or 0, 0):Forward() end
    toward:Normalize()
    local side = Vector(-toward.y, toward.x, 0)
    local yaw = math.deg(math.atan2(toward.y, toward.x))
    for i = -1, 1 do
        local pos = S.stand.pos + toward * GUARD_OUT + side * (i * GUARD_GAP)
        pos = (LC.GroundAt and LC.GroundAt(pos + Vector(0, 0, 30))) or pos
        local npc = PostOne(LC.SpawnSoldier, "ar2", pos, yaw, "guarding the address")
        if npc then S.guards[#S.guards + 1] = npc end
    end
    -- the detail round her
    for k = 1, math.Clamp(cvDetail:GetInt(), 0, #DETAIL) do
        local d = DETAIL[k]
        local out = Angle(0, yaw + d.ang, 0):Forward()
        local reach = d.out
        -- (a wall in the way: as far out as there is room, or not at all)
        local tr = util.TraceLine and util.TraceLine({ start = S.stand.pos + Vector(0, 0, 40), endpos = S.stand.pos + Vector(0, 0, 40) + out * reach, mask = MASK_SOLID_BRUSHONLY })
        if tr and tr.Hit and tr.Fraction then reach = reach * tr.Fraction - 30 end
        if reach >= 90 then
            local pos = S.stand.pos + out * reach
            pos = (LC.GroundAt and LC.GroundAt(pos + Vector(0, 0, 30))) or pos
            local npc
            if d.cop and LC.SpawnCop then npc = PostOne(LC.SpawnCop, nil, pos, yaw + d.ang, "guarding the Administrator")
            else npc = PostOne(LC.SpawnSoldier, "ar2", pos, yaw + d.ang, "guarding the Administrator") end
            if npc then S.detail[#S.detail + 1] = npc end
        end
    end
end
LC.SpeechGuards = function() return S and S.guards or {} end
LC.SpeechDetail = function() return S and S.detail or {} end
-- Her security takes them over (an attempt on her life: sv_livingcity_adminsecurity.lua): the row, the detail
-- and the city's own Administrator, if she stands there, are no longer the address's to remove when it ends.
function LC.SpeechHandOver()
    if not S then return {}, nil end
    local list = {}
    for _, l in ipairs({ S.guards or {}, S.detail or {} }) do
        for _, g in ipairs(l) do if IsValid(g) then list[#list + 1] = g end end
    end
    S.guards, S.detail = {}, {}
    local her = S.her
    S.her = nil
    return list, her
end
local function GuardsThink(now)
    if now < (S.nextGuards or 0) then return end
    S.nextGuards = now + 2
    for _, list in ipairs({ S.guards or {}, S.detail or {} }) do
        for _, npc in ipairs(list) do
            local post = IsValid(npc) and npc:Health() > 0 and npc.lcSpeechGuard
            if post and not (npc.GetEnemy and IsValid(npc:GetEnemy())) then
                if npc:GetPos():DistToSqr(post.pos) > 40 * 40 then
                    if npc.SetLastPosition and npc.SetSchedule then
                        npc:SetLastPosition(post.pos)
                        npc:SetSchedule(SCHED_FORCED_GO)
                    end
                elseif LC.FaceYaw and math.abs((npc:GetAngles().y - post.yaw + 180) % 360 - 180) > 12 then
                    LC.FaceYaw(npc, post.yaw)
                end
            end
        end
    end
end
-- One of them at their place: they stand and face the stand (sv_livingcity.lua's Arrive hands them over).
function LC.SpeechArrive(npc, st, now)
    if not (S and S.npcs[npc]) then
        -- a few come to hear her for the agenda's "Address the citizens" (LC.SpeechGatherFew): they stay while it lasts
        if st.addressCrowd and st.questLock == st.addressCrowd then
            LC.SetState(npc, st, "event")
            st.eventUntil = now + 300
            if st.speechYaw and LC.FaceYaw then LC.FaceYaw(npc, st.speechYaw) end
            return
        end
        st.untilT = now + 2
        return
    end
    LC.SetState(npc, st, "event")
    st.eventUntil = now + 900
    if st.speechYaw and LC.FaceYaw then LC.FaceYaw(npc, st.speechYaw) end
end

-- A few of the city's own walk to the crowd point to hear her, without a whole address (the agenda's
-- "Address the citizens": the owner, 15 November, placed a stand and a crowd point and the job sent her to
-- a random room). tag: what keeps them there (the job, which locks them to it: sv_livingcity_quests.lua).
-- Returns the citizens on their way.
function LC.SpeechGatherFew(stand, crowd, n, tag)
    local out = {}
    if not (stand and crowd) then return out end
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and (st.state == "idle" or st.state == "moving") and not st.unmanaged and not st.questLock
            and not st.test and not st.leaving and not st.line and not st.npcWork and not st.carry and not st.exCitizen
            and not (S and S.npcs[npc]) then
            local d = npc:GetPos():DistToSqr(crowd.pos)
            if d < 3000 * 3000 then cands[#cands + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    for _, c in ipairs(cands) do
        if #out >= n then break end
        local pos, yaw = SpotFor(crowd.pos, stand.pos, #out + 1)
        if LC.GoTo and LC.GoTo(c.npc, c.st, pos, false, { kind = "speech", pos = pos, yaw = yaw }) then
            c.st.speechYaw, c.st.addressCrowd = yaw, tag
            out[#out + 1] = c.npc
        end
    end
    return out
end

local function Tell(p, title, text, secs)
    if LC.Notice then LC.Notice(p, "warn", title, text, secs or 10) else p:ChatPrint("[" .. title .. "] " .. text) end
end

-- Call the city to an address. by: the player Administrator (nil: the city's own). text: her words (a
-- player's), or nil (the city's own picks a topic). Returns true, or false and why.
function LC.CallSpeech(by, text)
    if S then return false, "The city is already gathering for an address." end
    local stand, crowd = LC.SpeechPlaces(IsValid(by) and by:GetPos() or nil)
    if not stand then return false, "There's no speech crowd point in this city. (Staff: Miscount Editor > Point: Administrator's speech crowd.)" end
    local now = CurTime()
    S = { by = IsValid(by) and by or nil, text = text, stand = stand, crowd = crowd, startT = now,
          speakAt = now + cvMuster:GetFloat(), npcs = {}, beaten = {}, warned = {} }
    if not S.by then
        local attempt = LC.AdminAttemptPending and LC.AdminAttemptPending() or nil
        local pieces, tense = LC.SpeechCompose(LC.Ledger and LC.Ledger() or {}, LC.SpeechEvents(os.time() - cvLook:GetFloat() * 60), LC.SpeechMood(), attempt)
        S.pieces, S.tense, S.attempt = pieces, tense, attempt ~= nil or nil
        local words = {}
        for _, p in ipairs(pieces) do words[#words + 1] = p.words end
        S.text = table.concat(words, " ")
    end
    Dress()
    PostGuards()
    -- (rows of six for a small crowd; up to twelve across when the whole city comes)
    local coming = #Candidates()
    if cvNPCs:GetInt() > 0 then coming = math.min(coming, cvNPCs:GetInt()) end
    S.cols = math.Clamp(math.ceil(math.sqrt(coming * 1.6)), 6, 12)
    if S.by then
        S.by:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(stand.pos + Vector(0, 0, 8))) or stand.pos)
        if S.by.SetEyeAngles then S.by:SetEyeAngles(Angle(0, stand.yaw or 0, 0)) end
        hook.Run("LivingCityAdminMoved", S.by, stand.pos)
        Tell(S.by, "Your address", string.format("The city is gathering in front of the stand. You speak in %d seconds.", math.floor(cvMuster:GetFloat())), 8)
    end
    -- the call: Overwatch's custom voice for a player's speech, her own for the city's
    local voice = S.by and "overwatch" or "administrator"
    if LC.CustomAnnounce then LC.Try(LC.CustomAnnounce, voice, "speech_soon", nil, true) end
    local where = Where(crowd.pos)
    for _, p in ipairs(player.GetAll()) do
        if MustAttend(p) then
            Tell(p, "The Administrator's address", "All citizens report to " .. where .. " now. Attendance is mandatory.", 12)
        end
    end
    Gather()
    hook.Run("LivingCitySpeechCalled", S.by, S)
    return true
end

-- Her words, now.
local function Speak()
    S.spoken = CurTime()
    local by = S.by
    if by and not IsValid(by) then by = nil end
    if S.pieces then
        -- the city's own: piece by piece, each line in chat as she says it (the screens get the whole of it)
        S.queue, S.nextPiece = {}, CurTime()
        for _, p in ipairs(S.pieces) do S.queue[#S.queue + 1] = p end
        if LC.SpeechDeliver then LC.SpeechDeliver(nil, S.text, S.crowd.pos, true) end
        return
    end
    if LC.SpeechDeliver then LC.SpeechDeliver(by, S.text, S.crowd.pos) end
    if LC.SpeechCrowd then LC.SpeechCrowd(S.crowd.pos, cvRadius:GetFloat() + 150) end
    S.endAt = CurTime() + cvAfter:GetFloat()
end
-- The next piece of her speech: its recording from her at the podium, its words in chat. Returns seconds it takes.
local function SayPiece(p)
    local path, txt
    if LC.PickAnnounceClip then path, txt = LC.PickAnnounceClip("administrator", "speech_" .. p.id, false, S.tense and 3 or p.tier) end
    local words = txt or p.words
    if path and IsValid(S.her) then S.her:EmitSound(path, 100, 100) end
    for _, q in ipairs(player.GetAll()) do q:ChatPrint("[The City Administrator, from the stand] " .. words) end
    S.said = (S.said or 0) + 1
    local secs = path and LC.AnnounceKnownSecs and LC.AnnounceKnownSecs(path) or 0
    if secs <= 0.2 then
        local n = 0
        for _ in string.gmatch(words, "%S+") do n = n + 1 end
        secs = math.max(3, n / 2.6)
    end
    return secs
end
local function SpeakOn(now)
    if not (S.queue and now >= (S.nextPiece or 0)) then return end
    local p = table.remove(S.queue, 1)
    if p then
        S.nextPiece = now + SayPiece(p) + 0.6
        return
    end
    S.queue = nil
    if S.attempt and LC.AdminAttemptSpoken then LC.AdminAttemptSpoken() end -- (said: her next address is an ordinary one)
    if LC.SpeechCrowd then LC.SpeechCrowd(S.crowd.pos, cvRadius:GetFloat() + 150) end
    S.endAt = now + cvAfter:GetFloat()
end

function LC.EndSpeech()
    if not S then return end
    local now = CurTime()
    for npc in pairs(S.npcs or {}) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and (st.state == "event" or st.state == "moving") then
            LC.SetState(npc, st, "idle")
            st.untilT = now + math.Rand(1, 5)
            st.speechYaw = nil
        end
    end
    if IsValid(S.podium) then S.podium:Remove() end
    if IsValid(S.her) then S.her:Remove() end
    for _, g in ipairs(S.guards or {}) do if IsValid(g) then g:Remove() end end
    for _, g in ipairs(S.detail or {}) do if IsValid(g) then g:Remove() end end
    hook.Run("LivingCitySpeechEnded", S)
    S = nil
end

-- Out cold, then they come to in the crowd.
local function BlackOut(p)
    local spot = S and LC.SpeechSpot((S.spots or 0) + 1 + (S.ko or 0))
    S.ko = (S.ko or 0) + 1
    if LC.KnockOut then
        LC.KnockOut(p, 6, 3, { "Out cold", "The stick again, and again. Everything goes black." })
    end
    timer.Simple(5.5, function()
        if not (IsValid(p) and p:Alive() and spot) then return end
        p:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(spot)) or spot)
        if S and p.SetEyeAngles then p:SetEyeAngles(Angle(0, (S.stand.pos - spot):Angle().y, 0)) end
        Tell(p, "You come to", "Standing in the crowd in front of the stand, held up by the people either side of you. Your head is pounding.", 8)
    end)
end
LC.SpeechBlackOut = BlackOut

-- The unit after someone who skipped it, if any (sv_livingcity.lua: that unit never takes them for crowding it).
function LC.SpeechChaser(p) return S and S.chaser and S.chaser[p] or nil end

-- A unit who sees someone skipping it: a warning, then the stick until they black out.
local function Strike(npc, p, now)
    if LC.ExerciseBeat and LC.ExerciseBeat(npc, p, "speech") then
        S.beaten[p] = (S.beaten[p] or 0) + 1
        if S.beaten[p] >= cvBeats:GetInt() or p:Health() <= 20 then
            S.beaten[p] = 0
            S.warned[p], S.chaser[p] = nil, nil
            BlackOut(p)
            p.lcSpeechNext = now + 8
        end
    end
end
local function Hunt(now)
    S.chaser = S.chaser or {}
    for _, p in ipairs(player.GetAll()) do
        -- the unit who warned them stays on them: after them, then the stick
        local u = S.chaser[p]
        if u and (not IsValid(u) or not MustAttend(p) or AtSpeech(p)) then S.chaser[p], u = nil, nil end
        if u and now >= (p.lcSpeechNext or 0) then
            local ust = LC.NPCs[u]
            if u:GetPos():DistToSqr(p:GetPos()) < 120 * 120 then
                Strike(u, p, now)
            elseif ust and ust.state ~= "hostile" and now >= (S.chaseT or 0) and LC.GoTo then
                LC.GoTo(u, ust, p:GetPos(), true, nil)
            end
        elseif MustAttend(p) and not AtSpeech(p) and now >= (p.lcSpeechNext or 0) then
            p.lcSpeechNext = now + 1
            local eye = p:EyePos()
            for npc, st in pairs(LC.NPCs or {}) do
                if IsValid(npc) and LC.IsSecurity and LC.IsSecurity(st) and st.state ~= "hostile"
                    and npc:GetPos():DistToSqr(p:GetPos()) < 800 * 800 and (not LC.LineOfSight or LC.LineOfSight(npc:EyePos(), eye, npc)) then
                    if not S.warned[p] then
                        S.warned[p] = true
                        if LC.Face then LC.Face(npc, p:GetPos()) end
                        npc:EmitSound("npc/metropolice/vo/firstwarningmove.wav", 78)
                        Tell(p, "Civil Protection", "The Administrator is addressing the city. Report to " .. Where(S.crowd.pos) .. ". Now.", 8)
                        p.lcSpeechNext = now + 12
                        S.chaser[p] = npc -- (and keeps an eye on them: still not moving when the time's up, the stick)
                    elseif npc:GetPos():DistToSqr(p:GetPos()) < 120 * 120 then
                        Strike(npc, p, now)
                        S.chaser[p] = npc
                    elseif LC.GoTo and (st.state == "idle" or st.state == "moving") then
                        LC.GoTo(npc, st, p:GetPos(), true, nil)
                        S.chaser[p] = npc
                    end
                    break
                end
            end
        end
    end
end

-- The city's own Administrator, once a city day, with nobody in the post.
local function CityDue()
    if not cvCity:GetBool() or S then return false end
    if LC.HumanAdministrator and LC.HumanAdministrator() then return false end
    if LC.EndingSession and LC.EndingSession() then return false end
    if not LC.SpeechPlaces() then return false end
    local hr = LC.Hour and LC.Hour()
    if not hr or math.floor(hr) ~= cvCityHr:GetInt() then return false end
    if LC.ExerciseToday then return false end -- (on the days with no morning exercise: the owner, 13 November)
    local day = LC.Ledger and LC.Ledger().day or 0
    if LC.SpeechCityDay == day then return false end
    LC.SpeechCityDay = day
    return true
end
LC.SpeechCityDue = CityDue

function LC.SpeechThink(now)
    now = now or CurTime()
    if not S then
        if CityDue() then LC.CallSpeech(nil, nil) end
        return
    end
    if S.by and not IsValid(S.by) then
        for _, p in ipairs(player.GetAll()) do if MustAttend(p) then Tell(p, "The Administrator's address", "The address is cancelled. Go about your business.", 8) end end
        LC.EndSpeech()
        return
    end
    if not S.spoken and now >= (S.nextGather or (S.startT + 4)) then
        S.nextGather = now + 4
        Gather()
        ComeOut(4)
    end
    GuardsThink(now)
    if now >= S.startT + cvMuster:GetFloat() * 0.5 then Hunt(now) end
    if not S.spoken and now >= S.speakAt then Speak() end
    if S and S.queue then SpeakOn(now) end
    if S.endAt and now >= S.endAt then LC.EndSpeech() end
end
timer.Create("LivingCitySpeech", 0.5, 0, function() if LC.Running ~= false then LC.SpeechThink(CurTime()) end end)
