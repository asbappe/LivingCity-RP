--[[
    Living City: households (the owner, 10 November: "shared households:
    roommates, family, a shared stash"; "I love it all").

    A citizen (or a Resistance member, on paper a citizen) can take others
    into their household: F1, looking at them, "Invite (name) into my
    household"; they accept on F2 > Me (More) > My household within two minutes.
    Members of a household:
      - live in the same block as its head (moved there when they join)
      - share their storage crates and lockers: each can open the others'
      - have keys to the head's apartment, if they rent one
      - know each other by name
    and the household has a name ("the Vornholt household", the head's
    surname, which the head can change), shown on F2 > Me (More) > My household and
    in Where I stand. Anyone can leave (F2 > Me (More) > My household > Leave); the
    head can send someone away; a household of one is no household. Up to
    lc_household_max (6) people. Kept in data/livingcity/households.json,
    each character in one household at most.

      lc_households 0/1, lc_household_max (6)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn  = CreateConVar("lc_households", "1", FLAGS, "Citizens can make a household: the same block, shared crates and lockers, keys, known to each other")
local cvMax = CreateConVar("lc_household_max", "6", FLAGS, "People in one household at most")

local FILE = "livingcity/households.json"
local H -- { [id] = { name, head = cid, members = { [cid] = name } } }
local INVITE_SECS = 120

local function CID(p) local c = IsValid(p) and p:GetNW2String("lc_cid", "") or "" return c ~= "" and c or nil end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function Citizenish(p) local f = p:GetNW2String("lcf_faction", "") return f == "" or f == "citizen" or f == "resistance" end
local function ByCID(cid) for _, p in ipairs(player.GetAll()) do if CID(p) == cid then return p end end end

local function Load()
    if H then return H end
    local t = LC.SafeReadJSON and LC.SafeReadJSON(FILE)
    H = istable(t) and t or {}
    return H
end
local function Save()
    if not file or not file.Write then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    if LC.SafeWrite then LC.SafeWrite(FILE, util.TableToJSON(Load())) end
end
function LC.HouseholdsReload() H = nil return Load() end

-- The household this person is in: id, record.
function LC.HouseholdOf(ply)
    local cid = CID(ply)
    if not cid then return nil end
    for id, h in pairs(Load()) do if h.members[cid] then return id, h end end
    return nil
end

local function Surname(name)
    local last = string.match(tostring(name or ""), "(%S+)%s*$")
    return last or "Unnamed"
end

local function Sync(ply)
    local id, h = LC.HouseholdOf(ply)
    if not h then ply:SetNW2String("lc_household", "") return end
    local list = {}
    for cid, n in pairs(h.members) do list[#list + 1] = { n = n, head = (cid == h.head) or nil, here = IsValid(ByCID(cid)) or nil } end
    table.sort(list, function(a, b) return (a.head and 1 or 0) > (b.head and 1 or 0) end)
    ply:SetNW2String("lc_household", util.TableToJSON({ name = h.name, head = h.head == CID(ply) or nil, members = list }) or "")
end
LC.HouseholdSync = Sync
local function SyncAll() for _, p in ipairs(player.GetAll()) do Sync(p) end end

-- Do these two share a household? (by character id: sv_livingcity_storage.lua asks for crates and lockers)
function LC.HouseholdShares(ply, ownerCid)
    if not cvOn:GetBool() or not ownerCid then return false end
    local _, h = LC.HouseholdOf(ply)
    return h ~= nil and h.members[ownerCid] ~= nil
end

local function MoveIn(ply, h)
    local head = ByCID(h.head)
    local n = IsValid(head) and LC.PlayerBlock and LC.PlayerBlock(head)
    if n and ply ~= head then
        ply:SetPData("lc_block_" .. game.GetMap(), n)
        ply:SetNW2Int("lc_block", n)
        ply:SetPData("lc_housed_how", "household")
        ply.lcIntakeState = nil
    end
    if IsValid(head) and ply ~= head and LC.GiveKey then pcall(LC.GiveKey, head, Name(ply), true) end
    -- they know each other
    for cid in pairs(h.members) do
        local o = ByCID(cid)
        if IsValid(o) and o ~= ply and LC.Introduce then pcall(LC.Introduce, ply, o) pcall(LC.Introduce, o, ply) end
    end
end

function LC.HouseholdInvite(head, target)
    if not cvOn:GetBool() then return false, "No households here." end
    if not IsValid(target) or not target:IsPlayer() or target == head then return false, "Look at who you want to take in." end
    if not Citizenish(head) or not Citizenish(target) then return false, "Households are for citizens." end
    if not CID(head) or not CID(target) then return false, "Only someone on the register." end
    if head:GetPos():DistToSqr(target:GetPos()) > 250 * 250 then return false, "Ask them face to face." end
    if LC.HouseholdOf(target) then return false, Name(target) .. " is in a household already." end
    local id, h = LC.HouseholdOf(head)
    if h and h.head ~= CID(head) then return false, "Only the head of your household takes people in." end
    if h then
        local n = 0
        for _ in pairs(h.members) do n = n + 1 end
        if n >= cvMax:GetInt() then return false, "Your household is full." end
    end
    target.lcHouseInvite = { from = head, at = CurTime() }
    target:SetNW2String("lc_house_invite", Name(head))
    target:ChatPrint("[Miscount] " .. Name(head) .. " asks you to join their household. F2 > Me (More) > My household to accept.")
    if LC.Notice then LC.Notice(target, "info", "A household", Name(head) .. " asks you to join their household: the same block, shared crates, keys. F2 > Me (More) > My household to accept.", 10) end
    head:ChatPrint("[Miscount] You've asked " .. Name(target) .. " to join your household.")
    return true
end

function LC.HouseholdAccept(ply, yes)
    local inv = ply.lcHouseInvite
    ply.lcHouseInvite = nil
    ply:SetNW2String("lc_house_invite", "")
    if not inv or CurTime() - inv.at > INVITE_SECS or not IsValid(inv.from) then return false, "There's no invitation waiting." end
    local head = inv.from
    if not yes then
        head:ChatPrint("[Miscount] " .. Name(ply) .. " declined your invitation.")
        return true
    end
    if LC.HouseholdOf(ply) then return false, "You're in a household already." end
    local id, h = LC.HouseholdOf(head)
    if not h then
        id = CID(head) .. ":" .. os.time()
        h = { name = "the " .. Surname(Name(head)) .. " household", head = CID(head), members = { [CID(head)] = Name(head) } }
        Load()[id] = h
    end
    h.members[CID(ply)] = Name(ply)
    MoveIn(ply, h)
    Save()
    SyncAll()
    for cid in pairs(h.members) do
        local o = ByCID(cid)
        if IsValid(o) then o:ChatPrint("[Miscount] " .. Name(ply) .. " has joined " .. h.name .. ".") end
    end
    hook.Run("LivingCityHouseholdJoined", ply, h)
    return true
end

local function Remove(id, h, cid)
    h.members[cid] = nil
    local left = 0
    for _ in pairs(h.members) do left = left + 1 end
    if left <= 1 then
        Load()[id] = nil -- (a household of one is no household)
    elseif cid == h.head then
        for c in pairs(h.members) do h.head = c break end -- (the next one heads it)
    end
end

function LC.HouseholdLeave(ply)
    local id, h = LC.HouseholdOf(ply)
    if not h then return false, "You're not in a household." end
    local name = h.name
    Remove(id, h, CID(ply))
    Save()
    SyncAll()
    ply:SetNW2String("lc_household", "")
    ply:ChatPrint("[Miscount] You've left " .. name .. ".")
    return true
end

function LC.HouseholdSendAway(head, name)
    local id, h = LC.HouseholdOf(head)
    if not h or h.head ~= CID(head) then return false, "Only the head of a household sends anyone away." end
    for cid, n in pairs(h.members) do
        if cid ~= h.head and string.lower(n) == string.lower(tostring(name or "")) then
            Remove(id, h, cid)
            Save()
            SyncAll()
            local o = ByCID(cid)
            if IsValid(o) then o:ChatPrint("[Miscount] You're no longer part of " .. h.name .. ".") o:SetNW2String("lc_household", "") end
            head:ChatPrint("[Miscount] " .. n .. " is no longer part of the household.")
            return true
        end
    end
    return false, "No one by that name in your household."
end

function LC.HouseholdRename(head, name)
    local id, h = LC.HouseholdOf(head)
    if not h or h.head ~= CID(head) then return false, "Only the head names the household." end
    name = string.Trim(string.gsub(tostring(name or ""), "[%c\"]", ""))
    if #name < 3 or #name > 40 then return false, "A name of 3 to 40 letters." end
    h.name = name
    Save()
    SyncAll()
    return true
end

hook.Add("PlayerInitialSpawn", "LivingCityHouseholds", function(ply) timer.Simple(6, function() if IsValid(ply) then Sync(ply) end end) end)
hook.Add("LivingCityCharacterSwitched", "LivingCityHouseholds", function(ply) timer.Simple(1, function() if IsValid(ply) then Sync(ply) end end) end)
hook.Add("LivingCityNewCharacter", "LivingCityHouseholds", function(ply, oldName, why, oldCid)
    -- a person's end leaves their household
    if not oldCid then return end
    for id, h in pairs(Load()) do
        if h.members[oldCid] then Remove(id, h, oldCid) Save() SyncAll() break end
    end
end)

-- The menu's actions.
local function Wrap()
    if LC.MenuActions then LC.MenuActions.houseaccept, LC.MenuActions.housedecline, LC.MenuActions.houseleave, LC.MenuActions.housename, LC.MenuActions.housesendaway = true, true, true, true, true end
    LC.TargetActions = LC.TargetActions or {}
    LC.TargetActions.houseinvite = function(ply, target) return LC.HouseholdInvite(ply, target) end
end
Wrap()
hook.Add("Initialize", "LivingCityHouseholds", Wrap)
hook.Add("PlayerSay", "LivingCityHouseholds", function(ply, text)
    local cmd, rest = string.match(string.Trim(tostring(text or "")), "^[!/](%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local ok, why
    if cmd == "houseaccept" then ok, why = LC.HouseholdAccept(ply, true)
    elseif cmd == "housedecline" then ok, why = LC.HouseholdAccept(ply, false)
    elseif cmd == "houseleave" then ok, why = LC.HouseholdLeave(ply)
    elseif cmd == "housename" then ok, why = LC.HouseholdRename(ply, rest)
    elseif cmd == "housesendaway" then ok, why = LC.HouseholdSendAway(ply, rest)
    else return end
    if not ok and why then ply:ChatPrint("[Miscount] " .. why) end
    return ""
end)
