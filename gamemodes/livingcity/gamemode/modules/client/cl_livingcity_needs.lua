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
LC_CL.HudX, LC_CL.HudY, LC_CL.HudW = 16, 16, 220

-- The quiet HUD (lc_quiet_hud, sh_livingcity_feel.lua): no running score.
-- Rank and XP are on F4, credits and standing at the top of your pockets
-- (F2), and hunger and thirst show once they're getting low, or for a few
-- seconds after you eat or drink.
function LC_CL.QuietHUD()
    local cv = GetConVar("lc_quiet_hud")
    return cv ~= nil and cv:GetBool()
end

local NEEDS_LOW = 50   -- below this, the bars come back
local NEEDS_SHOW = 6   -- seconds they stay up after a change
local lastNeeds = { h = nil, t = nil, untilT = 0 }
function LC_CL.NeedsVisible(ply)
    local h, t = ply:GetNW2Float("lcn_hunger", 100), ply:GetNW2Float("lcn_thirst", 100)
    local now = CurTime()
    -- eating or drinking (a jump up), not the slow drain
    if (lastNeeds.h and h > lastNeeds.h + 2) or (lastNeeds.t and t > lastNeeds.t + 2) then lastNeeds.untilT = now + NEEDS_SHOW end
    lastNeeds.h, lastNeeds.t = h, t
    if not LC_CL.QuietHUD() then return true end
    return h < NEEDS_LOW or t < NEEDS_LOW or ply:GetNW2Float("lcn_parasites", 0) > now or now < lastNeeds.untilT
end

