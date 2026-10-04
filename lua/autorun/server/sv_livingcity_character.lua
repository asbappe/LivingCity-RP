--[[
    Living City: characters and permanent death

    In the Living City gamemode you are a person, and when you die that person
    is gone. You come back as someone new: a new name and citizen number, no
    credits, no standing, no job, no pockets, no stash, no history, no rank
    in any faction, and a housing block of your own. Whoever they were, they
    are nobody's problem now.

    Not counted as a death: infested players (the infested come back), admins in build
    mode, and anyone in custody (dying doesn't end a sentence, or shorten it).

    lc_permadeath 0 turns it off. As an addon on another gamemode it never runs.
    What belongs to the real player, not the character, stays: conduct strikes
    and the combat log.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPerma = CreateConVar("lc_permadeath", "1", FLAGS, "In the Living City gamemode, dying means starting over as a new character")

local FIRST = {
    "Dale", "Marta", "Owen", "Ilse", "Tomas", "Nadia", "Piotr", "Greta", "Jonas", "Lena", "Anton", "Vera",
    "Emil", "Rosa", "Felix", "Hana", "Karl", "Mira", "Stefan", "Edith", "Bram", "Clara", "Viktor", "Alma",
    "Walt", "Nora", "Dmitri", "Ruth", "Hugo", "Elsa", "Arvid", "Petra",
}
local LAST = {
    "Hollis", "Brandt", "Kowal", "Reyes", "Marsh", "Novak", "Lindqvist", "Okafor", "Varga", "Sutter", "Mercer", "Dunn",
    "Petrov", "Calloway", "Reiter", "Haas", "Moreau", "Tanner", "Zielinski", "Voss", "Abbott", "Kessler", "Ferro", "Lund",
    "Quill", "Maddox", "Sorensen", "Pruitt", "Hale", "Ostrander", "Weller", "Duval",
}

function LC.NewCharacterName()
    return FIRST[math.random(#FIRST)] .. " " .. LAST[math.random(#LAST)],
        string.format("#%02d-%03d", math.random(10, 99), math.random(100, 999))
end

function LC.CharacterName(ply)
    local n = ply:GetNW2String("lc_char", "")
    return n ~= "" and n or ply:Nick()
end

local function Enabled()
    return cvPerma:GetBool() and LC.InOwnGamemode and LC.InOwnGamemode()
end

local function Assign(ply, announce)
    local name, cid = LC.NewCharacterName()
    ply:SetNW2String("lc_char", name)
    ply:SetNW2String("lc_cid", cid)
    ply:SetPData("lc_char", name)
    ply:SetPData("lc_cid", cid)
    if announce then ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", name, cid)) end
end

hook.Add("PlayerInitialSpawn", "LivingCityCharacter", function(ply)
    local name, cid = ply:GetPData("lc_char", ""), ply:GetPData("lc_cid", "")
    if name == "" then
        Assign(ply)
    else
        ply:SetNW2String("lc_char", name)
        ply:SetNW2String("lc_cid", cid)
    end
    timer.Simple(7, function()
        if IsValid(ply) and Enabled() then
            ply:ChatPrint(string.format("[Living City] You are %s, citizen %s. If you die, that person is gone.", LC.CharacterName(ply), ply:GetNW2String("lc_cid", "")))
        end
    end)
end)

-- Everything that belonged to the dead person.
function LC.NewCharacter(ply, why)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local oldName = LC.CharacterName(ply)

    -- pockets and hidden things
    if LC.Inventory and LC.TakeItem then
        for id, n in pairs(table.Copy(LC.Inventory(ply))) do LC.TakeItem(ply, id, n) end
    end
    ply.lcStash = nil
    ply:RemovePData("lci_stash_" .. game.GetMap())

    -- money and standing
    ply:SetPData("lce_credits", GetConVar("lc_start_credits") and GetConVar("lc_start_credits"):GetInt() or 20)
    ply:SetNW2Int("lce_credits", tonumber(ply:GetPData("lce_credits", 20)) or 20)
    ply:SetPData("lce_standing", 0)
    ply:SetNW2Int("lce_standing", 0)

    -- rank everywhere, back to citizen
    if LCF and LCF.Factions then
        for _, f in ipairs(LCF.Factions) do ply:SetPData("lcf_xp_" .. f.id, 0) end
    end
    if LC.SetJob then LC.SetJob(ply, "", true) end
    if LC.SetFaction then LC.SetFaction(ply, "citizen", nil, true) end

    -- story and traits
    ply.lcStory, ply.lcStoryPostings = nil, nil
    for _, key in ipairs({ "lcq_story", "lcq_loyalty", "lcq_sympathy", "lcq_corruption", "lcq_done" }) do ply:RemovePData(key) end
    if LC.QuestOf and LC.QuestOf[ply] and LC.AbandonQuest then LC.AbandonQuest(ply) end

    -- who they are to the law
    if LC.ClearWanted then LC.ClearWanted(ply) end
    ply.lcIdentity = nil
    ply:SetNW2String("lcd_alias", "")

    -- a new body, a new door
    ply:SetNW2Float("lcn_hunger", 80)
    ply:SetNW2Float("lcn_thirst", 80)
    ply.lcnDied = nil
    if LC.AssignBlock then LC.AssignBlock(ply, true) end
    Assign(ply)

    hook.Run("LivingCityNewCharacter", ply, oldName, why)
    ply.lcNewLife = oldName
end

-- Told once they're back on their feet.
hook.Add("PlayerSpawn", "LivingCityCharacter", function(ply)
    local old = ply.lcNewLife
    if not old then return end
    ply.lcNewLife = nil
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        ply:ChatPrint(string.format("[Living City] %s is dead. You are %s, citizen %s. You start over with nothing.",
            old, LC.CharacterName(ply), ply:GetNW2String("lc_cid", "")))
    end)
end)

hook.Add("PlayerDeath", "LivingCityCharacter", function(ply)
    if not Enabled() or ply.lcNoPermadeath then return end
    if ply:GetNW2Bool("lc_build", false) then return end
    if LC.PlayerIsZombie(ply) then return end
    if LC.InCustody and LC.InCustody(ply) then return end
    LC.NewCharacter(ply, "death")
end)

concommand.Add("lc_newcharacter", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer and LC.FindPlayer(args[1])
    if not target then
        local msg = "[Living City] Usage: lc_newcharacter <name>  (wipes their character)"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    LC.NewCharacter(target, "admin")
end)
