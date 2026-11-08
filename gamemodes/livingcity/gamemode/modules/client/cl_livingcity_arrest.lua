--[[
    Living City (client): struggling against an arrest (sv_livingcity_arrest.lua)

    While a struggle lasts, a bar on screen shows who's winning, and E (your
    use key) is a press in the struggle instead of opening anything. Nothing
    else is taken over: the mouse and the camera stay yours.
]]

LC_CL = LC_CL or {}
LC_CL.Struggle = nil -- { role, other, endT, mine, theirs, ratio, margin }

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
hook.Add("HUDPaint", "LivingCityStruggle", function()
    local s = Active()
    if not s then return end
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
