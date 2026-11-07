--[[
    Living City: static map props

    Stoves, sinks and vending machines that are part of the map's compiled
    geometry ("prop_static") aren't entities, so the server can't see them
    the usual way. But the map file lists every one of them, with its model
    and position, so this reads the list straight out of maps/<map>.bsp (the
    game lump "sprp") and remembers the ones that matter:

      stove     cook from your pockets (F3) while you stand by it
      sink      press E to drink, and fill bottles and cans (boil them after)
      vending   press E to buy a can

    The result is LC.StaticFixtures = { { kind, pos, ang, model } }. The
    survival code uses it for E presses and for "near heat" and "near a sink".
    Dumpsters and bins go in LC.StaticBins (same shape): quests send people to
    them, and a can put in one counts as put in the trash. Beds, couches and
    chairs go in LC.StaticRest (kind "bed", "couch" or "seat"): the rebels at
    home sleep and sit on them (sv_livingcity_rebellife.lua).
    lc_scanprops rescans and reports what was found.
]]

if CLIENT then return end

LC = LC or {}
LC.StaticFixtures = LC.StaticFixtures or {}
LC.StaticBins = LC.StaticBins or {}
LC.StaticSurfaces = LC.StaticSurfaces or {}
LC.StaticJunk = LC.StaticJunk or {}
LC.StaticRest = LC.StaticRest or {}
LC.StaticTerminals = LC.StaticTerminals or {}

local KINDS = {
    { "stove", "stove" }, { "furnace", "stove" }, { "oven", "stove" },
    { "sink", "sink" },
    { "toilet", "toilet" }, { "bathtub", "bath" }, { "bath_tub", "bath" }, { "shower", "bath" }, -- (sv_livingcity_hygiene.lua)
    { "vendingmachine", "vending" }, { "vending_machine", "vending" }, { "vending", "vending" },
    -- Combine terminals the Resistance can steal data from (sv_livingcity_heist.lua)
    { "combine_interface", "dataterm" }, { "breenconsole", "dataterm" }, { "combine_intmonitor", "dataterm" },
    { "combine_smallmonitor", "dataterm" }, { "masterinterface", "masterterm" }, -- (the master terminal: the motherlode)
}

-- Dumpsters and bins: not fixtures you use, but places to be.
local BINS = { "dumpster", "trashcan", "trash_can", "trashbin", "garbagecan", "garbage_can",
    "refrigerator", "furniturefridge" } -- fridges too: something to search, and somewhere to keep things
function LC.IsBinModel(model)
    model = string.lower(model or "")
    for _, pat in ipairs(BINS) do
        if string.find(model, pat, 1, true) then return true end
    end
    return false
end

-- Tables, counters, desks and shelves: somewhere to leave (or hide) something.
local SURFACES = { "table", "desk", "counter", "shelf", "shelves", "cabinet", "dresser", "drawer", "workbench", "nightstand", "bookcase" }
function LC.IsSurfaceModel(model)
    model = string.lower(model or "")
    for _, pat in ipairs(SURFACES) do
        if string.find(model, pat, 1, true) then return true end
    end
    return false
end

-- Somewhere to sleep or sit: "bed", "couch" or "seat" (a workbench is a surface, not a bench to sit on).
function LC.RestKindForModel(model)
    model = string.lower(model or "")
    if model == "" or string.find(model, "workbench", 1, true) then return nil end
    for _, pat in ipairs({ "mattress", "furniturebed", "bedframe", "bunkbed", "bunk_bed", "/bed0", "/bed_", "_bed0", "cot0" }) do
        if string.find(model, pat, 1, true) then return "bed" end
    end
    if string.find(model, "couch", 1, true) or string.find(model, "sofa", 1, true) then return "couch" end
    for _, pat in ipairs({ "chair", "stool", "bench" }) do
        if string.find(model, pat, 1, true) then return "seat" end
    end
    return nil
end

