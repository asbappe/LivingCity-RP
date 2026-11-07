--[[
    Living City: the Endings menu, the server's side (cl_livingcity_endingtune.lua draws it)

      A superadmin picks an ending and tunes it while it plays: every one of its
      settings (lc_ending_<id>_..., saved like any other setting, with the map's
      layout), and its dances, bone by bone. A dance's tuning is a turn added to
      one bone of one move (Bloom's dance, the hora, Father Grigori's headbang...)
      on top of what the code does; it's kept in data/livingcity/ending_tuning.json
      and sent to everyone, so every screen dances the same. So are the few
      settings each player's own game would otherwise keep for itself (Bloom's
      palms, the headbang, the kippah, the chair).
]]

LC = LC or {}

util.AddNetworkString("lc_tune_req")  -- client: open the menu (send me what there is)
util.AddNetworkString("lc_tune_info") -- server: the endings, their settings, the tuning
util.AddNetworkString("lc_tune_set")  -- client: change one thing
util.AddNetworkString("lc_tune_all")  -- server: the dances' tuning, to everyone

local FILE = "livingcity/ending_tuning.json"
LC.EndingTuneFile = FILE

-- the settings everyone's dance shares, though each game has its own (client settings)
local SHARED = { lc_bloom_palm = true, lc_headbang_angle = true, lc_shalom_kippah = true, lc_shalom_chair = true }
LC.EndingTuneShared = SHARED

local tuning = { bones = {}, shared = {} } -- bones[move][bone] = { p, y, r }; shared[name] = "value"

local function Load()
    local raw = file.Read(FILE, "DATA")
    local t = raw and util.JSONToTable(raw)
    if istable(t) then
        tuning.bones = istable(t.bones) and t.bones or {}
        tuning.shared = istable(t.shared) and t.shared or {}
    end
    LC.EndingTuneBaked()
end

-- Tuning sent in and now part of the code itself: the saved copy of it is dropped (once
-- in the code, keeping it too would turn the bone twice). Each: move, bone, { p, y, r }.
local BAKED = {
    -- 20 October: Bloom's hands the right way round on people (the Combine's units have their own)
    { "ears", "L_Hand", { 0, 0, 180 } }, { "ears", "R_Hand", { 0, 0, -180 } },
}
function LC.EndingTuneBaked()
    local changed = false
    for _, b in ipairs(BAKED) do
        local m = tuning.bones[b[1]]
        local o = m and m[b[2]]
        if istable(o) then
            local same = true
            for i = 1, 3 do if math.abs((tonumber(o[i]) or 0) - b[3][i]) > 0.5 then same = false end end
            if same then m[b[2]] = nil changed = true end
            if next(m) == nil then tuning.bones[b[1]] = nil end
        end
    end
    return changed
end
Load()

local function Save()
    timer.Create("LivingCityEndingTuneSave", 1, 1, function()
        file.CreateDir("livingcity")
        file.Write(FILE, util.TableToJSON(tuning, true))
    end)
end

