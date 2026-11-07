--[[
    Living City (client): Labor Assignment's screen

    The rows of the Labor Assignment terminal's screen (or window): your
    assignment and how long you're tied to it, the button that asks the Union
    for work, and once you're free to change, every job with the ones you
    can't have yet and why. The window itself, and the terminal's own screen,
    are cl_livingcity_intake.lua's (LC_CL.OpenDesk). The server side is
    sv_livingcity_labor.lua.
]]

LC_CL = LC_CL or {}

local DIM = Color(160, 155, 142)
local GOOD, BAD = Color(120, 210, 140), Color(230, 110, 90)

local function Act(action, arg)
    if LC_CL.DeskAct then LC_CL.DeskAct(action, arg) end
end

local function Plural(n, one, many) return n == 1 and ("1 " .. one) or (tostring(n) .. " " .. many) end
-- How long a new job holds you; a 0 turns that part off, both 0: no hold (nil).
local function Hold(mins, shifts)
    if mins > 0 and shifts > 0 then return Plural(mins, "minute", "minutes") .. " or " .. Plural(shifts, "shift", "shifts") .. ", whichever comes first" end
    if mins > 0 then return Plural(mins, "minute", "minutes") end
    if shifts > 0 then return Plural(shifts, "shift", "shifts") end
end

-- t: the desk's payload (t.labor is sv_livingcity_labor.lua's LC.LaborDeskInfo).
function LC_CL.LaborRows(t, Line, Head, Button, Way, Close)
    local l = t.labor or {}
    if l.registered == false then
        Head("NO RECORD")
        Line("You're not registered yet. Register at Civil Intake first, then come back here with your papers.")
        Way(1, "Show me the way to Civil Intake")
        return
    end
    if l.canWork == false then
        Head("NOT ELIGIBLE")
        Line("The Union only gives work to citizens.", BAD)
        return
    end
    Line("Identity papers: " .. (l.papers and "presented" or "NOT on you (Civil Intake replaces them)"), l.papers and GOOD or BAD)

    if l.first then
        Head("YOUR WORK ASSIGNMENT")
        local hold = Hold(l.minMinutes or 30, l.minShifts or 4)
        Line("Every citizen works. The Union gives you the post with the most openings."
            .. (hold and (" You stay on it for " .. hold .. "; then you can come back here and ask for a different job.") or ""), DIM)
        Button("Ask for my work assignment", l.papers, function() Act("assign") Close() end)
        return
    end

    Head(l.jobName and ("ASSIGNED: " .. string.upper(l.jobName)) or "NO WORK ASSIGNMENT")
    if l.jobName and l.place then Line("Work at the " .. string.lower(l.place) .. ". Your shifts are on your board (F4).", DIM) end
    if l.locked then
        local mOn, sOn = (l.minMinutes or 30) > 0, (l.minShifts or 4) > 0
        local left = (mOn and sOn) and string.format("%s more, or %s more, whichever comes first",
            Plural(l.minsLeft or 0, "minute", "minutes"), Plural(l.shiftsLeft or 0, "shift", "shifts"))
            or (mOn and (Plural(l.minsLeft or 0, "minute", "minutes") .. " more") or (Plural(l.shiftsLeft or 0, "shift", "shifts") .. " more"))
        local sofar = (mOn and sOn) and (Plural(l.mins or 0, "minute", "minutes") .. " and " .. Plural(l.shifts or 0, "shift", "shifts"))
            or (mOn and Plural(l.mins or 0, "minute", "minutes") or Plural(l.shifts or 0, "shift", "shifts"))
        Line("You're tied to this assignment for " .. left .. " (so far: " .. sofar .. ").", BAD)
        Line("Come back then if you want a different job.", DIM)
    else
        if not l.jobName then
            Button("Let the Union choose (the post with the most openings)", l.papers, function() Act("assign") Close() end)
        end
        Head(l.jobName and "ASK FOR A DIFFERENT JOB" or "OR ASK FOR A JOB")
        local hold = Hold(l.minMinutes or 30, l.minShifts or 4)
        Line((hold and ("A new job holds you for " .. hold .. ". ") or "") .. string.format("Your Civil Standing is %d.", l.standing or 0), DIM)
        if (l.wait or 0) > 0 then
            Line(string.format("You changed jobs recently: the Union lets you change again in %s.",
                (l.wait >= 120) and Plural(math.ceil(l.wait / 60), "minute", "minutes") or Plural(l.wait, "second", "seconds")), BAD)
        end
        for _, j in ipairs(l.jobs or {}) do
            if j.current then
                Line(j.name .. "   (your job now)", GOOD)
            elseif j.locked then
                Button(j.name .. "   (" .. j.locked .. ")", false, function() end)
            else
                Button(j.name .. "   (" .. string.lower(j.place or "") .. ")", l.papers and (l.wait or 0) <= 0,
                    function() Act("choose", j.num) Close() end, j.desc)
            end
        end
    end
    if l.housingNext then
        Head("NEXT")
        Line("Then Housing Allocation gives you a room.")
        Way(2, "Show me the way to Housing Allocation")
    end
end
