--[[
    Living City: path mapping, drawing the walkable network by walking it

      Turn it on from the editor panel ("Paths and doors": Path mapping), with
      lc_pathmap in the console, or !pathmap in chat, then just walk the
      streets, stairs, ramps and alleys you want NPCs to be able to use. As you
      go it lays path nodes about every lc_pathmap_spacing units (130), links
      each to the last one (only if a person could really walk between them)
      and to any other node nearby that you could walk to, so loops close up
      by themselves. Walk over an existing node and you join it instead of
      stacking another on top.

      It only maps while you're actually walking: noclip, being in the air,
      a vehicle or a ladder pause it, and a jump of more than 400 units (a
      teleport) starts a fresh chain instead of drawing a link across it.
      Everything is saved to the map's layout file a few seconds after you
      stop, so nothing is lost, and turning it off saves at once. These are
      the same path nodes as the editor's own (and are drawn in its overlay),
      so you can still delete, link and unlink them by hand.

      lc_pathmap (toggle), lc_pathmap_spacing, lc_pathmap_undo (remove the
      nodes you've added since you turned it on)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvSpacing = CreateConVar("lc_pathmap_spacing", "130", FLAGS, "Civil Protection units of walking between path nodes while path mapping")

local JOIN = 70        -- standing this close to an existing node (and able to walk to it) joins it
local LINK = 230       -- other nodes this close, and walkable, get linked too
local RESET = 400      -- a jump this far in one step is a teleport: start a fresh chain
local SAVE_AFTER = 4   -- seconds after the last new node before saving

LC.PathMappers = LC.PathMappers or {}

local function Mapping(ply)
    local m = LC.PathMappers[ply]
    return m
end

local function CanMap(ply)
    return IsValid(ply) and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP
        and ply:IsOnGround() and not (ply.InVehicle and ply:InVehicle())
        and ply:GetMoveType() ~= MOVETYPE_LADDER
end

local function Flush(ply, m)
    if m.dirty then
        m.dirty = false
        LC.SaveData()
        if LC.SendData and IsValid(ply) then LC.SendData(ply) end -- the overlay shows what you've laid
    end
end

local function NewNode(m, pos)
    local id = LC.NextNodeId
    LC.NextNodeId = id + 1
    local n = { id = id, pos = Vector(pos.x, pos.y, pos.z), links = {} }
    LC.Nodes[id] = n
    m.added[#m.added + 1] = n
    return n
end

local function Link(a, b)
    if a == b or a.links[b.id] then return false end
    a.links[b.id], b.links[a.id] = true, true
    return true
end

-- One step of mapping for one player. Returns the node they're now "at".
function LC.PathMapStep(ply)
    local m = Mapping(ply)
    if not m or not CanMap(ply) then return nil end
    local pos = ply:GetPos()
    local last = m.last
    if last and (LC.Nodes[last.id] ~= last or last.pos:Distance(pos) > RESET) then last = nil end

    -- standing on or beside an existing node: join it rather than stack another
    local near
    for _, n in pairs(LC.Nodes) do
        if n ~= last then
            local d = n.pos:Distance(pos)
            if d < JOIN and (not near or d < near.d) and LC.Walkable(pos, n.pos) then near = { n = n, d = d } end
        end
    end

    -- hardly moved from the last node and nothing else to join: nothing to do
    if last and not near then
        local d = last.pos:Distance(pos)
        if d < cvSpacing:GetFloat() and math.abs(last.pos.z - pos.z) < 40 then m.last = last return last end
    end

    local node
    local changed = false
    if near then
        node = near.n
    else
        node = NewNode(m, pos)
        m.count = (m.count or 0) + 1
        changed = true
        if m.count % 10 == 0 then ply:ChatPrint(string.format("[Path mapping] %d nodes laid this session (%d in the map).", m.count, table.Count(LC.Nodes))) end
    end

    if last and LC.Walkable(last.pos, node.pos) and Link(last, node) then changed = true end
    -- close loops: anything else nearby a person could walk to
    local linked = 0
    for _, n in pairs(LC.Nodes) do
        if n ~= node and n ~= last and not node.links[n.id] and linked < 3 and n.pos:DistToSqr(node.pos) < LINK * LINK
            and math.abs(n.pos.z - node.pos.z) < 60 and LC.Walkable(node.pos, n.pos) and LC.Walkable(n.pos, node.pos) then
            if Link(node, n) then linked = linked + 1 changed = true end
        end
    end

    m.last = node
    if changed then
        m.dirty = true
        m.saveAt = CurTime() + SAVE_AFTER
        if LC.RebuildGraph then LC.RebuildGraph() end
    end
    return node
end

function LC.SetPathMapping(ply, on)
    if not IsValid(ply) or not LC.CanEdit(ply) then return false end
    local was = LC.PathMappers[ply]
    if on and not was then
        LC.PathMappers[ply] = { added = {}, count = 0 }
        ply:SetNW2Bool("lc_pathmap", true)
        ply:ChatPrint("[Path mapping] ON. Walk the places NPCs should be able to go. Noclip, jumping and vehicles pause it. Run lc_pathmap again to stop.")
    elseif not on and was then
        Flush(ply, was)
        LC.PathMappers[ply] = nil
        ply:SetNW2Bool("lc_pathmap", false)
        ply:ChatPrint(string.format("[Path mapping] OFF. %d nodes added and saved (%d in the map). Unlinked ones show red in the editor overlay.", was.count or 0, table.Count(LC.Nodes)))
    end
    return true
end

concommand.Add("lc_pathmap", function(ply, _, args)
    if not IsValid(ply) or not LC.CanEdit(ply) then return end
    local want = args[1]
    local on
    if want == "1" then on = true elseif want == "0" then on = false else on = not LC.PathMappers[ply] end
    LC.SetPathMapping(ply, on)
end)

concommand.Add("lc_pathmap_undo", function(ply)
    local m = IsValid(ply) and LC.PathMappers[ply]
    if not m then if IsValid(ply) then ply:ChatPrint("[Path mapping] Turn it on first; undo removes what this session added.") end return end
    local n = 0
    for i = #m.added, 1, -1 do
        if LC.RemoveNode(m.added[i]) then n = n + 1 end
    end
    m.added, m.last, m.count, m.dirty = {}, nil, 0, false
    ply:ChatPrint(string.format("[Path mapping] Removed the %d nodes added this session.", n))
end)

hook.Add("PlayerSay", "LivingCityPathMapChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!pathmap" or t == "/pathmap" then
        if not LC.CanEdit(ply) then ply:ChatPrint("Only editors can map paths.") return "" end
        LC.SetPathMapping(ply, not LC.PathMappers[ply])
        return ""
    end
end)

timer.Create("LivingCityPathMap", 0.25, 0, function()
    local now = CurTime()
    for ply, m in pairs(LC.PathMappers) do
        if not IsValid(ply) then
            LC.PathMappers[ply] = nil
        else
            LC.PathMapStep(ply)
            if m.dirty and now >= (m.saveAt or 0) then Flush(ply, m) end
        end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityPathMap", function(ply)
    local m = LC.PathMappers[ply]
    if m then Flush(nil, m) LC.PathMappers[ply] = nil end
end)
