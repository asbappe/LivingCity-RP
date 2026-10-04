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

util.AddNetworkString("lcc_open")
util.AddNetworkString("lcc_submit")
util.AddNetworkString("lcc_result")
util.AddNetworkString("lcc_keep")

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

local function RandomModel()
    local list = LCF and LCF.CitizenModels or {}
    return #list > 0 and list[math.random(#list)] or ""
end

local function Assign(ply, announce)
    local name, cid = LC.NewCharacterName()
    ply:SetNW2String("lc_char", name)
    ply:SetNW2String("lc_cid", cid)
    ply:SetPData("lc_char", name)
    ply:SetPData("lc_cid", cid)
    local model = RandomModel()
    ply:SetNW2String("lc_model", model)
    ply:SetPData("lc_model", model)
    if announce then ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", name, cid)) end
end

hook.Add("PlayerInitialSpawn", "LivingCityCharacter", function(ply)
    local name, cid = ply:GetPData("lc_char", ""), ply:GetPData("lc_cid", "")
    if name == "" then
        Assign(ply)
    else
        ply:SetNW2String("lc_char", name)
        ply:SetNW2String("lc_cid", cid)
        local model = ply:GetPData("lc_model", "")
        if model == "" then model = RandomModel() ply:SetPData("lc_model", model) end
        ply:SetNW2String("lc_model", model)
    end
    -- a character who hasn't been chosen yet gets to choose
    if ply:GetPData("lc_chosen", "0") ~= "1" then
        timer.Simple(4, function()
            if IsValid(ply) and ply:GetPData("lc_chosen", "0") ~= "1" then LC.OpenCharacterCreator(ply) end
        end)
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

    ply:SetPData("lc_chosen", "0") -- a new person gets to be named
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
        LC.OpenCharacterCreator(ply)
    end)
end)