-- Junk worth tearing apart with a crowbar (sv_livingcity_salvage.lua): wrecked
-- cars, radiators, pipes, engines, crates, pallets, the city's debris. "big"
-- ones (cars, engines) give more and take longer.
local JUNK = {
    { "props_vehicles/car", true }, { "props_vehicles/truck", true }, { "props_vehicles/van", true },
    { "props_vehicles/trailer", true }, { "props_vehicles/apc", true }, { "props_vehicles/tractor", true },
    { "engine", true }, { "generator", true }, { "radiator" }, { "pipe" }, { "tire" }, { "carparts" },
    { "props_junk/wood_crate" }, { "props_junk/wood_pallet" }, { "props_junk/ibeam" }, { "props_junk/metalbucket" },
    { "props_junk/propane" }, { "props_junk/pushcart" }, { "props_junk/cardboard_box" }, { "props_debris/metal" },
    { "pallet" }, { "crate" }, { "oildrum" }, { "computer" },
    { "props_c17/metalpot" }, { "props_c17/metalladder" },
    { "props_c17/furniturewashingmachine", true }, { "props_c17/furniturestove", true },
    { "props_wasteland/laundry_", true }, { "props_interiors/radiator" }, { "props_lab/monitor" }, { "props_lab/harddrive" }, { "props_lab/reciever" },
    { "props_lab/powerbox" }, { "props_lab/servers" },
}
function LC.IsJunkModel(model)
    model = string.lower(model or "")
    if model == "" or LC.IsBinModel(model) then return false end
    for _, j in ipairs(JUNK) do
        if string.find(model, j[1], 1, true) then return true, j[2] == true end
    end
    return false
end

-- Combine consoles and terminals (the stalkers who look after the Combine's buildings work them:
-- sv_livingcity_zonestalkers.lua). They go in LC.StaticTerminals.
LC.TERMINAL_MODELS = { "props_combine/combine_interface", "props_combine/combine_intmonitor", "props_combine/combine_smallmonitor",
    "props_combine/combine_monitorbay", "props_combine/combine_intwallunit", "props_combine/breenconsole", "props_combine/combine_console" }
function LC.IsTerminalModel(model)
    model = string.lower(model or "")
    if model == "" then return false end
    for _, pat in ipairs(LC.TERMINAL_MODELS) do if string.find(model, pat, 1, true) then return true end end
    return false
end

function LC.FixtureKindForModel(model)
    model = string.lower(model or "")
    if model == "" then return nil end
    for _, k in ipairs(KINDS) do
        if string.find(model, k[1], 1, true) then return k[2] end
    end
    return nil
end

local VBSP = 0x50534256       -- "VBSP"
local GAME_LUMP = 35
local SPRP_A, SPRP_B = 0x73707270, 0x70727073 -- "sprp", whichever way round the map was written

