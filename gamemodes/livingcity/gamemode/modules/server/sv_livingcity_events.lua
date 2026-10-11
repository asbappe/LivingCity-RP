--[[
    Living City: city events

      Announcements  Overwatch city voice over the PA every few minutes
      rations        citizens flock to the ration lines, which move faster
      sweep          Civil Protection stops citizens far more often
      curfew         citizens go home; players outside their housing block get
                     three warnings from any cop who sees them, then become wanted
      lockdown       curfew, but running, with extra units on the street
      Radio chatter  cops key their radios now and then
      The can        every so often a cop drops a can at your feet. You know the rest.

    Rations and curfew are announced two minutes ahead; a sweep, a raid or a
    supply convoy is a surprise (units are briefed, and the Resistance's
    informants whisper it on Freq 7). A lockdown is never scheduled: it
    answers violence (a high alert, or the city in unrest).

    Events run automatically (lc_auto_events) or from the editor panel / commands:
      lc_event <rations|sweep|curfew|lockdown> [minutes], lc_endevent, lc_announce
]]

if CLIENT then return end

util.AddNetworkString("lc_announce")

LC = LC or {}
LC.ExtraCops = LC.ExtraCops or 0

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAnnounce  = CreateConVar("lc_announce_interval", "0", FLAGS, "Minutes between random ambient announcements (0 = off: the PA only speaks when something happens)")
local cvAuto      = CreateConVar("lc_auto_events", "1", FLAGS, "Run city events automatically")
local cvInterval  = CreateConVar("lc_event_interval", "12", FLAGS, "Minutes between automatic events")
CreateConVar("lc_curfew_citizens", "0", FLAGS, "Citizens left on the streets during curfew")
local cvGrace     = CreateConVar("lc_curfew_grace", "60", FLAGS, "Seconds after a curfew or lockdown starts before anyone outside is warned (60 minimum)")
local cvEnforce   = CreateConVar("lc_curfew_enforce", "1", FLAGS, "Cops warn, then pursue, players out during curfew")
local cvChatter   = CreateConVar("lc_chatter", "1", FLAGS, "Civil Protection radio chatter")
local cvCan       = CreateConVar("lc_can_event", "1", FLAGS, "Pick up that can (0 off, 1 on, 2 refusing makes you wanted)")

local CV = "npc/overwatch/cityvoice/"
local VOICE = {
    ambient = {
        CV .. "f_innactionisconspiracy_spkr.wav", CV .. "f_anticitizenreport_spkr.wav",
        CV .. "f_trainstation_cooperation_spkr.wav", CV .. "f_trainstation_inform_spkr.wav",
        CV .. "f_rationunitsdeduct_3_spkr.wav", CV .. "f_citizenshiprevoked_6_spkr.wav",
        CV .. "f_evasionbehavior_2_spkr.wav", CV .. "f_capitalmalcompliance_spkr.wav",
    },
    rations  = { CV .. "f_trainstation_assemble_spkr.wav", CV .. "f_trainstation_assumepositions_spkr.wav" },
    sweep    = { CV .. "f_confirmcivilstatus_1_spkr.wav" },
    raid     = { CV .. "f_confirmcivilstatus_1_spkr.wav" },
    curfew   = { CV .. "f_unrestprocedure1_spkr.wav" },
    lockdown = { CV .. "f_unrestprocedure1_spkr.wav", CV .. "f_protectionresponse_1_spkr.wav" },
    supply   = { CV .. "f_protectionresponse_1_spkr.wav" },
    ended    = { CV .. "f_sociostabilizationrestored_spkr.wav" },
}

local TITLES = {
    rations = "Ration distribution", sweep = "Civil status inspections", curfew = "Curfew",
    lockdown = "Lockdown", raid = "Housing block inspection", ended = "Stabilization restored", ambient = "City announcement",
    response = "Overwatch response", supply = "Supply convoy",
}