hook.Add("PlayerDeath", "LivingCityCharacter", function(ply)
    if not Enabled() or ply.lcNoPermadeath then return end
    if ply:GetNW2Bool("lc_build", false) then
        ply:ChatPrint("[Living City] You died in build mode, so you keep this character. Type !build to leave build mode and play for real.")
        return
    end
    if LC.PlayerIsZombie(ply) then return end
    if LC.InCustody and LC.InCustody(ply) then
        ply:ChatPrint("[Living City] You died in custody. That doesn't change who you are, or how long you're in for.")
        return
    end
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

------------------------------------------------------------------------
-- Choosing who you are: a name and a face
------------------------------------------------------------------------

-- Names that are celebrities, characters, memes or jokes. Compared with spaces and
-- punctuation removed. Longer entries, so ordinary surnames aren't caught by accident.
local BLOCKED = {
    -- public figures
    "donaldtrump", "barackobama", "joebiden", "vladimirputin", "elonmusk", "kanyewest", "taylorswift", "beyonce",
    "kimkardashian", "justinbieber", "arianagrande", "ladygaga", "snoopdogg", "johnnydepp", "tomcruise", "bradpitt",
    "angelinajolie", "leonardodicaprio", "willsmith", "dwaynejohnson", "keanureeves", "robertdowney", "chrishemsworth",
    "scarlettjohansson", "elvispresley", "michaeljackson", "marilynmonroe", "davidbowie", "freddiemercury", "johnlennon",
    "paulmccartney", "bobdylan", "stevejobs", "billgates", "markzuckerberg", "jeffbezos", "kimjong", "hitler",
    "stalin", "mussolini", "maozedong", "polpot", "saddamhussein", "binladen", "jeffreyepstein",
    -- characters, in this game and others
    "gordonfreeman", "alyxvance", "barneycalhoun", "isaackleiner", "wallacebreen", "elivance", "drbreen",
    "harrypotter", "hermionegranger", "dumbledore", "voldemort", "lukeskywalker", "darthvader", "hansolo", "obiwan",
    "frodobaggins", "gandalf", "aragorn", "batman", "brucewayne", "superman", "clarkkent", "spiderman", "peterparker",
    "ironman", "tonystark", "thejoker", "harleyquinn", "supermario", "pikachu", "waltwhite", "walterwhite",
    "jessepinkman", "saulgoodman", "tonysoprano", "jonsnow", "daenerys", "tyrionlannister", "sherlockholmes",
    "jamesbond", "johnwick", "forrestgump", "spongebob", "homersimpson", "bartsimpson", "picklerick", "herobrine",
    "sonicthehedgehog", "masterchief", "geraltofrivia", "solidsnake", "laracroft", "doomguy",
    "johnmarston", "arthurmorgan", "nathandrake", "commandershepard", "sansundertale", "walterwhite", "optimusprime",
    -- memes and jokes
    "deeznuts", "mikehunt", "hughjass", "bendover", "seymourbutts", "mikerotch", "anitabath", "imanidiot", "yourmom",
}
-- Whole words that are never fine in a name.
local BLOCKED_WORDS = {
    "fuck", "fucker", "shit", "cunt", "bitch", "dick", "cock", "pussy", "penis", "vagina", "whore", "slut", "nigger",
    "nigga", "faggot", "fag", "nazi", "rape", "rapist", "retard", "god", "jesus", "satan", "admin", "moderator",
    "staff", "owner", "combine", "overwatch", "gordon", "freeman", "skibidi", "ligma", "sugma", "sigma", "bofa", "yolo",
    "rizzler", "gyatt", "noscope", "shrek", "kratos", "heisenberg", "joker", "yoda", "gandalf", "voldemort",
}

local REMINDER = "Choose a realistic name for a person living in this city and era: an ordinary name, first and last if you like. "
    .. "No celebrities, characters from games, films or shows, memes or joke names."

local function Title(word)
    word = string.lower(word)
    return (string.gsub(word, "(%a)([%a]*)", function(a, b) return string.upper(a) .. b end))
end

-- Returns true, the cleaned-up name; or false, why not.
function LC.ValidateCharacterName(raw)
    local name = string.Trim(tostring(raw or ""))
    name = string.gsub(name, "%s+", " ")
    if #name < 3 or #name > 26 then return false, "Names are between 3 and 26 characters long." end
    if string.find(name, "[^%a '%-]") then return false, "Names use letters only: no numbers or symbols." end
    local words = {}
    for w in string.gmatch(name, "%S+") do words[#words + 1] = w end
    if #words < 1 or #words > 3 then return false, "A name is one to three words: a first name, and a surname if you like." end
    for _, w in ipairs(words) do
        local letters = string.gsub(w, "[^%a]", "")
        if #letters < 2 then return false, "Each part of your name needs at least two letters." end
        if #letters >= 3 and not string.find(string.lower(letters), "[aeiouy]") then return false, "That doesn't read like a real name." end
        if string.find(string.lower(letters), "(%a)%1%1") then return false, "That doesn't read like a real name." end
        for _, bad in ipairs(BLOCKED_WORDS) do
            if string.lower(letters) == bad then return false, "That name isn't allowed. " .. REMINDER end
        end
    end
    local squashed = string.lower(string.gsub(name, "[^%a]", ""))
    for _, bad in ipairs(BLOCKED) do
        if string.find(squashed, string.gsub(bad, " ", ""), 1, true) then
            return false, "That name looks like a celebrity, a character or a joke. " .. REMINDER
        end
    end
    local clean = {}
    for _, w in ipairs(words) do clean[#clean + 1] = Title(w) end
    return true, table.concat(clean, " ")
end

local function NameInUse(name, except)
    local low = string.lower(name)
    for _, p in ipairs(player.GetAll()) do
        if p ~= except and string.lower(p:GetNW2String("lc_char", "")) == low then return true end
    end
    for _, p in ipairs(LC.People and LC.People.list or {}) do
        if p.alive and string.lower(p.name or "") == low then return true end
    end
    return false
end

local function ValidModel(path)
    for _, m in ipairs(LCF and LCF.CitizenModels or {}) do if m == path then return true end end
    return false
end

function LC.SetCharacter(ply, name, model)
    if name then
        ply:SetNW2String("lc_char", name)
        ply:SetPData("lc_char", name)
    end
    if model then
        ply:SetNW2String("lc_model", model)
        ply:SetPData("lc_model", model)
        if LC.RefreshModel then LC.RefreshModel(ply) end
    end
end

function LC.OpenCharacterCreator(ply)
    if not IsValid(ply) then return end
    LC.SendCompressed("lcc_open", {
        name = LC.CharacterName(ply), model = ply:GetNW2String("lc_model", ""), models = LCF and LCF.CitizenModels or {},
        cid = ply:GetNW2String("lc_cid", ""), reminder = REMINDER,
        first = ply:GetPData("lc_chosen", "0") ~= "1" and ply.lcNewLife == nil,
    }, { ply })
end

local function Result(ply, ok, msg)
    net.Start("lcc_result")
    net.WriteBool(ok)
    net.WriteString(msg or "")
    net.Send(ply)
end

net.Receive("lcc_submit", function(_, ply)
    local name, model = net.ReadString(), net.ReadString()
    if (ply.lccNext or 0) > CurTime() then return Result(ply, false, "One moment.") end
    ply.lccNext = CurTime() + 1
    if not ValidModel(model) then return Result(ply, false, "Choose one of the faces shown.") end
    local ok, clean = LC.ValidateCharacterName(name)
    if not ok then return Result(ply, false, clean) end
    if NameInUse(clean, ply) then return Result(ply, false, "Someone in the city already has that name.") end
    LC.SetCharacter(ply, clean, model)
    ply:SetPData("lc_chosen", "1")
    ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", clean, ply:GetNW2String("lc_cid", "")))
    Result(ply, true, clean)
end)

-- Keeping the random name and face is a choice too.
net.Receive("lcc_keep", function(_, ply)
    ply:SetPData("lc_chosen", "1")
end)

hook.Add("PlayerSay", "LivingCityCharacterChat", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!character" then return end
    LC.OpenCharacterCreator(ply)
    return ""
end)

-- Staff: set or reopen someone's character.
concommand.Add("lc_setname", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer and LC.FindPlayer(args[1])
    local name = table.concat(args, " ", 2)
    if not target or name == "" then
        local msg = "[Living City] Usage: lc_setname <player> <new name>"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    LC.SetCharacter(target, name, nil)
    target:ChatPrint("[Living City] Staff changed your name to " .. name .. ".")
end)

concommand.Add("lc_creator", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer and LC.FindPlayer(args[1])
    if target then LC.OpenCharacterCreator(target) end
end)