hook.Add("HUDPaint", "LivingCityNeedsHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local quiet = LC_CL.QuietHUD()
    local needs = GetGlobal2Bool("lc_needs_on", false) and LC_CL.NeedsVisible(ply)
    local econ = GetGlobal2Bool("lc_economy_on", true) and not quiet -- (the server's setting: sv_livingcity_economy.lua)
    local ident, identCol
    if LC_CL.IdentityLine then ident, identCol = LC_CL.IdentityLine() end
    local xpFrac, xpLabel, xpCol, xpGain
    if LC_CL.XPInfo then xpFrac, xpLabel, xpCol, xpGain = LC_CL.XPInfo() end -- (still asked, so a gain made while quiet isn't shown later)
    if quiet then xpFrac = nil end
    if not needs and not econ and not ident and not xpFrac then LC_CL.HudBottom = LC_CL.HudY return end

    local x, y, w = LC_CL.HudX, LC_CL.HudY, LC_CL.HudW
    local rows = (needs and 2 or 0) * 14 + (econ and 14 or 0) + (ident and 14 or 0) + (xpFrac and 14 or 0)
    draw.RoundedBox(4, x, y, w, 8 + rows, Color(10, 12, 16, 170))
    local ry = y + 4
    if ident then
        draw.SimpleText(ident, "DefaultSmall", x + 6, ry + 6, identCol or INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        ry = ry + 14
    end
    if xpFrac then
        -- rank and XP toward the next one, always in view
        local c = xpCol or ACCENT
        draw.RoundedBox(2, x + 4, ry, w - 8, 11, Color(40, 38, 34, 220))
        draw.RoundedBox(2, x + 4, ry, math.max(0, (w - 8) * xpFrac), 11, Color(c.r, c.g, c.b, 150))
        draw.SimpleText(xpLabel, "DefaultSmall", x + 8, ry + 5.5, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if xpGain then
            local up = string.sub(xpGain, 1, 1) == "+"
            draw.SimpleTextOutlined(xpGain, "DermaDefaultBold", x + w + 6, ry + 5.5, up and Color(140, 230, 120) or Color(235, 100, 90),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
        end
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
        draw.SimpleText(string.format("Credits: %d", ply:GetNW2Int("lce_credits", 0)), "DefaultSmall", x + 6, ry + 6, ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%s (%d)", tier.name, standing), "DefaultSmall", x + w - 6, ry + 6, tier.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        ry = ry + 14
    end
    LC_CL.HudBottom = ry + 4
end)

local BANDS = { union = "Union band", resistance = "Freq 7", cp = "CP net" }
local DISGUISES = { cp = "Civil Protection uniform", citizen = "citizen clothes", rebel = "Resistance gear" }

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

    -- a unit shouting at you
    local shoutUntil = ply:GetNW2Float("lc_shout_until", 0)
    if shoutUntil > now then
        local cx, cy = ScrW() / 2, ScrH() * 0.36
        local pulse = 0.6 + 0.4 * math.abs(math.sin(now * 8))
        draw.RoundedBox(4, cx - 260, cy - 28, 520, 56, Color(60, 10, 10, 220))
        draw.SimpleTextOutlined(ply:GetNW2String("lc_shout", "STOP RUNNING!"), "DermaLarge", cx, cy,
            Color(255, 70 + 120 * pulse, 70 + 120 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
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

-- (one of the camera's steps, after the field of view is capped: cl_livingcity_view.lua)
LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.dizzy = { order = 40, fn = function(ply, view)
    local d = DizzyAmount()
    if d <= 0 then return end
    local t = CurTime()
    view.angles = view.angles + Angle(math.sin(t * 0.9) * 2 * d, math.sin(t * 0.6) * 1.5 * d, math.sin(t * 1.3) * 6 * d)
    view.fov = view.fov + math.sin(t * 0.7) * 5 * d
end }

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
        if GetGlobal2Bool("lc_economy_on", true) and LCS and LCS.TierFor then
            -- money and standing live here (the quiet HUD keeps them off the screen)
            local me = LocalPlayer()
            local standing = me:GetNW2Int("lce_standing", 0)
            local tier = LCS.TierFor(standing)
            draw.SimpleText(string.format("%d credits     %s (%d)", me:GetNW2Int("lce_credits", 0), tier.name, standing),
                "DermaDefault", w - 40, 8, tier.color or DIM, TEXT_ALIGN_RIGHT)
        end
        if lastInv.maxKg then
            -- weight and large things, against what you can carry
            local heavy = lastInv.kg > lastInv.maxKg + 0.001 or (lastInv.bulky or 0) > (lastInv.maxBulky or 1)
            draw.SimpleText(string.format("%.1f / %.0f kg     large %d / %d", lastInv.kg, lastInv.maxKg, lastInv.bulky or 0, lastInv.maxBulky or 1),
                "DermaDefault", w - 40, 24, heavy and ILLEGAL or DIM, TEXT_ALIGN_RIGHT)
            if heavy then draw.SimpleText("Too much to carry: you're slowed down", "DermaDefault", w - 40, 38, ILLEGAL, TEXT_ALIGN_RIGHT) end
        else
            draw.SimpleText(string.format("%d / %d", count, lastInv.size or 12), "DermaDefault", w - 40, 24, DIM, TEXT_ALIGN_RIGHT)
        end
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
    elseif LocalPlayer():GetNW2String("lcf_faction", "") == "resistance" then
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 8)
        b:SetTall(30)
        b:SetText("Change into plain clothes")
        b.DoClick = function() Act("wear", "plain") end
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

    -- a bin, locker or crate in front of you
    local box = lastInv.container
    if box then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 0, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText(string.upper(box.name or "storage") .. (box.owner and ("  (" .. box.owner .. "'s)") or "")
            .. string.format("   %.1f / %.0f kg", box.kg or 0, box.maxKg or 0))
        head:SizeToContents()
        if not box.mode then
            local l = vgui.Create("DLabel", scroll)
            l:Dock(TOP)
            l:DockMargin(4, 0, 0, 8)
            l:SetTextColor(DIM)
            l:SetText(box.why or "Locked.")
            l:SizeToContents()
        else
            local ids = table.GetKeys(box.items or {})
            table.sort(ids)
            if #ids == 0 then
                local l = vgui.Create("DLabel", scroll)
                l:Dock(TOP)
                l:DockMargin(4, 0, 0, 4)
                l:SetTextColor(DIM)
                l:SetText(box.mode == "search" and "Empty. Nothing to find." or (box.mode == "shop" and "Nothing for sale right now."
                    or (box.kind == "stall" and "Nothing on it. Put things up for sale from your pockets below (Sell)." or "Empty. Put things in from your pockets below.")))
                l:SizeToContents()
            end
            for _, id in ipairs(ids) do
                local it = LCS.Items[id]
                if it then
                    local row = vgui.Create("DPanel", scroll)
                    row:Dock(TOP)
                    row:DockMargin(12, 0, 0, 3)
                    row:SetTall(28)
                    row.Paint = function(self, w, h)
                        draw.RoundedBox(3, 0, 0, w, h, Color(36, 34, 30, 240))
                        local price = box.prices and box.prices[id]
                        draw.SimpleText(string.format("%s  x%d%s", it.name, box.items[id] or 0, price and string.format("   %d credits", price) or ""),
                            "DermaDefault", 10, h / 2, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        if it.contraband then draw.SimpleText("contraband", "DermaDefault", w - 110, h / 2, ILLEGAL, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
                    end
                    if box.mode == "shop" then
                        local b = vgui.Create("DButton", row)
                        b:Dock(RIGHT)
                        b:DockMargin(4, 3, 4, 3)
                        b:SetWide(110)
                        local price = box.prices and box.prices[id] or 0
                        b:SetText("Buy (" .. price .. ")")
                        b:SetEnabled((box.credits or 0) >= price)
                        b.DoClick = function() Act("cbuy", id) end
                    elseif box.mode == "open" or it.contraband then
                        local b = vgui.Create("DButton", row)
                        b:Dock(RIGHT)
                        b:DockMargin(4, 3, 4, 3)
                        b:SetWide(90)
                        b:SetText(box.mode == "search" and "Confiscate" or "Take")
                        b.DoClick = function() Act("ctake", id) end
                        if box.kind == "stall" and box.mode == "open" then
                            local pb = vgui.Create("DButton", row)
                            pb:Dock(RIGHT)
                            pb:DockMargin(4, 3, 0, 3)
                            pb:SetWide(70)
                            pb:SetText("Price")
                            pb.DoClick = function()
                                Derma_StringRequest("Price", "How many credits for one " .. it.name .. "?", tostring(box.prices and box.prices[id] or 10),
                                    function(v) local n = tonumber(v) if n then Act("cstock", id .. "|" .. math.floor(n)) end end)
                            end
                        end
                    end
                end
            end
            if box.kind == "stall" and box.mode == "open" then
                local tillRow = vgui.Create("DPanel", scroll)
                tillRow:Dock(TOP)
                tillRow:DockMargin(12, 2, 0, 4)
                tillRow:SetTall(24)
                tillRow.Paint = nil
                local c = vgui.Create("DButton", tillRow)
                c:Dock(LEFT)
                c:SetWide(200)
                c:SetText(string.format("Collect the takings (%d)", box.till or 0))
                c:SetEnabled((box.till or 0) > 0)
                c.DoClick = function() Act("ccollect") end
                if box.closed then
                    local r = vgui.Create("DButton", tillRow)
                    r:Dock(LEFT)
                    r:DockMargin(6, 0, 0, 0)
                    r:SetWide(200)
                    r:SetText("Closed by the Union: reopen")
                    r.DoClick = function() Act("creopen") end
                end
            end
            if box.mine and box.kind ~= "bin" then
                local b = vgui.Create("DButton", scroll)
                b:Dock(TOP)
                b:DockMargin(12, 2, 0, 4)
                b:SetTall(24)
                b:SetText(box.kind == "locker" and "Give up the locker (empty it first)"
                    or (box.kind == "stall" and "Pack up the stall (empty it first)" or "Pack up the crate (empty it first)"))
                b.DoClick = function() Act("crelease") end
            end
        end
        local gap = vgui.Create("DPanel", scroll)
        gap:Dock(TOP)
        gap:SetTall(8)
        gap.Paint = nil
    end

    -- notes you're carrying
    if lastInv.notes and #lastInv.notes > 0 then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 0, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText("NOTES")
        head:SizeToContents()
        for i, n in ipairs(lastInv.notes) do
            local b = vgui.Create("DButton", scroll)
            b:Dock(TOP)
            b:DockMargin(12, 0, 0, 3)
            b:SetTall(24)
            b:SetText("\"" .. (n.first or "") .. "...\"" .. (n.sig and ("  (" .. n.sig .. ")") or ""))
            b.DoClick = function() if LC_CL.ReadCarriedNote then LC_CL.ReadCarriedNote(i) end end
        end
    end

    -- someone in front of you to hand things to
    local tr = LocalPlayer():GetEyeTrace()
    local giveTo = tr and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(LocalPlayer():EyePos()) < 110 * 110 and tr.Entity or nil

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
            local btnW = 0 -- room the buttons take on the right, so the weight sits beside them
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetTall(34)
            row.Paint = function(self, w, h)
                draw.RoundedBox(3, 0, 0, w, h, Color(30, 28, 24, 240))
                local label = string.format("%s  x%d", it.name, lastInv.items[id] or 0)
                if lastInv.maxKg and LCS.Weight then
                    draw.SimpleText(string.format("%.1f kg%s", LCS.Weight(id) * (lastInv.items[id] or 0), LCS.IsBulky(id) and ", large" or ""),
                        "DermaDefault", w - 8 - btnW, h / 2, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
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
                btnW = btnW + 78
            end
            Btn("Drop", "drop")
            if lastInv.stash then Btn("Stash", "store", "Hide it at home. Searches don't reach your stash.") end
            if box and box.mode == "open" and box.kind == "stall" then
                local b = vgui.Create("DButton", row)
                b:Dock(RIGHT)
                b:DockMargin(4, 4, 4, 4)
                b:SetWide(70)
                b:SetText("Sell")
                b:SetTooltip("Put one on the stall, at a price you set")
                b.DoClick = function()
                    Derma_StringRequest("Sell", "How many credits for one " .. it.name .. "?", "10",
                        function(v) local n = tonumber(v) if n then Act("cstock", id .. "|" .. math.floor(n)) end end)
                end
                btnW = btnW + 78
            elseif box and box.mode == "open" then Btn("Put in", "cput", "Into " .. (box.name or "storage")) end
            if it.place then Btn("Set down", "place", it.desc) end
            if it.fillTo then Btn("Fill", "fill") end
            if it.cooksTo then Btn(it.fillTo == nil and it.thirst and "Boil" or "Cook", "cook") end
            if it.hunger or it.thirst or it.cures then Btn(it.hunger and "Eat" or (it.cures and "Take" or "Drink"), "use") end
            if it.wear then Btn("Wear", "wear") end
            if it.use then Btn(it.useLabel or "Use", "use", it.desc) end
            if giveTo then Btn("Give", "give", "Hand one to the person in front of you") end
            if it.tool then Btn("Use", "use", "Look at a locked door first. Or type !pick, or bind a key to lc_pick.") end

            if it.papers then Btn("Use", "use", "Become someone else. Clears your wanted status if no unit is watching.") end
            if it.forge then Btn("Forge", "use", "Out of sight of any unit.") end
        end
    end

    -- units don't make things: they're issued them (sv_livingcity_cpsupply.lua)
    local me = LocalPlayer()
    local mf = me:GetNW2String("lcf_faction", "")
    local isUnit = me:GetNW2Bool("lc_unit", false) or mf == "cp" or mf == "ota"
    if isUnit then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 12, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText("SUPPLIES")
        head:SizeToContents()
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP)
        l:DockMargin(4, 0, 0, 6)
        l:SetTextColor(INK)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText("Visit a Civil Protection Commissary to be issued supplies: grenades for your rank, ammunition, armour, bandages and your ration.")
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 4)
        b:SetTall(30)
        b:SetText("Mark the nearest Civil Protection Commissary on my screen")
        b.DoClick = function()
            if LC_CL.SendAction then LC_CL.SendAction("waypoint", "cpsupply") end
            if IsValid(invFrame) then invFrame:Remove() end
        end
    end

    -- the lab (sv_livingcity_lab.lua) makes the Resistance's guns; everyone else buys them
    if mf == "resistance" then
        local b = vgui.Create("DButton", scroll)
        b:Dock(TOP)
        b:DockMargin(0, 12, 0, 0)
        b:SetTall(28)
        b:SetText("Guns, ammunition, jammers, radios: the scientist in the lab makes them (mark the lab)")
        b.DoClick = function()
            if LC_CL.SendAction then LC_CL.SendAction("waypoint", "lab") end
            if IsValid(invFrame) then invFrame:Remove() end
        end
    end

    -- what you can make from what you're carrying (by hand: the rest is the lab's, or the black market's)
    if LCS.Recipes and not isUnit then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 12, 0, 4)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(ACCENT)
        head:SetText("MAKE")
        head:SizeToContents()
        for _, r in ipairs(LCS.Recipes) do
            local out = LCS.Items[r.out]
            local parts, can = {}, true
            for nid, n in pairs(r.needs) do
                local have = lastInv.items[nid] or 0
                if have < n then can = false end
                parts[#parts + 1] = string.format("%s %d/%d", string.lower(LCS.Items[nid] and LCS.Items[nid].name or nid), math.min(have, n), n)
            end
            table.sort(parts)
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetTall(38)
            row.Paint = function(self, w, h)
                draw.RoundedBox(3, 0, 0, w, h, Color(30, 28, 24, can and 240 or 140))
                draw.SimpleText(out and out.name or r.out, "DermaDefaultBold", 10, 11, can and INK or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(table.concat(parts, ", ") .. (r.bench and "   (at a workbench)" or (r.private and "   (out of sight)" or "")), "DefaultSmall", 10, 27, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            row:SetTooltip(r.desc or "")
            local b = vgui.Create("DButton", row)
            b:Dock(RIGHT)
            b:DockMargin(4, 6, 4, 6)
            b:SetWide(70)
            b:SetText("Make")
            b:SetEnabled(can)
            b.DoClick = function() Act("make", r.id) end
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
        disguise = t.disguise, alias = t.alias, kg = t.kg, maxKg = t.maxKg, bulky = t.bulky, maxBulky = t.maxBulky,
        container = t.container, notes = t.notes }
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
        draw.SimpleText(t.quartermaster and "THE QUARTERMASTER" or "BLACK MARKET", "DermaLarge", 16, 14, ILLEGAL)
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

    -- at the quartermaster: the Combine's data, decoded (not sold)
    if #(t.decode or {}) > 0 then
        local head = vgui.Create("DLabel", scroll)
        head:Dock(TOP)
        head:DockMargin(4, 4, 0, 6)
        head:SetFont("DermaDefaultBold")
        head:SetTextColor(Color(120, 220, 255))
        head:SetText("DECODE THE COMBINE'S DATA")
        head:SizeToContents()
        for _, d in ipairs(t.decode) do
            Row(string.format("%s  x%d", d.name, d.n), d.desc, "Decode", true, function()
                net.Start("lcu_decode")
                net.WriteString(d.id)
                net.SendToServer()
            end, Color(120, 220, 255))
        end
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
        head:SetText(t.quartermaster and "THE QUARTERMASTER WILL BUY" or "THE DEALER WILL BUY")
        head:SizeToContents()
        for _, sitem in ipairs(t.sell) do
            Row(string.format("%s  x%d", sitem.name, sitem.n), nil, "Sell for " .. sitem.price, true, function()
                net.Start("lcu_sell")
                net.WriteString(sitem.id)
                net.WriteBool(false)
                net.SendToServer()
            end)
            if sitem.n > 1 then
                Row("   all " .. sitem.n, nil, "Sell all for " .. (sitem.price * sitem.n), true, function()
                    net.Start("lcu_sell")
                    net.WriteString(sitem.id)
                    net.WriteBool(true)
                    net.SendToServer()
                end, DIM)
            end
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
