--[[
    Living City (client): the Administrator's Commissary and market panel (sv_livingcity_market.lua).
    Her tablet > The Commissary and the market. Two pages: each Commissary good's restriction, price,
    standing and supply; and what the black market is charging, and what the city wants.
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Set(id, field, value)
    net.Start("lc_market_set") net.WriteString(id) net.WriteString(field) net.WriteString(tostring(value)) net.SendToServer()
end

local PRICES = { 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 5 }
local INK, DIM, WARN, ROW = Color(235, 230, 215), Color(170, 165, 150), Color(235, 190, 90), Color(30, 28, 24, 240)

local frame, page

local function PriceText(m) return m == 1 and "Usual price" or string.format("%d%% of usual", math.floor(m * 100 + 0.5)) end
local function StandingText(n, tiers)
    for _, t in ipairs(tiers or {}) do if t.min == n then return string.format("%s (%d)", t.name, n) end end
    return tostring(n)
end

local function CommissaryPage(parent, t)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    for _, g in ipairs(t.goods or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(62)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, ROW)
            draw.SimpleText(g.name, "DermaDefaultBold", 10, 12, g.restricted and DIM or INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("Usually %d credits, now %d.   Black market: %s.   Demand: %s", g.price or 0, g.now or 0,
                g.black and (g.black .. " credits") or "not sold", (g.demand or 0) > 0 and ("+" .. g.demand .. "%") or "ordinary"),
                "DermaDefault", 10, 30, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if g.note then draw.SimpleText(g.note, "DermaDefault", 10, 48, WARN, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
        end
        local reset = vgui.Create("DButton", row)
        reset:Dock(RIGHT) reset:DockMargin(4, 18, 6, 18) reset:SetWide(70)
        reset:SetText("As usual")
        reset.DoClick = function() Set(g.id, "reset", "") end
        local supply = vgui.Create("DComboBox", row)
        supply:Dock(RIGHT) supply:DockMargin(4, 18, 0, 18) supply:SetWide(95)
        supply:SetValue(g.supply == "scarce" and string.format("Scarce (%d)", g.stock or 0) or (g.supply == "plentiful" and "Plentiful" or "Normal supply"))
        for _, s in ipairs({ { "Plentiful", "plentiful" }, { "Normal supply", "normal" }, { "Scarce", "scarce" } }) do supply:AddChoice(s[1], s[2]) end
        supply.OnSelect = function(_, _, _, v) Set(g.id, "supply", v) end
        local standing = vgui.Create("DComboBox", row)
        standing:Dock(RIGHT) standing:DockMargin(4, 18, 0, 18) standing:SetWide(120)
        standing:SetValue("Needs " .. StandingText(g.standing or -50, t.tiers))
        standing:AddChoice("Usual (" .. StandingText(g.baseStanding or -50, t.tiers) .. ")", "default")
        local seen = {}
        for _, tier in ipairs(t.tiers or {}) do seen[tier.min] = true standing:AddChoice(StandingText(tier.min, t.tiers), tier.min) end
        for _, n in ipairs({ 50, 100, 250, 600, 800, 1000 }) do if not seen[n] then standing:AddChoice(tostring(n), n) end end
        standing.OnSelect = function(_, _, _, v) Set(g.id, "standing", v) end
        local price = vgui.Create("DComboBox", row)
        price:Dock(RIGHT) price:DockMargin(4, 18, 0, 18) price:SetWide(105)
        price:SetValue(PriceText(g.mul or 1))
        for _, m in ipairs(PRICES) do price:AddChoice(PriceText(m), m) end
        price.OnSelect = function(_, _, _, v) Set(g.id, "price", v) end
        local restrict = vgui.Create("DCheckBoxLabel", row)
        restrict:Dock(RIGHT) restrict:DockMargin(4, 22, 4, 22) restrict:SetWide(80)
        restrict:SetText("Restricted")
        restrict:SetChecked(g.restricted == true)
        restrict.OnChange = function(_, v) Set(g.id, "restrict", v and "1" or "0") end
    end
    return scroll
end

local function MarketPage(parent, t)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    local function Line(text, col, bold)
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP) l:DockMargin(6, 2, 6, 2)
        l:SetFont(bold and "DermaDefaultBold" or "DermaDefault")
        l:SetTextColor(col or INK)
        l:SetWrap(true) l:SetAutoStretchVertical(true)
        l:SetText(text)
    end
    local r = t.restricted or {}
    Line("RESTRICTED AT THE COMMISSARY", WARN, true)
    Line(#r > 0 and table.concat(r, ", ") or "Nothing.", INK)
    if #r > 0 then
        Line(string.format("Each restriction drives another citizen to the Resistance: %d more fighter%s in rebel territory, and their operations come %d%% sooner.",
            t.rebels or 0, (t.rebels or 0) == 1 and "" or "s", math.floor((1 - (t.opsMul or 1)) * 100 + 0.5)), WARN)
    end
    Line(" ", DIM)
    Line("THE BLACK MARKET", WARN, true)
    if #(t.black or {}) == 0 then Line("Charging what it always does. Nothing is in short supply or in demand.", DIM) end
    for _, b in ipairs(t.black or {}) do
        Line(string.format("%s: %d credits (usually %d)%s%s", b.name, b.price or 0, b.usual or 0,
            b.note and ("   " .. b.note) or "", (b.demand or 0) > 0 and string.format("   (demand +%d%%)", b.demand) or ""), b.extra and WARN or INK)
    end
    return scroll
end

function LC_CL.OpenMarketAdmin(t)
    t = t or {}
    page = IsValid(frame) and frame.lcSheet and frame.lcSheet:GetActiveTab() and frame.lcSheet:GetActiveTab():GetText() or page
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("The Commissary and the market")
    frame:SetSize(math.min(ScrW() - 40, 900), math.min(ScrH() - 40, 640))
    frame:Center()
    frame:MakePopup()
    if t.on == false then
        local l = vgui.Create("DLabel", frame)
        l:Dock(FILL) l:SetText("The market is switched off on this server (lc_market 0). Prices are as fixed.")
        return frame
    end
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    frame.lcSheet = sheet
    local a = vgui.Create("DPanel", sheet) a.Paint = function() end
    CommissaryPage(a, t)
    local b = vgui.Create("DPanel", sheet) b.Paint = function() end
    MarketPage(b, t)
    sheet:AddSheet("The Commissary", a, "icon16/cart.png")
    sheet:AddSheet("The market", b, "icon16/chart_line.png")
    if page == "The market" and sheet.SwitchToName then sheet:SwitchToName("The market") end
    return frame
end
function LC_CL.MarketAdminFrame() return frame end

net.Receive("lc_market_admin", function() LC_CL.OpenMarketAdmin(ReadCompressed()) end)