local cvSupplyMin = CreateConVar("lc_supply_minutes", "6", FLAGS, "How long a supply drop stays before the convoy moves on")
local DEFAULT_MINUTES = { rations = 3, sweep = 2, curfew = 4, lockdown = 3, raid = 4 }
setmetatable(DEFAULT_MINUTES, { __index = function(_, k) if k == "supply" then return cvSupplyMin:GetFloat() end end })
-- (no lockdown: a lockdown answers violence, from the escalation or the city
-- falling into unrest: sv_livingcity_response.lua, sv_livingcity_war.lua)
local AUTO_WEIGHTS = { { "rations", 45 }, { "sweep", 30 }, { "curfew", 18 }, { "raid", 14 }, { "supply", 10 } }
LC.AutoEventWeights = AUTO_WEIGHTS

-- Announced ahead to everyone: the routine, published ones. A sweep, a raid or
-- a supply convoy is a surprise; only the units (and the Resistance's informants) know.
LC.PublicEvents = { rations = true, curfew = true }

local RADIO_LINES = {
    "npc/metropolice/vo/copy.wav", "npc/metropolice/vo/ten4.wav", "npc/metropolice/vo/rodgerthat.wav",
    "npc/metropolice/vo/affirmative.wav", "npc/metropolice/vo/affirmative2.wav",
}
local WARNINGS = {
    "npc/metropolice/vo/firstwarningmove.wav",
    "npc/metropolice/vo/secondwarning.wav",
    "npc/metropolice/vo/finalwarning.wav",
}

local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

------------------------------------------------------------------------
-- Announcements
------------------------------------------------------------------------

-- What each PA line says, roughly, in plain words: the voice lines come from
-- Half-Life 2 and aren't always clear, or are a loose fit for what's happening.
local SAYS = {
    f_innactionisconspiracy_spkr = "Failing to report suspicious behaviour counts as conspiracy. Report it to Civil Protection.",
    f_anticitizenreport_spkr = "Ground units: an anticitizen has been reported in this community. Contain them.",
    f_trainstation_cooperation_spkr = "Residents: a miscount has been detected. Cooperate with Civil Protection to keep your full rations.",
    f_trainstation_inform_spkr = "Residents: this block may harbour civil unrest. Inform, cooperate, assemble.",
    f_rationunitsdeduct_3_spkr = "Occupants: your block is charged with tolerating noncompliance. Ration units are being deducted.",
    f_citizenshiprevoked_6_spkr = "An individual has been convicted of anticivil violations. Their citizenship is revoked.",
    f_evasionbehavior_2_spkr = "Evasive behaviour detected. Ground protection teams: isolate the suspect.",
    f_capitalmalcompliance_spkr = "An individual is charged with capital malcompliance. Anticitizen status approved.",
    f_trainstation_assemble_spkr = "Citizen notice: assemble at your designated positions.",
    f_trainstation_assumepositions_spkr = "Residents: assume your positions.",
    f_confirmcivilstatus_1_spkr = "Persons of interest: confirm your civil status with your local protection team immediately.",
    f_unrestprocedure1_spkr = "Unrest procedure is now in effect.",
    f_protectionresponse_1_spkr = "All ground protection teams: response protocol is now in effect.",
    f_sociostabilizationrestored_spkr = "Socio-stabilization restored. Units, return to standard duty.",
}

local function Minutes()
    local left = (LC.EventEnds or CurTime()) - CurTime()
    local m = math.max(1, math.floor(left / 60 + 0.5))
    return m == 1 and "about a minute" or (m .. " minutes")
end

local function IsUnit(ply)
    return LC.PlayerIsCP(ply) or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply))
end

