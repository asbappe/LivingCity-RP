--[[ Living City: the animation viewer (an owner's tool, not part of the gamemode)

     Put this file in your own game's garrysmod/lua/ folder, start a Single Player game (Sandbox, gm_construct),
     open the console (~) and type:
         sv_allowcslua 1
         lua_openscript_cl lc_animview.lua
     A window opens: the models in the Workshop items below (left), each model's animations (middle, with a search
     box), and a preview that plays the one you click (right). Drag the preview to turn it, mouse wheel to zoom.
     "Show it on" plays the animation on a standard player model instead: dance packs often ship animations in a
     model with no body of its own. "Open a model" takes any model path (the Alyx sleep rig, say). "Save the list"
     writes everything to garrysmod/data/lc_anims.txt, for Claude.

     Add other Workshop items' numbers to WANT. ]]

local function Text(p) local v = IsValid(p) and p:GetValue() return type(v) == "string" and v or "" end

local WANT = { ["3830765710"] = true, ["2538387266"] = true }

local STAND_INS = {
    { "This model itself", nil },
    { "Male citizen (player)", "models/player/group01/male_07.mdl" },
    { "Female citizen (player)", "models/player/group01/female_02.mdl" },
    { "Rebel (player)", "models/player/group03/male_04.mdl" },
    { "Combine soldier (player)", "models/player/combine_soldier.mdl" },
    { "Metrocop (player)", "models/player/police.mdl" },
    { "Kleiner (player)", "models/player/kleiner.mdl" },
}

-- every model in the wanted Workshop items: { wsid, title, path }
local function Models()
    local out = {}
    for _, a in ipairs(engine.GetAddons and engine.GetAddons() or {}) do
        if WANT[tostring(a.wsid)] then
            local files
            if game.MountGMA and a.file then
                local ok, list = game.MountGMA(a.file)
                if ok then files = list end
            end
            for _, f in ipairs(files or {}) do
                if string.match(f, "%.mdl$") then out[#out + 1] = { wsid = tostring(a.wsid), title = a.title or "", path = f } end
            end
        end
    end
    table.sort(out, function(x, y) return x.path < y.path end)
    return out
end

-- every animation a model has: { i, name, secs, act }
local function Sequences(path)
    local out = {}
    if not path or path == "" then return out end
    local e = ClientsideModel(path, RENDERGROUP_OTHER)
    if not IsValid(e) then return out end
    for i = 0, (e:GetSequenceCount() or 0) - 1 do
        out[#out + 1] = { i = i, name = e:GetSequenceName(i) or ("#" .. i), secs = e:SequenceDuration(i) or 0, act = e:GetSequenceActivityName(i) or "" }
    end
    e:Remove()
    return out
end

local function SaveList(models)
    local lines = {}
    for _, m in ipairs(models) do
        lines[#lines + 1] = "== " .. m.wsid .. " " .. m.title .. "  " .. m.path
        for _, s in ipairs(Sequences(m.path)) do
            lines[#lines + 1] = string.format("  seq %d  %s  %.2fs  %s", s.i, s.name, s.secs, s.act)
        end
    end
    file.Write("lc_anims.txt", table.concat(lines, "\n"))
    return #lines
end

if IsValid(LC_ANIMVIEW) then LC_ANIMVIEW:Remove() end
local frame = vgui.Create("DFrame")
LC_ANIMVIEW = frame
frame:SetTitle("Living City: animation viewer")
local W, H = math.min(ScrW() - 40, 1180), math.min(ScrH() - 40, 680)
frame:SetSize(W, H)
frame:Center()
frame:MakePopup()
local models = Models()
local current = { model = nil, seqName = nil, standIn = nil, speed = 1, loop = true }

-- the models
local mlist = vgui.Create("DListView", frame)
mlist:SetPos(8, 30)
mlist:SetSize(330, H - 80)
mlist:SetMultiSelect(false)
mlist:AddColumn("Model (" .. #models .. ")")

local openEntry = vgui.Create("DTextEntry", frame)
openEntry:SetPos(8, H - 44)
openEntry:SetSize(250, 24)
openEntry:SetPlaceholderText("Open a model: models/....mdl")
local openBtn = vgui.Create("DButton", frame)
openBtn:SetPos(262, H - 44)
openBtn:SetSize(76, 24)
openBtn:SetText("Open")

-- the animations
local search = vgui.Create("DTextEntry", frame)
search:SetPos(346, 30)
search:SetSize(330, 24)
search:SetPlaceholderText("Search the animations...")
local slist = vgui.Create("DListView", frame)
slist:SetPos(346, 58)
slist:SetSize(330, H - 66)
slist:SetMultiSelect(false)
slist:AddColumn("#"):SetFixedWidth(36)
slist:AddColumn("Animation")
slist:AddColumn("Secs"):SetFixedWidth(44)

-- the preview
local px = 684
local view = vgui.Create("DModelPanel", frame)
view:SetPos(px, 58)
view:SetSize(W - px - 8, H - 190)
view:SetFOV(40)
local note = ""
local yaw, dist, dragging, lastX = 30, 1, false, 0

local standIn = vgui.Create("DComboBox", frame)
standIn:SetPos(px, 30)
standIn:SetSize(W - px - 8, 24)
standIn:SetValue("Show it on: this model itself")
for _, s in ipairs(STAND_INS) do standIn:AddChoice("Show it on: " .. s[1], s[2] or false) end

local speed = vgui.Create("DNumSlider", frame)
speed:SetPos(px, H - 126)
speed:SetSize(W - px - 8, 24)
speed:SetText("Speed")
speed:SetMin(0.1) speed:SetMax(3) speed:SetDecimals(2) speed:SetValue(1)
speed.OnValueChanged = function(_, v) current.speed = v end

local loop = vgui.Create("DCheckBoxLabel", frame)
loop:SetPos(px, H - 96)
loop:SetText("Loop")
loop:SetValue(true)
loop.OnChange = function(_, v) current.loop = v end

local copyBtn = vgui.Create("DButton", frame)
copyBtn:SetPos(px + 70, H - 100)
copyBtn:SetSize(170, 24)
copyBtn:SetText("Copy the animation's name")
copyBtn.DoClick = function() if current.seqName then SetClipboardText(current.seqName) end end

local saveBtn = vgui.Create("DButton", frame)
saveBtn:SetPos(px + 248, H - 100)
saveBtn:SetSize(W - px - 256, 24)
saveBtn:SetText("Save the list (for Claude)")
saveBtn.DoClick = function()
    local n = SaveList(models)
    note = "Saved " .. n .. " lines to garrysmod/data/lc_anims.txt"
end

local info = vgui.Create("DLabel", frame)
info:SetPos(px, H - 66)
info:SetSize(W - px - 8, 56)
info:SetWrap(true)
info:SetText("Pick a model on the left, then an animation.")

-- show the current choice
local function Frame()
    local e = view.Entity
    if not IsValid(e) then return end
    local mn, mx = e:GetRenderBounds()
    local centre = (mn + mx) / 2
    local size = math.max(24, (mx - mn):Length())
    local a = math.rad(yaw)
    view:SetLookAt(centre)
    view:SetCamPos(centre + Vector(math.cos(a), math.sin(a), 0.25) * size * 1.3 * dist)
end
local function Play()
    local path = current.standIn or current.model
    note = ""
    if not path then return end
    if view:GetModel() ~= path then view:SetModel(path) end
    local e = view.Entity
    if not IsValid(e) then note = "That model can't be loaded." return end
    if current.seqName then
        local seq = e:LookupSequence(current.seqName)
        if not seq or seq < 0 then
            note = "This model doesn't have \"" .. current.seqName .. "\": try another in \"Show it on\"."
        else
            e:ResetSequence(seq)
            e:SetCycle(0)
            e:SetPlaybackRate(1)
        end
    end
    Frame()
end

local all = {}
local function FillSequences()
    slist:Clear()
    local q = string.lower(Text(search))
    for _, s in ipairs(all) do
        if q == "" or string.find(string.lower(s.name), q, 1, true) or string.find(string.lower(s.act), q, 1, true) then
            local line = slist:AddLine(s.i, s.name, string.format("%.1f", s.secs))
            line.lcSeq = s
        end
    end
end
local function PickModel(path)
    current.model, current.seqName = path, nil
    all = Sequences(path)
    FillSequences()
    info:SetText(path .. "\n" .. #all .. " animations. Pick one.")
    Play()
end

for _, m in ipairs(models) do
    local line = mlist:AddLine(m.path)
    line.lcPath = m.path
    line:SetTooltip(m.title .. " (" .. m.wsid .. ")")
end
if #models == 0 then mlist:AddLine("(none found: subscribed? the numbers in WANT?)") end
mlist.OnRowSelected = function(_, _, row) if row.lcPath then PickModel(row.lcPath) end end
openBtn.DoClick = function() local p = string.Trim(Text(openEntry)) if p ~= "" then PickModel(p) end end
search.OnChange = FillSequences
slist.OnRowSelected = function(_, _, row)
    local s = row.lcSeq
    if not s then return end
    current.seqName = s.name
    info:SetText(string.format("%s\n#%d  %s  (%.2f seconds)  %s", current.model or "", s.i, s.name, s.secs, s.act ~= "" and s.act or ""))
    Play()
end
standIn.OnSelect = function(_, _, _, data)
    current.standIn = data or nil
    Play()
end

-- it plays at the chosen speed, looping or holding the last frame; drag to turn, wheel to zoom
local last = RealTime()
function view:LayoutEntity(e)
    local now = RealTime()
    local dt = math.min(0.1, now - last)
    last = now
    if not IsValid(e) then return end
    e:FrameAdvance(dt * current.speed)
    if e:GetCycle() >= 0.999 then
        if current.loop then e:SetCycle(0) else e:SetCycle(0.999) end
    end
    if dragging then
        local x = gui.MouseX()
        yaw = yaw - (x - lastX) * 0.5
        lastX = x
        Frame()
    end
end
function view:OnMousePressed() dragging, lastX = true, gui.MouseX() end
function view:OnMouseReleased() dragging = false end
function view:OnMouseWheeled(d) dist = math.Clamp(dist - d * 0.1, 0.3, 4) Frame() end
local paintWas = view.PaintOver
function view:PaintOver(w, h)
    if paintWas then paintWas(self, w, h) end
    if note ~= "" then draw.SimpleTextOutlined(note, "DermaDefaultBold", w / 2, h - 16, Color(255, 190, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black) end
end

frame.lcParts = { mlist = mlist, slist = slist, view = view, standIn = standIn, saveBtn = saveBtn, openBtn = openBtn, openEntry = openEntry, search = search, copyBtn = copyBtn }
print("[lc_animview] " .. #models .. " models from the Workshop items")
