--[[
    Living City: the Endings menu (superadmins): tune the secret endings live

      C > Help > Endings menu, the button in the Living City Editor tool, or
      lc_endings_menu in the console. Pick an ending (the one playing is picked for
      you) and, while it plays:

        The dance   pick one of its moves and a bone on the body map, and turn it
                    with three sliders; the bone lights up on everyone doing that
                    move (yellow, with its axes: red forward, green right, blue up)
                    and in the close-up at the top (drag it to turn round, wheel to
                    zoom). Left and right mirror each other unless you untick it.
                    No ending playing? Tick the stand-in: someone does the move in
                    front of you, only on your screen.
        Settings    every one of the ending's settings, as sliders and boxes, with
                    its default a click away; the song's time, for its sections.
        Just for you   your own volume, calm mode and the like.
        Changes     everything you've changed, to copy and send on, so it can be
                    built in as the new normal.

      A dance's tuning is a turn added to a bone on top of what the code does, so
      the dance keeps moving. The server keeps it and every player's game dances
      the same (sv_livingcity_endingtune.lua).
]]

if SERVER then return end

LC_CL = LC_CL or {}

local data = { bones = {}, shared = {} } -- what the server says (and what you've just changed)
local frame, info
local state = { ending = nil, move = nil, bone = nil, mirror = true, standIn = false, bpm = 120, yaw = 180, dist = 80, lastPlaying = nil }
local seen = {} -- [ent] = CurTime(): someone doing the move being tuned, just now
local standIn

-- the shared settings: one value for everyone's game (the server's), else your own
local SHARED = { lc_bloom_palm = "90", lc_headbang_angle = "35 0 0", lc_shalom_kippah = "6.5 0 -1", lc_shalom_chair = "21 0" }
local SHARED_OF = { bloom = { "lc_bloom_palm" }, water = { "lc_headbang_angle" }, shalom = { "lc_shalom_kippah", "lc_shalom_chair" } }

