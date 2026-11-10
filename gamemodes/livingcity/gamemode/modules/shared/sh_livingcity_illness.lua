--[[
    Living City (shared): what a fever does to how you move (sv_livingcity_illness.lua)

      A fever           no running (walking pace at most), and fists are no use:
                        you're too weak to throw a punch.
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
