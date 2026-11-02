--[[
    Living City (client): the City Administrator election (a vote on screen) and the office
    (sv_livingcity_cityadmin.lua).
]]

LC_CL = LC_CL or {}

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local function Act(what, arg, target)
    net.Start("lc_admin_do") net.WriteString(what) net.WriteString(arg or "") net.WriteEntity(IsValid(target) and target or NULL) net.SendToServer()
end

-- A recall (sv_livingcity_cityadmin.lua): Civil Protection and the Administration vote yes or no
net.Receive("lc_recall", function()
    local secs, sitting, rival = net.ReadFloat(), net.ReadString(), net.ReadString()
    if IsValid(LC_CL.RecallFrame) then LC_CL.RecallFrame:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.RecallFrame = f
    f:SetTitle("Recall: City Administrator")
    f:SetSize(380, 170)
    f:Center()
    f:MakePopup()
    local ends = CurTime() + secs
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(TOP) lbl:SetTall(48) lbl:SetWrap(true)
    lbl.Think = function(s) s:SetText(string.format("%s calls for %s to be removed, and to take the office. The vote closes in %d seconds.", rival, sitting, math.max(0, math.ceil(ends - CurTime())))) end
    for _, b in ipairs({ { "Yes: remove " .. sitting, true }, { "No: " .. sitting .. " stays", false } }) do
        local btn = vgui.Create("DButton", f)
        btn:Dock(TOP) btn:SetTall(34) btn:DockMargin(0, 4, 0, 0)
        btn:SetText(b[1])
        btn.DoClick = function() net.Start("lc_recall_vote") net.WriteBool(b[2]) net.SendToServer() f:Remove() end
    end
end)

net.Receive("lc_election", function()
    local secs = net.ReadFloat()
    local n = net.ReadUInt(6)
    local cands = {}
    for _ = 1, n do cands[#cands + 1] = { i = net.ReadUInt(6), name = net.ReadString() } end
    if IsValid(LC_CL.ElectionFrame) then LC_CL.ElectionFrame:Remove() end
    local f = vgui.Create("DFrame")
    LC_CL.ElectionFrame = f
    f:SetTitle("Election: City Administrator")
    f:SetSize(360, 80 + #cands * 44)
    f:Center()
    f:MakePopup()
    local ends = CurTime() + secs
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(TOP)
    lbl:SetTall(24)
    lbl.Think = function(s) s:SetText(string.format("Vote for one. The vote closes in %d seconds.", math.max(0, math.ceil(ends - CurTime())))) end
    for _, c in ipairs(cands) do
        local b = vgui.Create("DButton", f)
        b:Dock(TOP)
        b:SetTall(38)
        b:DockMargin(0, 4, 0, 0)
        b:SetText(c.name)
        b.DoClick = function()
            net.Start("lc_election_vote") net.WriteUInt(c.i, 6) net.SendToServer()
            f:Remove()
        end
    end
end)

net.Receive("lc_admin_office", function()
    local t = ReadCompressed() or {}
    local menu = DermaMenu()
    -- the sealed directives (cl_livingcity_directives.lua), and the orders their riddles need
    local sd = menu:AddOption("Sealed directives", function() net.Start("lc_directive_act") net.WriteString("open") net.WriteString("") net.SendToServer() end)
    sd:SetIcon("icon16/email.png")
    local od, oo = menu:AddSubMenu("Orders")
    oo:SetIcon("icon16/script.png")
    od:AddOption("Shut down the grid (a blackout, 15 minutes)", function() Act("blackout") end)
    od:AddOption("Restore the power", function() Act("lift") end)
    od:AddOption("Stand down the morticians (20 minutes)", function() Act("morticians") end)
    od:AddOption("Ban weedkiller (20 minutes)", function() Act("weedkiller") end)
    od:AddOption("Declare a Day of Cleansing", function() Act("cleansing") end)
    od:AddOption("Permit Father Grigori's flock to worship", function() Act("worship") end)
    od:AddOption("An amnesty: open every cell", function() Act("amnesty") end)
    local ev, o1 = menu:AddSubMenu("Call a city event")
    o1:SetIcon("icon16/bell.png")
    ev:AddOption("A curfew", function() Act("event", "curfew") end)
    ev:AddOption("A ration day", function() Act("event", "rations") end)
    ev:AddOption("An inspection sweep", function() Act("event", "sweep") end)
    ev:AddOption("A Combine parade", function() Act("event", "parade") end)
    local ra, o2 = menu:AddSubMenu("Rations for the hour")
    o2:SetIcon("icon16/cake.png")
    ra:AddOption("Generous (full packets for all)", function() Act("rations", "generous") end)
    ra:AddOption("Austere (short packets for all)", function() Act("rations", "austere") end)
    ra:AddOption("As usual", function() Act("rations", "normal") end)
    local pr, o3 = menu:AddSubMenu("Commissary prices for the hour")
    o3:SetIcon("icon16/money.png")
    for _, f in ipairs({ 0.75, 0.9, 1, 1.1, 1.25 }) do pr:AddOption(string.format("%d%%", f * 100), function() Act("prices", tostring(f)) end) end
    local jb, o4 = menu:AddSubMenu("A Union job bonus for the hour")
    o4:SetIcon("icon16/coins.png")
    for _, j in ipairs(t.jobs or {}) do jb:AddOption(j.name, function() Act("bonus", j.id) end) end
    menu:AddSpacer()
    for _, p in ipairs(t.people or {}) do
        p.ent = Entity(p.idx or 0)
        local sub, o = menu:AddSubMenu(p.name .. (p.wanted and "  (wanted)" or ""))
        o:SetIcon("icon16/user.png")
        sub:AddOption("Commend (+15 standing)", function() Act("commend", "15", p.ent) end)
        sub:AddOption("Censure (-15 standing)", function() Act("censure", "15", p.ent) end)
        if p.wanted then sub:AddOption("Pardon", function() Act("pardon", "", p.ent) end) end
        sub:AddOption("A week's free housing", function() Act("housing", "", p.ent) end)
        sub:AddOption("A curfew permit", function() Act("permit", "", p.ent) end)
    end
    menu:Open()
end)
