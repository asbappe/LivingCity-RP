--[[
    Living City: the Resistance's operations, and what the city does about them

      Combine doors   a Resistance member (Member and up) can hack a Combine or
                      locked door: !hack (or bind a key to lc_hack), looking at
                      it, twelve seconds, and it opens for thirty. Sometimes it
                      trips an alarm. Rebel NPCs on an operation do the same
                      by themselves when a Combine door is in their way.
      NPC operations  the Resistance's fighters run operations too, now and
                      then (lc_rebel_ops 1): a raid on a data terminal (the
                      Resistance get the decoded data), a prison break when one
                      of their own is in a cell, a city screen hijack. They hold
                      the objective for a while to pull it off; units can stop
                      them. And they answer what the Combine do: an Overwatch
                      landing or a supply drop gets a team sent at it (an
                      ambush; a raid on the crate, two loads gone and food for
                      the stores) lc_rebel_react of the time (0.5), straight
                      away, whenever no other fight is on.
      Prison break    the Resistance can break one of their own out of a cell
                      (Operations board): get to the cell, hold it open while
                      the alarm goes. Units get "Prison break".
      Smugglers       a Resistance supply run is watched: once the crate is
                      taken, every unit sees SMUGGLER on their screen where the
                      carrier is, every few seconds, and gets "Intercept the
                      smuggler". Arresting or killing the carrier stops it.
      Informants      a citizen can quietly report someone to Civil Protection:
                      !inform, looking at them (or !inform <name>). If they
                      really are Resistance, wanted, or carrying contraband,
                      the tip is real: units see them outlined for a minute and
                      the informant is paid. A false report costs standing. A
                      Resistance member who sees you do it marks you a
                      traitor: the Resistance (players and fighters) know.
      Screen hijack   a Resistance member wires into a city screen (!hijack, or
                      E on it, ten seconds), and for a minute the screen is
                      theirs: the city hears the Resistance's message. Units
                      cut it with E on the screen. If it runs its minute, rebel
                      ground spreads faster and sociostability slips to yellow
                      for ten minutes.
      Overwatch drops when sociostability stays red (or the city is in unrest),
                      Overwatch sends soldiers down to a landing zone (editor
                      "Point: Overwatch landing zone", or a street). Units get
                      "Secure the landing zone"; the Resistance "Ambush the
                      landing".
      Foremen         a Trusted citizen (150 standing) can be a Union foreman
                      (!foreman): !assign <name> hands another citizen a work
                      order, and the foreman takes a cut of their pay.
      Vortigaunts     the Resistance can free a shackled vortigaunt from a
                      Combine work site and bring it home: it stays in rebel
                      territory and heals the Resistance's wounded.

      lc_rebel_ops 0/1, lc_rebel_react (0.5), lc_overwatch_drops 0/1, lc_drop_soldiers (4),
      lc_drop_cooldown (60), lc_informants 0/1, lc_rebel_ops_minutes (60: operations are sporadic)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOps      = CreateConVar("lc_rebel_ops", "1", FLAGS, "Rebel NPCs run operations: data heists, prison breaks, screen hijacks, ambushes")
local cvDrops    = CreateConVar("lc_overwatch_drops", "1", FLAGS, "Overwatch sends soldiers down when the city stays in unrest")
local cvDropN    = CreateConVar("lc_drop_soldiers", "4", FLAGS, "Soldiers in an Overwatch drop")
local cvDropCool = CreateConVar("lc_drop_cooldown", "60", FLAGS, "Minutes between Overwatch drops")
local cvInform   = CreateConVar("lc_informants", "1", FLAGS, "Citizens can inform on people")
local cvOpsGap   = CreateConVar("lc_rebel_ops_minutes", "60", FLAGS, "Least minutes between the Resistance fighters' own operations (sporadic, not a war)")
local cvReact    = CreateConVar("lc_rebel_react", "0.5", FLAGS, "Chance the Resistance's fighters go for an Overwatch landing or a supply drop (0 to 1)")

local function Pick(t) return t[math.random(#t)] end
local function Unit(p) return LC.PlayerIsCP and LC.PlayerIsCP(p) end
local function IsResistance(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end
-- Combine locks, screens and terminals need the multitool: the Resistance's Hackers carry one;
-- anyone else can buy one from the black market (contraband)
function LC.CanHack(p) return IsValid(p) and p:IsPlayer() and p:HasWeapon("weapon_lc_multitool") end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "" end
local function Units()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if Unit(p) then out[#out + 1] = p end end
    return out
end
local function TellUnits(text) for _, p in ipairs(Units()) do p:ChatPrint(text) end end
local function MarkUnits(name, pos, secs)
    local units = Units()
    if LC.SendCompressed and #units > 0 then
        LC.SendCompressed("lc_cpmark", { name = name, x = pos.x, y = pos.y, z = pos.z, secs = secs or 90 }, units)
    end
end
local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end

------------------------------------------------------------------------
-- Combine doors
------------------------------------------------------------------------

local function LockedCombineDoor(door)
    if not (LC.IsDoorEntity and LC.IsDoorEntity(door)) then return false end
    if LC.DoorPicked and LC.DoorPicked(door) then return false end
    local cp, locked = true, true
    if LC.DoorLockKind then cp, locked = LC.DoorLockKind(door) end
    return cp or locked
end

function LC.HackDoor(ply)
    if not LC.CanHack(ply) then
        return false, "You need a multitool for that. (The Resistance's Hackers carry one; the black market sells them.)"
    end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    local tr = ply:GetEyeTrace()
    local door = tr and tr.Entity
    if not IsValid(door) or tr.HitPos:DistToSqr(ply:EyePos()) > 110 * 110 or not LockedCombineDoor(door) then
        return false, "Look at a locked Combine door, up close."
    end
    ply:EmitSound("buttons/combine_button7.wav", 60)
    return LC.StartTask(ply, 12, "Hacking the lock... keep at it", {
        maxMove = 40, cancelText = "You pull the wires out. It stays shut.",
        done = function(p)
            if not IsValid(door) then return end
            if LC.OpenPickedDoor then LC.OpenPickedDoor(door, true) else door:Fire("Unlock") door:Fire("Open", "", 0.1) end
            door:EmitSound("buttons/combine_button1.wav", 70)
            p:ChatPrint("[Resistance] The lock gives. Thirty seconds before it shuts again.")
            if math.random() < 0.35 then
                TellUnits("[CP net] Door breach " .. Where(door:GetPos()) .. ". A Combine lock has been tampered with.")
                MarkUnits("DOOR BREACH", door:GetPos(), 60)
            end
            if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then LC.ReportCrime(p, "Tampering with a Combine lock", 180) end
            hook.Run("LivingCityDoorHacked", p, door)
        end,
    })
end
concommand.Add("lc_hack", function(ply) if IsValid(ply) then local ok, why = LC.HackDoor(ply) if not ok and why then ply:ChatPrint(why) end end end)

-- Rebel fighters on an operation get through Combine doors in their way.
local hacking = {}
local function NPCDoors(sk, now)
    for _, npc in ipairs(sk.rebels or {}) do
        if IsValid(npc) and npc:Health() > 0 then
            local h = hacking[npc]
            if h then
                if not IsValid(h.door) or npc:GetPos():DistToSqr(h.door:GetPos()) > 160 * 160 then
                    hacking[npc] = nil
                elseif now >= h.at then
                    hacking[npc] = nil
                    if LockedCombineDoor(h.door) and LC.OpenPickedDoor then
                        LC.OpenPickedDoor(h.door, true)
                        h.door:EmitSound("buttons/combine_button1.wav", 70)
                    end
                end
            else
                for _, e in ipairs(ents.FindInSphere(npc:GetPos(), 110)) do
                    if LockedCombineDoor(e) then
                        hacking[npc] = { door = e, at = now + 4 }
                        npc:EmitSound("buttons/combine_button7.wav", 60)
                        break
                    end
                end
            end
        else
            hacking[npc] = nil
        end
    end
end

------------------------------------------------------------------------
-- Prison breaks
------------------------------------------------------------------------

function LC.BreakOut(prisoner, by)
    if not IsValid(prisoner) or not (LC.Prisoners and LC.Prisoners[prisoner]) then return false end
    prisoner:ChatPrint("[Resistance] The cell door slams open. \"Move. Now.\" You're out, and wanted.")
    if LC.EscapePrisoner then LC.EscapePrisoner(prisoner) end
    Radio("resistance", prisoner:Nick() .. " is out. Get them home.")
    if IsValid(by) and by:IsPlayer() and LC.AddXP then LC.AddXP(by, 50, "prison break") end
    hook.Run("LivingCityBreakout", prisoner, by)
    return true
end

function LC.PrisonBreakAlarm(pos)
    TellUnits("[CP net] PRISON BREAK " .. Where(pos) .. ". Anticitizens are at the cells. All Civil Protection units respond.")
    MarkUnits("PRISON BREAK", pos, 120)
    if sound and sound.Play then sound.Play("ambient/alarms/klaxon1.wav", pos, 85) end -- (a klaxon that ends: the alarm used before is a loop, and never stopped)
    LC.LastPrisonBreak = { pos = pos, at = CurTime() }
    if LC.PostDirective then LC.PostDirective("cp_prisonbreak") end
end

-- A jailed member of the Resistance, and where their cell is.
function LC.JailedRebel()
    for p, pr in pairs(LC.Prisoners or {}) do
        if IsValid(p) and IsResistance(p) and pr.cell then return p, pr.cell.pos end
    end
    return nil
end

------------------------------------------------------------------------
-- Smugglers on a supply run
------------------------------------------------------------------------

LC.Smugglers = LC.Smugglers or {} -- [q] = true

function LC.TrackSmuggler(q)
    LC.Smugglers[q] = true
    TellUnits("[CP net] Union supplies stolen. The smuggler's on the move: follow the SMUGGLER marker.")
    if LC.PostDirective then LC.PostDirective("cp_intercept") end
end

local function SmugglerTick()
    for q in pairs(LC.Smugglers) do
        local c = q.owner
        if q.done or not IsValid(c) or not c:Alive() then
            LC.Smugglers[q] = nil
        else
            MarkUnits("SMUGGLER", c:GetPos(), 8)
        end
    end
end

-- Arrested or killed with the crate: stopped.
local function Stopped(ply)
    for q in pairs(LC.Smugglers) do
        if q.owner == ply and not q.done then
            LC.Smugglers[q] = nil
            for _, u in ipairs(Units()) do if LC.QuestEvent then LC.QuestEvent("smuggler_stopped", u, ply) end end
            TellUnits("[CP net] The smuggler is down. Supplies recovered.")
            if LC.AbandonQuest then LC.AbandonQuest(ply) end
        end
    end
end
hook.Add("PlayerDeath", "LivingCitySmugglers", function(ply) Stopped(ply) end)
hook.Add("LivingCityIncarcerated", "LivingCitySmugglers", function(ply) if IsValid(ply) and ply:IsPlayer() then Stopped(ply) end end)

------------------------------------------------------------------------
-- Informants
------------------------------------------------------------------------

local function HasContraband(p)
    for id, n in pairs(LC.Inventory and LC.Inventory(p) or {}) do
        local it = LCS.Items[id]
        if n > 0 and it and it.contraband then return true end
    end
    return false
end

function LC.Inform(ply, target)
    if not cvInform:GetBool() then return false end
    if Unit(ply) then return false, "You're a Civil Protection unit: arrest them." end
    if IsResistance(ply) then return false, "Inform on your own? No." end
    if not IsValid(target) or not target:IsPlayer() or target == ply then return false, "Look at who you want to report (or !inform <name>)." end
    if (ply.lcInformNext or 0) > CurTime() then return false, string.format("Civil Protection has your last report. (%ds)", math.ceil(ply.lcInformNext - CurTime())) end
    ply.lcInformNext = CurTime() + 300
    local real = IsResistance(target) or (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) or HasContraband(target)
    -- seen doing it? A Resistance member who watches you talk to the Combine remembers.
    local eye = ply:EyePos()
    for _, w in ipairs(player.GetAll()) do
        if w ~= ply and IsResistance(w) and w:Alive() and w:GetPos():DistToSqr(ply:GetPos()) < 700 * 700 then
            local tr = util.TraceLine({ start = w:EyePos(), endpos = eye, mask = MASK_OPAQUE, filter = { w, ply } })
            if tr.Fraction > 0.97 then
                ply:SetNW2Float("lc_traitor_until", CurTime() + 1800)
                Radio("resistance", w:Nick() .. " saw " .. ply:Nick() .. " informing to the Combine. Traitor.")
                hook.Run("LivingCityTraitor", ply, w)
                break
            end
        end
    end
    if real then
        local who = target:GetNW2String("lcd_alias", "") ~= "" and ("citizen " .. target:GetNW2String("lcd_alias", "")) or target:Nick()
        TellUnits("[CP net] Informant tip: " .. who .. " is a suspected anticitizen, " .. Where(target:GetPos()) .. ". Outlined for 60 seconds.")
        target:SetNW2Float("lc_spotted_until", CurTime() + 60)
        target:SetNW2String("lc_spotted_why", "informant tip")
        if LC.AddViolation then LC.AddViolation(target, "Informant tip: suspected anticitizen") end
        if LC.AddCredits then LC.AddCredits(ply, 25, "informant's reward") end
        if LC.AddStanding then LC.AddStanding(ply, 5, "useful information") end
        ply:ChatPrint("[Civil Protection] Your report has been received. The Union thanks you.")
    else
        if LC.AddStanding then LC.AddStanding(ply, -5, "a false report") end
        ply:ChatPrint("[Civil Protection] Your report was checked. It was false. Don't waste our time.")
    end
    hook.Run("LivingCityInformed", ply, target, real)
    return true, real
end

------------------------------------------------------------------------
-- Hijacking a city screen
------------------------------------------------------------------------

local MESSAGES = {
    "Citizens of City 17. They count your rations, your words, your children. Count theirs.",
    "The Combine are not invincible. Every Civil Protection unit you see is a man in a mask. Remember that.",
    "Lambda lives. Help is closer than you think.",
    "Their cameras are blind tonight. Look out for one another.",
}

function LC.HijackStart(screen, by)
    if not IsValid(screen) or screen:GetNW2Float("lc_hijacked_until", 0) > CurTime() then return false end
    screen:SetNW2Float("lc_hijacked_until", CurTime() + 60)
    screen.lcHijacker = by
    screen.lcHijackedAt = CurTime() -- (units take it back if no player does: sv_livingcity_npcwork.lua)
    local where = Where(screen:GetPos())
    TellUnits("[CP net] A city screen " .. where .. " has been hijacked. Get there and cut it (E on the screen).")
    MarkUnits("HIJACKED SCREEN", screen:GetPos(), 70)
    if LC.PostDirective then LC.PostDirective("cp_retakescreen") end
    LC.LastHijack = { pos = screen:GetPos(), at = CurTime(), screen = screen }
    for i = 0, 3 do
        timer.Simple(i * 15, function()
            if IsValid(screen) and screen:GetNW2Float("lc_hijacked_until", 0) > CurTime() then
                for _, p in ipairs(player.GetAll()) do p:ChatPrint("[Broadcast interrupted] " .. MESSAGES[i + 1]) end
            end
        end)
    end
    timer.Simple(60, function()
        if not IsValid(screen) or screen:GetNW2Float("lc_hijacked_until", 0) <= 0 then return end
        screen:SetNW2Float("lc_hijacked_until", 0)
        LC.RebelSurgeUntil = CurTime() + 600
        LC.SocioOverride = { level = "yellow", untilT = CurTime() + 600, by = "Resistance broadcast" }
        if LC.RefreshSocio then pcall(LC.RefreshSocio, false, true) end
        for _, p in ipairs(player.GetAll()) do p:ChatPrint("[City] The Resistance's message ran for a full minute. People are talking.") end
        if IsValid(screen.lcHijacker) and screen.lcHijacker:IsPlayer() and LC.AddXP then LC.AddXP(screen.lcHijacker, 40, "screen hijack") end
        hook.Run("LivingCityHijackDone", screen)
    end)
    hook.Run("LivingCityHijack", screen, by)
    return true
end

function LC.HijackScreen(ply, screen)
    if not LC.CanHack(ply) then return false, "You need a multitool to wire into it." end
    if not IsValid(screen) or screen:GetClass() ~= "lc_screen" then return false, "Look at a city screen." end
    if screen:GetNW2Float("lc_hijacked_until", 0) > CurTime() then return false, "It's already ours." end
    if LC.Busy and LC.Busy(ply) then return false, "You're busy." end
    return LC.StartTask(ply, 10, "Wiring into the screen... keep at it", {
        maxMove = 40, cancelText = "You pull the wires. The screen goes back to the Combine.",
        done = function(p)
            if LC.HijackStart(screen, p) then
                p:ChatPrint("[Resistance] You're in. One minute: keep Civil Protection units off it.")
                if LC.SeenBySecurity and LC.SeenBySecurity(p, 900) then LC.ReportCrime(p, "Sedition", 240) end
            end
        end,
    })
end

function LC.CutHijack(ply, screen)
    if not Unit(ply) or not IsValid(screen) or screen:GetNW2Float("lc_hijacked_until", 0) <= CurTime() then return false end
    screen:SetNW2Float("lc_hijacked_until", 0)
    screen:EmitSound("buttons/combine_button2.wav", 70)
    if LC.AddXP then LC.AddXP(ply, 20, "hijacked screen cut") end
    TellUnits("[CP net] The hijacked screen is back under control.")
    for _, p in ipairs(player.GetAll()) do if IsResistance(p) then p:ChatPrint("[Resistance] They cut the broadcast.") end end
    if LC.QuestEvent then LC.QuestEvent("screen_retaken", ply, screen) end
    return true
end

hook.Add("KeyPress", "LivingCityHijack", function(ply, key)
    if key ~= IN_USE or not ply:Alive() then return end
    if (ply.lcHijackNext or 0) > CurTime() then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if not IsValid(e) or e:GetClass() ~= "lc_screen" or tr.HitPos:DistToSqr(ply:EyePos()) > 130 * 130 then return end
    ply.lcHijackNext = CurTime() + 1
    if Unit(ply) then LC.CutHijack(ply, e)
    elseif LC.CanHack(ply) then
        local ok, why = LC.HijackScreen(ply, e)
        if not ok and why then ply:ChatPrint(why) end
    end
end)

------------------------------------------------------------------------
-- Overwatch drops
------------------------------------------------------------------------

LC.OverwatchDrop = LC.OverwatchDrop or nil
local nextDrop, redSince = 0, nil

function LC.StartOverwatchDrop(pos)
    if LC.OverwatchDrop then return false, "a drop is already down" end
    if not pos then
        local lz = LC.PointsOfKind and LC.PointsOfKind("lz") or {}
        pos = #lz > 0 and Pick(lz).pos or (LC.SupplyDropSpot and LC.SupplyDropSpot())
    end
    if not pos then return false, "nowhere to land" end
    local d = { pos = pos, soldiers = {}, startT = CurTime(), untilT = CurTime() + 300 }
    LC.OverwatchDrop = d
    local where = Where(pos)
    TellUnits("[CP net] Overwatch reinforcements inbound " .. where .. ". Secure the landing zone.")
    MarkUnits("LANDING ZONE", pos, 120)
    Radio("resistance", "Dropship inbound " .. where .. ". Overwatch soldiers. Hit them on the ground, or keep clear.")
    if LC.AnnounceLine then LC.AnnounceLine("f_protectionresponse_1_spkr.wav", "Overwatch soldiers are landing " .. where .. ".") end
    if LC.PostDirective then LC.PostDirective("cp_securelz") LC.PostDirective("res_ambushlz") end
    -- They come by dropship: in over the rooftops, down over the landing zone,
    -- out they come, and it climbs away. Under a roof (no open sky), they come on foot.
    local clear = 0 -- (how far out to stand: the container takes up room)
    -- When the city is on red and has been for a while (this is what brings a
    -- drop), the first one out is an Overwatch Elite; the rest are soldiers.
    local elite = LC.Socio == "red"
    local function Deploy(spot, i, n, onFoot, door)
        local sp = LC.Spawners and LC.Spawners.soldier
        if not sp or LC.OverwatchDrop ~= d then return end
        local a = i / math.max(1, n) * math.pi * 2
        local at
        if door then
            at = door.pos + Vector(0, 0, 4) -- (out of the container's door, one after another)
        else
            at = spot + Vector(math.cos(a) * (50 + clear + i * 12), math.sin(a) * (50 + clear + i * 12), 6)
            if LC.GroundAt then at = LC.GroundAt(at) + Vector(0, 0, 6) end
        end
        local ok, npc, st = pcall(sp, at, (elite and i == 1) and "elite" or nil)
        if ok and IsValid(npc) and st and door then
            npc:SetAngles(Angle(0, door.dir:Angle().y, 0))
            -- the deploy: Half-Life 2's soldiers jump or step down out of the container
            if LC.PlayGesture then LC.PlayGesture(npc, { "Dropship_Deploy", "ACT_JUMP", "jump_holding_land" }, 1.4) end
        end
        if ok and IsValid(npc) and st then
            st.unmanaged = true
            st.dropGuard = true
            st.drop = d
            st.routeGroup = nil
            -- they take up posts round the landing zone (and fight from there)
            local post = pos + Vector(math.cos(a) * 160, math.sin(a) * 160, 0)
            st.holdPos = LC.GroundAt and LC.GroundAt(post) or post
            if LC.GoTo then
                if door then timer.Simple(1.5, function() if IsValid(npc) and st then LC.GoTo(npc, st, st.holdPos, true, nil) end end)
                else LC.GoTo(npc, st, st.holdPos, onFoot, nil) end
            end
            d.soldiers[#d.soldiers + 1] = npc
        end
    end
    local n = cvDropN:GetInt()
    d.expected = n
    timer.Simple(6, function()
        if LC.OverwatchDrop ~= d then return end
        local ship = LC.FlyDropship and LC.FlyDropship({ pos = pos, hold = 8 + n * 1.5, troops = true, -- (the soldiers come out of its container, which never leaves its claws)
            onLanded = function(_, ground, container, door)
                if IsValid(container) and not door then clear = 130 end
                for i = 1, n do timer.Simple(1 + (i - 1) * 1.4, function() Deploy(ground, i, n, false, door) end) end
            end })
        if ship then
            d.ship = ship
            return
        end
        -- on foot, from out of sight, at a run
        local from = LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos) or pos
        Radio("resistance", "No dropship: they're coming in on foot " .. where .. ".")
        for i = 1, n do timer.Simple((i - 1) * 0.5, function() Deploy(from, i, n, true) end) end
    end)
    hook.Run("LivingCityOverwatchDrop", d)
    return true, d
end

function LC.EndOverwatchDrop()
    local d = LC.OverwatchDrop
    if not d then return end
    LC.OverwatchDrop = nil
    nextDrop = CurTime() + cvDropCool:GetFloat() * 60
    for _, s in ipairs(d.soldiers) do
        local st = IsValid(s) and LC.NPCs and LC.NPCs[s]
        if st then st.unmanaged, st.dropGuard, st.drop, st.holdPos, st.eventUntil, st.leaveAt = nil, nil, nil, nil, 0, CurTime() + 60 end
    end
end

-- The Overwatch Commander calls a squad in: to the landing zone nearest
-- them (or where they stand), one every fifteen minutes.
local COMMAND_EVERY = 15 * 60
LC.CommanderDropAt = LC.CommanderDropAt or 0
function LC.CommanderDrop(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_special", "") ~= "ow_commander" then return false, "Only the Overwatch Commander can call in a squad." end
    local now = CurTime()
    if now < LC.CommanderDropAt then
        local left = LC.CommanderDropAt - now
        return false, string.format("The next squad can be called in %d:%02d.", math.floor(left / 60), math.floor(left % 60))
    end
    if LC.OverwatchDrop then return false, "A squad is already down." end
    local best
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("lz") or {}) do
        if not best or p.pos:DistToSqr(ply:GetPos()) < best:DistToSqr(ply:GetPos()) then best = p.pos end
    end
    local ok, d = LC.StartOverwatchDrop(best or ply:GetPos())
    if not ok then return false, "The dropship can't come: " .. tostring(d) .. "." end
    LC.CommanderDropAt = now + COMMAND_EVERY
    for _, p in ipairs(player.GetAll()) do p:SetNW2Float("lc_cmd_drop_at", LC.CommanderDropAt) end
    return true
end
LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.dropship = function(ply)
    local ok, why = LC.CommanderDrop(ply)
    if ok then
        if LC.Notice then LC.Notice(ply, "info", "Squad inbound", "A dropship is on its way with an Overwatch squad. Secure the landing zone.", 6) end
    elseif why then
        if LC.Notice then LC.Notice(ply, "bad", "No squad", why, 5) else ply:ChatPrint(why) end
    end
end

local function DropTick(now)
    local d = LC.OverwatchDrop
    if d then
        local alive = 0
        for _, s in ipairs(d.soldiers) do if IsValid(s) and s:Health() > 0 then alive = alive + 1 end end
        if now > d.untilT or (now - d.startT > 45 and alive == 0) then -- (the dropship takes a while to come in)
            if alive == 0 and now - d.startT > 45 then
                Radio("resistance", "The landing party is down. Good work.")
                TellUnits("[CP net] The Overwatch landing party is lost.")
            end
            LC.EndOverwatchDrop()
        end
        return
    end
    if not cvDrops:GetBool() or not LC.Running or now < nextDrop then return end
    local hot = LC.Socio == "red" or (LC.CityState and LC.CityState() == "unrest")
    if hot then
        redSince = redSince or now
        if now - redSince > 90 then
            redSince = nil
            LC.StartOverwatchDrop()
        end
    else
        redSince = nil
    end
end

------------------------------------------------------------------------
-- The Resistance's fighters run operations of their own
------------------------------------------------------------------------

local NEED = { heist = 30, breakout = 15, screen = 15, ambush = 20, supply = 15 }
local triedBreakout = setmetatable({}, { __mode = "k" })

local function Achieve(sk)
    sk.achieved = true -- (not sk.done: that is EndSkirmish's own flag, and setting it here meant the skirmish never ended, so no raid or sweep came again)
    local purpose, data = sk.purpose, sk.data or {}
    if purpose == "heist" then
        if data.key and LC.TerminalReadyAt then LC.TerminalReadyAt[data.key] = CurTime() + 20 * 60 end
        SetGlobal2Float("lc_rebel_intel", CurTime() + 300)
        Radio("resistance", "Our fighters got into the Combine's systems: Civil Protection unit positions for everyone, five minutes. Move.")
        TellUnits("[CP net] Data stolen from a Combine terminal " .. Where(sk.target) .. ".")
    elseif purpose == "breakout" then
        if IsValid(data.prisoner) then LC.BreakOut(data.prisoner, nil) end
    elseif purpose == "screen" then
        if IsValid(data.screen) then LC.HijackStart(data.screen, nil) end
    elseif purpose == "ambush" then
        Radio("resistance", "Our fighters hit the landing zone.")
    elseif purpose == "supply" then
        local sup, took = LC.Supply, 0
        if sup and IsValid(sup.crate) then
            local left = sup.crate:GetNW2Int("lc_loads", 0)
            took = math.min(2, left)
            if took > 0 then sup.crate:SetNW2Int("lc_loads", left - took) end
        end
        -- and food for the stores at home
        local rp = sk.zone and LC.RebelProps and LC.RebelProps[sk.zone]
        if rp and IsValid(rp.cache) and LC.AddToCache then LC.AddToCache(rp.cache, 3) end
        Radio("resistance", took > 0 and string.format("Our fighters got into the supply drop: %d load%s gone, and food for the stores.", took, took == 1 and "" or "s")
            or "Our fighters hit the supply drop. Cleaned out already.")
        TellUnits("[CP net] Anticitizens looted the supply drop " .. Where(sk.target) .. ".")
    end
    hook.Run("LivingCityRebelOpDone", purpose, sk)
end

local function OpTick(now)
    local sk = LC.Skirmish
    if not sk then return end
    NPCDoors(sk, now)
    if not sk.purpose or sk.done or sk.achieved then return end
    local near = 0
    for _, npc in ipairs(sk.rebels or {}) do
        if IsValid(npc) and npc:Health() > 0 and npc:GetPos():DistToSqr(sk.target) < 280 * 280 then near = near + 1 end
    end
    if near > 0 then
        sk.progress = (sk.progress or 0) + 1
        if not sk.alarmed and sk.progress >= math.floor((NEED[sk.purpose] or 20) / 2) then
            sk.alarmed = true
            if sk.purpose == "heist" then
                TellUnits("[CP net] DATA BREACH " .. Where(sk.target) .. ". Armed anticitizens at a Combine terminal.")
                MarkUnits("DATA BREACH", sk.target, 120)
                if LC.PostDirective then LC.LastBreach = { pos = sk.target, at = now } LC.PostDirective("cp_databreach") end
            elseif sk.purpose == "breakout" then
                LC.PrisonBreakAlarm(sk.target)
            end
        end
        if sk.progress >= (NEED[sk.purpose] or 20) then Achieve(sk) end
    end
end

local function NearestRebelZone(pos)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        if not z.grown then
            local d = z.pos:DistToSqr(pos)
            if not bd or d < bd then best, bd = z, d end
        end
    end
    return best
end

local function LaunchOp(purpose, target, data)
    local z = NearestRebelZone(target)
    if not z or not LC.StartRebelRaid then return false end
    local ok = LC.StartRebelRaid(z, target, purpose, data)
    if ok then
        local what = ({ heist = "a Combine data terminal", breakout = "the prison", screen = "a city screen", ambush = "the landing zone", supply = "the supply drop" })[purpose]
        Radio("resistance", "Our fighters are going for " .. (what or "the Combine") .. " " .. Where(target) .. ". Lend a hand.")
    end
    return ok
end
LC.LaunchRebelOp = LaunchOp

-- What the Combine do, the Resistance answer: an Overwatch landing or a supply
-- drop gets a team sent at it now and then, straight away, not on the
-- operations' slow clock.
local function React(now)
    if not cvOps:GetBool() or not LC.Running or LC.Skirmish then return false end
    local chance = math.Clamp(cvReact:GetFloat(), 0, 1)
    local d = LC.OverwatchDrop
    if d and not d.ambushed and now - d.startT > 25 then
        d.ambushed = true
        if math.random() < chance then return LaunchOp("ambush", d.pos, {}) end
    end
    local sup = LC.Supply
    if sup and not sup.rebelsTried and now - sup.startT > 40 then
        sup.rebelsTried = true
        if math.random() < chance then return LaunchOp("supply", sup.pos, {}) end
    end
    return false
end
LC.RebelReact = React

local nextOpAllowed = 0
local MaybeLaunchOne
local function MaybeLaunch(now)
    if not cvOps:GetBool() or not LC.Running or LC.Skirmish then return end
    -- sporadic: one operation in a while (lc_rebel_ops_minutes, 60, give or take), never a running battle
    if nextOpAllowed == 0 then nextOpAllowed = now + cvOpsGap:GetFloat() * 60 * math.Rand(0.4, 0.8) end
    if now < nextOpAllowed then return end
    local launched = MaybeLaunchOne(now)
    if launched then nextOpAllowed = now + cvOpsGap:GetFloat() * 60 * math.Rand(0.8, 1.2) * (LC.MarketOpsMul and LC.MarketOpsMul() or 1) * (LC.SmallOpsMul and LC.SmallOpsMul() or 1) end -- (small-server mode: sv_livingcity_smallserver.lua) -- (sooner while the Commissary's restricted: sv_livingcity_market.lua)
end

MaybeLaunchOne = function(now)
    -- one of ours in a cell: they come for them (once per stay)
    local prisoner, cellPos = LC.JailedRebel()
    if prisoner and not triedBreakout[prisoner] and LC.Prisoners[prisoner] and (LC.Prisoners[prisoner].untilT - now) > 60 then
        triedBreakout[prisoner] = true
        if math.random() < 0.5 then return LaunchOp("breakout", cellPos, { prisoner = prisoner }) end
    end
    local r = math.random()
    if r < 0.06 and LC.DataTerminals then
        local ready = {}
        for _, t in ipairs(LC.DataTerminals()) do if (LC.TerminalReadyAt[t.key] or 0) <= now then ready[#ready + 1] = t end end
        if #ready > 0 then local t = Pick(ready) return LaunchOp("heist", t.pos, { key = t.key }) end
    elseif r < 0.1 then
        local screens = LC.EntsOf("lc_screen")
        if #screens > 0 then local s = Pick(screens) return LaunchOp("screen", s:GetPos(), { screen = s }) end
    end
end

------------------------------------------------------------------------
-- Union foremen
------------------------------------------------------------------------

local WORK = { "cit_streetlight", "cit_rubble", "cit_pipe", "cit_cleanup" }
local assignSerial = 900000

function LC.BecomeForeman(ply)
    if LC.QuestFaction and LC.QuestFaction(ply) ~= "citizen" then return false, "Foremen are citizens." end
    if (LC.Standing and LC.Standing(ply) or 0) < 150 then return false, "The Union only makes Trusted citizens foremen (150 Civil Standing)." end
    local on = not ply:GetNW2Bool("lc_foreman", false)
    ply:SetNW2Bool("lc_foreman", on)
    return true, on and "[Union] You're a foreman now. !assign <name> hands a citizen a work order; you take a cut of their pay." or "[Union] You hand back your foreman's armband."
end

function LC.AssignWork(foreman, target)
    if not foreman:GetNW2Bool("lc_foreman", false) then return false, "You're not a foreman (!foreman)." end
    if not IsValid(target) or target == foreman or (LC.QuestFaction and LC.QuestFaction(target) ~= "citizen") then return false, "Assign it to another citizen." end
    if LC.QuestOf and LC.QuestOf[target] then return false, target:Nick() .. " is already working." end
    local t
    local ids = table.Copy(WORK)
    while #ids > 0 and not t do
        local id = table.remove(ids, math.random(#ids))
        for _, x in ipairs(LC.QuestTemplates or {}) do if x.id == id then t = x end end
    end
    if not t then return false, "No work orders to hand out." end
    local okB, spec = pcall(t.build, target)
    if not okB or not spec then return false, "Nothing to send them to right now." end
    assignSerial = assignSerial + 1
    spec.id, spec.tmpl, spec.faction, spec.data = assignSerial, t, "citizen", spec.data or {}
    spec.title = spec.title .. " (from foreman " .. foreman:Nick() .. ")"
    LC.Postings.citizen = LC.Postings.citizen or {}
    table.insert(LC.Postings.citizen, 1, spec)
    target.lcqNext = 0
    if not LC.AcceptPosting(target, spec.id) then return false, target:Nick() .. " can't take it right now." end
    local q = LC.QuestOf[target]
    if q then q.foreman = foreman end
    target:ChatPrint("[Union] Foreman " .. foreman:Nick() .. " has given you a work order: " .. spec.title .. ". It's on your board (F4).")
    return true, "[Union] Work order handed to " .. target:Nick() .. "."
end

hook.Add("LivingCityQuestComplete", "LivingCityForeman", function(p, q)
    if q and q.foreman and IsValid(q.foreman) and p == q.owner then
        local cut = math.max(5, math.floor((q.reward or 10) * 0.5))
        LC.AddCredits(q.foreman, cut, "foreman's cut")
        if LC.AddStanding then LC.AddStanding(q.foreman, 1, nil) end
    end
end)

------------------------------------------------------------------------
-- Freed vortigaunts charge the Resistance's vests (sv_livingcity_vest.lua)
------------------------------------------------------------------------

LC.RebelVorts = LC.RebelVorts or {}

function LC.SettleVort(npc, quiet)
    if not IsValid(npc) then return end
    LC.RebelVorts[npc] = true
    local st = LC.NPCs and LC.NPCs[npc]
    if st then
        st.unmanaged, st.leaveAt, st.questLock = true, nil, nil
        if LC.SetState then LC.SetState(npc, st, "event") end
        st.eventUntil = CurTime() + 1e6
    end
    LC.SetNPCStr(npc, "lc_pname", "Freed vortigaunt")
    if not quiet then Radio("resistance", "The vortigaunt is home. Ask it (E) and it will charge your vest.") end
end

-- Vortigaunts already living free in rebel territory, whether or not anyone has freed one
-- (they used to come only from the "Free a vortigaunt" job): this many, at a spot in rebel ground.
local cvVorts = CreateConVar("lc_rebel_vorts", "1", FLAGS, "Freed vortigaunts living in rebel territory from the start (more come from the Free a vortigaunt job)")
local nextVortHome = 0
local function VortHome(now)
    if now < nextVortHome or not LC.Running then return end
    nextVortHome = now + 30
    local have = 0
    for v in pairs(LC.RebelVorts) do if IsValid(v) then have = have + 1 end end
    if have >= cvVorts:GetInt() then return end
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
    if #zones == 0 then return end
    local spot = LC.SpotInZone and LC.SpotInZone(zones[math.random(#zones)])
    if not spot then return end
    local v = ents.Create("npc_vortigaunt")
    if not IsValid(v) then return end
    v:SetPos(spot + Vector(0, 0, 4))
    v:Spawn()
    v:Activate()
    if LC.RegisterNPC then LC.RegisterNPC(v, "vortigaunt") end
    v:SetNW2Bool("lc_noragdoll", true) -- (dead: a body the morticians collect)
    LC.SettleVort(v, true)
end
LC.VortHome = function(now) nextVortHome = 0 VortHome(now or CurTime()) end -- (for tests)

local function VortTick()
    for v in pairs(LC.RebelVorts) do
        if not IsValid(v) or v:Health() <= 0 then LC.RebelVorts[v] = nil end
    end
end
-- Why one didn't come (for the debug report).
function LC.VortHomeWhy()
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
    if cvVorts:GetInt() <= 0 then return "lc_rebel_vorts is 0" end
    if #zones == 0 then return "no rebel zones drawn" end
    return nil
end

-- Shackled vortigaunts sweeping the streets (the owner: "at least 1 being a street sweep slave"):
-- Combine property, collared, harming nobody and harmed by nobody, moving to a new stretch of
-- street now and then. They come in out of sight.
-- (The owner, 7 November:) they really sweep now: a push broom in the claws, swung as they pace a
-- short stretch back and forth; they step aside for whoever walks into them (the city's people
-- too: they stood in doorways and nobody got through); and shackled, they never zap anything:
-- a headcrab or a zombie near them, they run.
local cvSlaves = CreateConVar("lc_vort_slaves", "2", FLAGS, "Shackled vortigaunts the Combine keep sweeping the streets (Combine property: they harm nobody, and nobody harms them)")
LC.VortSlaves = LC.VortSlaves or {}
local nextSlave = 0
local BROOM_MODEL = "models/props_c17/pushbroom.mdl"
-- where the broom sits (in the right claw when the model has the attachment, on the body otherwise),
-- and how far it swings: tune here if it looks wrong in game
local BROOM = { claw = { pos = Vector(0, 0, 0), ang = Angle(50, 0, 0) }, body = { pos = Vector(16, 8, 34), ang = Angle(50, 0, 0) },
    swing = 12, tilt = 7, rate = 2.4 }
local SLAVE_MONSTERS = { "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_headcrab_poison",
    "npc_zombie", "npc_zombie_torso", "npc_fastzombie", "npc_fastzombie_torso", "npc_poisonzombie", "npc_zombine" }

-- The collar: no vortessence. The engine's vortigaunt zaps whatever it hates (it killed a headcrab, the
-- owner saw): its attacks are taken away, and the infested are something to run from, not fight.
local function Harmless(v)
    if v.CapabilitiesRemove then
        v:CapabilitiesRemove(bit.bor(CAP_INNATE_RANGE_ATTACK1 or 8192, CAP_INNATE_RANGE_ATTACK2 or 16384,
            CAP_INNATE_MELEE_ATTACK1 or 2048, CAP_INNATE_MELEE_ATTACK2 or 4096))
    end
    for _, cls in ipairs(SLAVE_MONSTERS) do v:AddRelationship(cls .. " D_FR 99") end
end

local function Broom(v, s)
    if IsValid(s.broom) then return s.broom end
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(BROOM_MODEL)
    e:SetPos(v:GetPos() + Vector(0, 0, 40))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_NONE) end
    local att = v.LookupAttachment and v:LookupAttachment("rightclaw") or 0
    local fit = (att and att > 0) and BROOM.claw or BROOM.body
    if att and att > 0 then e:SetParent(v, att) else e:SetParent(v) end
    if e.SetLocalPos then e:SetLocalPos(fit.pos) end
    if e.SetLocalAngles then e:SetLocalAngles(fit.ang) end
    s.broom, s.fit = e, fit
    v.lcBroom = e
    if v.DeleteOnRemove then v:DeleteOnRemove(e) end
    return e
end

-- The swing: the broom pushed out and back along the ground, the vortigaunt's arms being the
-- engine's (no sweeping animation of its own that can be counted on).
local function Swing(v, s, now)
    local e = s.broom
    if not IsValid(e) or not e.SetLocalPos then return end
    local fit = s.fit or BROOM.body
    local k = math.sin(now * BROOM.rate)
    e:SetLocalPos(fit.pos + Vector(k * BROOM.swing, 0, 0))
    e:SetLocalAngles(Angle(fit.ang.p + k * BROOM.tilt, fit.ang.y, fit.ang.r))
end

-- Walked into (a player, or one of the city's people wedged against it): a shuffle to whichever
-- side is open, then a few steps clear, as the city's people do (sv_livingcity.lua, "Out of the way").
local function StepAside(v, s, other, now)
    local vp = v:GetPos()
    local dir = vp - other:GetPos()
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = v:GetForward() end
    dir:Normalize()
    local side = Vector(-dir.y, dir.x, 0)
    local to
    for _, sd in ipairs({ side, -side }) do
        local p = vp + sd * 60 + dir * 20
        local tr = util.TraceHull({ start = vp + Vector(0, 0, 8), endpos = p + Vector(0, 0, 8),
            mins = Vector(-14, -14, 0), maxs = Vector(14, 14, 60), filter = { v, other }, mask = MASK_NPCSOLID })
        if tr and not tr.Hit then to = p break end
    end
    s.asideAt = now + 2
    if not to then return false end
    v:SetPos(vp + (to - vp):GetNormalized() * 16) -- (a shuffle at once)
    if v.SetLastPosition and v.SetSchedule then
        v:SetLastPosition(to)
        v:SetSchedule(SCHED_FORCED_GO)
    end
    s.paceAt = now + 5 -- (not straight back into them)
    return true
end

local function SlaveMakeWay(now)
    for v, s in pairs(LC.VortSlaves) do
        if IsValid(v) and v:Health() > 0 and (s.asideAt or 0) < now then
            local vp = v:GetPos()
            local wedged
            for _, e in ipairs(ents.FindInSphere(vp, 48)) do
                if e ~= v and IsValid(e) and ((e:IsPlayer() and e:Alive()) or (e:IsNPC() and e:Health() > 0 and not e.lcVortSlave)) then
                    local toward = vp - e:GetPos()
                    toward.z = 0
                    local vel = e:GetVelocity()
                    vel.z = 0
                    if vel:LengthSqr() > 30 * 30 and toward:LengthSqr() > 1 and vel:GetNormalized():Dot(toward:GetNormalized()) > 0.3 then
                        StepAside(v, s, e, now)
                        s.wedged = nil
                        break
                    elseif e:IsNPC() and toward:LengthSqr() < 40 * 40 then
                        wedged = e
                    end
                end
            end
            if wedged then
                -- one of the city's people standing against it a moment (stuck behind it in a doorway): make way
                s.wedged = (s.wedged or 0) + 1
                if s.wedged >= 4 then s.wedged = nil StepAside(v, s, wedged, now) end
            else
                s.wedged = nil
            end
        end
    end
end
LC.VortSlaveMakeWay = SlaveMakeWay -- (for tests)

local swingTick = 0
timer.Create("LivingCityVortSweep", 0.1, 0, function()
    if next(LC.VortSlaves) == nil then return end
    local now = CurTime()
    local ok, err = pcall(function()
        for v, s in pairs(LC.VortSlaves) do if IsValid(v) and (s.fleeUntil or 0) < now then Swing(v, s, now) end end
        swingTick = swingTick + 1
        if swingTick % 3 == 0 then SlaveMakeWay(now) end
    end)
    if not ok and LC.Error then LC.Error("vortigaunt sweeping", err) end
end)

-- The infested near: run (not walk), away from them, as the citizens do.
local function Flee(v, s, now)
    local vp = v:GetPos()
    local threat
    for _, e in ipairs(ents.FindInSphere(vp, 400)) do
        if e ~= v and IsValid(e) and LC.IsMonster and LC.IsMonster(e) and (not e.Health or e:Health() > 0) then threat = e break end
    end
    if not threat then return false end
    local away = vp - threat:GetPos()
    away.z = 0
    if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
    away:Normalize()
    local dest
    for _ = 1, 8 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("citizen", vp + away * 700)
        if p and (p - vp):GetNormalized():Dot(away) > 0.2 then dest = p break end
    end
    dest = dest or (vp + away * 400)
    if v.SetLastPosition then
        v:SetLastPosition(dest)
        v:SetSchedule(SCHED_FORCED_GO_RUN)
    end
    s.fleeUntil = now + 6
    s.next = math.max(s.next or 0, now + 12)
    s.paceAt = now + 8
    return true
end
LC.VortSlaveFlee = Flee -- (for tests)

local function SlaveTick(now)
    if not LC.Running then return end
    local have = 0
    for v, s in pairs(LC.VortSlaves) do
        if not IsValid(v) or v:Health() <= 0 then
            if s and IsValid(s.broom) then s.broom:Remove() end
            LC.VortSlaves[v] = nil
        else
            have = have + 1
            -- (the owner, 1 November: they walked at the Combine and were shot) Combine property: the units
            -- and the vortigaunt leave each other be, and it bothers nobody
            for npc, st in pairs(LC.NPCs or {}) do
                if IsValid(npc) and npc ~= v and not (s.calm and s.calm[npc]) and npc.AddEntityRelationship then
                    s.calm = s.calm or setmetatable({}, { __mode = "k" })
                    s.calm[npc] = true
                    npc:AddEntityRelationship(v, D_NU, 99)
                    v:AddEntityRelationship(npc, D_NU, 99)
                end
            end
            for _, p in ipairs(player.GetAll()) do v:AddEntityRelationship(p, D_NU, 99) end
            if not s.harmless then s.harmless = true Harmless(v) end
            Broom(v, s)
            local fleeing = (s.fleeUntil or 0) > now or Flee(v, s, now)
            local walking = v.IsCurrentSchedule and (v:IsCurrentSchedule(SCHED_FORCED_GO) or v:IsCurrentSchedule(SCHED_FORCED_GO_RUN))
            if not fleeing then
                -- standing still: sweeping, as in Half-Life 2's first streets (the model's own animation, when it has one)
                if not walking and now > (s.sweepAt or 0) and LC.PlayGesture then
                    s.sweepAt = now + 8
                    LC.PlayGesture(v, { "sweep", "Sweep", "sweep_idle", "Sweep_idle", "broom", "sweeping" }, 8)
                end
                -- pacing the stretch: a few steps forward with the broom, then back, while the broom swings
                if now > (s.paceAt or 0) then
                    s.paceAt = now + math.Rand(5, 8)
                    s.paceDir = -(s.paceDir or -1)
                    local vp = v:GetPos()
                    local to = vp + v:GetForward() * (70 * s.paceDir)
                    local tr = util.TraceHull({ start = vp + Vector(0, 0, 8), endpos = to + Vector(0, 0, 8),
                        mins = Vector(-14, -14, 0), maxs = Vector(14, 14, 60), filter = v, mask = MASK_NPCSOLID })
                    if tr and not tr.Hit and v.SetLastPosition then
                        v:SetLastPosition(to)
                        v:SetSchedule(SCHED_FORCED_GO)
                    end
                end
                if now > (s.next or 0) then
                    s.next = now + math.Rand(25, 50)
                    -- a new stretch of street: open ground, not a doorway (the owner, 7 November)
                    local p
                    for _ = 1, 4 do
                        local q = LC.RandomWanderPos and LC.RandomWanderPos("citizen", v:GetPos())
                        if q and not (LC.InInfest and LC.InInfest(q)) then
                            p = q
                            if not LC.RoomAround or LC.RoomAround(q) then break end
                        end
                    end
                    if p and v.SetLastPosition then
                        v:SetLastPosition(p)
                        v:SetSchedule(SCHED_FORCED_GO)
                        s.paceAt = now + 10
                    end
                end
            end
        end
    end
    if now < nextSlave or have >= cvSlaves:GetInt() then return end
    nextSlave = now + 20
    local pos = LC.RandomWanderPos and LC.RandomWanderPos("citizen")
    if not pos or (LC.InInfest and LC.InInfest(pos)) or (LC.InRebelZone and LC.InRebelZone(pos)) then return end
    if LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 50)) then return end
    local v = ents.Create("npc_vortigaunt")
    if not IsValid(v) then return end
    if not util.IsValidModel or util.IsValidModel("models/vortigaunt_slave.mdl") then v:SetModel("models/vortigaunt_slave.mdl") end
    v:SetPos(pos + Vector(0, 0, 4))
    v:Spawn()
    v:Activate()
    -- (set again after it's spawned: the engine's vortigaunt puts its own model back, and they walked about
    -- without their shackles, the owner saw; only the body had them)
    if not util.IsValidModel or util.IsValidModel("models/vortigaunt_slave.mdl") then v:SetModel("models/vortigaunt_slave.mdl") end
    if LC.QuestVortPeaceful then LC.QuestVortPeaceful(v, true) end
    Harmless(v)
    v:SetNW2Bool("lc_shackled", true)
    v:SetNW2Bool("lc_noragdoll", true) -- (dead: a body the morticians collect, sv_livingcity_bodies.lua)
    LC.SetNPCStr(v, "lc_pname", "Shackled vortigaunt")
    LC.SetNPCStr(v, "lc_doing", "sweeping the street, collared")
    v.lcVortSlave = true
    LC.VortSlaves[v] = { next = 0, harmless = true }
    Broom(v, LC.VortSlaves[v])
end
LC.VortSlaveTick = function(now) nextSlave = 0 SlaveTick(now or CurTime()) end -- (for tests)

-- Cut loose (!unshackle, sv_livingcity_vort.lua): the collar comes off, it heads for rebel ground, and
-- lives there free (charging vests on request). The Combine want it back: hunted on the way.
function LC.FreeStreetVort(v, by)
    if not IsValid(v) or not v.lcVortSlave then return false end
    local s = LC.VortSlaves[v]
    if s and IsValid(s.broom) then s.broom:Remove() end -- (the broom stays in the Combine's gutter)
    v.lcBroom = nil
    LC.VortSlaves[v] = nil
    v.lcVortSlave = nil
    v.lcVortFreed = true -- (freed from its shackles: it counts in dreams, sv_livingcity_propagandamore.lua)
    if not util.IsValidModel or util.IsValidModel("models/vortigaunt.mdl") then v:SetModel("models/vortigaunt.mdl") end
    v:SetNW2Bool("lc_shackled", false)
    LC.SetNPCStr(v, "lc_pname", "Freed vortigaunt")
    LC.SetNPCStr(v, "lc_doing", "heading for rebel ground")
    if LC.QuestVortPeaceful then LC.QuestVortPeaceful(v, false) end
    v:EmitSound("npc/vort/vort_foot" .. math.random(1, 4) .. ".wav", 70)
    if IsValid(by) then
        by:ChatPrint("[Living City] The collar falls. The vortigaunt looks at you a long moment, then heads for rebel ground.")
        if LC.AddXP then LC.AddXP(by, 30, "freeing a vortigaunt") end
    end
    Radio("resistance", "A vortigaunt has been freed from the street crews. It's on its way to us. Welcome it.")
    local zones = LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}
    local spot = #zones > 0 and LC.SpotInZone and LC.SpotInZone(zones[math.random(#zones)])
    if not spot then LC.SettleVort(v, true) return true end
    local started = CurTime()
    local function Walk()
        if not IsValid(v) or v:Health() <= 0 then return end
        if v:GetPos():DistToSqr(spot) < 200 * 200 or CurTime() - started > 120 then
            -- home (or near enough, and out of sight: it finds its own way the rest)
            if v:GetPos():DistToSqr(spot) >= 200 * 200 and not (LC.IsSeen and LC.IsSeen(v:GetPos() + Vector(0, 0, 50))) then v:SetPos(spot + Vector(0, 0, 4)) end
            LC.SetNPCStr(v, "lc_doing", "")
            LC.SettleVort(v, true)
            return
        end
        if v.SetLastPosition then v:SetLastPosition(spot) v:SetSchedule(SCHED_FORCED_GO_RUN) end
        timer.Simple(3, Walk)
    end
    Walk()
    hook.Run("LivingCityVortFreed", v, by)
    if IsValid(by) and LC.QuestEvent then LC.QuestEvent("vort_freed", by, v) end -- (the Free your kin job: sv_livingcity_vortwork.lua)
    return true
end

-- A freed vortigaunt charges your vest when you ask it (E), not by itself (not while you sleep
-- beside it): once every lc_vort_charge_minutes.
local cvVortCharge = CreateConVar("lc_vort_charge_minutes", "10", FLAGS, "Minutes before a freed vortigaunt will charge the same person's vest again (E on it)")
function LC.VortCharge(ply, v)
    if not IsValid(v) or not LC.RebelVorts[v] or not IsValid(ply) or not ply:Alive() then return false end
    if not IsResistance(ply) then return false, "The vortigaunt looks at you, and through you." end
    if not (LC.HasVest and LC.HasVest(ply)) then return false, "\"You wear no vessel for the vortessence, friend.\" (You've no powered vest on.)" end
    if ply:Armor() >= LC.VestCap(ply) then return false, "\"Your vessel is full.\" (Your vest is fully charged.)" end
    local now = CurTime()
    if (ply.lcVortChargeNext or 0) > now then
        return false, string.format("\"The vortessence needs time to gather.\" (%d min)", math.ceil((ply.lcVortChargeNext - now) / 60))
    end
    ply.lcVortChargeNext = now + cvVortCharge:GetFloat() * 60
    LC.ChargeVest(ply, 25)
    v:EmitSound("npc/vort/health_charge.wav", 65)
    return true, "The vortigaunt's hands glow green, and your vest hums with charge."
end
hook.Add("PlayerUse", "LivingCityVortCharge", function(ply, ent)
    if LC.StalkerCantSpeak and LC.StalkerCantSpeak(ply, ent) then return false end
    if not (IsValid(ent) and LC.RebelVorts[ent]) then return end
    if (ply.lcVortUse or 0) > CurTime() then return false end
    ply.lcVortUse = CurTime() + 1
    local ok, msg = LC.VortCharge(ply, ent)
    if msg then ply:ChatPrint("[Vortigaunt] " .. msg) end
    return false
end)

------------------------------------------------------------------------
-- Commands and the clock
------------------------------------------------------------------------

local function FindPlayer(name)
    name = string.lower(name or "")
    if name == "" then return nil end
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), name, 1, true) then return p end
    end
    return nil
end

hook.Add("PlayerSay", "LivingCityResistanceOps", function(ply, text)
    local cmd, rest = string.match(string.Trim(text), "^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    if cmd == "!hack" then
        local ok, why = LC.HackDoor(ply)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    elseif cmd == "!inform" then
        local target = FindPlayer(rest)
        if not target then
            local tr = ply:GetEyeTrace()
            if tr and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(ply:EyePos()) < 600 * 600 then target = tr.Entity end
        end
        local ok, why = LC.Inform(ply, target)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    elseif cmd == "!hijack" then
        local tr = ply:GetEyeTrace()
        local ok, why = LC.HijackScreen(ply, tr and tr.Entity)
        if not ok and why then ply:ChatPrint(why) end
        return ""
    elseif cmd == "!foreman" then
        local _, msg = LC.BecomeForeman(ply)
        if msg then ply:ChatPrint(msg) end
        return ""
    elseif cmd == "!assign" then
        local _, msg = LC.AssignWork(ply, FindPlayer(rest))
        if msg then ply:ChatPrint(msg) end
        return ""
    end
end)

local nextOps, nextSmuggle, nextReact = 0, 0, 0
timer.Create("LivingCityResistanceOps", 1, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        OpTick(now)
        DropTick(now)
        VortTick()
        VortHome(now)
        SlaveTick(now)
        if now >= nextSmuggle then nextSmuggle = now + 5 SmugglerTick() end
        if now >= nextReact then nextReact = now + 5 React(now) end
        if nextOps == 0 then nextOps = now + 180 end -- not in the first minutes of a city
        if now > nextOps then
            nextOps = now + 60
            MaybeLaunch(now)
        end
    end)
    if not ok and LC.Error then LC.Error("resistance ops", err) end
end)
