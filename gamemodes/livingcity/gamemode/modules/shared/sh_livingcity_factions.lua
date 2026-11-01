--[[
    City Factions: configuration

    This is the file to edit to make the factions yours: rename ranks, change
    XP thresholds, models, loadouts, armor, health and speeds. Ranks inherit
    anything they leave out from the rank below them.

    Rank fields:
      name, short       full and short rank names
      xp                XP needed in this faction to hold the rank
      models            player models to pick from
      loadout           weapons issued on spawn
      health, armor     starting values
      walk, run         movement speeds
      hunted            Civil Protection treats this person as an anticitizen on
                        sight, anywhere outside a rebel zone

    Faction fields:
      cp        counts as Civil Protection for Living City (doors, arrests, NPC cops)
      zombie    counts as a zombie (NPC zombies are friendly, everyone else is not)
      whitelist only players an admin has whitelisted can join (lcf_whitelist)
      requires  { faction = "cp", rank = 3 }: must have reached that rank there first
      specials  unique roles inside the faction (see Father Grigori)
]]


LCF = LCF or {}

local function Models(group, males, females)
    local out = {}
    for i = 1, males do out[#out + 1] = string.format("models/player/%s/male_%02d.mdl", group, i) end
    for i = 1, females do out[#out + 1] = string.format("models/player/%s/female_%02d.mdl", group, i) end
    return out
end

local CITIZEN = Models("group01", 9, 6)
local REBEL = Models("group03", 9, 6)

LCF.CitizenModels = CITIZEN -- what a new character may choose from

LCF.Factions = {
    {
        id = "citizen", name = "Citizen", color = Color(160, 190, 160),
        desc = "An ordinary resident of the city. Keep your head down, carry your papers, collect your rations. " ..
               "Assignments from the Union earn standing.",
        ranks = {
            { name = "Citizen", short = "CIT", xp = 0, models = CITIZEN, loadout = { "weapon_fists" } },
            { name = "Union Worker", short = "CWU", xp = 120 },
            { name = "Loyalist", short = "LOY", xp = 350 },
            { name = "Model Citizen", short = "MOD", xp = 800 },
        },
    },
    {
        id = "resistance", name = "Resistance", color = Color(225, 150, 60),
        desc = "The underground. Low ranks pass for ordinary citizens. Fighters wear the lambda openly and are hunted on sight outside rebel territory.",
        ranks = {
            { name = "Sympathizer", short = "SYM", xp = 0, models = CITIZEN, loadout = { "weapon_fists" } },
            { name = "Member", short = "MBR", xp = 150, loadout = { "weapon_fists", "weapon_crowbar" } },
            { name = "Fighter", short = "FTR", xp = 400, models = REBEL, armor = 25, hunted = true,
              loadout = { "weapon_crowbar", "weapon_pistol", "weapon_smg1" } },
            { name = "Lieutenant", short = "LT", xp = 900, armor = 50,
              loadout = { "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_shotgun" } },
            { name = "Commander", short = "CMD", xp = 1800, armor = 75,
              loadout = { "weapon_crowbar", "weapon_357", "weapon_smg1", "weapon_shotgun", "weapon_ar2" } },
        },
        specials = {
            {
                id = "hacker", name = "Hacker", max = 2, minRank = 2,
                desc = "Combine locks, screens and terminals are your trade. You carry the multitool: hack doors open, " ..
                       "hijack city screens, pull data off Combine terminals. It's contraband: a search will take it.",
                loadout = { "weapon_crowbar", "weapon_pistol", "weapon_lc_multitool" },
            },
            {
                id = "smuggler", name = "Smuggler", max = 2, minRank = 2,
                desc = "Moving the cell's cargo is your trade: guns, ammunition and worse, out past the units to drops all over the city. " ..
                       "Your board (F3) has smuggling runs on it, better paid than anything a courier carries. A search that finds the cargo finds you.",
                loadout = { "weapon_crowbar", "weapon_pistol" },
            },
            {
                id = "chaplain", name = "Father Grigori", max = 1, minRank = 2,
                desc = "Chaplain of the Resistance. A priest who will not let faith die under the Combine. " ..
                       "He tends the wounded with his Blessing and preaches the Word aloud. The Combine have " ..
                       "declared his faith contraband, so Civil Protection hunts him on sight outside rebel territory.",
                models = { "models/player/monk.mdl" },
                loadout = { "weapon_lc_blessing", "weapon_shotgun" },
                health = 120, armor = 0, hunted = true,
            },
            {
                id = "vortigaunt", name = "Free Vortigaunt", max = 2, minRank = 2, vort = true,
                desc = "A vortigaunt with the shackles off, fighting beside the people who freed it. Its vortessence " ..
                       "heals (right click) and strikes (left click). The Combine want it back in chains, and hunt it on sight.",
                models = { "models/vortigaunt.mdl" },
                loadout = { "weapon_lc_vort" },
                health = 150, armor = 0, hunted = true,
            },
        },
    },
    {
        -- One career, from the records office to the Overwatch. The Overwatch
        -- ranks (overwatch = true) need the transhuman conditioning first: the
        -- Overwatch Candidate story offers it to Division Leaders. Without it,
        -- XP keeps counting but the rank stops at Division Leader.
        id = "cp", name = "Civil Protection", color = Color(80, 140, 255), cp = true,
        desc = "Civil Protection: the records office, the Metropolice, and for the best of them, the Overwatch. " ..
               "Earn your way up. Past Division Leader there is no going back to being human.",
        ranks = {
            { name = "Recruit", short = "RCT", xp = 0, models = { "models/player/police.mdl", "models/player/police_fem.mdl" },
              loadout = { "weapon_lc_baton" }, armor = 25 },
            { name = "Metrocop", short = "MPF", xp = 150, loadout = { "weapon_lc_baton", "weapon_pistol" }, armor = 50 },
            { name = "Division Leader", short = "DvL", xp = 600, loadout = { "weapon_lc_baton", "weapon_pistol", "weapon_smg1" }, armor = 75 },
            { name = "Combine Prison Guard", short = "OPG", xp = 1200, overwatch = true, hla = "guard", models = { "models/player/combine_soldier_prisonguard.mdl" },
              loadout = { "weapon_lc_baton", "weapon_smg1", "weapon_shotgun" }, health = 100, armor = 100 },
            { name = "Combine Soldier", short = "OWS", xp = 2000, overwatch = true, hla = "soldier", models = { "models/player/combine_soldier.mdl" },
              loadout = { "weapon_lc_baton", "weapon_smg1", "weapon_frag" } },
            { name = "Elite Soldier", short = "EOW", xp = 3000, overwatch = true, hla = "elite", models = { "models/player/combine_super_soldier.mdl" },
              loadout = { "weapon_lc_baton", "weapon_ar2", "weapon_frag" }, health = 125, armor = 150 },
        },
        specials = {
            {
                id = "scanner_op", name = "Scanner Operator", max = 2, minRank = 1,
                desc = "Two at a time, from any rank. Flies a city scanner from a Combine console or data terminal, " ..
                       "or anywhere in the Nexus (F1 > Unit tools). Photographs earn XP, and a rebel caught on camera " ..
                       "goes out to every Civil Protection unit as a BOLO.",
                models = { "models/player/police.mdl", "models/player/police_fem.mdl" },
                loadout = { "weapon_lc_baton" },
                armor = 25,
            },
            {
                id = "ow_commander", name = "Overwatch Commander", max = 1, minRank = 6, overwatch = true, hla = "elite",
                desc = "One at a time, from the Elite. Calls in an Overwatch squad by dropship (F1 > Unit tools), " ..
                       "every fifteen minutes, and commands every Civil Protection unit in the city.",
                models = { "models/player/combine_super_soldier.mdl" },
                loadout = { "weapon_lc_baton", "weapon_ar2", "weapon_frag" },
                health = 150, armor = 200,
            },
        },
    },
    {
        id = "vort", name = "Vortigaunt", color = Color(150, 200, 120), vort = true,
        desc = "A shackled vortigaunt: Combine property, put to work on the city's dirtiest labour. The collar holds " ..
               "your vortessence in. The Resistance can cut the shackles (!unshackle), if they reach you.",
        ranks = {
            { name = "Laborer", short = "VLB", xp = 0, models = { "models/vortigaunt.mdl" }, loadout = { "weapon_lc_vort" }, health = 120 },
            { name = "Trusted Laborer", short = "VTL", xp = 250 },
            { name = "Overseer's Hand", short = "VOH", xp = 700 },
        },
    },
    {
        id = "admin", name = "City Administrator", color = Color(235, 235, 235), cp = true, whitelist = true,
        desc = "The face of the city's government. Whitelisted by staff.",
        ranks = {
            { name = "Administrator", short = "ADM", xp = 0, models = { "models/player/breen.mdl" }, loadout = { "weapon_fists", "weapon_lc_admin" } },
        },
        specials = {
            {
                id = "propaganda_director", name = "Director of Propaganda", max = 1, minRank = 1,
                desc = "The city's voice. Carries the microphone: on air over every loudspeaker and screen, a minute at a time, " ..
                       "when the transmitter is ready. Keep hold of it: the Resistance would love to use it.",
                models = { "models/player/breen.mdl" },
                loadout = { "weapon_fists", "weapon_lc_microphone" },
            },
        },
    },
    {
        -- not chosen: made. The worst anticitizens the city catches (sv_livingcity_custody.lua)
        id = "stalker", name = "Stalker", color = Color(140, 120, 110), whitelist = true, stalker = true,
        desc = "What the Combine make of the anticitizens they can't use any other way. Combine property: slow, unarmed, " ..
               "made to work. It lasts until you die, or the city has had its use of you.",
        ranks = {
            { name = "Stalker", short = "STK", xp = 0, models = { "models/player/corpse1.mdl" }, loadout = { "weapon_lc_hands" },
              health = 60, walk = 90, run = 90 },
        },
    },
    {
        id = "zombie", name = "Infested", color = Color(125, 175, 60), zombie = true,
        desc = "What the headcrabs left behind. NPC zombies are your kin. Everyone else is food, and knows it.",
        ranks = {
            { name = "Zombie", short = "ZMB", xp = 0, models = { "models/player/zombie_classic.mdl" },
              loadout = { "weapon_lc_claws" }, health = 150, walk = 80, run = 120 },
            { name = "Fast Zombie", short = "FZM", xp = 300, models = { "models/player/zombie_fast.mdl" },
              health = 100, walk = 220, run = 380 },
            { name = "Zombine", short = "ZBN", xp = 900, models = { "models/player/zombie_soldier.mdl" },
              health = 250, armor = 50, walk = 90, run = 170 },
        },
    },
}

-- XP awarded for things that matter to each faction
LCF.XP = {
    duty_per_minute = 1,  -- active (not AFK) time in any faction with ranks
    arrest_player   = 25, -- CP/Overwatch incarcerating a player
    arrest_npc      = 5,  -- CP/Overwatch detaining an NPC citizen
    heal_per_25hp   = 1,  -- Father Grigori's Blessing
    infect          = 10, -- a zombie killing a human player
    infect_npc      = 2,  -- a zombie killing an NPC citizen
    strike_penalty  = 50, -- lost per conduct strike
}

------------------------------------------------------------------------
-- Helpers (shared)
------------------------------------------------------------------------

LCF.ById = {}
for _, f in ipairs(LCF.Factions) do
    LCF.ById[f.id] = f
    -- ranks inherit what they leave out from the rank below
    for i = 2, #f.ranks do
        local r, prev = f.ranks[i], f.ranks[i - 1]
        for _, k in ipairs({ "models", "loadout", "health", "armor", "walk", "run", "hunted" }) do
            if r[k] == nil then r[k] = prev[k] end
        end
    end
    f.specialsById = {}
    for _, s in ipairs(f.specials or {}) do f.specialsById[s.id] = s end
end

function LCF.Get(id) return LCF.ById[id] end

-- The rank this much XP earns. conditioned: has had the transhuman
-- conditioning (else the Overwatch ranks stay out of reach).
function LCF.RankIndexFor(fac, xp, conditioned)
    local idx = 1
    for i, r in ipairs(fac.ranks) do
        if r.overwatch and not conditioned then break end
        if xp >= (r.xp or 0) then idx = i end
    end
    return idx
end

-- The rank (or special role) a player holds now.
function LCF.RankOf(ply)
    local f = LCF.ById[ply:GetNW2String("lcf_faction", "")]
    if not f then return nil end
    local sid = ply:GetNW2String("lcf_special", "")
    return (sid ~= "" and f.specialsById[sid]) or f.ranks[ply:GetNW2Int("lcf_rank", 1)] or f.ranks[1]
end

-- Overwatch: a Civil Protection rank (or role) past the conditioning.
function LCF.IsOverwatch(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "cp" then return false end
    local r = LCF.RankOf(ply)
    return r ~= nil and r.overwatch == true
end

function LCF.UnitNumber(steamid)
    return tonumber(util.CRC(steamid or "")) % 90000 + 10000
end
