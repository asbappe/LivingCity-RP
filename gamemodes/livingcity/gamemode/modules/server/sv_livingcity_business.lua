--[[
    Living City: apartments and trade

      Apartments    Doors tagged "Door: apartment people can rent" in the editor.
                    Look at one and !rent: lc_rent_price credits (50) for
                    lc_rent_hours hours (3) of real time. !rent again extends
                    it (up to a day ahead). A double door is rented together.
                    While it's yours it's locked to everyone but you and
                    whoever you give a key: !givekey <name>, !takekey <name>.
                    !lock and !unlock (looking at the door), !unrent to give
                    it up, !apartment to see where it is and how long is left.
                    Units can force their way in (E, three seconds).
                    One apartment per person (lc_rent_max).
                    No commands needed: look at the door with your hands out
                    and right click. A free apartment asks "rent it?" (yes or
                    no); your own door locks and unlocks. Everyone sees who
                    holds a door, or that it is free, when they look at it.

      Trade         A CWU business license (Commissary, Civil Standing 50) lets
                    you set down a market stall (sv_livingcity_storage.lua) and
                    sell from it at your own prices. An officer can revoke a
                    license from the records terminal: the license is taken and
                    their stalls close until they get a new one.
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPrice = CreateConVar("lc_rent_price", "50", FLAGS, "Credits for one rent period of an apartment (units and citizens of high standing pay nothing)")
-- (the owner, 2026-11-01: loyalty pays) one apartment rent-free for the city's best citizens, and for units
local cvFreeStanding = CreateConVar("lc_free_rent_standing", "200", FLAGS, "Civil Standing at which a citizen's apartment is rent-free (0: nobody)")
-- (it started at 400 the same day: a server that got that moves to 200 once, the owner asked)
if cvFreeStanding:GetString() == "400" then
    if cvFreeStanding.SetString then cvFreeStanding:SetString("200") elseif RunConsoleCommand then RunConsoleCommand("lc_free_rent_standing", "200") end
end
local cvFreeCP = CreateConVar("lc_free_rent_cp", "1", FLAGS, "Civil Protection units get their apartment rent-free")
-- What this person pays for a rent period, and why it's free if it is.
function LC.RentPrice(ply)
    if IsValid(ply) then
        if cvFreeCP:GetBool() and LC.PlayerIsCP and LC.PlayerIsCP(ply) then return 0, "Civil Protection housing: no rent for a unit" end
        local need = cvFreeStanding:GetInt()
        if need > 0 and LC.Standing and LC.Standing(ply) >= need then return 0, "rent-free, for a citizen of your standing" end
    end
    return cvPrice:GetInt()
end
-- (29 October: 40 became 15; 1 November: 15 became 50, the owner asked. Settings are saved, so a server
-- still on an old default moves to 50 once; a price someone chose themselves is left alone.)
if cvPrice:GetString() == "40" or cvPrice:GetString() == "15" then
    if cvPrice.SetString then cvPrice:SetString("50") elseif RunConsoleCommand then RunConsoleCommand("lc_rent_price", "50") end
end
local cvHours = CreateConVar("lc_rent_hours", "3", FLAGS, "Hours (real time) one rent period lasts")
local cvMax   = CreateConVar("lc_rent_max", "1", FLAGS, "Apartments one person can rent")

util.AddNetworkString("lc_rent_ask")
util.AddNetworkString("lc_rent_confirm")

local DIR = "livingcity"
local function FilePath() return DIR .. "/" .. game.GetMap() .. "_rentals.json" end

LC.Rentals = LC.Rentals or nil -- [doorId] = { owner, ownerName, untilT (os.time), keys = { [cid] = name }, locked, doors = { ids } }

local function Load()
    if LC.Rentals then return LC.Rentals end
    local t = LC.SafeReadJSON(FilePath()) or {}
    LC.Rentals = {}
    for k, v in pairs(istable(t) and t or {}) do LC.Rentals[tonumber(k) or k] = v end
    return LC.Rentals
end

local function Save()
    LC.SafeWrite(FilePath(), util.TableToJSON(Load()))
end

local function OwnerKey(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and cid or ("sid:" .. ply:SteamID())
end
local function OwnerName(ply) return LC.CharacterName and LC.CharacterName(ply) or ply:Nick() end

local function DoorById(id)
    id = tonumber(id)
    return id and ents.GetMapCreatedEntity and ents.GetMapCreatedEntity(id) or nil
end

local function IsRentDoor(door)
    return IsValid(door) and LC.IsDoorEntity and LC.IsDoorEntity(door) and LC.GetDoorTag(door) == "rent"
end

-- The rental a door belongs to (its own, or its partner's in a double door).
function LC.RentalOf(door)
    if not IsValid(door) then return nil end
    local id = door:MapCreationID()
    local all = Load()
    if all[id] then return all[id], id end
    for main, r in pairs(all) do
        for _, d in ipairs(r.doors or {}) do if d == id then return r, main end end
    end
    return nil
end

local HasKey
function LC.HasRentKey(ply, r) return HasKey(ply, r) end
function HasKey(ply, r)
    local k = OwnerKey(ply)
    return r.owner == k or (r.keys and r.keys[k] ~= nil)
end
LC.HasApartmentKey = function(ply, door) local r = LC.RentalOf(door) return r ~= nil and HasKey(ply, r) end

local function EachDoor(r, main, fn)
    local d = DoorById(main)
    if IsValid(d) then fn(d) end
    for _, id in ipairs(r.doors or {}) do
        local e = DoorById(id)
        if IsValid(e) then fn(e) end
    end
end

-- What everybody sees when they look at the door (cl_livingcity_rent.lua):
-- "A:<price>:<hours>" if it is free, "O:<name>" if somebody holds it.
local function Mark(door, r)
    if not IsValid(door) then return end
    if r then
        door:SetNW2String("lc_rent", "O:" .. (r.ownerName or "someone"))
        door:SetNW2String("lc_rentkey", r.owner or "")
        door:SetNW2Bool("lc_rentlocked", r.locked and true or false)
    else
        door:SetNW2String("lc_rent", string.format("A:%d:%s", cvPrice:GetInt(), tostring(cvHours:GetFloat())))
        door:SetNW2String("lc_rentkey", "")
        door:SetNW2Bool("lc_rentlocked", false)
    end
end

function LC.ApplyRentDoor(door)
    local r = LC.RentalOf(door)
    Mark(door, r)
    if r and r.locked then
        door:Fire("Close")
        door:Fire("Lock", "", 0.1)
    else
        door:Fire("Unlock")
    end
end

local function Relock(r, main) EachDoor(r, main, function(d) LC.ApplyRentDoor(d) end) end

local function MyRentals(ply)
    local out = {}
    for main, r in pairs(Load()) do if r.owner == OwnerKey(ply) then out[#out + 1] = { main = main, r = r } end end
    return out
end

local function DoorAhead(ply)
    local tr = ply:GetEyeTrace()
    local d = tr and tr.Entity
    if IsRentDoor(d) and d:GetPos():DistToSqr(ply:GetPos()) < 160 * 160 then return d end
    return nil
end

local function Left(r) return math.max(0, (r.untilT or 0) - os.time()) end
local function Hm(secs) return string.format("%dh %02dm", math.floor(secs / 3600), math.floor(secs % 3600 / 60)) end

-- Why this person can't rent this door right now (nil if they can).
local function RentBlock(ply, door)
    local price, period = LC.RentPrice(ply), cvHours:GetFloat() * 3600
    local r = LC.RentalOf(door)
    if r and r.owner ~= OwnerKey(ply) then return "Someone already lives here." end
    if not r and #MyRentals(ply) >= cvMax:GetInt() then return "You already rent somewhere. !unrent it first." end
    if r and Left(r) + period > 86400 then return "It's paid up for as long as the landlord will take." end
    if LC.Credits and LC.Credits(ply) < price then return string.format("The rent is %d credits.", price) end
    return nil
end

function LC.Rent(ply, door)
    door = IsRentDoor(door) and door or DoorAhead(ply)
    if not door then return false, "Look at an apartment door that's for rent." end
    local price, period = cvPrice:GetInt(), cvHours:GetFloat() * 3600
    local free
    price, free = LC.RentPrice(ply)
    local r, main = LC.RentalOf(door)
    local why = RentBlock(ply, door)
    if why then return false, why end
    if price > 0 and LC.AddCredits then LC.AddCredits(ply, -price) end
    if r then
        r.untilT = r.untilT + period
        Save()
        return true, string.format("%s It's yours for %s more.", free and ("No charge: " .. free .. ".") or "Paid.", Hm(Left(r)))
    end
    main = door:MapCreationID()
    r = { owner = OwnerKey(ply), ownerName = OwnerName(ply), untilT = os.time() + period, keys = {}, locked = true, doors = {} }
    -- the other half of a double door comes with it
    for _, d in ipairs(ents.FindInSphere(door:WorldSpaceCenter(), 140)) do
        if d ~= door and IsRentDoor(d) and not LC.RentalOf(d) then r.doors[#r.doors + 1] = d:MapCreationID() end
    end
    Load()[main] = r
    Save()
    Relock(r, main)
    hook.Run("LivingCityRented", ply, main)
    return true, string.format("It's yours for %s%s. Locked to everyone but you. !givekey <name> to let someone in.", Hm(Left(r)), free and (", " .. free) or "")
end

function LC.Unrent(ply)
    local mine = MyRentals(ply)
    if #mine == 0 then return false, "You don't rent anywhere." end
    for _, m in ipairs(mine) do
        Load()[m.main] = nil
        EachDoor(m.r, m.main, function(d) LC.ApplyRentDoor(d) end)
    end
    Save()
    return true, "You've moved out."
end

function LC.SetApartmentLock(ply, locked, aimed)
    local door = IsRentDoor(aimed) and aimed or DoorAhead(ply)
    local r, main = LC.RentalOf(door)
    if not r then return false, "Look at your apartment door." end
    if not HasKey(ply, r) then return false, "You don't have a key." end
    r.locked = locked
    Save()
    Relock(r, main)
    door:EmitSound(locked and "doors/door_latch1.wav" or "doors/door_latch3.wav", 60)
    return true, locked and "Locked." or "Unlocked: anyone can come in."
end

function LC.GiveKey(ply, name, give)
    local mine = MyRentals(ply)
    if #mine == 0 then return false, "You don't rent anywhere." end
    local target = LC.FindPlayer and LC.FindPlayer(name)
    if not target then
        -- or the person in front of you
        local tr = ply:GetEyeTrace()
        if tr and IsValid(tr.Entity) and tr.Entity:IsPlayer() then target = tr.Entity end
    end
    if not target or target == ply then return false, "Who? Name them, or look at them." end
    local r = mine[1].r
    r.keys = r.keys or {}
    if give then
        r.keys[OwnerKey(target)] = OwnerName(target)
        target:ChatPrint("[Living City] " .. OwnerName(ply) .. " gave you a key to their apartment.")
    else
        r.keys[OwnerKey(target)] = nil
        target:ChatPrint("[Living City] " .. OwnerName(ply) .. " took back the key to their apartment.")
    end
    Save()
    return true, give and ("You gave " .. OwnerName(target) .. " a key.") or ("You took " .. OwnerName(target) .. "'s key back.")
end

function LC.ApartmentInfo(ply)
    local mine = MyRentals(ply)
    if #mine == 0 then
        local keys = {}
        for _, r in pairs(Load()) do if r.keys and r.keys[OwnerKey(ply)] then keys[#keys + 1] = r.ownerName or "someone" end end
        return #keys > 0 and ("You don't rent anywhere, but you have keys to: " .. table.concat(keys, ", ") .. "'s.")
            or "You don't rent anywhere. Look at an apartment door that's for rent and !rent."
    end
    local r = mine[1].r
    local d = DoorById(mine[1].main)
    local where = IsValid(d) and LC.DescribePlace and LC.DescribePlace(d:GetPos()) or ""
    local holders = {}
    for _, n in pairs(r.keys or {}) do holders[#holders + 1] = n end
    return string.format("Your apartment, %s: %s left, %s. Keys: %s.", where, Hm(Left(r)), r.locked and "locked" or "unlocked",
        #holders > 0 and table.concat(holders, ", ") or "just you")
end

-- Pressing E on a rented, locked door.
local breaching = {}
function LC.RentDoorUse(ply, door)
    local r, main = LC.RentalOf(door)
    if not r or not r.locked then return nil end
    if HasKey(ply, r) then
        -- open already: E shuts it again (it used to open it again, so it never shut till unlocked)
        if LC.DoorIsOpen and LC.DoorIsOpen(door) then
            door:Fire("Close")
            door:Fire("Lock", "", 1)
            LC.OpenedDoors[door] = nil
            LC.Relock[door] = nil
            return false
        end
        -- locked is locked, for the one with the key too: the handle rattles. Unlock it first
        -- (right click it with your hands out, or !unlock)
        door:EmitSound("doors/door_locked2.wav", 60)
        if (ply.lcRentLockedSaid or 0) < CurTime() then
            ply.lcRentLockedSaid = CurTime() + 4
            ply:ChatPrint("[Living City] It's locked. Unlock it first: right click it with your hands out (or !unlock).")
        end
        return false
    end
    if LC.PlayerIsCP(ply) and LC.StartTask then
        if breaching[ply] and breaching[ply] > CurTime() then return false end
        breaching[ply] = CurTime() + 4
        LC.StartTask(ply, 3, "Forcing the door...", {
            maxMove = 40, cancelText = "You stop.",
            done = function(p)
                if not IsValid(door) then return end
                door:Fire("Unlock")
                door:Fire("Open", "", 0.1)
                LC.OpenedDoors[door] = CurTime() + 8
                LC.Relock[door] = true
                door:EmitSound("physics/wood/wood_crate_break3.wav", 80)
                for _, q in ipairs(player.GetAll()) do
                    if HasKey(q, r) then q:ChatPrint("[Living City] Civil Protection forced the door of " .. (r.ownerName or "the") .. "'s apartment.") end
                end
            end,
        })
        return false
    end
    if (ply.lcRentKnock or 0) < CurTime() then
        ply.lcRentKnock = CurTime() + 1
        door:EmitSound("physics/wood/wood_crate_impact_hard2.wav", 70)
        ply:ChatPrint("Locked. (Someone lives here.)")
    end
    return false
end

-- Rent runs out.
timer.Create("LivingCityRent", 30, 0, function()
    local now = os.time()
    local changed = false
    for main, r in pairs(Load()) do
        if (r.untilT or 0) <= now then
            Load()[main] = nil
            changed = true
            EachDoor(r, main, function(d) LC.ApplyRentDoor(d) end)
            for _, p in ipairs(player.GetAll()) do
                if OwnerKey(p) == r.owner then p:ChatPrint("[Living City] Your rent ran out. The apartment isn't yours any more.") end
            end
        elseif not r.warned and r.untilT - now < 600 then
            r.warned = true
            changed = true
            for _, p in ipairs(player.GetAll()) do
                if OwnerKey(p) == r.owner then p:ChatPrint("[Living City] Your rent runs out in 10 minutes. Look at the door, F1 > Rent / lock this door to pay more.") end
            end
        end
    end
    if changed then Save() end
end)

------------------------------------------------------------------------
-- Right click with your hands (weapon_lc_hands): no commands needed
------------------------------------------------------------------------

-- A free apartment asks "rent it?"; your own door (or one you hold a key to)
-- locks and unlocks; someone else's just says so.
function LC.HandsRightClick(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if (ply.lcRentRC or 0) > CurTime() then return false end
    local door = DoorAhead(ply)
    if not door then return false end
    ply.lcRentRC = CurTime() + 0.5
    local r = LC.RentalOf(door)
    if not r then
        local why = RentBlock(ply, door)
        if why then ply:ChatPrint(why) return true end
        net.Start("lc_rent_ask")
        net.WriteEntity(door)
        net.WriteUInt(math.Clamp(LC.RentPrice(ply), 0, 65535), 16)
        net.WriteFloat(cvHours:GetFloat())
        net.Send(ply)
        return true
    end
    if HasKey(ply, r) then
        local ok, msg = LC.SetApartmentLock(ply, not r.locked, door)
        if msg then ply:ChatPrint(msg) end
        return true
    end
    ply:ChatPrint("Someone lives here.")
    return true
end

net.Receive("lc_rent_confirm", function(_, ply)
    if not IsValid(ply) or (ply.lcRentYes or 0) > CurTime() then return end
    ply.lcRentYes = CurTime() + 1
    local door = net.ReadEntity()
    if not IsRentDoor(door) or door:GetPos():DistToSqr(ply:GetPos()) > 200 * 200 then return end
    if LC.RentalOf(door) then ply:ChatPrint("Someone already lives here.") return end
    local _, msg = LC.Rent(ply, door)
    if msg then ply:ChatPrint(msg) end
end)

------------------------------------------------------------------------
-- Licenses
------------------------------------------------------------------------

-- An officer takes a trader's license away; their stalls close.
function LC.RevokeLicense(officer, target)
    if not (LC.IsCPOfficer and LC.IsCPOfficer(officer)) then return false, "Officers only." end
    if not IsValid(target) then return false, "They're not in the city right now." end
    local had = LC.HasItem(target, "business_license")
    while LC.HasItem(target, "business_license") do LC.TakeItem(target, "business_license", 1) end
    if LC.SetStallsClosed and LC.StorageOwnerKey then LC.SetStallsClosed(LC.StorageOwnerKey(target), true) end
    if LC.AddViolation then LC.AddViolation(target, "Business license revoked", officer:GetNW2String("lcf_title", officer:Nick())) end
    target:ChatPrint("[Civil Workers' Union] Your business license has been revoked. Your stalls are closed.")
    return true, had and ((LC.CharacterName and LC.CharacterName(target) or target:Nick()) .. "'s license is revoked.") or "They had no license; their stalls are closed."
end

------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------

local function Say(ply, ok, msg) if msg then ply:ChatPrint(msg) end end
local CMDS = {
    rent = function(ply) Say(ply, LC.Rent(ply)) end,
    unrent = function(ply) Say(ply, LC.Unrent(ply)) end,
    lock = function(ply) Say(ply, LC.SetApartmentLock(ply, true)) end,
    unlock = function(ply) Say(ply, LC.SetApartmentLock(ply, false)) end,
    givekey = function(ply, rest) Say(ply, LC.GiveKey(ply, rest, true)) end,
    takekey = function(ply, rest) Say(ply, LC.GiveKey(ply, rest, false)) end,
    apartment = function(ply) ply:ChatPrint(LC.ApartmentInfo(ply)) end,
}
for k, fn in pairs(CMDS) do LC.SlashCommands[k] = fn end

hook.Add("PlayerSay", "LivingCityBusinessChat", function(ply, text)
    local raw = string.Trim(text or "")
    local lead = string.sub(raw, 1, 1)
    if lead ~= "!" and lead ~= "/" then return end
    if lead == "/" and LC.ICChatActive and LC.ICChatActive() then return end
    local cmd, rest = string.match(raw, "^[!/](%S+)%s*(.*)$")
    local fn = cmd and CMDS[string.lower(cmd)]
    if not fn then return end
    fn(ply, rest or "")
    return ""
end)
