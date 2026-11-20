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
        Raise     The leader (a Commander; a Lieutenant when no Commander is
                  playing: LC.AdminPlotLeader), standing in rebel territory,
                  F2 > Resistance > Raise the flag here. A pole stands where
                  he stood and the flag climbs it for lc_base_setup_time
                  (300 s), but only while he is alive within lc_base_radius
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
local POLE_SCALE = 3
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

local function ShowFlag()
    local s = B.S
    if not s.state then return end
    if not IsValid(s.flag) then
        local e = ents.Create("prop_physics")
        if not IsValid(e) then return end
        e:SetModel(POLE)
        e:SetPos(s.pos)
        e:Spawn()
        if e.SetModelScale then e:SetModelScale(POLE_SCALE, 0) end
        local phys = e.GetPhysicsObject and e:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        e.lcDressing, e.lcSceneProp, e.lcBaseFlag = true, "baseflag", true
        if e.SetNW2Bool then e:SetNW2Bool("lc_baseflag", true) end
        s.flag = e
    end
    if s.flag.SetNW2Float then s.flag:SetNW2Float("lc_flag_h", Height()) end
end

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
    if LC.SafeWrite then LC.SafeWrite(File(), util.TableToJSON(saved, true)) end
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
    if IsValid(s.flag) then s.flag:Remove() end
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
    if not (LC.AdminPlotLeader and LC.AdminPlotLeader(ply)) then return false, "Only the Resistance's leader raises the flag." end
    if not Living(ply) then return false, "Not now." end
    local s = B.S
    if s.state == "overrun" then return false, "The headquarters is overrun: clear it out first." end
    if s.state then return false, "Strike the flag at the old headquarters first." end
    local zone = B.SiteAt(ply:GetPos())
    if not zone then return false, "Only in rebel territory." end
    local fwd = ply.GetAimVector and ply:GetAimVector() or Vector(1, 0, 0)
    fwd = Vector(fwd.x, fwd.y, 0)
    if fwd:Length() < 0.1 then fwd = Vector(1, 0, 0) end
    fwd:Normalize()
    local pos = ply:GetPos() + fwd * 60
    pos = LC.FloorUnder and LC.FloorUnder(pos) or pos
    local g = B.Ground(pos, cvCore:GetFloat())
    if g.wild or g.combine then return false, "Not with them here." end
    B.S = { zone = zone, state = "raising", prog = 0, pos = pos, by = ply, seen = CurTime() }
    ShowFlag()
    return true
end

function LC.BaseStrike(ply)
    local s = B.S
    if not (LC.AdminPlotLeader and LC.AdminPlotLeader(ply)) then return false, "Only the Resistance's leader strikes the flag." end
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
    if not (LC.AdminPlotLeader and LC.AdminPlotLeader(ply)) then return false, "Only the Resistance's leader." end
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
hook.Add("KeyPress", "LivingCityBase", function(ply, key)
    if key == IN_USE and B.S.state and Unit(ply) then LC.BaseTear(ply) end
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
    if LC.BaseOn() and LC.AdminPlotLeader then       -- (who sees the line on their F2: whoever may give it)
        for _, p in ipairs(player.GetAll()) do
            local leads = LC.AdminPlotLeader(p) == true
            if p:GetNW2Bool("lc_res_leads", false) ~= leads then p:SetNW2Bool("lc_res_leads", leads) end
        end
    end
    if not s.state then return end
    local now = CurTime()
    local g = B.Ground(s.pos, cvCore:GetFloat())
    -- a unit at the pole: it comes down, unless a rebel comes back or the unit leaves it
    if s.tear then
        if #g.rebels > 0 or not (Unit(s.tear.by) and Near(s.tear.by, s.pos, 160)) then
            s.tear = nil
        else
            s.tear.t = s.tear.t + dt
            if s.tear.t >= cvTear:GetFloat() then Ransack() return end
        end
    end
    local leaderHere = Rebel(s.by) and LC.AdminPlotLeader and LC.AdminPlotLeader(s.by) and Near(s.by, s.pos, cvRadius:GetFloat())
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
end)
hook.Add("PostCleanupMap", "LivingCityBase", function()      -- (the map's cleanup took the pole and the office: put them back)
    local s = B.S
    if not s.state then return end
    s.flag, s.props = nil, {}
    ShowFlag()
    if s.state ~= "raising" then Office() end
end)

-- (for the tests: as if no flag had ever been raised)
function B.Reset()
    for _, e in pairs(B.S.props or {}) do if IsValid(e) then e:Remove() end end
    if IsValid(B.S.flag) then B.S.flag:Remove() end
    B.S, B.sent = {}, nil
end