-- Each ending's moves: { move, what it is }
local MOVES = {
    bloom = { { "ears", "The dance: hands up, wrists flapping, hips swaying" }, { "ears_combine", "The dance, on the Combine's units only (their bones sit differently)" } },
    marrow = { { "club", "Club dance (the kicks)" }, { "rave", "Rave dance (bigger kicks)" } },
    bus = { { "bus", "Sat down, arms up (Base's ZIG riders too)" } },
    base = { { "bus", "Sat in a ZIG, arms up (the Bus's riders too)" } },
    hard = { { "hard", "Party hard (a pose and its mirror image)" } },
    shalom = { { "hora", "The hora: arms on the shoulders, the grapevine" }, { "hora_in", "Rushing into the middle, arms up" }, { "chair", "Up on the chair" } },
    plane = { { "numa", "Numa numa" } },
    fire = { { "fire", "Bent over, behind out, arms pumping (on the ground)" }, { "fly", "Flying on it, Superman style (Pelvis tips the whole body)" } },
    standup = { { "cheer", "The crowd cheering" }, { "hanged", "On the rope, kicking" }, { "limp", "Limp, at the end" } },
    water = { { "bang", "Father Grigori headbanging (the heavy parts)" }, { "groove", "Father Grigori dancing (the calm parts)" } },
}
LC_CL.EndingMoves = MOVES
-- (the moves that are tuned on the Combine's units on their own)
local MOVES_COMBINE = {}
for _, list in pairs(MOVES) do for _, m in ipairs(list) do if string.find(m[1], "_combine$") then MOVES_COMBINE[m[1]] = true end end end

local FULL = { "Head", "Spine2", "Spine", "Pelvis", "R_UpperArm", "R_Forearm", "R_Hand", "L_UpperArm", "L_Forearm", "L_Hand", "R_Thigh", "R_Calf", "L_Thigh", "L_Calf" }
local GRIGORI = { "Head", "Neck1", "Spine2", "Spine1", "Spine", "Pelvis", "R_UpperArm", "R_Forearm", "L_UpperArm", "L_Forearm" }
local HANG = { "Head", "R_UpperArm", "R_Forearm", "L_UpperArm", "L_Forearm", "R_Thigh", "R_Calf", "L_Thigh", "L_Calf" }
local function BonesOf(move)
    if move == "bang" or move == "groove" then return GRIGORI end
    if move == "hanged" or move == "limp" then return HANG end
    return FULL
end

-- where each bone sits on the body map (facing you: their right arm on your left)
local MAP = {
    Head = { 0.5, 0.04, "Head" }, Neck1 = { 0.5, 0.15, "Neck" }, Spine2 = { 0.5, 0.26, "Chest" }, Spine1 = { 0.5, 0.37, "Mid back" },
    Spine = { 0.5, 0.48, "Lower back" }, Pelvis = { 0.5, 0.59, "Hips" },
    R_UpperArm = { 0.14, 0.2, "R upper arm" }, R_Forearm = { 0.14, 0.33, "R forearm" }, R_Hand = { 0.14, 0.46, "R hand" },
    L_UpperArm = { 0.86, 0.2, "L upper arm" }, L_Forearm = { 0.86, 0.33, "L forearm" }, L_Hand = { 0.86, 0.46, "L hand" },
    R_Thigh = { 0.3, 0.73, "R thigh" }, R_Calf = { 0.3, 0.88, "R calf" }, L_Thigh = { 0.7, 0.73, "L thigh" }, L_Calf = { 0.7, 0.88, "L calf" },
}

-- what each of a bone's three turns does (as the playtests showed them)
local function Hints(bone)
    if string.find(bone, "UpperArm", 1, true) then return "Out to the side (right arm: minus, left: plus)", "Raise forward (minus is up)", "Twist" end
    if string.find(bone, "Forearm", 1, true) then return "Swing sideways", "Bend the elbow", "Twist (turns the palm)" end
    if string.find(bone, "Hand", 1, true) then return "Sideways", "Bend the wrist", "Twist" end
    if string.find(bone, "Thigh", 1, true) then return "Out to the side", "Swing forward and back", "Twist" end
    if string.find(bone, "Calf", 1, true) then return "Sideways", "Bend the knee (lifts the foot off the floor)", "Twist" end
    return "Nod (forward and back)", "Tilt side to side", "Twist"
end

local function Other(bone)
    if string.sub(bone, 1, 2) == "R_" then return "L_" .. string.sub(bone, 3) end
    if string.sub(bone, 1, 2) == "L_" then return "R_" .. string.sub(bone, 3) end
end

------------------------------------------------------------------------
-- The tuning itself, used by the dances (cl_livingcity_endings.lua)
------------------------------------------------------------------------

-- The Combine's units (and any pack's Combine models) have bones that sit differently from
-- people's: a move can be tuned for them on its own ("<move>_combine"), on top of the rest.
local function CombineBody(ent)
    local m = string.lower(ent.GetModel and ent:GetModel() or "")
    return string.find(m, "police", 1, true) or string.find(m, "combine", 1, true) or string.find(m, "soldier", 1, true)
        or string.find(m, "elite", 1, true) or string.find(m, "/hla", 1, true) or false
end
LC_CL.EndingCombineBody = CombineBody
local function Add(a, off)
    if not off then return a end
    return Angle(a.p + (off[1] or 0), a.y + (off[2] or 0), a.r + (off[3] or 0))
end
function LC_CL.EndingTuneBone(ent, move, name, a)
    local combine = CombineBody(ent) and true or false
    if frame and (move == state.move and not (combine and MOVES_COMBINE[move .. "_combine"]) or (combine and state.move == move .. "_combine")) then seen[ent] = CurTime() end
    local m = data.bones[move]
    a = Add(a, m and m[name])
    if combine then
        local c = data.bones[move .. "_combine"]
        a = Add(a, c and c[name])
    end
    return a
end

function LC_CL.EndingTunedCV(cv)
    local n = cv.GetName and cv:GetName()
    return (n and data.shared[n]) or cv:GetString()
end

function LC_CL.EndingTuning() return data end
function LC_CL.EndingTuneState() return state end

net.Receive("lc_tune_all", function()
    local t = net.ReadTable()
    if istable(t) then data.bones = istable(t.bones) and t.bones or {} data.shared = istable(t.shared) and t.shared or {} end
end)

local pending = {}
local function Send(kind, a, b, p, y, r)
    local key = kind .. ":" .. tostring(a) .. ":" .. tostring(b)
    pending[key] = { kind, a, b, p, y, r }
    timer.Create("LivingCityTune" .. key, 0.15, 1, function()
        local m = pending[key]
        pending[key] = nil
        if not m then return end
        net.Start("lc_tune_set")
        net.WriteString(m[1])
        net.WriteString(m[2])
        net.WriteString(m[3])
        if m[1] == "bone" then net.WriteFloat(m[4]) net.WriteFloat(m[5]) net.WriteFloat(m[6]) end
        net.SendToServer()
    end)
