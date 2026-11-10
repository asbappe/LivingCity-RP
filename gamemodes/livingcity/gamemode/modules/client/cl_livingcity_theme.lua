--[[
    Living City (client): how every window looks, by who you are and where you stand
    (the owner, 10 November: "artistic overhauls of all UI items that are consistent enough across the
    gamemode while still having flavours based on the faction and context").

    One place paints every window's back, title bar and ordinary buttons:
      combine    Civil Protection, the Administration, stalkers: black glass, thin cyan lines, cut corners
      rebel      the Resistance: rust and scrap plate, rivets, a hazard stripe, the lambda
      citizen    citizens and shackled vortigaunts: a grey concrete slab, heavy and plain
      custody    whoever you are, while they question you: black, a hard light, a red bar

    How it reaches windows that paint themselves: every DFrame made while lc_ui_theme is 1 gets the
    "LivingCity" Derma skin (its plain buttons, combo boxes and scroll bars follow), and a frame with its
    own Paint has that Paint run on top of the themed back, with its own full-window box and title strip
    left out (those are what the theme replaces). A window can ask for a look of its own with
    LC_CL.SetTheme(panel, "custody"), or opt out with panel.lcNoTheme = true (the pamphlet does).

    The backs are pictures when they're there (materials/livingcity/ui/<name>.jpg, made by
    _dev/posters/ui.js, sent to players at map start); without them, flat colour.

    Setting (client): lc_ui_theme (1; 0 and every window is as it was).
]]

LC_CL = LC_CL or {}

local cvTheme = CreateClientConVar("lc_ui_theme", "1", true, false, "Windows are drawn in your faction's style (Combine, Resistance, citizen); 0: plain, as before")

local THEMES = {
    combine = {
        bg = Color(9, 15, 22, 248), head = Color(13, 24, 34, 255), plate = Color(20, 34, 48, 255), plateHot = Color(28, 52, 70, 255),
        line = Color(72, 200, 222, 255), dim = Color(38, 104, 120, 255), text = Color(214, 236, 242, 255), accent = Color(72, 200, 222, 255),
        tint = Color(255, 255, 255, 255), tex = "livingcity/ui/combine.jpg", label = "OVERWATCH LINK  //  SECTOR ACTIVE",
    },
    rebel = {
        bg = Color(36, 25, 18, 248), head = Color(74, 46, 26, 255), plate = Color(62, 41, 26, 255), plateHot = Color(88, 56, 30, 255),
        line = Color(226, 138, 44, 255), dim = Color(118, 72, 36, 255), text = Color(242, 228, 206, 255), accent = Color(232, 145, 42, 255),
        tint = Color(255, 255, 255, 255), tex = "livingcity/ui/rust.jpg", label = "NO GODS  NO MASTERS  NO BENEFACTORS",
    },
    citizen = {
        bg = Color(50, 52, 54, 248), head = Color(84, 87, 89, 255), plate = Color(72, 75, 77, 255), plateHot = Color(92, 96, 99, 255),
        line = Color(126, 130, 132, 255), dim = Color(34, 35, 36, 255), text = Color(228, 228, 222, 255), accent = Color(112, 140, 170, 255),
        tint = Color(255, 255, 255, 255), tex = "livingcity/ui/concrete.jpg", label = "UNION RESIDENT SERVICES",
    },
    custody = {
        bg = Color(5, 7, 9, 252), head = Color(124, 22, 18, 255), plate = Color(22, 26, 30, 255), plateHot = Color(44, 50, 56, 255),
        line = Color(232, 236, 240, 255), dim = Color(110, 116, 122, 255), text = Color(236, 238, 240, 255), accent = Color(206, 52, 42, 255),
        tint = Color(150, 160, 170, 255), tex = "livingcity/ui/combine.jpg", label = "DETAINED.  ANSWER.  COMPLY.",
    },
}
LC_CL.Themes = THEMES

local FACTION_THEME = { cp = "combine", admin = "combine", stalker = "combine", resistance = "rebel", citizen = "citizen", vort = "citizen" }

-- The look for you, now.
function LC_CL.ThemeName()
    local me = LocalPlayer and LocalPlayer()
    local f = IsValid(me) and me.GetNW2String and me:GetNW2String("lcf_faction", "") or ""
    return FACTION_THEME[f] or "citizen"
end

function LC_CL.ThemeOn() return cvTheme:GetBool() and not LC_CL.ThemeBroken end

