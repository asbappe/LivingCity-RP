--[[
    Living City: what the Resistance's people say to you, recordable (the owner, 13 November playtest:
    "[Resistance] 'I'm on watch. Find someone else.' and lines like it: audit them and add them to the
    voice scripts")

    LC.ResistanceLines: every line a fighter, a lookout, the quartermaster or the medic says to a player
    in chat, by id. LC.ResistanceSay(ply, npc, id, before, after) puts it in chat as before ("[Resistance]
    'words'", with the narration around it) and, when the owner has recorded it, plays it from the one
    saying it: garrysmod/sound/livingcity/resistance/<id>_male1.wav or <id>_female1.wav (.mp3 and .ogg
    too; more takes as 2, 3...). Without a recording, the Half-Life 2 sound the caller plays as before.
    Every line: VOICE_LINES.md, section 13 (python3 _dev/voice_lines.py).
]]

if CLIENT then return end

LC = LC or {}

LC.ResistanceVoiceRoot = "livingcity/resistance/"
LC.ResistanceLines = {
    on_watch = "I'm on watch. Find someone else.",
    busy = "I'm busy. Ask someone else.",
    head_back = "Right. I'll head back.",
    not_earned = "Who are you? Get someone who's earned it to ask me.",
    parade = "Any more and you're a parade.",
    meet_there = "We'll meet you there.",
    qm_greet = "What do you need?",
    qm_chip = "Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it.",
    qm_stranger = "I don't know you. But if you've brought something for the fight, I'll take it.",
    medic_hurt = "Hurt? I can patch you up.",
    medic_fine = "You look fine to me. Come back when you're bleeding.",
    medic_charge = "I hate to charge, but these don't grow on trees.",
    medic_broke = "You don't have the credits, friend. Sorry.",
}

local clips -- [id_gender] = { paths }
function LC.ResistanceRescan()
    clips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.ResistanceVoiceRoot .. "*", "GAME") or {}) do
        local base = string.match(string.lower(n), "^(.-)%d*%.[%a%d]+$")
        if base and base ~= "" then
            clips[base] = clips[base] or {}
            table.insert(clips[base], LC.ResistanceVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.ResistanceVoiceRoot .. n) end
        end
    end
end
-- A recording of line id for a man or a woman, or nil.
function LC.ResistanceClip(id, gender)
    if not clips then LC.ResistanceRescan() end
    local list = clips[id .. "_" .. (gender == "female" and "female" or "male")]
    return list and list[math.random(#list)] or nil
end

-- Say line id to ply, from npc. before/after: the narration around it (strings, may be nil).
-- True if a recording played (the caller then skips its Half-Life 2 sound).
function LC.ResistanceSay(ply, npc, id, before, after, prefix)
    local words = LC.ResistanceLines[id]
    if not words then return false end
    if IsValid(ply) then
        ply:ChatPrint((prefix or "[Resistance] ") .. (before and (before .. " ") or "") .. "'" .. words .. "'" .. (after and (" " .. after) or ""))
    end
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    local gender = st and st.gender or (IsValid(npc) and LC.ModelIsFemale and LC.ModelIsFemale(npc:GetModel()) and "female") or "male"
    local clip = LC.ResistanceClip(id, gender)
    if clip and IsValid(npc) then npc:EmitSound(clip, 75) return true end
    return false
end

-- For lc_voice_missing: the lines not recorded yet (both voices).
function LC.ResistanceMissing()
    LC.ResistanceRescan()
    local out = {}
    for id in pairs(LC.ResistanceLines) do
        for _, g in ipairs({ "male", "female" }) do if not LC.ResistanceClip(id, g) then out[#out + 1] = id .. "_" .. g end end
    end
    table.sort(out)
    return out
end

hook.Add("InitPostEntity", "LivingCityResistanceVoice", function() LC.ResistanceRescan() end)