if LC.EndingTuneBaked() then Save() end -- (the saved copy, without what's in the code now)

function LC.EndingTuning() return tuning end

-- Which ending a setting belongs to (nil: not an ending's setting; "all": every ending's)
function LC.EndingSettingGroup(name)
    if name == "lc_endings_on" then return "all" end
    local rest = isstring(name) and string.match(name, "^lc_ending_([%w_]+)$")
    if not rest then return nil end
    if string.sub(rest, 1, 6) == "minge_" then return "harpies" end
    if string.sub(rest, 1, 6) == "flood_" then return "water" end
    local first = string.match(rest, "^([%w]+)_")
    if first and LC.Endings and LC.Endings[first] then return first end
    return "all"
end

local function SendAll(to, omit)
    net.Start("lc_tune_all")
    net.WriteTable(tuning)
    if to then net.Send(to)
    elseif omit and net.SendOmit then net.SendOmit(omit)
    else net.Broadcast() end
end

-- Every other player's game gets the new tuning: at once, then at most every half second
-- while someone drags a slider (each send is the whole tuning, to everyone).
local shareNext, shareOmit, sharePending = 0, nil, false
function LC.EndingTuneShare(omit)
    local now = CurTime()
    if now >= shareNext and not sharePending then
        shareNext = now + 0.5
        return SendAll(nil, omit)
    end
    shareOmit, sharePending = omit, true
    timer.Create("LivingCityEndingTuneShare", math.max(0.05, shareNext - now), 1, function()
        sharePending, shareNext = false, CurTime() + 0.5
        SendAll(nil, IsValid(shareOmit) and shareOmit or nil)
    end)
end

-- everything the menu shows: the endings (and which one is on), and each one's settings
function LC.EndingTuneInfo()
    local list = {}
    for _, id in ipairs(LC.EndingOrder or {}) do
        local e = LC.Endings and LC.Endings[id]
        if e then list[#list + 1] = { id = id, name = e.name } end
    end
    local settings = {}
    for name, info in pairs(LC_SettingInfo or {}) do
        local g = LC.EndingSettingGroup(name)
        local cv = g and GetConVar(name)
        if cv then
            settings[g] = settings[g] or {}
            table.insert(settings[g], { name = name, v = cv:GetString(), d = info.d, help = info.help, min = info.min, max = info.max })
        end
    end
    for _, l in pairs(settings) do table.sort(l, function(a, b) return a.name < b.name end) end
    local E = (LC.EndingAny and LC.EndingAny()) or (LC.EndingSession and LC.EndingSession()) -- (a dream's too)
    return { endings = list, now = E and E.id or nil, phase = E and E.phase or nil, settings = settings, tuning = tuning }
end

net.Receive("lc_tune_req", function(_, ply)
    if not (IsValid(ply) and ply:IsSuperAdmin()) then return end
    net.Start("lc_tune_info")
    net.WriteTable(LC.EndingTuneInfo())
    net.Send(ply)
end)

local function Num(x) x = tonumber(x) or 0 return math.Clamp(x, -360, 360) end

-- kind "bone": move, bone, p, y, r (all 0: back to the code's own);
-- kind "setting": name, value (an ending's setting, or one of the shared ones; "" for the shared one's own again)
function LC.EndingTuneSet(ply, kind, a, b, p, y, r)
    if IsValid(ply) and not ply:IsSuperAdmin() then return false end
    if kind == "bone" then
        if not (isstring(a) and isstring(b) and string.match(a, "^[%w_]+$") and string.match(b, "^[%w_]+$")) or #a > 24 or #b > 24 then return false end
        p, y, r = Num(p), Num(y), Num(r)
        tuning.bones[a] = tuning.bones[a] or {}
        if p == 0 and y == 0 and r == 0 then tuning.bones[a][b] = nil else tuning.bones[a][b] = { p, y, r } end
        if next(tuning.bones[a]) == nil then tuning.bones[a] = nil end
    elseif kind == "setting" then
        if not isstring(a) or not isstring(b) or #b > 400 then return false end
        if SHARED[a] then
            tuning.shared[a] = b ~= "" and b or nil
        elseif LC.EndingSettingGroup(a) and GetConVar(a) then
            RunConsoleCommand(a, b)
            return true
        else
            return false
        end
    else
        return false
    end
    Save()
    LC.EndingTuneShare(IsValid(ply) and ply or nil)
    return true
end

net.Receive("lc_tune_set", function(_, ply)
    local kind = net.ReadString()
    if kind == "bone" then
        LC.EndingTuneSet(ply, kind, net.ReadString(), net.ReadString(), net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    else
        LC.EndingTuneSet(ply, kind, net.ReadString(), net.ReadString())
    end
end)

-- everyone's game dances the same: the tuning on joining
hook.Add("PlayerInitialSpawn", "LivingCityEndingTune", function(ply)
    timer.Simple(5, function() if IsValid(ply) and (next(tuning.bones) or next(tuning.shared)) then SendAll(ply) end end)
end)