-- What actually happens, for the person reading it.
local MEANS = {
    ambient = function()
        if LC.CityState and LC.CityState() == "unrest" then
            return "The city is in unrest: more inspections and raids, and rations come slower. See !city."
        end
        return "Just the city talking. Nothing changes."
    end,
    rations = function(ply)
        if LC.PlayerIsCP(ply) then return "Rations are being handed out for " .. Minutes() .. ". The lines move faster and citizens crowd them; keep order." end
        return "Rations are being handed out for " .. Minutes() .. ". Lines move faster and you can collect again sooner. Stand at the front of a ration line to get yours (not if you're wanted)."
    end,
    sweep = function(ply)
        if LC.PlayerIsCP(ply) then return "Civil status inspections for " .. Minutes() .. ". Stop and search citizens: units stop people far more often now." end
        return "Civil status inspections for " .. Minutes() .. ". Units stop and search people far more often and from further away. Anything illegal on you will be found: stash it, or stay out of sight."
    end,
    raid = function(ply)
        local block = LC.Raid and LC.Raid.block
        local name = block and LC.BlockName(block) or "a housing block"
        if LC.PlayerIsCP(ply) then return "Units are searching " .. name .. ". Contraband found there is traced to its owner, who becomes wanted." end
        local mine = block and LC.PlayerBlock and LC.PlayerBlock(ply) == block
        return "Units are searching " .. name .. (mine and " (your block)" or "") .. " room by room. Anyone there gets frisked, contraband lying around is traced to whoever left it, and they become wanted. Stashes can be found too."
    end,
    curfew = function(ply)
        local grace = math.floor(math.max(0, (LC.EventGraceEnds or CurTime()) - CurTime()))
        if IsUnit(ply) then return "Curfew for " .. Minutes() .. ". After " .. grace .. " seconds, citizens still outside get three warnings from a unit, then they're wanted." end
        local home = LC.PlayerBlock and LC.PlayerBlock(ply)
        if not home and LC.AwaitingHousing and LC.AwaitingHousing(ply) then
            return "Curfew for " .. Minutes() .. ". You have no room yet: wait it out at Civil Intake, or where you arrived. Units leave new arrivals there alone."
        end
        return "Curfew for " .. Minutes() .. ". Get inside " .. (home and LC.BlockName(home) or "your housing block") ..
            " (your HUD points the way). You have " .. grace .. " seconds. After that, a unit who sees you outside warns you three times, then you're wanted. Running is allowed until then."
    end,
    lockdown = function(ply)
        local grace = math.floor(math.max(0, (LC.EventGraceEnds or CurTime()) - CurTime()))
        if IsUnit(ply) then return "Lockdown for " .. Minutes() .. ": a curfew with extra units out. After " .. grace .. " seconds, anyone outside gets three warnings, then they're wanted." end
        local home = LC.PlayerBlock and LC.PlayerBlock(ply)
        if not home and LC.AwaitingHousing and LC.AwaitingHousing(ply) then
            return "Lockdown for " .. Minutes() .. ". You have no room yet: wait it out at Civil Intake, or where you arrived. Units leave new arrivals there alone."
        end
        return "Lockdown for " .. Minutes() .. ": a curfew, with extra units on the street. Get inside " .. (home and LC.BlockName(home) or "your housing block") ..
            " within " .. grace .. " seconds. After that, units who see you outside warn you three times, then you're wanted."
    end,
    ended = function() return "The curfew is over. You can go out again." end,
    response = function() return "Overwatch has been sent in. Keep clear of any fighting." end,
    supply = function(ply)
        local where = LC.Supply and LC.DescribePlace and LC.DescribePlace(LC.Supply.pos) or "on the streets"
        if LC.PlayerIsCP(ply) then return "A supply convoy is unloading " .. where .. " for " .. Minutes() .. ". Guard the crate: if anything's left in it when the convoy moves on, every unit nearby is paid." end
        if ply:GetNW2String("lcf_faction", "") == "resistance" then return "A supply convoy is unloading " .. where .. " for " .. Minutes() .. ". Guns, ammunition, medicine, lightly guarded. Take what you can (E on the crate)." end
        return "A supply convoy is unloading " .. where .. " for " .. Minutes() .. ". Keep clear of it. Anyone caught taking from the crate is wanted."
    end,
}

local ENDED = {
    rations = "Ration distribution is over. Lines go back to their usual pace.",
    sweep = "Inspections are over. Units are back to stopping people at the usual rate.",
    raid = "The housing block inspection is over.",
}

-- detail: a line of its own that replaces the usual explanation (who, where).
-- the PA gets harder in its tone when the city's slipping
local HARSH = {
    CV .. "f_rationunitsdeduct_3_spkr.wav", CV .. "f_citizenshiprevoked_6_spkr.wav", CV .. "f_capitalmalcompliance_spkr.wav",
    CV .. "f_innactionisconspiracy_spkr.wav", CV .. "f_evasionbehavior_2_spkr.wav",
}

