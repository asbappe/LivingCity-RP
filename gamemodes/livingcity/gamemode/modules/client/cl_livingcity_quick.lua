--[[
    Living City (client): the quick menu

    F1. Like a voice menu in a team shooter: a short list at the left of the
    screen, picked with the number keys (1 to 9; 0 goes back or closes), and
    you keep moving while it's up. Nine things, for who you are:

      Civil Protection   backup, 10-20, BOLO, mask voice lines, records
      Overwatch          the same, in a soldier's voice
      Citizens           hands up, your name, your papers, talking, pockets
      The Resistance     hands up, gear up or plain clothes, talking, the
                         black market, pockets

    6 to 8 change with what's in front of you (a person: search, tie, show
    your papers; a body; a door) and with your own trouble (downed, tied,
    wanted); with nothing there they're your usual three. 9 is everything
    else: the full menu (cl_livingcity_actions.lua), also on C. A ">" opens a
    page of its own (voice lines, talking, poses).

    bind a key to lc_quick to open it from something other than F1.
]]

LC_CL = LC_CL or {}

local INK, DIM = Color(236, 232, 220), Color(150, 150, 145)
local BG, HEAD = Color(10, 12, 16, 220), Color(20, 24, 30, 235)
local ACCENT = { cp = Color(120, 190, 255), ota = Color(120, 190, 255), resistance = Color(235, 120, 80), default = Color(235, 180, 70) }
local CONTEXT = Color(140, 225, 160)

surface.CreateFont("LCQuickTitle", { font = "Trebuchet MS", size = 18, weight = 700 })
surface.CreateFont("LCQuickItem", { font = "Trebuchet MS", size = 18, weight = 500 })
surface.CreateFont("LCQuickNum", { font = "Trebuchet MS", size = 18, weight = 800 })

local function Send(...) if LC_CL.SendAction then LC_CL.SendAction(...) end end
local function Ask(...) if LC_CL.AskAction then LC_CL.AskAction(...) end end
local function Say(title, prompt, prefix)
    Derma_StringRequest(title, prompt, "", function(text)
        text = string.Trim(text or "")
        if text ~= "" then RunConsoleCommand("say", prefix .. text) end
    end)
end
local function Title(s) return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2) end

local function Item(label, run) return { label = label, run = run } end
local function Page(label, build) return { label = label, page = build } end
local function Name(p) return LC_CL.ICName and LC_CL.ICName(p) or "them" end

------------------------------------------------------------------------
-- Pages
------------------------------------------------------------------------

local function TalkPage()
    return { title = "TALK", items = {
        Item("Yell...", function() Say("Yell", "What do you yell?", "/y ") end),
        Item("Whisper...", function() Say("Whisper", "What do you whisper?", "/w ") end),
        Item("Describe what I do (/me)...", function() Say("An action", "What do you do? (e.g. leans against the wall)", "/me ") end),
        Item("Describe the scene (/it)...", function() Say("The scene", "What happens? (e.g. A siren starts up somewhere.)", "/it ") end),
        Item("On my radio...", function() Ask("Radio", "What do you say on the radio?", "r") end),
        Item("Roll the dice (1 to 100)", function() RunConsoleCommand("say", "/roll") end),
        Item("Out of character, nearby...", function() Say("Out of character", "Said out of character, to people nearby", "/looc ") end),
        Item("Out of character, everyone...", function() Say("Out of character", "Said out of character, to the whole server", "// ") end),
    } }
end

