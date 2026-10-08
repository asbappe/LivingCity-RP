--[[
    Living City: acts (server). See sh_livingcity_acts.lua for the list.
]]

if CLIENT then return end

LC = LC or {}
LC.SlashCommands = LC.SlashCommands or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvActs = CreateConVar("lc_acts", "1", FLAGS, "Poses and gestures: /sit, /kneel, /lie, /lean, /wave and the rest")

local function StandEye(ply) return LC.StandEye and LC.StandEye(ply) or Vector(0, 0, 64) end -- (lc_eye_height: sv_livingcity_life.lua)

function LC.StopAct(ply, quiet)
    if ply:GetNW2String("lc_act", "") == "" then return false end
    ply:SetNW2String("lc_act", "")
    if ply.lcActEye then ply:SetViewOffset(StandEye(ply)) ply.lcActEye = nil end
    return true
end

function LC.StartAct(ply, name)
    if not cvActs:GetBool() then return false, "Acts are off on this server." end
    local p = LCA.Poses[name]
    if not p then return false, "No such pose." end
    if not ply:Alive() then return false end
    if LC.IsTied and LC.IsTied(ply) then return false, "Not with your hands tied." end
    if LC.IsDowned and LC.IsDowned(ply) then return false end
    if not ply:IsOnGround() then return false, "Get your feet on the ground first." end
    if ply:GetVelocity():Length2DSqr() > 30 * 30 then return false, "Stand still first." end
    if ply:GetNW2String("lc_act", "") == name then LC.StopAct(ply) return true end
    ply:SetNW2String("lc_act", name)
    ply:SetNW2Float("lc_act_at", CurTime())
    if p.eye then
        ply:SetViewOffset(Vector(0, 0, p.eye))
        ply.lcActEye = true
    elseif ply.lcActEye then
        ply:SetViewOffset(StandEye(ply))
        ply.lcActEye = nil
    end
    if ply:HasWeapon("weapon_lc_hands") then ply:SelectWeapon("weapon_lc_hands") end
    if not LCA.Resolve(ply, name) then
        ply:ChatPrint("(This model has no animation for that, but you hold still.)")
    end
    return true
end

function LC.Gesture(ply, name)
    if not cvActs:GetBool() then return false end
    local g = LCA.Gestures[name]
    if not g or not ply:Alive() or (LC.IsTied and LC.IsTied(ply)) then return false end
    if (ply.lcGestureNext or 0) > CurTime() then return false end
    ply.lcGestureNext = CurTime() + 1.5
    ply:ConCommand("act " .. g)
    return true
end

-- Moving off ends a pose.
local BREAK = { [IN_FORWARD or 8] = true, [IN_BACK or 16] = true, [IN_MOVELEFT or 512] = true, [IN_MOVERIGHT or 1024] = true,
    [IN_JUMP or 2] = true, [IN_ATTACK or 1] = true }
hook.Add("KeyPress", "LivingCityActs", function(ply, key)
    if BREAK[key] and ply:GetNW2String("lc_act", "") ~= "" then LC.StopAct(ply) end
end)
hook.Add("PlayerSwitchWeapon", "LivingCityActs", function(ply, old, new)
    if IsValid(new) and new:GetClass() ~= "weapon_lc_hands" then LC.StopAct(ply) end
end)
hook.Add("PlayerSpawn", "LivingCityActs", function(ply) LC.StopAct(ply) end)
hook.Add("PlayerDeath", "LivingCityActs", function(ply) LC.StopAct(ply) end)
hook.Add("LivingCityTied", "LivingCityActs", function(ply) LC.StopAct(ply) end)
hook.Add("LivingCityDowned", "LivingCityActs", function(ply) LC.StopAct(ply) end)
-- nobody stays sitting once they're pushed or carried off
timer.Create("LivingCityActs", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNW2String("lc_act", "") ~= "" and (not ply:IsOnGround() or ply:GetVelocity():Length2DSqr() > 80 * 80) then
            LC.StopAct(ply)
        end
    end
end)

local function Pose(name) return function(ply) local ok, why = LC.StartAct(ply, name) if not ok and why then ply:ChatPrint(why) end end end
for _, n in ipairs({ "sit", "kneel", "lie", "lean", "cower" }) do LC.SlashCommands[n] = Pose(n) end
LC.SlashCommands.pose = function(ply, rest)
    local n = math.Clamp(tonumber(string.match(rest or "", "%d")) or 1, 1, 4)
    Pose("pose" .. n)(ply)
end
LC.SlashCommands.stand = function(ply) LC.StopAct(ply) end
LC.SlashCommands.act = function(ply, rest)
    rest = string.lower(string.Trim(rest or ""))
    if rest == "" or rest == "stop" then LC.StopAct(ply) return end
    if LCA.Gestures[rest] then LC.Gesture(ply, rest) return end
    if LCA.Poses[rest] then Pose(rest)(ply) return end
    ply:ChatPrint("Poses: /sit /kneel /lie /lean /cower /pose 1-4 (/stand to get up). Gestures: /wave /salute /bow /nod /shake /point /beckon /halt /cheer /laugh")
end
for n in pairs(LCA.Gestures) do LC.SlashCommands[n] = function(ply) LC.Gesture(ply, n) end end

-- The same with "!", for when in-character chat is off.
hook.Add("PlayerSay", "LivingCityActsChat", function(ply, text)
    local raw = string.Trim(text or "")
    local lead = string.sub(raw, 1, 1)
    if lead ~= "!" and lead ~= "/" then return end
    if lead == "/" and LC.ICChatActive and LC.ICChatActive() then return end
    local cmd, rest = string.match(raw, "^[!/](%S+)%s*(.*)$")
    cmd = cmd and string.lower(cmd)
    if not cmd or not (LCA.Poses[cmd] or LCA.Gestures[cmd] or cmd == "pose" or cmd == "stand" or cmd == "act") then return end
    if string.match(cmd, "^pose%d$") then return end
    LC.SlashCommands[cmd](ply, rest or "")
    return ""
end)