function LC.Announce(kind, path, detail)
    if not path and kind == "ambient" and LC.CityState and LC.CityState() == "unrest" then path = LC.Pick(HARSH) end
    local subtitle
    if not path and LC.PickAnnounceClip then path, subtitle = LC.PickAnnounceClip("overwatch", kind, true) end -- a custom recording (sv_livingcity_announcer.lua)
    path = path or LC.Pick(VOICE[kind] or VOICE.ambient)
    net.Start("lc_announce")
    net.WriteString(path)
    net.WriteString(TITLES[kind] or TITLES.ambient)
    net.Broadcast()
    -- and in chat, what it said and what it means
    local key = string.match(path, "([^/]+)%.wav$") or ""
    local says = subtitle or SAYS[key]
    local title = TITLES[kind] or TITLES.ambient
    for _, ply in ipairs(player.GetAll()) do
        if says then ply:ChatPrint("[" .. title .. "] \"" .. says .. "\"") end
        local ok, means = pcall(function() return detail or (MEANS[kind] and MEANS[kind](ply)) end)
        if ok and means then ply:ChatPrint("  > " .. means) end
        -- and on the screen, where it won't scroll away (sv_livingcity_notices.lua)
        local text = (ok and means) or (says and ("\"" .. says .. "\"")) or nil
        if text and LC.Notice and kind ~= "ambient" then LC.Notice(ply, "event", title, text) end
    end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local warnings = {} -- [ply] = { stage, next }
local nextAuto, nextAnnounce = 0, 0
local pendingAuto -- the next automatic event, picked early so radios can warn people
LC.EventSerial = LC.EventSerial or 0
local SOON = 120 -- radios warn, and the event's directives go up, two minutes ahead

local function Publish()
    SetGlobal2String("lc_event", LC.Event or "")
    SetGlobal2Float("lc_event_ends", LC.EventEnds or 0)
    SetGlobal2Float("lc_event_grace", LC.EventGraceEnds or 0)
end

-- Time to reach home before curfew is enforced. Never less than a minute.
function LC.CurfewGrace() return math.max(60, cvGrace:GetFloat()) end

function LC.EndEvent(silent)
    local was = LC.Event
    if not was then return end
    LC.Event, LC.EventEnds, LC.EventGraceEnds = nil, nil, nil
    LC.ExtraCops = 0
    warnings = {}
    Publish()
    if not silent and (was == "curfew" or was == "lockdown") then LC.Announce("ended") end
    if not silent and ENDED[was] then
        for _, ply in ipairs(player.GetAll()) do ply:ChatPrint("[City] " .. ENDED[was]) end
    end
    LC.Log("info", "Event ended: " .. was)
    hook.Run("LivingCityEventEnded", was)
end

function LC.StartEvent(name, minutes)
    if not DEFAULT_MINUTES[name] then return false end
    if LC.Event then LC.EndEvent(true) end
    minutes = tonumber(minutes) or DEFAULT_MINUTES[name]
    LC.Event = name
    LC.EventEnds = CurTime() + minutes * 60
    LC.EventSerial = (LC.EventSerial or 0) + 1
    LC.ExtraCops = name == "lockdown" and 3 or 0
    LC.EventGraceEnds = (name == "curfew" or name == "lockdown") and (CurTime() + LC.CurfewGrace()) or nil
    warnings = {}
    Publish()

    if name == "rations" then
        for _, line in pairs(LC.Lines or {}) do line.nextAdvance = CurTime() + 8 end
        -- pull idle citizens toward the lines right away
        for npc, st in pairs(LC.NPCs or {}) do
            if st.role == "citizen" and st.state == "idle" then st.untilT = 0 end
        end
    elseif name == "curfew" or name == "lockdown" then
        for npc, st in pairs(LC.NPCs or {}) do
            if st.role == "citizen" and not st.test and not st.questLock and (st.state == "idle" or st.state == "moving") and not st.leaving then
                st.untilT = 0
                if st.state == "moving" then LC.StartLeaving(npc, st, name == "lockdown") end
            end
        end
    end

    LC.Log("info", string.format("Event started: %s (%s min)", name, tostring(minutes)))
    hook.Run("LivingCityEventStarted", name, minutes)
    LC.Announce(name) -- after the event has set itself up, so the explanation can say which block
    return true
