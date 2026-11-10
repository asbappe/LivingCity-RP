--[[
    Living City: Citizen Information

    A clerk behind a counter (editor: "Fixture: Citizen Information desk",
    entities/lc_infoclerk.lua) who answers questions on the city's rules: the
    official version, in a flat, tired voice (the owner, 10 November: "an NPC
    that is city helpdesk or Citizen Information ... behind a counter that
    answers questions on topics"). Never a word about bins, the black market
    or the Resistance: for that, find the old-timer (sv_livingcity_oldtimer.lua).

    Press E: a window of topics. Each answer is also learning it: the tip
    cards for that topic don't come (LC.Learn, sv_livingcity_learning.lua).
    "Where is...?" marks the way to an official place (Civil Intake, Housing
    Allocation, Labor Assignment, the Commissary, the ration dispenser, your
    block): the marker and the trail on the ground, from what's on this map.
    Your Civil Standing sets the clerk's manner: polite at 50 and up, curt
    below zero. Someone wanted is told to stay where they are, nothing more.

    Recordings, if you make them: garrysmod/sound/livingcity/clerk/, named
    for the line (rations1.wav, greet_curt1.wav). Every line: VOICE_LINES.md
    section 6 (LC.InfoDeskLines below). Without one, a terminal's chime.

    Setting: lc_infodesk (1; 0 and the clerk only shrugs).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvDesk = CreateConVar("lc_infodesk", "1", FLAGS, "The Citizen Information clerk answers questions (0: they only shrug)")

LC.InfoDeskVoiceRoot = "livingcity/clerk/"

-- id = { button, words, tips it teaches }
LC.InfoDeskTopics = {
    { "rations", "Rations and ration cards",
      "Rations are issued at the ration dispenser. Each ration requires one ration card. Ration cards are issued on completion of a Union shift: one card per shift. No shift, no card. No card, no ration. Your first allocation after arrival is guaranteed.",
      { "dispenser", "ration", "event_rations", "item_papers" } },
    { "work", "Work",
      "All residents are assigned labor. Report to Labor Assignment for your assignment. Shifts pay credits and Civil Standing, and each completed shift earns one ration card. Your shifts are listed on your work board.",
      { "workbench" } },
    { "housing", "Housing",
      "Housing Allocation assigns rooms to registered residents with a work assignment. Your room is in your housing block. Sleep there, keep your possessions there, and be there at curfew.",
      { "intake_housing", "home_block", "apartment" } },
    { "papers", "Papers and registration",
      "Every resident is registered at Civil Intake and carries identity papers at all times. Present them to any Civil Protection unit on request. Lost papers are replaced at Civil Intake, for a fee.",
      { "intake_arrival", "item_papers" } },
    { "law", "The law",
      "The city's laws are posted on the law board. Ignorance of the law is not a defence. Comply with Civil Protection. Do not run in their presence. Report anticivil activity.",
      { "lawboard", "running", "stopped" } },
    { "curfew", "Curfew",
      "Curfew is announced two minutes in advance. When it begins, return to your housing block and remain there until morning. Residents found outside during curfew will be detained.",
      { "curfew_warning", "event_curfew" } },
    { "standing", "Civil Standing",
      "Civil Standing measures your value to the city. Work, compliance and reporting raise it. Infractions lower it. Below zero, ration privileges are withdrawn. High standing qualifies a resident for Civil Protection.",
      { "low_standing", "socio_yellow", "socio_red" } },
    { "cp", "Joining Civil Protection",
      "Residents of sufficient Civil Standing may apply to Civil Protection. Applications are made on your work board, under Factions. Civil Protection serves the city. Consider it.",
      { "cp_eligible" } },
}

-- Spoken lines that aren't a topic's answer (the recordings' names).
LC.InfoDeskLines = {
    greet = "Citizen Information. State your question.",
    greet_warm = "Good day, citizen. Thank you for your cooperation. How may I help you?",
    greet_curt = "Make it quick. There are others waiting.",
    where = "Which location? I will mark the route.",
    route = "The route is marked. Follow it. Next.",
    noplace = "That facility is not available in this sector.",
    wanted = "You have an outstanding warrant. Remain where you are. Civil Protection is aware of you.",
    closed = "This desk is closed. Come back later.",
}

-- Where is...? (the official places only: LC.WaypointPlaces)
local WHERE = {
    { "intake", "Civil Intake" }, { "housing", "Housing Allocation" }, { "labor", "Labor Assignment" },
    { "shop", "The Commissary" }, { "dispenser", "The ration dispenser" }, { "home", "My housing block" },
}

local AUDIO = { wav = true, mp3 = true, ogg = true }
local clips
local function Scan()
    clips = {}
    for _, n in ipairs(file.Find("sound/" .. LC.InfoDeskVoiceRoot .. "*", "GAME") or {}) do
        local base, ext = string.match(string.lower(n), "^(.-)%d*%.(%w+)$")
        if base and AUDIO[ext] then
            clips[base] = clips[base] or {}
            table.insert(clips[base], LC.InfoDeskVoiceRoot .. n)
            if resource and resource.AddFile then resource.AddFile("sound/" .. LC.InfoDeskVoiceRoot .. n) end
        end
    end
end
LC.InfoDeskRescan = Scan
hook.Add("Initialize", "LivingCityInfoDesk", Scan)

function LC.InfoDeskClip(id)
    if not clips then Scan() end
    local t = clips[id]
    return t and t[math.random(#t)] or nil
end

local function Speak(ent, id)
    if not IsValid(ent) then return end
    local c = LC.InfoDeskClip(id)
    ent:EmitSound(c or "buttons/blip1.wav", c and 70 or 55)
end

local function TopicById(id)
    for _, t in ipairs(LC.InfoDeskTopics) do if t[1] == id then return t end end
end

local function Manner(ply)
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return "greet_warm" end
    local s = LC.Standing and LC.Standing(ply) or 0
    if s >= 50 then return "greet_warm" end
    if s < 0 then return "greet_curt" end
    return "greet"
end

local function Menu(ply, ent, said)
    local opts = {}
    for _, t in ipairs(LC.InfoDeskTopics) do opts[#opts + 1] = { t[1], t[2] } end
    opts[#opts + 1] = { "where", "Where is...?" }
    LC.OpenDialog(ply, "infodesk", ent, { title = "Citizen Information", sub = "A clerk behind the counter. Behind them, a portrait of the Administrator.", text = said, options = opts })
end

function LC.OpenInfoDesk(ply, ent)
    if not IsValid(ply) or not LC.OpenDialog then return false end
    if not cvDesk:GetBool() then
        Speak(ent, "closed")
        LC.OpenDialog(ply, "infodesk", ent, { title = "Citizen Information", text = "'" .. LC.InfoDeskLines.closed .. "'", options = {} })
        return true
    end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then
        Speak(ent, "wanted")
        LC.OpenDialog(ply, "infodesk", ent, { title = "Citizen Information", sub = "The clerk's hand moves under the counter.", text = "'" .. LC.InfoDeskLines.wanted .. "'", options = {} })
        return true
    end
    local m = Manner(ply)
    Speak(ent, m)
    Menu(ply, ent, "'" .. LC.InfoDeskLines[m] .. "'")
    hook.Run("LivingCityInfoDesk", ply, ent)
    return true
end

LC.DialogHandlers.infodesk = function(ply, ent, id)
    if not cvDesk:GetBool() or (LC.PlayerIsWanted and LC.PlayerIsWanted(ply)) then return nil end
    if id == "where" then
        local opts = {}
        for _, w in ipairs(WHERE) do opts[#opts + 1] = { "go_" .. w[1], w[2] } end
        opts[#opts + 1] = { "back", "Something else" }
        Speak(ent, "where")
        LC.OpenDialog(ply, "infodesk", ent, { title = "Citizen Information", text = "'" .. LC.InfoDeskLines.where .. "'", options = opts })
        return "where"
    end
    if id == "back" then Menu(ply, ent, "'Next question.'") return "back" end
    local way = string.match(id, "^go_(%w+)$")
    if way then
        local find = LC.WaypointPlaces and LC.WaypointPlaces[way]
        local pos, label
        if find then pos, label = find(ply) end
        if not pos then
            Speak(ent, "noplace")
            Menu(ply, ent, "'" .. LC.InfoDeskLines.noplace .. "'")
            return "noplace"
        end
        if LC.GuideTo then LC.GuideTo(ply, pos, label) end
        Speak(ent, "route")
        Menu(ply, ent, "'" .. LC.InfoDeskLines.route .. "'")
        return "route"
    end
    local t = TopicById(id)
    if not t then return end
    Speak(ent, t[1])
    if LC.Learn then LC.Learn(ply, unpack(t[4])) end
    hook.Run("LivingCityInfoDeskTopic", ply, t[1])
    Menu(ply, ent, "'" .. t[3] .. "'")
    return t[1]
end
