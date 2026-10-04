--[[
    Living City: housing blocks

    Paint "block" zones with the editor and give each a number. A block can be
    several zones with the same number (two wings of one building, say).

    Every player is assigned a block the first time they join a map, spread
    evenly across the blocks that exist, and keeps it across visits. During
    curfew and lockdown their HUD points them home, and cops only hassle
    people who are outside their own block.

    NPC citizens head into the nearest block when they go home.

    Chat: !block      Console (admin): lc_setblock <name> <number>, lc_reassignblocks
]]

if CLIENT then return end

util.AddNetworkString("lc_public")

LC = LC or {}

CreateConVar("lc_block_name", "Habitation Block %02d", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "How blocks are named. %02d is replaced with the block number.")

local function Key() return "lc_block_" .. game.GetMap() end

function LC.BlockNumbers()
    local seen, out = {}, {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        local n = z.group or 0
        if n > 0 and not seen[n] then seen[n] = true; out[#out + 1] = n end
    end
    table.sort(out)
    return out
end

local function BlockExists(n)
    for _, b in ipairs(LC.BlockNumbers()) do if b == n then return true end end
    return false
end

function LC.InBlock(pos, n)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if (z.group or 0) == n and pos:DistToSqr(z.pos) < z.r * z.r then return true end
    end
    return false
end

function LC.PlayerBlock(ply)
    local n = ply:GetNW2Int("lc_block", 0)
    return n > 0 and n or nil
end

-- true / false, or nil when this map has no blocks to be in.
function LC.PlayerInOwnBlock(ply)
    local n = LC.PlayerBlock(ply)
    if not n then return nil end
    return LC.InBlock(ply:GetPos(), n)
end

local function LeastCrowded()
    local blocks = LC.BlockNumbers()
    if #blocks == 0 then return nil end
    local counts = {}
    for _, p in ipairs(player.GetAll()) do
        local n = LC.PlayerBlock(p)
        if n then counts[n] = (counts[n] or 0) + 1 end
    end
    table.sort(blocks, function(a, b)
        local ca, cb = counts[a] or 0, counts[b] or 0
        if ca == cb then return a < b end
        return ca < cb
    end)
    return blocks[1]
end

function LC.AssignBlock(ply, force)
    local saved = tonumber(ply:GetPData(Key(), 0)) or 0
    if not force and saved > 0 and BlockExists(saved) then
        ply:SetNW2Int("lc_block", saved)
        return saved
    end
    local n = LeastCrowded()
    ply:SetNW2Int("lc_block", n or 0)
    if n then
        ply:SetPData(Key(), n)
        ply:ChatPrint("[Living City] You have been assigned to " .. LC.BlockName(n) .. ".")
    end
    return n
end

------------------------------------------------------------------------
-- Public layout data every player needs (block locations for the HUD)
------------------------------------------------------------------------

local function PublicSnapshot()
    local blocks = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("block") or {}) do
        if (z.group or 0) > 0 then
            blocks[#blocks + 1] = { n = z.group, x = z.pos.x, y = z.pos.y, z = z.pos.z, r = z.r }
        end
    end
    return { blocks = blocks }
end

function LC.BroadcastPublic(target)
    local recipients = IsValid(target) and { target } or player.GetAll()
    if #recipients == 0 then return end
    LC.SendCompressed("lc_public", PublicSnapshot(), recipients)
    if not IsValid(target) then
        -- blocks may have been added or removed: fix anyone left homeless
        for _, p in ipairs(player.GetAll()) do
            local n = LC.PlayerBlock(p)
            if not n or not BlockExists(n) then LC.AssignBlock(p) end
        end
    end
end

hook.Add("PlayerInitialSpawn", "LivingCityHousing", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        LC.AssignBlock(ply)
        LC.BroadcastPublic(ply)
    end)
end)

hook.Add("PlayerSay", "LivingCityHousingChat", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!block" then return end
    local n = LC.PlayerBlock(ply)
    ply:ChatPrint(n and ("[Living City] You live in " .. LC.BlockName(n) .. ".")
        or "[Living City] This map has no housing blocks yet.")
    return ""
end)

concommand.Add("lc_setblock", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    local n = tonumber(args[2])
    if not target or not n or not BlockExists(n) then
        local msg = "[Living City] Usage: lc_setblock <name> <block number that exists>"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    target:SetNW2Int("lc_block", n)
    target:SetPData(Key(), n)
    target:ChatPrint("[Living City] You have been reassigned to " .. LC.BlockName(n) .. ".")
end)

concommand.Add("lc_reassignblocks", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    for _, p in ipairs(player.GetAll()) do p:SetNW2Int("lc_block", 0) end
    for _, p in ipairs(player.GetAll()) do LC.AssignBlock(p, true) end
end)
