--[[
    City Factions: configuration

    This is the file to edit to make the factions yours: rename ranks, change
    XP thresholds, models, loadouts, armor, health and speeds. Ranks inherit
    anything they leave out from the rank below them.

    The faction system only runs on Sandbox-based servers with lc_factions 1.
    On DarkRP, Helix, NutScript or Clockwork it stays off, because those have
    their own faction systems (which Living City already understands).

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
      requires  { faction = "cp", rank = 6 }: must have reached that rank there first
      specials  unique roles inside the faction (see Father Grigori)
]]

AddCSLuaFile()

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
                id = "chaplain", name = "Father Grigori", max = 1, minRank = 2,
                desc = "Chaplain of the Resistance. A priest who will not let faith die under the Combine. " ..
                       "He tends the wounded with his Blessing and preaches the Word aloud. The Combine have " ..
                       "declared his faith contraband, so Civil Protection hunts him on sight outside rebel territory.",
                models = { "models/player/monk.mdl" },
                loadout = { "weapon_lc_blessing", "weapon_shotgun" },
                health = 120, armor = 0, hunted = true,
            },
        },
    },
    {
        id = "cp", name = "Civil Protection", color = Color(80, 140, 255), cp = true,
        desc = "The Metropolice. Patrol, inspect, detain. Earn your way up the ranks, and the best are offered to Overwatch.",
        ranks = {
            { name = "Recruit", short = "RCT", xp = 0, models = { "models/player/police.mdl", "models/player/police_fem.mdl" },
              loadout = { "weapon_lc_baton" }, armor = 25 },
            { name = "Unit 05", short = "05", xp = 100, loadout = { "weapon_lc_baton", "weapon_pistol" }, armor = 50 },
            { name = "Unit 04", short = "04", xp = 250 },
            { name = "Unit 03", short = "03", xp = 450 },
            { name = "Unit 02", short = "02", xp = 700 },
            { name = "Unit 01", short = "01", xp = 1000, loadout = { "weapon_lc_baton", "weapon_pistol", "weapon_smg1" }, armor = 75 },
            { name = "Officer", short = "OfC", xp = 1400 },
            { name = "Elite Protection Unit", short = "EpU", xp = 2000, armor = 100 },
            { name = "Division Leader", short = "DvL", xp = 2800 },
            { name = "Sectoral Commander", short = "SeC", xp = 4000 },
        },
    },
    {
        id = "ota", name = "Overwatch", color = Color(205, 70, 70), cp = true,
        requires = { faction = "cp", rank = 6 },
        desc = "Transhuman Overwatch soldiers. Reach Unit 01 in Civil Protection to be considered.",
        ranks = {
            { name = "Overwatch Soldier", short = "OWS", xp = 0, models = { "models/player/combine_soldier.mdl" },
              loadout = { "weapon_lc_baton", "weapon_smg1", "weapon_frag" }, health = 100, armor = 100 },
            { name = "Prison Guard", short = "OPG", xp = 600, models = { "models/player/combine_soldier_prisonguard.mdl" },
              loadout = { "weapon_lc_baton", "weapon_smg1", "weapon_shotgun" } },
            { name = "Elite", short = "EOW", xp = 1500, models = { "models/player/combine_super_soldier.mdl" },
              loadout = { "weapon_lc_baton", "weapon_ar2", "weapon_frag" }, health = 125, armor = 150 },
        },
    },
    {
        id = "admin", name = "City Administrator", color = Color(235, 235, 235), cp = true, whitelist = true,
        desc = "The face of the city's government. Whitelisted by staff.",
        ranks = {
            { name = "Administrator", short = "ADM", xp = 0, models = { "models/player/breen.mdl" }, loadout = { "weapon_fists" } },
        },
    },
    {
        id = "zombie", name = "Infested", color = Color(125, 175, 60), zombie = true,
        desc = "What the headcrabs left behind. NPC zombies are your kin. Everyone else is food, and knows it.",
        ranks = {
            { name = "Zombie", short = "ZMB", xp = 0, models = { "models/player/zombie_classic.mdl" },
              loadout = { "weapon_lc_claws" }, health = 150, walk = 140, run = 200 },
            { name = "Fast Zombie", short = "FZM", xp = 300, models = { "models/player/zombie_fast.mdl" },
              health = 100, walk = 220, run = 380 },
            { name = "Zombine", short = "ZBN", xp = 900, models = { "models/player/zombie_soldier.mdl" },
              health = 250, armor = 50, walk = 150, run = 230 },
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

function LCF.RankIndexFor(fac, xp)
    local idx = 1
    for i, r in ipairs(fac.ranks) do
        if xp >= (r.xp or 0) then idx = i end
    end
    return idx
end

function LCF.UnitNumber(steamid)
    return tonumber(util.CRC(steamid or "")) % 90000 + 10000
end
