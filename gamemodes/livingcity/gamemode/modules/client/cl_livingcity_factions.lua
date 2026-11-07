--[[
    City Factions (client): the faction list (F4 > Factions), faction HUD, and name tags.

    Name tags show what others are meant to see: low-rank Resistance members
    appear as ordinary citizens to everyone except fellow Resistance.
]]

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

------------------------------------------------------------------------
-- Menu
------------------------------------------------------------------------

local function JoinButton(parent, text, enabled, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText(text)
    b:SetEnabled(enabled)
    b:SetTall(26)
    b:Dock(TOP)
    b:DockMargin(0, 6, 0, 0)
    b.DoClick = onClick
    return b
end

local function Join(fid, sid)
    net.Start("lcf_join")
    net.WriteString(fid)
    net.WriteString(sid or "")
    net.SendToServer()
    if LC_CL and LC_CL.CloseHub then LC_CL.CloseHub() end
end

-- The faction list, built into F4's Factions tab (cl_livingcity_hub.lua)
local function BuildFactions(menu, data)
    -- who holds the city, across the top
    if LC_CL and LC_CL.DrawControlBar then
        local bar = vgui.Create("DPanel", menu)
        bar:Dock(TOP)
        bar:SetTall(58)
        bar:DockMargin(4, 2, 4, 4)
        bar.Paint = function(self, w, h) LC_CL.DrawControlBar(0, 0, w, h) end
    end

    -- admins: the testing tools (XP, ranks, credits, standing)
    if data.admin then
        local tools = vgui.Create("DButton", menu)
        tools:Dock(BOTTOM)
        tools:SetTall(28)
        tools:DockMargin(4, 4, 4, 2)
        tools:SetText("Admin: testing tools (XP, ranks, credits, standing)")
        tools.DoClick = function() RunConsoleCommand("lc_admintools") if LC_CL and LC_CL.CloseHub then LC_CL.CloseHub() end end
    end

    local scroll = vgui.Create("DScrollPanel", menu)
    scroll:Dock(FILL)

    -- (the owner, 1 November: a header for each faction, its roles shown when you open it; was one tall scroll)
    for _, entry in ipairs(data.factions) do
        local f = LCF.Get(entry.id)
        if f then
            local mine = data.current == f.id
            local cat = vgui.Create("DCollapsibleCategory", scroll)
            cat:Dock(TOP)
            cat:DockMargin(4, 4, 4, 2)
            cat:SetExpanded(mine)
            local roles = #(entry.specials or {})
            cat:SetLabel(f.name .. (mine and "   (yours)" or "") .. (roles > 0 and string.format("   %d special role%s", roles, roles == 1 and "" or "s") or ""))
            if type(cat.Header) ~= "function" and IsValid(cat.Header) then
                cat.Header:SetTall(30)
                cat.Header:SetFont("DermaDefaultBold")
                cat.Header:SetTextColor(Color(240, 240, 240))
                cat.Header.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(44, 48, 58, 245) or Color(32, 35, 43, 245))
                    draw.RoundedBox(0, 0, 0, 5, h, f.color)
                    draw.SimpleText(cat:GetExpanded() and "-" or "+", "DermaDefaultBold", w - 14, h / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            cat.Paint = function() end
            local card = vgui.Create("DPanel")
            cat:SetContents(card)
            card:DockPadding(14, 8, 10, 10)
            card.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(24, 26, 32, 235))
                draw.RoundedBox(0, 0, 0, 5, h, f.color)
            end

            local desc = vgui.Create("DLabel", card)
            desc:SetWrap(true)
            desc:SetAutoStretchVertical(true)
            desc:SetTextColor(Color(210, 210, 210))
            desc:SetText(f.desc or "")
            desc:Dock(TOP)
            desc:DockMargin(0, 4, 0, 0)

            if #f.ranks > 1 then
                local r = f.ranks[entry.rank]
                local nextR = f.ranks[entry.rank + 1]
                local info = vgui.Create("DLabel", card)
                info:SetTextColor(Color(170, 170, 170))
                info:SetText(string.format("Your rank: %s   XP %d%s", r.name, entry.xp,
                    nextR and string.format("   (next: %s at %d)", nextR.name, nextR.xp) or "   (highest rank)"))
                info:SizeToContents()
                info:Dock(TOP)
                info:DockMargin(0, 4, 0, 0)
            end

            -- what it asks of you, and how far along you are (Civil Protection: standing, and the records office)
            for _, rq in ipairs(entry.reqs or {}) do
                if (rq.need or 0) > 0 then
                    local bar = vgui.Create("DPanel", card)
                    bar:Dock(TOP)
                    bar:SetTall(22)
                    bar:DockMargin(0, 6, 0, 0)
                    bar.Paint = function(self, w, h)
                        local frac = math.Clamp((rq.have or 0) / rq.need, 0, 1)
                        draw.RoundedBox(3, 0, 0, w, h, Color(40, 42, 50, 240))
                        draw.RoundedBox(3, 0, 0, math.max(0, w * frac), h, frac >= 1 and Color(90, 160, 90, 230) or Color(f.color.r, f.color.g, f.color.b, 170))
                        draw.SimpleText(string.format("%s: %d / %d%s", rq.label, math.max(0, rq.have or 0), rq.need, frac >= 1 and "  (done)" or ""),
                            "DermaDefault", 8, h / 2, Color(235, 235, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                end
            end

            local isCurrent = data.current == f.id and data.special == ""
            JoinButton(card, isCurrent and "You are here" or (entry.ok and ("Join " .. f.name) or entry.why), entry.ok and not isCurrent,
                function() Join(f.id) end)

            for _, sp in ipairs(entry.specials or {}) do
                local s = f.specialsById[sp.id]
                if s then
                    local sl = vgui.Create("DLabel", card)
                    sl:SetFont("DermaDefaultBold")
                    sl:SetTextColor(Color(240, 220, 160))
                    sl:SetText("Special role: " .. s.name .. "  (" .. sp.taken .. "/" .. (s.max or 1) .. " taken)")
                    sl:SizeToContents()
                    sl:Dock(TOP)
                    sl:DockMargin(0, 10, 0, 0)
                    local sd = vgui.Create("DLabel", card)
                    sd:SetWrap(true)
                    sd:SetAutoStretchVertical(true)
                    sd:SetTextColor(Color(200, 200, 200))
                    sd:SetText(s.desc or "")
                    sd:Dock(TOP)
                    -- how a role sits with your rank: on top of it, not instead of it
                    local kit = {}
                    for _, w in ipairs(s.loadout or {}) do kit[#kit + 1] = (string.gsub(string.gsub(w, "^weapon_lc_", ""), "^weapon_", "")) end
                    local myRank = f.ranks[entry.rank] and f.ranks[entry.rank].name or "your rank"
                    local how = vgui.Create("DLabel", card)
                    how:SetWrap(true)
                    how:SetAutoStretchVertical(true)
                    how:SetTextColor(Color(160, 190, 220))
                    how:SetText(string.format("A role, not a rank: you stay %s and keep earning XP toward the next rank. While you hold it you carry its kit%s instead of your rank's%s. To give it up, press \"Join %s\" above: you're back to %s with %s kit.",
                        myRank, #kit > 0 and (" (" .. table.concat(kit, ", ") .. ")") or "", s.models and " and wear its clothes" or "", f.name, myRank, myRank == "your rank" and "its" or "a " .. myRank .. "'s"))
                    how:Dock(TOP)
                    how:DockMargin(0, 2, 0, 0)
                    local mine = data.current == f.id and data.special == s.id
                    JoinButton(card, mine and "You hold this role" or (sp.ok and ("Take up the role of " .. s.name) or sp.why),
                        sp.ok and not mine, function() Join(f.id, s.id) end)
                end
            end

            card:InvalidateLayout(true)
            card:SizeToChildren(false, true)
            -- wrapped text only finds its height a frame or two later: keep the card as tall as what's in it
            -- (it was measured too soon, and a long card, a special role's, was cut off by the next one)
            card.Think = function(self)
                local need = 0
                for _, c in ipairs(self:GetChildren()) do
                    if IsValid(c) and c:IsVisible() then
                        local _, y = c:GetPos()
                        local _, _, _, mb = c:GetDockMargin()
                        need = math.max(need, y + c:GetTall() + (mb or 0))
                    end
                end
                need = need + 10
                if math.abs(self:GetTall() - need) > 1 then
                    self:SetTall(need)
                    if IsValid(cat) then cat:InvalidateLayout(true) end
                end
            end
        end
    end
end

net.Receive("lcf_menu", function()
    local data = ReadCompressed()
    if not data or not LCF then return end
    data.factions = data.factions or {}
    if LC_CL and LC_CL.HubFill then LC_CL.HubFill("factions", function(p) BuildFactions(p, data) end) end
end)

------------------------------------------------------------------------
-- HUD
------------------------------------------------------------------------

local function MyFaction()
    local ply = LocalPlayer()
    if not IsValid(ply) or not LCF then return nil end
    return LCF.Get(ply:GetNW2String("lcf_faction", ""))
end

-- One small line (rank, block, hunted) that the needs HUD stacks under its bars.
-- No big banner: the old panel repeated the faction and rank ("Citizen / Citizen")
-- and sat where the chat lives.
LC_CL = LC_CL or {}
function LC_CL.IdentityLine()
    local f = MyFaction()
    if not f then return nil end
    local ply = LocalPlayer()
    local rank = f.ranks[ply:GetNW2Int("lcf_rank", 1)] or f.ranks[1]
    local special = f.specialsById[ply:GetNW2String("lcf_special", "")]
    -- (a special role is held on top of your rank: "Hacker (Fighter)")
    local title = special and (special.name .. " (" .. rank.name .. ")") or ply:GetNW2String("lcf_title", rank.name)
    local text = title
    if title ~= f.name and #f.ranks == 1 then text = f.name end
    local block = ply:GetNW2Int("lc_block", 0)
    if block > 0 then
        local cv = GetConVar("lc_block_name")
        local ok, s = pcall(string.format, GetGlobal2String("lc_block_name", "") ~= "" and GetGlobal2String("lc_block_name", "") or (cv and cv:GetString()) or "Habitation Block %02d", block)
        text = text .. "  |  " .. (ok and s or ("Block " .. block))
    end
    if (special and special.hunted) or (not special and rank.hunted) then text = text .. "  |  hunted" end
    return text, f.color
end

-- XP toward the next rank, for the HUD bar: fraction filled, the label
-- ("Metrocop  312 / 600 XP"), the faction color, and a "+25 XP" that shows for
-- a few seconds after you earn some. Nil for factions without ranks to climb.
local lastXP, gainAmt, gainUntil = nil, 0, 0
function LC_CL.XPInfo()
    local f = MyFaction()
    if not f or #f.ranks < 2 then lastXP = nil return nil end
    local ply = LocalPlayer()
    local xp = ply:GetNW2Int("lcf_xp", 0)
    local idx = math.Clamp(ply:GetNW2Int("lcf_rank", 1), 1, #f.ranks)
    if lastXP and xp ~= lastXP then
        local d = xp - lastXP
        -- keep adding while the last gain is still on screen
        gainAmt = (CurTime() < gainUntil and gainAmt or 0) + d
        gainUntil = CurTime() + 4
    end
    lastXP = xp
    local rank, nextR = f.ranks[idx], f.ranks[idx + 1]
    local special = f.specialsById[ply:GetNW2String("lcf_special", "")]
    local name = special and (special.name .. " (" .. rank.name .. ")") or rank.name
    local frac, label
    if nextR and nextR.overwatch and not ply:GetNW2Bool("lcf_transhuman", false) then
        -- (the Overwatch ranks wait on the conditioning: the Overwatch Candidate story)
        frac = 1
        label = string.format("%s   %d XP (higher needs the Overwatch conditioning)", name, xp)
    elseif nextR then
        local base, goal = rank.xp or 0, nextR.xp or 0
        frac = goal > base and math.Clamp((xp - base) / (goal - base), 0, 1) or 1
        label = string.format("%s   %d / %d XP", name, xp, goal)
    else
        frac = 1
        label = string.format("%s   %d XP (top rank)", name, xp)
    end
    local gain = CurTime() < gainUntil and gainAmt ~= 0 and string.format("%+d XP", gainAmt) or nil
    return frac, label, f.color, gain, nextR and nextR.name or nil
end

-- Sympathizers: to the Resistance, a small lambda over the heads of the
-- ordinary-looking citizens who are secretly with them (close by, and in
-- sight). Nobody else sees it. (Ask one to keep watch: E, then the talk window.)
LC_CL = LC_CL or {}
function LC_CL.IsSympathizer(ent)
    if not IsValid(ent) or ent:GetClass() ~= "npc_citizen" or not ent:GetNW2Bool("lc_prebel", false) then return false end
    return not string.find(ent:GetNW2String("lc_pjob", ""), "Resistance", 1, true) -- (the fighters wear it openly)
end

local SYMP_COL, SYMP_OUT = Color(235, 150, 70), Color(0, 0, 0, 200)
local sympList, sympNext = {}, 0
local function Lambda(x, y, s, a)
    -- a hand-drawn lambda: the long stroke and the short one, outlined
    for pass = 1, 2 do
        local c = pass == 1 and Color(0, 0, 0, 200 * a) or Color(SYMP_COL.r, SYMP_COL.g, SYMP_COL.b, 255 * a)
        surface.SetDrawColor(c)
        local w = pass == 1 and 2 or 1
        for o = -w, w do
            surface.DrawLine(x - s * 0.5 + o, y - s, x + s * 0.6 + o, y + s)
            surface.DrawLine(x + o, y - s * 0.05, x - s * 0.6 + o, y + s)
        end
    end
end

-- (made once here, not every frame)
local V_0_0_80 = Vector(0, 0, 80)
local V_0_0_82 = Vector(0, 0, 82)
hook.Add("HUDPaint", "LivingCitySympathizers", function()
    local me = LocalPlayer()
    if not IsValid(me) or me:GetNW2String("lcf_faction", "") ~= "resistance" or not me:Alive() then return end
    local now = CurTime()
    if now > sympNext then
        sympNext = now + 0.4
        sympList = {}
        local eye = me:EyePos()
        for _, e in ipairs(ents.FindByClass("npc_citizen")) do
            if LC_CL.IsSympathizer(e) and not e:GetNW2Bool("lc_lookout", false) then
                local head = e:GetPos() + V_0_0_80
                local d = head:Distance(eye)
                if d < 600 then
                    local tr = util.TraceLine({ start = eye, endpos = head, mask = MASK_OPAQUE, filter = { me, e } })
                    if not tr.Hit then sympList[#sympList + 1] = { e = e, d = d } end
                end
            end
        end
    end
    for _, it in ipairs(sympList) do
        if IsValid(it.e) then
            local sp = (it.e:GetPos() + V_0_0_82):ToScreen()
            if sp.visible then Lambda(sp.x, sp.y, 6, math.Clamp(1.2 - it.d / 600, 0.25, 1)) end
        end
    end
end)

-- Name tags: what you're allowed to see about the person in front of you.
-- Disguises change what everyone else sees. A real unit who looks closely
-- at a "unit" for a few seconds notices the designation isn't on the roster.
local stareEnt, stareSince = nil, 0
local SECURITY = { cp = true, admin = true }

if surface and surface.CreateFont then
    surface.CreateFont("LCNameMain", { font = "Tahoma", size = 20, weight = 800, extended = true })
    surface.CreateFont("LCNameSub", { font = "Tahoma", size = 17, weight = 600, extended = true })
end

hook.Add("HUDDrawTargetID", "LivingCityFactionsTargetID", function()
    if not MyFaction() then return end
    local tr = LocalPlayer():GetEyeTrace()
    local ent = tr.Entity
    -- the city's named people: who they are, what they do, and (to the Resistance) who's with us
    if IsValid(ent) and (ent:IsNPC() or ent:GetNW2Bool("lc_sleeper", false)) and tr.HitPos:DistToSqr(tr.StartPos) < 350 * 350 then
        local pname = ent:GetNW2String("lc_pname", "")
        if pname ~= "" then
            local x, y = ScrW() / 2, ScrH() / 2 + 40
            draw.SimpleTextOutlined(pname, "LCNameMain", x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            local job = ent:GetNW2String("lc_pjob", "")
            local doing = ent:GetNW2String("lc_doing", "") -- what they're at right now (sv_livingcity_npcwork.lua)
            if doing ~= "" then job = (job ~= "" and (job .. ", ") or "") .. doing end
            if job ~= "" then
                draw.SimpleTextOutlined(job, "LCNameSub", x, y + 20, Color(190, 190, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            end
            if ent:GetNW2Bool("lc_prebel", false) and LocalPlayer():GetNW2String("lcf_faction", "") == "resistance" then
                local line = "one of ours"
                if ent:GetNW2Bool("lc_lookout", false) then
                    line = "one of ours: keeping watch"
                elseif LC_CL.IsSympathizer and LC_CL.IsSympathizer(ent) then
                    line = LocalPlayer():GetNW2Int("lcf_rank", 1) >= 2 and "one of ours: a sympathizer (E, and ask them to keep watch)" or "one of ours: a sympathizer"
                end
                draw.SimpleTextOutlined(line, "LCNameSub", x, y + 40, Color(235, 150, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            end
        end
        stareEnt = nil
        return false
    end
    if not IsValid(ent) or not ent:IsPlayer() or tr.HitPos:DistToSqr(tr.StartPos) > 500 * 500 then
        stareEnt = nil
        return false
    end
    if ent ~= stareEnt then stareEnt, stareSince = ent, CurTime() end

    local mine = LocalPlayer():GetNW2String("lcf_faction", "")
    local theirs = ent:GetNW2String("lcf_faction", "")
    local title = (mine == theirs) and ent:GetNW2String("lcf_title", "") or ent:GetNW2String("lcf_public_title", "")
    local f = LCF.Get(theirs)
    local shown = f
    if theirs == "resistance" and mine ~= "resistance" and title == "Citizen" then shown = LCF.Get("citizen") end

    local flagged = false
    local disguise = ent:GetNW2String("lcd_disguise", "")
    if disguise == "cp" and mine ~= theirs then
        title = ent:GetNW2String("lcd_title", "CP")
        shown = LCF.Get("cp")
        flagged = SECURITY[mine] and CurTime() - stareSince > 2.5 and tr.HitPos:DistToSqr(tr.StartPos) < 250 * 250
    elseif disguise == "citizen" and mine ~= theirs then
        title = "Citizen"
        shown = LCF.Get("citizen")
    elseif disguise == "rebel" and mine ~= theirs then
        title = "Resistance"
        shown = LCF.Get("resistance")
        -- the Resistance know their own faces
        flagged = mine == "resistance" and CurTime() - stareSince > 2.5 and tr.HitPos:DistToSqr(tr.StartPos) < 250 * 250
        if flagged then
            draw.SimpleTextOutlined("NOT ONE OF OURS", "DermaDefaultBold", ScrW() / 2, ScrH() / 2 + 80, Color(255, 120, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            flagged = false
        end
    end

    local x, y = ScrW() / 2, ScrH() / 2 + 40
    local charName = ent:GetNW2String("lc_char", "")
    -- a name only if they've told you it; otherwise what they look like
    local masked = (theirs == "cp" or disguise == "cp") and theirs ~= "admin"
    local shownName
    if masked then
        shownName = title ~= "" and title or "Civil Protection"
        title = ""
    elseif LC_CL.Knows and not LC_CL.Knows(ent) then
        shownName = LC_CL.Description and LC_CL.Description(ent) or "Someone"
    else
        local alias = ent:GetNW2String("lcd_alias", "")
        shownName = alias ~= "" and ("Citizen " .. alias) or (charName ~= "" and charName or ent:Nick())
    end
    draw.SimpleTextOutlined(shownName, (LC_CL.Knows and not LC_CL.Knows(ent) and not masked) and "DermaDefaultBold" or "DermaLarge", x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    if title ~= "" then
        draw.SimpleTextOutlined(title, "DermaDefaultBold", x, y + 22, shown and shown.color or color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if flagged then
        draw.SimpleTextOutlined("NOT ON THE ROSTER (search them: baton reload, or !search)", "DermaDefaultBold", x, y + 40,
            Color(255, 90, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    -- what units know: a BOLO out on them, hands tied, hands up (sv_livingcity_cp.lua)
    local extra = {}
    if SECURITY[mine] and ent:GetNW2Bool("lc_bolo", false) then extra[#extra + 1] = { "BOLO: " .. ent:GetNW2String("lc_bolo_text", ""), Color(255, 90, 80) } end
    if ent:GetNW2Bool("lc_tied", false) then extra[#extra + 1] = { "Hands cuffed", Color(235, 200, 90) }
    elseif ent:GetNW2Bool("lc_handsup", false) then extra[#extra + 1] = { "Hands up", Color(200, 220, 255) } end
    if ent:GetNW2Bool("lc_afk", false) then extra[#extra + 1] = { "AFK", Color(170, 170, 170) } end
    local legacy = ent:GetNW2String("lc_legacy_title", "")
    if legacy ~= "" then extra[#extra + 1] = { legacy, Color(190, 170, 120) } end -- (many lives behind them: sv_livingcity_progress.lua) -- (idle: sv_livingcity_cityadmin.lua)
    local ey = y + (flagged and 58 or 40)
    for _, e in ipairs(extra) do
        draw.SimpleTextOutlined(e[1], "DermaDefaultBold", x, ey, e[2], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        ey = ey + 18
    end
    return false
end)
