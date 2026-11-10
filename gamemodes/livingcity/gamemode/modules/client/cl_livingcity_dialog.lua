--[[
    Living City (client): the question-and-answer window (sv_livingcity_dialog.lua):
    the Citizen Information clerk, the old-timer, the orientation pamphlet.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 226, 210), Color(170, 165, 150)
local frame

local function Do(id)
    net.Start("lc_dialog_do")
    net.WriteString(id)
    net.SendToServer()
end

net.Receive("lc_dialog", function()
    local ent = net.ReadEntity()
    local title, sub, text = net.ReadString(), net.ReadString(), net.ReadString()
    local opts = {}
    for i = 1, net.ReadUInt(4) do opts[i] = { net.ReadString(), net.ReadString() } end
    if IsValid(frame) then frame:Remove() end
    if title == "" and #opts == 0 then return end
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
