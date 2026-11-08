--[[
    Living City: quick lookups (server and client)

    LC.EntsOf(cls)   the entities of one class, kept up to date as they're
                     made and removed, instead of searching every entity in
                     the map each time (ents.FindByClass walks them all). The
                     city's own classes (lc_*) are tracked from the start; any
                     other class is tracked from the first time it's asked
                     for. The list is shared: read it, don't change it.
    LC.Players()     every player, for a loop: for _, ply in LC.Players() do.
                     The same players, in the same order, as
                     ipairs(player.GetAll()), but through the game's own
                     player.Iterator where it has one, which keeps one list
                     instead of making a new table on every call (the loops
                     that run every tick, or for every NPC on its turn, made
                     hundreds a second). Don't change the list while looping.
]]

LC = LC or {}

local byClass = {} -- [class] = { set = { [ent] = true }, list = {}, dirty = bool }

local function Bucket(cls)
    local b = byClass[cls]
    if not b then
        -- whatever is already out there (a reload, or the first time it's asked for); kept up to date from now on
        b = { set = {}, list = {}, dirty = true }
        byClass[cls] = b
        if ents and ents.FindByClass then
            for _, e in ipairs(ents.FindByClass(cls)) do b.set[e] = true end
        end
    end
    return b
end

hook.Add("OnEntityCreated", "LivingCityRegistry", function(e)
    if not IsValid(e) then return end
    local cls = e:GetClass()
    if not cls then return end
    local b = byClass[cls]
    if not b then
        if string.sub(cls, 1, 3) ~= "lc_" then return end
        b = Bucket(cls)
    end
    b.set[e] = true
    b.dirty = true
end)

hook.Add("EntityRemoved", "LivingCityRegistry", function(e)
    local cls = e.GetClass and e:GetClass()
    local b = cls and byClass[cls]
    if b and b.set[e] then
        b.set[e] = nil
        b.dirty = true
    end
end)

function LC.EntsOf(cls)
    local b = byClass[cls] or Bucket(cls)
    if b.dirty then
        local list = {}
        for e in pairs(b.set) do
            if IsValid(e) then list[#list + 1] = e else b.set[e] = nil end
        end
        b.list, b.dirty = list, false
    end
    return b.list
end

-- How many of a class there are (no list built twice).
function LC.CountOf(cls) return #LC.EntsOf(cls) end

-- Every player, for a loop (see the top of this file). Looked up on each call, so a game
-- without player.Iterator (or a test) gets ipairs(player.GetAll()), exactly as before.
function LC.Players()
    local it = player and player.Iterator
    if it then return it() end
    return ipairs(player.GetAll())
end
