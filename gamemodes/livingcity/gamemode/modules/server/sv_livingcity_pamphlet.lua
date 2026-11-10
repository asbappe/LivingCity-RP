--[[
    Living City: the Civil Orientation pamphlet

    Every new arrival registered at Civil Intake is handed one (a fresh one
    with each new life): rations, work, housing, papers, curfew, the law,
    Civil Standing, as the Administrator's office puts it (its own words:
    LC.PamphletPages below; the topics are the Citizen Information clerk's,
    sv_livingcity_infodesk.lua). Read it from your
    pockets any time; each page read is learning it, so the tip cards for it
    don't come (LC.Learn). It weighs nothing and can be dropped.

    Setting: lc_pamphlet (1; 0 and nobody is handed one).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPamphlet = CreateConVar("lc_pamphlet", "1", FLAGS, "New arrivals are handed a Civil Orientation pamphlet at Civil Intake, to read from their pockets")

-- Written by someone in the Administrator's office: kind on the surface, a threat underneath (the owner,
-- 10 November: "natural english ... as someone working for the administrator wrote it ... a bit harsh with a
-- veneer of being kind"). Its own words, not the clerk's. id = { page title, the page } (the ids are the
-- clerk's topics, so a page teaches the same tips: LC.InfoDeskTopics).
local COVER = "WELCOME HOME\n\nYou were brought here for your own protection, and the city is glad to have you. In return it asks very little: work, do as you're told, and keep your papers on you. This pamphlet explains how. Please read it carefully. \"I didn't know\" has never helped anyone.\n\nThe Office of the City Administrator"

LC.PamphletPages = {
    { "rations", "Rations",
      "Nobody in this city goes hungry unless they choose to. Every Union shift you finish earns you a ration card, and each card buys one ration at the dispenser. It really is that simple. Your first meal after you arrive is on us. After that, you earn it like everyone else." },
    { "work", "Work",
      "Idleness is bad for you, and worse for the city. Labor Assignment will find you something suitable. Shifts pay credits and Civil Standing, and every one you finish puts a ration card in your hand. Your shifts are on your work board." },
    { "housing", "Housing",
      "Housing Allocation finds a room for every resident with a job. Every resident with a job, you'll notice. Your room is where you sleep, where you keep your things, and where you will be when curfew starts." },
    { "papers", "Your papers",
      "You're registered now, which means, as far as the city is concerned, you exist. Keep your identity papers on you at all times, and show them to any Civil Protection officer who asks. They are entitled to ask. Lost papers can be replaced at Civil Intake, for a fee. Try not to lose them." },
    { "law", "The law",
      "The laws are posted on the law board for anyone to read, so nobody can say they weren't told. Do what Civil Protection tells you. Don't run when they're nearby: they'll assume the worst, and they're usually right. If you see something, report it. Your neighbours would do the same for you." },
    { "curfew", "Curfew",
      "Curfew is for your own safety. You'll hear a warning two minutes before it starts. When it does, go home to your block and stay there until morning. Anyone found outside will be detained, and nobody wants that, least of all you." },
    { "standing", "Civil Standing",
      "Civil Standing is how the city knows who it can count on. Work, cooperate and report what you see, and it goes up. Break the rules and it goes down. Let it drop below zero and you'll lose your rations until you've earned them back. Climb high enough, and Civil Protection may have a place for you." },
    { "cp", "Civil Protection",
      "The city looks after those who look after it. Residents with high enough Civil Standing can apply to join Civil Protection from their work board, under Factions. The uniform brings respect, and a sense of purpose. Do think about it." },
}

local function Pages(ply, text)
    local opts = {}
    for _, t in ipairs(LC.PamphletPages) do opts[#opts + 1] = { t[1], t[2] } end
    LC.OpenDialog(ply, "pamphlet", nil, { title = "Civil Orientation pamphlet", sub = "Thin grey paper, stamped with the Combine's mark.", text = text, options = opts })
end

function LC.ReadPamphlet(ply)
    if not IsValid(ply) or not LC.OpenDialog or not LC.HasItem(ply, "pamphlet") then return false end
    Pages(ply, COVER)
    if LC.Learn then LC.Learn(ply, "welcome", "intake_arrival") end
    return true
end

LC.DialogHandlers.pamphlet = function(ply, _, id)
    if not LC.HasItem(ply, "pamphlet") then return end
    for _, t in ipairs(LC.PamphletPages) do
        if t[1] == id then
            for _, topic in ipairs(LC.InfoDeskTopics or {}) do
                if topic[1] == id and LC.Learn then LC.Learn(ply, unpack(topic[4])) end
            end
            Pages(ply, string.upper(t[2]) .. "\n\n" .. t[3])
            return id
        end
    end
end

hook.Add("LivingCityRegistered", "LivingCityPamphlet", function(ply)
    if not cvPamphlet:GetBool() or not IsValid(ply) or not LC.GiveItem or LC.HasItem(ply, "pamphlet") then return end
    LC.GiveItem(ply, "pamphlet", 1)
    ply:ChatPrint("[Civil Intake] You are handed a Civil Orientation pamphlet. Read it (it's in your pockets).")
end)