-- A window with a look of its own, whoever is looking ("custody", "rebel", "combine", "citizen").
function LC_CL.SetTheme(panel, name)
    if IsValid(panel) and THEMES[name] then panel.lcTheme = name end
end

-- The look a panel is drawn in: its own, else its window's, else yours.
local function ThemeOf(panel)
    local p, n = panel, 0
    while p and n < 12 do
        if type(p.lcTheme) == "string" and THEMES[p.lcTheme] then return THEMES[p.lcTheme], p.lcTheme end
        p = p.GetParent and p:GetParent() or nil
        n = n + 1
    end
    local name = LC_CL.ThemeName()
    return THEMES[name], name
end
LC_CL.ThemeOf = ThemeOf

local mats = {}
local function Mat(path)
    if mats[path] == nil then
        mats[path] = false
        if file and file.Exists and file.Exists("materials/" .. path, "GAME") then mats[path] = Material(path, "smooth") end
    end
    return mats[path]
end

if surface and surface.CreateFont then
    surface.CreateFont("LCThemeTiny", { font = "Arial", size = 11, weight = 800 })
end

local HEAD = 24
local SHADE, LIGHT = Color(0, 0, 0, 120), Color(255, 255, 255, 26)

local function Rect(c, x, y, w, h) surface.SetDrawColor(c.r, c.g, c.b, c.a) surface.DrawRect(x, y, w, h) end
local function Rivet(t, x, y)
    Rect(SHADE, x - 3, y - 2, 7, 7)
    Rect(t.dim, x - 3, y - 3, 6, 6)
    Rect(t.line, x - 2, y - 2, 2, 2)
end