local function PosePage()
    local items = {}
    for _, p in ipairs({ "sit", "kneel", "lie", "lean", "cower" }) do items[#items + 1] = Item(p == "lie" and "Lie down" or Title(p), function() Send(p) end) end
    items[#items + 1] = Item("Stand: pose 1", function() Send("pose", "1") end)
    items[#items + 1] = Item("Stand: pose 2", function() Send("pose", "2") end)
    items[#items + 1] = Item("Stand up", function() Send("stand") end)
    return { title = "POSE", items = items }
end

local function GesturePage()
    local all, items, seen = LCA and LCA.Gestures or {}, {}, {}
    for _, n in ipairs({ "wave", "salute", "nod", "shake", "point", "beckon", "halt", "bow" }) do
        if all[n] and #items < 8 then items[#items + 1] = Item(Title(n), function() Send(n) end) seen[n] = true end
    end
    local rest = {}
    for n in pairs(all) do if not seen[n] then rest[#rest + 1] = n end end
    table.sort(rest)
    for _, n in ipairs(rest) do if #items < 8 then items[#items + 1] = Item(Title(n), function() Send(n) end) end end
    return { title = "GESTURE", items = items }
end

-- The mask's most used lines (and soldiers' own); all of them: the full list.
local CP_LINES = { "movealong", "holdit", "apply", "document", "freeze", "first", "youcango", "copy" }
local function VoicePage()
    local me = LocalPlayer()
    local ota = me:GetNW2String("lcf_faction", "") == "ota"
    local items = {}
    if ota then
        for _, l in ipairs(LCCP and LCCP.VoiceOTA or {}) do
            if #items < 8 then items[#items + 1] = Item(l[2], function() RunConsoleCommand("lc_vo", l[1]) end) end
        end
    else
        local by = {}
        for _, l in ipairs(LCCP and LCCP.Voice or {}) do by[l[1]] = l end
        for _, w in ipairs(CP_LINES) do
            local l = by[w]
            if l then items[#items + 1] = Item(l[2], function() RunConsoleCommand("lc_vo", l[1]) end) end
        end
    end
    items[9] = Item("All the voice lines...", function() Send("vo") end)
    return { title = "VOICE", items = items }
end

local function SocioPage()
    local items = {}
    for _, l in ipairs({ "green", "yellow", "red", "auto" }) do items[#items + 1] = Item(string.upper(l), function() Send("socio", l) end) end
    return { title = "SOCIOSTABILITY", items = items }
end

local function ResistancePage()
    local me = LocalPlayer()
    local items = {
        Item("Find the lab (mark it)", function() Send("waypoint", "lab") end),
        Item("Donate food to the supply crate", function() Send("donate") end),
        Item("Have the quartermaster decode a data chip", function() Send("decode") end),
    }
    if me:HasWeapon("weapon_lc_multitool") then items[#items + 1] = Item("Hack the Combine door I'm looking at", function() Send("hack") end) end
    return { title = "RESISTANCE", items = items }
end

local function StaffPage()
    local me = LocalPlayer()
    return { title = "STAFF", items = {
        Item("Staff panel (logs, tickets, warnings, bans)", function() Send("staff") end),
        Item("Admin testing tools", function() Send("admintools") end),
        Item(me:GetNW2Bool("lc_build", false) and "Build mode: off (back to playing)" or "Build mode: on", function() Send("build") end),
        Item("Path mapping: on / off", function() Send("pathmap") end),
    } }
end

------------------------------------------------------------------------
-- What's in front of you, and your own trouble: slots 6 to 8 first
------------------------------------------------------------------------

local function Context(me, unit, rebel)
    local out = {}
    local function Add(label, run) out[#out + 1] = { label = label, run = run, ctx = true } end
    local now = CurTime()
    if me:GetNW2Float("lc_downed_until", 0) > now then Add("Give up (let go)", function() Send("giveup") end) end
    if me:GetNW2Bool("lc_tied", false) then Add("Work at the ties", function() Send("struggle") end) end
    if not unit and me:GetNW2Float("lc_wanted_until", 0) > now then Add("Give myself up (near a unit)", function() Send("surrender") end) end
    if me:GetNW2Bool("lc_interrogated", false) then
        Add("Talk to the interrogator", function() net.Start("lc_interrogate_reply") net.WriteBool(true) net.SendToServer() end)
    end
    if me:GetNW2Bool("lc_hauling", false) then Add("Let go of the body", function() Send("haul") end) end
    if IsValid(me:GetNW2Entity("lc_scanner")) then Add("Disconnect from the scanner", function() Send("unlink") end) end

    local tr = me:GetEyeTrace()
    local e = tr and tr.Entity
    local close = tr and tr.HitPos and tr.HitPos:DistToSqr(me:EyePos()) < 150 * 150
    if not (IsValid(e) and close) then return out end
    local cls = e:GetClass() or ""
    if e:IsPlayer() then
        local n = Name(e)
        local tied = e:GetNW2Bool("lc_tied", false)
        if unit then
            Add("Search " .. n, function() Send("search") end)
            if tied then
                Add("Drag " .. n .. " along / let go", function() Send("drag") end)
                Add("Cut " .. n .. "'s ties", function() Send("untie") end)
            else
                Add("Zip-tie " .. n, function() Send("tie") end)
            end
            if e:GetNW2String("lcj_job", "") ~= "" and e:GetNW2Entity("lc_escorting") ~= me then Add("Escort " .. n, function() Send("escort", "", e) end) end
            if tied or e:GetNW2Bool("lc_handsup", false) then Add("Take " .. n .. "'s microphone", function() Send("takemic", "", e) end) end
        else
            Add("Tell " .. n .. " my name", function() Send("recognize") end)
            Add("Show " .. n .. " my papers", function() Send("showpapers") end)
            if tied then
                Add("Cut " .. n .. "'s ties", function() Send("untie") end)
                Add("Drag " .. n .. " along / let go", function() Send("drag") end)
            end
            if me:GetNW2Bool("lc_foreman", false) then Add("Give " .. n .. " a work order", function() Send("assign", "", e) end) end
            if not rebel then Add("Inform on " .. n, function() Send("inform", "", e) end) end
        end
    elseif e:GetNW2Bool("lc_downed_body", false) then
        Add("Drag them along / let go", function() Send("drag") end)
        Add(unit and "Cuff them, or help them up: hold E" or "Help them up: hold E", function() end)
    elseif e:GetNW2Bool("lc_body", false) then
        Add("Search the body's pockets", function() Send("searchbody", "", e) end)
        Add("Haul the body", function() Send("haul", "", e) end)
    elseif cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating" or cls == "func_movelinear" then
        Add("Rent / lock this door", function() Send("rent") end)
        Add("Pick the lock (lockpick)", function() Send("pick") end)
        if me:HasWeapon("weapon_lc_multitool") then Add("Hack the Combine lock", function() Send("hack") end) end
    elseif cls == "lc_forcefield" then
        Add("Swipe a Combine keycard", function() Send("swipe", "", e) end)
        if me:HasWeapon("weapon_lc_multitool") then Add("Short it out (multitool)", function() Send("shortfield", "", e) end) end
    elseif cls == "lc_transformer" then
        if e:GetNW2Bool("lc_down", false) then Add("Repair the transformer", function() Send("transformer", "", e) end)
        elseif me:HasWeapon("weapon_lc_multitool") then Add("Sabotage the transformer", function() Send("sabotage", "", e) end) end
    elseif cls == "lc_powerbank" then
        if unit then Add("Read the power bank", function() Send("checkpoint", "status", e) end)
        elseif me:HasWeapon("weapon_lc_multitool") then Add("Short out the power bank", function() Send("checkpoint", "short", e) end) end
    elseif cls == "npc_turret_floor" and unit then
        Add("Pack up this turret", function() Send("checkpoint", "pack", e) end)
    elseif cls == "lc_screen" and me:HasWeapon("weapon_lc_multitool") then
        Add("Hijack this screen (multitool)", function() Send("hijack") end)
    end
    return out
end

------------------------------------------------------------------------
-- The first page: who you are
------------------------------------------------------------------------

function LC_CL.QuickRoot()
    local me = LocalPlayer()
    local f = me:GetNW2String("lcf_faction", "")
    local unit = me:GetNW2Bool("lc_unit", false) or f == "cp" or f == "ota"
    local rebel = f == "resistance"
    local rank = me:GetNW2Int("lcf_rank", 1)
    local officer = me:IsAdmin() or (f == "cp" and rank >= 7) or (f == "ota" and rank >= 3)
    local hands = Item(me:GetNW2Bool("lc_handsup", false) and "Lower my hands" or "Put my hands up", function() Send("handsup") end)
    local pockets = Item("My pockets (F2)", function() RunConsoleCommand("gm_showteam") end)
    local board = Item("My board: jobs (F3)", function() RunConsoleCommand("gm_showspare1") end)
    local items, usual, title, accent
    if unit then
        title = me:GetNW2String("lcf_title", "") ~= "" and me:GetNW2String("lcf_title", "") or (f == "ota" and "OVERWATCH" or "CIVIL PROTECTION")
        accent = ACCENT.cp
        items = {
            Item("Call for backup", function() Send("backup") end),
            Item("Send my 10-20", function() Send("10-20") end),
            Item("Issue a BOLO...", function() Ask("BOLO", "What should units look out for?", "bolo") end),
            Page("Voice lines", VoicePage),
            Item("Records terminal", function() Send("records") end),
        }
        usual = {
            Item("Unit tools (everything a unit has)", function() if LC_CL.OpenUnitTools then LC_CL.OpenUnitTools() end end),
            Item("My directives (F3)", function() RunConsoleCommand("gm_showspare1") end),
            officer and Page("Sociostability", SocioPage) or pockets,
        }
    elseif rebel then
        title, accent = "RESISTANCE", ACCENT.resistance
        local plain = me:GetNW2String("lcd_disguise", "") ~= ""
        items = {
            hands,
            Item(plain and "Gear up (Resistance clothes)" or "Change into plain clothes", function() Send(plain and "gearup" or "plain") end),
            Page("Talk", TalkPage),
            Item("Black market", function() Send("market") end),
            pockets,
        }
        usual = { Page("Resistance", ResistancePage), Page("Pose", PosePage), board }
    else
        title, accent = f == "admin" and "STAFF" or "CITIZEN", ACCENT.default
        items = {
            hands,
            Item("Tell everyone nearby my name", function() Send("recognize", "all") end),
            Item("My papers", function() Send("papers") end),
            Page("Talk", TalkPage),
            pockets,
        }
        usual = { Page("Pose", PosePage), Page("Gesture", GesturePage), (f == "admin" and me:IsAdmin()) and Page("Staff", StaffPage) or board }
    end
    -- 6 to 8: what's in front of you first, then your usual three
    local ctx = Context(me, unit, rebel)
    for i = 1, 3 do items[5 + i] = ctx[i] or table.remove(usual, 1) end
    items[9] = Item("Everything else (full menu)", function() if LC_CL.OpenActions then LC_CL.OpenActions() end end)
    return { title = string.upper(title), items = items, accent = accent }
end

------------------------------------------------------------------------
-- Open, pick, close
------------------------------------------------------------------------

local open -- { page, stack, last }

function LC_CL.QuickOpen() return open ~= nil end
function LC_CL.CloseQuick() open = nil end

function LC_CL.OpenQuick()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    open = { page = LC_CL.QuickRoot(), stack = {}, last = CurTime() }
    LC_CL.ActionsOpenedAt = CurTime() -- (the server's own F1 answer doesn't also open the guide)
end

-- 1 to 9 picks; 0 goes back a page, or closes.
function LC_CL.QuickPick(n)
    if not open then return end
    open.last = CurTime()
    if n == 0 then
        if #open.stack > 0 then open.page = table.remove(open.stack) else open = nil end
        return
    end
    local it = open.page.items[n]
    if not it then return end
    if it.page then
        local accent = open.page.accent
        table.insert(open.stack, open.page)
        open.page = it.page()
        open.page.accent = open.page.accent or accent
        return
    end
    open = nil
    if it.run then it.run() end
end

concommand.Add("lc_quick", function() if open then open = nil else LC_CL.OpenQuick() end end)

local was = {}
hook.Add("Think", "LivingCityQuickKeys", function()
    if not open then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() or (gui and gui.IsGameUIVisible and gui.IsGameUIVisible()) or CurTime() - open.last > 20 then
        open = nil
        return
    end
    if (me.IsTyping and me:IsTyping()) or (vgui and vgui.GetKeyboardFocus and vgui.GetKeyboardFocus()) then return end
    for n = 0, 9 do
        local k1, k2 = _G["KEY_" .. n], _G["KEY_PAD_" .. n]
        local down = (k1 and input.IsKeyDown(k1)) or (k2 and input.IsKeyDown(k2)) or false
        if down and not was[n] then
            was[n] = true
            LC_CL.QuickPick(n)
            return
        end
        was[n] = down
    end
end)

-- While it's up, the number keys are for it, not for switching weapons.
hook.Add("PlayerBindPress", "LivingCityQuick", function(ply, bind, pressed)
    if not open or not bind then return end
    if string.match(bind, "^slot%d+$") then return true end
end)

-- a label cut to fit its row
local function Fit(text, font, width)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= width then return text end
    while #text > 4 and surface.GetTextSize(text .. "...") > width do text = string.sub(text, 1, -2) end
    return text .. "..."
end

hook.Add("HUDPaint", "LivingCityQuick", function()
    if not open then return end
    local page = open.page
    local accent = page.accent or ACCENT.default
    local W, H = 380, 34 + 9 * 26 + 26
    local x, y = 24, math.floor(ScrH() * 0.5 - H / 2)
    draw.RoundedBox(4, x, y, W, H, BG)
    draw.RoundedBox(4, x, y, W, 30, HEAD)
    draw.RoundedBox(0, x, y + 28, W, 2, accent)
    draw.SimpleText(page.title or "", "LCQuickTitle", x + 12, y + 15, accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    for i = 1, 9 do
        local it = page.items[i]
        local ry = y + 34 + (i - 1) * 26
        if it then
            local col = it.ctx and CONTEXT or INK
            draw.SimpleText(tostring(i), "LCQuickNum", x + 16, ry + 12, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            it.fit = it.fit or Fit(it.label .. (it.page and "  >" or ""), "LCQuickItem", W - 46)
            draw.SimpleText(it.fit, "LCQuickItem", x + 34, ry + 12, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(tostring(i), "LCQuickNum", x + 16, ry + 12, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    draw.SimpleText(#open.stack > 0 and "0  Back" or "0  Close", "DermaDefault", x + 12, y + H - 13, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local key = input and input.LookupBinding and input.LookupBinding("+menu_context")
    draw.SimpleText((key and string.upper(key) or "C") .. ": the full menu", "DermaDefault", x + W - 12, y + H - 13, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end)
