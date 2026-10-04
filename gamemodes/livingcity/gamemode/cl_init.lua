--[[
    Living City (gamemode, client)

    No spawn menu or context menu unless you're an admin in build mode, no
    Sandbox hints, and F1 opens a short guide to the city.
]]

include("shared.lua")

function GM:SpawnMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:ContextMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:SuppressHint() return true end

local INK, ACCENT = Color(232, 226, 210), Color(230, 180, 90)

local GUIDE = {
    { "Keys", {
        "F1  this guide        F2  your pockets (and stash at home)",
        "F3  your board: jobs, stories, Union employment        F4  factions",
        "E on people: talk to citizens, report to units. E on things: pick up, use.",
    } },
    { "Permanent death", {
        "When you die, that person is gone. You come back as someone new, with a new name and citizen number,",
        "and nothing: no credits, standing, job, pockets, stash or rank. Be careful who you pick a fight with.",
    } },
    { "Staying alive", {
        "Eat and drink. Ration dispensers and the ration line feed you; the Commissary (!shop) sells the rest.",
        "Wade into water and press E to drink, but boil it first if you can (stove or fire, F2).",
        "Your fists kill birds. Cook them.",
    } },
    { "Staying out of trouble", {
        "Don't crowd Civil Protection. Warnings come first, then the stick.",
        "When a unit stops you, stand still. Anything illegal in your pockets may be found.",
        "Curfew: you get a minute to reach your housing block. A travel permit gets you past one stop.",
        "Combine-only areas (the nexus, offices, armory, prison) are off limits. Doors by the cells are locked.",
        "Raids: units sweep a housing block and trace any contraband (guns, TVs, radios...) to whoever owned it.",
        "Being wanted means every unit nearby comes for you. Get caught and you're arrested.",
        "Kill units and it escalates: armed units, then Overwatch squads. Lie low to cool it off.",
        "To give yourself up, walk up to a unit and press E. It goes easier on you.",
        "Anticitizen? Do community service from your board (F3), or serve your time.",
    } },
    { "Getting by", {
        "Take a Union job on your board (F3) and work shifts for credits and Civil Standing.",
        "Standing decides what the Commissary will sell you. Crimes lower it.",
        "Rebel territory has a black market (!market). Radios: !r to talk.",
        "Search the dead with E. Dead units carry ammunition, and sometimes a keycard.",
    } },
}

net.Receive("lcg_help", function()
    local admin = net.ReadBool()
    local f = vgui.Create("DFrame")
    f:SetTitle("")
    f:SetSize(math.min(ScrW() - 60, 680), math.min(ScrH() - 60, 560))
    f:Center()
    f:MakePopup()
    f.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(16, 15, 13, 245))
        draw.SimpleText("LIVING CITY", "DermaLarge", 16, 14, ACCENT)
    end
    local scroll = vgui.Create("DScrollPanel", f)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 30, 8, 8)
    local sections = table.Copy(GUIDE)
    if admin then
        sections[#sections + 1] = { "Admin", {
            "!build toggles build mode: spawn menu, context menu, physgun, toolgun (Living City Editor) and noclip.",
            "lc_debugreport copies a report to send when something breaks.",
        } }
    end
    for _, sec in ipairs(sections) do
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(0, 10, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText(string.upper(sec[1]))
        head:SizeToContents()
        for _, line in ipairs(sec[2]) do
            local l = vgui.Create("DLabel", scroll)
            l:Dock(TOP)
            l:DockMargin(8, 0, 0, 2)
            l:SetTextColor(INK)
            l:SetWrap(true)
            l:SetAutoStretchVertical(true)
            l:SetText(line)
        end
    end
end)

-- Chat shows who people are in the city, not their Steam names.
hook.Add("OnPlayerChat", "LivingCityCharacterNames", function(ply, text, teamOnly, dead)
    if not IsValid(ply) then return end
    local name = ply:GetNW2String("lc_char", "")
    if name == "" then return end
    chat.AddText(Color(150, 170, 200), name, color_white, ": " .. text)
    return true
end)
