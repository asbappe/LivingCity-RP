--[[
    Living City (client): talking to people

    The little window that opens when you press E on a citizen
    (sv_livingcity_talk.lua): who they are, how they feel about you, what
    they just said, and what you can do.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(232, 226, 210), Color(170, 165, 150)
local MOOD = { warm = Color(140, 210, 140), afraid = Color(230, 140, 110), neutral = Color(190, 190, 190) }

local frame

local function Do(npc, what)
    net.Start("lc_talk_do")
    net.WriteEntity(npc)
    net.WriteString(what)
    net.SendToServer()
end

net.Receive("lc_talk", function()
    local npc = net.ReadEntity()
    if not IsValid(npc) then
        if IsValid(frame) then frame:Remove() end
        return
    end
    local name, job, doing, mood, kind, said = net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString()
    local canChat, canFood, canPick, canInform, canRecruit = net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()
    -- how they seem and why (the city's minds, sv_livingcity_minds.lua; empty unless lc_minds_show is on)
    local seem = net.ReadString() or ""
    -- what you could give them (sv_livingcity_talk.lua, LC.GiveableTo): id and label
    local give = {}
    for _ = 1, net.ReadUInt(8) or 0 do
        local id, label = net.ReadString(), net.ReadString()
        if id and id ~= "" then give[#give + 1] = { id = id, label = label or id } end
    end
    local canChair, canCage = net.ReadBool(), net.ReadBool()
    local tall = 330 + (seem ~= "" and 34 or 0) + (canChair and 30 or 0) + (canCage and 30 or 0)

    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle(name)
    frame:SetSize(420, tall)
    -- low on the screen, off to the right, and see-through: so you can still see who you're talking to
    frame:SetPos(math.floor(ScrW() * 0.62), ScrH() - tall - 60)
    frame:MakePopup()
    frame.npc = npc
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(16, 15, 13, 150))
        draw.RoundedBoxEx(6, 0, 0, w, 24, Color(30, 28, 24, 190), true, true, false, false)
    end

    local head = vgui.Create("DLabel", frame)
    head:Dock(TOP)
    head:DockMargin(8, 2, 8, 0)
    head:SetTall(18)
    head:SetTextColor(DIM)
    head:SetText((job ~= "" and job or "No work") .. (doing ~= "" and ("  |  " .. doing) or ""))

    local feel = vgui.Create("DLabel", frame)
    feel:Dock(TOP)
    feel:DockMargin(8, 0, 8, 4)
    feel:SetTall(18)
    feel:SetTextColor(MOOD[kind] or MOOD.neutral)
    feel:SetText("They're " .. mood .. ".")

    if seem ~= "" then
        local how = vgui.Create("DLabel", frame)
        how:Dock(TOP)
        how:DockMargin(8, 0, 8, 4)
        how:SetTall(30)
        how:SetWrap(true)
        how:SetTextColor(DIM)
        how:SetText(seem)
    end

    local words = vgui.Create("DLabel", frame)
    words:Dock(TOP)
    words:DockMargin(8, 2, 8, 8)
    words:SetTall(70)
    words:SetWrap(true)
    words:SetTextColor(INK)
    words:SetText(said ~= "" and said or "They wait for you to say something.")

    local function Button(label, what, enabled)
        local b = vgui.Create("DButton", frame)
        b:Dock(TOP)
        b:DockMargin(8, 0, 8, 4)
        b:SetTall(26)
        b:SetText(label)
        b:SetEnabled(enabled ~= false)
        b.DoClick = function()
            if what then Do(npc, what) else frame:Remove() end
        end
        return b
    end
    Button("Chat (what have they heard?)", "chat", canChat)
    -- Give something: a menu of what's in your pockets that could be handed over
    local giveB = Button(#give > 0 and "Give something..." or "Give something (nothing to give)", nil, #give > 0)
    giveB.DoClick = function()
        local m = DermaMenu()
        for _, g in ipairs(give) do m:AddOption(g.label, function() Do(npc, "give:" .. g.id) end) end
        m:Open()
    end
    if canRecruit then Button("Ask them to keep watch for us (a lookout)", "recruit") end
    if canCage then Button("Take them prisoner (to the holding cage)", "cage") end
    if canChair then Button("Take them to interrogation chair", "chair") end
    Button("Pick their pocket (Guile)", "pick", canPick)
    if canInform then Button("Inform on them to Civil Protection", "inform") end
    Button("Leave", nil)

    -- walk away, or they do, and it's over
    local baseThink = frame.Think -- (DFrame's own: dragging and resizing the window)
    frame.Think = function(self)
        if baseThink then baseThink(self) end
        local me = LocalPlayer()
        if not IsValid(self.npc) or not IsValid(me) or me:GetPos():DistToSqr(self.npc:GetPos()) > 220 * 220 then self:Remove() end
    end
end)
