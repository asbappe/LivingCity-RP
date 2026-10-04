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

    Events run automatically (lc_auto_events) or from the editor panel / commands:
      lc_event <rations|sweep|curfew|lockdown> [minutes], lc_endevent, lc_announce
]]

if CLIENT then return end

util.AddNetworkString("lc_announce")

LC = LC or {}
LC.ExtraCops = LC.ExtraCops or 0

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvAnnounce  = CreateConVar("lc_announce_interval", "6", FLAGS, "Minutes between ambient announcements (0 = off)")
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
    ended    = { CV .. "f_sociostabilizationrestored_spkr.wav" },
}

local TITLES = {
    rations = "Ration distribution", sweep = "Civil status inspections", curfew = "Curfew",
    lockdown = "Lockdown", raid = "Housing block inspection", ended = "Stabilization restored", ambient = "City announcement",
    response = "Overwatch response",
}

local DEFAULT_MINUTES = { rations = 3, sweep = 2, curfew = 4, lockdown = 3, raid = 4 }
local AUTO_WEIGHTS = { { "rations", 45 }, { "sweep", 30 }, { "curfew", 18 }, { "lockdown", 7 }, { "raid", 14 } }

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

function LC.Announce(kind, path)
    path = path or LC.Pick(VOICE[kind] or VOICE.ambient)
    net.Start("lc_announce")
    net.WriteString(path)
    net.WriteString(TITLES[kind] or TITLES.ambient)
    net.Broadcast()
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local warnings = {} -- [ply] = { stage, next }
local nextAuto, nextAnnounce = 0, 0
local pendingAuto -- the next automatic event, picked early so radios can warn people
LC.EventSerial = LC.EventSerial or 0
local SOON = 45

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

    LC.Announce(name)
    LC.Log("info", string.format("Event started: %s (%s min)", name, tostring(minutes)))
    hook.Run("LivingCityEventStarted", name, minutes)
    return true
end

local function PickAuto()
    local total = 0
    for _, w in ipairs(AUTO_WEIGHTS) do total = total + w[2] end
    local r = math.random() * total
    for _, w in ipairs(AUTO_WEIGHTS) do
        r = r - w[2]
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
            local tr = util.TraceLine({ start = npc:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = npc })
            if tr.Fraction > 0.97 then return npc, st end
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

local function EnforceCurfew(now)
    if not cvEnforce:GetBool() then return end
    if now < (LC.EventGraceEnds or 0) then return end -- grace period: time to get home
    for _, ply in ipairs(player.GetAll()) do
        local exempt = not ply:Alive() or LC.PlayerIsCP(ply) or LC.PlayerIsZombie(ply)
            or (LC.InCustody and LC.InCustody(ply)) or LC.PlayerIsWanted(ply)
            or (LC.DisguisedAsCP and LC.DisguisedAsCP(ply))
            or (ply.lcPermitSerial ~= nil and ply.lcPermitSerial == LC.EventSerial)
        if not exempt and LC.PlayerInOwnBlock then
            exempt = LC.PlayerInOwnBlock(ply) == true
        end
        if exempt then
            warnings[ply] = nil
        else
            local w = warnings[ply] or { stage = 0, next = 0 }
            warnings[ply] = w
            if now > w.next then
                local cop, cst = SeenByCop(ply)
                if cop and LC.CurfewExcuse and LC.CurfewExcuse(ply, cop) then
                    warnings[ply] = nil -- a permit, or papers that say night shift
                elseif cop then
                    w.stage = w.stage + 1
                    w.next = now + 8
                    LC.Face(cop, ply:GetPos())
                    local home = LC.PlayerBlock and LC.PlayerBlock(ply)
                    local where = home and BlockName(home) or "your residence"
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
        return Say(ply, "[Living City] Events: rations, sweep, curfew, lockdown, raid. Usage: lc_event curfew 5")
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
