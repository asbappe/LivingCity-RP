--[[
    Living City: characters and permanent death

    In the Living City gamemode you are a person, and when you die that person
    is gone. You come back as someone new: a new name and citizen number, no
    credits, no standing, no job, no pockets, no stash, no history, no rank
    in any faction, and a housing block of your own. Whoever they were, they
    are nobody's problem now.

    Not counted as a death: infested players (the infested come back), admins in build
    mode, and anyone in custody (dying doesn't end a sentence, or shorten it).

    lc_permadeath 0 turns it off. Most deaths aren't the end, though: each
    person has a few close calls first (sv_livingcity_progress.lua).
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

local FIRST_MALE = {
    "Dale", "Owen", "Tomas", "Piotr", "Jonas", "Anton", "Emil", "Felix", "Karl", "Stefan",
    "Bram", "Viktor", "Walt", "Dmitri", "Hugo", "Arvid", "Aaron", "Adrian", "Albert", "Alec",
    "Alexei", "Andrei", "Axel", "Benno", "Boris", "Bruno", "Casimir", "Conrad", "Dario", "Dennis",
    "Edgar", "Elias", "Erik", "Ernst", "Eugen", "Fabian", "Franz", "Gabriel", "Georg", "Gideon",
    "Gregor", "Gustav", "Hans", "Heinrich", "Henrik", "Igor", "Ivan", "Jakob", "Jarek", "Joris",
    "Josef", "Julian", "Kasper", "Klaus", "Konrad", "Kurt", "Lars", "Leo", "Leon", "Lorenz",
    "Lukas", "Marek", "Markus", "Martin", "Mateo", "Matthias", "Max", "Mikhail", "Milos", "Nikolai",
    "Nils", "Oskar", "Otto", "Pavel", "Pieter", "Rafael", "Ragnar", "Rolf", "Roman", "Rudolf",
    "Samuel", "Sasha", "Sebastian", "Sergei", "Simon", "Teodor", "Theo", "Torsten", "Ulrich", "Vaclav",
    "Vlad", "Werner", "Wilhelm", "Yuri", "Zane",
}
local FIRST_FEMALE = {
    "Marta", "Ilse", "Nadia", "Greta", "Lena", "Vera", "Rosa", "Hana", "Mira", "Edith",
    "Clara", "Alma", "Nora", "Ruth", "Elsa", "Petra", "Agnes", "Alena", "Alice", "Amelie",
    "Anja", "Anna", "Beata", "Berta", "Birgit", "Brigitte", "Camilla", "Carla", "Cecilia", "Charlotte",
    "Dagmar", "Daria", "Dora", "Eliska", "Elena", "Emma", "Erika", "Eva", "Felicia", "Freya",
    "Gerda", "Gisela", "Hedda", "Helena", "Henrietta", "Ida", "Ines", "Irena", "Irina", "Iris",
    "Ivana", "Jana", "Johanna", "Judith", "Julia", "Karin", "Katarina", "Katya", "Klara", "Lara",
    "Leona", "Liesel", "Lina", "Livia", "Lotte", "Lucia", "Magda", "Margit", "Maren", "Maria",
    "Mathilde", "Maya", "Melina", "Milena", "Monika", "Natalia", "Nina", "Olga", "Paula", "Rebecca",
    "Renata", "Rita", "Sabine", "Selma", "Silke", "Sofia", "Sonja", "Stella", "Tamara", "Tatiana",
    "Ursula", "Valeria", "Vesna", "Viola", "Wanda", "Yelena", "Zora",
}
local FIRST_GENDER = {}
for _, n in ipairs(FIRST_MALE) do FIRST_GENDER[n] = "male" end
for _, n in ipairs(FIRST_FEMALE) do FIRST_GENDER[n] = "female" end
-- (first and last names combine freely: well over three hundred different names)
local LAST = {
    "Hollis", "Brandt", "Kowal", "Reyes", "Marsh", "Novak", "Lindqvist", "Okafor", "Varga", "Sutter",
    "Mercer", "Dunn", "Petrov", "Calloway", "Reiter", "Haas", "Moreau", "Tanner", "Zielinski", "Voss",
    "Abbott", "Kessler", "Ferro", "Lund", "Quill", "Maddox", "Sorensen", "Pruitt", "Hale", "Ostrander",
    "Weller", "Duval", "Adler", "Almasi", "Andersen", "Bauer", "Becker", "Berger", "Bishop", "Blum",
    "Bosch", "Brandl", "Brenner", "Burke", "Carver", "Cole", "Dahl", "Decker", "Dietrich", "Dolan",
    "Drake", "Eklund", "Engel", "Fischer", "Foley", "Frank", "Fuchs", "Galvin", "Gruber", "Hartmann",
    "Hendry", "Hoffman", "Holt", "Horvat", "Ivanov", "Jansen", "Jovanovic", "Keller", "Kline", "Koch",
    "Kovacs", "Kraus", "Kruger", "Lange", "Larsen", "Lehmann", "Lorenz", "Maier", "Marek", "Meyer",
    "Molnar", "Nagy", "Neumann", "Nowak", "Olsen", "Orlov", "Pavlik", "Pearce", "Perrin", "Pohl",
    "Quinn", "Raske", "Richter", "Rossi", "Roth", "Sadler", "Schaefer", "Schmidt", "Schneider", "Scholz",
    "Seidel", "Sokolov", "Stein", "Strand", "Thorne", "Ulrich", "Vance", "Vogel", "Wagner", "Walsh",
    "Weber", "Winter", "Wolff", "Yeager", "Zahn", "Zeman",
}

-- "male" or "female" for a name this file made up (by its first name), or nil.
function LC.NameGender(name)
    return FIRST_GENDER[string.match(name or "", "^(%S+)") or ""]
end

-- A man's or a woman's name to go with the face (either, if gender is nil).
-- avoid: a name not to hand out again (the one they had). Never a banned one.
-- Is this name on somebody right now: a player's character, or a living person in the city?
function LC.NameInUse(name)
    for _, p in ipairs(player.GetAll()) do
        if p:GetNW2String("lc_char", "") == name then return true end
    end
    return LC.PersonNameTaken ~= nil and LC.PersonNameTaken(name) or false
end

function LC.NewCharacterName(gender, avoid)
    local name, cid
    for _ = 1, 60 do
        local list = gender == "female" and FIRST_FEMALE or gender == "male" and FIRST_MALE
            or (math.random() < 0.5 and FIRST_MALE or FIRST_FEMALE)
        name = list[math.random(#list)] .. " " .. LAST[math.random(#LAST)]
        cid = string.format("#%02d-%03d", math.random(10, 99), math.random(100, 999))
        if name ~= avoid and not (LC.CharBanned and LC.CharBanned(name)) and not LC.NameInUse(name) then break end
    end
    return name, cid
end

function LC.CharacterName(ply)
    local n = ply:GetNW2String("lc_char", "")
    return n ~= "" and n or ply:Nick()
end

local function Enabled()
    return cvPerma:GetBool()
end

local function RandomModel()
    local list = LCF and LCF.CitizenModels or {}
    return #list > 0 and list[math.random(#list)] or ""
end

local function Assign(ply, announce)
    -- (a fresh person: name, number and face; sv_livingcity_slots.lua uses it for a new slot)
    local model = RandomModel()
    local name, cid = LC.NewCharacterName(string.find(string.lower(model), "female", 1, true) and "female" or "male", ply:GetNW2String("lc_char", ""))
    ply:SetNW2String("lc_char", name)
    ply:SetNW2String("lc_cid", cid)
    ply:SetPData("lc_char", name)
    ply:SetPData("lc_cid", cid)
    ply:SetNW2String("lc_model", model)
    ply:SetPData("lc_model", model)
    if LC.StartLife then LC.StartLife(ply) end -- (their time in the city starts now: sv_livingcity_life.lua)
    if LC.IntakeNew then LC.IntakeNew(ply) end -- (nothing is theirs yet: sv_livingcity_intake.lua)
    if announce then ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", name, cid)) end
end

LC.AssignNewCharacter = function(ply, announce) return Assign(ply, announce) end

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
    local oldCid = ply:GetNW2String("lc_cid", "")
    -- what the next person inherits, and the player's record of this life (sv_livingcity_progress.lua)
    local inherit = LC.Inheritance and LC.Inheritance(ply, why) or 0
    if LC.RecordLegacy then LC.RecordLegacy(ply, why) end

    -- pockets and hidden things
    if LC.Inventory and LC.TakeItem then
        for id, n in pairs(table.Copy(LC.Inventory(ply))) do LC.TakeItem(ply, id, n) end
    end
    ply.lcStash = nil
    ply:RemovePData("lci_stash_" .. game.GetMap())

    -- money and standing
    ply:SetPData("lce_credits", (GetConVar("lc_start_credits") and GetConVar("lc_start_credits"):GetInt() or 20) + inherit)
    ply.lcInherited = inherit
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
    Assign(ply) -- (the new person first: whether they're handed a room depends on who they are)
    if LC.AssignBlock then LC.AssignBlock(ply, true) end

    ply:SetPData("lc_chosen", "0") -- a new person gets to be named
    hook.Run("LivingCityNewCharacter", ply, oldName, why, oldCid)
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

-- The death card (sv_livingcity_life.lua) goes out first, while everything of
-- theirs is still there to tell.
hook.Add("PlayerDeath", "LivingCityCharacter", function(ply, inflictor, attacker)
    local function Card(gone, note) if LC.RecordDeath then LC.RecordDeath(ply, gone, attacker, note) end end
    -- (lcEndOfLife: an ending that is final whatever the setting, like a stalker stepping into the light)
    if (not Enabled() and not ply.lcEndOfLife) or ply.lcNoPermadeath then
        Card(false, "Permanent death is off here: you come back as yourself.")
        return
    end
    if ply:GetNW2Bool("lc_build", false) then
        ply:ChatPrint("[Living City] You died in build mode, so you keep this character. C > Help > Build mode to leave build mode and play for real.")
        Card(false, "Build mode: you keep this character.")
        return
    end
    if LC.PlayerIsZombie(ply) then
        Card(false, "The infestation doesn't let go. You come back as you were.")
        return
    end
    if LC.InCustody and LC.InCustody(ply) then
        ply:ChatPrint("[Living City] You died in custody. That doesn't change who you are, or how long you're in for.")
        Card(false, "Died in custody: you're still you, and still serving your time.")
        return
    end
    -- a close call, unless this one is the end of them (sv_livingcity_progress.lua)
    if LC.DeathIsFinal and not LC.DeathIsFinal(ply) then
        local left = LC.UseCloseCall(ply)
        Card(false, left > 0 and string.format("A close call: %d left.", left) or "A close call: the last one.")
        return
    end
    Card(true)
    LC.NewCharacter(ply, ply.lcEndOfLife or "death")
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

-- opts.intake: the registration form at a Civil Intake terminal (sv_livingcity_intake.lua):
-- nothing filled in for you, a description to give, no "keep what I was given".
-- opts.asked: they asked for it (!character), so say why not if it's not now.
function LC.OpenCharacterCreator(ply, opts)
    if not IsValid(ply) then return end
    local intake = opts and opts.intake
    if not intake and LC.IntakeDefersCreator and LC.IntakeDefersCreator(ply) then
        if opts and opts.asked then ply:ChatPrint("[Civil Intake] Who you are goes on your registration form, at the Civil Intake terminal.") end
        return
    end
    LC.SendCompressed("lcc_open", {
        name = intake and "" or LC.CharacterName(ply), model = ply:GetNW2String("lc_model", ""), models = LCF and LCF.CitizenModels or {},
        cid = ply:GetNW2String("lc_cid", ""), reminder = REMINDER,
        first = ply:GetPData("lc_chosen", "0") ~= "1" and ply.lcNewLife == nil,
        intake = intake and true or nil, desc = intake and ply:GetNW2String("lc_desc", "") or nil,
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
    local desc = net.ReadString() or "" -- (the registration form's description)
    if (ply.lccNext or 0) > CurTime() then return Result(ply, false, "One moment.") end
    ply.lccNext = CurTime() + 1
    if not ValidModel(model) then return Result(ply, false, "Choose one of the faces shown.") end
    local ok, clean = LC.ValidateCharacterName(name)
    if not ok then return Result(ply, false, clean) end
    if NameInUse(clean, ply) then return Result(ply, false, "Someone in the city already has that name.") end
    if LC.CharBanned and LC.CharBanned(clean) then return Result(ply, false, "That person can't come back. Choose another name.") end
    local atDesk = IsValid(ply.lcIntakeTerm)
    if atDesk and LC.IntakeFormCheck then
        local okF, why = LC.IntakeFormCheck(ply, desc)
        if not okF then return Result(ply, false, why) end
    end
    LC.SetCharacter(ply, clean, model)
    if atDesk and LC.SetDescription then LC.SetDescription(ply, desc) end
    ply:SetPData("lc_chosen", "1")
    if not atDesk then ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", clean, ply:GetNW2String("lc_cid", ""))) end
    Result(ply, true, clean)
    hook.Run("LivingCityCharacterChosen", ply, clean, model)
end)

-- The registration form's "Suggest a name": an ordinary one for the face picked.
util.AddNetworkString("lcc_suggest")
util.AddNetworkString("lcc_suggested")
net.Receive("lcc_suggest", function(_, ply)
    if (ply.lccSuggestNext or 0) > CurTime() then return end
    ply.lccSuggestNext = CurTime() + 0.5
    local model = string.lower(net.ReadString() or "")
    local name = LC.NewCharacterName(string.find(model, "female", 1, true) and "female" or "male", ply:GetNW2String("lc_char", ""))
    net.Start("lcc_suggested")
    net.WriteString(name or "")
    net.Send(ply)
end)

-- Keeping the random name and face is a choice too.
net.Receive("lcc_keep", function(_, ply)
    ply:SetPData("lc_chosen", "1")
end)

hook.Add("PlayerSay", "LivingCityCharacterChat", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!character" then return end
    LC.OpenCharacterCreator(ply, { asked = true })
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
