--[[
    Living City survival and economy (client): hunger and thirst HUD, Credits
    and Civil Standing, Breen's water side effects, the inventory (F2) with
    your stash, the Union Commissary and the black market, and the little
    status lines for radios, disguises, papers, stops and lockpicking.
]]

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

local INK, DIM, ACCENT = Color(232, 226, 210), Color(170, 165, 150), Color(230, 180, 90)
local ILLEGAL = Color(225, 95, 80)
local PANEL = Color(16, 15, 13, 240)
local HUNGER_COL, THIRST_COL = Color(220, 160, 80), Color(90, 170, 230)

------------------------------------------------------------------------
-- HUD
------------------------------------------------------------------------

local function Bar(x, y, w, h, frac, col, label)
    draw.RoundedBox(2, x, y, w, h, Color(40, 38, 34, 220))
    draw.RoundedBox(2, x, y, math.max(0, w * frac), h, frac < 0.15 and Color(220, 60, 60) or col)
    draw.SimpleText(label, "DefaultSmall", x + 4, y + h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- Top-left, compact: the bottom-left belongs to the chat.
LC_CL = LC_CL or {}
LC_CL.HudX, LC_CL.HudY, LC_CL.HudW = 16, 16, 190

hook.Add("HUDPaint", "LivingCityNeedsHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local needs = GetGlobal2Bool("lc_needs_on", false)
    local econ = GetConVar("lc_economy")
    econ = econ and econ:GetBool()
    local ident, identCol
    if LC_CL.IdentityLine then ident, identCol = LC_CL.IdentityLine() end
    if not needs and not econ and not ident then LC_CL.HudBottom = LC_CL.HudY return end

    local x, y, w = LC_CL.HudX, LC_CL.HudY, LC_CL.HudW
    local rows = (needs and 2 or 0) * 14 + (econ and 14 or 0) + (ident and 14 or 0)
    draw.RoundedBox(4, x, y, w, 8 + rows, Color(10, 12, 16, 170))
    local ry = y + 4
    if ident then
        draw.SimpleText(ident, "DefaultSmall", x + 6, ry + 6, identCol or INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        ry = ry + 14
    end
    if needs then
        local h, t = ply:GetNW2Float("lcn_hunger", 100), ply:GetNW2Float("lcn_thirst", 100)
        Bar(x + 4, ry, w - 8, 11, h / 100, HUNGER_COL, "Hunger")
        ry = ry + 14
        Bar(x + 4, ry, w - 8, 11, t / 100, THIRST_COL, "Thirst" .. (ply:GetNW2Float("lcn_parasites", 0) > CurTime() and " (parasites)" or ""))
        ry = ry + 14
    end
    if econ and LCS then
        local standing = ply:GetNW2Int("lce_standing", 0)
        local tier = LCS.TierFor(standing)
        draw.SimpleText(string.format("%d cr", ply:GetNW2Int("lce_credits", 0)), "DefaultSmall", x + 6, ry + 6, ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%s (%d)", tier.name, standing), "DefaultSmall", x + w - 6, ry + 6, tier.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        ry = ry + 14
    end
    LC_CL.HudBottom = ry + 4
end)

local BANDS = { union = "Union band", resistance = "Freq 7", cp = "CP net" }
local DISGUISES = { cp = "Civil Protection uniform", citizen = "citizen clothes" }

hook.Add("HUDPaint", "LivingCityUndergroundHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local now = CurTime()

    -- radio, disguise, papers: one quiet line under the needs box
    local bits = {}
    local band = ply:GetNW2String("lcu_band", "")
    if BANDS[band] then bits[#bits + 1] = "Radio: " .. BANDS[band] .. " (!r)" end
    local d = ply:GetNW2String("lcd_disguise", "")
    if DISGUISES[d] then bits[#bits + 1] = "Wearing " .. DISGUISES[d] end
    local alias = ply:GetNW2String("lcd_alias", "")
    if alias ~= "" then bits[#bits + 1] = "Papers: citizen " .. alias end
    if #bits > 0 then
        draw.SimpleTextOutlined(table.concat(bits, "  |  "), "DefaultSmall", LC_CL.HudX + 2, (LC_CL.HudBottom or 60) + 2,
            d ~= "" and Color(240, 200, 120) or INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
    end

    -- being stopped or searched
    local stopUntil = ply:GetNW2Float("lcu_stop_until", 0)
    if stopUntil > now then
        local cx, cy = ScrW() / 2, ScrH() * 0.28
        draw.RoundedBox(4, cx - 210, cy - 22, 420, 44, Color(20, 30, 45, 220))
        draw.SimpleText("STAND STILL FOR INSPECTION", "DermaLarge", cx, cy, Color(140, 190, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- working a lock
    local pickUntil = ply:GetNW2Float("lcu_pick_until", 0)
    if pickUntil > now then
        local start = ply:GetNW2Float("lcu_pick_start", now)
        local frac = math.Clamp((now - start) / math.max(0.1, pickUntil - start), 0, 1)
        local cx, cy, bw = ScrW() / 2, ScrH() * 0.62, 260
        draw.RoundedBox(3, cx - bw / 2, cy, bw, 14, Color(30, 28, 24, 220))
        draw.RoundedBox(3, cx - bw / 2, cy, bw * frac, 14, ACCENT)
        draw.SimpleTextOutlined(ply:GetNW2String("lcu_progress", "Working the lock... keep looking at it"), "DermaDefault", cx, cy - 4, INK,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
    end
end)

------------------------------------------------------------------------
-- Breen's water, and coffee
------------------------------------------------------------------------

local dizzyUntil, dizzyStart, warmUntil = 0, 0, 0

net.Receive("lcn_effect", function()
    local kind, forget = net.ReadString(), net.ReadBool()
    if kind == "breen" then
        dizzyStart, dizzyUntil = CurTime(), CurTime() + 25
        if forget then chat.AddText(Color(150, 170, 220), "Everything feels... pleasant. What were you doing?") end
    elseif kind == "coffee" then
        warmUntil = CurTime() + 30
        chat.AddText(Color(220, 180, 120), "Real coffee. For a moment you remember what mornings used to be.")
    end
end)

local function DizzyAmount()
    local now = CurTime()
    if now > dizzyUntil then return 0 end
    local fadeIn = math.Clamp((now - dizzyStart) / 3, 0, 1)
    local fadeOut = math.Clamp((dizzyUntil - now) / 6, 0, 1)
    return fadeIn * fadeOut
end

hook.Add("RenderScreenspaceEffects", "LivingCityDizzy", function()
    local d = DizzyAmount()
    if d > 0 then
        DrawMotionBlur(0.12, 0.85 * d, 0.02)
        DrawColorModify({
            ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0.02 * d,
            ["$pp_colour_brightness"] = 0.03 * d, ["$pp_colour_contrast"] = 1 - 0.1 * d,
            ["$pp_colour_colour"] = 1 - 0.45 * d, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })
    end
    if CurTime() < warmUntil then
        local w = math.Clamp((warmUntil - CurTime()) / 30, 0, 1)
        DrawColorModify({
            ["$pp_colour_addr"] = 0.03 * w, ["$pp_colour_addg"] = 0.015 * w, ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1, ["$pp_colour_colour"] = 1 + 0.15 * w,
            ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })
    end
end)

hook.Add("CalcView", "LivingCityDizzy", function(ply, pos, angles, fov)
    local d = DizzyAmount()
    if d <= 0 then return end
    local t = CurTime()
    return {
        origin = pos,
        angles = angles + Angle(math.sin(t * 0.9) * 2 * d, math.sin(t * 0.6) * 1.5 * d, math.sin(t * 1.3) * 6 * d),
        fov = fov + math.sin(t * 0.7) * 5 * d,
    }
end)

------------------------------------------------------------------------
-- Inventory (F2 / !inv)
------------------------------------------------------------------------

local invFrame
local lastInv = { items = {}, size = 12 }
local function Total(t) local n = 0 for _, c in pairs(t or {}) do n = n + c end return n end

local function Act(action, id)
    net.Start("lci_act")
    net.WriteString(action)
    net.WriteString(id or "")
    net.SendToServer()
end

local function OpenInventory()
    if IsValid(invFrame) then invFrame:Remove() end
    if not LCS then return end
    invFrame = vgui.Create("DFrame")
    invFrame:SetTitle("")
    invFrame:SetSize(math.min(ScrW() - 60, 520), math.min(ScrH() - 60, 520))
    invFrame:Center()
    invFrame:MakePopup()
    local count = Total(lastInv.items)
    invFrame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, PANEL)
        draw.SimpleText("POCKETS", "DermaLarge", 16, 14, ACCENT)
        draw.SimpleText(string.format("%d / %d", count, lastInv.size or 12), "DermaDefault", w - 40, 24, DIM, TEXT_ALIGN_RIGHT)
    end

    local scroll = vgui.Create("DScrollPanel", invFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 26, 6, 6)

    if lastInv.disguise then
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 8)
        b:SetTall(30)
        b:SetText("Take off the " .. (DISGUISES[lastInv.disguise] or "disguise"))
        b.DoClick = function() Act("takeoff") end
    end
    if lastInv.alias then
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(4, 0, 0, 6)
        l:SetTextColor(Color(240, 200, 120))
        l:SetText("Your papers say you are citizen " .. lastInv.alias .. ".")
        l:SizeToContents()
    end

    if LocalPlayer():WaterLevel() >= 1 then
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 8)
        b:SetTall(30)
        b:SetText("Drink from the water (it may not be clean)")
        b.DoClick = function() Act("drinkwater") end
    end

    local ids = table.GetKeys(lastInv.items)
    table.sort(ids)
    if #ids == 0 then
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:SetTextColor(DIM)
        l:SetText("Your pockets are empty.")
        l:SizeToContents()
    end
    for _, id in ipairs(ids) do
        local it = LCS.Items[id]
        if it then
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetTall(34)
            row.Paint = function(self, w, h)
                draw.RoundedBox(3, 0, 0, w, h, Color(30, 28, 24, 240))
                local label = string.format("%s  x%d", it.name, lastInv.items[id] or 0)
                draw.SimpleText(label, "DermaDefaultBold", 10, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if it.contraband then
                    surface.SetFont("DermaDefaultBold")
                    local tw = surface.GetTextSize(label)
                    draw.SimpleText("contraband", "DermaDefault", 18 + tw, h / 2, ILLEGAL, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            if it.desc then row:SetTooltip(it.desc) end
            local function Btn(text, action, tip)
                local b = vgui.Create("DButton", row)
                b:Dock(RIGHT)
                b:DockMargin(4, 4, 4, 4)
                b:SetWide(70)
                b:SetText(text)
                if tip then b:SetTooltip(tip) end
                b.DoClick = function() Act(action, id) end
            end
            Btn("Drop", "drop")
            if lastInv.stash then Btn("Stash", "store", "Hide it at home. Searches don't reach your stash.") end
            if it.fillTo then Btn("Fill", "fill") end
            if it.cooksTo then Btn(it.fillTo == nil and it.thirst and "Boil" or "Cook", "cook") end
            if it.hunger or it.thirst or it.cures then Btn(it.hunger and "Eat" or (it.cures and "Take" or "Drink"), "use") end
            if it.wear then Btn("Wear", "wear") end
            if it.tool then Btn("Use", "use", "Look at a locked door first.") end
            if it.papers then Btn("Use", "use", "Become someone else. Clears your wanted status if no unit is watching.") end
            if it.forge then Btn("Forge", "use", "Somewhere private: your own block, or rebel territory.") end
        end
    end

    if lastInv.stash then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 12, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText(string.format("YOUR STASH  %d / %d", Total(lastInv.stash), lastInv.stashSize or 8))
        head:SizeToContents()
        local sids = table.GetKeys(lastInv.stash)
        table.sort(sids)
        if #sids == 0 then
            local l = vgui.Create("DLabel", scroll)
            l:Dock(TOP)
            l:DockMargin(4, 0, 0, 0)
            l:SetTextColor(DIM)
            l:SetText("Nothing hidden here yet.")
            l:SizeToContents()
        end
        for _, id in ipairs(sids) do
            local it = LCS.Items[id]
            if it then
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, 4)
                row:SetTall(30)
                row.Paint = function(self, w, h)
                    draw.RoundedBox(3, 0, 0, w, h, Color(24, 26, 30, 240))
                    draw.SimpleText(string.format("%s  x%d", it.name, lastInv.stash[id] or 0), "DermaDefault", 10, h / 2,
                        it.contraband and ILLEGAL or INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                local b = vgui.Create("DButton", row)
                b:Dock(RIGHT)
                b:DockMargin(4, 3, 4, 3)
                b:SetWide(70)
                b:SetText("Take")
                b.DoClick = function() Act("take", id) end
            end
        end
    end
end

net.Receive("lci_inv", function()
    local t = ReadCompressed()
    if not t then return end
    lastInv = { items = t.items or {}, size = t.size or 12, stash = t.stash, stashSize = t.stashSize,
        disguise = t.disguise, alias = t.alias }
    if t.open or IsValid(invFrame) then OpenInventory() end
end)

------------------------------------------------------------------------
-- Union Commissary
------------------------------------------------------------------------

local shopFrame

net.Receive("lce_shop", function()
    local t = ReadCompressed()
    if not t or not LCS then return end
    if IsValid(shopFrame) then shopFrame:Remove() end
    shopFrame = vgui.Create("DFrame")
    shopFrame:SetTitle("")
    shopFrame:SetSize(math.min(ScrW() - 60, 620), math.min(ScrH() - 60, 600))
    shopFrame:Center()
    shopFrame:MakePopup()
    local tier = LCS.TierFor(t.standing or 0)
    shopFrame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, PANEL)
        draw.SimpleText("UNION COMMISSARY", "DermaLarge", 16, 14, ACCENT)
        draw.SimpleText(string.format("%d credits   |   %s (%d)", t.credits or 0, tier.name, t.standing or 0), "DermaDefault", w - 40, 24, tier.color, TEXT_ALIGN_RIGHT)
    end
    local scroll = vgui.Create("DScrollPanel", shopFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 26, 6, 6)
    for _, g in ipairs(t.goods or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetTall(54)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(30, 28, 24, 240))
            draw.SimpleText(g.name, "DermaDefaultBold", 10, 14, g.ok and INK or DIM)
            draw.SimpleText(g.desc or "", "DermaDefault", 10, 32, DIM)
        end
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:DockMargin(6, 10, 10, 10)
        b:SetWide(150)
        b:SetText(g.ok and (g.price .. " credits") or (g.why or "Unavailable"))
        b:SetEnabled(g.ok == true)
        b.DoClick = function()
            net.Start("lce_buy")
            net.WriteString(g.id)
            net.SendToServer()
        end
    end
end)

------------------------------------------------------------------------
-- The black market
------------------------------------------------------------------------

local marketFrame

net.Receive("lcu_market", function()
    local t = ReadCompressed()
    if not t then return end
    if IsValid(marketFrame) then marketFrame:Remove() end
    marketFrame = vgui.Create("DFrame")
    marketFrame:SetTitle("")
    marketFrame:SetSize(math.min(ScrW() - 60, 620), math.min(ScrH() - 60, 620))
    marketFrame:Center()
    marketFrame:MakePopup()
    marketFrame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(14, 12, 12, 245))
        draw.SimpleText("BLACK MARKET", "DermaLarge", 16, 14, ILLEGAL)
        draw.SimpleText(string.format("%d credits", t.credits or 0), "DermaDefault", w - 40, 24, ACCENT, TEXT_ALIGN_RIGHT)
    end
    local scroll = vgui.Create("DScrollPanel", marketFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 26, 6, 6)

    local function Row(name, desc, buttonText, enabled, onClick, nameCol)
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetTall(desc and 54 or 34)
        row.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, Color(30, 24, 22, 240))
            draw.SimpleText(name, "DermaDefaultBold", 10, desc and 14 or h / 2, nameCol or INK, TEXT_ALIGN_LEFT, desc and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
            if desc then draw.SimpleText(desc, "DermaDefault", 10, 32, DIM) end
        end
        local b = vgui.Create("DButton", row)
        b:Dock(RIGHT)
        b:DockMargin(6, desc and 10 or 4, 10, desc and 10 or 4)
        b:SetWide(150)
        b:SetText(buttonText)
        b:SetEnabled(enabled)
        b.DoClick = onClick
    end

    for _, g in ipairs(t.goods or {}) do
        Row(g.name, g.desc, g.ok and (g.price .. " credits") or (g.why or "Unavailable"), g.ok == true, function()
            net.Start("lcu_buy")
            net.WriteString(g.id)
            net.SendToServer()
        end, g.ok and INK or DIM)
    end

    if #(t.sell or {}) > 0 then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 10, 0, 6)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText("THE DEALER WILL BUY")
        head:SizeToContents()
        for _, sitem in ipairs(t.sell) do
            Row(string.format("%s  x%d", sitem.name, sitem.n), nil, "Sell for " .. sitem.price, true, function()
                net.Start("lcu_sell")
                net.WriteString(sitem.id)
                net.SendToServer()
            end)
        end
    end
end)

------------------------------------------------------------------------
-- No duplicate corpses: birds and headcrabs leave a carcass item, and Living
-- City's people leave a searchable body, so the game's own ragdoll is hidden.
------------------------------------------------------------------------

local CARCASS_CLASSES = {
    npc_pigeon = true, npc_crow = true, npc_seagull = true,
    npc_headcrab = true, npc_headcrab_fast = true, npc_headcrab_black = true, npc_headcrab_poison = true,
}

hook.Add("CreateClientsideRagdoll", "LivingCityNoDuplicates", function(ent, rag)
    if not IsValid(ent) or not IsValid(rag) then return end
    if CARCASS_CLASSES[ent:GetClass()] or ent:GetNW2Bool("lc_noragdoll", false) then
        rag:SetNoDraw(true)
        timer.Simple(0, function() if IsValid(rag) then pcall(rag.Remove, rag) end end)
    end
end)
