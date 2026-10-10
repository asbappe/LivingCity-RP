--[[
    Living City: the unit's kick

    Every rank of Civil Protection (the Overwatch included) can kick: G by
    default (lc_kick_key on the client), or F1 > Kick. No weapon to switch to.

      A door that isn't locked     swings open, away from you
      A locked door                gives on the second kick (lc_kick_door_kicks);
                                   an apartment's tenants are told
      A Combine door               opens (units have the codes anyway)
      A prison or locked-tagged    doesn't give
      door
      Someone                      knocked back, and hurt a little
      Something loose              sent flying

    Everyone sees the leg come up (cl_livingcity_kick.lua): in first person
    it's your own model's leg, whatever you wear.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_kick", "1", FLAGS, "Civil Protection can kick (doors, people, props)")
local cvKicks  = CreateConVar("lc_kick_door_kicks", "2", FLAGS, "Kicks it takes to break a locked door open")
local cvDamage = CreateConVar("lc_kick_damage", "12", FLAGS, "Harm a kick does to someone")

local REACH = 72
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

-- What a kick does to a door. True if it did something.
function LC.KickDoor(ply, door)
    local tag = LC.GetDoorTag and LC.GetDoorTag(door)
    local auto = not tag and LC.AutoDoorTag and LC.AutoDoorTag(door) or nil
    door:EmitSound(Pick(DOOR_HIT), 80)
    if tag == "prison" or auto == "prison" or tag == "locked" or tag == "open" then
        ply:ChatPrint("It doesn't give.")
        return false
    end
    local function Burst(relock)
        door:Fire("Unlock")
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
