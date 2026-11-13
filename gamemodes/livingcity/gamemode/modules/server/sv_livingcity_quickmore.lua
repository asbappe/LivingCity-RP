--[[
    Living City: more on F2 (the owner, later on 7 November)

    What F2 (cl_livingcity_quick.lua) shows for each side, beyond what was there:
      the Insider       Inside >: the same as C > Civil Protection > Inside, each greyed with why
                        it isn't open right now (someone can see you, not yet, only at the Commissary)
      the Resistance    Freq 7 >: a message on the band, call for backup (every Resistance player
                        hears it and sees where you are; a couple of idle fighters nearby come and
                        stay with you), send my position, guide me to rebel ground or the lab
      a citizen         Me >: find work, my rations, my home and rent, my standing
      a prisoner        My sentence: what you're in for and how long is left
      the Administrator open my tablet, the laws, tonight's dream, command the guards (follow,
                        hold here, how close, what they do when there's trouble), order the arrest of whoever you're looking at
      senior units      Call a sweep >: a contraband sweep or a block raid, Division Leader and up,
                        when the city's pacing allows it

    What the menu greys out comes from here: LC.QuickInfo, sent with F2 (init.lua) and every two
    seconds while it's open (lc_quick_info). Every action is checked again here when it arrives
    (lc_quickmore). No chat or console commands of its own, no settings.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_quick_info")
util.AddNetworkString("lc_quickmore")

local REB_BACKUP_GAP = 120  -- seconds between one Resistance player's calls for backup
local REB_POS_GAP    = 20   -- ... and their position on Freq 7
local REB_FIGHTERS   = 2    -- idle fighters nearby who come when you call
local REB_RANGE      = 4000 -- how far away they can be
local MARK_SECS      = 90   -- a marker stays this long
local GUIDE_SECS     = 600  -- a guidance trail, at most this long
local ARREST_GAP     = 300  -- the Administrator's order of arrest: once every five minutes
local ARREST_SECS    = 600  -- wanted for ten minutes
local SWEEP_GAP      = 900  -- an officer's sweep or raid: one every fifteen minutes, city-wide
local SWEEP_RANK     = 3    -- Division Leader and up

LC.QuickMoreConfig = { REB_BACKUP_GAP = REB_BACKUP_GAP, REB_POS_GAP = REB_POS_GAP, REB_FIGHTERS = REB_FIGHTERS, ARREST_GAP = ARREST_GAP,
    ARREST_SECS = ARREST_SECS, SWEEP_GAP = SWEEP_GAP, SWEEP_RANK = SWEEP_RANK }

local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function Name(p) return LC.CharacterName and LC.CharacterName(p) or p:Nick() end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end
local function Wait(at) return math.max(0, math.ceil((at or 0) - CurTime())) end
local function Mins(secs) return math.max(1, math.ceil(secs / 60)) end
local function Tell(ply, kind, title, text, secs) if LC.Notice then LC.Notice(ply, kind, title, text, secs or 8) end end
-- Mark a kind of place (sv_livingcity_notices.lua's list) without its own notice: true, or false and why.
local function Mark(ply, kind)
    local find = LC.WaypointPlaces and LC.WaypointPlaces[kind]
    if not find then return false end
    local pos, label = find(ply)
    if not pos then return false, label end
    if LC.SetWaypoint then LC.SetWaypoint(ply, pos, label, kind == "home" and 260 or 170) end
    if kind == "home" and ply.lcWaypoint and LC.PlayerBlock then ply.lcWaypoint.block = LC.PlayerBlock(ply) end
    return true
end
LC.QuickMark = Mark
local function ZoneCenter(z) return z.box and ((z.box.mins + z.box.maxs) * 0.5) or z.pos end

------------------------------------------------------------------------
-- Guidance: a marker and a trail to a place (the quest trail's own, sv_livingcity_guidance.lua)
------------------------------------------------------------------------

function LC.GuideTo(ply, pos, label)
    if not IsValid(ply) or not pos then return false end
    ply.lcGuide = { pos = pos, untilT = CurTime() + GUIDE_SECS, label = label }
    if LC.SetWaypoint then LC.SetWaypoint(ply, pos, label, 200) end
    return true
end

-- The nearest rebel ground, and the nearest lab, from where they stand.
function LC.NearestRebelGround(pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKindShared and LC.ZonesOfKindShared("rebel") or {}) do
        local c = ZoneCenter(z)
        if c then
            local d = c:DistToSqr(pos)
            if not bd or d < bd then best, bd = c, d end
        end
    end
    return best
end

local function GuideResistance(ply, what)
    if Faction(ply) ~= "resistance" then return false, "Only the Resistance knows the way." end
    if what == "rebel" then
        local p = LC.NearestRebelGround(ply:GetPos())
        if not p then return false, "There's no rebel ground in this city yet." end
        LC.GuideTo(ply, p, "Rebel ground")
        Tell(ply, "info", "Freq 7", "The way to our ground is marked, with a trail on the ground to follow.")
        return true
    elseif what == "lab" then
        local find = LC.WaypointPlaces and LC.WaypointPlaces.lab
        local p, label = nil, "No cell has a lab yet."
        if find then p, label = find(ply) end
        if not p then return false, label end
        LC.GuideTo(ply, p, label)
        Tell(ply, "info", "Freq 7", "The way to the lab is marked, with a trail on the ground to follow.")
        return true
    end
    return false
end

------------------------------------------------------------------------
-- The Resistance: Freq 7
------------------------------------------------------------------------

-- Everyone on our side, and anyone else listening to Freq 7.
local function Freq7(text, except)
    for _, p in ipairs(player.GetAll()) do
        if p ~= except and (Faction(p) == "resistance" or (LC.HearsBand and LC.HearsBand(p, "resistance"))) then p:ChatPrint("[Freq 7] " .. text) end
    end
end

-- A marker for every Resistance player (the 10-20 marker, in our colour: cl_livingcity_war.lua).
local function RebelMark(ply, label)
    local list = {}
    for _, p in ipairs(player.GetAll()) do if p ~= ply and Faction(p) == "resistance" then list[#list + 1] = p end end
    local pos = ply:GetPos()
    if #list > 0 and LC.SendCompressed then
        LC.SendCompressed("lc_cpmark", { name = "rebel:" .. ply:EntIndex(), label = label, rebel = true, x = pos.x, y = pos.y, z = pos.z, secs = MARK_SECS }, list)
    end
    return #list
end

-- Idle fighters nearby: not following anyone, not on a raid, a post, an errand or a fight.
function LC.RebelBackupCandidates(ply)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "rebel" and npc:Health() > 0 and not st.follow and not st.raid and not st.skirmish
            and not st.quartermaster and not st.post and not st.errand and not st.foe and not st.questLock then
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d < REB_RANGE * REB_RANGE then out[#out + 1] = { npc = npc, st = st, d = d } end
        end
    end
    table.sort(out, function(a, b) return a.d < b.d end)
    return out
end

-- Why no fighters can come (nil: they can).
local function FightersWhyNot(ply)
    if ply:GetNW2Int("lcf_rank", 1) < 2 then return "Members and up can lead fighters." end
    if LC.ManpowerOn and LC.ManpowerOn() and LC.ManpowerPool then
        local hold = GetConVar("lc_manpower_hold")
        local need = hold and hold:GetInt() or 3
        local p = LC.ManpowerPool("rebel")
        if p.reserve < need then return string.format("we can't spare fighters: only %d left in reserve", p.reserve) end
    end
    if LC.SquadRoom and LC.SquadRoom(ply) <= 0 then return string.lower(string.sub(LC.SquadFullText(ply), 1, 1)) .. string.sub(LC.SquadFullText(ply), 2, -2) end
    return nil
end

function LC.RebelCallBackup(ply)
    if not IsValid(ply) or Faction(ply) ~= "resistance" then return false, "Only the Resistance calls on Freq 7 for backup." end
    if not ply:Alive() or (LC.Prisoners and LC.Prisoners[ply]) then return false, "Not now." end
    -- (the owner, 9 November: calling for backup takes a Freq 7 radio)
    if LC.RadioBand and LC.RadioBand(ply) ~= "resistance" then return false, "You need a Freq 7 radio to call for backup." end
    -- (the owner, 13 November: "no one should be able to broadcast on freq7 without a transmitter")
    if not LC.SendsOnFreq7(ply) then return false, "You need a radio transmitter too: a Freq 7 radio only listens." end
    local wait = Wait(ply.lcRebBackupNext)
    if wait > 0 then return false, string.format("Your last call is still out. Again in %d seconds.", wait) end
    ply.lcRebBackupNext = CurTime() + REB_BACKUP_GAP
    local where = Where(ply:GetPos())
    Freq7(Name(ply) .. " needs backup " .. where .. ". Their position is marked.", ply)
    RebelMark(ply, "Backup: " .. Name(ply))
    -- idle fighters nearby come and stay with them (as if they'd asked each one: sv_livingcity_rebels.lua), as many as
    -- their squad has room for (sv_livingcity_squads.lua); not enough nearby, and more come out of rebel territory
    local sent, fromHome, whyNot = 0, 0, FightersWhyNot(ply)
    if not whyNot and LC.RebelRecruit then
        local room = LC.SquadRoom and LC.SquadRoom(ply) or (REB_FIGHTERS - (LC.FollowersOf and #LC.FollowersOf(ply) or 0))
        for _, c in ipairs(LC.RebelBackupCandidates(ply)) do
            if sent >= room then break end
            LC.RebelRecruit(ply, c.npc, c.st)
            if c.st.follow == ply then sent = sent + 1 end
        end
        if sent < room and LC.RebelTerritoryBackup then
            for _, c in ipairs(LC.RebelTerritoryBackup(ply, room - sent)) do
                LC.RebelRecruit(ply, c.npc, c.st)
                if c.st.follow == ply then sent, fromHome = sent + 1, fromHome + 1 end
            end
        end
    end
    local text = "Every Resistance player has heard, and sees where you are for a minute and a half."
    if sent > 0 then
        text = text .. string.format(" %d fighter%s %s on the way, and stay%s with you (E on one sends them home).", sent, sent == 1 and "" or "s", sent == 1 and "is" or "are", sent == 1 and "s" or "")
        if fromHome > 0 then text = text .. string.format(" %d of them come%s out of rebel territory: give them a minute to reach you.", fromHome, fromHome == 1 and "s" or "") end
        if LC.SquadLimit then text = text .. string.format(" Your squad: %d of %d.", LC.FollowersOf and #LC.FollowersOf(ply) or sent, (LC.SquadLimit(ply))) end
    elseif whyNot then
        text = text .. " No fighters are coming: " .. whyNot .. "."
    else
        text = text .. " No fighters are free, nearby or in rebel territory."
    end
    Tell(ply, "info", "Backup called", text, 9)
    hook.Run("LivingCityRebelBackup", ply, sent)
    return true, sent
end

-- Sends on Freq 7: a Freq 7 radio and a radio transmitter (a Fighter and up are issued both: sv_livingcity_crafting.lua).
function LC.SendsOnFreq7(ply)
    if not LC.TransmitBands then return true end
    for _, b in ipairs(LC.TransmitBands(ply)) do if b == "resistance" then return true end end
    return false
end

function LC.RebelSendPosition(ply)
    if not IsValid(ply) or Faction(ply) ~= "resistance" then return false, "Only the Resistance." end
    if not ply:Alive() or (LC.Prisoners and LC.Prisoners[ply]) then return false, "Not now." end
    if not LC.SendsOnFreq7(ply) then return false, "You need a Freq 7 radio and a radio transmitter to send your position." end
    local wait = Wait(ply.lcRebPosNext)
    if wait > 0 then return false, string.format("Again in %d seconds.", wait) end
    ply.lcRebPosNext = CurTime() + REB_POS_GAP
    Freq7(Name(ply) .. " is " .. Where(ply:GetPos()) .. ".", ply)
    local n = RebelMark(ply, Name(ply))
    Tell(ply, "info", "Freq 7", n > 0 and string.format("Your position is marked for the Resistance (%d) for a minute and a half.", n) or "Your position is out on Freq 7. No one else from the Resistance is on right now.")
    return true
end

------------------------------------------------------------------------
-- A citizen: Me >
------------------------------------------------------------------------

local function IsCitizen(ply) local f = Faction(ply) return f == "citizen" or f == "" end

-- The next Civil Standing milestone above theirs: standing, what it brings.
local function NextMilestone(standing)
    local free = GetConVar("lc_free_rent_standing")
    local list = { { 50, "a CWU business license at the Commissary" }, { 150, "Union foreman (F2)" } }
    if free and free:GetInt() > 0 then list[#list + 1] = { free:GetInt(), "rent-free housing" } end
    table.sort(list, function(a, b) return a[1] < b[1] end)
    for _, m in ipairs(list) do if standing < m[1] then return m[1], m[2] end end
    return nil
end

local function MeInfo(ply)
    local t = {}
    -- work
    if LC.IntakePending and LC.IntakePending(ply) then t.work = "intake"
    elseif LC.Job and LC.Job(ply) then t.work, t.job = "job", LC.Job(ply).name
    elseif LC.LaborDesk and LC.LaborDesk() then t.work = "labor"
    else t.work = "board" end
    -- rations
    t.ration = Wait(ply.lcnRationAt)
    t.cards = LC.RationCards and LC.RationCards(ply) or 0
    t.ready = LC.RationReady and LC.RationReady(ply) or false
    -- home
    local apt = LC.ApartmentSummary and LC.ApartmentSummary(ply)
    if apt then t.home, t.left = "apartment", apt.left
    elseif LC.PlayerBlock and LC.PlayerBlock(ply) then t.home, t.block = "block", LC.BlockName and LC.BlockName(LC.PlayerBlock(ply)) or "your block"
    else t.home = "none" end
    -- standing
    t.standing = LC.Standing and LC.Standing(ply) or 0
    t.wanted = (LC.PlayerIsWanted and LC.PlayerIsWanted(ply)) or false
    t.next, t.nextWhat = NextMilestone(t.standing)
    return t
end

function LC.QuickFindWork(ply)
    if not IsValid(ply) then return false end
    local m = MeInfo(ply)
    if m.work == "intake" then
        Mark(ply, "intake")
        Tell(ply, "info", "Find work", "Register at Civil Intake first: no work, rations or room until you're on the register. It's marked on your screen.")
    elseif m.work == "job" then
        local ok = Mark(ply, "work")
        Tell(ply, "info", "Find work", "You work as " .. m.job .. ". " .. (ok and "Your workplace is marked. " or "") .. "F4 has your next shift.")
    elseif m.work == "labor" then
        Mark(ply, "labor")
        Tell(ply, "info", "Find work", "Labor Assignment gives you a Union job: press E on its terminal. It's marked on your screen. The job board is on F4.")
    else
        Tell(ply, "info", "Find work", "Pick a Union job on the job board: F4 > Jobs.")
    end
    return true
end

function LC.QuickRations(ply)
    if not IsValid(ply) then return false end
    local m = MeInfo(ply)
    local when = m.ready and "Your ration is ready now." or (m.ration > 0 and string.format("Your next ration is in %d minute%s.", Mins(m.ration), Mins(m.ration) == 1 and "" or "s") or "Your ration isn't ready yet.")
    local cards = m.cards == 0 and " You have no ration card: each Union shift you finish earns one." or string.format(" You have %d ration card%s (the dispenser takes one).", m.cards, m.cards == 1 and "" or "s")
    local ok = Mark(ply, "dispenser")
    Tell(ply, "info", "My rations", when .. cards .. (ok and " The nearest dispenser is marked." or ""), 9)
    return true
end

function LC.QuickHome(ply)
    if not IsValid(ply) then return false end
    local apt = LC.ApartmentSummary and LC.ApartmentSummary(ply)
    if apt then
        if LC.SetWaypoint then LC.SetWaypoint(ply, apt.pos, "My apartment", 170) end
        local price, why = 0, nil
        if LC.RentPrice then price, why = LC.RentPrice(ply) end
        local rent = (price or 0) > 0 and string.format(" Rent is %d credits a period: right click the door with your hands out to pay ahead.", price) or (" " .. (why and (string.upper(string.sub(why, 1, 1)) .. string.sub(why, 2) .. ".") or "No rent to pay."))
        Tell(ply, "info", "My home", string.format("Your apartment, %s: %dh %02dm left.%s It's marked on your screen.", apt.where, math.floor(apt.left / 3600), math.floor(apt.left % 3600 / 60), rent), 10)
        return true
    end
    if LC.PlayerBlock and LC.PlayerBlock(ply) then
        Mark(ply, "home")
        Tell(ply, "info", "My home", "You live in " .. (LC.BlockName and LC.BlockName(LC.PlayerBlock(ply)) or "your block") .. ": no rent for a room the city gives you. It's marked on your screen. An apartment of your own: right click a door that's for rent, with your hands out.", 10)
        return true
    end
    if LC.IntakePending and LC.IntakePending(ply) then
        Mark(ply, "intake")
        Tell(ply, "info", "My home", "No room yet. Register at Civil Intake first, then ask Housing Allocation. Civil Intake is marked on your screen.", 10)
        return true
    end
    local ok = Mark(ply, "housing")
    Tell(ply, "info", "My home", "No room yet. " .. (ok and "Housing Allocation gives you one (with a work assignment): it's marked on your screen." or "Right click an apartment door that's for rent, with your hands out.") , 10)
    return true
end

function LC.QuickStanding(ply)
    if not IsValid(ply) then return false end
    local m = MeInfo(ply)
    local parts = { string.format("Civil Standing %d.", m.standing) }
    if m.wanted then
        parts[#parts + 1] = "You are WANTED" .. (ply:GetNW2String("lc_wanted_reason", "") ~= "" and (": " .. ply:GetNW2String("lc_wanted_reason", "")) or "") .. ". Give yourself up to a unit, or keep out of sight."
    else
        parts[#parts + 1] = "Not wanted."
    end
    parts[#parts + 1] = "No fines owed (a street fine is taken on the spot)."
    if m.next then parts[#parts + 1] = string.format("Next: %s at %d.", m.nextWhat, m.next) end
    Tell(ply, m.wanted and "warn" or "info", "My standing", table.concat(parts, " "), 10)
    return true
end

------------------------------------------------------------------------
-- A prisoner: My sentence
------------------------------------------------------------------------

function LC.QuickSentence(ply)
    local pr = IsValid(ply) and LC.Prisoners and LC.Prisoners[ply]
    if not pr then return false, "You're not serving a sentence." end
    local left = Wait(pr.untilT)
    Tell(ply, "info", "My sentence", string.format("You're in for: %s. %d:%02d left. Stay in your cell: leaving it is escaping.",
        (pr.reason and pr.reason ~= "") and pr.reason or "breaking the city's laws", math.floor(left / 60), left % 60), 9)
    return true
end

------------------------------------------------------------------------
-- The City Administrator
------------------------------------------------------------------------

local function IsAdministrator(p) return IsValid(p) and p:IsPlayer() and Faction(p) == "admin" end

-- Why the Administrator can't order this person's arrest (nil: they can).
function LC.AdminArrestWhyNot(admin, target)
    if not IsAdministrator(admin) then return "Only the City Administrator." end
    if not IsValid(target) or not target:IsPlayer() or target == admin then return "Look at the person you want arrested." end
    if LC.PlayerIsCP(target) then return "Not one of the city's own." end
    if target:IsAdmin() then return "Not a member of staff." end
    if LC.Prisoners and LC.Prisoners[target] then return "They're already in a cell." end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(target) then return "They're already wanted." end
    local wait = Wait(admin.lcArrestNext)
    if wait > 0 then return string.format("Not yet: in %d minute%s.", Mins(wait), Mins(wait) == 1 and "" or "s") end
    return nil
end

function LC.AdminOrderArrest(admin, target)
    local why = LC.AdminArrestWhyNot(admin, target)
    if why then return false, why end
    if target:GetPos():DistToSqr(admin:GetPos()) > 1500 * 1500 then return false, "They're too far away to point out." end
    if not (LC.ReportCrime and LC.ReportCrime(target, "By order of the Administrator", ARREST_SECS)) then return false, "Not now." end
    admin.lcArrestNext = CurTime() + ARREST_GAP
    if LC.AddBOLO and LC.RecordKey then
        admin.lcBoloNext = nil -- (the Administrator's order is its own call)
        pcall(LC.AddBOLO, admin, LC.RecordKey(target), "By order of the Administrator: arrest on sight", 15)
    end
    Tell(target, "warn", "Wanted", "The City Administrator has ordered your arrest. Every unit has your description.", 10)
    Tell(admin, "info", "Order of arrest", Name(target) .. " is wanted, by your order, and every unit has a BOLO.")
    hook.Run("LivingCityAdminArrest", admin, target)
    return true
end

-- The bodyguard (sv_livingcity_cityadmin.lua): "follow" (as always), or "hold" here; how close they
-- follow ("close", "medium" as always, "far"); and what they do when there's trouble ("always" as
-- they always have, "stay" with me, stand "between" us, "holdfire" unless fired on). The last two
-- kinds are her standing orders: she can give them with no guards about, for whoever comes next.
local GUARD_DIST_SAY = {
    close = "Close: right at your shoulder.",
    medium = "Medium: a few steps behind you, as they always have.",
    far = "Far: well back, giving you room.",
}
local GUARD_MODE_SAY = {
    always = "As they always have: whoever hurts you is theirs, and they fight as soldiers do.",
    stay = "Stay with me: they shoot from their place beside you and never chase.",
    between = "Stand between us: each one puts himself between you and a threat.",
    holdfire = "Hold fire unless fired on: they start nothing, and answer only whoever hurts you or one of them.",
}
LC.AdminGuardOrderSay = { dist = GUARD_DIST_SAY, mode = GUARD_MODE_SAY }
function LC.AdminGuardOrder(admin, order)
    if not IsAdministrator(admin) then return false, "Only the City Administrator." end
    order = tostring(order or "")
    if GUARD_DIST_SAY[order] and LC.AdminGuardPref then
        LC.AdminGuardPref(admin).dist = order
        Tell(admin, "info", "Your guards", GUARD_DIST_SAY[order])
        return true
    end
    if GUARD_MODE_SAY[order] and LC.AdminGuardPref then
        local pref = LC.AdminGuardPref(admin)
        if pref.mode == "holdfire" and order ~= "holdfire" and LC.AdminGuardUnholdFire then
            for npc, who in pairs(LC.AdminGuards or {}) do
                if who == admin and IsValid(npc) then LC.AdminGuardUnholdFire(npc, LC.NPCs[npc]) end
            end
        end
        pref.mode = order
        Tell(admin, "info", "Your guards", GUARD_MODE_SAY[order])
        return true
    end
    local mine = 0
    for npc, who in pairs(LC.AdminGuards or {}) do if who == admin and IsValid(npc) then mine = mine + 1 end end
    if mine == 0 then return false, "You have no guards with you right now." end
    if order == "hold" then
        admin.lcGuardHold = { pos = admin:GetPos(), fwd = admin:GetForward(), right = admin:GetRight() }
        Tell(admin, "info", "Your guards", "They hold here until you call them to you. Anyone who hurts you is still theirs.")
    elseif order == "follow" then
        admin.lcGuardHold = nil
        Tell(admin, "info", "Your guards", "They're with you again.")
    else
        return false
    end
    return true
end
hook.Add("PlayerDeath", "LivingCityQuickMoreGuards", function(ply) ply.lcGuardHold = nil end)

------------------------------------------------------------------------
-- Senior units: call a sweep or a raid (the city's own events, sv_livingcity_events.lua)
------------------------------------------------------------------------

local SWEEPS = { sweep = "a contraband sweep (civil status inspections)", raid = "a block raid (a housing block inspection)" }
local lastEventEnd = 0
hook.Add("LivingCityEventEnded", "LivingCityQuickMoreSweep", function() lastEventEnd = CurTime() end)
function LC.OfficerSweepReset() lastEventEnd, LC.OfficerSweepNext = 0, 0 end

local function IsSenior(ply)
    return IsValid(ply) and Faction(ply) == "cp" and LC.PlayerIsCP(ply) and ply:GetNW2Int("lcf_rank", 1) >= SWEEP_RANK
end

-- Why this unit can't call one now (nil: they can).
function LC.OfficerSweepWhyNot(ply, kind)
    if not SWEEPS[kind] then return "No such order." end
    if not IsSenior(ply) then return "Division Leaders and up only." end
    if LC.EndingBusy and LC.EndingBusy() then return "Not while the city dreams." end
    if LC.Event then return "Not while the city has something on." end
    if LC.PendingEvent then return "The city has something planned in a minute or two." end
    local wait = Wait(LC.OfficerSweepNext)
    if wait > 0 then return string.format("Dispatch allows another in %d minute%s.", Mins(wait), Mins(wait) == 1 and "" or "s") end
    -- the city's own pace: at least half the usual time between events since the last one ended
    local iv = GetConVar("lc_event_interval")
    local gap = (iv and iv:GetFloat() or 24) * 30
    if lastEventEnd > 0 then
        wait = Wait(lastEventEnd + gap)
        if wait > 0 then return string.format("Too soon after the last one: in %d minute%s.", Mins(wait), Mins(wait) == 1 and "" or "s") end
    end
    return nil
end

function LC.OfficerCallSweep(ply, kind)
    local why = LC.OfficerSweepWhyNot(ply, kind)
    if why then return false, why end
    if not (LC.StartEvent and LC.StartEvent(kind)) then return false, "That can't happen right now (or the map has nowhere for it)." end
    LC.OfficerSweepNext = CurTime() + SWEEP_GAP
    local who = ply:GetNW2String("lcf_title", "") ~= "" and ply:GetNW2String("lcf_title", "") or ply:Nick()
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and LC.PlayerIsCP(p) then p:ChatPrint("[CP net] " .. who .. " orders " .. SWEEPS[kind] .. ". All units.") end
    end
    Tell(ply, "info", "Ordered", "Dispatch confirms: " .. SWEEPS[kind] .. ", now.")
    return true
end

------------------------------------------------------------------------
-- What F2 greys out, and why (sent to the one player)
------------------------------------------------------------------------

function LC.QuickInfo(ply)
    local t = {}
    if not IsValid(ply) then return t end
    local f = Faction(ply)
    if LC.IsInsider and LC.IsInsider(ply) then
        local watched, why = false, nil
        if LC.InsiderWatched then watched, why = LC.InsiderWatched(ply) end
        local wanted = 0
        for _, p in ipairs(player.GetAll()) do if p ~= ply and LC.PlayerIsWanted and LC.PlayerIsWanted(p) then wanted = wanted + 1 end end
        local wait = {}
        for _, k in ipairs({ "tip", "skim", "copy", "foul", "spike" }) do wait[k] = LC.InsiderWait and LC.InsiderWait(ply, k) or 0 end
        t.ins = { watched = watched and (why or "Someone can see you.") or nil, wait = wait, wanted = wanted,
            commissary = (LC.NearCPSupply and LC.NearCPSupply(ply)) and true or false, weedkiller = (LC.HasItem and LC.HasItem(ply, "weedkiller")) and true or false }
    end
    if f == "resistance" then
        local tx = false
        if LC.TransmitBands then for _, b in ipairs(LC.TransmitBands(ply)) do if b == "resistance" then tx = true end end end
        t.reb = { backup = Wait(ply.lcRebBackupNext), pos = Wait(ply.lcRebPosNext), tx = tx, radio = (not LC.RadioBand) or LC.RadioBand(ply) == "resistance" }
    end
    if IsCitizen(ply) then t.me = MeInfo(ply) end
    if f == "admin" then
        local guards = 0
        for npc, who in pairs(LC.AdminGuards or {}) do if who == ply and IsValid(npc) then guards = guards + 1 end end
        local pref = LC.AdminGuardPref and LC.AdminGuardPref(ply) or {}
        t.adm = { arrest = Wait(ply.lcArrestNext), guards = guards, hold = ply.lcGuardHold ~= nil, dream = LC.DreamOffice and LC.DreamOffice() or nil,
            dist = pref.dist or "medium", mode = pref.mode or "always" }
    end
    if IsSenior(ply) then t.sweep = { sweep = LC.OfficerSweepWhyNot(ply, "sweep"), raid = LC.OfficerSweepWhyNot(ply, "raid") } end
    return t
end

function LC.QuickInfoSend(ply)
    if not IsValid(ply) then return end
    local ok, t = pcall(LC.QuickInfo, ply)
    if not ok then
        if LC.Error then LC.Error("quick info", t) end
        t = {}
    end
    net.Start("lc_quick_info")
    net.WriteString(util.TableToJSON(t) or "{}")
    net.Send(ply)
end

net.Receive("lc_quick_info", function(_, ply)
    if not IsValid(ply) or (ply.lcQuickInfoNext or 0) > CurTime() then return end
    ply.lcQuickInfoNext = CurTime() + 0.8
    LC.QuickInfoSend(ply)
end)

------------------------------------------------------------------------
-- From F2
------------------------------------------------------------------------

local ACTIONS = {
    guide = function(ply, arg) return GuideResistance(ply, arg) end,
    rbackup = function(ply) return LC.RebelCallBackup(ply) end,
    rpos = function(ply) return LC.RebelSendPosition(ply) end,
    work = function(ply) return LC.QuickFindWork(ply) end,
    rations = function(ply) return LC.QuickRations(ply) end,
    home = function(ply) return LC.QuickHome(ply) end,
    standing = function(ply) return LC.QuickStanding(ply) end,
    sentence = function(ply) return LC.QuickSentence(ply) end,
    office = function(ply)
        if not IsAdministrator(ply) then return false, "Only the City Administrator." end
        if LC.OpenAdminOffice then LC.OpenAdminOffice(ply) end
        return true
    end,
    arrest = function(ply, _, target) return LC.AdminOrderArrest(ply, target) end,
    guards = function(ply, arg) return LC.AdminGuardOrder(ply, arg) end,
    sweep = function(ply, arg) return LC.OfficerCallSweep(ply, arg) end,
}
LC.QuickMoreActions = ACTIONS

-- One F2 action: true, or false and why not (told to them).
function LC.QuickMore(ply, cmd, arg, target)
    local fn = ACTIONS[tostring(cmd or "")]
    if not fn or not IsValid(ply) then return false end
    local ok, a, b = pcall(fn, ply, arg, target)
    if not ok then
        if LC.Error then LC.Error("quick action " .. tostring(cmd), a) end
        return false
    end
    if not a and b then Tell(ply, "warn", "Not now", b, 6) end
    return a, b
end

net.Receive("lc_quickmore", function(_, ply)
    if not IsValid(ply) or (ply.lcQuickMoreNext or 0) > CurTime() then return end
    ply.lcQuickMoreNext = CurTime() + 0.3
    local cmd, arg, target = net.ReadString(), net.ReadString(), net.ReadEntity()
    LC.QuickMore(ply, cmd, string.sub(arg or "", 1, 40), target)
    LC.QuickInfoSend(ply)
end)
