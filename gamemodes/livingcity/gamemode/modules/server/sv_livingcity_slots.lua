--[[
    Living City: character slots

    A player can have several people in the city (lc_char_slots, 3), and
    switch between them: !characters (or !chars) opens the list. Each one is
    a whole life of its own: name, number and face, description, who they
    know, credits, standing, faction and rank in every faction, Union job,
    pockets, stash, housing block, story and traits, and the record Civil
    Protection keeps on them.

    Switching is like walking off and somebody else walking on: you respawn
    as them. Not while you're wanted, in custody, down, tied up, in a fight
    or on a job, and not more often than lc_char_switch_cooldown seconds
    (300; admins can switch at will).

    Permanent death still applies to whoever you're playing: when they die,
    that slot gets a new person. The other slots are untouched.

    What belongs to the player and not the person stays the same whoever
    you play: conduct strikes, the combat log, tips you've seen, whitelists.
]]

if CLIENT then return end

util.AddNetworkString("lc_slots")
util.AddNetworkString("lc_slots_do")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSlots = CreateConVar("lc_char_slots", "3", FLAGS, "How many characters each player can have (1 turns character slots off)")
local cvWait  = CreateConVar("lc_char_switch_cooldown", "300", FLAGS, "Seconds between switching characters")

-- Everything that belongs to one person, as saved data.
local function CharKeys()
    local map = game.GetMap()
    local keys = {
        "lc_char", "lc_cid", "lc_model", "lc_chosen", "lc_desc", "lc_recog", "lc_lived", "lc_lived_full", "lc_intake", "lc_registered",
        "lce_credits", "lce_standing", "lcf_faction", "lcf_special", "lci_inv", "lci_stash_" .. map, "lc_block_" .. map,
        "lcj_job", "lcq_story", "lcq_done", "lcq_loyalty", "lcq_sympathy", "lcq_corruption", "lc_notes",
        "lc_docs", "lc_housed_how", "lc_transfer_at",
    }
    for _, f in ipairs(LCF and LCF.Factions or {}) do keys[#keys + 1] = "lcf_xp_" .. f.id end
    return keys
end
LC.CharKeys = CharKeys

local function Meta(ply)
    if not ply.lcSlotMeta then
        local t = util.JSONToTable(ply:GetPData("lc_slots", "") or "") or {}
        t.active = tonumber(t.active) or 1
        t.slots = istable(t.slots) and t.slots or {}
        -- JSON turns numbered keys into strings
        local fixed = {}
        for k, v in pairs(t.slots) do fixed[tonumber(k) or k] = v end
        t.slots = fixed
        ply.lcSlotMeta = t
    end
    return ply.lcSlotMeta
end

local function SaveMeta(ply) ply:SetPData("lc_slots", util.TableToJSON(Meta(ply))) end

function LC.ActiveSlot(ply) return Meta(ply).active end

-- A short summary of who's in the active slot right now.
local function Summary(ply)
    local f = LCF and LCF.Get and LCF.Get(ply:GetNW2String("lcf_faction", "citizen"))
    local rank = f and f.ranks[ply:GetNW2Int("lcf_rank", 1)]
    return {
        name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick(), cid = ply:GetNW2String("lc_cid", ""),
        model = ply:GetNW2String("lc_model", ""), faction = f and f.name or "Citizen", rank = rank and rank.name or nil,
        credits = LC.Credits and LC.Credits(ply) or nil, standing = LC.Standing and LC.Standing(ply) or nil, last = os.time(),
    }
end

local function Capture(ply)
    local snap = {}
    for _, k in ipairs(CharKeys()) do
        local v = ply:GetPData(k, nil)
        if v ~= nil then snap[k] = v end
    end
    snap._hunger = ply:GetNW2Float("lcn_hunger", 100)
    snap._thirst = ply:GetNW2Float("lcn_thirst", 100)
    return snap
end

local function Restore(ply, snap)
    for _, k in ipairs(CharKeys()) do
        if snap and snap[k] ~= nil then ply:SetPData(k, snap[k]) else ply:RemovePData(k) end
    end
    ply.lcIntakeState, ply.lcDocs = nil, nil -- (their papers and room: sv_livingcity_intake.lua reads them again)
end

-- Everything held in memory for the old person, thrown away and read again.
local function Reload(ply, snap)
    ply.lcInv, ply.lcStash, ply.lcStashMap = nil, nil, nil
    ply.lcStory, ply.lcStoryPostings = nil, nil
    ply.lcRecog = nil
    ply.lcNotes = nil
    ply.lcIdentity = nil
    ply:SetNW2String("lcd_alias", "")
    ply:SetNW2String("lcd_disguise", "")
    ply:SetNW2Bool("lc_handsup", false)
    ply:SetNW2String("lc_char", ply:GetPData("lc_char", ""))
    ply:SetNW2String("lc_cid", ply:GetPData("lc_cid", ""))
    ply:SetNW2String("lc_model", ply:GetPData("lc_model", ""))
    ply:SetNW2String("lc_desc", ply:GetPData("lc_desc", ""))
    ply:SetNW2String("lcj_job", ply:GetPData("lcj_job", ""))
    ply:SetNW2Int("lce_credits", LC.Credits and LC.Credits(ply) or 0)
    ply:SetNW2Int("lce_standing", LC.Standing and LC.Standing(ply) or 0)
    ply:SetNW2Float("lcn_hunger", snap and tonumber(snap._hunger) or 80)
    ply:SetNW2Float("lcn_thirst", snap and tonumber(snap._thirst) or 80)
    ply:SetNW2Float("lcn_parasites", 0)
    if LC.ClearWanted then LC.ClearWanted(ply) end
    if LC.AssignBlock then LC.AssignBlock(ply) end
    if LC.SendInv then LC.SendInv(ply) end
    -- this person's faction, and their special role if there's still a place in it
    local fid, sid = "citizen", nil
    if LC.SavedFaction then fid, sid = LC.SavedFaction(ply) end
    if LC.SetFaction then
        LC.SetFaction(ply, fid, sid, true) -- respawns them as this person
    else
        ply:Spawn()
    end
    hook.Run("LivingCityCharacterSwitched", ply)
end

-- Can this player switch right now? ok, or false and why.
function LC.CanSwitchCharacter(ply)
    if cvSlots:GetInt() < 2 then return false, "Character slots are off on this server." end
    if not ply:Alive() then return false, "Not while you're dead." end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return false, "Not while you're wanted." end
    if (LC.InCustody and LC.InCustody(ply)) or (LC.Prisoners and LC.Prisoners[ply]) then return false, "Not while you're in custody." end
    if LC.IsDowned and LC.IsDowned(ply) then return false, "Not while you're down." end
    if LC.IsTied and LC.IsTied(ply) then return false, "Not with your hands tied." end
    if LC.InCombat and LC.InCombat(ply) then return false, "Not in the middle of a fight." end
    if LC.QuestOf and LC.QuestOf[ply] then return false, "Finish or abandon your job first (!abandon)." end
    if (ply.lcSlotNext or 0) > CurTime() and not ply:IsAdmin() then
        return false, string.format("You can switch again in %ds.", math.ceil(ply.lcSlotNext - CurTime()))
    end
    return true
end

function LC.SwitchCharacter(ply, n)
    n = math.floor(tonumber(n) or 0)
    if n < 1 or n > cvSlots:GetInt() then return false, "No such slot." end
    local m = Meta(ply)
    if n == m.active then return false, "You're already playing them." end
    local ok, why = LC.CanSwitchCharacter(ply)
    if not ok then return false, why end
    -- put the current person away
    if LC.FlushLived then LC.FlushLived(ply) end -- (their time in the city, up to now)
    m.slots[m.active] = Summary(ply)
    ply:SetPData("lc_slot_" .. m.active, util.TableToJSON(Capture(ply)))
    -- and bring the other one out
    local raw = ply:GetPData("lc_slot_" .. n, "")
    local snap = raw ~= "" and util.JSONToTable(raw) or nil
    Restore(ply, snap)
    m.active = n
    local fresh = snap == nil
    if fresh then
        -- somebody new in the city
        if LC.AssignNewCharacter then LC.AssignNewCharacter(ply) end
        ply:SetPData("lc_chosen", "0")
        if LC.AssignBlock then LC.AssignBlock(ply, true) end
    end
    SaveMeta(ply)
    ply.lcSlotNext = CurTime() + cvWait:GetFloat()
    Reload(ply, snap)
    m.slots[n] = Summary(ply)
    SaveMeta(ply)
    if fresh then
        ply:ChatPrint(string.format("[Living City] You are someone new: %s, citizen %s.", LC.CharacterName(ply), ply:GetNW2String("lc_cid", "")))
        if LC.OpenCharacterCreator then timer.Simple(0.5, function() if IsValid(ply) then LC.OpenCharacterCreator(ply) end end) end
    else
        ply:ChatPrint(string.format("[Living City] You are %s, citizen %s.", LC.CharacterName(ply), ply:GetNW2String("lc_cid", "")))
    end
    LC.Log("info", string.format("%s switched to slot %d (%s)", ply:Nick(), n, LC.CharacterName(ply)))
    return true
end

function LC.DeleteCharacterSlot(ply, n)
    n = math.floor(tonumber(n) or 0)
    local m = Meta(ply)
    if n == m.active then return false, "You can't delete the person you're playing. Switch to someone else first." end
    if not m.slots[n] then return false, "That slot is empty." end
    local snap = util.JSONToTable(ply:GetPData("lc_slot_" .. n, "") or "")
    hook.Run("LivingCityCharacterDeleted", ply, istable(snap) and snap.lc_cid or nil)
    m.slots[n] = nil
    ply:RemovePData("lc_slot_" .. n)
    SaveMeta(ply)
    return true, "Gone. Nobody in the city remembers them."
end

function LC.SendSlots(ply)
    local m = Meta(ply)
    m.slots[m.active] = Summary(ply)
    local can, why = LC.CanSwitchCharacter(ply)
    local list = {}
    for i = 1, math.max(1, cvSlots:GetInt()) do list[i] = m.slots[i] or false end
    LC.SendCompressed("lc_slots", { active = m.active, slots = list, can = can or nil, why = why }, ply)
end

net.Receive("lc_slots_do", function(_, ply)
    local action, n = net.ReadString(), net.ReadString()
    local ok, msg
    if action == "play" then ok, msg = LC.SwitchCharacter(ply, n)
    elseif action == "delete" then ok, msg = LC.DeleteCharacterSlot(ply, n) end
    if msg then ply:ChatPrint("[Characters] " .. msg) end
    if action ~= "play" or not ok then LC.SendSlots(ply) end
end)

-- The person who died keeps their slot; the slot gets the new person.
hook.Add("LivingCityNewCharacter", "LivingCitySlots", function(ply)
    local m = Meta(ply)
    timer.Simple(0, function() if IsValid(ply) then m.slots[m.active] = Summary(ply) SaveMeta(ply) end end)
end)

hook.Add("PlayerSay", "LivingCitySlotsChat", function(ply, text)
    local t = string.lower(string.Trim(text or ""))
    if t == "!characters" or t == "!chars" or t == "!charselect" or t == "/characters" then
        if cvSlots:GetInt() < 2 then
            ply:ChatPrint("Character slots are off on this server. C > Me > Change my name and face.")
        else
            LC.SendSlots(ply)
        end
        return ""
    end
end)
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.characters = function(ply) LC.SendSlots(ply) end
LC.SlashCommands.chars = LC.SlashCommands.characters
concommand.Add("lc_characters", function(ply) if IsValid(ply) then LC.SendSlots(ply) end end)
