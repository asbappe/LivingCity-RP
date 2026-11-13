--[[
    Living City (client): struggling against an arrest (sv_livingcity_arrest.lua)

    While a struggle lasts, E (your use key) is a press in the struggle
    instead of opening anything. Nothing else is taken over: the mouse and the
    camera stay yours.

    Who's winning is felt, not shown on a bar (the owner, 12 November: "if we
    could find a different way to illustrate or show or infer progress or at
    least struggling other than a bar, then yes please"): every press jolts
    the view with a scuffle, the edges of the screen close in as you lose and
    open as you win, a line says what your body feels, and a heartbeat comes
    in as time runs out. lc_struggle_bar 1 (your own client) brings the old
    bar back.
]]

LC_CL = LC_CL or {}
LC_CL.Struggle = nil -- { role, other, endT, mine, theirs, ratio, margin }

local cvBar = CreateClientConVar("lc_struggle_bar", "0", true, false,
    "1: show the old bar while struggling against cuffs or working at them; 0: feel it instead (jolts, the screen's edges, sounds)")
function LC_CL.StruggleBar() return cvBar:GetBool() end

-- A tug you feel: a small jolt of the view and a scuffle. (Also used for working at the cuffs: cl_livingcity_cuffed.lua.)
local SCUFFLE = { "physics/body/body_medium_impact_soft1.wav", "physics/body/body_medium_impact_soft2.wav",
    "physics/body/body_medium_impact_soft3.wav", "physics/body/body_medium_impact_soft5.wav" }
