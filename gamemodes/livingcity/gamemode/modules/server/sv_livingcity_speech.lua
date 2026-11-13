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
      - With nobody playing her, the city's own Administrator gives one a city day (lc_speech_city_hour),
        announced in her own voice (speech_soon), standing at the podium herself. What she says comes from
        the state of the city (LC.SpeechTopicFor): unrest, hunger, low spirits, disorder, or praise when all
        is calm; each is a recording of her own (speech_<topic>1.wav in sound/livingcity/administrator/),
        its words shown either way.
      - Citizens found away from it by a unit (from halfway through the muster to the end): a warning, then
        the stick, again and again until they black out (lc_speech_beatings), and they come to standing in
        the crowd.
      - When she speaks the loyal cheer and salute; Resistance sympathizers salute half-heartedly, a beat
        late, and mutter it flat (LC.CrowdCheer, sv_livingcity_exercise.lua).

    With no crowd point, a speech is as it always was: her words at once, from the stand.

      lc_speech_muster 120, lc_speech_after 45, lc_speech_radius 650, lc_speech_beatings 3, lc_speech_npcs 18,
      lc_speech_city 1, lc_speech_city_hour 12, lc_speech_podium (model)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMuster  = CreateConVar("lc_speech_muster", "120", FLAGS, "Seconds the city has to gather before the Administrator's address begins")
local cvAfter   = CreateConVar("lc_speech_after", "45", FLAGS, "Seconds the crowd stays after she has spoken")
local cvRadius  = CreateConVar("lc_speech_radius", "650", FLAGS, "How close to the speech crowd point counts as being at the address")
local cvBeats   = CreateConVar("lc_speech_beatings", "3", FLAGS, "Blows with the stick before someone who skipped the address blacks out (and comes to in the crowd)")
local cvNPCs    = CreateConVar("lc_speech_npcs", "18", FLAGS, "How many of the city's own citizens gather for an address")
local cvCity    = CreateConVar("lc_speech_city", "1", FLAGS, "With nobody playing the Administrator, the city's own Administrator gives an address once a city day")
local cvCityHr  = CreateConVar("lc_speech_city_hour", "12", FLAGS, "The city hour the city's own Administrator gives her daily address")
local cvPodium  = CreateConVar("lc_speech_podium", "models/props_combine/breenconsole.mdl", FLAGS, "The podium put in front of the speech stand for an address")

local S -- the address under way, or nil
function LC.SpeechSession() return S end

-- Her speeches with nobody playing her, by what the city needs to hear (the owner: lines for her speeches,
-- to record). id: the recording's name (speech_<id>1.wav, in her usual tone); when: chosen when.
LC.SpeechTopics = {
    { id = "unrest", when = "The Resistance is strong", tier = 3,
      words = "Citizens. There are those among you who whisper of freedom, and mean only chaos. They hide behind your doors and eat from your rations. Every one of them you shelter is a debt your whole block will pay. Point them out, and be thanked. Stay silent, and be counted with them." },
    { id = "hunger", when = "Supply is low", tier = 1,
      words = "My dear citizens. I know the rations have been thin. I feel every empty bowl in this city as if it were my own. But the Union provides for those who provide for the Union. Work your shifts, keep your quotas, and the trains will come. Patience is a form of loyalty." },
    { id = "morale", when = "Morale is low", tier = 1,
      words = "Chins up, my children! I see tired faces, and I understand. But look around you: the lights are on, the streets are swept, and not one of you is alone. We are building something here, together, that will outlast every one of us. Be proud of it. I am proud of you." },
    { id = "order", when = "Her authority is low", tier = 2,
      words = "Let me be clear, so that no one can say they were not told. My patience is not endless. The rules of this city are not suggestions. Civil Protection acts with my full authority, and my authority is not in question. Remember that, when you are tempted to forget it." },
    { id = "calm", when = "All is well", tier = 1,
      words = "Citizens! Another day of peace, of order, of honest work. You have made this city a model for every other. The Union sees it. I see it. Go back to your work with my gratitude, and know that as long as you keep faith with me, I will always keep faith with you." },
}
-- What she talks about today: whatever the city most needs to hear.
function LC.SpeechTopicFor(state)
    state = state or (LC.Ledger and LC.Ledger()) or {}
    local function T(id) for _, t in ipairs(LC.SpeechTopics) do if t.id == id then return t end end end
    if (state.resistance or 50) >= 65 then return T("unrest") end
    if (state.supply or 50) <= 30 then return T("hunger") end
    if (state.authority or 50) <= 35 then return T("order") end
    if (state.morale or 50) <= 35 then return T("morale") end
    return T("calm")
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
        local topic = LC.SpeechTopicFor()
        S.topic = topic
        S.text = topic and topic.words or "Citizens. The Union thanks you."
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
    if LC.CustomAnnounce then pcall(LC.CustomAnnounce, voice, "speech_soon", nil, true) end
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
    local path
    if S.topic and LC.PickAnnounceClip then
        local p, txt = LC.PickAnnounceClip("administrator", "speech_" .. S.topic.id, false, S.topic.tier)
        if p then path = p if txt then S.text = txt end end
    end
    if path and IsValid(S.her) then S.her:EmitSound(path, 100, 100) end
    if LC.SpeechDeliver then LC.SpeechDeliver(by, S.text, S.crowd.pos) end
    if LC.SpeechCrowd then LC.SpeechCrowd(S.crowd.pos, cvRadius:GetFloat() + 150) end
    S.endAt = CurTime() + cvAfter:GetFloat()
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
    if S.endAt and now >= S.endAt then LC.EndSpeech() end
end
timer.Create("LivingCitySpeech", 0.5, 0, function() if LC.Running ~= false then LC.SpeechThink(CurTime()) end end)
