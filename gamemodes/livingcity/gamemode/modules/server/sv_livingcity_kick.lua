--[[
    Living City: the unit's kick

    Every rank of Civil Protection (the Overwatch included) can kick: G by
    default (lc_kick_key on the client), or F2 > Kick. No weapon to switch to.

      A door that isn't locked     swings open, away from you
      A locked door                gives on the second kick (lc_kick_door_kicks);
                                   an apartment's tenants are told
      A Combine door               opens (units have the codes anyway)
      A brush door (sliding,       doesn't budge
      a shutter, a gate)
      A prison or locked-tagged    doesn't give
      door
      Someone                      knocked back, and hurt a little
      Something loose              sent flying

    Only hinged doors: a brush door (a sliding warehouse door, a Combine
    shutter, a gate) doesn't budge. The Overwatch's boots are heavier.
      Combine Soldier   the door comes off its hinges and falls over where
                        it hung
      Elite Soldier     it flies into the room, five to ten feet (never the
                        same twice), hard enough to kill whoever it hits
      Commander         further still
    lc_kick_door_power scales the flight (0: the Overwatch open doors like
    anyone). It's back on its hinges after lc_kick_door_back seconds (120).

    Everyone sees the leg come up (cl_livingcity_kick.lua): in first person
    it's your own model's leg, whatever you wear.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_kick", "1", FLAGS, "Civil Protection can kick (doors, people, props)")
local cvKicks  = CreateConVar("lc_kick_door_kicks", "2", FLAGS, "Kicks it takes to break a locked door open")
local cvDamage = CreateConVar("lc_kick_damage", "12", FLAGS, "Harm a kick does to someone")
local cvPower  = CreateConVar("lc_kick_door_power", "1", FLAGS, "How hard the Overwatch kick a door off its hinges (0: they open doors like anyone)")
local cvBack   = CreateConVar("lc_kick_door_back", "600", FLAGS, "Seconds before a door kicked off its hinges is put back by itself (if no Maintenance Technician has rehung it)")
local cvRehangPay = CreateConVar("lc_rehang_pay", "10", FLAGS, "Credits a Maintenance Technician is paid for rehanging a kicked-in door")

local REACH = 72
local BREAK_DAMAGE = 30 -- (a crowbar does 25)
local HIT_AT = 0.25 -- (seconds into the kick that the foot lands)
local EVERY = 1.1

local SWING = "npc/fast_zombie/claw_miss1.wav"
local THUD = { "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav" }
local DOOR_HIT = { "physics/wood/wood_panel_impact_hard1.wav", "physics/wood/wood_box_impact_hard3.wav" }
local DOOR_BREAK = "physics/wood/wood_crate_break3.wav"

local function Pick(t) return t[math.random(#t)] end

function LC.CanKick(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:Alive() then return false end
    if ply.InVehicle and ply:InVehicle() then return false end
    if LC.Prisoners and LC.Prisoners[ply] then return false end
    if ply:GetNW2Bool("lc_tied", false) or ply:GetNW2Bool("lc_sleeping", false) then return false end
    return LC.PlayerIsCP ~= nil and LC.PlayerIsCP(ply) and ply:GetNW2String("lcf_faction", "") == "cp"
end

-- How hard this unit kicks a door off its hinges: 0 for anyone below Combine
-- Soldier; 1 the Soldier (it falls over), 2 the Elite (it flies), 3 the Commander.
function LC.KickPower(ply)
    if not (LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply)) or cvPower:GetFloat() <= 0 then return 0 end
    if ply:GetNW2String("lcf_special", "") == "ow_commander" then return 3 end
    local rank = ply:GetNW2Int("lcf_rank", 1)
    if rank >= 6 then return 2 end
    if rank >= 5 then return 1 end
    return 0
end

-- How far a door flies (units): the Elite five to ten feet, the Commander
-- eight to fourteen; a Soldier's just falls (0).
local FEET = 12
function LC.DoorFlight(power)
    local m = cvPower:GetFloat()
    if power >= 3 then return math.Rand(8 * FEET, 14 * FEET) * m end
    if power >= 2 then return math.Rand(5 * FEET, 10 * FEET) * m end
    return 0
end

LC.BlownDoors = LC.BlownDoors or {} -- [door] = the flying prop

------------------------------------------------------------------------
-- Knocked out (a door that hits you): out cold for a while, then the
-- world swims. Never a death, never a close call.
------------------------------------------------------------------------

local KO_SECS = 15
function LC.KnockOut(ent, secs, dizzy)
    if not IsValid(ent) then return false end
    local now = CurTime()
    if ent:IsPlayer() then
        if not ent:Alive() then return false end
        if secs > 0 then
            ent:SetNW2Float("lc_ko_until", now + secs)
            if ent.Freeze then ent:Freeze(true) end
            timer.Simple(secs, function() if IsValid(ent) and ent.Freeze then ent:Freeze(false) end end)
            ent:EmitSound("physics/body/body_medium_impact_hard4.wav", 75)
        end
        ent:SetNW2Float("lc_dizzy_from", now + secs)
        ent:SetNW2Float("lc_dizzy_until", now + secs + (dizzy or 0))
        if LC.Notice then
            LC.Notice(ent, "bad", secs > 0 and "Out cold" or "Knocked senseless",
                secs > 0 and "A door, out of nowhere. Everything goes black." or "The door catches you on its way down. The room won't keep still.", 6)
        end
        return true
    end
    local st = LC.NPCs and LC.NPCs[ent]
    if st and secs > 0 and LC.SetState then
        LC.SetState(ent, st, "event")
        st.eventUntil = now + secs
        if ent.SetSchedule then ent:SetSchedule(SCHED_IDLE_STAND) end
        if LC.PlayGesture then LC.PlayGesture(ent, { "ACT_FLINCH_PHYSICS", "ACT_BIG_FLINCH" }, 1) end
    end
    return true
end

hook.Add("PlayerDeath", "LivingCityKnockOut", function(ply)
    ply:SetNW2Float("lc_ko_until", 0)
    if ply.Freeze then ply:Freeze(false) end
end)

-- Back on its hinges, as it was.
function LC.RehangDoor(door)
    local prop = LC.BlownDoors[door]
    LC.BlownDoors[door] = nil
    for c, p in pairs(LC.DoorCarriers or {}) do if p == prop then LC.DropDoor(c, true) end end
    if IsValid(prop) then prop:Remove() end
    if not IsValid(door) then return end
    door:SetNoDraw(false)
    door:SetNotSolid(false)
    door.lcBlown = nil
    door:Fire("Close")
    if LC.ApplyDoorState then timer.Simple(0.5, function() if IsValid(door) then LC.ApplyDoorState(door) end end) end
end

-- Off its hinges: the door stays where it was, open and unseen (so the room
-- behind it isn't cut off from view), and a copy of it flies in. What it hits
-- at speed is hurt, more the harder it was kicked.
function LC.BlowDoor(ply, door, power, dir)
    if door.lcBlown then return nil end
    local prop = ents.Create("prop_physics")
    if not IsValid(prop) then return nil end
    prop:SetModel(door:GetModel())
    prop:SetPos(door:GetPos())
    prop:SetAngles(door:GetAngles())
    prop:SetSkin(door:GetSkin() or 0)
    prop:Spawn()
    prop.lcKickedDoor = door
    door.lcBlown = true
    door.lcBlownAt = CurTime()
    door:Fire("Unlock")
    door:Fire("Open")
    door:SetNoDraw(true)
    door:SetNotSolid(true)
    LC.BlownDoors[door] = prop
    if prop.SetPhysicsAttacker then prop:SetPhysicsAttacker(ply, 10) end
    local flight = LC.DoorFlight(power)
    prop.lcFlight = flight
    local phys = prop:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        if flight > 0 then
            -- a low arc into the room (about half a second in the air), turning over as it goes
            phys:SetVelocity(dir * flight * 2.2 + Vector(0, 0, 150))
            phys:AddAngleVelocity(VectorRand() * 160)
        else
            -- off its hinges: the top goes over, the bottom stays about where it was
            phys:SetVelocity(dir * 30)
            phys:ApplyForceOffset(dir * phys:GetMass() * 180, prop:WorldSpaceCenter() + Vector(0, 0, 40))
        end
    end
    local untilT = CurTime() + 2
    local hit = {}
    if prop.AddCallback then
        prop:AddCallback("PhysicsCollide", function(_, data)
            local victim = data.HitEntity
            if CurTime() > untilT or not IsValid(victim) or hit[victim] or victim == ply then return end
            if not (victim:IsPlayer() or victim:IsNPC()) then return end
            if (data.Speed or 0) < 60 then return end
            hit[victim] = true
            -- it knocks them out (a flying door) or senseless (a falling one); it never kills
            timer.Simple(0, function() if IsValid(victim) then LC.KnockOut(victim, flight > 0 and KO_SECS or 0, flight > 0 and 25 or 10) end end)
        end)
    end
    door:EmitSound(DOOR_BREAK, 90)
    door:EmitSound("physics/wood/wood_furniture_break2.wav", 85)
    if util.Effect and EffectData then
        local fx = EffectData()
        fx:SetOrigin(door:WorldSpaceCenter())
        fx:SetScale(2)
        util.Effect("ThumperDust", fx)
    end
    timer.Simple(math.max(5, cvBack:GetFloat()), function() LC.RehangDoor(door) end)
    hook.Run("LivingCityDoorKicked", ply, door)
    return prop
end

-- What a kick does to a door. True if it did something.
function LC.KickDoor(ply, door)
    -- a brush door (a sliding warehouse door, a Combine shutter, a gate) is
    -- too big and too heavy: a boot does nothing to it
    if door:GetClass() ~= "prop_door_rotating" then
        door:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 75)
        ply:ChatPrint("It doesn't budge.")
        return false
    end
    local tag = LC.GetDoorTag and LC.GetDoorTag(door)
    local auto = not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) or nil
    door:EmitSound(Pick(DOOR_HIT), 80)
    if tag == "prison" or auto == "prison" or tag == "locked" or tag == "open" then
        ply:ChatPrint("It doesn't give.")
        return false
    end
    if door.lcBlown then return false end
    -- the Overwatch take a hinged door off its hinges
    local power = not (tag == "cp" or auto == "cp") and LC.KickPower(ply) or 0
    local dir = ply:GetAimVector()
    dir.z = 0
    dir:Normalize()
    if power > 0 then
        local rental = LC.RentalOf and LC.RentalOf(door)
        if LC.BlowDoor(ply, door, power, dir) then
            if rental and rental.locked and LC.HasRentKey then
                for _, p in ipairs(player.GetAll()) do
                    if LC.HasRentKey(p, rental) then p:ChatPrint("[Living City] The Overwatch kicked the door of " .. (rental.ownerName or "the") .. "'s apartment off its hinges.") end
                end
            end
            return true
        end
    end
    local function Burst(relock)
        door:Fire("Unlock")
        -- kicked, not opened: it bangs open fast, then swings at its own pace again
        local kv = door.GetKeyValues and door:GetKeyValues() or {}
        local was = tonumber(kv.speed)
        door:SetKeyValue("speed", tostring(math.max(500, (was or 100) * 5)))
        timer.Simple(1.2, function() if IsValid(door) then door:SetKeyValue("speed", tostring(was or 100)) end end)
        if door:GetClass() == "prop_door_rotating" then door:Fire("OpenAwayFrom", "!activator", 0.05, ply, ply) else door:Fire("Open", "", 0.05) end
        if LC.OpenedDoors then LC.OpenedDoors[door] = CurTime() + 8 end
        if relock and LC.Relock then LC.Relock[door] = true end
    end
    local locked = door.GetInternalVariable and door:GetInternalVariable("m_bLocked") == true
    local rental = LC.RentalOf and LC.RentalOf(door)
    if rental and rental.locked then locked = true end
    if tag == "cp" or auto == "cp" or not locked then
        Burst(locked)
        return true
    end
    -- locked: it takes a few
    local now = CurTime()
    if (door.lcKickedAt or 0) < now - 20 then door.lcKicks = 0 end
    door.lcKicks = (door.lcKicks or 0) + 1
    door.lcKickedAt = now
    if door.lcKicks < math.max(1, cvKicks:GetInt()) then return true end
    door.lcKicks = 0
    door:EmitSound(DOOR_BREAK, 85)
    Burst(true)
    if rental and rental.locked then
        for _, p in ipairs(player.GetAll()) do
            if LC.HasRentKey and LC.HasRentKey(p, rental) then
                p:ChatPrint("[Living City] Civil Protection kicked in the door of " .. (rental.ownerName or "the") .. "'s apartment.")
            end
        end
    end
    hook.Run("LivingCityDoorKicked", ply, door)
    return true
end

-- The foot lands: whatever's in front of you.
function LC.KickLand(ply)
    if not IsValid(ply) or not ply:Alive() then return nil end
    local from = ply:GetShootPos() - Vector(0, 0, 24)
    local dir = ply:GetAimVector()
    dir.z = math.Clamp(dir.z, -0.3, 0.3)
    dir:Normalize()
    local tr = util.TraceHull({ start = from, endpos = from + dir * REACH, filter = ply,
        mins = Vector(-8, -8, -8), maxs = Vector(8, 8, 8), mask = MASK_SHOT_HULL })
    local ent = tr.Entity
    if not tr.Hit or not IsValid(ent) then
        if tr.Hit then ply:EmitSound(Pick(DOOR_HIT), 70) end
        return nil
    end
    if LC.IsDoorEntity and LC.IsDoorEntity(ent) then
        LC.KickDoor(ply, ent)
        return "door"
    end
    if ent:IsPlayer() or ent:IsNPC() then
        ent:EmitSound(Pick(THUD), 75)
        local push = dir * 320 + Vector(0, 0, 120)
        if ent:IsPlayer() then ent:SetVelocity(push) elseif ent.SetVelocity then ent:SetVelocity(push) end
        local d = DamageInfo and DamageInfo()
        if d then
            d:SetDamage(cvDamage:GetFloat())
            d:SetDamageType(DMG_CLUB)
            d:SetAttacker(ply)
            d:SetInflictor(ply)
            d:SetDamageForce(dir * 4000)
            ent:TakeDamageInfo(d)
        else
            ent:TakeDamage(cvDamage:GetFloat(), ply, ply)
        end
        if ent:IsPlayer() then ent:ViewPunch(Angle(-8, math.random(-6, 6), 0)) end
        hook.Run("LivingCityKicked", ply, ent)
        return "person"
    end
    -- a boot is as good as a crowbar: crates, planks, anything breakable breaks
    if not ent.lcKickedDoor then
        local d = DamageInfo and ent.TakeDamageInfo and DamageInfo()
        if d then
            d:SetDamage(BREAK_DAMAGE)
            d:SetDamageType(DMG_CLUB)
            d:SetAttacker(ply)
            d:SetInflictor(ply)
            d:SetDamagePosition(tr.HitPos)
            d:SetDamageForce(dir * 3000)
            ent:TakeDamageInfo(d)
        elseif ent.TakeDamage then
            ent:TakeDamage(BREAK_DAMAGE, ply, ply)
        end
    end
    if not IsValid(ent) then return "prop" end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) and phys:IsMoveable() then
        phys:ApplyForceOffset(dir * math.min(phys:GetMass(), 200) * 450, tr.HitPos)
        ent:EmitSound(Pick(DOOR_HIT), 70)
        return "prop"
    end
    ent:EmitSound(Pick(DOOR_HIT), 70)
    return "wall"
end

-- A kick: the leg comes up now, the foot lands a moment later.
function LC.Kick(ply)
    if not LC.CanKick(ply) then return false end
    local now = CurTime()
    if (ply.lcKickNext or 0) > now then return false end
    ply.lcKickNext = now + EVERY
    ply:SetNW2Float("lc_kick_at", now)
    ply:EmitSound(SWING, 65, math.random(90, 105))
    ply:ViewPunch(Angle(-3, 0, 0))
    timer.Simple(HIT_AT, function() if IsValid(ply) and ply:Alive() then LC.KickLand(ply) end end)
    return true
end

LC.SlashCommands = LC.SlashCommands or {}
LC.SlashCommands.kick = function(ply)
    if not LC.CanKick(ply) and IsValid(ply) and cvOn:GetBool() then ply:ChatPrint("Only Civil Protection kick doors in.") return end
    LC.Kick(ply)
end

concommand.Add("lc_kick", function(ply) if IsValid(ply) then LC.Kick(ply) end end)

------------------------------------------------------------------------
-- Rehanging a door: a Maintenance Technician (a player, or one of the
-- city's own crews) lifts the fallen door, carries it back to its frame
-- and hangs it again. E on the door to lift it; at the frame, E again.
------------------------------------------------------------------------

LC.DoorCarriers = LC.DoorCarriers or {} -- [carrier] = the fallen door

local function Technician(ply) return LC.Job ~= nil and LC.Job(ply) ~= nil and LC.Job(ply).id == "maintenance" end

function LC.DropDoor(carrier, quiet)
    local prop = LC.DoorCarriers[carrier]
    LC.DoorCarriers[carrier] = nil
    if IsValid(prop) and prop.SetCollisionGroup then prop:SetCollisionGroup(COLLISION_GROUP_NONE) end
    if IsValid(carrier) and carrier:IsPlayer() then
        carrier:SetNW2Entity("lc_carry_door", NULL)
        if not quiet then carrier:ChatPrint("You set the door down.") end
    end
end

-- Is this fallen door at its frame?
function LC.DoorAtFrame(prop)
    local door = IsValid(prop) and prop.lcKickedDoor
    return IsValid(door) and prop:GetPos():DistToSqr(door:GetPos()) < 110 * 110
end

-- Hung: back on its hinges, and the technician is paid.
function LC.DoorRehung(prop, by)
    local door = IsValid(prop) and prop.lcKickedDoor
    if not IsValid(door) then return false end
    door:EmitSound("doors/door_metal_thin_close2.wav", 70)
    LC.RehangDoor(door)
    if IsValid(by) and by:IsPlayer() then
        local pay = cvRehangPay:GetInt()
        if pay > 0 and LC.AddCredits then LC.AddCredits(by, pay, "door rehung") end
        if LC.Notice then LC.Notice(by, "info", "Door rehung", "Back on its hinges." .. (pay > 0 and string.format(" %d credits.", pay) or ""), 5) end
    end
    return true
end

-- E on a fallen door.
function LC.UseFallenDoor(ply, prop)
    if not IsValid(prop) or not IsValid(prop.lcKickedDoor) then return false end
    if (ply.lcDoorUseNext or 0) > CurTime() then return true end
    ply.lcDoorUseNext = CurTime() + 0.6
    if not Technician(ply) then return false, "Off its hinges. A Maintenance Technician could hang it back up." end
    if LC.DoorCarriers[ply] == prop then
        if not LC.DoorAtFrame(prop) then LC.DropDoor(ply) return true end
        LC.DropDoor(ply, true)
        if not LC.StartTask then return LC.DoorRehung(prop, ply) end
        return LC.StartTask(ply, 8, "Rehanging the door...", {
            maxMove = 60, cancelText = "You leave it leaning against the frame.",
            done = function(p) LC.DoorRehung(prop, p) end,
        })
    end
    for c, p in pairs(LC.DoorCarriers) do if p == prop and IsValid(c) then return false, "Someone already has hold of it." end end
    if LC.DoorAtFrame(prop) then -- (already by the frame: straight to hanging it)
        LC.DoorCarriers[ply] = prop
        return LC.UseFallenDoor(ply, prop)
    end
    LC.DoorCarriers[ply] = prop
    ply:SetNW2Entity("lc_carry_door", prop)
    if prop.SetCollisionGroup then prop:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
    if LC.SetWaypoint then LC.SetWaypoint(ply, prop.lcKickedDoor:GetPos(), "The door frame", 90) end
    if LC.Notice then LC.Notice(ply, "info", "A door to rehang", "Carry it back to the frame it came off (marked), and press E on it there.", 6) end
    return true
end

hook.Add("PlayerUse", "LivingCityFallenDoor", function(ply, ent)
    if IsValid(ent) and ent.lcKickedDoor then
        local ok, why = LC.UseFallenDoor(ply, ent)
        if not ok and why then ply:ChatPrint(why) end
        return false
    end
end)

-- carried: it comes along in front of you, held upright
hook.Add("Think", "LivingCityCarryDoor", function()
    if next(LC.DoorCarriers) == nil then return end
    for c, prop in pairs(LC.DoorCarriers) do
        local alive = IsValid(c) and (c:IsPlayer() and c:Alive() or (not c:IsPlayer() and c:Health() > 0))
        if not alive or not IsValid(prop) or c:GetPos():DistToSqr(prop:GetPos()) > 300 * 300 then
            LC.DropDoor(c, true)
        else
            local phys = prop:GetPhysicsObject()
            if IsValid(phys) then
                local yaw = c:IsPlayer() and c:EyeAngles().y or c:GetAngles().y
                local target = c:GetPos() + Angle(0, yaw, 0):Forward() * 46 + Vector(0, 0, 8)
                local v = (target - prop:GetPos()) * 6
                if v:Length() > 400 then v = v:GetNormalized() * 400 end
                phys:Wake()
                phys:SetVelocity(v)
                phys:SetAngles(Angle(0, yaw + 90, 0))
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityCarryDoor", function(ply) LC.DropDoor(ply, true) end)

-- The city's own crews rehang a door nobody else has (after the players have had their chance).
if LC.AddNPCTask then
    LC.AddNPCTask("maintenance", { id = "door", label = "rehanging a door", find = function(npc, st, now)
        local grace = LC.NPCWorkGrace and LC.NPCWorkGrace("maintenance") or 60
        local best, bd
        for door, prop in pairs(LC.BlownDoors) do
            local free = true
            for _, p in pairs(LC.DoorCarriers) do if p == prop then free = false end end
            if free and IsValid(door) and IsValid(prop) and now - (door.lcBlownAt or now) >= grace
                and not (LC.NPCWorkClaimed and LC.NPCWorkClaimed("door" .. door:EntIndex())) then
                local d = prop:GetPos():DistToSqr(npc:GetPos())
                if d < 5000 * 5000 and (not bd or d < bd) then best, bd = door, d end
            end
        end
        if not best then return nil end
        local door, prop = best, LC.BlownDoors[best]
        local function Still() return IsValid(door) and LC.BlownDoors[door] == prop and IsValid(prop) end
        return { key = "door" .. door:EntIndex(), steps = {
            { pos = function(n) return LC.NPCWorkBeside(prop:GetPos(), n:GetPos(), 50) end, face = function() return prop:WorldSpaceCenter() end,
              check = Still, secs = 3, anim = { "ACT_PICKUP_GROUND", "ACT_PICKUP_RACK" }, doing = "lifting a door",
              done = function(n) if Still() then LC.DoorCarriers[n] = prop if prop.SetCollisionGroup then prop:SetCollisionGroup(COLLISION_GROUP_WEAPON) end end end },
            { pos = function(n) return LC.NPCWorkBeside(door:GetPos(), n:GetPos(), 60) end, face = function() return door:WorldSpaceCenter() end,
              check = Still, secs = 8, anim = { "ACT_PICKUP_RACK" },
              sound = { "physics/wood/wood_box_impact_soft1.wav", "physics/metal/metal_solid_impact_soft1.wav" }, doing = "rehanging a door",
              done = function() LC.DoorRehung(prop, nil) end },
        }, onEnd = function(n) if LC.DoorCarriers[n] then LC.DropDoor(n, true) end end }
    end })
end

-- every door back on its hinges when the city stops
hook.Add("LivingCityStopped", "LivingCityKick", function()
    for door in pairs(LC.BlownDoors) do LC.RehangDoor(door) end
end)

------------------------------------------------------------------------
-- A reminder (the owner, 2 November): a unit facing a locked door a kick would open, close up, is told on
-- screen how to kick it (cl_livingcity_kick.lua names their own keys).
------------------------------------------------------------------------

function LC.KickWouldOpen(door)
    if not IsValid(door) or door:GetClass() ~= "prop_door_rotating" or door.lcBlown then return false end
    if not (door.GetInternalVariable and door:GetInternalVariable("m_bLocked") == true) then return false end
    local tag = LC.GetDoorTag and LC.GetDoorTag(door)
    local auto = not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) or nil
    return not (tag == "prison" or auto == "prison" or tag == "locked" or tag == "open" or tag == "office")
end
timer.Create("LivingCityKickHint", 0.3, 0, function()
    if not cvOn:GetBool() then return end
    for _, p in ipairs(player.GetAll()) do
        local door = NULL
        if LC.CanKick(p) then
            local tr = p:GetEyeTrace()
            local e = tr and tr.Entity
            if IsValid(e) and tr.HitPos:DistToSqr(p:EyePos()) < 100 * 100 and LC.KickWouldOpen(e) then door = e end
        end
        if p:GetNW2Entity("lc_kick_hint") ~= door then p:SetNW2Entity("lc_kick_hint", door) end
    end
end)
