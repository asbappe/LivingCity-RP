--[[
    Living City: the actions menu (server side)

    Everything that used to be a chat command can be done from the menus: the
    quick menu (F1, cl_livingcity_quick.lua) and the full menu (C, or 9 on the
    quick menu; cl_livingcity_actions.lua). The menu
    sends the action here; it's run exactly as the chat command would be. Chat
    commands still work as a backup. A few things have their own handling: an
    informant's report, a foreman's work order, and answering an interrogation.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_action")
util.AddNetworkString("lc_hints_list")
util.AddNetworkString("lc_interrogate")
util.AddNetworkString("lc_interrogate_reply")

-- What the menu may run, and the chat command it stands for. Every chat
-- command a player can type has a place in a menu (the client smoke test
-- checks each one), so nothing depends on knowing the command.
local ALLOWED = {
    handsup = true, holster = true, surrender = true, struggle = true, stuck = true, stash = true, fish = true,
    salvage = true, donate = true, plain = true, gearup = true, recognize = true, tie = true, untie = true, drag = true,
    search = true, backup = true, ["10-20"] = true, records = true, vo = true, unshackle = true, decode = true,
    foreman = true, rent = true, pick = true, hack = true, hijack = true, request = true, r = true, ru = true,
    unlink = true, sit = true, kneel = true, lie = true, lean = true, cower = true, stand = true, socio = true, bolo = true,
    -- you
    pose = true, giveup = true, talk = true, papers = true, showpapers = true, credits = true, character = true, characters = true, chardesc = true,
    -- getting by, home, the city
    shop = true, market = true, write = true, block = true, apartment = true, lock = true, unlock = true,
    givekey = true, takekey = true, unrent = true, time = true, city = true, laws = true, broadcast = true,
    -- settings and help (each checks who's asking)
    bob = true, hints = true, ticket = true, build = true, admintools = true, staff = true, pathmap = true,
    changeclothes = true, sleep = true, -- (sv_livingcity_hygiene.lua, sv_livingcity_rest.lua)
    bodycart = true, -- (a Mortician's body cart, sv_livingcity_mortuary.lua)
    casual = true, gunsout = true, meet = true, -- (orders for a Resistance squad, sv_livingcity_rebels.lua)
    scout = true, -- (intel for the quartermaster, sv_livingcity_funding.lua)
    rationbreak = true, back = true, -- (a ration break from a shift, sv_livingcity_quests.lua)
    dropship = true, kick = true, scanner = true, ways = true, -- (the Overwatch Commander's squad, sv_livingcity_resistanceops.lua; a unit's kick, sv_livingcity_kick.lua)
}
for n in pairs(LCA and LCA.Gestures or {}) do ALLOWED[n] = true end -- (wave, salute, bow...)
LC.MenuActions = ALLOWED

function LC.RunAction(ply, cmd, rest)
    cmd = string.lower(tostring(cmd or ""))
    rest = string.sub(tostring(rest or ""), 1, 200)
    if not ALLOWED[cmd] then return false end
    if LC.SlashCommands and LC.SlashCommands[cmd] then
        local ok, err = pcall(LC.SlashCommands[cmd], ply, rest)
        if not ok and LC.Error then LC.Error("action " .. cmd, err) end
        return true
    end
    hook.Run("PlayerSay", ply, "!" .. cmd .. (rest ~= "" and (" " .. rest) or ""), false)
    return true
end

net.Receive("lc_action", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.lcActionNext or 0) > CurTime() then return end
    ply.lcActionNext = CurTime() + 0.3
    local cmd, rest, target = net.ReadString(), net.ReadString(), net.ReadEntity()
    if cmd == "inform" then
        local ok, why
        if LC.Inform then ok, why = LC.Inform(ply, target) end
        if not ok and why then ply:ChatPrint(why) end
    elseif cmd == "takemic" then
        local ok, why
        if LC.TakeMicrophone then ok, why = LC.TakeMicrophone(ply, target) end
        if not ok and why then ply:ChatPrint(why) end
    elseif cmd == "haul" then
        if ply:GetNW2Bool("lc_hauling", false) then
            if LC.StopHaul then LC.StopHaul(ply) end
        elseif LC.StartHaul then
            local ok, why = LC.StartHaul(ply, target)
            if not ok and why then ply:ChatPrint(why) end
        end
    elseif cmd == "transformer" or cmd == "sabotage" or cmd == "swipe" or cmd == "shortfield" then
        -- the power grid and forcefields (sv_livingcity_power.lua)
        if not IsValid(target) or target:GetPos():DistToSqr(ply:GetPos()) > 200 * 200 then return end
        local fn = (cmd == "transformer" and LC.UseTransformer) or (cmd == "sabotage" and LC.SabotageTransformer)
            or (cmd == "swipe" and LC.SwipeForcefield) or (cmd == "shortfield" and LC.ShortForcefield)
        if fn then
            local ok, why = fn(ply, target)
            if not ok and why then ply:ChatPrint(why) end
        end
    elseif cmd == "checkpoint" then
        -- turrets and power banks (sv_livingcity_checkpoints.lua)
        if LC.CheckpointAction then LC.CheckpointAction(ply, rest, target) end
    elseif cmd == "escort" then
        -- a worker asks for (or dismisses) an escort; a unit takes one on, or hands it back (sv_livingcity_escort.lua)
        if LC.EscortCommand then LC.EscortCommand(ply, rest, target) end
    elseif cmd == "waypoint" then
        if LC.WaypointTo then LC.WaypointTo(ply, rest) end -- a marker on the way somewhere (sv_livingcity_notices.lua)
    elseif cmd == "readmail" then
        if LC.SendMailList then LC.SendMailList(ply) end -- units at the post office (sv_livingcity_mail.lua)
    elseif cmd == "searchbody" then
        if IsValid(target) and target.lcBody and LC.StartBodySearch and ply:GetPos():DistToSqr(target:GetPos()) < 170 * 170 then
            local ok, why = LC.StartBodySearch(ply, target)
            if not ok and why then ply:ChatPrint(why) end
        end
    elseif cmd == "assign" then
        local _, msg
        if LC.AssignWork then _, msg = LC.AssignWork(ply, target) end
        if msg then ply:ChatPrint(msg) end
    else
        LC.RunAction(ply, cmd, rest)
    end
end)

-- The tips you've had, to read again at your own pace (cl_livingcity_hints.lua)
net.Receive("lc_hints_list", function(_, ply)
    if not IsValid(ply) or (ply.lcHintsListNext or 0) > CurTime() then return end
    ply.lcHintsListNext = CurTime() + 1
    if LC.SendSeenHints then LC.SendSeenHints(ply) end
end)

-- Interrogation: a choice on the screen (sv_livingcity_custody.lua)
hook.Add("LivingCityInterrogation", "LivingCityActions", function(ply)
    if not IsValid(ply) then return end
    net.Start("lc_interrogate")
    net.Send(ply)
end)

net.Receive("lc_interrogate_reply", function(_, ply)
    if not IsValid(ply) then return end
    local talk = net.ReadBool()
    if talk then
        if LC.InterrogationTalk then LC.InterrogationTalk(ply) end
    else
        ply:ChatPrint("[Interrogation] You say nothing.")
    end
end)