end

local function SetBone(move, bone, p, y, r)
    data.bones[move] = data.bones[move] or {}
    data.bones[move][bone] = (p ~= 0 or y ~= 0 or r ~= 0) and { p, y, r } or nil
    Send("bone", move, bone, p, y, r)
end

local function BoneOff(move, bone)
    local o = data.bones[move] and data.bones[move][bone]
    return o and o[1] or 0, o and o[2] or 0, o and o[3] or 0
end

------------------------------------------------------------------------
-- The stand-in, and who's doing the move being tuned
------------------------------------------------------------------------

local function DropStandIn()
    if IsValid(standIn) then standIn:Remove() end
    standIn = nil
end

local function StandIn()
    local me = LocalPlayer()
    if not (state.standIn and frame and IsValid(frame) and IsValid(me) and state.move) then DropStandIn() return nil end
    if not IsValid(standIn) then
        -- (a move tuned on the Combine's units on its own: a metrocop stands in)
        local mdl = MOVES_COMBINE[state.move] and "models/player/police.mdl" or me:GetModel()
        standIn = ClientsideModel and ClientsideModel(mdl, RENDERGROUP_OPAQUE)
        standIn.lcCombine = MOVES_COMBINE[state.move] or false
        if not IsValid(standIn) then standIn = nil return nil end
        for _, s in ipairs({ "idle_all_01", "idle_all_02", "idle_unarmed", "idle_subtle" }) do
            local seq = standIn.LookupSequence and standIn:LookupSequence(s) or -1
            if seq and seq >= 0 then standIn:ResetSequence(seq) break end
        end
        -- on the floor in front of you, facing you
        local yaw = me:EyeAngles().y
        local at = me:GetPos() + Angle(0, yaw, 0):Forward() * 110
        local tr = util.TraceLine({ start = at + Vector(0, 0, 50), endpos = at - Vector(0, 0, 300), mask = MASK_SOLID_BRUSHONLY })
        standIn:SetPos(tr and tr.Hit and tr.HitPos or at)
        standIn:SetAngles(Angle(0, yaw + 180, 0))
    end
    return standIn
end

hook.Add("Think", "LivingCityEndingTuneStandIn", function()
    local s = StandIn()
    if not s then return end
    if s.SetCycle then s:SetCycle((CurTime() * 0.2) % 1) end
    if s.lcCombine ~= nil and s.lcCombine ~= (MOVES_COMBINE[state.move] or false) then DropStandIn() return end -- (a metrocop for those, you for the rest)
    if LC_CL.EndingPoseMove then LC_CL.EndingPoseMove(s, (string.gsub(state.move, "_combine$", "")), CurTime() * state.bpm / 60) end
end)

-- everyone doing the move now (the stand-in first)
local function Targets()
    local out = {}
    if IsValid(standIn) then out[1] = standIn end
    local now = CurTime()
    for e, t in pairs(seen) do
        if not IsValid(e) or now - t > 0.6 then seen[e] = nil
        elseif e ~= standIn then out[#out + 1] = e end
    end
    return out
end

local watching = 1
local function Watched()
    local list = Targets()
    if #list == 0 then return nil end
    if IsValid(standIn) then return standIn end
    local function Ix(e) return e.EntIndex and e:EntIndex() or 0 end
    table.sort(list, function(a, b) return Ix(a) < Ix(b) end)
    return list[((watching - 1) % #list) + 1]
end

-- the bone being tuned, lit up on everyone doing the move (and its other side, dimmer)
-- (made once here, not every frame)
local C_255_220_40_220 = Color(255, 220, 40, 220)
local C_255_70_70 = Color(255, 70, 70)
local C_70_255_70 = Color(70, 255, 70)
local C_80_150_255 = Color(80, 150, 255)
local C_80_220_255_140 = Color(80, 220, 255, 140)
hook.Add("PostDrawTranslucentRenderables", "LivingCityEndingTune", function(_, sky)
    if sky or not (frame and IsValid(frame)) or not state.bone then return end
    if render.SetColorMaterial then render.SetColorMaterial() end
    local other = state.mirror and Other(state.bone)
    for _, e in ipairs(Targets()) do
        for i, bone in ipairs({ state.bone, other }) do
            local id = bone and e.LookupBone and e:LookupBone("ValveBiped.Bip01_" .. bone)
            local m = id and e.GetBoneMatrix and e:GetBoneMatrix(id)
            if m then
                local pos, ang = m:GetTranslation(), m:GetAngles()
                if i == 1 then
                    render.DrawSphere(pos, 2.4, 12, 12, C_255_220_40_220)
                    render.DrawLine(pos, pos + ang:Forward() * 14, C_255_70_70, false)
                    render.DrawLine(pos, pos + ang:Right() * 14, C_70_255_70, false)
                    render.DrawLine(pos, pos + ang:Up() * 14, C_80_150_255, false)
                else
                    render.DrawSphere(pos, 1.6, 10, 10, C_80_220_255_140)
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- The menu
------------------------------------------------------------------------

local WHITE, DIM, GOLD = Color(235, 235, 235), Color(170, 170, 180), Color(255, 210, 90)

local function Label(parent, text, col, font)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:DockMargin(4, 2, 4, 2)
    l:SetText(text)
    l:SetTextColor(col or WHITE)
    if font then l:SetFont(font) end
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    return l
end

local function Slider(parent, text, mn, mx, dec, val, onChange)
    local s = vgui.Create("DNumSlider", parent)
    s:Dock(TOP)
    s:DockMargin(4, 0, 4, 0)
    s:SetText(text)
    s:SetMin(mn) s:SetMax(mx) s:SetDecimals(dec)
    s:SetValue(val)
    local lbl = s.Label
    if lbl and type(lbl) ~= "function" and lbl.SetTextColor then lbl:SetTextColor(WHITE) end
    s.OnValueChanged = function(_, v) if not s.lcLoading then onChange(v) end end
    return s
end

local function Button(parent, text, fn, dock)
    local b = vgui.Create("DButton", parent)
    b:Dock(dock or TOP)
    b:DockMargin(4, 2, 4, 2)
    b:SetText(text)
    b.DoClick = fn
    return b
end

-- a slider's range when the setting doesn't say
local function Range(name, d, v)
    if string.find(name, "yaw", 1, true) or string.find(name, "angle", 1, true) or string.find(name, "palm", 1, true) then return -180, 180 end
    local x = math.max(math.abs(d or 0), math.abs(v or 0))
    if (d or 0) < 0 or (v or 0) < 0 then return -math.max(x * 3, 10), math.max(x * 3, 10) end
    if x == 0 then return 0, 10 end
    if x <= 1 then return 0, x <= 0.5 and 1 or 2 end
    return 0, math.ceil(x * 3)
end

local function Nums(str)
    local out = {}
    for n in string.gmatch(str or "", "%S+") do
        local x = tonumber(n)
        if not x then return nil end
        out[#out + 1] = x
    end
    return #out > 0 and #out <= 3 and out or nil
end

-- one setting: what it's called, what it does, its control, and its default a click away
local function SettingRow(parent, s, shared)
    local row = vgui.Create("DSizeToContents", parent) -- (as tall as what's in it)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 6)
    row:DockPadding(4, 4, 4, 8)
    row:SetSizeX(false)
    row.Paint = function(_, w, h) surface.SetDrawColor(255, 255, 255, 10) surface.DrawRect(0, 0, w, h) end
    local nice = string.gsub(string.gsub(s.name, "^lc_ending_", ""), "_", " ")
    Label(row, nice .. (shared and "   (the same on everyone's screen)" or "") .. "   " .. s.name, GOLD)
    if s.help and s.help ~= "" then Label(row, s.help, DIM) end
    local controls = {}
    local function Changed(v)
        s.v = v
        Send("setting", s.name, v)
        if shared then data.shared[s.name] = v end
    end
    local nums, dnums = Nums(s.v), Nums(s.d)
    if nums and dnums and #nums == #dnums then
        local axes = #nums == 1 and { "" } or (#nums == 2 and { "first", "second" } or { "pitch", "yaw", "roll" })
        for i = 1, #nums do
            local mn, mx = Range(s.name, dnums[i], nums[i])
            if s.min and #nums == 1 then mn = s.min end
            if s.max and #nums == 1 then mx = s.max end
            local whole = math.floor(dnums[i]) == dnums[i] and math.floor(nums[i]) == nums[i] and mx - mn > 4
            controls[i] = Slider(row, axes[i] ~= "" and axes[i] or "value", mn, mx, whole and 0 or 2, nums[i], function()
                local parts = {}
                for j, c in ipairs(controls) do parts[j] = tostring(math.Round(c:GetValue(), whole and 0 or 2)) end
                Changed(table.concat(parts, " "))
            end)
        end
    else
        local t = vgui.Create("DTextEntry", row)
        t:Dock(TOP)
        t:DockMargin(4, 0, 4, 0)
        t:SetText(s.v or "")
        t.OnEnter = function(self) Changed(self:GetValue()) end
        t.OnLoseFocus = function(self) if self:GetValue() ~= s.v then Changed(self:GetValue()) end end
        controls[1] = t
    end
    Button(row, "Back to the default (" .. tostring(s.d) .. ")", function()
        local d = Nums(s.d)
        if d and #controls == #d and controls[1].SetValue and not controls[1].SetMultiline then
            for i, c in ipairs(controls) do c.lcLoading = true c:SetValue(d[i]) c.lcLoading = nil end
        elseif controls[1].SetText then controls[1]:SetText(s.d or "") end
        Changed(s.d or "")
        if shared then data.shared[s.name] = nil end
    end)
    return row
end

local Fill -- (below: builds the menu for the ending picked)

-- The same setting? "0.360000" is 0.36: numbers (and lists of them) are compared as numbers.
local function SameValue(a, b)
    a, b = tostring(a or ""), tostring(b or "")
    if a == b then return true end
    local ta, tb = {}, {}
    for w in string.gmatch(a, "[^%s,:]+") do ta[#ta + 1] = w end
    for w in string.gmatch(b, "[^%s,:]+") do tb[#tb + 1] = w end
    if #ta ~= #tb or #ta == 0 then return false end
    for i = 1, #ta do
        local x, y = tonumber(ta[i]), tonumber(tb[i])
        if x and y then
            if math.abs(x - y) > 1e-4 then return false end
        elseif ta[i] ~= tb[i] then
            return false
        end
    end
    return true
end
LC_CL.EndingSameValue = SameValue

local function Changes()
    local lines = { "Miscount: ending tuning, from the Endings menu" }
    if info and info.settings then
        local any = false
        for g, list in pairs(info.settings) do
            for _, s in ipairs(list) do
                if not SameValue(s.v, s.d) then
                    if not any then lines[#lines + 1] = "" lines[#lines + 1] = "Settings changed from their default:" any = true end
                    lines[#lines + 1] = string.format("  %s = %s   (default %s; %s)", s.name, s.v, s.d, g)
                end
            end
        end
    end
    if next(data.shared) then
        lines[#lines + 1] = "" lines[#lines + 1] = "Shared settings (the same on everyone's screen):"
        for n, v in SortedPairs(data.shared) do lines[#lines + 1] = string.format("  %s = %s   (default %s)", n, v, SHARED[n] or "?") end
    end
    if next(data.bones) then
        lines[#lines + 1] = "" lines[#lines + 1] = "Dance tuning (added to the code's own turn of the bone; pitch yaw roll):"
        for move, bones in SortedPairs(data.bones) do
            for bone, o in SortedPairs(bones) do lines[#lines + 1] = string.format("  %s: %s %g %g %g", move, bone, o[1], o[2], o[3]) end
        end
    end
    if #lines == 1 then lines[#lines + 1] = "" lines[#lines + 1] = "Nothing changed yet." end
    return table.concat(lines, "\n")
end
LC_CL.EndingTuneChanges = Changes

local function DanceTab(sheet, id)
    local pnl = vgui.Create("DScrollPanel", sheet)
    local moves = MOVES[id]
    if not moves then
        Label(pnl, "This ending has no dance to tune. Its settings are on the next tab.", DIM)
        return pnl
    end
    local have = false
    for _, m in ipairs(moves) do if m[1] == state.move then have = true end end
    if not have then state.move = moves[1][1] end
    local list = BonesOf(state.move)
    local ok = false
    for _, b in ipairs(list) do if b == state.bone then ok = true end end
    if not ok then state.bone = "R_UpperArm" end

    local pick = vgui.Create("DComboBox", pnl)
    pick:Dock(TOP)
    pick:DockMargin(4, 4, 4, 4)
    for _, m in ipairs(moves) do pick:AddChoice(m[2], m[1], m[1] == state.move) end
    pick.OnSelect = function(_, _, _, move) state.move = move seen = {} DropStandIn() Fill() end

    -- the close-up: whoever's doing the move, the bone lit up; drag to turn round it, wheel to zoom
    local view = vgui.Create("DPanel", pnl)
    view:Dock(TOP)
    view:DockMargin(4, 0, 4, 4)
    view:SetTall(240)
    view.Paint = function(self, w, h)
        surface.SetDrawColor(16, 16, 22, 255) surface.DrawRect(0, 0, w, h)
        local e = Watched()
        if not IsValid(e) then
            draw.SimpleText("Nobody's doing this move in sight.", "DermaDefault", w / 2, h / 2 - 8, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Play the ending, or tick the stand-in below.", "DermaDefault", w / 2, h / 2 + 8, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        local id2 = state.bone and e.LookupBone and e:LookupBone("ValveBiped.Bip01_" .. state.bone)
        local centre = id2 and e.GetBonePosition and e:GetBonePosition(id2) or (e:GetPos() + Vector(0, 0, 40))
        local ang = Angle(8, (e.GetAngles and e:GetAngles().y or 0) + state.yaw, 0)
        local x, y = self:LocalToScreen(0, 0)
        if render.RenderView then
            render.RenderView({ origin = centre - ang:Forward() * state.dist, angles = ang, x = x, y = y, w = w, h = h, fov = 55,
                drawviewer = true, drawhud = false, drawmonitors = false, dopostprocess = false })
        end
        draw.SimpleText("drag to turn round, wheel to zoom", "DermaDefault", 6, h - 6, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
    view.OnMousePressed = function(self) self.lcDrag = { gui.MouseX(), state.yaw } if self.MouseCapture then self:MouseCapture(true) end end
    view.OnMouseReleased = function(self) self.lcDrag = nil if self.MouseCapture then self:MouseCapture(false) end end
    view.Think = function(self) if self.lcDrag then state.yaw = self.lcDrag[2] + (gui.MouseX() - self.lcDrag[1]) * 0.6 end end
    view.OnMouseWheeled = function(_, d) state.dist = math.Clamp(state.dist - d * 8, 25, 400) return true end
    Button(pnl, "Watch someone else doing it", function() watching = watching + 1 end)

    -- the body map: click a bone
    local body = vgui.Create("DPanel", pnl)
    body:Dock(TOP)
    body:DockMargin(4, 4, 4, 4)
    body:SetTall(250)
    body.Paint = function(_, w, h) surface.SetDrawColor(255, 255, 255, 8) surface.DrawRect(0, 0, w, h) end
    local sliders, hints = {}, {}
    local function Load()
        local p, y, r = BoneOff(state.move, state.bone)
        local hp, hy, hr = Hints(state.bone)
        if hints.title then hints.title:SetText((MAP[state.bone] and MAP[state.bone][3] or state.bone) .. "   (" .. state.bone .. ")") end
        for i, v in ipairs({ p, y, r }) do
            local s = sliders[i]
            if s then
                s.lcLoading = true
                s:SetValue(v)
                s.lcLoading = nil
            end
            if hints[i] then hints[i]:SetText(({ hp, hy, hr })[i]) end
        end
    end
    local buttons = {}
    body.PerformLayout = function(self, w, h)
        for _, it in ipairs(buttons) do it[1]:SetPos(it[2][1] * w - 48, it[2][2] * h) end
    end
    for _, bone in ipairs(list) do
        local at = MAP[bone]
        if at then
            local b = vgui.Create("DButton", body)
            b:SetText(at[3])
            b:SetSize(96, 22)
            buttons[#buttons + 1] = { b, at }
            b.Paint = function(self, w, h)
                local on = state.bone == bone
                local off = data.bones[state.move] and data.bones[state.move][bone]
                surface.SetDrawColor(on and 255 or 60, on and 200 or 60, on and 40 or 70, 255)
                surface.DrawRect(0, 0, w, h)
                if off then surface.SetDrawColor(80, 220, 255, 255) surface.DrawOutlinedRect(0, 0, w, h) end
            end
            b:SetTextColor(Color(255, 255, 255))
            b.DoClick = function() state.bone = bone Load() end
        end
    end
    Label(pnl, "Yellow: the bone you're turning. Blue edge: a bone that's been tuned. In the world it's lit up on everyone doing the move (red forward, green right, blue up).", DIM)

    local mirror = vgui.Create("DCheckBoxLabel", pnl)
    mirror:Dock(TOP)
    mirror:DockMargin(4, 4, 4, 4)
    mirror:SetText("Left and right mirror each other")
    mirror:SetValue(state.mirror)
    mirror.OnChange = function(_, v) state.mirror = v end

    local function Changed()
        local p, y, r = math.Round(sliders[1]:GetValue()), math.Round(sliders[2]:GetValue()), math.Round(sliders[3]:GetValue())
        SetBone(state.move, state.bone, p, y, r)
        local other = state.mirror and Other(state.bone)
        if other then SetBone(state.move, other, -p, y, -r) end
    end
    hints.title = Label(pnl, "", GOLD)
    for i = 1, 3 do
        hints[i] = Label(pnl, "", DIM)
        sliders[i] = Slider(pnl, ({ "Pitch", "Yaw", "Roll" })[i], -180, 180, 0, 0, Changed)
    end
    Load()
    Button(pnl, "Back to how the code has it: this bone", function()
        SetBone(state.move, state.bone, 0, 0, 0)
        local other = state.mirror and Other(state.bone)
        if other then SetBone(state.move, other, 0, 0, 0) end
        Load()
    end)
    Button(pnl, "Back to how the code has it: the whole move", function()
        for _, bone in ipairs(list) do if data.bones[state.move] and data.bones[state.move][bone] then SetBone(state.move, bone, 0, 0, 0) end end
        Load()
    end)

    local si = vgui.Create("DCheckBoxLabel", pnl)
    si:Dock(TOP)
    si:DockMargin(4, 8, 4, 4)
    si:SetText("Stand-in: someone doing the move in front of you (only on your screen)")
    si:SetValue(state.standIn)
    si.OnChange = function(_, v) state.standIn = v if not v then DropStandIn() end end
    Slider(pnl, "The stand-in's beats a minute", 40, 200, 0, state.bpm, function(v) state.bpm = v end)
    return pnl
end

local function SettingsTab(sheet, id)
    local pnl = vgui.Create("DScrollPanel", sheet)
    local songLbl = Label(pnl, "", GOLD)
    local labelThink = songLbl.Think -- (the label's own: growing to fit)
    songLbl.Think = function(self)
        if labelThink then labelThink(self) end
        local t = LC_CL.EndingSongPos and LC_CL.EndingSongPos()
        local S = LC_CL.Ending and LC_CL.Ending()
        self:SetText(t and string.format("The song is at %.1f s (%s)", t, S and S.client and S.client.section or "") or "The song's time shows here while an ending plays (for lining up its sections: seconds:part,seconds:part,...).")
    end
    Button(pnl, "Copy the song's time", function() local t = LC_CL.EndingSongPos and LC_CL.EndingSongPos() if t then SetClipboardText(string.format("%.1f", t)) end end)
    for _, n in ipairs(SHARED_OF[id] or {}) do
        local cv = GetConVar(n)
        SettingRow(pnl, { name = n, v = data.shared[n] or (cv and cv:GetString()) or SHARED[n], d = SHARED[n], help = cv and cv.GetHelpText and cv:GetHelpText() or "" }, true)
    end
    local list = info and info.settings and info.settings[id] or {}
    if #list == 0 and not SHARED_OF[id] then Label(pnl, "No settings of its own.", DIM) end
    for _, s in ipairs(list) do SettingRow(pnl, s) end
    Label(pnl, "Every ending:", GOLD)
    for _, s in ipairs(info and info.settings and info.settings.all or {}) do SettingRow(pnl, s) end
    return pnl
end

local function YouTab(sheet)
    local pnl = vgui.Create("DScrollPanel", sheet)
    Label(pnl, "These are your own game's, not the server's.", DIM)
    local function Num(text, cv, mn, mx, dec)
        local s = vgui.Create("DNumSlider", pnl)
        s:Dock(TOP) s:DockMargin(4, 0, 4, 0)
        s:SetText(text) s:SetMin(mn) s:SetMax(mx) s:SetDecimals(dec)
        s:SetConVar(cv)
    end
    Num("How loud the songs are", "lc_ending_volume", 0, 2, 2)
    local calm = vgui.Create("DCheckBoxLabel", pnl)
    calm:Dock(TOP) calm:DockMargin(4, 4, 4, 4)
    calm:SetText("Calm: no strobes or screen flashes")
    calm:SetConVar("lc_ending_calm")
    Num("Base's arcade blocks (1: off)", "lc_pixel_size", 1, 16, 0)
    return pnl
end

local function ChangesTab(sheet)
    local pnl = vgui.Create("DPanel", sheet)
    pnl.Paint = function() end
    Label(pnl, "Everything you've changed. Copy it and send it on, and it can be built in as the new normal.", DIM)
    local box = vgui.Create("DTextEntry", pnl)
    box:Dock(FILL)
    box:DockMargin(4, 4, 4, 4)
    box:SetMultiline(true)
    box:SetText(Changes())
    local bar = vgui.Create("DPanel", pnl)
    bar:Dock(BOTTOM)
    bar:SetTall(30)
    bar.Paint = function() end
    Button(bar, "Copy it all", function() SetClipboardText(Changes()) end, LEFT):SetWide(140)
    Button(bar, "Refresh", function() box:SetText(Changes()) end, LEFT):SetWide(100)
    return pnl
end

Fill = function()
    if not (frame and IsValid(frame)) then return end
    if IsValid(frame.lcBody) then frame.lcBody:Remove() end
    local id = state.ending
    local body = vgui.Create("DPropertySheet", frame)
    body:Dock(FILL)
    frame.lcBody = body
    body:AddSheet("The dance", DanceTab(body, id), "icon16/user.png")
    body:AddSheet("Settings", SettingsTab(body, id), "icon16/cog.png")
    body:AddSheet("Just for you", YouTab(body), "icon16/heart.png")
    body:AddSheet("Changes", ChangesTab(body), "icon16/page_copy.png")
    if isstring(frame.lcSheet) and istable(body.Items) then
        for _, it in ipairs(body.Items) do if it.Name == frame.lcSheet then body:SetActiveTab(it.Tab) end end
    end
    body.OnActiveTabChanged = function(_, _, new) frame.lcSheet = new and new.GetText and new:GetText() or nil end
end

local function Playing()
    local S = LC_CL.Ending and LC_CL.Ending()
    return S and S.id or nil
end

local function Open(newInfo)
    info = newInfo or info or {}
    if istable(info.tuning) then data.bones = info.tuning.bones or {} data.shared = info.tuning.shared or {} end
    local playing = Playing() or info.now
    state.ending = playing or state.ending or (info.endings and info.endings[1] and info.endings[1].id)
    state.lastPlaying = playing
    if not (frame and IsValid(frame)) then
        frame = vgui.Create("DFrame")
        if LC_CL.SetTheme then LC_CL.SetTheme(frame, "staff") end -- (out of character: cl_livingcity_theme.lua)
        frame:SetSize(math.min(520, ScrW() - 40), math.min(ScrH() - 60, 960))
        frame:SetPos(ScrW() - frame:GetWide() - 20, 30)
        frame:SetTitle("Endings: tune them live")
        frame:SetSizable(true)
        frame:SetDeleteOnClose(true)
        frame:MakePopup()
        frame.OnRemove = function() DropStandIn() seen = {} frame = nil end
        -- the top: which ending, play it now, stop it
        local top = vgui.Create("DPanel", frame)
        top:Dock(TOP)
        top:SetTall(28)
        top.Paint = function() end
        local pick = vgui.Create("DComboBox", top)
        pick:Dock(FILL)
        pick:DockMargin(2, 2, 2, 2)
        frame.lcPick = pick
        Button(top, "Play it now", function() RunConsoleCommand("lc_ending", state.ending, "now") end, RIGHT):SetWide(90)
        Button(top, "Stop it", function() RunConsoleCommand("lc_ending_cancel") end, RIGHT):SetWide(64)
        Button(top, "Dreams", function() if LC_CL.DreamsMenu then LC_CL.DreamsMenu() end end, RIGHT):SetWide(64) -- (cl_livingcity_dreams.lua)
        local baseThink = frame.Think -- (the window's own: dragging and resizing it)
        frame.Think = function(self)
            if baseThink then baseThink(self) end
            local p = Playing()
            if p ~= state.lastPlaying then
                state.lastPlaying = p
                if p and p ~= state.ending then state.ending = p Open() end
            end
        end
    end
    local pick = frame.lcPick
    pick:Clear()
    for _, e in ipairs(info.endings or {}) do
        pick:AddChoice(e.name .. (e.id == playing and "   (playing now)" or ""), e.id, e.id == state.ending)
    end
    pick.OnSelect = function(_, _, _, id) state.ending = id seen = {} DropStandIn() Fill() end
    Fill()
end
LC_CL.OpenEndingsMenu = Open
function LC_CL.CloseEndingsMenu() if frame and IsValid(frame) then frame:Remove() end frame = nil DropStandIn() end

net.Receive("lc_tune_info", function() Open(net.ReadTable()) end)

function LC_CL.EndingsMenu()
    local me = LocalPlayer()
    if not (IsValid(me) and me:IsSuperAdmin()) then
        chat.AddText(Color(255, 200, 80), "[Endings] ", color_white, "Only a superadmin can tune the endings.")
        return
    end
    net.Start("lc_tune_req")
    net.SendToServer()
end
concommand.Add("lc_endings_menu", function() LC_CL.EndingsMenu() end)
