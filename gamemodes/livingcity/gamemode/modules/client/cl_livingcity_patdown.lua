--[[
    Living City (client): the quick menu that comes with cuffing someone (sv_livingcity_patdown.lua)

    The owner, 12 November: an optional patdown at arrest, and no mouse windows:
    "a special hidden menu that appears for these situations similar to the F1 and
    F2 quick menus". It comes up by itself when you cuff a player and goes when
    they're out of your reach; 0 closes it (the patdown is skipped, and can still
    be done later from F1 while they're cuffed).
]]

LC_CL = LC_CL or {}

local function Send(...) if LC_CL.SendAction then LC_CL.SendAction(...) end end

net.Receive("lc_custody", function()
    local target, name = net.ReadEntity(), net.ReadString()
    if not IsValid(target) or not LC_CL.OpenSituation then return end
    LC_CL.OpenSituation({ id = "custody", title = name .. ", cuffed",
        items = {
            { label = "Pat them down", run = function() Send("patdown", "", target) end },
            { label = "No time: walk them along / let go", run = function() Send("drag") end },
            { label = "Take the cuffs off", run = function() Send("untie") end },
        },
        note = "A patdown finds weapons, radios and tools in their pockets. Skip it and they keep what they carry.",
        stay = function()
            local me = LocalPlayer()
            return IsValid(target) and IsValid(me) and target:GetNW2Bool("lc_tied", false) and me:GetPos():DistToSqr(target:GetPos()) < 250 * 250
        end })
end)