end

local function PickAuto()
    -- the state of the city tilts it (sv_livingcity_war.lua): unrest means more inspections and raids
    local weights, total = {}, 0
    for i, w in ipairs(AUTO_WEIGHTS) do
        weights[i] = w[2] * (LC.EventWeightMul and LC.EventWeightMul(w[1]) or 1)
            * (LC.AtmosEventMul and LC.AtmosEventMul(w[1]) or 1) -- night: curfew more likely (sv_livingcity_atmos.lua)
        total = total + weights[i]
    end
    local r = math.random() * total
    for i, w in ipairs(AUTO_WEIGHTS) do
        r = r - weights[i]
        if r <= 0 then return w[1] end
    end
    return "rations"
end

------------------------------------------------------------------------
-- Curfew enforcement
------------------------------------------------------------------------

local function SeenByCop(ply)
    local eye = ply:EyePos()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and LC.IsSecurity(st) and st.state ~= "hostile" and st.state ~= "event"
            and npc:GetPos():DistToSqr(ply:GetPos()) < 700 * 700 then
            if LC.LineOfSight(npc:EyePos(), eye, npc) then return npc, st end
        end
    end
    return nil
end

local function BlockName(n)
    local fmt = GetConVar("lc_block_name") and GetConVar("lc_block_name"):GetString() or "Habitation Block %02d"
    local ok, s = pcall(string.format, fmt, n)
    return ok and s or ("Block " .. n)
end
LC.BlockName = BlockName

-- Someone who spawns (or respawns as a new person) into a curfew gets time to walk home
-- from where they appeared: a minute at least, more for a long way (their block's
-- middle, at a walking pace with some to spare), before the warnings start.
local function PersonalGrace(ply)
    local secs = LC.CurfewGrace()
    local n = LC.PlayerBlock and LC.PlayerBlock(ply)
    if n and LC.ZonesOfKind then
        local best
        for _, z in ipairs(LC.ZonesOfKind("block")) do
            if (z.group or 0) == n then
                local d = z.pos:Distance(ply:GetPos())
                if not best or d < best then best = d end
            end
        end
        if best then secs = math.max(secs, math.min(240, best / 110 * 1.3)) end
    end
    return secs
end
LC.CurfewPersonalGrace = PersonalGrace

