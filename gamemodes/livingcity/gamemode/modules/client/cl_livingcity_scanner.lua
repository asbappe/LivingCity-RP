--[[
    Living City: the scanner link, as the pilot sees it, and scanner reports,
    as units see them.

    The pilot looks out of the scanner (their body stays at the console, where
    everyone else can see it) through red lenses, like the Civil Protection
    mask's in red: sentence left, the flash's charge, the controls, and the
    nearest suspect in front of the camera, bracketed, with how far it is and
    whether it's close enough to photograph (about ten feet).

    Units see whoever a scanner report caught lit up in red, through walls,
    with what they were reported for, until the report runs out.
]]

local function Scanner(ply)
    local sc = IsValid(ply) and ply:GetNW2Entity("lc_scanner") or nil
    return IsValid(sc) and sc or nil
end

-- (one of the camera's steps: cl_livingcity_view.lua)
LC_CL = LC_CL or {}
LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.scanner = { order = 10, fn = function(ply, view, ctx)
    local sc = Scanner(ply)
    if not sc then return end
    -- where you're looking, not the body's physics angles (which bob and tip as it bumps things)
    local eye = ply:EyeAngles()
    view.angles = Angle(eye.p, eye.y, sc:GetNW2Float("lc_roll", 0))
    view.origin = sc:GetPos() + view.angles:Forward() * 12
    view.drawviewer = true
    ctx.remote = true
end }

-- No hands or gun floating in front of the camera.
hook.Add("PreDrawViewModel", "LivingCityScanner", function()
    if Scanner(LocalPlayer()) then return true end
end)

hook.Add("HUDShouldDraw", "LivingCityScanner", function(name)
    if (name == "CHudWeaponSelection" or name == "CHudAmmo" or name == "CHudSecondaryAmmo" or name == "CHudCrosshair")
        and Scanner(LocalPlayer()) then
        return false
    end
end)

-- The scanner's lenses: the Civil Protection mask's view, in red. Dark at the
-- edges, a red tint, scanlines. Drawn under the HUD so the readouts sit on top.
local CAM = Color(255, 90, 80, 230)
local DIM = Color(255, 120, 110, 120)
local OK = Color(120, 255, 140, 240)
local AMBER = Color(255, 190, 80, 240)

local RED_TINT, RED_EDGE, RED_LINE = { 60, 8, 6, 34 }, { 14, 0, 0, 200 }, { 255, 80, 70, 8 }
local function DrawRedLenses(w, h) LC_CL.DrawLens(w, h, RED_TINT, RED_EDGE, RED_LINE) end

hook.Add("HUDPaintBackground", "LivingCityScannerLenses", function()
    if Scanner(LocalPlayer()) then DrawRedLenses(ScrW(), ScrH()) end
end)

local function Clock(secs)
    secs = math.max(0, math.floor(secs))
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

local function Feet(units) return math.floor(units / 12 + 0.5) end

-- Brackets round whatever's on screen at ent's height.
local function Bracket(ent, col)
    local top = (ent:GetPos() + Vector(0, 0, 76)):ToScreen()
    local bot = ent:GetPos():ToScreen()
    if not top.visible and not bot.visible then return nil end
    local hgt = math.max(24, bot.y - top.y)
    local wid = hgt * 0.5
    local x, y = top.x - wid / 2, top.y
    local c = math.max(6, hgt * 0.2)
    surface.SetDrawColor(col)
    surface.DrawLine(x, y, x + c, y) surface.DrawLine(x, y, x, y + c)
    surface.DrawLine(x + wid, y, x + wid - c, y) surface.DrawLine(x + wid, y, x + wid, y + c)
    surface.DrawLine(x, y + hgt, x + c, y + hgt) surface.DrawLine(x, y + hgt, x, y + hgt - c)
    surface.DrawLine(x + wid, y + hgt, x + wid - c, y + hgt) surface.DrawLine(x + wid, y + hgt, x + wid, y + hgt - c)
    return top.x, y + hgt
end

hook.Add("HUDPaint", "LivingCityScannerPilot", function()
    local ply = LocalPlayer()
    local sc = Scanner(ply)
    if not sc then return end
    local w, h = ScrW(), ScrH()
    local now = CurTime()
    local cx, cy = w / 2, h / 2
    local range = sc:GetNW2Float("lc_photo_range", 128)

    -- the readout, top centre, like the mask's
    draw.SimpleText("CITY SCANNER  ::  LINKED" .. (math.floor(now * 2) % 2 == 0 and "  ::  REC" or ""), "DermaDefaultBold", cx, 8, CAM, TEXT_ALIGN_CENTER)
    local untilT = ply:GetNW2Float("lc_jail_until", 0)
    if untilT > now then
        draw.SimpleText("CUSTODY: " .. Clock(untilT - now) .. "     PHOTO RANGE: " .. Feet(range) .. " FT", "DermaDefault", cx, 24, DIM, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("PHOTO RANGE: " .. Feet(range) .. " FT", "DermaDefault", cx, 24, DIM, TEXT_ALIGN_CENTER)
    end

    -- the flash's charge, where the mask has its biosignal
    local last = sc:GetNW2Float("lc_flash_at", -100)
    local ready = math.Clamp((now - last) / 4, 0, 1)
    local bw = 120
    surface.SetDrawColor(90, 30, 25, 160)
    surface.DrawRect(cx - bw / 2, 42, bw, 3)
    surface.SetDrawColor(ready >= 1 and CAM or AMBER)
    surface.DrawRect(cx - bw / 2, 42, bw * ready, 3)

    -- the reticle
    surface.SetDrawColor(CAM)
    surface.DrawLine(cx - 18, cy, cx - 6, cy) surface.DrawLine(cx + 6, cy, cx + 18, cy)
    surface.DrawLine(cx, cy - 18, cx, cy - 6) surface.DrawLine(cx, cy + 6, cx, cy + 18)

    -- what's in frame: the nearest suspect, and whether it's close enough
    local status, scol
    local t = sc:GetNW2Entity("lc_target")
    if IsValid(t) then
        local d = t:EyePos():Distance(sc:GetPos())
        local why = string.upper(sc:GetNW2String("lc_target_why", "suspect"))
        local col
        if sc:GetNW2Bool("lc_target_done", false) then
            col, status = DIM, why .. ": ALREADY REPORTED"
        elseif d <= range then
            col, status = OK, why .. ": IN RANGE. FLASH TO PHOTOGRAPH"
        else
            col, status = AMBER, string.format("%s: MOVE CLOSER (%d FT, NEED %d)", why, Feet(d), Feet(range))
        end
        scol = col
        local bx, by = Bracket(t, col)
        if bx then
            draw.SimpleTextOutlined(why, "DermaDefaultBold", bx, by + 4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            draw.SimpleTextOutlined(Feet(d) .. " FT", "DermaDefault", bx, by + 18, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
        end
    end
    if sc:GetNW2Bool("lc_ground", false) then
        local done = sc:GetNW2Bool("lc_ground_done", false)
        draw.SimpleTextOutlined(done and "REBEL GROUND: ALREADY REPORTED" or "REBEL GROUND IN FRAME. FLASH TO PHOTOGRAPH",
            "DermaDefaultBold", cx, cy + 60, done and DIM or OK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if sc:GetNW2Bool("lc_jammed", false) then
        draw.SimpleTextOutlined("SIGNAL JAMMED: PICTURES WON'T REACH CIVIL PROTECTION", "DermaDefaultBold", cx, cy + 100, AMBER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if sc:GetNW2Bool("lc_smoke", false) then
        draw.SimpleTextOutlined("SMOKE IN FRAME: NO PICTURE THROUGH IT", "DermaDefaultBold", cx, cy + 80, AMBER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if status then
        draw.SimpleTextOutlined(status, "DermaDefaultBold", cx, cy + 40, scol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end

    draw.SimpleText(ready >= 1 and "FLASH READY" or "CHARGING", "DermaDefaultBold", cx, h - 64, ready >= 1 and CAM or AMBER, TEXT_ALIGN_CENTER)
    draw.SimpleText("WASD fly   SPACE up   CTRL down   SHIFT faster   LMB flash / photograph   R disconnect",
        "DermaDefault", cx, h - 44, DIM, TEXT_ALIGN_CENTER)
    if untilT > now then
        draw.SimpleText("Flash a Civil Protection unit: more time.  Photograph a suspect up close: Civil Standing, never time off.",
            "DermaDefault", cx, h - 28, DIM, TEXT_ALIGN_CENTER)
    end
end)

-- The flash itself: a burst of light at the scanner, seen by everyone near it.
local lastSeen = {}
-- (made once here, not every frame)
local C_255_255_255_60 = Color(255, 255, 255, 60)
hook.Add("Think", "LivingCityScannerFlash", function()
    local now = CurTime()
    for _, sc in ipairs(LC.EntsOf("lc_rscanner")) do
        local at = sc:GetNW2Float("lc_flash_at", -100)
        if at > (lastSeen[sc] or -100) then
            lastSeen[sc] = at
            if now - at < 0.5 then
                local dl = DynamicLight(sc:EntIndex())
                if dl then
                    dl.pos = sc:GetPos()
                    dl.r, dl.g, dl.b = 255, 255, 255
                    dl.brightness = 6
                    dl.decay = 3000
                    dl.size = 600
                    dl.dietime = now + 0.25
                end
                if sc:GetNW2Entity("lc_pilot") == LocalPlayer() then
                    LocalPlayer():ScreenFade(SCREENFADE.IN, C_255_255_255_60, 0.3, 0)
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- Scanner reports, for units
------------------------------------------------------------------------

local RED = Color(255, 70, 60)

-- (only players and NPCs are ever photographed or tipped off, so only they are looked at, not every
-- entity in the map)
local function Spotted()
    local now, list = CurTime(), {}
    for _, set in ipairs({ player.GetAll(), ents.FindByClass("npc_*") }) do
        for _, ent in ipairs(set) do
            if IsValid(ent) and ent:GetNW2Float("lc_spotted_until", 0) > now then list[#list + 1] = ent end
        end
    end
    return list
end

local cache, cacheAt = {}, 0
local function SpottedCached()
    if CurTime() - cacheAt > 0.5 then cache, cacheAt = Spotted(), CurTime() end
    return cache
end

-- Decoded Combine data (sv_livingcity_heist.lua): for a while the Resistance see every unit
local UNIT_CLASSES = { npc_metropolice = true, npc_combine_s = true, npc_hunter = true }
local INTEL_BLUE, intelAt, intelList = Color(80, 170, 255), 0, {}
hook.Add("PreDrawHalos", "LivingCityRebelIntel", function()
    local me = LocalPlayer()
    if GetGlobal2Float("lc_rebel_intel", 0) < CurTime() or me:GetNW2String("lcf_faction", "") ~= "resistance" then return end
    -- who to outline, worked out twice a second (not every frame)
    local now = CurTime()
    if now > intelAt then
        intelAt = now + 0.5
        intelList = {}
        for cls in pairs(UNIT_CLASSES) do
            for _, e in ipairs(LC.EntsOf(cls)) do intelList[#intelList + 1] = e end
        end
        for _, p in ipairs(player.GetAll()) do
            if p ~= me and p:GetNW2Bool("lc_unit", false) then intelList[#intelList + 1] = p end
        end
    end
    local list = {}
    for _, e in ipairs(intelList) do if IsValid(e) then list[#list + 1] = e end end
    if #list > 0 then halo.Add(list, INTEL_BLUE, 2, 2, 1, true, true) end
end)
-- (made once here, not every frame)
local C_120_190_255 = Color(120, 190, 255)
hook.Add("HUDPaint", "LivingCityRebelIntel", function()
    local left = GetGlobal2Float("lc_rebel_intel", 0) - CurTime()
    if left <= 0 or LocalPlayer():GetNW2String("lcf_faction", "") ~= "resistance" then return end
    draw.SimpleTextOutlined(string.format("COMBINE DATA DECODED: UNIT POSITIONS  %d:%02d", math.floor(left / 60), math.floor(left % 60)), "DermaDefaultBold",
        ScrW() / 2, ScrH() * 0.12, C_120_190_255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)

hook.Add("PreDrawHalos", "LivingCityScannerReports", function()
    if not LocalPlayer():GetNW2Bool("lc_unit", false) then return end
    local list = {}
    for _, ent in ipairs(SpottedCached()) do
        if IsValid(ent) and ent ~= LocalPlayer() then list[#list + 1] = ent end
    end
    if #list > 0 then halo.Add(list, RED, 2, 2, 1, true, true) end
end)

-- (made once here, not every frame)
local C_255_200_190 = Color(255, 200, 190)
local C_255_220_180_200 = Color(255, 220, 180, 200)
local V_0_0_84 = Vector(0, 0, 84)
hook.Add("HUDPaint", "LivingCityScannerReports", function()
    local me = LocalPlayer()
    -- a jammer nearby: the radio's static (sv_livingcity_convoy.lua)
    if me:GetNW2Bool("lc_jammed", false) then
        local a = 150 + 100 * math.abs(math.sin(CurTime() * 6))
        draw.SimpleTextOutlined("RADIO JAMMED", "DermaDefaultBold", ScrW() / 2, 62, Color(255, 190, 80, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        draw.SimpleTextOutlined("A jammer is close. Find it (it beeps) and press E to smash it.", "DermaDefault", ScrW() / 2, 78, C_255_220_180_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    if not me:GetNW2Bool("lc_unit", false) then return end
    local now = CurTime()
    for _, ent in ipairs(SpottedCached()) do
        if IsValid(ent) and ent ~= me then
            local s = (ent:GetPos() + V_0_0_84):ToScreen()
            if s.visible then
                local left = ent:GetNW2Float("lc_spotted_until", 0) - now
                draw.SimpleTextOutlined("SCANNER: " .. string.upper(ent:GetNW2String("lc_spotted_why", "suspect")),
                    "DermaDefaultBold", s.x, s.y, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
                draw.SimpleTextOutlined(string.format("%dm  %ds", math.floor(ent:GetPos():Distance(me:GetPos()) / 52.5), math.ceil(left)),
                    "DermaDefault", s.x, s.y + 2, C_255_200_190, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            end
        end
    end
end)
