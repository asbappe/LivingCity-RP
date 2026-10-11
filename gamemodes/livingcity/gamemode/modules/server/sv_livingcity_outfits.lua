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
    skins and bodygroup pieces that fit, add it, save. The Clinic Medic
    starts out in Half-Life 2's own medic clothes.

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
local FACE = "{face}" -- (in a model path: the person's own face, male_03 and so on)

-- Each job: { list = { { pm = player model, npc = NPC model (optional), skins = { n, ... }, bg = { [name] = { n, ... } } } } }
local DEFAULTS = {
    medic = { list = { { pm = "models/player/group03m/" .. FACE .. ".mdl", npc = "models/humans/group03m/" .. FACE .. ".mdl" } } },
}

LC.Outfits = LC.Outfits or nil

function LC.LoadOutfits()
    local t = file.Exists(FILE, "DATA") and util.JSONToTable(file.Read(FILE, "DATA") or "") or nil
    LC.Outfits = istable(t) and t or table.Copy(DEFAULTS)
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

-- The look this person wears for this job: model, skin, { bodygroup name = value }.
-- key keeps it the same person to person; face is their own face (male_03).
function LC.OutfitFor(jobId, key, face, forPlayer)
    if not cvOn:GetBool() or not jobId or jobId == "" then return nil end
    local o = Outfits()[jobId]
    local list = o and o.list
    if not istable(list) or #list == 0 then return nil end
    local h = Hash(tostring(key) .. "|" .. jobId)
    local e = list[h % #list + 1]
    local path = forPlayer and e.pm or (e.npc or (e.pm and string.gsub(e.pm, "^models/player/", "models/humans/")))
    if not path or path == "" then return nil end
    if string.find(path, FACE, 1, true) then
        path = string.gsub(path, "{face}", face or "male_01")
    end
    local skin
    if istable(e.skins) and #e.skins > 0 then skin = e.skins[Hash(key .. "skin") % #e.skins + 1] end
    local bg = {}
    for name, vals in pairs(e.bg or {}) do
        if istable(vals) and #vals > 0 then bg[name] = vals[Hash(key .. name) % #vals + 1] end
    end
    return path, skin, bg
end

-- Put a look on a body.
function LC.ApplyLook(ent, skin, bg)
    if not IsValid(ent) then return end
    if skin and ent.SetSkin then ent:SetSkin(skin) end
    if bg and ent.GetBodyGroups then
        for _, g in ipairs(ent:GetBodyGroups() or {}) do
            if bg[g.name] ~= nil then ent:SetBodygroup(g.id, bg[g.name]) end
        end
    end
end

local function Valid(path) return path and (not util.IsValidModel or util.IsValidModel(path)) end

-- One of the city's people, as they're put into the world (sv_livingcity_people.lua).
function LC.DressPerson(npc, p)
    if not IsValid(npc) or not p then return false end
    -- a height of their own (a few percent either way), the same every time
    if cvHeights:GetBool() and npc.SetModelScale then npc:SetModelScale(0.96 + (Hash("h" .. tostring(p.id)) % 81) / 1000, 0) end
    local path, skin, bg = LC.OutfitFor(p.job or EVERYONE, "p" .. tostring(p.id), LC.FaceOf(p.model), false)
    if not Valid(path) then return false end
    npc:SetModel(path)
    LC.ApplyLook(npc, skin, bg)
    return true
end

-- A citizen player in their job's clothes.
local function PlayerLook(ply)
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" then return nil end
    local job = ply:GetNW2String("lcj_job", "")
    if job == "" then job = EVERYONE end
    return LC.OutfitFor(job, ply:GetNW2String("lc_cid", ply:SteamID()), LC.FaceOf(ply:GetNW2String("lc_model", "")), true)
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
        if not bad and LC.FaceOf(low) and not string.find(low, "models/player/group0", 1, true) then extra[#extra + 1] = path end
    end
    table.sort(extra)
    for _, p in ipairs(extra) do Add(p) end
    return out
end

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

concommand.Add("lc_outfits", function(ply) if IsValid(ply) then LC.OpenOutfits(ply) end end)
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.outfits = function(ply) if not LC.OpenOutfits(ply) then ply:ChatPrint("Admins only.") end end
