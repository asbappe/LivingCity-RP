--[[
    Living City: utility boxes at the loudspeakers, and the Resistance's hackers on the PA

    The owner, 13 November: "Resistance hackers take over the loudspeakers. A Resistance hacker walks up
    to one of the city's loudspeakers and hacks it; the Resistance leader's next speech then plays over
    every hacked loudspeaker"; and "a utility box at every loudspeaker: a small box at hip height by each
    loudspeaker point, a black cable from it to the loudspeaker: what a hacker targets and what a repair
    technician fixes."

      - Every loudspeaker gets a utility box below it by itself (entities/lc_utilitybox.lua), on the
        ground under the speaker, at hip height, with a black cable up to it. Nothing to place.
      - A Hacker (the Resistance's Hacker role) presses E on the box: LC.SpeakerHackTask seconds
        (8) of splicing, and the loudspeaker is the Resistance's for LC.SpeakerHackSecs (20 minutes).
      - Colonel Cubbage's answer to her address (sv_livingcity_speechanswer.lua) then also plays from
        every hacked loudspeaker: his recording from the speaker, his words to everyone near it.
      - Civil Protection or Overwatch press E on a hacked box to cut the splice out (5 seconds), for
        a little XP; a hacked box sparks now and then, so it can be found.
      - The radio repair crew (the Radio Repair job) mends a broken loudspeaker from its box (6 seconds).

      lc_speaker_boxes 0/1 (1): the boxes (and with them the hacking)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_speaker_boxes", "1", FLAGS, "A utility box under every loudspeaker: Resistance Hackers splice into the PA there, units cut them out, the repair crew mends speakers")

LC.SpeakerHackTask, LC.SpeakerHackSecs, LC.SpeakerCutTask, LC.SpeakerMendTask = 8, 1200, 5, 6
LC.SpeakerHearRadius = 900

function LC.SpeakerHacked(sp)
    return IsValid(sp) and sp:GetNW2Float("lc_hacked_until", 0) > CurTime()
end
function LC.HackedSpeakers()
    local out = {}
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_loudspeaker") or ents.FindByClass("lc_loudspeaker")) do
        if LC.SpeakerHacked(e) and not e:GetNW2Bool("lc_broken", false) then out[#out + 1] = e end
    end
    return out
end

-- Where the box goes: straight down from the speaker to the floor, a little out from what it hangs
-- on, at hip height. nil if there's no floor under it within reach.
function LC.UtilityBoxSpot(sp)
    local top = sp:GetPos()
    local out = sp:GetForward() * 14
    local tr = util.TraceLine({ start = top + out, endpos = top + out - Vector(0, 0, 900), filter = sp, mask = MASK_SOLID_BRUSHONLY or MASK_SOLID })
    if not tr.Hit or tr.StartSolid then return nil end
    return tr.HitPos + Vector(0, 0, 36), Angle(0, sp:GetAngles().y, 0)
end

function LC.EnsureUtilityBoxes()
    if not cvOn:GetBool() then return 0 end
    local made = 0
    for _, sp in ipairs(LC.EntsOf and LC.EntsOf("lc_loudspeaker") or ents.FindByClass("lc_loudspeaker")) do
        if IsValid(sp) and not IsValid(sp.lcBox) then
            local pos, ang = LC.UtilityBoxSpot(sp)
            if pos then
                local box = ents.Create("lc_utilitybox")
                if IsValid(box) then
                    box:SetPos(pos)
                    box:SetAngles(ang)
                    box:Spawn()
                    box:SetNW2Entity("lc_speaker", sp)
                    box.lcSpeaker = sp
                    sp.lcBox = box
                    sp:CallOnRemove("lc_utilitybox", function(e) if IsValid(e.lcBox) then e.lcBox:Remove() end end)
                    made = made + 1
                end
            end
        end
    end
    return made
end

local function Special(ply) return ply:GetNW2String("lcf_special", "") end

-- E on a box. True if something was started.
function LC.UseUtilityBox(ply, box)
    if not IsValid(ply) or not ply:Alive() or not IsValid(box) then return false end
    local sp = box.lcSpeaker or box:GetNW2Entity("lc_speaker")
    if not IsValid(sp) then return false end
    local hacked = LC.SpeakerHacked(sp)
    local broken = sp:GetNW2Bool("lc_broken", false)
    local function Busy(secs, text, done)
        local ok, why = LC.StartTask(ply, secs, text, { maxMove = 60, done = done })
        if not ok and why then ply:ChatPrint(why) end
        return ok
    end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then
        if not hacked then
            ply:ChatPrint(broken and "[Utility box] The loudspeaker's dead. The radio repair crew will see to it." or "[Utility box] Sealed and humming. Nothing's been tampered with.")
            return false
        end
        return Busy(LC.SpeakerCutTask, "Cutting the spliced line out...", function(p)
            if not IsValid(sp) then return end
            sp:SetNW2Float("lc_hacked_until", 0)
            box:EmitSound("buttons/combine_button5.wav", 60)
            if LC.Notice then LC.Notice(p, "info", "Splice cut out", "The loudspeaker is the city's again.", 5) end
            if LC.AddXP then pcall(LC.AddXP, p, 2, "cut a Resistance splice out of a loudspeaker") end
            hook.Run("LivingCitySpeakerCut", p, sp)
        end)
    end
    if Special(ply) == "hacker" and ply:GetNW2String("lcf_faction", "") == "resistance" then
        if broken then ply:ChatPrint("[Utility box] The loudspeaker's dead: nothing to splice into.") return false end
        if hacked then
            ply:ChatPrint(string.format("[Utility box] Already ours, for about %d more minutes.", math.ceil((sp:GetNW2Float("lc_hacked_until", 0) - CurTime()) / 60)))
            return false
        end
        return Busy(LC.SpeakerHackTask, "Splicing into the loudspeaker's line...", function(p)
            if not IsValid(sp) then return end
            sp:SetNW2Float("lc_hacked_until", CurTime() + LC.SpeakerHackSecs)
            box:EmitSound("buttons/button19.wav", 55)
            if LC.Notice then LC.Notice(p, "info", "The loudspeaker is ours", "When the Colonel next answers her, he'll be heard from here too.", 7) end
            hook.Run("LivingCitySpeakerHacked", p, sp)
        end)
    end
    local job = LC.Job and LC.Job(ply)
    if broken and job and job.id == "radio" then
        return Busy(LC.SpeakerMendTask, "Mending the loudspeaker from its box...", function()
            if IsValid(sp) and LC.RepairStreetFixture then LC.RepairStreetFixture(sp) end
        end)
    end
    ply:ChatPrint(broken and "[Utility box] The loudspeaker's dead. That's the radio repair crew's work." or "[Utility box] A Union utility box, padlocked. It hums.")
    return false
end

-- His line from every hacked loudspeaker too (called from sv_livingcity_speechanswer.lua's Say).
-- clip: his recording, or nil; heard: players who already heard it (skipped). Returns who heard it.
function LC.SpeakerHackSay(clip, words, heard)
    local out = {}
    heard = heard or {}
    local r = LC.SpeakerHearRadius
    for _, sp in ipairs(LC.HackedSpeakers()) do
        if clip then sp:EmitSound(clip, 95, 100) end
        for _, p in ipairs(player.GetAll()) do
            if not heard[p] and p:GetPos():DistToSqr(sp:GetPos()) <= r * r then
                heard[p] = true
                out[#out + 1] = p
                p:ChatPrint("[Loudspeaker] Colonel Cubbage: " .. words)
            end
        end
    end
    return out
end

-- a hacked box sparks now and then (how a unit finds one)
timer.Create("LivingCitySpeakerHackSparks", 6, 0, function()
    if not cvOn:GetBool() then return end
    for _, sp in ipairs(LC.HackedSpeakers()) do
        local box = sp.lcBox
        if IsValid(box) and math.random() < 0.5 then
            local ed = EffectData and EffectData()
            if ed then
                ed:SetOrigin(box:GetPos() + box:GetUp() * 8)
                ed:SetMagnitude(1) ed:SetScale(1) ed:SetRadius(2)
                if util.Effect then util.Effect("Sparks", ed) end
            end
            box:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 55, 110, 0.5)
        end
    end
end)
timer.Create("LivingCityUtilityBoxes", 15, 0, function()
    local ok, err = pcall(LC.EnsureUtilityBoxes)
    if not ok and LC.Error then LC.Error("utility boxes", err) end
end)
