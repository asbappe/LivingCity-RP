--[[
    Living City: the Colonel

    A weary old fighter at the Resistance camp, by the quartermaster (Odessa
    Cubbage's face), who knows things nobody should (the owner, 10 November).
    Only the Resistance can see him. Nobody else ever has: he isn't there.
    He died when the Combine burned the first camp, and the cell still sees
    him (the owner: "unless he is client-side for a player and actually just
    a hallucination, which is actually an awesome story idea"). He's drawn on
    each Resistance player's own screen and nowhere else, so he can't be
    shot, can't be arrested, and is simply gone whenever the Combine are in
    the camp, back when they've left. Anyone else near someone talking to
    him sees them talking quietly to an empty corner.

    E on him (cl_livingcity_colonel.lua asks; the window: sv_livingcity_dialog.lua):

      What's the word?      live intel, marked: a sweep coming into rebel
                            ground, a prisoner being marched to the cells, a
                            supply drop, or a sympathizer close by (a lookout
                            waiting to be asked). Quiet days, he says so.
      His jobs              unmarked, like the old-timer's: what he needs slips
                            out at the end of his greeting. Medicine for the
                            wounded (three Union medicine); his brother's tags,
                            taken into Combine ground (dog tags lie somewhere
                            in a Combine-only zone, the prison or by the
                            Combine's Commissary); then the unit who burned the
                            first camp (a named Civil Protection unit: his
                            designation, nothing more). Each pays (XP, the
                            brother's revolver), and each lets him tell you
                            more, until he tells you what he is.
      Debrief me            after a Resistance job: clean (no warrant, nobody
                            down, nobody taken) is lc_colonel_debrief_xp (25)
                            XP and a nod; messy or failed, a dressing-down.
      Heard anything strange?  once you've done him a favour: whispers that
                            point, crooked, at the city's secret endings
                            (the ways the city itself can set them off,
                            sv_livingcity_directives.lua).

    Recordings, if you make them: garrysmod/sound/livingcity/colonel/,
    named for the line (greet1.wav, whisper_base1.wav). Every line:
    VOICE_LINES.md section 9 (LC.ColonelLines). Only the player he's talking
    to hears them. Without one, nothing: he's in your head.

    Setting: lc_colonel (1; 0 and he's gone).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_colonel_use")
util.AddNetworkString("lc_colonel_say")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_colonel", "1", FLAGS, "The Colonel: an old fighter at the Resistance camp only the Resistance can see (intel, jobs, debriefs, whispers)")
local cvDebrief = CreateConVar("lc_colonel_debrief_xp", "25", FLAGS, "XP the Colonel gives for a clean Resistance job when you debrief with him")

local REACH = 170
local DEBRIEF_WINDOW = 2700
LC.ColonelVoiceRoot = "livingcity/colonel/"

LC.ColonelLines = {
    greet = "Another one. Sit, if you like. Nobody else does.",
    greet_back = "You came back. Most don't.",
    greet_trust = "The quartermaster won't look at me, you know. Hasn't for years. Sit.",
    greet_known = "You've worked it out by now, haven't you. Nobody else can see me. I didn't get out of the first camp. None of us did, not really. But you keep coming, so I keep telling you what I know.",
    job_medicine = "Our wounded are in a bad way. Three of the Union's medicines would see them through.",
    thanks_medicine = "That'll keep them breathing. Good. You think of others. That's rarer than courage.",
    job_tags = "They took my brother's tags when they took him. They keep things like that on their own ground. I'd like them back.",
    thanks_tags = "His. His name, scratched in by hand. Here. He'd want you to have this. It never missed for him.",
    job_unit = "One more thing. The unit who lit the first camp. Designation %s. Still walking around.",
    job_unit_none = "There's a unit I'd like to see in the ground. When he's back on the streets, I'll tell you his number.",
    thanks_unit = "Is it done? ...It is. I can feel it. Thank you. I don't think I'll need anything else.",
    intel_sweep = "They're coming into our ground. Now. Clear what you can carry and go.",
    intel_march = "They're walking one of ours to the cells. Right now. You can still get to them.",
    intel_supply = "Supply drop coming in. Guarded, but not well. Go.",
    intel_sympathizer = "That one. They're with us, they just don't know it yet. Ask them to keep watch.",
    intel_quiet = "Quiet. Too quiet. Rest while you can.",
    debrief_clean = "Clean. Nobody saw you, nobody followed you home. That's how it's done.",
    debrief_messy = "You got it done, and half the city knows your face. Next time, slower.",
    debrief_failed = "We lost that one. Learn why before you try again.",
    debrief_none = "Nothing to report? Then go and do something worth reporting.",
    nothing = "That's not what I need.",
    whisper_harpies = "When the streets run red fast enough, a dozen dead in a few minutes, something comes down out of the sky. Something with wings.",
    whisper_plane = "Do the morning drill, five of you or more, and do it perfectly. Not one mistake. Then look up.",
    whisper_hard = "Kill the city's lights and keep them dead for a quarter of an hour. Somebody starts a party in the dark, and nobody can stop it.",
    whisper_shalom = "Six people dancing in a ring, in this city. Imagine it. They say the whole city joins in.",
    whisper_fire = "Set fifteen fires burning at once. Then watch what the city does.",
    whisper_base = "The master core, the big one from their nexus. Get it to our scientist and let him crack it open. All their screens change.",
    whisper_marrow = "When the dead pile up faster than they can be carried off, or the infested hold half the city, the bones get restless.",
    whisper_bloom = "Let the weeds take the streets, every crack full, and leave them be. The city starts to dance.",
    whisper_water = "There's a priest who'd swallow anything holy. Feed him the master core and pray for rain. A lot of rain.",
    whisper_standup = "Keep the city red for three quarters of an hour straight. The crowd starts wanting a show.",
    whisper_none = "Nothing you haven't heard from me already.",
}
local WHISPERS = { "harpies", "plane", "hard", "shalom", "fire", "base", "marrow", "bloom", "water", "standup" }
local JOBS = { "medicine", "tags", "unit" }

------------------------------------------------------------------------
-- Where he is (by the quartermaster, or in the middle of rebel ground), and whether he's "there"
------------------------------------------------------------------------

local function Quartermaster()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.quartermaster and npc:Health() > 0 then return npc end
    end
end

function LC.ColonelSpot()
    local qm = Quartermaster()
    if IsValid(qm) then
        local pos = qm:GetPos() + qm:GetRight() * 80
        return pos, qm:GetAngles().y
    end
    for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("rebel") or {}) do
        local c = z.box and ((z.box.mins + z.box.maxs) * 0.5) or z.pos
        if c then return Vector(c.x, c.y, (z.box and z.box.mins.z) or c.z), 0 end
    end
end

-- The Combine in the camp: he's gone till they leave.
local function CombineNear(pos)
    local sk = LC.Skirmish
    if sk and sk.kind == "sweep" and sk.zone and LCZ and LCZ.Near and LCZ.Near(sk.zone, pos, 300) then return true end
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p) and p:GetPos():DistToSqr(pos) < 600 * 600 then return true end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and (st.role == "cop" or st.role == "soldier") and npc:GetPos():DistToSqr(pos) < 600 * 600 then return true end
    end
    return false
end

function LC.ColonelTick()
    local pos, yaw = nil, 0
    if cvOn:GetBool() then pos, yaw = LC.ColonelSpot() end
    local here = pos ~= nil and not CombineNear(pos)
    SetGlobal2Bool("lc_colonel_here", here)
    if pos then
        SetGlobal2Vector("lc_colonel_pos", pos)
        SetGlobal2Float("lc_colonel_yaw", yaw or 0)
    end
    LC.ColonelHere, LC.ColonelPos = here, pos
    return here
end
timer.Create("LivingCityColonel", 2, 0, function() LC.ColonelTick() end)

------------------------------------------------------------------------
-- What he remembers about you (this character)
------------------------------------------------------------------------

local function Key(ply) return "lc_colonel_" .. string.gsub(ply:GetNW2String("lc_char", ""), "[^%w]", "") end
local function Mem(ply)
    if not ply.lcColonel or ply.lcColonelKey ~= Key(ply) then
        ply.lcColonelKey = Key(ply)
        ply.lcColonel = util.JSONToTable(ply:GetPData(ply.lcColonelKey, "") or "") or {}
        ply.lcColonel.done = ply.lcColonel.done or {}
    end
    return ply.lcColonel
end
local function Save(ply) ply:SetPData(Key(ply), util.TableToJSON(Mem(ply))) end
LC.ColonelMem = Mem

function LC.ColonelJob(ply)
    local m = Mem(ply)
    for _, j in ipairs(JOBS) do if not m.done[j] then return j end end
end

------------------------------------------------------------------------
-- The jobs' world: the brother's tags, the unit
------------------------------------------------------------------------

local function TagsSpot()
    local function Center(z) return z.box and ((z.box.mins + z.box.maxs) * 0.5) or z.pos end
    local zs = LC.ZonesOfKindShared and LC.ZonesOfKindShared("combine") or {}
    if #zs == 0 then zs = LC.ZonesOfKindShared and LC.ZonesOfKindShared("prison") or {} end
    if #zs > 0 then
        local z = zs[math.random(#zs)]
        local c = Center(z)
        if c then return Vector(c.x, c.y, (z.box and z.box.mins.z or c.z) + 8) end
    end
    local e = LC.NearestEntOf and LC.NearestEntOf(Vector(0, 0, 0), { "lc_cpsupply" })
    if IsValid(e) then return e:GetPos() + e:GetForward() * 40 + Vector(0, 0, 8) end
end

function LC.ColonelEnsureTags()
    if IsValid(LC.ColonelTagsEnt) then return LC.ColonelTagsEnt end
    if (LC.ColonelTagsNext or 0) > CurTime() then return nil end
    local pos = TagsSpot()
    if not pos or not LC.SpawnWorldItem then return nil end
    LC.ColonelTagsEnt = LC.SpawnWorldItem("dog_tags", pos)
    LC.ColonelTagsNext = CurTime() + 600
    return LC.ColonelTagsEnt
end

local function UnitByPid(pid)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and npc.lcProfile and npc.lcProfile.id == pid and npc:Health() > 0 then return npc end
    end
end

-- The unit he wants dead, for this player (picked once, kept while he lives).
function LC.ColonelUnit(ply)
    local m = Mem(ply)
    local npc = m.unit and UnitByPid(m.unit)
    if IsValid(npc) then return npc end
    local cops = {}
    for n, st in pairs(LC.NPCs or {}) do
        if IsValid(n) and st.role == "cop" and n.lcProfile and n:Health() > 0 and not st.test then cops[#cops + 1] = n end
    end
    if #cops == 0 then return nil end
    npc = cops[math.random(#cops)]
    m.unit = npc.lcProfile.id
    Save(ply)
    return npc
end

hook.Add("OnNPCKilled", "LivingCityColonel", function(npc, attacker)
    if not IsValid(npc) or not npc.lcProfile or not IsValid(attacker) or not attacker:IsPlayer() then return end
    local m = Mem(attacker)
    if LC.ColonelJob(attacker) == "unit" and m.unit == npc.lcProfile.id then
        m.unitDead = true
        Save(attacker)
        attacker:ChatPrint("Somewhere at the camp, an old man lets out a breath he's been holding for years.")
    end
end)

------------------------------------------------------------------------
-- Talking to him
------------------------------------------------------------------------

local function Say(ply, id)
    local clip
    local list = file.Find("sound/" .. LC.ColonelVoiceRoot .. id .. "*", "GAME") or {}
    for _, n in ipairs(list) do
        local ext = string.lower(string.match(n, "%.(%w+)$") or "")
        if ext == "wav" or ext == "mp3" or ext == "ogg" then clip = LC.ColonelVoiceRoot .. n break end
    end
    if not clip then return end
    net.Start("lc_colonel_say") net.WriteString(clip) net.Send(ply)
end

local function CanTalk(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if ply:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    if not LC.ColonelHere or not LC.ColonelPos then LC.ColonelTick() end
    return LC.ColonelHere and LC.ColonelPos and ply:GetPos():DistToSqr(LC.ColonelPos) < REACH * REACH
end
LC.ColonelCanTalk = CanTalk

local function JobLine(ply)
    local j = LC.ColonelJob(ply)
    if j == "unit" then
        local u = LC.ColonelUnit(ply)
        if IsValid(u) then return string.format(LC.ColonelLines.job_unit, LC.NPCStr and LC.NPCStr(u, "lc_pname", "unknown") or "unknown") end
        return LC.ColonelLines.job_unit_none
    end
    if j == "tags" then LC.ColonelEnsureTags() end
    return j and LC.ColonelLines["job_" .. j] or nil
end

local function Menu(ply, said)
    local m = Mem(ply)
    local opts = { { "intel", "What's the word?" }, { "give", "Give him something from your pockets" } }
    if ply.lcOpReport then opts[#opts + 1] = { "debrief", "Debrief me" } end
    if m.done.medicine then opts[#opts + 1] = { "whisper", "Heard anything strange?" } end
    LC.OpenDialog(ply, "colonel", nil, { title = "The Colonel",
        sub = "A grey-haired fighter in an old coat, standing by the quartermaster. Nobody else looks at him.", text = said, options = opts })
end

local function Greeting(ply)
    local m = Mem(ply)
    if m.done.unit then return "greet_known" end
    if m.done.tags then return "greet_trust" end
    if m.done.medicine then return "greet_back" end
    return "greet"
end

function LC.OpenColonel(ply)
    if not CanTalk(ply) or not LC.OpenDialog then return false end
    local g = Greeting(ply)
    Say(ply, g)
    local job = JobLine(ply)
    Menu(ply, LC.ColonelLines[g] .. (job and ("\n\n" .. job) or ""))
    -- anyone else near sees someone talking to nobody
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:GetNW2String("lcf_faction", "") ~= "resistance" and p:GetPos():DistToSqr(ply:GetPos()) < 400 * 400 then
            p:ChatPrint("* " .. (LC.NameFor and LC.NameFor(p, ply) or "Someone") .. " is talking quietly to an empty corner.")
        end
    end
    hook.Run("LivingCityColonel", ply)
    return true
end

net.Receive("lc_colonel_use", function(_, ply)
    if (ply.lcColonelNext or 0) > CurTime() then return end
    ply.lcColonelNext = CurTime() + 0.5
    LC.OpenColonel(ply)
end)

-- Live intel: the first of these that's true right now, marked.
function LC.ColonelIntel(ply)
    local sk = LC.Skirmish
    if sk and sk.kind == "sweep" and sk.zone then
        local z = sk.zone
        return "intel_sweep", z.box and ((z.box.mins + z.box.maxs) * 0.5) or z.pos, "Where they're sweeping"
    end
    for prisoner, mm in pairs(LC.Marching or {}) do
        if IsValid(prisoner) then return "intel_march", prisoner:GetPos(), "The prisoner march" end
    end
    local s = LC.Supply
    if s and s.pos then return "intel_supply", s.pos, "The supply drop" end
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and st.rebel and not st.test then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < 3000 * 3000 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    if IsValid(best) then return "intel_sympathizer", best:GetPos(), "A sympathizer" end
    return "intel_quiet"
end

LC.DialogHandlers.colonel = function(ply, _, id)
    if not CanTalk(ply) then return nil end
    local m = Mem(ply)
    if id == "intel" then
        local line, pos, label = LC.ColonelIntel(ply)
        if pos and LC.GuideTo then LC.GuideTo(ply, pos, label) end
        Say(ply, line)
        Menu(ply, LC.ColonelLines[line])
        return line
    end
    if id == "give" then
        local j = LC.ColonelJob(ply)
        local ok = false
        if j == "medicine" and LC.HasItem(ply, "medicine", 3) then ok = LC.TakeItem(ply, "medicine", 3)
        elseif j == "tags" and LC.HasItem(ply, "dog_tags") then ok = LC.TakeItem(ply, "dog_tags", 1)
        elseif j == "unit" and m.unitDead then ok = true end
        if not ok then Say(ply, "nothing") Menu(ply, LC.ColonelLines.nothing .. (j and ("\n\n" .. (JobLine(ply) or "")) or "")) return "nothing" end
        m.done[j] = true
        Save(ply)
        if j == "medicine" and LC.AddXP then LC.AddXP(ply, 40, "the Colonel's wounded") end
        if j == "tags" then
            if LC.AddXP then LC.AddXP(ply, 60, "the Colonel's brother") end
            ply:Give("weapon_357")
            ply:GiveAmmo(12, "357", true)
        end
        if j == "unit" and LC.AddXP then LC.AddXP(ply, 75, "the first camp, avenged") end
        Say(ply, "thanks_" .. j)
        local nxt = JobLine(ply)
        Menu(ply, LC.ColonelLines["thanks_" .. j] .. (nxt and ("\n\n" .. nxt) or ""))
        hook.Run("LivingCityColonelJob", ply, j)
        return "done_" .. j
    end
    if id == "debrief" then
        local r = ply.lcOpReport
        ply.lcOpReport = nil
        local line = "debrief_none"
        if r and CurTime() - r.t < DEBRIEF_WINDOW then
            line = (not r.ok and "debrief_failed") or (r.messy and "debrief_messy") or "debrief_clean"
            if line == "debrief_clean" and LC.AddXP and cvDebrief:GetInt() > 0 then LC.AddXP(ply, cvDebrief:GetInt(), "a clean job, debriefed") end
        end
        Say(ply, line)
        Menu(ply, LC.ColonelLines[line] .. (r and r.title and ("\n\n(" .. r.title .. ")") or ""))
        return line
    end
    if id == "whisper" then
        if not m.done.medicine then return nil end
        ply.lcColonelHeard = ply.lcColonelHeard or {}
        local left = {}
        for _, w in ipairs(WHISPERS) do if not ply.lcColonelHeard[w] then left[#left + 1] = w end end
        local line = "whisper_none"
        if #left > 0 then
            local w = left[math.random(#left)]
            ply.lcColonelHeard[w] = true
            line = "whisper_" .. w
        end
        Say(ply, line)
        Menu(ply, LC.ColonelLines[line])
        return line
    end
end

------------------------------------------------------------------------
-- Debriefs: how a Resistance job went
------------------------------------------------------------------------

local function Resistance(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end
hook.Add("LivingCityQuestAccepted", "LivingCityColonel", function(ply, q)
    if Resistance(ply) then ply.lcOpTrack = { title = q and q.title, messy = false } end
end)
local function Messy(ply) if IsValid(ply) and ply.lcOpTrack then ply.lcOpTrack.messy = true end end
hook.Add("LivingCityWanted", "LivingCityColonel", function(ply) Messy(ply) end)
hook.Add("LivingCityDowned", "LivingCityColonel", function(ply) Messy(ply) end)
hook.Add("LivingCityIncarcerated", "LivingCityColonel", function(ply) if IsValid(ply) and ply:IsPlayer() then Messy(ply) end end)
local function Report(ply, q, ok)
    if not Resistance(ply) then return end
    local tr = ply.lcOpTrack
    ply.lcOpTrack = nil
    ply.lcOpReport = { title = (q and q.title) or (tr and tr.title), ok = ok, messy = tr and tr.messy or false, t = CurTime() }
end
hook.Add("LivingCityQuestComplete", "LivingCityColonel", function(ply, q) Report(ply, q, true) end)
hook.Add("LivingCityQuestFailed", "LivingCityColonel", function(ply, q) Report(ply, q, false) end)
