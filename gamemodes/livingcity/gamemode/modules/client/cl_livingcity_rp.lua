--[[
    Living City (client): in-character chat, who you know, and being down.
]]

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

LC_CL = LC_CL or {}
LC_CL.recog = LC_CL.recog or {}

net.Receive("lc_chat", function()
    local t = ReadCompressed()
    if not t or not t.p then return end
    local args = {}
    for _, p in ipairs(t.p) do
        if type(p) == "table" then args[#args + 1] = Color(p[1] or 255, p[2] or 255, p[3] or 255) else args[#args + 1] = p end
    end
    chat.AddText(unpack(args))
end)

net.Receive("lc_recog", function()
    local t = ReadCompressed() or {}
    LC_CL.recog = {}
    for _, cid in ipairs(t.cids or {}) do LC_CL.recog[cid] = true end
end)

-- Do I know this person's name?
function LC_CL.Knows(ply)
    if not IsValid(ply) then return false end
    if ply == LocalPlayer() then return true end
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and LC_CL.recog[cid] == true
end

-- What they look like, to someone who doesn't know them.
function LC_CL.Description(ply)
    local own = ply:GetNW2String("lc_desc", "")
    if own ~= "" then return own end
    local m = string.lower(ply:GetModel() or "")
    if string.find(m, "vortigaunt", 1, true) then
        return ply:GetNW2String("lcf_faction", "") == "vort" and "A shackled vortigaunt" or "A vortigaunt"
    end
    local who = (string.find(m, "female", 1, true) or string.find(m, "police_fem", 1, true)) and "woman" or "man"
    local clothes = string.find(m, "group03", 1, true) and "in Resistance gear" or "in Union blue"
    return "A " .. who .. " " .. clothes
end

-- Down and bleeding out
-- (made once here, not every frame)
local C_220_220_220 = Color(220, 220, 220)
local C_255_120_110 = Color(255, 120, 110)
hook.Add("HUDPaint", "LivingCityDownedHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local untilT = ply:GetNW2Float("lc_downed_until", 0)
    local left = untilT - CurTime()
    if left <= 0 then return end
    local w, h = ScrW(), ScrH()
    surface.SetDrawColor(90, 0, 0, math.Clamp(180 - left, 60, 170))
    surface.DrawRect(0, 0, w, h)
    draw.SimpleTextOutlined("YOU'RE DOWN", "DermaLarge", w / 2, h * 0.38, C_255_120_110, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
    draw.SimpleTextOutlined(string.format("Bleeding out: %d:%02d", math.floor(left / 60), math.floor(left % 60)), "DermaDefaultBold", w / 2, h * 0.38 + 34,
        color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined("Someone can help you up (E on you). You can still whisper. !giveup to let go.", "DermaDefault", w / 2, h * 0.38 + 56,
        C_220_220_220, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)

-- A body on the ground that's still breathing
-- (made once here, not every frame)
local C_255_140_120 = Color(255, 140, 120)
hook.Add("HUDPaint", "LivingCityDownedLabel", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if not IsValid(e) or not e:GetNW2Bool("lc_downed_body", false) or tr.HitPos:DistToSqr(ply:EyePos()) > 200 * 200 then return end
    local who = e:GetNW2Entity("lc_downed_ply")
    local name = IsValid(who) and (LC_CL.Knows(who) and who:GetNW2String("lc_char", who:Nick()) or LC_CL.Description(who)) or "Someone"
    local left = IsValid(who) and math.max(0, who:GetNW2Float("lc_downed_until", 0) - CurTime()) or 0
    local x, y = ScrW() / 2, ScrH() / 2 + 40
    draw.SimpleTextOutlined(name, "DermaDefaultBold", x, y, C_255_140_120, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined(string.format("Down, bleeding out (%ds). E to help them up. !drag to drag them.", math.floor(left)), "DermaDefault", x, y + 15,
        color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)
