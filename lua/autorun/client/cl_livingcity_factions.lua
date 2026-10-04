--[[
    City Factions (client): faction menu, faction HUD, and name tags.

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

local menu

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
    if IsValid(menu) then menu:Close() end
end

net.Receive("lcf_menu", function()
    local data = ReadCompressed()
    if not data or not LCF then return end
    if IsValid(menu) then menu:Remove() end

    menu = vgui.Create("DFrame")
    menu:SetTitle("Factions")
    menu:SetSize(math.min(ScrW() - 60, 720), math.min(ScrH() - 60, 640))
    menu:Center()
    menu:MakePopup()

    local scroll = vgui.Create("DScrollPanel", menu)
    scroll:Dock(FILL)

    for _, entry in ipairs(data.factions) do
        local f = LCF.Get(entry.id)
        if f then
            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP)
            card:DockMargin(4, 4, 4, 6)
            card:DockPadding(14, 10, 10, 10)
            card.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(24, 26, 32, 235))
                draw.RoundedBox(0, 0, 0, 5, h, f.color)
            end

            local title = vgui.Create("DLabel", card)
            title:SetFont("DermaLarge")
            title:SetTextColor(f.color)
            title:SetText(f.name .. (data.current == f.id and "   (current)" or ""))
            title:SizeToContents()
            title:Dock(TOP)

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
                    local mine = data.current == f.id and data.special == s.id
                    JoinButton(card, mine and "You hold this role" or (sp.ok and ("Take up the role of " .. s.name) or sp.why),
                        sp.ok and not mine, function() Join(f.id, s.id) end)
                end
            end

            card:InvalidateLayout(true)
            card:SizeToChildren(false, true)
        end
    end
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
    local title = special and special.name or ply:GetNW2String("lcf_title", rank.name)
    local text = title
    if title ~= f.name and #f.ranks == 1 then text = f.name end
    local block = ply:GetNW2Int("lc_block", 0)
    if block > 0 then
        local cv = GetConVar("lc_block_name")
        local ok, s = pcall(string.format, cv and cv:GetString() or "Habitation Block %02d", block)
        text = text .. "  |  " .. (ok and s or ("Block " .. block))
    end
    if (special and special.hunted) or (not special and rank.hunted) then text = text .. "  |  hunted" end
    return text, f.color
end

-- Name tags: what you're allowed to see about the person in front of you.
-- Disguises change what everyone else sees. A real unit who looks closely
-- at a "unit" for a few seconds notices the designation isn't on the roster.
local stareEnt, stareSince = nil, 0
local SECURITY = { cp = true, ota = true, admin = true }

hook.Add("HUDDrawTargetID", "LivingCityFactionsTargetID", function()
    if not MyFaction() then return end
    local tr = LocalPlayer():GetEyeTrace()
    local ent = tr.Entity
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
    end

    local x, y = ScrW() / 2, ScrH() / 2 + 40
    local charName = ent:GetNW2String("lc_char", "")
    draw.SimpleTextOutlined(charName ~= "" and charName or ent:Nick(), "DermaLarge", x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    if title ~= "" then
        draw.SimpleTextOutlined(title, "DermaDefaultBold", x, y + 22, shown and shown.color or color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if flagged then
        draw.SimpleTextOutlined("NOT ON THE ROSTER (search them: baton reload, or !search)", "DermaDefaultBold", x, y + 40,
            Color(255, 90, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    return false
end)
