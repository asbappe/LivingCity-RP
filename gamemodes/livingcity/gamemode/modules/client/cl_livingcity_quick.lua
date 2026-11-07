--[[
    Living City (client): the quick menus

    Like a voice menu in a team shooter: a short list at the left of the screen, picked
    with the number keys (1 to 9; 0 goes back or closes), and you keep moving while it's
    up. Two of them (the owner, 7 November: "F1 can be generic/general commands and
    hotkeys via the quick number menu, and F2 can be the same BUT contextual and specific
    commands for their class/rank/faction"):

      F1   what everyone has: what now?, hands up, your papers, talking, your pockets
           (F3); 6 to 8 change with what's in front of you (a person: tell them your
           name, show your papers; a body; a door) and with your own trouble (downed,
           tied, wanted); with nothing there they're poses, gestures and F4.
      F2   what your side, rank and job have: Civil Protection's 1 Voice lines, 2 Unit
           tools, 3 Kick, 4 Call for backup, 5 BOLO, 6 Send my 10-20 (the owner,
           7 November); the Resistance's clothes, black market, errands and squad
           orders; the Administrator's sociostability and broadcast; a vortigaunt's
           call; a stalker's work; a worker's job tools (an escort, a ration break, the
           body cart, foreman); staff tools. Then what only your side does to what's in
           front of you (a unit: search, cuff, escort). Nothing of the kind: it says so.

    9 on either is everything else: the full menu (cl_livingcity_actions.lua), also on C.
    A ">" opens a page of its own (voice lines, talking, poses).

    F1 is the key itself (cl_livingcity_actions.lua); F2 is the server's answer to
    gm_showteam (lcg_quick2, init.lua). Bind a key to lc_quick or lc_quick2 to open
    them from something else.
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
        Item("Tell everyone nearby my name", function() Send("recognize", "all") end),
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
    local ota = LCF and LCF.IsOverwatch and LCF.IsOverwatch(me)
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

-- Your side's manpower, as the server last sent it (sv_livingcity_manpower.lua): lines of text.
LC_CL.Manpower = LC_CL.Manpower or {}
net.Receive("lc_manpower", function()
    local s = net.ReadString() or ""
    local out = {}
    for l in string.gmatch(s, "[^\n]+") do out[#out + 1] = l end
    LC_CL.Manpower = out
end)
-- The manpower lines in a page's empty rows, from row `from` down.
local function ManpowerRows(from)
    local rows = {}
    for i, l in ipairs(LC_CL.Manpower or {}) do
        if from + i - 1 <= 9 then rows[from + i - 1] = l end
    end
    return rows
end

local function ResistancePage()
    local me = LocalPlayer()
    local items = {
        Item("Find the lab (mark it)", function() Send("waypoint", "lab") end),
        Item("Donate food to the supply crate", function() Send("donate") end),
        Item("Decode a data chip (at the lab)", function() Send("decode") end),
        Item("Write down what you see (needs paper)", function() Send("scout") end),
    }
    if me:HasWeapon("weapon_lc_multitool") then items[#items + 1] = Item("Hack the Combine door I'm looking at", function() Send("hack") end) end
    -- (the owner, 7 November: losses you can see; the fighters we have left, under the rest)
    return { title = "RESISTANCE", items = items, empty = ManpowerRows(7) }
end

-- The Combine's manpower, for the Administrator (units see it on the unit tools).
local function ManpowerPage()
    local rows = ManpowerRows(1)
    if not rows[1] then rows[1] = "No manpower report yet." end
    return { title = "COMBINE MANPOWER", items = {}, empty = rows }
end

local function SquadPage()
    return { title = "SQUAD ORDERS", items = {
        Item("Act casual (guns away, plain clothes)", function() Send("casual") end),
        Item("Guns out", function() Send("gunsout") end),
        Item("Go on ahead: meet me at the job's marker", function() Send("meet") end),
    } }
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
-- What's in front of you, and your own trouble: slots 6 to 8 first.
-- role = true: only your side does it (a unit's search and cuffs): that one's on F2.
------------------------------------------------------------------------

local function Context(me, unit, rebel)
    local out = {}
    local function Add(label, run, role) out[#out + 1] = { label = label, run = run, ctx = true, role = role or nil } end
    local now = CurTime()
    if me:GetNW2Float("lc_downed_until", 0) > now then Add("Give up (let go)", function() Send("giveup") end) end
    if me:GetNW2Bool("lc_tied", false) then Add("Work at the cuffs", function() Send("struggle") end) end
    if me:GetNW2Float("lc_gman_rival_until", 0) > now then Add("Call a vote to remove the City Administrator", function() Send("recall") end) end
    if not unit and me:GetNW2Float("lc_wanted_until", 0) > now then Add("Give myself up (near a Civil Protection unit)", function() Send("surrender") end) end
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
            Add("Search " .. n, function() Send("search") end, true)
            if tied then
                Add("Drag " .. n .. " along / let go", function() Send("drag") end)
                Add("Uncuff " .. n, function() Send("untie") end)
            else
                Add("Cuff " .. n, function() Send("tie") end, true)
            end
            if e:GetNW2String("lcj_job", "") ~= "" and e:GetNW2Entity("lc_escorting") ~= me then Add("Escort " .. n, function() Send("escort", "", e) end, true) end
            if tied or e:GetNW2Bool("lc_handsup", false) then Add("Take " .. n .. "'s microphone", function() Send("takemic", "", e) end, true) end
        else
            Add("Tell " .. n .. " my name", function() Send("recognize") end)
            Add("Show " .. n .. " my papers", function() Send("showpapers") end)
            if tied then
                Add("Uncuff " .. n, function() Send("untie") end)
                Add("Drag " .. n .. " along / let go", function() Send("drag") end)
            end
            if me:GetNW2Bool("lc_foreman", false) then Add("Give " .. n .. " a work order", function() Send("assign", "", e) end, true) end
            if rebel and e:GetNW2String("lcf_faction", "") == "vort" then Add("Cut the vortigaunt's shackles", function() Send("unshackle") end, true) end
            if not rebel then Add("Inform on " .. n, function() Send("inform", "", e) end) end
        end
    elseif unit and e:GetNW2Bool("lc_cuffed", false) then
        -- a citizen or rebel cuffed with the baton (sv_livingcity_arrest.lua)
        Add("Walk them to the cells / let go", function() Send("drag") end, true)
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
        if unit then Add("Read the power bank", function() Send("checkpoint", "status", e) end, true)
        elseif me:HasWeapon("weapon_lc_multitool") then Add("Short out the power bank", function() Send("checkpoint", "short", e) end) end
    elseif cls == "npc_turret_floor" and unit then
        Add("Pack up this turret", function() Send("checkpoint", "pack", e) end, true)
    elseif cls == "lc_screen" and me:HasWeapon("weapon_lc_multitool") then
        Add("Hijack this screen (multitool)", function() Send("hijack") end)
    end
    return out
end

local function Who(me)
    local f = me:GetNW2String("lcf_faction", "")
    return f, me:GetNW2Bool("lc_unit", false) or f == "cp", f == "resistance"
end
local function Hub(tab) if LC_CL.OpenHub then LC_CL.OpenHub(tab) else RunConsoleCommand("gm_showspare2") end end
local function Full() return Item("Everything else (full menu)", function() if LC_CL.OpenActions then LC_CL.OpenActions() end end) end

------------------------------------------------------------------------
-- F1: what everyone has
------------------------------------------------------------------------

function LC_CL.QuickRoot()
    local me = LocalPlayer()
    local f, unit, rebel = Who(me)
    local hands = Item(me:GetNW2Bool("lc_handsup", false) and "Lower my hands" or "Put my hands up", function() Send("handsup") end)
    -- slot 1: the next step, and the way to everywhere (cl_livingcity_nextstep.lua)
    local whatNow = Page("What now?", function() return LC_CL.WhatNowPage and LC_CL.WhatNowPage() or { title = "WHAT NOW?", items = {} } end)
    local items = {
        whatNow,
        hands,
        Item("My papers", function() Send("papers") end),
        Page("Talk", TalkPage),
        Item("My pockets (F3)", function() RunConsoleCommand("gm_showspare1") end),
    }
    local usual = { Page("Pose", PosePage), Page("Gesture", GesturePage), Item("Jobs, career, factions (F4)", function() Hub("jobs") end) }
    -- after the fixed slots, up to 8: what's in front of you first, then your usual ones
    local ctx = {}
    for _, it in ipairs(Context(me, unit, rebel)) do if not it.role then ctx[#ctx + 1] = it end end
    local n = #items
    for i = 1, 8 - n do items[n + i] = ctx[i] or table.remove(usual, 1) end
    items[9] = Full()
    local accent = unit and ACCENT.cp or (rebel and ACCENT.resistance or ACCENT.default)
    return { title = "QUICK MENU", items = items, accent = accent, kind = "general" }
end

------------------------------------------------------------------------
-- F2: what your side, rank and job have
------------------------------------------------------------------------

local EMPTY = { "Nothing here for your side or job right now.", "F1 has what everyone can do." }

function LC_CL.QuickRoleRoot()
    local me = LocalPlayer()
    local f, unit, rebel = Who(me)
    local fac = LCF and LCF.Get and LCF.Get(f)
    local title, accent = fac and fac.name or "", ACCENT.default
    local items, usual = {}, {}
    local function Add(it) if it and #items < 8 then items[#items + 1] = it end end
    if unit then
        title = me:GetNW2String("lcf_title", "") ~= "" and me:GetNW2String("lcf_title", "") or ((LCF and LCF.IsOverwatch and LCF.IsOverwatch(me)) and "OVERWATCH" or "CIVIL PROTECTION")
        accent = ACCENT.cp
        -- (the owner, 7 November: 1 Voice lines, 2 Unit tools, 3 Kick, 4 Call for backup, 5 BOLO, 6 Send my 10-20)
        local tools = Item("Unit tools (everything a unit has)", function() if LC_CL.OpenUnitTools then LC_CL.OpenUnitTools() end end)
        tools.id = "unittools"
        local kick = Item("Kick (" .. (LC_CL.KickKeyName and LC_CL.KickKeyName() or "G") .. ")", function() Send("kick") end)
        kick.id = "kick"
        Add(Page("Voice lines", VoicePage))
        Add(tools)
        Add(kick)
        Add(Item("Call for backup", function() Send("backup") end))
        Add(Item("Issue a BOLO...", function() Ask("BOLO", "What should Civil Protection units look out for?", "bolo") end))
        Add(Item("Send my 10-20", function() Send("10-20") end))
        usual = { Item("My directives (F4)", function() Hub("jobs") end), Item("Records terminal", function() Send("records") end) }
    elseif rebel then
        title, accent = "RESISTANCE", ACCENT.resistance
        local plain = me:GetNW2String("lcd_disguise", "") ~= ""
        Add(Item(plain and "Gear up (Resistance clothes)" or "Change into plain clothes", function() Send(plain and "gearup" or "plain") end))
        Add(Item("Black market", function() Send("market") end))
        Add(Page("Resistance", ResistancePage))
        if me:GetNW2Int("lc_squad_n", 0) > 0 then Add(Page("Squad orders", SquadPage)) end
    elseif f == "admin" then
        -- only the Administrator sets sociostability (the owner, 7 November)
        Add(Page("Sociostability", SocioPage))
        Add(Item("Broadcast to the whole city...", function() Ask("Broadcast", "What does the city hear?", "broadcast") end))
        if #(LC_CL.Manpower or {}) > 0 then Add(Page("Combine manpower", ManpowerPage)) end
    elseif f == "vort" then
        Add(Item("Reach out through the vortessence", function() Send("vortcall") end))
    elseif f == "stalker" then
        Add(Item("My work: the Stalker's Lot (F4)", function() Hub("jobs") end))
    end
    -- a worker's job tools
    local job = me:GetNW2String("lcj_job", "")
    if not unit and job ~= "" then
        local esc = me:GetNW2String("lc_escort_phase", "") ~= "" or me:GetNW2Bool("lc_escort_wait", false)
        Add(Item(esc and "Send my escort away" or "Ask for a Civil Protection escort", function() Send("escort") end))
    end
    if me:GetNW2Bool("lc_ration_break", false) then Add(Item("Back to work (end the ration break)", function() Send("back") end))
    elseif job ~= "" and GetGlobal2String("lc_event", "") == "rations" then Add(Item("Take a ration break", function() Send("rationbreak") end)) end
    if job == "mortuary" then Add(Item("Take a body cart, or leave it", function() Send("bodycart") end)) end
    if (f == "citizen" or f == "") and me:GetNW2Int("lce_standing", 0) >= 150 then
        Add(Item(me:GetNW2Bool("lc_foreman", false) and "Stop being a Union foreman" or "Become a Union foreman", function() Send("foreman") end))
    end
    -- staff
    if me:IsAdmin() then usual[#usual + 1] = Page("Staff", StaffPage) end
    -- then what only your side does to what's in front of you, then your usual ones
    for _, it in ipairs(Context(me, unit, rebel)) do if it.role then Add(it) end end
    for _, it in ipairs(usual) do Add(it) end
    local empty = #items == 0
    items[9] = Full()
    if title == "" then title = "YOUR SIDE" end
    return { title = string.upper(title), items = items, accent = accent, kind = "role", empty = empty and EMPTY or nil }
end

------------------------------------------------------------------------
-- Open, pick, close
------------------------------------------------------------------------

local open -- { page, stack, last, kind }

-- open at all, or (kind "general" for F1, "role" for F2) that one
function LC_CL.QuickOpen(kind) return open ~= nil and (kind == nil or open.kind == kind) end
function LC_CL.CloseQuick() open = nil end

function LC_CL.OpenQuick()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    open = { page = LC_CL.QuickRoot(), stack = {}, last = CurTime(), kind = "general" }
    LC_CL.ActionsOpenedAt = CurTime() -- (the server's own F1 answer doesn't also open the guide)
end

function LC_CL.OpenQuick2()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    open = { page = LC_CL.QuickRoleRoot(), stack = {}, last = CurTime(), kind = "role" }
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

concommand.Add("lc_quick", function() if LC_CL.QuickOpen("general") then open = nil else LC_CL.OpenQuick() end end)
local function Toggle2() if LC_CL.QuickOpen("role") then open = nil else LC_CL.OpenQuick2() end end
concommand.Add("lc_quick2", Toggle2)
-- F2 (gm_showteam), as the server answers it (init.lua)
net.Receive("lcg_quick2", Toggle2)

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
        elseif page.empty and page.empty[i] then
            draw.SimpleText(page.empty[i], "DermaDefault", x + 16, ry + 12, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(tostring(i), "LCQuickNum", x + 16, ry + 12, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    draw.SimpleText(#open.stack > 0 and "0  Back" or "0  Close", "DermaDefault", x + 12, y + H - 13, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local key = input and input.LookupBinding and input.LookupBinding("+menu_context")
    draw.SimpleText((key and string.upper(key) or "C") .. ": the full menu", "DermaDefault", x + W - 12, y + H - 13, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end)

-- The keys that open F1 and F2 (whatever they're bound to), and where something is on the first
-- page of F2 (or else F1), for hints that name the keys: LC_CL.QuickSlot("kick") -> 3, "F2".
-- Looked up live, so a hint stays right if things move.
function LC_CL.QuickKeyName()
    local k = input and input.LookupBinding and input.LookupBinding("gm_showhelp")
    return string.upper(k or "F1")
end
function LC_CL.QuickRoleKeyName()
    local k = input and input.LookupBinding and input.LookupBinding("gm_showteam")
    return string.upper(k or "F2")
end
function LC_CL.QuickSlot(id)
    for _, r in ipairs({ { LC_CL.QuickRoleRoot, LC_CL.QuickRoleKeyName }, { LC_CL.QuickRoot, LC_CL.QuickKeyName } }) do
        local ok, root = pcall(r[1])
        if ok and root then
            for n = 1, 9 do local it = root.items[n] if it and it.id == id then return n, r[2]() end end
        end
    end
    return nil
end
