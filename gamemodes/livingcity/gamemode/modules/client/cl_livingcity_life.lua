--[[
    Living City (client): the end of a life

    When you die the screen goes dark, and a card says who that person was:

        Ada Grey
        Citizen #12-345

        Lived 3 hours 12 minutes in the city.
        Six people knew her name.
        Shot by a masked Civil Protection unit.

        That person is gone.
        Click to go on.

    Deaths that don't end the person (build mode, custody, the infested,
    permanent death off) get a short card that says why. When you're back,
    your eyes open on the city again. The server sends the card
    (sv_livingcity_life.lua); lc_respawn_secs is how long it stays before you
    can go on.

    Also here, for the quiet HUD (lc_quiet_hud): no kill feed in the corner.
]]

LC_CL = LC_CL or {}

local INK, DIM, ACCENT = Color(232, 226, 210), Color(160, 155, 142), Color(230, 180, 90)
local FADE = 2.5   -- seconds to go dark
local WAKE = 2.2   -- seconds for your eyes to open again

surface.CreateFont("LCObitName", { font = "Trebuchet MS", size = 46, weight = 500 })
surface.CreateFont("LCObitLine", { font = "Trebuchet MS", size = 22, weight = 500 })
surface.CreateFont("LCObitSmall", { font = "Trebuchet MS", size = 17, weight = 500 })

local card, diedAt, wakeAt = nil, 0, -100

local function ReadCompressed()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data or "")
    return json and util.JSONToTable(json) or nil
end

net.Receive("lc_obituary", function()
    local t = ReadCompressed()
    if not istable(t) then return end
    card = t
    diedAt = CurTime()
    card.untilT = diedAt + (tonumber(t.wait) or 12)
end)

function LC_CL.DeathCard() return card end

local WORDS = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve" }

-- "3 hours 12 minutes", "2 days 5 hours", "40 minutes", "less than a minute"
function LC_CL.Span(secs)
    secs = math.floor(tonumber(secs) or 0)
    if secs < 60 then return "less than a minute" end
    local d, h, m = math.floor(secs / 86400), math.floor(secs % 86400 / 3600), math.floor(secs % 3600 / 60)
    local function n(x, one, many) return x == 1 and ("1 " .. one) or (x .. " " .. many) end
    if d > 0 then return n(d, "day", "days") .. (h > 0 and (" " .. n(h, "hour", "hours")) or "") end
    if h > 0 then return n(h, "hour", "hours") .. (m > 0 and (" " .. n(m, "minute", "minutes")) or "") end
    return n(m, "minute", "minutes")
end

-- The lines under the name, in order.
function LC_CL.DeathLines(c)
    local lines = {}
    if not c then return lines end
    if c.gone then
        local her = c.she and "her" or "his"
        local secs = tonumber(c.lived) or 0
        if c.full then
            lines[#lines + 1] = "Lived " .. LC_CL.Span(secs) .. " in the city."
        elseif secs >= 60 then
            lines[#lines + 1] = "Lived at least " .. LC_CL.Span(secs) .. " in the city." -- (someone from before the count began)
        else
            lines[#lines + 1] = "Lived in the city since before anyone kept count."
        end
        local k = tonumber(c.known) or 0
        if k <= 0 then
            lines[#lines + 1] = "Nobody knew " .. her .. " name."
        elseif k == 1 then
            lines[#lines + 1] = "One person knew " .. her .. " name."
        else
            lines[#lines + 1] = (WORDS[k] or tostring(k)) .. " people knew " .. her .. " name."
        end
        if c.cause and c.cause ~= "" then lines[#lines + 1] = c.cause end
    elseif c.note and c.note ~= "" then
        lines[#lines + 1] = c.note
    end
    return lines
end

local function A(col, a) return Color(col.r, col.g, col.b, math.Clamp(a, 0, 255)) end

local function Black(a)
    surface.SetDrawColor(0, 0, 0, math.Clamp(a, 0, 255))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

-- Over the HUD, under the chat (so you can still read it).
hook.Add("PostDrawHUD", "LivingCityDeathCard", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local now = CurTime()
    if ply:Alive() then
        if card then card = nil wakeAt = now end -- back: eyes open
        if now - wakeAt < WAKE then Black(255 * (1 - (now - wakeAt) / WAKE)) end
        return
    end
    if not card then return end
    local t = now - diedAt
    Black(255 * math.Clamp(t / FADE, 0, 1))
    local W, H = ScrW(), ScrH()
    local cx, y = W / 2, H * 0.32
    local a0 = math.Clamp((t - 1.2) / 1.5, 0, 1) * 255
    if a0 <= 0 then return end

    if card.gone then
        draw.SimpleText(card.name or "", "LCObitName", cx, y, A(INK, a0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 40
        if card.cid and card.cid ~= "" then
            draw.SimpleText("Citizen " .. card.cid, "LCObitSmall", cx, y, A(DIM, a0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        y = y + 58
    else
        draw.SimpleText("You died.", "LCObitName", cx, y, A(INK, a0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 64
    end
    -- the lines come one after another
    for i, line in ipairs(LC_CL.DeathLines(card)) do
        local a = math.Clamp((t - 2.2 - 0.9 * i) / 1.2, 0, 1) * 255
        draw.SimpleText(line, "LCObitLine", cx, y, A(INK, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 32
    end

    local by = H * 0.74
    if card.gone then
        local a = math.Clamp((t - 6) / 1.5, 0, 1) * 255
        draw.SimpleText("That person is gone.", "LCObitSmall", cx, by, A(DIM, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    if now >= (card.untilT or 0) then
        local pulse = 0.6 + 0.4 * math.abs(math.sin(now * 2))
        draw.SimpleText("Click to go on.", "LCObitSmall", cx, by + 30, A(ACCENT, 255 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- The quiet HUD: nobody's deaths scroll past in the corner.
hook.Add("DrawDeathNotice", "LivingCityQuietHUD", function()
    if LC_CL.QuietHUD and LC_CL.QuietHUD() then return false end
end)
