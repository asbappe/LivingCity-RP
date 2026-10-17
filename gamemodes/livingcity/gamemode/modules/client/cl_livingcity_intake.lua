--[[
    Living City (client): Civil Intake

    For a new arrival: one line at the bottom of the screen saying what's
    next (register at Civil Intake, or ask Housing Allocation for a room) and
    how far, and a marker over that terminal. While a terminal works on you,
    a bar: stay beside it. The terminals carry a sign of their own.
    The server side is sv_livingcity_intake.lua.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 226, 210), Color(160, 155, 142)
local BLUE = Color(120, 200, 255)
local OUTLINE = Color(0, 0, 0, 220)

surface.CreateFont("LCIntakeSign", { font = "Trebuchet MS", size = 52, weight = 700 })
surface.CreateFont("LCIntakeSignSmall", { font = "Trebuchet MS", size = 30, weight = 500 })

-- What's next for this person: "register", "housing", or nil.
function LC_CL.IntakeStep(ply)
    if not IsValid(ply) then return nil end
    if ply:GetNW2Bool("lc_unreg", false) then return "register" end
    if ply:GetNW2Bool("lc_unhoused", false) then return "housing" end
    return nil
end

-- The terminals, looked for once a second.
local desks, desksAt = {}, -1
local function Desks()
    local now = CurTime()
    if now - desksAt > 1 or now < desksAt then
        desks = {}
        for _, e in ipairs(ents.FindByClass and ents.FindByClass("lc_intake") or {}) do
            if IsValid(e) then desks[#desks + 1] = e end
        end
        desksAt = now
    end
    return desks
end

local function DeskKind(e) local k = e:GetNW2String("lc_ikind", "") return k ~= "" and k or "register" end

-- The nearest terminal of a kind, and how far (in units).
function LC_CL.NearestDesk(kind)
    local me = LocalPlayer()
    if not IsValid(me) then return nil end
    local best, bd
    for _, e in ipairs(Desks()) do
        if IsValid(e) and DeskKind(e) == kind then
            local d = e:GetPos():DistToSqr(me:GetPos())
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best, bd and math.sqrt(bd) or nil
end

local function Meters(units) return math.max(1, math.floor(units / 40 + 0.5)) end

hook.Add("HUDPaint", "LivingCityIntake", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local now = CurTime()
    local W, H = ScrW(), ScrH()

    -- the terminal working on you
    local untilT = ply:GetNW2Float("lc_intake_until", 0)
    local working = untilT > now
    if working then
        local secs = math.max(1, ply:GetNW2Float("lc_intake_secs", 8))
        local frac = math.Clamp(1 - (untilT - now) / secs, 0, 1)
        local cx, cy = W / 2, H * 0.64
        draw.RoundedBox(4, cx - 190, cy - 28, 380, 58, Color(10, 14, 20, 225))
        draw.SimpleText(ply:GetNW2String("lc_intake_doing", "Processing") .. "...", "DermaDefaultBold", cx, cy - 13, BLUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.RoundedBox(2, cx - 170, cy + 2, 340, 10, Color(40, 44, 50, 230))
        draw.RoundedBox(2, cx - 170, cy + 2, 340 * frac, 10, BLUE)
        draw.SimpleText("Stay at the terminal", "DefaultSmall", cx, cy + 20, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local step = LC_CL.IntakeStep(ply)
    if not step then return end
    local desk, dist = LC_CL.NearestDesk(step)
    local text = step == "register" and "NEW ARRIVAL: register at Civil Intake" or "NO ROOM YET: ask Housing Allocation"
    if dist then text = text .. string.format("   %d m", Meters(dist)) end
    draw.SimpleTextOutlined(text, "DermaDefaultBold", W / 2, H - 150, BLUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, OUTLINE)

    -- a marker over the terminal (unless a waypoint already marks it: cl_livingcity_notices.lua)
    local way = LC_CL.Waypoint and LC_CL.Waypoint()
    local marked = way and IsValid(desk) and way.pos:DistToSqr(desk:GetPos()) < 100 * 100
    if IsValid(desk) and not working and not marked then
        local sp = (desk:GetPos() + Vector(0, 0, 96)):ToScreen()
        if sp and sp.visible then
            local label = step == "register" and "CIVIL INTAKE" or "HOUSING ALLOCATION"
            draw.SimpleTextOutlined(label, "DefaultSmall", sp.x, sp.y - 14, BLUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, OUTLINE)
            draw.RoundedBox(2, sp.x - 4, sp.y - 2, 8, 8, BLUE)
        end
    end
end)

-- The sign on the terminal itself (lc_intake.lua draws it, in 3D).
function LC_CL.DrawIntakeSign(ent)
    local housing = DeskKind(ent) == "housing"
    draw.RoundedBox(6, -300, -70, 600, 140, Color(8, 16, 26, 230))
    surface.SetDrawColor(BLUE.r, BLUE.g, BLUE.b, 180)
    surface.DrawOutlinedRect(-300, -70, 600, 140, 3)
    draw.SimpleText(housing and "HOUSING ALLOCATION" or "CIVIL INTAKE", "LCIntakeSign", 0, -24, BLUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(housing and "Registered arrivals: request a room" or "New arrivals: registration", "LCIntakeSignSmall", 0, 30, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

------------------------------------------------------------------------
-- The terminals' screens (sv_livingcity_intake.lua, LC.SendDesk)
--   Civil Intake, registered: your record; replacing lost papers or a card.
--   Housing Allocation: the housing register. Apply for a block (or any),
--   or, housed, see where and how, find the way, and ask for a transfer.
------------------------------------------------------------------------

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

surface.CreateFont("LCDeskTitle", { font = "Trebuchet MS", size = 26, weight = 700 })
surface.CreateFont("LCDeskHead", { font = "Trebuchet MS", size = 18, weight = 700 })
surface.CreateFont("LCDeskText", { font = "Trebuchet MS", size = 16, weight = 500 })

local PANEL, ROW = Color(8, 14, 22, 245), Color(18, 28, 40, 235)
local GOOD, BAD = Color(120, 210, 140), Color(230, 110, 90)

-- How you came to have the room you have.
local HOW = {
    allocation = "Allocated here, at Housing Allocation.",
    transfer = "Transferred here at your request.",
    papers = "Came with your papers (there was no Housing Allocation desk then).",
    staff = "Assigned by the city administration.",
    auto = "Already on file before you came to this desk: assigned when you first arrived in the city.",
}

local desk
function LC_CL.DeskAct(action, arg)
    net.Start("lc_intake_act")
    net.WriteString(action)
    net.WriteInt(arg or 0, 16)
    net.SendToServer()
end

function LC_CL.OpenDesk(t)
    if IsValid(desk) then desk:Remove() end
    if not t then return end
    local housing = t.kind == "housing"
    local W, H = math.min(ScrW() - 40, 640), math.min(ScrH() - 40, housing and 600 or 420)
    desk = vgui.Create("DFrame")
    desk:SetTitle("")
    desk:SetSize(W, H)
    desk:Center()
    desk:MakePopup()
    desk.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        surface.SetDrawColor(BLUE.r, BLUE.g, BLUE.b, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText(housing and "HOUSING ALLOCATION" or "CIVIL INTAKE", "LCDeskTitle", 16, 10, BLUE)
        draw.SimpleText((t.name or "?") .. "   citizen " .. (t.cid or "?"), "LCDeskText", w - 40, 20, INK, TEXT_ALIGN_RIGHT)
    end
    local scroll = vgui.Create("DScrollPanel", desk)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 30, 8, 8)

    local function Close() if IsValid(desk) then desk:Remove() end end
    local function Line(text, col, font)
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(4, 2, 4, 2)
        l:SetFont(font or "LCDeskText")
        l:SetTextColor(col or INK)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(text)
        return l
    end
    local function Head(text) local l = Line(text, BLUE, "LCDeskHead") l:DockMargin(4, 10, 4, 4) end
    local function Button(text, enabled, fn, tip)
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(4, 3, 4, 3)
        b:SetTall(30)
        b:SetText(text)
        b:SetEnabled(enabled ~= false)
        if tip then b:SetTooltip(tip) end
        b.DoClick = fn
        return b
    end
    local function Way(n, label) Button(label, true, function() LC_CL.DeskAct("way", n) Close() end) end

    if not housing then
        Head("YOUR RECORD")
        Line("Housing: " .. (t.blockName or (t.awaiting and "none yet" or "none on file")))
        Line("Identity papers: " .. (t.papers and "on you" or "NOT on you"), t.papers and GOOD or BAD)
        Line("Ration card: " .. (t.card and "on you" or "NOT on you"), t.card and GOOD or BAD)
        Line(string.format("Credits: %d", t.credits or 0), DIM)
        if not t.papers then
            Button(string.format("Replace my identity papers (%d credits)", t.papersFee or 10), (t.credits or 0) >= (t.papersFee or 10),
                function() LC_CL.DeskAct("papers") Close() end, "Civil Protection units ask for papers; Housing Allocation wants to see them")
        end
        if not t.card then
            Button(string.format("Replace my ration card (%d credits)", t.cardFee or 15), (t.credits or 0) >= (t.cardFee or 15),
                function() LC_CL.DeskAct("card") Close() end, "The ration dispensers want to see it")
        end
        if t.papers and t.card then Line("Your papers are in order.", GOOD) end
        if t.awaiting and t.housingDesk then
            Head("NEXT")
            Line("You have no room yet. Housing Allocation assigns one.")
            Way(2, "Show me the way to Housing Allocation")
        elseif (t.block or 0) > 0 then
            Way(3, "Show me the way home")
        end
    elseif t.pending then
        Head("NO RECORD")
        Line("The terminal can't find you on the register. Register at Civil Intake first; then come back with your papers.")
        Way(1, "Show me the way to Civil Intake")
    elseif t.awaiting then
        Head("APPLICATION FOR HOUSING")
        Line("Present your papers and pick a block. Any block is approved at once (the least crowded). A crowded block is only granted to citizens in good standing ("
            .. (t.good or 50) .. " or more). Yours: " .. (t.standing or 0) .. ".", DIM)
        Line("Papers: " .. (t.papers and "presented" or "NOT on you (Civil Intake replaces them)"), t.papers and GOOD or BAD)
        Button("Any block (approved at once)", t.papers, function() LC_CL.DeskAct("apply", 0) Close() end)
        local least
        for _, b in ipairs(t.blocks or {}) do least = math.min(least or b.residents, b.residents) end
        for _, b in ipairs(t.blocks or {}) do
            local crowded = b.residents > (least or 0) + 1
            Button(string.format("Apply for %s   (%d living there%s%s)", b.name, b.residents, b.m and (", " .. b.m .. " m away") or "",
                crowded and ", crowded" or ""), t.papers, function() LC_CL.DeskAct("apply", b.n) Close() end)
        end
        if #(t.blocks or {}) == 0 then Line("No blocks on file in this city.", BAD) end
    else
        Head("ASSIGNED: " .. string.upper(t.blockName or "no room"))
        Line(HOW[t.how or ""] or HOW.auto, DIM)
        if (t.block or 0) > 0 then Way(3, "Show me the way home") end
        Head("REQUEST A TRANSFER")
        if t.transfer then
            Line("Move to another block (once every half hour). A crowded block needs good standing (" .. (t.good or 50) .. ").", DIM)
            for _, b in ipairs(t.blocks or {}) do
                if b.n ~= t.block then
                    Button(string.format("Transfer to %s   (%d living there%s)", b.name, b.residents, b.m and (", " .. b.m .. " m away") or ""),
                        t.papers, function() LC_CL.DeskAct("transfer", b.n) Close() end)
                end
            end
            if not t.papers then Line("Present your papers to apply: you have none on you.", BAD) end
        else
            Line(t.transferWhy or "Not now.", DIM)
        end
    end
    local close = Button("Close", true, Close)
    close:DockMargin(4, 12, 4, 3)
end

net.Receive("lc_intake_ui", function() LC_CL.OpenDesk(ReadCompressed()) end)

------------------------------------------------------------------------
-- Papers, shown (yours, or someone holding theirs up for you)
------------------------------------------------------------------------

local card -- { info, untilT }
surface.CreateFont("LCPapersBig", { font = "Courier New", size = 22, weight = 700 })
surface.CreateFont("LCPapers", { font = "Courier New", size = 16, weight = 600 })

net.Receive("lc_papers_card", function()
    local t = ReadCompressed()
    if t then card = { info = t, untilT = CurTime() + 9 } end
end)
function LC_CL.ShowPapersCard(t) card = t and { info = t, untilT = CurTime() + 9 } or nil end

hook.Add("HUDPaint", "LivingCityPapers", function()
    if not card or CurTime() > card.untilT then card = nil return end
    local t = card.info
    local W, H = 360, 190
    local x, y = ScrW() - W - 30, ScrH() * 0.3
    local a = math.Clamp((card.untilT - CurTime()) / 0.5, 0, 1)
    draw.RoundedBox(4, x, y, W, H, Color(214, 206, 180, 245 * a))
    draw.RoundedBox(0, x, y, W, 30, Color(60, 80, 100, 245 * a))
    local ink = Color(40, 36, 30, 255 * a)
    draw.SimpleText("CIVIL REGISTRY: IDENTITY", "LCPapers", x + 12, y + 15, Color(230, 235, 240, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(t.from and "SHOWN TO YOU" or "YOUR PAPERS", "DefaultSmall", x + W - 12, y + 15, Color(200, 210, 220, 255 * a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.upper(t.name or "?"), "LCPapersBig", x + 14, y + 50, ink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("CID " .. (t.cid or "?"), "LCPapers", x + 14, y + 78, ink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("HOUSING  " .. string.upper(t.block or "?"), "LCPapers", x + 14, y + 100, ink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local desc = t.desc or ""
    if #desc > 44 then desc = string.sub(desc, 1, 42) .. "..." end
    draw.SimpleText(desc, "DefaultSmall", x + 14, y + 122, Color(70, 64, 56, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(t.card and "RATION CARD ATTACHED" or "NO RATION CARD", "DefaultSmall", x + 14, y + 142, ink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    if t.from then draw.SimpleText("Held up by the person in front of you", "DefaultSmall", x + 14, y + H - 16, Color(70, 64, 56, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
end)
