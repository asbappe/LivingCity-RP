--[[
    Living City: the Resistance's headquarters (one live base at a time)

      The owner, 20 November: "the highest ranking Resistance player
      (Lieutenant or Commander) can alter the location of the resistance HQ
      ... which he has to visit and be present at ... it takes 5 minutes
      with him nearby (within 300 feet radius or so) to setup"; "setup could
      literally be hoisting the flag up the pole slowly"; the commander's
      office ("securitybank.mdl with all the camera monitors, his desk,
      shelves, any computers or consoles, board, even the science lab")
      does "not show until the base is established"; and, to stop leaders
      "running in a big circle around the map moving CONSTANTLY", the base
      moves only three ways: "they move willingly ... so they have to
      packup the commander's office", "the combine come in and destroy
      everything and ransack it ... confiscating some of the credits", or
      "zombies or antlions take over ... but the resources CAN be reclaimed
      if they went in and took it back".

      So:
        Poles     A bare pole stands in every rebel territory (where a
                  leader last planted it, else at the map's lc_hq_setup, else
                  in the middle of the camp).
        Raise     Any Lieutenant or Commander of the Resistance, at the pole:
                  E (or, anywhere in rebel territory, F2 > Resistance >
                  Raise the flag here, which plants the pole where he
                  stands). Whoever of those ranks is near keeps it going,
                  so a leader who leaves strands nobody. A pole stands where
                  he stood (as tall as fits: short under a roof or a
                  bridge; at a map marker with a ..._top marker above it,
                  as tall as that: the silo's pole, raised from its bottom
                  floor, flies its flag on its top floor) and the flag
                  climbs it for lc_base_setup_time (300 s), but only while he is alive within lc_base_radius
                  (4800 units: 300 feet) and nothing hostile is within
                  lc_base_core (700) of the pole. Left for a minute, it
                  slides back down. At the top the base is live and the
                  office appears round the pole.
        Strike    The same F2 line at the live base, once it has stood
                  lc_base_stay (600 s): the flag comes down over
                  lc_base_pack_time (180 s) with him near; at the bottom the
                  office is packed and a flag may be raised somewhere else.
        Ransack   A Civil Protection or Overwatch unit presses E at the
                  pole while no living Resistance player is within the core:
                  the flag comes down in lc_base_teardown (20 s) as long as
                  the unit stays by it and no rebel comes back. At the
                  bottom the office is destroyed, lc_base_ransack_share (35)
                  per cent of the fund is shared among the units in the
                  core, and the Resistance has no base.
        Overrun   Zombies, headcrabs or antlions within the core and no
                  living rebel there for lc_base_overrun (45 s): the flag
                  drops to half mast and the base is not live. The office
                  stays. Clear them out and stand there 20 s and it is live
                  again (or strike it then). No flag goes up elsewhere while
                  it is overrun.

      The flag is the only thing that says any of this: no notices.
      The office's things are the camp's own (a held E carries them,
      sv_livingcity_campmove.lua); where each was left at a site is kept
      (data/livingcity/<map>_base.json) and it comes back there, so each
      site's office is laid out once by hand. The camps' security monitors
      (sv_livingcity_sceneprops.lua) are now part of the office: they stand
      only at the live base, not in every camp.

      For other code: LC.BaseLive() (the base's zone, or nil), LC.BaseState(),
      hooks LivingCityBaseLive(zone), LivingCityBaseGone(zone, how) with how
      "packed", "ransacked" or "abandoned", LivingCityBaseRansacked(zone,
      credits, unit). Globals for the menu: lc_base (the state).
      Settings: lc_base (1: on), and those named above.
]]

if CLIENT then return end

LC = LC or {}
LC.Base = LC.Base or {}
local B = LC.Base

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_base", "1", FLAGS, "The Resistance has one headquarters at a time, set up by its leader raising a flag (0: off, and every camp has its monitors as before)", 0, 1)
local cvSetup = CreateConVar("lc_base_setup_time", "300", FLAGS, "Seconds the flag takes to climb the pole (setting the headquarters up)", 5, 3600)
local cvPack = CreateConVar("lc_base_pack_time", "180", FLAGS, "Seconds the flag takes to come down when the leader strikes it (packing the headquarters up)", 5, 3600)
local cvStay = CreateConVar("lc_base_stay", "600", FLAGS, "Seconds a headquarters must have stood before its leader may strike the flag", 0, 36000)
local cvRadius = CreateConVar("lc_base_radius", "4800", FLAGS, "How near the pole the leader must stay while the flag goes up or comes down (4800 units is 300 feet)", 100, 30000)
local cvCore = CreateConVar("lc_base_core", "700", FLAGS, "How near the pole counts as holding the headquarters' ground", 100, 5000)
local cvTear = CreateConVar("lc_base_teardown", "20", FLAGS, "Seconds a unit takes to tear the flag down", 1, 600)
local cvShare = CreateConVar("lc_base_ransack_share", "35", FLAGS, "Per cent of the Resistance's fund the units take when they ransack the headquarters", 0, 100)
local cvOverrun = CreateConVar("lc_base_overrun", "45", FLAGS, "Seconds zombies or antlions hold the headquarters' ground, with no rebel there, before it is overrun", 1, 3600)

local POLE = "models/props_c17/signpole001.mdl"
local POLE_MODEL_HIGH, POLE_HIGH, POLE_LOW = 110, 330, 110   -- the model's own height; a pole in the open; the shortest pole
local POLE_TALL = 4096 -- the tallest pole a map's _top marker may ask for
local RECLAIM = 20     -- seconds a rebel stands in a cleared, overrun base before it is live again
local SLIDE = 60       -- seconds the leader may be away before a half-raised flag starts back down
-- The commander's office: what appears round the pole when the base is live.
LC.BaseOffice = {
    { kind = "bank", model = "models/props_lab/securitybank.mdl" },
    { kind = "desk", model = "models/props_wasteland/controlroom_desk001a.mdl" },
    { kind = "console", model = "models/props_lab/workspace002.mdl" },
    { kind = "shelves", model = "models/props_wasteland/kitchen_shelf002a.mdl" },
    { kind = "lab", model = "models/props_lab/workspace003.mdl" },
    { kind = "servers", model = "models/props_lab/servers.mdl" },
    { kind = "board", model = "models/props_lab/corkboard001.mdl", up = 48 },
}
local WILD = { npc_zombie = true, npc_zombie_torso = true, npc_fastzombie = true, npc_fastzombie_torso = true, npc_poisonzombie = true, npc_zombine = true,
    npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true, npc_antlion = true, npc_antlionguard = true,
    npc_antlion_worker = true }
local COMBINE_NPC = { npc_metropolice = true, npc_combine_s = true, npc_hunter = true, npc_manhack = true, npc_strider = true }

B.S = B.S or {}        -- the base: zone, state ("raising", "live", "striking", "overrun"), prog (0..1), pos, flag, by, liveAt, props

function LC.BaseOn() return cvOn:GetBool() end
function LC.BaseState() return B.S.state end
function LC.BaseLive() return B.S.state == "live" and B.S.zone or nil end
-- Is this camp the one whose office shows? (For the camps' own dressing.)
function LC.BaseShows(z)
    local s = B.S
    if not (s.zone and (s.state == "live" or s.state == "overrun" or s.state == "striking")) then return false end
    return (LC.RebelLeader and LC.RebelLeader(z) or z) == s.zone
end

local function Faction(p) return IsValid(p) and p.GetNW2String and p:GetNW2String("lcf_faction", "") or "" end
local function Living(p) return IsValid(p) and (not p.Alive or p:Alive()) end
local function Rebel(p) return Faction(p) == "resistance" and Living(p) end
local function Unit(p) local f = Faction(p) return (f == "cp" or f == "ota") and Living(p) end
local function Near(p, pos, r) return IsValid(p) and p:GetPos():DistToSqr(pos) <= r * r end

-- Who may raise and strike the flag: any Lieutenant or Commander of the Resistance (the owner, 20 November: "Resistance
-- Commander or Lieutenant is required to establish a Resistance HQ"; so a Commander who leaves in the middle of a move
-- leaves nobody stranded: any Lieutenant carries on).
local ltIndex
function LC.BaseMayLead(ply)
    if not Rebel(ply) then return false end
    if not ltIndex then
        local fac = LCF and LCF.Get and LCF.Get("resistance")
        for i, r in ipairs(fac and fac.ranks or {}) do if r.name == "Lieutenant" then ltIndex = i end end
        ltIndex = ltIndex or 4
    end
    return ply:GetNW2Int("lcf_rank", 1) >= ltIndex
end
local MayLead = LC.BaseMayLead

-- Who is on the base's ground: rebels, units, and whether anything wild or the Combine's own is there.
function B.Ground(pos, r)
    local out = { rebels = {}, units = {}, wild = false, combine = false }
    for _, p in ipairs(player.GetAll()) do
        if Near(p, pos, r) then
            if Rebel(p) then out.rebels[#out.rebels + 1] = p
            elseif Unit(p) then out.units[#out.units + 1] = p out.combine = true
            elseif Faction(p) == "zombie" and Living(p) then out.wild = true end
        end
    end
    for _, e in ipairs(ents.FindInSphere and ents.FindInSphere(pos, r) or {}) do
        if IsValid(e) and e.IsNPC and e:IsNPC() and (not e.Health or e:Health() > 0) then
            local c = e:GetClass()
            if WILD[c] then out.wild = true elseif COMBINE_NPC[c] then out.combine = true end
        end
    end
    return out
end

-- The rebel territory a place is in (its leading zone), or nil.
function B.SiteAt(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if LCZ.Contains(z, pos, 0) then return LC.RebelLeader and LC.RebelLeader(z) or z end
    end
    return nil
end

------------------------------------------------------------------------
-- The flag and the office
------------------------------------------------------------------------

local function Height()
    local s = B.S
    if not s.state then return 0 end
    local h = (s.state == "live" and 1) or (s.state == "overrun" and 0.5) or (s.prog or 0)
    if s.tear then h = h * (1 - math.Clamp(s.tear.t / math.max(1, cvTear:GetFloat()), 0, 1)) end
    return h
end

-- The map's own spots for a pole: every info_target named lc_hq_setup..., where its pole stands (the floor under it) and,
-- when a second info_target named the same with _top added stands above it, how tall (to that marker: the owner,
-- 21 November, of the silo: raised "from the bottom of the silo" with "the flag ... flush with eye level on the top
-- floor"). A ..._top marker is never a spot of its own. Each: { ent, pos, high } (high nil: no _top).
function B.Markers()
    local found = ents.FindByName and ents.FindByName("lc_hq_setup*") or {}
    local function Name(t) return string.lower(tostring(t.GetName and t:GetName() or "")) end
    local tops = {}
    for _, t in ipairs(found) do
        local n = IsValid(t) and Name(t) or ""
        if string.sub(n, -4) == "_top" then
            local key = string.sub(n, 1, -5)
            tops[key] = tops[key] or {}
            table.insert(tops[key], t)
        end
    end
    local out = {}
    for _, t in ipairs(found) do
        if IsValid(t) and string.sub(Name(t), -4) ~= "_top" then
            local pos = LC.FloorUnder and LC.FloorUnder(t:GetPos()) or t:GetPos()
            local high, best
            for _, top in ipairs(tops[Name(t)] or {}) do      -- (the nearest of its _top markers above it; only its height counts)
                local p = IsValid(top) and top:GetPos()
                if p and p.z > pos.z then
                    local d = (p.x - pos.x) ^ 2 + (p.y - pos.y) ^ 2
                    if not best or d < best then best, high = d, math.Clamp(math.floor(p.z - pos.z), POLE_LOW, POLE_TALL) end
                end
            end
            out[#out + 1] = { ent = t, pos = pos, high = high }
        end
    end
    return out
end

-- How tall a pole may stand here: at a map marker with a _top marker, as tall as that marker says; else under a roof (a
-- bridge, a tunnel, a room) only as tall as fits, so a base in the canal's shantytown shows no flag over the canal's
-- walls (the owner, 20 November: "a short flagpole").
local function HighAt(pos)
    for _, m in ipairs(B.Markers()) do
        if m.high and math.abs(m.pos.z - pos.z) <= 48 and (m.pos.x - pos.x) ^ 2 + (m.pos.y - pos.y) ^ 2 <= 16 * 16 then return m.high end
    end
    local tr = util.TraceLine and util.TraceLine({ start = pos + Vector(0, 0, 8), endpos = pos + Vector(0, 0, POLE_HIGH + 60), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit and tr.HitPos then return math.Clamp(math.floor(tr.HitPos.z - pos.z - 24), POLE_LOW, POLE_HIGH) end
    return POLE_HIGH
end

local function Piece(pos, scale)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return nil end
    e:SetModel(POLE)
    e:SetPos(pos)
    e:Spawn()
    if e.SetModelScale then e:SetModelScale(scale, 0) end
    local phys = e.GetPhysicsObject and e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcDressing, e.lcSceneProp = true, "baseflag"
    return e
end
local function Unstack(e) for _, p in ipairs(e.lcParts or {}) do if IsValid(p) then p:Remove() end end end
-- A pole: one piece, scaled to its height. A pole taller than one in the open (a map's _top marker: the silo's) is a
-- stack of pieces each about as tall and thick as one in the open, since the model scales the same every way: one
-- piece 1700 tall would be 15 times as thick. The foot piece is the pole (the flag's numbers, E at it); the rest stand
-- on it and go with it.
local function Pole(pos, high)
    local n = high > POLE_HIGH and math.ceil(high / POLE_HIGH) or 1
    local e = Piece(pos, high / n / POLE_MODEL_HIGH)
    if not IsValid(e) then return nil end
    e.lcBaseFlag, e.lcHigh = true, high
    if n > 1 then
        e.lcParts = {}
        for i = 1, n - 1 do
            local p = Piece(pos + Vector(0, 0, high * i / n), high / n / POLE_MODEL_HIGH)
            if IsValid(p) then e.lcParts[#e.lcParts + 1] = p end
        end
        if e.CallOnRemove then e:CallOnRemove("lc_pole_parts", Unstack) end
    end
    if e.SetNW2Bool then
        e:SetNW2Bool("lc_baseflag", true)
        e:SetNW2Float("lc_flag_top", high)
        e:SetNW2Float("lc_flag_h", 0)
        e:SetNW2Bool("lc_flag_up", false)
    end
    return e
end
local function Drop(e) if IsValid(e) then Unstack(e) e:Remove() end end

local saved
local function File() return "livingcity/" .. game.GetMap() .. "_base.json" end
local function Load()
    if not saved then
        local t = LC.SafeReadJSON and LC.SafeReadJSON(File())
        saved = istable(t) and t or {}
    end
    return saved
end
function B.Forget() saved = nil end
local function Write() if LC.SafeWrite then LC.SafeWrite(File(), util.TableToJSON(saved or {}, true)) end end

-- Where a territory's pole stands: where a leader last planted it, else the map's own spot for it (an info_target
-- named lc_hq_setup inside the territory; one with a _top marker first), else the middle of the camp.
function B.PoleSpot(zone)
    local key = LC.CampKey and LC.CampKey(zone)
    local w = key and Load()[key .. "_pole"]
    if w then return Vector(w.x, w.y, w.z) end
    local first
    for _, m in ipairs(B.Markers()) do
        if B.SiteAt(m.ent:GetPos()) == zone then
            if m.high then return m.pos end
            first = first or m.pos
        end
    end
    if first then return first end
    return LC.FloorUnder and LC.FloorUnder(zone.pos) or zone.pos
end

-- A bare pole in every rebel territory (the owner, 20 November: any member can walk up to it; only a Lieutenant or
-- Commander can raise the flag on it), and at every one of the map's own spots for one (an info_target named
-- lc_hq_setup...) whether a territory covers it or not (the owner, 20 November: "always stand a bare pole at the
-- markers"). Outside a territory nobody can raise a flag on it: E there says it takes rebel territory.
B.poles = B.poles or {}
function B.Poles()
    local live = {}
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        local lead = LC.RebelLeader and LC.RebelLeader(z) or z
        if not live[lead] then
            live[lead] = true
            if not IsValid(B.poles[lead]) then
                local pos = B.PoleSpot(lead)
                B.poles[lead] = Pole(pos, HighAt(pos))
            end
        end
    end
    for _, m in ipairs(B.Markers()) do
        if not B.SiteAt(m.ent:GetPos()) then
            local pos = m.pos
            local key = string.format("marker %d %d %d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
            live[key] = true
            if not IsValid(B.poles[key]) then B.poles[key] = Pole(pos, HighAt(pos)) end
        end
    end
    for z, e in pairs(B.poles) do
        if not live[z] then
            Drop(e)
            B.poles[z] = nil
        end
    end
end
-- The pole a player is standing at (within reach), and its territory.
function B.PoleAt(ply, reach)
    for z, e in pairs(B.poles) do
        if IsValid(e) and Near(ply, e:GetPos(), reach or 110) then return e, z end
    end
    return nil
end

local function ShowFlag()
    local s = B.S
    if not s.state then return end
    if not IsValid(s.flag) then
        local e = B.poles[s.zone]
        if IsValid(e) and (e:GetPos():DistToSqr(s.pos) > 4 or e.lcHigh ~= (s.high or POLE_HIGH)) then Drop(e) e = nil end   -- (planted somewhere new)
        if not IsValid(e) then e = Pole(s.pos, s.high or POLE_HIGH) end
        if not IsValid(e) then return end
        B.poles[s.zone] = e
        s.flag = e
    end
    if s.flag.SetNW2Float then
        s.flag:SetNW2Float("lc_flag_h", Height())
        s.flag:SetNW2Bool("lc_flag_up", true)
    end
end

-- Where the office's things stand now is where they come back to at this site.
function B.Remember()
    local s = B.S
    if not (s.zone and s.props and LC.CampKey) then return end
    local at = {}
    for kind, e in pairs(s.props) do
        if IsValid(e) then
            local p = e:GetPos()
            at[kind] = { x = p.x, y = p.y, z = p.z, yaw = e:GetAngles().y }
        end
    end
    if next(at) == nil then return end
    Load()[LC.CampKey(s.zone)] = at
    Write()
end

local function Office()
    local s = B.S
    s.props = s.props or {}
    local at = LC.CampKey and Load()[LC.CampKey(s.zone)] or {}
    local n = #LC.BaseOffice
    for i, it in ipairs(LC.BaseOffice) do
        if not IsValid(s.props[it.kind]) and (not util.IsValidModel or util.IsValidModel(it.model)) and LC.ScenePlace then
            local w = at[it.kind]
            local pos, yaw
            if w then
                pos, yaw = Vector(w.x, w.y, w.z), w.yaw or 0
            else      -- (never laid out here: in a ring round the pole, facing it, for somebody to arrange)
                local a = (i - 1) * 2 * math.pi / n
                local p = s.pos + Vector(math.cos(a) * 150, math.sin(a) * 150, 0)
                p = LC.FloorUnder and LC.FloorUnder(p) or p
                pos, yaw = p + Vector(0, 0, it.up or 0), math.deg(a) + 180
            end
            local e = LC.ScenePlace(it.model, pos, yaw, "office", it.kind)
            if IsValid(e) then
                if not w and e.OBBMins then pos = pos - Vector(0, 0, e:OBBMins().z - 0.5) e:SetPos(pos) end
                e.lcCampZone = s.zone
                s.props[it.kind] = e
            end
        end
    end
end

local function Clear(destroyed)
    local s = B.S
    if not destroyed then B.Remember() end
    for _, e in pairs(s.props or {}) do if IsValid(e) then e:Remove() end end
    if IsValid(s.flag) and s.flag.SetNW2Float then      -- (the pole stays: bare again)
        s.flag:SetNW2Float("lc_flag_h", 0)
        s.flag:SetNW2Bool("lc_flag_up", false)
    end
    B.S = {}
end

local function Gone(how)
    local zone = B.S.zone
    Clear(how == "ransacked")
    hook.Run("LivingCityBaseGone", zone, how)
    if LC.Log then LC.Log("info", "The Resistance's headquarters is gone (" .. how .. ")") end
end

------------------------------------------------------------------------
-- The leader's F2 line
------------------------------------------------------------------------

function LC.BaseRaise(ply)
    if not LC.BaseOn() then return false, "No headquarters on this server." end
    if not MayLead(ply) then return false, "A Resistance Commander or Lieutenant is required." end
    if not Living(ply) then return false, "Not now." end
    local s = B.S
    if s.state == "overrun" then return false, "The headquarters is overrun: clear it out first." end
    if s.state then return false, "Strike the flag at the old headquarters first." end
    local zone = B.SiteAt(ply:GetPos())
    if not zone then return false, "Only in rebel territory." end
    local pos
    local pole, poleZone = B.PoleAt(ply, 150)
    if IsValid(pole) and poleZone == zone then
        pos = pole:GetPos()                              -- (at the territory's own pole)
    else                                                 -- (from F2, away from it: the pole is planted where he stands, and stays there)
        local fwd = ply.GetAimVector and ply:GetAimVector() or Vector(1, 0, 0)
        fwd = Vector(fwd.x, fwd.y, 0)
        if fwd:Length() < 0.1 then fwd = Vector(1, 0, 0) end
        fwd:Normalize()
        pos = ply:GetPos() + fwd * 60
        pos = LC.FloorUnder and LC.FloorUnder(pos) or pos
        if LC.CampKey then
            Load()[LC.CampKey(zone) .. "_pole"] = { x = pos.x, y = pos.y, z = pos.z }
            Write()
        end
    end
    local g = B.Ground(pos, cvCore:GetFloat())
    if g.wild or g.combine then return false, "Not with them here." end
    local high = HighAt(pos)
    B.S = { zone = zone, state = "raising", prog = 0, pos = pos, by = ply, seen = CurTime(), high = high }
    ShowFlag()
    return true
end

function LC.BaseStrike(ply)
    local s = B.S
    if not MayLead(ply) then return false, "A Resistance Commander or Lieutenant is required." end
    if s.state ~= "live" then return false, "No headquarters to pack up." end
    if not Near(ply, s.pos, cvRadius:GetFloat()) then return false, "Go to the headquarters." end
    local left = (s.liveAt or 0) + cvStay:GetFloat() - CurTime()
    if left > 0 then return false, string.format("Too soon: %d minutes yet.", math.ceil(left / 60)) end
    s.state, s.prog, s.by, s.seen = "striking", 1, ply, CurTime()
    return true
end

-- One line on the leader's F2 does whatever comes next.
function LC.BaseOrder(ply)
    local s = B.S
    if not s.state then return LC.BaseRaise(ply) end
    if not MayLead(ply) then return false, "A Resistance Commander or Lieutenant is required." end
    if s.state == "raising" then Gone("abandoned") return true end
    if s.state == "live" then return LC.BaseStrike(ply) end
    if s.state == "striking" then s.state, s.prog, s.liveAt = "live", 1, s.liveAt or CurTime() return true end
    return false, "The headquarters is overrun: clear it out first."
end

LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.base = function(ply)
    local ok, why = LC.BaseOrder(ply)
    return ok, why and ("[Resistance] " .. why) or nil
end

------------------------------------------------------------------------
-- A unit tears the flag down
------------------------------------------------------------------------

function LC.BaseTear(ply)
    local s = B.S
    if not (s.state and Unit(ply) and Near(ply, s.pos, 110)) then return false end
    if s.tear then return false end
    if #B.Ground(s.pos, cvCore:GetFloat()).rebels > 0 then return false end
    s.tear = { by = ply, t = 0 }
    return true
end
-- A raid's own NPC unit at the pole (sv_livingcity_hq.lua): tears it down the same way, while no rebel is near.
function LC.BaseTearNPC(npc)
    local s = B.S
    if not (s.state and IsValid(npc) and npc:IsNPC() and npc:Health() > 0 and Near(npc, s.pos, 110)) then return false end
    if s.tear then return false end
    if #B.Ground(s.pos, cvCore:GetFloat()).rebels > 0 then return false end
    s.tear = { by = npc, t = 0 }
    return true
end
-- E at a pole: a unit tears a flying flag down; a Lieutenant or Commander does what their F2 line does. (Anyone else of
-- the Resistance is told by the pole's own prompt that it takes one of those: cl_livingcity_base.lua.)
function LC.BasePoleUse(ply)
    if not LC.BaseOn() then return false end
    if Unit(ply) then return B.S.state ~= nil and LC.BaseTear(ply) end
    if not MayLead(ply) then return false end
    local pole, zone = B.PoleAt(ply, 110)
    if not IsValid(pole) then return false end
    if B.S.state and B.S.zone ~= zone then return false end      -- (another territory's bare pole while a flag flies elsewhere)
    return LC.BaseOrder(ply)
end
hook.Add("KeyPress", "LivingCityBase", function(ply, key)
    if key == IN_USE then LC.BasePoleUse(ply) end
end)

local function Ransack()
    local s = B.S
    local units = B.Ground(s.pos, cvCore:GetFloat()).units
    local fund = LC.ResistanceFund and LC.ResistanceFund() or 0
    local taken = math.floor(math.max(0, fund) * cvShare:GetFloat() / 100)
    if taken > 0 and LC.ResistanceFundTake then LC.ResistanceFundTake(taken, "the headquarters ransacked", s.tear and s.tear.by) end
    if taken > 0 and #units > 0 and LC.AddCredits then
        local each = math.floor(taken / #units)
        for _, u in ipairs(units) do if each > 0 then LC.AddCredits(u, each, "the Resistance's headquarters") end end
    end
    local zone, unit = s.zone, s.tear and s.tear.by
    Gone("ransacked")
    hook.Run("LivingCityBaseRansacked", zone, taken, unit)
end

------------------------------------------------------------------------
-- Every second
------------------------------------------------------------------------

function B.Tick(dt)
    dt = dt or 1
    local s = B.S
    local st = s.state or ""
    if st ~= B.sent then
        B.sent = st
        SetGlobal2String("lc_base", st)
    end
    if LC.BaseOn() ~= B.sentOn then
        B.sentOn = LC.BaseOn()
        SetGlobal2Bool("lc_base_on", B.sentOn)
    end
    if LC.BaseOn() then       -- (who sees the line on their F2, and the pole's prompt: whoever may give it)
        for _, p in ipairs(player.GetAll()) do
            local may = MayLead(p) == true
            if p:GetNW2Bool("lc_base_may", false) ~= may then p:SetNW2Bool("lc_base_may", may) end
        end
        B.poleLook = (B.poleLook or 0) + dt
        if B.poleLook >= 5 or not B.poled then B.poleLook, B.poled = 0, true B.Poles() end
    end
    if not s.state then return end
    local now = CurTime()
    local g = B.Ground(s.pos, cvCore:GetFloat())
    -- a unit at the pole: it comes down, unless a rebel comes back or the unit leaves it
    if s.tear then
        local tearer = Unit(s.tear.by) or (IsValid(s.tear.by) and s.tear.by.IsNPC and s.tear.by:IsNPC() and s.tear.by:Health() > 0)
        if #g.rebels > 0 or not (tearer and Near(s.tear.by, s.pos, 160)) then
            s.tear = nil
        else
            s.tear.t = s.tear.t + dt
            if s.tear.t >= cvTear:GetFloat() then Ransack() return end
        end
    end
    local leaderHere = false      -- (whoever raised it, or any other Lieutenant or Commander: the move does not hang on one player)
    for _, p in ipairs(player.GetAll()) do
        if MayLead(p) and Near(p, s.pos, cvRadius:GetFloat()) then leaderHere = true break end
    end
    if s.state == "raising" then
        if leaderHere then s.seen = now end
        if leaderHere and not (g.wild or g.combine) then
            s.prog = s.prog + dt / math.max(1, cvSetup:GetFloat())
            if s.prog >= 1 then
                s.state, s.prog, s.liveAt = "live", 1, now
                Office()
                hook.Run("LivingCityBaseLive", s.zone)
                if LC.Log then LC.Log("info", "The Resistance's headquarters is set up") end
            end
        elseif now - (s.seen or now) > SLIDE then
            s.prog = s.prog - dt / 30
            if s.prog <= 0 then Gone("abandoned") return end
        end
    elseif s.state == "striking" then
        if leaderHere and not (g.wild or g.combine) then
            s.prog = s.prog - dt / math.max(1, cvPack:GetFloat())
            if s.prog <= 0 then Gone("packed") return end
        end
    elseif s.state == "live" then
        if g.wild and #g.rebels == 0 then
            s.wildSince = s.wildSince or now
            if now - s.wildSince >= cvOverrun:GetFloat() then s.state, s.wildSince, s.clearSince = "overrun", nil, nil end
        else
            s.wildSince = nil
        end
        Office()      -- (anything of the office that could not be put out before)
        s.kept = (s.kept or 0) + dt
        if s.kept >= 30 then s.kept = 0 B.Remember() end
    elseif s.state == "overrun" then
        if not g.wild and #g.rebels > 0 then
            s.clearSince = s.clearSince or now
            if now - s.clearSince >= RECLAIM then s.state, s.clearSince = "live", nil end
        else
            s.clearSince = nil
        end
    end
    ShowFlag()
end

timer.Create("LivingCityBase", 1, 0, function()
    local ok, err = LC.Try(B.Tick, 1)
    if not ok and LC.Error then LC.Error("headquarters", err) end
end)

hook.Add("LivingCityStopped", "LivingCityBase", function()
    if B.S.state then Clear(false) end
    for z, e in pairs(B.poles) do Drop(e) end
    B.poles, B.poled = {}, nil
end)
hook.Add("PostCleanupMap", "LivingCityBase", function()      -- (the map's cleanup took the pole and the office: put them back)
    local s = B.S
    if not s.state then return end
    s.flag, s.props = nil, {}
    B.poles = {}
    B.Poles()
    ShowFlag()
    if s.state ~= "raising" then Office() end
end)

-- (for the tests: as if no flag had ever been raised)
function B.Reset()
    for _, e in pairs(B.S.props or {}) do if IsValid(e) then e:Remove() end end
    for z, e in pairs(B.poles) do Drop(e) end
    B.S, B.sent, B.poles, B.poled = {}, nil, {}, nil
end
