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
local cvNPCs    = CreateConVar("lc_speech_npcs", "18", FLAGS, "How many of the city's own citizens gather for an address")
local cvCity    = CreateConVar("lc_speech_city", "1", FLAGS, "With nobody playing the Administrator, the city's own Administrator gives an address on the days with no morning exercise")
local cvLook    = CreateConVar("lc_speech_lookback", "240", FLAGS, "Minutes of the chronicle the city's own Administrator looks back over for her address")
local cvCityHr  = CreateConVar("lc_speech_city_hour", "12", FLAGS, "The city hour the city's own Administrator gives her address")
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
function LC.SpeechCompose(state, events, mood)
    state = state or {}
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

-- The i-th place in the crowd: rows of six facing the stand.
function LC.SpeechSpot(i)
    if not S then return nil end
    local c, st = S.crowd.pos, S.stand.pos
    local toward = st - c
    toward.z = 0
    if toward:LengthSqr() < 1 then toward = Vector(1, 0, 0) end
    toward:Normalize()
    local side = Vector(-toward.y, toward.x, 0)
    local row, col = math.floor((i - 1) / 6), (i - 1) % 6
    local pos = c + side * ((col - 2.5) * 56) - toward * (row * 60)
    pos = (LC.GroundAt and LC.GroundAt(pos + Vector(0, 0, 30))) or pos
    return pos, math.deg(math.atan2(toward.y, toward.x))
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

-- The city's own citizens walk to the crowd.
local function Gather()
    local n, got = cvNPCs:GetInt(), 0
    S.npcs = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if got >= n then break end
        if IsValid(npc) and st.role == "citizen" and (st.state == "idle" or st.state == "moving") and not st.unmanaged and not st.questLock
            and not st.test and not st.leaving and not st.line and not st.npcWork and not st.carry and not st.exCitizen then
            local pos, yaw = LC.SpeechSpot(got + 1)
            if pos and LC.GoTo and LC.GoTo(npc, st, pos, false, { kind = "speech", pos = pos, yaw = yaw }) then
                st.speechYaw = yaw
                S.npcs[npc] = true
                got = got + 1
            end
        end
    end
    S.spots = got
    return got
end
-- One of them at their place: they stand and face the stand (sv_livingcity.lua's Arrive hands them over).
function LC.SpeechArrive(npc, st, now)
    if not (S and S.npcs[npc]) then st.untilT = now + 2 return end
    LC.SetState(npc, st, "event")
    st.eventUntil = now + 900
    if st.speechYaw and LC.FaceYaw then LC.FaceYaw(npc, st.speechYaw) end
end

local function Tell(p, title, text, secs)
    if LC.Notice then LC.Notice(p, "warn", title, text, secs or 10) else p:ChatPrint("[" .. title .. "] " .. text) end
end

-- Call the city to an address. by: the player Administrator (nil: the city's own). text: her words (a
-- player's), or nil (the city's own picks a topic). Returns true, or false and why.
function LC.CallSpeech(by, text)
    if S then return false, "The city is already gathering for an address." end
    local stand, crowd = LC.SpeechPlaces(IsValid(by) and by:GetPos() or nil)
    if not stand then return false, "There's no speech crowd point in this city. (Staff: Miscount Editor > Point: speech crowd.)" end
    local now = CurTime()
    S = { by = IsValid(by) and by or nil, text = text, stand = stand, crowd = crowd, startT = now,
          speakAt = now + cvMuster:GetFloat(), npcs = {}, beaten = {}, warned = {} }
    if not S.by then
        local pieces, tense = LC.SpeechCompose(LC.Ledger and LC.Ledger() or {}, LC.SpeechEvents(os.time() - cvLook:GetFloat() * 60), LC.SpeechMood())
        S.pieces, S.tense = pieces, tense
        local words = {}
        for _, p in ipairs(pieces) do words[#words + 1] = p.words end
        S.text = table.concat(words, " ")
    end
    Dress()
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
    if now >= S.startT + cvMuster:GetFloat() * 0.5 then Hunt(now) end
    if not S.spoken and now >= S.speakAt then Speak() end
    if S and S.queue then SpeakOn(now) end
    if S.endAt and now >= S.endAt then LC.EndSpeech() end
end
timer.Create("LivingCitySpeech", 0.5, 0, function() if LC.Running ~= false then LC.SpeechThink(CurTime()) end end)
