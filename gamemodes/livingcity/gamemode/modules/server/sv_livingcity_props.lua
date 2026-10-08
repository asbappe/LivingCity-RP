--[[
    Living City: persistent props

    Build mode, spawn any prop and put it where you want it, then zap it with
    the Living City Editor ("Prop: make persistent", left click). It's saved
    in the map's layout with everything else, frozen where it stands, and it's
    there every time the map loads.

      Left click on it again   saves it as it is now (moved, recoloured,
                               re-skinned with the other tools)
      Right click on it        no longer persistent: it stays where it is
                               until the map changes, an ordinary prop again
      The physgun              moves it (build mode): saved where you drop it
      The remover tool         takes it out of the layout as well as the world
      Broken or blown up       it comes back, out of sight, a minute later

    Saved per prop: model, position, angle, skin, colour, material, scale and
    bodygroups.
]]

if CLIENT then return end

LC = LC or {}
LC.Props = LC.Props or {}            -- { id, model, pos, ang, skin, color, material, scale, bodygroups }
LC.PropEnts = LC.PropEnts or {}      -- [id] = entity
LC.NextPropId = LC.NextPropId or 1

local PROP_CLASSES = { prop_physics = true, prop_physics_multiplayer = true, prop_dynamic = true }

local function Tell(ply, msg) if IsValid(ply) then ply:ChatPrint("[Living City] " .. msg) end end

local function Freeze(e)
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
end

-- What a prop looks like right now, as saved data.
local function Capture(e, rec)
    rec.model = e:GetModel()
    rec.pos = e:GetPos()
    rec.ang = e:GetAngles()
    rec.skin = e:GetSkin() or 0
    local c = e:GetColor()
    rec.color = c and { c.r, c.g, c.b, c.a } or nil
    local m = e:GetMaterial()
    rec.material = (m and m ~= "") and m or nil
    local s = e.GetModelScale and e:GetModelScale() or 1
    rec.scale = (s and s ~= 1) and s or nil
    local groups = {}
    if e.GetNumBodyGroups then
        for i = 0, (e:GetNumBodyGroups() or 1) - 1 do
            local v = e:GetBodygroup(i)
            if v and v ~= 0 then groups[tostring(i)] = v end
        end
    end
    rec.bodygroups = next(groups) and groups or nil
    return rec
end

local function Dress(e, rec)
    if rec.skin then e:SetSkin(rec.skin) end
    if rec.color then
        e:SetColor(Color(rec.color[1] or 255, rec.color[2] or 255, rec.color[3] or 255, rec.color[4] or 255))
        if (rec.color[4] or 255) < 255 then e:SetRenderMode(RENDERMODE_TRANSCOLOR) end
    end
    if rec.material then e:SetMaterial(rec.material) end
    if rec.scale and e.SetModelScale then e:SetModelScale(rec.scale, 0) end
    for k, v in pairs(rec.bodygroups or {}) do e:SetBodygroup(tonumber(k) or 0, v) end
end

local function Mark(e, rec)
    e.lcPersistId = rec.id
    e:SetNW2Bool("lc_persist", true)
    LC.PropEnts[rec.id] = e
    rec.goneAt = nil
end

local function RecordOf(id)
    for i, r in ipairs(LC.Props) do if r.id == id then return r, i end end
    return nil
end
LC.PropRecord = RecordOf

-- Make a prop persistent (or, if it already is, save it as it is now).
function LC.PersistProp(ply, e)
    if not IsValid(e) or not PROP_CLASSES[e:GetClass()] then
        return false, "Aim at a prop (one you've spawned)."
    end
    if e:MapCreationID() and e:MapCreationID() >= 0 then
        return false, "That prop is part of the map already: it's always there."
    end
    if e.lcDressing or e.lcRebelProp or e.lcFixture or e.lcQuest then
        return false, "That one belongs to the city (dressing, a supply crate, a fixture or a job). Spawn your own."
    end
    local rec = e.lcPersistId and RecordOf(e.lcPersistId)
    local fresh = rec == nil
    if fresh then
        rec = { id = LC.NextPropId }
        LC.NextPropId = LC.NextPropId + 1
        LC.Props[#LC.Props + 1] = rec
    end
    Freeze(e)
    Capture(e, rec)
    Mark(e, rec)
    LC.SaveData()
    return true, fresh and "new" or "updated", rec
end

-- No longer persistent: out of the layout. keep: leave it in the world as an ordinary prop.
function LC.UnpersistProp(e, keep)
    local id = IsValid(e) and e.lcPersistId
    if not id then return false end
    local _, i = RecordOf(id)
    if i then table.remove(LC.Props, i) end
    LC.PropEnts[id] = nil
    e.lcPersistId = nil
    e:SetNW2Bool("lc_persist", false)
    if not keep then e:Remove() end
    LC.SaveData()
    return true
end

local function SpawnFrom(rec)
    if not rec.model or (util.IsValidModel and not util.IsValidModel(rec.model)) then return nil end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(rec.model)
    e:SetPos(rec.pos)
    e:SetAngles(rec.ang or Angle(0, 0, 0))
    e:Spawn()
    e:Activate()
    Dress(e, rec)
    Freeze(e)
    Mark(e, rec)
    return e
end

-- Put back whatever's missing. now: at once (the map's just loaded), else only
-- out of sight and a minute after it went (broken, blown up).
function LC.SyncProps(now)
    local t = CurTime()
    local want = {}
    for _, rec in ipairs(LC.Props) do
        want[rec.id] = true
        local e = LC.PropEnts[rec.id]
        if not IsValid(e) or e.lcPersistId ~= rec.id then
            rec.goneAt = rec.goneAt or t
            if now or (t - rec.goneAt > 60 and not (LC.IsSeen and LC.IsSeen(rec.pos + Vector(0, 0, 30)))) then
                SpawnFrom(rec)
            end
        end
    end
    -- props whose record went (an undo, a restored backup): gone too
    for id, e in pairs(LC.PropEnts) do
        if not want[id] then
            if IsValid(e) and e.lcPersistId == id then e:Remove() end
            LC.PropEnts[id] = nil
        end
    end
