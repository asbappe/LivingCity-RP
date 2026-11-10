--[[
    Living City: things other people can see (the owner, 10 November:
    "citizen goals: status symbols", "I love it all").

      Fine clothes  (the Commissary, Trusted citizens, 120 credits): put on
                    from your pockets, you wear the better-dressed citizen
                    clothes, and "Well dressed" shows with your title. Take
                    them off the same way (or a job's clothes replace them).
      Home decor    (the Commissary: a potted cactus, a desk lamp, a picture
                    frame, an armchair, a radio set): use it from your pockets
                    while in your own block, and it's set down where you're
                    looking. It stays, across restarts, for anyone to see.
                    E on your own piece takes it back into your pockets.
                    At most lc_decor_max (6) each.
      A radio set   placed like decor; E on it (anyone) plays music, again
                    to stop. Its owner crouches and presses E to take it back.
      A pet bird    (the Commissary, standing 100, 80 credits): a tame pigeon
                    that rides on your shoulder (use it from your pockets: on,
                    off). Everyone sees it.

      lc_decor_max (6)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvMax = CreateConVar("lc_decor_max", "6", FLAGS, "Pieces of home decor (and radio sets) one person can have placed at once")
CreateConVar("lc_petbird_pos", "-1 3 5", FLAGS, "Where a pet bird sits on the shoulder: forward right up (cl_livingcity_petbird.lua)")

LC.ItemUseHandlers = LC.ItemUseHandlers or {}

local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function Key(p) return (p.SteamID64 and p:SteamID64() or tostring(p)) .. ":" .. (p.GetPData and p:GetPData("lc_cid", "") or "") end

------------------------------------------------------------------------
-- Fine clothes
------------------------------------------------------------------------

local FINE = {
    male = { "models/player/group02/male_02.mdl", "models/player/group02/male_04.mdl", "models/player/group02/male_06.mdl", "models/player/group02/male_08.mdl" },
    female = { "models/player/group02/female_02.mdl", "models/player/group02/female_04.mdl", "models/player/group02/female_06.mdl" },
}
local function Valid(m) return util.IsValidModel == nil or util.IsValidModel(m) end

-- The better-dressed version of this face: the same number in the group02 set, else the nearest there is.
function LC.FineModelFor(model)
    model = string.lower(model or "")
    local try = string.gsub(model, "group01", "group02")
    if try ~= model and Valid(try) then return try end
    local list = string.find(model, "female", 1, true) and FINE.female or FINE.male
    for _, m in ipairs(list) do if Valid(m) then return m end end
    return nil
end

local function ShowTitle(ply)
    if LC.LegacyTitle then ply:SetNW2String("lc_legacy_title", (LC.LegacyTitle(ply))) end
end

LC.ItemUseHandlers.finery = function(ply)
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return false, "Not over a uniform." end
    if ply.lcFineFrom then
        if Valid(ply.lcFineFrom) then ply:SetModel(ply.lcFineFrom) end
        ply.lcFineFrom = nil
        ply:SetNW2Bool("lc_well_dressed", false)
        ShowTitle(ply)
        ply:ChatPrint("[Living City] You take off the fine clothes and fold them away.")
        return true
    end
    local fine = LC.FineModelFor(ply:GetModel())
    if not fine then return false, "They don't fit you." end
    ply.lcFineFrom = ply:GetModel()
    ply:SetModel(fine)
    ply:SetNW2Bool("lc_well_dressed", true)
    ShowTitle(ply)
    ply:ChatPrint("[Living City] You put on the fine clothes. People will notice.")
    return true
end
hook.Add("PlayerSpawn", "LivingCityFinery", function(ply) ply.lcFineFrom = nil ply:SetNW2Bool("lc_well_dressed", false) end)

-- "Well dressed" with their title.
local wrapped = false
local function Wrap()
    if wrapped or not LC.LegacyTitle then return end
    wrapped = true
    local orig = LC.LegacyTitle
    LC.LegacyTitle = function(ply, ...)
        local t, lives = orig(ply, ...)
        if IsValid(ply) and ply:GetNW2Bool("lc_well_dressed", false) then t = (t and t ~= "") and ("Well dressed, " .. t) or "Well dressed" end
        return t, lives
    end
end
hook.Add("Initialize", "LivingCityStatus", Wrap)
timer.Simple(0, Wrap)

------------------------------------------------------------------------
-- A pet bird
------------------------------------------------------------------------

LC.ItemUseHandlers.petbird = function(ply)
    local on = not ply:GetNW2Bool("lc_pet_bird", false)
    ply:SetNW2Bool("lc_pet_bird", on)
    ply:EmitSound(on and "ambient/creatures/pigeon_idle" .. math.random(1, 4) .. ".wav" or "npc/crow/alert2.wav", 60)
    ply:ChatPrint(on and "[Living City] Your bird hops onto your shoulder." or "[Living City] Your bird hops back into your coat.")
    return true
end
hook.Add("PlayerDeath", "LivingCityPetBird", function(ply) ply:SetNW2Bool("lc_pet_bird", false) end)
hook.Add("LivingCityInventoryChanged", "LivingCityPetBird", function(ply)
    if IsValid(ply) and ply:GetNW2Bool("lc_pet_bird", false) and not (LC.HasItem and LC.HasItem(ply, "pet_bird")) then ply:SetNW2Bool("lc_pet_bird", false) end
end)

------------------------------------------------------------------------
-- Home decor and the radio set
------------------------------------------------------------------------

LC.Decor = LC.Decor or {} -- { { ent, item, owner (key), name, pos, ang } }
local function File() return "livingcity/" .. game.GetMap() .. "_decor.json" end

local function SaveDecor()
    if not file or not file.Write then return end
    local out = {}
    for _, d in ipairs(LC.Decor) do
        local e = d.ent
        local pos = IsValid(e) and e:GetPos() or d.pos
        local ang = IsValid(e) and e:GetAngles() or d.ang
        out[#out + 1] = { item = d.item, owner = d.owner, name = d.name, x = pos.x, y = pos.y, z = pos.z, p = ang.p, yw = ang.y, r = ang.r }
    end
    if file.CreateDir then file.CreateDir("livingcity") end
    if LC.SafeWrite then LC.SafeWrite(File(), util.TableToJSON(out)) end
end
LC.SaveDecor = SaveDecor

local function Spawn(d)
    local it = LCS.Items[d.item]
    if not it then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(it.model)
    e:SetPos(d.pos)
    e:SetAngles(d.ang)
    e:Spawn()
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcDecor = d
    e:SetNW2String("lc_decor_owner", d.name or "")
    e:SetNW2String("lc_decor_item", d.item)
    d.ent = e
    return e
end

local function Count(key)
    local n = 0
    for _, d in ipairs(LC.Decor) do if d.owner == key and IsValid(d.ent) then n = n + 1 end end
    return n
end

LC.ItemUseHandlers.decor = function(ply, id)
    if not (LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply)) then return false, "Set it down at home: in your own block." end
    local key = Key(ply)
    if Count(key) >= cvMax:GetInt() then return false, string.format("You have %d things set out at home already. Take one back first (E on it).", cvMax:GetInt()) end
    local tr = ply:GetEyeTrace()
    if not tr or not tr.Hit or tr.HitPos:DistToSqr(ply:EyePos()) > 160 * 160 then return false, "Look at where you want it, close by." end
    if not LC.TakeItem(ply, id, 1) then return false end
    local d = { item = id, owner = key, name = Name(ply), pos = tr.HitPos + tr.HitNormal * 4, ang = Angle(0, ply:EyeAngles().y + 180, 0) }
    if not Spawn(d) then LC.GiveItem(ply, id, 1) return false, "It won't stand there." end
    LC.Decor[#LC.Decor + 1] = d
    SaveDecor()
    ply:ChatPrint("[Home] " .. LCS.Items[id].name .. " set down. E on it to take it back.")
    hook.Run("LivingCityDecorPlaced", ply, d)
    return true
end

-- E on a piece: the owner takes it back; a radio set plays or stops for anyone.
local SONGS = { "music/hl2_song12_long.mp3", "music/hl2_song20_submix0.mp3", "music/hl1_song10.mp3", "music/hl2_song33.mp3" }
function LC.UseDecor(ply, e)
    local d = IsValid(e) and e.lcDecor
    if not d then return false end
    -- a radio set: E plays or stops it, for anyone; its owner crouches and presses E to take it back
    if d.item == "radio_set" and not (d.owner == Key(ply) and ply.Crouching and ply:Crouching()) then
        if e.lcSong then
            e:StopSound(e.lcSong)
            e.lcSong = nil
            e:EmitSound("buttons/lightswitch2.wav", 60)
        else
            e.lcSong = SONGS[math.random(#SONGS)]
            e:EmitSound("buttons/lightswitch2.wav", 60)
            e:EmitSound(e.lcSong, 62, 100, 0.6)
        end
        return true
    end
    if d.owner ~= Key(ply) then
        ply:ChatPrint("[Home] " .. (d.name ~= "" and (d.name .. "'s") or "Someone's") .. ". Not yours to take.")
        return true
    end
    if e.lcSong then e:StopSound(e.lcSong) end
    for i, x in ipairs(LC.Decor) do if x == d then table.remove(LC.Decor, i) break end end
    e:Remove()
    LC.GiveItem(ply, d.item, 1)
    SaveDecor()
    ply:ChatPrint("[Home] Back in your pockets.")
    return true
end
hook.Add("PlayerUse", "LivingCityDecor", function(ply, e)
    if IsValid(e) and e.lcDecor then
        if (ply.lcDecorUse or 0) > CurTime() then return false end
        ply.lcDecorUse = CurTime() + 0.6
        LC.UseDecor(ply, e)
        return false
    end
end)

-- Back where they were, after a restart.
function LC.LoadDecor()
    for _, d in ipairs(LC.Decor) do if IsValid(d.ent) then d.ent:Remove() end end
    LC.Decor = {}
    local t = LC.SafeReadJSON and LC.SafeReadJSON(File())
    for _, r in ipairs(istable(t) and t or {}) do
        local d = { item = r.item, owner = r.owner, name = r.name, pos = Vector(r.x or 0, r.y or 0, r.z or 0), ang = Angle(r.p or 0, r.yw or 0, r.r or 0) }
        if Spawn(d) then LC.Decor[#LC.Decor + 1] = d end
    end
end
hook.Add("InitPostEntity", "LivingCityDecor", function() timer.Simple(5, LC.LoadDecor) end)
hook.Add("PostCleanupMap", "LivingCityDecor", function() timer.Simple(1, LC.LoadDecor) end)