hook.Add("PlayerSpawn", "LivingCityCurfewGrace", function(ply)
    if LC.Event == "curfew" or LC.Event == "lockdown" then
        ply.lcCurfewGrace = CurTime() + LC.CurfewGrace() -- at once; worked out properly once they've landed
        warnings[ply] = nil
        timer.Simple(0.5, function() -- (after they've been put where they spawn)
            if IsValid(ply) then
                ply.lcCurfewGrace = CurTime() + PersonalGrace(ply)
                warnings[ply] = nil
            end
        end)
    end
end)

local function EnforceCurfew(now)
    if not cvEnforce:GetBool() then return end
    if now < (LC.EventGraceEnds or 0) then return end -- grace period: time to get home
    for _, ply in ipairs(player.GetAll()) do
        local exempt = not ply:Alive() or LC.PlayerIsCP(ply) or LC.PlayerIsZombie(ply)
            or (LC.InCustody and LC.InCustody(ply)) or LC.PlayerIsWanted(ply)
            or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
            or (LC.PlayerIsStalker and LC.PlayerIsStalker(ply))
            or (ply.lcPermitSerial ~= nil and ply.lcPermitSerial == LC.EventSerial)
        if not exempt and LC.PlayerInOwnBlock then
            exempt = LC.PlayerInOwnBlock(ply) == true
        end
        if not exempt and LC.IntakeShelter and LC.IntakeShelter(ply) then exempt = true end -- no room yet, waiting by Civil Intake
        if not exempt and now < (ply.lcCurfewGrace or 0) then exempt = true end -- just arrived: time to get home
        if exempt then
            warnings[ply] = nil
        else
            local w = warnings[ply] or { stage = 0, next = 0 }
            warnings[ply] = w
            if now > w.next then
                local cop, cst = SeenByCop(ply)
                if not cop then w.next = now + 1 end -- nobody in sight: look again in a second, not every half
                if cop and LC.CurfewExcuse and LC.CurfewExcuse(ply, cop) then
                    warnings[ply] = nil -- a permit, or papers that say night shift
                elseif cop then
                    w.stage = w.stage + 1
                    w.next = now + 15 -- (time to act on a warning before the next)
                    LC.Face(cop, ply:GetPos())
                    local home = LC.PlayerBlock and LC.PlayerBlock(ply)
                    local where = home and BlockName(home)
                        or (LC.AwaitingHousing and LC.AwaitingHousing(ply) and "Civil Intake (you have no room yet)") or "your residence"
                    hook.Run("LivingCityCurfewWarning", ply, w.stage)
                    if w.stage <= #WARNINGS then
                        cop:EmitSound(WARNINGS[w.stage], 80)
                        Say(ply, string.format("[Civil Protection] Curfew is in effect. Return to %s. (Warning %d of %d)",
                            where, w.stage, #WARNINGS))
                    else
                        cop:EmitSound("npc/metropolice/vo/holdit.wav", 80)
                        Say(ply, "[Civil Protection] Curfew violation. You are now wanted.")
                        LC.ReportCrime(ply, "Curfew violation", 240)
                        LC.MakeCopsHostile(ply, ply:GetPos(), 1500)
                        warnings[ply] = nil
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- Radio chatter
------------------------------------------------------------------------

local function Chatter(now)
    if not cvChatter:GetBool() then return end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "cop" and now > (st.nextChatter or 0)
            and (st.state == "idle" or st.state == "moving") then
            st.nextChatter = now + math.Rand(40, 90)
            if not LC.FarFromPlayers(npc:GetPos(), 1200) and math.random() < 0.5 then
                npc:EmitSound("npc/metropolice/vo/on1.wav", 70)
                local line = LC.Pick(RADIO_LINES)
                timer.Simple(0.35, function() if IsValid(npc) then npc:EmitSound(line, 72) end end)
                timer.Simple(2.4, function() if IsValid(npc) then npc:EmitSound("npc/metropolice/vo/off1.wav", 70) end end)
            end
        end
    end
end

------------------------------------------------------------------------
-- Pick up that can.
------------------------------------------------------------------------

local can           -- the active encounter, if any
local canCooldown = {} -- [ply] = time they can be picked on again
local nextCanCheck = 0

local function EndCan(success)
    if not can then return end
    local c = can
    can = nil
    if IsValid(c.cop) and c.cst then
        if success then c.cop:EmitSound("npc/metropolice/vo/affirmative.wav", 75) end
        LC.SetState(c.cop, c.cst, "idle")
        c.cst.untilT = CurTime() + 3
    end
    if IsValid(c.prop) then SafeRemoveEntityDelayed(c.prop, success and 5 or 30) end
end

local function StartCan(cop, cst, ply)
    local prop = ents.Create("prop_physics")
    if not IsValid(prop) then return end
    prop:SetModel("models/props_junk/popcan01a.mdl")
    prop.lcCan = true -- not for pocketing; the officer wants it in the trash
    prop:SetPos(cop:EyePos() + cop:GetForward() * 18 - Vector(0, 0, 18))
    prop:Spawn()
    local phys = prop:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity((ply:GetPos() - prop:GetPos()):GetNormalized() * 160 + Vector(0, 0, 40))
    end
    cop:SetSchedule(SCHED_IDLE_STAND)
    LC.Face(cop, ply:GetPos())
    LC.SetState(cop, cst, "event")
    cst.eventUntil = CurTime() + 45
    cop:EmitSound("npc/metropolice/vo/pickupthecan1.wav", 78)
    can = { prop = prop, cop = cop, cst = cst, ply = ply, stage = "dropped", t = CurTime() }
    canCooldown[ply] = CurTime() + 600
end

local function OnPickup(ply, ent)
    if can and ent == can.prop and can.stage ~= "picked" then
        can.stage = "picked"
        can.t = CurTime()
        if IsValid(can.cop) then
            timer.Simple(0.6, function()
                if can and IsValid(can.cop) then can.cop:EmitSound("npc/metropolice/vo/putitinthetrash1.wav", 78) end
            end)
        end
    end
end
hook.Add("OnPlayerPhysicsPickup", "LivingCityCan", OnPickup)
hook.Add("GravGunOnPickedUp", "LivingCityCan", OnPickup)
hook.Add("PhysgunPickup", "LivingCityCan", function(ply, ent) OnPickup(ply, ent) end)

local function NearTrash(pos)
    for _, b in ipairs(LC.StaticBins or {}) do -- the map's own dumpsters and bins
        if b.pos:DistToSqr(pos) < 90 * 90 then return true end
    end
    for _, e in ipairs(ents.FindInSphere(pos, 70)) do
        local m = string.lower(e:GetModel() or "")
        if string.find(m, "trash", 1, true) or string.find(m, "dumpster", 1, true) or string.find(m, "garbage", 1, true) then
            return true
        end
    end
    return false
end

local function CanThink(now)
    if not can then
        if cvCan:GetInt() == 0 or LC.Event or now < nextCanCheck then return end
        nextCanCheck = now + 30
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.role == "cop" and st.state == "idle" and math.random() < 0.15 then
                for _, ply in ipairs(player.GetAll()) do
                    if ply:Alive() and not ply:InVehicle() and now > (canCooldown[ply] or 0)
                        and not LC.PlayerIsCP(ply) and not LC.PlayerIsZombie(ply) and not (LC.Prisoners and LC.Prisoners[ply])
                        and not (LC.DisguisedAsCP and LC.DisguisedAsCP(ply)) and not (LC.Stops and LC.Stops[ply])
                        and ply:GetPos():DistToSqr(npc:GetPos()) < 250 * 250 then
                        return StartCan(npc, st, ply)
                    end
                end
            end
        end
        return
    end

    local c = can
    if not IsValid(c.cop) or not IsValid(c.ply) or not c.ply:Alive() or c.cst.state ~= "event" then return EndCan(false) end
    LC.Face(c.cop, c.ply:GetPos())
    c.cst.eventUntil = now + 10

    if c.stage == "dropped" then
        if not IsValid(c.prop) then return EndCan(false) end
        if now - c.t > 12 then
            c.stage = "angry"
            c.t = now
            c.cop:EmitSound("npc/metropolice/vo/pickupthecan3.wav", 80)
        end
    elseif c.stage == "angry" then
        if now - c.t > 3 then
            if cvCan:GetInt() >= 2 then
                LC.ReportCrime(c.ply, "Refusing a lawful order", 90)
                LC.MakeCopsHostile(c.ply, c.cop:GetPos(), 60)
            elseif c.ply:GetPos():DistToSqr(c.cop:GetPos()) < 200 * 200 then
                -- a shove, not a beating
                c.ply:SetVelocity(c.cop:GetForward() * 380 + Vector(0, 0, 120))
                c.ply:ViewPunch(Angle(-12, math.Rand(-6, 6), 0))
                c.cop:EmitSound("Weapon_StunStick.Melee_Hit", 70)
            end
            return EndCan(false)
        end
    elseif c.stage == "picked" then
        if not IsValid(c.prop) then return EndCan(false) end
        if NearTrash(c.prop:GetPos()) then return EndCan(true) end
        if now - c.t > 25 then
            c.cop:EmitSound("npc/metropolice/vo/putitinthetrash2.wav", 78)
            return EndCan(false)
        end
    end
end

------------------------------------------------------------------------
-- Main timer
------------------------------------------------------------------------

timer.Create("LivingCityEvents", 0.5, 0, function()
    local ok, err = pcall(function()
        if not LC.Running then
            if LC.Event then LC.EndEvent(true) end
            if can then EndCan(false) end
            return
        end
        local now = CurTime()

        if LC.Event and LC.EventEnds and now > LC.EventEnds then LC.EndEvent(false) end

        if cvAuto:GetBool() and not LC.Event then
            if nextAuto == 0 then nextAuto = now + cvInterval:GetFloat() * 60 end
            if not pendingAuto and nextAuto - now <= SOON then
                pendingAuto = PickAuto()
                LC.PendingEvent = pendingAuto
                hook.Run("LivingCityEventSoon", pendingAuto, math.max(0, nextAuto - now))
            end
            if now > nextAuto then
                LC.StartEvent(pendingAuto or PickAuto())
                pendingAuto, LC.PendingEvent = nil, nil
                nextAuto = now + cvInterval:GetFloat() * 60
            end
        end

        local every = cvAnnounce:GetFloat()
        if every > 0 and not LC.Event then
            if nextAnnounce == 0 then nextAnnounce = now + every * 60 end
            if now > nextAnnounce then
                LC.Announce("ambient")
                nextAnnounce = now + every * 60 * math.Rand(0.8, 1.2)
            end
        end

        if LC.Event == "curfew" or LC.Event == "lockdown" then EnforceCurfew(now) end
        Chatter(now)
        CanThink(now)
    end)
    if not ok then LC.Error("events", err) end
end)

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

concommand.Add("lc_event", function(ply, _, args)
    if not LC.CanEdit(ply) then return end
    local name = string.lower(args[1] or "")
    if not LC.Running then return Say(ply, "[Living City] Start the city first.") end
    if not LC.StartEvent(name, args[2]) then
        return Say(ply, "[Living City] Events: rations, sweep, curfew, lockdown, raid, supply. Usage: lc_event curfew 5")
    end
    Say(ply, "[Living City] Event started: " .. name)
end)

concommand.Add("lc_endevent", function(ply)
    if not LC.CanEdit(ply) then return end
    LC.EndEvent(false)
end)

concommand.Add("lc_announce", function(ply)
    if not LC.CanEdit(ply) then return end
    LC.Announce("ambient")
end)

------------------------------------------------------------------------
-- The PA speaks when something happens, and says what it's about
------------------------------------------------------------------------

local lastSaid = 0
local function Say(file, detail)
    local now = CurTime()
    if now - lastSaid < 45 then return false end -- not a running commentary
    lastSaid = now
    LC.Announce("ambient", CV .. file, detail)
    return true
end
LC.AnnounceLine = Say

-- a unit sets off after someone causing a disturbance
hook.Add("LivingCityQuestAccepted", "LivingCityPA", function(ply, q)
    if q and q.tmpl and q.tmpl.id == "cp_disturbance" then
        Say("f_evasionbehavior_2_spkr.wav", "Civil Protection is chasing someone " .. (q.data and q.data.where or "nearby") .. ". Stay out of the way.")
    end
end)
-- wanted: for running, evasion; for killing or attacking, capital malcompliance
hook.Add("LivingCityWanted", "LivingCityPA", function(ply, reason)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local r = string.lower(reason or "")
    local who = ply:GetNW2String("lcd_alias", "") ~= "" and ("citizen " .. ply:GetNW2String("lcd_alias", "")) or ply:Nick()
    if string.find(r, "kill", 1, true) or string.find(r, "murder", 1, true) or string.find(r, "assault", 1, true) or string.find(r, "attack", 1, true) then
        Say("f_capitalmalcompliance_spkr.wav", who .. " is wanted: " .. (reason or "violence") .. ".")
    elseif string.find(r, "flee", 1, true) or string.find(r, "escap", 1, true) or string.find(r, "evad", 1, true) then
        Say("f_evasionbehavior_2_spkr.wav", who .. " is wanted: " .. (reason or "evasion") .. ".")
    end
end)
-- a long sentence: citizenship revoked
hook.Add("LivingCityIncarcerated", "LivingCityPA", function(ply, secs)
    if IsValid(ply) and ply:IsPlayer() and (tonumber(secs) or 0) >= 300 then
        Say("f_citizenshiprevoked_6_spkr.wav", ply:Nick() .. " has been sentenced.")
    end
end)
-- someone reports a crime: failing to report is conspiracy (said when people do report)
hook.Add("LivingCityRequest", "LivingCityPA", function()
    Say("f_innactionisconspiracy_spkr.wav", "A citizen has reported something to Civil Protection.")
end)
