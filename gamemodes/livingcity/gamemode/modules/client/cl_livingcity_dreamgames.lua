--[[
    Living City: the nightmare dreams you play, your side (sv_livingcity_dreamgames.lua)

      While you're in one: its name, what to do, your lives and the time left, at the top of the
      screen. The Patrol Maze's tokens glow in the corridors (golden ones pulse), and the screen
      goes cold blue while the officers are afraid. Freeze, Citizen says when to stop, in red.
]]

LC_CL = LC_CL or {}

local st -- the game you're in, as the server last said

net.Receive("lc_dreamgame", function()
    local t = net.ReadTable() or {}
    if t.k == "start" then
        st = t
        st.got = {}
    elseif t.k == "got" then
        if st and st.got then st.got[t.i] = true st.left = math.max(0, (st.left or 1) - 1) end
    elseif t.k == "state" then
        if st then for k, v in pairs(t) do if k ~= "k" then st[k] = v end end end
    elseif t.k == "stop" then
        st = nil
    end
end)
function LC_CL.DreamGame() return st end

local glow = Material("sprites/light_glow02_add")
local BLUE, GOLD = Color(120, 210, 255), Color(255, 205, 70)

hook.Add("PostDrawTranslucentRenderables", "LivingCityDreamGames", function(_, sky)
    if sky or not st or not st.tokens then return end
    render.SetMaterial(glow)
    local pulse = 0.75 + 0.25 * math.sin(CurTime() * 6)
    for i, t in ipairs(st.tokens) do
        if not st.got[i] then
            local big = t[4] == 1
            local s = big and 40 * pulse or 16
            render.DrawSprite(Vector(t[1], t[2], t[3]), s, s, big and GOLD or BLUE)
        end
    end
end)

local function Line(text, y, col, font)
    draw.SimpleTextOutlined(text, font or "DermaDefaultBold", ScrW() / 2, y, col or Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 220))
end

hook.Add("HUDPaint", "LivingCityDreamGames", function()
    if not st then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:GetNW2Bool("lc_dreaming", false) then st = nil return end
    local now = CurTime()
    -- the screen's mood
    if st.afraid and st.afraid > now then
        surface.SetDrawColor(40, 80, 255, 35)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    elseif st.phase == "red" then
        surface.SetDrawColor(255, 0, 0, 40)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    local y = 34
    Line(st.name or "A nightmare", y, Color(255, 120, 120), "DermaLarge")
    y = y + 34
    Line(st.goal or "", y, Color(225, 225, 225))
    y = y + 18
    local left = math.max(0, math.floor((st.ends or now) - now))
    local bits = { string.format("Time left: %d:%02d", math.floor(left / 60), left % 60) }
    if (st.maxLives or 1) > 1 then bits[#bits + 1] = string.format("Lives: %d of %d", st.lives or 0, st.maxLives) end
    if st.left then bits[#bits + 1] = string.format("Tokens left: %d", st.left) end
    if st.alive then bits[#bits + 1] = string.format("Still standing: %d", st.alive) end
    Line(table.concat(bits, "     "), y, Color(255, 215, 120))
    -- the big word, in the middle
    if st.phase == "red" then
        Line("FREEZE!", ScrH() * 0.3, Color(255, 60, 60), "DermaLarge")
    elseif st.phase == "green" then
        Line("Move! His back is turned.", ScrH() * 0.3, Color(120, 255, 140), "DermaLarge")
    elseif st.afraid and st.afraid > now then
        Line(string.format("They're afraid of you: catch them! (%d)", math.ceil(st.afraid - now)), ScrH() * 0.3, Color(140, 180, 255), "DermaLarge")
    end
end)