-- The back of a window: its picture (or flat colour), its title bar, its edges.
local function PaintBack(t, name, w, h)
    local m = Mat(t.tex)
    if m and not m:IsError() then
        surface.SetDrawColor(t.tint.r, t.tint.g, t.tint.b, 255)
        surface.SetMaterial(m)
        surface.DrawTexturedRect(0, 0, w, h)
        if draw and draw.NoTexture then draw.NoTexture() end
    else
        Rect(t.bg, 0, 0, w, h)
    end
    Rect(t.head, 0, 0, w, HEAD)
    local wide = w >= 430
    if name == "combine" then
        -- thin light, cut corners, a faint scan
        for y = HEAD + 2, h - 2, 4 do Rect(Color(255, 255, 255, 5), 1, y, w - 2, 1) end
        surface.SetDrawColor(t.dim.r, t.dim.g, t.dim.b, 255) surface.DrawOutlinedRect(0, 0, w, h)
        Rect(t.line, 0, HEAD - 2, w, 2)
        Rect(t.line, 0, 0, 16, 2) Rect(t.line, 0, 0, 2, 16) Rect(t.line, w - 16, h - 2, 16, 2) Rect(t.line, w - 2, h - 16, 2, 16)
        Rect(t.line, 0, h - 2, 5, 2) Rect(t.line, w - 5, 0, 5, 2)
        for i = 0, 5 do Rect(i % 2 == 0 and t.line or t.dim, 8 + i * 7, h - 7, 5, 3) end
    elseif name == "rebel" then
        -- welded plate: a heavy edge, rivets, a hazard end to the title bar
        Rect(SHADE, 0, 0, w, 3) Rect(SHADE, 0, h - 3, w, 3) Rect(SHADE, 0, 0, 3, h) Rect(SHADE, w - 3, 0, 3, h)
        Rect(t.dim, 3, HEAD, w - 6, 1) Rect(LIGHT, 3, 3, w - 6, 1)
        Rect(t.line, 0, HEAD - 2, w, 2)
        Rect(SHADE, 3, HEAD, w - 6, 3)
        for x = w - 124, w - 108, 16 do
            if wide and draw and draw.NoTexture and surface.DrawPoly then
                draw.NoTexture()
                surface.SetDrawColor(t.accent.r, t.accent.g, t.accent.b, 230)
                surface.DrawPoly({ { x = x, y = HEAD - 3 }, { x = x + 8, y = 3 }, { x = x + 14, y = 3 }, { x = x + 6, y = HEAD - 3 } })
            end
        end
        Rivet(t, 9, HEAD + 9) Rivet(t, w - 9, HEAD + 9) Rivet(t, 9, h - 9) Rivet(t, w - 9, h - 9)
        for x = 90, w - 90, 120 do Rivet(t, x, h - 9) end
        Rect(Color(0, 0, 0, 60), 20, h - 22, math.floor(w * 0.3), 1) Rect(Color(255, 255, 255, 14), 40, HEAD + 16, math.floor(w * 0.22), 1)
    elseif name == "custody" then
        -- a hard light from above, a red bar, nothing else
        for i = 0, 9 do Rect(Color(255, 255, 255, 22 - i * 2), 0, HEAD + i * 5, w, 5) end
        surface.SetDrawColor(t.line.r, t.line.g, t.line.b, 255) surface.DrawOutlinedRect(0, 0, w, h)
        Rect(t.accent, 0, HEAD, w, 2) Rect(t.accent, 0, h - 4, w, 4)
    else
        -- a slab: lighter on top, a dark foot, a form number
        Rect(LIGHT, 0, 0, w, 1) Rect(t.dim, 0, HEAD - 1, w, 1)
        Rect(t.dim, 0, h - 3, w, 3) Rect(t.dim, w - 2, 0, 2, h) Rect(LIGHT, 0, 0, 1, h)
        Rect(t.accent, 0, HEAD, 4, h - HEAD - 3)
        if wide then draw.SimpleText("FORM 27-B", "LCThemeTiny", w - 10, h - 12, t.line, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    end
    if wide and draw and draw.SimpleText then
        draw.SimpleText(t.label, "LCThemeTiny", name == "rebel" and w - 136 or w - 112, HEAD / 2, name == "custody" and t.text or t.line, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

function LC_CL.PaintThemeBack(panel, w, h)
    local t, name = ThemeOf(panel)
    PaintBack(t, name, w, h)
end

-- An ordinary button, a combo box: a plate in the window's look.
local function PaintPlate(panel, w, h)
    local t, name = ThemeOf(panel)
    local hot = panel.Hovered or (panel.IsHovered and panel:IsHovered())
    local down = panel.Depressed or (panel.IsDown and panel:IsDown())
    local off = panel.GetDisabled and panel:GetDisabled()
    local base = (hot and not off) and t.plateHot or t.plate
    Rect(base, 0, 0, w, h)
    if name == "combine" then
        Rect(off and t.dim or t.line, 0, 0, 3, h)
        if hot and not off then surface.SetDrawColor(t.line.r, t.line.g, t.line.b, 255) surface.DrawOutlinedRect(0, 0, w, h) end
    elseif name == "rebel" then
        Rect(LIGHT, 0, 0, w, 1) Rect(SHADE, 0, h - 2, w, 2)
        Rect(t.dim, 4, math.floor(h / 2) - 1, 3, 3) Rect(t.dim, w - 7, math.floor(h / 2) - 1, 3, 3)
        if hot and not off then surface.SetDrawColor(t.line.r, t.line.g, t.line.b, 255) surface.DrawOutlinedRect(0, 0, w, h) end
    elseif name == "custody" then
        surface.SetDrawColor(t.dim.r, t.dim.g, t.dim.b, 255) surface.DrawOutlinedRect(0, 0, w, h)
        if hot and not off then Rect(t.accent, 0, h - 2, w, 2) end
    else
        Rect(t.dim, 0, h - 2, w, 2) Rect(LIGHT, 0, 0, w, 1)
        if hot and not off then Rect(t.accent, 0, 0, 3, h) end
    end
    if down and not off then Rect(Color(t.accent.r, t.accent.g, t.accent.b, 70), 0, 0, w, h) end
    if off then Rect(Color(0, 0, 0, 110), 0, 0, w, h) end
end

------------------------------------------------------------------------
-- The Derma skin: the default one, with windows, buttons, combo boxes and scroll bars repainted
------------------------------------------------------------------------

local function DefineSkin()
    if not (derma and derma.DefineSkin and derma.GetNamedSkin and table.Copy) then return false end
    local base = derma.GetNamedSkin("Default")
    if not base then return false end
    local SKIN = table.Copy(base)
    SKIN.PrintName = "Living City"
    SKIN.Author = "Living City"
    SKIN.Colours = SKIN.Colours or {}
    local light, dim = Color(232, 230, 222, 255), Color(150, 150, 146, 255)
    SKIN.Colours.Button = { Normal = light, Hover = Color(255, 255, 255, 255), Down = Color(255, 255, 255, 255), Disabled = dim }
    SKIN.Colours.Window = { TitleActive = light, TitleInactive = dim }
    function SKIN:PaintFrame(panel, w, h) LC_CL.PaintThemeBack(panel, w, h) end
    function SKIN:PaintButton(panel, w, h)
        if panel.m_bBackground == false then return end
        PaintPlate(panel, w, h)
    end
    function SKIN:PaintComboBox(panel, w, h) PaintPlate(panel, w, h) end
    function SKIN:PaintVScrollBar(panel, w, h) local t = ThemeOf(panel) Rect(Color(0, 0, 0, 90), 0, 0, w, h) Rect(t.dim, 0, 0, 1, h) end
    function SKIN:PaintScrollBarGrip(panel, w, h) local t = ThemeOf(panel) Rect(t.plateHot, 1, 0, w - 2, h) Rect(t.line, 1, 0, w - 2, 2) end
    function SKIN:PaintButtonUp(panel, w, h) local t = ThemeOf(panel) Rect(t.plate, 0, 0, w, h) Rect(t.line, math.floor(w / 2) - 3, math.floor(h / 2), 6, 2) end
    function SKIN:PaintButtonDown(panel, w, h) local t = ThemeOf(panel) Rect(t.plate, 0, 0, w, h) Rect(t.line, math.floor(w / 2) - 3, math.floor(h / 2) - 1, 6, 2) end
    derma.DefineSkin("LivingCity", "Living City: windows in your faction's style", SKIN)
    return true
end
local skinOK = DefineSkin()
LC_CL.ThemeSkin = skinOK

------------------------------------------------------------------------
-- Windows that paint themselves: their Paint runs over the themed back, minus its own back and title strip
------------------------------------------------------------------------

local function Themed(old)
    return function(self, w, h)
        if not LC_CL.ThemeOn() or self.lcNoTheme == true then return old(self, w, h) end
        local okB, errB = pcall(LC_CL.PaintThemeBack, self, w, h)
        if not okB then
            LC_CL.ThemeBroken = true
            print("[Living City] window styles are off after an error: " .. tostring(errB))
            return old(self, w, h)
        end
        -- (their own full-window box and title strip are what the theme stands in for: skip just those)
        local rb, rbx, dr = draw.RoundedBox, draw.RoundedBoxEx, surface.DrawRect
        local function Back(x, y, bw, bh)
            return x == 0 and y == 0 and bw and bh and bw >= w - 1 and (bh >= h - 1 or (bh >= 18 and bh <= 30))
        end
        draw.RoundedBox = function(r, x, y, bw, bh, ...) if Back(x, y, bw, bh) then return end return rb(r, x, y, bw, bh, ...) end
        draw.RoundedBoxEx = function(r, x, y, bw, bh, ...) if Back(x, y, bw, bh) then return end return rbx(r, x, y, bw, bh, ...) end
        surface.DrawRect = function(x, y, bw, bh) if Back(x, y, bw, bh) then return end return dr(x, y, bw, bh) end
        local ok, res = pcall(old, self, w, h)
        draw.RoundedBox, draw.RoundedBoxEx, surface.DrawRect = rb, rbx, dr
        if not ok then
            self.Paint = old -- (it paints itself as it always did, and says why if it still can't)
            return
        end
        return res
    end
end

LC_CL.ThemedPaint = Themed

-- A new window: the skin now, and (a moment later, once whoever made it has set it up) its Paint wrapped.
function LC_CL.ThemeWindow(p)
    if not IsValid(p) or p.lcThemeSet == true then return end
    p.lcThemeSet = true
    if skinOK and p.SetSkin then p:SetSkin("LivingCity") end
    timer.Simple(0, function()
        if not IsValid(p) or p.lcNoTheme == true then
            if IsValid(p) and p.lcNoTheme == true and p.SetSkin then p:SetSkin("Default") end
            return
        end
        -- (only a Paint of its own: the plain DFrame one already goes through the skin)
        local own = p.GetTable and rawget(p:GetTable(), "Paint") or nil
        local cls = vgui.GetControlTable and vgui.GetControlTable("DFrame") or nil
        if own and not (cls and own == cls.Paint) then p.Paint = Themed(own) end
    end)
end

if vgui and vgui.Create and not LC_CL.ThemeCreateWas then
    local create = vgui.Create
    LC_CL.ThemeCreateWas = create
    vgui.Create = function(class, ...)
        local p = create(class, ...)
        if class == "DFrame" and p and cvTheme:GetBool() and not LC_CL.ThemeBroken then
            local ok = pcall(LC_CL.ThemeWindow, p)
            if not ok then LC_CL.ThemeBroken = true end
        end
        return p
    end
end