function LC_CL.FeltTug(strength, snd, pitch)
    local me = LocalPlayer()
    if not IsValid(me) then return end
    if util.ScreenShake then util.ScreenShake(me:GetPos(), strength or 2, 12, 0.18, 64) end
    if me.EmitSound then me:EmitSound(snd or SCUFFLE[math.random(#SCUFFLE)], 55, pitch or math.random(92, 108), 0.35) end
end

-- The screen's edges darkened by an amount from 0 to 1 (how much it's going against you).
local GRAD = { u = Material("vgui/gradient-u"), d = Material("vgui/gradient-d"), l = Material("vgui/gradient-l"), r = Material("vgui/gradient-r") }
function LC_CL.ClosingEdges(amount, tint)
    amount = math.Clamp(amount or 0, 0, 1)
    if amount <= 0.01 then return end
    local w, h = ScrW(), ScrH()
    local c = tint or color_black
    surface.SetDrawColor(c.r, c.g, c.b, 235 * amount)
    local dy, dx = h * (0.12 + 0.3 * amount), w * (0.1 + 0.28 * amount)
    surface.SetMaterial(GRAD.u) surface.DrawTexturedRect(0, 0, w, dy)
    surface.SetMaterial(GRAD.d) surface.DrawTexturedRect(0, h - dy, w, dy)
    surface.SetMaterial(GRAD.l) surface.DrawTexturedRect(0, 0, dx, h)
    surface.SetMaterial(GRAD.r) surface.DrawTexturedRect(w - dx, 0, dx, h)
end

-- What it feels like, by how the struggle is going (share: the resister's, past half they're free).
function LC_CL.StruggleFeel(s, share)
    local resist = s.role == "resist"
    local mineShare = resist and share or (1 - share)
    if resist then
        if mineShare < 0.25 then return "They're forcing your arms behind your back."
        elseif mineShare < 0.42 then return "Their grip is tight on your wrists."
        elseif mineShare < 0.5 then return "You're twisting loose..."
        end
        return "Their grip is slipping!"
    end
    if mineShare < 0.25 then return s.other .. " is tearing free of you."
    elseif mineShare < 0.42 then return s.other .. " is twisting in your hands."
    elseif mineShare < 0.5 then return "You've nearly got their arms..."
    end
    return "You've got them pinned."
end

net.Receive("lc_struggle", function()
    if not net.ReadBool() then LC_CL.Struggle = nil return end
    local s = {
        role = net.ReadString(), other = net.ReadString(), endT = net.ReadFloat(),
        mine = net.ReadUInt(10), theirs = net.ReadUInt(10), ratio = net.ReadFloat(), margin = net.ReadUInt(4),
    }
    -- (presses not yet counted on the server stay on the bar)
    local old = LC_CL.Struggle
    if old and old.role == s.role and old.mine > s.mine and old.endT == s.endT then s.mine = old.mine end
    LC_CL.Struggle = s
end)

local function Active()
    local s = LC_CL.Struggle
    if s and CurTime() > s.endT + 1 then LC_CL.Struggle = nil return nil end
    return s
end

-- The resister's share of the tug: past half, they break free.
function LC_CL.StruggleShare(s)
    local r = s.role == "resist" and s.mine or s.theirs
    local o = s.role == "resist" and s.theirs or s.mine
    local need = o * s.ratio + s.margin
    return r / math.max(1, r + need)
end

hook.Add("PlayerBindPress", "LivingCityStruggle", function(_, bind, pressed)
    local s = Active()
    if not s or not pressed or not bind or not string.find(bind, "+use", 1, true) then return end
    if CurTime() > s.endT then return true end
    s.mine = s.mine + 1
    if not cvBar:GetBool() then LC_CL.FeltTug(1.5 + math.random()) end
    net.Start("lc_struggle_press")
    net.SendToServer()
    return true
end)

-- (made once here, not every frame)
local C_140_220_140 = Color(140, 220, 140)
local C_16_18_22_225 = Color(16, 18, 22, 225)
local C_180_60_50 = Color(180, 60, 50)
local C_220_200_120 = Color(220, 200, 120)
local C_230_140_120 = Color(230, 140, 120)
local C_235_235_235 = Color(235, 235, 235)
local C_40_42_48 = Color(40, 42, 48)
local C_235_220_200 = Color(235, 220, 200)

-- Felt, not a bar: the edges close in as it goes against you, a line says what your body feels, a heartbeat at the end.
local function PaintFelt(s)
    local resist = s.role == "resist"
    local share = math.Clamp(LC_CL.StruggleShare(s), 0, 1)
    local mineShare = resist and share or (1 - share)
    -- (half and half: a little dark; losing badly: nearly closed; winning: open)
    LC_CL.ClosingEdges(math.Clamp((0.62 - mineShare) * 1.6, 0, 1))
    local cx, y = ScrW() / 2, ScrH() * 0.72
    draw.SimpleTextOutlined(LC_CL.StruggleFeel(s, share), "DermaLarge", cx, y, C_235_220_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    draw.SimpleTextOutlined(resist and ("Fight " .. s.other .. " off: hammer E") or ("Hold " .. s.other .. " down: hammer E"),
        "DermaDefault", cx, y + 28, C_220_200_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    local now = CurTime()
    local left = s.endT - now
    if left > 0 and left < 3 and (s.nextBeat or 0) <= now then
        s.nextBeat = now + 0.45
        local me = LocalPlayer()
        if IsValid(me) and me.EmitSound then me:EmitSound("player/heartbeat1.wav", 50, 100, 0.5) end
    end
end

hook.Add("HUDPaint", "LivingCityStruggle", function()
    local s = Active()
    if not s then return end
    if not cvBar:GetBool() then return PaintFelt(s) end
    local w, h = math.min(520, ScrW() - 32), 96
    local x, y = (ScrW() - w) / 2, ScrH() * 0.68
    draw.RoundedBox(8, x, y, w, h, C_16_18_22_225)
    local resist = s.role == "resist"
    local title = resist and ("Break free of " .. s.other .. ": press E as fast as you can")
        or ("Hold " .. s.other .. " down: press E as fast as you can")
    draw.SimpleText(title, "DermaDefaultBold", x + w / 2, y + 16, C_235_235_235, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    -- the tug: the officer's side from the left, the one resisting from the right, free past the middle
    local bx, by, bw, bh = x + 16, y + 32, w - 32, 22
    local share = math.Clamp(LC_CL.StruggleShare(s), 0, 1)
    local cop, them = Color(70, 110, 170), C_180_60_50
    draw.RoundedBox(4, bx, by, bw, bh, C_40_42_48)
    draw.RoundedBox(4, bx, by, bw * (1 - share), bh, cop)
    draw.RoundedBox(4, bx + bw * (1 - share), by, bw * share, bh, them)
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawRect(bx + bw / 2 - 1, by - 3, 2, bh + 6)
    local winning = (share >= 0.5) == resist
    draw.SimpleText(winning and "You're winning" or "You're losing", "DermaDefault", x + w / 2, y + 66,
        winning and C_140_220_140 or C_230_140_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    -- time left
    local left = math.max(0, s.endT - CurTime())
    local total = math.max(1, s.total or left)
    s.total = s.total or left
    draw.RoundedBox(2, bx, y + h - 12, bw * math.Clamp(left / total, 0, 1), 4, C_220_200_120)
end)
