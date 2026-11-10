--[[
    Living City: the Civil Orientation pamphlet

    Every new arrival registered at Civil Intake is handed one (a fresh one
    with each new life): rations, work, housing, papers, curfew, the law,
    Civil Standing, the official version (the same words as the Citizen
    Information clerk, sv_livingcity_infodesk.lua). Read it from your
    pockets any time; each page read is learning it, so the tip cards for it
    don't come (LC.Learn). It weighs nothing and can be dropped.

    Setting: lc_pamphlet (1; 0 and nobody is handed one).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPamphlet = CreateConVar("lc_pamphlet", "1", FLAGS, "New arrivals are handed a Civil Orientation pamphlet at Civil Intake, to read from their pockets")

local COVER = "WELCOME TO YOUR NEW CITY.\n\nYou have been relocated for your safety and the common good. This pamphlet contains everything a compliant resident needs to know. Read it. Keep it. Your cooperation is noted.\n\nIssued by the Office of the City Administrator."

local function Pages(ply, text)
    local opts = {}
    for _, t in ipairs(LC.InfoDeskTopics or {}) do opts[#opts + 1] = { t[1], t[2] } end
    LC.OpenDialog(ply, "pamphlet", nil, { title = "Civil Orientation pamphlet", sub = "Grey paper, stamped with the Combine's mark.", text = text, options = opts })
end

function LC.ReadPamphlet(ply)
    if not IsValid(ply) or not LC.OpenDialog or not LC.HasItem(ply, "pamphlet") then return false end
    Pages(ply, COVER)
    if LC.Learn then LC.Learn(ply, "welcome", "intake_arrival") end
    return true
end

LC.DialogHandlers.pamphlet = function(ply, _, id)
    if not LC.HasItem(ply, "pamphlet") then return end
    for _, t in ipairs(LC.InfoDeskTopics or {}) do
        if t[1] == id then
            if LC.Learn then LC.Learn(ply, unpack(t[4])) end
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
