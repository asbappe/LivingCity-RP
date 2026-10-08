--[[
    Living City: salvage, bins anywhere, the reclamation point, and workbenches

      Salvage       hold a crowbar and press E on junk: a wrecked car, a
                    radiator, pipes, an engine, a crate, a pallet, a fridge,
                    the city's debris (the map's own props, or a "salvage
                    pile" point placed in the editor). A few seconds of prying
                    gets scrap, rags, chemicals, now and then gun parts. It's
                    loud: units nearby hear it, and the nearest Civil
                    Protection on the street walks over to look. Each piece
                    has to sit for lc_salvage_refill seconds (900) before
                    there's anything left to take. Breaking a crate open, with
                    anything, sometimes spills something useful too.
      The crowbar   is a weapon as much as a tool, so it's contraband: the
                    black market sells them, the Resistance lab makes them, searches
                    always find them, and a unit who sees you with one out
                    makes you wanted (lc_crowbar_wanted seconds, 120). Rebel
                    ground is the exception.
      Bin points    the editor's "Point: searchable bin" turns any spot (a
                    rubbish pile, a skip, a crate the map's props don't count
                    as a bin) into one, for maps short on real bins.
      Reclamation   a Union reclamation point (editor fixture): press E and
                    hand in scrap, empty cans and bottles for a few credits
                    and a little Civil Standing, up to lc_reclaim_cap credits
                    (40) an hour. The loyal way to use junk. The Resistance
                    would rather you kept it.
      Workbench     a lab bench (the editor's Resistance lab, which has a
                    scientist: sv_livingcity_lab.lua) or any workbench the map
                    already has. Rebels at home busy themselves at one
                    (sv_livingcity_rebellife.lua).

      Guarded       in rebel territory, a rebel who sees someone prying at or
                    smashing their crates warns them twice, then shoves, then
                    hits harder, and only after that turns on them
                    (lc_rebel_guard 0/1). Resistance members are never stopped.

      lc_salvage 0/1, lc_rebel_guard 0/1, lc_salvage_refill (900), lc_crowbar_wanted (120),
      lc_reclaim_cap (40)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_salvage", "1", FLAGS, "Players can tear junk apart with a crowbar for materials")
local cvRefill  = CreateConVar("lc_salvage_refill", "900", FLAGS, "Seconds before a salvaged piece of junk has anything left to take")
local cvCrowbar = CreateConVar("lc_crowbar_wanted", "120", FLAGS, "Seconds wanted for being seen by security with a crowbar out (0: never)")
local cvReclaim = CreateConVar("lc_reclaim_cap", "40", FLAGS, "Most credits a player can earn at reclamation points in an hour")

local REACH = 110

------------------------------------------------------------------------
-- What there is to salvage
------------------------------------------------------------------------

local SALVAGE = {
    { nil, 14 }, { "scrap", 50 }, { "cloth", 12 }, { "chemicals", 9 }, { "can_empty", 6 }, { "gun_parts", 2 },
}
local SALVAGE_BIG = { -- cars and engines: metal, and the fluids in them
    { nil, 6 }, { "scrap", 55 }, { "chemicals", 20 }, { "cloth", 8 }, { "gun_parts", 3 },
}
local function Roll(tbl)
    local total = 0
    for _, e in ipairs(tbl) do total = total + e[2] end
    local r = math.random() * total
    for _, e in ipairs(tbl) do
        r = r - e[2]
        if r <= 0 then return e[1] end
    end
    return nil
end
LC.RollSalvage = function(big) return Roll(big and SALVAGE_BIG or SALVAGE) end

local stripped = {} -- [key] = time there's something to take again
LC.SalvageStripped = stripped

-- What it is, to say so: "Prying the radiator apart".
local NAMES = { { "radiator", "the radiator" }, { "engine", "the engine" }, { "pipe", "the pipes" }, { "car", "the wreck" },
    { "truck", "the wreck" }, { "van", "the wreck" }, { "bus", "the wreck" }, { "crate", "the crate" }, { "pallet", "the pallet" },
    { "fridge", "the fridge" }, { "refrigerator", "the fridge" }, { "washer", "the washing machine" }, { "stove", "the stove" },
    { "oildrum", "the drum" }, { "barrel", "the drum" }, { "fence", "the fencing" }, { "debris", "the debris" }, { "rubble", "the rubble" } }
local function NameOf(model)
    model = string.lower(model or "")
    for _, n in ipairs(NAMES) do if string.find(model, n[1], 1, true) then return n[2] end end
    return "it"
end
LC.JunkName = NameOf

-- Aiming at a map prop whose origin is at pos (the floor): across the floor, and below head height above it.
local function Aimed(pos, hit, r)
    local dx, dy = hit.x - pos.x, hit.y - pos.y
    return dx * dx + dy * dy < r * r and hit.z > pos.z - 16 and hit.z < pos.z + 140
end

-- The junk you're looking at: key, position, big?, what it is (or nil). Only
-- the thing your aim is on, never something a few feet away from it.
function LC.JunkAt(ply)
    local tr = ply:GetEyeTrace()
    if not tr or not tr.HitPos or tr.HitPos:DistToSqr(ply:EyePos()) > REACH * REACH then return nil end
    local e = tr.Entity
    if IsValid(e) and not (e.IsWorld and e:IsWorld()) then
        if not e:IsPlayer() and not e:IsNPC() and not e.lcQuest and not e.lcDressing and not e.lcFixture
            and not string.StartWith(e:GetClass(), "lc_") and LC.IsJunkModel then
            local junk, big = LC.IsJunkModel(e:GetModel())
            if junk then return "e" .. e:EntIndex(), e:GetPos(), big, NameOf(e:GetModel()) end
        end
        return nil
    end
    local hit = tr.HitPos
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "salvage" and Aimed(p.pos, hit, 60) then
            return string.format("p%d:%d:%d", math.floor(p.pos.x), math.floor(p.pos.y), math.floor(p.pos.z)), p.pos, true, "the junk pile"
        end
    end
    local best, bd, bbig
    for _, j in ipairs(LC.StaticJunk or {}) do
        local _, big = LC.IsJunkModel(j.model)
        if Aimed(j.pos, hit, big and 110 or 45) then
            local dx, dy = hit.x - j.pos.x, hit.y - j.pos.y
            local d = dx * dx + dy * dy
            if not bd or d < bd then best, bd, bbig = j, d, big end
        end
    end
    if best then
        local p = best.pos
        return string.format("s%d:%d:%d", math.floor(p.x), math.floor(p.y), math.floor(p.z)), p, bbig, NameOf(best.model)
    end
    return nil
end

local function HoldingCrowbar(ply)
    local w = ply:GetActiveWeapon()
    return IsValid(w) and w:GetClass() == "weapon_crowbar"
end
LC.HoldingCrowbar = HoldingCrowbar

-- The noise: units near enough hear it, and a unit on the street comes to look.
LC.SalvageHeard = LC.SalvageHeard or 0
function LC.SalvageNoise(ply, pos)
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and LC.PlayerIsCP(p) and p:GetPos():DistToSqr(pos) < 1200 * 1200 then
            p:ChatPrint("[CP] Metal being pried apart" .. (where ~= "" and (", " .. where) or " nearby") .. ". Unauthorised salvage?")
        end
    end
    local now = CurTime()
    if now < LC.SalvageHeard then return nil end
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and not st.questLock and not st.raid and not st.skirmish
            and st.state ~= "hostile" and st.state ~= "escort" and st.state ~= "event" and not st.workEscort then
            local d = npc:GetPos():DistToSqr(pos)
            if d < 1400 * 1400 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    if best and LC.GoTo then
        LC.SalvageHeard = now + 20
        local st = LC.NPCs[best]
        if LC.AbandonTask then LC.AbandonTask(best, st, now) end
        if LC.GoTo(best, st, pos, false, nil) then
            best:EmitSound("npc/metropolice/vo/investigating10-103.wav", 75)
            return best
        end
    end
    return nil
end

function LC.Salvage(ply)
    if not cvOn:GetBool() then return false end
    if LC.PlayerIsCP(ply) then return false, "Units don't pick through junk." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local key, pos, big, name = LC.JunkAt(ply)
    if not key then return false, "Look at some junk: a wreck, a radiator, pipes, a crate." end
    if not HoldingCrowbar(ply) then return false, "You'll need a crowbar out to get anything off that." end
    if LC.RebelGuard(ply, pos) then return false end
    local now = CurTime()
    if (stripped[key] or 0) > now then
        return false, "Stripped already. Nothing left worth taking, for now."
    end
    ply:EmitSound("physics/metal/metal_box_strain" .. math.random(1, 4) .. ".wav", 80)
    LC.SalvageNoise(ply, pos)
    return LC.StartTask(ply, big and 9 or 6, "Prying " .. (name or "it") .. " apart... keep at it", {
        maxMove = 48, cancelText = "You leave it.",
        done = function(p)
            if (stripped[key] or 0) > CurTime() then return end
            stripped[key] = CurTime() + cvRefill:GetFloat()
            local got = {}
            for _ = 1, big and 3 or 2 do
                local id = Roll(big and SALVAGE_BIG or SALVAGE)
                if id then
                    if LC.GiveOrDrop then LC.GiveOrDrop(p, id, 1) else LC.GiveItem(p, id) end
                    got[#got + 1] = LCS.Items[id] and string.lower(LCS.Items[id].name) or id
                end
            end
            p:EmitSound("physics/metal/metal_sheet_impact_hard" .. math.random(6, 8) .. ".wav", 80)
            LC.SalvageNoise(p, pos)
            p:ChatPrint(#got > 0 and ("Salvaged: " .. table.concat(got, ", ") .. ".") or "Nothing worth keeping in it.")
            hook.Run("LivingCitySalvaged", p, got)
        end,
    })
end

-- E on junk with a crowbar out (and the crowbar doesn't pick it up instead)
hook.Add("KeyPress", "LivingCitySalvage", function(ply, key)
    if key ~= IN_USE or not cvOn:GetBool() or not ply:Alive() or not HoldingCrowbar(ply) then return end
    if LC.Busy and LC.Busy(ply) then return end
    if (ply.lcSalvageNext or 0) > CurTime() then return end
    if not LC.JunkAt(ply) then return end
    ply.lcSalvageNext = CurTime() + 0.6
    local ok, why = LC.Salvage(ply)
    if not ok and why then ply:ChatPrint(why) end
end)

hook.Add("AllowPlayerPickup", "LivingCitySalvage", function(ply, ent)
    if cvOn:GetBool() and HoldingCrowbar(ply) and IsValid(ent) and LC.IsJunkModel and LC.IsJunkModel(ent:GetModel()) then return false end
end)

-- Breaking a crate open, with anything, sometimes spills something.
hook.Add("PropBreak", "LivingCitySalvage", function(attacker, prop)
    if not cvOn:GetBool() or not IsValid(attacker) or not attacker:IsPlayer() or not IsValid(prop) then return end
    if prop.lcQuest or prop.lcDressing then return end
    if prop.lcRebelProp or (LC.IsJunkModel and LC.IsJunkModel(prop:GetModel())) then LC.RebelGuard(attacker, prop:GetPos()) end
    if not (LC.IsJunkModel and LC.IsJunkModel(prop:GetModel())) then return end
    if math.random() > 0.35 then return end
    local id = Roll(SALVAGE)
    if id and LC.SpawnWorldItem then LC.SpawnWorldItem(id, prop:GetPos() + Vector(0, 0, 12)) end
end)

------------------------------------------------------------------------
-- Rebels guard their own things
------------------------------------------------------------------------

-- A rebel who sees an outsider wrecking what's theirs (salvaging or smashing
-- crates in rebel territory) warns them twice, then shoves, then hits harder,
-- and only after that turns on them. Returns true if a rebel saw it.
local cvGuard = CreateConVar("lc_rebel_guard", "1", FLAGS, "Rebels warn, shove, then turn on outsiders who wreck their supplies (0: they don't care)")
local GUARD_LINES = { "vo/npc/male01/gethellout.wav", "vo/npc/male01/watchout.wav" }

local function RebelWatching(ply, dist)
    local eye = ply:EyePos()
    local best, bst, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and st.state ~= "hostile" and npc:Health() > 0 then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < dist * dist and (not bd or d < bd) then
                local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
                if tr.Fraction > 0.97 then best, bst, bd = npc, st, d end
            end
        end
    end
    return best, bst
end

function LC.RebelGuard(ply, pos)
    if not cvGuard:GetBool() or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LC.PlayerIsCP(ply) or ply:GetNW2String("lcf_faction", "") == "resistance" then return false end
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return false end
    if not (LC.InRebelZone and (LC.InRebelZone(pos or ply:GetPos()) or LC.InRebelZone(ply:GetPos()))) then return false end
    local npc, st = RebelWatching(ply, 700)
    if not npc then return false end
    local now = CurTime()
    local b = ply.lcRebelWarn
    if not b or now - b.last > 90 then
        b = { n = 0, last = 0 }
        ply.lcRebelWarn = b
    end
    if now - b.last < 2.5 then return true end
    b.n = b.n + 1
    b.last = now
    local away = ply:GetPos() - npc:GetPos()
    away.z = 0
    away = away:GetNormalized()
    if npc.SetAngles then npc:SetAngles(Angle(0, (-away):Angle().y, 0)) end
    if b.n <= 2 then
        npc:EmitSound(GUARD_LINES[b.n], 75)
        ply:ChatPrint(b.n == 1 and "[Rebel] Hey! Those are our supplies. Quit it."
            or "[Rebel] I won't say it again. Put it down and walk away.")
    elseif b.n <= 4 then
        ply:SetVelocity(away * (b.n == 3 and 320 or 480) + Vector(0, 0, 110))
        ply:ViewPunch(Angle(-10, math.Rand(-6, 6), 0))
        npc:EmitSound("physics/body/body_medium_impact_soft3.wav", 70)
        if b.n == 4 then ply:TakeDamage(5, npc, npc) end
        ply:ChatPrint(b.n == 3 and "[Rebel] A hard shove back out of it. Go."
            or "[Rebel] A fist in the ribs. Last chance.")
    else
        ply.lcRebelWarn = nil
        npc:EmitSound("vo/npc/male01/gethellout.wav", 80)
        ply:ChatPrint("[Rebel] That's it.")
        if LC.MakeOneHostile then LC.MakeOneHostile(npc, st, ply) end
    end
    hook.Run("LivingCityRebelGuard", ply, npc, b.n)
    return true
end

-- Hitting a rebel's crate or garden pot counts the same.
hook.Add("EntityTakeDamage", "LivingCityRebelGuard", function(ent, dmg)
    if not IsValid(ent) or not ent.lcRebelProp then return end
    local a = dmg:GetAttacker()
    if IsValid(a) and a:IsPlayer() then LC.RebelGuard(a, ent:GetPos()) end
end)

------------------------------------------------------------------------
-- The crowbar is a weapon
------------------------------------------------------------------------

timer.Create("LivingCityCrowbar", 2, 0, function()
    local secs = cvCrowbar:GetFloat()
    if secs <= 0 then return end
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and HoldingCrowbar(ply) and not LC.PlayerIsCP(ply) and (ply.lcCrowbarNext or 0) < now
            and not (LC.PlayerIsZombie and LC.PlayerIsZombie(ply))
            and not (LC.InRebelZone and LC.InRebelZone(ply:GetPos()))
            and not (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
            and LC.SeenBySecurity and LC.SeenBySecurity(ply, 700) then
            ply.lcCrowbarNext = now + 60
            if not (LC.PlayerIsWanted and LC.PlayerIsWanted(ply)) then
                LC.ReportCrime(ply, "Carrying a weapon (a crowbar)", secs)
                ply:ChatPrint("[Civil Protection] A unit saw the crowbar in your hand. That's a weapon.")
                hook.Run("LivingCityCrowbarSeen", ply)
            end
        end
    end
end)

------------------------------------------------------------------------
-- Bin points: anywhere the editor says is a bin, is one
------------------------------------------------------------------------

function LC.BinPointAt(pos, r)
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == "bin" and p.pos:DistToSqr(pos) < (r or 90) ^ 2 then return p end
    end
    return nil
end

------------------------------------------------------------------------
-- Workbenches
------------------------------------------------------------------------

function LC.NearWorkbench(ply, dist)
    dist = dist or 150
    local pos = ply:GetPos()
    for _, e in ipairs(LC.EntsOf("lc_workbench")) do
        if IsValid(e) and e:GetPos():DistToSqr(pos) < dist * dist then return e end
    end
    for _, s in ipairs(LC.StaticSurfaces or {}) do
        if s.model and string.find(s.model, "workbench", 1, true) and s.pos:DistToSqr(pos) < dist * dist then return s end
    end
    return nil
end

------------------------------------------------------------------------
-- Reclamation
------------------------------------------------------------------------

local RECLAIM = { scrap = 2, can_empty = 1, bottle_empty = 1, can_dirty = 1, bottle_dirty = 1 }
LC.ReclaimPrices = RECLAIM
LC.Reclaimed = LC.Reclaimed or {} -- [ply] = { { t, n } }

function LC.Reclaim(ply, ent)
    if LC.PlayerIsCP(ply) then return false, "Units don't hand in scrap." end
    local now = CurTime()
    local list, earned = {}, 0
    for _, e in ipairs(LC.Reclaimed[ply] or {}) do
        if now - e.t < 3600 then list[#list + 1] = e earned = earned + e.n end
    end
    LC.Reclaimed[ply] = list
    local room = cvReclaim:GetInt() - earned
    if room <= 0 then return false, "[Reclamation] Quota met for now. Come back later." end
    local pay, items, ids = 0, 0, {}
    for id in pairs(RECLAIM) do ids[#ids + 1] = id end
    table.sort(ids)
    local taken = {}
    for _, id in ipairs(ids) do
        local price = RECLAIM[id]
        while LC.HasItem(ply, id) and pay + price <= room do
            LC.TakeItem(ply, id)
            pay, items = pay + price, items + 1
            taken[id] = (taken[id] or 0) + 1
        end
    end
    if items == 0 then return false, "[Reclamation] Scrap metal, empty cans and bottles only." end
    table.insert(list, { t = now, n = pay })
    LC.AddCredits(ply, pay, "reclamation")
    local standing = math.floor(items / 4)
    if standing > 0 and LC.AddStanding then LC.AddStanding(ply, standing, "materials returned to the Union") end
    if IsValid(ent) then ent:EmitSound("ambient/machines/combine_terminal_idle" .. math.random(1, 4) .. ".wav", 65) end
    if ply:GetNW2String("lcf_faction", "") == "resistance" then
        ply:ChatPrint("[Reclamation] The Union thanks you. (The cell could have made something of that.)")
    else
        ply:ChatPrint("[Reclamation] The Union thanks you for your contribution.")
    end
    hook.Run("LivingCityReclaimed", ply, items, pay, taken)
    return true, pay
end

hook.Add("PlayerSay", "LivingCitySalvageChat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!salvage" then
        local ok, why = LC.Salvage(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    end
end)
concommand.Add("lc_salvage_now", function(ply)
    if not IsValid(ply) then return end
    local ok, why = LC.Salvage(ply)
    if not ok and why then ply:ChatPrint(why) end
end)

------------------------------------------------------------------------
-- A downed city scanner is scrap: it comes apart in the street (and gives the
-- Resistance a reason to bring them down). Not one flown from a console: those
-- are put up on demand, so shooting them down would be free scrap on tap.
------------------------------------------------------------------------

local SCANNER_PARTS = { { "scrap", 70 }, { "chemicals", 15 }, { "gun_parts", 10 }, { nil, 5 } }
function LC.ScannerScrap(pos)
    local dropped = {}
    if not cvOn:GetBool() or not LC.SpawnWorldItem then return dropped end
    local n = math.random(2, 3)
    for i = 1, n do
        local id = i == 1 and "scrap" or Roll(SCANNER_PARTS) -- always some scrap
        if id then
            local e = LC.SpawnWorldItem(id, pos + Vector(math.random(-20, 20), math.random(-20, 20), 10), nil,
                Vector(math.random(-60, 60), math.random(-60, 60), 80))
            dropped[#dropped + 1] = id
            if IsValid(e) then e.lcScannerScrap = true end
        end
    end
    return dropped
end

hook.Add("OnNPCKilled", "LivingCityScannerScrap", function(npc)
    if not IsValid(npc) then return end
    local cls = npc:GetClass()
    if cls == "npc_cscanner" or cls == "npc_clawscanner" or (LC.NPCs and LC.NPCs[npc] and LC.NPCs[npc].role == "scanner") then
        LC.ScannerScrap(npc:GetPos())
    end
end)