end

-- The layout (re)loaded: everything where it's saved.
hook.Add("LivingCityLayoutChanged", "LivingCityProps", function()
    timer.Simple(0, function()
        local fresh = LC.PropsFresh
        LC.PropsFresh = nil
        local ok, err = pcall(LC.SyncProps, fresh)
        if not ok and LC.Error then LC.Error("persistent props", err) end
    end)
end)
hook.Add("PostCleanupMap", "LivingCityProps", function()
    timer.Simple(0, function() pcall(LC.SyncProps, true) end)
end)
timer.Create("LivingCityProps", 10, 0, function()
    local ok, err = pcall(LC.SyncProps, false)
    if not ok and LC.Error then LC.Error("persistent props", err) end
end)

-- Moved with the physgun (build mode): saved where it's dropped, frozen again.
hook.Add("PhysgunDrop", "LivingCityProps", function(ply, e)
    if not IsValid(e) or not e.lcPersistId or not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local rec = RecordOf(e.lcPersistId)
    if not rec then return end
    Freeze(e)
    Capture(e, rec)
    LC.SaveData()
    Tell(ply, "Moved: the persistent prop is saved where you put it.")
end)

-- The remover tool takes it out of the layout too.
hook.Add("CanTool", "LivingCityProps", function(ply, tr, tool)
    if tool ~= "remover" or not tr or not IsValid(tr.Entity) or not tr.Entity.lcPersistId then return end
    if not (LC.CanEdit and LC.CanEdit(ply)) then return end
    local e = tr.Entity
    local rec = RecordOf(e.lcPersistId)
    if rec then
        local _, i = RecordOf(rec.id)
        table.remove(LC.Props, i)
        LC.PropEnts[rec.id] = nil
        e.lcPersistId = nil
        LC.SaveData()
        Tell(ply, "Removed, and taken out of the layout.")
    end
end)

-- For saving and loading (sv_livingcity_data.lua).
function LC.PropsToSave()
    local out = {}
    for _, r in ipairs(LC.Props) do
        out[#out + 1] = { id = r.id, model = r.model, x = r.pos.x, y = r.pos.y, z = r.pos.z,
            p = r.ang and r.ang.p or 0, yw = r.ang and r.ang.y or 0, rl = r.ang and r.ang.r or 0,
            skin = r.skin, color = r.color, material = r.material, scale = r.scale, bodygroups = r.bodygroups }
    end
    return out
end

function LC.PropsFromSave(list)
    LC.Props = {}
    local top = 0
    for _, t in ipairs(list or {}) do
        if isstring(t.model) and tonumber(t.x) then
            local id = tonumber(t.id) or (top + 1)
            top = math.max(top, id)
            LC.Props[#LC.Props + 1] = {
                id = id, model = t.model, pos = Vector(tonumber(t.x), tonumber(t.y) or 0, tonumber(t.z) or 0),
                ang = Angle(tonumber(t.p) or 0, tonumber(t.yw) or 0, tonumber(t.rl) or 0),
                skin = tonumber(t.skin), color = istable(t.color) and t.color or nil, material = isstring(t.material) and t.material or nil,
                scale = tonumber(t.scale), bodygroups = istable(t.bodygroups) and t.bodygroups or nil,
            }
        end
    end
    LC.NextPropId = math.max(LC.NextPropId or 1, top + 1)
    LC.PropsFresh = true -- (just loaded: put them all out at once)
end
