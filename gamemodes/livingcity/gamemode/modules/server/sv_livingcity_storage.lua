--[[
    Living City: places to keep things

      Bins and dumpsters   anyone can hide something in one (look at it and open
                           your pockets, F2) and anyone can take it out. Things
                           left there are thrown out after lc_bin_minutes (40).
                           Dead drops.
      Lockers              placed with the editor ("Fixture: locker"). The first
                           person to put something in one claims it; after that
                           it opens for them alone. Press E on it. Give it up
                           (empty) from the same screen.
      Storage crates       bought at the Commissary and set down anywhere from
                           your pockets ("Set down"). Only you open it. Pack it
                           up again when it's empty. lc_crates_per_person (2).

    Units open any locker or crate: it's a search. They see what's inside and
    can confiscate the contraband, which goes on the owner's record and makes
    them wanted if they're in the city.

    Lockers and crates keep their contents across restarts
    (garrysmod/data/livingcity/<map>_storage.json). Everything is weighed:
    lc_bin_kg (10), lc_locker_kg (25), lc_crate_kg (35).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_storage", "1", FLAGS, "Bins, lockers and crates people can keep things in")
local cvBinMins  = CreateConVar("lc_bin_minutes", "40", FLAGS, "Minutes before what's left in a bin is thrown out")
local cvBinKg    = CreateConVar("lc_bin_kg", "10", FLAGS, "Kilograms a bin or dumpster holds")
local cvLockerKg = CreateConVar("lc_locker_kg", "25", FLAGS, "Kilograms a locker holds")
local cvCrateKg  = CreateConVar("lc_crate_kg", "35", FLAGS, "Kilograms a storage crate holds")
local cvCrates   = CreateConVar("lc_crates_per_person", "2", FLAGS, "Storage crates one person can have set down")
local cvStallKg  = CreateConVar("lc_stall_kg", "30", FLAGS, "Kilograms a market stall holds")
local cvStalls   = CreateConVar("lc_stalls_per_person", "1", FLAGS, "Market stalls one person can have set up")

local DIR = "livingcity"
local function FilePath() return DIR .. "/" .. game.GetMap() .. "_storage.json" end

LC.Storage = LC.Storage or nil -- [id] = { kind, items, owner, ownerName, pos, ang, touched }
local dirty = false

local function Load()
    if LC.Storage then return LC.Storage end
    local raw = file.Read(FilePath(), "DATA")
    local t = raw and util.JSONToTable(raw) or {}
    LC.Storage = istable(t) and t or {}
    for _, c in pairs(LC.Storage) do c.items = istable(c.items) and c.items or {} end
    return LC.Storage
end

local function Save()
    local out = {}
    for id, c in pairs(Load()) do
        if c.kind ~= "bin" then
            out[id] = { kind = c.kind, items = c.items, owner = c.owner, ownerName = c.ownerName, pos = c.pos, ang = c.ang,
                prices = c.prices, till = c.till, closed = c.closed }
        end
    end
    file.CreateDir(DIR)
    file.Write(FilePath(), util.TableToJSON(out))
end

timer.Create("LivingCityStorageSave", 15, 0, function()
    if dirty then dirty = false Save() end
end)

-- Who owns things: the person (by citizen number), not the account.
local function OwnerKey(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and cid or ("sid:" .. ply:SteamID())
end
local function OwnerName(ply) return LC.CharacterName and LC.CharacterName(ply) or ply:Nick() end
local function RealUnit(ply) return LC.PlayerIsCP(ply) end

local function Capacity(c)
    if c.kind == "bin" then return cvBinKg:GetFloat() end
    if c.kind == "locker" then return cvLockerKg:GetFloat() end
    if c.kind == "stall" then return cvStallKg:GetFloat() end
    return cvCrateKg:GetFloat()
end

local function Weight(items)
    local kg = 0
    for id, n in pairs(items) do kg = kg + LCS.Weight(id) * n end
    return kg
end

local NAMES = { bin = "the bin", locker = "the locker", crate = "the crate", stall = "the stall" }

------------------------------------------------------------------------
-- Finding the container someone is at
------------------------------------------------------------------------

local function EntityContainer(e)
    if not IsValid(e) then return nil end
    local store = Load()
    if e:GetClass() == "lc_locker" then
        local id = "locker:" .. tostring(e.lcFixtureKey or e:EntIndex())
        store[id] = store[id] or { kind = "locker", items = {} }
        store[id].ent = e
        return id, store[id]
    elseif (e:GetClass() == "lc_crate" or e:GetClass() == "lc_stall") and e.lcStorageId then
        local c = store[e.lcStorageId]
        if c then c.ent = e return e.lcStorageId, c end
    end
    return nil
end

-- The container in front of this player: something they're looking at up close, or a bin.
function LC.ContainerAt(ply)
    if not cvOn:GetBool() then return nil end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:GetPos():DistToSqr(ply:GetPos()) < 130 * 130 then
        local id, c = EntityContainer(e)
        if id then return id, c end
    end
    if LC.BinAt then
        local key = LC.BinAt(ply)
        if key then
            local store = Load()
            local id = "bin:" .. key
            store[id] = store[id] or { kind = "bin", items = {}, touched = CurTime() }
            return id, store[id]
        end
    end
    return nil
end

-- What this player may do with it: "open" (their own, or a bin), "search" (a unit), or nil and why.
local function Access(ply, c)
    if c.kind == "bin" then return "open" end
    if not c.owner or c.owner == OwnerKey(ply) then return "open" end
    if RealUnit(ply) then return "search" end
    if c.kind == "stall" then
        if c.closed then return nil, "The stall is closed." end
        return "shop"
    end
    return nil, (c.kind == "locker" and "The locker is locked. It's someone else's." or "The crate is locked. It isn't yours.")
end

-- For the pockets screen: what's in the container in front of them.
function LC.ContainerView(ply)
    local id, c = LC.ContainerFocused(ply)
    if not id then return nil end
    local mode, why = Access(ply, c)
    local v = { id = id, kind = c.kind, name = NAMES[c.kind], mode = mode, why = why, kg = Weight(c.items), maxKg = Capacity(c),
        owner = c.ownerName, mine = c.owner ~= nil and c.owner == OwnerKey(ply) or nil }
    if mode then v.items = c.items end
    if c.kind == "stall" then
        v.prices = c.prices or {}
        if mode == "open" then v.till = c.till or 0 v.closed = c.closed or nil end
        if mode == "shop" then v.credits = LC.Credits and LC.Credits(ply) or 0 end
    end
    return v
end

-- Pressing E on a locker or crate: open your pockets alongside it.
function LC.OpenContainer(ply, ent)
    if not cvOn:GetBool() then return end
    local id, c = EntityContainer(ent)
    if not id then return end
    ply.lcContainerFocus = { id = id, untilT = CurTime() + 120, ent = ent }
    local mode, why = Access(ply, c)
    if not mode then ply:EmitSound("doors/default_locked.wav", 55) ply:ChatPrint(why) return end
    if mode == "search" then ply:ChatPrint("[Search] You open " .. NAMES[c.kind] .. (c.ownerName and (" (" .. c.ownerName .. "'s)") or "") .. ".") end
    if LC.SendInv then LC.SendInv(ply, true) end
end

-- The container the pockets screen is showing: the one they opened with E (if still close), or what they're looking at.
local function Focused(ply)
    local f = ply.lcContainerFocus
    if f and f.untilT > CurTime() and IsValid(f.ent) and f.ent:GetPos():DistToSqr(ply:GetPos()) < 160 * 160 then
        local id, c = EntityContainer(f.ent)
        if id then return id, c end
    end
    return LC.ContainerAt(ply)
end
LC.ContainerFocused = Focused

------------------------------------------------------------------------
-- Putting in and taking out
------------------------------------------------------------------------

function LC.ContainerPut(ply, id)
    local cid, c = Focused(ply)
    if not cid then return false, "There's nothing here to put it in." end
    local mode, why = Access(ply, c)
    if mode ~= "open" then return false, why or "Not yours to fill." end
    if not LC.HasItem(ply, id) then return false end
    if Weight(c.items) + LCS.Weight(id) > Capacity(c) + 0.001 then return false, "It won't fit." end
    LC.TakeItem(ply, id, 1)
    c.items[id] = (c.items[id] or 0) + 1
    c.touched = CurTime()
    if c.kind == "locker" and not c.owner then
        c.owner, c.ownerName = OwnerKey(ply), OwnerName(ply)
        ply:ChatPrint("[Living City] The locker is yours now. Only you can open it.")
    end
    if c.kind ~= "bin" then dirty = true end
    if c.kind == "bin" and LCS.Items[id] and LCS.Items[id].contraband then c.contraband = true end
    hook.Run("LivingCityStored", ply, cid, id)
    return true
end

function LC.ContainerTake(ply, id)
    local cid, c = Focused(ply)
    if not cid then return false end
    local mode, why = Access(ply, c)
    if not mode then return false, why end
    if (c.items[id] or 0) < 1 then return false end
    if mode == "shop" then return false, "Buy it." end
    if mode == "search" then
        -- units only take what's illegal
        if not (LCS.Items[id] and LCS.Items[id].contraband) then return false, "It's not contraband. It stays." end
    end
    local okC, whyC = LC.CanCarry(ply, id, 1)
    if not okC then return false, whyC end
    c.items[id] = c.items[id] - 1
    if c.items[id] <= 0 then c.items[id] = nil end
    LC.GiveItem(ply, id, 1)
    if c.kind ~= "bin" then dirty = true end
    if mode == "search" then
        if LC.AddXP then LC.AddXP(ply, 5, "Contraband seized") end
        local owner
        for _, p in ipairs(player.GetAll()) do if OwnerKey(p) == c.owner then owner = p end end
        local name = LCS.Items[id].name
        if IsValid(owner) then
            LC.ReportCrime(owner, "Contraband in their " .. (c.kind == "locker" and "locker" or "crate"), 180)
            if LC.AddViolation then LC.AddViolation(owner, "Contraband found in their " .. c.kind .. ": " .. name, ply:GetNW2String("lcf_title", ply:Nick())) end
            owner:ChatPrint("[Civil Protection] Your " .. c.kind .. " was searched. They found: " .. name .. ".")
        end
    end
    return true
end

-- Giving up an empty locker, or packing up an empty crate.
function LC.ContainerRelease(ply)
    local cid, c = Focused(ply)
    if not cid or c.kind == "bin" then return false end
    if c.owner ~= OwnerKey(ply) then return false, "It isn't yours." end
    if next(c.items) ~= nil then return false, "Empty it first." end
    if c.kind == "locker" then
        c.owner, c.ownerName = nil, nil
        dirty = true
        return true, "The locker is free for anyone now."
    end
    local itemId = c.kind == "stall" and "vendor_stall" or "storage_crate"
    if (c.till or 0) > 0 then return false, "Collect the takings first." end
    if not LC.CanCarry(ply, itemId, 1) then return false, "You can't carry it." end
    if IsValid(c.ent) then c.ent:Remove() end
    Load()[cid] = nil
    dirty = true
    LC.GiveItem(ply, itemId, 1)
    return true, c.kind == "stall" and "You pack the stall up." or "You pack the crate up."
end

------------------------------------------------------------------------
-- Storage crates in the world
------------------------------------------------------------------------

local function SpawnCrate(id, c)
    local e = ents.Create(c.kind == "stall" and "lc_stall" or "lc_crate")
    if not IsValid(e) then return nil end
    e:SetPos(Vector(c.pos.x, c.pos.y, c.pos.z))
    e:SetAngles(Angle(0, c.ang or 0, 0))
    e:Spawn()
    e.lcStorageId = id
    e:SetNW2String("lc_label_kind", c.kind)
    e:SetNW2String("lc_owner_name", c.ownerName or "")
    c.ent = e
    return e
end

function LC.PlaceCrate(ply, itemId)
    itemId = itemId or "storage_crate"
    local kind = LCS.Items[itemId] and LCS.Items[itemId].place or "crate"
    if not cvOn:GetBool() then return false, "Storage is off on this server." end
    if not LC.HasItem(ply, itemId) then return false end
    if kind == "stall" and not LC.HasItem(ply, "business_license") then
        return false, "Trading needs a CWU business license in your pockets (the Commissary issues them)."
    end
    local mine = 0
    for _, c in pairs(Load()) do if c.kind == kind and c.owner == OwnerKey(ply) then mine = mine + 1 end end
    local cap = kind == "stall" and cvStalls:GetInt() or cvCrates:GetInt()
    if mine >= cap then return false, string.format("You already have %d %s set down. Pack one up first.", mine, kind == "stall" and "stalls" or "crates") end
    local fwd = ply:GetForward()
    fwd.z = 0
    local spot = ply:GetPos() + fwd:GetNormalized() * 50
    local ground = LC.GroundAt and LC.GroundAt(spot + Vector(0, 0, 30)) or spot
    if LC.NearDoor and LC.NearDoor(ground, 90) then return false, "Not in a doorway." end
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ground + Vector(0, 0, 16), filter = ply })
    if tr.Hit and tr.Fraction < 0.9 then return false, "There's no room there." end
    LC.TakeItem(ply, itemId, 1)
    LC.CrateSerial = (LC.CrateSerial or 0) + 1
    local id = string.format("%s:%d-%d", kind, os.time(), LC.CrateSerial)
    local c = { kind = kind, items = {}, owner = OwnerKey(ply), ownerName = OwnerName(ply), prices = kind == "stall" and {} or nil, till = kind == "stall" and 0 or nil,
        pos = { x = ground.x, y = ground.y, z = ground.z + 1 }, ang = math.floor(ply:EyeAngles().y) }
    Load()[id] = c
    SpawnCrate(id, c)
    dirty = true
    return true
end

-- On a new map or a restart: the crates people left come back.
function LC.RestoreCrates()
    for id, c in pairs(Load()) do
        if (c.kind == "crate" or c.kind == "stall") and not IsValid(c.ent) and c.pos then SpawnCrate(id, c) end
    end
end
hook.Add("InitPostEntity", "LivingCityStorage", function() timer.Simple(2, function() pcall(LC.RestoreCrates) end) end)
hook.Add("PostCleanupMap", "LivingCityStorage", function() timer.Simple(1, function() pcall(LC.RestoreCrates) end) end)

-- What's left in bins gets thrown out.
timer.Create("LivingCityBins", 60, 0, function()
    local now = CurTime()
    for id, c in pairs(Load()) do
        if c.kind == "bin" and now - (c.touched or now) > cvBinMins:GetFloat() * 60 then Load()[id] = nil end
    end
end)

------------------------------------------------------------------------
-- Market stalls: stock it with prices, people buy, takings wait in the till
------------------------------------------------------------------------

-- Put one in for sale at a price (or change the price of what's there). spec: "item|price"
function LC.StallStock(ply, spec)
    local id, price = string.match(tostring(spec or ""), "^([%w_]+)|(%d+)$")
    price = tonumber(price)
    if not id or not price then return false, "Name a price." end
    local cid, c = Focused(ply)
    if not cid or c.kind ~= "stall" then return false end
    if c.owner ~= OwnerKey(ply) then return false, "It isn't your stall." end
    price = math.Clamp(math.floor(price), 1, 5000)
    c.prices = c.prices or {}
    if LC.HasItem(ply, id) then
        local ok, why = LC.ContainerPut(ply, id)
        if not ok then return false, why end
    elseif (c.items[id] or 0) < 1 then
        return false
    end
    c.prices[id] = price
    dirty = true
    return true
end

function LC.StallBuy(ply, id)
    local cid, c = Focused(ply)
    if not cid or c.kind ~= "stall" then return false end
    if c.closed then return false, "The stall is closed." end
    if c.owner == OwnerKey(ply) then return false, "It's your own stall. Take it back instead." end
    local price = c.prices and c.prices[id]
    if (c.items[id] or 0) < 1 or not price then return false, "That's gone." end
    if not LC.Credits or LC.Credits(ply) < price then return false, "You can't afford it." end
    local okC, whyC = LC.CanCarry(ply, id, 1)
    if not okC then return false, whyC end
    LC.AddCredits(ply, -price)
    c.items[id] = c.items[id] - 1
    if c.items[id] <= 0 then c.items[id] = nil c.prices[id] = nil end
    c.till = (c.till or 0) + price
    LC.GiveItem(ply, id, 1)
    dirty = true
    for _, p in ipairs(player.GetAll()) do
        if OwnerKey(p) == c.owner then p:ChatPrint(string.format("[Stall] Sold: %s, %d credits. (%d in the till)", LCS.Items[id].name, price, c.till)) end
    end
    hook.Run("LivingCityStallSale", ply, cid, id, price)
    return true, string.format("Bought: %s, %d credits.", LCS.Items[id].name, price)
end

function LC.StallCollect(ply)
    local cid, c = Focused(ply)
    if not cid or c.kind ~= "stall" or c.owner ~= OwnerKey(ply) then return false end
    local n = c.till or 0
    if n <= 0 then return false, "The till is empty." end
    c.till = 0
    LC.AddCredits(ply, n, "the stall's takings")
    dirty = true
    return true
end

-- A unit closing someone's stalls (their license revoked), or the owner opening them again.
function LC.SetStallsClosed(ownerKey, closed)
    for _, c in pairs(Load()) do
        if c.kind == "stall" and c.owner == ownerKey then c.closed = closed or nil dirty = true end
    end
end
LC.StorageOwnerKey = OwnerKey

function LC.StallReopen(ply)
    local cid, c = Focused(ply)
    if not cid or c.kind ~= "stall" or c.owner ~= OwnerKey(ply) then return false end
    if not LC.HasItem(ply, "business_license") then return false, "You need a business license to trade." end
    c.closed = nil
    dirty = true
    return true, "The stall is open."
end

-- Pockets screen actions (sv_livingcity_survival.lua routes them here).
function LC.StorageAction(ply, action, id)
    local ok, msg
    if action == "cstock" then ok, msg = LC.StallStock(ply, id)
    elseif action == "cbuy" then ok, msg = LC.StallBuy(ply, id)
    elseif action == "ccollect" then ok, msg = LC.StallCollect(ply)
    elseif action == "creopen" then ok, msg = LC.StallReopen(ply)
    elseif action == "cput" then ok, msg = LC.ContainerPut(ply, id)
    elseif action == "ctake" then ok, msg = LC.ContainerTake(ply, id)
    elseif action == "crelease" then ok, msg = LC.ContainerRelease(ply)
    elseif action == "place" then ok, msg = LC.PlaceCrate(ply, id)
    else return false end
    if msg then ply:ChatPrint(msg) end
    if LC.SendInv then LC.SendInv(ply, true) end
    return true
end
