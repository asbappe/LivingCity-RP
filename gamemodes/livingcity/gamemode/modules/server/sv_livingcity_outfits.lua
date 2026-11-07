--[[
    Living City: clothes that show the job

    Each Union job can have its own looks: a model, the skins it may wear
    and the bodygroups it may show (a cap, overalls, glasses). The city's
    people with that job wear one, and so does a citizen player who holds
    it. Each person gets their own pick from what's allowed, and keeps it.
    A look made from Half-Life 2's citizens can keep each person's own face
    (the same face, in that outfit's clothes).

    Set them up in game, no files to edit: the editor's panel, Job outfits
    (or !outfits, admin). Pick a job, a model from whatever's installed (the
    stock citizens and medics, the hostages, a Workshop pack), tick the
    skins and bodygroup pieces that fit, add it, save. (No job is dressed
    by default: Half-Life 2's medic clothes are the Resistance's.)

    "Everyone else" is for the people without a job: give them glasses,
    beanies or caps from a pack, and each picks their own.

    Cheap variety on top, nothing to download: each of the city's people
    is a little taller or shorter than the next (lc_people_heights), and
    each citizen player's shirt has its own drab colour (the default
    citizen playermodels tint with the player colour).

    Saved in garrysmod/data/livingcity/outfits.json, for every map.
    lc_outfits 0: everyone dresses as they always did.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_outfits_open")
util.AddNetworkString("lc_outfits_save")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_outfits", "1", FLAGS, "The city's people (and citizen players) wear their job's outfit")
local cvHeights = CreateConVar("lc_people_heights", "1", FLAGS, "The city's people are slightly different heights, each their own")
local cvTint = CreateConVar("lc_citizen_tint", "1", FLAGS, "Each citizen player's shirt has its own drab colour")

local EVERYONE = "_none" -- (the looks for people without a job)
local CREATOR = "_creator" -- (what a new character may choose from: the character creator)

local FILE = "livingcity/outfits.json"
local FACE = "{face}" -- (in a model path: the person's own face, male_03 and so on; {sex}: male or female, to match)

-- Each job: { list = { { pm = player model, npc = NPC model (optional), skins = { n, ... }, bg = { [name] = { n, ... } } } } }
-- (none: the Clinic Medic used to start in Half-Life 2's medic clothes, group03m, but those are the
-- Resistance's medics, armband and all; the owner, 1 November: a city medic in rebel clothes. A city clinic
-- has no uniform of its own in Half-Life 2, so they wear their own clothes unless an admin dresses the job.)
local DEFAULTS = {}
local OLD_MEDIC = "models/player/group03m/" .. FACE .. ".mdl"

LC.Outfits = LC.Outfits or nil

function LC.LoadOutfits()
    local t = file.Exists(FILE, "DATA") and util.JSONToTable(file.Read(FILE, "DATA") or "") or nil
    LC.Outfits = istable(t) and t or table.Copy(DEFAULTS)
    -- a server still on the old default medic outfit (the rebel medics): taken off
    local m = LC.Outfits.medic
    if istable(m) and istable(m.list) and #m.list == 1 and m.list[1].pm == OLD_MEDIC and not m.list[1].skins and not m.list[1].bg then
        LC.Outfits.medic = nil
    end
    return LC.Outfits
end

function LC.SaveOutfits()
    file.CreateDir("livingcity")
    file.Write(FILE, util.TableToJSON(LC.Outfits or {}, true))
end

local function Outfits() return LC.Outfits or LC.LoadOutfits() end

-- "male_03" from a citizen model's path (nil if it isn't one)
function LC.FaceOf(path)
    return path and string.match(string.lower(path), "((f?e?male)_%d+)%.mdl$") or nil
end

local function Hash(s) return tonumber(util.CRC(s)) or 0 end

-- A woman's model? Every female model in Half-Life 2 and the packs says "female" in its path, and no male one does.
function LC.ModelIsFemale(path) return string.find(string.lower(tostring(path or "")), "female", 1, true) ~= nil end
-- A player character's sex: from the face they chose in the creator (lc_model), else the body they're in now
-- (never from a job's clothes, which could be a uniform of either).
function LC.PlayerSex(ply)
    local own = ply:GetNW2String("lc_model", "")
    if own == "" then own = ply:GetModel() end
    return LC.ModelIsFemale(own) and "female" or "male"
end

-- The look this person wears for this job: model, skin, { bodygroup name = value }.
-- key keeps it the same person to person; face is their own face (male_03).
-- sex: "male" or "female" when it's known (the person's own record); else from their face
function LC.OutfitFor(jobId, key, face, forPlayer, sex)
    if not cvOn:GetBool() or not jobId or jobId == "" then return nil end
    local o = Outfits()[jobId]
    local list = o and o.list
    if not istable(list) or #list == 0 then return nil end
    local h = Hash(tostring(key) .. "|" .. jobId)
    local e = list[h % #list + 1]
    local path = forPlayer and e.pm or (e.npc or (e.pm and string.gsub(e.pm, "^models/player/", "models/humans/")))
    if not path or path == "" then return nil end
    -- {sex}: male or female, by the person's own face (a pack with one model of each)
    if sex ~= "male" and sex ~= "female" then sex = (face and string.sub(face, 1, 6) == "female") and "female" or "male" end
    if string.find(path, FACE, 1, true) then
        -- (no numbered face: a pack's look, like Black Mesa's; a Half-Life 2 face of their own sex)
        path = string.gsub(path, "{face}", face or (sex == "female" and "female_01" or "male_01"))
    end
    path = string.gsub(path, "{sex}", sex)
    local skin
    if istable(e.skins) and #e.skins > 0 then skin = e.skins[Hash(key .. "skin") % #e.skins + 1] end
    local bg = {}
    for name, vals in pairs(e.bg or {}) do
        if istable(vals) and #vals > 0 then bg[name] = vals[Hash(key .. name) % #vals + 1] end
    end
    return path, skin, bg
end

-- Battle gear from a clothes pack (a soldier's helmet, a welding mask): worn only by the
-- Resistance in the open, in their own gear (a rebel player not passing as a citizen, or one
-- of the rebel fighters). Anyone else's piece is left off.
local BATTLE_GEAR = { "helmet", "weld" }
local function BattleGear(name)
    name = string.lower(tostring(name or ""))
    for _, w in ipairs(BATTLE_GEAR) do if string.find(name, w, 1, true) then return true end end
    return false
end
LC.IsBattleGear = BattleGear
local function OpenRebel(ent)
    if ent:IsPlayer() then
        return ent:GetNW2String("lcf_faction", "") == "resistance" and not (LC.PassesAsCitizen and LC.PassesAsCitizen(ent))
    end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and st.role == "rebel"
end

-- Put a look on a body.
function LC.ApplyLook(ent, skin, bg)
    if not IsValid(ent) then return end
    if skin and ent.SetSkin then ent:SetSkin(skin) end
    if bg and ent.GetBodyGroups then
        local open = nil
        for _, g in ipairs(ent:GetBodyGroups() or {}) do
            local v = bg[g.name]
            if v ~= nil then
                if v > 0 and g.submodels and BattleGear(g.submodels[v] or g.name) then
                    if open == nil then open = OpenRebel(ent) end
                    if not open then v = 0 end
                end
                ent:SetBodygroup(g.id, v)
            end
        end
    end
    LC.StripBattleGear(ent)
end

-- Anything battle-like a model wears by itself (some packs' medics come with a helmet on
-- by default): off, unless it's the Resistance in the open. The bodygroup goes to its first
-- piece that isn't battle gear (usually none at all).
function LC.StripBattleGear(ent)
    if not IsValid(ent) or not ent.GetBodyGroups or not ent.GetBodygroup then return end
    local open
    for _, g in ipairs(ent:GetBodyGroups() or {}) do
        local cur = ent:GetBodygroup(g.id) or 0
        local subs = g.submodels or {}
        if BattleGear(subs[cur]) then
            if open == nil then open = OpenRebel(ent) end
            if open then return end
            for k = 0, #subs do
                if subs[k] ~= nil and not BattleGear(subs[k]) then ent:SetBodygroup(g.id, k) break end
            end
        end
    end
end

local function Valid(path) return path and (not util.IsValidModel or util.IsValidModel(path)) end

-- Work clothes only for the work (a hazmat suit: sv_livingcity_cleanup.lua): a job whose outfit says onDuty
-- is worn only on a shift (players) or while doing the job (the city's people); otherwise their own clothes.
local function DutyOnly(jobId) local o = jobId and Outfits()[jobId] return o ~= nil and o.onDuty == true end
LC.OutfitDutyOnly = DutyOnly
function LC.PlayerOnDuty(ply)
    local q = LC.QuestOf and LC.QuestOf[ply]
    return q ~= nil and q.chain == "shift"
end

-- The Black Mesa citizens pack (Workshop 534130993): when the server has it and no looks are set for
-- "Everyone else (no job)", about half the city's people without a job wear its citizens and refugees
-- (each person always the same), the rest keep their Half-Life 2 faces. Players are never changed by it.
local BMS_WSID = "534130993"
local cvBMS = CreateConVar("lc_bms_people", "50", FLAGS, "Percent of the city's people without a job who wear the Black Mesa citizens pack's looks, when the server has it (0: none)")
local BMS_NPC = { "models/humans/group01/{sex}_bms_citizen_npc.mdl", "models/humans/group02/{sex}_bms_refugee_npc.mdl" }
local BMS_PM = {
    "models/sirgibs/ragdolls/bms_citizens/male_citizen_player.mdl", "models/sirgibs/ragdolls/bms_citizens/female_citizen_player.mdl",
    "models/sirgibs/ragdolls/bms_citizens/male_refugee_player.mdl", "models/sirgibs/ragdolls/bms_citizens/female_refugee_player.mdl",
}
local function HasModel(path) return util.IsValidModel ~= nil and util.IsValidModel(path) == true end
function LC.HasBlackMesa() return HasModel("models/humans/group01/male_bms_citizen_npc.mdl") end
local bmsSkins = {}
function LC.BlackMesaLook(p, sex)
    if not p or cvBMS:GetInt() <= 0 then return nil end
    local o = Outfits()[EVERYONE]
    if o and istable(o.list) and #o.list > 0 then return nil end -- (the owner's own looks for them)
    local h = Hash("bms" .. tostring(p.id))
    if h % 100 >= cvBMS:GetInt() then return nil end
    local path = string.gsub(BMS_NPC[math.floor(h / 100) % 3 == 0 and 2 or 1], "{sex}", sex == "female" and "female" or "male") -- (a third refugees)
    if not HasModel(path) then return nil end
    if not bmsSkins[path] then
        local n = 1
        pcall(function()
            local info = util.GetModelInfo and util.GetModelInfo(path)
            n = math.max(1, tonumber(info and info.SkinCount) or 1)
        end)
        bmsSkins[path] = n
    end
    return path, Hash("bmsskin" .. tostring(p.id)) % bmsSkins[path]
end
-- Each body part the model has (a coat, a cap, glasses), picked for this person and kept.
local function OwnParts(ent, key)
    if not ent.GetBodyGroups or not ent.SetBodygroup then return end
    for _, g in ipairs(ent:GetBodyGroups() or {}) do
        local n = tonumber(g.num) or 1
        if n > 1 and g.id then ent:SetBodygroup(g.id, Hash(key .. tostring(g.name)) % n) end
    end
end
-- Joining players download the pack, or they'd see the ERROR model.
hook.Add("InitPostEntity", "LivingCityBlackMesa", function()
    if LC.HasBlackMesa() and resource and resource.AddWorkshop then resource.AddWorkshop(BMS_WSID) end
end)

-- One of the city's people, as they're put into the world (sv_livingcity_people.lua).
-- onDuty: they're at their job's work now (for an onDuty outfit; put into the world, they aren't).
function LC.DressPerson(npc, p, onDuty)
    if not IsValid(npc) or not p then return false end
    -- a height of their own (a few percent either way), the same every time
    if cvHeights:GetBool() and npc.SetModelScale then npc:SetModelScale(0.96 + (Hash("h" .. tostring(p.id)) % 81) / 1000, 0) end
    local sex = (p.gender == "female" or p.gender == "male") and p.gender or (LC.ModelIsFemale(p.model) and "female" or "male")
    local job = p.job or EVERYONE
    if DutyOnly(job) and not onDuty then
        job = EVERYONE
        if p.model and npc:GetModel() ~= p.model then npc:SetModel(p.model) if npc.SetSkin then npc:SetSkin(0) end end
    end
    local path, skin, bg = LC.OutfitFor(job, "p" .. tostring(p.id), LC.FaceOf(p.model), false, sex)
    if not Valid(path) and job == EVERYONE then
        local bms, bskin = LC.BlackMesaLook(p, sex)
        if bms then
            npc:SetModel(bms)
            if npc.SetSkin then npc:SetSkin(bskin or 0) end
            OwnParts(npc, "bms" .. tostring(p.id))
            return true
        end
    end
    if not Valid(path) then return false end
    npc:SetModel(path)
    if npc.SetBodyGroups then npc:SetBodyGroups("000000000000000") end
    LC.ApplyLook(npc, skin, bg)
    return true
end

-- A citizen player in their job's clothes.
local function PlayerLook(ply)
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" then return nil end
    local job = ply:GetNW2String("lcj_job", "")
    if job == "" or (DutyOnly(job) and not LC.PlayerOnDuty(ply)) then job = EVERYONE end
    local own = ply:GetNW2String("lc_model", "")
    return LC.OutfitFor(job, ply:GetNW2String("lc_cid", ply:SteamID()), LC.FaceOf(own), true, LC.PlayerSex(ply))
end

LC.ModelOverrides = LC.ModelOverrides or {}
LC.ModelOverrides.outfit = function(ply)
    local path = PlayerLook(ply)
    if Valid(path) then return path end
    -- no job clothes: the face they chose, if it's one the city's own list doesn't have (a pack's)
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" then return nil end
    local chosen = ply:GetNW2String("lc_model", "")
    if chosen == "" or table.HasValue(LCF and LCF.CitizenModels or {}, chosen) then return nil end
    if LC.CreatorChoice(chosen) and Valid(chosen) then return chosen end
end

-- drab shirts, one each (the default citizen playermodels tint with the player colour)
local DRAB = { Vector(0.24, 0.31, 0.44), Vector(0.34, 0.34, 0.34), Vector(0.40, 0.30, 0.20), Vector(0.30, 0.33, 0.20),
    Vector(0.20, 0.34, 0.35), Vector(0.16, 0.19, 0.28), Vector(0.42, 0.38, 0.30), Vector(0.30, 0.22, 0.22) }
function LC.CitizenTint(key) return DRAB[Hash("tint" .. tostring(key)) % #DRAB + 1] end

local function DressPlayer(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local f = ply:GetNW2String("lcf_faction", "")
    if cvTint:GetBool() and ply.SetPlayerColor and (f == "citizen" or f == "resistance") then -- (a rebel in plain clothes mustn't stand out by their shirt)
        ply:SetPlayerColor(LC.CitizenTint(ply:GetNW2String("lc_cid", ply:SteamID())))
    end
    local path, skin, bg = PlayerLook(ply)
    if not Valid(path) then
        -- their own look: the face (skin) and clothes they chose
        if f == "citizen" or f == "resistance" then
            local own = util.JSONToTable(ply:GetPData("lc_bgs", "") or "") or {}
            LC.ApplyLook(ply, tonumber(ply:GetPData("lc_skin", "")), own)
        end
        return
    end
    if ply:GetModel() ~= path and LC.RefreshModel then LC.RefreshModel(ply) end
    -- (their own look's pieces were numbered for their own model: on a job's model they turned into other
    -- things, a welding helmet on a medic; the outfit starts bare and adds only its own)
    if ply.SetBodyGroups then ply:SetBodyGroups("000000000000000") end
    LC.ApplyLook(ply, skin, bg)
end
LC.DressPlayer = DressPlayer

hook.Add("PlayerSpawn", "LivingCityOutfits", function(ply) timer.Simple(0.3, function() DressPlayer(ply) end) end)
hook.Add("LivingCityJobChanged", "LivingCityOutfits", function(ply)
    if LC.RefreshModel then LC.RefreshModel(ply) end
    timer.Simple(0, function() DressPlayer(ply) end)
end)

------------------------------------------------------------------------
-- Who you are: what the character creator offers (cl_livingcity_character.lua)
------------------------------------------------------------------------

local NOT_CITIZEN = { "police", "combine", "zombie", "corpse", "skeleton", "charple", "soldier", "hazmat", "hev" }

-- Every look a new character may choose: { path, skins (nil: any), bg (nil: any) }.
-- The "New characters choose from" looks if an admin has set them up; else
-- Half-Life 2's citizens and every installed citizen-like playermodel (named
-- male_NN or female_NN, the way citizen packs name them).
function LC.CreatorChoices()
    local out, seen = {}, {}
    local function Add(path, skins, bg)
        if path and not seen[path] then seen[path] = true out[#out + 1] = { path = path, skins = skins, bg = bg } end
    end
    local o = Outfits()[CREATOR]
    if o and istable(o.list) and #o.list > 0 then
        for _, e in ipairs(o.list) do
            if e.pm and string.find(e.pm, FACE, 1, true) then
                for _, m in ipairs(LCF and LCF.CitizenModels or {}) do
                    local face = LC.FaceOf(m)
                    if face then Add((string.gsub(e.pm, "{face}", face)), e.skins, e.bg) end
                end
            else
                Add(e.pm, istable(e.skins) and #e.skins > 0 and e.skins or nil, e.bg)
            end
        end
        return out
    end
    for _, m in ipairs(LCF and LCF.CitizenModels or {}) do Add(m) end
    local extra = {}
    for _, path in pairs(player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}) do
        local low = string.lower(path)
        local bad = false
        for _, w in ipairs(NOT_CITIZEN) do if string.find(low, w, 1, true) then bad = true break end end
        if not bad and LC.FaceOf(low) and not string.find(low, "models/player/group0", 1, true)
            and (not util.IsValidModel or util.IsValidModel(path)) then extra[#extra + 1] = path end -- (a pack missing its files: never offered)
    end
    table.sort(extra)
    for _, p in ipairs(extra) do Add(p) end
    -- the Black Mesa citizens and refugees, if the server has the pack (its names aren't male_NN)
    for _, p in ipairs(BMS_PM) do if HasModel(p) then Add(p) end end
    return out
end

-- Joining players get the Workshop packs the creator's looks come from (or
-- they'd see the ERROR model). Legacy folder packs can't be sent this way:
-- those need FastDL, or the players subscribed to them.
local function SendCreatorPacks()
    if not (engine and engine.GetAddons and resource and resource.AddWorkshop) then return end
    local paths = {}
    for _, c in ipairs(LC.CreatorChoices()) do
        if c.path and not string.find(string.lower(c.path), "models/player/group0", 1, true) then paths[#paths + 1] = c.path end
    end
    if #paths == 0 then return end
    for _, a in ipairs(engine.GetAddons()) do
        local id = tostring(a.wsid or "")
        if a.mounted ~= false and id ~= "" and id ~= "0" and a.title then
            for _, p in ipairs(paths) do
                if file.Exists(p, a.title) then resource.AddWorkshop(id) break end
            end
        end
    end
end
hook.Add("InitPostEntity", "LivingCityCreatorPacks", SendCreatorPacks)

function LC.CreatorChoice(path)
    for _, c in ipairs(LC.CreatorChoices()) do if c.path == path then return c end end
    return nil
end

-- A chosen skin and bodygroups, kept to what this look allows.
function LC.CleanLook(path, skin, bg)
    local c = LC.CreatorChoice(path)
    if not c then return nil end
    skin = tonumber(skin) and math.Clamp(math.floor(tonumber(skin)), 0, 63) or 0
    if c.skins and not table.HasValue(c.skins, skin) then skin = c.skins[1] or 0 end
    local out = {}
    for name, v in pairs(istable(bg) and bg or {}) do
        v = tonumber(v)
        if isstring(name) and v then
            v = math.Clamp(math.floor(v), 0, 31)
            local allowed = c.bg and c.bg[name]
            if not c.bg or (allowed and table.HasValue(allowed, v)) then out[string.sub(name, 1, 64)] = v end
        end
    end
    return skin, out
end

-- Kept with the person (sv_livingcity_slots.lua keeps lc_skin and lc_bgs per character).
function LC.SetLook(ply, skin, bg)
    ply:SetPData("lc_skin", tostring(skin or 0))
    ply:SetPData("lc_bgs", util.TableToJSON(bg or {}))
    ply:SetNW2Int("lc_skin", skin or 0)
    timer.Simple(0.1, function() if IsValid(ply) then LC.DressPlayer(ply) end end)
end

hook.Add("LivingCityNewCharacter", "LivingCityOutfitsLook", function(ply)
    ply:RemovePData("lc_skin")
    ply:RemovePData("lc_bgs")
end)

------------------------------------------------------------------------
-- The designer (cl_livingcity_outfits.lua)
------------------------------------------------------------------------

function LC.OpenOutfits(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return false end
    local jobs = {}
    for _, o in ipairs(LCJ and LCJ.Occupations or {}) do jobs[#jobs + 1] = { id = o.id, name = o.name } end
    jobs[#jobs + 1] = { id = EVERYONE, name = "Everyone else (no job)" }
    jobs[#jobs + 1] = { id = CREATOR, name = "New characters choose from" }
    LC.SendCompressed("lc_outfits_open", { jobs = jobs, outfits = Outfits() }, ply)
    return true
end

-- What the designer sends back for one job, cleaned up.
function LC.SetOutfit(ply, jobId, list)
    if IsValid(ply) and not ply:IsAdmin() then return false, "Admins only." end
    if jobId ~= EVERYONE and jobId ~= CREATOR and not (LCJ and LCJ.ById[jobId]) then return false, "No such job." end
    local clean = {}
    for _, e in ipairs(istable(list) and list or {}) do
        if istable(e) and isstring(e.pm) and e.pm ~= "" and #clean < 16 then
            local c = { pm = string.sub(e.pm, 1, 200), npc = isstring(e.npc) and e.npc ~= "" and string.sub(e.npc, 1, 200) or nil, skins = {}, bg = {} }
            for _, n in ipairs(istable(e.skins) and e.skins or {}) do if tonumber(n) then c.skins[#c.skins + 1] = math.floor(tonumber(n)) end end
            for name, vals in pairs(istable(e.bg) and e.bg or {}) do
                if isstring(name) and istable(vals) then
                    local v = {}
                    for _, n in ipairs(vals) do if tonumber(n) then v[#v + 1] = math.floor(tonumber(n)) end end
                    if #v > 0 then c.bg[string.sub(name, 1, 64)] = v end
                end
            end
            clean[#clean + 1] = c
        end
    end
    Outfits()[jobId] = { list = clean }
    LC.SaveOutfits()
    -- everyone dresses again
    local function Has(j) return (j ~= nil and j ~= "" and j or EVERYONE) == jobId end
    for _, p in ipairs(player.GetAll()) do if Has(p:GetNW2String("lcj_job", "")) then DressPlayer(p) end end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.profile and Has(st.profile.job) then LC.DressPerson(npc, st.profile) end
    end
    return true
end

net.Receive("lc_outfits_save", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local len = net.ReadUInt(32)
    local raw = util.Decompress(net.ReadData(len) or "") or ""
    local t = util.JSONToTable(raw)
    if not istable(t) then return end
    local ok, why = LC.SetOutfit(ply, tostring(t.job or ""), t.list)
    ply:ChatPrint("[Outfits] " .. (ok and "Saved. Everyone with that job dresses the part now." or (why or "Not saved.")))
end)

-- (not "lc_outfits": that name is the on/off setting, and a setting and a command can't share a name)
concommand.Add("lc_outfits_edit", function(ply) if IsValid(ply) and not LC.OpenOutfits(ply) then ply:ChatPrint("Admins only.") end end)
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.outfits = function(ply) if not LC.OpenOutfits(ply) then ply:ChatPrint("Admins only.") end end

------------------------------------------------------------------------
-- Into the work clothes for the work, and out of them after (onDuty outfits)
------------------------------------------------------------------------

local OFF_GRACE = 90 -- (seconds between one task and the next before the city's people change back)
local function DutyTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local job = ply:GetNW2String("lcj_job", "")
        local want = job ~= "" and DutyOnly(job) and LC.PlayerOnDuty(ply) or false
        if ply.lcDutyDressed ~= want and ply:Alive() then
            local was = ply.lcDutyDressed
            ply.lcDutyDressed = want
            if was ~= nil or want then
                if LC.RefreshModel then LC.RefreshModel(ply) end
                DressPlayer(ply)
                if ply.SetupHands then ply:SetupHands() end
            end
        end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        local p = st.profile
        if IsValid(npc) and p and p.job and DutyOnly(p.job) then
            local want
            if st.npcWork then
                want, st.lcOffSince = true, nil
            else
                st.lcOffSince = st.lcOffSince or now
                -- (only off the shift for good: in bed or leaving. Curfew and bedtime used to undress a worker
                -- between two bins, so the sanitation worker flipped models after every one: the owner, 7 November)
                local home = st.state == "abed" or st.leaving
                want = st.lcDuty == true and not home and now - st.lcOffSince < OFF_GRACE
            end
            if want ~= (st.lcDuty == true) then
                st.lcDuty = want
                LC.DressPerson(npc, p, want)
            end
        end
    end
end
LC.OutfitDutyTick = DutyTick
timer.Create("LivingCityDutyClothes", 2, 0, function()
    local ok, err = pcall(DutyTick, CurTime())
    if not ok and LC.Error then LC.Error("duty clothes", err) end
end)
