--[[
    Living City: Combine strongholds' tripwires and turrets, as the gamemode hears them

    The owner, 21 November, approving valve-tripwire-turrets (Valve's d3_c17_10b): red laser tripwires in
    Combine strongholds (Combine pass through) wake turrets that rise from the floor and re-arm when clear;
    shutting the control rooms ends the defences. The map side is the map modules' (_dev/tools/
    map_security.py): each room has two logic_relays, lc_<room>_alarm (fired when a wire is broken) and
    lc_<room>_off (shuts the room's defences for good). On a map without them nothing here happens.

      A wire broken    every Civil Protection and Overwatch player hears it on the CP net, with where;
                       whoever broke it (a player who isn't Combine) is wanted for trespass, and the
                       units near turn on them.
      Cut the defences a Resistance job, while any room's defences are up: get to the room's control point
                       (where its _off relay stands), wire it out (the wiring game), and the turrets sink
                       for good.
]]

if CLIENT then return end

LC = LC or {}
LC.Strongholds = LC.Strongholds or { off = {} }
local S = LC.Strongholds
S.TRESPASS_SECS = 120

local function RoomOf(name, suffix)
    return isstring(name) and string.match(name, "^lc_(.+)_" .. suffix .. "$") or nil
end

-- The rooms whose defences are still up: [room] = the _off relay.
function LC.StrongholdRooms()
    local out = {}
    for _, e in ipairs(ents.FindByName("lc_*")) do
        local room = IsValid(e) and RoomOf(e:GetName(), "off")
        if room and not S.off[room] then out[room] = e end
    end
    return out
end

local function Combine(ply) return LC.PlayerIsCP and LC.PlayerIsCP(ply) end

function LC.StrongholdAlarm(room, pos, who)
    if S.off[room] then return false end
    local where = LC.DescribePlace and LC.DescribePlace(pos) or ""
    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: stronghold tripwire broken " .. where .. ". Turrets active.") end
    if IsValid(who) and who:IsPlayer() and not Combine(who) then
        if LC.ReportCrime then LC.ReportCrime(who, "Trespass in a Combine stronghold", S.TRESPASS_SECS) end
        if LC.Running and LC.MakeCopsHostile then LC.MakeCopsHostile(who, pos, 1500) end
    end
    hook.Run("LivingCityStrongholdAlarm", room, pos, who)
    return true
end

-- Shut a room's defences for good (the map's own _off relay does the rest).
function LC.StrongholdOff(room, by)
    if S.off[room] then return false end
    local relay = ents.FindByName("lc_" .. room .. "_off")[1]
    if not IsValid(relay) then return false end
    S.off[room] = true
    relay:Fire("Trigger", "", 0)
    if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: stronghold defences down " .. (LC.DescribePlace and LC.DescribePlace(relay:GetPos()) or "") .. ".") end
    hook.Run("LivingCityStrongholdOff", room, by)
    return true
end

hook.Add("AcceptInput", "LivingCityStrongholds", function(ent, input, activator, caller)
    if not IsValid(ent) or string.lower(input or "") ~= "trigger" then return end
    local name = ent.GetName and ent:GetName() or ""
    local room = RoomOf(name, "alarm")
    if room then
        local who = (IsValid(activator) and activator:IsPlayer() and activator) or (IsValid(caller) and caller:IsPlayer() and caller) or nil
        LC.Try(LC.StrongholdAlarm, room, IsValid(who) and who:GetPos() or ent:GetPos(), who)
        return
    end
    room = RoomOf(name, "off")
    if room then S.off[room] = true end -- (shut by the map itself: a stronghold's own switches)
end)
hook.Add("PostCleanupMap", "LivingCityStrongholds", function() S.off = {} end)
hook.Add("InitPostEntity", "LivingCityStrongholds", function() S.off = {} end)

-- The Resistance's job: shut a room's defences at its control point, by hand.
do
    local Q = LC.QB
    if Q and LC.QuestTemplates then
        LC.QuestTemplates[#LC.QuestTemplates + 1] = {
            id = "res_cutdefences", brings = false, factions = { resistance = true }, violent = true, squad = 4,
            available = function() return LC.Running and next(LC.StrongholdRooms()) ~= nil end,
            build = function(ply)
                local best, bd, room
                for r, relay in pairs(LC.StrongholdRooms()) do
                    local d = relay:GetPos():DistToSqr(ply:GetPos())
                    if not bd or d < bd then best, bd, room = relay, d, r end
                end
                if not best then return nil end
                local pos = best:GetPos()
                local where = Q.Place(pos, ply:GetPos())
                local go = Q.GameGo(pos, "Get to the stronghold's control point " .. where .. " (marked)", "wiring", { what = "the turret circuit", pos = pos }, 120)
                local cut = Q.GameStage("Wire out the turret circuit")
                cut.onDone = function(q) LC.StrongholdOff(room, q.owner) end
                return {
                    title = "Cut the defences " .. where, reward = 45, limit = 600, failOnArrest = true,
                    desc = "Tripwires and floor turrets guard a Combine stronghold " .. where .. ". Get to its control point and wire the turrets out for good.",
                    stages = { go, cut },
                }
            end,
        }
    end
end