-- Reads the static props of a BSP. Returns a list of fixtures, or nil and why.
function LC.ReadStaticFixtures(path)
    local f = file.Open(path, "rb", "GAME")
    if not f then return nil, "couldn't open " .. path end
    local function done(...) f:Close() return ... end

    if f:ReadLong() ~= VBSP then return done(nil, "not a BSP file") end
    f:ReadLong() -- version
    f:Seek(8 + GAME_LUMP * 16)
    local gofs, glen = f:ReadLong(), f:ReadLong()
    if not glen or glen <= 0 then return done({}) end

    f:Seek(gofs)
    local count = f:ReadLong()
    if count < 0 or count > 64 then return done(nil, "odd game lump directory") end
    local sp
    for _ = 1, count do
        local id, flags, _, ofs, len = f:ReadLong(), f:ReadUShort(), f:ReadUShort(), f:ReadLong(), f:ReadLong()
        if id == SPRP_A or id == SPRP_B then sp = { ofs = ofs, len = len, flags = flags } break end
    end
    if not sp then return done({}) end
    if bit.band(sp.flags, 1) ~= 0 then return done(nil, "the map's static props are compressed") end

    f:Seek(sp.ofs)
    local dictN = f:ReadLong()
    if dictN < 0 or dictN > 100000 then return done(nil, "odd model list") end
    local kinds = {}
    for i = 1, dictN do
        local name = f:Read(128) or ""
        name = string.match(name, "^[^%z]*") or ""
        local kind = LC.FixtureKindForModel(name) or (LC.IsBinModel(name) and "bin") or (LC.IsSurfaceModel(name) and "surface")
            or (LC.RestKindForModel(name) and "rest") or (LC.IsJunkModel(name) and "junk") or (LC.IsTerminalModel(name) and "terminal")
        kinds[i] = kind and { kind, string.lower(name) } or false
    end
    local leafN = f:ReadLong()
    if leafN < 0 then return done(nil, "odd leaf list") end
    f:Seek(f:Tell() + leafN * 2)
    local propN = f:ReadLong()
    local start = f:Tell()
    if propN <= 0 then return done({}) end
    -- the record size depends on the map's version, but origin, angles and the model index lead them all
    local size = math.floor((sp.ofs + sp.len - start) / propN)
    if size < 26 then return done(nil, "odd prop records") end

    local out = {}
    for i = 0, propN - 1 do
        local at = start + i * size
        f:Seek(at + 24)
        local k = kinds[f:ReadUShort() + 1]
        if k then
            f:Seek(at)
            local x, y, z = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
            local p, yw, r = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
            out[#out + 1] = { kind = k[1], pos = Vector(x, y, z), ang = Angle(p, yw, r), model = k[2] }
        end
    end
    return done(out)
end

function LC.ScanStaticProps()
    local list, why = LC.ReadStaticFixtures("maps/" .. game.GetMap() .. ".bsp")
    LC.StaticFixtures, LC.StaticBins, LC.StaticSurfaces, LC.StaticJunk, LC.StaticRest = {}, {}, {}, {}, {}
    LC.StaticTerminals = {}
    for _, fx in ipairs(list or {}) do
        if fx.kind == "rest" then fx.kind = LC.RestKindForModel(fx.model) or "seat" end
        table.insert(fx.kind == "terminal" and LC.StaticTerminals or fx.kind == "bin" and LC.StaticBins or fx.kind == "surface" and LC.StaticSurfaces
            or fx.kind == "junk" and LC.StaticJunk or (fx.kind == "bed" or fx.kind == "couch" or fx.kind == "seat") and LC.StaticRest
            or LC.StaticFixtures, fx)
    end
    LC.StaticScanNote = list and nil or why
    LC.StaticScanned = true
    if list then
        LC.Log("info", string.format("Static props: %d stove/sink/vending fixtures, %d dumpsters or bins, %d tables, counters or shelves, %d beds and seats and %d pieces of junk to salvage found in the map", #LC.StaticFixtures, #LC.StaticBins, #LC.StaticSurfaces, #LC.StaticRest, #LC.StaticJunk))
    else
        LC.Log("warn", "Static props couldn't be read: " .. tostring(why))
    end
    return list ~= nil
end

-- The nearest static fixture of a kind within dist of pos (or any kind if kind is nil).
function LC.StaticFixtureNear(pos, kind, dist)
    local best, bd
    for _, fx in ipairs(LC.StaticFixtures) do
        if not kind or fx.kind == kind then
            local d = fx.pos:DistToSqr(pos)
            if d < dist * dist and (not bd or d < bd) then best, bd = fx, d end
        end
    end
    return best
end

hook.Add("InitPostEntity", "LivingCityStaticProps", function()
    timer.Simple(2, function() local ok, err = pcall(LC.ScanStaticProps) if not ok then LC.Error("staticprops", err) end end)
end)

concommand.Add("lc_scanprops", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok = LC.ScanStaticProps()
    local counts = {}
    for _, fx in ipairs(LC.StaticFixtures) do counts[fx.kind] = (counts[fx.kind] or 0) + 1 end
    local parts = {}
    for k, n in pairs(counts) do parts[#parts + 1] = n .. " " .. k end
    if #LC.StaticBins > 0 then parts[#parts + 1] = #LC.StaticBins .. " dumpsters or bins" end
    if #(LC.StaticJunk or {}) > 0 then parts[#parts + 1] = #LC.StaticJunk .. " pieces of junk to salvage" end
    if #(LC.StaticRest or {}) > 0 then parts[#parts + 1] = #LC.StaticRest .. " beds and seats" end
    local msg = ok and ("[Living City] Static props: " .. (#parts > 0 and table.concat(parts, ", ") or "no stoves, sinks or vending machines")
        or ("[Living City] Couldn't read the map's props: " .. tostring(LC.StaticScanNote)))
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
