--[[
    Living City (shared): what a fever does to how you move (sv_livingcity_illness.lua)

      A fever           no running (walking pace at most), and fists are no use:
                        you're too weak to throw a punch. The gun in your hands
                        sways and swims (the owner, 10 November), and bullets
                        leave the barrel where it's swaying, not where you aim:
                        LC.FeverSway is the one drift both follow.
      The fever dream   at midday the fever takes you: down on the ground, unable
                        to move, jump or swing until it lets you go
                        (lc_feverdream, what the screen shows: cl_livingcity_feverdream.lua).
    Both are networked (lc_ill, lc_feverdream), so movement is predicted on the
    player's own computer as well as the server.
]]

LC = LC or {}

function LC.HasFever(ply) return IsValid(ply) and string.find(ply:GetNW2String("lc_ill", ""), "fever", 1, true) ~= nil end
function LC.InFeverDream(ply) return IsValid(ply) and ply:GetNW2Float("lc_feverdream", 0) > CurTime() end

hook.Add("SetupMove", "LivingCityFever", function(ply, mv)
    if LC.InFeverDream(ply) then
        mv:SetMaxClientSpeed(0.01)
        mv:SetForwardSpeed(0) mv:SetSideSpeed(0) mv:SetUpSpeed(0)
        return
    end
    if not LC.HasFever(ply) then return end
    local cap = ply:GetWalkSpeed() or 110
    if mv:GetMaxClientSpeed() > cap then mv:SetMaxClientSpeed(cap) end
end)

hook.Add("StartCommand", "LivingCityFever", function(ply, cmd)
    if LC.InFeverDream(ply) then
        cmd:RemoveKey(IN_JUMP) cmd:RemoveKey(IN_ATTACK) cmd:RemoveKey(IN_ATTACK2) cmd:RemoveKey(IN_SPEED) cmd:RemoveKey(IN_DUCK)
        return
    end
    if not LC.HasFever(ply) then return end
    cmd:RemoveKey(IN_SPEED)
    local w = ply:GetActiveWeapon()
    if IsValid(w) and w:GetClass() == "weapon_fists" then cmd:RemoveKey(IN_ATTACK) cmd:RemoveKey(IN_ATTACK2) end
end)

-- The fever's drift: how far off (pitch, yaw, roll in degrees) the gun points right now. The same on the
-- player's computer and the server (it's a function of the clock and who they are), so the bullets go
-- where the swaying gun on screen points.
function LC.FeverSway(ply, t)
    if not LC.HasFever(ply) then return Angle(0, 0, 0) end
    t = t or CurTime()
    local k = (IsValid(ply) and ply:EntIndex() or 1) * 1.7
    return Angle(5 * math.sin(t * 1.3 + k) + 2.5 * math.sin(t * 3.1 + k * 2),
        8 * math.sin(t * 0.9 + k * 0.5) + 3 * math.sin(t * 2.3 + k),
        10 * math.sin(t * 0.7 + k))
end

-- bullets come out where the gun is swaying, and wild besides
hook.Add("EntityFireBullets", "LivingCityFeverAim", function(ent, data)
    if not IsValid(ent) or not ent:IsPlayer() or not LC.HasFever(ent) or not data or not data.Dir then return end
    local sw = LC.FeverSway(ent)
    local a = data.Dir:Angle()
    a.p, a.y = a.p + sw.p, a.y + sw.y
    data.Dir = a:Forward()
    local sp = data.Spread or Vector(0, 0, 0)
    data.Spread = Vector(sp.x + 0.05, sp.y + 0.05, 0)
    return true
end)

-- (the gun on screen, swaying: cl_livingcity_feverdream.lua, LC_CL.FeverViewModel)
