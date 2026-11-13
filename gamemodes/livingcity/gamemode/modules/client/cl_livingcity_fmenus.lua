--[[
    Living City: the F3 and F4 windows and each other's keys

    With a window open the game's own key binds don't fire, so with the pockets
    (F3) open, F4 did nothing until the pockets were shut by hand, and the
    other way round (the owner, 11 November). Each of the two windows says here
    that it is open (LC_CL.FMenu); while one is, the keys bound to
    gm_showspare1 and gm_showspare2 are watched: a window's own key shuts it,
    the other's key shuts it and opens the other.
]]

if SERVER then return end

LC_CL = LC_CL or {}

local CMDS = { "gm_showspare1", "gm_showspare2" }
local DEFAULT = { gm_showspare1 = "F3", gm_showspare2 = "F4" }
local open = {} -- [command] = its window
local was = {}  -- [command] = its key was down a moment ago

local function KeyOf(cmd)
    local name = input and input.LookupBinding and input.LookupBinding(cmd) or nil
    local code = input and input.GetKeyCode and input.GetKeyCode(name or DEFAULT[cmd]) or nil
    return (code and code > 0) and code or nil
end
local function Down(cmd)
    local k = KeyOf(cmd)
    return k ~= nil and input.IsKeyDown ~= nil and input.IsKeyDown(k) == true
end

-- A window opened by this command's key (the pockets: gm_showspare1; jobs, career and factions: gm_showspare2).
function LC_CL.FMenu(cmd, frame)
    open[cmd] = frame
    for _, c in ipairs(CMDS) do was[c] = Down(c) end -- (the key that opened it is still down: not a new press)
end

-- Shut F3 and F4 (a situation's quick menu takes over: cl_livingcity_quick.lua, LC_CL.OpenSituation).
function LC_CL.CloseFMenus()
    for _, c in ipairs(CMDS) do
        local f = open[c]
        if IsValid(f) then if f.Close then f:Close() else f:Remove() end end
        open[c] = nil
    end
end

-- What a press of this command's key does now: "close", "switch" (shut the other window and open this one) or nil.
function LC_CL.FMenuPress(cmd)
    local mine = IsValid(open[cmd])
    local other
    for _, c in ipairs(CMDS) do if c ~= cmd and IsValid(open[c]) then other = c end end
    if mine then return "close" end
    if other then return "switch", other end
    return nil
end

hook.Add("Think", "LivingCityFMenus", function()
    local any = false
    for _, c in ipairs(CMDS) do if IsValid(open[c]) then any = true end end
    if not any then return end
    for _, cmd in ipairs(CMDS) do
        local down = Down(cmd)
        if down and not was[cmd] then
            local what, other = LC_CL.FMenuPress(cmd)
            if what == "close" then
                open[cmd]:Close()
                open[cmd] = nil
            elseif what == "switch" then
                open[other]:Close()
                open[other] = nil
                RunConsoleCommand(cmd)
            end
        end
        was[cmd] = down
    end
end)
