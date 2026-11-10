--[[
    Living City (client): the question-and-answer window (sv_livingcity_dialog.lua):
    the Citizen Information clerk, the old-timer, the orientation pamphlet.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 226, 210), Color(170, 165, 150)
local frame

local lastPage = "" -- (the pamphlet page last asked for: which picture to show)

local function Do(id)
    lastPage = id
    net.Start("lc_dialog_do")
    net.WriteString(id)
    net.SendToServer()
end

------------------------------------------------------------------------
-- The Civil Orientation pamphlet: a printed leaflet, not a grey window (the owner, 10 November: "a dystopian
-- propaganda pamphlet ... reminiscent of modern day tourist or information pamphlets"). Three folded panels on
-- worn paper: the cover panel lists the sections, the other two carry the page, under a picture cut from the
-- city's own posters. The paper is materials/livingcity/pamphlet/paper.jpg and the pictures are
-- materials/livingcity/posters/<kind>.jpg (both made by _dev/posters/); without them it's drawn plainly.
------------------------------------------------------------------------

surface.CreateFont("LCPamphletTitle", { font = "Arial", size = 21, weight = 900 })
surface.CreateFont("LCPamphletHead", { font = "Arial", size = 40, weight = 900 })
surface.CreateFont("LCPamphletBody", { font = "Arial", size = 19, weight = 500 })
surface.CreateFont("LCPamphletItem", { font = "Arial", size = 18, weight = 700 })
surface.CreateFont("LCPamphletSmall", { font = "Arial", size = 14, weight = 700 })
surface.CreateFont("LCPamphletTiny", { font = "Arial", size = 11, weight = 700 })

local P_PAPER, P_INK, P_SLATE, P_RED, P_DIM = Color(221, 214, 194), Color(24, 33, 44), Color(36, 52, 70), Color(194, 59, 42), Color(104, 106, 100)
local P_WHITE = Color(255, 255, 255)
-- page = { the poster its picture is cut from, how far down the poster's picture the cut starts (0 to 351) }
local PAGE_ART = {
    [""] = { "administrator", 150 }, rations = { "dispenser", 150 }, work = { "work", 180 }, housing = { "housing", 230 },
    papers = { "intake", 330 }, law = { "law", 340 }, curfew = { "curfew", 320 }, standing = { "loyalty", 270 }, cp = { "recruit", 60 },
}
local pMats = {}
local function PMat(path)
    if pMats[path] == nil then
        pMats[path] = false
        if file.Exists("materials/" .. path, "GAME") then pMats[path] = Material(path, "smooth") end
    end
    return pMats[path]
end

local function OpenPamphlet(text, opts)
    local W, H = 860, 580
    local PX, PY, PW, PH = 306, 28, 526, 190 -- the picture
    local head, body = string.match(text, "^(.-)\n\n(.*)$")
    if not head then head, body = "", text end
    local sign
    local b2, s2 = string.match(body, "^(.*)\n\n([^\n]+)$")
    if b2 and #s2 < 60 then body, sign = b2, s2 end
    local pa = PAGE_ART[lastPage] or PAGE_ART[""]
    local art, paper = PMat("livingcity/posters/" .. pa[1] .. ".jpg"), PMat("livingcity/pamphlet/paper.jpg")
    local v0 = (24 + pa[2]) / 1024
    local v1 = v0 + (720 * PH / PW) / 1024

    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(W, H)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame.OnClose = function() Do("") end
    frame.Paint = function(_, w, h)
        if paper and not paper:IsError() then
            surface.SetDrawColor(P_WHITE) surface.SetMaterial(paper) surface.DrawTexturedRect(0, 0, w, h)
        else
            surface.SetDrawColor(P_PAPER) surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(P_SLATE) surface.DrawRect(0, 0, 280, 96)
            surface.SetDrawColor(P_RED) surface.DrawRect(0, 96, 280, 6)
            surface.SetDrawColor(0, 0, 0, 45) surface.DrawRect(280, 0, 1, h) surface.DrawRect(570, 0, 1, h)
        end
        draw.SimpleText("CIVIL ORIENTATION", "LCPamphletTitle", 74, 36, P_PAPER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("A guide for new residents", "LCPamphletSmall", 75, 60, P_PAPER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("IN THIS PAMPHLET", "LCPamphletTiny", 26, 124, P_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if art and not art:IsError() then
            surface.SetDrawColor(P_INK) surface.DrawRect(PX - 3, PY - 3, PW + 6, PH + 6)
            surface.SetDrawColor(P_WHITE) surface.SetMaterial(art)
            surface.DrawTexturedRectUV(PX, PY, PW, PH, 24 / 768, v0, 744 / 768, v1)
        else
            surface.SetDrawColor(P_SLATE) surface.DrawRect(PX, PY, PW, PH)
        end
        surface.SetDrawColor(P_RED) surface.DrawRect(PX - 3, PY + PH + 3, PW + 6, 5)
        draw.SimpleText(head, "LCPamphletHead", PX - 2, PY + PH + 40, P_SLATE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if sign then draw.SimpleText(sign, "LCPamphletSmall", PX + PW - 110, h - 62, P_INK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
        draw.SimpleText("FORM CO-1.   RETAIN THIS PAMPHLET.   ISSUED AT CIVIL INTAKE.", "LCPamphletTiny", PX, h - 22, P_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local words = vgui.Create("DLabel", frame)
    words:SetPos(PX, PY + PH + 68)
    words:SetSize(PW, 230)
    words:SetFont("LCPamphletBody")
    words:SetTextColor(P_INK)
    words:SetWrap(true)
    words:SetContentAlignment(7)
    words:SetText(body)

    -- the sections, numbered down the cover panel
    for i, o in ipairs(opts) do
        local b = vgui.Create("DButton", frame)
        b:SetPos(22, 138 + (i - 1) * 36)
        b:SetSize(240, 31)
        b:SetText("")
        local here = o[1] == lastPage
        b.Paint = function(self, w, h)
            local hot = here or self:IsHovered()
            surface.SetDrawColor(hot and P_RED or P_SLATE) surface.DrawRect(0, 0, h, h)
            draw.SimpleText(tostring(i), "LCPamphletItem", h / 2, h / 2, P_PAPER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(o[2], "LCPamphletItem", h + 12, h / 2, hot and P_RED or P_INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(0, 0, 0, hot and 110 or 40) surface.DrawRect(h + 12, h - 2, w - h - 12, 1)
        end
        b.DoClick = function() Do(o[1]) end
    end
    local shut = vgui.Create("DButton", frame)
    shut:SetPos(22, 138 + #opts * 36 + 10)
    shut:SetSize(240, 31)
    shut:SetText("")
    shut.Paint = function(self, w, h)
        surface.SetDrawColor(P_INK) surface.DrawOutlinedRect(0, 0, w, h)
        draw.SimpleText("Fold it away", "LCPamphletItem", w / 2, h / 2, self:IsHovered() and P_RED or P_INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    shut.DoClick = function() frame:Close() end
end

net.Receive("lc_dialog", function()
    local ent = net.ReadEntity()
    local title, sub, text = net.ReadString(), net.ReadString(), net.ReadString()
    local opts = {}
    for i = 1, net.ReadUInt(4) do opts[i] = { net.ReadString(), net.ReadString() } end
    local style = net.ReadString()
    if IsValid(frame) then frame:Remove() end
    if title == "" and #opts == 0 then return end
    if style == "pamphlet" then OpenPamphlet(text, opts) return end
    local h = 150 + 30 * (#opts + 1) + math.min(220, math.ceil(#text / 52) * 17)
    frame = vgui.Create("DFrame")
    frame:SetTitle(title)
    frame:SetSize(460, h)
    frame:SetPos(math.floor(ScrW() * 0.6), math.max(20, ScrH() - h - 60))
    frame:MakePopup()
    frame.ent = IsValid(ent) and ent or nil
    frame.Paint = function(self, w, hh)
        draw.RoundedBox(6, 0, 0, w, hh, Color(16, 15, 13, 170))
        draw.RoundedBoxEx(6, 0, 0, w, 24, Color(30, 28, 24, 200), true, true, false, false)
    end
    frame.OnClose = function() Do("") end
    if sub ~= "" then
        local s = vgui.Create("DLabel", frame)
        s:Dock(TOP) s:DockMargin(8, 2, 8, 2) s:SetTall(18) s:SetTextColor(DIM) s:SetText(sub)
    end
    local words = vgui.Create("DLabel", frame)
    words:Dock(TOP) words:DockMargin(8, 4, 8, 8)
    words:SetTall(math.min(240, 24 + math.ceil(#text / 52) * 17))
    words:SetWrap(true) words:SetContentAlignment(7) words:SetTextColor(INK)
    words:SetText(text)
    for _, o in ipairs(opts) do
        local b = vgui.Create("DButton", frame)
        b:Dock(TOP) b:DockMargin(8, 0, 8, 4) b:SetTall(26)
        b:SetText(o[2])
        b.DoClick = function() Do(o[1]) end
    end
    local b = vgui.Create("DButton", frame)
    b:Dock(TOP) b:DockMargin(8, 0, 8, 4) b:SetTall(26)
    b:SetText("Leave")
    b.DoClick = function() frame:Close() end
    local baseThink = frame.Think
    frame.Think = function(self)
        if baseThink then baseThink(self) end
        local me = LocalPlayer()
        if self.ent and (not IsValid(self.ent) or not IsValid(me) or me:GetPos():DistToSqr(self.ent:GetPos()) > 240 * 240) then self:Close() end
    end
end)
